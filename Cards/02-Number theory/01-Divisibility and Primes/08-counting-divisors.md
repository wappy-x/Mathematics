# Counting divisors: read how many divisors a number has straight off its prime factorisation

[Syllabus](../../../SYLLABUS.md) → [Number theory](../../../SYLLABUS.md#w02) → [Divisibility and Primes](../../../SYLLABUS.md#w02-s01) → Counting divisors

---

## General Overview

A box holds 96 floor tiles. Lay all 96 in one rectangle — every tile used, no gaps, no cutting. How many shapes? Turning a shape round is not a new shape.

You start listing. 1 by 96. 2 by 48. 3 by 32. 4 by 24. 6 by 16. 8 by 12. Six, and you are fairly sure that is all.

Each side of each shape divides 96 with nothing left over — it is a **divisor** ([Divides](01-divides.md)). So the question is how many divisors 96 has, and the factorisation answers it without listing. 96 is 2 × 2 × 2 × 2 × 2 × 3: five 2s and one 3. Add one to each count and multiply: (5 + 1) × (1 + 1) = 12 divisors, which pair off into six rectangles.

**Add one to how many times each prime appears in the factorisation, multiply those numbers together, and that is how many divisors there are.**

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

| Piece | Plain meaning | In our box of 96 |
| --- | --- | --- |
| a prime | no divisor but 1 and itself ([Primes and composites](05-primes-and-composites.md)) | 2 and 3 |
| how often it appears | count it in the factorisation | five 2s, one 3 |
| one more than that count | the choices for that prime, counting the choice of taking none | 6 and 2 |
| a divisor | goes in with nothing left over ([Divides](01-divides.md)) | any cell of the grid |

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

---

## Sources

Verified 6 Sep 2026; every link resolves.

- Hardy, G. H., and E. M. Wright. *An Introduction to the Theory of Numbers*, 6th ed. Oxford University Press, 2008. [Publisher page](https://global.oup.com/academic/product/an-introduction-to-the-theory-of-numbers-9780199219865). Chapter 16, in full.
- Apostol, Tom M. *Introduction to Analytic Number Theory*. Springer, 1976. [doi:10.1007/978-1-4757-5579-4](https://doi.org/10.1007/978-1-4757-5579-4). Chapter 2, the counting and sum rules.
- OEIS Foundation. *Sequence A000005, the number of divisors*. [oeis.org/A000005](https://oeis.org/A000005). Every number's count: 1, 2, 2, 3, 2, 4 and on.
