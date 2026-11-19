# Algebraic cycles: subvarieties added with weights, and the classes they leave behind

[Syllabus](../../../SYLLABUS.md) → [Algebraic geometry](../README.md) → [Cohomology and the Hodge Conjecture](../README.md#s05) → Algebraic cycles

---

## General Overview

Take the surface X of points $`(x : y : z : w)`$ in complex projective 3-space with $`x^4 - y^4 - z^4 + w^4 = 0`$. It is a smooth quartic surface, the shelf's house example. The field is $`\mathbb{C}`$ throughout. It is also the Fermat quartic $`x^4 + y^4 + z^4 + w^4 = 0`$ of [The Hodge conjecture](08-hodge-conjecture-statement-and-known-cases.md) in other coordinates (multiply y and z by a number whose fourth power is −1), and the two lines found below are two of its 48 lines.

Slice X with the plane P where $`x - y - z + w = 0`$. A plane slice of a quartic is a curve of degree 4. On this plane it breaks into three pieces:

- the line L, where $`x = y`$ and $`z = w`$;
- the line M, where $`x = z`$ and $`y = w`$;
- a conic C, a curve of degree 2.

Now take the conic and the line L together, each counted once. That bundle is written $`W = C + L`$. It is an **algebraic cycle**: a list of subvarieties (shapes cut out by polynomial equations) with a whole-number **weight** on each. Weights can be negative, as in $`3C - 2L`$.

A cycle is only a list. Its **class** $`[W]`$ is what cohomology keeps of it: the numbers it gives when other curves and forms are measured against it. For $`W = C + L`$:

- a general plane meets W in 3 points;
- W meets itself 0 times, in the sense made exact below;
- W meets the line M in 3 points;
- the surface's holomorphic 2-form $`\sigma`$ (a form built from two dz's, defined in Step 2) integrates to 0 over W.

The last zero is the test this shelf is built on. Every class that comes from a cycle passes it. Whether passing it is enough is [The Hodge conjecture](08-hodge-conjecture-statement-and-known-cases.md).

**An algebraic cycle is a whole-number combination of subvarieties; its class is the cohomology class that integrates every closed form over it, piece by piece with the weights, and because every piece is complex that class has type (p, p).**

**What kind of fact this is:** a definition (the cycle and its class) and a theorem (every cycle class has type (p, p)), proved in outline in Why it works; the intersection numbers on X are computed exactly by the checks.

### The picture: from shapes to numbers

```mermaid
flowchart LR
    C["conic C, weight 1"] --> W["cycle W = C + L"]
    L["line L, weight 1"] --> W
    W --> K["class [W] in H2 of X"]
    K -->|"meet a plane"| D["3 points"]
    K -->|"meet itself"| S["0"]
    K -->|"integrate sigma"| T["0, so type (1, 1)"]
```

The cycle is the list on the left. The class is everything to its right: three numbers, each printed by the checks below.

---

## The formula

Notation first, in words.

- X is a smooth projective variety over $`\mathbb{C}`$ of complex dimension n. Here X is the quartic surface and n = 2.
- A **subvariety** $`V_i`$ is an irreducible shape inside X (one that does not split into two smaller shapes), cut out by further polynomial equations. Its **codimension** p is how many complex dimensions it falls short of X. A curve on a surface has p = 1.
- $`H^{2p}(X, \mathbb{Z})`$ is the cohomology of X in degree 2p with whole-number coefficients ([Cohomology and the cup product in outline](../../17-Topology/05-Homology/08-cohomology-and-cup-product-in-outline.md)). Over $`\mathbb{C}`$ it splits into pieces $`H^{a,b}`$ with $`a + b = 2p`$, where a counts the $`dz`$'s and b the $`d\bar z`$'s in a form ([Hodge decomposition](05-hodge-decomposition.md)).

```math
W = \sum_i n_i V_i, \qquad [W] = \sum_i n_i\,[V_i] \in H^{2p}(X, \mathbb{Z}), \qquad \int_X [W] \wedge \alpha = \sum_i n_i \int_{V_i} \alpha
```

**Read it aloud:** a cycle is a sum of subvarieties with whole-number weights. Its class is the same sum of their classes. Pairing the class with a closed form α means integrating α over each piece and adding the results with the weights.

Here α is any closed form of degree $`2(n - p)`$, the degree a piece of codimension p can integrate. The type statement is:

```math
[W] \in H^{p,p}(X), \qquad \text{because} \qquad \int_{V_i} \alpha = 0 \ \text{ for every closed } \alpha \text{ of type } (a, b) \text{ with } a \ne b
```

**Read it aloud:** the class lies in the (p, p) piece, because a form with unequal numbers of dz's and dz-bars integrates to zero over every complex piece.

On the surface X, p = 1, and two curve classes are paired by the **intersection number**. For two different curves that meet cleanly it counts their meeting points over $`\mathbb{C}`$:

```math
A \cdot B = \int_X [A] \wedge [B], \qquad [C + L] = h - [M], \qquad (C + L) \cdot h = 3, \qquad (C + L) \cdot (C + L) = 0
```

**Read it aloud:** A dot B is the integral over X of the product of their classes. The class of C plus L is the plane class minus the class of M. It meets a plane 3 times and itself 0 times.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $`X`$; $`x, y, z, w`$ | the variety; its homogeneous coordinates | $`x^4 - y^4 - z^4 + w^4 = 0`$, a surface | — |
| $`n`$, $`p`$ | complex dimension of X; codimension of a piece | n = 2; p = 1 for a curve | higher p, higher degree 2p |
| $`P`$, $`h`$ | a plane; the class of a plane slice, the hyperplane class | $`x - y - z + w = 0`$; $`h \cdot h = 4`$ | — |
| $`C`$, $`L`$, $`M`$ | the conic and the two lines in the slice | $`C + L + M`$ is the slice | — |
| $`V_i`$, $`n_i`$ | the pieces of a cycle; their whole-number weights | C and L, weights 1 and 1 | a bigger weight scales that piece's numbers |
| $`W`$, $`[W]`$ | a cycle; its class | $`W = C + L`$, $`[W] = h - [M]`$ | — |
| $`H^{2p}(X, \mathbb{Z})`$ | whole-number cohomology in degree 2p | rank 22 for this X in degree 2 | — |
| $`H^{a,b}`$ | the part of cohomology made of forms with a dz's and b dz-bars | type (1, 1) has dimension 20 here | — |
| $`A \cdot B`$ | intersection number of two curve classes | $`C \cdot L = 2`$, $`C \cdot C = -2`$ | — |
| $`\omega`$ | a closed (1, 1)-form with class h, scaled so a line has area 1 | integrates to 2 over C | — |
| $`\sigma`$ | the holomorphic 2-form of X, type (2, 0) | $`dx \wedge dy / (\partial F/\partial z)`$ with w = 1 | — |
| $`E`$, $`dz_1 \wedge dz_2`$ | the square-lattice torus $`\mathbb{C}/\mathbb{Z}[i]`$; the (2, 0)-form on $`E \times E`$ | gives i on a real torus, 0 on curves | — |

Also used:

- F, the quartic's polynomial; q, the conic's quadratic form;
- α, a closed form being integrated; β, any form, with $`d\beta`$ its exterior derivative (an exact form);
- u and v, tangent vectors in Step 2; s and t, lattice vectors in Step 5;
- $`e_1, \dots, e_4`$, the lattice basis of $`E \times E`$; $`p_{jk}`$, a real torus's six class coordinates;
- K, g and D, the canonical class, genus and curve in the adjunction formula;
- ρ, the rank of the cycle classes in degree 2; i, the square root of −1.

### When it holds

- **X smooth and compact.** Integrating over X and turning integrals into classes needs a compact manifold. On an open X a curve can run off to infinity and its integrals diverge.
- **Complex pieces.** A real surface inside a complex one still has a class, but it can fail type (1, 1). The real torus in Step 5 gives i, not 0.
- **Counts over $`\mathbb{C}`$, with multiplicity.** C meets L in two points with non-real coordinates. Counted over $`\mathbb{R}`$ there are none, and the self-intersection of C comes out +2 instead of −2.
- **The surface around the curve.** $`L \cdot L = -2`$ on X. In the plane P alone a line meets itself once. Self-intersection depends on where the curve sits.
- **Clean meetings for point counts.** $`A \cdot B`$ is a plain count only when A and B are different curves with different tangent lines at each meeting point. Otherwise each point carries a multiplicity, the subject of [Intersection multiplicity](../03-Plane%20Curves/02-intersection-multiplicity-and-tangency.md).

---

## Why it works

### Step 0: a shape is known by what it integrates

A closed subvariety has no boundary. By Stokes' theorem, an exact form $`d\beta`$ integrates to 0 over it. So the integral of a closed form over V depends only on the form's de Rham class ([De Rham cohomology](02-de-rham-cohomology-of-varieties.md)).

That makes V a linear rule: "give me a class, I return a number". Poincaré duality on the compact manifold X turns such a rule into a class $`[V]`$: the one class whose product with any α, integrated over X, gives $`\int_V \alpha`$.

