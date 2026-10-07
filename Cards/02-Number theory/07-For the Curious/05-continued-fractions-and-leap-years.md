---
type: card
wing: 02-Number theory
shelf: For the Curious
topic: Approximations
item: Continued fractions
kind: method
status: verified
updated: 2026-09-06
needs_first:
  - "[[Cards/02-Number theory/02-Greatest Common Divisor and Euclid's Algorithm/03-euclidean-algorithm|euclidean-algorithm]]"
  - "[[Cards/01-Foundations/01-Everyday Arithmetic/07-fractions|fractions]]"
  - "[[Cards/01-Foundations/01-Everyday Arithmetic/08-decimals|decimals]]"
next: []
tags:
  - mathematics
  - number theory
  - continued-fractions-and-leap-years
---

# Continued fractions: Euclid's algorithm read as nested fractions, and why the leap-year rule is 97 in 400

Number theory → For the Curious → Approximations → Continued fractions

---

## General Overview

A year is not 365 days. It is 365.2422 days, near enough: 365 whole days and a leftover of 0.2422 of a day. Leap days are how the calendar swallows it. So: what is the cheapest fraction close to 0.2422? Cheap means a small bottom number — how many years until the rule repeats.

Euclid's algorithm answers it ([euclidean-algorithm](../02-Greatest%20Common%20Divisor%20and%20Euclid%27s%20Algorithm/03-euclidean-algorithm.md)). Run it on 0.2422 written as a fraction, 1211/5000, and it returns whole numbers: 0, 4, 7, 1, 3, 4, 1, 1, 1, 2. The leading 0 is step 0 — no whole days in the leftover. Cut the list short after step 1, then 2, 3, 4, and you get 1/4, 7/29, 8/33, 31/128 — each the best fraction of its size. The first, one leap day every four years, is Julius Caesar's rule.

**Euclid's algorithm on a fraction returns a list of whole numbers; cutting the list short gives the best cheap approximations, cheapest first.**

### The picture

```
Days the calendar drifts in 400 years.  One block = 0.1 days.
A minus means the calendar year is too short instead of too long.

  1/4       3.120  ███████████████████████████████
  7/29     -0.328  ███
  8/33      0.090  █
 31/128    -0.005
 97/400     0.120  █
```

1/4 is the outlier: 3.120 days too many every 400 years — what Pope Gregory's reform had to mop up.

---

## The formula

Stack the steps into nested fractions and the leftover is exact:

**0.2422 = 1 / (4 + 1 / (7 + 1 / (1 + 1 / (3 + …))))**

**Read it aloud:** one over four — except the four is four-and-a-bit, and the bit is one over seven-and-a-bit, each correction smaller than the last.

That stack is a **continued fraction**. Cut it at a plus sign and work out what is left: a plain fraction. Those cut-offs are the **convergents** — from here on, the **stops**.

| Piece | Plain meaning | In our year |
| --- | --- | --- |
| the leftover | what is left after 365 whole days | 0.2422 |
| a step | one number from Euclid's list | 0, 4, 7, 1, 3, … |
| a stop | the fraction from cutting short | 1/4 at step 1 … 31/128 at step 4 |
| top and bottom | leap days inserted, years in the cycle | 31 and 128 |

---

## Why it works

### Step 0: peel off the whole part, then flip what is left

Write down a number's whole part. The leftover is under 1, so turn it upside down: now it is over 1, with a whole part of its own. Write that down. Repeat. Each flip gives the next step.

### Step 1: that is Euclid's algorithm

0.2422 is exactly 2422/10000, which cuts down to 1211/5000. Divide with remainder over and over, each time dividing the last divisor by the last remainder. Asking how many whole times 1211 goes into 5000 asks for the whole part of the flipped leftover.

| Divide | Whole times | What is left |
| --- | --- | --- |
| 1211 by 5000 | 0 | 1211 |
| 5000 by 1211 | 4 | 156 |
| 1211 by 156 | 7 | 119 |
| 156 by 119 | 1 | 37 |
| 119 by 37 | 3 | 8 |

The list carries on 4, 1, 1, 1, 2, then a remainder of 0 shuts it down: every ordinary fraction's list stops, because Euclid's algorithm stops ([irrational-numbers](../../01-Foundations/02-The%20Number%20Line/03-irrational-numbers.md) is where they never do).

The stops build themselves from the steps: new top number = the step, times the previous top, plus the top before that. Bottoms the same. Start from 0/1, with 1/0 imagined before it. From 7/29 and the step 1: 8 = 1 × 7 + 1, 33 = 1 × 29 + 4.

