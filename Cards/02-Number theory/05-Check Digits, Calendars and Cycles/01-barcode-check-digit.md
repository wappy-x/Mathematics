---
type: card
wing: 02-Number theory
shelf: Check Digits, Calendars and Cycles
topic: Check digits
item: Barcode check digits
kind: method
status: verified
updated: 2026-09-06
needs_first:
  - "[[Cards/02-Number theory/03-Clock Arithmetic/02-modular-addition-and-multiplication|modular-addition-and-multiplication]]"
  - "[[Cards/02-Number theory/01-Divisibility and Primes/03-divisibility-rules|divisibility-rules]]"
  - "[[Cards/02-Number theory/02-Greatest Common Divisor and Euclid's Algorithm/05-coprime-numbers|coprime-numbers]]"
  - "[[Cards/01-Foundations/01-Everyday Arithmetic/01-place-value|place-value]]"
next:
  - "[[Cards/02-Number theory/05-Check Digits, Calendars and Cycles/02-isbn-check-digit|isbn-check-digit]]"
tags:
  - mathematics
  - number theory
  - barcode-check-digit
---

# Barcode check digits: the last digit of an EAN-13 makes a weighted sum land on a multiple of 10

Number theory → Check Digits, Calendars and Cycles → Check digits → Barcode check digits

---

## General Overview

A pack on the shop counter. Under the black stripes, a row of digits: **5901234123457**. Thirteen of them.

Twelve are the product's name in numbers. The thirteenth is not information — it is a receipt for the other twelve.

The scanner reads all thirteen and does one small sum. On a multiple of 10, good read. Anywhere else a digit was misread, and the till stays quiet. That thirteenth is the **check digit**: a digit that lets the number test itself. The code is an **EAN-13** — International Article Number, thirteen digits (GS1 calls the number a GTIN-13).

**The last digit is chosen so that a weighted sum of all thirteen digits lands exactly on a multiple of 10, and anything else means a misread.**

### The picture: every digit with its weight under it

```
5901234123457, the weight under each digit, the product under that

  5   9   0   1   2   3   4   1   2   3   4   5  |  7
  1   3   1   3   1   3   1   3   1   3   1   3  |  1
  5  27   0   3   2   9   4   3   2   9   4  15  |  7
```

The twelve products left of the bar add to 83. Add the check digit's own 7 and you have 90.

---

## The formula

Weights run 1, 3, 1, 3 from the left. Multiply each digit by its weight and add:

**5 × 1 + 9 × 3 + 0 × 1 + 1 × 3 + 2 × 1 + 3 × 3 + 4 × 1 + 1 × 3 + 2 × 1 + 3 × 3 + 4 × 1 + 5 × 3 = 83**

The next multiple of 10 above 83 is 90, so:

**check digit = 90 − 83 = 7**

**Read it aloud:** weight the twelve digits, add them up, and the check digit is how far short of the next multiple of 10 you landed.

| Piece | Plain meaning | In our barcode |
| --- | --- | --- |
| the weights | 1, 3, 1, 3, … from the left | 1 for the 5, 3 for the 9 |
| the weighted sum | each digit times its weight, added | 83 |
| the check digit | how far short of the next multiple of 10 | 7 |
| the whole code | all thirteen weighted, check digit at weight 1 | 90 |

---

## Why it works

### Step 0: zero is the only leftover the scanner accepts

Thirteen is odd, so the check digit sits in an odd position and carries weight 1. Whatever the twelve leave over, it pays off — 10 minus that leftover. A good code therefore leaves nothing over on a 10-hour clock ([modular-addition-and-multiplication](../03-Clock%20Arithmetic/02-modular-addition-and-multiplication.md)): the remainder after dividing by 10 is 0. One number to look at, one value allowed.

The same in remainders: 83 leaves 3, and 10 − 3 is the 7.

### Step 1: one wrong digit can never hide

At weight 1 the total moves by the size of the change, 1 to 9 — never a multiple of 10, so it steps off. At weight 3 the move is 3 times the change. And 3 and 10 share no factor ([coprime-numbers](../02-Greatest%20Common%20Divisor%20and%20Euclid%27s%20Algorithm/05-coprime-numbers.md)). So the total lands on a multiple of 10 only when the change does — and the change is 1 to 9.

Mistype our fifth digit, the 2, as an 8: 5901834123457, total 96. Rejected.

### Step 2: five pairs of neighbours slip through

Neighbours carry weights 1 and 3, one each. Swap them and the total moves by twice the gap between the digits — a multiple of 10 only when that gap is 5, or 0, and 0 means the digits matched.

Swap the 9 and the 0 at the front of ours: gap 9, total 72. Rejected.

Now put a 0 and a 5 side by side. Change our fourth digit from 1 to 5 and redo the check digit: **5905234123455**, total 100, valid. Swap that 0 and 5: **5950234123455**, total 90, still a multiple of 10, accepted, wrong product. Five pairs are blind like this: 0 with 5, 1 with 6, on to 4 with 9.

