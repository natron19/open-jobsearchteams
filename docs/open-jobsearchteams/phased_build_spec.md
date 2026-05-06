# JobSearchTeams Demo — Phased Build Specification

**Based on:** `docs/open-jobsearchteams/jobsearchteams_demo_spec.md` v1.0  
**Boilerplate:** Open Demo Starter v2.0  
**Build order:** Each phase completes before the next starts. Manual smoke tests and RSpec tests are required at the end of each phase before proceeding.

---

## Technical Notes Before Building

### Model Name Override
The product spec (§7) specifies `gemini-2.0-flash`. **Do not use this.** Per `docs/ai-templates.md`, `gemini-2.0-flash` returns 404 on v1beta for new API keys. Use `gemini-2.5-flash` instead.

### AiGatekeeper Length Conflict
`AiGatekeeper` enforces a 5000-character input limit on the rendered prompt. The `job_description` field alone allows up to 8000 characters. The full rendered template (profile fields + job description) will routinely exceed 5000 characters for real job postings.

**Resolution:** In Phase 6, raise `AiGatekeeper::MAX_INPUT_LENGTH` to `12000` to accommodate the largest valid input (8000 char job description + ~1000 chars of profile fields + template scaffolding). Document this change inline.

### No SCSS Compilation
The boilerplate uses Propshaft — no SCSS compilation pipeline. The spec mentions `_accent.scss`. All CSS goes in `app/assets/stylesheets/application.css` directly.

### Singular Profile Resource
`/profile` uses a singular resource-style routing (no `:id` in URLs) because each user has exactly one profile. Routes are defined explicitly (not via `resource :profile`) to keep the paths exactly as specified in the PRD.

---

## Phase 1: Boilerplate Customization

**Goal:** Stamp this boilerplate as JobSearchTeams Demo. No new models or controllers yet.

### Tasks

**1.1 — Environment variables**  
Update `.env.example`:
```
APP_NAME=JobSearchTeams Demo
APP_TAGLINE=Paste a job description. Get a personalized AI career advisor session.
APP_DESCRIPTION=AI-powered job fit analysis for focused job seekers.
GEMINI_API_KEY=your-gemini-api-key-here
AI_CALLS_PER_USER_PER_DAY=50
AI_GLOBAL_TIMEOUT_SECONDS=15
```

**1.2 — Accent color and custom CSS**  
Update `app/assets/stylesheets/application.css`:
- Set `--accent: #2563eb` and `--accent-hover: #1d4ed8`
- Add `.text-lime { color: #84cc16; }` and `.border-lime { border-color: #84cc16 !important; }`
- Add `.fit-score-circle` rule (96×96px, flex center, 50% border-radius, 2rem bold font)

**1.3 — Navbar links**  
Update `app/views/layouts/application.html.erb` navbar section to include:
- "My Sessions" → `advisor_sessions_path` (only shown when signed in)
- "My Profile" → `profile_path` (only shown when signed in)

**1.4 — README update**  
Replace `README.md` content with the JobSearchTeams Demo README from spec §11. Keep the stack table and AI safety section from the boilerplate README — append the JobSearchTeams-specific sections.

### Manual Tests
- [ ] `bin/rails server` starts without errors
- [ ] Landing page (`/`) loads with boilerplate content still in place (home view not yet replaced)
- [ ] Navbar shows "My Sessions" and "My Profile" links when signed in as `demo@example.com`
- [ ] Accent color is visibly blue (`#2563eb`) on buttons and active links

### RSpec Tests
None for this phase — no new application logic introduced.

---

## Phase 2: Data Models and Migrations

**Goal:** Create all three domain models with correct schema, associations, and validations.

### Tasks

**2.1 — Migration: `create_job_seeker_profiles`**
```ruby
create_table :job_seeker_profiles, id: :uuid do |t|
  t.references :user, null: false, foreign_key: true, type: :uuid
  t.string :current_role, null: false
  t.string :target_role, null: false
  t.text :top_skills, null: false
  t.text :biggest_challenge, null: false
  t.timestamps null: false
end
add_index :job_seeker_profiles, :user_id, unique: true
```

**2.2 — Migration: `create_advisor_sessions`**
```ruby
create_table :advisor_sessions, id: :uuid do |t|
  t.references :user, null: false, foreign_key: true, type: :uuid
  t.string :job_title, null: false
  t.string :company_name, null: false
  t.text :job_description, null: false
  t.timestamps null: false
end
add_index :advisor_sessions, :created_at
```

**2.3 — Migration: `create_advisor_reports`**
```ruby
create_table :advisor_reports, id: :uuid do |t|
  t.references :advisor_session, null: false, foreign_key: true, type: :uuid
  t.integer :fit_score, null: false
  t.text :rationale, null: false
  t.text :strengths
  t.text :gaps
  t.string :resume_headline
  t.text :outreach_draft
  t.text :gemini_raw
  t.timestamps null: false
end
add_index :advisor_reports, :advisor_session_id, unique: true
```

