# Poles on the path: dent the contour round them and collect half a residue, and the principal value is what is left

[Syllabus](../../../SYLLABUS.md) → [Complex analysis](../README.md) → [Real Integrals and Counting Zeros](../README.md#s06) → Poles on the path

---

## General Overview

A camera shutter opens for a fixed moment and shuts. The light it passes is a square pulse: full brightness while open, nothing otherwise. Split that pulse into steady waves. With the open time scaled to 2 units, the strength of the wave at frequency x is proportional to sin x/x: a hump of height 1 at x = 0, then ripples shrinking like 1/x.

Its total signed area, lobes above minus lobes below, is π. Rebuilding the pulse divides that area by π, so the waves added back at the pulse's middle give brightness 1: fully open.

The contour method of [Jordan's lemma](03-oscillatory-integrals-and-jordans-lemma.md) trades sin x/x for e^(iz)/z, which has a pole at 0, right on the path. The fix is a tiny half-circle round it: a dent. The dent does not shrink to nothing; it keeps half the pole's residue. What the rest of the path measures is the principal value: the integral with equal gaps cut out either side of the pole. For 1/(x(1 + x^2)) the pieces left and right of 0 are each infinite, yet the principal value is 0.

**A tiny half-circle round a simple pole on the path contributes −iπ times the residue, so the principal value of a real integral is 2πi times the residues above the axis plus iπ times the residues on it.**

**What kind of fact this is:** a theorem, proved on this card in Why it works; the principal value it computes is a definition.

### The picture: the dented loop at R = 2

<p align="center"><img src="../figures/indented-contours-and-principal-values.svg" alt="The indented contour: the real line from minus 2 to 2 with a small half-circle dent of radius 0.25 over the pole at 0, closed by the upper arc of radius 2; the point i is inside" width="420"></p>

To scale: 60 units per 1, 0 at (180, 170), R = 2, ε = 0.25. Segments (60.00, 170.00)-(165.00, 170.00) and (195.00, 170.00)-(300.00, 170.00); dent top (180.00, 155.00); arc top (180.00, 50.00); i at (180.00, 110.00). Hollow: the pole at 0, outside. Dot: the second example's pole, inside. The dent runs clockwise.

---

## The formula

A reminder: the residue $\operatorname{Res}(f, a)$ is the coefficient of 1/(z − a) in f's expansion near a pole a, and a loop integral is 2πi times the residues inside ([The residue theorem](../05-Laurent%20Series%2C%20Singularities%20and%20Residues/05-the-residue-theorem.md)). At a **simple pole** f behaves like c/(z − a), nothing worse.

The definition: cut a gap of half-width ε either side of the pole a, integrate the rest, then shrink the gap and widen the ends:

$$\operatorname{PV}\int_{-\infty}^{\infty} f(x)\,dx = \lim_{\varepsilon \to 0,\ R \to \infty}\left(\int_{-R}^{a-\varepsilon} f(x)\,dx + \int_{a+\varepsilon}^{R} f(x)\,dx\right).$$

**Read it aloud:** the integral with equal gaps cut round the pole, in the limit as the gaps close.

The dent. Let $\Gamma_\varepsilon$ be the arc $z = a + \varepsilon e^{it}$, with t running from an angle α to an angle β. At a simple pole with residue c,

$$\lim_{\varepsilon \to 0} \int_{\Gamma_\varepsilon} f(z)\,dz = i(\beta - \alpha)\,c.$$

**Read it aloud:** a shrinking arc round a simple pole picks up i times the angle it sweeps times the residue.

The upper dent runs from angle π to 0, so it picks up −iπc. When the big arc $C_R$ fades as R grows,

$$\operatorname{PV}\int_{-\infty}^{\infty} f(x)\,dx = 2\pi i \sum_{\operatorname{Im} b > 0} \operatorname{Res}(f, b) + i\pi \sum_{a \text{ real}} \operatorname{Res}(f, a).$$

**Read it aloud:** full residues above the axis, half residues on it.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $f$, $x$, $z$ | the function; a real point; a point of the plane | e^(iz)/z, then 1/(z(1 + z^2)) | — |
| $a$, $c$ | a simple pole on the real line; its residue | a = 0, c = 1 in both | the dent's share grows |
| $b$ | a pole above the real axis | i, for the second example | — |
| $\varepsilon$, $\Gamma_\varepsilon$ | the dent's radius; the dent itself | 0.5, 0.1, 0.01 | dent moves away from −iπc |
| $R$, $C_R$ | the big arc's radius; the big arc | 5, 10, 20 | the arc fades |
| $t$, $\alpha$, $\beta$ | angle along an arc; its start and end | π to 0 on the dent | a bigger share |
| $\operatorname{PV}$ | principal value: equal gaps, then the limit | iπ, then 0 | — |
| $i$, $\pi$ | the quarter turn, i^2 = −1; a half turn in radians | the dent sweeps π | — |

### When it holds

- **A simple pole on the path.** At a double pole the dent blows up: for 1/z^2 it is −2/ε, −200 at ε = 0.01, though the residue is 0.
- **Equal gaps.** Take the left gap twice the right and the second example tends to ln 2 = 0.693147, not 0.
- **The big arc fades.** A degree gap of 2 ([The semicircle contour](01-semicircle-contours.md)) or a factor e^(iz) does it.
- **Not the ordinary integral.** When each side converges on its own, the two agree; for 1/(x(1 + x^2)) only the principal value exists.

---

## Why it works

### Step 0: a half-turn round a pole is half of a full turn

The integral of 1/(z − a) round a pole counts only the angle swept, not the radius. A full turn gives 2πi times the residue, so a clockwise half-turn gives −πi times it.

### Step 1: prove the arc rule

Near a simple pole, $f(z) = c/(z - a) + g(z)$, where g is holomorphic at a and so bounded, say by M, on a small disc. On the arc, z − a = εe^(it) and dz = iεe^(it) dt. The singular part integrates exactly:

$$\int_\alpha^\beta \frac{c}{\varepsilon e^{it}}\, i\varepsilon e^{it}\,dt = i(\beta - \alpha)\,c.$$

The radius cancels. The remainder is at most M times the length ε|β − α|, which tends to 0.

For e^(iz)/z, c = 1 and g(z) = (e^(iz) − 1)/z. Its series gives |g| ≤ (e^ε − 1)/ε, so the dent is within π(e^ε − 1) of −iπ: at ε = 0.1 it is −2.941704i, off by 0.199889, bound 0.330404.

### Step 2: close the dented loop for sin x/x

Walk from −R to −ε, over the dent to ε, on to R, and back along the big arc. The pole at 0 is dented out, so nothing is inside and Cauchy's theorem makes the loop 0 ([Cauchy's theorem](../03-Contour%20Integrals%20and%20Cauchy%27s%20Theorem/03-cauchys-theorem.md)).

At x and −x, e^(ix)/x adds to 2i sin x/x: the cosine parts cancel. So the segments give 2i times the area under sin x/x from ε to R. At ε = 0.1, R = 10 the pieces are 3.116806i, −2.941704i and −0.175103i, summing to 0. Jordan's lemma bounds the big arc by π/R. Let ε shrink and R grow:

$$\operatorname{PV}\int_{-\infty}^{\infty} \frac{e^{ix}}{x}\,dx - i\pi = 0, \qquad \text{so} \qquad \int_{-\infty}^{\infty} \frac{\sin x}{x}\,dx = \pi.$$

The imaginary part is the shutter's area; sin x/x has no pole, so it needs no principal value.

### Step 3: a real pole with a pole inside

For $f(z) = 1/(z(1 + z^2))$ the pole at 0 has residue 1 and the pole at i has residue 1/(i · 2i) = −1/2. The dented loop now encloses i:

