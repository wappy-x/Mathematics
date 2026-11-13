# Random numbers from a computer: linear congruential and Mersenne generators, seeds and tests

[Syllabus](../../../SYLLABUS.md) → [Probability and statistics](../README.md) → [Simulation](../README.md#s11) → Random numbers from a computer

---

## General Overview

A simulation throws 100,000 darts at a square one unit on a side. A dart counts as a hit when it lands within one unit of the bottom-left corner, inside a quarter circle. The quarter circle covers π/4 of the square, so four times the share of hits estimates π.

On Monday the program, started from the number 20260929, prints 3.13856, give or take a standard error of 0.00520. The standard error is the typical size of the luck in a run of this length. On Friday the same program, started from the same number, prints 3.13856 again, to every digit. Started from 20260930 it prints 3.14304. Both runs sit within one standard error of π = 3.14159.

The darts were never random. A computer follows fixed rules, so every "random" number it hands out is computed from the one before. Think of a shuffled deck dealt from the top: the deal looks random, but the same shuffle gives the same deal every time.

The rule is a **pseudo-random number generator**, from here on a **generator**. The dart program uses **MT19937**, the Mersenne Twister, built into Python and R; Step 5 opens it up.

The number it starts from, 20260929 on Monday, is the **seed**. Same seed, same stream of numbers, same answer: that is what lets a bug be chased, a result be checked by someone else, and two designs be compared on identical luck.

Two questions decide whether a generator can be trusted. How long does its stream run before it repeats? And does the stream pass for uniform draws between 0 and 1 ([Uniform](../04-Continuous%20Distributions/02-uniform-distribution.md)) under tests designed to catch it out?

**A generator is a fixed rule applied over and over to a hidden number; the seed picks the starting number, so the same seed replays the same stream exactly, and a generator earns trust only through the length of its loop and the tests its output passes.**

**What kind of fact this is:** a method: a deterministic recipe that imitates uniform draws, never the real thing; the rule for when the simplest generators visit every value is a theorem, proved on this card in Why it works.

### The picture: a 16-state generator goes round once, then repeats

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Outputs of x to (5x + 3) mod 16, seed 7"
    x-axis "Step number" [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]
    y-axis "Output (a whole number from 0 to 15)" 0 --> 16
    line [7, 6, 1, 8, 11, 10, 5, 12, 15, 14, 9, 0, 3, 2, 13, 4, 7]
```

The line: the seed 7 at step 0, then the generator's 16 outputs, printed by both checks. It hits every whole number from 0 to 15 exactly once with no visible plan, and at step 16 is back at 7, to repeat forever. Real generators do the same with far more states.

---

## The formula

Notation first. The **mod** operation gives the remainder after division: 38 mod 16 is 6, since 38 = 2 × 16 + 6. The three-bar sign ≡ reads "leaves the same remainder as" ([Congruence](../../02-Number%20theory/03-Clock%20Arithmetic/01-congruence-mod-n.md)). A subscript counts steps: $x_n$ is the generator's state after $n$ steps, and $x_0$ is the seed.

The simplest family, the **linear congruential generator** (LCG: multiply, add, keep the remainder), is one line:

$$x_{n+1} = (a\,x_n + c) \bmod m, \qquad u_n = \frac{x_n}{m}$$

**Read it aloud:** multiply the current number by $a$, add $c$, keep the remainder after dividing by $m$; that remainder is the next number, and dividing it by $m$ gives a draw between 0 and 1.

The example above is $a = 5$, $c = 3$, $m = 16$, seed 7: $5 \times 7 + 3 = 38$, and 38 mod 16 is 6, so $x_1 = 6$ and $u_1 = 6/16 = 0.3750$.

The state can take only $m$ values, so the stream must repeat. The **full-cycle rule** (Hull and Dobell, 1962) says when the loop is as long as possible. For $m$ a power of 2, as in most software:

$$\text{loop length} = m \iff c \text{ is odd and } a \equiv 1 \pmod 4$$

**Read it aloud:** the generator visits all $m$ states before repeating exactly when the added number is odd and the multiplier leaves remainder 1 on division by 4. For other $m$ the rule reads: $c$ shares no factor with $m$, $a - 1$ is divisible by every prime that divides $m$, and by 4 if 4 divides $m$.

Uniformity is tested by sorting $N$ draws into $k$ equal bins and adding up the squared surprises ([Chi-square tests](../08-Confidence%20Intervals%20and%20Tests/06-chi-square-tests.md)):

$$\chi^2 = \sum_{j=1}^{k} \frac{(O_j - E_j)^2}{E_j}$$

**Read it aloud:** in each bin, square the gap between the count seen and the count expected, divide by the count expected, and add over the bins.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $x_n$, $n$ | the state after $n$ steps, a whole number from 0 to $m - 1$ | $x_1 = 6$ | — |
| $x$, $y$ | in the figure: one output and the output after it | 7 and 6 | — |
| $x_0$ | the seed: the starting state | 7 (darts: 20260929) | a different stream, same quality |
| $a$ | the multiplier | 5 | stirs harder; quality depends on its digits, not its size |
| $c$ | the increment, added each step | 3 | odd (with $a \equiv 1 \pmod 4$) gives the full loop; even gives at most half |
| $m$ | the modulus: how many states there are | 16 (minstd, Step 1: 2^31 − 1) | longer possible loop |
| $u_n$ | the draw between 0 and 1, $x_n / m$ | $u_1 = 0.3750$ | — |
| $S(n)$ | in the proof: $1 + a + a^2 + \dots + a^{n-1}$ | adds $n$ powers of 5 | — |
| $N$ | number of draws tested | 10,000 | real flaws show up more clearly |
| $k$ | number of equal bins | 10 | finer test, fewer draws per bin |
| $O_j$, $E_j$, $j$ | draws seen, and expected, in bin number $j$ | 1031 and 1000 | — |
| $\chi^2$ | chi-square: the total squared surprise | 18.29 (MT19937) | above 16.919 fails at 5% |

### When it holds

- **The arithmetic is exact.** A multiply that silently drops its top bits is a different generator with a different loop.
- **The draws are taken in the same order.** One extra draw early in the program, or threads that take turns in no fixed order, shift every later number, and the replay is lost.
- **For the full-cycle rule as stated, $m$ is a power of 2.** If $c$ is even the loop is at most half as long: $(5x + 2) \bmod 16$ loops after 8.
- **For the tests, the draws are compared with a known law.** A test finds only the pattern it looks for: a generator can pass the bin test and still fail badly on triples, as RANDU does below.

---

## Why it works

### Step 0: a machine with finitely many states must loop

Only $m$ states are possible, so within $m + 1$ steps some state comes back, and from there the stream repeats. A designer controls only how long the loop is and how patternless the path round it looks. Randomness, here, is a standard the output must meet under testing, not a property of the rule.

### Step 1: the same seed replays the same stream, and any stretch can be reached directly

The rule's only input is the current state, so the same seed gives the same stream: 3.13856 twice. A different seed starts somewhere else on the loop: 3.14304. The two differ by 0.00448, less than one standard error, which is the size of luck at 100,000 darts ([Monte Carlo](04-monte-carlo-estimates-and-error.md)).

Determinism also allows jumping ahead. The generator Park and Miller called the minimal standard, **minstd**, has $c = 0$, $a = 16807$ and $m = 2^{31} - 1$. With no increment, $n$ steps multiply the seed by $a$ exactly $n$ times, so $x_n = a^n x_0 \bmod m$. Repeated squaring computes $a^{10000}$ with a handful of squarings instead of 10,000 steps. From seed 1, stepping and jumping both land on 1043618065: the value Park and Miller published as the test that an implementation is correct. Jumping is how parallel workers get separate stretches of one stream.

### Step 2: when the loop visits every state

For $m$ a power of 2 the full-cycle rule has a short proof, by counting factors of 2. The shape:

1. When $a$ is odd, each state has exactly one state before it, so the states fall into separate loops. Full cycle means the loop through 0 has length $m$.
2. From 0, the state after $n$ steps is $c \times S(n) \bmod m$, where $S(n) = 1 + a + \dots + a^{n-1}$.
3. With $c$ odd, that state is 0 exactly when $m$ divides $S(n)$.
4. With $a \equiv 1 \pmod 4$, $S(n)$ carries exactly as many factors of 2 as $n$ does. So $S(n)$ first becomes divisible by $m$ at $n = m$.

Each condition is needed: the folded proof shows how the loop shortens when one fails.

The checks test the rule against brute force. For $m = 16$ they run every pair of $a$ and $c$ from 0 to 15 and find 32 with a full loop; the rule picks out the same 32 pairs. For $m = 64$: 512 pairs both ways.

<details>
<summary>Detailed proof: the full-cycle rule for m a power of 2, at least 4</summary>

**Loops.** If $a$ is odd it has an inverse on the $m$-clock, so $x \mapsto (ax + c) \bmod m$ can be undone: no two states share a successor. Following successors from any state must then return to it, so the states split into separate loops. The generator has a full cycle exactly when the loop through 0 has length $m$.

**The state after n steps.** Start at 0. Then $x_1 = c = c\,S(1)$. If $x_n = c\,S(n)$, then $x_{n+1} = a\,c\,S(n) + c = c\,(a\,S(n) + 1) = c\,S(n+1)$, all mod $m$. With $c$ odd, $c$ has an inverse, so $x_n = 0$ exactly when $m$ divides $S(n)$.

**Counting factors of 2 (for a ≡ 1 mod 4).** If $n$ is odd, $S(n)$ adds $n$ odd numbers and is odd: no factor of 2, like $n$. If $n$ is even, pair the terms: $S(n) = (1 + a)(1 + a^2 + a^4 + \dots + a^{n-2})$. The first factor is 2 more than a multiple of 4, so it carries exactly one factor of 2. The second is $S$ built from $a^2$ over $n/2$ terms, and $a^2 \equiv 1 \pmod 4$ too. By induction on $n$ it carries as many factors of 2 as $n/2$. Together: as many as $n$. Since $m$ is a power of 2, $m$ divides $S(n)$ exactly when $m$ divides $n$; the first such $n$ is $m$, and the loop through 0 has length $m$.

**Necessity.** If $c$ is even and $a$ odd, $ax + c$ has the parity of $x$, so a stream never changes parity and misses half the states. If $a$ is even, every state after the first has the parity of $c$. If $a \equiv 3 \pmod 4$, then $1 + a$ is a multiple of 4, so for even $n$ the pairing gives $S(n)$ at least one more factor of 2 than $n$; at $n = m/2$ that makes $m$ divide $S(n)$, and the loop through 0 closes by step $m/2$.

The toy generator has $a = 5 \equiv 1 \pmod 4$ and $c = 3$ odd: a full loop of 16, as the chart shows.

</details>

### Step 3: a full loop is not randomness

The rule guarantees coverage, not disorder. Take $a = 1$, $c = 1$: the loop is full, and the stream is 8, 9, 10, 11, 12, 13, a counter.

The toy generator hides two quieter patterns. Its last binary digit, or **bit**, runs 0, 1, 0, 1 for ever, because with $m$ a power of 2 the lowest bit is itself a generator with only two states. And its consecutive pairs line up. Plot each output $x$ against the next output $y$ and all 16 points fall on four parallel lines.

### The picture: consecutive outputs of the toy generator, as points (x, y)

<p align="center"><img src="../figures/pseudo-random-numbers.svg" alt="The 16 pairs of consecutive outputs of x to 5x + 3 mod 16, lying on four parallel lines x + 3y = 9, 25, 41, 57" width="420"></p>

Every point satisfies $x + 3y = 9$, 25, 41 or 57: the check lists the 16 pairs and finds exactly those four values. Drawn to scale, one unit to 12.5 drawing units on both axes. The reason is one line of algebra: $y \equiv 5x + 3 \pmod{16}$, and $3 \times 5 = 15 \equiv -1$, so $3y \equiv -x + 9$, which gives $x + 3y \equiv 9 \pmod{16}$. Every LCG does this. George Marsaglia showed in 1968 that consecutive draws of any LCG, taken in pairs, triples or longer runs, lie on a limited number of flat sheets. A good multiplier makes the sheets many and close together; a bad one makes them few.

The notorious bad one is **RANDU**, IBM's generator of the 1960s: $a = 65539$, $c = 0$, $m = 2^{31}$. Since $65539 = 2^{16} + 3$, squaring gives $a^2 \equiv 6a - 9 \pmod{2^{31}}$, so every output is fixed by the two before: $x_{n+2} \equiv 6x_{n+1} - 9x_n$. In the check, 9 times one output, minus 6 times the next, plus the one after, is a multiple of $2^{31}$ for all 10,000 triples of consecutive outputs. Those triples lie on just 15 planes in the unit cube. For MT19937 (its top 31 bits) the same combination is a multiple of $2^{31}$ in 0 of 10,000 triples.

### Step 4: testing uniformity with chi-square

A test asks one question: would honest uniform draws look this lumpy? Sort 10,000 draws into 10 equal bins, about 1000 expected in each.

For honest draws, the chi-square total follows the chi-square law with 9 **degrees of freedom** (the bin count less one, since the counts must add to 10,000) ([The reference distributions](../07-Sampling%20and%20Estimation/03-chi-square-t-and-f-distributions.md)). The match is close when each bin expects many draws.

Its p-value, the chance honest draws would score at least as high ([Hypothesis tests](../08-Confidence%20Intervals%20and%20Tests/03-hypothesis-tests-and-p-values.md)), comes from the area under that law's density. The checks compute it with their own Simpson's-rule integrator, which adds up the area in many thin slices. At 16.919, the 5% point that printed tables give for 9 degrees of freedom, the integrator returns 0.0500.

| Generator | Chi-square | p-value |
| --- | --- | --- |
| MT19937, seed 20260929 | 18.29 | 0.0319 |
| minstd, seed 1 | 6.69 | 0.6694 |
| RANDU, seed 1 | 8.81 | 0.4548 |

### The picture: 10,000 MT19937 draws in ten bins

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "MT19937, seed 20260929: draws per bin"
    x-axis "Bin of the draw" ["0-0.1", "0.1-0.2", "0.2-0.3", "0.3-0.4", "0.4-0.5", "0.5-0.6", "0.6-0.7", "0.7-0.8", "0.8-0.9", "0.9-1"]
    y-axis "Draws in the bin (axis starts at 800)" 800 --> 1100
    bar [1031, 1014, 1053, 1027, 946, 1057, 993, 971, 920, 988]
    line [1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000]
```

Bars: the counts, printed by both checks. Line: the 1000 expected in each bin. The axis starts at 800, which magnifies the wobble.

The best generator of the three has the worst score and fails at the 5% level. A 5% test rejects honest draws one time in twenty, by design. From seeds 1 to 100, MT19937 falls below 0.05 in 5 runs: what a sound generator should do. RANDU passes comfortably, because the bin test looks at one draw at a time and RANDU's flaw lives in triples. Serious test batteries run hundreds of tests aimed at different patterns.

### Step 5: bigger states, stirred with bits

Modern generators keep a much larger state and stir it with bit operations: shifts (slide the binary digits left or right) and XOR (exclusive or: compare two numbers digit by digit, 1 where they differ).

**MT19937**, the Mersenne Twister of Matsumoto and Nishimura (1998), holds 624 numbers of 32 bits. Each refill mixes every word with its neighbour and with the word 397 places on; each output is then scrambled further, "tempered", before release.

Its loop has length $2^{19937} - 1$, a **Mersenne prime** (a prime one less than a power of 2), which gives the name. The 1998 paper proves it by polynomial algebra over bits, and this card takes it as stated. The check's version, from seed 5489, gives 4123659995 as its 10,000th output, the value the C++ standard fixes as the test of a correct implementation.

**SplitMix64**, written out in many checks on this wing, is a counter with a scrambler. Its state steps by a fixed odd number: an LCG with $a = 1$ and odd $c$, so by Step 2 its loop covers all $2^{64}$ states. On its own that is the counter of Step 3. A mixing function then shifts, XORs and multiplies the state so that neighbouring counts give unrelated outputs. Because the state after $n$ steps is the seed plus $n$ times the step, the 10,000th output can be computed directly; the check gets the same number both ways.

Physical noise and cryptographic generators are the other routes; simulation rarely needs them, security always needs the second. How far fixed rules can stand in for true randomness is the subject of Pseudorandomness.

---

## Worked numbers, by hand

The toy generator $x_{n+1} = (5x_n + 3) \bmod 16$, seed 7.

| Step | Arithmetic | Value |
| --- | --- | --- |
| $x_1$ | 5 × 7 + 3 = 38; 38 − 2 × 16 | 6 |
| $u_1$ | 6 / 16 | 0.3750 |
| $x_2$ | 5 × 6 + 3 = 33; 33 − 2 × 16 | 1 |
| $x_3$ | 5 × 1 + 3 = 8 | 8 |
| $x_4$ | 5 × 8 + 3 = 43; 43 − 2 × 16 | 11 |
| $u_2$, $u_3$, $u_4$ | 1/16, 8/16, 11/16 | 0.0625, 0.5000, 0.6875 |
| the rule | $a = 5$ leaves 1 on division by 4; $c = 3$ is odd | full loop |
| steps until 7 returns | keep going: 10, 5, 12, 15, 14, 9, 0, 3, 2, 13, 4, 7 | **16** |

Each of the 16 values appears exactly once per loop, then the loop replays: the reason real generators have loops far longer than any simulation will use.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Even increment: $(5x + 2) \bmod 16$ | loop of 8 | an odd seed never reaches an even state |
| Multiplier 3, remainder 3 on division by 4: $(3x + 3) \bmod 16$ | loop of 8 | an extra factor of 2 closes the loop at step $m/2$ |
| Last bit of the toy generator as a coin | 0, 1, 0, 1, … | with $m$ a power of 2, the lowest bit has a loop of 2 |
| minstd seeded 1 and 2 as "independent" streams | seed 2 gives 0.000016, 0.263076, 0.511211: seed 1's 0.000008, 0.131538, 0.755605 doubled, less 1 once past 1 | with $c = 0$, the seed-2 stream is 2 times the seed-1 stream mod $m$, in 1000 of 1000 outputs |
| Trusting RANDU because it passes the bin test | p = 0.4548, yet 10,000 of 10,000 triples on 15 planes | the test looked at single draws, the flaw lives in triples |

---

## Code, from first principles, and it actually runs

Both programs write out their generators (linear congruential, MT19937, SplitMix64) and import no random module. Four roads:

- the full-cycle rule against brute force over every multiplier and increment;
- the 10,000th output by stepping, by jumping ahead and against published values;
- a hand-written Simpson's rule against the printed 5% table value;
- simulated numbers held to their standard errors or a failure count, never to exact matches.

### Python

```python
# Random numbers from a computer -- the check behind the card.  Standard library
# only, no random module: every generator is written out here.  Roads: rule
# against brute force, stepping against jumping ahead against published values,
# and statistical tests whose own yardstick is checked against a printed table.
import math
M32, M64, P = 2**32 - 1, 2**64 - 1, 2**31 - 1

def lcg(a, c, m, x, n):                        # n outputs of x -> (a x + c) mod m
    out = []
    for _ in range(n):
        x = (a * x + c) % m
        out.append(x)
    return out

def cycle(a, c, m, x):                         # length of the loop the seed falls into
    seen, n = {}, 0
    while x not in seen:
        seen[x], x, n = n, (a * x + c) % m, n + 1
    return n - seen[x]

def powmod(b, e, m):                           # square-and-multiply, to jump ahead
    r = 1
    while e:
        if e & 1: r = r * b % m
        b, e = b * b % m, e >> 1
    return r

class MT:                                      # MT19937, Matsumoto and Nishimura 1998
    def __init__(self, seed):
        self.s = [seed]
        for i in range(1, 624):
            self.s.append((1812433253 * (self.s[-1] ^ (self.s[-1] >> 30)) + i) & M32)
        self.i = 624
    def next32(self):
        s = self.s
        if self.i == 624:                      # refill all 624 words at once
            for k in range(624):
                y = (s[k] & 0x80000000) | (s[(k + 1) % 624] & 0x7FFFFFFF)
                s[k] = s[(k + 397) % 624] ^ (y >> 1) ^ (0x9908B0DF * (y & 1))
            self.i = 0
        y = s[self.i]; self.i += 1
        y ^= y >> 11; y ^= (y << 7) & 0x9D2C5680; y ^= (y << 15) & 0xEFC60000
        return y ^ (y >> 18)
    def u(self): return self.next32() / 2**32

def splitmix(state):                           # SplitMix64: a counter, then a scrambler
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return state, z ^ (z >> 31)

def chi2(draw, n=10000, k=10):                 # counts in k equal bins, and the statistic
    obs = [0] * k
    for _ in range(n): obs[int(draw() * k)] += 1
    return obs, sum((o - n / k) ** 2 / (n / k) for o in obs)

def pvalue(x, steps=2000):                     # chance a true uniform scores above x, for
    g = 3.5 * 2.5 * 1.5 * 0.5 * math.sqrt(math.pi)    # 9 degrees of freedom, by Simpson's rule
    f = lambda t: t ** 3.5 * math.exp(-t / 2) / (2 ** 4.5 * g)
    h = x / steps
    s = f(0) + f(x) + sum((4 if j % 2 else 2) * f(j * h) for j in range(1, steps))
    return 1 - s * h / 3

def stream(a, m, x):                           # an LCG without increment, as u in [0, 1)
    def draw():
        nonlocal x
        x = a * x % m
        return x / m
    return draw

def darts(seed, n=100000):                     # the house example: darts at a unit square
    g, hits = MT(seed), 0
    for _ in range(n):
        x, y = g.u(), g.u()
        hits += x * x + y * y < 1
    p = hits / n
    return 4 * p, 4 * math.sqrt(p * (1 - p) / n)

yn = lambda b: "yes" if b else "no"
toy = lcg(5, 3, 16, 7, 16)
pairs = sorted(zip([7] + toy[:15], toy))
print(f"toy,x -> (5x + 3) mod 16,seed 7,outputs {toy},cycle {cycle(5, 3, 16, 7)}")
print(f"toy,u = x/16,first four {', '.join(f'{x / 16:.4f}' for x in toy[:4])},last bits {[x & 1 for x in toy[:12]]}")
print(f"figure,pairs {pairs},values of x + 3y {sorted({x + 3 * y for x, y in pairs})}")
rule_ok = True
for m in (16, 64):
    brute = [(a, c) for a in range(m) for c in range(m) if cycle(a, c, m, 0) == m]
    rule = [(a, c) for a in range(m) for c in range(m) if c % 2 == 1 and a % 4 == 1]
    rule_ok = rule_ok and brute == rule
    print(f"full cycle,m {m},pairs by brute force {len(brute)},by the rule {len(rule)},same pairs {yn(brute == rule)}")
print(f"cycle,(5x + 2) mod 16 from 7: {cycle(5, 2, 16, 7)},(3x + 3) mod 16 from 7: {cycle(3, 3, 16, 7)},"
      f"(x + 1) mod 16: {cycle(1, 1, 16, 7)} {lcg(1, 1, 16, 7, 6)}")
step, jump = lcg(16807, 0, P, 1, 10000)[-1], powmod(16807, 10000, P)
print(f"minstd,x -> 16807x mod (2^31 - 1),seed 1,10000th by stepping {step},by jumping {jump},published 1043618065")
g = MT(5489)
mt_out = [g.next32() for _ in range(10000)]
print(f"mt19937,seed 5489,first {mt_out[0]},10000th {mt_out[-1]},published 10000th 4123659995")
s, sm = 0, []
for _ in range(10000):
    s, z = splitmix(s)
    sm.append(z)
jump_sm = splitmix((10000 - 1) * 0x9E3779B97F4A7C15 & M64)[1]   # the counter jumps straight there
print(f"splitmix64,seed 0,first {sm[0]:016x},10000th by stepping {sm[-1]:016x},by jumping {jump_sm:016x}")
print(f"chi-square,table 5% point for 9 degrees of freedom 16.919,p by Simpson {pvalue(16.919):.4f}")
pv = []
for name, draw in [("mt19937 seed 20260929", MT(20260929).u), ("minstd seed 1", stream(16807, P, 1)),
                   ("randu seed 1", stream(65539, 2**31, 1))]:
    obs, x2 = chi2(draw)
    pv.append(pvalue(x2))
    print(f"uniformity,{name},10000 draws in 10 bins (1000 expected in each) {obs},chi-square {x2:.2f},p {pv[-1]:.4f}")
low = sum(1 for sd in range(1, 101) if pvalue(chi2(MT(sd).u)[1]) < 0.05)
print(f"uniformity,mt19937 seeds 1 to 100,tests with p below 0.05: {low} of 100")
r = lcg(65539, 0, 2**31, 1, 10002)
g = MT(20260929)
w = [g.next32() >> 1 for _ in range(10002)]
on = sum(1 for i in range(10000) if (9 * r[i] - 6 * r[i + 1] + r[i + 2]) % 2**31 == 0)
planes = len({(9 * r[i] - 6 * r[i + 1] + r[i + 2]) // 2**31 for i in range(10000)})
on_mt = sum(1 for i in range(10000) if (9 * w[i] - 6 * w[i + 1] + w[i + 2]) % 2**31 == 0)
print(f"triples,randu,9x - 6y + z a multiple of 2^31 in {on} of 10000,planes {planes},mt19937 {on_mt} of 10000")
s1, s2 = lcg(16807, 0, P, 1, 1000), lcg(16807, 0, P, 2, 1000)
twice = sum(1 for a, b in zip(s1, s2) if b == 2 * a % P)
print(f"seeds,minstd seed 1 {', '.join(f'{x / P:.6f}' for x in s1[:3])},seed 2 {', '.join(f'{x / P:.6f}' for x in s2[:3])},"
      f"seed-2 output = 2 x seed-1 output mod m in {twice} of 1000")
(a1, se1), (a2, _), (b1, seb) = darts(20260929), darts(20260929), darts(20260930)
print(f"darts,100000 each,seed 20260929 run 1 {a1:.5f} ({round(a1 * 25000)} hits),run 2 {a2:.5f},se {se1:.5f}")
print(f"darts,seed 20260930 {b1:.5f},se {seb:.5f},pi {math.pi:.5f},gap between seeds {abs(a1 - b1):.5f}")
assert sorted(toy) == list(range(16)) and all((x + 3 * y) % 16 == 9 for x, y in pairs)  # rule; x + 3y = 9 mod 16
assert rule_ok and cycle(5, 2, 16, 7) == cycle(3, 3, 16, 7) == 8  # rule = brute force; broken rule halves
assert step == jump == 1043618065                              # three roads to minstd's 10000th
assert mt_out[-1] == 4123659995 and sm[-1] == jump_sm          # published value; counter jump
assert abs(pvalue(16.919) - 0.05) < 1e-4                       # own integrator = printed table
assert on == 10000 and planes == 15 and on_mt < 5              # a^2 = 6a - 9 predicts the planes
assert twice == 1000                                           # algebra predicts the seed clone
assert round(a1 * 25000) == 78464 and a1 != b1                 # the Rust run's hits; new seed, new run
assert abs(a1 - math.pi) < 4 * se1 and abs(b1 - math.pi) < 4 * seb
assert min(pv) > 0.001 and low <= 14                           # 5 in 100 expected, sd about 2
print("ALL CHECKS PASS")
```

**Ran 2026-10-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
toy,x -> (5x + 3) mod 16,seed 7,outputs [6, 1, 8, 11, 10, 5, 12, 15, 14, 9, 0, 3, 2, 13, 4, 7],cycle 16
toy,u = x/16,first four 0.3750, 0.0625, 0.5000, 0.6875,last bits [0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1]
figure,pairs [(0, 3), (1, 8), (2, 13), (3, 2), (4, 7), (5, 12), (6, 1), (7, 6), (8, 11), (9, 0), (10, 5), (11, 10), (12, 15), (13, 4), (14, 9), (15, 14)],values of x + 3y [9, 25, 41, 57]
full cycle,m 16,pairs by brute force 32,by the rule 32,same pairs yes
full cycle,m 64,pairs by brute force 512,by the rule 512,same pairs yes
cycle,(5x + 2) mod 16 from 7: 8,(3x + 3) mod 16 from 7: 8,(x + 1) mod 16: 16 [8, 9, 10, 11, 12, 13]
minstd,x -> 16807x mod (2^31 - 1),seed 1,10000th by stepping 1043618065,by jumping 1043618065,published 1043618065
mt19937,seed 5489,first 3499211612,10000th 4123659995,published 10000th 4123659995
splitmix64,seed 0,first e220a8397b1dcdaf,10000th by stepping 488601e3f80e210a,by jumping 488601e3f80e210a
chi-square,table 5% point for 9 degrees of freedom 16.919,p by Simpson 0.0500
uniformity,mt19937 seed 20260929,10000 draws in 10 bins (1000 expected in each) [1031, 1014, 1053, 1027, 946, 1057, 993, 971, 920, 988],chi-square 18.29,p 0.0319
uniformity,minstd seed 1,10000 draws in 10 bins (1000 expected in each) [993, 1007, 998, 958, 1001, 1049, 989, 963, 1026, 1016],chi-square 6.69,p 0.6694
uniformity,randu seed 1,10000 draws in 10 bins (1000 expected in each) [974, 1011, 984, 1031, 1011, 972, 1004, 1064, 959, 990],chi-square 8.81,p 0.4548
uniformity,mt19937 seeds 1 to 100,tests with p below 0.05: 5 of 100
triples,randu,9x - 6y + z a multiple of 2^31 in 10000 of 10000,planes 15,mt19937 0 of 10000
seeds,minstd seed 1 0.000008, 0.131538, 0.755605,seed 2 0.000016, 0.263076, 0.511211,seed-2 output = 2 x seed-1 output mod m in 1000 of 1000
darts,100000 each,seed 20260929 run 1 3.13856 (78464 hits),run 2 3.13856,se 0.00520
darts,seed 20260930 3.14304,se 0.00519,pi 3.14159,gap between seeds 0.00448
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Random numbers from a computer -- the same check as the Python, in Rust.  No
// crates: every generator is written out here.  Roads: rule against brute
// force, stepping against jumping ahead against published values, and
// statistical tests whose own yardstick is checked against a printed table.
use std::collections::{BTreeSet, HashMap};
const P: u64 = (1 << 31) - 1;

fn lcg(a: u64, c: u64, m: u64, mut x: u64, n: usize) -> Vec<u64> {   // n outputs of (a x + c) mod m
    (0..n).map(|_| { x = (a * x + c) % m; x }).collect()
}

fn cycle(a: u64, c: u64, m: u64, mut x: u64) -> u64 {   // length of the loop the seed falls into
    let (mut seen, mut n) = (HashMap::new(), 0u64);
    while !seen.contains_key(&x) {
        seen.insert(x, n);
        x = (a * x + c) % m;
        n += 1;
    }
    n - seen[&x]
}

fn powmod(mut b: u64, mut e: u64, m: u64) -> u64 {      // square-and-multiply, to jump ahead
    let mut r = 1;
    while e > 0 {
        if e & 1 == 1 { r = r * b % m }
        b = b * b % m;
        e >>= 1;
    }
    r
}

struct Mt { s: Vec<u32>, i: usize }                     // MT19937, Matsumoto and Nishimura 1998
impl Mt {
    fn new(seed: u32) -> Mt {
        let mut s = vec![seed];
        for i in 1..624u32 {
            let p = s[i as usize - 1];
            s.push(1812433253u32.wrapping_mul(p ^ (p >> 30)).wrapping_add(i));
        }
        Mt { s, i: 624 }
    }
    fn next32(&mut self) -> u32 {
        if self.i == 624 {                              // refill all 624 words at once
            for k in 0..624 {
                let y = (self.s[k] & 0x80000000) | (self.s[(k + 1) % 624] & 0x7FFFFFFF);
                self.s[k] = self.s[(k + 397) % 624] ^ (y >> 1) ^ (0x9908B0DF * (y & 1));
            }
            self.i = 0;
        }
        let mut y = self.s[self.i];
        self.i += 1;
        y ^= y >> 11; y ^= (y << 7) & 0x9D2C5680; y ^= (y << 15) & 0xEFC60000;
        y ^ (y >> 18)
    }
    fn u(&mut self) -> f64 { self.next32() as f64 / 4294967296.0 }
}

fn splitmix(state: u64) -> (u64, u64) {                 // SplitMix64: a counter, then a scrambler
    let state = state.wrapping_add(0x9E3779B97F4A7C15);
    let z = (state ^ (state >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (state, z ^ (z >> 31))
}

fn chi2(draw: &mut dyn FnMut() -> f64) -> (Vec<u64>, f64) {   // counts in 10 bins, and the statistic
    let mut obs = vec![0u64; 10];
    for _ in 0..10000 { obs[(draw() * 10.0) as usize] += 1 }
    (obs.clone(), obs.iter().map(|&o| (o as f64 - 1000.0).powi(2) / 1000.0).sum())
}

fn pvalue(x: f64) -> f64 {                              // chance a true uniform scores above x,
    let g = 3.5 * 2.5 * 1.5 * 0.5 * std::f64::consts::PI.sqrt();   // 9 degrees of freedom, Simpson
    let f = |t: f64| t.powf(3.5) * (-t / 2.0).exp() / (2f64.powf(4.5) * g);
    let h = x / 2000.0;
    let mut acc = 0.0;
    for j in 1..2000 { acc += (if j % 2 == 1 { 4.0 } else { 2.0 }) * f(j as f64 * h) }
    1.0 - (f(0.0) + f(x) + acc) * h / 3.0
}

fn stream(a: u64, m: u64, mut x: u64) -> impl FnMut() -> f64 {   // LCG without increment, u in [0, 1)
    move || { x = a * x % m; x as f64 / m as f64 }
}

fn darts(seed: u32) -> (f64, f64) {                     // the house example: darts at a unit square
    let (mut g, mut hits, n) = (Mt::new(seed), 0u64, 100000.0);
    for _ in 0..100000 {
        let (x, y) = (g.u(), g.u());
        if x * x + y * y < 1.0 { hits += 1 }
    }
    let p = hits as f64 / n;
    (4.0 * p, 4.0 * (p * (1.0 - p) / n).sqrt())
}

fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn fl(v: &[u64], m: f64, d: usize) -> String {
    v.iter().map(|&x| format!("{:.*}", d, x as f64 / m)).collect::<Vec<_>>().join(", ")
}

fn main() {
    let toy = lcg(5, 3, 16, 7, 16);
    let mut pairs: Vec<(u64, u64)> = (0..16).map(|i| (if i == 0 { 7 } else { toy[i - 1] }, toy[i])).collect();
    pairs.sort();
    let lines: Vec<u64> = pairs.iter().map(|&(x, y)| x + 3 * y).collect::<BTreeSet<u64>>().into_iter().collect();
    let bits: Vec<u64> = toy[..12].iter().map(|x| x & 1).collect();
    println!("toy,x -> (5x + 3) mod 16,seed 7,outputs {:?},cycle {}", toy, cycle(5, 3, 16, 7));
    println!("toy,u = x/16,first four {},last bits {:?}", fl(&toy[..4], 16.0, 4), bits);
    println!("figure,pairs {:?},values of x + 3y {:?}", pairs, lines);
    let mut rule_ok = true;
    for m in [16u64, 64] {
        let all: Vec<(u64, u64)> = (0..m).flat_map(|a| (0..m).map(move |c| (a, c))).collect();
        let brute: Vec<(u64, u64)> = all.iter().copied().filter(|&(a, c)| cycle(a, c, m, 0) == m).collect();
        let rule: Vec<(u64, u64)> = all.iter().copied().filter(|&(a, c)| c % 2 == 1 && a % 4 == 1).collect();
        rule_ok = rule_ok && brute == rule;
        println!("full cycle,m {},pairs by brute force {},by the rule {},same pairs {}", m, brute.len(), rule.len(), yn(brute == rule));
    }
    println!("cycle,(5x + 2) mod 16 from 7: {},(3x + 3) mod 16 from 7: {},(x + 1) mod 16: {} {:?}",
             cycle(5, 2, 16, 7), cycle(3, 3, 16, 7), cycle(1, 1, 16, 7), lcg(1, 1, 16, 7, 6));
    let (step, jump) = (lcg(16807, 0, P, 1, 10000)[9999], powmod(16807, 10000, P));
    println!("minstd,x -> 16807x mod (2^31 - 1),seed 1,10000th by stepping {},by jumping {},published 1043618065", step, jump);
    let mut g = Mt::new(5489);
    let mt_out: Vec<u32> = (0..10000).map(|_| g.next32()).collect();
    println!("mt19937,seed 5489,first {},10000th {},published 10000th 4123659995", mt_out[0], mt_out[9999]);
    let (mut s, mut sm) = (0u64, Vec::new());
    for _ in 0..10000 { let (s2, z) = splitmix(s); s = s2; sm.push(z); }
    let jump_sm = splitmix(9999u64.wrapping_mul(0x9E3779B97F4A7C15)).1;   // the counter jumps straight there
    println!("splitmix64,seed 0,first {:016x},10000th by stepping {:016x},by jumping {:016x}", sm[0], sm[9999], jump_sm);
    println!("chi-square,table 5% point for 9 degrees of freedom 16.919,p by Simpson {:.4}", pvalue(16.919));
    let mut mt = Mt::new(20260929);
    let mut tests: Vec<(&str, Box<dyn FnMut() -> f64>)> = vec![("mt19937 seed 20260929", Box::new(move || mt.u())),
        ("minstd seed 1", Box::new(stream(16807, P, 1))), ("randu seed 1", Box::new(stream(65539, 1 << 31, 1)))];
    let mut pv = Vec::new();
    for (name, draw) in tests.iter_mut() {
        let (obs, x2) = chi2(draw.as_mut());
        pv.push(pvalue(x2));
        println!("uniformity,{},10000 draws in 10 bins (1000 expected in each) {:?},chi-square {:.2},p {:.4}", name, obs, x2, pv[pv.len() - 1]);
    }
    let low = (1..=100u32).filter(|&sd| { let mut g = Mt::new(sd); pvalue(chi2(&mut || g.u()).1) < 0.05 }).count();
    println!("uniformity,mt19937 seeds 1 to 100,tests with p below 0.05: {} of 100", low);
    let r: Vec<i64> = lcg(65539, 0, 1 << 31, 1, 10002).iter().map(|&x| x as i64).collect();
    let mut g = Mt::new(20260929);
    let w: Vec<i64> = (0..10002).map(|_| (g.next32() >> 1) as i64).collect();
    let comb = |v: &Vec<i64>, i: usize| 9 * v[i] - 6 * v[i + 1] + v[i + 2];
    let on = (0..10000).filter(|&i| comb(&r, i).rem_euclid(1 << 31) == 0).count();
    let planes = (0..10000).map(|i| comb(&r, i).div_euclid(1 << 31)).collect::<BTreeSet<i64>>().len();
    let on_mt = (0..10000).filter(|&i| comb(&w, i).rem_euclid(1 << 31) == 0).count();
    println!("triples,randu,9x - 6y + z a multiple of 2^31 in {} of 10000,planes {},mt19937 {} of 10000", on, planes, on_mt);
    let (s1, s2) = (lcg(16807, 0, P, 1, 1000), lcg(16807, 0, P, 2, 1000));
    let twice = s1.iter().zip(&s2).filter(|&(a, b)| *b == 2 * a % P).count();
    println!("seeds,minstd seed 1 {},seed 2 {},seed-2 output = 2 x seed-1 output mod m in {} of 1000",
             fl(&s1[..3], P as f64, 6), fl(&s2[..3], P as f64, 6), twice);
    let ((a1, se1), (a2, _), (b1, seb)) = (darts(20260929), darts(20260929), darts(20260930));
    let pi = std::f64::consts::PI;
    println!("darts,100000 each,seed 20260929 run 1 {:.5} ({} hits),run 2 {:.5},se {:.5}", a1, (a1 * 25000.0).round() as u64, a2, se1);
    println!("darts,seed 20260930 {:.5},se {:.5},pi {:.5},gap between seeds {:.5}", b1, seb, pi, (a1 - b1).abs());
    assert!(toy.iter().copied().collect::<BTreeSet<u64>>().len() == 16 && pairs.iter().all(|&(x, y)| (x + 3 * y) % 16 == 9));
    assert!(rule_ok && cycle(5, 2, 16, 7) == 8 && cycle(3, 3, 16, 7) == 8);   // rule = brute force; broken rule halves
    assert!(step == 1043618065 && jump == 1043618065);                 // three roads to minstd's 10000th
    assert!(mt_out[9999] == 4123659995 && sm[9999] == jump_sm);          // published value; counter jump
    assert!((pvalue(16.919) - 0.05).abs() < 1e-4);                     // own integrator = printed table
    assert!(on == 10000 && planes == 15 && on_mt < 5);                 // a^2 = 6a - 9 predicts the planes
    assert!(twice == 1000);                                            // algebra predicts the seed clone
    assert!((a1 * 25000.0).round() as u64 == 78464 && a1 != b1);       // the Python run's hits; new seed, new run
    assert!((a1 - pi).abs() < 4.0 * se1 && (b1 - pi).abs() < 4.0 * seb);
    assert!(pv.iter().all(|&p| p > 0.001) && low <= 14);               // 5 in 100 expected, sd about 2
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-10-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
toy,x -> (5x + 3) mod 16,seed 7,outputs [6, 1, 8, 11, 10, 5, 12, 15, 14, 9, 0, 3, 2, 13, 4, 7],cycle 16
toy,u = x/16,first four 0.3750, 0.0625, 0.5000, 0.6875,last bits [0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1]
figure,pairs [(0, 3), (1, 8), (2, 13), (3, 2), (4, 7), (5, 12), (6, 1), (7, 6), (8, 11), (9, 0), (10, 5), (11, 10), (12, 15), (13, 4), (14, 9), (15, 14)],values of x + 3y [9, 25, 41, 57]
full cycle,m 16,pairs by brute force 32,by the rule 32,same pairs yes
full cycle,m 64,pairs by brute force 512,by the rule 512,same pairs yes
cycle,(5x + 2) mod 16 from 7: 8,(3x + 3) mod 16 from 7: 8,(x + 1) mod 16: 16 [8, 9, 10, 11, 12, 13]
minstd,x -> 16807x mod (2^31 - 1),seed 1,10000th by stepping 1043618065,by jumping 1043618065,published 1043618065
mt19937,seed 5489,first 3499211612,10000th 4123659995,published 10000th 4123659995
splitmix64,seed 0,first e220a8397b1dcdaf,10000th by stepping 488601e3f80e210a,by jumping 488601e3f80e210a
chi-square,table 5% point for 9 degrees of freedom 16.919,p by Simpson 0.0500
uniformity,mt19937 seed 20260929,10000 draws in 10 bins (1000 expected in each) [1031, 1014, 1053, 1027, 946, 1057, 993, 971, 920, 988],chi-square 18.29,p 0.0319
uniformity,minstd seed 1,10000 draws in 10 bins (1000 expected in each) [993, 1007, 998, 958, 1001, 1049, 989, 963, 1026, 1016],chi-square 6.69,p 0.6694
uniformity,randu seed 1,10000 draws in 10 bins (1000 expected in each) [974, 1011, 984, 1031, 1011, 972, 1004, 1064, 959, 990],chi-square 8.81,p 0.4548
uniformity,mt19937 seeds 1 to 100,tests with p below 0.05: 5 of 100
triples,randu,9x - 6y + z a multiple of 2^31 in 10000 of 10000,planes 15,mt19937 0 of 10000
seeds,minstd seed 1 0.000008, 0.131538, 0.755605,seed 2 0.000016, 0.263076, 0.511211,seed-2 output = 2 x seed-1 output mod m in 1000 of 1000
darts,100000 each,seed 20260929 run 1 3.13856 (78464 hits),run 2 3.13856,se 0.00520
darts,seed 20260930 3.14304,se 0.00519,pi 3.14159,gap between seeds 0.00448
ALL CHECKS PASS
```

The two outputs match line for line, and that match is the replay test: each program asserts the 78,464 hits the other counted from seed 20260929, while the second run inside one program can only repeat the first.

Every assert was also broken on purpose (a wrong rule, a wrong tempering shift, a wrong Simpson constant, a wider dart target, a wrong seed algebra, an even toy increment) and each stopped the run.

### Lean

Lean proves the full-cycle rule for every power of 2 from 4 up, plus jumping ahead and RANDU's flaw for every seed.

- Take $m$ a power of 2, at least 4. Then the loop length is $m$ from every seed exactly when $c$ is odd and $a \equiv 1 \pmod 4$.
- Take $c = 0$ and any seed $x_0$ below $m$. Then $n$ steps give $x_n = a^n x_0 \bmod m$.
- Take any RANDU state $x$, and the next two states, $y$ and $z$. Then $9x - 6y + z$ is a multiple of $2^{31}$.
- The toy generator's 16 outputs from seed 7 come out exactly, and 7 first returns at step 16.
- The even increment and the multiplier 3 each give a loop of 8 from seed 7.
- Brute force over every $a$ and $c$ from 0 to 15 agrees with the rule, and the rule picks 32 pairs.
- Take $a = 1$ and $c = 1$. Then the stream from 8 counts 8, 9, 10, 11, 12, 13.
- The toy's pairs lie on the four lines, and its last bit alternates 0, 1.
- Take RANDU's $a = 65539$. Then $a^2$ and $6a - 9$ leave the same remainder on division by $2^{31}$.
- From seed 1, minstd's 10,000th state is 1043618065, by stepping and by jumping.

The chi-square tests, MT19937, SplitMix64, the 15 planes, the seed-2 stream and the darts are left to the Python and Rust checks.

```lean
-- Random numbers from a computer: a linear congruential generator x ↦ (a x + c) mod 2^k (with 2^k at least 4) runs through all 2^k states before repeating exactly when c is odd and a leaves remainder 1 on division by 4; with no increment, n steps multiply the seed by a^n; and RANDU's every output is fixed by the two before it.
import Mathlib.Data.ZMod.Basic
import Mathlib.Dynamics.PeriodicPts.Defs
import Mathlib.Data.Int.Basic
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Tactic.NormNum
import Mathlib.Algebra.Ring.GeomSum
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Positivity

open Finset in
lemma prn_sum_double (a n : ℕ) :
    ∑ i ∈ range (2 * n), a ^ i = (∑ i ∈ range n, a ^ i) * (1 + a ^ n) := by
  rw [two_mul, Finset.sum_range_add]
  simp only [pow_add, ← Finset.mul_sum]
  ring

open Finset in
lemma prn_sum_one_mod_four (a : ℕ) (ha : a % 4 = 1) (m : ℕ) :
    ∃ t, ∑ i ∈ range (2 ^ m), a ^ i = 2 ^ m * (2 * t + 1) := by
  induction m with
  | zero => exact ⟨0, by simp⟩
  | succ m ih =>
    obtain ⟨t, ht⟩ := ih
    have h4 : a ^ (2 ^ m) % 4 = 1 := by rw [Nat.pow_mod, ha]; simp
    obtain ⟨q, hq⟩ : ∃ q, a ^ (2 ^ m) = 4 * q + 1 := ⟨a ^ (2 ^ m) / 4, by omega⟩
    refine ⟨2 * t * q + t + q, ?_⟩
    rw [pow_succ, mul_comm (2 ^ m) 2, prn_sum_double, ht, hq]
    ring

open Finset in
lemma prn_sum_odd (a : ℕ) (ha : a % 2 = 1) (m : ℕ) :
    2 ^ m ∣ ∑ i ∈ range (2 ^ m), a ^ i := by
  induction m with
  | zero => simp
  | succ m ih =>
    have h2 : 2 ∣ 1 + a ^ (2 ^ m) := by
      have : a ^ (2 ^ m) % 2 = 1 := by rw [Nat.pow_mod, ha]; simp
      omega
    rw [show 2 ^ (m + 1) = 2 * 2 ^ m by ring, prn_sum_double, Nat.mul_comm 2 (2 ^ m)]
    exact mul_dvd_mul ih h2

open Finset in
lemma prn_sum_three_mod_four (a : ℕ) (ha : a % 4 = 3) (m : ℕ) :
    2 ^ (m + 2) ∣ ∑ i ∈ range (2 ^ (m + 1)), a ^ i := by
  induction m with
  | zero =>
    norm_num [Finset.sum_range_succ]
    omega
  | succ m ih =>
    have h2 : 2 ∣ 1 + a ^ (2 ^ (m + 1)) := by
      have ha2 : a % 2 = 1 := by omega
      have : a ^ (2 ^ (m + 1)) % 2 = 1 := by rw [Nat.pow_mod, ha2]; simp
      omega
    rw [show 2 ^ (m + 1 + 1) = 2 * 2 ^ (m + 1) by ring, prn_sum_double,
      show 2 ^ (m + 1 + 2) = 2 ^ (m + 2) * 2 by ring]
    exact mul_dvd_mul ih h2

open Finset in
lemma prn_iter (N a c : ℕ) (f : ZMod N → ZMod N) (hf : ∀ y, f y = (a : ZMod N) * y + c)
    (n : ℕ) (x : ZMod N) :
    f^[n] x = (a : ZMod N) ^ n * x + c * ∑ i ∈ range n, (a : ZMod N) ^ i := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [Function.iterate_succ_apply', ih, hf, geom_sum_succ]
    ring

open Finset in
lemma prn_iter_sub (N a c : ℕ) (f : ZMod N → ZMod N) (hf : ∀ y, f y = (a : ZMod N) * y + c)
    (n : ℕ) (x : ZMod N) :
    f^[n] x - x = (∑ i ∈ range n, (a : ZMod N) ^ i) * (((a : ZMod N) - 1) * x + c) := by
  rw [prn_iter N a c f hf]
  have := geom_sum_mul (a : ZMod N) n
  linear_combination (-x) * this

lemma prn_two_pow_ne_zero (j : ℕ) : (2 : ZMod (2 ^ (j + 2))) ^ (j + 1) ≠ 0 := by
  intro h
  have h' : ((2 ^ (j + 1) : ℕ) : ZMod (2 ^ (j + 2))) = 0 := by exact_mod_cast h
  rw [ZMod.natCast_eq_zero_iff] at h'
  have h1 := Nat.le_of_dvd (by positivity) h'
  have h2 : 2 ^ (j + 1) < 2 ^ (j + 2) := Nat.pow_lt_pow_right (by norm_num) (by omega)
  omega

lemma prn_two_pow_eq_zero (j : ℕ) : (2 : ZMod (2 ^ (j + 2))) ^ (j + 2) = 0 := by
  exact_mod_cast ZMod.natCast_self (2 ^ (j + 2))

#print axioms prn_sum_double
#print axioms prn_sum_one_mod_four
#print axioms prn_sum_odd
#print axioms prn_sum_three_mod_four
#print axioms prn_iter
#print axioms prn_iter_sub
#print axioms prn_two_pow_ne_zero
#print axioms prn_two_pow_eq_zero

/-- The full-cycle rule (Hull and Dobell, 1962), for m a power of 2 and at least 4. The linear
congruential generator x ↦ (a × x + c) mod m visits all m states before repeating, from every
seed, exactly when the increment c is odd and the multiplier a leaves remainder 1 on division
by 4. Here the states are the m remainders, and the loop length of a seed is the first number of
steps that brings it back. -/
theorem lcg_full_cycle_iff_c_odd_and_a_one_mod_four (k : ℕ) (hk : 2 ≤ k) (a c : ℕ) :
    (∀ x : ZMod (2 ^ k),
        Function.minimalPeriod (fun y : ZMod (2 ^ k) => (a : ZMod (2 ^ k)) * y + c) x = 2 ^ k) ↔
      (Odd c ∧ a % 4 = 1) := by
  obtain ⟨j, rfl⟩ : ∃ j, k = j + 2 := ⟨k - 2, by omega⟩
  set f := fun y : ZMod (2 ^ (j + 2)) => (a : ZMod (2 ^ (j + 2))) * y + c with hfdef
  have hf : ∀ y, f y = (a : ZMod (2 ^ (j + 2))) * y + c := fun y => rfl
  have hlt : 2 ^ (j + 1) < 2 ^ (j + 2) := Nat.pow_lt_pow_right (by norm_num) (by omega)
  constructor
  · intro h
    have hfix : ∀ x, f^[2 ^ (j + 2)] x = x := fun x => by
      have := Function.iterate_minimalPeriod (f := f) (x := x)
      rwa [h x] at this
    have hhalf : ¬ (f^[2 ^ (j + 1)] (0 : ZMod (2 ^ (j + 2))) = 0) := by
      intro h0
      have hd := (show Function.IsPeriodicPt f (2 ^ (j + 1)) 0 from h0).minimalPeriod_dvd
      rw [h 0] at hd
      have := Nat.le_of_dvd (by positivity) hd
      omega
    have ha : a % 2 = 1 := by
      by_contra hae
      have hinj : Function.Injective f := by
        have hid : f^[2 ^ (j + 2)] = id := funext hfix
        have h2 : f^[2 ^ (j + 2)] = f^[2 ^ (j + 2) - 1] ∘ f := by
          rw [← Function.iterate_succ]
          congr 1
          have := Nat.one_le_two_pow (n := j + 2)
          omega
        apply Function.Injective.of_comp (f := f^[2 ^ (j + 2) - 1])
        rw [← h2, hid]
        exact Function.injective_id
      have hfe : f 0 = f ((2 : ZMod (2 ^ (j + 2))) ^ (j + 1)) := by
        obtain ⟨b, rfl⟩ : ∃ b, a = 2 * b := ⟨a / 2, by omega⟩
        rw [hf, hf]
        push_cast
        linear_combination (-(b : ZMod (2 ^ (j + 2)))) * prn_two_pow_eq_zero j
      exact prn_two_pow_ne_zero j (hinj hfe).symm
    have hit : f^[2 ^ (j + 1)] 0 =
        ((c * ∑ i ∈ Finset.range (2 ^ (j + 1)), a ^ i : ℕ) : ZMod (2 ^ (j + 2))) := by
      rw [prn_iter _ a c f hf]
      push_cast
      ring
    have hc : c % 2 = 1 := by
      by_contra hce
      apply hhalf
      rw [hit, ZMod.natCast_eq_zero_iff]
      have hd := prn_sum_odd a ha (j + 1)
      obtain ⟨d, rfl⟩ : ∃ d, c = 2 * d := ⟨c / 2, by omega⟩
      have h2 : 2 ^ (j + 2) ∣ 2 * ∑ i ∈ Finset.range (2 ^ (j + 1)), a ^ i := by
        rw [show 2 ^ (j + 2) = 2 * 2 ^ (j + 1) by ring]
        exact mul_dvd_mul_left 2 hd
      exact h2.trans (Dvd.intro d (by ring))
    refine ⟨Nat.odd_iff.mpr hc, ?_⟩
    by_contra h4
    have h43 : a % 4 = 3 := by omega
    apply hhalf
    rw [hit, ZMod.natCast_eq_zero_iff]
    exact Dvd.dvd.mul_left (prn_sum_three_mod_four a h43 j) c
  · rintro ⟨hc, ha⟩ x
    have hS2 := prn_sum_odd a (by omega) (j + 2)
    have hper : Function.IsPeriodicPt f (2 ^ (j + 2)) x := by
      show f^[_] x = x
      rw [← sub_eq_zero, prn_iter_sub _ a c f hf]
      have h0 : (∑ i ∈ Finset.range (2 ^ (j + 2)), (a : ZMod (2 ^ (j + 2))) ^ i) = 0 := by
        have := (ZMod.natCast_eq_zero_iff _ _).mpr hS2
        push_cast at this
        exact this
      rw [h0, zero_mul]
    have hdvd := hper.minimalPeriod_dvd
    rw [Nat.dvd_prime_pow Nat.prime_two] at hdvd
    obtain ⟨i, hi, hieq⟩ := hdvd
    rw [hieq]
    by_contra hne
    have hi' : i ≤ j + 1 := by
      rcases lt_or_eq_of_le hi with h | h
      · omega
      · exact absurd (by rw [h]) hne
    have hp : Function.IsPeriodicPt f (2 ^ (j + 1)) x := by
      have : Function.minimalPeriod f x ∣ 2 ^ (j + 1) := by
        rw [hieq]; exact Nat.pow_dvd_pow 2 hi'
      exact (Function.isPeriodicPt_minimalPeriod f x).trans_dvd this
    have h1 : f^[2 ^ (j + 1)] x - x = 0 := sub_eq_zero.mpr hp
    rw [prn_iter_sub _ a c f hf] at h1
    obtain ⟨t, ht⟩ := prn_sum_one_mod_four a ha (j + 1)
    have hS : (∑ i ∈ Finset.range (2 ^ (j + 1)), (a : ZMod (2 ^ (j + 2))) ^ i) =
        2 ^ (j + 1) * (2 * t + 1) := by
      have := congrArg (Nat.cast : ℕ → ZMod (2 ^ (j + 2))) ht
      push_cast at this
      exact this
    rw [hS] at h1
    obtain ⟨r, hr⟩ : ∃ r, a = 4 * r + 1 := ⟨a / 4, by omega⟩
    obtain ⟨s, hs⟩ := hc
    rw [hr, hs] at h1
    push_cast at h1
    apply prn_two_pow_ne_zero j
    linear_combination h1 - ((t : ZMod (2 ^ (j + 2))) + (2 * t + 1) * (2 * r * x + s)) *
      prn_two_pow_eq_zero j

/-- Jumping ahead. With no increment (c = 0), n steps of x ↦ (a × x) mod m multiply the seed by
a exactly n times: from any seed x₀ (a state, so below m), the state after n steps is
aⁿ × x₀ mod m. -/
theorem lcg_no_increment_jump_ahead (m a x₀ n : ℕ) (hx : x₀ < m) :
    (fun x : ℕ => a * x % m)^[n] x₀ = a ^ n * x₀ % m := by
  induction n with
  | zero => simp [Nat.mod_eq_of_lt hx]
  | succ n ih =>
    rw [Function.iterate_succ_apply', ih, Nat.mul_mod, Nat.mod_mod, ← Nat.mul_mod, pow_succ]
    ring_nf

/-- RANDU's flaw. For RANDU, x ↦ 65539 × x mod 2³¹, take any output x and the next two, y and z.
Then 9 × x − 6 × y + z is always a multiple of 2³¹: every output is fixed by the two before it. -/
theorem randu_three_outputs_satisfy_nine_minus_six_plus_one (x : ℕ) :
    let y : ℕ := 65539 * x % 2 ^ 31
    let z : ℕ := 65539 * y % 2 ^ 31
    (2 ^ 31 : ℤ) ∣ 9 * (x : ℤ) - 6 * (y : ℤ) + (z : ℤ) := by
  intro y z
  have hy : (y : ℤ) = 65539 * x - 2 ^ 31 * ((65539 * x : ℕ) / 2 ^ 31 : ℕ) := by
    have := Nat.mod_add_div (65539 * x) (2 ^ 31)
    simp only [y]
    omega
  have hz : (z : ℤ) = 65539 * y - 2 ^ 31 * ((65539 * y : ℕ) / 2 ^ 31 : ℕ) := by
    have := Nat.mod_add_div (65539 * y) (2 ^ 31)
    simp only [z]
    omega
  rw [hz, hy]
  exact ⟨2 * x - 65533 * ((65539 * x : ℕ) / 2 ^ 31 : ℕ) - ((65539 * y : ℕ) / 2 ^ 31 : ℕ),
    by push_cast; ring⟩

-- One step of the toy generator: 5 × 7 + 3 = 38, and 38 mod 16 is 6.
example : 5 * 7 + 3 = 38 ∧ 38 % 16 = 6 ∧ 38 = 2 * 16 + 6 := by decide
-- The toy generator (5x + 3) mod 16 from seed 7: its 16 outputs, ending back at 7.
example : (List.range 16).map (fun n => (fun x : ℕ => (5 * x + 3) % 16)^[n + 1] 7) =
    [6, 1, 8, 11, 10, 5, 12, 15, 14, 9, 0, 3, 2, 13, 4, 7] := by decide
-- Its loop length is 16: 7 first comes back after 16 steps.
example : (fun x : ℕ => (5 * x + 3) % 16)^[16] 7 = 7 ∧
    ∀ n ∈ Finset.Ico 1 16, (fun x : ℕ => (5 * x + 3) % 16)^[n] 7 ≠ 7 := by decide
-- The rule for the toy generator: a = 5 leaves 1 on division by 4, and c = 3 is odd.
example : 5 % 4 = 1 ∧ 3 % 2 = 1 := by decide
-- Even increment: (5x + 2) mod 16 from 7 loops after 8. And a = 3 (remainder 3 on division
-- by 4): (3x + 3) mod 16 from 7 also loops after 8.
example : (fun x : ℕ => (5 * x + 2) % 16)^[8] 7 = 7 ∧
    ∀ n ∈ Finset.Ico 1 8, (fun x : ℕ => (5 * x + 2) % 16)^[n] 7 ≠ 7 := by decide
example : (fun x : ℕ => (3 * x + 3) % 16)^[8] 7 = 7 ∧
    ∀ n ∈ Finset.Ico 1 8, (fun x : ℕ => (3 * x + 3) % 16)^[n] 7 ≠ 7 := by decide
-- Brute force for m = 16: for every pair a, c from 0 to 15, 0 first comes back at step 16
-- exactly when the rule holds, and the rule picks out 32 of the 256 pairs.
example : ∀ a ∈ Finset.range 16, ∀ c ∈ Finset.range 16,
    (((fun x : ℕ => (a * x + c) % 16)^[16] 0 = 0 ∧
        ∀ n ∈ Finset.Ico 1 16, (fun x : ℕ => (a * x + c) % 16)^[n] 0 ≠ 0) ↔
      (c % 2 = 1 ∧ a % 4 = 1)) := by decide
example : ((Finset.range 16 ×ˢ Finset.range 16).filter
      (fun p : ℕ × ℕ => p.2 % 2 = 1 ∧ p.1 % 4 = 1)).card = 32 := by decide
-- A full loop is not randomness: a = 1, c = 1 counts 8, 9, 10, 11, 12, 13.
example : (List.range 6).map (fun n => (fun x : ℕ => (x + 1) % 16)^[n] 8) =
    [8, 9, 10, 11, 12, 13] := by decide
-- The toy's consecutive pairs (x, y) lie on four lines: x + 3y is 9, 25, 41 or 57.
example : ∀ x ∈ Finset.range 16, (x + 3 * ((5 * x + 3) % 16)) % 16 = 9 ∧
    x + 3 * ((5 * x + 3) % 16) ∈ ({9, 25, 41, 57} : Finset ℕ) := by decide
-- Its last bit alternates 0, 1, 0, 1 along the stream 6, 1, 8, 11, ...
example : (List.range 12).map (fun n => (fun x : ℕ => (5 * x + 3) % 16)^[n + 1] 7 % 2) =
    [0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1] := by decide
-- RANDU: 65539 = 2^16 + 3, and a² leaves the same remainder as 6a − 9 on division by 2^31.
example : 65539 = 2 ^ 16 + 3 ∧ 65539 ^ 2 % 2 ^ 31 = (6 * 65539 - 9) % 2 ^ 31 := by norm_num
-- minstd, a = 16807, m = 2^31 − 1, seed 1: the 10,000th state is 1043618065, by stepping
-- 10,000 times and by jumping straight there with a^10000 × 1 mod m.
example : (fun x : ℕ => 16807 * x % (2 ^ 31 - 1))^[10000] 1 = 1043618065 := by decide +kernel
example : 16807 ^ 10000 * 1 % (2 ^ 31 - 1) = 1043618065 := by decide +kernel

#print axioms lcg_full_cycle_iff_c_odd_and_a_one_mod_four
#print axioms lcg_no_increment_jump_ahead
#print axioms randu_three_outputs_satisfy_nine_minus_six_plus_one
```

**Checked 2026-11-13 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'prn_sum_double' depends on axioms: [propext, Classical.choice, Quot.sound]
'prn_sum_one_mod_four' depends on axioms: [propext, Classical.choice, Quot.sound]
'prn_sum_odd' depends on axioms: [propext, Classical.choice, Quot.sound]
'prn_sum_three_mod_four' depends on axioms: [propext, Classical.choice, Quot.sound]
'prn_iter' depends on axioms: [propext, Classical.choice, Quot.sound]
'prn_iter_sub' depends on axioms: [propext, Classical.choice, Quot.sound]
'prn_two_pow_ne_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'prn_two_pow_eq_zero' depends on axioms: [propext, Quot.sound]
'lcg_full_cycle_iff_c_odd_and_a_one_mod_four' depends on axioms: [propext, Classical.choice, Quot.sound]
'lcg_no_increment_jump_ahead' depends on axioms: [propext, Quot.sound]
'randu_three_outputs_satisfy_nine_minus_six_plus_one' depends on axioms: [propext, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **An even increment.** In the toy line, change `lcg(5, 3, 16, 7, 16)` to `lcg(5, 2, 16, 7, 16)`. Guess the outputs: 5, 11, 9, 15, 13, 3, 1, 7, then the same eight again. The full-loop assert stops the run.
> - **A third modulus for the rule.** Change `(16, 64)` to `(16, 32, 64)`. Guess the count for 32: 8 multipliers times 16 odd increments, 128, and brute force agrees.
> - **Replace RANDU's multiplier.** Change `lcg(65539, ...` to `lcg(69069, ...` (a well-studied multiplier). The triples on planes drop from 10,000 to 0, and the planes assert stops the run.
> - **Move the table value.** Change `pvalue(16.919)` in the chi-square print to `pvalue(14.684)`, the 10% point for 9 degrees of freedom: it prints 0.1000.

---

## The usual mistake

> [!warning]
> **Treating a passed test as proof of randomness.** A test answers one narrow question. RANDU passes the ten-bin test with p = 0.4548, while every one of its 10,000 triples sits on one of 15 planes. A simulation of points in a cube driven by RANDU gives wrong answers that no single-draw test would catch.
>
> - **Treating one failed test as proof of a bad generator.** MT19937 scores p = 0.0319 from seed 20260929; across seeds 1 to 100 it falls below 0.05 in 5 runs, exactly the one in twenty a 5% test allows.
> - **Seeding streams with neighbouring numbers.** With minstd, seed 2 gives exactly twice seed 1's stream, mod $m$: the "independent" runs are tied together in 1000 of 1000 outputs. Take separate stretches by jumping ahead, or use a generator built for splitting.
> - **Taking low bits from a power-of-2 LCG.** The toy generator's last bit runs 0, 1, 0, 1. Dice made by `x mod 6` from such a generator inherit the pattern; use the high bits, as $u_n = x_n / m$ does.
> - **Re-running with new seeds until the answer looks right.** Each seed gives a legitimate run; choosing among them afterwards is running many tests and reporting one ([Many tests](../08-Confidence%20Intervals%20and%20Tests/08-multiple-testing.md)).
> - **Using a simulation generator for secrets.** MT19937's state can be rebuilt from 624 consecutive outputs, after which every later output is known. Passwords and keys need a cryptographic generator.

---

## Where you meet it in real life

- **Published research.** A simulation study that states its generator and seed can be re-run by a referee to the last digit; more on seeds and parallel streams: [Seeds](../../14-Applied%20and%20computational/08-Scientific%20Computing%20Practice/03-reproducible-simulation-and-seeds.md).
- **Monte Carlo estimates.** Every estimate on [Monte Carlo](04-monte-carlo-estimates-and-error.md), and every simulated option price in the finance wing, is only as good as the uniform draws underneath it.
- **Games.** A video game that builds its world from a seed builds the same world for every player who types that seed, because the terrain is a generator's stream.
- **Shuffling and sampling.** Dealing a card game or picking a random sample of records draws from a generator; [Fair choices from a list you cannot hold](../../14-Applied%20and%20computational/02-Randomised%20and%20Approximate%20Algorithms/03-shuffling-and-reservoir-sampling.md) shows how to do it fairly.
- **Software testing.** Random-input tests print their seed on failure, so the failing case replays exactly.

> **Say it back**
> A computer makes random-looking numbers by applying a fixed rule to a hidden number, again and again. The seed is the starting number, so the same seed replays the same stream: that is what makes a simulation repeatable. The simplest rule, multiply, add and keep the remainder, visits every state before repeating exactly when the increment is odd and the multiplier leaves 1 on division by 4. Visiting every state is not randomness: such streams line up on lines and planes, and their low bits repeat quickly. A generator is trusted after tests aimed at many patterns, knowing a sound one still fails a 5% test one time in twenty.

---

## What this builds on

- [Uniform](../04-Continuous%20Distributions/02-uniform-distribution.md): the flat law on 0 to 1 that every generator imitates, and the bin shares it predicts.
- [Congruence](../../02-Number%20theory/03-Clock%20Arithmetic/01-congruence-mod-n.md): remainders and the ≡ sign that the generator's rule and the full-cycle proof are written in.

## Where this goes next

- [Inverse transform](02-inverse-transform-sampling.md): turning uniform draws into draws from any other law.
- [Monte Carlo](04-monte-carlo-estimates-and-error.md): why the dart estimate's error shrinks like one over the square root of the number of darts.
- [Randomised algorithms](../../14-Applied%20and%20computational/02-Randomised%20and%20Approximate%20Algorithms/01-randomised-algorithms-and-expectation.md): algorithms that flip coins to run faster, and what their average cost means.
- [Fair choices from a list you cannot hold](../../14-Applied%20and%20computational/02-Randomised%20and%20Approximate%20Algorithms/03-shuffling-and-reservoir-sampling.md): fair shuffles and samples built from a generator's draws.
- [Seeds](../../14-Applied%20and%20computational/08-Scientific%20Computing%20Practice/03-reproducible-simulation-and-seeds.md): seeds, parallel streams and version pinning in practice.
- Pseudorandomness: when a fixed rule can provably replace true randomness.

A generator hands out flat draws between 0 and 1, but a simulation needs waiting times, heights and prices with other shapes; [Inverse transform](02-inverse-transform-sampling.md) turns one into the other.

---

## Sources

Verified 2026-09-29: every link below resolves to the publisher's page or, for the standard, the committee's own document.

- Knuth, Donald E. *The Art of Computer Programming, Volume 2: Seminumerical Algorithms*, 3rd ed. Addison-Wesley, 1997. [Publisher page](https://www.informit.com/store/art-of-computer-programming-volume-2-seminumerical-algorithms-9780201896848). Chapter 3: the full-cycle theorem for linear congruential generators, the chi-square test, the spectral test and RANDU's planes.
- Hull, T. E., and A. R. Dobell. "Random number generators." *SIAM Review* 4, no. 3 (1962). [DOI 10.1137/1004061](https://doi.org/10.1137/1004061). The full-cycle rule.
- Marsaglia, George. "Random numbers fall mainly in the planes." *Proceedings of the National Academy of Sciences* 61, no. 1 (1968). [DOI 10.1073/pnas.61.1.25](https://doi.org/10.1073/pnas.61.1.25). Consecutive LCG outputs lie on few planes.
- Park, Stephen K., and Keith W. Miller. "Random number generators: good ones are hard to find." *Communications of the ACM* 31, no. 10 (1988). [DOI 10.1145/63039.63042](https://doi.org/10.1145/63039.63042). The minimal standard generator and its check value 1043618065.
- Matsumoto, Makoto, and Takuji Nishimura. "Mersenne twister: a 623-dimensionally equidistributed uniform pseudo-random number generator." *ACM Transactions on Modeling and Computer Simulation* 8, no. 1 (1998). [DOI 10.1145/272991.272995](https://doi.org/10.1145/272991.272995). MT19937 and the proof of its period.
- Steele, Guy L., Doug Lea, and Christine H. Flood. "Fast splittable pseudorandom number generators." OOPSLA 2014. [DOI 10.1145/2660193.2660195](https://doi.org/10.1145/2660193.2660195). The SplitMix64 generator used in the checks on this wing.
- ISO/IEC JTC1/SC22/WG21. *Working Draft, Standard for Programming Language C++*, N4861, 2020. [Committee document](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2020/n4861.pdf). Section [rand.predef] fixes the 10,000th outputs of minstd_rand0 (1043618065) and mt19937 (4123659995).
