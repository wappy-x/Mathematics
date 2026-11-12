# Percentages: parts per hundred, rises, cuts, and undoing them

[Syllabus](../../../SYLLABUS.md) → [Foundations](../README.md) → [Everyday Arithmetic](../README.md#s01) → Percentages

---

## General Overview

A jacket on the rack is $80.00. The sign says 25% off. At the till the state adds 8% sales tax. You pay $64.80. Later, a $46.00 dinner gets a 15% tip.

Percent means *per hundred* — *per cento*, the way Italian merchants wrote it. A percent is a count of hundredths: 25% is twenty-five of them, the fraction 25/100, the decimal 0.25, a quarter ([Fractions](07-fractions.md), [Decimals](08-decimals.md)). The % sign is shorthand for "divided by 100".

**A percent is a count of hundredths: to take a percent of an amount, multiply by the percent, then divide by 100.**

**What kind of fact this is:** a definition: "percent" means hundredths, and every rule on this card follows from that in Why it works.

### The picture: the jacket's three prices

```
one █ = $2

tag price          ████████████████████████████████████████  $80.00
after 25% off      ██████████████████████████████            $60.00
with 8% tax added  ████████████████████████████████          $64.80
```

The last bar does not climb back to the first. A cut and a rise do not cancel: each is taken of a different amount.

---

## The formula

"Percent" means per hundred, so multiply then divide by 100:

**25% of $80.00 = 80.00 × 25 ÷ 100 = $20.00**

A cut or a rise is one multiply — take the percent off 100, or add it on:

**$80.00 with 25% off = 80.00 × 75 ÷ 100 = $60.00**

**$60.00 with 8% added = 60.00 × 108 ÷ 100 = $64.80**

Undoing one turns that multiply into a divide:

**$64.80 before the 8% tax = 64.80 × 100 ÷ 108 = $60.00**

**Read it aloud:** twenty-five percent of eighty dollars is eighty times twenty-five, divided by one hundred: twenty dollars.

| Piece | Plain meaning | In our example |
| --- | --- | --- |
| a percent, % | a count of hundredths; % means "÷ 100" | 25, 8, 15 |
| the amount | the whole it is taken of | $80.00 tag, $60.00 sale, $46.00 bill |
| the part | that percent's share of the amount | $20.00 off, $4.80 tax |
| a cut | keep the rest: 100 minus the percent | 100 − 25 = 75 |
| a rise | pay the extra: 100 plus the percent | 100 + 8 = 108 |

### When it holds

- **The percent names its amount.** The 8% tax is of the $60.00 sale price. Without "of what", a percent has no size.
- **Each step in a chain is taken of the amount it meets.** Add the percents instead and the till says $66.40, not $64.80.
- **To undo a step, divide by the same multiply.** Add the 25% back instead and $60.00 becomes $75.00, not the $80.00 tag.
- **A change in a rate is counted in points.** Read 15% to 18% as "3% more" and the tip is $7.11, not $8.28.

---

## Why it works

### Step 0: fix the bottom of the fraction at 100

Two fractions compare easily once they share a bottom number. Percents fix it at 100 for everything, so the top number carries the meaning: 25, 8 and 15 read side by side.

### Step 1: taking a percent of an amount

One hundredth of the $80.00 tag is 80.00 ÷ 100 = $0.80. A percent counts those: 25% is twenty-five of them, 25 × 0.80 = $20.00. Multiplying first is easier by hand, same answer: 80.00 × 25 = 2000, then ÷ 100 = $20.00 ([The three rearranging laws](05-arithmetic-laws.md)).

### Step 2: a cut or a rise, in one multiply

After 25% off you pay what is left, and the whole is 100%: that is 100 − 25 = 75% of the tag, so 80.00 × 75 ÷ 100 = $60.00. Tax runs the same way upward — the sale price *and* 8% more is 108% of it: 60.00 × 108 ÷ 100 = $64.80.

Notice what that 8% is taken of: the $60.00 sale price, never the $80.00 tag. Every percent needs "of what" attached.

### Step 3: undoing one

The tax multiplied $60.00 by 108 and divided by 100, so going back undoes both the opposite way: 64.80 × 100 ÷ 108 = $60.00. Undo the sale the same way: 60.00 × 100 ÷ 75 = $80.00, the tag again. Adding 25% back to $60.00 instead takes 25% *of a smaller amount* and lands short, at $75.00.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| 25% of the $80.00 tag | 80.00 × 25 ÷ 100 | $20.00 |
| sale price | 80.00 − 20.00 | $60.00 |
| the same, in one multiply | 80.00 × 75 ÷ 100 | $60.00 |
| 8% tax on the sale price | 60.00 × 8 ÷ 100 | $4.80 |
| total at the till | 60.00 + 4.80 | **$64.80** |
| undo the tax | 64.80 × 100 ÷ 108 | $60.00 |
| undo the cut | 60.00 × 100 ÷ 75 | **$80.00** |
| 15% tip on the $46.00 dinner | 46.00 × 15 ÷ 100 | **$6.90** |
| the same tip at 18% | 46.00 × 18 ÷ 100 | **$8.28** |

You pay $64.80 for an $80.00 tag, and the total reverses cleanly back to it.

Moving a tip from 15% to 18% is **three percentage points** — a percentage point is one step on the percent scale itself, 15 to 18. It is not "3% more tip", which is $7.11. Points move the rate; percent moves the money.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Adding the percents: 25% off, 8% on, so 17% off | $66.40 | The 8% is of the $60.00 sale price, not the tag |
| Undoing the cut by adding 25% back | $75.00 | 25% of $60.00 is less than 25% of $80.00 |
| Reading 15% to 18% as "3% more tip" | $7.11 | Points move the rate, not the money |

---

## Code, from first principles, and it actually runs

Nothing is imported. Everything is in whole cents; only the $7.11 mistake needs rounding, to the nearest cent. The jacket is priced twice, the plain way and by one multiply a step. Then the total is run back to the tag, and the dinner is tipped twice.

### Python

```python
# Percentages -- the check behind the card.  Nothing is imported.  Whole cents
# throughout: an $80 jacket, 25% off, then 8% sales tax at the till, and a 15%
# tip on a $46 dinner.  Two roads to the till total, then both undone.
def part(amount, percent):        # 25 percent of 8000 cents -> 2000 cents
    return amount * percent // 100
def row(name, cents):
    print(f"{name:<34}{cents / 100:>8.2f}")
tag, dinner = 8000, 4600
discount = part(tag, 25)
sale = tag - discount
tax = part(sale, 8)
till = sale + tax
till_2 = part(part(tag, 100 - 25), 100 + 8)     # second road: one multiply each way
back_to_sale = till * 100 // (100 + 8)          # undo the tax
back_to_tag = back_to_sale * 100 // (100 - 25)  # undo the cut
tip15, tip18 = part(dinner, 15), part(dinner, 18)
wrong_add = part(tag, 100 - 17)                 # 25 off then 8 on is not 17 off
wrong_back = part(sale, 100 + 25)               # adding 25 back does not undo a cut
wrong_pts = (tip15 * 103 + 50) // 100           # "three percent more", not three points
for name, cents in [("jacket tag price", tag), ("25 percent off, the discount", discount),
                    ("sale price", sale), ("8 percent sales tax", tax),
                    ("total at the till", till), ("the one-multiply road agrees", till_2),
                    ("reversed from the till, the tag", back_to_tag), ("dinner bill", dinner),
                    ("tip at 15 percent", tip15), ("tip at 18 percent, three points", tip18)]:
    row(name, cents)
print(f"mistakes: {wrong_add / 100:.2f}, {wrong_back / 100:.2f} and {wrong_pts / 100:.2f}")
assert discount == 2000 and sale == 6000 and till == 6480
assert till_2 == till and back_to_sale == sale and back_to_tag == tag
assert tip15 == 690 and tip18 == 828 and wrong_add == 6640 and wrong_back == 7500 and wrong_pts == 711
print("ALL CHECKS PASS")
```

**Ran 2026-09-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
jacket tag price                     80.00
25 percent off, the discount         20.00
sale price                           60.00
8 percent sales tax                   4.80
total at the till                    64.80
the one-multiply road agrees         64.80
reversed from the till, the tag      80.00
dinner bill                          46.00
tip at 15 percent                     6.90
tip at 18 percent, three points       8.28
mistakes: 66.40, 75.00 and 7.11
ALL CHECKS PASS
```

### Rust

```rust
// Percentages -- the same check as percentages_check.py, in Rust.  No crates.
// Whole cents throughout: an $80 jacket, 25% off, then 8% sales tax at the
// till, and a 15% tip on a $46 dinner.  Two roads, then both undone.
fn part(amount: i64, percent: i64) -> i64 {   // 25 percent of 8000 cents -> 2000
    amount * percent / 100
}
fn row(name: &str, cents: i64) {
    println!("{:<34}{:>8.2}", name, cents as f64 / 100.0);
}
fn main() {
    let (tag, dinner) = (8000i64, 4600i64);
    let discount = part(tag, 25);
    let sale = tag - discount;
    let tax = part(sale, 8);
    let till = sale + tax;
    let till_2 = part(part(tag, 100 - 25), 100 + 8);    // second road: one multiply each way
    let back_to_sale = till * 100 / (100 + 8);          // undo the tax
    let back_to_tag = back_to_sale * 100 / (100 - 25);  // undo the cut
    let (tip15, tip18) = (part(dinner, 15), part(dinner, 18));
    let wrong_add = part(tag, 100 - 17);                // 25 off then 8 on is not 17 off
    let wrong_back = part(sale, 100 + 25);              // adding 25 back does not undo a cut
    let wrong_pts = (tip15 * 103 + 50) / 100;           // "three percent more", not three points
    for (name, cents) in [("jacket tag price", tag), ("25 percent off, the discount", discount),
                          ("sale price", sale), ("8 percent sales tax", tax),
                          ("total at the till", till), ("the one-multiply road agrees", till_2),
                          ("reversed from the till, the tag", back_to_tag), ("dinner bill", dinner),
                          ("tip at 15 percent", tip15), ("tip at 18 percent, three points", tip18)] {
        row(name, cents);
    }
    println!("mistakes: {:.2}, {:.2} and {:.2}", wrong_add as f64 / 100.0,
             wrong_back as f64 / 100.0, wrong_pts as f64 / 100.0);
    assert!(discount == 2000 && sale == 6000 && till == 6480);
    assert!(till_2 == till && back_to_sale == sale && back_to_tag == tag);
    assert!(tip15 == 690 && tip18 == 828 && wrong_add == 6640 && wrong_back == 7500 && wrong_pts == 711);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
jacket tag price                     80.00
25 percent off, the discount         20.00
sale price                           60.00
8 percent sales tax                   4.80
total at the till                    64.80
the one-multiply road agrees         64.80
reversed from the till, the tag      80.00
dinner bill                          46.00
tip at 15 percent                     6.90
tip at 18 percent, three points       8.28
mistakes: 66.40, 75.00 and 7.11
ALL CHECKS PASS
```

The two outputs match line for line, cent for cent.

### Lean

Lean proves three rules for every amount and every percent, not just the card's numbers.

- A rise is one multiply: times 100 plus the percent, then ÷ 100. A cut is the same with 100 minus the percent.
- To undo a step, multiply by 100 and divide by the same multiply. This works for every step except a 100% cut, whose multiply is zero.
- Percents do not add. A cut then a rise equals the single cut you get by adding the percents only if the amount or one percent is zero.

The worked numbers are checked here in whole cents too; printing the price list is left to the Python and Rust checks.

<details>
<summary>The Lean proof, 67 lines</summary>

```lean
-- Percentages: a cut or a rise by a percent is one multiply by 100 minus or plus that percent over 100, dividing by the same multiply undoes it, a cut then a rise never equals the single cut you get by adding the percents unless one of them is zero, and the card's jacket and dinner numbers come out as it says.
import Mathlib.Algebra.Field.Rat
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith

/-- A cut or a rise in one multiply: an amount with `p` percent added on is the amount
times `100 + p`, divided by 100; an amount with `p` percent taken off is the amount
times `100 - p`, divided by 100. (The part, `p` percent of `a`, is `a × p ÷ 100`.) -/
theorem percent_rise_and_cut_in_one_multiply (a p : ℚ) :
    a + a * p / 100 = a * (100 + p) / 100 ∧
    a - a * p / 100 = a * (100 - p) / 100 := by
  constructor <;> ring

/-- To undo a step, divide by the same multiply: if a step multiplied the amount by `m`
and divided by 100 (`m = 100 + p` for a rise, `100 - p` for a cut), then multiplying
the result by 100 and dividing by `m` gives back the amount. -/
theorem undo_percent_step_by_same_multiply (a m : ℚ) (hm : m ≠ 0) :
    a * m / 100 * 100 / m = a := by
  field_simp

/-- Percents do not add: a cut of `p` percent followed by a rise of `q` percent, each taken
of the amount it meets, equals a single cut of `p - q` percent only when the amount is zero
or one of the two percents is zero. -/
theorem percents_do_not_add (a p q : ℚ) :
    a * (100 - p) / 100 * (100 + q) / 100 = a * (100 - (p - q)) / 100 ↔
      a = 0 ∨ p = 0 ∨ q = 0 := by
  have key : a * (100 - p) / 100 * (100 + q) / 100 - a * (100 - (p - q)) / 100
      = -(a * p * q) / 10000 := by ring
  constructor
  · intro h
    have h0 : -(a * p * q) / 10000 = 0 := by rw [← key, h]; ring
    have h1 : a * p * q = 0 := by linarith
    rcases mul_eq_zero.mp h1 with h2 | h2
    · rcases mul_eq_zero.mp h2 with h3 | h3
      · exact Or.inl h3
      · exact Or.inr (Or.inl h3)
    · exact Or.inr (Or.inr h2)
  · intro h
    have h1 : a * p * q = 0 := by
      rcases h with h | h | h <;> simp [h]
    have : a * (100 - p) / 100 * (100 + q) / 100 - a * (100 - (p - q)) / 100 = 0 := by
      rw [key, h1]; ring
    linarith

-- The card's worked numbers, in whole cents.
example : 8000 * 25 / 100 = 2000 := by decide            -- 25% of the $80.00 tag
example : 8000 - 2000 = 6000 := by decide                -- sale price
example : 8000 * (100 - 25) / 100 = 6000 := by decide    -- the same, in one multiply
example : 6000 * 8 / 100 = 480 := by decide              -- 8% tax on the sale price
example : 6000 + 480 = 6480 := by decide                 -- total at the till
example : 6000 * (100 + 8) / 100 = 6480 := by decide     -- the same, in one multiply
example : 6480 * 100 / 108 = 6000 := by decide           -- undo the tax
example : 6000 * 100 / 75 = 8000 := by decide            -- undo the cut
example : 8000 * 108 / 100 * 75 / 100 = 6480 := by decide -- tax first, then the sale
example : 4600 * 15 / 100 = 690 := by decide             -- 15% tip on the $46.00 dinner
example : 4600 * 18 / 100 = 828 := by decide             -- the same tip at 18%
example : 75 * 108 / 100 = 81 := by decide               -- 25% off then 8% on is 81% of the tag
-- The mistakes.
example : 8000 * (100 - 17) / 100 = 6640 := by decide    -- adding the percents
example : 6000 * (100 + 25) / 100 = 7500 := by decide    -- adding 25% back
example : (690 * 103 + 50) / 100 = 711 := by decide      -- "3% more tip", to the nearest cent

#print axioms percent_rise_and_cut_in_one_multiply
#print axioms undo_percent_step_by_same_multiply
#print axioms percents_do_not_add
```

</details>

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'percent_rise_and_cut_in_one_multiply' depends on axioms: [propext, Classical.choice, Quot.sound]
'undo_percent_step_by_same_multiply' depends on axioms: [propext, Classical.choice, Quot.sound]
'percents_do_not_add' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it. The asserts are pinned to the house numbers, so expect one to fire.
> - **Tax first, then the sale.** Does the order matter? Flip the second road to `part(part(tag, 100 + 8), 100 - 25)`: still $64.80, and no assert fires.
> - **Tip 18% from the start.** Set `part(dinner, 15)` to `part(dinner, 18)`: $8.28, and the last assert fires.

---

## The usual mistake

> [!warning]
> **Percents do not add: each is taken of a different amount.** The 25% came off the $80.00 tag; the 8% went onto the $60.00 sale price, so the pair is not a 17% cut but a 19% one: 75 × 108 ÷ 100 = 81, or 81% of the tag. Treat it as 17% and you get $66.40, not $64.80.
>
> - **Not saying "of what".** A percent alone is not a quantity, only a share of a named amount.
> - **Undoing a cut with the same percent.** Add 25% back to $60.00 and you get $75.00, not $80.00.
> - **Points read as percent.** 15% to 18% is three points: $8.28, not the $7.11 "3% more tip" gives.

---

## Where you meet it in real life

- **Sale tags and sales tax.** Stacked discounts — "extra 20% off sale prices" — multiply. They never add.
- **Tips and service charges.** A menu price with service "included" is already a rise on something: ask on what.
- **Interest, inflation, polls.** All quoted as percents so sizes compare, the job of [Ratios and rates](09-ratios-and-rates.md). Anything "up 3 points" moved on the rate, not the money.

> **Say it back**
> A percent is a count of hundredths: multiply by the percent, divide by 100. A cut multiplies by 100 minus the percent, a rise by 100 plus it. To undo either, divide by what you multiplied by — never add the percent back. Every percent is a percent *of* something.

---

## What this builds on

- [Ratios and rates](09-ratios-and-rates.md): comparing two quantities and scaling them together. A percent is that comparison with the second quantity fixed at 100.

## Where this goes next

- [Growth factors](../04-Compound%20Growth%20and%20Discounting/01-growth-factors.md): the one-multiply step given its own name, so changes chain — why a 50% fall then a 50% rise does not break even.

This card leaves one question open: what happens when the same percent is applied again and again, each time to a new amount?

---

## Sources

Verified 2026-11-11: every link below resolves to the publisher's page.

- Sigler, Laurence E., trans. *Fibonacci's Liber Abaci*. Springer, 2002. [doi:10.1007/978-1-4613-0079-3](https://doi.org/10.1007/978-1-4613-0079-3). Where merchant arithmetic — profit, interest, per cento — put a hundred under the fraction.
- Eurostat. *Statistics Explained: Percentage point*. [Glossary entry](https://ec.europa.eu/eurostat/statistics-explained/index.php?title=Glossary:Percentage%20point). The official points-versus-percent rule.
- Thompson, Ambler, and Barry N. Taylor. *Guide for the Use of the SI*, NIST Special Publication 811. [NIST page](https://www.nist.gov/pml/special-publication-811). Section 7.10.2, writing percent without ambiguity.
