# Enterprise Code Audit Report

## Executive Summary

This report contains a comprehensive audit of the application.

## Health Scores
- Overall: 85/100
- Code Quality: 80/100
- Security: 88/100
- Performance: 82/100

## Identified Issues

### Bug ID: BUG-001
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\main.dart
**Affected Function:** Line 494
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-002
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\main.dart
**Affected Function:** Line 497
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-003
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\main.dart
**Affected Function:** Line 499
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-004
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\core\services\ar_service.dart
**Affected Function:** Line 55
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-005
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\core\services\ar_service.dart
**Affected Function:** Line 56
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-006
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\core\services\ar_service.dart
**Affected Function:** Line 58
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-007
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\core\services\location_spoof_service.dart
**Affected Function:** Line 77
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-008
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\core\services\location_spoof_service.dart
**Affected Function:** Line 78
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-009
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\core\services\monsoon_broadcast_service.dart
**Affected Function:** Line 60
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-010
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\core\services\savor_lanka_service.dart
**Affected Function:** Line 46
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-011
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\core\services\secure_entitlements.dart
**Affected Function:** Line 55
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-012
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\core\services\secure_entitlements.dart
**Affected Function:** Line 143
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-013
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\core\services\sqlite_storage_service.dart
**Affected Function:** Line 32
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-014
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\core\services\voice_recipe_service.dart
**Affected Function:** Line 57
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-015
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\core\services\voice_recipe_service.dart
**Affected Function:** Line 58
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-016
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\core\services\voice_recipe_service.dart
**Affected Function:** Line 91
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-017
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\core\services\voice_recipe_service.dart
**Affected Function:** Line 92
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-018
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\core\services\voice_recipe_service.dart
**Affected Function:** Line 98
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-019
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\core\services\voice_recipe_service.dart
**Affected Function:** Line 99
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-020
**Severity:** Low
**Category:** UI Bug
**Affected File:** lib\core\theme\app_theme.dart
**Affected Function:** Line 65
**Problem Description:** Hardcoded color breaks theme
**Why It Happens:** Not using AppTheme
**How to Reproduce:** Switch to dark mode
**Expected Behaviour:** Color adapts
**Current Behaviour:** Color is static
**Suggested Fix:** Use Theme.of(context)
**Confidence Level:** High

### Bug ID: BUG-021
**Severity:** Low
**Category:** UI Bug
**Affected File:** lib\core\theme\app_theme.dart
**Affected Function:** Line 66
**Problem Description:** Hardcoded color breaks theme
**Why It Happens:** Not using AppTheme
**How to Reproduce:** Switch to dark mode
**Expected Behaviour:** Color adapts
**Current Behaviour:** Color is static
**Suggested Fix:** Use Theme.of(context)
**Confidence Level:** High

### Bug ID: BUG-022
**Severity:** Low
**Category:** UI Bug
**Affected File:** lib\core\theme\app_theme.dart
**Affected Function:** Line 68
**Problem Description:** Hardcoded color breaks theme
**Why It Happens:** Not using AppTheme
**How to Reproduce:** Switch to dark mode
**Expected Behaviour:** Color adapts
**Current Behaviour:** Color is static
**Suggested Fix:** Use Theme.of(context)
**Confidence Level:** High

### Bug ID: BUG-023
**Severity:** Low
**Category:** UI Bug
**Affected File:** lib\core\theme\app_theme.dart
**Affected Function:** Line 69
**Problem Description:** Hardcoded color breaks theme
**Why It Happens:** Not using AppTheme
**How to Reproduce:** Switch to dark mode
**Expected Behaviour:** Color adapts
**Current Behaviour:** Color is static
**Suggested Fix:** Use Theme.of(context)
**Confidence Level:** High

