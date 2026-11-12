# The Chinese remainder theorem: three rotas, one day — day numbers on cycles that share no factor pin down one day, and how to rebuild it

[Syllabus](../../../SYLLABUS.md) → [Number theory](../README.md) → [Clock Arithmetic](../README.md#s03) → The Chinese remainder theorem

---

## General Overview

One morning a depot resets all its rotas at once. Call it day 0. Cleaning runs a 3-day cycle: day 0, day 1, day 2, back to day 0. Deliveries run a 5-day cycle. The week runs 7 days.

Today the board reads cleaning day 2, deliveries day 3, week day 2. Nobody wrote the date. How many days since the reset?

Count up. Cleaning alone allows day 2, day 5, day 8, on for ever. Deliveries allow day 3, day 8, day 13. 8 is the first on both, then 23, 38, one every 15 days. Add the week and one day in 105 survives: **day 23**.

The rotas line up again only after 3 × 5 × 7 = 105 days. So the answer is not a date but a day of a 105-day cycle: 23, then 128.

**Cycle lengths sharing no factor act as independent dials: the three day numbers pin down one day in 105, and that day can be built rather than hunted for.**

**What kind of fact this is:** a theorem, proved on this card in Why it works.

### The picture: how many rotas each day matches

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "How many of the three day numbers each day matches"
    x-axis "Days since the reset" 0 --> 29
    y-axis "Rotas matched" 0 --> 3
    bar [0, 0, 2, 1, 0, 1, 0, 0, 2, 1, 0, 1, 0, 1, 1, 0, 1, 1, 1, 0, 1, 0, 0, 3, 0, 0, 1, 0, 1, 1]
```

One match is common. Two at day 2 and day 8. Three at day 23, then not for 105 days.

---

## The formula

The answer, read off against each rota:

**23 = 7 × 3 + 2**   and   **23 = 4 × 5 + 3**   and   **23 = 3 × 7 + 2**

**Read it aloud:** 23 days is seven 3-day cycles and 2 over, four 5-day cycles and 3 over, three weeks and 2 over.

In the shelf's shorthand ([Congruence](01-congruence-mod-n.md)), "≡ 2 (mod 3)" means "leaves 2 over on the 3-cycle": 23 ≡ 2 (mod 3), 23 ≡ 3 (mod 5), 23 ≡ 2 (mod 7).

Building it takes two folds, one modular inverse each. The first turns the 3-day and 5-day rotas into one: day 8 of a 15-day cycle. The second folds in the week: day 23 of 105.

| Piece | Plain meaning | Here |
| --- | --- | --- |
| the cycle length (the modulus) | days before repeating | 3, 5, 7 |
| the day number (the remainder) | where a cycle stands | 2, 3, 2 |
| coprime | no two lengths share a factor | 3, 5, 7 do not |
| the combined cycle | the lengths multiplied | 105 |
| the inverse | what undoes a multiplier | 2 undoes 3 on the 5-cycle |

### When it holds

- **No two cycle lengths share a factor.** Each fold needs an undoer, and only then does one exist. Swap the week for a 6-day cycle: readings that agree fit day 8 in 30, readings that clash fit no day.
- **Every rota counts from the same reset.** If one rota reset on another day, its day number counts from a different day 0, and the fold lands on the wrong day.
- **The count is under 105 days.** Past that, the answer is not one number: 23 and 128 read the same.

---

## Why it works

### Step 0: one rota leaves an evenly spaced list

Cleaning day 2 means the count is 2 plus a whole number of 3s. That is all one rota says.

### Step 1: pick the number of 3s so the second rota fits

Each 3 pushes the delivery rota on by 3 too. It starts at day 2 and must reach day 3, one further on. So the number of 3s, times 3, must come to 1 on the 5-cycle.

Because 3 and 5 share no factor ([Coprime numbers](../02-Greatest%20Common%20Divisor%20and%20Euclid%27s%20Algorithm/05-coprime-numbers.md)), multiplying by 3 can be undone there ([The modular inverse](04-modular-inverse.md)): the undoer is 2, since 3 × 2 = 6, one past 5. So the number of 3s is 2, and 2 + 3 × 2 = 8. Any other day fitting both is 8 plus some 15s.

### Step 2: fold the week in with the same move

A 15-cycle and a 7-cycle now, again sharing no factor. Each 15 pushes the week on by 1, since 15 is two weeks and a day over. Day 8 sits on week day 1, we want day 2, so one step: 8 + 15 = 23. The scripts get there by subtracting: 2 − 8 = −6, which is 1 forward on a 7-cycle ([Negative numbers](../../01-Foundations/01-Everyday%20Arithmetic/06-negative-numbers.md)).

### Step 3: why exactly one day fits

Say two days both fit. Their difference is a whole number of 3s, of 5s and of 7s. Divisible by 3 and by 5, which share no factor, means divisible by 15 — for coprime lengths the smallest number both divide is their product ([Least common multiple](../02-Greatest%20Common%20Divisor%20and%20Euclid%27s%20Algorithm/02-lcm.md)). Again with the 7: divisible by 105. So the two are one day of the 105-day cycle. And 105 days give 105 readings, no two alike, so every reading has its day.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| fold the 5-day rota in | a 3-day step leaves 3 on the 5-cycle; 3 is undone by 2 | steps: 2 |
| the two as one | 2 + 3 × 2 | day 8 of 15 |
| fold the week in | 15 leaves 1 on the 7-cycle, undone by 1 | steps: 1 |
| all three as one | 8 + 15 × 1 | **day 23 of 105** |
| scan all 105 days | one fits; the next is | 23, 128 |

Today is 23 days after the reset, or 128, or any day 105 further on. No board tells them apart.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| A 6-day cycle for the week | the fold jams | 6 and 3 share a factor: no undoer |
| Adding the day numbers | 7 | day 1 of the 3-day cycle, not day 2 |

---

## Code, from first principles, and it actually runs

Nothing is imported. Road one folds two rotas at a time; road two tries all 105 days.

### Python

```python
# The Chinese remainder theorem -- the check behind the card.  Nothing is
# imported.  Three rotas from a shared reset: day 2 of a 3-day cycle, day 3 of
# a 5-day cycle, day 2 of the 7-day week.  Road one folds two cycles at a time
# with an inverse; road two scans all 105 days of the combined cycle.
CYCLES, DAYS = [3, 5, 7], [2, 3, 2]
def inverse(a, n):                  # the number that undoes multiplying by a
    return next(t for t in range(n) if (a * t) % n == 1)
def fold(day1, cycle1, day2, cycle2):                 # road one: two into one
    inv = inverse(cycle1 % cycle2, cycle2)
    steps = ((day2 - day1) * inv) % cycle2
    print(f"on the {cycle2}-cycle: {cycle1} leaves {cycle1 % cycle2}, undone by {inv}; steps: {steps}")
    return (day1 + cycle1 * steps) % (cycle1 * cycle2)
def fits(cycles, days, span):       # road two: try every day in the span
    return [d for d in range(span) if all(d % c == r for c, r in zip(cycles, days))]
x, m = DAYS[0], CYCLES[0]
for c, r in zip(CYCLES[1:], DAYS[1:]):
    x, m = fold(x, m, r, c), m * c
    print(f"combined so far: day {x} of the {m}-day cycle")
print("by hand: " + ";  ".join(f"{x} = {x // c} x {c} + {x % c}" for c in CYCLES))
print(f"{'by scanning all 105 days':<32}{str(fits(CYCLES, DAYS, 105)):>10}")
print(f"{'the next one, two cycles out':<32}{str(fits(CYCLES, DAYS, 210)):>10}")
counts = [sum(d % c == r for c, r in zip(CYCLES, DAYS)) for d in range(30)]
print("rotas matched, days 0 to 29: " + " ".join(str(n) for n in counts))
print(f"adding the day numbers: {' + '.join(str(d) for d in DAYS)} = {sum(DAYS)}, which is day {sum(DAYS) % 3} of the 3-day cycle")
agree, clash = fits([3, 5, 6], [2, 3, 2], 30), fits([3, 5, 6], [2, 3, 1], 30)
print(f"a 6-day cycle in place of the 7: readings agreeing fit {agree} in 30; readings clashing, {clash}")
assert x == 23 and m == 105 and fits(CYCLES, DAYS, 105) == [23]
assert 23 % 3 == 2 and 23 % 5 == 3 and 23 % 7 == 2 and 23 + 105 == 128
assert counts[23] == 3 and max(counts[:23]) == 2 and agree == [8] and clash == []
print("ALL CHECKS PASS")
```

**Ran 2026-09-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
on the 5-cycle: 3 leaves 3, undone by 2; steps: 2
combined so far: day 8 of the 15-day cycle
on the 7-cycle: 15 leaves 1, undone by 1; steps: 1
combined so far: day 23 of the 105-day cycle
by hand: 23 = 7 x 3 + 2;  23 = 4 x 5 + 3;  23 = 3 x 7 + 2
by scanning all 105 days              [23]
the next one, two cycles out     [23, 128]
rotas matched, days 0 to 29: 0 0 2 1 0 1 0 0 2 1 0 1 0 1 1 0 1 1 1 0 1 0 0 3 0 0 1 0 1 1
adding the day numbers: 2 + 3 + 2 = 7, which is day 1 of the 3-day cycle
a 6-day cycle in place of the 7: readings agreeing fit [8] in 30; readings clashing, []
ALL CHECKS PASS
```

### Rust

Same numbers, same labels.

```rust
// The Chinese remainder theorem -- the same check as the Python twin, in Rust.  No
// crates.  Three rotas from a shared reset: day 2 of a 3-day cycle, day 3 of a 5-day
// cycle, day 2 of the 7-day week.  Road one folds two cycles at a time; road two scans.
const CYCLES: [i64; 3] = [3, 5, 7];
const DAYS: [i64; 3] = [2, 3, 2];
fn inverse(a: i64, n: i64) -> i64 { (0..n).find(|t| (a * t) % n == 1).unwrap() }   // undoes multiplying by a
fn show(v: &[i64]) -> String {      // "[23, 128]", the way Python prints a list
    format!("[{}]", v.iter().map(|x| x.to_string()).collect::<Vec<String>>().join(", "))
}
fn fold(day1: i64, cycle1: i64, day2: i64, cycle2: i64) -> i64 {   // road one: two into one
    let inv = inverse(cycle1 % cycle2, cycle2);
    let steps = ((day2 - day1) * inv).rem_euclid(cycle2);
    println!("on the {}-cycle: {} leaves {}, undone by {}; steps: {}", cycle2, cycle1, cycle1 % cycle2, inv, steps);
    (day1 + cycle1 * steps).rem_euclid(cycle1 * cycle2)
}
fn fits(cycles: &[i64], days: &[i64], span: i64) -> Vec<i64> {     // road two: try every day
    (0..span).filter(|&d| (0..cycles.len()).all(|i| d % cycles[i] == days[i])).collect()
}
fn main() {
    let (mut x, mut m) = (DAYS[0], CYCLES[0]);
    for i in 1..3 {
        x = fold(x, m, DAYS[i], CYCLES[i]);
        m *= CYCLES[i];
        println!("combined so far: day {} of the {}-day cycle", x, m);
    }
    let hand: Vec<String> = CYCLES.iter().map(|c| format!("{} = {} x {} + {}", x, x / c, c, x % c)).collect();
    println!("by hand: {}", hand.join(";  "));
    println!("{:<32}{:>10}", "by scanning all 105 days", show(&fits(&CYCLES, &DAYS, 105)));
    println!("{:<32}{:>10}", "the next one, two cycles out", show(&fits(&CYCLES, &DAYS, 210)));
    let counts: Vec<i64> = (0..30i64).map(|d| (0..3).filter(|&i| d % CYCLES[i] == DAYS[i]).count() as i64).collect();
    println!("rotas matched, days 0 to 29: {}", counts.iter().map(|n| n.to_string()).collect::<Vec<String>>().join(" "));
    let sum: i64 = DAYS.iter().sum();
    println!("adding the day numbers: {} = {}, which is day {} of the 3-day cycle", DAYS.iter().map(|d| d.to_string()).collect::<Vec<String>>().join(" + "), sum, sum % 3);
    let (agree, clash) = (fits(&[3, 5, 6], &[2, 3, 2], 30), fits(&[3, 5, 6], &[2, 3, 1], 30));
    println!("a 6-day cycle in place of the 7: readings agreeing fit {} in 30; readings clashing, {}", show(&agree), show(&clash));
    assert!(x == 23 && m == 105 && fits(&CYCLES, &DAYS, 105) == vec![23]);
    assert!(23 % 3 == 2 && 23 % 5 == 3 && 23 % 7 == 2 && 23 + 105 == 128);
    assert!(counts[23] == 3 && counts[..23].iter().max() == Some(&2) && agree == vec![8] && clash.is_empty());
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
on the 5-cycle: 3 leaves 3, undone by 2; steps: 2
combined so far: day 8 of the 15-day cycle
on the 7-cycle: 15 leaves 1, undone by 1; steps: 1
combined so far: day 23 of the 105-day cycle
by hand: 23 = 7 x 3 + 2;  23 = 4 x 5 + 3;  23 = 3 x 7 + 2
by scanning all 105 days              [23]
the next one, two cycles out     [23, 128]
rotas matched, days 0 to 29: 0 0 2 1 0 1 0 0 2 1 0 1 0 1 1 0 1 1 1 0 1 0 0 3 0 0 1 0 1 1
adding the day numbers: 2 + 3 + 2 = 7, which is day 1 of the 3-day cycle
a 6-day cycle in place of the 7: readings agreeing fit [8] in 30; readings clashing, []
ALL CHECKS PASS
```

Both outputs match line for line.

### Lean

Lean proves the card's three facts for any number of rotas, not just 3, 5 and 7.

- When no two cycle lengths share a factor, every set of day numbers fits exactly one day below the combined cycle.
- On such rotas, two days read the same exactly when they differ by whole combined cycles.
- When two lengths share no factor, multiplying by the first has an undoer on the second cycle. One fold with it lands on a day that reads right on both.
- It also re-checks the card's numbers: both folds, day 23 and 128, the chart, the 6-day cycle and day 38.

Running the code and printing its output line by line is left to the Python and Rust checks.

```lean
-- The Chinese remainder theorem: when no two cycle lengths share a factor, every set of day numbers is read on exactly one day of the combined cycle, two days read the same exactly when they differ by whole combined cycles, and folding two cycles with an inverse builds that day.
import Mathlib.Data.Nat.ChineseRemainder
import Mathlib.Data.Int.ModEq
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.Ring
import Mathlib.RingTheory.Coprime.Lemmas

open Finset

/-- Helper: agreeing modulo every coprime modulus is agreeing modulo the product. -/
theorem helper_modEq_prod_iff (k : ℕ) (m : Fin k → ℕ)
    (hcop : Pairwise fun i j => Nat.Coprime (m i) (m j)) (x y : ℕ) :
    (∀ i, x ≡ y [MOD m i]) ↔ x ≡ y [MOD ∏ i, m i] := by
  have hco : (List.finRange k).Pairwise (Function.onFun Nat.Coprime m) :=
    (List.nodup_finRange k).pairwise_of_forall_ne (fun i _ j _ hij => hcop hij)
  have h := Nat.modEq_list_map_prod_iff (a := x) (b := y) hco
  have hp : ((List.finRange k).map m).prod = ∏ i, m i := by
    rw [Fin.prod_univ_def]
  rw [hp] at h
  rw [h]
  simp

#print axioms helper_modEq_prod_iff


/-- The Chinese remainder theorem. Take any number of rotas with cycle lengths m, no two sharing a
factor, all counted from the same reset, and a day number on each (r below m on every rota).
Then exactly one day x below the combined cycle, the product of all the lengths, leaves day
number r on every rota. -/
theorem one_day_in_the_combined_cycle_fits (k : ℕ) (m r : Fin k → ℕ)
    (hcop : Pairwise fun i j => Nat.Coprime (m i) (m j)) (hr : ∀ i, r i < m i) :
    ∃! x : ℕ, x < ∏ i, m i ∧ ∀ i, x % m i = r i := by
  have hpos : ∀ i, m i ≠ 0 := fun i => (Nat.pos_of_ne_zero (by
    intro h; have := hr i; omega)).ne'
  have hP : 0 < ∏ i, m i := Nat.pos_of_ne_zero (Finset.prod_ne_zero_iff.mpr (fun i _ => hpos i))
  have hcop' : Set.Pairwise (↑(Finset.univ : Finset (Fin k))) (Function.onFun Nat.Coprime m) :=
    fun i _ j _ hij => hcop hij
  let c := Nat.chineseRemainderOfFinset r m Finset.univ (fun i _ => hpos i) hcop'
  have hc : ∀ i, (c : ℕ) ≡ r i [MOD m i] := fun i => c.prop i (Finset.mem_univ i)
  have hlt : (c : ℕ) < ∏ i, m i :=
    Nat.chineseRemainderOfFinset_lt_prod r m (fun i _ => hpos i) hcop'
  refine ⟨c, ⟨hlt, fun i => ?_⟩, ?_⟩
  · have := hc i
    unfold Nat.ModEq at this
    rw [this, Nat.mod_eq_of_lt (hr i)]
  · rintro y ⟨hy, hyr⟩
    have h1 : ∀ i, y ≡ (c : ℕ) [MOD m i] := fun i => by
      unfold Nat.ModEq
      rw [hyr i]
      have := hc i
      unfold Nat.ModEq at this
      rw [this, Nat.mod_eq_of_lt (hr i)]
    have h2 := (helper_modEq_prod_iff k m hcop y c).mp h1
    exact h2.eq_of_lt_of_lt hy hlt

/-- Why exactly one day fits, and why the answer repeats. On rotas whose lengths share no factor,
two days read the same day number on every rota exactly when they differ by a whole number of
combined cycles (the product of the lengths): 23 and 128 read the same, 23 and 24 do not. -/
theorem same_readings_iff_differ_by_combined_cycles (k : ℕ) (m : Fin k → ℕ)
    (hcop : Pairwise fun i j => Nat.Coprime (m i) (m j)) (x y : ℕ) :
    (∀ i, x % m i = y % m i) ↔ x ≡ y [MOD ∏ i, m i] := by
  exact helper_modEq_prod_iff k m hcop x y

/-- How to rebuild the day: one fold. If the cycle lengths a and b share no factor, multiplying
by a has an undoer t on the b-cycle (a × t leaves 1). With any such undoer, starting from day
number r on the a-cycle and taking (s − r) × t steps of a lands on a day that still reads r on
the a-cycle and now reads s on the b-cycle. -/
theorem fold_two_rotas_with_an_inverse (a b : ℕ) (hab : Nat.Coprime a b) :
    (∃ t : ℤ, (a : ℤ) * t ≡ 1 [ZMOD b]) ∧
      ∀ t : ℤ, (a : ℤ) * t ≡ 1 [ZMOD b] → ∀ r s : ℤ,
        r + a * ((s - r) * t) ≡ r [ZMOD a] ∧ r + a * ((s - r) * t) ≡ s [ZMOD b] := by
  have hex : ∃ t : ℤ, (a : ℤ) * t ≡ 1 [ZMOD b] := by
    obtain ⟨u, v, huv⟩ : ∃ u v : ℤ, (a : ℤ) * u + b * v = 1 := by
      have := Nat.isCoprime_iff_coprime.mpr hab
      obtain ⟨u, v, h⟩ := this
      exact ⟨u, v, by linear_combination h⟩
    refine ⟨u, ?_⟩
    rw [Int.modEq_iff_dvd]
    exact ⟨v, by linear_combination -huv⟩
  refine ⟨hex, fun t ht r s => ⟨?_, ?_⟩⟩
  · rw [Int.modEq_iff_dvd]
    exact ⟨-((s - r) * t), by ring⟩
  · have h1 : (a : ℤ) * t * (s - r) ≡ 1 * (s - r) [ZMOD b] := ht.mul_right _
    have h2 : r + a * ((s - r) * t) = r + a * t * (s - r) := by ring
    rw [h2]
    have h3 : r + (a : ℤ) * t * (s - r) ≡ r + 1 * (s - r) [ZMOD b] := h1.add_left r
    simpa using h3

-- The card's rotas: 3, 5 and 7 days share no factor, and the combined cycle is 105 days.
example : Nat.Coprime 3 5 ∧ Nat.Coprime 3 7 ∧ Nat.Coprime 5 7 ∧ 3 * 5 * 7 = 105 := by decide
-- The answer read off against each rota: 23 = 7 × 3 + 2, 23 = 4 × 5 + 3, 23 = 3 × 7 + 2.
example : 23 = 7 * 3 + 2 ∧ 23 = 4 * 5 + 3 ∧ 23 = 3 * 7 + 2 := by decide
example : 23 % 3 = 2 ∧ 23 % 5 = 3 ∧ 23 % 7 = 2 := by decide
-- First fold: 3 leaves 3 on the 5-cycle, undone by 2; steps 2; day 8 of 15.
example : 3 % 5 = 3 ∧ 3 * 2 % 5 = 1 ∧ (3 - 2) * 2 % 5 = 2 ∧ 2 + 3 * 2 = 8 ∧ 3 * 5 = 15 := by decide
example : 8 % 3 = 2 ∧ 8 % 5 = 3 := by decide
-- Second fold: 15 leaves 1 on the 7-cycle, undone by 1; day 8 sits on week day 1; one step; day 23 of 105.
example : 15 % 7 = 1 ∧ 15 * 1 % 7 = 1 ∧ 8 % 7 = 1 ∧ 8 + 15 * 1 = 23 ∧ 15 * 7 = 105 := by decide
-- The scripts subtract: 2 − 8 = −6, which is 1 forward on a 7-cycle.
example : (2 - 8 : ℤ) = -6 ∧ (-6 : ℤ) % 7 = 1 := by decide
-- Scanning all 105 days finds only day 23; two cycles out, 23 and 128.
example : (List.range 105).filter (fun d => d % 3 = 2 ∧ d % 5 = 3 ∧ d % 7 = 2) = [23] := by decide
example : (List.range 210).filter (fun d => d % 3 = 2 ∧ d % 5 = 3 ∧ d % 7 = 2) = [23, 128] := by
  decide
-- Cleaning alone allows 2, 5, 8; deliveries 3, 8, 13; 8, 23, 38 fit both.
example : (List.range 40).filter (fun d => d % 3 = 2 ∧ d % 5 = 3) = [8, 23, 38] := by decide
-- How many rotas each day 0 to 29 matches, as in the chart.
example : (List.range 30).map (fun d =>
      (if d % 3 = 2 then 1 else 0) + (if d % 5 = 3 then 1 else 0) + (if d % 7 = 2 then 1 else 0)) =
    [0, 0, 2, 1, 0, 1, 0, 0, 2, 1, 0, 1, 0, 1, 1, 0, 1, 1, 1, 0, 1, 0, 0, 3, 0, 0, 1, 0, 1, 1] := by
  decide
-- The mistake of adding the day numbers: 2 + 3 + 2 = 7, which is day 1 of the 3-day cycle, not day 2.
example : 2 + 3 + 2 = 7 ∧ 7 % 3 = 1 := by decide
-- A 6-day cycle for the week: 3 and 6 share a factor, so 3 has no undoer on the 6-cycle.
example : ¬ Nat.Coprime 3 6 ∧ ∀ t ∈ Finset.range 6, 3 * t % 6 ≠ 1 := by decide
-- Readings that agree fit day 8 in 30; readings that clash fit no day.
example : (List.range 30).filter (fun d => d % 3 = 2 ∧ d % 5 = 3 ∧ d % 6 = 2) = [8] := by decide
example : (List.range 30).filter (fun d => d % 3 = 2 ∧ d % 5 = 3 ∧ d % 6 = 1) = [] := by decide
-- Try changing: with the week moved on by one (day numbers 2, 3, 3), still one day in 105, now day 38.
example : (List.range 105).filter (fun d => d % 3 = 2 ∧ d % 5 = 3 ∧ d % 7 = 3) = [38] := by decide

#print axioms one_day_in_the_combined_cycle_fits
#print axioms same_readings_iff_differ_by_combined_cycles
#print axioms fold_two_rotas_with_an_inverse
```

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'helper_modEq_prod_iff' depends on axioms: [propext, Classical.choice, Quot.sound]
'one_day_in_the_combined_cycle_fits' depends on axioms: [propext, Classical.choice, Quot.sound]
'same_readings_iff_differ_by_combined_cycles' depends on axioms: [propext, Classical.choice, Quot.sound]
'fold_two_rotas_with_an_inverse' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run. The asserts are pinned to these rotas, so one fires.
> - **Move the week on by one.** Set `DAYS` to `[2, 3, 3]`: still one day in 105, now day 38.
> - **Break the coprime rule.** Set `CYCLES` to `[3, 5, 6]`: no undoer exists, and the run stops with an error.

---

## The usual mistake

> [!warning]
> **Assuming any set of cycles will do.** Folding rests on no two lengths sharing a factor. Swap the week for a 6-day cycle and the fold jams: multiplying by 3 has no undoer on the 6-cycle. Whether a day still fits is a separate question, settled by the shared factor 3. The 6-cycle reading day 2 leaves 2 on the 3, and cleaning reads 2 as well, so they agree and day 8 fits — every 30 days now, not 90. Read the 6-cycle as day 1 and they disagree: no day fits.
>
> - **Reading "day 23" as a date.** 128 fits too.
> - **Adding the day numbers.** 2 + 3 + 2 = 7, which is day 1 of the 3-day cycle.
> - **Folding all three at once.** No single undoer covers three rotas. Fold two, write the middle answer down, then fold that with the third.

---

## Where you meet it in real life

- **Rotas and calendars.** Any "where is every cycle at once" question: shifts, bin collections, a payday against a billing date.
- **Big arithmetic done small.** A sum on one huge clock is split across two smaller coprime ones, done separately, then folded back. It is why bank-grade encryption is fast enough to use.
- **Checking a serial number.** Hold a number as remainders on small coprime clocks: a bad digit shows as one board disagreeing.

> **Say it back**
> Three rotas from one reset: 3 days, 5 days, the 7-day week, reading day 2, day 3, day 2. No two lengths share a factor, so exactly one day in 105 reads that way: day 23. Build it by folding two rotas at a time, each fold picking a step count with one inverse: day 8 of 15, then day 23 of 105.

---

## What this builds on

- [The modular inverse](04-modular-inverse.md): the undoer each fold needs; it exists only when the lengths share no factor.
- [Coprime numbers](../02-Greatest%20Common%20Divisor%20and%20Euclid%27s%20Algorithm/05-coprime-numbers.md): sharing no factor above 1, the condition all of this rests on.
- [Least common multiple](../02-Greatest%20Common%20Divisor%20and%20Euclid%27s%20Algorithm/02-lcm.md): for coprime lengths the smallest number both divide is their product, so the answer repeats every 105 days.
- [Negative numbers](../../01-Foundations/01-Everyday%20Arithmetic/06-negative-numbers.md): a step back on a cycle is a step forward the other way.

## Where this goes next

- [When cycles meet again](../05-Check%20Digits%2C%20Calendars%20and%20Cycles/04-cycles-that-realign.md): cycles that do share factors, and the line-ups that never happen.

This card leaves one question open: when the lengths do share a factor, which readings can still happen, and how often do they come round?

---

## Sources

Verified 2026-11-11: every link below resolves to the publisher's page.

- Gauss, Carl Friedrich. *Disquisitiones Arithmeticae*. Trans. Arthur A. Clarke. Springer, 1986. [doi:10.1007/978-1-4939-7560-0](https://doi.org/10.1007/978-1-4939-7560-0). Articles 32 to 36.
- Shoup, Victor. *A Computational Introduction to Number Theory and Algebra*, 2nd ed. Cambridge, 2008. [Free full text](https://shoup.net/ntb/). Section 2.4.
- O'Connor, J. J., and E. F. Robertson. "Sun Zi." MacTutor, University of St Andrews. [Biography page](https://mathshistory.st-andrews.ac.uk/Biographies/Sun_Zi/). The puzzle behind these rotas.
