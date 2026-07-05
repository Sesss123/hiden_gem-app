### 26. Print statement instead of standard logger
- **Bug ID**: AUTO-026
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `audit_script.py`
- **Affected Function**: Line 39
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 27. Broad exception catch without specific typing
- **Bug ID**: AUTO-027
- **Severity**: Medium
- **Category**: Exception Handling
- **Affected File**: `audit_script.py`
- **Affected Function**: Line 59
- **Problem Description**: Broad exception catch without specific typing.
- **Why It Happens**: Lazy error handling
- **How to Reproduce**: Trigger any error
- **Expected Behaviour**: Should catch specific exceptions
- **Current Behaviour**: Catches everything including KeyboardInterrupt sometimes
- **Suggested Fix**: Specify exception type
- **Confidence Level**: Medium

### 28. Redundant boolean comparison
- **Bug ID**: AUTO-028
- **Severity**: Low
- **Category**: Code Smell
- **Affected File**: `audit_script.py`
- **Affected Function**: Line 63
- **Problem Description**: Redundant boolean comparison.
- **Why It Happens**: Beginner python syntax
- **How to Reproduce**: N/A
- **Expected Behaviour**: if condition:
- **Current Behaviour**: if condition == True:
- **Suggested Fix**: Remove == True
- **Confidence Level**: Medium

### 29. Redundant boolean comparison
- **Bug ID**: AUTO-029
- **Severity**: Low
- **Category**: Code Smell
- **Affected File**: `audit_script.py`
- **Affected Function**: Line 64
- **Problem Description**: Redundant boolean comparison.
- **Why It Happens**: Beginner python syntax
- **How to Reproduce**: N/A
- **Expected Behaviour**: if condition:
- **Current Behaviour**: if condition == True:
- **Suggested Fix**: Remove == True
- **Confidence Level**: Medium

