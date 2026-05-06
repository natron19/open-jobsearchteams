require "rails_helper"

RSpec.describe JobSeekerProfile, type: :model do
  subject { build(:job_seeker_profile) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:current_role) }
    it { is_expected.to validate_presence_of(:target_role) }
    it { is_expected.to validate_presence_of(:top_skills) }
    it { is_expected.to validate_presence_of(:biggest_challenge) }
    it { is_expected.to validate_uniqueness_of(:user_id).ignoring_case_sensitivity }
  end

  it "saves a valid profile" do
    expect(build(:job_seeker_profile)).to be_valid
  end
end
