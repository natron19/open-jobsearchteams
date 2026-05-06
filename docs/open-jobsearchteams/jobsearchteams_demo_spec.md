# JobSearchTeams Demo - Product Requirements Document

**Document Version:** 1.0
**Last Updated:** May 1, 2026
**Built on:** Open Demo Starter v2.0
**License:** MIT

---

## 1. App Overview

JobSearchTeams Demo is a single-user, locally-runnable Rails 8 app that lets a signed-in job seeker paste any job description and receive a personalized AI career advisor session in return. The user provides a brief profile of their background once; from there they can analyze as many job listings as they want.

The core output is a structured advisor report: a fit score with rationale, three strengths to emphasize for the specific role, two gaps to address, a suggested resume headline tailored to the application, and a networking outreach message draft for a contact at that company. Every report is persisted so the user can revisit and compare assessments across roles.

The problem: most job seekers apply blindly without tailoring their approach to each role. A brief, targeted AI analysis turns a generic application into a strategically calibrated one. This demo isolates the AI advisor core of JobSearchTeams, a larger multi-tenant career support group platform the author is building. The production version adds team features, peer accountability groups, shared job boards, and coach-mediated sessions. This demo is scoped to one user, runs on localhost, and is open source under MIT license.

UX pattern: profile dashboard plus form-then-advisor-report. The user's profile is always visible as context. The job analysis form is the primary action. The result page is the payoff.

---

## 2. Customizations Applied to the Boilerplate

- `APP_NAME=JobSearchTeams Demo`, `APP_TAGLINE=Paste a job description. Get a personalized AI career advisor session.`, `APP_DESCRIPTION=AI-powered job fit analysis for focused job seekers.` set in `.env.example`
- Accent color `#2563eb` (blue) with hover `#1d4ed8` set in `app/assets/stylesheets/_accent.scss`. Secondary lime `#84cc16` used for fit score badge and strength highlights only.
- Navbar links: "My Sessions" pointing to `/advisor_sessions`, "My Profile" pointing to `/profile`
- `home/index.html.erb` replaced with the JobSearchTeams landing pitch: problem statement, three-step explanation (fill profile, paste job, get report), and a single call-to-action button
- `dashboard/show.html.erb` replaced with a two-panel view: left panel shows profile summary; right panel shows the list of past advisor sessions
- UX pattern: profile-dashboard-plus-form-then-result
- AI templates seeded: `jobsearchteams_advisor_v1`

---

## 3. Data Model

### JobSeekerProfile

One record per user. Created on first sign-in via a redirect gate in `AdvisorSessionsController`.

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | Primary key |
| `user_id` | uuid | Foreign key; unique index (one profile per user) |
| `current_role` | string | **(template variable)** |
| `target_role` | string | **(template variable)** |
| `top_skills` | text | Comma-separated or freeform; **(template variable)** |
| `biggest_challenge` | text | **(template variable)** |
| `created_at` | datetime | |
| `updated_at` | datetime | |

**Associations:** `belongs_to :user`

**Validations:** `current_role` presence; `target_role` presence; `top_skills` presence; `biggest_challenge` presence; `user_id` uniqueness

---

### AdvisorSession

One record per job description the user submits. Stores the inputs to the Gemini call.

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | Primary key |
| `user_id` | uuid | Foreign key; indexed |
| `job_title` | string | **(template variable)** |
| `company_name` | string | **(template variable)** |
| `job_description` | text | **(template variable)**; max 8000 characters enforced at validation |
| `created_at` | datetime | |
| `updated_at` | datetime | |

**Associations:** `belongs_to :user`; `has_one :advisor_report, dependent: :destroy`

**Validations:** `job_title` presence; `company_name` presence; `job_description` presence; `job_description` length maximum 8000

---

### AdvisorReport

