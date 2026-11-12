# Simple interest: the same $20 every year, a straight line

[Syllabus](../../../SYLLABUS.md) → [Foundations](../README.md) → [Compound Growth and Discounting](../README.md#s04) → Simple interest

---

## General Overview

Your cousin asks to borrow $500. You say yes, at 4% a year, on **simple interest**: the charge is worked out on the $500 you handed over, and on nothing else, ever.

4% of $500 is $20.00. So the debt grows by $20.00 in the first year, $20.00 in the second, $20.00 in the fifth. The $500 never changes, so the $20.00 never changes either. After five years the interest adds up to $100.00 and your cousin owes you $600.00.

The $500 has a name: the **principal**, the money actually handed over, as opposed to the interest stacked on top of it. Simple interest is the deal where the percent is only ever taken of the principal.

**The same amount is added every year, so the balance climbs in equal steps — a straight line.**

**What kind of fact this is:** a definition: a deal two people agree on, not a law of nature. The straight line follows from it, shown in Why it works.

### The picture: what your cousin owes

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "What your cousin owes, year by year"
    x-axis "Years since the loan" [0, 1, 2, 3, 4, 5]
    y-axis "Owed, in dollars" 480 --> 620
    line [500, 520, 540, 560, 580, 600]
```

The line is the balance owed; the axis starts at $480 so the steps show. Each year adds the same $20.00, so the points land on a straight line. Interest that earned interest would bend upward — [Compound interest](03-compound-interest.md).

---

## The formula

The deal, written as numbers:

**one year's interest = 500.00 × 0.04 = 20.00**

**five years' interest = 500.00 × 0.04 × 5 = 100.00**

**to repay = 500.00 + 100.00 = 600.00**

**Read it aloud:** the money lent, times the rate as a decimal, times the years, is the interest — add the money lent back on and that is the bill.

The standard form, the one you will meet elsewhere: interest = principal × rate × years.

| Piece | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| the principal | the money actually handed over, once | $500.00 | lend twice as much, earn twice the interest |
| the rate | the percent charged per year, as a decimal | 0.04 | double it and every year's charge doubles |
| the years | how long the money stays out | 5 | each extra year adds one more $20.00 |
| the interest | the charge for use of the money, added up | $100.00 | rises in step with all three above |
| the total to repay | principal plus interest | $600.00 | rises with all three above too |

4% means four per hundred, which as a decimal is 0.04 — the move made on [Growth factors](01-growth-factors.md).

### When it holds

- **The percent is taken of the principal only.** Take it of the balance and the bill is $608.33, not $600.00.
- **The rate is a decimal.** Leave 4% as 4 and the bill is $10500.00.
- **The rate and the term use the same clock.** Count a five-month loan as 5 years and it is charged the full $100.00.

---

## Why it works

### The percent never leaves the $500

Interest is rent on money. Simple interest sets the rent on the thing that was lent — the $500 — and leaves it there. Year three ignores the interest on the books, because that interest was never handed over. So the yearly charge is 500.00 × 0.04 = 20.00, every single year.

### Adding the same thing five times is multiplying by five

Five years of the deal is $20.00 owed, five times over. Adding one fixed amount over and over is what multiplying is, so the total is 20.00 × 5 = 100.00. Swap the $20.00 back for 500.00 × 0.04 and it is 500.00 × 0.04 × 5 = 100.00 in one move. Two roads, one $100.00; the code drives both.

### That is exactly what makes it a straight line

A straight line is the shape of equal steps: the same rise for every step sideways. The step here is $20.00 a year, unchanging, so the balance walks 500.00, 520.00, 540.00, 560.00, 580.00, 600.00 — a line. Equal-step growth has a name: [Linear versus exponential growth](../03-Powers%2C%20Roots%20and%20Logarithms/02-linear-vs-exponential-growth.md).

Let each year's interest join the principal and start earning, and the step stops being equal, so the shape stops being a line. That is [Compound interest](03-compound-interest.md).

---

## Worked numbers, by hand

The cousin loan, in dollars to 2 decimal places. Nothing in this table needs rounding; every figure lands on the cent.

| Step | Arithmetic | Value |
| --- | --- | --- |
| the rate, as a decimal | 4 ÷ 100 | 0.04 |
| one year's interest | 500.00 × 0.04 | 20.00 |
| after year 1 | 500.00 + 20.00 | 520.00 |
| after year 2 | 520.00 + 20.00 | 540.00 |
| after year 3 | 540.00 + 20.00 | 560.00 |
| after year 4 | 560.00 + 20.00 | 580.00 |
| after year 5 | 580.00 + 20.00 | 600.00 |
| the same, in one move | 500.00 + 500.00 × 0.04 × 5 | **600.00** |

Your cousin hands back $600.00: the $500.00 you lent, plus $100.00 for five years of having it.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Charging on the balance, not the principal | $608.33 | The interest started earning interest: a different deal. |
| Using 4 where the rate belongs | $10500.00 | The percent was never turned into a decimal. |
| Asking only for the interest | $100.00 | The principal comes home too. |

---

## Code, from first principles, and it actually runs

Nothing is imported. The loan is worked twice — once by walking the five years and adding $20.00 each time, once by the one-move formula — and the two answers have to agree. The wrong answers above are printed too, so the card cannot quietly disagree with itself.

### Python

```python
# Simple interest -- the check behind the card.  Nothing is imported.  $500
# lent to a cousin at 4% a year, simple interest, for five years.  Two roads:
# the one-line formula, and adding the same $20.00 on five times.
principal, rate, years = 500.00, 0.04, 5

def row(name, value):
    print(f"{name:<38}{'$' + format(value, '.2f'):>10}")

per_year = principal * rate                      # the same $20.00 every year
balance, steps = principal, [principal]
for _ in range(years):                           # road 1: add it on, year by year
    balance = balance + per_year
    steps.append(balance)
by_formula = principal * rate * years            # road 2: straight to the total
compound, wrong_rate = principal, principal + principal * 4 * years
for _ in range(years):
    compound = compound * (1 + rate)             # the mistake: interest on interest
row("principal lent to the cousin", principal)
row("interest each year, 500.00 x 0.04", per_year)
print(f"{'balance, years 0 to 5':<38}" + " ".join(f"${b:.2f}" for b in steps))
row("interest after five years, added up", balance - principal)
row("the same by principal x rate x years", by_formula)
row("step from each year to the next", steps[1] - steps[0])
row("to repay after five years", balance)
row("if the interest earned interest", compound)
row("if 4% were read as 4", wrong_rate)
assert abs(per_year - 20.00) < 1e-9 and abs(balance - 600.00) < 1e-9
assert abs(by_formula - 100.00) < 1e-9 and abs(balance - principal - by_formula) < 1e-9
assert all(abs(b - (500.00 + 20.00 * i)) < 1e-9 for i, b in enumerate(steps))
print("ALL CHECKS PASS")
```

**Ran 2026-09-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
principal lent to the cousin             $500.00
interest each year, 500.00 x 0.04         $20.00
balance, years 0 to 5                 $500.00 $520.00 $540.00 $560.00 $580.00 $600.00
interest after five years, added up      $100.00
the same by principal x rate x years     $100.00
step from each year to the next           $20.00
to repay after five years                $600.00
if the interest earned interest          $608.33
if 4% were read as 4                   $10500.00
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Simple interest -- the same check as simple_interest_check.py, in Rust.  No
// crates.  $500 lent to a cousin at 4% a year, simple interest, five years.
// Two roads: the one-line formula, and adding the same $20.00 on five times.
fn row(name: &str, value: f64) {
    println!("{:<38}{:>10}", name, format!("${:.2}", value));
}

fn main() {
    let (principal, rate, years) = (500.00f64, 0.04f64, 5);
    let per_year = principal * rate;                 // the same $20.00 every year
    let mut balance = principal;
    let mut steps = vec![principal];
    for _ in 0..years {                              // road 1: add it on, year by year
        balance = balance + per_year;
        steps.push(balance);
    }
    let by_formula = principal * rate * years as f64;   // road 2: straight to the total
    let wrong_rate = principal + principal * 4.0 * years as f64;
    let mut compound = principal;
    for _ in 0..years {
        compound = compound * (1.0 + rate);          // the mistake: interest on interest
    }
    row("principal lent to the cousin", principal);
    row("interest each year, 500.00 x 0.04", per_year);
    let cells: Vec<String> = steps.iter().map(|b| format!("${:.2}", b)).collect();
    println!("{:<38}{}", "balance, years 0 to 5", cells.join(" "));
    row("interest after five years, added up", balance - principal);
    row("the same by principal x rate x years", by_formula);
    row("step from each year to the next", steps[1] - steps[0]);
    row("to repay after five years", balance);
    row("if the interest earned interest", compound);
    row("if 4% were read as 4", wrong_rate);
    assert!((per_year - 20.00).abs() < 1e-9 && (balance - 600.00).abs() < 1e-9);
    assert!((by_formula - 100.00).abs() < 1e-9 && (balance - principal - by_formula).abs() < 1e-9);
    for (i, b) in steps.iter().enumerate() {
        assert!((b - (500.00 + 20.00 * i as f64)).abs() < 1e-9);
    }
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
principal lent to the cousin             $500.00
interest each year, 500.00 x 0.04         $20.00
balance, years 0 to 5                 $500.00 $520.00 $540.00 $560.00 $580.00 $600.00
interest after five years, added up      $100.00
the same by principal x rate x years     $100.00
step from each year to the next           $20.00
to repay after five years                $600.00
if the interest earned interest          $608.33
if 4% were read as 4                   $10500.00
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves the simple-interest rules for every principal, every rate and every number of years, not just the cousin's loan.

- After any number of years, the balance is the principal plus principal × rate × years.
- Between any two years, the balance changes by principal × rate × the years between them: equal steps, a straight line.
- If the interest earned interest, the bill would be higher from the second year on, for any principal and rate above zero.
- The cousin's numbers: $20.00 a year, $600.00 to repay, $10500.00 if 4% were read as 4, and $608.33 if interest earned interest.

The printed tables and the year-by-year runs are left to the Python and Rust checks.

```lean
-- Simple interest: when the same charge, principal times rate, is added every year, the balance after n years is the principal plus principal times rate times n, the balance climbs in equal steps along a straight line, interest that earns interest ends up strictly higher from year two on, and the card's cousin-loan numbers come out as it says.
import Mathlib.Basic.Real.Basic
import Mathlib.Data.Rat.Defs
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Positivity

/-- Simple interest, interest = principal × rate × years: if a loan of `P` at rate `r`
(a decimal, per year) starts at `P` and each year adds the percent taken of the principal
only, `P × r`, then after `n` years the balance is `P + P × r × n`, so the interest added
up is `P × r × n`. -/
theorem simple_interest_balance (P r : ℝ) (b : ℕ → ℝ)
    (h0 : b 0 = P) (hstep : ∀ n, b (n + 1) = b n + P * r) :
    ∀ n : ℕ, b n = P + P * r * n := by
  intro n
  induction n with
  | zero => simp [h0]
  | succ k ih =>
    rw [hstep, ih]
    push_cast
    ring

/-- A straight line: under simple interest the balance rises by the same yearly charge
`P × r` for every year that passes, so between any two years `m` and `n` the balance
changes by `P × r × (n - m)`. -/
theorem simple_interest_straight_line (P r : ℝ) (b : ℕ → ℝ)
    (h0 : b 0 = P) (hstep : ∀ n, b (n + 1) = b n + P * r) :
    ∀ m n : ℕ, b n - b m = P * r * ((n : ℝ) - m) := by
  intro m n
  have h := simple_interest_balance P r b h0 hstep
  rw [h n, h m]
  ring

/-- Taking the percent of the balance instead of the principal is a different deal: if the
interest earns interest (each year adds `r` times the current balance), then for a positive
principal and a positive rate the bill is strictly higher than the simple-interest bill
from the second year on. -/
theorem interest_on_interest_bill_higher (P r : ℝ) (hP : 0 < P) (hr : 0 < r)
    (b c : ℕ → ℝ)
    (hb0 : b 0 = P) (hb : ∀ n, b (n + 1) = b n + P * r)
    (hc0 : c 0 = P) (hc : ∀ n, c (n + 1) = c n + c n * r) :
    ∀ n : ℕ, 2 ≤ n → b n < c n := by
  have hc1 : c 1 = P + P * r := by rw [hc 0, hc0]
  have hc2 : c 2 = P + 2 * P * r + P * r ^ 2 := by
    have := hc 1
    rw [hc1] at this
    rw [show (2:ℕ) = 1 + 1 from rfl, this]; ring
  have hcpos : ∀ n : ℕ, 0 < c n := by
    intro n
    induction n with
    | zero => rw [hc0]; exact hP
    | succ k ih => rw [hc]; nlinarith [mul_pos ih hr]
  have key : ∀ n : ℕ, 2 ≤ n → P + P * r * n < c n := by
    intro n hn
    induction n, hn using Nat.le_induction with
    | base =>
      rw [hc2]; push_cast
      nlinarith [mul_pos hP (pow_pos hr 2)]
    | succ k hk ih =>
      rw [hc]
      push_cast
      have hk0 : (0:ℝ) ≤ k := Nat.cast_nonneg k
      nlinarith [mul_pos hP hr, mul_pos (mul_pos hP hr) hr, mul_nonneg (mul_nonneg (mul_pos hP hr).le hr.le) hk0, mul_lt_mul_of_pos_right ih hr]
  intro n hn
  have h := simple_interest_balance P r b hb0 hb n
  rw [h]
  exact key n hn

-- The card's worked numbers, in whole dollars (4% is 4 per 100).
example : 500 * 4 / 100 = 20 := by decide              -- one year's interest
example : 500 + 20 = 520 := by decide                  -- after year 1
example : 520 + 20 = 540 := by decide                  -- after year 2
example : 540 + 20 = 560 := by decide                  -- after year 3
example : 560 + 20 = 580 := by decide                  -- after year 4
example : 580 + 20 = 600 := by decide                  -- after year 5
example : 20 * 5 = 100 := by decide                    -- five years' interest, added up
example : 500 * 4 * 5 / 100 = 100 := by decide         -- principal × rate × years
example : 500 + 500 * 4 * 5 / 100 = 600 := by decide   -- the same, in one move
-- The same in the main theorem's form, with the rate 4/100 as an exact fraction.
example : (500 : ℝ) + 500 * (4 / 100) * 5 = 600 := by norm_num
-- The mistakes.
example : 500 + 500 * 4 * 5 = 10500 := by decide       -- 4% read as 4
-- Interest on interest: 500 × 1.04^5 is exactly 608.3264512, which is $608.33 to the cent.
example : (500 : ℚ) * (1 + 4 / 100) ^ 5 = 6083264512 / 10000000 := by norm_num
example : (60832.5 : ℚ) ≤ 500 * (1 + 4 / 100) ^ 5 * 100 ∧
    (500 : ℚ) * (1 + 4 / 100) ^ 5 * 100 < 60833.5 := by norm_num

#print axioms simple_interest_balance
#print axioms simple_interest_straight_line
#print axioms interest_on_interest_bill_higher
```

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'simple_interest_balance' depends on axioms: [propext, Classical.choice, Quot.sound]
'simple_interest_straight_line' depends on axioms: [propext, Classical.choice, Quot.sound]
'interest_on_interest_bill_higher' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it. The asserts are pinned to the cousin's numbers, so expect one to fire.
> - **Let the interest earn interest.** In the year-by-year loop, multiply the balance by 1 plus the rate instead of adding the fixed charge. The steps stop being equal, the bill climbs to the $608.33 row, and the first assert fires: the balance is no longer $600.00.
> - **Take the percent sign literally.** Set the rate to 4, not 0.04. Every charge is a hundred times too big, the bill becomes the $10500.00 row, and the first assert fires.

---

## The usual mistake

> [!warning]
> **Assuming that interest, once charged, starts earning.** It does on a savings account and a credit card. Not here. Simple interest pins the charge to the money actually lent, so the fifth year costs the same $20.00 as the first. Run the loan the other way and the bill is $608.33, not $600.00 — small over five years, enormous over thirty.
>
>
> - Leaving the percent as 4 instead of 0.04. The loan comes back at $10500.00.
> - Quoting the interest as the bill. $100.00 is what the loan cost; $600.00 is what gets handed over.
> - Mixing units: a rate per year, a term in months. Both must be on the same clock before they multiply.

---

## Where you meet it in real life

- **Car loans.** Mostly simple interest: the charge never earns interest, and the same rule is applied to the part of the loan still unpaid, which is why paying early saves money.
- **A late invoice.** A flat percent per month, charged on the overdue bill itself and not on the penalties already added.
- **Money lent between people.** The cousin deal. Unless somebody says compound, this is what both of you have in mind — and it is the wrong model for a bank account: [Compound interest](03-compound-interest.md).

> **Say it back**
> Simple interest charges the percent on the money actually lent, never on the interest. $500 at 4% earns $20.00 a year, the same $20.00 each time. Five years of that is $100.00, so your cousin repays $600.00. The same amount added each year means equal steps, which plot as a straight line. Let the interest earn interest and it becomes $608.33, and a curve.

---

## What this builds on

- [Growth factors](01-growth-factors.md): turning 4% into the decimal 0.04 you multiply by.
- [Linear versus exponential growth](../03-Powers%2C%20Roots%20and%20Logarithms/02-linear-vs-exponential-growth.md): the shape of equal steps, which is what this balance is.

## Where this goes next

- [Compound interest](03-compound-interest.md): what happens when each year's interest joins the principal and earns too. It runs its own example, a savings account.

This card leaves one question open: how much more does money grow when the interest earns interest too?

---

## Sources

Verified 6 Sep 2026 in a browser: every link below resolves to the publisher's page.

- Consumer Financial Protection Bureau. *Auto loans*. [consumerfinance.gov](https://www.consumerfinance.gov/consumer-tools/auto-loans/). The US regulator on loans priced against the outstanding principal.
- U.S. Securities and Exchange Commission. *Interest*, Investor.gov glossary. [investor.gov](https://www.investor.gov/introduction-investing/investing-basics/glossary/interest). The regulator's definition of interest.
- U.S. Securities and Exchange Commission. *Compound Interest Calculator*. [investor.gov](https://www.investor.gov/financial-tools-calculators/calculators/compound-interest-calculator). The contrast: what happens once the interest earns.
