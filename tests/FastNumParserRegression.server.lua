--!strict
-- Roblox Studio Script beside FastNum ModuleScript.
local F = require(script.Parent:WaitForChild("FastNum"))
assert(F.VERSION == "2.9.6")
local out = F.zero()
local samples = {
    "0", "-0", "1", "-1", "100", "0.001", "1e3", "-3.5e-10",
    "2e1000", "1e-400", "-3.5e-400", "+1.25E+12345", "000000123",
    "  -3.5e-10  ", "1e309", "-1e-325", "2e999999", "bad", "NaN",
    "1e999999", "1e+", "++2", "1.2.3", "",
}
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
local huge = F.fromStringInto(out, "2e1000")
assert(huge == out and huge[1] == 2 and huge[2] == 1000, "Huge exponent lost during parsing")
local tiny = F.fromStringInto(out, "-3.5e-400")
assert(tiny == out and tiny[1] == -3.5 and tiny[2] == -400, "Tiny exponent lost during parsing")
local malformed = F.fromStringInto(out, "1e+")
assert(malformed == out and F.isNaN(malformed), "Malformed exponent accepted")
local restored = F.deserialize(F.serialize(F.fromString("2e1000")))
assert(restored[1] == 2 and restored[2] == 1000, "Huge exponent serialization regressed")
print("FastNum v2.9.6 parser regression PASS")
