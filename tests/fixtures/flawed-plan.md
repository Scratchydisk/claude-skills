# Flawed implementation plan fixture

This fixture intentionally contains contract defects for audit tooling.

## Tasks

### Task 1: Add the owner field

- Produces: `owner_id`

### Task 2: Approve records

- Consumes: `business_owner_person_id`
- Produces: `approval_result`

The normative result field is `approval_result`, but the example payload uses
`approvalResult`, so its literal does not conform (C9).

```json
{"approvalResult":"ok"}
```

The plan says to update “the picker” but does not count the sites or provide a
command that verifies the count. It also promises that approval is functional
without naming an invocation route. A later task consumes `approval_result`
before any earlier task produces it.
