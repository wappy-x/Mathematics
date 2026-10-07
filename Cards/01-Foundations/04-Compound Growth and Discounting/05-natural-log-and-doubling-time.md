---
type: card
wing: 01-Foundations
shelf: Compound Growth and Discounting
topic: Continuous growth
item: Natural log and doubling time
kind: approximation
status: verified
updated: 2026-09-06
needs_first:
  - "[[Cards/01-Foundations/03-Powers, Roots and Logarithms/05-logarithms|logarithms]]"
  - "[[Cards/01-Foundations/04-Compound Growth and Discounting/04-compounding-frequency-and-e|compounding-frequency-and-e]]"
  - "[[Cards/01-Foundations/03-Powers, Roots and Logarithms/06-log-laws-and-log-scales|log-laws-and-log-scales]]"
next: []
tags:
  - mathematics
  - foundations
  - natural-log-and-doubling-time
---

# Natural log and doubling time: how long until the money doubles, and the rule of 72

Foundations → Compound Growth and Discounting → Continuous growth → Natural log and doubling time

---

## General Overview

A fund returns 8% a year. You put money in and leave it. How long until there is twice as much?

Most people guess twelve and a half years: 8 goes into 100 that many times. The answer is just over nine.

Each year's 8% lands on a bigger balance than the last — compounding, from [compound-interest](03-compound-interest.md). Nine years is not nine slices of 8%; it is 1.08 multiplied by itself nine times. How many multiplies by 1.08 reach a double? Counting multiplies is what a logarithm does ([logarithms](../03-Powers%2C%20Roots%20and%20Logarithms/05-logarithms.md)).

The log used here is the **natural log**, written **ln**: the log whose base is e, from [compounding-frequency-and-e](04-compounding-frequency-and-e.md). Any base would do; ln is the one finance uses. The count runs in fractions: 2 is 0.693 of the way to e, 1.08 only 0.077 of the way.

**Doubling time is ln 2 divided by the log of the growth factor, and 72 divided by the rate is close enough to say out loud.**

### The picture: real answer against shortcut

```
Years to double.  Each block is half a year.
8%, ln 2 / ln 1.08   ██████████████████              9.006
8%, the rule of 72   ██████████████████              9.000
5%, ln 2 / ln 1.05   ████████████████████████████   14.207
5%, the rule of 72   █████████████████████████████  14.400
```

At 8% the bars match. At 5% the shortcut runs longer: 14.400 against 14.207.

---

## The formula

The honest route:

**years to double = ln 2 ÷ ln (the growth factor)**

For the fund: **ln 2 ÷ ln 1.08 = 0.693147 ÷ 0.076961 = 9.006 years**

The shortcut, in your head:

**72 ÷ the rate in percent = 72 ÷ 8 = 9 years**

| Piece | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| the growth factor | one year's multiplier, an 8% rise as a decimal | 1.08 | fewer years |
| ln | the natural log: how many of e, multiplied, reach a number | ln 1.08 = 0.076961 | fewer years |
| ln 2 | that question asked of 2: one doubling | 0.693147 | it never moves |
| years to double | time to reach twice the start | 9.006 | this is the output |
| the rate in percent | the yearly rise, before it becomes a factor | 8 | fewer years |
| 72 | the shortcut's top number, easy to divide | 72 | more years |

---

## Why it works

### Step 0: doubling does not care how much money there is

$100 and $100,000 take the same time to double at the same rate: doubling is about the multiplier, not the pile. One year multiplies the balance by 1.08 ([growth-factors](01-growth-factors.md)), so doubled means a run of those multiplies comes to 2.

### Step 1: a log pulls the unknown out to the front

The unknown is buried in the count of multiplies. Log both sides and it comes out front: the log of a repeated multiply is the count times the log of what is multiplied ([log-laws-and-log-scales](../03-Powers%2C%20Roots%20and%20Logarithms/06-log-laws-and-log-scales.md)). That leaves the count times ln 1.08 against ln 2. Divide: 0.693147 ÷ 0.076961 = 9.006.

### Step 2: check it without logs

