module ElectionsHelper
  def host(url)
    URI.parse(url).host.sub(/\A(?:en|www)\./, '')
  end
end