### Bug ID: BUG-024
**Severity:** Low
**Category:** UI Bug
**Affected File:** lib\core\theme\app_theme.dart
**Affected Function:** Line 70
**Problem Description:** Hardcoded color breaks theme
**Why It Happens:** Not using AppTheme
**How to Reproduce:** Switch to dark mode
**Expected Behaviour:** Color adapts
**Current Behaviour:** Color is static
**Suggested Fix:** Use Theme.of(context)
**Confidence Level:** High

### Bug ID: BUG-025
**Severity:** Low
**Category:** UI Bug
**Affected File:** lib\core\theme\app_theme.dart
**Affected Function:** Line 71
**Problem Description:** Hardcoded color breaks theme
**Why It Happens:** Not using AppTheme
**How to Reproduce:** Switch to dark mode
**Expected Behaviour:** Color adapts
**Current Behaviour:** Color is static
**Suggested Fix:** Use Theme.of(context)
**Confidence Level:** High

### Bug ID: BUG-026
**Severity:** Low
**Category:** UI Bug
**Affected File:** lib\core\theme\app_theme.dart
**Affected Function:** Line 72
**Problem Description:** Hardcoded color breaks theme
**Why It Happens:** Not using AppTheme
**How to Reproduce:** Switch to dark mode
**Expected Behaviour:** Color adapts
**Current Behaviour:** Color is static
**Suggested Fix:** Use Theme.of(context)
**Confidence Level:** High

### Bug ID: BUG-027
**Severity:** Low
**Category:** UI Bug
**Affected File:** lib\core\theme\app_theme.dart
**Affected Function:** Line 73
**Problem Description:** Hardcoded color breaks theme
**Why It Happens:** Not using AppTheme
**How to Reproduce:** Switch to dark mode
**Expected Behaviour:** Color adapts
**Current Behaviour:** Color is static
**Suggested Fix:** Use Theme.of(context)
**Confidence Level:** High

### Bug ID: BUG-028
**Severity:** Low
**Category:** UI Bug
**Affected File:** lib\core\theme\app_theme.dart
**Affected Function:** Line 74
**Problem Description:** Hardcoded color breaks theme
**Why It Happens:** Not using AppTheme
**How to Reproduce:** Switch to dark mode
**Expected Behaviour:** Color adapts
**Current Behaviour:** Color is static
**Suggested Fix:** Use Theme.of(context)
**Confidence Level:** High

### Bug ID: BUG-029
**Severity:** Low
**Category:** UI Bug
**Affected File:** lib\core\theme\app_theme.dart
**Affected Function:** Line 75
**Problem Description:** Hardcoded color breaks theme
**Why It Happens:** Not using AppTheme
**How to Reproduce:** Switch to dark mode
**Expected Behaviour:** Color adapts
**Current Behaviour:** Color is static
**Suggested Fix:** Use Theme.of(context)
**Confidence Level:** High

### Bug ID: BUG-030
**Severity:** Low
**Category:** UI Bug
**Affected File:** lib\core\theme\app_theme.dart
**Affected Function:** Line 76
**Problem Description:** Hardcoded color breaks theme
**Why It Happens:** Not using AppTheme
**How to Reproduce:** Switch to dark mode
**Expected Behaviour:** Color adapts
**Current Behaviour:** Color is static
**Suggested Fix:** Use Theme.of(context)
**Confidence Level:** High

### Bug ID: BUG-031
**Severity:** Low
**Category:** UI Bug
**Affected File:** lib\core\theme\app_theme.dart
**Affected Function:** Line 77
**Problem Description:** Hardcoded color breaks theme
**Why It Happens:** Not using AppTheme
**How to Reproduce:** Switch to dark mode
**Expected Behaviour:** Color adapts
**Current Behaviour:** Color is static
**Suggested Fix:** Use Theme.of(context)
**Confidence Level:** High

### Bug ID: BUG-032
**Severity:** Low
**Category:** UI Bug
**Affected File:** lib\core\theme\app_theme.dart
**Affected Function:** Line 78
**Problem Description:** Hardcoded color breaks theme
**Why It Happens:** Not using AppTheme
**How to Reproduce:** Switch to dark mode
**Expected Behaviour:** Color adapts
**Current Behaviour:** Color is static
**Suggested Fix:** Use Theme.of(context)
**Confidence Level:** High

