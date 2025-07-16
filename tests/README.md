# Crosspaths Testing Framework

This directory contains comprehensive unit tests for the Crosspaths addon's Engine functions.

## Test Coverage

The test suite provides complete coverage for all new analytics functions added in recent commits:

### Core Engine Functions Tested

- **`GetStatsSummary()`** - Basic statistics aggregation
- **`GetRecentActivity()`** - Time-based activity analysis (24h, 7d, 30d)
- **`GetContextStats()`** - Encounter context breakdown with percentages
- **`GetClassStats()`** - Class distribution with detailed encounter statistics
- **`GetSessionStats()`** - Current session tracking and analytics
- **`GetTopPlayersByType()`** - Role-based analytics (tanks, healers, DPS, item level, achievements)

### Test Categories

1. **Functionality Tests** - Verify core function behavior with realistic mock data
2. **Data Validation** - Ensure proper data types and structure
3. **Edge Cases** - Handle empty/nil databases gracefully
4. **Role Detection** - Validate specialization-based role classification
5. **Sorting & Limits** - Verify proper ordering and result limiting
6. **Error Handling** - Test invalid inputs and edge conditions

## Test Architecture

### Files

- **`test_runner.lua`** - Simple test framework with assertions
- **`mock_wow.lua`** - Mock WoW API and comprehensive test data
- **`test_engine.lua`** - Complete Engine function test suite
- **`run_tests.sh`** - Test execution script for CI/CD

### Mock Data

The test suite uses realistic mock data including:

- **12 test players** across all classes and roles
- **Tank specs**: Protection Paladin/Warrior, Blood DK, Guardian Druid, Brewmaster Monk
- **Healer specs**: Holy/Discipline Priest, Restoration Druid/Shaman, Mistweaver Monk
- **DPS specs**: Frost Mage, Assassination Rogue
- **Varied encounter data**: Different zones, contexts, timestamps
- **Performance metrics**: Item levels, achievement points, mounts

### Assertion Functions

- `assertEqual(actual, expected, message)` - Exact value comparison
- `assertTrue(condition, message)` - Truthy value validation
- `assertFalse(condition, message)` - Falsy value validation
- `assertNotNil(value, message)` - Non-nil validation
- `assertType(value, expectedType, message)` - Type checking
- `assertGreaterThan(actual, expected, message)` - Numeric comparison

## Running Tests

### Local Development

```bash
# Run all tests
./tests/run_tests.sh

# Run specific test file
lua tests/test_engine.lua

# Check test syntax only
luac -p tests/*.lua
```

### Continuous Integration

Tests automatically run on every PR through GitHub Actions:

1. **Syntax Validation** - All test files must have valid Lua syntax
2. **Unit Test Execution** - Complete test suite with 181+ test cases
3. **Result Reporting** - Pass/fail status with detailed output

## Test Results

Current test coverage includes **181 test cases** covering:

- ✅ **Engine functions**: All new analytics functions tested
- ✅ **Analytics functions**: Time-based, role-based, and context analysis
- ✅ **Edge cases**: Empty databases, nil values, invalid inputs
- ✅ **Error handling**: Graceful degradation and proper error responses

## Adding New Tests

When adding new Engine functions:

1. **Add mock data** to `mock_wow.lua` if needed
2. **Write test cases** in `test_engine.lua` following existing patterns
3. **Test locally** with `./tests/run_tests.sh`
4. **Verify CI passes** on PR submission

### Test Template

```lua
TestRunner.runTest("Function Name - Test Description", function()
    local result = Engine:NewFunction()
    
    TestRunner.assertNotNil(result, "Result should not be nil")
    TestRunner.assertType(result, "table", "Result should be a table")
    TestRunner.assertTrue(#result > 0, "Should have some data")
    
    -- Test specific functionality
    for i, item in ipairs(result) do
        TestRunner.assertNotNil(item.field, "Item should have required field")
        TestRunner.assertType(item.field, "string", "Field should be string")
    end
end)
```

## Benefits

This testing framework provides:

- **Confidence** - All Engine functions work as expected
- **Regression Prevention** - Changes can't break existing functionality  
- **Documentation** - Tests serve as usage examples
- **Quality Assurance** - Every PR validated before merge
- **Development Speed** - Quick feedback on code changes

The test suite ensures that all advanced statistics and analytics features work correctly across different scenarios and edge cases, providing comprehensive validation for every PR.