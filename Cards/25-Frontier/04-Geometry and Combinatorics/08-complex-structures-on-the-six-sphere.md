# The six-sphere: does S^6 carry a true complex structure, and the 2026 claims that it does

[Syllabus](../../../SYLLABUS.md) → [Frontier](../README.md) → [Geometry and Combinatorics](../README.md#s04) → The six-sphere

---

## General Overview

The ordinary globe, $`S^2`$, is also the Riemann sphere: the complex plane with one point added at infinity. On it, "turn a small arrow a quarter turn to the left" is the same as "multiply it by $`i`$" (the square root of −1). Do the quarter turn twice and the arrow points backwards: $`i^2 = -1`$.

The **six-sphere** $`S^6`$ is the set of points at distance 1 from the centre in seven-dimensional space. It also has a quarter-turn rule, built from the **octonions** (an eight-dimensional number system with its own multiplication). At the point $`x = (2/7, 3/7, 6/7, 0, 0, 0, 0)`$, the rule turns the arrow $`v = (3, -2, 0, 1, 0, 0, 0)`$ into $`(3/7, -2/7, 0, -13/7, 12/7, 6/7, -18/7)`$. Turn that again and $`v`$ comes back reversed, $`(-3, 2, 0, -1, 0, 0, 0)`$, exactly.

A rule like that is an **almost complex structure**. A **complex structure** asks for more: coordinates made of complex numbers, near every point, whose own quarter turns are the rule. On $`S^2`$ such coordinates exist. On $`S^6`$, the octonion rule fails a test this card computes, and whether any other rule passes has been asked since Hopf's work in the late 1940s. It is often called the **Hopf problem**.

In 2026 a positive answer was claimed. By September 2026 a long manuscript, produced by an AI system under the direction of the mathematician Levent Alpöge, was circulating with a complex structure on $`S^6`$. Jeff Viaclovsky posted a further two-parameter family on 2026-09-27, and Philip Engel posted a self-contained proof of the construction on 2026-09-29. None of this is refereed yet.

**An almost complex structure is a quarter-turn rule J on every tangent plane with J twice equal to minus the identity; it comes from complex coordinates exactly when its Nijenhuis tensor is zero; on the six-sphere the octonion rule has Nijenhuis tensor of length 4 on suitable unit arrows, so it is not one, and the 2026 claims build a different rule that is.**

**What kind of fact this is:** three proved theorems and one claim. Proved: the octonion rule is almost complex (computed here), only $`S^2`$ and $`S^6`$ among spheres are almost complex (Borel and Serre, 1953), and no complex structure on $`S^6`$ keeps lengths of the round sphere (LeBrun, 1987). Claimed as of 2026-11-24: $`S^6`$ has a complex structure. This card outlines the claim and proves none of it.

### Status, as of 2026-11-24

| Statement | Kind | Status | Primary source |
| --- | --- | --- | --- |
| $`S^6`$ has an almost complex structure | theorem | proved; the octonion rule, checked on this card | the octonion construction (classical) |
| Only $`S^2`$ and $`S^6`$ are almost complex spheres | theorem | proved, 1953 | Borel and Serre (1953) |
| No complex structure on $`S^6`$ preserves the round sphere's lengths | theorem | proved, 1987 | LeBrun (1987) |
| $`S^6`$ has a complex structure | theorem | claimed: manuscript in 2026; independent proof posted 2026-09-29; not refereed | Engel (2026) |
| A two-parameter family of them | theorem | claimed: preprint posted 2026-09-27; not refereed | Viaclovsky (2026) |
| A further family, disjoint from the known ones | theorem | claimed: preprint posted 2026-09-27, revised 2026-10-09; not refereed | Liu and Rollenske (2026), arXiv:2609.33826 |

The manuscript itself is not cited here: it is credited to an AI system, and this wing cites the independent mathematicians who checked and extended it. This card found no refereed version and no formal proof check of the construction as of 2026-11-24. How to audit a machine-made claim is on [Machines that prove](../07-Physics%2C%20Finance%20and%20Machines/02-ai-and-mathematics-2026.md).

### The picture: the route to the claim

```mermaid
flowchart TB
    A["Octonion rule J on S^6:<br/>almost complex"] --> B["1953: Borel and Serre:<br/>only S^2 and S^6 are almost complex"]
    B --> C["1957: Newlander and Nirenberg:<br/>complex exactly when N_J = 0"]
    C --> D["Octonion J: N_J is never 0<br/>(computed on this card)"]
    D --> E["1987: LeBrun:<br/>no length-keeping J is complex"]
    E --> F["2026: manuscript claims a complex S^6,<br/>built from a family of complex 2-tori"]
    F --> G["2026-09-27: Viaclovsky, a 2-parameter family<br/>2026-09-29: Engel, a self-contained proof"]
    G --> H["Status 2026-11-24: claimed, not refereed"]
```

The top five boxes are proved. The next two are dated claims, not refereed. The last is the status.

---

## The formula

Notation first, in words. A **tangent vector** at a point $`x`$ is an arrow that touches the sphere there; all of them form the **tangent space** $`T_xS^6`$, a flat six-dimensional copy of space. A **vector field** chooses one tangent vector at every point.

The octonion **cross product** $`u \times v`$ of two arrows in seven-dimensional space comes from octonion multiplication with seven units $`e_1, \dots, e_7`$: the products $`e_1e_2 = e_4`$, $`e_2e_3 = e_5`$, and so on, shifting every index by one. The rule is

```math
J_x(v) = x \times v \quad\text{for } v \text{ in } T_xS^6, \qquad J_x\big(J_x(v)\big) = -v
```

**Read it aloud:** at the point x, turn the tangent arrow v by crossing it with x; doing it twice reverses v.

Whether J comes from complex coordinates is measured by the **Nijenhuis tensor**, built from the [Lie bracket](../../23-Differential%20geometry%20and%20Lie%20groups/03-Manifolds/08-lie-brackets-and-frobenius-theorem.md) $`[X,Y]`$, the gap left when two motions swap order:

```math
N_J(X,Y) = [JX,JY] - J[JX,Y] - J[X,JY] - [X,Y]
```

**Read it aloud:** move along JX and JY and record the swap gap; subtract the turned gaps of the mixed pairs; subtract the plain gap. Complex coordinates exist exactly when the result is zero for every pair.

For the octonion rule this works out to a closed form, checked three ways by the code:

```math
N_J(X,Y) = -4\, x \times (X \times Y)
```

At $`x = (2/7, 3/7, 6/7, 0, 0, 0, 0)`$ with $`X = e_4`$ and $`Y = e_5`$ it is $`(-24/7, 0, 8/7, 0, 0, 12/7, 0)`$, of squared length 16.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $`S^n`$ | the sphere of radius 1 in $`n+1`$ dimensions | $`S^6`$, in seven dimensions | above 6, no sphere is even almost complex |
| $`e_1, \dots, e_7`$ | the octonions' seven imaginary units | $`e_1e_2 = e_4`$ | — |
| $`x`$ | a point of $`S^6`$, a unit arrow | $`(2/7, 3/7, 6/7, 0, 0, 0, 0)`$ | off the sphere, J squares to $`-\lvert x\rvert^2`$ |
| $`v`$, $`T_xS^6`$ | a tangent arrow; all of them at $`x`$ | $`(3, -2, 0, 1, 0, 0, 0)`$, squared length 14 | — |
| $`u \times v`$ | octonion cross product: the imaginary part of $`uv`$ | $`e_1 \times e_2 = e_4`$ | its squared length is $`\lvert u\rvert^2\lvert v\rvert^2 - (u\cdot v)^2`$ |
| $`J`$ | almost complex structure: a quarter-turn rule, $`J^2 = -1`$ | $`J_x(v) = x \times v`$ | — |
| $`X`$, $`Y`$ | vector fields: one arrow at every point | $`e_4`$ and $`e_5`$ at $`x`$ | — |
| $`[X,Y]`$, $`B(X,Y)`$ | Lie bracket: the swap gap of two motions; $`B`$: how fast J turns along $`X`$, applied to $`Y`$ | inside $`N_J`$ | — |
| $`N_J`$ | Nijenhuis tensor: zero exactly when J is complex | squared length 16 at $`x`$ | 0 on $`S^2`$, never 0 on $`S^6`$ |
| $`\mathbb{P}^1`$ | the projective line: the Riemann sphere as a base | the base of the 2026 torus family | — |
| $`\chi`$, $`c_n`$, $`p_1`$, $`\omega`$ | Euler number, top Chern class, first Pontryagin class; a Kähler form | $`\chi(S^6) = 2 = c_3`$; no $`\omega`$ on $`S^6`$ | — |
| $`n`$, $`(n-1)!`$ | half the sphere's dimension; its factorial test | $`n = 3`$, $`2! = 2`$ | $`(n-1)!`$ outgrows 2 from $`n = 4`$ |

### When it holds

- **The point is on the sphere.** J squares to $`-\lvert x\rvert^2`$, so at $`2x`$ the turn twice gives $`-4v`$: $`(-12, 8, 0, -4, 0, 0, 0)`$.
- **The arrow is tangent.** For an arrow that pokes out, such as $`e_1`$ at $`x`$, twice-turning gives $`(-45/49, 6/49, 12/49, 0, 0, 0, 0)`$, not $`-e_1`$.
- **The cross product is the octonion one.** In seven dimensions only this product, up to rotation, has the length rule; a made-up table loses $`J^2 = -1`$.
- **Integrability needs every pair.** $`N_J`$ vanishes for some pairs, such as $`Y = JX`$. Complex coordinates need it to vanish for all.
- **The 2026 claim needs a different J.** LeBrun's theorem rules out every complex J that keeps round lengths, so a complex $`S^6`$ must bend lengths.

---

## Why it works

### Step 0: complex coordinates force the quarter-turn rule to be flat

In a complex coordinate $`z = a + ib`$, multiplying a step by $`i`$ is the same matrix at every point. Moving in the $`a`$ direction and then the $`b`$ direction, or the other way round, ends at the same place. So with complex coordinates, all the swap gaps in $`N_J`$ cancel. The **Newlander–Nirenberg theorem** (1957) proves the converse: if $`N_J`$ is zero everywhere, complex coordinates exist. This card states it with its source and does not prove it.

That theorem turns "is there a complex structure?" into "is there a J with zero Nijenhuis tensor?". It plays the role Frobenius's theorem, on [Lie bracket](../../23-Differential%20geometry%20and%20Lie%20groups/03-Manifolds/08-lie-brackets-and-frobenius-theorem.md), plays for planes: a bracket test that decides whether local pieces knit together.

### Step 1: the octonion rule squares to −1

For unit $`x`$ and any $`v`$, octonion arithmetic gives

```math
x \times (x \times v) = (x \cdot v)\,x - \lvert x\rvert^2\, v
```

On the sphere $`\lvert x\rvert = 1`$, and a tangent $`v`$ has $`x \cdot v = 0`$, so the right side is $`-v`$. Also $`x \times v`$ is perpendicular to $`x`$, so the turned arrow stays tangent, and the length rule keeps its length: 14 before, 14 after. The code checks all 49 pairs of units against the length rule, then $`J^2 = -1`$ on six tangent arrows, in exact fractions.

### Step 2: on the globe the same recipe is complex

Replace octonions by quaternions (four-dimensional numbers with units $`i, j, k`$). Their cross product is the ordinary one in three dimensions, and $`J_x(v) = x \times v`$ is the left quarter turn on $`S^2`$. At $`x = (2/7, 3/7, 6/7)`$ it turns $`(3, -2, 0)`$ into $`(12/7, 18/7, -13/7)`$.

Here $`N_J = 0`$. The closed form shows why: two tangent arrows on $`S^2`$ have a cross product along $`x`$, and $`x \times x = 0`$. This is the Riemann sphere of [Complex manifolds and Kahler forms](../../22-Algebraic%20geometry/05-Cohomology%20and%20the%20Hodge%20Conjecture/04-complex-manifolds-and-kahler-forms.md).

### Step 3: on the six-sphere it is not

In seven dimensions, two tangent arrows can have a cross product that is again tangent, and then $`x \times (X \times Y)`$ is not zero. For unit $`X`$, $`Y`$ with $`Y`$ perpendicular to both $`X`$ and $`JX`$, the length is exactly 4. At $`e_1`$, 12 of the 15 pairs of unit tangent directions have $`\lvert N_J\rvert^2 = 16`$. The other 3 are pairs $`Y = \pm JX`$, where it is 0.

The root cause is that octonions are not associative. The three-dimensional cross product obeys the **Jacobi identity**, $`a\times(b\times c) + b\times(c\times a) + c\times(a\times b) = 0`$; the seven-dimensional one does not: for $`e_1, e_2, e_3`$ the sum is $`3e_6`$.

<details>
<summary>Detailed derivation: the closed form for the Nijenhuis tensor</summary>

Extend arrows off the sphere: for constant $`a`$, the field $`X = a - (a\cdot x)x`$ is tangent along $`S^6`$, and $`JX = x \times a`$, since $`x \times x = 0`$. Brackets of fields tangent along the sphere, computed in seven-dimensional space, are the sphere's own brackets. Each bracket is a derivative of these simple polynomials, so $`N_J`$ comes out exactly. That is the code's first road.

The second road uses how fast J turns. Moving along $`X`$, the change of J applied to $`Y`$ is the tangent part of $`X \times Y`$; call it $`B(X,Y)`$. For any torsion-free connection (a way of differentiating arrows in which the order of two directions does not matter),

$`\displaystyle N_J(X,Y) = B(JX,Y) - B(JY,X) - J\,B(X,Y) + J\,B(Y,X).`$

The octonion product gives $`B(JX,Y) = -J\,B(X,Y)`$, and $`B`$ changes sign when its arrows swap. The four terms then collapse:

$`\displaystyle N_J(X,Y) = -4\,J\,B(X,Y) = -4\,x \times (X \times Y).`$

The code computes all three expressions in exact fractions and finds them equal at $`x`$, for a second pair at $`x`$ whose plain bracket is not zero, and at all 15 pairs at $`e_1`$.

</details>

### Step 4: why only $`S^2`$ and $`S^6`$

An almost complex structure makes the tangent bundle a complex bundle, which has Chern classes ([Chern-Weil](../../23-Differential%20geometry%20and%20Lie%20groups/06-Lie%20Groups/13-chern-weil-theory-and-characteristic-classes.md)). On $`S^{2n}`$ the top one, $`c_n`$, must equal the Euler number, 2. Borel and Serre (1953) ruled out every sphere except $`S^2`$ and $`S^6`$ using Steenrod operations, which no card in this library teaches.

A later route, quoted here without proof, uses Bott's integrality theorem: $`c_n`$ of a complex bundle on $`S^{2n}`$ is a multiple of $`(n-1)!`$. So 2 must be a multiple of $`(n-1)!`$, which fails from $`n = 4`$, where $`3! = 6`$. On $`S^4`$ the test passes, but $`c_1 = 0`$ there, so the first Pontryagin class would be $`p_1 = c_1^2 - 2c_2 = -4`$, while $`S^4`$ has $`p_1 = 0`$. Only $`S^2`$ and $`S^6`$ survive, and both do have J.

### Step 5: LeBrun, and why a complex $`S^6`$ cannot be Kähler

The octonion J keeps the lengths of the round sphere: it turns every arrow without stretching it. LeBrun (1987) proved that no complex structure on $`S^6`$ keeps those lengths. His proof uses twistor spaces, which this library does not teach; this card states the result.

A complex $`S^6`$ can never be Kähler either. A Kähler form $`\omega`$ is closed and $`\omega^3`$ is a volume form, so $`\omega`$ gives a nonzero class in the second cohomology. But $`S^6`$ has no second cohomology.

### Step 6: the 2026 construction, in outline

The outline follows Engel's self-contained proof (2026-09-29). It is a research proof, summarized here, not proved.

1. Start from a family of complex 2-tori (each a four-dimensional doughnut with complex coordinates), one over each point of the projective line $`\mathbb{P}^1`$.
2. Away from three special points, the family is smooth. Fill in the fibres over those points. Two of them come from logarithmic transforms (cut out a neighbourhood of one fibre and glue it back with a twist), of multiplicities 3 and 4. The result is a compact complex threefold: three complex coordinates near each point.
3. Show the threefold is simply connected (every loop shrinks) and has the integer homology of $`S^6`$.
4. A simply connected space with the homology of $`S^6`$ is a homotopy sphere (it can be deformed to $`S^6`$). In dimension 6 such a space is a topological sphere, by Smale's work behind [The Poincare conjecture, solved](../02-The%20Millennium%20Problems/07-poincare-conjecture-solved.md) in high dimensions. Kervaire and Milnor's count of smooth spheres leaves only one in dimension 6, so it is the standard $`S^6`$.

Engel notes one open conflict. The threefold maps holomorphically onto $`\mathbb{P}^1`$, which contradicts a published 1998 corollary of Campana, Demailly and Peternell saying any complex $`S^6`$ admits no such map: it has algebraic dimension zero, meaning no non-constant meromorphic functions (ratios of holomorphic functions), and a map onto $`\mathbb{P}^1`$ would give one. That corollary is cited here through Engel's paper. He states the contradiction and does not locate an error in either argument; it is part of what refereeing must settle.

The complex structure is integrable by construction, so its Nijenhuis tensor is zero. It is not the octonion J, and by Step 5 it bends lengths and is not Kähler. Viaclovsky's family (2026-09-27) starts from a different elliptic surface and gives structures not equivalent to the first ones. Wenfei Liu and Sönke Rollenske (arXiv:2609.33826, 2026-09-27) follow a similar path to another family, disjoint from the known ones. The earliest independent paper on the construction, by Yun-Heng Du, Bin Guo, Yuta Kusakabe and Song-Yan Xie (arXiv:2610.00250, 2026-09-23), studies it and shows its complex six-spheres are Oka manifolds: holomorphic maps into them are as plentiful as continuous ones, in a precise sense. All of these are preprints.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| the point | $`(4 + 9 + 36)/49`$ | $`\lvert x\rvert^2 = 1`$ |
| the arrow is tangent | $`(2\cdot 3 + 3\cdot(-2))/7`$ | $`x \cdot v = 0`$ |
| one turn | $`J_x(v) = x \times v`$ | $`(3/7, -2/7, 0, -13/7, 12/7, 6/7, -18/7)`$ |
| length kept | $`(9 + 4 + 169 + 144 + 36 + 324)/49`$ | 14 |
| two turns | $`x \times (x \times v)`$ | **$`(-3, 2, 0, -1, 0, 0, 0) = -v`$** |
| check the pair | $`JX \cdot Y`$ for $`X = e_4`$, $`Y = e_5`$ | 0 |
| Nijenhuis tensor | $`-4\,x \times (e_4 \times e_5)`$, $`e_4 e_5 = e_7`$ | $`(-24/7, 0, 8/7, 0, 0, 12/7, 0)`$ |
| its squared length | $`(576 + 64 + 144)/49`$ | **16** |
| the globe | $`N_J`$ on $`S^2`$ at $`(2/7, 3/7, 6/7)`$ | **0** |

The octonion rule is a true quarter turn at every tangent arrow, yet its Nijenhuis tensor has length 4, so it is almost complex and not complex.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Point off the sphere, $`2x`$ | twice-turned $`v`$ is $`(-12, 8, 0, -4, 0, 0, 0) = -4v`$ | J squares to $`-\lvert x\rvert^2`$ |
| Arrow not tangent, $`e_1`$ | $`(-45/49, 6/49, 12/49, 0, 0, 0, 0)`$, not $`-e_1`$ | the term $`(x \cdot v)\,x`$ survives |
| Treating octonions like quaternions | Jacobi sum for $`e_1, e_2, e_3`$ is $`3e_6`$, not 0 | the seven-dimensional product is not associative |
| Taking $`J^2 = -1`$ as enough | $`\lvert N_J\rvert^2 = 16`$ at $`x`$ | almost complex is not complex |

The code prints all four.

---

## Code, from first principles, and it actually runs

The code builds the seven-dimensional cross product from the table of seven triples and works only in exact fractions. It checks the length rule on all 49 pairs of units and checks $`J^2 = -1`$ on six tangent arrows. It then computes the Nijenhuis tensor by three independent roads: brackets of explicit vector fields, the formula through the turning rate of J, and the closed form $`-4\,x \times (X \times Y)`$. One pair, built from $`e_1`$ and $`e_2`$, is not tangent at $`x`$, so the plain bracket $`[X,Y]`$ is not zero there and every term of the brackets road is tested. It repeats the computation on $`S^2`$ with quaternions, where the answer is 0. Last, it prints the sphere test of Step 4 for $`n`$ up to 8.

### Python

```python
# The six-sphere card's check.  Standard library only, exact fractions only.
# Roads: J^2 = -1 by direct product; the Nijenhuis tensor three ways
# (brackets of explicit fields, a connection formula, a closed form).
from fractions import Fraction as F

T7 = [(i, (i + 1) % 7, (i + 3) % 7) for i in range(7)]  # e1e2=e4, e2e3=e5, ...
T3 = [(0, 1, 2)]                                        # quaternions: ij = k

def cross(u, v, T):
    w = [F(0)] * len(u)
    for (i, j, k) in T:
        for (a, b, c) in ((i, j, k), (j, k, i), (k, i, j)):
            w[c] += u[a] * v[b] - u[b] * v[a]
    return w

def dot(u, v): return sum(a * b for a, b in zip(u, v))
def add(*vs): return [sum(c) for c in zip(*vs)]
def sc(s, v): return [s * a for a in v]
def basis(n, i): return [F(int(k == i)) for k in range(n)]
def show(v): return "(" + ", ".join(str(a) for a in v) + ")"

def nij_brackets(p, a, b, T):
    # Fields near the sphere: X = a - (a.p)p and JX = p x a; D = derivative.
    J = lambda v: cross(p, v, T)
    X = (add(a, sc(-dot(a, p), p)), lambda w: add(sc(-dot(a, w), p), sc(-dot(a, p), w)))
    Y = (add(b, sc(-dot(b, p), p)), lambda w: add(sc(-dot(b, w), p), sc(-dot(b, p), w)))
    JX = (cross(p, a, T), lambda w: cross(w, a, T))
    JY = (cross(p, b, T), lambda w: cross(w, b, T))
    br = lambda U, V: add(V[1](U[0]), sc(-1, U[1](V[0])))  # [U,V] = DV(U) - DU(V)
    return add(br(JX, JY), sc(-1, J(br(JX, Y))), sc(-1, J(br(X, JY))), sc(-1, br(X, Y)))

def nij_connection(p, X, Y, T):
    J = lambda v: cross(p, v, T)
    B = lambda U, V: add(cross(U, V, T), sc(-dot(p, cross(U, V, T)), p))  # (nabla_U J)V
    return add(B(J(X), Y), sc(-1, B(J(Y), X)), sc(-1, J(B(X, Y))), J(B(Y, X)))

def nij_closed(p, X, Y, T): return sc(-4, cross(p, cross(X, Y, T), T))

E = [basis(7, i) for i in range(7)]
print("table: e1e2=e4 e2e3=e5 e3e4=e6 e4e5=e7 e5e6=e1 e6e7=e2 e7e1=e3")
bad = 0
for u in E:
    for v in E:
        w = cross(u, v, T7)
        bad += dot(w, w) != dot(u, u) * dot(v, v) - dot(u, v) ** 2
assert bad == 0
print("length rule |u x v|^2 = |u|^2|v|^2 - (u.v)^2: 49 basis pairs, failures", bad)
jac = add(cross(E[0], cross(E[1], E[2], T7), T7), cross(E[1], cross(E[2], E[0], T7), T7),
          cross(E[2], cross(E[0], E[1], T7), T7))
print("Jacobi sum for e1, e2, e3 in 7D:", show(jac))
i3 = [basis(3, i) for i in range(3)]
jac3 = add(cross(i3[0], cross(i3[1], i3[2], T3), T3), cross(i3[1], cross(i3[2], i3[0], T3), T3),
           cross(i3[2], cross(i3[0], i3[1], T3), T3))
assert jac3 == [0, 0, 0] and jac != [0] * 7
print("Jacobi sum for i, j, k in 3D:", show(jac3))

p = [F(2, 7), F(3, 7), F(6, 7), F(0), F(0), F(0), F(0)]
v = [F(3), F(-2), F(0), F(1), F(0), F(0), F(0)]
Jv = cross(p, v, T7); JJv = cross(p, Jv, T7)
print("point x =", show(p), " |x|^2 =", dot(p, p))
print("tangent v =", show(v), " x.v =", dot(p, v), " |v|^2 =", dot(v, v))
print("Jv = x x v =", show(Jv), " |Jv|^2 =", dot(Jv, Jv), " x.Jv =", dot(p, Jv))
print("J(Jv) =", show(JJv))
assert dot(p, p) == 1 and JJv == sc(-1, v) and dot(Jv, Jv) == dot(v, v)
for s in range(1, 6):  # J^2 = -1 on more tangent vectors, built by projection
    w = [F((s * k * k + 3 * k + s) % 11 - 5) for k in range(7)]
    w = add(w, sc(-dot(w, p), p))
    assert cross(p, cross(p, w, T7), T7) == sc(-1, w)
print("J(Jw) = -w checked for 5 more tangent vectors at x")

X, Y = E[3], E[4]
N1 = nij_brackets(p, X, Y, T7); N2 = nij_connection(p, X, Y, T7); N3 = nij_closed(p, X, Y, T7)
print("X = e4, Y = e5: JX.Y =", dot(cross(p, X, T7), Y))
print("N(X,Y) by brackets   =", show(N1))
print("N(X,Y) by connection =", show(N2))
print("N(X,Y) = -4 x(XxY)   =", show(N3))
assert N1 == N2 == N3
print("|N(X,Y)|^2 =", dot(N1, N1))
assert dot(N1, N1) == 16
zero = nz = 0
for a in range(1, 7):
    for b in range(a + 1, 7):
        n1 = nij_brackets(E[0], E[a], E[b], T7)
        assert n1 == nij_closed(E[0], E[a], E[b], T7) == nij_connection(E[0], E[a], E[b], T7)
        zero += n1 == [0] * 7; nz += dot(n1, n1) == 16
assert zero + nz == 15
print("at e1, 15 pairs of basis tangents: N = 0 for", zero, "pairs, |N|^2 = 16 for", nz)
a, b = E[0], E[1]  # e1, e2 are not tangent at x, so the plain bracket [X,Y] is not 0 there
Xa, Yb = add(a, sc(-dot(a, p), p)), add(b, sc(-dot(b, p), p))
n4 = nij_brackets(p, a, b, T7)
assert n4 == nij_connection(p, Xa, Yb, T7) == nij_closed(p, Xa, Yb, T7) != [0] * 7
print("X, Y from e1, e2, not tangent at x: three roads agree, N =", show(n4))

q = [F(2, 7), F(3, 7), F(6, 7)]
a2, b2 = [F(3), F(-2), F(0)], [F(0), F(6), F(-3)]
n2 = nij_brackets(q, a2, b2, T3)
assert dot(q, a2) == dot(q, b2) == 0 and n2 == nij_closed(q, a2, b2, T3) == [0, 0, 0]
print("S^2 at", show(q), "J(3,-2,0) =", show(cross(q, a2, T3)), " N =", show(n2))

print("n, sphere, (n-1)!, test: c_n = Euler number 2 must be a multiple of (n-1)!")
f = 1
for n in range(1, 9):
    f = f * (n - 1) if n > 1 else 1
    ok = 2 % f == 0
    note = "passes" if ok else "fails"
    if n == 2:  # S^4, quoted facts, not checked here: c1 = 0 and c2 = 2 give p1 = c1^2 - 2 c2, but p1(S^4) = 0
        p1 = 0 * 0 - 2 * 2
        note = "passes, but p1 = -2 c2 = " + str(p1) + ", not 0: fails"
    print(n, "S^" + str(2 * n), f, note)
    assert ok == (n <= 3)

print("what breaks, off the sphere: x' = 2x gives J(Jv) =", show(cross(sc(2, p), cross(sc(2, p), v, T7), T7)))
e1 = E[0]
print("what breaks, not tangent: v = e1 gives J(Jv) =", show(cross(p, cross(p, e1, T7), T7)))
print("ALL CHECKS PASS")
```

**Ran 2026-11-24 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
table: e1e2=e4 e2e3=e5 e3e4=e6 e4e5=e7 e5e6=e1 e6e7=e2 e7e1=e3
length rule |u x v|^2 = |u|^2|v|^2 - (u.v)^2: 49 basis pairs, failures 0
Jacobi sum for e1, e2, e3 in 7D: (0, 0, 0, 0, 0, 3, 0)
Jacobi sum for i, j, k in 3D: (0, 0, 0)
point x = (2/7, 3/7, 6/7, 0, 0, 0, 0)  |x|^2 = 1
tangent v = (3, -2, 0, 1, 0, 0, 0)  x.v = 0  |v|^2 = 14
Jv = x x v = (3/7, -2/7, 0, -13/7, 12/7, 6/7, -18/7)  |Jv|^2 = 14  x.Jv = 0
J(Jv) = (-3, 2, 0, -1, 0, 0, 0)
J(Jw) = -w checked for 5 more tangent vectors at x
X = e4, Y = e5: JX.Y = 0
N(X,Y) by brackets   = (-24/7, 0, 8/7, 0, 0, 12/7, 0)
N(X,Y) by connection = (-24/7, 0, 8/7, 0, 0, 12/7, 0)
N(X,Y) = -4 x(XxY)   = (-24/7, 0, 8/7, 0, 0, 12/7, 0)
|N(X,Y)|^2 = 16
at e1, 15 pairs of basis tangents: N = 0 for 3 pairs, |N|^2 = 16 for 12
X, Y from e1, e2, not tangent at x: three roads agree, N = (0, 0, 0, 0, 0, -24/7, 0)
S^2 at (2/7, 3/7, 6/7) J(3,-2,0) = (12/7, 18/7, -13/7)  N = (0, 0, 0)
n, sphere, (n-1)!, test: c_n = Euler number 2 must be a multiple of (n-1)!
1 S^2 1 passes
2 S^4 1 passes, but p1 = -2 c2 = -4, not 0: fails
3 S^6 2 passes
4 S^8 6 fails
5 S^10 24 fails
6 S^12 120 fails
7 S^14 720 fails
8 S^16 5040 fails
what breaks, off the sphere: x' = 2x gives J(Jv) = (-12, 8, 0, -4, 0, 0, 0)
what breaks, not tangent: v = e1 gives J(Jv) = (-45/49, 6/49, 12/49, 0, 0, 0, 0)
ALL CHECKS PASS
```

### Rust

```rust
// The six-sphere card's check.  std only, exact fractions only.
// Roads: J^2 = -1 by direct product; the Nijenhuis tensor three ways
// (brackets of explicit fields, a connection formula, a closed form).
use std::ops::{Add, Mul, Neg, Sub};

#[derive(Clone, Copy, PartialEq, Debug)]
struct Q { n: i128, d: i128 }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q {
    let g = gcd(n, d).max(1); let s = if d < 0 { -1 } else { 1 };
    Q { n: s * n / g, d: s * d / g }
}
fn z(n: i128) -> Q { q(n, 1) }
impl Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.n * o.d + o.n * self.d, self.d * o.d) } }
impl Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { self + (-o) } }
impl Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.n * o.n, self.d * o.d) } }
impl Neg for Q { type Output = Q; fn neg(self) -> Q { Q { n: -self.n, d: self.d } } }
impl std::fmt::Display for Q {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        if self.d == 1 { write!(f, "{}", self.n) } else { write!(f, "{}/{}", self.n, self.d) }
    }
}
type V = Vec<Q>;
type T = Vec<(usize, usize, usize)>;

