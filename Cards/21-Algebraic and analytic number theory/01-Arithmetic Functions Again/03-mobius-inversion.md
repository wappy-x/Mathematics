# The Mobius function: plus one, minus one or zero, and how it undoes a divisor sum

[Syllabus](../../../SYLLABUS.md) → [Algebraic and analytic number theory](../README.md) → [Arithmetic Functions Again](../README.md#s01) → The Mobius function

---

## General Overview

A dial has 60 marks, like the minutes on a clock. A pointer starts at mark 0 and jumps the same number of marks, k, on every tick. A jump of 7 visits all 60 marks before it comes home. A jump of 6 comes home after 10 ticks and never sees mark 1.

Hash tables meet the same question. A table with 60 slots that probes every k-th slot reaches every slot only for certain k. Of the 60 possible jumps, exactly 16 tour the whole dial. That count is Euler's totient: $`\varphi(60) = 16`$, the number of whole numbers from 1 to 60 that share no factor with 60 ([Euler's totient](../../02-Number%20theory/04-Powers%20on%20the%20Clock/03-eulers-totient.md)).

Now sort all 60 jumps by how many ticks they take to come home. The loop lengths are the divisors of 60. Exactly $`\varphi(d)`$ jumps have loop length d, so the totients of the divisors of 60 add up to 60. That is Gauss's identity, true for every n.

This card runs that identity backwards. It knows only that the totients over the divisors of n add to n, and from that alone it rebuilds $`\varphi(60)`$:

```math
60 - 30 - 20 - 12 + 10 + 6 + 4 - 2 = 16
```

The signs come from the **Möbius function** $`\mu`$. It gives each divisor a weight of +1, −1 or 0, read off its prime factors.

**Weight each divisor d of n by μ(d), which is +1 or −1 when d is a product of different primes (an even or odd number of them) and 0 when a prime repeats; then a divisor sum, weighted by these signs, gives back the function that was summed.**

**What kind of fact this is:** a theorem, proved on this card in Why it works, for every whole number. The code also checks it for every n up to 10,000; that check is evidence, and the proof is what covers all n.

### The picture: the 60 jumps, sorted by loop length

```
loop length  1 | #                   1
loop length  2 | #                   1
loop length  3 | ##                  2
loop length  4 | ##                  2
loop length  5 | ####                4
loop length  6 | ##                  2
loop length 10 | ####                4
loop length 12 | ####                4
loop length 15 | ########            8
loop length 20 | ########            8
loop length 30 | ########            8
loop length 60 | ################   16
```

Each # is one jump size. The bar at loop length d has $`\varphi(d)`$ marks, and the twelve bars hold all 60 jumps.

---

## The formula

Notation first, in words. The bar in $`d \mid n`$ reads "d divides n". A **squarefree** number is one that no prime divides twice: 30 is squarefree, and 60 is not, since 2 × 2 divides 60. The Möbius function is

```math
\mu(n)=\begin{cases}1 & n = 1\\(-1)^r & n \text{ is } r \text{ different primes multiplied}\\0 & \text{a prime squared divides } n\end{cases}
```

So μ is 0 off the squarefree numbers. The inversion formula is a pair of statements, each true exactly when the other is:

```math
g(n)=\sum_{d\mid n} f(d)\ \text{ for every } n \quad\Longleftrightarrow\quad f(n)=\sum_{d\mid n}\mu(d)\,g\!\left(\frac{n}{d}\right)\ \text{ for every } n
```

**Read it aloud:** if g adds up f over the divisors of each number, then f comes back from g by adding g at n over d, weighted by the Möbius sign of d, over the same divisors.

For the totient, f is $`\varphi`$ and g is "n itself". Gauss's identity and its inversion read

```math
\sum_{d\mid n}\varphi(d)=n\quad\Longrightarrow\quad\varphi(n)=\sum_{d\mid n}\mu(d)\,\frac{n}{d}=n\prod_{p\mid n}\left(1-\frac{1}{p}\right)
```

**Read it aloud:** the totients of the divisors add to n, so the totient is n over d with Möbius signs, which is also n times one bracket, one minus one over p, for each different prime p dividing n.

Two more forms follow from the same proof. One swaps sums for products. The other works for sums over all n up to a bound x instead of over divisors:

```math
g(n)=\prod_{d\mid n} f(d)\iff f(n)=\prod_{d\mid n} g\!\left(\frac{n}{d}\right)^{\mu(d)},\qquad G(x)=\sum_{n\le x}F\!\left(\frac{x}{n}\right)\iff F(x)=\sum_{n\le x}\mu(n)\,G\!\left(\frac{x}{n}\right)
```

**Read it aloud:** a product over divisors is undone by raising to the Möbius signs; a sum of F at x over n, for every n up to x, is undone by weighting G at x over n with the sign of n.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $`n`$, $`d`$, $`e`$, $`m`$, $`a`$, $`b`$ | whole numbers; $`d`$ and $`e`$ run over divisors of $`n`$; $`a/b`$ is a fraction in Step 5 | n = 60; d = 1, 2, 3, …, 60 | more divisors, longer sums |
| $`p`$ | a prime dividing $`n`$ | 2, 3, 5 | one more bracket $`1 - 1/p`$ |
| $`k`$, $`t`$, $`j`$, $`c`$ | a jump size; a count of ticks; $`k = (n/d)\,j`$; a greatest common divisor, such as $`c = \gcd(k, n)`$ | jump 6: t = 10 ticks home, j = 1, c = 6 | — |
| $`f`$, $`g`$ | arithmetic functions: one number for each whole number | f is φ, g(n) = n | — |
| $`\mu(d)`$ | the Möbius sign of $`d`$ | μ(6) = 1, μ(30) = −1, μ(4) = 0 | a repeated prime makes it 0 |
| $`\varphi(n)`$ | Euler's totient: the count from 1 to n sharing no factor with n | φ(60) = 16 | more primes in n, smaller share |
| $`\mathbf 1`$, $`\varepsilon`$, $`\mathrm{id}`$ | value 1 everywhere; 1 at n = 1 and 0 after; $`\mathrm{id}(n) = n`$ | $`\mathbf 1 * \varphi = \mathrm{id}`$ | — |
| $`a * b`$ | Dirichlet convolution: the sum of $`a(d)\,b(n/d)`$ over $`d \mid n`$ | $`\varphi = \mu * \mathrm{id}`$ | — |
| $`x`$ | a bound, any real number at least 1 | 60, 1,000, 10,000 | more terms in the sum |
| $`F`$, $`G`$, $`\lfloor y \rfloor`$ | functions of a bound; $`\lfloor y \rfloor`$ is y rounded down | $`G(x) = \lfloor x\rfloor(\lfloor x\rfloor+1)/2`$ | — |
| $`T(x)`$ | the running total of φ(1) to φ(x) | T(60) = 1,102 | grows like $`3x^2/\pi^2`$ |
| $`r(n)`$ | p if n is one of p, p², p³, … for a prime p, else 1 (so r(1) = 1) | r(8) = 2, r(12) = 1 | — |

### When it holds

- **Every divisor, from 1 to n itself.** The sum runs over the whole divisor list. Leave out d = 1 and the 60 sum is −44, not 16.
- **Zero on repeated primes.** Signs that count a repeated prime, giving 4 = 2 × 2 the sign +1, turn the 60 sum into 24, not 16.
- **Nothing about f, for the sum form.** Inversion is finite arithmetic on divisors, so it holds for any f at all, with any values. The product form needs every value nonzero, since it divides.
- **Coprime parts, for splitting the totient.** The product formula comes from φ being multiplicative: φ(ab) = φ(a)φ(b) when a and b share no prime. For 360 and 2002, which share a 2, the product is 69,120, not φ(720720) = 138,240: the trap [Multiplicative functions](02-multiplicative-functions-and-dirichlet-convolution.md) warns of.

---

## Why it works

### Step 0: the signs cancel over every divisor list except the list of 1

The idea that makes inversion possible is one fact about μ: its values over the divisors of n add to 1 when n = 1 and to 0 for every larger n. Over the divisors of 60 the signs are 1, −1, −1, 0, −1, 1, 1, 0, 1, 0, −1, 0, which add to 0.

