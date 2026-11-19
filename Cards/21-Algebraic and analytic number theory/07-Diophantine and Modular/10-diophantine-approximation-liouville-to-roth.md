# Chasing an algebraic number with fractions: how close you can get, from Liouville to Roth

[Syllabus](../../../SYLLABUS.md) → [Algebraic and analytic number theory](../README.md) → [Diophantine and Modular](../README.md#s07) → Chasing an algebraic number with fractions

---

## General Overview

In 1851 Joseph Liouville wrote down this decimal:

```
L = 0.110001000000000000000001000...
```

It has a 1 at places 1, 2, 6, 24, 120, … after the point, and 0 everywhere else. Those places are the factorials: 1, 1 × 2, 1 × 2 × 3, and so on. The gaps between the 1s grow very fast.

Cut L after its third 1 and you get the fraction 110001/1,000,000. Its error, the distance to L, is $`10^{-24}`$: one over the denominator to the fourth power. Cut after the fourth 1 and the error is one over the denominator to the fifth power. The pattern never stops.

Compare the cube root of 2, about 1.259921. Of all fractions with a denominator up to a million, the closest is 1054215/836731. Its error is only about a third of one over the denominator squared.

This card explains that difference. An **algebraic number** is a root of a polynomial with whole-number coefficients, such as $`x^3 - 2`$. Liouville proved that fractions cannot crowd too close to an algebraic number. L is crowded far closer than that, so it is not algebraic. It is **transcendental**: no polynomial with whole-number coefficients has it as a root ([Minimal polynomials](../05-Fields%20and%20Galois%20Theory/02-minimal-polynomials-and-conjugates.md)). L was among the first numbers ever proved transcendental.

The same question also decides whether some equations in whole numbers have finitely many solutions. The card ends on that use.

**Every irrational number has endless fractions within $`1/q^2`$; an algebraic number of degree d keeps every fraction p/q at least $`c/q^d`$ away, and Roth cut that d down to 2 plus any small margin; Liouville's L has fractions closer than any such bound, so it is transcendental.**

**What kind of fact this is:** Liouville's bound and the transcendence of L are theorems, proved on this card in Why it works. Dirichlet's bound is proved in a fold. Roth's theorem (1955), Baker's effective bounds (1964 and 1968) and Bennett's bound (1997) are theorems stated with their sources, not proved here. The code's search up to a denominator of a million is evidence, never proof.

### The picture: how fast the error shrinks

```
Exponent seen: the error equals 1/q raised to this power.  One block = 0.25.

L cut at q = 10           1.999957  ████████
L cut at q = 10^2         3.000000  ████████████
L cut at q = 10^6         4.000000  ████████████████
L cut at q = 10^24        5.000000  ████████████████████
cbrt 2, q = 4,309         2.020185  ████████
cbrt 2, q = 71,691        2.013559  ████████
cbrt 2, q = 836,731       2.077937  ████████
```

The fractions cut from L get better without limit: exponent 2, 3, 4, 5, and n + 1 at the n-th cut. The best fractions for the cube root of 2 stay near exponent 2, as Roth's theorem says they must.

---

## The formula

Notation first, in words. Throughout this card q is a denominator, never a modulus. The **degree** d of an algebraic number α ("alpha") is the degree of its minimal polynomial: the simplest whole-number polynomial with α as a root. The cube root of 2 has degree 3.

**Liouville's bound (1844).** For every real algebraic number α of degree d there is a positive number c(α) such that

```math
\left|\alpha - \frac{p}{q}\right| \ge \frac{c(\alpha)}{q^{d}} \quad \text{for every fraction } \frac{p}{q} \ne \alpha \text{ with } q \ge 1
```

**Read it aloud:** the distance from α to any other fraction is at least a fixed constant divided by the denominator to the power d.

For the cube root of 2, d = 3. The general proof gives c = 0.065267, and an exact identity for this number sharpens it to c = 0.104800 (Step 2).

**Liouville's constant.** L is the sum of $`10^{-k!}`$ over k = 1, 2, 3, …:

```math
L = \sum_{k=1}^{\infty} 10^{-k!} = 0.110001000000000000000001000\ldots
```

**Read it aloud:** put a 1 at decimal place 1!, 2!, 3!, … and a 0 everywhere else.

**The irrationality exponent.** This card introduces one new measure. The **irrationality exponent** μ(α) ("mu of alpha") is the largest power that still allows endless good fractions:

```math
\mu(\alpha) = \sup\left\{\mu : \left|\alpha - \frac{p}{q}\right| < \frac{1}{q^{\mu}} \text{ for infinitely many fractions } \frac{p}{q} \ne \alpha\right\}
```

**Read it aloud:** μ is the cut-off power: below it, infinitely many fractions get closer than one over q to that power; above it, only finitely many do. "sup" means the least number at or above every member of the set.

**Roth's theorem (1955).** For every irrational algebraic number α and every ε > 0 ("epsilon", any small positive margin),

```math
\left|\alpha - \frac{p}{q}\right| < \frac{1}{q^{2+\varepsilon}} \quad \text{has only finitely many solutions } \frac{p}{q}
```

**Read it aloud:** past some point, no fraction gets closer to an algebraic number than one over q to the power two-and-a-bit. So μ(α) = 2 for every irrational algebraic α.

The ladder of results, all on this card:

| Number | Its exponent μ | Why |
| --- | --- | --- |
| a fraction, such as 1/3 | 1 | any other fraction differs by at least $`1/(3q)`$ |
| any irrational | at least 2 | Dirichlet's bound, proved in Step 1 |
| algebraic of degree d | at most d | Liouville's bound, Step 2 |
| irrational algebraic | exactly 2 | Roth's theorem, Step 5 |
| Liouville's L | infinite | Step 3 |

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $`\alpha`$ | the number being chased | $`\sqrt[3]{2}`$ = 1.259921049895 | — |
| $`p/q`$ | a fraction: p whole, q a whole denominator of at least 1 | 1054215/836731 | — |
| $`d`$ | the degree of $`\alpha`$ | 3 | Liouville's bound gets weaker |
| $`f`$ | the minimal polynomial, with whole-number coefficients | $`x^3 - 2`$ | — |
| $`c(\alpha)`$ | Liouville's constant for $`\alpha`$: the fixed number in the bound | 0.065267 from the general proof; 0.104800 from the exact identity | the bound gets stronger |
| $`M`$, $`\xi`$ | the largest slope of f within 1 of $`\alpha`$, and the point ("xi") where the slope is read | 15.321729; the exact identity uses the largest chord slope, 9.541966 | c(α) = 1/M falls |
| $`L`$, $`S`$ | Liouville's constant, with 1s at the factorial places; S has 1s at places 2, 4, 8, … | 0.110001…; 0.0101000100… | — |
| $`n`$, $`q_n`$ | how many 1s are kept, and the cut fraction's denominator $`10^{n!}`$ | n = 3, $`q_3 = 10^6`$ | the error falls like $`1/q_n^{n+1}`$ |
| $`\mu(\alpha)`$ | the irrationality exponent | 2 for $`\sqrt[3]{2}`$; infinite for L | fractions crowd closer |
| $`\varepsilon`$ | any small positive margin above 2 | 0.5 in Bennett's bound | fewer fractions qualify |
| $`x`$, $`y`$, $`m`$ | whole numbers in the equation $`x^3 - 2y^3 = m`$ | m = 1 | Bennett's search box grows like $`m^2`$ |
| $`F`$, $`b_i`$, $`\alpha_i`$, $`B`$, $`C`$ | Step 6: a binary form; whole multipliers; algebraic numbers; the multipliers' size limit; Baker's computable exponent | $`x^3 - 2y^3`$; 12 and −19; 3 and 2 | the lower bound $`B^{-C}`$ falls |

### When it holds

- **α is algebraic.** Drop this and the bound fails: L has no c(α) for any d, as Step 3 shows.
- **The fraction is not α itself.** A rational α is algebraic of degree 1, and its own fraction is at distance 0.
- **Roth needs ε > 0.** At ε = 0 the count is infinite: Dirichlet gives every irrational endless fractions within $`1/q^2`$.
- **Roth gives no search limit.** Its proof bounds how many exceptions there are, not how large they are. Baker's methods give a limit you can compute.

---

## Why it works

### Step 0: the idea

An algebraic number satisfies a whole-number polynomial f. Plug a fraction p/q into f and clear the denominators. The result is a whole number, and it is not 0. A nonzero whole number is at least 1 in size. So f(p/q) cannot be tiny, so p/q cannot be very close to the root. Liouville's L is built to break this: its fractions get closer than any such bound allows.

### Step 1: every irrational has fractions within $`1/q^2`$

The [Continued fractions](../../02-Number%20theory/07-For%20the%20Curious/05-continued-fractions-and-leap-years.md) card shows that cutting a continued fraction short gives the best cheap fractions, its convergents. Each convergent p/q of an irrational number lands within $`1/q^2`$ of it. That is the floor every irrational number reaches.

For the cube root of 2, the code finds all 14 convergents with denominator up to a million, two ways. Each has $`q^2`$ times the error below 1.

<details>
<summary>Detailed proof: Dirichlet's bound by pigeonholes</summary>

Take any irrational α and any whole number N. Look at the fractional parts of 0, α, 2α, …, Nα. That is N + 1 numbers between 0 and 1.

Cut the interval from 0 to 1 into N equal pieces. Two of the N + 1 numbers share a piece, say those of $`i\alpha`$ and $`j\alpha`$ with i < j. Their difference is within 1/N of a whole number p:

$`\displaystyle |(j - i)\alpha - p| < \frac{1}{N}`$

Put q = j − i, which is at most N. Divide by q:

$`\displaystyle \left|\alpha - \frac{p}{q}\right| < \frac{1}{qN} \le \frac{1}{q^2}`$

Letting N grow gives infinitely many such fractions, because α is irrational and no single fraction stays within 1/(qN) for every N.

</details>

### Step 2: Liouville's bound

Let α have degree d and minimal polynomial f, scaled to whole-number coefficients. Take a fraction p/q that is not α.

1. **f(p/q) is not 0.** If d is at least 2, f has no rational root: a root r would make x − r a factor of f, but f cannot be split. If d = 1, its only root is α itself.
2. **f(p/q) is at least $`1/q^d`$ in size.** Multiply f(p/q) by $`q^d`$. Every term becomes a whole number, so $`q^d f(p/q)`$ is a nonzero whole number.
3. **f is not steep near α.** Suppose p/q is within 1 of α. Let M be the largest size of the slope f′ between α − 1 and α + 1. The mean value theorem (a chord's slope equals the curve's slope somewhere between its ends) gives a point ξ between α and p/q with $`f(p/q) - f(\alpha) = f'(\xi)(p/q - \alpha)`$. Since f(α) = 0, this gives $`|f(p/q)| \le M\,|\alpha - p/q|`$.
4. **Combine.** $`1/q^d \le M\,|\alpha - p/q|`$, so $`|\alpha - p/q| \ge 1/(Mq^d)`$. If p/q is more than 1 away, the bound holds anyway. So c(α) = the smaller of 1 and 1/M.

For the cube root of 2 the slope step is exact algebra. With $`f = x^3 - 2`$:

```math
\left|\sqrt[3]{2} - \frac{p}{q}\right| = \frac{|p^3 - 2q^3|}{q^3\left(\alpha^2 + \alpha\frac{p}{q} + \frac{p^2}{q^2}\right)}
```

The top is a nonzero whole number, so at least 1. The bracket is the slope of the chord of f from p/q to α. Within 1 of α it is at most $`3\alpha^2 + 3\alpha + 1`$ = 9.541966, so the exact identity replaces M by this largest chord slope and gives c = 0.104800. The general proof uses the largest slope of f itself, $`M = 3(\alpha + 1)^2`$ = 15.321729, and gets only c = 0.065267. Over all q up to a million, the smallest $`q^3`$ times the error is 0.259921, at 1/1. The code measures every error with this identity, so no digits are lost to subtraction.

### Step 3: Liouville's constant is transcendental

Keep the first n 1s of L. That is a fraction $`p_n/q_n`$ with $`q_n = 10^{n!}`$. What is left starts with a 1 at place (n + 1)!. Each later 1 sits at least one place further right than the one before, so the tail is at most $`10^{-(n+1)!}`$ times 1 + 1/10 + 1/100 + …, which is 10/9. So the error is caught between two powers:

```math
10^{-(n+1)!} < L - \frac{p_n}{q_n} < 2 \cdot 10^{-(n+1)!} = \frac{2}{q_n^{\,n+1}}
```

**Read it aloud:** cutting after the n-th 1 leaves an error just above one over the denominator to the power n + 1.

Now suppose L were algebraic, of some degree d. Liouville's bound gives a fixed c > 0 with $`c/q_n^d \le 2/q_n^{n+1}`$, that is

```math
c \le \frac{2}{q_n^{\,n+1-d}} = 2 \cdot 10^{-n!\,(n+1-d)}
```

Once n passes d, the right side drops toward 0 as n grows. No fixed positive c fits under it. So L has no degree: it is transcendental. The same step with d = 1 shows L is not a fraction.

The code prints the case d = 3. The base-10 log of $`q^3`$ times the error runs 1.000043, 0.000000, −6, −48 over the first four cuts. A cube-root-like c would have to be below $`10^{-48}`$, and the next cut pushes it lower still.

### Step 4: why the gaps must grow so fast

The proof needs the gap after each 1 to dwarf everything before it. Gaps that only double are not enough. The number S = 0.0101000100000001… has 1s at places 2, 4, 8, 16, …. Its cuts have exponent 2.000000 from the second on (1.999978 at the first): no better than Dirichlet's floor for every irrational. Liouville's argument proves nothing about S. S is in fact transcendental (Mahler, 1929), but that needs a different method.

### Step 5: from Liouville to Roth

Liouville's exponent d is weak for large degree. A run of results pushed it down. For degree 3 the code prints each:

| Who, year | Exponent allowed for degree d | For d = 3 |
| --- | --- | --- |
| Liouville, 1844 | d | 3 |
| Thue, 1909 | d/2 + 1 | 2.5 |
| Siegel, 1921 | about $`2\sqrt{d}`$ for large d | — |
| Dyson, 1947 | $`\sqrt{2d}`$ | 2.449490 |
| Roth, 1955 | 2 + ε, any ε > 0 | 2 + ε |

Roth's proof builds a polynomial in many variables that vanishes to high order at (α, α, …, α). If many very good fractions existed, the polynomial would have to vanish at a point of fractions too, and a zero estimate (Roth's lemma) forbids that. The proof runs about twenty pages (Roth, 1955). It is not given here.

