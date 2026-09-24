# FastME

**FastME** is a high-performance large-number library for Roblox Luau.

It represents numbers as a compact normalized mantissa/exponent pair:

```luau
{mantissa, exponent}
```

For example:

```text
{1.25, 6}  ==  1.25e6  ==  1,250,000
{9.5, 120} ==  9.5e120
```

FastME is designed for games that need values far beyond normal floating-point display ranges while keeping arithmetic, comparisons, formatting, parsing, and common game-math operations fast.

> Current version: **2.8.0**  
> Build: **slowpath-rebuild-20260924-a**

---

## Highlights

- Native Luau-oriented implementation with `--!native` and `--!optimize 2`
- Compact two-number representation
- Fast construction from ordinary numbers and strings
- `string.byte`-driven recovery path in `fromString`
- Arithmetic, roots, powers, logarithms, comparisons, rounding, interpolation, percentages, means, trigonometry, combinatorics, and aggregates
- Human-readable suffix formatting such as `K`, `M`, `B`, `Qa`, `Qi`, and generated higher suffixes
- Scientific and engineering notation
- Human-formatted parsing such as `"1.25Qa"`
- Serialization / deserialization
- Mutable/in-place and output-buffer APIs
- Cached factorial and log-factorial tables for small/medium integer inputs
- Special-value handling for zero, `NaN`, `Infinity`, and `-Infinity`

---

## Installation

Create a `ModuleScript` named `FastME` and paste `FastME.luau` into it.

Then require it:

```luau
local FastME = require(path.To.FastME)
```

For best performance, leave these directives at the top of the module:

```luau
--!native
--!optimize 2
```

---

## Value Representation

FastME values use:

```luau
export type Value = {number}
```

The first element is the mantissa and the second is the base-10 exponent.

```luau
local value = FastME.raw(1.2345, 100)

print(value[1]) -- 1.2345
print(value[2]) -- 100
```

Normalized finite non-zero values generally keep the mantissa in:

```text
1 <= |mantissa| < 10
```

Do not manually change the mantissa/exponent of a normalized value unless you intentionally want a raw representation.

---

## Quick Start

```luau
local FastME = require(path.To.FastME)

local coins = FastME.fromNumber(1250)
local reward = FastME.fromString("2.5e6")

local total = FastME.add(coins, reward)

print(FastME.toString(total))
print(FastME.toSuffix(total))
print(FastME.toScientific(total))
```

Example output:

```text
2501250
2.50M
2.50e6
```

---

## Creating Values

### `FastME.new(mantissa, exponent?)`

Creates and normalizes a value.

```luau
local x = FastME.new(125, 4)
-- approximately {1.25, 6}
```

### `FastME.raw(mantissa, exponent)`

Creates a value without normalization.

```luau
local x = FastME.raw(1.25, 6)
```

### Constants

```luau
FastME.zero()
FastME.one()
FastME.two()
FastME.ten()
FastME.pi()
FastME.e()
```

### Conversion

```luau
local a = FastME.fromNumber(123456)
local b = FastME.fromString("1.23456e5")

local number = FastME.toNumber(a)
local normalized = FastME.normalize({123.456, 3})

local copy = FastME.clone(a)
local mantissa, exponent = FastME.unpack(a)
```

`toNumber` follows normal IEEE-754 number limits. Extremely large FastME values can therefore become `math.huge`, and extremely small values can underflow when converted back to a normal Luau number.

---

## Parsing

### `FastME.fromString(string)`

Parses ordinary and scientific numeric strings.

```luau
FastME.fromString("1250")
FastME.fromString("-3.75")
FastME.fromString("1.25e1000")
FastME.fromString("4.2E-500")
```

The ordinary finite-number path uses `tonumber`. Overflow/underflow recovery uses a byte-oriented scan so extremely large scientific values can still be represented without depending on normal f64 range.

### `FastME.fromFormattedString(string)`

Parses common suffix notation.

```luau
FastME.fromFormattedString("1.5K")
FastME.fromFormattedString("2.25M")
FastME.fromFormattedString("7.1Qa")
FastME.fromFormattedString("3.4Vg")
```

Recognized built-in parse suffixes include:

```text
K M B T
Qa Qi Sx Sp Oc No
Dc Ud Dd Td Qad Qid Sxd Spd Ocd Nod Vg
```

Common upper/lowercase spellings are supported.

---

## Arithmetic

