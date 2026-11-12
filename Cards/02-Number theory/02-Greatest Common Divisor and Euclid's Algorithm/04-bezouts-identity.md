# Bezout's identity: the gcd is always a whole-number mix of the two numbers, and running Euclid backwards finds the mix

[Syllabus](../../../SYLLABUS.md) → [Number theory](../README.md) → [Greatest Common Divisor and Euclid's Algorithm](../README.md#s02) → Bezout's identity

---

## General Overview

Two jugs, no markings. One holds 21 litres, one holds 15. A tap, and a tub. Fill a jug and tip it in, or dip a jug out and throw that jugful away. Leave exactly 3 litres.

It works. Fill the 15 three times: 45 litres in. Dip the 21 twice and throw both away: 42 gone. Left: 3.

One line holds the session: **21 × (−2) + 15 × 3 = 3**. Pouring in counts up, throwing away counts down, so the minus sign is a real move ([Negative numbers](../../01-Foundations/01-Everyday%20Arithmetic/06-negative-numbers.md)).

The 3 is not luck: it is the greatest common divisor — gcd for short — of 21 and 15, the biggest number dividing both ([Greatest common divisor](01-gcd.md)).

**Any whole-number mix of two numbers — copies of one poured in, copies of the other thrown away — lands on a multiple of their gcd, and the gcd itself is always reachable.**

**What kind of fact this is:** a theorem, proved on this card in Why it works: Euclid's chain, walked back up, always reaches the gcd.

A mix's real name is an integer linear combination; the counts are the Bezout coefficients.

### The picture: down, then back up

```mermaid
flowchart TD
  D1["21 = 1 x 15 + 6"] --> D2["15 = 2 x 6 + 3"]
  D2 --> D3["6 = 2 x 3 + 0, so the gcd is 3"]
  D3 --> B1["3 = 15 − 2 x 6"]
  B1 --> B2["6 = 21 − 1 x 15, so swap it in"]
  B2 --> B3["3 = 21 x (−2) + 15 x 3"]
```

Down: divide until the remainder is 0. Up: replace each remainder by the line above it.

---

## The formula

**21 × (−2) + 15 × 3 = −42 + 45 = 3**

In general: **first number × its count + second number × its count = their gcd.**

**Read it aloud:** two jugfuls of the 21 thrown away, three of the 15 poured in, 3 litres left.

| Piece | Plain meaning | In our jugs |
| --- | --- | --- |
| the two numbers | what the jugs hold | 21 and 15 |
| a count (a Bezout coefficient) | jugfuls, minus meaning thrown away | −2 and 3 |
| a mix (an integer linear combination) | each number times its count, added | 21 × (−2) + 15 × 3 |
| the gcd | biggest number dividing both; mixes reach its multiples | 3 |

### When it holds

- **Counts are whole numbers.** Allow part of a jugful and any amount can be left, so the gcd no longer sets the floor.
- **A count may be negative.** That is a jugful thrown away. Pour in only, and no mix of 21 and 15 lands on 3.
- **The two numbers are not both 0.** Two empty jugs leave 0 every time, and there is no greatest divisor to reach.
- **The target is a multiple of the gcd.** Ask for anything else and no counts exist: the search finds 0 mixes that land on 1 or 2 litres.

---

## Why it works

### Step 0: a mix can only reach multiples of a shared divisor

3 divides 21 and 3 divides 15. Copies of a multiple of 3 stay multiples of 3, and so does their sum ([Divides](../01-Divisibility%20and%20Primes/01-divides.md)). So every mix of these jugs is a multiple of 3 — nothing between 0 and 3 is reachable.

### Step 1: rearrange Euclid's chain

The chain's three lines are in the picture ([Euclid's algorithm](03-euclidean-algorithm.md)). Stand the remainders on their own:

- 6 = 21 − 1 × 15
- 3 = 15 − 2 × 6

### Step 2: walk back up, swapping in

The second line mixes 15 and 6, and 6 is not a jug. The first says what 6 is, so swap it in:

3 = 15 − 2 × (21 − 1 × 15)

Multiply out and gather like pieces ([The three rearranging laws](../../01-Foundations/01-Everyday%20Arithmetic/05-arithmetic-laws.md)):

