# coding: utf-8
require 'csv'
require 'date'
require 'open-uri'
require 'csv'

require 'nokogiri'

elections = []

MONTHS = %w(January February March April May June July August September October November December)
JURISDICTIONS = [
  'Canada',
  'Federal',
  'Alberta',
  'British Columbia',
  'Manitoba',
  'New Brunswick',
  'Newfoundland and Labrador',
  'Northwest Territories',
  'Nova Scotia',
  'Nunavut',
  'Ontario',
  'Prince Edward Island',
  'Saskatchewan',
  'Quebec',
  'Québec',
  'Yukon',
].map do |jurisdiction|
  Regexp.escape(jurisdiction)
end.join('|')

namespace :scrape do
  desc "TODO"
  task :govt => :environment do
    source = 'http://www.psc-cfp.gc.ca/plac-acpl/leave-conge/ann2-eng.htm'
    doc = Nokogiri::HTML(open(source))
    doc.xpath('//tr').each do |tr|
      next if tr.at_css('th')
      tds = tr.css('td')
      tds[1].css('br').each{|br| br.replace(' ')}
      type, notes = tds[1].text.downcase.match(/\A([^(]+?)(?: \(([^)]+)\))?\z/)[1..2]
      if %w(federal provincial territorial).include?(type)
        type = 'general'
      end

      scope = nil
      if ['cities, towns and villages', 'hamlets', 'municipalities', 'resort villages', 'rural municipalities'].include?(type)
        scope = type
        type = 'municipal'
      end

      elections.push({
        date: Date.parse(tds[2].text),
        jurisdiction: tds[0].text,
        type: type,
        scope: scope,
        notes: notes,
        source: source,
      })
    end
  end

  desc "TODO"
  task :wiki => :environment do
    def parse_wiki(href, year)
      elections = []

      source = "http://en.wikipedia.org#{href}"
      doc = Nokogiri::HTML(open(source))
      doc.xpath('//div[@id="mw-content-text"]/ul/li').each do |li|
        date, text = li.text.sub(/ elections?, #{year}/, '').split(' - ')
        if text && !text[/leadership|co-spokesperson/]
          type         = text.slice!(/by-election|general|municipal/)
          jurisdiction = text.slice!(/#{JURISDICTIONS}/)

          text.slice!(/\(([^)]+)\)/)
          scope = $1

          text.slice!(/in (\S+)/)
          division = $1

          if jurisdiction.nil?
            text.slice!(/provincial/)
            doc = Nokogiri::HTML(open("http://en.wikipedia.org#{li.at_css('a')[:href]}"))
            jurisdiction = doc.at_css('.infobox th').text.slice!(/#{JURISDICTIONS}/)
            division = text.strip.slice!(/.+/)
          end

          if jurisdiction == 'Federal'
            jurisdiction = 'Canada'
          end

          unless text.strip.empty?
            puts "Warning: Unrecognized text #{text.inspect}"
          end

          elections.push({
            date: Date.parse("#{date} #{year}"),
            jurisdiction: jurisdiction,
            type: type,
            scope: scope,
            division: division,
            source: source,
          })
        end
      end

      elections
    end

    current_year = Date.today.year
    doc = Nokogiri::HTML(open('http://en.wikipedia.org/wiki/Canadian_electoral_calendar'))
    doc.xpath('//div[@id="mw-content-text"]/ul/li/a').each do |a|
      if a.text.to_i >= current_year
        elections += parse_wiki(a[:href], a.text)
      end
    end
  end

  desc "TODO"
  task :muni => :environment do
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

          notes = nil
          scope = nil
          if index.nonzero?
            texts[index - 1].slice!(/\(([^)]+)\):\z/)
            notes = $1
            scope = texts[index - 1].gsub("\n", '').sub(/\AFor /, '').sub(/:\z/, '').downcase.strip
          end

          elections.push({
            date: Date.parse(text),
            jurisdiction: jurisdiction,
            type: 'municipal',
            scope: scope,
            notes: notes,
            source: source,
          })
        end
      end
    end
  end

  desc "TODO"
  task :csv => :environment do
    CSV.open('elections.csv', 'w') do |csv|
      csv << %w(Date Jurisdiction Type Scope Division Notes Source)
      elections.each do |election|
        csv << [
          election[:date],
          election[:jurisdiction],
          election[:type],
          election[:scope],
          election[:division],
          election[:notes],
          election[:source],
        ]
      end
    end
  end

  desc "TODO"
  task :db => :environment do
    elections.each do |e|
      Election.create(
        :year => e[:date].year,
        :start_date => e[:date],
        :end_date => e[:date],
        :jurisdiction => e[:jurisdiction],
        :election_type => e[:type],
        :scope => e[:scope],
        :division => e[:division],
        :notes => e[:notes],
        :source => e[:source],
        )
    end
  end

end