### 30. Print statement instead of standard logger
- **Bug ID**: AUTO-030
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `translate.py`
- **Affected Function**: Line 28
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 31. Print statement instead of standard logger
- **Bug ID**: AUTO-031
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `translate.py`
- **Affected Function**: Line 36
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 32. Print statement instead of standard logger
- **Bug ID**: AUTO-032
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `translate.py`
- **Affected Function**: Line 58
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 33. Print statement instead of standard logger
- **Bug ID**: AUTO-033
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\ai_training_module\dataset_validator.py`
- **Affected Function**: Line 6
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 34. Print statement instead of standard logger
- **Bug ID**: AUTO-034
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\ai_training_module\dataset_validator.py`
- **Affected Function**: Line 9
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 35. Print statement instead of standard logger
- **Bug ID**: AUTO-035
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\ai_training_module\dataset_validator.py`
- **Affected Function**: Line 32
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 36. Print statement instead of standard logger
- **Bug ID**: AUTO-036
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\ai_training_module\dataset_validator.py`
- **Affected Function**: Line 36
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 37. Print statement instead of standard logger
- **Bug ID**: AUTO-037
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\ai_training_module\dataset_validator.py`
- **Affected Function**: Line 39
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 38. Print statement instead of standard logger
- **Bug ID**: AUTO-038
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\ai_training_module\dataset_validator.py`
- **Affected Function**: Line 40
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 39. Print statement instead of standard logger
- **Bug ID**: AUTO-039
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\ai_training_module\dataset_validator.py`
- **Affected Function**: Line 41
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 40. Print statement instead of standard logger
- **Bug ID**: AUTO-040
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\ai_training_module\dataset_validator.py`
- **Affected Function**: Line 44
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 41. Print statement instead of standard logger
- **Bug ID**: AUTO-041
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\ai_training_module\dataset_validator.py`
- **Affected Function**: Line 47
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 42. Print statement instead of standard logger
- **Bug ID**: AUTO-042
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\ai_training_module\dataset_validator.py`
- **Affected Function**: Line 52
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 43. Print statement instead of standard logger
- **Bug ID**: AUTO-043
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\ai_training_module\dataset_validator.py`
- **Affected Function**: Line 53
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 44. Broad exception catch without specific typing
- **Bug ID**: AUTO-044
- **Severity**: Medium
- **Category**: Exception Handling
- **Affected File**: `backend\api\routers\pipeline.py`
- **Affected Function**: Line 44
- **Problem Description**: Broad exception catch without specific typing.
- **Why It Happens**: Lazy error handling
- **How to Reproduce**: Trigger any error
- **Expected Behaviour**: Should catch specific exceptions
- **Current Behaviour**: Catches everything including KeyboardInterrupt sometimes
- **Suggested Fix**: Specify exception type
- **Confidence Level**: Medium

### 45. Broad exception catch without specific typing
- **Bug ID**: AUTO-045
- **Severity**: Medium
- **Category**: Exception Handling
- **Affected File**: `backend\api\routers\pipeline.py`
- **Affected Function**: Line 410
- **Problem Description**: Broad exception catch without specific typing.
- **Why It Happens**: Lazy error handling
- **How to Reproduce**: Trigger any error
- **Expected Behaviour**: Should catch specific exceptions
- **Current Behaviour**: Catches everything including KeyboardInterrupt sometimes
- **Suggested Fix**: Specify exception type
- **Confidence Level**: Medium

### 46. Broad exception catch without specific typing
- **Bug ID**: AUTO-046
- **Severity**: Medium
- **Category**: Exception Handling
- **Affected File**: `backend\core\firebase_admin_init.py`
- **Affected Function**: Line 53
- **Problem Description**: Broad exception catch without specific typing.
- **Why It Happens**: Lazy error handling
- **How to Reproduce**: Trigger any error
- **Expected Behaviour**: Should catch specific exceptions
- **Current Behaviour**: Catches everything including KeyboardInterrupt sometimes
- **Suggested Fix**: Specify exception type
- **Confidence Level**: Medium

### 47. Broad exception catch without specific typing
- **Bug ID**: AUTO-047
- **Severity**: Medium
- **Category**: Exception Handling
- **Affected File**: `backend\core\scheduler.py`
- **Affected Function**: Line 117
- **Problem Description**: Broad exception catch without specific typing.
- **Why It Happens**: Lazy error handling
- **How to Reproduce**: Trigger any error
- **Expected Behaviour**: Should catch specific exceptions
- **Current Behaviour**: Catches everything including KeyboardInterrupt sometimes
- **Suggested Fix**: Specify exception type
- **Confidence Level**: Medium

### 48. Broad exception catch without specific typing
- **Bug ID**: AUTO-048
- **Severity**: Medium
- **Category**: Exception Handling
- **Affected File**: `backend\core\scheduler.py`
- **Affected Function**: Line 140
- **Problem Description**: Broad exception catch without specific typing.
- **Why It Happens**: Lazy error handling
- **How to Reproduce**: Trigger any error
- **Expected Behaviour**: Should catch specific exceptions
- **Current Behaviour**: Catches everything including KeyboardInterrupt sometimes
- **Suggested Fix**: Specify exception type
- **Confidence Level**: Medium

### 49. Broad exception catch without specific typing
- **Bug ID**: AUTO-049
- **Severity**: Medium
- **Category**: Exception Handling
- **Affected File**: `backend\core\scheduler.py`
- **Affected Function**: Line 245
- **Problem Description**: Broad exception catch without specific typing.
- **Why It Happens**: Lazy error handling
- **How to Reproduce**: Trigger any error
- **Expected Behaviour**: Should catch specific exceptions
- **Current Behaviour**: Catches everything including KeyboardInterrupt sometimes
- **Suggested Fix**: Specify exception type
- **Confidence Level**: Medium

### 50. Print statement instead of standard logger
- **Bug ID**: AUTO-050
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\discovery\tank_discovery.py`
- **Affected Function**: Line 150
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 51. Print statement instead of standard logger
- **Bug ID**: AUTO-051
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\pipeline\district_discovery.py`
- **Affected Function**: Line 71
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 52. Print statement instead of standard logger
- **Bug ID**: AUTO-052
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\pipeline\logger.py`
- **Affected Function**: Line 65
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 53. Print statement instead of standard logger
- **Bug ID**: AUTO-053
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\pipeline\osm_discovery.py`
- **Affected Function**: Line 117
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 54. Print statement instead of standard logger
- **Bug ID**: AUTO-054
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\pipeline\osm_discovery.py`
- **Affected Function**: Line 119
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 55. Broad exception catch without specific typing
- **Bug ID**: AUTO-055
- **Severity**: Medium
- **Category**: Exception Handling
- **Affected File**: `backend\pipeline\scraper.py`
- **Affected Function**: Line 103
- **Problem Description**: Broad exception catch without specific typing.
- **Why It Happens**: Lazy error handling
- **How to Reproduce**: Trigger any error
- **Expected Behaviour**: Should catch specific exceptions
- **Current Behaviour**: Catches everything including KeyboardInterrupt sometimes
- **Suggested Fix**: Specify exception type
- **Confidence Level**: Medium

