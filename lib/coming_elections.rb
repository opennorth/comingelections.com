module ComingElections
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

  JURISDICTIONS = [
    'Canada',
    # Provinces
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
    # Territories
    'Northwest Territories',
    'Nunavut',
    'Yukon',
    # Municipalities
    'Bedford',
    'Bromont',
    'Cowansville',
    'Magog',
    'Vancouver',
    'Winnipeg',
    'Montreal',
    'Iqaluit'
  ]

  ELECTION_TYPES = %w(general by-election municipal)
end
