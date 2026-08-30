# Third-party notices

This repository's own code is MIT-licensed under the root `LICENSE`, copyright
2026 Stewart McSporran. The material listed below was written by other people,
is copied here unmodified, and stays under its own licence and copyright.

## Superpowers — `skills/brainstorming/`

- Source: <https://github.com/obra/superpowers.git>
- Revision: `b36e0829c6d0140e93cfef2ca599b1b07d4a7797` (the annotated tag
  `v6.3.0` dereferences to this commit)
- Upstream path: `skills/brainstorming/`
- Licence: MIT, copyright (c) 2025 Jesse Vincent
- Licence text: `skills/brainstorming/LICENSE`, copied verbatim from the
  upstream repository root at the revision above

The eight files below are byte-for-byte copies of the upstream directory at
that commit. Nothing was edited, reformatted, or reconstructed from memory.
`LICENSE` is the ninth file in the vendored directory and is the upstream root
licence, added here because MIT requires the copyright and permission notice to
travel with copies of the software.

| File | SHA-256 |
| --- | --- |
| `SKILL.md` | `74edf03ea6d24ef53db48677b93558d14a979bdf052ca3f57ecdca0c66791608` |
| `spec-document-reviewer-prompt.md` | `95a0a195de9d984be2fffa95bab16fc8c563bc296a9cfc5e9c29cb3ece0d7457` |
| `visual-companion.md` | `77eb44a4ec3408bb3dafb872288ecd94beb8cf21da4f2bafa54fd08255d7808b` |
| `scripts/frame-template.html` | `6a8a4e58bd6a44b904e2e3c57de774481d909204597e1498de53f1b2fecc4c4e` |
| `scripts/helper.js` | `43c6d69954a46ec34a2a262bcc62a9a7e83e839c739f199cb72646d397c686e3` |
| `scripts/server.cjs` | `2d2961ea8d11f56c5f4c3a1a68d22709efa5d7601a2246d8c880774e7e9e8412` |
| `scripts/start-server.sh` | `a4e5ae84275bcaacd2f84345afeabe59cf7b00ba080e123da7cc1fb226f12847` |
| `scripts/stop-server.sh` | `0b5ccbbd57f62d3ed88993f7940b5ee0e5c0fc9b21c550c623da4f6292e47daf` |
| `LICENSE` (upstream repository root) | `a37e0e9697144819e1d965176ac4ae5bc3fa02d11e7812036bbcadf6dafe2400` |

Verify the vendored copy against upstream at any time:

```sh
git clone --depth 1 https://github.com/obra/superpowers.git /tmp/superpowers-verify
git -C /tmp/superpowers-verify fetch --depth 1 origin b36e0829c6d0140e93cfef2ca599b1b07d4a7797
git -C /tmp/superpowers-verify checkout FETCH_HEAD
diff -r /tmp/superpowers-verify/skills/brainstorming skills/brainstorming --exclude=LICENSE
```

An empty diff means the copy is unmodified.

## Superpowers skills that are not vendored

`writing-plans`, `subagent-driven-development`, and `executing-plans` come from
the same repository and the same commit, and carry the same MIT licence. This
repository does not copy them. No skill here reads their files, so there is
nothing to vendor them for; `docs/runtime-portability.md` records how to install
them from upstream instead. Treat a missing one as a stop, not as something to
rewrite locally.
