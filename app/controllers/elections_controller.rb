class ElectionsController < ApplicationController
  def index
    @elections = Election.order(:start_date)

    respond_to do |format|
      format.html
      format.json { render json: @elections }
      format.csv {
        headers['Content-Type'] = 'text/csv; charset=utf-8; header=present'
        headers['Content-Disposition'] = %(attachment; filename="upcoming_elections.csv")
        send_data @elections.to_csv
      }
    end
  end
end