Singular points do not spoil this: they have zero area, and the integral over the smooth part still converges (Griffiths and Harris, in Sources).

### Step 1: weights add

Integration is linear. The integral over $`C + L`$ is the integral over C plus the integral over L. So $`[C + L] = [C] + [L]`$, and $`3C - 2L`$ has class $`3[C] - 2[L]`$.

Each $`[V_i]`$ is a whole-number class: a complex subvariety has a natural orientation, so it has a homology class over $`\mathbb{Z}`$ ([Homology groups](../../17-Topology/05-Homology/02-homology-groups.md)). Whole-number weights keep the sum whole.

### Step 2: a complex piece sees only type (p, p)

At a smooth point of a complex curve, the tangent directions form a complex line: if u is tangent, so is iu. Take any form with two dz's, such as $`dx \wedge dy`$ in complex coordinates x, y. On the pair (u, iu):

```math
(dx \wedge dy)(u, iu) = dx(u)\,dy(iu) - dy(u)\,dx(iu) = i\,\big(dx(u)\,dy(u) - dy(u)\,dx(u)\big) = 0
```

**Read it aloud:** a two-dz form, fed a tangent vector and i times it, gives i times something minus itself, which is zero.

So every (2, 0)-form restricts to zero on a complex curve, and by conjugation so does every (0, 2)-form. Only (1, 1)-forms survive, and their integrals are what $`[W]`$ records. In general a piece of codimension p has complex dimension $`n - p`$, only $`(n - p, n - p)`$-forms survive on it, and the class has type (p, p).

The check makes this concrete at the point $`(1 : 1 : 1 : 1)`$, which lies on both L and M. Set w = 1 and write $`F = x^4 - y^4 - z^4 + 1`$. The holomorphic 2-form of X is $`\sigma = dx \wedge dy / (\partial F / \partial z)`$: a (2, 0)-form with complex-analytic coefficients, the only one on X up to a constant factor. At this point $`\partial F/\partial z = -4z^3 = -4`$.

| Tangent pair at (1, 1, 1) | $`\sigma`$ on it | What the pair spans |
| --- | --- | --- |
| u = (1, 1, 0) and iu | 0 | the complex tangent line of L |
| v = (1, 0, 1) and iv | 0 | the complex tangent line of M |
| u and v | $`(1 \cdot 0 - 1 \cdot 1)/(-4) = 1/4`$ | the tangent plane of X's real points |

A real surface can carry a (2, 0) part. A complex curve cannot.

### Step 3: the plane slice gives the numbers

Put $`w = -x + y + z`$ into F. The result factors exactly, with each factor once:

```math
F\big|_P = 2\,(x - y)(x - z)\,q, \qquad q = x^2 + 2y^2 + 2z^2 - xy - xz + 3yz
```

**Read it aloud:** on the plane, the quartic is 2 times x minus y, times x minus z, times the conic q.

The factor $`x - y`$ is L, $`x - z`$ is M, and q is C. The matrix of q has determinant 3/2, which is not zero, so C is a smooth conic. Its leading minors 1, 7/4 and 3/2 are all positive, so C has no real points at all.

So the slice is the cycle $`C + L + M`$, and its class is h: every plane slice has the same class, because one plane slides to any other.

The direct counts, all over $`\mathbb{C}`$:

- $`C \cdot L = 2`$: on $`x = y`$, q becomes $`2(y^2 + yz + z^2)`$, with discriminant −12, so two different points.
- $`C \cdot M = 2`$: on $`x = z`$, q becomes the same form, discriminant −12.
- $`L \cdot M = 1`$: the four linear equations of L and M have rank 3, so they share the single point $`(1 : 1 : 1 : 1)`$, where q = 6, so C misses it.
- $`C \cdot h = 2`$, $`L \cdot h = 1`$, $`M \cdot h = 1`$: the plane $`x = 0`$ meets each curve in as many points as its degree; for C, $`2y^2 + 3yz + 2z^2`$ has discriminant −7.

Now pair $`h = C + L + M`$ with C, then L, then M:

```math
C \cdot C = 2 - 2 - 2 = -2, \qquad L \cdot L = 1 - 2 - 1 = -2, \qquad M \cdot M = 1 - 2 - 1 = -2
```

**Read it aloud:** each self-intersection is that curve's degree minus its meetings with the other two pieces, and all three come out minus 2.

A second road gives the same −2: the adjunction formula.

<details>
<summary>The adjunction formula on a quartic surface, quoted</summary>

For a smooth curve D of genus g on a smooth surface X with canonical class K (the class of the bundle of holomorphic 2-forms),

$`\displaystyle D \cdot D + K \cdot D = 2g - 2.`$

A smooth surface of degree d in projective 3-space has $`K = (d - 4)\,h`$, so on a quartic $`K = 0`$. Such a surface is a K3 surface. A smooth conic and a line are both copies of the projective line, so g = 0 and $`D \cdot D = -2`$. Huybrechts, in Sources, proves both facts.

X itself is smooth: the four partial derivatives $`4x^3`$, $`-4y^3`$, $`-4z^3`$, $`4w^3`$ vanish together only at $`x = y = z = w = 0`$, which is not a point of projective space.

</details>

A third check: $`h \cdot h = 2 + 1 + 1 = 4`$, and the line $`x = y = 0`$ meets X where $`z^4 = w^4`$, in 4 different points, since $`z^4 - w^4`$ has no repeated root. A plane times a plane is a line, and a line meets a quartic 4 times.

### Step 4: the class of C + L

Write the intersection numbers of C, L and M as a table:

| | C | L | M |
| --- | ---: | ---: | ---: |
| C | −2 | 2 | 2 |
| L | 2 | −2 | 1 |
| M | 2 | 1 | −2 |

For $`W = C + L`$, add the C and L rows and columns: $`W \cdot W = -2 + 2 \times 2 - 2 = 0`$, and $`W \cdot M = 2 + 1 = 3`$. Because $`[C] + [L] + [M] = h`$, the class is $`[W] = h - [M]`$, whose square is $`4 - 2 \times 1 - 2 = 0`$ again.

What the 0 means: every plane through M meets X in M plus a plane cubic. Each such cubic has class $`h - [M]`$, the class of $`C + L`$. All but finitely many of these cubics are smooth curves of genus 1 (quoted, not checked here). So $`C + L`$ is one member of a family that sweeps X, the member that broke into a conic and a line. Members of one family never meet, so the square is 0. The class cannot tell the broken member from a smooth one.

The check also reads the class analytically. It integrates ω over C and L, each parametrised by one complex number, with Simpson's rule: 2.000000 and 1.000000, so W gives 3.000000, matching $`W \cdot h = 3`$.

### Step 5: a class that fails the test

On X every class built so far is type (1, 1), as Step 2 promised. To see the test fail, take the house torus $`E = \mathbb{C}/\mathbb{Z}[i]`$ and the surface $`E \times E`$. Its whole-number classes in degree 2 form a lattice of rank 6, and everything is exact.

Use the lattice vectors $`e_1 = (1, 0)`$, $`e_2 = (i, 0)`$, $`e_3 = (0, 1)`$, $`e_4 = (0, i)`$. A real 2-torus spanned by lattice vectors s and t has class $`s \wedge t`$, written as six whole numbers $`p_{jk} = s_j t_k - s_k t_j`$. The (2, 0)-form gives:

```math
(dz_1 \wedge dz_2)(u, v) = (p_{13} - p_{24}) + i\,(p_{14} + p_{23})
```

**Read it aloud:** dz1 wedge dz2 on the class is p13 minus p24, plus i times p14 plus p23.

Type (1, 1) means both brackets vanish: two conditions, so the type (1, 1) classes have rank 6 − 2 = 4.

| Real 2-torus | Spanned by | $`dz_1 \wedge dz_2`$ gives | A cycle? |
| --- | --- | --- | --- |
| $`E \times 0`$ | (1, 0), (i, 0) | 0 | yes, a curve |
| $`0 \times E`$ | (0, 1), (0, i) | 0 | yes |
| the diagonal | (1, 1), (i, i) | 0 | yes |
| graph of $`z \mapsto iz`$ | (1, i), (i, −1) | 0 | yes |
| a real torus | (1, 0), (0, i) | **i** | no class of type (1, 1) |

