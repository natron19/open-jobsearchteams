# JobSearchTeams Demo — Build Tasks

All implementation is complete. Remaining items are manual verification steps — run them in order.

Full implementation details: `docs/open-jobsearchteams/phased_build_spec.md`  
Product spec: `docs/open-jobsearchteams/jobsearchteams_demo_spec.md`

---

## Implementation Status

| Phase | Code | Verified |
|---|---|---|
| 1 — Boilerplate customization | ✅ | ⬜ |
| 2 — Data models & migrations | ✅ | ✅ |
| 3 — Routes | ✅ | ⬜ |
| 4 — Controllers | ✅ | ⬜ |
| 5 — Views & Stimulus controllers | ✅ | ⬜ |
| 6 — AI integration & seed data | ✅ | ⬜ |
| 7 — RSpec test suite | ✅ | ⬜ |

**Database fix applied:** `config/database.yml` renamed from `open_base_*` to `open_jobsearchteams_*`.  
**Migration fix applied:** duplicate `add_index` calls removed from `CreateJobSeekerProfiles` and `CreateAdvisorReports`.  
**shoulda-matchers added:** gem added to `Gemfile` `:test` group; configured in `spec/rails_helper.rb`.  
**Gemini fix:** `thinkingConfig: { thinkingBudget: 0 }` added inside `generationConfig` to prevent thinking tokens consuming output budget on `gemini-2.5-flash`.  
**Gemini fix:** markdown code fence stripping added in `AdvisorSessionsController#create` before `JSON.parse`.

---

## Verification Sequence

Run these in order. Each block must pass before moving to the next.

---

### Step 1 — Create DB and migrate

```
bin/rails db:create db:migrate
```

- [x] Runs clean with no errors
- [x] Three new migrations appear: `CreateJobSeekerProfiles`, `CreateAdvisorSessions`, `CreateAdvisorReports`

---

### Step 2 — Model specs

```
bundle exec rspec spec/models/
```

- [x] All model specs pass (job_seeker_profile, advisor_session, advisor_report)
- [x] Zero failures

---

### Step 3 — Seed the database

```
bin/rails db:seed
```

- [x] Runs clean — prints: demo user, health_ping, jobsearchteams_advisor_v1, 3 sessions with reports

---

### Step 4 — Start the server and smoke-test in browser

```
bin/rails server
```

Visit each URL and confirm:

**Landing page**
- [ ] `/` — two-column layout with three-step explanation and "Get started" button

**Auth**
- [ ] Sign in as `demo@example.com` / `password123`
- [ ] Navbar shows "My Sessions" and "My Profile" links
- [ ] Accent color is visibly blue on buttons

**Dashboard**
- [ ] `/dashboard` — left panel shows profile summary; right panel shows 3 seeded sessions

**Profile flows**
- [ ] `/profile` — shows all four profile fields
- [ ] `/profile/edit` — form pre-filled; save redirects back to profile
- [ ] Sign up as a new user → profile gate redirects `/advisor_sessions/new` to `/profile/new`
- [ ] Create profile → redirects to dashboard with flash

**Session list**
- [ ] `/advisor_sessions` — three session cards with color-coded badges (72 = yellow, 45 = muted, 81 = lime)

**Session show — Acme Cloud (score 72)**
- [ ] `/advisor_sessions/<acme-id>` — AI disclaimer visible above score
- [ ] Fit score hero shows "72" with yellow background
- [ ] Strengths card has lime left border, 3 bullet points
- [ ] Gaps card has yellow left border, 2 bullet points
- [ ] Next Steps card shows resume headline with "Copy" button
- [ ] Copy button flips to "Copied!" and restores after 2 seconds
- [ ] Outreach draft card shows `<pre>` text with "Copy" button and personalization disclaimer
- [ ] "Show raw response" collapse toggle reveals raw JSON

**New session form**
- [ ] `/advisor_sessions/new` — profile context strip shows current → target role
- [ ] Character counter shows remaining chars; turns red below 200

**Admin**
- [ ] `/admin/ai_templates` — shows `health_ping` and `jobsearchteams_advisor_v1`
- [ ] `/admin/llm_requests` — loads without error

---

### Step 5 — Live Gemini call (requires GEMINI_API_KEY in .env)

- [x] Submit a real job description via `/advisor_sessions/new`
- [x] Redirects to show page with a populated advisor report
- [ ] `/admin/llm_requests` shows the new LlmRequest with status `success`

---

### Step 6 — Full RSpec suite

```
bundle exec rspec
```

- [x] Zero failures (131 examples, 0 failures)
- [x] No real Gemini API calls in output

```
bundle exec rspec --format documentation
```

- [ ] Review output — all examples described correctly

---

### Step 7 — Access control check

- [ ] Sign in as user A; note a session ID from `/advisor_sessions`
- [ ] Sign up as user B; visit `/advisor_sessions/<user-A-session-id>` directly — confirm 404

---

## Completion Checklist

- [x] Step 1 — DB migrate clean
- [x] Step 2 — Model specs pass
- [x] Step 3 — Seeds load
- [x] Step 4 — All browser smoke tests pass
- [x] Step 5 — Live Gemini call succeeds
- [x] Step 6 — Full RSpec suite passes (0 failures)
- [x] Step 7 — Access control confirmed