<details>
<summary>The credit card version, folded</summary>

A bank card uses **Luhn's rule**, patented by Hans Peter Luhn in 1960: double every second digit from the right, fold anything past 9 by adding its two digits — double 7 for 14, then 1 + 4 = 5 — and land on a multiple of 10. The fold is what closes the swap hole, all but one pair.

</details>

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| the twelve digits, weighted | 5 + 27 + 0 + 3 + 2 + 9 + 4 + 3 + 2 + 9 + 4 + 15 | 83 |
| the next multiple of 10 | 90 | 90 |
| what is missing | 90 − 83 | **7** |
| the digit printed on the pack | last mark of 5901234123457 | **7** |
| all thirteen weighted | 83 + 7 | **90** |

Computed and printed agree, so nothing was misread.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| One digit mistyped, 5901834123457 | 96 | Not a multiple of 10; refused |
| Two neighbours swapped, 5091234123457 | 72 | Not a multiple of 10; refused |
| Neighbours 5 apart swapped, 5950234123455 | 90 | A multiple of 10; gets through |

---

## Code, from first principles, and it actually runs

Nothing is imported. The twelve digits are weighted and added the plain way; the check digit comes by the remainder on a 10-hour clock, then is matched against the printed digit. Then four codes: two caught, one valid, one that hides.

### Python

```python
# EAN-13 check digits -- the check behind the card.  Nothing is imported.  The
# barcode 5901234123457: weights 1, 3, 1, 3, ... left to right, and all
# thirteen weighted digits must add to a multiple of 10.
CODE = "5901234123457"
def weighted(code):                 # 1, 3, 1, 3, ... starting at 1 on the left
    return [int(d) * (1 if i % 2 == 0 else 3) for i, d in enumerate(code)]

def total(code):
    return sum(weighted(code))

def row(name, value, tail=""):
    print(f"{name:<38}{value:>4}{tail}")

first12 = total(CODE[:12])
check = (10 - first12 % 10) % 10                      # the second road: no search
print("the twelve digits, weighted:  " + " ".join(str(v) for v in weighted(CODE[:12])))
row("weighted sum of the first twelve", first12)
row("the multiple of 10 it lands on", first12 + check)
row("what is missing, the check digit", check)
row(f"all thirteen weighted, {first12} + {check}", total(CODE))
for name, code in (("one digit wrong, 5901834123457", "5901834123457"),
                   ("neighbours swapped, 5091234123457", "5091234123457"),
                   ("a 0 and a 5 side by side, valid", "5905234123455"),
                   ("those two swapped, 5950234123455", "5950234123455")):
    row(name, total(code), "  passes" if total(code) % 10 == 0 else "  fails")
print(f"a Luhn double folds: 2 x 7 = {2 * 7}, then {14 // 10} + {14 % 10} = {14 // 10 + 14 % 10}")
assert check == 7 and int(CODE[12]) == check and first12 == 83
assert total(CODE) == 90 and total("5901834123457") == 96 and total("5091234123457") == 72
assert total("5905234123455") == 100 and total("5950234123455") == 90
print("ALL CHECKS PASS")
```

**Ran 2026-09-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
the twelve digits, weighted:  5 27 0 3 2 9 4 3 2 9 4 15
weighted sum of the first twelve        83
the multiple of 10 it lands on          90
what is missing, the check digit         7
all thirteen weighted, 83 + 7           90
one digit wrong, 5901834123457          96  fails
neighbours swapped, 5091234123457       72  fails
a 0 and a 5 side by side, valid        100  passes
those two swapped, 5950234123455        90  passes
a Luhn double folds: 2 x 7 = 14, then 1 + 4 = 5
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// EAN-13 check digits -- the same check as barcode_check_digit_check.py, in
// Rust.  No crates.  The barcode 5901234123457: weights 1, 3, 1, 3, ... left
// to right, and all thirteen weighted digits must add to a multiple of 10.
const CODE: &str = "5901234123457";

fn weighted(code: &str) -> Vec<i64> {   // 1, 3, 1, 3, ... starting at 1 on the left
    code.bytes().enumerate()
        .map(|(i, b)| ((b - b'0') as i64) * if i % 2 == 0 { 1 } else { 3 })
        .collect()
}

fn total(code: &str) -> i64 { weighted(code).iter().sum() }

fn row(name: &str, value: i64, tail: &str) { println!("{:<38}{:>4}{}", name, value, tail); }

