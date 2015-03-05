# coding: utf-8

require 'open-uri'

MONTHS = I18n.t('date.month_names').drop(1)

namespace :scrape do
  def logger
    @logger ||= begin
      Rails.logger = Logger.new(STDOUT)
      Rails.logger.formatter = proc do |severity, datetime, progname, msg|
        "#{msg}\n"
      end
      Rails.logger
    end
  end

  desc "Scrape the Public Service Commission of Canada"
  task public_service_commission: :environment do
    source = 'http://www.psc-cfp.gc.ca/plac-acpl/leave-conge/ann2-eng.htm'
    doc = Nokogiri::HTML(open(source))

    doc.xpath('//tr').each do |tr|
      next if tr.at_css('th')
      scope = nil

      tds = tr.css('td')
      tds[1].css('br').each{|br| br.replace(' ')}

      type, notes = tds[1].text.match(/\A([^(]+?)(?: \(([^)]+)\))?\z/)[1..2]
      type.downcase!

      if %w(federal provincial territorial).include?(type)
        type = 'general'
      end
      if ['cities, towns and villages', 'hamlets', 'municipalities', 'resort villages', 'rural municipalities'].include?(type)
        scope, type = type, 'municipal'
      end

      begin
        Election.create_or_update({
          start_date: Date.parse(tds[2].text),
          jurisdiction: tds[0].text,
          election_type: type,
          scope: scope,
          notes: notes,
          source: source,
        })
      rescue ArgumentError => e
        logger.error("#{e.message}: #{tds[2].text}")
      end
    end
  end

  # @todo Compare to schedules. If identical, remove this Rake task.
  # @see https://docs.google.com/a/opennorth.ca/spreadsheet/ccc?key=0AtzgYYy0ZABtdHU4ZUxlNEFKbWRvN242M0hPRVBQMWc&usp=drive_web#gid=0
  desc "Scrape Muniscope"
  task muniscope: :environment do
    source = 'http://www.icurr.org/research/municipal_facts/Elections/index.php'
    doc = Nokogiri::HTML(open(source))

    doc.xpath('//table/tbody//tr').each do |tr|
      texts = tr.at_xpath('.//td[@class="rcell"]').to_s.split('<br>').map do |html|
        Nokogiri::HTML(html).text.strip
      end

      texts.each_with_index do |text,index|
        if MONTHS.include?(text.split(' ')[0])
          jurisdiction = tr.at_xpath('.//td[@class="lcell"]').text
          if jurisdiction == 'Québec'
            jurisdiction = 'Quebec'
          end

          scope = nil
          if index.nonzero?
            scope = texts[index - 1].gsub("\n", '').sub(/\AFor /, '').sub(/:\z/, '').downcase.strip
          end

          begin
            Election.create_or_update({
              start_date: Date.parse(text),
              jurisdiction: jurisdiction,
              election_type: 'municipal',
              scope: scope,
              source: source,
            })
          rescue ActiveRecord::RecordInvalid => e
            logger.error("#{e.message}: #{scope}")
          end
        end
      end
    end
  end

  desc "Scrape Wikipedia"
  task wikipedia: :environment do
    def pattern(values)
      values.map{|value| Regexp.escape(value)}.join('|')
    end

    def normalize(string)
      string.gsub(/ - |[—–]/, '-').downcase
    end

    SCOPES = Regexp.new(pattern(ComingElections::SCOPES), Regexp::IGNORECASE)
    PROVINCES_AND_TERRITORIES = Regexp.new(pattern(ComingElections::PROVINCES_AND_TERRITORIES))

    OLD_DIVISIONS = Regexp.new(pattern([
      'Cape Breton North', # https://en.wikipedia.org/wiki/Cape_Breton_North
      'Charlevoix', # https://en.wikipedia.org/wiki/Charlevoix_%28provincial_electoral_district%29
      'Kent', # https://en.wikipedia.org/wiki/Kent_%28provincial_electoral_district%29
      'Markham', # https://en.wikipedia.org/wiki/Markham_%28provincial_electoral_district%29
      'New Maryland-Sunbury West', # https://en.wikipedia.org/wiki/New_Maryland-Sunbury
      'Kamouraska-Témiscouata', # https://en.wikipedia.org/wiki/Kamouraska-T%C3%A9miscouata
      'Restigouche-La-Vallée', # https://en.wikipedia.org/wiki/Restigouche-La-Vall%C3%A9e
      'Rivière-du-Loup', # https://en.wikipedia.org/wiki/Rivi%C3%A8re-du-Loup_%28electoral_district%29
      'Vancouver-Burrard', # https://en.wikipedia.org/wiki/Vancouver-Burrard
    ]))

    # No OCD-IDs yet.
    names = {
      'Yukon' => [
        normalize('Whitehorse Centre'),
      ],
      'Nunavut' => [
        normalize('Iqaluit West'),
        normalize('Rankin Inlet South'),
        normalize('Uqqummiut'),
      ],
    }

    codes = {}
    CSV.parse(open('https://raw.githubusercontent.com/opencivicdata/ocd-division-ids/master/identifiers/country-ca/ca_provinces_and_territories.csv')).drop(1).each do |_,name,_,_,sgc|
      codes[sgc] = name
    end
    names['Canada'] = []
    CSV.parse(open('https://raw.githubusercontent.com/opencivicdata/ocd-division-ids/master/identifiers/country-ca/ca_federal_electoral_districts.csv')).drop(1).each do |_,name|
      names['Canada'] << normalize(name)
    end
    names['Municipal'] = {}
    CSV.parse(open('https://raw.githubusercontent.com/opencivicdata/ocd-division-ids/master/identifiers/country-ca/ca_census_subdivisions.csv')).drop(1).each do |id,name|
      province_or_territory = codes[id.split(':')[-1][0, 2]]
      names['Municipal'][province_or_territory] ||= []
      names['Municipal'][province_or_territory] << normalize(name)
    end

    { 'nl' => 'Newfoundland and Labrador',
      'pe' => 'Prince Edward Island',
      'ns' => 'Nova Scotia',
      'nb' => 'New Brunswick',
      'qc' => 'Quebec',
      'on' => 'Ontario',
      'mb' => 'Manitoba',
      'sk' => 'Saskatchewan',
      'ab' => 'Alberta',
      'bc' => 'British Columbia',
    }.each do |type_id,province_or_territory|
      names[province_or_territory] = []
      CSV.parse(open("https://raw.github.com/opencivicdata/ocd-division-ids/master/identifiers/country-ca/province-#{type_id}-electoral_districts.csv")).drop(1).each do |_,name|
        names[province_or_territory] << normalize(name)
      end
    end

    doc = Nokogiri::HTML(open('https://en.wikipedia.org/wiki/Canadian_electoral_calendar'))
    doc.xpath('//div[@id="mw-content-text"]/ul/li/a').each do |a|
      year = a.text.to_i
      if year >= 2007 && a[:class] != 'new' # The format before 2007 is different, and we don't need history that far back.
        source = "http://en.wikipedia.org#{a[:href]}"

        doc = Nokogiri::HTML(open(source))
        doc.xpath('//span[@id="Unknown_date"]/../following-sibling::ul[1]').remove
        doc.xpath('//span[@id="See_also"]/../following-sibling::ul[1]').remove
        doc.xpath('//div[@id="mw-content-text"]/ul/li').each do |li|
          next if li.text[/\b(co-spokesperson election|leadership election|plebiscites?|referendum|school board|senate nominee election)\b/i]

          original_text = li.text

          # Clean the string of needless information.
          text = original_text.dup
          # @see https://en.wikipedia.org/wiki/Canadian_electoral_calendar,_2007
          # @see https://en.wikipedia.org/wiki/Canadian_electoral_calendar,_2014
          text.gsub!(/\[\d+\]|\(postponed from [^)]+\)|\. See also [A-Za-z ]+ provincial by-elections|\b(?:for|in|Canadian|(?:City|Regional) Council)\b|,? #{year}\.?| elections?\b/i, '')
          text.chomp!('.')
          text.strip!
          text.squeeze!(' ')
          date, text = text.strip.split(/: | [-–] /, 2) # n-dash

          # If the list item has many sub-items.
          if text
            lines = [text]
          elsif date["\n"]
            date, *lines = date.split(/\n+/)
          else
            # Unknown date, usually
            logger.error("can't parse: #{source} #{date}")
            next
          end

          lines.each do |text|
            next if text[OLD_DIVISIONS]

            election_type = text.slice!(/\b(?:general|by-elections?)\b/i)
            level = text.slice!(/\b(?:federal|provincial|territorial|municipal)\b/i)
            level.downcase! if level
            scope = text.slice!(SCOPES)
            scope.downcase! if scope

            # @todo 2014 sometimes declares by-elections in different provinces in one line.
            jurisdiction = nil
            divisions = []

            # There may be a hint as to which province or territory the election is in.
            hint = text['Quebec City'] ? nil : text.slice!(PROVINCES_AND_TERRITORIES)
            text.gsub!(hint, '') if hint
            text = text.sub('Quebec City', 'Québec').sub('()', '').strip.chomp(',').strip.sub(/\Aand +/, '')
            level = 'municipal' if scope == 'mayoral'

            # Process by-elections.
            if %w(by-elections by-election).include?(election_type)
              # Make it easy to see, in error messages, if parts are properly identified.
              text.gsub!(/,[, ]+(?:and )?| and /, '|')

              # There may be by-elections in multiple divisions.
              parts = text.split('|')

              if level == 'federal'
                jurisdiction = 'Canada'
                parts.each do |part|
                  if names['Canada'].include?(normalize(part))
                    divisions << text.slice!(part)
                  end
                end
              elsif %w(provincial territorial).include?(level) && hint
                jurisdiction = hint
                parts.each do |part|
                  if names.key?(hint) && names[hint].include?(normalize(part))
                    divisions << text.slice!(part)
                  end
                end
              elsif level == 'municipal'
                if parts.size == 1
                  names['Municipal'].each do |province_or_territory,value|
                    if value.include?(normalize(parts[0]))
                      jurisdiction = province_or_territory
                      divisions << text.slice!(parts[0])
                    end
                  end
                else
                  # @todo 2014 sometimes declares elections in different municipalities in one line.
                end
              else # Provincial by-elections often omit the province name.
                matched = []
                options = names.keys - ['Canada', 'Municipal']

                # Try to find a unique jurisdiction containing this division.
                parts.each do |part|
                  matches = []
                  names.each do |province_or_territory,value|
                    if !%w(Canada Municipal).include?(province_or_territory) && value.include?(normalize(part))
                      matched << part
                      matches << province_or_territory
                    end
                  end
                  options &= matches
                end

                if options.size == 1
                  jurisdiction = options[0]
                  matched.each do |part|
                    divisions << text.slice!(part)
                  end
                end
              end
            else
              if level == 'municipal' && !election_type
                election_type = 'municipal'
                if text.empty?
                  jurisdiction = hint
                else
                  names['Municipal'].each do |province_or_territory,value|
                    if value.include?(normalize(text))
                      jurisdiction = province_or_territory
                      division = text.slice!(0, text.size)
                    end
                  end
                end
              elsif %w(provincial territorial).include?(level) || election_type == 'general'
                jurisdiction = hint
              elsif level == 'federal' && !jurisdiction && !election_type
                jurisdiction = 'Canada'
                election_type = 'general'
              end
            end

            text.sub!(/\A\|+\z/, '')

            unless text.empty? # For now, only wards, districts, boroughs, etc. should remain.
              logger.error("year=#{year}  type=#{election_type.ljust(12)}  text=#{text.ljust(50)}  #{original_text.inspect}")
              next
            end

            attributes = {
              start_date: Date.parse("#{date} #{year}"),
              jurisdiction: jurisdiction,
              election_type: election_type && election_type.chomp('s'),
              scope: scope,
              source: source,
            }

            if divisions.empty?
              begin
                Election.create_or_update(attributes)
              rescue ActiveRecord::RecordInvalid => e
                logger.error("#{e.message}: #{original_text.inspect}: #{attributes.inspect}")
              end
            else
              divisions.each do |division|
                begin
                  Election.create_or_update(attributes.merge(division: division))
                rescue ActiveRecord::RecordInvalid => e
                  logger.error("#{e.message}: #{original_text.inspect}: #{attributes.inspect}")
                end
              end
            end
          end
        end
      end
    end
  end
end