```luau
local a = FastME.fromString("1e100")
local b = FastME.fromString("2.5e99")

local sum = FastME.add(a, b)
local difference = FastME.sub(a, b)
local product = FastME.mul(a, b)
local quotient = FastME.div(a, b)

local reciprocal = FastME.recip(a)

local squared = FastME.square(a)
local cubed = FastME.cube(a)

local squareRoot = FastME.sqrt(a)
local cubeRoot = FastME.cbrt(a)

local p5 = FastME.powInt(a, 5)
local power = FastME.pow(a, 2.5)

local root = FastME.nthRoot(a, 3)
-- alias:
local sameRoot = FastME.root(a, 3)

local shifted = FastME.scale10(a, 25)
```

---

## Scalar Arithmetic

When one operand is an ordinary Luau number:

```luau
local a = FastME.fromString("1e50")

FastME.addNumber(a, 25)
FastME.subNumber(a, 25)
FastME.mulNumber(a, 2)
FastME.divNumber(a, 2)
```

---

## Comparison and Predicates

```luau
FastME.compare(a, b)
FastME.compareAbs(a, b)

FastME.eq(a, b)
FastME.neq(a, b)

FastME.lt(a, b)
FastME.lte(a, b)
FastME.gt(a, b)
FastME.gte(a, b)

FastME.isZero(a)
FastME.isOne(a)
FastME.isNaN(a)
FastME.isInfinity(a)
FastME.isFinite(a)
FastME.isPositive(a)
FastME.isNegative(a)

FastME.sign(a)
FastME.abs(a)
FastME.neg(a)

FastME.almostEqual(a, b)
FastME.almostEqual(a, b, 1e-10)
```

`compare` returns:

```text
-1  a < b
 0  a == b
 1  a > b
```

---

## Min / Max / Clamp

```luau
FastME.min(a, b)
FastME.max(a, b)
FastME.clamp(value, minimum, maximum)
```

---

## Logarithms and Exponentials

```luau
FastME.log10(a)
FastME.ln(a)
FastME.log2(a)
FastME.log(a, 5)

FastME.fromLog10(1000)
FastME.exp10(1000)
FastME.exp2(100)
FastME.exp(100)
```

The logarithm functions return normal Luau numbers representing the logarithm, while the exponential constructors return FastME values.

---

## Rounding

```luau
FastME.trunc(a)
FastME.floor(a)
FastME.ceil(a)
FastME.round(a)
FastME.frac(a)

FastME.roundSignificant(a, 6)
```

---

## Distance and Interpolation

```luau
FastME.distance(a, b)
FastME.absDelta(a, b)

FastME.lerp(a, b, 0.5)
FastME.inverseLerp(a, b, value)

FastME.remap(
	value,
	oldMinimum,
	oldMaximum,
	newMinimum,
	newMaximum
)

FastME.smoothstep(edge0, edge1, value)
FastME.smootherstep(edge0, edge1, value)
```

---

## Means and Geometry

```luau
FastME.mean(a, b)
FastME.geometricMean(a, b)
FastME.harmonicMean(a, b)

FastME.rms(a, b)
FastME.hypot(a, b)

FastME.midpoint(a, b)
```

---

## Percent and Growth

```luau
FastME.percentOf(a, 25)
FastME.increasePercent(a, 10)
FastME.decreasePercent(a, 10)

local change = FastME.percentChange(oldValue, newValue)
local orders = FastME.ordersBetween(a, b)
```

---

## Remainder and Modulo

```luau
local remainder = FastME.rem(a, b)
local modulo = FastME.mod(a, b)
```

FastME uses dedicated close-exponent paths where the operation can be safely performed directly and falls back to normalized large-number arithmetic where needed.

---

## Combinatorics

```luau
local f = FastME.factorial(100)
local logF = FastME.log10Factorial(100)

local permutations = FastME.permutation(100, 10)
local combinations = FastME.combination(100, 10)

-- aliases
local permutations2 = FastME.nPr(100, 10)
local combinations2 = FastME.nCr(100, 10)
```

FastME caches factorial and base-10 log-factorial data through `256`, making common combinatoric calls significantly cheaper than rebuilding the product every time.

For larger inputs, FastME switches to logarithmic/Stirling-style computation where appropriate.

---

## Gamma and Beta

```luau
local logGamma = FastME.logGamma(5.5)
local gamma = FastME.gamma(5.5)
local beta = FastME.beta(2.5, 3.5)
```

---

## Trigonometry

