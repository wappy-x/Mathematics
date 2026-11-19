# The unit theorem: how many independent invertible elements a ring of integers holds

[Syllabus](../../../SYLLABUS.md) → [Algebraic and analytic number theory](../README.md) → [Algebraic Numbers](../README.md#s06) → The unit theorem

---

## General Overview

Among the ordinary whole numbers, only 1 and −1 have whole-number reciprocals. Add $`\sqrt{2}`$ and that changes. The number $`1 + \sqrt{2}`$ times $`\sqrt{2} - 1`$ is $`2 - 1 = 1`$, so each is the other's reciprocal, and both have whole coordinates.

A number like that is a **unit**: a member of the ring whose reciprocal is also in the ring. Units divide everything, so they are the noise in any factorisation. In $`\mathbb{Z}[\sqrt{2}]`$ (all $`a + b\sqrt{2}`$ with $`a, b`$ whole) they never run out.

Yet one number makes them all. A search of every $`b`$ from 1 to 10,000 finds 11 units $`a + b\sqrt{2}`$ with $`a, b > 0`$, and they are exactly the powers $`(1 + \sqrt{2})^1`$ to $`(1 + \sqrt{2})^{11}`$. With signs and negative powers, every unit is $`\pm(1 + \sqrt{2})^m`$. One independent unit, plus a sign.

The **unit theorem**, proved by Dirichlet in 1846, says how many independent units any number field has. Count the ways the field sits inside the real line, add the mirror-image pairs of ways it sits inside the complex plane, then subtract one. For $`\mathbb{Z}[\sqrt{2}]`$: two real ways, so one unit. For the house example $`\mathbb{Z}[\sqrt{-5}]`$, where 6 factors two ways: one mirror-image pair, so none, and the only units are 1 and −1. For a cubic field with three real ways: two.

**The units of a ring of integers are a few roots of unity times all products of powers of $`r_1 + r_2 - 1`$ fundamental units, where $`r_1`$ counts the real embeddings and $`r_2`$ the pairs of complex ones.**

**What kind of fact this is:** a theorem. Why it works proves the upper bound and the structure in full, and the lower bound (the rank is never smaller) in a folded detailed proof. The code proves, by an exhaustive search, that the units it names are fundamental in four fields, and that the only units of $`\mathbb{Z}[\sqrt{-5}]`$ are 1 and −1.

### The picture: logarithms turn the units into evenly spaced points

```
log of each unit above 1 in Z[root 2].   One block = 0.2.
  1 + root 2         ████                     0.881374
  3 + 2 root 2       █████████                1.762747
  7 + 5 root 2       █████████████            2.644121
 17 + 12 root 2      ██████████████████       3.525494
 41 + 29 root 2      ██████████████████████   4.406868
```

Multiplying by $`1 + \sqrt{2}`$ adds the same step, 0.881374, to the logarithm. The units become a row of evenly spaced points, a **lattice**. The theorem is a count of that lattice's directions.

---

## The formula

Some words first, from earlier cards on this shelf.

- A **number field** $`K`$ is the rational numbers with one root $`\theta`$ added; its **degree** $`n`$ is the number of coordinates a member needs ([Algebraic integers](01-algebraic-integers-and-number-fields.md)).
- Its **ring of integers** $`O_K`$ holds its algebraic integers. For every field on this card, $`O_K = \mathbb{Z}[\theta]`$, the whole-number combinations of $`1, \theta, \dots, \theta^{n-1}`$, taking $`\theta = (1 + \sqrt{5})/2`$ for $`\mathbb{Q}(\sqrt{5})`$ ([Rings of integers](03-rings-of-integers-and-integral-bases.md)).
- An **embedding** $`\sigma_i`$ places $`K`$ inside the complex numbers by sending $`\theta`$ to one root of its polynomial. The **norm** $`N(\alpha)`$ is the product of all $`n`$ images of $`\alpha`$ ([Norm, trace and discriminant](02-norms-traces-and-discriminants.md)).
- $`r_1`$ counts the real embeddings and $`r_2`$ the pairs of complex ones, so $`n = r_1 + 2r_2`$ ([Class groups](05-class-groups-and-the-minkowski-bound.md)). A **place** is one real embedding, or one mirror-image pair of complex ones: $`r_1 + r_2`$ places in all.

New on this card: $`O_K^\times`$ is the group of units of $`O_K`$, and a **root of unity** $`\zeta`$ is a number with $`\zeta^k = 1`$ for some whole $`k \ge 1`$ (here $`\zeta`$ is a root of unity, not a zeta function).

```math
O_K^\times \cong \{\zeta \in O_K : \zeta^{w_K} = 1\} \times \mathbb{Z}^{r}, \qquad r = r_1 + r_2 - 1
```

**Read it aloud:** the units of the ring are the roots of unity in it, $`w_K`$ of them, times a free part with $`r_1 + r_2 - 1`$ independent directions.

In practice: there are **fundamental units** $`\varepsilon_1, \dots, \varepsilon_r`$, and every unit is, in exactly one way,

```math
u = \zeta\, \varepsilon_1^{m_1} \varepsilon_2^{m_2} \cdots \varepsilon_r^{m_r}, \qquad m_j \text{ whole}
```

When $`r = 1`$ the single one is written $`\varepsilon_K`$, chosen above 1 at a real embedding. For $`\mathbb{Q}(\sqrt{2})`$, $`\varepsilon_K = 1 + \sqrt{2}`$, $`w_K = 2`$ and $`\zeta = \pm 1`$.

The size of the free part is the **regulator** $`R_K`$. Give each place a weight $`c_i`$: 1 for a real embedding, 2 for a complex pair. Then

```math
R_K = \Big| \det\big[\, c_i \log|\sigma_i(\varepsilon_j)| \,\big]_{1 \le i,\, j \le r} \Big|
```

**Read it aloud:** the regulator is the size of the determinant of the weighted logs of the fundamental units, at any $`r`$ of the $`r + 1`$ places. Rank 0 gives $`R_K = 1`$. For $`\mathbb{Q}(\sqrt{2})`$ it is $`\log(1 + \sqrt{2}) = 0.881374`$.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $`K`$, $`\theta`$, $`n`$ | the number field, the root that makes it, and its degree | $`\mathbb{Q}(\sqrt{2})`$, $`\theta = \sqrt{2}`$, $`n = 2`$ | more embeddings to count |
| $`O_K`$, $`O_K^\times`$ | the ring of integers, and its units | $`\mathbb{Z}[\sqrt{2}]`$; all $`\pm(1 + \sqrt{2})^m`$ | — |
| $`\sigma_i`$, $`c_i`$ | the $`i`$-th place, and its weight 1 (real) or 2 (complex pair) | $`\sqrt{2} \mapsto \sqrt{2}`$ and $`-\sqrt{2}`$; both weight 1 | — |
| $`r_1`$, $`r_2`$ | real embeddings; pairs of complex embeddings | 2 and 0 | each real one adds a unit direction |
| $`r`$ | the rank: how many fundamental units | $`2 + 0 - 1 = 1`$ | more independent units |
| $`\zeta`$, $`w_K`$ | a root of unity; how many there are | $`\pm 1`$; 2 | — |
| $`\varepsilon_j`$, $`\varepsilon_K`$ | the fundamental units; the single one when $`r = 1`$ | $`1 + \sqrt{2}`$ | — |
| $`u`$, $`m_j`$ | a unit, and its whole exponents | $`7 + 5\sqrt{2} = (1 + \sqrt{2})^3`$ | $`u`$ grows like $`(1 + \sqrt{2})^{m}`$ |
| $`L(u)`$ | the log vector $`(c_i \log\lvert\sigma_i(u)\rvert)`$ | $`(0.881374, -0.881374)`$ for $`1 + \sqrt{2}`$ | — |
| $`R_K`$ | the regulator: the volume of one cell of units | 0.881374 | fundamental units are larger |
| $`B`$, $`B_i`$; $`s`$, $`M`$, $`a_i`$, $`\alpha_t`$, $`u_k`$ | a size bound on every image, or on the image at place $`i`$, for a search; in the Step 4 fold, the number of places $`r_1 + r_2`$, Minkowski's constant, the sizes of a box, a run of members with indices $`t`$, and a unit small at every place but $`k`$ | 5 at both places | the search box grows |
| $`N(\alpha)`$, $`d_K`$ | the norm; the field discriminant | $`N(1 + \sqrt{2}) = -1`$; $`d_K = 8`$ | — |

### When it holds

- **The whole ring of integers.** The theorem counts units of $`O_K`$. A smaller ring such as $`\mathbb{Z}[\sqrt{5}]`$ still has rank 1, but its smallest unit is the cube of the true one, and its regulator is 3 times too big.
- **Complex embeddings counted in pairs.** $`\sqrt[3]{2}`$ has one real and two complex images. Counting the complex ones singly predicts rank 2. But the two complex images are mirror images with the same size, so they add one direction, not two (Step 2), and the rank is 1.
- **A number field, of finite degree.** The proof needs finitely many embeddings. In an infinite extension the count has no meaning.
- **The count is a rank, not a list.** The theorem guarantees $`r`$ fundamental units exist. It does not hand them over, and in large fields finding them is hard work.

---

## Why it works

### Step 0: the idea, logs turn multiplying into adding

Take the absolute value of each image of a unit and then its logarithm. Multiplying two units adds their log vectors. So the units, under logs, form an additive group of points in ordinary space.

Three facts then finish the job. The points lie in a flat space of dimension $`r_1 + r_2 - 1`$. They are spread out, never piling up near a point. And they fill every direction of that flat space. Points like that form a lattice, and a lattice in $`r`$ dimensions has $`r`$ basis vectors: the fundamental units.

### Step 1: units are exactly the members of norm $`\pm 1`$

The norm multiplies, $`N(\alpha\beta) = N(\alpha)N(\beta)`$, and is a whole number on $`O_K`$ ([Norm, trace and discriminant](02-norms-traces-and-discriminants.md)). If $`u v = 1`$, then $`N(u) N(v) = 1`$ with both whole, so $`N(u) = \pm 1`$.

Conversely, if $`N(u) = \pm 1`$, the product of the other $`n - 1`$ images of $`u`$ is $`\pm 1/u`$. That product is an algebraic integer, and it lies in $`K`$, so it is in $`O_K`$. So $`1/u`$ is in the ring.

In $`\mathbb{Z}[\sqrt{2}]`$ the units are the solutions of $`a^2 - 2b^2 = \pm 1`$. [Pell's equation](../../03-Algebra/10-For%20the%20Curious/04-pell-equation-and-root-two.md) found the plus-one solutions as the powers of $`3 + 2\sqrt{2}`$. The minus-one solutions fill the gaps: $`1 + \sqrt{2}`$ has norm −1, and its square is $`3 + 2\sqrt{2}`$.

### Step 2: the log vectors lie in a flat space of dimension $`r_1 + r_2 - 1`$

Define the log vector with one coordinate per place:

```math
L(u) = \big(c_1 \log|\sigma_1(u)|, \; \dots, \; c_{r_1 + r_2} \log|\sigma_{r_1 + r_2}(u)|\big)
```

A complex pair gets one coordinate, weight 2, because the two images are mirror images with the same size. The coordinates add up to the log of the size of the norm:

```math
\sum_i c_i \log|\sigma_i(u)| = \log|N(u)| = \log 1 = 0
```

So every log vector lies in the flat space where the coordinates sum to zero. It has $`r_1 + r_2`$ coordinates and one condition, so its dimension is $`r_1 + r_2 - 1`$. Together with Step 3, which shows the log vectors are spread out, this caps the rank at $`r_1 + r_2 - 1`$.

For $`1 + \sqrt{2}`$: the images are $`1 + \sqrt{2}`$ and $`1 - \sqrt{2}`$, with logs of their sizes $`0.881374`$ and $`-0.881374`$. They sum to zero.

### Step 3: the points are spread out, and what maps to zero is the roots of unity

Fix a size $`B`$. Only finitely many members of $`O_K`$ have every image of size at most $`B`$. The reason: the coefficients of a member's polynomial are sums of products of its images, so they are whole numbers of bounded size. There are finitely many such polynomials, each with finitely many roots.

Two consequences follow.

- **The log vectors are spread out.** Any bounded region holds only finitely many of them. A subgroup of ordinary space with that property is a lattice, generated by at most as many vectors as the dimension.
- **The units with log vector zero form a finite group.** They have every image of size exactly 1. Each member of a finite group has a power equal to 1, so these units are the roots of unity. A finite group of nonzero numbers under multiplication is always cyclic (all powers of one member); its size is $`w_K`$.

So $`O_K^\times`$ is a finite group of roots of unity times a lattice of rank at most $`r_1 + r_2 - 1`$. That the group splits as a product this way is the structure theorem for finitely generated abelian groups, stated on [Smith normal form](../../17-Topology/05-Homology/03-computing-homology-by-smith-normal-form.md).

### Step 4: the rank is exactly $`r_1 + r_2 - 1`$

This is the hard half, and it uses Minkowski's lattice point theorem from [Class groups](05-class-groups-and-the-minkowski-bound.md). That theorem says a large enough symmetric box always contains a nonzero member of $`O_K`$.

The plan in words. For each place $`k`$, build a unit that is small (size below 1) at every other place. Its log vector is negative everywhere except at $`k`$. Such vectors, one per place, point in $`r_1 + r_2 - 1`$ independent directions.

<details>
<summary>Detailed proof: a unit small at every place but one, and why such units are independent</summary>

Write $`s = r_1 + r_2`$ and fix a place $`k`$. Minkowski's theorem gives a constant $`M`$ (depending on $`K`$) such that, for any sizes $`a_1, \dots, a_s > 0`$ with $`\prod_i a_i^{c_i} = M`$, some nonzero $`\alpha \in O_K`$ has $`|\sigma_i(\alpha)| \le a_i`$ for every $`i`$. Its norm then satisfies $`1 \le |N(\alpha)| \le M`$.

Start from any such $`\alpha_1`$. Choose new sizes $`a_i < |\sigma_i(\alpha_1)|`$ for every $`i \ne k`$, and make $`a_k`$ large enough that the product is still $`M`$. This gives $`\alpha_2`$. Repeat, getting $`\alpha_1, \alpha_2, \alpha_3, \dots`$, each strictly smaller than the last at every place except $`k`$.

Every $`\alpha_t`$ has $`|N(\alpha_t)| \le M`$, and only finitely many ideals of $`O_K`$ have norm at most $`M`$. So two of them, $`\alpha_{t_1}`$ and $`\alpha_{t_2}`$ with $`t_1 < t_2`$, generate the same ideal. Then $`u_k = \alpha_{t_2} / \alpha_{t_1}`$ is a unit, and for every $`i \ne k`$:

$`\displaystyle |\sigma_i(u_k)| = \frac{|\sigma_i(\alpha_{t_2})|}{|\sigma_i(\alpha_{t_1})|} < 1`$

So $`L(u_k)`$ has negative entries at every place except $`k`$, and its entries sum to zero, so its $`k`$-th entry is positive.

Stack $`L(u_1), \dots, L(u_{s-1})`$ as the rows of a table and delete the last column. Row $`k`$ (for $`k < s`$) has a positive diagonal entry equal to minus the sum of all its other entries, including the deleted one, which is strictly negative. So the diagonal entry is strictly larger than the sum of the sizes of the other kept entries. A square table with that property, strict diagonal dominance, has nonzero determinant. So $`L(u_1), \dots, L(u_{s-1})`$ are independent, and the rank is at least $`s - 1 = r_1 + r_2 - 1`$.

</details>

### Step 5: the regulator is the volume of one cell

The fundamental units' log vectors span one cell of the lattice. Its volume, measured in any $`r`$ of the $`r + 1`$ coordinates, is $`R_K`$. Which coordinate is dropped does not matter: every row of the log table sums to zero, so deleting one column or another changes the determinant only by a sign.

The code checks this on the cubic field of $`x^3 + x^2 - 2x - 1`$, whose root is $`2\cos(2\pi/7) = 1.246980`$. With $`\theta`$ that root, $`\theta`$ and $`\theta + 1`$ are fundamental units. Dropping place 3, place 2 or place 1 gives 0.525455 every time.

[The class number formula](06-class-number-formula-and-the-dedekind-zeta-function.md) finds $`R_K = 0.48121`$ for $`\mathbb{Q}(\sqrt{5})`$ from an analytic limit; the search here gives 0.481212.

### Step 6: how to find a fundamental unit, and prove it is one

**For rank 1,** $`\varepsilon_K`$ is the smallest unit above 1, since any unit above 1 at that real place is $`\varepsilon_K^m`$ with $`m \ge 1`$. Searching $`\mathbb{Z}[\sqrt{2}]`$ over all members with both images of size at most 5 gives 2.414214, which is $`1 + \sqrt{2}`$.

**In general,** if candidate units $`\varepsilon_1, \dots, \varepsilon_r`$ miss part of the unit lattice, some missing unit has its log vector inside the cell they span. Its images are then bounded by sizes $`B_i`$ read off from the candidates' logs. So:

1. List every member of $`O_K`$ with every image within its bound $`B_i`$. Step 3 says this list is finite.
2. Keep the ones of norm $`\pm 1`$.
3. Check that each is a root of unity times whole powers of the candidates.

If no unit fails, nothing is missing: the candidates are fundamental.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| a unit in $`\mathbb{Z}[\sqrt{2}]`$ | $`(1 + \sqrt{2})(\sqrt{2} - 1) = 2 - 1`$ | 1 |
| its norm | $`1^2 - 2 \times 1^2`$ | −1 |
| its square | $`1 + 2\sqrt{2} + 2`$ | $`3 + 2\sqrt{2}`$, norm +1 |
| its cube | $`(3 + 2\sqrt{2})(1 + \sqrt{2}) = 3 + 4 + 5\sqrt{2}`$ | $`7 + 5\sqrt{2}`$, norm $`49 - 50 = -1`$ |
| places of $`\mathbb{Q}(\sqrt{2})`$ | $`\sqrt{2} \mapsto \sqrt{2}`$ and $`-\sqrt{2}`$, both real | $`r_1 = 2,\ r_2 = 0`$ |
| rank | $`2 + 0 - 1`$ | **1** |
| regulator | $`\log(1 + \sqrt{2})`$ | 0.881374 |
| a cubic: $`\theta = \sqrt[3]{2}`$, places | one real image, one complex pair | $`r_1 = 1,\ r_2 = 1`$, rank **1** |
| norm of $`1 + \theta + \theta^2`$ | $`a^3 + 2b^3 + 4c^3 - 6abc = 1 + 2 + 4 - 6`$ | 1, a unit |
| its inverse | $`(1 + \theta + \theta^2)(\theta - 1) = \theta^3 - 1 = 2 - 1`$ | 1, so the inverse is $`\theta - 1`$ |
| its real image | $`1 + \sqrt[3]{2} + \sqrt[3]{4}`$ | 3.847322 |
| its regulator | $`\log 3.847322`$ | 1.347377 |
| a totally real cubic, $`x^3 + x^2 - 2x - 1`$ | three real roots | $`r_1 = 3`$, rank **2**, $`R_K = 0.525455`$ |

**Every unit of $`\mathbb{Z}[\sqrt{2}]`$ is $`\pm(1 + \sqrt{2})^m`$ for a whole $`m`$, and $`\mathbb{Z}[\sqrt[3]{2}]`$ has one fundamental unit too, $`1 + \sqrt[3]{2} + \sqrt[3]{4}`$.** Both fields have rank 1 for different reasons: two real places in one, one real place and one complex pair in the other.

The complex images of the cubic unit have squared size 0.259921, which is $`\sqrt[3]{2} - 1`$, so the three images multiply to 1, as the norm says.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| $`\mathbb{Z}[\sqrt{5}]`$ used as the ring of $`\mathbb{Q}(\sqrt{5})`$ | smallest unit $`2 + \sqrt{5} = 4.236068`$, regulator 1.443635, not 0.481212 | $`(1 + \sqrt{5})/2`$ is an integer too; $`2 + \sqrt{5}`$ is its cube, ratio 3 |
| Pell's $`3 + 2\sqrt{2}`$ taken as fundamental | regulator 1.762747; $`1 + \sqrt{2}`$ would be its power 0.5 | the norm −1 unit is the true generator |
| Complex embeddings of $`\sqrt[3]{2}`$ counted singly, $`r_2 = 2`$ | rank 2 predicted; the true rank is 1 | the logs of $`1 + \theta + \theta^2`$ at the three embeddings are 1.347377, −0.673689, −0.673689: a complex pair always has one size, so it adds one direction (Step 2) |
| Rank 0 read as "units are ±1" in $`\mathbb{Q}(i)`$ | 4 units: $`\pm 1, \pm i`$ | rank 0 leaves the roots of unity, and $`w_K`$ varies |

The code prints every row.

---

## Code, from first principles, and it actually runs

The code takes three independent roads, with exact whole-number products, norms and inverses. Road 1 counts the places twice: from roots found numerically (the Durand–Kerner method, which finds all roots of a polynomial at once) and from the sign of the exact discriminant, which is $`(-1)^{r_2}`$. Road 2 is Step 6's box search: it lists every unit in the box, checks each against the claimed units, confirms that its weighted logs add to zero as Step 2 says, and measures the rank of what it found. Road 3 recomputes every regulator from $`\sqrt{2}`$, $`2^{1/3}`$ and $`\cos(2\pi/7)`$. For the example, a search of $`a^2 - 2b^2 = \pm 1`$ up to $`b = 10{,}000`$ is matched against the powers of $`1 + \sqrt{2}`$.

### Python

```python
# Dirichlet's unit theorem -- the check behind the card.  Standard library only.
# Members of Z[theta] are whole coordinate lists, multiplied exactly.  Road 1
# counts places by numerical roots and by the sign of the exact discriminant.
# Road 2 searches a box for every unit and proves the claimed units fundamental.
# Road 3 redoes each regulator from closed forms (square root, cube root, cosine).
from itertools import product
from math import log, exp, isqrt, prod, sqrt, cos, pi

def mul(x, y, p):                     # product in Z[theta], theta^n = -sum p[k] theta^k
    n, r = len(p), [0] * (2 * len(p) - 1)
    for i, a in enumerate(x):
        for j, b in enumerate(y):
            r[i + j] += a * b
    for d in range(2 * n - 2, n - 1, -1):
        c, r[d] = r[d], 0
        for k in range(n):
            r[d - n + k] -= c * p[k]
    return r[:n]
def det(M):                           # Laplace expansion: whole numbers or floats
    return M[0][0] if len(M) == 1 else sum((-1) ** j * M[0][j] * det([r[:j] + r[j + 1:] for r in M[1:]]) for j in range(len(M)))
def e(n, k): return [int(i == k) for i in range(n)]
def matrix(x, p):                     # "multiply by x": column j holds x theta^j
    return [list(r) for r in zip(*[mul(x, power(e(len(p), 1), j, p), p) for j in range(len(p))])]
def norm(x, p): return det(matrix(x, p))
def gram(p): return [[sum(matrix(mul(e(len(p), i), e(len(p), j), p), p)[k][k] for k in range(len(p)))
                      for j in range(len(p))] for i in range(len(p))]
def inverse(u, p):                    # Cramer's rule; a unit's determinant is +1 or -1
    M = matrix(u, p)
    return [det([r[:k] + [int(i == 0)] + r[k + 1:] for i, r in enumerate(M)]) // det(M) for k in range(len(p))]
def power(x, m, p):
    y, b = e(len(p), 0), (x if m >= 0 else inverse(x, p))
    for _ in range(abs(m)):
        y = mul(y, b, p)
    return y
def places(p):                        # Durand-Kerner roots; one place per real root or complex pair
    n, f = len(p), lambda x: x ** len(p) + sum(c * x ** k for k, c in enumerate(p))
    z = [(0.4 + 0.9j) ** k for k in range(n)]
    for _ in range(500):
        z = [z[i] - f(z[i]) / prod(z[i] - z[j] for j in range(n) if j != i) for i in range(n)]
    real = sorted((w.real for w in z if abs(w.imag) < 1e-9), reverse=True)
    return [(complex(t), 1) for t in real] + [(w, 2) for w in sorted((w for w in z if w.imag >= 1e-9), key=lambda w: w.real)]
def sig(x, z): return sum(c * z ** k for k, c in enumerate(x))
def logs(x, P): return [w * log(abs(sig(x, z))) for z, w in P]
def search(p, P, B):                  # every unit with |sigma_i(x)| <= B_i at each place
    n, G = len(p), gram(p)
    adj = [[(-1) ** (i + j) * det([r[:i] + r[i + 1:] for k, r in enumerate(G) if k != j])
            for j in range(n)] for i in range(n)]
    T = [sum(w * b * abs(z) ** j for (z, w), b in zip(P, B)) for j in range(n)]
    H = [int(sum(abs(adj[k][j]) * T[j] for j in range(n)) / abs(det(G))) + 1 for k in range(n)]
    return [list(x) for x in product(*[range(-h, h + 1) for h in H]) if any(x)
            and all(abs(sig(x, z)) <= b * (1 + 1e-9) for (z, w), b in zip(P, B)) and abs(norm(list(x), p)) == 1]
def rank(vs):                         # Gram-Schmidt rank of the log vectors
    bs = []
    for v in vs:
        for b in bs:
            c = sum(s * t for s, t in zip(v, b)); v = [s - c * t for s, t in zip(v, b)]
        if sqrt(sum(s * s for s in v)) > 1e-6:
            bs.append([s / sqrt(sum(t * t for t in v)) for s in v])
    return len(bs)
def study(p, eps):
    n, P = len(p), places(p)
    r1 = sum(1 for z, w in P if w == 1); r2 = len(P) - r1; r = r1 + r2 - 1; D = det(gram(p))
    assert (D > 0) == (r2 % 2 == 0)   # sign of d_K is (-1)^r2: places counted two ways
    assert len(eps) == r and all(abs(norm(u, p)) == 1 for u in eps)
    L = [logs(u, P) for u in eps]
    S = [[L[j][i] for j in range(r)] for i in range(r)]
    B = [exp(sum(abs(l[i]) for l in L) / P[i][1]) for i in range(len(P))]
    units = search(p, P, B)
    w = sum(1 for u in units if max(abs(t) for t in logs(u, P)) < 1e-9)
    for u in units:                   # each unit found = root of unity times powers of eps
        l = logs(u, P); assert abs(sum(l)) < 1e-9   # Step 2: the weighted logs add to log|N(u)| = 0
        k = [det([[l[i] if c == j else S[i][c] for c in range(r)] for i in range(r)]) / det(S) for j in range(r)]
        assert all(abs(t - round(t)) < 1e-6 for t in k)
        for v, t in zip(eps, k):
            u = mul(u, power(v, -round(t), p), p)
        assert power(u, w, p) == e(n, 0)
    return dict(P=P, r1=r1, r2=r2, r=r, D=D, R=abs(det(S)) if r else 1.0, w=w, N=len(units),
                found=rank([logs(u, P) for u in units]), units=units)
def smallest(p, B):                   # smallest unit above 1 at the first real place
    P = places(p)
    return min((sig(u, P[0][0]).real, u) for u in search(p, P, B) if sig(u, P[0][0]).real > 1 + 1e-9)
def f6(x): return f"{x:.6f}"

c2, c4 = 2 * cos(2 * pi / 7), 2 * cos(4 * pi / 7)
FIELDS = [("Q(root 2)", [-2, 0], [[1, 1]], log(1 + sqrt(2))),
          ("Q(root -5)", [5, 0], [], 1.0),
          ("Q(cbrt 2)", [-2, 0, 0], [[1, 1, 1]], log(1 + exp(log(2) / 3) + exp(2 * log(2) / 3))),
          ("x^3+x^2-2x-1", [-1, -2, 1], [[0, 1, 0], [1, 1, 0]],
           abs(log(c2) * log(abs(1 + c4)) - log(abs(c4)) * log(1 + c2))),
          ("Q(root 5)", [-1, -1], [[0, 1]], log((1 + sqrt(5)) / 2))]
info = {}
print("field            d_K  r1 r2  rank r1+r2-1  rank found  w  units in box  regulator")
for name, p, eps, Rclosed in FIELDS:
    s = info[name] = study(p, eps)
    assert s["found"] == s["r"] and abs(s["R"] - Rclosed) < 1e-9
    print(f"{name:15} {s['D']:>5} {s['r1']:>3} {s['r2']:>2} {s['r']:>8} {s['found']:>11} {s['w']:>4}"
          f" {s['N']:>9}      {f6(s['R'])}")

LIMIT, p2 = 10000, [-2, 0]            # the example: units a + b root 2 with a, b > 0
found = [(isqrt(2 * b * b + s), b, s) for b in range(1, LIMIT + 1) for s in (-1, 1)
         if isqrt(2 * b * b + s) ** 2 == 2 * b * b + s]
pows = [tuple(power([1, 1], m, p2)) + (norm(power([1, 1], m, p2), p2),) for m in range(1, 12)]
z2 = smallest(p2, [5, 5])
assert found == pows and power([1, 1], 12, p2)[1] > LIMIT and z2[1] == [1, 1]
print(f"search b = 1..{LIMIT}: {len(found)} units with a, b > 0; powers m = 1..{len(pows)} of 1 + root 2 match")
print("first five: " + ", ".join(f"{a} + {b} root 2 (norm {s:+d})" for a, b, s in found[:5]))
print(f"(1 + root 2)(root 2 - 1) = {mul([1, 1], [-1, 1], p2)}; (1 + root 2)^2 = {power([1, 1], 2, p2)}; "
      f"smallest unit above 1 by search = {f6(z2[0])}; L(1 + root 2) = {', '.join(map(f6, logs([1, 1], places(p2))))}")
P2 = places(p2)
for m in range(1, 6):
    a, b = power([1, 1], m, p2); l = logs([a, b], P2)[0]
    print(f"bar {m}: log({a} + {b} root 2) = {f6(l)}  " + "#" * round(l * 5))
p3, P3, s3 = [-2, 0, 0], places([-2, 0, 0]), smallest([-2, 0, 0], [4, 1])   # theta^3 = 2
assert s3[1] == [1, 1, 1] and mul([1, 1, 1], [-1, 1, 0], p3) == [1, 0, 0]
print(f"cubic: N(1 + t + t^2) = {norm([1, 1, 1], p3)}, 1 + 2 + 4 - 6 = {1 + 2 + 4 - 6}; "
      f"(1 + t + t^2)(t - 1) = {mul([1, 1, 1], [-1, 1, 0], p3)}; N(t - 1) = {norm([-1, 1, 0], p3)}")
print(f"cubic: real value {f6(sig([1, 1, 1], P3[0][0]).real)}, |complex value|^2 "
      f"{f6(abs(sig([1, 1, 1], P3[1][0])) ** 2)}, cbrt 2 - 1 = {f6(exp(log(2) / 3) - 1)}; "
      f"smallest unit above 1 by search {s3[1]} = {f6(s3[0])}")
P7 = info["x^3+x^2-2x-1"]["P"]; L7 = [logs(u, P7) for u in ([0, 1, 0], [1, 1, 0])]
print("x^3+x^2-2x-1: roots " + ", ".join(f6(z.real) for z, w in P7) + "; logs of t: " +
      ", ".join(map(f6, L7[0])) + "; logs of t + 1: " + ", ".join(map(f6, L7[1])))
print("regulator dropping place 3, 2, 1: " + ", ".join(
    f6(abs(L7[0][i] * L7[1][j] - L7[0][j] * L7[1][i])) for i, j in ((0, 1), (0, 2), (1, 2))))

z5, R5 = smallest([-5, 0], [5, 5]), info["Q(root 5)"]["R"]   # what breaks
assert z5[1] == [2, 1] and power([0, 1], 3, [-1, -1]) == [1, 2]
print(f"mistake 1, Z[root 5] for the ring: smallest unit {z5[1][0]} + {z5[1][1]} root 5 = {f6(z5[0])} = phi^3, "
      f"regulator {f6(log(z5[0]))}, not {f6(R5)}; ratio {f6(log(z5[0]) / R5)}")
k = logs([1, 1], P2)[0] / logs([3, 2], P2)[0]; assert abs(k - 0.5) < 1e-12
print(f"mistake 2, Pell's 3 + 2 root 2 as fundamental: regulator {f6(logs([3, 2], P2)[0])}; "
      f"1 + root 2 would be its power {f6(k)}, not whole")
s3i, l3 = info["Q(cbrt 2)"], [log(abs(sig([1, 1, 1], z))) for z in (P3[0][0], P3[1][0], P3[1][0].conjugate())]
print(f"mistake 3, Q(cbrt 2) with r2 = 2, counting complex embeddings singly: rank {s3i['r1'] + 2 - 1} predicted; logs of "
      f"1 + t + t^2 at the real and both complex embeddings {', '.join(map(f6, l3))}: the pair matches, one direction, not two")
gi = study([1, 0], []); assert gi["w"] == 4
print(f"mistake 4, units of Q(i) taken as +1, -1 only: the box holds {gi['N']}: {gi['units']}")
print("ALL CHECKS PASS")
```

**Ran 2026-11-15 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
field            d_K  r1 r2  rank r1+r2-1  rank found  w  units in box  regulator
Q(root 2)           8   2  0        1           1    2         6      0.881374
Q(root -5)        -20   0  1        0           0    2         2      1.000000
Q(cbrt 2)        -108   1  1        1           1    2         6      1.347377
x^3+x^2-2x-1       49   3  0        2           2    2        24      0.525455
Q(root 5)           5   2  0        1           1    2         6      0.481212
search b = 1..10000: 11 units with a, b > 0; powers m = 1..11 of 1 + root 2 match
first five: 1 + 1 root 2 (norm -1), 3 + 2 root 2 (norm +1), 7 + 5 root 2 (norm -1), 17 + 12 root 2 (norm +1), 41 + 29 root 2 (norm -1)
(1 + root 2)(root 2 - 1) = [1, 0]; (1 + root 2)^2 = [3, 2]; smallest unit above 1 by search = 2.414214; L(1 + root 2) = 0.881374, -0.881374
bar 1: log(1 + 1 root 2) = 0.881374  ####
bar 2: log(3 + 2 root 2) = 1.762747  #########
bar 3: log(7 + 5 root 2) = 2.644121  #############
bar 4: log(17 + 12 root 2) = 3.525494  ##################
bar 5: log(41 + 29 root 2) = 4.406868  ######################
cubic: N(1 + t + t^2) = 1, 1 + 2 + 4 - 6 = 1; (1 + t + t^2)(t - 1) = [1, 0, 0]; N(t - 1) = 1
cubic: real value 3.847322, |complex value|^2 0.259921, cbrt 2 - 1 = 0.259921; smallest unit above 1 by search [1, 1, 1] = 3.847322
x^3+x^2-2x-1: roots 1.246980, -0.445042, -1.801938; logs of t: 0.220724, -0.809587, 0.588863; logs of t + 1: 0.809587, -0.588863, -0.220724
regulator dropping place 3, 2, 1: 0.525455, 0.525455, 0.525455
mistake 1, Z[root 5] for the ring: smallest unit 2 + 1 root 5 = 4.236068 = phi^3, regulator 1.443635, not 0.481212; ratio 3.000000
mistake 2, Pell's 3 + 2 root 2 as fundamental: regulator 1.762747; 1 + root 2 would be its power 0.500000, not whole
mistake 3, Q(cbrt 2) with r2 = 2, counting complex embeddings singly: rank 2 predicted; logs of 1 + t + t^2 at the real and both complex embeddings 1.347377, -0.673689, -0.673689: the pair matches, one direction, not two
mistake 4, units of Q(i) taken as +1, -1 only: the box holds 4: [[-1, 0], [0, -1], [0, 1], [1, 0]]
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Dirichlet's unit theorem -- the same check as the Python, in Rust.  No crates.
// Members of Z[theta] are whole coordinate lists, multiplied exactly (i128).
// Road 1 counts places by numerical roots and by the sign of the exact
// discriminant.  Road 2 searches a box for every unit and proves the claimed
// units fundamental.  Road 3 redoes each regulator from closed forms.
use std::f64::consts::PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl C {
    fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } }
    fn sub(self, o: C) -> C { C { re: self.re - o.re, im: self.im - o.im } }
    fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } }
    fn div(self, o: C) -> C { let d = o.re * o.re + o.im * o.im;
        C { re: (self.re * o.re + self.im * o.im) / d, im: (self.im * o.re - self.re * o.im) / d } }
    fn abs(self) -> f64 { self.re.hypot(self.im) }
    fn pw(self, k: usize) -> C { (0..k).fold(C { re: 1.0, im: 0.0 }, |a, _| a.mul(self)) }
}
type V = Vec<i128>; type Places = Vec<(C, f64)>;
fn mul(x: &V, y: &V, p: &V) -> V {
    let n = p.len(); let mut r = vec![0i128; 2 * n - 1];
    for (i, a) in x.iter().enumerate() { for (j, b) in y.iter().enumerate() { r[i + j] += a * b; } }
    for d in (n..2 * n - 1).rev() { let c = r[d]; r[d] = 0; for k in 0..n { r[d - n + k] -= c * p[k]; } }
    r.truncate(n); r
}
fn minor<T: Copy>(m: &Vec<Vec<T>>, row: usize, col: usize) -> Vec<Vec<T>> {
    m.iter().enumerate().filter(|(i, _)| *i != row)
        .map(|(_, r)| r.iter().enumerate().filter(|(j, _)| *j != col).map(|(_, v)| *v).collect()).collect()
}
fn deti(m: &Vec<Vec<i128>>) -> i128 {
    if m.len() == 1 { return m[0][0]; }
    (0..m.len()).map(|j| (if j % 2 == 0 { 1 } else { -1 }) * m[0][j] * deti(&minor(m, 0, j))).sum()
}
fn detf(m: &Vec<Vec<f64>>) -> f64 {
    if m.len() == 1 { return m[0][0]; }
    (0..m.len()).map(|j| (if j % 2 == 0 { 1.0 } else { -1.0 }) * m[0][j] * detf(&minor(m, 0, j))).sum()
}
fn e(n: usize, k: usize) -> V { (0..n).map(|i| (i == k) as i128).collect() }
fn matrix(x: &V, p: &V) -> Vec<Vec<i128>> {
    let n = p.len(); let cols: Vec<V> = (0..n).map(|j| mul(x, &power(&e(n, 1), j as i64, p), p)).collect();
    (0..n).map(|i| (0..n).map(|j| cols[j][i]).collect()).collect()
}
fn norm(x: &V, p: &V) -> i128 { deti(&matrix(x, p)) }
fn gram(p: &V) -> Vec<Vec<i128>> { let n = p.len();
    (0..n).map(|i| (0..n).map(|j| { let m = matrix(&mul(&e(n, i), &e(n, j), p), p); (0..n).map(|k| m[k][k]).sum() }).collect()).collect() }
