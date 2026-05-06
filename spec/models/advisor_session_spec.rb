require "rails_helper"

RSpec.describe AdvisorSession, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_one(:advisor_report).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:job_title) }
    it { is_expected.to validate_presence_of(:company_name) }
    it { is_expected.to validate_presence_of(:job_description) }
    it { is_expected.to validate_length_of(:job_description).is_at_most(8000) }
  end

  it "destroys the associated report when the session is destroyed" do
    session = create(:advisor_session)
    create(:advisor_report, advisor_session: session)
    expect { session.destroy }.to change(AdvisorReport, :count).by(-1)
  end
end