One record per AdvisorSession. Created immediately after a successful Gemini call in `AdvisorSessionsController#create`.

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | Primary key |
| `advisor_session_id` | uuid | Foreign key; unique index (one report per session) |
| `fit_score` | integer | 1 to 100; parsed from Gemini JSON output |
| `rationale` | text | Parsed from Gemini JSON output |
| `strengths` | text | JSON array stored as text; 3 items |
| `gaps` | text | JSON array stored as text; 2 items |
| `resume_headline` | string | Parsed from Gemini JSON output |
| `outreach_draft` | text | Parsed from Gemini JSON output |
| `gemini_raw` | text | **(Gemini output, used for Show raw response toggle)** |
| `created_at` | datetime | |
| `updated_at` | datetime | |

**Associations:** `belongs_to :advisor_session`

**Validations:** `fit_score` presence; `fit_score` numericality (integer, 1 to 100); `rationale` presence; `advisor_session_id` uniqueness

---

## 4. Routes

All HTML responses. Auth routes (`/sign_up`, `/sign_in`, `/sign_out`, `/passwords/*`) and admin routes (`/admin/*`) come from the boilerplate and are not listed here.

| Verb | Path | Controller#Action | Purpose |
|---|---|---|---|
| GET | `/` | `home#index` | Public landing page |
| GET | `/dashboard` | `dashboard#show` | Signed-in home with profile summary and session list |
| GET | `/profile` | `job_seeker_profiles#show` | View own profile; redirects to `#new` if none exists |
| GET | `/profile/new` | `job_seeker_profiles#new` | Profile setup form (first-time only) |
| POST | `/profile` | `job_seeker_profiles#create` | Save new profile |
| GET | `/profile/edit` | `job_seeker_profiles#edit` | Edit existing profile |
| PATCH | `/profile` | `job_seeker_profiles#update` | Save profile changes |
| GET | `/advisor_sessions` | `advisor_sessions#index` | List all sessions for current user |
| GET | `/advisor_sessions/new` | `advisor_sessions#new` | Job analysis form |
| POST | `/advisor_sessions` | `advisor_sessions#create` | Submit job description; triggers Gemini call |
| GET | `/advisor_sessions/:id` | `advisor_sessions#show` | Session detail with advisor report |

---

## 5. Controllers and Actions

### `JobSeekerProfilesController`

Inherits from `ApplicationController`. Scopes all queries to `current_user`.

- **`show`** - Finds `current_user.job_seeker_profile`; redirects to `new` if the record does not exist.
- **`new`** - Renders the profile creation form. Redirects to `show` if the user already has a profile.
- **`create`** - Builds `current_user.build_job_seeker_profile(profile_params)` and saves. On success, redirects to `dashboard_path` with a welcome flash. On failure, re-renders `new`.
- **`edit`** - Loads `current_user.job_seeker_profile`; 404 if not found.
- **`update`** - Saves changes to the existing profile. On success, redirects to `profile_path`. On failure, re-renders `edit`.

Strong parameters: `current_role`, `target_role`, `top_skills`, `biggest_challenge`.

---

### `AdvisorSessionsController`

Inherits from `ApplicationController`. Scopes all queries to `current_user`.

`before_action :require_profile` on `new` and `create` - redirects to `new_profile_path` with a flash notice if `current_user.job_seeker_profile` is nil.

- **`index`** - Loads `current_user.advisor_sessions.order(created_at: :desc)`. Eager-loads `:advisor_report` to avoid N+1 on the list.
- **`new`** - Renders the job analysis form. Pre-populates nothing.
- **`create`** - The primary AI action. Builds and saves an `AdvisorSession` with strong params. On save success, calls `GeminiService.generate(template: "jobsearchteams_advisor_v1", variables: {...})` with all profile fields and session fields as variables. Parses the JSON response, builds and saves an `AdvisorReport`, then redirects to `advisor_session_path(@session)`. Rescues `GeminiService::GeminiError` (and subclasses) and re-renders `new` with an inline alert partial and a retry button. On `AdvisorSession` save failure, re-renders `new` with validation errors.
- **`show`** - Loads `current_user.advisor_sessions.find(params[:id])`. Raises `ActiveRecord::RecordNotFound` (handled in `ApplicationController`) if the session belongs to a different user. Eager-loads `:advisor_report`.

Strong parameters: `job_title`, `company_name`, `job_description`.

---

## 6. Views

### `home/index.html.erb`

