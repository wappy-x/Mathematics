# How primes thin out: the prime counting function and the n over log n rule

[Syllabus](../../../SYLLABUS.md) → [Number theory](../README.md) → [For the Curious](../README.md#s07) → How primes thin out

---

## General Overview

The corridor of lockers from [The sieve of Eratosthenes](../01-Divisibility%20and%20Primes/06-sieve-of-eratosthenes.md). A hundred doors, sieved: 25 left open, one in four.

A thousand doors long: 168 open. A million long: 78,498 open, about one in thirteen.

The primes never run out — [There are infinitely many primes](../02-Greatest%20Common%20Divisor%20and%20Euclid%27s%20Algorithm/08-infinitude-of-primes.md) settles that — but they spread out.

That count has a shorthand. **pi(x)**, said "pi of x", is how many primes there are up to x (1 is not one of them) — nothing to do with circles. So pi(100) = 25, pi(1,000) = 168, pi(1,000,000) = 78,498.

And there is a rule for it, built out of a logarithm ([Logarithms](../../01-Foundations/03-Powers%2C%20Roots%20and%20Logarithms/05-logarithms.md)).

**Divide x by the natural log of x and you have roughly how many primes lie below x — and the further you walk, the better "roughly" does.**

### The picture: primes per hundred lockers

```
Primes among one hundred lockers, wherever you are standing. One block is one prime.
lockers 1 to 100                  █████████████████████████  25
lockers 901 to 1,000              ██████████████             14
the hundred just under 1,000,000  ████████                    8
```

Same corridor width each time; the primes are getting scarcer.

---

## The formula

**pi(x) is about x ÷ ln x**

At a million:

**pi(1,000,000) = 78,498, while 1,000,000 ÷ ln 1,000,000 = 1,000,000 ÷ 13.8155 = 72,382**

**ln x** is the natural log of x: the question [Logarithms](../../01-Foundations/03-Powers%2C%20Roots%20and%20Logarithms/05-logarithms.md) asks, with e (about 2.718) as the base, not 10 ([Natural log and doubling time](../../01-Foundations/04-Compound%20Growth%20and%20Discounting/05-natural-log-and-doubling-time.md)) — ln 1,000,000 = 13.8155 means e reaches a million after 13.8155 multiplies. It climbs painfully slowly, which is the point.

| Piece | Plain meaning | In our corridor | Push it up and the answer… |
| --- | --- | --- | --- |
| x | how far you count | 1,000,000 lockers | more primes, thinner share |
| pi(x) | how many of them are prime | pi(1,000,000) = 78,498 | the answer itself |
| ln x | a count of multiplies: the log | ln 1,000,000 = 13.8155 | ln 100 = 4.6052 to 13.8155: 10,000 times the corridor, three times the log |
| x ÷ ln x | the estimate | 72,382 | a bigger log, a lower estimate |
| the ratio | true count ÷ estimate, before rounding | 78,498 ÷ 72,382 = 1.084 | it heads towards 1 — the theorem |

Out loud: "n over log n".

---

## Why it works

### Step 0: every pass of the sieve takes a thinner slice

Every number that is not prime has a smaller prime dividing it; that is what the sieve lives on. The 2s take half the doors, the 3s a third of what is left, the 5s a fifth of that. Each pass thins the survivors by less than the one before. Nothing takes the last one — that is infinitude — but the share sags all the way.

### Step 1: near x, about one number in ln x is prime

At a million, ln 1,000,000 = 13.8155, so about one locker in fourteen is prime that far along. A real count agrees: the hundred just under a million hold 8 primes. Back at the start, the same hundred held 25.

### Step 2: add the shares up, and that is the rule

One in ln x prime, across x numbers, is about x ÷ ln x primes. Which also says how it goes wrong: the whole corridor is charged the log from the far end, where primes are thinnest, so the estimate lands low at every size in this card, and at every size past 17 — 22 against 25, 145 against 168, 72,382 against 78,498.

### Step 3: what was proved

Hadamard and de la Vallée Poussin, separately, in 1896: **the ratio of pi(x) to x ÷ ln x goes to 1 as x runs off without end.** That is the prime number theorem. Wing 06, complex analysis, proves it, and carries a sharper estimate — the logarithmic integral — that adds a share at every number.

---

## Worked numbers, by hand

The corridor of a million, sieved.

| Step | Arithmetic | Value |
| --- | --- | --- |
| sieve, count the open doors | pi(1,000,000) | 78,498 |
| its natural log | ln 1,000,000 | 13.8155 |
| the estimate | 1,000,000 ÷ 13.8155 | 72,382 |
| how far it falls short | 78,498 − 72,382 | 6,116 |
| the ratio | 78,498 ÷ 72,382 | **1.084** |

Short by 6,116 primes: the truth is 1.084 times the estimate.

At 100 the miss is 3 and the ratio 1.151; at 1,000, 23 and 1.161. Those ratios divide by the estimate unrounded: 21.71 and 144.76, not 22 and 145. The ratio drops towards 1, but not tidily: 1,000 is a shade worse than 100. The theorem promises the drift, not a better step each time.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Log base 10 instead of the natural log | 166,667 below a million | twice the true 78,498 |
| Reading pi(1,000) as the 1,000th prime | 7,919 | pi counts primes, it names none |
| Holding the opening rate of 25 per hundred | 250,000 below a million | the rate is local and falls |

---

## Code, from first principles, and it actually runs

Nothing is imported but the log. The corridor of a million is sieved and the open doors counted, then counted again by a slower road: dividing every number by everything up to its own square root ([Roots](../../01-Foundations/03-Powers%2C%20Roots%20and%20Logarithms/03-roots-and-fractional-exponents.md)), at both ends of the corridor. Both counts are set against x ÷ ln x.

### Python

```python
# How primes thin out -- the check behind the card.  Only log is imported.  A corridor of a
# million lockers is sieved, the doors left open are counted a second way by trial division,
# and those counts are set against x divided by the natural log of x.
from math import log
def sieve(n):                       # doors 2..n; slam every multiple of every door kept
    open_ = [True] * (n + 1)
    open_[0] = open_[1] = False
    for p in range(2, int(n ** 0.5) + 1):
        if open_[p]: open_[p * p::p] = [False] * len(range(p * p, n + 1, p))
    return open_
def is_prime(k):                    # second road: divide k by everything up to its root
    d = 2
    while d * d <= k and k % d: d += 1
    return d * d > k
def com(v): return f"{v:,}"         # 78498 -> 78,498

flags = sieve(1000000)
pi = lambda x: sum(flags[:x + 1])
print(f"{'x':>9}{'primes up to x':>16}{'ln x':>10}{'x / ln x':>12}{'miss':>8}{'ratio':>8}")
for x in (100, 1000, 1000000):
    g, p = x / log(x), pi(x)
    print(f"{com(x):>9}{com(p):>16}{log(x):>10.4f}{com(round(g)):>12}{com(p - round(g)):>8}{p / g:>8.3f}")
print(f"the 1000th prime is {com([k for k in range(2, 8000) if flags[k]][999])}, not {pi(1000)}")
print("log base 10 instead of ln predicts " + ", ".join(com(round(x * log(10) / log(x))) for x in (100, 1000, 1000000)))
print(f"primes per hundred lockers: {pi(100)} in the first, {pi(1000) - pi(900)} at 901 to 1000, {pi(1000000) - pi(999900)} in the last before a million")
print(f"a flat {pi(100)} per hundred all the way would give {com(pi(100) * 10000)}, not {com(pi(1000000))}")
assert pi(100) == 25 and pi(1000) == 168 and pi(1000000) == 78498
assert sum(1 for k in range(2, 101) if is_prime(k)) == 25 and sum(1 for k in range(2, 1001) if is_prime(k)) == 168 and sum(1 for k in range(999901, 1000001) if is_prime(k)) == 8
assert round(100 / log(100)) == 22 and round(1000 / log(1000)) == 145 and round(1000000 / log(1000000)) == 72382
print("ALL CHECKS PASS")
```

**Ran 2026-09-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
        x  primes up to x      ln x    x / ln x    miss   ratio
      100              25    4.6052          22       3   1.151
    1,000             168    6.9078         145      23   1.161
1,000,000          78,498   13.8155      72,382   6,116   1.084
the 1000th prime is 7,919, not 168
log base 10 instead of ln predicts 50, 333, 166,667
primes per hundred lockers: 25 in the first, 14 at 901 to 1000, 8 in the last before a million
a flat 25 per hundred all the way would give 250,000, not 78,498
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// How primes thin out -- the same check as how_primes_thin_out_check.py, in Rust.  No crates.
// A corridor of a million lockers is sieved, the doors left open are counted a second way by
// trial division, and those counts are set against x divided by the natural log of x.
fn sieve(n: usize) -> Vec<bool> {          // doors 2..n; slam every multiple of every door kept
    let mut open = vec![true; n + 1];
    open[0] = false; open[1] = false;
    let mut p = 2;
    while p * p <= n { if open[p] { let mut m = p * p; while m <= n { open[m] = false; m += p; } } p += 1; }
    open
}
fn is_prime(k: usize) -> bool {            // second road: divide k by everything up to its root
    let mut d = 2;
    while d * d <= k && k % d != 0 { d += 1; }
    d * d > k
}
fn com(v: i64) -> String {                 // 78498 -> 78,498
    let s = v.to_string(); let mut o = String::new();
    for (i, c) in s.chars().enumerate() { if i > 0 && (s.len() - i) % 3 == 0 { o.push(','); } o.push(c); }
    o
}
fn main() {
    let flags = sieve(1000000);
    let pi = |x: usize| flags[..=x].iter().filter(|b| **b).count() as i64;
    let d10 = |x: f64| com((x * 10f64.ln() / x.ln()).round() as i64);
    println!("{:>9}{:>16}{:>10}{:>12}{:>8}{:>8}", "x", "primes up to x", "ln x", "x / ln x", "miss", "ratio");
    for x in [100usize, 1000, 1000000] {
        let (g, p) = (x as f64 / (x as f64).ln(), pi(x));
        println!("{:>9}{:>16}{:>10.4}{:>12}{:>8}{:>8.3}", com(x as i64), com(p), (x as f64).ln(), com(g.round() as i64), com(p - g.round() as i64), p as f64 / g);
    }
    println!("the 1000th prime is {}, not {}", com((2..8000).filter(|k| flags[*k]).nth(999).unwrap() as i64), pi(1000));
    println!("log base 10 instead of ln predicts {}, {}, {}", d10(100.0), d10(1000.0), d10(1000000.0));
    println!("primes per hundred lockers: {} in the first, {} at 901 to 1000, {} in the last before a million",
             pi(100), pi(1000) - pi(900), pi(1000000) - pi(999900));
    println!("a flat {} per hundred all the way would give {}, not {}", pi(100), com(pi(100) * 10000), com(pi(1000000)));
    assert!(pi(100) == 25 && pi(1000) == 168 && pi(1000000) == 78498);
    assert!((2..=100).filter(|k| is_prime(*k)).count() == 25 && (2..=1000).filter(|k| is_prime(*k)).count() == 168 && (999901..=1000000).filter(|k| is_prime(*k)).count() == 8);
    assert!((100f64 / 100f64.ln()).round() == 22.0 && (1000f64 / 1000f64.ln()).round() == 145.0 && (1e6 / 1e6f64.ln()).round() == 72382.0);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
        x  primes up to x      ln x    x / ln x    miss   ratio
      100              25    4.6052          22       3   1.151
    1,000             168    6.9078         145      23   1.161
1,000,000          78,498   13.8155      72,382   6,116   1.084
the 1000th prime is 7,919, not 168
log base 10 instead of ln predicts 50, 333, 166,667
primes per hundred lockers: 25 in the first, 14 at 901 to 1000, 8 in the last before a million
a flat 25 per hundred all the way would give 250,000, not 78,498
ALL CHECKS PASS
```

Both outputs match line for line.

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **Make the corridor ten times longer.** Change both millions to ten million. Which way does the ratio move? Down, nearer 1, while the miss grows. The asserts still pass: they ask only about the first million.
> - **Open locker 1.** Drop the line shutting doors 0 and 1. Both swing open, so every count rises by two — 27 up to 100, 78,500 to a million — and the first assert fires.

---

## The usual mistake

> [!warning]
> **Thinking "the estimate gets better" means the gap closes.** It does not. The gap grows without limit: 3 at 100, 23 at 1,000, 6,116 at a million. What shrinks is that gap beside the size of the count — the ratio, 1.151 then 1.161 then 1.084, drifting to 1.
>
> - **pi(x) is not the x-th prime.** pi(1,000) = 168; the 1,000th prime is 7,919.
> - **The log is the natural one.** Base 10 predicts 166,667 below a million, against 78,498.
> - **Thinning is not stopping.** However far you walk there are more primes ahead ([There are infinitely many primes](../02-Greatest%20Common%20Divisor%20and%20Euclid%27s%20Algorithm/08-infinitude-of-primes.md)).

---

## Where you meet it in real life

- **Making keys.** RSA needs large random primes ([RSA in outline](../06-Codes%20and%20Secrets/03-rsa-in-outline.md)). About one number in ln x is prime near x, so a random search takes a few hundred tries at key sizes, not billions. The tries themselves are [The Miller-Rabin test](../06-Codes%20and%20Secrets/05-miller-rabin.md).
- **Answering without counting.** "How many primes below a billion?" One log gets within a few percent, no sieve.
- **The open questions.** Twin primes and Goldbach ([Goldbach, twin primes and friends](04-goldbach-and-open-problems.md)) ask about the pockets and pairs inside this thinning, and stay hard while the average is settled.

> **Say it back**
> pi(x) counts the primes up to x: 25 up to 100, 168 up to 1,000, 78,498 up to a million. They thin out as you walk: ever more smaller primes to catch a number. Near x about one number in ln x is prime, so below x there are about x ÷ ln x in all. The estimate lands low and its miss keeps growing, but the ratio of truth to estimate slides to 1 — the prime number theorem.

---

## What this builds on

- [The sieve of Eratosthenes](../01-Divisibility%20and%20Primes/06-sieve-of-eratosthenes.md): builds the corridor and the honest counts.
- [There are infinitely many primes](../02-Greatest%20Common%20Divisor%20and%20Euclid%27s%20Algorithm/08-infinitude-of-primes.md): the thinning never reaches zero, so a rule for the count is worth having.
- [Logarithms](../../01-Foundations/03-Powers%2C%20Roots%20and%20Logarithms/05-logarithms.md): a log is a count of multiplies, all ln x means here.
- [Log laws and log scales](../../01-Foundations/03-Powers%2C%20Roots%20and%20Logarithms/06-log-laws-and-log-scales.md): why a log climbs so slowly.

## Where this goes next

Nothing later needs this card; shelf 7 is detours. Sideways: [Goldbach, twin primes and friends](04-goldbach-and-open-problems.md) asks what this average cannot answer, and [Perfect numbers and Mersenne primes](02-perfect-numbers-and-mersenne.md) hunts single primes far past any corridor.

---

## Sources

Verified 6 Sep 2026; every link resolves.

- OEIS Foundation. Sequence A006880, the primes below 10, 100, 1,000 and so on. [oeis.org/A006880](https://oeis.org/A006880). Where 25, 168 and 78,498 were checked.
- Zagier, Don. "Newman's short proof of the prime number theorem". *American Mathematical Monthly* 104 (1997), 705-708. [PDF](https://people.mpim-bonn.mpg.de/zagier/files/doi/10.2307/2975232/fulltext.pdf). Three pages, dating the two 1896 proofs.
- Crandall, Richard, and Carl Pomerance. *Prime Numbers: A Computational Perspective*. Springer, 2005. [doi:10.1007/0-387-28979-8](https://doi.org/10.1007/0-387-28979-8). Chapter 1 states the theorem and the sharper estimate.