$$\operatorname{PV}\int_{-\infty}^{\infty} \frac{dx}{x(1 + x^2)} + (-i\pi)(1) = 2\pi i\left(-\tfrac{1}{2}\right) = -i\pi.$$

So the principal value is 0. On the big arc |f| ≤ 1/(R(R^2 − 1)) and the length is πR, so the arc is at most π/(R^2 − 1).

### Step 4: the one-sided pieces are infinite

F(x) = ln|x| − ½ ln(1 + x^2) has derivative 1/x − x/(1 + x^2) = f(x). So the piece from ε to 1 is −½ ln 2 − ln ε + ½ ln(1 + ε^2): 4.258647 at ε = 0.01, 8.863767 at ε = 0.0001, without bound. The left piece is its mirror, since f is odd, so the matched sum is 0 for every ε. The ordinary integral does not exist.

<details>
<summary>Detailed proof: the limits, with every bound</summary>

**Arc rule.** At a simple pole, g = f − c/(z − a) is continuous on a closed disc |z − a| ≤ ε0, so |g| ≤ M there. For ε < ε0 the remainder is at most Mε|β − α|, below any tolerance η > 0 once ε < η/(M|β − α|). The singular part is i(β − α)c exactly.

**sin x/x.** Segments + dent + big arc = 0 for every 0 < ε < R. The dent is within π(e^ε − 1) of −iπ and the arc within π/R; the bounds are separate, so the joint limit holds however ε and R move. So the integral of sin x/x from ε to R tends to π/2.

**Convergence on its own.** Split the half-line at multiples of π. The humps alternate in sign and shrink to 0, so their sums converge: the alternating series test. The integral of |sin x/x| diverges, since the k-th hump is at least 2/((k + 1)π), a harmonic tail.

**Unequal gaps.** Gaps λε and ε give F(λε) − F(ε), which tends to ln λ.

</details>

A second road needs no complex numbers: add the humps of sin x/x between multiples of π, then average neighbouring running totals until they settle. Pushing the pole off the line by a small iδ instead of denting gives the principal value plus or minus iπ times the residue; that split drives The Hilbert transform.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| Residue of e^(iz)/z at 0 | z · e^(iz)/z at z = 0 | 1 |
| Dent's limit | −iπ × 1 | −3.141593i |
| Loop has nothing inside | PV − iπ = 0 | PV = 3.141593i |
| Shutter's area | imaginary part | **3.141593** |
| Second example: residue at i | 1/(i · 2i) | −0.5 |
| Loop | 2πi × (−0.5) | −3.141593i |
| Its principal value | −iπ − (−iπ) | **0** |

Divided by π, the area rebuilds the pulse's middle at brightness 1: fully open.

### The picture: the running area settles on π

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Area under sin x/x from -X to X"
    x-axis "X (frequency units)" [2, 4, 6, 8, 10, 12, 14, 16, 18, 20]
    y-axis "Area (no units)" 2.8 --> 3.6
    line [3.21, 3.52, 2.85, 3.15, 3.32, 3.01, 3.11, 3.26, 3.07, 3.10]
    line [3.14, 3.14, 3.14, 3.14, 3.14, 3.14, 3.14, 3.14, 3.14, 3.14]
```

Orange: the area from −X to X. Teal: π. The swings shrink only like 1/X.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Full residue at the dent | 6.283185 | The dent is half a turn, not a whole one |
| Dent given the anticlockwise sign | −3.141593 | The upper dent runs from angle π down to 0 |
| Left gap 2ε, right gap ε, ε = 0.001 | 0.693146, tending to ln 2 | Unequal gaps are not a principal value |
| Double pole 1/z^2, ε = 0.01 | dent −200 | The half-residue rule needs a simple pole |

---

## Code, from first principles, and it actually runs

Two roads to π. Road one: the residue at 0 by its own limit, then the dent rule. Road two: the humps of sin x/x, each a Simpson sum (area under matched parabolas), then repeated averaging. Every arc is a Simpson sum on its own path. Four asserts: arcs within their bounds; the sin x/x loop sums to 0; the roads agree; the second loop's arc within π/(R^2 − 1), and the loop equal to 2πi times the residue at i.

### Python

```python
# Poles on the path -- the check behind the card.  Standard library only.
# Road one: dent the path round the pole at 0.  The dent keeps -i pi times the
# residue, so PV of e^(ix)/x is i pi and the area under sin x/x is pi.
# Road two: add the humps of sin x/x between multiples of pi, then average the
# partial sums until they settle.  Second example: 1/(x(1+x^2)), PV 0.
import math

def show(w):                                     # 'a + bi', six decimals, no -0.000000
    a, b = round(w.real, 6) + 0.0, round(w.imag, 6) + 0.0
    return f"{a:.6f} {'-' if b < 0 else '+'} {abs(b):.6f}i"
def simpson(g, a, b, n=2000):                    # Simpson's rule on n (even) panels
    h = (b - a) / n
    return h / 3 * (g(a) + g(b) + sum((4 if j % 2 else 2) * g(a + j * h) for j in range(1, n)))
def arc(f, r, start, end):                       # z = r e^(it), dz = i z dt, t from start to end
    return simpson(lambda t: f(r * complex(math.cos(t), math.sin(t))) * 1j * r * complex(math.cos(t), math.sin(t)), start, end)
def wave(z): return complex(math.cos(z.real), math.sin(z.real)) * math.exp(-z.imag) / z   # e^(iz)/z
def rat(z): return 1 / (z * (1 + z * z))         # 1/(z(1+z^2))
def r6(x): return f"{round(x, 6) + 0.0:.6f}"      # six decimals, no -0.000000
def sinc(x): return math.sin(x) / x if x else 1.0
def F(x): return math.log(abs(x)) - 0.5 * math.log(1 + x * x)   # antiderivative of 1/(x(1+x^2)), x not 0

def res(f, a, d=1e-5):                           # residue by its limit (z - a) f(z), from both sides
    return (d * f(a + d) - d * f(a - d)) / 2
c_wave, c_rat, c_i = res(wave, 0j), res(rat, 0j), res(rat, 1j)
print(f"residues by limit: e^(iz)/z at 0 {show(c_wave)}; 1/(z(1+z^2)) at 0 {show(c_rat)}, at i {show(c_i)}")
for eps, R in ((0.5, 5), (0.1, 10), (0.01, 20)):
    dent, big = arc(wave, eps, math.pi, 0), arc(wave, R, 0, math.pi)
    off, bound = abs(dent + 1j * math.pi * c_wave), math.pi * (math.exp(eps) - 1)
    print(f"dent eps = {eps}: {show(dent)}, off -pi i by {off:.6f} (bound {bound:.6f}); big arc R = {R}: size {abs(big):.6f} (Jordan bound {math.pi / R:.6f})")
    assert off <= bound and abs(big) <= math.pi / R
seg = 2j * simpson(sinc, 0.1, 10)                # the two real pieces of e^(ix)/x, eps = 0.1, R = 10
dent, big = arc(wave, 0.1, math.pi, 0), arc(wave, 10, 0, math.pi)
print(f"closed at eps = 0.1, R = 10: segments {show(seg)} + dent {show(dent)} + arc {show(big)} = {show(seg + dent + big)}")
assert abs(seg + dent + big) < 1e-8              # Cauchy: no pole inside, so the loop is 0
road1 = math.pi * c_wave.real                    # PV of e^(ix)/x = -(dent limit) = i pi c
print(f"road 1, dent: PV of e^(ix)/x = {show(1j * road1)}, so area under sin x/x = {road1:.6f}")
sums = [0.0]                                     # road 2: the humps, then repeated averaging
for k in range(40):
    sums.append(sums[-1] + simpson(sinc, k * math.pi, (k + 1) * math.pi, 400))