### Step 2: each stop is the best of its size

**No fraction with a bottom number up to 128 is closer to 0.2422 than 31/128 is.** Not close — closest, out of every bottom number up to 128.

Cutting the stack short is the only loss, and what you drop sits under every division above it. The stops overshoot and undershoot in turn, and the gap shrinks faster than the bottom number grows. Square roots give lists that repeat forever — a wing 03 story.

---

## Worked numbers, by hand

| Stop | Arithmetic | Value, then drift over 400 years |
| --- | --- | --- |
| 1/4 | 1 ÷ 4 | 0.250000, 3.120 |
| 7/29 | 7 ÷ 29 | 0.241379, -0.328 |
| 8/33 | 8 ÷ 33 | 0.242424, 0.090 |
| 31/128 | 31 ÷ 128 | 0.242188, -0.005 |
| 97/400 | 97 ÷ 400 | 0.242500, **0.120** |

Drift is (the value − 0.2422) × 400: an average rate on a common 400-year yardstick. Count the rule out year by year and 97 appears on its own: of 400 years, 100 are divisible by four, and 3 of those centuries get skipped.

The calendar on your wall is 0.120 days out after 400 years; a whole day of drift takes thousands of years.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Stopping at 1/4 | 3.120 | a quarter is bigger than 0.2422 |
| Treating 97/400 as best of its size | 0.120, not -0.005 | 31/128 is closer |
| Calling a stop exact | 0.090, for 8/33 | best of its size is not exact |

---

## Code, from first principles, and it actually runs

Nothing is imported. Road one runs Euclid's algorithm on 1211/5000 and builds the stops as it goes. Road two ignores it: it tries every bottom number up to a cap, keeps the closest, and counts the Gregorian leap years, 1 to 400. Then the same steps on pi.

### Python

```python
# Continued fractions and the leap year -- the check behind the card.  Nothing is
# imported.  A year is 365.2422 days; Euclid on the leftover 0.2422 = 1211/5000 gives
# the steps, stopping early gives the fractions, brute force is the second road.
LEFT = 1211 / 5000
def euclid_steps(a, b):                        # 1211/5000 -> 0, 4, 7, 1, 3, ...
    out = []
    while b: out.append(a // b); a, b = b, a % b
    return out
def stops(steps):                              # the early stops, as top/bottom
    top, t_before, bot, b_before, out = steps[0], 1, 1, 0, [(steps[0], 1)]
    for s in steps[1:]:
        top, t_before, bot, b_before = s * top + t_before, top, s * bot + b_before, bot
        out.append((top, bot))
    return out
def best_upto(cap):                            # closest fraction, bottom <= cap
    return min(((round(q * LEFT), q) for q in range(1, cap + 1)), key=lambda f: abs(LEFT - f[0] / f[1]))
steps = euclid_steps(1211, 5000); four = stops(steps)[1:5]
leaps = sum(1 for y in range(1, 401) if y % 4 == 0 and (y % 100 != 0 or y % 400 == 0))
print(f"{'a year, in days':<40}365.2422")
print(f"{'the leftover after 365 whole days':<40}0.2422 = 1211/5000")
print(f"{'the whole-number steps, from Euclid':<40}" + ", ".join(map(str, steps)))
rows = [(f"   stop after step {i}", p, q) for i, (p, q) in enumerate(four, 1)] + [("   the Gregorian rule", 97, 400)]
for name, p, q in rows: print(f"{name:<22}{p:>4}/{q:<5}{p / q:.6f}{(p / q - LEFT) * 400:>9.3f} days adrift per 400 years")
print(f"counting the real rule over 400 years: {400 // 4} minus {400 // 4 - leaps} century skips is {leaps} leap days")
print(f"every stop beats every fraction with a bottom up to its own; best up to 400 is {best_upto(400)[0]}/{best_upto(400)[1]}, not 97/400")
print("pi as 3.14159265358979, same trick: " + ", ".join(f"{p}/{q}" for p, q in stops(euclid_steps(314159265358979, 100000000000000))[:4]))
assert four == [(1, 4), (7, 29), (8, 33), (31, 128)] and leaps == 97
assert all(best_upto(q) == (p, q) for p, q in four) and best_upto(400) == (31, 128)
assert abs(97 / 400 - LEFT) > 20 * abs(31 / 128 - LEFT)
print("ALL CHECKS PASS")
```

