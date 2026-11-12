# Counting divisors: read how many divisors a number has straight off its prime factorisation

[Syllabus](../../../SYLLABUS.md) → [Number theory](../README.md) → [Divisibility and Primes](../README.md#s01) → Counting divisors

---

## General Overview

A box holds 96 floor tiles. Lay all 96 in one rectangle — every tile used, no gaps, no cutting. How many shapes? Turning a shape round is not a new shape.

You start listing. 1 by 96. 2 by 48. 3 by 32. 4 by 24. 6 by 16. 8 by 12. Six, and you are fairly sure that is all.

Each side of each shape divides 96 with nothing left over — it is a **divisor** ([Divides](01-divides.md)). So the question is how many divisors 96 has.

The prime factorisation answers it without listing. A prime has no divisor but 1 and itself, and the prime factorisation breaks a number into primes ([Prime factorisation](07-prime-factorisation.md)). 96 is 2 × 2 × 2 × 2 × 2 × 3: five 2s and one 3. Add one to each count and multiply: (5 + 1) × (1 + 1) = 12 divisors, which pair off into six rectangles.

**Add one to how many times each prime appears in the factorisation, multiply those numbers together, and that is how many divisors there are.**

**What kind of fact this is:** a theorem, proved on this card in Why it works: each divisor is one choice per prime.

### The picture: the 12 divisors of 96

| | no 2s | one | two | three | four | five 2s |
| --- | --- | --- | --- | --- | --- | --- |
| **no 3** | 1 | 2 | 4 | 8 | 16 | 32 |
| **one 3** | 3 | 6 | 12 | 24 | 48 | 96 |

Every divisor sits in exactly one cell. Six columns by two rows is 12.

---

## The formula

On the box, and on a second number:

**96 = 2 × 2 × 2 × 2 × 2 × 3, so the count is (5 + 1) × (1 + 1) = 12.**

**360 = 2 × 2 × 2 × 3 × 3 × 5, so the count is (3 + 1) × (2 + 1) × (1 + 1) = 4 × 3 × 2 = 24.**

**Read it aloud:** five 2s give six choices, one 3 gives two choices, and six times two is twelve divisors.

| Piece | Plain meaning | In our box of 96 |
| --- | --- | --- |
| a prime | no divisor but 1 and itself ([Primes and composites](05-primes-and-composites.md)) | 2 and 3 |
| how often it appears | count it in the factorisation | five 2s, one 3 |
| one more than that count | the choices for that prime, counting the choice of taking none | 6 and 2 |
| a divisor | goes in with nothing left over ([Divides](01-divides.md)) | any cell of the grid |

### When it holds

- **The number is broken all the way down to primes.** Stop at 4 × 24 and the counts mean nothing.
- **Divisors means positive divisors.** Count the negative ones too and the answer doubles.
- **Shapes are half the divisors only when the number is not a square.** A square has one side that pairs with itself, so its count is odd.

---

## Why it works

### Step 0: a divisor is built from the same primes

Break any divisor of 96 into primes. They come from 96's own pile: a number has one prime factorisation and no other ([Prime factorisation](07-prime-factorisation.md)). So a divisor of 96 is built from 2s and 3s — never more than five 2s, never more than one 3.

### Step 1: one decision per prime, and decisions multiply

How many 2s: nought up to five. Six answers. How many 3s: nought or one. Two answers. Each pair of answers builds exactly one divisor — three 2s and one 3 builds 24, none of either builds 1, all of them build 96.

Six ways to answer the first, two for each: 6 × 2 = 12 ([Multiplying and dividing](../../01-Foundations/01-Everyday%20Arithmetic/03-multiplying-and-dividing.md)). The added one is the choice of taking none of a prime — miss it and you lose the no-2s column and the no-3 row: seven divisors, 1 among them.

### Step 2: divisors pair off, so shapes are half of them

Divisors pair off, each pair multiplying to 96: 1 with 96, 2 with 48, 3 with 32, 4 with 24, 6 with 16, 8 with 12. A rectangle is one pair, so 12 divisors make 6 shapes.

<details>
<summary>Adding the divisors up, not just counting them</summary>

The grid adds up as easily as it counts. The no-3 row is 1 + 2 + 4 + 8 + 16 + 32 = 63. The one-3 row is that 63 with a 3 in every term: 63 × 3. Together, 63 × 4 = 252, the sum of all 12 divisors of 96 — where [Perfect numbers and Mersenne primes](../07-For%20the%20Curious/02-perfect-numbers-and-mersenne.md) starts.

</details>

---

## Worked numbers, by hand

The box, then 360.

| Step | Arithmetic | Value |
| --- | --- | --- |
| break 96 into primes | 2 × 2 × 2 × 2 × 2 × 3 | 96 |
| add one to each prime's count | 5 + 1, 1 + 1 | 6 and 2 |
| multiply | 6 × 2 | **12 divisors** |
| pair into rectangles | 12 ÷ 2 | **6 shapes** |
| the same run on 360 | (3 + 1) × (2 + 1) × (1 + 1) | **24 divisors** |

Six rectangles, each using the whole box.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Multiplying the counts, forgetting the one | 5 | 5 × 1 leaves out taking none |
| Adding the choices, not multiplying | 8 | Every choice of 2s goes with every choice of 3s, so multiply |
| Dropping 1 and 96 | 10 | Both divide 96 |

The code prints all three.

---

## Code, from first principles, and it actually runs

Nothing is imported. The count is read off the factorisation, then checked against the slow road: every number from 1 to 96 tried, keeping those that go in. The roads share no working.

### Python

```python
# Counting divisors -- the check behind the card.  Nothing is imported.  A box
# of 96 tiles: 96 = 2 x 2 x 2 x 2 x 2 x 3.  The count is read off that prime
# factorisation, then checked the slow way, by trying every number up to 96.
def primes_of(n):                    # 96 -> [2, 2, 2, 2, 2, 3]
    out, d = [], 2
    while d * d <= n:
        while n % d == 0: out.append(d); n //= d
        d += 1
    return out + ([n] if n > 1 else [])
def by_formula(n):                   # one more than each prime's count, multiplied
    total, ps = 1, primes_of(n)
    for p in sorted(set(ps)): total *= ps.count(p) + 1
    return total
def by_hand(n): return [d for d in range(1, n + 1) if n % d == 0]   # the slow road
def row(name, value): print(f"{name:<44}{value:>4}")
print("96 = " + " x ".join(str(p) for p in primes_of(96)))
row("(5 + 1) x (1 + 1)", by_formula(96))
row("divisors of 96, the slow way", len(by_hand(96)))
print("divisors of 96: " + ", ".join(str(d) for d in by_hand(96)))
print("the grid, no 3:  " + ", ".join(str(d) for d in by_hand(96) if d % 3))
print("the grid, one 3: " + ", ".join(str(d) for d in by_hand(96) if d % 3 == 0))
row("rectangle shapes, 12 / 2", by_formula(96) // 2)
row("360 = 2 x 2 x 2 x 3 x 3 x 5, (3 + 1) x (2 + 1) x (1 + 1)", by_formula(360))
row("divisors of 360, the slow way", len(by_hand(360)))
row("sum of the divisors of 96, 63 x 4", sum(by_hand(96)))
print(f"the three mistakes come out at {5 * 1}, {(5 + 1) + (1 + 1)} and {by_formula(96) - 2}")
assert by_formula(96) == len(by_hand(96)) == 12 and by_hand(96)[-1] == 96
assert sorted([d for d in by_hand(96) if d % 3] + [d for d in by_hand(96) if d % 3 == 0]) == by_hand(96)
assert by_formula(360) == len(by_hand(360)) == 24 and sum(by_hand(96)) == 63 * 4
print("ALL CHECKS PASS")
```

**Ran 2026-09-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
96 = 2 x 2 x 2 x 2 x 2 x 3
(5 + 1) x (1 + 1)                             12
divisors of 96, the slow way                  12
divisors of 96: 1, 2, 3, 4, 6, 8, 12, 16, 24, 32, 48, 96
the grid, no 3:  1, 2, 4, 8, 16, 32
the grid, one 3: 3, 6, 12, 24, 48, 96
rectangle shapes, 12 / 2                       6
360 = 2 x 2 x 2 x 3 x 3 x 5, (3 + 1) x (2 + 1) x (1 + 1)  24
divisors of 360, the slow way                 24
sum of the divisors of 96, 63 x 4            252
the three mistakes come out at 5, 8 and 10
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Counting divisors -- the same check as counting_divisors_check.py, in Rust.
// No crates.  A box of 96 tiles: 96 = 2 x 2 x 2 x 2 x 2 x 3.  The count is read
// off that prime factorisation, then checked by trying every number up to 96.
fn primes_of(mut n: i64) -> Vec<i64> {          // 96 -> [2, 2, 2, 2, 2, 3]
    let (mut out, mut d) = (Vec::new(), 2);
    while d * d <= n {
        while n % d == 0 { out.push(d); n /= d; }
        d += 1;
    }
    if n > 1 { out.push(n); } out
}
fn by_formula(n: i64) -> i64 {                  // one more than each prime's count, multiplied
    let (ps, mut total) = (primes_of(n), 1);
    for (i, p) in ps.iter().enumerate() {
        if i == 0 || *p != ps[i - 1] { total *= ps.iter().filter(|q| *q == p).count() as i64 + 1; }
    }
    total
}
fn by_hand(n: i64) -> Vec<i64> { (1..=n).filter(|d| n % d == 0).collect() }   // the slow road
fn list(v: Vec<i64>) -> String { v.iter().map(|d| d.to_string()).collect::<Vec<_>>().join(", ") }
fn row(name: &str, value: i64) { println!("{:<44}{:>4}", name, value); }
fn main() {
    println!("96 = {}", list(primes_of(96)).replace(", ", " x "));
    row("(5 + 1) x (1 + 1)", by_formula(96));
    row("divisors of 96, the slow way", by_hand(96).len() as i64);
    println!("divisors of 96: {}", list(by_hand(96)));
    println!("the grid, no 3:  {}", list(by_hand(96).into_iter().filter(|d| d % 3 != 0).collect()));
    println!("the grid, one 3: {}", list(by_hand(96).into_iter().filter(|d| d % 3 == 0).collect()));
    row("rectangle shapes, 12 / 2", by_formula(96) / 2);
    row("360 = 2 x 2 x 2 x 3 x 3 x 5, (3 + 1) x (2 + 1) x (1 + 1)", by_formula(360));
    row("divisors of 360, the slow way", by_hand(360).len() as i64);
    row("sum of the divisors of 96, 63 x 4", by_hand(96).iter().sum::<i64>());
    println!("the three mistakes come out at {}, {} and {}", 5, (5 + 1) + (1 + 1), by_formula(96) - 2);
    assert!(by_formula(96) == 12 && by_hand(96).len() == 12 && *by_hand(96).last().unwrap() == 96);
    let mut grid: Vec<i64> = by_hand(96).into_iter().filter(|d| d % 3 != 0)
        .chain(by_hand(96).into_iter().filter(|d| d % 3 == 0)).collect();
    grid.sort(); assert!(grid == by_hand(96));
    assert!(by_formula(360) == 24 && by_hand(360).len() == 24 && by_hand(96).iter().sum::<i64>() == 63 * 4);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
96 = 2 x 2 x 2 x 2 x 2 x 3
(5 + 1) x (1 + 1)                             12
divisors of 96, the slow way                  12
divisors of 96: 1, 2, 3, 4, 6, 8, 12, 16, 24, 32, 48, 96
the grid, no 3:  1, 2, 4, 8, 16, 32
the grid, one 3: 3, 6, 12, 24, 48, 96
rectangle shapes, 12 / 2                       6
360 = 2 x 2 x 2 x 3 x 3 x 5, (3 + 1) x (2 + 1) x (1 + 1)  24
divisors of 360, the slow way                 24
sum of the divisors of 96, 63 x 4            252
the three mistakes come out at 5, 8 and 10
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves the rule and its two side facts for every positive whole number, not just 96.

- Add one to how many times each prime appears, multiply those numbers, and that is how many divisors there are.
- The count of divisors is odd exactly when the number is a square.
- When the number is not a square, the rectangle shapes are exactly half the divisors.

Lean also checks the worked numbers for 96, 360 and 100; the printed output and the slow road are left to the Python and Rust checks.

<details>
<summary>The Lean proof, 154 lines</summary>

```lean
-- Counting divisors: for every positive whole number n, the number of positive divisors of n is the product, over the primes in n's factorisation, of one more than how many times that prime appears; the count is odd exactly when n is a square, and otherwise the rectangle shapes are half the divisors.
import Mathlib.NumberTheory.ArithmeticFunction.Misc
import Mathlib.NumberTheory.Divisors
import Mathlib.Algebra.Group.Even
import Mathlib.Tactic.NormNum.Prime

open Finset

theorem cd_card_antidiag (n : ℕ) (hn : 0 < n) : #n.divisorsAntidiagonal = #n.divisors := by
  rw [← Nat.image_fst_divisorsAntidiagonal]
  symm
  apply Finset.card_image_of_injOn
  intro p hp q hq h
  have h1 := (Nat.mem_divisorsAntidiagonal.mp hp).1
  have h2 := (Nat.mem_divisorsAntidiagonal.mp hq).1
  have hp1 : 0 < p.1 := Nat.pos_of_ne_zero (Nat.left_ne_zero_of_mem_divisorsAntidiagonal hp)
  have h' : p.1 = q.1 := h
  have : p.2 = q.2 := by
    apply Nat.eq_of_mul_eq_mul_left hp1
    rw [h1, h', h2]
  exact Prod.ext h' this

theorem cd_gt_eq_lt (n : ℕ) :
    #(n.divisorsAntidiagonal.filter (fun p => p.2 < p.1)) =
      #(n.divisorsAntidiagonal.filter (fun p => p.1 < p.2)) := by
  apply Finset.card_nbij' Prod.swap Prod.swap
  · intro p hp
    simp only [Finset.mem_coe, Finset.mem_filter, Nat.swap_mem_divisorsAntidiagonal] at hp ⊢
    exact ⟨hp.1, by simpa using hp.2⟩
  · intro p hp
    simp only [Finset.mem_coe, Finset.mem_filter, Nat.swap_mem_divisorsAntidiagonal] at hp ⊢
    exact ⟨hp.1, by simpa using hp.2⟩
  · intro p _; simp
  · intro p _; simp

theorem cd_key (n : ℕ) (hn : 0 < n) :
    2 * #(n.divisorsAntidiagonal.filter (fun p => p.1 ≤ p.2)) =
      #n.divisors + #(n.divisorsAntidiagonal.filter (fun p => p.1 = p.2)) := by
  have h1 := Finset.card_filter_add_card_filter_not (s := n.divisorsAntidiagonal)
    (fun p : ℕ × ℕ => p.1 ≤ p.2)
  have h2 : (n.divisorsAntidiagonal.filter (fun p => ¬ p.1 ≤ p.2)) =
      n.divisorsAntidiagonal.filter (fun p => p.2 < p.1) := by
    apply Finset.filter_congr; intro p _; simp
  have h3 := Finset.card_filter_add_card_filter_not
    (s := n.divisorsAntidiagonal.filter (fun p => p.1 ≤ p.2)) (fun p : ℕ × ℕ => p.1 = p.2)
  have h4 : (n.divisorsAntidiagonal.filter (fun p => p.1 ≤ p.2)).filter (fun p => p.1 = p.2)
      = n.divisorsAntidiagonal.filter (fun p => p.1 = p.2) := by
    ext p; simp only [Finset.mem_filter]; constructor
    · rintro ⟨⟨a, _⟩, c⟩; exact ⟨a, c⟩
    · rintro ⟨a, c⟩; exact ⟨⟨a, c.le⟩, c⟩
  have h5 : (n.divisorsAntidiagonal.filter (fun p => p.1 ≤ p.2)).filter (fun p => ¬ p.1 = p.2)
      = n.divisorsAntidiagonal.filter (fun p => p.1 < p.2) := by
    ext p; simp only [Finset.mem_filter]; constructor
    · rintro ⟨⟨a, b⟩, c⟩; exact ⟨a, lt_of_le_of_ne b c⟩
    · rintro ⟨a, c⟩; exact ⟨⟨a, c.le⟩, c.ne⟩
  rw [h2, cd_gt_eq_lt] at h1
  rw [h4, h5] at h3
  rw [← cd_card_antidiag n hn]
  omega

theorem cd_eq_nonsquare (n : ℕ) (hsq : ¬ IsSquare n) :
    #(n.divisorsAntidiagonal.filter (fun p => p.1 = p.2)) = 0 := by
  rw [Finset.card_eq_zero, Finset.filter_eq_empty_iff]
  intro p hp h
  apply hsq
  exact ⟨p.1, by rw [← (Nat.mem_divisorsAntidiagonal.mp hp).1, ← h]⟩

theorem cd_eq_square (n : ℕ) (hn : 0 < n) (hsq : IsSquare n) :
    #(n.divisorsAntidiagonal.filter (fun p => p.1 = p.2)) = 1 := by
  obtain ⟨m, rfl⟩ := hsq
  rw [Finset.card_eq_one]
  refine ⟨(m, m), ?_⟩
  ext p
  simp only [Finset.mem_filter, Nat.mem_divisorsAntidiagonal, Finset.mem_singleton]
  constructor
  · rintro ⟨⟨h, _⟩, h2⟩
    obtain ⟨a, b⟩ := p
    simp only at h h2
    subst h2
    have : a * a = m * m := h
    have : a = m := by nlinarith [Nat.mul_self_le_mul_self_iff (m := a) (n := m)]
    simp [this]
  · rintro rfl
    exact ⟨⟨rfl, hn.ne'⟩, rfl⟩

#print axioms cd_card_antidiag
#print axioms cd_gt_eq_lt
#print axioms cd_key
#print axioms cd_eq_nonsquare
#print axioms cd_eq_square

/-- Counting divisors. Take any positive whole number n and break it all the way down to primes.
For each prime, add one to how many times it appears in the factorisation, then multiply those
numbers together: the result is how many positive divisors n has. -/
theorem card_divisors_eq_prod_factorization_add_one (n : ℕ) (hn : 0 < n) :
    #n.divisors = ∏ p ∈ n.primeFactors, (n.factorization p + 1) := by
  exact Nat.card_divisors hn.ne'

/-- A square has one side that pairs with itself, so its count is odd: a positive whole number
has an odd number of positive divisors exactly when it is a square. -/
theorem card_divisors_odd_iff_is_square (n : ℕ) (hn : 0 < n) :
    Odd #n.divisors ↔ IsSquare n := by
  have key := cd_key n hn
  by_cases hsq : IsSquare n
  · have := cd_eq_square n hn hsq
    simp only [hsq, iff_true]
    rw [this] at key
    exact ⟨#(n.divisorsAntidiagonal.filter (fun p => p.1 ≤ p.2)) - 1, by omega⟩
  · have := cd_eq_nonsquare n hsq
    rw [this] at key
    simp only [hsq, iff_false, Nat.not_odd_iff_even]
    exact ⟨#(n.divisorsAntidiagonal.filter (fun p => p.1 ≤ p.2)), by omega⟩

/-- Divisors pair off, each pair multiplying to n. A rectangle shape is one such pair a × b = n,
with turning it round not counted as new (so a ≤ b). When n is positive and not a square, the
number of shapes is exactly half the number of divisors. -/
theorem shapes_are_half_the_divisors_when_not_square (n : ℕ) (hn : 0 < n) (hsq : ¬ IsSquare n) :
    2 * #(n.divisorsAntidiagonal.filter (fun p => p.1 ≤ p.2)) = #n.divisors := by
  have key := cd_key n hn
  rw [cd_eq_nonsquare n hsq] at key
  omega

-- The box: 96 = 2 × 2 × 2 × 2 × 2 × 3, five 2s and one 3.
example : (96 : ℕ) = 2 * 2 * 2 * 2 * 2 * 3 ∧ (96 : ℕ) = 2 ^ 5 * 3 ^ 1 := by norm_num
-- (5 + 1) × (1 + 1) = 12, and 96 really has 12 divisors.
example : (5 + 1) * (1 + 1) = 12 ∧ #(Nat.divisors 96) = 12 := by decide
-- The 12 divisors of 96, listed.
example : Nat.divisors 96 = {1, 2, 3, 4, 6, 8, 12, 16, 24, 32, 48, 96} := by decide
-- The grid: 2 ^ i × 3 ^ j, i from 0 to 5 and j from 0 to 1, fills every cell exactly once.
example : (range 6 ×ˢ range 2).image (fun ij : ℕ × ℕ => 2 ^ ij.1 * 3 ^ ij.2) = Nat.divisors 96 ∧
    #((range 6 ×ˢ range 2).image (fun ij : ℕ × ℕ => 2 ^ ij.1 * 3 ^ ij.2)) = 6 * 2 := by decide
-- The six rectangles: 1 by 96, 2 by 48, 3 by 32, 4 by 24, 6 by 16, 8 by 12.
example : (Nat.divisorsAntidiagonal 96).filter (fun p => p.1 ≤ p.2) =
    {(1, 96), (2, 48), (3, 32), (4, 24), (6, 16), (8, 12)} := by decide
example : #((Nat.divisorsAntidiagonal 96).filter (fun p => p.1 ≤ p.2)) = 12 / 2 := by decide
-- 360 = 2 × 2 × 2 × 3 × 3 × 5, so (3 + 1) × (2 + 1) × (1 + 1) = 24 divisors.
example : (360 : ℕ) = 2 ^ 3 * 3 ^ 2 * 5 ^ 1 ∧ (3 + 1) * (2 + 1) * (1 + 1) = 24 := by norm_num
example : #(Nat.divisors 360) = 24 := by decide
-- Adding the divisors: 1 + 2 + 4 + 8 + 16 + 32 = 63, and the whole grid adds to 63 × 4 = 252.
example : 1 + 2 + 4 + 8 + 16 + 32 = 63 ∧ 63 * 3 = 189 ∧ ∑ d ∈ Nat.divisors 96, d = 63 * 4 ∧
    63 * 4 = 252 := by decide
-- The three mistakes come out at 5, 8 and 10.
example : 5 * 1 = 5 ∧ (5 + 1) + (1 + 1) = 8 ∧ #((Nat.divisors 96).erase 1 |>.erase 96) = 10 := by
  decide
-- Try changing: 100 = 2 × 2 × 5 × 5 has (2 + 1) × (2 + 1) = 9 divisors, an odd count, as 10 × 10 = 100.
example : (100 : ℕ) = 2 ^ 2 * 5 ^ 2 ∧ #(Nat.divisors 100) = (2 + 1) * (2 + 1) ∧ 10 * 10 = 100 := by
  decide
-- 97 is prime, so it splits no way but 1 by 97.
example : Nat.Prime 97 := by norm_num
example : #(Nat.divisors 97) = 2 := by decide

#print axioms card_divisors_eq_prod_factorization_add_one
#print axioms card_divisors_odd_iff_is_square
#print axioms shapes_are_half_the_divisors_when_not_square
```

</details>

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'cd_card_antidiag' depends on axioms: [propext, Classical.choice, Quot.sound]
'cd_gt_eq_lt' depends on axioms: [propext, Classical.choice, Quot.sound]
'cd_key' depends on axioms: [propext, Classical.choice, Quot.sound]
'cd_eq_nonsquare' depends on axioms: [propext, Classical.choice, Quot.sound]
'cd_eq_square' depends on axioms: [propext, Classical.choice, Quot.sound]
'card_divisors_eq_prod_factorization_add_one' depends on axioms: [propext, Classical.choice, Quot.sound]
'card_divisors_odd_iff_is_square' depends on axioms: [propext, Classical.choice, Quot.sound]
'shapes_are_half_the_divisors_when_not_square' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it. The asserts are pinned to 96, so expect one to fire.
> - **Run it on 100.** Put 100 everywhere 96 appears. 100 is 2 × 2 × 5 × 5, so (2 + 1) × (2 + 1) = 9 divisors. 10 pairs with itself, so one divisor has no partner and the count is odd.
> - **Take the added one away.** In the line `total *= ps.count(p) + 1`, change the `+ 1` to `+ 0`. 96 drops to 5, the slow road still says 12, and the first assert fires.

---

## The usual mistake

> [!warning]
> **Multiplying the counts instead of one more than each count.** Five 2s and one 3 is not 5 × 1 = 5 divisors. The added one is the choice of taking *none* of that prime.
>
> - **A half-finished factorisation.** Call 96 "4 × 24", count two primes, and the answer is nonsense. Break it to primes first ([Prime factorisation](07-prime-factorisation.md)).

---

## Where you meet it in real life

- **Laying anything out in a rectangle.** Tiles, chairs, a photo grid, pallets in a lorry. The layouts are half the divisors, unless the count is a square.
- **Package sizes.** 96 splits evenly ten ways besides 1 by 96; 97 is prime, so it splits no way at all. That is why cases run on 12, 24 and 36.
- **Adding divisors rather than counting.** The grid gives 252 for 96: [Perfect numbers and Mersenne primes](../07-For%20the%20Curious/02-perfect-numbers-and-mersenne.md).

> **Say it back**
> Every divisor is built from the number's own primes, never using more of a prime than the number has. Building one is a decision per prime: how many to take, from none up to all. Those decisions multiply, so add one to each count and multiply. 96 is five 2s and one 3: (5 + 1) × (1 + 1) = 12 divisors, pairing off into 6 rectangles.

---

## What this builds on

- [Multiplying and dividing](../../01-Foundations/01-Everyday%20Arithmetic/03-multiplying-and-dividing.md): why separate choices multiply rather than add — six ways, then two for each, is 6 × 2.
- [Prime factorisation](07-prime-factorisation.md): the factorisation this card reads, and its uniqueness, which stops a divisor smuggling in a prime 96 never had.

## Where this goes next

- [Perfect numbers and Mersenne primes](../07-For%20the%20Curious/02-perfect-numbers-and-mersenne.md): stop counting divisors and start adding them. When they add to twice the number, it is called perfect.

Left open: the grid adds the divisors of 96 to 252. When does that sum come out at exactly twice the number?

---

## Sources

Verified 2026-11-11: every link below resolves to the publisher's page.

- Hardy, G. H., and E. M. Wright. *An Introduction to the Theory of Numbers*, 6th ed. Oxford University Press, 2008. [doi:10.1093/oso/9780199219858.001.0001](https://doi.org/10.1093/oso/9780199219858.001.0001). Chapter 16, in full.
- Apostol, Tom M. *Introduction to Analytic Number Theory*. Springer, 1976. [doi:10.1007/978-1-4757-5579-4](https://doi.org/10.1007/978-1-4757-5579-4). Chapter 2, the counting and sum rules.
- OEIS Foundation. *Sequence A000005, the number of divisors*. [oeis.org/A000005](https://oeis.org/A000005). Every number's count: 1, 2, 2, 3, 2, 4 and on.
