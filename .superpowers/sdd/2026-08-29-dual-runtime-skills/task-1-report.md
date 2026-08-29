# Task 1 report — portability contract tests and fixtures

## Status

Implemented the executable portability contract tests and both behavioural
Markdown audit fixtures. Commit message: `test: define dual-runtime
portability contracts`.

## RED evidence

Ran:

```text
bash tests/test-check-portability.sh
```

The test failed with 18 contract failures. Every invocation reported status
127 and:

```text
tests/test-check-portability.sh: line 21: .../scripts/check-portability.sh: No such file or directory
```

This is the intended RED state: the failure is caused by the production
checker being absent, not by a fixture or shell syntax error. `bash -n` and
`git diff --check` both pass.

## Files

- `tests/test-check-portability.sh` — black-box temporary-repository tests for
  missing metadata/files, directory/name mismatch, all five invalid OpenCode
  name forms (including 65 characters), all six forbidden runtime paths,
  missing relative references, warning-only host wording, and a valid skill.
- `tests/fixtures/incomplete-spec.md` — independent audit fixture covering
  C1, C2, C7, C10, and C11 omissions.
- `tests/fixtures/flawed-plan.md` — independent audit fixture covering a
  literal mismatch, producer/consumer defects, an uncounted site change, and
  missing invocation ownership.

## Test summary

`bash tests/test-check-portability.sh`: RED as expected (18 failures, exit 1;
underlying missing-checker invocations exit 127).

## Concerns

- The checker implementation (Task 2) must preserve the diagnostic fragments
  asserted by the tests, especially the `ERROR: <skill-id>:` prefixes and
  `PASS: 1 skills checked` success message.
- The warning case intentionally requires only a `WARN:` diagnostic; the
  checker may report more than one warning for its two host-tool phrases.
