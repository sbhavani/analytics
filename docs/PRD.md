# PRD: Plausible Analytics

A privacy-focused, lightweight, open-source web analytics platform. An alternative to Google Analytics that doesn't use cookies and is fully compliant with GDPR, CCPA, and PECR.

## Implementation Status

Core platform complete. Advanced features (funnels, ecommerce, API) in progress. See [ROADMAP.md](ROADMAP.md) for details.

## User Stories

### P0: Core Analytics (Must Have) — ✅ Complete

**As a** website owner,
**I want** to see visitor statistics for my site,
**So that** I can understand my traffic patterns.

- [P0-US1] ✅ Pageview tracking via JavaScript snippet
- [P0-US2] ✅ Unique visitor counting (session-based, no cookies)
- [P0-US3] ✅ Dashboard with key metrics (visitors, pageviews, bounce rate, visit duration)
- [P0-US4] ✅ Time period filtering (today, this week, this month, custom range)
- [P0-US5] ✅ Top pages report
- [P0-US6] ✅ Top referral sources (referrer analysis)
- [P0-US7] ✅ Geographic distribution (country-level)
- [P0-US8] ✅ Real-time dashboard (live visitor count)

**Acceptance Criteria:**
- JavaScript snippet < 1KB gzipped
- No cookies set on visitor browsers
- Dashboard loads in < 2 seconds
- Real-time updates within 30 seconds

---

### P0: Privacy Compliance (Must Have) — ✅ Complete

**As a** site operator,
**I want** analytics that respects visitor privacy,
**So that** I'm compliant with GDPR, CCPA, and PECR.

- [P0-US9] ✅ No personal data collection (no IP, no fingerprinting)
- [P0-US10] ✅ No cookies required
- [P0-US11] ✅ Data processing agreement available
- [P0-US12] ✅ Cookie-less consent mode (no banner required in most jurisdictions)
- [P0-US13] ✅ Data retention settings (configurable by user)

**Acceptance Criteria:**
- Legal for use in EU without consent banner
- No PII stored in database
- Configurable data retention (3 months to unlimited)

---

### P0: Multi-Site Management (Must Have) — ✅ Complete

**As a** site owner with multiple properties,
**I want** to manage all my sites from one account,
**So that** I can view analytics for each site easily.

- [P0-US14] ✅ Create and manage multiple sites
- [P0-US15] ✅ Site-level permissions (owner, viewer, admin)
- [P0-US16] ✅ Invite team members to sites
- [P0-US17] ✅ Site API keys for event ingestion

**Acceptance Criteria:**
- Unlimited sites per account
- Role-based access control
- API key rotation support

---

### P1: Advanced Metrics (Should Have) — ✅ Complete

**As a** website owner,
**I want** deeper insights into visitor behavior,
**So that** I can optimize my site performance.

- [P1-US1] ✅ Custom events (track clicks, downloads, outbound links)
- [P1-US2] ✅ Custom properties/dimensions (e.g., logged-in status, plan type)
- [P1-US3] ✅ Goal tracking (conversion tracking)
- [P1-US4] ✅ Exit pages analysis
- [P1-US5] ✅ Entry pages analysis
- [P1-US6] ✅ UTM parameter tracking (source, medium, campaign)

**Acceptance Criteria:**
- Custom events track without page reload
- Goals show conversion rate
- UTM parameters parsed automatically

---

### P1: Funnels & Cohorts (Should Have) — 🔄 In Progress

**As a** marketing manager,
**I want** to understand user journeys and conversion paths,
**So that** I can identify drop-off points.

- [P1-US7] 🔄 Funnel visualization (step-by-step conversion)
- [P1-US8] 🔄 Cohort analysis
- [P1-US9] ⬜ Retention reports

**Acceptance Criteria:**
- Funnels display step-by-step drop-off rates
- Cohorts show user return patterns over time

---

### P1: Data Export & API (Should Have) — ✅ Complete

**As an** analyst,
**I want** to export data for external analysis,
**So that** I can create custom reports.

- [P1-US10] ✅ CSV export for all reports
- [P1-US11] ✅ REST API for programmatic access
- [P1-US12] ✅ API rate limiting with quotas

**Acceptance Criteria:**
- Export completes for 100k rows in < 30 seconds
- API returns JSON with pagination
- Rate limits clearly documented

---

### P1: Email & Slack Reports (Should Have) — ✅ Complete

