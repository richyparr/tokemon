# Requirements: Tokemon

**Defined:** 2026-02-18
**Core Value:** Know your Claude usage at a glance before hitting limits.

## v4.0 Requirements

Requirements for Raycast extension release.

### Extension Foundation

- [ ] **EXT-01**: Extension scaffolded with TypeScript, React, @raycast/api
- [ ] **EXT-02**: Custom Tokemon icon displayed in Raycast
- [ ] **EXT-03**: MIT license and README with setup instructions
- [ ] **EXT-04**: User can enter OAuth token via setup wizard

### Dashboard Command

- [ ] **DASH-01**: User sees session usage percentage
- [ ] **DASH-02**: User sees weekly usage percentage
- [ ] **DASH-03**: User sees reset timer countdown
- [ ] **DASH-04**: User sees pace indicator (on track / ahead / behind)
- [ ] **DASH-05**: User can manually refresh usage data

### Menu Bar Command

- [ ] **MENU-01**: Usage percentage displayed in Raycast menu bar
- [ ] **MENU-02**: Menu bar updates automatically (background refresh)
- [ ] **MENU-03**: Menu bar color indicates usage level (green/orange/red)

### Multi-Profile

- [ ] **PROF-01**: User can add multiple profiles with tokens
- [ ] **PROF-02**: User can switch between profiles
- [ ] **PROF-03**: User can delete profiles

### Alerts

- [ ] **ALRT-01**: User can configure usage threshold for alerts
- [ ] **ALRT-02**: User receives Raycast notification at threshold
- [ ] **ALRT-03**: User can test alert from settings

---

## Previous Milestones (Archived)

- **v1.0-v3.0**: See [milestones/](milestones/) for archived requirements

## Out of Scope

| Feature | Reason |
|---------|--------|
| Alfred extension | Raycast-only for v4.0; Alfred deferred |
| iOS companion | Deferred until Apple Developer Program |
| Tokemon.app integration | Keep extension standalone; may add later |
| Direct Keychain access | Raycast Store rejects Keychain requests |
| Claude chat/AI features | Scope creep; focus on usage monitoring |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| EXT-01 | Phase 18 | Pending |
| EXT-02 | Phase 18 | Pending |
| EXT-03 | Phase 18 | Pending |
| EXT-04 | Phase 18 | Pending |
| DASH-01 | Phase 19 | Pending |
| DASH-02 | Phase 19 | Pending |
| DASH-03 | Phase 19 | Pending |
| DASH-04 | Phase 19 | Pending |
| DASH-05 | Phase 19 | Pending |
| MENU-01 | Phase 20 | Pending |
| MENU-02 | Phase 20 | Pending |
| MENU-03 | Phase 20 | Pending |
| PROF-01 | Phase 21 | Pending |
| PROF-02 | Phase 21 | Pending |
| PROF-03 | Phase 21 | Pending |
| ALRT-01 | Phase 21 | Pending |
| ALRT-02 | Phase 21 | Pending |
| ALRT-03 | Phase 21 | Pending |

**Coverage:**
- v4.0 requirements: 18 total
- Mapped to phases: 18
- Unmapped: 0

---
*Requirements defined: 2026-02-18*
*Last updated: 2026-02-18 after v4.0 roadmap created*
