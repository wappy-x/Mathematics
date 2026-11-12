# Wilson's theorem: multiply everything below a prime and the clock shows -1, and only primes do this

[Syllabus](../../../SYLLABUS.md) → [Number theory](../README.md) → [Powers on the Clock](../README.md#s04) → Wilson's theorem

---

## General Overview

Six dancers, 1 to 6, on a floor marked as a 7-hour clock: hours 0 to 6, and a step past 6 lands on 0 ([Congruence](../03-Clock%20Arithmetic/01-congruence-mod-n.md)). Each must find the partner who undoes them: the one they multiply with to reach 1 ([The modular inverse](../03-Clock%20Arithmetic/04-modular-inverse.md)).

2 takes 4: 2 × 4 is 8, one clock and 1 over. 3 takes 5: 15 is two clocks and 1 over. 1 partners itself, and so does 6: 36 is five clocks and 1 over.

Multiply all six together. Each couple collapses to 1. 6 undoes itself, but it is in the row once, so it has nothing to cancel with. It survives, leaving 1 × 6, which is 6. The long way agrees: 720 is 102 clocks and 6 over.

6 is one short of a full clock, so the reading is -1 ([Negative numbers](../../01-Foundations/01-Everyday%20Arithmetic/06-negative-numbers.md)).

**Multiply every number below a prime clock size together and the clock reads -1 — and no clock that is not prime ever does that.**

**What kind of fact this is:** a theorem in both directions, proved on this card in Why it works.

Wilson claimed it in 1770; Lagrange proved it a year later.

### The picture: who undoes who

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Each dancer on a 7-hour clock, and the partner who undoes them"
    x-axis "The dancer" [1, 2, 3, 4, 5, 6]
    y-axis "The partner that multiplies with it to 1" 0 --> 6
    bar [1, 4, 5, 2, 3, 6]
```

Dancers 1 and 6 sit on their own numbers. The other four cross over: 2 with 4, 3 with 5. Two alone, the rest in couples: that is the proof.

---

## The formula

The clock is the statement:

**1 × 2 × 3 × 4 × 5 × 6 = 720 = 102 × 7 + 6, and 6 - 7 = -1, so 720 ≡ -1 (mod 7)**

**Read it aloud:** one times two, up to six, is 720: 102 whole sevens and 6 over, one short of 7, so the 7-clock reads -1.

The ≡ means the same reading; the (mod 7) says which clock.

| Piece | Plain meaning | Here |
| --- | --- | --- |
| the clock size | how many hours, and it must be prime | 7 |
| the row | 1 up to one below the clock size | 1, 2, 3, 4, 5, 6 |
| a partner | what multiplies with yours to land on 1 | 4 undoes 2 |
| the reading | what is left when whole clocks come off, also called -1 | 6 |

Call the clock size p, for prime: multiply every number from 1 up to p - 1 and the reading is -1 (mod p).

It runs backwards too: a reading of -1 means the clock size is prime.

### When it holds

- **A prime clock size.** It gives every dancer one partner. On an 8-clock, 2 and 4 both sit in the row and make a whole clock: the reading is 0.
- **The whole row.** Stop short and a couple breaks: leave out 4, and 2 has nothing to cancel with.
- **Backwards, every composite fails.** Most read 0; the 4-clock reads 2. Neither is -1.

---

## Why it works

### Step 0: on a prime clock every dancer has one undo

7 is prime, so no dancer from 1 to 6 shares a factor with it. That is the condition for an undo, and it is unique ([The modular inverse](../03-Clock%20Arithmetic/04-modular-inverse.md)). Partnering is mutual: if 4 undoes 2, 2 undoes 4.

### Step 1: only 1 and 6 are their own partner

A dancer is its own partner when multiplying it by itself reads 1. That means 7 divides the dancer times itself, minus 1 — one below the dancer times one above it. Take dancer 3: 3 × 3 - 1 is 8, which is 2 × 4.

7 is prime, so it divides one of those two pieces ([Euclid's lemma](../02-Greatest%20Common%20Divisor%20and%20Euclid%27s%20Algorithm/06-euclids-lemma.md)). One below is 0 only for dancer 1; one above is 7 only for dancer 6.

### Step 2: everyone else cancels in couples, and 1 × 6 is left

2, 3, 4 and 5 remain. Each has a partner in that group, not itself, so they split into two couples: (2, 4) and (3, 5), both reading 1.

Reordered, the row is 1 × (2 × 4) × (3 × 5) × 6. Both brackets read 1, so 1 × 6 survives: one short of the clock, -1.

### Step 3: why no other clock can do it

Take an 8-clock. Its row runs 1 to 7, so 2 and 4 both sit in it. They multiply to 8, a whole clock: the reading is 0 and stays 0. Any clock with room for both its factors goes that way.

A 9-clock has just one factor, 3, twice over. Still 0: 3 and its double 6 both sit in the row, and 3 × 6 = 18 is two whole clocks. Same for any prime times itself, above 4.

That leaves the 4-clock, too small to hold its factors apart: 1 × 2 × 3 is 6, which reads 2.

Fermat's little theorem shuffles these dancers ([Fermat's little theorem](02-fermats-little-theorem.md)); this one multiplies them together.

---

## Worked numbers, by hand

Both roads.

| Step | Arithmetic | Value |
| --- | --- | --- |
| the row, the long way | 1 × 2 × 3 × 4 × 5 × 6 | 720 |
| whole clocks off | 720 = 102 × 7 + 6 | 6 |
| as a negative | 6 - 7 | **-1** |
| first couple | 2 × 4 = 8 | 1 |
| second couple | 3 × 5 = 15 | 1 |
| the pairing road | 1 × 1 × 1 × 6 | **6** |

Same reading both ways, and the pairing road never passes 15 while the long way hits 720.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| On an 8-clock | 0 | 2 and 4 both sit in the row and multiply to 8 |
| On a 4-clock | 2 | the one composite that reads anything but 0 |

---

## Code, from first principles, and it actually runs

Nothing is imported. The row is multiplied in full, 720, then whole clocks come off. A second way cancels the couples. Two composite clocks follow.

### Python

```python
# Wilson's theorem -- the check behind the card.  Nothing is imported.  Six
# dancers, 1 to 6, on a 7-hour clock: each pairs off with the partner that
# undoes it, so the whole product reads 6, one short of a clock, which is -1.
CLOCK = 7
def product(top, clock):        # 1 x 2 x ... x top, whole clocks taken off
    out = 1
    for k in range(1, top + 1): out = (out * k) % clock
    return out

def row(name, value): print(f"{name:<48}{value:>5}")
partners = [b for a in range(1, CLOCK) for b in range(1, CLOCK) if (a * b) % CLOCK == 1]
alone = [a for a in range(1, CLOCK) if partners[a - 1] == a]          # 1 and 6
pairs = [(a, partners[a - 1]) for a in range(1, CLOCK) if a < partners[a - 1]]
plain = 1
for k in range(1, CLOCK): plain = plain * k                           # 720, in full
paired = 1
for a, b in pairs: paired = (paired * a * b) % CLOCK                  # each pair reads 1
for a in alone: paired = (paired * a) % CLOCK                         # 1 and 6 are left
row("1 x 2 x 3 x 4 x 5 x 6", plain)
row(f"{plain} = {plain // CLOCK} x {CLOCK} + {plain % CLOCK}, so the 7-clock reads", plain % CLOCK)
print("who undoes who, dancers 1 to 6:  " + " ".join(str(b) for b in partners))
print("the two pairs: " + ", ".join(f"{a} x {b} = {a * b} reads {a * b % CLOCK}" for a, b in pairs))
print(f"their own partner: 1 x 1 = 1 and 6 x 6 = {alone[1] * alone[1]}, both read 1")
row("the pairing road, 1 x 1 x 1 x 6, reads", paired)
row(f"that reading as a negative: {plain % CLOCK} - {CLOCK}", plain % CLOCK - CLOCK)
print(f"composites: an 8-clock (5040) reads {product(7, 8)}, a 4-clock (6) reads {product(3, 4)}")
assert plain == 720 and plain == 102 * CLOCK + 6
assert partners == [1, 4, 5, 2, 3, 6] and alone == [1, 6] and pairs == [(2, 4), (3, 5)]
assert paired == 6 and plain % CLOCK == 6 and product(7, 8) == 0 and product(3, 4) == 2
print("ALL CHECKS PASS")
```

**Ran 2026-09-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
1 x 2 x 3 x 4 x 5 x 6                             720
720 = 102 x 7 + 6, so the 7-clock reads             6
who undoes who, dancers 1 to 6:  1 4 5 2 3 6
the two pairs: 2 x 4 = 8 reads 1, 3 x 5 = 15 reads 1
their own partner: 1 x 1 = 1 and 6 x 6 = 36, both read 1
the pairing road, 1 x 1 x 1 x 6, reads              6
that reading as a negative: 6 - 7                  -1
composites: an 8-clock (5040) reads 0, a 4-clock (6) reads 2
ALL CHECKS PASS
```

### Rust

Same numbers, built with `rustc --edition 2021 -O`.

```rust
// Wilson's theorem -- the same check as the Python one, in Rust.  No crates.
// Six dancers, 1 to 6, on a 7-hour clock: each pairs off with the partner that
// undoes it, so the whole product reads 6, one short of a clock, which is -1.
const CLOCK: i64 = 7;

fn product(top: i64, clock: i64) -> i64 {   // 1 x 2 x ... x top, whole clocks taken off
    let mut out = 1;
    for k in 1..=top { out = (out * k) % clock; }
    out
}

fn row(name: &str, value: i64) { println!("{:<48}{:>5}", name, value); }

fn main() {
    let partners: Vec<i64> = (1..CLOCK)
        .map(|a| (1..CLOCK).find(|&b| (a * b) % CLOCK == 1).unwrap()).collect();
    let alone: Vec<i64> = (1..CLOCK).filter(|&a| partners[(a - 1) as usize] == a).collect();
    let pairs: Vec<(i64, i64)> = (1..CLOCK).filter(|&a| a < partners[(a - 1) as usize])
        .map(|a| (a, partners[(a - 1) as usize])).collect();
    let mut plain = 1i64;
    for k in 1..CLOCK { plain = plain * k; }                          // 720, in full
    let mut paired = 1i64;
    for &(a, b) in pairs.iter() { paired = (paired * a * b) % CLOCK; }  // each pair reads 1
    for &a in alone.iter() { paired = (paired * a) % CLOCK; }         // 1 and 6 are left
    row("1 x 2 x 3 x 4 x 5 x 6", plain);
    row(&format!("{} = {} x {} + {}, so the 7-clock reads", plain, plain / CLOCK, CLOCK, plain % CLOCK), plain % CLOCK);
    let who: Vec<String> = partners.iter().map(|b| b.to_string()).collect();
    println!("who undoes who, dancers 1 to 6:  {}", who.join(" "));
    let two: Vec<String> = pairs.iter()
        .map(|&(a, b)| format!("{} x {} = {} reads {}", a, b, a * b, a * b % CLOCK)).collect();
    println!("the two pairs: {}", two.join(", "));
    println!("their own partner: 1 x 1 = 1 and 6 x 6 = {}, both read 1", alone[1] * alone[1]);
    row("the pairing road, 1 x 1 x 1 x 6, reads", paired);
    row(&format!("that reading as a negative: {} - {}", plain % CLOCK, CLOCK), plain % CLOCK - CLOCK);
    println!("composites: an 8-clock (5040) reads {}, a 4-clock (6) reads {}", product(7, 8), product(3, 4));
    assert!(plain == 720 && plain == 102 * CLOCK + 6);
    assert!(partners == vec![1, 4, 5, 2, 3, 6] && alone == vec![1, 6] && pairs == vec![(2, 4), (3, 5)]);
    assert!(paired == 6 && plain % CLOCK == 6 && product(7, 8) == 0 && product(3, 4) == 2);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
1 x 2 x 3 x 4 x 5 x 6                             720
720 = 102 x 7 + 6, so the 7-clock reads             6
who undoes who, dancers 1 to 6:  1 4 5 2 3 6
the two pairs: 2 x 4 = 8 reads 1, 3 x 5 = 15 reads 1
their own partner: 1 x 1 = 1 and 6 x 6 = 36, both read 1
the pairing road, 1 x 1 x 1 x 6, reads              6
that reading as a negative: 6 - 7                  -1
composites: an 8-clock (5040) reads 0, a 4-clock (6) reads 2
ALL CHECKS PASS
```

### Lean

Lean proves the card's three facts for every clock size, not just 7.

- A clock size of at least 2 is prime exactly when its row reads -1.
- On a clock that is not prime, the row reads 0, except the 4-clock, where it reads 2.
- On a prime clock, only 1 and -1 are their own partner.
- It also re-checks the card's numbers: 720, the partner table, the pairing road, and the 4-, 5-, 8-, 9- and 12-clocks.

Printing the output line by line is left to the Python and Rust checks.

```lean
-- Wilson's theorem: for a clock size n of at least 2, the product 1 × 2 × ... × (n - 1) reads -1 on the n-clock exactly when n is prime, every composite clock reads 0 except the 4-clock, which reads 2, and on a prime clock only 1 and -1 are their own partner.
import Mathlib.NumberTheory.Wilson
import Mathlib.Tactic.NormNum.Basic

open Nat

/-- Helper: for 0 < a < b, a * b divides b!. -/
theorem helper_mul_dvd_factorial (a b : ℕ) (ha : 0 < a) (hab : a < b) : a * b ∣ b ! := by
  obtain ⟨c, rfl⟩ : ∃ c, b = c + 1 := ⟨b - 1, by omega⟩
  have h : a ∣ c ! := Nat.dvd_factorial ha (by omega)
  rw [Nat.factorial_succ, mul_comm a]
  exact mul_dvd_mul_left _ h

/-- Helper: a composite n other than 4 divides (n - 1)!. -/
theorem helper_composite_dvd_factorial (n : ℕ) (hn : 2 ≤ n) (hnp : ¬ n.Prime) (h4 : n ≠ 4) :
    n ∣ (n - 1)! := by
  have hn1 : n ≠ 1 := by omega
  have hap : (n.minFac).Prime := Nat.minFac_prime hn1
  have ha2 : 2 ≤ n.minFac := hap.two_le
  have hab : n.minFac ≤ n / n.minFac := Nat.minFac_le_div (by omega) hnp
  obtain ⟨a, b, hab', ha2', hb, hn'⟩ : ∃ a b : ℕ, a ≤ b ∧ 2 ≤ a ∧ n = a * b ∧ True :=
    ⟨n.minFac, n / n.minFac, hab, ha2, (Nat.mul_div_cancel' (Nat.minFac_dvd n)).symm, trivial⟩
  have hbn : b < n := by rw [hb]; nlinarith
  rcases Nat.lt_or_ge a b with h | h
  · have h1 : a * b ∣ b ! := helper_mul_dvd_factorial a b (by omega) h
    have h2 : b ! ∣ (n - 1)! := Nat.factorial_dvd_factorial (by omega)
    rw [hb] at h2 ⊢
    exact h1.trans h2
  · have hba : b = a := le_antisymm h hab'
    rw [hba] at hb hbn
    have ha3 : 3 ≤ a := by
      by_contra hlt
      have : a = 2 := by omega
      apply h4; rw [hb, this]
    have h1 : a * (2 * a) ∣ (2 * a)! := helper_mul_dvd_factorial a (2 * a) (by omega) (by omega)
    have h5 : 2 * a + 1 ≤ n := by nlinarith
    have h2 : (2 * a)! ∣ (n - 1)! := Nat.factorial_dvd_factorial (by omega)
    have h3 : n ∣ a * (2 * a) := by rw [hb]; exact ⟨2, by ring⟩
    exact h3.trans (h1.trans h2)

#print axioms helper_mul_dvd_factorial
#print axioms helper_composite_dvd_factorial

/-- Wilson's theorem, both directions. Take a clock size n of at least 2. Multiply every number
from 1 up to n - 1 together, that is (n - 1)!. The n-clock reads -1 exactly when n is prime:
every prime clock reads -1, and no clock that is not prime ever does. -/
theorem prime_iff_product_below_reads_neg_one (n : ℕ) (hn : 2 ≤ n) :
    n.Prime ↔ (((n - 1)! : ℕ) : ZMod n) = -1 := by
  exact Nat.prime_iff_fac_equiv_neg_one (by omega)

/-- Backwards, every composite fails. On a clock size n of at least 2 that is not prime, the
product 1 × 2 × ... × (n - 1) reads 0, except on the 4-clock, where it reads 2. -/
theorem composite_clock_reads_zero_or_two (n : ℕ) (hn : 2 ≤ n) (hnp : ¬ n.Prime) :
    (((n - 1)! : ℕ) : ZMod n) = if n = 4 then 2 else 0 := by
  have h0 : n ≠ 1 := by omega
  by_cases h4 : n = 4
  · subst h4
    simp only [ite_true]
    decide
  · simp only [h4, ite_false]
    have := helper_composite_dvd_factorial n hn hnp h4
    exact (ZMod.natCast_eq_zero_iff _ _).mpr this

/-- Step 1: on a prime clock, the only numbers that are their own partner (times themselves
read 1) are 1 and the top hour p - 1, which is -1. -/
theorem own_partner_iff_one_or_neg_one (p : ℕ) (hp : p.Prime) (x : ZMod p) :
    x * x = 1 ↔ x = 1 ∨ x = -1 := by
  have := Fact.mk hp
  constructor
  · intro h
    have h' : (x - 1) * (x + 1) = 0 := by linear_combination h
    rcases mul_eq_zero.mp h' with h1 | h1
    · left; linear_combination h1
    · right; linear_combination h1
  · rintro (h | h) <;> subst h <;> ring

-- The row on the 7-clock: 1 × 2 × 3 × 4 × 5 × 6 = 720 = 102 × 7 + 6, and 6 - 7 = -1.
example : 1 * 2 * 3 * 4 * 5 * 6 = 720 ∧ 6 ! = 720 := by decide
example : 720 = 102 * 7 + 6 ∧ 720 % 7 = 6 := by decide
example : (6 : ℤ) - 7 = -1 := by norm_num
example : ((720 : ℕ) : ZMod 7) = -1 := by decide
-- Who undoes who on the 7-clock: 2 × 4 = 8 and 3 × 5 = 15 read 1; 1 × 1 = 1 and 6 × 6 = 36 read 1.
example : 2 * 4 = 8 ∧ 8 % 7 = 1 ∧ 3 * 5 = 15 ∧ 15 % 7 = 1 := by decide
example : 1 * 1 % 7 = 1 ∧ 6 * 6 = 36 ∧ 36 % 7 = 1 := by decide
-- The partner table: dancers 1 to 6 have partners 1, 4, 5, 2, 3, 6.
example : (1 * 1) % 7 = 1 ∧ (2 * 4) % 7 = 1 ∧ (3 * 5) % 7 = 1 ∧ (4 * 2) % 7 = 1 ∧
    (5 * 3) % 7 = 1 ∧ (6 * 6) % 7 = 1 := by decide
-- The pairing road: 1 × (2 × 4) × (3 × 5) × 6 reads 6.
example : (1 * (2 * 4) * (3 * 5) * 6) % 7 = 6 := by decide
-- Dancer 3: 3 × 3 - 1 = 8 = 2 × 4.
example : 3 * 3 - 1 = 8 ∧ 8 = 2 * 4 := by decide
-- An 8-clock: 7! = 5040 reads 0. A 4-clock: 3! = 6 reads 2.
example : 7 ! = 5040 ∧ 5040 % 8 = 0 := by decide
example : 3 ! = 6 ∧ 6 % 4 = 2 := by decide
-- A 9-clock: 3 × 6 = 18 is two whole clocks, and 8! reads 0.
example : 3 * 6 = 18 ∧ 18 = 2 * 9 ∧ 8 ! % 9 = 0 := by decide
-- A 5-clock: 1 × 2 × 3 × 4 = 24 is four clocks and 4 over, one short of 5.
example : 4 ! = 24 ∧ 24 = 4 * 5 + 4 ∧ ((24 : ℕ) : ZMod 5) = -1 := by decide
-- The numbers with an undo on an 8-clock (1, 3, 5, 7) and a 12-clock (1, 5, 7, 11) multiply to 1.
example : (1 * 3 * 5 * 7) % 8 = 1 ∧ (1 * 5 * 7 * 11) % 12 = 1 := by decide

#print axioms prime_iff_product_below_reads_neg_one
#print axioms composite_clock_reads_zero_or_two
#print axioms own_partner_iff_one_or_neg_one
```

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'helper_mul_dvd_factorial' depends on axioms: [propext, Quot.sound]
'helper_composite_dvd_factorial' depends on axioms: [propext, Classical.choice, Quot.sound]
'prime_iff_product_below_reads_neg_one' depends on axioms: [propext, Classical.choice, Quot.sound]
'composite_clock_reads_zero_or_two' depends on axioms: [propext, Classical.choice, Quot.sound]
'own_partner_iff_one_or_neg_one' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it. The asserts and the printed labels are pinned to the 7-clock: expect an assert to fire, and the labels to lie.
> - **Move to a 5-clock.** The row is 1 × 2 × 3 × 4 = 24: four clocks and 4 over, one short of 5. Still -1.
> - **Break the prime.** Set the clock to 9. Dancers 3 and 6 share its factor 3 and have no partner, so the script trips before printing.

---

## The usual mistake

> [!warning]
> **Expecting the answer 1.** Fermat's theorem sends a number round a loop back to 1. This one reads 6 on the 7-clock: one short, not one over.
>
> - **Thinking -1 is not 6.** Same hour, two names. -1 is the useful one: it holds on every prime clock.
> - **Believing every composite reads 0.** The 4-clock reads 2, alone among them, and still fails.
> - **Using it on big primes.** It never lies, but the row for a 40-digit prime is unwritable: [The Fermat test](../06-Codes%20and%20Secrets/04-fermat-test-and-carmichael.md).

---

## Where you meet it in real life

- **Proving a number prime on paper.** An exact test both ways, no liars to rule out — unlike Fermat's ([Primes and composites](../01-Divisibility%20and%20Primes/05-primes-and-composites.md), [The Fermat test](../06-Codes%20and%20Secrets/04-fermat-test-and-carmichael.md)).
- **Square roots on a prime clock.** Step 1 stands alone: only 1 and the top hour are their own partner, so a square root has two answers or none.
- **Clocks where every number has an undo.** The pairing still runs, but more dancers are their own partner, so the answer changes: an 8-clock and a 12-clock read 1. Only 4, powers of one prime, and twice those, read -1 ([The order of a number and primitive roots](05-order-and-primitive-roots.md)).

> **Say it back**
> Line up 1 to 6. Each has one partner it multiplies with to reach 1 on the 7-clock, and only 1 and 6 are their own partner. So the row folds into couples reading 1, leaving 1 × 6 = 6, one short of the clock: -1. A clock that is not prime never gets there: its own factors sit in the row and spoil it. A reading of -1 proves a prime — exact, and far too slow to use.

---

## What this builds on

- [The modular inverse](../03-Clock%20Arithmetic/04-modular-inverse.md): the partner that undoes a number, and why a prime clock gives everyone one.
- [Euclid's lemma](../02-Greatest%20Common%20Divisor%20and%20Euclid%27s%20Algorithm/06-euclids-lemma.md): a prime dividing a product divides one of its pieces — Step 1.
- [Negative numbers](../../01-Foundations/01-Everyday%20Arithmetic/06-negative-numbers.md): why one short of a full clock is written -1.

## Where this goes next

- [The Fermat test](../06-Codes%20and%20Secrets/04-fermat-test-and-carmichael.md): a quick primality test, and the numbers that fool it.
- [The Miller-Rabin test](../06-Codes%20and%20Secrets/05-miller-rabin.md): the test RSA actually uses. RSA locks messages with two large primes ([RSA in outline](../06-Codes%20and%20Secrets/03-rsa-in-outline.md)).

Left open: is there a prime test as exact as this one, but fast enough for big numbers?

---

## Sources

Verified 2026-11-11: every link below resolves to the publisher's page.

- Lagrange, Joseph-Louis. "Démonstration d'un théorème nouveau concernant les nombres premiers" (1771), in *Œuvres de Lagrange*, tome 3, Gauthier-Villars, 1869. [Internet Archive](https://archive.org/details/uvresdelagrange03lagr). The first published proof.
- Ireland, Kenneth, and Michael Rosen. *A Classical Introduction to Modern Number Theory*, 2nd ed. Springer, 1990. [doi:10.1007/978-1-4757-2103-4](https://link.springer.com/book/10.1007/978-1-4757-2103-4). Chapter 4.
- Apostol, Tom M. *Introduction to Analytic Number Theory*. Springer, 1976. [doi:10.1007/978-1-4757-5579-4](https://link.springer.com/book/10.1007/978-1-4757-5579-4). Section 5.6 proves it from Lagrange's theorem on polynomial congruences.
