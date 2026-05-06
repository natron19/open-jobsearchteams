# Admin user — credentials for local demo use only
User.find_or_create_by!(email: "demo@example.com") do |u|
  u.name                  = "Demo User"
  u.password              = "password123"
  u.password_confirmation = "password123"
  u.admin                 = true
end

puts "Demo user: demo@example.com / password123"

# Health ping template — used by /up/llm
AiTemplate.find_or_create_by!(name: "health_ping") do |t|
  t.description          = "Minimal prompt used by the /up/llm health check endpoint."
  t.system_prompt        = "You are a health check endpoint. Respond with exactly: ok"
  t.user_prompt_template = "ping"
  t.model                = "gemini-2.5-flash"
  t.max_output_tokens    = 10
  t.temperature          = 0.0
  t.notes                = "Do not modify. Used by HealthController#llm."
end

puts "Seeded: health_ping AI template"

# JobSearchTeams advisor template
AiTemplate.find_or_create_by!(name: "jobsearchteams_advisor_v1") do |t|
  t.description = "Career advisor fit analysis. Scores a job seeker's profile against a job description and returns structured coaching output."
  t.system_prompt = <<~PROMPT.strip
    You are a senior career advisor who specializes in job search strategy, resume positioning, and professional networking. You give honest, specific, and actionable advice. You never give generic coaching that could apply to any candidate - every observation you make must reference either the candidate's stated background or a specific requirement or signal from the job description they provided.

    Your output is a JSON object. Return valid JSON only. No markdown code fences, no prose outside the JSON. All fields are required.

    JSON schema:
    {
      "fit_score": <integer from 1 to 100. 90 to 100 means the candidate is an unusually strong match. 70 to 89 means solid match with minor gaps. 50 to 69 means plausible match that requires positioning work. Below 50 means significant gaps that need direct acknowledgment.>,
      "rationale": "<2 to 3 sentences explaining the score. Reference specific requirements from the job description and specific elements of the candidate's background. Be direct.>",
      "strengths": [
        "<strength 1 tied to a specific requirement in the job description>",
        "<strength 2 tied to a specific requirement in the job description>",
        "<strength 3 tied to a specific requirement in the job description>"
      ],
      "gaps": [
        "<gap 1 description plus a concrete mitigation suggestion (e.g., frame it this way, highlight this instead, address it proactively in cover letter)>",
        "<gap 2 description plus a concrete mitigation suggestion>"
      ],
      "resume_headline": "<an 8 to 12 word headline the candidate could use as a resume summary title for this specific application. Do not use generic phrases like results-driven professional.>",
      "outreach_draft": "<a 3 to 4 sentence LinkedIn connection request or cold email draft to a hypothetical contact at the company. Mention the specific role by name. Reference something concrete about the company or role that shows genuine interest. Do not be sycophantic.>"
    }
  PROMPT
  t.user_prompt_template = <<~PROMPT.strip
    Candidate profile:
    - Current role: {{current_role}}
    - Target role: {{target_role}}
    - Top skills: {{top_skills}}
    - Biggest challenge in their job search: {{biggest_challenge}}

    Job they are evaluating:
    - Job title: {{job_title}}
    - Company: {{company_name}}
    - Full job description:
    {{job_description}}

    Analyze this candidate's fit for this specific role. Return your response as a JSON object matching the schema above.
  PROMPT
  t.model             = "gemini-2.5-flash"
  t.max_output_tokens = 1200
  t.temperature       = 0.4
  t.notes             = "Called by AdvisorSessionsController#create. Output is JSON; controller parses with JSON.parse. Common failure: generic strengths not tied to the JD. Second failure: inflated fit scores. If scores cluster above 75 for weak matches, add a calibration sentence to the system prompt."
end

puts "Seeded: jobsearchteams_advisor_v1 AI template"

# ── Domain seed data ────────────────────────────────────────────────────────────
demo_user = User.find_by!(email: "demo@example.com")

profile = JobSeekerProfile.find_or_create_by!(user: demo_user) do |p|
  p.current_role      = "Senior Marketing Manager"
  p.target_role       = "Director of Product Marketing"
  p.top_skills        = "Go-to-market strategy, competitive positioning, cross-functional leadership, B2B SaaS, analyst relations"
  p.biggest_challenge = "Most director roles ask for P&L ownership experience I do not have yet; I am unsure how to position my indirect revenue influence"