[Dirichlet series](../../07-Complex%20analysis/09-Special%20Functions%20and%20the%20Zeta%20Function/06-dirichlet-series-and-mobius-inversion.md) proves this, $`\mu * \mathbf 1 = \varepsilon`$, and proves inversion in general, once by dividing by the zeta function and once by grouping convolutions. Step 2 re-proves inversion from convolution in two lines; the rest of the card is spent on the totient, the product form and the running-total form.

The proof of $`\mu * \mathbf 1 = \varepsilon`$ in a sentence: the squarefree divisors of n come in pairs, with and without the smallest prime of n, and each pair has opposite signs.

### Step 1: Gauss's identity, by sorting the jumps

On a dial of n marks, a jump of k comes home after $`n / \gcd(k, n)`$ ticks. A jump has loop length d exactly when $`k = (n/d)\,j`$ with j between 1 and d and j sharing no factor with d. There are $`\varphi(d)`$ such j, so φ(d) jumps have loop length d.

Every jump from 1 to n has exactly one loop length, and each loop length divides n. Counting the n jumps by loop length gives $`\sum_{d \mid n} \varphi(d) = n`$.

<details>
<summary>Detailed proof: the jumps with loop length d number exactly φ(d)</summary>

Write $`c = \gcd(k, n)`$. After t ticks the pointer is at $`tk`$ wrapped at n. It is home when n divides $`tk`$, which happens exactly when $`n/c`$ divides $`t\,(k/c)`$. Since $`n/c`$ and $`k/c`$ share no factor, this means $`n/c`$ divides t. So the first return is at $`t = n/c`$.

Loop length d therefore means $`\gcd(k, n) = n/d`$. Write $`k = (n/d)\,j`$. Then $`\gcd(k, n) = (n/d)\gcd(j, d)`$, which equals $`n/d`$ exactly when $`\gcd(j, d) = 1`$. As k runs from 1 to n, j runs from 1 to d, and the coprime j number $`\varphi(d)`$.

</details>

On the 60 dial the sorted counts are 1, 1, 2, 2, 4, 2, 4, 4, 8, 8, 8, 16, matching φ of the divisors, total 60. The code finds them by stepping the pointer, with no gcd in sight. [Multiplicative functions](02-multiplicative-functions-and-dirichlet-convolution.md) proves the same identity one prime power at a time; its folded second proof sorts 1 to n by their gcd with n, which is this dial sorting in other words.

### Step 2: inversion, from convolution

In the language of [Multiplicative functions](02-multiplicative-functions-and-dirichlet-convolution.md), "g adds up f over divisors" is $`g = \mathbf 1 * f`$. Convolution is associative ([Dirichlet series](../../07-Complex%20analysis/09-Special%20Functions%20and%20the%20Zeta%20Function/06-dirichlet-series-and-mobius-inversion.md) proves it: both groupings add over the same triples of divisors), so

```math
\mu * g=\mu * (\mathbf 1 * f)=(\mu * \mathbf 1) * f=\varepsilon * f=f
```

The last step holds because ε is 1 only at 1, so $`\varepsilon * f`$ picks out f(n). The other direction is the same line with μ and $`\mathbf 1`$ swapped: if $`f = \mu * g`$, then $`\mathbf 1 * f = g`$.

<details>
<summary>Detailed proof: inversion by swapping two finite sums</summary>

Put the divisor sum for g inside the Möbius sum:

$`\displaystyle \sum_{d\mid n}\mu(d)\,g\!\left(\frac{n}{d}\right)=\sum_{d\mid n}\mu(d)\sum_{e\mid n/d}f(e)=\sum_{e\mid n}f(e)\sum_{d\mid n/e}\mu(d)`$

The pairs (d, e) in both double sums are the same: d and e with d × e dividing n. By Step 0 the inner sum on the right is 1 when $`n/e = 1`$ and 0 otherwise. Only the term e = n survives, leaving f(n).

</details>

### Step 3: the totient, three ways

Apply Step 2 with f = φ and g = id. Gauss's identity says $`\mathbf 1 * \varphi = \mathrm{id}`$, so $`\varphi = \mu * \mathrm{id}`$:

```math
\varphi(n)=\sum_{d\mid n}\mu(d)\,\frac{n}{d}
```

Only squarefree d count. Each one is a choice of some of the different primes of n, with sign −1 for each prime chosen. Expanding the product of brackets $`(1 - 1/p)`$ makes the same choices, one term per choice. So the sum equals $`n \prod_{p \mid n} (1 - 1/p)`$.

