FactoryBot.define do
  factory :advisor_report do
    association :advisor_session
    fit_score       { 72 }
    rationale       { "Strong GTM background offsets the P&L gap." }
    strengths       { JSON.dump(["GTM expertise", "Analyst relations", "Cross-functional leadership"]) }
    gaps            { JSON.dump(["No direct P&L ownership", "MBA not held"]) }
    resume_headline { "B2B SaaS Product Marketer Driving GTM Strategy" }
    outreach_draft  { "I wanted to reach out about the Director of Product Marketing role..." }
    gemini_raw      { '{"fit_score":72,"rationale":"Strong GTM background...","strengths":[],"gaps":[],"resume_headline":"","outreach_draft":""}' }
  end
end
