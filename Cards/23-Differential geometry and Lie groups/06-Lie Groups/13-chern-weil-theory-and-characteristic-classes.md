# Chern-Weil: whole numbers from curvature that no connection can change

[Syllabus](../../../SYLLABUS.md) → [Differential geometry and Lie groups](../README.md) → [Lie Groups](../README.md#s06) → Chern-Weil

---

## General Overview

A survey drone's camera, carried level round a 6036 km box over the North Atlantic, comes home turned 2.9994° ([Principal bundle and connection](10-principal-bundles-and-connections-in-outline.md)). That turn is curvature: the box encloses 2124864 km² of a globe whose curvature is 1/R². Over the whole globe the same curvature adds up to 720°, two whole turns.

Two turns is not an accident of the Earth's size or of the rule used to carry the camera. Squash the globe, or carry the camera by a different rule, and the curvature moves around, but its total stays two turns. This card explains why.

The machine is **Chern-Weil theory**. Put the curvature into a polynomial that ignores the choice of reference frames. The result is a closed form (a form with zero exterior derivative). Change the connection and the form changes only by an exact form (the exterior derivative of something). So its integral over a closed manifold does not change. These integrals are **characteristic numbers**: Chern numbers for complex bundles, Pontryagin numbers for real ones, and the Euler number for oriented ones.

The card works three examples on the globe and the circle:

- The **monopole line bundle** over the globe, the bundle a spin-half particle's quantum phase lives in. Its curvature integrates to exactly one turn: first Chern number 1.
- The camera's own bundle of level frames, the tangent bundle. Its Euler number is 2, the Gauss-Bonnet total.
- The **Möbius line bundle** over a circle. It is twisted, yet every curvature form it has is zero. Some twists need more than curvature to detect.

**A polynomial in the curvature that ignores the choice of frames gives a closed form whose cohomology class is the same for every connection, so its integral over a closed manifold is a property of the bundle alone: one turn for the monopole bundle, two for the globe's tangent bundle.**

**What kind of fact this is:** a theorem, the Chern-Weil theorem, proved on this card in Why it works: the forms are closed and their classes do not depend on the connection. That a line bundle's first Chern number over the globe is a whole number is also proved here. The four-dimensional Gauss-Bonnet-Chern formula and the Thom isomorphism are stated with sources, not proved, and the formula is checked on the 4-sphere. All results are global: they need a closed manifold.

### The picture: from a connection to a whole number

```mermaid
flowchart LR
    C["connection<br/>a rule for carrying frames<br/>(many choices)"] --> F["curvature F<br/>turn per unit area<br/>(changes with the connection)"]
    F --> P["invariant polynomial P(F)<br/>det, trace, Pfaffian<br/>(ignores the gauge)"]
    P --> H["class of P(F) in de Rham cohomology<br/>(same for every connection)"]
    H --> N["integral over a closed manifold<br/>a whole number: 1, 2, ..."]
```

Schematic. Each arrow forgets more choices; by the last box only the bundle is left.

---

## The formula

Notation first, in words. A **vector bundle** $`E`$ of **rank** $`r`$ over a manifold $`M`$ attaches an $`r`$-dimensional vector space, the **fibre**, to each point. It is glued from trivial pieces: over each patch it is (patch) × $`\mathbb{C}^r`$ or $`\mathbb{R}^r`$. On an overlap of patches, the **transition function** $`g`$ says how one patch's coordinates read in the other's. A **connection** $`\nabla`$ carries fibres along paths; in a gauge (a choice of frame on a patch) it is a matrix of one-forms $`A`$, and its **curvature** is $`F = dA + A \wedge A`$, as on [Principal bundle and connection](10-principal-bundles-and-connections-in-outline.md).

The **total Chern class** of a complex bundle is one determinant:

```math
c(E) = \det\!\Big(I + \frac{i}{2\pi}F\Big) = 1 + c_1(E) + c_2(E) + \cdots, \qquad c_1 = \frac{i}{2\pi}\mathrm{tr}\,F, \quad c_2 = \frac{1}{8\pi^2}\big(\mathrm{tr}(F\wedge F) - \mathrm{tr}F\wedge\mathrm{tr}F\big)
```

**Read it aloud:** expand the determinant of the identity plus i times the curvature over two pi; the part of degree two is the first Chern form, the part of degree four the second.

Here $`c_k`$ is a closed $`2k`$-form, and the card's claim is about its class in $`H^{2k}_{dR}(M)`$, the de Rham cohomology group ([de Rham cohomology](../04-Differential%20Forms/08-de-rham-cohomology.md)). For a circle group, [Principal bundle and connection](10-principal-bundles-and-connections-in-outline.md) writes $`F`$ as a real turn per area. The complex form is $`-i`$ times it, so $`c_1 = F/2\pi`$ with $`F`$ real: one turn of curvature per unit of $`c_1`$.

For a real bundle with a metric, the curvature $`\Omega`$ is an antisymmetric matrix of two-forms. Two more polynomials apply:

```math
p(E) = \det\!\Big(I + \frac{\Omega}{2\pi}\Big) = 1 + p_1 + p_2 + \cdots, \quad p_1 = -\frac{1}{8\pi^2}\mathrm{tr}(\Omega\wedge\Omega), \qquad e(E) = \mathrm{Pf}\Big(\frac{\Omega}{2\pi}\Big)
```

**Read it aloud:** the Pontryagin classes come from the same determinant without the i; the Euler class of an oriented bundle of even rank is the Pfaffian of the curvature over two pi.

The **Pfaffian** $`\mathrm{Pf}`$ is a square root of the determinant of an antisymmetric matrix. For rank 2 it is the one entry $`\Omega_{12}`$, so $`e = K\,dA/2\pi`$, the Gauss-Bonnet integrand. For rank 4 it is $`\Omega_{12}\wedge\Omega_{34} - \Omega_{13}\wedge\Omega_{24} + \Omega_{14}\wedge\Omega_{23}`$.

The theorem itself: for two connections with curvatures $`F_0`$ and $`F_1`$, and any invariant polynomial $`P`$,

```math
P(F_1) - P(F_0) = dT
```

**Read it aloud:** the two forms differ by the exterior derivative of a transgression form T, built from the two connections, so they have the same integral over any closed manifold.

The monopole bundle on the globe, with $`\varphi`$ the angle down from the North Pole and $`\theta`$ the longitude east, has curvature

```math
\frac{F}{2\pi} = \frac{1}{4\pi}\sin\varphi\, d\varphi\wedge d\theta, \qquad \int_{S^2}\frac{F}{2\pi} = \frac{1}{4\pi}\times 2 \times 2\pi = 1
```

**Read it aloud:** one quarter-pi-th of the area element; the phi integral of sine gives 2, the theta integral gives two pi, and the product is one.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $`E`$, $`M`$, $`r`$ | a vector bundle; its base manifold; its rank, the fibre's dimension | monopole bundle over the globe, $`r = 1`$ | — |
| $`g`$, $`n`$ | transition function on the overlap of two patches; its winding number round the equator | $`g = e^{i\theta}`$, $`n = 1`$; tangent bundle $`n = 2`$ | $`c_1`$ rises one for one |
| $`\nabla`$, $`A`$, $`A_N`$, $`A_S`$ | connection; its one-form in a gauge; in the north and south gauges | $`A_N = \tfrac12(1-\cos\varphi)\,d\theta`$ | — |
| $`F`$, $`\Omega`$, $`D`$ | curvature of a complex bundle; of a real bundle, an antisymmetric matrix of two-forms; the covariant exterior derivative | $`F = \tfrac12\sin\varphi\,d\varphi\wedge d\theta`$ | more turn per area |
| $`P`$, $`\tilde P`$, $`k`$, $`H^{2k}_{dR}`$, $`X`$, $`t`$, $`I`$ | invariant polynomial of degree $`k`$ and its multilinear form; de Rham cohomology in degree $`2k`$; a matrix, a number and the identity inside $`\det(I + tX)`$ | $`\det`$, $`\mathrm{tr}`$, $`\mathrm{Pf}`$ | — |
| $`c(E)`$, $`c_1`$, $`c_2`$ | total Chern class; first and second Chern forms | $`\int c_1 = 1`$ | — |
| $`p_1`$, $`e`$, $`\mathrm{Pf}`$ | first Pontryagin form of a real bundle; Euler form of an oriented even-rank bundle; Pfaffian | $`p_1 = 0`$ and $`\int e = 2`$ on the 4-sphere | $`e`$ flips sign with orientation |
| $`\psi`$, $`\langle u\vert v\rangle`$ | a quantum state at a grid point; the complex inner product of two states | spin-half state $`(\cos\frac{\varphi}{2},\ e^{i\theta}\sin\frac{\varphi}{2})`$ | — |
| $`w_1`$ | first Stiefel-Whitney class, mod 2 | Möbius 1, plain band 0 | — |
| $`\eta`$, $`b`$, $`\nabla_t`$, $`F_t`$, $`T`$ | difference of two connections; the example's global one-form; the straight path between connections and its curvature; the transgression form | $`b`$ moves $`F`$ at 55°N 15°W from 0.286788 to 0.554616 | $`F`$ moves, the integral does not |
| $`\varphi`$, $`\theta`$, $`x, y, z`$, $`K`$, $`R`$ | angle down from the North Pole; longitude east; the globe's coordinates in space; Gaussian curvature $`1/R^2`$; the globe's radius | box 30° to 40°, 30°W to 0°; $`R`$ = 6371 km | — |
| $`\chi`$, $`\mathrm{Rm}`$, $`\mathrm{Ric}`$, $`S`$, $`e^a`$, $`dV_g`$ | Euler characteristic; curvature tensor, Ricci and scalar curvature of a metric; an orthonormal coframe; the volume form | unit 4-sphere: $`\lvert\mathrm{Rm}\rvert^2 = 24`$, $`\lvert\mathrm{Ric}\rvert^2 = 36`$, $`S = 12`$ | — |

Clash said once: $`dA`$ is area in $`K\,dA`$; $`e`$ is the Euler class here, not the number 2.718…; $`T`$ is the transgression form, not a tangent vector or kinetic energy; $`S`$ is scalar curvature, while $`S^2`$ and $`S^4`$ are spheres.

### When it holds

- **The polynomial must ignore the gauge.** A gauge change turns $`F`$ into $`g^{-1}Fg`$. The trace and the determinant survive it; a single entry does not. In the check, the top-left entry of a curvature moves from 0.300000i to −0.148000i under one gauge change, while $`c_1`$ and $`c_2`$ stay at 0.063662 and −0.006586.
- **The manifold must be closed for a number.** On a patch with an edge, Stokes' theorem leaves a boundary term, and the integral depends on the connection there.
- **The Euler form needs an orientation.** A reflection flips the Pfaffian: 8 becomes −8 in the check. A bundle with no orientation has no Euler class in this sense.
- **Real numbers cannot see signs.** Chern-Weil forms live in real cohomology. A twist that only flips a sign, like the Möbius band's, is invisible to them: curvature 0, twist $`w_1 = 1`$.

---

## Why it works

### Step 0: curvature moves, its class does not

Any two connections on one bundle differ by a one-form $`\eta`$ defined on the whole manifold, with no gauge failure anywhere. So the curvatures differ, but an invariant polynomial of them changes only by $`d`$ of a global form (Step 5 builds it). The exterior derivative of a global form integrates to zero over a closed manifold, by [Stokes on manifolds](../04-Differential%20Forms/06-stokes-theorem-on-manifolds.md). The integral therefore cannot move. What is left belongs to the bundle: how its patches are glued.

### Step 1: a bundle is patches plus gluing

Cover the globe by two patches: everything but the South Pole, and everything but the North Pole. Over each patch the monopole bundle is (patch) × $`\mathbb{C}`$. On the overlap, a band round the equator, a vector reads $`v`$ in the north frame and $`e^{i\theta}v`$ in the south frame. That transition function $`g = e^{i\theta}`$ winds once round the unit circle as the equator is walked once. Its winding number, $`n = 1`$, fixes the whole bundle.

With more patches, the transition functions must agree on triple overlaps: 1 to 2 to 3 equals 1 to 3.

The tangent bundle, the camera's level frames, glues the same way. Take the frame given by the stereographic chart from the South Pole (smooth everywhere but the South Pole) and the frame from the North Pole's chart. Walk the equator: one frame turns against the other twice. So the tangent bundle has $`n = 2`$. No frame covers the whole globe, which is the [Hairy ball theorem](09-vector-field-zeros-and-the-hairy-ball.md).

### Step 2: the curvature integral counts the winding

Give the monopole bundle a connection in each gauge:

```math
A_N = \tfrac12(1 - \cos\varphi)\,d\theta, \qquad A_S = -\tfrac12(1 + \cos\varphi)\,d\theta, \qquad A_N - A_S = d\theta
```

Each is smooth on its own patch: near the North Pole $`1 - \cos\varphi`$ dies like $`\varphi^2/2`$, which tames $`d\theta`$. The two differ by $`g^{-1}dg = i\,d\theta`$, written as a real turn rate $`d\theta`$: the gauge-change rule from [Principal bundle and connection](10-principal-bundles-and-connections-in-outline.md). Both give the same curvature, $`F = \tfrac12\sin\varphi\,d\varphi\wedge d\theta`$.

Split the globe at any latitude. Stokes on the northern cap in the north gauge, and on the rest in the south gauge, gives

```math
\int_{S^2} F = \oint (A_N - A_S) = \oint d\theta = 2\pi n
```

So $`\int c_1 = n`$, a whole number. At 50°N, the north gauge's loop holds 0.116978 of a turn and the south gauge's holds 0.883022: together 1.000000. The split point is arbitrary; the sum is not.

The camera's level frames carry the connection of [Principal bundle and connection](10-principal-bundles-and-connections-in-outline.md), with $`F = K\,dA`$ and total 720°. Counted in turns, that is $`\int c_1 = 2`$, matching $`n = 2`$. The tangent bundle is the monopole bundle tensored with itself, and the check finds 2 three ways.

### Step 3: invariant polynomials ignore the gauge

A gauge change sends $`F`$ to $`g^{-1}Fg`$ ([Principal bundle and connection](10-principal-bundles-and-connections-in-outline.md), Step 5). A polynomial $`P`$ with $`P(g^{-1}Xg) = P(X)`$ for every $`g`$ in the group therefore gives the same form in every gauge. Such a $`P`$ is called **invariant**.

- $`\det(I + tX)`$ is invariant for every number $`t`$: $`\det(g^{-1}(I+tX)g) = \det(I+tX)`$. Each coefficient of $`t^k`$ is then invariant too; these give the Chern and Pontryagin forms.
- $`\mathrm{Pf}(g^{T}Xg) = \det(g)\,\mathrm{Pf}(X)`$. So the Pfaffian is invariant under rotations, $`\det g = +1`$, and flips under reflections. That is why the Euler class needs an oriented bundle ([Orientability](../../17-Topology/03-Surfaces%20and%20Manifolds/03-orientability-mobius-strip-and-klein-bottle.md)).

For a commuting group such as the circle, $`g^{-1}Fg = F`$, so every polynomial is invariant and $`F`$ itself is already a gauge-free form.

### Step 4: the forms are closed

The curvature obeys the **Bianchi identity** $`DF = dF + A\wedge F - F\wedge A = 0`$, where $`D`$ is the covariant exterior derivative: $`d`$ corrected by the connection. Invariance of $`P`$ turns $`d`$ of $`P(F)`$ into a sum of terms each holding one $`DF`$. Each is zero. So $`dP(F) = 0`$: the form is closed and has a class in $`H^{2k}_{dR}(M)`$.

<details>
<summary>Detailed proof: the Bianchi identity and closedness</summary>

Take $`d`$ of $`F = dA + A\wedge A`$. Since $`dd = 0`$,

$`\displaystyle dF = dA\wedge A - A\wedge dA.`$

Substitute $`dA = F - A\wedge A`$. The triple products $`A\wedge A\wedge A`$ cancel, leaving $`dF = F\wedge A - A\wedge F`$, which is $`DF = 0`$.

Write $`P(X) = \tilde P(X, \dots, X)`$ with $`\tilde P`$ symmetric and multilinear (linear in each slot). Differentiating $`\tilde P(g^{-1}X_1g, \dots) = \tilde P(X_1, \dots)`$ along $`g = e^{sY}`$ at $`s = 0`$ gives $`\sum_j \tilde P(X_1, \dots, [X_j, Y], \dots) = 0`$. For forms this means $`d`$ of $`\tilde P(F, \dots, F)`$ may be computed with $`D`$ in place of $`d`$, slot by slot:

$`\displaystyle dP(F) = k\,\tilde P(DF, F, \dots, F) = 0.`$

</details>

### Step 5: the class does not depend on the connection

Join two connections by a straight path, $`\nabla_t = \nabla_0 + t\eta`$ for $`t`$ from 0 to 1. Here $`\eta = \nabla_1 - \nabla_0`$ is a matrix of one-forms defined on all of $`M`$, because the gauge-change term $`g^{-1}dg`$ is the same for both and cancels. Along the path the curvature changes at the rate $`dF_t/dt = D_t\eta`$. Feed that into $`P`$:

```math
P(F_1) - P(F_0) = d\Big(k\int_0^1 \tilde P(\eta, F_t, \dots, F_t)\,dt\Big) = dT
```

The transgression form $`T`$ is global, so over a closed $`M`$ its derivative integrates to zero. This is the Chern-Weil theorem.

<details>
<summary>Detailed proof: the derivative along the path is exact</summary>

With $`A_t = A_0 + t\eta`$ in one gauge, $`F_t = dA_t + A_t\wedge A_t`$, so

$`\displaystyle \frac{dF_t}{dt} = d\eta + A_t\wedge\eta + \eta\wedge A_t = D_t\eta.`$

By multilinearity and symmetry, $`\frac{d}{dt}P(F_t) = k\,\tilde P(D_t\eta, F_t, \dots, F_t)`$. The same invariance argument as in Step 4, with the Bianchi identity $`D_tF_t = 0`$, gives

$`\displaystyle k\,\tilde P(D_t\eta, F_t, \dots, F_t) = d\big(k\,\tilde P(\eta, F_t, \dots, F_t)\big).`$

Integrate from $`t = 0`$ to 1. Each $`\tilde P(\eta, F_t, \dots)`$ is gauge-invariant, so it is one global form.

</details>

For a circle group, $`\eta`$ is a real one-form and $`T`$ is $`\eta/2\pi`$. The check takes the global form $`b = \tfrac12\big(z(x\,dy - y\,dx) + x(y\,dz - z\,dy)\big)`$, written in the globe's own $`x, y, z`$, and adds it to the monopole connection. By hand, $`db = \tfrac12\sin\varphi\,(x^2 - 2y^2 + z^2)\,d\varphi\wedge d\theta`$, which averages to zero over the globe. At 55°N 15°W the curvature density, the coefficient of $`d\varphi\wedge d\theta`$, changes from 0.286788 to 0.554616, and the check matches its finite difference to this formula. The integral stays 1: 1.002064351 on a 20 × 40 grid and 1.000514551 on 40 × 80, closing in on 1 as the grid is refined.

### Step 6: the Euler class, and the 4-sphere

For an oriented rank-2 bundle, the Pfaffian is the single curvature entry, so $`e = K\,dA/2\pi`$ and $`\int e = \chi`$ is [Gauss-Bonnet](../02-Surfaces/10-gauss-bonnet-theorem.md). In 1944 Chern gave an intrinsic proof of the same for every even dimension: on a closed oriented Riemannian manifold of dimension $`2m`$, $`\int_M \mathrm{Pf}(\Omega/2\pi) = \chi(M)`$. In dimension 4 the Pfaffian, written in the curvature tensors, gives

```math
\chi(M) = \frac{1}{32\pi^2}\int_M \big(\lvert\mathrm{Rm}\rvert^2 - 4\lvert\mathrm{Ric}\rvert^2 + S^2\big)\,dV_g
```

Stated with its source ([Chern 1944](https://doi.org/10.2307/1969302)), not proved here. On the unit 4-sphere, every curvature two-form is $`\Omega_{ab} = e^a\wedge e^b`$, with $`e^1, \dots, e^4`$ an orthonormal coframe (unit one-forms at right angles). Then:

- the Pfaffian is $`3\,e^1\wedge e^2\wedge e^3\wedge e^4`$: three terms, each $`+1`$;
- the volume is $`8\pi^2/3 = 26.318945070`$, so $`\chi = 3 \times 26.318945070/(4\pi^2) = 2`$;
- the curvature-tensor form gives $`(24 - 4 \times 36 + 144) \times 26.318945070/(32\pi^2) = 2`$;
- counting cells of the boundary of a 5-simplex (the 4-dimensional analogue of a tetrahedron's surface) gives $`6 - 15 + 20 - 15 + 6 = 2`$;
- $`\mathrm{tr}(\Omega\wedge\Omega) = 0`$, so $`p_1 = 0`$ on the 4-sphere. On the complex projective plane (complex lines through 0 in $`\mathbb{C}^3`$) it integrates to 3 ([Milnor and Stasheff](https://doi.org/10.1515/9781400881826), section 15).

The code's numerical volume, 26.325699833 on a 40-point grid, makes both Pfaffian routes read 2.000513; the excess is the grid error, not geometry.

### Step 7: what curvature cannot see

A real line bundle with a metric has curvature in $`\mathfrak{o}(1)`$, the Lie algebra of the group $`\{+1, -1\}`$. That algebra is zero. So every Chern-Weil form of a real line bundle vanishes.

The Möbius band, as a line bundle over a circle, is still twisted. Cover the circle by two arcs. They overlap in two pieces, with transition signs $`+1`$ and $`-1`$. Carry a nonzero vector once round: it returns as $`-1`$ times itself. The **first Stiefel-Whitney class** $`w_1`$ records that sign as a class mod 2: 1 for the Möbius band, 0 for the plain band, and 0 for the Möbius band tensored with itself, since $`(-1)^2 = 1`$. It is the obstruction to orienting the bundle. Chern-Weil forms are real and of even degree, while $`w_1`$ has degree 1 and lives mod 2, so no curvature form can record it.

The general tool behind such classes is the **Thom isomorphism**, stated here in outline with its source ([Milnor and Stasheff](https://doi.org/10.1515/9781400881826), sections 8 to 10). For an oriented rank-$`r`$ bundle there is a **Thom class**: a cohomology class on the bundle, supported near the zero section, that integrates to 1 on each fibre. Multiplying by it shifts the cohomology of $`M`$ up by $`r`$ degrees without loss. The Euler class is the Thom class pulled back along the zero section. Geometrically, it counts the zeros of a general section with signs, the [Hairy ball theorem](09-vector-field-zeros-and-the-hairy-ball.md)'s 4 + 4 − 6 = 2 on the globe. The same construction with mod-2 coefficients, where no orientation is needed, defines the Stiefel-Whitney classes.

---

## Worked numbers, by hand

The monopole bundle over the globe, in two gauges split at 50°N ($`\varphi = 40^\circ`$).

| Step | Arithmetic | Value |
| --- | --- | --- |
| curvature over $`2\pi`$ | $`\tfrac{1}{4\pi}\sin\varphi\,d\varphi\wedge d\theta`$ | — |
| integral over $`\varphi`$ | $`\int_0^\pi \sin\varphi\,d\varphi`$ | 2 |
| integral over $`\theta`$ | $`\int_0^{2\pi} d\theta`$ | $`2\pi`$ |
| $`c_1`$ | $`\tfrac{1}{4\pi}\times 2\times 2\pi`$ | 1 |
| north cap, north gauge | $`\tfrac12(1 - \cos 40^\circ)`$ | 0.116978 |
| the rest, south gauge | $`\tfrac12(1 + \cos 40^\circ)`$ | 0.883022 |
| sum | $`0.116978 + 0.883022`$ | 1.000000 |
| survey box, camera (tangent bundle) | $`(\cos 30^\circ - \cos 40^\circ)\times 30^\circ`$ in radians | 2.9994° |
| survey box, spin-half phase (monopole bundle) | half of 2.9994° | 1.4997° |
| **first Chern number** | winding of $`g = e^{i\theta}`$ | **1** |

The monopole bundle holds exactly half the tangent bundle's curvature everywhere: 1.4997° against the camera's 2.9994° on the box, one turn against two on the globe.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| use the north gauge on the whole globe, so Stokes "gives" 0 | round 89.9°S the north gauge still carries 0.999999 turn | the gauge fails at the South Pole; the whole turn hides there |
| forget the $`1/2\pi`$ | 6.284801 on a 40 × 80 grid | the integral counts radians, not turns |
| count level-frame overlaps on a 1 × 2 grid | 0.000000; true value 2 | each square holds a full turn, which reads as no phase |
| use the top-left entry of $`F`$, not its trace | 0.300000i, then −0.148000i after a gauge change | a single entry is not invariant |
| ignore orientation in the Pfaffian | 8 becomes −8 under a reflection | the Euler class is defined only for oriented bundles |
| expect curvature to detect the Möbius twist | curvature 0; $`w_1 = 1`$ | real-valued forms cannot record a sign |

---

## Code, from first principles, and it actually runs

The programs import only square roots, trigonometry, complex arithmetic (a struct in Rust) and, in Python, a permutation generator. They find the monopole bundle's $`c_1 = 1`$ by two independent roads, integrating $`F/2\pi`$ on two grids and a lattice count from spin-half overlaps that uses no connection at all ([Fukui, Hatsugai and Suzuki 2005](https://doi.org/10.1143/JPSJ.74.1674)), and print the winding that defines the bundle. They find the tangent bundle's Euler number 2 by clutching between stereographic frames, by level-frame overlaps, and by $`K\,dA/2\pi`$. Then they change the connection, test invariant polynomials, compute $`\chi(S^4) = 2`$ three ways, and print the Möbius sign.

The lattice road needs one fact. Multiply the overlaps $`\langle\psi_1|\psi_2\rangle\langle\psi_2|\psi_3\rangle\langle\psi_3|\psi_4\rangle\langle\psi_4|\psi_1\rangle`$ round a grid square, where $`\langle u|v\rangle`$ is the complex inner product of two states. Its phase is the curvature in the square (for a small square) and does not depend on the phase chosen for any state. Over a closed surface every edge appears twice, once each way, so the phases add to a whole number of turns exactly.

### Python

```python
import cmath, math
from itertools import permutations

PI, TURN = math.pi, 2 * math.pi

def p(ph, th):  # point on the unit globe: ph down from the North Pole, th east
    return (math.sin(ph) * math.cos(th), math.sin(ph) * math.sin(th), math.cos(ph))

def chern_by_integral(density, n):  # midpoint rule for (1/2pi) times the integral of F
    s, dph, dth = 0.0, PI / n, TURN / (2 * n)
    for i in range(n):
        for j in range(2 * n):
            s += density((i + 0.5) * dph, (j + 0.5) * dth) * dph * dth
    return s / TURN

def chern_by_lattice(state, n):  # overlaps round each grid square: no connection, no gauge
    s, dph, dth = 0.0, PI / n, TURN / (2 * n)
    for i in range(n):
        for j in range(2 * n):
            c = [state(a * dph, b * dth) for a, b in ((i, j), (i + 1, j), (i + 1, j + 1), (i, j + 1))]
            loop = 1
            for k in range(4):
                loop *= sum(x.conjugate() * y for x, y in zip(c[k], c[(k + 1) % 4]))
            s += cmath.phase(loop)
    return s / TURN + 0.0

def winding(angle, m=720):  # whole turns made by an angle carried once round the equator
    tot, prev = 0.0, angle(0.0)
    for k in range(1, m + 1):
        cur = angle(TURN * k / m)
        tot += (cur - prev + PI) % TURN - PI
        prev = cur
    return tot / TURN

spin_half = lambda ph, th: (complex(math.cos(ph / 2)), cmath.exp(1j * th) * math.sin(ph / 2))

def level_frame(ph, th):  # (e_phi + i e_theta)/sqrt 2: a level frame as one complex vector
    ep = (math.cos(ph) * math.cos(th), math.cos(ph) * math.sin(th), -math.sin(ph))
    et = (-math.sin(th), math.cos(th), 0.0)
    return tuple(complex(a, b) / math.sqrt(2) for a, b in zip(ep, et))

def stereo_frame(w):  # d/d(Re w) of the inverse stereographic chart from the South Pole
    d = 1 + abs(w) ** 2
    return (2 / d - 4 * w.real ** 2 / d ** 2, -4 * w.real * w.imag / d ** 2, -4 * w.real / d ** 2)

def clutch_tangent(th):  # angle from the north-chart frame to the south-chart frame on the equator
    q = p(PI / 2, th)
    a, b = stereo_frame(complex(q[0], q[1])), stereo_frame(complex(q[0], -q[1]))
    b = (b[0], -b[1], -b[2])  # the south chart is the north chart after (x, y, z) -> (x, -y, -z)
    cr = (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])
    return math.atan2(sum(u * v for u, v in zip(cr, q)), sum(u * v for u, v in zip(a, b)))

def b_form(ph, th):  # global 1-form b = z(x dy - y dx) + x(y dz - z dy), times 1/2; parts (b_ph, b_th)
    x, y, z = p(ph, th)
    vs = ((math.cos(ph) * math.cos(th), math.cos(ph) * math.sin(th), -math.sin(ph)),
          (-math.sin(ph) * math.sin(th), math.sin(ph) * math.cos(th), 0.0))
    return [0.5 * (z * (x * v[1] - y * v[0]) + x * (y * v[2] - z * v[1])) for v in vs]

def deformed(ph, th, h=1e-5):  # F density of the monopole connection plus b: F + db
    db = (b_form(ph + h, th)[1] - b_form(ph - h, th)[1] - b_form(ph, th + h)[0] + b_form(ph, th - h)[0]) / (2 * h)
    return 0.5 * math.sin(ph) + db

sign = lambda s: -1 if sum(1 for i in range(len(s)) for j in range(i) if s[j] > s[i]) % 2 else 1

def top_form(R, pf):  # e1234 coefficient of Pf(Omega) (pf True) or of tr(Omega ^ Omega)
    tot = 0.0
    for a, b, c, d in permutations(range(4)):
        if pf:
            t = sum(sign(s) * R[s[0]][s[1]][a][b] * R[s[2]][s[3]][c][d] for s in permutations(range(4))) / 8
        else:
            t = sum(R[i][j][a][b] * R[j][i][c][d] for i in range(4) for j in range(4))
        tot += sign((a, b, c, d)) * t / 4
    return tot + 0.0

pf4 = lambda m: m[0][1] * m[2][3] - m[0][2] * m[1][3] + m[0][3] * m[1][2]

print("part 1: the monopole (Hopf) line bundle over the globe")
F = lambda ph, th: 0.5 * math.sin(ph)
c20, c40 = chern_by_integral(F, 20), chern_by_integral(F, 40)
print(f"c1 by integrating F/2pi: 20 x 40 grid {c20:.9f}; 40 x 80 grid {c40:.9f}")
print(f"error ratio, coarse over fine: {(c20 - 1) / (c40 - 1):.4f}")
cap, south = 0.5 * (1 - math.cos(math.radians(40))), 0.5 * (1 + math.cos(math.radians(40)))
print(f"north gauge round 50N: {cap:.6f} turn; south gauge: {south:.6f} turn; sum {cap + south:.6f}")
c_wind, c_lat = winding(lambda th: th), chern_by_lattice(spin_half, 6)
print(f"c1 from the clutching angle at the equator: {c_wind:.6f}; from spin-half overlaps, 6 x 12 grid: {c_lat:.12f}")
box = (math.cos(math.radians(30)) - math.cos(math.radians(40))) * PI / 6
print(f"survey box: area {box * 6371 ** 2:.0f} km2, rim {6371 * (PI / 9 + PI / 6 * (0.5 + math.sin(math.radians(40)))):.0f} km; camera turn {math.degrees(box):.4f} deg; spin-half phase {math.degrees(box / 2):.4f} deg")
print("part 2: the tangent bundle (the camera's level frames)")
e_wind, e_lat = winding(clutch_tangent), chern_by_lattice(level_frame, 6)
e_int = chern_by_integral(lambda ph, th: math.sin(ph), 40)
print(f"Euler number from the clutching between stereographic frames: {e_wind:.6f}; from level-frame overlaps, 6 x 12 grid: {e_lat:.12f}")
print(f"Euler number from K dA / 2pi, 40 x 80 grid: {e_int:.9f}")
print("part 3: a different connection on the monopole bundle")
mid = (math.radians(35), math.radians(-15))
print(f"F density at 55N 15W: old {F(*mid):.6f}, new {deformed(*mid):.6f}")
d20, d40 = chern_by_integral(deformed, 20), chern_by_integral(deformed, 40)
print(f"c1 of the new connection: 20 x 40 grid {d20:.9f}; 40 x 80 grid {d40:.9f}")
print("part 4: invariant polynomials")
X = [[0.3j, 0.2 + 0.1j], [-0.2 + 0.1j, -0.7j]]
g = [[0.6, 0.8j], [0.8j, 0.6]]  # unitary, so g^-1 is its conjugate transpose
gi = [[g[j][i].conjugate() for j in range(2)] for i in range(2)]
mul = lambda A, B: [[sum(A[i][k] * B[k][j] for k in range(2)) for j in range(2)] for i in range(2)]
Y = mul(gi, mul(X, g))
cs = []
for nm, M in (("F", X), ("g^-1 F g", Y)):
    cs.append(((1j * (M[0][0] + M[1][1]) / TURN).real, (-(M[0][0] * M[1][1] - M[0][1] * M[1][0]) / TURN ** 2).real))
    print(f"{nm}: c1 part {cs[-1][0]:.6f}, c2 part {cs[-1][1]:.6f}, top-left entry {M[0][0].imag:.6f}i")
W = [[0, 1, 2, 3], [-1, 0, 4, 5], [-2, -4, 0, 6], [-3, -5, -6, 0]]
Wr = [[(-1 if (i == 0) != (j == 0) else 1) * W[i][j] for j in range(4)] for i in range(4)]
print(f"Pfaffian {pf4(W)}, after a reflection {pf4(Wr)}; Pfaffian squared {pf4(W) ** 2}")
print("part 5: the round 4-sphere, radius 1")
dl = lambda a, b: 1.0 if a == b else 0.0
R = [[[[dl(a, c) * dl(b, d) - dl(a, d) * dl(b, c) for d in range(4)] for c in range(4)] for b in range(4)] for a in range(4)]
pf_c, tr_c = top_form(R, True), top_form(R, False)
vol = {n: TURN * math.prod(sum(math.sin((i + 0.5) * PI / n) ** k for i in range(n)) * PI / n for k in (1, 2, 3)) for n in (20, 40)}
rm2 = sum(R[a][b][c][d] ** 2 for a in range(4) for b in range(4) for c in range(4) for d in range(4))
ric = [[sum(R[c][a][c][b] for c in range(4)) for b in range(4)] for a in range(4)]
ric2, sc = sum(ric[a][b] ** 2 for a in range(4) for b in range(4)), sum(ric[a][a] for a in range(4))
chi_pf, chi_gbc = pf_c * vol[40] / TURN ** 2, (rm2 - 4 * ric2 + sc ** 2) * vol[40] / (32 * PI ** 2)
chi_cells = sum((-1) ** k * math.comb(6, k + 1) for k in range(5))
print(f"Pfaffian of curvature: {pf_c:.6f} e1234; trace of Omega^Omega: {tr_c:.6f} e1234")
print(f"volume: 20 grid {vol[20]:.9f}; 40 grid {vol[40]:.9f}; exact 8pi^2/3 {8 * PI ** 2 / 3:.9f}")
print(f"|Rm|^2 {rm2:.0f}, |Ric|^2 {ric2:.0f}, S^2 {sc ** 2:.0f}; p1 from the trace: {-tr_c * vol[40] / (8 * PI ** 2) + 0.0:.6f}")
print(f"chi: from the Pfaffian {chi_pf:.6f}; from 4D Gauss-Bonnet-Chern {chi_gbc:.6f}; from cells {chi_cells}")
print("part 6: real line bundles over the circle")
mob = (1, -1)  # transition signs on the two overlaps of two arcs covering the circle
for nm, t in (("band", (1, 1)), ("Mobius", mob), ("Mobius squared", tuple(a * a for a in mob))):
    hol = t[0] * t[1]
    print(f"{nm}: section returns {hol:+d}, w1 = {(1 - hol) // 2}, curvature 0, two-sided copies {2 if hol == 1 else 1}")
print("what breaks")
print(f"north gauge alone round 89.9S: {0.5 * (1 - math.cos(math.radians(179.9))):.6f} turn hidden at the pole")
print(f"F without the 1/2pi: {c40 * TURN:.6f}; level frames on a 1 x 2 grid: {chern_by_lattice(level_frame, 1):.6f}")
assert abs(c40 - 1) < 1e-3 and abs(c20 - 1) > abs(c40 - 1)
assert round(c_wind) == round(c_lat) == 1 and abs(c_lat - 1) < 1e-9
assert round(e_wind) == round(e_lat) == 2 and abs(e_int - 2) < 1e-3
assert abs(d40 - 1) < 1e-3 and abs(deformed(*mid) - F(*mid) * (1 + sum(w * u * u for w, u in zip((1, -2, 1), p(*mid))))) < 1e-6
assert abs(cs[0][0] - cs[1][0]) < 1e-12 and abs(cs[0][1] - cs[1][1]) < 1e-12 and abs(X[0][0] - Y[0][0]) > 0.1
assert pf4(W) ** 2 == sum(sign(s) * math.prod(W[i][s[i]] for i in range(4)) for s in permutations(range(4)))
assert abs(pf_c - 3) < 1e-12 and abs(chi_pf - 2) < 1e-3 and abs(chi_gbc - chi_cells) < 1e-3 and max(abs(ric2 - 36), abs(sc - 12)) < 1e-12
print("ALL CHECKS PASS")
```

**Ran 2026-11-24 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
part 1: the monopole (Hopf) line bundle over the globe
c1 by integrating F/2pi: 20 x 40 grid 1.001028824; 40 x 80 grid 1.000257067
error ratio, coarse over fine: 4.0022
north gauge round 50N: 0.116978 turn; south gauge: 0.883022 turn; sum 1.000000
c1 from the clutching angle at the equator: 1.000000; from spin-half overlaps, 6 x 12 grid: 1.000000000000
survey box: area 2124864 km2, rim 6036 km; camera turn 2.9994 deg; spin-half phase 1.4997 deg
part 2: the tangent bundle (the camera's level frames)
Euler number from the clutching between stereographic frames: 2.000000; from level-frame overlaps, 6 x 12 grid: 2.000000000000
Euler number from K dA / 2pi, 40 x 80 grid: 2.000514134
part 3: a different connection on the monopole bundle
F density at 55N 15W: old 0.286788, new 0.554616
c1 of the new connection: 20 x 40 grid 1.002064351; 40 x 80 grid 1.000514551
part 4: invariant polynomials
F: c1 part 0.063662, c2 part -0.006586, top-left entry 0.300000i
g^-1 F g: c1 part 0.063662, c2 part -0.006586, top-left entry -0.148000i
Pfaffian 8, after a reflection -8; Pfaffian squared 64
part 5: the round 4-sphere, radius 1
Pfaffian of curvature: 3.000000 e1234; trace of Omega^Omega: 0.000000 e1234
volume: 20 grid 26.345846054; 40 grid 26.325699833; exact 8pi^2/3 26.318945070
|Rm|^2 24, |Ric|^2 36, S^2 144; p1 from the trace: 0.000000
chi: from the Pfaffian 2.000513; from 4D Gauss-Bonnet-Chern 2.000513; from cells 2
part 6: real line bundles over the circle
band: section returns +1, w1 = 0, curvature 0, two-sided copies 2
Mobius: section returns -1, w1 = 1, curvature 0, two-sided copies 1
Mobius squared: section returns +1, w1 = 0, curvature 0, two-sided copies 2
what breaks
north gauge alone round 89.9S: 0.999999 turn hidden at the pole
F without the 1/2pi: 6.284801; level frames on a 1 x 2 grid: 0.000000
ALL CHECKS PASS
```

### Rust

```rust
use std::f64::consts::PI;
const TURN: f64 = 2.0 * PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl C {
    fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } }
    fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } }
    fn conj(self) -> C { C { re: self.re, im: -self.im } }
}
fn c(re: f64, im: f64) -> C { C { re, im } }
fn p(ph: f64, th: f64) -> [f64; 3] { [ph.sin() * th.cos(), ph.sin() * th.sin(), ph.cos()] } // point on the unit globe: ph down from the North Pole, th east
fn dot(a: [f64; 3], b: [f64; 3]) -> f64 { a[0] * b[0] + a[1] * b[1] + a[2] * b[2] }
fn chern_by_integral(density: &dyn Fn(f64, f64) -> f64, n: usize) -> f64 { // midpoint rule for (1/2pi) times the integral of F
    let (mut s, dph, dth) = (0.0, PI / n as f64, TURN / (2 * n) as f64);
    for i in 0..n { for j in 0..2 * n {
        s += density((i as f64 + 0.5) * dph, (j as f64 + 0.5) * dth) * dph * dth;
    } }
    s / TURN
}
fn chern_by_lattice(state: &dyn Fn(f64, f64) -> Vec<C>, n: usize) -> f64 { // overlaps round each grid square: no connection, no gauge
    let (mut s, dph, dth) = (0.0, PI / n as f64, TURN / (2 * n) as f64);
    for i in 0..n { for j in 0..2 * n {
        let cs: Vec<Vec<C>> = [(i, j), (i + 1, j), (i + 1, j + 1), (i, j + 1)].iter()
            .map(|&(a, b)| state(a as f64 * dph, b as f64 * dth)).collect();
        let mut lp = c(1.0, 0.0);
        for k in 0..4 {
            let mut ov = c(0.0, 0.0);
            for (x, y) in cs[k].iter().zip(cs[(k + 1) % 4].iter()) { ov = ov.add(x.conj().mul(*y)); }
            lp = lp.mul(ov);
        }
        s += lp.im.atan2(lp.re);
    } }
    s / TURN + 0.0
}
fn winding(angle: &dyn Fn(f64) -> f64, m: usize) -> f64 { // whole turns made by an angle carried once round the equator
    let (mut tot, mut prev) = (0.0, angle(0.0));
    for k in 1..=m {
        let cur = angle(TURN * k as f64 / m as f64);
        tot += (cur - prev + PI).rem_euclid(TURN) - PI;
        prev = cur;
    }
    tot / TURN
}
fn spin_half(ph: f64, th: f64) -> Vec<C> { vec![c((ph / 2.0).cos(), 0.0), c(th.cos() * (ph / 2.0).sin(), th.sin() * (ph / 2.0).sin())] }
fn level_frame(ph: f64, th: f64) -> Vec<C> { // (e_phi + i e_theta)/sqrt 2: a level frame as one complex vector
    let ep = [ph.cos() * th.cos(), ph.cos() * th.sin(), -ph.sin()];
    let et = [-th.sin(), th.cos(), 0.0];
    (0..3).map(|k| c(ep[k] / 2f64.sqrt(), et[k] / 2f64.sqrt())).collect()
}
fn stereo_frame(wr: f64, wi: f64) -> [f64; 3] { // d/d(Re w) of the inverse stereographic chart from the South Pole
    let d = 1.0 + wr.hypot(wi).powf(2.0);
    [2.0 / d - 4.0 * wr.powf(2.0) / d.powf(2.0), -4.0 * wr * wi / d.powf(2.0), -4.0 * wr / d.powf(2.0)]
}
fn clutch_tangent(th: f64) -> f64 { // angle from the north-chart frame to the south-chart frame on the equator
    let q = p(PI / 2.0, th);
    let (a, b0) = (stereo_frame(q[0], q[1]), stereo_frame(q[0], -q[1]));
    let b = [b0[0], -b0[1], -b0[2]]; // the south chart is the north chart after (x, y, z) -> (x, -y, -z)
    let cr = [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];
    dot(cr, q).atan2(dot(a, b))
}
fn b_form(ph: f64, th: f64) -> [f64; 2] { // global 1-form b = z(x dy - y dx) + x(y dz - z dy), times 1/2; parts (b_ph, b_th)
    let [x, y, z] = p(ph, th);
    let vs = [[ph.cos() * th.cos(), ph.cos() * th.sin(), -ph.sin()], [-ph.sin() * th.sin(), ph.sin() * th.cos(), 0.0]];
    vs.map(|v| 0.5 * (z * (x * v[1] - y * v[0]) + x * (y * v[2] - z * v[1])))
}
fn deformed(ph: f64, th: f64) -> f64 { // F density of the monopole connection plus b: F + db
    let (h, bf) = (1e-5, b_form);
    let db = (bf(ph + h, th)[1] - bf(ph - h, th)[1] - bf(ph, th + h)[0] + bf(ph, th - h)[0]) / (2.0 * h);
    0.5 * ph.sin() + db
}
fn perms() -> Vec<[usize; 4]> { // the 24 orderings of 0, 1, 2, 3, in dictionary order
    (0..256).map(|k| [k / 64, k / 16 % 4, k / 4 % 4, k % 4]).filter(|s| (0..4).all(|i| (0..i).all(|j| s[i] != s[j]))).collect()
}
fn sign(s: &[usize; 4]) -> f64 { if (0..4).map(|i| (0..i).filter(|&j| s[j] > s[i]).count()).sum::<usize>() % 2 == 1 { -1.0 } else { 1.0 } }
fn top_form(r: &Vec<Vec<Vec<Vec<f64>>>>, pf: bool) -> f64 { // e1234 coefficient of Pf(Omega) (pf true) or of tr(Omega ^ Omega)
    let mut tot = 0.0;
    for q in perms() { let [a, b, c, d] = q;
        let t = if pf {
            perms().iter().map(|s| sign(s) * r[s[0]][s[1]][a][b] * r[s[2]][s[3]][c][d]).sum::<f64>() / 8.0
        } else {
            (0..16).map(|k| r[k / 4][k % 4][a][b] * r[k % 4][k / 4][c][d]).sum::<f64>()
        };
        tot += sign(&q) * t / 4.0;
    }
    tot + 0.0
}
fn pf4(m: &[[i64; 4]; 4]) -> i64 { m[0][1] * m[2][3] - m[0][2] * m[1][3] + m[0][3] * m[1][2] }

fn main() {
    println!("part 1: the monopole (Hopf) line bundle over the globe");
    let f = |ph: f64, _th: f64| 0.5 * ph.sin();
    let (c20, c40) = (chern_by_integral(&f, 20), chern_by_integral(&f, 40));
    println!("c1 by integrating F/2pi: 20 x 40 grid {:.9}; 40 x 80 grid {:.9}", c20, c40);
    println!("error ratio, coarse over fine: {:.4}", (c20 - 1.0) / (c40 - 1.0));
    let (cap, south) = (0.5 * (1.0 - 40f64.to_radians().cos()), 0.5 * (1.0 + 40f64.to_radians().cos()));
    println!("north gauge round 50N: {:.6} turn; south gauge: {:.6} turn; sum {:.6}", cap, south, cap + south);
    let (c_wind, c_lat) = (winding(&|th| th, 720), chern_by_lattice(&spin_half, 6));
    println!("c1 from the clutching angle at the equator: {:.6}; from spin-half overlaps, 6 x 12 grid: {:.12}", c_wind, c_lat);
    let bx = (30f64.to_radians().cos() - 40f64.to_radians().cos()) * PI / 6.0;
    println!("survey box: area {:.0} km2, rim {:.0} km; camera turn {:.4} deg; spin-half phase {:.4} deg", bx * 6371f64.powf(2.0),
        6371.0 * (PI / 9.0 + PI / 6.0 * (0.5 + 40f64.to_radians().sin())), bx.to_degrees(), (bx / 2.0).to_degrees());
    println!("part 2: the tangent bundle (the camera's level frames)");
    let (e_wind, e_lat) = (winding(&clutch_tangent, 720), chern_by_lattice(&level_frame, 6));
    let e_int = chern_by_integral(&|ph: f64, _th: f64| ph.sin(), 40);
    println!("Euler number from the clutching between stereographic frames: {:.6}; from level-frame overlaps, 6 x 12 grid: {:.12}", e_wind, e_lat);
    println!("Euler number from K dA / 2pi, 40 x 80 grid: {:.9}", e_int);
    println!("part 3: a different connection on the monopole bundle");
    let (mph, mth) = (35f64.to_radians(), (-15f64).to_radians());
    println!("F density at 55N 15W: old {:.6}, new {:.6}", f(mph, mth), deformed(mph, mth));
    let (d20, d40) = (chern_by_integral(&deformed, 20), chern_by_integral(&deformed, 40));
    println!("c1 of the new connection: 20 x 40 grid {:.9}; 40 x 80 grid {:.9}", d20, d40);
    println!("part 4: invariant polynomials");
    let x = [[c(0.0, 0.3), c(0.2, 0.1)], [c(-0.2, 0.1), c(0.0, -0.7)]];
    let g = [[c(0.6, 0.0), c(0.0, 0.8)], [c(0.0, 0.8), c(0.6, 0.0)]]; // unitary, so g^-1 is its conjugate transpose
    let gi = [[g[0][0].conj(), g[1][0].conj()], [g[0][1].conj(), g[1][1].conj()]];
    let mul = |a: [[C; 2]; 2], b: [[C; 2]; 2]| -> [[C; 2]; 2] {
        let e = |i: usize, j: usize| c(0.0, 0.0).add(a[i][0].mul(b[0][j])).add(a[i][1].mul(b[1][j]));
        [[e(0, 0), e(0, 1)], [e(1, 0), e(1, 1)]]
    };
    let y = mul(gi, mul(x, g));
    let mut cs = vec![];
    for (nm, m) in [("F", x), ("g^-1 F g", y)] {
        let det = m[0][0].mul(m[1][1]).re - m[0][1].mul(m[1][0]).re;
        cs.push((-(m[0][0].add(m[1][1])).im / TURN, -det / TURN.powf(2.0)));
        let l = cs[cs.len() - 1];
        println!("{}: c1 part {:.6}, c2 part {:.6}, top-left entry {:.6}i", nm, l.0, l.1, m[0][0].im);
    }
    let w: [[i64; 4]; 4] = [[0, 1, 2, 3], [-1, 0, 4, 5], [-2, -4, 0, 6], [-3, -5, -6, 0]];
    let mut wr = w;
    for i in 0..4 { for j in 0..4 { if (i == 0) != (j == 0) { wr[i][j] = -w[i][j]; } } }
    println!("Pfaffian {}, after a reflection {}; Pfaffian squared {}", pf4(&w), pf4(&wr), pf4(&w).pow(2));
    println!("part 5: the round 4-sphere, radius 1");
    let dl = |a: usize, b: usize| if a == b { 1.0 } else { 0.0 };
    let r: Vec<Vec<Vec<Vec<f64>>>> = (0..4).map(|a| (0..4).map(|b| (0..4).map(|c| (0..4)
        .map(|d| dl(a, c) * dl(b, d) - dl(a, d) * dl(b, c)).collect()).collect()).collect()).collect();
    let (pf_c, tr_c) = (top_form(&r, true), top_form(&r, false));
    let vol = |n: usize| TURN * (1..=3).map(|k| (0..n).map(|i| ((i as f64 + 0.5) * PI / n as f64).sin()
        .powf(k as f64)).sum::<f64>() * PI / n as f64).product::<f64>();
    let (v20, v40) = (vol(20), vol(40));
    let rm2: f64 = (0..256).map(|k| r[k / 64][k / 16 % 4][k / 4 % 4][k % 4].powf(2.0)).sum();
    let ric: Vec<Vec<f64>> = (0..4).map(|a| (0..4).map(|b| (0..4).map(|c| r[c][a][c][b]).sum()).collect()).collect();
    let ric2: f64 = (0..16).map(|k| ric[k / 4][k % 4].powf(2.0)).sum();
    let sc: f64 = (0..4).map(|a| ric[a][a]).sum();
    let (chi_pf, chi_gbc) = (pf_c * v40 / TURN.powf(2.0), (rm2 - 4.0 * ric2 + sc.powf(2.0)) * v40 / (32.0 * PI.powf(2.0)));
    let comb = |n: i64, k: i64| (0..k).fold(1i64, |acc, i| acc * (n - i) / (i + 1));
    let chi_cells: i64 = (0..5).map(|k| (-1i64).pow(k as u32) * comb(6, k + 1)).sum();
    println!("Pfaffian of curvature: {:.6} e1234; trace of Omega^Omega: {:.6} e1234", pf_c, tr_c);
    println!("volume: 20 grid {:.9}; 40 grid {:.9}; exact 8pi^2/3 {:.9}", v20, v40, 8.0 * PI.powf(2.0) / 3.0);
    println!("|Rm|^2 {:.0}, |Ric|^2 {:.0}, S^2 {:.0}; p1 from the trace: {:.6}", rm2, ric2, sc.powf(2.0), -tr_c * v40 / (8.0 * PI.powf(2.0)) + 0.0);
    println!("chi: from the Pfaffian {:.6}; from 4D Gauss-Bonnet-Chern {:.6}; from cells {}", chi_pf, chi_gbc, chi_cells);
    println!("part 6: real line bundles over the circle");
    let mob = [1i32, -1]; // transition signs on the two overlaps of two arcs covering the circle
    for (nm, t) in [("band", [1, 1]), ("Mobius", mob), ("Mobius squared", mob.map(|a| a * a))] {
        let hol = t[0] * t[1];
        println!("{}: section returns {:+}, w1 = {}, curvature 0, two-sided copies {}", nm, hol, (1 - hol) / 2, if hol == 1 { 2 } else { 1 });
    }
    println!("what breaks");
    println!("north gauge alone round 89.9S: {:.6} turn hidden at the pole", 0.5 * (1.0 - 179.9f64.to_radians().cos()));
    println!("F without the 1/2pi: {:.6}; level frames on a 1 x 2 grid: {:.6}", c40 * TURN, chern_by_lattice(&level_frame, 1));
    assert!((c40 - 1.0).abs() < 1e-3 && (c20 - 1.0).abs() > (c40 - 1.0).abs());
    assert!(c_wind.round() == 1.0 && c_lat.round() == 1.0 && (c_lat - 1.0).abs() < 1e-9);
    assert!(e_wind.round() == 2.0 && e_lat.round() == 2.0 && (e_int - 2.0).abs() < 1e-3);
    let [px, py, pz] = p(mph, mth);
    assert!((d40 - 1.0).abs() < 1e-3 && (deformed(mph, mth) - f(mph, mth) * (1.0 + px * px - 2.0 * py * py + pz * pz)).abs() < 1e-6);
    assert!((cs[0].0 - cs[1].0).abs() < 1e-12 && (cs[0].1 - cs[1].1).abs() < 1e-12 && (x[0][0].im - y[0][0].im).abs() > 0.1);
    assert!((pf4(&w).pow(2) as f64) == perms().iter().map(|s| sign(s) * (0..4).map(|i| w[i][s[i]] as f64).product::<f64>()).sum::<f64>());
    assert!((pf_c - 3.0).abs() < 1e-12 && (chi_pf - 2.0).abs() < 1e-3 && (chi_gbc - chi_cells as f64).abs() < 1e-3 && (ric2 - 36.0).abs() < 1e-12 && (sc - 12.0).abs() < 1e-12);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-24 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
part 1: the monopole (Hopf) line bundle over the globe
c1 by integrating F/2pi: 20 x 40 grid 1.001028824; 40 x 80 grid 1.000257067
error ratio, coarse over fine: 4.0022
north gauge round 50N: 0.116978 turn; south gauge: 0.883022 turn; sum 1.000000
c1 from the clutching angle at the equator: 1.000000; from spin-half overlaps, 6 x 12 grid: 1.000000000000
survey box: area 2124864 km2, rim 6036 km; camera turn 2.9994 deg; spin-half phase 1.4997 deg
part 2: the tangent bundle (the camera's level frames)
Euler number from the clutching between stereographic frames: 2.000000; from level-frame overlaps, 6 x 12 grid: 2.000000000000
Euler number from K dA / 2pi, 40 x 80 grid: 2.000514134
part 3: a different connection on the monopole bundle
F density at 55N 15W: old 0.286788, new 0.554616
c1 of the new connection: 20 x 40 grid 1.002064351; 40 x 80 grid 1.000514551
part 4: invariant polynomials
F: c1 part 0.063662, c2 part -0.006586, top-left entry 0.300000i
g^-1 F g: c1 part 0.063662, c2 part -0.006586, top-left entry -0.148000i
Pfaffian 8, after a reflection -8; Pfaffian squared 64
part 5: the round 4-sphere, radius 1
Pfaffian of curvature: 3.000000 e1234; trace of Omega^Omega: 0.000000 e1234
volume: 20 grid 26.345846054; 40 grid 26.325699833; exact 8pi^2/3 26.318945070
|Rm|^2 24, |Ric|^2 36, S^2 144; p1 from the trace: 0.000000
chi: from the Pfaffian 2.000513; from 4D Gauss-Bonnet-Chern 2.000513; from cells 2
part 6: real line bundles over the circle
band: section returns +1, w1 = 0, curvature 0, two-sided copies 2
Mobius: section returns -1, w1 = 1, curvature 0, two-sided copies 1
Mobius squared: section returns +1, w1 = 0, curvature 0, two-sided copies 2
what breaks
north gauge alone round 89.9S: 0.999999 turn hidden at the pole
F without the 1/2pi: 6.284801; level frames on a 1 x 2 grid: 0.000000
ALL CHECKS PASS
```

### Lean

Lean proves the monopole bundle's first Chern number for two connections, and that $`\det(I + tX)`$ ignores the gauge.

- Take the monopole curvature $`F = \tfrac12\sin\varphi\,d\varphi\wedge d\theta`$. Then $`F/2\pi`$ integrates over the globe to exactly 1, the first Chern number.
- Take the new curvature density $`\tfrac12\sin\varphi\,(1 + x^2 - 2y^2 + z^2)`$ from adding $`b`$. Then its integral over the globe, over $`2\pi`$, is still exactly 1.
- Take any square matrix $`X`$, any invertible matrix $`g`$ and any number $`t`$. Then $`\det(I + t\,g^{-1}Xg) = \det(I + tX)`$.
- The two gauges' shares add to one turn, at any split latitude.
- The test matrix has Pfaffian 8, and −8 after a reflection; its Pfaffian squared is its determinant.
- The 4-sphere's three sums for $`\chi`$ each give 2: from the Pfaffian, the curvature tensors and the cells.

The grid integrals, the lattice counts, the formula for $`db`$ and the 4-sphere's curvature values are left to the Python and Rust checks.

```lean
-- Chern-Weil: the monopole bundle's curvature over the globe integrates to exactly one turn, adding the card's global one-form to its connection leaves that total at exactly one, and det(I + tX) does not change when X is replaced by g⁻¹Xg.
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.NormNum

open Real Matrix

namespace ChernWeil

/-! On the globe, `φ` is the angle down from the North Pole (0 to π) and `θ` the longitude east
(0 to 2π). A two-form `f(φ, θ) dφ ∧ dθ` is integrated over the globe as the iterated integral of
its density `f` over these ranges. The monopole curvature is `F = ½ sin φ dφ ∧ dθ`; its first
Chern number is the integral of `F / 2π`. -/

/-- The monopole (Hopf) line bundle over the globe has first Chern number 1: its curvature
`F = ½ sin φ dφ ∧ dθ`, divided by `2π` and integrated over the whole globe, gives exactly one
turn, `(1/4π) × 2 × 2π = 1`. -/
theorem monopole_first_chern_number_eq_one :
    (1 / (2 * π)) * ∫ θ in (0 : ℝ)..2 * π, ∫ φ in (0 : ℝ)..π, (1 / 2) * sin φ = 1 := by
  rw [intervalIntegral.integral_const_mul, integral_sin]
  simp only [cos_zero, cos_pi, intervalIntegral.integral_const, smul_eq_mul]
  field_simp
  ring

/-- Changing the connection does not change the Chern number. Adding the card's global one-form
`b = ½ (z (x dy − y dx) + x (y dz − z dy))` to the monopole connection changes the curvature density
from `½ sin φ` to `½ sin φ (1 + x² − 2y² + z²)`, with `x = sin φ cos θ`, `y = sin φ sin θ`,
`z = cos φ` the globe's coordinates; the curvature moves from point to point, but its integral
over the globe, divided by `2π`, is still exactly 1. -/
theorem first_chern_number_unchanged_by_new_connection :
    (1 / (2 * π)) * ∫ θ in (0 : ℝ)..2 * π, ∫ φ in (0 : ℝ)..π,
      (1 / 2) * sin φ * (1 + (sin φ * cos θ) ^ 2 - 2 * (sin φ * sin θ) ^ 2 + cos φ ^ 2) = 1 := by
  have hin : ∀ θ : ℝ, (∫ φ in (0 : ℝ)..π,
      (1 / 2) * sin φ * (1 + (sin φ * cos θ) ^ 2 - 2 * (sin φ * sin θ) ^ 2 + cos φ ^ 2))
      = 2 * cos θ ^ 2 := by
    intro θ
    have hpt : ∀ φ : ℝ,
        (1 / 2) * sin φ * (1 + (sin φ * cos θ) ^ 2 - 2 * (sin φ * sin θ) ^ 2 + cos φ ^ 2)
          = sin φ - (3 / 2 * sin θ ^ 2) * sin φ ^ 3 := by
      intro φ
      have hφ := sin_sq_add_cos_sq φ
      have hθ := sin_sq_add_cos_sq θ
      linear_combination (1 / 2 * sin φ) * hφ + (1 / 2 * sin φ * sin φ ^ 2) * hθ
    simp_rw [hpt]
    rw [intervalIntegral.integral_sub, intervalIntegral.integral_const_mul, integral_sin,
      integral_sin_pow_three]
    · simp only [cos_zero, cos_pi]
      have hθ := sin_sq_add_cos_sq θ
      linear_combination (-2 : ℝ) * hθ
    · exact continuous_sin.intervalIntegrable _ _
    · exact (continuous_const.mul (continuous_sin.pow 3)).intervalIntegrable _ _
  simp_rw [hin]
  rw [intervalIntegral.integral_const_mul, integral_cos_sq]
  simp only [cos_zero, sin_zero, sin_two_pi, cos_two_pi]
  field_simp
  ring

/-- Invariant polynomials ignore the gauge: for every square matrix `X`, every invertible matrix
`g` (a gauge change) and every number `t`, `det(I + t g⁻¹Xg) = det(I + tX)`. So every coefficient
of `t^k` in `det(I + tX)`, which gives the Chern and Pontryagin forms, is the same in every gauge. -/
theorem det_one_add_smul_gauge_change {n R : Type*} [Fintype n] [DecidableEq n] [CommRing R]
    (g : (Matrix n n R)ˣ) (X : Matrix n n R) (t : R) :
    det (1 + t • ((g⁻¹ : (Matrix n n R)ˣ).val * X * g.val)) = det (1 + t • X) := by
  have h : (1 : Matrix n n R) + t • ((g⁻¹ : (Matrix n n R)ˣ).val * X * g.val)
      = (g⁻¹ : (Matrix n n R)ˣ).val * (1 + t • X) * g.val := by
    rw [Matrix.mul_add, Matrix.add_mul, Matrix.mul_one, Matrix.mul_smul, Matrix.smul_mul,
      ← Units.val_mul, inv_mul_cancel, Units.val_one]
  rw [h, det_units_conj']

/-! The card's worked numbers, checked exactly. -/

-- Monopole bundle: (1/4π) × 2 × 2π = 1.
example : (1 / (4 * π)) * 2 * (2 * π) = 1 := by
  field_simp; norm_num

-- North cap in the north gauge plus the rest in the south gauge, split at any latitude: one turn.
example (φ₀ : ℝ) : (1 / 2) * (1 - cos φ₀) + (1 / 2) * (1 + cos φ₀) = 1 := by
  ring

/-- The Pfaffian of a 4 by 4 antisymmetric matrix: `W₁₂ W₃₄ − W₁₃ W₂₄ + W₁₄ W₂₃`. -/
def pf4 (W : Matrix (Fin 4) (Fin 4) ℤ) : ℤ := W 0 1 * W 2 3 - W 0 2 * W 1 3 + W 0 3 * W 1 2

/-- The card's antisymmetric test matrix. -/
def W : Matrix (Fin 4) (Fin 4) ℤ := !![0, 1, 2, 3; -1, 0, 4, 5; -2, -4, 0, 6; -3, -5, -6, 0]

/-- The same matrix after the reflection that flips the first axis. -/
def Wr : Matrix (Fin 4) (Fin 4) ℤ := !![0, -1, -2, -3; 1, 0, 4, 5; 2, -4, 0, 6; 3, -5, -6, 0]

-- Pfaffian 8, after a reflection −8; Pfaffian squared 64, the determinant.
example : pf4 W = 8 := by decide
example : pf4 Wr = -8 := by decide
example : pf4 W ^ 2 = W.det := by
  norm_num [pf4, W, Matrix.det_succ_row_zero, Fin.sum_univ_succ, Fin.succAbove]

-- Unit 4-sphere: the Pfaffian 3 times the volume 8π²/3, over 4π², gives χ = 2.
example : 3 * (8 * π ^ 2 / 3) / (4 * π ^ 2) = 2 := by
  field_simp; norm_num

-- Unit 4-sphere: (|Rm|² − 4|Ric|² + S²) times the volume, over 32π², gives χ = 2.
example : ((24 : ℝ) - 4 * 36 + 144) * (8 * π ^ 2 / 3) / (32 * π ^ 2) = 2 := by
  field_simp; norm_num

-- Cells of the boundary of a 5-simplex: 6 − 15 + 20 − 15 + 6 = 2.
example : ∑ k ∈ Finset.range 5, (-1 : ℤ) ^ k * (Nat.choose 6 (k + 1) : ℤ) = 2 := by decide

-- Möbius band: transition signs +1 and −1, so a section returns as −1 and w₁ = 1.
example : (1 - (1 : ℤ) * (-1)) / 2 = 1 := by decide

#print axioms monopole_first_chern_number_eq_one
#print axioms first_chern_number_unchanged_by_new_connection
#print axioms det_one_add_smul_gauge_change

end ChernWeil
```

**Checked 2026-11-24 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'ChernWeil.monopole_first_chern_number_eq_one' depends on axioms: [propext, Classical.choice, Quot.sound]
'ChernWeil.first_chern_number_unchanged_by_new_connection' depends on axioms: [propext, Classical.choice, Quot.sound]
'ChernWeil.det_one_add_smul_gauge_change' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> - Guess first: what does the lattice count give for a state that winds three times? In `spin_half`, change `cmath.exp(1j * th)` to `cmath.exp(3j * th)`. The count reads **3.000000000000**: a line bundle of Chern number 3. The assert for 1 then stops the run, as it should.
> - Guess first: does a much stronger change of connection move $`c_1`$? In `b_form`, change the `0.5` to `5.0`. The density at 55°N 15°W becomes **2.965062** and turns negative elsewhere, yet $`c_1`$ on the 40 × 80 grid is **1.002831908**. Only the grid error grows, enough to trip the 0.001 assert.
> - Guess first: where does the north gauge's share go if the split moves to 10°N? Change both `40`s to `80` in the line that sets `cap`. The shares become **0.413176** and **0.586824**; the sum is still 1.000000.
> - Guess first: how coarse can the level-frame lattice get? Change the `6` in `chern_by_lattice(level_frame, 6)` to `2`. A 2 × 4 grid still gives **2.000000000000**; only the 1 × 2 grid fails.

---

## The usual mistake

> [!warning]
> **Treating the curvature at a point as the invariant.** It is not. Adding a global one-form to the monopole connection moves the curvature density at 55°N 15°W from 0.286788 to 0.554616. Only the class of the form, and so its integral over the closed globe, is fixed: 1.000514551 on a 40 × 80 grid, tending to 1.
>
> - **Trusting a single gauge across the whole manifold.** The north gauge alone would make $`F`$ exact and its integral 0. It fails at the South Pole, where 0.999999 of a turn is still hiding at 89.9°S.
> - **Using a polynomial that is not invariant.** One entry of $`F`$ changes from 0.300000i to −0.148000i under a gauge change. Traces, determinants and the Pfaffian do not change.
> - **Forgetting the normalisation.** Without the $`1/2\pi`$ the monopole bundle gives 6.284801, which is not a whole number.
> - **Expecting curvature to see every twist.** The Möbius band has $`w_1 = 1`$ and every Chern-Weil form zero.

---

## Where you meet it in real life

- **The quantum Hall effect.** In a two-dimensional electron layer in a strong magnetic field, the Hall conductance comes in whole multiples of one fixed unit, the electron charge squared over Planck's constant. The whole multiple is a first Chern number, of the electron states over the torus of momenta ([Thouless, Kohmoto, Nightingale and den Nijs 1982](https://doi.org/10.1103/PhysRevLett.49.405)). The lattice road in the code is how such numbers are computed in practice.
- **Spin and magnetic fields.** Steer a magnetic field slowly round a loop of directions, and a spin-half particle aligned with it returns with an extra phase of half the enclosed solid angle (the area on the unit sphere of directions). For directions tracing the survey box, that is 1.4997°. These phases are the monopole bundle's holonomy.
- **Dirac's monopole.** A magnetic monopole's field over a sphere around it is a $`U(1)`$ curvature. Its first Chern number must be a whole number, which forces electric charge to come in whole units if any monopole exists.
- **Navigation near the poles.** No level heading reference covers the whole globe, because the tangent bundle's Euler number is 2, not 0. Systems switch references, such as true north and grid north, between patches, like the two gauges here.
- **Yang-Mills instantons.** On four-dimensional space, the second Chern number of a finite-energy $`SU(2)`$ gauge field, the integral of $`c_2`$, is a whole number that labels its topological sector ([Yang-Mills](../07-Geometric%20Analysis%20and%20Physics/03-yang-mills-fields-and-gauge-theory.md)).

> **Say it back**
> A bundle is trivial pieces glued by transition functions, and a connection gives it a curvature F that moves when the connection changes. Put F into a polynomial that ignores the gauge, such as det(I + iF/2π), and the result is a closed form. Two connections give forms that differ by an exact form, so the form's integral over a closed manifold belongs to the bundle. The monopole bundle over the globe gives 1, the globe's tangent bundle gives 2, and the 4-sphere's Pfaffian gives 2. A sign-only twist like the Möbius band's needs Stiefel-Whitney classes, which curvature cannot see.

---

## What this builds on

- [Principal bundle and connection](10-principal-bundles-and-connections-in-outline.md): the connection $`A`$, the curvature $`F = dA + A\wedge A`$, the gauge rule $`F' = g^{-1}Fg`$, and the 2 turns of the globe, which this card turns into a theorem about every connection.
- [Hairy ball theorem](09-vector-field-zeros-and-the-hairy-ball.md): zeros of a field counted with signs, the geometric meaning of the Euler class.
- [de Rham cohomology](../04-Differential%20Forms/08-de-rham-cohomology.md): closed forms modulo exact ones, the home of every class on this card.
- [Gauss-Bonnet](../02-Surfaces/10-gauss-bonnet-theorem.md): the rank-2 case of the Euler class, total curvature equal to $`2\pi\chi`$.
- [Stokes on manifolds](../04-Differential%20Forms/06-stokes-theorem-on-manifolds.md): why an exact form integrates to zero over a closed manifold, and the two-gauge split of the globe.
- [Orientability](../../17-Topology/03-Surfaces%20and%20Manifolds/03-orientability-mobius-strip-and-klein-bottle.md): the Möbius band and the sign that $`w_1`$ records.
- [Cohomology and the cup product in outline](../../17-Topology/05-Homology/08-cohomology-and-cup-product-in-outline.md): cohomology with whole-number and mod-2 coefficients, where the integer and mod-2 classes live before they become forms.
- [Chern classes and Hirzebruch-Riemann-Roch](../../22-Algebraic%20geometry/09-Intersection%20Theory%20and%20Surfaces/02-chern-classes-and-hirzebruch-riemann-roch.md): the same Chern classes built from algebra, for bundles on algebraic varieties.

## Where this goes next

- [Yang-Mills](../07-Geometric%20Analysis%20and%20Physics/03-yang-mills-fields-and-gauge-theory.md): give the curvature an energy and look for the connections of least energy; the second Chern number fixes a lower bound in each topological sector.
- [Spinors and the Dirac operator](../07-Geometric%20Analysis%20and%20Physics/12-spinors-dirac-operators-and-the-index-theorem.md): the index theorem, which counts solutions of the Dirac equation by an integral of Pontryagin forms.
- [The six-sphere](../../25-Frontier/04-Geometry%20and%20Combinatorics/08-complex-structures-on-the-six-sphere.md): whether $`S^6`$ carries a complex structure, a question about which Chern classes its tangent bundle can have.

Curvature gives every characteristic class over the real numbers, but which mod-2 classes, like $`w_1`$, does it miss, and what detects them on a given manifold?

---

## Sources

Verified 2026-11-24: every link below resolves to the publisher's page.

- Chern, Shiing-Shen. "A Simple Intrinsic Proof of the Gauss-Bonnet Formula for Closed Riemannian Manifolds." *Annals of Mathematics* 45, no. 4 (1944): 747–752. [doi:10.2307/1969302](https://doi.org/10.2307/1969302). The Pfaffian of the curvature integrates to the Euler characteristic in every even dimension.
- Chern, Shiing-Shen. "Characteristic Classes of Hermitian Manifolds." *Annals of Mathematics* 47, no. 1 (1946): 85–121. [doi:10.2307/1969037](https://doi.org/10.2307/1969037). Chern classes defined from curvature.
- Milnor, John W., and James D. Stasheff. *Characteristic Classes*. Annals of Mathematics Studies 76. Princeton University Press, 1974. [doi:10.1515/9781400881826](https://doi.org/10.1515/9781400881826). Stiefel-Whitney, Chern, Pontryagin and Euler classes, the Thom isomorphism, and the Chern-Weil construction in Appendix C.
- Fukui, Takahiro, Yasuhiro Hatsugai, and Hiroshi Suzuki. "Chern Numbers in Discretized Brillouin Zone: Efficient Method of Computing (Spin) Hall Conductances." *Journal of the Physical Society of Japan* 74, no. 6 (2005): 1674–1677. [doi:10.1143/JPSJ.74.1674](https://doi.org/10.1143/JPSJ.74.1674). The lattice count from overlaps that gives exact whole numbers.
- Thouless, D. J., M. Kohmoto, M. P. Nightingale, and M. den Nijs. "Quantized Hall Conductance in a Two-Dimensional Periodic Potential." *Physical Review Letters* 49, no. 6 (1982): 405–408. [doi:10.1103/PhysRevLett.49.405](https://doi.org/10.1103/PhysRevLett.49.405). The Hall conductance as a first Chern number.