**2.4 — Model: `JobSeekerProfile`**
```ruby
class JobSeekerProfile < ApplicationRecord
  belongs_to :user
  validates :current_role, presence: true
  validates :target_role, presence: true
  validates :top_skills, presence: true
  validates :biggest_challenge, presence: true
  validates :user_id, uniqueness: true
end
```

**2.5 — Model: `AdvisorSession`**
```ruby
class AdvisorSession < ApplicationRecord
  belongs_to :user
  has_one :advisor_report, dependent: :destroy
  validates :job_title, presence: true
  validates :company_name, presence: true
  validates :job_description, presence: true
  validates :job_description, length: { maximum: 8000 }
end
```

**2.6 — Model: `AdvisorReport`**
```ruby
class AdvisorReport < ApplicationRecord
  belongs_to :advisor_session
  validates :fit_score, presence: true,
    numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 100 }
  validates :rationale, presence: true
  validates :advisor_session_id, uniqueness: true
end
```

**2.7 — User model updates**  
Add to `app/models/user.rb`:
```ruby
has_one :job_seeker_profile, dependent: :destroy
has_many :advisor_sessions, dependent: :destroy
```

**2.8 — FactoryBot factories**

`spec/factories/job_seeker_profiles.rb`:
```ruby
FactoryBot.define do
  factory :job_seeker_profile do
    association :user
    current_role      { "Senior Marketing Manager" }
    target_role       { "Director of Product Marketing" }
    top_skills        { "GTM strategy, competitive positioning, B2B SaaS" }
    biggest_challenge { "Lack of direct P&L ownership experience" }
  end
end
```

`spec/factories/advisor_sessions.rb`:
```ruby
FactoryBot.define do
  factory :advisor_session do
    association :user
    job_title       { "Director of Product Marketing" }
    company_name    { "Acme Cloud" }
    job_description { "We are looking for a Director of Product Marketing..." }
  end
end
```

`spec/factories/advisor_reports.rb`:
```ruby
FactoryBot.define do
  factory :advisor_report do
    association :advisor_session
    fit_score       { 72 }
    rationale       { "Strong GTM background offsets the P&L gap." }
    strengths       { JSON.dump(["GTM expertise", "Analyst relations", "Cross-functional leadership"]) }
    gaps            { JSON.dump(["No P&L ownership", "MBA not held"]) }
    resume_headline { "B2B SaaS Product Marketer Driving GTM Strategy" }
    outreach_draft  { "I wanted to reach out about the Director of Product Marketing role..." }
    gemini_raw      { '{"fit_score":72,"rationale":"Strong GTM background..."}' }
  end
end
```

### Manual Tests
- [ ] `bin/rails db:migrate` runs without errors
- [ ] Rails console: `JobSeekerProfile.new.valid?` returns false (validations work)
- [ ] Rails console: `AdvisorSession.new(job_description: "x" * 8001).valid?` returns false (length validation)
- [ ] Rails console: `AdvisorReport.new(fit_score: 101).valid?` returns false (numericality)
- [ ] Rails console: create a full profile + session + report chain and verify associations

### RSpec Tests

**`spec/models/job_seeker_profile_spec.rb`**
- validates presence of `current_role`, `target_role`, `top_skills`, `biggest_challenge`
- validates uniqueness of `user_id`
- `belongs_to :user`
- valid factory saves successfully

**`spec/models/advisor_session_spec.rb`**
- validates presence of `job_title`, `company_name`, `job_description`
- validates `job_description` length maximum 8000 characters
- `belongs_to :user`
- `has_one :advisor_report`
- dependent destroy: deleting a session destroys its report

**`spec/models/advisor_report_spec.rb`**
- validates presence of `fit_score` and `rationale`
- validates `fit_score` is integer between 1 and 100 (rejects 0 and 101)
- validates uniqueness of `advisor_session_id`
- `belongs_to :advisor_session`

---

## Phase 3: Routes

**Goal:** Wire up all URL paths before writing controllers or views.

### Tasks

**3.1 — Profile routes**  
Add to `config/routes.rb` (explicit paths, singular profile per user):
```ruby
get   "/profile",      to: "job_seeker_profiles#show",  as: :profile
get   "/profile/new",  to: "job_seeker_profiles#new",   as: :new_profile
post  "/profile",      to: "job_seeker_profiles#create"
get   "/profile/edit", to: "job_seeker_profiles#edit",  as: :edit_profile
patch "/profile",      to: "job_seeker_profiles#update"
```

**3.2 — Advisor session routes**
```ruby
resources :advisor_sessions, only: [:index, :new, :create, :show]
```

