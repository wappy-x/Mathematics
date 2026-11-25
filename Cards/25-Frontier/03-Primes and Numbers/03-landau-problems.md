# Landau's four problems: Goldbach, twin primes, Legendre, and primes of the form n squared plus 1

[Syllabus](../../../SYLLABUS.md) → [Frontier](../README.md) → [Primes and Numbers](../README.md#s03) → Landau's four problems

---

## General Overview

100 × 100 = 10,000 and 101 × 101 = 10,201. Is there a prime between them? Yes: **10,007** is one. In fact 23 of the 200 numbers in between are prime.

The question "is there always a prime between two neighbouring squares?" is one of four that Edmund Landau set out in Cambridge in August 1912, at the International Congress of Mathematicians. He called them unattackable "at the present state of science". The other three ask about Goldbach's sums of two primes, twin primes and primes of the form n² + 1.

More than a century later, all four are still open. Many results sit close to them, and several of those are often reported as if they settled a Landau problem. This card keeps the record straight. For each problem it gives the exact statement, what is proved, what is only checked, and the date and source of each fact.

**Each of Landau's four problems asks for a prime in a thin set; all four are open as of 2026-11-23, and every nearby result, however famous, proves a weaker or a different statement.**

**What kind of fact this is:** four conjectures, each open as of 2026-11-23: no accepted proof or disproof. Around them the card states dated theorems with sources and instances checked by its own code. A check up to some number is evidence, never proof. Nothing here proves or refutes a Landau problem.

The number-theory wing's [Landau's four problems](../../21-Algebraic%20and%20analytic%20number%20theory/04-Sieves%20and%20Prime%20Gaps/08-landau-problems-and-legendre.md) states all four and shows why sieve methods stop one step short of each. This card does not repeat that. It spends its space on the status record.

### The picture: primes between neighbouring squares near 10,000

Each bar counts the primes strictly between n² and (n + 1)². Legendre's problem asks only that no bar ever has length zero.

```
n =  96   9216 to   9409 #####################    21
n =  97   9409 to   9604 ######################   22
n =  98   9604 to   9801 #######################  23
n =  99   9801 to  10000 #####################    21
n = 100  10000 to  10201 #######################  23
n = 101  10201 to  10404 ######################   22
n = 102  10404 to  10609 ####################     20
n = 103  10609 to  10816 #####################    21
n = 104  10816 to  11025 #####################    21
```

Near 10,000 every interval holds about 20 primes, far from zero. The expected count at n = 100 is 21.7. It is the sum of 1/log m over the interval, where log is the natural logarithm and 1/log m is the chance that a number near m is prime. Nothing in this picture is a proof: the open question is whether some bar, far out, is empty.

---

## The formula

Landau's four questions, in his own order and with his constants. Throughout, p and q are primes.

```math
\begin{aligned} &\text{(1) } n^2 + 1: && n^2 + 1 \text{ is prime for infinitely many whole numbers } n \\ &\text{(2) Goldbach:} && \text{every even } m \ge 4 \text{ equals } p + q \\ &\text{(3) Twin primes:} && \pi_2(x) \to \infty \text{ as } x \to \infty \\ &\text{(4) Legendre:} && \pi\big((n+1)^2\big) - \pi\big(n^2\big) \ge 1 \text{ for every whole number } n \ge 1 \end{aligned}
```

**Read it aloud:** n squared plus one is prime infinitely often; every even number from 4 up is two primes added; the twin pairs never run out; and between any two neighbouring squares there is a prime.

Here π(x) is the prime-counting function: the number of primes up to x. π₂(x) counts the twin pairs p, p + 2 with p at most x, as on [Twin primes](01-twin-primes-and-bounded-gaps.md).

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $`n`$ | a whole number: the base of a square, or the input to n² + 1 | 100, giving 10,000 to 10,201 | the interval between squares has 2n numbers, so more primes |
| $`m`$ | an even number to split as two primes; also the running number in the sum of 1/log m | 10,000 = 59 + 9,941 | more ways: 127 for 10,000 |
| $`p`$, $`q`$ | primes | 10,007 | — |
| $`x`$ | a size: the top of a count | 10^6; 4 × 10^18 | — |
| $`\pi(x)`$ | the number of primes up to x | π(10,201) − π(10,000) = 23 | grows like x / log x |
| $`\pi_2(x)`$ | the number of twin pairs up to x | 8,169 pairs below 10^6 | grows, as far as anyone has counted |
| $`a`$, $`b`$ | whole numbers in Friedlander and Iwaniec's a² + b⁴ | b = 1 would give n² + 1 | — |

### When it holds

Each statement has a boundary. Move it and the statement changes or fails.

- **Goldbach needs "even" and "from 4 up".** Landau wrote "every even m > 2". The number 2 is not two primes added. Odd numbers such as 11 fail: one prime would have to be 2, and 11 − 2 = 9 is not prime.
- **Twin primes need the gap 2.** With gap 1 the only pair is 2 and 3, since one of two neighbours is even.
- **Legendre needs n ≥ 1.** At n = 0 there are 0 whole numbers strictly between 0 and 1. "Strictly" does not matter from n = 1 up, since a square is never prime.
- **n² + 1 needs a polynomial with no forced factor.** n² − 1 = (n − 1)(n + 1) is prime for 1 value of n from 1 to 1,000, namely n = 2. n² + 1 does not factor, and no prime divides all its values.

---

## Why it works

Nothing below proves a Landau problem. The steps explain what kind of evidence can bear on each one, then lay out the record.

### Step 0: one question, four thin sets

Each problem asks whether a thin set of numbers contains primes. The sets are the numbers m − p, the pairs n and n + 2, the 2n numbers after n², and the values n² + 1.

Landau chose them on purpose. He wrote that he picked "questions with precise wording" and "special constants, to bring out the core more clearly". The gap 2, the squares and the polynomial n² + 1 are the simplest cases of much wider questions.

### Step 1: two kinds of claim, two kinds of evidence

The four statements split into two pairs by their quantifier (the "for every" or "infinitely many" that governs them).

- **"For every n" claims: Goldbach and Legendre.** One counterexample would refute them. So a computer search can disprove them, and a finished search to some bound is a real fact: "checked to N".
- **"Infinitely many" claims: twin primes and n² + 1.** No finite search can prove or refute them. A count such as 8,169 twin pairs below 10^6 shows the pattern goes on, not that it never stops.

That is why the status record below has a "checked" column for two problems and a "counted" column for the other two.

### Step 2: how a gap table checks Legendre

The number-theory wing's card proves one fact this card uses. If no prime lies between n² and (n + 1)², then the primes on either side are at least 2n + 3 apart.

So a table of the largest prime gaps checks Legendre. At n = 100 a failure would need a gap of at least 203 near 10,000. Below 10^6 the largest gap is 114, after 492,113, so every n from 56 to 999 passes, and trial division clears n = 1 to 55.