fn cross(u: &V, v: &V, t: &T) -> V {
    let mut w = vec![z(0); u.len()];
    for &(i, j, k) in t {
        for &(a, b, c) in &[(i, j, k), (j, k, i), (k, i, j)] { w[c] = w[c] + u[a] * v[b] - u[b] * v[a]; }
    }
    w
}
fn dot(u: &V, v: &V) -> Q { u.iter().zip(v).fold(z(0), |s, (a, b)| s + *a * *b) }
fn add(u: &V, v: &V) -> V { u.iter().zip(v).map(|(a, b)| *a + *b).collect() }
fn sc(s: Q, v: &V) -> V { v.iter().map(|a| s * *a).collect() }
fn basis(n: usize, i: usize) -> V { (0..n).map(|k| z((k == i) as i128)).collect() }
fn show(v: &V) -> String { format!("({})", v.iter().map(|a| a.to_string()).collect::<Vec<_>>().join(", ")) }
fn zero(v: &V) -> bool { v.iter().all(|a| a.n == 0) }

fn nij_brackets(p: &V, a: &V, b: &V, t: &T) -> V {
    // Fields near the sphere: X = a - (a.p)p and JX = p x a; d = derivative.
    let j = |v: &V| cross(p, v, t);
    let xv = add(a, &sc(-dot(a, p), p)); let yv = add(b, &sc(-dot(b, p), p));
    let dx = |w: &V| add(&sc(-dot(a, w), p), &sc(-dot(a, p), w));
    let dy = |w: &V| add(&sc(-dot(b, w), p), &sc(-dot(b, p), w));
    let jxv = cross(p, a, t); let jyv = cross(p, b, t);
    let djx = |w: &V| cross(w, a, t); let djy = |w: &V| cross(w, b, t);
    let b1 = add(&djy(&jxv), &sc(z(-1), &djx(&jyv)));   // [JX,JY]
    let b2 = add(&dy(&jxv), &sc(z(-1), &djx(&yv)));     // [JX,Y]
    let b3 = add(&djy(&xv), &sc(z(-1), &dx(&jyv)));     // [X,JY]
    let b4 = add(&dy(&xv), &sc(z(-1), &dx(&yv)));       // [X,Y]
    add(&add(&b1, &sc(z(-1), &j(&b2))), &add(&sc(z(-1), &j(&b3)), &sc(z(-1), &b4)))
}
fn nij_connection(p: &V, x: &V, y: &V, t: &T) -> V {
    let j = |v: &V| cross(p, v, t);
    let bb = |u: &V, v: &V| { let c = cross(u, v, t); add(&c, &sc(-dot(p, &c), p)) };
    add(&add(&bb(&j(x), y), &sc(z(-1), &bb(&j(y), x))), &add(&sc(z(-1), &j(&bb(x, y))), &j(&bb(y, x))))
}
fn nij_closed(p: &V, x: &V, y: &V, t: &T) -> V { sc(z(-4), &cross(p, &cross(x, y, t), t)) }
fn jacobi(a: &V, b: &V, c: &V, t: &T) -> V {
    add(&add(&cross(a, &cross(b, c, t), t), &cross(b, &cross(c, a, t), t)), &cross(c, &cross(a, b, t), t))
}

