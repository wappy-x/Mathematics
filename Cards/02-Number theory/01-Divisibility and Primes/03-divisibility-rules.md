# Divisibility rules: reading the digits to see whether 2, 3, 4, 5, 6, 8, 9 or 10 divides a number

[Syllabus](../../../SYLLABUS.md) → [Number theory](../../../SYLLABUS.md#w02) → [Divisibility and Primes](../../../SYLLABUS.md#w02-s01) → Divisibility rules

---

## General Overview

Dinner for a big table. The bill is **$1,236**, and everyone wants to pay the same whole number of dollars. Can three of you split it? Four? Eight?

Nobody divides 1,236 to find out. Add the digits: 1 + 2 + 3 + 6 = 12, a multiple of 3, so three ways works. The last two digits, 36, are a multiple of 4, so four ways works. The last three, 236, are not a multiple of 8, so eight people cannot.

Those are **divisibility rules**: tests that read a few digits instead of dividing.

**Every rule reads a small number — a tail, or the digit sum — and bins the rest, because the rest is a multiple of the number you are testing.**

### The picture: where the rules cut

```
1,236 dollars, cut between the place-value columns

    1230 + 6      1230 is a whole number of tens, so 2, 5 and 10 read only the 6
    1200 + 36     1200 is a whole number of hundreds, so 4 reads only the 36
    1000 + 236    1000 is a whole number of thousands, so 8 reads only the 236
```

Only the right piece decides.

---

## The formula

The **digit sum** is the digits added up, 1 + 2 + 3 + 6 = 12. **The last digits** are read off the right end: 6, 36, 236.

| Divisor | The test | 1,236 is |
| --- | --- | --- |
| 2 | last digit even | yes: 2 × 618 |
| 3 | digit sum divides by 3 | yes: 3 × 412 |
| 4 | last two digits divide by 4 | yes: 4 × 309 |
| 5 | last digit 0 or 5 | no: 5 × 247 + 1 |
| 6 | the 2 test and the 3 test | yes: 6 × 206 |
| 8 | last three digits divide by 8 | no: 8 × 154 + 4 |
| 9 | digit sum divides by 9 | no: 9 × 137 + 3 |
| 10 | last digit 0 | no: 10 × 123 + 6 |

**Read it aloud: tail for 2, 4, 5, 8 and 10; digit sum for 3 and 9; both of those for 6.**

---

## Why it works

### Why the tail is enough

Ten is two 5s, so any number of whole tens splits two, five and ten ways. The bill is 1230 + 6, so only the 6 decides: even, so 2 divides; not 0 or 5, so 5 and 10 do not.

A hundred is four 25s: the bill is 1200 + 36, and 36 splits four ways. A thousand is eight 125s: the bill is 1000 + 236, and 236 is 4 over — the bill's own leftover, 1,236 = 8 × 154 + 4.

### Why the digits add up for 3 and 9

Every column is one more than a row of 9s: 10 is 9 + 1, 100 is 99 + 1, 1000 is 999 + 1. So the bill is one 999 plus 1, two 99s plus 2, three 9s plus 3, and 6.

Sweep the nines together: 1 × 999 + 2 × 99 + 3 × 9 = 1224, which is 9 × 136. What is left is the digit sum, 12. So 1,236 = 1224 + 12.

1224 is a multiple of 9, so also of 3 (9 is three 3s). It cannot change either verdict. Only the digit sum, 12, can: 12 is a multiple of 3, so 1,236 = 3 × 412; 12 runs 3 past 9, so 1,236 = 9 × 137 + 3.

### Six is 2 and 3 together

Six is 2 × 3, and 2 and 3 share no factor above 1, so splitting two and three ways means splitting six ways: 1,236 = 6 × 206. The pairing needs testers with no shared factor. The 2 and 4 tests together are no test for 8 — 12 passes 2 and 4, but fails 8.

<details>
<summary>7 and 11, if you want them</summary>

**11:** add every other digit, then the ones you skipped; if the totals match or differ by a multiple of 11, 11 divides.
**7:** chop off the last digit, double it, subtract it from the rest, and repeat.
The 7 test is slower than dividing.

</details>

The alternative is the division itself: [Division with a remainder](04-division-with-remainder.md).

---

## Worked numbers, by hand

The bill, test by test.

| Step | Arithmetic | Value |
| --- | --- | --- |
| add the digits | 1 + 2 + 3 + 6 | 12 |
| three ways: 12 divides by 3 | 1236 ÷ 3 | **412** |
| four ways: 36 does too | 1236 ÷ 4 | **309** |
| eight ways: 236 does not | 1236 ÷ 8 | 154, **4 left** |
| nine ways: 12 does not | 1236 ÷ 9 | 137, 3 left |

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| 4 tested on the last digit | "no", 6 is not | 1,236 = 4 × 309 |
| digit sum 12 as a pass for 9 | "yes" | 1,236 = 9 × 137 + 3 |
| 8 tested on the last two digits | "no" on a $1,136 bill | 1,136 = 8 × 142 |

---

## Code, from first principles, and it actually runs

Each rule is decided from the digits alone. The real division is the second road; an assert makes the two agree.

### Python

```python
# Divisibility rules -- the check behind the card.  Nothing is imported.  The
# $1,236 restaurant bill: every rule is decided from the digits alone, then
# checked against the real division, a second road to the same verdict.
BILL = 1236                                     # the restaurant bill, in dollars
SUM = 1 + 2 + 3 + 6                             # the digit sum, 12
NINES = 1 * 999 + 2 * 99 + 3 * 9                # the pile of nines under the digits
LOOK = {2: BILL % 10, 5: BILL % 10, 10: BILL % 10, 4: BILL % 100,
        8: BILL % 1000, 3: SUM, 9: SUM}         # the little number each rule reads
WORDS = {2: "last digit 6", 3: "digit sum 12", 4: "last two digits 36",
         5: "last digit 6", 6: "passes 2 and 3", 8: "last three digits 236",
         9: "digit sum 12", 10: "last digit 6"}

def rule(d):                        # the verdict from the digits, never dividing 1236
    return rule(2) and rule(3) if d == 6 else LOOK[d] % d == 0

for d in (2, 3, 4, 5, 6, 8, 9, 10):
    q, r = BILL // d, BILL % d
    done = f"1236 = {d} x {q}" + (f" + {r}" if r else "")
    print(f"{d:<4}{WORDS[d]:<23}{'yes' if rule(d) else 'no':<6}{done}")
    assert rule(d) == (r == 0)      # the digits and the division must agree
print(f"splits  1236 = {BILL - BILL % 10} + {BILL % 10} = {BILL - BILL % 100} + {BILL % 100}"
      f" = {BILL - BILL % 1000} + {BILL % 1000}; 10 = 2 x {10 // 2}, 100 = 4 x {100 // 4}, 1000 = 8 x {1000 // 8}")
print(f"nines   1236 = 1 x 999 + 2 x 99 + 3 x 9 + {SUM} = {NINES} + {SUM}, and {NINES} = 9 x {NINES // 9}")
print(f"mistakes  last digit for 4 says no (truth 4 x {BILL // 4}); sum 12 for 9 says yes "
      f"(truth 9 x {BILL // 9} + {BILL % 9}); last two digits for 8 says no on 1136 (truth 8 x {1136 // 8})")
assert BILL % 9 == SUM % 9 == 3 and BILL % 3 == SUM % 3 == 0
assert BILL % 8 == (BILL % 1000) % 8 == 4 and NINES % 9 == 0 and NINES + SUM == BILL
assert 1136 % 8 == 0 and (1136 % 100) % 8 != 0  # the rule that is not a rule
print("ALL CHECKS PASS")
```

**Ran 2026-09-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
2   last digit 6           yes   1236 = 2 x 618
3   digit sum 12           yes   1236 = 3 x 412
4   last two digits 36     yes   1236 = 4 x 309
5   last digit 6           no    1236 = 5 x 247 + 1
6   passes 2 and 3         yes   1236 = 6 x 206
8   last three digits 236  no    1236 = 8 x 154 + 4
9   digit sum 12           no    1236 = 9 x 137 + 3
10  last digit 6           no    1236 = 10 x 123 + 6
splits  1236 = 1230 + 6 = 1200 + 36 = 1000 + 236; 10 = 2 x 5, 100 = 4 x 25, 1000 = 8 x 125
nines   1236 = 1 x 999 + 2 x 99 + 3 x 9 + 12 = 1224 + 12, and 1224 = 9 x 136
mistakes  last digit for 4 says no (truth 4 x 309); sum 12 for 9 says yes (truth 9 x 137 + 3); last two digits for 8 says no on 1136 (truth 8 x 142)
ALL CHECKS PASS
```

### Rust

Same numbers, built with `rustc --edition 2021 -O`.

```rust
// Divisibility rules -- the same check as divisibility_rules_check.py, in Rust.
// No crates.  The $1,236 restaurant bill: every rule is decided from the digits
// alone, then checked against the real division, a second road to the verdict.
const BILL: i64 = 1236;                        // the restaurant bill, in dollars
const SUM: i64 = 1 + 2 + 3 + 6;                // the digit sum, 12
const NINES: i64 = 1 * 999 + 2 * 99 + 3 * 9;   // the pile of nines under the digits

fn look(d: i64) -> i64 {           // the little number the rule for d reads
    match d { 2 | 5 | 10 => BILL % 10, 4 => BILL % 100, 8 => BILL % 1000, _ => SUM }
}

fn rule(d: i64) -> bool {          // the verdict from the digits, never dividing 1236
    if d == 6 { rule(2) && rule(3) } else { look(d) % d == 0 }
}

fn main() {
    let words = [(2, "last digit 6"), (3, "digit sum 12"), (4, "last two digits 36"),
                 (5, "last digit 6"), (6, "passes 2 and 3"), (8, "last three digits 236"),
                 (9, "digit sum 12"), (10, "last digit 6")];
    for (d, w) in words {
        let (q, r) = (BILL / d, BILL % d);
        let mut done = format!("1236 = {} x {}", d, q);
        if r != 0 { done.push_str(&format!(" + {}", r)); }
        println!("{:<4}{:<23}{:<6}{}", d, w, if rule(d) { "yes" } else { "no" }, done);
        assert!(rule(d) == (r == 0));   // the digits and the division must agree
    }
    println!("splits  1236 = {} + {} = {} + {} = {} + {}; 10 = 2 x {}, 100 = 4 x {}, 1000 = 8 x {}",
             BILL - BILL % 10, BILL % 10, BILL - BILL % 100, BILL % 100,
             BILL - BILL % 1000, BILL % 1000, 10 / 2, 100 / 4, 1000 / 8);
    println!("nines   1236 = 1 x 999 + 2 x 99 + 3 x 9 + {} = {} + {}, and {} = 9 x {}",
             SUM, NINES, SUM, NINES, NINES / 9);
    println!("mistakes  last digit for 4 says no (truth 4 x {}); sum 12 for 9 says yes \
              (truth 9 x {} + {}); last two digits for 8 says no on 1136 (truth 8 x {})",
             BILL / 4, BILL / 9, BILL % 9, 1136 / 8);
    assert!(BILL % 9 == SUM % 9 && SUM % 9 == 3 && BILL % 3 == 0 && SUM % 3 == 0);
    assert!(BILL % 8 == (BILL % 1000) % 8 && BILL % 8 == 4 && NINES % 9 == 0 && NINES + SUM == BILL);
    assert!(1136 % 8 == 0 && (1136 % 100) % 8 != 0);   // the rule that is not a rule
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
2   last digit 6           yes   1236 = 2 x 618
3   digit sum 12           yes   1236 = 3 x 412
4   last two digits 36     yes   1236 = 4 x 309
5   last digit 6           no    1236 = 5 x 247 + 1
6   passes 2 and 3         yes   1236 = 6 x 206
8   last three digits 236  no    1236 = 8 x 154 + 4
9   digit sum 12           no    1236 = 9 x 137 + 3
10  last digit 6           no    1236 = 10 x 123 + 6
splits  1236 = 1230 + 6 = 1200 + 36 = 1000 + 236; 10 = 2 x 5, 100 = 4 x 25, 1000 = 8 x 125
nines   1236 = 1 x 999 + 2 x 99 + 3 x 9 + 12 = 1224 + 12, and 1224 = 9 x 136
mistakes  last digit for 4 says no (truth 4 x 309); sum 12 for 9 says yes (truth 9 x 137 + 3); last two digits for 8 says no on 1136 (truth 8 x 142)
ALL CHECKS PASS
```

The two outputs match line for line.

> [!TIP]
> **Try changing**
> Guess first, then run. The asserts are pinned to this bill, so one will fire.
> - **Make it a $1,232 bill.** Set `BILL` to 1232 and `SUM` to 1 + 2 + 3 + 2. Now 3 and 6 turn to no, and 8 turns to yes. The `WORDS` labels are pinned too: change 6 to 2 and 12 to 8, or ignore them.
> - **Break the 8 rule.** Give 8 the entry `BILL % 100` in `LOOK` — two digits, not three. It still prints no here and every assert passes, right by luck. Point it at a $1,136 bill: `BILL` 1136, `SUM` 1 + 1 + 3 + 6, `NINES` 1 * 999 + 1 * 99 + 3 * 9. The 8 row is the one that fails.

---

## The usual mistake

> [!warning]
> **Using the digit sum for everything.** It works for 3 and 9, nothing else. This bill's digit sum, 12, is a multiple of 4, and 4 does divide the bill, so the wrong method looks right by accident. The 4 test is the last two digits, 36.
>
> - **Mixing 3 with 9.** Digit sum 12 passes for 3 and fails for 9. Read it as a pass for both and you claim nine can split the bill: 1,236 = 9 × 137 + 3.

---

## Where you meet it in real life

- **Splitting a bill.** Whole dollars a head: does one number divide another? [Divides](01-divides.md)
- **Check digits.** A barcode's last digit makes a weighted total land on a multiple of 10 — a rule run backwards: [Barcode check digits](../05-Check%20Digits%2C%20Calendars%20and%20Cycles/01-barcode-check-digit.md).
- **Factoring by hand.** The rules for 2, 3 and 5 strip out the easy primes: [Prime factorisation](07-prime-factorisation.md).

> **Say it back**
> A rule reads a small number — a tail, or the digit sum — and bins the rest, which is already a multiple of the number being tested. Last digit for 2, 5 and 10; last two for 4; last three for 8. Digit sum for 3 and 9, since every column is one more than a row of 9s. For 6, pass 2 and 3 both.

---

## What this builds on

- [Place value](../../01-Foundations/01-Everyday%20Arithmetic/01-place-value.md): that 1,236 means one thousand, two hundreds, three tens and six ones.
- [The three rearranging laws](../../01-Foundations/01-Everyday%20Arithmetic/05-arithmetic-laws.md): cutting 1,236 into 1200 + 36 without changing it.
- [Divides](01-divides.md): what "divides" means, and that a multiple of 9 is a multiple of 3.

## Where this goes next

- [Barcode check digits](../05-Check%20Digits%2C%20Calendars%20and%20Cycles/01-barcode-check-digit.md): the same digit-reading, used to build a number that must pass a test for 10.

---

## Sources

Verified 6 Sep 2026; every link resolves.

- Burton, David M. *Elementary Number Theory*, 7th ed. McGraw-Hill, 2011. [Publisher page](https://www.mheducation.com/highered/product/elementary-number-theory-burton/M9780073383149.html). Chapter 4 proves them.
- Knuth, Donald E. *The Art of Computer Programming, Volume 2*, 3rd ed. Addison-Wesley, 1997. [Publisher page](https://www.informit.com/store/art-of-computer-programming-volume-2-seminumerical-9780201896848). Section 4.1: the columns these rules read.
- Conway, John H., and Richard K. Guy. *The Book of Numbers*. Springer, 1996. [doi:10.1007/978-1-4612-4072-3](https://doi.org/10.1007/978-1-4612-4072-3). How numbers are written.