**As a** busy site owner,
**I want** periodic reports delivered to my inbox,
**So that** I stay informed without logging in.

- [P1-US13] ✅ Weekly/monthly email reports
- [P1-US14] ✅ Slack integration for reports
- [P1-US15] ✅ Traffic spike notifications

**Acceptance Criteria:**
- Reports delivered on schedule
- Spike alerts trigger at configurable threshold

---

### P2: Ecommerce Tracking (Could Have) — ✅ Complete

**As an** online store owner,
**I want** to track revenue and ecommerce metrics,
**So that** I can measure conversion and revenue.

- [P2-US1] ✅ Product revenue tracking
- [P2-US2] ✅ Order ID and value tracking
- [P2-US3] ✅ Cart size tracking

**Acceptance Criteria:**
- Revenue shows in dashboard
- Order data aggregated correctly

---

### P2: Search Integration (Could Have) — ✅ Complete

**As an** SEO manager,
**I want** to see search keywords driving traffic,
**So that** I can optimize for high-performing terms.

- [P2-US4] ✅ Google Search Console integration
- [P2-US5] ✅ Search keywords report (via GSC)
- [P2-US6] ✅ Content keywords (top performing pages for keywords)

---

### P2: Advanced Filtering (Could Have) — ⬜ Not Started

**As an** analyst,
**I want** to drill down into specific visitor segments,
**So that** I can analyze specific audiences.

- [P2-US7] ⬜ Advanced filter builder (combine multiple conditions)
- [P2-US8] ⬜ Saved filter presets
- [P2-US9] ⬜ Compare time periods side-by-side

---

### P3: Self-Hosted Features (Nice to Have) — ✅ Complete

**As a** self-hosted user,
**I want** a complete self-hosted solution,
**So that** I can run Plausible on my own infrastructure.

- [P3-US1] ✅ Docker-based deployment
- [P3-US2] ✅ Single-node setup with ClickHouse
- [P3-US3] ✅ SMTP email configuration
- [P3-US4] ✅ SSL/TLS support

**Acceptance Criteria:**
- Docker Compose one-command startup
- < 2GB RAM for 10k events/day

---

### P3: Enterprise Features (Nice to Have) — ⬜ Not Started

**As an** enterprise customer,
**I want** advanced features for large-scale deployment,
**So that** I can meet organizational requirements.

- [P3-US5] ⬜ SSO/SAML authentication
- [P3-US6] ⬜ Role-based access control hierarchy
- [P3-US7] ⬜ Audit logs
- [P3-US8] ⬜ Data residency controls (region-specific storage)

---

## Non-Functional Requirements

### Performance
- Dashboard loads in < 2 seconds for 10M events
- Event ingestion handles 1000 events/second
- Real-time dashboard updates within 30 seconds
- JavaScript snippet < 1KB gzipped

### Privacy & Legal
- No cookies required (no consent banner in EU)
- No PII stored (no IP addresses, no fingerprints)
- GDPR-compliant data processing agreement
- CCPA and PECR compliant
- Data retention configurable (3 months to unlimited)
- Right to deletion (data purge) supported

### Security
- SQL injection prevention via Ecto parameterized queries
- CSRF protection on all forms
- Rate limiting on public endpoints
- API key authentication with secret rotation
- Secure session management

### Scalability
- PostgreSQL for transactional data (users, sites, settings)
- ClickHouse for analytics queries (time-series optimized)
- Read replicas supported for high traffic
- Horizontal scaling via ClickHouse cluster

### Reliability
- 99.9% uptime SLA (cloud)
- Automated backups
- Point-in-time recovery for database

## Test Scenarios

1. **Pageview**: Load page with Plausible script, verify event appears in dashboard
2. **Unique visitor**: Visit from two browsers, verify unique count = 2
3. **Referrer**: Visit from external link, verify referrer captured correctly
4. **Custom event**: Click tracked element, verify event appears in dashboard
5. **Goal conversion**: Complete goal action, verify conversion recorded
6. **Time filter**: Change date range, verify data updates correctly
7. **CSV export**: Export 10k rows, verify all data present
8. **API**: Query stats via API, verify JSON response matches dashboard
9. **Real-time**: Generate traffic, verify real-time counter updates
10. **Team invite**: Invite user, verify they can access assigned sites
11. **Data retention**: Set 30-day retention, verify old data purged
12. **Self-hosted**: Run Docker compose, verify all services start
