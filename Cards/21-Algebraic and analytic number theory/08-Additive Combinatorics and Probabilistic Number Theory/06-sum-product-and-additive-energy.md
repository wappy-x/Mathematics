# Sum-product: a set of numbers cannot be small for adding and for multiplying at once

[Syllabus](../../../SYLLABUS.md) → [Algebraic and analytic number theory](../README.md) → [Additive Combinatorics and Probabilistic Number Theory](../README.md#s08) → Sum-product

---

## General Overview

Take the ten powers of 2 that size computer memory: 1, 2, 4, 8, 16, 32, 64, 128, 256, 512. Add every pair, a number to itself included, and count the different answers. There are **55**, as many as there are pairs at all. No two pairs give the same total.

Now multiply every pair instead. There are only **19** different answers. Any product of two powers of 2 is again a power of 2, from 1 up to 2 to the 18th, and there are only 19 of those.

Swap in the plain run 1, 2, 3, …, 10 and the roles flip. Its pair sums fill 2 to 20, only **19** values, while its products give **42**.

So each set is small for one operation and large for the other. Paul Erdős and Endre Szemerédi showed in 1983 that this is no accident: no set of whole numbers can be small for both. That statement is the **sum-product** phenomenon. The proved bounds are far weaker than what the counts suggest, and the right answer is still open.

A second count travels with it: the **additive energy**. It counts the coincidences, the pairs of pairs with the same sum. Few coincidences force many different sums, and this card proves that exactly.

**A finite set of numbers that adds into few values must multiply into many, and the size of the sumset is pinned from below by the number of coincidences among pair sums, its additive energy.**

**What kind of fact this is:** the energy bound is a theorem, proved on this card in Why it works. The sum-product bound is a theorem stated with named sources (Erdős–Szemerédi 1983; Solymosi 2009, with an explicit constant). The strongest form, the Erdős–Szemerédi conjecture, is open as of 2026-11-15. The counts on this card are evidence, not proof.

### The picture: two runs, two operations

```
geometric 1..512   A+A ####################################################### 55
                   A.A ###################                                     19
arithmetic 1..10   A+A ###################                                     19
                   A.A ##########################################              42
```

Each run is short on one bar and long on the other. The code prints these bars.

---

## The formula

Notation first, in words. A is a finite set of numbers, and bars count members: $`\lvert A\rvert`$ is how many A holds.

- The **sumset** $`A + A`$ is the set of all sums a + b with a and b in A. Repeats count once.
- The **product set** $`A \cdot A`$ is the set of all products ab with a and b in A.
- The **additive energy** $`E_+(A)`$ counts ordered quadruples (a, b, c, d) from A with a + b = c + d.
- The **multiplicative energy** $`E_\times(A)`$ counts ordered quadruples (a, b, c, d) from A with ab = cd.
- The **representation count** r(s) is the number of ordered pairs (a, b) from A with a + b = s.

### The energy bound

```math
\lvert A + A\rvert \;\ge\; \frac{\lvert A\rvert^4}{E_+(A)}
```

**Read it aloud:** the number of different sums is at least the fourth power of the set's size divided by the number of coincidences among pair sums.

For the powers of 2: $`10^4 / 190 = 52.6`$, and the true count is 55. For the run 1 to 10: $`10^4/670 = 14.9`$, against a true 19.

### The sum-product bound

Erdős and Szemerédi proved there are fixed numbers c > 0 and δ > 0 that work for every finite set of whole numbers:

```math
\max\big(\lvert A + A\rvert,\; \lvert A \cdot A\rvert\big) \;\ge\; c\,\lvert A\rvert^{1+\delta}
```

**Read it aloud:** the larger of the sumset and the product set beats the set's own size by a fixed power.

The explicit form used here is Solymosi's, for any finite set of positive real numbers:

```math
\lvert A \cdot A\rvert\,\lvert A + A\rvert^2 \;\ge\; \frac{\lvert A\rvert^4}{4\lceil \log_2 \lvert A\rvert\rceil}, \qquad \max\big(\lvert A + A\rvert,\, \lvert A \cdot A\rvert\big) \;\ge\; \frac{\lvert A\rvert^{4/3}}{2\lceil \log_2 \lvert A\rvert\rceil^{1/3}}
```

**Read it aloud:** the product set times the square of the sumset is at least the fourth power of the size, over four times a rounded-up logarithm; so one of the two beats the size to the power four thirds, up to that logarithm.

Here $`\lceil x\rceil`$ rounds x up to a whole number. The paper leaves the log's base open; the card takes base 2, the cautious choice, since a larger log only lowers the floor. For the powers of 2: $`19 \times 55^2 = 57{,}475`$, far above the floor $`10^4/16 = 625.0`$.

The conjecture says the exponent can be pushed to 2: for every small ε > 0 and every large enough set, $`\max(\lvert A + A\rvert, \lvert A \cdot A\rvert) \ge \lvert A\rvert^{2-\varepsilon}`$. It is open.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $`A`$ | a finite set of numbers | 1, 2, 4, …, 512 | — |
| $`\lvert A\rvert`$, n | how many numbers A holds | 10 | both sets grow, at most like $`n^2`$ |
| $`A + A`$ | all sums a + b, repeats once | 55 values | — |
| $`A \cdot A`$ | all products ab, repeats once | 19 values | — |
| r(s) | ordered pairs (a, b) adding to s | r(3) = 2: 1 + 2 and 2 + 1 | more coincidences, fewer sums |
| $`E_+(A)`$ | ordered quadruples with a + b = c + d | 190 | the energy bound on the sumset falls |
| $`E_\times(A)`$ | ordered quadruples with ab = cd | 670 | the product set tends to shrink |
| c, δ | fixed constants in Erdős–Szemerédi | not explicit in 1983 | a stronger theorem |
| ε | a small positive exponent | — | a weaker conjecture |
| $`\lceil \log_2 \lvert A\rvert\rceil`$ | base-2 log of the size, rounded up | $`\lceil \log_2 10\rceil = 4`$ | a weaker floor |

### When it holds

- **Ordinary numbers: whole, rational or real.** In wrap-round arithmetic it fails. Take all 13 remainders mod 13: 13 sums, 13 products, no growth at all.
- **The same set on both sides.** With two different sets it fails: take B = {1}, and $`A + B`$ and $`A \cdot B`$ are both copies of A, with no growth. The theorem is about one set meeting itself.
- **Energy counts every quadruple, the dull ones too.** The quadruples with {a, b} = {c, d} always exist: 190 of them for ten numbers. Drop them and the energy of the powers of 2 reads 0, and the bound divides by zero.
- **Positive numbers, for Solymosi's constant.** Negative numbers are handled by splitting A into its positive and negative parts, at a cost in the constant.
- **Large sets.** For ten numbers the floor of 625.0 is far below 57,475. The bound bites only as $`\lvert A\rvert`$ grows.

---

## Why it works

### Step 0: adding likes runs, multiplying likes ratios

A set adds into few values when its members are evenly spaced, like 1 to 10. It multiplies into few values when its members are evenly spaced *in ratio*, like 1, 2, 4, …. Even spacing in both senses at once is impossible for three or more different numbers: a fixed step and a fixed ratio pull apart.

The proof turns that tension into a count. Collisions among sums are measured by the additive energy. Collisions among products are measured by the same count with multiplication.

### Step 1: why the powers of 2 give 55 sums and 19 products

Write each power in binary, base 2. The sum $`2^i + 2^j`$ with i < j has exactly two 1-digits, at places i and j. With i = j it is $`2^{i+1}`$, a single 1-digit. Different pairs give different digit patterns, so all 55 unordered pairs give different sums.

A product $`2^i \times 2^j`$ is $`2^{i+j}`$, and i + j runs from 0 to 18: 19 values. Multiplying powers of 2 is adding exponents, so the product set of the powers of 2 *is* the sumset of the exponents 0 to 9, renamed. That is why the powers' multiplicative energy, 670, equals the additive energy of a ten-number run.

### Step 2: two ways to count the energy

Count the quadruples directly, all $`10^4`$ of them, keeping those with a + b = c + d. Or group pairs by their sum: if r(s) pairs make s, then $`r(s)^2`$ quadruples have both pairs making s.

```math
E_+(A) = \sum_{s} r(s)^2, \qquad \sum_{s} r(s) = \lvert A\rvert^2
```

**Read it aloud:** the energy adds the squares of the representation counts; the counts themselves add up to every ordered pair.

For the powers of 2 every unordered sum is unique, so r(s) is 2 for a sum of two different powers and 1 for a doubled power. That gives 45 sums with r = 2 and 10 with r = 1: $`45 \times 4 + 10 = 190`$, which is $`2n^2 - n`$ with n = 10. The code checks this both ways.

For the run 1 to 10, r(s) climbs 1, 2, …, 10 and falls back, and the squares add to $`(2n^3 + n)/3 = 670`$. More coincidences, more energy.

### Step 3: few coincidences force many sums

There are $`\lvert A\rvert^2`$ ordered pairs, shared among the $`\lvert A + A\rvert`$ different sums. On average each sum gets $`\lvert A\rvert^2 / \lvert A + A\rvert`$ pairs.

An average of squares is never below the square of the average. So

```math
\frac{E_+(A)}{\lvert A + A\rvert} \;\ge\; \left(\frac{\lvert A\rvert^2}{\lvert A + A\rvert}\right)^2
```

Multiply out and the energy bound appears: $`\lvert A + A\rvert \ge \lvert A\rvert^4 / E_+(A)`$. Equality needs every r(s) equal, which is why the powers of 2 come close: 52.6 against 55.

<details>
<summary>Detailed proof: an average of squares beats the square of the average</summary>

Let the sums be $`s_1, \dots, s_k`$ with $`k = \lvert A + A\rvert`$, and let $`m = \lvert A\rvert^2 / k`$ be the average of the $`r(s_i)`$. Every square is at least zero:

$`\displaystyle 0 \le \sum_{i=1}^{k} \big(r(s_i) - m\big)^2 = \sum_{i} r(s_i)^2 - 2m \sum_{i} r(s_i) + k m^2`$

The middle sum is $`\lvert A\rvert^2 = km`$, so the right side is $`E_+(A) - 2km^2 + km^2 = E_+(A) - km^2`$. Hence $`E_+(A) \ge k m^2 = \lvert A\rvert^4 / k`$, and rearranging gives $`k \ge \lvert A\rvert^4 / E_+(A)`$. This is the Cauchy–Schwarz inequality in its simplest form.

</details>

### Step 4: the sum-product bound, in outline

The same step works with products: $`\lvert A \cdot A\rvert \ge \lvert A\rvert^4 / E_\times(A)`$. So a small product set forces a large multiplicative energy. Solymosi's step is to show that a large multiplicative energy forces a large sumset.

<details>
<summary>The key idea of Solymosi's proof, in outline</summary>

Plot every pair (a, b) from A as a point in the plane. Pairs with the same ratio b/a lie on one line through the origin. Two pairs with the same ratio give a quadruple with ab' = a'b, so the multiplicative energy adds the squared point counts of these lines.

Sort the lines by slope. Add a point on one line to a point on the next line: the sum lands strictly between the two lines. Different neighbouring pairs of lines give disjoint wedges, so all these sums are different points. Every such sum has coordinates in $`A + A`$, so there are at most $`\lvert A + A\rvert^2`$ of them.

Grouping the lines by roughly equal point counts, in powers of 2, costs the factor $`\lceil \log_2 \lvert A\rvert\rceil`$. The result is $`E_\times(A) \le 4\lvert A + A\rvert^2 \lceil \log_2 \lvert A\rvert\rceil`$, and with Step 4's first line that gives the stated bound. The full proof is in Solymosi's short 2009 paper.

</details>

### Step 5: what is proved and what is open

| Exponent on $`\lvert A\rvert`$ | Status |
| --- | --- |
| 1 + δ, some fixed δ > 0 | proved for whole numbers, Erdős and Szemerédi, 1983 |
| 5/4 | proved for real numbers, Elekes, 1997 |
| 4/3, with a log factor | proved for real numbers, Solymosi, 2009 |
| 4/3 + 2/1167 | proved for real numbers, Rudnev and Stevens, 2022: the best in the sources cited here |
| 2 − ε, for every ε > 0 | conjectured by Erdős and Szemerédi; open as of 2026-11-15 |

Exponent 2 is the ceiling: a set of n numbers has at most n(n + 1)/2 unordered pairs, so neither set can be bigger than about $`n^2/2`$.

---

## Worked numbers, by hand

The geometric run 1, 2, 4, …, 512, with n = 10.

| Step | Arithmetic | Value |
| --- | --- | --- |
| ordered pairs | 10 × 10 | 100 |
| different sums | one per unordered pair, n(n + 1)/2 | **55** |
| different products | exponents 0 to 18, 2n − 1 | **19** |
| additive energy | 45 × 4 + 10, or $`2n^2 - n`$ | 190 |
| energy bound on the sumset | $`10^4 / 190`$ | 52.6 ≤ 55 |
| Solymosi's left side | $`19 \times 55^2`$ | 57,475 |
| Solymosi's floor | $`10^4 / (4 \times 4)`$ | 625.0 |
| larger of the two sets | max(55, 19) | **55** |

The powers of 2 are as small as possible for multiplying, and they also reach the largest sumset any ten numbers can have.

The run 1 to 10 gives the mirror picture: 19 sums, 42 products, energy 670, and the bound 14.9 ≤ 19.

### The smallest both ways, by search

Which six numbers from 1 to 24 keep *both* sets small? The code tries all 134,596 choices. The smallest larger side is 15, first reached by 1, 2, 3, 4, 6, 8, a set that is part run and part doubling. Other sets tie with it; this one comes first in the search order. Its sumset has 13 values and its product set 15, so the larger is **15**.

| For six numbers | Value |
| --- | --- |
| trivial floor, 2n − 1 | 11 |
| $`6^{4/3}`$ | 10.90 |
| Solymosi's floor | 3.78 |
| the best of 134,596 sets | **15** |

The proved floor is far below the search. That gap is the open problem in miniature, though a search up to 24 is evidence, not proof.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Ordered pairs read as the sumset | 100, not 55 | 1 + 2 and 2 + 1 are one sum |
| Energy bound turned round | ceiling 52.6, but the sumset is 55 | It is a floor, never a ceiling |
| Wrap-round arithmetic mod 13 | 13 sums, 13 products, from 13 | All of Z mod 13 is closed under both operations |
| Dull quadruples left out of the energy | energy 0 | The bound divides by zero |

The code prints all four.

---

## Code, from first principles, and it actually runs

The code builds each sumset and product set as a set of values. It counts the energy two ways: by testing all $`n^4`$ quadruples, and by adding up $`r(s)^2`$. Both meet closed forms derived by hand. The multiplication table for 1 to 100 is counted twice: by building the set, and by testing each number up to 10,000 for a factor pair. The search tries every six-number set from 1 to 24. Nothing is imported.

### Python

```python
# Sum-product and additive energy -- the check behind the card.  Nothing is
# imported.  A geometric run 1, 2, 4, ..., 512 and the arithmetic
# run 1 to 10: sumsets, product sets and additive energy, each counted two ways,
# the energy bound |A+A| >= |A|^4 / E checked, and every 6-number set drawn
# from 1 to 24 searched for the one smallest at adding and multiplying at once.
def sums(A, B): return {a + b for a in A for b in B}
def prods(A, B): return {a * b for a in A for b in B}

def energy_brute(A):                     # road one: every quadruple a + b = c + d
    return sum(1 for a in A for b in A for c in A for d in A if a + b == c + d)

def energy_by_r(A, op):                  # road two: add up r(s)^2, r(s) = ways to make s
    r = {}
    for a in A:
        for b in A:
            s = op(a, b)
            r[s] = r.get(s, 0) + 1
    return sum(v * v for v in r.values())

def products_by_divisors(n):             # 1..n times 1..n, without building the set
    return sum(1 for m in range(1, n * n + 1)
               if any(m % d == 0 and m // d <= n for d in range(1, n + 1)))

def ceil_log2(n):                        # the smallest whole k with 2^k >= n
    k = 0
    while 2 ** k < n: k += 1
    return k

def subsets(pool, k):                    # every k-number subset, smallest first
    if k == 0: yield (); return
    for i in range(len(pool) - k + 1):
        for rest in subsets(pool[i + 1:], k - 1): yield (pool[i],) + rest

def bar(v): return "#" * v
def yn(c): return "yes" if c else "no"

G = [2 ** i for i in range(10)]          # the geometric run
P = list(range(1, 11))                   # the arithmetic run
M = [1, 2, 3, 4, 6, 8]                   # the search's winner, found below
n = len(G)
rows = []
for name, A in (("geometric 1..512", G), ("arithmetic 1..10", P), ("mixed 1,2,3,4,6,8", M)):
    s, p = len(sums(A, A)), len(prods(A, A))
    e1, e2 = energy_brute(A), energy_by_r(A, lambda a, b: a + b)
    ex = energy_by_r(A, lambda a, b: a * b)
    m = len(A)
    rows.append((name, m, s, p, e1, e2, ex))
    print(f"{name}: |A| {m}, |A+A| {s}, |A.A| {p}, E+ {e1} (by r(s)^2: {e2}), Ex {ex}")
    print(f"  energy bound |A|^4/E+ = {m ** 4}/{e1} = {m ** 4 / e1:.1f} <= |A+A| {s}: {yn(m ** 4 / e1 <= s)}")
    lhs, rhs = p * s * s, m ** 4 / (4 * ceil_log2(m))
    print(f"  Solymosi: |A.A| |A+A|^2 = {lhs} >= |A|^4/(4 ceil(log2|A|)) = {rhs:.1f}: {yn(lhs >= rhs)}")
g, ar = rows[0], rows[1]
print(f"closed forms, n = {n}: n(n+1)/2 = {n * (n + 1) // 2}, 2n - 1 = {2 * n - 1}, "
      f"2n^2 - n = {2 * n * n - n}, (2n^3 + n)/3 = {(2 * n ** 3 + n) // 3}")
print(f"ordered pairs (a, b): {n * n}; unordered with a <= b: {n * (n + 1) // 2}")
r = {}
for x in G:
    for y in G: r[x + y] = r.get(x + y, 0) + 1
c2, c1 = sum(1 for v in r.values() if v == 2), sum(1 for v in r.values() if v == 1)
print(f"geometric run: products 1 to 2^{max(prods(G, G)).bit_length() - 1}; sums made by 2 ordered "
      f"pairs {c2}, by 1 pair {c1}; r(3) = {r.get(3, 0)}")
print(f"arithmetic run: sums run {min(sums(P, P))} to {max(sums(P, P))}; ceil(log2 10) = {ceil_log2(10)}")
print("picture: sizes of A+A and A.A")
for name, _, s, p, *_ in rows[:2]:
    print(f"  {name:18} A+A {bar(s):55} {s}")
    print(f"  {'':18} A.A {bar(p):55} {p}")
sizes = [(k, len(prods(range(1, k + 1), range(1, k + 1)))) for k in (10, 100)]
print(f"multiplication table 1..n x 1..n, distinct products: {sizes}")
print(f"the same for n = 100, by testing each m up to 10000 for a divisor pair: "
      f"{products_by_divisors(100)}")
best, count = None, 0
for A in subsets(list(range(1, 25)), 6):
    count += 1
    m = max(len(sums(A, A)), len(prods(A, A)))
    if best is None or m < best[0]: best = (m, A)
print(f"search: {count} sets of 6 from 1..24; smallest max(|A+A|, |A.A|) = {best[0]}, "
      f"first at {list(best[1])}")
print(f"for |A| = 6: 2|A| - 1 = 11, |A|^(4/3) = {6 ** (4 / 3):.2f}, "
      f"Solymosi floor |A|^(4/3)/(2 ceil(log2|A|)^(1/3)) = {6 ** (4 / 3) / (2 * ceil_log2(6) ** (1 / 3)):.2f}")
Z = list(range(13))                      # a hypothesis broken: wrap-round arithmetic
zs, zp = {(a + b) % 13 for a in Z for b in Z}, {(a * b) % 13 for a in Z for b in Z}
print(f"mistake 1, ordered pairs read as the sumset of the run: {n * n}, not {g[2]}")
print(f"mistake 2, bound turned round, |A+A| <= |A|^4/E+: ceiling {n ** 4 / g[4]:.1f}, "
      f"but |A+A| is {g[2]}")
print(f"mistake 3, all 13 residues mod 13: |A+A| {len(zs)}, |A.A| {len(zp)}, |A| {len(Z)}")
print(f"mistake 4, energy without the trivial quadruples, geometric run: {g[4] - (2 * n * n - n)}")
assert [g[2], g[3], ar[2], ar[3]] == [n * (n + 1) // 2, 2 * n - 1, 2 * n - 1, 42]  # sizes vs formulas
assert all(r[4] == r[5] for r in rows)                           # energy, two roads
assert g[4] == 2 * n * n - n and ar[4] == (2 * n ** 3 + n) // 3   # energy vs closed forms
assert g[6] == ar[4] and all(r[1] ** 4 <= r[2] * r[4] for r in rows)   # log map; the bound
assert sizes[1][1] == products_by_divisors(100) == 2906          # products, two roads
assert best == (15, (1, 2, 3, 4, 6, 8)) and count == 134596 and len(zs) == len(zp) == 13
print("ALL CHECKS PASS")
```

**Ran 2026-11-15 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
geometric 1..512: |A| 10, |A+A| 55, |A.A| 19, E+ 190 (by r(s)^2: 190), Ex 670
  energy bound |A|^4/E+ = 10000/190 = 52.6 <= |A+A| 55: yes
  Solymosi: |A.A| |A+A|^2 = 57475 >= |A|^4/(4 ceil(log2|A|)) = 625.0: yes
arithmetic 1..10: |A| 10, |A+A| 19, |A.A| 42, E+ 670 (by r(s)^2: 670), Ex 278
  energy bound |A|^4/E+ = 10000/670 = 14.9 <= |A+A| 19: yes
  Solymosi: |A.A| |A+A|^2 = 15162 >= |A|^4/(4 ceil(log2|A|)) = 625.0: yes
mixed 1,2,3,4,6,8: |A| 6, |A+A| 13, |A.A| 15, E+ 114 (by r(s)^2: 114), Ex 106
  energy bound |A|^4/E+ = 1296/114 = 11.4 <= |A+A| 13: yes
  Solymosi: |A.A| |A+A|^2 = 2535 >= |A|^4/(4 ceil(log2|A|)) = 108.0: yes
closed forms, n = 10: n(n+1)/2 = 55, 2n - 1 = 19, 2n^2 - n = 190, (2n^3 + n)/3 = 670
ordered pairs (a, b): 100; unordered with a <= b: 55
geometric run: products 1 to 2^18; sums made by 2 ordered pairs 45, by 1 pair 10; r(3) = 2
arithmetic run: sums run 2 to 20; ceil(log2 10) = 4
picture: sizes of A+A and A.A
  geometric 1..512   A+A ####################################################### 55
                     A.A ###################                                     19
  arithmetic 1..10   A+A ###################                                     19
                     A.A ##########################################              42
multiplication table 1..n x 1..n, distinct products: [(10, 42), (100, 2906)]
the same for n = 100, by testing each m up to 10000 for a divisor pair: 2906
search: 134596 sets of 6 from 1..24; smallest max(|A+A|, |A.A|) = 15, first at [1, 2, 3, 4, 6, 8]
for |A| = 6: 2|A| - 1 = 11, |A|^(4/3) = 10.90, Solymosi floor |A|^(4/3)/(2 ceil(log2|A|)^(1/3)) = 3.78
mistake 1, ordered pairs read as the sumset of the run: 100, not 55
mistake 2, bound turned round, |A+A| <= |A|^4/E+: ceiling 52.6, but |A+A| is 55
mistake 3, all 13 residues mod 13: |A+A| 13, |A.A| 13, |A| 13
mistake 4, energy without the trivial quadruples, geometric run: 0
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Sum-product and additive energy -- the same check as the Python, in Rust.  No
// crates.  A geometric run 1, 2, 4, ..., 512 and the arithmetic run 1 to 10:
// sumsets, product sets and additive energy, each counted two ways, the energy
// bound |A+A| >= |A|^4 / E checked, and every 6-number set drawn from 1 to 24
// searched for the one smallest at adding and multiplying at once.
use std::collections::{BTreeSet, HashMap};

fn sums(a: &[i64]) -> BTreeSet<i64> { a.iter().flat_map(|x| a.iter().map(move |y| x + y)).collect() }
fn prods(a: &[i64]) -> BTreeSet<i64> { a.iter().flat_map(|x| a.iter().map(move |y| x * y)).collect() }

fn energy_brute(a: &[i64]) -> i64 {                 // road one: every quadruple a + b = c + d
    let mut n = 0;
    for &w in a { for &x in a { for &y in a { for &z in a { if w + x == y + z { n += 1 } } } } }
    n
}

fn energy_by_r(a: &[i64], op: fn(i64, i64) -> i64) -> i64 {   // road two: add up r(s)^2
    let mut r: HashMap<i64, i64> = HashMap::new();
    for &x in a { for &y in a { *r.entry(op(x, y)).or_insert(0) += 1 } }
    r.values().map(|v| v * v).sum()
}

fn products_by_divisors(n: i64) -> i64 {            // 1..n times 1..n, without building the set
    (1..=n * n).filter(|&m| (1..=n).any(|d| m % d == 0 && m / d <= n)).count() as i64
}

fn ceil_log2(n: i64) -> i64 {                        // the smallest whole k with 2^k >= n
    let mut k = 0;
    while (1i64 << k) < n { k += 1 }
    k
}

fn subsets(pool: &[i64], k: usize, cur: &mut Vec<i64>, out: &mut Vec<Vec<i64>>) {
    if k == 0 { out.push(cur.clone()); return }      // every k-number subset, smallest first
    if pool.len() < k { return }
    for i in 0..=pool.len() - k {
        cur.push(pool[i]);
        subsets(&pool[i + 1..], k - 1, cur, out);
        cur.pop();
    }
}

fn bar(v: usize) -> String { "#".repeat(v) }
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }

