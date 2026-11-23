# The Hodge conjecture: which cohomology classes come from algebraic subvarieties

[Syllabus](../../../SYLLABUS.md) → [Frontier](../README.md) → [The Millennium Problems](../README.md#s02) → The Hodge conjecture

---

## General Overview

On 2000-05-24, at a meeting in Paris, the Clay Mathematics Institute named seven Millennium Problems and offered $1 million for each. One, the Poincaré conjecture, is solved. The Hodge conjecture is one of the six that are not. On 2026-11-23 Clay's own page gives its status in one word: "Unsolved".

The official statement is by Pierre Deligne. In plain words it asks this. A smooth shape cut out by polynomial equations has "holes" of many sizes, recorded by its **cohomology classes** (the independent ways a closed film can sit inside the shape). Some of these classes are traced by smaller shapes inside it, also cut out by polynomials: its **algebraic subvarieties**. The conjecture says that one simple test picks out exactly the classes these subvarieties can reach.

Here is a shape where the test is first hard. The **Fermat cubic fourfold** is the set of points where $`x_0^3 + x_1^3 + x_2^3 + x_3^3 + x_4^3 + x_5^3 = 0`$, inside five-dimensional complex projective space. It has complex dimension 4. Its middle cohomology has 23 directions, and the test allows 21 of them. It contains 405 flat planes, and the checks below find that these planes reach all 21 directions, and no more.

Dimension 4 matters because it is the first dimension where the known general theorems stop. Below dimension 4 the conjecture is a theorem for every shape. In dimension 4, codimension 2 is the first open case, and the cubic fourfold is one of the few families where it has been settled (Zucker, 1977).

**The Hodge conjecture says that on a smooth complex projective variety every rational cohomology class of type (p, p) is a rational combination of classes of subvarieties of codimension p; it is proved for p = 0, 1, n − 1 and n, false with integer coefficients, and open in general.**

**What kind of fact this is:** a conjecture. Status: open as of 2026-11-23, meaning there is no accepted proof and no accepted counterexample. The kind and the status are separate fields, as [Kinds of claim](../01-How%20Research%20Works/02-theorem-conjecture-model-approximation.md) sets out. The facts about the Fermat cubic fourfold on this card are theorems, checked here by computation.

### The picture: what the test allows, and what the planes reach

```
b4, all classes in H^4                 #######################  23
h^2,2, classes of type (2,2)           #####################    21
planes on the Fermat cubic fourfold    #####################    21
algebraic classes, very general cubic  #                         1
```

One mark per dimension. The checks print the first three bars. The last is a quoted theorem: a cubic fourfold chosen outside countably many special families has only one algebraic direction, the class $`h^2`$ defined below. The gap between the second and fourth bars is why the test asks about *rational* classes, not about every class of type (2, 2).

---

## The formula

The full development is on the algebraic-geometry card [The Hodge conjecture](../../22-Algebraic%20geometry/05-Cohomology%20and%20the%20Hodge%20Conjecture/08-hodge-conjecture-statement-and-known-cases.md). It states the conjecture, proves the case p = 1 (Lefschetz's theorem on divisors, the combinations of codimension-1 subvarieties), shows the failure with integer coefficients, and works the Picard number of a K3 surface. This card uses those results and spends its space on the Clay statement, the first open case and the status.

Notation, in words first:

- $`X`$ is a **smooth projective variety** over $`\mathbb{C}`$: the common zeros of homogeneous polynomials in some projective space, with no singular points. Its complex dimension is $`n`$.
- $`H^{2p}(X, \mathbb{Q})`$ is its cohomology in degree 2p with rational coefficients.
- The [Hodge decomposition](../../22-Algebraic%20geometry/05-Cohomology%20and%20the%20Hodge%20Conjecture/05-hodge-decomposition.md) splits the complex cohomology by **type** (p, q): forms with p factors $`dz`$ and q factors $`d\bar z`$. $`H^{p,q}`$ is the type-(p, q) part, and $`h^{p,q}`$ its dimension.
- A subvariety $`W`$ of codimension p has a **cycle class** $`[W]`$ in $`H^{2p}`$.

```math
\mathrm{Hdg}^p(X) = H^{2p}(X, \mathbb{Q}) \cap H^{p,p}(X) \overset{?}{=} \Big\{ \textstyle\sum_i q_i\,[W_i] \;:\; q_i \in \mathbb{Q},\ W_i \subset X \text{ of codimension } p \Big\}
```

**Read it aloud:** the Hodge classes of degree 2p, the rational classes of type p, p, should be exactly the rational combinations of classes of subvarieties of codimension p.

The inclusion from right to left is a theorem: every cycle class is rational and has type (p, p). The conjecture is the inclusion from left to right. With our example, n = 4 and p = 2: $`\mathrm{Hdg}^2`$ of the Fermat cubic fourfold has dimension 21, and the 405 plane classes span it.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $`X`$, $`n`$, $`x_i`$ | a smooth projective variety over $`\mathbb{C}`$; its complex dimension; the six coordinates | the Fermat cubic fourfold; n = 4 | each extra dimension opens more cases: n = 5 leaves p = 2, 3 open |
| $`d`$ | the degree of the equation | 3 | $`h^{2,2}`$ grows: 142 at d = 4 |
| $`p`$ | the codimension of the subvarieties, half the degree 2p | p = 2 | p = 0, 1, n − 1, n are proved |
| $`H^{2p}(X, \mathbb{Q})`$, $`b_4`$ | rational cohomology in degree 2p; its dimension in degree 4 | $`b_4 = 23`$ | more classes to explain |
| $`H^{p,q}`$, $`h^{p,q}`$ | the classes of type (p, q); their dimension | $`h^{3,1}, h^{2,2}, h^{1,3}`$ = 1, 21, 1 | a bigger $`h^{2,2}`$ allows more algebraic classes |
| $`\mathrm{Hdg}^p(X)`$ | the Hodge classes: rational classes of type (p, p) | dimension 21 | at most $`h^{p,p}`$ |
| $`W`$, $`[W]`$, $`q_i`$ | a subvariety; its cycle class; rational weights | a plane $`P`$ on X | — |
| $`P \cdot P'`$ | the intersection number of two planes in X | 3, −1, 1 or 0 | — |
| $`h`$, $`h^2`$ | the hyperplane class; its square, the class of X cut by two general hyperplanes, a surface of degree 3; not a Hodge number, which always has two superscripts | $`h^2 \cdot h^2 = 3`$, $`h^2 \cdot P = 1`$ | — |
| $`p_1`$, $`p_2`$ | the Pontryagin classes, as multiples of $`h^2`$ and $`h^4`$, from which Hirzebruch's formula gives the signature | −3, 42 | — |
| $`\omega`$, $`a, b, c`$, $`u, v`$ | a primitive cube root of 1, so $`\omega^2 + \omega + 1 = 0`$; the plane coefficients, with cube −1; whole numbers in $`u + v\omega`$ | $`a, b, c \in \{-1, -\omega, -\omega^2\}`$ | — |

### When it holds

- **Projective, not just Kähler.** On a compact Kähler manifold (a complex manifold with a compatible metric, not necessarily cut out by polynomials) the statement fails. Zucker's 1977 appendix gives complex tori with Hodge classes that come from no subvariety, and Voisin (2002) found classes that are not even Chern classes of coherent sheaves. The conjecture is stated only for projective varieties.
- **Rational coefficients.** With integer coefficients it is false: Atiyah and Hirzebruch (1962) and Kollár (1992) gave counterexamples, shown on [The Hodge conjecture](../../22-Algebraic%20geometry/05-Cohomology%20and%20the%20Hodge%20Conjecture/08-hodge-conjecture-statement-and-known-cases.md).
- **Type (p, p).** A cycle class always has type (p, p). Drop the type test and the claim fails at once: on our example 23 rational classes would be called algebraic, and only 21 are.
- **Smooth, over $`\mathbb{C}`$.** The types need the complex structure of a smooth variety. Over a finite field the parallel question is the Tate conjecture, a different problem.

What the conjecture does **not** claim:

- It does not say the weights $`q_i`$ can all be chosen positive, so that the class comes from subvarieties alone rather than a difference of them. Deligne's statement says no one knows which classes should have that form.
- It does not give a method to find the subvarieties. A proof could show they exist without naming them.
- It does not claim anything for integer classes, or for non-projective manifolds.

---

## Why it works

The conjecture is open, so this section shows why the known part holds and where the known methods stop. The Fermat cubic fourfold is traced through both.

### Step 0: why subvarieties pass the test

A subvariety of codimension p has n − p complex directions. A form with more than n − p factors of $`dz`$, or more than n − p factors of $`d\bar z`$, restricts to zero on it. So the subvariety pairs only with forms of type (n − p, n − p), and by duality its class has type (p, p). It is also a rational class. This is the easy inclusion, proved on [The Hodge conjecture](../../22-Algebraic%20geometry/05-Cohomology%20and%20the%20Hodge%20Conjecture/08-hodge-conjecture-statement-and-known-cases.md).

### Step 1: which cases are theorems, and where they stop

Two theorems settle four values of p in every dimension:

1. **p = 1, Lefschetz (1, 1).** Every integer class of type (1, 1) is the first Chern class of a line bundle (the degree-2 class that measures how the bundle twists), and so the class of a divisor (a combination of codimension-1 subvarieties). The proof turns the type condition into a line bundle through the exponential map.
2. **p = n − 1, by hard Lefschetz.** Multiplying by the hyperplane class n − 2 times carries degree-2 Hodge classes onto degree-(2n − 2) Hodge classes. Cutting divisors with hyperplanes then gives curves.
3. **p = 0 and p = n** hold trivially: the whole variety and a point.

The checks list the codimensions these theorems leave open:

| Dimension n | Open codimensions p |
| --- | --- |
| 1, 2, 3 | none |
| 4 | 2 |
| 5 | 2, 3 |
| 6 | 2, 3, 4 |

So every variety of dimension at most 3 satisfies the conjecture. The first open case is p = 2 on a fourfold: classes in $`H^4`$ of a four-dimensional variety. That is our example.

### Step 2: the test side on the cubic fourfold

Griffiths' theorem computes the Hodge numbers of a hypersurface by counting monomials. For the Fermat cubic, a monomial counts when each exponent is at most 1. The type-(4 − p, p) part, apart from the class $`h^2`$, matches the monomials of degree 3(p + 1) − 6.

| p | degree | monomials | type |
| --- | --- | --- | --- |
| 0 | −3 | 0 | $`h^{4,0} = 0`$ |
| 1 | 0 | 1 | $`h^{3,1} = 1`$ |
| 2 | 3 | 20 | $`h^{2,2} = 20 + 1 = 21`$ |
| 3 | 6 | 1 | $`h^{1,3} = 1`$ |
| 4 | 9 | 0 | $`h^{0,4} = 0`$ |

The sum is $`b_4 = 23`$. Two topological numbers confirm it.

- **Euler number.** The Chern-class formula for a cubic in five-dimensional projective space gives 3 × 9 = 27. The other Betti numbers in even degree are 1 each, four of them, and those in odd degree are 0 (Lefschetz's hyperplane theorem matches the low degrees with projective space, and Poincaré duality mirrors them to the high degrees), so $`b_4 = 27 - 4 = 23`$.
- **Signature** (the number of positive minus negative directions of the intersection form on $`H^4`$). Hirzebruch's formula, with Pontryagin classes $`p_1 = -3h^2`$ and $`p_2 = 42h^4`$ written as multiples of powers of the hyperplane class $`h`$, with $`h^4 = 3`$, gives $`3 \times (7 \times 42 - 9)/45 = 19`$. The Hodge index theorem gives the same 19 from the Hodge numbers, so $`H^4`$ has 21 positive and 2 negative directions.

So $`\mathrm{Hdg}^2`$ has dimension at most 21. This is only what the test allows; it says nothing yet about subvarieties.

### Step 3: the subvariety side, from 405 planes

The Fermat cubic contains planes. Split the six coordinates into three pairs, such as (0, 1), (2, 3), (4, 5). Set $`x_0 = a x_1`$, $`x_2 = b x_3`$, $`x_4 = c x_5`$ with $`a^3 = b^3 = c^3 = -1`$. Then

```math
x_0^3 + x_1^3 + \dots + x_5^3 = (a^3 + 1)x_1^3 + (b^3 + 1)x_3^3 + (c^3 + 1)x_5^3 = 0
```

for every point of the plane. There are 15 ways to pair the coordinates and $`3^3 = 27`$ choices of a, b and c, so 405 planes.

Two planes in X can meet in a line, a point, or not at all. The check decides which by exact linear algebra in the numbers $`u + v\omega`$ with u, v whole numbers. The intersection numbers are standard for planes in a cubic fourfold:

| How two planes meet | Intersection number | Pairs per plane |
| --- | ---: | ---: |
| the same plane | 3 | 1 |
| in a line | −1 | 24 |
| in a point | 1 | 156 |
| not at all | 0 | 224 |

The 405 × 405 matrix of these numbers has rank 21 modulo the prime 2,147,483,647. Exact integer arithmetic confirms it: 21 chosen planes have Gram determinant 27, not zero, so their classes are independent over $`\mathbb{Q}`$. The form on them is positive definite, as the Hodge–Riemann relations (the sign rules for the intersection form on each type) say it must be on rational (2, 2) classes.

```math
21 \le \dim \text{span of the plane classes} \le \dim \mathrm{Hdg}^2 \le h^{2,2} = 21
```

**Read it aloud:** the planes give at least twenty-one directions, the test allows at most twenty-one, so every Hodge class in degree four is a rational combination of planes.

A consistency check uses the class $`h^2`$. The 3-space $`x_0 = a x_1`$, $`x_2 = b x_3`$ cuts X in $`x_4^3 + x_5^3 = 0`$: three planes through one line. So $`h^2`$ is the sum of three planes, and

```math
h^2 \cdot h^2 = 3 \times 3 + 6 \times (-1) = 3, \qquad h^2 \cdot P = 1 \text{ for every plane } P
```

Here 3 is the degree of X, and 1 says each plane has degree 1. All 405 triples agree.

### Step 4: why one example is not a proof

The Fermat cubic is special. A very general cubic fourfold contains no planes, and its only Hodge class in degree 4 is $`h^2`$, up to multiples. The 21 directions of type (2, 2) are still there, but only one of them is rational. So the plane count settles one variety, not the family.

Zucker's 1977 proof covers every smooth cubic fourfold with a different tool. In outline:

1. Sweep X by a pencil of hyperplane sections, a one-parameter family of cubic threefolds.
2. Each threefold has an intermediate Jacobian, a complex torus built from its $`H^3`$.
3. A Hodge class on X becomes a holomorphic section of the family of tori, a **normal function**.
4. On a cubic threefold the curves fill the whole intermediate Jacobian (Clemens and Griffiths), so the section is realised by curves, which sweep out a surface on X.

The argument rests on facts about cubic threefolds. No general method turns a rational (p, p) class into a subvariety when p is 2 or more. Deligne's statement notes that this is open even for the pieces of the diagonal of $`X \times X`$.

### Step 5: the status ledger

Each line separates the kind of claim from its status, with a date and a source.

| Statement | Kind | Status | Date | Source |
| --- | --- | --- | --- | --- |
| p = 1, every smooth projective X | theorem | proved | Lefschetz, 1924 | Voisin's survey |
| p = n − 1; all X with n ≤ 3 | theorem | proved | 1941, when Hodge proved hard Lefschetz | Voisin's survey; Deligne's statement |
| p = 2 on every smooth cubic fourfold | theorem | proved | 1977 | Zucker |
| integer coefficients | conjecture | refuted | 1962, 1992 | [The Hodge conjecture](../../22-Algebraic%20geometry/05-Cohomology%20and%20the%20Hodge%20Conjecture/08-hodge-conjecture-statement-and-known-cases.md) |
| compact Kähler manifolds | conjecture | refuted | 1977; stronger form 2002 | Zucker's appendix; Voisin's survey |
| every abelian fourfold | theorem | claimed | preprint 2025-02-05, revised 2025-06-08 | Markman, arXiv 2502.03415 |
| the general conjecture | conjecture | open | 2026-11-23 | Clay |

An abelian variety is a projective variety that is also a group, such as a product of elliptic curves. Markman's preprint proves that certain Hodge classes on abelian sixfolds are algebraic, and its abstract states that the conjecture for abelian fourfolds is known to follow. The arXiv page lists no journal publication as of 2026-11-23, so the status stays **claimed**, however strong the argument.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| monomials of degree 3 in 6 variables, exponents at most 1 | choose 3 of 6 | 20 |
| Hodge numbers in degree 4 | 0, 1, 20 + 1, 1, 0 | $`h^{2,2} = 21`$ |
| Euler number | 3 × 9 | 27, so $`b_4 = 23`$ |
| signature | 3 × (7 × 42 − 9) / 45 | 19, so (21, 2) |
| planes | 15 pairings × 27 | 405 |
| $`h^2 \cdot h^2`$ | 3 × 3 + 6 × (−1) | 3 |
| rank of the 405 × 405 matrix | elimination, then an exact 21 × 21 determinant | 21 |
| Hodge classes reached | 21 ≤ span ≤ 21 | **all 21** |

So the conjecture holds on the Fermat cubic fourfold, in the first degree where no theorem valid for all varieties forces it.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| A plane meets itself once, as two planes meeting in a point do | rank 405, more than $`b_4 = 23`$ | in a cubic fourfold $`P \cdot P = 3`$; the impossible rank exposes the error |
| A line of contact counted +1, not −1 | rank 345, more than $`b_4 = 23`$ | planes meeting in a line have intersection number −1 |
| Every rational class in $`H^4`$ is algebraic | 23 claimed; 21 algebraic | the two classes of types (3, 1) and (1, 3) fail the test |
| Every class of type (2, 2) is algebraic | 21 claimed; 1 on a very general cubic fourfold (quoted) | the test applies to rational classes only |

The checks compute every wrong answer except the 1, which is a quoted theorem.

---

## Code, from first principles, and it actually runs

Two independent roads meet at 21, and a third checks the class $`h^2`$. Road 1 is the test side: the Hodge numbers by counting monomials, checked against the Euler number and the signature. Road 2 is the subvariety side: the 405 planes, how each pair meets by exact algebra with cube roots of unity, and the rank of their intersection matrix modulo a prime, confirmed by an exact integer determinant. Road 3 builds the class $`h^2`$ from three planes in 405 ways and checks that all agree. Nothing here tests the conjecture itself. The asserts check one variety.

### Python

```python
# The Hodge conjecture in degree 4, on the Fermat cubic fourfold -- the check behind the card.
# Standard library only.  X: x0^3 + x1^3 + ... + x5^3 = 0 in P^5, a smooth cubic fourfold.
#   road 1 (Hodge side): h^(p,q) by counting monomials, against the Euler number and the signature
#   road 2 (cycle side): its 405 planes, how each pair meets (exact algebra in Z[w], w^3 = 1),
#                        and the rank of their intersection matrix, mod a prime and exactly
#   road 3 (one class two ways): h^2 as three planes in one 3-space, for all 405 such triples
from itertools import product
from math import comb

def mul(x, y):                    # Z[w] with w^2 = -1 - w; the pair (a, b) means a + b w
    return (x[0] * y[0] - x[1] * y[1], x[0] * y[1] + x[1] * y[0] - x[1] * y[1])
def sub(x, y):
    return (x[0] - y[0], x[1] - y[1])
Z0, ONE = (0, 0), (1, 0)
ROOTS = [(-1, 0), (0, -1), (1, 1)]                    # -1, -w, -w^2: the three cube roots of -1

def matchings(s):                 # the ways to split the list s into pairs
    if not s:
        return [[]]
    return [[(s[0], s[k])] + m for k in range(1, len(s)) for m in matchings(s[1:k] + s[k + 1:])]

def meet_dim(P, Q):               # dim of P n Q in C^6: 3 minus the rank of P's forms on Q's basis
    M = [[sub(ONE if l == i else (b if k == i else Z0), mul(a, ONE if l == j else (b if k == j else Z0)))
          for (k, l, b) in Q] for (i, j, a) in P]     # form x_i - a x_j on basis vector b e_k + e_l
    minor = lambda r, s, c, e: sub(mul(M[r][c], M[s][e]), mul(M[r][e], M[s][c]))
    det = Z0
    for c in range(3):
        t = mul(M[0][c], minor(1, 2, (c + 1) % 3, (c + 2) % 3))
        det = (det[0] + t[0], det[1] + t[1])
    if det != Z0:
        return 0
    if any(minor(r, s, c, e) != Z0 for r, s in ((0, 1), (0, 2), (1, 2)) for c, e in ((0, 1), (0, 2), (1, 2))):
        return 1
    return 2 if any(x != Z0 for row in M for x in row) else 3

PRIME = 2 ** 31 - 1
def rank_mod(G, p=PRIME):         # rank by elimination modulo a prime: a lower bound for the rank over Q
    m, r = [[x % p for x in row] for row in G], 0
    for c in range(len(m[0])):
        piv = next((i for i in range(r, len(m)) if m[i][c]), None)
        if piv is None:
            continue
        m[r], m[piv] = m[piv], m[r]
        inv = pow(m[r][c], p - 2, p)
        for i in range(r + 1, len(m)):
            if m[i][c]:
                f = m[i][c] * inv % p
                m[i] = [(x - f * y) % p for x, y in zip(m[i], m[r])]
        r += 1
    return r

def bareiss_det(m):               # exact determinant by fraction-free elimination
    m, prev, sign, n = [row[:] for row in m], 1, 1, len(m)
    for c in range(n):
        piv = next((i for i in range(c, n) if m[i][c] != 0), None)
        if piv is None:
            return 0
        if piv != c:
            m[c], m[piv], sign = m[piv], m[c], -sign
        for i in range(c + 1, n):
            for j in range(c + 1, n):
                m[i][j] = (m[c][c] * m[i][j] - m[i][c] * m[c][j]) // prev
        prev = m[c][c]
    return sign * prev

# ---- road 1: Hodge numbers of a smooth cubic fourfold ----
n, d = 4, 3
deg = [(p + 1) * d - (n + 2) for p in range(n + 1)]
jac = [sum(1 for e in product(range(d - 1), repeat=n + 2) if sum(e) == t) for t in deg]
hodge = jac[:]
hodge[2] += 1                                         # the class h^2 of a plane section of a plane section
b4 = sum(hodge)
chern = sum(comb(n + 2, i) * (-d) ** (n - i) for i in range(n + 1))
euler = d * chern
p1, p2 = comb(6, 1) - d ** 2, comb(6, 2) - 6 * d ** 2 + d ** 4
assert d * (7 * p2 - p1 ** 2) % 45 == 0
sig = d * (7 * p2 - p1 ** 2) // 45
sig_hodge = sum((-1) ** p * hodge[p] for p in range(n + 1)) + sum((-1) ** k for k in (0, 1, 3, 4))  # + h^k,k
print(f"road 1, the Hodge side of a smooth fourfold of degree {d}")
print(f"monomials with exponents at most {d - 2}, of degree {', '.join(map(str, deg))}: {', '.join(map(str, jac))}")
print(f"h^4,0 = {hodge[0]}, h^3,1 = {hodge[1]}, h^2,2 = {jac[2]} + 1 = {hodge[2]}, h^1,3 = {hodge[3]}, "
      f"h^0,4 = {hodge[4]}; b4 = {b4}")
print(f"Euler number {d} x {chern} = {euler}, so b4 = {euler} - 4 = {euler - 4}")
print(f"signature from p1 = {p1}, p2 = {p2}: {d} x (7 x {p2} - {p1 * p1}) / 45 = {sig}; "
      f"from Hodge numbers: {sig_hodge}; so H^4 has signature ({(b4 + sig) // 2}, {(b4 - sig) // 2})")

# ---- road 2: the 405 planes and their intersection matrix ----
planes = [[(i, j, c) for (i, j), c in zip(mt, cs)] for mt in matchings(list(range(6)))
          for cs in product(ROOTS, repeat=3)]
assert all(mul(mul(r, r), r) == (-1, 0) for r in ROOTS)   # c^3 = -1: each plane lies on X
N = len(planes)
VAL = {3: 3, 2: -1, 1: 1, 0: 0}                       # same plane, a line, a point, empty
dims = [[3 if r == c else None for c in range(N)] for r in range(N)]
for r in range(N):
    for c in range(r + 1, N):
        dims[r][c] = dims[c][r] = meet_dim(planes[r], planes[c])
G = [[VAL[x] for x in row] for row in dims]
kinds = [sorted({row.count(k) for row in dims}) for k in (2, 1, 0)]
print(f"road 2, the cycle side: {len(matchings(list(range(6))))} pairings x 3^3 roots = {N} planes on the Fermat cubic fourfold")
print(f"each plane meets {kinds[0][0]} others in a line, {kinds[1][0]} in a point, misses {kinds[2][0]}; "
      f"P.P = {G[0][0]}")
r405 = rank_mod(G)
print(f"rank of the {N} x {N} intersection matrix modulo the prime {PRIME}: {r405}")
basis, minors = [], [1]
for c in range(N):                                    # grow a basis while the Gram determinant stays nonzero
    dt = bareiss_det([[G[a][b] for b in basis + [c]] for a in basis + [c]])
    if dt != 0:
        basis, minors = basis + [c], minors + [dt]
neg = sum(1 for u, v in zip(minors, minors[1:]) if (u > 0) != (v > 0))
print(f"independent planes found: {len(basis)}; exact Gram determinant of the {len(basis)}: {minors[-1]}")
print(f"signature of the intersection form on them: ({len(basis) - neg}, {neg})")

# ---- road 3: h^2 as three planes in one 3-space ----
triples = [[t for t in range(N) if all(planes[t][q] == planes[s][q] for q in range(3) if q != v)]
           for s in range(N) for v in range(3)]
triples = sorted({tuple(t) for t in triples})
rows = {tuple(sum(G[m][c] for m in t) for c in range(N)) for t in triples}
row = next(iter(rows))
h2sq = sum(row[m] for m in triples[0])
print(f"road 3, h^2 as three planes sharing a line: {len(triples)} triples; distinct rows h^2.P: {len(rows)}")
print(f"h^2.P for every plane: {', '.join(map(str, sorted(set(row))))}; h^2.h^2 = 3 x 3 + 6 x (-1) = {h2sq}")

# ---- what breaks ----
wrong = [[1 if r == c else G[r][c] for c in range(N)] for r in range(N)]
flip = [[-x if x == -1 else x for x in row] for row in G]
print(f"mistake 1, a plane meets itself once (P.P = 1): rank {rank_mod(wrong)}, more than b4 = {b4}")
print(f"mistake 2, a line meeting counted +1, not -1: rank {rank_mod(flip)}, more than b4 = {b4}")
print(f"mistake 3, every rational class in H^4 algebraic: {b4} claimed, {len(basis)} algebraic here")
print(f"mistake 4, every (2,2) class algebraic: h^2,2 = {hodge[2]} claimed, 1 for a very general cubic (quoted)")
for k in range(1, 7):                                 # degrees 2p left open by Lefschetz (p = 0, 1, n-1, n)
    left = [str(p) for p in range(k + 1) if p not in (0, 1, k - 1, k)]
    print(f"dimension {k}: codimensions p not covered by Lefschetz: {', '.join(left) or 'none'}")
assert hodge == [0, 1, 21, 1, 0] and b4 == euler - 4 == 23           # road 1 against the Euler number
assert sig == sig_hodge == 19 and all(len(k) == 1 for k in kinds)   # road 1 against the signature
assert r405 == len(basis) == hodge[2] == 21                         # road 2 meets road 1
assert neg == 0 and minors[-1] > 0                                  # positive definite, as (2,2) classes are
assert len(rows) == 1 and set(row) == {1} and h2sq == 3             # road 3: h^2.P = 1, h^4 = 3 = degree
assert rank_mod(wrong) > b4 and rank_mod(flip) > b4                 # the wrong forms are impossible
print("ALL CHECKS PASS")
```

**Ran 2026-11-23 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
road 1, the Hodge side of a smooth fourfold of degree 3
monomials with exponents at most 1, of degree -3, 0, 3, 6, 9: 0, 1, 20, 1, 0
h^4,0 = 0, h^3,1 = 1, h^2,2 = 20 + 1 = 21, h^1,3 = 1, h^0,4 = 0; b4 = 23
Euler number 3 x 9 = 27, so b4 = 27 - 4 = 23
signature from p1 = -3, p2 = 42: 3 x (7 x 42 - 9) / 45 = 19; from Hodge numbers: 19; so H^4 has signature (21, 2)
road 2, the cycle side: 15 pairings x 3^3 roots = 405 planes on the Fermat cubic fourfold
each plane meets 24 others in a line, 156 in a point, misses 224; P.P = 3
rank of the 405 x 405 intersection matrix modulo the prime 2147483647: 21
independent planes found: 21; exact Gram determinant of the 21: 27
signature of the intersection form on them: (21, 0)
road 3, h^2 as three planes sharing a line: 405 triples; distinct rows h^2.P: 1
h^2.P for every plane: 1; h^2.h^2 = 3 x 3 + 6 x (-1) = 3
mistake 1, a plane meets itself once (P.P = 1): rank 405, more than b4 = 23
mistake 2, a line meeting counted +1, not -1: rank 345, more than b4 = 23
mistake 3, every rational class in H^4 algebraic: 23 claimed, 21 algebraic here
mistake 4, every (2,2) class algebraic: h^2,2 = 21 claimed, 1 for a very general cubic (quoted)
dimension 1: codimensions p not covered by Lefschetz: none
dimension 2: codimensions p not covered by Lefschetz: none
dimension 3: codimensions p not covered by Lefschetz: none
dimension 4: codimensions p not covered by Lefschetz: 2
dimension 5: codimensions p not covered by Lefschetz: 2, 3
dimension 6: codimensions p not covered by Lefschetz: 2, 3, 4
ALL CHECKS PASS
```

### Rust

```rust
// The Hodge conjecture in degree 4, on the Fermat cubic fourfold -- the check behind the card.
// std only.  X: x0^3 + x1^3 + ... + x5^3 = 0 in P^5, a smooth cubic fourfold.
//   road 1 (Hodge side): h^(p,q) by counting monomials, against the Euler number and the signature
//   road 2 (cycle side): its 405 planes, how each pair meets (exact algebra in Z[w], w^3 = 1),
//                        and the rank of their intersection matrix, mod a prime and exactly
//   road 3 (one class two ways): h^2 as three planes in one 3-space, for all 405 such triples
use std::collections::BTreeSet;
type W = (i64, i64); // a + b w in Z[w], with w^2 = -1 - w
type Plane = Vec<(usize, usize, W)>; // forms x_i - c x_j
const Z0: W = (0, 0); const ONE: W = (1, 0); const PRIME: i64 = (1 << 31) - 1;
const ROOTS: [W; 3] = [(-1, 0), (0, -1), (1, 1)]; // -1, -w, -w^2: the three cube roots of -1

fn mul(x: W, y: W) -> W { (x.0 * y.0 - x.1 * y.1, x.0 * y.1 + x.1 * y.0 - x.1 * y.1) }
fn sub(x: W, y: W) -> W { (x.0 - y.0, x.1 - y.1) }
fn comb(n: i64, k: i64) -> i64 { (0..k).fold(1, |a, i| a * (n - i) / (i + 1)) }

fn matchings(s: &[usize]) -> Vec<Vec<(usize, usize)>> {
    if s.is_empty() { return vec![vec![]]; } let mut out = vec![];
    for k in 1..s.len() {
        let rest: Vec<usize> = s[1..].iter().cloned().filter(|&x| x != s[k]).collect();
        for m in matchings(&rest) {
            out.push([vec![(s[0], s[k])], m].concat());
        }
    }
    out
}

fn meet_dim(p: &Plane, q: &Plane) -> usize {
    let coord = |k: usize, l: usize, b: W, t: usize| if t == l { ONE } else if t == k { b } else { Z0 };
    let m: Vec<Vec<W>> = p.iter().map(|&(i, j, a)| q.iter()
        .map(|&(k, l, b)| sub(coord(k, l, b, i), mul(a, coord(k, l, b, j)))).collect()).collect();
    let minor = |r: usize, s: usize, c: usize, e: usize| sub(mul(m[r][c], m[s][e]), mul(m[r][e], m[s][c]));
    let mut det = Z0;
    for c in 0..3 {
        let t = mul(m[0][c], minor(1, 2, (c + 1) % 3, (c + 2) % 3));
        det = (det.0 + t.0, det.1 + t.1);
    }
    if det != Z0 { return 0 }
    let pairs = [(0, 1), (0, 2), (1, 2)];
    if pairs.iter().any(|&(r, s)| pairs.iter().any(|&(c, e)| minor(r, s, c, e) != Z0)) { return 1; }
    if m.iter().flatten().any(|&x| x != Z0) { 2 } else { 3 }
}

fn rank_mod(g: &Vec<Vec<i64>>) -> usize {
    let p = PRIME;
    let mut m: Vec<Vec<i64>> = g.iter().map(|row| row.iter().map(|x| x.rem_euclid(p)).collect()).collect();
    let mut r = 0;
    for c in 0..m[0].len() {
        let Some(piv) = (r..m.len()).find(|&i| m[i][c] != 0) else { continue };
        m.swap(r, piv);
        let (mut inv, mut b, mut e) = (1i64, m[r][c], p - 2);
        while e > 0 { if e & 1 == 1 { inv = inv * b % p; } b = b * b % p; e >>= 1; }
        for i in r + 1..m.len() {
            if m[i][c] != 0 {
                let f = m[i][c] * inv % p;
                let top = m[r].clone();
                for (x, y) in m[i].iter_mut().zip(top) { *x = (*x - f * y).rem_euclid(p); }
            }
        }
        r += 1;
    }
    r
}

fn bareiss_det(a: Vec<Vec<i128>>) -> i128 {
    let (n, mut m, mut prev, mut sign) = (a.len(), a, 1i128, 1i128);
    for c in 0..n {
        let Some(piv) = (c..n).find(|&i| m[i][c] != 0) else { return 0 };
        if piv != c { m.swap(c, piv); sign = -sign; }
        for i in c + 1..n {
            for j in c + 1..n {
                m[i][j] = (m[c][c].checked_mul(m[i][j]).unwrap() - m[i][c].checked_mul(m[c][j]).unwrap()) / prev;
            }
        }
        prev = m[c][c];
    }
    sign * prev
}

fn join(v: &[i64]) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ") }

fn main() {
    // ---- road 1: Hodge numbers of a smooth cubic fourfold ----
    let (n, d) = (4i64, 3i64);
    let deg: Vec<i64> = (0..=n).map(|p| (p + 1) * d - (n + 2)).collect();
    let digits = |e: i64| (0..6).map(|k| e / (d - 1).pow(k) % (d - 1)).sum::<i64>(); // exponents below d - 1
    let jac: Vec<i64> = deg.iter().map(|&t| (0..(d - 1).pow(6)).filter(|&e| digits(e) == t).count() as i64).collect();
    let hodge: Vec<i64> = jac.iter().enumerate().map(|(p, &x)| x + (p == 2) as i64).collect(); // + the class h^2
    let b4: i64 = hodge.iter().sum();
    let chern: i64 = (0..=n).map(|i| comb(n + 2, i) * (-d).pow((n - i) as u32)).sum();
    let euler = d * chern;
    let (p1, p2) = (comb(6, 1) - d * d, comb(6, 2) - 6 * d * d + d.pow(4));
    assert!(d * (7 * p2 - p1 * p1) % 45 == 0);
    let sig = d * (7 * p2 - p1 * p1) / 45;
    let sig_hodge: i64 = (0..=4).map(|p| (-1i64).pow(p as u32) * hodge[p]).sum::<i64>()
        + [0u32, 1, 3, 4].iter().map(|&k| (-1i64).pow(k)).sum::<i64>(); // + h^k,k
    println!("road 1, the Hodge side of a smooth fourfold of degree {}", d);
    println!("monomials with exponents at most {}, of degree {}: {}", d - 2, join(&deg), join(&jac));
    println!("h^4,0 = {}, h^3,1 = {}, h^2,2 = {} + 1 = {}, h^1,3 = {}, h^0,4 = {}; b4 = {}",
        hodge[0], hodge[1], jac[2], hodge[2], hodge[3], hodge[4], b4);
    println!("Euler number {} x {} = {}, so b4 = {} - 4 = {}", d, chern, euler, euler, euler - 4);
    println!("signature from p1 = {}, p2 = {}: {} x (7 x {} - {}) / 45 = {}; from Hodge numbers: {}; so H^4 has signature ({}, {})",
        p1, p2, d, p2, p1 * p1, sig, sig_hodge, (b4 + sig) / 2, (b4 - sig) / 2);

    // ---- road 2: the 405 planes and their intersection matrix ----
    let mut planes: Vec<Plane> = vec![];
    for mt in matchings(&[0, 1, 2, 3, 4, 5]) {
        for a in ROOTS { for b in ROOTS { for c in ROOTS {
            planes.push(mt.iter().zip([a, b, c]).map(|(&(i, j), r)| (i, j, r)).collect());
        } } }
    }
    assert!(ROOTS.iter().all(|&r| mul(mul(r, r), r) == (-1, 0))); // c^3 = -1: each plane lies on X
    let nn = planes.len();
    let val = |x: usize| [0i64, 1, -1, 3][x]; // empty, a point, a line, same plane
    let mut dims = vec![vec![3usize; nn]; nn];
    for r in 0..nn { for c in r + 1..nn { let x = meet_dim(&planes[r], &planes[c]); dims[r][c] = x; dims[c][r] = x; } }
    let g: Vec<Vec<i64>> = dims.iter().map(|row| row.iter().map(|&x| val(x)).collect()).collect();
    let kinds: Vec<BTreeSet<usize>> = [2usize, 1, 0].iter()
        .map(|&k| dims.iter().map(|row| row.iter().filter(|&&x| x == k).count()).collect()).collect();
    let first = |s: &BTreeSet<usize>| *s.iter().next().unwrap();
    println!("road 2, the cycle side: {} pairings x 3^3 roots = {} planes on the Fermat cubic fourfold", matchings(&[0, 1, 2, 3, 4, 5]).len(), nn);
    println!("each plane meets {} others in a line, {} in a point, misses {}; P.P = {}",
        first(&kinds[0]), first(&kinds[1]), first(&kinds[2]), g[0][0]);
    let r405 = rank_mod(&g);
    println!("rank of the {} x {} intersection matrix modulo the prime {}: {}", nn, nn, PRIME, r405);
    let (mut basis, mut minors): (Vec<usize>, Vec<i128>) = (vec![], vec![1]);
    for c in 0..nn {
        let idx = [basis.clone(), vec![c]].concat();
        let dt = bareiss_det(idx.iter().map(|&a| idx.iter().map(|&b| g[a][b] as i128).collect()).collect());
        if dt != 0 { basis = idx; minors.push(dt); }
    }
    let neg = minors.windows(2).filter(|w| (w[0] > 0) != (w[1] > 0)).count();
    println!("independent planes found: {}; exact Gram determinant of the {}: {}", basis.len(), basis.len(), minors.last().unwrap());
    println!("signature of the intersection form on them: ({}, {})", basis.len() - neg, neg);

    // ---- road 3: h^2 as three planes in one 3-space ----
    let mut tset: BTreeSet<Vec<usize>> = BTreeSet::new();
    for (s, v) in (0..nn).flat_map(|s| (0..3).map(move |v| (s, v))) {
        tset.insert((0..nn).filter(|&t| (0..3).all(|q| q == v || planes[t][q] == planes[s][q])).collect());
    }
    let triples: Vec<Vec<usize>> = tset.into_iter().collect();
    let rows: BTreeSet<Vec<i64>> = triples.iter()
        .map(|t| (0..nn).map(|c| t.iter().map(|&m| g[m][c]).sum()).collect()).collect();
    let row = rows.iter().next().unwrap().clone();
    let h2sq: i64 = triples[0].iter().map(|&m| row[m]).sum();
    let rowset: Vec<i64> = row.iter().cloned().collect::<BTreeSet<i64>>().into_iter().collect();
    println!("road 3, h^2 as three planes sharing a line: {} triples; distinct rows h^2.P: {}", triples.len(), rows.len());
    println!("h^2.P for every plane: {}; h^2.h^2 = 3 x 3 + 6 x (-1) = {}", join(&rowset), h2sq);

    // ---- what breaks ----
    let wrong: Vec<Vec<i64>> = (0..nn).map(|r| (0..nn).map(|c| if r == c { 1 } else { g[r][c] }).collect()).collect();
    let flip: Vec<Vec<i64>> = g.iter().map(|row| row.iter().map(|&x| if x == -1 { 1 } else { x }).collect()).collect();
    let (rw, rf) = (rank_mod(&wrong), rank_mod(&flip));
    println!("mistake 1, a plane meets itself once (P.P = 1): rank {}, more than b4 = {}", rw, b4);
    println!("mistake 2, a line meeting counted +1, not -1: rank {}, more than b4 = {}", rf, b4);
    println!("mistake 3, every rational class in H^4 algebraic: {} claimed, {} algebraic here", b4, basis.len());
    println!("mistake 4, every (2,2) class algebraic: h^2,2 = {} claimed, 1 for a very general cubic (quoted)", hodge[2]);
    for k in 1..=6i64 { // degrees 2p left open by Lefschetz (p = 0, 1, n-1, n)
        let left: Vec<i64> = (0..=k).filter(|&p| ![0, 1, k - 1, k].contains(&p)).collect();
        println!("dimension {}: codimensions p not covered by Lefschetz: {}", k,
            if left.is_empty() { "none".to_string() } else { join(&left) });
    }
    assert!(hodge == vec![0, 1, 21, 1, 0] && b4 == euler - 4 && b4 == 23); // road 1 against the Euler number
    assert!(sig == sig_hodge && sig == 19 && kinds.iter().all(|k| k.len() == 1)); // road 1 against the signature
    assert!(r405 == basis.len() && r405 as i64 == hodge[2] && r405 == 21); // road 2 meets road 1
    assert!(neg == 0 && *minors.last().unwrap() > 0); // positive definite, as (2,2) classes are
    assert!(rows.len() == 1 && rowset == vec![1] && h2sq == 3); // road 3: h^2.P = 1, h^4 = 3 = degree
    assert!(rw as i64 > b4 && rf as i64 > b4); // the wrong forms are impossible
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-23 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
road 1, the Hodge side of a smooth fourfold of degree 3
monomials with exponents at most 1, of degree -3, 0, 3, 6, 9: 0, 1, 20, 1, 0
h^4,0 = 0, h^3,1 = 1, h^2,2 = 20 + 1 = 21, h^1,3 = 1, h^0,4 = 0; b4 = 23
Euler number 3 x 9 = 27, so b4 = 27 - 4 = 23
signature from p1 = -3, p2 = 42: 3 x (7 x 42 - 9) / 45 = 19; from Hodge numbers: 19; so H^4 has signature (21, 2)
road 2, the cycle side: 15 pairings x 3^3 roots = 405 planes on the Fermat cubic fourfold
each plane meets 24 others in a line, 156 in a point, misses 224; P.P = 3
rank of the 405 x 405 intersection matrix modulo the prime 2147483647: 21
independent planes found: 21; exact Gram determinant of the 21: 27
signature of the intersection form on them: (21, 0)
road 3, h^2 as three planes sharing a line: 405 triples; distinct rows h^2.P: 1
h^2.P for every plane: 1; h^2.h^2 = 3 x 3 + 6 x (-1) = 3
mistake 1, a plane meets itself once (P.P = 1): rank 405, more than b4 = 23
mistake 2, a line meeting counted +1, not -1: rank 345, more than b4 = 23
mistake 3, every rational class in H^4 algebraic: 23 claimed, 21 algebraic here
mistake 4, every (2,2) class algebraic: h^2,2 = 21 claimed, 1 for a very general cubic (quoted)
dimension 1: codimensions p not covered by Lefschetz: none
dimension 2: codimensions p not covered by Lefschetz: none
dimension 3: codimensions p not covered by Lefschetz: none
dimension 4: codimensions p not covered by Lefschetz: 2
dimension 5: codimensions p not covered by Lefschetz: 2, 3
dimension 6: codimensions p not covered by Lefschetz: 2, 3, 4
ALL CHECKS PASS
```

### Lean

Lean proves the counting facts of Step 1 for every dimension n, the plane equation of Step 3, and the worked numbers.

- Take any dimension n. Then the proved codimensions 0, 1, n − 1 and n cover every codimension from 0 to n exactly when n is at most 3. Lean checks this count only; Lefschetz's theorems themselves are quoted.
- Take any dimension n. Then the codimensions left open are exactly 2, 3, …, n − 2.
- The table in Step 1 is checked row by row, for dimensions 1 to 6.
- Take a, b and c whose cubes are −1, and the plane they give in Step 3. Then every point of that plane satisfies the Fermat cubic's equation.
- The worked numbers check: 20 monomials, 23 directions in all, Euler number 27, and signature 19.
- The signature 19 splits the 23 directions into 21 positive and 2 negative.
- There are 15 pairings times 27 choices of a, b and c, so 405 planes.
- Take $`h^2`$ as three planes through one line. Then $`h^2 \cdot h^2 = 3 \times 3 + 6 \times (-1) = 3`$.

How the 405 planes meet, and their rank 21, are left to the Python and Rust checks; the conjecture stays open.

```lean
-- The Hodge conjecture: this file proves the exact whole-number and algebraic facts behind the card, namely which codimensions Lefschetz's theorems leave open, that the Fermat cubic fourfold contains its 405 planes, and the card's worked counts.
import Mathlib.RingTheory.RootsOfUnity.PrimitiveRoots
import Mathlib.Data.Complex.Basic
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open Finset

/-- Lefschetz's (1, 1) theorem and hard Lefschetz settle the codimensions p = 0, 1, n − 1 and n
in every dimension n. These four values cover every codimension p from 0 to n exactly when the
dimension n is at most 3; so every variety of dimension at most 3 satisfies the conjecture, and
dimension 4 is the first with an open case. -/
theorem lefschetz_cases_cover_all_codimensions_iff (n : ℕ) :
    (∀ p ≤ n, p = 0 ∨ p = 1 ∨ p = n - 1 ∨ p = n) ↔ n ≤ 3 := by
  constructor
  · intro h
    by_contra hn
    have := h 2 (by omega)
    omega
  · intro hn p hp
    omega

/-- The codimensions p from 0 to n that the Lefschetz cases (p = 0, 1, n − 1, n) leave open
are exactly 2, 3, …, n − 2. -/
theorem lefschetz_open_codimensions (n : ℕ) :
    (range (n + 1)).filter (fun p => p ≠ 0 ∧ p ≠ 1 ∧ p ≠ n - 1 ∧ p ≠ n) = Icc 2 (n - 2) := by
  ext p
  simp only [mem_filter, mem_range, mem_Icc]
  omega

/-- Each plane x₀ = a x₁, x₂ = b x₃, x₄ = c x₅, with a³ = b³ = c³ = −1, lies on the Fermat cubic
fourfold x₀³ + x₁³ + x₂³ + x₃³ + x₄³ + x₅³ = 0: every point of the plane satisfies the equation. -/
theorem plane_lies_on_fermat_cubic {R : Type*} [CommRing R] (a b c : R)
    (ha : a ^ 3 = -1) (hb : b ^ 3 = -1) (hc : c ^ 3 = -1) (x₁ x₃ x₅ : R) :
    (a * x₁) ^ 3 + x₁ ^ 3 + (b * x₃) ^ 3 + x₃ ^ 3 + (c * x₅) ^ 3 + x₅ ^ 3 = 0 := by
  rw [mul_pow, mul_pow, mul_pow, ha, hb, hc]
  ring

#print axioms lefschetz_cases_cover_all_codimensions_iff
#print axioms lefschetz_open_codimensions
#print axioms plane_lies_on_fermat_cubic

-- The card's table of open codimensions: dimensions 1 to 6.
example : (range 4).filter (fun p => p ≠ 0 ∧ p ≠ 1 ∧ p ≠ 3 - 1 ∧ p ≠ 3) = ∅ := by decide
example : (range 5).filter (fun p => p ≠ 0 ∧ p ≠ 1 ∧ p ≠ 4 - 1 ∧ p ≠ 4) = {2} := by decide
example : (range 6).filter (fun p => p ≠ 0 ∧ p ≠ 1 ∧ p ≠ 5 - 1 ∧ p ≠ 5) = {2, 3} := by decide
example : (range 7).filter (fun p => p ≠ 0 ∧ p ≠ 1 ∧ p ≠ 6 - 1 ∧ p ≠ 6) = {2, 3, 4} := by decide

-- Monomials of degree 3 in 6 variables with every exponent at most 1: choose 3 of 6.
example : Nat.choose 6 3 = 20 := by decide
-- Hodge numbers in degree 4 add up to b₄ = 23.
example : 0 + 1 + (20 + 1) + 1 + 0 = 23 := by norm_num
-- Euler number: 3 × (sum of C(6, i) (−3)^(4 − i) for i = 0..4) = 3 × 9 = 27, so b₄ = 27 − 4 = 23.
example : (∑ i ∈ range 5, (Nat.choose 6 i : ℤ) * (-3) ^ (4 - i)) = 9 := by decide
example : (3 : ℤ) * 9 - 4 = 23 := by norm_num
-- Pontryagin classes p₁ = 6 − 9 = −3, p₂ = 15 − 6 × 9 + 81 = 42, and the signature 3 × (7 × 42 − 9) / 45 = 19.
example : (6 : ℤ) - 3 ^ 2 = -3 ∧ (15 : ℤ) - 6 * 3 ^ 2 + 3 ^ 4 = 42 := by norm_num
example : (3 : ℤ) * (7 * 42 - (-3) ^ 2) = 19 * 45 := by norm_num
-- The same signature from the Hodge numbers 0, 1, 21, 1, 0 and h^(k,k) = 1 for k = 0, 1, 3, 4.
example : ((0 : ℤ) - 1 + 21 - 1 + 0) + (1 - 1 - 1 + 1) = 19 := by norm_num
-- So H⁴ has 21 positive and 2 negative directions.
example : (23 + 19) / 2 = 21 ∧ (23 - 19) / 2 = 2 := by norm_num
-- 15 pairings of the six coordinates times 3³ choices of a, b, c: 405 planes.
example : 15 * 3 ^ 3 = 405 := by norm_num
-- h² · h² = 3 × 3 + 6 × (−1) = 3, the degree of the cubic.
example : (3 : ℤ) * 3 + 6 * (-1) = 3 := by norm_num
```

**Checked 2026-11-23 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'lefschetz_cases_cover_all_codimensions_iff' depends on axioms: [propext, Quot.sound]
'lefschetz_open_codimensions' depends on axioms: [propext, Classical.choice, Quot.sound]
'plane_lies_on_fermat_cubic' depends on axioms: [propext, Quot.sound]
```

> [!TIP]
> **Try changing**
> - **Guess first: a quartic fourfold.** Set `n, d = 4, 4`. How big is $`h^{2,2}`$ now? Road 1 prints $`h^{3,1} = 21`$, $`h^{2,2} = 142`$, $`b_4 = 184`$, Euler number 188 and signature (142, 42). Roads 2 and 3 are written for the cubic, so their asserts stop the run.
> - **Guess first: a small prime.** Set the default in `rank_mod` to `p=3`. Does the rank go up or down? It drops to 19. A rank modulo a prime can only undercount. The exact determinant proves at least 21; $`h^{2,2}`$ = 21 caps it.
> - **Guess first: the self-intersection.** In `wrong`, the 1 replaces 3. The rank jumps to 405, far above 23. A wrong intersection number cannot hide: cohomology has only 23 directions.
> - **Guess first: the sign of a line.** `flip` counts a line meeting as +1. The rank is 345. The −1 is forced.

---

## The usual mistake

> [!warning]
> **Reading a settled family as progress toward a proof.** The conjecture holds for every variety of dimension at most 3, for every cubic fourfold, and for the Fermat cubic fourfold computed here. None of this moves the general case. Each success uses a feature of its family, such as a pencil of well-understood cubic threefolds, that a general fourfold lacks. The status is open as of 2026-11-23.
>
> - **Integer coefficients.** Hodge's first version used integers. It is false: there are integer classes of type (p, p) that no combination of subvarieties reaches.
> - **Type alone.** "Every class of type (2, 2) is algebraic" claims 21 directions on every cubic fourfold. A very general one has 1.
> - **Kähler is enough.** On some compact Kähler manifolds the statement fails, so the projective hypothesis does real work.
> - **Claimed as proved.** Markman's 2025 abelian-fourfold result is a preprint with no journal reference found as of 2026-11-23. It is recorded as claimed.

---

## Where you meet it in real life

- **The Millennium Prize.** Clay offers $1 million for a solution, under its published rules. Its page lists the problem as "Unsolved".
- **Classifying cubic fourfolds.** Extra Hodge classes, beyond $`h^2`$, mark the special cubic fourfolds, such as those that contain a plane. Hassett's divisors of special cubic fourfolds are sorted this way, and the question of which cubic fourfolds are rational is studied through them.
- **Motives.** Grothendieck's theory of motives, a hoped-for universal cohomology of varieties, needs to know which cohomology classes are algebraic. Over $`\mathbb{C}`$ the Hodge conjecture is the predicted answer.
- **Arithmetic.** Over finite fields the Tate conjecture asks the same question with Frobenius in place of type (p, p).

> **Say it back**
> The Hodge conjecture is one of the seven Clay Millennium Problems, stated by Deligne and open as of 2026-11-23. It says every rational class of type (p, p) on a smooth complex projective variety is a rational combination of classes of subvarieties. Lefschetz's theorem settles p = 1, and with it every variety of dimension at most 3. The first open case is codimension 2 on fourfolds. On the Fermat cubic fourfold the test allows 21 directions and its 405 planes reach all 21, but one variety, or one family, is not a proof.

---

## What this builds on

- [The Hodge conjecture](../../22-Algebraic%20geometry/05-Cohomology%20and%20the%20Hodge%20Conjecture/08-hodge-conjecture-statement-and-known-cases.md): the statement, the proof of Lefschetz's (1, 1) theorem, the failure over the integers, and the Picard number of the Fermat quartic K3 surface, where lines reach every Hodge class in degree 2, as the planes here reach every one in degree 4.
- [Hodge decomposition](../../22-Algebraic%20geometry/05-Cohomology%20and%20the%20Hodge%20Conjecture/05-hodge-decomposition.md): the split of cohomology by type, and the Hodge numbers that bound the algebraic classes.

## Where this goes next

- [Yang-Mills existence and mass gap](06-yang-mills-and-the-mass-gap.md): the next card on this shelf, a Millennium Problem from physics rather than geometry.
- [Birch and Swinnerton-Dyer](02-birch-and-swinnerton-dyer.md): another Clay problem that asks an analytic invariant to count algebraic objects.
- [The Riemann hypothesis](01-riemann-hypothesis.md), [P versus NP](03-p-versus-np.md), [Navier-Stokes](04-navier-stokes-existence-and-smoothness.md) and [The Poincare conjecture, solved](07-poincare-conjecture-solved.md): the rest of the shelf, the last of them the one problem Clay lists as solved.

The question this card leaves open: for p of 2 or more, is there any method that turns a rational class of type (p, p) into a subvariety?

---

## Sources

Verified 2026-11-23: every link below resolves to the publisher's page.

- Deligne, Pierre. "The Hodge Conjecture." Clay Mathematics Institute, official problem description. [claymath.org](https://www.claymath.org/millennium/hodge-conjecture/). The exact statement, the status "Unsolved", and the remark on the diagonal of $`X \times X`$; Clay's [Millennium Problems page](https://www.claymath.org/millennium-problems/) gives the 2000-05-24 announcement and the prize.
- Voisin, Claire. "The Hodge Conjecture." In *Open Problems in Mathematics*, Springer, 2016, 521–543. [DOI 10.1007/978-3-319-32162-2_17](https://doi.org/10.1007/978-3-319-32162-2_17). A survey of the known cases, the Lefschetz theorems and the failure for Kähler manifolds.
- Zucker, Steven. "The Hodge conjecture for cubic fourfolds." *Compositio Mathematica* 34, no. 2 (1977): 199–209. [numdam.org](http://www.numdam.org/item/CM_1977__34_2_199_0/). The proof for every smooth cubic fourfold by normal functions, and an appendix of complex tori on which the Kähler version fails, cited in Deligne's statement.
- Huybrechts, Daniel. *The Geometry of Cubic Hypersurfaces*. Cambridge University Press, 2023. [DOI 10.1017/9781009280020](https://doi.org/10.1017/9781009280020). Cubic fourfolds: their Hodge numbers, the lattice of signature (21, 2), planes and their intersection numbers, and the very general case.
- Markman, Eyal. "Cycles on abelian 2n-folds of Weil type from secant sheaves on abelian n-folds." arXiv preprint, v1 2025-02-05, v2 2025-06-08. [arXiv 2502.03415](https://arxiv.org/abs/2502.03415). The claimed result behind the abelian-fourfold line of the ledger.