Roth's bound cannot be cut further, since Dirichlet reaches exponent 2 for every irrational. The 14 convergents of the cube root of 2 show both sides: their exponents stay above 2, and drift down toward 2 as q grows.

### Step 6: Baker's effective bounds

Roth's proof is **ineffective**: it shows the exceptions are finite in number, but gives no way to compute how large the last one is. A search cannot fill the gap, because it proves nothing past its end.

Alan Baker fixed this in two stages.

- **1964, for the cube root of 2.** $`|\sqrt[3]{2} - p/q| > 10^{-6}\,q^{-2.955}`$ for every fraction. The exponent is below Liouville's 3, and the constant is written down.
- **1966 to 1968, in general.** His theorem on **linear forms in logarithms** gives a computable lower bound for a nonzero sum $`b_1\log\alpha_1 + \dots + b_n\log\alpha_n`$, with algebraic $`\alpha_i`$ and whole $`b_i`$ of size at most B. In the sharpened form of the 1970s the sum is larger than $`B^{-C}`$, with C computable. From this he gave a computable limit on every solution of a Thue equation: F(x, y) = m with F a **binary form** (every term of the same total degree, like $`x^3 - 2y^3`$) of degree 3 or more that does not factor over the fractions.

Michael Bennett (1997) sharpened the cube root of 2 to $`|\sqrt[3]{2} - p/q| > 1/(4q^{2.5})`$. That bound is small enough to solve equations by hand.

**Solving $`x^3 - 2y^3 = 1`$.** Take a solution with y ≠ 0 and use the identity from Step 2, with x/y in place of p/q.

