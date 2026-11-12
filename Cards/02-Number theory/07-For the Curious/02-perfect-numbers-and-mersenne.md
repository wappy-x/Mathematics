# Perfect numbers and Mersenne primes: 6, 28, 496 and the record-prime hunt

[Syllabus](../../../SYLLABUS.md) → [Number theory](../README.md) → [For the Curious](../README.md#s07) → Perfect numbers and Mersenne primes

---

## General Overview

A double-six domino set has 28 tiles. Deal them into equal piles, every tile used: 1, 2, 4, 7 or 14 all work, and the whole box as one pile of 28.

Ignore that last one and add the rest: 1 + 2 + 4 + 7 + 14 = 28. The pile sizes rebuild the set.

Each of those goes into 28 with nothing left over — a **divisor** ([Divides](../01-Divisibility%20and%20Primes/01-divides.md)). Every divisor but 28 itself is a **proper divisor**.

**A number is perfect when its proper divisors — everything that goes into it, except itself — add back up to it.**

Almost nothing does this: 6, 28, 496, 8128, then nothing until the numbers get huge.

**What kind of fact this is:** a theorem, proved in Why it works: Euclid's recipe always makes a perfect number. Euler's converse for even numbers is stated without proof, and odd perfect numbers are an open question as of 2026-11-11.

### The picture: every divisor of 28

| twos taken | 1 | 2 | 4 |
| --- | --- | --- | --- |
| **on its own** | 1 | 2 | 4 |
| **times 7** | 7 | 14 | 28 |

28 is 4 × 7: the top row is the doubling run 1, 2, 4, the bottom is that run times 7. Six cells, six divisors.

---

## The formula

Three moves:

**Double 1 along: 1, 2, 4, then 8. Take one off that last doubling: 8 − 1 = 7. If that is prime, multiply it by the doubling just below: 4 × 7 = 28, and 28 is perfect.**

**Read it aloud:** eight take away one is seven, seven is prime, so four times seven, twenty-eight, is perfect.

| Piece | Plain meaning | In our 28 |
| --- | --- | --- |
| the doubling run | 1, doubled again and again ([Exponents](../../01-Foundations/03-Powers%2C%20Roots%20and%20Logarithms/01-exponents-and-powers.md)) | 1, 2, 4 — the next doubling is 8 |
| a Mersenne number | one less than a doubling, after Marin Mersenne, a French friar of the 1600s | 8 − 1 = 7 |
| a Mersenne prime | that number when prime: no divisor but 1 and itself ([Primes and composites](../01-Divisibility%20and%20Primes/05-primes-and-composites.md)) | 7 |
| the perfect number | the Mersenne prime times the doubling below it | 4 × 7 = 28 |

### When it holds

- **The Mersenne number is prime.** 2047 = 23 × 89 is not, so 1024 × 2047 = 2096128 has proper divisors adding to 2325392, not 2096128.
- **Proper divisors only.** Count 28 itself and the sum is 56, twice the number.
- **Even numbers only.** The recipe and Euler's proof cover even perfect numbers. No odd one is known, and none is ruled out.

---

## Why it works

### Step 0: a doubling run lands one short of the next doubling

1 + 2 + 4 = 7, one short of 8. Double the total and the run shifts up: twice 1 + 2 + 4 is 2 + 4 + 8, the same run with the 1 dropped and 8 added. So twice the total is the total, minus 1, plus 8. Take the total off both sides: what is left is the total, and it is 8 − 1 = 7.

### Step 1: with 7 prime, 28 has six divisors

28 is 2 × 2 × 7 and nothing else ([Prime factorisation](../01-Divisibility%20and%20Primes/07-prime-factorisation.md)). A divisor takes some of the twos — 1, 2 or 4 — and either the 7 or not ([Counting divisors](../01-Divisibility%20and%20Primes/08-counting-divisors.md)). That is the grid above.

### Step 2: add the two rows, and a 2 falls out

The bottom row is the top row times 7, so add both at once: (1 + 2 + 4) × (1 + 7) = 7 × 8 = 56. The first bracket is the doubling run, 8 − 1 = 7 by Step 0. The second is 1 + 7 only because 7 is prime, with no other divisors to add in.

So every divisor of 28 adds to 56, which is 2 × 28. Drop the 28 and the proper divisors add to 28. Nothing here was special to 28: the brackets multiply to twice the number whenever the recipe's Mersenne number is prime.

That is Euclid, around 300 BC. Euler proved the return trip in the 1700s, published only after his death — every even perfect number is built this way. Odd ones are the open question: none found, none ruled out.

<details>
<summary>Why the count of doublings has to be prime too</summary>

1 to 2 to 4 to 8 is three doublings, and 3 is prime. That is forced: when the count is itself two smaller numbers multiplied, the Mersenne number splits with it — six doublings gives 63, and 7 goes into it.

</details>

---

## Worked numbers, by hand

The 28 dominoes, end to end:

| Step | Arithmetic | Value |
| --- | --- | --- |
| the doubling run | 1 + 2 + 4 | 7 |
| the next doubling | 4 × 2 | 8 |
| one off it, and prime | 8 − 1 | 7 |
| the perfect number | 4 × 7 | 28 |
| all its divisors | 1 + 2 + 4 + 7 + 14 + 28 | 56 |
| the same, two brackets | (1 + 2 + 4) × (1 + 7) | 56 |
| the proper ones | 56 − 28 | **28** |

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Counting 28 itself as a proper divisor | 56 | That is every divisor, always twice the number |
| Skipping the prime check: eleven doublings, 1024 × 2047 = 2096128 | 2325392 | 2047 = 23 × 89, so its divisors overshoot |

---

## Code, from first principles, and it actually runs

Nothing is imported but a logarithm and a rounding-down, and only to count digits. 28 is done the plain way — list what goes in, add — then again by Euclid's two brackets, then the recipe on the first four Mersenne primes, each answer checked against a by-hand divisor sum.

### Python

```python
# Perfect numbers and Mersenne primes -- the check behind the card.  28 is done
# the plain way, its proper divisors listed and added, then again by Euclid's
# recipe, then the recipe on the first four.  log10 only counts digits.
from math import floor, log10
def divisors(n):                       # every d that goes into n, n itself last
    return [d for d in range(1, n + 1) if n % d == 0]
def digit_count(twos):                 # digits in that many 2s multiplied, minus 1
    return floor(twos * log10(2)) + 1
def row(name, value):
    print(f"{name:<44}{value:>8}")

d28 = divisors(28)
print("28 = " + " + ".join(str(d) for d in d28[:-1]))
row("proper divisors of 28 add to", sum(d28[:-1]))
row("all divisors of 28 add to, that is 2 x 28", sum(d28))
row("Euclid's way, (1 + 2 + 4) x (1 + 7) = 7 x 8", (1 + 2 + 4) * (1 + 7))
pairs = [(2, 3), (3, 7), (5, 31), (7, 127)]
print("the recipe: " + ", ".join(f"{2 ** (p - 1)} x {m} = {2 ** (p - 1) * m}" for p, m in pairs))
hand = [sum(divisors(2 ** (p - 1) * m)[:-1]) for p, m in pairs]
print("added up by hand: " + ", ".join(str(s) for s in hand))
print("2047 = 23 x 89, not prime, and 1024 x 2047 =", 1024 * 2047)
row("proper divisors of 2096128 add to", sum(divisors(2096128)[:-1]))
row("digits in the record prime, 136279841 twos", digit_count(136279841))
row("digits in its perfect number, 52nd known", digit_count(2 * 136279841 - 1))
assert d28 == [1, 2, 4, 7, 14, 28] and sum(d28[:-1]) == 28
assert sum(d28) == (1 + 2 + 4) * (1 + 7) == 56
assert [2 ** (p - 1) * m for p, m in pairs] == hand == [6, 28, 496, 8128]
assert sum(divisors(2096128)[:-1]) == 2325392 and 23 * 89 == 2047
assert digit_count(136279841) == 41024320 and digit_count(2 * 136279841 - 1) == 82048640
print("ALL CHECKS PASS")
```

**Ran 2026-09-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
28 = 1 + 2 + 4 + 7 + 14
proper divisors of 28 add to                      28
all divisors of 28 add to, that is 2 x 28         56
Euclid's way, (1 + 2 + 4) x (1 + 7) = 7 x 8       56
the recipe: 2 x 3 = 6, 4 x 7 = 28, 16 x 31 = 496, 64 x 127 = 8128
added up by hand: 6, 28, 496, 8128
2047 = 23 x 89, not prime, and 1024 x 2047 = 2096128
proper divisors of 2096128 add to            2325392
digits in the record prime, 136279841 twos  41024320
digits in its perfect number, 52nd known    82048640
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Perfect numbers and Mersenne primes -- the same check as
// perfect_numbers_and_mersenne_check.py, in Rust.  No crates.  28 the plain
// way, then Euclid's recipe, then the recipe on the first four.  The f64
// log10 only counts digits in the record prime.
fn divisors(n: i64) -> Vec<i64> {      // every d that goes into n, n itself last
    (1..=n).filter(|d| n % d == 0).collect()
}
fn proper_sum(n: i64) -> i64 {         // the same list, with n itself dropped
    divisors(n).iter().sum::<i64>() - n
}
fn digit_count(twos: f64) -> i64 {     // digits in that many 2s multiplied, minus 1
    (twos * 2f64.log10()).floor() as i64 + 1
}
fn row(name: &str, value: i64) { println!("{:<44}{:>8}", name, value); }

fn main() {
    let d28 = divisors(28);
    let parts: Vec<String> = d28[..d28.len() - 1].iter().map(|d| d.to_string()).collect();
    println!("28 = {}", parts.join(" + "));
    row("proper divisors of 28 add to", proper_sum(28));
    row("all divisors of 28 add to, that is 2 x 28", d28.iter().sum::<i64>());
    row("Euclid's way, (1 + 2 + 4) x (1 + 7) = 7 x 8", (1 + 2 + 4) * (1 + 7));
    let pairs = [(2i64, 3i64), (3, 7), (5, 31), (7, 127)];
    let recipe: Vec<String> = pairs.iter()
        .map(|&(p, m)| format!("{} x {} = {}", 1i64 << (p - 1), m, (1i64 << (p - 1)) * m)).collect();
    println!("the recipe: {}", recipe.join(", "));
    let sums: Vec<i64> = pairs.iter().map(|&(p, m)| proper_sum((1i64 << (p - 1)) * m)).collect();
    let shown: Vec<String> = sums.iter().map(|s| s.to_string()).collect();
    println!("added up by hand: {}", shown.join(", "));
    println!("2047 = 23 x 89, not prime, and 1024 x 2047 = {}", 1024 * 2047);
    row("proper divisors of 2096128 add to", proper_sum(2096128));
    row("digits in the record prime, 136279841 twos", digit_count(136279841.0));
    row("digits in its perfect number, 52nd known", digit_count(2.0 * 136279841.0 - 1.0));
    assert!(d28 == vec![1, 2, 4, 7, 14, 28] && proper_sum(28) == 28);
    assert!(d28.iter().sum::<i64>() == (1 + 2 + 4) * (1 + 7) && d28.iter().sum::<i64>() == 56);
    assert!(sums == vec![6, 28, 496, 8128]);
    assert!(proper_sum(2096128) == 2325392 && 23 * 89 == 2047);
    assert!(digit_count(136279841.0) == 41024320 && digit_count(2.0 * 136279841.0 - 1.0) == 82048640);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
28 = 1 + 2 + 4 + 7 + 14
proper divisors of 28 add to                      28
all divisors of 28 add to, that is 2 x 28         56
Euclid's way, (1 + 2 + 4) x (1 + 7) = 7 x 8       56
the recipe: 2 x 3 = 6, 4 x 7 = 28, 16 x 31 = 496, 64 x 127 = 8128
added up by hand: 6, 28, 496, 8128
2047 = 23 x 89, not prime, and 1024 x 2047 = 2096128
proper divisors of 2096128 add to            2325392
digits in the record prime, 136279841 twos  41024320
digits in its perfect number, 52nd known    82048640
ALL CHECKS PASS
```

Both outputs match line for line: whole numbers, nothing to round.

### Lean

Lean proves Euclid's recipe for every count of doublings whose Mersenne number is prime.

- When the Mersenne number is prime, it times the doubling just below it is perfect.
- Then every divisor of that number, itself included, adds to twice the number.
- A Mersenne number can be prime only when the count of doublings is prime.
- The card's numbers: 28's proper divisors, 6, 28, 496 and 8128 perfect, and 2047 = 23 × 89.

The sum 2325392 for 2096128 and the record prime's digit counts are left to the Python and Rust checks.

```lean
-- Perfect numbers and Mersenne primes: whenever one less than a doubling of 1 is prime, that prime times the doubling below it is a perfect number (Euclid), all its divisors add to twice it, a prime Mersenne number needs a prime count of doublings, and the card's numbers 6, 28, 496, 8128 and 2047 = 23 × 89 come out as it says.
import Mathlib.NumberTheory.LucasLehmer
import Mathlib.NumberTheory.Divisors
import Mathlib.Tactic.Simproc.Divisors
import Mathlib.Tactic.NormNum.Prime

open Nat

open ArithmeticFunction in
open scoped ArithmeticFunction.sigma in
theorem helper_sum_divisors (k : ℕ) (hp : (mersenne (k + 1)).Prime) :
    ∑ i ∈ (2 ^ k * mersenne (k + 1)).divisors, i = 2 * (2 ^ k * mersenne (k + 1)) := by
  have h2 : σ 1 (2 ^ k) = mersenne (k + 1) := by
    simp_rw [sigma_one_apply, mersenne, ← one_add_one_eq_two, ← geom_sum_mul_add 1 (k + 1)]
    norm_num
  rw [← mul_assoc, ← pow_succ', ← sigma_one_apply, mul_comm,
    isMultiplicative_sigma.map_mul_of_coprime ((Odd.coprime_two_right (by simp)).pow_right _),
    h2]
  simp [hp, sigma_one_apply]

#print axioms helper_sum_divisors

/-- Euclid's recipe. Double 1 along `k + 1` times to reach `2 ^ (k + 1)`, and take one off to get
the Mersenne number `mersenne (k + 1) = 2 ^ (k + 1) - 1`. If that Mersenne number is prime, then
it times the doubling just below, `2 ^ k`, is perfect: its proper divisors (every divisor except
the number itself) add back up to it. -/
theorem euclid_mersenne_prime_gives_perfect (k : ℕ) (hp : (mersenne (k + 1)).Prime) :
    Nat.Perfect (2 ^ k * mersenne (k + 1)) := by
  rw [Nat.perfect_iff_sum_divisors_eq_two_mul (by positivity)]
  exact helper_sum_divisors k hp

/-- Counting the number itself too: when the Mersenne number `2 ^ (k + 1) - 1` is prime, every
divisor of `2 ^ k * (2 ^ (k + 1) - 1)`, the number included, adds to exactly twice the number. -/
theorem sum_all_divisors_is_twice (k : ℕ) (hp : (mersenne (k + 1)).Prime) :
    ∑ i ∈ (2 ^ k * mersenne (k + 1)).divisors, i = 2 * (2 ^ k * mersenne (k + 1)) := by
  exact helper_sum_divisors k hp

/-- The count of doublings has to be prime too: if `2 ^ p - 1` is prime, then `p` is prime.
(Required, not sufficient: `p = 11` is prime but `2 ^ 11 - 1 = 2047 = 23 × 89` is not.) -/
theorem mersenne_prime_needs_prime_count (p : ℕ) (hp : (mersenne p).Prime) : p.Prime := by
  exact Nat.Prime.of_mersenne hp

-- 28 = 1 + 2 + 4 + 7 + 14: its proper divisors, and they add back to 28.
example : Nat.properDivisors 28 = {1, 2, 4, 7, 14} := by decide
example : ∑ i ∈ Nat.properDivisors 28, i = 28 := by decide
-- Counting 28 itself: every divisor adds to 56, twice 28.
example : ∑ i ∈ Nat.divisors 28, i = 56 := by decide
-- Step 0: the doubling run 1 + 2 + 4 is one short of 8.
example : 1 + 2 + 4 = 8 - 1 := by decide
-- Euclid's two brackets for 28.
example : (1 + 2 + 4) * (1 + 7) = 56 ∧ 56 = 2 * 28 := by decide
-- The recipe on the first four Mersenne primes: 2 × 3, 4 × 7, 16 × 31, 64 × 127.
example : mersenne 2 = 3 ∧ mersenne 3 = 7 ∧ mersenne 5 = 31 ∧ mersenne 7 = 127 := by
  simp [mersenne]
example : (3 : ℕ).Prime ∧ (7 : ℕ).Prime ∧ (31 : ℕ).Prime ∧ (127 : ℕ).Prime := by norm_num
example : 2 * 3 = 6 ∧ 4 * 7 = 28 ∧ 16 * 31 = 496 ∧ 64 * 127 = 8128 := by decide
example : Nat.Perfect 6 := by decide
example : Nat.Perfect 28 := by decide
example : Nat.Perfect 496 := by decide
example : Nat.Perfect 8128 := by
  rw [Nat.perfect_iff_sum_properDivisors (by norm_num)]
  simp [Nat.properDivisors_ofNat]
-- Eleven doublings: 11 is prime, but 2047 = 23 × 89 is not, and 1024 × 2047 = 2096128.
example : mersenne 11 = 2047 ∧ 2047 = 23 * 89 ∧ 1024 * 2047 = 2096128 := by
  simp [mersenne]
example : (11 : ℕ).Prime ∧ ¬ (2047 : ℕ).Prime := by norm_num
-- Six doublings: 2 ^ 6 - 1 = 63, and 7 goes into it.
example : mersenne 6 = 63 ∧ 7 ∣ 63 := by
  simp [mersenne]

#print axioms euclid_mersenne_prime_gives_perfect
#print axioms sum_all_divisors_is_twice
#print axioms mersenne_prime_needs_prime_count
```

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'helper_sum_divisors' depends on axioms: [propext, Classical.choice, Quot.sound]
'euclid_mersenne_prime_gives_perfect' depends on axioms: [propext, Classical.choice, Quot.sound]
'sum_all_divisors_is_twice' depends on axioms: [propext, Classical.choice, Quot.sound]
'mersenne_prime_needs_prime_count' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it. The asserts are pinned, so expect one to fire.
> - **Take the eleven-doubling case seriously.** Add `(11, 2047)` to `pairs`: the by-hand line answers 2325392, not 2096128, and the third assert fires.

---

## The usual mistake

> [!warning]
> **Thinking a prime count of doublings is enough.** Eleven doublings, and 11 is prime. But 2048 − 1 = 2047 = 23 × 89: no Mersenne prime, no perfect number. Required, not sufficient — which is why the hunt is a hunt and not a list. Nobody knows whether the Mersenne primes run out either.
>
> - Waiting for an odd perfect number. None found, none ruled out: the state of it, not a gap in your reading.
> - Reading "the 52nd known" as "the 52nd". Not every count below the record has been tested.

---

## Where you meet it in real life

- **A record-prime headline.** On 21 October 2024 the Great Internet Mersenne Prime Search announced the largest known prime: 136,279,841 twos multiplied together, then 1 taken off — 41,024,320 digits, only the 52nd Mersenne prime found. Euclid's recipe turns it into the 52nd known perfect number, 82,048,640 digits long.
- **The machines hunting it.** Volunteers run Lucas–Lehmer, a test built for this shape: start at 4, square and take 2 off, two fewer times than the count of doublings, on a clock the size of the Mersenne number ([Powers on the clock](../04-Powers%20on%20the%20Clock/01-modular-exponentiation.md)). Land on 0 and it is prime.
- **Sorting numbers by their divisors.** Overshoot and a number is abundant, fall short and it is deficient; perfect is the knife edge.

> **Say it back**
> A number is perfect when everything that goes into it, itself not counted, adds back up to it: 28 = 1 + 2 + 4 + 7 + 14. Euclid's recipe makes them: double 1 along, take one off the last doubling, and if that is prime, multiply it by the doubling below. It works because the divisors split into two brackets that multiply to exactly twice the number. Euler proved every even perfect number comes that way, so the perfect-number hunt and the Mersenne-prime hunt are one job.

---

## What this builds on

- [Counting divisors](../01-Divisibility%20and%20Primes/08-counting-divisors.md): why 28 has six divisors and where to find them.
- [Prime factorisation](../01-Divisibility%20and%20Primes/07-prime-factorisation.md): that 28 is 2 × 2 × 7 and nothing else, which closes the grid.
- [Exponents](../../01-Foundations/03-Powers%2C%20Roots%20and%20Logarithms/01-exponents-and-powers.md): the doubling run, written short.

## Where this goes next

Nothing depends on this card; shelf 7 is detours. Its neighbours:

- [Pythagorean triples](01-pythagorean-triples.md): another recipe that turns two small numbers into whole numbers with a hidden pattern.
- [How primes thin out](03-how-primes-thin-out.md): how many primes there are on average, where this card hunts single huge ones.
- [Goldbach, twin primes and friends](04-goldbach-and-open-problems.md): where the odd perfect number's unproven cousins live.
- [Continued fractions](05-continued-fractions-and-leap-years.md): Euclid again, his algorithm read as nested fractions.

The question this card leaves open: is there an odd perfect number, and do the Mersenne primes ever run out?

---

## Sources

Verified 2026-11-11: every link below resolves to the publisher's page.

- Great Internet Mersenne Prime Search. "52nd Known Mersenne Prime Discovered", 21 October 2024. [Press release](https://www.mersenne.org/primes/press/M136279841.html). The record prime and its digits.
- Euclid. *Elements*, Book IX, Proposition 36, in D. E. Joyce's edition. [Clark University](https://mathcs.clarku.edu/~djoyce/elements/bookIX/propIX36.html). The recipe, about 300 BC.
- Crandall, Richard, and Carl Pomerance. *Prime Numbers: A Computational Perspective*, 2nd ed. Springer, 2005. [doi:10.1007/0-387-28979-8](https://doi.org/10.1007/0-387-28979-8). Sections 1.3 and 4.2, the Euclid-Euler theorem.
