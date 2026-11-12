# Absolute and relative error: wrong by how much, wrong by what fraction

[Syllabus](../../../SYLLABUS.md) → [Numerical analysis](../README.md) → [Floating Point and Error](../README.md#s01) → Absolute and relative error

---

## General Overview

A carpenter cuts a beam that should be 3,000 mm long (an illustrative figure, like every length and price on this card). It comes out at 2,998 mm: 2 mm short. The beam still fits the roof. Nobody will ever notice.

The same afternoon a 20 mm bolt comes off the lathe at 18 mm: also 2 mm short. That bolt is scrap. It no longer reaches through the nut.

Both parts missed by 2 mm. The miss in millimetres is the **absolute error**. It says *how much* the result is wrong. The miss as a share of the true length is the **relative error**. It says *what fraction* of the thing is wrong: 0.0667 percent of the beam, 10 percent of the bolt. The bolt is 150 times worse, and only the relative error shows it.

The relative error also tells you how many digits of a result to trust. The beam's 2,998 mm is right to three significant digits: "3.00 m". The bolt's 18 mm is right to one: "2 × 10^1 mm". This card shows how to quote an error both ways, how to turn one into the other, and how to count correct digits.

**The absolute error is the miss in the quantity's own units; the relative error is that miss divided by the true size, and it counts how many leading digits of the result can be trusted.**

**What kind of fact this is:** two definitions (absolute error, relative error), a convention (what "p correct significant digits" means), and a theorem, proved on this card in Why it works: the relative error fixes the number of correct digits to within one.

### The picture: one miss, two parts

```
The same 2 mm miss, as a share of each part.  One █ = 0.5 percent.

3,000 mm beam   ▏                         0.0667 percent
20 mm bolt      ████████████████████     10 percent
```

The beam's bar is too short to draw. The bolt's is twenty blocks. The millimetres are identical; the fractions are not.

---

## The formula

First, a name for the result we got. Write $x$ for the **true value** (3,000 mm) and $\hat x$, read "x hat" or "the computed x", for the **value we got** (2,998 mm). The hat means "measured, cut or computed, and possibly wrong".

$$E_{\text{abs}} = |\hat x - x| \qquad\qquad E_{\text{rel}} = \frac{|\hat x - x|}{|x|} \quad (x \neq 0)$$

**Read it aloud:** the absolute error is the distance between what we got and the truth; the relative error is that distance divided by the size of the truth.

The bars $|\ \ |$ mean "size, ignoring the sign". The signed miss $\hat x - x = -2$ mm says the beam is short. The error sizes drop the sign and keep the 2.

Converting between the two is one multiply or one divide:

$$E_{\text{abs}} = E_{\text{rel}} \times |x| \qquad\qquad E_{\text{rel}} = E_{\text{abs}} \div |x|$$

A tape rated at 0.1 percent can be off by 0.001 × 3,000 = 3.000 mm on the beam and by 0.001 × 20 = 0.020 mm on the bolt. One rating, two very different millimetre figures.

**Correct significant digits.** Write the true value in scientific notation, $|x| = $ (a front number at least 1 and below 10) $\times 10^k$, so $10^k \le |x| < 10^{k+1}$. The beam is $3 \times 10^3$ mm, so $k = 3$. The result $\hat x$ has $p$ **correct significant digits** when its miss is at most half a unit in the $p$-th digit of $x$:

$$E_{\text{abs}} \le \tfrac12 \times 10^{\,k-p+1}$$

For the beam, digit 3 is the tens-of-millimetres digit, so half a unit is 5 mm. The 2 mm miss fits; the 0.5 mm half-unit of digit 4 does not. Three correct digits.

The theorem proved below links digits to the relative error:

$$E_{\text{rel}} \le 5 \times 10^{-(p+1)} \;\Rightarrow\; \text{at least } p \text{ correct digits} \;\Rightarrow\; E_{\text{rel}} \le 5 \times 10^{-p}$$

**Read it aloud:** a relative error of at most half of ten to the minus p guarantees p good digits, and p good digits force it to be at most five times ten to the minus p.

As a rule of thumb, the number of correct digits is close to $-\log_{10} E_{\text{rel}}$: 3.176 for the beam, 1.000 for the bolt.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $x$ | the true value | 3,000 mm beam; 20 mm bolt | the same miss becomes a smaller fraction |
| $\hat x$, "the computed x" | the value we got: cut, measured or computed | 2,998 mm; 18 mm | further from $x$, bigger errors |
| $E_{\text{abs}}$ | absolute error: the miss, in the quantity's units | 2 mm on both | fewer correct digits |
| $E_{\text{rel}}$ | relative error: the miss as a fraction of $\lvert x\rvert$, no units | 6.667e-4, meaning 6.667 × 10^-4 (0.0667 percent); 1.000e-1 (10 percent) | fewer correct digits |
| $k$ | the power of ten in $x$'s scientific notation | 3 for the beam; 1 for the bolt | each digit is worth ten times more |
| $p$ | the count of correct significant digits | 3 for the beam; 1 for the bolt | a tighter half-unit test to pass |
| $c$ | a unit-change factor, used in Why it works | 1/1000, millimetres to metres | both errors in new units; the relative one unchanged |

### When it holds

- **The true value is not zero, and not close to it.** At $x = 0$ the relative error divides by zero. Near zero it explodes: a beam meant to leave 1 mm of clearance in a 3,001 mm opening leaves 3 mm, a relative error of 200 percent on the clearance.
- **You divide by the true value.** In practice the truth is often unknown, so people divide by $\hat x$. That gives $E_{\text{rel}} / (1 - E_{\text{rel}})$ for a short result: 11.1111 percent for the bolt instead of 10. Harmless when the error is small, misleading when it is not.
- **The digit count refers to the true value's digits.** Comparing the characters of 2,998 and 3,000 finds no digit in common, yet the cut is good to three digits. The half-unit test is the one that counts.
- **The error is a true error, an estimate or a bound, and you say which.** Here the true lengths are known, so every error on this card is a **true error**. Usually only a bound is known; the formulas are the same, read as "at most".

---

## Why it works

### Step 0: an error has a size and a scale

A miss of 2 mm is a size. Whether it matters depends on the scale of the thing it is a miss *of*. Dividing by the true value measures the miss against that scale, which is what "a fraction of the beam" means ([Percentages](../../01-Foundations/01-Everyday%20Arithmetic/10-percentages.md): a percent is a fraction of a named whole).

### Step 1: the relative error has no units

Measure the beam in metres instead: $x = 3$ m, $\hat x = 2.998$ m. The absolute error becomes 0.002000 m, a different number. The relative error is still 6.667e-4.

The reason is one line. Changing units multiplies $x$ and $\hat x$ by the same factor $c$ (here $c = 1/1000$). The top of the fraction becomes $c\,|\hat x - x|$ and the bottom becomes $c\,|x|$. The $c$ cancels. That is why a relative error can compare a beam with a bolt, a rent with a lunch, or a distance to the Moon with a microchip.

### Step 2: digits measure the miss at the scale of the number

Scientific notation puts every number on the same footing: one digit in front, then a power of ten ([Scientific notation](../../01-Foundations/03-Powers%2C%20Roots%20and%20Logarithms/04-scientific-notation.md)). The first significant digit of $x$ is worth $10^k$, the second $10^{k-1}$, and the $p$-th $10^{k-p+1}$.

Rounding to $p$ digits can move a number by up to half of that last unit. So "p correct digits" means "the miss is no bigger than a rounding at digit p would allow": $E_{\text{abs}} \le \tfrac12 \times 10^{k-p+1}$. That is a convention, chosen because it matches what rounding does. Higham's standard reference writes "less than" half a unit where this card writes "at most". The two differ only when the miss is exactly half a unit, and no example on this card sits on that edge.

### Step 3: the relative error pins the digits to within one

The digit test uses the absolute error and the power $k$. The relative error uses the absolute error and $|x|$. Since $|x|$ sits between $10^k$ and $10^{k+1}$, the two tests can disagree by at most one factor of ten, which is one digit.

<details>
<summary>Detailed proof: both directions of the bracket</summary>

Write $10^k \le |x| < 10^{k+1}$.

**p correct digits force a small relative error.** Suppose $E_{\text{abs}} \le \tfrac12 \times 10^{k-p+1}$. Divide both sides by $|x|$, which is at least $10^k$:

$$E_{\text{rel}} \le \frac{\tfrac12 \times 10^{k-p+1}}{10^k} = \tfrac12 \times 10^{1-p} = 5 \times 10^{-p}.$$

**A small enough relative error guarantees p correct digits.** Suppose $E_{\text{rel}} \le 5 \times 10^{-(p+1)} = \tfrac12 \times 10^{-p}$. Multiply by $|x|$, which is less than $10^{k+1}$:

$$E_{\text{abs}} = E_{\text{rel}}\,|x| < \tfrac12 \times 10^{-p} \times 10^{k+1} = \tfrac12 \times 10^{k-p+1}.$$

That is the half-unit test for digit $p$. Both directions are proved.

**The rule of thumb.** If $p$ digits are correct, the first direction gives $p \le -\log_{10} E_{\text{rel}} + \log_{10} 5$, and $\log_{10} 5 \approx 0.699$. If digit $p + 1$ is not correct, the second direction (taken the other way round) gives $E_{\text{rel}} > 5 \times 10^{-(p+2)}$, so $p > -\log_{10} E_{\text{rel}} - 1.301$. The true count lies in that window, from $-\log_{10} E_{\text{rel}} - 1.301$ up to $-\log_{10} E_{\text{rel}} + 0.699$. It is two units wide, so it holds two whole numbers: the same two the bracket allows. They need not sit either side of $-\log_{10} E_{\text{rel}}$: for the beam, at 3.176, they are 2 and 3.

</details>

The bracket is tight: both ends happen. A 10 m rail cut 4 mm short and a 97.5 m rail cut 39 mm short both have relative error 4.000e-4. The first has 4 correct digits, the second 3. Same fraction, one digit apart, because 10,000 sits at the bottom of its power of ten and 97,500 near the top.

---

## Worked numbers, by hand

The beam: $x = 3000$ mm, $\hat x = 2998$ mm. Then the bolt: $x = 20$ mm, $\hat x = 18$ mm.

| Step | Arithmetic | Value |
| --- | --- | --- |
| beam, signed miss | 2,998 − 3,000 | −2 mm |
| beam, absolute error | size of −2 | 2 mm |
| beam, relative error | 2 ÷ 3,000 | 6.667e-4 |
| as a percent | 6.667e-4 × 100 | 0.0667 percent |
| beam in scientific notation | 3,000 = 3 × 10^3 | $k = 3$ |
| half a unit in digit 3 | ½ × 10^(3 − 3 + 1) | 5 mm, and 2 ≤ 5 passes |
| half a unit in digit 4 | ½ × 10^(3 − 4 + 1) | 0.5 mm, and 2 > 0.5 fails |
| beam, correct digits | passes at 3, fails at 4 | **3 digits** |
| bolt, relative error | 2 ÷ 20 | 1.000e-1, 10 percent |
| bolt in scientific notation | 20 = 2 × 10^1 | $k = 1$ |
| half a unit in digits 1 and 2 | 5 mm passes, 0.5 mm fails | **1 digit** |
| bolt against beam | 1.000e-1 ÷ 6.667e-4 | **150.0 times worse** |

The beam measured as 2,998 mm can be trusted as "3.00 m". The bolt measured as 18 mm can be trusted only as "about 20 mm", one digit. The same 2 mm costs the beam nothing and the bolt everything.

A check from the relative error alone: for the beam it allows 2 or 3 digits (bracket 2-3), and the half-unit test settles it at 3. For the bolt it allows 0 or 1, and the test gives 1.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Quote only the absolute error | "2 mm" for both parts | Hides a factor of 150.0 between them; a miss means nothing without the size of the thing |
| Divide by the cut length, not the true one | bolt 11.1111 percent instead of 10; beam 6.671e-4 instead of 6.667e-4 | The bottom of the fraction is the result, not the truth; it gives $E_{\text{rel}}/(1 - E_{\text{rel}})$ |
| Count the characters 2998 and 3000 share | 0 correct digits instead of 3 | A carry across 3,000 changes every written digit while the value moves only 2 mm |
| Take the relative error of a near-zero quantity | 200 percent on a 1 mm clearance | The true value is tiny, so any miss is a huge fraction of it |

---

## Code, from first principles, and it actually runs

The code repeats every number on the card for the beam, the bolt, two rails, the clearance and four "Try changing" cases. Lengths are whole millimetres, so the misses are exact. It reaches the digit count by **two independent roads**: the half-unit test on the absolute error, and the bracket from the relative error alone, which must contain it and be at most one digit wide.

A third check is the $-\log_{10}$ window from the proof. It also converts each relative error back to millimetres, changes units to metres, and tests the identity behind the wrong denominator. Last, it runs the shelf's shared example: a fitness tracker that adds 0.1 ten million times.

### Python

```python
# Absolute and relative error -- the check behind the card.  Standard library only.
# A 3,000 mm beam and a 20 mm bolt, each cut 2 mm short.  Lengths are whole
# millimetres, so the misses and the digit test are exact integer arithmetic;
# the relative error is a float, checked against the integers and a bracket.
from math import log10


def sci(v, d):                       # e-notation printed the same way as Rust: 6.667e-4
    m, e = f"{v:.{d}e}".split("e")
    return m + "e" + str(int(e))


def lead_power(x):                   # k with 10^k <= x < 10^(k+1): the power in scientific notation
    k = 0
    while 10 ** (k + 1) <= x:
        k += 1
    return k


def digits(x, miss):                 # road 1: p correct digits when miss <= half a unit in digit p
    k, p = lead_power(x), 0
    while p < 17 and 2 * miss * 10 ** p <= 10 ** k:
        p += 1
    return p


def half_unit(x, p):                 # half a unit in digit p of x: 1/2 x 10^(k-p+1)
    k = lead_power(x)
    return 5 * 10 ** (k - p) if k >= p else 5 / 10 ** (p - k)


def bracket(rel):                    # road 2: what the relative error alone allows
    lo = hi = 0
    while lo < 17 and rel * 10 ** (lo + 2) <= 5:   # rel <= 5 x 10^-(p+1) guarantees p digits
        lo += 1
    while hi < 17 and rel * 10 ** (hi + 1) <= 5:   # p digits forces rel <= 5 x 10^-p
        hi += 1
    return lo, hi


def matching(a, b):                  # the wrong test: count leading characters that agree
    n = 0
    for c, d in zip(str(a), str(b)):
        if c != d:
            break
        n += 1
    return n


def report(name, x, xhat):
    miss = abs(xhat - x)             # absolute error, exact
    rel = miss / x                   # relative error
    p, (lo, hi) = digits(x, miss), bracket(rel)
    print(f"{name}: true {x}, got {xhat}, abs {miss}, rel {sci(rel, 3)}, "
          f"percent {100 * rel:.4f}, digits {p}, bracket {lo}-{hi}, -log10 {-log10(rel):.3f}, "
          f"half-units at digits {p} and {p + 1}: {half_unit(x, p)}, {half_unit(x, p + 1)}")
    assert abs(rel * x - miss) < 1e-12 * x            # converting back gives the integer miss
    assert (p == 0 or miss <= half_unit(x, p)) and miss > half_unit(x, p + 1)
    assert lo <= p <= hi and hi - lo <= 1             # the relative error pins digits within one
    assert -log10(rel) - 1.302 < p <= -log10(rel) + 0.699
    return miss, rel, p


beam_abs, beam_rel, beam_p = report("beam", 3000, 2998)
bolt_abs, bolt_rel, bolt_p = report("bolt", 20, 18)
print(f"same miss, bolt rel / beam rel = {bolt_rel / beam_rel:.1f}")
print(f"kept digits: beam {2998 / 1000:.{beam_p - 1}f} m, bolt {sci(18, bolt_p - 1)} mm")
assert beam_abs == bolt_abs == 2 and beam_p == 3 and bolt_p == 1
assert abs(bolt_rel / beam_rel - 3000 / 20) < 1e-9

# units: metres change the absolute error, not the relative one
m_abs, m_rel = abs(2.998 - 3.0), abs(2.998 - 3.0) / 3.0
print(f"beam in metres: abs {m_abs:.6f} m, rel {sci(m_rel, 3)}")
assert abs(m_rel - beam_rel) < 1e-12 and abs(m_abs * 1000 - beam_abs) < 1e-9

# converting: a tape rated 0.1 percent, as millimetres on each part
for name, x in (("beam", 3000), ("bolt", 20)):
    print(f"0.1 percent of the {name}: {0.001 * x:.3f} mm")

# same relative error 4e-4, one digit apart
r1, r2 = report("10 m rail", 10000, 9996), report("97.5 m rail", 97500, 97461)
assert r1[1] == r2[1] == 4e-4 and (r1[2], r2[2]) == (4, 3)

# what breaks
print(f"wrong: divide by the cut length, bolt {100 * 2 / 18:.4f} percent, beam {sci(2 / 2998, 3)}")
assert abs(2 / 18 - bolt_rel / (1 - bolt_rel)) < 1e-15        # dividing by xhat gives rel/(1 - rel)
print(f"wrong: count matching digits of 2998 and 3000: {matching(2998, 3000)}")
gap = report("clearance in a 3001 mm opening", 3001 - 3000, 3001 - 2998)
assert gap[1] == 2.0 and gap[2] == 0

# try changing
tries = [report(name, x, xhat)[2] for name, x, xhat in (
    ("beam, 1 mm miss", 3000, 2999), ("beam, 6 mm miss", 3000, 2994),
    ("200 mm bolt, 2 mm miss", 200, 198), ("30 m girder, 2 mm miss", 30000, 29998))]
assert tries == [3, 2, 2, 4]                                   # the digit counts found by hand

# the shelf's house example: a tracker adds 0.1 ten million times
total = 0.0
for _ in range(10_000_000):
    total += 0.1
t_abs = abs(total - 1_000_000)
t_rel = t_abs / 1_000_000
t_p, (t_lo, t_hi) = digits(1_000_000, t_abs), bracket(t_rel)
print(f"tracker: total {total:.6f}, abs {sci(t_abs, 3)}, rel {sci(t_rel, 3)}, digits {t_p}, bracket {t_lo}-{t_hi}")
assert 1e-4 < t_abs < 2e-4 and t_p == 10 and t_lo <= t_p <= t_hi
print("ALL CHECKS PASS")
```

**Ran 2026-11-11 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
beam: true 3000, got 2998, abs 2, rel 6.667e-4, percent 0.0667, digits 3, bracket 2-3, -log10 3.176, half-units at digits 3 and 4: 5, 0.5
bolt: true 20, got 18, abs 2, rel 1.000e-1, percent 10.0000, digits 1, bracket 0-1, -log10 1.000, half-units at digits 1 and 2: 5, 0.5
same miss, bolt rel / beam rel = 150.0
kept digits: beam 3.00 m, bolt 2e1 mm
beam in metres: abs 0.002000 m, rel 6.667e-4
0.1 percent of the beam: 3.000 mm
0.1 percent of the bolt: 0.020 mm
10 m rail: true 10000, got 9996, abs 4, rel 4.000e-4, percent 0.0400, digits 4, bracket 3-4, -log10 3.398, half-units at digits 4 and 5: 5, 0.5
97.5 m rail: true 97500, got 97461, abs 39, rel 4.000e-4, percent 0.0400, digits 3, bracket 3-4, -log10 3.398, half-units at digits 3 and 4: 50, 5
wrong: divide by the cut length, bolt 11.1111 percent, beam 6.671e-4
wrong: count matching digits of 2998 and 3000: 0
clearance in a 3001 mm opening: true 1, got 3, abs 2, rel 2.000e0, percent 200.0000, digits 0, bracket 0-0, -log10 -0.301, half-units at digits 0 and 1: 5, 0.5
beam, 1 mm miss: true 3000, got 2999, abs 1, rel 3.333e-4, percent 0.0333, digits 3, bracket 3-4, -log10 3.477, half-units at digits 3 and 4: 5, 0.5
beam, 6 mm miss: true 3000, got 2994, abs 6, rel 2.000e-3, percent 0.2000, digits 2, bracket 2-3, -log10 2.699, half-units at digits 2 and 3: 50, 5
200 mm bolt, 2 mm miss: true 200, got 198, abs 2, rel 1.000e-2, percent 1.0000, digits 2, bracket 1-2, -log10 2.000, half-units at digits 2 and 3: 5, 0.5
30 m girder, 2 mm miss: true 30000, got 29998, abs 2, rel 6.667e-5, percent 0.0067, digits 4, bracket 3-4, -log10 4.176, half-units at digits 4 and 5: 5, 0.5
tracker: total 999999.999839, abs 1.610e-4, rel 1.610e-10, digits 10, bracket 9-10
ALL CHECKS PASS
```

### Rust

```rust
// Absolute and relative error -- the same check as absolute_and_relative_error_check.py,
// in Rust.  No crates.  A 3,000 mm beam and a 20 mm bolt, each cut 2 mm short.
// Misses are whole millimetres held exactly in f64; powers of ten are built by
// repeated multiplication, so every comparison matches the Python run bit for bit.
fn sci(v: f64, d: usize) -> String {       // e-notation, the same text as Python's: 6.667e-4
    format!("{:.*e}", d, v)
}

fn pow10(n: i32) -> f64 {                  // exact for the powers used here
    let mut p = 1.0;
    for _ in 0..n {
        p *= 10.0;
    }
    p
}

fn lead_power(x: f64) -> i32 {             // k with 10^k <= x < 10^(k+1)
    let mut k = 0;
    while pow10(k + 1) <= x {
        k += 1;
    }
    k
}

fn digits(x: f64, miss: f64) -> i32 {      // road 1: miss <= half a unit in digit p
    let (k, mut p) = (lead_power(x), 0);
    while p < 17 && 2.0 * miss * pow10(p) <= pow10(k) {
        p += 1;
    }
    p
}

fn half_unit(x: f64, p: i32) -> f64 {      // half a unit in digit p of x: 1/2 x 10^(k-p+1)
    let k = lead_power(x);
    if k >= p { 5.0 * pow10(k - p) } else { 5.0 / pow10(p - k) }
}

fn bracket(rel: f64) -> (i32, i32) {       // road 2: what the relative error alone allows
    let (mut lo, mut hi) = (0, 0);
    while lo < 17 && rel * pow10(lo + 2) <= 5.0 {
        lo += 1;
    }
    while hi < 17 && rel * pow10(hi + 1) <= 5.0 {
        hi += 1;
    }
    (lo, hi)
}

fn matching(a: i64, b: i64) -> usize {     // the wrong test: leading characters that agree
    let (sa, sb) = (a.to_string(), b.to_string());
    sa.chars().zip(sb.chars()).take_while(|(c, d)| c == d).count()
}

fn report(name: &str, x: i64, xhat: i64) -> (f64, f64, i32) {
    let miss = (xhat - x).abs() as f64;
    let xf = x as f64;
    let rel = miss / xf;
    let (p, (lo, hi)) = (digits(xf, miss), bracket(rel));
    println!("{}: true {}, got {}, abs {}, rel {}, percent {:.4}, digits {}, bracket {}-{}, -log10 {:.3}, \
              half-units at digits {} and {}: {}, {}",
             name, x, xhat, miss, sci(rel, 3), 100.0 * rel, p, lo, hi, -rel.log10(),
             p, p + 1, half_unit(xf, p), half_unit(xf, p + 1));
    assert!((rel * xf - miss).abs() < 1e-12 * xf);
    assert!((p == 0 || miss <= half_unit(xf, p)) && miss > half_unit(xf, p + 1));
    assert!(lo <= p && p <= hi && hi - lo <= 1);
    let pf = p as f64;
    assert!(-rel.log10() - 1.302 < pf && pf <= -rel.log10() + 0.699);
    (miss, rel, p)
}

fn main() {
    let (beam_abs, beam_rel, beam_p) = report("beam", 3000, 2998);
    let (bolt_abs, bolt_rel, bolt_p) = report("bolt", 20, 18);
    println!("same miss, bolt rel / beam rel = {:.1}", bolt_rel / beam_rel);
    println!("kept digits: beam {:.*} m, bolt {} mm", (beam_p - 1) as usize, 2998.0 / 1000.0,
             sci(18.0, (bolt_p - 1) as usize));
    assert!(beam_abs == 2.0 && bolt_abs == 2.0 && beam_p == 3 && bolt_p == 1);
    assert!((bolt_rel / beam_rel - 3000.0 / 20.0).abs() < 1e-9);

    let m_abs = (2.998f64 - 3.0).abs();
    let m_rel = m_abs / 3.0;
    println!("beam in metres: abs {:.6} m, rel {}", m_abs, sci(m_rel, 3));
    assert!((m_rel - beam_rel).abs() < 1e-12 && (m_abs * 1000.0 - beam_abs).abs() < 1e-9);

    for (name, x) in [("beam", 3000.0), ("bolt", 20.0)] {
        println!("0.1 percent of the {}: {:.3} mm", name, 0.001 * x);
    }

    let (r1, r2) = (report("10 m rail", 10000, 9996), report("97.5 m rail", 97500, 97461));
    assert!(r1.1 == 4e-4 && r2.1 == 4e-4 && r1.2 == 4 && r2.2 == 3);

    println!("wrong: divide by the cut length, bolt {:.4} percent, beam {}",
             100.0 * 2.0 / 18.0, sci(2.0 / 2998.0, 3));
    assert!((2.0 / 18.0 - bolt_rel / (1.0 - bolt_rel)).abs() < 1e-15);
    println!("wrong: count matching digits of 2998 and 3000: {}", matching(2998, 3000));
    let gap = report("clearance in a 3001 mm opening", 3001 - 3000, 3001 - 2998);
    assert!(gap.1 == 2.0 && gap.2 == 0);

    let mut tries = Vec::new();
    for (name, x, xhat) in [("beam, 1 mm miss", 3000, 2999), ("beam, 6 mm miss", 3000, 2994),
                            ("200 mm bolt, 2 mm miss", 200, 198), ("30 m girder, 2 mm miss", 30000, 29998)] {
        tries.push(report(name, x, xhat).2);
    }
    assert!(tries == vec![3, 2, 2, 4]);                // the digit counts found by hand

    let mut total = 0.0f64;
    for _ in 0..10_000_000 {
        total += 0.1;
    }
    let t_abs = (total - 1_000_000.0).abs();
    let t_rel = t_abs / 1_000_000.0;
    let (t_p, (t_lo, t_hi)) = (digits(1_000_000.0, t_abs), bracket(t_rel));
    println!("tracker: total {:.6}, abs {}, rel {}, digits {}, bracket {}-{}",
             total, sci(t_abs, 3), sci(t_rel, 3), t_p, t_lo, t_hi);
    assert!(1e-4 < t_abs && t_abs < 2e-4 && t_p == 10 && t_lo <= t_p && t_p <= t_hi);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-11 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
beam: true 3000, got 2998, abs 2, rel 6.667e-4, percent 0.0667, digits 3, bracket 2-3, -log10 3.176, half-units at digits 3 and 4: 5, 0.5
bolt: true 20, got 18, abs 2, rel 1.000e-1, percent 10.0000, digits 1, bracket 0-1, -log10 1.000, half-units at digits 1 and 2: 5, 0.5
same miss, bolt rel / beam rel = 150.0
kept digits: beam 3.00 m, bolt 2e1 mm
beam in metres: abs 0.002000 m, rel 6.667e-4
0.1 percent of the beam: 3.000 mm
0.1 percent of the bolt: 0.020 mm
10 m rail: true 10000, got 9996, abs 4, rel 4.000e-4, percent 0.0400, digits 4, bracket 3-4, -log10 3.398, half-units at digits 4 and 5: 5, 0.5
97.5 m rail: true 97500, got 97461, abs 39, rel 4.000e-4, percent 0.0400, digits 3, bracket 3-4, -log10 3.398, half-units at digits 3 and 4: 50, 5
wrong: divide by the cut length, bolt 11.1111 percent, beam 6.671e-4
wrong: count matching digits of 2998 and 3000: 0
clearance in a 3001 mm opening: true 1, got 3, abs 2, rel 2.000e0, percent 200.0000, digits 0, bracket 0-0, -log10 -0.301, half-units at digits 0 and 1: 5, 0.5
beam, 1 mm miss: true 3000, got 2999, abs 1, rel 3.333e-4, percent 0.0333, digits 3, bracket 3-4, -log10 3.477, half-units at digits 3 and 4: 5, 0.5
beam, 6 mm miss: true 3000, got 2994, abs 6, rel 2.000e-3, percent 0.2000, digits 2, bracket 2-3, -log10 2.699, half-units at digits 2 and 3: 50, 5
200 mm bolt, 2 mm miss: true 200, got 198, abs 2, rel 1.000e-2, percent 1.0000, digits 2, bracket 1-2, -log10 2.000, half-units at digits 2 and 3: 5, 0.5
30 m girder, 2 mm miss: true 30000, got 29998, abs 2, rel 6.667e-5, percent 0.0067, digits 4, bracket 3-4, -log10 4.176, half-units at digits 4 and 5: 5, 0.5
tracker: total 999999.999839, abs 1.610e-4, rel 1.610e-10, digits 10, bracket 9-10
ALL CHECKS PASS
```

### Lean

Lean proves the digit bracket, the unit change and the wrong-denominator identity for every allowed value, and checks the card's whole-millimetre examples.

- For any true value $x$ that is not zero, a relative error of at most $5 \times 10^{-(p+1)}$ guarantees $p$ correct digits.
- The other way round, $p$ correct digits force a relative error of at most $5 \times 10^{-p}$.
- Multiplying the true and computed values by the same nonzero factor $c$ leaves the relative error unchanged.
- For a short result, $0 < \hat x \le x$, dividing the miss by $\hat x$ gives exactly $E_{\text{rel}} / (1 - E_{\text{rel}})$.
- The hand arithmetic holds exactly: the beam, the bolt, the factor of 150, the tape, the two rails and the 200 percent clearance.

The decimals, the $-\log_{10}$ window, the matching-characters mistake, the Try changing cases and the tracker are left to the Python and Rust checks.

```lean
-- Absolute and relative error: the relative error fixes the number of correct significant digits to within one.
import Mathlib.Data.Int.Log
import Mathlib.Algebra.Order.Archimedean.Real.Basic
import Mathlib.Tactic.NormNum

/-! The true value is `x`, the computed value is `x̂` (written `xhat`).
The absolute error is `|xhat - x|` and the relative error is `|xhat - x| / |x|`.
The power `k` in the scientific notation of `x` is Mathlib's `Int.log 10 |x|`,
the unique integer with `10 ^ k ≤ |x| < 10 ^ (k + 1)` when `x ≠ 0`.
`xhat` has `p` correct significant digits when `|xhat - x| ≤ 1/2 * 10 ^ (k - p + 1)`. -/

/-- The relative error pins the number of correct significant digits to within one:
for a nonzero true value `x` with `10 ^ k ≤ |x| < 10 ^ (k + 1)`,
a relative error of at most `5 * 10 ^ (-(p + 1))` guarantees `p` correct digits
(miss at most half a unit in digit `p`), and `p` correct digits force
a relative error of at most `5 * 10 ^ (-p)`. -/
theorem relative_error_pins_correct_digits (x xhat : ℝ) (hx : x ≠ 0) (p : ℕ) :
    (|xhat - x| / |x| ≤ 5 * (10 : ℝ) ^ (-((p : ℤ) + 1)) →
        |xhat - x| ≤ 1 / 2 * (10 : ℝ) ^ (Int.log 10 |x| - p + 1)) ∧
    (|xhat - x| ≤ 1 / 2 * (10 : ℝ) ^ (Int.log 10 |x| - p + 1) →
        |xhat - x| / |x| ≤ 5 * (10 : ℝ) ^ (-(p : ℤ))) := by
  have hax : 0 < |x| := abs_pos.mpr hx
  have hlo : (10 : ℝ) ^ Int.log 10 |x| ≤ |x| := by
    have := Int.zpow_log_le_self (b := 10) (r := |x|) (by norm_num) hax
    exact_mod_cast this
  have hhi : |x| < (10 : ℝ) ^ (Int.log 10 |x| + 1) := by
    have := Int.lt_zpow_succ_log_self (b := 10) (R := ℝ) (by norm_num) |x|
    exact_mod_cast this
  generalize Int.log 10 |x| = k at hlo hhi ⊢
  have h10 : (10 : ℝ) ≠ 0 := by norm_num
  have key1 : (1 : ℝ) / 2 * (10 : ℝ) ^ (k - p + 1) =
      5 * (10 : ℝ) ^ (-((p : ℤ) + 1)) * 10 ^ (k + 1) := by
    rw [mul_assoc, ← zpow_add₀ h10]
    have : k - p + 1 = (-((p : ℤ) + 1) + (k + 1)) + 1 := by ring
    rw [this, zpow_add_one₀ h10]; ring
  have key2 : (1 : ℝ) / 2 * (10 : ℝ) ^ (k - p + 1) = 5 * (10 : ℝ) ^ (-(p : ℤ)) * 10 ^ k := by
    rw [mul_assoc, ← zpow_add₀ h10]
    have : k - p + 1 = (-(p : ℤ) + k) + 1 := by ring
    rw [this, zpow_add_one₀ h10]; ring
  constructor
  · intro h
    rw [div_le_iff₀ hax] at h
    rw [key1]
    calc |xhat - x| ≤ 5 * (10 : ℝ) ^ (-((p : ℤ) + 1)) * |x| := h
      _ ≤ 5 * (10 : ℝ) ^ (-((p : ℤ) + 1)) * 10 ^ (k + 1) :=
        mul_le_mul_of_nonneg_left hhi.le (mul_pos (by norm_num) (zpow_pos (by norm_num) _)).le
  · intro h
    rw [div_le_iff₀ hax]
    rw [key2] at h
    calc |xhat - x| ≤ 5 * (10 : ℝ) ^ (-(p : ℤ)) * 10 ^ k := h
      _ ≤ 5 * (10 : ℝ) ^ (-(p : ℤ)) * |x| :=
        mul_le_mul_of_nonneg_left hlo (mul_pos (by norm_num) (zpow_pos (by norm_num) _)).le

/-- The relative error has no units: changing units multiplies the true and computed
values by the same nonzero factor `c`, and the relative error does not change. -/
theorem relative_error_unchanged_by_units (x xhat c : ℝ) (hc : c ≠ 0) :
    |c * xhat - c * x| / |c * x| = |xhat - x| / |x| := by
  rw [← mul_sub, abs_mul, abs_mul]
  exact mul_div_mul_left _ _ (abs_ne_zero.mpr hc)

/-- Dividing by the result instead of the truth: for a short result `0 < xhat ≤ x`,
the miss divided by `xhat` equals `E_rel / (1 - E_rel)`, where `E_rel` is the true
relative error. -/
theorem divide_by_result_gives_rel_over_one_minus_rel (x xhat : ℝ) (hxhat : 0 < xhat)
    (hshort : xhat ≤ x) :
    |xhat - x| / |xhat| = (|xhat - x| / |x|) / (1 - |xhat - x| / |x|) := by
  have hx : 0 < x := lt_of_lt_of_le hxhat hshort
  rw [abs_of_nonpos (by linarith), abs_of_pos hx, abs_of_pos hxhat]
  have : 1 - -(xhat - x) / x = xhat / x := by field_simp; ring
  rw [this, div_div_div_cancel_right₀ hx.ne']

/-! The card's whole-number worked examples, in millimetres. -/

-- Beam: x = 3000, xhat = 2998. Absolute error 2, relative error 2/3000.
example : |(2998 : ℝ) - 3000| = 2 := by norm_num
example : |(2998 : ℝ) - 3000| / |(3000 : ℝ)| = 2 / 3000 := by norm_num
-- Beam in scientific notation: k = 3.
example : (10 : ℝ) ^ (3 : ℤ) ≤ 3000 ∧ (3000 : ℝ) < 10 ^ ((3 : ℤ) + 1) := by norm_num
-- Beam: passes the half-unit test at digit 3 (5 mm), fails it at digit 4 (1/2 mm): 3 digits.
example : |(2998 : ℝ) - 3000| ≤ 1 / 2 * (10 : ℝ) ^ ((3 : ℤ) - 3 + 1) := by norm_num
example : ¬ (|(2998 : ℝ) - 3000| ≤ 1 / 2 * (10 : ℝ) ^ ((3 : ℤ) - 4 + 1)) := by norm_num
-- Bolt: x = 20, xhat = 18. Relative error 1/10, k = 1, one correct digit.
example : |(18 : ℝ) - 20| / |(20 : ℝ)| = 1 / 10 := by norm_num
example : (10 : ℝ) ^ (1 : ℤ) ≤ 20 ∧ (20 : ℝ) < 10 ^ ((1 : ℤ) + 1) := by norm_num
example : |(18 : ℝ) - 20| ≤ 1 / 2 * (10 : ℝ) ^ ((1 : ℤ) - 1 + 1) ∧
    ¬ (|(18 : ℝ) - 20| ≤ 1 / 2 * (10 : ℝ) ^ ((1 : ℤ) - 2 + 1)) := by norm_num
-- The bolt is 150 times worse than the beam.
example : (2 / 20 : ℝ) / (2 / 3000) = 150 := by norm_num
-- A tape rated at 1/1000: 3 mm on the beam, 1/50 mm on the bolt.
example : (1 / 1000 : ℝ) * 3000 = 3 ∧ (1 / 1000 : ℝ) * 20 = 1 / 50 := by norm_num
-- Dividing by the cut length for the bolt: 2/18 = (1/10) / (1 - 1/10).
example : (2 / 18 : ℝ) = (1 / 10) / (1 - 1 / 10) := by norm_num
-- Two rails with the same relative error 4/10000, one digit apart.
example : (4 : ℝ) / 10000 = 39 / 97500 := by norm_num
-- 10 m rail: k = 4, passes digit 4 (5 mm), fails digit 5: 4 digits.
example : (4 : ℝ) ≤ 1 / 2 * (10 : ℝ) ^ ((4 : ℤ) - 4 + 1) ∧
    ¬ ((4 : ℝ) ≤ 1 / 2 * (10 : ℝ) ^ ((4 : ℤ) - 5 + 1)) := by norm_num
-- 97.5 m rail: k = 4, passes digit 3 (50 mm), fails digit 4 (5 mm): 3 digits.
example : (10 : ℝ) ^ (4 : ℤ) ≤ 97500 ∧ (97500 : ℝ) < 10 ^ ((4 : ℤ) + 1) := by norm_num
example : (39 : ℝ) ≤ 1 / 2 * (10 : ℝ) ^ ((4 : ℤ) - 3 + 1) ∧
    ¬ ((39 : ℝ) ≤ 1 / 2 * (10 : ℝ) ^ ((4 : ℤ) - 4 + 1)) := by norm_num
-- Clearance: true 1 mm, got 3 mm, relative error 2 (200 percent).
example : |(3 : ℝ) - 1| / |(1 : ℝ)| = 2 := by norm_num

#print axioms relative_error_pins_correct_digits
#print axioms relative_error_unchanged_by_units
#print axioms divide_by_result_gives_rel_over_one_minus_rel
```

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'relative_error_pins_correct_digits' depends on axioms: [propext, Classical.choice, Quot.sound]
'relative_error_unchanged_by_units' depends on axioms: [propext, Classical.choice, Quot.sound]
'divide_by_result_gives_rel_over_one_minus_rel' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then look at the matching line of the output.
> - **Guess first: does halving the beam's miss buy a digit?** Make the cut 2,999 mm. The relative error halves to 3.333e-4, but the count stays at 3 digits: 1 mm is still more than the 0.5 mm half-unit of digit 4.
> - **Guess first: how big a miss costs the beam a digit?** Make the cut 2,994 mm. A 6 mm miss is over the 5 mm half-unit of digit 3, so the count drops to 2 digits, at 0.2000 percent.
> - **Guess first: a ten-times longer bolt?** A 200 mm bolt cut to 198 mm has relative error 1.000e-2, 1 percent, and 2 correct digits. Ten times the length, one more digit.
> - **Guess first: a 30 m girder?** The same 2 mm on 30,000 mm is 6.667e-5 and 4 correct digits. Each factor of ten in length buys about one digit.

---

## The usual mistake

> [!warning]
> **Quoting an error without the size of the thing.** "Accurate to 2 mm" is excellent for a 3,000 mm beam (6.667e-4, three good digits) and useless for a 20 mm bolt (10 percent, one good digit). An absolute error carries units and no scale. Say what it is an error *in*, or quote the relative error beside it.
>
> - **Dividing by the result instead of the truth.** For the bolt this gives 11.1111 percent instead of 10. When the truth is unknown, say which you divided by.
> - **Counting matching characters as correct digits.** 2,998 and 3,000 share no written digit, yet 2,998 is good to 3 digits. Use the half-unit test.
> - **Trusting a relative error near zero.** A 2 mm miss on a 1 mm clearance is 200 percent. When the true value can be zero, quote the absolute error.

---

## Where you meet it in real life

- **Engineering drawings.** A dimension carries a tolerance in millimetres, an absolute error allowed. General tolerance tables allow a bigger miss on a longer part, which is the relative error at work.
- **Measurement reports.** Metrology, the science of measurement, separates the **error**, the true miss, which is rarely known, from the **uncertainty**, a stated bound on it. The international guide to expressing uncertainty is the standard for laboratories.
- **Money.** A $2 mistake on $3,000 of rent is 6.667e-4; the same $2 on a $20 lunch is 10 percent. The arithmetic is the beam and the bolt again.
- **Computers.** A computer stores most numbers with a small relative error, under the same bound for a tiny number as for a huge one ([IEEE 754](02-ieee-floating-point.md)). The shelf's fitness tracker adds 0.1 ten million times and reads 999,999.999839 instead of 1,000,000: an absolute error of 1.610e-4, a relative error of 1.610e-10, and 10 correct digits. Why it drifts, and how to stop it, is [Adding a million numbers without losing the small ones](07-summation-kahan-and-welford.md).
- **Subtraction.** Taking the difference of two close numbers turns a small relative error into a large one, as the clearance did here: [Machine epsilon and cancellation](03-rounding-cancellation-and-machine-epsilon.md).
- **Published results.** "Three significant figures" in a lab report is a claim that the relative error is at most about 5 parts in 1,000.

> **Say it back**
> The absolute error is how far a result is from the truth, in the quantity's own units. The relative error divides that by the size of the truth, so it has no units and compares parts of any size. A 2 mm miss is 6.667e-4 of a 3,000 mm beam and 10 percent of a 20 mm bolt, 150 times worse. A result has p correct digits when its miss is at most half a unit in the p-th digit of the truth. The relative error fixes that count to within one: about minus the base-ten log of the relative error.

---

## What this builds on

- [Percentages](../../01-Foundations/01-Everyday%20Arithmetic/10-percentages.md): a percent is a fraction of a named whole. A relative error is that fraction, with the true value as the whole.
- [Scientific notation](../../01-Foundations/03-Powers%2C%20Roots%20and%20Logarithms/04-scientific-notation.md): a front number times a power of ten. The power $k$ fixes what each significant digit is worth, which the digit test needs.

## Where this goes next

- [IEEE 754](02-ieee-floating-point.md): how a computer holds a number in a sign, an exponent and a fraction, and why its rounding is a relative error, not an absolute one.
- [Interval arithmetic](09-interval-arithmetic-in-outline.md): instead of one number and a quoted error, carry a guaranteed range through every step of a calculation.

The rest of the shelf uses both kinds of error: [Two different errors](04-truncation-versus-rounding-error.md), [Conditioning and stability](05-conditioning-and-stability.md), [Forward and backward error](06-forward-and-backward-error.md) and [Counting the work](08-operation-counts-and-cost.md).

Left open: the tracker never measured anything badly. A computer number holds about 16 significant digits, yet the total kept only 10. Where, inside the machine, did the other six go?

---

## Sources

Verified 2026-11-11: every link below resolves to the publisher's page.

- Higham, Nicholas J. *Accuracy and Stability of Numerical Algorithms*, 2nd ed. SIAM, 2002. [doi:10.1137/1.9780898718027](https://doi.org/10.1137/1.9780898718027). Section 1.2 defines absolute and relative error and correct significant digits by the half-unit rule, and warns that the definitions are subtle.
- Goldberg, David. "What Every Computer Scientist Should Know About Floating-Point Arithmetic." *ACM Computing Surveys* 23, no. 1 (1991): 5–48. [doi:10.1145/103162.103163](https://doi.org/10.1145/103162.103163). Relative error as the natural measure for numbers a computer stores.
- Joint Committee for Guides in Metrology. *JCGM 100:2008, Evaluation of measurement data - Guide to the expression of uncertainty in measurement*. BIPM. [Publisher page](https://www.bipm.org/en/committees/jc/jcgm/publications). The laboratory standard that separates a measurement's error from its stated uncertainty.
