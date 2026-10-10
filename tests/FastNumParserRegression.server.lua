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
print("FastNum v2.9.6 parser regression PASS")
