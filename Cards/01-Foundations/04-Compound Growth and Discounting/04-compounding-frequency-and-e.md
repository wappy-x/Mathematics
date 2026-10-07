# Compounding more often, and the number e: the ceiling on how fast 5% can grow

[Syllabus](../../../SYLLABUS.md) → [Foundations](../README.md) → [Compound Growth and Discounting](../README.md#s04) → Compounding more often, and the number e

---

## General Overview

Your bank pays 5% a year on $100. Paid once, at year end, that is $105.00.

Ask for it monthly. The bank cuts the 5% into twelve slices and pays one a month. Each slice is smaller, but the early ones sit there earning too, so the year ends above $105.00. Daily is higher again, barely. Every millionth of a second, higher still. The balance creeps up and never gets away: it walks to $105.13 and stops.

The stop is the interesting part. Paying more often is free money, and the free money runs out. Turn the dial up: one dollar at 100% for a year. Paid once, $2.000000. Twice, $2.250000. Monthly, $2.613035. Daily, $2.714567. A million times, $2.718280.

**Cutting a year's interest into more and finer payments always earns more, but the total is capped by a fixed number, 2.718281828, called e.**

### The picture: the ladder running out of room

```
$1.00 at 100% for a year, one block = 10 cents, part-blocks dropped

paid once a year               ████████████████████ 2.000000
paid twice a year              ██████████████████████ 2.250000
paid monthly, 12 times         ██████████████████████████ 2.613035
paid daily, 365 times          ███████████████████████████ 2.714567
paid a million times           ███████████████████████████ 2.718280
the ceiling, e by the series   ███████████████████████████ 2.718282
```

The first jump is worth a quarter of a dollar. Daily to a million payments is worth about four tenths of a cent.

---

## The formula

The formula is the payment schedule written out. One dollar at 100%, paid twice: half the rate, paid in twice.

**1.00 × (1 + 0.5) × (1 + 0.5) = 2.250000**

Paid monthly, same shape:

**1.00 × (1 + 1 ÷ 12), multiplied in twelve times over = 2.613035**

Cut finer and the answers climb toward the ceiling. The ceiling is a shrinking list, added up:

**1 + 1 + 1 ÷ 2 + 1 ÷ 6 + 1 ÷ 24 + … = 2.718282**

The same list with 0.05 in it, on $100:

**100.00 × (1 + 0.05 + 0.05 × 0.05 ÷ 2 + 0.05 × 0.05 × 0.05 ÷ 6 + …) = 105.127110, which is $105.13**

**Read it aloud:** cut the rate into equal slices, multiply by one-plus-a-slice once per slice, and however fine you cut, the year hits a ceiling.

| Piece | Plain meaning | In our example | Push it up… |
| --- | --- | --- | --- |
| the starting money | day-one balance | $1.00, then $100.00 | end rises in step |
| the yearly rate | percent promised for a year | 100%, then 5% | higher ceiling |
| the payments | how often interest lands | 1, 2, 12, 365 | more, by less each time |
| one slice | rate divided by payments | 100% ÷ 12 | finer, and more |
| the growth factor | what $1.00 becomes | 2.000000 to 2.718282 | runs into its own ceiling |
| e | the ceiling at 100% | 2.718281828 | nothing moves it |

---

## Why it works

### Splitting the rate does not split the growth

One dollar, 100%, paid twice. Half the rate is 50%, so midyear the account holds 1.50. The second 50% is charged on 1.50, not 1.00: it pays 0.75, and the year ends at 2.250000. That extra 0.25 is the second payment landing on the first one's interest.

### Every extra payment helps less

Monthly gets 2.613035, daily 2.714567, a million payments 2.718280. The extra only ever comes from interest earning interest inside the year, and finer slices only let that start sooner.

### Why it stops

Write out what earns what over the year, at 100%.

- 1 — your dollar
- 1 — the plain interest on it
- 1 ÷ 2 — interest on that interest
- 1 ÷ 6 — interest on *that*
- 1 ÷ 24 — and so on

Each term is the one before divided by the next counting number: halved, then a third, then a quarter. A list shrinking that fast has a finite total: 2.718282, which the ladder only ever reaches from below.

### The ceiling has a name

To nine decimals it is 2.718281828, and it is called **e**: a fixed number, like pi, that does not shift with the rate or the money. "Compounded continuously" means the ceiling was reached.

Put 0.05 in the list instead of 1 and the total comes out smaller: $100 ends at 105.127110, or $105.13 to the cent. Going backwards, from a balance to the time it took, needs the tool that undoes e: [Natural log and doubling time](05-natural-log-and-doubling-time.md).

---

## Worked numbers, by hand

One dollar at 100% for a year, six decimals so the ceiling shows. Then $100 at 5%, to the cent.

| Step | Arithmetic | Value |
| --- | --- | --- |
| paid once a year | 1.00 × (1 + 1) | 2.000000 |
| paid twice | 1.00 × (1 + 1 ÷ 2), twice | 2.250000 |
| paid monthly | 1.00 × (1 + 1 ÷ 12), 12 times | 2.613035 |
| paid daily | 1.00 × (1 + 1 ÷ 365), 365 times | 2.714567 |
| the ceiling | 1 + 1 + 1 ÷ 2 + 1 ÷ 6 + … | 2.718282 |
| $100 at 5%, once | 100.00 × (1 + 0.05) | 105.00 |
| $100, continuous | 100.00 × (1 + 0.05 + 0.05 × 0.05 ÷ 2 + …) | 105.127110 |
| to the cent | rounded | **105.13** |

Just under thirteen cents, for compounding continuously instead of yearly.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Expecting a windfall from continuous | 105.13, against 105.00 | Just under thirteen cents |
| Calling monthly continuous | 2.613035, not 2.718282 | Monthly is nowhere near it |
| Forgetting the slices earn too | 2.000000 | Interest on interest is the mover |

---

## Code, from first principles, and it actually runs

Nothing is imported, so nothing arrives knowing e. One road walks the ladder, one-plus-a-slice per payment, a million times if asked. The other never mentions payments: it adds up the shrinking list.

### Python

```python
# Compounding more often, and the number e -- the check behind the card.  Nothing
# is imported.  $1 at 100% for a year, the rate split n ways and multiplied in n
# times, then the same ceiling a second way: the series 1 + 1 + 1/2 + 1/6 + ...
def ladder(rate, n):                   # (1 + rate/n) multiplied in, n times over
    total = 1.0
    for _ in range(n):
        total = total * (1.0 + rate / n)
    return total
def series(rate):                      # 1 + rate + rate x rate / 2 + ... , 20 terms
    total, term = 0.0, 1.0
    for k in range(1, 21):
        total, term = total + term, term * rate / k
    return total
def row(name, value, places):
    print(f"{name:<33}{value:>13.{places}f}")
for name, n in (("paid once a year", 1), ("paid twice a year", 2),
                ("paid monthly, 12 times", 12), ("paid daily, 365 times", 365),
                ("paid a million times", 1000000)):
    row(name, ladder(1.0, n), 6)
row("the ceiling, e by the series", series(1.0), 6)
row("e, to nine decimals", series(1.0), 9)
yearly, cont = 100.0 * ladder(0.05, 1), 100.0 * series(0.05)
row("$100 at 5%, paid once a year", yearly, 2)
row("$100 at 5%, paid continuously", cont, 6)
row("$100 continuous, to the cent", round(cont, 2), 2)
assert abs(ladder(1.0, 2) - 2.25) < 1e-12
assert abs(series(1.0) - ladder(1.0, 1000000)) < 1e-5
assert round(yearly, 2) == 105.00 and round(cont, 2) == 105.13
print("ALL CHECKS PASS")
```

**Ran 2026-09-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
paid once a year                      2.000000
paid twice a year                     2.250000
paid monthly, 12 times                2.613035
paid daily, 365 times                 2.714567
paid a million times                  2.718280
the ceiling, e by the series          2.718282
e, to nine decimals                2.718281828
$100 at 5%, paid once a year            105.00
$100 at 5%, paid continuously       105.127110
$100 continuous, to the cent            105.13
ALL CHECKS PASS
```

### Rust

Same numbers and labels, via `rustc --edition 2021 -O`.

```rust
// Compounding more often, and the number e -- the same check as the Python one,
// in Rust.  No crates.  $1 at 100% for a year, the rate split n ways and
// multiplied in n times, then the ceiling by the series 1 + 1 + 1/2 + 1/6 + ...
fn ladder(rate: f64, n: u64) -> f64 {      // (1 + rate/n) multiplied in, n times over
    let mut total = 1.0;
    for _ in 0..n { total = total * (1.0 + rate / n as f64); }
    total
}
fn series(rate: f64) -> f64 {              // 1 + rate + rate x rate / 2 + ... , 20 terms
    let (mut total, mut term) = (0.0, 1.0);
    for k in 1..21 { total += term; term = term * rate / k as f64; }
    total
}
fn row(name: &str, value: f64, places: usize) {
    println!("{:<33}{:>13.p$}", name, value, p = places);
}
fn main() {
    let steps: [(&str, u64); 5] = [("paid once a year", 1), ("paid twice a year", 2),
        ("paid monthly, 12 times", 12), ("paid daily, 365 times", 365),
        ("paid a million times", 1000000)];
    for (name, n) in steps { row(name, ladder(1.0, n), 6); }
    row("the ceiling, e by the series", series(1.0), 6);
    row("e, to nine decimals", series(1.0), 9);
    let yearly = 100.0 * ladder(0.05, 1);
    let cont = 100.0 * series(0.05);
    row("$100 at 5%, paid once a year", yearly, 2);
    row("$100 at 5%, paid continuously", cont, 6);
    row("$100 continuous, to the cent", (cont * 100.0).round() / 100.0, 2);
    assert!((ladder(1.0, 2) - 2.25).abs() < 1e-12);
    assert!((series(1.0) - ladder(1.0, 1000000)).abs() < 1e-5);
    assert!(((yearly * 100.0).round() / 100.0 - 105.00).abs() < 1e-9
        && ((cont * 100.0).round() / 100.0 - 105.13).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
paid once a year                      2.000000
paid twice a year                     2.250000
paid monthly, 12 times                2.613035
paid daily, 365 times                 2.714567
paid a million times                  2.718280
the ceiling, e by the series          2.718282
e, to nine decimals                2.718281828
$100 at 5%, paid once a year            105.00
$100 at 5%, paid continuously       105.127110
$100 continuous, to the cent            105.13
ALL CHECKS PASS
```

The two outputs match line for line.

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **Pay it ten million times.** Change the last 1000000 to 10000000. The row prints 2.718282, matching the ceiling row under it: arrived to six decimals, still not past.
> - **Turn the dial down to 5%.** Change `ladder(1.0, n)` to `ladder(0.05, n)`. It runs from 1.050000 to 1.051271 — on $100, the 105.127110 already there.

---

## The usual mistake

> [!warning]
> **Thinking that paying more often keeps paying more.** One dollar at 100% for a year ends under 2.718282 whether the interest lands twice, daily or a million times. Past daily there is nothing left to buy.
>
> - Reading "5% compounded monthly" as 5% a month. It is a twelfth of that.
> - Rounding e before multiplying. Round money at the end, to the nearest cent.
> - Blaming continuous compounding for a jump in a balance. Here it is just under thirteen cents.

---

## Where you meet it in real life

- **The two rates on a credit card offer.** APR is the advertised one, APY the one you pay. They differ because the charge lands monthly or daily.
- **Anything that grows or decays on its own.** Populations, bacteria, a cooling room, a drug clearing your blood: nothing waits for a payment date, so e is how they are written.
- **Moving money between dates.** Option and rate models compound continuously: one convention instead of many schedules. [Discounting](06-discounting-and-present-value.md).

> **Say it back**
> Interest paid more often earns a little more, because the early payments earn too. One dollar at 100% goes 2.000000 paid once, 2.250000 twice, 2.613035 monthly, 2.714567 daily. The gains shrink and stop at a ceiling: 2.718281828, called e. Reaching it is what "compounded continuously" means. On $100 at 5% that is $105.13 against $105.00.

---

## What this builds on

- [Compound interest](03-compound-interest.md): interest that earns interest, and why the balance bends upward. This card pays it in smaller instalments.

## Where this goes next

- [Natural log and doubling time](05-natural-log-and-doubling-time.md): the tool that undoes e, and how long money takes to double.
- [Discounting](06-discounting-and-present-value.md): the ladder backwards, money next year turned into money today.

---

## Sources

Verified 6 Sep 2026; every link resolves.

- NIST. *Digital Library of Mathematical Functions*, §4.2. [dlmf.nist.gov/4.2](https://dlmf.nist.gov/4.2). The reference definition of e.
- Euler, Leonhard. *Introduction to Analysis of the Infinite, Book I*, trans. John D. Blanton. Springer, 1988. [doi:10.1007/978-1-4612-1021-4](https://doi.org/10.1007/978-1-4612-1021-4). Where the series and the letter e were set out.
- Maor, Eli. *e: The Story of a Number*. Princeton University Press, 1994. [Publisher page](https://press.princeton.edu/books/paperback/9780691168487/e-the-story-of-a-number). The history, at book length.