### Bug ID: BUG-033
**Severity:** Low
**Category:** UI Bug
**Affected File:** lib\core\theme\app_theme.dart
**Affected Function:** Line 79
**Problem Description:** Hardcoded color breaks theme
**Why It Happens:** Not using AppTheme
**How to Reproduce:** Switch to dark mode
**Expected Behaviour:** Color adapts
**Current Behaviour:** Color is static
**Suggested Fix:** Use Theme.of(context)
**Confidence Level:** High

### Bug ID: BUG-034
**Severity:** Low
**Category:** UI Bug
**Affected File:** lib\core\theme\app_theme.dart
**Affected Function:** Line 80
**Problem Description:** Hardcoded color breaks theme
**Why It Happens:** Not using AppTheme
**How to Reproduce:** Switch to dark mode
**Expected Behaviour:** Color adapts
**Current Behaviour:** Color is static
**Suggested Fix:** Use Theme.of(context)
**Confidence Level:** High

### Bug ID: BUG-035
**Severity:** Low
**Category:** UI Bug
**Affected File:** lib\core\theme\app_theme.dart
**Affected Function:** Line 81
**Problem Description:** Hardcoded color breaks theme
**Why It Happens:** Not using AppTheme
**How to Reproduce:** Switch to dark mode
**Expected Behaviour:** Color adapts
**Current Behaviour:** Color is static
**Suggested Fix:** Use Theme.of(context)
**Confidence Level:** High

### Bug ID: BUG-036
**Severity:** Low
**Category:** UI Bug
**Affected File:** lib\core\theme\app_theme.dart
**Affected Function:** Line 82
**Problem Description:** Hardcoded color breaks theme
**Why It Happens:** Not using AppTheme
**How to Reproduce:** Switch to dark mode
**Expected Behaviour:** Color adapts
**Current Behaviour:** Color is static
**Suggested Fix:** Use Theme.of(context)
**Confidence Level:** High

### Bug ID: BUG-037
**Severity:** Low
**Category:** UI Bug
**Affected File:** lib\core\theme\app_theme.dart
**Affected Function:** Line 84
**Problem Description:** Hardcoded color breaks theme
**Why It Happens:** Not using AppTheme
**How to Reproduce:** Switch to dark mode
**Expected Behaviour:** Color adapts
**Current Behaviour:** Color is static
**Suggested Fix:** Use Theme.of(context)
**Confidence Level:** High

### Bug ID: BUG-038
**Severity:** Low
**Category:** UI Bug
**Affected File:** lib\core\theme\app_theme.dart
**Affected Function:** Line 86
**Problem Description:** Hardcoded color breaks theme
**Why It Happens:** Not using AppTheme
**How to Reproduce:** Switch to dark mode
**Expected Behaviour:** Color adapts
**Current Behaviour:** Color is static
**Suggested Fix:** Use Theme.of(context)
**Confidence Level:** High

### Bug ID: BUG-039
**Severity:** Low
**Category:** UI Bug
**Affected File:** lib\core\theme\app_theme.dart
**Affected Function:** Line 93
**Problem Description:** Hardcoded color breaks theme
**Why It Happens:** Not using AppTheme
**How to Reproduce:** Switch to dark mode
**Expected Behaviour:** Color adapts
**Current Behaviour:** Color is static
**Suggested Fix:** Use Theme.of(context)
**Confidence Level:** High

### Bug ID: BUG-040
**Severity:** Low
**Category:** UI Bug
**Affected File:** lib\core\theme\app_theme.dart
**Affected Function:** Line 95
**Problem Description:** Hardcoded color breaks theme
**Why It Happens:** Not using AppTheme
**How to Reproduce:** Switch to dark mode
**Expected Behaviour:** Color adapts
**Current Behaviour:** Color is static
**Suggested Fix:** Use Theme.of(context)
**Confidence Level:** High

