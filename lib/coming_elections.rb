# coding: utf-8

module ComingElections
  ELECTION_TYPES = [
    'general',
    'by-election',
    'municipal',
    'mayoral',
  ]

  SCOPES = [
    'cities and (southern) towns and villages',
    'cities, (southern) towns and villages',
    'cities, cornwall, & stratford',
    'cities, towns and villages',
    'even-numbered rural municipalities',
    'excluding charlottetown, cornwall, stratford and summerside',
    'charlottetown, cornwall, stratford and summerside', # must come after
    'hamlets',
    'mayoral',
    'municipalities',
    'northern municipalities (northern towns, villages and hamlets)',
    'odd-numbered rural municipalities',
    'resort villages',
    'rural municipalities',
    'taxed communities',
    'tlicho community governments',
    'urban municipalities',
  ]

  PROVINCES_AND_TERRITORIES = [
    'Newfoundland and Labrador',
    'Prince Edward Island',
    'Nova Scotia',
    'New Brunswick',
    'Quebec',
    'Ontario',
    'Manitoba',
    'Saskatchewan',
    'Alberta',
    'British Columbia',
    'Yukon',
    'Northwest Territories',
    'Nunavut',
  ]
end