The record gap below 4 × 10^18 is 1,476. So every n from 737 up passes until (n + 1)² reaches 4 × 10^18, that is n + 1 = 2,000,000,000. The smaller n are already cleared below 10^6. Legendre is checked for every n up to 1,999,999,999.

### Step 3: the status record

Status words follow one rule. **Open** means no accepted proof or disproof. **Proved** means refereed, or accepted in a source independent of the authors. **Claimed** means a primary source asserts it and it is not yet accepted.

| Problem | Landau's number | Kind | Status, 2026-11-23 | Checked or counted | Source of the check |
| --- | --- | --- | --- | --- | --- |
| n² + 1 | 1 | conjecture | open | 112 values of n up to 1,000 give a prime (this card's code) | — |
| Goldbach | 2 | conjecture | open | every even number up to 4 × 10^18 | Oliveira e Silva, Herzog and Pardi, 2014 |
| Twin primes | 3 | conjecture | open | 8,169 pairs below 10^6 (this card's code) | — |
| Legendre | 4 | conjecture | open | every n up to 1,999,999,999 | the 2014 gap table, through Step 2 |

### Step 4: the nearest proved results, dated

Each row is a theorem: proved and refereed. Each is weaker than the Landau problem beside it, or about a different statement.

| Year published | Problem it is near | What is proved | Why it is not the problem | Where sourced |
| --- | --- | --- | --- | --- |
| 1937 | Legendre | a prime between n³ and (n + 1)³ for every large n (Ingham) | cubes, not squares | Sources |
| 1973 | Goldbach | every large even number is a prime plus a number with at most two prime factors (Chen) | the second number may have two factors | [Goldbach](../../21-Algebraic%20and%20analytic%20number%20theory/04-Sieves%20and%20Prime%20Gaps/07-goldbach-and-chens-theorem.md) |
| 1978 | n² + 1 | n² + 1 has at most two prime factors for infinitely many n (Iwaniec) | two factors, not one | [Landau's four problems](../../21-Algebraic%20and%20analytic%20number%20theory/04-Sieves%20and%20Prime%20Gaps/08-landau-problems-and-legendre.md) |
| 1998 | n² + 1 | infinitely many primes a² + b⁴ (Friedlander and Iwaniec) | both a and b vary; n² + 1 fixes b = 1 | Sources |
| 2001 | Legendre | a prime between x − x^0.525 and x for every large x (Baker, Harman and Pintz) | the window x^0.525 is wider than the 2√x between squares once x passes 2^40 | [Landau's four problems](../../21-Algebraic%20and%20analytic%20number%20theory/04-Sieves%20and%20Prime%20Gaps/08-landau-problems-and-legendre.md) |
| 2014 | Twin primes | some gap of at most 70,000,000 occurs infinitely often (Zhang); 246 later in 2014 (Polymath) | 246 is not 2 | [Bounded gaps](../../21-Algebraic%20and%20analytic%20number%20theory/04-Sieves%20and%20Prime%20Gaps/05-bounded-gaps-zhang-maynard.md) |
| 2023 | n² + 1 | the largest prime factor of n² + 1 exceeds n^1.279 for infinitely many n (Merikoski) | a large factor is not the whole number | Sources |

Ingham's result rests on a simple comparison. He proved prime gaps near x are at most about x^(5/8). The gap between neighbouring cubes is about 3x^(2/3), and 5/8 = 0.625 is less than 2/3 = 0.667. Squares would need gaps below 2√x, an exponent of 1/2 = 0.500, which no method reaches. Even the Riemann hypothesis gives only √x log x, which is too wide.

### Step 5: the corrected record

These are the confusions that a status record has to correct. Each line pairs a common wrong statement with the record.

| Wrong statement | The record |
| --- | --- |
| "Legendre: there is a prime between n and 2n" | That is Bertrand's postulate, proved by Chebyshev in 1852 ([Chebyshev's bounds](../../21-Algebraic%20and%20analytic%20number%20theory/01-Arithmetic%20Functions%20Again/08-chebyshev-bounds.md) proves it and cites his paper). Between 100 and 200 there are 21 primes. Legendre's interval after n² is only 2n numbers long. |
| "Legendre: there is a prime between n² and n² + n" | That is Oppermann's conjecture: a stronger, separate statement, which would imply Legendre's. At n = 100 the two halves hold 11 and 12 primes. |
| "Goldbach was proved in 2013" | The 2013 preprint is about the ternary statement: every odd number above 5 is three primes. It is cited on the number-theory wing's [Goldbach](../../21-Algebraic%20and%20analytic%20number%20theory/04-Sieves%20and%20Prime%20Gaps/07-goldbach-and-chens-theorem.md). Landau's even, two-prime statement is open. |
| "Twin primes were proved in 2013" | Zhang proved bounded gaps, refereed in 2014: a gap of at most 70,000,000 recurs. The gap 2 is open; see [Twin primes](01-twin-primes-and-bounded-gaps.md). |
| "Legendre is checked for every n up to 4 × 10^18" | The bound 4 × 10^18 is on the numbers, not on n. Legendre is checked for n up to 1,999,999,999, whose last interval ends at 2,000,000,000² = 4 × 10^18. The check runs through the 2014 gap table (Step 2), not a direct search. |
| "Landau called the fourth problem Legendre's" | Landau named no one. The name Legendre's conjecture is a later label; this card cites no statement of it in Legendre's own writings. |

<details>
<summary>Detailed: what Landau's 1912 text says, question by question</summary>

Landau's lecture, "Solved and unsolved problems from the theory of the distribution of primes and of the Riemann zeta function", runs from page 93 to page 108 of volume 1 of the Congress proceedings. The four questions are on page 106. In translation:

1. Does the function u² + 1 represent infinitely many primes for whole numbers u? (Landau's u is this card's n.)
2. Does the equation m = p + p′ have a solution in primes for every even m > 2?
3. Does the equation 2 = p − p′ have infinitely many solutions in primes?
4. Is there at least one prime between n² and (n + 1)² for every positive whole number n?

He introduces them, on page 105, as questions he holds "unattackable at the present state of science". The card's title lists them in a different order; the numbering above is Landau's.

</details>

---

## Worked numbers, by hand

The example: is there a prime between 100² = 10,000 and 101² = 10,201?

| Step | Arithmetic | Value |
| --- | --- | --- |
| 10,001 | 73 × 137 | not prime |
| 10,003 | 7 × 1,429 | not prime |
| 10,005 | 3 × 5 × 23 × 29 | not prime |
| 10,002, 10,004, 10,006 | even | not prime |
| 10,007: which divisors to try | √10,007 is below 101, since 101 × 101 = 10,201 | the 25 primes up to 97 |
| 10,007 divided by each of them | the smallest remainder is 1 | none divides |
| 10,007 | no prime up to 97 divides it | **prime** |
| all primes from 10,001 to 10,200 | from 10,007 to 10,193 | 23 |
| expected count | sum of 1/log m from 10,001 to 10,200 | 21.7 |

So Legendre holds at n = 100, with 23 primes where one is enough. The same interval touches the other three problems:

- **Twin primes:** 10,007 and 10,009 are a twin pair. The interval holds 5 pairs: (10,007, 10,009), (10,037, 10,039), (10,067, 10,069), (10,091, 10,093) and (10,139, 10,141).
- **Goldbach:** 10,000 = 59 + 9,941, and 10,000 has 127 such splits with p ≤ q.
- **n² + 1:** the interval's first number is 100² + 1 = 10,001 = 73 × 137, not prime. Both factors leave remainder 1 on division by 4. That is no accident: an odd prime divides some n² + 1 only if it leaves remainder 1 ([Landau's four problems](../../21-Algebraic%20and%20analytic%20number%20theory/04-Sieves%20and%20Prime%20Gaps/08-landau-problems-and-legendre.md), Step 4).

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Replace Legendre by Bertrand: a prime between n and 2n | 21 primes between 100 and 200, a theorem since 1852 | Near 10,000, Bertrand's interval would be 10,000 numbers long; Legendre's is 200 |
| Replace Legendre by Oppermann without its boundary | 0 primes between 1 and 2, at n = 1 | Oppermann's halves need n ≥ 2; from 2 to 999 both halves hold |
| Replace n² + 1 by n² − 1 | 1 prime for n = 1 to 1,000, at n = 2 | n² − 1 = (n − 1)(n + 1) factors, so it is prime only when n − 1 = 1 |
| Read Merikoski's exponent as holding for every n | 137, against 100^1.279 ≈ 361, at n = 100 | The theorem says "infinitely many n", not "every n" |

