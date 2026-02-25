# Tasks: Funnel Visualization

**Input**: Design documents from `/specs/001-funnel-visualization/`
**Prerequisites**: plan.md, spec.md

## Status: Feature Already Implemented ✅

The funnel visualization feature described in the specification already exists in this codebase as a production-ready Enterprise feature.

---

## Implementation Complete

No implementation tasks are required. The feature is fully implemented:

### Backend Implementation

| Component | Location | Status |
|-----------|----------|--------|
| Funnel Schema | `/extra/lib/plausible/funnel.ex` | ✅ Complete |
| CRUD Operations | `/extra/lib/plausible/funnels.ex` | ✅ Complete |
| Analytics Query | `/extra/lib/plausible/stats/funnel.ex` | ✅ Complete |
| API Endpoint | `/api/stats/:domain/funnels/:id` | ✅ Complete |

### Frontend Implementation

| Component | Location | Status |
|-----------|----------|--------|
| Funnel Component | `/assets/js/dashboard/extra/funnel.js` | ✅ Complete |
| Tooltip | `/assets/js/dashboard/extra/funnel-tooltip.js` | ✅ Complete |

### Existing Tests

| Test Location | Coverage |
|---------------|----------|
| `/test/plausible/funnels_test.exs` | CRUD operations |
| `/test/plausible/stats/funnel_test.exs` | Analytics queries |

---

## Verification

To verify the feature is working:

1. **Create a funnel**:
   ```bash
   # Via admin UI or API
   POST /api/sites/{site_id}/funnels
   ```

2. **View funnel analytics**:
   ```bash
   GET /api/stats/{domain}/funnels/{funnel_id}
   ```

3. **Frontend**: Navigate to dashboard → Funnels tab

---

## Feature Coverage

| User Story | Status | Implementation |
|------------|--------|----------------|
| US1: View Conversion Funnel | ✅ Complete | `funnel.js` with Chart.js visualization |
| US2: Configure Funnel Steps | ✅ Complete | `funnels.ex` CRUD operations |
| US3: Analyze Drop-off Insights | ✅ Complete | `stats/funnel.ex` with drop-off calculations |

---

## Notes

- Feature requires Enterprise subscription (billing check in `Funnels.create/3`)
- Uses ClickHouse `windowFunnel` for efficient sequential event matching
- Supports dark/light themes and mobile responsive design
- All requirements from spec.md are satisfied
