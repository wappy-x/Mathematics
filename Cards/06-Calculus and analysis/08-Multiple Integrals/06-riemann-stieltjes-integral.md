# Stieltjes integrals: integrating against a weight that can jump

[Syllabus](../../../SYLLABUS.md) → [Calculus and analysis](../README.md) → [Multiple Integrals](../README.md#s08) → Stieltjes integrals

---

## General Overview

An insurer holds 1,000 contracts for the year. 400 pay nothing. 500 pay amounts spread evenly between $0 and $100. 100 hit the policy cap and pay exactly $100. What does one contract pay on average?

Counting answers it: 500 × $50 + 100 × $100 = $35,000 in total, $35 per contract. The interest is in the list's shape. The middle is a smooth spread, which an ordinary integral handles. The ends are lumps: many contracts on one payout, and a lump has no width for an integral to use.

Thomas Stieltjes's fix, from 1894, keeps the thin slices but measures each by how much of the book (the 1,000 contracts) it holds. That share is read off a running total: the share of contracts paying at most a given amount.

The running total climbs across the spread, jumps at a lump and never falls: it is nondecreasing. From here on the running total is the **integrator**, and the share a slice holds is its **weight**.

**A Stieltjes integral adds value times weight, where a slice's weight is how far a nondecreasing running total rises across it; a steady rise gives an ordinary integral and a jump gives a single term.**

**What kind of fact this is:** a definition; that it exists for every continuous value against every nondecreasing integrator is a theorem, proved on this card in Why it works.

### The picture: the running share of the book

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Share of the 1,000 contracts paying at most x dollars"
    x-axis "Payout x, in dollars" ["-20", "-10", "just below 0", "0", "20", "40", "60", "80", "just below 100", "100"]
    y-axis "Share of contracts, from 0 to 1" 0 --> 1
    line [0, 0, 0, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1]
```

The line is the integrator: a leap of 0.40 at $0 (the zero-payers), a steady climb to 0.90, a leap of 0.10 at the cap. The axis is not to scale; each "just below" point sits a hair left of its leap.

---

## The formula

Notation first, in words. The integral of f against G is written with the stretched S and dG where dx used to be: the rises of G, not widths, supply the weights. It is read "the integral of f with respect to G".

Write $G$ for the integrator and $f$ for the value being averaged, here the payout itself, f(x) = x. Cut the interval from a to b at points $a = x_0 < x_1 < \dots < x_n = b$. Slice k runs from $x_{k-1}$ to $x_k$, and its weight is how far G rises across it:

$$\Delta G_k = G(x_k) - G(x_{k-1})$$

Pick any point $\xi_k$ in slice k, its **tag**. A **Stieltjes sum** $S$ adds value at the tag times weight; the integral is where these sums settle as the widest slice shrinks, whatever the tags:

$$\int_a^b f(x)\,dG(x) = \lim_{\text{widest slice} \to 0}\ \sum_{k=1}^{n} f(\xi_k)\,\bigl(G(x_k) - G(x_{k-1})\bigr)$$

**Read it aloud:** weigh each thin slice by how much the integrator climbs across it, multiply by the value there, add, and see where the total settles.

When G is a steady rise plus a few jumps, this becomes a working formula. $G'$ is the rate of G (its derivative) where it climbs smoothly; a jump of size $w_j$ sits at $c_j$:

$$\int_a^b f\,dG = \int_a^b f(x)\,G'(x)\,dx + \sum_j w_j\,f(c_j)$$

**Read it aloud:** the smooth part is an ordinary integral with G's rate as a density; each jump adds its size times the value there.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $f$ | the value being averaged | the payout x | scales the average |
| $G$ | the integrator: a running total that never falls | share paying at most x | a later rise raises it |
| $x$, $a$, $b$ | the variable; the interval's ends | dollars; −20 and 100 | — |
| $n$, $k$, $x_k$ | slice count, a slice's counter, its right cut | 12 slices of $10 | tighter bracket |
| $\Delta G_k$ | weight of slice k: G's rise across it | 0.40 on the slice ending at $0 | — |
| $\xi_k$, $S$, $L$, $U$ | a tag; its sum; lowest and highest sums | L = 27.50, U = 37.50 at 12 slices | — |
| $G'$ | rate of G where it climbs smoothly | 0.005 per dollar | more contracts in the spread |
| $w_j$, $c_j$, $j$ | size and place of jump j; its counter | 0.40 at $0, 0.10 at $100 | a bigger cap lump raises it |

Units: dollars per contract. The total weight G(b) − G(a) is 1.00, the whole book, so the integral is the average.

### When it holds

- **A continuous value.** Continuity of f suffices. Drop it where G jumps and the sums split: a $1 fee on each contract that pays something jumps at $0, as G does. With 125 slices, left tags give 0.5992 and right tags 1.0000, and finer grids keep the split.
- **An integrator that never falls.** The bracket in Why it works needs weights of zero or more. Integrators that also fall need bounded variation, a finite total of rises and falls: [Bounded variation](../../10-Measure%20and%20integration/11-Derivatives%20Meet%20the%20Lebesgue%20Integral/01-functions-of-bounded-variation.md).
- **A jump counts only inside the interval.** G(0) already includes the zero-payers, so starting at a = 0 would hide that jump; hence the start at −20.
- **The working formula needs a rate.** G must climb at a continuous rate between finitely many jumps.

---

## Why it works

### Step 0: weight replaces width

If G(x) = x, every weight is a width and the Stieltjes sum is the rectangle sum of [The integral](../04-Integrals/01-riemann-integral.md). That construction only needed weights that are nonnegative and add across neighbouring slices; any running total that never falls supplies them.

### Step 1: nonnegative weights give a bracket

Every weight is zero or more, so on each slice, lowest value times weight ≤ tag value times weight ≤ highest value times weight. Adding traps every Stieltjes sum between a lower sum L and an upper sum U. The payout rises with x, so L uses left ends and U right ends: with 12 slices of $10, L = 27.50 and U = 37.50.

An extra cut splits a slice's weight into pieces that add back to it, and each piece's lowest value is no lower than the slice's: L can only rise, U only fall. As on the Riemann card, every lower sum sits below every upper sum, and because the real numbers have no gaps, the lower sums have a least upper bound, sup L.

### Step 2: the gap closes

Slice by slice, U − L is (highest − lowest value) times weight, so the gap is at most the largest swing of f on one slice times the total weight G(b) − G(a).

For the payout the swing is the slice width and the total weight 1.00, so the gap is the width: 10.000, 1.000, 0.100 at 12, 120, 1200 slices. To land within $0.10, use 1200 slices.

For any continuous f the swings shrink together; that is uniform continuity ([Uniform continuity](../01-Limits%20and%20Continuity/08-uniform-continuity-and-lipschitz.md)). So the best lower and upper sums are equal, every tagged sum is squeezed onto them, and the integral exists.

### Step 3: a steady rise becomes an ordinary integral

Where G climbs at a continuous rate G', the fundamental theorem of calculus ([Fundamental theorem of calculus](../04-Integrals/02-fundamental-theorem-of-calculus.md)) makes each weight roughly G' times the width: the sum becomes a rectangle sum for f times G'. The spread holds 0.50 of the book over $100, so G' = 0.005 per dollar, and the smooth part is 0.005 × 100 × 100 / 2 = 25.00 dollars per contract.

### Step 4: a jump becomes one term

A jump of size w at c raises G on one slice only, the one straddling c. It contributes f(tag) × w, the tag within one slice width of c. As slices shrink, continuity of f at c sends the term to w × f(c): here 0.40 × $0 = 0 and 0.10 × $100 = 10.00.

### Step 5: add the parts

Stieltjes sums are additive in the integrator: split G into its steady part and its jumps, and every sum splits the same way. The integral is 25.00 + 0 + 10.00 = 35.00 dollars per contract, as counting gave.

<details>
<summary>Detailed proof</summary>

Let f be continuous on [a, b] and G nondecreasing. Given ε > 0, uniform continuity gives δ > 0 with |f(s) − f(t)| < ε whenever |s − t| < δ. Take a partition with widest slice under δ, and let m_k, M_k be the least and greatest values of f on slice k. Then
U − L = Σ (M_k − m_k) ΔG_k ≤ ε Σ ΔG_k = ε (G(b) − G(a)).
By Step 1 every L is at most every U; let I = sup L. Then I and every tagged sum S lie in [L, U], so |S − I| ≤ ε (G(b) − G(a)) for every partition finer than δ and every choice of tags.

Jump of size w at c, with a < c ≤ b: only the slice with x_{k−1} < c ≤ x_k has a rise, so S = w f(ξ_k) with |ξ_k − c| < δ, and |S − w f(c)| < w ε.

Steady part: if G has a continuous rate G' on [p, q], the mean value theorem gives ΔG_k = G'(η_k) Δx_k with η_k in slice k and Δx_k its width, so S differs from the rectangle sum of f G' by at most max|f| × (largest swing of G' on a slice) × (q − p), which tends to 0.

</details>

A second road: integration by parts ([Integration by parts](../04-Integrals/04-integration-by-parts.md)) holds for Stieltjes integrals too. It turns the average into the ordinary integral of 1 − G(x) from 0 to 100, the area above the running share: also 35.00.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| smooth part | 0.005 × 100 × 100 / 2 | 25.00 |
| jump at $0 | 0.40 × $0 | 0 |
| jump at the cap | 0.10 × $100 | 10.00 |
| average payout | 25.00 + 0 + 10.00 | **$35.00** |

Each contract costs $35 on average, $10 of it from the 100 capped contracts that a rate-only reading never sees.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Jumps dropped, G' only | $25.00 | The cap lump carries $10 of the average |
| Jumps dropped, divided by the smooth weight 0.50 | $50.00 | The zero-payers vanish from the head count |
| Width instead of weight: x dx from 0 to 100 | 5000.00 | Counts dollars, not contracts |
| A fee that jumps where G jumps | 0.5992 or 1.0000, by tag | No common limit; counting gives 0.6000 |

---

## Code, from first principles, and it actually runs

Nothing is imported. Four roads reach the average: the working formula; lower and upper Stieltjes sums, with the gap checked against width times total weight; the 1,000 contracts listed and averaged; and the area above G. The fee case puts $0 inside a slice and asserts the tags never agree.

### Python

```python
# Stieltjes integrals -- the check behind the card.  Standard library only.
# A book of 1,000 contracts: 400 pay $0, 500 pay amounts spread evenly over
# $0 to $100, and 100 pay the $100 cap.  G(x) is the share paying at most x.
# The average payout is the integral of x against G, reached by four roads.
A, B = -20.0, 100.0

def G(x):                               # the accumulator: right-continuous
    if x < 0: return 0.0
    if x < 100: return 0.4 + 0.005 * x  # lump 0.4 at zero, then a steady rise
    return 1.0                          # lump 0.1 at the cap

def pay(x): return x                    # the integrand: dollars paid

def rs_sum(f, n, tag):                  # Stieltjes sum on n equal slices of [A, B]
    h = (B - A) / n
    return sum(f(A + (k + tag) * h) * (G(A + (k + 1) * h) - G(A + k * h)) for k in range(n))

book = [0.0] * 400 + [(k + 0.5) * 0.2 for k in range(500)] + [100.0] * 100
smooth = 0.005 * 100 ** 2 / 2           # road 1: antiderivative of x times the rate G'
jumps = 0.4 * pay(0) + 0.1 * pay(100)   # road 1: each lump times the payout there
split = smooth + jumps
by_hand = sum(book) / len(book)         # road 3: average the 1,000 contracts one by one
m = 100000                              # road 4: area above G, by a midpoint sum
tail = sum(1 - G((k + 0.5) * 100 / m) for k in range(m)) * 100 / m

print(f"book: {book.count(0.0)} at $0, {sum(1 for p in book if 0 < p < 100)} spread between, {book.count(100.0)} at $100")
print(f"chart, G at -20 -10 0- 0 20 40 60 80 100- 100: " + " ".join(f"{G(x):.2f}" for x in (-20, -10, -1e-9, 0, 20, 40, 60, 80, 100 - 1e-9, 100)))
print(f"lumps: {G(0) - G(-1e-9):.2f} at $0, {G(100) - G(100 - 1e-9):.2f} at $100; rate between them {(G(60) - G(20)) / 40:.3f} per dollar")
print(f"total weight G(b) - G(a) = {G(B) - G(A):.2f}; contracts paying something: {sum(1 for p in book if p > 0)}")
print(f"road 1, split: smooth part {smooth:.2f} + lumps {jumps:.2f} = {split:.2f}")
for n in (12, 120, 1200):               # road 2: lower and upper sums close on it
    lo, hi = rs_sum(pay, n, 0.0), rs_sum(pay, n, 1.0)
    print(f"road 2, n = {n}: slice width {(B - A) / n:.2f}, lower {lo:.3f}, upper {hi:.3f}, gap {hi - lo:.3f}")
    assert lo <= split <= hi and abs((hi - lo) - (B - A) / n * (G(B) - G(A))) < 1e-9
print(f"road 3, contract by contract: {len(book)} contracts, total {sum(book):.2f}, average {by_hand:.2f}")
print(f"road 4, area above G from 0 to 100: {tail:.2f}")
assert abs(by_hand - split) < 1e-9      # the list agrees with the formula
assert abs(tail - split) < 1e-6         # the area agrees with the formula
print(f"mistake 1, lumps dropped: {smooth:.2f}")
print(f"mistake 2, lumps dropped, divided by smooth weight {G(100 - 1e-9) - G(0):.2f}: {smooth / (G(100 - 1e-9) - G(0)):.2f}")
print(f"mistake 3, width instead of weight, integral of x from 0 to 100: {100 ** 2 / 2:.2f}")

def fee(x): return 1.0 if x > 0 else 0.0   # $1 on each contract that pays something
for n in (125, 1250):                   # 0 falls inside a slice, not on a cut
    lo, hi = rs_sum(fee, n, 0.0), rs_sum(fee, n, 1.0)
    print(f"shared jump, n = {n}: left tags {lo:.4f}, right tags {hi:.4f}")
    assert hi - lo > 0.39               # the tags never agree: no integral
print(f"fee by counting contracts: {sum(1 for p in book if p > 0) / len(book):.4f} per contract")
print("ALL CHECKS PASS")
```

**Ran 2026-09-27 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
book: 400 at $0, 500 spread between, 100 at $100
chart, G at -20 -10 0- 0 20 40 60 80 100- 100: 0.00 0.00 0.00 0.40 0.50 0.60 0.70 0.80 0.90 1.00
lumps: 0.40 at $0, 0.10 at $100; rate between them 0.005 per dollar
total weight G(b) - G(a) = 1.00; contracts paying something: 600
road 1, split: smooth part 25.00 + lumps 10.00 = 35.00
road 2, n = 12: slice width 10.00, lower 27.500, upper 37.500, gap 10.000
road 2, n = 120: slice width 1.00, lower 34.250, upper 35.250, gap 1.000
road 2, n = 1200: slice width 0.10, lower 34.925, upper 35.025, gap 0.100
road 3, contract by contract: 1000 contracts, total 35000.00, average 35.00
road 4, area above G from 0 to 100: 35.00
mistake 1, lumps dropped: 25.00
mistake 2, lumps dropped, divided by smooth weight 0.50: 50.00
mistake 3, width instead of weight, integral of x from 0 to 100: 5000.00
shared jump, n = 125: left tags 0.5992, right tags 1.0000
shared jump, n = 1250: left tags 0.5997, right tags 1.0000
fee by counting contracts: 0.6000 per contract
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Stieltjes integrals -- the same check as the Python, in Rust, std only.
// A book of 1,000 contracts: 400 pay $0, 500 pay amounts spread evenly over
// $0 to $100, and 100 pay the $100 cap.  G(x) is the share paying at most x.
// The average payout is the integral of x against G, reached by four roads.
const A: f64 = -20.0;
const B: f64 = 100.0;

fn g(x: f64) -> f64 {
    // the accumulator: right-continuous, lump 0.4 at zero, lump 0.1 at the cap
    if x < 0.0 { 0.0 } else if x < 100.0 { 0.4 + 0.005 * x } else { 1.0 }
}

fn pay(x: f64) -> f64 { x }

fn fee(x: f64) -> f64 { if x > 0.0 { 1.0 } else { 0.0 } } // $1 if it pays something

fn rs_sum(f: fn(f64) -> f64, n: usize, tag: f64) -> f64 {
    // Stieltjes sum on n equal slices of [A, B], tag 0 = left end, 1 = right end
    let h = (B - A) / n as f64;
    (0..n).map(|k| {
        let (l, r) = (A + k as f64 * h, A + (k + 1) as f64 * h);
        f(A + (k as f64 + tag) * h) * (g(r) - g(l))
    }).sum()
}

fn main() {
    let mut book = vec![0.0f64; 400];
    book.extend((0..500).map(|k| (k as f64 + 0.5) * 0.2));
    book.extend(vec![100.0f64; 100]);
    let paying = book.iter().filter(|&&p| p > 0.0).count();
    let smooth = 0.005 * 100.0f64.powi(2) / 2.0; // road 1: antiderivative of x times G'
    let jumps = 0.4 * pay(0.0) + 0.1 * pay(100.0); // road 1: each lump times its payout
    let split = smooth + jumps;
    let total: f64 = book.iter().sum();
    let by_hand = total / book.len() as f64; // road 3: contract by contract
    let m = 100000;
    let tail: f64 = (0..m).map(|k| 1.0 - g((k as f64 + 0.5) * 100.0 / m as f64)).sum::<f64>() * 100.0 / m as f64;
    let pts = [-20.0, -10.0, -1e-9, 0.0, 20.0, 40.0, 60.0, 80.0, 100.0 - 1e-9, 100.0];
    let row: Vec<String> = pts.iter().map(|&x| format!("{:.2}", g(x))).collect();
    let spread = book.iter().filter(|&&p| p > 0.0 && p < 100.0).count();
    let (zeros, capped) = (book.iter().filter(|&&p| p == 0.0).count(), book.iter().filter(|&&p| p == 100.0).count());
    println!("book: {} at $0, {} spread between, {} at $100", zeros, spread, capped);
    println!("chart, G at -20 -10 0- 0 20 40 60 80 100- 100: {}", row.join(" "));
    println!("lumps: {:.2} at $0, {:.2} at $100; rate between them {:.3} per dollar",
        g(0.0) - g(-1e-9), g(100.0) - g(100.0 - 1e-9), (g(60.0) - g(20.0)) / 40.0);
    println!("total weight G(b) - G(a) = {:.2}; contracts paying something: {}", g(B) - g(A), paying);
    println!("road 1, split: smooth part {:.2} + lumps {:.2} = {:.2}", smooth, jumps, split);
    for n in [12usize, 120, 1200] {
        // road 2: lower and upper sums close on it
        let (lo, hi) = (rs_sum(pay, n, 0.0), rs_sum(pay, n, 1.0));
        let h = (B - A) / n as f64;
        println!("road 2, n = {}: slice width {:.2}, lower {:.3}, upper {:.3}, gap {:.3}", n, h, lo, hi, hi - lo);
        assert!(lo <= split && split <= hi && ((hi - lo) - h * (g(B) - g(A))).abs() < 1e-9);
    }
    println!("road 3, contract by contract: {} contracts, total {:.2}, average {:.2}", book.len(), total, by_hand);
    println!("road 4, area above G from 0 to 100: {:.2}", tail);
    assert!((by_hand - split).abs() < 1e-9); // the list agrees with the formula
    assert!((tail - split).abs() < 1e-6); // the area agrees with the formula
    println!("mistake 1, lumps dropped: {:.2}", smooth);
    let sw = g(100.0 - 1e-9) - g(0.0);
    println!("mistake 2, lumps dropped, divided by smooth weight {:.2}: {:.2}", sw, smooth / sw);
    println!("mistake 3, width instead of weight, integral of x from 0 to 100: {:.2}", 100.0f64.powi(2) / 2.0);
    for n in [125usize, 1250] {
        // 0 falls inside a slice, not on a cut
        let (lo, hi) = (rs_sum(fee, n, 0.0), rs_sum(fee, n, 1.0));
        println!("shared jump, n = {}: left tags {:.4}, right tags {:.4}", n, lo, hi);
        assert!(hi - lo > 0.39); // the tags never agree: no integral
    }
    println!("fee by counting contracts: {:.4} per contract", paying as f64 / book.len() as f64);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-27 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
book: 400 at $0, 500 spread between, 100 at $100
chart, G at -20 -10 0- 0 20 40 60 80 100- 100: 0.00 0.00 0.00 0.40 0.50 0.60 0.70 0.80 0.90 1.00
lumps: 0.40 at $0, 0.10 at $100; rate between them 0.005 per dollar
total weight G(b) - G(a) = 1.00; contracts paying something: 600
road 1, split: smooth part 25.00 + lumps 10.00 = 35.00
road 2, n = 12: slice width 10.00, lower 27.500, upper 37.500, gap 10.000
road 2, n = 120: slice width 1.00, lower 34.250, upper 35.250, gap 1.000
road 2, n = 1200: slice width 0.10, lower 34.925, upper 35.025, gap 0.100
road 3, contract by contract: 1000 contracts, total 35000.00, average 35.00
road 4, area above G from 0 to 100: 35.00
mistake 1, lumps dropped: 25.00
mistake 2, lumps dropped, divided by smooth weight 0.50: 50.00
mistake 3, width instead of weight, integral of x from 0 to 100: 5000.00
shared jump, n = 125: left tags 0.5992, right tags 1.0000
shared jump, n = 1250: left tags 0.5997, right tags 1.0000
fee by counting contracts: 0.6000 per contract
ALL CHECKS PASS
```

### Lean

Lean proves the existence theorem and the working formula in general, and the card's $35 average for the 1,000 contracts.

- Take a value that is continuous on the interval and an integrator that never falls there. The Stieltjes sums settle on one number as the widest slice shrinks, whatever the tags.
- Let an integrator that never falls be a steady rise at a continuous rate G' plus finitely many jumps inside the interval. For a continuous value, the integral is the ordinary integral of f times G', plus each jump's size times the value there.
- The average payout, the integral of the payout x against the share G from −20 to 100, is exactly $35 per contract.
- The hand arithmetic holds exactly: the counting, the chart, the worked numbers, the 12-slice sums 27.50 and 37.50, and the mistakes.

The fee's split sums, the 120- and 1200-slice sums, the contract-by-contract average and the area above G are left to the Python and Rust checks.

<details>
<summary>The Lean proof, 474 lines</summary>

```lean
-- Stieltjes integrals: a continuous value has a Stieltjes integral against every nondecreasing integrator, a steady rise plus jumps gives an ordinary integral plus one term per jump, and the card's 1,000 contracts average $35.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Topology.UniformSpace.HeineCantor

open Set

/-- A partition of `[a, b]` into `n` slices: the cuts `a = x 0 < x 1 < ... < x n = b`. -/
def IsPartition (a b : ℝ) (n : ℕ) (x : Fin (n + 1) → ℝ) : Prop :=
  StrictMono x ∧ x 0 = a ∧ x (Fin.last n) = b

/-- A Stieltjes sum: value at the tag `ξ k` times the weight `G(x_k) - G(x_{k-1})` of slice `k`. -/
def stieltjesSum (f G : ℝ → ℝ) (n : ℕ) (x : Fin (n + 1) → ℝ) (ξ : Fin n → ℝ) : ℝ :=
  ∑ k : Fin n, f (ξ k) * (G (x k.succ) - G (x k.castSucc))

/-- `I` is the Stieltjes integral of `f` against `G` from `a` to `b`: the Stieltjes sums settle
on `I` as the widest slice shrinks, whatever the tags. For every `ε > 0` there is a width `δ > 0`
such that every partition whose slices are all narrower than `δ`, with any tag in each slice,
gives a sum within `ε` of `I`. -/
def HasStieltjesIntegral (f G : ℝ → ℝ) (a b I : ℝ) : Prop :=
  ∀ ε > 0, ∃ δ > 0, ∀ (n : ℕ) (x : Fin (n + 1) → ℝ) (ξ : Fin n → ℝ),
    IsPartition a b n x →
    (∀ k : Fin n, x k.succ - x k.castSucc < δ) →
    (∀ k : Fin n, ξ k ∈ Icc (x k.castSucc) (x k.succ)) →
    |stieltjesSum f G n x ξ - I| < ε

/-- The `n` equal slices of `[a, b]`: cut `k` sits at `a + (b - a) k / n`. -/
noncomputable def evenCuts (a b : ℝ) (n : ℕ) (k : Fin (n + 1)) : ℝ :=
  a + (b - a) * (k : ℕ) / n

/-- The card's integrator: the share of the 1,000 contracts paying at most `x` dollars.
A lump of 2/5 at $0, a steady rise of 1/200 per dollar, and a lump of 1/10 at the $100 cap. -/
noncomputable def bookShare (x : ℝ) : ℝ :=
  if x < 0 then 0 else if x < 100 then 2 / 5 + x / 200 else 1

lemma rs_fin_tele (n : ℕ) (y : Fin (n + 1) → ℝ) :
    ∑ k : Fin n, (y k.succ - y k.castSucc) = y (Fin.last n) - y 0 := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [Fin.sum_univ_castSucc]
    have := ih (fun i => y i.castSucc)
    simp only [Fin.succ_castSucc] at this ⊢
    rw [this]
    simp only [Fin.castSucc_zero, Fin.succ_last]
    ring

#print axioms rs_fin_tele

lemma rs_part_mem {a b : ℝ} {n : ℕ} {x : Fin (n + 1) → ℝ} (h : IsPartition a b n x)
    (i : Fin (n + 1)) : x i ∈ Icc a b := by
  obtain ⟨hm, h0, hl⟩ := h
  constructor
  · rw [← h0]; exact hm.monotone (Fin.zero_le i)
  · rw [← hl]; exact hm.monotone (Fin.le_last i)

#print axioms rs_part_mem

lemma rs_part_lt {a b : ℝ} {n : ℕ} {x : Fin (n + 1) → ℝ} (h : IsPartition a b n x)
    (k : Fin n) : x k.castSucc < x k.succ := h.1 (Fin.castSucc_lt_succ (i := k))

#print axioms rs_part_lt

lemma rs_crit (f G Φ Ψ : ℝ → ℝ) (a b : ℝ)
    (h : ∀ ε > 0, ∃ δ > 0, ∀ u ξ v, a ≤ u → u ≤ ξ → ξ ≤ v → v ≤ b → v - u < δ →
      |Φ v - Φ u - f ξ * (G v - G u)| ≤ ε * (Ψ v - Ψ u)) :
    HasStieltjesIntegral f G a b (Φ b - Φ a) := by
  intro ε hε
  set C := |Ψ b - Ψ a| + 1 with hC
  have hCpos : 0 < C := by positivity
  obtain ⟨δ, hδ, hδ'⟩ := h (ε / (2 * C)) (by positivity)
  refine ⟨δ, hδ, fun n x ξ hP hmesh htag => ?_⟩
  have hsum : Φ b - Φ a - stieltjesSum f G n x ξ = ∑ k : Fin n, (Φ (x k.succ) - Φ (x k.castSucc)
      - f (ξ k) * (G (x k.succ) - G (x k.castSucc))) := by
    rw [Finset.sum_sub_distrib, rs_fin_tele n (fun i => Φ (x i)), hP.2.1, hP.2.2]; rfl
  have hb : |Φ b - Φ a - stieltjesSum f G n x ξ| ≤ ε / (2 * C) * (Ψ b - Ψ a) := by
    rw [hsum]
    calc _ ≤ ∑ k : Fin n, |Φ (x k.succ) - Φ (x k.castSucc)
            - f (ξ k) * (G (x k.succ) - G (x k.castSucc))| := Finset.abs_sum_le_sum_abs _ _
      _ ≤ ∑ k : Fin n, ε / (2 * C) * (Ψ (x k.succ) - Ψ (x k.castSucc)) :=
          Finset.sum_le_sum fun k _ => hδ' _ _ _ (rs_part_mem hP _).1 (htag k).1 (htag k).2
            (rs_part_mem hP _).2 (hmesh k)
      _ = _ := by rw [← Finset.mul_sum, rs_fin_tele n (fun i => Ψ (x i)), hP.2.1, hP.2.2]
  have h2 : ε / (2 * C) * C = ε / 2 := by field_simp
  rw [abs_sub_comm]
  calc _ ≤ ε / (2 * C) * (Ψ b - Ψ a) := hb
    _ ≤ ε / (2 * C) * C :=
        mul_le_mul_of_nonneg_left (by rw [hC]; linarith [le_abs_self (Ψ b - Ψ a)]) (by positivity)
    _ < ε := by rw [h2]; linarith

#print axioms rs_crit

lemma rs_clamp_swap (G : ℝ → ℝ) (p q r s : ℝ) (hpq : p ≤ q) (hrs : r ≤ s) :
    G (max p (min q s)) - G (max p (min q r))
      = G (max r (min s q)) - G (max r (min s p)) := by
  rcases le_total q r with h1 | h1
  · rw [show max p (min q s) = max p (min q r) by
        simp only [max_def, min_def]; split_ifs <;> linarith,
      show max r (min s q) = max r (min s p) by
        simp only [max_def, min_def]; split_ifs <;> linarith]
    ring
  rcases le_total s p with h2 | h2
  · rw [show max p (min q s) = max p (min q r) by
        simp only [max_def, min_def]; split_ifs <;> linarith,
      show max r (min s q) = max r (min s p) by
        simp only [max_def, min_def]; split_ifs <;> linarith]
    ring
  rw [show max p (min q s) = max r (min s q) by
        simp only [max_def, min_def]; split_ifs <;> linarith,
      show max p (min q r) = max r (min s p) by
        simp only [max_def, min_def]; split_ifs <;> linarith]

#print axioms rs_clamp_swap

lemma rs_clamp_overlap (G : ℝ → ℝ) (p q r s : ℝ) (_hpq : p ≤ q) (hrs : r ≤ s)
    (h : G (max p (min q s)) - G (max p (min q r)) ≠ 0) : r < q ∧ p < s := by
  constructor
  · by_contra hcon
    push Not at hcon
    apply h
    rw [show max p (min q s) = max p (min q r) by
        simp only [max_def, min_def]; split_ifs <;> linarith]
    ring
  · by_contra hcon
    push Not at hcon
    apply h
    rw [show max p (min q s) = max p (min q r) by
        simp only [max_def, min_def]; split_ifs <;> linarith]
    ring

#print axioms rs_clamp_overlap

lemma rs_clamp_nonneg (G : ℝ → ℝ) (a b p q r s : ℝ) (hG : MonotoneOn G (Icc a b))
    (hp : p ∈ Icc a b) (hq : q ∈ Icc a b) (_hpq : p ≤ q) (hrs : r ≤ s) :
    0 ≤ G (max p (min q s)) - G (max p (min q r)) := by
  have m1 : max p (min q s) ∈ Icc a b :=
    ⟨hp.1.trans (le_max_left _ _), max_le hp.2 ((min_le_left _ _).trans hq.2)⟩
  have m2 : max p (min q r) ∈ Icc a b :=
    ⟨hp.1.trans (le_max_left _ _), max_le hp.2 ((min_le_left _ _).trans hq.2)⟩
  exact sub_nonneg.2 (hG m2 m1 (max_le_max le_rfl (min_le_min le_rfl hrs)))

#print axioms rs_clamp_nonneg

lemma rs_cauchy (f G : ℝ → ℝ) (a b : ℝ) (hf : ContinuousOn f (Icc a b))
    (hG : MonotoneOn G (Icc a b)) :
    ∀ ε > 0, ∃ δ > 0, ∀ (n : ℕ) (x : Fin (n + 1) → ℝ) (ξ : Fin n → ℝ)
      (m : ℕ) (y : Fin (m + 1) → ℝ) (η : Fin m → ℝ),
      IsPartition a b n x → (∀ k : Fin n, x k.succ - x k.castSucc < δ) →
      (∀ k : Fin n, ξ k ∈ Icc (x k.castSucc) (x k.succ)) →
      IsPartition a b m y → (∀ k : Fin m, y k.succ - y k.castSucc < δ) →
      (∀ k : Fin m, η k ∈ Icc (y k.castSucc) (y k.succ)) →
      |stieltjesSum f G n x ξ - stieltjesSum f G m y η| ≤ ε * (G b - G a) := by
  intro ε hε
  obtain ⟨δ, hδ, hδ'⟩ := Metric.uniformContinuousOn_iff.1
    (isCompact_Icc.uniformContinuousOn_of_continuous hf) ε hε
  refine ⟨δ / 2, by positivity, ?_⟩
  intro n x ξ m y η hP hPm hPt hQ hQm hQt
  set W : Fin n → Fin m → ℝ := fun k j =>
    G (max (x k.castSucc) (min (x k.succ) (y j.succ)))
      - G (max (x k.castSucc) (min (x k.succ) (y j.castSucc))) with hW
  have hrow : ∀ k, ∑ j, W k j = G (x k.succ) - G (x k.castSucc) := by
    intro k
    rw [hW]
    rw [rs_fin_tele m (fun i => G (max (x k.castSucc) (min (x k.succ) (y i)))), hQ.2.1, hQ.2.2]
    have h1 := rs_part_mem hP k.castSucc
    have h2 := rs_part_mem hP k.succ
    have h3 := rs_part_lt hP k
    rw [min_eq_left h2.2, max_eq_right h3.le, min_eq_right (h1.1.trans h3.le),
      max_eq_left h1.1]
  have hcol : ∀ j, ∑ k, W k j = G (y j.succ) - G (y j.castSucc) := by
    intro j
    have hsw : ∀ k, W k j = G (max (y j.castSucc) (min (y j.succ) (x k.succ)))
        - G (max (y j.castSucc) (min (y j.succ) (x k.castSucc))) := fun k =>
      rs_clamp_swap G _ _ _ _ (rs_part_lt hP k).le (rs_part_lt hQ j).le
    rw [Finset.sum_congr rfl fun k _ => hsw k]
    rw [rs_fin_tele n (fun i => G (max (y j.castSucc) (min (y j.succ) (x i)))), hP.2.1, hP.2.2]
    have h1 := rs_part_mem hQ j.castSucc
    have h2 := rs_part_mem hQ j.succ
    have h3 := rs_part_lt hQ j
    rw [min_eq_left h2.2, max_eq_right h3.le, min_eq_right (h1.1.trans h3.le),
      max_eq_left h1.1]
  have hdiff : stieltjesSum f G n x ξ - stieltjesSum f G m y η
      = ∑ k, ∑ j, (f (ξ k) - f (η j)) * W k j := by
    unfold stieltjesSum
    rw [Finset.sum_congr rfl fun k _ => congrArg (f (ξ k) * ·) (hrow k).symm,
      Finset.sum_congr rfl fun j _ => congrArg (f (η j) * ·) (hcol j).symm]
    simp only [Finset.mul_sum]
    rw [Finset.sum_comm (s := Finset.univ) (t := Finset.univ)
      (f := fun j k => f (η j) * W k j), ← Finset.sum_sub_distrib]
    refine Finset.sum_congr rfl fun k _ => ?_
    rw [← Finset.sum_sub_distrib]
    exact Finset.sum_congr rfl fun j _ => by ring
  rw [hdiff]
  calc |∑ k, ∑ j, (f (ξ k) - f (η j)) * W k j| ≤ ∑ k, ∑ j, ε * W k j := by
        refine (Finset.abs_sum_le_sum_abs _ _).trans (Finset.sum_le_sum fun k _ => ?_)
        refine (Finset.abs_sum_le_sum_abs _ _).trans (Finset.sum_le_sum fun j _ => ?_)
        have hW0 : 0 ≤ W k j := rs_clamp_nonneg G a b _ _ _ _ hG (rs_part_mem hP _)
          (rs_part_mem hP _) (rs_part_lt hP k).le (rs_part_lt hQ j).le
        rw [abs_mul, abs_of_nonneg hW0]
        by_cases hz : W k j = 0
        · rw [hz]; simp
        · apply mul_le_mul_of_nonneg_right _ hW0
          obtain ⟨o1, o2⟩ := rs_clamp_overlap G _ _ _ _ (rs_part_lt hP k).le
            (rs_part_lt hQ j).le hz
          have hξ : ξ k ∈ Icc a b :=
            ⟨(rs_part_mem hP _).1.trans (hPt k).1, (hPt k).2.trans (rs_part_mem hP _).2⟩
          have hη : η j ∈ Icc a b :=
            ⟨(rs_part_mem hQ _).1.trans (hQt j).1, (hQt j).2.trans (rs_part_mem hQ _).2⟩
          have hd := hδ' _ hξ _ hη (by
            rw [Real.dist_eq, abs_lt]
            constructor <;> linarith [(hPt k).1, (hPt k).2, (hQt j).1, (hQt j).2, hPm k, hQm j])
          rw [Real.dist_eq] at hd
          exact hd.le
    _ = ε * (G b - G a) := by
        simp only [← Finset.mul_sum, hrow]
        rw [rs_fin_tele n (fun i => G (x i)), hP.2.1, hP.2.2]

#print axioms rs_cauchy

lemma rs_half (ε D : ℝ) (hε : 0 < ε) (hD : 0 ≤ D) : ε / (2 * (D + 1)) * D ≤ ε / 2 := by
  rw [div_mul_eq_mul_div, div_le_div_iff₀ (by positivity) (by norm_num)]
  nlinarith

#print axioms rs_half

lemma rs_even_part (a b : ℝ) (hab : a < b) (n : ℕ) :
    IsPartition a b (n + 1) (evenCuts a b (n + 1)) := by
  have hn : (0 : ℝ) < ((n + 1 : ℕ) : ℝ) := by positivity
  refine ⟨fun i j hij => ?_, ?_, ?_⟩
  · simp only [evenCuts]
    have : ((i : ℕ) : ℝ) < ((j : ℕ) : ℝ) := by exact_mod_cast hij
    have h2 : (b - a) * (i : ℕ) / ((n + 1 : ℕ) : ℝ) < (b - a) * (j : ℕ) / ((n + 1 : ℕ) : ℝ) :=
      div_lt_div_of_pos_right (mul_lt_mul_of_pos_left this (sub_pos.2 hab)) hn
    linarith
  · simp [evenCuts]
  · simp only [evenCuts, Fin.val_last]
    field_simp
    ring

#print axioms rs_even_part

lemma rs_even_mesh (a b : ℝ) (n : ℕ) (k : Fin (n + 1)) :
    evenCuts a b (n + 1) k.succ - evenCuts a b (n + 1) k.castSucc = (b - a) / ((n : ℝ) + 1) := by
  simp only [evenCuts, Fin.val_succ, Fin.val_castSucc]
  push_cast
  field_simp
  ring

#print axioms rs_even_mesh

/-- The Stieltjes integral exists: if the value `f` is continuous on `[a, b]` and the
integrator `G` never falls there, then the Stieltjes sums of `f` against `G` settle on one
number as the widest slice shrinks, whatever the tags. -/
theorem continuous_has_stieltjes_integral_against_nondecreasing (f G : ℝ → ℝ) (a b : ℝ)
    (hf : ContinuousOn f (Icc a b)) (hG : MonotoneOn G (Icc a b)) :
    ∃ I, HasStieltjesIntegral f G a b I := by
  by_cases hab : a < b
  · have hD : 0 ≤ G b - G a :=
      sub_nonneg.2 (hG (left_mem_Icc.2 hab.le) (right_mem_Icc.2 hab.le) hab.le)
    set D := G b - G a with hDdef
    have hC := rs_cauchy f G a b hf hG
    set s : ℕ → ℝ := fun N => stieltjesSum f G (N + 1) (evenCuts a b (N + 1))
      (fun k => evenCuts a b (N + 1) k.castSucc) with hs
    have htag : ∀ N (k : Fin (N + 1)), evenCuts a b (N + 1) k.castSucc ∈
        Icc (evenCuts a b (N + 1) k.castSucc) (evenCuts a b (N + 1) k.succ) :=
      fun N k => ⟨le_rfl, (rs_part_lt (rs_even_part a b hab N) k).le⟩
    have hmesh : ∀ δ > 0, ∃ N₀ : ℕ, ∀ N ≥ N₀, ∀ k : Fin (N + 1),
        evenCuts a b (N + 1) k.succ - evenCuts a b (N + 1) k.castSucc < δ := by
      intro δ hδ
      obtain ⟨N₀, hN₀⟩ := exists_nat_gt ((b - a) / δ)
      refine ⟨N₀, fun N hN k => ?_⟩
      rw [rs_even_mesh, div_lt_iff₀ (by positivity)]
      rw [div_lt_iff₀ hδ] at hN₀
      have : (N₀ : ℝ) ≤ N := by exact_mod_cast hN
      nlinarith
    -- the key estimate: two fine sums are close
    have hclose : ∀ ε > 0, ∃ δ > 0, ∃ N₀ : ℕ, ∀ N ≥ N₀, ∀ (n : ℕ) (x : Fin (n + 1) → ℝ)
        (ξ : Fin n → ℝ), IsPartition a b n x → (∀ k : Fin n, x k.succ - x k.castSucc < δ) →
        (∀ k : Fin n, ξ k ∈ Icc (x k.castSucc) (x k.succ)) →
        |stieltjesSum f G n x ξ - s N| ≤ ε / 2 := by
      intro ε hε
      obtain ⟨δ, hδ, hδ'⟩ := hC (ε / (2 * (D + 1))) (by positivity)
      obtain ⟨N₀, hN₀⟩ := hmesh δ hδ
      refine ⟨δ, hδ, N₀, fun N hN n x ξ hP hPm hPt => ?_⟩
      exact (hδ' n x ξ (N + 1) _ _ hP hPm hPt (rs_even_part a b hab N) (hN₀ N hN)
        (htag N)).trans (rs_half ε D hε hD)
    have hcs : CauchySeq s := by
      rw [Metric.cauchySeq_iff]
      intro ε hε
      obtain ⟨δ, hδ, N₀, hN₀⟩ := hclose ε hε
      obtain ⟨N₁, hN₁⟩ := hmesh δ hδ
      refine ⟨max N₀ N₁, fun p hp q hq => ?_⟩
      rw [Real.dist_eq]
      have := hN₀ q (le_of_max_le_left hq) (p + 1) _ _ (rs_even_part a b hab p)
        (hN₁ p (le_of_max_le_right hp)) (htag p)
      linarith
    obtain ⟨I, hI⟩ := cauchySeq_tendsto_of_complete hcs
    refine ⟨I, fun ε hε => ?_⟩
    obtain ⟨δ, hδ, N₀, hN₀⟩ := hclose ε hε
    obtain ⟨N₁, hN₁⟩ := Metric.tendsto_atTop.1 hI (ε / 2) (by positivity)
    refine ⟨δ, hδ, fun n x ξ hP hPm hPt => ?_⟩
    have h1 := hN₀ (max N₀ N₁) (le_max_left _ _) n x ξ hP hPm hPt
    have h2 := hN₁ (max N₀ N₁) (le_max_right _ _)
    rw [Real.dist_eq] at h2
    calc |stieltjesSum f G n x ξ - I|
        ≤ |stieltjesSum f G n x ξ - s (max N₀ N₁)| + |s (max N₀ N₁) - I| := abs_sub_le _ _ _
      _ < ε := by linarith
  · refine ⟨0, fun ε hε => ⟨1, one_pos, fun n x ξ hP _ _ => ?_⟩⟩
    obtain rfl : n = 0 := by
      by_contra hn
      apply hab
      rw [← hP.2.1, ← hP.2.2]
      apply hP.1
      rw [Fin.lt_def]
      simp only [Fin.val_zero, Fin.val_last]
      omega
    simp [stieltjesSum, hε]

/-- The working formula: if the nondecreasing integrator `G` is a part `G₀` climbing at a
continuous rate `g` plus finitely many jumps, of size `w j` at the point `c j` inside the
interval (`a < c j ≤ b`), then for a continuous value `f` the Stieltjes integral is the ordinary
integral of `f` times the rate, plus each jump's size times the value there. -/
theorem stieltjes_integral_rate_plus_jumps (f G G₀ g : ℝ → ℝ) (a b : ℝ) (m : ℕ)
    (w c : Fin m → ℝ)
    (hf : ContinuousOn f (Icc a b)) (hG : MonotoneOn G (Icc a b))
    (hG₀ : ∀ x ∈ Icc a b, HasDerivWithinAt G₀ (g x) (Icc a b) x)
    (hg : ContinuousOn g (Icc a b))
    (hc : ∀ j, c j ∈ Ioc a b)
    (hsplit : ∀ x ∈ Icc a b, G x = G₀ x + ∑ j, w j * (if c j ≤ x then 1 else 0)) :
    HasStieltjesIntegral f G a b ((∫ x in a..b, f x * g x) + ∑ j, w j * f (c j)) := by
  obtain ⟨M, hM⟩ := isCompact_Icc.exists_bound_of_continuousOn hg
  have hfg : ContinuousOn (fun x => f x * g x) (Icc a b) := hf.mul hg
  have hint : ∀ p ∈ Icc a b, ∀ q ∈ Icc a b,
      IntervalIntegrable (fun x => f x * g x) MeasureTheory.volume p q :=
    fun p hp q hq => (hfg.mono (uIcc_subset_Icc hp hq)).intervalIntegrable
  have hintg : ∀ p ∈ Icc a b, ∀ q ∈ Icc a b, IntervalIntegrable g MeasureTheory.volume p q :=
    fun p hp q hq => (hg.mono (uIcc_subset_Icc hp hq)).intervalIntegrable
  set s : Fin m → ℝ → ℝ := fun j x => if c j ≤ x then 1 else 0 with hs
  set Φ : ℝ → ℝ := fun x => (∫ t in a..x, f t * g t) + ∑ j, w j * f (c j) * s j x with hΦ
  set Ψ : ℝ → ℝ := fun x => M * x + ∑ j, |w j| * s j x with hΨ
  have key := rs_crit f G Φ Ψ a b ?_
  · convert key using 1
    have h1 : ∀ j, s j b = 1 := fun j => by simp [hs, (hc j).2]
    have h0 : ∀ j, s j a = 0 := fun j => by simp [hs, not_le.2 (hc j).1]
    simp only [hΦ, h1, h0, mul_one, mul_zero, Finset.sum_const_zero,
      intervalIntegral.integral_same, add_zero, sub_zero]
  · intro ε hε
    obtain ⟨δ, hδ, hδ'⟩ := Metric.uniformContinuousOn_iff.1
      (isCompact_Icc.uniformContinuousOn_of_continuous hf) ε hε
    refine ⟨δ, hδ, fun u ξ v hau huξ hξv hvb hvu => ?_⟩
    have huv : u ≤ v := huξ.trans hξv
    have hu : u ∈ Icc a b := ⟨hau, huv.trans hvb⟩
    have hv : v ∈ Icc a b := ⟨hau.trans huv, hvb⟩
    have hξ : ξ ∈ Icc a b := ⟨hau.trans huξ, hξv.trans hvb⟩
    have ha : a ∈ Icc a b := ⟨le_rfl, hau.trans (huv.trans hvb)⟩
    have hGs : G v - G u = (G₀ v - G₀ u) + ∑ j, w j * (s j v - s j u) := by
      rw [hsplit v hv, hsplit u hu]
      simp only [hs, mul_sub, Finset.sum_sub_distrib]
      ring
    have hG₀' : G₀ v - G₀ u = ∫ t in u..v, g t := by
      symm
      apply intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le huv
      · exact fun x hx => (hG₀ x ⟨hau.trans hx.1, hx.2.trans hvb⟩).continuousWithinAt.mono
          (Icc_subset_Icc hau hvb)
      · exact fun x hx => (hG₀ x ⟨hau.trans hx.1.le, hx.2.le.trans hvb⟩).hasDerivAt
          (Icc_mem_nhds (hau.trans_lt hx.1) (hx.2.trans_le hvb))
      · exact hintg u hu v hv
    have hΦ' : Φ v - Φ u = (∫ t in u..v, f t * g t) + ∑ j, w j * f (c j) * (s j v - s j u) := by
      simp only [hΦ]
      rw [← intervalIntegral.integral_interval_sub_left (hint a ha v hv) (hint a ha u hu)]
      simp only [mul_sub, Finset.sum_sub_distrib]
      ring
    have hA : (∫ t in u..v, (f t - f ξ) * g t)
        = (∫ t in u..v, f t * g t) - f ξ * ∫ t in u..v, g t := by
      simp only [sub_mul]
      rw [intervalIntegral.integral_sub (hint u hu v hv) ((hintg u hu v hv).const_mul (f ξ)),
        intervalIntegral.integral_const_mul]
    have hB : ∑ j, w j * (f (c j) - f ξ) * (s j v - s j u)
        = ∑ j, w j * f (c j) * (s j v - s j u) - f ξ * ∑ j, w j * (s j v - s j u) := by
      rw [Finset.mul_sum, ← Finset.sum_sub_distrib]
      exact Finset.sum_congr rfl fun j _ => by ring
    have hE : Φ v - Φ u - f ξ * (G v - G u) = (∫ t in u..v, (f t - f ξ) * g t)
        + ∑ j, w j * (f (c j) - f ξ) * (s j v - s j u) := by
      rw [hΦ', hGs, hG₀', hA, hB]; ring
    have hAb : |∫ t in u..v, (f t - f ξ) * g t| ≤ ε * M * (v - u) := by
      have := intervalIntegral.norm_integral_le_of_norm_le_const (a := u) (b := v)
        (C := ε * M) (f := fun t => (f t - f ξ) * g t) ?_
      · rw [Real.norm_eq_abs, abs_of_nonneg (sub_nonneg.2 huv)] at this
        exact this
      · intro t ht
        rw [uIoc_of_le huv] at ht
        have htm : t ∈ Icc a b := ⟨hau.trans ht.1.le, ht.2.trans hvb⟩
        have hd : dist (f t) (f ξ) < ε := hδ' t htm ξ hξ (by
          rw [Real.dist_eq, abs_lt]; constructor <;> linarith [ht.1, ht.2])
        rw [Real.dist_eq] at hd
        rw [norm_mul, Real.norm_eq_abs]
        exact mul_le_mul hd.le (hM t htm) (norm_nonneg _) hε.le
    have hBb : |∑ j, w j * (f (c j) - f ξ) * (s j v - s j u)|
        ≤ ε * ∑ j, |w j| * (s j v - s j u) := by
      rw [Finset.mul_sum]
      refine (Finset.abs_sum_le_sum_abs _ _).trans (Finset.sum_le_sum fun j _ => ?_)
      simp only [hs]
      by_cases h1 : c j ≤ u
      · have h2 : c j ≤ v := h1.trans huv
        simp [h1, h2]
      · by_cases h2 : c j ≤ v
        · simp only [h1, h2, ↓reduceIte, sub_zero, mul_one, abs_mul]
          have hcm : c j ∈ Icc a b := ⟨(hc j).1.le, (hc j).2⟩
          have hd : dist (f (c j)) (f ξ) < ε := hδ' _ hcm ξ hξ (by
            rw [Real.dist_eq, abs_lt]; constructor <;> linarith [not_le.1 h1])
          rw [Real.dist_eq] at hd
          nlinarith [abs_nonneg (w j)]
        · have h1' : ¬ c j ≤ u := h1
          simp [h1', h2]
    have hΨ' : Ψ v - Ψ u = M * (v - u) + ∑ j, |w j| * (s j v - s j u) := by
      simp only [hΨ, mul_sub, Finset.sum_sub_distrib]; ring
    rw [hE, hΨ']
    calc _ ≤ |∫ t in u..v, (f t - f ξ) * g t| + |∑ j, w j * (f (c j) - f ξ) * (s j v - s j u)| :=
          abs_add_le _ _
      _ ≤ ε * M * (v - u) + ε * ∑ j, |w j| * (s j v - s j u) := add_le_add hAb hBb
      _ = _ := by ring

/-- The card's answer: the average payout, the Stieltjes integral of the payout `x` against the
share of contracts paying at most `x`, taken from -20 to 100, is $35 per contract. -/
theorem book_average_payout_is_35 :
    HasStieltjesIntegral (fun x => x) bookShare (-20) 100 35 := by
  have key := rs_crit (fun x => x) bookShare
    (fun x => if x < 0 then 0 else if x < 100 then x ^ 2 / 400 else 35)
    (fun x => 2 * bookShare x) (-20) 100 ?_
  · convert key using 1; norm_num
  · intro ε hε
    refine ⟨ε, hε, fun u ξ v hu huξ hξv hv hvu => ?_⟩
    simp only [bookShare]
    rw [abs_le]
    split_ifs <;> constructor <;>
      nlinarith [mul_nonneg (sub_nonneg.2 huξ) (sub_nonneg.2 hξv),
        mul_nonneg (sub_nonneg.2 (huξ.trans hξv)) hε.le,
        mul_nonneg (sub_nonneg.2 (huξ.trans hξv)) (sub_nonneg.2 huξ),
        mul_nonneg (sub_nonneg.2 (huξ.trans hξv)) (sub_nonneg.2 hξv),
        mul_nonneg (sub_nonneg.2 (huξ.trans hξv)) (sub_pos.2 hvu).le]

-- Counting: 400 + 500 + 100 = 1,000 contracts; 500 × $50 + 100 × $100 = $35,000, $35 each.
example : 400 + 500 + 100 = 1000 ∧ 500 * 50 + 100 * 100 = 35000 ∧ 35000 / 1000 = 35 := by
  decide
-- The integrator's chart: G at -20, 0, 20, 40, 60, 80, 100 is 0, 2/5, 1/2, 3/5, 7/10, 4/5, 1.
example : [-20, 0, 20, 40, 60, 80, 100].map bookShare = [0, 2 / 5, 1 / 2, 3 / 5, 7 / 10, 4 / 5, 1] := by
  norm_num [bookShare]
-- Total weight G(b) - G(a) = 1, the whole book.
example : bookShare 100 - bookShare (-20) = 1 := by norm_num [bookShare]
-- Worked numbers: smooth part 1/200 × 100 × 100 / 2 = 25; jumps 2/5 × 0 + 1/10 × 100 = 10;
-- average 25 + 0 + 10 = 35.
example : (1 / 200 : ℚ) * 100 * 100 / 2 = 25 ∧ (2 / 5 : ℚ) * 0 + 1 / 10 * 100 = 10 ∧
    (25 : ℚ) + 0 + 10 = 35 := by norm_num
-- 12 slices of $10, left tags: the lower sum is 55/2 (27.50).
example : stieltjesSum (fun x => x) bookShare 12 (evenCuts (-20) 100 12)
    (fun k => evenCuts (-20) 100 12 k.castSucc) = 55 / 2 := by
  norm_num [stieltjesSum, evenCuts, bookShare, Fin.sum_univ_succ]
-- 12 slices of $10, right tags: the upper sum is 75/2 (37.50).
example : stieltjesSum (fun x => x) bookShare 12 (evenCuts (-20) 100 12)
    (fun k => evenCuts (-20) 100 12 k.succ) = 75 / 2 := by
  norm_num [stieltjesSum, evenCuts, bookShare, Fin.sum_univ_succ]
-- The mistakes: lumps dropped gives 25; divided by the smooth weight 1/2 gives 50;
-- width instead of weight, 100 × 100 / 2, gives 5000.
example : (25 : ℚ) / (1 / 2) = 50 ∧ (100 : ℚ) * 100 / 2 = 5000 := by norm_num
-- The fee by counting: 600 of the 1,000 contracts pay something, 3/5 of a dollar each.
example : 400 + 500 + 100 - 400 = 600 ∧ (600 : ℚ) / 1000 = 3 / 5 := by norm_num

#print axioms continuous_has_stieltjes_integral_against_nondecreasing
#print axioms stieltjes_integral_rate_plus_jumps
#print axioms book_average_payout_is_35
```

</details>

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'rs_fin_tele' depends on axioms: [propext, Classical.choice, Quot.sound]
'rs_part_mem' depends on axioms: [propext, Classical.choice, Quot.sound]
'rs_part_lt' depends on axioms: [propext, Classical.choice, Quot.sound]
'rs_crit' depends on axioms: [propext, Classical.choice, Quot.sound]
'rs_clamp_swap' depends on axioms: [propext, Classical.choice, Quot.sound]
'rs_clamp_overlap' depends on axioms: [propext, Classical.choice, Quot.sound]
'rs_clamp_nonneg' depends on axioms: [propext, Classical.choice, Quot.sound]
'rs_cauchy' depends on axioms: [propext, Classical.choice, Quot.sound]
'rs_half' depends on axioms: [propext, Classical.choice, Quot.sound]
'rs_even_part' depends on axioms: [propext, Classical.choice, Quot.sound]
'rs_even_mesh' depends on axioms: [propext, Classical.choice, Quot.sound]
'continuous_has_stieltjes_integral_against_nondecreasing' depends on axioms: [propext, Classical.choice, Quot.sound]
'stieltjes_integral_rate_plus_jumps' depends on axioms: [propext, Classical.choice, Quot.sound]
'book_average_payout_is_35' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> - **Start at the lump.** Guess first, then set A to 0. Answer: the 0.40 jump hides inside G(a) and the total weight falls to 0.60; the integral stays 35.00, since that jump paid $0. The fee's assert fails: with the jump outside, both tags close on 0.6000.
> - **A convenient grid.** Guess first, then run the fee on 120 slices. Answer: $0 becomes a cut, both tags see a zero fee on the lump, the sums nearly agree near 0.6000, and the last assert fails. The definition demands every fine grid.

---

## The usual mistake

> [!warning]
> **Replacing dG by G'(x) dx everywhere.** A jump has no rate: G' is zero on either side and undefined at it. The rate discards every contract sitting on one payout: $25.00 instead of $35.00.
>
> - **Averaging over the smooth weight only.** $25.00 divided by 0.50 gives $50.00, dropping the zero-payers from the count too.
> - **Starting the interval on a jump.** A jump at the start is inside G(a) and never registers as a rise.
> - **Trusting one grid.** Cuts exactly at the fee's jump make its sums agree and hide the split on other grids.

---

## Where you meet it in real life

- **Insurance pricing.** Claim lists have a lump at zero, lumps at policy limits and a spread between; the pure premium, the average claim, is this integral.
- **Probability.** A running share like G is a distribution function, and the average is the expected value of [Expectation](../../09-Probability%20and%20statistics/02-Random%20Variables/02-expectation.md), for counts, spreads and mixtures alike.
- **Counting primes.** Sums over primes are integrals against the prime count, which jumps at each prime: Partial summation.

Weight spread over a region instead of a line is [Double integrals](01-double-integrals.md).

> **Say it back**
> A Stieltjes integral weighs each slice by how much a running total rises across it, not by its width. With a running total that never falls and a continuous value, lower and upper sums close on one number. A steady rise becomes an ordinary integral; a jump becomes its size times the value there. For the 1,000 contracts: 25 from the spread, 10 from the cap, $35 each.

---

## What this builds on

- [The integral](../04-Integrals/01-riemann-integral.md): the lower and upper sums, and the gap test, reused here with weights in place of widths.

## Where this goes next

- [Expectation](../../09-Probability%20and%20statistics/02-Random%20Variables/02-expectation.md): the running share as a distribution, this integral as its average.
- [The Lebesgue-Stieltjes integral](../../10-Measure%20and%20integration/11-Derivatives%20Meet%20the%20Lebesgue%20Integral/05-lebesgue-stieltjes-integral.md): the same weights, with values that need not be continuous.
- [The Ito integral](../../11-Stochastic%20processes%20and%20calculus/06-Ito%20Calculus/01-ito-integral.md): an integrator so rough that the tag choice changes the answer for good.

So what: counting prices the fee at once, yet it has no Stieltjes integral; the integral that agrees with counting is [The Lebesgue-Stieltjes integral](../../10-Measure%20and%20integration/11-Derivatives%20Meet%20the%20Lebesgue%20Integral/05-lebesgue-stieltjes-integral.md).

---

## Sources

Verified 2026-09-27: every link below resolves to the page named.

- Stieltjes, T.-J. "Recherches sur les fractions continues." *Annales de la Faculté des sciences de Toulouse*, series 1, vol. 8 (1894), J1–J122. [Numdam record](https://www.numdam.org/item/AFST_1894_1_8_4_J1_0/). Where the integral first appears.
- Sharpley, Robert. "Riemann-Stieltjes Integration: Properties." Analysis II lecture notes, University of South Carolina. [Notes](https://people.math.sc.edu/sharpley/math555/Lectures/RS_Properties.html). Additivity in the integrator, the total-weight bound, the one-term rule for jumps.
- Just, Winfried. "Review Module R11." Advanced Calculus, Ohio University. [Notes](https://people.ohio.edu/just/M4302S21/Modules/ModR11.pdf). The reduction to an ordinary integral when the integrator has a rate.
