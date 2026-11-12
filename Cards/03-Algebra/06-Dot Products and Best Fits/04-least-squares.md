# Least squares: the best-fit line is a projection, and the normal equations hand it to you in one step

[Syllabus](../../../SYLLABUS.md) → [Algebra](../README.md) → [Dot Products and Best Fits](../README.md#s06) → Least squares

---

## General Overview

Four used cars at one dealer, same model. One year old: $20,000. Two years: $17,000. Three years: $13,000. Four years: $10,000. Prices are counted in thousands from here: 20, 17, 13 and 10.

One rule for all four would be a straight line: a price when new, the same amount off every year. But the drops are 3, then 4, then 3, and a line drops by the same amount each year — four demands, two numbers, so something has to miss.

So ask which line misses least. Least squares scores every candidate the same way — each car's miss, squared, the four squares added — and takes the smallest total.

The winner is price = 23.5 − 3.4 × age: the cars land at 20.1, 16.7, 13.3 and 9.9, squared miss 0.2. The worst single miss is $300, on a car that sold for 13 thousand. One equation hands that line over; no hunting.

**The four cars stack into one matrix equation with no exact answer, and the best fit is the shadow of the prices on everything a line can reach: the misses left over stick straight out of it.**

**What kind of fact this is:** a method, resting on a theorem proved on this card in Why it works: the nearest point of a flat sheet is the one whose leftover is perpendicular.

### The picture: four cars, and the line that misses least

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Four used cars: price paid, and the least-squares line"
    x-axis "Age of the car, in years" [1, 2, 3, 4]
    y-axis "Price, in thousands of dollars" 0 --> 25
    bar [20, 17, 13, 10]
    line [20.1, 16.7, 13.3, 9.9]
```

The bars are the prices paid, the line is the fit; those four gaps are the subject of this card.

---

## The formula

Car by car, the wish is slope × age + intercept = price — four equations in two unknowns.

Stack the left-hand sides into a matrix, one row per car: the age, then a 1. Call it $A$, 4 rows × 2 columns:

`[[1, 1], [2, 1], [3, 1], [4, 1]]`

The first column holds the ages; the second is all ones and carries the intercept, the price at age zero. The unknowns go in $x$ = (slope, intercept), the prices in $b$ = (20, 17, 13, 10). Multiplying $A$ by $x$ ([Matrix multiplication](../04-Matrices/03-matrix-multiplication.md)) rebuilds all four left-hand sides:

$$A x = b$$

and it has no solution. Least squares swaps it for one that does:

$$A^T A x = A^T b$$

$A^T$, said "A transpose", is $A$ with rows and columns swapped: the 4 × 2 becomes 2 × 4.

**Read it aloud:** multiply both sides by the flipped table, and an unsolvable wish becomes two ordinary equations whose answer is the closest line.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $A$ | one row per car: its age, then a 1 | `[[1, 1], [2, 1], [3, 1], [4, 1]]`, 4 × 2 | more cars pull on the same two numbers |
| $x$ | the unknowns: slope, then intercept | (−3.4, 23.5) | — |
| $b$ | the prices paid, one per car | (20, 17, 13, 10) | raise one, the line tilts that way |
| $A^T$ | "A transpose": rows and columns swapped | 2 × 4: ages in row one, 1s in row two | — |
| $A^T A$ | the columns of $A$ dotted with each other | `[[30, 10], [10, 4]]` | — |
| $A^T b$ | those columns dotted with the prices | (133, 60) | — |
| $r$ | the leftover: price minus fitted price, the residual | (−0.1, 0.3, −0.3, 0.1) | worse fit; the squares are the score |

Every entry is a dot product ([The dot product](01-dot-product.md)): multiply matching entries, add them up. Out come 30 × slope + 10 × intercept = 133 and 10 × slope + 4 × intercept = 60.

### When it holds

- **The ages differ.** Equal ages make the columns copies. Then the determinant, the number whose zero means no unique answer, is zero: no single slope and intercept.
- **A line is the right shape.** A curved pattern gets a best line that is still the wrong shape; a column for age squared fits the curve.
- **Only the prices miss.** Ages count as known; sloppy ages tilt the slope, unreported.
- **Every car counts the same, squared.** One cheap sale to a friend outweighs three ordinary cars nudging back.

---

## Why it works

### Step 0: four prices are one point

Stop counting cars and count coordinates: the four prices are one arrow, $b$ = (20, 17, 13, 10), in a space with one axis per car.

A line's four predictions are slope × (1, 2, 3, 4) + intercept × (1, 1, 1, 1): every mix of the two columns of $A$. Those mixes sweep out a flat sheet, one point per drawable line — and $b$ is not on it. Fitting is finding the sheet's nearest point.

### Step 1: nearest means perpendicular

That is the projection card ([Projection](02-orthogonal-projection.md)): the nearest point is the shadow, and the leftover is perpendicular. A leaning leftover would run partly along the sheet, and sliding that way would shorten it. So the fit is the shadow of $b$, and $r$ = $b$ − $A x$ points straight out. Squared lengths add that way, by Pythagoras — which is why the score squares each miss.

### Step 2: perpendicular to the sheet means perpendicular to both columns

Everything in the sheet is a mix of the two columns, so an arrow at right angles to both is at right angles to every mix. Two dot products carry the condition: ages column · $r$ = 0, ones column · $r$ = 0. That pair is $A^T r$ = (0, 0) — multiplying by $A^T$ dots each column of $A$ with what follows.

```mermaid
flowchart LR
    B["prices b<br/>(20, 17, 13, 10)"] -->|"drop a perpendicular"| P["shadow A x<br/>(20.1, 16.7, 13.3, 9.9)"]
    B -->|"what is left"| R["leftover r<br/>(-0.1, 0.3, -0.3, 0.1)"]
    R -->|"dot product 0 with each"| C["the two columns of A<br/>ages (1, 2, 3, 4), ones (1, 1, 1, 1)"]
    P -->|"is a mix of"| C
```

The prices split into a shadow a line can hit and a leftover no line can touch.

### Step 3: write the two zeros out, and the equation appears

Put $r$ = $b$ − $A x$ back into $A^T r$ = 0:

$$A^T (b - A x) = 0$$

Push $A^T$ through the bracket, move the second piece across:

$$A^T A x = A^T b$$

These are the **normal equations**; "normal" is the old word for perpendicular, so the name is the geometry. No calculus, nothing minimised by hand: "the leftover is perpendicular" *is* the equation.

### Step 4: two equations, two unknowns

$A^T A$ is 2 × 2 however many cars there are: four here, four thousand at a dealership. Its determinant — the number whose vanishing means no unique answer ([The inverse matrix](../05-Solving%20Systems/03-inverse-matrix.md)) — is 30 × 4 − 10 × 10 = 20. Working code solves the pair rather than inverting.

**The other road.** Statistics teaches this line with no matrix: slope = sum of (age − average age) × (price − average price), divided by the sum of (age − average age) squared. Then intercept = average price − slope × average age. With average age 2.5 and average price 15: −17 ÷ 5 = −3.4, then 15 + 8.5 = 23.5 — the same equations rearranged. The code runs both.

---

## Worked numbers, by hand

Ages 1, 2, 3, 4. Prices 20, 17, 13, 10, in thousands.

| Step | Arithmetic | Value |
| --- | --- | --- |
| ages · ages | 1 + 4 + 9 + 16 | 30 |
| ages · ones | 1 + 2 + 3 + 4 | 10 |
| ones · ones | four cars | 4 |
| ages · prices | 20 + 34 + 39 + 40 | 133 |
| ones · prices | 20 + 17 + 13 + 10 | 60 |
| determinant | 30 × 4 − 10 × 10 | 20 |
| slope | (133 × 4 − 10 × 60) ÷ 20 | **−3.4** |
| intercept | (30 × 60 − 10 × 133) ÷ 20 | **23.5** |
| fitted prices | 23.5 − 3.4 × each age | 20.1, 16.7, 13.3, 9.9 |
| leftovers | 20 − 20.1, 17 − 16.7, 13 − 13.3, 10 − 9.9 | −0.1, 0.3, −0.3, 0.1 |
| total squared miss | 0.01 + 0.09 + 0.09 + 0.01 | **0.2** |

The model is worth about 23.5 thousand new and drops about 3.4 thousand a year, never more than 0.3 out.

The leftovers carry their own certificate. Ones column: −0.1 + 0.3 − 0.3 + 0.1 = 0. Ages column: −0.1 + 0.6 − 0.9 + 0.4 = 0. Both zero: no other line scores lower.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Dropping the column of ones | slope 4.4333, squared miss 368.3667 | Without an intercept the line starts at zero and tilts up: older cars cost more |
| Fitting the first and last car only | slope −3.3333, squared miss 0.2222 | An exact hit on two cars, no say for the other two |
| Adding the leftovers, not squaring | 0.0000, and 0.0000 again for price = 27.5 − 5 × age | Ups cancel downs, so a line scoring 13.0000 squared ties the best |

The code prints all three.

---

## Code, from first principles, and it actually runs

Nothing is imported. Road one builds the dot products behind $A^T A$ and $A^T b$ from the raw ages and prices, then cross-multiplies the 2 × 2 system; road two reaches the same line from the two averages. The scripts also dot the leftovers against both columns, reproduce the three wrong answers, and fit a second lot of prices.

### Python

```python
# Least squares -- the check behind the card.  Nothing is imported.  Four used cars:
# ages 1, 2, 3, 4 years and prices $20k, $17k, $13k, $10k.  Two roads to the same
# line: the normal equations A^T A x = A^T b, built and solved here by hand, and the
# slope-from-the-means formula that statistics teaches instead.
AGES, PRICES = [1.0, 2.0, 3.0, 4.0], [20.0, 17.0, 13.0, 10.0]
LATER, MISSES = [21.0, 18.0, 12.0, 9.0], [-0.1, 0.3, -0.3, 0.1]   # second lot; misses by hand

def normal_equations(xs, ys):                     # road 1: A^T A x = A^T b, 2x2
    n, sx, sy = float(len(xs)), sum(xs), sum(ys)
    sxx = sum(x * x for x in xs)                  # ages column dotted with itself
    sxy = sum(x * y for x, y in zip(xs, ys))      # ages column dotted with prices
    det = sxx * n - sx * sx                       # Cramer's rule, written out
    return (sxy * n - sx * sy) / det, (sxx * sy - sx * sxy) / det, [sxx, sx, n, sxy, sy]

def from_means(xs, ys):                           # road 2: the statistics formula
    mx, my = sum(xs) / len(xs), sum(ys) / len(ys)
    top = sum((x - mx) * (y - my) for x, y in zip(xs, ys))
    slope = top / sum((x - mx) * (x - mx) for x in xs)
    return slope, my - slope * mx

def squared_miss(xs, ys, m, k):                   # the score any line is judged by
    return sum((y - (m * x + k)) ** 2 for x, y in zip(xs, ys))
def row(name, values): print(f"{name:<36}" + "".join(f"{v:>8.2f}" for v in values))
def one(name, value): print(f"{name:<36}{value:>16}")

m1, k1, s = normal_equations(AGES, PRICES)
m2, k2 = from_means(AGES, PRICES)
fits = [m1 * x + k1 for x in AGES]
left = [y - f for y, f in zip(PRICES, fits)]
dot_age, dot_one = sum(x * r for x, r in zip(AGES, left)), sum(left)
sse = squared_miss(AGES, PRICES, m1, k1)
row("ages, in years", AGES)
row("prices, in $ thousands", PRICES)
row("A^T A, first row", [s[0], s[1]])
row("A^T A, second row", [s[1], s[2]])
row("A^T b", [s[3], s[4]])
print(f"road 1, the normal equations        slope {m1:>8.4f}   intercept {k1:>8.4f}")
print(f"road 2, from the two means          slope {m2:>8.4f}   intercept {k2:>8.4f}")
row("fitted prices, in $ thousands", fits)
row("misses, price minus fitted price", left)
one("total squared miss", f"{sse:.4f}")
one("leftover dot ages column", f"{abs(dot_age):.12f}")
one("leftover dot ones column", f"{abs(dot_one):.12f}")
m0, mf = s[3] / s[0], (PRICES[3] - PRICES[0]) / (AGES[3] - AGES[0])
sse0 = squared_miss(AGES, PRICES, m0, 0.0)        # wrong: no ones column
ssef = squared_miss(AGES, PRICES, mf, PRICES[0] - mf * AGES[0])   # wrong: two cars only
plain_5, sse5 = sum(y - (-5.0 * x + 27.5) for x, y in zip(AGES, PRICES)), \
    squared_miss(AGES, PRICES, -5.0, 27.5)
print(f"wrong, no ones column: slope {m0:.4f}, squared miss {sse0:.4f}")
print(f"wrong, first and last car only: slope {mf:.4f}, squared miss {ssef:.4f}")
print(f"wrong, misses added not squared: fitted line {abs(dot_one):.4f}, "
      f"the -5.0 line {abs(plain_5):.4f}, whose squared miss is {sse5:.4f}")
m3, k3, _ = normal_equations(AGES, LATER)
print(f"second case, prices 21, 18, 12, 9: slope {m3:.4f}, intercept {k3:.4f}, "
      f"squared miss {squared_miss(AGES, LATER, m3, k3):.4f}")
assert s == [30.0, 10.0, 4.0, 133.0, 60.0]
assert abs(m1 + 3.4) < 1e-12 and abs(k1 - 23.5) < 1e-12 and abs(sse - 0.2) < 1e-12 and max(abs(r - t) for r, t in zip(left, MISSES)) < 1e-12
assert abs(m1 - m2) < 1e-12 and abs(k1 - k2) < 1e-12 and abs(dot_age) < 1e-12 and abs(dot_one) < 1e-12
assert sse < ssef < sse5 < sse0 and abs(m3 + 4.2) < 1e-12 and abs(k3 - 25.5) < 1e-12
print("ALL CHECKS PASS")
```

**Ran 2026-09-19 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
ages, in years                          1.00    2.00    3.00    4.00
prices, in $ thousands                 20.00   17.00   13.00   10.00
A^T A, first row                       30.00   10.00
A^T A, second row                      10.00    4.00
A^T b                                 133.00   60.00
road 1, the normal equations        slope  -3.4000   intercept  23.5000
road 2, from the two means          slope  -3.4000   intercept  23.5000
fitted prices, in $ thousands          20.10   16.70   13.30    9.90
misses, price minus fitted price       -0.10    0.30   -0.30    0.10
total squared miss                            0.2000
leftover dot ages column              0.000000000000
leftover dot ones column              0.000000000000
wrong, no ones column: slope 4.4333, squared miss 368.3667
wrong, first and last car only: slope -3.3333, squared miss 0.2222
wrong, misses added not squared: fitted line 0.0000, the -5.0 line 0.0000, whose squared miss is 13.0000
second case, prices 21, 18, 12, 9: slope -4.2000, intercept 25.5000, squared miss 1.8000
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Least squares -- the same check as the Python, in Rust.  No crates.  Four used
// cars: ages 1, 2, 3, 4 years and prices $20k, $17k, $13k, $10k.  Two roads to the
// same line: the normal equations A^T A x = A^T b, built and solved here by hand,
// and the slope-from-the-means formula that statistics teaches instead.
const AGES: [f64; 4] = [1.0, 2.0, 3.0, 4.0];
const PRICES: [f64; 4] = [20.0, 17.0, 13.0, 10.0];
const LATER: [f64; 4] = [21.0, 18.0, 12.0, 9.0];        // a second lot, same ages
const MISSES: [f64; 4] = [-0.1, 0.3, -0.3, 0.1];        // the four misses, by hand

fn normal_equations(xs: &[f64], ys: &[f64]) -> (f64, f64, Vec<f64>) {
    let n = xs.len() as f64;                            // road 1: A^T A x = A^T b
    let sx: f64 = xs.iter().sum();
    let sy: f64 = ys.iter().sum();
    let sxx: f64 = xs.iter().map(|x| x * x).sum();      // ages column dotted with itself
    let sxy: f64 = xs.iter().zip(ys).map(|(x, y)| x * y).sum();   // ages with prices
    let det = sxx * n - sx * sx;                        // Cramer's rule, written out
    ((sxy * n - sx * sy) / det, (sxx * sy - sx * sxy) / det, vec![sxx, sx, n, sxy, sy])
}
fn from_means(xs: &[f64], ys: &[f64]) -> (f64, f64) {   // road 2: the statistics formula
    let mx: f64 = xs.iter().sum::<f64>() / xs.len() as f64;
    let my: f64 = ys.iter().sum::<f64>() / ys.len() as f64;
    let top: f64 = xs.iter().zip(ys).map(|(x, y)| (x - mx) * (y - my)).sum();
    let slope = top / xs.iter().map(|x| (x - mx) * (x - mx)).sum::<f64>();
    (slope, my - slope * mx)
}
fn squared_miss(xs: &[f64], ys: &[f64], m: f64, k: f64) -> f64 {   // the score
    xs.iter().zip(ys).map(|(x, y)| (y - (m * x + k)) * (y - (m * x + k))).sum()
}
fn row(name: &str, values: &[f64]) {
    let mut line = format!("{:<36}", name);
    for v in values { line.push_str(&format!("{:>8.2}", v)); }
    println!("{}", line);
}
fn one(name: &str, value: String) { println!("{:<36}{:>16}", name, value); }
fn main() {
    let (m1, k1, s) = normal_equations(&AGES, &PRICES);
    let (m2, k2) = from_means(&AGES, &PRICES);
    let fits: Vec<f64> = AGES.iter().map(|x| m1 * x + k1).collect();
    let left: Vec<f64> = PRICES.iter().zip(&fits).map(|(y, f)| y - f).collect();
    let dot_age: f64 = AGES.iter().zip(&left).map(|(x, r)| x * r).sum();
    let dot_one: f64 = left.iter().sum();
    let sse = squared_miss(&AGES, &PRICES, m1, k1);
    row("ages, in years", &AGES);
    row("prices, in $ thousands", &PRICES);
    row("A^T A, first row", &[s[0], s[1]]);
    row("A^T A, second row", &[s[1], s[2]]);
    row("A^T b", &[s[3], s[4]]);
    println!("road 1, the normal equations        slope {:>8.4}   intercept {:>8.4}", m1, k1);
    println!("road 2, from the two means          slope {:>8.4}   intercept {:>8.4}", m2, k2);
    row("fitted prices, in $ thousands", &fits);
    row("misses, price minus fitted price", &left);
    one("total squared miss", format!("{:.4}", sse));
    one("leftover dot ages column", format!("{:.12}", dot_age.abs()));
    one("leftover dot ones column", format!("{:.12}", dot_one.abs()));
    let (m0, mf) = (s[3] / s[0], (PRICES[3] - PRICES[0]) / (AGES[3] - AGES[0]));
    let sse0 = squared_miss(&AGES, &PRICES, m0, 0.0);            // wrong: no ones column
    let ssef = squared_miss(&AGES, &PRICES, mf, PRICES[0] - mf * AGES[0]);  // two cars only
    let plain_5: f64 = AGES.iter().zip(&PRICES).map(|(x, y)| y - (-5.0 * x + 27.5)).sum();
    let sse5 = squared_miss(&AGES, &PRICES, -5.0, 27.5);
    println!("wrong, no ones column: slope {:.4}, squared miss {:.4}", m0, sse0);
    println!("wrong, first and last car only: slope {:.4}, squared miss {:.4}", mf, ssef);
    println!("wrong, misses added not squared: fitted line {:.4}, the -5.0 line {:.4}, \
whose squared miss is {:.4}", dot_one.abs(), plain_5.abs(), sse5);
    let (m3, k3, _) = normal_equations(&AGES, &LATER);
    println!("second case, prices 21, 18, 12, 9: slope {:.4}, intercept {:.4}, \
squared miss {:.4}", m3, k3, squared_miss(&AGES, &LATER, m3, k3));
    assert!(s == vec![30.0, 10.0, 4.0, 133.0, 60.0]);
    assert!((m1 + 3.4).abs() < 1e-12 && (k1 - 23.5).abs() < 1e-12 && (sse - 0.2).abs() < 1e-12
        && left.iter().zip(&MISSES).all(|(r, t)| (r - t).abs() < 1e-12));
    assert!((m1 - m2).abs() < 1e-12 && (k1 - k2).abs() < 1e-12
        && dot_age.abs() < 1e-12 && dot_one.abs() < 1e-12);
    assert!(sse < ssef && ssef < sse5 && sse5 < sse0
        && (m3 + 4.2).abs() < 1e-12 && (k3 - 25.5).abs() < 1e-12);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-19 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
ages, in years                          1.00    2.00    3.00    4.00
prices, in $ thousands                 20.00   17.00   13.00   10.00
A^T A, first row                       30.00   10.00
A^T A, second row                      10.00    4.00
A^T b                                 133.00   60.00
road 1, the normal equations        slope  -3.4000   intercept  23.5000
road 2, from the two means          slope  -3.4000   intercept  23.5000
fitted prices, in $ thousands          20.10   16.70   13.30    9.90
misses, price minus fitted price       -0.10    0.30   -0.30    0.10
total squared miss                            0.2000
leftover dot ages column              0.000000000000
leftover dot ones column              0.000000000000
wrong, no ones column: slope 4.4333, squared miss 368.3667
wrong, first and last car only: slope -3.3333, squared miss 0.2222
wrong, misses added not squared: fitted line 0.0000, the -5.0 line 0.0000, whose squared miss is 13.0000
second case, prices 21, 18, 12, 9: slope -4.2000, intercept 25.5000, squared miss 1.8000
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves the card's main facts for any number of cars, and checks the four cars' numbers as exact fractions.

- Any table $A$, any prices $b$: a choice $x$ misses least exactly when it solves $A^T A x = A^T b$.
- Squared lengths add, by Pythagoras. Any other choice scores the best squared miss plus the squared gap between the two sets of predictions.
- When the ages differ, exactly one line misses least. Its slope and intercept are the cross-multiplied formulas in the worked table.
- The four cars: $A^T A$ = `[[30, 10], [10, 4]]`, $A^T b$ = (133, 60), determinant 20, slope −3.4, intercept 23.5.
- The fitted prices, the leftovers, their zero dot products with both columns, and the squared miss 0.2.
- The other road, the three mistakes, the second lot of prices, and the zero determinant when every car is aged 2.

The printed decimals, and running both roads in code, are left to the Python and Rust checks.

```lean
-- Least squares: a choice of coefficients makes the total squared miss as small as possible exactly when it solves the normal equations A^T A x = A^T b, the squared miss of any other choice is the best one plus a Pythagoras term, and when the ages are not all equal the best straight line is unique and given by the card's cross-multiplied formulas, with the card's four used cars checked exactly.
import Mathlib.Data.Matrix.Mul
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Basic.Real.Basic
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.NormNum
import Mathlib

open Matrix

/-! The prices are one column `b : Fin n → ℝ`, one entry per car. The design matrix `A` has one
row per car and one column per unknown (`p` columns; for a line, `p = 2`: the age, then a 1).
`A *ᵥ x` is `A` times the column `x`, which rebuilds the predicted prices, and `Aᵀ` is `A`
transposed. The total squared miss of a choice `x` is the leftover `b - A *ᵥ x` dotted with
itself, `(b - A *ᵥ x) ⬝ᵥ (b - A *ᵥ x)`. -/

/-- Helper: a real vector dotted with itself is never negative. -/
theorem ls_dot_self_nonneg {n : ℕ} (v : Fin n → ℝ) : 0 ≤ v ⬝ᵥ v :=
  Finset.sum_nonneg fun i _ => mul_self_nonneg (v i)

/-- Helper: the expansion of the squared miss of `y` around `x`. -/
theorem ls_expand {n p : ℕ} (A : Matrix (Fin n) (Fin p) ℝ) (b : Fin n → ℝ) (x y : Fin p → ℝ) :
    (b - A *ᵥ y) ⬝ᵥ (b - A *ᵥ y) =
      (b - A *ᵥ x) ⬝ᵥ (b - A *ᵥ x) - 2 * ((Aᵀ *ᵥ b - (Aᵀ * A) *ᵥ x) ⬝ᵥ (y - x)) +
        (A *ᵥ (y - x)) ⬝ᵥ (A *ᵥ (y - x)) := by
  have h1 : b - A *ᵥ y = (b - A *ᵥ x) - A *ᵥ (y - x) := by
    rw [mulVec_sub]; abel
  have h2 : (b - A *ᵥ x) ⬝ᵥ (A *ᵥ (y - x)) = (Aᵀ *ᵥ b - (Aᵀ * A) *ᵥ x) ⬝ᵥ (y - x) := by
    rw [dotProduct_mulVec, ← mulVec_mulVec, ← mulVec_sub, mulVec_transpose]
  rw [h1, ← h2]
  generalize b - A *ᵥ x = u
  generalize A *ᵥ (y - x) = v
  simp only [sub_dotProduct, dotProduct_sub, dotProduct_comm v u]
  ring

/-- Helper: if `0 ≤ -2 t G + t² c` for every real `t`, with `0 ≤ G` and `0 ≤ c`, then `G = 0`. -/
theorem ls_quad_zero (G c : ℝ) (hG : 0 ≤ G) (hc : 0 ≤ c)
    (h : ∀ t : ℝ, 0 ≤ -2 * t * G + t ^ 2 * c) : G = 0 := by
  have hc1 : 0 < c + 1 := by linarith
  have ht := h (G / (c + 1))
  have key : 0 ≤ (c + 1) ^ 2 * (-2 * (G / (c + 1)) * G + (G / (c + 1)) ^ 2 * c) :=
    mul_nonneg (by positivity) ht
  have e : (c + 1) ^ 2 * (-2 * (G / (c + 1)) * G + (G / (c + 1)) ^ 2 * c) = -(G ^ 2 * (c + 2)) := by
    field_simp; ring
  rw [e] at key
  have : G ^ 2 * (c + 2) ≤ 0 := by linarith
  have hG2 : G ^ 2 ≤ 0 := by
    by_contra hneg
    rw [not_le] at hneg
    have : 0 < G ^ 2 * (c + 2) := mul_pos hneg (by linarith)
    linarith
  nlinarith

/-- Helper: the expansion of the squared miss of a line `(m', k')` around `(m, k)`. -/
theorem ls_line_expand {n : ℕ} (age price : Fin n → ℝ) (m k m' k' : ℝ) :
    ∑ i, (price i - (m' * age i + k')) ^ 2 =
      ∑ i, (price i - (m * age i + k)) ^ 2
        - 2 * ((m' - m) * ∑ i, age i * (price i - (m * age i + k))
            + (k' - k) * ∑ i, (price i - (m * age i + k)))
        + ∑ i, ((m' - m) * age i + (k' - k)) ^ 2 := by
  rw [Finset.mul_sum, Finset.mul_sum, ← Finset.sum_add_distrib, Finset.mul_sum,
    ← Finset.sum_sub_distrib, ← Finset.sum_add_distrib]
  refine Finset.sum_congr rfl fun i _ => ?_
  ring

/-- Helper: `n Σ a² − (Σ a)²` is half the sum of all squared differences. -/
theorem ls_det_eq {n : ℕ} (age : Fin n → ℝ) :
    2 * ((n : ℝ) * ∑ i, age i ^ 2 - (∑ i, age i) ^ 2) = ∑ i, ∑ j, (age i - age j) ^ 2 := by
  have e : ∀ i j, (age i - age j) ^ 2 = age i ^ 2 + age j ^ 2 - 2 * (age i * age j) := by
    intro i j; ring
  simp only [e, Finset.sum_sub_distrib, Finset.sum_add_distrib, ← Finset.mul_sum,
    ← Finset.sum_mul, Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul]
  ring

theorem ls_det_pos {n : ℕ} (age : Fin n → ℝ) (h : ∃ i j, age i ≠ age j) :
    0 < (n : ℝ) * ∑ i, age i ^ 2 - (∑ i, age i) ^ 2 := by
  obtain ⟨i, j, hij⟩ := h
  have hpos : 0 < (age i - age j) ^ 2 := by
    have : age i - age j ≠ 0 := sub_ne_zero.mpr hij
    positivity
  have h1 : (age i - age j) ^ 2 ≤ ∑ j', (age i - age j') ^ 2 :=
    Finset.single_le_sum (f := fun j' => (age i - age j') ^ 2) (fun _ _ => sq_nonneg _)
      (Finset.mem_univ j)
  have h2 : ∑ j', (age i - age j') ^ 2 ≤ ∑ i', ∑ j', (age i' - age j') ^ 2 :=
    Finset.single_le_sum (f := fun i' => ∑ j', (age i' - age j') ^ 2)
      (fun _ _ => Finset.sum_nonneg fun _ _ => sq_nonneg _) (Finset.mem_univ i)
  have := ls_det_eq age
  linarith

/-- Least squares is the normal equations. For any table `A` (any number of rows and columns)
and any prices `b`, a choice `x` scores the smallest total squared miss of every possible choice
exactly when it solves `Aᵀ A x = Aᵀ b`, that is, exactly when the leftover `b - A x` is
perpendicular to every column of `A`. -/
theorem least_squares_iff_normal_equations {n p : ℕ} (A : Matrix (Fin n) (Fin p) ℝ)
    (b : Fin n → ℝ) (x : Fin p → ℝ) :
    (∀ y : Fin p → ℝ, (b - A *ᵥ x) ⬝ᵥ (b - A *ᵥ x) ≤ (b - A *ᵥ y) ⬝ᵥ (b - A *ᵥ y)) ↔
      (Aᵀ * A) *ᵥ x = Aᵀ *ᵥ b := by
  constructor
  · intro hmin
    set g := Aᵀ *ᵥ b - (Aᵀ * A) *ᵥ x with hg
    have hG : g ⬝ᵥ g = 0 := by
      apply ls_quad_zero (g ⬝ᵥ g) ((A *ᵥ g) ⬝ᵥ (A *ᵥ g)) (ls_dot_self_nonneg g)
        (ls_dot_self_nonneg _)
      intro t
      have hy := hmin (x + t • g)
      rw [ls_expand A b x (x + t • g)] at hy
      have hd : x + t • g - x = t • g := by abel
      rw [hd, mulVec_smul, dotProduct_smul, smul_dotProduct, dotProduct_smul, smul_eq_mul,
        smul_eq_mul, smul_eq_mul] at hy
      rw [← hg] at hy
      nlinarith
    have : g = 0 := dotProduct_self_eq_zero.mp hG
    rw [hg] at this
    exact (sub_eq_zero.mp this).symm
  · intro hx y
    rw [ls_expand A b x y, hx, sub_self, zero_dotProduct, mul_zero, sub_zero]
    have := ls_dot_self_nonneg (A *ᵥ (y - x))
    linarith

/-- Squared lengths add, by Pythagoras. If `x` solves the normal equations, then for every other
choice `y` the total squared miss of `y` is the best total squared miss plus the squared length
of `A (y - x)`, the gap between the two sets of predictions. -/
theorem squared_miss_splits_by_pythagoras {n p : ℕ} (A : Matrix (Fin n) (Fin p) ℝ)
    (b : Fin n → ℝ) (x : Fin p → ℝ) (hx : (Aᵀ * A) *ᵥ x = Aᵀ *ᵥ b) (y : Fin p → ℝ) :
    (b - A *ᵥ y) ⬝ᵥ (b - A *ᵥ y) =
      (b - A *ᵥ x) ⬝ᵥ (b - A *ᵥ x) + (A *ᵥ (y - x)) ⬝ᵥ (A *ᵥ (y - x)) := by
  rw [ls_expand A b x y, hx, sub_self, zero_dotProduct, mul_zero, sub_zero]

/-- The best-fit line, in one step. Take `n` cars with ages `age i` and prices `price i`, and
suppose the ages are not all equal. Then a line price = slope × age + intercept has the smallest
total squared miss of all lines exactly when
slope = (n × Σ age·price − Σ age × Σ price) / (n × Σ age² − (Σ age)²) and
intercept = (Σ age² × Σ price − Σ age × Σ age·price) / (n × Σ age² − (Σ age)²).
So the best line exists, is unique, and is the cross-multiplied answer of the normal
equations. -/
theorem best_fit_line_unique_when_ages_differ {n : ℕ} (age price : Fin n → ℝ)
    (h : ∃ i j, age i ≠ age j) (m k : ℝ) :
    (∀ m' k' : ℝ, ∑ i, (price i - (m * age i + k)) ^ 2 ≤ ∑ i, (price i - (m' * age i + k')) ^ 2) ↔
      (m = ((n : ℝ) * ∑ i, age i * price i - (∑ i, age i) * ∑ i, price i) /
            ((n : ℝ) * ∑ i, age i ^ 2 - (∑ i, age i) ^ 2) ∧
        k = ((∑ i, age i ^ 2) * ∑ i, price i - (∑ i, age i) * ∑ i, age i * price i) /
            ((n : ℝ) * ∑ i, age i ^ 2 - (∑ i, age i) ^ 2)) := by
  have hD := ls_det_pos age h
  have hD0 := hD.ne'
  set E1 := ∑ i, age i * (price i - (m * age i + k)) with hE1
  set E0 := ∑ i, (price i - (m * age i + k)) with hE0
  clear_value E1 E0
  have hE1' : E1 = ∑ i, age i * price i - m * ∑ i, age i ^ 2 - k * ∑ i, age i := by
    rw [hE1, Finset.mul_sum, Finset.mul_sum, ← Finset.sum_sub_distrib, ← Finset.sum_sub_distrib]
    exact Finset.sum_congr rfl fun i _ => by ring
  have hE0' : E0 = ∑ i, price i - m * ∑ i, age i - k * n := by
    rw [hE0, Finset.mul_sum, ← Finset.sum_sub_distrib]
    simp only [Finset.sum_sub_distrib, Finset.sum_add_distrib, Finset.sum_const,
      Finset.card_univ, Fintype.card_fin, nsmul_eq_mul]
    ring
  have step : (∀ m' k' : ℝ, ∑ i, (price i - (m * age i + k)) ^ 2 ≤
      ∑ i, (price i - (m' * age i + k')) ^ 2) ↔ (E1 = 0 ∧ E0 = 0) := by
    constructor
    · intro hmin
      have hz : E1 ^ 2 + E0 ^ 2 = 0 := by
        apply ls_quad_zero (E1 ^ 2 + E0 ^ 2) (∑ i, (E1 * age i + E0) ^ 2) (by positivity)
          (Finset.sum_nonneg fun _ _ => sq_nonneg _)
        intro t
        have hy := hmin (m + t * E1) (k + t * E0)
        rw [ls_line_expand age price m k (m + t * E1) (k + t * E0)] at hy
        have e1 : m + t * E1 - m = t * E1 := by ring
        have e2 : k + t * E0 - k = t * E0 := by ring
        rw [e1, e2] at hy
        have e3 : ∑ i, (t * E1 * age i + t * E0) ^ 2 = t ^ 2 * ∑ i, (E1 * age i + E0) ^ 2 := by
          rw [Finset.mul_sum]; exact Finset.sum_congr rfl fun i _ => by ring
        rw [e3, ← hE1, ← hE0] at hy
        nlinarith
      constructor <;> nlinarith [sq_nonneg E1, sq_nonneg E0]
    · rintro ⟨h1, h0⟩ m' k'
      rw [ls_line_expand age price m k m' k', ← hE1, ← hE0, h1, h0]
      have := Finset.sum_nonneg (s := Finset.univ)
        (fun i _ => sq_nonneg ((m' - m) * age i + (k' - k)))
      linarith
  rw [step, hE1', hE0']
  constructor
  · rintro ⟨h1, h0⟩
    constructor
    · rw [eq_div_iff hD0]; linear_combination (-(n : ℝ)) * h1 + (∑ i, age i) * h0
    · rw [eq_div_iff hD0]; linear_combination (-(∑ i, age i ^ 2)) * h0 + (∑ i, age i) * h1
  · rintro ⟨hm, hk⟩
    rw [eq_div_iff hD0] at hm hk
    constructor
    · apply mul_left_cancel₀ hD0
      linear_combination (-(∑ i, age i ^ 2)) * hm - (∑ i, age i) * hk
    · apply mul_left_cancel₀ hD0
      linear_combination (-(∑ i, age i)) * hm - (n : ℝ) * hk

-- The four cars: A = [[1, 1], [2, 1], [3, 1], [4, 1]], prices b = (20, 17, 13, 10) in thousands.
-- A^T A = [[30, 10], [10, 4]] and A^T b = (133, 60).
example : (!![(1 : ℚ), 1; 2, 1; 3, 1; 4, 1])ᵀ * !![(1 : ℚ), 1; 2, 1; 3, 1; 4, 1] =
    !![30, 10; 10, 4] := by
  ext i j; fin_cases i <;> fin_cases j <;>
    norm_num [Matrix.mul_apply, Fin.sum_univ_four, Matrix.transpose_apply]
example : (!![(1 : ℚ), 1; 2, 1; 3, 1; 4, 1])ᵀ *ᵥ ![20, 17, 13, 10] = ![133, 60] := by
  ext i; fin_cases i <;>
    norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_four, Matrix.transpose_apply]