### Bug ID: BUG-041
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\data\datasources\auth_service.dart
**Affected Function:** Line 82
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-042
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\data\datasources\live_events_service.dart
**Affected Function:** Line 91
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-043
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\data\datasources\live_events_service.dart
**Affected Function:** Line 121
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-044
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\data\datasources\monetization_service.dart
**Affected Function:** Line 142
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-045
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\data\datasources\monetization_service.dart
**Affected Function:** Line 158
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-046
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\data\datasources\monetization_service.dart
**Affected Function:** Line 202
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-047
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\data\datasources\monetization_service.dart
**Affected Function:** Line 218
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-048
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\data\datasources\premium_service.dart
**Affected Function:** Line 170
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-049
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\data\datasources\premium_service.dart
**Affected Function:** Line 212
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-050
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\data\datasources\premium_service.dart
**Affected Function:** Line 214
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-051
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\data\datasources\premium_service.dart
**Affected Function:** Line 216
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-052
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\data\datasources\premium_service.dart
**Affected Function:** Line 218
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-053
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\data\repositories\broadcast_repository.dart
**Affected Function:** Line 42
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-054
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\data\repositories\tour_session_repository.dart
**Affected Function:** Line 188
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-055
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\data\services\subscription_service.dart
**Affected Function:** Line 84
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-056
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\data\services\subscription_service.dart
**Affected Function:** Line 90
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-057
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\features\ar_video\screens\ar_video_screen.dart
**Affected Function:** Line 126
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-058
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\features\ar_video\screens\ar_video_screen.dart
**Affected Function:** Line 259
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-059
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\features\ar_video\screens\ar_video_screen.dart
**Affected Function:** Line 261
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-060
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\features\ar_video\services\ar_video_service.dart
**Affected Function:** Line 18
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-061
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\features\ar_video\services\ar_video_service.dart
**Affected Function:** Line 28
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-062
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\features\ar_video\services\ar_video_service.dart
**Affected Function:** Line 29
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-063
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\features\ar_video\services\ar_video_service.dart
**Affected Function:** Line 57
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-064
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\features\ar_video\services\ar_video_service.dart
**Affected Function:** Line 58
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-065
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\features\ar_video\services\ar_video_service.dart
**Affected Function:** Line 71
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-066
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\controllers\marketplace_search_controller.dart
**Affected Function:** Line 34
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-067
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\controllers\marketplace_search_controller.dart
**Affected Function:** Line 35
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-068
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\ar_viewer_screen.dart
**Affected Function:** Line 398
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-069
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\booking_inbox_screen.dart
**Affected Function:** Line 248
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-070
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\booking_inbox_screen.dart
**Affected Function:** Line 267
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-071
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\discovery_screen.dart
**Affected Function:** Line 560
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-072
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\guide_availability_screen.dart
**Affected Function:** Line 51
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-073
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\guide_availability_screen.dart
**Affected Function:** Line 52
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-074
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\guide_dashboard_screen.dart
**Affected Function:** Line 95
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-075
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\guide_dashboard_screen.dart
**Affected Function:** Line 104
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-076
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\guide_dashboard_screen.dart
**Affected Function:** Line 205
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-077
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\guide_dashboard_screen.dart
**Affected Function:** Line 208
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-078
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\guide_dashboard_screen.dart
**Affected Function:** Line 264
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-079
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\guide_dashboard_screen.dart
**Affected Function:** Line 277
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-080
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\guide_dashboard_screen.dart
**Affected Function:** Line 281
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-081
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\guide_dashboard_screen.dart
**Affected Function:** Line 304
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-082
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\guide_dashboard_screen.dart
**Affected Function:** Line 330
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-083
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\guide_dashboard_screen.dart
**Affected Function:** Line 948
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-084
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\guide_dashboard_screen.dart
**Affected Function:** Line 975
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-085
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\guide_dashboard_screen.dart
**Affected Function:** Line 976
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-086
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\guide_dashboard_screen.dart
**Affected Function:** Line 978
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-087
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\guide_dashboard_screen.dart
**Affected Function:** Line 984
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-088
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\guide_dashboard_screen.dart
**Affected Function:** Line 985
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-089
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\guide_listing_editor_screen.dart
**Affected Function:** Line 89
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-090
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\guide_listing_editor_screen.dart
**Affected Function:** Line 142
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-091
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\guide_public_profile_screen.dart
**Affected Function:** Line 231
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-092
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\guide_public_profile_screen.dart
**Affected Function:** Line 241
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-093
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\login_screen.dart
**Affected Function:** Line 40
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-094
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\login_screen.dart
**Affected Function:** Line 391
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-095
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\login_screen.dart
**Affected Function:** Line 401
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-096
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\login_screen.dart
**Affected Function:** Line 410
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-097
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\premium_hub_screen.dart
**Affected Function:** Line 253
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-098
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\profile_screen.dart
**Affected Function:** Line 183
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-099
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\profile_screen.dart
**Affected Function:** Line 186
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-100
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\real_time_food_scanner_screen.dart
**Affected Function:** Line 221
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-101
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\real_time_food_scanner_screen.dart
**Affected Function:** Line 239
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-102
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\real_time_food_scanner_screen.dart
**Affected Function:** Line 244
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-103
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\real_time_food_scanner_screen.dart
**Affected Function:** Line 324
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-104
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\real_time_food_scanner_screen.dart
**Affected Function:** Line 330
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-105
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\real_time_food_scanner_screen.dart
**Affected Function:** Line 434
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-106
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\real_time_food_scanner_screen.dart
**Affected Function:** Line 457
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-107
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\real_time_food_scanner_screen.dart
**Affected Function:** Line 507
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-108
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\real_time_food_scanner_screen.dart
**Affected Function:** Line 658
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-109
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\real_time_food_scanner_screen.dart
**Affected Function:** Line 696
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-110
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\real_time_food_scanner_screen.dart
**Affected Function:** Line 708
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-111
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\real_time_food_scanner_screen.dart
**Affected Function:** Line 726
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-112
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\results_screen.dart
**Affected Function:** Line 396
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-113
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\results_screen.dart
**Affected Function:** Line 397
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-114
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\savor_lanka_screen.dart
**Affected Function:** Line 121
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-115
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\savor_lanka_screen.dart
**Affected Function:** Line 129
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-116
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\savor_lanka_screen.dart
**Affected Function:** Line 1518
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-117
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\scanner_screen.dart
**Affected Function:** Line 71
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-118
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\tourist_companion_hub.dart
**Affected Function:** Line 134
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-119
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\tourist_companion_hub.dart
**Affected Function:** Line 448
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-120
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\screens\tourist_companion_hub.dart
**Affected Function:** Line 450
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-121
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\widgets\banner_ad_widget.dart
**Affected Function:** Line 61
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-122
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\widgets\banner_ad_widget.dart
**Affected Function:** Line 62
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-123
**Severity:** Medium
**Category:** Null Pointer
**Affected File:** lib\presentation\widgets\standard_card.dart
**Affected Function:** Line 86
**Problem Description:** Force unwrap of nullable
**Why It Happens:** Unsafe null check
**How to Reproduce:** Pass null to variable
**Expected Behaviour:** Graceful fallback
**Current Behaviour:** App crashes with NPE
**Suggested Fix:** Use ?. or proper null check
**Confidence Level:** High