Public page. Two-column Bootstrap grid: left column has headline ("Job search without guesswork"), a three-step explanation (1. fill in your background; 2. paste a job description; 3. get a fit score plus actionable advice), and a "Get started" button. Right column has a placeholder screenshot card with caption. No Turbo or Stimulus behavior.

---

### `dashboard/show.html.erb`

Two-panel layout. Left panel: profile summary card showing `current_role`, `target_role`, `top_skills`, and `biggest_challenge`, with an "Edit profile" link. Right panel: advisor session list (most recent first) rendered via the `_session_card` partial, with a prominent "Analyze a new job" button at the top.

---

### `job_seeker_profiles/new.html.erb` and `_form.html.erb`

Single-column form with a brief explainer: "Tell us about your search so the AI advisor can personalize every analysis." Fields: current role (text input), target role (text input), top skills (textarea with placeholder "e.g., Python, product management, stakeholder communication"), biggest challenge (textarea). Submit button labeled "Save my profile".

`edit.html.erb` renders the shared `_form.html.erb` partial with the same layout.

---

### `job_seeker_profiles/show.html.erb`

Displays all four profile fields in a definition list card. Links to `edit_profile_path` and to `new_advisor_session_path`.

---

### `advisor_sessions/index.html.erb`

Bootstrap card grid. Each card rendered via `_session_card` partial. If no sessions exist, renders an empty-state card with a "Run your first analysis" call-to-action. Includes a "Analyze a new job" button in the page header.

---

### `advisor_sessions/_session_card.html.erb`

Card showing: job title, company name, fit score badge (color-coded by range: 80 plus is lime `#84cc16`, 60 to 79 is yellow, below 60 is muted), and relative timestamp. Links to the session show page.

---

### `advisor_sessions/new.html.erb`

Form with three fields: job title (text input), company name (text input), job description (large textarea with a "Paste the full job description here" placeholder). A profile context strip above the form shows the user's current_role and target_role in small muted text as a reminder. Submit button labeled "Analyze this job". Stimulus controller `character-counter` on the job description textarea shows remaining character count against the 8000-character limit.

---

### `advisor_sessions/show.html.erb`

The result page. Rendered only when `@session.advisor_report` exists.

Structure:
1. Header row: job title, company name, timestamp.
2. Fit score hero: large circular badge with the integer score and a color fill matching the range (lime/yellow/muted). Rationale text below the badge.
3. Three-column Bootstrap row: "Strengths" card (3 bullet points, lime left border), "Gaps" card (2 bullet points, yellow left border), and "Next Steps" card with resume headline (displayed in a blockquote) and a "Copy" button wired to a Stimulus `clipboard` controller.
4. Outreach draft card: full draft text in a `<pre>` block with a "Copy" button.
5. "Show raw response" Bootstrap collapse toggle revealing `@session.advisor_report.gemini_raw` in a `<pre>` block. This is required by the boilerplate's UX contract.
6. "Analyze another job" button linking to `new_advisor_session_path`.

No Turbo Frames or streams on this page. The Gemini call is synchronous in `create`; the show page is a standard redirect-after-create render.

---

### `shared/_gemini_error.html.erb`

Inherited from the boilerplate. Rendered on Gemini errors in `advisor_sessions/new.html.erb`. Shows the error type with a user-friendly message and a "Try again" button that re-submits.

---

## 7. AI Templates and Gemini Integration

### Template: `jobsearchteams_advisor_v1`

**Description:** Career advisor fit analysis. Scores a job seeker's profile against a job description and returns structured coaching output.

---

**System prompt:**

```
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
  "resume_headline": "<an 8 to 12 word headline the candidate could use as a resume summary title for this specific application. Do not use generic phrases like 'results-driven professional'.>",
  "outreach_draft": "<a 3 to 4 sentence LinkedIn connection request or cold email draft to a hypothetical contact at the company. Mention the specific role by name. Reference something concrete about the company or role that shows genuine interest. Do not be sycophantic.>"
}
```

---

**User prompt template:**

```
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
```

---

**Variables consumed:**