fn main() {
    let first12 = total(&CODE[..12]);
    let check = (10 - first12 % 10) % 10;             // the second road: no search
    let parts: Vec<String> = weighted(&CODE[..12]).iter().map(|v| v.to_string()).collect();
    println!("the twelve digits, weighted:  {}", parts.join(" "));
    row("weighted sum of the first twelve", first12, "");
    row("the multiple of 10 it lands on", first12 + check, "");
    row("what is missing, the check digit", check, "");
    row(&format!("all thirteen weighted, {} + {}", first12, check), total(CODE), "");
    for (name, code) in [("one digit wrong, 5901834123457", "5901834123457"),
                         ("neighbours swapped, 5091234123457", "5091234123457"),
                         ("a 0 and a 5 side by side, valid", "5905234123455"),
                         ("those two swapped, 5950234123455", "5950234123455")] {
        row(name, total(code), if total(code) % 10 == 0 { "  passes" } else { "  fails" });
    }
    println!("a Luhn double folds: 2 x 7 = {}, then {} + {} = {}",
             2 * 7, 14 / 10, 14 % 10, 14 / 10 + 14 % 10);
    assert!(check == 7 && (CODE.as_bytes()[12] - b'0') as i64 == check && first12 == 83);
    assert!(total(CODE) == 90 && total("5901834123457") == 96 && total("5091234123457") == 72);
    assert!(total("5905234123455") == 100 && total("5950234123455") == 90);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
the twelve digits, weighted:  5 27 0 3 2 9 4 3 2 9 4 15
weighted sum of the first twelve        83
the multiple of 10 it lands on          90
what is missing, the check digit         7
all thirteen weighted, 83 + 7           90
one digit wrong, 5901834123457          96  fails
neighbours swapped, 5091234123457       72  fails
a 0 and a 5 side by side, valid        100  passes
those two swapped, 5950234123455        90  passes
a Luhn double folds: 2 x 7 = 14, then 1 + 4 = 5
ALL CHECKS PASS
```

The two outputs match line for line.

> [!TIP]
> **Try changing**
> Guess first, then run it; an assert will fire.
> - **Break a digit.** Change the 9 in `CODE` to a 4. It carries weight 3 and the gap is 5, so the total drops 15: 90 becomes 75, and the first assert, on the check digit, fires.
> - **Flatten the weights.** Make every weight 1. The twelve digits add to 39, the check digit comes out 1, and every neighbouring swap turns invisible.

---

## The usual mistake

> [!warning]
> **Thinking a check digit says the number is correct.** It says the number is *consistent with itself*. Anyone can compute a valid check digit for a product that never existed. It catches accidents, not lies.
>
> - **Taking 10 for the check digit.** If the twelve already land on a multiple of 10, the digit is 0.
> - **Weighting from the wrong end.** The standard counts from the right. Thirteen is odd, so both ends agree here; on the twelve digits of a UPC they do not.

---

## Where you meet it in real life

- **Every till.** Scanners misread smudged stripes all day. The check digit is why the wrong tin almost never rings up at the wrong price; you just pass the pack again.
- **Bank cards and phone IMEI numbers.** Luhn's rule: why a site rejects a mistyped card before it reaches the bank.
- **Older books.** An ISBN-10 checks on an 11-hour clock, catching every swap this card misses: [isbn-check-digit](02-isbn-check-digit.md). Today's 13-digit ISBN is an EAN-13 and shares the hole.

> **Say it back**
> A barcode's last digit is not information, it is a test. Weight the digits 1, 3, 1, 3 and add them up; the last digit is picked to push the total onto a multiple of 10. Ours comes to 83, 7 short of 90, so the check digit is 7. Any single wrong digit shifts the total off the multiple and is caught. A swap of neighbours shifts it by twice their gap, so neighbours 5 apart slip through — the hole in the rule for swapped neighbours.

---

## What this builds on

- [place-value](../../01-Foundations/01-Everyday%20Arithmetic/01-place-value.md): a numeral is digits in columns, which is what lets a barcode be read a digit at a time.
- [divisibility-rules](../01-Divisibility%20and%20Primes/03-divisibility-rules.md): testing a number by weighting its digits, the move made here.
- [modular-addition-and-multiplication](../03-Clock%20Arithmetic/02-modular-addition-and-multiplication.md): only what a total leaves on a clock matters.
- [coprime-numbers](../02-Greatest%20Common%20Divisor%20and%20Euclid%27s%20Algorithm/05-coprime-numbers.md): two numbers sharing no factor, which is why weight 3 hides nothing.

## Where this goes next

- [isbn-check-digit](02-isbn-check-digit.md): the same trick on an 11-hour clock, where a prime modulus closes the swap hole this card leaves open.

---

## Sources

Verified 6 Sep 2026: every link below resolves to the publisher's page.

- GS1. *GS1 General Specifications*. [Standard page](https://ref.gs1.org/standards/genspecs/). Defines EAN-13, its weights and its check digit.
- Luhn, Hans Peter. *Computer for Verifying Numbers*. US Patent 2,950,048, 1960. [Patent page](https://patents.google.com/patent/US2950048A/en). The folded variant on bank cards.
