# Incomplete specification fixture

This fixture intentionally fails the contract audit. It names a `Cell` data
structure without listing fields (C1), uses `RESIDENTIAL` only in an example
without defining the vocabulary or casing (C2), and promises a click handler
without naming what invokes it (C7). It also consumes `business_owner_person_id`
without naming a producer or route (C10), and says to rename “the card heading”
without counting its sites or recording a search command (C11).

## Example

```json
{"kind":"RESIDENTIAL"}
```

The map contains a `Cell`. Clicking a card runs `handleBuildClick()`.

Rename the card heading to “Properties”.
