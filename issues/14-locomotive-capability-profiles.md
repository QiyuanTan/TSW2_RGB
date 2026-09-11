# 14 — Add minimal locomotive capability profiles

**Labels:** `agent-ready`, `kind:feature`, `area:state`, `area:profiles`  
**Dependencies:** 07, 08, 11

## Outcome

Generic controls remain global while locomotive-specific availability/interpretation can be selected without duplicating bindings or the full rule set.

## Scope

- Define versioned profile schema for locomotive identity match, supported capabilities, reader interpretation parameters, exceptions, and optional visual overrides.
- Implement generic fallback and one profile for the acceptance locomotive proven in issue 02.
- Validate unknown locomotive, ambiguous identity, unsupported fields, malformed profile, and schema version.
- Document how a contributor adds/tests a profile.

## Acceptance criteria

- Profiles contain no physical key assignments.
- Generic actions/rules are referenced rather than copied.
- Unknown locomotives safely use only proven generic capabilities; they never inherit unsafe state interpretations.
- One fixture-backed profile selection test covers identity, capabilities, exception, and fallback.
- Schema validation errors identify the profile/field without exposing personal data.

## Verification

Schema/unit tests, replay with supported and unknown locomotive, duplicate-profile conflict test.

## Out of scope

Broad locomotive catalog or community marketplace.