sums = sums[1:]
for _ in range(20):
    sums = [(p + q) / 2 for p, q in zip(sums, sums[1:])]
road2 = 2 * sums[-1]
print(f"road 2, 40 humps summed and averaged 20 times: {road2:.6f}")
assert abs(road1 - road2) < 1e-9
print("chart, area from -X to X, X = 2, 4, ..., 20:", ", ".join(f"{2 * simpson(sinc, 0, X):.2f}" for X in range(2, 21, 2)), f"(pi {math.pi:.2f})")
for eps in (0.01, 0.0001):
    print(f"1/(x(1+x^2)), gap eps = {eps}: right piece {F(1) - F(eps):.6f}, left piece {F(-eps) - F(-1):.6f}, sum {r6(F(1) - F(eps) + F(-eps) - F(-1))}")
real = F(-0.01) - F(-10) + F(10) - F(0.01)        # both real pieces, eps = 0.01, R = 10
dent, big, loop = arc(rat, 0.01, math.pi, 0), arc(rat, 10, 0, math.pi), 2j * math.pi * c_i
print(f"closed at eps = 0.01, R = 10: real {r6(real)} + dent {show(dent)} + arc {show(big)} (bound {math.pi / 99:.6f}) = {show(real + dent + big)}; 2 pi i x Res at i = {show(loop)}")
assert abs(big) <= math.pi / 99 and abs(real + dent + big - loop) < 1e-8   # arc bound pi/(R^2 - 1)
print(f"PV of 1/(x(1+x^2)) = loop - dent limit = {show(loop + 1j * math.pi * c_rat)}")
print(f"mistake, full residue at 0: {2 * math.pi * c_wave.real:.6f}; dent run anticlockwise: {-road1:.6f}; left gap 2 eps = 0.001: {F(0.002) - F(0.001):.6f} (ln 2 = {math.log(2):.6f})")
print(f"mistake, double pole 1/z^2, dent eps = 0.01: {show(arc(lambda z: 1 / (z * z), 0.01, math.pi, 0))}, though its residue is 0")
o, s = (180, 170), 60                            # figure: 0 at (180, 170), 60 units per 1, R = 2, eps = 0.25
print(f"figure, segments ({o[0] - 2 * s:.2f}, {o[1]:.2f})-({o[0] - s / 4:.2f}, {o[1]:.2f}) and ({o[0] + s / 4:.2f}, {o[1]:.2f})-({o[0] + 2 * s:.2f}, {o[1]:.2f}); dent top ({o[0]:.2f}, {o[1] - s / 4:.2f}); arc top ({o[0]:.2f}, {o[1] - 2 * s:.2f}); i at ({o[0]:.2f}, {o[1] - s:.2f})")
print("ALL CHECKS PASS")
```

**Ran 2026-09-28 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
residues by limit: e^(iz)/z at 0 1.000000 + 0.000000i; 1/(z(1+z^2)) at 0 1.000000 + 0.000000i, at i -0.500000 + 0.000000i
dent eps = 0.5: 0.000000 - 2.155378i, off -pi i by 0.986215 (bound 2.038018); big arc R = 5: size 0.041730 (Jordan bound 0.628319)
dent eps = 0.1: 0.000000 - 2.941704i, off -pi i by 0.199889 (bound 0.330404); big arc R = 10: size 0.175103 (Jordan bound 0.314159)
dent eps = 0.01: 0.000000 - 3.121593i, off -pi i by 0.020000 (bound 0.031574); big arc R = 20: size 0.045109 (Jordan bound 0.157080)
closed at eps = 0.1, R = 10: segments 0.000000 + 3.116806i + dent 0.000000 - 2.941704i + arc 0.000000 - 0.175103i = 0.000000 + 0.000000i
road 1, dent: PV of e^(ix)/x = 0.000000 + 3.141593i, so area under sin x/x = 3.141593
road 2, 40 humps summed and averaged 20 times: 3.141593
chart, area from -X to X, X = 2, 4, ..., 20: 3.21, 3.52, 2.85, 3.15, 3.32, 3.01, 3.11, 3.26, 3.07, 3.10 (pi 3.14)
1/(x(1+x^2)), gap eps = 0.01: right piece 4.258647, left piece -4.258647, sum 0.000000
1/(x(1+x^2)), gap eps = 0.0001: right piece 8.863767, left piece -8.863767, sum 0.000000
closed at eps = 0.01, R = 10: real 0.000000 + dent 0.000000 - 3.141593i + arc 0.000000 + 0.000000i (bound 0.031733) = 0.000000 - 3.141593i; 2 pi i x Res at i = 0.000000 - 3.141593i
PV of 1/(x(1+x^2)) = loop - dent limit = 0.000000 + 0.000000i
mistake, full residue at 0: 6.283185; dent run anticlockwise: -3.141593; left gap 2 eps = 0.001: 0.693146 (ln 2 = 0.693147)
mistake, double pole 1/z^2, dent eps = 0.01: -200.000000 + 0.000000i, though its residue is 0
figure, segments (60.00, 170.00)-(165.00, 170.00) and (195.00, 170.00)-(300.00, 170.00); dent top (180.00, 155.00); arc top (180.00, 50.00); i at (180.00, 110.00)
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Poles on the path -- the same check as the Python, in Rust.  No crates.
// Road one: dent the path round the pole at 0.  The dent keeps -i pi times the
// residue, so PV of e^(ix)/x is i pi and the area under sin x/x is pi.
// Road two: add the humps of sin x/x between multiples of pi, then average the
// partial sums until they settle.  Second example: 1/(x(1+x^2)), PV 0.
use std::f64::consts::PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn div(a: C, b: C) -> C { let d = b.re * b.re + b.im * b.im; c((a.re * b.re + a.im * b.im) / d, (a.im * b.re - a.re * b.im) / d) }
fn scale(a: C, k: f64) -> C { c(a.re * k, a.im * k) }
fn abs(a: C) -> f64 { a.re.hypot(a.im) }
fn r6(x: f64) -> String { let s = format!("{:.6}", x); if s == "-0.000000" { "0.000000".to_string() } else { s } }
fn show(w: C) -> String { // 'a + bi', six decimals, no -0.000000
    let b = format!("{:.6}", w.im.abs());
    format!("{} {} {}i", r6(w.re), if w.im < 0.0 && b != "0.000000" { '-' } else { '+' }, b)
}
fn simpson(g: &dyn Fn(f64) -> C, a: f64, b: f64, n: usize) -> C { // Simpson's rule on n (even) panels
    let h = (b - a) / n as f64;
    let mut s = add(g(a), g(b));
    for j in 1..n { s = add(s, scale(g(a + j as f64 * h), if j % 2 == 1 { 4.0 } else { 2.0 })) }
    scale(s, h / 3.0)
}
fn arc(f: &dyn Fn(C) -> C, r: f64, start: f64, end: f64) -> C { // z = r e^(it), dz = i z dt
    simpson(&|t: f64| { let z = c(r * t.cos(), r * t.sin()); mul(f(z), c(-z.im, z.re)) }, start, end, 2000)
}
fn wave(z: C) -> C { div(scale(c(z.re.cos(), z.re.sin()), (-z.im).exp()), z) } // e^(iz)/z
fn rat(z: C) -> C { div(c(1.0, 0.0), mul(z, add(c(1.0, 0.0), mul(z, z)))) } // 1/(z(1+z^2))
fn sinc(x: f64) -> C { c(if x == 0.0 { 1.0 } else { x.sin() / x }, 0.0) }
fn big_f(x: f64) -> f64 { x.abs().ln() - 0.5 * (1.0 + x * x).ln() } // antiderivative of 1/(x(1+x^2))
fn res(f: fn(C) -> C, a: C) -> C { // residue by its limit (z - a) f(z), from both sides
    let d = 1e-5;
    scale(sub(scale(f(add(a, c(d, 0.0))), d), scale(f(sub(a, c(d, 0.0))), d)), 0.5)
}
fn main() {
    let (c_wave, c_rat, c_i) = (res(wave, c(0.0, 0.0)), res(rat, c(0.0, 0.0)), res(rat, c(0.0, 1.0)));
    println!("residues by limit: e^(iz)/z at 0 {}; 1/(z(1+z^2)) at 0 {}, at i {}", show(c_wave), show(c_rat), show(c_i));
    for (eps, r) in [(0.5f64, 5.0f64), (0.1, 10.0), (0.01, 20.0)] {
        let (dent, big) = (arc(&wave, eps, PI, 0.0), arc(&wave, r, 0.0, PI));
        let (off, bound) = (abs(add(dent, mul(c(0.0, PI), c_wave))), PI * (eps.exp() - 1.0));
        println!("dent eps = {}: {}, off -pi i by {:.6} (bound {:.6}); big arc R = {}: size {:.6} (Jordan bound {:.6})", eps, show(dent), off, bound, r, abs(big), PI / r);
        assert!(off <= bound && abs(big) <= PI / r);
    }
    let seg = mul(c(0.0, 2.0), simpson(&sinc, 0.1, 10.0, 2000)); // the two real pieces of e^(ix)/x
    let (dent, big) = (arc(&wave, 0.1, PI, 0.0), arc(&wave, 10.0, 0.0, PI));
    let total = add(seg, add(dent, big));
    println!("closed at eps = 0.1, R = 10: segments {} + dent {} + arc {} = {}", show(seg), show(dent), show(big), show(total));
    assert!(abs(total) < 1e-8); // Cauchy: no pole inside, so the loop is 0
    let road1 = PI * c_wave.re; // PV of e^(ix)/x = -(dent limit) = i pi c
    println!("road 1, dent: PV of e^(ix)/x = {}, so area under sin x/x = {:.6}", show(c(0.0, road1)), road1);
    let mut sums: Vec<f64> = Vec::new(); // road 2: the humps, then repeated averaging
    let mut acc = 0.0;
    for k in 0..40 { acc += simpson(&sinc, k as f64 * PI, (k + 1) as f64 * PI, 400).re; sums.push(acc) }
    for _ in 0..20 { sums = sums.windows(2).map(|w| (w[0] + w[1]) / 2.0).collect() }
    let road2 = 2.0 * sums[sums.len() - 1];
    println!("road 2, 40 humps summed and averaged 20 times: {:.6}", road2);
    assert!((road1 - road2).abs() < 1e-9);
    let chart: Vec<String> = (1..=10).map(|k| format!("{:.2}", 2.0 * simpson(&sinc, 0.0, 2.0 * k as f64, 2000).re)).collect();
    println!("chart, area from -X to X, X = 2, 4, ..., 20: {} (pi {:.2})", chart.join(", "), PI);
    for eps in [0.01f64, 0.0001] {
        let (right, left) = (big_f(1.0) - big_f(eps), big_f(-eps) - big_f(-1.0));
        println!("1/(x(1+x^2)), gap eps = {}: right piece {:.6}, left piece {:.6}, sum {}", eps, right, left, r6(right + left));
    }
    let real = big_f(-0.01) - big_f(-10.0) + big_f(10.0) - big_f(0.01); // both real pieces, eps = 0.01, R = 10
    let (dent, big, lp) = (arc(&rat, 0.01, PI, 0.0), arc(&rat, 10.0, 0.0, PI), mul(c(0.0, 2.0 * PI), c_i));
    let closed = add(c(real, 0.0), add(dent, big));
    println!("closed at eps = 0.01, R = 10: real {} + dent {} + arc {} (bound {:.6}) = {}; 2 pi i x Res at i = {}", r6(real), show(dent), show(big), PI / 99.0, show(closed), show(lp));
    assert!(abs(big) <= PI / 99.0 && abs(sub(closed, lp)) < 1e-8); // arc bound pi/(R^2 - 1)
    println!("PV of 1/(x(1+x^2)) = loop - dent limit = {}", show(add(lp, mul(c(0.0, PI), c_rat))));
    println!("mistake, full residue at 0: {:.6}; dent run anticlockwise: {:.6}; left gap 2 eps = 0.001: {:.6} (ln 2 = {:.6})", 2.0 * PI * c_wave.re, -road1, big_f(0.002) - big_f(0.001), 2f64.ln());
    println!("mistake, double pole 1/z^2, dent eps = 0.01: {}, though its residue is 0", show(arc(&|z: C| div(c(1.0, 0.0), mul(z, z)), 0.01, PI, 0.0)));
    let (ox, oy, s) = (180.0, 170.0, 60.0); // figure: 0 at (180, 170), 60 units per 1, R = 2, eps = 0.25
    println!("figure, segments ({:.2}, {:.2})-({:.2}, {:.2}) and ({:.2}, {:.2})-({:.2}, {:.2}); dent top ({:.2}, {:.2}); arc top ({:.2}, {:.2}); i at ({:.2}, {:.2})",
        ox - 2.0 * s, oy, ox - s / 4.0, oy, ox + s / 4.0, oy, ox + 2.0 * s, oy, ox, oy - s / 4.0, ox, oy - 2.0 * s, ox, oy - s);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-28 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
residues by limit: e^(iz)/z at 0 1.000000 + 0.000000i; 1/(z(1+z^2)) at 0 1.000000 + 0.000000i, at i -0.500000 + 0.000000i
dent eps = 0.5: 0.000000 - 2.155378i, off -pi i by 0.986215 (bound 2.038018); big arc R = 5: size 0.041730 (Jordan bound 0.628319)
dent eps = 0.1: 0.000000 - 2.941704i, off -pi i by 0.199889 (bound 0.330404); big arc R = 10: size 0.175103 (Jordan bound 0.314159)
dent eps = 0.01: 0.000000 - 3.121593i, off -pi i by 0.020000 (bound 0.031574); big arc R = 20: size 0.045109 (Jordan bound 0.157080)
closed at eps = 0.1, R = 10: segments 0.000000 + 3.116806i + dent 0.000000 - 2.941704i + arc 0.000000 - 0.175103i = 0.000000 + 0.000000i
road 1, dent: PV of e^(ix)/x = 0.000000 + 3.141593i, so area under sin x/x = 3.141593
road 2, 40 humps summed and averaged 20 times: 3.141593
chart, area from -X to X, X = 2, 4, ..., 20: 3.21, 3.52, 2.85, 3.15, 3.32, 3.01, 3.11, 3.26, 3.07, 3.10 (pi 3.14)
1/(x(1+x^2)), gap eps = 0.01: right piece 4.258647, left piece -4.258647, sum 0.000000
1/(x(1+x^2)), gap eps = 0.0001: right piece 8.863767, left piece -8.863767, sum 0.000000
closed at eps = 0.01, R = 10: real 0.000000 + dent 0.000000 - 3.141593i + arc 0.000000 + 0.000000i (bound 0.031733) = 0.000000 - 3.141593i; 2 pi i x Res at i = 0.000000 - 3.141593i
PV of 1/(x(1+x^2)) = loop - dent limit = 0.000000 + 0.000000i
mistake, full residue at 0: 6.283185; dent run anticlockwise: -3.141593; left gap 2 eps = 0.001: 0.693146 (ln 2 = 0.693147)
mistake, double pole 1/z^2, dent eps = 0.01: -200.000000 + 0.000000i, though its residue is 0
figure, segments (60.00, 170.00)-(165.00, 170.00) and (195.00, 170.00)-(300.00, 170.00); dent top (180.00, 155.00); arc top (180.00, 50.00); i at (180.00, 110.00)
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves the arc rule for every simple pole and every arc, and both worked examples exactly.

- Near a simple pole with residue c, the arc from angle α to angle β tends to i(β − α)c as ε shrinks to 0.
- So the upper dent, from π to 0, keeps −iπ times the residue.
- The area under sin x/x from A to B tends to π as A runs to −∞ and B runs to +∞, each on its own.
- For 1/(x(1 + x^2)), equal gaps give a sum that tends to 0 as ε shrinks and R grows: the principal value is 0.
- The piece from ε to 1 grows without bound, and the piece from −1 to −ε falls without bound.
- A left gap 2ε and a right gap ε give a sum that tends to ln 2, not 0.
- The hand arithmetic holds exactly: the residue −1/2 at i, the loop's −iπ, the derivative of F and the double-pole dent −200.

The general principal-value formula, the closed loops and every decimal are left to the Python and Rust checks.

```lean
-- Poles on the path: a shrinking arc round a simple pole picks up i times the angle it sweeps times the residue (so a half-circle dent keeps −iπ times it), the area under sin x/x is π, and the principal value of 1/(x(1 + x²)) is 0 although each side of the pole is infinite.
import Mathlib.Analysis.Analytic.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.ImproperIntegrals
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Sinc
import Mathlib.MeasureTheory.Integral.Prod
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.MeasureTheory.Integral.ExpDecay