**3.3 — Verify named helpers**  
Running `bin/rails routes` must produce all paths from spec §4. Check that these helpers exist:
- `profile_path`, `new_profile_path`, `edit_profile_path`
- `advisor_sessions_path`, `new_advisor_session_path`, `advisor_session_path(:id)`

### Manual Tests
- [ ] `bin/rails routes | grep profile` shows all five profile routes
- [ ] `bin/rails routes | grep advisor` shows index, new, create, show for advisor_sessions
- [ ] No routing conflicts with boilerplate routes (sign_in, sign_up, dashboard, admin)

### RSpec Tests
None for this phase — routes are covered by request specs in later phases.

---

## Phase 4: Controllers

**Goal:** Implement all controller logic. AI call stubbed out in `AdvisorSessionsController#create` for now (wired in Phase 6).

### Tasks

**4.1 — `JobSeekerProfilesController`**

```ruby
class JobSeekerProfilesController < ApplicationController
  def show
    @profile = current_user.job_seeker_profile
    redirect_to new_profile_path unless @profile
  end

  def new
    redirect_to profile_path if current_user.job_seeker_profile
    @profile = JobSeekerProfile.new
  end

  def create
    @profile = current_user.build_job_seeker_profile(profile_params)
    if @profile.save
      redirect_to dashboard_path, notice: "Profile saved! Now analyze your first job."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @profile = current_user.job_seeker_profile
    render file: Rails.public_path.join("404.html"), status: :not_found unless @profile
  end

  def update
    @profile = current_user.job_seeker_profile
    if @profile.update(profile_params)
      redirect_to profile_path, notice: "Profile updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:job_seeker_profile).permit(:current_role, :target_role, :top_skills, :biggest_challenge)
  end
end
```

**4.2 — `AdvisorSessionsController`**

```ruby
class AdvisorSessionsController < ApplicationController
  before_action :require_profile, only: [:new, :create]

  def index
    @sessions = current_user.advisor_sessions.includes(:advisor_report).order(created_at: :desc)
  end

  def new
    @session = AdvisorSession.new
    @profile = current_user.job_seeker_profile
  end

  def create
    @session = current_user.advisor_sessions.build(session_params)
    @profile = current_user.job_seeker_profile

    unless @session.save
      render :new, status: :unprocessable_entity and return
    end

    # AI call — implemented in Phase 6. Placeholder redirect for now.
    redirect_to advisor_session_path(@session)
  end

  def show
    @session = current_user.advisor_sessions.includes(:advisor_report).find(params[:id])
  end

  private

  def require_profile
    unless current_user.job_seeker_profile
      redirect_to new_profile_path, notice: "Please complete your profile before analyzing jobs."
    end
  end

  def session_params
    params.require(:advisor_session).permit(:job_title, :company_name, :job_description)
  end
end
```

**4.3 — `DashboardController#show` update**  
Update `app/controllers/dashboard_controller.rb`:
```ruby
def show
  @profile = current_user.job_seeker_profile
  @sessions = current_user.advisor_sessions.includes(:advisor_report).order(created_at: :desc).limit(10)
end
```

### Manual Tests
- [ ] Sign in as `demo@example.com`; visiting `/profile/new` renders the form (no error)
- [ ] `POST /profile` with valid params redirects to `/dashboard`
- [ ] `GET /profile` redirects to `/profile/new` when no profile exists
- [ ] `GET /advisor_sessions/new` redirects to `/profile/new` when no profile exists
- [ ] `GET /advisor_sessions/new` renders the form after creating a profile
- [ ] `GET /advisor_sessions` loads without error (empty list)
- [ ] `GET /dashboard` loads without error (profile + sessions variables available)

### RSpec Tests
None required for controllers in isolation at this phase — covered fully by request specs in Phase 7.

---

## Phase 5: Views and Stimulus Controllers

**Goal:** All pages render correctly. All forms submit. Character counter and clipboard Stimulus controllers work.

### Tasks

**5.1 — `home/index.html.erb`** (replace boilerplate placeholder)

Two-column Bootstrap grid:
- Left: headline "Job search without guesswork", three-step explanation (fill profile / paste job description / get fit score), "Get started" button → `sign_up_path`
- Right: placeholder card with caption "Sample advisor report"
- No Turbo or Stimulus behavior on this page

**5.2 — `dashboard/show.html.erb`** (replace boilerplate content)

Two-panel layout (`col-md-4` / `col-md-8`):
- Left: profile summary card showing all four fields, "Edit profile" link → `edit_profile_path`. If no profile, show "Set up your profile" prompt linking to `new_profile_path`.
- Right: heading + "Analyze a new job" button → `new_advisor_session_path`. Render `_session_card` partial for each session in `@sessions`. Empty-state message if no sessions.