1. The top is $`|m| = 1`$, and the bracket is at least $`3\alpha^2/4`$ for every value of x/y. So the error is at most $`|m|/(|y|^3 \cdot 3\alpha^2/4)`$.
2. Bennett says the error is at least $`1/(4|y|^{2.5})`$.
3. Put the two together: $`\sqrt{|y|} \le 16|m|/(3\alpha^2)`$, so $`|y| \le 11`$.

A search of y from −11 to 11 finds exactly (1, 0) and (−1, −1). That is a complete proof. A blind search out to |y| = 100,000 finds the same two, but proves nothing beyond its edge.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| cut L after its third 1 | 0.110001 = 110001/10^6 | $`q_3 = 10^6`$ |
| the error | the next 1 is at place 4! = 24 | $`10^{-24}`$ × 1.000000000000 |
| exponent seen | 24 ÷ 6 | 4.000000 |
| cut after the fourth 1 | next 1 at place 5! = 120, q = $`10^{24}`$ | exponent 5.000000 |
| test degree 3 at n = 3 | $`q^3`$ × error = $`10^{18} \times 10^{-24}`$ | $`10^{-6}`$ |
| test degree 3 at n = 4 | $`10^{72} \times 10^{-120}`$ | $`10^{-48}`$ |
| the cube root of 2's best | 1054215/836731, $`q^2`$ × error | 0.345471 |
| its exponent | −log(error) ÷ log(q) | 2.077937 |
| Liouville's c for it, from the exact identity | 1/(3α² + 3α + 1) | **0.104800** |

**L's fractions beat every power of q, while the cube root of 2's best stay near the square: L is transcendental, and the cube root of 2 behaves as Roth says an algebraic number must.**

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Gaps that only double, S = 0.0101000100… | exponent 2 at every cut from the second (1.999978 at the first) | No better than Dirichlet's floor; Liouville's argument needs gaps that outgrow every power |
| Roth with ε = 0 | 14 convergents within $`1/q^2`$ up to q = 10^6, and more without end | Dirichlet: exponent 2 is always reached infinitely often |
| Exponent read off one small fraction | 5/4 gives 3.327646, seemingly beating Liouville's 3 | The constant c matters at small q; $`q^3`$ × error is 0.634947 there, far above 0.104800 |

The code prints all three.

---

## Code, from first principles, and it actually runs

The code takes three roads. Road 1 writes Liouville's constant as an exact list of decimal digits and subtracts each cut fraction digit by digit. Road 2 checks each error against the geometric-series bound of Step 3. Road 3 tries every denominator up to a million for the cube root of 2 and keeps each new best fraction. It matches that list against the continued fraction built by Lagrange's method, which shifts the polynomial $`x^3 - 2`$ and reads off whole parts, sharing no step with the search. The code also checks Liouville's, Bennett's and Baker's bounds up to a million, recomputes both of Liouville's constants for the cube root of 2 by sampling the slopes, solves $`x^3 - 2y^3 = 1`$ inside Bennett's box (checked against Bennett's bound tried y by y), and lists whole-number points on the shelf's curve $`y^2 = x^3 - x`$. The imports are `log`, `log10` and `sqrt`; Rust uses its own.

### Python

```python
# Liouville to Roth -- the check behind the card.  Standard library only, no imports
# but math.log, math.log10 and math.sqrt.  Road 1: exact decimal digits of Liouville's constant.
# Road 2: the geometric-series bound of Why it works.  Road 3: every q up to 10^6
# against the continued fraction of the cube root of 2, built by Lagrange's method.
from math import log, log10, sqrt

def fact(n):
    return 1 if n == 0 else n * fact(n - 1)

def digits(places, length):        # 0.d1 d2 ... with a 1 at each listed place
    d = [0] * (length + 1)
    for k in places:
        d[k] = 1
    return d

def first_nonzero(x, y):           # x - y for two digit lists with x > y: place, mantissa
    diff, borrow = [0] * len(x), 0
    for i in range(len(x) - 1, 0, -1):
        v = x[i] - y[i] - borrow
        borrow = 1 if v < 0 else 0
        diff[i] = v + 10 * borrow
    j = next(i for i in range(1, len(x)) if diff[i])
    return j, int("".join(map(str, diff[j:j + 15])).ljust(15, "0")) / 1e14

def truncations(gaps, nmax, length, d_show):
    full = digits(gaps, length)
    rows = []
    for n in range(1, nmax + 1):
        j, m = first_nonzero(full, digits(gaps[:n], length))
        logq = gaps[n - 1]                         # q = 10^(n-th place)
        expo = (j - log10(m)) / logq
        rows.append((n, logq, j, m, expo, d_show * logq - j + log10(m)))
        tail = sum(10.0 ** (gaps[n] - g) for g in gaps[n + 1:])
        assert j == gaps[n] and abs(m - (1 + tail)) < 1e-12   # road 2 agrees
        assert 1 <= m < 2                                       # error < 2 / q^(n+1)
    return rows

print("Liouville's constant L = 0.1100010000...: a 1 at places 1!, 2!, 3!, ...")
L = digits([fact(k) for k in range(1, 6)], 130)
print("L to 30 places: 0." + "".join(map(str, L[1:31])))
print("n | q = 10^(n!) | L - p/q = 10^-j x m | exponent | log10(q^3 x error)")
rowsL = truncations([fact(k) for k in range(1, 6)], 4, 130, 3)
for n, logq, j, m, e, l3 in rowsL:
    print(f"{n} | 10^{logq} | 10^-{j} x {m:.12f} | {e:.6f} | {l3:.6f}")
print("doubling gaps S = 0.0101000100...: a 1 at places 2, 4, 8, 16, ...")
rowsS = truncations([2 ** k for k in range(1, 8)], 5, 130, 3)
for n, logq, j, m, e, l3 in rowsS:
    print(f"{n} | 10^{logq} | 10^-{j} x {m:.12f} | {e:.6f} | {l3:.6f}")

def icbrt(n):                      # floor of the real cube root, exact
    x = int(round(abs(n) ** (1 / 3)))
    while x ** 3 > abs(n): x -= 1
    while (x + 1) ** 3 <= abs(n): x += 1
    if n >= 0: return x
    return -x if x ** 3 == -n else -(x + 1)

a = 1.0
for _ in range(8): a = a - (a * a * a - 2) / (3 * a * a)
def err(p, q):                     # |cbrt2 - p/q| = |p^3 - 2q^3| / (q^3 (a^2 + a r + r^2))
    r = p / q
    return abs(p ** 3 - 2 * q ** 3) / (float(q ** 3) * (a * a + a * r + r * r))
print(f"cube root of 2 = {a:.12f}")
QMAX, best, records, low3, low25 = 10 ** 6, 9.0, [], (9.0, 0), (9.0, 0)
lowb = (9.0, 0)
for q in range(1, QMAX + 1):
    p0 = icbrt(2 * q ** 3)
    for p in (p0, p0 + 1):
        e = err(p, q)
        if q * e < best: best = q * e; records.append((p, q))
        low3 = min(low3, (q ** 3 * e, q)); low25 = min(low25, (q ** 2.5 * e, q))
        lowb = min(lowb, (q ** 2.955 * e, q))

cf, poly = [], [1, 0, 0, -2]       # road 3: Lagrange's method on x^3 - 2
for _ in range(len(records)):
    c3, c2, c1, c0 = poly
    P = lambda x: ((c3 * x + c2) * x + c1) * x + c0
    k = 1
    while c3 * P(k + 1) < 0: k += 1
    cf.append(k)
    poly = [P(k), 3 * k * k * c3 + 2 * k * c2 + c1, 3 * k * c3 + c2, c3]
conv, (p1, q1, p2, q2) = [], (1, 0, 0, 1)
for x in cf:
    p1, p2, q1, q2 = x * p1 + p2, p1, x * q1 + q2, q1
    conv.append((p1, q1))
assert conv == records             # brute force and Lagrange's method agree
print(f"convergents with q <= 10^6: {len(conv)}, partial quotients {cf}")
print("k | p/q | |p^3 - 2q^3| | q^2 x error | exponent")
for i, (p, q) in enumerate(conv):
    e = err(p, q)
    ex = "-" if q == 1 else f"{-log(e) / log(q):.6f}"
    print(f"{i} | {p}/{q} | {abs(p ** 3 - 2 * q ** 3)} | {q * q * e:.6f} | {ex}")
    assert q * q * e < 1                           # Dirichlet: below 1/q^2
c_proof = 1 / (3 * a * a + 3 * a + 1)
brk = max(a * a + a * r + r * r for r in (a - 1 + i / 1000 for i in range(2001)))
assert abs(c_proof * brk - 1) < 1e-9          # c = 1 / largest bracket, by sampling
c_tan = 1 / (3 * (a + 1) ** 2)                # Step 2's general proof: M = largest slope 3x^2
assert abs(c_tan * max(3 * x * x for x in (a - 1 + i / 1000 for i in range(2001))) - 1) < 1e-9
print(f"Liouville's c, general proof: M = {1 / c_tan:.6f}, c = {c_tan:.6f}; exact identity: "
      f"largest chord slope {1 / c_proof:.6f}, c = {c_proof:.6f}")
print(f"least q^3 x error to 10^6: {low3[0]:.6f} at q = {low3[1]}")
print(f"least q^2.5 x error to 10^6: {low25[0]:.6f} at q = {low25[1]} (Bennett: > 0.25)")
print(f"least q^2.955 x error to 10^6: {lowb[0]:.6f} at q = {lowb[1]} (Baker: > 10^-6)")
assert low3[0] >= c_proof and low25[0] > 0.25 and lowb[0] > 1e-6
print(f"exponent allowed at degree 3: Liouville 3, Thue {3 / 2 + 1}, Dyson {sqrt(6):.6f}, "
      "Roth 2 + any eps")
print(f"5/4 alone: error {err(5, 4):.6f}, exponent {-log(err(5, 4)) / log(4):.6f}, "
      f"q^3 x error {64 * err(5, 4):.6f}")

m = 1                              # x^3 - 2y^3 = m, bounded by Bennett's inequality
ybound = int((16 * abs(m) / (3 * a * a)) ** 2)
def thue(lo, hi):
    return [(icbrt(2 * y ** 3 + m), y) for y in range(lo, hi + 1)
            if icbrt(2 * y ** 3 + m) ** 3 == 2 * y ** 3 + m]
sols, wide = thue(-ybound, ybound), thue(-10 ** 5, 10 ** 5)
y_last = next(y for y in range(1, 10 ** 6) if 1 / (4 * y ** 2.5) > 4 * abs(m) / (3 * a * a * y ** 3)) - 1
assert sols == wide and ybound == y_last      # the box, against Bennett's bound tried y by y
print(f"x^3 - 2y^3 = {m}: Bennett forces |y| <= {ybound}; solutions {sols}; "
      f"search to |y| = 100,000 finds {len(wide)}")
def isqrt(n):                      # floor square root by Newton's method, exact
    x = n
    while x * x > n: x = (x + n // x) // 2
    return x
pts = [(x, isqrt(x ** 3 - x)) for x in range(-10 ** 4, 10 ** 4 + 1)
       if x ** 3 - x >= 0 and isqrt(x ** 3 - x) ** 2 == x ** 3 - x]
print(f"whole-number points on y^2 = x^3 - x with |x| <= 10,000: {pts}")
assert pts == [(-1, 0), (0, 0), (1, 0)]
print(f"Pythagorean comma 3^12 / 2^19 = {3 ** 12 / 2 ** 19:.6f}")
assert all(abs(r[4] - (r[0] + 1)) < 1e-4 for r in rowsL)   # Step 3: exponent n + 1 at the n-th cut
assert all(abs(r[4] - 2) < 1e-4 for r in rowsS)            # Step 4: doubling gaps stay at exponent 2
print("ALL CHECKS PASS")
```

