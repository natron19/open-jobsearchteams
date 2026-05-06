class AdvisorSessionsController < ApplicationController
  before_action :require_profile, only: [:new, :create]

  def index
    @sessions = current_user.advisor_sessions.includes(:advisor_report).order(created_at: :desc)
  end

  def new
    @session = AdvisorSession.new
    @profile = current_user.job_seeker_profile
  end

  def create
    @session = current_user.advisor_sessions.build(session_params)
    @profile = current_user.job_seeker_profile

    unless @session.save
      render :new, status: :unprocessable_entity and return
    end

    result = GeminiService.generate(
      template:  "jobsearchteams_advisor_v1",
      variables: {
        current_role:      @profile.current_role,
        target_role:       @profile.target_role,
        top_skills:        @profile.top_skills,
        biggest_challenge: @profile.biggest_challenge,
        job_title:         @session.job_title,
        company_name:      @session.company_name,
        job_description:   @session.job_description
      }
    )

    json_text = result.gsub(/\A\s*```(?:json)?\s*/m, "").gsub(/\s*```\s*\z/m, "").strip
    parsed = JSON.parse(json_text)
    @session.create_advisor_report!(
      fit_score:       parsed["fit_score"],
      rationale:       parsed["rationale"],
      strengths:       JSON.dump(parsed["strengths"]),
      gaps:            JSON.dump(parsed["gaps"]),
      resume_headline: parsed["resume_headline"],
      outreach_draft:  parsed["outreach_draft"],
      gemini_raw:      result
    )
    redirect_to advisor_session_path(@session)

  rescue JSON::ParserError
    @session.destroy
    flash.now[:alert] = "The AI returned an unexpected format. Please try again."
    render :new, status: :unprocessable_entity

  rescue GeminiService::BudgetExceededError
    @session.destroy
    render :new, locals: { gemini_error: :budget_exceeded }, status: :unprocessable_entity

  rescue GeminiService::GatekeeperError
    @session.destroy
    render :new, locals: { gemini_error: :gatekeeper_blocked }, status: :unprocessable_entity

  rescue GeminiService::TimeoutError
    @session.destroy
    render :new, locals: { gemini_error: :timeout }, status: :unprocessable_entity

  rescue GeminiService::GeminiError
    @session.destroy
    render :new, locals: { gemini_error: :error }, status: :unprocessable_entity
  end

  def show
    @session = current_user.advisor_sessions.includes(:advisor_report).find(params[:id])
  end

  private

  def require_profile
    unless current_user.job_seeker_profile
      redirect_to new_profile_path, notice: "Please complete your profile before analyzing jobs."
    end
  end

  def session_params
    params.require(:advisor_session).permit(:job_title, :company_name, :job_description)
  end
end
