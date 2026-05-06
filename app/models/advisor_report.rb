class AdvisorReport < ApplicationRecord
  belongs_to :advisor_session

  validates :fit_score, presence: true,
                        numericality: { only_integer: true,
                                        greater_than_or_equal_to: 1,
                                        less_than_or_equal_to: 100 }
  validates :rationale,          presence: true
  validates :advisor_session_id, uniqueness: true
end