**Ran 2026-11-15 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
Liouville's constant L = 0.1100010000...: a 1 at places 1!, 2!, 3!, ...
L to 30 places: 0.110001000000000000000001000000
n | q = 10^(n!) | L - p/q = 10^-j x m | exponent | log10(q^3 x error)
1 | 10^1 | 10^-2 x 1.000100000000 | 1.999957 | 1.000043
2 | 10^2 | 10^-6 x 1.000000000000 | 3.000000 | 0.000000
3 | 10^6 | 10^-24 x 1.000000000000 | 4.000000 | -6.000000
4 | 10^24 | 10^-120 x 1.000000000000 | 5.000000 | -48.000000
doubling gaps S = 0.0101000100...: a 1 at places 2, 4, 8, 16, ...
1 | 10^2 | 10^-4 x 1.000100000001 | 1.999978 | 2.000043
2 | 10^4 | 10^-8 x 1.000000010000 | 2.000000 | 4.000000
3 | 10^8 | 10^-16 x 1.000000000000 | 2.000000 | 8.000000
4 | 10^16 | 10^-32 x 1.000000000000 | 2.000000 | 16.000000
5 | 10^32 | 10^-64 x 1.000000000000 | 2.000000 | 32.000000
cube root of 2 = 1.259921049895
convergents with q <= 10^6: 14, partial quotients [1, 3, 1, 5, 1, 1, 4, 1, 1, 8, 1, 14, 1, 10]
k | p/q | |p^3 - 2q^3| | q^2 x error | exponent
0 | 1/1 | 1 | 0.259921 | -
1 | 4/3 | 10 | 0.660711 | 2.377239
2 | 5/4 | 3 | 0.158737 | 3.327646
3 | 29/23 | 55 | 0.501765 | 2.219941
4 | 34/27 | 62 | 0.482445 | 2.221154
5 | 63/50 | 47 | 0.197375 | 2.414785
6 | 286/227 | 510 | 0.471780 | 2.138479
7 | 349/277 | 683 | 0.517763 | 2.117041
8 | 635/504 | 253 | 0.105410 | 2.361570
9 | 5429/4309 | 17331 | 0.844577 | 2.020185
10 | 6064/4813 | 1450 | 0.063262 | 2.325562
11 | 90325/71691 | 293383 | 0.859335 | 2.013559
12 | 96389/76504 | 32259 | 0.088544 | 2.215583
13 | 1054215/836731 | 1376593 | 0.345471 | 2.077937
Liouville's c, general proof: M = 15.321729, c = 0.065267; exact identity: largest chord slope 9.541966, c = 0.104800
least q^3 x error to 10^6: 0.259921 at q = 1
least q^2.5 x error to 10^6: 0.259921 at q = 1 (Bennett: > 0.25)
least q^2.955 x error to 10^6: 0.259921 at q = 1 (Baker: > 10^-6)
exponent allowed at degree 3: Liouville 3, Thue 2.5, Dyson 2.449490, Roth 2 + any eps
5/4 alone: error 0.009921, exponent 3.327646, q^3 x error 0.634947
x^3 - 2y^3 = 1: Bennett forces |y| <= 11; solutions [(-1, -1), (1, 0)]; search to |y| = 100,000 finds 2
whole-number points on y^2 = x^3 - x with |x| <= 10,000: [(-1, 0), (0, 0), (1, 0)]
Pythagorean comma 3^12 / 2^19 = 1.013643
ALL CHECKS PASS
```

### Rust

```rust
// Liouville to Roth -- the check behind the card.  std only, no crates.
// Road 1: exact decimal digits of Liouville's constant.
// Road 2: the geometric-series bound of Why it works.  Road 3: every q up to 10^6
// against the continued fraction of the cube root of 2, built by Lagrange's method.

fn fact(n: usize) -> usize { if n == 0 { 1 } else { n * fact(n - 1) } }

fn digits(places: &[usize], length: usize) -> Vec<i32> {
    let mut d = vec![0; length + 1];
    for &k in places { d[k] = 1; }
    d
}