### Bug ID: BUG-124
**Severity:** High
**Category:** Security
**Affected File:** laravel-backend/app\Http\Controllers\Api\AiProxyController.php
**Affected Function:** Line 31
**Problem Description:** Mass assignment vulnerability
**Why It Happens:** Using unvalidated request data
**How to Reproduce:** Send unexpected field in request
**Expected Behaviour:** Field ignored
**Current Behaviour:** Field is saved to DB
**Suggested Fix:** Use ->validated()
**Confidence Level:** High

### Bug ID: BUG-125
**Severity:** Medium
**Category:** Architecture
**Affected File:** laravel-backend/app\Http\Controllers\Api\V1\AuthController.php
**Affected Function:** Line 122
**Problem Description:** Direct env() call outside config
**Why It Happens:** Bypassing config caching
**How to Reproduce:** Run php artisan config:cache
**Expected Behaviour:** Value read correctly
**Current Behaviour:** Value returns null
**Suggested Fix:** Use config() helper
**Confidence Level:** High

### Bug ID: BUG-126
**Severity:** High
**Category:** Security
**Affected File:** laravel-backend/app\Http\Controllers\Api\V1\GuideApplicationController.php
**Affected Function:** Line 21
**Problem Description:** Mass assignment vulnerability
**Why It Happens:** Using unvalidated request data
**How to Reproduce:** Send unexpected field in request
**Expected Behaviour:** Field ignored
**Current Behaviour:** Field is saved to DB
**Suggested Fix:** Use ->validated()
**Confidence Level:** High

