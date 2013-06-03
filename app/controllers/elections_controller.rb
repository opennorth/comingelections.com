class ElectionsController < ApplicationController
  def index
    range = Date.today..1.year.from_now.to_date
    @elections = Election.within(range) + ElectionSchedule.within(range)

    respond_to do |format|
      format.html
      format.json {
        render json: @elections
      }
      format.csv {
        send_data Election.to_csv(@elections), filename: 'comingelections.csv', type: 'text/csv; charset=utf-8; header=present'
      }
    end
  end
end
