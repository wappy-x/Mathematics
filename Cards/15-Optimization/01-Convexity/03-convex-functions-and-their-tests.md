# Convex functions: chords above the graph, and the curvature test that proves it

[Syllabus](../../../SYLLABUS.md) → [Optimization](../README.md) → [Convexity](../README.md#s01) → Convex functions

---

## General Overview

A roaster sells a house blend of arabica and robusta. Two settings are chosen: roast time past first crack (the popping sound that marks a light roast), from 0 to 3 minutes, and robusta's share of the beans, from 0 to 50%. Robusta is cheaper, say £5 a kilo against £9, so the roaster wants to minimise cost by using as much robusta as taste allows. The limit is taste: a panel scores bitterness from 0 to 10, and the blend must score at most 6.

Darker roasts taste more bitter, and the bitterness climbs faster the longer the roast. Robusta adds bitterness too. Recipe A, a 1-minute roast with 40% robusta, scores 3.69 and costs £7.40 a kilo. Recipe C, a 3-minute roast with 10% robusta, scores 5.82 and costs £8.60. Both pass.

Is every recipe between them also in spec, untasted? Halfway is a 2-minute roast with 25% robusta. If the bitterness curve bends upward like a bowl, the halfway recipe can score no more than the average of the two ends, 4.76. It actually scores 4.47.

That guarantee is what **convex** buys. There are three tests for it: chords above the graph, tangents below it, and curvature that never turns downward. For smooth functions they always agree.

**A smooth function is convex exactly when every tangent plane lies under its graph, and exactly when its curvature is never negative in any direction; the chord test, the tangent test and the curvature test are one fact seen three ways.**

**What kind of fact this is:** a theorem, proved on this card in Why it works. The bitterness formula is a model: a plausible made-up fit, not published tasting data.

### The picture: bitterness along the straight path from A to C

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Bitterness on the path from recipe A to recipe C"
    x-axis "Share of the way from A to C" [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]
    y-axis "Bitterness (panel points, 0 to 10)" 3 --> 6
    line [3.69, 3.81, 3.95, 4.11, 4.28, 4.47, 4.68, 4.92, 5.19, 5.49, 5.82]
    line [3.69, 3.90, 4.12, 4.33, 4.54, 4.76, 4.97, 5.18, 5.40, 5.61, 5.82]
    line [3.69, 3.81, 3.93, 4.05, 4.16, 4.28, 4.40, 4.52, 4.64, 4.76, 4.88]
```

The middle line is the true bitterness. The top line is the chord joining A to C: the graph stays under it. The bottom line is the tangent at A, the straight line with A's slope: the graph stays over it. Squeezed between a chord above and a tangent below, the curve can only bend upward.

---

## The formula

The roaster's model, with t the roast time in minutes past first crack and w the robusta share:

$$B(t, w) = 1 + e^{t/2} + k\,t\,w + 4w^2, \qquad k = 1.$$

The term $e^{t/2}$ is bitterness that compounds with roast time, multiplying by $e^{1/2} = 1.6487$ each minute. The term $k\,t\,w$ says robusta's bitter notes grow as the roast goes on, at rate k. The term $4w^2$ is robusta's own bite.

Write a recipe as a point, x = (t, w). [Convex sets](02-convex-sets.md) wrote the mix of two points as $\theta x + (1-\theta)y$, with θ (theta) a weight from 0 to 1. The calculus wing's [Convex functions](../../06-Calculus%20and%20analysis/07-Several%20Variables/09-convex-functions.md) already defined convexity by chords and proved the curvature test. Here they are side by side with the new one, the tangent test, for a function f with two continuous derivatives on an open convex set:

$$\underbrace{f(\theta x + (1-\theta)y) \le \theta f(x) + (1-\theta) f(y)}_{\text{chord}} \iff \underbrace{f(y) \ge f(x) + \nabla f(x)^{\top}(y - x)}_{\text{tangent}} \iff \underbrace{\nabla^2 f(x) \succeq 0}_{\text{curvature}}$$

**Read it aloud:** the graph sits under every chord, if and only if it sits over every tangent plane, if and only if its curvature is never negative in any direction.

Two pieces of notation are new to this wing. The Hessian H, the table of second derivatives, is written $\nabla^2 f(x)$ from here on. And $M \succeq 0$, read "M is positive semidefinite", means $v^{\top} M v \ge 0$ for every direction v ([Quadratic forms](../../03-Algebra/07-Eigenvalues%20and%20Symmetric%20Matrices/05-quadratic-forms-and-positive-definite.md)).

When the curvature is boxed in, between a least value μ (mu) and a greatest value L, the tangent test sharpens into a sandwich:

$$f(x) + \nabla f(x)^{\top}(y-x) + \tfrac{\mu}{2}\lVert y-x\rVert^2 \;\le\; f(y) \;\le\; f(x) + \nabla f(x)^{\top}(y-x) + \tfrac{L}{2}\lVert y-x\rVert^2.$$

**Read it aloud:** the true value sits above the tangent plus a bowl of curvature μ, and below the tangent plus a bowl of curvature L.

A function with μ > 0 is **strongly convex**: it curves up by at least μ in every direction. One with a ceiling L is **L-smooth**: it never curves up faster than L.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $B(t, w)$ | bitterness, panel points from 0 to 10 | 3.6887 at A, 5.8217 at C | the spec of 6 rules more recipes out |
| $t$ | roast time past first crack, minutes | 0 to 3; A has 1, C has 3 | bitterness climbs, faster and faster |
| $w$ | robusta share of the beans | 0 to 0.5; A has 0.4, C has 0.1 | cheaper, and more bitter |
| $k$ | how fast robusta's bitterness grows with roast time | 1 | above √2 = 1.4142, B stops being convex |
| $f$, $x$, $y$ | any function under test, and two points (recipes) | B, A = (1, 0.4), C = (3, 0.1) | — |
| $\theta$, $z$ | mixing weight, from 0 to 1; the mix itself | ½ gives the halfway recipe (2, 0.25) | the mix moves toward x |
| $\nabla f(x)$ | gradient: the slopes in t and in w | (1.2244, 4.2000) at A | a steeper tangent plane |
| $\nabla^2 f(x)$, $H$ | Hessian: the table of second derivatives | `[[0.4122, 1], [1, 8]]` at A | more curvature |
| $v$, $M$, $\succeq 0$ | a direction; a symmetric matrix; "never negative along any direction" | determinant 2.2974, trace 8.4122 at A | — |
| $\mu$, $L$, $\lVert\cdot\rVert$ | least and greatest curvature over the recipes; length | 0.1230 and 8.1424 | a tighter sandwich, or a looser one |
| $S(t)$ | a bitterness curve that levels off, for What breaks | $8/(1 + e^{2-t})$ | — |
| $g$, $s$, $\xi$, $\sigma$ | the function along one segment; how far along it (0 to 1); a point on it and its position (xi, sigma), from Taylor's theorem | s = 0.5 down to 0.001 in Step 1 | — |

### When it holds

- **Two continuous derivatives.** The Hessian must exist. A kink, such as $\lvert t - 2\rvert$, can be convex with no Hessian at the kink; [Subgradients](07-subgradients.md) handles it.
- **An open convex domain.** Every segment between recipes must stay inside, or chords leave the domain. The converse (Step 4) also needs room to step a little in every direction. B's formula is convex on the whole strip t > −1.3863, which holds every real recipe; below it the determinant turns negative.
- **Every direction, not just the axes.** With k = 4, each setting alone curves upward, yet the blend fails along a diagonal (What breaks, row 1).
- **Every point, not one.** The curve S passes the curvature test at 1 minute and fails at 3 (row 3).
- **Strong convexity needs μ > 0, and the sandwich needs μ and L valid along the whole segment.** On the roaster's box of recipes (t from 0 to 3, w from 0 to 0.5) they come from t = 0 and t = 3, the ends of the roast range.

---

## Why it works

### Step 0: every test is a test on straight lines

Pick two recipes x and y and walk the segment between them: $g(s) = f(x + s(y-x))$, for s from 0 to 1. Along that walk the chain rule gives

$$g'(s) = \nabla f(x + s(y-x))^{\top}(y-x), \qquad g''(s) = (y-x)^{\top}\,\nabla^2 f(x + s(y-x))\,(y-x).$$

So the chord test for f is the chord test for every slice g. The tangent test for f is "g lies above its tangent at 0". The curvature test is "g'' ≥ 0 on every slice". Each claim in several variables is a one-variable claim on every line.

### Step 1: chord implies tangent

Start from the chord inequality with the mix close to x. Write the weight on y as s. Then

$$f(x + s(y-x)) \le f(x) + s\,\big(f(y) - f(x)\big), \quad\text{so}\quad \frac{f(x + s(y-x)) - f(x)}{s} \le f(y) - f(x).$$

The left side is the average slope from x over a step of size s. As s shrinks it becomes the slope at x in direction y − x, which is $\nabla f(x)^{\top}(y-x)$. The inequality survives the limit: that is the tangent test.

On the roaster's segment from A to C, the quotients for s = 0.5, 0.1, 0.01, 0.001 are 1.5591, 1.2500, 1.1946 and 1.1893. They fall toward the slope 1.1887. Every one stays below the ceiling, B(C) − B(A) = 2.1330.

### Step 2: tangent implies chord

Take the mix z = θx + (1 − θ)y. Write the tangent test at z twice, once toward x and once toward y:

$$f(x) \ge f(z) + \nabla f(z)^{\top}(x - z), \qquad f(y) \ge f(z) + \nabla f(z)^{\top}(y - z).$$

Multiply the first by θ and the second by 1 − θ, then add. The slope terms cancel, because θ(x − z) + (1 − θ)(y − z) = θx + (1 − θ)y − z = 0. What is left is θf(x) + (1 − θ)f(y) ≥ f(z): the chord test.

### Step 3: curvature implies tangent, and gives μ and L

Taylor's theorem on the slice g, with the remainder in its mean-value form, says that for some point ξ (xi) on the segment,

$$f(y) = f(x) + \nabla f(x)^{\top}(y-x) + \tfrac12 (y-x)^{\top}\,\nabla^2 f(\xi)\,(y-x).$$

If $\nabla^2 f \succeq 0$, the last term is never negative, so f(y) is at least the tangent. That is the tangent test.

If also $\mu\lVert v\rVert^2 \le v^{\top}\nabla^2 f\,v \le L\lVert v\rVert^2$ everywhere, the last term lies between $\frac{\mu}{2}\lVert y-x\rVert^2$ and $\frac{L}{2}\lVert y-x\rVert^2$. That is the sandwich. For recipe C seen from A: the tangent gives 4.8774, the μ-bowl adds 0.2516, so the floor is 5.1291. The true value is 5.8217. The ceiling is 21.5287, loose, because L comes from the steep robusta direction while the step from A to C is mostly roast time.

### Step 4: tangent implies curvature, the converse

Write the tangent test from x toward y, and from y back toward x, then add the two. The function values cancel and leave

$$\big(\nabla f(y) - \nabla f(x)\big)^{\top}(y - x) \ge 0.$$

In words: the slope never decreases as you walk along any line. For A and C, the slopes are (1.2244, 4.2000) at A and (2.3408, 3.8000) at C; the change, measured along C − A, is 2.3530, positive.

Now put y = x + s v for a small step s in direction v, and divide by s². The left side becomes $v^{\top}\nabla^2 f(x)\,v$ as s shrinks, and it stays at least 0. That holds for every direction v, so $\nabla^2 f(x) \succeq 0$. The open domain matters here: x needs room for a small step in every direction.

Steps 1 and 2 tie the chord test to the tangent test both ways; Steps 3 and 4 tie the tangent test to the curvature test both ways. The three are one fact.

<details>
<summary>Detailed proof: the three tests agree, and the converse in full</summary>

Let f have continuous second derivatives on an open convex set, and let x and y be in it.

(Chord ⇒ tangent.) For 0 < s ≤ 1, convexity with weight 1 − s on x gives f(x + s(y − x)) ≤ (1 − s)f(x) + s f(y). Subtract f(x) and divide by s: [f(x + s(y − x)) − f(x)]/s ≤ f(y) − f(x). As s → 0 the left side tends to g'(0) = ∇f(x)ᵀ(y − x).

(Tangent ⇒ chord.) Shown in Step 2: apply the tangent inequality at z = θx + (1 − θ)y toward x and toward y, weight by θ and 1 − θ, and add.

(Curvature ⇒ tangent.) g(s) = f(x + s(y − x)) has two continuous derivatives on [0, 1]. Taylor's theorem gives g(1) = g(0) + g'(0) + ½ g''(σ) for some σ in (0, 1), with g''(σ) = (y − x)ᵀ∇²f(ξ)(y − x), ξ = x + σ(y − x). If ∇²f(ξ) ⪰ 0 then g(1) ≥ g(0) + g'(0), which is the tangent inequality.

(Tangent ⇒ curvature.) Adding the tangent inequalities at x and at y gives (∇f(y) − ∇f(x))ᵀ(y − x) ≥ 0. Fix v. Because the set is open, x + s v stays in it for every small enough s > 0. Put y = x + s v and divide by s²: (∇f(x + s v) − ∇f(x))ᵀv / s ≥ 0. As s → 0 this tends to vᵀ∇²f(x)v, by the definition of the second derivative along v. So vᵀ∇²f(x)v ≥ 0 for every v.

(Applying it to the roaster.) ∇²B = `[[e^(t/2)/4, k], [k, 8]]`. A symmetric 2 × 2 matrix is positive semidefinite when both diagonal entries are at least 0 and the determinant is at least 0 (complete the square, as on the quadratic-forms card). Here the diagonal entries are positive, and with k = 1 the determinant is 2e^(t/2) − 1. It is positive whenever t > −2 ln 2 = −1.3863. So B is convex on that open strip, which contains every recipe. With general k the determinant is 2e^(t/2) − k², which at t = 0 is 2 − k²: convexity on the box needs k ≤ √2.

</details>

### Step 5: why a proof needs the curvature formula, not the grid

The code runs the chord test on 861 pairs of recipes at three weights, and the tangent test on 1,722 ordered pairs. All pass for B. That is evidence, not proof: something could go wrong between grid points.

The determinant $2e^{t/2} - 1$ is different: a formula, positive for every t > −1.3863, not just at 42 grid points. So the curvature formula proves convexity, while one failing chord disproves it.

---

## Worked numbers, by hand

Recipes A = (1 min, 40% robusta) and C = (3 min, 10% robusta). The number e is about 2.7183, so $e^{0.5} = 1.6487$, $e^{1} = 2.7183$ and $e^{1.5} = 4.4817$.

| Step | Arithmetic | Value |
| --- | --- | --- |
| B at A | 1 + 1.6487 + 1 × 0.4 + 4 × 0.16 | 3.6887 |
| B at C | 1 + 4.4817 + 3 × 0.1 + 4 × 0.01 | 5.8217 |
| chord test at halfway (2 min, 25%) | 1 + 2.7183 + 0.5 + 0.25 = 4.4683, under (3.6887 + 5.8217) ÷ 2 = 4.7552 | gap 0.2869 |
| slopes at A | (e^0.5 ÷ 2 + w, t + 8w) = (1.6487 ÷ 2 + 0.4, 1 + 8 × 0.4) | (1.2244, 4.2000) |
| tangent test at C | 3.6887 + 1.2244 × 2 + 4.2 × (−0.3) = 4.8774, under 5.8217 | gap 0.9442 |
| Hessian at A | `[[e^0.5 / 4, 1], [1, 8]]` | `[[0.4122, 1], [1, 8]]` |
| curvature test at A | determinant 0.4122 × 8 − 1 = 2.2974; trace 8.4122; both positive | eigenvalues 0.2826 and 8.1296 |
| curvature test everywhere | determinant $2e^{t/2} - 1$, and $e^{t/2} \ge 1$ for t ≥ 0 | **at least 1.0000** |
| tangent floor at (3 min, 40%) | 3.6887 + 1.2244 × 2 + 4.2 × 0 | **6.1374, over the spec of 6** |

All three tests pass at the recipes checked, and the curvature formula passes at every recipe the roaster can make. So B is convex. Every recipe between two in-spec recipes is in spec. And one tasting at A, with its slopes, rules out the 3-minute, 40% robusta recipe without roasting it: its floor is already 6.1374, and its true score is 7.3217.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Test each setting on its own, with k = 4 | axis chords pass (least slack 0.006512); diagonal entries 0.4122 and 8; yet halfway between (0 min, 50%) at 3.0000 and (2 min, 0%) at 3.7183 scores 3.8987, above their average 3.3591 | determinant −12.7026 at t = 1: the cross term wins along a diagonal |
| Trust a tangent floor on a curve that levels off | the tangent to S at 3 min claims S(1) ≥ 2.7027; the true S(1) is 2.1515 | S curves down past 2 minutes, so its tangent rides above the graph |
| Check curvature at one point | S''(1) = 0.7269, a pass | S''(3) = −0.7269: the test must hold everywhere |
| Use the formula outside its strip, t = −2 | determinant −0.2642, least eigenvalue −0.0325 | B is convex only for t > −1.3863 |

With k = 4, the grid tests all fail together: least chord slack −0.6262, least tangent slack −3.0183, least eigenvalue −1.4442. That matches the theorem: a smooth function cannot pass one test everywhere and fail another.

---

## Code, from first principles, and it actually runs

The code reaches each answer by two roads. Slopes come from the hand formula and from central differences (the value a small step ahead minus a small step behind, over twice the step). Curvatures come from the hand formula and from second differences. Those pairs share no arithmetic. μ and L come from the hand Hessian at the box's ends and from the second-difference Hessians at all 42 grid recipes. Both of those roads use the same 2 × 2 eigenvalue formula, so a separate check confirms that every pair of eigenvalues it returns adds up to the matrix's trace (the sum of its diagonal) and multiplies to its determinant. The tangent's prediction at C is checked against a central difference along the segment from A. Then the three tests run over the whole grid, for B and for the k = 4 blend. The theorem says the three tests stand or fall together, and on the grid they do: all pass for B, all fail for k = 4.

### Python

```python
# Convex functions and their tests -- the check behind the card.  Standard library only.
# Bitterness B on a 0-10 tasting scale.  t = roast minutes past first crack (0 to 3),
# w = robusta share of the blend (0 to 0.5), k = how fast robusta's bitterness grows with
# roast time (1 in the model).  Three tests -- chord, tangent, curvature -- run on
# a grid of 42 recipes, for B and for two curves that fail; each has an independent road.
from math import exp, sqrt, log

def B(t, w, k=1.0):    return 1 + exp(t / 2) + k * t * w + 4 * w * w
def grad(t, w, k=1.0): return (exp(t / 2) / 2 + k * w, k * t + 8 * w)   # slopes, by hand
def hess(t, w, k=1.0): return ((exp(t / 2) / 4, k), (k, 8.0))           # curvatures, by hand
def S(t):              return 8 / (1 + exp(2 - t))                      # bitterness that levels off

def num_grad(f, p, h=1e-5):                       # slopes again, by central differences
    return tuple((f(p[0] + h * (i == 0), p[1] + h * (i == 1)) -
                  f(p[0] - h * (i == 0), p[1] - h * (i == 1))) / (2 * h) for i in range(2))

def num_hess(f, p, h=1e-3):                       # curvatures again, by second differences
    at = lambda a, b: f(p[0] + a * h, p[1] + b * h)
    hxy = (at(1, 1) - at(1, -1) - at(-1, 1) + at(-1, -1)) / (4 * h * h)
    return ((at(1, 0) - 2 * at(0, 0) + at(-1, 0)) / h ** 2, hxy), (hxy, (at(0, 1) - 2 * at(0, 0) + at(0, -1)) / h ** 2)

def eig(H):                                       # eigenvalues of a symmetric 2 x 2, smaller first
    tr, gap = H[0][0] + H[1][1], sqrt((H[0][0] - H[1][1]) ** 2 + 4 * H[0][1] ** 2)
    return (tr - gap) / 2, (tr + gap) / 2

dot = lambda u, v: u[0] * v[0] + u[1] * v[1]
mix = lambda th, x, y: (th * x[0] + (1 - th) * y[0], th * x[1] + (1 - th) * y[1])
GRID = [(0.5 * i, 0.1 * j) for i in range(7) for j in range(6)]
PAIRS = [(x, y) for n, x in enumerate(GRID) for y in GRID[n + 1:]]

def three_tests(f, g, pairs=PAIRS):              # least slack of each test over the grid
    chord = min(th * f(*x) + (1 - th) * f(*y) - f(*mix(th, x, y)) for x, y in pairs for th in (0.25, 0.5, 0.75))
    tang = min(f(*y) - f(*x) - dot(g(*x), (y[0] - x[0], y[1] - x[1])) for x in GRID for y in GRID if x != y)
    return chord, tang, min(eig(num_hess(f, p))[0] for p in GRID)

A, C, M, F = (1.0, 0.4), (3.0, 0.1), (2.0, 0.25), (3.0, 0.4)
bA, bC, bM = B(*A), B(*C), B(*M)
gA, gC, d = grad(*A), grad(*C), (C[0] - A[0], C[1] - A[1])
tanC, floorF = bA + dot(gA, d), bA + dot(gA, (F[0] - A[0], F[1] - A[1]))
HA, nA = hess(*A), num_hess(B, A)
quot = [(B(*mix(1 - s, A, C)) - bA) / s for s in (0.5, 0.1, 0.01, 0.001)]
mono = dot((gC[0] - gA[0], gC[1] - gA[1]), d)
mu, L = eig(hess(0, 0))[0], eig(hess(3, 0))[1]                 # Hessian rises with t only
eg = [eig(num_hess(B, p)) for p in GRID]
mu_g, L_g = min(e[0] for e in eg), max(e[1] for e in eg)
lo, hi = tanC + mu / 2 * dot(d, d), tanC + L / 2 * dot(d, d)
okB = three_tests(B, grad)
G, gG = (lambda t, w: B(t, w, 4.0)), (lambda t, w: grad(t, w, 4.0))
badG = three_tests(G, gG)
axisG = three_tests(G, gG, [(x, y) for x, y in PAIRS if x[0] == y[0] or x[1] == y[1]])[0]
HG = hess(1, 0, 4.0)
s1, s3 = S(1), S(3)
d1, d3 = s1 * (8 - s1) / 8, s3 * (8 - s3) / 8                   # S' = S(8 - S)/8
c1, c3 = d1 * (8 - 2 * s1) / 8, d3 * (8 - 2 * s3) / 8           # S'' = S'(8 - 2S)/8
n3 = (S(3.001) - 2 * s3 + S(2.999)) / 1e-6
tanS1 = s3 + d3 * (1 - 3)
th = [0.1 * i for i in range(11)]
print("model: B(t, w) = 1 + e^(t/2) + t*w + 4*w^2; t in [0, 3] min, w in [0, 0.5]")
print(f"prices: arabica 9.00, robusta 5.00 pounds/kg; e^(1/2) = {exp(0.5):.4f}, e^1 = {exp(1):.4f}, e^(3/2) = {exp(1.5):.4f}")
for name, p, b in (("A", A, bA), ("C", C, bC), ("halfway", M, bM)):
    print(f"recipe {name} ({p[0]:.0f} min, {100 * p[1]:.0f}% robusta): B = {b:.4f}, cost {9 - 4 * p[1]:.2f} pounds/kg")
print(f"chord: average of A and C {(bA + bC) / 2:.4f}, halfway {bM:.4f}, gap {(bA + bC) / 2 - bM:.4f}")
print(f"slopes at A by formula ({gA[0]:.4f}, {gA[1]:.4f}); by central differences ({num_grad(B, A)[0]:.4f}, {num_grad(B, A)[1]:.4f})")
print(f"tangent at A predicts C: {bA:.4f} + {gA[0] * d[0]:.4f} + ({gA[1] * d[1]:.4f}) = {tanC:.4f}; true {bC:.4f}; gap {bC - tanC:.4f}")
print(f"tangent floor at (3 min, 40%): {floorF:.4f} > 6, out of spec untasted; true {B(*F):.4f}")
print(f"Hessian at A by formula [[{HA[0][0]:.4f}, {HA[0][1]:.4f}], [{HA[1][0]:.4f}, {HA[1][1]:.4f}]]"
      f"; by second differences [[{nA[0][0]:.4f}, {nA[0][1]:.4f}], [{nA[1][0]:.4f}, {nA[1][1]:.4f}]]")
print(f"at A: determinant {HA[0][0] * HA[1][1] - 1:.4f}, trace {HA[0][0] + 8:.4f}, eigenvalues {eig(HA)[0]:.4f} and {eig(HA)[1]:.4f}")
print(f"determinant 2e^(t/2) - 1 is at least {2 * exp(0) - 1:.4f} for t >= 0; turns negative below t = {-2 * log(2):.4f}")
print("step 1 quotients, s = 0.5, 0.1, 0.01, 0.001: " + ", ".join(f"{q:.4f}" for q in quot)
      + f"; limit {dot(gA, d):.4f}; ceiling {bC - bA:.4f}")
print(f"step 4 slopes at C ({gC[0]:.4f}, {gC[1]:.4f}); slope change along C - A: {mono:.4f}")
print(f"mu, least eigenvalue on the box (t = 0): formula {mu:.4f}, grid {mu_g:.4f}")
print(f"L, largest eigenvalue on the box (t = 3): formula {L:.4f}, grid {L_g:.4f}")
print(f"sandwich for C: {tanC:.4f} + {mu / 2 * dot(d, d):.4f} = {lo:.4f} <= {bC:.4f} <= {hi:.4f}")
print(f"grid: {len(GRID)} recipes, {len(PAIRS)} pairs x 3 weights, {len(GRID) * (len(GRID) - 1)} ordered pairs")
print("B, least slack: chord {:.6f}, tangent {:.6f}, least eigenvalue {:.4f}".format(*okB))
print("k = 4, least slack: chord {:.4f}, tangent {:.4f}, least eigenvalue {:.4f}".format(*badG))
print(f"k = 4, chords along the axes only: least slack {axisG:.6f}; diagonal at t = 1: {HG[0][0]:.4f} and {HG[1][1]:.4f}; determinant {HG[0][0] * 8 - 16:.4f}")
print(f"k = 4 chord: (0 min, 50%) {G(0, 0.5):.4f}, (2 min, 0%) {G(2, 0):.4f}, average {(G(0, 0.5) + G(2, 0)) / 2:.4f}; halfway (1 min, 25%) {G(1, 0.25):.4f}")
print(f"levelling curve: S(1) = {s1:.4f}, S(3) = {s3:.4f}, slope at 3 {d3:.4f}; tangent at 3 claims S(1) >= {tanS1:.4f}")
print(f"levelling curve: S''(1) = {c1:.4f}, S''(3) = {c3:.4f}, by second differences {n3:.4f}")
print(f"try: k = 1.5, least eigenvalue at t = 0: {eig(hess(0, 0, 1.5))[0]:.4f}; switch-off k = {sqrt(2):.4f}")
print(f"try: t = -2, determinant {2 * exp(-1) - 1:.4f}, least eigenvalue {eig(hess(-2, 0))[0]:.4f}")
print(f"try: tangent at C predicts A: {bC + dot(gC, (-d[0], -d[1])):.4f}; true {bA:.4f}")
print("chart theta: " + ", ".join(f"{x:.1f}" for x in th))
print("chart B from A to C: " + ", ".join(f"{B(*mix(1 - x, A, C)):.2f}" for x in th))
print("chart chord: " + ", ".join(f"{(1 - x) * bA + x * bC:.2f}" for x in th))
print("chart tangent at A: " + ", ".join(f"{bA + x * dot(gA, d):.2f}" for x in th))
assert all(abs(u - v) < 1e-6 for p in GRID for u, v in zip(grad(*p), num_grad(B, p)))       # slopes two ways
assert all(abs(hess(*p)[i][j] - num_hess(B, p)[i][j]) < 1e-4 for p in GRID for i in range(2) for j in range(2))
assert min(okB) > 0 and max(badG) < 0 and axisG > 0                    # three tests agree, both ways
assert tanC < bC and abs(quot[-1] - dot(gA, d)) < 1e-2 and max(quot) <= bC - bA and mono > 0
assert abs(mu - mu_g) < 1e-5 and abs(L - L_g) < 1e-5 and lo <= bC <= hi   # mu and L two ways
assert tanS1 > s1 and c1 > 0 > c3 and abs(n3 - c3) < 1e-5              # the levelling curve fails
assert abs(tanS1 - (s3 - (S(3 + 1e-5) - S(3 - 1e-5)) / 1e-5)) < 1e-6    # its tangent value two ways
assert abs(tanC - bA - (B(*mix(1 - 1e-5, A, C)) - B(*mix(1 + 1e-5, A, C))) / 2e-5) < 1e-6   # tangent at A two ways
mats = [HA, hess(0, 0), hess(3, 0), hess(0, 0, 1.5), hess(-2, 0)] + [num_hess(f, p) for f in (B, G) for p in GRID]
assert all(l1 <= l2 and abs(l1 + l2 - H[0][0] - H[1][1]) < 1e-9 and abs(l1 * l2 - H[0][0] * H[1][1] + H[0][1] * H[1][0]) < 1e-9
           for H in mats for l1, l2 in [eig(H)])   # every eigenvalue pair: sum = trace, product = determinant
print("ALL CHECKS PASS")
```

**Ran 2026-11-11 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
model: B(t, w) = 1 + e^(t/2) + t*w + 4*w^2; t in [0, 3] min, w in [0, 0.5]
prices: arabica 9.00, robusta 5.00 pounds/kg; e^(1/2) = 1.6487, e^1 = 2.7183, e^(3/2) = 4.4817
recipe A (1 min, 40% robusta): B = 3.6887, cost 7.40 pounds/kg
recipe C (3 min, 10% robusta): B = 5.8217, cost 8.60 pounds/kg
recipe halfway (2 min, 25% robusta): B = 4.4683, cost 8.00 pounds/kg
chord: average of A and C 4.7552, halfway 4.4683, gap 0.2869
slopes at A by formula (1.2244, 4.2000); by central differences (1.2244, 4.2000)
tangent at A predicts C: 3.6887 + 2.4487 + (-1.2600) = 4.8774; true 5.8217; gap 0.9442
tangent floor at (3 min, 40%): 6.1374 > 6, out of spec untasted; true 7.3217
Hessian at A by formula [[0.4122, 1.0000], [1.0000, 8.0000]]; by second differences [[0.4122, 1.0000], [1.0000, 8.0000]]
at A: determinant 2.2974, trace 8.4122, eigenvalues 0.2826 and 8.1296
determinant 2e^(t/2) - 1 is at least 1.0000 for t >= 0; turns negative below t = -1.3863
step 1 quotients, s = 0.5, 0.1, 0.01, 0.001: 1.5591, 1.2500, 1.1946, 1.1893; limit 1.1887; ceiling 2.1330
step 4 slopes at C (2.3408, 3.8000); slope change along C - A: 2.3530
mu, least eigenvalue on the box (t = 0): formula 0.1230, grid 0.1230
L, largest eigenvalue on the box (t = 3): formula 8.1424, grid 8.1424
sandwich for C: 4.8774 + 0.2516 = 5.1291 <= 5.8217 <= 21.5287
grid: 42 recipes, 861 pairs x 3 weights, 1722 ordered pairs
B, least slack: chord 0.004637, tangent 0.024025, least eigenvalue 0.1230
k = 4, least slack: chord -0.6262, tangent -3.0183, least eigenvalue -1.4442
k = 4, chords along the axes only: least slack 0.006512; diagonal at t = 1: 0.4122 and 8.0000; determinant -12.7026
k = 4 chord: (0 min, 50%) 3.0000, (2 min, 0%) 3.7183, average 3.3591; halfway (1 min, 25%) 3.8987
levelling curve: S(1) = 2.1515, S(3) = 5.8485, slope at 3 1.5729; tangent at 3 claims S(1) >= 2.7027
levelling curve: S''(1) = 0.7269, S''(3) = -0.7269, by second differences -0.7269
try: k = 1.5, least eigenvalue at t = 0: -0.0302; switch-off k = 1.4142
try: t = -2, determinant -0.2642, least eigenvalue -0.0325
try: tangent at C predicts A: 2.2800; true 3.6887
chart theta: 0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0
chart B from A to C: 3.69, 3.81, 3.95, 4.11, 4.28, 4.47, 4.68, 4.92, 5.19, 5.49, 5.82
chart chord: 3.69, 3.90, 4.12, 4.33, 4.54, 4.76, 4.97, 5.18, 5.40, 5.61, 5.82
chart tangent at A: 3.69, 3.81, 3.93, 4.05, 4.16, 4.28, 4.40, 4.52, 4.64, 4.76, 4.88
ALL CHECKS PASS
```

### Rust

The same checks, the same labels, built with `rustc --edition 2021 -O`.

```rust
// Convex functions and their tests -- the same check as the Python, in Rust.  No crates.
// Bitterness B on a 0-10 tasting scale.  t = roast minutes past first crack (0 to 3),
// w = robusta share of the blend (0 to 0.5), k = how fast robusta's bitterness grows with
// roast time (1 in the model).  Three tests -- chord, tangent, curvature -- run on
// a grid of 42 recipes, for B and for two curves that fail; each has an independent road.
type P = (f64, f64);
type M = [[f64; 2]; 2];

fn bk(t: f64, w: f64, k: f64) -> f64 { 1.0 + (t / 2.0).exp() + k * t * w + 4.0 * w * w }
fn b(t: f64, w: f64) -> f64 { bk(t, w, 1.0) }
fn g4(t: f64, w: f64) -> f64 { bk(t, w, 4.0) }
fn grad(t: f64, w: f64, k: f64) -> P { ((t / 2.0).exp() / 2.0 + k * w, k * t + 8.0 * w) }   // slopes, by hand
fn hess(t: f64, k: f64) -> M { [[(t / 2.0).exp() / 4.0, k], [k, 8.0]] }                   // curvatures, by hand
fn s(t: f64) -> f64 { 8.0 / (1.0 + (2.0 - t).exp()) }                                    // levels off

fn num_grad(f: fn(f64, f64) -> f64, p: P) -> P {     // slopes again, by central differences
    let h = 1e-5;
    ((f(p.0 + h, p.1) - f(p.0 - h, p.1)) / (2.0 * h), (f(p.0, p.1 + h) - f(p.0, p.1 - h)) / (2.0 * h))
}
fn num_hess(f: fn(f64, f64) -> f64, p: P) -> M {     // curvatures again, by second differences
    let h = 1e-3;
    let at = |a: f64, c: f64| f(p.0 + a * h, p.1 + c * h);
    let hxy = (at(1.0, 1.0) - at(1.0, -1.0) - at(-1.0, 1.0) + at(-1.0, -1.0)) / (4.0 * h * h);
    [[(at(1.0, 0.0) - 2.0 * at(0.0, 0.0) + at(-1.0, 0.0)) / (h * h), hxy],
     [hxy, (at(0.0, 1.0) - 2.0 * at(0.0, 0.0) + at(0.0, -1.0)) / (h * h)]]
}
fn eig(m: M) -> P {                                   // eigenvalues of a symmetric 2 x 2, smaller first
    let (tr, gap) = (m[0][0] + m[1][1], ((m[0][0] - m[1][1]).powi(2) + 4.0 * m[0][1].powi(2)).sqrt());
    ((tr - gap) / 2.0, (tr + gap) / 2.0)
}
fn dot(u: P, v: P) -> f64 { u.0 * v.0 + u.1 * v.1 }
fn mix(th: f64, x: P, y: P) -> P { (th * x.0 + (1.0 - th) * y.0, th * x.1 + (1.0 - th) * y.1) }

fn three_tests(f: fn(f64, f64) -> f64, k: f64, grid: &[P], pairs: &[(P, P)]) -> (f64, f64, f64) {
    let mut chord = f64::INFINITY;                    // least slack of each test over the grid
    for &(x, y) in pairs { for th in [0.25, 0.5, 0.75] {
        let m = mix(th, x, y);
        chord = chord.min(th * f(x.0, x.1) + (1.0 - th) * f(y.0, y.1) - f(m.0, m.1));
    } }
    let mut tang = f64::INFINITY;
    for &x in grid { for &y in grid { if x != y {
        tang = tang.min(f(y.0, y.1) - f(x.0, x.1) - dot(grad(x.0, x.1, k), (y.0 - x.0, y.1 - x.1)));
    } } }
    let curv = grid.iter().map(|&p| eig(num_hess(f, p)).0).fold(f64::INFINITY, f64::min);
    (chord, tang, curv)
}
fn list(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ") }

fn main() {
    let grid: Vec<P> = (0..7).flat_map(|i| (0..6).map(move |j| (0.5 * i as f64, 0.1 * j as f64))).collect();
    let mut pairs: Vec<(P, P)> = Vec::new();
    for n in 0..grid.len() { for m in n + 1..grid.len() { pairs.push((grid[n], grid[m])) } }
    let (a, c, m, f) = ((1.0, 0.4), (3.0, 0.1), (2.0, 0.25), (3.0, 0.4));
    let (ba, bc, bm) = (b(a.0, a.1), b(c.0, c.1), b(m.0, m.1));
    let (ga, gc, d) = (grad(a.0, a.1, 1.0), grad(c.0, c.1, 1.0), (c.0 - a.0, c.1 - a.1));
    let (tan_c, floor_f) = (ba + dot(ga, d), ba + dot(ga, (f.0 - a.0, f.1 - a.1)));
    let (ha, na) = (hess(a.0, 1.0), num_hess(b, a));
    let quot: Vec<f64> = [0.5, 0.1, 0.01, 0.001].iter().map(|&sv| { let p = mix(1.0 - sv, a, c); (b(p.0, p.1) - ba) / sv }).collect();
    let mono = dot((gc.0 - ga.0, gc.1 - ga.1), d);
    let (mu, l) = (eig(hess(0.0, 1.0)).0, eig(hess(3.0, 1.0)).1);   // Hessian rises with t only
    let eg: Vec<P> = grid.iter().map(|&p| eig(num_hess(b, p))).collect();
    let mu_g = eg.iter().map(|e| e.0).fold(f64::INFINITY, f64::min);
    let l_g = eg.iter().map(|e| e.1).fold(f64::NEG_INFINITY, f64::max);
    let (lo, hi) = (tan_c + mu / 2.0 * dot(d, d), tan_c + l / 2.0 * dot(d, d));
    let ok_b = three_tests(b, 1.0, &grid, &pairs);
    let bad_g = three_tests(g4, 4.0, &grid, &pairs);
    let axis: Vec<(P, P)> = pairs.iter().cloned().filter(|(x, y)| x.0 == y.0 || x.1 == y.1).collect();
    let axis_g = three_tests(g4, 4.0, &grid, &axis).0;
    let hg = hess(1.0, 4.0);
    let (s1, s3) = (s(1.0), s(3.0));
    let (d1, d3) = (s1 * (8.0 - s1) / 8.0, s3 * (8.0 - s3) / 8.0);             // S' = S(8 - S)/8
    let (c1, c3) = (d1 * (8.0 - 2.0 * s1) / 8.0, d3 * (8.0 - 2.0 * s3) / 8.0); // S'' = S'(8 - 2S)/8
    let n3 = (s(3.001) - 2.0 * s3 + s(2.999)) / 1e-6;
    let tan_s1 = s3 + d3 * (1.0 - 3.0);
    let th: Vec<f64> = (0..11).map(|i| 0.1 * i as f64).collect();
    let nga = num_grad(b, a);
    println!("model: B(t, w) = 1 + e^(t/2) + t*w + 4*w^2; t in [0, 3] min, w in [0, 0.5]");
    println!("prices: arabica 9.00, robusta 5.00 pounds/kg; e^(1/2) = {:.4}, e^1 = {:.4}, e^(3/2) = {:.4}", 0.5f64.exp(), 1f64.exp(), 1.5f64.exp());
    for (name, p, bv) in [("A", a, ba), ("C", c, bc), ("halfway", m, bm)] {
        println!("recipe {} ({:.0} min, {:.0}% robusta): B = {:.4}, cost {:.2} pounds/kg", name, p.0, 100.0 * p.1, bv, 9.0 - 4.0 * p.1);
    }
    println!("chord: average of A and C {:.4}, halfway {:.4}, gap {:.4}", (ba + bc) / 2.0, bm, (ba + bc) / 2.0 - bm);
    println!("slopes at A by formula ({:.4}, {:.4}); by central differences ({:.4}, {:.4})", ga.0, ga.1, nga.0, nga.1);
    println!("tangent at A predicts C: {:.4} + {:.4} + ({:.4}) = {:.4}; true {:.4}; gap {:.4}", ba, ga.0 * d.0, ga.1 * d.1, tan_c, bc, bc - tan_c);
    println!("tangent floor at (3 min, 40%): {:.4} > 6, out of spec untasted; true {:.4}", floor_f, b(f.0, f.1));
    println!("Hessian at A by formula [[{:.4}, {:.4}], [{:.4}, {:.4}]]; by second differences [[{:.4}, {:.4}], [{:.4}, {:.4}]]",
             ha[0][0], ha[0][1], ha[1][0], ha[1][1], na[0][0], na[0][1], na[1][0], na[1][1]);
    println!("at A: determinant {:.4}, trace {:.4}, eigenvalues {:.4} and {:.4}", ha[0][0] * ha[1][1] - 1.0, ha[0][0] + 8.0, eig(ha).0, eig(ha).1);
    println!("determinant 2e^(t/2) - 1 is at least {:.4} for t >= 0; turns negative below t = {:.4}", 2.0 * 0f64.exp() - 1.0, -2.0 * 2f64.ln());
    println!("step 1 quotients, s = 0.5, 0.1, 0.01, 0.001: {}; limit {:.4}; ceiling {:.4}", list(&quot, 4), dot(ga, d), bc - ba);
    println!("step 4 slopes at C ({:.4}, {:.4}); slope change along C - A: {:.4}", gc.0, gc.1, mono);
    println!("mu, least eigenvalue on the box (t = 0): formula {:.4}, grid {:.4}", mu, mu_g);
    println!("L, largest eigenvalue on the box (t = 3): formula {:.4}, grid {:.4}", l, l_g);
    println!("sandwich for C: {:.4} + {:.4} = {:.4} <= {:.4} <= {:.4}", tan_c, mu / 2.0 * dot(d, d), lo, bc, hi);
    println!("grid: {} recipes, {} pairs x 3 weights, {} ordered pairs", grid.len(), pairs.len(), grid.len() * (grid.len() - 1));
    println!("B, least slack: chord {:.6}, tangent {:.6}, least eigenvalue {:.4}", ok_b.0, ok_b.1, ok_b.2);
    println!("k = 4, least slack: chord {:.4}, tangent {:.4}, least eigenvalue {:.4}", bad_g.0, bad_g.1, bad_g.2);
    println!("k = 4, chords along the axes only: least slack {:.6}; diagonal at t = 1: {:.4} and {:.4}; determinant {:.4}", axis_g, hg[0][0], hg[1][1], hg[0][0] * 8.0 - 16.0);
    println!("k = 4 chord: (0 min, 50%) {:.4}, (2 min, 0%) {:.4}, average {:.4}; halfway (1 min, 25%) {:.4}", g4(0.0, 0.5), g4(2.0, 0.0), (g4(0.0, 0.5) + g4(2.0, 0.0)) / 2.0, g4(1.0, 0.25));
    println!("levelling curve: S(1) = {:.4}, S(3) = {:.4}, slope at 3 {:.4}; tangent at 3 claims S(1) >= {:.4}", s1, s3, d3, tan_s1);
    println!("levelling curve: S''(1) = {:.4}, S''(3) = {:.4}, by second differences {:.4}", c1, c3, n3);
    println!("try: k = 1.5, least eigenvalue at t = 0: {:.4}; switch-off k = {:.4}", eig(hess(0.0, 1.5)).0, 2f64.sqrt());
    println!("try: t = -2, determinant {:.4}, least eigenvalue {:.4}", 2.0 * (-1f64).exp() - 1.0, eig(hess(-2.0, 1.0)).0);
    println!("try: tangent at C predicts A: {:.4}; true {:.4}", bc + dot(gc, (-d.0, -d.1)), ba);
    println!("chart theta: {}", list(&th, 1));
    println!("chart B from A to C: {}", list(&th.iter().map(|&x| { let p = mix(1.0 - x, a, c); b(p.0, p.1) }).collect::<Vec<_>>(), 2));
    println!("chart chord: {}", list(&th.iter().map(|&x| (1.0 - x) * ba + x * bc).collect::<Vec<_>>(), 2));
    println!("chart tangent at A: {}", list(&th.iter().map(|&x| ba + x * dot(ga, d)).collect::<Vec<_>>(), 2));
    for &p in &grid {                                                           // slopes two ways
        let (u, v) = (grad(p.0, p.1, 1.0), num_grad(b, p));
        assert!((u.0 - v.0).abs() < 1e-6 && (u.1 - v.1).abs() < 1e-6);
        let (hf, hn) = (hess(p.0, 1.0), num_hess(b, p));                        // curvatures two ways
        assert!((0..2).all(|i| (0..2).all(|j| (hf[i][j] - hn[i][j]).abs() < 1e-4)));
    }
    assert!(ok_b.0.min(ok_b.1).min(ok_b.2) > 0.0 && bad_g.0.max(bad_g.1).max(bad_g.2) < 0.0 && axis_g > 0.0);
    assert!(tan_c < bc && (quot[3] - dot(ga, d)).abs() < 1e-2 && quot.iter().all(|&q| q <= bc - ba) && mono > 0.0);
    assert!((mu - mu_g).abs() < 1e-5 && (l - l_g).abs() < 1e-5 && lo <= bc && bc <= hi);   // mu and L two ways
    assert!(tan_s1 > s1 && c1 > 0.0 && 0.0 > c3 && (n3 - c3).abs() < 1e-5);              // the levelling curve fails
    assert!((tan_s1 - (s3 - (s(3.0 + 1e-5) - s(3.0 - 1e-5)) / 1e-5)).abs() < 1e-6);       // its tangent value two ways
    let along = |sv: f64| { let p = mix(sv, a, c); b(p.0, p.1) };
    assert!((tan_c - ba - (along(1.0 - 1e-5) - along(1.0 + 1e-5)) / 2e-5).abs() < 1e-6); // tangent at A two ways
    let mut mats: Vec<M> = vec![ha, hess(0.0, 1.0), hess(3.0, 1.0), hess(0.0, 1.5), hess(-2.0, 1.0)];
    for fun in [b, g4] { for &p in &grid { mats.push(num_hess(fun, p)); } }
    assert!(mats.iter().all(|h| { let (l1, l2) = eig(*h); l1 <= l2 && (l1 + l2 - h[0][0] - h[1][1]).abs() < 1e-9
        && (l1 * l2 - h[0][0] * h[1][1] + h[0][1] * h[1][0]).abs() < 1e-9 }));   // every eigenvalue pair: sum = trace, product = determinant
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-11 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
model: B(t, w) = 1 + e^(t/2) + t*w + 4*w^2; t in [0, 3] min, w in [0, 0.5]
prices: arabica 9.00, robusta 5.00 pounds/kg; e^(1/2) = 1.6487, e^1 = 2.7183, e^(3/2) = 4.4817
recipe A (1 min, 40% robusta): B = 3.6887, cost 7.40 pounds/kg
recipe C (3 min, 10% robusta): B = 5.8217, cost 8.60 pounds/kg
recipe halfway (2 min, 25% robusta): B = 4.4683, cost 8.00 pounds/kg
chord: average of A and C 4.7552, halfway 4.4683, gap 0.2869
slopes at A by formula (1.2244, 4.2000); by central differences (1.2244, 4.2000)
tangent at A predicts C: 3.6887 + 2.4487 + (-1.2600) = 4.8774; true 5.8217; gap 0.9442
tangent floor at (3 min, 40%): 6.1374 > 6, out of spec untasted; true 7.3217
Hessian at A by formula [[0.4122, 1.0000], [1.0000, 8.0000]]; by second differences [[0.4122, 1.0000], [1.0000, 8.0000]]
at A: determinant 2.2974, trace 8.4122, eigenvalues 0.2826 and 8.1296
determinant 2e^(t/2) - 1 is at least 1.0000 for t >= 0; turns negative below t = -1.3863
step 1 quotients, s = 0.5, 0.1, 0.01, 0.001: 1.5591, 1.2500, 1.1946, 1.1893; limit 1.1887; ceiling 2.1330
step 4 slopes at C (2.3408, 3.8000); slope change along C - A: 2.3530
mu, least eigenvalue on the box (t = 0): formula 0.1230, grid 0.1230
L, largest eigenvalue on the box (t = 3): formula 8.1424, grid 8.1424
sandwich for C: 4.8774 + 0.2516 = 5.1291 <= 5.8217 <= 21.5287
grid: 42 recipes, 861 pairs x 3 weights, 1722 ordered pairs
B, least slack: chord 0.004637, tangent 0.024025, least eigenvalue 0.1230
k = 4, least slack: chord -0.6262, tangent -3.0183, least eigenvalue -1.4442
k = 4, chords along the axes only: least slack 0.006512; diagonal at t = 1: 0.4122 and 8.0000; determinant -12.7026
k = 4 chord: (0 min, 50%) 3.0000, (2 min, 0%) 3.7183, average 3.3591; halfway (1 min, 25%) 3.8987
levelling curve: S(1) = 2.1515, S(3) = 5.8485, slope at 3 1.5729; tangent at 3 claims S(1) >= 2.7027
levelling curve: S''(1) = 0.7269, S''(3) = -0.7269, by second differences -0.7269
try: k = 1.5, least eigenvalue at t = 0: -0.0302; switch-off k = 1.4142
try: t = -2, determinant -0.2642, least eigenvalue -0.0325
try: tangent at C predicts A: 2.2800; true 3.6887
chart theta: 0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0
chart B from A to C: 3.69, 3.81, 3.95, 4.11, 4.28, 4.47, 4.68, 4.92, 5.19, 5.49, 5.82
chart chord: 3.69, 3.90, 4.12, 4.33, 4.54, 4.76, 4.97, 5.18, 5.40, 5.61, 5.82
chart tangent at A: 3.69, 3.81, 3.93, 4.05, 4.16, 4.28, 4.40, 4.52, 4.64, 4.76, 4.88
ALL CHECKS PASS
```

The two outputs match line for line.

> [!TIP]
> **Try changing**
> - Guess first: does a slightly stronger robusta-and-roast effect still give a bowl? Set the default `k=1.0` to `k=1.5` in `B`, `grad` and `hess`. The least eigenvalue at t = 0 drops to −0.0302 and the third assert fails. The switch-off point is k = √2 = 1.4142, where the determinant 2 − k² at t = 0 reaches zero.
> - Guess first: is the tangent at C also a floor at A? Yes: it predicts 2.2800, and the true value is 3.6887. Every tangent of a convex function is a floor, wherever it is drawn.
> - Guess first: is B convex for negative roast times? Change `range(7)` in `GRID` to start at −4 (`range(-4, 7)`). The grid now reaches t = −2, where the determinant is −0.2642 and the least eigenvalue −0.0325, and the third assert fails.

---

## The usual mistake

> [!warning]
> **Testing each setting on its own.** Curving up in roast time, and curving up in robusta share, does not make a bowl. With k = 4 the diagonal entries of the Hessian are 0.4122 and 8, both positive, and every chord along the axes passes. But the determinant at 1 minute is −12.7026, and the halfway blend of (0 min, 50%) and (2 min, 0%) scores 3.8987, above the chord's 3.3591. The cross term needs its own check, in every direction.
>
> - **Reading grid passes as proof.** All 861 chord pairs pass for B, the closest with slack 0.004637. That says nothing between grid points. The determinant formula, at least 1.0000 for every t ≥ 0, is the proof.
> - **Reading the tangent as a forecast.** The tangent at A predicts 4.8774 at C; the truth is 5.8217. A tangent of a convex function is a floor: a guaranteed under-estimate, low or equal, not a forecast.
> - **Checking curvature at one point.** The levelling curve S passes at 1 minute, S''(1) = 0.7269, and fails at 3, S''(3) = −0.7269. Its tangent at 3 minutes then claims a floor of 2.7027 where the truth is 2.1515.
> - **Forgetting the domain.** B's formula is convex for t > −1.3863 only. At t = −2 the determinant is −0.2642. Convexity is always "convex on a stated set".

---

## Where you meet it in real life

- **Blending and recipe software.** If every quality score is convex and must stay under a limit, the in-spec recipes form a convex set ([Convex sets](02-convex-sets.md)): mixing two good recipes never makes a bad one. The roaster's halfway recipe, 4.4683 against a guarantee of 4.7552, is the small case of this.
- **Machine-learning losses.** The usual proof that logistic regression's loss is convex is this card's curvature test: its Hessian is a sum of one-direction pieces, each positive semidefinite.
- **Portfolio risk.** A portfolio's variance has as Hessian twice the covariance matrix, which is always positive semidefinite, so variance is convex in the weights ([Quadratic forms](../../03-Algebra/07-Eigenvalues%20and%20Symmetric%20Matrices/05-quadratic-forms-and-positive-definite.md)).
- **Solvers that cut.** Outer-approximation and cutting-plane methods replace a convex constraint by tangent planes. Each plane is a safe cut because of the tangent test: the roaster's floor of 6.1374 at (3 min, 40%) is one such cut.
- **Convergence speeds.** μ and L set how fast gradient methods close in, a story for [Gradient descent](../02-Unconstrained%20Methods/02-gradient-descent-and-its-rate.md). For the roaster they are 0.1230 and 8.1424.

> **Say it back**
> A smooth function is convex exactly when its graph sits under every chord, over every tangent plane, and curves up in every direction, everywhere. The tangent test follows from the chord test by shrinking the chord; the chord test follows from two tangents at the mix; the curvature test gives the tangent test through Taylor's theorem, and adding two tangents gives it back. For the roaster, the determinant $2e^{t/2} - 1$ stays positive, so every recipe between two in-spec recipes is in spec. Sampled chords can only disprove convexity; the curvature formula proves it.

---

## What this builds on

- [Convex sets](02-convex-sets.md): the mix θx + (1 − θ)y and domains that hold every segment, on which a convex function lives.
- [Convex functions](../../06-Calculus%20and%20analysis/07-Several%20Variables/09-convex-functions.md): the chord definition and the curvature test in its "v-transpose H v at least zero" form, proved there for one direction at a time.
- [Quadratic forms](../../03-Algebra/07-Eigenvalues%20and%20Symmetric%20Matrices/05-quadratic-forms-and-positive-definite.md): when a symmetric matrix is positive (semi)definite, and the two-entry test used on the roaster's Hessian.

## Where this goes next

- [Convexity pays off](04-local-minima-are-global-when-convex.md): with the tangent test, a flat point is a certificate that nothing anywhere is lower.
- [Jensen's inequality](05-jensen-and-supporting-lines.md): the chord test stretched to averages of many points, and tangents as supporting lines.
- [Subgradients](07-subgradients.md): the tangent test kept where the graph has a kink and no gradient exists.
- [Building convex functions](09-operations-that-preserve-convexity.md): proving convexity by assembly rules, without computing a Hessian.
- [Quadratic programs](../06-Conic%2C%20Quadratic%20and%20Stochastic%20Programs/01-quadratic-programs-and-markowitz.md): a convex quadratic cost, whose constant Hessian makes the curvature test a single matrix check.

The curvature test needs two derivatives; what certifies convexity for a function with corners, such as a cost whose price changes at a volume break, is the question this card leaves open.

---

## Sources

Verified 2026-11-11: every link below resolves to the publisher's page.

- Boyd, Stephen, and Lieven Vandenberghe. *Convex Optimization*. Cambridge University Press, 2004. [doi:10.1017/CBO9780511804441](https://doi.org/10.1017/CBO9780511804441). Sections 3.1.3 and 3.1.4: the first-order (tangent) and second-order (curvature) conditions; section 9.1.2: strong convexity and the quadratic sandwich.
- Nesterov, Yurii. *Lectures on Convex Optimization*, 2nd ed. Springer, 2018. [doi:10.1007/978-3-319-91578-4](https://doi.org/10.1007/978-3-319-91578-4). Chapter 2: smooth convex functions, the constants μ and L, and the equivalence of first- and second-order conditions.
- Hiriart-Urruty, J.-B., and C. Lemaréchal. *Fundamentals of Convex Analysis*. Springer, 2001. [doi:10.1007/978-3-642-56468-0](https://doi.org/10.1007/978-3-642-56468-0). Chapter B: first- and second-order characterisations of convex functions, with full proofs.
- Rockafellar, R. Tyrrell. *Convex Analysis*. Princeton University Press, 1970. [Publisher page](https://press.princeton.edu/books/paperback/9780691015866/convex-analysis). Section 4: the Hessian criterion on an open convex set.