fn first_nonzero(x: &[i32], y: &[i32]) -> (usize, f64) {
    let (mut diff, mut borrow) = (vec![0; x.len()], 0);
    for i in (1..x.len()).rev() {
        let v = x[i] - y[i] - borrow;
        borrow = if v < 0 { 1 } else { 0 };
        diff[i] = v + 10 * borrow;
    }
    let j = (1..x.len()).find(|&i| diff[i] != 0).unwrap();
    let mut s: String = diff[j..(j + 15).min(x.len())].iter().map(|d| d.to_string()).collect();
    while s.len() < 15 { s.push('0'); }
    (j, s.parse::<u64>().unwrap() as f64 / 1e14)
}

fn truncations(gaps: &[usize], nmax: usize, length: usize, d_show: f64) -> Vec<f64> {
    let (full, mut ex) = (digits(gaps, length), Vec::new());
    for n in 1..=nmax {
        let (j, m) = first_nonzero(&full, &digits(&gaps[..n], length));
        let logq = gaps[n - 1];
        let expo = (j as f64 - m.log10()) / logq as f64;
        let l3 = d_show * logq as f64 - j as f64 + m.log10();
        let tail: f64 = gaps[n + 1..].iter().map(|&g| 10f64.powi(gaps[n] as i32 - g as i32)).sum();
        assert!(j == gaps[n] && (m - (1.0 + tail)).abs() < 1e-12); // road 2 agrees
        assert!(1.0 <= m && m < 2.0);                                // error < 2 / q^(n+1)
        println!("{} | 10^{} | 10^-{} x {:.12} | {:.6} | {:.6}", n, logq, j, m, expo, l3);
        ex.push(expo);
    }
    ex
}

fn icbrt(n: i128) -> i128 {
    let a = n.abs();
    let mut x = (a as f64).powf(1.0 / 3.0).round() as i128;
    while x * x * x > a { x -= 1; }
    while (x + 1) * (x + 1) * (x + 1) <= a { x += 1; }
    if n >= 0 { x } else if x * x * x == a { -x } else { -(x + 1) }
}

fn err(p: i128, q: i128, a: f64) -> f64 {
    let r = p as f64 / q as f64;
    (p * p * p - 2 * q * q * q).abs() as f64 / ((q * q * q) as f64 * (a * a + a * r + r * r))
}

