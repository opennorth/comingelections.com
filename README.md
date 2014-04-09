# Coming Elections

A simple service to alert you of upcoming elections in Canada.

## Development

    git clone git@github.com:opennorth/comingelections.git
    bundle
    bundle exec rake db:setup
    bundle exec rake scheduler:scrape
    rails s

## Deployment

    heroku apps:create --addons scheduler:standard sendgrid:starter
    heroku config:add SECRET_KEY_BASE=`bundle exec rake secret`
    git push heroku master

## Elections offices

* [Canada](http://elections.ca/)
* [Alberta](http://www.elections.ab.ca/)
* [British Columbia](http://www.elections.bc.ca/)
* [Manitoba](http://www.elections.mb.ca/)
* [New Brunswick](http://www.gnb.ca/elections/)
* [Newfoundland and Labrador](http://www.elections.gov.nl.ca/)
* [Nova Scotia](http://electionsnovascotia.ca/)
* [Ontario](http://www.elections.on.ca/)
* [Prince Edward Island](http://www.electionspei.ca/)
* [Quebec](http://www.electionsquebec.qc.ca/)
* [Saskatchewan](http://www.elections.sk.ca/)
* [Northwest Territories](http://www.electionsnwt.ca/)
* [Nunavut](http://www.elections.nu.ca/)
* [Yukon](http://www.electionsyukon.gov.yk.ca/)

## Fixed election dates

* [Alberta](http://www.assembly.ab.ca/ISYS/LADDAR_files/docs/bills/bill/legislature_27/session_4/20110222_bill-021.pdf)
* [British Columbia](http://www3.elections.bc.ca/index.php/voting/)
* [Manitoba](http://residents.gov.mb.ca/reference.html?d=details&program_id=282)
* [New Brunswick](http://www.gnb.ca/legis/bill/FILE/57/2/Bill-9-e.htm)
* [Newfoundland and Labrador](http://www.assembly.nl.ca/pdf/MembersParliamentaryGuide.pdf)
* [Ontario](http://www.elections.on.ca/NR/rdonlyres/E61AA9C4-CA1B-4F0B-AAB4-85EB9884950B/0/VotingInOntProvincialElections.pdf)
* [Prince Edward Island](http://www.electionspei.ca/reference/events_2020.pdf)
* [Quebec](http://www.cic.gc.ca/english/resources/publications/discover/section-09.asp)
* [Saskatchewan](http://www.legassembly.sk.ca/about/election-of-a-member/)
* [Northwest Territories](http://www.maca.gov.nt.ca/?page_id=3632)
* [Municipal (Canadian Labour Congress)]
(http://www.canadianlabour.ca/action-center/municipalities-matter/municipal-election-chart-province-territory)
* [Municipal (Muniscope)](http://www.icurr.org/research/municipal_facts/Elections/index.php)
* [Municipal (Wikipedia)](http://en.wikipedia.org/wiki/Municipal_elections_in_Canada)
* [Federal, provincial and territorial levels (parl.gc.ca)](http://www.parl.gc.ca/ParlInfo/Compilations/ProvinceTerritory/ProvincialFixedElections.aspx)
* [Federal, provincial and territorial levels (Wikipedia)](http://en.wikipedia.org/wiki/Fixed_election_dates_in_Canada)

## Bugs? Questions?

This repository is on GitHub: [http://github.com/opennorth/comingelections](http://github.com/opennorth/comingelections), where your contributions, forks, bug reports, feature requests, and feedback are greatly welcomed.

Copyright (c) 2013 Open North Inc., released under the MIT license