```luau
FastME.sin(a)
FastME.cos(a)
FastME.tan(a)

FastME.asin(a)
FastME.acos(a)
FastME.atan(a)

FastME.rad(a)
FastME.deg(a)
```

Trigonometric functions ultimately operate within normal floating-point trigonometric range, so values too large to convert meaningfully to a normal number may not produce useful trig results.

---

## Aggregates

```luau
local values = {
	FastME.fromNumber(10),
	FastME.fromNumber(20),
	FastME.fromNumber(30),
}

local sum = FastME.sum(values)
local product = FastME.product(values)
local average = FastME.average(values)

local minimum = FastME.minOf(values)
local maximum = FastME.maxOf(values)
```

`minOf` and `maxOf` may return `nil` for an empty array.

---

## Formatting

FastME supports scientific, engineering, suffix, and general string formatting.

```luau
local x = FastME.fromString("1.234567e15")

print(FastME.toScientific(x))
print(FastME.toEngineering(x))
print(FastME.toSuffix(x))
print(FastME.toString(x))
print(FastME.format(x))
```

`FastME.format` is an alias of `FastME.toSuffix`.

### Format Configuration

```luau
FastME.FormatConfig.Precision = 2
FastME.FormatConfig.MaxPrecision = 8
FastME.FormatConfig.EStart = 3000
FastME.FormatConfig.ScientificStart = -6
FastME.FormatConfig.TrimZeros = false
```

Defaults:

| Setting | Default | Meaning |
|---|---:|---|
| `Precision` | `2` | Default suffix precision |
| `MaxPrecision` | `8` | Maximum precision used by suffix formatting |
| `EStart` | `3000` | Exponent threshold for `E...` exponent formatting |
| `ScientificStart` | `-6` | Lower exponent boundary used by suffix formatting |
| `TrimZeros` | `false` | Remove trailing decimal zeroes when enabled |

Example:

```luau
FastME.FormatConfig.TrimZeros = true
FastME.FormatConfig.Precision = 3

local x = FastME.fromString("1.2e12")

print(FastME.toSuffix(x))
-- 1.2T
```

### Built-in suffixes

FastME includes:

```text
K, M, B, T,
Qa, Qi, Sx, Sp, Oc, No,
Dc, Ud, Dd, Td,
Qad, Qid, Sxd, Spd, Ocd, Nod, Vg
```

It can generate additional suffix groups beyond the fixed table up to its internal suffix-generation limit.

### Exponent formatting

```luau
FastME.formatExponent(1_234_567, 2)
```

Example style:

```text
1.23M
```

### Suffix lookup

```luau
local suffix = FastME.getSuffix(5)
-- "Qa"
```

---

## Serialization

FastME provides a compact text representation for persistence/network payloads:

```luau
local value = FastME.fromString("1.23456789e100")

local encoded = FastME.serialize(value)
local decoded = FastME.deserialize(encoded)
```

Serialized form:

```text
mantissa@exponent
```

Example:

```text
1.23456789@100
```

`serialize` writes up to 17 significant digits for the mantissa so normal f64 precision can round-trip through the text representation.

---

## Special Values

FastME recognizes:

```luau
FastME.fromString("0")
FastME.fromNumber(math.huge)
FastME.fromNumber(-math.huge)
FastME.fromNumber(0 / 0)
```

Formatting returns:

```text
0
Infinity
-Infinity
NaN
```

Use the predicate functions when branching on these states.

---

## Performance

FastME is intended for hot game code.

The v2.x series has focused on:

- direct normalized arithmetic
- avoiding unnecessary API-to-API forwarding
- Luau-native-friendly builtin calls
- table-free or cache-backed hot paths where useful
- specialized small integer powers
- byte-based extreme-number parsing
- factorial/combinatoric caches
- aligned-mantissa interpolation and aggregate math
- reduced formatting helper chains

The supplied full API benchmark covers **137 public functions and aliases** at iteration counts from `10,000` to `1,000,000`.

Performance varies with:

- Roblox/Luau version
- native code generation
- input exponent distance
- allocation vs in-place APIs
- formatting precision
- special-value branches
- Studio vs live-server execution

For meaningful comparisons, benchmark inside Roblox using the same inputs and iteration counts between versions.

---

## Benchmarking

Recommended setup:

```luau
--!native
--!optimize 2
```

Always verify the loaded module before benchmarking:

```luau
print(FastME.VERSION)
print(FastME.BUILD)
```

Expected for this build:

