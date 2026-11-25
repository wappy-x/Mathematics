# Haar measure: the one fair way to measure size on a group

[Syllabus](../../../SYLLABUS.md) → [Harmonic analysis](../README.md) → [Harmonic Analysis on Groups](../README.md#s08) → Haar measure

---

## General Overview

A share price that rises from $1 to $2 has doubled. So has one that rises from $5 to $10. Multiplying by 5 carries the first move onto the second, so for anything measured by ratios the two moves should count as the same size.

Ordinary length disagrees. The interval [1, 2] has length 1 and [5, 10] has length 5. Length is fair for **adding**: sliding [1, 2] to [6, 7] keeps length 1. It is unfair for **multiplying**.

The fix is to weigh each point x by 1/x. The size of [a, b] becomes the area under 1/x from a to b, which is ln(b/a), where ln is the natural logarithm. Then [1, 2], [2, 4], [4, 8] and [5, 10] all have size ln 2 = 0.693147. Stretching by any factor now keeps every size.

That is a **Haar measure**: a way to give sizes to sets in a group so that moving a set by any group member keeps its size. Alfred Haar proved in 1933 that a wide class of groups has one. Later work showed it is unique once one unit of size is chosen. Every Fourier theory on this shelf integrates against it.

Groups where the order of multiplying matters need care. On the ax + b group (the maps t ↦ at + b with a > 0, the stretch-and-shift maps behind wavelets), moving a set from the left and moving it from the right need two different fair measures. They differ by a factor a. The **modular function** records that factor.

**A Haar measure gives every set in a locally compact group a size that does not change when the set is multiplied on the left by any member; it always exists, it is unique up to one scale factor, and where left and right fair sizes differ the modular function measures the gap.**

**What kind of fact this is:** two theorems, existence and uniqueness, stated precisely with their key ideas and a named source (existence in outline in a fold); the four formulas for ℝ, the positive reals, the ax + b group and GL₂(ℝ) are proved on this card in Why it works; the modular function is a definition, made possible by uniqueness.

### The picture: four doublings, two rulers

```
                 ordinary length dx          fair size dx/x
[1, 2]    |#                        1          |######   0.693147
[2, 4]    |##                       2          |######   0.693147
[4, 8]    |####                     4          |######   0.693147
[5, 10]   |#####                    5          |######   0.693147
```

Each line is one doubling. The two columns use different scales: on the left one # is one unit of length, on the right six # stand for 0.693147. Ordinary length grows with where the interval sits. The fair size is the same for all four, because each is a stretched copy of [1, 2].

---

## The formula

Notation first, in words.

- A **group** is a set with one operation, a member $`e`$ that changes nothing, and an undo $`g^{-1}`$ for every member $`g`$ ([Groups](../../03-Algebra/08-Groups/01-groups.md)).
- A **topological group** is a group with a notion of nearness (a topology) in which multiplying and undoing are continuous.
- It is **locally compact** when every member has a neighbourhood whose closure is compact, and two different members always have separate neighbourhoods (Hausdorff) ([Compactness with no distances, and Tychonoff](../../17-Topology/02-Topological%20Spaces/06-compactness-and-tychonoff.md)). On ℝ the compact sets are the closed, bounded ones.
- A **Radon measure** gives finite size to compact sets and is fixed by its values on compact and open sets ([Radon measures and the Riesz representation theorem](../../10-Measure%20and%20integration/11-Derivatives%20Meet%20the%20Lebesgue%20Integral/06-radon-measures-and-riesz-representation.md)).
- For a set $`E`$ and a member $`g`$, $`gE`$ is every point of $`E`$ multiplied by $`g`$ on the left; $`Eg`$ multiplies on the right.

A **left Haar measure** $`\mu`$ (mu) is a Radon measure, not zero, with

```math
\mu(gE) = \mu(E) \quad \text{for every member } g \text{ and every Borel set } E .
```

**Read it aloud:** move any set by any member of the group, from the left, and its size stays the same.

Haar's theorem then says two things:

```math
\text{a left Haar measure } \mu \text{ exists}, \qquad \nu \text{ another one} \;\Rightarrow\; \nu = c\,\mu \text{ for one number } c > 0 .
```

**Read it aloud:** every locally compact group has a fair measure, and any two fair measures differ only by the choice of unit.

The four groups of this card, with $`\lambda`$ for ordinary length, area or volume ([Lebesgue measure](../../10-Measure%20and%20integration/02-Length%20Done%20Properly/03-lebesgue-measure.md)):

| Group | Operation | Left Haar measure | Right Haar measure |
| --- | --- | --- | --- |
| ℝ | $`x + y`$ | $`dx`$ | $`dx`$ |
| positive reals | $`xy`$ | $`dx/x`$ | $`dx/x`$ |
| ax + b group | $`(a,b)(c,d) = (ac,\ ad + b)`$ | $`da\,db/a^2`$ | $`da\,db/a`$ |
| GL₂(ℝ) | matrix product | $`dX/\lvert\det X\rvert^2`$ | $`dX/\lvert\det X\rvert^2`$ |

Here $`(a, b)`$ stands for the map $`t \mapsto at + b`$, and the product $`(a,b)(c,d)`$ is "do $`(c,d)`$, then $`(a,b)`$". GL₂(ℝ) is the group of invertible 2 by 2 real matrices; $`dX`$ is ordinary volume on their four entries.

The **modular function** $`\Delta`$ (capital delta) measures what moving from the right does to a left Haar measure:

```math
\mu(Eg) = \Delta(g)\,\mu(E), \qquad \Delta(a, b) = \frac{1}{a} \text{ on the ax + b group}.
```

**Read it aloud:** moving a set from the right scales its left-fair size by a fixed factor that depends only on the mover.

A group with $`\Delta = 1`$ everywhere is **unimodular**: there, left and right Haar measures agree.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $`G`$, $`e`$ | the group and its do-nothing member | positive reals, $`e = 1`$ | — |
| $`g`$, $`k`$, $`g^{-1}`$ | members used as movers, and the undo of $`g`$ | multiply by 5, then by 1/5 | the set moves further; its fair size stays put |
| $`E`$, $`gE`$, $`Eg`$ | a set whose size is measured; it moved from the left, from the right | [1, 2] and 5 · [1, 2] = [5, 10]; the box [1, 2] × [0, 1] | more points, more size |
| $`\lambda`$, $`dx`$ | ordinary length, area or volume | [5, 10] has length 5 | grows with the stretch factor |
| $`\mu`$ | a left Haar measure | $`dx/x`$: [5, 10] has size 0.693147 | — |
| $`\rho`$ | a right Haar measure (rho) | $`da\,db/a`$: the box has size 0.693147 | — |
| $`\nu`$, $`c`$ | a second Haar measure, and the factor between them | $`\log_{10}`$ sizes, $`c = 1/\ln 10`$ | larger unit, larger sizes |
| $`\Delta(g)`$ | the modular function | $`\Delta(2, 3) = 0.5`$ | further from 1, more lopsided |
| $`(a, b)`$, $`(c, d)`$, $`t`$ | the map $`t \mapsto at + b`$ on a real number $`t`$: stretch $`a > 0`$, shift $`b`$; $`(c, d)`$ a second such map, the mover in Step 3, whose stretch $`c`$ is not the scale factor $`c`$ | $`g = (2, 3)`$ | — |
| $`X`$, $`A`$, $`\det`$ | a 2 by 2 invertible matrix, a mover, the determinant | $`A`$ = `[[2, 1], [0, 1]]`, $`\det A = 2`$ | $`dX`$ grows by $`(\det A)^2`$ |
| $`h`$, $`J_g(x)`$, $`n`$, $`f`$ | a density; the Jacobian determinant of moving by $`g`$, at $`x`$; the number of coordinates; a test function | $`h = 1/x`$, $`J_g = g`$, $`n = 1`$ | larger $`J_g`$, smaller density at $`g`$ |
| $`(K:U)`$, $`K_0`$, $`V_0`$ | Haar's count: least number of moved copies of a small open set $`U`$ covering a compact $`K`$; the yardstick set; its inside | 6932 half-open copies of [1, 1.0001) cover [5, 10]; $`K_0`$ = [1, 10] | smaller $`U`$, larger count |

### When it holds

- **The group is locally compact.** There, a Haar measure gives each point a neighbourhood of finite size: one whose closure is compact. In ℓ², the space of square-summable sequences, no fair measure other than 0 gives any ball a finite size. The unit points $`e_1, e_2, \ldots`$ sit 1.414214 apart, so balls of radius 0.707107 round them never overlap, yet all fit in one ball of radius 1.707107. If that ball had finite size, the infinitely many small balls, all one size by fairness, would each have size 0. Scaled, the same picture works for a ball of any radius. And countably many balls of one radius cover ℓ², centred at the sequences with finitely many nonzero rational entries, so the whole measure would be 0.
- **The measure is Radon.** Counting measure on ℝ (each point weighs 1) is translation invariant too, but it gives the compact set [0, 1] infinite size. Uniqueness is only among Radon measures.
- **Left and right are kept apart.** On the ax + b group the right measure $`da\,db/a`$ is not left invariant: moving the box by $`g = (2, 3)`$ from the left doubles its right size, from 0.693147 to 1.386294.

---

## Why it works

### Step 0: fairness at one point decides everything

A fair measure looks the same near every member, because some mover carries any neighbourhood of $`e`$ onto a neighbourhood of any $`g`$. So the size of one small patch near $`e`$ fixes the size of every moved copy of that patch, near any member. That gives uniqueness, up to the patch's size. Existence asks whether carrying that patch around is consistent; on a group, it is.

### Step 1: the recipe on groups with coordinates

On the four groups here the members are points of an open set in ℝⁿ: n = 1, 1, 2 and 4. Moving by $`g`$ is a smooth map $`x \mapsto gx`$. Look for a fair measure with a density $`h`$: $`\mu(E) = \int_E h(x)\,dx`$.

Change of variables ([Change of variables for Lebesgue measure](../../10-Measure%20and%20integration/06-Product%20Measures%20and%20Fubini/08-lebesgue-change-of-variables-and-polar-coordinates.md)) says a smooth one-to-one map scales small volumes by the size of its Jacobian determinant $`J_g(x)`$, the determinant of its matrix of partial derivatives. So

```math
\mu(gE) = \int_E h(gx)\,\lvert J_g(x)\rvert\,dx .
```

That equals $`\mu(E)`$ for every $`E`$ exactly when $`h(gx)\,\lvert J_g(x)\rvert = h(x)`$. Put $`x = e`$:

```math
h(g) = \frac{h(e)}{\lvert J_g(e)\rvert} .
```

**Read it aloud:** the fair density at $`g`$ is the density at the identity divided by how much moving by $`g`$ stretches a tiny patch at the identity.

The only free choice is $`h(e)`$, the unit. The fold checks that this $`h`$ works at every $`x`$, not only at $`e`$.

<details>
<summary>Detailed proof: the recipe gives a fair measure</summary>

Moving by $`gx`$ is moving by $`x`$, then by $`g`$. By the chain rule, Jacobian determinants multiply along that chain:

$`\displaystyle J_{gx}(e) = J_g(x)\, J_x(e) .`$

Divide $`h(e)`$ by the size of both sides. The left gives $`h(gx)`$ and the right gives $`h(x)/\lvert J_g(x)\rvert`$, so $`h(gx)\,\lvert J_g(x)\rvert = h(x)`$ for every $`g`$ and $`x`$. That is the invariance condition, so $`\mu(gE) = \mu(E)`$.

Conversely, a fair measure with a continuous density must satisfy the condition at $`x = e`$, so its density is this one with some $`h(e)`$. The same argument with $`x \mapsto xg`$ gives the right Haar density.

</details>

### Step 2: the line and the positive reals

On ℝ, moving by $`g`$ is $`x \mapsto g + x`$, with Jacobian 1. So $`h`$ is constant: ordinary length $`dx`$.

On the positive reals, moving by $`g`$ is $`x \mapsto gx`$, with Jacobian $`g`$. So $`h(g) = 1/g`$ with $`h(1) = 1`$. The size of $`[a, b]`$ is

```math
\mu([a,b]) = \int_a^b \frac{dx}{x} = \ln\frac{b}{a}, \qquad \mu([5, 10]) = \ln 2 = 0.693147 .
```

Choosing $`h(1) = 1/\ln 10`$ instead gives sizes in base-10 logarithms: [1, 10] gets size 1 and [1, 2] gets 0.30103. That is the same Haar measure with another unit, $`c = 1/\ln 10`$.

### Step 3: the ax + b group, left and right

The identity is $`(1, 0)`$, the map $`t \mapsto t`$.

- **From the left,** $`g = (c, d)`$ sends $`(a, b)`$ to $`(ca,\ cb + d)`$. Both coordinates stretch by $`c`$, so $`J = c^2`$ and $`h(a, b) = 1/a^2`$.
- **From the right,** $`g = (c, d)`$ sends $`(a, b)`$ to $`(ac,\ ad + b)`$. Its matrix of partial derivatives is `[[c, 0], [d, 1]]`, so $`J = c`$ and the right density is $`1/a`$.

Take the box $`E = [1, 2] \times [0, 1]`$ and the mover $`g = (2, 3)`$:

- $`gE = [2, 4] \times [3, 5]`$, a box.
- $`Eg`$ is the slanted set of points $`(2a,\ 3a + b)`$: each slice at fixed first coordinate $`a'`$ in [2, 4] is an interval of length 1.

The left sizes are $`\int_1^2 da/a^2 = 0.5`$ for $`E`$ and $`2 \times (1/2 - 1/4) = 0.5`$ for $`gE`$. For $`Eg`$ the left size is $`\int_2^4 da/a^2 = 0.25`$. Moving from the right halved it, so $`\Delta(2, 3) = 0.5 = 1/2`$, one over the stretch.

### Step 4: GL₂(ℝ)

Moving by $`A`$ from the left, $`X \mapsto AX`$, is linear on the four entries. It acts on each column of $`X`$ by $`A`$, so its determinant is $`(\det A)^2`$. Step 1 gives $`h(X) = 1/\lvert\det X\rvert^2`$, since $`\det(AX) = \det A \det X`$. Moving from the right acts on each row by $`A`$, with the same determinant, so the right density is the same. GL₂(ℝ) is unimodular even though $`AX`$ and $`XA`$ differ.

### Step 5: existence on every locally compact group

Groups without coordinates, such as infinite products of circles, need another road. Haar's idea is to count. For a compact set $`K`$ and a small open set $`U`$, let $`(K:U)`$ be the least number of left-moved copies $`gU`$ that cover $`K`$. Moving a cover moves it to a cover, so $`(gK:U) = (K:U)`$ exactly.

Fix a yardstick $`K_0`$ and divide: $`(K:U)/(K_0:U)`$. As $`U`$ shrinks, this ratio settles towards the size of $`K`$ in units of $`K_0`$. On the positive reals the code uses half-open copies of $`[1, 1.0001)`$, which line up end to end; open copies of the same size would need at most one more each time, which does not change the limit. [5, 10] needs 6932 copies and [1, 10] needs 23028. The ratio is 0.301025, against the Haar size 0.30103.

<details>
<summary>Existence in outline: from covering counts to a Radon measure</summary>

1. **Bounds.** Let $`V_0`$ be the inside of $`K_0`$, assumed not empty. Cover $`K`$ by $`(K:V_0)`$ copies of $`V_0`$, then each copy by $`(K_0:U)`$ copies of $`U`$. So the ratio never exceeds $`(K:V_0)`$, whatever $`U`$ is: it lies in the closed interval $`[0,\ (K:V_0)]`$.
2. **A limit by Tychonoff.** Put one such interval for every compact $`K`$ and take their product, which is compact by Tychonoff's theorem. The ratios, one point of the product for each $`U`$, have a limit point as $`U`$ shrinks to $`e`$.
3. **Additivity.** In the limit the size is left invariant, monotone and subadditive, and it adds exactly over two compact sets that are a positive gap apart, since a small enough $`U`$ cannot touch both.
4. **A measure.** Such a size on compact sets, a content, extends to a Radon measure through outer measure or the Riesz representation theorem.

Haar did this in 1933 for groups with a countable base of open sets; André Weil removed that condition in 1940. Folland, chapter 2, gives the full proof.

</details>

### Step 6: uniqueness on every locally compact group

The statement: if $`\mu`$ and $`\nu`$ are left Haar measures on $`G`$, then $`\nu = c\,\mu`$ for one $`c > 0`$.

The key idea: integrate a pair of test functions over pairs of points, $`G \times G`$. Fubini's theorem lets the order of integration swap, and each measure's invariance lets a variable be moved. The ratio $`\int f\,d\nu / \int f\,d\mu`$ then comes out the same for every continuous $`f`$ with compact support. Folland proves it in chapter 2. On the four groups here, Step 1 gave it only among measures with a continuous density. On ℝ, [Translation invariance and the Vitali set](../../10-Measure%20and%20integration/02-Length%20Done%20Properly/04-translation-invariance-and-the-vitali-set.md) proves it for every measure on the Borel sets: one that ignores slides and gives [0, 1) size 1 is ordinary length.

### Step 7: the modular function

Left and right moves commute: $`k(Eg) = (kE)g`$. So $`E \mapsto \mu(Eg)`$ is again a left Haar measure. Uniqueness makes it $`\Delta(g)\,\mu`$ for one number $`\Delta(g)`$, which defines $`\Delta`$.

Moving by $`g`$ and then by $`k`$ multiplies the factors, so $`\Delta(gk) = \Delta(g)\,\Delta(k)`$. Weighting $`\mu`$ by $`1/\Delta`$ then gives a right Haar measure:

```math
d\rho(g) = \frac{d\mu(g)}{\Delta(g)}, \qquad \frac{da\,db/a^2}{1/a} = \frac{da\,db}{a} .
```

Three kinds of group are always unimodular:

- **Abelian groups:** left and right moves are the same move.
- **Discrete groups:** counting measure is fair from both sides.
- **Compact groups:** $`\Delta`$ is continuous, so its values form a bounded group of positive numbers, and any number above 1 has powers that grow without bound, so only 1 is left.

The clock ℤ/12 of [Fourier analysis on a finite abelian group](01-fourier-analysis-on-finite-abelian-groups.md) is all three. Its Haar measure, scaled to total 1, gives each hour 0.083333 = 1/12. On the circle it is arc length divided by $`2\pi`$, so a 30-degree arc also gets 0.083333. The $`1/2\pi`$ in the circle's inner product is that choice of unit.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| [1, 2] under dx/x | ln 2 − ln 1 | 0.693147 |
| [5, 10] under dx/x | ln 10 − ln 5 = ln 2 | **0.693147** |
| [5, 10] under dx | 10 − 5 | 5 |
| box E, left size | ∫ from 1 to 2 of da/a², times width 1 | 0.5 |
| gE, left size | ∫ from 2 to 4 of da/a², times width 2 | 0.5 |
| Eg, left size | ∫ from 2 to 4 of da/a², times slice length 1 | 0.25 |
| modular function at g = (2, 3) | 0.25 / 0.5 | **0.5 = 1/a** |
| box E, right size | ∫ from 1 to 2 of da/a | 0.693147 |
| Eg, right size | ∫ from 2 to 4 of da/a, times 1 | 0.693147 |
| GL₂: dX grows under A | (det A)² = 2² | **4** |

The fair size of a doubling is ln 2 wherever it starts, and on the ax + b group moving from the right by a stretch of 2 halves every left size.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Ordinary length on the positive reals | [1, 2] is 1, [5, 10] is 5 | dx is fair for adding, not multiplying |
| Right measure da db/a used for left moves | E is 0.693147, gE is 1.386294 | the right measure is fair from the right only |
| Left measure used for right moves | E is 0.5, Eg is 0.25 | that halving is $`\Delta(2, 3)`$, not an error in the integral |
| Plain dX on GL₂(ℝ) | AE over E is 4.018 by sampling, exactly 4 | the factor $`1/\lvert\det X\rvert^2`$ was dropped |

The code prints every row.

---

## Code, from first principles, and it actually runs

The code finds every size by a closed form and again by brute force, four roads in all. Logarithms come from a series written out, checked once against the library. Intervals on the positive reals are measured by a midpoint rule at 100 and 1,000 cells and by Haar's covering count at three widths. The ax + b sets are measured by counting grid cells, 200 by 1,000, using only a test for "is this point in the set". GL₂(ℝ) sets are measured by 100,000 random samples each, from a SplitMix64 generator with seed 2026, with standard errors printed, and the box of matrices near the identity also by midpoint grids of 16⁴ and 32⁴ cells.

### Python

```python
# Haar measure -- the check behind the card.  Standard library only; math.log
# appears once, as a cross-check labelled 'library'.  Groups: the positive
# reals under multiplication, the ax + b group and GL2(R).  Every size is
# found by a closed form and again by brute force (grids, covers, sampling).
import math

def ln(x):                                   # ln x = 2 atanh((x-1)/(x+1)), summed
    z = (x - 1) / (x + 1)
    s, p = 0.0, z
    for k in range(1, 800, 2):
        s, p = s + p / k, p * z * z
    return 2 * s

def mid(f, a, b, n):                         # midpoint rule with n cells
    h = (b - a) / n
    return h * sum(f(a + (i + 0.5) * h) for i in range(n))

def cover(a, b, eps):                        # Haar's count: slid copies of [1, 1+eps)
    n, x = 0, a
    while x < b:
        x, n = x * (1 + eps), n + 1
    return n

LN2, LN10 = ln(2.0), ln(10.0)
print(f"ln 2 = {LN2:.12f} (library {math.log(2):.12f}); log10 2 = {LN2 / LN10:.6f}")
print("positive reals, ordinary length dx  vs  fair size dx/x")
for a, b in [(1, 2), (2, 4), (4, 8), (5, 10)]:
    print(f"  [{a}, {b}]: dx {b - a}, dx/x closed form {ln(b / a):.6f}, "
          f"midpoint 100 cells {mid(lambda x: 1 / x, a, b, 100):.6f}, 1000 cells {mid(lambda x: 1 / x, a, b, 1000):.9f}")
for eps in [0.01, 0.001, 0.0001]:
    c12, c510, c110 = cover(1, 2, eps), cover(5, 10, eps), cover(1, 10, eps)
    print(f"  cover by [g, g(1+{eps})): [1,2] needs {c12}, [5,10] needs {c510}, [1,10] needs {c110}; ratio {c510 / c110:.6f}")
digits = [0] * 10                            # leading digits of 2^1 .. 2^1000, exact
p = 1
for k in range(1, 1001):
    p *= 2
    digits[int(str(p)[0])] += 1
frac_road = sum(1 for k in range(1, 1001) if (k * LN2 / LN10) % 1 < LN2 / LN10)
print(f"Benford: 2^1..2^1000 starting with 1: {digits[1]} by digits, {frac_road} by k log10 2 mod 1; Haar share {LN2 / LN10:.5f}")

def grid(dens, inside, a0, a1, b0, b1, n, m):   # brute force: count cells of a box
    ha, hb, tot = (a1 - a0) / n, (b1 - b0) / m, 0.0
    for i in range(n):
        a = a0 + (i + 0.5) * ha
        cnt = sum(1 for j in range(m) if inside(a, b0 + (j + 0.5) * hb))
        tot += dens(a) * cnt * hb * ha
    return tot

inE = lambda a, b: 1 <= a <= 2 and 0 <= b <= 1           # E = [1,2] x [0,1]; g = (2, 3)
in_gE = lambda a, b: inE(a / 2, (b - 3) / 2)             # g*(a,b) = (2a, 2b + 3)
in_Eg = lambda a, b: inE(a / 2, b - 1.5 * a)             # (a,b)*g = (2a, 3a + b)
left, right = (lambda a: 1 / (a * a)), (lambda a: 1 / a)
closed = {"E": (0.5, LN2), "gE": (0.5, 2 * LN2), "Eg": (0.25, LN2)}
boxes = {"E": (inE, 1, 2, 0, 1), "gE": (in_gE, 2, 4, 3, 5), "Eg": (in_Eg, 2, 4, 3, 7)}
print("ax + b group, (a,b)(c,d) = (ac, ad + b), E = [1,2] x [0,1], g = (2, 3)")
brute = {}
for name, (ins, a0, a1, b0, b1) in boxes.items():
    L = grid(left, ins, a0, a1, b0, b1, 200, 1000)
    R = grid(right, ins, a0, a1, b0, b1, 200, 1000)
    brute[name] = (L, R)
    print(f"  {name:2}: left da db/a^2 = {closed[name][0]:.6f} (grid {L:.5f}),"
          f" right da db/a = {closed[name][1]:.6f} (grid {R:.5f})")
delta = brute["Eg"][0] / brute["E"][0]
print(f"  modular function at g: left size of Eg over E = {delta:.4f}; 1/a = {1 / 2:.4f}")

class Mix:                                   # SplitMix64, seed stated, written out
    def __init__(s, seed): s.x = seed
    def u(s):
        s.x = (s.x + 0x9E3779B97F4A7C15) & (2**64 - 1)
        z = s.x
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & (2**64 - 1)
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & (2**64 - 1)
        return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53

def inBox(X):                                # E: entries within 0.1 of the identity
    return abs(X[0] - 1) <= 0.1 and abs(X[1]) <= 0.1 and abs(X[2]) <= 0.1 and abs(X[3] - 1) <= 0.1

def sample(inside, lo, hi, n, rng):          # Monte Carlo of dX/|det X|^2 and of dX
    vol, s, s2, hits = 1.0, 0.0, 0.0, 0
    for k in range(4): vol *= hi[k] - lo[k]
    for _ in range(n):
        Y = [lo[k] + (hi[k] - lo[k]) * rng.u() for k in range(4)]
        if inside(Y):
            d = Y[0] * Y[3] - Y[1] * Y[2]
            w = 1 / (d * d)
            s, s2, hits = s + w, s2 + w * w, hits + 1
    mean, msq = s / n, s2 / n
    return vol * mean, vol * math.sqrt((msq - mean * mean) / n), vol * hits / n

# A = [[2, 1], [0, 1]], det 2.  X is stored as [x11, x12, x21, x22].
in_AE = lambda Y: inBox([(Y[0] - Y[2]) / 2, (Y[1] - Y[3]) / 2, Y[2], Y[3]])
in_EA = lambda Y: inBox([Y[0] / 2, Y[1] - Y[0] / 2, Y[2] / 2, Y[3] - Y[2] / 2])
def nu_grid(g):                              # 4-D midpoint grid on E, g cells a side
    h, tot = 0.2 / g, 0.0
    for i in range(g ** 4):
        q = [((i // g ** k) % g + 0.5) * h - 0.1 for k in range(4)]
        d = (1 + q[0]) * (1 + q[3]) - q[1] * q[2]
        tot += h * h * h * h / (d * d)
    return tot

nu16, nuE_grid = nu_grid(16), nu_grid(32)                # second cut-off: 32^4 cells
rng = Mix(2026)
runs = {"E": sample(inBox, [0.9, -0.1, -0.1, 0.9], [1.1, 0.1, 0.1, 1.1], 100000, rng),
        "AE": sample(in_AE, [1.7, 0.7, -0.1, 0.9], [2.3, 1.3, 0.1, 1.1], 100000, rng),
        "EA": sample(in_EA, [1.8, 0.8, -0.2, 0.8], [2.2, 1.2, 0.2, 1.2], 100000, rng)}
print(f"GL2(R), A = [[2, 1], [0, 1]], det A = 2; E = matrices within 0.1 of I, dX-volume {0.2 * 0.2 * 0.2 * 0.2:.4f}")
print(f"  E : dX/|det X|^2 by midpoint grid, 16^4 cells {nu16:.7f}, 32^4 cells {nuE_grid:.7f}")
for name, (nu, se, vol) in runs.items():
    print(f"  {name:2}: dX/|det X|^2 = {nu:.7f} +- {se:.7f} (100000 samples), plain dX = {vol:.7f}")
print(f"  plain dX ratio AE/E = {runs['AE'][2] / runs['E'][2]:.3f}; |det A|^2 = 4")
print(f"clock Z/12: each hour {1 / 12:.6f}; circle d(theta)/2pi: a 30-degree arc {30 / 360:.6f}")
print(f"l2, not locally compact: |e1 - e2| = {math.sqrt(2):.6f}, so balls of radius {math.sqrt(2) / 2:.6f} "
      f"round every e_k are disjoint inside one ball of radius {1 + math.sqrt(2) / 2:.6f}")
assert abs(LN2 - math.log(2)) < 1e-12 and abs(LN10 - math.log(10)) < 1e-12
assert all(abs(mid(lambda x: 1 / x, a, b, 1000) - LN2) < 1e-6 for a, b in [(1, 2), (5, 10)])
assert cover(1, 2, 1e-4) == cover(5, 10, 1e-4) and abs(cover(5, 10, 1e-4) / cover(1, 10, 1e-4) - LN2 / LN10) < 1e-4
assert digits[1] == frac_road == 301
for name in closed:                                       # grid against closed form
    assert abs(brute[name][0] - closed[name][0]) < 0.01 * closed[name][0]
    assert abs(brute[name][1] - closed[name][1]) < 0.01 * closed[name][1]
assert abs(delta - 0.5) < 0.01
assert abs(runs["E"][0] - nuE_grid) < 4 * runs["E"][1]
for name in ["AE", "EA"]:                                 # invariance, within 4 standard errors
    assert abs(runs[name][0] - nuE_grid) < 4 * runs[name][1]
assert abs(runs["AE"][2] / runs["E"][2] - 4) < 0.05
print("ALL CHECKS PASS")
```

**Ran 2026-11-24 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
ln 2 = 0.693147180560 (library 0.693147180560); log10 2 = 0.301030
positive reals, ordinary length dx  vs  fair size dx/x
  [1, 2]: dx 1, dx/x closed form 0.693147, midpoint 100 cells 0.693144, 1000 cells 0.693147149
  [2, 4]: dx 2, dx/x closed form 0.693147, midpoint 100 cells 0.693144, 1000 cells 0.693147149
  [4, 8]: dx 4, dx/x closed form 0.693147, midpoint 100 cells 0.693144, 1000 cells 0.693147149
  [5, 10]: dx 5, dx/x closed form 0.693147, midpoint 100 cells 0.693144, 1000 cells 0.693147149
  cover by [g, g(1+0.01)): [1,2] needs 70, [5,10] needs 70, [1,10] needs 232; ratio 0.301724
  cover by [g, g(1+0.001)): [1,2] needs 694, [5,10] needs 694, [1,10] needs 2304; ratio 0.301215
  cover by [g, g(1+0.0001)): [1,2] needs 6932, [5,10] needs 6932, [1,10] needs 23028; ratio 0.301025
Benford: 2^1..2^1000 starting with 1: 301 by digits, 301 by k log10 2 mod 1; Haar share 0.30103
ax + b group, (a,b)(c,d) = (ac, ad + b), E = [1,2] x [0,1], g = (2, 3)
  E : left da db/a^2 = 0.500000 (grid 0.50000), right da db/a = 0.693147 (grid 0.69315)
  gE: left da db/a^2 = 0.500000 (grid 0.50000), right da db/a = 1.386294 (grid 1.38629)
  Eg: left da db/a^2 = 0.250000 (grid 0.25000), right da db/a = 0.693147 (grid 0.69315)
  modular function at g: left size of Eg over E = 0.5000; 1/a = 0.5000
GL2(R), A = [[2, 1], [0, 1]], det A = 2; E = matrices within 0.1 of I, dX-volume 0.0016
  E : dX/|det X|^2 by midpoint grid, 16^4 cells 0.0016324, 32^4 cells 0.0016325
  E : dX/|det X|^2 = 0.0016324 +- 0.0000009 (100000 samples), plain dX = 0.0016000
  AE: dX/|det X|^2 = 0.0016368 +- 0.0000059 (100000 samples), plain dX = 0.0064290
  EA: dX/|det X|^2 = 0.0016361 +- 0.0000091 (100000 samples), plain dX = 0.0064192
  plain dX ratio AE/E = 4.018; |det A|^2 = 4
clock Z/12: each hour 0.083333; circle d(theta)/2pi: a 30-degree arc 0.083333
l2, not locally compact: |e1 - e2| = 1.414214, so balls of radius 0.707107 round every e_k are disjoint inside one ball of radius 1.707107
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Haar measure -- the same check as the Python, in Rust.  No crates; f64::ln
// appears once, as a cross-check labelled 'library'.  Groups: the positive
// reals under multiplication, the ax + b group and GL2(R).  Every size is
// found by a closed form and again by brute force (grids, covers, sampling).
fn ln(x: f64) -> f64 {                       // ln x = 2 atanh((x-1)/(x+1)), summed
    let z = (x - 1.0) / (x + 1.0);
    let (mut s, mut p) = (0.0, z);
    for k in (1..800).step_by(2) { s += p / k as f64; p = p * z * z; }
    2.0 * s
}

fn mid(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {   // midpoint rule
    let h = (b - a) / n as f64;
    let mut s = 0.0;
    for i in 0..n { s += f(a + (i as f64 + 0.5) * h); }
    h * s
}

fn cover(a: f64, b: f64, eps: f64) -> usize {   // Haar's count: slid copies of [1, 1+eps)
    let (mut n, mut x) = (0, a);
    while x < b { x *= 1.0 + eps; n += 1; }
    n
}

fn grid(dens: &dyn Fn(f64) -> f64, inside: &dyn Fn(f64, f64) -> bool,
        a0: f64, a1: f64, b0: f64, b1: f64, n: usize, m: usize) -> f64 {   // count cells
    let (ha, hb) = ((a1 - a0) / n as f64, (b1 - b0) / m as f64);
    let mut tot = 0.0;
    for i in 0..n {
        let a = a0 + (i as f64 + 0.5) * ha;
        let cnt = (0..m).filter(|&j| inside(a, b0 + (j as f64 + 0.5) * hb)).count();
        tot += dens(a) * cnt as f64 * hb * ha;
    }
    tot
}

fn in_e(a: f64, b: f64) -> bool { 1.0 <= a && a <= 2.0 && 0.0 <= b && b <= 1.0 }

struct Mix(u64);                             // SplitMix64, seed stated, written out
impl Mix {
    fn u(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * (2.0f64).powi(-53)
    }
}

fn in_box(x: [f64; 4]) -> bool {             // E: entries within 0.1 of the identity
    (x[0] - 1.0).abs() <= 0.1 && x[1].abs() <= 0.1 && x[2].abs() <= 0.1 && (x[3] - 1.0).abs() <= 0.1
}

fn nu_grid(g: usize) -> f64 {                // 4-D midpoint grid on E, g cells a side
    let (h, mut tot) = (0.2 / g as f64, 0.0);
    for i in 0..g.pow(4) {
        let mut q = [0.0; 4];
        for k in 0..4 { q[k] = (((i / g.pow(k as u32)) % g) as f64 + 0.5) * h - 0.1; }
        let d = (1.0 + q[0]) * (1.0 + q[3]) - q[1] * q[2];
        tot += h * h * h * h / (d * d);
    }
    tot
}

fn sample(inside: &dyn Fn([f64; 4]) -> bool, lo: [f64; 4], hi: [f64; 4], n: usize, rng: &mut Mix)
    -> (f64, f64, f64) {                     // Monte Carlo of dX/|det X|^2 and of dX
    let (mut vol, mut s, mut s2, mut hits) = (1.0, 0.0, 0.0, 0usize);
    for k in 0..4 { vol *= hi[k] - lo[k]; }
    for _ in 0..n {
        let mut y = [0.0; 4];
        for k in 0..4 { y[k] = lo[k] + (hi[k] - lo[k]) * rng.u(); }
        if inside(y) {
            let d = y[0] * y[3] - y[1] * y[2];
            let w = 1.0 / (d * d);
            s += w; s2 += w * w; hits += 1;
        }
    }
    let (mean, msq) = (s / n as f64, s2 / n as f64);
    (vol * mean, vol * ((msq - mean * mean) / n as f64).sqrt(), vol * hits as f64 / n as f64)
}

fn main() {
    let (ln2, ln10) = (ln(2.0), ln(10.0));
    let recip = |x: f64| 1.0 / x;
    println!("ln 2 = {:.12} (library {:.12}); log10 2 = {:.6}", ln2, 2f64.ln(), ln2 / ln10);
    println!("positive reals, ordinary length dx  vs  fair size dx/x");
    for (a, b) in [(1, 2), (2, 4), (4, 8), (5, 10)] {
        let (fa, fb) = (a as f64, b as f64);
        println!("  [{}, {}]: dx {}, dx/x closed form {:.6}, midpoint 100 cells {:.6}, 1000 cells {:.9}",
                 a, b, b - a, ln(fb / fa), mid(&recip, fa, fb, 100), mid(&recip, fa, fb, 1000));
    }
    for eps in [0.01, 0.001, 0.0001] {
        let (c12, c510, c110) = (cover(1.0, 2.0, eps), cover(5.0, 10.0, eps), cover(1.0, 10.0, eps));
        println!("  cover by [g, g(1+{})): [1,2] needs {}, [5,10] needs {}, [1,10] needs {}; ratio {:.6}",
                 eps, c12, c510, c110, c510 as f64 / c110 as f64);
    }
    let mut digits = [0usize; 10];                  // leading digits of 2^1 .. 2^1000, exact
    let mut p: Vec<u8> = vec![1];                   // decimal digits, lowest first
    for _ in 1..=1000 {
        let mut carry = 0;
        for d in p.iter_mut() { let v = *d * 2 + carry; *d = v % 10; carry = v / 10; }
        if carry > 0 { p.push(carry); }
        digits[*p.last().unwrap() as usize] += 1;
    }
    let frac_road = (1..=1000).filter(|&k| (k as f64 * ln2 / ln10) % 1.0 < ln2 / ln10).count();
    println!("Benford: 2^1..2^1000 starting with 1: {} by digits, {} by k log10 2 mod 1; Haar share {:.5}",
             digits[1], frac_road, ln2 / ln10);

    let in_ge = |a: f64, b: f64| in_e(a / 2.0, (b - 3.0) / 2.0);   // g*(a,b) = (2a, 2b + 3)
    let in_eg = |a: f64, b: f64| in_e(a / 2.0, b - 1.5 * a);       // (a,b)*g = (2a, 3a + b)
    let left = |a: f64| 1.0 / (a * a);
    let names = ["E", "gE", "Eg"];
    let closed = [(0.5, ln2), (0.5, 2.0 * ln2), (0.25, ln2)];
    let boxes: [(&dyn Fn(f64, f64) -> bool, f64, f64, f64, f64); 3] =
        [(&in_e, 1.0, 2.0, 0.0, 1.0), (&in_ge, 2.0, 4.0, 3.0, 5.0), (&in_eg, 2.0, 4.0, 3.0, 7.0)];
    println!("ax + b group, (a,b)(c,d) = (ac, ad + b), E = [1,2] x [0,1], g = (2, 3)");
    let mut brute = [(0.0, 0.0); 3];
    for i in 0..3 {
        let (ins, a0, a1, b0, b1) = boxes[i];
        let l = grid(&left, ins, a0, a1, b0, b1, 200, 1000);
        let r = grid(&recip, ins, a0, a1, b0, b1, 200, 1000);
        brute[i] = (l, r);
        println!("  {:2}: left da db/a^2 = {:.6} (grid {:.5}), right da db/a = {:.6} (grid {:.5})",
                 names[i], closed[i].0, l, closed[i].1, r);
    }
    let delta = brute[2].0 / brute[0].0;
    println!("  modular function at g: left size of Eg over E = {:.4}; 1/a = {:.4}", delta, 1.0 / 2.0);

    // A = [[2, 1], [0, 1]], det 2.  X is stored as [x11, x12, x21, x22].
    let in_ae = |y: [f64; 4]| in_box([(y[0] - y[2]) / 2.0, (y[1] - y[3]) / 2.0, y[2], y[3]]);
    let in_ea = |y: [f64; 4]| in_box([y[0] / 2.0, y[1] - y[0] / 2.0, y[2] / 2.0, y[3] - y[2] / 2.0]);
    let (nu16, nue_grid) = (nu_grid(16), nu_grid(32));             // second cut-off: 32^4 cells
    let mut rng = Mix(2026);
    let run_e = sample(&in_box, [0.9, -0.1, -0.1, 0.9], [1.1, 0.1, 0.1, 1.1], 100000, &mut rng);
    let run_ae = sample(&in_ae, [1.7, 0.7, -0.1, 0.9], [2.3, 1.3, 0.1, 1.1], 100000, &mut rng);
    let run_ea = sample(&in_ea, [1.8, 0.8, -0.2, 0.8], [2.2, 1.2, 0.2, 1.2], 100000, &mut rng);
    println!("GL2(R), A = [[2, 1], [0, 1]], det A = 2; E = matrices within 0.1 of I, dX-volume {:.4}",
             0.2 * 0.2 * 0.2 * 0.2);
    println!("  E : dX/|det X|^2 by midpoint grid, 16^4 cells {:.7}, 32^4 cells {:.7}", nu16, nue_grid);
    for (name, (nu, se, vol)) in [("E", run_e), ("AE", run_ae), ("EA", run_ea)] {
        println!("  {:2}: dX/|det X|^2 = {:.7} +- {:.7} (100000 samples), plain dX = {:.7}", name, nu, se, vol);
    }
    println!("  plain dX ratio AE/E = {:.3}; |det A|^2 = 4", run_ae.2 / run_e.2);
    println!("clock Z/12: each hour {:.6}; circle d(theta)/2pi: a 30-degree arc {:.6}", 1.0 / 12.0, 30.0 / 360.0);
    let r2 = 2f64.sqrt();
    println!("l2, not locally compact: |e1 - e2| = {:.6}, so balls of radius {:.6} round every e_k are disjoint inside one ball of radius {:.6}",
             r2, r2 / 2.0, 1.0 + r2 / 2.0);
    assert!((ln2 - 2f64.ln()).abs() < 1e-12 && (ln10 - 10f64.ln()).abs() < 1e-12);
    assert!([(1.0, 2.0), (5.0, 10.0)].iter().all(|&(a, b)| (mid(&recip, a, b, 1000) - ln2).abs() < 1e-6));
    assert!(cover(1.0, 2.0, 1e-4) == cover(5.0, 10.0, 1e-4));
    assert!((cover(5.0, 10.0, 1e-4) as f64 / cover(1.0, 10.0, 1e-4) as f64 - ln2 / ln10).abs() < 1e-4);
    assert!(digits[1] == frac_road && frac_road == 301);
    for i in 0..3 {                                         // grid against closed form
        assert!((brute[i].0 - closed[i].0).abs() < 0.01 * closed[i].0);
        assert!((brute[i].1 - closed[i].1).abs() < 0.01 * closed[i].1);
    }
    assert!((delta - 0.5).abs() < 0.01);
    assert!((run_e.0 - nue_grid).abs() < 4.0 * run_e.1);
    for run in [run_ae, run_ea] {                           // invariance, within 4 standard errors
        assert!((run.0 - nue_grid).abs() < 4.0 * run.1);
    }
    assert!((run_ae.2 / run_e.2 - 4.0).abs() < 0.05);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-24 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
ln 2 = 0.693147180560 (library 0.693147180560); log10 2 = 0.301030
positive reals, ordinary length dx  vs  fair size dx/x
  [1, 2]: dx 1, dx/x closed form 0.693147, midpoint 100 cells 0.693144, 1000 cells 0.693147149
  [2, 4]: dx 2, dx/x closed form 0.693147, midpoint 100 cells 0.693144, 1000 cells 0.693147149
  [4, 8]: dx 4, dx/x closed form 0.693147, midpoint 100 cells 0.693144, 1000 cells 0.693147149
  [5, 10]: dx 5, dx/x closed form 0.693147, midpoint 100 cells 0.693144, 1000 cells 0.693147149
  cover by [g, g(1+0.01)): [1,2] needs 70, [5,10] needs 70, [1,10] needs 232; ratio 0.301724
  cover by [g, g(1+0.001)): [1,2] needs 694, [5,10] needs 694, [1,10] needs 2304; ratio 0.301215
  cover by [g, g(1+0.0001)): [1,2] needs 6932, [5,10] needs 6932, [1,10] needs 23028; ratio 0.301025
Benford: 2^1..2^1000 starting with 1: 301 by digits, 301 by k log10 2 mod 1; Haar share 0.30103
ax + b group, (a,b)(c,d) = (ac, ad + b), E = [1,2] x [0,1], g = (2, 3)
  E : left da db/a^2 = 0.500000 (grid 0.50000), right da db/a = 0.693147 (grid 0.69315)
  gE: left da db/a^2 = 0.500000 (grid 0.50000), right da db/a = 1.386294 (grid 1.38629)
  Eg: left da db/a^2 = 0.250000 (grid 0.25000), right da db/a = 0.693147 (grid 0.69315)
  modular function at g: left size of Eg over E = 0.5000; 1/a = 0.5000
GL2(R), A = [[2, 1], [0, 1]], det A = 2; E = matrices within 0.1 of I, dX-volume 0.0016
  E : dX/|det X|^2 by midpoint grid, 16^4 cells 0.0016324, 32^4 cells 0.0016325
  E : dX/|det X|^2 = 0.0016324 +- 0.0000009 (100000 samples), plain dX = 0.0016000
  AE: dX/|det X|^2 = 0.0016368 +- 0.0000059 (100000 samples), plain dX = 0.0064290
  EA: dX/|det X|^2 = 0.0016361 +- 0.0000091 (100000 samples), plain dX = 0.0064192
  plain dX ratio AE/E = 4.018; |det A|^2 = 4
clock Z/12: each hour 0.083333; circle d(theta)/2pi: a 30-degree arc 0.083333
l2, not locally compact: |e1 - e2| = 1.414214, so balls of radius 0.707107 round every e_k are disjoint inside one ball of radius 1.707107
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves Haar's theorem and the modular function for every locally compact group, and the $`dx/x`$ sizes on the positive reals.

- Take any locally compact group. Then it has a left Haar measure, Radon and not zero.
- Suppose $`\mu`$ and $`\nu`$ are left Haar measures on one group. Then $`\nu = c\,\mu`$ for one number $`c > 0`$.
- Take any locally compact group. Then it has a modular function $`\Delta`$, every value above 0, with $`\Delta(gk) = \Delta(g)\,\Delta(k)`$.
- Suppose $`\mu`$ is any left Haar measure and $`g`$ any member. Then $`\mu(Eg) = \Delta(g)\,\mu(E)`$ for every Borel set $`E`$.
- Suppose $`g > 0`$. Then stretching any Borel set of positive reals by $`g`$ keeps its $`dx/x`$ size.
- Suppose $`0 < a \le b`$. Then $`[a, b]`$ has $`dx/x`$ size $`\ln(b/a)`$.
- Lean also checks the worked arithmetic, such as $`\Delta(2, 3) = 1/2`$ and $`(\det A)^2 = 4`$.

The ax + b and GL₂(ℝ) sizes, the covering counts and every decimal are left to the Python and Rust checks.

```lean
-- Haar measure: every locally compact group has a left Haar measure, unique up to one scale factor, with a modular function for right moves, and dx/x is the fair measure on the positive reals.
import Mathlib.MeasureTheory.Group.ModularCharacter
import Mathlib.MeasureTheory.Measure.WithDensity
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.MeasureTheory.Function.JacobianOneDim

open MeasureTheory Measure Set
open scoped NNReal ENNReal

namespace HaarMeasureCard

/-- **Haar's theorem.** On a locally compact (Hausdorff) topological group, with its Borel
sets, a left Haar measure exists: a nonzero Radon measure `μ` with `μ (g E) = μ E` for every
member `g` and Borel set `E`. In Mathlib's terms this is `IsHaarMeasure μ` (finite on compact
sets, left invariant, positive on nonempty open sets) together with `μ.Regular` (Radon). And
any two left Haar measures differ only by the choice of unit: `ν = c • μ` for one `c > 0`. -/
theorem left_haar_measure_exists_unique
    (G : Type*) [Group G] [TopologicalSpace G] [IsTopologicalGroup G]
    [LocallyCompactSpace G] [T2Space G] [MeasurableSpace G] [BorelSpace G] :
    (∃ μ : Measure G, IsHaarMeasure μ ∧ μ.Regular) ∧
    ∀ μ ν : Measure G, IsHaarMeasure μ → μ.Regular → IsHaarMeasure ν → ν.Regular →
      ∃ c : ℝ≥0, 0 < c ∧ ν = c • μ := by
  refine ⟨⟨haarMeasure (Classical.arbitrary (TopologicalSpace.PositiveCompacts G)),
    inferInstance, inferInstance⟩, ?_⟩
  intro μ ν hμ hμr hν hνr
  exact ⟨haarScalarFactor ν μ, haarScalarFactor_pos_of_isHaarMeasure ν μ,
    isMulLeftInvariant_eq_smul_of_regular ν μ⟩

/-- **The modular function.** On a locally compact group there is one multiplicative map
`Δ : G → (0, ∞)` such that moving a set from the right by `g` scales every left Haar measure
by `Δ g`: `μ (E g) = Δ g * μ E` for every left Haar (Radon) measure `μ` and Borel set `E`.
It satisfies `Δ (g k) = Δ g * Δ k`, and it does not depend on which Haar measure is used. -/
theorem modular_function_exists
    (G : Type*) [Group G] [TopologicalSpace G] [IsTopologicalGroup G]
    [LocallyCompactSpace G] [T2Space G] [MeasurableSpace G] [BorelSpace G] :
    ∃ Δ : G →* ℝ≥0, (∀ g, 0 < Δ g) ∧
      ∀ μ : Measure G, IsHaarMeasure μ → μ.Regular →
        ∀ (g : G) (E : Set G), MeasurableSet E →
          μ ((fun x => x * g) '' E) = (Δ g : ℝ≥0∞) * μ E := by
  let Δ : G →* ℝ≥0 :=
    { toFun := fun g => modularCharacter g⁻¹
      map_one' := by simp
      map_mul' := fun g k => by simp [mul_inv_rev, map_mul, mul_comm] }
  refine ⟨Δ, fun g => modularCharacterFun_pos g⁻¹, ?_⟩
  intro μ hμ hμr g E hE
  have hreg : (map (· * g⁻¹) μ).Regular := by
    have := Regular.map (μ := μ) (Homeomorph.mulRight g⁻¹)
    simpa using this
  have h1 : map (· * g⁻¹) μ = haarScalarFactor (map (· * g⁻¹) μ) μ • μ :=
    isMulLeftInvariant_eq_smul_of_regular _ _
  have h2 : modularCharacterFun g⁻¹ = haarScalarFactor (map (· * g⁻¹) μ) μ :=
    modularCharacterFun_eq_haarScalarFactor μ g⁻¹
  have h3 : (fun x => x * g) '' E = (· * g⁻¹) ⁻¹' E := Set.image_mul_right
  rw [h3, ← map_apply (measurable_mul_const g⁻¹) hE, h1]
  show _ = ((modularCharacterFun g⁻¹ : ℝ≥0) : ℝ≥0∞) * μ E
  rw [h2]
  rfl

/-- **The positive reals.** The measure `dx/x` (Lebesgue measure with density `1/x`) is fair
under multiplication: stretching any Borel set of positive reals by a factor `g > 0` keeps its
size, and the interval `[a, b]` with `0 < a ≤ b` has size `ln (b / a)`. -/
theorem dx_div_x_mul_invariant_and_interval :
    let μ : Measure ℝ := volume.withDensity (fun x => ENNReal.ofReal x⁻¹)
    (∀ g : ℝ, 0 < g → ∀ E : Set ℝ, MeasurableSet E → E ⊆ Ioi 0 →
        μ ((fun x => g * x) '' E) = μ E) ∧
    (∀ a b : ℝ, 0 < a → a ≤ b → μ (Icc a b) = ENNReal.ofReal (Real.log (b / a))) := by
  intro μ
  refine ⟨?_, ?_⟩
  · intro g hg E hE _
    have himg : MeasurableSet ((fun x => g * x) '' E) := by
      have : (fun x => g * x) '' E = (fun x => g⁻¹ * x) ⁻¹' E := by
        ext y; constructor
        · rintro ⟨x, hx, rfl⟩; simpa [← mul_assoc, inv_mul_cancel₀ hg.ne'] using hx
        · intro hy; exact ⟨g⁻¹ * y, hy, by simp [← mul_assoc, mul_inv_cancel₀ hg.ne']⟩
      rw [this]; exact (measurable_const_mul g⁻¹) hE
    simp only [μ, withDensity_apply _ himg, withDensity_apply _ hE]
    have hd : ∀ x ∈ E, HasDerivWithinAt (fun x => g * x) g E x := fun x _ => by
      simpa using ((hasDerivAt_id x).const_mul g).hasDerivWithinAt
    rw [lintegral_image_eq_lintegral_abs_deriv_mul hE hd
      (fun x _ y _ h => mul_left_cancel₀ hg.ne' h)]
    congr 1
    funext x
    rw [abs_of_pos hg, ← ENNReal.ofReal_mul hg.le, mul_inv, ← mul_assoc,
      mul_inv_cancel₀ hg.ne', one_mul]
  · intro a b ha hab
    simp only [μ, withDensity_apply _ measurableSet_Icc]
    have hcont : ContinuousOn (fun x : ℝ => x⁻¹) (Icc a b) :=
      continuousOn_inv₀.mono (fun x hx => (ha.trans_le hx.1).ne')
    have hint : IntegrableOn (fun x : ℝ => x⁻¹) (Icc a b) := hcont.integrableOn_Icc
    rw [← ofReal_integral_eq_lintegral_ofReal hint]
    · rw [integral_Icc_eq_integral_Ioc, ← intervalIntegral.integral_of_le hab,
        integral_inv_of_pos ha (ha.trans_le hab)]
    · filter_upwards [ae_restrict_mem measurableSet_Icc] with x hx
      exact inv_nonneg.mpr (ha.le.trans hx.1)

-- The card's worked examples, in exact arithmetic.
-- [1, 2] and [5, 10] have the same fair size: ln (10 / 5) = ln (2 / 1).
example : Real.log (10 / 5) = Real.log (2 / 1) := by norm_num
-- ax + b group, E = [1,2] × [0,1], g = (2, 3): left size of E is 1 - 1/2,
-- of gE is 2 × (1/2 - 1/4), of Eg is 1/2 - 1/4; so Δ(2, 3) = (1/4) / (1/2) = 1/2.
example : (1 : ℚ) - 1 / 2 = 1 / 2 := by norm_num
example : (2 : ℚ) * (1 / 2 - 1 / 4) = 1 / 2 := by norm_num
example : ((1 : ℚ) / 2 - 1 / 4) / (1 / 2) = 1 / 2 := by norm_num
-- GL₂(ℝ): A = [[2, 1], [0, 1]] has det A = 2, so plain volume dX grows by (det A)² = 4.
example : Matrix.det !![(2 : ℤ), 1; 0, 1] = 2 := by norm_num [Matrix.det_fin_two]
example : (Matrix.det !![(2 : ℤ), 1; 0, 1]) ^ 2 = 4 := by norm_num [Matrix.det_fin_two]
-- The clock ℤ/12, Haar measure of total 1: each hour gets 1/12, and a 30-degree arc
-- of the circle gets 30/360 = 1/12.
example : (12 : ℚ) * (1 / 12) = 1 := by norm_num
example : (30 : ℚ) / 360 = 1 / 12 := by norm_num

#print axioms left_haar_measure_exists_unique
#print axioms modular_function_exists
#print axioms dx_div_x_mul_invariant_and_interval

end HaarMeasureCard
```

**Checked 2026-11-24 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'HaarMeasureCard.left_haar_measure_exists_unique' depends on axioms: [propext, Classical.choice, Quot.sound]
'HaarMeasureCard.modular_function_exists' depends on axioms: [propext, Classical.choice, Quot.sound]
'HaarMeasureCard.dx_div_x_mul_invariant_and_interval' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> - Guess first: what does the left size of $`Eg`$ become for the mover $`g = (4, 3)`$? Change `in_Eg` to `inE(a / 4, b - 0.75 * a)` and its box to `(in_Eg, 4, 8, 3, 7)`. The grid prints 0.12500, so $`\Delta = 0.25 = 1/4`$, and the assert pinned to 0.25 stops the run.
> - Guess first: is the right measure fair from the left? Swap `left` and `right` in the `grid` calls. The asserts stop it, since gE's left column now reads 1.38629 where 0.5 was expected.
> - Guess first: does invariance survive new random numbers? Change the seed `Mix(2026)` to `Mix(7)`. The sampled sizes of AE and EA move to 0.0016379 and 0.0016251, still within four standard errors of the 32⁴ grid's 0.0016325, and every assert passes.
> - Guess first: how fine must the covering be? Put 0.1 in the list of widths. [5, 10] needs 8 copies and [1, 10] needs 25, a ratio of 0.320000 against 0.30103: coarse copies overshoot.

---

## The usual mistake

> [!warning]
> **Assuming the left Haar measure is also fair from the right.** On the ax + b group the left measure $`da\,db/a^2`$ gives the box $`E`$ size 0.5 and its right-moved copy $`Eg`$ size 0.25. Formulas that move variables from the right, such as convolution on a non-commutative group, need the factor $`\Delta`$.
>
> - **Ordinary length on a multiplicative group.** It gives [5, 10] size 5 and [1, 2] size 1, though one is a stretched copy of the other; the fair sizes are both 0.693147.
> - **Forgetting the determinant on GL₂(ℝ).** Plain volume grows by $`(\det A)^2 = 4`$ under $`X \mapsto AX`$; only $`dX/\lvert\det X\rvert^2`$ stays put, at 0.0016325 for the box of matrices within 0.1 of the identity.
> - **Treating "the" Haar measure as one measure.** It is unique only up to a unit: natural logs give [1, 2] size 0.693147, base-10 logs 0.30103. Total 1 is a natural unit only on a compact group.

---

## Where you meet it in real life

- **Leading digits (Benford's law).** Quantities spread over many scales tend to have leading digits distributed by the fair size on the positive reals. The share starting with 1 is $`\log_{10} 2`$ = 0.30103. Of the first 1,000 powers of 2, exactly 301 start with a 1.
- **Wavelets.** The [Continuous wavelet transform](../05-Wavelets%20and%20Time-Frequency/02-continuous-wavelet-transform-and-the-scalogram.md) rebuilds a signal from its coefficients with the weight $`db\,da/a^2`$. That weight is the left Haar measure of the ax + b group, so no scale is favoured.
- **Statistics for location and scale.** A normal model with unknown centre and spread is acted on by the ax + b group. The prior weight "one over the spread", the right Haar measure, gives intervals matching the classical t-interval. The left one, "one over the spread squared", gives different answers.
- **Random rotations and matrices.** "A uniformly random rotation" means a sample from the Haar measure of the rotation group, scaled to total 1. Simulations of molecules, crystals and quantum circuits draw from it.

> **Say it back**
> A Haar measure gives sets in a group sizes that do not change when a set is moved by a group member. On the positive reals it is dx/x, so every doubling has size ln 2 = 0.693147. Every locally compact group has one, unique up to a unit. On groups with coordinates its density is one over the Jacobian of moving at the identity. Left and right fair sizes can differ, by the modular function, which is 1/a on the ax + b group and 1 on abelian, discrete and compact groups.

---

## What this builds on

- [Fourier analysis on a finite abelian group](01-fourier-analysis-on-finite-abelian-groups.md): the clock ℤ/12, whose Haar measure is counting measure, 1/12 per hour.
- [Lebesgue measure](../../10-Measure%20and%20integration/02-Length%20Done%20Properly/03-lebesgue-measure.md): the length $`\lambda`$ that is the Haar measure of ℝ.
- [Translation invariance and the Vitali set](../../10-Measure%20and%20integration/02-Length%20Done%20Properly/04-translation-invariance-and-the-vitali-set.md): fairness under sliding on the line, and why only measurable sets can get a size.
- [Radon measures and the Riesz representation theorem](../../10-Measure%20and%20integration/11-Derivatives%20Meet%20the%20Lebesgue%20Integral/06-radon-measures-and-riesz-representation.md): the kind of measure Haar's theorem produces, and the step from a content to a measure.
- [Change of variables for Lebesgue measure](../../10-Measure%20and%20integration/06-Product%20Measures%20and%20Fubini/08-lebesgue-change-of-variables-and-polar-coordinates.md): the Jacobian factor behind every density on this card.
- [Compactness with no distances, and Tychonoff](../../17-Topology/02-Topological%20Spaces/06-compactness-and-tychonoff.md): local compactness, and the compact product that picks a limit in the existence proof.
- [Groups](../../03-Algebra/08-Groups/01-groups.md): the operation, the identity and the undo.

## Where this goes next

- [Pontryagin duality](03-pontryagin-duality.md): the next card on this shelf, a Fourier transform on every locally compact abelian group, integrating against its Haar measure.
- [Peter-Weyl](04-peter-weyl-theorem.md): on a compact group, Haar measure of total 1 turns averaging into orthogonality of matrix entries.
- [Representation](../../23-Differential%20geometry%20and%20Lie%20groups/06-Lie%20Groups/05-representations-in-outline.md): averaging over a finite or compact group, the tool that needs a Haar measure of total 1.

A Haar measure makes integrals on a group fair; what plays the part of the pure waves of one frequency on a group that is not ℝ is the question this card leaves open.

---

## Sources

Verified 2026-11-24: every link below resolves to the publisher's page.

- Haar, Alfred. "Der Massbegriff in der Theorie der kontinuierlichen Gruppen." *Annals of Mathematics* 34 (1933), 147–169. [doi:10.2307/1968346](https://doi.org/10.2307/1968346). The original existence proof by covering counts.
- Folland, Gerald B. *A Course in Abstract Harmonic Analysis*, 2nd ed. CRC Press, 2016. [Publisher page](https://www.routledge.com/A-Course-in-Abstract-Harmonic-Analysis/Folland/p/book/9781498727136). Chapter 2: existence, uniqueness, the modular function and the standard examples.
- Halmos, Paul R. *Measure Theory*. Van Nostrand, 1950; Springer reprint, Graduate Texts in Mathematics 18, 1974. [doi:10.1007/978-1-4684-9440-2](https://doi.org/10.1007/978-1-4684-9440-2). Chapter XI builds Haar measure from contents.
- Hill, Theodore P. "A Statistical Derivation of the Significant-Digit Law." *Statistical Science* 10 (1995), 354–363. [doi:10.1214/ss/1177009869](https://doi.org/10.1214/ss/1177009869). Benford's law and its scale invariance.
