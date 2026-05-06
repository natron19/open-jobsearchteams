FactoryBot.define do
  factory :advisor_session do
    association :user
    job_title       { "Director of Product Marketing" }
    company_name    { "Acme Cloud" }
    job_description { "We are looking for a Director of Product Marketing to lead our GTM strategy." }
  end
end
