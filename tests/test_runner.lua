#!/usr/bin/env lua
-- Test Runner for Crosspaths Engine
-- Provides a simple test framework for unit testing Engine functions

local TestRunner = {}

-- Test results tracking
TestRunner.totalTests = 0
TestRunner.passedTests = 0
TestRunner.failedTests = 0
TestRunner.results = {}

-- Assert functions
function TestRunner.assertEqual(actual, expected, message)
    TestRunner.totalTests = TestRunner.totalTests + 1
    message = message or string.format("Expected %s, got %s", tostring(expected), tostring(actual))
    
    if actual == expected then
        TestRunner.passedTests = TestRunner.passedTests + 1
        table.insert(TestRunner.results, {status = "PASS", message = message})
        return true
    else
        TestRunner.failedTests = TestRunner.failedTests + 1
        table.insert(TestRunner.results, {status = "FAIL", message = message})
        return false
    end
end

function TestRunner.assertTrue(condition, message)
    TestRunner.totalTests = TestRunner.totalTests + 1
    message = message or string.format("Expected truthy value, got %s", tostring(condition))
    
    if condition then
        TestRunner.passedTests = TestRunner.passedTests + 1
        table.insert(TestRunner.results, {status = "PASS", message = message})
        return true
    else
        TestRunner.failedTests = TestRunner.failedTests + 1
        table.insert(TestRunner.results, {status = "FAIL", message = message})
        return false
    end
end

function TestRunner.assertFalse(condition, message)
    TestRunner.totalTests = TestRunner.totalTests + 1
    message = message or string.format("Expected falsy value, got %s", tostring(condition))
    
    if not condition then
        TestRunner.passedTests = TestRunner.passedTests + 1
        table.insert(TestRunner.results, {status = "PASS", message = message})
        return true
    else
        TestRunner.failedTests = TestRunner.failedTests + 1
        table.insert(TestRunner.results, {status = "FAIL", message = message})
        return false
    end
end

function TestRunner.assertNotNil(value, message)
    TestRunner.totalTests = TestRunner.totalTests + 1
    message = message or string.format("Expected non-nil value, got %s", tostring(value))
    
    if value ~= nil then
        TestRunner.passedTests = TestRunner.passedTests + 1
        table.insert(TestRunner.results, {status = "PASS", message = message})
        return true
    else
        TestRunner.failedTests = TestRunner.failedTests + 1
        table.insert(TestRunner.results, {status = "FAIL", message = message})
        return false
    end
end

function TestRunner.assertType(value, expectedType, message)
    local actualType = type(value)
    message = message or string.format("Expected type %s, got %s", expectedType, actualType)
    return TestRunner.assertEqual(actualType, expectedType, message)
end

function TestRunner.assertGreaterThan(actual, expected, message)
    TestRunner.totalTests = TestRunner.totalTests + 1
    message = message or string.format("Expected %s > %s", tostring(actual), tostring(expected))
    
    if actual > expected then
        TestRunner.passedTests = TestRunner.passedTests + 1
        table.insert(TestRunner.results, {status = "PASS", message = message})
        return true
    else
        TestRunner.failedTests = TestRunner.failedTests + 1
        table.insert(TestRunner.results, {status = "FAIL", message = message})
        return false
    end
end

-- Test suite runner
function TestRunner.runTest(testName, testFunction)
    print(string.format("Running test: %s", testName))
    local success, error = pcall(testFunction)
    
    if not success then
        TestRunner.totalTests = TestRunner.totalTests + 1
        TestRunner.failedTests = TestRunner.failedTests + 1
        table.insert(TestRunner.results, {status = "ERROR", message = string.format("Test %s failed with error: %s", testName, error)})
    end
end

-- Print results
function TestRunner.printResults()
    print("\n" .. string.rep("=", 50))
    print("TEST RESULTS")
    print(string.rep("=", 50))
    
    for _, result in ipairs(TestRunner.results) do
        print(string.format("[%s] %s", result.status, result.message))
    end
    
    print(string.rep("-", 50))
    print(string.format("Total Tests: %d", TestRunner.totalTests))
    print(string.format("Passed: %d", TestRunner.passedTests))
    print(string.format("Failed: %d", TestRunner.failedTests))
    
    if TestRunner.failedTests == 0 then
        print("ALL TESTS PASSED! ✓")
        return 0
    else
        print(string.format("FAILURES: %d tests failed ✗", TestRunner.failedTests))
        return 1
    end
end

return TestRunner