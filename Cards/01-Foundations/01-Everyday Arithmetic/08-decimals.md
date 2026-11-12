# Decimals: fractions whose bottom is a power of ten

[Syllabus](../../../SYLLABUS.md) → [Foundations](../README.md) → [Everyday Arithmetic](../README.md#s01) → Decimals

---

## General Overview

Petrol is $1.85 a litre. You fill a 42.5-litre tank. The receipt says **$78.63**.

The petrol was worth 78 dollars, 62 cents and half a cent. The pump picked a side and rounded up.

That dot is not a new kind of number. It is the columns from [Place value](01-place-value.md), carried right: after ones come tenths, hundredths, thousandths. Those columns make a fraction — 1.85 is 185 over 100 — so decimals obey the rules from [Fractions](07-fractions.md).

**A decimal is a fraction whose bottom is a power of ten — ten, a hundred, a thousand, and so on — so you can strip the point out, work in whole numbers, and put the point back at the end.**

**What kind of fact this is:** a definition, plus a method proved on this card in Why it works. Rounding a half cent up is a trade rule, not maths.

### The picture: the columns keep going right of the point

```
      tens    ones   .   tenths   hundredths   thousandths
        7       8    .      6          2            5
       10       1    .     0.1        0.01        0.001
```

Each column is ten times its right neighbour, or a tenth of its left one.

---

## The formula

Clear the points, multiply whole numbers, put the point back:

**1.85 × 42.5 = (185 ÷ 100) × (425 ÷ 10) = (185 × 425) ÷ 1000 = 78625 ÷ 1000 = 78.625**

**Read it aloud:** a decimal place is one column right of the point. Two places plus one makes three, so multiply 185 by 425 as whole numbers, then walk the point three columns left.

| Piece | Plain meaning | In our example |
| --- | --- | --- |
| the decimal point | where the ones column ends | the dot in 1.85 |
| the bottom | ten, a hundred, a thousand — one zero for each place right of the point | 1.85 is 185 over 100 |
| clearing the point | shift right until whole, counting shifts | 1.85 becomes 185 |
| putting it back | shift left by the shifts counted | 78625 becomes 78.625 |

### When it holds

- **Both decimals stop.** Each needs a last column, so it clears to a whole number. A third never stops (see the fold in Why it works), so there is no whole number to multiply.
- **The places are counted in both numbers.** Two from 1.85 and one from 42.5 make three. Put the point back two columns and the fill reads 786.25.
- **It is a multiplication.** Adding lines the points up instead (Step 4). Count places on an addition and the point lands in the wrong column.
- **Nothing is rounded before the end.** Round 42.5 litres to 43 first and the fill reads 79.55.

---

## Why it works

### Step 0: the columns never stopped

Nothing says the columns stop at the ones. Keep dividing by ten: tenths, hundredths, thousandths. So 1.85 is one whole, eight tenths, five hundredths — 185 hundredths, or 185 over 100.

### Step 1: clearing the point scales the problem

Shifting the point one column right multiplies a number by ten. Two shifts turn 1.85 into 185, a hundred times too big. One shift turns 42.5 into 425, ten times too big. Multiply the whole numbers, as [Multiplying and dividing](03-multiplying-and-dividing.md) does: 185 × 425 = 78625, a thousand times too big.

### Step 2: putting the point back undoes that

Shift the point three columns left and 78625 becomes **78.625**. Two places from 1.85 and one from 42.5: three come back out.

### Step 3: the fraction road, a second opinion

185 over 100, both parts divided by 5, is 37 over 20; 425 over 10 is 85 over 2. Multiply tops and bottoms: 3145 over 40, which reduces to **629 over 8**. Divide 629 by 8 and 78.625 comes back.

<details>
<summary>Why some fractions never land</summary>

Ten is two times five, so a bottom built only from twos and fives rebuilds as tens and stops. Here 8 is 2 × 2 × 2. A bottom of 3 cannot, so a third runs 0.333 forever — exact as a fraction, no last column.

</details>

### Step 4: adding stacks the points instead

Multiplying counts places; adding lines them up. Ones over ones, tenths over tenths, a zero wherever a number is short a column: 42 litres is 77.700, the half litre 0.925, and they stack.

---

## Worked numbers, by hand

The fill: 42.5 litres at $1.85.

| Step | Arithmetic | Value |
| --- | --- | --- |
| clear both points, three shifts | 1.85 → 185, 42.5 → 425 | 185, 425 |
| multiply whole numbers | 185 × 425 | 78625 |
| put the point back, three shifts | 78625 ÷ 1000 | 78.625 |
| the fraction road | 37/20 × 85/2 = 3145/40 | 629/8 |
| divide it out | 629 ÷ 8 | 78.625 |
| the adding road, stacked on the point | 77.700 + 0.925 | 78.625 |
| round to the cent | third place is a 5, so up | **78.63** |

Money stops at cents, so the receipt reads $78.63. Pumps round a half cent up by trade rule; science often rounds a half to the even digit instead.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Cutting at two places, not rounding | 78.62 | The half cent dropped, not decided |
| Putting the point back two columns | 786.25 | Three places in, three out |
| Rounding 42.5 up to 43 first | 79.55 | Round once, at the end |

The code prints all three.

---

## Code, from first principles, and it actually runs

Nothing is imported, and no decimal reaches the arithmetic. The fill runs in whole thousandths of a dollar, checked by the fraction road and by adding. The point is put back by hand.

### Python

```python
# Decimals -- the check behind the card.  Nothing is imported.  Petrol at
# $1.85 a litre into a 42.5-litre tank, and a receipt that has to land on a
# whole cent.  Three roads to the same total, all of them in whole numbers.
def row(name, value):
    print(f"{name:<36}{value:>9}")
def point(thousandths):            # 78625 -> "78.625", the point put back by hand
    return f"{thousandths // 1000}.{thousandths % 1000:03d}"
def money(cents):                  # 7863 -> "78.63"
    return f"{cents // 100}.{cents % 100:02d}"
price, litres = 185, 425           # $1.85 as hundredths, 42.5 litres as tenths
total = price * litres             # thousandths of a dollar
row("$1.85 is 185 over 100", price)
row("42.5 litres is 425 over 10", litres)
row("185 x 425, both whole numbers", total)
row("78625 over 1000, the point back", point(total))
top, bottom = 37 * 85, 20 * 2      # the fraction road, 3145 over 40
row("37/20 x 85/2 = 3145/40, reduced", f"{top // 5}/{bottom // 5}")
row("629 divided by 8", point(top * 1000 // bottom))
whole, half = price * 420, price * 5      # 42 litres, then the last half litre
row(f"42 litres {point(whole)}, half litre {point(half)}", point(whole + half))
cents = (total + 5) // 10          # to the nearest cent, a half cent goes up
row("the receipt, rounded to the cent", money(cents))
row("columns right of the point", "0.1 0.01 0.001")
print(f"mistakes: {money(total // 10)}, {money(total)}, "
      f"and 43 litres gives {money(price * 430 // 10)}")
assert total == 78625 and top * 1000 // bottom == total    # two roads, one answer
assert whole + half == total and top // 5 == 629 and bottom // 5 == 8
assert cents == 7863 and 629 * 125 == total   # 629/8 is 78.625, and 1/8 is 0.125
assert point(total) == "78.625" and money(cents) == "78.63"  # the printed strings
print("ALL CHECKS PASS")
```

**Ran 2026-09-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
$1.85 is 185 over 100                     185
42.5 litres is 425 over 10                425
185 x 425, both whole numbers           78625
78625 over 1000, the point back        78.625
37/20 x 85/2 = 3145/40, reduced         629/8
629 divided by 8                       78.625
42 litres 77.700, half litre 0.925     78.625
the receipt, rounded to the cent        78.63
columns right of the point          0.1 0.01 0.001
mistakes: 78.62, 786.25, and 43 litres gives 79.55
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Decimals -- the same check as decimals_check.py, in Rust.  No crates.
// Petrol at $1.85 a litre into a 42.5-litre tank, and a receipt that has to
// land on a whole cent.  Three roads to the same total, all in whole numbers.
fn row(name: &str, value: &str) { println!("{:<36}{:>9}", name, value); }
fn point(thousandths: i64) -> String {    // 78625 -> "78.625", the point put back
    format!("{}.{:03}", thousandths / 1000, thousandths % 1000)
}
fn money(cents: i64) -> String { format!("{}.{:02}", cents / 100, cents % 100) }
fn main() {
    let (price, litres) = (185i64, 425i64);   // $1.85 as hundredths, 42.5 as tenths
    let total = price * litres;               // thousandths of a dollar
    row("$1.85 is 185 over 100", &price.to_string());
    row("42.5 litres is 425 over 10", &litres.to_string());
    row("185 x 425, both whole numbers", &total.to_string());
    row("78625 over 1000, the point back", &point(total));
    let (top, bottom) = (37i64 * 85, 20i64 * 2);   // the fraction road, 3145 over 40
    row("37/20 x 85/2 = 3145/40, reduced", &format!("{}/{}", top / 5, bottom / 5));
    row("629 divided by 8", &point(top * 1000 / bottom));
    let (whole, half) = (price * 420, price * 5);  // 42 litres, then the half litre
    row(&format!("42 litres {}, half litre {}", point(whole), point(half)),
        &point(whole + half));
    let cents = (total + 5) / 10;             // to the nearest cent, a half goes up
    row("the receipt, rounded to the cent", &money(cents));
    row("columns right of the point", "0.1 0.01 0.001");
    println!("mistakes: {}, {}, and 43 litres gives {}",
             money(total / 10), money(total), money(price * 430 / 10));
    assert!(total == 78625 && top * 1000 / bottom == total);   // two roads, one answer
    assert!(whole + half == total && top / 5 == 629 && bottom / 5 == 8);
    assert!(cents == 7863 && 629 * 125 == total);  // 629/8 is 78.625, and 1/8 is 0.125
    assert!(point(total) == "78.625" && money(cents) == "78.63");  // the printed strings
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
$1.85 is 185 over 100                     185
42.5 litres is 425 over 10                425
185 x 425, both whole numbers           78625
78625 over 1000, the point back        78.625
37/20 x 85/2 = 3145/40, reduced         629/8
629 divided by 8                       78.625
42 litres 77.700, half litre 0.925     78.625
the receipt, rounded to the cent        78.63
columns right of the point          0.1 0.01 0.001
mistakes: 78.62, 786.25, and 43 litres gives 79.55
ALL CHECKS PASS
```

The two outputs match line for line. Neither language holds a decimal: thousandths in, strings out.

### Lean

Lean proves the method and the stopping rule for every decimal and every fraction, not just this fill.

- Multiply two stopping decimals as whole numbers, then put the point back by both counts of places added together.
- A fraction stops as a decimal exactly when its bottom, once reduced, is built only from twos and fives.
- A third never stops: no whole number over any power of ten equals one third.

Lean also checks the fill's whole-number sums, but the printed strings, like 78.625 and $78.63, are left to the Python and Rust checks.

<details>
<summary>The Lean proof, 120 lines</summary>

```lean
-- Decimals: multiplying two stopping decimals is multiplying their whole-number digits and putting the point back by the total count of places, a fraction stops as a decimal exactly when its bottom in lowest terms has no prime factor but 2 and 5, and so one third never stops.
import Mathlib.Data.Rat.Lemmas
import Mathlib.Data.Rat.Cast.Defs
import Mathlib.Data.Nat.Prime.Defs
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Ring
import Mathlib.Data.Nat.Factorization.Induction
import Mathlib.Algebra.Ring.Rat

/-- Helper: a whole number whose prime factors are all 2 or 5 divides some power of ten. -/
theorem aux_dvd_pow_ten (n : ℕ) :
    (∀ p : ℕ, p.Prime → p ∣ n → p = 2 ∨ p = 5) → ∃ k : ℕ, n ∣ 10 ^ k := by
  induction n using induction_on_primes with
  | zero =>
    intro h
    have := h 3 Nat.prime_three (dvd_zero 3)
    omega
  | one => intro _; exact ⟨0, by simp⟩
  | prime_mul p a hp ih =>
    intro h
    obtain ⟨k, hk⟩ := ih (fun q hq hqa => h q hq (dvd_mul_of_dvd_right hqa p))
    have hp' := h p hp (dvd_mul_right p a)
    have hp10 : p ∣ 10 := by
      rcases hp' with rfl | rfl <;> norm_num
    exact ⟨k + 1, by rw [pow_succ, mul_comm (10 ^ k)]; exact mul_dvd_mul hp10 hk⟩

#print axioms aux_dvd_pow_ten

/-- The card's method: a decimal with `m` places is the whole number `a` over ten to the `m`.
To multiply two of them, multiply the whole numbers and put the point back by both counts of
places together: `a` over ten to the `m`, times `b` over ten to the `n`, is `a × b` over ten to
the `m + n` (1.85 × 42.5 is 185 × 425 over a thousand). -/
theorem decimal_mul_clear_points (a b m n : ℕ) :
    ((a : ℚ) / 10 ^ m) * ((b : ℚ) / 10 ^ n) = ((a * b : ℕ) : ℚ) / 10 ^ (m + n) := by
  push_cast
  rw [div_mul_div_comm, pow_add]

/-- Why some fractions never land: a fraction can be written as a stopping decimal, a whole
number over a power of ten, exactly when its bottom in lowest terms is built only from twos and
fives. -/
theorem stops_as_decimal_iff_bottom_twos_and_fives (q : ℚ) :
    (∃ a : ℤ, ∃ m : ℕ, q = (a : ℚ) / 10 ^ m) ↔
      ∀ p : ℕ, p.Prime → p ∣ q.den → p = 2 ∨ p = 5 := by
  constructor
  · rintro ⟨a, m, hq⟩ p hp hpd
    have h1 : q * (10 : ℚ) ^ m = (a : ℚ) := by
      rw [hq]; field_simp
    have h8 : p ∣ 10 ^ m := by
      have h6 : (q.num : ℚ) * (10 ^ m : ℤ) = (a : ℚ) * q.den := by
        have : (q.num : ℚ) = q * q.den := (Rat.mul_den_eq_num q).symm
        rw [this]
        push_cast
        rw [← h1]; ring
      have h7 : q.num * (10 ^ m : ℤ) = a * q.den := by exact_mod_cast h6
      have h7' : (q.den : ℤ) ∣ q.num * (10 ^ m : ℤ) := ⟨a, by rw [h7]; ring⟩
      have h7'' : q.den ∣ q.num.natAbs * 10 ^ m := by
        have := Int.natAbs_dvd_natAbs.mpr h7'
        simpa [Int.natAbs_mul, Int.natAbs_pow] using this
      have hcop : q.den.Coprime q.num.natAbs := q.reduced.symm
      exact hpd.trans (hcop.dvd_of_dvd_mul_left h7'')
    have h9 : p ∣ 10 := hp.dvd_of_dvd_pow h8
    have h10 : p ∣ 2 * 5 := by simpa using h9
    rcases (Nat.Prime.dvd_mul hp).mp h10 with h | h
    · left; exact (Nat.prime_dvd_prime_iff_eq hp Nat.prime_two).mp h
    · right; exact (Nat.prime_dvd_prime_iff_eq hp Nat.prime_five).mp h
  · intro h
    obtain ⟨k, c, hc⟩ := aux_dvd_pow_ten q.den h
    refine ⟨q.num * c, k, ?_⟩
    have hd : (q.den : ℚ) ≠ 0 := by exact_mod_cast q.den_nz
    have hc' : (10 : ℚ) ^ k = q.den * c := by exact_mod_cast hc
    have hq : q = q.num / q.den := (Rat.num_div_den q).symm
    rw [hc']
    push_cast
    conv_lhs => rw [hq]
    have hc0 : (c : ℚ) ≠ 0 := by
      intro h0
      rw [h0] at hc'
      simp at hc'
    field_simp

/-- A third never stops: no whole number over any power of ten equals one third. -/
theorem one_third_never_stops :
    ¬ ∃ a : ℤ, ∃ m : ℕ, (1 / 3 : ℚ) = (a : ℚ) / 10 ^ m := by
  rintro ⟨a, m, h⟩
  have h1 : (10 : ℚ) ^ m = 3 * a := by
    field_simp at h; linarith
  have h2 : (10 : ℤ) ^ m = 3 * a := by exact_mod_cast h1
  have h3 : 3 ∣ 10 ^ m := by
    have : (3 : ℤ) ∣ 10 ^ m := ⟨a, h2⟩
    exact_mod_cast this
  have h4 : 3 ∣ 10 := Nat.prime_three.dvd_of_dvd_pow h3
  omega

-- The fill: $1.85 is 185 over 100, 42.5 litres is 425 over 10, and 185 × 425 = 78625.
example : 185 * 425 = 78625 := by norm_num
-- Two places plus one is three: 185/100 × 425/10 = 78625/1000.
example : (185 / 100 : ℚ) * (425 / 10) = 78625 / 1000 := by norm_num
example : (10 : ℕ) ^ 2 * 10 ^ 1 = 10 ^ 3 := by norm_num
-- The fraction road: 185/100 is 37/20, 425/10 is 85/2, and 37 × 85 over 20 × 2 is 3145/40.
example : (185 / 100 : ℚ) = 37 / 20 ∧ (425 / 10 : ℚ) = 85 / 2 := by norm_num
example : 37 * 85 = 3145 ∧ 20 * 2 = 40 := by norm_num
-- 3145/40 reduces to 629/8, and 629/8 is 78625 thousandths.
example : (3145 / 40 : ℚ) = 629 / 8 := by norm_num
example : (629 / 8 : ℚ) = 78625 / 1000 := by norm_num
example : 629 * 125 = 78625 := by norm_num
-- The bottom 8 is 2 × 2 × 2, built only from twos, so it lands.
example : 8 = 2 * 2 * 2 := by norm_num
-- The adding road in thousandths: 42 litres is 77700, the half litre 925, and they stack.
example : 185 * 420 = 77700 ∧ 185 * 5 = 925 ∧ 77700 + 925 = 78625 := by norm_num
-- The receipt in cents: a half cent goes up, so 78625 thousandths round to 7863 cents.
example : (78625 + 5) / 10 = 7863 := by norm_num
-- The mistakes: cutting gives 7862 cents; 43 litres gives 79550 thousandths, 7955 cents.
example : 78625 / 10 = 7862 := by norm_num
example : 185 * 430 = 79550 ∧ 185 * 430 / 10 = 7955 := by norm_num

#print axioms decimal_mul_clear_points
#print axioms stops_as_decimal_iff_bottom_twos_and_fives
#print axioms one_third_never_stops
```

</details>

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'aux_dvd_pow_ten' depends on axioms: [propext, Classical.choice, Quot.sound]
'decimal_mul_clear_points' depends on axioms: [propext, Classical.choice, Quot.sound]
'stops_as_decimal_iff_bottom_twos_and_fives' depends on axioms: [propext, Classical.choice, Quot.sound]
'one_third_never_stops' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it. The asserts are pinned to this fill, so expect one to fire.
> - **Shift the point one column too few.** In `point`, change both 1000s to 100 and the three-digit pad to two. The fill reads 786.25, the second mistake above, and the last assert fires.
> - **Make the tank whole.** Set `litres` to 430, meaning 43 litres. The total is 79.55, the fraction road disagrees, and the first assert fires.

---

## The usual mistake

> [!warning]
> **Lining the points up when you should be counting them.** Adding needs the points stacked. Multiplying does not: strip both points out, multiply, then walk the point back by as many places as you removed. Applied to a multiplication, the adding move is how 78.625 turns into 786.25.
>
> - Cutting instead of rounding: 78.62, and the half cent vanishes on every fill.
> - Rounding early: 43 litres instead of 42.5 gives 79.55, nearly a dollar out.
> - Storing money as decimals in code: it drifts. Store whole cents, as both scripts do.

---

## Where you meet it in real life

- **Every pump and till.** In the US, petrol is priced to a tenth of a cent, so nearly every fill lands between two cents and is rounded.
- **Payroll and invoices.** A rate like $1.85 an hour meets hours like 42.5, and the rounded cent must be accounted for.
- **Anything measured.** Litres and kilograms are read to a decimal place, and counting places carries into [Ratios and rates](09-ratios-and-rates.md).

> **Say it back**
> A decimal is place value carried right of the dot: tenths, hundredths, thousandths — a fraction whose bottom is a power of ten. To multiply, strip the points out, multiply whole numbers, then walk the point back by as many places as you removed: 185 × 425 is 78625, so 1.85 × 42.5 is 78.625. To add, stack the points. Money keeps two places, so the receipt says $78.63.

---

## What this builds on

- [Fractions](07-fractions.md): multiplying tops and bottoms, and reducing 3145/40 to 629/8.
- [Place value](01-place-value.md): each column is ten times its right neighbour; decimals continue past the ones.

## Where this goes next

- [Ratios and rates](09-ratios-and-rates.md): dollars per litre is a rate, built on the arithmetic here.
- [Irrational numbers](../02-The%20Number%20Line/03-irrational-numbers.md): decimals that never stop and never repeat, which no fraction can write.
- [Scientific notation](../03-Powers%2C%20Roots%20and%20Logarithms/04-scientific-notation.md): shifting the point, to write very large and very small numbers short.

This card leaves one question open: a decimal with no last column cannot be cleared to a whole number, so what exact number does it name?

---

## Sources

Verified 2026-11-11: every link below resolves to the publisher's page.

- O'Connor, J. J. and Robertson, E. F. "Simon Stevin." *MacTutor History of Mathematics Archive*, St Andrews. [MacTutor page](https://mathshistory.st-andrews.ac.uk/Biographies/Stevin/). Stevin's *De Thiende* (1585) argued decimal fractions into European use.
- National Institute of Standards and Technology. *NIST Handbook 44*, current edition. [NIST page](https://www.nist.gov/pml/owm/nist-handbook-44-current-edition). Section 3.30, the legal rulebook for retail fuel pumps in the US.
- Thompson, A. and Taylor, B. N. *NIST Special Publication 811*, 2008. [doi:10.6028/NIST.SP.811e2008](https://doi.org/10.6028/NIST.SP.811e2008). Section B.7, rounding: an exact half goes to the even digit.