The four curves span rank 4: all the type (1, 1) classes, over $`\mathbb{Q}`$. The real torus has a (2, 0) part, so no cycle has its class. Whether every type (p, p) class is reached by cycles is the question of [The Hodge conjecture](08-hodge-conjecture-statement-and-known-cases.md).

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| the slice | put $`w = -x + y + z`$ into F | $`2(x - y)(x - z)\,q`$ |
| C is smooth, no real points | determinant and leading minors of q's matrix | 3/2; 1, 7/4, 3/2 |
| $`C \cdot L`$ | q on $`x = y`$: $`2y^2 + 2yz + 2z^2`$, discriminant $`2^2 - 4 \times 2 \times 2`$ | −12, so 2 points |
| $`C \cdot M`$ | q on $`x = z`$: same form | 2 |
| $`C \cdot h`$ | q on $`x = 0`$: $`2y^2 + 3yz + 2z^2`$, discriminant $`9 - 16`$ | −7, so 2 points |
| $`L \cdot M`$ | $`x = y`$, $`z = w`$, $`x = z`$, $`y = w`$ | 1 point, (1 : 1 : 1 : 1) |
| $`C \cdot C`$ | $`C \cdot h - C \cdot L - C \cdot M = 2 - 2 - 2`$ | −2 |
| $`L \cdot L`$ | $`1 - 2 - 1`$ | −2 |
| $`h \cdot h`$ | $`2 + 1 + 1`$ | 4 |
| $`W \cdot h`$ | $`C \cdot h + L \cdot h = 2 + 1`$ | **3** |
| $`W \cdot W`$ | $`-2 + 2 \times 2 - 2`$ | **0** |
| $`W \cdot M`$ | $`2 + 1`$ | 3 |
| $`\int_W \sigma`$ | σ is zero on each complex tangent line | **0, so type (1, 1)** |

**The cycle C + L has class $`h - [M]`$: degree 3, square 0, and type (1, 1).** It is a broken member of the family of plane cubics through M, and its class counts exactly like a smooth one.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Count $`C \cap L`$ and $`C \cap M`$ over $`\mathbb{R}`$ | 0 and 0, so $`C \cdot C = 2 - 0 - 0 = 2`$ | the meeting points have non-real coordinates; adjunction says −2 |
| Use the plane's rule $`L \cdot L = +1`$ | $`L \cdot h = 2 + 1 + 1 = 4`$, but L meets a plane in 1 point | self-intersection depends on the surface around the curve |
| Treat the real torus spanned by (1, 0), (0, i) in $`E \times E`$ as a cycle | $`dz_1 \wedge dz_2`$ gives i, not 0 | it is not a complex curve, so its class has a (2, 0) part |

---

## Code, from first principles, and it actually runs

The code reaches the class of $`C + L`$ by three independent roads. Road 1 is exact algebra: it factors the plane slice with whole-number polynomial arithmetic, counts meeting points by discriminants and by ranks of linear equations, finds the 4 different points of the line x = y = 0 on X by exact elimination (the quartic in z that gives them shares no factor with its derivative), and solves for the self-intersections. Road 2 is analysis: it integrates the (1, 1)-form ω over C and L with Simpson's rule and recovers the degrees. Road 3 is the type test: σ on tangent pairs at (1 : 1 : 1 : 1), after checking that u lies along L and v along M, then the exact lattice test on $`E \times E`$ with ranks by fraction arithmetic. Nothing imported knows any intersection number.

### Python

