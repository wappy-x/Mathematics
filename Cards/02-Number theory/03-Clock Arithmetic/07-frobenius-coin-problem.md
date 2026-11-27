# The coin problem: with 5-cent and 7-cent stamps every amount above 23 can be paid, and 23 cannot

[Syllabus](../../../SYLLABUS.md) → [Number theory](../README.md) → [Clock Arithmetic](../README.md#s03) → The coin problem

---

## General Overview

A post office has only 5-cent and 7-cent stamps left. Postage must be exact.

24 cents works: two 5s and two 7s. But no pile of 5s and 7s makes 1, 2, 3, 4, 6, 8, 9, 11, 13, 16, 18 or 23 cents. That is 12 amounts.

From 24 on, everything works: 24 to 28 do, and adding 5s covers the rest.

This is the **coin problem**; its answer is the **Frobenius number**.

**When two stamp values of 2 or more share no factor above 1, only finitely many amounts cannot be paid, and the largest is the product minus both values: 5 × 7 − 5 − 7 = 23.**

**What kind of fact this is:** a theorem for two sizes, proved in Why it works; three sizes have no such formula, so this card searches.

### The amounts in five rows

Sort amounts by remainder after dividing by 5: five rows, the buckets of [Residue classes](03-residue-classes.md). A row's doorstep is its first payable amount; adding 5s pays the rest of the row.

| Remainder | Cannot be paid | Doorstep |
| --- | --- | --- |
| 0 | none | 0 |
| 1 | 1, 6, 11, 16 | 21 |
| 2 | 2 | 7 |
| 3 | 3, 8, 13, 18, 23 | 28 |
| 4 | 4, 9 | 14 |

The highest doorstep is 28, so the last gap is one 5 below it: 23.

---

## The formula

```math
\text{largest amount that cannot be paid} = a b - a - b = 5 \times 7 - 5 - 7 = 23
```

```math
\text{how many amounts cannot be paid} = (a - 1)(b - 1) / 2 = 4 \times 6 / 2 = 12
```

**Read it aloud:** the product less both values is the last amount that fails; one less than each, multiplied and halved, counts the failures.

$`ab`$ means $`a \times b`$. The values must be coprime: no whole number above 1 divides both ([Coprime numbers](../02-Greatest%20Common%20Divisor%20and%20Euclid%27s%20Algorithm/05-coprime-numbers.md)). An amount $`n`$ is payable when $`a x + b y = n`$ with counts $`x`$, $`y`$ of 0 or more.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $`a`$, $`b`$ | the two stamp values, 2 or more and coprime | 5 and 7 cents | more gaps |
| $`x`$, $`y`$ | how many of each stamp, 0 or more | 2 and 2, for 24 cents | — |
| $`n`$ | the amount to pay | 24 cents | above 23, always payable |
| $`ab - a - b`$ | the largest amount that cannot be paid | 23 | — |
| $`(a - 1)(b - 1)/2`$ | how many amounts cannot be paid | 12 | — |
| $`c`$, $`z`$ | a third size, and its count | boxes of 20, beside 6 and 9 | no single rule |

### When it holds

- **The values are coprime.** 6 and 9 make only multiples of 3, so the gaps never end.
- **Both values 2 or more.** A 1-cent stamp pays everything.
- **Counts of 0 or more.** Allow stamps back and every amount works: 3 × 5 − 2 × 7 = 1.
- **Exactly two sizes.** Three sizes have no such formula; boxes of 6, 9 and 20 stop at 43.

---

## Why it works

### Step 0: one paid amount pays everything above it in its row

A 5-cent stamp moves an amount one place along its row. So a row is unpayable before its doorstep and payable from it on.

### Step 1: each doorstep is made of 7s alone

Strip the 5s out of a payable amount. The pile of 7s left is payable, no larger, and in the same row. So a doorstep uses no 5s.

### Step 2: the 7s land in five different rows

The piles 0, 7, 14, 21 and 28 leave remainders 0, 2, 4, 1 and 3: all different, because 7 and 5 are coprime ([Solving a x ≡ b (mod n)](05-linear-congruences.md)). Other piles in a row are 35 or more bigger, so these are the doorsteps. The highest is four 7s; in general, $`a - 1`$ copies of $`b`$.

### Step 3: the last gap is one stamp below the highest doorstep

28 opens its row, so 23 fails; no doorstep tops 28, so any amount below its doorstep is at most 28 − 5 = 23. In letters: $`(a - 1) b - a = ab - a - b`$.

### Step 4: exactly half of 0 to 23 fails

Pair each amount $`n`$ from 0 to 23 with $`23 - n`$. In every pair exactly one is payable. 24 amounts make 12 pairs, so 12 gaps; in letters, $`(a - 1)(b - 1)/2`$.

<details>
<summary>Why exactly one of each pair is payable</summary>

Not both: their sum, 23, would be payable. At least one: as in Step 2, write $`n`$ with 0 to 4 sevens and a count of 5s that may be negative.

$`\displaystyle n = 5 x + 7 y, \quad 0 \le y \le 4`$

If $`x`$ is below 0, it is at most −1, and the partner is payable:

$`\displaystyle 23 - n = 5 \times 7 - 5 - 7 - 5 x - 7 y = 5 (-1 - x) + 7 (4 - y)`$

</details>

### Step 5: three sizes, with and without negative counts

With negative counts, $`a x + b y + c z = n`$ has whole-number answers exactly when the greatest common divisor (gcd) of the sizes divides $`n`$. Apply [Bezout's identity](../02-Greatest%20Common%20Divisor%20and%20Euclid%27s%20Algorithm/04-bezouts-identity.md) twice: 6 × (−1) + 9 × 1 = 3, then 3 × 7 + 20 × (−1) = 1, so 6 × (−7) + 9 × 7 + 20 × (−1) = 1.

Scaling by $`n`$ reaches any $`n`$. Conversely, the gcd divides every size, hence every mix: 6, 9 and 15 give only multiples of 3.

With counts of 0 or more, boxes of 6, 9 and 20 sort into rows by remainder on 6: doorsteps from 9s and 20s are 0, 49, 20, 9, 40 and 29, so the last gap is 49 − 6 = 43. No formula like $`ab - a - b`$ exists for three sizes, though faster methods exist.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| doorsteps, rows 0 to 4 | piles of 7s by remainder | 0, 21, 7, 28, 14 |
| highest doorstep | 4 × 7 | 28 |
| one stamp below it | 28 − 5 | **23** |
| five in a row | 24 = 2 × 5 + 2 × 7, 25 = 5 × 5, 26 = 5 + 3 × 7, 27 = 4 × 5 + 7, 28 = 4 × 7 | all payable |
| the formula | 5 × 7 − 5 − 7 | **23** |
| gaps per row | doorstep ÷ 5, rounded down | 0, 4, 1, 5, 2 |
| gaps in all | 0 + 4 + 1 + 5 + 2, and 4 × 6 / 2 | **12** |

23 cents is the last postage that cannot be made.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Taking the product as the last gap | 35 | 35 is seven 5s; the two values must also come off |
| Taking the highest doorstep as the last gap | 28 | 28 is four 7s; the gap is one 5 below it |
| Forgetting to halve the count | 24 | only one amount in each pair fails |

---

## Code, from first principles, and it actually runs

Nothing is imported. Search, doorsteps and the formula each give 23 and 12; pairing also gives 12, and search and doorsteps give 43 for the boxes.

### Python

```python
# The coin problem -- the check behind the card.  Nothing is imported.  Stamps of 5 and 7
# cents, then boxes of 6, 9 and 20.  Roads: search, the remainder ladder, the formula, pairing.
def payable(sizes, top):                    # road one: build every amount upward
    ok = [True] + [False] * top
    for n in range(1, top + 1): ok[n] = any(n >= s and ok[n - s] for s in sizes)
    return ok
def ladder(sizes):                          # road two: cheapest amount in each row, from the other sizes only
    a, ok = sizes[0], payable(sizes[1:], sizes[0] * max(sizes) * 3)
    return [min(n for n in range(len(ok)) if ok[n] and n % a == r) for r in range(a)]
A, B, BOXES = 5, 7, [6, 9, 20]
ok, rows, F = payable([A, B], 100), ladder([A, B]), A * B - A - B   # road three: formula
gaps, pairs = [n for n in range(101) if not ok[n]], sum(ok[n] != ok[F - n] for n in range(F + 1)) // 2  # road four: n, 23 - n
print(f"{A} and {B} cannot pay:", " ".join(str(n) for n in gaps))
print(f"first payable in rows 0..{A - 1}: {rows}; gaps per row {[r // A for r in rows]}; largest gap {max(rows)} - {A} = {max(rows) - A}")
print(f"formula {A} x {B} - {A} - {B} = {F}; gaps {len(gaps)}, ({A}-1)({B}-1)/2 = {(A - 1) * (B - 1) // 2}, pairs split {pairs} of {(F + 1) // 2}")
ys = {n: min(y for y in range(A) if (n - B * y) % A == 0) for n in range(F + 1, F + A + 1)}  # the next five
print("; ".join(f"{n} = {(n - B * y) // A} x {A} + {y} x {B}" for n, y in ys.items()))
box, brows, c = payable(BOXES, 200), ladder(BOXES), BOXES[0]
bgaps = [n for n in range(201) if not box[n]]
print(f"boxes {', '.join(map(str, BOXES))}: largest gap {bgaps[-1]}, rows {brows}, {max(brows)} - {c} = {max(brows) - c}; gaps {len(bgaps)}")
(u, v), (s, t), R = (-1, 1), (7, -1), range(-10, 11)      # Bezout twice: 6u + 9v = 3, then 3s + 20t = 1
print(f"negatives allowed: 3 x {A} - 2 x {B} = {3 * A - 2 * B}; 6 x {u} + 9 x {v} = {6 * u + 9 * v}, {6 * u + 9 * v} x {s} + 20 x {t} = {(6 * u + 9 * v) * s + 20 * t}, so 6 x {u * s} + 9 x {v * s} + 20 x {t} = {6 * u * s + 9 * v * s + 20 * t}")
mix = lambda p, q, w: sorted({p * x + q * y + w * z for x in R for y in R for z in R} & set(range(51)))
print(f"counts -10 to 10, amounts 0 to 50: 6, 9, 20 reach {len(mix(6, 9, 20))} of 51; 6, 9, 15 reach only {' '.join(map(str, mix(6, 9, 15)))}")
print(f"the three mistakes come out at {A * B}, {max(rows)} and {(A - 1) * (B - 1)}")
assert gaps[-1] == F == max(rows) - A == 23 and len(gaps) == (A - 1) * (B - 1) // 2 == pairs == sum(r // A for r in rows) == 12
assert rows == [0, 21, 7, 28, 14] and all(d % A == r and ok[d] and (d < A or not ok[d - A]) for r, d in enumerate(rows)) and all(ok[24:]) and ok[A * B] and ok[max(rows)]
assert bgaps[-1] == max(brows) - c == 43 and len(bgaps) == sum(r // c for r in brows) == 22 and all(d % c == r and box[d] and (d < c or not box[d - c]) for r, d in enumerate(brows))
assert 6 * u * s + 9 * v * s + 20 * t == 1 and len(mix(6, 9, 20)) == 51 and mix(6, 9, 15) == list(range(0, 51, 3))
print("ALL CHECKS PASS")
```

**Ran 2026-11-23 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
5 and 7 cannot pay: 1 2 3 4 6 8 9 11 13 16 18 23
first payable in rows 0..4: [0, 21, 7, 28, 14]; gaps per row [0, 4, 1, 5, 2]; largest gap 28 - 5 = 23
formula 5 x 7 - 5 - 7 = 23; gaps 12, (5-1)(7-1)/2 = 12, pairs split 12 of 12
24 = 2 x 5 + 2 x 7; 25 = 5 x 5 + 0 x 7; 26 = 1 x 5 + 3 x 7; 27 = 4 x 5 + 1 x 7; 28 = 0 x 5 + 4 x 7
boxes 6, 9, 20: largest gap 43, rows [0, 49, 20, 9, 40, 29], 49 - 6 = 43; gaps 22
negatives allowed: 3 x 5 - 2 x 7 = 1; 6 x -1 + 9 x 1 = 3, 3 x 7 + 20 x -1 = 1, so 6 x -7 + 9 x 7 + 20 x -1 = 1
counts -10 to 10, amounts 0 to 50: 6, 9, 20 reach 51 of 51; 6, 9, 15 reach only 0 3 6 9 12 15 18 21 24 27 30 33 36 39 42 45 48
the three mistakes come out at 35, 28 and 24
ALL CHECKS PASS
```

### Rust

Same numbers, same labels.

```rust
// The coin problem -- the same check as the Python, in Rust.  No crates.  Stamps of 5 and 7
// cents, then boxes of 6, 9 and 20.  Roads: search, the remainder ladder, the formula, pairing.
fn payable(sizes: &[usize], top: usize) -> Vec<bool> {     // road one: build every amount upward
    let mut ok = vec![false; top + 1]; ok[0] = true;
    for n in 1..=top { ok[n] = sizes.iter().any(|&s| n >= s && ok[n - s]); }
    ok
}
fn ladder(sizes: &[usize]) -> Vec<usize> {                 // road two: cheapest amount in each row, from the other sizes only
    let (a, ok) = (sizes[0], payable(&sizes[1..], sizes[0] * sizes.iter().max().unwrap() * 3));
    (0..a).map(|r| (0..ok.len()).filter(|&n| ok[n] && n % a == r).min().unwrap()).collect()
}
fn mix(p: i64, q: i64, w: i64) -> Vec<i64> {              // amounts 0 to 50 that counts -10 to 10 reach
    (0..51).filter(|&n| (-10..11).any(|x| (-10..11).any(|y| (-10..11).any(|z| p * x + q * y + w * z == n)))).collect()
}
fn join<T: ToString>(v: &[T], sep: &str) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(sep) }
fn main() {
    let (a, b, boxes) = (5usize, 7usize, [6usize, 9, 20]);
    let (ok, rows, f) = (payable(&[a, b], 100), ladder(&[a, b]), a * b - a - b); // road three: formula
    let gaps: Vec<usize> = (0..=100).filter(|&n| !ok[n]).collect();
    let (pairs, top) = ((0..=f).filter(|&n| ok[n] != ok[f - n]).count() / 2, *rows.iter().max().unwrap()); // road four
    let door = |ok: &[bool], a: usize, rows: &[usize]| rows.iter().enumerate().all(|(r, &d)| d % a == r && ok[d] && (d < a || !ok[d - a]));
    println!("{} and {} cannot pay: {}", a, b, join(&gaps, " "));
    println!("first payable in rows 0..{}: {:?}; gaps per row {:?}; largest gap {} - {} = {}", a - 1, rows, rows.iter().map(|r| r / a).collect::<Vec<_>>(), top, a, top - a);
    println!("formula {} x {} - {} - {} = {}; gaps {}, ({}-1)({}-1)/2 = {}, pairs split {} of {}", a, b, a, b, f, gaps.len(), a, b, (a - 1) * (b - 1) / 2, pairs, (f + 1) / 2);
    println!("{}", (f + 1..=f + a).map(|n| { let y = (0..a).find(|&y| (n - b * y) % a == 0).unwrap(); format!("{} = {} x {} + {} x {}", n, (n - b * y) / a, a, y, b) }).collect::<Vec<_>>().join("; "));
    let (bx, brows, c) = (payable(&boxes, 200), ladder(&boxes), boxes[0]);
    let (bgaps, btop): (Vec<usize>, usize) = ((0..=200).filter(|&n| !bx[n]).collect(), *brows.iter().max().unwrap());
    println!("boxes {}: largest gap {}, rows {:?}, {} - {} = {}; gaps {}", join(&boxes, ", "), bgaps[bgaps.len() - 1], brows, btop, c, btop - c, bgaps.len());
    let ((u, v), (s, t), m20, m15) = ((-1i64, 1i64), (7i64, -1i64), mix(6, 9, 20), mix(6, 9, 15)); // Bezout twice: 6u + 9v = 3, 3s + 20t = 1
    println!("negatives allowed: 3 x {} - 2 x {} = {}; 6 x {} + 9 x {} = {}, {} x {} + 20 x {} = {}, so 6 x {} + 9 x {} + 20 x {} = {}", a, b, 3 * a as i64 - 2 * b as i64,
             u, v, 6 * u + 9 * v, 6 * u + 9 * v, s, t, (6 * u + 9 * v) * s + 20 * t, u * s, v * s, t, 6 * u * s + 9 * v * s + 20 * t);
    println!("counts -10 to 10, amounts 0 to 50: 6, 9, 20 reach {} of 51; 6, 9, 15 reach only {}", m20.len(), join(&m15, " "));
    println!("the three mistakes come out at {}, {} and {}", a * b, top, (a - 1) * (b - 1));
    assert!(gaps[gaps.len() - 1] == f && f == top - a && f == 23 && gaps.len() == (a - 1) * (b - 1) / 2 && gaps.len() == pairs && pairs == rows.iter().map(|r| r / a).sum::<usize>() && pairs == 12);
    assert!(rows == vec![0, 21, 7, 28, 14] && door(&ok, a, &rows) && ok[24..].iter().all(|&v| v) && ok[a * b] && ok[top]);
    assert!(bgaps[bgaps.len() - 1] == btop - c && btop - c == 43 && bgaps.len() == brows.iter().map(|r| r / c).sum::<usize>() && bgaps.len() == 22 && door(&bx, c, &brows));
    assert!(6 * u * s + 9 * v * s + 20 * t == 1 && m20.len() == 51 && m15 == (0..51).step_by(3).collect::<Vec<i64>>());
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-23 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
5 and 7 cannot pay: 1 2 3 4 6 8 9 11 13 16 18 23
first payable in rows 0..4: [0, 21, 7, 28, 14]; gaps per row [0, 4, 1, 5, 2]; largest gap 28 - 5 = 23
formula 5 x 7 - 5 - 7 = 23; gaps 12, (5-1)(7-1)/2 = 12, pairs split 12 of 12
24 = 2 x 5 + 2 x 7; 25 = 5 x 5 + 0 x 7; 26 = 1 x 5 + 3 x 7; 27 = 4 x 5 + 1 x 7; 28 = 0 x 5 + 4 x 7
boxes 6, 9, 20: largest gap 43, rows [0, 49, 20, 9, 40, 29], 49 - 6 = 43; gaps 22
negatives allowed: 3 x 5 - 2 x 7 = 1; 6 x -1 + 9 x 1 = 3, 3 x 7 + 20 x -1 = 1, so 6 x -7 + 9 x 7 + 20 x -1 = 1
counts -10 to 10, amounts 0 to 50: 6, 9, 20 reach 51 of 51; 6, 9, 15 reach only 0 3 6 9 12 15 18 21 24 27 30 33 36 39 42 45 48
the three mistakes come out at 35, 28 and 24
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves the two-size results for every pair of coprime stamp values, and the three-size rule for any three whole-number sizes.

- Take coprime stamp values $`a`$ and $`b`$. Then $`ab - a - b`$ cannot be paid with counts of 0 or more, and every larger amount can.
- Take coprime $`a`$ and $`b`$ again. Then only finitely many amounts cannot be paid, and there are exactly $`(a - 1)(b - 1)/2`$ of them.
- Allow counts below 0. Then $`a x + b y + c z = n`$ has whole-number answers exactly when the gcd of the three sizes divides $`n`$.
- For 5 and 7, the gaps up to 23 are exactly the 12 listed, and 24 to 28 are all payable.
- For 6, 9 and 20, 43 cannot be made, and 44 to 49 can.
- Bezout twice gives 6 × (−7) + 9 × 7 + 20 × (−1) = 1, and the gcd of 6, 9 and 15 is 3.

Box orders above 49, the 22 box gaps and the search over counts −10 to 10 are left to the Python and Rust checks.

```lean
-- The coin problem: with two coprime stamp values a and b, the amount a b - a - b cannot be paid and every larger amount can, exactly (a - 1)(b - 1)/2 amounts cannot be paid, and with counts allowed below 0, a x + b y + c z = n has answers exactly when the gcd of the three sizes divides n.
import Mathlib.Data.Int.GCD
import Mathlib.Data.Set.Card
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.Zify

/-- Two payable amounts never add up to a b - a - b. -/
theorem frob_not_both (a b : ℕ) (cop : Nat.Coprime a b) (x y x' y' : ℕ) :
    (a : ℤ) * x + b * y + (a * x' + b * y') + a + b ≠ a * b := by
  intro h
  have h' : a * (x + x' + 1) + b * (y + y' + 1) = a * b := by
    have : ((a * (x + x' + 1) + b * (y + y' + 1) : ℕ) : ℤ) = ((a * b : ℕ) : ℤ) := by
      push_cast; linarith
    exact_mod_cast this
  have hd : a ∣ (y + y' + 1) * b := by
    have h1 : a ∣ a * (x + x' + 1) + b * (y + y' + 1) := h' ▸ dvd_mul_right a b
    have h2 := (Nat.dvd_add_right (dvd_mul_right a (x + x' + 1))).mp h1
    rwa [mul_comm] at h2
  have hs : a ∣ y + y' + 1 := Nat.Coprime.dvd_of_dvd_mul_right cop hd
  rcases Nat.eq_zero_or_pos a with ha | ha
  · subst ha
    rw [zero_dvd_iff] at hs
    omega
  · have hle : a ≤ y + y' + 1 := Nat.le_of_dvd (by omega) hs
    have : b * a ≤ b * (y + y' + 1) := Nat.mul_le_mul_left b hle
    nlinarith

/-- Every whole number is a x + b y with 0 ≤ x < b. -/
theorem frob_canon (a b : ℕ) (cop : Nat.Coprime a b) (hb : 0 < b) (m : ℤ) :
    ∃ x : ℕ, x < b ∧ ∃ y : ℤ, (a : ℤ) * x + b * y = m := by
  have hg := Nat.gcd_eq_gcd_ab a b
  rw [cop.gcd_eq_one] at hg
  set u := Nat.gcdA a b
  set v := Nat.gcdB a b
  have hbz : (0 : ℤ) < b := by exact_mod_cast hb
  refine ⟨((u * m) % b).toNat, ?_, a * ((u * m) / b) + v * m, ?_⟩
  · have h1 := Int.emod_lt_of_pos (u * m) hbz
    have h2 := Int.emod_nonneg (u * m) hbz.ne'
    omega
  · have h2 := Int.emod_nonneg (u * m) hbz.ne'
    rw [Int.toNat_of_nonneg h2]
    have h3 := Int.emod_add_mul_ediv (u * m) b
    push_cast at hg
    linear_combination (a : ℤ) * h3 + m * hg.symm

/-- For 0 ≤ n ≤ a b - a - b, exactly one of n and a b - a - b - n is payable. -/
theorem frob_compl (a b : ℕ) (cop : Nat.Coprime a b) (hb : 0 < b) (n m : ℕ)
    (hnm : (n : ℤ) + m = a * b - a - b) :
    (∃ x y : ℕ, a * x + b * y = m) ↔ ¬ ∃ x y : ℕ, a * x + b * y = n := by
  constructor
  · rintro ⟨x, y, hxy⟩ ⟨x', y', hxy'⟩
    apply frob_not_both a b cop x' y' x y
    have h1 : ((a * x + b * y : ℕ) : ℤ) = m := by exact_mod_cast hxy
    have h2 : ((a * x' + b * y' : ℕ) : ℤ) = n := by exact_mod_cast hxy'
    push_cast at h1 h2
    linarith
  · intro hn
    obtain ⟨x, hx, y, hxy⟩ := frob_canon a b cop hb n
    have hy : y < 0 := by
      by_contra hy
      push Not at hy
      apply hn
      refine ⟨x, y.toNat, ?_⟩
      have : ((a * x + b * y.toNat : ℕ) : ℤ) = n := by
        push_cast; rw [Int.toNat_of_nonneg hy]; exact hxy
      exact_mod_cast this
    refine ⟨b - 1 - x, (-1 - y).toNat, ?_⟩
    have : ((a * (b - 1 - x) + b * (-1 - y).toNat : ℕ) : ℤ) = m := by
      have e1 : ((b - 1 - x : ℕ) : ℤ) = b - 1 - x := by omega
      push_cast
      rw [e1, Int.toNat_of_nonneg (by omega)]
      linear_combination -hnm - hxy
    exact_mod_cast this

#print axioms frob_not_both
#print axioms frob_canon
#print axioms frob_compl

/-- The two-size theorem. When the stamp values a and b share no factor above 1, the amount
a b - a - b cannot be paid with counts of 0 or more, and every larger amount can:
5 × 7 − 5 − 7 = 23. (The difference is taken in the integers, so for a value of 1 it is −1
and every amount can be paid.) -/
theorem largest_unpayable_amount_is_ab_minus_a_minus_b (a b : ℕ) (cop : Nat.Coprime a b) :
    (¬ ∃ x y : ℕ, (a : ℤ) * x + b * y = a * b - a - b) ∧
      ∀ n : ℕ, (a : ℤ) * b - a - b < n → ∃ x y : ℕ, a * x + b * y = n := by
  refine ⟨?_, ?_⟩
  · rintro ⟨x, y, h⟩
    exact frob_not_both a b cop x y 0 0 (by push_cast; linarith)
  · intro n hn
    rcases Nat.eq_zero_or_pos b with hb | hb
    · subst hb
      have ha : a = 1 := Nat.coprime_zero_right a |>.mp cop
      exact ⟨n, 0, by subst ha; ring⟩
    · obtain ⟨x, hx, y, hxy⟩ := frob_canon a b cop hb n
      have hy : 0 ≤ y := by
        by_contra hy
        push Not at hy
        have hx' : (x : ℤ) ≤ b - 1 := by omega
        have : (a : ℤ) * x ≤ a * (b - 1) := by
          apply mul_le_mul_of_nonneg_left hx'; positivity
        nlinarith
      refine ⟨x, y.toNat, ?_⟩
      have : ((a * x + b * y.toNat : ℕ) : ℤ) = n := by
        push_cast; rw [Int.toNat_of_nonneg hy]; exact hxy
      exact_mod_cast this

/-- The gap count. When a and b share no factor above 1, only finitely many amounts cannot be
paid with counts of 0 or more, and there are exactly (a - 1)(b - 1)/2 of them:
4 × 6 / 2 = 12 for 5 and 7. -/
theorem unpayable_amounts_number_half_of_a_minus_one_times_b_minus_one (a b : ℕ)
    (cop : Nat.Coprime a b) :
    {n : ℕ | ¬ ∃ x y : ℕ, a * x + b * y = n}.Finite ∧
      {n : ℕ | ¬ ∃ x y : ℕ, a * x + b * y = n}.ncard = (a - 1) * (b - 1) / 2 := by
  classical
  rcases Nat.eq_zero_or_pos a with ha | ha
  · subst ha
    have hb : b = 1 := Nat.coprime_zero_left b |>.mp cop
    subst hb
    have : {n : ℕ | ¬ ∃ x y : ℕ, 0 * x + 1 * y = n} = ∅ := by
      ext n; simp
    rw [this]; simp
  rcases Nat.eq_zero_or_pos b with hb | hb
  · subst hb
    have ha1 : a = 1 := Nat.coprime_zero_right a |>.mp cop
    subst ha1
    have : {n : ℕ | ¬ ∃ x y : ℕ, 1 * x + 0 * y = n} = ∅ := by
      ext n; simp
    rw [this]; simp
  set N := (a - 1) * (b - 1) with hNdef
  have hN : (N : ℤ) = a * b - a - b + 1 := by
    rw [hNdef]; push_cast [Nat.cast_sub (show 1 ≤ a by omega), Nat.cast_sub (show 1 ≤ b by omega)]
    ring
  set T := (Finset.range N).filter (fun n => ¬ ∃ x y : ℕ, a * x + b * y = n) with hT
  set P := (Finset.range N).filter (fun n => ∃ x y : ℕ, a * x + b * y = n) with hP
  have hS : {n : ℕ | ¬ ∃ x y : ℕ, a * x + b * y = n} = (T : Set ℕ) := by
    ext n
    simp only [Set.mem_ofPred_eq, hT, Finset.coe_filter, Finset.mem_range]
    constructor
    · intro h
      refine ⟨?_, h⟩
      by_contra hn
      push Not at hn
      apply h
      apply (largest_unpayable_amount_is_ab_minus_a_minus_b a b cop).2 n
      have : (N : ℤ) ≤ n := by exact_mod_cast hn
      linarith
    · exact fun h => h.2
  rw [hS]
  refine ⟨Finset.finite_toSet T, ?_⟩
  rw [Set.ncard_coe_finset]
  have hsum : P.card + T.card = N := by
    rw [hP, hT]; simpa using Finset.card_filter_add_card_filter_not
      (s := Finset.range N) (fun n => ∃ x y : ℕ, a * x + b * y = n)
  have key : ∀ n, n < N → ((((N - 1 - n : ℕ) : ℤ) + n = a * b - a - b) ∧
      ((n : ℤ) + ((N - 1 - n : ℕ) : ℤ) = a * b - a - b)) := by
    intro n hn
    have : ((N - 1 - n : ℕ) : ℤ) = N - 1 - n := by omega
    constructor <;> linarith
  have hTP : T.card = P.card := by
    apply Finset.card_nbij' (fun n => N - 1 - n) (fun n => N - 1 - n)
    · intro n hn
      simp only [hT, hP, Finset.coe_filter, Finset.mem_range, Set.mem_ofPred_eq] at hn ⊢
      refine ⟨by omega, ?_⟩
      exact (frob_compl a b cop hb n (N - 1 - n) (key n hn.1).2).mpr hn.2
    · intro n hn
      simp only [hT, hP, Finset.coe_filter, Finset.mem_range, Set.mem_ofPred_eq] at hn ⊢
      refine ⟨by omega, ?_⟩
      intro h
      exact (frob_compl a b cop hb (N - 1 - n) n (key n hn.1).1).mp hn.2 h
    · intro n hn
      simp only [hT, Finset.coe_filter, Finset.mem_range, Set.mem_ofPred_eq] at hn
      show N - 1 - (N - 1 - n) = n
      omega
    · intro n hn
      simp only [hP, Finset.coe_filter, Finset.mem_range, Set.mem_ofPred_eq] at hn
      show N - 1 - (N - 1 - n) = n
      omega
  omega

/-- Three sizes with counts allowed below 0: a x + b y + c z = n has whole-number answers
exactly when the greatest common divisor of the three sizes divides n. -/
theorem three_sizes_solvable_iff_gcd_dvd (a b c n : ℤ) :
    (∃ x y z : ℤ, a * x + b * y + c * z = n) ↔ ((Int.gcd (Int.gcd a b) c : ℤ) ∣ n) := by
  set g := Int.gcd (Int.gcd a b) c
  constructor
  · rintro ⟨x, y, z, h⟩
    rw [← h]
    have hgd : (g : ℤ) ∣ (Int.gcd a b : ℤ) := Int.gcd_dvd_left _ _
    have hgc : (g : ℤ) ∣ c := Int.gcd_dvd_right _ _
    have hga : (g : ℤ) ∣ a := hgd.trans (Int.gcd_dvd_left _ _)
    have hgb : (g : ℤ) ∣ b := hgd.trans (Int.gcd_dvd_right _ _)
    exact dvd_add (dvd_add (hga.mul_right x) (hgb.mul_right y)) (hgc.mul_right z)
  · rintro ⟨k, hk⟩
    have h1 := Int.gcd_eq_gcd_ab a b
    have h2 := Int.gcd_eq_gcd_ab (Int.gcd a b : ℤ) c
    refine ⟨Int.gcdA a b * Int.gcdA (Int.gcd a b) c * k,
      Int.gcdB a b * Int.gcdA (Int.gcd a b) c * k, Int.gcdB (Int.gcd a b) c * k, ?_⟩
    rw [hk]
    linear_combination (-(k : ℤ)) * h2 - (Int.gcdA (Int.gcd a b) c * k) * h1

-- Stamps of 5 and 7: up to 23, the amounts that cannot be paid are exactly these 12.
-- (Counts of 24 or more of either stamp overshoot 23, so searching counts below 24 is complete.)
example : (Finset.range 24).filter
      (fun n => ¬ ∃ x ∈ Finset.range 24, ∃ y ∈ Finset.range 24, 5 * x + 7 * y = n)
    = {1, 2, 3, 4, 6, 8, 9, 11, 13, 16, 18, 23} := by decide

-- The formula and the count for 5 and 7.
example : 5 * 7 - 5 - 7 = 23 := by norm_num
example : (5 - 1) * (7 - 1) / 2 = 12 := by norm_num

-- From 24 on: five amounts in a row, one per row, and adding 5s covers the rest.
example : 24 = 2 * 5 + 2 * 7 ∧ 25 = 5 * 5 ∧ 26 = 1 * 5 + 3 * 7 ∧ 27 = 4 * 5 + 1 * 7 ∧ 28 = 4 * 7 := by
  norm_num

-- The doorsteps: the piles 0, 7, 14, 21, 28 of 7s land in rows 0, 2, 4, 1, 3; one 5 below 28 is 23.
example : [0, 7, 14, 21, 28].map (· % 5) = [0, 2, 4, 1, 3] := by decide
example : 4 * 7 - 5 = 23 := by norm_num

-- The usual mistakes: the product 35 is seven 5s, and 4 × 6 = 24 forgets to halve.
example : 5 * 7 = 7 * 5 + 0 * 7 ∧ (5 - 1) * (7 - 1) = 24 := by norm_num

-- Allowing a stamp handed back makes every amount work: 3 × 5 − 2 × 7 = 1.
example : (3 : ℤ) * 5 - 2 * 7 = 1 := by norm_num

-- Boxes of 6, 9 and 20: 43 cannot be made, and 44 to 49 (one per row of 6) can.
example : ¬ ∃ x ∈ Finset.range 8, ∃ y ∈ Finset.range 5, ∃ z ∈ Finset.range 3,
    6 * x + 9 * y + 20 * z = 43 := by decide
example : 44 = 4 * 6 + 20 ∧ 45 = 5 * 9 ∧ 46 = 6 + 2 * 20 ∧ 47 = 3 * 9 + 20 ∧ 48 = 8 * 6 ∧
    49 = 9 + 2 * 20 := by norm_num

-- The box doorsteps 0, 49, 20, 9, 40, 29 land in rows 0 to 5; one 6 below 49 is 43.
example : [0, 49, 20, 9, 40, 29].map (· % 6) = [0, 1, 2, 3, 4, 5] := by decide
example : 49 - 6 = 43 := by norm_num

-- Bezout twice for 6, 9 and 20, and the gcds of 6, 9, 20 and of 6, 9, 15.
example : (6 : ℤ) * (-1) + 9 * 1 = 3 ∧ (3 : ℤ) * 7 + 20 * (-1) = 1 ∧
    (6 : ℤ) * (-7) + 9 * 7 + 20 * (-1) = 1 := by norm_num
example : Int.gcd (Int.gcd 6 9) 20 = 1 ∧ Int.gcd (Int.gcd 6 9) 15 = 3 := by decide

#print axioms largest_unpayable_amount_is_ab_minus_a_minus_b
#print axioms unpayable_amounts_number_half_of_a_minus_one_times_b_minus_one
#print axioms three_sizes_solvable_iff_gcd_dvd
```

**Checked 2026-11-23 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'frob_not_both' depends on axioms: [propext, Classical.choice, Quot.sound]
'frob_canon' depends on axioms: [propext, Classical.choice, Quot.sound]
'frob_compl' depends on axioms: [propext, Classical.choice, Quot.sound]
'largest_unpayable_amount_is_ab_minus_a_minus_b' depends on axioms: [propext, Classical.choice, Quot.sound]
'unpayable_amounts_number_half_of_a_minus_one_times_b_minus_one' depends on axioms: [propext, Classical.choice, Quot.sound]
'three_sizes_solvable_iff_gcd_dvd' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first; each hits a pinned assert.
> - **Set `A, B = 5, 8`.** Last gap 27, with 14 gaps.
> - **Set `A, B = 3, 5`.** Only 1, 2, 4 and 7 fail.
> - **Set `BOXES = [9, 20]`.** Two sizes again, so the formula works: 151.

---

## The usual mistake

> [!warning]
> **Using the formula when the values share a factor.** 6 and 9 make only multiples of 3, so no largest gap exists.
>
> - **Taking the product.** 5 × 7 = 35 is seven 5s, so it is payable.
> - **Forgetting to halve.** 4 × 6 = 24, but only 12 amounts fail.
> - **Allowing change back.** 3 × 5 − 2 × 7 = 1, so every amount works.

---

## Where you meet it in real life

- **Postage.** With two coprime stamp values of 2 or more, every rate above the Frobenius number is payable exactly.
- **Pack sizes.** Boxes of 6, 9 and 20 fill every exact order above 43, but not 43.
- **Game scores.** Two coprime point values of 2 or more leave a highest impossible score.

> **Say it back**
> Sort amounts by remainder on 5. Each row opens at a pile of 7s; highest is 28, so the last gap is 28 − 5 = 23 = 5 × 7 − 5 − 7. Half of 0 to 23 fails: 12. Three sizes have no formula; search gives 43 for 6, 9 and 20.

---

## What this builds on

- [Residue classes](03-residue-classes.md): the five remainder rows, each opened by its doorstep.
- [Bezout's identity](../02-Greatest%20Common%20Divisor%20and%20Euclid%27s%20Algorithm/04-bezouts-identity.md): any multiple of the gcd is a mix; twice, it settles three sizes.
- [Solving a x ≡ b (mod n)](05-linear-congruences.md): one count of 7s from 0 to 4 lands in each row.
- [Coprime numbers](../02-Greatest%20Common%20Divisor%20and%20Euclid%27s%20Algorithm/05-coprime-numbers.md): no shared factor above 1, which makes the gaps end.

## Where this goes next

- [Powers on the clock](../04-Powers%20on%20the%20Clock/01-modular-exponentiation.md): the next shelf starts here, turning from sums of multiples to multiplying a number by itself many times on a clock.
- [Pseudo-polynomial time](../../24-Computability%20and%20complexity/03-Time%20Complexity/06-pseudo-polynomial-time-and-numbers-in-the-input.md): why this card's upward search is fast only for small sizes.

Left open: as the number of sizes grows, can the largest gap still be found quickly? The next shelf turns to powers.

---

## Sources

Verified 2026-11-23: every link below resolves to the publisher's page.

- Ramírez Alfonsín, J. L. *The Diophantine Frobenius Problem*. Oxford University Press, 2005. [doi:10.1093/acprof:oso/9780198568209.001.0001](https://doi.org/10.1093/acprof:oso/9780198568209.001.0001). Chapter 1: methods faster than search. Chapters 2 and 5: the two-size formula and gap count.
- Brauer, Alfred. "On a Problem of Partitions." *American Journal of Mathematics* 64 (1942): 299–312. [doi:10.2307/2371684](https://doi.org/10.2307/2371684). Early work on three or more sizes.
- Curtis, Frank. "On Formulas for the Frobenius Number of a Numerical Semigroup." *Mathematica Scandinavica* 67 (1990): 190–192. [doi:10.7146/math.scand.a-12330](https://doi.org/10.7146/math.scand.a-12330). No polynomial formula exists for three sizes.