**5.3 — `job_seeker_profiles/` views**

`_form.html.erb`:
- Brief explainer text above the form
- Fields: `current_role` (text_field), `target_role` (text_field), `top_skills` (text_area, placeholder), `biggest_challenge` (text_area)
- Submit button: "Save my profile"

`new.html.erb`: renders `_form.html.erb` with heading "Set up your profile"

`edit.html.erb`: renders `_form.html.erb` with heading "Edit your profile"

`show.html.erb`: definition-list card with all four fields, links to `edit_profile_path` and `new_advisor_session_path`

**5.4 — `advisor_sessions/index.html.erb`**

- Page header with "My Sessions" heading + "Analyze a new job" button
- Bootstrap card grid rendering `_session_card` partial for each session
- Empty state card if `@sessions.empty?` with "Run your first analysis" CTA → `new_advisor_session_path`

**5.5 — `advisor_sessions/_session_card.html.erb`**

Bootstrap card showing:
- Job title (card title)
- Company name (card subtitle)
- Fit score badge (color-coded: lime bg `#84cc16` for 80+, `warning` for 60–79, `secondary` for <60). Only show badge if `session.advisor_report` exists.
- Relative timestamp (`time_ago_in_words`)
- Link to `advisor_session_path(session)`

**5.6 — `advisor_sessions/new.html.erb`**

- Profile context strip above the form (shows `@profile.current_role` → `@profile.target_role` in small muted text)
- Single-column form card with three fields:
  - `job_title` (text_field)
  - `company_name` (text_field)
  - `job_description` (text_area, large, placeholder "Paste the full job description here")
- Character counter on `job_description`: `data-controller="character-counter"` wired Stimulus controller showing remaining chars against 8000 limit
- Submit button: "Analyze this job"

**5.7 — `advisor_sessions/show.html.erb`**

Structure (only rendered if `@session.advisor_report` present; otherwise show a "report pending" state):

1. Header: job title + company name + timestamp
2. AI disclaimer (above fit score): _"This analysis is AI-generated based on the text you provided. It reflects pattern matching against your profile and the job description — not a recruiter's judgment or inside knowledge of the company's hiring criteria. Use it as one input among many."_
3. Fit score hero: `.fit-score-circle` div with large score, color-coded background (lime/warning/secondary). Rationale text below.
4. Three-column row:
   - Strengths card: 3 bullet points from `JSON.parse(@session.advisor_report.strengths)`, left border lime
   - Gaps card: 2 bullet points from `JSON.parse(@session.advisor_report.gaps)`, left border warning
   - Next Steps card: resume headline in `<blockquote>` with "Copy" button wired to Stimulus `clipboard` controller
5. Outreach draft card: `<pre>` with draft text + "Copy" button + disclaimer _"Review and personalize before sending. Generic outreach messages reduce response rates."_
6. Bootstrap collapse toggle: "Show raw response" → reveals `@session.advisor_report.gemini_raw` in `<pre>`
7. "Analyze another job" button → `new_advisor_session_path`

**5.8 — Stimulus controller: `character-counter`**

`app/javascript/controllers/character_counter_controller.js`:
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "counter"]
  static values  = { max: { type: Number, default: 8000 } }

  connect() {
    this.update()
  }

  update() {
    const remaining = this.maxValue - this.inputTarget.value.length
    this.counterTarget.textContent = `${remaining} characters remaining`
    this.counterTarget.classList.toggle("text-danger", remaining < 200)
  }
}
```

Usage in `new.html.erb`:
```erb
<div data-controller="character-counter" data-character-counter-max-value="8000">
  <%= f.text_area :job_description,
      class: "form-control",
      rows: 12,
      placeholder: "Paste the full job description here",
      data: { character_counter_target: "input", action: "input->character-counter#update" } %>
  <div class="text-muted small mt-1" data-character-counter-target="counter"></div>
</div>
```

**5.9 — Stimulus controller: `clipboard`**

`app/javascript/controllers/clipboard_controller.js`:
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "button"]

  copy() {
    navigator.clipboard.writeText(this.sourceTarget.textContent).then(() => {
      const original = this.buttonTarget.textContent
      this.buttonTarget.textContent = "Copied!"
      setTimeout(() => { this.buttonTarget.textContent = original }, 2000)
    })
  }
}
```

Usage for resume headline:
```erb
<div data-controller="clipboard">
  <blockquote data-clipboard-target="source">
    <%= @session.advisor_report.resume_headline %>
  </blockquote>
  <button class="btn btn-sm btn-outline-secondary"
          data-clipboard-target="button"
          data-action="click->clipboard#copy">Copy</button>
</div>
```