```python
# Algebraic cycles and cycle classes: the check behind the card.  Standard library only.
# X: x^4 - y^4 - z^4 + w^4 = 0, a smooth quartic surface over C.  The plane P: x - y - z + w = 0
# cuts X in a line L (x = y, z = w), a line M (x = z, y = w) and a conic C.  The cycle is W = C + L.
from fractions import Fraction as Fr
import math, cmath

def pmul(p, q):                   # polynomials as {exponent tuple: coefficient}
    r = {}
    for a, c in p.items():
        for b, d in q.items():
            k = tuple(i + j for i, j in zip(a, b)); r[k] = r.get(k, 0) + c * d
    return {k: v for k, v in r.items() if v}
def padd(*ps):
    r = {}
    for p in ps:
        for k, v in p.items(): r[k] = r.get(k, 0) + v
    return {k: v for k, v in r.items() if v}
def ppow(p, n): return pmul(ppow(p, n - 1), p) if n else {(0, 0, 0): 1}
x, y, z = {(1, 0, 0): 1}, {(0, 1, 0): 1}, {(0, 0, 1): 1}
neg = lambda p: {k: -v for k, v in p.items()}
w = padd(neg(x), y, z)                                   # on P, w = -x + y + z
F_on_P = padd(ppow(x, 4), neg(ppow(y, 4)), neg(ppow(z, 4)), ppow(w, 4))
Q = {(2, 0, 0): 1, (0, 2, 0): 2, (0, 0, 2): 2, (1, 1, 0): -1, (1, 0, 1): -1, (0, 1, 1): 3}
split = pmul(pmul(padd(x, neg(y)), padd(x, neg(z))), {k: 2 * v for k, v in Q.items()})
print("road 1, exact algebra on the plane section, over C")
print(f"F on P = 2 (x - y)(x - z)(x^2 + 2y^2 + 2z^2 - xy - xz + 3yz): {'yes' if split == F_on_P else 'no'}")
S = [[Fr(1), Fr(-1, 2), Fr(-1, 2)], [Fr(-1, 2), Fr(2), Fr(3, 2)], [Fr(-1, 2), Fr(3, 2), Fr(2)]]
det = (S[0][0] * (S[1][1] * S[2][2] - S[1][2] * S[2][1]) - S[0][1] * (S[1][0] * S[2][2] - S[1][2] * S[2][0])
       + S[0][2] * (S[1][0] * S[2][1] - S[1][1] * S[2][0]))
print(f"conic matrix determinant {det}, leading minors 1, {S[0][0] * S[1][1] - S[0][1] ** 2}: smooth, no real points")

def meet(a, b, c):                # points of the binary quadratic a s^2 + b s t + c t^2 on P^1: over C, over R
    disc = b * b - 4 * a * c
    return (2 if disc != 0 else 1), (2 if disc > 0 else 1 if disc == 0 else 0), disc
def q_on(u, v):                   # q restricted to the line s u + t v of the plane, as (a, b, c)
    qf = lambda p: sum(S[i][j] * p[i] * p[j] for i in range(3) for j in range(3))
    bil = sum(S[i][j] * u[i] * v[j] for i in range(3) for j in range(3))
    return qf(u), 2 * bil, qf(v)
rows = [("C . L", (1, 1, 0), (0, 0, 1)), ("C . M", (1, 0, 1), (0, 1, 0)), ("C . h (plane x = 0)", (0, 1, 0), (0, 0, 1))]
num = {}
for name, u, v in rows:
    nC, nR, disc = meet(*q_on(u, v))
    num[name] = (nC, nR); print(f"{name}: discriminant {disc}; {nC} points over C, {nR} over R")
def rank(m):                      # rank of a matrix, by exact elimination over Q
    m = [list(map(Fr, r)) for r in m]; rk = 0
    for c in range(len(m[0])):
        piv = next((i for i in range(rk, len(m)) if m[i][c] != 0), None)
        if piv is None: continue
        m[rk], m[piv] = m[piv], m[rk]
        for i in range(len(m)):
            if i != rk and m[i][c] != 0: m[i] = [x - m[i][c] / m[rk][c] * y for x, y in zip(m[i], m[rk])]
        rk += 1
    return rk
lin = [[1, -1, 0, 0], [0, 0, 1, -1], [1, 0, -1, 0], [0, 1, 0, -1]]   # L: x = y, z = w; M: x = z, y = w
pt = (1, 1, 1, 1)
print(f"L . M: (1 : 1 : 1 : 1) on both: {'yes' if all(sum(a * b for a, b in zip(r, pt)) == 0 for r in lin) else 'no'}; "
      f"q there = {sum(S[i][j] for i in range(3) for j in range(3))}, so C misses it")
CL, CM, CH = num["C . L"][0], num["C . M"][0], num["C . h (plane x = 0)"][0]
LM, LH, MH = [int(rank(r) == 3) for r in (lin, lin[:2] + [[1, 0, 0, 0]], lin[2:] + [[1, 0, 0, 0]])]  # 3 independent planes: 1 point
CC, LL, MM = CH - CL - CM, LH - CL - LM, MH - CM - LM    # h = C + L + M, paired with C, L and M
G = [[CC, CL, CM], [CL, LL, LM], [CM, LM, MM]]
hh = CH + LH + MH
print(f"self-intersections from h = C + L + M: C.C = {CC}, L.L = {LL}, M.M = {MM}; adjunction 2g - 2 = -2")
ft = [-1, 0, 0, 0, 1]; dft = [(4 - k) * c for k, c in enumerate(ft[:-1])]   # X on x = y = 0 at w = 1 (w = 0 forces z = 0): 1 - t^4; dft = ft'
npts = 4 - (7 - rank([[0] * i + ft + [0] * (2 - i) for i in range(3)] + [[0] * i + dft + [0] * (3 - i) for i in range(4)]))  # 4 - deg gcd(ft, ft')
print(f"h.h = {CH} + {LH} + {MH} = {hh}; line x = y = 0 meets X where z^4 = w^4: {npts} points")
eu = 4 ** 3 - 4 * 4 ** 2 + 6 * 4                         # Euler number of a smooth quartic surface (quoted formula)
print(f"Euler number {eu}, so H^2 has rank {eu - 2}; h^(2,0) = h^(0,2) = 1, so type (1,1) has dimension {eu - 4}")
def pair(a, b): return sum(a[i] * G[i][j] * b[j] for i in range(3) for j in range(3))
def cycle(n, m):                                       # n C + m L
    W = (n, m, 0); return pair(W, (1, 1, 1)), pair(W, W), pair(W, (0, 0, 1))
for n, m in [(1, 1), (3, -2)]:
    d, s, wm = cycle(n, m); print(f"W = {n} C {'+' if m > 0 else '-'} {abs(m)} L: degree W.h = {d}, W.W = {s}, W.M = {wm}")
print(f"[C + L] = h - [M]: pairs with C, L, M as {[pair((1, 1, 0), e) for e in ((1, 0, 0), (0, 1, 0), (0, 0, 1))]} "
      f"and h - M as {[CH - CM, LH - LM, MH - MM]}")

print("road 2, the class read by integrating forms (Simpson's rule)")
om = cmath.exp(2j * math.pi / 3)
p0 = (om, om, 1)                                       # a point of C, where C meets L
def Bf(u, v): return sum(float(S[i][j]) * u[i] * v[j] for i in range(3) for j in range(3))
def curve_C(t):                   # second point of C on the line from p0 towards d = (1, t, 0)
    d, dd = (1, t, 0), (0, 1, 0)
    qd, b = Bf(d, d), Bf(p0, d)
    qd1, b1 = 2 * Bf(d, dd), Bf(p0, dd)
    ph = [qd * p0[i] - 2 * b * d[i] for i in range(3)]
    dph = [qd1 * p0[i] - 2 * b1 * d[i] - 2 * b * dd[i] for i in range(3)]
    return ph + [ph[1] + ph[2] - ph[0]], dph + [dph[1] + dph[2] - dph[0]]
curve_L = lambda t: ([1, 1, t, t], [0, 0, 1, 1])
def fs_area(curve, n=400):        # integral of the hyperplane form h over the curve; a line gives 1
    def dens(t):
        ph, dph = curve(t)
        a = sum(abs(c) ** 2 for c in ph); b = sum(abs(c) ** 2 for c in dph)
        cr = sum(complex(c).conjugate() * e for c, e in zip(ph, dph))
        return (a * b - abs(cr) ** 2) / (math.pi * a * a)
    tot = 0.0
    for i in range(n + 1):        # t = tan(alpha) e^(i theta): Simpson in alpha, trapezium in theta
        al = (math.pi / 2) * i / n; wa = 1 if i in (0, n) else (4 if i % 2 else 2)
        if i == n: continue
        r = math.tan(al); jac = r / math.cos(al) ** 2
        ring = sum(dens(r * cmath.exp(2j * math.pi * k / n)) for k in range(n)) * (2 * math.pi / n)
        tot += wa * ring * jac
    return tot * (math.pi / 2) / n / 3
aC, aL = fs_area(curve_C), fs_area(curve_L)
print(f"integral of h over C {aC:.6f}, over L {aL:.6f}, over W = C + L {aC + aL:.6f}")

print("road 3, the type test")
def gs(c):                        # a Gaussian number with rational parts, printed exactly
    re, im = Fr(c.real), Fr(c.imag)
    if im == 0: return str(re)
    t = "i" if im == 1 else "-i" if im == -1 else f"{im}i"
    return t if re == 0 else f"{re} {'+' if im > 0 else '-'} {t.lstrip('-')}"
def sigma(u, v): return (u[0] * v[1] - u[1] * v[0]) / -4  # dx dy / (dF/dz) at (1, 1, 1), chart w = 1
u, v = (1, 1, 0), (1, 0, 1)                            # tangent to L and to M; together, X's real points
iu, iv = tuple(1j * c for c in u), tuple(1j * c for c in v)
print(f"sigma on L's tangent (u, iu): {gs(sigma(u, iu))}; on M's (v, iv): {gs(sigma(v, iv))}; on the real plane (u, v): {gs(sigma(u, v))}")
def plk(a, b): return tuple(a[i] * b[j] - a[j] * b[i] for i in range(4) for j in range(i + 1, 4))
def dz12(p): return complex(p[1] - p[4], p[2] + p[3])  # dz1 dz2 on the class; basis (1,0), (i,0), (0,1), (0,i)
tor = [("E x 0", (1, 0, 0, 0), (0, 1, 0, 0)), ("0 x E", (0, 0, 1, 0), (0, 0, 0, 1)), ("diagonal", (1, 0, 1, 0), (0, 1, 0, 1)),
       ("graph of i", (1, 0, 0, 1), (0, 1, -1, 0)), ("real torus (1,0), (0,i)", (1, 0, 0, 0), (0, 0, 0, 1))]
cls = []
for name, a, b in tor:
    p = plk(a, b); cls.append(p); print(f"E x E, {name}: class {p}, dz1 dz2 gives {gs(dz12(p))}")
tests = [[0, 1, 0, 0, -1, 0], [0, 0, 1, 1, 0, 0]]     # p13 - p24 = 0, p14 + p23 = 0: the type (1, 1) classes
print(f"rank of the four curve classes {rank(cls[:4])}; rank of all type (1,1) classes 6 - {rank(tests)} = {6 - rank(tests)}")
wC = CH - num["C . L"][1] - num["C . M"][1]
print(f"mistake 1, C . L and C . M over R: {num['C . L'][1]} and {num['C . M'][1]}, so C.C = {CH} - 0 - 0 = {wC}")
print(f"mistake 2, L.L = +1 as in the plane: L.h = {CL + 1 + LM}, but L meets a plane in {LH} point")
print(f"mistake 3, the real torus as a cycle: dz1 dz2 gives {gs(dz12(cls[4]))}, not 0")
assert split == F_on_P and det == Fr(3, 2)                         # the section really is L + M + C
assert (CL, CM, CH) == (2, 2, 2) and num["C . L"][1] == 0         # counts over C against over R
assert (CC, LL, MM) == (-2, -2, -2) and hh == npts                  # linearity against adjunction and a line's points
assert cycle(1, 1)[1] == hh - 2 * MH + MM == 0 and cycle(1, 1)[0] == round(aC + aL) == 3  # [W] = h - [M]
assert abs(aC - CH) < 1e-6 and abs(aL - LH) < 1e-6                  # analysis against counting
assert all(sum(a * b for a, b in zip(r, s + (0,))) == 0 for r, s in zip(lin, (u, u, v, v)))   # u lies along L, v along M
assert sigma(u, iu) == 0 and sigma(v, iv) == 0 and sigma(u, v) != 0
assert all(dz12(p) == 0 for p in cls[:4]) and dz12(cls[4]) != 0
assert rank(cls[:4]) == 6 - rank(tests) == 4
print("ALL CHECKS PASS")
```

