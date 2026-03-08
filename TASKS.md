# Tasks

Big items that spawn Cursor plans. Check off when complete, move to Completed section.

---

## Current Sprint: Go-To-Market Launch

### External Setup (You — no code needed)

- [x] **Generate AUTH_SECRET** — Run `openssl rand -base64 33`, save the output. NextAuth needs this to encrypt session cookies. Without it, auth crashes on boot.
- [x] **Google OAuth App** — console.cloud.google.com → Create OAuth 2.0 client → callback: `https://propedge.bet/api/auth/callback/google` (and localhost:3000 for dev). Powers "Continue with Google" sign-in.
- [x] **GitHub OAuth App** — github.com/settings/developers → New OAuth App → callback: `https://propedge.bet/api/auth/callback/github`. Powers "Continue with GitHub" sign-in.
- [x] **Stripe Account + Products** — dashboard.stripe.com → Create two subscription products: Pro ($19/mo) and Sharp ($49/mo). Copy both Price IDs. Create webhook endpoint → `https://propedge.bet/api/webhooks/stripe`. Copy signing secret. This is how you collect money and know who paid.
- [x] **Resend Account + Domain Verification** — resend.com → Add `propedge.bet` as sending domain → Add DNS records (SPF/DKIM/DMARC). Without this, daily picks emails land in spam or don't send at all.
- [ ] **Plausible Analytics** — plausible.io → Add `propedge.bet` ($9/mo). Deferred until user base grows — not worth $9/mo on zero traffic.
- [x] **Discord Server + Webhook** — Create server → `#daily-picks` channel → Server Settings → Integrations → Webhooks → Copy URL. Daily picks auto-post here every morning.
- [x] **Push DB Schema** — Run `cd nba-prop-website && pnpm drizzle-kit push`. Creates the 4 auth tables in Neon. Without this, first sign-in attempt crashes with "relation does not exist."
- [x] **Add Env Vars to Vercel** — Project Settings → Environment Variables. All the secrets from above: AUTH_SECRET, AUTH_GOOGLE_ID/SECRET, AUTH_GITHUB_ID/SECRET, STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET, STRIPE_PRO_PRICE_ID, STRIPE_SHARP_PRICE_ID, NEXT_PUBLIC_APP_URL, RESEND_API_KEY, NEXT_PUBLIC_PLAUSIBLE_DOMAIN. Missing any one = that feature silently breaks in production.
- [ ] **Register Sportsbook Affiliates** — Apply to DraftKings (Impact.com), FanDuel (Impact.com), PrizePicks referral. You earn $25-200 per depositing user. Approval takes 1-4 weeks so apply NOW. Bet buttons already work without IDs, you just add them as URL params once approved.
- [ ] **Create @PropEdge Twitter/X** — Your primary marketing channel. Post 3 picks pre-game daily, grade them next morning. Builds a public timestamped track record. NBA betting Twitter will amplify good picks organically.
- [x] **Add GitHub repo secrets** — Add `UPDATE_API_KEY` and `DISCORD_WEBHOOK_URL` to GitHub repo Settings → Secrets → Actions.

### CI Pipeline Updates (Claude)

- [x] **Add daily digest email to CI** — After morning pipeline, curl `POST /api/send-daily-digest` with Bearer token. Sends top picks to all subscribers.
- [x] **Add weekly recap email to CI** — Monday-only step, curl `POST /api/send-weekly-recap`. Sends graded results for the week.
- [x] **Verify Discord bot step** — Confirmed already wired up in CI (Phase 2c, continue-on-error, gated on DISCORD_WEBHOOK_URL).
- [x] **Add ML backtest grading to CI** — Grade yesterday's predictions against actual results before generating new ones.

### Content & Marketing (You)

- [ ] **First Twitter/X thread** — "The NBA prop market no one is talking about" (binary props edge). Use real backtest data. End with link to propedge.bet.
- [ ] **Reddit posts** — Educational posts on r/sportsbook, r/PrizePicks. Frame as "I built an ML model, here are the results." Don't sell, demonstrate.
- [ ] **TikTok content** — Screen recordings of Prop AI picks + next-day results. Hook: "I let AI pick NBA props for 30 days."
- [ ] **Product Hunt launch** — Write description of ML methodology + transparent track record.
- [ ] **Find 3-5 mid-tier NBA TikTok creators** — Offer free lifetime access for a mention. No cash upfront.

---

## Backlog

- [ ] **Email capture prominence** — Make email signup more visible on homepage (below hero, not just footer/insights)
- [ ] **Methodology page** — Explain the ML model approach (non-technical) for skeptical users
- [ ] **Cumulative win rate chart** — Add to Track Record page (not just recent results)
- [ ] **YouTube series** — Weekly "Prop AI Picks" recap with track record updates
- [ ] **API access tier** — Expose `POST /api/v1/predictions` for developers ($99-299/mo)
- [ ] **Discord premium channel** — Gated `#premium-picks` with role-based access synced to Stripe tier
- [ ] **Player usage rate features** — Add to ML model for better predictions
- [ ] **Lineup/injury features** — Integrate injury data for model improvement
- [ ] **Scrape 2024-2025 defense stats** — Enable training on both seasons' props
- [ ] **Upgrade SportsGameOdds API tier** — Free tier (2,500 obj/mo) will run out with paying users

---

## Completed

- [x] Initial project setup from ai-project-start template
- [x] DOE setup for nba-data-backend: directives/data/, execution/nba_data/, AGENT.md backend section
- [x] Backend data pipeline — full pipeline running daily (gamelogs → games → stats → defense → props)
- [x] ML model — LightGBM trained on 2 seasons, 70+ features, 78% WR at high confidence
- [x] Frontend — Next.js 15 app with Slate, Analytics, Track Record, Player pages, 7 themes, 5 layouts
- [x] ML predictions integrated into Slate page (confidence badges)
- [x] **Legal compliance** — Disclaimer bar, Terms, Privacy, Responsible Gambling pages, in-context warnings on Track Record/Slate/ParlayBuilder, cookie consent banner
- [x] **Auth system** — NextAuth v5 with Google + GitHub OAuth, Drizzle adapter, database sessions, sign-in/error pages, NavBar/MobileTabBar/Profile integration
- [x] **Stripe payments** — Pro ($19/mo) and Sharp ($49/mo) subscriptions, checkout/portal/webhook routes, pricing page with three-tier cards
- [x] **Feature gating** — UpgradeGate component, ML badges behind Pro on Slate, Analytics limited for free, middleware protecting /profile
- [x] **Analytics tracking** — Plausible script + custom events (share, bet click, upgrade, parlay build)
- [x] **Social sharing** — OG image generation for picks, PickShareButton on Slate, ShareButtons on Track Record, dynamic OG metadata
- [x] **Affiliate links** — BetButton component (DK/FD/PP) on Slate player rows, AI picks, and TopPicks
- [x] **Email newsletter** — Resend integration, daily digest endpoint, weekly recap endpoint, unsubscribe endpoint
- [x] **Discord bot** — post_discord_picks.py script + CI integration (non-blocking)
- [x] **Traded player data cleanup** — `scripts/cleanup_traded_players.py` removes phantom DNP/old-team entries for traded players; deleted 137 phantom rows across 12 players; ML predictions regenerated