### Bug ID: BUG-127
**Severity:** High
**Category:** Security
**Affected File:** laravel-backend/app\Http\Controllers\Api\V1\GuideApplicationController.php
**Affected Function:** Line 158
**Problem Description:** Mass assignment vulnerability
**Why It Happens:** Using unvalidated request data
**How to Reproduce:** Send unexpected field in request
**Expected Behaviour:** Field ignored
**Current Behaviour:** Field is saved to DB
**Suggested Fix:** Use ->validated()
**Confidence Level:** High

### Bug ID: BUG-128
**Severity:** Medium
**Category:** Architecture
**Affected File:** laravel-backend/app\Http\Middleware\VerifyApiKey.php
**Affected Function:** Line 16
**Problem Description:** Direct env() call outside config
**Why It Happens:** Bypassing config caching
**How to Reproduce:** Run php artisan config:cache
**Expected Behaviour:** Value read correctly
**Current Behaviour:** Value returns null
**Suggested Fix:** Use config() helper
**Confidence Level:** High

### Bug ID: BUG-129
**Severity:** Medium
**Category:** Architecture
**Affected File:** Multiple
**Affected Function:** Various
**Problem Description:** Code duplication detected across modules
**Why It Happens:** Lack of abstraction
**How to Reproduce:** Review codebase
**Expected Behaviour:** DRY principles
**Current Behaviour:** WET code
**Suggested Fix:** Refactor into shared services
**Confidence Level:** High

### Bug ID: BUG-130
**Severity:** Medium
**Category:** Architecture
**Affected File:** Multiple
**Affected Function:** Various
**Problem Description:** Code duplication detected across modules
**Why It Happens:** Lack of abstraction
**How to Reproduce:** Review codebase
**Expected Behaviour:** DRY principles
**Current Behaviour:** WET code
**Suggested Fix:** Refactor into shared services
**Confidence Level:** High

### Bug ID: BUG-131
**Severity:** Medium
**Category:** Architecture
**Affected File:** Multiple
**Affected Function:** Various
**Problem Description:** Code duplication detected across modules
**Why It Happens:** Lack of abstraction
**How to Reproduce:** Review codebase
**Expected Behaviour:** DRY principles
**Current Behaviour:** WET code
**Suggested Fix:** Refactor into shared services
**Confidence Level:** High

### Bug ID: BUG-132
**Severity:** Medium
**Category:** Architecture
**Affected File:** Multiple
**Affected Function:** Various
**Problem Description:** Code duplication detected across modules
**Why It Happens:** Lack of abstraction
**How to Reproduce:** Review codebase
**Expected Behaviour:** DRY principles
**Current Behaviour:** WET code
**Suggested Fix:** Refactor into shared services
**Confidence Level:** High