fn main() {
    let t7: T = (0..7).map(|i| (i, (i + 1) % 7, (i + 3) % 7)).collect();
    let t3: T = vec![(0, 1, 2)];
    let e: Vec<V> = (0..7).map(|i| basis(7, i)).collect();
    println!("table: e1e2=e4 e2e3=e5 e3e4=e6 e4e5=e7 e5e6=e1 e6e7=e2 e7e1=e3");
    let mut bad = 0;
    for u in &e { for v in &e {
        let w = cross(u, v, &t7);
        if dot(&w, &w) != dot(u, u) * dot(v, v) - dot(u, v) * dot(u, v) { bad += 1; }
    } }
    assert!(bad == 0);
    println!("length rule |u x v|^2 = |u|^2|v|^2 - (u.v)^2: 49 basis pairs, failures {}", bad);
    let jac = jacobi(&e[0], &e[1], &e[2], &t7);
    println!("Jacobi sum for e1, e2, e3 in 7D: {}", show(&jac));
    let i3: Vec<V> = (0..3).map(|i| basis(3, i)).collect();
    let jac3 = jacobi(&i3[0], &i3[1], &i3[2], &t3);
    assert!(zero(&jac3) && !zero(&jac));
    println!("Jacobi sum for i, j, k in 3D: {}", show(&jac3));

    let p: V = vec![q(2, 7), q(3, 7), q(6, 7), z(0), z(0), z(0), z(0)];
    let v: V = vec![z(3), z(-2), z(0), z(1), z(0), z(0), z(0)];
    let jv = cross(&p, &v, &t7); let jjv = cross(&p, &jv, &t7);
    println!("point x = {}  |x|^2 = {}", show(&p), dot(&p, &p));
    println!("tangent v = {}  x.v = {}  |v|^2 = {}", show(&v), dot(&p, &v), dot(&v, &v));
    println!("Jv = x x v = {}  |Jv|^2 = {}  x.Jv = {}", show(&jv), dot(&jv, &jv), dot(&p, &jv));
    println!("J(Jv) = {}", show(&jjv));
    assert!(dot(&p, &p) == z(1) && jjv == sc(z(-1), &v) && dot(&jv, &jv) == dot(&v, &v));
    for s in 1..6i128 {
        let w: V = (0..7i128).map(|k| z((s * k * k + 3 * k + s) % 11 - 5)).collect();
        let w = add(&w, &sc(-dot(&w, &p), &p));
        assert!(cross(&p, &cross(&p, &w, &t7), &t7) == sc(z(-1), &w));
    }
    println!("J(Jw) = -w checked for 5 more tangent vectors at x");

    let (x, y) = (&e[3], &e[4]);
    let n1 = nij_brackets(&p, x, y, &t7); let n2 = nij_connection(&p, x, y, &t7); let n3 = nij_closed(&p, x, y, &t7);
    println!("X = e4, Y = e5: JX.Y = {}", dot(&cross(&p, x, &t7), y));
    println!("N(X,Y) by brackets   = {}", show(&n1));
    println!("N(X,Y) by connection = {}", show(&n2));
    println!("N(X,Y) = -4 x(XxY)   = {}", show(&n3));
    assert!(n1 == n2 && n2 == n3);
    println!("|N(X,Y)|^2 = {}", dot(&n1, &n1));
    assert!(dot(&n1, &n1) == z(16));
    let (mut zc, mut nz) = (0, 0);
    for a in 1..7 { for b in (a + 1)..7 {
        let m = nij_brackets(&e[0], &e[a], &e[b], &t7);
        assert!(m == nij_closed(&e[0], &e[a], &e[b], &t7) && m == nij_connection(&e[0], &e[a], &e[b], &t7));
        if zero(&m) { zc += 1; }
        if dot(&m, &m) == z(16) { nz += 1; }
    } }
    assert!(zc + nz == 15);
    println!("at e1, 15 pairs of basis tangents: N = 0 for {} pairs, |N|^2 = 16 for {}", zc, nz);
    let (a1, b1) = (&e[0], &e[1]);   // e1, e2 are not tangent at x, so the plain bracket [X,Y] is not 0 there
    let xa = add(a1, &sc(-dot(a1, &p), &p)); let yb = add(b1, &sc(-dot(b1, &p), &p));
    let n4 = nij_brackets(&p, a1, b1, &t7);
    assert!(n4 == nij_connection(&p, &xa, &yb, &t7) && n4 == nij_closed(&p, &xa, &yb, &t7) && !zero(&n4));
    println!("X, Y from e1, e2, not tangent at x: three roads agree, N = {}", show(&n4));

    let qq: V = vec![q(2, 7), q(3, 7), q(6, 7)];
    let a2: V = vec![z(3), z(-2), z(0)]; let b2: V = vec![z(0), z(6), z(-3)];
    let m2 = nij_brackets(&qq, &a2, &b2, &t3);
    assert!(dot(&qq, &a2) == z(0) && dot(&qq, &b2) == z(0) && zero(&m2) && m2 == nij_closed(&qq, &a2, &b2, &t3));
    println!("S^2 at {} J(3,-2,0) = {}  N = {}", show(&qq), show(&cross(&qq, &a2, &t3)), show(&m2));

    println!("n, sphere, (n-1)!, test: c_n = Euler number 2 must be a multiple of (n-1)!");
    let mut f: i128 = 1;
    for n in 1..9i128 {
        if n > 1 { f *= n - 1; }
        let ok = 2 % f == 0;
        let mut note = String::from(if ok { "passes" } else { "fails" });
        if n == 2 { // S^4, quoted facts, not checked here: c1 = 0 and c2 = 2 give p1 = c1^2 - 2 c2, but p1(S^4) = 0
            let p1 = 0 * 0 - 2 * 2;
            note = format!("passes, but p1 = -2 c2 = {}, not 0: fails", p1);
        }
        println!("{} S^{} {} {}", n, 2 * n, f, note);
        assert!(ok == (n <= 3));
    }
    let p2 = sc(z(2), &p);
    println!("what breaks, off the sphere: x' = 2x gives J(Jv) = {}", show(&cross(&p2, &cross(&p2, &v, &t7), &t7)));
    println!("what breaks, not tangent: v = e1 gives J(Jv) = {}", show(&cross(&p, &cross(&p, &e[0], &t7), &t7)));
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-24 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
table: e1e2=e4 e2e3=e5 e3e4=e6 e4e5=e7 e5e6=e1 e6e7=e2 e7e1=e3
length rule |u x v|^2 = |u|^2|v|^2 - (u.v)^2: 49 basis pairs, failures 0
Jacobi sum for e1, e2, e3 in 7D: (0, 0, 0, 0, 0, 3, 0)
Jacobi sum for i, j, k in 3D: (0, 0, 0)
point x = (2/7, 3/7, 6/7, 0, 0, 0, 0)  |x|^2 = 1
tangent v = (3, -2, 0, 1, 0, 0, 0)  x.v = 0  |v|^2 = 14
Jv = x x v = (3/7, -2/7, 0, -13/7, 12/7, 6/7, -18/7)  |Jv|^2 = 14  x.Jv = 0
J(Jv) = (-3, 2, 0, -1, 0, 0, 0)
J(Jw) = -w checked for 5 more tangent vectors at x
X = e4, Y = e5: JX.Y = 0
N(X,Y) by brackets   = (-24/7, 0, 8/7, 0, 0, 12/7, 0)
N(X,Y) by connection = (-24/7, 0, 8/7, 0, 0, 12/7, 0)
N(X,Y) = -4 x(XxY)   = (-24/7, 0, 8/7, 0, 0, 12/7, 0)
|N(X,Y)|^2 = 16
at e1, 15 pairs of basis tangents: N = 0 for 3 pairs, |N|^2 = 16 for 12
X, Y from e1, e2, not tangent at x: three roads agree, N = (0, 0, 0, 0, 0, -24/7, 0)
S^2 at (2/7, 3/7, 6/7) J(3,-2,0) = (12/7, 18/7, -13/7)  N = (0, 0, 0)
n, sphere, (n-1)!, test: c_n = Euler number 2 must be a multiple of (n-1)!
1 S^2 1 passes
2 S^4 1 passes, but p1 = -2 c2 = -4, not 0: fails
3 S^6 2 passes
4 S^8 6 fails
5 S^10 24 fails
6 S^12 120 fails
7 S^14 720 fails
8 S^16 5040 fails
what breaks, off the sphere: x' = 2x gives J(Jv) = (-12, 8, 0, -4, 0, 0, 0)
what breaks, not tangent: v = e1 gives J(Jv) = (-45/49, 6/49, 12/49, 0, 0, 0, 0)
ALL CHECKS PASS
```

### Lean

Lean proves the octonion rule's three facts at every point of $`S^6`$, for every tangent arrow, and checks the card's worked numbers.

- Take any arrows $`u`$ and $`v`$. Then $`\lvert u \times v\rvert^2 = \lvert u\rvert^2\lvert v\rvert^2 - (u\cdot v)^2`$.
- Take a point $`x`$ of $`S^6`$ and a tangent arrow $`v`$. Then $`x \times (x \times v) = -v`$, and $`x \times v`$ is tangent, with the length of $`v`$.
- Take tangent arrows $`X`$ and $`Y`$ at $`x`$, with $`N_J`$ built from $`B`$ as in the detailed derivation. Then $`N_J(X,Y) = -4\,x \times (X \times Y)`$.
- Take unit tangent arrows $`X`$ and $`Y`$, with $`Y`$ perpendicular to $`X`$ and to $`JX`$. Then $`\lvert N_J(X,Y)\rvert^2 = 16`$, so $`N_J`$ is not zero.
- The table gives $`e_1 \times e_2 = e_4`$.
- At the card's point $`x`$, one turn and two turns of $`v`$ match the worked numbers, ending at $`-v`$.
- Take $`X = e_4`$ and $`Y = e_5`$ at $`x`$. Then $`N_J = (-24/7, 0, 8/7, 0, 0, 12/7, 0)`$, of squared length 16.
- The Jacobi sum for $`e_1, e_2, e_3`$ is $`3e_6`$, not 0.
- At the point $`2x`$, two turns give $`-4v`$.
- For $`v = e_1`$, which is not tangent, two turns give $`(-45/49, 6/49, 12/49, 0, 0, 0, 0)`$, not $`-e_1`$.
- For $`n`$ from 1 to 8, 2 is a multiple of $`(n-1)!`$ only for $`n = 1, 2, 3`$.

The brackets road to $`N_J`$, the 15 pairs at $`e_1`$ and $`S^2`$ are left to the Python and Rust checks.

```lean
-- The six-sphere: the octonion quarter-turn rule J(v) = x × v on the six-sphere squares to minus the identity, yet its Nijenhuis tensor equals −4 x × (X × Y) and has length 4 on suitable unit arrows, so it is almost complex and not complex.
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Data.Matrix.Mul
import Mathlib.Data.Fin.VecNotation
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.LinearCombination

open Matrix

/-- The seven-dimensional (octonion) cross product: `u × v` is the imaginary part of the
octonion product of two imaginary octonions, with units `e₁, …, e₇` (indices `0, …, 6` here)
and the card's table `e₁e₂ = e₄, e₂e₃ = e₅, …` (every index shifted by one, mod 7).
Component `c` is `u_{c+1}v_{c+3} − u_{c+3}v_{c+1} + u_{c+4}v_{c+5} − u_{c+5}v_{c+4}
+ u_{c+2}v_{c+6} − u_{c+6}v_{c+2}`, indices mod 7. Mathlib has no octonions, so it is
written out. -/
def octCross {R : Type*} [CommRing R] (u v : Fin 7 → R) : Fin 7 → R := fun c =>
  u (c + 1) * v (c + 3) - u (c + 3) * v (c + 1)
    + u (c + 4) * v (c + 5) - u (c + 5) * v (c + 4)
    + u (c + 2) * v (c + 6) - u (c + 6) * v (c + 2)

/-- The card's `B(U, V)`: how fast the octonion rule turns along `U`, applied to `V`, at the
point `x`; it is the tangent part of `U × V`, that is `U × V − (x · (U × V)) x`. -/
def turnRate {R : Type*} [CommRing R] (x U V : Fin 7 → R) : Fin 7 → R :=
  octCross U V - (x ⬝ᵥ octCross U V) • x

/-- The Nijenhuis tensor of the octonion rule `J_x(v) = x × v` at the point `x`, through the
card's torsion-free-connection formula
`N_J(X,Y) = B(JX,Y) − B(JY,X) − J B(X,Y) + J B(Y,X)`. -/
def nijenhuisOct {R : Type*} [CommRing R] (x X Y : Fin 7 → R) : Fin 7 → R :=
  turnRate x (octCross x X) Y - turnRate x (octCross x Y) X
    - octCross x (turnRate x X Y) + octCross x (turnRate x Y X)

theorem octCross_octCross_self {R : Type*} [CommRing R] (x v : Fin 7 → R) :
    octCross x (octCross x v) = (x ⬝ᵥ v) • x - (x ⬝ᵥ x) • v := by
  ext i; fin_cases i <;> simp [octCross, dotProduct, Fin.sum_univ_seven] <;> ring

#print axioms octCross_octCross_self

theorem dot_octCross_self {R : Type*} [CommRing R] (x v : Fin 7 → R) :
    x ⬝ᵥ octCross x v = 0 := by
  simp [octCross, dotProduct, Fin.sum_univ_seven]; ring

#print axioms dot_octCross_self

theorem octCross_dot_octCross {R : Type*} [CommRing R] (u v : Fin 7 → R) :
    octCross u v ⬝ᵥ octCross u v = (u ⬝ᵥ u) * (v ⬝ᵥ v) - (u ⬝ᵥ v) ^ 2 := by
  simp [octCross, dotProduct, Fin.sum_univ_seven]; ring

#print axioms octCross_dot_octCross

theorem dot_octCross_eq {R : Type*} [CommRing R] (x X Y : Fin 7 → R) :
    x ⬝ᵥ octCross X Y = octCross x X ⬝ᵥ Y := by
  simp [octCross, dotProduct, Fin.sum_univ_seven]; ring

#print axioms dot_octCross_eq

theorem octCross_anti {R : Type*} [CommRing R] (u v : Fin 7 → R) :
    octCross u v = -octCross v u := by
  ext i; fin_cases i <;> simp [octCross] <;> ring

#print axioms octCross_anti

theorem octCross_self {R : Type*} [CommRing R] (x : Fin 7 → R) :
    octCross x x = 0 := by
  ext i; fin_cases i <;> simp [octCross] <;> ring

#print axioms octCross_self

theorem octCross_sub_smul {R : Type*} [CommRing R] (x a b : Fin 7 → R) (c : R) :
    octCross x (a - c • b) = octCross x a - c • octCross x b := by
  ext i; fin_cases i <;> simp [octCross] <;> ring

#print axioms octCross_sub_smul

theorem octCross_neg {R : Type*} [CommRing R] (x v : Fin 7 → R) :
    octCross x (-v) = -octCross x v := by
  ext i; fin_cases i <;> simp [octCross] <;> ring

#print axioms octCross_neg

theorem octCross_polar {R : Type*} [CommRing R] (a b c : Fin 7 → R) :
    octCross a (octCross c b) + octCross c (octCross a b)
      = (a ⬝ᵥ b) • c + (c ⬝ᵥ b) • a - (2 * (a ⬝ᵥ c)) • b := by
  ext i; fin_cases i <;> simp [octCross, dotProduct, Fin.sum_univ_seven] <;> ring

#print axioms octCross_polar

theorem dot_octCross_octCross {R : Type*} [CommRing R] (x X Y : Fin 7 → R) :
    x ⬝ᵥ octCross (octCross x X) Y = (x ⬝ᵥ X) * (x ⬝ᵥ Y) - (x ⬝ᵥ x) * (X ⬝ᵥ Y) := by
  rw [dot_octCross_eq, octCross_octCross_self]
  simp [sub_dotProduct, smul_dotProduct]

#print axioms dot_octCross_octCross

theorem nijenhuisOct_eq {R : Type*} [CommRing R] (x X Y : Fin 7 → R) :
    nijenhuisOct x X Y = (-4 : R) • octCross x (octCross X Y)
      + (3 * (x ⬝ᵥ Y)) • X - (3 * (x ⬝ᵥ X)) • Y := by
  have h1 := octCross_polar Y X x
  have h2 := octCross_polar X Y x
  rw [octCross_anti Y X, octCross_neg, dotProduct_comm Y X, dotProduct_comm Y x] at h1
  rw [dotProduct_comm X x] at h2
  unfold nijenhuisOct turnRate
  rw [octCross_sub_smul, octCross_sub_smul, octCross_self, dot_octCross_octCross,
    dot_octCross_octCross, octCross_anti (octCross x X) Y, octCross_anti (octCross x Y) X,
    octCross_anti Y X, octCross_neg, dotProduct_comm Y X]
  ext i
  have e1 := congrFun h1 i
  have e2 := congrFun h2 i
  simp only [Pi.add_apply, Pi.sub_apply, Pi.smul_apply, Pi.neg_apply, smul_eq_mul,
    Pi.zero_apply] at e1 e2 ⊢
  linear_combination e2 - e1

#print axioms nijenhuisOct_eq

/-- The octonion rule is almost complex: at a point `x` of the six-sphere (`|x|² = 1`) and
for a tangent arrow `v` (`x · v = 0`), the turned arrow `J v = x × v` is again tangent, has
the same length as `v`, and turning twice reverses `v`: `x × (x × v) = −v`. -/
theorem octonion_rule_squares_to_neg_one (x v : Fin 7 → ℝ) (hx : x ⬝ᵥ x = 1)
    (hv : x ⬝ᵥ v = 0) :
    octCross x (octCross x v) = -v ∧ x ⬝ᵥ octCross x v = 0 ∧
      octCross x v ⬝ᵥ octCross x v = v ⬝ᵥ v := by
  refine ⟨?_, dot_octCross_self x v, ?_⟩
  · rw [octCross_octCross_self, hx, hv]; simp
  · rw [octCross_dot_octCross, hx, hv]; ring

/-- The closed form of the Nijenhuis tensor: at a point `x` of the six-sphere and for tangent
arrows `X`, `Y` there, `N_J(X, Y) = −4 x × (X × Y)`. -/
theorem nijenhuis_eq_neg_four_cross (x X Y : Fin 7 → ℝ) (hx : x ⬝ᵥ x = 1)
    (hX : x ⬝ᵥ X = 0) (hY : x ⬝ᵥ Y = 0) :
    nijenhuisOct x X Y = (-4 : ℝ) • octCross x (octCross X Y) := by
  rw [nijenhuisOct_eq, hX, hY]; simp

/-- The octonion rule is not complex: at a point `x` of the six-sphere, for unit tangent
arrows `X`, `Y` with `Y` perpendicular to both `X` and `J X = x × X`, the Nijenhuis tensor
has squared length 16 (length 4), so it is not zero. -/
theorem nijenhuis_sq_length_eq_sixteen (x X Y : Fin 7 → ℝ) (hx : x ⬝ᵥ x = 1)
    (hX : x ⬝ᵥ X = 0) (hY : x ⬝ᵥ Y = 0) (hXX : X ⬝ᵥ X = 1) (hYY : Y ⬝ᵥ Y = 1)
    (hXY : X ⬝ᵥ Y = 0) (hJXY : octCross x X ⬝ᵥ Y = 0) :
    nijenhuisOct x X Y ⬝ᵥ nijenhuisOct x X Y = 16 := by
  rw [nijenhuis_eq_neg_four_cross x X Y hx hX hY, smul_dotProduct, dotProduct_smul,
    octCross_dot_octCross, octCross_dot_octCross, hx, hXX, hYY, hXY, dot_octCross_eq, hJXY]
  simp; norm_num

-- The table: e₁e₂ = e₄.
example : octCross (![1, 0, 0, 0, 0, 0, 0] : Fin 7 → ℚ) ![0, 1, 0, 0, 0, 0, 0]
    = ![0, 0, 0, 1, 0, 0, 0] := by
  ext i; fin_cases i <;> simp [octCross]

-- The card's point x = (2/7, 3/7, 6/7, 0, 0, 0, 0) is on the sphere, and the arrow
-- v = (3, −2, 0, 1, 0, 0, 0) is tangent there, with squared length 14.
example : (![2/7, 3/7, 6/7, 0, 0, 0, 0] : Fin 7 → ℚ) ⬝ᵥ ![2/7, 3/7, 6/7, 0, 0, 0, 0] = 1 ∧
    (![2/7, 3/7, 6/7, 0, 0, 0, 0] : Fin 7 → ℚ) ⬝ᵥ ![3, -2, 0, 1, 0, 0, 0] = 0 ∧
    (![3, -2, 0, 1, 0, 0, 0] : Fin 7 → ℚ) ⬝ᵥ ![3, -2, 0, 1, 0, 0, 0] = 14 := by
  simp [dotProduct, Fin.sum_univ_seven]; norm_num

-- One turn: J v = x × v = (3/7, −2/7, 0, −13/7, 12/7, 6/7, −18/7).
example : octCross (![2/7, 3/7, 6/7, 0, 0, 0, 0] : Fin 7 → ℚ) ![3, -2, 0, 1, 0, 0, 0]
    = ![3/7, -2/7, 0, -13/7, 12/7, 6/7, -18/7] := by
  ext i; fin_cases i <;> simp [octCross] <;> norm_num

-- Two turns: x × (x × v) = (−3, 2, 0, −1, 0, 0, 0) = −v.
example : octCross (![2/7, 3/7, 6/7, 0, 0, 0, 0] : Fin 7 → ℚ)
    (octCross ![2/7, 3/7, 6/7, 0, 0, 0, 0] ![3, -2, 0, 1, 0, 0, 0])
    = ![-3, 2, 0, -1, 0, 0, 0] := by
  ext i; fin_cases i <;> simp [octCross] <;> norm_num

-- The Nijenhuis tensor at x for X = e₄, Y = e₅ is (−24/7, 0, 8/7, 0, 0, 12/7, 0),
-- of squared length 16.
example : nijenhuisOct (![2/7, 3/7, 6/7, 0, 0, 0, 0] : Fin 7 → ℚ) ![0, 0, 0, 1, 0, 0, 0]
    ![0, 0, 0, 0, 1, 0, 0] = ![-24/7, 0, 8/7, 0, 0, 12/7, 0] := by
  ext i; fin_cases i <;>
    simp [nijenhuisOct, turnRate, octCross, dotProduct, Fin.sum_univ_seven] <;> norm_num

example : (![-24/7, 0, 8/7, 0, 0, 12/7, 0] : Fin 7 → ℚ) ⬝ᵥ ![-24/7, 0, 8/7, 0, 0, 12/7, 0]
    = 16 := by
  simp [dotProduct, Fin.sum_univ_seven]; norm_num

-- The seven-dimensional product breaks the Jacobi identity: for e₁, e₂, e₃ the sum
-- e₁ × (e₂ × e₃) + e₂ × (e₃ × e₁) + e₃ × (e₁ × e₂) is 3e₆.
example : octCross (![1, 0, 0, 0, 0, 0, 0] : Fin 7 → ℚ)
      (octCross ![0, 1, 0, 0, 0, 0, 0] ![0, 0, 1, 0, 0, 0, 0])
    + octCross ![0, 1, 0, 0, 0, 0, 0] (octCross ![0, 0, 1, 0, 0, 0, 0] ![1, 0, 0, 0, 0, 0, 0])
    + octCross ![0, 0, 1, 0, 0, 0, 0] (octCross ![1, 0, 0, 0, 0, 0, 0] ![0, 1, 0, 0, 0, 0, 0])
    = ![0, 0, 0, 0, 0, 3, 0] := by
  ext i; fin_cases i <;> norm_num [octCross]

-- What breaks, off the sphere: at 2x, turning v twice gives (−12, 8, 0, −4, 0, 0, 0) = −4v.
example : octCross (![4/7, 6/7, 12/7, 0, 0, 0, 0] : Fin 7 → ℚ)
    (octCross ![4/7, 6/7, 12/7, 0, 0, 0, 0] ![3, -2, 0, 1, 0, 0, 0])
    = ![-12, 8, 0, -4, 0, 0, 0] := by
  ext i; fin_cases i <;> simp [octCross] <;> norm_num

-- What breaks, not tangent: for v = e₁ at x, turning twice gives
-- (−45/49, 6/49, 12/49, 0, 0, 0, 0), not −e₁.
example : octCross (![2/7, 3/7, 6/7, 0, 0, 0, 0] : Fin 7 → ℚ)
    (octCross ![2/7, 3/7, 6/7, 0, 0, 0, 0] ![1, 0, 0, 0, 0, 0, 0])
    = ![-45/49, 6/49, 12/49, 0, 0, 0, 0] := by
  ext i; fin_cases i <;> simp [octCross] <;> norm_num

-- The sphere test of Step 4: for n from 1 to 8, the Euler number 2 is a multiple of
-- (n − 1)! exactly for n = 1, 2, 3 (the spheres S², S⁴, S⁶).
example : (List.range' 1 8).filter (fun n => 2 % (n - 1).factorial == 0) = [1, 2, 3] := by
  decide

#print axioms octonion_rule_squares_to_neg_one
#print axioms nijenhuis_eq_neg_four_cross
#print axioms nijenhuis_sq_length_eq_sixteen
```

**Checked 2026-11-24 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'octCross_octCross_self' depends on axioms: [propext, Classical.choice, Quot.sound]
'dot_octCross_self' depends on axioms: [propext, Classical.choice, Quot.sound]
'octCross_dot_octCross' depends on axioms: [propext, Classical.choice, Quot.sound]
'dot_octCross_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'octCross_anti' depends on axioms: [propext, Classical.choice, Quot.sound]
'octCross_self' depends on axioms: [propext, Classical.choice, Quot.sound]
'octCross_sub_smul' depends on axioms: [propext, Classical.choice, Quot.sound]
'octCross_neg' depends on axioms: [propext, Classical.choice, Quot.sound]
'octCross_polar' depends on axioms: [propext, Classical.choice, Quot.sound]
'dot_octCross_octCross' depends on axioms: [propext, Classical.choice, Quot.sound]
'nijenhuisOct_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'octonion_rule_squares_to_neg_one' depends on axioms: [propext, Classical.choice, Quot.sound]
'nijenhuis_eq_neg_four_cross' depends on axioms: [propext, Classical.choice, Quot.sound]
'nijenhuis_sq_length_eq_sixteen' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **A different tangent pair.** Guess first: what is $`\lvert N_J\rvert^2`$ for $`X = e_4`$, $`Y = e_6`$ at $`x`$? Change `E[4]` to `E[5]` in the line `X, Y = E[3], E[4]`. Answer: the three roads still agree, on squared length 208/49, not 16, because $`e_6`$ is not perpendicular to $`JX`$ there; the assert on 16 stops the run.
> - **Break the table.** Guess first: does $`J^2 = -1`$ survive a made-up product? Change `(i + 3) % 7` to `(i + 2) % 7`. Answer: no; the length rule fails on some pairs and the first assert stops the run.
> - **A wrong constant.** Guess first: is the closed form's factor really −4? Change `sc(-4,` to `sc(-2,`. Answer: the brackets road and the closed form disagree, and the assert stops the run.

---

## The usual mistake

> [!warning]
> **Reading "almost complex" as "complex".** The octonion rule passes $`J^2 = -1`$ at every point, yet $`\lvert N_J\rvert^2 = 16`$ on unit perpendicular arrows, so no complex coordinates fit it. The 2026 claims are about a different J, built from scratch.
>
> - **Taking LeBrun's theorem as a no.** It forbids only structures that keep round lengths. The 2026 structures bend lengths, so there is no conflict.
> - **Upgrading the claim.** A self-contained preprint by an independent mathematician is strong evidence, but in this wing it is still "claimed" until refereed or independently accepted. The status as of 2026-11-24 is claimed.
> - **Expecting a Kähler six-sphere.** $`S^6`$ has no second cohomology, so no Kähler form, for any complex structure.
> - **Checking one pair.** $`N_J`$ is 0 for $`Y = JX`$; at $`e_1`$, 3 of 15 pairs give 0. The other 12 give 16.

---

## Where you meet it in real life

- **Symmetry groups.** The symmetries of the octonions form the 14-dimensional group $`G_2`$. It moves $`S^6`$ onto itself and keeps the octonion J, which makes $`S^6`$ the standard example of a space with this kind of rule.
- **String theory.** Seven-dimensional spaces of $`G_2`$ type are candidate shapes for the extra dimensions of M-theory. The cone over the octonion $`S^6`$, which is flat seven-dimensional space, is the simplest model case.
- **Textbooks on complex geometry.** The Hopf problem has long been the stock example of a question that the integrability test states and that topology cannot settle.
- **Machine help in research.** The first 2026 manuscript was produced by an AI system under a mathematician's direction and then checked and rewritten by others. [Machines that prove](../07-Physics%2C%20Finance%20and%20Machines/02-ai-and-mathematics-2026.md) lists how to audit such a claim.

> **Say it back**
> An almost complex structure is a quarter-turn rule J on every tangent plane, with J twice equal to minus the identity. On the six-sphere, crossing with the point in octonion arithmetic gives one, and exact arithmetic confirms $`J^2 = -1`$. It comes from complex coordinates exactly when the Nijenhuis tensor is zero, and for the octonion rule that tensor has length 4 on unit perpendicular arrows. Only $`S^2`$ and $`S^6`$ are almost complex spheres, and LeBrun ruled out a complex $`S^6`$ that keeps round lengths. In 2026 a complex $`S^6`$ built from a family of complex tori was claimed, given an independent self-contained proof, and extended, but as of 2026-11-24 it is not refereed.

---

## What this builds on

- [The Poincare conjecture, solved](../02-The%20Millennium%20Problems/07-poincare-conjecture-solved.md): Smale's high-dimensional result, used to recognise the 2026 threefold as a sphere.
- [Complex manifolds and Kahler forms](../../22-Algebraic%20geometry/05-Cohomology%20and%20the%20Hodge%20Conjecture/04-complex-manifolds-and-kahler-forms.md): complex charts, the Riemann sphere, and the Kähler forms $`S^6`$ cannot carry.
- [Sphere, torus and projective plane](../../23-Differential%20geometry%20and%20Lie%20groups/03-Manifolds/02-example-manifolds-sphere-torus-and-projective-space.md): spheres as manifolds with tangent spaces.
- [Lie bracket](../../23-Differential%20geometry%20and%20Lie%20groups/03-Manifolds/08-lie-brackets-and-frobenius-theorem.md): the swap gap inside the Nijenhuis tensor, and Frobenius's bracket test.
- [Chern-Weil](../../23-Differential%20geometry%20and%20Lie%20groups/06-Lie%20Groups/13-chern-weil-theory-and-characteristic-classes.md): Chern classes and the Euler number used in the sphere test.
- [Sphere packing, solved in dimensions 8 and 24](06-sphere-packing-and-viazovska.md): another dimension made special by an exceptional structure; there the E8 lattice, here the octonions.

## Where this goes next

- [The smooth Poincare conjecture in dimension four](11-smooth-four-dimensional-poincare-conjecture.md): the one dimension where "a topological sphere is the standard sphere" is still open; in dimension 6 it is settled, which the 2026 proof uses.
- [Caratheodory's conjecture](09-caratheodory-conjecture.md): another shelf problem about curved surfaces in space.
- [The status register](../07-Physics%2C%20Finance%20and%20Machines/05-the-status-register.md): the wing's ledger, where this claim belongs with its date and source.

The question this card leaves open: will the 2026 construction be refereed and accepted, and how large is the space of complex structures on $`S^6`$?

---

## Sources

Verified 2026-11-24: every link below resolves to the publisher's page.

- Borel, A., and J.-P. Serre. "Groupes de Lie et puissances réduites de Steenrod." *American Journal of Mathematics* 75 (1953), 409–448. [doi:10.2307/2372495](https://doi.org/10.2307/2372495). Proves that only $`S^2`$ and $`S^6`$ among spheres are almost complex.
- Newlander, A., and L. Nirenberg. "Complex analytic coordinates in almost complex manifolds." *Annals of Mathematics* 65 (1957), 391–404. [doi:10.2307/1970051](https://doi.org/10.2307/1970051). Proves that a zero Nijenhuis tensor gives complex coordinates.
- LeBrun, C. "Orthogonal complex structures on $`S^6`$." *Proceedings of the American Mathematical Society* 101 (1987), 136–138. [doi:10.1090/S0002-9939-1987-0897084-7](https://doi.org/10.1090/S0002-9939-1987-0897084-7). No complex structure on $`S^6`$ keeps the round sphere's lengths.
- Engel, P. "Complex structures on $`S^6`$." Preprint, arXiv:2609.38442, posted 2026-09-29. [arXiv page](https://arxiv.org/abs/2609.38442). A self-contained proof of the 2026 construction; the source of Step 6.
- Viaclovsky, J. "A two-parameter family of complex structures on $`S^6`$." Preprint, arXiv:2609.33785, posted 2026-09-27. [arXiv page](https://arxiv.org/abs/2609.33785). A further family, shown not equivalent to the first examples.
