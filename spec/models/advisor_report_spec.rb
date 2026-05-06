require "rails_helper"

RSpec.describe AdvisorReport, type: :model do
  subject { build(:advisor_report) }

  describe "associations" do
    it { is_expected.to belong_to(:advisor_session) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:fit_score) }
    it { is_expected.to validate_presence_of(:rationale) }
    it { is_expected.to validate_uniqueness_of(:advisor_session_id).ignoring_case_sensitivity }
    it { is_expected.to validate_numericality_of(:fit_score)
           .only_integer
           .is_greater_than_or_equal_to(1)
           .is_less_than_or_equal_to(100) }
  end

  it "rejects a fit_score of 0" do
    report = build(:advisor_report, fit_score: 0)
    expect(report).not_to be_valid
  end

  it "rejects a fit_score of 101" do
    report = build(:advisor_report, fit_score: 101)
    expect(report).not_to be_valid
  end

  it "accepts a fit_score of 1" do
    report = build(:advisor_report, fit_score: 1)
    expect(report).to be_valid
  end

  it "accepts a fit_score of 100" do
    report = build(:advisor_report, fit_score: 100)
    expect(report).to be_valid
  end
end