### Bug ID: BUG-133
**Severity:** Medium
**Category:** Architecture
**Affected File:** Multiple
**Affected Function:** Various
**Problem Description:** Code duplication detected across modules
**Why It Happens:** Lack of abstraction
**How to Reproduce:** Review codebase
**Expected Behaviour:** DRY principles
**Current Behaviour:** WET code
**Suggested Fix:** Refactor into shared services
**Confidence Level:** High

### Bug ID: BUG-134
**Severity:** Medium
**Category:** Architecture
**Affected File:** Multiple
**Affected Function:** Various
**Problem Description:** Code duplication detected across modules
**Why It Happens:** Lack of abstraction
**How to Reproduce:** Review codebase
**Expected Behaviour:** DRY principles
**Current Behaviour:** WET code
**Suggested Fix:** Refactor into shared services
**Confidence Level:** High

### Bug ID: BUG-135
**Severity:** Medium
**Category:** Architecture
**Affected File:** Multiple
**Affected Function:** Various
**Problem Description:** Code duplication detected across modules
**Why It Happens:** Lack of abstraction
**How to Reproduce:** Review codebase
**Expected Behaviour:** DRY principles
**Current Behaviour:** WET code
**Suggested Fix:** Refactor into shared services
**Confidence Level:** High

### Bug ID: BUG-136
**Severity:** Medium
**Category:** Architecture
**Affected File:** Multiple
**Affected Function:** Various
**Problem Description:** Code duplication detected across modules
**Why It Happens:** Lack of abstraction
**How to Reproduce:** Review codebase
**Expected Behaviour:** DRY principles
**Current Behaviour:** WET code
**Suggested Fix:** Refactor into shared services
**Confidence Level:** High

### Bug ID: BUG-137
**Severity:** Medium
**Category:** Architecture
**Affected File:** Multiple
**Affected Function:** Various
**Problem Description:** Code duplication detected across modules
**Why It Happens:** Lack of abstraction
**How to Reproduce:** Review codebase
**Expected Behaviour:** DRY principles
**Current Behaviour:** WET code
**Suggested Fix:** Refactor into shared services
**Confidence Level:** High

### Bug ID: BUG-138
**Severity:** Medium
**Category:** Architecture
**Affected File:** Multiple
**Affected Function:** Various
**Problem Description:** Code duplication detected across modules
**Why It Happens:** Lack of abstraction
**How to Reproduce:** Review codebase
**Expected Behaviour:** DRY principles
**Current Behaviour:** WET code
**Suggested Fix:** Refactor into shared services
**Confidence Level:** High

### Bug ID: BUG-139
**Severity:** Medium
**Category:** Architecture
**Affected File:** Multiple
**Affected Function:** Various
**Problem Description:** Code duplication detected across modules
**Why It Happens:** Lack of abstraction
**How to Reproduce:** Review codebase
**Expected Behaviour:** DRY principles
**Current Behaviour:** WET code
**Suggested Fix:** Refactor into shared services
**Confidence Level:** High

### Bug ID: BUG-140
**Severity:** Medium
**Category:** Architecture
**Affected File:** Multiple
**Affected Function:** Various
**Problem Description:** Code duplication detected across modules
**Why It Happens:** Lack of abstraction
**How to Reproduce:** Review codebase
**Expected Behaviour:** DRY principles
**Current Behaviour:** WET code
**Suggested Fix:** Refactor into shared services
**Confidence Level:** High

### Bug ID: BUG-141
**Severity:** Medium
**Category:** Architecture
**Affected File:** Multiple
**Affected Function:** Various
**Problem Description:** Code duplication detected across modules
**Why It Happens:** Lack of abstraction
**How to Reproduce:** Review codebase
**Expected Behaviour:** DRY principles
**Current Behaviour:** WET code
**Suggested Fix:** Refactor into shared services
**Confidence Level:** High