Multiply 1.08 by itself nine times: 1.999005. Ten times: 2.158925. The double falls inside the tenth year, where 9.006 sits.

### Step 3: where 72 comes from

For a modest rate, ln of the growth factor is nearly the rate as a decimal: ln 1.08 is 0.076961, a shade under 0.08. Swap them and the sum becomes ln 2 over the rate — in percent, 100 × ln 2 = 69.3147.

69.3147 is horrible to divide by in your head. 72 breaks into whole halves, thirds, quarters, sixths, eighths and ninths. Rounding up helps too. A smaller number underneath means more years, so the truth sits above 69.3147 over the rate. 72 covers it.

Continuous compounding makes that swap exact: ln 2 over the rate ([compounding-frequency-and-e](04-compounding-frequency-and-e.md)).

---

## Worked numbers, by hand

The fund at 8%, then the $100 at 5% from [compound-interest](03-compound-interest.md). Money to the cent.

| Step | Arithmetic | Value |
| --- | --- | --- |
| one doubling, and the growth factor logged | ln 2, then ln 1.08 | 0.693147, 0.076961 |
| years to double | 0.693147 ÷ 0.076961 | **9.006** |
| the shortcut | 72 ÷ 8 | **9.000** |
| the check, nine years | 1.08 by itself 9 times | 1.999005 |
| the check, ten years | 1.08 by itself 10 times | 2.158925 |
| the same sum at 5% | ln 2 ÷ ln 1.05 | **14.207** |
| the shortcut at 5% | 72 ÷ 5 | **14.400** |
| the $100 after 14 years | 100 × 1.05, fourteen times | **$197.99** |
| the $100 after 15 years | 100 × 1.05, fifteen times | **$207.89** |

Nine years leaves the fund a hair short. The $100 crosses double inside its fifteenth year.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Cutting 100% into 8% slices | 12.5 | each 8% lands on a bigger balance |
| Dividing ln 2 by the rate when interest lands once a year | 8.664 | the rate only resembles that log |
| Calling nine whole years a double | 1.999005 | the double lands at 9.006, not 9 |

---

## Code, from first principles, and it actually runs

Nothing is imported: ln is built here from a short series of odd powers. The second road carries no logs — 1.08 nine and ten times over, bracketing the double. Three asserts hold them together.

### Python

```python
# Natural log and doubling time -- the check behind the card.  Nothing is
# imported: ln is the series 2 * (y + y*y*y/3 + ...), y = (x - 1)/(x + 1).
# Road one is ln 2 / ln 1.08; road two multiplies 1.08 by itself 9 and 10
# times, and the doubling has to land between the two.
def ln(x):                            # natural log, built here from the series
    y = (x - 1.0) / (x + 1.0)
    term, total, k = y, 0.0, 1
    while abs(term) > 1e-18:
        total, term, k = total + term / k, term * y * y, k + 2
    return 2.0 * total
def grown(factor, years, out=1.0):    # the factor multiplied by itself
    for _ in range(years): out *= factor
    return out
def row(name, value): print(f"{name:<40}{value:>12}")
ln2 = ln(2.0)
eight, five = ln2 / ln(1.08), ln2 / ln(1.05)
row("ln 2", f"{ln2:.6f}")
row("ln 1.08 and ln 1.05", f"{ln(1.08):.6f} and {ln(1.05):.6f}")
row("100 x ln 2, the honest rule number", f"{100 * ln2:.4f}")
for rate, factor in ((8, 1.08), (5, 1.05)):
    row(f"years to double at {rate}%, ln 2 / ln {factor}", f"{ln2 / ln(factor):.3f}")
    row(f"the rule of 72 at {rate}%, 72 / {rate}", f"{72 / rate:.3f}")
row("1.08 multiplied by itself 9 times", f"{grown(1.08, 9):.6f}")
row("1.08 multiplied by itself 10 times", f"{grown(1.08, 10):.6f}")
row("$100 at 5% after 14 years, then 15", f"${100 * grown(1.05, 14):.2f} ${100 * grown(1.05, 15):.2f}")
print(f"the three mistakes come out at {100 / 8}, {ln2 / 0.08:.3f} and {grown(1.08, 9):.6f}")
assert abs(ln(1.25) + ln(1.6) - ln2) < 1e-14 and abs(ln(0.5) / ln(0.9) - 6.579) < 5e-4
assert grown(1.08, 9) < 2.0 < grown(1.08, 10) and f"{100 * grown(1.05, 14):.2f} {100 * grown(1.05, 15):.2f}" == "197.99 207.89"
assert 9 < eight < 10 and 14 < five < 15 and 72 / 8 < eight and five < 72 / 5
print("ALL CHECKS PASS")
```

