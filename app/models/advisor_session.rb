class AdvisorSession < ApplicationRecord
  belongs_to :user
  has_one :advisor_report, dependent: :destroy

  validates :job_title,       presence: true
  validates :company_name,    presence: true
  validates :job_description, presence: true
  validates :job_description, length: { maximum: 8000 }
end
