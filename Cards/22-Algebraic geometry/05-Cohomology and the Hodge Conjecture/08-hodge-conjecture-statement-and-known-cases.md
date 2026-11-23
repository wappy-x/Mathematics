# The Hodge conjecture: every rational class of type p and p comes from a cycle

[Syllabus](../../../SYLLABUS.md) → [Algebraic geometry](../README.md) → [Cohomology and the Hodge Conjecture](../README.md#s05) → The Hodge conjecture

---

## General Overview

Take the surface $`x^4 + y^4 + z^4 + w^4 = 0`$ in complex projective space $`\mathbb{P}^3`$, the **Fermat quartic**. It is a smooth quartic surface, and every smooth quartic surface is a **K3 surface**: a compact complex surface with no holes of dimension 1 and a nowhere-zero 2-form.

Its second cohomology has 22 independent directions: 22 independent ways a closed two-dimensional film can sit inside it ([De Rham cohomology](02-de-rham-cohomology-of-varieties.md)). Some directions are reached by curves drawn on the surface itself. The Fermat quartic contains 48 straight lines, and the check below finds that they span 20 directions, no more.

Hodge theory sorts these directions by **type**: a pair of numbers (p, q) saying how many factors $`dz`$ and how many factors $`d\bar z`$ the forms of a class carry ([Hodge decomposition](05-hodge-decomposition.md)). A curve only ever reaches type (1, 1), and only 20 of the 22 directions have that type. So no curve can reach more than 20, and on this surface the type test and the curves agree exactly. The count of directions that curves reach is the **Picard number** $`\rho`$, and here $`\rho = 20`$.

A very general quartic surface (one outside countably many special families) holds no lines. Its curves reach one direction only, the plane sections, so $`\rho = 1`$, although the type test still allows 20. What separates the two surfaces is not the type alone but which *rational* classes have that type.

The Hodge conjecture says the type test, applied to rational classes, is the whole story, in every degree and every dimension.

**On a smooth complex projective variety, every cohomology class with rational coefficients that has type (p, p) should be a rational combination of classes of subvarieties of codimension p; for p = 1 this is Lefschetz's theorem, and on a K3 surface it makes the Picard number the rank of the group of integer classes of type (1, 1).**

**What kind of fact this is:** a conjecture, unproved as of 2026-11-17, and one of the Clay Millennium Problems. The case p = 1 is a theorem, sketched on this card in Why it works; p = n − 1 follows from it, so every variety of dimension at most 3 satisfies the conjecture. With integer coefficients in place of rational ones the statement is false. The value $`\rho = 20`$ for the Fermat quartic is computed by the checks.

### The picture: what the type test allows, and what curves reach

```
b2, all classes in H^2               ######################   22
h^1,1, the type-(1,1) dimension      ####################     20
rho, Fermat quartic (48 lines)       ####################     20
rho, very general quartic            #                         1
```

One mark per dimension. The first three bars are printed by the checks; the last is a quoted theorem (Noether–Lefschetz). The gap between the second and fourth bars is why the conjecture asks only about rational classes, not about every class of type (1, 1).

---

## The formula

Notation first, in words. $`X`$ is a **smooth projective variety** over $`\mathbb{C}`$: the common zeros of homogeneous polynomials in some $`\mathbb{P}^N`$, with no singular points, of complex dimension $`n`$. Its cohomology $`H^k(X, \mathbb{Q})`$ is the space of k-dimensional cohomology classes with rational coefficients ([Cohomology and the cup product in outline](../../17-Topology/05-Homology/08-cohomology-and-cup-product-in-outline.md)).

[Hodge decomposition](05-hodge-decomposition.md) splits the complex cohomology by type: $`H^k(X, \mathbb{C}) = \bigoplus_{p+q=k} H^{p,q}(X)`$, where a class of **type (p, q)** is carried by forms with p copies of $`dz`$ and q copies of $`d\bar z`$. Its dimensions are the Hodge numbers $`h^{p,q}`$.

This card introduces two symbols. $`\mathrm{Hdg}^p(X)`$ is the space of **Hodge classes**: rational classes in degree 2p that have type (p, p). $`\rho(X)`$ is the **Picard number**, the dimension of $`\mathrm{Hdg}^1(X)`$.

```math
\mathrm{Hdg}^p(X) = H^{2p}(X, \mathbb{Q}) \cap H^{p,p}(X) \overset{?}{=} \Big\{ \textstyle\sum_i q_i\,[W_i] \;:\; q_i \in \mathbb{Q},\ W_i \subset X \text{ a subvariety of codimension } p \Big\}
```

**Read it aloud:** the Hodge classes of degree 2p are the rational classes that have type p, p; the conjecture asks whether each of them is a rational combination of classes of subvarieties of codimension p.

The inclusion from right to left is known: every cycle class is rational and of type (p, p) ([Algebraic cycles](07-algebraic-cycles-and-cycle-classes.md)). The conjecture is the inclusion from left to right.

For p = 1 it is a theorem, and it even holds with integers:

```math
H^2(X, \mathbb{Z}) \cap H^{1,1}(X) = \{\, c_1(\mathcal{O}(D)) \,\}, \qquad \rho(X) = \mathrm{rank}\,\{\, c_1(\mathcal{O}(D)) \,\} = \dim \mathrm{Hdg}^1(X)
```

**Read it aloud:** an integer class in degree 2 has type 1, 1 exactly when it is the first Chern class of a line bundle, that is, the class of a divisor; the Picard number is the rank of the group of these classes.

On a K3 surface the (2, 0) part is one line, spanned by the class of a nowhere-zero 2-form $`\sigma`$. A real class has type (1, 1) exactly when its (2, 0) part is zero, which is one test:

```math
\alpha \in H^2(X, \mathbb{Z}) \text{ has type } (1,1) \iff \int_X \alpha \wedge \sigma = 0, \qquad 1 \le \rho(X) \le h^{1,1} = 20
```

**Read it aloud:** an integer class on a K3 surface has type 1, 1 when its integral against sigma is zero; the Picard number lies between 1 and 20.

For most quartics only the multiples of the plane class pass, giving $`\rho = 1`$. On special ones, such as the Fermat quartic, many integer classes pass.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $`X`$, $`n`$, $`\mathbb{P}^N`$ | a smooth projective variety over $`\mathbb{C}`$; its complex dimension; the projective space it sits in | the Fermat quartic, n = 2 | at n ≤ 3 the conjecture is a theorem |
| $`H^k(X, \mathbb{Q})`$, $`H^k(X, \mathbb{Z})`$, $`b_k`$, $`\alpha`$ | cohomology with rational or integer coefficients; the Betti number, the dimension of $`H^k`$; one class in it | $`b_2 = 22`$ | — |
| $`H^{p,q}`$, $`h^{p,q}`$ | the classes of type (p, q); their dimension | $`h^{2,0}, h^{1,1}, h^{0,2}`$ = 1, 20, 1 | a bigger $`h^{1,1}`$ allows a bigger ρ |
| $`p`$, $`\mathrm{Hdg}^p(X)`$ | the codimension; rational classes of type (p, p) in degree 2p | p = 1 | — |
| $`W`$, $`[W]`$, $`q_i`$ | a subvariety; its cycle class; the rational weights in a combination of cycle classes | a line on the quartic | — |
| $`D`$, $`\mathcal{O}(D)`$, $`\mathcal{L}`$, $`c_1`$ | a divisor, a combination of curves on a surface; its line bundle; any line bundle; the first Chern class, which turns a line bundle into a class in $`H^2`$ (see the fold for $`\mathcal{O}_X`$, $`\mathcal{O}_X^*`$ and Pic) | $`c_1(\mathcal{O}(L)) = [L]`$ | — |
| $`\rho(X)`$ | the Picard number: the dimension of $`\mathrm{Hdg}^1`$ | 20 on the Fermat quartic; 1 on a very general quartic | at most $`h^{1,1}`$ |
| $`\sigma`$ | the nowhere-zero 2-form of a K3 surface; it spans $`H^{2,0}`$ | one per surface, up to scale | — |
| $`L`$, $`L \cdot L'`$, $`g`$ | a line on the surface; the intersection number of two curves; a curve's genus | $`L \cdot L = -2`$; two lines meet in 1 point or 0 | — |
| $`h`$ | the plane class: the class of a plane section | $`h^2 = 4`$, $`h \cdot L = 1`$ | — |
| $`\zeta`$, $`a`$, $`b`$ | $`\zeta = e^{i\pi/4}`$, a primitive 8th root of unity; numbers with $`a^4 = b^4 = -1`$ | $`a \in \{\zeta, \zeta^3, \zeta^5, \zeta^7\}`$ | — |
| $`d`$, $`\ell`$ | the degree of a hypersurface; the class of degree 1 in $`H^4`$ of a threefold | d = 125 | — |

The $`h`$ here is the plane class from [Cohomology of projective space](03-cohomology-of-projective-space.md), not a Hodge number; Hodge numbers always carry two superscripts.

### When it holds

- **Projective, not just Kähler.** On a compact complex torus that is not projective, Hodge classes need not come from subvarieties; the conjecture is stated only for projective varieties.
- **Rational coefficients.** With integer coefficients it fails: Atiyah and Hirzebruch found torsion classes that come from no cycle (1962), and Kollár found non-torsion ones (1992). Mistake 4 below shows Kollár's degree-125 threefold.
- **Type (p, p).** A cycle class always has type (p, p), so a rational class of any other type can never be algebraic. Dropping the type test would call all 22 rational classes on the quartic algebraic; only 20 are.
- **Smooth and over $`\mathbb{C}`$.** Hodge types need the complex structure of a smooth variety. Over a finite field the analogous statement is the Tate conjecture, a different problem.

---

## Why it works

### Step 0: a subvariety only sees forms of its own type

A subvariety $`W`$ of codimension p has complex dimension n − p. Integrating a form over W keeps only the form's restriction to W.

A form with more than n − p copies of $`dz`$ restricts to zero on W, because W has only n − p complex directions. The same holds for $`d\bar z`$. So W pairs to zero with every form except those of type (n − p, n − p). By duality its class $`[W]`$ has type (p, p). It is also an integer class, since W is a cycle. So every cycle class is a Hodge class.

The Hodge conjecture asks for the converse. Step 1 proves it for p = 1.

### Step 1: in degree 2, line bundles turn type into existence

The proof runs through line bundles ([Line bundles and divisors](06-line-bundles-and-divisor-classes.md)).

1. Every line bundle has a first Chern class in $`H^2(X, \mathbb{Z})`$, and it has type (1, 1).
2. An integer class $`c`$ is a first Chern class exactly when its image in $`H^{0,2}`$ is zero. This comes from the exponential map $`f \mapsto e^{2\pi i f}`$, which links functions, nonzero functions and integers.
3. For a real class, the (0, 2) part is the mirror image of the (2, 0) part. So "image zero in $`H^{0,2}`$" is the same as "type (1, 1)".
4. On a projective variety every line bundle has a meromorphic section. Its zeros minus its poles form a divisor $`D`$, and $`c = [D]`$.

So every integer class of type (1, 1) is the class of a divisor. Rational classes follow by clearing denominators.


<details>
<summary>Detailed proof: the exponential sequence and Lefschetz's (1, 1) theorem</summary>

Write $`\mathcal{O}_X`$ for the holomorphic functions on $`X`$ and $`\mathcal{O}_X^*`$ for the nowhere-zero ones ([Sheaves](01-sheaves-in-outline.md)). The map $`f \mapsto e^{2\pi i f}`$ sends $`\mathcal{O}_X`$ onto $`\mathcal{O}_X^*`$ locally, and its kernel is the constant integers. That gives a short exact sequence of sheaves and, from it, a long exact sequence in cohomology. The part that matters is:

$`\displaystyle H^1(X, \mathcal{O}_X^*) \xrightarrow{\;c_1\;} H^2(X, \mathbb{Z}) \longrightarrow H^2(X, \mathcal{O}_X).`$

Line bundles up to isomorphism are $`H^1(X, \mathcal{O}_X^*) = \mathrm{Pic}(X)`$, and the first arrow is the first Chern class. Exactness says a class in $`H^2(X, \mathbb{Z})`$ is some $`c_1`$ exactly when it dies in $`H^2(X, \mathcal{O}_X)`$.

By the Hodge decomposition, $`H^2(X, \mathcal{O}_X) = H^{0,2}(X)`$, and the second arrow is projection to the (0, 2) part. An integer class is real, and complex conjugation swaps $`H^{2,0}`$ and $`H^{0,2}`$. So its (0, 2) part is zero exactly when its (2, 0) part is zero, that is, when it has type (1, 1).

Finally, on a projective variety, for a line bundle $`\mathcal{L}`$ and a large enough m, both $`\mathcal{L} \otimes \mathcal{O}(m)`$ and $`\mathcal{O}(m)`$ have nonzero holomorphic sections, s and t. The ratio s/t is a meromorphic section of $`\mathcal{L}`$, and its divisor $`D = Z_+ - Z_-`$ has $`c_1(\mathcal{L}) = [Z_+] - [Z_-]`$. Chow's theorem makes $`Z_\pm`$ algebraic.

</details>

### Step 2: one step down from the top degree, by hard Lefschetz

The **hard Lefschetz theorem** says that multiplying by the plane class $`n - 2`$ times is an isomorphism from $`H^2(X, \mathbb{Q})`$ to $`H^{2n-2}(X, \mathbb{Q})`$, and it respects types. So every Hodge class of degree 2n − 2 is $`h^{n-2}`$ times a Hodge class of degree 2.

By Step 1 that degree-2 class is a rational combination of divisors D. Multiplying $`[D]`$ by $`h^{n-2}`$ gives the class of D cut by n − 2 general planes, which is a curve. So p = n − 1 holds with rational coefficients.

The cases p = 0 and p = n hold trivially: the whole variety and a point. On a variety of dimension at most 3, every p is 0, 1, n − 1 or n, so the conjecture holds there.

### Step 3: the type test on a K3 surface, counted

For the quartic surface, the Hodge numbers come from counting monomials. Griffiths' theorem, quoted from Voisin, identifies the primitive pieces of $`H^2`$ with parts of degree 0, 4 and 8 of the ring $`\mathbb{C}[x, y, z, w] / (x^3, y^3, z^3, w^3)`$; the relations are the partial derivatives of the Fermat equation, divided by 4.

A monomial survives when each exponent is at most 2. There are 1, 19 and 1 of them in degrees 0, 4 and 8. Adding the plane class h to the middle count gives:

```math
h^{2,0} = 1, \qquad h^{1,1} = 19 + 1 = 20, \qquad h^{0,2} = 1, \qquad b_2 = 22
```

**Read it aloud:** one class of type two, zero; twenty of type one, one; one of type zero, two; twenty-two in all.

A second road gives the same numbers. A smooth quartic surface has Euler number $`4^3 - 4 \cdot 4^2 + 6 \cdot 4 = 24`$ and signature $`(4 - 4^2) \cdot 4/3 = -16`$, both standard formulas quoted from Huybrechts. With $`b_0 = b_4 = 1`$ and $`b_1 = b_3 = 0`$, $`b_2 = 22`$. The Hodge index theorem writes the signature as $`2 + 2h^{2,0} - h^{1,1} = 2 + 2 - 20 = -16`$. Both roads agree.

So $`\rho \le 20`$ on every quartic surface. Whether $`\rho`$ reaches 20 depends on the surface.

### Step 4: the cycle side, from 48 lines

The Fermat quartic contains lines. Set $`x = a y`$ and $`z = b w`$ with $`a^4 = b^4 = -1`$. Then $`x^4 + y^4 + z^4 + w^4 = (a^4 + 1) y^4 + (b^4 + 1) w^4 = 0`$ for every y and w. There are 4 choices of a, 4 of b, and 3 ways to pair the four coordinates, so 3 × 16 = 48 lines.

Each line $`L`$ is a copy of $`\mathbb{P}^1`$, a sphere. On a K3 surface the canonical class is zero, so adjunction gives $`L \cdot L = 2g - 2 = -2`$, with genus g = 0. Two different lines meet in one point or not at all. They meet exactly when their four defining linear forms are dependent, which is a 4 × 4 determinant equal to zero. The check computes every determinant exactly, in whole numbers combined with powers of $`\zeta = e^{i\pi/4}`$.

Each line meets 14 others. The 48 × 48 matrix of intersection numbers has rank 20, by exact integer elimination. Intersection numbers depend only on classes, so the 48 classes span at least 20 dimensions of $`\mathrm{Hdg}^1`$. With Step 3:

```math
20 \le \rho(\text{Fermat quartic}) \le h^{1,1} = 20, \qquad \text{so } \rho = 20
```

**Read it aloud:** the lines give at least twenty, the type test allows at most twenty, so the Picard number is exactly twenty.

On this surface, every Hodge class in degree 2 is a rational combination of lines. That is the conjecture for p = 1, seen in numbers.

### Step 5: two consistency checks on the lines

**The plane class.** The plane $`x = a y`$ cuts the surface in $`z^4 + w^4 = 0`$, which is four lines through one point. So h is the sum of those four lines. Its square is $`4 \times (-2) + 2 \times 6 = 4`$, the degree of the surface, since the four lines meet in 6 pairs. All 24 such planes give the same row of intersection numbers, and $`h \cdot L = 1`$ for every line: each line has degree 1.

**The Hodge index theorem.** It says the intersection form on $`\mathrm{Hdg}^1`$ of a surface has exactly one positive direction. On 20 independent lines the check finds signature (1, 19) and determinant −64.

### Step 6: why the conjecture needs ℚ, not ℤ

For p ≥ 2 the integer version fails.

- **Torsion.** Atiyah and Hirzebruch (1962) found varieties with a torsion class in $`H^4(X, \mathbb{Z})`$, a class that is zero when multiplied by some whole number, that comes from no cycle. Torsion is invisible over ℚ.
- **Not torsion.** Kollár (1992) took a very general hypersurface $`X`$ of degree 125 in $`\mathbb{P}^4`$. Its $`H^4(X, \mathbb{Z})`$ is one copy of ℤ, generated by a class $`\ell`$ of degree 1, and all of it has type (2, 2). Kollár proved that every curve on X has degree a multiple of 5. So $`\ell`$ is no curve's class. But $`h^2 = 125\,\ell`$ is the class of a plane section of a plane section, so $`\ell = h^2/125`$ is algebraic over ℚ.

Hodge first stated the conjecture over ℤ. These examples are why the modern statement uses ℚ.

### Step 7: what is known, and why p ≥ 2 is hard

Known, with rational coefficients:

- p = 0, 1, n − 1, n, for every smooth projective variety (Steps 1 and 2), so all of dimension at most 3.
- Some special families, case by case: certain abelian varieties and certain Fermat hypersurfaces, where the Hodge classes can be built from divisors or from explicit cycles.

Step 1 had a machine: the exponential map turns a type condition into a line bundle, and a line bundle into a divisor. In codimension 2 and higher no such machine is known, and no general method builds a subvariety from a cohomology class. Deligne's official problem description notes that it is not known even for the Künneth pieces of the diagonal of $`X \times X`$: the parts of the diagonal's class that split into a class of X times a class of X.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| monomials of degree 4, exponents ≤ 2 | coefficient of $`t^4`$ in $`(1 + t + t^2)^4`$ | 19 |
| Hodge numbers | 1, 19 + 1, 1 | $`h^{2,0}, h^{1,1}, h^{0,2}`$ = 1, 20, 1 |
| Euler number | 64 − 64 + 24 | 24, so $`b_2`$ = 22 |
| signature | 2 + 2 × 1 − 20 | −16 |
| lines | 3 pairings × 4 × 4 | 48 |
| self-intersection | 2 × 0 − 2 | −2 |
| plane class | 4 × (−2) + 2 × 6 | $`h^2`$ = 4 |
| rank of the 48 × 48 matrix | exact elimination | 20 |
| Picard number | 20 ≤ ρ ≤ 20 | **ρ = 20** |

All 20 type-(1, 1) directions of the Fermat quartic are reached by its lines, so the Hodge conjecture for p = 1 holds there in the most visible way.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| A line meets itself once, as in the plane | rank 48, more than $`b_2`$ = 22 | on a K3 surface $`L \cdot L = -2`$; the impossible rank exposes the error |
| Every rational class in $`H^2`$ is algebraic | 22 claimed; ρ = 20 | the two classes with (2, 0) and (0, 2) parts fail the type test |
| Every class of type (1, 1) is algebraic | 20 claimed; ρ = 1 on a very general quartic (quoted) | type (1, 1) must be met by a rational class |
| Integer coefficients | degree 125 threefold: $`\ell`$ has degree 1, curves have degrees 5, 10, 15, …; $`\ell = h^2/125`$ | holds over ℚ only (Kollár) |

The ρ = 1 and Kollár's divisibility are quoted theorems; the check prints the arithmetic around them.

---

## Code, from first principles, and it actually runs

Three independent roads meet at ρ = 20 on the Fermat quartic. Road 1 is the Hodge side: Hodge numbers by counting monomials, against the Euler number and the signature. Road 2 is the cycle side: the 48 lines, which pairs meet by exact 4 × 4 determinants in whole numbers with powers of ζ, and the rank of their intersection matrix by fraction-free elimination. Road 3 builds the plane class from four lines in 24 different ways and gets one class with $`h^2 = 4`$.

### Python

```python
# The Hodge conjecture in degree 2, on a K3 surface -- the check behind the card.
# Standard library only.  The Fermat quartic x^4 + y^4 + z^4 + w^4 = 0 in P^3:
#   road 1 (Hodge side): h^(p,q) by counting monomials, against the Euler number and the signature
#   road 2 (cycle side): its 48 lines, which pairs meet (exact 4 x 4 determinants over Z[zeta]),
#                        and the rank of their intersection matrix, by exact integer elimination
#   road 3 (one class two ways): 24 plane sections, four lines each, all give the plane class h
from itertools import permutations, product

def zmul(a, b):                   # Z[t]/(t^4 + 1): t = zeta, a primitive 8th root of unity
    r = [0] * 8
    for i in range(4):
        for j in range(4):
            r[i + j] += a[i] * b[j]
    return tuple(r[k] - r[k + 4] for k in range(4))

ZERO, ONE, ZETA = (0, 0, 0, 0), (1, 0, 0, 0), (0, 1, 0, 0)

def zdet(m):                      # 4 x 4 determinant over Z[zeta], one term per permutation
    total = ZERO
    for p in permutations(range(4)):
        sign = (-1) ** sum(p[i] > p[j] for i in range(4) for j in range(i + 1, 4))
        term = ONE
        for i in range(4):
            term = zmul(term, m[i][p[i]])
        total = tuple(t + sign * x for t, x in zip(total, term))
    return total

def bareiss(m):                   # fraction-free elimination: (rank, signed determinant if square)
    m, prev, r, sign = [row[:] for row in m], 1, 0, 1
    for c in range(len(m[0])):
        p = next((i for i in range(r, len(m)) if m[i][c] != 0), None)
        if p is None:
            continue
        if p != r:
            m[r], m[p], sign = m[p], m[r], -sign
        for i in range(r + 1, len(m)):
            for j in range(c + 1, len(m[0])):
                m[i][j] = (m[r][c] * m[i][j] - m[i][c] * m[r][j]) // prev
            m[i][c] = 0
        prev, r = m[r][c], r + 1
    full = r == len(m) == len(m[0])
    return r, sign * prev if full else 0

# ---- road 1: Hodge numbers of a smooth quartic surface ----
d = 4
jac = [sum(1 for e in product(range(d - 1), repeat=4) if sum(e) == k) for k in (0, 4, 8)]
h20, h11, h02 = jac[0], jac[1] + 1, jac[2]          # degree 0, 4, 8 of C[x,y,z,w]/(x^3, y^3, z^3, w^3); +1 is h
euler, sig = d ** 3 - 4 * d ** 2 + 6 * d, (4 - d * d) * d // 3
b2 = euler - 2                                       # b0 = b4 = 1, b1 = b3 = 0
print("road 1, the Hodge side of a smooth quartic surface (a K3 surface)")
print(f"monomials with exponents at most 2, of degree 0, 4, 8: {jac[0]}, {jac[1]}, {jac[2]}")
print(f"h^2,0 = {h20}, h^1,1 = {jac[1]} + 1 = {h11}, h^0,2 = {h02}; b2 = {h20 + h11 + h02}")
print(f"Euler number 64 - 64 + 24 = {euler}, so b2 = {b2}; signature (4 - 16) x 4 / 3 = {sig}")
print(f"signature from Hodge numbers 2 + 2 x {h20} - {h11} = {2 + 2 * h20 - h11}; "
      f"positive part b+ = {(b2 + sig) // 2} = 2 h^2,0 + 1")

# ---- road 2: the 48 lines and their intersection matrix ----
roots = [ONE]
for _ in range(7):
    roots.append(zmul(roots[-1], ZETA))
roots = [roots[k] for k in (1, 3, 5, 7)]            # the four a with a^4 = -1
lines, planes = [], []
for (i, j, k, l) in [(0, 1, 2, 3), (0, 2, 1, 3), (0, 3, 1, 2)]:
    for a, b in product(roots, roots):                # the line x_i = a x_j, x_k = b x_l
        f, g = [ZERO] * 4, [ZERO] * 4
        f[i], f[j], g[k], g[l] = ONE, tuple(-x for x in a), ONE, tuple(-x for x in b)
        lines.append((f, g))
assert all(zmul(zmul(r, r), zmul(r, r)) == (-1, 0, 0, 0) for r in roots)   # a^4 = -1: each line lies on X
n = len(lines)
meet = lambda r, c: zdet(list(lines[r]) + list(lines[c])) == ZERO
G = [[-2 if r == c else int(meet(r, c)) for c in range(n)] for r in range(n)]
rank48, _ = bareiss(G)
print("road 2, the cycle side: the 48 lines on the Fermat quartic")
meets = sorted({sum(row) + 2 for row in G})          # how many other lines each of the 48 meets
print(f"lines: {n}; each meets {', '.join(map(str, meets))} others; self-intersection of a line: {G[0][0]}")
print(f"rank of the 48 x 48 intersection matrix over Q: {rank48}")
basis, minors = [], [1]
for c in range(n):                                    # grow a basis while the Gram determinant stays nonzero
    _, dt = bareiss([[G[a][b] for b in basis + [c]] for a in basis + [c]])
    if dt != 0:
        basis, minors = basis + [c], minors + [dt]
neg = sum(1 for u, v in zip(minors, minors[1:]) if (u > 0) != (v > 0))
print(f"independent lines found: {len(basis)}; Gram determinant of the {len(basis)}: {minors[-1]}")
print(f"signature of the intersection form on them: ({len(basis) - neg}, {neg})")

# ---- road 3: plane sections ----
for q, a in product(range(3), range(4)):              # the planes x_i = a x_j and x_k = a x_l
    planes += [[16 * q + 4 * a + b for b in range(4)], [16 * q + 4 * b + a for b in range(4)]]
rows = [[sum(G[m][c] for m in pl) for c in range(n)] for pl in planes]
h_sq = sum(rows[0][m] for m in planes[0])
print("road 3, the plane class h as four coplanar lines")
print(f"planes holding four lines: {len(planes)}; distinct rows h.L among them: {len(set(map(tuple, rows)))}")
print(f"h.L for every line: {sorted(set(rows[0]))}; h^2 = 4 x (-2) + 2 x 6 = {h_sq}")

# ---- what breaks ----
wrong = [[1 if r == c else G[r][c] for c in range(n)] for r in range(n)]
kd, kp = 125, 5
print(f"mistake 1, a line meets itself once, as in the plane: rank {bareiss(wrong)[0]}, more than b2 = {b2}")
print(f"mistake 2, every rational class in H^2 algebraic: {b2} claimed, rho = {len(basis)} here")
print(f"mistake 3, every (1,1) class algebraic: h^1,1 = {h11} claimed, rho = 1 for a very general quartic (quoted)")
print(f"mistake 4, integer coefficients: degree {kd} threefold, {kp}^3 divides {kd}: {'yes' if kd % kp ** 3 == 0 else 'no'}; "
      f"class l of degree 1, curve degrees multiples of {kp} (quoted); h^2 = {kd} l, so l = h^2/{kd} over Q only")
assert (h20, h11, h02) == (1, 20, 1) and h20 + h11 + h02 == b2       # road 1 against the Euler number
assert 2 + 2 * h20 - h11 == sig and (b2 + sig) // 2 == 2 * h20 + 1    # road 1 against the signature
assert rank48 == len(basis) == h11 == 20                             # road 2 meets road 1: rho = 20
assert meets == [14]                                                 # every line meets the same 14 others
assert minors[-1] == -64 and neg == 19                                # Hodge index: one positive direction
assert len(set(map(tuple, rows))) == 1 and set(rows[0]) == {1} and h_sq == 4
assert bareiss(wrong)[0] > b2                                       # mistake 1: the wrong form is impossible
print("ALL CHECKS PASS")
```

**Ran 2026-11-17 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
road 1, the Hodge side of a smooth quartic surface (a K3 surface)
monomials with exponents at most 2, of degree 0, 4, 8: 1, 19, 1
h^2,0 = 1, h^1,1 = 19 + 1 = 20, h^0,2 = 1; b2 = 22
Euler number 64 - 64 + 24 = 24, so b2 = 22; signature (4 - 16) x 4 / 3 = -16
signature from Hodge numbers 2 + 2 x 1 - 20 = -16; positive part b+ = 3 = 2 h^2,0 + 1
road 2, the cycle side: the 48 lines on the Fermat quartic
lines: 48; each meets 14 others; self-intersection of a line: -2
rank of the 48 x 48 intersection matrix over Q: 20
independent lines found: 20; Gram determinant of the 20: -64
signature of the intersection form on them: (1, 19)
road 3, the plane class h as four coplanar lines
planes holding four lines: 24; distinct rows h.L among them: 1
h.L for every line: [1]; h^2 = 4 x (-2) + 2 x 6 = 4
mistake 1, a line meets itself once, as in the plane: rank 48, more than b2 = 22
mistake 2, every rational class in H^2 algebraic: 22 claimed, rho = 20 here
mistake 3, every (1,1) class algebraic: h^1,1 = 20 claimed, rho = 1 for a very general quartic (quoted)
mistake 4, integer coefficients: degree 125 threefold, 5^3 divides 125: yes; class l of degree 1, curve degrees multiples of 5 (quoted); h^2 = 125 l, so l = h^2/125 over Q only
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// The Hodge conjecture in degree 2, on a K3 surface -- the same check as the Python, in Rust.
// No crates.  The Fermat quartic x^4 + y^4 + z^4 + w^4 = 0 in P^3:
//   road 1 (Hodge side): h^(p,q) by counting monomials, against the Euler number and the signature
//   road 2 (cycle side): its 48 lines, which pairs meet (exact 4 x 4 determinants over Z[zeta]),
//                        and the rank of their intersection matrix, by exact integer elimination
//   road 3 (one class two ways): 24 plane sections, four lines each, all give the plane class h
type Z8 = [i128; 4];                         // Z[t]/(t^4 + 1): t = zeta, a primitive 8th root of unity
const ZERO: Z8 = [0, 0, 0, 0];
const ONE: Z8 = [1, 0, 0, 0];
const ZETA: Z8 = [0, 1, 0, 0];

fn zmul(a: Z8, b: Z8) -> Z8 {
    let mut r = [0i128; 8];
    for i in 0..4 { for j in 0..4 { r[i + j] += a[i].checked_mul(b[j]).unwrap(); } }
    [r[0] - r[4], r[1] - r[5], r[2] - r[6], r[3] - r[7]]
}

fn perms(k: usize, cur: &mut Vec<usize>, out: &mut Vec<Vec<usize>>) {
    if cur.len() == k { out.push(cur.clone()); return; }
    for v in 0..k { if !cur.contains(&v) { cur.push(v); perms(k, cur, out); cur.pop(); } }
}

fn zdet(m: &Vec<Z8>) -> Z8 {                 // 4 x 4 determinant over Z[zeta]; m is 16 entries, row by row
    let mut ps = Vec::new();
    perms(4, &mut Vec::new(), &mut ps);
    let mut total = ZERO;
    for p in ps {
        let inv = (0..4).map(|i| (i + 1..4).filter(|&j| p[i] > p[j]).count()).sum::<usize>();
        let sign = if inv % 2 == 0 { 1 } else { -1 };
        let mut term = ONE;
        for i in 0..4 { term = zmul(term, m[4 * i + p[i]]); }
        for t in 0..4 { total[t] += sign * term[t]; }
    }
    total
}

fn bareiss(m0: &Vec<Vec<i128>>) -> (usize, i128) {   // fraction-free elimination: (rank, signed det if square)
    let mut m = m0.clone();
    let (rows, cols) = (m.len(), m[0].len());
    let (mut prev, mut r, mut sign) = (1i128, 0usize, 1i128);
    for c in 0..cols {
        let Some(p) = (r..rows).find(|&i| m[i][c] != 0) else { continue };
        if p != r { m.swap(r, p); sign = -sign; }
        for i in r + 1..rows {
            for j in c + 1..cols {
                m[i][j] = (m[r][c].checked_mul(m[i][j]).unwrap() - m[i][c].checked_mul(m[r][j]).unwrap()) / prev;
            }
            m[i][c] = 0;
        }
        prev = m[r][c];
        r += 1;
    }
    (r, if r == rows && rows == cols { sign * prev } else { 0 })
}

fn main() {
    // ---- road 1: Hodge numbers of a smooth quartic surface ----
    let d: i64 = 4;
    let jac: Vec<i64> = [0, 4, 8].iter().map(|&k| {
        let mut c = 0;
        for e in 0..81 { let (a, b, x, y) = (e % 3, e / 3 % 3, e / 9 % 3, e / 27); if a + b + x + y == k { c += 1; } }
        c
    }).collect();
    let (h20, h11, h02) = (jac[0], jac[1] + 1, jac[2]);
    let (euler, sig) = (d.pow(3) - 4 * d * d + 6 * d, (4 - d * d) * d / 3);
    let b2 = euler - 2;
    println!("road 1, the Hodge side of a smooth quartic surface (a K3 surface)");
    println!("monomials with exponents at most 2, of degree 0, 4, 8: {}, {}, {}", jac[0], jac[1], jac[2]);
    println!("h^2,0 = {}, h^1,1 = {} + 1 = {}, h^0,2 = {}; b2 = {}", h20, jac[1], h11, h02, h20 + h11 + h02);
    println!("Euler number 64 - 64 + 24 = {}, so b2 = {}; signature (4 - 16) x 4 / 3 = {}", euler, b2, sig);
    println!("signature from Hodge numbers 2 + 2 x {} - {} = {}; positive part b+ = {} = 2 h^2,0 + 1",
             h20, h11, 2 + 2 * h20 - h11, (b2 + sig) / 2);

    // ---- road 2: the 48 lines and their intersection matrix ----
    let mut pw = vec![ONE];
    for _ in 0..7 { let t = zmul(*pw.last().unwrap(), ZETA); pw.push(t); }
    let roots: Vec<Z8> = [1, 3, 5, 7].iter().map(|&k| pw[k]).collect();     // the four a with a^4 = -1
    let pairings = [(0, 1, 2, 3), (0, 2, 1, 3), (0, 3, 1, 2)];
    let mut lines: Vec<Vec<Z8>> = Vec::new();                           // 8 entries: the two linear forms
    for &(i, j, k, l) in pairings.iter() {
        for a in roots.iter() { for b in roots.iter() {                  // the line x_i = a x_j, x_k = b x_l
            let mut f = vec![ZERO; 8];
            f[i] = ONE; f[j] = a.map(|x| -x); f[4 + k] = ONE; f[4 + l] = b.map(|x| -x);
            lines.push(f);
        } }
    }
    assert!(roots.iter().all(|&r| zmul(zmul(r, r), zmul(r, r)) == [-1, 0, 0, 0]));   // a^4 = -1: each line lies on X
    let n = lines.len();
    let meet = |r: usize, c: usize| { let mut m = lines[r].clone(); m.extend(lines[c].iter()); zdet(&m) == ZERO };
    let g: Vec<Vec<i128>> = (0..n).map(|r| (0..n).map(|c| if r == c { -2 } else if meet(r, c) { 1 } else { 0 }).collect()).collect();
    let (rank48, _) = bareiss(&g);
    println!("road 2, the cycle side: the 48 lines on the Fermat quartic");
    let mut meets: Vec<i128> = g.iter().map(|r| r.iter().sum::<i128>() + 2).collect(); meets.sort(); meets.dedup();   // how many other lines each of the 48 meets
    println!("lines: {}; each meets {} others; self-intersection of a line: {}", n, meets.iter().map(|m| m.to_string()).collect::<Vec<_>>().join(", "), g[0][0]);
    println!("rank of the 48 x 48 intersection matrix over Q: {}", rank48);
    let (mut basis, mut minors): (Vec<usize>, Vec<i128>) = (vec![], vec![1]);
    for c in 0..n {                                                     // grow a basis while the Gram determinant stays nonzero
        let mut idx = basis.clone(); idx.push(c);
        let sub: Vec<Vec<i128>> = idx.iter().map(|&a| idx.iter().map(|&b| g[a][b]).collect()).collect();
        let (_, dt) = bareiss(&sub);
        if dt != 0 { basis.push(c); minors.push(dt); }
    }
    let neg = minors.windows(2).filter(|w| (w[0] > 0) != (w[1] > 0)).count();
    println!("independent lines found: {}; Gram determinant of the {}: {}", basis.len(), basis.len(), minors.last().unwrap());
    println!("signature of the intersection form on them: ({}, {})", basis.len() - neg, neg);

    // ---- road 3: plane sections ----
    let mut planes: Vec<Vec<usize>> = Vec::new();
    for q in 0..3 { for a in 0..4 {                                     // the planes x_i = a x_j and x_k = a x_l
        planes.push((0..4).map(|b| 16 * q + 4 * a + b).collect());
        planes.push((0..4).map(|b| 16 * q + 4 * b + a).collect());
    } }
    let rows: Vec<Vec<i128>> = planes.iter().map(|pl| (0..n).map(|c| pl.iter().map(|&m| g[m][c]).sum()).collect()).collect();
    let h_sq: i128 = planes[0].iter().map(|&m| rows[0][m]).sum();
    let mut distinct = rows.clone(); distinct.sort(); distinct.dedup();
    let mut hl = rows[0].clone(); hl.sort(); hl.dedup();
    println!("road 3, the plane class h as four coplanar lines");
    println!("planes holding four lines: {}; distinct rows h.L among them: {}", planes.len(), distinct.len());
    println!("h.L for every line: {:?}; h^2 = 4 x (-2) + 2 x 6 = {}", hl, h_sq);

    // ---- what breaks ----
    let wrong: Vec<Vec<i128>> = (0..n).map(|r| (0..n).map(|c| if r == c { 1 } else { g[r][c] }).collect()).collect();
    let (kd, kp): (i64, i64) = (125, 5);
    let wrong_rank = bareiss(&wrong).0;
    println!("mistake 1, a line meets itself once, as in the plane: rank {}, more than b2 = {}", wrong_rank, b2);
    println!("mistake 2, every rational class in H^2 algebraic: {} claimed, rho = {} here", b2, basis.len());
    println!("mistake 3, every (1,1) class algebraic: h^1,1 = {} claimed, rho = 1 for a very general quartic (quoted)", h11);
    println!("mistake 4, integer coefficients: degree {} threefold, {}^3 divides {}: {}; class l of degree 1, curve degrees multiples of {} (quoted); h^2 = {} l, so l = h^2/{} over Q only",
             kd, kp, kd, if kd % kp.pow(3) == 0 { "yes" } else { "no" }, kp, kd, kd);
    assert!((h20, h11, h02) == (1, 20, 1) && h20 + h11 + h02 == b2);           // road 1 against the Euler number
    assert!(2 + 2 * h20 - h11 == sig && (b2 + sig) / 2 == 2 * h20 + 1);       // road 1 against the signature
    assert!(rank48 == basis.len() && basis.len() as i64 == h11 && h11 == 20);  // road 2 meets road 1: rho = 20
    assert!(meets == vec![14]);                                                // every line meets the same 14 others
    assert!(*minors.last().unwrap() == -64 && neg == 19);                      // Hodge index: one positive direction
    assert!(distinct.len() == 1 && hl == vec![1] && h_sq == 4);
    assert!(wrong_rank as i64 > b2);                                           // mistake 1: the wrong form is impossible
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-17 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
road 1, the Hodge side of a smooth quartic surface (a K3 surface)
monomials with exponents at most 2, of degree 0, 4, 8: 1, 19, 1
h^2,0 = 1, h^1,1 = 19 + 1 = 20, h^0,2 = 1; b2 = 22
Euler number 64 - 64 + 24 = 24, so b2 = 22; signature (4 - 16) x 4 / 3 = -16
signature from Hodge numbers 2 + 2 x 1 - 20 = -16; positive part b+ = 3 = 2 h^2,0 + 1
road 2, the cycle side: the 48 lines on the Fermat quartic
lines: 48; each meets 14 others; self-intersection of a line: -2
rank of the 48 x 48 intersection matrix over Q: 20
independent lines found: 20; Gram determinant of the 20: -64
signature of the intersection form on them: (1, 19)
road 3, the plane class h as four coplanar lines
planes holding four lines: 24; distinct rows h.L among them: 1
h.L for every line: [1]; h^2 = 4 x (-2) + 2 x 6 = 4
mistake 1, a line meets itself once, as in the plane: rank 48, more than b2 = 22
mistake 2, every rational class in H^2 algebraic: 22 claimed, rho = 20 here
mistake 3, every (1,1) class algebraic: h^1,1 = 20 claimed, rho = 1 for a very general quartic (quoted)
mistake 4, integer coefficients: degree 125 threefold, 5^3 divides 125: yes; class l of degree 1, curve degrees multiples of 5 (quoted); h^2 = 125 l, so l = h^2/125 over Q only
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves the card's exact counts on the Fermat quartic: its 48 lines, which pairs meet, the rank 20, and the Hodge numbers.

- Take any point on any of the 48 lines. Then $`x^4 + y^4 + z^4 + w^4 = 0`$ there, so each line lies on the surface.
- Two different lines meet when the 4 × 4 determinant of their linear forms is zero. By that test, each line meets exactly 14 of the other 47.
- Take the four lines in any of the 24 planes, such as $`x = a y`$. Then their intersection numbers with any line $`L`$ add to 1, so $`h \cdot L = 1`$.
- Take the 48 × 48 matrix of intersection numbers, with $`L \cdot L = -2`$ on the diagonal. Then its rank over ℚ is exactly 20.
- Take the monomials in four variables with each exponent at most 2. Then degrees 0, 4 and 8 hold 1, 19 and 1 of them.
- Take the Hodge numbers 1, 19 + 1 = 20 and 1. Then they add to $`b_2 = 22`$, the Euler number 24 minus 2.
- Take the same Hodge numbers. Then $`2 + 2h^{2,0} - h^{1,1} = -16`$, the signature.

The determinant −64 and signature (1, 19) on 20 independent lines are left to the Python and Rust checks.

```lean
-- The Hodge conjecture: the 48 lines on the Fermat quartic x^4 + y^4 + z^4 + w^4 = 0 lie on the surface, each meets exactly 14 others, four coplanar ones give the plane class, their intersection matrix has rank 20, and the monomial count gives the Hodge numbers 1, 20, 1 of a quartic surface, so the lines fill all 20 directions of type (1, 1).
import Mathlib.LinearAlgebra.Matrix.Rank
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.RingTheory.RootsOfUnity.Complex
import Mathlib.Analysis.SpecialFunctions.Complex.Log
import Mathlib.Tactic

open Matrix

/-- `ζ = e^(iπ/4)`, a primitive 8th root of unity; its odd powers `ζ, ζ^3, ζ^5, ζ^7` are the
four numbers `a` with `a^4 = -1`. -/
noncomputable def ζ8 : ℂ := Complex.exp (Real.pi * Complex.I / 4)

/-- The three ways to split the coordinates `x_0, x_1, x_2, x_3` into two pairs:
`(0 1)(2 3)`, `(0 2)(1 3)` and `(0 3)(1 2)`. -/
def pairing (q : ℕ) : Fin 4 × Fin 4 × Fin 4 × Fin 4 :=
  if q = 0 then (0, 1, 2, 3) else if q = 1 then (0, 2, 1, 3) else (0, 3, 1, 2)

/-- Line number `r = 16 q + 4 s + t` (with `q < 3`, `s, t < 4`) is cut out by the two linear
forms `x_i - a x_j` and `x_k - b x_l`, where `(i, j, k, l)` is pairing `q`, `a = ζ^(2s+1)` and
`b = ζ^(2t+1)`. Each form is stored as its coefficient vector. -/
noncomputable def lineForm (r : Fin 48) : Fin 2 → Fin 4 → ℂ :=
  match pairing (r.val / 16) with
  | (i, j, k, l) =>
    ![Pi.single i 1 - ζ8 ^ (2 * (r.val / 4 % 4) + 1) • Pi.single j 1,
      Pi.single k 1 - ζ8 ^ (2 * (r.val % 4) + 1) • Pi.single l 1]

/-- Two lines meet exactly when their four defining linear forms are dependent, that is, when
the 4 × 4 determinant of those forms is zero. -/
def LinesMeet (r c : Fin 48) : Prop :=
  Matrix.det (Matrix.of ![lineForm r 0, lineForm r 1, lineForm c 0, lineForm c 1]) = 0

open Classical in
/-- The intersection matrix of the 48 lines on a K3 surface: `L · L = -2` on the diagonal,
and for two different lines `1` if they meet and `0` if not. -/
noncomputable def lineGram : Matrix (Fin 48) (Fin 48) ℚ :=
  Matrix.of fun r c => if r = c then -2 else if LinesMeet r c then 1 else 0

/-! ### Helper lemmas for the proofs below -/

lemma zeta8_isPrimitiveRoot : IsPrimitiveRoot ζ8 8 := by
  have h := Complex.isPrimitiveRoot_exp 8 (by norm_num)
  have e : ζ8 = Complex.exp (2 * Real.pi * Complex.I / (8 : ℕ)) := by
    unfold ζ8; congr 1; push_cast; ring
  rw [e]; exact h

#print axioms zeta8_isPrimitiveRoot

lemma zeta8_pow_eq_iff (m n : ℕ) : ζ8 ^ m = ζ8 ^ n ↔ m % 8 = n % 8 := by
  have hred : ∀ k : ℕ, ζ8 ^ k = ζ8 ^ (k % 8) := fun k => by
    conv_lhs => rw [← Nat.div_add_mod k 8, pow_add, pow_mul, zeta8_isPrimitiveRoot.pow_eq_one,
      one_pow, one_mul]
  rw [hred m, hred n]
  constructor
  · exact fun h => zeta8_isPrimitiveRoot.pow_inj (Nat.mod_lt _ (by norm_num))
      (Nat.mod_lt _ (by norm_num)) h
  · intro h; rw [h]

#print axioms zeta8_pow_eq_iff

lemma zeta8_pow_four : ζ8 ^ 4 = -1 := by
  unfold ζ8
  rw [← Complex.exp_nat_mul]
  have : ((4 : ℕ) : ℂ) * (Real.pi * Complex.I / 4) = Real.pi * Complex.I := by push_cast; ring
  rw [this, Complex.exp_pi_mul_I]

#print axioms zeta8_pow_four

lemma zeta8_odd_pow_four (m : ℕ) : (ζ8 ^ (2 * m + 1)) ^ 4 = -1 := by
  rw [← pow_mul, show (2 * m + 1) * 4 = 8 * m + 4 by ring, pow_add, pow_mul,
    zeta8_isPrimitiveRoot.pow_eq_one, one_pow, one_mul, zeta8_pow_four]

#print axioms zeta8_odd_pow_four

/-- The two forms of a line in pairing `q`, with coefficients `a` and `b`. -/
noncomputable def lineFormAux (q : ℕ) (a b : ℂ) : Fin 2 → Fin 4 → ℂ :=
  match pairing q with
  | (i, j, k, l) => ![Pi.single i 1 - a • Pi.single j 1, Pi.single k 1 - b • Pi.single l 1]

lemma lineForm_eq (r : Fin 48) : lineForm r = lineFormAux (r.val / 16)
    (ζ8 ^ (2 * (r.val / 4 % 4) + 1)) (ζ8 ^ (2 * (r.val % 4) + 1)) := rfl

#print axioms lineForm_eq

/-- The determinant of two lines' forms, by the pairings `q` and `q'` of the two lines;
`a, b` are the first line's coefficients and `c, d` the second's. -/
noncomputable def detExpr (q q' : ℕ) (a b c d : ℂ) : ℂ :=
  if q = q' then (if q = 1 then (a - c) * (b - d) else -((a - c) * (b - d)))
  else if q = 0 ∧ q' = 1 then a * d - b * c
  else if q = 1 ∧ q' = 0 then b * c - a * d
  else if q = 0 ∧ q' = 2 then a * b * d - c
  else if q = 2 ∧ q' = 0 then b * c * d - a
  else if q = 1 ∧ q' = 2 then a * b - c * d
  else c * d - a * b

lemma det_lineFormAux (q q' : ℕ) (hq : q < 3) (hq' : q' < 3) (a b c d : ℂ) :
    Matrix.det (Matrix.of ![lineFormAux q a b 0, lineFormAux q a b 1,
      lineFormAux q' c d 0, lineFormAux q' c d 1]) = detExpr q q' a b c d := by
  interval_cases q <;> interval_cases q' <;>
    simp (config := { decide := true }) [lineFormAux, pairing, detExpr,
      Matrix.det_succ_row_zero, Fin.sum_univ_succ, Pi.single_apply] <;> ring

#print axioms det_lineFormAux

/-- When two lines meet, as a condition on the exponents of `ζ` mod 8. -/
def condB (q q' A B C D : ℕ) : Bool :=
  if q = q' then (A % 8 == C % 8 || B % 8 == D % 8)
  else if (q = 0 ∧ q' = 1) ∨ (q = 1 ∧ q' = 0) then (A + D) % 8 == (B + C) % 8
  else if q = 0 ∧ q' = 2 then (A + B + D) % 8 == C % 8
  else if q = 2 ∧ q' = 0 then (B + C + D) % 8 == A % 8
  else (A + B) % 8 == (C + D) % 8

lemma detExpr_eq_zero_iff (q q' : ℕ) (hq : q < 3) (hq' : q' < 3) (A B C D : ℕ) :
    detExpr q q' (ζ8 ^ A) (ζ8 ^ B) (ζ8 ^ C) (ζ8 ^ D) = 0 ↔ condB q q' A B C D = true := by
  interval_cases q <;> interval_cases q' <;>
    simp only [detExpr, condB, ← pow_add] <;> simp <;>
    simp only [sub_eq_zero, zeta8_pow_eq_iff] <;> constructor <;> intro h <;> omega

#print axioms detExpr_eq_zero_iff

/-- The meeting rule on line numbers, computable. -/
def meetB (r c : Fin 48) : Bool :=
  condB (r.val / 16) (c.val / 16) (2 * (r.val / 4 % 4) + 1) (2 * (r.val % 4) + 1)
    (2 * (c.val / 4 % 4) + 1) (2 * (c.val % 4) + 1)

lemma linesMeet_iff (r c : Fin 48) : LinesMeet r c ↔ meetB r c = true := by
  have hr := r.isLt
  have hc := c.isLt
  unfold LinesMeet meetB
  rw [lineForm_eq r, lineForm_eq c, det_lineFormAux _ _ (by omega) (by omega),
    detExpr_eq_zero_iff _ _ (by omega) (by omega)]

#print axioms linesMeet_iff

/-- The intersection matrix over `ℤ`, computable. -/
def gramZ (r c : Fin 48) : ℤ := if r = c then -2 else if meetB r c then 1 else 0

lemma lineGram_eq : lineGram = (Matrix.of gramZ).map (Int.cast : ℤ → ℚ) := by
  ext r c
  by_cases h1 : r = c <;> by_cases h2 : meetB r c = true <;>
    simp [lineGram, gramZ, h1, h2, linesMeet_iff]

#print axioms lineGram_eq

lemma quartic_aux (u v w y a b : ℂ) (h0 : u = a * v) (h1 : w = b * y) (ha : a ^ 4 = -1)
    (hb : b ^ 4 = -1) : u ^ 4 + v ^ 4 + w ^ 4 + y ^ 4 = 0 := by
  subst h0 h1
  linear_combination v ^ 4 * ha + y ^ 4 * hb

#print axioms quartic_aux

def selS : Fin 20 → Fin 48 := ![0, 1, 2, 3, 4, 5, 6, 8, 9, 10, 16, 17, 18, 20, 21, 22, 32, 33, 34, 36]

def certB : Matrix (Fin 20) (Fin 48) ℤ :=
  !![1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 1, -1, 0, 0, 0, 1, 0, 0, 0, 1, -1, 1, 2, -1, 2, 0, -1, 0, 0, 0, 0, 1, 0, 3, 0, -2, 1, -3, 0, 3, 0, 1, 1, -1;
    0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0, 1, -1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 2, -2, 1, 0, -1, 1, 0, 0, 0, 1, 0, 3, -1, -1, 0, -2, 0, 3, 1, 0, 2, -2;
    0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 1, 0, -1, 0, 0, 0, 1, 0, 0, 0, 1, -1, 2, 2, -2, 2, -1, -1, 1, 0, 0, 0, 1, 0, 3, -1, -1, 1, -3, 0, 3, 0, 1, 2, -2;
    0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 1, 1, -2, 0, 0, 0, 1, 0, 0, 0, 1, -1, 1, 3, -2, 2, 0, -2, 1, 0, 0, 0, 1, 0, 3, 0, -2, 1, -3, -1, 4, 0, 1, 2, -2;
    0, 0, 0, 0, 1, 0, 0, -1, 0, 0, 0, 0, -1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 1, 0, 1, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, -1, 0, -1, 0, 1;
    0, 0, 0, 0, 0, 1, 0, -1, 0, 0, 0, 0, 0, -1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, -1, -1, 1, -1, 1, 1, -1, 0, 0, 0, 0, 0, -1, 0, 1, 0, 2, 0, -2, 0, -1, 0, 1;
    0, 0, 0, 0, 0, 0, 1, -1, 0, 0, 0, 0, 0, 0, -1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, -1, 0, -1, 0, 1, 0, 0, 0, 0, 0, 0, -1, 0, 1, 0, 1, 0, -1, 0, 0, 0, 0;
    0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, -1, -1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 1, 1, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, -1, -1, 0, 0, 1;
    0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, -1, 0, -1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 1, 0, 1, 0, -1, 0, 0, 0, 0, 0, -1, 1, 0, 1, 1, -1, -1, -1, 0, 0, 1;
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, -1, 0, 0, -1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 1, 0, 0, 1, -1, 0, 0, 0, 0, 0, -1, 1, 0, 1, 0, 0, -1, -1, 1, -1, 1;
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 0, -1, 1, -1, 0, 1, 0, 0, 0, 0, 0, 0, -1, 1, 0, 0, 1, 0, -1, 0, 0, -1, 1;
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, -1, 0, 0, 0, 0, 1, 0, -1, 0, -1, -1, 1, 1, 0, 0, 0, 0, 0, -1, 0, 1, -1, 1, 1, -1, 1, 0, -1, 0;
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, -1, 0, 0, 0, 0, 0, 1, -1, 0, 0, -1, 0, 1, 0, 0, 0, 0, 0, 0, -1, 1, -1, 0, 1, 0, 1, 0, 0, -1;
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, -1, 0, -1, 0, 1, -1, 1, 0, 0, 0, 0, 0, 0, 0, -1, 1, 0, 0, 1, 0, -1, 0, 0, -1, 1;
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, -1, 1, -1, -1, 1, -1, 0, 1, 0, 0, 0, 0, 0, 0, -1, 0, 1, -1, 1, 1, -1, 1, 0, -1, 0;
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, -1, 1, 0, -1, 0, -1, 0, 0, 1, 0, 0, 0, 0, 0, 0, -1, 1, -1, 0, 1, 0, 1, 0, 0, -1;
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, -1, 0, -1, 1, 0, 0, 1, -1, 0, -1, 0, 0, 1;
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, -1, 0, -1, 0, 1, 0, 1, 0, -1, 0, -1, 0, 1;
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, -1, 0, 0, -1, 1, -1, 1, 0, 0, 1, -1, 0, 0;
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, -1, 1, -1, 0, 0, 0, 0, -1, 1, -1, 1]

def certX : Matrix (Fin 20) (Fin 20) ℤ :=
  !![-85, -71, -86, -100, 21, 48, 31, 6, 23, 21, 30, 30, 4, 26, 34, 12, 16, 28, 16, 4;
    -71, -82, -85, -94, 24, 42, 26, 17, 30, 33, 34, 20, -6, 30, 28, -2, 20, 24, 4, 16;
    -86, -85, -105, -110, 29, 54, 29, 13, 33, 28, 36, 26, -6, 36, 38, 6, 20, 28, 12, 12;
    -100, -94, -110, -132, 30, 60, 38, 14, 30, 32, 40, 36, 4, 32, 44, 12, 16, 32, 16, 8;
    21, 24, 29, 30, -18, -18, -8, -9, -12, -7, -6, 0, 6, -10, -8, 2, -4, -8, -4, 0;
    48, 42, 54, 60, -18, -36, -18, -6, -18, -12, -16, -12, 4, -16, -20, -4, -8, -16, -8, 0;
    31, 26, 29, 38, -8, -18, -18, -1, -6, -9, -10, -12, -2, -6, -12, -6, -4, -8, -4, 0;
    6, 17, 13, 14, -9, -6, -1, -17, -13, -12, -4, 6, 6, -4, 2, 10, -4, -4, 4, -4;
    23, 30, 33, 30, -12, -18, -6, -13, -26, -17, -10, 4, 14, -14, -4, 10, -12, -8, 4, -8;
    21, 33, 28, 32, -7, -12, -9, -12, -17, -25, -14, -2, 8, -10, -6, 8, -8, -4, 8, -12;
    30, 34, 36, 40, -6, -16, -10, -4, -10, -14, -20, -12, 0, -12, -12, 0, -8, -8, 0, -8;
    30, 20, 26, 36, 0, -12, -12, 6, 4, -2, -12, -24, -12, -4, -16, -12, 0, -8, -8, 0;
    4, -6, -6, 4, 6, 4, -2, 6, 14, 8, 0, -12, -20, 8, -4, -12, 8, 0, -8, 8;
    26, 30, 36, 32, -10, -16, -6, -4, -14, -10, -12, -4, 8, -20, -12, 0, -8, -8, 0, -8;
    34, 28, 38, 44, -8, -20, -12, 2, -4, -6, -12, -16, -4, -12, -24, -12, 0, -8, -8, 0;
    12, -2, 6, 12, 2, -4, -6, 10, 10, 8, 0, -12, -12, 0, -12, -20, 8, 0, -8, 8;
    16, 20, 20, 16, -4, -8, -4, -4, -12, -8, -8, 0, 8, -8, 0, 8, -16, -8, 0, -8;
    28, 24, 28, 32, -8, -16, -8, -4, -8, -4, -8, -8, 0, -8, -8, 0, -8, -16, -8, 0;
    16, 4, 12, 16, -4, -8, -4, 4, 4, 8, 0, -8, -8, 0, -8, -8, 0, -8, -16, 8;
    4, 16, 12, 8, 0, 0, 0, -4, -8, -12, -8, 0, 8, -8, 0, 8, -8, 0, 8, -16]

lemma count_meet : ∀ r : Fin 48,
    (Finset.univ.filter (fun c => c ≠ r ∧ meetB r c = true)).card = 14 := by
  decide +kernel

#print axioms count_meet

lemma plane_sums : ∀ (q : Fin 3) (s : Fin 4) (c : Fin 48),
    ∑ t : Fin 4, gramZ ⟨16 * q.val + 4 * s.val + t.val, by omega⟩ c = 1 ∧
    ∑ t : Fin 4, gramZ ⟨16 * q.val + 4 * t.val + s.val, by omega⟩ c = 1 := by
  decide +kernel

#print axioms plane_sums

lemma gram_factor : ∀ r c : Fin 48,
    gramZ r c = ∑ k : Fin 20, gramZ r (selS k) * certB k c := by
  decide +kernel

#print axioms gram_factor

lemma gram_minor_inverse : ∀ i j : Fin 20,
    ∑ k : Fin 20, gramZ (selS i) (selS k) * certX k j = if i = j then 8 else 0 := by
  decide +kernel

#print axioms gram_minor_inverse

/-- The cycle side of `ρ = 20` on the Fermat quartic: the intersection matrix of its 48 lines
(self-intersection `-2`, and `1` or `0` for two different lines as they meet or not) has rank
exactly 20 over `ℚ`. Intersection numbers depend only on classes, so the 48 line classes span
20 dimensions of `Hdg^1`; with `h^(1,1) = 20` this fills every direction of type (1, 1), and
the Hodge conjecture for `p = 1` holds on this surface by explicit curves. -/
theorem fermat_quartic_lines_intersection_rank_eq_twenty : lineGram.rank = 20 := by
  rw [lineGram_eq]
  apply le_antisymm
  · have hfac : (Matrix.of gramZ).map (Int.cast : ℤ → ℚ) =
        ((Matrix.of gramZ).map (Int.cast : ℤ → ℚ)).submatrix id selS *
          certB.map (Int.cast : ℤ → ℚ) := by
      ext r c
      simp only [Matrix.mul_apply, Matrix.map_apply, Matrix.submatrix_apply, Matrix.of_apply, id]
      rw [gram_factor r c]
      push_cast
      rfl
    rw [hfac]
    exact (Matrix.rank_mul_le_left _ _).trans (Matrix.rank_le_width _)
  · have hinv : ((Matrix.of gramZ).map (Int.cast : ℤ → ℚ)).submatrix selS selS *
        ((1 / 8 : ℚ) • certX.map (Int.cast : ℤ → ℚ)) = 1 := by
      ext i j
      simp only [Matrix.mul_apply, Matrix.smul_apply, Matrix.map_apply, Matrix.submatrix_apply,
        Matrix.of_apply, smul_eq_mul, Matrix.one_apply]
      have h := gram_minor_inverse i j
      calc ∑ k, (gramZ (selS i) (selS k) : ℚ) * (1 / 8 * (certX k j : ℚ))
          = 1 / 8 * ((∑ k, gramZ (selS i) (selS k) * certX k j : ℤ) : ℚ) := by
            push_cast
            rw [Finset.mul_sum]
            refine Finset.sum_congr rfl fun k _ => ?_
            ring
        _ = _ := by rw [h]; split_ifs <;> norm_num
    calc (20 : ℕ) = (1 : Matrix (Fin 20) (Fin 20) ℚ).rank := by rw [Matrix.rank_one]; simp
      _ = _ := by rw [← hinv]
      _ ≤ _ := Matrix.rank_mul_le_left _ _
      _ ≤ _ := Matrix.rank_submatrix_le _ _ _

/-- The Hodge side of a smooth quartic surface, by counting monomials: in
`ℂ[x, y, z, w] / (x^3, y^3, z^3, w^3)` the monomials (each exponent at most 2) of degree 0, 4
and 8 number 1, 19 and 1, so `h^(2,0) = 1`, `h^(1,1) = 19 + 1 = 20`, `h^(0,2) = 1`. Their sum
is `b_2 = 22`, the Euler number `4^3 - 4·4^2 + 6·4 = 24` minus 2, and `2 + 2 h^(2,0) - h^(1,1)`
is the signature `(4 - 4^2)·4/3 = -16`. -/
theorem quartic_hodge_numbers_by_monomials :
    let jac : ℕ → ℕ := fun k =>
      (Finset.univ.filter (fun e : Fin 4 → Fin 3 => ∑ i, (e i : ℕ) = k)).card
    jac 0 = 1 ∧ jac 4 = 19 ∧ jac 8 = 1 ∧
      jac 0 + (jac 4 + 1) + jac 8 = 4 ^ 3 - 4 * 4 ^ 2 + 6 * 4 - 2 ∧
      (2 + 2 * (jac 0 : ℤ) - (jac 4 + 1)) * 3 = (4 - 4 ^ 2) * 4 := by
  decide +kernel

open Classical in
/-- The 48 lines on the Fermat quartic: every point of every line satisfies
`x_0^4 + x_1^4 + x_2^4 + x_3^4 = 0`; each line meets exactly 14 of the other 47; and the four
lines in each of the 24 planes `x_i = a x_j` (or `x_k = b x_l`) add up to the plane class `h`,
which has `h · L = 1` for every line `L`. -/
theorem fermat_quartic_lines_on_surface_meet_fourteen_plane_class :
    (∀ (r : Fin 48) (x : Fin 4 → ℂ), lineForm r 0 ⬝ᵥ x = 0 → lineForm r 1 ⬝ᵥ x = 0 →
        ∑ i, x i ^ 4 = 0) ∧
      (∀ r : Fin 48, (Finset.univ.filter (fun c => c ≠ r ∧ LinesMeet r c)).card = 14) ∧
      (∀ (q : Fin 3) (s : Fin 4) (c : Fin 48),
        ∑ t : Fin 4, lineGram ⟨16 * q.val + 4 * s.val + t.val, by omega⟩ c = 1 ∧
        ∑ t : Fin 4, lineGram ⟨16 * q.val + 4 * t.val + s.val, by omega⟩ c = 1) := by
  refine ⟨?_, ?_, ?_⟩
  · intro r x h0 h1
    have hr := r.isLt
    have hq : r.val / 16 < 3 := by omega
    have ha := zeta8_odd_pow_four (r.val / 4 % 4)
    have hb := zeta8_odd_pow_four (r.val % 4)
    rw [lineForm_eq] at h0 h1
    generalize ζ8 ^ (2 * (r.val / 4 % 4) + 1) = a at h0 ha
    generalize ζ8 ^ (2 * (r.val % 4) + 1) = b at h1 hb
    generalize r.val / 16 = q at hq h0 h1
    simp only [Fin.sum_univ_four]
    interval_cases q <;>
      simp [lineFormAux, pairing, dotProduct, Fin.sum_univ_four, Pi.single_apply] at h0 h1
    · linear_combination quartic_aux (x 0) (x 1) (x 2) (x 3) a b (by linear_combination h0)
        (by linear_combination h1) ha hb
    · linear_combination quartic_aux (x 0) (x 2) (x 1) (x 3) a b (by linear_combination h0)
        (by linear_combination h1) ha hb
    · linear_combination quartic_aux (x 0) (x 3) (x 1) (x 2) a b (by linear_combination h0)
        (by linear_combination h1) ha hb
  · intro r
    have e : (Finset.univ.filter (fun c => c ≠ r ∧ LinesMeet r c)) =
        Finset.univ.filter (fun c => c ≠ r ∧ meetB r c = true) := by
      ext c; simp [linesMeet_iff]
    rw [e]
    convert count_meet r
  · intro q s c
    have key := plane_sums q s c
    simp only [lineGram_eq, Matrix.map_apply, Matrix.of_apply]
    exact_mod_cast key

-- 3 pairings times 4 choices of a times 4 choices of b: 48 lines.
example : 3 * 4 * 4 = 48 := by norm_num
-- Each line is a sphere, genus 0: L · L = 2g - 2 = -2.
example : (2 * 0 - 2 : ℤ) = -2 := by norm_num
-- Four coplanar lines meet in 6 pairs: h^2 = 4 × (-2) + 2 × 6 = 4.
example : Nat.choose 4 2 = 6 := by decide
example : (4 * (-2) + 2 * 6 : ℤ) = 4 := by norm_num
-- Euler number 64 - 64 + 24 = 24, so b_2 = 24 - 2 = 22 = 1 + 20 + 1.
example : (4 ^ 3 - 4 * 4 ^ 2 + 6 * 4 : ℤ) = 24 ∧ (24 - 2 : ℤ) = 1 + 20 + 1 := by norm_num
-- Signature (4 - 16) × 4 / 3 = -16 = 2 + 2 × 1 - 20, and b+ = (22 - 16) / 2 = 3 = 2 × 1 + 1.
example : ((4 - 16) * 4 : ℤ) = -16 * 3 ∧ (2 + 2 * 1 - 20 : ℤ) = -16 ∧
    ((22 + -16) / 2 : ℤ) = 2 * 1 + 1 := by norm_num
-- Kollár: 5^3 divides 125, and h^2 = 125 l, so l = h^2 / 125.
example : 5 ^ 3 ∣ 125 := by decide

#print axioms fermat_quartic_lines_intersection_rank_eq_twenty
#print axioms quartic_hodge_numbers_by_monomials
#print axioms fermat_quartic_lines_on_surface_meet_fourteen_plane_class
```

**Checked 2026-11-17 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'zeta8_isPrimitiveRoot' depends on axioms: [propext, Classical.choice, Quot.sound]
'zeta8_pow_eq_iff' depends on axioms: [propext, Classical.choice, Quot.sound]
'zeta8_pow_four' depends on axioms: [propext, Classical.choice, Quot.sound]
'zeta8_odd_pow_four' depends on axioms: [propext, Classical.choice, Quot.sound]
'lineForm_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'det_lineFormAux' depends on axioms: [propext, Classical.choice, Quot.sound]
'detExpr_eq_zero_iff' depends on axioms: [propext, Classical.choice, Quot.sound]
'linesMeet_iff' depends on axioms: [propext, Classical.choice, Quot.sound]
'lineGram_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'quartic_aux' depends on axioms: [propext, Classical.choice, Quot.sound]
'count_meet' depends on axioms: [propext, Classical.choice, Quot.sound]
'plane_sums' depends on axioms: [propext, Classical.choice, Quot.sound]
'gram_factor' depends on axioms: [propext, Classical.choice, Quot.sound]
'gram_minor_inverse' depends on axioms: [propext, Classical.choice, Quot.sound]
'fermat_quartic_lines_intersection_rank_eq_twenty' depends on axioms: [propext, Classical.choice, Quot.sound]
'quartic_hodge_numbers_by_monomials' depends on axioms: [propext, Classical.choice, Quot.sound]
'fermat_quartic_lines_on_surface_meet_fourteen_plane_class' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it. The asserts are pinned to the card's numbers, so expect one to stop the program.
> - **A different self-intersection.** Change `-2 if r == c` to `0 if r == c`. Guess first: zero self-intersection is wrong for a sphere on a K3 surface. The rank comes out 48, far above 20, and the road-2 assert stops the run.
> - **Kollár's condition.** Change `kd, kp = 125, 5` to `kd, kp = 100, 5`. Guess first: $`5^3`$ does not divide 100, so the theorem behind mistake 4 no longer applies. The mistake-4 line prints "no"; the run still passes, because Kollár's theorem is quoted, not computed.
> - **Forget the relations.** Change `range(d - 1)` to `range(d)`, so exponents up to 3 survive. Guess first: degree 4 now holds 31 monomials, giving $`h^{1,1} = 32`$, more than $`b_2 = 22`$. The road-1 assert stops the run.

---

## The usual mistake

> [!warning]
> **Reading the conjecture as "every class of type (p, p) is algebraic".** The test applies to rational classes. A very general quartic surface has $`h^{1,1} = 20`$ but ρ = 1: of the 20 complex dimensions of type (1, 1), only the multiples of the plane class are rational classes. The conjecture asks about $`H^{2p}(X, \mathbb{Q}) \cap H^{p,p}`$, never about $`H^{p,p}`$ alone.
>
> - **Integer coefficients.** Kollár's degree-125 threefold has an integer Hodge class $`\ell`$ of degree 1 that no cycle reaches; only $`125\,\ell = h^2`$ is reached.
> - **Plane geometry on a K3 surface.** A line on the quartic has $`L \cdot L = -2`$, not +1; with +1 the 48 lines would span 48 dimensions in a space of 22.
> - **"Proved for surfaces, so proved."** Surfaces and threefolds are done by Lefschetz; the first open cases are in degree 4 on fourfolds.
> - **Kähler is enough.** The statement needs a projective variety; on non-projective complex tori it fails.

---

## Where you meet it in real life

- **Classifying K3 surfaces.** The Picard number and the lattice of integer (1, 1) classes sort K3 surfaces into families. Quartics with ρ ≥ 2 form countably many families of smaller dimension, such as the quartics that contain a line.
- **Arithmetic of surfaces.** Over finite fields the Tate conjecture plays the role of the Hodge conjecture, with classes fixed by Frobenius in place of type (p, p) ([The curve mod p](../04-Elliptic%20Curves/05-reduction-mod-p-and-hasse.md) counts points on curves).
- **The Millennium Problems.** The Hodge conjecture is one of the seven problems the Clay Mathematics Institute named in 2000, stated by Deligne in the form on this card.

> **Say it back**
> A subvariety of codimension p has a rational class of type (p, p). The Hodge conjecture says the converse: every rational class of type (p, p) on a smooth projective complex variety is a rational combination of such classes. For p = 1 it is Lefschetz's theorem, proved through line bundles and the exponential map, and it gives p = n − 1 too. On the Fermat quartic, a K3 surface, the type test allows 20 dimensions and the 48 lines fill all 20, so ρ = 20. With integer coefficients the statement is false, and in codimension 2 and higher it is open.

---

## What this builds on

- [Algebraic cycles](07-algebraic-cycles-and-cycle-classes.md): a subvariety W and its class [W]; Step 0 here uses that every cycle class is a Hodge class.
- [Hodge decomposition](05-hodge-decomposition.md): the split of cohomology by type, and the Hodge numbers $`h^{p,q}`$ that bound ρ.
- [Line bundles and divisors](06-line-bundles-and-divisor-classes.md): $`\mathcal{O}(D)`$, Pic(X) and $`c_1`$, the bridge in Lefschetz's proof.
- [Cohomology of projective space](03-cohomology-of-projective-space.md): the plane class h, which every projective variety carries.
- [Cohomology and the cup product in outline](../../17-Topology/05-Homology/08-cohomology-and-cup-product-in-outline.md): rational and integer cohomology, and torsion.

## Where this goes next

- [The Hodge conjecture](../../25-Frontier/02-The%20Millennium%20Problems/05-hodge-conjecture.md): the Frontier wing's record of the conjecture's status, the partial results and the prize.

The open question is the one this card names: for p ≥ 2, is every rational class of type (p, p) on a smooth projective variety a combination of subvarieties?

---

## Sources

Verified 2026-11-17: every link below resolves to the publisher's page.

- Deligne, Pierre. "The Hodge Conjecture." Clay Mathematics Institute, official problem description. [claymath.org](https://www.claymath.org/millennium/hodge-conjecture/). The exact statement, the proof route for $`H^2`$, the failure over ℤ and for Kähler manifolds.
- Voisin, Claire. *Hodge Theory and Complex Algebraic Geometry II*. Cambridge University Press, 2003. [DOI 10.1017/CBO9780511615177](https://doi.org/10.1017/CBO9780511615177). Hodge classes, the Lefschetz theorems, Griffiths' description of hypersurface cohomology, Noether–Lefschetz.
- Huybrechts, Daniel. *Lectures on K3 Surfaces*. Cambridge University Press, 2016. [DOI 10.1017/CBO9781316594193](https://doi.org/10.1017/CBO9781316594193). K3 surfaces, the Picard number, the lattice $`H^2(X, \mathbb{Z})`$, and the Fermat quartic with ρ = 20.
- Atiyah, M. F., and F. Hirzebruch. "Analytic cycles on complex manifolds." *Topology* 1 (1962), 25–45. [DOI 10.1016/0040-9383(62)90094-0](https://doi.org/10.1016/0040-9383(62)90094-0). Torsion integer classes that come from no cycle.
- Ballico, E., F. Catanese and C. Ciliberto. "Trento examples." In *Classification of Irregular Varieties*, Lecture Notes in Mathematics 1515, Springer, 1992, 134–139. [DOI 10.1007/BFb0098342](https://doi.org/10.1007/BFb0098342). Kollár's example there: the degree-125 hypersurface whose curves all have degree divisible by 5.
