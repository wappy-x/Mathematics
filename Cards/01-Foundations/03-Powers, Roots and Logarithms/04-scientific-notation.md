# Scientific notation: very big and very small numbers as a number times a power of ten

[Syllabus](../../../SYLLABUS.md) → [Foundations](../../../SYLLABUS.md#w01) → [Powers, Roots and Logarithms](../../../SYLLABUS.md#w01-s03) → Scientific notation

---

## General Overview

The Sun is about 150,000,000 km away. A red blood cell is about 0.000007 m across. Put both on one page and neither reads: one is a wall of zeros, the other is zeros before a single 7.

Scientific notation — also called **standard form** — splits a number in two: a **front number** between 1 and 10, properly the **coefficient** (or significand), and a **power of ten** counting the tens to multiply or divide by. The Sun becomes 1.5 x 10^8 km. The cell becomes 7 x 10^-6 m. No zeros left to count, nothing rounded away.

**Write the front number, then the count of tens it rides on, and the number is written.**

### The picture: how far apart these two are

```
One block = one power of ten, counting up from the red blood cell.
10^0 is 1: no tens either way.

red blood cell      |                     7 x 10^-6 m
one metre           |██████               1 x 10^0 m
distance to the Sun |█████████████████    1.5 x 10^11 m
```

Six blocks from the cell to one metre. Seventeen to the Sun, in metres. A bar is not the size of the thing; it is how many tens get you there.

---

## The formula

Each number, written out then split:

**150,000,000 = 1.5 x 10^8**

**0.000007 = 7 x 10^-6**

**Read it aloud:** one point five, carried up by eight tens; and seven, carried down by six tens.

| Piece | Plain meaning | In our two numbers |
| --- | --- | --- |
| the front number (coefficient) | from 1 up to, not including, 10 | 1.5, and 7 |
| the power of ten | places the dot moves | 8, and -6 |
| a positive power | dot right, number big | 1.5 x 10^8 is 150,000,000 |
| a negative power | dot left, number small | 7 x 10^-6 is 0.000007 |
| the two together | front number on that power | the number, no zeros counted |

The minus in 10^-6 does not make the number negative. It says *divide* by ten six times: still positive, only small ([Exponents](01-exponents-and-powers.md)).

---

## Why it works

### Step 0: sliding the dot is multiplying by ten

Each column of a written number is worth ten times the column on its right. Slide the dot one place right and the number is multiplied by ten; one place left, divided by ten — [Decimals](../01-Everyday%20Arithmetic/08-decimals.md) read from the other end. Nothing is lost: slide back the same distance and the original is there.

### Step 1: slide until one digit stands in front

150,000,000 km. The dot sits unwritten at the right-hand end; slide it left 8 places to reach 1.5. Sliding left 8 places divided it by ten 8 times, so multiply back: **1.5 x 10^8 km.**

0.000007 m. Slide the dot right 6 places to reach 7. Sliding right 6 places multiplied it by ten 6 times, so divide back: **7 x 10^-6 m.**

### Step 2: change the unit, the power moves

One kilometre is 1000 m, which is 10^3 m. Multiplying powers of ten piles the tens up, so powers add: 8 + 3 = 11. **1.5 x 10^8 km is 1.5 x 10^11 m.** The front number never moved.

### Step 3: comparing is subtracting

How many blood cells wide is the distance to the Sun? Divide 1.5 x 10^11 m by 7 x 10^-6 m: front numbers divide, powers subtract.

1.5 ÷ 7 ≈ 0.2142857, and 11 − (−6) = 17, because taking away a debt of six tens hands you six more tens.

That is 0.2142857 x 10^17, not yet standard form: the front number must sit between 1 and 10. Slide the dot one place right, drop the power by one. **2.142857 x 10^16.**

The power alone is the number's **order of magnitude**: its size to the nearest ten-fold step. Which power a number sits on is [Logarithms](05-logarithms.md).

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| the Sun, dot left 8 places | 150,000,000 km | 1.5 x 10^8 km |
| km into m: 1000 is 10^3, powers add | 8 + 3 | 1.5 x 10^11 m |
| the cell, dot right 6 places | 0.000007 m | 7 x 10^-6 m |
| divide the front numbers | 1.5 ÷ 7 | ≈ 0.2142857 |
| subtract the powers | 11 − (−6) | 17 |
| slide back into standard form | 0.2142857 x 10^17 | **2.142857 x 10^16** |

The two powers are 17 apart, and sliding the front number back between 1 and 10 drops that by one: the Sun is about 2.142857 x 10^16 blood-cell widths away.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Counting the zeros after the dot in 0.000007: 5 of them, so 7 x 10^-5 | 0.000070 m | The dot travels 6 places, past the 7 — ten times too wide |
| Adding the powers instead of subtracting | 2.142857 x 10^4 | Division subtracts: 11 − (−6) |
| Front number outside 1 to 10 | 0.2142857 x 10^17 | Right size, wrong form, unreadable at a glance |

All three values appear in both outputs.

---

## Code, from first principles, and it actually runs

Nothing is imported. Each number is built the plain way, ten at a time, and checked against the numeral to within a hair. The comparison then takes two roads: plain division of the two full numbers, and front numbers divided while powers subtract.

### Python

```python
# Scientific notation -- the check behind the card.  Nothing is imported.  The
# distance to the Sun and the width of a red blood cell, each written out the
# long way and as a front number times a power of ten, then set side by side.

def times_ten(front, power):        # 1.5, 8 -> multiply 1.5 by ten, eight times
    value = front
    for _ in range(abs(power)):
        value = value * 10.0 if power > 0 else value / 10.0
    return value

def row(name, value):
    print(f"{name:<34}{value}")

row("distance to the Sun, km", f"{150000000.0:.0f}")
row("1.5 x 10^8 km, multiplied out", f"{times_ten(1.5, 8):.0f}")
row("distance to the Sun, m", f"{150000000000.0:.0f}")
row("1.5 x 10^11 m, multiplied out", f"{times_ten(1.5, 11):.0f}")
row("width of a red blood cell, m", f"{0.000007:.6f}")
row("7 x 10^-6 m, divided out", f"{times_ten(7.0, -6):.6f}")
long_way = 150000000000.0 / 0.000007                 # one road: plain division
front, power = 1.5 / 7.0 * 10.0, 11 - (-6) - 1       # the other: fronts, then powers
row("Sun over cell, plain division", f"{long_way / times_ten(1.0, 16):.6f} x 10^16")
row("Sun over cell, powers subtracted", f"{1.5 / 7.0:.7f} x 10^17 = {front:.6f} x 10^{power}")
print(f"the dot moves 8 places for the Sun in km and 6 for the cell; km to m adds 3; 11 - (-6) = {11 - (-6)}")
print("more to read: 6.02 x 10^23 slides the dot 23 places right, 1.5 x 10^-9 slides it 9 places left")
print(f"the mistakes come out at {times_ten(7.0, -5):.6f} m and {front:.6f} x 10^{11 + -6 - 1}")
assert times_ten(1.5, 8) == 150000000.0
assert abs(times_ten(7.0, -6) - 0.000007) < 1e-18
assert abs(long_way - times_ten(front, power)) < 1000000.0
print("ALL CHECKS PASS")
```

**Ran 2026-09-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
distance to the Sun, km           150000000
1.5 x 10^8 km, multiplied out     150000000
distance to the Sun, m            150000000000
1.5 x 10^11 m, multiplied out     150000000000
width of a red blood cell, m      0.000007
7 x 10^-6 m, divided out          0.000007
Sun over cell, plain division     2.142857 x 10^16
Sun over cell, powers subtracted  0.2142857 x 10^17 = 2.142857 x 10^16
the dot moves 8 places for the Sun in km and 6 for the cell; km to m adds 3; 11 - (-6) = 17
more to read: 6.02 x 10^23 slides the dot 23 places right, 1.5 x 10^-9 slides it 9 places left
the mistakes come out at 0.000070 m and 2.142857 x 10^4
ALL CHECKS PASS
```

### Rust

Same numbers and labels, built with `rustc --edition 2021 -O`.

```rust
// Scientific notation -- the same check as scientific_notation_check.py, in
// Rust.  No crates.  The distance to the Sun and the width of a red blood
// cell, written out the long way and as a front number times a power of ten.

fn times_ten(front: f64, power: i32) -> f64 {   // 1.5, 8 -> multiply 1.5 by ten, eight times
    let mut value = front;
    for _ in 0..power.abs() {
        value = if power > 0 { value * 10.0 } else { value / 10.0 };
    }
    value
}

fn row(name: &str, value: String) { println!("{:<34}{}", name, value); }

fn main() {
    row("distance to the Sun, km", format!("{:.0}", 150000000.0f64));
    row("1.5 x 10^8 km, multiplied out", format!("{:.0}", times_ten(1.5, 8)));
    row("distance to the Sun, m", format!("{:.0}", 150000000000.0f64));
    row("1.5 x 10^11 m, multiplied out", format!("{:.0}", times_ten(1.5, 11)));
    row("width of a red blood cell, m", format!("{:.6}", 0.000007f64));
    row("7 x 10^-6 m, divided out", format!("{:.6}", times_ten(7.0, -6)));
    let long_way = 150000000000.0f64 / 0.000007;                // one road: plain division
    let (front, power) = (1.5f64 / 7.0 * 10.0, 11 - (-6) - 1);  // the other: fronts, then powers
    row("Sun over cell, plain division", format!("{:.6} x 10^16", long_way / times_ten(1.0, 16)));
    row("Sun over cell, powers subtracted",
        format!("{:.7} x 10^17 = {:.6} x 10^{}", 1.5f64 / 7.0, front, power));
    println!("the dot moves 8 places for the Sun in km and 6 for the cell; km to m adds 3; 11 - (-6) = {}",
             11 - (-6));
    println!("more to read: 6.02 x 10^23 slides the dot 23 places right, 1.5 x 10^-9 slides it 9 places left");
    println!("the mistakes come out at {:.6} m and {:.6} x 10^{}",
             times_ten(7.0, -5), front, 11 + -6 - 1);
    assert!(times_ten(1.5, 8) == 150000000.0);
    assert!((times_ten(7.0, -6) - 0.000007).abs() < 1e-18);
    assert!((long_way - times_ten(front, power)).abs() < 1000000.0);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
distance to the Sun, km           150000000
1.5 x 10^8 km, multiplied out     150000000
distance to the Sun, m            150000000000
1.5 x 10^11 m, multiplied out     150000000000
width of a red blood cell, m      0.000007
7 x 10^-6 m, divided out          0.000007
Sun over cell, plain division     2.142857 x 10^16
Sun over cell, powers subtracted  0.2142857 x 10^17 = 2.142857 x 10^16
the dot moves 8 places for the Sun in km and 6 for the cell; km to m adds 3; 11 - (-6) = 17
more to read: 6.02 x 10^23 slides the dot 23 places right, 1.5 x 10^-9 slides it 9 places left
the mistakes come out at 0.000070 m and 2.142857 x 10^4
ALL CHECKS PASS
```

The two outputs match line for line.

> [!TIP]
> **Try changing**
> Guess first, then run it. The asserts are pinned to these numbers, so one will fire.
> - **Make the cell ten times wider.** Change every `-6` that belongs to the cell's width to `-5`. The width prints as 0.000070 m and the second assert fires.
> - **Add the powers instead of subtracting.** On the line that sets the front number and the power, change `11 - (-6)` to `11 + (-6)`. The comparison collapses to 2.142857 x 10^4 and the third assert fires: plain division still says 2.142857 x 10^16.

---

## The usual mistake

> [!warning]
> **Reading the power as a count of zeros.** It counts places the dot moves, not zeros. 150,000,000 has seven zeros, but the power is 8: the dot also travels past the 5.
>
> - Adding the powers when the job was division: 2.142857 x 10^16 becomes 2.142857 x 10^4, easy to miss because the front number still looks right.
> - Changing the unit and leaving the power alone: in metres the Sun is 1.5 x 10^11, not 1.5 x 10^8.

---

## Where you meet it in real life

- **Calculator and phone screens.** `1.5e11` and `1.5E11` both mean 1.5 x 10^11; the `e` is shorthand for "times ten to the".
- **Chemistry and physics constants.** 6.02 x 10^23 is the count of particles in one mole — written out, a line of digits nobody could check.
- **Lab and engineering measurements.** A gap of 1.5 x 10^-9 m is a length no ruler shows: the power carries the smallness, the front number the precision.

> **Say it back**
> Very big and very small numbers are hard to read because they are mostly zeros. Split each one: a front number between 1 and 10, times a power of ten. The power counts the places the dot moved, right if positive, left if negative. The Sun is 1.5 x 10^11 m away, a red blood cell 7 x 10^-6 m across. Divide the front numbers and subtract the powers: the two powers are 17 apart, and with the front number back between 1 and 10 that is 2.142857 x 10^16 cell widths.

---

## What this builds on

- [Exponents](01-exponents-and-powers.md): what a power is, why a power of zero is 1, why a negative power divides.
- [Decimals](../01-Everyday%20Arithmetic/08-decimals.md): the columns right of the dot, where the small number lives.

## Where this goes next

- [Logarithms](05-logarithms.md): "what power got me here?", when the power is not a whole number.
- [Log laws and log scales](06-log-laws-and-log-scales.md): an axis marked 1, 10, 100 instead of 1, 2, 3 — this card's picture as a ruler.

---

## Sources

Verified 6 Sep 2026; every link resolves.

- NASA Goddard, *Sun Fact Sheet*. [nssdc.gsfc.nasa.gov](https://nssdc.gsfc.nasa.gov/planetary/factsheet/sunfact.html). The Earth-to-Sun distance, rounded here to 150,000,000 km.
- Dean, Laura. *Blood Groups and Red Cell Antigens*. NCBI Bookshelf, 2005. [ncbi.nlm.nih.gov](https://www.ncbi.nlm.nih.gov/books/NBK2263/). The red cell at a few millionths of a metre, rounded here to 0.000007 m.
- Bureau International des Poids et Mesures, *The International System of Units (SI Brochure)*, 9th ed. [bipm.org](https://www.bipm.org/en/publications/si-brochure). The official powers of ten behind kilo, milli and micro.
