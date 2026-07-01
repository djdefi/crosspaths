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

-- Invoke refactored Config builders under the mock to catch runtime errors in the
-- widget factory / spec-table loop (not just load-time errors).
TestRunner.runTest("Config builders run (factory smoke)", function()
    Crosspaths.db.settings = Crosspaths.db.settings or {}
    Crosspaths.db.settings.tracking = Crosspaths.db.settings.tracking or {}
    local parent = MockWoW._makeFrame()
    parent.generalYOffset = -100 -- numeric field the builder reads (mock returns tables otherwise)
    local ok, err = pcall(function()
        Crosspaths.Config:CreateTrackingSettings(parent)
    end)
    TestRunner.assertTrue(ok, "CreateTrackingSettings runs without error: " .. tostring(err))
    TestRunner.assertType(Crosspaths.Config.CreateCheckbox, "function", "CreateCheckbox factory present")
end)

os.exit(TestRunner.printResults())
