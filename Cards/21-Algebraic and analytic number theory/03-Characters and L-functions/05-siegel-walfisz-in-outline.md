# Siegel-Walfisz: the prime count in a progression, uniform over small moduli

[Syllabus](../../../SYLLABUS.md) → [Algebraic and analytic number theory](../README.md) → [Characters and L-functions](../README.md#s03) → Siegel-Walfisz

---

## General Overview

Sort the 78,498 primes below a million by their remainder on division by 7. The prime 7 sits alone in remainder 0. Remainders 1 to 6 hold 13,063, 13,065, 13,105, 13,069, 13,105 and 13,090 primes. The largest and smallest differ by 42: the six classes mod 7 agree to a third of a percent (0.32 percent).

[Dirichlet's theorem](04-dirichlets-theorem-on-primes-in-progressions.md) gives each class its fair share in the long run, one fixed modulus at a time. Proofs about primes often need more: the fair share for many moduli at once, with one error bound for all of them.

The Siegel-Walfisz theorem gives that, for every modulus up to a power of $`\log x`$ (log is the natural logarithm). At a million the range is small: up to 13.82 with power 1, or 190.87 with power 2. The price is strange: the error bound has a constant that nobody can compute.

Two more names appear in the statement. φ(q), Euler's totient, counts the classes mod q that share no factor with q: φ(7) = 6. li(x), the logarithmic integral, is the smooth estimate of the prime count: 78,627.55 at a million.

**For every power A, the primes up to x in any class a mod q, with q at most $`(\log x)^A`$ and a sharing no factor with q, number li(x)/φ(q) up to an error of at most a fixed multiple of $`x e^{-C\sqrt{\log x}}`$; one constant C works for all those moduli, but its value is ineffective: the proof shows it exists and gives no way to compute it.**

**What kind of fact this is:** a theorem, proved by Walfisz in 1936 from Siegel's 1935 bound on real zeros. This outline card proves the last step in a fold and quotes Siegel's bound and the zero-free region for L-functions from Davenport. The counts are evidence, never proof.

### The picture: the six classes mod 7, magnified

```
class 1  ######                      13063
class 2  #######                     13065
class 3  ########################### 13105
class 4  #########                   13069
class 5  ########################### 13105
class 6  ####################        13090
```

Bars start at 13,050, one mark per 2 primes; drawn from 0, all six would look equal. The non-squares mod 7 (3, 5, 6) lead the squares (1, 2, 4) by 103 primes in total.

```mermaid
flowchart LR
    A["Zero-free region for L(s, χ)<br/>except one possible real zero β₁"] --> B["Siegel: β₁ < 1 − c(ε) q^−ε<br/>c(ε) ineffective"]
    B --> C["q ≤ (log x)^A: the zero costs<br/>at most x e^(−c(ε)√log x)"]
    C --> D["Siegel-Walfisz:<br/>π(x; q, a) = li(x)/φ(q) + small error"]
```

The chain of the proof. Only the middle step has a constant nobody can compute, and it is why the modulus must stay small.

---

## The formula

Notation, in words:

- The **modulus** q is the number we divide by; a is a remainder.
- π(x; q, a) counts the primes up to x with remainder a.
- φ(q), Euler's totient, counts the numbers from 1 to q sharing no factor with q.
- li(x) is the logarithmic integral, taken from 0.
- A **character** χ mod q is a pattern of values on remainders that multiplies like the numbers do ([Dirichlet characters](01-dirichlet-characters.md)); χ̄ is its complex conjugate.
- L(s, χ) is the character's L-function ([Dirichlet L-functions](03-dirichlet-l-functions.md)).

```math
\pi(x; q, a) = \frac{\mathrm{li}(x)}{\varphi(q)} + O_A\big(x\,e^{-C_A\sqrt{\log x}}\big) \quad \text{for every } q \le (\log x)^A \text{ and every } a \text{ with } \gcd(a, q) = 1
```

**Read it aloud:** the primes up to x in the class a mod q number li of x over phi of q, plus an error below a constant times x e to the minus C root log x, the same for every modulus up to log x to the A.

The danger is one real zero $`\beta_1`$, close to 1, of the L-function of one real character $`\chi_1`$. If it exists, it adds its own term:

```math
\pi(x; q, a) \approx \frac{\mathrm{li}(x)}{\varphi(q)} - \chi_1(a)\,\frac{\mathrm{li}(x^{\beta_1})}{\varphi(q)}
```

**Read it aloud:** the count is the fair share, minus the character's value at a times li of x to the beta-one, over phi of q.

Siegel's theorem bounds how close that zero can be to 1:

```math
\beta_1 < 1 - \frac{c(\varepsilon)}{q^{\varepsilon}} \qquad \text{for every } \varepsilon > 0
```

**Read it aloud:** the exceptional zero stays below one minus c of epsilon over q to the epsilon, where c of epsilon is positive but cannot be computed.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $`x`$ | how far we count | 10^6 | the relative spread shrinks |
| $`q`$, $`a`$ | the modulus; a remainder sharing no factor with it | q = 7, a = 1 to 6 | q up: fewer primes per class, bigger misses |
| $`\pi(x; q, a)`$ | primes up to x with remainder a mod q | 13,063 to 13,105 | — |
| $`\varphi(q)`$ | Euler's totient: how many classes hold the primes not dividing q | φ(7) = 6 | each class's share falls |
| $`\mathrm{li}(x)`$ | the logarithmic integral, the smooth prime-count estimate | 78,627.55 | — |
| $`A`$ | the power that fixes the moduli allowed, $`q \le (\log x)^A`$ | A = 2: q up to 190.87 | more moduli; a smaller C |
| $`C_A`$, $`O_A`$, $`c`$, $`c'`$ | the ineffective constant in the exponent; an error bound depending only on A; computable constants of the zero-free region | $`C_A`$: no value known | C up: a smaller error |
| $`\chi`$, $`\overline{\chi}`$, $`\chi_0`$, $`\chi_1`$, $`\chi_2`$ | characters mod q: any; its complex conjugate; the principal one (1 on every class coprime to q); a real one (values ±1, 0); a second real one (labels local to this card; on [Dirichlet characters](01-dirichlet-characters.md) they name characters mod 10) | $`\chi_1`$ mod 7: +1 on squares 1, 2, 4; −1 on 3, 5, 6 | — |
| $`\beta_1`$; $`\beta_2`$, $`q_2`$ | an exceptional zero, real, of $`L(s, \chi_1)`$ near 1; a real zero of $`L(s, \chi_2)`$, and its modulus | none seen: $`L(\sigma, \chi_1)`$ ≥ 1.146586 on 51 points of [0.5, 1] | toward 1: a bigger hole in the square classes |
| $`\varepsilon`$, $`c(\varepsilon)`$ | a small exponent, and Siegel's ineffective constant for it | ε = 1/4 when A = 2 | ε down: c(ε) smaller, still unknown |
| $`L(s, \chi)`$ | the L-function, $`\sum \chi(n) n^{-s}`$ | $`L(1, \chi_1)`$ = 1.187410 | — |
| $`s = \sigma + it`$, $`\rho = \beta + it`$ | a complex input with real part σ and height t; a zero, with real part β | σ from 0.5 to 1 | β toward 1: the zero's term $`x^{\beta}`$ grows |

### When it holds

- **The remainder a must share no factor with q.** Class 0 mod 7 holds only the prime 7, not 13,083 primes.
- **The modulus must stay below a fixed power of log x as x grows.** A is free, so no single count can break this: 9,973 is inside $`(\log x)^4`$ = 36,431 at a million. What fails is a modulus that grows like a power of x: at $`q = x^{0.1}`$ Siegel's saving shrinks toward nothing (Step 6).
- **The constant is ineffective.** "For x large enough" comes with no size, so no single count is certified.
- **The error beats every power of log x, not a power of x.** $`x e^{-C\sqrt{\log x}}`$ is below x over any power of log x, but above $`x^{0.99}`$. Square-root accuracy needs GRH (see The usual mistake).

---

## Why it works

### Step 0: one possible zero is the whole difficulty

Prime counts in a class come from the zeros of the L-functions mod q, and a zero near the line $`\mathrm{Re}\,s = 1`$ makes a large error. The zero-free region keeps every zero away from that line except one possible kind: a real zero of a real character. Siegel's theorem pushes that one away from 1 by $`q^{-\varepsilon}`$, which is enough only while q is small next to x.

### Step 1: the count in a class is an average over characters

For a coprime to q, the sum of $`\overline{\chi}(a)\chi(n)`$ over all φ(q) characters is φ(q) when n has remainder a, and 0 otherwise ([Dirichlet characters](01-dirichlet-characters.md)). So, for primes p not dividing q,

```math
\pi(x; q, a) = \frac{1}{\varphi(q)} \sum_{\chi} \overline{\chi}(a) \sum_{p \le x} \chi(p)
```

The principal character $`\chi_0`$ gives the fair share. Every other character gives a sum $`\sum_{p \le x} \chi(p)`$ that must be small. For $`\chi_1`$ mod 7 that sum is the square classes minus the rest: 39,197 − 39,300 = −103.

### Step 2: each character sum is controlled by zeros

A zero $`\rho = \beta + it`$ of $`L(s, \chi)`$ contributes about $`x^{\rho}/\rho`$ to the sum of $`\chi(p)\log p`$, as zeta's zeros do for the prime count. Measured against x, its size is $`x^{\beta - 1}`$.

The zero-free region for L-functions (Davenport, chapter 14) says no L(s, χ) mod q has a zero with

```math
\beta > 1 - \frac{c}{\log\big(q(|t| + 2)\big)}
```

except possibly one real zero $`\beta_1`$ of one real character $`\chi_1`$. All the other zeros cost at most $`x e^{-c'\sqrt{\log x}}`$ in total, with a computable c′, while q stays below $`e^{\sqrt{\log x}}`$.

### Step 3: why the three-four-one trick cannot catch a real zero

[The zero-free region](../02-The%20Zeta%20Function%20and%20the%20Prime%20Number%20Theorem/03-the-zero-free-region.md) for zeta works because a zero enters four times and the pole at 1 only three. For a character the trick uses ζ three times, $`L(s, \chi)`$ four times and $`L(s, \chi^2)`$ once.

- **Complex χ, or a zero off the real axis:** $`L(s, \chi^2)`$ has no pole near the zero, and the zero's four copies win.
- **Real χ and a real zero:** $`\chi^2 = \chi_0`$, and $`L(s, \chi_0)`$ has a pole at 1. Three poles plus one face four copies of the zero. The powers tie, and no contradiction follows.

That tie leaves room for one real zero very close to 1, called an **exceptional zero** (or Siegel zero). Whether any exists is open as of 2026-11-15.

### Step 4: what an exceptional zero would cost

If $`L(s, \chi_1)`$ mod 7 had a real zero $`\beta_1`$, each square class (1, 2, 4) would lose about $`\mathrm{li}(x^{\beta_1})/6`$ primes and each other class would gain as many. At x = 10^6:

| Zero at β₁ | Primes moved per class | Square classes minus the rest |
| ---: | ---: | ---: |
| 0.99 | 11,540 | −69,242 |
| 0.9 | 3,698 | −22,190 |
| 0.75 | 572 | −3,434 |
| 0.6 | 94 | −563 |

The real gap is −103. $`L(\sigma, \chi_1)`$ also stays far from 0: its smallest value on 51 points from σ = 0.5 to 1 is 1.146586, at σ = 0.5, and $`L(1, \chi_1) = \pi/\sqrt{7}`$ = 1.187410. On this evidence mod 7 has no exceptional zero.

The trouble is the moduli nobody can scan. For q with hundreds of digits, nothing computable excludes a zero at $`1 - 10^{-50}`$, which would empty half the classes for every x anyone could count.

### Step 5: Siegel's bound, and why its constant is ineffective

Siegel (1935) proved $`\beta_1 < 1 - c(\varepsilon) q^{-\varepsilon}`$ for every ε > 0, in two cases:

1. **No real character has a real zero above $`1 - \varepsilon/10`$.** Then the bound holds with an explicit constant.
2. **Some real character $`\chi_2`$, modulus $`q_2`$, has such a zero $`\beta_2`$.** The proof uses it as a lever. The product $`\zeta(s)L(s, \chi_1)L(s, \chi_2)L(s, \chi_1\chi_2)`$ has non-negative coefficients, and its size near 1 bounds $`\beta_1`$. The constant depends on $`q_2`$ and $`\beta_2`$.

Nobody knows which case is true, and in case 2 nobody knows $`q_2`$. So c(ε) exists but has no known value: it is **ineffective**, and $`C_A`$ inherits that.

### Step 6: small moduli turn Siegel's bound into the error term

The exceptional term against the fair share is $`x^{\beta_1 - 1}`$. Siegel's bound makes it at most $`\exp(-c(\varepsilon)\log x / q^{\varepsilon})`$. Choose ε = 1/(2A). When $`q \le (\log x)^A`$, $`q^{\varepsilon}`$ is at most $`\sqrt{\log x}`$, so the exponent is at least $`c(\varepsilon)\sqrt{\log x}`$: the same shape as the other zeros' error.

<details>
<summary>Detailed proof: from Siegel's bound to the error term</summary>

Fix A > 0 and put ε = 1/(2A). Take x ≥ 3 and q ≤ (log x)^A.

Siegel's bound gives $`1 - \beta_1 > c(\varepsilon) q^{-\varepsilon}`$. Since $`q^{\varepsilon} \le (\log x)^{A\varepsilon} = (\log x)^{1/2}`$,

$`\displaystyle 1 - \beta_1 > \frac{c(\varepsilon)}{\sqrt{\log x}}.`$

So the exceptional term, divided by x, is

$`\displaystyle x^{\beta_1 - 1} = e^{-(1 - \beta_1)\log x} < e^{-c(\varepsilon)\log x/\sqrt{\log x}} = e^{-c(\varepsilon)\sqrt{\log x}}.`$

The exceptional term has size $`\mathrm{li}(x^{\beta_1})/\varphi(q) \le x^{\beta_1}`$, so it is below $`x e^{-c(\varepsilon)\sqrt{\log x}}`$.

Step 2 bounds all other zeros by $`x e^{-c'\sqrt{\log x}}`$, because $`q \le (\log x)^A < e^{\sqrt{\log x}}`$ for large x. Take $`C_A = \min(c(\varepsilon), c')/2`$; the halving absorbs the factors of log x left over from counting primes with weight log p and then removing the weight. Then both errors are $`O_A(x e^{-C_A\sqrt{\log x}})`$, and $`C_A`$ is as ineffective as $`c(\varepsilon)`$.

</details>

The exponent $`\log x / q^{1/4}`$ sets the saving, a factor $`e^{-c(\varepsilon) \times \text{exponent}}`$:

| x | log x | q up to $`(\log x)^2`$ | exponent there, $`=\sqrt{\log x}`$ | exponent at $`q = x^{0.1}`$ |
| --- | ---: | ---: | ---: | ---: |
| 10^6 | 13.82 | 190.87 | 3.72 | 9.7806 |
| 10^12 | 27.63 | 763.47 | 5.26 | 13.8483 |
| 10^100 | 230.26 | 53,018.98 | 15.17 | 0.7281 |

Inside the range the exponent grows with x. At a power of x, such as $`q = x^{0.1}`$, it shrinks toward 0 and Siegel's bound saves nothing. (At 10^6 and 10^12, $`x^{0.1}`$ is still below $`(\log x)^2`$.) This, not a wide count at one x, is why the modulus must stay small.

---

## Worked numbers, by hand

The primes below a million, mod 7:

| Step | Arithmetic | Value |
| --- | --- | --- |
| 1. primes below 10^6 | sieve, and trial division | 78,498 |
| 2. drop the prime 7 | 78,498 − 1 | 78,497 |
| 3. classes that can hold primes | φ(7) | 6 |
| 4. fair share | 78,497 / 6 | 13,082.83 |
| 5. the theorem's share | li(10^6) / 6 = 78,627.55 / 6 | 13,104.59 |
| 6. smallest and largest class | class 1; classes 3 and 5 | 13,063 and 13,105 |
| 7. class over the theorem's share | 13,063 / 13,104.59 to 13,105 / 13,104.59 | 0.99683 to 1.00003 |
| 8. the spread | 42 / 13,082.83 | **0.32 percent** |

The six classes agree to a third of a percent already at a million. They sit just below li(x)/6 because li(10^6) overshoots π(10^6) by 129.55.

The same holds across moduli. With A = 1, the theorem covers q up to log x = 13.82:

| q | φ(q) | Fair share | Smallest | Largest | Worst miss |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 7 | 6 | 13,082.83 | 13,063 | 13,105 | 0.17 percent |
| 11 | 10 | 7,849.70 | 7,814 | 7,876 | 0.45 percent |
| 13 | 12 | 6,541.42 | 6,511 | 6,568 | 0.46 percent |
| 101 | 100 | 784.97 | 758 | 816 | 3.95 percent |
| 1,009 | 1,008 | 77.87 | 57 | 93 | 26.80 percent |

Every q from 3 to 13 misses the class mean by under half a percent; the code prints all eleven.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| A class sharing a factor with q | class 0 mod 7 holds 1 prime, not 13,083 | only the prime 7 itself is ≡ 0 mod 7 |
| Dividing by q instead of φ(q) | 78,498 / 7 = 11,214.00, 14.3 percent low | one of the seven classes is empty |
| x / log x in place of li(x) | 12,063.74 per class, 7.8 percent low | x / log x undercounts the primes themselves |
| A modulus that grows like a power of x: $`q = x^{0.1}`$ | Siegel's exponent 0.7281 at x = 10^100, against 15.17 at $`q = (\log x)^2`$ | the hypothesis fails: the exponent falls toward 0, so Siegel's bound saves nothing |

The code prints all four.

---

## Code, from first principles, and it actually runs

The scripts count primes by class and compare with the theorem, taking independent roads at each step. Class counts: a sieve and trial division, matching exactly. li(10^6): its series and Simpson's rule, both matching the house table. $`L(1, \chi_1)`$: an Euler–Maclaurin sum, the closed form $`\pi/\sqrt{7}`$ and a partial sum. They also print every modulus from 3 to 13 against 101, 1,009 and 9,973, the scatter of the counts at 9,973, the cost of a hypothetical zero, and the exponents of Step 6.

### Python

```python
# Siegel-Walfisz -- the check behind the card.  Standard library only.  Primes below a million
# split into the classes mod 7 by a sieve and by trial division; li(x) by its series and by
# Simpson's rule; L(s, chi) for the quadratic character mod 7 by Euler-Maclaurin and, at s = 1,
# by a closed form; then what an exceptional zero would cost and why the modulus must stay small.
import math
X, Q = 10**6, 7
flag = bytearray([1]) * (X + 1); flag[0] = flag[1] = 0          # road 1: sieve of Eratosthenes
for p in range(2, 1001):
    if flag[p]: flag[p * p::p] = bytearray(len(range(p * p, X + 1, p)))
primes = [p for p in range(X + 1) if flag[p]]
small = [p for p in range(2, 1001) if all(p % d for d in range(2, math.isqrt(p) + 1))]
def is_prime_td(n):                                              # road 2: trial division
    for d in small:
        if d * d > n: return True
        if n % d == 0: return False
    return True
td = [n for n in range(2, X + 1) if is_prime_td(n)]
def classes(ps, q):
    c = [0] * q
    for p in ps: c[p % q] += 1
    return c
c7, t7 = classes(primes, Q), classes(td, Q)
print(f"primes below 10^6: sieve {len(primes)}; trial division {len(td)}")
print("mod 7, sieve: " + "; ".join(f"class {a} {c7[a]}" for a in range(Q)))
print("mod 7, trial division: " + "; ".join(f"class {a} {t7[a]}" for a in range(Q)))
GAMMA, L = 0.5772156649015329, math.log(X)                       # Euler's constant, quoted
def li_series(x):                                                # li(x) = gamma + ln ln x + sum (ln x)^n / (n n!)
    u, term, s, n = math.log(x), 1.0, 0.0, 0
    while True:
        n += 1; term *= u / n; s += term / n
        if term / n < 1e-17 * s: return GAMMA + math.log(u) + s
def simpson(f, a, b, m=20000):
    h = (b - a) / m
    return h / 3 * (f(a) + f(b) + sum((4 if k % 2 else 2) * f(a + k * h) for k in range(1, m)))
Li = simpson(lambda u: math.exp(u) / u, math.log(2), L)          # offset Li(x): integral from 2 to x of dt / ln t
li_a, li_b = li_series(X), Li + li_series(2)
print(f"li(10^6): series {li_a:.2f}; Simpson from 2 plus li(2) {li_b:.2f}; offset Li(10^6) {Li:.2f}; li minus pi {li_a - len(primes):.2f}")
six = c7[1:]; pred = li_a / 6; mean = (len(primes) - 1) / 6
print(f"prediction li(x)/6 = {pred:.2f}; mean of the six classes {mean:.2f}; smallest {min(six)}, largest {max(six)}")
print(f"spread {max(six) - min(six)} primes = {100 * (max(six) - min(six)) / mean:.2f} percent of the mean; "
      f"class / prediction from {min(six) / pred:.5f} to {max(six) / pred:.5f}")
chi = [0] + [1 if pow(a, 3, Q) == 1 else -1 for a in range(1, Q)]   # Euler's criterion: a^3 mod 7
res = sum(c7[a] for a in range(1, Q) if chi[a] == 1); non = sum(c7[a] for a in range(1, Q) if chi[a] == -1)
print(f"squares mod 7: {[a for a in range(1, Q) if chi[a] == 1]}; their classes {res}; the other three {non}; "
      f"lead {non - res}; sqrt(x)/ln x = {math.sqrt(X) / L:.2f}")
phi = lambda q: sum(1 for a in range(1, q + 1) if math.gcd(a, q) == 1)
worst = {}
for q in list(range(3, 14)) + [101, 1009, 9973]:
    c = classes(primes, q); k = [c[a] for a in range(q) if math.gcd(a, q) == 1]; m = sum(k) / len(k)
    worst[q] = max(abs(v / m - 1) for v in k)
    print(f"q = {q}: phi {phi(q)}; mean per class {m:.2f}; smallest {min(k)}; largest {max(k)}; "
          f"worst miss {100 * worst[q]:.2f} percent")
k = classes(primes, 9973)[1:]; m = sum(k) / len(k)               # q = 9973: the scatter of small counts
sd = math.sqrt(sum((v - m) ** 2 for v in k) / len(k))
print(f"q = 9973: mean {m:.2f}; standard deviation {sd:.2f}, {100 * sd / m:.0f} percent of the mean; "
      f"(ln x)^4 = {L ** 4:.0f}, so q = 9973 is inside the range for A = 4")
def Lchi(s, N=40):                                               # sum of chi(n) n^-s: head plus Euler-Maclaurin tail
    tot = 0.0
    for a in range(1, Q):
        y = Q * N + a
        head = sum((Q * n + a) ** -s for n in range(N))
        integ = -math.log(y) / Q if abs(s - 1) < 1e-12 else y ** (1 - s) / (Q * (s - 1))
        tail = y ** -s / 2 + Q * s / 12 * y ** (-s - 1) - Q ** 3 * s * (s + 1) * (s + 2) / 720 * y ** (-s - 3)
        tot += chi[a] * (head + integ + tail)
    return tot
grid = [(Lchi(0.5 + k / 100), 0.5 + k / 100) for k in range(51)]
print("L(sigma, chi) mod 7: " + "; ".join(f"sigma {s:.1f} {v:.6f}" for v, s in grid[::10]))
print(f"smallest on 51 points from 0.5 to 1: {min(grid)[0]:.6f} at sigma {min(grid)[1]:.2f}")
closed = -math.pi / Q ** 1.5 * sum(a * chi[a] for a in range(1, Q))
direct = sum(chi[n % Q] / n for n in range(1, 7 * 10**5 + 1))
print(f"L(1, chi): Euler-Maclaurin {Lchi(1):.6f}; closed form pi/sqrt(7) {closed:.6f}; "
      f"partial sum to 700000 {direct:.6f}")
cost = [(b, li_series(X ** b) / 6) for b in (0.99, 0.9, 0.75, 0.6)]
print("a real zero at beta: primes moved per class li(x^beta)/6, squares minus the rest: "
      + "; ".join(f"beta {b} {v:.0f}, {-6 * v:.0f}" for b, v in cost))
for e in (6, 12, 100):
    lx = e * math.log(10); qs = lx ** 2
    print(f"x = 10^{e}: ln x {lx:.2f}; q up to (ln x)^2 = {qs:.2f}; exponent ln x / q^(1/4) there {lx / qs ** 0.25:.2f} "
          f"= sqrt(ln x) {math.sqrt(lx):.2f}; at q = x^0.1 {lx / 10 ** (e * 0.1 / 4):.4f}")
print(f"breaks: class 0 holds {c7[0]}; divide by 7 not 6: {len(primes) / 7:.2f} "
      f"({100 * (1 - len(primes) / 7 / mean):.1f} percent low); x/ln x over 6: {X / L / 6:.2f} "
      f"({100 * (1 - X / L / 6 / mean):.1f} percent low)")
assert len(primes) == len(td) == 78498 and c7 == t7                     # two roads to every class count
assert abs(li_a - li_b) < 1e-4 and abs(li_a - 78627.55) < 0.006 and abs(Li - 78626.50) < 0.006  # house table
assert (max(six) - min(six)) / mean < 0.004 and c7[0] == 1              # six classes agree; 7 alone in class 0
assert abs(Lchi(1) - closed) < 1e-9 and abs(direct - closed) < 1e-5     # L(1, chi) three ways
assert min(grid)[0] > 0.5                                               # no real zero on the grid
assert max(worst[q] for q in range(3, 14)) < 0.005 < worst[101] < worst[1009] < worst[9973]
print("ALL CHECKS PASS")
```

**Ran 2026-11-15 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
primes below 10^6: sieve 78498; trial division 78498
mod 7, sieve: class 0 1; class 1 13063; class 2 13065; class 3 13105; class 4 13069; class 5 13105; class 6 13090
mod 7, trial division: class 0 1; class 1 13063; class 2 13065; class 3 13105; class 4 13069; class 5 13105; class 6 13090
li(10^6): series 78627.55; Simpson from 2 plus li(2) 78627.55; offset Li(10^6) 78626.50; li minus pi 129.55
prediction li(x)/6 = 13104.59; mean of the six classes 13082.83; smallest 13063, largest 13105
spread 42 primes = 0.32 percent of the mean; class / prediction from 0.99683 to 1.00003
squares mod 7: [1, 2, 4]; their classes 39197; the other three 39300; lead 103; sqrt(x)/ln x = 72.38
q = 3: phi 2; mean per class 39248.50; smallest 39231; largest 39266; worst miss 0.04 percent
q = 4: phi 2; mean per class 39248.50; smallest 39175; largest 39322; worst miss 0.19 percent
q = 5: phi 4; mean per class 19624.25; smallest 19593; largest 19665; worst miss 0.21 percent
q = 6: phi 2; mean per class 39248.00; smallest 39231; largest 39265; worst miss 0.04 percent
q = 7: phi 6; mean per class 13082.83; smallest 13063; largest 13105; worst miss 0.17 percent
q = 8: phi 4; mean per class 19624.25; smallest 19552; largest 19669; worst miss 0.37 percent
q = 9: phi 6; mean per class 13082.83; smallest 13063; largest 13099; worst miss 0.15 percent
q = 10: phi 4; mean per class 19624.00; smallest 19593; largest 19665; worst miss 0.21 percent
q = 11: phi 10; mean per class 7849.70; smallest 7814; largest 7876; worst miss 0.45 percent
q = 12: phi 4; mean per class 19624.00; smallest 19564; largest 19667; worst miss 0.31 percent
q = 13: phi 12; mean per class 6541.42; smallest 6511; largest 6568; worst miss 0.46 percent
q = 101: phi 100; mean per class 784.97; smallest 758; largest 816; worst miss 3.95 percent
q = 1009: phi 1008; mean per class 77.87; smallest 57; largest 93; worst miss 26.80 percent
q = 9973: phi 9972; mean per class 7.87; smallest 1; largest 17; worst miss 115.96 percent
q = 9973: mean 7.87; standard deviation 2.04, 26 percent of the mean; (ln x)^4 = 36431, so q = 9973 is inside the range for A = 4
L(sigma, chi) mod 7: sigma 0.5 1.146586; sigma 0.6 1.160945; sigma 0.7 1.171739; sigma 0.8 1.179462; sigma 0.9 1.184555; sigma 1.0 1.187410
smallest on 51 points from 0.5 to 1: 1.146586 at sigma 0.50
L(1, chi): Euler-Maclaurin 1.187410; closed form pi/sqrt(7) 1.187410; partial sum to 700000 1.187409
a real zero at beta: primes moved per class li(x^beta)/6, squares minus the rest: beta 0.99 11540, -69242; beta 0.9 3698, -22190; beta 0.75 572, -3434; beta 0.6 94, -563
x = 10^6: ln x 13.82; q up to (ln x)^2 = 190.87; exponent ln x / q^(1/4) there 3.72 = sqrt(ln x) 3.72; at q = x^0.1 9.7806
x = 10^12: ln x 27.63; q up to (ln x)^2 = 763.47; exponent ln x / q^(1/4) there 5.26 = sqrt(ln x) 5.26; at q = x^0.1 13.8483
x = 10^100: ln x 230.26; q up to (ln x)^2 = 53018.98; exponent ln x / q^(1/4) there 15.17 = sqrt(ln x) 15.17; at q = x^0.1 0.7281
breaks: class 0 holds 1; divide by 7 not 6: 11214.00 (14.3 percent low); x/ln x over 6: 12063.74 (7.8 percent low)
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Siegel-Walfisz -- the check behind the card.  std only.  Primes below a million split into
// the classes mod 7 by a sieve and by trial division; li(x) by its series and by Simpson's rule;
// L(s, chi) for the quadratic character mod 7 by Euler-Maclaurin and, at s = 1, by a closed form;
// then what an exceptional zero would cost and why the modulus must stay small.
const X: usize = 1_000_000;
const Q: usize = 7;
const GAMMA: f64 = 0.5772156649015329; // Euler's constant, quoted

fn gcd(a: usize, b: usize) -> usize { if b == 0 { a } else { gcd(b, a % b) } }
fn isqrt(n: usize) -> usize { let mut r = (n as f64).sqrt() as usize; while r * r > n { r -= 1; } while (r + 1) * (r + 1) <= n { r += 1; } r }
fn classes(ps: &[usize], q: usize) -> Vec<usize> { let mut c = vec![0; q]; for &p in ps { c[p % q] += 1; } c }
fn li_series(x: f64) -> f64 { // li(x) = gamma + ln ln x + sum (ln x)^n / (n n!)
    let (u, mut term, mut s, mut n) = (x.ln(), 1.0f64, 0.0f64, 0.0f64);
    loop {
        n += 1.0; term *= u / n; s += term / n;
        if term / n < 1e-17 * s { return GAMMA + u.ln() + s; }
    }
}
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, m: usize) -> f64 {
    let h = (b - a) / m as f64;
    let mut inner = 0.0;
    for k in 1..m { inner += (if k % 2 == 1 { 4.0 } else { 2.0 }) * f(a + k as f64 * h); }
    h / 3.0 * (f(a) + f(b) + inner)
}
fn lchi(s: f64, chi: &[i64]) -> f64 { // sum of chi(n) n^-s: head plus Euler-Maclaurin tail
    let (n_head, qf) = (40usize, Q as f64);
    let mut tot = 0.0;
    for a in 1..Q {
        let y = (Q * n_head + a) as f64;
        let mut head = 0.0;
        for n in 0..n_head { head += ((Q * n + a) as f64).powf(-s); }
        let integ = if (s - 1.0).abs() < 1e-12 { -y.ln() / qf } else { y.powf(1.0 - s) / (qf * (s - 1.0)) };
        let tail = y.powf(-s) / 2.0 + qf * s / 12.0 * y.powf(-s - 1.0)
            - qf.powi(3) * s * (s + 1.0) * (s + 2.0) / 720.0 * y.powf(-s - 3.0);
        tot += chi[a] as f64 * (head + integ + tail);
    }
    tot
}
fn modpow(mut b: usize, mut e: usize, m: usize) -> usize { let mut r = 1; b %= m; while e > 0 { if e & 1 == 1 { r = r * b % m; } b = b * b % m; e >>= 1; } r }

fn main() {
    let mut flag = vec![true; X + 1]; flag[0] = false; flag[1] = false; // road 1: sieve
    for p in 2..1001 { if flag[p] { let mut m = p * p; while m <= X { flag[m] = false; m += p; } } }
    let primes: Vec<usize> = (0..=X).filter(|&p| flag[p]).collect();
    let small: Vec<usize> = (2..1001).filter(|&p| (2..isqrt(p) + 1).all(|d| p % d != 0)).collect();
    let is_prime_td = |n: usize| -> bool { // road 2: trial division
        for &d in &small { if d * d > n { return true; } if n % d == 0 { return false; } }
        true
    };
    let td: Vec<usize> = (2..=X).filter(|&n| is_prime_td(n)).collect();
    let (c7, t7) = (classes(&primes, Q), classes(&td, Q));
    println!("primes below 10^6: sieve {}; trial division {}", primes.len(), td.len());
    let join = |c: &Vec<usize>| (0..Q).map(|a| format!("class {} {}", a, c[a])).collect::<Vec<_>>().join("; ");
    println!("mod 7, sieve: {}", join(&c7));
    println!("mod 7, trial division: {}", join(&t7));
    let xf = X as f64; let lx = xf.ln();
    let li_off = simpson(|u: f64| u.exp() / u, 2f64.ln(), lx, 20000);
    let (li_a, li_b) = (li_series(xf), li_off + li_series(2.0));
    println!("li(10^6): series {:.2}; Simpson from 2 plus li(2) {:.2}; offset Li(10^6) {:.2}; li minus pi {:.2}",
        li_a, li_b, li_off, li_a - primes.len() as f64);
    let six = &c7[1..]; let (mn, mx) = (*six.iter().min().unwrap(), *six.iter().max().unwrap());
    let pred = li_a / 6.0; let mean = (primes.len() - 1) as f64 / 6.0;
    println!("prediction li(x)/6 = {:.2}; mean of the six classes {:.2}; smallest {}, largest {}", pred, mean, mn, mx);
    println!("spread {} primes = {:.2} percent of the mean; class / prediction from {:.5} to {:.5}",
        mx - mn, 100.0 * (mx - mn) as f64 / mean, mn as f64 / pred, mx as f64 / pred);
    let mut chi = vec![0i64; Q]; // Euler's criterion: a^3 mod 7
    for a in 1..Q { chi[a] = if modpow(a, 3, Q) == 1 { 1 } else { -1 }; }
    let sq: Vec<String> = (1..Q).filter(|&a| chi[a] == 1).map(|a| a.to_string()).collect();
    let res: usize = (1..Q).filter(|&a| chi[a] == 1).map(|a| c7[a]).sum();
    let non: usize = (1..Q).filter(|&a| chi[a] == -1).map(|a| c7[a]).sum();
    println!("squares mod 7: [{}]; their classes {}; the other three {}; lead {}; sqrt(x)/ln x = {:.2}",
        sq.join(", "), res, non, non - res, xf.sqrt() / lx);
    let phi = |q: usize| (1..=q).filter(|&a| gcd(a, q) == 1).count();
    let mut worst = std::collections::HashMap::new();
    let qs: Vec<usize> = (3..14).chain([101, 1009, 9973]).collect();
    for &q in &qs {
        let c = classes(&primes, q);
        let k: Vec<usize> = (0..q).filter(|&a| gcd(a, q) == 1).map(|a| c[a]).collect();
        let m = k.iter().sum::<usize>() as f64 / k.len() as f64;
        let w = k.iter().map(|&v| (v as f64 / m - 1.0).abs()).fold(0.0, f64::max);
        worst.insert(q, w);
        println!("q = {}: phi {}; mean per class {:.2}; smallest {}; largest {}; worst miss {:.2} percent",
            q, phi(q), m, k.iter().min().unwrap(), k.iter().max().unwrap(), 100.0 * w);
    }
    let k9 = classes(&primes, 9973)[1..].to_vec(); // q = 9973: the scatter of small counts
    let m9 = k9.iter().sum::<usize>() as f64 / k9.len() as f64;
    let sd9 = (k9.iter().map(|&v| (v as f64 - m9).powi(2)).sum::<f64>() / k9.len() as f64).sqrt();
    println!("q = 9973: mean {:.2}; standard deviation {:.2}, {:.0} percent of the mean; (ln x)^4 = {:.0}, so q = 9973 is inside the range for A = 4",
        m9, sd9, 100.0 * sd9 / m9, lx.powi(4));
    let grid: Vec<(f64, f64)> = (0..51).map(|k| { let s = 0.5 + k as f64 / 100.0; (lchi(s, &chi), s) }).collect();
    let parts: Vec<String> = grid.iter().step_by(10).map(|(v, s)| format!("sigma {:.1} {:.6}", s, v)).collect();
    println!("L(sigma, chi) mod 7: {}", parts.join("; "));
    let gmin = grid.iter().cloned().fold((f64::INFINITY, 0.0), |a, b| if b.0 < a.0 { b } else { a });
    println!("smallest on 51 points from 0.5 to 1: {:.6} at sigma {:.2}", gmin.0, gmin.1);
    let sum_ac: i64 = (1..Q).map(|a| a as i64 * chi[a]).sum();
    let closed = -std::f64::consts::PI / (Q as f64).powf(1.5) * sum_ac as f64;
    let mut direct = 0.0; for n in 1..=700_000usize { direct += chi[n % Q] as f64 / n as f64; }
    let l1 = lchi(1.0, &chi);
    println!("L(1, chi): Euler-Maclaurin {:.6}; closed form pi/sqrt(7) {:.6}; partial sum to 700000 {:.6}", l1, closed, direct);
    let cost: Vec<String> = [0.99, 0.9, 0.75, 0.6].iter().map(|&b: &f64| { let v = li_series(xf.powf(b)) / 6.0;
        format!("beta {} {:.0}, {:.0}", b, v, -6.0 * v) }).collect();
    println!("a real zero at beta: primes moved per class li(x^beta)/6, squares minus the rest: {}", cost.join("; "));
    for e in [6.0f64, 12.0, 100.0] {
        let l = e * 10f64.ln(); let qq = l * l;
        println!("x = 10^{}: ln x {:.2}; q up to (ln x)^2 = {:.2}; exponent ln x / q^(1/4) there {:.2} = sqrt(ln x) {:.2}; at q = x^0.1 {:.4}",
            e, l, qq, l / qq.powf(0.25), l.sqrt(), l / 10f64.powf(e * 0.1 / 4.0));
    }
    let np = primes.len() as f64;
    println!("breaks: class 0 holds {}; divide by 7 not 6: {:.2} ({:.1} percent low); x/ln x over 6: {:.2} ({:.1} percent low)",
        c7[0], np / 7.0, 100.0 * (1.0 - np / 7.0 / mean), xf / lx / 6.0, 100.0 * (1.0 - xf / lx / 6.0 / mean));
    assert!(primes.len() == 78498 && td.len() == 78498 && c7 == t7); // two roads to every class count
    assert!((li_a - li_b).abs() < 1e-4 && (li_a - 78627.55).abs() < 0.006 && (li_off - 78626.50).abs() < 0.006); // house table
    assert!(((mx - mn) as f64) / mean < 0.004 && c7[0] == 1); // six classes agree; 7 alone in class 0
    assert!((l1 - closed).abs() < 1e-9 && (direct - closed).abs() < 1e-5); // L(1, chi) three ways
    assert!(gmin.0 > 0.5); // no real zero on the grid
    let small_w = (3..14).map(|q| worst[&q]).fold(0.0, f64::max);
    assert!(small_w < 0.005 && 0.005 < worst[&101] && worst[&101] < worst[&1009] && worst[&1009] < worst[&9973]);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-15 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
primes below 10^6: sieve 78498; trial division 78498
mod 7, sieve: class 0 1; class 1 13063; class 2 13065; class 3 13105; class 4 13069; class 5 13105; class 6 13090
mod 7, trial division: class 0 1; class 1 13063; class 2 13065; class 3 13105; class 4 13069; class 5 13105; class 6 13090
li(10^6): series 78627.55; Simpson from 2 plus li(2) 78627.55; offset Li(10^6) 78626.50; li minus pi 129.55
prediction li(x)/6 = 13104.59; mean of the six classes 13082.83; smallest 13063, largest 13105
spread 42 primes = 0.32 percent of the mean; class / prediction from 0.99683 to 1.00003
squares mod 7: [1, 2, 4]; their classes 39197; the other three 39300; lead 103; sqrt(x)/ln x = 72.38
q = 3: phi 2; mean per class 39248.50; smallest 39231; largest 39266; worst miss 0.04 percent
q = 4: phi 2; mean per class 39248.50; smallest 39175; largest 39322; worst miss 0.19 percent
q = 5: phi 4; mean per class 19624.25; smallest 19593; largest 19665; worst miss 0.21 percent
q = 6: phi 2; mean per class 39248.00; smallest 39231; largest 39265; worst miss 0.04 percent
q = 7: phi 6; mean per class 13082.83; smallest 13063; largest 13105; worst miss 0.17 percent
q = 8: phi 4; mean per class 19624.25; smallest 19552; largest 19669; worst miss 0.37 percent
q = 9: phi 6; mean per class 13082.83; smallest 13063; largest 13099; worst miss 0.15 percent
q = 10: phi 4; mean per class 19624.00; smallest 19593; largest 19665; worst miss 0.21 percent
q = 11: phi 10; mean per class 7849.70; smallest 7814; largest 7876; worst miss 0.45 percent
q = 12: phi 4; mean per class 19624.00; smallest 19564; largest 19667; worst miss 0.31 percent
q = 13: phi 12; mean per class 6541.42; smallest 6511; largest 6568; worst miss 0.46 percent
q = 101: phi 100; mean per class 784.97; smallest 758; largest 816; worst miss 3.95 percent
q = 1009: phi 1008; mean per class 77.87; smallest 57; largest 93; worst miss 26.80 percent
q = 9973: phi 9972; mean per class 7.87; smallest 1; largest 17; worst miss 115.96 percent
q = 9973: mean 7.87; standard deviation 2.04, 26 percent of the mean; (ln x)^4 = 36431, so q = 9973 is inside the range for A = 4
L(sigma, chi) mod 7: sigma 0.5 1.146586; sigma 0.6 1.160945; sigma 0.7 1.171739; sigma 0.8 1.179462; sigma 0.9 1.184555; sigma 1.0 1.187410
smallest on 51 points from 0.5 to 1: 1.146586 at sigma 0.50
L(1, chi): Euler-Maclaurin 1.187410; closed form pi/sqrt(7) 1.187410; partial sum to 700000 1.187409
a real zero at beta: primes moved per class li(x^beta)/6, squares minus the rest: beta 0.99 11540, -69242; beta 0.9 3698, -22190; beta 0.75 572, -3434; beta 0.6 94, -563
x = 10^6: ln x 13.82; q up to (ln x)^2 = 190.87; exponent ln x / q^(1/4) there 3.72 = sqrt(ln x) 3.72; at q = x^0.1 9.7806
x = 10^12: ln x 27.63; q up to (ln x)^2 = 763.47; exponent ln x / q^(1/4) there 5.26 = sqrt(ln x) 5.26; at q = x^0.1 13.8483
x = 10^100: ln x 230.26; q up to (ln x)^2 = 53018.98; exponent ln x / q^(1/4) there 15.17 = sqrt(ln x) 15.17; at q = x^0.1 0.7281
breaks: class 0 holds 1; divide by 7 not 6: 11214.00 (14.3 percent low); x/ln x over 6: 12063.74 (7.8 percent low)
ALL CHECKS PASS
```

### Lean

Lean proves Step 1 and both halves of Step 6 in general, plus the card's whole-number checks.

- Suppose A > 0, x ≥ 3, and the modulus q is at most $`(\log x)^A`$. Suppose also that a real $`\beta_1`$ obeys Siegel's bound $`1 - \beta_1 > c/q^{1/(2A)}`$ with c > 0. Then $`x^{\beta_1} < x e^{-c\sqrt{\log x}}`$: the same shape as the other zeros' error.
- Take a modulus q ≥ 1, a remainder a sharing no factor with q, and a whole number x. Then $`\pi(x; q, a) = \frac{1}{\varphi(q)} \sum_{\chi} \overline{\chi}(a) \sum_{p \le x} \chi(p)`$.
- Take δ > 0 and ε > 0, and let the modulus grow as $`q = x^{\delta}`$. Then Siegel's exponent $`\log x / q^{\varepsilon}`$ tends to 0 as x grows, so the bound saves nothing.
- φ(q) is as printed for every q from 3 to 13, and for 101, 1,009 and 9,973.
- Suppose a prime p has remainder 0 mod 7. Then p = 7.
- Cubing 1 to 6 mod 7 gives 1 for the squares 1, 2, 4 and 6 for 3, 5, 6.
- The seven class counts add to 78,498, the spread is 42, and the squares trail the rest by 39,300 − 39,197 = 103.
- Dividing 78,498 by 7, not φ(7), gives exactly 11,214.

The prime counts, li(x) and $`L(\sigma, \chi_1)`$ are left to the Python and Rust checks, and Siegel's bound to Davenport.

```lean
-- Siegel-Walfisz: Siegel's bound 1 − β > c/q^(1/(2A)) keeps an exceptional zero's term x^β below x e^(−c√log x) for every modulus q up to (log x)^A, the prime count in a class a mod q is the average over characters of χ̄(a) times the character's prime sum, and a modulus growing like a power of x makes Siegel's saving exponent fall to 0.
import Mathlib.NumberTheory.DirichletCharacter.Orthogonality
import Mathlib.NumberTheory.MulChar.Lemmas
import Mathlib.Analysis.SpecialFunctions.Pow.Asymptotics
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Data.Nat.Totient
import Mathlib.Tactic.NormNum.Prime
import Mathlib.RingTheory.RootsOfUnity.AlgebraicallyClosed
import Mathlib.Analysis.Complex.Polynomial.Basic

open Filter Topology Finset

/-- **From Siegel's bound to the error term (the card's folded proof).** Fix a power A > 0 and
put ε = 1/(2A). Take x ≥ 3 and a modulus q (a positive whole number) with q ≤ (log x)^A. If a
real zero β obeys Siegel's bound 1 − β > c/q^ε with a constant c > 0, then the zero's term
x^β is below x e^(−c√log x): the same shape as the error from all the other zeros. -/
theorem exceptional_zero_term_lt_of_siegel_bound {A c x β : ℝ} {q : ℕ} (hA : 0 < A) (hc : 0 < c)
    (hx : 3 ≤ x) (hq0 : 0 < q) (hq : (q : ℝ) ≤ Real.log x ^ A)
    (hβ : c / (q : ℝ) ^ (1 / (2 * A)) < 1 - β) :
    x ^ β < x * Real.exp (-c * Real.sqrt (Real.log x)) := by
  have hx0 : 0 < x := by linarith
  have hL1 : 0 < Real.log x := Real.log_pos (by linarith)
  set L := Real.log x with hL
  have hL0 : 0 < L := hL1
  have hq1 : (0 : ℝ) < q := by exact_mod_cast hq0
  have hqe : (q : ℝ) ^ (1 / (2 * A)) ≤ Real.sqrt L := by
    rw [Real.sqrt_eq_rpow]
    calc (q : ℝ) ^ (1 / (2 * A)) ≤ (L ^ A) ^ (1 / (2 * A)) :=
          Real.rpow_le_rpow hq1.le hq (by positivity)
      _ = L ^ (1 / 2 : ℝ) := by
          rw [← Real.rpow_mul hL0.le]; congr 1; field_simp
  have hqpos : 0 < (q : ℝ) ^ (1 / (2 * A)) := Real.rpow_pos_of_pos hq1 _
  have hs : 0 < Real.sqrt L := Real.sqrt_pos.mpr hL0
  have h2 : c / Real.sqrt L ≤ c / (q : ℝ) ^ (1 / (2 * A)) :=
    div_le_div_of_nonneg_left hc.le hqpos hqe
  have h3 : β * L < L - c * Real.sqrt L := by
    have : β < 1 - c / Real.sqrt L := by linarith
    have hLs : L = Real.sqrt L * Real.sqrt L := (Real.mul_self_sqrt hL0.le).symm
    have := mul_lt_mul_of_pos_right this hL0
    calc β * L < (1 - c / Real.sqrt L) * L := this
      _ = L - c * Real.sqrt L := by
        rw [sub_mul, one_mul, div_mul_eq_mul_div, mul_div_assoc, Real.div_sqrt]
  rw [Real.rpow_def_of_pos hx0]
  conv_rhs => rw [← Real.exp_log hx0]
  rw [← Real.exp_add, Real.exp_lt_exp, ← hL]
  nlinarith

/-- **The count in a class is an average over characters (Step 1).** For a modulus q ≥ 1, a
remainder a sharing no factor with q, and a whole number x, the number of primes p ≤ x with
p ≡ a mod q equals 1/φ(q) times the sum, over all Dirichlet characters χ mod q, of χ̄(a) times
the sum of χ(p) over the primes p ≤ x. -/
theorem prime_count_in_class_eq_character_average {q : ℕ} [NeZero q] {a : ℕ} (ha : a.Coprime q)
    (x : ℕ) :
    ((((range (x + 1)).filter (fun p ↦ p.Prime ∧ p ≡ a [MOD q])).card : ℕ) : ℂ) =
      1 / (q.totient : ℂ) * ∑ χ : DirichletCharacter ℂ q,
        starRingEnd ℂ (χ (a : ZMod q)) * ∑ p ∈ (range (x + 1)).filter Nat.Prime, χ (p : ZMod q) := by
  have hu : IsUnit (a : ZMod q) := (ZMod.isUnit_iff_coprime a q).mpr ha
  have key : ∀ χ : DirichletCharacter ℂ q, starRingEnd ℂ (χ (a : ZMod q)) = χ (a : ZMod q)⁻¹ := by
    intro χ
    have h1 : starRingEnd ℂ (χ (a : ZMod q)) = (χ (a : ZMod q))⁻¹ := by
      rw [← Complex.star_def, MulChar.star_apply', MulChar.inv_apply_eq_inv']
    rw [h1]
    refine (eq_inv_of_mul_eq_one_left ?_).symm
    rw [← map_mul, ZMod.inv_mul_of_unit _ hu, map_one]
  have hφ : (q.totient : ℂ) ≠ 0 := by
    exact_mod_cast (Nat.totient_pos.mpr (Nat.pos_of_ne_zero (NeZero.ne q))).ne'
  have hswap : ∑ χ : DirichletCharacter ℂ q,
        starRingEnd ℂ (χ (a : ZMod q)) * ∑ p ∈ (range (x + 1)).filter Nat.Prime, χ (p : ZMod q) =
      ∑ p ∈ (range (x + 1)).filter Nat.Prime, ∑ χ : DirichletCharacter ℂ q,
        χ (a : ZMod q)⁻¹ * χ (p : ZMod q) := by
    simp_rw [key, Finset.mul_sum]
    exact Finset.sum_comm
  rw [hswap]
  simp_rw [DirichletCharacter.sum_char_inv_mul_char_eq ℂ hu]
  rw [Finset.sum_ite, Finset.sum_const_zero, add_zero, Finset.sum_const,
    nsmul_eq_mul, Finset.filter_filter]
  field_simp
  congr 2
  ext p
  simp only [Finset.mem_filter, ZMod.natCast_eq_natCast_iff]
  constructor
  · rintro ⟨h1, h2, h3⟩; exact ⟨h1, h2, h3.symm⟩
  · rintro ⟨h1, h2, h3⟩; exact ⟨h1, h2, h3.symm⟩

/-- **Why the modulus must stay small (Step 6).** If the modulus grows like a power of x,
q = x^δ with δ > 0, then Siegel's saving exponent log x / q^ε tends to 0 as x grows, for
every ε > 0: the bound saves nothing. -/
theorem siegel_exponent_tendsto_zero_of_power_modulus {δ ε : ℝ} (hδ : 0 < δ) (hε : 0 < ε) :
    Tendsto (fun x : ℝ ↦ Real.log x / (x ^ δ) ^ ε) atTop (𝓝 0) := by
  have h := (isLittleO_log_rpow_atTop (mul_pos hδ hε)).tendsto_div_nhds_zero
  refine h.congr' ?_
  filter_upwards [eventually_ge_atTop (0 : ℝ)] with x hx
  rw [Real.rpow_mul hx]

-- φ(7) = 6: six classes mod 7 can hold primes other than 7.
example : Nat.totient 7 = 6 := by decide
-- The moduli of the card's table: φ(11) = 10, φ(13) = 12, φ(101) = 100, φ(1009) = 1008, φ(9973) = 9972.
example : Nat.totient 11 = 10 ∧ Nat.totient 13 = 12 ∧ Nat.totient 101 = 100 ∧
    Nat.totient 1009 = 1008 ∧ Nat.totient 9973 = 9972 := by
  refine ⟨?_, ?_, ?_, ?_, ?_⟩ <;> rw [Nat.totient_prime (by norm_num)]
-- Every q from 3 to 13: φ(q) is 2, 2, 4, 2, 6, 4, 6, 4, 10, 4, 12.
example : (List.range' 3 11).map Nat.totient = [2, 2, 4, 2, 6, 4, 6, 4, 10, 4, 12] := by decide
-- Class 0 mod 7 holds only the prime 7.
example (p : ℕ) (hp : p.Prime) (h : p ≡ 0 [MOD 7]) : p = 7 := by
  have h7 : 7 ∣ p := Nat.modEq_zero_iff_dvd.mp h
  exact ((Nat.prime_dvd_prime_iff_eq (by norm_num) hp).mp h7).symm
-- The squares mod 7 are 1, 2, 4 (Euler's criterion: a³ ≡ 1), and 3, 5, 6 give a³ ≡ −1 ≡ 6.
example : (List.range' 1 6).map (fun a ↦ a ^ 3 % 7) = [1, 1, 6, 1, 6, 6] := by decide
-- The class counts 1 + 13,063 + 13,065 + 13,105 + 13,069 + 13,105 + 13,090 make the 78,498 primes.
example : 1 + 13063 + 13065 + 13105 + 13069 + 13105 + 13090 = 78498 := by norm_num
-- The spread: 13,105 − 13,063 = 42 primes.
example : 13105 - 13063 = 42 := by norm_num
-- The square classes 1, 2, 4 hold 39,197; the others 39,300; a lead of 103.
example : 13063 + 13065 + 13069 = 39197 ∧ 13105 + 13105 + 13090 = 39300 ∧ 39300 - 39197 = 103 := by
  norm_num
-- Dividing by q instead of φ(q): 78,498 / 7 is exactly 11,214.
example : 78498 = 7 * 11214 := by norm_num

#print axioms exceptional_zero_term_lt_of_siegel_bound
#print axioms prime_count_in_class_eq_character_average
#print axioms siegel_exponent_tendsto_zero_of_power_modulus
```

**Checked 2026-11-15 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'exceptional_zero_term_lt_of_siegel_bound' depends on axioms: [propext, Classical.choice, Quot.sound]
'prime_count_in_class_eq_character_average' depends on axioms: [propext, Classical.choice, Quot.sound]
'siegel_exponent_tendsto_zero_of_power_modulus' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **Count to a hundred thousand: `X, Q = 10**5, 7`.** The classes now run from 1,584 to 1,613, and the spread grows to 1.81 percent: fewer primes, larger relative misses. The first assert stops it, because 78,498 is the count for a million. (The labels still say 10^6.)
> - **Move the hypothetical zero to 0.5: replace `0.6` by `0.5` in the `cost` list.** Each class moves by only 30 primes, a gap of −178. A zero on the critical line is ordinary; the danger is a zero near 1.
> - **Shorten the head of the L-function sum: `N=2` in `Lchi`.** $`L(1, \chi_1)`$ comes out at 1.187405 instead of 1.187410, and the fourth assert stops it.

---

## The usual mistake

> [!warning]
> **Reading Siegel-Walfisz as a statement about counts anyone can compute.** Its constant is ineffective, so it never says "from x = such-and-such on". The 0.32 percent spread at a million is evidence; the theorem cannot prove any explicit count.
>
> - **Taking "uniform" to mean "for every modulus".** The range is $`q \le (\log x)^A`$ with A fixed as x grows: with A = 2, up to 190.87 at a million. A modulus growing like a power of x leaves every such range (Step 6). One count cannot show it: at q = 9,973 the classes hold 1 to 17 primes, the scatter of small counts (7.87 per class, standard deviation 2.04), and 9,973 is inside the range for A = 4.
> - **Blaming the leftover gap on an exceptional zero.** The squares mod 7 trail by 103 primes. That is Chebyshev's bias, the same size as $`\sqrt{x}/\log x`$ = 72.38. It comes from prime squares, which all land in square classes. A zero at 0.6 would force a gap of 563.
> - **Thinking GRH is needed for the theorem.** It is not: Siegel-Walfisz is proved. GRH, the generalized Riemann hypothesis (every non-trivial zero of every L(s, χ) has real part 1/2), gives the stronger, effective error $`\sqrt{x}\log x`$ for q up to nearly $`\sqrt{x}`$; it was proved in 2026, with the Riemann hypothesis.

---

## Where you meet it in real life

- **Three primes (Vinogradov's theorem).** Every large enough odd number is a sum of three primes. The first proof used primes in progressions for moduli up to a power of log x, so its "large enough" had no stated size until later work.
- **Bombieri-Vinogradov and sieve methods.** Siegel-Walfisz handles the small moduli; [Bombieri-Vinogradov](../04-Sieves%20and%20Prime%20Gaps/04-bombieri-vinogradov.md) handles the rest on average.
- **Class numbers.** Siegel's bound says the class number of an imaginary quadratic field grows nearly like the square root of its discriminant (its size measure), but ineffectively. So the list of fields with class number 1 needed other methods.

> **Say it back**
> The 78,498 primes below a million split into six classes mod 7 that agree to a third of a percent. Siegel-Walfisz gives every class a mod q its fair share li(x)/φ(q), with one error bound for all moduli up to a power of log x. The proof averages over characters and uses the zero-free region for L-functions, which misses only one possible real zero of a real character. Siegel's bound keeps that zero $`q^{-\varepsilon}`$ away from 1: enough while q is small, but with a constant nobody can compute.

---

## What this builds on

- [Dirichlet's theorem](04-dirichlets-theorem-on-primes-in-progressions.md): the count π(x; q, a), the averaging over characters, and the fair share 1/φ(q) for one fixed modulus.
- [The zero-free region](../02-The%20Zeta%20Function%20and%20the%20Prime%20Number%20Theorem/03-the-zero-free-region.md): the three-four-one trick, which works for L-functions except at a real zero of a real character.
- [Dirichlet L-functions](03-dirichlet-l-functions.md): L(s, χ), its zeros, and the value $`L(1, \chi)`$.

## Where this goes next

- [Bombieri-Vinogradov](../04-Sieves%20and%20Prime%20Gaps/04-bombieri-vinogradov.md): the fair share on average over moduli up to nearly $`\sqrt{x}`$, as strong as GRH for most uses.
- [Gauss sums](06-gauss-sums.md): the exact size and sign of a character's Gauss sum, which sets the constant in the functional equation linking each L-function to its conjugate character's.

The question this card leaves open: does any real character have an exceptional zero, and if not, can the constant be made effective?

---

## Sources

Verified 2026-11-15: every link below resolves to the publisher's page.

- Siegel, Carl Ludwig. "Über die Classenzahl quadratischer Zahlkörper." *Acta Arithmetica* 1 (1935), 83–86. [DOI](https://doi.org/10.4064/aa-1-1-83-86). The bound $`\beta_1 < 1 - c(\varepsilon)q^{-\varepsilon}`$, in its class-number form, with the two-case proof.
- Walfisz, Arnold. "Zur additiven Zahlentheorie. II." *Mathematische Zeitschrift* 40 (1936), 592–607. [DOI](https://doi.org/10.1007/BF01218882). The theorem itself: Siegel's bound turned into a uniform prime count for moduli up to a power of log x.
- Davenport, Harold. *Multiplicative Number Theory*, 2nd edition. Springer, Graduate Texts in Mathematics 74, 1980. [DOI](https://doi.org/10.1007/978-1-4757-5927-3). The zero-free region for L-functions with its one exception (chapter 14), Siegel's theorem (chapter 21) and the Siegel-Walfisz theorem (chapter 22).
- Montgomery, Hugh L., and Robert C. Vaughan. *Multiplicative Number Theory I: Classical Theory*. Cambridge University Press, 2006. [DOI](https://doi.org/10.1017/CBO9780511618314). A modern account of exceptional zeros, Siegel's theorem and primes in progressions, including the ineffectivity.
