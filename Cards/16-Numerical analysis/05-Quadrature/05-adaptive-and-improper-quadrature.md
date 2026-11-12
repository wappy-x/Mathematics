# Adaptive quadrature and awkward integrals: spend points where the function misbehaves

[Syllabus](../../../SYLLABUS.md) → [Numerical analysis](../README.md) → [Quadrature](../README.md#s05) → Adaptive quadrature and awkward integrals

---

## General Overview

A factory's power feeder draws a steady 2 megawatts (MW) all day. Around 18:00 the furnaces fire, and the draw surges to 10 MW for about half an hour. The utility bills the day's energy in megawatt-hours (MWh). The number wanted is that energy to within one kilowatt-hour: 0.001 MWh. The load curve is illustrative, and its exact energy is 54.1721241571 MWh, so every answer below can be graded.

Energy is the area under the load curve: an integral. A quadrature rule estimates it by a weighted sum of the curve's values at chosen points. Spread the points evenly and most land on flat hours. The surge gets only a few.

**Adaptive quadrature** works differently. It cuts the day into **panels** (sub-intervals) and estimates the error on each one. It then splits only the panel with the largest estimated error, and repeats. It stops when the estimates add up to less than the tolerance.

On this load it used 255 function values and finished with a true error of 3.797e-10 MWh. A meter read every ten minutes uses 145 values and is off by 1.003e-3 MWh, a whole kilowatt-hour.

The same tool handles two awkward kinds of integral: one out to infinity, and one whose integrand goes infinite at an end. A **substitution** (a change of variable) turns each into a well-behaved integral on a finite interval. The card's second example is Planck's radiation integral, out to infinity, which gives the Stefan–Boltzmann constant to all ten printed digits.

**Estimate each panel's error by comparing two rules that share their points, split the worst panel until the estimates add up to less than the tolerance, and first turn an infinite range or an end spike into a tame finite integral by a change of variable.**

**What kind of fact this is:** a method with an error estimate, not an error bound. The degrees of exactness (13 and 23) and the substitution rule are theorems, proved on this card in Why it works, except one step: that the 8 new Kronrod nodes are real and inside the panel is stated with a source. The estimate can fail, and the card shows it failing.

### The picture: how densely the final nine panels sample

Each panel gets 15 points, so a narrow panel means dense sampling. Points per hour in each of the nine final panels:

```
 0.00-12.00 h  #                       1.25
12.00-15.00 h  #####                   5.00
15.00-16.50 h  ##########             10.00
16.50-17.25 h  ####################   20.00
17.25-18.00 h  ####################   20.00
18.00-18.75 h  ####################   20.00
18.75-19.50 h  ####################   20.00
19.50-21.00 h  ##########             10.00
21.00-24.00 h  #####                   5.00
```

The four panels around 18:00 get 20 points per hour. The twelve quiet night hours share one panel at 1.25 points per hour. The bars show only the nine final panels; the values spent on panels that were later split are not drawn.

---

## The formula

Notation from [Trapezoid, midpoint and Simpson](01-newton-cotes-and-composite-rules.md): a rule's **nodes** are the points where it samples $f$, its **weights** say how much each sample counts, and its **degree of exactness** is the highest degree of polynomial it integrates exactly. The 7-point Gauss rule, exact to degree 13, comes from [Gaussian quadrature](03-gaussian-quadrature.md).

On one panel $[a, b]$, write $c = (a+b)/2$ for its centre and $h = (b-a)/2$ for its half-width. Two rules use the same 15 points:

$$K = h \sum_{i=1}^{15} w_i\, f(c + h x_i), \qquad G = h \sum_{j=1}^{7} v_j\, f(c + h x_{2j})$$

The panel's error estimate, and the rule for the whole interval:

$$\text{estimate} = |K - G|, \qquad \text{split the worst panel until } \sum_{\text{panels}} |K - G| \le \tau$$

Two substitutions make awkward integrals finite and smooth:

$$\int_0^\infty f(x)\,dx = \int_0^1 f\!\left(\frac{u}{1-u}\right)\frac{du}{(1-u)^2}, \qquad \int_0^1 f(x)\,dx = \int_0^1 f(u^2)\,2u\,du$$

**Read it aloud:** the Kronrod sum K samples a panel at 15 points, the Gauss sum G reuses 7 of them, and their gap estimates the error. Keep splitting the panel with the biggest gap until the gaps add up to less than tau, after rewriting any infinite range or end spike in a new variable u on a finite interval.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $f$, $x$, $I$ | the integrand, its variable, and its true integral over one panel | the load; Planck's $x^3/(e^x - 1)$ | — |
| $L(t)$, $t$ | the load in MW at time $t$ in hours; its integral over the day is the exact energy | $2 + 8/(1 + ((t-18)/0.25)^2)$; exact energy 54.1721241571 MWh | — |
| $[a, b]$, $c$, $h$ | one panel, its centre and its half-width | first panel 0 to 24 hours: 12 hours and 12 hours | wider: more error in that panel |
| $x_i$ | the 15 Kronrod nodes on $[-1, 1]$, in increasing order; $x_2, x_4, \dots, x_{14}$ are the 7 Gauss nodes | 0, ±0.2078, …, ±0.9915 | — |
| $w_i$, $v_j$ | Kronrod weights and Gauss weights | at the centre, 0.2095 and 0.4180 | — |
| $K$, $G$ | the 15-point Kronrod sum and the 7-point Gauss sum on a panel | first panel: 50.0744320662 and 50.0348993221 MWh | — |
| $\lvert K - G \rvert$ | the panel's error estimate | first panel: 3.953e-2 MWh | that panel is split sooner |
| $\tau$ | tolerance: the allowed sum of estimates. Say "tau". | 1e-3 MWh, one kilowatt-hour | fewer function values, a looser answer |
| $u$ | the new variable in a substitution | $u = x/(1+x)$ for Planck; $u = \sqrt{x}$ for $1/\sqrt{x}$ | — |
| $p$, $m$ | the power of an end spike $x^{-p}$, and the power in the substitution $x = u^m$ | $p$ = 1/2, $m$ = 2 | a bigger $p$ needs a bigger $m$ |
| $P_7$, $E_8$, $q$, $s$, $r$ | in the proof: the Legendre polynomial of degree 7, the polynomial whose roots are the 8 new nodes, and helper polynomials | — | — |

### When it holds

- **The integrand can be evaluated anywhere.** Adaptivity chooses its own points. Fixed meter readings every ten minutes cannot be split, and their trapezoid sum is off by 1.003e-3 MWh.
- **The integrand is smooth on each final panel.** Where it is not, as $1/\sqrt{x}$ at 0, splitting still converges, but slowly: 1395 values for 1e-8. A substitution does it with 15.
- **Every feature shows up in the first samples.** A surge 36 seconds wide that falls between the first 15 nodes is invisible: the estimate reads 1.996e-5 and the true error is −1.248e-1 MWh. Start from more panels, or put a panel edge at any known event.
- **The tolerance is above rounding level.** At $\tau$ = 1e-6 the answer already agrees with the closed form to rounding level. Asking for 1e-12 costs 735 values and buys nothing.
- **For an infinite range, $f(x)$ falls at least as fast as $1/x^2$.** The mapped integrand equals $f(x)(1+x)^2$, so it stays finite at $u = 1$ only then. Planck's integrand falls like $x^3 e^{-x}$, far faster.

---

## Why it works

### Step 0: the error lives where the curve bends

A rule with degree of exactness 13 is nearly exact on any panel where $f$ looks like a polynomial of degree 13. The flat night hours are such a panel. The surge is not.

The total error is the sum of the panel errors. So new function values cut the total most in the panel with the largest error. The method needs an error estimate for each panel and a rule for which panel to split.

### Step 1: two rules from one set of points

To estimate the error of a rule, compare it with a better rule. A second Gauss rule would cost new points: a 15-point Gauss rule shares only the centre with the 7-point one.

The Kronrod idea keeps the 7 Gauss nodes and adds 8 new ones. That leaves 8 free node positions and 15 free weights: 23 numbers. A rule with 23 free numbers can match 23 conditions, the integrals of $1, x, \dots, x^{22}$. Symmetry adds one more for free: the nodes and weights are mirror images about 0, so the rule gives 0 for the odd power $x^{23}$, and so does the true integral. So the 15-point Kronrod rule is exact to degree 23, and its error estimate comes from the same 15 function values.

The code checks the table three ways:

- the Gauss nodes from Newton's method on the Legendre polynomial $P_7$ match the table with a gap of 0;
- the Kronrod weights, solved from 8 moment equations, match with a gap of 8.327e-17;
- on $[-1, 1]$ the Gauss rule's error on $x^{12}$ is −2.776e-17 and on $x^{14}$ is −1.855e-4; the Kronrod rule's error on $x^{22}$ is −4.163e-17, on $x^{23}$ is 0.000e0 and on $x^{24}$ is 5.733e-9.

So the degrees are exactly 13 and 23.

<details>
<summary>Detailed proof: why the 8 new nodes give degree 23</summary>

Write $P_7$ for the Legendre polynomial whose roots are the Gauss nodes, and $E_8$ for the monic polynomial whose roots are the 8 new nodes. Choose the 15 weights so that the rule is exact on every polynomial of degree 14 or less. Fifteen distinct nodes always allow this (the interpolatory weights).

Take any polynomial $q$ of degree at most 22. Divide it by $P_7 E_8$, which has degree 15:

$$q = s\,P_7 E_8 + r, \qquad \deg s \le 7, \quad \deg r \le 14.$$

The product $P_7 E_8$ is zero at all 15 nodes, so the rule gives 0 for $s P_7 E_8$. It is exact on $r$. So the rule is exact on $q$ if and only if

$$\int_{-1}^{1} s(x)\,P_7(x)\,E_8(x)\,dx = 0 \quad \text{for every } s \text{ of degree} \le 7.$$

That is 8 linear conditions on the 8 free coefficients of $E_8$. For the Legendre case they have a unique solution, the Stieltjes polynomial. That its 8 roots are real, inside $(-1, 1)$ and interlaced with the Gauss nodes is a separate theorem for the Legendre case, stated here without proof. The paper on computing Kronrod rules in the Sources shows how to find them.

The last degree comes from symmetry. For $q$ of degree 23 the quotient $s$ has degree 8, and its extra term $x^8$ contributes $x^8 P_7 E_8$. That is an odd function, since $P_7$ is odd and $x^8$ and $E_8$ are even (the new nodes come in pairs $\pm x$), so its integral over $[-1, 1]$ is 0. The condition still holds, and the rule is exact to degree 23. The code's $x^{24}$ test shows it fails at degree 24.

</details>

### Step 2: the gap between the rules estimates the worse rule's error

Write $I$ for the true integral on a panel. Then

$$K - G = (I - G) - (I - K).$$

On a panel where $f$ is smooth, $K$ is far more accurate than $G$. So $|K - G|$ is close to the error of $G$, the worse rule. The method still returns $K$.

On the load at $\tau$ = 1e-3, the nine $G$ values add to 54.1721831077 MWh, a true error of 5.895e-5. The estimate is 5.897e-5: almost exactly $G$'s error. The returned $K$ sum has a true error of 3.797e-10. The estimate is 155297 times the true error, which is safe but pessimistic. Library codes such as QUADPACK rescale the gap to cut this waste.

On a panel where neither rule sees the shape, both miss together. The first panel, the whole day, gives $K$ = 50.0744320662 and $G$ = 50.0348993221. The estimate is 3.953e-2 MWh, but the true error is 4.098 MWh. The estimate is too small, and the method continues only because 3.953e-2 is above $\tau$.

### Step 3: always split the worst panel

Each round, the method halves the panel with the largest estimate and runs both rules on each half, for 30 new values. It stops when the estimates add up to $\tau$ or less.

On a smooth panel, halving pays off fast. By the Gauss error formula from [Gaussian quadrature](03-gaussian-quadrature.md), the error on a panel of half-width $h$ is a constant times $h^{15}$ times the 14th derivative of $f$ somewhere in the panel. Halving $h$ divides it by about 2 to the 15th. A panel that still straddles the surge keeps a large estimate and is split again.

The cost grows slowly as the tolerance tightens:

| Tolerance $\tau$ (MWh) | Function values | Panels | Estimate | True error |
| --- | ---: | ---: | --- | --- |
| 1e-3 | 255 | 9 | 5.897e-5 | 3.797e-10 |
| 1e-6 | 315 | 11 | 1.346e-7 | 0.000e0 |
| 1e-9 | 405 | 14 | 1.985e-10 | 0.000e0 |
| 1e-12 | 735 | 25 | 7.454e-13 | 0.000e0 |

A true error of 0.000e0 means the sum and the closed form round to the same double. Both carry rounding error, so the true error is at rounding level, not known to be zero; adding in another order can move the last bit.

Uniform panels with the same 15-point rule, for comparison:

| Panels | Function values | True error | Observed order |
| ---: | ---: | --- | ---: |
| 4 | 60 | 2.809e-3 | — |
| 8 | 120 | 1.138e-4 | 4.6 |
| 16 | 240 | 4.419e-7 | 8.0 |
| 32 | 480 | 3.798e-10 | 10.2 |

The observed order is log2 of the drop in error when the panels double. The theorem's order for the 15-point rule is 24 (each panel's error falls like $h^{25}$, and there are about $1/h$ panels), reached only once panels are much narrower than the surge; here rounding level arrives first. Uniform panels need 480 values to match what adaptivity did with 255.