The code prints every row.

---

## Code, from first principles, and it actually runs

The code builds one sieve of Eratosthenes (a table that crosses out every multiple of each prime, leaving the primes) up to 1,000,003, the first prime past a million. It reaches each count a second, independent way. Trial division re-checks the primes near 10,000, the 127 Goldbach splits of 10,000, the 5 twin pairs and the 112 values of n² + 1. The gap argument re-checks Legendre for n = 1 to 999. An algebraic identity, n² − 1 = (n − 1)(n + 1), predicts the single prime n² − 1. The figures 4 × 10^18, 1,476, 70,000,000, 600 and 246 are quoted from the published record, not computed.

### Python

```python
# Landau's four problems, the status card -- the check behind it.  Standard library only.
# One sieve of Eratosthenes to 1,000,003 gives the counts; trial division, the gap
# argument and an algebraic identity reach each count a second, independent way.
import math
X = 1_000_003                                      # the first prime past 10^6
flag = bytearray([1]) * (X + 1); flag[0] = flag[1] = 0
for p in range(2, 1001):
    if flag[p]:
        flag[p * p::p] = bytearray(len(range(p * p, X + 1, p)))
primes = [p for p in range(2, X + 1) if flag[p]]
def by_division(n):                                # road two: trial division
    d = 2
    while d * d <= n and n % d: d += 1
    return n > 1 and d * d > n
def factor(n):
    out, d = [], 2
    while d * d <= n:
        while n % d == 0: out.append(d); n //= d
        d += 1
    return out + ([n] if n > 1 else [])
def between(a, b): return [m for m in range(a + 1, b) if flag[m]]   # strictly between
# The example: Legendre at n = 100, between 10,000 and 10,201
inside = between(100**2, 101**2)
print(f"primes between 10000 and 10201: {len(inside)}; first {inside[0]}, last {inside[-1]}")
for m in range(10001, 10007, 2): print(f"{m} = {' x '.join(map(str, factor(m)))}")
small = [p for p in primes if p < 101]
rems = [10007 % p for p in small]
print(f"10007 by the {len(small)} primes up to 97: smallest remainder {min(rems)}; 101 x 101 = {101 * 101}")
expect = sum(1 / math.log(m) for m in range(10001, 10201))
print(f"expected count, sum of 1/log m from 10001 to 10200: {expect:.1f}")
for n in range(96, 105):
    c = len(between(n * n, (n + 1) ** 2))
    print(f"bar n = {n:>3} {n * n:>6} to {(n + 1) ** 2:>6} {'#' * c} {c}")
# Legendre for n = 1 to 999: road one counts directly, road two is the gap argument
direct = all(between(n * n, (n + 1) ** 2) for n in range(1, 1000))
gap = max((b - a, a) for a, b in zip(primes, primes[1:]) if a < 10**6)
start = (gap[0] - 3) // 2 + 1                       # a failure at n needs a gap >= 2n + 3
hold = all(any(by_division(m) for m in range(n * n + 1, (n + 1) ** 2)) for n in range(1, start))
print(f"Legendre n = 1 to 999 counted directly: {direct}; largest gap below 10^6: {gap[0]} after {gap[1]:,}")
print(f"gap argument: n >= {start} needs a gap >= {2 * start + 3}, none below 10^6; n = 1 to {start - 1} by trial division: {hold}")
print(f"at n = 100 a failure needs a gap of at least {2 * 100 + 3}")
print(f"quoted gap record 1476 below 4e18: n >= {(1476 - 3) // 2 + 1} safe up to n + 1 = {math.isqrt(4 * 10**18):,}")
print(f"0.525 window equals 2 sqrt x at x = 2^40 = {2**40:,}")
print(f"Ingham 1937: exponent 5/8 = {5 / 8:.3f} < 2/3 = {2 / 3:.3f}, enough for cubes; squares need 1/2 = {1 / 2:.3f}")
print("quoted record, by year published: Goldbach checked to 4e18 (2014); bounded gaps 70000000 (2014), 600 (2015), 246 (2014)")
# What Legendre does not say: Bertrand (proved) and Oppermann (stronger, open)
print(f"Bertrand, between 100 and 200: {len(between(100, 200))} primes")
lo, hi = between(10000, 10100), between(10100, 10201)
opp = all(between(n * n, n * n + n) and between(n * n + n, (n + 1) ** 2) for n in range(2, 1000))
print(f"Oppermann at n = 100: {len(lo)} below 10100, {len(hi)} above; both halves hold for n = 2 to 999: {opp}")
print(f"boundary cases: primes between 1 and 2: {len(between(1, 2))}; whole numbers between 0 and 1: {len(range(1, 1))}")
# Goldbach: 10,000 as p + q, two roads; every even m from 4 to 10^6
pairs = [p for p in primes if p <= 5000 and flag[10000 - p]]
pairs2 = [p for p in range(2, 5001) if by_division(p) and by_division(10000 - p)]
worst = max((next(p for p in primes if flag[m - p]), m) for m in range(4, 10**6 + 1, 2))
print(f"10000 = p + q with p <= q: {len(pairs)} ways by sieve, {len(pairs2)} by division; smallest {pairs[0]} + {10000 - pairs[0]}")
print(f"Goldbach for every even m from 4 to 1,000,000: yes; hardest m = {worst[1]:,} needs p = {worst[0]}")
# Twin primes in the example interval, and below 10^6
tw = [p for p in inside if flag[p + 2] and p + 2 < 10201]
tw2 = [p for p in range(10001, 10199, 2) if by_division(p) and by_division(p + 2)]
twins = sum(1 for p in primes if p + 2 < 10**6 and flag[p + 2])
print(f"twin pairs inside 10000 to 10201: {', '.join(f'({p}, {p + 2})' for p in tw)}; by division {len(tw2)}")
print(f"twin pairs below 10^6: {twins:,}")
# n^2 + 1: the example's first number is 100^2 + 1
f1 = factor(10001)
hits = [n for n in range(1, 1001) if flag[n * n + 1]]
hits2 = [n for n in range(1, 1001) if by_division(n * n + 1)]
print(f"100^2 + 1 = 10001 = {f1[0]} x {f1[1]}; remainders on division by 4: {f1[0] % 4}, {f1[1] % 4}")
print(f"n^2 + 1 prime for n = 1 to 1000: {len(hits)} by sieve, {len(hits2)} by division; last {hits[-1]}")
sq = [n for n in range(1, 1001) if flag[n * n - 1]]
print(f"n^2 - 1 = (n - 1)(n + 1) prime for n = 1 to 1000: {len(sq)}, at n = {sq[0]}")
print(f"largest prime factor of 10001: {max(f1)}; 100^1.279 = {100**1.279:.0f}")
assert inside[0] == 10007 and all(by_division(m) for m in inside) and not any(by_division(m) for m in range(10001, 10007))
assert len(inside) == sum(by_division(m) for m in range(10001, 10201)) and 0 not in rems
assert direct and hold and gap == (114, 492113) and opp and not between(1, 2)
assert 2 * start + 1 <= gap[0] < 2 * start + 3          # start is the first n the gap table clears
assert pairs == pairs2 and worst == (523, 503222) and twins == 8169
assert tw == tw2 and tw[0] == 10007 and len(tw) == 5
assert hits == hits2 and len(hits) == 112 and sq == [2] and f1 == [73, 137]
print("ALL CHECKS PASS")
```

