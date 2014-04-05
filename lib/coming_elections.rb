# coding: utf-8

module ComingElections
  ELECTION_TYPES = %w(general by-election municipal)

  SCOPES = [
    'cities and (southern) towns and villages',
    'cities, towns and villages',
    'even-numbered rural municipalities',
    'odd-numbered rural municipalities',
    'hamlets',
    'municipalities',
    'resort villages',
    'rural municipalities',
    'taxed communities',
    'tlicho community governments',
    'urban municipalities',
  ]

  PROVINCES_AND_TERRITORIES = [
    'Alberta',
    'British Columbia',
    'Manitoba',
    'New Brunswick',
    'Newfoundland and Labrador',
    'Nova Scotia',
    'Ontario',
    'Prince Edward Island',
    'Quebec',
    'Saskatchewan',
    'Yukon',
    'Northwest Territories',
    'Nunavut',
  ]
end
