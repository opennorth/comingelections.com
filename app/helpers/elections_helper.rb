module ElectionsHelper
  def to_csv do

    @col_sep = ','

    headers['Content-Type'] = 'text/csv; charset=utf-8; header=present'
    headers['Content-Disposition'] = %(attachment; filename="#{filename}")

    CSV.generate(:col_sep => @col_sep, :row_sep => "\r\n") do |csv|
      csv << headers
      @elections.each do |election|
        begin
          csv << election.csv_row
        rescue ArgumentError => e # non-UTF8 characters from spammers
          logger.error "#{e.inspect}: #{row.inspect}"
        end
      end
    end.html_safe



#    render layout: false

  end
  def csv_row(id) do 
    [
      self.id,
      self.year,
      self.start_date,
      self.end_date,
      self.division,
      self.election_type,
    ]
  end
end