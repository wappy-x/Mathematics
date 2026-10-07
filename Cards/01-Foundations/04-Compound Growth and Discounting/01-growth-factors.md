# Growth factors: a 25% rise is a multiply by 1.25, and percent changes do not add

[Syllabus](../../../SYLLABUS.md) → [Foundations](../../../SYLLABUS.md#w01) → [Compound Growth and Discounting](../../../SYLLABUS.md#w01-s04) → Growth factors

---

## General Overview

A jacket is $80.00 in March. In autumn the shop puts it up 25%. In January it goes into the sale at 25% off. Same percent up, same percent down, and the ticket reads $75.00.

Nothing was stolen. The rise took 25% of $80.00: $20.00. The sale took 25% of $100.00: $25.00. Equal percents, unequal amounts.

Write a percent change as one number you multiply by, and it stops being a trick. A 25% rise is a multiply by 1.25. A 25% cut is a multiply by 0.75. That multiplier is the **growth factor**.

**A percent change is one multiplier: 1 plus the change for a rise, 1 minus it for a cut. Chain changes by multiplying the factors, never by adding the percents.**

### The picture: four prices

```
one █ = $5

March, before the season                ████████████████      $80.00
after the 25% rise                      ████████████████████  $100.00
after the 25% sale                      ███████████████       $75.00
a second jacket, half off then half on  ████████████          $60.00
```

Up 25 then down 25 lands below the start. The second jacket starts at $80.00 too.

---

## The formula

Write the percent as a decimal — 25% is 0.25 ([Percentages](../01-Everyday%20Arithmetic/10-percentages.md)) — then build the multiplier around 1:

**a 25% rise: 1 + 0.25 = 1.25, and $80.00 × 1.25 = $100.00**

**a 25% cut: 1 − 0.25 = 0.75, and $100.00 × 0.75 = $75.00**

**the two changes as one number: 1.25 × 0.75 = 0.9375, and $80.00 × 0.9375 = $75.00**

| Piece | Plain meaning | In our example |
| --- | --- | --- |
| the change, as a decimal | the percent divided by 100 | 0.25, 0.50 |
| a growth factor | what you multiply by | 1.25, 0.75 |
| a rise | 1 plus the change | 1.25 |
| a cut | 1 minus the change | 0.75 |
| chaining | the factors multiplied | 0.9375 |
| the new amount | old amount times the factor | 80.00 × 0.9375 |

**new amount = old amount × (1 + the change)**, and the change is negative for a cut.

Above 1 is a rise, below 1 a cut, exactly 1 no change.

---

## Why it works

### Step 0: the whole amount is 1

Whatever the price is, all of it is 1 — one whole price, 100%. A 25% rise wants all of it and a quarter more: 1 + 0.25. A 25% cut keeps all of it less a quarter: 1 − 0.25. One multiply, whole job.

### Step 1: one multiply, not two moves

The long way up: 25% of $80.00 is $20.00, add it on, $100.00. The factor way: 80.00 × 1.25. Both amounts are shares of the same $80.00, so they gather into one multiply: 80.00 + 20.00 = (80.00 × 1) + (80.00 × 0.25) = 80.00 × 1.25 ([The three rearranging laws](../01-Everyday%20Arithmetic/05-arithmetic-laws.md)).

### Step 2: the second factor works on what the first left

The sale multiplies the raised price, not the March tag: 100.00 × 0.75 = $75.00. That is 80.00 × 1.25 × 0.75. Multiplying can be grouped any way, so gather the factors first: 1.25 × 0.75 = 0.9375, and 80.00 × 0.9375 = $75.00.

To read a factor back as a percent, take it from 1: 1 − 0.9375 = 0.0625, so 6.25% down. Up 25% then down 25% is a 6.25% cut.

Run the sale first — 80.00 × 0.75 = $60.00, then × 1.25 — and it is $75.00 again. The order is not what costs the money. It is that 0.9375 is not 1.

### Step 3: undoing a change

To undo a multiply, divide. 1 ÷ 1.25 = 0.80, a 20% cut: 100.00 × 0.80 = $80.00, the March price back. A rise is undone by a smaller cut, never a matching one.

### Step 4: half off, half on

The second jacket, also $80.00: halved to $40.00, then up 50%, 40.00 × 1.50 = $60.00. As factors, 0.50 × 1.50 = 0.75, a 25% cut. Half off then half on loses a quarter, whatever the price.

The same factor over and over — 1.05 a year on a savings account — is compound interest: [Compound interest](03-compound-interest.md). [Simple interest](02-simple-interest.md) is the flat version that does add.

---

## Worked numbers, by hand

Dollars to two decimal places; every figure lands on an exact cent — the +0.5 in the code is a guard, never used here.

| Step | Arithmetic | Value |
| --- | --- | --- |
| 25% rise, factor 1.25 | 80.00 × 1.25 | $100.00 |
| 25% sale, factor 0.75 | 100.00 × 0.75 | **$75.00** |
| the season as one factor | 1.25 × 0.75 = 0.9375, then 80.00 × 0.9375 | $75.00 |
| the other order, sale first | 80.00 × 0.75, then × 1.25 | $75.00 |
| undoing the rise | 1 ÷ 1.25 = 0.80, then 100.00 × 0.80 | $80.00 |
| half off | 80.00 × 0.50 | $40.00 |
| half on again | 40.00 × 1.50 | **$60.00** |
| that pair as one factor | 0.50 × 1.50 | 0.75 |

Both pairs sounded like they cancelled. Neither did.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Reading up 25% then down 25% as no change | $80.00 | The cut is taken of the raised price |
| Multiplying by 0.25 for a 25% rise | $20.00 | 0.25 is the part; the growth factor is 1.25 |
| Adding the factors, 1.25 + 0.75 | $160.00 | Factors chain by multiplying |

The code prints all three.

---

## Code, from first principles, and it actually runs

Nothing is imported. The season is priced three ways: step by step, as one gathered multiply, and swapped. Then the rise is undone, the second jacket halved and restored.

### Python

```python
# Growth factors -- the check behind the card.  Nothing is imported.  Money in
# whole cents, rounded to the nearest cent: an $80 jacket up 25% for the season,
# then 25% off in the sale.  Then half off a second jacket, and half on again.
def after(cents, factor):          # 8000 cents at factor 1.25 -> 10000 cents
    return int(cents * factor + 0.5)
def row(name, cents): print(f"{name:<36}{cents / 100:>9.2f}")
start = 8000
rise = after(start, 1 + 0.25)
cut = after(rise, 1 - 0.25)
pair = after(start, 1.25 * 0.75)             # second road: one factor for both changes
other = after(after(start, 0.75), 1.25)      # third road: the same two changes, swapped
undo = after(rise, 1 / 1.25)
half_off = after(start, 1 - 0.50)
half_on = after(half_off, 1 + 0.50)
pair2 = after(start, 0.50 * 1.50)
wrong_add = after(start, 1.00)               # +25 and -25 read as no change at all
wrong_part = after(start, 0.25)              # 0.25 is the part, not the growth factor
wrong_sum = after(start, 1.25 + 0.75)        # factors chain by multiplying, not adding
for name, cents in [("jacket at the start", start), ("25 percent rise, factor 1.25", rise),
                    ("25 percent cut, factor 0.75", cut), ("the pair as one factor, 0.9375", pair),
                    ("the other order, cut then rise", other), ("undo the rise: 20 percent off, 0.80", undo),
                    ("half off, factor 0.50", half_off), ("half on again, factor 1.50", half_on),
                    ("that pair as one factor, 0.75", pair2)]:
    row(name, cents)
print(f"a 5 percent rise is factor {1 + 0.05:.2f}; 0.9375 is {(1 - 1.25 * 0.75) * 100:.2f} percent down; 0.75 is {(1 - 0.5 * 1.5) * 100:.2f} percent down")
print(f"the three mistakes come out at {wrong_add / 100:.2f}, {wrong_part / 100:.2f} and {wrong_sum / 100:.2f}")
assert rise == 10000 and cut == 7500 and pair == cut
assert other == 7500 and undo == start and pair2 == 6000
assert half_on == 6000 and wrong_add == 8000 and wrong_part == 2000 and wrong_sum == 16000
print("ALL CHECKS PASS")
```

**Ran 2026-09-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
jacket at the start                     80.00
25 percent rise, factor 1.25           100.00
25 percent cut, factor 0.75             75.00
the pair as one factor, 0.9375          75.00
the other order, cut then rise          75.00
undo the rise: 20 percent off, 0.80     80.00
half off, factor 0.50                   40.00
half on again, factor 1.50              60.00
that pair as one factor, 0.75           60.00
a 5 percent rise is factor 1.05; 0.9375 is 6.25 percent down; 0.75 is 25.00 percent down
the three mistakes come out at 80.00, 20.00 and 160.00
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Growth factors -- the same check as growth_factors_check.py, in Rust.  No
// crates.  Money in whole cents, rounded to the nearest cent: an $80 jacket up
// 25% for the season, then 25% off in the sale.  Then half off, and half on.
fn after(cents: i64, factor: f64) -> i64 {   // 8000 cents at factor 1.25 -> 10000
    (cents as f64 * factor + 0.5) as i64
}
fn row(name: &str, cents: i64) { println!("{:<36}{:>9.2}", name, cents as f64 / 100.0); }
fn main() {
    let start = 8000i64;
    let rise = after(start, 1.0 + 0.25);
    let cut = after(rise, 1.0 - 0.25);
    let pair = after(start, 1.25 * 0.75);            // second road: one factor for both changes
    let other = after(after(start, 0.75), 1.25);     // third road: the same two changes, swapped
    let undo = after(rise, 1.0 / 1.25);
    let half_off = after(start, 1.0 - 0.50);
    let half_on = after(half_off, 1.0 + 0.50);
    let pair2 = after(start, 0.50 * 1.50);
    let wrong_add = after(start, 1.00);              // +25 and -25 read as no change at all
    let wrong_part = after(start, 0.25);             // 0.25 is the part, not the growth factor
    let wrong_sum = after(start, 1.25 + 0.75);       // factors chain by multiplying, not adding
    for (name, cents) in [("jacket at the start", start), ("25 percent rise, factor 1.25", rise),
                          ("25 percent cut, factor 0.75", cut), ("the pair as one factor, 0.9375", pair),
                          ("the other order, cut then rise", other), ("undo the rise: 20 percent off, 0.80", undo),
                          ("half off, factor 0.50", half_off), ("half on again, factor 1.50", half_on),
                          ("that pair as one factor, 0.75", pair2)] {
        row(name, cents);
    }
    println!("a 5 percent rise is factor {:.2}; 0.9375 is {:.2} percent down; 0.75 is {:.2} percent down",
             1.0 + 0.05, (1.0 - 1.25 * 0.75) * 100.0, (1.0 - 0.5 * 1.5) * 100.0);
    println!("the three mistakes come out at {:.2}, {:.2} and {:.2}", wrong_add as f64 / 100.0,
             wrong_part as f64 / 100.0, wrong_sum as f64 / 100.0);
    assert!(rise == 10000 && cut == 7500 && pair == cut);
    assert!(other == 7500 && undo == start && pair2 == 6000);
    assert!(half_on == 6000 && wrong_add == 8000 && wrong_part == 2000 && wrong_sum == 16000);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
jacket at the start                     80.00
25 percent rise, factor 1.25           100.00
25 percent cut, factor 0.75             75.00
the pair as one factor, 0.9375          75.00
the other order, cut then rise          75.00
undo the rise: 20 percent off, 0.80     80.00
half off, factor 0.50                   40.00
half on again, factor 1.50              60.00
that pair as one factor, 0.75           60.00
a 5 percent rise is factor 1.05; 0.9375 is 6.25 percent down; 0.75 is 25.00 percent down
the three mistakes come out at 80.00, 20.00 and 160.00
ALL CHECKS PASS
```

The two outputs match line for line.

> [!TIP]
> **Try changing**
> Guess first. The asserts hold the house numbers, so one will fire.
> - **Make the sale 20% off.** Back to the March price? Change `after(rise, 1 - 0.25)` to `after(rise, 1 - 0.20)`: $80.00 exactly, and the first assert fires.
> - **Break even after half off.** Change the half-on factor from `1 + 0.50` to `1 + 1.00`: $80.00 again, so climbing back takes a 100% rise, and the last assert fires.

---

## The usual mistake

> [!warning]
> **Adding the percent changes instead of multiplying the factors.** Up 25% then down 25% is not zero. It is 1.25 × 0.75 = 0.9375, a 6.25% cut: $75.00, not $80.00.
>
> - **Using the percent itself as the factor.** 80.00 × 0.25 is $20.00, not a rise. 0.25 is the part; 1.25 is the factor.
> - **Adding factors.** 1.25 + 0.75 = 2.00 doubles the jacket to $160.00.
> - **Expecting a matching cut to undo a rise.** Undoing the 25% rise takes 20% off, factor 0.80.

---

## Where you meet it in real life

- **Stacked sale tags.** "Extra 30% off marked-down prices" multiplies the factors; percents never add ([Percentages](../01-Everyday%20Arithmetic/10-percentages.md)).
- **A savings account.** 5% a year is a multiply by 1.05, for as long as the money sits: [Simple interest](02-simple-interest.md), then [Compound interest](03-compound-interest.md).
- **A fund that drops and recovers.** Down 50% needs a 100% rise to get level, which is why a bad year hurts longer than it looks.

> **Say it back**
> A percent change is one number to multiply by: 1 plus the change for a rise, 1 minus it for a cut. So 25% up is 1.25, 25% down is 0.75. Changes chain by multiplying: 1.25 × 0.75 = 0.9375, a 6.25% cut, so the $80.00 jacket ends at $75.00, not $80.00. To undo a factor, divide by it: 1 ÷ 1.25 = 0.80.

---

## What this builds on

- [Percentages](../01-Everyday%20Arithmetic/10-percentages.md): reading a percent as hundredths, and taking a percent of an amount. This card packs that into one multiplier.
- [The three rearranging laws](../01-Everyday%20Arithmetic/05-arithmetic-laws.md): gathering a sum into one multiply, the move behind Step 1.

## Where this goes next

- [Simple interest](02-simple-interest.md): the same rate on the starting amount every year, adding in a straight line instead of multiplying.
- [Compound interest](03-compound-interest.md): one growth factor applied over and over, where this chaining bends upward.
- Then [Compounding more often, and the number e](04-compounding-frequency-and-e.md) splits a year's factor into pieces, [Natural log and doubling time](05-natural-log-and-doubling-time.md) counts how many double the money, and [Discounting](06-discounting-and-present-value.md) runs one backwards.

---

## Sources

Verified 6 Sep 2026; every source link below resolves.

- Kellison, Stephen G. *The Theory of Interest*, 3rd ed. McGraw-Hill, 2009. [Publisher page](https://www.mheducation.com/highered/product/theory-interest-kellison/M9780073382449.html). Chapter 1: the growth factor as an accumulation function.
- Eurostat. *Statistics Explained: Percentage change*. [Glossary entry](https://ec.europa.eu/eurostat/statistics-explained/index.php?title=Glossary:Percentage+change). The official definition of a percentage change.
- OpenStax. *Prealgebra 2e*, section 6.3. [Book page](https://openstax.org/books/prealgebra-2e/pages/6-3-solve-sales-tax-commission-and-discount-applications). Sections 6.2 and 6.3, price-tag arithmetic at length.
