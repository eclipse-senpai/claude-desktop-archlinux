# Security Audit Report: eclipse-senpai/claude-desktop-archlinux

Date: 2026-04-16  
Scope: Shell scripts, PKGBUILD/packaging logic, repository security posture, supply-chain and update/install path, CI/CD automation.

## Executive Summary

- No Critical findings identified.
- One High-severity supply-chain risk remains open (mutable upstream source + disabled checksum verification in `PKGBUILD`).
- One Medium finding was remediated in this PR (cached checkout trust hardening).
- Additional Low/Informational hardening opportunities are documented below.

## Findings by Severity

### Critical

None identified.

### High

#### H-01: Mutable upstream source with checksum verification disabled

- **Description**: The package pulls `aaddrick/claude-desktop-debian` from the mutable `main` branch tarball URL and sets `sha256sums=('SKIP' 'SKIP')`.
- **Impact**: If upstream or delivery path is compromised, malicious source can be executed during build (`build.sh`), resulting in code execution on the builder host and compromised package output.
- **Evidence**:
  - `/home/runner/work/claude-desktop-archlinux/claude-desktop-archlinux/PKGBUILD:16-20`
- **Recommended fix**:
  1. Pin upstream source to an immutable commit/tag archive.
  2. Replace `SKIP` with verified checksums (at least for immutable source and local patch).
  3. Add a controlled update process for bumping commit/tag + checksum.
- **Status**: Open (requires packaging workflow change).

### Medium

#### M-01: Cached repository trust confusion in install/update path (fixed)

- **Description**: Installer/updater reused `~/.cache/claude-desktop-archlinux` without validating `origin`, and used generic pull behavior.
- **Impact**: A tampered local checkout could point to an attacker-controlled remote and execute malicious `PKGBUILD`/scripts during `makepkg -si`.
- **Evidence**:
  - `/home/runner/work/claude-desktop-archlinux/claude-desktop-archlinux/install.sh:25-30`
  - `/home/runner/work/claude-desktop-archlinux/claude-desktop-archlinux/claudeupdate.sh:27-32`
- **Remediation implemented in this PR**:
  - Validate `origin` URL matches expected repository.
  - Pull explicitly from `origin main` with `--ff-only`.
- **Status**: Resolved.

### Low

#### L-01: `curl | bash` usage remains available (partially mitigated)

- **Description**: Direct piping of remote scripts to shell is documented.
- **Impact**: Increases blast radius for supply-chain/script-delivery compromise and reduces user review opportunities.
- **Evidence**:
  - `/home/runner/work/claude-desktop-archlinux/claude-desktop-archlinux/README.md:8`
  - `/home/runner/work/claude-desktop-archlinux/claude-desktop-archlinux/README.md:38`
- **Remediation implemented in this PR**:
  - Added safer “download, review, then execute” alternatives.
  - `/home/runner/work/claude-desktop-archlinux/claude-desktop-archlinux/README.md:11-17`
  - `/home/runner/work/claude-desktop-archlinux/claude-desktop-archlinux/README.md:41-47`
- **Recommended fix**: Prefer documented review-first flow as default installation/update guidance.

### Informational

#### I-01: No CI workflows present

- **Description**: No GitHub Actions workflows detected.
- **Impact**: No automated lint/security/test checks on changes.
- **Evidence**:
  - `.github/workflows/*` not present.
- **Recommended hardening**:
  - Add minimal CI for shell syntax checks and `shellcheck`.
  - Add scheduled security scanning where feasible.

#### I-02: Repository security metadata is minimal

- **Description**: No `SECURITY.md`, no Dependabot config, no `CODEOWNERS` file found.
- **Impact**: Slower vulnerability reporting path and reduced dependency/update hygiene visibility.
- **Evidence**:
  - `SECURITY.md` not present
  - `.github/dependabot.yml` not present
  - `.github/CODEOWNERS` not present
- **Recommended hardening**:
  - Add `SECURITY.md` with disclosure process.
  - Add Dependabot for GitHub Actions (if introduced later) and ecosystem updates.
  - Add `CODEOWNERS` for critical files (`PKGBUILD`, install/update scripts, patches).

## Supply-Chain / Update Path Review Notes

- Build trust is transitive across:
  1. Anthropic installer download/verification in upstream builder.
  2. `aaddrick/claude-desktop-debian` source integrity.
  3. This repo’s installer/updater and packaging scripts.
- Main unresolved risk is mutable, unpinned upstream source with skipped checksums.

## CI/CD Security Review Notes

- No GitHub Actions automation currently exists in this repository, so no workflow misconfiguration vulnerabilities were identified in-repo.
- If workflows are added later, apply least-privilege permissions, pin action SHAs, and restrict untrusted PR token exposure.

## Validation Performed

- Baseline syntax checks before changes:
  - `bash -n install.sh claudeupdate.sh PKGBUILD claude-desktop.install`
- Post-change syntax checks:
  - `bash -n install.sh claudeupdate.sh PKGBUILD claude-desktop.install`

