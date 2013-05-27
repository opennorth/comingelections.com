# coding: utf-8
require 'csv'
require 'date'
require 'open-uri'
require 'csv'

require 'nokogiri'


MONTHS = %w(January February March April May June July August September October November December)
JURISDICTIONS = [
  'Canada',
  'Canadian',
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
  desc "Scrape Government Site"
  task :govt => [:environment,] do
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

      Election.create_or_update({
        start_date: Date.parse(tds[2].text),
        jurisdiction: tds[0].text,
        type: type,
        scope: scope,
        notes: notes,
        source: source,
      })
    end
  end

  desc "Scrape Wikipedia page"
  task :wiki => :environment do
    def parse_wiki(href, year)
      source = "http://en.wikipedia.org#{href}"
      doc = Nokogiri::HTML(open(source))
      doc.xpath('//div[@id="mw-content-text"]/ul/li').each do |li|
        date, text = li.text.sub(/ elections?, #{year}/, '').split(/:| - /)
        unless MONTHS.include?(date.split(' ')[0])
          date = li.at_xpath('parent::*/preceding-sibling::h2[1]').text + date
          date = date.gsub('[edit]','')
        end

        if text 
          parse_line(source, li, year, date, text)
        end
        #if there is a nested list (one date and many elections)
        if MONTHS.include?(date.split(' ')[0]) && !text
          p year
          li.xpath('.//li').each do |nested_li|
            date = date.split("\n")[0]
            text = nested_li.text
            parse_line(source, nested_li, year, date, text)
          end
        end

      end
    end

    def parse_line(source, li, year, date, text)
      if !text[/leadership|co-spokesperson|referendum|plebiscite|school/i]
        type         = text.slice!(/by-election|general|municipal/)
        jurisdiction = text.slice!(/#{JURISDICTIONS}/) 


        text.slice!(/\(([^)]+)\)/)
        scope = $1

        text.slice!(/in (\S+)/)
        division = $1 unless $1 == '.'

        if jurisdiction.nil? || jurisdiction.strip.empty?
          text.slice!(/provincial/)
          if li.at_css('a/@title[contains("does not exist")]') || !li.at_css('a')
            puts li.text
          else
            doc = Nokogiri::HTML(open("http://en.wikipedia.org#{li.at_css('a')[:href]}"))
            if doc.at_css('.infobox th')
              jurisdiction = doc.at_css('.infobox th').text.slice!(/#{JURISDICTIONS}/) || 
              doc.at_css('h1.firstHeading span').text.slice!(/#{JURISDICTIONS}/) 
            end
            division = text.strip.slice!(/.+/)
          end
       end

        if jurisdiction == 'Federal'
          jurisdiction = 'Canada'
        end

        unless text.strip.empty?
             puts "Warning: Unrecognized text #{text.inspect}"
        end
        Election.create_or_update({
          start_date: Date.parse("#{date} #{year}"),
          jurisdiction: jurisdiction,
          election_type: type,
          scope: scope,
          division: division,
          source: source,
        })
      end
    end    
    


    current_year = Date.today.year
    doc = Nokogiri::HTML(open('http://en.wikipedia.org/wiki/Canadian_electoral_calendar'))
    doc.xpath('//div[@id="mw-content-text"]/ul/li/a').each do |a|
      if a.text.to_i >= current_year
        parse_wiki(a[:href], a.text) 
      end
    end
  end

  desc "Scrape Municipal page"
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

          Election.create_or_update({
            start_date: Date.parse(text),
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

end