-- Determinant 30 × 4 − 10 × 10 = 20.
example : Matrix.det !![(30 : ℚ), 10; 10, 4] = 20 := by norm_num [Matrix.det_fin_two_of]
-- Slope (133 × 4 − 10 × 60) / 20 = −17/5 (the card's −3.4);
-- intercept (30 × 60 − 10 × 133) / 20 = 47/2 (the card's 23.5).
example : ((133 : ℚ) * 4 - 10 * 60) / 20 = -17/5 ∧ ((30 : ℚ) * 60 - 10 * 133) / 20 = 47/2 := by
  norm_num
-- (−17/5, 47/2) solves the normal equations: 30 m + 10 k = 133 and 10 m + 4 k = 60.
example : !![(30 : ℚ), 10; 10, 4] *ᵥ ![-17/5, 47/2] = ![133, 60] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
-- Fitted prices 20.1, 16.7, 13.3, 9.9, written exactly.
example : !![(1 : ℚ), 1; 2, 1; 3, 1; 4, 1] *ᵥ ![-17/5, 47/2] = ![201/10, 167/10, 133/10, 99/10] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
-- Leftovers −0.1, 0.3, −0.3, 0.1, dotted with both columns give 0, and their squares add to 0.2.
example : (![-1/10, 3/10, -3/10, 1/10] : Fin 4 → ℚ) ⬝ᵥ ![1, 2, 3, 4] = 0 ∧
    (![-1/10, 3/10, -3/10, 1/10] : Fin 4 → ℚ) ⬝ᵥ ![1, 1, 1, 1] = 0 := by
  norm_num [dotProduct, Fin.sum_univ_four]
example : ∑ i : Fin 4, ((![20, 17, 13, 10] : Fin 4 → ℚ) i -
    (-17/5 * (![1, 2, 3, 4] : Fin 4 → ℚ) i + 47/2)) ^ 2 = 1/5 := by
  norm_num [Fin.sum_univ_four]
-- The other road: average age 5/2, average price 15; Σ (age − 5/2)(price − 15) = −17,
-- Σ (age − 5/2)² = 5, slope −17/5, intercept 15 + 17/2 = 47/2.
example : ∑ i : Fin 4, ((![1, 2, 3, 4] : Fin 4 → ℚ) i - 5/2) *
    ((![20, 17, 13, 10] : Fin 4 → ℚ) i - 15) = -17 ∧
    ∑ i : Fin 4, ((![1, 2, 3, 4] : Fin 4 → ℚ) i - 5/2) ^ 2 = 5 ∧
    (15 : ℚ) - (-17/5) * (5/2) = 47/2 := by
  norm_num [Fin.sum_univ_four]
-- Mistake 1, no column of ones: slope 133/30 (4.4333), squared miss 11051/30 (368.3667).
example : ∑ i : Fin 4, ((![20, 17, 13, 10] : Fin 4 → ℚ) i -
    133/30 * (![1, 2, 3, 4] : Fin 4 → ℚ) i) ^ 2 = 11051/30 := by
  norm_num [Fin.sum_univ_four]
-- Mistake 2, first and last car only: slope −10/3 (−3.3333), squared miss 2/9 (0.2222).
example : ∑ i : Fin 4, ((![20, 17, 13, 10] : Fin 4 → ℚ) i -
    (-10/3 * (![1, 2, 3, 4] : Fin 4 → ℚ) i + 70/3)) ^ 2 = 2/9 := by
  norm_num [Fin.sum_univ_four]
-- Mistake 3, adding misses without squaring: price = 27.5 − 5 × age also sums to 0,
-- but its squared miss is 13.
example : ∑ i : Fin 4, ((![20, 17, 13, 10] : Fin 4 → ℚ) i -
    (-5 * (![1, 2, 3, 4] : Fin 4 → ℚ) i + 55/2)) = 0 ∧
    ∑ i : Fin 4, ((![20, 17, 13, 10] : Fin 4 → ℚ) i -
    (-5 * (![1, 2, 3, 4] : Fin 4 → ℚ) i + 55/2)) ^ 2 = 13 := by
  norm_num [Fin.sum_univ_four]
-- Second lot, prices 21, 18, 12, 9: A^T b = (129, 60), slope −21/5, intercept 51/2,
-- squared miss 9/5 (1.8).
example : !![(30 : ℚ), 10; 10, 4] *ᵥ ![-21/5, 51/2] = ![129, 60] ∧
    (!![(1 : ℚ), 1; 2, 1; 3, 1; 4, 1])ᵀ *ᵥ ![21, 18, 12, 9] = ![129, 60] := by
  constructor <;> ext i <;> fin_cases i <;>
    norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two, Fin.sum_univ_four,
      Matrix.transpose_apply]
example : ∑ i : Fin 4, ((![21, 18, 12, 9] : Fin 4 → ℚ) i -
    (-21/5 * (![1, 2, 3, 4] : Fin 4 → ℚ) i + 51/2)) ^ 2 = 9/5 := by
  norm_num [Fin.sum_univ_four]
-- Every car aged 2: A^T A = [[16, 8], [8, 4]], determinant 16 × 4 − 8 × 8 = 0, no unique line.
example : Matrix.det !![(16 : ℚ), 8; 8, 4] = 0 := by norm_num [Matrix.det_fin_two_of]

#print axioms ls_dot_self_nonneg
#print axioms ls_expand
#print axioms ls_quad_zero
#print axioms ls_line_expand
#print axioms ls_det_eq
#print axioms ls_det_pos
#print axioms least_squares_iff_normal_equations
#print axioms squared_miss_splits_by_pythagoras
#print axioms best_fit_line_unique_when_ages_differ
```

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'ls_dot_self_nonneg' depends on axioms: [propext, Classical.choice, Quot.sound]
'ls_expand' depends on axioms: [propext, Classical.choice, Quot.sound]
'ls_quad_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'ls_line_expand' depends on axioms: [propext, Classical.choice, Quot.sound]
'ls_det_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'ls_det_pos' depends on axioms: [propext, Classical.choice, Quot.sound]
'least_squares_iff_normal_equations' depends on axioms: [propext, Classical.choice, Quot.sound]
'squared_miss_splits_by_pythagoras' depends on axioms: [propext, Classical.choice, Quot.sound]
'best_fit_line_unique_when_ages_differ' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it; the asserts are pinned to the four cars.
> - **Nudge the prices.** Set `PRICES` to `[21.0, 18.0, 12.0, 9.0]`: slope −4.2000, intercept 25.5000, squared miss 1.8000. Those prices bend more than a line can follow.
> - **Give every car the same age.** Set `AGES` to `[2.0, 2.0, 2.0, 2.0]`: the determinant is zero, so Python stops on a division by zero and Rust returns NaN, "not a number".
> - **Stop squaring.** In `squared_miss`, drop the square: the fitted line scores 0.0000, and so does the line whose squared miss is 13.0000.

---

## The usual mistake

> [!warning]
> **Thinking the projection happens on the page.** It is tempting to picture each dot dropped at right angles onto the drawn line. That is not this. The projection happens in the space with one axis per car, where the prices are one point and every drawable line a point of a flat sheet; on the page, the misses run straight up and down.
>
> - **Trusting a score that cancels.** The leftovers add to 0.0000, and so do those of price = 27.5 − 5 × age, whose squared miss is 13.0000. Square first, then add.
> - **Forgetting the column of ones.** Leave it out and the fit is told a new car is free: slope 4.4333, squared miss 368.3667.
> - **Reading the line outside its range.** These cars are one to four years old; age 8 returns a negative price, unflagged.

---

## Where you meet it in real life

- **Every straight trendline in a spreadsheet.** `SLOPE`, `INTERCEPT` and `LINEST` answer these normal equations, by a steadier route than building the small matrix $A^T A$; any table of ages and prices is a depreciation schedule fitted this way.
- **Calibrating an instrument.** Weigh known masses on a new scale, fit a line to what it reports, then read it backwards to correct later readings.
- **More columns, same equation.** Add mileage: $A$ becomes 4 × 3, $A^T A$ becomes 3 × 3, every word above holds. That is "regression" in most reports.
- **Columns already perpendicular.** Perpendicular columns of length 1 make the small matrix the identity (1s on the diagonal, 0s elsewhere), and the answer is two dot products ([Gram-Schmidt](03-gram-schmidt-and-orthonormal-bases.md)).

> **Say it back**
> No line hits all four prices, so the question becomes which line misses least. Stack the ages and a column of ones into $A$, the slope and intercept into $x$, the prices into $b$: the wish $A x = b$ has no answer. Read the prices as one point in a space with an axis per car, the drawable lines as a flat sheet: the fit is the shadow, so the leftover is perpendicular to both columns. Written down, that is $A^T A x = A^T b$ — price = 23.5 − 3.4 × age, squared miss 0.2.

---

## What this builds on

- [Projection](02-orthogonal-projection.md): the shadow and its perpendicular leftover, here with two columns.
- [Matrix multiplication](../04-Matrices/03-matrix-multiplication.md): how $A x$ turns two unknowns into four predictions.
- [The inverse matrix](../05-Solving%20Systems/03-inverse-matrix.md): solving the small square system, and the determinant behind it.
- [Percentages](../../01-Foundations/01-Everyday%20Arithmetic/10-percentages.md): judging a miss. 0.3 on a car worth 13 is small; on a car worth 1 it is not.

## Where this goes next

- [Least squares](../../09-Probability%20and%20statistics/09-Regression/01-least-squares-regression.md): the same line with noise assumed, so the slope gets an error bar.
- [Multiple regression](../../09-Probability%20and%20statistics/09-Regression/03-multiple-regression-and-gauss-markov.md): many columns, and why no unbiased rival beats this fit.
- [L2 as a Hilbert space](../../10-Measure%20and%20integration/07-Sizes%20of%20Functions/06-l2-as-a-hilbert-space.md): the same geometry with functions as the arrows.
- [Conditional expectation as a projection](../../10-Measure%20and%20integration/09-Conditional%20Expectation/03-conditional-expectation-as-projection.md): a forecast as the shadow of a random quantity.
- [The SVI smile](../../12-Financial%20mathematics/12-The%20smile%20and%20the%20surface/04-svi-smile-fit.md): squared misses minimised against traded option prices.
- [A spot price that reverts](../../12-Financial%20mathematics/25-Commodity%20forwards%20-%20carry%2C%20storage%2C%20convenience%20yield%20and%20the%20curve/06-mean-reverting-spot-and-the-futures-curve.md): a pull-back speed fitted from price history.
- [Wiener and LMS](../../13-Engineering%20mathematics/05-Signals/07-adaptive-and-optimal-filters.md): these equations re-solved as each reading arrives.
- [Least squares two ways](../../16-Numerical%20analysis/03-Numerical%20Linear%20Algebra/06-least-squares-normal-equations-versus-qr.md): why software never forms $A^T A$.
- [Fitting instead of passing through](../../16-Numerical%20analysis/04-Interpolation%20and%20Approximation/07-least-squares-and-orthogonal-polynomials.md): perpendicular columns, so curves fit without the small matrix.

Nothing here says how far to trust −3.4, and that question opens [Least squares](../../09-Probability%20and%20statistics/09-Regression/01-least-squares-regression.md).

---

## Sources

Verified 19 Sep 2026: every link below resolves to the publisher's page.

- Stigler, Stephen M. "Gauss and the Invention of Least Squares." *The Annals of Statistics* 9, no. 3 (1981): 465–474. [doi:10.1214/aos/1176345451](https://doi.org/10.1214/aos/1176345451). Legendre published in 1805; Gauss said he had used it since 1795.
- Strang, Gilbert. "Lecture 16: Projection matrices and least squares." *18.06 Linear Algebra*, Spring 2010. MIT OpenCourseWare. [Lecture page](https://ocw.mit.edu/courses/18-06-linear-algebra-spring-2010/resources/lecture-16-projection-matrices-and-least-squares/). Projection first, then least squares, with this picture.
- *Introductory Statistics 2e*, section 12.3, "The Regression Equation." OpenStax, Rice University. [Textbook page](https://openstax.org/books/introductory-statistics-2e/pages/12-3-the-regression-equation). The second road, as statistics teaches it.
- Björck, Åke. *Numerical Methods in Matrix Computations*. Springer, 2015. [Publisher page](https://link.springer.com/book/10.1007/978-3-319-05089-8). Why working software uses QR, which splits $A$ into perpendicular columns times a triangle of numbers, instead of building the small matrix.