**Ran 2026-11-17 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
road 1, exact algebra on the plane section, over C
F on P = 2 (x - y)(x - z)(x^2 + 2y^2 + 2z^2 - xy - xz + 3yz): yes
conic matrix determinant 3/2, leading minors 1, 7/4: smooth, no real points
C . L: discriminant -12; 2 points over C, 0 over R
C . M: discriminant -12; 2 points over C, 0 over R
C . h (plane x = 0): discriminant -7; 2 points over C, 0 over R
L . M: (1 : 1 : 1 : 1) on both: yes; q there = 6, so C misses it
self-intersections from h = C + L + M: C.C = -2, L.L = -2, M.M = -2; adjunction 2g - 2 = -2
h.h = 2 + 1 + 1 = 4; line x = y = 0 meets X where z^4 = w^4: 4 points
Euler number 24, so H^2 has rank 22; h^(2,0) = h^(0,2) = 1, so type (1,1) has dimension 20
W = 1 C + 1 L: degree W.h = 3, W.W = 0, W.M = 3
W = 3 C - 2 L: degree W.h = 4, W.W = -50, W.M = 4
[C + L] = h - [M]: pairs with C, L, M as [0, 0, 3] and h - M as [0, 0, 3]
road 2, the class read by integrating forms (Simpson's rule)
integral of h over C 2.000000, over L 1.000000, over W = C + L 3.000000
road 3, the type test
sigma on L's tangent (u, iu): 0; on M's (v, iv): 0; on the real plane (u, v): 1/4
E x E, E x 0: class (1, 0, 0, 0, 0, 0), dz1 dz2 gives 0
E x E, 0 x E: class (0, 0, 0, 0, 0, 1), dz1 dz2 gives 0
E x E, diagonal: class (1, 0, 1, -1, 0, 1), dz1 dz2 gives 0
E x E, graph of i: class (1, -1, 0, 0, -1, 1), dz1 dz2 gives 0
E x E, real torus (1,0), (0,i): class (0, 0, 1, 0, 0, 0), dz1 dz2 gives i
rank of the four curve classes 4; rank of all type (1,1) classes 6 - 2 = 4
mistake 1, C . L and C . M over R: 0 and 0, so C.C = 2 - 0 - 0 = 2
mistake 2, L.L = +1 as in the plane: L.h = 4, but L meets a plane in 1 point
mistake 3, the real torus as a cycle: dz1 dz2 gives i, not 0
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Algebraic cycles and cycle classes: the check behind the card.  Rust std only.
// X: x^4 - y^4 - z^4 + w^4 = 0, a smooth quartic surface over C.  The plane P: x - y - z + w = 0
// cuts X in a line L (x = y, z = w), a line M (x = z, y = w) and a conic C.  The cycle is W = C + L.
use std::collections::BTreeMap;
use std::f64::consts::PI;
type Poly = BTreeMap<[u32; 3], i64>;

fn pmul(p: &Poly, q: &Poly) -> Poly {
    let mut r = Poly::new();
    for (a, c) in p { for (b, d) in q { *r.entry([a[0] + b[0], a[1] + b[1], a[2] + b[2]]).or_insert(0) += c * d; } }
    r.retain(|_, v| *v != 0); r
}
fn padd(ps: &[&Poly]) -> Poly {
    let mut r = Poly::new();
    for p in ps { for (k, v) in *p { *r.entry(*k).or_insert(0) += v; } }
    r.retain(|_, v| *v != 0); r
}
fn ppow(p: &Poly, n: u32) -> Poly { let mut r = Poly::from([([0, 0, 0], 1)]); for _ in 0..n { r = pmul(&r, p); } r }
fn neg(p: &Poly) -> Poly { p.iter().map(|(k, v)| (*k, -v)).collect() }

#[derive(Clone, Copy, PartialEq)]
struct Fr { n: i128, d: i128 }             // a fraction in lowest terms, d > 0; overflow stops the run
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn fr(n: i128, d: i128) -> Fr { let g = gcd(n, d).max(1) * d.signum(); Fr { n: n / g, d: d / g } }
fn fm(a: Fr, b: Fr) -> Fr { fr(a.n.checked_mul(b.n).unwrap(), a.d.checked_mul(b.d).unwrap()) }
fn fa(a: Fr, b: Fr) -> Fr { fr(a.n.checked_mul(b.d).unwrap() + b.n.checked_mul(a.d).unwrap(), a.d.checked_mul(b.d).unwrap()) }
fn fs(a: Fr, b: Fr) -> Fr { fa(a, fr(-b.n, b.d)) } fn fstr(a: Fr) -> String { if a.d == 1 { format!("{}", a.n) } else { format!("{}/{}", a.n, a.d) } }
fn gs(re: Fr, im: Fr) -> String {           // a Gaussian number with rational parts, printed exactly
    if im.n == 0 { return fstr(re); }
    let t = if im == fr(1, 1) { "i".to_string() } else if im == fr(-1, 1) { "-i".to_string() } else { format!("{}i", fstr(im)) };
    if re.n == 0 { t } else { format!("{} {} {}", fstr(re), if im.n > 0 { "+" } else { "-" }, t.trim_start_matches('-')) }
}

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64) -> C { C { re, im: 0.0 } }
fn cadd(a: C, b: C) -> C { C { re: a.re + b.re, im: a.im + b.im } } fn csub(a: C, b: C) -> C { C { re: a.re - b.re, im: a.im - b.im } }
fn cmul(a: C, b: C) -> C { C { re: a.re * b.re - a.im * b.im, im: a.re * b.im + a.im * b.re } }
fn cis(t: f64) -> C { C { re: t.cos(), im: t.sin() } } fn abs2(a: C) -> f64 { a.re * a.re + a.im * a.im }

fn rank(m: &Vec<Vec<i64>>) -> usize {
    let mut m: Vec<Vec<Fr>> = m.iter().map(|r| r.iter().map(|&x| fr(x as i128, 1)).collect()).collect();
    let mut rk = 0;
    for col in 0..m[0].len() {
        let piv = match (rk..m.len()).find(|&i| m[i][col].n != 0) { Some(p) => p, None => continue };
        m.swap(rk, piv);
        for i in 0..m.len() {
            if i != rk && m[i][col].n != 0 {
                let f = fm(m[i][col], fr(m[rk][col].d, m[rk][col].n));
                let row = m[rk].clone(); for j in 0..row.len() { m[i][j] = fs(m[i][j], fm(f, row[j])); }
            }
        }
        rk += 1; }
    rk }

