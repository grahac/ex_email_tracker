# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2026-11-05

### Security
- Require Ecto 3.14.3 or newer within 3.x to fix unbounded query-cache growth (CVE-2026-118391).
- Require Phoenix HTML 4.4.0 or newer within 4.x to fix attribute-name HTML injection (CVE-2026-117645). These requirements apply to consuming applications, independently of this library's lockfile.

## [0.1.0] - 2024-07-01

### Added
- Initial release of ExEmailTracker
- Email open tracking via transparent pixel
- Email click tracking with URL preservation
- Real-time analytics dashboard using Phoenix LiveView
- Database schemas and migration generator
- Router helpers for easy integration
- Privacy-compliant tracking with opt-out support
- Unsubscribe link management
- A/B testing support via variants
- Export capabilities for analytics data
- Comprehensive test suite
- GDPR compliance features