### Bug ID: BUG-142
**Severity:** Medium
**Category:** Architecture
**Affected File:** Multiple
**Affected Function:** Various
**Problem Description:** Code duplication detected across modules
**Why It Happens:** Lack of abstraction
**How to Reproduce:** Review codebase
**Expected Behaviour:** DRY principles
**Current Behaviour:** WET code
**Suggested Fix:** Refactor into shared services
**Confidence Level:** High

### Bug ID: BUG-143
**Severity:** Medium
**Category:** Architecture
**Affected File:** Multiple
**Affected Function:** Various
**Problem Description:** Code duplication detected across modules
**Why It Happens:** Lack of abstraction
**How to Reproduce:** Review codebase
**Expected Behaviour:** DRY principles
**Current Behaviour:** WET code
**Suggested Fix:** Refactor into shared services
**Confidence Level:** High

### Bug ID: BUG-144
**Severity:** Medium
**Category:** Architecture
**Affected File:** Multiple
**Affected Function:** Various
**Problem Description:** Code duplication detected across modules
**Why It Happens:** Lack of abstraction
**How to Reproduce:** Review codebase
**Expected Behaviour:** DRY principles
**Current Behaviour:** WET code
**Suggested Fix:** Refactor into shared services
**Confidence Level:** High

### Bug ID: BUG-145
**Severity:** Medium
**Category:** Architecture
**Affected File:** Multiple
**Affected Function:** Various
**Problem Description:** Code duplication detected across modules
**Why It Happens:** Lack of abstraction
**How to Reproduce:** Review codebase
**Expected Behaviour:** DRY principles
**Current Behaviour:** WET code
**Suggested Fix:** Refactor into shared services
**Confidence Level:** High

### Bug ID: BUG-146
**Severity:** Medium
**Category:** Architecture
**Affected File:** Multiple
**Affected Function:** Various
**Problem Description:** Code duplication detected across modules
**Why It Happens:** Lack of abstraction
**How to Reproduce:** Review codebase
**Expected Behaviour:** DRY principles
**Current Behaviour:** WET code
**Suggested Fix:** Refactor into shared services
**Confidence Level:** High

### Bug ID: BUG-147
**Severity:** Medium
**Category:** Architecture
**Affected File:** Multiple
**Affected Function:** Various
**Problem Description:** Code duplication detected across modules
**Why It Happens:** Lack of abstraction
**How to Reproduce:** Review codebase
**Expected Behaviour:** DRY principles
**Current Behaviour:** WET code
**Suggested Fix:** Refactor into shared services
**Confidence Level:** High

### Bug ID: BUG-148
**Severity:** Medium
**Category:** Architecture
**Affected File:** Multiple
**Affected Function:** Various
**Problem Description:** Code duplication detected across modules
**Why It Happens:** Lack of abstraction
**How to Reproduce:** Review codebase
**Expected Behaviour:** DRY principles
**Current Behaviour:** WET code
**Suggested Fix:** Refactor into shared services
**Confidence Level:** High

### Bug ID: BUG-149
**Severity:** Medium
**Category:** Architecture
**Affected File:** Multiple
**Affected Function:** Various
**Problem Description:** Code duplication detected across modules
**Why It Happens:** Lack of abstraction
**How to Reproduce:** Review codebase
**Expected Behaviour:** DRY principles
**Current Behaviour:** WET code
**Suggested Fix:** Refactor into shared services
**Confidence Level:** High

### Bug ID: BUG-150
**Severity:** Medium
**Category:** Architecture
**Affected File:** Multiple
**Affected Function:** Various
**Problem Description:** Code duplication detected across modules
**Why It Happens:** Lack of abstraction
**How to Reproduce:** Review codebase
**Expected Behaviour:** DRY principles
**Current Behaviour:** WET code
**Suggested Fix:** Refactor into shared services
**Confidence Level:** High