- `{{current_role}}` - `JobSeekerProfile#current_role`
- `{{target_role}}` - `JobSeekerProfile#target_role`
- `{{top_skills}}` - `JobSeekerProfile#top_skills`
- `{{biggest_challenge}}` - `JobSeekerProfile#biggest_challenge`
- `{{job_title}}` - `AdvisorSession#job_title`
- `{{company_name}}` - `AdvisorSession#company_name`
- `{{job_description}}` - `AdvisorSession#job_description`

**Model:** `gemini-2.0-flash`

**max_output_tokens:** 1200. The structured JSON output is bounded and predictable; 1200 tokens is sufficient headroom while keeping costs low.

**temperature:** 0.4. Lower than the default because the output is structured JSON and the advice should be grounded and consistent, not creatively varied. Higher temperatures produce hallucinated skill matches that feel plausible but are not grounded in the input.

**Notes:** The most common failure mode is the model returning generic strengths that are not tied to anything specific in the job description (e.g., "strong communication skills"). The system prompt's instruction to reference specific requirements mitigates this but should be monitored. The second failure mode is an inflated fit score - the model tends toward optimism. If scores cluster above 75 for weak matches, add a calibration sentence to the system prompt (e.g., "A fit_score of 50 means a realistic chance with positioning work; reserve 80 plus for candidates who meet most requirements directly"). The outreach draft tends to be too formal on the first iteration; the notes field in the admin UI is the right place to track successful prompt variants.

**Where it is called:** `AdvisorSessionsController#create`, after the `AdvisorSession` record is saved.

**Expected output format:** JSON object matching the schema above.

**How the response is parsed:** `JSON.parse(result)` in the controller. The parsed hash is used to build `AdvisorReport` field-by-field. `strengths` and `gaps` are stored as `JSON.dump(parsed["strengths"])` and `JSON.dump(parsed["gaps"])` respectively. The raw Gemini string is stored in `gemini_raw`. If `JSON.parse` raises, the controller rescues and re-renders `new` with an inline error ("The AI returned an unexpected format. Please try again.").

**Raw response stored in:** `AdvisorReport#gemini_raw`

---

## 8. AI Safety Considerations

### Content Sensitivity

Career advice is a moderately high-stakes domain. A job seeker acting on a poor fit score or a badly calibrated strengths assessment could underconfidently withdraw from a role they were qualified for, or overconfidently pursue a role they were far from ready for. The advice is consequential to livelihood but not to physical safety.

The outreach draft adds a secondary concern: a user who sends an AI-generated cold message without reading it could come across as generic or inauthentic, which damages their candidacy. The UI should make clear that the outreach draft is a starting point, not a finished message.

### App-Specific Disclaimers

The boilerplate footer already carries "AI-generated content can be incorrect. Verify before acting." This app adds a second disclaimer directly on the `advisor_sessions/show.html.erb` result page, placed above the fit score:

> "This analysis is AI-generated based on the text you provided. It reflects pattern matching against your profile and the job description - not a recruiter's judgment or inside knowledge of the company's hiring criteria. Use it as one input among many."

The outreach draft card adds a line below the draft:

> "Review and personalize before sending. Generic outreach messages reduce response rates."

### Tightened Settings

No change to the default 50-calls-per-day cap. Job seekers running many analyses in a day are the intended power users. The 8000-character limit on `job_description` is the primary abuse mitigation; most real job postings are 500 to 2000 characters, and the limit prevents a user from pasting entire resumes or unrelated documents as the "job description."

### What This Demo Deliberately Does Not Do

- **No coaching relationship simulation.** This is a one-shot analysis, not a persistent advisor agent with memory of prior sessions. The production version of JobSearchTeams includes coach-mediated group sessions; this demo does not simulate that relationship.
- **No competitive intelligence on companies.** The demo does not call a search API to enrich the company name with real data. A user asking about a company they dislike or a competitor is not a concern at this scope.
- **No resume parsing or upload.** The user describes their background in freeform text. Parsing uploaded PDFs introduces Active Storage and PII complexity that is out of scope for this demo.
- **No verification of the job description's authenticity.** A user could paste fabricated text. This is acceptable for a local demo; a production deployment would add source URL verification.
- **No emotional support or mental health framing.** Job searching is stressful. This demo does not attempt to acknowledge distress or offer encouragement; it stays in the analytical lane. A production peer support feature would require a separate, carefully designed experience.