fn main() {
    let g: Vec<i64> = (0..10).map(|i| 1i64 << i).collect();       // the geometric run
    let p: Vec<i64> = (1..=10).collect();                          // the arithmetic run
    let mixed: Vec<i64> = vec![1, 2, 3, 4, 6, 8];                  // the search's winner
    let n: i64 = 10;
    let mut rows: Vec<(String, i64, i64, i64, i64, i64, i64)> = Vec::new();
    for (name, a) in [("geometric 1..512", &g), ("arithmetic 1..10", &p), ("mixed 1,2,3,4,6,8", &mixed)] {
        let (s, pr) = (sums(a).len() as i64, prods(a).len() as i64);
        let (e1, e2) = (energy_brute(a), energy_by_r(a, |x, y| x + y));
        let ex = energy_by_r(a, |x, y| x * y);
        let m = a.len() as i64;
        let m4 = m.pow(4);
        println!("{}: |A| {}, |A+A| {}, |A.A| {}, E+ {} (by r(s)^2: {}), Ex {}", name, m, s, pr, e1, e2, ex);
        let eb = m4 as f64 / e1 as f64;
        println!("  energy bound |A|^4/E+ = {}/{} = {:.1} <= |A+A| {}: {}", m4, e1, eb, s, yn(eb <= s as f64));
        let (lhs, rhs) = (pr * s * s, m4 as f64 / (4 * ceil_log2(m)) as f64);
        println!("  Solymosi: |A.A| |A+A|^2 = {} >= |A|^4/(4 ceil(log2|A|)) = {:.1}: {}", lhs, rhs, yn(lhs as f64 >= rhs));
        rows.push((name.to_string(), m, s, pr, e1, e2, ex));
    }
    let (gr, ar) = (rows[0].clone(), rows[1].clone());
    println!("closed forms, n = {}: n(n+1)/2 = {}, 2n - 1 = {}, 2n^2 - n = {}, (2n^3 + n)/3 = {}",
             n, n * (n + 1) / 2, 2 * n - 1, 2 * n * n - n, (2 * n.pow(3) + n) / 3);
    println!("ordered pairs (a, b): {}; unordered with a <= b: {}", n * n, n * (n + 1) / 2);
    let mut r: HashMap<i64, i64> = HashMap::new();
    for &x in &g { for &y in &g { *r.entry(x + y).or_insert(0) += 1 } }
    let c2 = r.values().filter(|&&v| v == 2).count();
    let c1 = r.values().filter(|&&v| v == 1).count();
    let top = *prods(&g).iter().max().unwrap();
    println!("geometric run: products 1 to 2^{}; sums made by 2 ordered pairs {}, by 1 pair {}; r(3) = {}",
             63 - top.leading_zeros(), c2, c1, r.get(&3).copied().unwrap_or(0));
    let sp = sums(&p);
    println!("arithmetic run: sums run {} to {}; ceil(log2 10) = {}", sp.iter().min().unwrap(), sp.iter().max().unwrap(),
             ceil_log2(10));
    println!("picture: sizes of A+A and A.A");
    for r in &rows[..2] {
        println!("  {:18} A+A {:55} {}", r.0, bar(r.2 as usize), r.2);
        println!("  {:18} A.A {:55} {}", "", bar(r.3 as usize), r.3);
    }
    let sizes: Vec<(i64, i64)> = [10i64, 100].iter()
        .map(|&k| (k, prods(&(1..=k).collect::<Vec<i64>>()).len() as i64)).collect();
    println!("multiplication table 1..n x 1..n, distinct products: [({}, {}), ({}, {})]",
             sizes[0].0, sizes[0].1, sizes[1].0, sizes[1].1);
    let by_div = products_by_divisors(100);
    println!("the same for n = 100, by testing each m up to 10000 for a divisor pair: {}", by_div);
    let mut all: Vec<Vec<i64>> = Vec::new();
    subsets(&(1..=24).collect::<Vec<i64>>(), 6, &mut Vec::new(), &mut all);
    let mut best: (usize, Vec<i64>) = (usize::MAX, Vec::new());
    for a in &all {
        let m = sums(a).len().max(prods(a).len());
        if m < best.0 { best = (m, a.clone()) }
    }
    println!("search: {} sets of 6 from 1..24; smallest max(|A+A|, |A.A|) = {}, first at {:?}",
             all.len(), best.0, best.1);
    let p43 = 6f64.powf(4.0 / 3.0);
    println!("for |A| = 6: 2|A| - 1 = 11, |A|^(4/3) = {:.2}, Solymosi floor |A|^(4/3)/(2 ceil(log2|A|)^(1/3)) = {:.2}",
             p43, p43 / (2.0 * (ceil_log2(6) as f64).powf(1.0 / 3.0)));
    let z: Vec<i64> = (0..13).collect();                           // a hypothesis broken: wrap-round
    let zs: BTreeSet<i64> = z.iter().flat_map(|x| z.iter().map(move |y| (x + y) % 13)).collect();
    let zp: BTreeSet<i64> = z.iter().flat_map(|x| z.iter().map(move |y| (x * y) % 13)).collect();
    println!("mistake 1, ordered pairs read as the sumset of the run: {}, not {}", n * n, gr.2);
    println!("mistake 2, bound turned round, |A+A| <= |A|^4/E+: ceiling {:.1}, but |A+A| is {}",
             n.pow(4) as f64 / gr.4 as f64, gr.2);
    println!("mistake 3, all 13 residues mod 13: |A+A| {}, |A.A| {}, |A| {}", zs.len(), zp.len(), z.len());
    println!("mistake 4, energy without the trivial quadruples, geometric run: {}", gr.4 - (2 * n * n - n));
    assert!(vec![gr.2, gr.3, ar.2, ar.3] == vec![n * (n + 1) / 2, 2 * n - 1, 2 * n - 1, 42]);
    assert!(rows.iter().all(|r| r.4 == r.5));                      // energy, two roads
    assert!(gr.4 == 2 * n * n - n && ar.4 == (2 * n.pow(3) + n) / 3);
    assert!(gr.6 == ar.4 && rows.iter().all(|r| r.1.pow(4) <= r.2 * r.4));
    assert!(sizes[1].1 == by_div && by_div == 2906);               // products, two roads
    assert!(best == (15, vec![1, 2, 3, 4, 6, 8]) && all.len() == 134596 && zs.len() == 13 && zp.len() == 13);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-15 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
geometric 1..512: |A| 10, |A+A| 55, |A.A| 19, E+ 190 (by r(s)^2: 190), Ex 670
  energy bound |A|^4/E+ = 10000/190 = 52.6 <= |A+A| 55: yes
  Solymosi: |A.A| |A+A|^2 = 57475 >= |A|^4/(4 ceil(log2|A|)) = 625.0: yes
arithmetic 1..10: |A| 10, |A+A| 19, |A.A| 42, E+ 670 (by r(s)^2: 670), Ex 278
  energy bound |A|^4/E+ = 10000/670 = 14.9 <= |A+A| 19: yes
  Solymosi: |A.A| |A+A|^2 = 15162 >= |A|^4/(4 ceil(log2|A|)) = 625.0: yes
mixed 1,2,3,4,6,8: |A| 6, |A+A| 13, |A.A| 15, E+ 114 (by r(s)^2: 114), Ex 106
  energy bound |A|^4/E+ = 1296/114 = 11.4 <= |A+A| 13: yes
  Solymosi: |A.A| |A+A|^2 = 2535 >= |A|^4/(4 ceil(log2|A|)) = 108.0: yes
closed forms, n = 10: n(n+1)/2 = 55, 2n - 1 = 19, 2n^2 - n = 190, (2n^3 + n)/3 = 670
ordered pairs (a, b): 100; unordered with a <= b: 55
geometric run: products 1 to 2^18; sums made by 2 ordered pairs 45, by 1 pair 10; r(3) = 2
arithmetic run: sums run 2 to 20; ceil(log2 10) = 4
picture: sizes of A+A and A.A
  geometric 1..512   A+A ####################################################### 55
                     A.A ###################                                     19
  arithmetic 1..10   A+A ###################                                     19
                     A.A ##########################################              42
multiplication table 1..n x 1..n, distinct products: [(10, 42), (100, 2906)]
the same for n = 100, by testing each m up to 10000 for a divisor pair: 2906
search: 134596 sets of 6 from 1..24; smallest max(|A+A|, |A.A|) = 15, first at [1, 2, 3, 4, 6, 8]
for |A| = 6: 2|A| - 1 = 11, |A|^(4/3) = 10.90, Solymosi floor |A|^(4/3)/(2 ceil(log2|A|)^(1/3)) = 3.78
mistake 1, ordered pairs read as the sumset of the run: 100, not 55
mistake 2, bound turned round, |A+A| <= |A|^4/E+: ceiling 52.6, but |A+A| is 55
mistake 3, all 13 residues mod 13: |A+A| 13, |A.A| 13, |A| 13
mistake 4, energy without the trivial quadruples, geometric run: 0
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves the energy bound, Solymosi's bound and the Erdős–Szemerédi theorem in full, and checks the card's worked counts.

- Take any finite set A of real numbers. Then $`\lvert A + A\rvert \ge \lvert A\rvert^4 / E_+(A)`$.
- Take any finite set A of positive real numbers. Then $`\lvert A \cdot A\rvert\,\lvert A + A\rvert^2 \ge \lvert A\rvert^4 / (4\lceil \log_2 \lvert A\rvert\rceil)`$.
- Erdős–Szemerédi holds: fixed numbers c > 0 and δ > 0 work for every finite set of whole numbers, negative ones included.
- The powers of 2 from 1 to 512 give 55 sums and 19 products, with additive energy 190 and multiplicative energy 670.
- The run 1 to 10 gives 19 sums and 42 products, with additive energy 670 and multiplicative energy 278.
- The set 1, 2, 3, 4, 6, 8 gives 13 sums and 15 products, with additive energy 114 and multiplicative energy 106.
- Take n = 10. Then the card's closed forms give 55, 19, 190 and 670.
- Take the powers of 2. Then $`\lceil \log_2 10\rceil = 4`$, and $`19 \times 55^2 = 57{,}475`$ clears the floor $`10^4/16 = 625`$.
- All 13 remainders mod 13 give 13 sums and 13 products.
- Ten numbers make 100 ordered pairs, not the 55 sums.

Counting energy by r(s), the decimals, the multiplication table, the six-number search and the four-thirds form are left to Python and Rust.

```lean
-- Sum-product: the sumset of a finite set of numbers has at least |A|^4 / E+(A) members, Solymosi's bound |A·A| |A+A|^2 ≥ |A|^4 / (4⌈log₂|A|⌉) holds for positive reals, and some fixed power 1 + δ makes max(|A+A|, |A·A|) at least c|A|^(1+δ) for whole numbers.
import Mathlib.Combinatorics.Additive.Energy
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Data.Nat.Log
import Mathlib.Data.ZMod.Defs
import Mathlib.Tactic.NormNum

/-! Notation: for a finite set `A`, `A + A` and `A * A` are Mathlib's pointwise sumset and
product set (repeats counted once), and `A.card` is `|A|`. Mathlib's `Finset.addEnergy A A`
counts quadruples `(a₁, a₂, b₁, b₂)` from `A` with `a₁ + b₁ = a₂ + b₂`; renaming
`(a, b, c, d) = (a₁, b₁, a₂, b₂)` makes it the card's count of ordered quadruples with
`a + b = c + d`, dull quadruples included. `Finset.mulEnergy A A` is the same with products.
`Nat.clog 2 n` is `⌈log₂ n⌉` for `n ≥ 1`. Division in `ℝ` by zero gives zero, so the bounds
read `0 ≤ …` for the empty set (and Solymosi's for a one-element set), where the card's
fractions are undefined. -/

open scoped Pointwise

/-! Helper lemmas for the proofs below. -/

lemma sp_between (l m a b : ℝ) (ha : 0 < a) (hb : 0 < b) (h : l ≠ m) :
    (l < (l * a + m * b) / (a + b) ∧ (l * a + m * b) / (a + b) < m) ∨
      (m < (l * a + m * b) / (a + b) ∧ (l * a + m * b) / (a + b) < l) := by
  have hab : 0 < a + b := by linarith
  rcases lt_or_gt_of_ne h with h | h
  · left; constructor
    · rw [lt_div_iff₀ hab]; nlinarith
    · rw [div_lt_iff₀ hab]; nlinarith
  · right; constructor
    · rw [lt_div_iff₀ hab]; nlinarith
    · rw [div_lt_iff₀ hab]; nlinarith

#print axioms sp_between

lemma sp_region (A : Finset ℝ) (hA : ∀ a ∈ A, 0 < a) (T : Finset ℝ) (nb : ℝ → ℝ)
    (hne : ∀ l ∈ T, nb l ≠ l)
    (hdisj : ∀ l ∈ T, ∀ l' ∈ T, ∀ σ : ℝ, ((l < σ ∧ σ < nb l) ∨ (nb l < σ ∧ σ < l)) →
      ((l' < σ ∧ σ < nb l') ∨ (nb l' < σ ∧ σ < l')) → l = l') :
    ∑ l ∈ T, ((A ×ˢ A).filter (fun p => p.2 = l * p.1)).card *
      ((A ×ˢ A).filter (fun p => p.2 = nb l * p.1)).card ≤ (A + A).card ^ 2 := by
  classical
  have hF : (T.sigma (fun l => ((A ×ˢ A).filter (fun p => p.2 = l * p.1)) ×ˢ
    ((A ×ˢ A).filter (fun p => p.2 = nb l * p.1)))).card = ∑ l ∈ T, ((A ×ˢ A).filter (fun p => p.2 = l * p.1)).card *
      ((A ×ˢ A).filter (fun p => p.2 = nb l * p.1)).card := by
    simp [Finset.card_sigma, Finset.card_product]
  rw [← hF, sq, ← Finset.card_product]
  refine Finset.card_le_card_of_injOn
    (fun x => (x.2.1.1 + x.2.2.1, x.2.1.2 + x.2.2.2)) ?_ ?_
  · intro x hx
    simp only [Finset.mem_coe, Finset.mem_sigma, Finset.mem_product, Finset.mem_filter] at hx
    simp only [Finset.coe_product, Set.mem_prod, Finset.mem_coe]
    exact ⟨Finset.add_mem_add hx.2.1.1.1 hx.2.2.1.1, Finset.add_mem_add hx.2.1.1.2 hx.2.2.1.2⟩
  · rintro ⟨l, ⟨a, a2⟩, ⟨b, b2⟩⟩ hx ⟨l', ⟨a', a2'⟩, ⟨b', b2'⟩⟩ hx' heq
    simp only [Finset.mem_coe, Finset.mem_sigma, Finset.mem_product,
      Finset.mem_filter] at hx hx'
    simp only [Prod.mk.injEq] at heq
    obtain ⟨hl, ⟨⟨ha, ha2⟩, e1⟩, ⟨⟨hb, hb2⟩, e2⟩⟩ := hx
    obtain ⟨hl', ⟨⟨ha', ha2'⟩, e1'⟩, ⟨⟨hb', hb2'⟩, e2'⟩⟩ := hx'
    subst e1 e2 e1' e2'
    have hapos := hA a ha
    have hbpos := hA b hb
    have hapos' := hA a' ha'
    have hbpos' := hA b' hb'
    have B1 := sp_between l (nb l) a b hapos hbpos (hne l hl).symm
    have B2 := sp_between l' (nb l') a' b' hapos' hbpos' (hne l' hl').symm
    have hs : (l * a + nb l * b) / (a + b) = (l' * a' + nb l' * b') / (a' + b') := by
      rw [heq.1, heq.2]
    rw [hs] at B1
    have hll := hdisj l hl l' hl' _ B1 B2
    subst hll
    have hd : (nb l - l) * (b - b') = 0 := by
      have h1 := heq.1
      have h2 := heq.2
      linear_combination h2 - l * h1
    have hlm : nb l - l ≠ 0 := sub_ne_zero.mpr (hne l hl)
    have hbb : b = b' := by
      rcases mul_eq_zero.mp hd with h | h
      · exact absurd h hlm
      · linarith
    have haa : a = a' := by linarith [heq.1]
    subst hbb; subst haa
    rfl

#print axioms sp_region

lemma sp_nb (T : Finset ℝ) :
    ∃ nb : ℝ → ℝ, (∀ l ∈ T, nb l ∈ insert 1 T) ∧
      (∀ l ∈ T, l < 1 → l < nb l ∧ ∀ x ∈ insert 1 T, l < x → nb l ≤ x) ∧
      (∀ l ∈ T, 1 < l → nb l < l ∧ ∀ x ∈ insert 1 T, x < l → x ≤ nb l) := by
  classical
  refine ⟨fun l => if h : l < 1 then ((insert 1 T).filter (l < ·)).min' ⟨1, by simp [h]⟩
    else if h' : 1 < l then ((insert 1 T).filter (· < l)).max' ⟨1, by simp [h']⟩ else 1,
    ?_, ?_, ?_⟩
  · intro l hl
    by_cases h : l < 1
    · simp only [h, dite_eq_left]
      exact (Finset.mem_filter.mp (Finset.min'_mem _ _)).1
    · by_cases h' : 1 < l
      · simp only [h, h', dite_eq_left, dite_eq_right, not_false_eq_true]
        exact (Finset.mem_filter.mp (Finset.max'_mem _ _)).1
      · simp only [h, h', dite_eq_right, not_false_eq_true]; simp
  · intro l hl h
    simp only [h, dite_eq_left]
    refine ⟨(Finset.mem_filter.mp (Finset.min'_mem _ _)).2, fun x hx hlx => ?_⟩
    exact Finset.min'_le _ _ (Finset.mem_filter.mpr ⟨hx, hlx⟩)
  · intro l hl h
    have h' : ¬ l < 1 := by linarith
    simp only [h, h', dite_eq_left, dite_eq_right, not_false_eq_true]
    have hm := Finset.max'_mem ((insert 1 T).filter (· < l)) ⟨1, by simp [h]⟩
    rw [Finset.mem_filter] at hm
    refine ⟨hm.2, fun x hx hlx => ?_⟩
    exact Finset.le_max' _ _ (Finset.mem_filter.mpr ⟨hx, hlx⟩)

#print axioms sp_nb

lemma sp_disj (T : Finset ℝ) (h1 : (1 : ℝ) ∉ T) (nb : ℝ → ℝ)
    (hlo : ∀ l ∈ T, l < 1 → l < nb l ∧ ∀ x ∈ insert 1 T, l < x → nb l ≤ x)
    (hhi : ∀ l ∈ T, 1 < l → nb l < l ∧ ∀ x ∈ insert 1 T, x < l → x ≤ nb l) :
    ∀ l ∈ T, ∀ l' ∈ T, ∀ σ : ℝ, ((l < σ ∧ σ < nb l) ∨ (nb l < σ ∧ σ < l)) →
      ((l' < σ ∧ σ < nb l') ∨ (nb l' < σ ∧ σ < l')) → l = l' := by
  have key : ∀ l ∈ T, ∀ l' ∈ T, l < l' → ∀ σ : ℝ, ((l < σ ∧ σ < nb l) ∨ (nb l < σ ∧ σ < l)) →
      ((l' < σ ∧ σ < nb l') ∨ (nb l' < σ ∧ σ < l')) → False := by
    intro l hl l' hl' hlt σ hb hb'
    have hl1 : l ≠ 1 := fun h => h1 (h ▸ hl)
    have hl1' : l' ≠ 1 := fun h => h1 (h ▸ hl')
    have mem1 : (1 : ℝ) ∈ insert 1 T := Finset.mem_insert_self _ _
    have memT : ∀ x ∈ T, x ∈ insert 1 T := fun x hx => Finset.mem_insert_of_mem hx
    rcases lt_or_gt_of_ne hl1 with h | h
    · obtain ⟨n1, n2⟩ := hlo l hl h
      have c1 := n2 l' (memT l' hl') hlt
      have c2 := n2 1 mem1 h
      rcases lt_or_gt_of_ne hl1' with h' | h'
      · obtain ⟨m1, _⟩ := hlo l' hl' h'
        rcases hb with ⟨_, _⟩ | ⟨_, _⟩ <;> rcases hb' with ⟨_, _⟩ | ⟨_, _⟩ <;> linarith
      · obtain ⟨m1, m2⟩ := hhi l' hl' h'
        have c3 := m2 1 mem1 h'
        rcases hb with ⟨_, _⟩ | ⟨_, _⟩ <;> rcases hb' with ⟨_, _⟩ | ⟨_, _⟩ <;> linarith
    · have h' : 1 < l' := by linarith
      obtain ⟨n1, _⟩ := hhi l hl h
      obtain ⟨m1, m2⟩ := hhi l' hl' h'
      have c3 := m2 l (memT l hl) hlt
      rcases hb with ⟨_, _⟩ | ⟨_, _⟩ <;> rcases hb' with ⟨_, _⟩ | ⟨_, _⟩ <;> linarith
  intro l hl l' hl' σ hb hb'
  rcases lt_trichotomy l l' with h | h | h
  · exact (key l hl l' hl' h σ hb hb').elim
  · exact h
  · exact (key l' hl' l hl h σ hb' hb).elim

#print axioms sp_disj

lemma sp_r_le_one (A : Finset ℝ) (l : ℝ) :
    ((A ×ˢ A).filter (fun p => p.2 = l * p.1)).card ≤
      ((A ×ˢ A).filter (fun p => p.2 = 1 * p.1)).card := by
  refine Finset.card_le_card_of_injOn (fun p => (p.1, p.1)) ?_ ?_
  · intro p hp
    simp only [Finset.mem_coe, Finset.mem_filter, Finset.mem_product] at hp ⊢
    exact ⟨⟨hp.1.1, hp.1.1⟩, by ring⟩
  · intro p hp q hq h
    simp only [Finset.mem_coe, Finset.mem_filter, Finset.mem_product] at hp hq
    simp only [Prod.mk.injEq] at h
    exact Prod.ext h.1 (by rw [hp.2, hq.2, h.1])

#print axioms sp_r_le_one

lemma sp_r_le_card (A : Finset ℝ) (l : ℝ) :
    ((A ×ˢ A).filter (fun p => p.2 = l * p.1)).card ≤ A.card := by
  refine Finset.card_le_card_of_injOn (fun p => p.1) ?_ ?_
  · intro p hp
    simp only [Finset.mem_coe, Finset.mem_filter, Finset.mem_product] at hp ⊢
    exact hp.1.1
  · intro p hp q hq h
    simp only [Finset.mem_coe, Finset.mem_filter, Finset.mem_product] at hp hq
    simp only at h
    exact Prod.ext h (by rw [hp.2, hq.2, h])

#print axioms sp_r_le_card

lemma sp_class (A : Finset ℝ) (hA : ∀ a ∈ A, 0 < a) (T : Finset ℝ) (h1 : (1 : ℝ) ∉ T) (i : ℕ)
    (hT : ∀ l ∈ T, 2 ^ i ≤ ((A ×ˢ A).filter (fun p => p.2 = l * p.1)).card ∧
      ((A ×ˢ A).filter (fun p => p.2 = l * p.1)).card < 2 ^ (i + 1)) :
    ∑ l ∈ T, ((A ×ˢ A).filter (fun p => p.2 = l * p.1)).card ^ 2 ≤ 2 * (A + A).card ^ 2 := by
  obtain ⟨nb, hmem, hlo, hhi⟩ := sp_nb T
  have hne : ∀ l ∈ T, nb l ≠ l := by
    intro l hl
    have : l ≠ 1 := fun h => h1 (h ▸ hl)
    rcases lt_or_gt_of_ne this with h | h
    · exact (hlo l hl h).1.ne'
    · exact (hhi l hl h).1.ne
  have hreg := sp_region A hA T nb hne (sp_disj T h1 nb hlo hhi)
  calc ∑ l ∈ T, ((A ×ˢ A).filter (fun p => p.2 = l * p.1)).card ^ 2
      ≤ ∑ l ∈ T, 2 * (((A ×ˢ A).filter (fun p => p.2 = l * p.1)).card *
          ((A ×ˢ A).filter (fun p => p.2 = nb l * p.1)).card) := by
        refine Finset.sum_le_sum (fun l hl => ?_)
        have key : ((A ×ˢ A).filter (fun p => p.2 = l * p.1)).card ≤
            2 * ((A ×ˢ A).filter (fun p => p.2 = nb l * p.1)).card := by
          rcases Finset.mem_insert.mp (hmem l hl) with h | h
          · rw [h]; have := sp_r_le_one A l; omega
          · have h2 := (hT l hl).2
            have h3 := (hT (nb l) h).1
            rw [pow_succ] at h2
            omega
        rw [sq]
        calc _ ≤ ((A ×ˢ A).filter (fun p => p.2 = l * p.1)).card *
              (2 * ((A ×ˢ A).filter (fun p => p.2 = nb l * p.1)).card) :=
                Nat.mul_le_mul_left _ key
          _ = _ := by ring
    _ = 2 * ∑ l ∈ T, ((A ×ˢ A).filter (fun p => p.2 = l * p.1)).card *
          ((A ×ˢ A).filter (fun p => p.2 = nb l * p.1)).card := by rw [Finset.mul_sum]
    _ ≤ 2 * (A + A).card ^ 2 := Nat.mul_le_mul_left _ hreg

#print axioms sp_class

lemma sp_energy_le (A : Finset ℝ) (hA : ∀ a ∈ A, 0 < a) :
    ∃ S : Finset ℝ, (∀ l ∈ S, 0 < ((A ×ˢ A).filter (fun p => p.2 = l * p.1)).card) ∧
      A.mulEnergy A ≤ ∑ l ∈ S, ((A ×ˢ A).filter (fun p => p.2 = l * p.1)).card ^ 2 := by
  classical
  set Q := ((A ×ˢ A) ×ˢ (A ×ˢ A)).filter
    (fun pq : (ℝ × ℝ) × (ℝ × ℝ) => pq.1.2 / pq.1.1 = pq.2.2 / pq.2.1) with hQ
  have hmemQ : ∀ pq ∈ Q, pq.1 ∈ (A ×ˢ A).filter (fun p => p.2 = pq.1.2 / pq.1.1 * p.1) ∧
      pq.2 ∈ (A ×ˢ A).filter (fun p => p.2 = pq.1.2 / pq.1.1 * p.1) := by
    intro pq hpq
    simp only [Q, Finset.mem_filter, Finset.mem_product] at hpq
    obtain ⟨⟨⟨h11, h12⟩, h21, h22⟩, he⟩ := hpq
    have p1 := hA _ h11
    have p2 := hA _ h21
    simp only [Finset.mem_filter, Finset.mem_product]
    refine ⟨⟨⟨h11, h12⟩, by field_simp⟩, ⟨⟨h21, h22⟩, ?_⟩⟩
    rw [he]; field_simp
  refine ⟨Q.image (fun pq => pq.1.2 / pq.1.1), ?_, ?_⟩
  · intro l hl
    obtain ⟨pq, hpq, rfl⟩ := Finset.mem_image.mp hl
    exact Finset.card_pos.mpr ⟨_, (hmemQ pq hpq).1⟩
  · have h1 : A.mulEnergy A ≤ Q.card := by
      unfold Finset.mulEnergy
      refine Finset.card_le_card_of_injOn (fun x => ((x.1.1, x.1.2), (x.2.2, x.2.1))) ?_ ?_
      · intro x hx
        simp only [Finset.mem_coe, Finset.mem_filter, Finset.mem_product] at hx
        obtain ⟨⟨⟨h11, h12⟩, h21, h22⟩, he⟩ := hx
        simp only [Q, Finset.mem_coe, Finset.mem_filter, Finset.mem_product]
        refine ⟨⟨⟨h11, h12⟩, h22, h21⟩, ?_⟩
        have p1 := hA _ h11
        have p2 := hA _ h22
        rw [div_eq_div_iff p1.ne' p2.ne']
        linarith
      · intro x _ y _ h
        simp only [Prod.mk.injEq] at h
        ext <;> simp [h]
    rw [Finset.card_eq_sum_card_image (fun pq => pq.1.2 / pq.1.1) Q] at h1
    refine h1.trans (Finset.sum_le_sum (fun l _ => ?_))
    rw [sq, ← Finset.card_product]
    refine Finset.card_le_card (fun pq hpq => ?_)
    rw [Finset.mem_filter] at hpq
    have := hmemQ pq hpq.1
    rw [hpq.2] at this
    exact Finset.mem_product.mpr this

#print axioms sp_energy_le

lemma sp_energy_bound (A : Finset ℝ) (hA : ∀ a ∈ A, 0 < a) :
    A.mulEnergy A ≤ A.card ^ 2 + (Nat.log 2 A.card + 1) * (2 * (A + A).card ^ 2) := by
  classical
  obtain ⟨S, hSpos, hE⟩ := sp_energy_le A hA
  refine hE.trans ?_
  have hsplit : ∑ l ∈ S, ((A ×ˢ A).filter (fun p => p.2 = l * p.1)).card ^ 2 ≤
      A.card ^ 2 + ∑ l ∈ S.erase 1, ((A ×ˢ A).filter (fun p => p.2 = l * p.1)).card ^ 2 := by
    by_cases h : (1 : ℝ) ∈ S
    · rw [← Finset.add_sum_erase S _ h]
      have := sp_r_le_card A 1
      gcongr
    · rw [Finset.erase_eq_of_notMem h]; omega
  refine hsplit.trans (Nat.add_le_add_left ?_ _)
  rw [← Finset.sum_fiberwise_of_maps_to (s := S.erase 1) (t := Finset.range (Nat.log 2 A.card + 1))
    (g := fun l => Nat.log 2 ((A ×ˢ A).filter (fun p => p.2 = l * p.1)).card)]
  · calc _ ≤ ∑ i ∈ Finset.range (Nat.log 2 A.card + 1), 2 * (A + A).card ^ 2 := by
          refine Finset.sum_le_sum (fun i _ => ?_)
          refine sp_class A hA _ (by simp) i (fun l hl => ?_)
          rw [Finset.mem_filter] at hl
          have hpos := hSpos l (Finset.mem_of_mem_erase hl.1)
          rw [← hl.2]
          exact ⟨Nat.pow_log_le_self 2 hpos.ne', Nat.lt_pow_succ_log_self (by norm_num) _⟩
      _ = _ := by simp
  · intro l _
    rw [Finset.mem_range, Nat.lt_succ_iff]
    exact Nat.log_mono_right (sp_r_le_card A l)

#print axioms sp_energy_bound

lemma es_sq_le_two_pow (k : ℕ) : k ^ 2 ≤ 2 ^ (k + 1) ∧ 2 * k + 1 ≤ 2 ^ (k + 1) := by
  induction k with
  | zero => norm_num
  | succ k ih =>
    have h2 : 2 ≤ 2 ^ (k + 1) := by
      calc 2 = 2 ^ 1 := by norm_num
        _ ≤ 2 ^ (k + 1) := Nat.pow_le_pow_right (by norm_num) (by omega)
    rw [pow_succ 2 (k + 1)]
    constructor <;> nlinarith [ih.1, ih.2]

#print axioms es_sq_le_two_pow

lemma es_clog_sq_le (q : ℕ) (hq : 1 ≤ q) : (Nat.clog 2 q) ^ 2 ≤ 4 * q := by
  rcases Nat.eq_or_lt_of_le hq with h | h
  · rw [← h]; simp [Nat.clog_one_right]
  · have h1 := Nat.pow_pred_clog_lt_self (b := 2) (by norm_num) h
    have hpos := Nat.clog_pos (b := 2) (by norm_num) h
    have h2 := (es_sq_le_two_pow (Nat.clog 2 q)).1
    obtain ⟨j, hj⟩ : ∃ j, Nat.clog 2 q = j + 1 := ⟨Nat.clog 2 q - 1, by omega⟩
    rw [hj] at h1 h2 ⊢
    simp only [Nat.pred_succ] at h1
    have e : 2 ^ (j + 1 + 1) = 4 * 2 ^ j := by ring
    rw [e] at h2
    linarith

#print axioms es_clog_sq_le

lemma es_pos_part (Q : Finset ℝ) (M : ℝ)
    (hadd : ((Q + Q).card : ℝ) ≤ M) (hmul : ((Q * Q).card : ℝ) ≤ M)
    (hS : (Q.card : ℝ) ^ 4 / (4 * (Nat.clog 2 Q.card : ℝ)) ≤
      ((Q * Q).card : ℝ) * ((Q + Q).card : ℝ) ^ 2) :
    (Q.card : ℝ) ^ 7 ≤ 64 * M ^ 6 := by
  have hq0 : (0 : ℝ) ≤ Q.card := by positivity
  rcases Nat.eq_zero_or_pos Q.card with h0 | hpos
  · rw [h0]; norm_num; positivity
  have hqM : (Q.card : ℝ) ≤ M := by
    have : Q.card ≤ (Q + Q).card := Finset.card_le_card_add_left (Finset.card_pos.mp hpos)
    have : (Q.card : ℝ) ≤ (Q + Q).card := by exact_mod_cast this
    linarith
  have hM0 : 0 ≤ M := le_trans hq0 hqM
  rcases Nat.eq_zero_or_pos (Nat.clog 2 Q.card) with hL | hL
  · have hq1 : Q.card ≤ 1 := by
      by_contra hc
      have := Nat.clog_pos (b := 2) (by norm_num) (by omega : 1 < Q.card)
      omega
    have hq1' : (Q.card : ℝ) = 1 := by
      have : Q.card = 1 := by omega
      rw [this]; norm_num
    rw [hq1'] at hqM ⊢
    have : (1 : ℝ) ≤ M ^ 6 := one_le_pow₀ hqM
    linarith
  · 
    have hLr : (0 : ℝ) < 4 * (Nat.clog 2 Q.card : ℝ) := by
      have : (1 : ℝ) ≤ Nat.clog 2 Q.card := by exact_mod_cast hL
      linarith
    rw [div_le_iff₀ hLr] at hS
    have hprod : ((Q * Q).card : ℝ) * ((Q + Q).card : ℝ) ^ 2 ≤ M ^ 3 := by
      have h1 : ((Q + Q).card : ℝ) ^ 2 ≤ M ^ 2 := pow_le_pow_left₀ (by positivity) hadd 2
      calc ((Q * Q).card : ℝ) * ((Q + Q).card : ℝ) ^ 2 ≤ M * M ^ 2 :=
            mul_le_mul hmul h1 (by positivity) hM0
        _ = M ^ 3 := by ring
    have hlog : ((Nat.clog 2 Q.card : ℕ) : ℝ) ^ 2 ≤ 4 * Q.card := by
      exact_mod_cast es_clog_sq_le Q.card hpos
    set q : ℝ := (Q.card : ℝ)
    set L : ℝ := (Nat.clog 2 Q.card : ℝ)
    have hL0 : 0 ≤ L := by positivity
    have h4 : q ^ 4 ≤ 4 * L * M ^ 3 := by nlinarith
    have hq4 : 0 ≤ q ^ 4 := by positivity
    have h8 : q ^ 8 ≤ 16 * L ^ 2 * M ^ 6 := by
      have := pow_le_pow_left₀ hq4 h4 2
      calc q ^ 8 = (q ^ 4) ^ 2 := by ring
        _ ≤ (4 * L * M ^ 3) ^ 2 := this
        _ = 16 * L ^ 2 * M ^ 6 := by ring
    have hM6 : 0 ≤ M ^ 6 := by positivity
    have h8' : q ^ 8 ≤ 64 * q * M ^ 6 := by nlinarith
    have hqpos : 0 < q := by simp only [q]; exact_mod_cast hpos
    have : q * q ^ 7 ≤ q * (64 * M ^ 6) := by nlinarith
    exact le_of_mul_le_mul_left this hqpos

#print axioms es_pos_part

/-- **The energy bound.** For any finite set `A` of real numbers (so also of whole or rational
numbers), the number of different pair sums is at least the fourth power of the set's size
divided by the additive energy: `|A + A| ≥ |A|^4 / E₊(A)`. -/
theorem card_add_ge_card_pow_four_div_addEnergy (A : Finset ℝ) :
    (A.card : ℝ) ^ 4 / (A.addEnergy A : ℝ) ≤ ((A + A).card : ℝ) := by
  have h := Finset.le_card_add_mul_addEnergy A A
  have h' : ((A.card : ℝ)) ^ 4 ≤ ((A + A).card : ℝ) * (A.addEnergy A : ℝ) := by
    have : (A.card ^ 2 * A.card ^ 2 : ℕ) = A.card ^ 4 := by ring
    exact_mod_cast this ▸ h
  rcases (Nat.zero_le (A.addEnergy A)).eq_or_lt with h0 | h0
  · rw [← h0]; simp
  · rw [div_le_iff₀ (by exact_mod_cast h0)]; exact h'

/-- **Solymosi's sum-product bound (2009).** For any finite set `A` of positive real numbers,
the product set times the square of the sumset is at least the fourth power of the set's size
over four times the rounded-up base-2 logarithm of that size:
`|A · A| |A + A|^2 ≥ |A|^4 / (4 ⌈log₂ |A|⌉)`. -/
theorem card_mul_mul_card_add_sq_ge (A : Finset ℝ) (hA : ∀ a ∈ A, 0 < a) :
    (A.card : ℝ) ^ 4 / (4 * (Nat.clog 2 A.card : ℝ)) ≤
      ((A * A).card : ℝ) * ((A + A).card : ℝ) ^ 2 := by
  classical
  have hCS := Finset.le_card_mul_mul_mulEnergy A A
  have hn : A.card ≤ (A + A).card := by
    rcases A.eq_empty_or_nonempty with h | h
    · simp [h]
    · exact Finset.card_le_card_add_left h
  rcases Nat.lt_or_ge A.card 3 with hsmall | hbig
  · obtain hc | hc | hc : A.card = 0 ∨ A.card = 1 ∨ A.card = 2 := by omega
    · rw [hc]; simp; positivity
    · rw [hc]; simp; positivity
    · rw [hc] at hn ⊢
      have hne : A.Nonempty := Finset.card_pos.mp (by omega)
      have hm : 1 ≤ (A * A).card := Finset.card_pos.mpr (hne.mul hne)
      have hc2 : (Nat.clog 2 2 : ℝ) = 1 := by
        have : Nat.clog 2 2 = 1 := by decide
        rw [this]; norm_num
      rw [hc2]
      have hm' : (1 : ℝ) ≤ (A * A).card := by exact_mod_cast hm
      have hn' : (2 : ℝ) ≤ (A + A).card := by exact_mod_cast hn
      push_cast
      nlinarith
  · have hL : 2 ≤ Nat.clog 2 A.card := by
      have := Nat.clog_mono_right 2 hbig
      have h3 : Nat.clog 2 3 = 2 := by decide
      omega
    have hlog := Nat.log_le_clog 2 A.card
    have hE := sp_energy_bound A hA
    have hE' : A.mulEnergy A ≤ 4 * Nat.clog 2 A.card * (A + A).card ^ 2 := by
      have : A.card ^ 2 ≤ (A + A).card ^ 2 := Nat.pow_le_pow_left hn 2
      have h5 : (Nat.log 2 A.card + 1) * (2 * (A + A).card ^ 2) ≤
          (Nat.clog 2 A.card + 1) * (2 * (A + A).card ^ 2) := by gcongr
      nlinarith
    have key : A.card ^ 4 ≤ 4 * Nat.clog 2 A.card * ((A * A).card * (A + A).card ^ 2) := by
      calc A.card ^ 4 = A.card ^ 2 * A.card ^ 2 := by ring
        _ ≤ (A * A).card * A.mulEnergy A := hCS
        _ ≤ (A * A).card * (4 * Nat.clog 2 A.card * (A + A).card ^ 2) :=
            Nat.mul_le_mul_left _ hE'
        _ = _ := by ring
    have hLpos : (0 : ℝ) < 4 * (Nat.clog 2 A.card : ℝ) := by
      have : (2 : ℝ) ≤ Nat.clog 2 A.card := by exact_mod_cast hL
      linarith
    rw [div_le_iff₀ hLpos]
    have : ((A.card ^ 4 : ℕ) : ℝ) ≤ ((4 * Nat.clog 2 A.card * ((A * A).card * (A + A).card ^ 2) : ℕ) : ℝ) :=
      by exact_mod_cast key
    push_cast at this
    linarith

/-- **The Erdős–Szemerédi sum-product theorem (1983).** There are fixed numbers `c > 0` and
`δ > 0` such that every finite set `A` of whole numbers has
`max(|A + A|, |A · A|) ≥ c |A|^(1+δ)`: no set can be small for adding and for multiplying
at once. -/
theorem exists_max_card_add_card_mul_ge :
    ∃ c δ : ℝ, 0 < c ∧ 0 < δ ∧ ∀ A : Finset ℤ,
      c * (A.card : ℝ) ^ (1 + δ) ≤ max ((A + A).card : ℝ) ((A * A).card : ℝ) := by
  classical
  refine ⟨1 / 8, 1 / 6, by norm_num, by norm_num, fun A => ?_⟩
  set M : ℝ := max ((A + A).card : ℝ) ((A * A).card : ℝ) with hMdef
  have hM1 : ((A + A).card : ℝ) ≤ M := le_max_left _ _
  have hM2 : ((A * A).card : ℝ) ≤ M := le_max_right _ _
  have hn0 : (0 : ℝ) ≤ A.card := by positivity
  have hnM : (A.card : ℝ) ≤ M := by
    rcases A.eq_empty_or_nonempty with h | h
    · rw [h]; simp only [Finset.card_empty, Nat.cast_zero]; exact le_trans (by positivity) hM1
    · have : A.card ≤ (A + A).card := Finset.card_le_card_add_left h
      have : (A.card : ℝ) ≤ (A + A).card := by exact_mod_cast this
      linarith
  have hM0 : 0 ≤ M := le_trans hn0 hnM
  -- positive and negative parts, moved into the positive reals
  set P : Finset ℝ := (A.filter (fun z => 0 < z)).image (fun z : ℤ => (z : ℝ)) with hP
  set N : Finset ℝ := (A.filter (fun z => z < 0)).image (fun z : ℤ => -(z : ℝ)) with hN
  have hPpos : ∀ a ∈ P, 0 < a := by
    intro a ha
    obtain ⟨z, hz, rfl⟩ := Finset.mem_image.mp ha
    have := (Finset.mem_filter.mp hz).2
    exact_mod_cast this
  have hNpos : ∀ a ∈ N, 0 < a := by
    intro a ha
    obtain ⟨z, hz, rfl⟩ := Finset.mem_image.mp ha
    have := (Finset.mem_filter.mp hz).2
    have : (z : ℝ) < 0 := by exact_mod_cast this
    linarith
  have hPcard : P.card = (A.filter (fun z => 0 < z)).card :=
    Finset.card_image_of_injective _ Int.cast_injective
  have hNcard : N.card = (A.filter (fun z => z < 0)).card :=
    Finset.card_image_of_injective _ (fun x y h => by simpa using h)
  have hsplit : A.card ≤ P.card + N.card + 1 := by
    rw [hPcard, hNcard]
    have h1 := Finset.card_filter_add_card_filter_not (s := A) (fun z : ℤ => 0 < z)
    have h2 : (A.filter (fun z : ℤ => ¬ 0 < z)) ⊆ insert 0 (A.filter (fun z => z < 0)) := by
      intro z hz
      rw [Finset.mem_filter] at hz
      rw [Finset.mem_insert, Finset.mem_filter]
      rcases lt_or_eq_of_le (not_lt.mp hz.2) with h | h
      · exact Or.inr ⟨hz.1, h⟩
      · exact Or.inl h
    have h3 := Finset.card_le_card h2
    have h4 := Finset.card_insert_le (0 : ℤ) (A.filter (fun z => z < 0))
    omega
  -- sums and products of the parts sit inside images of A + A and A * A
  have hPadd : ((P + P).card : ℝ) ≤ M := by
    have : (P + P) ⊆ (A + A).image (fun z : ℤ => (z : ℝ)) := by
      intro x hx
      obtain ⟨a, ha, b, hb, rfl⟩ := Finset.mem_add.mp hx
      obtain ⟨a', ha', rfl⟩ := Finset.mem_image.mp ha
      obtain ⟨b', hb', rfl⟩ := Finset.mem_image.mp hb
      exact Finset.mem_image.mpr ⟨a' + b', Finset.add_mem_add (Finset.mem_filter.mp ha').1
        (Finset.mem_filter.mp hb').1, by push_cast; ring⟩
    have h := (Finset.card_le_card this).trans Finset.card_image_le
    have : ((P + P).card : ℝ) ≤ (A + A).card := by exact_mod_cast h
    linarith
  have hPmul : ((P * P).card : ℝ) ≤ M := by
    have : (P * P) ⊆ (A * A).image (fun z : ℤ => (z : ℝ)) := by
      intro x hx
      obtain ⟨a, ha, b, hb, rfl⟩ := Finset.mem_mul.mp hx
      obtain ⟨a', ha', rfl⟩ := Finset.mem_image.mp ha
      obtain ⟨b', hb', rfl⟩ := Finset.mem_image.mp hb
      exact Finset.mem_image.mpr ⟨a' * b', Finset.mul_mem_mul (Finset.mem_filter.mp ha').1
        (Finset.mem_filter.mp hb').1, by push_cast; ring⟩
    have h := (Finset.card_le_card this).trans Finset.card_image_le
    have : ((P * P).card : ℝ) ≤ (A * A).card := by exact_mod_cast h
    linarith
  have hNadd : ((N + N).card : ℝ) ≤ M := by
    have : (N + N) ⊆ (A + A).image (fun z : ℤ => -(z : ℝ)) := by
      intro x hx
      obtain ⟨a, ha, b, hb, rfl⟩ := Finset.mem_add.mp hx
      obtain ⟨a', ha', rfl⟩ := Finset.mem_image.mp ha
      obtain ⟨b', hb', rfl⟩ := Finset.mem_image.mp hb
      exact Finset.mem_image.mpr ⟨a' + b', Finset.add_mem_add (Finset.mem_filter.mp ha').1
        (Finset.mem_filter.mp hb').1, by push_cast; ring⟩
    have h := (Finset.card_le_card this).trans Finset.card_image_le
    have : ((N + N).card : ℝ) ≤ (A + A).card := by exact_mod_cast h
    linarith
  have hNmul : ((N * N).card : ℝ) ≤ M := by
    have : (N * N) ⊆ (A * A).image (fun z : ℤ => (z : ℝ)) := by
      intro x hx
      obtain ⟨a, ha, b, hb, rfl⟩ := Finset.mem_mul.mp hx
      obtain ⟨a', ha', rfl⟩ := Finset.mem_image.mp ha
      obtain ⟨b', hb', rfl⟩ := Finset.mem_image.mp hb
      exact Finset.mem_image.mpr ⟨a' * b', Finset.mul_mem_mul (Finset.mem_filter.mp ha').1
        (Finset.mem_filter.mp hb').1, by push_cast; ring⟩
    have h := (Finset.card_le_card this).trans Finset.card_image_le
    have : ((N * N).card : ℝ) ≤ (A * A).card := by exact_mod_cast h
    linarith
  have hPb := es_pos_part P M hPadd hPmul (card_mul_mul_card_add_sq_ge P hPpos)
  have hNb := es_pos_part N M hNadd hNmul (card_mul_mul_card_add_sq_ge N hNpos)
  -- the larger part has at least a third of the elements, or A has at most one element
  have key : (A.card : ℝ) ^ 7 ≤ 8 ^ 6 * M ^ 6 := by
    set m := max P.card N.card with hm
    have hmb : (m : ℝ) ^ 7 ≤ 64 * M ^ 6 := by
      rcases max_choice P.card N.card with h | h
      · rw [hm, h]; exact hPb
      · rw [hm, h]; exact hNb
    have hnm : A.card ≤ 2 * m + 1 := by
      have := le_max_left P.card N.card
      have := le_max_right P.card N.card
      omega
    have hM6 : 0 ≤ M ^ 6 := by positivity
    rcases Nat.eq_zero_or_pos m with h0 | hmpos
    · have hn1 : A.card ≤ 1 := by omega
      have hn1' : (A.card : ℝ) ≤ 1 := by exact_mod_cast hn1
      have h7 : (A.card : ℝ) ^ 7 ≤ (A.card : ℝ) ^ 6 := by
        rw [pow_succ]
        nlinarith [pow_nonneg hn0 6]
      have h6 : (A.card : ℝ) ^ 6 ≤ M ^ 6 := pow_le_pow_left₀ hn0 hnM 6
      nlinarith
    · have h3 : (A.card : ℝ) ≤ 3 * m := by
        have : A.card ≤ 3 * m := by omega
        exact_mod_cast this
      have h7 : (A.card : ℝ) ^ 7 ≤ (3 * (m : ℝ)) ^ 7 := pow_le_pow_left₀ hn0 h3 7
      have : (3 * (m : ℝ)) ^ 7 = 3 ^ 7 * (m : ℝ) ^ 7 := by ring
      nlinarith
  have hpow : ((1 : ℝ) / 8 * (A.card : ℝ) ^ (1 + (1 : ℝ) / 6)) ^ 6 = (A.card : ℝ) ^ 7 / 8 ^ 6 := by
    rw [mul_pow, ← Real.rpow_natCast ((A.card : ℝ) ^ (1 + (1 : ℝ) / 6)) 6,
      ← Real.rpow_mul hn0]
    norm_num
    ring
  refine le_of_pow_le_pow_left₀ (n := 6) (by norm_num) hM0 ?_
  rw [hpow, div_le_iff₀ (by norm_num)]
  linarith

/-! The card's worked counts. -/

/-- The geometric run 1, 2, 4, …, 512 (the powers 2⁰ to 2⁹). -/
def geomRun : Finset ℕ := (Finset.range 10).image (2 ^ ·)

-- 55 sums, 19 products, additive energy 190, multiplicative energy 670.
example : (geomRun + geomRun).card = 55 := by decide +kernel
example : (geomRun * geomRun).card = 19 := by decide +kernel
example : geomRun.addEnergy geomRun = 190 := by decide +kernel
example : geomRun.mulEnergy geomRun = 670 := by decide +kernel

-- The run 1 to 10: 19 sums (2 to 20), 42 products, energies 670 and 278.
example : (Finset.Icc 1 10 + Finset.Icc 1 10 : Finset ℕ).card = 19 := by decide +kernel
example : (Finset.Icc 1 10 * Finset.Icc 1 10 : Finset ℕ).card = 42 := by decide +kernel
example : (Finset.Icc 1 10 : Finset ℕ).addEnergy (Finset.Icc 1 10) = 670 := by decide +kernel
example : (Finset.Icc 1 10 : Finset ℕ).mulEnergy (Finset.Icc 1 10) = 278 := by decide +kernel

-- The mixed set 1, 2, 3, 4, 6, 8: 13 sums, 15 products, energies 114 and 106.
example : (({1, 2, 3, 4, 6, 8} : Finset ℕ) + {1, 2, 3, 4, 6, 8}).card = 13 := by decide +kernel
example : (({1, 2, 3, 4, 6, 8} : Finset ℕ) * {1, 2, 3, 4, 6, 8}).card = 15 := by decide +kernel
example : ({1, 2, 3, 4, 6, 8} : Finset ℕ).addEnergy {1, 2, 3, 4, 6, 8} = 114 := by decide +kernel
example : ({1, 2, 3, 4, 6, 8} : Finset ℕ).mulEnergy {1, 2, 3, 4, 6, 8} = 106 := by decide +kernel

-- Closed forms at n = 10: n(n+1)/2 = 55, 2n − 1 = 19, 2n² − n = 190, (2n³ + n)/3 = 670.
example : 10 * 11 / 2 = 55 ∧ 2 * 10 - 1 = 19 ∧ 2 * 10 ^ 2 - 10 = 190 ∧
    (2 * 10 ^ 3 + 10) / 3 = 670 := by decide +kernel

-- Solymosi at ten numbers: ⌈log₂ 10⌉ = 4, and 19 × 55² = 57,475 is at least 10⁴ / 16 = 625.
example : Nat.clog 2 10 = 4 := by decide +kernel
example : 19 * 55 ^ 2 = 57475 ∧ 10 ^ 4 / (4 * 4) = 625 ∧ 625 ≤ 57475 := by decide +kernel

-- What breaks: all 13 remainders mod 13 give 13 sums and 13 products, no growth.
example : ((Finset.univ : Finset (ZMod 13)) + Finset.univ).card = 13 := by decide +kernel
example : ((Finset.univ : Finset (ZMod 13)) * Finset.univ).card = 13 := by decide +kernel

-- What breaks: ordered pairs from ten numbers number 100, not the 55 sums.
example : ((Finset.range 10) ×ˢ (Finset.range 10)).card = 100 := by decide +kernel

#print axioms card_add_ge_card_pow_four_div_addEnergy
#print axioms card_mul_mul_card_add_sq_ge
#print axioms exists_max_card_add_card_mul_ge
```

**Checked 2026-11-15 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'sp_between' depends on axioms: [propext, Classical.choice, Quot.sound]
'sp_region' depends on axioms: [propext, Classical.choice, Quot.sound]
'sp_nb' depends on axioms: [propext, Classical.choice, Quot.sound]
'sp_disj' depends on axioms: [propext, Classical.choice, Quot.sound]
'sp_r_le_one' depends on axioms: [propext, Classical.choice, Quot.sound]
'sp_r_le_card' depends on axioms: [propext, Classical.choice, Quot.sound]
'sp_class' depends on axioms: [propext, Classical.choice, Quot.sound]
'sp_energy_le' depends on axioms: [propext, Classical.choice, Quot.sound]
'sp_energy_bound' depends on axioms: [propext, Classical.choice, Quot.sound]
'es_sq_le_two_pow' depends on axioms: [propext, Classical.choice, Quot.sound]
'es_clog_sq_le' depends on axioms: [propext, Classical.choice, Quot.sound]
'es_pos_part' depends on axioms: [propext, Classical.choice, Quot.sound]
'card_add_ge_card_pow_four_div_addEnergy' depends on axioms: [propext, Classical.choice, Quot.sound]
'card_mul_mul_card_add_sq_ge' depends on axioms: [propext, Classical.choice, Quot.sound]
'exists_max_card_add_card_mul_ge' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it. The asserts are pinned to the card's sets, so some changes stop the program.
> - **Powers of 3.** Set `G` to `[3 ** i for i in range(10)]`. Guess: does the ratio matter? It does not: still 55 sums and 19 products, by base-3 digits, and every assert passes.
> - **A longer run.** Set `P` to `list(range(1, 21))`. Guess the sums and products: 39 and 152. The first assert stops it, since it expects 19.
> - **Seven numbers.** Change the 6 in the search to 7. The smallest larger side grows to 18, first reached by 1, 2, 3, 4, 6, 8, 12, and the last assert stops it.
> - **Break the energy.** Add `and a != b` to the test in `energy_brute`. The two roads to the energy disagree and the second assert stops it.

---

## The usual mistake

> [!warning]
> **Reading the energy bound as a ceiling.** $`\lvert A\rvert^4 / E_+(A)`$ is a floor on the sumset, never a cap. For the powers of 2 it gives 52.6, and the sumset is 55. Average-of-squares arguments only push one way.
>
> - **Counting ordered pairs as the sumset.** Ten numbers make 100 ordered pairs but at most 55 different sums, since a + b = b + a.
> - **Leaving out the dull quadruples.** Quadruples with {a, b} = {c, d} always count. Without them the powers of 2 have energy 0, not 190.
> - **Expecting growth in wrap-round arithmetic.** All 13 remainders mod 13 give 13 sums and 13 products. The Z mod p version (Bourgain, Katz and Tao, 2004) needs A to stay well short of all p remainders.
> - **Taking the conjecture as proved.** The proved exponent is about 4/3, not 2. For six numbers, Solymosi's floor is 3.78 while the smallest found among sets from 1 to 24 is 15.

---

## Where you meet it in real life

- **Randomness for computers.** A version of the theorem in Z mod p, proved by Bourgain, Katz and Tao in 2004, underlies extractors: procedures that turn several weakly random sources into nearly perfect random bits.
- **The multiplication table.** The 100 × 100 table holds only 2,906 different products out of 10,000 cells. Kevin Ford found the order of magnitude of how fast this share falls, and it rests on how many prime factors a typical number has ([Typical numbers have about log log n distinct prime factors](01-hardy-ramanujan-and-typical-prime-factor-counts.md)).
- **Finding structure in large sets.** A set with high additive energy hides a large piece with few sums (the Balog–Szemerédi–Gowers theorem). Gowers used this in his proof of Szemerédi's theorem, outlined in [Long progressions](05-szemeredi-and-green-tao-in-outline.md).
- **Geometry of points and lines.** Elekes proved his 5/4 by counting how often points meet lines. Solymosi's proof, in outline above, sorts lines through the origin by slope.

> **Say it back**
> The sumset of A collects every a + b, and the product set every ab. Powers of 2 multiply into 19 values but add into 55; the run 1 to 10 adds into 19 but multiplies into 42. The additive energy counts quadruples with a + b = c + d, and an average-of-squares step proves the sumset is at least the size to the fourth over the energy. Erdős and Szemerédi proved that no set of whole numbers is small for both operations, Solymosi's version gives exponent 4/3, and exponent 2 is conjectured.

---

## What this builds on

- [Inclusion-exclusion for any number of sets](../../04-Combinatorics%20and%20graphs/04-Inclusion-Exclusion%20and%20Pigeonhole/01-inclusion-exclusion-for-n-sets.md): the exact count of distinct values among overlapping groups. The sumset is such a count, of 100 pair sums sharing values, and too many overlaps to list for a large set. The energy keeps only the pairs-of-pairs layer, and the average-of-squares step turns that one layer into a guaranteed floor.

## Where this goes next

- [Erdos problems](07-erdos-problems-and-computer-search.md): the Erdős–Szemerédi conjecture is one of many Erdős problems where a computer search, like the one on this card, gives evidence and sometimes a proof.

Other cards on this shelf: [Typical numbers have about log log n distinct prime factors](01-hardy-ramanujan-and-typical-prime-factor-counts.md), [Erdos-Kac](02-erdos-kac-theorem.md), [Equidistribution](03-equidistribution-and-weyls-criterion.md), [Three distances](04-three-distance-theorem.md) and [Long progressions](05-szemeredi-and-green-tao-in-outline.md).

The question this card leaves open: can the exponent 4/3 be pushed all the way to 2, as the search on small sets suggests?

---

## Sources

Verified 2026-11-15: every link below resolves to the publisher's page.

- Erdős, Paul, and Endre Szemerédi. "On sums and products of integers." In *Studies in Pure Mathematics*, Birkhäuser, 1983, 213–218. [DOI 10.1007/978-3-0348-5438-2_19](https://doi.org/10.1007/978-3-0348-5438-2_19). The theorem with exponent 1 + δ, and the conjecture.
- Elekes, György. "On the number of sums and products." *Acta Arithmetica* 81, no. 4 (1997): 365–367. [DOI 10.4064/aa-81-4-365-367](https://doi.org/10.4064/aa-81-4-365-367). Exponent 5/4 for real numbers, by counting points on lines.
- Solymosi, József. "Bounding multiplicative energy by the sumset." *Advances in Mathematics* 222 (2009): 402–408. [DOI 10.1016/j.aim.2009.04.006](https://doi.org/10.1016/j.aim.2009.04.006). The explicit bound on this card and the slope argument in Step 4.
- Rudnev, Misha, and Sophie Stevens. "An update on the sum-product problem." *Mathematical Proceedings of the Cambridge Philosophical Society* 173 (2022): 411–430. [DOI 10.1017/S0305004121000633](https://doi.org/10.1017/S0305004121000633). The exponent 4/3 + 2/1167.
- Tao, Terence, and Van H. Vu. *Additive Combinatorics*. Cambridge University Press, 2006. [DOI 10.1017/CBO9780511755149](https://doi.org/10.1017/CBO9780511755149). Additive energy, the Cauchy–Schwarz bound of Step 3, and sum-product in fields.
