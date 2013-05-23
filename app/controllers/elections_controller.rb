class ElectionsController < ApplicationController
  # GET /elections
  # GET /elections.json
  def index
    @elections = Election.order(:start_date)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @elections }
      format.csv {
        headers['Content-Type'] = 'text/csv; charset=utf-8; header=present'
        headers['Content-Disposition'] = %(attachment; filename="upcoming_elections.csv") 
        send_data @elections.to_csv
      }
    end
  end

  # GET /elections/1
  # GET /elections/1.json
  def show
    @election = Election.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @election }
    end
  end

  # GET /elections/new
  # GET /elections/new.json
  
end
