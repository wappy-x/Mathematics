# The real numbers have no gaps: every point on the tape is a number

[Syllabus](../../../SYLLABUS.md) → [Foundations](../README.md) → [The Number Line](../README.md#s02) → The real numbers have no gaps

---

## General Overview

Throw a dart at a one-metre tape measure. It sticks somewhere. Not on a millimetre mark — between two of them.

Buy a finer tape, marked every tenth of a millimetre. Same hole, still between marks. No tape ever marks the spot.

So is the landing place a number?

Every mark on every tape is a fraction: so many pieces out of so many. Fractions are packed absurdly tight — between any two sits another, halfway. They still miss things. [Irrational numbers](03-irrational-numbers.md) showed one: root 2, the number that gives 2 when multiplied by itself — about 1.414 metres, the diagonal of a one-metre square tile. No fraction lands there. A dart can.

The **real numbers** are the fractions plus every landing place they miss.

**Every point on the tape is a real number, and every real number is a point on the tape.**

**What kind of fact this is:** an axiom, a starting rule that is not proved. Build the reals from cuts (Why it works, Step 3) and it becomes a theorem.

### The picture: the marks closing in on the dart

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "The nearest tape marks either side of the dart, as the tape gets finer"
    x-axis "How many decimal places the tape is marked to" [0, 1, 2, 3, 4]
    y-axis "Distance along the tape, in metres" 1 --> 2
    line [1, 1.4, 1.41, 1.414, 1.4142]
    line [2, 1.5, 1.42, 1.415, 1.4143]
```

Rising line: the nearest mark below the dart. Falling line: the nearest above. They close in but never meet.

---

## The formula

One promise carries the card:

**If a collection of numbers has a member, and some one number sits above everything in it, then there is a lowest such number — and it is a real number too.**

**Read it aloud:** a collection with a member and a ceiling has a lowest ceiling, and it is a real number.

Drop either condition and the promise says nothing: the counting numbers 1, 2, 3, ... have no ceiling.

On the dart, in metres:

**Collection: every number whose square (the number times itself) is under 2. Nothing in it reaches 1.5, because 1.5 × 1.5 = 2.25. Its lowest ceiling is root 2, 1.41421356..., and that is a real number.**

| Piece | Plain meaning | In the dart example |
| --- | --- | --- |
| a collection | any bunch of numbers you can describe | every number whose square is under 2 |
| has a member | at least one number is in it | 1 is: 1 × 1 = 1, under 2 |
| a ceiling (upper bound) | nothing in the collection passes it | 1.5, 1.42, 2 |
| the lowest ceiling (least upper bound) | the smallest ceiling there is | 1.41421356..., where the dart hit |
| completeness | that lowest ceiling is always a real number | the reals keep it, fractions break it |

### When it holds

- **It has a member.** If it is empty, every number is a ceiling, and none is the lowest.
- **It has a ceiling.** The counting numbers have none, so nothing can be the lowest.
- **The numbers are the reals.** Among the fractions it fails: 1.415 and 1.4143 are both ceilings, and every fraction ceiling has a smaller one (Step 2).

---

## Why it works

### Step 0: packed tight is not gapless

Between any two fractions sits another. Do that forever and they look like a solid line. They are not: root 2 is missing, and so is every decimal that never settles into a repeating block.

### Step 1: squeeze the dart between two marks

Mark the tape to one decimal place. 1.4 × 1.4 = 1.96, under 2, so 1.4 is below the dart; 1.5 × 1.5 = 2.25, over 2, so 1.5 is above it. Two places: 1.41 and 1.42. Four places: 1.4142 and 1.4143.

Every one of those marks is a fraction, and the gap shrinks toward nothing.

### Step 2: the fractions cannot name the lowest ceiling

Name any fraction that is a ceiling. Say 1.415: its square, 2.002225, is over 2, so nothing in the collection passes it. But 1.4143 is smaller and still a ceiling — its square is 2.00024449, still over 2. Any fraction whose square is over 2 can be trimmed a hair and stay over 2, so it was never the lowest.

Stopping would need a fraction whose square is exactly 2, and there is none. Bounded, yet no lowest ceiling among the fractions: the promise breaks.

### Step 3: put a number at the meeting point

The reals close that hole: wherever a squeeze like this happens, a number sits at the meeting point. Here that is 1.41421356..., root 2 — the lowest ceiling.

That is **completeness**: what makes the reals the reals instead of the fractions, which obey every other rule of arithmetic and fail this one.

Richard Dedekind, in 1872, took another route: split all the fractions into a left pile and a right pile so the left pile has no largest member, and call the split itself (a cut) a number.

---

## Worked numbers, by hand

In metres.

| Step | Arithmetic | Value |
| --- | --- | --- |
| one place, below | 1.4 × 1.4 | 1.96 |
| one place, above | 1.5 × 1.5 | 2.25 |
| two places, below | 1.41 × 1.41 | 1.9881 |
| two places, above | 1.42 × 1.42 | 2.0164 |
| four places, below | 1.4142 × 1.4142 | 1.99996164 |
| four places, above | 1.4143 × 1.4143 | 2.00024449 |
| the lowest ceiling | both ends agree to eight places | **1.41421356** |

The dart landed at 1.41421356... metres. No fraction sits there; the tape does.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Stopping at 1.4142 | 1.99996164 | Under 2, so it is in the collection |
| Stopping at 1.415 | 2.002225 | A ceiling, but 1.4143 is a smaller one |
| Asking the fractions | no answer | Every fraction ceiling has a smaller one under it |

---

## Code, from first principles, and it actually runs

No decimal enters the machine: every step is whole-number arithmetic, so nothing rounds. Road one walks the decimal places. Road two halves the bracket from 1 to 2, forty times, until both ends read the same to eight places. Three asserts, one that the roads agree.

### Python

```python
# The real numbers have no gaps -- the check behind the card.  Nothing is
# imported.  The collection is every number whose square is under 2 -- the
# spot the dart hit on the tape.  Two roads to its least ceiling: decimal
# places, then halving a bracket.  Whole numbers only, so nothing rounds.
def dec(n, places):                 # dec(14142, 4) -> "1.4142"
    s = str(n).rjust(places + 1, "0")
    return s if places == 0 else s[:len(s) - places] + "." + s[len(s) - places:]

print("places   below       its square    above       its square")
for k, low, high in [(0, 1, 2), (1, 14, 15), (2, 141, 142), (3, 1414, 1415), (4, 14142, 14143)]:
    unit = 10 ** k
    assert low * low < 2 * unit * unit < high * high     # low is inside, high is a ceiling
    print(f"  {k}      {dec(low * 10 ** (4 - k), 4):<12}{dec(low * low, 2 * k):<14}{dec(high * 10 ** (4 - k), 4):<12}{dec(high * high, 2 * k)}")

lo, hi, den = 1, 2, 1                                    # the second road: halve the gap
for _ in range(40):
    lo, hi, den = 2 * lo, 2 * hi, 2 * den
    mid = (lo + hi) // 2
    if mid * mid < 2 * den * den: lo = mid
    else: hi = mid
print(f"halving from 1 to 2, forty times: the least ceiling is caught between {dec(lo * 10 ** 8 // den, 8)} and {dec(hi * 10 ** 8 // den, 8)}")
assert 14142 * den <= lo * 10000 and hi * 10000 <= 14143 * den
print("the two roads agree: the halving bracket sits inside 1.4142 and 1.4143")
print(f"a ceiling, but not the least: 1.415 squares to {dec(1415 * 1415, 6)}, and 1.4143 squares to {dec(14143 * 14143, 8)}")
print(f"not a ceiling at all: 1.4142 squares to {dec(14142 * 14142, 8)}, which is under 2")
assert 14142 * 14142 < 2 * 10000 * 10000 < 14143 * 14143 and 14143 < 1415 * 10
print("ALL CHECKS PASS")
```

**Ran 2026-09-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
places   below       its square    above       its square
  0      1.0000      1             2.0000      4
  1      1.4000      1.96          1.5000      2.25
  2      1.4100      1.9881        1.4200      2.0164
  3      1.4140      1.999396      1.4150      2.002225
  4      1.4142      1.99996164    1.4143      2.00024449
halving from 1 to 2, forty times: the least ceiling is caught between 1.41421356 and 1.41421356
the two roads agree: the halving bracket sits inside 1.4142 and 1.4143
a ceiling, but not the least: 1.415 squares to 2.002225, and 1.4143 squares to 2.00024449
not a ceiling at all: 1.4142 squares to 1.99996164, which is under 2
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// The real numbers have no gaps -- the same check as the Python file, in
// Rust.  No crates.  The collection is every number whose square is under
// 2 -- the spot the dart hit on the tape.  Two roads to its least ceiling:
// decimal places, then halving a bracket.  i128 keeps every step exact.
fn dec(n: i128, places: usize) -> String {   // dec(14142, 4) -> "1.4142"
    let mut s = n.to_string();
    while s.len() < places + 1 { s.insert(0, '0'); }
    if places == 0 { s } else { let c = s.len() - places; format!("{}.{}", &s[..c], &s[c..]) }
}

fn ten(k: u32) -> i128 { 10i128.pow(k) }

fn main() {
    println!("places   below       its square    above       its square");
    for (k, low, high) in [(0u32, 1i128, 2i128), (1, 14, 15), (2, 141, 142), (3, 1414, 1415), (4, 14142, 14143)] {
        let unit = ten(k);
        assert!(low * low < 2 * unit * unit && 2 * unit * unit < high * high);   // low is inside, high is a ceiling
        println!("  {}      {:<12}{:<14}{:<12}{}", k, dec(low * ten(4 - k), 4), dec(low * low, 2 * k as usize),
                 dec(high * ten(4 - k), 4), dec(high * high, 2 * k as usize));
    }
    let (mut lo, mut hi, mut den) = (1i128, 2i128, 1i128);                       // the second road: halve the gap
    for _ in 0..40 {
        lo *= 2; hi *= 2; den *= 2;
        let mid = (lo + hi) / 2;
        if mid * mid < 2 * den * den { lo = mid; } else { hi = mid; }
    }
    println!("halving from 1 to 2, forty times: the least ceiling is caught between {} and {}",
             dec(lo * ten(8) / den, 8), dec(hi * ten(8) / den, 8));
    assert!(14142 * den <= lo * 10000 && hi * 10000 <= 14143 * den);
    println!("the two roads agree: the halving bracket sits inside 1.4142 and 1.4143");
    println!("a ceiling, but not the least: 1.415 squares to {}, and 1.4143 squares to {}",
             dec(1415 * 1415, 6), dec(14143 * 14143, 8));
    println!("not a ceiling at all: 1.4142 squares to {}, which is under 2", dec(14142 * 14142, 8));
    assert!(14142 * 14142 < 2 * 10000 * 10000 && 2 * 10000 * 10000 < 14143 * 14143 && 14143 < 1415 * 10);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
places   below       its square    above       its square
  0      1.0000      1             2.0000      4
  1      1.4000      1.96          1.5000      2.25
  2      1.4100      1.9881        1.4200      2.0164
  3      1.4140      1.999396      1.4150      2.002225
  4      1.4142      1.99996164    1.4143      2.00024449
halving from 1 to 2, forty times: the least ceiling is caught between 1.41421356 and 1.41421356
the two roads agree: the halving bracket sits inside 1.4142 and 1.4143
a ceiling, but not the least: 1.415 squares to 2.002225, and 1.4143 squares to 2.00024449
not a ceiling at all: 1.4142 squares to 1.99996164, which is under 2
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves the promise for every collection of real numbers, and both dart claims beside it.

- Any collection of real numbers with a member and a ceiling has a lowest ceiling, and it is a real number.
- Among the reals, the numbers whose square is under 2 have root 2 as their lowest ceiling.
- Among the fractions, the same collection has a member and a ceiling, yet every fraction ceiling has a smaller one.
- So no fraction is its lowest ceiling.

The tape's squares, such as 1.4143 × 1.4143, are checked in Lean too; halving the bracket forty times is left to the Python and Rust checks.

<details>
<summary>The Lean proof, 120 lines</summary>

```lean
-- The real numbers have no gaps: every collection of real numbers with a member and a ceiling has a lowest ceiling that is a real number, for the numbers whose square is under 2 that lowest ceiling is root 2, and among the fractions the same collection has no lowest ceiling at all.
import Mathlib.Algebra.Order.Archimedean.Real.Basic
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Order.Bounds.Basic
import Mathlib.Tactic.NormNum
import Mathlib.NumberTheory.Real.Irrational

/-- Completeness: if a collection of real numbers has a member, and some one number sits above
everything in it, then there is a lowest such number (a least upper bound), and it is a real
number too. -/
theorem nonempty_bounded_above_has_lowest_ceiling (S : Set ℝ) (hne : S.Nonempty)
    (hbdd : BddAbove S) : ∃ x : ℝ, IsLUB S x := by
  exact ⟨sSup S, isLUB_csSup hne hbdd⟩

/-- The dart: among the real numbers, the collection of every number whose square is under 2
has root 2 as its lowest ceiling. -/
theorem sqrt_two_is_lowest_ceiling : IsLUB {x : ℝ | x * x < 2} (√2) := by
  have h2 : √2 * √2 = 2 := Real.mul_self_sqrt (by norm_num)
  have hpos : 0 < √2 := Real.sqrt_pos.mpr (by norm_num)
  constructor
  · intro x hx
    simp only [Set.mem_setOf_eq] at hx
    by_contra h
    push_neg at h
    nlinarith
  · intro b hb
    have h1 : (1 : ℝ) ≤ b := hb (by simp only [Set.mem_setOf_eq]; norm_num)
    by_contra h
    push_neg at h
    have hm : ((b + √2) / 2) ∈ {x : ℝ | x * x < 2} := by
      simp only [Set.mem_setOf_eq]
      nlinarith
    have := hb hm
    linarith

/-- The fractions have a gap: the fractions whose square is under 2 have a member (1) and a
ceiling (for example 3/2), but every fraction ceiling has a smaller fraction ceiling under it,
so no fraction is the lowest ceiling. -/
theorem fractions_have_no_lowest_ceiling :
    ({q : ℚ | q * q < 2}).Nonempty ∧ BddAbove {q : ℚ | q * q < 2} ∧
      (∀ r ∈ upperBounds {q : ℚ | q * q < 2}, ∃ r' ∈ upperBounds {q : ℚ | q * q < 2}, r' < r) ∧
      ¬ ∃ r : ℚ, IsLUB {q : ℚ | q * q < 2} r := by
  have key : ∀ r ∈ upperBounds {q : ℚ | q * q < 2}, ∃ r' ∈ upperBounds {q : ℚ | q * q < 2}, r' < r := by
    intro r hr
    have h1 : (1 : ℚ) ≤ r := hr (by simp only [Set.mem_setOf_eq]; norm_num)
    have hne : r * r ≠ 2 := by
      intro h
      apply irrational_sqrt_two
      refine ⟨r, ?_⟩
      have h2 : ((r : ℝ)) * (r : ℝ) = 2 := by exact_mod_cast h
      have h0 : (0 : ℝ) ≤ (r : ℝ) := by exact_mod_cast (by linarith : (0 : ℚ) ≤ r)
      rw [← h2]
      exact (Real.sqrt_mul_self h0).symm
    have hge : 2 < r * r := by
      by_contra hcon
      push_neg at hcon
      have hlt : r * r < 2 := lt_of_le_of_ne hcon hne
      have hr2 : r < 2 := by nlinarith
      set δ : ℚ := (2 - r * r) / 5 with hδ
      have hδpos : 0 < δ := by rw [hδ]; linarith
      have hδle : δ ≤ 1 := by rw [hδ]; nlinarith
      have hin : (r + δ) ∈ {q : ℚ | q * q < 2} := by
        simp only [Set.mem_setOf_eq]
        nlinarith
      have := hr hin
      linarith
    refine ⟨r / 2 + 1 / r, ?_, ?_⟩
    · intro q hq
      simp only [Set.mem_setOf_eq] at hq
      have hrpos : 0 < r := by linarith
      have hr' : 0 < r / 2 + 1 / r := by positivity
      have hsq : 2 ≤ (r / 2 + 1 / r) * (r / 2 + 1 / r) := by
        have : (r / 2 + 1 / r) * (r / 2 + 1 / r) - 2 = (r * r - 2) ^ 2 / (4 * (r * r)) := by
          field_simp
          ring
        have : 0 ≤ (r * r - 2) ^ 2 / (4 * (r * r)) := by positivity
        linarith
      by_contra h
      push_neg at h
      nlinarith
    · have hrpos : 0 < r := by linarith
      have : r / 2 + 1 / r < r ↔ 2 < r * r := by
        rw [show r / 2 + 1 / r = (r * r + 2) / (2 * r) by field_simp, div_lt_iff₀ (by positivity)]
        constructor <;> intro h <;> nlinarith
      exact this.mpr hge
  refine ⟨⟨1, by simp only [Set.mem_setOf_eq]; norm_num⟩, ⟨2, ?_⟩, key, ?_⟩
  · intro q hq
    simp only [Set.mem_setOf_eq] at hq
    by_contra h
    push_neg at h
    nlinarith
  · rintro ⟨r, hr⟩
    obtain ⟨r', hr', hlt⟩ := key r hr.1
    have := hr.2 hr'
    linarith

-- 1 is in the collection: 1 × 1 = 1, under 2.
example : (1 * 1 : ℕ) = 1 ∧ (1 : ℕ) < 2 := by decide
-- No places: 1 × 1 = 1 is under 2, and 2 × 2 = 4 is over it.
example : (1 * 1 : ℕ) < 2 ∧ (2 : ℕ) < 2 * 2 := by decide
-- One place, in tenths: 14 × 14 = 196 is under 200, and 15 × 15 = 225 is over it (1.96 and 2.25).
example : (14 * 14 : ℕ) = 196 ∧ (15 * 15 : ℕ) = 225 ∧ (196 : ℕ) < 2 * 10 ^ 2 ∧
    2 * 10 ^ 2 < (225 : ℕ) := by norm_num
-- Two places, in hundredths: 141 × 141 = 19881 and 142 × 142 = 20164 sit either side of 20000.
example : (141 * 141 : ℕ) = 19881 ∧ (142 * 142 : ℕ) = 20164 ∧ (19881 : ℕ) < 2 * 10 ^ 4 ∧
    2 * 10 ^ 4 < (20164 : ℕ) := by norm_num
-- Three places: 1414 × 1414 = 1999396 and 1415 × 1415 = 2002225 sit either side of 2000000.
example : (1414 * 1414 : ℕ) = 1999396 ∧ (1415 * 1415 : ℕ) = 2002225 ∧
    (1999396 : ℕ) < 2 * 10 ^ 6 ∧ 2 * 10 ^ 6 < (2002225 : ℕ) := by norm_num
-- Four places: 14142 × 14142 = 199996164 and 14143 × 14143 = 200024449 sit either side of 200000000.
example : (14142 * 14142 : ℕ) = 199996164 ∧ (14143 * 14143 : ℕ) = 200024449 ∧
    (199996164 : ℕ) < 2 * 10 ^ 8 ∧ 2 * 10 ^ 8 < (200024449 : ℕ) := by norm_num
-- 1.415 is a ceiling, but 1.4143 is a smaller one: 14143 < 14150, and 14143 × 14143 is still over 2 × 10^8.
example : (14143 : ℕ) < 1415 * 10 ∧ 2 * 10 ^ 8 < (14143 * 14143 : ℕ) := by norm_num
-- Stopping at 1.4142 is wrong: its square is under 2, so it is in the collection, not a ceiling.
example : (14142 * 14142 : ℕ) < 2 * 10 ^ 8 := by norm_num

#print axioms nonempty_bounded_above_has_lowest_ceiling
#print axioms sqrt_two_is_lowest_ceiling
#print axioms fractions_have_no_lowest_ceiling
```

</details>

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'nonempty_bounded_above_has_lowest_ceiling' depends on axioms: [propext, Classical.choice, Quot.sound]
'sqrt_two_is_lowest_ceiling' depends on axioms: [propext, Classical.choice, Quot.sound]
'fractions_have_no_lowest_ceiling' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **Halve fewer times.** Change the forty to a ten. The bracket is still a thousandth wide, 1.4140 to 1.4150, so it no longer fits inside 1.4142 and 1.4143 and the assert fires.
> - **Start with a false ceiling.** Bracket 1 to 1: 1 squares to 1, under 2, so it is inside the collection, not above it. The bracket never moves off 1.00000000, and the same assert fires.

---

## The usual mistake

> [!warning]
> **Hunting for the biggest member instead of the lowest ceiling.** There is none: every number whose square is under 2 has a bigger one also under 2. The lowest ceiling stands just outside: 1.41421356... is not in the collection, because that square is exactly 2.
>
> - Treating "packed tight" as "no gaps". Fractions are packed tight and still miss root 2.
> - Treating completeness as one more fact about the reals. It is the one rule that separates them from the fractions: assumed if you take the reals as given, proved if you build them from cuts.

---

## Where you meet it in real life

- **Any measurement.** A length, a temperature, a time. The reading is a real number whether or not the marks reach it: [The number line and inequalities](02-number-line-and-inequalities.md).
- **Solvers that close in.** A calculator's root key, a spreadsheet goal seek — each halves a bracket. They work because the squeeze lands somewhere.
- **A graph crossing a line.** A cost curve meets a revenue line at a point: the line has no gap to jump.

> **Say it back**
> A dart on a tape lands between marks, however fine the marks get. Every mark is a fraction, and fractions miss places — root 2 is one. The reals are the fractions plus all those places. That is completeness: any collection with a member and a ceiling has a lowest ceiling, and it is a real number. Here, 1.41421356..., which no fraction supplies. That is why the reals are the line.

---

## What this builds on

- [Irrational numbers](03-irrational-numbers.md): that root 2 is not a fraction — the missing place this card points at.
- [The number families](01-number-families.md): which numbers are fractions and which are not.

## Where this goes next

- [No gaps](../../06-Calculus%20and%20analysis/01-Limits%20and%20Continuity/02-supremum-and-completeness.md): the same promise in symbols. The lowest ceiling is named the supremum and used to prove that roots exist.

Nothing else on this shelf needs this card. It finishes with [Absolute value](05-absolute-value-and-distance.md), which does not need completeness.

The question this card leaves open: how does calculus use the lowest ceiling to prove a number exists?

---

## Sources

Verified 2026-11-11: every link below resolves to the publisher's page.

- Dedekind, Richard. *Essays on the Theory of Numbers*, trans. W. W. Beman. Open Court, 1901. [Project Gutenberg](https://www.gutenberg.org/ebooks/21016). The 1872 essay that first said the line has no gaps.
- Abbott, Stephen. *Understanding Analysis*, 2nd ed. Springer, 2015. [doi:10.1007/978-1-4939-2712-8](https://doi.org/10.1007/978-1-4939-2712-8). Section 1.3 states the promise, on this collection.