### Step 4: an infinite range becomes a finite one

Substitute $x = u/(1-u)$. As $u$ runs from 0 toward 1, $x$ runs from 0 toward infinity. The slope is $dx/du = 1/(1-u)^2$, so the substitution rule from calculus gives the first identity in The formula. Since $1/(1-u) = 1 + x$, the new integrand is $f(x)(1+x)^2$.

Planck's law says how a hot body's radiation is spread over photon energies. Measure the photon energy $x$ in units of the thermal energy: Boltzmann's constant times the temperature. The total radiation is then proportional to

$$\int_0^\infty \frac{x^3}{e^x - 1}\,dx = \frac{\pi^4}{15} = 6.49393940227.$$

The mapped integrand is finite on $[0, 1)$ and falls to 0 as $u \to 1$. Near $x = 0$ the formula reads 0/0, but the integrand tends to 0 like $x^2$, and no node of a Gauss or Kronrod rule sits on an end of its panel. So neither end is ever evaluated.

The adaptive run on the mapped integral, at $\tau$ = 1e-10, used 285 values. Its estimate was 1.112e-11 and its true error 8.882e-16.

The other approach, cutting the range off, needs a known tail:

| Cut off at | Value | Missing |
| ---: | --- | --- |
| x = 10 | 6.43192189678 | 6.202e-2 |
| x = 20 | 6.49392017995 | 1.922e-5 |
| x = 40 | 6.49393940227 | 2.922e-13, at rounding level |

At x = 40 the missing part is so small that rounding in the total blurs its third digit. The cut-off works only with a good guess of where the tail ends. The substitution needs no guess.

### Step 5: an end spike becomes a constant

The integral of $1/\sqrt{x}$ from 0 to 1 is 2. The integrand goes infinite at 0, and no polynomial looks like it there.

Uniform panels crawl. With 1, 4, 16 and 64 panels the errors are −4.568e-2, −2.284e-2, −1.142e-2 and −5.710e-3. Each fourfold refinement only halves the error: an order of 0.5 in $h$, against 24 for a smooth integrand.

The reason is scaling. On the first panel $[0, 2h]$, the integrand is the same shape at every size, so the rule misses the same fraction of that panel's area, $2\sqrt{2h}$. The error shrinks like $\sqrt{h}$ however small $h$ gets. Adaptivity keeps halving that first panel and reaches 1e-8 after 1395 values.

Substitute $x = u^2$. Then $dx = 2u\,du$ and $1/\sqrt{x} = 1/u$, so the new integrand is $2u/u = 2$, a constant. One panel of 15 values gives the answer with error 0.000e0.

In general a spike like $x^{-p}$, with $p$ below 1, becomes bounded under $x = u^m$ once $m(1-p) \ge 1$, since the new integrand is $m\,u^{m(1-p)-1}$. The **tanh-sinh** (double exponential) rule applies one substitution that flattens both ends of any interval at once; the double exponential paper in the Sources introduced it. **Clenshaw–Curtis** rules, whose points are cosines, offer another nested pair: doubling the points reuses the old ones, which gives an error estimate as cheaply as Kronrod's.

---

## Worked numbers, by hand

The load: 2 MW plus a surge to 10 MW at 18:00, tolerance one kilowatt-hour.

| Step | Arithmetic | Value |
| --- | --- | --- |
| exact energy | 48 + 2(atan 24 + atan 72) | 54.1721241571 MWh |
| first panel, 0 to 24 hours | $K - G$ = 50.0744320662 − 50.0348993221 | estimate 3.953e-2 > 1e-3: split |
| its true error | 54.1721241571 − 50.0744320662 | 4.098 MWh |
| keep splitting the worst panel | stop at 9 panels | estimates add to 5.897e-5 ≤ 1e-3 |
| function values | 15 × (2 × 9 − 1) | 255 |
| sampling near 18:00 | 15 ÷ 0.75 hours | 20.00 points per hour |
| sampling at night | 15 ÷ 12 hours | 1.25 points per hour |
| **answer** | sum of the nine $K$ values | **54.1721241575 MWh**, true error 3.797e-10 |

