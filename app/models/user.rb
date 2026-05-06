class User < ApplicationRecord
  has_secure_password

  has_one  :job_seeker_profile, dependent: :destroy
  has_many :advisor_sessions,   dependent: :destroy
  has_many :password_resets,    dependent: :destroy
  has_many :llm_requests,       dependent: :destroy

  before_save :downcase_email

  validates :email, presence: true, uniqueness: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true

  def first_name
    name.split.first
  end

  private

  def downcase_email
    self.email = email.downcase
  end
end
