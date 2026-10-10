# FastNum (FastME)

## v2.9.6 maintenance: parser and Luau analyzer

- `fromStringInto(out, text)` now uses the same one-`tonumber` fast path as `fromString` for inputs up to 18 bytes. It still writes into the supplied two-element destination table, without allocating a new result.
- Normal decimal, scientific, exceptional and overflow/underflow inputs retain the existing fallback parser semantics.
- Replaced `--!nocheck` with `--!nonstrict` so Studio Script Analysis is no longer completely disabled for the main module. **This is not a claim of a clean strict typecheck.**
- Persistent `lbencode`/`lbdecode` formats and mathematical algorithms are unchanged.

Run `tests/FastNumParserRegression.server.lua` under Roblox Studio, with the main module named `FastNum` beside it. Check analyzer diagnostics and benchmark `fromStringInto` on representative short/large exponent workloads before merging.

---


**A fast, compact, mantissa/exponent number library for Roblox Luau.** Build incremental games, simulators, and other number-heavy systems that need values beyond the normal IEEE-754 magnitude range without giving up familiar math APIs.

**Current release:** `2.9.6` · **Module:** `FastNum.lua` · **Exported table:** `FastME`  
**Build:** `math-validation-20261007` · **Runtime:** Roblox Luau

[Source](FastNum.lua) · [Installation](#installation) · [Quick start](#quick-start) · [API overview](#construction-and-parsing) · [Limitations](#precision-and-limitations)

## Why FastNum?

- **Huge magnitudes:** normalized base-10 mantissa/exponent pairs represent values such as `1.25e10000` without converting the full value to a regular Luau number.
- **Native-oriented math:** `--!native` / `--!optimize 2`, specialized common operations, and scalar hot paths.
- **Multiple allocation models:** standard result values, reusable output tables, mutable operations, and raw two-number math.
- **Parsing and formatting:** decimal/scientific input, supported game suffixes, scientific/engineering notation, and compact suffix output.
- **Persistence helpers:** text pair serialization, an order-preserving scalar codec, and compatibility decoding for an earlier codec format.

> FastNum is the GitHub repository and source filename. The table returned by `require` is named **FastME**; examples below use that name.

## What's new in v2.9.6?

The 2.9.6 release carries forward the optimized v2.9.4 string parser and the v2.9.2 codec changes, with additional math and input validation:

- Validates finite, integer decimal exponents in normalization and conversion pathways.
- Keeps the optimized scientific-string parser and `fromStringInto` output-table API.
- Improves arithmetic and comparison behavior around NaN, infinity, and invalid exponent inputs.
- Includes large-exponent remainder/modulo handling (`rem` and `mod`), subject to finite mantissa precision.
- Uses a signed logarithmic scalar encoding for `lbencode`/`lbdecode`, with legacy-code decoding and `encodeData` retention logic.
- Retains `serialize`/`deserialize` for the **two-number FastME value format**, distinct from the scalar codec.

**Documentation scope:** this README describes the functions exposed by the current `FastNum.lua`. It does not claim a universal speedup or proof of correctness for every possible input.

## Installation

1. Open [`FastNum.lua`](FastNum.lua) and copy its contents.
2. In Roblox Studio, create a **ModuleScript** named `FastME`, for example under `ReplicatedStorage`, and paste the source.
3. Require the ModuleScript from a Script or LocalScript.

```luau
local FastME = require(game.ReplicatedStorage.FastME)

print(FastME.VERSION) -- 2.9.6
print(FastME.BUILD) -- math-validation-20261007
```

The source already declares `--!native` and `--!optimize 2`. Keep the directives at the top if you want Luau's native optimization paths when available.

## Quick start

```luau
local FastME = require(game.ReplicatedStorage.FastME)

local coins = FastME.fromNumber(1250)
local reward = FastME.fromString("2.5e6")
local total = FastME.add(coins, reward)

print(FastME.toSuffix(total)) -- 2.50M (default precision)
print(FastME.toScientific(total)) -- scientific notation
print(FastME.gt(total, coins)) -- true
```

### Representation

A FastME value is a two-element table:

```luau
local value = FastME.new(125, 4)
print(value[1], value[2]) -- approximately 1.25, 6
```

Its approximate mathematical value is `mantissa * 10^exponent`. Normalized nonzero finite values have `1 <= abs(mantissa) < 10`, and the exponent is a finite integer. Zero is represented as `{0, 0}`.

**Use `new` or `normalize` for externally constructed values.** `raw` and the raw pair functions assume the caller understands their input representation.

## Construction and parsing

| API | Purpose |
|---|---|
| `new(m, e?)` | Construct and normalize a mantissa/exponent value |
| `raw(m, e)` | Construct without normalization |
| `zero()`, `one()`, `two()`, `ten()`, `pi()`, `e()` | Common constructors |
| `fromNumber(x)` | Convert an ordinary Luau number |
| `fromString(s)` | Parse numeric/scientific text |
| `fromStringInto(out, s)` | Parse into an existing value table |
| `fromFormattedString(s)` | Parse a recognized formatted suffix |
| `toNumber(a)` | Convert back to an ordinary Luau number |
| `normalize(a)`, `clone(a)`, `unpack(a)` | Normalize, clone, or extract pair elements |

```luau
local huge = FastME.fromString("1.25e10000")
local decimal = FastME.fromString("-0.00025")
local short = FastME.fromFormattedString("2.5Qa")

local reusable = {0, 0}
FastME.fromStringInto(reusable, "7.5e250")
print(FastME.toScientific(reusable))
```

`fromString` accepts ordinary decimal and scientific numeric input; for examples such as `"1.5K"` and `"2.5Qa"` use `fromFormattedString` instead. Unparseable numeric text produces a NaN value; check it with `isNaN` when input is untrusted.

Supported parsed suffixes include `K`, `M`, `B`, `T`, `Qa`, `Qi`, `Sx`, `Sp`, `Oc`, `No` and the built-in extended group through `Vg`. The **formatter can generate more suffixes than the suffix parser recognizes**; don't assume every generated suffix will parse back.

## Arithmetic, roots and comparison

```luau
local a = FastME.fromString("1e100")
local b = FastME.fromString("2.5e99")

local sum = FastME.add(a, b)
local difference = FastME.sub(a, b)
local product = FastME.mul(a, b)
local quotient = FastME.div(a, b)

local squared = FastME.square(a)
local squareRoot = FastME.sqrt(a)
local power = FastME.powInt(b, 3)
local shifted = FastME.scale10(a, 5)

print(FastME.toScientific(sum))
print(FastME.gte(sum, a)) -- true
```

For ordinary scalar operands, prefer `addNumber`, `subNumber`, `mulNumber`, or `divNumber` where convenient.

| Group | Functions |
|---|---|
| Arithmetic | `add`, `sub`, `mul`, `div`, `recip`, `square`, `cube` |
| Roots / powers | `sqrt`, `cbrt`, `powInt`, `pow`, `nthRoot`, `root` (alias), `scale10` |
| Scalar arithmetic | `addNumber`, `subNumber`, `mulNumber`, `divNumber` |
| Comparison | `compare`, `compareAbs`, `eq`, `neq`, `lt`, `lte`, `gt`, `gte`, `almostEqual` |
| Predicates | `isZero`, `isOne`, `isNaN`, `isInfinity`, `isFinite`, `isPositive`, `isNegative` |
| Sign / bounds | `sign`, `abs`, `neg`, `min`, `max`, `clamp` |
| Remainder | `rem` (truncated quotient), `mod` (floor quotient) |

FastME's boolean ordering methods return `false` when a NaN operand makes an ordering invalid. The numeric `compare` function returns `0` for NaN cases; **do not interpret that as valid equality** without checking `isNaN`.

## Reusable values and raw-pair operations

Standard arithmetic (`add`, `mul`, etc.) returns a new value table. For hot code, reuse an output table or mutate an existing value intentionally.

```luau
local a = FastME.fromNumber(100)
local b = FastME.fromNumber(25)

-- Write a result to an existing table.
local out = {0, 0}
FastME.addInto(out, a, b)

-- Modify the first value directly.
FastME.iadd(a, b)

-- Return raw mantissa/exponent values without allocating a result table.
local m, e = FastME.addRaw(1.25, 6, 2.5, 6)
print(m, e)
```

- **Output table:** `set`, `copyInto`, `fromStringInto`, `addInto`, `subInto`, `mulInto`, `divInto`, `powInto`, `squareInto`, `sqrtInto`.
- **In-place:** `iadd`, `isub`, `imul`, `idiv`, `isquare`, `isqrt`, `ipow`, `ineg`, `iabs`, `ifma`.
- **Raw pairs:** `normalizeRaw`, `fromNumberRaw`, `fromStringRaw`, `toNumberRaw`, `addRaw`, `subRaw`, `mulRaw`, `divRaw`, `scaleRaw`, `divScalarRaw`, `recipRaw`, `squareRaw`, `sqrtRaw`, `fromLog10Raw`, `powIntRaw`, `powRaw`, `compareRaw`.

A raw pair function may return **two numbers** instead of a table. Supply normalized values to arithmetic raw functions unless the individual operation explicitly supports non-normalized input. An in-place call changes its first argument; use `clone` when the original must be preserved.

## Formatting

```luau
local value = FastME.fromString("1.234567e15")

print(FastME.toSuffix(value)) -- e.g. 1.23Qa
print(FastME.toScientific(value)) -- scientific notation
print(FastME.toEngineering(value)) -- engineering notation
print(FastME.toString(value)) -- general numeric representation
```

`format` is an alias of `toSuffix`. `getSuffix(group)` retrieves a suffix by 10^3 group index; `formatExponent(exponent, precision)` formats a number such as an exponent with compact units.

### Format configuration

| Setting | v2.9.6 default | Meaning |
|---|---:|---|
| `Precision` | `2` | Default suffix digits after decimal |
| `MaxPrecision` | `8` | Maximum digits accepted by suffix formatting |
| `EStart` | `3000` | Suffix formatter switches to compact `E`-exponent style |
| `ScientificStart` | `-6` | Lower boundary for suffix formatting |
| `TrimZeros` | `false` | Trim trailing zeros in formatted output |

```luau
FastME.FormatConfig.Precision = 3
FastME.FormatConfig.TrimZeros = true

local value = FastME.fromString("1.2e12")
print(FastME.toSuffix(value)) -- 1.2T
```

## Persistence and serialization

**FastME values** and **ordinary scalar numbers** have different encoders. Choose based on the data you are storing.

### 1. Serialize a mantissa/exponent FastME value

```luau
local balance = FastME.fromString("1.23456789e500")
local saved = FastME.serialize(balance) -- mantissa@exponent
local restored = FastME.deserialize(saved)
```

`serialize` uses a text pair of the form `mantissa@exponent`, with up to 17 significant digits for the mantissa. `deserialize` validates the exponent and normalizes the result. This is useful when you want to store values far beyond ordinary number magnitude limits.

### 2. Encode an ordinary scalar number

```luau
local score = 125000
local encoded = FastME.lbencode(score)
local decoded = FastME.lbdecode(encoded)

-- Keep the greater decoded score when replacing stored data.
local nextEncoded = FastME.encodeData(130000, encoded)
```

`lbencode` maps a finite ordinary number to a signed logarithmic scalar value. `lbdecode` reverses the mapping approximately; its decoder also recognizes the earlier large-offset encoding. `lbecode` remains an alias for `lbencode` for older callers. `encodeData(value, previousEncoded?)` keeps the larger decoded scalar value and can migrate an old code.

**Important:** the scalar codec is **not lossless** and should not be used as a replacement for `serialize` when saving very large FastME values, exact integer identifiers, currency requiring exact cents, or security-sensitive data. Save the complete pair with `serialize` when that is what you need.

## Additional mathematics

The module also includes:

| Category | Functions |
|---|---|
| Logs and exponentials | `log10`, `ln`, `log2`, `log`, `fromLog10`, `exp10`, `exp2`, `exp` |
| Rounding | `trunc`, `floor`, `ceil`, `round`, `frac`, `roundSignificant` |
| Interpolation | `distance`, `absDelta` (alias), `lerp`, `inverseLerp`, `remap`, `smoothstep`, `smootherstep` |
| Statistics / geometry | `mean`, `midpoint` (alias), `geometricMean`, `harmonicMean`, `rms`, `hypot` |
| Percent and growth | `percentOf`, `increasePercent`, `decreasePercent`, `percentChange`, `ordersBetween` |
| Combinatorics | `log10Factorial`, `factorial`, `permutation`, `combination`, `nPr` (alias), `nCr` (alias) |
| Special functions | `logGamma`, `gamma`, `beta` |
| Trigonometry | `sin`, `cos`, `tan`, `asin`, `acos`, `atan`, `rad`, `deg` |
| Aggregates | `sum`, `product`, `average`, `minOf`, `maxOf` |

Some functions, especially trigonometry and ordinary-number-returning helpers, rely on IEEE-754 range or accuracy. See [limitations](#precision-and-limitations).

## Example: incremental-game upgrade cost

```luau
local FastME = require(game.ReplicatedStorage.FastME)

local baseCost = FastME.fromNumber(100)
local multiplier = FastME.fromNumber(1.15)

local function upgradeCost(level: number)
    return FastME.mul(baseCost, FastME.powInt(multiplier, level))
end

local cost = upgradeCost(1000)
print(FastME.toSuffix(cost))
```

## Precision and limitations

FastME extends **magnitude**, not arbitrary numeric **precision**:

- The mantissa is an IEEE-754 double, so it has roughly **15–17 significant decimal digits**. Tiny additions to much larger magnitudes may be rounded away.
- The exponent is also stored in a double; exact integer granularity is limited to the IEEE-754 safe-integer range. Invalid, nonfinite and fractional exponents are rejected by key public validation/conversion paths.
- `toNumber` can overflow to infinity or underflow to zero. Keep values in FastME form for huge/small arithmetic.
- `rem`/`mod` use special paths for wide exponent gaps, but are still constrained by mantissa precision rather than providing arbitrary-precision modular arithmetic.
- Display formatting rounds output. Do **not** parse display suffixes as an archival storage format.
- NaN/infinity and undefined operations require explicit error handling in game logic.
- Native compilation, execution speed and memory use depend on the current Roblox/Luau engine, input shapes and allocation patterns. No universal per-function performance result is claimed here.

If your application needs exact decimal money, arbitrarily many integer digits, or cryptographic precision, use a library designed for those requirements.

## Benchmarking and regression checks

Run benchmarks **inside Roblox Studio** on the same machine, inputs and Luau settings, with warm-up and repeat runs. Compare like-for-like code paths (allocating `add` vs allocating `add`, or raw-pair `addRaw` vs `addRaw`). Verify the loaded module first:

```luau
local FastME = require(game.ReplicatedStorage.FastME)
assert(FastME.VERSION == "2.9.6", "Wrong FastME version loaded")

local x = FastME.fromString("1e1000")
assert(FastME.isFinite(x), "Huge number parsing failed")
assert(FastME.gt(FastME.addNumber(FastME.one(), 2), FastME.two()), "Arithmetic failed")

print("FastME", FastME.VERSION, FastME.BUILD)
```

Recommended additional regression categories: ordinary and extreme string parsing, negative/zero cases, arithmetic identities, NaN/infinity propagation, remainders, scalar-codec round-trips, serialization round-trips, and in-place/output-table behavior. Benchmark results are not correctness proofs.

## Migrating from older versions

- **From v2.8.0:** replace the previous ModuleScript source. The v2.8.0 README included build-specific warnings about duplicated mutable operations; those notes described **that older build**, not the current source.
- **From v2.9.1:** use the v2.9.6 `FastNum.lua` for the newer parsing, scalar codec, and validation paths. Test game-specific inputs and saved values before deploying.
- **Stored scalar leaderboard values:** `lbdecode` includes compatibility handling for legacy large-offset encodings. Re-encoding in the new format is recommended after verifying decoded values.
- **Serialized FastME pairs:** continue using `serialize`/`deserialize`; do not confuse them with `lbencode`/`lbdecode`.

## Development

Issues, regression reports, benchmark comparisons and reproducible test cases are welcome in this repository's [issue tracker](https://github.com/SillyDev2026/FastNum/issues). When reporting a math bug, include the exact input, expected and observed values, module version/build, and whether the test ran in Roblox Studio or another Lua runtime.

---

**FastNum v2.9.6 — optimized Luau, explicit numerical trade-offs, and a complete public API.**
