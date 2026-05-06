require "rails_helper"

RSpec.describe "JobSeekerProfiles", type: :request do
  let(:user) { create(:user) }

  describe "GET /profile" do
    it "redirects to sign in when unauthenticated" do
      get profile_path
      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects to /profile/new when no profile exists" do
      sign_in_as(user)
      get profile_path
      expect(response).to redirect_to(new_profile_path)
    end

    it "renders the show page when a profile exists" do
      sign_in_as(user)
      create(:job_seeker_profile, user: user)
      get profile_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /profile/new" do
    it "redirects to sign in when unauthenticated" do
      get new_profile_path
      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects to profile show when a profile already exists" do
      sign_in_as(user)
      create(:job_seeker_profile, user: user)
      get new_profile_path
      expect(response).to redirect_to(profile_path)
    end

    it "renders the form when no profile exists" do
      sign_in_as(user)
      get new_profile_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /profile" do
    let(:valid_params) do
      { job_seeker_profile: {
          current_role:      "Engineer",
          target_role:       "Senior Engineer",
          top_skills:        "Ruby, Rails, PostgreSQL",
          biggest_challenge: "Not enough senior roles nearby"
      } }
    end

    it "redirects to sign in when unauthenticated" do
      post profile_path, params: valid_params
      expect(response).to redirect_to(sign_in_path)
    end

    it "creates the profile and redirects to dashboard" do
      sign_in_as(user)
      expect {
        post profile_path, params: valid_params
      }.to change(JobSeekerProfile, :count).by(1)
      expect(response).to redirect_to(dashboard_path)
    end

    it "re-renders new with validation errors when fields are missing" do
      sign_in_as(user)
      post profile_path, params: { job_seeker_profile: { current_role: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /profile" do
    let!(:profile) { create(:job_seeker_profile, user: user) }

    it "redirects to sign in when unauthenticated" do
      patch profile_path, params: { job_seeker_profile: { current_role: "Updated" } }
      expect(response).to redirect_to(sign_in_path)
    end

    it "updates the profile and redirects to show" do
      sign_in_as(user)
      patch profile_path, params: { job_seeker_profile: { current_role: "Updated Role" } }
      expect(response).to redirect_to(profile_path)
      expect(profile.reload.current_role).to eq("Updated Role")
    end

    it "re-renders edit with errors when update is invalid" do
      sign_in_as(user)
      patch profile_path, params: { job_seeker_profile: { current_role: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