### Manual Tests
- [ ] `/` renders two-column landing page with "Get started" button
- [ ] `/dashboard` shows profile summary (left) and session list (right); shows empty-state if no sessions
- [ ] `/profile/new` renders form with all four fields
- [ ] Submitting the profile form with all fields creates the profile and redirects to dashboard
- [ ] Submitting the profile form with missing fields re-renders with error messages
- [ ] `/profile` shows all four profile fields
- [ ] `/profile/edit` renders the form pre-filled
- [ ] `/advisor_sessions` shows empty state with CTA when no sessions
- [ ] `/advisor_sessions/new` shows profile context strip with current/target role
- [ ] Character counter decrements as you type in the job description field
- [ ] Character counter turns red when < 200 characters remain
- [ ] `/advisor_sessions/new` form submission creates an AdvisorSession (report will be missing until Phase 6)
- [ ] `/advisor_sessions/:id` renders without error (no report yet — shows "report pending" state)
- [ ] Copy button on show page copies text and changes label to "Copied!"
- [ ] "Show raw response" collapse toggle shows/hides raw JSON

### RSpec Tests
None required at this phase — UI structure is verified by manual tests and covered by request specs in Phase 7.

---

## Phase 6: AI Integration and Seed Data

**Goal:** Wire the Gemini call, parse the JSON response, and populate the app with realistic seed data.

### Tasks

**6.1 — AiGatekeeper: raise input length limit**  
In `app/services/ai_gatekeeper.rb`, change:
```ruby
MAX_INPUT_LENGTH = 5000
```
to:
```ruby
MAX_INPUT_LENGTH = 12000
# Raised from 5000 to accommodate job description inputs up to 8000 chars
# plus profile context and template scaffolding (~1200 chars).
```

**6.2 — `db/seeds.rb`: add AI template**  
Remove `demo_placeholder_v1` seed block. Add:

```ruby
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
  t.model            = "gemini-2.5-flash"
  t.max_output_tokens = 1200
  t.temperature      = 0.4
  t.notes            = "Called by AdvisorSessionsController#create. Output is JSON; controller parses with JSON.parse. Common failure: generic strengths not tied to the JD. Second failure: inflated fit scores. If scores cluster above 75 for weak matches, add a calibration sentence to the system prompt."
end

puts "Seeded: jobsearchteams_advisor_v1 AI template"
```

**6.3 — `db/seeds.rb`: domain seed data**

After the template seeds, add:

```ruby
# Domain seed data — realistic populated state
demo_user = User.find_by!(email: "demo@example.com")

profile = JobSeekerProfile.find_or_create_by!(user: demo_user) do |p|
  p.current_role      = "Senior Marketing Manager"
  p.target_role       = "Director of Product Marketing"
  p.top_skills        = "Go-to-market strategy, competitive positioning, cross-functional leadership, B2B SaaS, analyst relations"
  p.biggest_challenge = "Most director roles ask for P&L ownership experience I do not have yet; I am unsure how to position my indirect revenue influence"
end

# Session 1 — primary demo (marketing manager targeting PMM director)
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

# Session 2 — UX researcher targeting principal researcher role
jd_designco = <<~JD.strip
  DesignCo is looking for a Principal UX Researcher to lead our research practice for our consumer mobile app (12M DAU). You will own the research roadmap, mentor 2 junior researchers, and partner with Product and Design to translate insights into product decisions. Mixed methods required.
JD

session2 = AdvisorSession.find_or_create_by!(user: demo_user, job_title: "Principal UX Researcher", company_name: "DesignCo") do |s|
  s.job_description = jd_designco
end

raw2 = {
  fit_score: 45,
  rationale: "The candidate's marketing background does not map to UX research methodology, mentorship of researchers, or consumer product work. This is a significant pivot that requires direct acknowledgment.",
  strengths: [
    "Cross-functional collaboration experience is transferable to partnering with Product and Design teams.",
    "Competitive positioning work involves some user insight synthesis, which shows adjacent analytical skills.",
    "GTM strategy background provides strong understanding of user behavior from a business lens."
  ],
  gaps: [
    "No stated UX research methodology experience (usability studies, diary studies, survey design). Mitigation: if the candidate has informal research experience, surface it explicitly; otherwise this application is premature without upskilling.",
    "Mentorship of junior researchers is listed as a core responsibility — the candidate has no stated people management experience in a research context. Mitigation: highlight any marketing team mentorship or intern supervision as a bridge."
  ],
  resume_headline: "Cross-Functional Marketing Leader Pivoting to User Research Practice",
  outreach_draft: "I am reaching out about the Principal UX Researcher role at DesignCo. My background is in product marketing with a strong user insight component, and I am actively building formal UX research skills to make this transition. I would appreciate your perspective on what the research team values most in a principal-level hire."
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

# Session 3 — Software engineer targeting engineering manager role
jd_techcorp = <<~JD.strip
  TechCorp seeks an Engineering Manager for our payments infrastructure team. You will manage a team of 6 engineers, own delivery for quarterly roadmap items, drive technical design reviews, and partner with Product on capacity planning. Prior hands-on engineering in payments or fintech required.
JD

session3 = AdvisorSession.find_or_create_by!(user: demo_user, job_title: "Engineering Manager, Payments", company_name: "TechCorp") do |s|
  s.job_description = jd_techcorp
end

raw3 = {
  fit_score: 81,
  rationale: "Strong technical depth and cross-functional leadership experience maps well to the EM role. The candidate's go-to-market background is unusual for an engineering manager but demonstrates business acumen that complements technical delivery ownership.",
  strengths: [
    "Cross-functional leadership matches the EM expectation of partnering with Product on capacity planning.",
    "B2B SaaS experience provides commercial context for payments infrastructure trade-offs.",
    "Demonstrated ownership of complex initiatives aligns with quarterly roadmap delivery accountability."
  ],
  gaps: [
    "No stated hands-on engineering background in payments or fintech — a hard requirement. Mitigation: be transparent in the application about background; focus on the transferable systems thinking.",
    "People management of engineers is not explicitly stated in the candidate profile. Mitigation: surface any indirect technical mentorship or cross-functional project leadership as evidence of EM readiness."
  ],
  resume_headline: "Technical GTM Leader Ready to Drive Engineering Team Delivery",
  outreach_draft: "I am reaching out about the Engineering Manager, Payments role at TechCorp. My background is at the intersection of technical product work and cross-functional delivery leadership, and I am drawn to TechCorp's payments infrastructure given its scale and the technical complexity of the team's roadmap. I would value a conversation about how the team approaches the transition from IC to manager."
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

puts "Seeded: 1 JobSeekerProfile, 3 AdvisorSessions, 3 AdvisorReports"
```

