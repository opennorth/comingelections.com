# coding: utf-8

require 'open-uri'

def pattern(array)
  array.map do |jurisdiction|
    if jurisdiction == 'Quebec'
      /Quebec(?! City)/
    else
      Regexp.escape(jurisdiction)
    end
  end.join('|')
end

MONTHS = %w(January February March April May June July August September October November December)
SCOPES = pattern(ComingElections::SCOPES)
PROVINCES = pattern(ComingElections::PROVINCES)
TERRITORIES = pattern(ComingElections::TERRITORIES)
JURISDICTIONS = pattern(ComingElections::JURISDICTIONS)
MUNICIPALITIES = pattern(ComingElections::MUNICIPALITIES)

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
            notes: notes,
            source: source,
          })
        end
      end
    end
  end

  # @note This is the part of the app that will require maintenance.
  desc "Scrape Wikipedia"
  task :wikipedia => :environment do
    def parse_line(source, li, year, date, text)
      if !text[/leadership|co-spokesperson|referendum|plebiscite|school/i]
        original = text.dup

        # Remove last period.
        text.chomp!('.')
        # Remove years.
        text.gsub!(/(?:, )\b\d{4}\b/, '')
        # Remove useless text.
        text.gsub!(/\(postponed from general\)|\b(?:City Council|District|Ward(?: of )?)\b/, '')

        # By-election pattern.
        pattern = /\b(federal|municipal|provincial|territorial) (by-election)(s)?(?: for|(?: held)? in)?\b/i
        if text[pattern]
          hint = $1.downcase
          type = $2
          multiple = !!$3
          text.sub!(pattern, '')

          text = text.strip.chomp(',')

          jurisdiction = nil
          case hint
          when 'federal'
            jurisdiction = 'Canada'
            text.gsub!(/canadian|federal/i, '')
          when 'provincial'
            text.slice!(/(?:in )?(#{PROVINCES})/)
            jurisdiction = $1

            if jurisdiction.nil?
              ComingElections::DIVISIONS.each do |key,values|
                # Division names are unique across provinces. However, Wikipedia
                # sometimes doesn't use the official name for a division; we
                # therefore run the risk of matching the incorrect province.
                if ComingElections::PROVINCES.include?(key) && values.include?(text)
                  jurisdiction = key
                  break
                end
              end
            end
          when 'municipal'
            # May be helpful later if we have a later list of municipalities.
            hint = text.slice!(/#{PROVINCES}/)
            text = text.strip.chomp(',')

            text.slice!(/(?:in )?(#{MUNICIPALITIES})/)
            jurisdiction = $1
          when 'territorial'
            text.slice!(/(?:in )?(#{TERRITORIES})/)
            jurisdiction = $1
          end

          text = text.strip.chomp(',')

          parts = if multiple
            text.split(/, (?:and )?| and /)
          else
            [text]
          end

          condition = parts.all? do |part|
            ComingElections::DIVISIONS.key?(jurisdiction) && ComingElections::DIVISIONS[jurisdiction].include?(part)
          end

          if condition
            divisions = parts
            text.clear
          end
        else
          type = text.slice!(/\b(?:general|municipal|provincial)\b/i)
          jurisdiction = text.slice!(/#{JURISDICTIONS}|Canadian|Federal/)
        end

        if type == 'by-election' && text.present?
          puts "#{text.inspect} #{original.inspect}: #{jurisdiction} #{type}"
        end

        if type
          type.downcase!
          type = case type
          when 'provincial'
            'general'
          else
            type
          end
        end

        scope = text.slice!(/#{SCOPES}/)

        text.gsub!(/provincial|municipal|ward| in |,$/i,'\1')
        p text if !text.empty? && type == 'by-election'
        divisions = text.slice!(/(([A-Z](\S+) ?)+)/)

        divisions = nil
        divisions = text.slice!(/([A-Z]\S+ ?)+/) # check
        @divisions << divisions if divisions

        if jurisdiction.nil? || jurisdiction.strip.empty?
          if li.at_css('a/@title[contains("does not exist")]') || !li.at_css('a')
            puts "Warning: not enough info for #{li.text}"
          else
            doc = Nokogiri::HTML(open("http://en.wikipedia.org#{li.at_css('a')[:href]}"))
            if doc.at_css('.infobox th')
              jurisdiction = doc.at_css('.infobox th').text.slice!(/#{JURISDICTIONS}/) ||
                doc.at_css('h1.firstHeading span').text.slice!(/#{JURISDICTIONS}/)
            end
            divisions = text.strip.slice!(/(([A-Z](\S+) ?)+)/) # check
          end
          if divisions.nil?
            # divisions = li.at_css('a').text.slice!(/([A-Z]\S+ ?)+/) # @todo
          end
        end
        divisions = divisions.split(/,|and/) if divisions

        if %w(Federal Canadian).include?(jurisdiction)
          jurisdiction = 'Canada'
          type ||= 'general'
        end

        unless text.strip.empty?
          if jurisdiction.nil?
            jurisdiction = 'Canada' if text.include? 'federal' or text.include? 'Federal'
          end

          if jurisdiction.nil? || type.nil?
            puts "Warning: Unrecognized text #{text.inspect} in #{original.inspect} #{source}"
          else
            puts "Ignoring text #{text.inspect} in #{original.inspect} #{source}"
          end
        end

        attributes = {
          start_date: Date.parse("#{date} #{year}"),
          jurisdiction: jurisdiction,
          election_type: type,
          scope: scope,
          source: source,
        }
        if divisions
          divisions.map(&:strip).each do |division|
            unless division == '.' || division.empty?
              begin
                Election.create_or_update(attributes.merge(division: division))
              rescue ActiveRecord::RecordInvalid => e
                puts "#{e.message}: #{original.inspect}: #{attributes.inspect}"
              end
            end
          end
        else
          begin
            Election.create_or_update(attributes)
          rescue ActiveRecord::RecordInvalid => e
            puts "#{e.message}: #{original.inspect}: #{attributes.inspect}"
          end
        end
      end
    end

    @divisions = []

    doc = Nokogiri::HTML(open('http://en.wikipedia.org/wiki/Canadian_electoral_calendar'))
    doc.xpath('//div[@id="mw-content-text"]/ul/li/a').each do |a|
      year = a.text.to_i
      if year >= 2007 && a[:class] != 'new' # The format before 2007 is different, and we don't need history.
        source = "http://en.wikipedia.org#{a[:href]}"

        doc = Nokogiri::HTML(open(source))
        doc.xpath('//div[@id="mw-content-text"]/ul/li').each do |li|
          date, text = li.text.sub(/ elections?(?:\[1\])?(?:, #{year})?/, '').split(/:| - /)
          unless MONTHS.include?(date.split(' ')[0])
            date = li.at_xpath('parent::*/preceding-sibling::h2[1]').text + date
            date = date.gsub('[edit]','')
          end

          if text
            parse_line(source, li, year, date, text)
          end

          #if there is a nested list (one date and many elections)
          # @see http://en.wikipedia.org/wiki/Canadian_electoral_calendar,_2011
          # @see http://en.wikipedia.org/wiki/Canadian_electoral_calendar,_2012
          if MONTHS.include?(date.split(' ')[0]) && !text
            li.xpath('.//li').each do |nested_li|
              date = date.split("\n")[0]
              text = nested_li.text
              parse_line(source, nested_li, year, date, text)
            end
          end
        end
      end
    end

    #puts @divisions.uniq.sort
  end
end