---

## 9. RSpec Outline

### `spec/models/job_seeker_profile_spec.rb`

- Validates presence of `current_role`, `target_role`, `top_skills`, `biggest_challenge`
- Enforces uniqueness of `user_id` (one profile per user)
- `belongs_to :user` association
- Valid profile with all fields saves successfully

### `spec/models/advisor_session_spec.rb`

- Validates presence of `job_title`, `company_name`, `job_description`
- Validates `job_description` length maximum 8000 characters
- `belongs_to :user` and `has_one :advisor_report` associations
- Dependent destroy: deleting a session deletes its report

### `spec/models/advisor_report_spec.rb`

- Validates presence of `fit_score` and `rationale`
- Validates `fit_score` is an integer between 1 and 100
- Enforces uniqueness of `advisor_session_id`
- `belongs_to :advisor_session` association

### `spec/requests/advisor_sessions_spec.rb`

- `GET /advisor_sessions/new` redirects to `/profile/new` if the user has no profile
- `POST /advisor_sessions` with valid params, stubbed Gemini response: creates an `AdvisorSession`, creates an `AdvisorReport`, redirects to the session show path
- `POST /advisor_sessions` with a stubbed `GeminiService::TimeoutError`: re-renders `new` with an error alert, does not create an `AdvisorReport`
- `POST /advisor_sessions` with a stubbed `GeminiService::BudgetExceededError`: re-renders `new` with the budget-exceeded message
- `GET /advisor_sessions/:id` returns 404 when the session belongs to a different user (access control)
- `POST /advisor_sessions` creates exactly one `LlmRequest` record per call (verifies logging integration)

### `spec/requests/job_seeker_profiles_spec.rb`

- `GET /profile` redirects to `/profile/new` if no profile exists
- `GET /profile` renders the show page if the profile exists
- `POST /profile` with valid params creates the profile and redirects to dashboard
- `POST /profile` with missing fields re-renders `new` with validation errors
- `PATCH /profile` with valid params updates the profile and redirects to show

---

## 10. Seed Data

### AiTemplate Seed

`db/seeds.rb` creates the `jobsearchteams_advisor_v1` template with the exact `system_prompt`, `user_prompt_template`, `model`, `max_output_tokens`, `temperature`, and `notes` values defined in Section 7.

### Domain Seeds

`db/seeds.rb` also creates one `JobSeekerProfile` and three `AdvisorSession` records (with their `AdvisorReport` records) attached to the seeded demo user, so the app shows a realistic populated state on first run.

**Seeded JobSeekerProfile:**
- `current_role`: "Senior Marketing Manager"
- `target_role`: "Director of Product Marketing"
- `top_skills`: "Go-to-market strategy, competitive positioning, cross-functional leadership, B2B SaaS, analyst relations"
- `biggest_challenge`: "Most director roles ask for P&L ownership experience I do not have yet; I am unsure how to position my indirect revenue influence"

**Seeded AdvisorSessions (sample values for one session):**
- `job_title`: "Director of Product Marketing"
- `company_name`: "Acme Cloud"
- `job_description`: A 600-word realistic job posting for a Director of Product Marketing at a B2B SaaS company, describing responsibilities for GTM strategy, competitive intelligence, analyst briefings, and cross-functional alignment, with requirements for 7 plus years of experience and a preferred MBA.

**Seeded AdvisorReport (for the above session):**
- `fit_score`: 72
- `rationale`: Seeded with a sample rationale referencing the candidate's GTM strengths against the role's P&L requirement gap.
- `strengths`: JSON array with three role-specific strengths.
- `gaps`: JSON array with two gaps including mitigation suggestions.
- `resume_headline`: "B2B SaaS Product Marketer Driving GTM Strategy and Analyst Relations"
- `outreach_draft`: A sample three-sentence outreach message.
- `gemini_raw`: The full raw JSON string from which the above fields were parsed.