**6.4 — `AdvisorSessionsController#create`: wire the AI call**

Replace the placeholder redirect with the full AI flow:

```ruby
def create
  @session = current_user.advisor_sessions.build(session_params)
  @profile = current_user.job_seeker_profile

  unless @session.save
    render :new, status: :unprocessable_entity and return
  end

  result = GeminiService.generate(
    template:  "jobsearchteams_advisor_v1",
    variables: {
      current_role:      @profile.current_role,
      target_role:       @profile.target_role,
      top_skills:        @profile.top_skills,
      biggest_challenge: @profile.biggest_challenge,
      job_title:         @session.job_title,
      company_name:      @session.company_name,
      job_description:   @session.job_description
    }
  )

  parsed = JSON.parse(result)
  @session.create_advisor_report!(
    fit_score:       parsed["fit_score"],
    rationale:       parsed["rationale"],
    strengths:       JSON.dump(parsed["strengths"]),
    gaps:            JSON.dump(parsed["gaps"]),
    resume_headline: parsed["resume_headline"],
    outreach_draft:  parsed["outreach_draft"],
    gemini_raw:      result
  )
  redirect_to advisor_session_path(@session)

rescue JSON::ParseError
  @session.destroy
  flash.now[:alert] = "The AI returned an unexpected format. Please try again."
  render :new, status: :unprocessable_entity

rescue GeminiService::BudgetExceededError
  @session.destroy
  render :new, locals: { gemini_error: :budget_exceeded }, status: :unprocessable_entity

rescue GeminiService::GatekeeperError
  @session.destroy
  render :new, locals: { gemini_error: :gatekeeper_blocked }, status: :unprocessable_entity

rescue GeminiService::TimeoutError
  @session.destroy
  render :new, locals: { gemini_error: :timeout }, status: :unprocessable_entity

rescue GeminiService::GeminiError
  @session.destroy
  render :new, locals: { gemini_error: :error }, status: :unprocessable_entity
end
```

Update `advisor_sessions/new.html.erb` to render error partial when `gemini_error` local is present:
```erb
<% if local_assigns[:gemini_error] %>
  <%= render "shared/ai_error", error_type: gemini_error %>
<% end %>
```

**6.5 — Run seeds**

After implementing the above:
```bash
bin/rails db:seed
```

### Manual Tests
- [ ] `bin/rails db:seed` runs without errors
- [ ] Sign in as `demo@example.com`; dashboard shows profile summary and 3 seeded sessions
- [ ] Three sessions appear in `/advisor_sessions` with correctly color-coded fit score badges (72 = yellow, 45 = muted, 81 = lime)
- [ ] Session show page for the 72-score Acme Cloud session renders all sections: fit score, rationale, 3 strengths, 2 gaps, headline, outreach
- [ ] "Show raw response" collapse reveals the raw JSON string
- [ ] Copy button for resume headline copies text and flips to "Copied!"
- [ ] Submit the real job analysis form with your GEMINI_API_KEY set — confirm a real Gemini response is parsed and an AdvisorReport is created
- [ ] Verify `LlmRequest` record is created in admin panel at `/admin/llm_requests`
- [ ] Test timeout path: temporarily set `AI_GLOBAL_TIMEOUT_SECONDS=0` and submit — should show timeout error and not create an orphaned AdvisorSession
- [ ] Test budget path: in admin console, create 50 LlmRequests for the demo user today and submit — should show budget-exceeded message

