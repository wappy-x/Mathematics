---
type: card
wing: 02-Number theory
shelf: For the Curious
topic: Special numbers
item: Perfect numbers and Mersenne primes
kind: theorem
status: verified
updated: 2026-09-06
needs_first:
  - "[[Cards/02-Number theory/01-Divisibility and Primes/08-counting-divisors|counting-divisors]]"
  - "[[Cards/02-Number theory/01-Divisibility and Primes/07-prime-factorisation|prime-factorisation]]"
  - "[[Cards/01-Foundations/03-Powers, Roots and Logarithms/01-exponents-and-powers|exponents-and-powers]]"
next: []
tags:
  - mathematics
  - number theory
  - perfect-numbers-and-mersenne
---

# Perfect numbers and Mersenne primes: 6, 28, 496 and the record-prime hunt

Number theory → For the Curious → Special numbers → Perfect numbers and Mersenne primes

---

## General Overview

A double-six domino set has 28 tiles. Deal them into equal piles, every tile used: 1, 2, 4, 7 or 14 all work, and the whole box as one pile of 28.

Ignore that last one and add the rest: 1 + 2 + 4 + 7 + 14 = 28. The pile sizes rebuild the set.

Each of those goes into 28 with nothing left over — a **divisor** ([divides](../01-Divisibility%20and%20Primes/01-divides.md)). Every divisor but 28 itself is a **proper divisor**.

**A number is perfect when its proper divisors — everything that goes into it, except itself — add back up to it.**

Almost nothing does this: 6, 28, 496, 8128, then nothing until the numbers get huge.

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

| Piece | Plain meaning | In our 28 |
| --- | --- | --- |
| the doubling run | 1, doubled again and again ([exponents-and-powers](../../01-Foundations/03-Powers%2C%20Roots%20and%20Logarithms/01-exponents-and-powers.md)) | 1, 2, 4 — the next doubling is 8 |
| a Mersenne number | one less than a doubling, after Marin Mersenne, a French friar of the 1600s | 8 − 1 = 7 |
| a Mersenne prime | that number when prime: no divisor but 1 and itself ([primes-and-composites](../01-Divisibility%20and%20Primes/05-primes-and-composites.md)) | 7 |
| the perfect number | the Mersenne prime times the doubling below it | 4 × 7 = 28 |

---

## Why it works

### Step 0: a doubling run lands one short of the next doubling

1 + 2 + 4 = 7, one short of 8. Double the total and the run shifts up: twice 1 + 2 + 4 is 2 + 4 + 8, the same run with the 1 dropped and 8 added. So twice the total is the total, minus 1, plus 8. Take the total off both sides: what is left is the total, and it is 8 − 1 = 7.

### Step 1: with 7 prime, 28 has six divisors

28 is 2 × 2 × 7 and nothing else ([prime-factorisation](../01-Divisibility%20and%20Primes/07-prime-factorisation.md)). A divisor takes some of the twos — 1, 2 or 4 — and either the 7 or not ([counting-divisors](../01-Divisibility%20and%20Primes/08-counting-divisors.md)). That is the grid above.

### Step 2: add the two rows, and a 2 falls out

The bottom row is the top row times 7, so add both at once: (1 + 2 + 4) × (1 + 7) = 7 × 8 = 56. The first bracket is the doubling run, 8 − 1 = 7 by Step 0. The second is 1 + 7 only because 7 is prime, with no other divisors to add in.

So every divisor of 28 adds to 56, which is 2 × 28. Drop the 28 and the proper divisors add to 28. Nothing here was special to 28: the brackets multiply to twice the number whenever the recipe's Mersenne number is prime. That is Euclid, around 300 BC. Euler proved the return trip a century later, published only after his death — every even perfect number is built this way. Odd ones are the open question: none found, none ruled out.

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
- **The machines hunting it.** Volunteers run Lucas–Lehmer, a test built for this shape: start at 4, square and take 2 off, two fewer times than the count of doublings, on a clock the size of the Mersenne number ([modular-exponentiation](../04-Powers%20on%20the%20Clock/01-modular-exponentiation.md)). Land on 0 and it is prime.
- **Sorting numbers by their divisors.** Overshoot and a number is abundant, fall short and it is deficient; perfect is the knife edge.

> **Say it back**
> A number is perfect when everything that goes into it, itself not counted, adds back up to it: 28 = 1 + 2 + 4 + 7 + 14. Euclid's recipe makes them: double 1 along, take one off the last doubling, and if that is prime, multiply it by the doubling below. It works because the divisors split into two brackets that multiply to exactly twice the number. Euler proved every even perfect number comes that way, so the perfect-number hunt and the Mersenne-prime hunt are one job.

---

## What this builds on

- [counting-divisors](../01-Divisibility%20and%20Primes/08-counting-divisors.md): why 28 has six divisors and where to find them.
- [prime-factorisation](../01-Divisibility%20and%20Primes/07-prime-factorisation.md): that 28 is 2 × 2 × 7 and nothing else, which closes the grid.
- [exponents-and-powers](../../01-Foundations/03-Powers%2C%20Roots%20and%20Logarithms/01-exponents-and-powers.md): the doubling run, written short.

## Where this goes next

Nothing depends on this card; shelf 7 is detours. Its neighbours: [pythagorean-triples](01-pythagorean-triples.md), [how-primes-thin-out](03-how-primes-thin-out.md), [goldbach-and-open-problems](04-goldbach-and-open-problems.md) — where the odd perfect number's unproven cousins live — and [continued-fractions-and-leap-years](05-continued-fractions-and-leap-years.md).

---

## Sources

Verified 6 Sep 2026; every link resolves.

- Great Internet Mersenne Prime Search. "52nd Known Mersenne Prime Discovered", 21 October 2024. [Press release](https://www.mersenne.org/primes/press/M136279841.html). The record prime and its digits.
- Euclid. *Elements*, Book IX, Proposition 36, in D. E. Joyce's edition. [Clark University](https://mathcs.clarku.edu/~djoyce/elements/bookIX/propIX36.html). The recipe, about 300 BC.
- Crandall, Richard, and Carl Pomerance. *Prime Numbers: A Computational Perspective*, 2nd ed. Springer, 2005. [doi:10.1007/0-387-28979-8](https://doi.org/10.1007/0-387-28979-8). Sections 1.3 and 4.2, the Euclid-Euler theorem.