namespace IndentedContoursAndPrincipalValues

open Complex Filter Topology

open MeasureTheory in
lemma odd_f (x : ℝ) : 1 / ((-x) * (1 + (-x) ^ 2)) = -(1 / (x * (1 + x ^ 2))) := by
  rw [neg_sq, neg_mul, div_neg]

#print axioms odd_f

open MeasureTheory in
lemma left_eq (a b : ℝ) :
    (∫ x in -b..-a, 1 / (x * (1 + x ^ 2))) = -∫ x in a..b, 1 / (x * (1 + x ^ 2)) := by
  rw [← intervalIntegral.integral_comp_neg (fun x : ℝ => 1 / (x * (1 + x ^ 2)))]
  simp only [odd_f, intervalIntegral.integral_neg]

#print axioms left_eq

open MeasureTheory in
lemma G_eq (a : ℝ) (ha : 0 < a) :
    (∫ x in a..1, 1 / (x * (1 + x ^ 2))) =
      -(Real.log 2 / 2) - Real.log a + Real.log (1 + a ^ 2) / 2 := by
  have hpos : ∀ x ∈ Set.uIcc a 1, 0 < x := by
    intro x hx
    rcases Set.mem_uIcc.mp hx with h | h
    · linarith [h.1]
    · linarith [h.1]
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt
    (f := fun x : ℝ => Real.log x - Real.log (1 + x ^ 2) / 2)]
  · norm_num
    ring
  · intro x hx
    have hx0 := hpos x hx
    have h1 : (1 + x ^ 2) ≠ 0 := by positivity
    have hd := ((Real.hasDerivAt_log hx0.ne').sub
      ((((hasDerivAt_pow 2 x).const_add 1).log h1).div_const 2))
    convert hd using 1
    field_simp
    ring
  · apply ContinuousOn.intervalIntegrable
    apply ContinuousOn.div continuousOn_const (by fun_prop)
    intro x hx
    have := hpos x hx
    positivity

#print axioms G_eq

open MeasureTheory in
lemma dir_inner_exp (x : ℝ) (hx : 0 < x) :
    (∫ t in Set.Ioi (0 : ℝ), Real.exp (-x * t)) = 1 / x := by
  rw [integral_exp_mul_Ioi (by linarith) 0]
  simp

#print axioms dir_inner_exp

open MeasureTheory in
lemma dir_inner_sin (R t : ℝ) :
    (∫ x in (0 : ℝ)..R, Real.sin x * Real.exp (-x * t)) =
      (1 - Real.exp (-R * t) * (t * Real.sin R + Real.cos R)) / (1 + t ^ 2) := by
  have ht : (1 + t ^ 2) ≠ 0 := by positivity
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt
    (f := fun x : ℝ => -(Real.exp (-x * t) * (t * Real.sin x + Real.cos x)) / (1 + t ^ 2))]
  · simp only [neg_zero, zero_mul, Real.exp_zero, Real.sin_zero, Real.cos_zero, mul_zero,
      zero_add, one_mul]
    field_simp
    ring
  · intro x _
    have h1 := (((hasDerivAt_id' x).neg.mul_const t).exp)
    have h2 := ((Real.hasDerivAt_sin x).const_mul t).add (Real.hasDerivAt_cos x)
    have hd := ((h1.mul h2).neg).div_const (1 + t ^ 2)
    convert hd using 1
    simp only [Pi.neg_apply, Pi.add_apply]
    field_simp
    ring
  · exact (by fun_prop : Continuous fun x : ℝ => Real.sin x * Real.exp (-x * t)).intervalIntegrable _ _

#print axioms dir_inner_sin

open MeasureTheory in
lemma dir_integrable (R : ℝ) :
    Integrable (Function.uncurry fun x t : ℝ => Real.sin x * Real.exp (-x * t))
      ((volume.restrict (Set.Ioc (0 : ℝ) R)).prod (volume.restrict (Set.Ioi (0 : ℝ)))) := by
  have hc : Continuous (Function.uncurry fun x t : ℝ => Real.sin x * Real.exp (-x * t)) := by
    show Continuous (fun p : ℝ × ℝ => Real.sin p.1 * Real.exp (-p.1 * p.2))
    fun_prop
  refine (integrable_prod_iff hc.aestronglyMeasurable).mpr ⟨?_, ?_⟩
  · filter_upwards [ae_restrict_mem measurableSet_Ioc] with x hx
    exact (exp_neg_integrableOn_Ioi 0 hx.1).const_mul (Real.sin x)
  · have hint : Integrable (fun x : ℝ => |Real.sinc x|) (volume.restrict (Set.Ioc (0 : ℝ) R)) :=
      Continuous.integrableOn_Ioc (by fun_prop)
    refine hint.congr ?_
    filter_upwards [ae_restrict_mem measurableSet_Ioc] with x hx
    have hx0 : 0 < x := hx.1
    show |Real.sinc x| = ∫ t in Set.Ioi (0 : ℝ), ‖Real.sin x * Real.exp (-x * t)‖
    simp_rw [norm_mul, Real.norm_eq_abs, Real.abs_exp]
    rw [integral_const_mul, dir_inner_exp x hx0, Real.sinc_of_ne_zero hx0.ne', abs_div,
      abs_of_pos hx0]
    ring

#print axioms dir_integrable

open MeasureTheory in
lemma dir_bound (R t : ℝ) :
    ‖Real.exp (-R * t) * (t * Real.sin R + Real.cos R) / (1 + t ^ 2)‖ ≤ 2 * Real.exp (-R * t) := by
  have ht : 0 < 1 + t ^ 2 := by positivity
  have he := Real.exp_pos (-R * t)
  rw [Real.norm_eq_abs, abs_div, abs_mul, Real.abs_exp, abs_of_pos ht, div_le_iff₀ ht]
  have h1 : |t * Real.sin R + Real.cos R| ≤ |t| + 1 := by
    calc |t * Real.sin R + Real.cos R| ≤ |t * Real.sin R| + |Real.cos R| := abs_add_le _ _
      _ ≤ |t| * 1 + 1 := by
        rw [abs_mul]
        gcongr
        · exact Real.abs_sin_le_one R
        · exact Real.abs_cos_le_one R
      _ = |t| + 1 := by ring
  have h2 : |t| ≤ 1 + t ^ 2 := by nlinarith [abs_nonneg t, sq_abs t]
  calc Real.exp (-R * t) * |t * Real.sin R + Real.cos R|
      ≤ Real.exp (-R * t) * (2 * (1 + t ^ 2)) := by
        apply mul_le_mul_of_nonneg_left _ he.le
        nlinarith [sq_nonneg t]
    _ = 2 * Real.exp (-R * t) * (1 + t ^ 2) := by ring

#print axioms dir_bound

open MeasureTheory in
lemma dir_partial (R : ℝ) (hR : 0 < R) :
    (∫ x in (0 : ℝ)..R, Real.sinc x) = Real.pi / 2 -
      ∫ t in Set.Ioi (0 : ℝ), Real.exp (-R * t) * (t * Real.sin R + Real.cos R) / (1 + t ^ 2) := by
  have hk : IntegrableOn (fun t : ℝ =>
      Real.exp (-R * t) * (t * Real.sin R + Real.cos R) / (1 + t ^ 2)) (Set.Ioi 0) := by
    refine Integrable.mono' ((exp_neg_integrableOn_Ioi 0 hR).const_mul 2) ?_
      (Eventually.of_forall fun t => dir_bound R t)
    exact (Continuous.div (by fun_prop) (by fun_prop) (fun t => by positivity) : Continuous fun t : ℝ =>
      Real.exp (-R * t) * (t * Real.sin R + Real.cos R) / (1 + t ^ 2)).aestronglyMeasurable
  rw [intervalIntegral.integral_of_le hR.le]
  calc (∫ x in Set.Ioc 0 R, Real.sinc x)
      = ∫ x in Set.Ioc 0 R, ∫ t in Set.Ioi (0 : ℝ), Real.sin x * Real.exp (-x * t) := by
        refine setIntegral_congr_fun measurableSet_Ioc (fun x hx => ?_)
        have hx0 : 0 < x := hx.1
        rw [integral_const_mul, dir_inner_exp x hx0, Real.sinc_of_ne_zero hx0.ne']
        ring
    _ = ∫ t in Set.Ioi (0 : ℝ), ∫ x in Set.Ioc 0 R, Real.sin x * Real.exp (-x * t) :=
        integral_integral_swap (dir_integrable R)
    _ = ∫ t in Set.Ioi (0 : ℝ), ((1 + t ^ 2)⁻¹ -
          Real.exp (-R * t) * (t * Real.sin R + Real.cos R) / (1 + t ^ 2)) := by
        refine integral_congr_ae (Eventually.of_forall fun t => ?_)
        simp only
        rw [← intervalIntegral.integral_of_le hR.le, dir_inner_sin]
        ring
    _ = Real.pi / 2 - ∫ t in Set.Ioi (0 : ℝ),
          Real.exp (-R * t) * (t * Real.sin R + Real.cos R) / (1 + t ^ 2) := by
        rw [integral_sub integrable_inv_one_add_sq.integrableOn hk, integral_Ioi_inv_one_add_sq,
          Real.arctan_zero, sub_zero]

#print axioms dir_partial

open MeasureTheory in
lemma dir_half : Tendsto (fun R : ℝ => ∫ x in (0 : ℝ)..R, Real.sinc x) atTop
    (𝓝 (Real.pi / 2)) := by
  have hE : Tendsto (fun R : ℝ => ∫ t in Set.Ioi (0 : ℝ),
      Real.exp (-R * t) * (t * Real.sin R + Real.cos R) / (1 + t ^ 2)) atTop (𝓝 0) := by
    have h2 : Tendsto (fun R : ℝ => 2 * R⁻¹) atTop (𝓝 0) := by
      simpa using tendsto_inv_atTop_zero.const_mul (2 : ℝ)
    refine squeeze_zero_norm' ?_ h2
    filter_upwards [eventually_gt_atTop 0] with R hR
    calc _ ≤ ∫ t in Set.Ioi (0 : ℝ), 2 * Real.exp (-R * t) :=
          norm_integral_le_of_norm_le ((exp_neg_integrableOn_Ioi 0 hR).const_mul 2)
            (Eventually.of_forall fun t => dir_bound R t)
      _ = 2 * R⁻¹ := by rw [integral_const_mul, dir_inner_exp R hR, one_div]
  have := hE.const_sub (Real.pi / 2)
  rw [sub_zero] at this
  refine this.congr' ?_
  filter_upwards [eventually_gt_atTop 0] with R hR
  rw [dir_partial R hR]

#print axioms dir_half

open MeasureTheory in
lemma dir_ae_ne : ∀ᵐ x : ℝ, x ≠ 0 := by
  rw [ae_iff]
  simp

#print axioms dir_ae_ne

open MeasureTheory in
lemma dir_split (a b : ℝ) : (∫ x in a..b, Real.sin x / x) =
    (∫ x in (0 : ℝ)..(-a), Real.sinc x) + ∫ x in (0 : ℝ)..b, Real.sinc x := by
  have h1 : (∫ x in a..b, Real.sin x / x) = ∫ x in a..b, Real.sinc x := by
    refine intervalIntegral.integral_congr_ae ?_
    filter_upwards [dir_ae_ne] with x hx _
    rw [Real.sinc_of_ne_zero hx]
  have h2 : (∫ x in (0 : ℝ)..(-a), Real.sinc x) = ∫ x in a..0, Real.sinc x := by
    have h := intervalIntegral.integral_comp_neg (a := a) (b := 0) (f := Real.sinc)
    simp only [Real.sinc_neg, neg_zero] at h
    exact h.symm
  rw [h1, h2, intervalIntegral.integral_add_adjacent_intervals
    (Real.continuous_sinc.intervalIntegrable _ _) (Real.continuous_sinc.intervalIntegrable _ _)]

#print axioms dir_split

/-- The card's main claim, the arc rule. Let f have a simple pole at a with residue c: near a
(but not at a) f(z) = c/(z − a) + g(z), where g is holomorphic at a. Let Γ_ε be the arc
z = a + εe^(it), t running from α to β, so dz = iεe^(it) dt. Then as the radius ε shrinks to 0
the integral of f along Γ_ε tends to i(β − α)c: i times the angle swept times the residue.
The upper dent runs from π to 0, so it keeps −iπ times the residue. -/
theorem arc_integral_tendsto_I_mul_angle_mul_residue
    (f g : ℂ → ℂ) (a c : ℂ) (α β : ℝ)
    (hg : AnalyticAt ℂ g a)
    (hf : ∀ᶠ z in 𝓝[≠] a, f z = c / (z - a) + g z) :
    Tendsto
      (fun ε : ℝ ↦ ∫ t in α..β,
        f (a + (ε : ℂ) * exp ((t : ℂ) * I)) * ((ε : ℂ) * I * exp ((t : ℂ) * I)))
      (𝓝[>] 0) (𝓝 (I * ((β : ℂ) - α) * c)) := by
  rw [eventually_nhdsWithin_iff, Metric.eventually_nhds_iff] at hf
  obtain ⟨r, hr, hfr⟩ := hf
  have hg2 : ∀ᶠ z in 𝓝 a, AnalyticAt ℂ g z ∧ dist (g z) (g a) < 1 :=
    hg.eventually_analyticAt.and
      (Metric.tendsto_nhds.mp hg.continuousAt 1 one_pos)
  obtain ⟨δ, hδ, hgδ⟩ := Metric.eventually_nhds_iff.mp hg2
  set M := ‖g a‖ + 1
  have hnorm : ∀ t : ℝ, ‖exp ((t : ℂ) * I)‖ = 1 := fun t => Complex.norm_exp_ofReal_mul_I t
  have hdist : ∀ (ε : ℝ) (t : ℝ), 0 < ε →
      dist (a + (ε : ℂ) * exp ((t : ℂ) * I)) a = ε := by
    intro ε t hε
    rw [dist_eq_norm, add_sub_cancel_left, norm_mul, hnorm, mul_one, Complex.norm_real,
      Real.norm_eq_abs, abs_of_pos hε]
  rw [tendsto_iff_norm_sub_tendsto_zero]
  have hbound : ∀ᶠ ε : ℝ in 𝓝[>] (0 : ℝ),
      ‖(∫ t in α..β,
        f (a + (ε : ℂ) * exp ((t : ℂ) * I)) * ((ε : ℂ) * I * exp ((t : ℂ) * I)))
        - I * ((β : ℂ) - α) * c‖ ≤ M * |β - α| * ε := by
    have hmem : Set.Ioo (0 : ℝ) (min r δ) ∈ 𝓝[>] (0 : ℝ) :=
      Ioo_mem_nhdsGT (lt_min hr hδ)
    filter_upwards [hmem] with ε hε
    obtain ⟨hε0, hε1⟩ := hε
    have hεr : ε < r := lt_of_lt_of_le hε1 (min_le_left _ _)
    have hεδ : ε < δ := lt_of_lt_of_le hε1 (min_le_right _ _)
    set z : ℝ → ℂ := fun t => a + (ε : ℂ) * exp ((t : ℂ) * I) with hz
    have hzd : ∀ t, dist (z t) a = ε := fun t => hdist ε t hε0
    have hεC : (ε : ℂ) ≠ 0 := by exact_mod_cast hε0.ne'
    have hpt : ∀ t : ℝ, f (z t) * ((ε : ℂ) * I * exp ((t : ℂ) * I)) =
        c * I + g (z t) * ((ε : ℂ) * I * exp ((t : ℂ) * I)) := by
      intro t
      have hne : z t ≠ a := by
        intro h
        have := hzd t
        rw [h, dist_self] at this
        linarith
      rw [hfr (by rw [hzd t]; exact hεr) hne]
      have hsub : z t - a = (ε : ℂ) * exp ((t : ℂ) * I) := by simp [hz]
      rw [hsub]
      have he : exp ((t : ℂ) * I) ≠ 0 := Complex.exp_ne_zero _
      field_simp
    have hcont : Continuous (fun t : ℝ => g (z t) * ((ε : ℂ) * I * exp ((t : ℂ) * I))) := by
      refine Continuous.mul ?_ (by fun_prop)
      rw [continuous_iff_continuousAt]
      intro t
      have hzc : Continuous z := by fun_prop
      exact ((hgδ (by rw [hzd t]; exact hεδ)).1.continuousAt).comp hzc.continuousAt
    rw [intervalIntegral.integral_congr (g := fun t : ℝ =>
        c * I + g (z t) * ((ε : ℂ) * I * exp ((t : ℂ) * I))) (fun t _ => hpt t)]
    rw [intervalIntegral.integral_add intervalIntegrable_const (hcont.intervalIntegrable _ _),
      intervalIntegral.integral_const, Complex.real_smul]
    have hrw : ((β - α : ℝ) : ℂ) * (c * I) +
        (∫ t in α..β, g (z t) * ((ε : ℂ) * I * exp ((t : ℂ) * I))) - I * ((β : ℂ) - α) * c
        = ∫ t in α..β, g (z t) * ((ε : ℂ) * I * exp ((t : ℂ) * I)) := by
      push_cast; ring
    rw [hrw]
    have := intervalIntegral.norm_integral_le_of_norm_le_const (a := α) (b := β) (C := M * ε)
      (f := fun t : ℝ => g (z t) * ((ε : ℂ) * I * exp ((t : ℂ) * I))) (by
        intro t _
        rw [norm_mul, norm_mul, norm_mul, hnorm, Complex.norm_I, Complex.norm_real,
          Real.norm_eq_abs, abs_of_pos hε0, mul_one, mul_one]
        refine mul_le_mul_of_nonneg_right ?_ hε0.le
        have h1 := (hgδ (by rw [hzd t]; exact hεδ)).2
        rw [dist_eq_norm] at h1
        have h2 := norm_le_norm_add_norm_sub' (g (z t)) (g a)
        simp only [M]
        linarith)
    calc _ ≤ M * ε * |β - α| := this
      _ = M * |β - α| * ε := by ring
  refine squeeze_zero' (Eventually.of_forall fun _ => norm_nonneg _) hbound ?_
  have : Tendsto (fun ε : ℝ => M * |β - α| * ε) (𝓝 0) (𝓝 (M * |β - α| * 0)) :=
    (continuous_const.mul continuous_id).tendsto 0
  rw [mul_zero] at this
  exact this.mono_left nhdsWithin_le_nhds

/-- The shutter's area. The integral of sin x/x from A to B tends to π as A runs to −∞ and B
runs to +∞, each end on its own: the area under sin x/x over the whole line is π. -/
theorem integral_sin_div_self_tendsto_pi :
    Tendsto (fun p : ℝ × ℝ ↦ ∫ x in p.1..p.2, Real.sin x / x) (atBot ×ˢ atTop)
      (𝓝 Real.pi) := by
  simp_rw [dir_split]
  have := (dir_half.comp (tendsto_neg_atBot_atTop.comp tendsto_fst)).add
    (dir_half.comp (tendsto_snd (f := (atBot : Filter ℝ)) (g := (atTop : Filter ℝ))))
  rw [add_halves] at this
  exact this

/-- The second example, f(x) = 1/(x(1 + x²)), with its pole at 0 on the path.
1. The principal value is 0: cut equal gaps (−ε, ε) round 0, integrate from −R to −ε and from
   ε to R, and the sum tends to 0 as ε shrinks to 0 and R grows.
2. The right piece, from ε to 1, grows without bound as ε shrinks to 0.
3. The left piece, from −1 to −ε, falls without bound as ε shrinks to 0. So the ordinary integral
   does not exist.
4. Unequal gaps give a different answer: a left gap 2ε and a right gap ε give ln 2, not 0. -/
theorem principal_value_inv_mul_one_add_sq_eq_zero :
    Tendsto (fun p : ℝ × ℝ ↦
        (∫ x in -p.2..-p.1, 1 / (x * (1 + x ^ 2))) + ∫ x in p.1..p.2, 1 / (x * (1 + x ^ 2)))
      (𝓝[>] 0 ×ˢ atTop) (𝓝 0) ∧
    Tendsto (fun ε : ℝ ↦ ∫ x in ε..1, 1 / (x * (1 + x ^ 2))) (𝓝[>] 0) atTop ∧
    Tendsto (fun ε : ℝ ↦ ∫ x in (-1)..-ε, 1 / (x * (1 + x ^ 2))) (𝓝[>] 0) atBot ∧
    Tendsto (fun ε : ℝ ↦
        (∫ x in (-1)..-(2 * ε), 1 / (x * (1 + x ^ 2))) + ∫ x in ε..1, 1 / (x * (1 + x ^ 2)))
      (𝓝[>] 0) (𝓝 (Real.log 2)) := by
  have h2 : Tendsto (fun ε : ℝ ↦ ∫ x in ε..1, 1 / (x * (1 + x ^ 2))) (𝓝[>] 0) atTop := by
    have hlim : Tendsto (fun ε : ℝ ↦ -(Real.log 2 / 2) + -Real.log ε) (𝓝[>] 0) atTop :=
      tendsto_atTop_add_const_left _ _ (tendsto_neg_atBot_atTop.comp Real.tendsto_log_nhdsGT_zero)
    refine tendsto_atTop_mono' _ ?_ hlim
    filter_upwards [self_mem_nhdsWithin] with ε hε
    rw [G_eq ε hε]
    have : 0 ≤ Real.log (1 + ε ^ 2) := Real.log_nonneg (by nlinarith)
    linarith
  refine ⟨?_, h2, ?_, ?_⟩
  · have : (fun p : ℝ × ℝ ↦
        (∫ x in -p.2..-p.1, 1 / (x * (1 + x ^ 2))) + ∫ x in p.1..p.2, 1 / (x * (1 + x ^ 2)))
        = fun _ => 0 := by
      funext p
      rw [left_eq]
      ring
    rw [this]
    exact tendsto_const_nhds
  · have : (fun ε : ℝ ↦ ∫ x in (-1)..-ε, 1 / (x * (1 + x ^ 2)))
        = fun ε => -∫ x in ε..1, 1 / (x * (1 + x ^ 2)) := by
      funext ε
      exact left_eq ε 1
    rw [this]
    exact tendsto_neg_atTop_atBot.comp h2
  · have hc : Continuous (fun ε : ℝ =>
        Real.log 2 + (Real.log (1 + ε ^ 2) - Real.log (1 + (2 * ε) ^ 2)) / 2) := by
      have h1 : Continuous (fun ε : ℝ => Real.log (1 + ε ^ 2)) :=
        Continuous.log (by fun_prop) (fun x => by positivity)
      have h2 : Continuous (fun ε : ℝ => Real.log (1 + (2 * ε) ^ 2)) :=
        Continuous.log (by fun_prop) (fun x => by positivity)
      fun_prop
    have hl := (hc.tendsto 0).mono_left (nhdsWithin_le_nhds (s := Set.Ioi 0))
    simp only [ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true, zero_pow, add_zero, Real.log_one,
      mul_zero, sub_self, zero_div] at hl
    refine hl.congr' ?_
    filter_upwards [self_mem_nhdsWithin] with ε hε
    have hε' : (0 : ℝ) < ε := hε
    rw [left_eq, G_eq ε hε', G_eq (2 * ε) (by linarith), Real.log_mul (by norm_num) hε'.ne']
    ring

/-- Residue of 1/(z(1 + z²)) at i: 1/(i · 2i) = −1/2. -/
example : (1 : ℂ) / (I * (2 * I)) = -1 / 2 := by
  rw [show I * (2 * I) = 2 * (I * I) by ring, I_mul_I]; norm_num

/-- The loop is 2πi × (−1/2) = −iπ; take away the dent's −iπ × 1 and the principal value is 0. -/
example : 2 * (Real.pi : ℂ) * I * (-1 / 2) - (-(I * Real.pi) * 1) = 0 := by ring

/-- F(x) = ln|x| − ½ ln(1 + x²) has derivative 1/x − x/(1 + x²), which is 1/(x(1 + x²)). -/
example (x : ℝ) (hx : x ≠ 0) : 1 / x - x / (1 + x ^ 2) = 1 / (x * (1 + x ^ 2)) := by
  have h : (1 + x ^ 2) ≠ 0 := by positivity
  field_simp; ring

/-- The double-pole dent for 1/z² is −2/ε: at ε = 1/100 it is −200. -/
example : (-2 : ℝ) / (1 / 100) = -200 := by norm_num

#print axioms arc_integral_tendsto_I_mul_angle_mul_residue
#print axioms integral_sin_div_self_tendsto_pi
#print axioms principal_value_inv_mul_one_add_sq_eq_zero

end IndentedContoursAndPrincipalValues
```

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'IndentedContoursAndPrincipalValues.odd_f' depends on axioms: [propext, Classical.choice, Quot.sound]
'IndentedContoursAndPrincipalValues.left_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'IndentedContoursAndPrincipalValues.G_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'IndentedContoursAndPrincipalValues.dir_inner_exp' depends on axioms: [propext, Classical.choice, Quot.sound]
'IndentedContoursAndPrincipalValues.dir_inner_sin' depends on axioms: [propext, Classical.choice, Quot.sound]
'IndentedContoursAndPrincipalValues.dir_integrable' depends on axioms: [propext, Classical.choice, Quot.sound]
'IndentedContoursAndPrincipalValues.dir_bound' depends on axioms: [propext, Classical.choice, Quot.sound]
'IndentedContoursAndPrincipalValues.dir_partial' depends on axioms: [propext, Classical.choice, Quot.sound]
'IndentedContoursAndPrincipalValues.dir_half' depends on axioms: [propext, Classical.choice, Quot.sound]
'IndentedContoursAndPrincipalValues.dir_ae_ne' depends on axioms: [propext, Classical.choice, Quot.sound]
'IndentedContoursAndPrincipalValues.dir_split' depends on axioms: [propext, Classical.choice, Quot.sound]
'IndentedContoursAndPrincipalValues.arc_integral_tendsto_I_mul_angle_mul_residue' depends on axioms: [propext, Classical.choice, Quot.sound]
'IndentedContoursAndPrincipalValues.integral_sin_div_self_tendsto_pi' depends on axioms: [propext, Classical.choice, Quot.sound]
'IndentedContoursAndPrincipalValues.principal_value_inv_mul_one_add_sq_eq_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **Forget dz.** In `arc`, delete `1j * r * `. The first assert stops it: the dent at ε = 0.5 misses its bound.
> - **The whole residue.** Set `road1 = 2 * math.pi * c_wave.real`. It reads 6.283185; the road assert stops it.
> - **Fewer averagings.** Change `range(20)` to `range(2)`. Road two misses π in the sixth decimal and the road assert stops it.

---

## The usual mistake

> [!warning]
> **Letting the dent shrink to nothing.** Round a simple pole the function grows like 1/ε exactly as the arc's length shrinks like ε, so the dent stays at −iπ times the residue. Drop it and sin x/x comes out at 0.
>
> - **Counting the pole fully.** That gives 6.283185. Dent below instead and the pole is inside: dent +iπ, loop 2πi, principal value iπ again.
> - **Principal value read as an ordinary integral.** For 1/(x(1 + x^2)) each side is infinite, 8.863767 at ε = 0.0001.
> - **Unmatched gaps.** Left gap twice the right gives ln 2, not 0.

---

## Where you meet it in real life

- **Optics and cameras.** A slit or a shutter has a sin x/x profile; its area π fixes the rebuilt pulse's height.
- **Signal processing.** An ideal low-pass filter, keeping frequencies below a cut-off, smooths with a sin x/x kernel.
- **Physics.** Poles on the real frequency axis are pushed off by a small iδ: a principal value plus or minus iπ times a residue.
- **Analytic signals.** The principal value against 1/(x − t) is the Hilbert transform: The Hilbert transform.

> **Say it back**
> A pole on the path is stepped round on a tiny half-circle. At a simple pole that half-circle keeps −iπ times the residue. The real line then carries the principal value: equal gaps cut round the pole. For e^(ix)/x nothing is inside, so the area under sin x/x is π. For 1/(x(1 + x^2)) each side is infinite, but the principal value is 0.

---

## What this builds on

- [Jordan's lemma](03-oscillatory-integrals-and-jordans-lemma.md): the factor e^(iz) and the bound π/R that makes the big arc fade.

## Where this goes next

- The Hilbert transform: the principal value against 1/(x − t) as a transform in its own right.

A dent handles one pole; taking the principal value against 1/(x − t) at every t at once is an operation on whole signals, and what it does to a wave is the Hilbert transform.

---

## Sources

Verified 2026-11-11: every link below resolves to the publisher's page.

- Orloff, Jeremy. "Topic 9: Definite integrals using the residue theorem." MIT OpenCourseWare 18.04, Spring 2018. [Course notes](https://ocw.mit.edu/courses/18-04-complex-variables-with-applications-spring-2018/resources/mit18_04s18_topic9/). Principal values, the half-residue arc theorem and indented contours.
- Stein, Elias M., and Rami Shakarchi. *Complex Analysis*. Princeton University Press, 2003. [Publisher page](https://press.princeton.edu/books/hardcover/9780691113852/complex-analysis). Chapter 2's exercises reach the integral of sin x/x on an indented semicircle.