**Ran 2026-09-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
a year, in days                         365.2422
the leftover after 365 whole days       0.2422 = 1211/5000
the whole-number steps, from Euclid     0, 4, 7, 1, 3, 4, 1, 1, 1, 2
   stop after step 1     1/4    0.250000    3.120 days adrift per 400 years
   stop after step 2     7/29   0.241379   -0.328 days adrift per 400 years
   stop after step 3     8/33   0.242424    0.090 days adrift per 400 years
   stop after step 4    31/128  0.242188   -0.005 days adrift per 400 years
   the Gregorian rule   97/400  0.242500    0.120 days adrift per 400 years
counting the real rule over 400 years: 100 minus 3 century skips is 97 leap days
every stop beats every fraction with a bottom up to its own; best up to 400 is 31/128, not 97/400
pi as 3.14159265358979, same trick: 3/1, 22/7, 333/106, 355/113
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Continued fractions and the leap year -- the same check in Rust, no crates.
// A year is 365.2422 days; Euclid on the leftover 0.2422 = 1211/5000 gives the
// steps, stopping early gives the fractions, brute force is the second road.
const LEFT: f64 = 1211.0 / 5000.0;
fn euclid_steps(mut a: i64, mut b: i64) -> Vec<i64> {   // 1211/5000 -> 0, 4, 7, 1, 3, ...
    let mut out = Vec::new();
    while b != 0 { out.push(a / b); let r = a % b; a = b; b = r; }
    out
}
fn stops(steps: &[i64]) -> Vec<(i64, i64)> {            // the early stops, as top/bottom
    let (mut t, mut tb, mut b, mut bb) = (steps[0], 1i64, 1i64, 0i64);
    let mut out = vec![(t, b)];
    for &s in &steps[1..] { let (nt, nb) = (s * t + tb, s * b + bb); tb = t; bb = b; t = nt; b = nb; out.push((t, b)); }
    out
}
fn best_upto(cap: i64) -> (i64, i64) {                  // closest fraction, bottom <= cap
    let (mut bp, mut bq, mut be) = (0i64, 1i64, f64::INFINITY);
    for q in 1..=cap {
        let p = (q as f64 * LEFT).round() as i64;
        if (LEFT - p as f64 / q as f64).abs() < be { be = (LEFT - p as f64 / q as f64).abs(); bp = p; bq = q; }
    }
    (bp, bq)
}
fn main() {
    let steps = euclid_steps(1211, 5000); let four = stops(&steps)[1..5].to_vec();
    let leaps = (1..=400).filter(|y| y % 4 == 0 && (y % 100 != 0 || y % 400 == 0)).count() as i64;
    println!("{:<40}365.2422", "a year, in days");
    println!("{:<40}0.2422 = 1211/5000", "the leftover after 365 whole days");
    println!("{:<40}{}", "the whole-number steps, from Euclid", steps.iter().map(|s| s.to_string()).collect::<Vec<_>>().join(", "));
    let mut rows: Vec<(String, i64, i64)> = four.iter().enumerate().map(|(i, &(p, q))| (format!("   stop after step {}", i + 1), p, q)).collect();
    rows.push(("   the Gregorian rule".to_string(), 97, 400));
    for (name, p, q) in &rows { let v = *p as f64 / *q as f64; println!("{:<22}{:>4}/{:<5}{:.6}{:>9.3} days adrift per 400 years", name, p, q, v, (v - LEFT) * 400.0); }
    println!("counting the real rule over 400 years: {} minus {} century skips is {} leap days", 400 / 4, 400 / 4 - leaps, leaps);
    println!("every stop beats every fraction with a bottom up to its own; best up to 400 is {}/{}, not 97/400", best_upto(400).0, best_upto(400).1);
    println!("pi as 3.14159265358979, same trick: {}", stops(&euclid_steps(314159265358979, 100000000000000))[..4].iter().map(|&(p, q)| format!("{}/{}", p, q)).collect::<Vec<_>>().join(", "));
    assert!(four == vec![(1, 4), (7, 29), (8, 33), (31, 128)] && leaps == 97);
    assert!(four.iter().all(|&(p, q)| best_upto(q) == (p, q)) && best_upto(400) == (31, 128));
    assert!((97.0 / 400.0 - LEFT).abs() > 20.0 * (31.0 / 128.0 - LEFT).abs());
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
a year, in days                         365.2422
the leftover after 365 whole days       0.2422 = 1211/5000
the whole-number steps, from Euclid     0, 4, 7, 1, 3, 4, 1, 1, 1, 2
   stop after step 1     1/4    0.250000    3.120 days adrift per 400 years
   stop after step 2     7/29   0.241379   -0.328 days adrift per 400 years
   stop after step 3     8/33   0.242424    0.090 days adrift per 400 years
   stop after step 4    31/128  0.242188   -0.005 days adrift per 400 years
   the Gregorian rule   97/400  0.242500    0.120 days adrift per 400 years
counting the real rule over 400 years: 100 minus 3 century skips is 97 leap days
every stop beats every fraction with a bottom up to its own; best up to 400 is 31/128, not 97/400
pi as 3.14159265358979, same trick: 3/1, 22/7, 333/106, 355/113
ALL CHECKS PASS
```

The two outputs match line for line.

> [!TIP]
> **Try changing**
> Guess first, then run it. The asserts are pinned to the real year, so expect one to fire.
> - **Feed it the Gregorian year.** Change 1211/5000 to 2425/10000, which is 0.2425. The steps come out 0, 4, 8, 12, the last stop is 97/400 exactly, drift zero.
> - **Widen the search.** Change the 400 fed to `best_upto` to 545, three places, not the 400-year figures. The winner jumps to 132/545, the next stop on the list, and the assert fires.

---

## The usual mistake

> [!warning]
> **Thinking a bigger bottom number always means a better fraction.** 97/400 has a bigger bottom number than 31/128 and sits much further from the truth. Only the stops are guaranteed best of their size.
>
> - Reading the step list 0, 4, 7, 1, 3 as the answer. It is the recipe.
> - Expecting the drift to shrink in a straight line: it goes 3.120, then -0.328, then 0.090.
> - Assuming the calendar picked the best fraction going. It picked 97/400 for the round centuries, at 0.120 days of drift.

---

## Where you meet it in real life

- **The calendar you are using now.** 97 leap days in 400 years, century skips included. The cycles it sets up drive [day-of-the-week](../05-Check%20Digits%2C%20Calendars%20and%20Cycles/03-day-of-the-week.md) and [cycles-that-realign](../05-Check%20Digits%2C%20Calendars%20and%20Cycles/04-cycles-that-realign.md).
- **Cutting gears, tuning instruments.** The bottom number is teeth to cut or notes in a scale, so you take the cheapest stop that works.
- **Pi in your head.** The same steps on 3.14159265358979 give 3/1, 22/7, 333/106, 355/113. The last is closer to pi than any fraction its size — the fourth stop.

> **Say it back**
> A year is 365.2422 days and the 0.2422 has to go somewhere. Euclid's algorithm on it returns whole numbers; stack them into nested fractions and the leftover is exact. Cut it short and you get a stop: 1/4, 7/29, 8/33, 31/128, each the closest fraction with a bottom number that small. 1/4 is the Julian calendar, 3.120 days adrift per 400 years. The Gregorian 97/400 is not a stop but a rounder neighbour of 8/33, 0.120 days adrift.

---

## What this builds on

- [euclidean-algorithm](../02-Greatest%20Common%20Divisor%20and%20Euclid%27s%20Algorithm/03-euclidean-algorithm.md): the quotients it throws away chasing a gcd are the steps here.
- [fractions](../../01-Foundations/01-Everyday%20Arithmetic/07-fractions.md): top over bottom, and cutting 2422/10000 down.
- [decimals](../../01-Foundations/01-Everyday%20Arithmetic/08-decimals.md): reading 365.2422 as whole days plus a leftover.

## Where this goes next

Nothing on disk depends on this card yet; wing 03's Pell card will. The rest of the shelf: [pythagorean-triples](01-pythagorean-triples.md), [perfect-numbers-and-mersenne](02-perfect-numbers-and-mersenne.md), [how-primes-thin-out](03-how-primes-thin-out.md), [goldbach-and-open-problems](04-goldbach-and-open-problems.md).

---

## Sources

Verified 6 Sep 2026; every link resolves.

- Khinchin, A. Ya. *Continued Fractions*. Dover, 1997. [Publisher page](https://store.doverpublications.com/products/9780486696300). The proof that each stop is best of its size.
- Reingold, Edward M., and Nachum Dershowitz. *Calendrical Calculations: The Ultimate Edition*, 4th ed. Cambridge University Press, 2018. [doi:10.1017/9781107415058](https://doi.org/10.1017/9781107415058). Year lengths, leap rules.
- United States Naval Observatory. *Introduction to Calendars*. [aa.usno.navy.mil](https://aa.usno.navy.mil/faq/calendars). The Julian and Gregorian leap rules.
