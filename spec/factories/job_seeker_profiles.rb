FactoryBot.define do
  factory :job_seeker_profile do
    association :user
    current_role      { "Senior Marketing Manager" }
    target_role       { "Director of Product Marketing" }
    top_skills        { "Go-to-market strategy, competitive positioning, B2B SaaS" }
    biggest_challenge { "Lack of direct P&L ownership experience" }
  end
end
