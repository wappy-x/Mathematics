# Continued fractions: Euclid's algorithm read as nested fractions, and why the leap-year rule is 97 in 400

[Syllabus](../../../SYLLABUS.md) → [Number theory](../README.md) → [For the Curious](../README.md#s07) → Continued fractions

---

## General Overview

A year is not 365 days. It is 365.2422 days, near enough: 365 whole days and a leftover of 0.2422 of a day. Leap days are how the calendar swallows it. So: what is the cheapest fraction close to 0.2422? Cheap means a small bottom number — how many years until the rule repeats.

[Euclid's algorithm](../02-Greatest%20Common%20Divisor%20and%20Euclid%27s%20Algorithm/03-euclidean-algorithm.md) answers it. Run it on 0.2422 written as a fraction, 1211/5000, and it returns whole numbers: 0, 4, 7, 1, 3, 4, 1, 1, 1, 2. The leading 0 is step 0 — no whole days in the leftover. Cut the list short after step 1, then 2, 3, 4, and you get 1/4, 7/29, 8/33, 31/128 — each the best fraction of its size. The first, one leap day every four years, is Julius Caesar's rule.

**Euclid's algorithm on a fraction returns a list of whole numbers; cutting the list short gives the best cheap approximations, cheapest first.**

**What kind of fact this is:** a theorem. Why it works gives the shape of the proof; Khinchin, in Sources, gives it in full.

### The picture

```
Days the calendar drifts in 400 years.  One block = 0.1 days.
A minus means the calendar year is too short instead of too long.

  1/4       3.120  ███████████████████████████████
  7/29     -0.328  ███
  8/33      0.090  █
 31/128    -0.005
 97/400     0.120  █
```

1/4 is the outlier: 3.120 days too many every 400 years — what Pope Gregory's reform had to mop up.

---

## The formula

Stack the steps into nested fractions and the leftover is exact:

**0.2422 = 1 / (4 + 1 / (7 + 1 / (1 + 1 / (3 + …))))**

**Read it aloud:** one over four — except the four is four-and-a-bit, and the bit is one over seven-and-a-bit, each correction smaller than the last.

That stack is a **continued fraction**. Cut it at a plus sign and work out what is left: a plain fraction. Those cut-offs are the **convergents** — from here on, the **stops**.

| Piece | Plain meaning | In our year |
| --- | --- | --- |
| the leftover | what is left after 365 whole days | 0.2422 |
| a step | one number from Euclid's list | 0, 4, 7, 1, 3, … |
| a stop | the fraction from cutting short | 1/4 at step 1 … 31/128 at step 4 |
| top and bottom | leap days inserted, years in the cycle | 31 and 128 |

### When it holds

- **The number is a fraction.** If it is irrational, the list never ends.
- **Best means best for its size.** Allow bigger bottom numbers and a later stop beats it.
- **The year is measured, near enough.** Change a late digit of 0.2422 and the later steps change; 1/4 stays.

---

## Why it works

### Step 0: peel off the whole part, then flip what is left

Write down a number's whole part. The leftover is under 1, so turn it upside down: now it is over 1, with a whole part of its own. Write that down. Repeat. Each flip gives the next step.

### Step 1: that is Euclid's algorithm

0.2422 is exactly 2422/10000, which cuts down to 1211/5000. Divide with remainder over and over, each time dividing the last divisor by the last remainder. Asking how many whole times 1211 goes into 5000 asks for the whole part of the flipped leftover.

| Divide | Whole times | What is left |
| --- | --- | --- |
| 1211 by 5000 | 0 | 1211 |
| 5000 by 1211 | 4 | 156 |
| 1211 by 156 | 7 | 119 |
| 156 by 119 | 1 | 37 |
| 119 by 37 | 3 | 8 |

The list carries on 4, 1, 1, 1, 2, then a remainder of 0 shuts it down: every ordinary fraction's list stops, because Euclid's algorithm stops ([Irrational numbers](../../01-Foundations/02-The%20Number%20Line/03-irrational-numbers.md) is where they never do).

The stops build themselves from the steps: new top number = the step, times the previous top, plus the top before that. Bottoms the same. Start from 0/1, with 1/0 imagined before it. From 7/29 and the step 1: 8 = 1 × 7 + 1, 33 = 1 × 29 + 4.

### Step 2: each stop is the best of its size

**No fraction with a bottom number up to 128 is closer to 0.2422 than 31/128 is.**

Cutting the stack short is the only loss, and what you drop sits under every division above it. The stops overshoot and undershoot in turn, and the gap shrinks faster than the bottom number grows. Square roots give lists that repeat forever.

---

## Worked numbers, by hand

| Stop | Arithmetic | Value, then drift over 400 years |
| --- | --- | --- |
| 1/4 | 1 ÷ 4 | 0.250000, 3.120 |
| 7/29 | 7 ÷ 29 | 0.241379, -0.328 |
| 8/33 | 8 ÷ 33 | 0.242424, 0.090 |
| 31/128 | 31 ÷ 128 | 0.242188, -0.005 |
| 97/400 | 97 ÷ 400 | 0.242500, **0.120** |

Drift is (the value − 0.2422) × 400: an average rate on a common 400-year yardstick. Count the rule out year by year and 97 appears on its own: of 400 years, 100 are divisible by four, and 3 of those centuries get skipped.

The calendar on your wall is 0.120 days out after 400 years; a whole day of drift takes thousands of years.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Stopping at 1/4 | 3.120 | a quarter is bigger than 0.2422 |
| Treating 97/400 as best of its size | 0.120, not -0.005 | 31/128 is closer |
| Calling a stop exact | 0.090, for 8/33 | best of its size is not exact |

---

## Code, from first principles, and it actually runs

Nothing is imported. Road one runs Euclid's algorithm on 1211/5000 and builds the stops as it goes. Road two ignores it: it tries every bottom number up to a cap, keeps the closest, and counts the Gregorian leap years, 1 to 400. Then the same steps on pi.

### Python

```python
# Continued fractions and the leap year -- the check behind the card.  Nothing is
# imported.  A year is 365.2422 days; Euclid on the leftover 0.2422 = 1211/5000 gives
# the steps, stopping early gives the fractions, brute force is the second road.
LEFT = 1211 / 5000
def euclid_steps(a, b):                        # 1211/5000 -> 0, 4, 7, 1, 3, ...
    out = []
    while b: out.append(a // b); a, b = b, a % b
    return out
def stops(steps):                              # the early stops, as top/bottom
    top, t_before, bot, b_before, out = steps[0], 1, 1, 0, [(steps[0], 1)]
    for s in steps[1:]:
        top, t_before, bot, b_before = s * top + t_before, top, s * bot + b_before, bot
        out.append((top, bot))
    return out
def best_upto(cap):                            # closest fraction, bottom <= cap
    return min(((round(q * LEFT), q) for q in range(1, cap + 1)), key=lambda f: abs(LEFT - f[0] / f[1]))
steps = euclid_steps(1211, 5000); four = stops(steps)[1:5]
leaps = sum(1 for y in range(1, 401) if y % 4 == 0 and (y % 100 != 0 or y % 400 == 0))
print(f"{'a year, in days':<40}365.2422")
print(f"{'the leftover after 365 whole days':<40}0.2422 = 1211/5000")
print(f"{'the whole-number steps, from Euclid':<40}" + ", ".join(map(str, steps)))
rows = [(f"   stop after step {i}", p, q) for i, (p, q) in enumerate(four, 1)] + [("   the Gregorian rule", 97, 400)]
for name, p, q in rows: print(f"{name:<22}{p:>4}/{q:<5}{p / q:.6f}{(p / q - LEFT) * 400:>9.3f} days adrift per 400 years")
print(f"counting the real rule over 400 years: {400 // 4} minus {400 // 4 - leaps} century skips is {leaps} leap days")
print(f"every stop beats every fraction with a bottom up to its own; best up to 400 is {best_upto(400)[0]}/{best_upto(400)[1]}, not 97/400")
print("pi as 3.14159265358979, same trick: " + ", ".join(f"{p}/{q}" for p, q in stops(euclid_steps(314159265358979, 100000000000000))[:4]))
assert four == [(1, 4), (7, 29), (8, 33), (31, 128)] and leaps == 97
assert all(best_upto(q) == (p, q) for p, q in four) and best_upto(400) == (31, 128)
assert abs(97 / 400 - LEFT) > 20 * abs(31 / 128 - LEFT)
print("ALL CHECKS PASS")
```

**Ran 2026-09-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
a year, in days                         365.2422
the leftover after 365 whole days       0.2422 = 1211/5000
the whole-number steps, from Euclid     0, 4, 7, 1, 3, 4, 1, 1, 1, 2
   stop after step 1     1/4    0.250000    3.120 days adrift per 400 years
   stop after step 2     7/29   0.241379   -0.328 days adrift per 400 years
   stop after step 3     8/33   0.242424    0.090 days adrift per 400 years
   stop after step 4    31/128  0.242188   -0.005 days adrift per 400 years
   the Gregorian rule   97/400  0.242500    0.120 days adrift per 400 years
counting the real rule over 400 years: 100 minus 3 century skips is 97 leap days
every stop beats every fraction with a bottom up to its own; best up to 400 is 31/128, not 97/400
pi as 3.14159265358979, same trick: 3/1, 22/7, 333/106, 355/113
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Continued fractions and the leap year -- the same check in Rust, no crates.
// A year is 365.2422 days; Euclid on the leftover 0.2422 = 1211/5000 gives the
// steps, stopping early gives the fractions, brute force is the second road.
const LEFT: f64 = 1211.0 / 5000.0;
fn euclid_steps(mut a: i64, mut b: i64) -> Vec<i64> {   // 1211/5000 -> 0, 4, 7, 1, 3, ...
    let mut out = Vec::new();
    while b != 0 { out.push(a / b); let r = a % b; a = b; b = r; }
    out
}
fn stops(steps: &[i64]) -> Vec<(i64, i64)> {            // the early stops, as top/bottom
    let (mut t, mut tb, mut b, mut bb) = (steps[0], 1i64, 1i64, 0i64);
    let mut out = vec![(t, b)];
    for &s in &steps[1..] { let (nt, nb) = (s * t + tb, s * b + bb); tb = t; bb = b; t = nt; b = nb; out.push((t, b)); }
    out
}
fn best_upto(cap: i64) -> (i64, i64) {                  // closest fraction, bottom <= cap
    let (mut bp, mut bq, mut be) = (0i64, 1i64, f64::INFINITY);
    for q in 1..=cap {
        let p = (q as f64 * LEFT).round() as i64;
        if (LEFT - p as f64 / q as f64).abs() < be { be = (LEFT - p as f64 / q as f64).abs(); bp = p; bq = q; }
    }
    (bp, bq)
}
fn main() {
    let steps = euclid_steps(1211, 5000); let four = stops(&steps)[1..5].to_vec();
    let leaps = (1..=400).filter(|y| y % 4 == 0 && (y % 100 != 0 || y % 400 == 0)).count() as i64;
    println!("{:<40}365.2422", "a year, in days");
    println!("{:<40}0.2422 = 1211/5000", "the leftover after 365 whole days");
    println!("{:<40}{}", "the whole-number steps, from Euclid", steps.iter().map(|s| s.to_string()).collect::<Vec<_>>().join(", "));
    let mut rows: Vec<(String, i64, i64)> = four.iter().enumerate().map(|(i, &(p, q))| (format!("   stop after step {}", i + 1), p, q)).collect();
    rows.push(("   the Gregorian rule".to_string(), 97, 400));
    for (name, p, q) in &rows { let v = *p as f64 / *q as f64; println!("{:<22}{:>4}/{:<5}{:.6}{:>9.3} days adrift per 400 years", name, p, q, v, (v - LEFT) * 400.0); }
    println!("counting the real rule over 400 years: {} minus {} century skips is {} leap days", 400 / 4, 400 / 4 - leaps, leaps);
    println!("every stop beats every fraction with a bottom up to its own; best up to 400 is {}/{}, not 97/400", best_upto(400).0, best_upto(400).1);
    println!("pi as 3.14159265358979, same trick: {}", stops(&euclid_steps(314159265358979, 100000000000000))[..4].iter().map(|&(p, q)| format!("{}/{}", p, q)).collect::<Vec<_>>().join(", "));
    assert!(four == vec![(1, 4), (7, 29), (8, 33), (31, 128)] && leaps == 97);
    assert!(four.iter().all(|&(p, q)| best_upto(q) == (p, q)) && best_upto(400) == (31, 128));
    assert!((97.0 / 400.0 - LEFT).abs() > 20.0 * (31.0 / 128.0 - LEFT).abs());
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
a year, in days                         365.2422
the leftover after 365 whole days       0.2422 = 1211/5000
the whole-number steps, from Euclid     0, 4, 7, 1, 3, 4, 1, 1, 1, 2
   stop after step 1     1/4    0.250000    3.120 days adrift per 400 years
   stop after step 2     7/29   0.241379   -0.328 days adrift per 400 years
   stop after step 3     8/33   0.242424    0.090 days adrift per 400 years
   stop after step 4    31/128  0.242188   -0.005 days adrift per 400 years
   the Gregorian rule   97/400  0.242500    0.120 days adrift per 400 years
counting the real rule over 400 years: 100 minus 3 century skips is 97 leap days
every stop beats every fraction with a bottom up to its own; best up to 400 is 31/128, not 97/400
pi as 3.14159265358979, same trick: 3/1, 22/7, 333/106, 355/113
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves the rules below for every fraction, the list rule for every number, and checks the worked numbers exactly.

- Each stop, from step 1 on, is the best of its size: no fraction with a bottom number up to its own is closer.
- A number's list of steps ends exactly when the number is a fraction. For an irrational number it never ends.
- From step 2 on, each new top is the step times the previous top, plus the top before that. Bottoms follow the same rule.
- The worked numbers: the steps of 1211/5000, the stops 1/4 to 31/128, the 97 leap days, and the steps of 0.2425.

The decimals, the search over bottom numbers up to 400, and pi are left to the Python and Rust checks.

<details>
<summary>The Lean proof, 331 lines</summary>

```lean
-- Continued fractions: a number's list of steps stops exactly when it is a fraction, the stops build from the steps, and each stop after step 1 or later is as close as any fraction with a bottom number no bigger than its own.
import Mathlib.Algebra.ContinuedFractions.Computation.TerminatesIffRat
import Mathlib.Algebra.ContinuedFractions.ContinuantsRecurrence
import Mathlib.Data.Rat.Floor
import Mathlib.Algebra.Order.Archimedean.Real.Basic
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum

open GenContFract in
theorem cfl_contsAux_int (x : ℚ) : ∀ n : ℕ,
    ((∃ z : ℤ, ((GenContFract.of x).contsAux n).a = z) ∧ (∃ z : ℤ, ((GenContFract.of x).contsAux n).b = z)) ∧
    ((∃ z : ℤ, ((GenContFract.of x).contsAux (n+1)).a = z) ∧ (∃ z : ℤ, ((GenContFract.of x).contsAux (n+1)).b = z)) := by
  intro n
  induction n with
  | zero =>
    refine ⟨⟨⟨1, ?_⟩, ⟨0, ?_⟩⟩, ⟨⟨⌊x⌋, ?_⟩, ⟨1, ?_⟩⟩⟩ <;> simp [contsAux, GenContFract.of_h_eq_floor]
  | succ n ih =>
    refine ⟨ih.2, ?_⟩
    rcases hs : (GenContFract.of x).s.get? n with _ | gp
    · have : (GenContFract.of x).TerminatedAt n := hs
      rw [contsAux_stable_step_of_terminated this]
      exact ih.2
    · rw [contsAux_recurrence hs rfl rfl]
      obtain ⟨ha, ⟨k, hk⟩⟩ := of_partNum_eq_one_and_exists_int_partDen_eq hs
      obtain ⟨⟨⟨a0, h0⟩, ⟨b0, h1⟩⟩, ⟨⟨a1, h2⟩, ⟨b1, h3⟩⟩⟩ := ih
      refine ⟨⟨k * a1 + a0, ?_⟩, ⟨k * b1 + b0, ?_⟩⟩
      · simp [ha, hk, h0, h2]
      · simp [ha, hk, h1, h3]

open GenContFract in
theorem cfl_nums_int (x : ℚ) (n : ℕ) : ∃ z : ℤ, (GenContFract.of x).nums n = z := by
  rw [num_eq_conts_a, nth_cont_eq_succ_nth_contAux]
  exact (cfl_contsAux_int x n).2.1

open GenContFract in
theorem cfl_dens_int (x : ℚ) (n : ℕ) : ∃ z : ℤ, (GenContFract.of x).dens n = z := by
  rw [den_eq_conts_b, nth_cont_eq_succ_nth_contAux]
  exact (cfl_contsAux_int x n).2.2

open GenContFract in
theorem cfl_sign (x : ℚ) (m : ℕ) (ifp : IntFractPair.{0} ℚ)
    (h : IntFractPair.stream x m = some ifp) :
    0 ≤ (-1 : ℚ) ^ m * (x - (GenContFract.of x).convs m) ∧
      (ifp.fr ≠ 0 → 0 < (-1 : ℚ) ^ m * (x - (GenContFract.of x).convs m)) := by
  have key := sub_convs_eq h
  simp only at key
  have hsq : ((-1 : ℚ) ^ m) * (-1) ^ m = 1 := by
    rw [← mul_pow]; simp
  by_cases hfr : ifp.fr = 0
  · have : x - (GenContFract.of x).convs m = 0 := by
      have := key; rw [if_pos hfr] at this; exact this
    rw [this]; simp [hfr]
  · rw [if_neg hfr] at key
    have hpos : 0 < ((GenContFract.of x).contsAux (m + 1)).b * (ifp.fr⁻¹ * ((GenContFract.of x).contsAux (m + 1)).b
        + ((GenContFract.of x).contsAux m).b) := by
      have hor : m = 0 ∨ ¬(GenContFract.of x).TerminatedAt (m - 1) := by
        rcases m with _ | m
        · simp
        · have : IntFractPair.stream x (m + 1) ≠ none := by simp [h]
          have : ¬(GenContFract.of x).TerminatedAt m :=
            (not_congr of_terminatedAt_n_iff_succ_nth_intFractPair_stream_eq_none).2 this
          exact Or.inr this
      have pB_ineq : (Nat.fib m : ℚ) ≤ ((GenContFract.of x).contsAux m).b := by
        apply fib_le_of_contsAux_b
        rcases hor with h0 | h0
        · left; omega
        · by_cases hm : m ≤ 1
          · left; exact hm
          · right; exact mt (terminated_stable (by omega)) h0
      have B_ineq : (Nat.fib (m + 1) : ℚ) ≤ ((GenContFract.of x).contsAux (m + 1)).b := by
        apply fib_le_of_contsAux_b
        rcases hor with h0 | h0
        · left; omega
        · by_cases hm : m + 1 ≤ 1
          · left; exact hm
          · right; simpa using h0
      have hB : 0 < ((GenContFract.of x).contsAux (m + 1)).b :=
        B_ineq.trans_lt' (by exact_mod_cast Nat.fib_pos.2 (Nat.succ_pos m))
      have hpB : 0 ≤ ((GenContFract.of x).contsAux m).b := (Nat.cast_nonneg _).trans pB_ineq
      have hfr0 : 0 < ifp.fr :=
        (Ne.symm hfr).lt_of_le (IntFractPair.nth_stream_fr_nonneg h)
      positivity
    have e : (-1 : ℚ) ^ m * (x - (GenContFract.of x).convs m) =
        1 / (((GenContFract.of x).contsAux (m + 1)).b * (ifp.fr⁻¹ * ((GenContFract.of x).contsAux (m + 1)).b
        + ((GenContFract.of x).contsAux m).b)) := by
      rw [key, ← mul_div_assoc, hsq]
    have e2 : 0 < (-1 : ℚ) ^ m * (x - (GenContFract.of x).convs m) := by rw [e]; positivity
    exact ⟨e2.le, fun _ => e2⟩


theorem cfl_key (x : ℚ) (P0 Q0 P1 Q1 a b ε : ℤ) (hε : ε * ε = 1)
    (hdet : P0 * Q1 - Q0 * P1 = ε) (hQ0 : 0 < Q0) (hQ : Q0 < Q1)
    (h0 : (ε : ℚ) * (Q0 * x - P0) ≤ 0) (h1 : 0 ≤ (ε : ℚ) * (Q1 * x - P1))
    (hb : 0 < b) (hbQ : b < Q1) : |(Q0 : ℚ) * x - P0| ≤ |(b : ℚ) * x - a| := by
  obtain ⟨u, v, hua, hvb⟩ : ∃ u v : ℤ, a = u * P0 + v * P1 ∧ b = u * Q0 + v * Q1 := by
    refine ⟨ε * (a * Q1 - b * P1), ε * (P0 * b - Q0 * a), ?_, ?_⟩
    · linear_combination (-(ε * a)) * hdet + (-a) * hε
    · linear_combination (-(ε * b)) * hdet + (-b) * hε
  have hS : (b : ℚ) * x - a = u * (Q0 * x - P0) + v * (Q1 * x - P1) := by
    have e1 : (a : ℚ) = u * P0 + v * P1 := by exact_mod_cast hua
    have e2 : (b : ℚ) = u * Q0 + v * Q1 := by exact_mod_cast hvb
    rw [e1, e2]; ring
  have hcase : (0 < u ∧ v < 0) ∨ (u < 0 ∧ 0 < v) ∨ (0 < u ∧ v = 0) := by
    rcases lt_trichotomy u 0 with hu0 | hu0 | hu0 <;> rcases lt_trichotomy v 0 with hv0 | hv0 | hv0
    · exfalso; nlinarith
    · exfalso; nlinarith
    · right; left; exact ⟨hu0, hv0⟩
    · exfalso; rw [hu0] at hvb; nlinarith
    · exfalso; rw [hu0, hv0] at hvb; omega
    · exfalso; rw [hu0] at hvb; nlinarith
    · left; exact ⟨hu0, hv0⟩
    · right; right; exact ⟨hu0, hv0⟩
    · exfalso; nlinarith
  rw [hS]
  have hε' : ε = 1 ∨ ε = -1 := by
    have : ε ∣ 1 := ⟨ε, hε.symm⟩
    exact Int.isUnit_iff.mp (isUnit_of_dvd_one this)
  set D0 : ℚ := Q0 * x - P0
  set D1 : ℚ := Q1 * x - P1
  rcases hcase with ⟨hu1, hv1⟩ | ⟨hu1, hv1⟩ | ⟨hu1, hv1⟩
  · have hu1' : (1 : ℚ) ≤ u := by exact_mod_cast hu1
    have hv1' : (v : ℚ) ≤ -1 := by exact_mod_cast (by omega : v ≤ -1)
    rcases hε' with rfl | rfl
    · have : D0 ≤ 0 := by simpa using h0
      have : 0 ≤ D1 := by simpa using h1
      rw [abs_of_nonpos (by assumption)]
      rw [abs_of_nonpos (by nlinarith)]
      nlinarith
    · have : 0 ≤ D0 := by simpa using h0
      have : D1 ≤ 0 := by simpa using h1
      rw [abs_of_nonneg (by assumption)]
      rw [abs_of_nonneg (by nlinarith)]
      nlinarith
  · have hu1' : (u : ℚ) ≤ -1 := by exact_mod_cast (by omega : u ≤ -1)
    have hv1' : (1 : ℚ) ≤ v := by exact_mod_cast hv1
    rcases hε' with rfl | rfl
    · have : D0 ≤ 0 := by simpa using h0
      have : 0 ≤ D1 := by simpa using h1
      rw [abs_of_nonpos (by assumption)]
      rw [abs_of_nonneg (by nlinarith)]
      nlinarith
    · have : 0 ≤ D0 := by simpa using h0
      have : D1 ≤ 0 := by simpa using h1
      rw [abs_of_nonneg (by assumption)]
      rw [abs_of_nonpos (by nlinarith)]
      nlinarith
  · rw [hv1] at hvb ⊢
    have hu1' : (1 : ℚ) ≤ u := by exact_mod_cast hu1
    simp only [Int.cast_zero, zero_mul, add_zero]
    rw [abs_mul, abs_of_pos (by linarith : (0:ℚ) < u)]
    nlinarith [abs_nonneg D0]

#print axioms cfl_contsAux_int
#print axioms cfl_nums_int
#print axioms cfl_dens_int
#print axioms cfl_sign
#print axioms cfl_key

/-- Each stop is the best of its size. Take a fraction x and run Euclid's algorithm on it, which is
Mathlib's continued fraction `GenContFract.of x`. Cut the list short after step n, for n = 1, 2, 3,
and so on; the stop is `convs n` and its bottom number is `dens n`. Then no fraction a / b with a
bottom number b from 1 up to that bottom number is closer to x than the stop is. -/
theorem stop_is_closest_fraction_of_its_size (x : ℚ) (n : ℕ) (hn : 1 ≤ n) (a : ℤ) (b : ℕ)
    (hb : 0 < b) (hbq : (b : ℚ) ≤ (GenContFract.of x).dens n) :
    |x - (GenContFract.of x).convs n| ≤ |x - (a : ℚ) / b| := by
  by_cases ht : (GenContFract.of x).TerminatedAt n
  · have := GenContFract.of_correctness_of_terminatedAt ht
    rw [← this]; simp
  obtain ⟨m, rfl⟩ : ∃ m, n = m + 1 := ⟨n - 1, by omega⟩
  -- stream facts
  have hne : GenContFract.IntFractPair.stream x (m + 1 + 1) ≠ none := fun h =>
    ht (GenContFract.of_terminatedAt_n_iff_succ_nth_intFractPair_stream_eq_none.2 h)
  obtain ⟨ifp1, hs1⟩ := Option.ne_none_iff_exists'.1 hne
  obtain ⟨ifp0, hs0, hfr0, -⟩ := GenContFract.IntFractPair.succ_nth_stream_eq_some_iff.1 hs1
  have S0 := (cfl_sign x (m + 1) ifp0 hs0).2 hfr0
  have S1 := (cfl_sign x (m + 1 + 1) ifp1 hs1).1
  -- integers
  obtain ⟨P0, hP0⟩ := cfl_nums_int x (m + 1)
  obtain ⟨P1, hP1⟩ := cfl_nums_int x (m + 1 + 1)
  obtain ⟨Q0, hQ0⟩ := cfl_dens_int x (m + 1)
  obtain ⟨Q1, hQ1⟩ := cfl_dens_int x (m + 1 + 1)
  -- positivity and growth of denominators
  have hnt : ¬(GenContFract.of x).TerminatedAt (m - 1) := mt (GenContFract.terminated_stable (by omega)) ht
  have hdm : (1 : ℚ) ≤ (GenContFract.of x).dens m := by
    have := GenContFract.succ_nth_fib_le_of_nth_den (v := x) (n := m)
      (by rcases m with _ | m
          · exact Or.inl rfl
          · exact Or.inr (mt (GenContFract.terminated_stable (by omega)) ht))
    have h1 : (1 : ℚ) ≤ (Nat.fib (m + 1) : ℚ) := by exact_mod_cast Nat.fib_pos.2 (Nat.succ_pos m)
    linarith
  obtain ⟨gp, hgp⟩ : ∃ gp, (GenContFract.of x).s.get? (m + 1) = some gp :=
    Option.ne_none_iff_exists'.1 ht
  have hga : gp.a = 1 := (GenContFract.of_partNum_eq_one_and_exists_int_partDen_eq hgp).left
  have hgb : (1 : ℚ) ≤ gp.b :=
    GenContFract.of_one_le_get?_partDen (GenContFract.partDen_eq_s_b hgp)
  have hrec := GenContFract.dens_recurrence hgp (rfl : (GenContFract.of x).dens m = _) rfl
  rw [hga] at hrec
  have hQ0pos : (1 : ℚ) ≤ (GenContFract.of x).dens (m + 1) := by
    have := GenContFract.of_den_mono (v := x) (n := m)
    linarith
  have hlt : (GenContFract.of x).dens (m + 1) < (GenContFract.of x).dens (m + 1 + 1) := by
    rw [hrec]; nlinarith
  -- determinant
  have hdet := (SimpContFract.of x).determinant (n := m + 1) ht
  have hdet' : (GenContFract.of x).nums (m + 1) * (GenContFract.of x).dens (m + 1 + 1) -
      (GenContFract.of x).dens (m + 1) * (GenContFract.of x).nums (m + 1 + 1) =
      (-1) ^ (m + 1 + 1) := hdet
  -- apply key
  have hP0' : (P0 : ℚ) = (GenContFract.of x).nums (m + 1) := hP0.symm
  have hP1' : (P1 : ℚ) = (GenContFract.of x).nums (m + 1 + 1) := hP1.symm
  have hQ0' : (Q0 : ℚ) = (GenContFract.of x).dens (m + 1) := hQ0.symm
  have hQ1' : (Q1 : ℚ) = (GenContFract.of x).dens (m + 1 + 1) := hQ1.symm
  have hQ0z : 0 < Q0 := by
    have : (1 : ℚ) ≤ Q0 := by rw [hQ0']; exact hQ0pos
    exact_mod_cast this
  have hQlt : Q0 < Q1 := by
    have : (Q0 : ℚ) < Q1 := by rw [hQ0', hQ1']; exact hlt
    exact_mod_cast this
  have hbz : (b : ℤ) < Q1 := by
    have : (b : ℚ) < Q1 := by linarith
    exact_mod_cast this
  have hbQ0 : (b : ℚ) ≤ Q0 := by rw [hQ0']; exact hbq
  have hdetZ : P0 * Q1 - Q0 * P1 = (-1 : ℤ) ^ (m + 1 + 1) := by
    have : (P0 : ℚ) * Q1 - Q0 * P1 = (-1 : ℚ) ^ (m + 1 + 1) := by
      rw [hP0', hP1', hQ0', hQ1']; exact hdet'
    exact_mod_cast this
  have hεε : ((-1 : ℤ) ^ (m + 1 + 1)) * (-1) ^ (m + 1 + 1) = 1 := by
    rw [← mul_pow]; simp
  have hεq : (((-1 : ℤ) ^ (m + 1 + 1) : ℤ) : ℚ) = -(-1 : ℚ) ^ (m + 1) := by
    push_cast; ring
  have hc0 : (GenContFract.of x).convs (m + 1) = (P0 : ℚ) / Q0 := by
    show (GenContFract.of x).nums (m + 1) / (GenContFract.of x).dens (m + 1) = _
    rw [hP0', hQ0']
  have hc1 : (GenContFract.of x).convs (m + 1 + 1) = (P1 : ℚ) / Q1 := by
    show (GenContFract.of x).nums (m + 1 + 1) / (GenContFract.of x).dens (m + 1 + 1) = _
    rw [hP1', hQ1']
  rw [hc0] at S0
  rw [hc1] at S1
  have hQ0q : (0 : ℚ) < Q0 := by exact_mod_cast hQ0z
  have hQ1q : (0 : ℚ) < Q1 := by exact_mod_cast hQ0z.trans hQlt
  have h0 : (((-1 : ℤ) ^ (m + 1 + 1) : ℤ) : ℚ) * (Q0 * x - P0) ≤ 0 := by
    have e : (((-1 : ℤ) ^ (m + 1 + 1) : ℤ) : ℚ) * (Q0 * x - P0) =
        -(((-1 : ℚ) ^ (m + 1) * (x - P0 / Q0)) * Q0) := by
      rw [hεq]; field_simp
    rw [e]
    have := mul_pos S0 hQ0q
    linarith
  have h1 : 0 ≤ (((-1 : ℤ) ^ (m + 1 + 1) : ℤ) : ℚ) * (Q1 * x - P1) := by
    have e : (((-1 : ℤ) ^ (m + 1 + 1) : ℤ) : ℚ) * (Q1 * x - P1) =
        ((-1 : ℚ) ^ (m + 1 + 1) * (x - P1 / Q1)) * Q1 := by
      rw [hεq]; field_simp; ring
    rw [e]
    exact mul_nonneg S1 hQ1q.le
  have hk := cfl_key x P0 Q0 P1 Q1 a b _ hεε hdetZ hQ0z hQlt h0 h1 (by exact_mod_cast hb) hbz
  have hbq' : (0 : ℚ) < b := by exact_mod_cast hb
  have eL : |x - (P0 : ℚ) / Q0| = |(Q0 : ℚ) * x - P0| / Q0 := by
    rw [← abs_of_pos hQ0q, ← abs_div, abs_of_pos hQ0q]
    congr 1; field_simp
  have eR : |x - (a : ℚ) / b| = |(b : ℚ) * x - a| / b := by
    rw [← abs_of_pos hbq', ← abs_div, abs_of_pos hbq']
    congr 1; field_simp
  have hk' : |(Q0 : ℚ) * x - P0| ≤ |(b : ℚ) * x - a| := by simpa using hk
  rw [hc0, eL, eR, div_le_div_iff₀ hQ0q hbq']
  nlinarith [abs_nonneg ((Q0 : ℚ) * x - P0), abs_nonneg ((b : ℚ) * x - a)]

/-- The list stops exactly for fractions. Euclid's steps on a number run out after finitely many
steps when the number is a fraction, and go on forever when it is irrational. -/
theorem steps_stop_iff_number_is_a_fraction (x : ℝ) :
    (GenContFract.of x).Terminates ↔ ∃ q : ℚ, x = (q : ℝ) := by
  exact GenContFract.terminates_iff_rat x

/-- The stops build themselves from the steps: if the next step is s, the new top number is
s times the previous top plus the top before that, and the bottom numbers follow the same rule. -/
theorem stops_build_from_steps (x : ℚ) (n : ℕ) (s : ℚ)
    (hs : (GenContFract.of x).partDens.get? (n + 1) = some s) :
    (GenContFract.of x).nums (n + 2) =
        s * (GenContFract.of x).nums (n + 1) + (GenContFract.of x).nums n ∧
      (GenContFract.of x).dens (n + 2) =
        s * (GenContFract.of x).dens (n + 1) + (GenContFract.of x).dens n := by
  obtain ⟨gp, hgp, rfl⟩ := GenContFract.exists_s_b_of_partDen hs
  have ha : gp.a = 1 := (GenContFract.of_partNum_eq_one_and_exists_int_partDen_eq hgp).left
  constructor
  · rw [GenContFract.nums_recurrence hgp rfl rfl, ha]; ring
  · rw [GenContFract.dens_recurrence hgp rfl rfl, ha]; ring

-- The leftover 0.2422 is 2422/10000, which cuts down to 1211/5000.
example : (2422 : ℚ) / 10000 = 1211 / 5000 := by norm_num
-- Euclid's algorithm on 1211 and 5000: whole times 0, 4, 7, 1, 3, 4, 1, 1, 1, 2, then remainder 0.
example : 1211 = 0 * 5000 + 1211 ∧ 5000 = 4 * 1211 + 156 ∧ 1211 = 7 * 156 + 119 ∧
    156 = 1 * 119 + 37 ∧ 119 = 3 * 37 + 8 ∧ 37 = 4 * 8 + 5 ∧ 8 = 1 * 5 + 3 ∧ 5 = 1 * 3 + 2 ∧
    3 = 1 * 2 + 1 ∧ 2 = 2 * 1 + 0 := by decide
-- The same steps from Mathlib's continued fraction of 1211/5000: whole part 0, then the list.
example : (GenContFract.of (1211 / 5000 : ℚ)).h = 0 ∧
    (List.range 10).map (fun n => (GenContFract.of (1211 / 5000 : ℚ)).partDens.get? n) =
      [some 4, some 7, some 1, some 3, some 4, some 1, some 1, some 1, some 2, none] := by
  decide +kernel
-- The stops after steps 1 to 4: 1/4, 7/29, 8/33, 31/128.
example : (GenContFract.of (1211 / 5000 : ℚ)).convs 1 = 1 / 4 ∧
    (GenContFract.of (1211 / 5000 : ℚ)).convs 2 = 7 / 29 ∧
    (GenContFract.of (1211 / 5000 : ℚ)).convs 3 = 8 / 33 ∧
    (GenContFract.of (1211 / 5000 : ℚ)).convs 4 = 31 / 128 := by
  decide +kernel
-- The stop 31/128 has bottom number 128, so the first theorem covers every bottom up to 128.
example : (GenContFract.of (1211 / 5000 : ℚ)).dens 4 = 128 := by decide +kernel
-- From 7/29 and the step 1: 8 = 1 × 7 + 1, 33 = 1 × 29 + 4.
example : 8 = 1 * 7 + 1 ∧ 33 = 1 * 29 + 4 := by decide
-- Counting the real rule over 400 years gives 97 leap days: 100 multiples of 4, 3 centuries skipped.
example : ((Finset.Icc 1 400).filter (fun y => y % 4 = 0)).card = 100 ∧
    ((Finset.Icc 1 400).filter (fun y => y % 100 = 0 ∧ y % 400 ≠ 0)).card = 3 ∧
    ((Finset.Icc 1 400).filter (fun y => y % 4 = 0 ∧ (y % 100 ≠ 0 ∨ y % 400 = 0))).card = 97 := by
  decide
-- Drift over 400 years: 1/4 is 3.120 days too many, 97/400 is 0.120 days too many.
example : ((1 : ℚ) / 4 - 1211 / 5000) * 400 = 78 / 25 ∧
    ((97 : ℚ) / 400 - 1211 / 5000) * 400 = 3 / 25 := by norm_num
-- 97/400 is not best of its size: 31/128 is more than 20 times closer to 0.2422.
example : |(97 : ℚ) / 400 - 1211 / 5000| > 20 * |(31 : ℚ) / 128 - 1211 / 5000| := by norm_num
-- The Gregorian year 0.2425 = 97/400: steps 0, 4, 8, 12, and the last stop is 97/400 exactly.
example : (GenContFract.of (97 / 400 : ℚ)).h = 0 ∧
    (List.range 4).map (fun n => (GenContFract.of (97 / 400 : ℚ)).partDens.get? n) =
      [some 4, some 8, some 12, none] ∧
    (GenContFract.of (97 / 400 : ℚ)).convs 3 = 97 / 400 := by
  decide +kernel

#print axioms stop_is_closest_fraction_of_its_size
#print axioms steps_stop_iff_number_is_a_fraction
#print axioms stops_build_from_steps
```

</details>

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'cfl_contsAux_int' depends on axioms: [propext, Classical.choice, Quot.sound]
'cfl_nums_int' depends on axioms: [propext, Classical.choice, Quot.sound]
'cfl_dens_int' depends on axioms: [propext, Classical.choice, Quot.sound]
'cfl_sign' depends on axioms: [propext, Classical.choice, Quot.sound]
'cfl_key' depends on axioms: [propext, Classical.choice, Quot.sound]
'stop_is_closest_fraction_of_its_size' depends on axioms: [propext, Classical.choice, Quot.sound]
'steps_stop_iff_number_is_a_fraction' depends on axioms: [propext, Classical.choice, Quot.sound]
'stops_build_from_steps' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it. The asserts are pinned to the real year, so expect one to fire.
> - **Feed it the Gregorian year.** Change 1211/5000 to 2425/10000, which is 0.2425. The steps come out 0, 4, 8, 12, the last stop is 97/400 exactly, drift zero.
> - **Widen the search.** Change the 400 fed to `best_upto` to 545, three places, not the 400-year figures. The winner jumps to 132/545, the next stop on the list, and the assert fires.

---

## The usual mistake

> [!warning]
> **Thinking a bigger bottom number always means a better fraction.** 97/400 has a bigger bottom number than 31/128 and sits much further from the truth. Only the stops are guaranteed best of their size.
>
> - Reading the step list 0, 4, 7, 1, 3 as the answer. It is the recipe.
> - Expecting the drift to shrink in a straight line: it goes 3.120, then -0.328, then 0.090.
> - Assuming the calendar picked the best fraction going. It picked 97/400 for the round centuries, at 0.120 days of drift.

---

## Where you meet it in real life

- **The calendar you are using now.** 97 leap days in 400 years, century skips included. The cycles it sets up drive [Day of the week for any date](../05-Check%20Digits%2C%20Calendars%20and%20Cycles/03-day-of-the-week.md) and [When cycles meet again](../05-Check%20Digits%2C%20Calendars%20and%20Cycles/04-cycles-that-realign.md).
- **Cutting gears, tuning instruments.** The bottom number is teeth to cut or notes in a scale, so you take the cheapest stop that works.
- **Pi in your head.** The same steps on 3.14159265358979 give 3/1, 22/7, 333/106, 355/113. The last is closer to pi than any fraction its size — the fourth stop.

> **Say it back**
> A year is 365.2422 days and the 0.2422 has to go somewhere. Euclid's algorithm on it returns whole numbers; stack them into nested fractions and the leftover is exact. Cut it short and you get a stop: 1/4, 7/29, 8/33, 31/128, each the closest fraction with a bottom number that small. 1/4 is the Julian calendar, 3.120 days adrift per 400 years. The Gregorian 97/400 is not a stop but a rounder neighbour of 8/33, 0.120 days adrift.

---

## What this builds on

- [Euclid's algorithm](../02-Greatest%20Common%20Divisor%20and%20Euclid%27s%20Algorithm/03-euclidean-algorithm.md): the quotients it throws away chasing a gcd are the steps here.
- [Fractions](../../01-Foundations/01-Everyday%20Arithmetic/07-fractions.md): top over bottom, and cutting 2422/10000 down.
- [Decimals](../../01-Foundations/01-Everyday%20Arithmetic/08-decimals.md): reading 365.2422 as whole days plus a leftover.

## Where this goes next

- [Pell's equation](../../03-Algebra/10-For%20the%20Curious/04-pell-equation-and-root-two.md): the same steps on root 2, where every second stop solves an equation in whole numbers.

The rest of the shelf: [Pythagorean triples](01-pythagorean-triples.md), [Perfect numbers and Mersenne primes](02-perfect-numbers-and-mersenne.md), [How primes thin out](03-how-primes-thin-out.md), [Goldbach, twin primes and friends](04-goldbach-and-open-problems.md).

This card leaves one question open: why does the list for a square root repeat forever?

---

## Sources

Verified 2026-11-11: every link below resolves to the publisher's page.

- Khinchin, A. Ya. *Continued Fractions*. Dover, 1997. [Publisher page](https://store.doverpublications.com/products/9780486696300). The proof that each stop is best of its size.
- Reingold, Edward M., and Nachum Dershowitz. *Calendrical Calculations: The Ultimate Edition*, 4th ed. Cambridge University Press, 2018. [doi:10.1017/9781107415058](https://doi.org/10.1017/9781107415058). Year lengths, leap rules.
- United States Naval Observatory. *Introduction to Calendars*. [aa.usno.navy.mil](https://aa.usno.navy.mil/faq/calendars). The Julian and Gregorian leap rules.
