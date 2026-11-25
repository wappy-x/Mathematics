# Serre duality: cohomology in degree i pairs with degree n - i, and Riemann-Roch follows

[Syllabus](../../../SYLLABUS.md) → [Algebraic geometry](../README.md) → [Sheaf Cohomology and Differentials](../README.md#s08) → Serre duality

---

## General Overview

Take the projective line $`\mathbb{P}^1`$: the ordinary line plus one point at infinity, with coordinates $`(x : y)`$. A line bundle $`\mathcal{O}(d)`$ on it is a rule that attaches a one-dimensional space to each point. Its global sections (choices made smoothly over the whole line) are the forms of degree d in x and y. So $`\mathcal{O}(1)`$ has two independent global sections, x and y. The bundle $`\mathcal{O}(-3)`$ has none.

But $`\mathcal{O}(-3)`$ has a first cohomology group $`H^1`$: a vector space that counts the ways local sections fail to glue into a global one. That space also has dimension 2.

That match is not luck. Serre duality says the cohomology of a sheaf in degree i is the dual of the cohomology of a partner sheaf in the opposite degree. On the line, the partner of $`\mathcal{O}(-3)`$ is $`\mathcal{O}(1)`$. So "2 sections of $`\mathcal{O}(1)`$" and "2 obstructions for $`\mathcal{O}(-3)`$" are one fact seen from two sides.

The payoff comes on curves. On a smooth plane quartic, a curve of degree 4 with genus 3, the canonical divisor K (the divisor of a differential) has $`\ell(K) = 3`$: three independent differentials. Riemann-Roch predicts that 3, and this card proves Riemann-Roch from Serre duality in two short steps.

**The cohomology of a sheaf in degree i is dual to the cohomology in degree n − i of its dual twisted by the canonical bundle; on a curve this turns the Euler-characteristic count deg D + 1 − g into Riemann-Roch.**

**What kind of fact this is:** a theorem. Serre duality for the line bundles $`\mathcal{O}(d)`$ on projective space is proved on this card in Why it works, and so is its numerical form (equal dimensions) for line sections of plane curves. The general statement is stated with its source (Hartshorne, III.7). Riemann-Roch for every divisor on every smooth projective curve is proved here from the general statement.

### The picture: the two columns mirror around d = −1

```
Dimensions of the cohomology of O(d) on the projective line

  d   h^0(O(d))     h^1(O(d))
 -5             0   ####  4
 -4             0   ###   3
 -3             0   ##    2
 -2             0   #     1
 -1             0         0
  0   #         1         0
  1   ##        2         0
  2   ###       3         0
  3   ####      4         0
```

Read the h^1 column upward from d = −1 and the h^0 column downward: they are the same bars. That is $`h^1(\mathcal{O}(d)) = h^0(\mathcal{O}(-2 - d))`$, Serre duality on the line with $`K = \mathcal{O}(-2)`$. The code prints both columns.

---

## The formula

Carried over, each in one line:

- **The field** k is any field for the results on projective space and for the line-section counts on plane curves. Riemann-Roch for every divisor needs k algebraically closed, such as ℂ, so that every point counts once. The code works over the rationals ℚ, and over $`\mathbb{F}_{13}`$ for a point count.
- **Sheaves and line bundles.** A coherent sheaf $`\mathcal{F}`$ is a sheaf of modules that is finitely generated on each chart ([Quasi-coherent sheaves](../06-Schemes%20and%20Modern%20Language/11-quasi-coherent-and-coherent-sheaves.md)). $`\mathcal{O}(d)`$ on $`\mathbb{P}^n`$ is the line bundle whose global sections are the forms of degree d. Curly $`\mathcal{O}`$ is a sheaf, not the point O of an elliptic curve.
- **Cohomology.** $`H^i(X, \mathcal{F})`$ is the i-th sheaf cohomology group, a k-vector space; $`h^i`$ is its dimension. $`H^0`$ is the global sections; $`H^1`$ and higher measure how local sections fail to glue ([Sheaf cohomology](05-sheaf-cohomology-as-a-derived-functor.md), computed by charts in [Cech cohomology](04-cech-cohomology-of-projective-space.md)).
- **The canonical bundle** $`K_X`$ is the line bundle of top-degree differential forms: on $`\mathbb{P}^n`$ it is $`\mathcal{O}(-n-1)`$; on a plane curve of degree d it is $`\mathcal{O}_C(d - 3)`$, by adjunction ([The canonical bundle and adjunction](02-canonical-bundle-and-adjunction.md)).
- **Divisors on a curve.** D, deg D, $`\ell(D)`$ and K come from [Divisors and Riemann-Roch](../03-Plane%20Curves/07-divisors-and-riemann-roch.md). $`\mathcal{O}_C(D)`$ is the line bundle whose sections are the functions in $`\mathcal{L}(D)`$, so $`\ell(D) = h^0(\mathcal{O}_C(D))`$.

New on this card, in words first. The **dual** $`\mathcal{F}^\vee`$ of a locally free sheaf is the sheaf of linear maps from it to $`\mathcal{O}_X`$; the dual of $`\mathcal{O}(d)`$ is $`\mathcal{O}(-d)`$. The **Euler characteristic** $`\chi(\mathcal{F})`$ is the alternating sum $`h^0 - h^1 + h^2 - \dots`$.

**Serre duality.** Let X be a smooth projective variety of dimension n over k, and $`\mathcal{F}`$ a locally free sheaf on X. For every i from 0 to n:

```math
H^i(X, \mathcal{F}) \cong H^{n-i}(X, \mathcal{F}^\vee \otimes K_X)^\vee
```

**Read it aloud:** the cohomology of F in degree i is the dual vector space of the cohomology, in the opposite degree n − i, of the dual of F twisted by the canonical bundle.

For any coherent $`\mathcal{F}`$, not only locally free ones, duality takes the form $`\mathrm{Ext}^i(\mathcal{F}, K_X) \cong H^{n-i}(X, \mathcal{F})^\vee`$ ([Ext](../07-Exact%20Sequences%2C%20Ext%20and%20Tor/05-ext-and-extensions.md)). For locally free $`\mathcal{F}`$, $`\mathrm{Ext}^i(\mathcal{F}, K_X) = H^i(X, \mathcal{F}^\vee \otimes K_X)`$, so this is the display with $`\mathcal{F}`$ and $`\mathcal{F}^\vee \otimes K_X`$ swapped.

On $`\mathbb{P}^1`$ with $`\mathcal{F} = \mathcal{O}(-3)`$, n = 1 and i = 1: $`\mathcal{F}^\vee \otimes K = \mathcal{O}(3) \otimes \mathcal{O}(-2) = \mathcal{O}(1)`$. So $`h^1(\mathcal{O}(-3)) = h^0(\mathcal{O}(1)) = 2`$.

**Riemann-Roch.** On a smooth projective curve C of genus g, for every divisor D:

```math
\chi(\mathcal{O}_C(D)) = \deg D + 1 - g, \qquad h^1(\mathcal{O}_C(D)) = \ell(K - D) \quad \Longrightarrow \quad \ell(D) - \ell(K - D) = \deg D + 1 - g
```

**Read it aloud:** sections minus obstructions equals degree plus one minus genus; duality turns the obstructions into sections of K − D; so the count of functions with poles in D, minus a correction, is degree plus one minus genus.

On the quartic with D = K: $`\ell(K) - \ell(0) = 4 + 1 - 3`$, so $`\ell(K) = 2 + 1 = 3`$.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $`X`$, $`n`$, $`\mathbb{P}^n`$ | a smooth projective variety and its dimension; projective n-space | $`\mathbb{P}^1`$, n = 1; $`\mathbb{P}^2`$, n = 2 | the degrees run 0 to n |
| $`\mathcal{F}`$, $`\mathcal{F}^\vee`$ | a locally free sheaf and its dual | $`\mathcal{O}(-3)`$ and $`\mathcal{O}(3)`$ | — |
| $`\mathcal{O}(d)`$, $`\mathcal{O}(e)`$ | line bundle with the degree-d forms as sections; e is a second twist, in Step 3 | $`\mathcal{O}(1)`$: x, y | h^0 grows, h^n shrinks |
| $`H^i`$, $`h^i`$, $`\mathrm{Ext}^i`$ | cohomology in degree i; its dimension over k; the Ext groups that replace it for any coherent sheaf | $`h^1(\mathcal{O}(-3)) = 2`$ | — |
| $`K_X`$, $`K`$ | the canonical bundle; on a curve, the canonical divisor | $`\mathcal{O}(-2)`$ on the line; $`\mathcal{O}_C(1)`$ on the quartic | moves the mirror point |
| $`x^a`$ | a Laurent monomial $`x_0^{a_0} \cdots x_n^{a_n}`$, negative powers allowed | $`x^{-1}y^{-2}`$ in $`H^1(\mathcal{O}(-3))`$ | — |
| $`C`$, $`d`$ | a smooth plane curve and its degree | $`x^4 + y^4 + z^4 = 0`$, d = 4 | genus grows like d²/2 |
| $`g`$ | the genus, $`h^1(\mathcal{O}_C)`$ | 1 for the cubic, 3 for the quartic | each unit costs one section |
| $`D`$, $`\deg D`$, $`m`$, $`P`$ | a divisor on C and its degree; D = m line sections has degree md; P is one point of C | the line section, degree 3 or 4 | one more section per degree, once large |
| $`\ell(D)`$, $`\mathcal{O}_C(D)`$ | $`h^0(\mathcal{O}_C(D))`$: independent functions with poles in D; the line bundle they are sections of | $`\ell(K) = 3`$ on the quartic | — |
| $`\chi`$ | Euler characteristic, $`h^0 - h^1`$ on a curve | $`\chi(\mathcal{O}_C(K)) = 3 - 1 = 2`$ | rises by 1 per point of D |
| $`k`$, $`k_P`$ | the field of scalars; $`k_P`$ is one copy of k sitting at the point P | ℚ; $`\mathbb{F}_{13}`$ for points | — |

### When it holds

- **X is projective (closed).** On the affine line, $`H^0(\mathcal{O})`$ is every polynomial: 11, 101, 1001 of degree at most 10, 100, 1000, with no end. One chart covers it, so $`H^1(K) = 0`$. No duality is possible.
- **X is smooth, or at least Cohen-Macaulay.** Then its dualizing sheaf (which every projective scheme has) gives duality in every degree and plays the role of K. On a singular variety without that property, the duality fails in some degrees. Plane curves are always fine: every plane curve, singular or not, has dualizing sheaf $`\mathcal{O}_C(d - 3)`$.
- **The partner is twisted by the right K.** Pair $`H^1(\mathcal{O}(-3))`$ with $`H^0`$ of the bare dual $`\mathcal{O}(3)`$ and the count is 4, not 2. Use $`\mathcal{O}(-n)`$ for K on $`\mathbb{P}^n`$ and 24 of 79 dimension checks in the code fail.
- **Riemann-Roch keeps its correction term.** Without $`\ell(K - D)`$, the quartic at D = K gives 2, not 3.

---

## Why it works

### Step 0: one top class, and multiplication into it

On a connected smooth projective variety of dimension n, the top cohomology of K is one-dimensional: $`H^n(X, K_X) \cong k`$. A trace map reads off that one number, the way a residue reads one coefficient of a Laurent series.

A section of $`\mathcal{F}`$ times a section of $`\mathcal{F}^\vee \otimes K`$ is a section of K. Cohomology classes multiply the same way, and degrees add: i plus n − i is n. So every class in $`H^i(\mathcal{F})`$ gives a linear function on $`H^{n-i}(\mathcal{F}^\vee \otimes K)`$. Serre duality says this pairing is perfect: it loses nothing in either direction, so each side is the dual of the other.

### Step 1: the cohomology of O(d), carried over

Cover $`\mathbb{P}^n`$ by the n + 1 charts where one coordinate is not 0. [Cech cohomology](04-cech-cohomology-of-projective-space.md) proves, one Laurent monomial $`x^a = x_0^{a_0} \cdots x_n^{a_n}`$ at a time, that only two kinds of monomial survive:

- $`H^0(\mathcal{O}(d))`$ is spanned by the monomials of degree d with every exponent at least 0: $`h^0 = \binom{d+n}{n}`$ for d ≥ 0.
- $`H^n(\mathcal{O}(d))`$ is spanned by those with every exponent at most −1: $`h^n = \binom{-d-1}{n}`$ for d ≤ −n − 1.
- Every degree strictly between 0 and n is 0.

The code does not assume this. It rebuilds the small Cech complex of each monomial and takes exact ranks, then compares with the binomials.

### Step 2: the pairing on projective space is perfect

Multiply $`x^a`$ in $`H^0(\mathcal{O}(d))`$ by $`x^b`$ in $`H^n(\mathcal{O}(-d-n-1))`$. The product has degree −n − 1, and $`H^n(\mathcal{O}(-n-1))`$ is spanned by one monomial, $`1/(x_0 x_1 \cdots x_n)`$. So the product is nonzero exactly when $`b = -1 - a`$ in every coordinate.

That rule is a one-to-one match. If every entry of a is at least 0, every entry of $`-1 - a`$ is at most −1, and back. The pairing matrix is a permutation matrix, so it is perfect: $`H^0(\mathcal{O}(d)) \cong H^n(\mathcal{O}(-d-n-1))^\vee`$, with $`K = \mathcal{O}(-n-1)`$.

On $`\mathbb{P}^1`$ with d = 1:

| $`H^0(\mathcal{O}(1))`$ | its partner in $`H^1(\mathcal{O}(-3))`$ | product |
| --- | --- | --- |
| y | $`x^{-1}y^{-2}`$ | $`x^{-1}y^{-1}`$ |
| x | $`x^{-2}y^{-1}`$ | $`x^{-1}y^{-1}`$ |

The middle degrees are 0 on both sides, so duality holds for every i. The code checks all 88 cases (n, d, i) and the pairing matrix at 12 values (n, d), up to 21 × 21.

<details>
<summary>The general theorem: from projective space to any smooth projective X</summary>

For any coherent sheaf $`\mathcal{F}`$ on $`\mathbb{P}^n`$, write it as a quotient of a sum of line bundles $`\mathcal{O}(q)`$. Both $`\mathrm{Ext}^i(\cdot, K)`$ and $`H^{n-i}(\cdot)^\vee`$ turn that presentation into exact sequences. They agree on every sum of $`\mathcal{O}(q)`$ by Step 2. A standard argument on the sequences then makes them agree on $`\mathcal{F}`$ (Hartshorne, Theorem III.7.1).

For a smooth projective X of dimension n inside $`\mathbb{P}^N`$, the dualizing sheaf of X is computed from that of $`\mathbb{P}^N`$ by Ext, and smoothness makes it the canonical bundle (Hartshorne, Corollary III.7.12). For a locally free $`\mathcal{F}`$, $`\mathrm{Ext}^i(\mathcal{F}, K_X) = H^i(\mathcal{F}^\vee \otimes K_X)`$, which gives the form in The formula.

</details>

### Step 3: duality on a plane curve, from duality on the plane

Let C be a plane curve of degree d. Multiplying by its equation gives the exact sequence $`0 \to \mathcal{O}(m - d) \to \mathcal{O}(m) \to \mathcal{O}_C(m) \to 0`$. Its long exact sequence of cohomology, with every $`H^1`$ on $`\mathbb{P}^2`$ equal to 0 (Step 1), gives two counts:

```math
h^0(\mathcal{O}_C(m)) = h^0(\mathcal{O}(m)) - h^0(\mathcal{O}(m - d)), \qquad h^1(\mathcal{O}_C(m)) = h^2(\mathcal{O}(m - d)) - h^2(\mathcal{O}(m))
```

Now apply duality on the plane, $`h^2(\mathcal{O}(e)) = h^0(\mathcal{O}(-3 - e))`$, to both terms on the right:

```math
h^1(\mathcal{O}_C(m)) = h^0(\mathcal{O}(d - 3 - m)) - h^0(\mathcal{O}(-3 - m)) = h^0(\mathcal{O}_C(d - 3 - m))
```

The last step is the first count with $`d - 3 - m`$ in place of m. Since $`K_C = \mathcal{O}_C(d - 3)`$, this is $`h^1(\mathcal{O}_C(D)) = \ell(K - D)`$ for D = m times a line section. The code checks it for d = 1 to 5 and m = −3 to 5: 45 cases.

At m = 0 it gives the genus: $`g = h^1(\mathcal{O}_C) = h^0(\mathcal{O}(d - 3)) = (d - 1)(d - 2)/2`$, the degree-genus formula. For d = 1 to 5 that is 0, 0, 1, 3, 6.

### Step 4: the Euler characteristic grows by one per point

Define the genus of a smooth projective curve as $`g = h^1(\mathcal{O}_C)`$. The constants are the only global functions on a connected closed curve, so $`h^0(\mathcal{O}_C) = 1`$ and $`\chi(\mathcal{O}_C) = 1 - g`$.

Add one point P to D. The sections of $`\mathcal{O}_C(D + P)`$ may have one more pole order at P. This gives the exact sequence $`0 \to \mathcal{O}_C(D) \to \mathcal{O}_C(D + P) \to k_P \to 0`$, where $`k_P`$ is one copy of k sitting at P. This step uses k algebraically closed: over ℚ a point whose coordinates need a square root counts twice, so it adds 2, not 1. A sheaf on one point has $`h^0 = 1`$ and no higher cohomology. The long exact sequence makes χ additive, so:

```math
\chi(\mathcal{O}_C(D + P)) = \chi(\mathcal{O}_C(D)) + 1
```

Every divisor is reached from 0 by adding and removing points. So $`\chi(\mathcal{O}_C(D)) = \deg D + 1 - g`$ for every D. The code checks it on the plane curves at all 45 cases.

### Step 5: Riemann-Roch

On a curve, n = 1. Serre duality with $`\mathcal{F} = \mathcal{O}_C(D)`$ and i = 1 says $`h^1(\mathcal{O}_C(D)) = h^0(\mathcal{O}_C(-D) \otimes K) = \ell(K - D)`$. Put it into Step 4:

```math
\ell(D) - \ell(K - D) = \chi(\mathcal{O}_C(D)) = \deg D + 1 - g
```

That is Riemann-Roch, as stated on [Divisors and Riemann-Roch](../03-Plane%20Curves/07-divisors-and-riemann-roch.md). Two consequences fall out at once.

- **D = 0:** $`1 - \ell(K) = 1 - g`$, so $`\ell(K) = g`$: a curve of genus g has g independent differentials.
- **D = K:** $`g - 1 = \deg K + 1 - g`$, so $`\deg K = 2g - 2`$. On a plane curve, deg K = d(d − 3), and the code checks d(d − 3) = 2g − 2 for d = 1 to 5.

---

## Worked numbers, by hand

The three examples: the line, the plane cubic $`x^3 + y^3 + z^3 = 0`$ and the plane quartic $`x^4 + y^4 + z^4 = 0`$, over ℚ.

| Step | Arithmetic | Value |
| --- | --- | --- |
| $`h^1(\mathcal{O}(-3))`$ on $`\mathbb{P}^1`$ | monomials with both exponents ≤ −1, degree −3: $`x^{-1}y^{-2}`$, $`x^{-2}y^{-1}`$ | 2 |
| its partner | $`\mathcal{O}(3) \otimes \mathcal{O}(-2)`$ | $`\mathcal{O}(1)`$ |
| $`h^0(\mathcal{O}(1))`$ | x, y | 2 |
| cubic: genus | (3 − 1)(3 − 2)/2 | 1 |
| cubic: K | $`\mathcal{O}_C(3 - 3)`$ | $`\mathcal{O}_C`$, degree 0 |
| cubic: D = line section | 1 · 3 | degree 3 |
| cubic: $`\ell(K - D)`$ | $`h^0(\mathcal{O}_C(-1))`$ | 0 |
| cubic: Riemann-Roch | 3 + 1 − 1 + 0 | $`\ell(D) = 3`$ |
| quartic: genus | (4 − 1)(4 − 2)/2 | 3 |
| quartic: K | $`\mathcal{O}_C(4 - 3)`$, a line section | degree 4 = 2 · 3 − 2 |
| quartic: $`\ell(K - K)`$ | $`\ell(0)`$, the constants | 1 |
| quartic: Riemann-Roch at D = K | 4 + 1 − 3 + 1 | **ℓ(K) = 3** |

The quartic has exactly three independent differentials, one for each linear form x, y, z. So its canonical map, which sends a point to the values of those three, is the plane embedding itself.

On the cubic, every divisor of degree 3 has $`\ell = 3`$ by the same line, since K = 0 and $`\ell(K - D) = 0`$ at positive degree. The code computes the line section only.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| $`K = \mathcal{O}(-n)`$ on $`\mathbb{P}^n`$ | 24 of 79 dimension checks fail | the mirror point is off by a half step |
| pair $`H^1(\mathcal{O}(-3))`$ with $`H^0(\mathcal{O}(3))`$ | 4, not 2 | the dual was taken but not twisted by K |
| Riemann-Roch without $`\ell(K - D)`$ | quartic at D = K: 2, not 3; cubic at D = 0: 0, not 1 | the correction term can be nonzero when deg D ≤ 2g − 2 |
| duality on the affine line | $`h^0(\mathcal{O})`$ = 11, 101, 1001 at degree ≤ 10, 100, 1000; $`h^1(K) = 0`$ | not projective: infinite on one side, 0 on the other |

---

## Code, from first principles, and it actually runs

The code computes the Cech cohomology of $`\mathcal{O}(d)`$ on $`\mathbb{P}^1`$, $`\mathbb{P}^2`$ and $`\mathbb{P}^3`$ by exact ranks, then tests duality and the pairing. It reaches the curve numbers by three independent roads:

1. **Cech ranks**, carried to the curve through the sequence of Step 3;
2. **counting monomials**: the degree-m part of $`k[x, y, z]/(x^d + y^d + z^d)`$ is spanned by the monomials whose z-power is below d, and those are counted directly;
3. **points over $`\mathbb{F}_{13}`$**: the code finds every point of the curve and computes the rank of the degree-m forms evaluated on them. A form that is not a multiple of the equation cannot vanish at more than md points (Bezout), so with enough points the rank equals $`\ell(D)`$. The case D = 4K on the quartic tests the curve itself: of the 15 forms of degree 4, the equation vanishes at every point, so the rank is 14.

Riemann-Roch is checked against all three, and the Cech ranks against the binomials of Step 1.

### Python

```python
# Serre duality and Riemann-Roch -- the check behind the card.  Standard library only.
# Road 1: Cech cohomology of O(d) on P^n by exact ranks, one Laurent monomial x^a at a time.
# Road 2: closed counts of monomials.  Road 3: a curve's points over F_13, and the rank of forms on them.
from itertools import combinations, product
from math import comb, gcd

def rank(rows, p=0):                                   # exact rank: over Q (p = 0) or over F_p
    M = [r[:] for r in rows]; r = 0
    for c in range(len(M[0]) if M else 0):
        q = next((i for i in range(r, len(M)) if (M[i][c] % p if p else M[i][c])), None)
        if q is None: continue
        M[r], M[q] = M[q], M[r]
        for i in range(r + 1, len(M)):
            M[i] = [M[r][c] * x - M[i][c] * y for x, y in zip(M[i], M[r])]
            g = 0
            for x in M[i]: g = gcd(g, x)
            M[i] = [x % p if p else x // max(g, 1) for x in M[i]]
        r += 1
    return r

def face(J, I):                                        # sign of I inside J in the Cech differential
    for k in range(len(J)):
        if J[:k] + J[k + 1:] == I: return (-1) ** k
    return 0

def cech(n, d):                                        # h^0..h^n of O(d) on P^n from the n + 1 standard charts
    B, h, top = abs(d) + n + 1, [0] * (n + 1), {0: [], n: []}
    for head in product(range(-B, B + 1), repeat=n):
        a = head + (d - sum(head),)                    # the monomial x_0^a_0 ... x_n^a_n of degree d
        if abs(a[-1]) > B: continue
        neg = {j for j in range(n + 1) if a[j] < 0}    # it lives on the overlaps U_I with I containing neg
        cells = [[I for I in combinations(range(n + 1), p + 1) if neg <= set(I)] for p in range(n + 1)]
        rk = [0] * (n + 2)                             # rk[p]: rank of the Cech map C^(p-1) -> C^p
        for p in range(1, n + 1):
            if cells[p - 1] and cells[p]:
                rk[p] = rank([[face(J, I) for I in cells[p - 1]] for J in cells[p]])
        for p in range(n + 1):
            k = len(cells[p]) - rk[p] - rk[p + 1]
            h[p] += k
            if k and p in top: top[p].append(a)
    return h, top

H, RANGE = {}, {1: (-5, 3), 2: (-8, 5), 3: (-5, 1)}   # each range is symmetric under d -> -d - n - 1
for n, (lo, hi) in RANGE.items():
    for d in range(lo, hi + 1): H[n, d] = cech(n, d)
    for i in range(n + 1):
        print(f"P^{n}, h^{i}(O(d)) for d = {lo}..{hi}: {[H[n, d][0][i] for d in range(lo, hi + 1)]}")
closed = lambda n, d, i: comb(d + n, n) if i == 0 and d >= 0 else comb(-d - 1, n) if i == n and d <= -n - 1 else 0
assert all(H[n, d][0][i] == closed(n, d, i) for n, d in H for i in range(n + 1))
print(f"Cech ranks against the monomial counts C(d + n, n) and C(-d - 1, n): agree at all {len(H)} (n, d)")
ok = [H[n, d][0][i] == H[n, -d - n - 1][0][n - i] for n, d in H for i in range(n + 1)]
bad = [H[n, d][0][i] != H[n, -d - n][0][n - i] for n, d in H if (n, -d - n) in H for i in range(n + 1)]
print(f"Serre duality, K = O(-n - 1): h^i(O(d)) = h^(n-i)(O(-d - n - 1)) at {sum(ok)} of {len(ok)} (n, d, i)")
print(f"mistake, K = O(-n): {sum(bad)} of {len(bad)} (n, d, i) fail")
assert all(ok) and any(bad)
sizes = []
for n, d in H:                                         # the Cech pairing H^0(O(d)) x H^n(O(-d-n-1)) -> H^n(K)
    A, Bd = H[n, d][1][0], H[n, -d - n - 1][1][n]
    if A:
        M = [[int(all(x + y == -1 for x, y in zip(a, b))) for b in Bd] for a in A]
        assert len(A) == len(Bd) == rank(M); sizes.append(len(A))
print(f"Cech pairing, x^a times x^b lands on 1/(x_0...x_n) exactly when b = -1 - a: perfect at {len(sizes)} (n, d), sizes up to {max(sizes)} x {max(sizes)}")
A, Bd = H[1, 1][1][0], H[1, -3][1][1]
print(f"P^1: H^0(O(1)) has exponents {A}, H^1(O(-3)) has {Bd}")
print(f"P^1: pairing matrix {[[int(all(x + y == -1 for x, y in zip(a, b))) for b in Bd] for a in A]}, so h^1(O(-3)) = {len(Bd)} = h^0(O(1))")
print(f"mistake, pair H^1(O(-3)) with H^0 of the dual O(3) alone: {H[1, 3][0][0]}, not {len(Bd)}")
hP = lambda i, m: H[2, m][0][i]                        # plane curve C of degree d: 0 -> O(m - d) -> O(m) -> O_C(m) -> 0
h0C = lambda d, m: hP(0, m) - hP(0, m - d)             # the H^1 terms of P^2 are 0, as printed above
h1C = lambda d, m: hP(2, m - d) - hP(2, m)
mon = lambda d, m: sum(1 for i in range(m + 1) for j in range(m + 1 - i) if m - i - j < d)   # z-power below d
gs = [h1C(d, 0) for d in range(1, 6)]
print(f"plane curves x^d + y^d + z^d, d = 1..5: genus h^1(O_C) = h^2(O(-d)) - h^2(O) = {gs}; (d-1)(d-2)/2 = {[(d - 1) * (d - 2) // 2 for d in range(1, 6)]}")
print(f"deg K = d(d - 3) = {[d * (d - 3) for d in range(1, 6)]}; 2g - 2 = {[2 * g - 2 for g in gs]}")
assert gs == [(d - 1) * (d - 2) // 2 for d in range(1, 6)] and all(d * (d - 3) == 2 * gs[d - 1] - 2 for d in range(1, 6))
pairs = [(d, m) for d in range(1, 6) for m in range(-3, 6)]
dual = all(h1C(d, m) == h0C(d, d - 3 - m) for d, m in pairs)
chi = all(h0C(d, m) - h1C(d, m) == m * d + 1 - gs[d - 1] for d, m in pairs)
rr = all(h0C(d, m) - h0C(d, d - 3 - m) == m * d + 1 - gs[d - 1] for d, m in pairs)
mons = all(h0C(d, m) == mon(d, m) for d, m in pairs if m >= 0)
print(f"on C, D = m times a line section, m = -3..5: duality h^1(O_C(D)) = h^0(O_C(K - D)) at all {len(pairs)}: {dual}")
print(f"chi(O_C(D)) = deg D + 1 - g at all {len(pairs)}: {chi}; Riemann-Roch l(D) - l(K - D) = deg D + 1 - g: {rr}")
print(f"h^0(O_C(m)) against the monomials of degree m with z-power below d, m >= 0: {mons}")
assert dual and chi and rr and mons
p = 13
def pts(d):                                            # points of x^d + y^d + z^d = 0 over F_13, one per line through 0
    cand = [(1, y, z) for y in range(p) for z in range(p)] + [(0, 1, z) for z in range(p)] + [(0, 0, 1)]
    return [v for v in cand if sum(c ** d for c in v) % p == 0]
def evrank(d, m):                                      # rank of the degree-m forms evaluated at those points
    ms = [(i, j, m - i - j) for i in range(m + 1) for j in range(m + 1 - i)]
    return rank([[pow(x, i, p) * pow(y, j, p) * pow(z, k, p) % p for i, j, k in ms] for x, y, z in pts(d)], p)
for d, m, what in ((3, 1, "cubic, D = line section, degree 3"), (4, 1, "quartic, D = K = line section, degree 4"), (4, 2, "quartic, D = 2K, degree 8"), (4, 4, "quartic, D = 4K, degree 16")):
    g, e = gs[d - 1], h0C(d, d - 3 - m)
    print(f"{what}: h^0 = {h0C(d, m)}; monomials {mon(d, m)}; Riemann-Roch {m * d} + 1 - {g} + l(K - D) {e} = {m * d + 1 - g + e}")
    print(f"  over F_{p}: {len(pts(d))} points; the {comb(m + 2, 2)} forms of degree {m} have rank {evrank(d, m)} on them")
    assert h0C(d, m) == mon(d, m) == m * d + 1 - g + e == evrank(d, m) and len(pts(d)) > m * d
print(f"quartic: h^0(2K) = {h0C(4, 2)} = 3g - 3, the number of parameters of curves of genus 3")
print(f"mistake, Riemann-Roch without l(K - D): quartic at D = K gives {4 + 1 - 3}, not {h0C(4, 1)}; cubic at D = 0 gives {0 + 1 - 1}, not {h0C(3, 0)}")
aff = [sum(1 for a in range(N + 1)) for N in (10, 100, 1000)]   # the monomials x^a with 0 <= a <= N on the one chart
c1 = list(combinations(range(1), 2))                   # Cech 1-cells of a one-chart cover: none, so h^1 = 0
print(f"mistake, the affine line (not projective): polynomials of degree <= N number {aff}, no end; h^1(K) = {len(c1)} with one chart")
assert aff[0] < aff[1] < aff[2] and not c1
print("ALL CHECKS PASS")
```

**Ran 2026-11-24 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
P^1, h^0(O(d)) for d = -5..3: [0, 0, 0, 0, 0, 1, 2, 3, 4]
P^1, h^1(O(d)) for d = -5..3: [4, 3, 2, 1, 0, 0, 0, 0, 0]
P^2, h^0(O(d)) for d = -8..5: [0, 0, 0, 0, 0, 0, 0, 0, 1, 3, 6, 10, 15, 21]
P^2, h^1(O(d)) for d = -8..5: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
P^2, h^2(O(d)) for d = -8..5: [21, 15, 10, 6, 3, 1, 0, 0, 0, 0, 0, 0, 0, 0]
P^3, h^0(O(d)) for d = -5..1: [0, 0, 0, 0, 0, 1, 4]
P^3, h^1(O(d)) for d = -5..1: [0, 0, 0, 0, 0, 0, 0]
P^3, h^2(O(d)) for d = -5..1: [0, 0, 0, 0, 0, 0, 0]
P^3, h^3(O(d)) for d = -5..1: [4, 1, 0, 0, 0, 0, 0]
Cech ranks against the monomial counts C(d + n, n) and C(-d - 1, n): agree at all 30 (n, d)
Serre duality, K = O(-n - 1): h^i(O(d)) = h^(n-i)(O(-d - n - 1)) at 88 of 88 (n, d, i)
mistake, K = O(-n): 24 of 79 (n, d, i) fail
Cech pairing, x^a times x^b lands on 1/(x_0...x_n) exactly when b = -1 - a: perfect at 12 (n, d), sizes up to 21 x 21
P^1: H^0(O(1)) has exponents [(0, 1), (1, 0)], H^1(O(-3)) has [(-2, -1), (-1, -2)]
P^1: pairing matrix [[0, 1], [1, 0]], so h^1(O(-3)) = 2 = h^0(O(1))
mistake, pair H^1(O(-3)) with H^0 of the dual O(3) alone: 4, not 2
plane curves x^d + y^d + z^d, d = 1..5: genus h^1(O_C) = h^2(O(-d)) - h^2(O) = [0, 0, 1, 3, 6]; (d-1)(d-2)/2 = [0, 0, 1, 3, 6]
deg K = d(d - 3) = [-2, -2, 0, 4, 10]; 2g - 2 = [-2, -2, 0, 4, 10]
on C, D = m times a line section, m = -3..5: duality h^1(O_C(D)) = h^0(O_C(K - D)) at all 45: True
chi(O_C(D)) = deg D + 1 - g at all 45: True; Riemann-Roch l(D) - l(K - D) = deg D + 1 - g: True
h^0(O_C(m)) against the monomials of degree m with z-power below d, m >= 0: True
cubic, D = line section, degree 3: h^0 = 3; monomials 3; Riemann-Roch 3 + 1 - 1 + l(K - D) 0 = 3
  over F_13: 9 points; the 3 forms of degree 1 have rank 3 on them
quartic, D = K = line section, degree 4: h^0 = 3; monomials 3; Riemann-Roch 4 + 1 - 3 + l(K - D) 1 = 3
  over F_13: 32 points; the 3 forms of degree 1 have rank 3 on them
quartic, D = 2K, degree 8: h^0 = 6; monomials 6; Riemann-Roch 8 + 1 - 3 + l(K - D) 0 = 6
  over F_13: 32 points; the 6 forms of degree 2 have rank 6 on them
quartic, D = 4K, degree 16: h^0 = 14; monomials 14; Riemann-Roch 16 + 1 - 3 + l(K - D) 0 = 14
  over F_13: 32 points; the 15 forms of degree 4 have rank 14 on them
quartic: h^0(2K) = 6 = 3g - 3, the number of parameters of curves of genus 3
mistake, Riemann-Roch without l(K - D): quartic at D = K gives 2, not 3; cubic at D = 0 gives 0, not 1
mistake, the affine line (not projective): polynomials of degree <= N number [11, 101, 1001], no end; h^1(K) = 0 with one chart
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Serre duality and Riemann-Roch -- the same check as the Python.  No crates.
// Road 1: Cech cohomology of O(d) on P^n by exact ranks, one Laurent monomial x^a at a time.
// Road 2: closed counts of monomials.  Road 3: a curve's points over F_13, and the rank of forms on them.
use std::collections::HashMap;
type Hc = (Vec<i64>, Vec<Vec<i64>>, Vec<Vec<i64>>); // h^0..h^n, exponents spanning H^0, exponents spanning H^n

fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn rank(rows: &Vec<Vec<i128>>, p: i128) -> usize { // exact rank: over Q (p = 0) or over F_p
    let mut m = rows.clone(); let mut r = 0;
    let cols = if m.is_empty() { 0 } else { m[0].len() };
    for c in 0..cols {
        let nz = |v: i128| if p > 0 { v % p != 0 } else { v != 0 };
        let q = match (r..m.len()).find(|&i| nz(m[i][c])) { Some(q) => q, None => continue };
        m.swap(r, q);
        for i in r + 1..m.len() {
            let (a, b) = (m[r][c], m[i][c]);
            let row: Vec<i128> = (0..cols).map(|k| a.checked_mul(m[i][k]).unwrap() - b.checked_mul(m[r][k]).unwrap()).collect();
            let g = row.iter().fold(0, |g, &x| gcd(g, x)).max(1);
            m[i] = row.iter().map(|&x| if p > 0 { x.rem_euclid(p) } else { x / g }).collect();
        }
        r += 1;
    }
    r
}
fn face(j: &Vec<usize>, i: &Vec<usize>) -> i128 { // sign of I inside J in the Cech differential
    for k in 0..j.len() {
        let mut s = j.clone(); s.remove(k);
        if &s == i { return if k % 2 == 0 { 1 } else { -1 }; }
    }
    0
}
fn combos(n: usize, k: usize) -> Vec<Vec<usize>> { // subsets of 0..n of size k, in lexicographic order
    if k == 0 { return vec![vec![]]; }
    let mut out = vec![];
    for first in 0..n { for rest in combos(n, k - 1) { if rest.iter().all(|&x| x > first) { let mut v = vec![first]; v.extend(rest); out.push(v); } } }
    out
}
fn cech(n: usize, d: i64) -> Hc { // h^0..h^n of O(d) on P^n from the n + 1 standard charts
    let b = d.abs() + n as i64 + 1;
    let (mut h, mut top0, mut topn) = (vec![0i64; n + 1], vec![], vec![]);
    let mut head = vec![-b; n];
    loop {
        let last = d - head.iter().sum::<i64>();
        if last.abs() <= b {
            let mut a = head.clone(); a.push(last); // the monomial x_0^a_0 ... x_n^a_n of degree d
            let neg: Vec<usize> = (0..=n).filter(|&j| a[j] < 0).collect();
            let cells: Vec<Vec<Vec<usize>>> = (0..=n).map(|p| combos(n + 1, p + 1).into_iter().filter(|c| neg.iter().all(|x| c.contains(x))).collect()).collect();
            let mut rk = vec![0usize; n + 2]; // rk[p]: rank of the Cech map C^(p-1) -> C^p
            for p in 1..=n {
                if !cells[p - 1].is_empty() && !cells[p].is_empty() {
                    rk[p] = rank(&cells[p].iter().map(|j| cells[p - 1].iter().map(|i| face(j, i)).collect()).collect(), 0);
                }
            }
            for p in 0..=n {
                let k = cells[p].len() as i64 - rk[p] as i64 - rk[p + 1] as i64;
                h[p] += k;
                if k > 0 && p == 0 { top0.push(a.clone()); }
                if k > 0 && p == n { topn.push(a.clone()); }
            }
        }
        let mut i = n; // next head, last coordinate fastest
        loop { if i == 0 { return (h, top0, topn); } i -= 1; if head[i] < b { head[i] += 1; break; } head[i] = -b; }
    }
}
fn comb(n: i64, k: i64) -> i64 { if k < 0 || n < k { 0 } else { (0..k).fold(1, |c, i| c * (n - i) / (i + 1)) } }
fn tf(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn lst(v: &Vec<i64>) -> String { format!("[{}]", v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ")) }
fn tup(v: &Vec<Vec<i64>>) -> String { format!("[{}]", v.iter().map(|t| format!("({})", t.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", "))).collect::<Vec<_>>().join(", ")) }
fn pairing(a: &Vec<Vec<i64>>, b: &Vec<Vec<i64>>) -> Vec<Vec<i128>> {
    a.iter().map(|x| b.iter().map(|y| x.iter().zip(y).all(|(u, v)| u + v == -1) as i128).collect()).collect() }
fn main() {
    let mut hh: HashMap<(usize, i64), Hc> = HashMap::new(); let mut keys = vec![];
    for (n, lo, hi) in [(1usize, -5i64, 3i64), (2, -8, 5), (3, -5, 1)] { // each range is symmetric under d -> -d - n - 1
        for d in lo..=hi { hh.insert((n, d), cech(n, d)); keys.push((n, d)); }
        for i in 0..=n { println!("P^{}, h^{}(O(d)) for d = {}..{}: {}", n, i, lo, hi, lst(&(lo..=hi).map(|d| hh[&(n, d)].0[i]).collect())); }
    }
    let closed = |n: i64, d: i64, i: i64| if i == 0 && d >= 0 { comb(d + n, n) } else if i == n && d <= -n - 1 { comb(-d - 1, n) } else { 0 };
    assert!(keys.iter().all(|&(n, d)| (0..=n).all(|i| hh[&(n, d)].0[i] == closed(n as i64, d, i as i64))));
    println!("Cech ranks against the monomial counts C(d + n, n) and C(-d - 1, n): agree at all {} (n, d)", keys.len());
    let (mut ok, mut bad) = (vec![], vec![]);
    for &(n, d) in &keys {
        for i in 0..=n { ok.push(hh[&(n, d)].0[i] == hh[&(n, -d - n as i64 - 1)].0[n - i]); }
        if let Some(w) = hh.get(&(n, -d - n as i64)) { for i in 0..=n { bad.push(hh[&(n, d)].0[i] != w.0[n - i]); } }
    }
    let cnt = |v: &Vec<bool>| v.iter().filter(|&&x| x).count();
    println!("Serre duality, K = O(-n - 1): h^i(O(d)) = h^(n-i)(O(-d - n - 1)) at {} of {} (n, d, i)", cnt(&ok), ok.len());
    println!("mistake, K = O(-n): {} of {} (n, d, i) fail", cnt(&bad), bad.len());
    assert!(cnt(&ok) == ok.len() && cnt(&bad) > 0);
    let mut sizes = vec![]; // the Cech pairing H^0(O(d)) x H^n(O(-d-n-1)) -> H^n(K)
    for &(n, d) in &keys {
        let (a, b) = (&hh[&(n, d)].1, &hh[&(n, -d - n as i64 - 1)].2);
        if !a.is_empty() { assert!(a.len() == b.len() && b.len() == rank(&pairing(a, b), 0)); sizes.push(a.len()); }
    }
    let mx = *sizes.iter().max().unwrap();
    println!("Cech pairing, x^a times x^b lands on 1/(x_0...x_n) exactly when b = -1 - a: perfect at {} (n, d), sizes up to {} x {}", sizes.len(), mx, mx);
    let (a, b) = (&hh[&(1, 1)].1, &hh[&(1, -3)].2);
    println!("P^1: H^0(O(1)) has exponents {}, H^1(O(-3)) has {}", tup(a), tup(b));
    let pm: Vec<Vec<i64>> = pairing(a, b).iter().map(|r| r.iter().map(|&x| x as i64).collect()).collect();
    println!("P^1: pairing matrix {}, so h^1(O(-3)) = {} = h^0(O(1))", tup(&pm).replace('(', "[").replace(')', "]"), b.len());
    println!("mistake, pair H^1(O(-3)) with H^0 of the dual O(3) alone: {}, not {}", hh[&(1, 3)].0[0], b.len());
    let hp = |i: usize, m: i64| hh[&(2, m)].0[i]; // plane curve C of degree d: 0 -> O(m - d) -> O(m) -> O_C(m) -> 0
    let h0c = |d: i64, m: i64| hp(0, m) - hp(0, m - d); // the H^1 terms of P^2 are 0, as printed above
    let h1c = |d: i64, m: i64| hp(2, m - d) - hp(2, m);
    let mon = |d: i64, m: i64| (0..=m).map(|i| (0..=m - i).filter(|j| m - i - j < d).count() as i64).sum::<i64>(); // z-power below d
    let gs: Vec<i64> = (1..6).map(|d| h1c(d, 0)).collect();
    println!("plane curves x^d + y^d + z^d, d = 1..5: genus h^1(O_C) = h^2(O(-d)) - h^2(O) = {}; (d-1)(d-2)/2 = {}", lst(&gs), lst(&(1..6).map(|d| (d - 1) * (d - 2) / 2).collect()));
    println!("deg K = d(d - 3) = {}; 2g - 2 = {}", lst(&(1..6).map(|d| d * (d - 3)).collect()), lst(&gs.iter().map(|g| 2 * g - 2).collect()));
    assert!((1..6).all(|d| gs[d as usize - 1] == (d - 1) * (d - 2) / 2 && d * (d - 3) == 2 * gs[d as usize - 1] - 2));
    let pairs: Vec<(i64, i64)> = (1..6).flat_map(|d| (-3..6).map(move |m| (d, m))).collect();
    let g = |d: i64| gs[d as usize - 1];
    let dual = pairs.iter().all(|&(d, m)| h1c(d, m) == h0c(d, d - 3 - m));
    let chi = pairs.iter().all(|&(d, m)| h0c(d, m) - h1c(d, m) == m * d + 1 - g(d));
    let rr = pairs.iter().all(|&(d, m)| h0c(d, m) - h0c(d, d - 3 - m) == m * d + 1 - g(d));
    let mons = pairs.iter().filter(|e| e.1 >= 0).all(|&(d, m)| h0c(d, m) == mon(d, m));
    println!("on C, D = m times a line section, m = -3..5: duality h^1(O_C(D)) = h^0(O_C(K - D)) at all {}: {}", pairs.len(), tf(dual));
    println!("chi(O_C(D)) = deg D + 1 - g at all {}: {}; Riemann-Roch l(D) - l(K - D) = deg D + 1 - g: {}", pairs.len(), tf(chi), tf(rr));
    println!("h^0(O_C(m)) against the monomials of degree m with z-power below d, m >= 0: {}", tf(mons));
    assert!(dual && chi && rr && mons);
    let p: i128 = 13;
    let pts = |d: u32| -> Vec<[i128; 3]> { // points of x^d + y^d + z^d = 0 over F_13, one per line through 0
        let mut c: Vec<[i128; 3]> = (0..p).flat_map(|y| (0..p).map(move |z| [1, y, z])).collect();
        c.extend((0..p).map(|z| [0, 1, z])); c.push([0, 0, 1]);
        c.into_iter().filter(|v| v.iter().map(|x| x.pow(d)).sum::<i128>() % p == 0).collect() };
    let evrank = |d: u32, m: u32| { // rank of the degree-m forms evaluated at those points
        let ms: Vec<(u32, u32, u32)> = (0..=m).flat_map(|i| (0..=m - i).map(move |j| (i, j, m - i - j))).collect();
        rank(&pts(d).iter().map(|v| ms.iter().map(|&(i, j, k)| v[0].pow(i) * v[1].pow(j) * v[2].pow(k) % p).collect()).collect(), p) as i64 };
    for (d, m, what) in [(3i64, 1i64, "cubic, D = line section, degree 3"), (4, 1, "quartic, D = K = line section, degree 4"), (4, 2, "quartic, D = 2K, degree 8"), (4, 4, "quartic, D = 4K, degree 16")] {
        let (gg, e) = (g(d), h0c(d, d - 3 - m));
        let (np, er) = (pts(d as u32).len() as i64, evrank(d as u32, m as u32));
        println!("{}: h^0 = {}; monomials {}; Riemann-Roch {} + 1 - {} + l(K - D) {} = {}", what, h0c(d, m), mon(d, m), m * d, gg, e, m * d + 1 - gg + e);
        println!("  over F_{}: {} points; the {} forms of degree {} have rank {} on them", p, np, comb(m + 2, 2), m, er);
        assert!(h0c(d, m) == mon(d, m) && mon(d, m) == m * d + 1 - gg + e && e + m * d + 1 - gg == er && np > m * d);
    }
    println!("quartic: h^0(2K) = {} = 3g - 3, the number of parameters of curves of genus 3", h0c(4, 2));
    println!("mistake, Riemann-Roch without l(K - D): quartic at D = K gives {}, not {}; cubic at D = 0 gives {}, not {}", 4 + 1 - 3, h0c(4, 1), 0 + 1 - 1, h0c(3, 0));
    let aff: Vec<i64> = [10i64, 100, 1000].iter().map(|&n| (0..=n).count() as i64).collect(); // the monomials x^a with 0 <= a <= N on the one chart
    let c1 = combos(1, 2); // Cech 1-cells of a one-chart cover: none, so h^1 = 0
    println!("mistake, the affine line (not projective): polynomials of degree <= N number {}, no end; h^1(K) = {} with one chart", lst(&aff), c1.len());
    assert!(aff[0] < aff[1] && aff[1] < aff[2] && c1.is_empty());
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-24 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
P^1, h^0(O(d)) for d = -5..3: [0, 0, 0, 0, 0, 1, 2, 3, 4]
P^1, h^1(O(d)) for d = -5..3: [4, 3, 2, 1, 0, 0, 0, 0, 0]
P^2, h^0(O(d)) for d = -8..5: [0, 0, 0, 0, 0, 0, 0, 0, 1, 3, 6, 10, 15, 21]
P^2, h^1(O(d)) for d = -8..5: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
P^2, h^2(O(d)) for d = -8..5: [21, 15, 10, 6, 3, 1, 0, 0, 0, 0, 0, 0, 0, 0]
P^3, h^0(O(d)) for d = -5..1: [0, 0, 0, 0, 0, 1, 4]
P^3, h^1(O(d)) for d = -5..1: [0, 0, 0, 0, 0, 0, 0]
P^3, h^2(O(d)) for d = -5..1: [0, 0, 0, 0, 0, 0, 0]
P^3, h^3(O(d)) for d = -5..1: [4, 1, 0, 0, 0, 0, 0]
Cech ranks against the monomial counts C(d + n, n) and C(-d - 1, n): agree at all 30 (n, d)
Serre duality, K = O(-n - 1): h^i(O(d)) = h^(n-i)(O(-d - n - 1)) at 88 of 88 (n, d, i)
mistake, K = O(-n): 24 of 79 (n, d, i) fail
Cech pairing, x^a times x^b lands on 1/(x_0...x_n) exactly when b = -1 - a: perfect at 12 (n, d), sizes up to 21 x 21
P^1: H^0(O(1)) has exponents [(0, 1), (1, 0)], H^1(O(-3)) has [(-2, -1), (-1, -2)]
P^1: pairing matrix [[0, 1], [1, 0]], so h^1(O(-3)) = 2 = h^0(O(1))
mistake, pair H^1(O(-3)) with H^0 of the dual O(3) alone: 4, not 2
plane curves x^d + y^d + z^d, d = 1..5: genus h^1(O_C) = h^2(O(-d)) - h^2(O) = [0, 0, 1, 3, 6]; (d-1)(d-2)/2 = [0, 0, 1, 3, 6]
deg K = d(d - 3) = [-2, -2, 0, 4, 10]; 2g - 2 = [-2, -2, 0, 4, 10]
on C, D = m times a line section, m = -3..5: duality h^1(O_C(D)) = h^0(O_C(K - D)) at all 45: True
chi(O_C(D)) = deg D + 1 - g at all 45: True; Riemann-Roch l(D) - l(K - D) = deg D + 1 - g: True
h^0(O_C(m)) against the monomials of degree m with z-power below d, m >= 0: True
cubic, D = line section, degree 3: h^0 = 3; monomials 3; Riemann-Roch 3 + 1 - 1 + l(K - D) 0 = 3
  over F_13: 9 points; the 3 forms of degree 1 have rank 3 on them
quartic, D = K = line section, degree 4: h^0 = 3; monomials 3; Riemann-Roch 4 + 1 - 3 + l(K - D) 1 = 3
  over F_13: 32 points; the 3 forms of degree 1 have rank 3 on them
quartic, D = 2K, degree 8: h^0 = 6; monomials 6; Riemann-Roch 8 + 1 - 3 + l(K - D) 0 = 6
  over F_13: 32 points; the 6 forms of degree 2 have rank 6 on them
quartic, D = 4K, degree 16: h^0 = 14; monomials 14; Riemann-Roch 16 + 1 - 3 + l(K - D) 0 = 14
  over F_13: 32 points; the 15 forms of degree 4 have rank 14 on them
quartic: h^0(2K) = 6 = 3g - 3, the number of parameters of curves of genus 3
mistake, Riemann-Roch without l(K - D): quartic at D = K gives 2, not 3; cubic at D = 0 gives 0, not 1
mistake, the affine line (not projective): polynomials of degree <= N number [11, 101, 1001], no end; h^1(K) = 0 with one chart
ALL CHECKS PASS
```

### Lean

Lean proves the counting at the heart of duality on projective space, and Riemann-Roch for line sections of plane curves.

- Take $`\mathbb{P}^n`$ and any whole number d. Then $`x^a`$ in $`H^0(\mathcal{O}(d))`$ and $`x^{-1-a}`$ in $`H^n(\mathcal{O}(-d-n-1))`$ match one to one.
- Take $`n \ge 0`$ and $`d \ge 0`$. Then the monomials of degree d in n + 1 variables number $`\binom{d+n}{n}`$, which is $`h^0(\mathcal{O}(d))`$.
- Take a smooth plane curve of degree d ≥ 1, and D = m line sections for any whole number m. Then the counts of Step 3 give $`\ell(D) - \ell(K - D) = \deg D + 1 - g`$, with $`g = (d - 1)(d - 2)/2`$.
- On $`\mathbb{P}^1`$, $`h^1(\mathcal{O}(-3)) = 2 = h^0(\mathcal{O}(1))`$.
- On the cubic, a line section has $`\ell(D) = 3`$. On the quartic, $`\ell(K) = 3`$ and g = 3.

The Cech ranks, the 88 duality cases, the monomial and $`\mathbb{F}_{13}`$ roads and the mistakes are left to the Python and Rust checks.

```lean
-- Serre duality: on projective space the monomial bases of H^0(O(d)) and H^n(O(-d-n-1)) match one to one, and Riemann-Roch holds for line sections of plane curves.
import Mathlib.Data.Set.Function
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.SetTheory.Cardinal.Finite
import Mathlib.Data.Finsupp.Multiset
import Mathlib.Data.Sym.Card
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Ring

/-- Twice C(k, 2) is k (k - 1), as integers. -/
theorem two_mul_choose_two (k : ℕ) : 2 * (k.choose 2 : ℤ) = k * ((k : ℤ) - 1) := by
  induction k with
  | zero => simp
  | succ k ih =>
    rw [Nat.choose_succ_succ, Nat.choose_one_right]
    push_cast
    linarith

/-- Serre duality count on the plane: h^0(O(e)) + h^0(O(-3 - e)) = (e + 1)(e + 2)/2. -/
theorem h0P2_add_dual (e : ℤ) :
    2 * ((Nat.choose (e + 2).toNat 2 : ℤ) + (Nat.choose (-3 - e + 2).toNat 2 : ℤ)) =
      (e + 1) * (e + 2) := by
  rcases le_or_gt (-2) e with h | h
  · rcases le_or_gt 0 e with h' | h'
    · have h1 : ((-3 - e + 2).toNat) = 0 := by omega
      rw [h1, mul_add, two_mul_choose_two]
      simp [Int.toNat_of_nonneg (by omega : 0 ≤ e + 2)]
      ring
    · rw [Nat.choose_eq_zero_of_lt (by omega : (e + 2).toNat < 2),
        Nat.choose_eq_zero_of_lt (by omega : (-3 - e + 2).toNat < 2)]
      have : e = -1 ∨ e = -2 := by omega
      rcases this with rfl | rfl <;> norm_num
  · have h1 : ((e + 2).toNat) = 0 := by omega
    have T := two_mul_choose_two (-3 - e + 2).toNat
    rw [Int.toNat_of_nonneg (by omega : 0 ≤ -3 - e + 2)] at T
    rw [h1]
    simp only [Nat.choose_zero_succ, Nat.cast_zero, zero_add]
    linarith

#print axioms two_mul_choose_two
#print axioms h0P2_add_dual

/-- Serre duality on projective space P^n, by the Cech pairing. The Laurent monomials
x^a = x_0^(a_0) ... x_n^(a_n) spanning H^0(O(d)) are those of degree d with every exponent at
least 0; those spanning H^n(O(-d-n-1)) have degree -d-n-1 and every exponent at most -1. The
product x^a x^b lands on the top class 1/(x_0 ... x_n) exactly when b = -1 - a, and this rule
matches the two bases one to one. So the pairing is perfect and
H^0(O(d)) is dual to H^n(O(-d-n-1)), with K = O(-n-1). -/
theorem cech_pairing_matches_sections_with_top_classes (n : ℕ) (d : ℤ) :
    Set.BijOn (fun a : Fin (n + 1) → ℤ => fun i => -1 - a i)
      {a | (∀ i, 0 ≤ a i) ∧ ∑ i, a i = d}
      {b | (∀ i, b i ≤ -1) ∧ ∑ i, b i = -d - ((n : ℤ) + 1)} := by
  refine ⟨?_, ?_, ?_⟩
  · rintro a ⟨h0, hs⟩
    refine ⟨fun i => by linarith [h0 i], ?_⟩
    simp only [Finset.sum_sub_distrib, Finset.sum_const, Finset.card_univ, Fintype.card_fin,
      hs, nsmul_eq_mul]
    push_cast; ring
  · intro a _ b _ h
    funext i
    have := congrFun h i
    simp only at this
    linarith
  · rintro b ⟨h0, hs⟩
    refine ⟨fun i => -1 - b i, ⟨fun i => by linarith [h0 i], ?_⟩, ?_⟩
    · simp only [Finset.sum_sub_distrib, Finset.sum_const, Finset.card_univ, Fintype.card_fin,
        hs, nsmul_eq_mul]
      push_cast; ring
    · funext i; simp

/-- The number of monomials of degree d in the n + 1 variables x_0, ..., x_n is the binomial
C(d + n, n): this is h^0(O(d)) on P^n for d ≥ 0. -/
theorem card_monomials_of_degree (n d : ℕ) :
    Nat.card {a : Fin (n + 1) → ℕ // ∑ i, a i = d} = Nat.choose (d + n) n := by
  rw [← Nat.card_congr (Sym.equivNatSumOfFintype (Fin (n + 1)) d), Nat.card_eq_fintype_card,
    Sym.card_sym_eq_choose, Fintype.card_fin]
  rw [show n + 1 + d - 1 = d + n by omega, Nat.choose_symm_add]

/-- Riemann-Roch for D = m line sections on a smooth plane curve C of degree d. Here
h^0(O_C(m)) = h^0(O(m)) - h^0(O(m - d)), with h^0(O(e)) = C(e + 2, 2) on the plane (0 for e < 0),
K = O_C(d - 3), deg D = m d and g = (d - 1)(d - 2)/2. Then
l(D) - l(K - D) = deg D + 1 - g for every whole number m. -/
theorem riemann_roch_plane_curve_line_sections (d : ℕ) (hd : 1 ≤ d) (m : ℤ) :
    let h0P2 : ℤ → ℤ := fun e => (Nat.choose (e + 2).toNat 2 : ℤ)
    let h0C : ℤ → ℤ := fun e => h0P2 e - h0P2 (e - d)
    h0C m - h0C ((d : ℤ) - 3 - m) = m * d + 1 - (((d - 1) * (d - 2) / 2 : ℕ) : ℤ) := by
  intro h0P2 h0C
  obtain ⟨k, rfl⟩ : ∃ k, d = k + 1 := ⟨d - 1, by omega⟩
  have hg : (k + 1 - 1) * (k + 1 - 2) / 2 = k.choose 2 := by
    rw [Nat.choose_two_right]; congr 1
  rw [hg]
  have A := h0P2_add_dual m
  have B := h0P2_add_dual (m - (k + 1 : ℕ))
  have G := two_mul_choose_two k
  have e1 : -3 - (m - ((k + 1 : ℕ) : ℤ)) = ((k + 1 : ℕ) : ℤ) - 3 - m := by ring
  have e2 : ((k + 1 : ℕ) : ℤ) - 3 - m - ((k + 1 : ℕ) : ℤ) = -3 - m := by ring
  rw [e1] at B
  simp only [h0C, h0P2, e2]
  push_cast at *
  linarith

-- P^1 with K = O(-2): h^1(O(-3)) = C(-(-3) - 1, 1) = 2 = h^0(O(1)) = C(1 + 1, 1).
example : Nat.choose ((-(-3 : ℤ) - 1).toNat) 1 = 2 ∧ Nat.choose (1 + 1) 1 = 2 := by decide

-- Plane cubic (d = 3, g = 1, K = O): D a line section, degree 3, has l(D) = C(3, 2) - C(0, 2) = 3.
example : (Nat.choose 3 2 : ℤ) - Nat.choose 0 2 = 3 ∧ (3 - 1) * (3 - 2) / 2 = 1 := by decide

-- Plane quartic (d = 4, g = 3): K is a line section of degree 4 and
-- l(K) = C(3, 2) - 0 = 3 = 4 + 1 - 3 + l(0), with l(0) = 1.
example : (Nat.choose 3 2 : ℤ) = 3 ∧ (4 : ℤ) + 1 - 3 + Nat.choose 2 2 = 3 ∧ (4 - 1) * (4 - 2) / 2 = 3 := by
  decide

#print axioms cech_pairing_matches_sections_with_top_classes
#print axioms card_monomials_of_degree
#print axioms riemann_roch_plane_curve_line_sections
```

**Checked 2026-11-24 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'two_mul_choose_two' depends on axioms: [propext, Classical.choice, Quot.sound]
'h0P2_add_dual' depends on axioms: [propext, Classical.choice, Quot.sound]
'cech_pairing_matches_sections_with_top_classes' depends on axioms: [propext, Classical.choice, Quot.sound]
'card_monomials_of_degree' depends on axioms: [propext, Classical.choice, Quot.sound]
'riemann_roch_plane_curve_line_sections' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> - Guess first: what is $`h^3(\mathcal{O}(-6))`$ on $`\mathbb{P}^3`$? In the Python line that sets `RANGE`, change `3: (-5, 1)` to `3: (-6, 2)`. The `P^3, h^3` line starts at 10, which equals $`h^0(\mathcal{O}(2)) = 10`$, the quadrics in four variables.
> - Guess first: how many differentials has a smooth plane quintic? Add `(5, 2, "quintic, D = K, degree 10")` to the list in the `for d, m, what` loop. The quintic has genus 6 and $`K = \mathcal{O}_C(2)`$; the new line prints $`h^0 = 6`$, by Riemann-Roch 10 + 1 − 6 + 1, and rank 6 on its 14 points over $`\mathbb{F}_{13}`$.
> - Guess first: what if the correction term is dropped? In the line that sets `rr`, replace `h0C(d, d - 3 - m)` by `0`. The assert after it stops the run: the formula then fails for every m ≤ d − 3.
> - Guess first: does every prime give enough points? Set `p = 29`. The Fermat quartic has no point at all over $`\mathbb{F}_{29}`$, the rank comes out at 0, and the assert stops the run. The point road needs more than md points.

---

## The usual mistake

> [!warning]
> **Pairing a sheaf with itself, or with its bare dual.** Serre duality matches $`H^i(\mathcal{F})`$ with $`H^{n-i}`$ of $`\mathcal{F}^\vee \otimes K`$, not of $`\mathcal{F}`$ and not of $`\mathcal{F}^\vee`$. On $`\mathbb{P}^1`$, $`H^1(\mathcal{O}(-3))`$ has dimension 2; $`H^0(\mathcal{O}(-3))`$ is 0 and $`H^0(\mathcal{O}(3))`$ is 4. Only the twist by $`K = \mathcal{O}(-2)`$ gives the right partner, $`\mathcal{O}(1)`$.
>
> - **The wrong canonical bundle.** K on $`\mathbb{P}^n`$ is $`\mathcal{O}(-n-1)`$. With $`\mathcal{O}(-n)`$, 24 of 79 checks fail.
> - **Dropping $`\ell(K - D)`$.** It is always 0 when deg D > 2g − 2, and can be nonzero below that. On the quartic at D = K the short formula gives 2, not 3; on the cubic at D = 0 it gives 0, not 1.
> - **Forgetting projectivity.** On the affine line the polynomials of degree at most 1000 already number 1001, while $`H^1(K) = 0`$.

---

## Where you meet it in real life

- **Error-correcting codes.** An algebraic-geometry code evaluates the functions of $`\mathcal{L}(D)`$ at points of a curve. Its dual code is built from differentials with poles bounded by a divisor related to K − D. Serre duality on the curve is why the dual code has the predicted dimension, and Riemann-Roch gives both dimensions.
- **Counting curves.** The curves of genus g ≥ 2 depend on 3g − 3 parameters. The deformations of C are $`H^1`$ of its tangent bundle, dual to $`H^0(2K)`$ by Serre duality, and Riemann-Roch gives $`\ell(2K) = 4g - 4 + 1 - g = 3g - 3`$. For the quartic the code prints 6.
- **Hodge numbers in geometry and physics.** On a smooth projective variety, Serre duality gives the symmetry $`h^{p,q} = h^{n-p,n-q}`$ of the Hodge numbers. Tables of these numbers, used in string theory to count particle families on Calabi-Yau spaces, rely on it to fill half of each table.

> **Say it back**
> On a smooth projective variety of dimension n, the cohomology of a sheaf in degree i is the dual of the cohomology in degree n − i of its dual twisted by the canonical bundle K. On projective space this is a one-to-one match of Laurent monomials, $`x^a`$ against $`x^{-1-a}`$, with $`K = \mathcal{O}(-n-1)`$. On a curve, the Euler characteristic of $`\mathcal{O}(D)`$ is deg D + 1 − g, because each added point adds one. Duality turns $`h^1(\mathcal{O}(D))`$ into $`\ell(K - D)`$, and that is Riemann-Roch. On the plane quartic, genus 3, it gives exactly 3 independent differentials.

---

## What this builds on

- [Sheaf cohomology](05-sheaf-cohomology-as-a-derived-functor.md): the groups $`H^i`$ and the long exact sequence that makes χ additive.
- [The canonical bundle and adjunction](02-canonical-bundle-and-adjunction.md): $`K = \mathcal{O}(-n-1)`$ on $`\mathbb{P}^n`$ and $`K_C = \mathcal{O}_C(d - 3)`$ on a plane curve.
- [Divisors and Riemann-Roch](../03-Plane%20Curves/07-divisors-and-riemann-roch.md): divisors, $`\ell(D)`$ and the statement of Riemann-Roch, which this card proves.
- [Ext](../07-Exact%20Sequences%2C%20Ext%20and%20Tor/05-ext-and-extensions.md): the Ext groups in the form of duality that holds for every coherent sheaf.
- [Cech cohomology](04-cech-cohomology-of-projective-space.md): the chart-by-chart complex that computes the cohomology of $`\mathcal{O}(d)`$ in Step 1.
- [Quasi-coherent sheaves](../06-Schemes%20and%20Modern%20Language/11-quasi-coherent-and-coherent-sheaves.md): coherent sheaves and $`\mathcal{O}(d)`$ as a shifted graded module.

## Where this goes next

- [The Weil conjectures](07-weil-conjectures-and-etale-cohomology.md): for curves, Riemann-Roch and the duality $`D \to K - D`$ give the functional equation of the zeta function over a finite field (Weil), and Poincaré duality in étale cohomology does it in every dimension. The zeta function ties together point counts like the 32 points of the quartic over $`\mathbb{F}_{13}`$.

This card computes cohomology dimensions over a field; it leaves open how duality behaves when the field is finite and the counts become point counts.

---

## Sources

Verified 2026-11-24: every link below resolves to the publisher's page.

- Hartshorne, Robin. *Algebraic Geometry*. Graduate Texts in Mathematics 52. Springer, 1977. [doi:10.1007/978-1-4757-3849-0](https://doi.org/10.1007/978-1-4757-3849-0). Section III.5: the Cech cohomology of $`\mathcal{O}(d)`$ on projective space; Section III.7: Serre duality; Section IV.1: Riemann-Roch proved from duality.
- Serre, Jean-Pierre. "Un théorème de dualité." *Commentarii Mathematici Helvetici* 29 (1955): 9–26. [doi:10.1007/BF02564268](https://doi.org/10.1007/BF02564268). The original duality theorem.
- Serre, Jean-Pierre. "Faisceaux algébriques cohérents." *Annals of Mathematics* 61, no. 2 (1955): 197–278. [doi:10.2307/1969915](https://doi.org/10.2307/1969915). Coherent sheaves, their cohomology on projective space and the twists $`\mathcal{O}(d)`$.
- Vakil, Ravi. *The Rising Sea: Foundations of Algebraic Geometry*. Princeton University Press, 2025. [doi:10.1515/9780691268682](https://doi.org/10.1515/9780691268682). A modern treatment of sheaf cohomology, Serre duality and Riemann-Roch for curves.
- Roch, Gustav. "Ueber die Anzahl der willkürlichen Constanten in algebraischen Functionen." *Journal für die reine und angewandte Mathematik* 64 (1865). [doi:10.1515/crll.1865.64.372](https://doi.org/10.1515/crll.1865.64.372). The correction term that Serre duality explains as $`h^1`$.
