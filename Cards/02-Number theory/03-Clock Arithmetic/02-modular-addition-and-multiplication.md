# Adding and multiplying on the clock: reduce before or after, the answer agrees

[Syllabus](../../../SYLLABUS.md) → [Number theory](../README.md) → [Clock Arithmetic](../README.md#s03) → Adding and multiplying on the clock

---

## General Overview

A market stall works your order out by hand on the receipt: 47 boxes at 23 cents, written 47 × 23 = 1,081. You are not redoing that multiplication at the counter.

Add the digits instead. 47 gives 4 + 7 = 11, then 1 + 1 = 2. 23 gives 5. Multiply those: 2 × 5 = 10, then 1. Now the receipt's answer: 1 + 0 + 8 + 1 = 10, then 1.

Both roads end on 1, so the receipt passes. Shrinking a number means keeping the remainder — what is left once whole 9s are thrown away ([Congruence](01-congruence-mod-n.md)).

This is called **casting out nines**. It works because shrinking first then multiplying gives the same result as multiplying first then shrinking.

**Remainders add and multiply on their own. Reduce before or reduce after, you land on the same remainder.**

**What kind of fact this is:** a theorem, proved on this card in Why it works, for every clock, not only the 9-clock.

### The picture: two roads, one answer

```mermaid
flowchart LR
  A["47 × 23"] --> B["1,081"] --> C["1 + 0 + 8 + 1 = 10 → 1"]
  A --> D["reduce first: 2 × 5"] --> E["10 → 1"]
```

Top road: multiply then reduce. Bottom: reduce then multiply.

---

## The formula

On a 9-hour clock, 47 leaves 2 and 23 leaves 5. So:

**47 × 23 leaves the same remainder as 2 × 5 does.**

**47 + 23 leaves the same remainder as 2 + 5 does.**

**Read it aloud:** reduce 47 and 23 to 2 and 5, multiply those, and land where 1,081 lands.

The shorthand from [Congruence](01-congruence-mod-n.md): 47 ≡ 2 (mod 9) and 23 ≡ 5 (mod 9), so 47 × 23 ≡ 2 × 5 (mod 9) and 47 + 23 ≡ 2 + 5 (mod 9). We picked 9 because the digit trick comes free with it. The rule holds on any clock.

| Piece | Plain meaning | On the receipt |
| --- | --- | --- |
| the modulus | how many hours the clock has | 9 |
| a remainder | what is left when whole 9s are gone | 47 leaves 2 |
| ≡ … (mod 9) | same remainder on the 9-clock | 47 ≡ 2 (mod 9) |
| casting out nines | reduce both sides, compare | 2 × 5 gives 1, 1,081 gives 1 |

### When it holds

- **Adding and multiplying only.** Dividing does not carry over: 3 × 4 = 12 and 3 × 1 = 3 both leave 3, yet 4 is not 1.
- **Both sides reduced, on the same clock.** Compare 1,081 with 10 instead of 1 with 1, and a right receipt looks wrong.
- **Digit sums need a clock where 10 leaves 1.** The 9-clock is one. On a 10-clock, adding the digits does not give the remainder.

---

## Why it works

### Step 0: remainder plus a pile of 9s

47 = 45 + 2, and 45 is five 9s. 23 = 18 + 5, and 18 is two 9s. The pile is invisible on the 9-clock; the 2 and the 5 are what shows.

### Step 1: adding, the piles merge

47 + 23 = (45 + 2) + (18 + 5). Reorder the pieces ([The three rearranging laws](../../01-Foundations/01-Everyday%20Arithmetic/05-arithmetic-laws.md)) into (45 + 18) + (2 + 5). The first bracket is seven 9s: still invisible. What shows is 2 + 5 = 7. The long way: 47 + 23 = 70, seven 9s and 7 over. The same 7.

### Step 2: multiplying, every cross piece carries a 9

47 × 23 = (45 + 2) × (18 + 5). Multiply that out: four pieces, 45 × 18, 45 × 5, 2 × 18 and 2 × 5. The first three each carry a 45 or an 18, so each is a whole number of 9s — invisible. Only 2 × 5 = 10 is left, and 10 leaves 1. So 1,081 leaves 1.

Nothing there was about 9, or about 47 and 23. Split any two numbers into remainder plus pile: every piece except remainder-times-remainder carries the modulus and vanishes.

### Step 3: why digit sums work

10 leaves 1 on the 9-clock, since 10 = 9 + 1. So does 100, being eleven 9s + 1, and so does 1,000.

Read 1,081 by its columns ([Place value](../../01-Foundations/01-Everyday%20Arithmetic/01-place-value.md)): 1 thousand, 0 hundreds, 8 tens, 1 one. By Step 2 each column's worth can be swapped for the 1 it leaves, and by Step 1 the columns still add, so every digit contributes only itself: 1 + 0 + 8 + 1 = 10, then 1.

A digit total of 9 is remainder 0: nine hours on, the clock reads zero.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| 47 reduced | 4 + 7 = 11, then 1 + 1 | 2 |
| 23 reduced | 2 + 3 | 5 |
| the remainders multiplied | 2 × 5 = 10, then 1 + 0 | **1** |
| the receipt's answer | 47 × 23 | 1,081 |
| that answer reduced | 1 + 0 + 8 + 1 = 10, then 1 + 0 | **1** |
| the same, no digits | 1,081 take away 9, 120 times | 1 |
| the sum, both roads | 47 + 23 = 70, and 2 + 5 | 7 |

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Writing 1,801 for 1,081 | 1 | Same digits, same total: a swap is invisible here |
| Slipping to 1,061 | 8 | 8 is not 1, so the check fires |

The code prints both, and the cancelling trap below.

---

## Code, from first principles, and it actually runs

Nothing is imported. The receipt is checked by digit sums, then by a road that never looks at a digit: take 9 away until what is left is under 9. Then the mistakes.

### Python

```python
# Adding and multiplying on the clock -- the check behind the card.  Nothing is
# imported.  The receipt: 47 x 23 = 1,081, checked by casting out nines.  Digit
# sums are one road; taking 9s away from the whole number is the other.
def cast_out(n):                     # add the digits, again and again; 9 lands on 0
    while n > 9:
        n = sum(int(d) for d in str(n))
    return 0 if n == 9 else n
def take_nines_away(n):              # the same remainder, by subtracting 9 over and over
    while n >= 9:
        n -= 9
    return n
def row(name, value):
    print(f"{name:<42}{value:>6}")
row("47 by digit sums", cast_out(47))
row("23 by digit sums", cast_out(23))
row("2 x 5 = 10, by digit sums", cast_out(2 * 5))
row("47 x 23 the long way", 47 * 23)
row("1081 by digit sums", cast_out(47 * 23))
row("1081 by taking 9s away, 120 times", take_nines_away(47 * 23))
row("47 + 23 = 70, and 2 + 5 = 7, both leave", cast_out(47 + 23))
row("a swapped 1801 passes anyway", cast_out(1801))
row("a slipped 1061 is caught, not 1", cast_out(1061))
row("1061 by taking 9s away, 8 again", take_nines_away(1061))
row("3 x 4 = 12 and 3 x 1 = 3 both leave", cast_out(3 * 4))
assert cast_out(47) == 2 and cast_out(23) == 5 and cast_out(2 * 5) == 1 and 47 * 23 == 1081
assert cast_out(1081) == 1 and take_nines_away(1081) == 1 and cast_out(3 * 4) == 3
assert cast_out(47 + 23) == 7 and cast_out(2 + 5) == 7 and cast_out(1801) == 1 and cast_out(1061) == 8
assert take_nines_away(1061) == 8 and cast_out(9) == 0 and cast_out(18) == 0
print("ALL CHECKS PASS")
```

**Ran 2026-09-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
47 by digit sums                               2
23 by digit sums                               5
2 x 5 = 10, by digit sums                      1
47 x 23 the long way                        1081
1081 by digit sums                             1
1081 by taking 9s away, 120 times              1
47 + 23 = 70, and 2 + 5 = 7, both leave        7
a swapped 1801 passes anyway                   1
a slipped 1061 is caught, not 1                8
1061 by taking 9s away, 8 again                8
3 x 4 = 12 and 3 x 1 = 3 both leave            3
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Adding and multiplying on the clock -- the same check as
// modular_addition_and_multiplication_check.py, in Rust.  No crates.  The
// receipt: 47 x 23 = 1,081, checked by casting out nines.  Digit sums are one
// road; taking 9s away from the whole number is the other.
fn cast_out(mut n: i64) -> i64 {          // add the digits, again and again; 9 lands on 0
    while n > 9 {
        let (mut sum, mut rest) = (0, n);
        while rest > 0 { sum += rest % 10; rest /= 10; }
        n = sum;
    }
    if n == 9 { 0 } else { n }
}
fn take_nines_away(mut n: i64) -> i64 {   // the same remainder, by subtracting 9 over and over
    while n >= 9 { n -= 9; }
    n
}
fn row(name: &str, value: i64) { println!("{:<42}{:>6}", name, value); }
fn main() {
    row("47 by digit sums", cast_out(47));
    row("23 by digit sums", cast_out(23));
    row("2 x 5 = 10, by digit sums", cast_out(2 * 5));
    row("47 x 23 the long way", 47 * 23);
    row("1081 by digit sums", cast_out(47 * 23));
    row("1081 by taking 9s away, 120 times", take_nines_away(47 * 23));
    row("47 + 23 = 70, and 2 + 5 = 7, both leave", cast_out(47 + 23));
    row("a swapped 1801 passes anyway", cast_out(1801));
    row("a slipped 1061 is caught, not 1", cast_out(1061));
    row("1061 by taking 9s away, 8 again", take_nines_away(1061));
    row("3 x 4 = 12 and 3 x 1 = 3 both leave", cast_out(3 * 4));
    assert!(cast_out(47) == 2 && cast_out(23) == 5 && cast_out(2 * 5) == 1 && 47 * 23 == 1081);
    assert!(cast_out(1081) == 1 && take_nines_away(1081) == 1 && cast_out(3 * 4) == 3);
    assert!(cast_out(47 + 23) == 7 && cast_out(2 + 5) == 7 && cast_out(1801) == 1 && cast_out(1061) == 8);
    assert!(take_nines_away(1061) == 8 && cast_out(9) == 0 && cast_out(18) == 0);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
47 by digit sums                               2
23 by digit sums                               5
2 x 5 = 10, by digit sums                      1
47 x 23 the long way                        1081
1081 by digit sums                             1
1081 by taking 9s away, 120 times              1
47 + 23 = 70, and 2 + 5 = 7, both leave        7
a swapped 1801 passes anyway                   1
a slipped 1061 is caught, not 1                8
1061 by taking 9s away, 8 again                8
3 x 4 = 12 and 3 x 1 = 3 both leave            3
ALL CHECKS PASS
```

The two outputs match line for line: whole numbers, nothing to round.

### Lean

Lean proves the rule on every clock, for every pair of whole numbers, not just the receipt.

- Reduce two numbers first, then add or multiply and reduce: you land on the same remainder as reducing at the end.
- If two numbers leave the same remainders as two others on one clock, their sums match, and so do their products.
- On any clock where 10 leaves 1, a number leaves the same remainder as its digit sum.
- The receipt's numbers, exactly: 47 × 23 = 1,081, both roads landing on 1, the swapped 1,801, the slipped 1,061 and the dividing trap.

The two step-by-step roads, adding digits again and again and taking 9s away, are left to the Python and Rust checks.

```lean
-- Adding and multiplying on the clock: on every clock, reducing two whole numbers before adding or multiplying lands on the same remainder as reducing after, and on any clock where 10 leaves 1 a number leaves the same remainder as its digit sum.
import Mathlib.Data.Nat.ModEq
import Mathlib.Data.Nat.Digits.Lemmas
import Mathlib.Tactic.NormNum

/-- Remainders add and multiply on their own. On a clock with `n` hours, take any two whole
numbers `a` and `b`. Reduce them first and then add (or multiply) and reduce: you land on the
same remainder as adding (or multiplying) first and reducing at the end. -/
theorem reduce_before_or_after_same_remainder (n a b : ℕ) :
    (a + b) % n = (a % n + b % n) % n ∧ (a * b) % n = (a % n * (b % n)) % n := by
  exact ⟨Nat.add_mod a b n, Nat.mul_mod a b n⟩

/-- The card's formula, in the shorthand of congruence. If `a` leaves the same remainder as `a'`
and `b` leaves the same remainder as `b'` on the same clock, then `a + b` leaves the same
remainder as `a' + b'`, and `a × b` the same as `a' × b'`. -/
theorem congruent_numbers_add_and_multiply_to_congruent (n a a' b b' : ℕ)
    (ha : a ≡ a' [MOD n]) (hb : b ≡ b' [MOD n]) :
    a + b ≡ a' + b' [MOD n] ∧ a * b ≡ a' * b' [MOD n] := by
  exact ⟨ha.add hb, ha.mul hb⟩

/-- Why digit sums work. On any clock where 10 leaves the same remainder as 1 (the 9-clock is
one), every whole number leaves the same remainder as the sum of its decimal digits. -/
theorem digit_sum_same_remainder_when_ten_leaves_one (n m : ℕ) (h : 10 ≡ 1 [MOD n]) :
    m ≡ (Nat.digits 10 m).sum [MOD n] := by
  by_cases h1 : n = 1
  · subst h1
    exact Nat.modEq_one
  · have h10 : 10 % n = 1 := by
      have : 1 % n = 1 := by
        rcases Nat.eq_zero_or_pos n with h0 | h0
        · subst h0; rfl
        · exact Nat.mod_eq_of_lt (by omega)
      unfold Nat.ModEq at h
      omega
    exact Nat.modEq_digits_sum n 10 h10 m

-- The receipt: 47 leaves 2 and 23 leaves 5 on the 9-clock.
example : 47 % 9 = 2 ∧ 23 % 9 = 5 := by decide
-- Step 0: 47 = 45 + 2 with 45 five 9s; 23 = 18 + 5 with 18 two 9s.
example : 47 = 5 * 9 + 2 ∧ 23 = 2 * 9 + 5 := by decide
-- Multiplying: 47 × 23 = 1,081, and both roads land on 1.
example : 47 * 23 = 1081 ∧ 1081 % 9 = 1 ∧ (2 * 5) % 9 = 1 := by decide
-- 1,081 by taking 9s away 120 times leaves 1.
example : 1081 = 120 * 9 + 1 := by decide
-- Adding: 47 + 23 = 70, and 70 and 2 + 5 both leave 7.
example : 47 + 23 = 70 ∧ 70 % 9 = 7 ∧ (2 + 5) % 9 = 7 := by decide
-- Digit sums: 47 gives 11, then 2; 23 gives 5; 1,081 gives 10, then 1.
example : (Nat.digits 10 47).sum = 11 ∧ (Nat.digits 10 11).sum = 2 := by norm_num
example : (Nat.digits 10 23).sum = 5 := by norm_num
example : (Nat.digits 10 1081).sum = 10 ∧ (Nat.digits 10 10).sum = 1 := by norm_num
-- 10, 100 and 1,000 each leave 1 on the 9-clock.
example : 10 % 9 = 1 ∧ 100 % 9 = 1 ∧ 1000 % 9 = 1 := by decide
-- A digit total of 9 is remainder 0.
example : 9 % 9 = 0 ∧ 18 % 9 = 0 := by decide
-- The swapped 1,801 passes anyway; the slipped 1,061 leaves 8 and is caught.
example : 1801 % 9 = 1 ∧ 1801 ≠ 1081 := by decide
example : 1061 % 9 = 8 := by decide
-- Dividing does not carry over: 3 × 4 and 3 × 1 both leave 3, yet 4 and 1 do not match.
example : (3 * 4) % 9 = 3 ∧ (3 * 1) % 9 = 3 ∧ 4 % 9 ≠ 1 % 9 := by decide
-- On a 10-clock digit sums fail: 1,061 has digit sum 8, but leaves 1.
example : (Nat.digits 10 1061).sum = 8 ∧ 1061 % 10 = 1 := by norm_num
-- Try changing: 47 × 24 = 1,128 leaves 3, not 1.
example : 47 * 24 = 1128 ∧ 1128 % 9 = 3 := by decide

#print axioms reduce_before_or_after_same_remainder
#print axioms congruent_numbers_add_and_multiply_to_congruent
#print axioms digit_sum_same_remainder_when_ten_leaves_one
```

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'reduce_before_or_after_same_remainder' depends on axioms: [propext]
'congruent_numbers_add_and_multiply_to_congruent' depends on axioms: [propext]
'digit_sum_same_remainder_when_ten_leaves_one' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **Break the receipt.** Change every `47 * 23` to `47 * 24`. That is 1,128, which reduces to 3, not 1, and an assert fires.
> - **Move the clock.** In the second road, swap both 9s for 10s. It returns the last digit now: 1 for 1,081, right by luck, and 1 for 1,061, where the answer is 8. The assert fires. Digit sums are a 9 trick, not a 10 trick.

---

## The usual mistake

> [!warning]
> **Dividing.** Adding and multiplying carry over to remainders. Dividing does not. On the 9-clock 3 × 4 = 12 leaves 3, and 3 × 1 = 3 leaves 3 too. Cancel the 3 and you have said 4 and 1 are the same number. Division comes later, with a condition attached ([The modular inverse](04-modular-inverse.md)). Until then, do not cancel.
>
> - The check can catch a wrong answer, never confirm a right one. 1,801 passes and is still wrong.
> - A digit total of 9 is remainder 0, not 9.
> - Reducing one side only: comparing 10 with 1,081 and calling them different. Reduce both.

---

## Where you meet it in real life

- **Check digits.** A barcode's last digit is set so the whole code leaves a fixed remainder; a typo breaks it: [Barcode check digits](../05-Check%20Digits%2C%20Calendars%20and%20Cycles/01-barcode-check-digit.md).
- **Days and dates.** Weekday arithmetic is a 7-hour clock: [Day of the week for any date](../05-Check%20Digits%2C%20Calendars%20and%20Cycles/03-day-of-the-week.md).
- **Enormous powers.** Reducing at every step keeps the numbers small enough to compute: [Powers on the clock](../04-Powers%20on%20the%20Clock/01-modular-exponentiation.md).

> **Say it back**
> On a clock you keep only the remainder. Reduce two numbers and then add or multiply: you land where multiplying first and reducing at the end lands. Each number is its remainder plus a pile of the modulus, and every piece built from a pile is invisible. On the 9-clock every column's worth leaves 1, so reducing is adding the digits: 47 gives 2, 23 gives 5, 2 × 5 gives 1, 1,081 gives 1, receipt passes. Division is not part of the deal.

---

## What this builds on

- [Congruence](01-congruence-mod-n.md): what a remainder on a clock is, and what "leaves the same remainder as" means.
- [The three rearranging laws](../../01-Foundations/01-Everyday%20Arithmetic/05-arithmetic-laws.md): reordering and regrouping a sum or a product, which Steps 1 and 2 lean on.

## Where this goes next

- [Residue classes](03-residue-classes.md): the remainders as numbers in their own right, with their own small tables.
- [Powers on the clock](../04-Powers%20on%20the%20Clock/01-modular-exponentiation.md): multiplying on the clock over and over, so huge powers stay small.
- [Barcode check digits](../05-Check%20Digits%2C%20Calendars%20and%20Cycles/01-barcode-check-digit.md): this check, built into every barcode.
- [Day of the week for any date](../05-Check%20Digits%2C%20Calendars%20and%20Cycles/03-day-of-the-week.md): the 7-hour clock, and what day a date lands on.

This card leaves division open: when can you divide on the clock? [The modular inverse](04-modular-inverse.md) answers it.

---

## Sources

Verified 2026-11-11: every link below resolves to the publisher's page.

- Gauss, Carl Friedrich. *Disquisitiones Arithmeticae*. Trans. Arthur A. Clarke. Springer, 1986. [doi:10.1007/978-1-4939-7560-0](https://doi.org/10.1007/978-1-4939-7560-0). Articles 1 to 8: where congruences are first added and multiplied.
- Hardy, G. H., and E. M. Wright. *An Introduction to the Theory of Numbers*, 6th ed. Oxford University Press, 2008. [doi:10.1093/oso/9780199219858.001.0001](https://doi.org/10.1093/oso/9780199219858.001.0001). Chapter V, congruences.
