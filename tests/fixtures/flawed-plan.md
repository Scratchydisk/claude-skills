# Flawed implementation plan fixture

This fixture intentionally contains contract defects for audit tooling.

## Tasks

### Task 1: Add the owner field

- Produces: `owner_id`

### Task 2: Approve records

- Consumes: `business_owner_person_id`
- Produces: `approval-result`

The normative result field is `approval_result`, but the example payload uses
`approvalResult`, so its literal does not conform (C9).

```json
{"approvalResult":"ok"}
```

The plan says to update “the picker” at one site, but names both the summary
picker and the advanced-search picker. The expected count of one disagrees with
the two named sites, and no command verifies the count (C11). It also promises
that approval is functional without naming an invocation route.

### Task 3: Publish approval status

- Consumes: `approval_result`

This consumer requires `approval_result`, but no earlier task produces that
exact symbol: Task 2 produces `approval-result` instead (C10).