The energy is known far better than the kilowatt-hour asked for, and most of the 255 values went to the surge.

Planck, out to infinity:

| Step | Arithmetic | Value |
| --- | --- | --- |
| map $x = u/(1-u)$ | adaptive on $[0, 1)$, $\tau$ = 1e-10 | 285 values |
| integral | against π^4/15 = 6.49393940227 | 6.49393940227, true error 8.882e-16 |
| Stefan–Boltzmann constant | 2π × (Boltzmann's constant)^4 × integral ÷ ((Planck's constant)^3 × (speed of light)^2) | 5.670374419e-8 W/(m^2 K^4) |
| the sun's surface at 5772 K | constant × 5772^4 | **62.9 MW per m^2** |

Every square metre of the sun's surface radiates about 62.9 megawatts. The constant matches the published exact value to all ten digits printed.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| One starting panel on a surge 36 seconds wide (half-width 0.005 hours) | 48.000868 against 48.125619 MWh: true error −1.248e-1, estimate 1.996e-5 | all 15 first nodes missed the surge, so both rules agreed on the wrong answer |
| Return the Gauss sums instead of the Kronrod sums | 54.1721831077 MWh, true error 5.895e-5 | the estimate measures the worse rule; return the better one |
| Cut Planck's range off at x = 10 | 6.43192189678, missing 6.202e-2 | the tail beyond the cut was never counted |
| Uniform panels on $1/\sqrt{x}$, 64 panels | true error −5.710e-3 | the spike sets an order of 0.5; no amount of refinement fixes the first panel |

Starting from 24 hourly panels fixes the first row: 600 values, true error −2.605e-6.

---

## Code, from first principles, and it actually runs

