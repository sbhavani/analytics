# Plausible Analytics Constitution

## Core Principles

### I. Privacy-First Development
Every feature must maintain the core privacy promise: no personal data collection, no cookies, GDPR/CCPA/PECR compliance by design. New features require a privacy impact assessment. Data minimization is mandatory - collect only what's necessary for analytics.

**Rationale**: Privacy is the foundational value proposition. Compromising this undermines the entire product mission.

### II. Test-Driven Development (NON-NEGOTIABLE)
All new features require tests written before implementation. The Elixir community uses ExUnit - follow the Red-Green-Refactor cycle. Unit tests for business logic, integration tests for database operations, and contract tests for API boundaries are mandatory.

**Rationale**: Ensures reliability in a data-critical application where incorrect analytics data erodes user trust.

### III. Performance as a Feature
Analytics applications handle high-volume data ingestion and complex queries. All code changes must consider performance impact. Query optimization, efficient data structures, and caching strategies are expected. Benchmarks required for performance-critical paths.

**Rationale**: Users expect real-time or near-real-time analytics. Poor performance directly impacts user experience and product viability.

### IV. Observability and Debuggability
Structured logging required for all operations. Error tracking with context. Metrics for key operations (events ingested, queries executed, API response times). The system must be debuggable in production without requiring console access.

**Rationale**: With distributed data (PostgreSQL + ClickHouse), debugging issues requires clear instrumentation and traceable operations.

### V. Simplicity and YAGNI
Start with the simplest solution that works. Avoid over-engineering - no premature abstractions. Code should be readable and maintainable over clever patterns. Reject features that add unnecessary complexity without proportional value.

**Rationale**: A simple codebase is easier to maintain, security-audit, and extend. Complexity is the enemy of reliability.

## Additional Constraints

### Technology Standards
- **Backend**: Elixir/Phoenix - follow Phoenix conventions for controllers, contexts, and schemas
- **Databases**: PostgreSQL for transactional data, ClickHouse for analytics queries
- **Frontend**: React with TypeScript, TailwindCSS for styling
- **Testing**: ExUnit for Elixir, Jest for JavaScript
- **Code Quality**: Credo for Elixir linting, ESLint/Prettier for JavaScript

### Security Requirements
- No sensitive data in logs
- Input validation on all user-facing endpoints
- SQL injection prevention via Ecto parameterized queries
- CSRF protection enabled on all forms
- Rate limiting on public endpoints

## Development Workflow

### Code Review Requirements
- All PRs require at least one approver
- Security-sensitive changes require two approvers
- Performance regressions must be justified with benchmarks
- Privacy impact review for data-handling changes

### Quality Gates
- All tests must pass (Elixir + JavaScript)
- Credo must pass with no errors
- ESLint/Prettier must pass
- TypeScript compilation must succeed
- Migration backwards-compatibility verified

### Release Process
- Version bump follows semantic versioning
- Changelog updated before release
- Database migrations tested in staging
- Rollback procedure documented for each release

## Governance

This constitution supersedes all other development practices. Amendments require:
1. Proposed changes documented with rationale
2. Review by at least two maintainers
3. Migration plan if changes affect existing workflows
4. Version bump according to semantic versioning rules:
   - MAJOR: Backward-incompatible principle changes
   - MINOR: New principles or materially expanded guidance
   - PATCH: Clarifications, wording fixes, non-semantic refinements

All team members are responsible for enforcing these principles during code review.

**Version**: 1.0.0 | **Ratified**: 2026-02-24 | **Last Amended**: 2026-02-24
