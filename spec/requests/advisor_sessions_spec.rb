require "rails_helper"

RSpec.describe "AdvisorSessions", type: :request do
  let(:user)    { create(:user) }
  let!(:profile) { create(:job_seeker_profile, user: user) }

  let(:valid_session_params) do
    { advisor_session: {
        job_title:       "Product Manager",
        company_name:    "Acme Corp",
        job_description: "We are looking for a PM to lead our core product team."
    } }
  end

  let(:gemini_json) do
    {
      fit_score:       75,
      rationale:       "Good match overall.",
      strengths:       ["Skill A", "Skill B", "Skill C"],
      gaps:            ["Gap A", "Gap B"],
      resume_headline: "Product Manager Driving B2B Growth",
      outreach_draft:  "I wanted to reach out about the PM role..."
    }.to_json
  end

  describe "GET /advisor_sessions" do
    it "redirects to sign in when unauthenticated" do
      get advisor_sessions_path
      expect(response).to redirect_to(sign_in_path)
    end

    it "renders the index for a signed-in user" do
      sign_in_as(user)
      get advisor_sessions_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /advisor_sessions/new" do
    it "redirects to sign in when unauthenticated" do
      get new_advisor_session_path
      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects to /profile/new when no profile exists" do
      user_without_profile = create(:user)
      sign_in_as(user_without_profile)
      get new_advisor_session_path
      expect(response).to redirect_to(new_profile_path)
    end

    it "renders the form when a profile exists" do
      sign_in_as(user)
      get new_advisor_session_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /advisor_sessions" do
    before { sign_in_as(user) }

    context "with valid params and a successful Gemini response" do
      before { gemini_returns(gemini_json) }

      it "creates an AdvisorSession and an AdvisorReport" do
        expect {
          post advisor_sessions_path, params: valid_session_params
        }.to change(AdvisorSession, :count).by(1)
          .and change(AdvisorReport, :count).by(1)
      end

      it "redirects to the session show path" do
        post advisor_sessions_path, params: valid_session_params
        expect(response).to redirect_to(advisor_session_path(AdvisorSession.last))
      end
    end

    context "when Gemini raises TimeoutError" do
      before { gemini_raises(GeminiService::TimeoutError) }

      it "re-renders new without creating an AdvisorReport" do
        expect {
          post advisor_sessions_path, params: valid_session_params
        }.not_to change(AdvisorReport, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "does not leave an orphaned AdvisorSession" do
        expect {
          post advisor_sessions_path, params: valid_session_params
        }.not_to change(AdvisorSession, :count)
      end
    end

    context "when Gemini raises BudgetExceededError" do
      before { gemini_raises(GeminiService::BudgetExceededError) }

      it "re-renders new and does not create a session" do
        expect {
          post advisor_sessions_path, params: valid_session_params
        }.not_to change(AdvisorSession, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with invalid session params" do
      it "re-renders new without calling Gemini" do
        expect(GeminiService).not_to receive(:generate)
        post advisor_sessions_path, params: { advisor_session: { job_title: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /advisor_sessions/:id" do
    it "redirects to sign in when unauthenticated" do
      session = create(:advisor_session, user: user)
      get advisor_session_path(session)
      expect(response).to redirect_to(sign_in_path)
    end

    it "returns 404 when the session belongs to a different user" do
      sign_in_as(user)
      other_user    = create(:user)
      other_session = create(:advisor_session, user: other_user)
      get advisor_session_path(other_session)
      expect(response).to have_http_status(:not_found)
    end

    it "renders the show page for the owner" do
      sign_in_as(user)
      session = create(:advisor_session, user: user)
      create(:advisor_report, advisor_session: session)
      get advisor_session_path(session)
      expect(response).to have_http_status(:ok)
    end
  end
end