Two additional seeded sessions use different roles (a UX researcher targeting a Principal Researcher role, and a software engineer targeting an engineering manager role) to demonstrate that the tool works across career tracks.

---

## 11. README Additions

### App Name and Tagline

**JobSearchTeams Demo** - Paste a job description. Get a personalized AI career advisor session.

---

### Description

JobSearchTeams Demo is a single-user Rails 8 app that turns job searching from a spray-and-pray activity into a targeted, informed process. Fill in a brief profile of your current role, target role, and skills. Paste any job description. Get back a fit score, three strengths to lead with, two gaps to address, a tailored resume headline, and a networking outreach draft - all specific to that role and your background.

---

### Screenshot

[Screenshot placeholder: advisor report showing fit score badge, strengths and gaps cards, resume headline, and outreach draft on a dark Bootstrap layout]

---

### Why I Built This

Job seekers I know spend hours applying to roles without ever pressure-testing their candidacy against the job description. A 10-second AI check catches the mismatches before the application goes out and surfaces the angles worth emphasizing.

This is a demo of the AI advisor core from JobSearchTeams, a larger multi-tenant platform I am building for career support groups - teams of job seekers who hold each other accountable, share leads, and give each other feedback. The full product lives at [jobsearchteams.com](https://jobsearchteams.com) (placeholder). This demo isolates the AI fit analysis feature, ships as a clean Rails app you can clone and run in five minutes, and is open source under MIT license. If you find it useful or want to improve the prompt, open a pull request.

---

### Editing the AI Prompt

The career advisor prompt is stored as an `AiTemplate` record, not hardcoded. Sign in as `demo@example.com` / `password123`, navigate to `/admin/ai_templates`, click `jobsearchteams_advisor_v1`, and use the live test panel to try different prompt variants. The right-hand panel lets you enter sample variable values, call Gemini, and see the response immediately without restarting the server.

---

### No Additional Setup Steps

Beyond `bin/setup`, no extra API keys or services are required. Set `GEMINI_API_KEY` in `.env` (copy from `.env.example`). That is the only required credential. The Gemini free tier is sufficient for typical demo use.

---

## 12. Bootstrap Dark Mode and Accent Color Notes

### Component Approach

This app is form-heavy with a structured result display. Component choices follow the "profile dashboard plus form-then-result" pattern:

- **Dashboard:** Two-column grid (`col-md-4` profile, `col-md-8` session list). Profile summary in a `card` with `card-body`. Session list as a `row g-3` card grid.
- **Session cards:** Bootstrap `card` with a `badge` for the fit score and `text-muted` for timestamps.
- **New session form:** Single-column `card` with `card-body`. `form-control` inputs. Character counter for the job description textarea uses `text-muted small` and updates via Stimulus.
- **Result page:** Fit score displayed as a large `display-4` number inside a `rounded-circle` div with an inline background color. Strengths and gaps in `list-group` items inside `card` components. Resume headline in a `blockquote`. Outreach draft in a `pre` inside a `card`.

### Accent Color Application

- `--accent: #2563eb` and `--accent-hover: #1d4ed8` set in `_accent.scss`
- Applied to: primary buttons (`btn-primary`), active navbar links, focus ring on form inputs, fit score badge text for scores above 80
- Secondary lime `#84cc16` applied only to: fit score badge background for scores above 80, left border on the "Strengths" card. Applied as inline style or a utility class in `_accent.scss` (`.text-lime` and `.border-lime`). Not applied to interactive elements to avoid color-meaning confusion.
- Scores 60 to 79: `--bs-warning` yellow for the fit score badge.
- Scores below 60: `--bs-secondary` muted for the fit score badge.

### Custom CSS

Beyond the accent color override, one additional rule in `_accent.scss`:

```css
.fit-score-circle {
  width: 96px;
  height: 96px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  font-size: 2rem;
  font-weight: 700;
}
```

All other styling uses Bootstrap utility classes. No custom layout CSS beyond the accent file.

---

*v1.0 - JobSearchTeams Demo spec. Built on Open Demo Starter v2.0. Open source under MIT license.*
