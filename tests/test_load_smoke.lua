#!/usr/bin/env lua
-- Crosspaths load smoke test
-- Loads every real module (Core, Logging, Engine, Tracker, UI, Config) into the mock
-- environment and asserts they load without error. This can't verify visual UI, but it
-- catches syntax errors, undefined globals/helpers, and load-time regressions that
-- luacheck misses -- a cheap guard for the UI/Config refactors.

package.path = package.path .. ";./?.lua;./tests/?.lua"

local TestRunner = require("test_runner")
local MockWoW = require("mock_wow")

local Crosspaths = MockWoW.setupMockEnvironment()

local modules = { "Core.lua", "Logging.lua", "Engine.lua", "Tracker.lua", "UI.lua", "Config.lua" }
for _, module in ipairs(modules) do
    TestRunner.runTest("load " .. module, function()
        local ok, err = pcall(function() MockWoW.loadAddonModule(module, Crosspaths) end)
        TestRunner.assertTrue(ok, module .. " loads without error: " .. tostring(err))
    end)
end

-- Key module tables are wired up after load
TestRunner.runTest("modules registered", function()
    TestRunner.assertType(Crosspaths.Engine, "table", "Engine registered")
    TestRunner.assertType(Crosspaths.UI, "table", "UI registered")
    TestRunner.assertType(Crosspaths.Config, "table", "Config registered")
    TestRunner.assertType(Crosspaths.Colorize, "function", "Colorize helper present")
end)

os.exit(TestRunner.printResults())