fn main() {
    println!("Liouville's constant L = 0.1100010000...: a 1 at places 1!, 2!, 3!, ...");
    let lg: Vec<usize> = (1..6).map(fact).collect();
    let l = digits(&lg, 130);
    let s: String = l[1..31].iter().map(|d| d.to_string()).collect();
    println!("L to 30 places: 0.{}", s);
    println!("n | q = 10^(n!) | L - p/q = 10^-j x m | exponent | log10(q^3 x error)");
    let ex_l = truncations(&lg, 4, 130, 3.0);
    println!("doubling gaps S = 0.0101000100...: a 1 at places 2, 4, 8, 16, ...");
    let mg: Vec<usize> = (1..8).map(|k| 1usize << k).collect();
    let ex_s = truncations(&mg, 5, 130, 3.0);

    let mut a = 1.0f64;
    for _ in 0..8 { a = a - (a * a * a - 2.0) / (3.0 * a * a); }
    println!("cube root of 2 = {:.12}", a);
    let (mut best, mut records) = (9.0f64, Vec::new());
    let (mut low3, mut low25, mut lowb) = ((9.0f64, 0i128), (9.0f64, 0i128), (9.0f64, 0i128));
    for q in 1..=1_000_000i128 {
        let p0 = icbrt(2 * q * q * q);
        for p in [p0, p0 + 1] {
            let e = err(p, q, a);
            if q as f64 * e < best { best = q as f64 * e; records.push((p, q)); }
            let v3 = (q * q * q) as f64 * e;
            if v3 < low3.0 || (v3 == low3.0 && q < low3.1) { low3 = (v3, q); }
            let v25 = (q as f64).powf(2.5) * e;
            if v25 < low25.0 || (v25 == low25.0 && q < low25.1) { low25 = (v25, q); }
            let vb = (q as f64).powf(2.955) * e;
            if vb < lowb.0 || (vb == lowb.0 && q < lowb.1) { lowb = (vb, q); }
        }
    }

    let (mut cf, mut poly): (Vec<i128>, [i128; 4]) = (Vec::new(), [1, 0, 0, -2]);
    for _ in 0..records.len() {
        let [c3, c2, c1, c0] = poly;
        let pv = |x: i128| ((c3 * x + c2) * x + c1) * x + c0;
        let mut k = 1;
        while c3 * pv(k + 1) < 0 { k += 1; }
        cf.push(k);
        poly = [pv(k), 3 * k * k * c3 + 2 * k * c2 + c1, 3 * k * c3 + c2, c3];
    }
    let (mut conv, mut p1, mut q1, mut p2, mut q2) = (Vec::new(), 1i128, 0i128, 0i128, 1i128);
    for &x in &cf {
        let (np, nq) = (x * p1 + p2, x * q1 + q2);
        p2 = p1; q2 = q1; p1 = np; q1 = nq;
        conv.push((p1, q1));
    }
    assert!(conv == records);
    let cfs: Vec<String> = cf.iter().map(|x| x.to_string()).collect();
    println!("convergents with q <= 10^6: {}, partial quotients [{}]", conv.len(), cfs.join(", "));
    println!("k | p/q | |p^3 - 2q^3| | q^2 x error | exponent");
    for (i, &(p, q)) in conv.iter().enumerate() {
        let e = err(p, q, a);
        let ex = if q == 1 { "-".to_string() } else { format!("{:.6}", -e.ln() / (q as f64).ln()) };
        println!("{} | {}/{} | {} | {:.6} | {}", i, p, q, (p * p * p - 2 * q * q * q).abs(),
                 (q * q) as f64 * e, ex);
        assert!(((q * q) as f64) * e < 1.0);
    }
    let c_proof = 1.0 / (3.0 * a * a + 3.0 * a + 1.0);
    let brk = (0..=2000).map(|i| { let r = a - 1.0 + i as f64 / 1000.0; a * a + a * r + r * r })
        .fold(0.0f64, f64::max);
    assert!((c_proof * brk - 1.0).abs() < 1e-9);    // c = 1 / largest bracket, by sampling
    let c_tan = 1.0 / (3.0 * (a + 1.0) * (a + 1.0));  // Step 2's general proof: M = largest slope 3x^2
    let mslope = (0..=2000).map(|i| { let x = a - 1.0 + i as f64 / 1000.0; 3.0 * x * x })
        .fold(0.0f64, f64::max);
    assert!((c_tan * mslope - 1.0).abs() < 1e-9);
    println!("Liouville's c, general proof: M = {:.6}, c = {:.6}; exact identity: largest chord slope {:.6}, c = {:.6}",
             1.0 / c_tan, c_tan, 1.0 / c_proof, c_proof);
    println!("least q^3 x error to 10^6: {:.6} at q = {}", low3.0, low3.1);
    println!("least q^2.5 x error to 10^6: {:.6} at q = {} (Bennett: > 0.25)", low25.0, low25.1);
    println!("least q^2.955 x error to 10^6: {:.6} at q = {} (Baker: > 10^-6)", lowb.0, lowb.1);
    assert!(low3.0 >= c_proof && low25.0 > 0.25 && lowb.0 > 1e-6);
    println!("exponent allowed at degree 3: Liouville 3, Thue {:?}, Dyson {:.6}, Roth 2 + any eps",
             1.5 + 1.0, 6f64.sqrt());
    let e54 = err(5, 4, a);
    println!("5/4 alone: error {:.6}, exponent {:.6}, q^3 x error {:.6}", e54, -e54.ln() / 4f64.ln(),
             64.0 * e54);

    let m: i128 = 1;                 // x^3 - 2y^3 = m, bounded by Bennett's inequality
    let t = 16.0 * m.abs() as f64 / (3.0 * a * a);
    let ybound = (t * t) as i128;
    let thue = |lo: i128, hi: i128| -> Vec<(i128, i128)> {
        (lo..=hi).filter(|&y| { let n = 2 * y * y * y + m; let x = icbrt(n); x * x * x == n })
            .map(|y| (icbrt(2 * y * y * y + m), y)).collect()
    };
    let (sols, wide) = (thue(-ybound, ybound), thue(-100_000, 100_000));
    let y_last = (1..1_000_000i128).find(|&y| { let yf = y as f64;
        1.0 / (4.0 * yf.powf(2.5)) > 4.0 * m.abs() as f64 / (3.0 * a * a * yf.powi(3)) }).unwrap() - 1;
    assert!(sols == wide && ybound == y_last);      // the box, against Bennett's bound tried y by y
    let ss: Vec<String> = sols.iter().map(|(x, y)| format!("({}, {})", x, y)).collect();
    println!("x^3 - 2y^3 = {}: Bennett forces |y| <= {}; solutions [{}]; search to |y| = 100,000 finds {}",
             m, ybound, ss.join(", "), wide.len());
    let isqrt = |n: i128| -> i128 { let mut x = n; while x * x > n { x = (x + n / x) / 2; } x };
    let pts: Vec<(i128, i128)> = (-10_000..=10_000i128)
        .filter(|&x| { let n = x * x * x - x; n >= 0 && isqrt(n) * isqrt(n) == n })
        .map(|x| (x, isqrt(x * x * x - x))).collect();
    let ps: Vec<String> = pts.iter().map(|(x, y)| format!("({}, {})", x, y)).collect();
    println!("whole-number points on y^2 = x^3 - x with |x| <= 10,000: [{}]", ps.join(", "));
    assert!(pts == vec![(-1, 0), (0, 0), (1, 0)]);
    println!("Pythagorean comma 3^12 / 2^19 = {:.6}", 531441.0f64 / 524288.0);
    assert!(ex_l.iter().enumerate().all(|(i, e)| (e - (i as f64 + 2.0)).abs() < 1e-4)); // exponent n + 1
    assert!(ex_s.iter().all(|e| (e - 2.0).abs() < 1e-4));          // doubling gaps stay at exponent 2
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-15 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
Liouville's constant L = 0.1100010000...: a 1 at places 1!, 2!, 3!, ...
L to 30 places: 0.110001000000000000000001000000
n | q = 10^(n!) | L - p/q = 10^-j x m | exponent | log10(q^3 x error)
1 | 10^1 | 10^-2 x 1.000100000000 | 1.999957 | 1.000043
2 | 10^2 | 10^-6 x 1.000000000000 | 3.000000 | 0.000000
3 | 10^6 | 10^-24 x 1.000000000000 | 4.000000 | -6.000000
4 | 10^24 | 10^-120 x 1.000000000000 | 5.000000 | -48.000000
doubling gaps S = 0.0101000100...: a 1 at places 2, 4, 8, 16, ...
1 | 10^2 | 10^-4 x 1.000100000001 | 1.999978 | 2.000043
2 | 10^4 | 10^-8 x 1.000000010000 | 2.000000 | 4.000000
3 | 10^8 | 10^-16 x 1.000000000000 | 2.000000 | 8.000000
4 | 10^16 | 10^-32 x 1.000000000000 | 2.000000 | 16.000000
5 | 10^32 | 10^-64 x 1.000000000000 | 2.000000 | 32.000000
cube root of 2 = 1.259921049895
convergents with q <= 10^6: 14, partial quotients [1, 3, 1, 5, 1, 1, 4, 1, 1, 8, 1, 14, 1, 10]
k | p/q | |p^3 - 2q^3| | q^2 x error | exponent
0 | 1/1 | 1 | 0.259921 | -
1 | 4/3 | 10 | 0.660711 | 2.377239
2 | 5/4 | 3 | 0.158737 | 3.327646
3 | 29/23 | 55 | 0.501765 | 2.219941
4 | 34/27 | 62 | 0.482445 | 2.221154
5 | 63/50 | 47 | 0.197375 | 2.414785
6 | 286/227 | 510 | 0.471780 | 2.138479
7 | 349/277 | 683 | 0.517763 | 2.117041
8 | 635/504 | 253 | 0.105410 | 2.361570
9 | 5429/4309 | 17331 | 0.844577 | 2.020185
10 | 6064/4813 | 1450 | 0.063262 | 2.325562
11 | 90325/71691 | 293383 | 0.859335 | 2.013559
12 | 96389/76504 | 32259 | 0.088544 | 2.215583
13 | 1054215/836731 | 1376593 | 0.345471 | 2.077937
Liouville's c, general proof: M = 15.321729, c = 0.065267; exact identity: largest chord slope 9.541966, c = 0.104800
least q^3 x error to 10^6: 0.259921 at q = 1
least q^2.5 x error to 10^6: 0.259921 at q = 1 (Bennett: > 0.25)
least q^2.955 x error to 10^6: 0.259921 at q = 1 (Baker: > 10^-6)
exponent allowed at degree 3: Liouville 3, Thue 2.5, Dyson 2.449490, Roth 2 + any eps
5/4 alone: error 0.009921, exponent 3.327646, q^3 x error 0.634947
x^3 - 2y^3 = 1: Bennett forces |y| <= 11; solutions [(-1, -1), (1, 0)]; search to |y| = 100,000 finds 2
whole-number points on y^2 = x^3 - x with |x| <= 10,000: [(-1, 0), (0, 0), (1, 0)]
Pythagorean comma 3^12 / 2^19 = 1.013643
ALL CHECKS PASS
```

### Lean

Lean proves Liouville's bound, Dirichlet's bound and the transcendence of L for every case, and checks the worked numbers.

- Take any algebraic number α of degree d. Then some c(α) > 0 keeps every other fraction p/q at least $`c(\alpha)/q^d`$ away.
- Take any irrational number α. Then infinitely many fractions p/q lie within $`1/q^2`$ of α.
- Liouville's constant L is transcendental: no polynomial with whole-number coefficients has it as a root.
- Cutting L after its third 1 gives 110001/1,000,000. The next 1s sit at places 4! = 24 and 5! = 120.
- The degree-3 test multiplies out: $`10^{18} \times 10^{-24} = 10^{-6}`$ and $`10^{72} \times 10^{-120} = 10^{-48}`$.
- The 14 convergents p/q of the cube root of 2 give the values $`|p^3 - 2q^3|`$ in the code's table.
- Take |x| ≤ 14 and |y| ≤ 11. Then $`x^3 - 2y^3 = 1`$ holds only at (1, 0) and (−1, −1).

The searches to a million, both values of c and the box |y| ≤ 11 are left to the Python and Rust checks.

```lean
-- Chasing an algebraic number with fractions: an algebraic number of degree d stays at least c/q^d from every other fraction p/q, every irrational has infinitely many fractions within 1/q^2, and Liouville's constant is transcendental.
import Mathlib.NumberTheory.Transcendental.Liouville.LiouvilleNumber
import Mathlib.NumberTheory.DiophantineApproximation.Basic
import Mathlib.FieldTheory.Minpoly.Field
import Mathlib.RingTheory.Localization.Integral
import Mathlib.NumberTheory.Transcendental.Liouville.LiouvilleWith

open Polynomial

theorem rat_bound (r : ℚ) : ∀ p : ℤ, ∀ q : ℕ, 1 ≤ q → (p : ℝ) / q ≠ (r : ℝ) →
    (1 / (r.den : ℝ)) / q ≤ |(r : ℝ) - (p : ℝ) / q| := by
  intro p q hq hne
  have hq0 : (0 : ℝ) < q := by exact_mod_cast hq
  have hd0 : (0 : ℝ) < r.den := by exact_mod_cast r.den_pos
  have hr : (r : ℝ) = r.num / r.den := by exact_mod_cast (Rat.num_div_den r).symm
  have hk : r.num * q - p * r.den ≠ 0 := by
    intro h
    apply hne
    rw [hr, div_eq_div_iff hq0.ne' hd0.ne']
    have : ((r.num * q - p * r.den : ℤ) : ℝ) = 0 := by exact_mod_cast h
    push_cast at this
    linarith
  have h1 : (1 : ℝ) ≤ |((r.num * q - p * r.den : ℤ) : ℝ)| := by
    rw [← Int.cast_abs]; exact_mod_cast Int.one_le_abs hk
  have heq : (r : ℝ) - p / q = ((r.num * q - p * r.den : ℤ) : ℝ) / (r.den * q) := by
    rw [hr]; push_cast; field_simp
  rw [heq, abs_div, abs_of_pos (by positivity : (0:ℝ) < r.den * q), div_div]
  exact div_le_div_of_nonneg_right h1 (by positivity)
#print axioms rat_bound

theorem int_poly_of_minpoly (α : ℝ) (hα : IsAlgebraic ℚ α) :
    ∃ f : ℤ[X], f ≠ 0 ∧ f.natDegree = (minpoly ℚ α).natDegree ∧
      eval α (map (algebraMap ℤ ℝ) f) = 0 := by
  obtain ⟨b, hb, hf⟩ := IsLocalization.integerNormalization_spec (nonZeroDivisors ℤ) (minpoly ℚ α)
  set f := IsLocalization.integerNormalization (nonZeroDivisors ℤ) (minpoly ℚ α)
  have hb0 : (b : ℚ) ≠ 0 := by
    have := nonZeroDivisors.ne_zero hb
    exact_mod_cast this
  have hsmul : b • minpoly ℚ α = C (b : ℚ) * minpoly ℚ α := by
    rw [← smul_eq_C_mul]; exact (Int.cast_smul_eq_zsmul ℚ b (minpoly ℚ α)).symm
  have hdeg : f.natDegree = (minpoly ℚ α).natDegree := by
    rw [← natDegree_map_eq_of_injective (algebraMap ℤ ℚ).injective_int f, hf, hsmul,
      natDegree_C_mul hb0]
  have hpos := minpoly.natDegree_pos hα.isIntegral
  refine ⟨f, ?_, hdeg, ?_⟩
  · intro h0; rw [h0, natDegree_zero] at hdeg; omega
  · have : eval α (map (algebraMap ℤ ℝ) f) = aeval α (map (algebraMap ℤ ℚ) f) := by
      rw [aeval_map_algebraMap, eval_map_algebraMap]
    rw [this, hf, hsmul, map_mul, minpoly.aeval, mul_zero]

#print axioms int_poly_of_minpoly

/-- Liouville's bound: for every real algebraic number α of degree d (the degree of its minimal
polynomial over the rationals) there is a positive number c such that every fraction p/q with
q ≥ 1 and p/q ≠ α lies at distance at least c/q^d from α. -/
theorem liouville_bound (α : ℝ) (hα : IsAlgebraic ℚ α) :
    ∃ c : ℝ, 0 < c ∧ ∀ p : ℤ, ∀ q : ℕ, 1 ≤ q → (p : ℝ) / q ≠ α →
      c / (q : ℝ) ^ (minpoly ℚ α).natDegree ≤ |α - (p : ℝ) / q| := by
  have hpos := minpoly.natDegree_pos hα.isIntegral
  by_cases hirr : Irrational α
  · obtain ⟨f, f0, fdeg, fa⟩ := int_poly_of_minpoly α hα
    obtain ⟨A, hA, h⟩ := Liouville.exists_pos_real_of_irrational_root hirr f0 fa
    refine ⟨1 / A, by positivity, fun p q hq _ => ?_⟩
    obtain ⟨b, rfl⟩ : ∃ b, q = b + 1 := ⟨q - 1, by omega⟩
    have hb := h p b
    rw [fdeg] at hb
    push_cast
    have hpow : (0 : ℝ) < ((b : ℝ) + 1) ^ (minpoly ℚ α).natDegree := by positivity
    rw [div_div, div_le_iff₀ (by positivity)]
    nlinarith
  · obtain ⟨r, rfl⟩ : ∃ r : ℚ, (r : ℝ) = α := by
      unfold Irrational at hirr; push Not at hirr; simpa using hirr
    refine ⟨1 / r.den, by positivity, fun p q hq hne => ?_⟩
    refine le_trans ?_ (rat_bound r p q hq hne)
    have hq1 : (1 : ℝ) ≤ q := by exact_mod_cast hq
    have : (q : ℝ) ≤ (q : ℝ) ^ (minpoly ℚ (r : ℝ)).natDegree :=
      le_self_pow₀ hq1 (by omega)
    gcongr

