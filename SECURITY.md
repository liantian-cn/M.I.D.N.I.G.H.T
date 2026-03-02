# Security Policy

## Scope

This repository focuses on a pixel-bridge architecture between an in-game addon and an external parser.

Security concerns in scope include:

1. Sensitive data leakage through logs, screenshots, or exported artifacts.
2. Malicious input handling in parser-side tooling.
3. Supply-chain risks in dependencies and tooling scripts.

## Out of Scope

1. Requests for cheat, bot, or unfair gameplay automation features.
2. Reverse-engineering or bypass techniques against anti-cheat systems.

## Supported Versions

| Version          | Status                         |
| ---------------- | ------------------------------ |
| `v0.1.x-draft`   | Supported on best-effort basis |
| `< v0.1.0-draft` | Not supported                  |

## Reporting a Vulnerability

1. Prefer private reporting through GitHub Security Advisory (if enabled).
2. If private reporting is unavailable, open a minimal public issue without exploit details.
3. Include:
   - Affected file(s)
   - Reproduction steps
   - Impact assessment
   - Suggested mitigation (optional)

## Response Expectations

1. Initial acknowledgment target: within 7 days.
2. Triage result target: within 14 days.
3. Fix timeline depends on severity and maintainer availability.

## Compliance Boundary

This project is for technical research and protocol design discussion.
Contributors must keep usage and changes aligned with game policies and fair-play principles.
