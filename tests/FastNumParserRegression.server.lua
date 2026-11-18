--!strict
-- Roblox Studio Script beside FastNum ModuleScript.
local F = require(script.Parent:WaitForChild("FastNum"))
assert(F.VERSION == "2.9.6")
local out = F.zero()
local samples = {"0", "1", "-1", "100", "0.001", "1e3", "-3.5e-10", "2e1000", "1e-400", "bad", "NaN", "1e999999"}
for _, input in ipairs(samples) do
    local expected = F.fromString(input)
    local result = F.fromStringInto(out, input)
    assert(result == out, "fromStringInto must reuse destination")
    local m1, e1 = expected[1], expected[2]
    local m2, e2 = result[1], result[2]
    assert((m1 == m2 or (m1 ~= m1 and m2 ~= m2)) and e1 == e2,
        "Parser mismatch: " .. input)
end
local one = F.fromStringInto(out, "123.5")
assert(one == out and F.toNumber(out) == 123.5)
-- Invalid and oversized precision should not crash formatters or allocate huge format strings.
local unit = F.one()
for _, precision in {0/0, math.huge, -math.huge, 1000000000, -100} do
    for _, formatter in {F.toScientific, F.toEngineering, F.toSuffix, F.toString} do
        local ok, formatted = pcall(formatter, unit, precision)
        assert(ok and type(formatted) == "string" and #formatted < 128, "Unsafe formatting precision: " .. tostring(precision))
    end
    local ok, value = pcall(F.roundSignificant, unit, precision)
    assert(ok and F.isFinite(value), "Unsafe significant-digit precision: " .. tostring(precision))
end
print("FastNum v2.9.6 parser regression PASS")