end

puts "Seeded: JobSeekerProfile for demo user"

# Session 1 — marketing manager targeting PMM director (score 72, yellow)
jd_acme = <<~JD.strip
  Acme Cloud is seeking a Director of Product Marketing to lead our GTM strategy for our enterprise data platform. You will own competitive intelligence, analyst briefings (Gartner, Forrester), and cross-functional alignment with Sales, Product, and Customer Success. You will define messaging and positioning for our flagship product line and drive enablement across a 200-person sales organization.

  Responsibilities: Lead GTM strategy for product launches. Own analyst relations program. Develop competitive intelligence function. Partner with Product to shape roadmap messaging. Drive sales enablement materials and training. Manage a team of 3 product marketers.

  Requirements: 7+ years of B2B SaaS product marketing experience. Proven track record of successful enterprise product launches. Experience with analyst briefings and inquiries. Strong cross-functional leadership skills. MBA preferred. P&L ownership experience a strong plus.
JD

session1 = AdvisorSession.find_or_create_by!(user: demo_user, job_title: "Director of Product Marketing", company_name: "Acme Cloud") do |s|
  s.job_description = jd_acme
end

raw1 = {
  fit_score: 72,
  rationale: "Strong GTM and analyst relations background directly maps to this role's core requirements. The gap is the P&L ownership preference — the candidate's indirect revenue influence needs to be explicitly quantified and positioned as equivalent impact.",
  strengths: [
    "7+ years of B2B SaaS product marketing experience aligns directly with the seniority requirement; GTM strategy ownership is a stated core responsibility.",
    "Analyst relations experience (Gartner, Forrester) is explicitly listed as a key requirement and matches the candidate's stated skills in analyst relations.",
    "Cross-functional leadership with Sales, Product, and Customer Success mirrors the candidate's stated top skills and the role's collaboration requirements."
  ],
  gaps: [
    "P&L ownership is listed as 'a strong plus' — the candidate lacks direct ownership. Mitigation: quantify indirect revenue impact (e.g., 'influenced $X ARR through GTM programs') and address it directly in the cover letter rather than leaving it to the interviewer's imagination.",
    "MBA is preferred but not required. Mitigation: no action needed unless the role explicitly requires it; the candidate's experience level compensates."
  ],
  resume_headline: "B2B SaaS Product Marketer Driving GTM Strategy and Analyst Relations",
  outreach_draft: "I wanted to reach out about the Director of Product Marketing role at Acme Cloud. I have spent seven years leading GTM strategy and analyst relations for B2B SaaS products, and Acme's enterprise data platform launch trajectory is exactly the type of challenge I am looking for at the director level. I would welcome a brief conversation about the team's priorities for the first 90 days."
}.to_json

AdvisorReport.find_or_create_by!(advisor_session: session1) do |r|
  parsed = JSON.parse(raw1)
  r.fit_score       = parsed["fit_score"]
  r.rationale       = parsed["rationale"]
  r.strengths       = JSON.dump(parsed["strengths"])
  r.gaps            = JSON.dump(parsed["gaps"])
  r.resume_headline = parsed["resume_headline"]
  r.outreach_draft  = parsed["outreach_draft"]
  r.gemini_raw      = raw1
end

# Session 2 — UX researcher targeting principal researcher (score 45, muted)
jd_designco = <<~JD.strip
  DesignCo is looking for a Principal UX Researcher to lead our research practice for our consumer mobile app (12M DAU). You will own the research roadmap, mentor 2 junior researchers, and partner with Product and Design to translate insights into product decisions. Mixed methods required. 5+ years of UX research experience required, ideally in consumer apps.
JD

session2 = AdvisorSession.find_or_create_by!(user: demo_user, job_title: "Principal UX Researcher", company_name: "DesignCo") do |s|
  s.job_description = jd_designco
end