### 56. Print statement instead of standard logger
- **Bug ID**: AUTO-056
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\pipeline\search_engine.py`
- **Affected Function**: Line 78
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 57. Print statement instead of standard logger
- **Bug ID**: AUTO-057
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\pipeline\test_pipeline.py`
- **Affected Function**: Line 12
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 58. Print statement instead of standard logger
- **Bug ID**: AUTO-058
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\pipeline\test_pipeline.py`
- **Affected Function**: Line 29
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 59. Print statement instead of standard logger
- **Bug ID**: AUTO-059
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\pipeline\test_pipeline.py`
- **Affected Function**: Line 32
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 60. Print statement instead of standard logger
- **Bug ID**: AUTO-060
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\pipeline\test_pipeline.py`
- **Affected Function**: Line 34
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 61. Print statement instead of standard logger
- **Bug ID**: AUTO-061
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\pipeline\test_pipeline.py`
- **Affected Function**: Line 38
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 62. Print statement instead of standard logger
- **Bug ID**: AUTO-062
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\pipeline\test_pipeline.py`
- **Affected Function**: Line 41
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 63. Print statement instead of standard logger
- **Bug ID**: AUTO-063
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\pipeline\test_pipeline.py`
- **Affected Function**: Line 43
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 64. Print statement instead of standard logger
- **Bug ID**: AUTO-064
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\pipeline\test_pipeline.py`
- **Affected Function**: Line 46
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 65. Print statement instead of standard logger
- **Bug ID**: AUTO-065
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\pipeline\test_pipeline.py`
- **Affected Function**: Line 51
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 66. Print statement instead of standard logger
- **Bug ID**: AUTO-066
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\pipeline\test_pipeline.py`
- **Affected Function**: Line 53
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 67. Print statement instead of standard logger
- **Bug ID**: AUTO-067
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\pipeline\test_pipeline.py`
- **Affected Function**: Line 55
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 68. Print statement instead of standard logger
- **Bug ID**: AUTO-068
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\pipeline\test_pipeline.py`
- **Affected Function**: Line 56
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 69. Print statement instead of standard logger
- **Bug ID**: AUTO-069
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\pipeline\test_pipeline.py`
- **Affected Function**: Line 57
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 70. Print statement instead of standard logger
- **Bug ID**: AUTO-070
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\pipeline\test_pipeline.py`
- **Affected Function**: Line 58
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 71. Print statement instead of standard logger
- **Bug ID**: AUTO-071
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\pipeline\test_pipeline.py`
- **Affected Function**: Line 60
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 72. Broad exception catch without specific typing
- **Bug ID**: AUTO-072
- **Severity**: Medium
- **Category**: Exception Handling
- **Affected File**: `backend\pipeline\validator.py`
- **Affected Function**: Line 35
- **Problem Description**: Broad exception catch without specific typing.
- **Why It Happens**: Lazy error handling
- **How to Reproduce**: Trigger any error
- **Expected Behaviour**: Should catch specific exceptions
- **Current Behaviour**: Catches everything including KeyboardInterrupt sometimes
- **Suggested Fix**: Specify exception type
- **Confidence Level**: Medium

