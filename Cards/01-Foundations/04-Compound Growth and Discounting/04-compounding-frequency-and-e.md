# Compounding more often, and the number e: the ceiling on how fast 5% can grow

[Syllabus](../../../SYLLABUS.md) → [Foundations](../README.md) → [Compound Growth and Discounting](../README.md#s04) → Compounding more often, and the number e

---

## General Overview

Your bank pays 5% a year on $100. Paid once, at year end, that is $105.00.

Ask for it monthly. The bank cuts the 5% into twelve slices and pays one a month. Each slice is smaller, but the early ones sit there earning too, so the year ends above $105.00. Daily is higher again, barely. Every millionth of a second, higher still. The balance creeps up and never gets away: it walks to $105.13 and stops.

The stop is the interesting part. Paying more often is free money, and the free money runs out. Turn the dial up: one dollar at 100% for a year. Paid once, $2.000000. Twice, $2.250000. Monthly, $2.613035. Daily, $2.714567. A million times, $2.718280.

**Cutting a year's interest into more and finer payments always earns more, but the total is capped by a fixed number, 2.718281828, called e.**

**What kind of fact this is:** e is a definition, the name of the ceiling. That more payments always earn more but never pass it is a theorem, shown in words in Why it works.

### The picture: the ladder running out of room

```
$1.00 at 100% for a year, one block = 10 cents, part-blocks dropped

paid once a year               ████████████████████ 2.000000
paid twice a year              ██████████████████████ 2.250000
paid monthly, 12 times         ██████████████████████████ 2.613035
paid daily, 365 times          ███████████████████████████ 2.714567
paid a million times           ███████████████████████████ 2.718280
the ceiling, e by the series   ███████████████████████████ 2.718282
```

The first jump is worth a quarter of a dollar. Daily to a million payments is worth about four tenths of a cent.

---

## The formula

The formula is the payment schedule written out. One dollar at 100%, paid twice: half the rate, paid in twice.

**1.00 × (1 + 0.5) × (1 + 0.5) = 2.250000**

Paid monthly, same shape:

**1.00 × (1 + 1 ÷ 12), multiplied in twelve times over = 2.613035**

Cut finer and the answers climb toward the ceiling. The ceiling is a shrinking list, added up:

**1 + 1 + 1 ÷ 2 + 1 ÷ 6 + 1 ÷ 24 + … = 2.718282**

The same list with 0.05 in it, on $100:

**100.00 × (1 + 0.05 + 0.05 × 0.05 ÷ 2 + 0.05 × 0.05 × 0.05 ÷ 6 + …) = 105.127110, which is $105.13**

**Read it aloud:** cut the rate into equal slices, multiply by one-plus-a-slice once per slice, and however fine you cut, the year hits a ceiling.

| Piece | Plain meaning | In our example | Push it up… |
| --- | --- | --- | --- |
| the starting money | day-one balance | $1.00, then $100.00 | end rises in step |
| the yearly rate | percent promised for a year | 100%, then 5% | higher ceiling |
| the payments | how often interest lands | 1, 2, 12, 365 | more, by less each time |
| one slice | rate divided by payments | 100% ÷ 12 | finer, and more |
| the growth factor | what $1.00 becomes | 2.000000 to 2.718282 | runs into its own ceiling |
| e | the ceiling at 100% | 2.718281828 | nothing moves it |

### When it holds

- **The interest stays in the account.** Take each payment out instead and $1.00 at 100% ends at 2.000000, however often it is paid.
- **The yearly rate is cut into equal slices.** Charge the full 100% every month instead of 100% ÷ 12 and the balance does not stop at 2.718282.
- **One fixed rate, for one year.** e is the ceiling for 100% over one year. At 5% the ceiling on $100 is 105.127110, and a rate that changes partway has its own ceiling.

---

## Why it works

### Splitting the rate does not split the growth

One dollar, 100%, paid twice. Half the rate is 50%, so midyear the account holds 1.50. The second 50% is charged on 1.50, not 1.00: it pays 0.75, and the year ends at 2.250000. That extra 0.25 is the second payment landing on the first one's interest.

### Every extra payment helps less

Monthly gets 2.613035, daily 2.714567, a million payments 2.718280. The extra only ever comes from interest earning interest inside the year, and finer slices only let that start sooner.

### Why it stops

Write out what earns what over the year, at 100%.

- 1 — your dollar
- 1 — the plain interest on it
- 1 ÷ 2 — interest on that interest
- 1 ÷ 6 — interest on *that*
- 1 ÷ 24 — and so on

Each term is the one before divided by the next counting number: halved, then a third, then a quarter. A list shrinking that fast has a finite total: 2.718282, which the ladder only ever reaches from below.

### The ceiling has a name

To nine decimals it is 2.718281828, and it is called **e**: a fixed number, like pi, that does not shift with the rate or the money. "Compounded continuously" means the ceiling was reached.

Put 0.05 in the list instead of 1 and the total comes out smaller: $100 ends at 105.127110, or $105.13 to the cent. Going backwards, from a balance to the time it took, needs the tool that undoes e: [Natural log and doubling time](05-natural-log-and-doubling-time.md).

---

## Worked numbers, by hand

One dollar at 100% for a year, six decimals so the ceiling shows. Then $100 at 5%, to the cent.

| Step | Arithmetic | Value |
| --- | --- | --- |
| paid once a year | 1.00 × (1 + 1) | 2.000000 |
| paid twice | 1.00 × (1 + 1 ÷ 2), twice | 2.250000 |
| paid monthly | 1.00 × (1 + 1 ÷ 12), 12 times | 2.613035 |
| paid daily | 1.00 × (1 + 1 ÷ 365), 365 times | 2.714567 |
| the ceiling | 1 + 1 + 1 ÷ 2 + 1 ÷ 6 + … | 2.718282 |
| $100 at 5%, once | 100.00 × (1 + 0.05) | 105.00 |
| $100, continuous | 100.00 × (1 + 0.05 + 0.05 × 0.05 ÷ 2 + …) | 105.127110 |
| to the cent | rounded | **105.13** |

Just under thirteen cents, for compounding continuously instead of yearly.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Expecting a windfall from continuous | 105.13, against 105.00 | Just under thirteen cents |
| Calling monthly continuous | 2.613035, not 2.718282 | Monthly is nowhere near it |
| Forgetting the slices earn too | 2.000000 | Interest on interest is the mover |

---

## Code, from first principles, and it actually runs

Nothing is imported, so nothing arrives knowing e. One road walks the ladder, one-plus-a-slice per payment, a million times if asked. The other never mentions payments: it adds up the shrinking list.

### Python

```python
# Compounding more often, and the number e -- the check behind the card.  Nothing
# is imported.  $1 at 100% for a year, the rate split n ways and multiplied in n
# times, then the same ceiling a second way: the series 1 + 1 + 1/2 + 1/6 + ...
def ladder(rate, n):                   # (1 + rate/n) multiplied in, n times over
    total = 1.0
    for _ in range(n):
        total = total * (1.0 + rate / n)
    return total
def series(rate):                      # 1 + rate + rate x rate / 2 + ... , 20 terms
    total, term = 0.0, 1.0
    for k in range(1, 21):
        total, term = total + term, term * rate / k
    return total
def row(name, value, places):
    print(f"{name:<33}{value:>13.{places}f}")
for name, n in (("paid once a year", 1), ("paid twice a year", 2),
                ("paid monthly, 12 times", 12), ("paid daily, 365 times", 365),
                ("paid a million times", 1000000)):
    row(name, ladder(1.0, n), 6)
row("the ceiling, e by the series", series(1.0), 6)
row("e, to nine decimals", series(1.0), 9)
yearly, cont = 100.0 * ladder(0.05, 1), 100.0 * series(0.05)
row("$100 at 5%, paid once a year", yearly, 2)
row("$100 at 5%, paid continuously", cont, 6)
row("$100 continuous, to the cent", round(cont, 2), 2)
assert abs(ladder(1.0, 2) - 2.25) < 1e-12
assert abs(series(1.0) - ladder(1.0, 1000000)) < 1e-5
assert round(yearly, 2) == 105.00 and round(cont, 2) == 105.13
print("ALL CHECKS PASS")
```

**Ran 2026-09-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
paid once a year                      2.000000
paid twice a year                     2.250000
paid monthly, 12 times                2.613035
paid daily, 365 times                 2.714567
paid a million times                  2.718280
the ceiling, e by the series          2.718282
e, to nine decimals                2.718281828
$100 at 5%, paid once a year            105.00
$100 at 5%, paid continuously       105.127110
$100 continuous, to the cent            105.13
ALL CHECKS PASS
```

### Rust

Same numbers and labels, via `rustc --edition 2021 -O`.

```rust
// Compounding more often, and the number e -- the same check as the Python one,
// in Rust.  No crates.  $1 at 100% for a year, the rate split n ways and
// multiplied in n times, then the ceiling by the series 1 + 1 + 1/2 + 1/6 + ...
fn ladder(rate: f64, n: u64) -> f64 {      // (1 + rate/n) multiplied in, n times over
    let mut total = 1.0;
    for _ in 0..n { total = total * (1.0 + rate / n as f64); }
    total
}
fn series(rate: f64) -> f64 {              // 1 + rate + rate x rate / 2 + ... , 20 terms
    let (mut total, mut term) = (0.0, 1.0);
    for k in 1..21 { total += term; term = term * rate / k as f64; }
    total
}
fn row(name: &str, value: f64, places: usize) {
    println!("{:<33}{:>13.p$}", name, value, p = places);
}
fn main() {
    let steps: [(&str, u64); 5] = [("paid once a year", 1), ("paid twice a year", 2),
        ("paid monthly, 12 times", 12), ("paid daily, 365 times", 365),
        ("paid a million times", 1000000)];
    for (name, n) in steps { row(name, ladder(1.0, n), 6); }
    row("the ceiling, e by the series", series(1.0), 6);
    row("e, to nine decimals", series(1.0), 9);
    let yearly = 100.0 * ladder(0.05, 1);
    let cont = 100.0 * series(0.05);
    row("$100 at 5%, paid once a year", yearly, 2);
    row("$100 at 5%, paid continuously", cont, 6);
    row("$100 continuous, to the cent", (cont * 100.0).round() / 100.0, 2);
    assert!((ladder(1.0, 2) - 2.25).abs() < 1e-12);
    assert!((series(1.0) - ladder(1.0, 1000000)).abs() < 1e-5);
    assert!(((yearly * 100.0).round() / 100.0 - 105.00).abs() < 1e-9
        && ((cont * 100.0).round() / 100.0 - 105.13).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
paid once a year                      2.000000
paid twice a year                     2.250000
paid monthly, 12 times                2.613035
paid daily, 365 times                 2.714567
paid a million times                  2.718280
the ceiling, e by the series          2.718282
e, to nine decimals                2.718281828
$100 at 5%, paid once a year            105.00
$100 at 5%, paid continuously       105.127110
$100 continuous, to the cent            105.13
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves the card's claims for one dollar at 100%, and again at any fixed yearly rate above zero.

- At 100%, one more payment always ends the year higher, with the interest left in the account.
- However many payments, the total stays below e.
- With enough payments, it gets as close to e as you like.
- The same three facts hold at any fixed yearly rate above zero, with that rate's own ceiling in place of e.
- That ceiling is the shrinking list, added up: 1 + rate + rate × rate ÷ 2 + …, for any rate.
- Paid twice at 100%, the account holds 1.50 midyear, gains 0.75, and ends at 2.25.
- $100 at 5%, paid once a year, ends at exactly $105.00.

The decimals, such as 2.718281828 and $105.13, are left to the Python and Rust checks, and so is how each extra payment helps less.

<details>
<summary>The Lean proof, 116 lines</summary>

```lean
-- Compounding more often, and the number e: cutting a year's interest at a fixed rate into more equal payments always ends the year higher, never reaches the ceiling exp r (which is e at 100%), and gets as close to it as you like, and that ceiling is the sum of the shrinking list 1 + r + r^2/2 + r^3/6 + ...
import Mathlib.Analysis.SpecialFunctions.Complex.LogBounds
import Mathlib.Analysis.SpecialFunctions.Exponential
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Tactic.NormNum

open Filter Topology

/-- Helper: the general-rate statement, proved once and used by both main theorems. -/
theorem compound_aux (r : ℝ) (hr : 0 < r) :
    (∀ n : ℕ, 1 ≤ n →
      (1 + r / (n : ℝ)) ^ n < (1 + r / ((n + 1 : ℕ) : ℝ)) ^ (n + 1)) ∧
    (∀ n : ℕ, 1 ≤ n → (1 + r / (n : ℝ)) ^ n < Real.exp r) ∧
    Tendsto (fun n : ℕ => (1 + r / (n : ℝ)) ^ n) atTop (𝓝 (Real.exp r)) := by
  refine ⟨?_, ?_, Real.tendsto_one_add_div_pow_exp r⟩
  · intro n hn
    have hn' : (0 : ℝ) < n := by exact_mod_cast hn
    have ha : 0 < 1 + r / (n : ℝ) := by positivity
    have hb : 0 < 1 + r / ((n : ℝ) + 1) := by positivity
    set a := 1 + r / (n : ℝ) with ha_def
    set b := 1 + r / ((n : ℝ) + 1) with hb_def
    have hx : b / a = 1 + (-(r / (((n : ℝ) + 1) * ((n : ℝ) + r)))) := by
      rw [ha_def, hb_def]
      field_simp
      ring
    have hxne : -(r / (((n : ℝ) + 1) * ((n : ℝ) + r))) ≠ 0 := by
      have : 0 < r / (((n : ℝ) + 1) * ((n : ℝ) + r)) := by positivity
      linarith
    have hxge : (-1 : ℝ) ≤ -(r / (((n : ℝ) + 1) * ((n : ℝ) + r))) := by
      have h1 : r / (((n : ℝ) + 1) * ((n : ℝ) + r)) ≤ 1 := by
        rw [div_le_one (by positivity)]
        nlinarith
      linarith
    have hb0 := one_add_mul_self_lt_rpow_one_add hxge hxne
      (show (1 : ℝ) < ((n + 1 : ℕ) : ℝ) by push_cast; linarith)
    have hb1 : 1 + ((n + 1 : ℕ) : ℝ) * (-(r / (((n : ℝ) + 1) * ((n : ℝ) + r)))) <
        (1 + (-(r / (((n : ℝ) + 1) * ((n : ℝ) + r))))) ^ (n + 1) := by
      rwa [Real.rpow_natCast] at hb0
    rw [← hx, div_pow] at hb1
    have e1 : (1 : ℝ) + ((n + 1 : ℕ) : ℝ) * (-(r / (((n : ℝ) + 1) * ((n : ℝ) + r)))) = 1 / a := by
      rw [ha_def]
      push_cast
      field_simp
      ring
    rw [e1, lt_div_iff₀ (by positivity)] at hb1
    have : 1 / a * a ^ (n + 1) = a ^ n := by
      rw [pow_succ]; field_simp
    have hcast : (((n + 1 : ℕ) : ℝ)) = (n : ℝ) + 1 := by push_cast; ring
    rw [hcast]
    rw [this] at hb1
    exact hb1
  · intro n hn
    have hn' : (0 : ℝ) < n := by exact_mod_cast hn
    have h1 : 1 + r / (n : ℝ) < Real.exp (r / (n : ℝ)) := by
      have := Real.add_one_lt_exp (show r / (n : ℝ) ≠ 0 by positivity)
      linarith
    have h0 : (0 : ℝ) ≤ 1 + r / (n : ℝ) := by positivity
    calc (1 + r / (n : ℝ)) ^ n < Real.exp (r / (n : ℝ)) ^ n :=
          pow_lt_pow_left₀ h1 h0 (by omega)
      _ = Real.exp r := by
          rw [← Real.exp_nat_mul]; congr 1; field_simp

/-- One dollar at 100% for a year, with the interest left in the account and the rate cut
into `n` equal slices, ends the year at `(1 + 1/n)^n`. Paying more often always earns more:
`n + 1` payments beat `n` payments. But the total is capped by `e = exp 1`: it stays below `e`
for every number of payments, and it climbs as close to `e` as you like. -/
theorem more_payments_earn_more_but_never_pass_e :
    (∀ n : ℕ, 1 ≤ n →
      (1 + 1 / (n : ℝ)) ^ n < (1 + 1 / ((n + 1 : ℕ) : ℝ)) ^ (n + 1)) ∧
    (∀ n : ℕ, 1 ≤ n → (1 + 1 / (n : ℝ)) ^ n < Real.exp 1) ∧
    Tendsto (fun n : ℕ => (1 + 1 / (n : ℝ)) ^ n) atTop (𝓝 (Real.exp 1)) := by
  have h := compound_aux 1 one_pos
  simpa using h

/-- The same at any fixed yearly rate `r > 0` (5% is `r = 1/20`): one dollar paid `n` equal
slices `r / n`, interest left in, ends at `(1 + r/n)^n`. More payments always earn more, the
total stays below the ceiling `exp r`, and it climbs as close to `exp r` as you like. -/
theorem more_payments_at_any_rate_capped_by_exp (r : ℝ) (hr : 0 < r) :
    (∀ n : ℕ, 1 ≤ n →
      (1 + r / (n : ℝ)) ^ n < (1 + r / ((n + 1 : ℕ) : ℝ)) ^ (n + 1)) ∧
    (∀ n : ℕ, 1 ≤ n → (1 + r / (n : ℝ)) ^ n < Real.exp r) ∧
    Tendsto (fun n : ℕ => (1 + r / (n : ℝ)) ^ n) atTop (𝓝 (Real.exp r)) := by
  exact compound_aux r hr

/-- The ceiling is a shrinking list, added up: `1 + r + r^2/2 + r^3/6 + r^4/24 + ...`, each
term the one before times `r` and divided by the next counting number, adds up to `exp r`.
At `r = 1` this is `1 + 1 + 1/2 + 1/6 + ... = e`. -/
theorem ceiling_is_the_shrinking_list (r : ℝ) :
    HasSum (fun k : ℕ => r ^ k / (Nat.factorial k : ℝ)) (Real.exp r) := by
  have h := NormedSpace.expSeries_div_hasSum_exp (𝔸 := ℝ) r
  rw [Real.exp_eq_exp_ℝ]
  exact h

-- Worked numbers, as exact fractions.
-- One dollar at 100%, paid once a year: 2.
example : (1 + 1 : ℚ) ^ 1 = 2 := by norm_num
-- Paid twice: midyear the account holds 3/2, the second half pays 3/4, the year ends at 9/4.
example : (1 : ℚ) * (1 + 1 / 2) = 3 / 2 := by norm_num
example : (3 / 2 : ℚ) * (1 / 2) = 3 / 4 := by norm_num
example : (1 + 1 / 2 : ℚ) ^ 2 = 9 / 4 := by norm_num
-- The extra quarter is the second payment landing on the first one's interest.
example : (9 / 4 : ℚ) - 2 = 1 / 4 := by norm_num
-- Paid monthly: exactly 13^12 / 12^12.
example : (1 + 1 / 12 : ℚ) ^ 12 = 13 ^ 12 / 12 ^ 12 := by norm_num
-- Taking each payment out instead: 12 or 365 slices of 100% still end at 2.
example : (1 : ℚ) + 12 * (1 / 12) = 2 := by norm_num
example : (1 : ℚ) + 365 * (1 / 365) = 2 := by norm_num
-- $100 at 5%, paid once a year: $105.
example : (100 : ℚ) * (1 + 5 / 100) = 105 := by norm_num
-- The shrinking list: each term is the one before divided by the next counting number.
example : (1 : ℚ) / 2 / 3 = 1 / 6 ∧ (1 : ℚ) / 6 / 4 = 1 / 24 := by norm_num

#print axioms compound_aux
#print axioms more_payments_earn_more_but_never_pass_e
#print axioms more_payments_at_any_rate_capped_by_exp
#print axioms ceiling_is_the_shrinking_list
```

</details>

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'compound_aux' depends on axioms: [propext, Classical.choice, Quot.sound]
'more_payments_earn_more_but_never_pass_e' depends on axioms: [propext, Classical.choice, Quot.sound]
'more_payments_at_any_rate_capped_by_exp' depends on axioms: [propext, Classical.choice, Quot.sound]
'ceiling_is_the_shrinking_list' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **Pay it ten million times.** Change the last 1000000 to 10000000. The row prints 2.718282, matching the ceiling row under it: arrived to six decimals, still not past.
> - **Turn the dial down to 5%.** Change `ladder(1.0, n)` to `ladder(0.05, n)`. It runs from 1.050000 to 1.051271 — on $100, the 105.127110 already there.

---

## The usual mistake

> [!warning]
> **Thinking that paying more often keeps paying more.** One dollar at 100% for a year ends under 2.718282 whether the interest lands twice, daily or a million times. Past daily there is nothing left to buy.
>
> - Reading "5% compounded monthly" as 5% a month. It is a twelfth of that.
> - Rounding e before multiplying. Round money at the end, to the nearest cent.
> - Blaming continuous compounding for a jump in a balance. Here it is just under thirteen cents.

---

## Where you meet it in real life

- **The two rates on a credit card offer.** APR (annual percentage rate) is the advertised one, APY (annual percentage yield) the one you pay. They differ because the charge lands monthly or daily.
- **Anything that grows or decays on its own.** Populations, bacteria, a cooling room, a drug clearing your blood: nothing waits for a payment date, so e is how they are written.
- **Moving money between dates.** Option and rate models compound continuously: one convention instead of many schedules. [Discounting](06-discounting-and-present-value.md).

> **Say it back**
> Interest paid more often earns a little more, because the early payments earn too. One dollar at 100% goes 2.000000 paid once, 2.250000 twice, 2.613035 monthly, 2.714567 daily. The gains shrink and stop at a ceiling: 2.718281828, called e. Reaching it is what "compounded continuously" means. On $100 at 5% that is $105.13 against $105.00.

---

## What this builds on

- [Compound interest](03-compound-interest.md): interest that earns interest, and why the balance bends upward. This card pays it in smaller instalments.

## Where this goes next

- [Natural log and doubling time](05-natural-log-and-doubling-time.md): the tool that undoes e, and how long money takes to double.
- [Discounting](06-discounting-and-present-value.md): the ladder backwards, money next year turned into money today.

This card leaves one question open: how long does money growing at a steady rate take to double?

---

## Sources

Verified 2026-11-11: every link below resolves to the publisher's page.

- NIST. *Digital Library of Mathematical Functions*, §4.2. [dlmf.nist.gov/4.2](https://dlmf.nist.gov/4.2). The reference definition of e.
- Euler, Leonhard. *Introduction to Analysis of the Infinite, Book I*, trans. John D. Blanton. Springer, 1988. [doi:10.1007/978-1-4612-1021-4](https://doi.org/10.1007/978-1-4612-1021-4). Where the series and the letter e were set out.
- Maor, Eli. *e: The Story of a Number*. Princeton University Press, 1994. [Publisher page](https://press.princeton.edu/books/paperback/9780691168487/e-the-story-of-a-number). The history, at book length.