The code checks the Gauss–Kronrod table three ways (Newton's method on $P_7$, 8 moment equations, exactness on powers of $x$), then runs the adaptive method on the load, Planck's integral and $1/\sqrt{x}$. Every answer meets an independent road: a closed form (atan, π^4/15 or 2), with uniform panels, a ten-minute trapezoid sum or a cut-off range as a third. The Python adds left to right with its own `total`, because its built-in `sum` rounds more carefully than Rust's loop and the outputs must match digit for digit.

### Python

```python
# Adaptive quadrature and awkward integrals -- the check behind the card.
# Standard library only: math gives atan, cos, exp, sqrt and pi. Every rule, weight
# and integral is computed here. Load in MW, time in hours, energy in MWh.
import math
from functools import reduce

XK = [0.991455371120812639, 0.949107912342758525, 0.864864423359769073, 0.741531185599394440,
      0.586087235467691130, 0.405845151377397167, 0.207784955007898468, 0.0]  # Kronrod nodes, x >= 0
WK = [0.022935322010529225, 0.063092092629978553, 0.104790010322250184, 0.140653259715525919,
      0.169004726639267903, 0.190350578064785410, 0.204432940075298892, 0.209482141084727828]
WG = [0.129484966168869693, 0.279705391489276668, 0.381830050505118945, 0.417959183673469388]  # Gauss: XK[1], XK[3], XK[5], XK[7]

def ef(x, d=3):                           # e-notation with the same text as Rust's {:.de}
    m, p = f"{x:.{d}e}".split("e")
    return f"{m}e{int(p)}"

def total(xs): return reduce(lambda s, x: s + x, xs, 0.0)  # plain left-to-right sum, as in Rust

def pw(x, n):                             # x to the n by repeated multiplication
    r = 1.0
    for _ in range(n):
        r *= x
    return r

def legendre(n, x):                       # P_n(x) and its slope, by the three-term recurrence
    p0, p1 = 0.0, 1.0
    for k in range(1, n + 1):
        p0, p1 = p1, ((2 * k - 1) * x * p1 - (k - 1) * p0) / k
    return p1, n * (x * p1 - p0) / (x * x - 1)

def kg(f, a, b):                          # Kronrod 15-point K and Gauss 7-point G on [a, b]
    c, h = (a + b) / 2, (b - a) / 2
    fc = f(c)
    k, g = WK[7] * fc, WG[3] * fc
    for i in range(7):
        s = f(c - h * XK[i]) + f(c + h * XK[i])
        k += WK[i] * s
        if i % 2 == 1:
            g += WG[i // 2] * s
    return k * h, g * h

def est(p): return abs(p[2] - p[3])       # a panel's error estimate |K - G|

def adaptive(f, a, b, tol, start=1):      # split the worst panel until the estimates sum to <= tol
    cuts = [a + (b - a) * j / start for j in range(start + 1)]
    ps = [(lo, hi) + kg(f, lo, hi) for lo, hi in zip(cuts, cuts[1:])]
    while total(est(p) for p in ps) > tol and len(ps) < 500:
        w = max(range(len(ps)), key=lambda j: est(ps[j]))
        lo, hi, _, _ = ps.pop(w)
        mid = (lo + hi) / 2
        ps += [(lo, mid) + kg(f, lo, mid), (mid, hi) + kg(f, mid, hi)]
    return total(p[2] for p in ps), total(est(p) for p in ps), 15 * (2 * len(ps) - start), ps

def uniform(f, a, b, n): return total(kg(f, a + (b - a) * j / n, a + (b - a) * (j + 1) / n)[0] for j in range(n))

# ---- 1. the rule's table, checked three ways ----
gn, gw = [], []
for i in range(4):                        # Newton on P_7 from a cosine guess
    x = math.cos(math.pi * (i + 0.75) / 7.5)
    for _ in range(8): p, dp = legendre(7, x); x -= p / dp
    gn.append(x)
    gw.append(2 / ((1 - x * x) * legendre(7, x)[1] * legendre(7, x)[1]))
dn = max(abs(gn[i] - XK[2 * i + 1]) for i in range(4))
dw = max(abs(gw[i] - WG[i]) for i in range(4))
print(f"Gauss nodes: Newton on P_7 vs table, max gap {ef(dn)}; weights 2/((1-x^2)P_7'(x)^2), max gap {ef(dw)}")
A = [[legendre(2 * m, x)[0] * (2 if i < 7 else 1) for i, x in enumerate(XK)] + [2.0 if m == 0 else 0.0] for m in range(8)]
for c in range(8):                        # Kronrod weights from 8 moment equations, Gaussian elimination
    r = max(range(c, 8), key=lambda r: abs(A[r][c])); A[c], A[r] = A[r], A[c]
    for r in range(c + 1, 8):
        q = A[r][c] / A[c][c]
        A[r] = [u - q * v for u, v in zip(A[r], A[c])]
wk = [0.0] * 8
for c in range(7, -1, -1):
    wk[c] = (A[c][8] - total(A[c][j] * wk[j] for j in range(c + 1, 8))) / A[c][c]
dk = max(abs(wk[i] - WK[i]) for i in range(8))
print(f"Kronrod weights from the moment equations vs table, max gap {ef(dk)}")
ex = {n: kg(lambda x: pw(x, n), -1, 1) for n in (12, 14, 22, 23, 24)}
print(f"exactness on [-1, 1]: G7 errors x^12 {ef(ex[12][1] - 2 / 13)}, x^14 {ef(ex[14][1] - 2 / 15)}; "
      f"K15 errors x^22 {ef(ex[22][0] - 2 / 23)}, x^23 {ef(ex[23][0])}, x^24 {ef(ex[24][0] - 2 / 25)}")
assert dn < 1e-15 and dw < 1e-15 and dk < 1e-14
assert abs(ex[22][0] - 2 / 23) < 1e-15 and abs(ex[23][0]) < 1e-15 and abs(ex[24][0] - 2 / 25) > 1e-9 and abs(ex[14][1] - 2 / 15) > 1e-6

# ---- 2. the peaked load: 2 MW all day plus a surge to 10 MW at 18:00, half-width 0.25 h ----
def surge(w): return lambda t: 2 + 8 / (1 + ((t - 18) / w) * ((t - 18) / w))
def surge_exact(w): return 48 + 8 * w * (math.atan(6 / w) + math.atan(18 / w))
load, E = surge(0.25), surge_exact(0.25)
print(f"load: exact energy 48 + 2(atan 24 + atan 72) = {E:.10f} MWh")
K0, G0 = kg(load, 0, 24)
print(f"first panel, 0 to 24 h: K15 {K0:.10f}, G7 {G0:.10f}, estimate {ef(abs(K0 - G0))}, true error {ef(abs(K0 - E))}")
v, e, n, ps = adaptive(load, 0, 24, 1e-3)
gsum = total(p[3] for p in ps)
print(f"adaptive, tol 1e-3: {v:.10f} MWh, estimate {ef(e)}, true error {ef(abs(v - E))}, "
      f"estimate / true {abs(e / (v - E)):.0f}, {n} evaluations, {len(ps)} panels")
for p in sorted(ps):
    print(f"  panel {p[0]:5.2f} to {p[1]:5.2f} h: {15 / (p[1] - p[0]):5.2f} points per hour")
print(f"same panels, G7 values summed: {gsum:.10f} MWh, true error {ef(abs(gsum - E))}")
assert abs(v - E) <= e <= 1e-3 and abs(gsum - E) > 1e-6
for tol in (1e-6, 1e-9, 1e-12):
    v2, e2, n2, p2 = adaptive(load, 0, 24, tol)
    print(f"adaptive, tol {ef(tol, 0)}: {n2} evaluations, {len(p2)} panels, estimate {ef(e2)}, true error {ef(abs(v2 - E))}")
ue = [abs(uniform(load, 0, 24, m) - E) for m in (4, 8, 16, 32)]
for j, m in enumerate((4, 8, 16, 32)):
    order = f", observed order {math.log2(ue[j - 1] / ue[j]):.1f}" if j else ""
    print(f"uniform, {m} panels, {15 * m} evaluations: true error {ef(ue[j])}{order}")
hh = 24 / 144
trap = hh * (total(load(j * hh) for j in range(145)) - (load(0) + load(24)) / 2)
print(f"ten-minute readings, trapezoid on 145 values: {trap:.10f} MWh, true error {ef(trap - E)}")
assert ue[1] > 1e-4 and 1e-9 > abs(v - E) and trap - E > 9e-4

# ---- 3. out to infinity: Planck's integral of x^3/(e^x - 1) from 0 to infinity is pi^4/15 ----
def planck(x): return 0.0 if x > 700 else x * x * x / (math.exp(x) - 1)
def mapped(t): return planck(t / (1 - t)) / ((1 - t) * (1 - t))  # x = t/(1 - t) takes [0, 1) to [0, infinity)
P = pw(math.pi, 4) / 15
v, e, n, ps = adaptive(mapped, 0, 1, 1e-10)
print(f"Planck: pi^4/15 = {P:.11f}; mapped to [0, 1): {v:.11f}, estimate {ef(e)}, true error {ef(abs(v - P))}, {n} evaluations")
assert abs(v - P) < 1e-10
sig = 2 * math.pi * pw(1.380649e-23, 4) * v / (pw(6.62607015e-34, 3) * pw(299792458.0, 2))
print(f"Stefan-Boltzmann constant from it: {ef(sig, 9)} W/(m^2 K^4); the sun at 5772 K: {sig * pw(5772.0, 4) / 1e6:.1f} MW per m^2")
for L in (10, 20, 40):
    vl, el, nl, pl = adaptive(planck, 0, L, 1e-10)
    print(f"cut off at x = {L}: {vl:.11f}, missing {ef(P - vl)}, {nl} evaluations")

# ---- 4. a spike at an end: the integral of 1/sqrt(x) from 0 to 1 is 2 ----
inv_sqrt = lambda x: 1 / math.sqrt(x)
se = [uniform(inv_sqrt, 0, 1, m) - 2 for m in (1, 4, 16, 64)]
print(f"1/sqrt(x), uniform 1, 4, 16, 64 panels: errors {', '.join(ef(s) for s in se)}")
v, e, n, ps = adaptive(inv_sqrt, 0, 1, 1e-8)
sub = kg(lambda u: 2 * u / math.sqrt(u * u), 0, 1)[0]
print(f"adaptive, tol 1e-8: error {ef(v - 2)}, {n} evaluations; substitute x = u^2: one panel, error {ef(sub - 2)}")
assert all(abs(se[j] / se[j + 1] - 2) < 1e-6 for j in range(3)) and abs(sub - 2) < 1e-15

# ---- 5. the trap: a surge 36 seconds wide (half-width 0.005 h) that one panel never sees ----
spike, S = surge(0.005), surge_exact(0.005)
v1, e1, n1, _ = adaptive(spike, 0, 24, 1e-3)
v24, e24, n24, _ = adaptive(spike, 0, 24, 1e-3, start=24)
print(f"spike: exact {S:.6f} MWh; from 1 panel {v1:.6f}, estimate {ef(e1)}, true error {ef(v1 - S)}, {n1} evaluations")
print(f"spike: from 24 hourly panels {v24:.6f}, estimate {ef(e24)}, true error {ef(v24 - S)}, {n24} evaluations")
assert S - v1 > 0.1 and 1e-3 > abs(v24 - S)
print("ALL CHECKS PASS")
```

**Ran 2026-11-11 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
Gauss nodes: Newton on P_7 vs table, max gap 0.000e0; weights 2/((1-x^2)P_7'(x)^2), max gap 1.110e-16
Kronrod weights from the moment equations vs table, max gap 8.327e-17
exactness on [-1, 1]: G7 errors x^12 -2.776e-17, x^14 -1.855e-4; K15 errors x^22 -4.163e-17, x^23 0.000e0, x^24 5.733e-9
load: exact energy 48 + 2(atan 24 + atan 72) = 54.1721241571 MWh
first panel, 0 to 24 h: K15 50.0744320662, G7 50.0348993221, estimate 3.953e-2, true error 4.098e0
adaptive, tol 1e-3: 54.1721241575 MWh, estimate 5.897e-5, true error 3.797e-10, estimate / true 155297, 255 evaluations, 9 panels
  panel  0.00 to 12.00 h:  1.25 points per hour
  panel 12.00 to 15.00 h:  5.00 points per hour
  panel 15.00 to 16.50 h: 10.00 points per hour
  panel 16.50 to 17.25 h: 20.00 points per hour
  panel 17.25 to 18.00 h: 20.00 points per hour
  panel 18.00 to 18.75 h: 20.00 points per hour
  panel 18.75 to 19.50 h: 20.00 points per hour
  panel 19.50 to 21.00 h: 10.00 points per hour
  panel 21.00 to 24.00 h:  5.00 points per hour
same panels, G7 values summed: 54.1721831077 MWh, true error 5.895e-5
adaptive, tol 1e-6: 315 evaluations, 11 panels, estimate 1.346e-7, true error 0.000e0
adaptive, tol 1e-9: 405 evaluations, 14 panels, estimate 1.985e-10, true error 0.000e0
adaptive, tol 1e-12: 735 evaluations, 25 panels, estimate 7.454e-13, true error 0.000e0
uniform, 4 panels, 60 evaluations: true error 2.809e-3
uniform, 8 panels, 120 evaluations: true error 1.138e-4, observed order 4.6
uniform, 16 panels, 240 evaluations: true error 4.419e-7, observed order 8.0
uniform, 32 panels, 480 evaluations: true error 3.798e-10, observed order 10.2
ten-minute readings, trapezoid on 145 values: 54.1731272643 MWh, true error 1.003e-3
Planck: pi^4/15 = 6.49393940227; mapped to [0, 1): 6.49393940227, estimate 1.112e-11, true error 8.882e-16, 285 evaluations
Stefan-Boltzmann constant from it: 5.670374419e-8 W/(m^2 K^4); the sun at 5772 K: 62.9 MW per m^2
cut off at x = 10: 6.43192189678, missing 6.202e-2, 105 evaluations
cut off at x = 20: 6.49392017995, missing 1.922e-5, 165 evaluations
cut off at x = 40: 6.49393940227, missing 2.922e-13, 225 evaluations
1/sqrt(x), uniform 1, 4, 16, 64 panels: errors -4.568e-2, -2.284e-2, -1.142e-2, -5.710e-3
adaptive, tol 1e-8: error -5.445e-9, 1395 evaluations; substitute x = u^2: one panel, error 0.000e0
spike: exact 48.125619 MWh; from 1 panel 48.000868, estimate 1.996e-5, true error -1.248e-1, 15 evaluations
spike: from 24 hourly panels 48.125617, estimate 4.340e-4, true error -2.605e-6, 600 evaluations
ALL CHECKS PASS
```

### Rust

The same check, built with `rustc --edition 2021 -O`.

```rust
// Adaptive quadrature and awkward integrals -- the same check as the Python, in Rust.
// std only: atan, cos, exp, sqrt and pi are primitives. Every rule, weight and
// integral is computed here. Load in MW, time in hours, energy in MWh.

const XK: [f64; 8] = [0.991455371120812639, 0.949107912342758525, 0.864864423359769073, 0.741531185599394440,
    0.586087235467691130, 0.405845151377397167, 0.207784955007898468, 0.0]; // Kronrod nodes, x >= 0
const WK: [f64; 8] = [0.022935322010529225, 0.063092092629978553, 0.104790010322250184, 0.140653259715525919,
    0.169004726639267903, 0.190350578064785410, 0.204432940075298892, 0.209482141084727828];
const WG: [f64; 4] = [0.129484966168869693, 0.279705391489276668, 0.381830050505118945, 0.417959183673469388];
// WG are the 7-point Gauss weights at XK[1], XK[3], XK[5] and XK[7] = 0
type Panel = (f64, f64, f64, f64); // (lo, hi, K, G)

fn ef(x: f64, d: usize) -> String { format!("{:.*e}", d, x) }

fn pw(x: f64, n: u32) -> f64 { // x to the n by repeated multiplication
    let mut r = 1.0;
    for _ in 0..n { r *= x; }
    r
}

fn legendre(n: usize, x: f64) -> (f64, f64) { // P_n(x) and its slope, three-term recurrence
    let (mut p0, mut p1) = (0.0, 1.0);
    for k in 1..=n {
        let p2 = ((2 * k - 1) as f64 * x * p1 - (k - 1) as f64 * p0) / k as f64;
        p0 = p1;
        p1 = p2;
    }
    (p1, n as f64 * (x * p1 - p0) / (x * x - 1.0))
}

fn kg(f: &dyn Fn(f64) -> f64, a: f64, b: f64) -> (f64, f64) { // Kronrod 15-point K and Gauss 7-point G
    let (c, h) = ((a + b) / 2.0, (b - a) / 2.0);
    let fc = f(c);
    let (mut k, mut g) = (WK[7] * fc, WG[3] * fc);
    for i in 0..7 {
        let s = f(c - h * XK[i]) + f(c + h * XK[i]);
        k += WK[i] * s;
        if i % 2 == 1 { g += WG[i / 2] * s; }
    }
    (k * h, g * h)
}

fn est(p: &Panel) -> f64 { (p.2 - p.3).abs() } // a panel's error estimate |K - G|

fn panel(f: &dyn Fn(f64) -> f64, lo: f64, hi: f64) -> Panel { let (k, g) = kg(f, lo, hi); (lo, hi, k, g) }

fn adaptive(f: &dyn Fn(f64) -> f64, a: f64, b: f64, tol: f64, start: usize) -> (f64, f64, usize, Vec<Panel>) {
    let cut = |j: usize| a + (b - a) * j as f64 / start as f64;
    let mut ps: Vec<Panel> = (0..start).map(|j| panel(f, cut(j), cut(j + 1))).collect();
    while ps.iter().fold(0.0, |s, p| s + est(p)) > tol && ps.len() < 500 {
        let mut w = 0;
        for j in 1..ps.len() { if est(&ps[j]) > est(&ps[w]) { w = j; } }
        let (lo, hi, _, _) = ps.remove(w);
        let mid = (lo + hi) / 2.0;
        ps.push(panel(f, lo, mid));
        ps.push(panel(f, mid, hi));
    }
    let v = ps.iter().fold(0.0, |s, p| s + p.2);
    let e = ps.iter().fold(0.0, |s, p| s + est(p));
    (v, e, 15 * (2 * ps.len() - start), ps)
}

fn uniform(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    (0..n).fold(0.0, |s, j| s + kg(f, a + (b - a) * j as f64 / n as f64, a + (b - a) * (j + 1) as f64 / n as f64).0)
}

fn surge(w: f64) -> impl Fn(f64) -> f64 { move |t: f64| 2.0 + 8.0 / (1.0 + ((t - 18.0) / w) * ((t - 18.0) / w)) }
fn surge_exact(w: f64) -> f64 { 48.0 + 8.0 * w * ((6.0 / w).atan() + (18.0 / w).atan()) }
fn planck(x: f64) -> f64 { if x > 700.0 { 0.0 } else { x * x * x / (x.exp() - 1.0) } }

fn main() {
    // ---- 1. the rule's table, checked three ways ----
    let (mut gn, mut gw) = (vec![], vec![]);
    for i in 0..4 { // Newton on P_7 from a cosine guess
        let mut x = (std::f64::consts::PI * (i as f64 + 0.75) / 7.5).cos();
        for _ in 0..8 { let (p, dp) = legendre(7, x); x -= p / dp; }
        gn.push(x);
        let dp = legendre(7, x).1;
        gw.push(2.0 / ((1.0 - x * x) * dp * dp));
    }
    let dn = (0..4).map(|i| (gn[i] - XK[2 * i + 1]).abs()).fold(0.0, f64::max);
    let dw = (0..4).map(|i| (gw[i] - WG[i]).abs()).fold(0.0, f64::max);
    println!("Gauss nodes: Newton on P_7 vs table, max gap {}; weights 2/((1-x^2)P_7'(x)^2), max gap {}", ef(dn, 3), ef(dw, 3));
    let mut a: Vec<Vec<f64>> = (0..8).map(|m| {
        let mut row: Vec<f64> = (0..8).map(|i| legendre(2 * m, XK[i]).0 * if i < 7 { 2.0 } else { 1.0 }).collect();
        row.push(if m == 0 { 2.0 } else { 0.0 });
        row
    }).collect();
    for c in 0..8 { // Kronrod weights from 8 moment equations, Gaussian elimination
        let mut r = c;
        for j in c + 1..8 { if a[j][c].abs() > a[r][c].abs() { r = j; } }
        a.swap(c, r);
        for r in c + 1..8 {
            let q = a[r][c] / a[c][c];
            let pivot = a[c].clone();
            for (u, v) in a[r].iter_mut().zip(pivot.iter()) { *u = *u - q * v; }
        }
    }
    let mut wk = [0.0; 8];
    for c in (0..8).rev() {
        let s = (c + 1..8).fold(0.0, |s, j| s + a[c][j] * wk[j]);
        wk[c] = (a[c][8] - s) / a[c][c];
    }
    let dk = (0..8).map(|i| (wk[i] - WK[i]).abs()).fold(0.0, f64::max);
    println!("Kronrod weights from the moment equations vs table, max gap {}", ef(dk, 3));
    let ex = |n: u32| kg(&|x: f64| pw(x, n), -1.0, 1.0);
    let (e12, e14, e22, e23, e24) = (ex(12).1 - 2.0 / 13.0, ex(14).1 - 2.0 / 15.0, ex(22).0 - 2.0 / 23.0, ex(23).0, ex(24).0 - 2.0 / 25.0);
    println!("exactness on [-1, 1]: G7 errors x^12 {}, x^14 {}; K15 errors x^22 {}, x^23 {}, x^24 {}", ef(e12, 3), ef(e14, 3), ef(e22, 3), ef(e23, 3), ef(e24, 3));
    assert!(dn < 1e-15 && dw < 1e-15 && dk < 1e-14);
    assert!(e22.abs() < 1e-15 && e23.abs() < 1e-15 && e24.abs() > 1e-9 && e14.abs() > 1e-6);

    // ---- 2. the peaked load: 2 MW all day plus a surge to 10 MW at 18:00, half-width 0.25 h ----
    let (load, big_e) = (surge(0.25), surge_exact(0.25));
    println!("load: exact energy 48 + 2(atan 24 + atan 72) = {:.10} MWh", big_e);
    let (k0, g0) = kg(&load, 0.0, 24.0);
    println!("first panel, 0 to 24 h: K15 {:.10}, G7 {:.10}, estimate {}, true error {}", k0, g0, ef((k0 - g0).abs(), 3), ef((k0 - big_e).abs(), 3));
    let (v, e, n, mut ps) = adaptive(&load, 0.0, 24.0, 1e-3, 1);
    let gsum = ps.iter().fold(0.0, |s, p| s + p.3);
    println!("adaptive, tol 1e-3: {:.10} MWh, estimate {}, true error {}, estimate / true {:.0}, {} evaluations, {} panels",
             v, ef(e, 3), ef((v - big_e).abs(), 3), (e / (v - big_e)).abs(), n, ps.len());
    ps.sort_by(|p, q| p.0.partial_cmp(&q.0).unwrap());
    for p in &ps { println!("  panel {:5.2} to {:5.2} h: {:5.2} points per hour", p.0, p.1, 15.0 / (p.1 - p.0)); }
    println!("same panels, G7 values summed: {:.10} MWh, true error {}", gsum, ef((gsum - big_e).abs(), 3));
    assert!((v - big_e).abs() <= e && e <= 1e-3 && (gsum - big_e).abs() > 1e-6);
    for tol in [1e-6, 1e-9, 1e-12] {
        let (v2, e2, n2, p2) = adaptive(&load, 0.0, 24.0, tol, 1);
        println!("adaptive, tol {}: {} evaluations, {} panels, estimate {}, true error {}", ef(tol, 0), n2, p2.len(), ef(e2, 3), ef((v2 - big_e).abs(), 3));
    }
    let ms = [4usize, 8, 16, 32];
    let ue: Vec<f64> = ms.iter().map(|&m| (uniform(&load, 0.0, 24.0, m) - big_e).abs()).collect();
    for j in 0..4 {
        let order = if j > 0 { format!(", observed order {:.1}", (ue[j - 1] / ue[j]).log2()) } else { String::new() };
        println!("uniform, {} panels, {} evaluations: true error {}{}", ms[j], 15 * ms[j], ef(ue[j], 3), order);
    }
    let hh = 24.0 / 144.0;
    let trap = hh * ((0..145).fold(0.0, |s, j| s + load(j as f64 * hh)) - (load(0.0) + load(24.0)) / 2.0);
    println!("ten-minute readings, trapezoid on 145 values: {:.10} MWh, true error {}", trap, ef(trap - big_e, 3));
    assert!(ue[1] > 1e-4 && 1e-9 > (v - big_e).abs() && trap - big_e > 9e-4);

    // ---- 3. out to infinity: Planck's integral of x^3/(e^x - 1) from 0 to infinity is pi^4/15 ----
    let mapped = |t: f64| planck(t / (1.0 - t)) / ((1.0 - t) * (1.0 - t)); // x = t/(1 - t): [0, 1) to [0, infinity)
    let big_p = pw(std::f64::consts::PI, 4) / 15.0;
    let (v, e, n, _) = adaptive(&mapped, 0.0, 1.0, 1e-10, 1);
    println!("Planck: pi^4/15 = {:.11}; mapped to [0, 1): {:.11}, estimate {}, true error {}, {} evaluations", big_p, v, ef(e, 3), ef((v - big_p).abs(), 3), n);
    assert!((v - big_p).abs() < 1e-10);
    let sig = 2.0 * std::f64::consts::PI * pw(1.380649e-23, 4) * v / (pw(6.62607015e-34, 3) * pw(299792458.0, 2));
    println!("Stefan-Boltzmann constant from it: {} W/(m^2 K^4); the sun at 5772 K: {:.1} MW per m^2", ef(sig, 9), sig * pw(5772.0, 4) / 1e6);
    for l in [10.0, 20.0, 40.0] {
        let (vl, _, nl, _) = adaptive(&planck, 0.0, l, 1e-10, 1);
        println!("cut off at x = {}: {:.11}, missing {}, {} evaluations", l, vl, ef(big_p - vl, 3), nl);
    }

    // ---- 4. a spike at an end: the integral of 1/sqrt(x) from 0 to 1 is 2 ----
    let inv_sqrt = |x: f64| 1.0 / x.sqrt();
    let se: Vec<f64> = [1usize, 4, 16, 64].iter().map(|&m| uniform(&inv_sqrt, 0.0, 1.0, m) - 2.0).collect();
    println!("1/sqrt(x), uniform 1, 4, 16, 64 panels: errors {}", se.iter().map(|s| ef(*s, 3)).collect::<Vec<_>>().join(", "));
    let (v, _, n, _) = adaptive(&inv_sqrt, 0.0, 1.0, 1e-8, 1);
    let sub = kg(&|u: f64| 2.0 * u / (u * u).sqrt(), 0.0, 1.0).0;
    println!("adaptive, tol 1e-8: error {}, {} evaluations; substitute x = u^2: one panel, error {}", ef(v - 2.0, 3), n, ef(sub - 2.0, 3));
    assert!((0..3).all(|j| (se[j] / se[j + 1] - 2.0).abs() < 1e-6) && (sub - 2.0).abs() < 1e-15);

    // ---- 5. the trap: a surge 36 seconds wide (half-width 0.005 h) that one panel never sees ----
    let (spike, s) = (surge(0.005), surge_exact(0.005));
    let (v1, e1, n1, _) = adaptive(&spike, 0.0, 24.0, 1e-3, 1);
    let (v24, e24, n24, _) = adaptive(&spike, 0.0, 24.0, 1e-3, 24);
    println!("spike: exact {:.6} MWh; from 1 panel {:.6}, estimate {}, true error {}, {} evaluations", s, v1, ef(e1, 3), ef(v1 - s, 3), n1);
    println!("spike: from 24 hourly panels {:.6}, estimate {}, true error {}, {} evaluations", v24, ef(e24, 3), ef(v24 - s, 3), n24);
    assert!(s - v1 > 0.1 && 1e-3 > (v24 - s).abs());
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-11 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
Gauss nodes: Newton on P_7 vs table, max gap 0.000e0; weights 2/((1-x^2)P_7'(x)^2), max gap 1.110e-16
Kronrod weights from the moment equations vs table, max gap 8.327e-17
exactness on [-1, 1]: G7 errors x^12 -2.776e-17, x^14 -1.855e-4; K15 errors x^22 -4.163e-17, x^23 0.000e0, x^24 5.733e-9
load: exact energy 48 + 2(atan 24 + atan 72) = 54.1721241571 MWh
first panel, 0 to 24 h: K15 50.0744320662, G7 50.0348993221, estimate 3.953e-2, true error 4.098e0
adaptive, tol 1e-3: 54.1721241575 MWh, estimate 5.897e-5, true error 3.797e-10, estimate / true 155297, 255 evaluations, 9 panels
  panel  0.00 to 12.00 h:  1.25 points per hour
  panel 12.00 to 15.00 h:  5.00 points per hour
  panel 15.00 to 16.50 h: 10.00 points per hour
  panel 16.50 to 17.25 h: 20.00 points per hour
  panel 17.25 to 18.00 h: 20.00 points per hour
  panel 18.00 to 18.75 h: 20.00 points per hour
  panel 18.75 to 19.50 h: 20.00 points per hour
  panel 19.50 to 21.00 h: 10.00 points per hour
  panel 21.00 to 24.00 h:  5.00 points per hour
same panels, G7 values summed: 54.1721831077 MWh, true error 5.895e-5
adaptive, tol 1e-6: 315 evaluations, 11 panels, estimate 1.346e-7, true error 0.000e0
adaptive, tol 1e-9: 405 evaluations, 14 panels, estimate 1.985e-10, true error 0.000e0
adaptive, tol 1e-12: 735 evaluations, 25 panels, estimate 7.454e-13, true error 0.000e0
uniform, 4 panels, 60 evaluations: true error 2.809e-3
uniform, 8 panels, 120 evaluations: true error 1.138e-4, observed order 4.6
uniform, 16 panels, 240 evaluations: true error 4.419e-7, observed order 8.0
uniform, 32 panels, 480 evaluations: true error 3.798e-10, observed order 10.2
ten-minute readings, trapezoid on 145 values: 54.1731272643 MWh, true error 1.003e-3
Planck: pi^4/15 = 6.49393940227; mapped to [0, 1): 6.49393940227, estimate 1.112e-11, true error 8.882e-16, 285 evaluations
Stefan-Boltzmann constant from it: 5.670374419e-8 W/(m^2 K^4); the sun at 5772 K: 62.9 MW per m^2
cut off at x = 10: 6.43192189678, missing 6.202e-2, 105 evaluations
cut off at x = 20: 6.49392017995, missing 1.922e-5, 165 evaluations
cut off at x = 40: 6.49393940227, missing 2.922e-13, 225 evaluations
1/sqrt(x), uniform 1, 4, 16, 64 panels: errors -4.568e-2, -2.284e-2, -1.142e-2, -5.710e-3
adaptive, tol 1e-8: error -5.445e-9, 1395 evaluations; substitute x = u^2: one panel, error 0.000e0
spike: exact 48.125619 MWh; from 1 panel 48.000868, estimate 1.996e-5, true error -1.248e-1, 15 evaluations
spike: from 24 hourly panels 48.125617, estimate 4.340e-4, true error -2.605e-6, 600 evaluations
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves the card's two substitutions for any integrand, and the general spike rule for every $p$ between 0 and 1.

- $\int_0^\infty f(x)\,dx = \int_0^1 f\!\left(\frac{u}{1-u}\right)\frac{du}{(1-u)^2}$ for any integrand $f$ with a finite integral.
- If $|f(x)| \le C/(1+x)^2$ for every $x \ge 0$, with $C$ a constant, the mapped integrand stays at most $C$ in size on $[0, 1)$.
- $\int_0^1 f(x)\,dx = \int_0^1 f(u^2)\,2u\,du$ for any integrand $f$ with a finite integral.
- For a spike $x^{-p}$ with $0 < p < 1$ and $m(1-p) \ge 1$, the substitution $x = u^m$ gives the new integrand $m\,u^{m(1-p)-1}$.
- That new integrand lies between 0 and $m$ on $(0, 1]$, and its integral from 0 to 1 equals that of $x^{-p}$.
- For $1/\sqrt{x}$, $p$ = 1/2 and $m$ = 2 give $m(1-p) = 1$, so the new integrand is the constant 2.
- The card's counts check out: 255, 315, 405 and 735 values for 9, 11, 14 and 25 panels, and 480 for 32 uniform panels.
- So do 600 values from 24 hourly panels, 20 and 1.25 points per hour, and 145 ten-minute readings.

The Gauss and Kronrod sums, the error estimates, the panel splitting, Planck's integral and every row of What breaks are left to the Python and Rust checks.

```lean
-- Adaptive quadrature and awkward integrals: the substitutions x = u/(1-u) and x = u^m turn an infinite range or an end spike into an integral on (0, 1) with a bounded integrand.
import Mathlib.MeasureTheory.Function.JacobianOneDim
import Mathlib.MeasureTheory.Integral.IntegralEqImproper
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open MeasureTheory Set

/-- An infinite range becomes a finite one: substituting x = u/(1-u) gives
∫₀^∞ f(x) dx = ∫₀¹ f(u/(1-u)) / (1-u)² du, and when f(x) falls at least as fast as
1/(1+x)², with |f(x)| ≤ C/(1+x)², the new integrand f(x)(1+x)² stays below C on [0, 1). -/
theorem infinite_range_substitution (f : ℝ → ℝ) (C : ℝ)
    (hf : ∀ x, 0 ≤ x → |f x| ≤ C / (1 + x) ^ 2) :
    (∫ x in Ioi (0 : ℝ), f x) = ∫ u in Ioo (0 : ℝ) 1, f (u / (1 - u)) / (1 - u) ^ 2 ∧
      ∀ u ∈ Ico (0 : ℝ) 1, |f (u / (1 - u)) / (1 - u) ^ 2| ≤ C := by
  constructor
  · have himg : (fun u : ℝ => u / (1 - u)) '' Ioo (0 : ℝ) 1 = Ioi 0 := by
      ext x
      simp only [mem_image, mem_Ioo, mem_Ioi]
      constructor
      · rintro ⟨u, ⟨h0, h1⟩, rfl⟩
        exact div_pos h0 (by linarith)
      · intro hx
        refine ⟨x / (1 + x), ⟨div_pos hx (by linarith), ?_⟩, ?_⟩
        · rw [div_lt_one (by linarith)]; linarith
        · have h1 : (1 + x) ≠ 0 := by linarith
          have h2 : 1 - x / (1 + x) = 1 / (1 + x) := by field_simp; ring
          rw [h2]; field_simp
    have hderiv : ∀ u ∈ Ioo (0 : ℝ) 1,
        HasDerivWithinAt (fun u : ℝ => u / (1 - u)) (1 / (1 - u) ^ 2) (Ioo 0 1) u := by
      intro u hu
      have hne : (1 - u) ≠ 0 := by linarith [hu.2]
      have h1 : HasDerivAt (fun y : ℝ => 1 - y) (-1) u := by
        simpa using (hasDerivAt_id u).const_sub (1:ℝ)
      have := (hasDerivAt_id' u).div h1 hne
      apply HasDerivAt.hasDerivWithinAt
      convert this using 1
      field_simp; ring
    have hinj : InjOn (fun u : ℝ => u / (1 - u)) (Ioo 0 1) := by
      intro u hu v hv huv
      have hu' : (1 - u) ≠ 0 := by linarith [hu.2]
      have hv' : (1 - v) ≠ 0 := by linarith [hv.2]
      simp only at huv
      rw [div_eq_div_iff hu' hv'] at huv
      linarith
    have key := integral_image_eq_integral_abs_deriv_smul measurableSet_Ioo hderiv hinj f
    rw [himg] at key
    rw [key]
    refine setIntegral_congr_fun measurableSet_Ioo (fun u hu => ?_)
    have hpos : 0 < 1 / (1 - u) ^ 2 := by
      have : 0 < 1 - u := by linarith [hu.2]
      positivity
    simp only [smul_eq_mul, abs_of_pos hpos]
    ring
  · intro u hu
    have hpos : 0 < 1 - u := by linarith [hu.2]
    have hx : 0 ≤ u / (1 - u) := div_nonneg hu.1 hpos.le
    have h := hf _ hx
    have he : 1 + u / (1 - u) = 1 / (1 - u) := by field_simp; ring
    rw [he] at h
    have h2 : C / (1 / (1 - u)) ^ 2 = C * (1 - u) ^ 2 := by field_simp
    rw [h2] at h
    rw [abs_div, abs_of_pos (by positivity : (0:ℝ) < (1 - u) ^ 2), div_le_iff₀ (by positivity)]
    exact h

/-- An end spike, by the substitution x = u²: ∫₀¹ f(x) dx = ∫₀¹ f(u²) · 2u du. -/
theorem end_spike_substitution (f : ℝ → ℝ) :
    (∫ x in Ioo (0 : ℝ) 1, f x) = ∫ u in Ioo (0 : ℝ) 1, f (u ^ 2) * (2 * u) := by
  have himg : (fun u : ℝ => u ^ 2) '' Ioo (0 : ℝ) 1 = Ioo 0 1 := by
    ext x
    simp only [mem_image, mem_Ioo]
    constructor
    · rintro ⟨u, ⟨h0, h1⟩, rfl⟩
      exact ⟨by positivity, by nlinarith⟩
    · rintro ⟨h0, h1⟩
      refine ⟨Real.sqrt x, ⟨Real.sqrt_pos.2 h0, ?_⟩, Real.sq_sqrt h0.le⟩
      rw [Real.sqrt_lt' one_pos]; linarith
  have hderiv : ∀ u ∈ Ioo (0 : ℝ) 1,
      HasDerivWithinAt (fun u : ℝ => u ^ 2) (2 * u) (Ioo 0 1) u := by
    intro u _
    have := hasDerivAt_pow 2 u
    apply HasDerivAt.hasDerivWithinAt
    convert this using 1
    ring
  have hinj : InjOn (fun u : ℝ => u ^ 2) (Ioo 0 1) := by
    intro u hu v hv huv
    simp only at huv
    exact (pow_left_inj₀ hu.1.le hv.1.le two_ne_zero).1 huv
  have key := integral_image_eq_integral_abs_deriv_smul measurableSet_Ioo hderiv hinj f
  rw [himg] at key
  rw [key]
  refine setIntegral_congr_fun measurableSet_Ioo (fun u hu => ?_)
  have hpos : 0 < 2 * u := by linarith [hu.1]
  simp only [smul_eq_mul, abs_of_pos hpos]
  ring

/-- A spike x^(-p) with 0 < p < 1 becomes bounded under x = u^m once m(1-p) ≥ 1:
the new integrand (u^m)^(-p) · m u^(m-1) equals m u^(m(1-p)-1), it lies between 0 and m
on (0, 1], and its integral over (0, 1) equals the integral of x^(-p). -/
theorem power_substitution_bounds_spike (p m : ℝ) (hp0 : 0 < p) (hp1 : p < 1)
    (hm : 1 ≤ m * (1 - p)) :
    (∫ x in Ioo (0 : ℝ) 1, x ^ (-p)) = ∫ u in Ioo (0 : ℝ) 1, m * u ^ (m * (1 - p) - 1) ∧
      ∀ u ∈ Ioc (0 : ℝ) 1,
        (u ^ m) ^ (-p) * (m * u ^ (m - 1)) = m * u ^ (m * (1 - p) - 1) ∧
          0 ≤ m * u ^ (m * (1 - p) - 1) ∧ m * u ^ (m * (1 - p) - 1) ≤ m := by
  have hm0 : 0 < m := by
    by_contra h
    have h' : m ≤ 0 := le_of_not_gt h
    nlinarith
  have hid : ∀ u : ℝ, 0 < u →
      (u ^ m) ^ (-p) * (m * u ^ (m - 1)) = m * u ^ (m * (1 - p) - 1) := by
    intro u hu
    rw [← Real.rpow_mul hu.le, mul_left_comm, ← Real.rpow_add hu]
    congr 2
    ring
  refine ⟨?_, fun u hu => ⟨hid u hu.1, ?_, ?_⟩⟩
  · have himg : (fun u : ℝ => u ^ m) '' Ioo (0 : ℝ) 1 = Ioo 0 1 := by
      ext x
      simp only [mem_image, mem_Ioo]
      constructor
      · rintro ⟨u, ⟨h0, h1⟩, rfl⟩
        exact ⟨Real.rpow_pos_of_pos h0 m, Real.rpow_lt_one h0.le h1 hm0⟩
      · rintro ⟨h0, h1⟩
        refine ⟨x ^ (1 / m), ⟨Real.rpow_pos_of_pos h0 _, Real.rpow_lt_one h0.le h1 (by positivity)⟩, ?_⟩
        rw [← Real.rpow_mul h0.le, one_div_mul_cancel hm0.ne', Real.rpow_one]
    have hderiv : ∀ u ∈ Ioo (0 : ℝ) 1,
        HasDerivWithinAt (fun u : ℝ => u ^ m) (m * u ^ (m - 1)) (Ioo 0 1) u := by
      intro u hu
      exact (Real.hasDerivAt_rpow_const (Or.inl hu.1.ne')).hasDerivWithinAt
    have hinj : InjOn (fun u : ℝ => u ^ m) (Ioo 0 1) := by
      intro u hu v hv huv
      simp only at huv
      have := congrArg (fun y => y ^ (1 / m)) huv
      rwa [← Real.rpow_mul hu.1.le, ← Real.rpow_mul hv.1.le, mul_one_div_cancel hm0.ne',
        Real.rpow_one, Real.rpow_one] at this
    have key := integral_image_eq_integral_abs_deriv_smul measurableSet_Ioo hderiv hinj
      (fun x : ℝ => x ^ (-p))
    rw [himg] at key
    rw [key]
    refine setIntegral_congr_fun measurableSet_Ioo (fun u hu => ?_)
    have hpos : 0 < m * u ^ (m - 1) := mul_pos hm0 (Real.rpow_pos_of_pos hu.1 _)
    simp only [smul_eq_mul, abs_of_pos hpos]
    rw [mul_comm]
    exact hid u hu.1
  · exact mul_nonneg hm0.le (Real.rpow_nonneg hu.1.le _)
  · have : u ^ (m * (1 - p) - 1) ≤ 1 := Real.rpow_le_one hu.1.le hu.2 (by linarith)
    nlinarith

-- 1/sqrt(x) is the spike p = 1/2; m = 2 gives m(1-p) = 1, so the new integrand is the constant 2.
example : (2 : ℚ) * (1 - 1 / 2) = 1 := by norm_num
example : (2 : ℚ) * (1 - 1 / 2) - 1 = 0 := by norm_num
-- Function values: 15 × (2 × panels − 1) at tolerances 1e-3, 1e-6, 1e-9, 1e-12.
example : 15 * (2 * 9 - 1) = 255 := by decide
example : 15 * (2 * 11 - 1) = 315 := by decide
example : 15 * (2 * 14 - 1) = 405 := by decide
example : 15 * (2 * 25 - 1) = 735 := by decide
-- Uniform panels: 32 panels of 15 values; the 24-hour start ends with 32 panels: 15 × (2 × 32 − 24).
example : 15 * 32 = 480 := by decide
example : 15 * (2 * 32 - 24) = 600 := by decide
-- Sampling density: 15 points over 3/4 hour near 18:00, over 12 hours at night.
example : (15 : ℚ) / (3 / 4) = 20 := by norm_num
example : (15 : ℚ) / 12 = 5 / 4 := by norm_num
-- Ten-minute readings over a day: 144 steps, 145 values.
example : 24 * 6 + 1 = 145 := by decide

#print axioms infinite_range_substitution
#print axioms end_spike_substitution
#print axioms power_substitution_bounds_spike
```

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'infinite_range_substitution' depends on axioms: [propext, Classical.choice, Quot.sound]
'end_spike_substitution' depends on axioms: [propext, Classical.choice, Quot.sound]
'power_substitution_bounds_spike' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run the Python.
> - **Where the first panels fall.** In section 5, change `start=24` to `start=3`. Guess first: do three 8-hour panels find the 36-second surge at 18:00? They do not: true error −0.1229 MWh after 45 values, and an assert stops the run. With `start=2`, the second panel's centre node sits exactly on 18:00, and the error drops to −2.05e-7 after 480 values.
> - **A sharper surge.** Change `surge(0.25), surge_exact(0.25)` to `surge(0.05), surge_exact(0.05)`, a 3-minute half-width. Guess first: how many more values? The run needs 345 values and 12 panels, with true error 4.128e-7, still inside one kilowatt-hour. An assert then stops the run, because the check expects 1e-9.
> - **A divergent tail.** In `mapped`, replace `planck(t / (1 - t))` with `1 / (1 + t / (1 - t))`, whose integral to infinity diverges. Guess first: what does the method report? The mapped integrand is $1/(1-u)$, unbounded at $u = 1$. The method keeps splitting toward 1 until a node rounds onto $u = 1$, and Python stops with a division by zero.

---

## The usual mistake

> [!warning]
> **"The error estimate passed, so the answer is right."** The estimate is built from the function values the method chose. Anything that falls between them is invisible. A 36-second surge missed by all 15 first nodes gives an estimate of 1.996e-5 and a true error of −1.248e-1 MWh, lost without a warning. Start from several panels, and put panel edges at known events.
>
> - **Trusting the estimate as a size.** On the first panel of the load the estimate was 3.953e-2 against a true error of 4.098. On resolved panels it overstates instead: 5.897e-5 against 3.797e-10.
> - **Cutting off infinity by eye.** A cut at x = 10 loses 6.202e-2 of Planck's 6.49393940227.
> - **Refining harder at a spike.** 64 uniform panels on $1/\sqrt{x}$ are still off by 5.710e-3; the substitution $x = u^2$ is exact with 15 values.

---

## Where you meet it in real life

- **Scientific libraries.** The general-purpose integrators in common numerical libraries descend from QUADPACK, which splits the worst panel. Its infinite-range routine uses this 15-point Kronrod pair after a map to a finite interval; its general-purpose finite-range routine uses a 21-point pair.
- **Physics constants and spectra.** Radiation, heat capacity and particle-statistics integrals run from 0 to infinity, as Planck's does, and are computed after a map to a finite interval.
- **Energy and metering.** Energy from a load model is an integral over the day with sharp events; adaptivity puts the effort on the events.
- **Engineering loads.** Stress near a crack tip or the field near a sharp edge behaves like a power of the distance, $1/\sqrt{x}$ included, and is integrated after a substitution like $x = u^2$.

> **Say it back**
> Adaptive quadrature cuts an interval into panels and estimates each panel's error by the gap between a 7-point Gauss rule and a 15-point Kronrod rule that reuses its points. It splits the panel with the largest gap until the gaps add up to less than the tolerance, so points gather where the function changes fast. The gap measures the worse rule, so the method returns the better one, and the gap can miss a feature that no sample sees. An infinite range becomes finite under $x = u/(1-u)$, and an end spike like $1/\sqrt{x}$ becomes a constant under $x = u^2$.

---

## What this builds on

- [Error bounds and Romberg](02-error-bounds-and-romberg.md): how a rule's error depends on the panel width and a derivative, the fact that makes splitting pay off.
- [Gaussian quadrature](03-gaussian-quadrature.md): the 7-point Gauss rule, its degree of exactness 13 and its error formula, which this card pairs with a Kronrod extension.
- [Improper integrals](../../06-Calculus%20and%20analysis/04-Integrals/07-improper-integrals.md): what an integral to infinity or up to a spike means, and when it converges, before any computing.

## Where this goes next

- [Many dimensions](06-multidimensional-and-monte-carlo-quadrature.md): when the integral has many variables, panels multiply too fast and random sampling takes over.
- The other cards on this shelf: [Trapezoid, midpoint and Simpson](01-newton-cotes-and-composite-rules.md) for the simplest rules, [Weighted Gauss rules](04-gauss-hermite-and-weighted-rules.md) for building an awkward factor such as $e^{-x}$ into the weights instead of a substitution, and [Quasi-Monte Carlo and sparse grids](07-quasi-monte-carlo-and-sparse-grids.md) for evenly spread points in many dimensions.

The question this card leaves open: when the error estimate itself cannot be trusted, as with the hidden surge, what can certify an integral?

---

## Sources

Verified 2026-11-11: every link below resolves to the publisher's page.

- Piessens, Robert, Elise de Doncker-Kapenga, Christoph W. Überhuber and David K. Kahaner. *QUADPACK: A Subroutine Package for Automatic Integration*. Springer, 1983. [doi:10.1007/978-3-642-61786-7](https://doi.org/10.1007/978-3-642-61786-7). The 15-point Kronrod table, the split-the-worst-panel strategy and the rescaled estimate.
- Laurie, Dirk P. "Calculation of Gauss-Kronrod quadrature rules." *Mathematics of Computation* 66 (1997): 1133–1145. [doi:10.1090/S0025-5718-97-00861-2](https://doi.org/10.1090/S0025-5718-97-00861-2). How Kronrod nodes and weights are computed, and when they exist.
- Gander, Walter, and Walter Gautschi. "Adaptive Quadrature—Revisited." *BIT Numerical Mathematics* 40 (2000): 84–101. [doi:10.1023/A:1022318402393](https://doi.org/10.1023/A:1022318402393). Failure cases of adaptive integrators and safer stopping rules.
- Takahasi, Hidetosi, and Masatake Mori. "Double Exponential Formulas for Numerical Integration." *Publications of the Research Institute for Mathematical Sciences* 9 (1974): 721–741. [doi:10.2977/prims/1195192451](https://doi.org/10.2977/prims/1195192451). The tanh-sinh substitution for end singularities.
- National Institute of Standards and Technology. "Stefan-Boltzmann constant." [CODATA value](https://physics.nist.gov/cgi-bin/cuu/Value?sigma). The exact SI value that the Planck integral reproduces.
