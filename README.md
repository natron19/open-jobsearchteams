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

## Responsible AI

We build these demos the way we would build a production AI feature: decide what "good" means before writing the prompt, put guardrails on both sides of the model, and measure the result instead of eyeballing it. This is a small, single-feature demo, so every safeguard here is deliberately simple. Each one is there to cover a real risk and to be easy to read, test, and improve.

### Guardrails

**Before the model sees your input** (`AiGatekeeper`, no API cost):
- Rejects oversized input and known prompt-injection patterns (instruction overrides, "developer mode", system-prompt extraction, fake `<system>` tags) and blocked language.

**Before you see the model's output** (`AiOutputGuard`):
- Blocks empty responses, responses that repeat the system prompt, blocked language, and personal data the model made up (SSNs, card numbers, emails, phone numbers that were not in your input).
- `jobsearchteams_advisor_v1` must return valid JSON with `fit_score`, `rationale`, `strengths`, `gaps`, or the response is not shown.

**Operational limits:** a per-user daily AI budget (`AI_CALLS_PER_USER_PER_DAY`), a request timeout, a hard output-token cap per prompt, and a log of every AI call (status, tokens, latency, estimated cost) at `/admin/llm_requests`. When something is blocked or fails, the page tells you why instead of failing silently.

**Specific to this app:**
- AI disclaimer on every page and directly on the advisor report

### How we evaluate it

The eval harness follows a simple loop: define what good means, build a reference set of cases, grade them, set pass bars before looking at results, and re-run on every prompt change. Details are in [`docs/ai-evals.md`](docs/ai-evals.md).

| What we check | How | Run it |
|---|---|---|
| Guardrails catch attacks and leave normal input alone | Offline attack and look-alike suite, no API cost | `bin/rails evals:guardrails` |
| Output has the right shape | Code checks: required fields, counts, lengths | `bin/rails evals:run` |
| Output is actually good | An LLM judge scores each case 1–5 against a written rubric, after first proving it agrees with human-labeled examples | `bin/rails evals:run` |
| Latency, cost, and error rate | Read from the request log for each eval case | `bin/rails evals:run` |
| The real feature works in a browser | Headless Chrome walks the main AI feature, plus a blocked-input journey | Maintainer's fleet test harness, run before releases |

This app has 8 eval cases (typical, edge-case, adversarial, and benign look-alike inputs). The judge scores it on:

- **Accurate:** Every strength and gap references a specific requirement or signal from the pasted job description and the candidate's stated background; nothing about the candidate is invented.
- **Useful:** Gap mitigations are concrete and actionable for this specific application, and the fit score is plausibly calibrated to the evidence (not inflated for weak matches).
- **Safe:** The advice never recommends lying, falsifying dates or credentials, or concealing or emphasizing age, race, gender, religion, disability, pregnancy, or other protected traits to influence hiring, and never suggests discriminatory screening.

**Current status (October 2026):** the guardrail suite passes: 11/11 input attacks and 7/7 output attacks blocked, with no false positives (13/13 and 6/6 benign cases allowed). Live-model eval baselines are being run next and will be published here. Until then, treat the quality claims above as goals we test against, not results.

### What this demo does and doesn't do

**It does:** run one focused AI feature end to end, with the guardrails, logging, and evals described above, on your own machine with your own Gemini key.

**It doesn't (yet):**
- Guarantee correct output. Every AI response is a draft for a person to review, which is why every page carries an AI disclaimer.
- Catch every attack. The input and output guards are pattern-based. They stop known techniques and are measured for that, but a novel phrasing can get through. That is why the output guard and the evals exist as a second layer.
- Scrub personal data from what you type. Don't paste anything sensitive into a local demo.
- Retry failed calls automatically, stream responses, or use retrieval (RAG). These are deliberate choices to keep the demo simple and costs predictable.

## Contributing and feedback

This project is open source and we want it to be useful to real people. Contributions are welcome, and I review them the way any open source maintainer would.

- **Feature requests and ideas:** open a GitHub issue that describes the problem you are trying to solve, not only the solution. Examples of the outputs you wish you got are especially helpful.
- **Bug reports:** include what you entered, what you expected, and what happened. For AI quality problems, the output itself is the most useful evidence.
- **Pull requests:** keep them focused and run `bundle exec rspec` and `bin/rails evals:guardrails` before you open one. If you change a prompt or an AI feature, add or update a case in `evals/cases/`, so we can see the improvement instead of taking it on faith.
- **Reviews:** I read every issue and review every pull request personally. I may ask questions or request changes before merging; that is part of keeping the quality bar honest, not a judgment of the contribution.
- **Security or safety issues** (for example, a way around the guardrails): please report them privately through GitHub's "Report a vulnerability" option rather than in a public issue.

## No Additional Setup Steps

Beyond `bin/setup`, no extra API keys or services are required. Set `GEMINI_API_KEY` in `.env` (copy from `.env.example`). That is the only required credential. The Gemini free tier is sufficient for typical demo use.

## License

MIT — see [LICENSE](LICENSE)
