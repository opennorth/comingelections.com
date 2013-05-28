class ElectionScheduleController < ApplicationController
  def index
    @election_schedules = ElectionSchedule.order(:last_election)
    respond_to do |format|
      format.html
      format.json {
        render json: @elections
      }
    end
  end
end