raw2 = {
  fit_score: 45,
  rationale: "The candidate's marketing background does not map to UX research methodology, mentorship of researchers, or consumer product work at scale. This is a significant pivot that requires direct acknowledgment and active upskilling.",
  strengths: [
    "Cross-functional collaboration experience is transferable to partnering with Product and Design teams on insight synthesis.",
    "Competitive positioning work involves adjacent user behavior analysis, demonstrating analytical aptitude.",
    "GTM strategy background provides strong understanding of user behavior from a business and market lens."
  ],
  gaps: [
    "No stated UX research methodology experience (usability studies, diary studies, survey design) — a hard requirement. Mitigation: if informal research experience exists, surface it explicitly; otherwise this application is premature without targeted upskilling.",
    "Mentoring junior researchers is a core responsibility and the candidate has no stated people management in a research context. Mitigation: highlight any cross-functional mentorship or intern supervision as a bridge to demonstrate people development instincts."
  ],
  resume_headline: "Cross-Functional Marketing Leader Pivoting to User Research Practice",
  outreach_draft: "I am reaching out about the Principal UX Researcher role at DesignCo. My background is in product marketing with a strong user insight component, and I am actively building formal UX research skills to make this transition. I would appreciate your perspective on what the research team values most in a principal-level hire from a non-traditional background."
}.to_json

AdvisorReport.find_or_create_by!(advisor_session: session2) do |r|
  parsed = JSON.parse(raw2)
  r.fit_score       = parsed["fit_score"]
  r.rationale       = parsed["rationale"]
  r.strengths       = JSON.dump(parsed["strengths"])
  r.gaps            = JSON.dump(parsed["gaps"])
  r.resume_headline = parsed["resume_headline"]
  r.outreach_draft  = parsed["outreach_draft"]
  r.gemini_raw      = raw2
end

# Session 3 — software engineer targeting engineering manager (score 81, lime)
jd_techcorp = <<~JD.strip
  TechCorp seeks an Engineering Manager for our payments infrastructure team. You will manage a team of 6 engineers, own delivery for quarterly roadmap items, drive technical design reviews, and partner with Product on capacity planning. Prior hands-on engineering in payments or fintech strongly preferred. 3+ years of engineering management experience required.
JD

session3 = AdvisorSession.find_or_create_by!(user: demo_user, job_title: "Engineering Manager, Payments", company_name: "TechCorp") do |s|
  s.job_description = jd_techcorp
end

raw3 = {
  fit_score: 81,
  rationale: "Strong technical depth and cross-functional leadership experience maps well to the EM role requirements. The candidate's GTM background is unusual for an engineering manager but demonstrates business acumen that directly supports the Product partnership and capacity planning expectations.",
  strengths: [
    "Cross-functional leadership experience maps directly to the EM expectation of partnering with Product on capacity planning and roadmap alignment.",
    "B2B SaaS product context provides commercial awareness for payments infrastructure trade-off decisions.",
    "Demonstrated ownership of complex, multi-stakeholder initiatives aligns with quarterly roadmap delivery accountability across a team of 6."
  ],
  gaps: [
    "No stated hands-on engineering background in payments or fintech — listed as strongly preferred. Mitigation: be transparent in the cover letter; emphasize adjacent systems thinking and the ability to quickly develop domain context.",
    "3+ years of engineering management is required — the candidate's people management experience should be explicitly quantified. Mitigation: surface any team or project leadership that involved direct management of engineers, even in a hybrid or informal capacity."
  ],
  resume_headline: "Technical GTM Leader Ready to Drive Engineering Team Delivery",
  outreach_draft: "I am reaching out about the Engineering Manager, Payments role at TechCorp. My background spans technical product work and cross-functional delivery leadership, and I am drawn to TechCorp's payments infrastructure given its scale and the complexity of the team's roadmap. I would value a conversation about how the team approaches the IC-to-manager transition and what the first-quarter delivery focus looks like."
}.to_json

AdvisorReport.find_or_create_by!(advisor_session: session3) do |r|
  parsed = JSON.parse(raw3)
  r.fit_score       = parsed["fit_score"]
  r.rationale       = parsed["rationale"]
  r.strengths       = JSON.dump(parsed["strengths"])
  r.gaps            = JSON.dump(parsed["gaps"])
  r.resume_headline = parsed["resume_headline"]
  r.outreach_draft  = parsed["outreach_draft"]
  r.gemini_raw      = raw3
end

puts "Seeded: 3 AdvisorSessions with AdvisorReports (scores: 72, 45, 81)"