**Ran 2026-11-23 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
primes between 10000 and 10201: 23; first 10007, last 10193
10001 = 73 x 137
10003 = 7 x 1429
10005 = 3 x 5 x 23 x 29
10007 by the 25 primes up to 97: smallest remainder 1; 101 x 101 = 10201
expected count, sum of 1/log m from 10001 to 10200: 21.7
bar n =  96   9216 to   9409 ##################### 21
bar n =  97   9409 to   9604 ###################### 22
bar n =  98   9604 to   9801 ####################### 23
bar n =  99   9801 to  10000 ##################### 21
bar n = 100  10000 to  10201 ####################### 23
bar n = 101  10201 to  10404 ###################### 22
bar n = 102  10404 to  10609 #################### 20
bar n = 103  10609 to  10816 ##################### 21
bar n = 104  10816 to  11025 ##################### 21
Legendre n = 1 to 999 counted directly: True; largest gap below 10^6: 114 after 492,113
gap argument: n >= 56 needs a gap >= 115, none below 10^6; n = 1 to 55 by trial division: True
at n = 100 a failure needs a gap of at least 203
quoted gap record 1476 below 4e18: n >= 737 safe up to n + 1 = 2,000,000,000
0.525 window equals 2 sqrt x at x = 2^40 = 1,099,511,627,776
Ingham 1937: exponent 5/8 = 0.625 < 2/3 = 0.667, enough for cubes; squares need 1/2 = 0.500
quoted record, by year published: Goldbach checked to 4e18 (2014); bounded gaps 70000000 (2014), 600 (2015), 246 (2014)
Bertrand, between 100 and 200: 21 primes
Oppermann at n = 100: 11 below 10100, 12 above; both halves hold for n = 2 to 999: True
boundary cases: primes between 1 and 2: 0; whole numbers between 0 and 1: 0
10000 = p + q with p <= q: 127 ways by sieve, 127 by division; smallest 59 + 9941
Goldbach for every even m from 4 to 1,000,000: yes; hardest m = 503,222 needs p = 523
twin pairs inside 10000 to 10201: (10007, 10009), (10037, 10039), (10067, 10069), (10091, 10093), (10139, 10141); by division 5
twin pairs below 10^6: 8,169
100^2 + 1 = 10001 = 73 x 137; remainders on division by 4: 1, 1
n^2 + 1 prime for n = 1 to 1000: 112 by sieve, 112 by division; last 986
n^2 - 1 = (n - 1)(n + 1) prime for n = 1 to 1000: 1, at n = 2
largest prime factor of 10001: 137; 100^1.279 = 361
ALL CHECKS PASS
```

### Rust

```rust
// Landau's four problems, the status card -- the same check as landau_problems_check.py,
// in Rust.  No crates.  One sieve of Eratosthenes to 1,000,003 gives the counts; trial
// division, the gap argument and an algebraic identity reach each count a second way.
fn by_division(n: usize) -> bool {                // road two: trial division
    let mut d = 2;
    while d * d <= n && n % d != 0 { d += 1; }
    n > 1 && d * d > n
}
fn factor(mut n: usize) -> Vec<usize> {
    let (mut out, mut d) = (vec![], 2);
    while d * d <= n {
        while n % d == 0 { out.push(d); n /= d; }
        d += 1;
    }
    if n > 1 { out.push(n); }
    out
}
fn commas(n: u64) -> String {
    let s = n.to_string();
    let mut out = String::new();
    for (i, c) in s.chars().enumerate() {
        if i > 0 && (s.len() - i) % 3 == 0 { out.push(','); }
        out.push(c);
    }
    out
}
fn tf(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn main() {
    const X: usize = 1_000_003;                   // the first prime past 10^6
    let mut flag = vec![true; X + 1];
    flag[0] = false; flag[1] = false;
    for p in 2..1001 {
        if flag[p] { let mut k = p * p; while k <= X { flag[k] = false; k += p; } }
    }
    let primes: Vec<usize> = (2..=X).filter(|&p| flag[p]).collect();
    let between = |a: usize, b: usize| -> Vec<usize> { (a + 1..b).filter(|&m| flag[m]).collect() };
    // The example: Legendre at n = 100, between 10,000 and 10,201
    let inside = between(10000, 10201);
    println!("primes between 10000 and 10201: {}; first {}, last {}", inside.len(), inside[0], inside[inside.len() - 1]);
    for m in (10001..10007).step_by(2) {
        let f: Vec<String> = factor(m).iter().map(|x| x.to_string()).collect();
        println!("{} = {}", m, f.join(" x "));
    }
    let small: Vec<usize> = primes.iter().cloned().filter(|&p| p < 101).collect();
    let rems: Vec<usize> = small.iter().map(|&p| 10007 % p).collect();
    println!("10007 by the {} primes up to 97: smallest remainder {}; 101 x 101 = {}", small.len(), rems.iter().min().unwrap(), 101 * 101);
    let expect: f64 = (10001..10201).map(|m| 1.0 / (m as f64).ln()).sum();
    println!("expected count, sum of 1/log m from 10001 to 10200: {:.1}", expect);
    for n in 96..105usize {
        let c = between(n * n, (n + 1) * (n + 1)).len();
        println!("bar n = {:>3} {:>6} to {:>6} {} {}", n, n * n, (n + 1) * (n + 1), "#".repeat(c), c);
    }
    // Legendre for n = 1 to 999: road one counts directly, road two is the gap argument
    let direct = (1..1000).all(|n| !between(n * n, (n + 1) * (n + 1)).is_empty());
    let gap = primes.windows(2).filter(|w| w[0] < 1_000_000).map(|w| (w[1] - w[0], w[0])).max().unwrap();
    let start = (gap.0 - 3) / 2 + 1;              // a failure at n needs a gap >= 2n + 3
    let hold = (1..start).all(|n| (n * n + 1..(n + 1) * (n + 1)).any(by_division));
    println!("Legendre n = 1 to 999 counted directly: {}; largest gap below 10^6: {} after {}", tf(direct), gap.0, commas(gap.1 as u64));
    println!("gap argument: n >= {} needs a gap >= {}, none below 10^6; n = 1 to {} by trial division: {}", start, 2 * start + 3, start - 1, tf(hold));
    println!("at n = 100 a failure needs a gap of at least {}", 2 * 100 + 3);
    println!("quoted gap record 1476 below 4e18: n >= {} safe up to n + 1 = {}", (1476 - 3) / 2 + 1, commas((4e18f64).sqrt() as u64));
    println!("0.525 window equals 2 sqrt x at x = 2^40 = {}", commas(1u64 << 40));
    println!("Ingham 1937: exponent 5/8 = {:.3} < 2/3 = {:.3}, enough for cubes; squares need 1/2 = {:.3}", 5.0 / 8.0, 2.0 / 3.0, 1.0 / 2.0);
    println!("quoted record, by year published: Goldbach checked to 4e18 (2014); bounded gaps 70000000 (2014), 600 (2015), 246 (2014)");
    // What Legendre does not say: Bertrand (proved) and Oppermann (stronger, open)
    println!("Bertrand, between 100 and 200: {} primes", between(100, 200).len());
    let (lo, hi) = (between(10000, 10100), between(10100, 10201));
    let opp = (2..1000).all(|n| !between(n * n, n * n + n).is_empty() && !between(n * n + n, (n + 1) * (n + 1)).is_empty());
    println!("Oppermann at n = 100: {} below 10100, {} above; both halves hold for n = 2 to 999: {}", lo.len(), hi.len(), tf(opp));
    println!("boundary cases: primes between 1 and 2: {}; whole numbers between 0 and 1: {}", between(1, 2).len(), (1..1).count());
    // Goldbach: 10,000 as p + q, two roads; every even m from 4 to 10^6
    let pairs: Vec<usize> = primes.iter().cloned().filter(|&p| p <= 5000 && flag[10000 - p]).collect();
    let pairs2: Vec<usize> = (2..5001).filter(|&p| by_division(p) && by_division(10000 - p)).collect();
    let worst = (4..=1_000_000).step_by(2).map(|m: usize| (*primes.iter().find(|&&p| flag[m - p]).unwrap(), m)).max().unwrap();
    println!("10000 = p + q with p <= q: {} ways by sieve, {} by division; smallest {} + {}", pairs.len(), pairs2.len(), pairs[0], 10000 - pairs[0]);
    println!("Goldbach for every even m from 4 to 1,000,000: yes; hardest m = {} needs p = {}", commas(worst.1 as u64), worst.0);
    // Twin primes in the example interval, and below 10^6
    let tw: Vec<usize> = inside.iter().cloned().filter(|&p| flag[p + 2] && p + 2 < 10201).collect();
    let tw2: Vec<usize> = (10001..10199).step_by(2).filter(|&p| by_division(p) && by_division(p + 2)).collect();
    let twins = primes.iter().filter(|&&p| p + 2 < 1_000_000 && flag[p + 2]).count();
    let shown: Vec<String> = tw.iter().map(|p| format!("({}, {})", p, p + 2)).collect();
    println!("twin pairs inside 10000 to 10201: {}; by division {}", shown.join(", "), tw2.len());
    println!("twin pairs below 10^6: {}", commas(twins as u64));
    // n^2 + 1: the example's first number is 100^2 + 1
    let f1 = factor(10001);
    let hits: Vec<usize> = (1..1001).filter(|&n| flag[n * n + 1]).collect();
    let hits2: Vec<usize> = (1..1001).filter(|&n| by_division(n * n + 1)).collect();
    println!("100^2 + 1 = 10001 = {} x {}; remainders on division by 4: {}, {}", f1[0], f1[1], f1[0] % 4, f1[1] % 4);
    println!("n^2 + 1 prime for n = 1 to 1000: {} by sieve, {} by division; last {}", hits.len(), hits2.len(), hits[hits.len() - 1]);
    let sq: Vec<usize> = (1..1001).filter(|&n| flag[n * n - 1]).collect();
    println!("n^2 - 1 = (n - 1)(n + 1) prime for n = 1 to 1000: {}, at n = {}", sq.len(), sq[0]);
    println!("largest prime factor of 10001: {}; 100^1.279 = {:.0}", f1.iter().max().unwrap(), 100f64.powf(1.279));
    assert!(inside[0] == 10007 && inside.iter().all(|&m| by_division(m)) && !(10001..10007).any(by_division));
    assert!(inside.len() == (10001..10201).filter(|&m| by_division(m)).count() && !rems.contains(&0));
    assert!(direct && hold && gap == (114, 492113) && opp && between(1, 2).is_empty());
    assert!(2 * start + 1 <= gap.0 && gap.0 < 2 * start + 3);   // start is the first n the gap table clears
    assert!(pairs == pairs2 && worst == (523, 503222) && twins == 8169);
    assert!(tw == tw2 && tw[0] == 10007 && tw.len() == 5);
    assert!(hits == hits2 && hits.len() == 112 && sq == vec![2] && f1 == vec![73, 137]);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-23 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
primes between 10000 and 10201: 23; first 10007, last 10193
10001 = 73 x 137
10003 = 7 x 1429
10005 = 3 x 5 x 23 x 29
10007 by the 25 primes up to 97: smallest remainder 1; 101 x 101 = 10201
expected count, sum of 1/log m from 10001 to 10200: 21.7
bar n =  96   9216 to   9409 ##################### 21
bar n =  97   9409 to   9604 ###################### 22
bar n =  98   9604 to   9801 ####################### 23
bar n =  99   9801 to  10000 ##################### 21
bar n = 100  10000 to  10201 ####################### 23
bar n = 101  10201 to  10404 ###################### 22
bar n = 102  10404 to  10609 #################### 20
bar n = 103  10609 to  10816 ##################### 21
bar n = 104  10816 to  11025 ##################### 21
Legendre n = 1 to 999 counted directly: True; largest gap below 10^6: 114 after 492,113
gap argument: n >= 56 needs a gap >= 115, none below 10^6; n = 1 to 55 by trial division: True
at n = 100 a failure needs a gap of at least 203
quoted gap record 1476 below 4e18: n >= 737 safe up to n + 1 = 2,000,000,000
0.525 window equals 2 sqrt x at x = 2^40 = 1,099,511,627,776
Ingham 1937: exponent 5/8 = 0.625 < 2/3 = 0.667, enough for cubes; squares need 1/2 = 0.500
quoted record, by year published: Goldbach checked to 4e18 (2014); bounded gaps 70000000 (2014), 600 (2015), 246 (2014)
Bertrand, between 100 and 200: 21 primes
Oppermann at n = 100: 11 below 10100, 12 above; both halves hold for n = 2 to 999: True
boundary cases: primes between 1 and 2: 0; whole numbers between 0 and 1: 0
10000 = p + q with p <= q: 127 ways by sieve, 127 by division; smallest 59 + 9941
Goldbach for every even m from 4 to 1,000,000: yes; hardest m = 503,222 needs p = 523
twin pairs inside 10000 to 10201: (10007, 10009), (10037, 10039), (10067, 10069), (10091, 10093), (10139, 10141); by division 5
twin pairs below 10^6: 8,169
100^2 + 1 = 10001 = 73 x 137; remainders on division by 4: 1, 1
n^2 + 1 prime for n = 1 to 1000: 112 by sieve, 112 by division; last 986
n^2 - 1 = (n - 1)(n + 1) prime for n = 1 to 1000: 1, at n = 2
largest prime factor of 10001: 137; 100^1.279 = 361
ALL CHECKS PASS
```

### Lean

Lean proves the gap argument and two facts about squares for every whole number, and checks the worked numbers.

- Lean writes out the four problems exactly as in the formula. It proves none of them: all four stay open.
- Suppose no prime lies strictly between n² and (n + 1)², with n at least 1. Then the primes on either side are at least 2n + 3 apart.
- Suppose an odd prime divides some n² + 1. Then it leaves remainder 1 on division by 4.
- Take any whole number n. Then n² − 1 is prime exactly when n = 2.
- 10,007 is a prime between 10,000 and 10,201, and 10,001, 10,003 and 10,005 are not prime.
- 10,001 = 73 × 137, both factors prime, and each leaves remainder 1 on division by 4.
- 10,000 = 59 + 9,941, two primes. The five twin pairs between 10,000 and 10,201 are all prime.
- 492,113 and 492,227 are both prime, and they are 114 apart.
- Take the record gap 1,476. Then 2n + 3 is larger than it exactly from n = 737 up.
- 2,000,000,000² = 4 × 10^18, and 2^40 = 1,099,511,627,776.
- 11 − 2 = 9 is not prime, so 11 is not 2 plus a prime.

The sieve counts up to 10^6 and the expected count 21.7 are left to the Python and Rust checks.

```lean
-- Landau's four problems: the four problems stated exactly (open, not proved here), the gap argument that turns a prime-gap table into a Legendre check, two facts about n^2 + 1 and n^2 - 1, and the card's whole-number examples.
import Mathlib.Data.Nat.Prime.Basic
import Mathlib.Data.Set.Finite.Basic
import Mathlib.Algebra.Order.Group.Nat
import Mathlib.Tactic.NormNum.Prime
import Mathlib.NumberTheory.LegendreSymbol.Basic
import Mathlib.Data.Nat.Find

/-- Landau's problem 1 (open as of 2026-11-23; the card does not prove it):
n^2 + 1 is prime for infinitely many whole numbers n. -/
def LandauSquarePlusOne : Prop :=
  {n : ℕ | (n ^ 2 + 1).Prime}.Infinite

/-- Landau's problem 2, Goldbach (open as of 2026-11-23): every even m ≥ 4 is p + q
with p and q prime. -/
def LandauGoldbach : Prop :=
  ∀ m : ℕ, Even m → 4 ≤ m → ∃ p q : ℕ, p.Prime ∧ q.Prime ∧ m = p + q

/-- Landau's problem 3, twin primes (open as of 2026-11-23): there are infinitely many
primes p with p + 2 also prime, so the twin-pair count π₂(x) grows without bound. -/
def LandauTwinPrimes : Prop :=
  {p : ℕ | p.Prime ∧ (p + 2).Prime}.Infinite

/-- Landau's problem 4, Legendre (open as of 2026-11-23): for every whole number n ≥ 1
there is a prime strictly between n^2 and (n + 1)^2. -/
def LandauLegendre : Prop :=
  ∀ n : ℕ, 1 ≤ n → ∃ p : ℕ, p.Prime ∧ n ^ 2 < p ∧ p < (n + 1) ^ 2

/-- The gap argument behind the Legendre check: for n ≥ 1, if no prime lies strictly
between n^2 and (n + 1)^2, then two consecutive primes p < q (no prime between them)
straddle the interval, p below n^2 and q above (n + 1)^2, and they are at least
2n + 3 apart. So a table of prime gaps all smaller than 2n + 3 proves Legendre at n. -/
theorem legendre_failure_forces_gap (n : ℕ) (hn : 1 ≤ n)
    (hnone : ∀ m : ℕ, n ^ 2 < m → m < (n + 1) ^ 2 → ¬ m.Prime) :
    ∃ p q : ℕ, p.Prime ∧ q.Prime ∧ p < n ^ 2 ∧ (n + 1) ^ 2 < q ∧
      (∀ m : ℕ, p < m → m < q → ¬ m.Prime) ∧ 2 * n + 3 ≤ q - p := by
  by_cases h1 : n = 1
  · subst h1
    exact absurd Nat.prime_two (hnone 2 (by norm_num) (by norm_num))
  have hn2 : 2 ≤ n := by omega
  have hsq : 4 ≤ n ^ 2 := by nlinarith
  have hnp : ¬ (n ^ 2).Prime := by
    rw [pow_two]; exact Nat.not_prime_mul (by omega) (by omega)
  have hnp' : ¬ ((n + 1) ^ 2).Prime := by
    rw [pow_two]; exact Nat.not_prime_mul (by omega) (by omega)
  -- p: the largest prime at most n^2
  set p := Nat.findGreatest Nat.Prime (n ^ 2) with hpdef
  have hpP : p.Prime := Nat.findGreatest_spec (P := Nat.Prime) (by omega : 2 ≤ n ^ 2) Nat.prime_two
  have hple : p ≤ n ^ 2 := Nat.findGreatest_le _
  have hplt : p < n ^ 2 := lt_of_le_of_ne hple (fun h => hnp (h ▸ hpP))
  -- q: the smallest prime above n^2
  have hex : ∃ q, n ^ 2 < q ∧ q.Prime := by
    obtain ⟨q, hq1, hq2⟩ := Nat.exists_infinite_primes (n ^ 2 + 1)
    exact ⟨q, by omega, hq2⟩
  classical
  let q := Nat.find hex
  have hq : n ^ 2 < q ∧ q.Prime := Nat.find_spec hex
  have hqmin : ∀ m, m < q → ¬ (n ^ 2 < m ∧ m.Prime) := fun m hm => Nat.find_min hex hm
  have hqgt : (n + 1) ^ 2 < q := by
    by_contra hc
    push Not at hc
    rcases lt_or_eq_of_le hc with hc | hc
    · exact hnone q hq.1 hc hq.2
    · exact hnp' (hc ▸ hq.2)
  refine ⟨p, q, hpP, hq.2, hplt, hqgt, ?_, ?_⟩
  · intro m hpm hmq hm
    by_cases hmn : m ≤ n ^ 2
    · exact Nat.findGreatest_is_greatest (P := Nat.Prime) hpm hmn hm
    · exact hqmin m hmq ⟨by omega, hm⟩
  · have : (n + 1) ^ 2 = n ^ 2 + 2 * n + 1 := by ring
    omega

/-- An odd prime divides some n^2 + 1 only if it leaves remainder 1 on division by 4. -/
theorem odd_prime_dvd_sq_add_one_mod_four (p n : ℕ) (hp : p.Prime) (hodd : p ≠ 2)
    (hdvd : p ∣ n ^ 2 + 1) : p % 4 = 1 := by
  have := Fact.mk hp
  have h0 : ((n : ZMod p)) ^ 2 = -1 := by
    have : ((n ^ 2 + 1 : ℕ) : ZMod p) = 0 := (ZMod.natCast_eq_zero_iff _ _).2 hdvd
    push_cast at this
    exact eq_neg_of_add_eq_zero_left this
  have h3 := ZMod.mod_four_ne_three_of_sq_eq_neg_one h0
  have hodd' : p % 2 = 1 := hp.eq_two_or_odd.resolve_left hodd
  omega

/-- n^2 - 1 = (n - 1)(n + 1) has a forced factor, so it is prime only at n = 2. -/
theorem sq_sub_one_prime_iff (n : ℕ) : (n ^ 2 - 1).Prime ↔ n = 2 := by
  have hfac : n ^ 2 - 1 = (n + 1) * (n - 1) := by
    have := Nat.sq_sub_sq n 1
    simpa using this
  constructor
  · intro h
    rw [hfac, Nat.prime_mul_iff] at h
    rcases h with ⟨_, h⟩ | ⟨hpr, h⟩
    · omega
    · have h0 : n = 0 := by omega
      subst h0
      exact absurd hpr (by norm_num)
  · rintro rfl
    norm_num

-- The example: 100^2 = 10,000 and 101^2 = 10,201, and 10,007 is a prime between them.
example : 100 ^ 2 = 10000 ∧ 101 ^ 2 = 10201 ∧ Nat.Prime 10007 ∧ 10000 < 10007 ∧ 10007 < 10201 := by
  norm_num
-- Legendre holds at n = 100.
example : ∃ p : ℕ, p.Prime ∧ 100 ^ 2 < p ∧ p < (100 + 1) ^ 2 := by
  refine ⟨10007, ?_, ?_, ?_⟩ <;> norm_num
-- The odd numbers before 10,007 in the interval are not prime.
example : 10001 = 73 * 137 ∧ 10003 = 7 * 1429 ∧ 10005 = 3 * 5 * 23 * 29 ∧
    ¬ Nat.Prime 10001 ∧ ¬ Nat.Prime 10003 ∧ ¬ Nat.Prime 10005 := by
  norm_num
-- 10,007 checked by the primes up to 97: 97 < 101 and 101 * 101 = 10,201 > 10,007.
example : 101 * 101 = 10201 ∧ 10007 < 101 * 101 ∧ 10007 % 97 ≠ 0 := by norm_num
-- 100^2 + 1 = 10,001 = 73 * 137, both factors prime and leaving remainder 1 on division by 4.
example : 100 ^ 2 + 1 = 73 * 137 ∧ Nat.Prime 73 ∧ Nat.Prime 137 ∧ 73 % 4 = 1 ∧ 137 % 4 = 1 := by
  norm_num
-- Goldbach: 10,000 = 59 + 9,941, both prime.
example : 10000 = 59 + 9941 ∧ Nat.Prime 59 ∧ Nat.Prime 9941 := by norm_num
-- The five twin pairs between 10,000 and 10,201.
example : Nat.Prime 10007 ∧ Nat.Prime 10009 ∧ Nat.Prime 10037 ∧ Nat.Prime 10039 ∧
    Nat.Prime 10067 ∧ Nat.Prime 10069 ∧ Nat.Prime 10091 ∧ Nat.Prime 10093 ∧
    Nat.Prime 10139 ∧ Nat.Prime 10141 := by
  norm_num
-- Boundary of Goldbach: 11 is odd and 11 - 2 = 9 is not prime.
example : 11 - 2 = 9 ∧ ¬ Nat.Prime 9 := by norm_num
-- At n = 100 a Legendre failure needs a gap of at least 203.
example : 2 * 100 + 3 = 203 := by norm_num
-- The largest gap below 10^6: 114, from the prime 492,113 to the prime 492,227.
example : Nat.Prime 492113 ∧ Nat.Prime 492227 ∧ 492227 - 492113 = 114 := by norm_num
-- The 2014 record gap 1,476 clears every n from 737 up; the check ends at
-- (n + 1)^2 = 2,000,000,000^2 = 4 * 10^18.
example : (1476 - 3) / 2 + 1 = 737 ∧ 2 * 737 + 3 > 1476 ∧ 2 * 736 + 3 ≤ 1476 ∧
    2000000000 ^ 2 = 4 * 10 ^ 18 := by
  norm_num
-- 2^40 = 1,099,511,627,776.
example : 2 ^ 40 = 1099511627776 := by norm_num
-- n^2 - 1 is prime at n = 2 (it is 3) and not at n = 3 (it is 8 = 2 * 4).
example : Nat.Prime (2 ^ 2 - 1) ∧ ¬ Nat.Prime (3 ^ 2 - 1) := by norm_num

#print axioms legendre_failure_forces_gap
#print axioms odd_prime_dvd_sq_add_one_mod_four
#print axioms sq_sub_one_prime_iff
```

**Checked 2026-11-23 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'legendre_failure_forces_gap' depends on axioms: [propext, Classical.choice, Quot.sound]
'odd_prime_dvd_sq_add_one_mod_four' depends on axioms: [propext, Classical.choice, Quot.sound]
'sq_sub_one_prime_iff' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> - Guess first: of the nine intervals from n = 96 to n = 104, which holds the fewest primes? Read the bars: n = 102, with 20.
> - Guess first: does the interval just below the example, 9,801 to 10,000 at n = 99, hold more or fewer primes than n = 100? Fewer: 21 against 23.
> - Guess first: how many values n² − 1 are prime for n from 1 to 1,000? Change `n * n + 1` to `n * n - 1`. The answer is 1, at n = 2.
> - Guess first: if Legendre failed at n = 100, how wide a prime gap would that need near 10,000? At least 2 × 100 + 3 = 203. The largest gap below 10^6 is 114.

---

## The usual mistake

> [!warning]
> **Reading a nearby theorem as the Landau problem.** Bertrand (1852), Ingham's cubes (1937), Chen (1973), Iwaniec (1978), Baker, Harman and Pintz (2001), the ternary Goldbach preprint (2013) and bounded gaps (2014) are each about a weaker or a different statement. None settles any of the four. Each Landau problem is open as of 2026-11-23.
>
> - **"Checked to 4 × 10^18" read as "true".** A check refutes nothing it did not test. Goldbach's hardest case to 10^6, m = 503,222, needs p = 523; nothing says the pattern survives beyond the checked range.
> - **Bertrand read as Legendre.** 21 primes between 100 and 200 say nothing about the 200 numbers after 10,000.
> - **An "infinitely many" theorem read as "every".** Merikoski's exponent 1.279 holds for infinitely many n; at n = 100 the largest prime factor of 10,001 is 137, below 100^1.279 ≈ 361.
> - **A count of twin pairs read as a check.** 8,169 pairs below 10^6 cannot refute or prove "infinitely many".

---

## Where you meet it in real life

- **Prime gap tables.** Searches that list every record gap up to 4 × 10^18 double as checks of Legendre, through the argument of Step 2.
- **Goldbach verification.** The same 2014 computation checked every even number to 4 × 10^18. Any future extension will be reported as a new "checked to" bound, never as a proof.
- **Status claims in the press.** Results such as bounded gaps are often headlined as "twin primes solved". A dated status record like the one in Step 3 is how to check such a claim.

> **Say it back**
> In 1912 Landau named four questions about primes: n² + 1 prime infinitely often, Goldbach, twin primes, and a prime between neighbouring squares. All four are open as of 2026-11-23. Goldbach and Legendre are "for every" claims, checked to 4 × 10^18 and to n = 1,999,999,999; twin primes and n² + 1 are "infinitely many" claims, which no finite search can settle. Between 10,000 and 10,201 lie 23 primes, the first 10,007, which also starts a twin pair. Every nearby theorem, from Bertrand's to bounded gaps, proves a weaker or a different statement.

---

## What this builds on

- [Landau's four problems](../../21-Algebraic%20and%20analytic%20number%20theory/04-Sieves%20and%20Prime%20Gaps/08-landau-problems-and-legendre.md): the four statements, the sieve results for each, the parity problem (a sieve cannot tell a number with an odd count of prime factors from one with an even count) that stops sieves, and the gap argument used in Step 2.
- [Goldbach](../../21-Algebraic%20and%20analytic%20number%20theory/04-Sieves%20and%20Prime%20Gaps/07-goldbach-and-chens-theorem.md): Chen's 1973 theorem with its source, the nearest proved result to Goldbach.
- [Bounded gaps](../../21-Algebraic%20and%20analytic%20number%20theory/04-Sieves%20and%20Prime%20Gaps/05-bounded-gaps-zhang-maynard.md): the gaps 70,000,000, 600 and 246, with their sources.

## Where this goes next

- [Twin primes](01-twin-primes-and-bounded-gaps.md): the full status record for Landau's third problem, with the Hardy-Littlewood prediction for π₂(x): a formula for how fast the twin count grows.
- [Goldbach](02-goldbach-conjecture.md): the full status record for Landau's second problem, and the Goldbach count r(n), the number of ways to split n as two primes.
- [Large gaps](../../21-Algebraic%20and%20analytic%20number%20theory/04-Sieves%20and%20Prime%20Gaps/06-large-gaps-and-the-cramer-model.md): how wide prime gaps can be, the quantity that decides how far Legendre can be checked.
- [The abc conjecture](04-abc-conjecture.md): the shelf's next problem, about sums rather than primes, where the status itself is disputed.
- [Schanuel's conjecture](08-schanuels-conjecture.md): one statement that would settle almost every open question about transcendental numbers.

The question this card leaves open: which problem falls first, and will it be by a sieve that gets past the parity problem or by a sharper bound on prime gaps?

---

## Sources

Verified 2026-11-23: every link below resolves to the publisher's page.

- Landau, Edmund. "Gelöste und ungelöste Probleme aus der Theorie der Primzahlverteilung und der Riemannschen Zetafunktion." *Proceedings of the Fifth International Congress of Mathematicians*, Cambridge 1912, vol. 1, 93–108. [International Mathematical Union scan](https://www.mathunion.org/fileadmin/ICM/Proceedings/ICM1912.1/ICM1912.1.ocr.pdf). The four questions, on page 106, and Landau's own numbering.
- Oliveira e Silva, Tomás, Siegfried Herzog and Silvio Pardi. "Empirical verification of the even Goldbach conjecture and computation of prime gaps up to 4·10<sup>18</sup>." *Mathematics of Computation* 83 (2014), 2033–2060. [doi:10.1090/S0025-5718-2013-02787-1](https://doi.org/10.1090/S0025-5718-2013-02787-1). Goldbach checked to 4 × 10^18, and the gap table whose record, 1,476, checks Legendre.
- Ingham, A. E. "On the difference between consecutive primes." *Quarterly Journal of Mathematics* os-8 (1937), 255–266. [doi:10.1093/qmath/os-8.1.255](https://doi.org/10.1093/qmath/os-8.1.255). Prime gaps near x below x^(5/8+ε) for every ε > 0, enough for a prime between neighbouring cubes.
- Friedlander, John, and Henryk Iwaniec. "The polynomial X² + Y⁴ captures its primes." *Annals of Mathematics* 148 (1998), 945–1040. [doi:10.2307/121034](https://doi.org/10.2307/121034). Infinitely many primes of the form a² + b⁴.
- Merikoski, Jori. "On the largest prime factor of n² + 1." *Journal of the European Mathematical Society* 25 (2023), 1253–1284. [doi:10.4171/JEMS/1216](https://doi.org/10.4171/JEMS/1216). The largest prime factor of n² + 1 exceeds n^1.279 for infinitely many n.