### RSpec Tests

Write `spec/services/ai_gatekeeper_spec.rb` updates (if MAX_INPUT_LENGTH changed):
- Verify 12000-char input does not raise
- Verify 12001-char input raises

---

## Phase 7: RSpec Test Suite

**Goal:** Full test coverage for all new models and request flows. Zero real API calls.

### Tasks

**7.1 — `spec/models/job_seeker_profile_spec.rb`**

```ruby
RSpec.describe JobSeekerProfile, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:current_role) }
    it { is_expected.to validate_presence_of(:target_role) }
    it { is_expected.to validate_presence_of(:top_skills) }
    it { is_expected.to validate_presence_of(:biggest_challenge) }
    it { is_expected.to validate_uniqueness_of(:user_id) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  it "saves a valid profile" do
    expect(build(:job_seeker_profile)).to be_valid
  end
end
```

**7.2 — `spec/models/advisor_session_spec.rb`**

```ruby
RSpec.describe AdvisorSession, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:job_title) }
    it { is_expected.to validate_presence_of(:company_name) }
    it { is_expected.to validate_presence_of(:job_description) }
    it { is_expected.to validate_length_of(:job_description).is_at_most(8000) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_one(:advisor_report).dependent(:destroy) }
  end

  it "destroys the report when the session is destroyed" do
    session = create(:advisor_session)
    create(:advisor_report, advisor_session: session)
    expect { session.destroy }.to change(AdvisorReport, :count).by(-1)
  end
end
```

**7.3 — `spec/models/advisor_report_spec.rb`**

```ruby
RSpec.describe AdvisorReport, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:fit_score) }
    it { is_expected.to validate_presence_of(:rationale) }
    it { is_expected.to validate_numericality_of(:fit_score)
           .only_integer.is_greater_than_or_equal_to(1).is_less_than_or_equal_to(100) }
    it { is_expected.to validate_uniqueness_of(:advisor_session_id) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:advisor_session) }
  end
end
```

**7.4 — `spec/requests/job_seeker_profiles_spec.rb`**

```ruby
RSpec.describe "JobSeekerProfiles", type: :request do
  let(:user) { create(:user) }

  describe "GET /profile" do
    it "redirects to sign in when unauthenticated" do
      get profile_path
      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects to /profile/new when no profile exists" do
      sign_in_as(user)
      get profile_path
      expect(response).to redirect_to(new_profile_path)
    end

    it "renders show when a profile exists" do
      sign_in_as(user)
      create(:job_seeker_profile, user: user)
      get profile_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /profile/new" do
    it "redirects to show when profile already exists" do
      sign_in_as(user)
      create(:job_seeker_profile, user: user)
      get new_profile_path
      expect(response).to redirect_to(profile_path)
    end
  end

  describe "POST /profile" do
    let(:valid_params) do
      { job_seeker_profile: {
          current_role: "Engineer",
          target_role: "Senior Engineer",
          top_skills: "Ruby, Rails",
          biggest_challenge: "Not enough senior roles nearby"
      } }
    end

    it "redirects to sign in when unauthenticated" do
      post profile_path, params: valid_params
      expect(response).to redirect_to(sign_in_path)
    end

    it "creates the profile and redirects to dashboard with valid params" do
      sign_in_as(user)
      expect {
        post profile_path, params: valid_params
      }.to change(JobSeekerProfile, :count).by(1)
      expect(response).to redirect_to(dashboard_path)
    end

    it "re-renders new with validation errors for missing fields" do
      sign_in_as(user)
      post profile_path, params: { job_seeker_profile: { current_role: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /profile" do
    let!(:profile) { create(:job_seeker_profile, user: user) }

    it "updates the profile and redirects to show" do
      sign_in_as(user)
      patch profile_path, params: { job_seeker_profile: { current_role: "Updated Role" } }
      expect(response).to redirect_to(profile_path)
      expect(profile.reload.current_role).to eq("Updated Role")
    end
  end
end
```

**7.5 — `spec/requests/advisor_sessions_spec.rb`**

