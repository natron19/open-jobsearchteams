class JobSeekerProfile < ApplicationRecord
  belongs_to :user

  validates :current_role,      presence: true
  validates :target_role,       presence: true
  validates :top_skills,        presence: true
  validates :biggest_challenge, presence: true
  validates :user_id,           uniqueness: true
end
