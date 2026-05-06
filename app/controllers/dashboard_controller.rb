class DashboardController < ApplicationController
  def show
    @profile  = current_user.job_seeker_profile
    @sessions = current_user.advisor_sessions.includes(:advisor_report).order(created_at: :desc).limit(10)
  end
end
