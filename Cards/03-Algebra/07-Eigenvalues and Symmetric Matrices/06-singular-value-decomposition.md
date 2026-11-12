# The singular value decomposition: every matrix is rotate, stretch the axes, rotate, and the stretch factors are the singular values

[Syllabus](../../../SYLLABUS.md) → [Algebra](../README.md) → [Eigenvalues and Symmetric Matrices](../README.md#s07) → The singular value decomposition

---

## General Overview

A game draws a round sprite, a coin one unit in radius, and hands every point to the matrix `[[3, 0], [4, 5]]`: (east, north) comes back as (3 east, 4 east + 5 north). The rim was a circle; it returns a tilted ellipse.

By how much did the coin stretch? No single entry says, since the 4 spills east into north. The rim's longest radius comes to 6.708204 and its shortest to 2.236068, at right angles.

Every matrix with real entries does its job in three moves: swing the input onto two perpendicular directions that suit it, stretch along each by a fixed non-negative factor, swing the result onto two perpendicular output directions. A move that keeps lengths and angles is called an **orthogonal matrix**: a turn, perhaps with a mirror flip.

**Every matrix is an orthogonal move, a stretch along perpendicular axes, and a second orthogonal move; the stretch factors are the singular values.**

**What kind of fact this is:** a theorem, proved on this card in Why it works.

### The picture: three moves

```mermaid
flowchart LR
    X["a point on the<br/>coin's round rim"] --> V["read it along the<br/>two input axes"]
    V --> S["stretch those two numbers<br/>by 6.708204 and 2.236068"]
    S --> U["lay the result along<br/>the two output axes"]
    U --> E["the matching point on<br/>the tilted ellipse"]
```

Sizes change in the middle box only.

---

## The formula

For every matrix $A$ with real entries:

$$A = U S V^T$$

**Read it aloud:** read the input along one set of perpendicular axes, stretch each number by its factor, lay the result along another set.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $A$ | the matrix, read as a map | `[[3, 0], [4, 5]]` | every factor moves with it |
| $V$, $v_1$, $v_2$, or $v_i$ for either | input axes: perpendicular columns of $V$, length 1 each; $V^T$ swaps rows and columns, reporting coordinates along them | (0.707107, 0.707107) and (0.707107, −0.707107) | — |
| $S$, $\sigma_1$, $\sigma_2$, or $\sigma_i$ for either | the stretch matrix: the **singular values**, said "sigma", down its diagonal, largest first, never negative | diagonal 6.708204 and 2.236068 | that half-axis lengthens |
| $U$, $u_1$, $u_2$ | output axes: perpendicular columns of $U$, length 1 each | (0.316228, 0.948683) and (0.948683, −0.316228) | — |
| $G$, $\lambda_1$, $\lambda_2$, or $\lambda_i$ for either | shorthand for $A^T A$, symmetric, with its eigenvalues, said "lambda": the squared factors | `[[25, 20], [20, 25]]`, 45 and 5 | — |
| $r$ | the rank: factors above zero | 2 | more directions survive |

The factors are square roots of $G$'s eigenvalues:

$$\sigma_i = \sqrt{\lambda_i}$$

Each output axis, one for each factor above zero, is its input axis's image scaled to length 1:

$$u_i = \frac{A v_i}{\sigma_i}$$

### When it holds

- **Real entries, any number of rows and columns.** Nothing else is required: rectangular and flattening matrices included. Complex entries have their own version.
- **Lengths by the dot product, one unit system throughout.** Rescale a coordinate and the factors change, so "large" and "small" depend on the units.
- **Two sets of axes, not one.** Demand a single set for both sides and most matrices refuse; that stricter demand is [Diagonalisation](03-diagonalisation-and-matrix-powers.md).
- **The factors are unique, the axes are not.** Reverse a matched pair $v_1$ and $u_1$ and the same matrix returns. Building $G$ by hand suits small cases only: forming $A^T A$ doubles the number of digits lost to rounding.

---

## Why it works

### Step 0: ask about length, not direction

Eigenvectors answer "which inputs come back pointing the same way" ([Eigenvalues and eigenvectors](02-eigenvalues-and-eigenvectors.md)). For a matrix that is not symmetric there may be too few, and nothing makes them perpendicular: the sprite's eigenvalues are 5.000000 and 3.000000, neither the 6.708204 the rim reached.

Ask about length instead. Of all inputs of length 1, which comes out longest? Squared length makes that a dot product:

$$|A x|^2 = (A x) \cdot (A x) = x^T A^T A x = x^T G x$$

x is any input, $x^T$ that input as a row, $|A x|$ its output's length, $G$ shorthand for $A^T A$. $G$ is symmetric, and $x^T G x$ is a squared length, never negative ([Quadratic forms](05-quadratic-forms-and-positive-definite.md)).

### Step 1: the spectral theorem hands over the input axes

A symmetric matrix has a full set of perpendicular unit eigenvectors with real eigenvalues ([The spectral theorem](04-spectral-theorem.md)). Call $G$'s pair $v_1$ and $v_2$, eigenvalues $\lambda_1$ and $\lambda_2$, largest first: the input axes, and $A$ was never asked to be symmetric or square.

Feed one in: $G v_i$ is $\lambda_i$ times $v_i$, and $v_i$ has length 1, so

$$|A v_i|^2 = v_i^T G v_i = \lambda_i$$

The output length is the square root of $\lambda_i$, and that is where the formula's square root comes from. For the sprite $G$ is `[[25, 20], [20, 25]]`, its eigenvalues 45 and 5, the stretches 6.708204 and 2.236068.

```
Stretch factors against the matrix's own eigenvalues, one bar step = 0.25 of a multiplier

longest stretch            ███████████████████████████  6.708204
shortest stretch           █████████                    2.236068
larger eigenvalue of A     ████████████████████         5.000000
smaller eigenvalue of A    ████████████                 3.000000
```

The top two bars are the half-axes; the bottom two answer another question.

### Step 2: the output axes come out perpendicular

Compare the two outputs with a dot product. $G v_2$ is $\lambda_2$ times $v_2$, and the axes are perpendicular:

$$(A v_1) \cdot (A v_2) = v_1^T G v_2 = \lambda_2 (v_1 \cdot v_2) = 0$$

Perpendicular in, perpendicular out. Each output is $\sigma_i$ long, so dividing by that length leaves perpendicular unit vectors with $A v_i = \sigma_i u_i$. For the sprite $A v_1$ is (2.121320, 6.363961), which over 6.708204 is $u_1$, (0.316228, 0.948683).

### Step 3: rebuild any input

Any input x is the sum of its pieces along the input axes:

$$x = (x \cdot v_1) v_1 + (x \cdot v_2) v_2$$

Apply the matrix piece by piece, using $A v_i = \sigma_i u_i$:

$$A x = \sigma_1 (x \cdot v_1) u_1 + \sigma_2 (x \cdot v_2) u_2$$

Three jobs in turn: collecting $x \cdot v_1$ and $x \cdot v_2$ is $V^T x$, multiplying each by its factor is $S$, laying the results along $u_1$ and $u_2$ is $U$. True for every input, so the matrices are equal: $A = U S V^T$. The code rebuilds `[[3, 0], [4, 5]]` exactly.

<details>
<summary>Detailed proof, for any number of rows and columns</summary>

Let $A$ have real entries, any shape, with n columns. $G = A^T A$ is square and symmetric, so the spectral theorem gives perpendicular unit eigenvectors $v_1, \ldots, v_n$ with eigenvalues $\lambda_1 \ge \ldots \ge \lambda_n$, none negative since Step 1 makes $\lambda_k = |A v_k|^2$. Let $r$ count those above zero. For k up to $r$, set $\sigma_k = \sqrt{\lambda_k}$ and $u_k = A v_k / \sigma_k$, perpendicular unit vectors by Step 2; above $r$ the length is zero, so that axis is flattened. Extend $u_1, \ldots, u_r$ to a full perpendicular unit set, the extras meeting zeros in $S$. Then $x = (x \cdot v_1) v_1 + \ldots + (x \cdot v_n) v_n$ gives $A x = \sigma_1 (x \cdot v_1) u_1 + \ldots + \sigma_r (x \cdot v_r) u_r$, which is $U S V^T x$, and matrices agreeing on every input are equal. Repeated eigenvalues leave the axes unfixed, the factors fixed.

</details>

### Step 4: two readings the factors hand over

The determinant, det A, is the factor by which a square matrix scales area, negative when it mirrors ([Determinants](../05-Solving%20Systems/04-determinants.md)). An orthogonal move cannot change area except to mirror it, so its determinant is 1 or −1. For a square matrix:

$$|\det A| = \sigma_1 \sigma_2$$

Here 6.708204 times 2.236068 is 15.000000, and so is 3 × 5 − 0 × 4 from the entries: the ellipse covers 15.000000 times the coin's area.

Second, the reading that matters for solving systems: the count of factors above zero is the rank, an axis with a zero factor being a direction the matrix flattens ([Rank and nullity](../05-Solving%20Systems/05-rank-nullity.md)). The sprite has rank 2; a rectangular matrix, with no determinant to compare, reads the same way. The same non-zero factors come from $A A^T$, smaller when $A$ is wide.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| build $G = A^T A$ | dot A's columns together | `[[25, 20], [20, 25]]` |
| its characteristic equation | (25 − λ)(25 − λ) − 20 × 20 = 0 | λ = 45 and 5 |
| the singular values | square roots of 45 and 5 | **6.708204 and 2.236068** |
| the input axes | (20, 45 − 25) and (20, 5 − 25), scaled to length 1 | (0.707107, 0.707107) and (0.707107, −0.707107) |
| their images | A times each axis | (2.121320, 6.363961) and (2.121320, −0.707107) |
| the output axes | each image over its factor | (0.316228, 0.948683) and (0.948683, −0.316228) |
| rebuild the matrix | U S V transpose, multiplied | **`[[3, 0], [4, 5]]`** |
| the area factor | 6.708204 × 2.236068 | **15.000000**, as is det A |
| the rank | factors above zero | **2** |

The rim is an ellipse: longest radius 6.708204 along (0.316228, 0.948683), shortest 2.236068.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| The matrix's own eigenvalues read as half-axes | 5.000000 and 3.000000 | A is not symmetric, so those directions are not perpendicular, not the ellipse's axes |
| G's eigenvalues used without square roots | product 225.000000, not 15.000000 | 45 and 5 are squared stretches |

---

## Code, from first principles, and it actually runs

The factors are reached twice, once by algebra and once by measurement. Road one is the hand method: build $G = A^T A$, solve its characteristic quadratic, take square roots, read off the axes. Road two measures instead, walking 100002 directions and keeping the longest and shortest outputs. Four assertions pin the product against the determinant, the factors against the entries, and the rebuild against the matrix. A second matrix, `[[1, 2], [2, 4]]`, has factors 5.000000 and 0.000000: rank 1, flattening (0.894427, −0.447214) to the zero vector.

### Python

```python
# Singular value decomposition -- the check behind the card.  Nothing is imported.  The
# sprite transform A = [[3, 0], [4, 5]] turns the unit circle into an ellipse.  Road one:
# the stretch factors from the eigenvalues of G = A^T A; road two: measure every direction.
def dot(u, v): return u[0] * v[0] + u[1] * v[1]
def mv(a, v): return [dot(a[0], v), dot(a[1], v)]
def tp(a): return [[a[0][0], a[1][0]], [a[0][1], a[1][1]]]
def mm(a, b): return [[dot(r, c) for c in tp(b)] for r in a]
def det(a): return a[0][0] * a[1][1] - a[0][1] * a[1][0]
def unit(w): n = dot(w, w) ** 0.5; return [w[0] / n, w[1] / n]
def drift(a, b): return max(abs(a[i][j] - b[i][j]) for i in (0, 1) for j in (0, 1))
def f6(v): return "(" + ", ".join(f"{0.0 if abs(x) < 5e-7 else x:.6f}" for x in v) + ")"
def eig2(a):                                      # both roots of the characteristic quadratic
    mid = (a[0][0] + a[1][1]) / 2; gap = (mid * mid - det(a)) ** 0.5
    return [mid + gap, mid - gap]
def svd(a):                                       # road one: the eigen-pairs of G = A^T A
    g = mm(tp(a), a); lam = eig2(g); sig = [x ** 0.5 for x in lam]
    vs = [unit([g[0][1], L - g[0][0]]) for L in lam]          # solves (G - L I)v = 0 by hand
    us = [[x / s for x in mv(a, v)] if s > 1e-12 else [] for s, v in zip(sig, vs)]
    us = [u if u else [-us[0][1], us[0][0]] for u in us]      # a flattened axis: complete the pair
    return g, lam, sig, vs, us
def sweep(a, n):                                  # road two: the stretch in every direction
    hi, lo, hdir, seen = -1.0, 1e18, [0.0, 0.0], 0
    for k in range(n + 1):
        t = k / n; den = 1 + t * t                # (1 - t*t, 2t)/den has length 1 for every t
        for s in (1.0, -1.0):                     # a half turn is enough: -v stretches like v
            v = [(1 - t * t) / den, s * 2 * t / den]; w = mv(a, v); L = dot(w, w); seen += 1
            if L > hi: hi, hdir = L, v
            if L < lo: lo = L
    return hi ** 0.5, lo ** 0.5, hdir, seen
A, B, EYE = [[3.0, 0.0], [4.0, 5.0]], [[1.0, 2.0], [2.0, 4.0]], [[1.0, 0.0], [0.0, 1.0]]
G, lam, sig, vs, us = svd(A)
U, V, S = tp(us), tp(vs), [[sig[0], 0.0], [0.0, sig[1]]]
rebuilt = mm(mm(U, S), tp(V)); hi, lo, hdir, seen = sweep(A, 50000)
squares = sum(x * x for row in A for x in row); cols = [dot(c, c) ** 0.5 for c in tp(A)]
rank = sum(1 for s in sig if s > 1e-12)
GB, lamB, sigB, vsB, usB = svd(B); rankB = sum(1 for s in sigB if s > 1e-12)
print(f"sprite A rows: {f6(A[0])}; {f6(A[1])}; det A {det(A):.6f}")
print(f"G = A^T A rows: {f6(G[0])}; {f6(G[1])}")
print(f"eigenvalues of G: {f6(lam)}; singular values, their square roots: {f6(sig)}")
print(f"input axes v1, v2: {f6(vs[0])}; {f6(vs[1])}")
print(f"images A v1, A v2: {f6(mv(A, vs[0]))}; {f6(mv(A, vs[1]))}")
print(f"output axes u1, u2: {f6(us[0])}; {f6(us[1])}")
print(f"road two, longest and shortest stretch over {seen} directions: {f6([hi, lo])}, "
      f"longest along ({hdir[0]:.4f}, {hdir[1]:.4f})")
print(f"U S V^T rows: {f6(rebuilt[0])}; {f6(rebuilt[1])}; largest drift from perpendicular "
      f"unit axes, U then V: {drift(mm(tp(U), U), EYE):.6f}, {drift(mm(tp(V), V), EYE):.6f}")
print(f"product of singular values {sig[0] * sig[1]:.6f}; absolute determinant {abs(det(A)):.6f}")
print(f"eigenvalues added {lam[0] + lam[1]:.6f}; squares of A's entries added {squares:.6f}")
print(f"nonzero singular values, the rank: {rank}")
print(f"A's own eigenvalues, not the stretches: {f6(eig2(A))}; A's column lengths: {f6(cols)}")
print(f"eigenvalues left unrooted, product {lam[0] * lam[1]:.6f}, "
      f"not the area factor {sig[0] * sig[1]:.6f}")
print(f"flat matrix B rows: {f6(B[0])}; {f6(B[1])}; det B {det(B):.6f}; "
      f"singular values {f6(sigB)}; rank {rankB}")
print(f"B kills its second input axis {f6(vsB[1])}: image {f6(mv(B, vsB[1]))}")
assert abs(hi - sig[0]) < 1e-6 and abs(lo - sig[1]) < 1e-6      # two roads, same stretches
assert abs(sig[0] * sig[1] - abs(det(A))) < 1e-12 and abs(lam[0] + lam[1] - squares) < 1e-12
assert drift(rebuilt, A) < 1e-12 and drift(mm(tp(U), U), EYE) < 1e-12 and drift(mm(tp(V), V), EYE) < 1e-12
assert abs(sigB[0] - 5.0) < 1e-12 and dot(mv(B, vsB[1]), mv(B, vsB[1])) < 1e-24 and (rank, rankB) == (2, 1)
print("ALL CHECKS PASS")
```

**Ran 2026-09-14 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
sprite A rows: (3.000000, 0.000000); (4.000000, 5.000000); det A 15.000000
G = A^T A rows: (25.000000, 20.000000); (20.000000, 25.000000)
eigenvalues of G: (45.000000, 5.000000); singular values, their square roots: (6.708204, 2.236068)
input axes v1, v2: (0.707107, 0.707107); (0.707107, -0.707107)
images A v1, A v2: (2.121320, 6.363961); (2.121320, -0.707107)
output axes u1, u2: (0.316228, 0.948683); (0.948683, -0.316228)
road two, longest and shortest stretch over 100002 directions: (6.708204, 2.236068), longest along (0.7071, 0.7071)
U S V^T rows: (3.000000, 0.000000); (4.000000, 5.000000); largest drift from perpendicular unit axes, U then V: 0.000000, 0.000000
product of singular values 15.000000; absolute determinant 15.000000
eigenvalues added 50.000000; squares of A's entries added 50.000000
nonzero singular values, the rank: 2
A's own eigenvalues, not the stretches: (5.000000, 3.000000); A's column lengths: (5.000000, 5.000000)
eigenvalues left unrooted, product 225.000000, not the area factor 15.000000
flat matrix B rows: (1.000000, 2.000000); (2.000000, 4.000000); det B 0.000000; singular values (5.000000, 0.000000); rank 1
B kills its second input axis (0.894427, -0.447214): image (0.000000, 0.000000)
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Singular value decomposition -- the same check as the Python, in Rust.  No crates.  The
// sprite transform A = [[3, 0], [4, 5]] turns the unit circle into an ellipse.  Road one:
// the stretch factors from the eigenvalues of G = A^T A; road two: measure every direction.
type Mat = [[f64; 2]; 2];
fn dot(u: [f64; 2], v: [f64; 2]) -> f64 { u[0] * v[0] + u[1] * v[1] }
fn mv(a: Mat, v: [f64; 2]) -> [f64; 2] { [dot(a[0], v), dot(a[1], v)] }
fn tp(a: Mat) -> Mat { [[a[0][0], a[1][0]], [a[0][1], a[1][1]]] }
fn mm(a: Mat, b: Mat) -> Mat { let t = tp(b); a.map(|r| [dot(r, t[0]), dot(r, t[1])]) }
fn det(a: Mat) -> f64 { a[0][0] * a[1][1] - a[0][1] * a[1][0] }
fn unit(w: [f64; 2]) -> [f64; 2] { let n = dot(w, w).sqrt(); [w[0] / n, w[1] / n] }
fn drift(a: Mat, b: Mat) -> f64 {                    // largest entry-by-entry gap
    let d = |i: usize, j: usize| (a[i][j] - b[i][j]).abs();
    d(0, 0).max(d(0, 1)).max(d(1, 0)).max(d(1, 1))
}
fn f6(v: [f64; 2]) -> String {                       // two numbers, six decimals, no minus zero
    let v = v.map(|x| if x.abs() < 5e-7 { 0.0 } else { x }); format!("({:.6}, {:.6})", v[0], v[1])
}
fn eig2(a: Mat) -> [f64; 2] {                        // both roots of the characteristic quadratic
    let mid = (a[0][0] + a[1][1]) / 2.0; let gap = (mid * mid - det(a)).sqrt();
    [mid + gap, mid - gap]
}
fn svd(a: Mat) -> (Mat, [f64; 2], [f64; 2], Mat, Mat) {   // road one: eigen-pairs of G = A^T A
    let g = mm(tp(a), a); let lam = eig2(g); let sig = lam.map(f64::sqrt);
    let vs = lam.map(|l| unit([g[0][1], l - g[0][0]]));   // solves (G - L I)v = 0 by hand
    let u1 = mv(a, vs[0]).map(|x| x / sig[0]);
    let u2 = if sig[1] > 1e-12 { mv(a, vs[1]).map(|x| x / sig[1]) }
             else { [-u1[1], u1[0]] };                    // a flattened axis: complete the pair
    (g, lam, sig, vs, [u1, u2])
}
fn sweep(a: Mat, n: i64) -> (f64, f64, [f64; 2], i64) {   // road two: stretch in every direction
    let (mut hi, mut lo, mut hdir, mut seen) = (-1.0f64, 1e18f64, [0.0, 0.0], 0i64);
    for k in 0..=n {
        let t = k as f64 / n as f64; let den = 1.0 + t * t;   // (1 - t*t, 2t)/den has length 1
        for s in [1.0f64, -1.0f64] {         // a half turn is enough: -v stretches like v
            let v = [(1.0 - t * t) / den, s * 2.0 * t / den];
            let w = mv(a, v); let l = dot(w, w); seen += 1;
            if l > hi { hi = l; hdir = v; }
            if l < lo { lo = l; }
        }
    }
    (hi.sqrt(), lo.sqrt(), hdir, seen)
}
fn main() {
    let a: Mat = [[3.0, 0.0], [4.0, 5.0]]; let b: Mat = [[1.0, 2.0], [2.0, 4.0]];
    let eye: Mat = [[1.0, 0.0], [0.0, 1.0]];
    let (g, lam, sig, vs, us) = svd(a);
    let (u, v, s) = (tp(us), tp(vs), [[sig[0], 0.0], [0.0, sig[1]]]);
    let rebuilt = mm(mm(u, s), tp(v)); let (hi, lo, hdir, seen) = sweep(a, 50000);
    let squares: f64 = a.iter().flatten().map(|x| x * x).sum();
    let cols = tp(a).map(|c| dot(c, c).sqrt()); let rank = sig.iter().filter(|&&x| x > 1e-12).count();
    let (_gb, _lamb, sigb, vsb, _usb) = svd(b); let rankb = sigb.iter().filter(|&&x| x > 1e-12).count();
    println!("sprite A rows: {}; {}; det A {:.6}", f6(a[0]), f6(a[1]), det(a));
    println!("G = A^T A rows: {}; {}", f6(g[0]), f6(g[1]));
    println!("eigenvalues of G: {}; singular values, their square roots: {}", f6(lam), f6(sig));
    println!("input axes v1, v2: {}; {}", f6(vs[0]), f6(vs[1]));
    println!("images A v1, A v2: {}; {}", f6(mv(a, vs[0])), f6(mv(a, vs[1])));
    println!("output axes u1, u2: {}; {}", f6(us[0]), f6(us[1]));
    println!("road two, longest and shortest stretch over {} directions: {}, longest along \
              ({:.4}, {:.4})", seen, f6([hi, lo]), hdir[0], hdir[1]);
    println!("U S V^T rows: {}; {}; largest drift from perpendicular unit axes, U then V: \
              {:.6}, {:.6}", f6(rebuilt[0]), f6(rebuilt[1]),
             drift(mm(tp(u), u), eye), drift(mm(tp(v), v), eye));
    println!("product of singular values {:.6}; absolute determinant {:.6}",
             sig[0] * sig[1], det(a).abs());
    println!("eigenvalues added {:.6}; squares of A's entries added {:.6}",
             lam[0] + lam[1], squares);
    println!("nonzero singular values, the rank: {}", rank);
    println!("A's own eigenvalues, not the stretches: {}; A's column lengths: {}",
             f6(eig2(a)), f6(cols));
    println!("eigenvalues left unrooted, product {:.6}, not the area factor {:.6}",
             lam[0] * lam[1], sig[0] * sig[1]);
    println!("flat matrix B rows: {}; {}; det B {:.6}; singular values {}; rank {}",
             f6(b[0]), f6(b[1]), det(b), f6(sigb), rankb);
    println!("B kills its second input axis {}: image {}", f6(vsb[1]), f6(mv(b, vsb[1])));
    assert!((hi - sig[0]).abs() < 1e-6 && (lo - sig[1]).abs() < 1e-6);   // two roads, same stretches
    assert!((sig[0] * sig[1] - det(a).abs()).abs() < 1e-12 && (lam[0] + lam[1] - squares).abs() < 1e-12);
    assert!(drift(rebuilt, a) < 1e-12 && drift(mm(tp(u), u), eye) < 1e-12 && drift(mm(tp(v), v), eye) < 1e-12);
    assert!((sigb[0] - 5.0).abs() < 1e-12 && dot(mv(b, vsb[1]), mv(b, vsb[1])) < 1e-24 && (rank, rankb) == (2, 1));
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-14 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
sprite A rows: (3.000000, 0.000000); (4.000000, 5.000000); det A 15.000000
G = A^T A rows: (25.000000, 20.000000); (20.000000, 25.000000)
eigenvalues of G: (45.000000, 5.000000); singular values, their square roots: (6.708204, 2.236068)
input axes v1, v2: (0.707107, 0.707107); (0.707107, -0.707107)
images A v1, A v2: (2.121320, 6.363961); (2.121320, -0.707107)
output axes u1, u2: (0.316228, 0.948683); (0.948683, -0.316228)
road two, longest and shortest stretch over 100002 directions: (6.708204, 2.236068), longest along (0.7071, 0.7071)
U S V^T rows: (3.000000, 0.000000); (4.000000, 5.000000); largest drift from perpendicular unit axes, U then V: 0.000000, 0.000000
product of singular values 15.000000; absolute determinant 15.000000
eigenvalues added 50.000000; squares of A's entries added 50.000000
nonzero singular values, the rank: 2
A's own eigenvalues, not the stretches: (5.000000, 3.000000); A's column lengths: (5.000000, 5.000000)
eigenvalues left unrooted, product 225.000000, not the area factor 15.000000
flat matrix B rows: (1.000000, 2.000000); (2.000000, 4.000000); det B 0.000000; singular values (5.000000, 0.000000); rank 1
B kills its second input axis (0.894427, -0.447214): image (0.000000, 0.000000)
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves the theorem for every matrix with real entries, any number of rows and columns, and checks the sprite's numbers exactly.

- Every such matrix $A$ equals $U S V^T$, with $U$ and $V$ orthogonal and the singular values down the diagonal of $S$.
- The factors are unique: write $A$ as $U S V^T$ with factors never negative, largest first, and they are the singular values.
- The singular values are never negative and come largest first, and their squares are the eigenvalues of $G$, repeats counted.
- For the sprite, $G$ is `[[25, 20], [20, 25]]` with eigenvalues 45 and 5, and the rebuild returns `[[3, 0], [4, 5]]` exactly.
- The square roots of 45 and 5 multiply to 15, which is det A.
- The flat matrix `[[1, 2], [2, 4]]` has determinant 0 and flattens (2, −1) to the zero vector.

The decimals and the measuring road through 100002 directions are left to the Python and Rust checks.

```lean
-- The singular value decomposition: every real matrix of any shape equals an orthogonal matrix times a stretch along perpendicular axes times a second orthogonal matrix, the stretch factors are always its singular values (the square roots of the eigenvalues of A transpose A, largest first, never negative), and the card's sprite numbers are checked exactly.
import Mathlib.Analysis.InnerProductSpace.SingularValues
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.LinearAlgebra.UnitaryGroup
import Mathlib.LinearAlgebra.Matrix.Charpoly.Basic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases

open Matrix

/-- The stretch matrix `S`: an `m` by `n` grid of zeros with the numbers `d 0, d 1, ...` down its
main diagonal (entry `(i, i)` is `d i`). It stretches input axis `i` by `d i` and lays it on output
axis `i`. -/
def stretchMatrix (m n : ℕ) (d : ℕ → ℝ) : Matrix (Fin m) (Fin n) ℝ :=
  Matrix.of fun i j => if (i : ℕ) = (j : ℕ) then d i else 0

noncomputable def svdColMat {k : ℕ} (b : OrthonormalBasis (Fin k) ℝ (EuclideanSpace ℝ (Fin k))) :
    Matrix (Fin k) (Fin k) ℝ :=
  Matrix.of fun i j => b j i

lemma svdColMat_mem {k : ℕ} (b : OrthonormalBasis (Fin k) ℝ (EuclideanSpace ℝ (Fin k))) :
    svdColMat b ∈ Matrix.orthogonalGroup (Fin k) ℝ := by
  have := (EuclideanSpace.basisFun (Fin k) ℝ).toMatrix_orthonormalBasis_mem_unitary b
  convert this using 1
  ext i j
  simp [svdColMat, Module.Basis.toMatrix_apply]
#print axioms svdColMat_mem

lemma svd_adj_comp_apply {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) (x : EuclideanSpace ℝ (Fin n)) :
    (LinearMap.adjoint (Matrix.toEuclideanLin A) ∘ₗ Matrix.toEuclideanLin A) x =
      WithLp.toLp 2 ((Aᵀ * A) *ᵥ WithLp.ofLp x) := by
  rw [← Matrix.toEuclideanLin_conjTranspose_eq_adjoint]
  simp [Matrix.toLpLin_apply, Matrix.mulVec_mulVec]
#print axioms svd_adj_comp_apply

lemma svd_gram_mul {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) :
    (Aᵀ * A) * svdColMat ((Matrix.toEuclideanLin A).isSymmetric_adjoint_comp_self.eigenvectorBasis
        finrank_euclideanSpace_fin) =
      svdColMat ((Matrix.toEuclideanLin A).isSymmetric_adjoint_comp_self.eigenvectorBasis
        finrank_euclideanSpace_fin) * Matrix.diagonal
        ((Matrix.toEuclideanLin A).isSymmetric_adjoint_comp_self.eigenvalues
        finrank_euclideanSpace_fin) := by
  set hT := (Matrix.toEuclideanLin A).isSymmetric_adjoint_comp_self
  ext i j
  have h := hT.apply_eigenvectorBasis finrank_euclideanSpace_fin j
  rw [svd_adj_comp_apply] at h
  have h2 := congrArg (fun x : EuclideanSpace ℝ (Fin n) => WithLp.ofLp x i) h
  simp [Matrix.mulVec, dotProduct] at h2
  rw [Matrix.mul_diagonal, Matrix.mul_apply]
  simp only [svdColMat, Matrix.of_apply]
  rw [h2]; ring
#print axioms svd_gram_mul

lemma svd_charpoly_gram {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) :
    (Aᵀ * A).charpoly =
      ∏ k : Fin n, (Polynomial.X - Polynomial.C ((Matrix.toEuclideanLin A).singularValues k ^ 2)) := by
  have hgm := svd_gram_mul A
  set hT := (Matrix.toEuclideanLin A).isSymmetric_adjoint_comp_self
  set V := svdColMat (hT.eigenvectorBasis finrank_euclideanSpace_fin) with hVdef
  have hV : V * Vᵀ = 1 := (Matrix.mem_orthogonalGroup_iff _ _).mp (svdColMat_mem _)
  have hVt : Vᵀ * V = 1 := (Matrix.mem_orthogonalGroup_iff' _ _).mp (svdColMat_mem _)
  have hG : Aᵀ * A = V * (Matrix.diagonal (hT.eigenvalues finrank_euclideanSpace_fin) * Vᵀ) := by
    calc Aᵀ * A = Aᵀ * A * (V * Vᵀ) := by rw [hV, Matrix.mul_one]
      _ = (Aᵀ * A * V) * Vᵀ := by rw [Matrix.mul_assoc (Aᵀ * A)]
      _ = _ := by rw [hgm, Matrix.mul_assoc]
  rw [hG, Matrix.charpoly_mul_comm, Matrix.mul_assoc, hVt, Matrix.mul_one, Matrix.charpoly_diagonal]
  refine Finset.prod_congr rfl fun k _ => ?_
  rw [(Matrix.toEuclideanLin A).sq_singularValues_fin finrank_euclideanSpace_fin k]
#print axioms svd_charpoly_gram

lemma svd_roots_prod {n : ℕ} (f : Fin n → ℝ) :
    (∏ j, (Polynomial.X - Polynomial.C (f j))).roots = (List.ofFn f : Multiset ℝ) := by
  rw [Finset.prod_eq_multiset_prod, ← Fin.univ_val_map]
  have : Multiset.map (fun j => Polynomial.X - Polynomial.C (f j)) Finset.univ.val =
      Multiset.map (fun a => Polynomial.X - Polynomial.C a) (Multiset.map f Finset.univ.val) := by
    rw [Multiset.map_map]
    rfl
  rw [this, Polynomial.roots_multiset_prod_X_sub_C]
#print axioms svd_roots_prod

/-- The card's theorem. Every matrix `A` of real numbers, with any number `m` of rows and any
number `n` of columns, is three moves: `A = U S Vᵀ`. Here `V` and `U` are orthogonal matrices
(their columns are perpendicular axes of length 1: a turn, perhaps with a mirror flip), and `S` is
the stretch matrix whose diagonal holds the singular values of `A`, largest first and never
negative. Mathlib's singular values of `A` are the square roots of the eigenvalues of `Aᵀ A`. -/
theorem every_matrix_is_rotate_stretch_rotate {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ) :
    ∃ U ∈ Matrix.orthogonalGroup (Fin m) ℝ, ∃ V ∈ Matrix.orthogonalGroup (Fin n) ℝ,
      A = U * stretchMatrix m n (Matrix.toEuclideanLin A).singularValues * Vᵀ := by
  set T := Matrix.toEuclideanLin A with hTdef
  set hT := T.isSymmetric_adjoint_comp_self
  set b := hT.eigenvectorBasis (finrank_euclideanSpace_fin (𝕜 := ℝ) (n := n)) with hb
  set σ := T.singularValues with hσ
  have hinner : ∀ i j : Fin n,
      inner ℝ (T (b i)) (T (b j)) = if i = j then σ i ^ 2 else 0 := by
    intro i j
    rw [← LinearMap.adjoint_inner_right, ← LinearMap.comp_apply, hT.apply_eigenvectorBasis,
      inner_smul_right, orthonormal_iff_ite.mp b.orthonormal i j]
    split_ifs with h
    · subst h
      rw [hσ, T.sq_singularValues_fin finrank_euclideanSpace_fin i]
      simp
    · simp
  have hnorm0 : ∀ j : Fin n, σ j = 0 → T (b j) = 0 := by
    intro j hj
    have := hinner j j
    rw [if_pos rfl, hj, real_inner_self_eq_norm_sq] at this
    simpa using this
  have hσm : ∀ j : ℕ, σ j ≠ 0 → j < m := by
    intro j hj
    have h1 : j < Module.finrank ℝ (LinearMap.range T) := by
      by_contra h
      push Not at h
      exact hj ((T.singularValues_eq_zero_iff_le_finrank_range).mpr h)
    have h2 : Module.finrank ℝ (LinearMap.range T) ≤ m :=
      (Submodule.finrank_le _).trans finrank_euclideanSpace_fin.le
    omega
  have hσn : ∀ j : ℕ, σ j ≠ 0 → j < n := by
    intro j hj
    by_contra h
    push Not at h
    exact hj (T.singularValues_of_finrank_le (by rw [finrank_euclideanSpace_fin]; exact h))
  let v : Fin m → EuclideanSpace ℝ (Fin m) := fun i =>
    if h : (i : ℕ) < n then (σ i)⁻¹ • T (b ⟨i, h⟩) else 0
  let s : Set (Fin m) := {i | σ i ≠ 0}
  have hv : Orthonormal ℝ (s.domRestrict v) := by
    rw [orthonormal_iff_ite]
    rintro ⟨i, hi⟩ ⟨j, hj⟩
    have hin := hσn i hi
    have hjn := hσn j hj
    simp only [Set.domRestrict_apply, v, dif_pos hin, dif_pos hjn, inner_smul_left,
      inner_smul_right, hinner]
    by_cases hij : i = j
    · subst hij
      have hi' : σ i ≠ 0 := hi
      simp
      field_simp
    · have : (⟨(i : ℕ), hin⟩ : Fin n) ≠ ⟨j, hjn⟩ := by
        intro h
        apply hij
        ext
        simpa using congrArg Fin.val h
      simp [this, hij]
  obtain ⟨bU, hbU⟩ := hv.exists_orthonormalBasis_extension_of_card_eq (by simp)
  refine ⟨svdColMat bU, svdColMat_mem bU, svdColMat b, svdColMat_mem b, ?_⟩
  have hV : svdColMat b * (svdColMat b)ᵀ = 1 :=
    (Matrix.mem_orthogonalGroup_iff _ _).mp (svdColMat_mem _)
  have key : A * svdColMat b = svdColMat bU * stretchMatrix m n σ := by
    ext i j
    have lhs : (A * svdColMat b) i j = (T (b j)) i := by
      simp [hTdef, Matrix.mul_apply, svdColMat, Matrix.toLpLin_apply, Matrix.mulVec, dotProduct]
    rw [lhs, Matrix.mul_apply]
    simp only [svdColMat, stretchMatrix, Matrix.of_apply]
    by_cases hj0 : σ j = 0
    · rw [hnorm0 j hj0]
      refine (Finset.sum_eq_zero fun k _ => ?_).symm
      split_ifs with h
      · rw [h, hj0]; ring
      · ring
    · have hjm := hσm j hj0
      rw [Finset.sum_eq_single ⟨j, hjm⟩]
      · have h1 := hbU ⟨j, hjm⟩ hj0
        rw [h1]
        simp [v, j.isLt]
        field_simp
      · intro k _ hk
        rw [if_neg]
        · ring
        · intro h
          apply hk
          ext
          exact h
      · simp
  calc A = A * (svdColMat b * (svdColMat b)ᵀ) := by rw [hV, Matrix.mul_one]
    _ = _ := by rw [← Matrix.mul_assoc, key]

/-- The factors are unique, the axes are not. However `A` is written as `U S Vᵀ`, with `U` and `V`
orthogonal and `S` a stretch matrix whose diagonal numbers are never negative and come largest
first, those diagonal numbers are exactly the singular values of `A`. -/
theorem stretch_factors_are_the_singular_values {m n : ℕ} (A : Matrix (Fin m) (Fin n) ℝ)
    (U : Matrix (Fin m) (Fin m) ℝ) (hU : U ∈ Matrix.orthogonalGroup (Fin m) ℝ)
    (V : Matrix (Fin n) (Fin n) ℝ) (hV : V ∈ Matrix.orthogonalGroup (Fin n) ℝ)
    (d : ℕ → ℝ) (hnonneg : ∀ k, k < min m n → 0 ≤ d k)
    (hsorted : ∀ k l, k ≤ l → l < min m n → d l ≤ d k)
    (hA : A = U * stretchMatrix m n d * Vᵀ) :
    ∀ k, k < min m n → d k = (Matrix.toEuclideanLin A).singularValues k := by
  intro k hk
  have h3 := svd_charpoly_gram A
  set σ := (Matrix.toEuclideanLin A).singularValues with hσ
  have hUt : Uᵀ * U = 1 := (Matrix.mem_orthogonalGroup_iff' _ _).mp hU
  have hVt : Vᵀ * V = 1 := (Matrix.mem_orthogonalGroup_iff' _ _).mp hV
  set S := stretchMatrix m n d with hS
  let e : Fin n → ℝ := fun j => if (j : ℕ) < m then d j ^ 2 else 0
  have hSS : Sᵀ * S = Matrix.diagonal e := by
    ext i j
    rw [Matrix.mul_apply]
    simp only [S, stretchMatrix, Matrix.transpose_apply, Matrix.of_apply, Matrix.diagonal_apply, e]
    by_cases him : (i : ℕ) < m
    · rw [Finset.sum_eq_single ⟨i, him⟩]
      · by_cases hij : i = j
        · subst hij
          simp [him]
          ring
        · have : (i : ℕ) ≠ j := fun h => hij (Fin.ext h)
          simp [hij, this]
      · intro k _ hk
        have : (k : ℕ) ≠ i := fun h => hk (Fin.ext h)
        simp [this]
      · simp
    · rw [Finset.sum_eq_zero]
      · split_ifs <;> simp_all
      · intro k _
        have : (k : ℕ) ≠ i := by omega
        simp [this]
  have hG : (Aᵀ * A).charpoly = ∏ j : Fin n, (Polynomial.X - Polynomial.C (e j)) := by
    have : Aᵀ * A = V * (Sᵀ * S * Vᵀ) := by
      rw [hA]
      simp only [Matrix.transpose_mul, Matrix.transpose_transpose, Matrix.mul_assoc]
      rw [← Matrix.mul_assoc Uᵀ U, hUt, Matrix.one_mul]
    rw [this, Matrix.charpoly_mul_comm, Matrix.mul_assoc, hVt, Matrix.mul_one, hSS,
      Matrix.charpoly_diagonal]
  have hroots := congrArg Polynomial.roots (hG.symm.trans h3)
  rw [svd_roots_prod, svd_roots_prod, Multiset.coe_eq_coe] at hroots
  have he : Antitone e := by
    intro i j hij
    have hij' : (i : ℕ) ≤ j := hij
    simp only [e]
    by_cases hjm : (j : ℕ) < m
    · have him : (i : ℕ) < m := lt_of_le_of_lt hij' hjm
      rw [if_pos hjm, if_pos him]
      have hjmn : (j : ℕ) < min m n := lt_min hjm j.isLt
      have h0 := hnonneg j hjmn
      have h1 := hsorted i j hij' hjmn
      nlinarith
    · rw [if_neg hjm]
      split_ifs <;> positivity
  have hσa : Antitone fun j : Fin n => σ j ^ 2 := by
    intro i j hij
    have h1 := (Matrix.toEuclideanLin A).singularValues_antitone (show (i : ℕ) ≤ j from hij)
    have h0 := (Matrix.toEuclideanLin A).singularValues_nonneg j
    simp only
    nlinarith
  have heq := List.ofFn_injective (hroots.eq_of_sortedGE he.sortedGE_ofFn hσa.sortedGE_ofFn)
  have hkm : k < m := lt_of_lt_of_le hk (min_le_left _ _)
  have hkn : k < n := lt_of_lt_of_le hk (min_le_right _ _)
  have hsq := congrFun heq ⟨k, hkn⟩
  simp only [e, if_pos hkm] at hsq
  exact (pow_left_inj₀ (hnonneg k hk) ((Matrix.toEuclideanLin A).singularValues_nonneg k)
    two_ne_zero).mp hsq

/-- The formula `σᵢ = √λᵢ`. The singular values of `A` are never negative and come largest
first, and their squares are the eigenvalues `λ₁, ..., λₙ` of `G = Aᵀ A`, counted with
repeats: the characteristic polynomial of `Aᵀ A` is `(x - σ₁²) ⋯ (x - σₙ²)`. -/
theorem singular_values_are_square_roots_of_eigenvalues_of_transpose_mul_self {m n : ℕ}
    (A : Matrix (Fin m) (Fin n) ℝ) :
    Antitone (Matrix.toEuclideanLin A).singularValues ∧
      (∀ k, 0 ≤ (Matrix.toEuclideanLin A).singularValues k) ∧
      (Aᵀ * A).charpoly =
        ∏ k : Fin n, (Polynomial.X - Polynomial.C ((Matrix.toEuclideanLin A).singularValues k ^ 2)) := by
  exact ⟨(Matrix.toEuclideanLin A).singularValues_antitone,
    (Matrix.toEuclideanLin A).singularValues_nonneg, svd_charpoly_gram A⟩

-- The sprite A = [[3, 0], [4, 5]]: G = Aᵀ A is [[25, 20], [20, 25]].
example : (!![3, 0; 4, 5] : Matrix (Fin 2) (Fin 2) ℤ)ᵀ * !![3, 0; 4, 5] = !![25, 20; 20, 25] := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_two]
-- Its characteristic equation (25 - λ)(25 - λ) - 20 × 20 = 0 has roots 45 and 5.
example : (25 - 45 : ℤ) * (25 - 45) - 20 * 20 = 0 := by norm_num
example : (25 - 5 : ℤ) * (25 - 5) - 20 * 20 = 0 := by norm_num
-- The input axes, before scaling to length 1: G (1, 1) = 45 (1, 1) and G (1, -1) = 5 (1, -1).
example : (!![25, 20; 20, 25] : Matrix (Fin 2) (Fin 2) ℤ) *ᵥ ![1, 1] = (45 : ℤ) • ![1, 1] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
example : (!![25, 20; 20, 25] : Matrix (Fin 2) (Fin 2) ℤ) *ᵥ ![1, -1] = (5 : ℤ) • ![1, -1] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
-- Their images: A (1, 1) = (3, 9) and A (1, -1) = (3, -1), perpendicular (3 × 3 + 9 × (-1) = 0),
-- with squared lengths 90 = 45 × 2 and 10 = 5 × 2.
example : (!![3, 0; 4, 5] : Matrix (Fin 2) (Fin 2) ℤ) *ᵥ ![1, 1] = ![3, 9] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
example : (!![3, 0; 4, 5] : Matrix (Fin 2) (Fin 2) ℤ) *ᵥ ![1, -1] = ![3, -1] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
example : (3 : ℤ) * 3 + 9 * (-1) = 0 ∧ (3 : ℤ) ^ 2 + 9 ^ 2 = 45 * 2 ∧ (3 : ℤ) ^ 2 + (-1) ^ 2 = 5 * 2 := by
  norm_num
-- The singular values: √45 × √5 = 15, the area factor, and det A = 3 × 5 - 0 × 4 = 15.
example : Real.sqrt 45 * Real.sqrt 5 = 15 := by
  rw [← Real.sqrt_mul (by norm_num), show (45 : ℝ) * 5 = 15 ^ 2 by norm_num]
  exact Real.sqrt_sq (by norm_num)
example : Matrix.det (!![3, 0; 4, 5] : Matrix (Fin 2) (Fin 2) ℤ) = 15 := by
  norm_num [Matrix.det_fin_two_of]
-- The rebuild, exactly. U = (1/√10) [[1, 3], [3, -1]], S = √5 diag(3, 1), V = (1/√2) [[1, 1], [1, -1]];
-- the square roots combine to √5 / (√10 √2) = 1/2, and (1/2) [[1, 3], [3, -1]] diag(3, 1) [[1, 1], [1, -1]]ᵀ
-- is A.
example : (1 / 2 : ℚ) • (!![1, 3; 3, -1] * !![3, 0; 0, 1] * (!![1, 1; 1, -1] : Matrix (Fin 2) (Fin 2) ℚ)ᵀ)
    = !![3, 0; 4, 5] := by
  ext i j; fin_cases i <;> fin_cases j <;>
    norm_num [Matrix.mul_apply, Matrix.vecMul, dotProduct, Matrix.transpose_apply, Fin.sum_univ_two]
example : Real.sqrt 5 / (Real.sqrt 10 * Real.sqrt 2) = 1 / 2 := by
  rw [← Real.sqrt_mul (by norm_num), show (10 : ℝ) * 2 = 2 ^ 2 * 5 by norm_num,
    Real.sqrt_mul (by norm_num), Real.sqrt_sq (by norm_num)]
  have h : Real.sqrt 5 ≠ 0 := by positivity
  field_simp
-- The axes are perpendicular: the unscaled axis grids satisfy Pᵀ P = 10 I and Qᵀ Q = 2 I.
example : (!![1, 3; 3, -1] : Matrix (Fin 2) (Fin 2) ℤ)ᵀ * !![1, 3; 3, -1] = (10 : ℤ) • 1 := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_two]
example : (!![1, 1; 1, -1] : Matrix (Fin 2) (Fin 2) ℤ)ᵀ * !![1, 1; 1, -1] = (2 : ℤ) • 1 := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_two]
-- Eigenvalues added: 45 + 5 = 50 = 3² + 0² + 4² + 5².
example : (45 + 5 : ℤ) = 3 ^ 2 + 0 ^ 2 + 4 ^ 2 + 5 ^ 2 := by norm_num
-- The mistakes: A's own eigenvalues are 5 and 3 (det (A - 5 I) = det (A - 3 I) = 0), not the
-- stretches; and the unrooted eigenvalues multiply to 45 × 5 = 225 = 15², not 15.
example : Matrix.det (!![3 - 5, 0; 4, 5 - 5] : Matrix (Fin 2) (Fin 2) ℤ) = 0 ∧
    Matrix.det (!![3 - 3, 0; 4, 5 - 3] : Matrix (Fin 2) (Fin 2) ℤ) = 0 := by
  norm_num [Matrix.det_fin_two_of]
example : (45 * 5 : ℤ) = 225 ∧ (225 : ℤ) = 15 ^ 2 := by norm_num
-- The flat matrix B = [[1, 2], [2, 4]]: det B = 0, Bᵀ B = [[5, 10], [10, 20]] with eigenvalues 25 and 0
-- (singular values 5 and 0, rank 1), and B flattens the axis (2, -1) to zero.
example : Matrix.det (!![1, 2; 2, 4] : Matrix (Fin 2) (Fin 2) ℤ) = 0 := by
  norm_num [Matrix.det_fin_two_of]
example : (!![1, 2; 2, 4] : Matrix (Fin 2) (Fin 2) ℤ)ᵀ * !![1, 2; 2, 4] = !![5, 10; 10, 20] := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_two]
example : (!![5, 10; 10, 20] : Matrix (Fin 2) (Fin 2) ℤ) *ᵥ ![1, 2] = (25 : ℤ) • ![1, 2] := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
example : (!![1, 2; 2, 4] : Matrix (Fin 2) (Fin 2) ℤ) *ᵥ ![2, -1] = 0 := by
  ext i; fin_cases i <;> norm_num [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
example : Real.sqrt 25 = 5 := by
  rw [show (25 : ℝ) = 5 ^ 2 by norm_num]
  exact Real.sqrt_sq (by norm_num)

#print axioms every_matrix_is_rotate_stretch_rotate
#print axioms stretch_factors_are_the_singular_values
#print axioms singular_values_are_square_roots_of_eigenvalues_of_transpose_mul_self
```

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'svdColMat_mem' depends on axioms: [propext, Classical.choice, Quot.sound]
'svd_adj_comp_apply' depends on axioms: [propext, Classical.choice, Quot.sound]
'svd_gram_mul' depends on axioms: [propext, Classical.choice, Quot.sound]
'svd_charpoly_gram' depends on axioms: [propext, Classical.choice, Quot.sound]
'svd_roots_prod' depends on axioms: [propext, Classical.choice, Quot.sound]
'every_matrix_is_rotate_stretch_rotate' depends on axioms: [propext, Classical.choice, Quot.sound]
'stretch_factors_are_the_singular_values' depends on axioms: [propext, Classical.choice, Quot.sound]
'singular_values_are_square_roots_of_eigenvalues_of_transpose_mul_self' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it. The asserts stop the program on a wrong number; they are pinned to the sprite.
> - **Forget the square root.** Change `sig = [x ** 0.5 for x in lam]` to `sig = [x for x in lam]`. The factors print as 45.000000 and 5.000000 while the measuring road still reports 6.708204, so the first assert stops it.
> - **Flatten the sprite.** Set `A` to `[[1.0, 2.0], [2.0, 4.0]]`. Guess the rank: 1, factors 5.000000 and 0.000000. The first assert stops it: no sampled direction hits the flattened axis.
> - **Reverse a matched pair.** In `svd`, change `vs = [unit([g[0][1], L - g[0][0]]) for L in lam]` to `vs = [unit([-g[0][1], g[0][0] - L]) for L in lam]`: both input axes reverse and both output axes follow. Nothing breaks.

---

## The usual mistake

> [!warning]
> **Reading a matrix's eigenvalues as how much it stretches.** The sprite has eigenvalues 5.000000 and 3.000000 and stretches the rim to 6.708204. Eigenvalues answer which directions survive pointing the same way, and for a matrix that is not symmetric they are not even perpendicular.
>
> - **Expecting a negative factor.** It is a length; every flip lives in $U$ or $V$, never in $S$.
> - **Treating a zero factor as failure.** That direction is flattened; the non-zero count is the rank.
> - **Expecting input and output axes to match.** Here (0.707107, 0.707107) goes in and (0.316228, 0.948683) comes out.
> - **Calling the smallest factor noise.** It may be the signal.

---

## Where you meet it in real life

- **Image compression.** A photograph is a grid of brightness numbers with a few large factors and a long tail of small ones: keep the large, store a fraction.
- **Fits on data that nearly repeats itself.** When two measured columns say nearly the same thing, one factor drops near zero and the coefficients swing wildly; largest factor over smallest, the condition number, is the warning sign.

<details>
<summary>Keeping only the biggest stretches</summary>

Step 3 writes the matrix as one piece per factor: $\sigma_1$ times the grid made by multiplying $u_1$ against $v_1$, then the same on the second pair. Drop the smallest and what is left is the closest matrix of that lower rank, by the squares of the entry gaps — Eckart and Young, 1936.

</details>

> **Say it back**
> Every real matrix works in three moves: onto perpendicular input axes, a stretch by fixed non-negative factors, onto perpendicular output axes. The factors are the singular values, square roots of the eigenvalues of A transpose times A, symmetric, so the spectral theorem supplies the axes. For `[[3, 0], [4, 5]]` they are 6.708204 and 2.236068: the ellipse's half-axes, product 15.000000, the area factor and the determinant alike.

---

## What this builds on

- [The spectral theorem](04-spectral-theorem.md): perpendicular unit eigenvectors for a symmetric matrix, which hands over the input axes.
- [Rank and nullity](../05-Solving%20Systems/05-rank-nullity.md): rank as the directions that survive, nullity as those flattened.

## Where this goes next

- [Principal components](../../09-Probability%20and%20statistics/09-Regression/07-principal-components.md): these axes on centred data.
- [Principal components](../../14-Applied%20and%20computational/06-Machine%20Learning%20Mathematics/07-principal-components-and-dimension-reduction.md): how many axes a wide table needs.
- [Singular value decomposition](../../16-Numerical%20analysis/03-Numerical%20Linear%20Algebra/08-svd-and-the-pseudoinverse.md): the factors without building $A^T A$; best answers to unsolvable systems.
- [Can you steer every state, and can you see every state](../../13-Engineering%20mathematics/04-State%20Space%20and%20Optimal%20Control/03-controllability-and-observability.md): rank off the factors, deciding whether a system steers.
- [Writing down model error](../../13-Engineering%20mathematics/10-Robustness%20and%20Adaptation/01-model-uncertainty-and-the-small-gain-theorem.md): the largest factor as worst-case gain.
- [Compressed sensing](../../13-Engineering%20mathematics/05-Signals/10-compressed-sensing-in-outline.md): recovery when a matrix flattens most of its input.

One question stays open, and every application above turns on it: the fold "Keeping only the biggest stretches" measures what a dropped factor costs the matrix, never what it costs the answer.

---

## Sources

Verified 14 Sep 2026: every link below resolves to the publisher's page.

- Axler, Sheldon. *Linear Algebra Done Right*, 4th ed. Springer, 2024. [Author's open-access book page](https://linear.axler.net/). The decomposition built from the spectral theorem, in this order.
- Strang, Gilbert. *Introduction to Linear Algebra*, 6th ed. Wellesley-Cambridge Press, 2023. [Author's edition page at MIT](https://math.mit.edu/~gs/linearalgebra/ila6/indexila6.html). Two sets of axes as a map's geometry.
- Eckart, Carl, and Gale Young. "The Approximation of One Matrix by Another of Lower Rank." *Psychometrika* 1, no. 3 (1936): 211–218. [doi:10.1007/BF02288367](https://doi.org/10.1007/BF02288367). The proof behind the fold "Keeping only the biggest stretches".
