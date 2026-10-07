# Euclid's algorithm: divide, keep the remainder, repeat, and the last non-zero remainder is the gcd

[Syllabus](../../../SYLLABUS.md) → [Number theory](../../../SYLLABUS.md#w02) → [Greatest Common Divisor and Euclid's Algorithm](../../../SYLLABUS.md#w02-s02) → Running the algorithm

---

## General Overview

Two cable drums in a van: 1071 m on one, 462 m on the other. The job needs equal lengths, every piece the same, no scrap on either drum. How long can a piece be?

The biggest length dividing both evenly is the **greatest common divisor**, or **gcd**: the largest number going into both with nothing left over. Listing what divides each and comparing finds it ([Greatest common divisor](01-gcd.md)), slowly.

Euclid's way takes three divisions. Divide the bigger by the smaller, keep the remainder — the bit left over — throw the bigger away, and repeat with the smaller and that remainder. Stop when a remainder is zero.

1071 = 2 × 462 + 147
462 = 3 × 147 + 21
147 = 7 × 21 + 0

The last remainder before that zero is 21. Cut at **21 m**: 51 pieces off the big drum, 22 off the small, 73 in all, both empty.

**Each division swaps the pair for a smaller pair with the same common divisors, so when a remainder hits zero the number you were dividing by is the answer.**

### The picture

```mermaid
flowchart LR
  A["1071 and 462"] -->|"1071 = 2 x 462 + 147"| B["462 and 147"]
  B -->|"462 = 3 x 147 + 21"| C["147 and 21"]
  C -->|"147 = 7 x 21 + 0"| D["gcd = 21"]
```

Each arrow is one division; the pair becomes divisor and remainder.

---

## The formula

The run is the formula:

**1071 = 2 × 462 + 147, then 462 = 3 × 147 + 21, then 147 = 7 × 21 + 0, so the gcd is 21**

**Read it aloud:** divide, note the remainder, divide the old smaller number by that remainder, repeat until a remainder is zero; the one before it is the gcd.

| Piece | Plain meaning | In our run |
| --- | --- | --- |
| the pair at each step | bigger, then smaller | 1071 and 462, 462 and 147, 147 and 21 |
| the quotient | how many whole times the smaller fits | 2, 3, 7 |
| the remainder | what is left over | 147, 21, 0 |
| the gcd | biggest number dividing both | 21 |

The quotients do no work here, but they are not junk: [Bezout's identity](04-bezouts-identity.md) uses them, and [Continued fractions](../07-For%20the%20Curious/05-continued-fractions-and-leap-years.md) reads them as a number.

---

## Why it works

### Step 0: the swap loses nothing

Take any number dividing 1071 and 462 evenly. The first line rearranges to 147 = 1071 − 2 × 462, and the difference of two of its multiples is another multiple. So it divides 147.

Now the reverse: any number dividing 462 and 147 divides 2 × 462 + 147, which is 1071. So the numbers dividing 1071 and 462 are *exactly* those dividing 462 and 147 — same list, same biggest member.

### Step 1: it stops, and the last line is easy

A remainder is always smaller than what you divided by: 147 under 462, 21 under 147, 0 under 21. Whole numbers falling every step and never going below zero cannot fall for ever, so a remainder hits zero. That is well-ordering: [Strong induction and the least element](../../01-Foundations/06-Proof/05-strong-induction-and-well-ordering.md).

That last line says 21 divides 147, and nothing bigger than 21 divides 21, so 21 is the biggest dividing both. Walk it back up: 21 is also the gcd of 462 and 147, and of 1071 and 462. In general the stop says gcd(n, 0) = n: n divides itself, and divides 0 too.

<details>
<summary>How many divisions can this take?</summary>

The slowest pairs are Fibonacci neighbours, each number the sum of the two before it — 34 and 55. Every quotient but the last is 1, the smallest chop: gcd(55, 34) takes 8 divisions where the drums took 3. Lamé proved in 1844 that the count never passes five divisions per digit of the smaller number: 34 has two digits, ceiling 5 × 2 = 10.

</details>

The other road is on [Greatest common divisor](01-gcd.md): split both into primes, multiply the shared ones. Same answer, but finding the factorisations is the expensive part.

---

## Worked numbers, by hand

In metres.

| Step | Arithmetic | Value |
| --- | --- | --- |
| divide 1071 by 462 | 1071 = 2 × 462 + 147 | 147 |
| divide 462 by 147 | 462 = 3 × 147 + 21 | 21 |
| divide 147 by 21 | 147 = 7 × 21 + 0 | 0 |
| last non-zero remainder | the gcd | **21** |
| pieces, both drums | 1071 ÷ 21 = 51, 462 ÷ 21 = 22 | **73** |

73 identical lengths, two empty drums. The code checks it a second way: every length up to 462 tried against both, and 21 is the biggest that fits.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Reading off the last quotient | 7 | 21 is bigger and fits too: 219 pieces, not 73 |
| Stopping one line early | 147 | 147 does not divide 462: 21 m stranded |
| Grabbing the first shared factor | 3 | 21 fits too: 511 pieces, not 73 |

---

## Code, from first principles, and it actually runs

Nothing is imported. The drums are worked the plain way, then checked by a road that knows nothing of Euclid: every length up to 462 tried, biggest dividing both kept. Then the three wrong cuts.

### Python

```python
# Euclid's algorithm -- the check behind the card.  Nothing is imported.  Two
# cable drums, 1071 m and 462 m, to be cut into equal lengths with nothing
# left over.  Plain way: divide, keep the remainder, repeat.  Second road:
# try every length that divides both and keep the biggest.  They must agree.
def euclid(a, b):                # the gcd, how many divisions it took, the divisions
    rows, steps = [], 0
    while b:
        rows.append((f"{a} = {a // b} x {b} + {a % b}", a % b))
        a, b, steps = b, a % b, steps + 1
    return a, steps, rows
def biggest_common_divisor(a, b):     # the slow road, kept for the cross-check
    return max(d for d in range(1, min(a, b) + 1) if a % d == 0 and b % d == 0)
def row(name, value):
    print(f"{name:<52}{value:>4}")
g, steps, rows = euclid(1071, 462)
for text, r in rows:
    row(text, r)
row(f"the last non-zero remainder, after {steps} divisions", g)
row("every length tried, the biggest that divides both", biggest_common_divisor(1071, 462))
row(f"pieces at {g} m: {1071 // g} from one drum, {462 // g} from the other", 1071 // g + 462 // g)
row(f"cut at 7 m instead: {1071 // 7} and {462 // 7}", 1071 // 7 + 462 // 7)
row(f"cut at 3 m instead: {1071 // 3} and {462 // 3}", 1071 // 3 + 462 // 3)
row("stop at 147 m: metres wasted off the 462 m drum", 462 % 147)
gf, sf, _ = euclid(55, 34)
print(f"slowest pair its size: gcd(55, 34) = {gf}, {sf} divisions, ceiling 5 x 2 = {5 * 2}")
assert (g, steps) == (21, 3) and 1071 % g == 0 and 462 % g == 0
assert g == biggest_common_divisor(1071, 462)
assert 1071 // g + 462 // g == 73 and 1071 // 7 + 462 // 7 == 219
print("ALL CHECKS PASS")
```

**Ran 2026-09-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
1071 = 2 x 462 + 147                                 147
462 = 3 x 147 + 21                                    21
147 = 7 x 21 + 0                                       0
the last non-zero remainder, after 3 divisions        21
every length tried, the biggest that divides both     21
pieces at 21 m: 51 from one drum, 22 from the other   73
cut at 7 m instead: 153 and 66                       219
cut at 3 m instead: 357 and 154                      511
stop at 147 m: metres wasted off the 462 m drum       21
slowest pair its size: gcd(55, 34) = 1, 8 divisions, ceiling 5 x 2 = 10
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Euclid's algorithm -- the same check as the Python, in Rust.  No crates.
// Two cable drums, 1071 m and 462 m, to be cut into equal lengths with
// nothing left over.  Plain way: divide, keep the remainder, repeat.  Second
// road: try every length that divides both and keep the biggest.  They agree.
fn euclid(a: i64, b: i64) -> (i64, i64, Vec<(String, i64)>) {
    let (mut a, mut b, mut steps, mut rows) = (a, b, 0i64, Vec::new());
    while b != 0 {
        rows.push((format!("{} = {} x {} + {}", a, a / b, b, a % b), a % b));
        let r = a % b;
        a = b;
        b = r;
        steps += 1;
    }
    (a, steps, rows)
}
fn biggest_common_divisor(a: i64, b: i64) -> i64 {   // the slow road, for the cross-check
    (1..=a.min(b)).filter(|d| a % d == 0 && b % d == 0).max().unwrap()
}
fn row(name: &str, value: i64) { println!("{:<52}{:>4}", name, value); }
fn main() {
    let (g, steps, rows) = euclid(1071, 462);
    for (text, r) in &rows { row(text, *r); }
    row(&format!("the last non-zero remainder, after {} divisions", steps), g);
    row("every length tried, the biggest that divides both", biggest_common_divisor(1071, 462));
    row(&format!("pieces at {} m: {} from one drum, {} from the other", g, 1071 / g, 462 / g),
        1071 / g + 462 / g);
    row(&format!("cut at 7 m instead: {} and {}", 1071 / 7, 462 / 7), 1071 / 7 + 462 / 7);
    row(&format!("cut at 3 m instead: {} and {}", 1071 / 3, 462 / 3), 1071 / 3 + 462 / 3);
    row("stop at 147 m: metres wasted off the 462 m drum", 462 % 147);
    let (gf, sf, _) = euclid(55, 34);
    println!("slowest pair its size: gcd(55, 34) = {}, {} divisions, ceiling 5 x 2 = {}", gf, sf, 5 * 2);
    assert!((g, steps) == (21, 3) && 1071 % g == 0 && 462 % g == 0);
    assert!(g == biggest_common_divisor(1071, 462));
    assert!(1071 / g + 462 / g == 73 && 1071 / 7 + 462 / 7 == 219);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
1071 = 2 x 462 + 147                                 147
462 = 3 x 147 + 21                                    21
147 = 7 x 21 + 0                                       0
the last non-zero remainder, after 3 divisions        21
every length tried, the biggest that divides both     21
pieces at 21 m: 51 from one drum, 22 from the other   73
cut at 7 m instead: 153 and 66                       219
cut at 3 m instead: 357 and 154                      511
stop at 147 m: metres wasted off the 462 m drum       21
slowest pair its size: gcd(55, 34) = 1, 8 divisions, ceiling 5 x 2 = 10
ALL CHECKS PASS
```

Both outputs match line for line: whole metres, nothing to round.

> [!TIP]
> **Try changing**
> Guess first, then run it. The asserts are pinned to the drums, so one will fire.
> - **Swap the drums.** Start from `euclid(462, 1071)`: the first division gives 0 with 462 over, which flips the pair into order. Still 21.
> - **Make the drums share nothing.** Change the 462 in `euclid(1071, 462)` to 460, and in the brute-force line beneath it. The last non-zero remainder is 1, so only 1 m pieces empty both: the drums are **coprime** ([Coprime numbers](05-coprime-numbers.md)).

---

## The usual mistake

> [!warning]
> **Reading off the last quotient instead of the last non-zero remainder.** The final line is 147 = 7 × 21 + 0, and that 7 is loud. But 7 is only how many times 21 fits into 147. Cut at 7 m and nothing complains — no scrap — you just cut 219 pieces where 73 would do.
>
> - **Stopping when a remainder gets small rather than zero.** 21 shows up on line two, but is the answer only because line three divides cleanly.
> - **Reaching for the factors first.** Primes give the same 21, but finding them is the slow half, hopeless at bank-login sizes.

---

## Where you meet it in real life

- **Fractions in lowest terms.** Reducing a fraction divides top and bottom by their gcd, found this way: [Fractions](../../01-Foundations/01-Everyday%20Arithmetic/07-fractions.md).
- **Keys and codes.** Bank logins lean on the gap between the two roads here: gcd is cheap, factoring is not. Two columns wider, the same loop builds a key: [Bezout's identity](04-bezouts-identity.md).
- **Cutting stock.** Timber, tape, sheet metal: two supplies cut to one size with no offcut, at their gcd.

> **Say it back**
> The gcd is the biggest number dividing two numbers with nothing left over. Divide the bigger by the smaller, keep the remainder, then divide the old smaller by that remainder, and keep going. Whatever divides one pair divides the next, and back, so the answer never moves while the numbers shrink. Remainders cannot fall below zero, so one is zero in the end — and the one before it is the answer. For the drums: 21 m, three divisions.

---

## What this builds on

- [Multiplying and dividing](../../01-Foundations/01-Everyday%20Arithmetic/03-multiplying-and-dividing.md): dividing one whole number by another, which every line here is.
- [Division with a remainder](../01-Divisibility%20and%20Primes/04-division-with-remainder.md): the quotient-and-remainder split, and why a remainder is always the smaller.
- [Greatest common divisor](01-gcd.md): what the gcd is, and the factor-list route this replaces.

## Where this goes next

- [Bezout's identity](04-bezouts-identity.md): run the same divisions backwards and the gcd comes out as whole-number helpings of the two starting numbers.
- [Continued fractions](../07-For%20the%20Curious/05-continued-fractions-and-leap-years.md): the discarded quotients, in order, give the best simple fractions near a ratio — how calendars pick leap years.

---

## Sources

Verified 6 Sep 2026; every link resolves.

- Euclid. *The Thirteen Books of the Elements, Vol. 2*, trans. Thomas L. Heath. Dover, 1956. [Publisher page](https://store.doverpublications.com/products/9780486600895). Book VII, Propositions 1 and 2.
- Knuth, Donald E. *The Art of Computer Programming, Volume 2*, 3rd ed. Addison-Wesley, 1997. [Publisher page](https://www.informit.com/store/art-of-computer-programming-volume-2-seminumerical-9780201896848). Section 4.5.2: step counts, Lamé's bound.
- Shoup, Victor. *A Computational Introduction to Number Theory and Algebra*, 2nd ed. Cambridge University Press, 2009. [Author's full text](https://www.shoup.net/ntb/). Chapter 4: the algorithm and its speed.