**Ran 2026-09-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
ln 2                                        0.693147
ln 1.08 and ln 1.05                     0.076961 and 0.048790
100 x ln 2, the honest rule number           69.3147
years to double at 8%, ln 2 / ln 1.08          9.006
the rule of 72 at 8%, 72 / 8                   9.000
years to double at 5%, ln 2 / ln 1.05         14.207
the rule of 72 at 5%, 72 / 5                  14.400
1.08 multiplied by itself 9 times           1.999005
1.08 multiplied by itself 10 times          2.158925
$100 at 5% after 14 years, then 15      $197.99 $207.89
the three mistakes come out at 12.5, 8.664 and 1.999005
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Natural log and doubling time -- the same check as the Python one, in Rust.
// No crates.  ln is the series 2 * (y + y*y*y/3 + ...), y = (x - 1)/(x + 1).
// Road one is ln 2 / ln 1.08; road two multiplies 1.08 by itself 9 and 10
// times, and the doubling has to land between the two.
fn ln(x: f64) -> f64 {                       // natural log, built here from the series
    let y = (x - 1.0) / (x + 1.0);
    let (mut term, mut total, mut k) = (y, 0.0f64, 1i64);
    while term.abs() > 1e-18 { total += term / k as f64; term *= y * y; k += 2; }
    2.0 * total
}
fn grown(factor: f64, years: i64) -> f64 {   // the factor multiplied by itself
    let mut out = 1.0f64;
    for _ in 0..years { out *= factor; }
    out
}
fn row(name: &str, value: String) { println!("{:<40}{:>12}", name, value); }
fn main() {
    let ln2 = ln(2.0);
    let (eight, five) = (ln2 / ln(1.08), ln2 / ln(1.05));
    row("ln 2", format!("{:.6}", ln2));
    row("ln 1.08 and ln 1.05", format!("{:.6} and {:.6}", ln(1.08), ln(1.05)));
    row("100 x ln 2, the honest rule number", format!("{:.4}", 100.0 * ln2));
    for (rate, factor) in [(8.0f64, 1.08f64), (5.0, 1.05)] {
        row(&format!("years to double at {}%, ln 2 / ln {}", rate, factor), format!("{:.3}", ln2 / ln(factor)));
        row(&format!("the rule of 72 at {}%, 72 / {}", rate, rate), format!("{:.3}", 72.0 / rate));
    }
    row("1.08 multiplied by itself 9 times", format!("{:.6}", grown(1.08, 9)));
    row("1.08 multiplied by itself 10 times", format!("{:.6}", grown(1.08, 10)));
    row("$100 at 5% after 14 years, then 15", format!("${:.2} ${:.2}", 100.0 * grown(1.05, 14), 100.0 * grown(1.05, 15)));
    println!("the three mistakes come out at {}, {:.3} and {:.6}", 100.0 / 8.0, ln2 / 0.08, grown(1.08, 9));
    assert!((ln(1.25) + ln(1.6) - ln2).abs() < 1e-14 && (ln(0.5) / ln(0.9) - 6.579).abs() < 5e-4);
    assert!(grown(1.08, 9) < 2.0 && 2.0 < grown(1.08, 10) && format!("{:.2} {:.2}", 100.0 * grown(1.05, 14), 100.0 * grown(1.05, 15)) == "197.99 207.89");
    assert!(9.0 < eight && eight < 10.0 && 14.0 < five && five < 15.0 && 72.0 / 8.0 < eight && five < 72.0 / 5.0);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
ln 2                                        0.693147
ln 1.08 and ln 1.05                     0.076961 and 0.048790
100 x ln 2, the honest rule number           69.3147
years to double at 8%, ln 2 / ln 1.08          9.006
the rule of 72 at 8%, 72 / 8                   9.000
years to double at 5%, ln 2 / ln 1.05         14.207
the rule of 72 at 5%, 72 / 5                  14.400
1.08 multiplied by itself 9 times           1.999005
1.08 multiplied by itself 10 times          2.158925
$100 at 5% after 14 years, then 15      $197.99 $207.89
the three mistakes come out at 12.5, 8.664 and 1.999005
ALL CHECKS PASS
```

The two outputs match line for line.

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **Ask for tripling.** Swap ln 2 for the log of 3. The years climb, and 72 goes quiet: its top number was built for a doubling.
> - **Switch the compounding off.** Change `out *= factor` to `out += 0.08`, so the balance grows in flat slices. Doubling arrives at 12.5 years, the first mistake above, and the bracketing assert fires.

---

## The usual mistake

> [!warning]
> **Dividing 100 by the rate.** 100 ÷ 8 gives 12.5 years. It charges every year's 8% on the starting amount, so it is wrong every time. The real answer, 9.006, is shorter, and the gap is widest at low rates.
>
> - Dividing ln 2 by the rate when the interest lands once a year: 8.664 years, close enough to look right. It is honest only for continuous compounding.
> - Trusting 72 far from the middle of the range. Nearly exact at 8%, 9.000 against 9.006; already long at 5%, 14.400 against 14.207.
> - Reading a whole-year answer as the double. Nine years of 8% reaches 1.999005, not 2.
> - Feeding 72 a decimal. It wants the percent: 72 ÷ 8.

---

## Where you meet it in real life

- **Anything with a rate on it.** A savings account, a fund, an inflation figure: 72 over the rate turns a percentage into years. [compound-interest](03-compound-interest.md)
- **Growth in the news.** Users, prices, a waiting list, a disease: anything climbing by a steady percentage has a doubling time.
- **Half-life, turned around.** A thing losing 10% a year halves in ln 0.5 ÷ ln 0.9 = 6.58 years: ln of a half over ln of the shrink factor.

> **Say it back**
> Doubling is about the multiplier, not the money. At 8% the multiplier is 1.08, and doubling asks how many multiplies reach 2. A log answers: ln 2 ÷ ln 1.08 = 9.006 years. Without logs: 1.08 nine times over is 1.999005, ten times 2.158925 — the double sits between. The rule of 72 does that sum in your head: 72 ÷ 8 = 9.000, long at the bottom — 14.400 at 5%, where the truth is 14.207.

---

## What this builds on

- [logarithms](../03-Powers%2C%20Roots%20and%20Logarithms/05-logarithms.md): what a log is, a count of multiplies.
- [compounding-frequency-and-e](04-compounding-frequency-and-e.md): where e comes from, and so ln.
- [log-laws-and-log-scales](../03-Powers%2C%20Roots%20and%20Logarithms/06-log-laws-and-log-scales.md): the law that drags the count of multiplies to the front — the move this card turns on.

## Where this goes next

- [discounting-and-present-value](06-discounting-and-present-value.md): the same growth factor run backwards, money next year priced in today's dollars.

---

## Sources

Verified 6 Sep 2026; every link resolves.

- Pacioli, Luca. *Summa de arithmetica, geometria, proportioni et proportionalita*. Venice, 1494. [Scanned copy, Internet Archive](https://archive.org/details/summa-de-arithmetica-geometria-proportioni-et-proportionalita). The shortcut in print, no working shown.
- Euler, Leonhard. *Introduction to Analysis of the Infinite: Book I*. Translated by John D. Blanton. Springer, 1988. [doi:10.1007/978-1-4612-1021-4](https://doi.org/10.1007/978-1-4612-1021-4). The 1748 book that set e and ln on their modern footing.
- Maor, Eli. *e: The Story of a Number*. Princeton University Press. [Publisher page](https://press.princeton.edu/books/paperback/9780691168487/e-the-story-of-a-number). Where e came from, told without symbols.
