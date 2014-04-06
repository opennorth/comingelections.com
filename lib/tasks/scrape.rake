# coding: utf-8

require 'open-uri'

MONTHS = I18n.t('date.month_names').drop(1)

namespace :scrape do
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

      Election.create_or_update({
        start_date: Date.parse(tds[2].text),
        jurisdiction: tds[0].text,
        election_type: type,
        scope: scope,
        notes: notes,
        source: source,
      })
    end
  end

  # @todo Compare to schedules. If identical, remove this Rake task.
  # @see https://docs.google.com/a/opennorth.ca/spreadsheet/ccc?key=0AtzgYYy0ZABtdHU4ZUxlNEFKbWRvN242M0hPRVBQMWc&usp=drive_web#gid=0
  desc "Scrape Muniscope"
  task :muniscope => :environment do
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

          Election.create_or_update({
            start_date: Date.parse(text),
            jurisdiction: jurisdiction,
            election_type: 'municipal',
            scope: scope,
            source: source,
          })
        end
      end
    end
  end

  desc "Scrape Wikipedia"
  task :wikipedia => :environment do
    def pattern(values)
      values.map{|value| Regexp.escape(value)}.join('|')
    end

    def normalize(string)
      string.gsub(/ - |[—–]/, '-').downcase
    end

    SCOPES = Regexp.new(pattern(ComingElections::SCOPES), Regexp::IGNORECASE)
    PROVINCES_AND_TERRITORIES = Regexp.new(pattern(ComingElections::PROVINCES_AND_TERRITORIES))

    # The following divisions no longer exist:
    SKIP = Regexp.new(pattern([
      'Cape Breton North',
      'Charlevoix',
      'Markham',
      'Kamouraska-Témiscouata',
      'Rivière-du-Loup',
      'Vancouver-Burrard',
    ]))

    # No OCD-IDs yet.
    names = {
      'Yukon' => [
        normalize('Whitehorse Centre'),
      ],
      'Nunavut' => [
        normalize('Iqaluit West'),
        normalize('Rankin Inlet South'),
      ],
    }

    codes = {}
    CSV.parse(open('https://raw.github.com/opencivicdata/ocd-division-ids/master/identifiers/country-ca/ca_provinces_and_territories.csv')).drop(1).each do |_,name,_,_,sgc|
      codes[sgc] = name
    end

    names['Canada'] = []
    CSV.parse(open('https://raw.github.com/opencivicdata/ocd-division-ids/master/identifiers/country-ca/ca_federal_electoral_districts.csv')).drop(1).each do |_,name|
      names['Canada'] << normalize(name)
    end
    names['Municipal'] = {}
    CSV.parse(open('https://raw.github.com/opencivicdata/ocd-division-ids/master/identifiers/country-ca/ca_census_subdivisions.csv')).drop(1).each do |id,name|
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

    doc = Nokogiri::HTML(open('http://en.wikipedia.org/wiki/Canadian_electoral_calendar'))
    doc.xpath('//div[@id="mw-content-text"]/ul/li/a').each do |a|
      year = a.text.to_i
      if year >= 2007 && a[:class] != 'new' # The format before 2007 is different, and we don't need history that far back.
        source = "http://en.wikipedia.org#{a[:href]}"

        doc = Nokogiri::HTML(open(source))
        doc.xpath('//div[@id="mw-content-text"]/ul/li').each do |li|
          next if ['Municipal elections in Canada', 'Elections in Canada'].include?(li.text) || li.text[/\b(co-spokesperson election|leadership election|plebiscites?|referendum|school board elections|senate nominee election)\b/i]

          # Clean the string of needless information.
          original_text = li.text
          text = original_text.dup
          text.gsub!(/\[1\]|\(postponed from general\)|\. See also [A-Za-z ]+ provincial by-elections|\b(?:for|in|Canadian|(?:City|Regional) Council)\b|,? #{year}\.?| elections?\b/i, '')
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
            puts "#{source} #{date}"
            next
          end

          lines.each do |text|
            next if text[SKIP]

            election_type = text.slice!(/\b(?:general|by-elections?)\b/i)
            level = text.slice!(/\b(?:federal|provincial|territorial|municipal)\b/i)
            level.downcase! if level
            scope = text.slice!(SCOPES)
            scope.downcase! if scope

            jurisdiction = nil
            divisions = []

            # There may be a hint as to which province or territory the election is in.
            hint = text['Quebec City'] ? nil : text.slice!(PROVINCES_AND_TERRITORIES)
            text = text.sub('Quebec City', 'Québec').sub('()', '').strip.chomp(',').strip
            level = 'municipal' if scope == 'mayoral'

            # Process by-elections.
            if %w(by-elections by-election).include?(election_type)
              # There may be by-elections in multiple divisions.
              parts = text.split(/, (?:and )?| and /)

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

            text.gsub!(/\A[, ]+|[, ]+\z/, '')
            text.sub!(/\Aand\z/, '')

            unless text.empty? # For now, only wards, districts, boroughs, etc. should remain.
              puts "#{year}  #{election_type.ljust(11)}  #{text.ljust(50)}  #{original_text.inspect}"
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
                puts "#{e.message}: #{original_text.inspect}: #{attributes.inspect}"
              end
            else
              divisions.each do |division|
                begin
                  Election.create_or_update(attributes.merge(division: division))
                rescue ActiveRecord::RecordInvalid => e
                  puts "#{e.message}: #{original_text.inspect}: #{attributes.inspect}"
                end
              end
            end
          end
        end
      end
    end
  end
end
