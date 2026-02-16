# Phase 10: Enhanced Export - Context

**Gathered:** 2026-02-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Expand PDF/CSV export capabilities to allow users to select date ranges when exporting data. Applies to both Admin API data (organization-wide) and local polling data. The export dialog, data content, and file formats will be enhanced while keeping the existing export buttons as entry points.

</domain>

<decisions>
## Implementation Decisions

### Date Range Options
- Preset periods: 7d, 30d, 90d, 1 year, All time, Custom
- "All time" fetches whatever the Admin API returns (no artificial cap)
- Custom date range uses a calendar range picker (click and drag)
- Date filtering applies to both Admin API AND local data exports

### Export Dialog UX
- Two-step sheet flow: Step 1 pick source, Step 2 pick date range
- Same dialog experience for local-only users (just without Admin API source option)
- Default to 30d period (no memory of last selection)
- Show preview/warning only for large exports (not for every export)

### Data Included
- CSV exports include cost column when available from Admin API
- PDF uses adaptive breakdown:
  - Daily detail for periods < 30 days
  - Weekly summaries for 30-90 days
  - Monthly summaries for > 90 days
- Full cache token breakdown: Input, Cache Creation, Cache Read, Output (4 separate columns)

### Export File Format
- Filename format: `tokemon-{type}-{period}.{ext}` (e.g., `tokemon-usage-2026-01-to-2026-02.csv`)
- CSV column order: Date, Total, Input, Output, Cache Read, Cache Create, Cost
- PDF includes summary section at top (totals + key metrics first)
- PDF uses tables only (no charts) for reliability

### Claude's Discretion
- Exact calendar picker implementation (native macOS approach)
- "Large export" threshold for showing preview
- PDF layout and typography details
- Error handling for API failures during export

</decisions>

<specifics>
## Specific Ideas

- Date range picker should feel native to macOS
- Filename includes date range so exports are self-documenting and sortable in Finder
- Summary-first PDF design for executives who want bottom line immediately

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 10-enhanced-export*
*Context gathered: 2026-02-16*
