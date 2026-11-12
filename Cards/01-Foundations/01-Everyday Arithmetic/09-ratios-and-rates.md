# Ratios and rates: comparing two quantities and scaling them together

[Syllabus](../../../SYLLABUS.md) → [Foundations](../README.md) → [Everyday Arithmetic](../README.md#s01) → Ratios and rates

---

## General Overview

A tin of paint. The label says **3 parts blue to 2 parts white** — not 3 litres and 2 litres, parts.

A part is any scoop, so long as every scoop is the same size — teaspoon or bucket, three of blue to two of white comes out the same colour. That is a **ratio**: two amounts of the same kind, side by side, where only their relative size matters. Written **3 : 2**, said "three to two".

A car covers 120 kilometres in 1.5 hours. Different kinds of amount: distance and time. Divide distance by time: 120 ÷ 1.5 = 80 kilometres per hour. That is a **rate**, how much of the first per one of the second.

**A ratio says how a whole splits up; a rate says how much per one. Both survive scaling: do the same to both sides and nothing changes.**

**What kind of fact this is:** two definitions, ratio and rate, and one rule about them: scaling both sides by the same number changes nothing, shown on this card in Why it works.

### The picture: a straight climb

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "The car, at 80 kilometres per hour"
    x-axis "Hours on the road" [0, 0.5, 1, 1.5]
    y-axis "Kilometres covered" 0 --> 130
    line [0, 40, 80, 120]
```

The car's distance, straight because the rate never changes: 40 kilometres by the half hour, 80 by the hour, 120 by the end. A rate is the steepness of that climb.

---

## The formula

Nothing to memorise. Two moves, on the numbers.

Splitting a total by a ratio:

**3 + 2 = 5 parts, and 15 litres ÷ 5 parts = 3 litres in one part, so blue = 3 × 3 = 9 litres and white = 2 × 3 = 6 litres**

Making a rate:

**120 kilometres ÷ 1.5 hours = 80 kilometres per hour**

**Read it aloud:** share the 15 litres over all 5 parts, then give blue 3 of them and white 2; a rate shares 120 kilometres over 1.5 hours, 80 for each hour.

| Piece | Plain meaning | In our example | Push it up and… |
| --- | --- | --- | --- |
| a part | one equal scoop | 3 litres | bigger tin, same colour |
| the ratio 3 : 2 | parts to each side | 3 blue, 2 white | raise the 3 alone: bluer paint |
| a rate | top ÷ bottom of a fraction | 80 km per hour | further per hour |
| a unit price | dollars per one | $2.25 ÷ 3 litres = $0.75 | the order costs more |

### When it holds

- **Every part is the same size.** The 3 : 2 counts equal scoops. Measure blue with a teaspoon and white with a bucket, and the paint is not 3 : 2 at all.
- **Both sides are scaled by the same number.** 9 litres to 6 is 3 : 2 times 3. Scale the blue alone, 9 litres against 2, and the colour changes.
- **The rate stays steady.** 80 kilometres per hour gives 40 kilometres by the half hour only if the car holds its speed. With a stop on the way, 80 is only an average, and the half-hour figure can be wrong.
- **Every litre costs the same.** Twelve litres at $0.75 cost $9.00 only with no bulk discount. A shop that sells big tins cheaper breaks the multiply.

---

## Why it works

### Step 0: a ratio only cares about relative size

9 litres of blue with 6 of white is the same colour as 3 with 2: both sides were multiplied by 3, so nothing shifted between them. **Both sides, same number** — the whole engine, and the cancelling move from [Fractions](07-fractions.md).

### Step 1: find what one part is worth

3 : 2 cuts the tin into 3 + 2 = 5 equal parts. The tin holds 15 litres, so one part is 15 ÷ 5 = 3 litres, and the mix is real: blue 9 litres, white 6. Two checks: 9 + 6 = 15, and 9 : 6 divided by 3 on both sides is 3 : 2 again.

### Step 2: a rate is the same move across different units

120 kilometres in 1.5 hours — as a fraction, 120 on top, 1.5 on the bottom. Divide until the bottom is 1: 120 ÷ 1.5 = 80 kilometres in one hour. The name carries the units, so you cannot lose them: kilometres **per** hour. Check it backwards, 80 × 1.5 = 120.

### Step 3: with a per-one figure, scaling is multiplying

Blue paint sells at 3 litres for $2.25. Per litre, 2.25 ÷ 3 = $0.75, so twelve litres cost 12 × 0.75 = **$9.00**. Second road, no unit price: twelve litres is four lots of three, and 4 × $2.25 = **$9.00**.

School calls two equal fractions a proportion; same move. A ratio with its bottom amount pinned at 100 is a percentage: [Percentages](10-percentages.md).

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| parts in the mix | 3 + 2 | 5 |
| litres in one part | 15 ÷ 5 | 3 |
| blue, then white | 3 × 3, then 2 × 3 | **9**, **6** |
| the check, back to the tin | 9 + 6 | 15 |
| the car's rate, and the check | 120 ÷ 1.5, then 80 × 1.5 | **80**, 120 |
| unit price | 2.25 ÷ 3 | **0.75** |
| twelve litres, and the other road | 12 × 0.75, then 4 × 2.25 | **9.00**, 9.00 |

Nine litres of blue, six of white. The car is doing 80 kilometres per hour, and twelve litres costs $9.00.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Dividing 15 by the 3 blue parts | 25 litres | Parts of 5 litres overflow the tin |
| Dividing 1.5 by 120 | 0.0125 hours per km | Upside down: time per kilometre |
| Multiplying the shelf price by 12 | $27.00 | $2.25 already buys 3 litres |

---

## Code, from first principles, and it actually runs

Nothing is imported. The tin is split by parts, then checked by adding the sides back. The rate is divided out, then checked by multiplying back. Twelve litres are priced by two roads that must agree.

### Python

```python
# Ratios and rates -- the check behind the card.  Nothing is imported.  Paint
# mixed 3 parts blue to 2 parts white, scaled up to a 15 litre tin.  A car that
# covers 120 km in 1.5 hours.  Blue paint sold at 3 litres for $2.25.
def row(name, value):
    print(f"{name:<34}{value:>11}")

blue_parts, white_parts, tin = 3, 2, 15
parts = blue_parts + white_parts
per_part = tin // parts                       # what one part is worth, in litres
blue, white = blue_parts * per_part, white_parts * per_part
row("parts in the mix, 3 blue + 2 white", parts)
row("litres in one part, 15 / 5", per_part)
row("blue litres and white litres", f"{blue} and {white}")
row("blue + white, back to the tin", blue + white)

km, hours = 120.0, 1.5
speed = km / hours                            # a rate: kilometres per one hour
row("car speed, 120 km / 1.5 hours", f"{speed:.0f}")
row("distance check, speed x 1.5 hours", f"{speed * hours:.0f}")
row("km by 0.5 hours and by 1 hour", f"{speed * 0.5:.0f} and {speed:.0f}")
price, litres = 2.25, 3
unit = price / litres                         # the same move: dollars per litre
row("unit price, $2.25 / 3 litres", f"{unit:.2f}")
row("twelve litres, 12 x unit price", f"{12 * unit:.2f}")
row("twelve litres, 4 x $2.25", f"{(12 // litres) * price:.2f}")
print(f"the three mistakes: {(tin // blue_parts) * parts} litres, {hours / km:.4f} hours per km, ${12 * price:.2f}")
assert parts == 5 and per_part == 3 and blue == 9 and white == 6 and blue + white == 15
assert speed == 80.0 and speed * hours == 120.0 and speed * 0.5 == 40.0
assert unit == 0.75 and 12 * unit == 9.0 and (12 // litres) * price == 9.0
print("ALL CHECKS PASS")
```

**Ran 2026-09-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
parts in the mix, 3 blue + 2 white          5
litres in one part, 15 / 5                  3
blue litres and white litres          9 and 6
blue + white, back to the tin              15
car speed, 120 km / 1.5 hours              80
distance check, speed x 1.5 hours         120
km by 0.5 hours and by 1 hour       40 and 80
unit price, $2.25 / 3 litres             0.75
twelve litres, 12 x unit price           9.00
twelve litres, 4 x $2.25                 9.00
the three mistakes: 25 litres, 0.0125 hours per km, $27.00
ALL CHECKS PASS
```

### Rust

Same numbers and labels, built with `rustc --edition 2021 -O`.

```rust
// Ratios and rates -- the same check as ratios_and_rates_check.py, in Rust.  No
// crates.  Paint mixed 3 parts blue to 2 parts white, scaled up to a 15 litre
// tin.  A car covering 120 km in 1.5 hours.  Blue paint, 3 litres for $2.25.
fn row(name: &str, value: String) { println!("{:<34}{:>11}", name, value); }

fn main() {
    let (blue_parts, white_parts, tin) = (3i64, 2i64, 15i64);
    let parts = blue_parts + white_parts;
    let per_part = tin / parts;                   // what one part is worth, in litres
    let (blue, white) = (blue_parts * per_part, white_parts * per_part);
    row("parts in the mix, 3 blue + 2 white", parts.to_string());
    row("litres in one part, 15 / 5", per_part.to_string());
    row("blue litres and white litres", format!("{} and {}", blue, white));
    row("blue + white, back to the tin", (blue + white).to_string());

    let (km, hours) = (120.0f64, 1.5f64);
    let speed = km / hours;                       // a rate: kilometres per one hour
    row("car speed, 120 km / 1.5 hours", format!("{:.0}", speed));
    row("distance check, speed x 1.5 hours", format!("{:.0}", speed * hours));
    row("km by 0.5 hours and by 1 hour", format!("{:.0} and {:.0}", speed * 0.5, speed));

    let (price, litres) = (2.25f64, 3.0f64);
    let unit = price / litres;                    // the same move: dollars per litre
    row("unit price, $2.25 / 3 litres", format!("{:.2}", unit));
    row("twelve litres, 12 x unit price", format!("{:.2}", 12.0 * unit));
    row("twelve litres, 4 x $2.25", format!("{:.2}", (12.0 / litres) * price));
    println!("the three mistakes: {} litres, {:.4} hours per km, ${:.2}",
             (tin / blue_parts) * parts, hours / km, 12.0 * price);

    assert!(parts == 5 && per_part == 3 && blue == 9 && white == 6 && blue + white == 15);
    assert!(speed == 80.0 && speed * hours == 120.0 && speed * 0.5 == 40.0);
    assert!(unit == 0.75 && 12.0 * unit == 9.0 && (12.0 / litres) * price == 9.0);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
parts in the mix, 3 blue + 2 white          5
litres in one part, 15 / 5                  3
blue litres and white litres          9 and 6
blue + white, back to the tin              15
car speed, 120 km / 1.5 hours              80
distance check, speed x 1.5 hours         120
km by 0.5 hours and by 1 hour       40 and 80
unit price, $2.25 / 3 litres             0.75
twelve litres, 12 x unit price           9.00
twelve litres, 4 x $2.25                 9.00
the three mistakes: 25 litres, 0.0125 hours per km, $27.00
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves three ratio rules for any amounts, not just the paint tin.

- Multiply both sides of a ratio by the same number, not zero, and the ratio does not change.
- Split any total by a ratio, with every amount positive, and the two shares add back to the total and keep the ratio.
- With neither side zero, multiply one side alone by any number but 1, and the ratio changes.

Lean also checks the card's sums as exact fractions; the decimals the programs print are left to the Python and Rust checks.

<details>
<summary>The Lean proof, 75 lines</summary>

```lean
-- Ratios and rates: multiplying both sides of a ratio by the same nonzero number leaves it unchanged, scaling one side alone changes it, and splitting a total by a ratio gives two shares that add back to the total and keep the ratio.
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.FieldSimp

/-- A ratio only cares about relative size. Do the same to both sides, multiplying the amount `a`
and the amount `b` by the same number `k` (not zero, or there is nothing left to compare), and the
ratio does not change: `k·a : k·b` is the same as `a : b`. 9 litres to 6 is 3 : 2 times 3. -/
theorem ratio_unchanged_when_both_sides_scaled (a b k : ℝ) (hk : k ≠ 0) :
    (k * a) / (k * b) = a / b := by
  exact mul_div_mul_left a b hk

/-- Splitting a total by a ratio: a total `T` split `p : q` has `p + q` equal parts, one part is
`T / (p + q)`, the first side gets `p` parts and the second gets `q`. The two shares add back to
the total, and they stand in the ratio `p : q`. Amounts and parts are positive. -/
theorem split_total_by_ratio (p q T : ℝ) (hp : 0 < p) (hq : 0 < q) (hT : 0 < T) :
    p * (T / (p + q)) + q * (T / (p + q)) = T ∧
    (p * (T / (p + q))) / (q * (T / (p + q))) = p / q := by
  have hpq : p + q ≠ 0 := by positivity
  have hx : T / (p + q) ≠ 0 := by positivity
  constructor
  · field_simp
  · exact mul_div_mul_right p q hx

/-- Scaling one side only changes the ratio: for nonzero amounts `a` and `b`, multiplying `a` alone
by any number `k` other than 1 gives a different ratio. Nine litres of blue with the original 2 of
white is not the same colour as 3 : 2. -/
theorem scaling_one_side_changes_ratio (a b k : ℝ) (ha : a ≠ 0) (hb : b ≠ 0) (hk : k ≠ 1) :
    (k * a) / b ≠ a / b := by
  intro h
  have h2 : k * a = a := by
    have := (div_left_inj' hb).mp h
    exact this
  have h3 : (k - 1) * a = 0 := by linarith
  rcases mul_eq_zero.mp h3 with h4 | h4
  · exact hk (by linarith)
  · exact ha h4

-- The tin: 3 : 2 is 3 + 2 = 5 parts, one part of 15 litres is 15 ÷ 5 = 3 litres.
example : 3 + 2 = 5 ∧ 15 / 5 = 3 := by decide
-- Blue 3 × 3 = 9 litres, white 2 × 3 = 6 litres, and 9 + 6 = 15 back to the tin.
example : 3 * 3 = 9 ∧ 2 * 3 = 6 ∧ 9 + 6 = 15 := by decide
-- 9 : 6 divided by 3 on both sides is 3 : 2 again.
example : (9 : ℚ) / 6 = 3 / 2 := by norm_num
example : 9 / 3 = 3 ∧ 6 / 3 = 2 := by decide
-- The car: 120 km in 1.5 hours (3/2 of an hour) is 80 km per hour, and 80 × 1.5 = 120 back.
example : (120 : ℚ) / (3 / 2) = 80 := by norm_num
example : (80 : ℚ) * (3 / 2) = 120 := by norm_num
-- At a steady 80 km per hour: 40 km by the half hour, 80 by the hour.
example : (80 : ℚ) * (1 / 2) = 40 ∧ (80 : ℚ) * 1 = 80 := by norm_num
-- Unit price: $2.25 (9/4 dollars) for 3 litres is $0.75 (3/4 of a dollar) a litre.
example : (9 / 4 : ℚ) / 3 = 3 / 4 := by norm_num
-- Twelve litres, two roads: 12 × $0.75 = $9.00, and 12 litres is 4 lots of 3, 4 × $2.25 = $9.00.
example : (12 : ℚ) * (3 / 4) = 9 := by norm_num
example : 12 / 3 = 4 := by decide
example : (4 : ℚ) * (9 / 4) = 9 := by norm_num
-- Mistake: dividing 15 by the 3 blue parts gives parts of 5 litres, and 5 parts of 5 is 25 litres.
example : 15 / 3 = 5 ∧ 5 * 5 = 25 ∧ 15 < 25 := by decide
-- Mistake: 1.5 ÷ 120 is 0.0125 (1/80), hours per kilometre.
example : (3 / 2 : ℚ) / 120 = 1 / 80 := by norm_num
-- Mistake: $2.25 × 12 = $27.00, which buys 27 ÷ 0.75 = 36 litres.
example : (9 / 4 : ℚ) * 12 = 27 := by norm_num
example : (27 : ℚ) / (3 / 4) = 36 := by norm_num
-- Scaling one side only: 9 litres of blue against 2 of white is not 3 : 2.
example : (9 : ℚ) / 2 ≠ 3 / 2 := by norm_num
-- Try changing: a 3 : 1 mix has 4 parts, whole-number 15 ÷ 4 floors to 3, and the tin check is 12.
example : 3 + 1 = 4 ∧ 15 / 4 = 3 ∧ 3 * 3 + 1 * 3 = 12 := by decide
-- Try changing: 120 km in 2 hours is 60 km per hour, and 60 × 2 = 120.
example : (120 : ℚ) / 2 = 60 ∧ (60 : ℚ) * 2 = 120 := by norm_num

#print axioms ratio_unchanged_when_both_sides_scaled
#print axioms split_total_by_ratio
#print axioms scaling_one_side_changes_ratio
```

</details>

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'ratio_unchanged_when_both_sides_scaled' depends on axioms: [propext, Classical.choice, Quot.sound]
'split_total_by_ratio' depends on axioms: [propext, Classical.choice, Quot.sound]
'scaling_one_side_changes_ratio' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it. The asserts are pinned to the house numbers, so expect one to fire.
> - **Make it a 3 : 1 mix.** Change the 2 in the mix line to a 1. Four parts now: the code floors 15 ÷ 4 to 3 litres, and the tin check comes out 12.
> - **Slow the car.** Set `hours` to 2.0. The rate drops to 60 kilometres per hour; the distance check still says 120.

---

## The usual mistake

> [!warning]
> **A ratio compares part to part, not part to whole.** The tin has five parts, and 5 is the number you divide by. Divide 15 by the 3 instead and each part is 5 litres: 25 litres of paint for a 15 litre tin.
>
> - **Turning a rate upside down.** 1.5 ÷ 120 = 0.0125 is a real number, but in hours per kilometre.
> - **Scaling one side only.** Nine litres of blue with the original 2 of white is not the same colour.
> - **Multiplying a price that already covers several.** $2.25 × 12 = $27.00 buys 36 litres. Price one first.

---

## Where you meet it in real life

- **The unit price on a shelf tag.** Dollars per litre, cents per 100 grams: the same 2.25 ÷ 3, done for you.
- **Anything with "per" in it.** Kilometres per hour, pay per hour, rent per week. Divide until the bottom is 1.
- **Mixing and scaling.** Paint, concrete, cocktails, dough. Hold the ratio, change the batch.

> **Say it back**
> A ratio compares two amounts of the same kind: 3 parts blue to 2 parts white. Add the parts to get 5, divide the 15 litre tin by 5 for one part of 3 litres, so blue is 9 litres to white's 6. A rate compares different kinds: 120 kilometres in 1.5 hours is 80 per hour — divide until the bottom is 1. A ratio splits by the total parts. Both survive scaling done to both sides.

---

## What this builds on

- [Fractions](07-fractions.md): reducing 9 : 6 to 3 : 2 is the cancelling move, done to a ratio.
- [Decimals](08-decimals.md): the numbers rarely land whole — 1.5 hours in, $0.75 a litre out.

## Where this goes next

- [Percentages](10-percentages.md): a ratio with its bottom amount pinned at 100, which is what makes percentages comparable across everything.

This card leaves one question open: two mixes from tins of different sizes have different totals, so how do you say which one is bluer?

---

## Sources

Verified 2026-11-11: every link below resolves to the publisher's page.

- Euclid. *The First Six Books of the Elements of Euclid*, ed. John Casey. Project Gutenberg. [Text](https://www.gutenberg.org/ebooks/21076). Book V, the careful ancient treatment.
- Bureau International des Poids et Mesures. *The International System of Units (SI Brochure)*, 9th ed. [Publisher page](https://www.bipm.org/en/publications/si-brochure). Defines the "per" units.
- Lamon, Susan J. *Teaching Fractions and Ratios for Understanding*, 4th ed. Routledge, 2020. [Publisher page](https://doi.org/10.4324/9781003008057). Catalogues the part-to-part confusion.