3 = 21 × (−2) + 15 × 3

Only the jugs are left: those are the pours.

Nothing here can fail: every chain stops, every line rearranges, and a mix swapped into a mix is still a mix ([Euclid's algorithm](03-euclidean-algorithm.md); careful form on [Strong induction and the least element](../../01-Foundations/06-Proof/05-strong-induction-and-well-ordering.md)).

Step 0 rules out everything below the gcd; Step 2 reaches it. So the gcd is the smallest amount above zero the tub can hold: biggest thing dividing both, smallest thing you can build.

### There is never just one answer

Pour 5 more of the 21 in and throw 7 more of the 15 away. They cancel: both are 105. The 5 is 15 ÷ 3, the 7 is 21 ÷ 3 — each jug over the gcd. The counts move with it: −2 + 5 = 3, 3 − 7 = −4.

21 × 3 + 15 × (−4) = 63 − 60 = 3

Either direction, forever: infinitely many pairs, all leaving 3 litres.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| divide 21 by 15 | 21 = 1 × 15 + 6 | 6 |
| divide 15 by 6 | 15 = 2 × 6 + 3 | 3 |
| divide 6 by 3, and stop | 6 = 2 × 3 + 0 | 0 |
| swap the 6 out | 3 = 15 − 2 × (21 − 1 × 15) | — |
| gather | 21 × (−2) + 15 × 3 = −42 + 45 | **3** |
| slide one step | 21 × 3 + 15 × (−4) | **3** |

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Pouring in only | 87 | 21 × 2 + 15 × 3; positive counts only fill |
| Reading the leftover as a jug | −27 | 3 = 15 − 2 × 6 is right; 21 in place of the 6 gives 15 − 42 |
| Swapping the counts | 33 | 21 × 3 + 15 × (−2); a count belongs to its number |

The code prints all three.

---

## Code, from first principles, and it actually runs

Nothing is imported. Road one runs Euclid's chain on 21 and 15, then walks it backwards until only the jugs remain. Road two tries every small mix: does anything above zero beat 3, does 1 or 2 turn up? A third route to the gcd — just listing the divisors — pins Euclid's answer.

### Python

```python
# Bezout's identity -- the check behind the card.  Nothing is imported.  Two
# jugs, 21 and 15 litres.  Road one: Euclid's chain, walked backwards, to write
# 3 as a mix of 21 and 15.  Road two: try every small mix and see what turns up.
A, B = 21, 15

def listing_gcd(a, b):            # independent of Euclid: list the divisors
    return max(d for d in range(1, min(a, b) + 1) if a % d == 0 and b % d == 0)

chain, a, b = [], A, B
while b:
    chain.append((a, a // b, b, a % b))
    a, b = b, a % b
g = a
print(f"{'gcd(21, 15) by Euclid':<38}{g:>4}")
for (u, q, v, r) in chain:
    print(f"{u} = {q} x {v} + {r}")
p, s = 1, -chain[-2][1]           # the last useful line: 3 = 15 - 2 x 6
for (u, q, v, r) in reversed(chain[:-2]):
    p, s = s, p - s * q           # swap in the line above it
print(f"Bezout: 21 x {p} + 15 x {s} = {A * p} + {B * s} = {A * p + B * s}")
p2, s2 = p + B // g, s - A // g   # slide along by one whole step
print(f"one step along (21 x {B // g} = 15 x {A // g} = {A * (B // g)}): 21 x {p2} + 15 x {s2} = {A * p2} + {B * s2} = {A * p2 + B * s2}")
mixes = [A * i + B * j for i in range(-9, 10) for j in range(-9, 10)]
print(f"{'smallest mix above zero, by search':<38}{min(m for m in mixes if m > 0):>4}")
print(f"{'mixes that land on 1 or 2 litres':<38}{sum(m in (1, 2) for m in mixes):>4}")
print(f"the three mistakes come out at {A * 2 + B * 3}, {B - 2 * A} and {A * 3 - B * 2}")
assert g == 3 and g == listing_gcd(A, B)
assert (p, s) == (-2, 3) and A * p + B * s == g and A * p2 + B * s2 == g
assert min(m for m in mixes if m > 0) == g and 1 not in mixes and 2 not in mixes
print("ALL CHECKS PASS")
```

**Ran 2026-09-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
gcd(21, 15) by Euclid                    3
21 = 1 x 15 + 6
15 = 2 x 6 + 3
6 = 2 x 3 + 0
Bezout: 21 x -2 + 15 x 3 = -42 + 45 = 3
one step along (21 x 5 = 15 x 7 = 105): 21 x 3 + 15 x -4 = 63 + -60 = 3
smallest mix above zero, by search       3
mixes that land on 1 or 2 litres         0
the three mistakes come out at 87, -27 and 33
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Bezout's identity -- the same check as the Python twin, in Rust.  No crates.
// Two jugs, 21 and 15 litres.  Road one: Euclid's chain, walked backwards, to
// write 3 as a mix of 21 and 15.  Road two: try every small mix and look.
const A: i64 = 21;
const B: i64 = 15;

fn listing_gcd(a: i64, b: i64) -> i64 {   // independent of Euclid: list the divisors
    (1..=a.min(b)).filter(|d| a % d == 0 && b % d == 0).max().unwrap()
}

fn main() {
    let (mut a, mut b) = (A, B);
    let mut chain: Vec<(i64, i64, i64, i64)> = Vec::new();
    while b != 0 { let t = a % b; chain.push((a, a / b, b, t)); a = b; b = t; }
    let g = a;
    println!("{:<38}{:>4}", "gcd(21, 15) by Euclid", g);
    for &(u, q, v, r) in &chain { println!("{} = {} x {} + {}", u, q, v, r); }
    let n = chain.len();
    let (mut p, mut s) = (1, -chain[n - 2].1);   // the last useful line: 3 = 15 - 2 x 6
    for &(_, q, _, _) in chain[..n - 2].iter().rev() { let (np, ns) = (s, p - s * q); p = np; s = ns; }
    println!("Bezout: 21 x {} + 15 x {} = {} + {} = {}", p, s, A * p, B * s, A * p + B * s);
    let (p2, s2) = (p + B / g, s - A / g);       // slide along by one whole step
    println!("one step along (21 x {} = 15 x {} = {}): 21 x {} + 15 x {} = {} + {} = {}", B / g, A / g, A * (B / g), p2, s2, A * p2, B * s2, A * p2 + B * s2);
    let mut mixes: Vec<i64> = Vec::new();
    for i in -9..=9 { for j in -9..=9 { mixes.push(A * i + B * j); } }
    let best = *mixes.iter().filter(|&&m| m > 0).min().unwrap();
    let hits = mixes.iter().filter(|&&m| m == 1 || m == 2).count();
    println!("{:<38}{:>4}", "smallest mix above zero, by search", best);
    println!("{:<38}{:>4}", "mixes that land on 1 or 2 litres", hits);
    println!("the three mistakes come out at {}, {} and {}", A * 2 + B * 3, B - 2 * A, A * 3 - B * 2);
    assert!(g == 3 && g == listing_gcd(A, B));
    assert!(p == -2 && s == 3 && A * p + B * s == g && A * p2 + B * s2 == g);
    assert!(best == g && !mixes.contains(&1) && !mixes.contains(&2));
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
gcd(21, 15) by Euclid                    3
21 = 1 x 15 + 6
15 = 2 x 6 + 3
6 = 2 x 3 + 0
Bezout: 21 x -2 + 15 x 3 = -42 + 45 = 3
one step along (21 x 5 = 15 x 7 = 105): 21 x 3 + 15 x -4 = 63 + -60 = 3
smallest mix above zero, by search       3
mixes that land on 1 or 2 litres         0
the three mistakes come out at 87, -27 and 33
ALL CHECKS PASS
```

Both outputs match line for line.

### Lean

Lean proves Bezout's identity for every two whole numbers that are not both 0, not just 21 and 15.

- Every mix of the two numbers is a multiple of their gcd, and some mix equals the gcd exactly.
- A target can be reached by a mix exactly when the gcd divides it.
- Sliding the counts by each jug over the gcd leaves the gcd again, so infinitely many pairs of counts work.
- The card's numbers check out: the chain, the counts −2 and 3, the slide to 3 and −4, and the three mistakes.
- The search agrees: counts from −9 to 9 never land on 1 or 2, and pouring in only never beats 15.

Running Euclid's chain step by step and printing each line is left to the Python and Rust checks.

<details>
<summary>The Lean proof, 104 lines</summary>

```lean
-- Bezout's identity: for whole numbers a and b, not both 0, every mix a × x + b × y is a multiple of their gcd, the gcd itself is such a mix, a target is reachable exactly when the gcd divides it, and the mixing counts are never unique.
import Mathlib.Data.Int.GCD
import Mathlib.Data.Int.Interval
import Mathlib.Data.Set.Finite.Basic
import Mathlib.Tactic.NormNum.GCD
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.LinearCombination

/-- Bezout's identity. Take two whole numbers a and b, not both 0. Any whole-number mix of them,
a × x + b × y (counts x and y may be negative), lands on a multiple of their gcd, and the gcd
itself is always reachable: some whole-number counts x and y give a × x + b × y = gcd(a, b). -/
theorem gcd_is_a_mix_and_every_mix_is_a_multiple_of_gcd (a b : ℤ) (h : a ≠ 0 ∨ b ≠ 0) :
    (∀ x y : ℤ, (Int.gcd a b : ℤ) ∣ a * x + b * y) ∧
      ∃ x y : ℤ, a * x + b * y = Int.gcd a b := by
  refine ⟨fun x y => ?_, ⟨Int.gcdA a b, Int.gcdB a b, (Int.gcd_eq_gcd_ab a b).symm⟩⟩
  exact dvd_add (Dvd.dvd.mul_right (Int.gcd_dvd_left a b) _) (Dvd.dvd.mul_right (Int.gcd_dvd_right a b) _)

/-- Measuring puzzles: with two whole numbers a and b, not both 0, a target c can be reached by
a whole-number mix a × x + b × y = c exactly when the gcd of a and b divides c. -/
theorem target_is_a_mix_iff_gcd_divides (a b c : ℤ) (h : a ≠ 0 ∨ b ≠ 0) :
    (∃ x y : ℤ, a * x + b * y = c) ↔ (Int.gcd a b : ℤ) ∣ c := by
  constructor
  · rintro ⟨x, y, rfl⟩
    exact dvd_add (Dvd.dvd.mul_right (Int.gcd_dvd_left a b) _) (Dvd.dvd.mul_right (Int.gcd_dvd_right a b) _)
  · rintro ⟨k, rfl⟩
    have := Int.gcd_eq_gcd_ab a b
    refine ⟨Int.gcdA a b * k, Int.gcdB a b * k, ?_⟩
    rw [this]
    ring

/-- There is never just one answer. If counts x and y give a × x + b × y = gcd(a, b), then sliding
x up by k × (b ÷ gcd) and y down by k × (a ÷ gcd) gives the gcd again, for every whole number k;
so infinitely many pairs of counts reach the gcd. -/
theorem bezout_counts_slide_and_are_infinitely_many (a b : ℤ) (h : a ≠ 0 ∨ b ≠ 0) :
    (∀ x y k : ℤ, a * x + b * y = Int.gcd a b →
        a * (x + k * (b / Int.gcd a b)) + b * (y - k * (a / Int.gcd a b)) = Int.gcd a b) ∧
      {p : ℤ × ℤ | a * p.1 + b * p.2 = Int.gcd a b}.Infinite := by
  have hg : (0 : ℤ) < Int.gcd a b := by
    exact_mod_cast Int.gcd_pos_iff.mpr h
  obtain ⟨a', ha⟩ : (Int.gcd a b : ℤ) ∣ a := Int.gcd_dvd_left a b
  obtain ⟨b', hb⟩ : (Int.gcd a b : ℤ) ∣ b := Int.gcd_dvd_right a b
  have hga : a / Int.gcd a b = a' := by
    exact Int.ediv_eq_of_eq_mul_right hg.ne' ha
  have hgb : b / Int.gcd a b = b' := by
    exact Int.ediv_eq_of_eq_mul_right hg.ne' hb
  have key : ∀ x y k : ℤ, a * x + b * y = Int.gcd a b →
      a * (x + k * (b / Int.gcd a b)) + b * (y - k * (a / Int.gcd a b)) = Int.gcd a b := by
    intro x y k hxy
    rw [hga, hgb]
    calc a * (x + k * b') + b * (y - k * a')
        = (a * x + b * y) + k * (a * b' - b * a') := by ring
      _ = _ := by
        have : a * b' - b * a' = 0 := by linear_combination b' * ha - a' * hb
        rw [this, hxy]; ring
  refine ⟨key, ?_⟩
  obtain ⟨x0, y0, h0⟩ := (gcd_is_a_mix_and_every_mix_is_a_multiple_of_gcd a b h).2
  have hne : b' ≠ 0 ∨ a' ≠ 0 := by
    by_contra hc
    rw [not_or, not_not, not_not] at hc
    have h1 : a = 0 := ha.trans (by rw [hc.2, mul_zero])
    have h2 : b = 0 := hb.trans (by rw [hc.1, mul_zero])
    rcases h with h | h
    · exact h h1
    · exact h h2
  refine Set.infinite_of_injective_forall_mem
    (f := fun k : ℤ => ((x0 + k * (b / Int.gcd a b), y0 - k * (a / Int.gcd a b)) : ℤ × ℤ))
    ?_ (fun k => key x0 y0 k h0)
  intro k l hkl
  simp only [Prod.mk.injEq, hga, hgb] at hkl
  obtain ⟨h1, h2⟩ := hkl
  rcases hne with hn | hn
  · have : k * b' = l * b' := by linarith
    exact mul_right_cancel₀ hn this
  · have : k * a' = l * a' := by linarith
    exact mul_right_cancel₀ hn this

-- The card's jugs: 21 and 15 litres, gcd 3.
example : Int.gcd 21 15 = 3 := by norm_num
-- Euclid's chain, down.
example : (21 : ℤ) = 1 * 15 + 6 ∧ (15 : ℤ) = 2 * 6 + 3 ∧ (6 : ℤ) = 2 * 3 + 0 := by decide
-- Walking back up: swap the 6 out, then gather.
example : (15 : ℤ) - 2 * (21 - 1 * 15) = 3 := by decide
example : (21 : ℤ) * (-2) + 15 * 3 = 3 ∧ (21 : ℤ) * (-2) = -42 ∧ (15 : ℤ) * 3 = 45 := by decide
-- Slide one step: 21 × 5 = 15 × 7 = 105, and the new pair 3, -4 also leaves 3.
example : (21 : ℤ) * 5 = 105 ∧ (15 : ℤ) * 7 = 105 := by decide
example : (21 : ℤ) * 3 + 15 * (-4) = 3 ∧ (21 : ℤ) * 3 = 63 ∧ (15 : ℤ) * (-4) = -60 := by decide
-- The three mistakes come out at 87, -27 and 33.
example : (21 : ℤ) * 2 + 15 * 3 = 87 ∧ (15 : ℤ) - 2 * 21 = -27 ∧ (21 : ℤ) * 3 + 15 * (-2) = 33 :=
  by decide
-- The search: counts from -9 to 9 never land on 1 or 2 litres, and 3 is reached.
example : ∀ i ∈ Finset.Icc (-9 : ℤ) 9, ∀ j ∈ Finset.Icc (-9 : ℤ) 9,
    21 * i + 15 * j ≠ 1 ∧ 21 * i + 15 * j ≠ 2 := by decide
-- Pouring in only (counts 0 to 9), the smallest mix above zero is 15, not 3.
example : ∀ i ∈ Finset.range 10, ∀ j ∈ Finset.range 10,
    0 < 21 * i + 15 * j → 15 ≤ 21 * i + 15 * j := by decide
-- Jugs 21 and 14: the gcd becomes 7, and 3 litres is impossible.
example : Int.gcd 21 14 = 7 ∧ ¬ ((7 : ℤ) ∣ 3) := by norm_num
-- 21 and 15 can leave 6 or 9 litres, never 4.
example : (3 : ℤ) ∣ 6 ∧ (3 : ℤ) ∣ 9 ∧ ¬ ((3 : ℤ) ∣ 4) := by decide

#print axioms gcd_is_a_mix_and_every_mix_is_a_multiple_of_gcd
#print axioms target_is_a_mix_iff_gcd_divides
#print axioms bezout_counts_slide_and_are_infinitely_many
```

</details>

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'gcd_is_a_mix_and_every_mix_is_a_multiple_of_gcd' depends on axioms: [propext, Quot.sound]
'target_is_a_mix_iff_gcd_divides' depends on axioms: [propext, Quot.sound]
'bezout_counts_slide_and_are_infinitely_many' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run. The asserts are pinned to these jugs, so one will fire.
> - **Make the jugs 21 and 14.** The gcd becomes 7, and 3 litres turns impossible.
> - **Ban throwing away.** Start the search at 0, not −9. The smallest mix above zero jumps to 15.

---

## The usual mistake

> [!warning]
> **Thinking both counts have to be positive.** Usually one is not. Throwing a jugful away is what lets 21 and 15 land on something as small as 3.
>
> - **Reading the counts off the chain.** The multipliers 1, 2, 2 down the chain (the quotients) are ingredients; only the walk back up turns them into −2 and 3.
> - **Reading the leftover as a jug.** Stop one line early and 3 = 15 − 2 × 6 is right. Write 21 where the 6 stands: 15 − 42 = −27.
> - **Expecting one right pair.** −2 and 3 is an answer, not the answer. So is 3 and −4.

---

## Where you meet it in real life

- **Undoing a multiplication on a clock.** What to multiply by to get back to 1 is exactly this, and needs gcd 1: [The modular inverse](../03-Clock%20Arithmetic/04-modular-inverse.md).
- **Sharing no factors.** With gcd 1 the mix lands on 1 itself, the hinge of [Coprime numbers](05-coprime-numbers.md) and [Euclid's lemma](06-euclids-lemma.md).
- **Measuring puzzles and gear teeth.** A target is reachable exactly when the gcd divides it: 21 and 15 can leave 6 or 9 litres, never 4, and two cogs line up on the multiples of their gcd.

> **Say it back**
> Pour copies of one number in, throw copies of the other away, and what is left is a multiple of their gcd — so 21 and 15 can never leave 1 or 2 litres. The gcd itself is always reachable: run Euclid down to it, then walk back up, swapping remainders out. Here, 21 × (−2) + 15 × 3 = 3. Slide by each jug over the gcd for another pair, forever.

---

## What this builds on

- [Greatest common divisor](01-gcd.md): the greatest common divisor, the number every mix is a multiple of.
- [Negative numbers](../../01-Foundations/01-Everyday%20Arithmetic/06-negative-numbers.md): a negative count is a jugful thrown away.
- [The three rearranging laws](../../01-Foundations/01-Everyday%20Arithmetic/05-arithmetic-laws.md): multiplying out the bracket, gathering like pieces.
- [Euclid's algorithm](03-euclidean-algorithm.md): the chain that finds the gcd and, backwards, the counts.

## Where this goes next

- [Coprime numbers](05-coprime-numbers.md): what changes when the gcd is 1 and the mix lands on 1.
- [Euclid's lemma](06-euclids-lemma.md): multiply that mix by another number; a prime dividing a product must divide a factor.
- [The modular inverse](../03-Clock%20Arithmetic/04-modular-inverse.md): the same counts, dividing on a clock.

Left open: when two numbers share no factor and the mix lands on 1, what can that 1 be used for?

---

## Sources

Verified 6 Sep 2026: every link below resolves.

- Euclid. *Elements*, Book VII, Proposition 2 (c. 300 BC), trans. David E. Joyce. [Clark University edition](https://mathcs.clarku.edu/~djoyce/elements/bookVII/propVII2.html). The chain, and Step 0, in Greek.
- Knuth, Donald E. *The Art of Computer Programming, Volume 2*, 3rd ed. Addison-Wesley, 1997. [Publisher page](https://www.informit.com/store/art-of-computer-programming-volume-2-seminumerical-9780201896848). Section 4.5.2, counts carried down the chain instead.
- O'Connor, J. J., and E. F. Robertson. "Étienne Bézout." *MacTutor History of Mathematics Archive*, University of St Andrews. [Biography](https://mathshistory.st-andrews.ac.uk/Biographies/Bezout/). Where the name came from.