```text
2.8.0
slowpath-rebuild-20260924-a
```

If the benchmark prints a different version, Studio is requiring a different ModuleScript or an older play/test session.

Stop the current session completely before swapping benchmark builds.

---

## Current v2.8.0 Build Note

The current `slowpath-rebuild-20260924-a` source contains duplicated operation statements in several **in-place / output-buffer** functions.

Affected code includes functions such as:

```text
addInto
subInto
mulInto
divInto
powInto

iadd
isub
imul
idiv
isquare
isqrt
ipow
ineg
iabs
```

Some duplicate calls only waste work, but several in-place forms can change the result twice. For example, applying `ineg` twice restores the original sign, and applying `isquare` twice computes a fourth power.

**Do not rely on these affected mutable APIs in this exact build until that duplication is patched.**

The ordinary immutable arithmetic APIs such as `add`, `sub`, `mul`, `div`, `pow`, `sqrt`, formatting, parsing, and combinatorics are separate from that issue.

---

## API Overview

### Construction / conversion

```text
new
raw
zero
one
two
ten
pi
e
clone
unpack
fromNumber
fromString
toNumber
normalize
```

### Arithmetic

```text
add
sub
mul
div
recip
square
sqrt
cube
cbrt
powInt
pow
nthRoot
root
scale10
```

### Scalar arithmetic

```text
addNumber
subNumber
mulNumber
divNumber
```

### Comparison / predicates

```text
compare
compareAbs
eq
neq
lt
lte
gt
gte
isZero
isOne
isNaN
isInfinity
isFinite
isPositive
isNegative
sign
abs
neg
almostEqual
```

### Min / max

```text
min
max
clamp
```

### Logs / exponentials

```text
log10
ln
log2
log
fromLog10
exp10
exp2
exp
```

### Rounding

```text
trunc
floor
ceil
round
frac
roundSignificant
```

### Distance / interpolation

```text
distance
absDelta
lerp
inverseLerp
remap
smoothstep
smootherstep
```

### Means / geometry

```text
mean
geometricMean
harmonicMean
rms
hypot
midpoint
```

### Percent / growth

```text
percentOf
increasePercent
decreasePercent
percentChange
ordersBetween
```

### Remainder

```text
rem
mod
```

### Combinatorics / special

```text
log10Factorial
factorial
permutation
combination
nPr
nCr
logGamma
gamma
beta
```

### Trigonometry

```text
sin
cos
tan
asin
acos
atan
rad
deg
```

### Aggregates

```text
sum
product
average
minOf
maxOf
```

### Formatting / parsing

```text
toScientific
toEngineering
toSuffix
toString
format
fromFormattedString
getSuffix
formatExponent
serialize
deserialize
```

### Mutable / output-buffer

```text
set
copyInto
addInto
subInto
mulInto
divInto
powInto

iadd
isub
imul
idiv
isquare
isqrt
ipow
ineg
iabs
ifma
```

See the v2.8.0 build note above before using the mutable arithmetic APIs in build `slowpath-rebuild-20260924-a`.

---

## Example: Roblox Currency

```luau
local FastME = require(path.To.FastME)

local coins = FastME.zero()

local function addCoins(amount: number)
	coins = FastME.addNumber(coins, amount)
end

addCoins(100)
addCoins(2500)

print(FastME.toSuffix(coins))
```

---

## Example: Huge Upgrade Cost

```luau
local FastME = require(path.To.FastME)

local baseCost = FastME.fromNumber(100)
local growth = FastME.fromNumber(1.15)

local function costAtLevel(level: number)
	return FastME.mul(
		baseCost,
		FastME.powInt(growth, level)
	)
end

local cost = costAtLevel(1000)

print(FastME.toSuffix(cost))
print(FastME.toScientific(cost))
```

---

## Example: Save / Load

```luau
local encoded = FastME.serialize(playerCoins)

-- store encoded...

local restored = FastME.deserialize(encoded)
```

---

## Design Goal

FastME is optimized for the common large-number workload in Roblox:

1. Keep the representation tiny.
2. Keep ordinary arithmetic predictable.
3. Avoid converting huge values back into regular f64 numbers unless necessary.
4. Specialize hot paths that show up in real benchmarks.
5. Preserve numeric behavior when an optimization is not demonstrably safe.
6. Prefer Roblox Luau measurements over generic Lua benchmark assumptions.

---

## Version

```text
FastME 2.8.0
Build: slowpath-rebuild-20260924-a
```
