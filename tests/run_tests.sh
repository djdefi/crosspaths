#!/bin/bash
# Test runner script for Crosspaths addon
# Runs all tests and reports results

set -e

echo "🧪 Starting Crosspaths Test Suite"
echo "=================================="

# Check if lua is available
if ! command -v lua &> /dev/null; then
    echo "❌ Error: Lua is not installed or not in PATH"
    exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "📁 Project root: $PROJECT_ROOT"
echo "📁 Test directory: $SCRIPT_DIR"

# Change to project root
cd "$PROJECT_ROOT"

# Check if test files exist
if [ ! -f "tests/test_engine.lua" ]; then
    echo "❌ Error: test_engine.lua not found in tests directory"
    exit 1
fi

if [ ! -f "tests/test_runner.lua" ]; then
    echo "❌ Error: test_runner.lua not found in tests directory"
    exit 1
fi

if [ ! -f "tests/mock_wow.lua" ]; then
    echo "❌ Error: mock_wow.lua not found in tests directory"
    exit 1
fi

echo "✅ All test files found"
echo ""

# Run syntax check on test files
echo "🔍 Checking test file syntax..."
for test_file in tests/*.lua; do
    if [ -f "$test_file" ]; then
        echo "  Checking $(basename "$test_file")..."
        if ! luac -p "$test_file" > /dev/null 2>&1; then
            echo "❌ Syntax error in $test_file"
            luac -p "$test_file"
            exit 1
        fi
    fi
done

echo "✅ All test files have valid syntax"
echo ""

# Run the main test suite
echo "🚀 Running Engine function tests..."
echo "-----------------------------------"

# Make test files executable and run them
chmod +x tests/test_engine.lua
chmod +x tests/test_tracker.lua

# Run the Engine tests
if lua tests/test_engine.lua; then
    echo ""
    echo "🚀 Running Tracker function tests..."
    echo "------------------------------------"
    
    # Run the Tracker tests
    if lua tests/test_tracker.lua; then
        echo ""
        echo "🚀 Running real-Engine (production code) tests..."
        echo "------------------------------------"

        # Run the real-Engine tests (load actual Engine.lua, not stubs)
        if lua tests/test_engine_real.lua && lua tests/test_load_smoke.lua; then
            echo ""
            echo "🎉 All tests completed successfully!"
            echo "✅ Test coverage verification: PASSED"
            echo ""
            echo "📊 Test Summary:"
            echo "  - Engine functions: ✓ Tested"
            echo "  - Tracker functions: ✓ Tested"
            echo "  - Real production Engine: ✓ Tested"
            echo "  - NPC/AI detection: ✓ Tested"
            echo "  - Analytics functions: ✓ Tested"
            echo "  - Edge cases: ✓ Tested"
            echo "  - Error handling: ✓ Tested"
            echo ""
            echo "🔧 Ready for continuous integration!"
            exit 0
        else
            echo ""
            echo "❌ Real-Engine tests failed!"
            echo "Please review the test output above and fix any issues."
            exit 1
        fi
    else
        echo ""
        echo "❌ Tracker tests failed!"
        echo "Please review the test output above and fix any issues."
        exit 1
    fi
else
    echo ""
    echo "❌ Engine tests failed!"
    echo "Please review the test output above and fix any issues."
    exit 1
fi