For 60 the brackets are 1/2, 2/3 and 4/5, and 60 × 1/2 × 2/3 × 4/5 = 16. The direct gcd count of numbers up to 60 also gives 16. [Euler's totient](../../02-Number%20theory/04-Powers%20on%20the%20Clock/03-eulers-totient.md) reaches the same product by counting; here it falls out of a divisor sum.

### Step 4: the product form

If every value is positive, take logs. A product over divisors becomes a sum over divisors, Step 2 inverts it, and undoing the log gives $`f(n)=\prod_{d \mid n} g(n/d)^{\mu(d)}`$. With nonzero values of any sign, the same swap of products works with no logs.

An example comes straight from [Prime factorisation](../../02-Number%20theory/01-Divisibility%20and%20Primes/07-prime-factorisation.md). Let r(d) be p when d is one of p, p², p³, … for a prime p, and 1 otherwise, so r(1) = 1. For each prime power $`p^k`$ that divides n exactly (written $`p^k \parallel n`$), the divisors p, p², …, $`p^k`$ each contribute one p. So the product of r(d) over the divisors of n is n itself.

Inverting gives $`r(n) = \prod_{d \mid n} (n/d)^{\mu(d)}`$. At n = 8 that is 8 ÷ 4 = 2. At n = 12 it is 12 × 2 ÷ (6 × 4) = 1. The log of r is the weight [The von Mangoldt function](04-von-mangoldt-and-the-logarithmic-derivative.md) puts on prime powers.

### Step 5: the running-total form

Here sums run over all n up to a bound x, not over divisors. If $`G(x) = \sum_{n \le x} F(x/n)`$ for every x at least 1, then

```math
\sum_{n\le x}\mu(n)\,G\!\left(\frac{x}{n}\right)=\sum_{n\le x}\mu(n)\sum_{m\le x/n}F\!\left(\frac{x}{nm}\right)=\sum_{k\le x}F\!\left(\frac{x}{k}\right)\sum_{n\mid k}\mu(n)=F(x)
```

The middle step collects the pairs (n, m) by their product k = nm. Step 0 then kills every k except k = 1.

The totient gives a real use. Let T(x) be the running total φ(1) + φ(2) + … up to x. It counts the fractions a/b in lowest terms with $`1 \le a \le b \le x`$. Group all pairs $`1 \le a \le b \le \lfloor x \rfloor`$ by their gcd c. Dividing out c leaves a pair in lowest terms with $`b \le x/c`$. So

```math
\sum_{n\le x}T\!\left(\frac{x}{n}\right)=\frac{\lfloor x\rfloor(\lfloor x\rfloor+1)}{2},\qquad T(x)=\sum_{n\le x}\mu(n)\,\frac{\lfloor x/n\rfloor(\lfloor x/n\rfloor+1)}{2}
```

The right-hand formula computes T(x) with no totient at all. At x = 60 both roads give 1,102. A theorem proved by Mertens in 1874 (Apostol, Chapter 3, gives it with its error term) says T(x) grows like $`3x^2/\pi^2`$: the ratio is 1.007065 at 60, 1.000752 at 1,000 and 1.000037 at 10,000. The difference $`T(x) - 3x^2/\pi^2`$ is 7.73, 228.45 and 1,130.91 at the same sizes: it grows, staying within a fixed multiple of x log x as the theorem's error term promises, while the ratio closes on 1. The [Big O and twiddle](01-asymptotic-notation-and-error-terms.md) card gives the language for such claims.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| divisors of 60 | 60 = 2 × 2 × 3 × 5 | 1, 2, 3, 4, 5, 6, 10, 12, 15, 20, 30, 60 |
| drop the non-squarefree | 4, 12, 20, 60 each hold 2 × 2 | 1, 2, 3, 5, 6, 10, 15, 30 |
| their signs | −1 per prime | +1, −1, −1, −1, +1, +1, +1, −1 |
| terms μ(d) × 60/d | 60/1, 60/2, … with signs | 60, −30, −20, −12, 10, 6, 4, −2 |
| add them | inversion | **16** |
| product form | 60 × 1/2 × 2/3 × 4/5 | **16** |
| count directly | k from 1 to 60 with gcd(k, 60) = 1 | 16 |
| the house number | 720720 = 2⁴ × 3² × 5 × 7 × 11 × 13: 240 divisors, 64 squarefree | **138,240** |

So 16 of the 60 jumps tour the dial: 1, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 49, 53, 59. For the house number, inversion, the product and a gcd count of all 720,720 numbers agree on 138,240, and the totients over its 240 divisors add back to 720,720.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Signs that count repeated primes (+1 on 4, −1 on 12) | 24, not 16 | The divisors with a squared prime no longer cancel |
| Signs dropped: every squarefree divisor counted +1 | 144, not 16 | Nothing cancels; that sum overcounts |
| The term d = 1 left out | −44, not 16 | The divisor list must be whole |
| φ(360) × φ(2002) taken for φ(720720) | 96 × 720 = 69,120, not 138,240 | 360 and 2002 share the prime 2, so φ does not split |

The code prints all four.

---

## Code, from first principles, and it actually runs

Only `math` is imported, for π as an outside value and for the integer square root. The totient is reached four independent ways: the gcd count straight from its definition, peeling with Gauss's identity, Möbius inversion, and the product of brackets. They agree for every n up to 10,000 (the gcd count to 1,000). Gauss's identity is checked a fifth way, by stepping a pointer round the 60 dial. The running-total form is checked against a direct sum, the product form against factorisation, and the string count against brute force.

### Python

```python
# The Mobius function and inversion -- the check behind the card.  Only math
# is imported, for pi as an outside value and for isqrt.  The examples are a
# dial of 60 marks and the house number 720720 = 2^4 x 3^2 x 5 x 7 x 11 x 13.
import math

N = 10_000                                       # every claim is also checked for n up to N

def gcd(a, b):                                   # Euclid, written out here
    while b:
        a, b = b, a % b
    return a

def primes_of(n):                                # trial division: {prime: exponent}
    out, p = {}, 2
    while p * p <= n:
        while n % p == 0:
            out[p], n = out.get(p, 0) + 1, n // p
        p += 1
    if n > 1:
        out[n] = out.get(n, 0) + 1
    return out

def mu(n):                                       # 0 on a repeated prime, else (-1)^(prime count)
    e = list(primes_of(n).values())
    return 0 if any(k > 1 for k in e) else (-1) ** len(e)

def divisors(n):                                 # pairs d and n/d, with d up to the square root
    small = [d for d in range(1, math.isqrt(n) + 1) if n % d == 0]
    return sorted(set(small + [n // d for d in small]))

def phi_count(n):                                # road 1, the definition: count k <= n with gcd 1
    return sum(1 for k in range(1, n + 1) if gcd(k, n) == 1)

def phi_mobius(n):                               # road 2, Mobius inversion of n = sum of phi(d)
    return sum(mu(d) * (n // d) for d in divisors(n))

def phi_product(n):                              # road 3, n times (1 - 1/p) for each prime p
    v = n
    for p in primes_of(n):
        v = v // p * (p - 1)
    return v

def loop_length(k, n):                           # step a pointer k marks at a time; count ticks home
    pos, t = k % n, 1
    while pos != 0:
        pos, t = (pos + k) % n, t + 1
    return t

divs = [[] for _ in range(N + 1)]                # divisor lists up to N, by a sieve
for d in range(1, N + 1):
    for m in range(d, N + 1, d):
        divs[m].append(d)
MU = [0] + [mu(n) for n in range(1, N + 1)]
peel = [0] * (N + 1)                             # road 4: phi(n) = n minus phi of smaller divisors
for n in range(1, N + 1):
    peel[n] = n - sum(peel[d] for d in divs[n][:-1])
via_mu = [0] + [sum(MU[d] * (n // d) for d in divs[n]) for n in range(1, N + 1)]
assert all(sum(MU[d] for d in divs[n]) == (n == 1) for n in range(1, N + 1))     # mu * 1 = epsilon
assert all(peel[n] == via_mu[n] == phi_product(n) for n in range(1, N + 1))     # inversion, n <= N
assert all(phi_count(n) == peel[n] for n in range(1, 1001))                     # Gauss, n <= 1000
print(f"checked n = 1..{N}: mu sums to 1 at n = 1 and 0 after; peeling = inversion = product")
print(f"checked n = 1..1000: the gcd count equals all three")

D = divisors(60)
tally = {}
for k in range(1, 61):
    tally[loop_length(k, 60)] = tally.get(loop_length(k, 60), 0) + 1
tours = [k for k in range(1, 61) if loop_length(k, 60) == 60]
print(f"divisors of 60: {D}")
print(f"jumps 1..60 sorted by loop length d: {[tally[d] for d in D]}")
print(f"phi(d) for the same d, by gcd count: {[phi_count(d) for d in D]}; total {sum(phi_count(d) for d in D)}")
print(f"jumps that visit all 60 marks: {tours}")
print(f"jump 7 comes home after {loop_length(7, 60)} ticks; jump 6 after {loop_length(6, 60)}")
print(f"mu(d) on the divisors of 60: {[mu(d) for d in D]}")
terms = [mu(d) * (60 // d) for d in D if mu(d) != 0]
print(f"inversion terms mu(d) x 60/d: {terms}; sum {sum(terms)}")
print(f"product form: 60 x 1/2 x 2/3 x 4/5 = {phi_product(60)}; gcd count {phi_count(60)}")
assert [tally[d] for d in D] == [phi_count(d) for d in D] and len(tours) == phi_mobius(60) == 16

H = 720720
DH = divisors(H)
sq = [d for d in DH if mu(d) != 0]
print(f"720720 = {primes_of(H)}: {len(DH)} divisors, {len(sq)} squarefree")
print(f"sum of phi(d) over its divisors: {sum(phi_product(d) for d in DH)}")
print(f"phi(720720): inversion {phi_mobius(H)}, product {phi_product(H)}, gcd count {phi_count(H)}")
assert sum(phi_product(d) for d in DH) == H and phi_mobius(H) == phi_count(H) == 138240

T = [0] * (N + 1)                                # T(x): the running total of phi up to x
for n in range(1, N + 1):
    T[n] = T[n - 1] + peel[n]
for x in (60, 1000, N):
    gauss = sum(T[x // n] for n in range(1, x + 1))
    inv = sum(MU[n] * (x // n) * (x // n + 1) // 2 for n in range(1, x + 1))
    main_term = 3 * x * x / math.pi ** 2
    print(f"x = {x}: T(x) = {T[x]}; inverted {inv}; sum of T(x/n) = {gauss} = x(x+1)/2; "
          f"T(x)/(3x^2/pi^2) = {T[x] / main_term:.6f}; T(x) - 3x^2/pi^2 = {T[x] - main_term:.2f}")
    assert inv == T[x] and gauss == x * (x + 1) // 2

def prime_behind(n):                             # product form: n = product of r(d) over d | n
    num = den = 1
    for d in divisors(n):
        if mu(d) == 1:
            num *= n // d
        elif mu(d) == -1:
            den *= n // d
    assert num % den == 0
    return num // den
print(f"r(n) for n = 1..12 from the product form: {[prime_behind(n) for n in range(1, 13)]}")
assert all(prime_behind(n) == (list(primes_of(n))[0] if len(primes_of(n)) == 1 else 1)
           for n in range(1, 2001))

def is_primitive(s, n):                          # an n-bit string that is no shorter block repeated
    return all(s != int(format(s, f"0{n}b")[:d] * (n // d), 2) for d in divisors(n)[:-1])

def has_factor(f):                               # a degree-8 polynomial over GF(2), as bits
    for g in range(2, 32):                       # every polynomial of degree 1 to 4
        a = f
        while a.bit_length() >= g.bit_length():
            a ^= g << (a.bit_length() - g.bit_length())
        if a == 0:
            return True
    return False
prim = sum(1 for s in range(256) if is_primitive(s, 8))
irred = sum(1 for f in range(256, 512) if not has_factor(f))
formula = sum(mu(d) * 2 ** (8 // d) for d in divisors(8))
print(f"8-bit strings with no shorter repeat: brute force {prim}, inversion {formula}; "
      f"/8 = {formula // 8}; irreducible degree-8 over GF(2), brute force {irred}")
assert prim == formula == 240 and irred == formula // 8

omega = lambda n: sum(primes_of(n).values())
print(f"mistake 1, signs counting repeated primes: {sum((-1) ** omega(d) * (60 // d) for d in D)}, not 16")
print(f"mistake 2, signs dropped: {sum(60 // d for d in D if mu(d) != 0)}, not 16")
print(f"mistake 3, the term d = 1 left out: {sum(terms[1:])}, not 16")
print(f"mistake 4, phi(360) x phi(2002) = {phi_product(360)} x {phi_product(2002)} = "
      f"{phi_product(360) * phi_product(2002)}, not {phi_product(H)}")
print("ALL CHECKS PASS")
```

**Ran 2026-11-15 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
checked n = 1..10000: mu sums to 1 at n = 1 and 0 after; peeling = inversion = product
checked n = 1..1000: the gcd count equals all three
divisors of 60: [1, 2, 3, 4, 5, 6, 10, 12, 15, 20, 30, 60]
jumps 1..60 sorted by loop length d: [1, 1, 2, 2, 4, 2, 4, 4, 8, 8, 8, 16]
phi(d) for the same d, by gcd count: [1, 1, 2, 2, 4, 2, 4, 4, 8, 8, 8, 16]; total 60
jumps that visit all 60 marks: [1, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 49, 53, 59]
jump 7 comes home after 60 ticks; jump 6 after 10
mu(d) on the divisors of 60: [1, -1, -1, 0, -1, 1, 1, 0, 1, 0, -1, 0]
inversion terms mu(d) x 60/d: [60, -30, -20, -12, 10, 6, 4, -2]; sum 16
product form: 60 x 1/2 x 2/3 x 4/5 = 16; gcd count 16
720720 = {2: 4, 3: 2, 5: 1, 7: 1, 11: 1, 13: 1}: 240 divisors, 64 squarefree
sum of phi(d) over its divisors: 720720
phi(720720): inversion 138240, product 138240, gcd count 138240
x = 60: T(x) = 1102; inverted 1102; sum of T(x/n) = 1830 = x(x+1)/2; T(x)/(3x^2/pi^2) = 1.007065; T(x) - 3x^2/pi^2 = 7.73
x = 1000: T(x) = 304192; inverted 304192; sum of T(x/n) = 500500 = x(x+1)/2; T(x)/(3x^2/pi^2) = 1.000752; T(x) - 3x^2/pi^2 = 228.45
x = 10000: T(x) = 30397486; inverted 30397486; sum of T(x/n) = 50005000 = x(x+1)/2; T(x)/(3x^2/pi^2) = 1.000037; T(x) - 3x^2/pi^2 = 1130.91
r(n) for n = 1..12 from the product form: [1, 2, 3, 2, 5, 1, 7, 2, 3, 1, 11, 1]
8-bit strings with no shorter repeat: brute force 240, inversion 240; /8 = 30; irreducible degree-8 over GF(2), brute force 30
mistake 1, signs counting repeated primes: 24, not 16
mistake 2, signs dropped: 144, not 16
mistake 3, the term d = 1 left out: -44, not 16
mistake 4, phi(360) x phi(2002) = 96 x 720 = 69120, not 138240
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// The Mobius function and inversion -- the same check as the Python, in Rust.
// No crates.  The examples are a dial of 60 marks and the house number
// 720720 = 2^4 x 3^2 x 5 x 7 x 11 x 13.  Whole numbers are i128.
type Z = i128;
const N: usize = 10_000;                         // every claim is also checked for n up to N

fn gcd(mut a: Z, mut b: Z) -> Z {                // Euclid, written out here
    while b != 0 { (a, b) = (b, a % b) }
    a
}

fn primes_of(mut n: Z) -> Vec<(Z, u32)> {        // trial division: (prime, exponent)
    let (mut out, mut p) = (Vec::new(), 2);
    while p * p <= n {
        let mut e = 0;
        while n % p == 0 { n /= p; e += 1 }
        if e > 0 { out.push((p, e)) }
        p += 1;
    }
    if n > 1 { out.push((n, 1)) }
    out
}

fn mu(n: Z) -> Z {                               // 0 on a repeated prime, else (-1)^(prime count)
    let f = primes_of(n);
    if f.iter().any(|&(_, e)| e > 1) { 0 } else if f.len() % 2 == 0 { 1 } else { -1 }
}

fn divisors(n: Z) -> Vec<Z> {                    // pairs d and n/d, with d up to the square root
    let mut out = Vec::new();
    let mut d = 1;
    while d * d <= n {
        if n % d == 0 { out.push(d); if d * d != n { out.push(n / d) } }
        d += 1;
    }
    out.sort();
    out
}

fn phi_count(n: Z) -> Z { (1..=n).filter(|&k| gcd(k, n) == 1).count() as Z }      // road 1
fn phi_mobius(n: Z) -> Z { divisors(n).iter().map(|&d| mu(d) * (n / d)).sum() }  // road 2
fn phi_product(n: Z) -> Z {                                                       // road 3
    primes_of(n).iter().fold(n, |v, &(p, _)| v / p * (p - 1))
}

fn loop_length(k: Z, n: Z) -> Z {                // step a pointer k marks at a time; count ticks home
    let (mut pos, mut t) = (k % n, 1);
    while pos != 0 { pos = (pos + k) % n; t += 1 }
    t
}

fn prime_behind(n: Z) -> Z {                     // product form: n = product of r(d) over d | n
    let (mut num, mut den): (Z, Z) = (1, 1);
    for d in divisors(n) {
        if mu(d) == 1 { num = num.checked_mul(n / d).unwrap() }
        if mu(d) == -1 { den = den.checked_mul(n / d).unwrap() }
    }
    assert!(num % den == 0);
    num / den
}

fn is_primitive(s: u32, n: u32) -> bool {        // an n-bit string that is no shorter block repeated
    divisors(n as Z).iter().filter(|&&d| d < n as Z).all(|&d| {
        let block = s >> (n - d as u32);
        let rep = (0..n / d as u32).fold(0u32, |acc, _| (acc << d) | block);
        rep != s
    })
}

fn bits(x: u32) -> u32 { 32 - x.leading_zeros() }
fn has_factor(f: u32) -> bool {                  // a degree-8 polynomial over GF(2), as bits
    (2u32..32).any(|g| {                         // every polynomial of degree 1 to 4
        let mut a = f;
        while bits(a) >= bits(g) { a ^= g << (bits(a) - bits(g)) }
        a == 0
    })
}

fn main() {
    let mut divs: Vec<Vec<usize>> = vec![Vec::new(); N + 1];      // divisor lists up to N, by a sieve
    for d in 1..=N { for m in (d..=N).step_by(d) { divs[m].push(d) } }
    let mut mus: Vec<Z> = vec![0; N + 1];
    for n in 1..=N { mus[n] = mu(n as Z) }
    let mut peel: Vec<Z> = vec![0; N + 1];      // road 4: phi(n) = n minus phi of smaller divisors
    for n in 1..=N {
        let below: Z = divs[n][..divs[n].len() - 1].iter().map(|&d| peel[d]).sum();
        peel[n] = n as Z - below;
    }
    for n in 1..=N {
        let s: Z = divs[n].iter().map(|&d| mus[d]).sum();
        assert!(s == if n == 1 { 1 } else { 0 });                   // mu * 1 = epsilon
        let via: Z = divs[n].iter().map(|&d| mus[d] * (n / d) as Z).sum();
        assert!(peel[n] == via && via == phi_product(n as Z));      // inversion, n <= N
        if n <= 1000 { assert!(phi_count(n as Z) == peel[n]) }      // Gauss, n <= 1000
    }
    println!("checked n = 1..{}: mu sums to 1 at n = 1 and 0 after; peeling = inversion = product", N);
    println!("checked n = 1..1000: the gcd count equals all three");

    let dd = divisors(60);
    let tally: Vec<Z> = dd.iter().map(|&d| (1..=60).filter(|&k| loop_length(k, 60) == d).count() as Z).collect();
    let tours: Vec<Z> = (1..=60).filter(|&k| loop_length(k, 60) == 60).collect();
    let phis: Vec<Z> = dd.iter().map(|&d| phi_count(d)).collect();
    println!("divisors of 60: {:?}", dd);
    println!("jumps 1..60 sorted by loop length d: {:?}", tally);
    println!("phi(d) for the same d, by gcd count: {:?}; total {}", phis, phis.iter().sum::<Z>());
    println!("jumps that visit all 60 marks: {:?}", tours);
    println!("jump 7 comes home after {} ticks; jump 6 after {}", loop_length(7, 60), loop_length(6, 60));
    println!("mu(d) on the divisors of 60: {:?}", dd.iter().map(|&d| mu(d)).collect::<Vec<Z>>());
    let terms: Vec<Z> = dd.iter().filter(|&&d| mu(d) != 0).map(|&d| mu(d) * (60 / d)).collect();
    println!("inversion terms mu(d) x 60/d: {:?}; sum {}", terms, terms.iter().sum::<Z>());
    println!("product form: 60 x 1/2 x 2/3 x 4/5 = {}; gcd count {}", phi_product(60), phi_count(60));
    assert!(tally == phis && tours.len() as Z == phi_mobius(60) && phi_mobius(60) == 16);

    let h: Z = 720720;
    let dh = divisors(h);
    let sq = dh.iter().filter(|&&d| mu(d) != 0).count();
    let fac: Vec<String> = primes_of(h).iter().map(|(p, e)| format!("{}: {}", p, e)).collect();
    println!("720720 = {{{}}}: {} divisors, {} squarefree", fac.join(", "), dh.len(), sq);
    let total: Z = dh.iter().map(|&d| phi_product(d)).sum();
    println!("sum of phi(d) over its divisors: {}", total);
    println!("phi(720720): inversion {}, product {}, gcd count {}", phi_mobius(h), phi_product(h), phi_count(h));
    assert!(total == h && phi_mobius(h) == phi_count(h) && phi_count(h) == 138240);

    let mut t: Vec<Z> = vec![0; N + 1];          // T(x): the running total of phi up to x
    for n in 1..=N { t[n] = t[n - 1] + peel[n] }
    for &x in &[60usize, 1000, N] {
        let gauss: Z = (1..=x).map(|n| t[x / n]).sum();
        let inv: Z = (1..=x).map(|n| { let m = (x / n) as Z; mus[n] * m * (m + 1) / 2 }).sum();
        let main_term = 3.0 * (x * x) as f64 / (std::f64::consts::PI * std::f64::consts::PI);
        println!("x = {}: T(x) = {}; inverted {}; sum of T(x/n) = {} = x(x+1)/2; T(x)/(3x^2/pi^2) = {:.6}; T(x) - 3x^2/pi^2 = {:.2}",
                 x, t[x], inv, gauss, t[x] as f64 / main_term, t[x] as f64 - main_term);
        assert!(inv == t[x] && gauss == (x * (x + 1) / 2) as Z);
    }

    println!("r(n) for n = 1..12 from the product form: {:?}", (1..=12).map(prime_behind).collect::<Vec<Z>>());
    for n in 1..=2000 {
        let f = primes_of(n);
        assert!(prime_behind(n) == if f.len() == 1 { f[0].0 } else { 1 });
    }

    let prim = (0u32..256).filter(|&s| is_primitive(s, 8)).count() as Z;
    let irred = (256u32..512).filter(|&f| !has_factor(f)).count() as Z;
    let formula: Z = divisors(8).iter().map(|&d| mu(d) * (1 << (8 / d))).sum();
    println!("8-bit strings with no shorter repeat: brute force {}, inversion {}; /8 = {}; irreducible degree-8 over GF(2), brute force {}",
             prim, formula, formula / 8, irred);
    assert!(prim == formula && formula == 240 && irred == formula / 8);

    let omega = |n: Z| primes_of(n).iter().map(|&(_, e)| e).sum::<u32>();
    let m1: Z = dd.iter().map(|&d| (if omega(d) % 2 == 0 { 1 } else { -1 }) * (60 / d)).sum();
    let m2: Z = dd.iter().filter(|&&d| mu(d) != 0).map(|&d| 60 / d).sum();
    println!("mistake 1, signs counting repeated primes: {}, not 16", m1);
    println!("mistake 2, signs dropped: {}, not 16", m2);
    println!("mistake 3, the term d = 1 left out: {}, not 16", terms[1..].iter().sum::<Z>());
    println!("mistake 4, phi(360) x phi(2002) = {} x {} = {}, not {}",
             phi_product(360), phi_product(2002), phi_product(360) * phi_product(2002), phi_product(h));
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-15 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
checked n = 1..10000: mu sums to 1 at n = 1 and 0 after; peeling = inversion = product
checked n = 1..1000: the gcd count equals all three
divisors of 60: [1, 2, 3, 4, 5, 6, 10, 12, 15, 20, 30, 60]
jumps 1..60 sorted by loop length d: [1, 1, 2, 2, 4, 2, 4, 4, 8, 8, 8, 16]
phi(d) for the same d, by gcd count: [1, 1, 2, 2, 4, 2, 4, 4, 8, 8, 8, 16]; total 60
jumps that visit all 60 marks: [1, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 49, 53, 59]
jump 7 comes home after 60 ticks; jump 6 after 10
mu(d) on the divisors of 60: [1, -1, -1, 0, -1, 1, 1, 0, 1, 0, -1, 0]
inversion terms mu(d) x 60/d: [60, -30, -20, -12, 10, 6, 4, -2]; sum 16
product form: 60 x 1/2 x 2/3 x 4/5 = 16; gcd count 16
720720 = {2: 4, 3: 2, 5: 1, 7: 1, 11: 1, 13: 1}: 240 divisors, 64 squarefree
sum of phi(d) over its divisors: 720720
phi(720720): inversion 138240, product 138240, gcd count 138240
x = 60: T(x) = 1102; inverted 1102; sum of T(x/n) = 1830 = x(x+1)/2; T(x)/(3x^2/pi^2) = 1.007065; T(x) - 3x^2/pi^2 = 7.73
x = 1000: T(x) = 304192; inverted 304192; sum of T(x/n) = 500500 = x(x+1)/2; T(x)/(3x^2/pi^2) = 1.000752; T(x) - 3x^2/pi^2 = 228.45
x = 10000: T(x) = 30397486; inverted 30397486; sum of T(x/n) = 50005000 = x(x+1)/2; T(x)/(3x^2/pi^2) = 1.000037; T(x) - 3x^2/pi^2 = 1130.91
r(n) for n = 1..12 from the product form: [1, 2, 3, 2, 5, 1, 7, 2, 3, 1, 11, 1]
8-bit strings with no shorter repeat: brute force 240, inversion 240; /8 = 30; irreducible degree-8 over GF(2), brute force 30
mistake 1, signs counting repeated primes: 24, not 16
mistake 2, signs dropped: 144, not 16
mistake 3, the term d = 1 left out: -44, not 16
mistake 4, phi(360) x phi(2002) = 96 x 720 = 69120, not 138240
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves inversion, the three totient formulas, and the product and running-total forms, for every whole number and every bound.

- Step 0 holds: the signs over the divisors of n add to 1 at n = 1, and to 0 after.
- Take any f and g whose values can be added and subtracted. Then g adds up f over divisors exactly when f comes back by inversion.
- The totients of the divisors of n add up to n, for every n: Gauss's identity.
- Take any whole number n. Then φ(n) is the sum of μ(d) × n/d over the divisors d of n.
- Take any whole number n. Then φ(n) is n times one bracket 1 − 1/p for each different prime p dividing n.
- Suppose every value of f and g is nonzero. Then products over divisors invert the same way, with each g(n/d) raised to the power μ(d).
- Take functions F and G of a bound x ≥ 1, with every sum over n up to x. Then G(x) adds up F(x/n) exactly when F(x) is the sum of μ(n) G(x/n).
- On the 60 dial, Lean lists the 16 touring jumps and checks that the inversion terms add to 16.
- For the house number 720720, the factorisation and the product of brackets, 138,240, check.
- The product form gives r(8) = 2 and r(12) = 1.
- The running total T(60) is 1,102, by the totients and by the inverted pair count.
- For eight-bit strings, the inversion sum gives 240, and 240 ÷ 8 = 30.
- The broken versions come out at 24, 144 and −44, not 16, and 96 × 720 = 69,120, not 138,240.

Checks up to 10,000, the dial stepping and the growth of T(x) are left to the Python and Rust checks.

```lean
-- The Mobius function: weighting a divisor sum by the Möbius signs gives back the function that was summed, for any function at all, and inverting Gauss's identity gives the totient as n times the product of (1 - 1/p).
import Mathlib.NumberTheory.ArithmeticFunction.Moebius
import Mathlib.Data.Nat.Totient
import Mathlib.Data.Nat.Squarefree
import Mathlib.Data.Real.Archimedean
import Mathlib.Tactic.Simproc.Factors
import Mathlib.Tactic.Simproc.Divisors
import Mathlib.Algebra.Order.Floor.Semifield

open ArithmeticFunction ArithmeticFunction.Moebius

theorem moebius_divisor_sum_eq (k : ℕ) :
    ∑ d ∈ k.divisors, μ d = if k = 1 then 1 else 0 := by
  rw [← coe_mul_zeta_apply, moebius_mul_coe_zeta, ArithmeticFunction.one_apply]

#print axioms moebius_divisor_sum_eq

theorem sum_Icc_div_eq_sum_antidiag {R : Type*} [AddCommMonoid R] (N : ℕ) (H : ℕ → ℕ → R) :
    ∑ n ∈ Finset.Icc 1 N, ∑ m ∈ Finset.Icc 1 (N / n), H n m =
      ∑ k ∈ Finset.Icc 1 N, ∑ p ∈ k.divisorsAntidiagonal, H p.1 p.2 := by
  rw [Finset.sum_sigma', Finset.sum_sigma']
  refine Finset.sum_bij' (fun p _ => ⟨p.1 * p.2, (p.1, p.2)⟩) (fun p _ => ⟨p.2.1, p.2.2⟩)
    ?_ ?_ ?_ ?_ ?_
  · rintro ⟨n, m⟩ h
    simp only [Finset.mem_sigma, Finset.mem_Icc, Nat.mem_divisorsAntidiagonal] at h ⊢
    obtain ⟨⟨hn1, hnN⟩, hm1, hmN⟩ := h
    have h0 : n * m ≠ 0 := Nat.mul_ne_zero (by omega) (by omega)
    have := (Nat.le_div_iff_mul_le (by omega)).mp hmN
    have hmn : n * m ≤ N := by linarith [mul_comm m n]
    exact ⟨⟨by omega, hmn⟩, by simp [h0]⟩
  · rintro ⟨k, a, b⟩ h
    simp only [Finset.mem_sigma, Finset.mem_Icc, Nat.mem_divisorsAntidiagonal] at h ⊢
    obtain ⟨⟨hk1, hkN⟩, hab, hk0⟩ := h
    subst hab
    have ha : a ≠ 0 := left_ne_zero_of_mul hk0
    have hb : b ≠ 0 := right_ne_zero_of_mul hk0
    refine ⟨⟨by omega, ?_⟩, by omega, ?_⟩
    · exact le_trans (Nat.le_mul_of_pos_right a (by omega)) hkN
    · rw [Nat.le_div_iff_mul_le (by omega)]; linarith [mul_comm a b]
  · rintro ⟨n, m⟩ _; rfl
  · rintro ⟨k, a, b⟩ h
    simp only [Finset.mem_sigma, Nat.mem_divisorsAntidiagonal] at h
    obtain ⟨_, hab, _⟩ := h
    subst hab; rfl
  · rintro ⟨n, m⟩ _; rfl

#print axioms sum_Icc_div_eq_sum_antidiag

/-- Möbius inversion. Let f and g be any functions on the whole numbers, with values in any
additive group (no condition on f at all). Then g adds up f over the divisors of every n,
g(n) = ∑_{d ∣ n} f(d), exactly when f comes back from g by the Möbius-weighted sum
f(n) = ∑_{d ∣ n} μ(d) g(n/d), for every n ≥ 1. Here μ(d) is +1 or −1 when d is a product of
an even or odd number of different primes, and 0 when a prime squared divides d. -/
theorem mobius_inversion {R : Type*} [AddCommGroup R] (f g : ℕ → R) :
    (∀ n > 0, g n = ∑ d ∈ n.divisors, f d) ↔
      ∀ n > 0, f n = ∑ d ∈ n.divisors, μ d • g (n / d) := by
  have := sum_eq_iff_sum_smul_moebius_eq (f := f) (g := g)
  simp only [Nat.sum_divisorsAntidiagonal (f := fun a b => μ a • g b)] at this
  constructor
  · intro h n hn; exact (this.mp (fun n hn => (h n hn).symm) n hn).symm
  · intro h n hn; exact (this.mpr (fun n hn => (h n hn).symm) n hn).symm

/-- The totient, three ways. Gauss's identity: the totients of the divisors of n add up to n.
Inverting it: φ(n) = ∑_{d ∣ n} μ(d) · n/d. Expanding the signs: φ(n) = n ∏_{p ∣ n} (1 − 1/p),
one bracket for each different prime p dividing n. -/
theorem totient_by_mobius_inversion (n : ℕ) :
    ∑ d ∈ n.divisors, Nat.totient d = n ∧
      (Nat.totient n : ℤ) = ∑ d ∈ n.divisors, μ d * ((n / d : ℕ) : ℤ) ∧
      (Nat.totient n : ℚ) = n * ∏ p ∈ n.primeFactors, (1 - 1 / (p : ℚ)) := by
  refine ⟨Nat.sum_totient n, ?_, ?_⟩
  · rcases Nat.eq_zero_or_pos n with rfl | hn
    · simp
    have := (sum_eq_iff_sum_mul_moebius_eq (R := ℤ) (f := fun d => (Nat.totient d : ℤ))
      (g := fun d => (d : ℤ))).mp (fun m _ => by exact_mod_cast Nat.sum_totient m) n hn
    simp only [Int.cast_id] at this
    rw [Nat.sum_divisorsAntidiagonal (f := fun a b => μ a * (b : ℤ))] at this
    simpa using this.symm
  · simpa only [one_div] using Nat.totient_eq_mul_prod_factors n

/-- The two more forms of inversion.
Product form: when every value of f and g is nonzero, g(n) = ∏_{d ∣ n} f(d) for every n ≥ 1
exactly when f(n) = ∏_{d ∣ n} g(n/d)^μ(d) for every n ≥ 1.
Running-total form: for functions F and G of a real bound x, G(x) = ∑_{n ≤ x} F(x/n) for every
x ≥ 1 exactly when F(x) = ∑_{n ≤ x} μ(n) G(x/n) for every x ≥ 1. -/
theorem mobius_inversion_product_form_and_running_total
    {K : Type*} [CommGroupWithZero K] (f g : ℕ → K)
    (hf : ∀ n > 0, f n ≠ 0) (hg : ∀ n > 0, g n ≠ 0)
    {R : Type*} [AddCommGroup R] (F G : ℝ → R) :
    ((∀ n > 0, g n = ∏ d ∈ n.divisors, f d) ↔
        ∀ n > 0, f n = ∏ d ∈ n.divisors, g (n / d) ^ μ d) ∧
      ((∀ x : ℝ, 1 ≤ x → G x = ∑ n ∈ Finset.Icc 1 ⌊x⌋₊, F (x / n)) ↔
        ∀ x : ℝ, 1 ≤ x → F x = ∑ n ∈ Finset.Icc 1 ⌊x⌋₊, μ n • G (x / n)) := by
  constructor
  · have := prod_eq_iff_prod_pow_moebius_eq_of_ne_zero (f := f) (g := g) hf hg
    simp only [Nat.prod_divisorsAntidiagonal (f := fun a b => g b ^ μ a)] at this
    constructor
    · intro h n hn; exact (this.mp (fun n hn => (h n hn).symm) n hn).symm
    · intro h n hn; exact (this.mpr (fun n hn => (h n hn).symm) n hn).symm
  -- facts about x / n
  have hge : ∀ x : ℝ, 1 ≤ x → ∀ n ∈ Finset.Icc 1 ⌊x⌋₊, 1 ≤ x / n := by
    intro x hx n hn
    rw [Finset.mem_Icc] at hn
    have hn0 : (0 : ℝ) < n := by exact_mod_cast hn.1
    rw [one_le_div hn0]
    exact (Nat.le_floor_iff (by linarith)).mp hn.2
  have hdiv : ∀ x : ℝ, ∀ a b : ℕ, x / a / b = x / ((a * b : ℕ) : ℝ) := by
    intro x a b; push_cast; rw [div_div]
  have hone : ∀ x : ℝ, 1 ≤ x → 1 ∈ Finset.Icc 1 ⌊x⌋₊ := by
    intro x hx; rw [Finset.mem_Icc]; exact ⟨le_rfl, Nat.le_floor (by simpa using hx)⟩
  constructor
  · intro h x hx
    have e : ∑ n ∈ Finset.Icc 1 ⌊x⌋₊, μ n • G (x / n) =
        ∑ n ∈ Finset.Icc 1 ⌊x⌋₊, ∑ m ∈ Finset.Icc 1 (⌊x⌋₊ / n), μ n • F (x / n / m) := by
      refine Finset.sum_congr rfl fun n hn => ?_
      rw [h (x / n) (hge x hx n hn), Nat.floor_div_natCast, Finset.smul_sum]
    rw [e, sum_Icc_div_eq_sum_antidiag, Finset.sum_eq_single_of_mem 1 (hone x hx)]
    · simp [Nat.divisorsAntidiagonal_one]
    · intro k _ hk1
      have e2 : ∑ p ∈ k.divisorsAntidiagonal, μ p.1 • F (x / p.1 / p.2) =
          ∑ p ∈ k.divisorsAntidiagonal, μ p.1 • F (x / k) := by
        refine Finset.sum_congr rfl fun p hp => ?_
        rw [Nat.mem_divisorsAntidiagonal] at hp
        rw [hdiv, hp.1]
      rw [e2, ← Finset.sum_smul,
        Nat.sum_divisorsAntidiagonal (f := fun a _ => μ a), moebius_divisor_sum_eq]
      simp [hk1]
  · intro h x hx
    have e : ∑ n ∈ Finset.Icc 1 ⌊x⌋₊, F (x / n) =
        ∑ n ∈ Finset.Icc 1 ⌊x⌋₊, ∑ m ∈ Finset.Icc 1 (⌊x⌋₊ / n), μ m • G (x / n / m) := by
      refine Finset.sum_congr rfl fun n hn => ?_
      rw [h (x / n) (hge x hx n hn), Nat.floor_div_natCast]
    rw [e, sum_Icc_div_eq_sum_antidiag, Finset.sum_eq_single_of_mem 1 (hone x hx)]
    · simp [Nat.divisorsAntidiagonal_one]
    · intro k _ hk1
      have e2 : ∑ p ∈ k.divisorsAntidiagonal, μ p.2 • G (x / p.1 / p.2) =
          ∑ p ∈ k.divisorsAntidiagonal, μ p.2 • G (x / k) := by
        refine Finset.sum_congr rfl fun p hp => ?_
        rw [Nat.mem_divisorsAntidiagonal] at hp
        rw [hdiv, hp.1]
      rw [e2, ← Finset.sum_smul,
        Nat.sum_divisorsAntidiagonal' (f := fun _ b => μ b), moebius_divisor_sum_eq]
      simp [hk1]

-- The 60 dial: the divisors of 60, and the 60 jumps sorted by loop length add back to 60.
example : Nat.divisors 60 = {1, 2, 3, 4, 5, 6, 10, 12, 15, 20, 30, 60} := by decide
example : ∑ d ∈ Nat.divisors 60, Nat.totient d = 60 := by decide

-- The 16 jumps that tour the whole dial, and φ(60) = 16.
example : (Finset.range 61).filter (fun k => Nat.Coprime k 60) =
    {1, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 49, 53, 59} := by decide
example : Nat.totient 60 = 16 := by decide

-- Möbius signs from the symbol table: μ(6) = 1, μ(30) = −1, μ(4) = 0.
example : μ 6 = 1 := by
  simp [moebius_apply_of_squarefree, Nat.squarefree_iff_nodup_primeFactorsList, cardFactors_apply,
    Nat.primeFactorsList_ofNat]
example : μ 30 = -1 := by
  simp [moebius_apply_of_squarefree, Nat.squarefree_iff_nodup_primeFactorsList, cardFactors_apply,
    Nat.primeFactorsList_ofNat]
example : μ 4 = 0 := moebius_eq_zero_of_not_squarefree (by decide)

-- Step 0: the signs over the divisors of 60 add to 0.
example : ∑ d ∈ Nat.divisors 60, μ d = 0 := by
  simp only [Nat.divisors_ofNat]
  simp [Finset.sum_insert, moebius_apply_of_squarefree, moebius_eq_zero_of_not_squarefree,
    Nat.squarefree_iff_nodup_primeFactorsList, cardFactors_apply, Nat.primeFactorsList_ofNat]

-- Inversion at 60: 60 − 30 − 20 − 12 + 10 + 6 + 4 − 2 = 16.
example : ∑ d ∈ Nat.divisors 60, μ d * ((60 / d : ℕ) : ℤ) = 16 := by
  simp only [Nat.divisors_ofNat]
  simp [Finset.sum_insert, moebius_apply_of_squarefree, moebius_eq_zero_of_not_squarefree,
    Nat.squarefree_iff_nodup_primeFactorsList, cardFactors_apply, Nat.primeFactorsList_ofNat]
example : (60 - 30 - 20 - 12 + 10 + 6 + 4 - 2 : ℤ) = 16 := by norm_num

-- Product of brackets at 60: 60 × 1/2 × 2/3 × 4/5 = 16.
example : (60 : ℚ) * (1 - 1 / 2) * (1 - 1 / 3) * (1 - 1 / 5) = 16 := by norm_num

-- The house number: 720720 = 2⁴ × 3² × 5 × 7 × 11 × 13, with 240 divisors, 64 of them squarefree,
-- and φ(720720) = 138,240 by the product of brackets.
example : 2 ^ 4 * 3 ^ 2 * 5 * 7 * 11 * 13 = 720720 := by norm_num
example : (4 + 1) * (2 + 1) * 2 * 2 * 2 * 2 = 240 := by norm_num
example : 2 ^ 6 = 64 := by norm_num
example : (720720 : ℚ) * (1 - 1 / 2) * (1 - 1 / 3) * (1 - 1 / 5) * (1 - 1 / 7) * (1 - 1 / 11)
    * (1 - 1 / 13) = 138240 := by norm_num

-- Product form: r(8) = 8 ÷ 4 = 2 and r(12) = 12 × 2 ÷ (6 × 4) = 1.
example : ∏ d ∈ Nat.divisors 8, ((8 / d : ℕ) : ℚ) ^ μ d = 2 := by
  simp only [Nat.divisors_ofNat]
  simp [Finset.prod_insert, moebius_apply_of_squarefree, moebius_eq_zero_of_not_squarefree,
    Nat.squarefree_iff_nodup_primeFactorsList, cardFactors_apply, Nat.primeFactorsList_ofNat]
  norm_num
example : ∏ d ∈ Nat.divisors 12, ((12 / d : ℕ) : ℚ) ^ μ d = 1 := by
  simp only [Nat.divisors_ofNat]
  simp [Finset.prod_insert, moebius_apply_of_squarefree, moebius_eq_zero_of_not_squarefree,
    Nat.squarefree_iff_nodup_primeFactorsList, cardFactors_apply, Nat.primeFactorsList_ofNat]
  norm_num

-- Running-total form at x = 60: T(60) = φ(1) + … + φ(60) = 1,102, and the inverted pair count
-- ∑_{n ≤ 60} μ(n) ⌊60/n⌋(⌊60/n⌋ + 1)/2 gives the same 1,102 with no totient; 60 × 61/2 = 1,830.
example : ∑ n ∈ Finset.Icc 1 60, Nat.totient n = 1102 := by decide
example : ∑ n ∈ Finset.Icc 1 60, μ n * ((60 / n * (60 / n + 1) / 2 : ℕ) : ℤ) = 1102 := by
  rw [show Finset.Icc 1 60 = Finset.Ico 1 61 from rfl, Finset.sum_Ico_eq_sum_range]
  simp [Finset.sum_range_succ, moebius_apply_of_squarefree, moebius_eq_zero_of_not_squarefree,
    Nat.squarefree_iff_nodup_primeFactorsList, cardFactors_apply, Nat.primeFactorsList_ofNat]
example : 60 * 61 / 2 = 1830 := by norm_num

-- Eight-bit strings that are no shorter block repeated: ∑_{d ∣ 8} μ(d) 2^(8/d) = 240, and 240/8 = 30.
example : ∑ d ∈ Nat.divisors 8, μ d * (2 : ℤ) ^ (8 / d) = 240 := by
  simp only [Nat.divisors_ofNat]
  simp [Finset.sum_insert, moebius_apply_of_squarefree, moebius_eq_zero_of_not_squarefree,
    Nat.squarefree_iff_nodup_primeFactorsList, cardFactors_apply, Nat.primeFactorsList_ofNat]
example : 240 / 8 = 30 := by norm_num

-- What breaks. Signs that count repeated primes, (−1) to the number of prime factors with
-- repeats: 24, not 16. Signs dropped: 144. The term d = 1 left out: −44.
example : ∑ d ∈ Nat.divisors 60, (-1 : ℤ) ^ cardFactors d * ((60 / d : ℕ) : ℤ) = 24 := by
  simp only [Nat.divisors_ofNat]
  simp [Finset.sum_insert, cardFactors_apply, Nat.primeFactorsList_ofNat]
example : 60 + 30 + 20 + 12 + 10 + 6 + 4 + 2 = 144 := by norm_num
example : (-30 - 20 - 12 + 10 + 6 + 4 - 2 : ℤ) = -44 := by norm_num

-- φ(360) × φ(2002) = 96 × 720 = 69,120, not φ(720720) = 138,240: 360 and 2002 share a 2.
example : Nat.totient 360 = 96 := by decide
example : (2002 : ℚ) * (1 - 1 / 2) * (1 - 1 / 7) * (1 - 1 / 11) * (1 - 1 / 13) = 720 := by norm_num
example : 96 * 720 = 69120 := by norm_num
example : Nat.gcd 360 2002 = 2 := by decide

#print axioms mobius_inversion
#print axioms totient_by_mobius_inversion
#print axioms mobius_inversion_product_form_and_running_total
```

**Checked 2026-11-15 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'moebius_divisor_sum_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'sum_Icc_div_eq_sum_antidiag' depends on axioms: [propext, Classical.choice, Quot.sound]
'mobius_inversion' depends on axioms: [propext, Classical.choice, Quot.sound]
'totient_by_mobius_inversion' depends on axioms: [propext, Classical.choice, Quot.sound]
'mobius_inversion_product_form_and_running_total' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it. The asserts are pinned to the card's numbers, so some changes stop the program.
> - **Guess first: what if μ gave +1, not 0, on a repeated prime?** In `mu`, change `return 0 if` to `return 1 if`. The first assert stops it: at n = 4 the signs add to 1, not 0.
> - **Guess first: is T(100) above or below 3 × 100²/π²?** Add 100 to the tuple `(60, 1000, N)`. The ratio prints above 1, between the values at 60 and at 1,000.
> - **Guess first: how many jumps tour a dial of 61 marks?** In the `tours` line, write `range(1, 62)` and change both 60s to 61. Since 61 is prime, every jump from 1 to 60 tours, and the assert pinned to 16 stops the run.

---

## The usual mistake

> [!warning]
> **Inverting with the wrong signs.** The Möbius sign is not "−1 for each prime factor, counted with repeats". A divisor holding a squared prime gets 0. Counting repeats turns the 60 sum into 24, not 16, because the divisors 4, 12, 20 and 60 no longer drop out.
>
> - **Dropping the signs.** Adding 60/d over the squarefree divisors with every sign +1 gives 144, not 16.
> - **Splitting φ across a shared prime.** φ(360) × φ(2002) = 96 × 720 = 69,120, half of φ(720720) = 138,240, because 360 and 2002 share a 2.
> - **Leaving out d = 1.** The divisor 1 always carries the sign +1 and the whole of g(n). Without its term 60 the sum is −44, not 16.

---

## Where you meet it in real life

- **Hash tables and round-robin schedules.** A probe step on a table of 60 slots reaches every slot only if it shares no factor with 60. Of the 60 steps, 16 do, and inversion counts them from Gauss's identity.
- **Error-checking codes and ciphers.** Byte-level codes and ciphers do arithmetic in GF(2⁸), the field of 256 elements, built from an irreducible polynomial of degree 8 over GF(2), arithmetic with only 0 and 1 where 1 + 1 = 0. Of the 256 eight-bit strings, 240 are not a shorter block repeated. The 256 field elements sort the same way: each is a root of exactly one irreducible polynomial, of a degree d dividing 8, with d roots. So 2⁸ is the sum, over the divisors d of 8, of d times the number of such polynomials, and inversion gives 240 elements whose polynomial has degree 8. Dividing by 8 gives 30 polynomials, and brute force agrees.
- **Fractions in lowest terms.** The running total T(x) counts the reduced fractions with denominator up to x, the Farey fractions used in rational approximation. Inverting a simple pair count gives T(60) = 1,102 with no totient computed.
- **Counting in combinatorics.** Inclusion–exclusion, adding and subtracting overlaps, is Möbius inversion on subsets. Rota's 1964 paper made it one method for any partially ordered set.

> **Say it back**
> The Möbius sign of d is +1 or −1 when d is a product of different primes, by whether their count is even or odd, and 0 when a prime repeats. These signs over the divisors of n cancel except at n = 1. So weighting a divisor sum by them undoes it: f = μ * g whenever g = 1 * f. The 60 jumps on a dial, sorted by loop length, show the totients of the divisors add to n; inversion then gives φ(60) = 60 − 30 − 20 − 12 + 10 + 6 + 4 − 2 = 16. The same proof undoes products over divisors and sums over all n up to x.

---

## What this builds on

- [Multiplicative functions](02-multiplicative-functions-and-dirichlet-convolution.md): Dirichlet convolution in this shelf's notation, Gauss's identity proved one prime power at a time, and why multiplicative functions split across coprime parts.
- [Dirichlet series](../../07-Complex%20analysis/09-Special%20Functions%20and%20the%20Zeta%20Function/06-dirichlet-series-and-mobius-inversion.md): defines μ, proves its signs cancel past 1, proves convolution associative, and proves inversion by dividing by zeta.
- [Prime factorisation](../../02-Number%20theory/01-Divisibility%20and%20Primes/07-prime-factorisation.md): one factorisation per number, so μ(n) and the brackets $`1 - 1/p`$ are well defined.

## Where this goes next

- [The von Mangoldt function](04-von-mangoldt-and-the-logarithmic-derivative.md): takes logs of the product form to weight prime powers by log p.
- [Squarefree numbers](07-squarefree-numbers-and-their-density.md): uses the same signs to count the numbers with no squared prime, about six in every ten.

This card makes the signs exact, but not their running total. How small does μ(1) + μ(2) + … + μ(x) stay as x grows? Proving it is a vanishing share of x is known to be equivalent to the prime number theorem. Holding it below x raised to every power above one half is equivalent to the Riemann hypothesis, open until a formal proof was certified on 2026-11-21 ([The Riemann hypothesis](../../25-Frontier/02-The%20Millennium%20Problems/01-riemann-hypothesis.md)).

---

## Sources

Verified 2026-11-15: every link below resolves to the publisher's page.

- Apostol, Tom M. *Introduction to Analytic Number Theory*. Springer, 1976. [DOI 10.1007/978-1-4757-5579-4](https://doi.org/10.1007/978-1-4757-5579-4). Chapter 2 proves Gauss's identity, Möbius inversion, the product form and the inversion for sums up to x; Chapter 3 gives the growth of the totient's running total.
- Möbius, A. F. "Über eine besondere Art von Umkehrung der Reihen." *Journal für die reine und angewandte Mathematik* 9 (1832), 105–123. [DOI 10.1515/crll.1832.9.105](https://doi.org/10.1515/crll.1832.9.105). The original paper on the inversion of series.
- Rota, Gian-Carlo. "On the foundations of combinatorial theory I. Theory of Möbius functions." *Zeitschrift für Wahrscheinlichkeitstheorie und verwandte Gebiete* 2 (1964), 340–368. [DOI 10.1007/BF00531932](https://doi.org/10.1007/BF00531932). Inversion on any partially ordered set, with inclusion–exclusion as a case.
- Lidl, Rudolf, and Harald Niederreiter. *Finite Fields*, 2nd ed. Cambridge University Press, 1997. [DOI 10.1017/CBO9780511525926](https://doi.org/10.1017/CBO9780511525926). Counts irreducible polynomials over a finite field by Möbius inversion.