fn inverse(u: &V, p: &V) -> V {
    let m = matrix(u, p); let d = deti(&m);
    (0..p.len()).map(|k| { let mk: Vec<Vec<i128>> = m.iter().enumerate()
        .map(|(i, r)| { let mut r = r.clone(); r[k] = (i == 0) as i128; r }).collect(); deti(&mk) / d }).collect()
}
fn power(x: &V, m: i64, p: &V) -> V {
    let b = if m >= 0 { x.clone() } else { inverse(x, p) };
    (0..m.abs()).fold(e(p.len(), 0), |y, _| mul(&y, &b, p))
}
fn places(p: &V) -> Places {
    let n = p.len();
    let f = |x: C| (0..n).fold(x.pw(n), |a, k| a.add(x.pw(k).mul(C { re: p[k] as f64, im: 0.0 })));
    let mut z: Vec<C> = (0..n).map(|k| C { re: 0.4, im: 0.9 }.pw(k)).collect();
    for _ in 0..500 {
        z = (0..n).map(|i| { let den = (0..n).filter(|&j| j != i).fold(C { re: 1.0, im: 0.0 }, |a, j| a.mul(z[i].sub(z[j])));
            z[i].sub(f(z[i]).div(den)) }).collect();
    }
    let mut real: Vec<f64> = z.iter().filter(|w| w.im.abs() < 1e-9).map(|w| w.re).collect();
    real.sort_by(|a, b| b.partial_cmp(a).unwrap());
    let mut cp: Vec<C> = z.iter().filter(|w| w.im >= 1e-9).cloned().collect();
    cp.sort_by(|a, b| a.re.partial_cmp(&b.re).unwrap());
    real.iter().map(|&t| (C { re: t, im: 0.0 }, 1.0)).chain(cp.iter().map(|&w| (w, 2.0))).collect()
}
fn sig(x: &V, z: C) -> C { x.iter().enumerate().fold(C { re: 0.0, im: 0.0 }, |a, (k, &c)| a.add(z.pw(k).mul(C { re: c as f64, im: 0.0 }))) }
fn logs(x: &V, pl: &Places) -> Vec<f64> { pl.iter().map(|&(z, w)| w * sig(x, z).abs().ln()).collect() }
fn search(p: &V, pl: &Places, b: &Vec<f64>) -> Vec<V> {
    let n = p.len(); let g = gram(p); let dg = deti(&g).abs() as f64;
    let adj: Vec<Vec<i128>> = (0..n).map(|i| (0..n).map(|j| (if (i + j) % 2 == 0 { 1 } else { -1 }) * deti(&minor(&g, j, i))).collect()).collect();
    let t: Vec<f64> = (0..n).map(|j| pl.iter().zip(b).map(|(&(z, w), &bb)| w * bb * z.abs().powi(j as i32)).sum()).collect();
    let h: Vec<i128> = (0..n).map(|k| ((0..n).map(|j| adj[k][j].abs() as f64 * t[j]).sum::<f64>() / dg) as i128 + 1).collect();
    let (mut out, mut x): (Vec<V>, V) = (vec![], h.iter().map(|v| -v).collect());
    loop {
        if x.iter().any(|&c| c != 0) && pl.iter().zip(b).all(|(&(z, _), &bb)| sig(&x, z).abs() <= bb * (1.0 + 1e-9))
            && norm(&x, p).abs() == 1 { out.push(x.clone()); }
        let mut i = n;
        loop { if i == 0 { return out; } i -= 1; if x[i] < h[i] { x[i] += 1; break; } x[i] = -h[i]; }
    }
}
fn rank(vs: &Vec<Vec<f64>>) -> usize {
    let mut bs: Vec<Vec<f64>> = vec![];
    for v0 in vs { let mut v = v0.clone();
        for b in &bs { let c: f64 = v.iter().zip(b).map(|(s, t)| s * t).sum(); v = v.iter().zip(b).map(|(s, t)| s - c * t).collect(); }
        let nv = v.iter().map(|s| s * s).sum::<f64>().sqrt(); if nv > 1e-6 { bs.push(v.iter().map(|s| s / nv).collect()); } }
    bs.len()
}
struct S { pl: Places, r1: usize, r2: usize, r: usize, d: i128, reg: f64, w: usize, n: usize, found: usize, units: Vec<V> }
fn study(p: &V, eps: &Vec<V>) -> S {
    let (n, pl) = (p.len(), places(p));
    let r1 = pl.iter().filter(|q| q.1 == 1.0).count(); let r2 = pl.len() - r1; let r = r1 + r2 - 1; let d = deti(&gram(p));
    assert_eq!(d > 0, r2 % 2 == 0);
    assert!(eps.len() == r && eps.iter().all(|u| norm(u, p).abs() == 1));
    let l: Vec<Vec<f64>> = eps.iter().map(|u| logs(u, &pl)).collect();
    let s: Vec<Vec<f64>> = (0..r).map(|i| (0..r).map(|j| l[j][i]).collect()).collect();
    let b: Vec<f64> = (0..pl.len()).map(|i| (l.iter().map(|li| li[i].abs()).sum::<f64>() / pl[i].1).exp()).collect();
    let units = search(p, &pl, &b);
    let w = units.iter().filter(|u| logs(u, &pl).iter().all(|t| t.abs() < 1e-9)).count();
    for u0 in &units {
        let lu = logs(u0, &pl); let mut u = u0.clone(); assert!(lu.iter().sum::<f64>().abs() < 1e-9); // Step 2: weighted logs add to 0
        for j in 0..r {
            let sj: Vec<Vec<f64>> = (0..r).map(|i| (0..r).map(|c| if c == j { lu[i] } else { s[i][c] }).collect()).collect();
            let k = detf(&sj) / detf(&s);
            assert!((k - k.round()).abs() < 1e-6);
            u = mul(&u, &power(&eps[j], -(k.round() as i64), p), p);
        }
        assert_eq!(power(&u, w as i64, p), e(n, 0));
    }
    let lv: Vec<Vec<f64>> = units.iter().map(|u| logs(u, &pl)).collect();
    S { r1, r2, r, d, reg: if r > 0 { detf(&s).abs() } else { 1.0 }, w, n: units.len(), found: rank(&lv), units, pl }
}
fn smallest(p: &V, b: Vec<f64>) -> (f64, V) {
    let pl = places(p); let mut best = (f64::MAX, vec![]);
    for u in search(p, &pl, &b) { let v = sig(&u, pl[0].0).re; if v > 1.0 + 1e-9 && v < best.0 { best = (v, u); } }
    best
}
fn f6(x: f64) -> String { format!("{:.6}", x) }
fn j6(v: &Vec<f64>) -> String { v.iter().map(|&x| f6(x)).collect::<Vec<_>>().join(", ") }
fn main() {
    let (c2, c4) = (2.0 * (2.0 * PI / 7.0).cos(), 2.0 * (4.0 * PI / 7.0).cos());
    let fields: Vec<(&str, V, Vec<V>, f64)> = vec![
        ("Q(root 2)", vec![-2, 0], vec![vec![1, 1]], (1.0 + 2f64.sqrt()).ln()),
        ("Q(root -5)", vec![5, 0], vec![], 1.0),
        ("Q(cbrt 2)", vec![-2, 0, 0], vec![vec![1, 1, 1]], (1.0 + (2f64.ln() / 3.0).exp() + (2.0 * 2f64.ln() / 3.0).exp()).ln()),
        ("x^3+x^2-2x-1", vec![-1, -2, 1], vec![vec![0, 1, 0], vec![1, 1, 0]],
         (c2.ln() * (1.0 + c4).abs().ln() - c4.abs().ln() * (1.0 + c2).ln()).abs()),
        ("Q(root 5)", vec![-1, -1], vec![vec![0, 1]], ((1.0 + 5f64.sqrt()) / 2.0).ln())];
    let mut info: Vec<S> = vec![];
    println!("field            d_K  r1 r2  rank r1+r2-1  rank found  w  units in box  regulator");
    for (name, p, eps, rc) in &fields {
        let s = study(p, eps);
        assert!(s.found == s.r && (s.reg - rc).abs() < 1e-9);
        println!("{:15} {:>5} {:>3} {:>2} {:>8} {:>11} {:>4} {:>9}      {}", name, s.d, s.r1, s.r2, s.r, s.found, s.w, s.n, f6(s.reg));
        info.push(s); }
    let (limit, p2) = (10000i128, vec![-2i128, 0]);
    let isq = |n: i128| { let mut k = n; while k * k > n { k = (k + n / k) / 2; } k };
    let mut found: Vec<(i128, i128, i128)> = vec![];
    for b in 1..=limit { for s in [-1i128, 1] { let a = isq(2 * b * b + s); if a * a == 2 * b * b + s { found.push((a, b, s)); } } }
    let pows: Vec<(i128, i128, i128)> = (1..12).map(|m| { let q = power(&vec![1, 1], m, &p2); (q[0], q[1], norm(&q, &p2)) }).collect();
    let z2 = smallest(&p2, vec![5.0, 5.0]);
    assert!(found == pows && power(&vec![1, 1], 12, &p2)[1] > limit && z2.1 == vec![1, 1]);
    println!("search b = 1..{}: {} units with a, b > 0; powers m = 1..{} of 1 + root 2 match", limit, found.len(), pows.len());
    println!("first five: {}", found[..5].iter().map(|(a, b, s)| format!("{} + {} root 2 (norm {:+})", a, b, s)).collect::<Vec<_>>().join(", "));
    println!("(1 + root 2)(root 2 - 1) = {:?}; (1 + root 2)^2 = {:?}; smallest unit above 1 by search = {}; L(1 + root 2) = {}",
             mul(&vec![1, 1], &vec![-1, 1], &p2), power(&vec![1, 1], 2, &p2), f6(z2.0), j6(&logs(&vec![1, 1], &places(&p2))));
    let pl2 = places(&p2);
    for m in 1..6 { let q = power(&vec![1, 1], m, &p2); let l = logs(&q, &pl2)[0];
        println!("bar {}: log({} + {} root 2) = {}  {}", m, q[0], q[1], f6(l), "#".repeat((l * 5.0).round_ties_even() as usize)); }
    let (p3, one3) = (vec![-2i128, 0, 0], vec![1i128, 1, 1]); let (pl3, s3) = (places(&p3), smallest(&p3, vec![4.0, 1.0]));
    assert!(s3.1 == one3 && mul(&one3, &vec![-1, 1, 0], &p3) == vec![1, 0, 0]);
    println!("cubic: N(1 + t + t^2) = {}, 1 + 2 + 4 - 6 = {}; (1 + t + t^2)(t - 1) = {:?}; N(t - 1) = {}", norm(&one3, &p3), 1 + 2 + 4 - 6, mul(&one3, &vec![-1, 1, 0], &p3), norm(&vec![-1, 1, 0], &p3));
    println!("cubic: real value {}, |complex value|^2 {}, cbrt 2 - 1 = {}; smallest unit above 1 by search {:?} = {}",
             f6(sig(&one3, pl3[0].0).re), f6(sig(&one3, pl3[1].0).abs().powi(2)), f6((2f64.ln() / 3.0).exp() - 1.0), s3.1, f6(s3.0));
    let pl7 = &info[3].pl; let l7: Vec<Vec<f64>> = [vec![0i128, 1, 0], vec![1, 1, 0]].iter().map(|u| logs(u, pl7)).collect();
    println!("x^3+x^2-2x-1: roots {}; logs of t: {}; logs of t + 1: {}", j6(&pl7.iter().map(|q| q.0.re).collect()), j6(&l7[0]), j6(&l7[1]));
    println!("regulator dropping place 3, 2, 1: {}", j6(&[(0, 1), (0, 2), (1, 2)].iter().map(|&(i, j)| (l7[0][i] * l7[1][j] - l7[0][j] * l7[1][i]).abs()).collect()));
    let (z5, r5) = (smallest(&vec![-5, 0], vec![5.0, 5.0]), info[4].reg);
    assert!(z5.1 == vec![2, 1] && power(&vec![0, 1], 3, &vec![-1, -1]) == vec![1, 2]);
    println!("mistake 1, Z[root 5] for the ring: smallest unit {} + {} root 5 = {} = phi^3, regulator {}, not {}; ratio {}",
             z5.1[0], z5.1[1], f6(z5.0), f6(z5.0.ln()), f6(r5), f6(z5.0.ln() / r5));
    let k = logs(&vec![1, 1], &pl2)[0] / logs(&vec![3, 2], &pl2)[0]; assert!((k - 0.5).abs() < 1e-12);
    println!("mistake 2, Pell's 3 + 2 root 2 as fundamental: regulator {}; 1 + root 2 would be its power {}, not whole", f6(logs(&vec![3, 2], &pl2)[0]), f6(k));
    let l3: Vec<f64> = [pl3[0].0, pl3[1].0, C { re: pl3[1].0.re, im: -pl3[1].0.im }].iter().map(|&z| sig(&one3, z).abs().ln()).collect();
    println!("mistake 3, Q(cbrt 2) with r2 = 2, counting complex embeddings singly: rank {} predicted; logs of 1 + t + t^2 at the real and both complex embeddings {}: the pair matches, one direction, not two", info[2].r1 + 2 - 1, j6(&l3));
    let gi = study(&vec![1, 0], &vec![]); assert_eq!(gi.w, 4);
    println!("mistake 4, units of Q(i) taken as +1, -1 only: the box holds {}: {:?}", gi.n, gi.units);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-15 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
field            d_K  r1 r2  rank r1+r2-1  rank found  w  units in box  regulator
Q(root 2)           8   2  0        1           1    2         6      0.881374
Q(root -5)        -20   0  1        0           0    2         2      1.000000
Q(cbrt 2)        -108   1  1        1           1    2         6      1.347377
x^3+x^2-2x-1       49   3  0        2           2    2        24      0.525455
Q(root 5)           5   2  0        1           1    2         6      0.481212
search b = 1..10000: 11 units with a, b > 0; powers m = 1..11 of 1 + root 2 match
first five: 1 + 1 root 2 (norm -1), 3 + 2 root 2 (norm +1), 7 + 5 root 2 (norm -1), 17 + 12 root 2 (norm +1), 41 + 29 root 2 (norm -1)
(1 + root 2)(root 2 - 1) = [1, 0]; (1 + root 2)^2 = [3, 2]; smallest unit above 1 by search = 2.414214; L(1 + root 2) = 0.881374, -0.881374
bar 1: log(1 + 1 root 2) = 0.881374  ####
bar 2: log(3 + 2 root 2) = 1.762747  #########
bar 3: log(7 + 5 root 2) = 2.644121  #############
bar 4: log(17 + 12 root 2) = 3.525494  ##################
bar 5: log(41 + 29 root 2) = 4.406868  ######################
cubic: N(1 + t + t^2) = 1, 1 + 2 + 4 - 6 = 1; (1 + t + t^2)(t - 1) = [1, 0, 0]; N(t - 1) = 1
cubic: real value 3.847322, |complex value|^2 0.259921, cbrt 2 - 1 = 0.259921; smallest unit above 1 by search [1, 1, 1] = 3.847322
x^3+x^2-2x-1: roots 1.246980, -0.445042, -1.801938; logs of t: 0.220724, -0.809587, 0.588863; logs of t + 1: 0.809587, -0.588863, -0.220724
regulator dropping place 3, 2, 1: 0.525455, 0.525455, 0.525455
mistake 1, Z[root 5] for the ring: smallest unit 2 + 1 root 5 = 4.236068 = phi^3, regulator 1.443635, not 0.481212; ratio 3.000000
mistake 2, Pell's 3 + 2 root 2 as fundamental: regulator 1.762747; 1 + root 2 would be its power 0.500000, not whole
mistake 3, Q(cbrt 2) with r2 = 2, counting complex embeddings singly: rank 2 predicted; logs of 1 + t + t^2 at the real and both complex embeddings 1.347377, -0.673689, -0.673689: the pair matches, one direction, not two
mistake 4, units of Q(i) taken as +1, -1 only: the box holds 4: [[-1, 0], [0, -1], [0, 1], [1, 0]]
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves the unit theorem and Step 1 for every number field, and checks the small sums behind the worked numbers.

- Take any number field $`K`$. Then it has $`r_1 + r_2 - 1`$ fundamental units. Every unit is, in exactly one way, a root of unity times whole powers of them.
- The roots of unity in $`O_K`$ form a finite cyclic group with $`w_K`$ members. Take a unit $`u`$. Then $`u`$ is a root of unity exactly when $`u^{w_K} = 1`$.
- Take any member $`\alpha`$ of $`O_K`$. Then $`\alpha`$ is a unit exactly when $`N(\alpha) = \pm 1`$, as in Step 1.
- Take $`1 + \sqrt{2}`$ in $`\mathbb{Z}[\sqrt{2}]`$. Then its product with $`\sqrt{2} - 1`$ is 1. Its square is $`3 + 2\sqrt{2}`$ and its cube is $`7 + 5\sqrt{2}`$.
- The first five units above 1 in $`\mathbb{Z}[\sqrt{2}]`$ have norms −1, +1, −1, +1, −1.
- For $`\mathbb{Q}(\sqrt[3]{2})`$, the norm sum $`1 + 2 + 4 - 6`$ of $`1 + \theta + \theta^2`$ is 1.
- The rank sums $`r_1 + r_2 - 1`$ for the code's first four fields come out 1, 0, 1 and 2.

Counting each field's places, the box searches that prove units fundamental, and every regulator are left to the Python and Rust checks.

```lean
-- The unit theorem: every unit of a number field's ring of integers is, in exactly one way, a root of unity times whole powers of r₁ + r₂ − 1 fundamental units.
import Mathlib.NumberTheory.NumberField.Units.DirichletTheorem
import Mathlib.NumberTheory.Zsqrtd.Basic

open NumberField NumberField.InfinitePlace NumberField.Units

/-- Helper: the unit theorem for any index count `n` equal to Mathlib's `rank K`. -/
theorem unit_theorem_of_rank_eq (K : Type*) [Field K] [NumberField K] (n : ℕ)
    (hn : NumberField.Units.rank K = n) :
    ∃ ε : Fin n → (𝓞 K)ˣ,
      ∀ u : (𝓞 K)ˣ, ∃! ζm : torsion K × (Fin n → ℤ),
        u = (ζm.1 : (𝓞 K)ˣ) * ∏ j, ε j ^ ζm.2 j := by
  subst hn
  exact ⟨fundSystem K, fun u => exist_unique_eq_mul_prod K u⟩

#print axioms unit_theorem_of_rank_eq

/-- Dirichlet's unit theorem. Let K be a number field, r₁ its number of real embeddings and
r₂ its number of pairs of complex embeddings. Then there are r = r₁ + r₂ − 1 fundamental
units ε₁, …, ε_r of the ring of integers O_K such that every unit u is, in exactly one way,
a root of unity ζ in O_K times whole powers of them: u = ζ · ε₁^m₁ ⋯ ε_r^m_r. -/
theorem units_eq_root_of_unity_mul_fundamental_units (K : Type*) [Field K] [NumberField K] :
    ∃ ε : Fin (nrRealPlaces K + nrComplexPlaces K - 1) → (𝓞 K)ˣ,
      ∀ u : (𝓞 K)ˣ, ∃! ζm : torsion K × (Fin (nrRealPlaces K + nrComplexPlaces K - 1) → ℤ),
        u = (ζm.1 : (𝓞 K)ˣ) * ∏ j, ε j ^ ζm.2 j := by
  apply unit_theorem_of_rank_eq
  rw [NumberField.Units.rank, card_eq_nrRealPlaces_add_nrComplexPlaces]

/-- The roots of unity in O_K form a finite cyclic group with w_K members, and a unit is one
of them exactly when its w_K-th power is 1. -/
theorem roots_of_unity_finite_cyclic (K : Type*) [Field K] [NumberField K] :
    Finite (torsion K) ∧ IsCyclic (torsion K) ∧
      ∀ ζ : (𝓞 K)ˣ, ζ ∈ torsion K ↔ ζ ^ torsionOrder K = 1 := by
  refine ⟨inferInstance, inferInstance, fun ζ => ⟨pow_torsionOrder_eq_one K, fun h => ?_⟩⟩
  rw [torsion, CommGroup.mem_torsion]
  exact isOfFinOrder_iff_pow_eq_one.2 ⟨torsionOrder K, torsionOrder_pos K, h⟩

/-- Step 1: a member of O_K is a unit exactly when its norm is +1 or −1. -/
theorem isUnit_iff_norm_eq_pm_one (K : Type*) [Field K] [NumberField K] (x : 𝓞 K) :
    IsUnit x ↔ (RingOfIntegers.norm ℚ x : ℚ) = 1 ∨ (RingOfIntegers.norm ℚ x : ℚ) = -1 := by
  rw [NumberField.isUnit_iff_norm, abs_eq zero_le_one]

-- Z[√2]: (1 + √2)(√2 − 1) = 1, so 1 + √2 is a unit.
example : (⟨1, 1⟩ : ℤ√2) * ⟨-1, 1⟩ = 1 := by decide
-- Its square is 3 + 2√2 and its cube is 7 + 5√2.
example : (⟨1, 1⟩ : ℤ√2) ^ 2 = ⟨3, 2⟩ := by decide
example : (⟨1, 1⟩ : ℤ√2) ^ 3 = ⟨7, 5⟩ := by decide
-- Norms a² − 2b² of the first five units above 1: −1, +1, −1, +1, −1.
example : Zsqrtd.norm (⟨1, 1⟩ : ℤ√2) = -1 := by decide
example : Zsqrtd.norm (⟨3, 2⟩ : ℤ√2) = 1 := by decide
example : Zsqrtd.norm (⟨7, 5⟩ : ℤ√2) = -1 := by decide
example : Zsqrtd.norm (⟨17, 12⟩ : ℤ√2) = 1 := by decide
example : Zsqrtd.norm (⟨41, 29⟩ : ℤ√2) = -1 := by decide
-- Q(∛2): the norm a³ + 2b³ + 4c³ − 6abc of 1 + θ + θ² is 1.
example : (1 : ℤ) ^ 3 + 2 * 1 ^ 3 + 4 * 1 ^ 3 - 6 * 1 * 1 * 1 = 1 := by norm_num
-- Ranks r₁ + r₂ − 1: Q(√2) has 2 + 0 − 1 = 1, Q(√−5) has 0 + 1 − 1 = 0,
-- Q(∛2) has 1 + 1 − 1 = 1, and the totally real cubic x³ + x² − 2x − 1 has 3 + 0 − 1 = 2.
example : (2 + 0 - 1 : ℕ) = 1 ∧ (0 + 1 - 1 : ℕ) = 0 ∧ (1 + 1 - 1 : ℕ) = 1 ∧ (3 + 0 - 1 : ℕ) = 2 := by
  decide

#print axioms units_eq_root_of_unity_mul_fundamental_units
#print axioms roots_of_unity_finite_cyclic
#print axioms isUnit_iff_norm_eq_pm_one
```

**Checked 2026-11-15 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'unit_theorem_of_rank_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'units_eq_root_of_unity_mul_fundamental_units' depends on axioms: [propext, Classical.choice, Quot.sound]
'roots_of_unity_finite_cyclic' depends on axioms: [propext, Classical.choice, Quot.sound]
'isUnit_iff_norm_eq_pm_one' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it. The first three add a row at the end of the `FIELDS` list in the Python.
> - **Another real quadratic.** Add `("Q(root 3)", [-3, 0], [[2, 1]], log(2 + sqrt(3)))`. Guess first: is $`2 + \sqrt{3}`$ fundamental? The run passes, with rank 1, 6 units in the box and regulator 1.316958.
> - **A size surprise.** Add `("Q(root 7)", [-7, 0], [[8, 3]], log(8 + 3 * sqrt(7)))`. Guess the regulator first. It is 2.768659: a small $`d`$ can have a large fundamental unit, $`8 + 3\sqrt{7}`$.
> - **Another pure cubic.** Add `("Q(cbrt 3)", [-3, 0, 0], [[4, 3, 2]], log(4 + 3 * exp(log(3) / 3) + 2 * exp(2 * log(3) / 3)))`. Guess first. It passes with rank 1 and regulator 2.524681: the unit is $`4 + 3\sqrt[3]{3} + 2\sqrt[3]{9}`$, of norm $`64 + 81 + 72 - 216 = 1`$.
> - **Claim a square.** In the $`\mathbb{Q}(\sqrt[3]{2})`$ row, replace `[[1, 1, 1]]` with `[[5, 4, 3]]`, which is $`(1 + \theta + \theta^2)^2`$. Guess first. The search finds $`1 + \theta + \theta^2`$ itself, whose exponent is one half, and an assert stops the program.

---

## The usual mistake

> [!warning]
> **Taking any generator of the norm +1 units for the fundamental unit.** Pell's equation $`x^2 - 2y^2 = 1`$ is solved by the powers of $`3 + 2\sqrt{2}`$, but that is not $`\varepsilon_K`$. The unit $`1 + \sqrt{2}`$ has norm −1, and $`3 + 2\sqrt{2}`$ is its square. Using $`3 + 2\sqrt{2}`$ doubles the regulator to 1.762747 and loses every odd power, such as $`7 + 5\sqrt{2}`$.
>
> - **The wrong ring.** In $`\mathbb{Z}[\sqrt{5}]`$ the smallest unit above 1 is $`2 + \sqrt{5} = 4.236068`$. In the true ring it is $`(1 + \sqrt{5})/2`$, and the regulator is 0.481212, not 1.443635.
> - **Counting each complex embedding.** For $`\sqrt[3]{2}`$ that predicts rank 2. The two complex images always have the same size, so the true rank is 1.
> - **Forgetting the roots of unity.** $`\mathbb{Q}(i)`$ has rank 0 yet 4 units, $`\pm 1`$ and $`\pm i`$. Rank counts only the free part.

---

## Where you meet it in real life

- **Pell-type equations.** The whole solutions of $`x^2 - dy^2 = \pm 1`$ are the units of $`\mathbb{Z}[\sqrt{d}]`$. The theorem says they all come from one, and the [Pell's equation](../07-Diophantine%20and%20Modular/01-pell-and-continued-fractions-revisited.md) card finds it by continued fractions.
- **Cubic equations in whole numbers.** The norm of $`a + b\sqrt[3]{2}`$ is $`a^3 + 2b^3`$, so the solutions of $`a^3 + 2b^3 = 1`$ are the units with no $`\sqrt[3]{4}`$ term. The unit $`\sqrt[3]{2} - 1`$, of norm 1, gives $`a = -1`$, $`b = 1`$.
- **Cryptography.** A 1989 key-exchange system used real quadratic fields. Its security rested on how hard the regulator is to compute when $`d`$ is large.
- **Computer algebra.** Number theory software computes fundamental units by relation-finding methods far faster than Step 6's search, then certifies them by checks like it. Tables of number fields list each regulator.
- **The class number.** The class number formula gives only the product $`h_K R_K`$, so $`R_K`$ must be known first.

> **Say it back**
> A unit is a member of the ring whose reciprocal is also in the ring; units are exactly the members of norm $`\pm 1`$. Taking logs of the sizes of a unit's images turns multiplying into adding and puts the units on a lattice in a flat space of dimension $`r_1 + r_2 - 1`$. So every unit is a root of unity times whole powers of $`r_1 + r_2 - 1`$ fundamental units. In $`\mathbb{Z}[\sqrt{2}]`$ that is one unit, $`1 + \sqrt{2}`$; in $`\mathbb{Z}[\sqrt{-5}]`$ none; in a cubic field with three real roots, two. The regulator is the volume of one cell of that lattice.

---

## What this builds on

- [Class groups](05-class-groups-and-the-minkowski-bound.md): the counts $`r_1`$ and $`r_2`$, and Minkowski's lattice point theorem, which the lower bound in Step 4 uses.
- [Pell's equation](../../03-Algebra/10-For%20the%20Curious/04-pell-equation-and-root-two.md): shows that the units $`a + b\sqrt{2}`$ never run out and come from powers of $`3 + 2\sqrt{2}`$. This card finds the true generator, $`1 + \sqrt{2}`$, and counts units in every field.

## Where this goes next

- [Pell's equation](../07-Diophantine%20and%20Modular/01-pell-and-continued-fractions-revisited.md): finds the fundamental unit of any real quadratic field from the continued fraction of $`\sqrt{d}`$, and shows when a unit of norm −1 exists.

The theorem says how many fundamental units there are, but not how large they are: no simple rule predicts that $`\mathbb{Q}(\sqrt{7})`$ needs $`8 + 3\sqrt{7}`$ while $`\mathbb{Q}(\sqrt{2})`$ needs only $`1 + \sqrt{2}`$.

---

## Sources

Verified 2026-11-15: every link below resolves to the publisher's page.

- Neukirch, Jürgen. *Algebraic Number Theory*. Springer, 1999. [doi:10.1007/978-3-662-03983-0](https://doi.org/10.1007/978-3-662-03983-0). The unit theorem through the log map and Minkowski's theorem, and the regulator as a lattice volume (chapter I, section 7).
- Marcus, Daniel A. *Number Fields*, 2nd ed. Springer, 2018. [doi:10.1007/978-3-319-90233-3](https://doi.org/10.1007/978-3-319-90233-3). A full elementary proof of the unit theorem, with exercises on real quadratic and cubic fields.
- Cohen, Henri. *A Course in Computational Algebraic Number Theory*. Springer, 1993. [doi:10.1007/978-3-662-02945-9](https://doi.org/10.1007/978-3-662-02945-9). Computing fundamental units and regulators, with tables of cubic fields.
- Pohst, Michael, and Hans Zassenhaus. *Algorithmic Algebraic Number Theory*. Cambridge University Press, 1989. [doi:10.1017/CBO9780511661952](https://doi.org/10.1017/CBO9780511661952). Algorithms for computing unit groups, fundamental units and regulators.
- Buchmann, Johannes, and Hugh C. Williams. "A key exchange system based on real quadratic fields." In *Advances in Cryptology — CRYPTO '89*, Lecture Notes in Computer Science 435. Springer, 1990. [doi:10.1007/0-387-34805-0_31](https://doi.org/10.1007/0-387-34805-0_31). Cryptography resting on the difficulty of computing the regulator.
