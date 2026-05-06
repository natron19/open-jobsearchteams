# JobSearchTeams Demo

> Paste a job description. Get a personalized AI career advisor session.

## Description

JobSearchTeams Demo is a single-user Rails 8 app that turns job searching from a spray-and-pray activity into a targeted, informed process. Fill in a brief profile of your current role, target role, and skills. Paste any job description. Get back a fit score, three strengths to lead with, two gaps to address, a tailored resume headline, and a networking outreach draft — all specific to that role and your background.

## Quick Start

1. Clone this repo
2. Run `bin/setup`
3. Copy `.env.example` to `.env` and add your Gemini API key
4. `bin/rails db:seed`
5. `bin/rails server`
6. Visit http://localhost:3000 and sign in with `demo@example.com` / `password123`

## Screenshot

_[Screenshot placeholder: advisor report showing fit score badge, strengths and gaps cards, resume headline, and outreach draft on a dark Bootstrap layout]_

## Why I Built This

Job seekers I know spend hours applying to roles without ever pressure-testing their candidacy against the job description. A 10-second AI check catches the mismatches before the application goes out and surfaces the angles worth emphasizing.

This is a demo of the AI advisor core from JobSearchTeams, a larger multi-tenant platform I am building for career support groups — teams of job seekers who hold each other accountable, share leads, and give each other feedback. The full product lives at [jobsearchteams.com](https://jobsearchteams.com) (placeholder). This demo isolates the AI fit analysis feature, ships as a clean Rails app you can clone and run in five minutes, and is open source under MIT license. If you find it useful or want to improve the prompt, open a pull request.

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `APP_NAME` | `"JobSearchTeams Demo"` | Displayed in the navbar and title |
| `APP_TAGLINE` | — | Shown in the footer |
| `APP_DESCRIPTION` | — | Shown on the landing page |
| `GEMINI_API_KEY` | (required) | Your Google Gemini API key — get one free at https://aistudio.google.com/app/apikey |
| `AI_CALLS_PER_USER_PER_DAY` | `50` | Daily AI call budget per user |
| `AI_GLOBAL_TIMEOUT_SECONDS` | `15` | Gemini request timeout in seconds |

## Stack

| Layer | Choice |
|---|---|
| Framework | Rails 8.1 |
| Database | PostgreSQL with UUID primary keys |
| Auth | Rails native (`has_secure_password`, sessions) |
| CSS | Bootstrap 5 dark mode (CDN) |
| JavaScript | Stimulus + Turbo via importmap |
| AI | Google Gemini via `gemini-ai` gem |
| Queue / Cache / Cable | Solid Stack (no Redis) |
| Testing | RSpec |

## Editing the AI Prompt

The career advisor prompt is stored as an `AiTemplate` record, not hardcoded. Sign in as `demo@example.com` / `password123`, navigate to `/admin/ai_templates`, click `jobsearchteams_advisor_v1`, and use the live test panel to try different prompt variants. The right-hand panel lets you enter sample variable values, call Gemini, and see the response immediately without restarting the server.

## AI Safety Posture

**What this app enforces:**
- Per-user daily call cap (default: 50/day, set via `AI_CALLS_PER_USER_PER_DAY`)
- Pre-flight gatekeeper: input length limit, prompt injection patterns, profanity filter
- Hard output token cap per template (1200 tokens for the advisor template)
- Configurable request timeout (default: 15s)
- Full request log with status, tokens, duration, and cost estimate
- Fail-soft UI: errors render an inline alert, never crash the page
- AI disclaimer on every page and directly on the advisor report

**Deliberately omitted (with rationale):**
- No PII scrubbing — demo apps have no production user data
- No content moderation API — Gemini's built-in safety filters are sufficient
- No automatic retries — avoids stacking costs on transient failures
- No RAG or vector DB — single-shot prompts only
- No streaming — synchronous calls keep the code simple

## No Additional Setup Steps

Beyond `bin/setup`, no extra API keys or services are required. Set `GEMINI_API_KEY` in `.env` (copy from `.env.example`). That is the only required credential. The Gemini free tier is sufficient for typical demo use.

## License

MIT — see [LICENSE](LICENSE)