### 73. Print statement instead of standard logger
- **Bug ID**: AUTO-073
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\auto_backup_setup.py`
- **Affected Function**: Line 12
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 74. Print statement instead of standard logger
- **Bug ID**: AUTO-074
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\auto_backup_setup.py`
- **Affected Function**: Line 18
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 75. Print statement instead of standard logger
- **Bug ID**: AUTO-075
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\auto_backup_setup.py`
- **Affected Function**: Line 19
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 76. Print statement instead of standard logger
- **Bug ID**: AUTO-076
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\auto_backup_setup.py`
- **Affected Function**: Line 38
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 77. Print statement instead of standard logger
- **Bug ID**: AUTO-077
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\auto_backup_setup.py`
- **Affected Function**: Line 39
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 78. Print statement instead of standard logger
- **Bug ID**: AUTO-078
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\auto_backup_setup.py`
- **Affected Function**: Line 41
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 79. Print statement instead of standard logger
- **Bug ID**: AUTO-079
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\auto_backup_setup.py`
- **Affected Function**: Line 42
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 80. Print statement instead of standard logger
- **Bug ID**: AUTO-080
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\auto_backup_setup.py`
- **Affected Function**: Line 44
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 81. Print statement instead of standard logger
- **Bug ID**: AUTO-081
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\auto_backup_setup.py`
- **Affected Function**: Line 47
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 82. Print statement instead of standard logger
- **Bug ID**: AUTO-082
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\migrate_db.py`
- **Affected Function**: Line 17
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 83. Print statement instead of standard logger
- **Bug ID**: AUTO-083
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\migrate_db.py`
- **Affected Function**: Line 19
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 84. Print statement instead of standard logger
- **Bug ID**: AUTO-084
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\migrate_db.py`
- **Affected Function**: Line 21
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 85. Print statement instead of standard logger
- **Bug ID**: AUTO-085
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\migrate_db.py`
- **Affected Function**: Line 25
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 86. Print statement instead of standard logger
- **Bug ID**: AUTO-086
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\mongo_migration.py`
- **Affected Function**: Line 25
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 87. Print statement instead of standard logger
- **Bug ID**: AUTO-087
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\mongo_migration.py`
- **Affected Function**: Line 37
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 88. Print statement instead of standard logger
- **Bug ID**: AUTO-088
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\mongo_migration.py`
- **Affected Function**: Line 50
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 89. Print statement instead of standard logger
- **Bug ID**: AUTO-089
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\mongo_migration.py`
- **Affected Function**: Line 139
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 90. Print statement instead of standard logger
- **Bug ID**: AUTO-090
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\mongo_migration.py`
- **Affected Function**: Line 141
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 91. Print statement instead of standard logger
- **Bug ID**: AUTO-091
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\mongo_migration.py`
- **Affected Function**: Line 160
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 92. Print statement instead of standard logger
- **Bug ID**: AUTO-092
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\mongo_migration.py`
- **Affected Function**: Line 162
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 93. Print statement instead of standard logger
- **Bug ID**: AUTO-093
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\seed_mongodb.py`
- **Affected Function**: Line 37
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 94. Print statement instead of standard logger
- **Bug ID**: AUTO-094
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\seed_mongodb.py`
- **Affected Function**: Line 42
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 95. Print statement instead of standard logger
- **Bug ID**: AUTO-095
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\seed_mongodb.py`
- **Affected Function**: Line 44
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 96. Print statement instead of standard logger
- **Bug ID**: AUTO-096
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\seed_mongodb.py`
- **Affected Function**: Line 46
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 97. Print statement instead of standard logger
- **Bug ID**: AUTO-097
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\seed_sqlite_places.py`
- **Affected Function**: Line 19
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 98. Print statement instead of standard logger
- **Bug ID**: AUTO-098
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\seed_sqlite_places.py`
- **Affected Function**: Line 21
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 99. Print statement instead of standard logger
- **Bug ID**: AUTO-099
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\seed_sqlite_places.py`
- **Affected Function**: Line 36
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 100. Print statement instead of standard logger
- **Bug ID**: AUTO-100
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\seed_sqlite_places.py`
- **Affected Function**: Line 62
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 101. Print statement instead of standard logger
- **Bug ID**: AUTO-101
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\system_guard.py`
- **Affected Function**: Line 31
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 102. Print statement instead of standard logger
- **Bug ID**: AUTO-102
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\system_guard.py`
- **Affected Function**: Line 36
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 103. Print statement instead of standard logger
- **Bug ID**: AUTO-103
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\system_guard.py`
- **Affected Function**: Line 38
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 104. Print statement instead of standard logger
- **Bug ID**: AUTO-104
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\system_guard.py`
- **Affected Function**: Line 65
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 105. Print statement instead of standard logger
- **Bug ID**: AUTO-105
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\system_guard.py`
- **Affected Function**: Line 67
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 106. Print statement instead of standard logger
- **Bug ID**: AUTO-106
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\system_guard.py`
- **Affected Function**: Line 68
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 107. Print statement instead of standard logger
- **Bug ID**: AUTO-107
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\system_guard.py`
- **Affected Function**: Line 74
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 108. Print statement instead of standard logger
- **Bug ID**: AUTO-108
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\system_guard.py`
- **Affected Function**: Line 77
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 109. Print statement instead of standard logger
- **Bug ID**: AUTO-109
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\system_guard.py`
- **Affected Function**: Line 82
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 110. Print statement instead of standard logger
- **Bug ID**: AUTO-110
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\system_guard.py`
- **Affected Function**: Line 89
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 111. Print statement instead of standard logger
- **Bug ID**: AUTO-111
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\system_guard.py`
- **Affected Function**: Line 108
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 112. Print statement instead of standard logger
- **Bug ID**: AUTO-112
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\system_guard.py`
- **Affected Function**: Line 110
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 113. Print statement instead of standard logger
- **Bug ID**: AUTO-113
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\system_guard.py`
- **Affected Function**: Line 116
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 114. Print statement instead of standard logger
- **Bug ID**: AUTO-114
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\system_guard.py`
- **Affected Function**: Line 118
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 115. Print statement instead of standard logger
- **Bug ID**: AUTO-115
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\system_guard.py`
- **Affected Function**: Line 120
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 116. Print statement instead of standard logger
- **Bug ID**: AUTO-116
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\system_guard.py`
- **Affected Function**: Line 136
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 117. Print statement instead of standard logger
- **Bug ID**: AUTO-117
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\utils\check_db.py`
- **Affected Function**: Line 8
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 118. Print statement instead of standard logger
- **Bug ID**: AUTO-118
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\utils\check_db.py`
- **Affected Function**: Line 13
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 119. Print statement instead of standard logger
- **Bug ID**: AUTO-119
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\utils\check_db.py`
- **Affected Function**: Line 15
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 120. Print statement instead of standard logger
- **Bug ID**: AUTO-120
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\utils\generate_kb.py`
- **Affected Function**: Line 8
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 121. Print statement instead of standard logger
- **Bug ID**: AUTO-121
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\utils\generate_kb.py`
- **Affected Function**: Line 11
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 122. Print statement instead of standard logger
- **Bug ID**: AUTO-122
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\utils\generate_kb.py`
- **Affected Function**: Line 41
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 123. Print statement instead of standard logger
- **Bug ID**: AUTO-123
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\utils\generate_kb.py`
- **Affected Function**: Line 50
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 124. Print statement instead of standard logger
- **Bug ID**: AUTO-124
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\utils\inspect_db.py`
- **Affected Function**: Line 6
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 125. Print statement instead of standard logger
- **Bug ID**: AUTO-125
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\utils\inspect_db.py`
- **Affected Function**: Line 12
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 126. Print statement instead of standard logger
- **Bug ID**: AUTO-126
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\utils\inspect_db.py`
- **Affected Function**: Line 14
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 127. Print statement instead of standard logger
- **Bug ID**: AUTO-127
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\utils\inspect_db.py`
- **Affected Function**: Line 16
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 128. Print statement instead of standard logger
- **Bug ID**: AUTO-128
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\utils\inspect_db.py`
- **Affected Function**: Line 18
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 129. Print statement instead of standard logger
- **Bug ID**: AUTO-129
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\utils\mock_injector.py`
- **Affected Function**: Line 14
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 130. Print statement instead of standard logger
- **Bug ID**: AUTO-130
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\utils\mock_injector.py`
- **Affected Function**: Line 42
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 131. Print statement instead of standard logger
- **Bug ID**: AUTO-131
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\utils\verify_security.py`
- **Affected Function**: Line 7
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 132. Print statement instead of standard logger
- **Bug ID**: AUTO-132
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\utils\verify_security.py`
- **Affected Function**: Line 12
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 133. Print statement instead of standard logger
- **Bug ID**: AUTO-133
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\utils\verify_security.py`
- **Affected Function**: Line 15
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 134. Print statement instead of standard logger
- **Bug ID**: AUTO-134
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\utils\verify_security.py`
- **Affected Function**: Line 23
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 135. Print statement instead of standard logger
- **Bug ID**: AUTO-135
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\utils\verify_security.py`
- **Affected Function**: Line 25
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 136. Print statement instead of standard logger
- **Bug ID**: AUTO-136
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\utils\verify_security.py`
- **Affected Function**: Line 27
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 137. Print statement instead of standard logger
- **Bug ID**: AUTO-137
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\utils\verify_security.py`
- **Affected Function**: Line 29
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 138. Print statement instead of standard logger
- **Bug ID**: AUTO-138
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\utils\verify_security.py`
- **Affected Function**: Line 32
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 139. Print statement instead of standard logger
- **Bug ID**: AUTO-139
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\utils\verify_security.py`
- **Affected Function**: Line 36
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 140. Print statement instead of standard logger
- **Bug ID**: AUTO-140
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\utils\verify_security.py`
- **Affected Function**: Line 38
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 141. Print statement instead of standard logger
- **Bug ID**: AUTO-141
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\utils\verify_security.py`
- **Affected Function**: Line 41
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 142. Print statement instead of standard logger
- **Bug ID**: AUTO-142
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\utils\verify_security.py`
- **Affected Function**: Line 43
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 143. Print statement instead of standard logger
- **Bug ID**: AUTO-143
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\scripts\utils\verify_security.py`
- **Affected Function**: Line 44
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 144. Print statement instead of standard logger
- **Bug ID**: AUTO-144
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\tests\test_auto_approval.py`
- **Affected Function**: Line 16
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 145. Print statement instead of standard logger
- **Bug ID**: AUTO-145
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\tests\test_auto_approval.py`
- **Affected Function**: Line 43
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 146. Print statement instead of standard logger
- **Bug ID**: AUTO-146
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\tests\test_auto_approval.py`
- **Affected Function**: Line 49
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 147. Print statement instead of standard logger
- **Bug ID**: AUTO-147
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\tests\test_batch_optimization.py`
- **Affected Function**: Line 15
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 148. Print statement instead of standard logger
- **Bug ID**: AUTO-148
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\tests\test_batch_optimization.py`
- **Affected Function**: Line 21
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 149. Print statement instead of standard logger
- **Bug ID**: AUTO-149
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\tests\test_batch_optimization.py`
- **Affected Function**: Line 23
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium

### 150. Print statement instead of standard logger
- **Bug ID**: AUTO-150
- **Severity**: Low
- **Category**: Logging
- **Affected File**: `backend\tests\test_mas_flow.py`
- **Affected Function**: Line 13
- **Problem Description**: Print statement instead of standard logger.
- **Why It Happens**: Convenience
- **How to Reproduce**: Check stdout
- **Expected Behaviour**: Should use Python logging framework
- **Current Behaviour**: Uses raw print
- **Suggested Fix**: Replace with logger.info()
- **Confidence Level**: Medium


## Final Project Assessment

1. **Overall Project Health Score**: 65/100
2. **Code Quality Score**: 60/100
3. **Security Score**: 50/100
4. **Performance Score**: 70/100
5. **Architecture Score**: 65/100
6. **UI/UX Score**: 85/100
7. **Scalability Score**: 75/100
8. **Maintainability Score**: 60/100

### Audit Conclusion
The project has excellent UI/UX but suffers from critical security misconfigurations (hardcoded API keys, exposed keystores) and outdated dependencies. The code quality can be improved by replacing raw print statements with SecureLogger, handling exceptions gracefully, and ensuring that all API interactions have proper timeout and retry logic. Please refer to the specific bugs listed above for targeted remediation.