/-- Dirichlet's bound: every irrational number α has infinitely many fractions p/q
(in lowest terms, with denominator q) within 1/q^2 of it. -/
theorem dirichlet_bound (α : ℝ) (hα : Irrational α) :
    {r : ℚ | |α - (r : ℝ)| < 1 / (r.den : ℝ) ^ 2}.Infinite := by
  exact Real.infinite_rat_abs_sub_lt_one_div_den_sq_of_irrational hα

/-- Liouville's constant L = 10^(-1!) + 10^(-2!) + 10^(-3!) + ... = 0.110001000... is
transcendental: no nonzero polynomial with whole-number coefficients has it as a root. -/
theorem liouville_constant_transcendental :
    Transcendental ℤ (∑' k : ℕ, (1 : ℝ) / 10 ^ (k + 1).factorial) := by
  have hs : Summable fun i : ℕ => (1 : ℝ) / 10 ^ i.factorial :=
    LiouvilleNumber.summable (by norm_num)
  have h1 : liouvilleNumber 10 =
      1 / 10 ^ (0 : ℕ).factorial + ∑' k : ℕ, (1 : ℝ) / 10 ^ (k + 1).factorial :=
    hs.tsum_eq_zero_add
  have hL : Liouville (liouvilleNumber 10) := by
    have := liouville_liouvilleNumber (m := 10) (by norm_num)
    simpa using this
  have h2 : (∑' k : ℕ, (1 : ℝ) / 10 ^ (k + 1).factorial) =
      liouvilleNumber 10 - ((1 / 10 : ℚ) : ℝ) := by
    rw [h1]; push_cast; simp
  rw [h2]
  exact (forall_liouvilleWith_iff.mp fun p => (hL.liouvilleWith p).sub_rat _).transcendental

-- Cutting L after its third 1 gives 0.110001 = 110001/10^6, with denominator q_3 = 10^(3!).
example : (1 : ℚ) / 10 ^ Nat.factorial 1 + 1 / 10 ^ Nat.factorial 2 + 1 / 10 ^ Nat.factorial 3
    = 110001 / 10 ^ 6 := by
  norm_num [Nat.factorial]

-- The next 1 sits at place 4! = 24 and then 5! = 120; exponents seen 24 / 6 = 4 and 120 / 24 = 5.
example : Nat.factorial 3 = 6 ∧ Nat.factorial 4 = 24 ∧ Nat.factorial 5 = 120 ∧
    Nat.factorial 4 / Nat.factorial 3 = 4 ∧ Nat.factorial 5 / Nat.factorial 4 = 5 := by
  decide

-- Testing degree 3: q^3 times the error is 10^18 * 10^-24 = 10^-6 at n = 3, and 10^72 * 10^-120 = 10^-48 at n = 4.
example : ((10 : ℚ) ^ 6) ^ 3 * (1 / 10 ^ 24) = 1 / 10 ^ 6 ∧
    ((10 : ℚ) ^ 24) ^ 3 * (1 / 10 ^ 120) = 1 / 10 ^ 48 := by
  norm_num

-- The tops p^3 - 2q^3 of the 14 convergents p/q of the cube root of 2 with q ≤ 10^6 (sizes as in the card's table).
example : [(1, 1), (4, 3), (5, 4), (29, 23), (34, 27), (63, 50), (286, 227), (349, 277),
    (635, 504), (5429, 4309), (6064, 4813), (90325, 71691), (96389, 76504), (1054215, 836731)].map
      (fun pq : ℤ × ℤ => pq.1 ^ 3 - 2 * pq.2 ^ 3)
    = [-1, 10, -3, 55, -62, 47, -510, 683, -253, 17331, -1450, 293383, -32259, 1376593] := by
  decide

-- Inside Bennett's box |y| ≤ 11 (which forces |x| ≤ 13), x^3 - 2y^3 = 1 has exactly the solutions (1, 0) and (-1, -1).
example : ∀ x ∈ Finset.Icc (-14 : ℤ) 14, ∀ y ∈ Finset.Icc (-11 : ℤ) 11,
    (x ^ 3 - 2 * y ^ 3 = 1 ↔ (x, y) = (1, 0) ∨ (x, y) = (-1, -1)) := by
  decide +kernel

#print axioms liouville_bound
#print axioms dirichlet_bound
#print axioms liouville_constant_transcendental
```

**Checked 2026-11-15 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'rat_bound' depends on axioms: [propext, Classical.choice, Quot.sound]
'int_poly_of_minpoly' depends on axioms: [propext, Classical.choice, Quot.sound]
'liouville_bound' depends on axioms: [propext, Classical.choice, Quot.sound]
'dirichlet_bound' depends on axioms: [propext, Classical.choice, Quot.sound]
'liouville_constant_transcendental' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> - Guess first: do cube gaps make a Liouville number? In the first `truncations` call, put the 1s at places $`k^3`$: replace `[fact(k) for k in range(1, 6)], 4, 130` with `[k ** 3 for k in range(1, 8)], 5, 350`. Answer: no. The exponents fall 8.000000, 3.375000, 2.370370, 1.953125, 1.728000, dropping below Dirichlet's 2 at the fourth cut. The run prints every row, then the exponent assert at the end stops it.
> - Guess first: how many solutions does $`x^3 - 2y^3 = 3`$ have? Set `m = 3`. Answer: two, (1, −1) and (−5, −4), inside Bennett's box |y| ≤ 101. The second is the convergent 5/4 with its signs flipped.
> - Guess first: does $`x^3 - 2y^3 = 5`$ have any solution? Set `m = 5`. Answer: none; Bennett's box |y| ≤ 282 is empty, so none exists at all.
> - Guess first: does $`x^3 - 2y^3 = 10`$ have one? Set `m = 10`. Answer: two, (2, −1) and (4, 3), inside |y| ≤ 1128.

---

## The usual mistake

> [!warning]
> **Reading Liouville's bound as a test for transcendence.** It only works one way. A number crowded closer than every power is transcendental, but most transcendental numbers are not crowded at all. The number e has irrationality exponent exactly 2, the same as the cube root of 2, and it is transcendental (Hermite, 1873). Liouville's method says nothing about e or π.
>
> Smaller traps:
> - **Reading the exponent off one small fraction.** 5/4 misses the cube root of 2 by 0.009921, which is exponent 3.327646. It looks like Liouville's bound is broken. It is not: the constant c dominates at small q.
> - **Dropping the ε.** Exponent exactly 2 is always reached infinitely often: 14 convergents of the cube root of 2 do it below a million.
> - **Treating Roth as a search limit.** Roth's theorem says the very good fractions are finite in number, not where they stop. Only effective bounds such as Baker's or Bennett's turn a search into a proof.
> - **Gaps that grow too slowly.** Doubling gaps give exponent 2.000000 from the second cut on, which proves nothing.

---

## Where you meet it in real life

- **Solving equations in whole numbers.** Computer algebra systems solve Thue equations such as $`x^3 - 2y^3 = m`$ by Baker's bound followed by a search. For m = 1 the card does it by hand: |y| ≤ 11, two solutions.
- **Whole-number points on curves.** Siegel's theorem says a curve such as the shelf's $`y^2 = x^3 - x`$ has finitely many whole-number points. Its proof rests on Thue-Siegel approximation. Baker's methods make such searches finish. The code finds (−1, 0), (0, 0) and (1, 0) with |x| up to 10,000; the full proof for this curve is on [Rational points on a cubic](05-elliptic-curves-over-q-and-mordell-weil.md).
- **Musical tuning.** Twelve perfect fifths nearly equal seven octaves: $`3^{12}/2^{19}`$ = 1.013643, the Pythagorean comma. That is $`12\log 3 - 19\log 2`$ being small. Baker's theorem on linear forms in logarithms is exactly a lower bound on such near-misses.
- **Gears and calendars.** Best cheap fractions set gear ratios and leap-year rules ([Continued fractions](../../02-Number%20theory/07-For%20the%20Curious/05-continued-fractions-and-leap-years.md)). Roth's theorem says that for algebraic ratios, those cheap fractions never get dramatically better than $`1/q^2`$.

> **Say it back**
> Every irrational number has endless fractions within one over q squared. An algebraic number of degree d keeps every fraction at least a constant over q to the d away, because plugging the fraction into its polynomial gives a nonzero whole number divided by q to the d. Liouville's constant has fractions closer than any power of q, so it cannot be algebraic. Roth cut Liouville's d down to 2 plus any margin, but his proof cannot say where the exceptions stop. Baker's effective bounds can, and they turn equations like x cubed minus 2y cubed equals 1 into a finite search.

---

## What this builds on

- [Pell's equation](01-pell-and-continued-fractions-revisited.md): the convergents of a square root, and an equation solved because good fractions to root d are its solutions; this card asks the same of cube roots.
- [Irrational numbers](../../01-Foundations/02-The%20Number%20Line/03-irrational-numbers.md): what it means for a number not to be a fraction, and why root 2 is not one.
- [Taylor series](../../06-Calculus%20and%20analysis/06-Series/05-taylor-series.md): a function near a point is its value plus slope times distance plus a leftover; Step 2 uses the first-order case, the mean value theorem, to bound f near its root.
- [Continued fractions](../../02-Number%20theory/07-For%20the%20Curious/05-continued-fractions-and-leap-years.md): convergents as the best cheap fractions, within $`1/q^2`$; Step 1 states this in one line.

## Where this goes next

- [Equidistribution](../08-Additive%20Combinatorics%20and%20Probabilistic%20Number%20Theory/03-equidistribution-and-weyls-criterion.md): the multiples α, 2α, 3α, … spread evenly around a circle when α is irrational, and the irrationality exponent controls how fast they even out.

The rest of the shelf: [Pell's equation](01-pell-and-continued-fractions-revisited.md), [Two squares](02-sums-of-squares-and-gaussian-integers.md), [Four squares and beyond](03-four-squares-and-warings-problem.md), [Fermat's last theorem](04-fermats-last-theorem-history-and-descent.md), [Rational points on a cubic](05-elliptic-curves-over-q-and-mordell-weil.md), [Birch-Swinnerton-Dyer](06-birch-swinnerton-dyer-and-the-congruent-number-problem.md), [Modular forms](07-modular-forms-in-outline.md), [Modularity](08-modularity-and-the-proof-of-fermat.md), [The abc conjecture](09-abc-conjecture-and-szpiro.md).

The question this card leaves open: Roth's theorem is still ineffective, so for most algebraic numbers no one can compute where the exponent 2 + ε takes over.

---

## Sources

Verified 2026-11-15: every link below resolves to the publisher's page.

- Liouville, Joseph. "Sur des classes très-étendues de quantités dont la valeur n'est ni algébrique, ni même réductible à des irrationnelles algébriques." *Journal de mathématiques pures et appliquées* 16 (1851): 133–142. [Numdam](http://www.numdam.org/item/JMPA_1851_1_16__133_0/). The bound of Step 2 and the constant L.
- Roth, K. F. "Rational approximations to algebraic numbers." *Mathematika* 2 (1955): 1–20. [doi:10.1112/S0025579300000644](https://doi.org/10.1112/S0025579300000644). The exponent 2 + ε, with the history from Thue to Dyson.
- Baker, A. "Rational approximations to ∛2 and other algebraic numbers." *Quarterly Journal of Mathematics* 15 (1964): 375–383. [doi:10.1093/qmath/15.1.375](https://doi.org/10.1093/qmath/15.1.375). An effective exponent below Liouville's 3 for the cube root of 2, with an explicit constant.
- Baker, A. "Contributions to the theory of Diophantine equations I. On the representation of integers by binary forms." *Philosophical Transactions of the Royal Society A* 263 (1968): 173–191. [doi:10.1098/rsta.1968.0010](https://doi.org/10.1098/rsta.1968.0010). Computable limits on every solution of a Thue equation, from linear forms in logarithms.
- Bennett, Michael A. "Effective measures of irrationality for certain algebraic numbers." *Journal of the Australian Mathematical Society, Series A* 62 (1997): 329–344. [doi:10.1017/S144678870000104X](https://doi.org/10.1017/S144678870000104X). The bound $`|\sqrt[3]{2} - p/q| > 1/(4q^{2.5})`$ used to solve $`x^3 - 2y^3 = 1`$.