fn main() {
    let (x, y, z) = (Poly::from([([1, 0, 0], 1)]), Poly::from([([0, 1, 0], 1)]), Poly::from([([0, 0, 1], 1)]));
    let w = padd(&[&neg(&x), &y, &z]);                         // on P, w = -x + y + z
    let f_on_p = padd(&[&ppow(&x, 4), &neg(&ppow(&y, 4)), &neg(&ppow(&z, 4)), &ppow(&w, 4)]);
    let q2 = Poly::from([([2, 0, 0], 2), ([0, 2, 0], 4), ([0, 0, 2], 4), ([1, 1, 0], -2), ([1, 0, 1], -2), ([0, 1, 1], 6)]);
    let split = pmul(&pmul(&padd(&[&x, &neg(&y)]), &padd(&[&x, &neg(&z)])), &q2);
    println!("road 1, exact algebra on the plane section, over C");
    println!("F on P = 2 (x - y)(x - z)(x^2 + 2y^2 + 2z^2 - xy - xz + 3yz): {}", if split == f_on_p { "yes" } else { "no" });
    let s = [[fr(1, 1), fr(-1, 2), fr(-1, 2)], [fr(-1, 2), fr(2, 1), fr(3, 2)], [fr(-1, 2), fr(3, 2), fr(2, 1)]];
    let m2 = |a: usize, b: usize, cc: usize, d: usize| fs(fm(s[1][a], s[2][b]), fm(s[1][cc], s[2][d]));
    let det = fa(fs(fm(s[0][0], m2(1, 2, 2, 1)), fm(s[0][1], m2(0, 2, 2, 0))), fm(s[0][2], m2(0, 1, 1, 0)));
    println!("conic matrix determinant {}, leading minors 1, {}: smooth, no real points", fstr(det), fstr(fs(fm(s[0][0], s[1][1]), fm(s[0][1], s[0][1]))));
    let qf = |u: [i128; 3], v: [i128; 3]| { let mut t = fr(0, 1);
        for i in 0..3 { for j in 0..3 { t = fa(t, fm(s[i][j], fr(u[i] * v[j], 1))); } } t };
    let rows = [("C . L", [1, 1, 0], [0, 0, 1]), ("C . M", [1, 0, 1], [0, 1, 0]), ("C . h (plane x = 0)", [0, 1, 0], [0, 0, 1])];
    let mut num = vec![];
    for (name, u, v) in rows {
        let (a, b, cc) = (qf(u, u), fm(fr(2, 1), qf(u, v)), qf(v, v));
        let disc = fs(fm(b, b), fm(fr(4, 1), fm(a, cc)));
        let n_c = if disc.n != 0 { 2 } else { 1 };
        let n_r = if disc.n > 0 { 2 } else if disc.n == 0 { 1 } else { 0 };
        num.push((n_c, n_r)); println!("{}: discriminant {}; {} points over C, {} over R", name, fstr(disc), n_c, n_r);
    }
    let lin = [[1, -1, 0, 0], [0, 0, 1, -1], [1, 0, -1, 0], [0, 1, 0, -1]];   // L: x = y, z = w; M: x = z, y = w
    let on = lin.iter().all(|r| r.iter().sum::<i64>() == 0);
    println!("L . M: (1 : 1 : 1 : 1) on both: {}; q there = {}, so C misses it", if on { "yes" } else { "no" }, fstr(qf([1, 1, 1], [1, 1, 1])));
    let (cl, cm, ch) = (num[0].0, num[1].0, num[2].0);
    let rk3 = |m: Vec<Vec<i64>>| (rank(&m) == 3) as i64;      // 3 independent planes: 1 point
    let (lm, lh, mh) = (rk3(lin.iter().map(|r| r.to_vec()).collect()), rk3(vec![lin[0].to_vec(), lin[1].to_vec(), vec![1, 0, 0, 0]]), rk3(vec![lin[2].to_vec(), lin[3].to_vec(), vec![1, 0, 0, 0]]));
    let (ccs, ll, mm) = (ch - cl - cm, lh - cl - lm, mh - cm - lm);  // h = C + L + M, paired with C, L and M
    let (g, hh) = ([[ccs, cl, cm], [cl, ll, lm], [cm, lm, mm]], ch + lh + mh);
    println!("self-intersections from h = C + L + M: C.C = {}, L.L = {}, M.M = {}; adjunction 2g - 2 = -2", ccs, ll, mm);
    let ft = [-1i64, 0, 0, 0, 1]; let dft: Vec<i64> = (0..4).map(|k| (4 - k as i64) * ft[k]).collect();   // X on x = y = 0 at w = 1 (w = 0 forces z = 0): 1 - t^4; dft = ft'
    let npts = 4 - (7 - rank(&(0..3).map(|i| [vec![0; i], ft.to_vec(), vec![0; 2 - i]].concat()).chain((0..4).map(|i| [vec![0; i], dft.clone(), vec![0; 3 - i]].concat())).collect()) as i64);  // 4 - deg gcd(ft, ft')
    println!("h.h = {} + {} + {} = {}; line x = y = 0 meets X where z^4 = w^4: {} points", ch, lh, mh, hh, npts);
    let eu = 4i64.pow(3) - 4 * 4i64.pow(2) + 6 * 4;              // Euler number of a smooth quartic surface (quoted formula)
    println!("Euler number {}, so H^2 has rank {}; h^(2,0) = h^(0,2) = 1, so type (1,1) has dimension {}", eu, eu - 2, eu - 4);
    let pair = |a: [i64; 3], b: [i64; 3]| { let mut t = 0; for i in 0..3 { for j in 0..3 { t += a[i] * g[i][j] * b[j]; } } t };
    let cycle = |n: i64, m: i64| { let wv = [n, m, 0]; (pair(wv, [1, 1, 1]), pair(wv, wv), pair(wv, [0, 0, 1])) };
    for (n, m) in [(1, 1), (3, -2)] {
        let (d, sq, wm) = cycle(n, m); println!("W = {} C {} {} L: degree W.h = {}, W.W = {}, W.M = {}", n, if m > 0 { "+" } else { "-" }, m.abs(), d, sq, wm);
    }
    let pc: Vec<i64> = [[1, 0, 0], [0, 1, 0], [0, 0, 1]].iter().map(|e| pair([1, 1, 0], *e)).collect();
    println!("[C + L] = h - [M]: pairs with C, L, M as {:?} and h - M as {:?}", pc, [ch - cm, lh - lm, mh - mm]);
    println!("road 2, the class read by integrating forms (Simpson's rule)");
    let sf: Vec<Vec<f64>> = s.iter().map(|r| r.iter().map(|a| a.n as f64 / a.d as f64).collect()).collect();
    let bf = |u: [C; 3], v: [C; 3]| { let mut t = c(0.0);
        for i in 0..3 { for j in 0..3 { t = cadd(t, cmul(c(sf[i][j]), cmul(u[i], v[j]))); } } t };
    let om = cis(2.0 * PI / 3.0);
    let p0 = [om, om, c(1.0)];                                 // a point of C, where C meets L
    let curve_c = |t: C| -> ([C; 4], [C; 4]) {                 // second point of C on the line from p0 towards d = (1, t, 0)
        let (d, dd) = ([c(1.0), t, c(0.0)], [c(0.0), c(1.0), c(0.0)]);
        let (qd, b) = (bf(d, d), bf(p0, d));
        let (qd1, b1) = (cmul(c(2.0), bf(d, dd)), bf(p0, dd));
        let mut ph = [c(0.0); 4]; let mut dph = [c(0.0); 4];
        for i in 0..3 {
            ph[i] = csub(cmul(qd, p0[i]), cmul(cmul(c(2.0), b), d[i]));
            dph[i] = csub(csub(cmul(qd1, p0[i]), cmul(cmul(c(2.0), b1), d[i])), cmul(cmul(c(2.0), b), dd[i]));
        }
        ph[3] = csub(cadd(ph[1], ph[2]), ph[0]); dph[3] = csub(cadd(dph[1], dph[2]), dph[0]); (ph, dph) };
    let curve_l = |t: C| -> ([C; 4], [C; 4]) { ([c(1.0), c(1.0), t, t], [c(0.0), c(0.0), c(1.0), c(1.0)]) };
    fn fs_area(curve: &dyn Fn(C) -> ([C; 4], [C; 4]), n: usize) -> f64 {   // integral of h over the curve; a line gives 1
        let dens = |t: C| { let (ph, dph) = curve(t);
            let a: f64 = ph.iter().map(|z| abs2(*z)).sum(); let b: f64 = dph.iter().map(|z| abs2(*z)).sum();
            let mut cr = c(0.0); for k in 0..4 { cr = cadd(cr, cmul(C { re: ph[k].re, im: -ph[k].im }, dph[k])); }
            (a * b - abs2(cr)) / (PI * a * a) };
        let mut tot = 0.0;
        for i in 0..n {                                        // t = tan(alpha) e^(i theta): Simpson in alpha, trapezium in theta
            let al = (PI / 2.0) * i as f64 / n as f64;
            let wa = if i == 0 { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
            let r = al.tan(); let jac = r / al.cos().powi(2);
            let mut ring = 0.0;
            for k in 0..n { let e = cis(2.0 * PI * k as f64 / n as f64); ring += dens(C { re: r * e.re, im: r * e.im }); }
            tot += wa * (ring * (2.0 * PI / n as f64)) * jac;
        }
        tot * (PI / 2.0) / n as f64 / 3.0
    }
    let (a_c, a_l) = (fs_area(&curve_c, 400), fs_area(&curve_l, 400));
    println!("integral of h over C {:.6}, over L {:.6}, over W = C + L {:.6}", a_c, a_l, a_c + a_l);
    println!("road 3, the type test");
    // sigma = dx dy / (dF/dz) at (1, 1, 1), chart w = 1; vectors are Gaussian integers (re, im)
    let sigma = |u: [(i128, i128); 3], v: [(i128, i128); 3]| {
        let gm = |a: (i128, i128), b: (i128, i128)| (a.0 * b.0 - a.1 * b.1, a.0 * b.1 + a.1 * b.0);
        let (p, q) = (gm(u[0], v[1]), gm(u[1], v[0]));
        gs(fr(p.0 - q.0, -4), fr(p.1 - q.1, -4)) };
    let (u, v) = ([(1, 0), (1, 0), (0, 0)], [(1, 0), (0, 0), (1, 0)]);   // tangent to L and to M; together, X's real points
    let (iu, iv) = (u.map(|a: (i128, i128)| (-a.1, a.0)), v.map(|a: (i128, i128)| (-a.1, a.0)));   // i times each vector
    println!("sigma on L's tangent (u, iu): {}; on M's (v, iv): {}; on the real plane (u, v): {}", sigma(u, iu), sigma(v, iv), sigma(u, v));
    let plk = |a: [i64; 4], b: [i64; 4]| { let mut p = vec![];
        for i in 0..4 { for j in i + 1..4 { p.push(a[i] * b[j] - a[j] * b[i]); } } p };
    let dz12 = |p: &Vec<i64>| (p[1] - p[4], p[2] + p[3]);    // dz1 dz2 on the class; basis (1,0), (i,0), (0,1), (0,i)
    let tor = [("E x 0", [1, 0, 0, 0], [0, 1, 0, 0]), ("0 x E", [0, 0, 1, 0], [0, 0, 0, 1]), ("diagonal", [1, 0, 1, 0], [0, 1, 0, 1]),
               ("graph of i", [1, 0, 0, 1], [0, 1, -1, 0]), ("real torus (1,0), (0,i)", [1, 0, 0, 0], [0, 0, 0, 1])];
    let gz = |t: (i64, i64)| gs(fr(t.0 as i128, 1), fr(t.1 as i128, 1));
    let mut cls = vec![];
    for (name, a, b) in tor {
        let p = plk(a, b); println!("E x E, {}: class ({}), dz1 dz2 gives {}", name, p.iter().map(|v| v.to_string()).collect::<Vec<_>>().join(", "), gz(dz12(&p)));
        cls.push(p); }
    let tests = vec![vec![0, 1, 0, 0, -1, 0], vec![0, 0, 1, 1, 0, 0]];   // p13 - p24 = 0, p14 + p23 = 0: the type (1, 1) classes
    let rc = rank(&cls[..4].to_vec());
    println!("rank of the four curve classes {}; rank of all type (1,1) classes 6 - {} = {}", rc, rank(&tests), 6 - rank(&tests));
    println!("mistake 1, C . L and C . M over R: {} and {}, so C.C = {} - 0 - 0 = {}", num[0].1, num[1].1, ch, ch - num[0].1 - num[1].1);
    println!("mistake 2, L.L = +1 as in the plane: L.h = {}, but L meets a plane in {} point", cl + 1 + lm, lh);
    println!("mistake 3, the real torus as a cycle: dz1 dz2 gives {}, not 0", gz(dz12(&cls[4])));
    assert!(split == f_on_p && det == fr(3, 2));                       // the section really is L + M + C
    assert!((cl, cm, ch) == (2, 2, 2) && num[0].1 == 0);              // counts over C against over R
    assert!((ccs, ll, mm) == (-2, -2, -2) && hh == npts);              // linearity against adjunction and a line's points
    assert!(cycle(1, 1).1 == hh - 2 * mh + mm && hh - 2 * mh + mm == 0 && cycle(1, 1).0 == (a_c + a_l).round() as i64 && cycle(1, 1).0 == 3);  // [W] = h - [M]
    assert!((a_c - ch as f64).abs() < 1e-6 && (a_l - lh as f64).abs() < 1e-6);   // analysis against counting
    assert!((0..4).all(|k| { let s = if k < 2 { u } else { v }; (0..3).map(|j| lin[k][j] * s[j].0 as i64).sum::<i64>() == 0 }));  // u lies along L, v along M
    assert!(sigma(u, iu) == "0" && sigma(v, iv) == "0" && sigma(u, v) != "0");
    assert!(cls[..4].iter().all(|p| dz12(p) == (0, 0)) && dz12(&cls[4]) != (0, 0));
    assert!(rc == 6 - rank(&tests) && rc == 4);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-17 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
road 1, exact algebra on the plane section, over C
F on P = 2 (x - y)(x - z)(x^2 + 2y^2 + 2z^2 - xy - xz + 3yz): yes
conic matrix determinant 3/2, leading minors 1, 7/4: smooth, no real points
C . L: discriminant -12; 2 points over C, 0 over R
C . M: discriminant -12; 2 points over C, 0 over R
C . h (plane x = 0): discriminant -7; 2 points over C, 0 over R
L . M: (1 : 1 : 1 : 1) on both: yes; q there = 6, so C misses it
self-intersections from h = C + L + M: C.C = -2, L.L = -2, M.M = -2; adjunction 2g - 2 = -2
h.h = 2 + 1 + 1 = 4; line x = y = 0 meets X where z^4 = w^4: 4 points
Euler number 24, so H^2 has rank 22; h^(2,0) = h^(0,2) = 1, so type (1,1) has dimension 20
W = 1 C + 1 L: degree W.h = 3, W.W = 0, W.M = 3
W = 3 C - 2 L: degree W.h = 4, W.W = -50, W.M = 4
[C + L] = h - [M]: pairs with C, L, M as [0, 0, 3] and h - M as [0, 0, 3]
road 2, the class read by integrating forms (Simpson's rule)
integral of h over C 2.000000, over L 1.000000, over W = C + L 3.000000
road 3, the type test
sigma on L's tangent (u, iu): 0; on M's (v, iv): 0; on the real plane (u, v): 1/4
E x E, E x 0: class (1, 0, 0, 0, 0, 0), dz1 dz2 gives 0
E x E, 0 x E: class (0, 0, 0, 0, 0, 1), dz1 dz2 gives 0
E x E, diagonal: class (1, 0, 1, -1, 0, 1), dz1 dz2 gives 0
E x E, graph of i: class (1, -1, 0, 0, -1, 1), dz1 dz2 gives 0
E x E, real torus (1,0), (0,i): class (0, 0, 1, 0, 0, 0), dz1 dz2 gives i
rank of the four curve classes 4; rank of all type (1,1) classes 6 - 2 = 4
mistake 1, C . L and C . M over R: 0 and 0, so C.C = 2 - 0 - 0 = 2
mistake 2, L.L = +1 as in the plane: L.h = 4, but L meets a plane in 1 point
mistake 3, the real torus as a cycle: dz1 dz2 gives i, not 0
ALL CHECKS PASS
```

### Lean

Lean proves Step 2's test on a curve's tangent line, the slice's factoring, the $`E \times E`$ formula, and the card's hand arithmetic.

- Suppose two vectors lie in one complex line, such as a curve's tangent pair u and iu. Then every (2, 0)-form gives 0 on them.
- Take the plane P, where $`w = -x + y + z`$. Then $`F = 2(x - y)(x - z) q`$ on P, so the slice is $`C + L + M`$.
- Take any two real vectors s and t, written in the basis $`e_1, \dots, e_4`$. Then $`dz_1 \wedge dz_2`$ on them is $`(p_{13} - p_{24}) + i (p_{14} + p_{23})`$.
- The conic's matrix has determinant 3/2, and its leading minors are 1, 7/4 and 3/2.
- The discriminants −12 and −7 in Step 3 check. At (1 : 1 : 1 : 1), q = 6.
- The self-intersections $`C \cdot C`$, $`L \cdot L`$ and $`M \cdot M`$ are all −2, and $`h \cdot h = 4`$.
- From the intersection table, $`W = C + L`$ has $`W \cdot h = 3`$, $`W \cdot W = 0`$ and $`W \cdot M = 3`$. For $`3C - 2L`$ these are 4, −50 and 4.
- The square of $`h - [M]`$ is $`4 - 2 - 2 = 0`$.
- The rank arithmetic checks: 24 − 2 = 22 for $`H^2`$, and 24 − 4 = 20 for type (1, 1).
- On $`E \times E`$, $`dz_1 \wedge dz_2`$ gives 0 on the four curves and i on the real torus.

Meeting points from discriminants, the Simpson integrals, σ at (1 : 1 : 1 : 1) and the lattice ranks are left to the Python and Rust checks.

```lean
-- Algebraic cycles: a holomorphic 2-form vanishes on every complex line, so a complex curve sees only type (1, 1), and the card's slice, intersection and torus numbers check exactly.
import Mathlib.LinearAlgebra.Alternating.Basic
import Mathlib.LinearAlgebra.Dimension.Finrank
import Mathlib.LinearAlgebra.Dimension.FreeAndStrongRankCondition
import Mathlib.LinearAlgebra.LinearIndependent.Lemmas
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Basic.Complex.Basic
import Mathlib.Tactic

open Complex Matrix

/-- A complex piece sees only type (p, p), in the card's case of a curve: a (2, 0)-form, that is a
complex-bilinear alternating form, gives 0 on every pair of vectors in a complex line, such as the
tangent pair (u, iu) of a complex curve. -/
theorem two_zero_form_vanishes_on_complex_line {V : Type*} [AddCommGroup V] [Module ℂ V]
    (σ : V [⋀^Fin 2]→ₗ[ℂ] ℂ) (S : Submodule ℂ V) (hS : Module.finrank ℂ S = 1)
    (x y : V) (hx : x ∈ S) (hy : y ∈ S) :
    σ ![x, y] = 0 := by
  obtain ⟨v, -, hv⟩ := (finrank_eq_one_iff' (K := ℂ) (V := S)).mp hS
  obtain ⟨a, ha⟩ := hv ⟨x, hx⟩
  obtain ⟨b, hb⟩ := hv ⟨y, hy⟩
  have hx' : a • (v : V) = x := by
    have := congrArg Subtype.val ha; simpa using this
  have hy' : b • (v : V) = y := by
    have := congrArg Subtype.val hb; simpa using this
  apply σ.map_linearDependent
  intro hLI
  have h := LinearIndependent.pair_iff.mp hLI
  by_cases ha0 : a = 0
  · have hx0 : x = 0 := by rw [← hx', ha0, zero_smul]
    have := h 1 0 (by simp [hx0])
    exact one_ne_zero this.1
  · have := h b (-a) (by
      rw [← hx', ← hy', smul_smul, smul_smul, ← add_smul]; ring_nf; exact zero_smul _ _)
    exact ha0 (neg_eq_zero.mp this.2)

/-- The plane slice: putting w = -x + y + z into x^4 - y^4 - z^4 + w^4 gives
2 (x - y)(x - z) q with q = x^2 + 2y^2 + 2z^2 - xy - xz + 3yz, so the slice is L + M + C. -/
theorem quartic_plane_slice_factors {R : Type*} [CommRing R] (x y z : R) :
    x ^ 4 - y ^ 4 - z ^ 4 + (-x + y + z) ^ 4
      = 2 * (x - y) * (x - z) * (x ^ 2 + 2 * y ^ 2 + 2 * z ^ 2 - x * y - x * z + 3 * y * z) := by
  ring

/-- On E × E with lattice basis (1, 0), (i, 0), (0, 1), (0, i), the form dz1 ∧ dz2 on the real
2-torus spanned by s and t equals (p13 - p24) + i (p14 + p23), where p_jk = s_j t_k - s_k t_j
(indices 1 to 4 on the card, 0 to 3 here). -/
theorem dz1_wedge_dz2_on_torus_class (s t : Fin 4 → ℝ) :
    ((s 0 : ℂ) + s 1 * I) * ((t 2 : ℂ) + t 3 * I) - ((s 2 : ℂ) + s 3 * I) * ((t 0 : ℂ) + t 1 * I)
      = (((s 0 * t 2 - s 2 * t 0) - (s 1 * t 3 - s 3 * t 1) : ℝ) : ℂ)
        + (((s 0 * t 3 - s 3 * t 0) + (s 1 * t 2 - s 2 * t 1) : ℝ) : ℂ) * I := by
  push_cast
  ring_nf
  rw [I_sq]
  ring

-- The conic's matrix has determinant 3/2 and leading minors 1, 7/4, 3/2: smooth, no real points.
example : !![(1 : ℚ), -1/2, -1/2; -1/2, 2, 3/2; -1/2, 3/2, 2].det = 3/2 := by
  norm_num [Matrix.det_fin_three]
example : (1 : ℚ) * 2 - (-1/2) ^ 2 = 7/4 := by norm_num

-- Discriminants: q on x = y (and on x = z) is 2y^2 + 2yz + 2z^2; q on x = 0 is 2y^2 + 3yz + 2z^2.
example : (2 : ℤ) ^ 2 - 4 * 2 * 2 = -12 := by norm_num
example : (3 : ℤ) ^ 2 - 4 * 2 * 2 = -7 := by norm_num
-- q at (1 : 1 : 1), the point of L and M, is 6, so C misses it.
example : (1 : ℤ) ^ 2 + 2 * 1 ^ 2 + 2 * 1 ^ 2 - 1 * 1 - 1 * 1 + 3 * 1 * 1 = 6 := by norm_num

-- Self-intersections from h = C + L + M, and h . h = 4.
example : (2 : ℤ) - 2 - 2 = -2 ∧ (1 : ℤ) - 2 - 1 = -2 ∧ (2 : ℤ) + 1 + 1 = 4 := by norm_num

-- The intersection matrix of C, L, M, and the cycles C + L and 3C - 2L.
example :
    let G : Matrix (Fin 3) (Fin 3) ℤ := !![-2, 2, 2; 2, -2, 1; 2, 1, -2]
    let W : Fin 3 → ℤ := ![1, 1, 0]
    W ⬝ᵥ (G *ᵥ ![1, 1, 1]) = 3 ∧ W ⬝ᵥ (G *ᵥ W) = 0 ∧ W ⬝ᵥ (G *ᵥ ![0, 0, 1]) = 3 := by
  decide
example :
    let G : Matrix (Fin 3) (Fin 3) ℤ := !![-2, 2, 2; 2, -2, 1; 2, 1, -2]
    let W : Fin 3 → ℤ := ![3, -2, 0]
    W ⬝ᵥ (G *ᵥ ![1, 1, 1]) = 4 ∧ W ⬝ᵥ (G *ᵥ W) = -50 ∧ W ⬝ᵥ (G *ᵥ ![0, 0, 1]) = 4 := by
  decide
-- [h - M] squared: 4 - 2 * 1 - 2 = 0.
example : (4 : ℤ) - 2 * 1 + (-2) = 0 := by norm_num

-- Euler number 24 of a quartic surface, so H^2 has rank 22 and type (1, 1) dimension 20.
example : (4 : ℤ) ^ 3 - 4 * 4 ^ 2 + 6 * 4 = 24 ∧ (24 : ℤ) - 2 = 22 ∧ (24 : ℤ) - 4 = 20 := by norm_num

-- E × E: dz1 ∧ dz2 on the four curves gives 0, on the real torus spanned by (1, 0), (0, i) gives i.
example : (1 : ℂ) * 0 - 0 * I = 0 := by simp
example : (0 : ℂ) * I - 1 * 0 = 0 := by simp
example : (1 : ℂ) * I - 1 * I = 0 := by ring
example : (1 : ℂ) * (-1) - I * I = 0 := by ring_nf; simp
example : (1 : ℂ) * I - 0 * 0 = I := by simp

#print axioms two_zero_form_vanishes_on_complex_line
#print axioms quartic_plane_slice_factors
#print axioms dz1_wedge_dz2_on_torus_class
```

**Checked 2026-11-17 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'two_zero_form_vanishes_on_complex_line' depends on axioms: [propext, Classical.choice, Quot.sound]
'quartic_plane_slice_factors' depends on axioms: [propext, Quot.sound]
'dz1_wedge_dz2_on_torus_class' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> - Guess first: what degree and square does $`C - L`$ have? Change `(3, -2)` to `(1, -1)` in the list of weights. It prints degree 1, $`W \cdot W = -8`$ and $`W \cdot M = 1`$.
> - Guess first: is the real torus spanned by (1, 0) and (0, 1 + i) a cycle? Change its second vector `(0, 0, 0, 1)` to `(0, 0, 1, 1)`. $`dz_1 \wedge dz_2`$ gives 1 + i, so no.
> - Guess first: how few integration steps still give 2.000000 for C? Change `n=400` to `n=20`. C comes out at 2.000051 and the assert stops the run.

---

## The usual mistake

> [!warning]
> **Reading $`C \cdot C`$ as "the points C shares with itself".** C shares every point with itself, so that count is not even finite. The intersection number is a pairing of classes: move one copy to a cycle with the same class that meets C cleanly, then count. For the conic it is −2, a negative number that no point count can produce.
>
> - **Counting over the reals.** C has no real points, so a real count gives $`C \cdot L = 0`$ and $`C \cdot C = 2`$, not −2.
> - **Borrowing the plane's numbers.** A line in a plane meets itself once, but on X, $`L \cdot L = -2`$; using +1 gives $`L \cdot h = 4`$ instead of 1.
> - **Dropping the weights.** $`3C - 2L`$ is not the set $`C \cup L`$: its degree is 4, while $`C + L`$ has degree 3.
> - **Calling every surface in X a cycle.** The real torus in $`E \times E`$ gives i under $`dz_1 \wedge dz_2`$, so its class is not type (1, 1).

---

## Where you meet it in real life

- **Elliptic fibrations of K3 surfaces.** A class with square 0 that moves in a family, like $`[C + L]`$, sweeps its surface with genus-1 curves. Searching the lattice of curve classes for such classes is how these fibrations are found. String theory uses them to build models of extra dimensions.
- **Abelian varieties and their symmetries.** On $`E \times E`$ the graph of $`z \mapsto iz`$ is a curve whose class records the map. The rank of curve classes, 4 here, measures how many extra symmetries the torus has.
- **Error-correcting codes.** Algebraic-geometry codes are built from a divisor on a curve: points with whole-number weights, a cycle of codimension 1. Riemann-Roch turns the weights into the code's dimension: how many independent symbols each message carries.
- **Counting problems.** Enumerative geometry counts curves through given conditions by multiplying classes, then reads the answer as a number of points, over $`\mathbb{C}`$ and with multiplicity.

> **Say it back**
> An algebraic cycle is a list of subvarieties with whole-number weights, such as the conic plus the line on the quartic surface. Its class is the cohomology class that integrates each closed form over the pieces and adds with the weights. On a surface, classes of curves pair by intersection numbers; for $`C + L`$ the class is $`h - [M]`$, with degree 3 and square 0. A complex piece kills every form with unequal numbers of dz's and dz-bars, so every cycle class has type (p, p). A real torus in $`E \times E`$ fails that test, so no cycle has its class.

---

## What this builds on

- [Line bundles and divisors](06-line-bundles-and-divisor-classes.md): a divisor is a cycle of codimension 1, and its class is $`c_1`$ of its line bundle; this card extends classes to every codimension and adds the type test.
- [De Rham cohomology](02-de-rham-cohomology-of-varieties.md): closed forms modulo exact ones, the classes a cycle integrates.
- [Hodge decomposition](05-hodge-decomposition.md): the split into types $`H^{a,b}`$ that the class lands in.
- [Cohomology and the cup product in outline](../../17-Topology/05-Homology/08-cohomology-and-cup-product-in-outline.md): the product of classes behind $`A \cdot B`$.
- [Homology groups](../../17-Topology/05-Homology/02-homology-groups.md): every closed oriented shape has a whole-number homology class.

## Where this goes next

- [The Hodge conjecture](08-hodge-conjecture-statement-and-known-cases.md): the rational classes of type (p, p), their count ρ in degree 2, and the claim that cycles reach them all.
- Forms and integration on manifolds in full, in the differential geometry wing (planned): the wedge, Stokes' theorem and Poincaré duality proved.

Every cycle class is type (p, p) with whole-number coordinates; whether every rational class of type (p, p) comes from some cycle with rational weights is the open question.

---

## Sources

Verified 2026-11-17: every link below resolves to the publisher's page.

- Griffiths, Phillip, and Joseph Harris. *Principles of Algebraic Geometry*. Wiley, 1978; Wiley Classics Library, 1994. [DOI 10.1002/9781118032527](https://doi.org/10.1002/9781118032527). Integration over analytic subvarieties, the fundamental class, and the intersection pairing on a surface.
- Voisin, Claire. *Hodge Theory and Complex Algebraic Geometry I*. Cambridge University Press, 2002. [DOI 10.1017/CBO9780511615344](https://doi.org/10.1017/CBO9780511615344). The cycle class of a subvariety and the proof that it has type (p, p).
- Fulton, William. *Intersection Theory*, 2nd ed. Springer, 1998. [DOI 10.1007/978-1-4612-1700-8](https://doi.org/10.1007/978-1-4612-1700-8). Cycles, rational equivalence and the cycle map to cohomology.
- Huybrechts, Daniel. *Lectures on K3 Surfaces*. Cambridge University Press, 2016. [DOI 10.1017/CBO9781316594193](https://doi.org/10.1017/CBO9781316594193). Quartic surfaces as K3 surfaces, the −2 curves, elliptic fibrations and the lattice of curve classes.
- Birkenhake, Christina, and Herbert Lange. *Complex Abelian Varieties*, 2nd ed. Springer, 2004. [DOI 10.1007/978-3-662-06307-1](https://doi.org/10.1007/978-3-662-06307-1). Classes on complex tori by alternating forms, and the type (1, 1) condition on $`E \times E`$.
