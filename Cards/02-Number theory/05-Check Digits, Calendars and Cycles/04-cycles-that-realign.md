# When cycles meet again: the 60-year calendar, the 52-year calendar round, and why some remainder pairs never happen

[Syllabus](../../../SYLLABUS.md) → [Number theory](../../../SYLLABUS.md#w02) → [Check Digits, Calendars and Cycles](../../../SYLLABUS.md#w02-s05) → When cycles meet again

---

## General Overview

A Chinese year carries two names. One list is ten long and names an element: Wood, Fire, Earth, Metal, Water, each used twice. The other is twelve long and names an animal: Rat, Ox, Tiger, on to Pig. The traditional words: **stems** and **branches**.

1984 was the Wood Rat, both lists at their start. 2026 is 42 years later. Divide 42 by 10 and 2 is left over: the stems have moved 2 on, to Fire. Divide by 12 and 6 is left over: the branches, 6 on, to Horse. 2026 is the Fire Horse. The year turns in late winter, not on 1 January.

Ten names against twelve looks like 120 combinations. Only 60 are ever a year: both lists read the same count, so both notice whether it is odd or even, and they must agree.

**Two cycles come back together after their lengths multiplied and then divided by the biggest number both lengths share — and that shared part is also what rules pairs of positions out.**

### The picture: sixty years to get home

```
stem, every 10     S.........S.........S.........S.........S.........S.........S
branch, every 12   B...........B...........B...........B...........B...........B
```

The first column is 1984 itself, then a column a year. S is the stems at their start, B the branches. They are home together only at year 60.

---

## The formula

2026 on both lists:

**42 ÷ 10 leaves 2, and 42 ÷ 12 leaves 6 — stem 2, branch 6, counting the first name as 0: the Fire Horse**

And the year both come home together:

**gcd(10, 12), the biggest number going into both, is 2 — so lcm(10, 12), the first year both lists reach, is 10 × 12 ÷ 2 = 60**

**Read it aloud: two cycles meet again after their lengths multiplied, then divided by the biggest number that goes into both.**

The same line runs the Maya 260-day and 365-day counts:

**gcd(260, 365) = 5, so lcm(260, 365) = 260 × 365 ÷ 5 = 94900 ÷ 5 = 18980 days — 52 years of 365 days, the calendar round**

| Piece | Plain meaning | Here |
| --- | --- | --- |
| the cycle length | how long a list runs | 10 and 12 |
| the remainder | how far a list has moved | 2 and 6 |
| gcd | biggest number into both ([Greatest common divisor](../02-Greatest%20Common%20Divisor%20and%20Euclid%27s%20Algorithm/01-gcd.md)) | 2 |
| lcm | first number both go into ([Least common multiple](../02-Greatest%20Common%20Divisor%20and%20Euclid%27s%20Algorithm/02-lcm.md)) | 60 |
| pairs on paper | the lengths multiplied | 120 |
| pairs that happen | those, divided by the gcd | 60 |

---

## Why it works

### Step 0 — there is one count, read two ways

Nothing runs two clocks. There is one number, years since 1984, and each list reports the remainder when it is divided by that list's length ([Division with a remainder](../01-Divisibility%20and%20Primes/04-division-with-remainder.md)). Stem and branch are two readings of one 42.

### Step 1 — both are home on a year both lengths go into

The stems are back at the start when the year count divides by 10 with nothing over, the branches when it divides by 12. Both at once needs a number 10 and 12 both go into, and the first is lcm(10, 12) = 60 ([Least common multiple](../02-Greatest%20Common%20Divisor%20and%20Euclid%27s%20Algorithm/02-lcm.md)). 120 is also a year both are home, but the second one.

### Step 2 — the shared factor rules pairs out

10 and 12 are both even. Taking 10 away, or 12, never turns an odd count even. So the remainder carries the count's odd-or-even straight through, on both lists: an even year leaves even remainders, an odd year odd ones.

That is the whole restriction. Stem 3 with branch 4, odd against even, asks one year to be odd and even at once. It never happens, nor does any mixed pair. Sixty survive, one every 60 years.

### Step 3 — share nothing and nothing is ruled out

Had the lengths shared no number above 1 — coprime ([Coprime numbers](../02-Greatest%20Common%20Divisor%20and%20Euclid%27s%20Algorithm/05-coprime-numbers.md)) — nothing could disagree, and every pair would happen, once per product. That is [The Chinese remainder theorem](../03-Clock%20Arithmetic/06-chinese-remainder-theorem.md).

The biggest number going into both Maya counts is 5, so their positions must agree on the remainder from 5. One pair in five survives, every 18980 days, not every 94900.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| years since the Wood Rat | 2026 − 1984 | 42 |
| where the stems stand | 42 ÷ 10, keep the remainder | 2, so Fire |
| where the branches stand | 42 ÷ 12, keep the remainder | 6, so Horse |
| what the lengths share | gcd(10, 12) | 2 |
| when both are home | 10 × 12 ÷ 2 | **60 years** |
| the Maya pair | 260 × 365 ÷ 5 | **18980 days** |
| that, in 365-day years | 18980 ÷ 365 | **52** |

The Fire Horse returns every 60 years; a full Maya date, every 52.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Multiplying, 10 × 12 | 120 years | Both are home, but it is the second time |
| Multiplying 260 × 365 | 94900 days | Five times too long: they share a factor 5 |
| Calling that the round | 260 years | The round is 52 years |

---

## Code, from first principles, and it actually runs

The year name comes from dividing and keeping remainders. Then two roads to the meeting year: the product divided by the biggest shared number, and counting up a year at a time.

### Python

```python
# When cycles meet again -- the check behind the card.  Nothing is imported.  A Chinese year name pairs a 10-year
# stem cycle with a 12-year branch cycle, counted from 1984, the Wood Rat.  Then the Maya 260-day and 365-day counts.
# Road one divides the product by the biggest number going into both; road two counts up one step at a time.
ELEMENTS = ["Wood", "Wood", "Fire", "Fire", "Earth", "Earth", "Metal", "Metal", "Water", "Water"]
ANIMALS = ["Rat", "Ox", "Tiger", "Rabbit", "Dragon", "Snake", "Horse", "Goat", "Monkey", "Rooster", "Dog", "Pig"]
def shared(a, b):                        # the biggest number going into both
    while b: a, b = b, a % b
    return a
def meet(a, b): return a * b // shared(a, b)          # road one
def count_up(a, b):                                   # road two
    n = 1
    while n % a or n % b: n += 1
    return n
def name(n): return ELEMENTS[n % 10] + " " + ANIMALS[n % 12]
year = 2026 - 1984
pairs = sorted({(n % 10, n % 12) for n in range(120)})
bad = (3, 4)
bad_count = sum(1 for n in range(120) if (n % 10, n % 12) == bad)
print(f"2026 is year {year} after 1984, the {name(0)}: stem {year % 10}, branch {year % 12} -- the {name(year)}")
print(f"road one: 10 x 12 = {10 * 12}, shared factor {shared(10, 12)}, so they meet again after {meet(10, 12)} years")
print(f"road two, counting up: both cycles come round together at year {count_up(10, 12)}")
print(f"pairs that ever happen: {len(pairs)} of the {10 * 12} on paper -- both remainders even, or both odd")
print(f"stem 3 with branch 4: happens {bad_count} times in 120 years -- 3 is odd, 4 is even")
print(f"Maya: 260 x 365 = {260 * 365}, shared factor {shared(260, 365)}, so the counts realign after {meet(260, 365)} days")
print(f"{meet(260, 365)} days is {meet(260, 365) // 260} rounds of the 260-day count and {meet(260, 365) // 365} of the 365-day count")
print(f"the three mistakes come out at {10 * 12} years, {260 * 365} days and {260 * 365 // 365} years")
assert year == 42 and (year % 10, year % 12) == (2, 6) and name(year) == "Fire Horse"
assert pairs == sorted((s, b) for s in range(10) for b in range(12) if s % 2 == b % 2) and len(pairs) == 60 and bad_count == 0
assert meet(10, 12) == 60 == count_up(10, 12) and meet(260, 365) == 18980 == 52 * 365 == 73 * 260 and 260 * 365 == 94900
print("ALL CHECKS PASS")
```

**Ran 2026-09-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
2026 is year 42 after 1984, the Wood Rat: stem 2, branch 6 -- the Fire Horse
road one: 10 x 12 = 120, shared factor 2, so they meet again after 60 years
road two, counting up: both cycles come round together at year 60
pairs that ever happen: 60 of the 120 on paper -- both remainders even, or both odd
stem 3 with branch 4: happens 0 times in 120 years -- 3 is odd, 4 is even
Maya: 260 x 365 = 94900, shared factor 5, so the counts realign after 18980 days
18980 days is 73 rounds of the 260-day count and 52 of the 365-day count
the three mistakes come out at 120 years, 94900 days and 260 years
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, `rustc --edition 2021 -O`.

```rust
// When cycles meet again -- the same check as the Python twin, in Rust.  No crates.  A Chinese year name
// pairs a 10-year stem cycle with a 12-year branch cycle, counted from 1984, the Wood Rat.  Then the Maya
// 260-day and 365-day counts.  Road one divides the product by the biggest number going into both.
const ELEMENTS: [&str; 10] = ["Wood", "Wood", "Fire", "Fire", "Earth", "Earth", "Metal", "Metal", "Water", "Water"];
const ANIMALS: [&str; 12] = ["Rat", "Ox", "Tiger", "Rabbit", "Dragon", "Snake", "Horse", "Goat", "Monkey", "Rooster", "Dog", "Pig"];
fn shared(a: i64, b: i64) -> i64 {       // the biggest number going into both
    let (mut a, mut b) = (a, b);
    while b != 0 { let t = a % b; a = b; b = t; }
    a
}
fn meet(a: i64, b: i64) -> i64 { a * b / shared(a, b) }        // road one
fn count_up(a: i64, b: i64) -> i64 {                           // road two
    let mut n = 1;
    while n % a != 0 || n % b != 0 { n += 1; }
    n
}
fn name(n: i64) -> String { format!("{} {}", ELEMENTS[(n % 10) as usize], ANIMALS[(n % 12) as usize]) }
fn main() {
    let year: i64 = 2026 - 1984;
    let mut pairs: Vec<(i64, i64)> = (0..120).map(|n| (n % 10, n % 12)).collect();
    pairs.sort();
    pairs.dedup();
    let bad: (i64, i64) = (3, 4);
    let bad_count = (0..120i64).filter(|n| (n % 10, n % 12) == bad).count();
    println!("2026 is year {} after 1984, the {}: stem {}, branch {} -- the {}", year, name(0), year % 10, year % 12, name(year));
    println!("road one: 10 x 12 = {}, shared factor {}, so they meet again after {} years", 10 * 12, shared(10, 12), meet(10, 12));
    println!("road two, counting up: both cycles come round together at year {}", count_up(10, 12));
    println!("pairs that ever happen: {} of the {} on paper -- both remainders even, or both odd", pairs.len(), 10 * 12);
    println!("stem 3 with branch 4: happens {} times in 120 years -- 3 is odd, 4 is even", bad_count);
    println!("Maya: 260 x 365 = {}, shared factor {}, so the counts realign after {} days", 260 * 365, shared(260, 365), meet(260, 365));
    println!("{} days is {} rounds of the 260-day count and {} of the 365-day count", meet(260, 365), meet(260, 365) / 260, meet(260, 365) / 365);
    println!("the three mistakes come out at {} years, {} days and {} years", 10 * 12, 260 * 365, 260 * 365 / 365);
    assert!(year == 42 && (year % 10, year % 12) == (2, 6) && name(year) == "Fire Horse");
    let want: Vec<(i64, i64)> = (0..10).flat_map(|s| (0..12).map(move |b| (s, b))).filter(|&(s, b)| s % 2 == b % 2).collect();
    assert!(pairs == want && pairs.len() == 60 && bad_count == 0);
    assert!(meet(10, 12) == 60 && count_up(10, 12) == 60 && meet(260, 365) == 18980 && 52 * 365 == 18980 && 73 * 260 == 18980 && 260 * 365 == 94900);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
2026 is year 42 after 1984, the Wood Rat: stem 2, branch 6 -- the Fire Horse
road one: 10 x 12 = 120, shared factor 2, so they meet again after 60 years
road two, counting up: both cycles come round together at year 60
pairs that ever happen: 60 of the 120 on paper -- both remainders even, or both odd
stem 3 with branch 4: happens 0 times in 120 years -- 3 is odd, 4 is even
Maya: 260 x 365 = 94900, shared factor 5, so the counts realign after 18980 days
18980 days is 73 rounds of the 260-day count and 52 of the 365-day count
the three mistakes come out at 120 years, 94900 days and 260 years
ALL CHECKS PASS
```

> [!TIP]
> **Try changing**
> Guess first, then run. The asserts are pinned to these calendars, so one fires.
> - **Make the branches 11 long.** Change the 12s to 11s: 10 and 11 share nothing, so all 110 pairs happen and the lists meet at 110.
> - **Pick a pair that does happen.** Set `bad` to `(2, 6)`: the count comes out 2, not 0, and the second assert fires.

---

## The usual mistake

> [!warning]
> **Multiplying the two cycle lengths.** Ten names and twelve names do not make 120 years. Multiplying counts every pair on paper, the impossible ones included. They come home after 60.
>
> - **Treating the positions as free.** Stem 3 with branch 4 is not a rare year. It is not a year.
> - **Multiplying the Maya counts.** 94900 days is five times the round of 18980 days.
> - **Reading a count as a date.** "Year 42" counts from a chosen start. Move the start and both remainders move.

---

## Where you meet it in real life

- **Two calendars at once.** A payday against a billing date: when are both back at the beginning ([Day of the week for any date](03-day-of-the-week.md)).
- **Gears.** A 10-tooth wheel driving a 12-tooth wheel: one pair of teeth meets again only after 60 tooth-steps.
- **Anything that returns to the start.** The same counting says how many repeats undo an operation: [Perfect shuffles](05-perfect-shuffles.md).

> **Say it back**
> A Chinese year carries two names, one from a list of ten, one from a list of twelve, both read off one count of years. 2026 is 42 years after the Wood Rat of 1984: stem 2, branch 6, the Fire Horse. The lists come home together after 10 × 12 ÷ 2 = 60 years, because 2 is the biggest number both lengths share. That same 2 rules out every pair with one remainder odd and the other even: only 60 of the 120 pairs are ever a year. The Maya counts, 260 and 365, share 5 and meet after 18980 days: the 52-year round.

---

## What this builds on

- [Least common multiple](../02-Greatest%20Common%20Divisor%20and%20Euclid%27s%20Algorithm/02-lcm.md): the first number two lengths both go into, and why it is the product divided by the gcd.
- [The Chinese remainder theorem](../03-Clock%20Arithmetic/06-chinese-remainder-theorem.md): the coprime case, every pair happening once per product. This card is the rest.

## Where this goes next

[Perfect shuffles](05-perfect-shuffles.md) asks it of one cycle: how many repeats bring a deck back.

---

## Sources

Verified 6 Sep 2026: every link resolves.

- Dershowitz, Nachum, and Edward M. Reingold. *Calendrical Calculations: The Ultimate Edition*, 4th ed. Cambridge University Press, 2018. [doi:10.1017/9781107415058](https://doi.org/10.1017/9781107415058). Both calendars, remainders and all.
- Aveni, Anthony F. *Skywatchers*. University of Texas Press, 2001. [Publisher page](https://utpress.utexas.edu/9780292705029/skywatchers/). Where the Maya counts came from.