```ruby
RSpec.describe "AdvisorSessions", type: :request do
  let(:user)    { create(:user) }
  let(:profile) { create(:job_seeker_profile, user: user) }

  let(:valid_params) do
    { advisor_session: {
        job_title: "Product Manager",
        company_name: "Acme",
        job_description: "We are looking for a PM..."
    } }
  end

  let(:gemini_response) do
    {
      fit_score: 75,
      rationale: "Good match.",
      strengths: ["Skill A", "Skill B", "Skill C"],
      gaps: ["Gap A", "Gap B"],
      resume_headline: "Product Manager Driving B2B Growth",
      outreach_draft: "I wanted to reach out about the PM role..."
    }.to_json
  end

  describe "GET /advisor_sessions/new" do
    it "redirects to sign in when unauthenticated" do
      get new_advisor_session_path
      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects to /profile/new when no profile exists" do
      sign_in_as(user)
      get new_advisor_session_path
      expect(response).to redirect_to(new_profile_path)
    end

    it "renders the form when a profile exists" do
      sign_in_as(user)
      profile
      get new_advisor_session_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /advisor_sessions" do
    before do
      sign_in_as(user)
      profile
    end

    context "with valid params and a successful Gemini response" do
      before { gemini_returns(gemini_response) }

      it "creates an AdvisorSession and an AdvisorReport" do
        expect {
          post advisor_sessions_path, params: valid_params
        }.to change(AdvisorSession, :count).by(1)
          .and change(AdvisorReport, :count).by(1)
      end

      it "redirects to the session show path" do
        post advisor_sessions_path, params: valid_params
        expect(response).to redirect_to(advisor_session_path(AdvisorSession.last))
      end

      it "creates exactly one LlmRequest record" do
        expect {
          post advisor_sessions_path, params: valid_params
        }.to change(LlmRequest, :count).by(1)
      end
    end

    context "when Gemini raises TimeoutError" do
      before { gemini_raises(GeminiService::TimeoutError) }

      it "re-renders new without creating an AdvisorReport" do
        expect {
          post advisor_sessions_path, params: valid_params
        }.not_to change(AdvisorReport, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "does not leave an orphaned AdvisorSession" do
        expect {
          post advisor_sessions_path, params: valid_params
        }.not_to change(AdvisorSession, :count)
      end
    end

    context "when Gemini raises BudgetExceededError" do
      before { gemini_raises(GeminiService::BudgetExceededError) }

      it "re-renders new with the budget-exceeded message" do
        post advisor_sessions_path, params: valid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("budget")
      end
    end
  end

  describe "GET /advisor_sessions/:id" do
    it "redirects to sign in when unauthenticated" do
      session = create(:advisor_session, user: user)
      get advisor_session_path(session)
      expect(response).to redirect_to(sign_in_path)
    end

    it "returns 404 when the session belongs to a different user" do
      sign_in_as(user)
      other_user    = create(:user)
      other_session = create(:advisor_session, user: other_user)
      expect {
        get advisor_session_path(other_session)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "renders the show page for the owner" do
      sign_in_as(user)
      session = create(:advisor_session, user: user)
      create(:advisor_report, advisor_session: session)
      get advisor_session_path(session)
      expect(response).to have_http_status(:ok)
    end
  end
end
```

### Manual Tests (Final acceptance checklist)
- [ ] `bundle exec rspec` passes with 0 failures, 0 real API calls
- [ ] Full end-to-end: sign up as a new user → set up profile → submit a job description → view the advisor report
- [ ] All three seeded sessions display correct badge colors on the index and dashboard
- [ ] Admin panel at `/admin/llm_requests` shows all LlmRequest rows from seeded data and test runs
- [ ] Admin panel at `/admin/ai_templates` shows `jobsearchteams_advisor_v1` and `health_ping`
- [ ] `/admin/ai_templates` test panel works: entering sample variable values and clicking "Run Test" returns a real Gemini response
- [ ] Sign out and visit `/advisor_sessions` — redirected to sign in
- [ ] Sign in as a second user (create one via `/sign_up`) — cannot see the first user's sessions (404)

---

## Build Order Summary

| Phase | Focus | Gate to Next Phase |
|---|---|---|
| 1 | Boilerplate customization (env, CSS, nav, README) | Server starts, navbar correct |
| 2 | Data models, migrations, factories | Migrations clean, model specs pass |
| 3 | Routes | `rails routes` shows all expected paths |
| 4 | Controllers (no AI) | All CRUD flows work without errors |
| 5 | Views and Stimulus controllers | All pages render, forms submit, JS interactions work |
| 6 | AI integration + seed data | Live Gemini call succeeds, seeded data populates |
| 7 | RSpec test suite | Full suite passes, zero real API calls |

---

*JobSearchTeams Demo — Phased Build Spec v1.0*  
*Cross-references: `docs/open-jobsearchteams/jobsearchteams_demo_spec.md`, `docs/ai-templates.md`, `docs/ai-guardrails.md`, `docs/testing.md`, `docs/turbo-stimulus-patterns.md`*
