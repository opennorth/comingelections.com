class ElectionsController < ApplicationController
  def index
    @elections = Election.order(:start_date)

    respond_to do |format|
      format.html
      format.json {
        render json: @elections
      }
      format.csv {
        send_data @elections.to_csv, filename: 'comingelections.csv', type: 'text/csv; charset=utf-8; header=present'
      }
    end
  end
end
