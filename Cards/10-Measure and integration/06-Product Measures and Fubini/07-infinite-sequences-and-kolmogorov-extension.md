# Infinitely many coin tosses: build them from one uniform number, and Kolmogorov's theorem for every other infinite sequence

[Syllabus](../../../SYLLABUS.md) → [Measure and integration](../README.md) → [Product Measures and Fubini](../README.md#s06) → Infinitely many coin tosses

---

## General Overview

A dart lands on a 1 m by 1 m board, 0.7236 m from the left edge, every point equally likely. Write that distance in binary, the base-2 system of 0s and 1s: 0.1011100100111101… Each digit answers one yes-or-no question. The first says whether the dart is in the right half of the edge (1) or the left (0). The second says which half of that half, and so on forever.

The laws of large numbers talk about a coin tossed forever. "The share of heads tends to one half" is a statement about all the tosses at once, so it needs one probability governing an endless sequence. A simulation of a few thousand tosses never needs that. A proof does. Where does such a probability come from?

From the dart. Measured by length, the digits of one uniform point are independent fair coin tosses. Deal the digits into infinitely many separate piles and each pile spells a new uniform number, independent of the others. Two uniforms make a new dart; any other law comes from a uniform through its quantile map, the inverse of its distribution function. For sequences whose terms depend on each other, Kolmogorov's extension theorem does the building, provided the laws of the first few terms fit together.

**Under length on the unit interval, the binary digits of one uniform point are independent fair coin tosses; regrouping them gives infinitely many independent uniforms, hence independent draws of any law, and Kolmogorov's theorem builds any sequence whose laws for the first n terms agree with one another.**

**What kind of fact this is:** three theorems. The digit theorem and the splitting theorem are proved on this card in Why it works. Kolmogorov's extension theorem is stated precisely; its proof is outlined in a folded note and given in full by Billingsley and Durrett (Sources).

### The picture: three digits, three fair coins

Each row is the bottom edge of the board, 0 to 1 m, shaded where one digit equals 1. Every row shades exactly half the edge, in 1, 2 and 4 pieces. Two rows overlap in a quarter; all three in an eighth, the last piece. The dashed line is the dart at 0.7236 m: shaded in rows 1 and 3, not in row 2, so its first three digits are 1, 0, 1. Drawn to scale.

<p align="center"><img src="../figures/infinite-sequences-and-kolmogorov-extension.svg" alt="The unit interval drawn three times; each copy shades where one binary digit of the position equals 1, in one, two and four pieces; a dashed line marks the dart at 0.7236 m" width="420"></p>

---

## The formula

Notation first, in words. $\Omega$ is the bottom edge of the board, the interval from 0 up to but not including 1, and $\lambda$ is length on it: Lebesgue measure ([Lebesgue measure](../02-Length%20Done%20Properly/03-lebesgue-measure.md)). A uniform dart is a point drawn with probability $\lambda$. The n-th binary digit of a point x is $d_n$: double x n times, keep the whole-number part, and read whether it is odd.

$$d_n(x) = \lfloor 2^n x \rfloor \bmod 2$$

Here $\lfloor y \rfloor$ is the whole-number part of y, and "mod 2" is the remainder on division by 2.

**The digit theorem.** For every n and every pattern of 0s and 1s $e_1, \dots, e_n$:

$$\lambda\{x : d_1(x) = e_1, \dots, d_n(x) = e_n\} = 2^{-n} = \prod_{i=1}^{n} \lambda\{x : d_i(x) = e_i\}$$

**Read it aloud:** any fixed pattern in the first n digits has chance one half multiplied by itself n times, the product of the digits' separate chances; so the digits are independent fair coins.

**The splitting theorem.** Every whole number n ≥ 1 is a power of 2 times an odd number in exactly one way, $n = 2^{k-1}(2j - 1)$. Call (k, j) the slot of position n. Pile k collects the digits in slots (k, 1), (k, 2), (k, 3), … and reads them as a new binary number:

$$U_k = \sum_{j=1}^{\infty} d_{2^{k-1}(2j-1)}\, 2^{-j}, \qquad k = 1, 2, 3, \dots$$

**Read it aloud:** the k-th new number takes as its j-th digit the old digit in slot (k, j).

Then $U_1, U_2, U_3, \dots$ are independent and each is uniform on the unit interval. For any distribution function $F$ with quantile map $Q(u) = \inf\{t : F(t) \ge u\}$ for 0 < u < 1, the draws $X_k = Q(U_k)$ are independent, each with law $F$ ([The law of a random variable](../03-Measurable%20Functions/05-pushforward-and-the-law.md)). The pairs $(U_1, U_2), (U_3, U_4), \dots$ are independent darts on the board.

**Kolmogorov's extension theorem.** For every n let $\mu_n$ be a probability on the Borel sets of $\mathbb{R}^n$, the n-long lists of reals. The family is **consistent** when adding a coordinate and asking nothing of it changes nothing:

$$\mu_{n+1}(A \times \mathbb{R}) = \mu_n(A) \quad \text{for every } n \text{ and every Borel set } A \subseteq \mathbb{R}^n$$

Then there is exactly one probability $P$ on the whole sequences $\mathbb{R}^{\mathbb{N}}$, with the product sigma-algebra, such that

$$P\{\omega : (\omega_1, \dots, \omega_n) \in A\} = \mu_n(A) \quad \text{for every } n \text{ and every Borel set } A \subseteq \mathbb{R}^n$$

**Read it aloud:** if the laws of the first n terms fit together, one law for the whole infinite sequence has all of them as its pieces.

The product sigma-algebra is the smallest sigma-algebra holding every **cylinder set**: a set that constrains only the first n coordinates, for some n, and leaves the rest free ([Product sigma-algebras](01-product-sigma-algebras.md)).

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $\Omega$, $\lambda$ | the unit interval and length on it | the board's bottom edge, 1 m | — |
| $x$ | the dart's distance from the left edge | 0.7236 m | its digits change |
| $d_n$, $n$ | the n-th binary digit of x, and its position | digits 1, 0, 1, 1 | a later digit halves a finer interval |
| $e_1$, $e_n$ | a fixed pattern of 0s and 1s to match | 1, 0, 1 | a longer pattern halves the chance each time |
| $U_k$, $k$, $j$ | the k-th new uniform; pile number, and place inside the pile | U_1 = 0.900990 | a higher k takes sparser positions |
| $F$, $Q$ | a distribution function, and its quantile map | a fair die: Q(u) = ⌊6u⌋ + 1 a.e. | a larger u gives a larger value |
| $X_k$ | the k-th draw with law F | die rolls 6, 1, 6, 5 | — |
| $\mu_n$ | the law of the first n terms, a probability on n-long lists | sticky coin: 0.32 on three heads | — |
| $A$ | a Borel set of n-long lists | "heads, heads, heads" | a bigger A has a bigger chance |
| $P$, $\omega$, $\omega_i$ | the law of the whole sequence; one sequence; its i-th term | all sticky-coin sequences | — |
| $T$, $J$, $\mu_J$ | any index set; a finite part of it; the law on the coordinates in J | T = the whole numbers | — |
| $A_k$, $B_i$, $C_i$, $D_m$ | sets used inside the folded proofs | — | — |
| $r$, $N$, $m$, $i$, $\varepsilon$, $s(k, j)$ | in the steps and proofs: how many positions are fixed, and the last of them; the whole number a pattern spells (Step 1), later how many digits of a pile are read, with i the number they spell; a small positive floor on chances; the position in slot (k, j), $2^{k-1}(2j-1)$ | positions 2, 5, 7: r = 3, N = 7; pattern 1, 0, 1: m = 5; s(2, 3) = 10 | — |

### When it holds

- **The dart is uniform.** A dart whose density is 2x, rising towards the right, has first digit 1 with chance 0.75, and both of the first two digits are 1 with chance 0.4375, not 0.75 × 0.625 = 0.46875.
- **The piles share no digits.** U built from digits 1, 2, 3, … and V from digits 2, 3, 4, … are correlated at 0.5.
- **The finite laws are consistent.** "Uniform over the words with an even number of heads" gives the first toss heads with chance 0 on one toss and 0.5 on two; no P has both as pieces.
- **Coordinates are real, or live in a space like the reals.** The existence proof uses that a probability on n-long lists of reals sits almost entirely on a closed, bounded set. On arbitrary coordinate spaces the theorem can fail.
- **Questions touch countably many coordinates.** Any index set $T$ works, with laws $\mu_J$ on each finite part $J$ that agree whenever coordinates are dropped. But every event of the product sigma-algebra depends on countably many coordinates, so for a process in continuous time "the path is continuous" is not an event. Brownian motion, in wing 11, needs a further step.

---

## Why it works

### Step 0: a pattern in the first n digits is one interval of length 2^-n

Fixing the first digit to 1 keeps the right half of the edge. Fixing the second to 0 keeps the left half of that. Each fixed digit halves an interval, so n fixed digits leave one interval of length $2^{-n}$. Halving multiplies lengths, and so the chances multiply. The rest is bookkeeping about which digits are fixed.

### Step 1: the digit events, exactly

Read $e_1 e_2 \dots e_n$ as a whole number m in binary. The first n digits of x match exactly when $\lfloor 2^n x \rfloor = m$: when x lies from $m/2^n$ up to but not including $(m+1)/2^n$, an interval of length $2^{-n}$.

The dart: doubling 0.7236 gives 1.4472, so the first digit is 1; keep 0.4472 and double to 0.8944, digit 0; then 1.7888, digit 1; then 1.5776, digit 1. The pattern 1, 0, 1 is m = 5 with n = 3, the interval from 5/8 = 0.625 up to 6/8, and 0.7236 is inside it.

### Step 2: any finite set of digits multiplies

Fix positions 2, 5 and 7 to 1, 0, 1 and leave the rest free. The four free positions among the first seven each take 0 or 1, so the event is 2^4 = 16 disjoint intervals of length 2^-7: 16/128 = 0.125 = 0.5^3.

In general, r fixed positions, the last at position N, give 2^(N−r) intervals of length 2^-N: chance 2^-r, the product of r halves. A digit's information is the four sets ∅, "digit is 0", "digit is 1" and the whole edge, and the product rule on every finite subfamily of such events is the definition of independence ([Independence as a product](04-independence-as-a-product-measure.md)). So $d_1, d_2, d_3, \dots$ are independent fair coins. The code checks all 8,190 patterns of length 1 to 12.

A point such as 0.5 has two binary expansions, 0.1000… and 0.0111…; the rule above always picks the first. Such points are fractions with a power of 2 below the line, countably many, so their total length is 0 and no chance on this card changes.

### Step 3: deal the digits into infinitely many piles

The slot rule pairs positions with pairs (k, j) one-to-one: strip every factor 2 from n, count them to get k − 1, and the odd number left is 2j − 1. That the pairs of whole numbers can be listed one-to-one against the whole numbers is [Countable sets](../../01-Foundations/09-Sizes%20of%20Infinity/02-countable-sets.md). Pile 1 takes the odd positions 1, 3, 5, …; pile 2 takes 2, 6, 10, …; pile 3 takes 4, 12, 20, …; pile 4 takes 8, 24, 40, …

The dart's first sixteen positions go to piles 1 2 1 3 1 2 1 4 1 2 1 3 1 2 1 5. Twenty digits from each of the first four piles give U_1 = 0.900990, U_2 = 0.107787, U_3 = 0.959763 and U_4 = 0.764359.

### Step 4: each pile is a uniform number

The digits of pile k are a subsequence of independent fair coins, so any pattern in its first m digits has chance $2^{-m}$. So $U_k$ lands in each interval from $i/2^m$ to $(i+1)/2^m$ with chance equal to its length. These dyadic intervals are nested or disjoint, so with ∅ they form a pi-system, a family closed under overlap, and they generate the Borel sets. Two probabilities that agree on a generating pi-system agree everywhere ([Pi-systems and Dynkin's theorem](../01-Sets%20You%20Can%20Measure/06-pi-systems-and-uniqueness.md)), so the law of $U_k$ is length.

### Step 5: different piles are independent

Events about the first m digits of different piles fix disjoint sets of old digits, so by Step 2 their chances multiply. Such events generate each pile's information, and independence checked on generating pi-systems passes to the whole sigma-algebras ([Independence as a product](04-independence-as-a-product-measure.md)).

The code checks this at level 12. The first 12 old digits give pile 1 six digits, pile 2 three, pile 3 two and pile 4 one: 64 × 8 × 4 × 2 = 4096 value combinations. The 4096 intervals of length 1/4096 produce every combination exactly once, which is the product law.

<details>
<summary>Detailed proof: the piles are independent uniforms</summary>

**Setting.** $\lambda$ on the Borel sets of $\Omega$; the $d_n$ are independent fair coins (Step 2); $s(k, j) = 2^{k-1}(2j-1)$ is one-to-one from pairs onto positions.

**1. Each $U_k$ is measurable.** Its partial sums are step functions, and a limit of measurable functions is measurable ([Sums, products, sups and limits](../03-Measurable%20Functions/02-limits-of-measurable-functions.md)).

**2. Each $U_k$ is uniform.** Let $D_m$ be the event that every pile-k digit after the m-th is 1. It lies inside "pile digits m + 1 to r are all 1", of chance $2^{-(r-m)}$ for every r, so it is null, and so is the union over m. Off that null set, $U_k \in [i/2^m, (i+1)/2^m)$ exactly when the first m pile digits spell i, of chance $2^{-m}$ by Step 2. The law of $U_k$ and $\lambda$ agree on the dyadic intervals, a pi-system generating the Borel sets, and both have total 1; the uniqueness theorem makes them equal.

**3. $U_1, \dots, U_r$ are independent.** For each k let the events "the first m digits of pile k spell i", over all m and i, with ∅ and $\Omega$, be the family for pile k. It is closed under overlap and generates the information of pile k's digits, which contains that of $U_k$. Pick $A_k$ from the family for pile k, for k = 1 to r. The overlap of the $A_k$ fixes old digits in distinct slots, so by Step 2 its chance is the product of their chances. Independence on generating pi-systems gives independence of the information of $U_1, \dots, U_r$, by the Dynkin argument of [Independence as a product](04-independence-as-a-product-measure.md) applied one family at a time, the other r − 1 events held fixed; an infinite family is independent when every finite part is.

**4. Other laws, and darts.** $Q$ is non-decreasing, so measurable, and $Q(U_k)$ has law F ([The law of a random variable](../03-Measurable%20Functions/05-pushforward-and-the-law.md)). The event $Q(U_k) \in B$ is the event $U_k \in Q^{-1}(B)$, so functions of independent variables stay independent. The pairs of uniforms have law length times length on the square ([Product measure](02-product-measure.md)).

</details>

### Step 6: any law, and more darts

For a fair die, $Q(u) = \lfloor 6u \rfloor + 1$ except at the five points where 6u is whole, a set of length 0, and the dart's four uniforms roll 6, 1, 6, 5. Paired, they are dart 1 at (0.900990, 0.107787) and dart 2 at (0.959763, 0.764359). One throw has become a sequence of independent throws.

### Step 7: Kolmogorov's theorem, when the terms depend on each other

A **sticky coin** is fair on the first toss; each later toss repeats the one before with chance 0.8. Its law for three tosses gives heads three times the chance 0.5 × 0.8 × 0.8 = 0.32. Summing its law for n + 1 tosses over the last toss returns its law for n tosses; the code checks every pattern up to length 10. That is consistency, and the theorem gives one law P on all infinite toss sequences.

Consistency is also necessary. If P exists, "the first n terms lie in A" and "the first n + 1 terms lie in A × ℝ" are the same set, so both laws must give it one number. The even-heads family gives 0 and 0.5, so no P exists for it.

Uniqueness is Step 4's argument again: cylinder sets form a pi-system generating the product sigma-algebra. Existence is the hard half. Set P on each cylinder set by its $\mu_n$, which consistency makes unambiguous, and extend. The extension needs countable additivity on cylinder sets, and that is where real coordinates matter.

<details>
<summary>Detailed proof, in outline: Kolmogorov's extension theorem</summary>

Full proofs: Billingsley, Section 36; Durrett, Theorem A.3.1.

**1. Cylinder sets form an algebra**, closed under complements and finite unions: two of them can be written over a common n, where union and complement act on Borel sets of $\mathbb{R}^n$.

**2. P is well defined and finitely additive there.** A cylinder set with base A over n has base A × ℝ over n + 1, and consistency gives the same value. Disjoint cylinder sets over a common n have disjoint bases.

**3. P is countably additive there.** It suffices that cylinder sets $B_1 \supseteq B_2 \supseteq \dots$ with every $P(B_i) \ge \varepsilon > 0$ share a point. For if disjoint cylinder sets $A_1, A_2, \dots$ have a cylinder set $A$ as their union, the sets $B_i = A \setminus (A_1 \cup \dots \cup A_i)$ decrease and share no point, and finite additivity gives $P(A) = P(A_1) + \dots + P(A_i) + P(B_i)$; so countable additivity is exactly $P(B_i) \to 0$. A probability on $\mathbb{R}^n$ gives each Borel set nearly its full size on a closed, bounded subset (proved in Billingsley). Shrink the base of $B_i$ that way, losing less than $\varepsilon/2^{i+1}$, and intersect the first i shrunken sets to get $C_i$ inside $B_i$ with $P(C_i) > \varepsilon/2$, so $C_i$ holds a point. Each coordinate of these points stays in a closed, bounded set, so a diagonal choice of subsequences, as in Cantor's diagonal argument, makes every coordinate converge. The limit lies in every $C_i$, since the bases are closed, hence in every $B_i$.

**4. Extend** to the product sigma-algebra ([Caratheodory's extension theorem](../02-Length%20Done%20Properly/05-caratheodory-extension-theorem.md)).

**5. Unique**, since cylinder sets are a generating pi-system ([Pi-systems and Dynkin's theorem](../01-Sets%20You%20Can%20Measure/06-pi-systems-and-uniqueness.md)).

Only item 3 uses real coordinates. For an arbitrary index set $T$ the proof runs on finite parts $J$, since each cylinder set involves finitely many coordinates.

</details>

The sticky coin also has a road back to the dart: toss 1 is heads when $U_1 < 0.5$, and toss k + 1 repeats toss k when $U_{k+1} < 0.8$. Any sequence whose next term has a stated law given the past can be built by such conditional quantile maps; that is the Ionescu-Tulcea theorem. Kolmogorov's theorem asks only for the consistent laws of the first n terms.

**What the code shows, and what only the proof shows.** The code checks every digit pattern of length at most 12, twenty digits of four piles, sticky-coin consistency up to 10 tosses, and 200,000 simulated darts. That every digit of every point behaves, and that every consistent family has a P, only the proofs cover.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| first digits of the dart | double 0.7236: 1.4472, 0.8944, 1.7888, 1.5776 | 1, 0, 1, 1 |
| the interval for 1, 0, 1 | 5/8 up to 6/8 | contains 0.7236 |
| digits 2, 5, 7 read 1, 0, 1 | 16 intervals of length 1/128 | **0.125 = 0.5^3** |
| piles of the first 16 positions | strip factors of 2 | 1 2 1 3 1 2 1 4 1 2 1 3 1 2 1 5 |
| the first four uniforms | 20 digits from each pile | 0.900990, 0.107787, 0.959763, 0.764359 |
| die rolls | ⌊6U⌋ + 1 | **6, 1, 6, 5** |
| sticky coin, three heads | 0.5 × 0.8 × 0.8 | **0.32** |

One dart at 0.7236 m has become two independent darts, four independent die rolls, and the start of a sticky-coin sequence, with infinitely many more to come.

### What breaks if you drop a piece

The shared-digit case takes one line of algebra. If U reads digits 1, 2, 3, … and V reads 2, 3, 4, …, then V = 2U − d_1. A uniform has variance 1/12 = 0.083333. U times d_1 averages 3/8, the area under x from 0.5 to 1, so their covariance is 3/8 − 1/4 = 0.125. The covariance of U and V is 2 × 0.083333 − 0.125 = 0.041667; divided by their common variance 0.083333, correlation 0.5.

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Two piles share digits: U from 1, 2, 3, …, V from 2, 3, 4, … | correlation 0.497050 on 4 digits, 0.500000 on 12; limit 0.5 | V = 2U − d_1 is built from U |
| A dart with density 2x | P(d_1 = 1) = 0.75; first two digits both 1 with 0.4375, not 0.46875 | length no longer splits evenly |
| An inconsistent family: uniform over words with an even number of heads | first toss heads: 0 on one toss, 0.5 on two | no single P has both as pieces |

The code prints all three.

---

## Code, from first principles, and it actually runs

Three roads. Road 1 reads the dart's digits by exact doubling and deals them into piles twice: by the slot rule, and by slicing every second, fourth, eighth and sixteenth digit. Road 2 counts the 4,096 intervals of length 1/4096 and sets every digit pattern against the product rule 0.5^n; it also counts the pile combinations, the three breaks and both families' consistency. Road 3 simulates 200,000 darts with SplitMix64, a small random-number generator written out in both languages, seed 20260929. Each dart holds 128 binary digits, so the four piles get 64, 32, 16 and 8; U4 is then a multiple of 1/256, so "top half" is tested as U4 ≥ 0.5, of chance exactly 0.5. Asserts on simulated numbers allow four standard errors; the largest miss, the three-uniform event, is about 1.3.

### Python

```python
# Infinitely many coin tosses from one dart -- the check behind the card.
# Standard library only.  Roads: (1) one dart x = 0.7236 m, its digits read by
# exact doubling and split two ways; (2) Lebesgue measure of digit events,
# counted exactly on the 4,096 dyadic cells of level 12 and set against the
# product rule 0.5^n; (3) a simulation: SplitMix64, seed 20260929, 200,000
# darts, each x held to 128 binary digits.
from fractions import Fraction as Fr
def digits(p, q, n):                         # first n binary digits of p/q, by doubling
    out = []
    for _ in range(n):
        p *= 2
        out.append(1 if p >= q else 0)
        p -= q * out[-1]
    return out
def slot(n):                                 # position n = 2^(k-1) * (2j - 1)  ->  (k, j)
    k = 1
    while n % 2 == 0:
        n, k = n // 2, k + 1
    return k, (n + 1) // 2
def split(ds, count):                        # U_k = sum of digit(slot (k, j)) / 2^j
    u = [Fr(0)] * count
    for n, d in enumerate(ds, start=1):
        k, j = slot(n)
        if k <= count:
            u[k - 1] += Fr(d, 2 ** j)
    return u
def dec(v): return f"{float(v):.6f}"
# ---- road 1: one dart ----
ds = digits(1809, 2500, 320)                 # x = 0.7236 = 1809/2500
y, dbl = Fr(1809, 2500), []
for _ in range(4):
    y = 2 * y; dbl.append(f"{float(y):.4f}"); y -= int(y)
print("doubling 0.7236 four times:", ", ".join(dbl))
print("dart x = 0.7236 m, binary digits 1-16:", " ".join(map(str, ds[:16])))
print("position 1-16 goes to uniform k:     ", " ".join(str(slot(n)[0]) for n in range(1, 17)))
U = split(ds, 4)
by_slicing = [sum(Fr(d, 2 ** (j + 1)) for j, d in enumerate(ds[2 ** k - 1::2 ** (k + 1)][:20])) for k in range(4)]
print("U1..U4 from 20 digits each:", ", ".join(dec(v) for v in by_slicing))
print(f"dart 1 = (U1, U2) = ({dec(by_slicing[0])}, {dec(by_slicing[1])}); dart 2 = (U3, U4) = ({dec(by_slicing[2])}, {dec(by_slicing[3])})")
print("die rolls floor(6U) + 1:", [int(6 * v) + 1 for v in by_slicing])
assert all(abs(U[k] - by_slicing[k]) < Fr(1, 2 ** 20) for k in range(4))   # two readings of the split
x_px = 30 + 300 * Fr(1809, 2500)
print(f"figure, x scale 30 + 300x px; dart at {float(x_px):.2f} px; digit-1 cells row 1 [0.5,1], row 2 [0.25,0.5] [0.75,1], row 3 [0.125,0.25] [0.375,0.5] [0.625,0.75] [0.875,1]")
# ---- road 2: Lebesgue measure on the 4,096 cells of level 12 ----
M = 12
cells = [digits(2 * i + 1, 2 ** (M + 1), M) for i in range(2 ** M)]      # digits of each cell's midpoint
worst = Fr(0)
for n in range(1, M + 1):
    tally = {}
    for c in cells:
        tally[tuple(c[:n])] = tally.get(tuple(c[:n]), 0) + 1
    assert len(tally) == 2 ** n
    worst = max([worst] + [abs(Fr(t, 2 ** M) - Fr(1, 2) ** n) for t in tally.values()])
print(f"all 8,190 words of lengths 1 to 12: measure = 0.5^n, largest gap {worst}")
pair = Fr(sum(1 for c in cells if c[1] == 1 and c[4] == 0 and c[6] == 1), 2 ** M)
print(f"P(d2 = 1, d5 = 0, d7 = 1) = {float(pair)} by counting cells; 0.5^3 = {0.5 ** 3}")
combos = {tuple(split(c, 4)) for c in cells}
print(f"U1..U4 read from 12 digits: 64 x 8 x 4 x 2 = {64 * 8 * 4 * 2} value combinations, {len(combos)} distinct, each measure 1/4096")
rect = Fr(sum(1 for c in cells if split(c, 2)[0] < Fr(1, 2) and split(c, 2)[1] < Fr(1, 4)), 2 ** M)
print(f"P(U1 < 0.5, U2 < 0.25) = {float(rect)} by counting cells; 0.5 x 0.25 = {0.5 * 0.25}")
assert worst == 0 and pair == Fr(1, 8) and len(combos) == 4096 and rect == Fr(1, 2) * Fr(1, 4)
# ---- what breaks ----
for m in (4, 8, 12, 16):                     # U from digits 1..m, V from digits 2..m: a reused digit
    us, vs = [], []
    for i in range(2 ** m):
        c = digits(2 * i + 1, 2 ** (m + 1), m)
        us.append(sum(Fr(d, 2 ** (j + 1)) for j, d in enumerate(c)))
        vs.append(sum(Fr(d, 2 ** j) for j, d in enumerate(c) if j >= 1))
    N = 2 ** m; mu, mv = sum(us) / N, sum(vs) / N
    cov = sum((a - mu) * (b - mv) for a, b in zip(us, vs)) / N
    vu, vv = sum((a - mu) ** 2 for a in us) / N, sum((b - mv) ** 2 for b in vs) / N
    corr = float(cov) / (float(vu) * float(vv)) ** 0.5
    print(f"shifted digits, m = {m:2d}: correlation of U and V = {corr:.6f}")
var, cov_d1 = Fr(1, 12), Fr(3, 8) - Fr(1, 2) * Fr(1, 2)   # Var U; Cov(U, d1) = E[U d1] - E[U] E[d1]
limit = (2 * var - cov_d1) / var             # V = 2U - d1, worked on the card
print(f"shifted digits, by hand: Var U = {dec(var)}, Cov(U, d1) = {dec(cov_d1)}, Cov(U, V) = {dec(2 * var - cov_d1)}, limit {float(limit)}")
assert abs(corr - float(limit)) < 1e-3
cdf = lambda a: a * a                        # a dart with density 2x: P(x <= a) = a^2
anti = [1 - cdf(Fr(1, 2)), cdf(Fr(1, 2)) - cdf(Fr(1, 4)) + 1 - cdf(Fr(3, 4)), 1 - cdf(Fr(3, 4))]
mid = [Fr(0)] * 3                            # the same three chances by midpoint sums
for i, c in enumerate(cells):
    w = 2 * Fr(2 * i + 1, 2 ** (M + 1)) / 2 ** M
    mid[0] += w * c[0]; mid[1] += w * c[1]; mid[2] += w * c[0] * c[1]
print(f"density-2x dart: P(d1 = 1) = {float(anti[0])}, P(d2 = 1) = {float(anti[1])}, "
      f"P(both) = {float(anti[2])}, product {float(anti[0] * anti[1])}")
assert anti == mid and anti[2] != anti[0] * anti[1]
# ---- Kolmogorov's consistency condition ----
def sticky(w):                               # first toss fair, each later toss repeats with 0.8
    p = Fr(1, 2)
    for a, b in zip(w, w[1:]):
        p *= Fr(4, 5) if a == b else Fr(1, 5)
    return p
def parity(w): return Fr(1, 2 ** (len(w) - 1)) if w.count("H") % 2 == 0 else Fr(0)   # even heads only
def words(n): return [""] if n == 0 else [w + s for w in words(n - 1) for s in "HT"]
ok = all(sticky(w + "H") + sticky(w + "T") == sticky(w) for n in range(1, 10) for w in words(n))
print(f"sticky coin, consistent for n = 1 to 10: {'yes' if ok else 'no'}; mu_3(HHH) = {float(sticky('HHH'))}")
print(f"parity family: mu_1(H) = {float(parity('H')):.2f}, but mu_2 gives the first toss H with {float(parity('HH') + parity('HT')):.2f}")
assert ok and parity("H") != parity("HH") + parity("HT")
# ---- road 3: simulation ----
MASK = 2 ** 64 - 1
state = 20260929
def splitmix():
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return z ^ (z >> 31)
def uniforms(x):                             # U1..U4 from the 128 digits of x, by slot
    u = [0, 0, 0, 0]
    for k in range(1, 5):
        bits = 2 ** (7 - k)
        for j in range(1, bits + 1):
            n = 2 ** (k - 1) * (2 * j - 1)
            u[k - 1] = 2 * u[k - 1] + ((x >> (128 - n)) & 1)
        u[k - 1] = u[k - 1] / 2 ** bits
    return u
T = 200000
s1 = s11 = s2 = s22 = s12 = 0.0
three = six = hhh = darts = 0
for _ in range(T):
    x = (splitmix() << 64) | splitmix()
    u1, u2, u3, u4 = uniforms(x)
    s1 += u1; s11 += u1 * u1; s2 += u2; s22 += u2 * u2; s12 += u1 * u2
    three += u1 < 0.5 and u2 < 0.5 and u3 < 0.5
    six += int(6 * u1) + 1 == 6
    t1 = u1 < 0.5; t2 = t1 if u2 < 0.8 else not t1; t3 = t2 if u3 < 0.8 else not t2
    hhh += t1 and t2 and t3
    darts += u1 < 0.5 and u4 >= 0.5
m1, m2 = s1 / T, s2 / T
r = (s12 / T - m1 * m2) / ((s11 / T - m1 * m1) * (s22 / T - m2 * m2)) ** 0.5
print(f"simulated, {T} darts: mean U1 {m1:.6f}, correlation U1 U2 {r:.6f}")
sims = [("P(U1, U2, U3 all < 0.5)", three, 0.125), ("P(die from U1 shows 6)", six, 1 / 6),
        ("P(sticky HHH)", hhh, 0.32), ("P(dart 1 left half, dart 2 top half)", darts, 0.25)]
for label, hits, exact in sims:
    f, se = hits / T, (exact * (1 - exact) / T) ** 0.5
    print(f"simulated {label} = {f:.6f}; exact {exact:.6f}; standard error {se:.6f}")
    assert abs(f - exact) < 4 * se
assert abs(m1 - 0.5) < 4 * (1 / 12 / T) ** 0.5 and abs(r) < 4 / T ** 0.5
print("ALL CHECKS PASS")
```

**Ran 2026-10-06 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
doubling 0.7236 four times: 1.4472, 0.8944, 1.7888, 1.5776
dart x = 0.7236 m, binary digits 1-16: 1 0 1 1 1 0 0 1 0 0 1 1 1 1 0 1
position 1-16 goes to uniform k:      1 2 1 3 1 2 1 4 1 2 1 3 1 2 1 5
U1..U4 from 20 digits each: 0.900990, 0.107787, 0.959763, 0.764359
dart 1 = (U1, U2) = (0.900990, 0.107787); dart 2 = (U3, U4) = (0.959763, 0.764359)
die rolls floor(6U) + 1: [6, 1, 6, 5]
figure, x scale 30 + 300x px; dart at 247.08 px; digit-1 cells row 1 [0.5,1], row 2 [0.25,0.5] [0.75,1], row 3 [0.125,0.25] [0.375,0.5] [0.625,0.75] [0.875,1]
all 8,190 words of lengths 1 to 12: measure = 0.5^n, largest gap 0
P(d2 = 1, d5 = 0, d7 = 1) = 0.125 by counting cells; 0.5^3 = 0.125
U1..U4 read from 12 digits: 64 x 8 x 4 x 2 = 4096 value combinations, 4096 distinct, each measure 1/4096
P(U1 < 0.5, U2 < 0.25) = 0.125 by counting cells; 0.5 x 0.25 = 0.125
shifted digits, m =  4: correlation of U and V = 0.497050
shifted digits, m =  8: correlation of U and V = 0.499989
shifted digits, m = 12: correlation of U and V = 0.500000
shifted digits, m = 16: correlation of U and V = 0.500000
shifted digits, by hand: Var U = 0.083333, Cov(U, d1) = 0.125000, Cov(U, V) = 0.041667, limit 0.5
density-2x dart: P(d1 = 1) = 0.75, P(d2 = 1) = 0.625, P(both) = 0.4375, product 0.46875
sticky coin, consistent for n = 1 to 10: yes; mu_3(HHH) = 0.32
parity family: mu_1(H) = 0.00, but mu_2 gives the first toss H with 0.50
simulated, 200000 darts: mean U1 0.499981, correlation U1 U2 -0.000449
simulated P(U1, U2, U3 all < 0.5) = 0.124015; exact 0.125000; standard error 0.000740
simulated P(die from U1 shows 6) = 0.166925; exact 0.166667; standard error 0.000833
simulated P(sticky HHH) = 0.320230; exact 0.320000; standard error 0.001043
simulated P(dart 1 left half, dart 2 top half) = 0.248970; exact 0.250000; standard error 0.000968
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`. Exact chances are whole-number counts over powers of 2, where Python uses fractions.

```rust
// Infinitely many coin tosses from one dart -- the same check in Rust, std only.
// Exact work is done in whole numbers: a dyadic chance is a count of cells over
// a power of two.  Roads: (1) one dart x = 0.7236 m, digits by exact doubling,
// split two ways; (2) Lebesgue measure of digit events on the 4,096 cells of
// level 12 against the product rule 0.5^n; (3) SplitMix64, seed 20260929,
// 200,000 darts, each x held to 128 binary digits.
use std::collections::{HashMap, HashSet};

fn digits(mut p: u128, q: u128, n: usize) -> Vec<u64> { // first n binary digits of p/q
    (0..n).map(|_| { p *= 2; let d = (p >= q) as u128; p -= q * d; d as u64 }).collect()
}
fn slot(mut n: usize) -> (usize, usize) {    // position n = 2^(k-1) * (2j - 1)  ->  (k, j)
    let mut k = 1;
    while n % 2 == 0 { n /= 2; k += 1; }
    (k, (n + 1) / 2)
}
fn split(ds: &[u64], count: usize, cap: usize) -> Vec<f64> { // U_k from slots (k, 1..cap)
    let mut u = vec![0.0; count];
    for (i, &d) in ds.iter().enumerate() {
        let (k, j) = slot(i + 1);
        if k <= count && j <= cap { u[k - 1] += d as f64 / 2f64.powi(j as i32); }
    }
    u
}
fn splitmix(state: &mut u64) -> u64 {
    *state = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = *state;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}
fn uniforms(x: u128) -> [f64; 4] {           // U1..U4 from the 128 digits of x, by slot
    let mut u = [0.0; 4];
    for k in 1..=4u32 {
        let bits = 1u32 << (7 - k);
        let mut v: u64 = 0;
        for j in 1..=bits {
            let n = (1u32 << (k - 1)) * (2 * j - 1);
            v = 2 * v + ((x >> (128 - n)) & 1) as u64;
        }
        u[(k - 1) as usize] = v as f64 / 2f64.powi(bits as i32);
    }
    u
}
fn main() {
    // ---- road 1: one dart ----
    let ds = digits(1809, 2500, 320);         // x = 0.7236 = 1809/2500
    let (mut p, mut dbl) = (1809u64, Vec::new());
    for _ in 0..4 { p *= 2; dbl.push(format!("{:.4}", p as f64 / 2500.0)); if p >= 2500 { p -= 2500 } }
    println!("doubling 0.7236 four times: {}", dbl.join(", "));
    let s: Vec<String> = ds[..16].iter().map(|d| d.to_string()).collect();
    println!("dart x = 0.7236 m, binary digits 1-16: {}", s.join(" "));
    let s: Vec<String> = (1..=16).map(|n| slot(n).0.to_string()).collect();
    println!("position 1-16 goes to uniform k:      {}", s.join(" "));
    let u = split(&ds, 4, 20);
    let sl: Vec<f64> = (0..4).map(|k| ds.iter().skip((1 << k) - 1).step_by(1 << (k + 1)).take(20)
        .enumerate().map(|(j, &d)| d as f64 / 2f64.powi(j as i32 + 1)).sum()).collect();
    let f6: Vec<String> = sl.iter().map(|v| format!("{:.6}", v)).collect();
    println!("U1..U4 from 20 digits each: {}", f6.join(", "));
    println!("dart 1 = (U1, U2) = ({}, {}); dart 2 = (U3, U4) = ({}, {})", f6[0], f6[1], f6[2], f6[3]);
    let die: Vec<i64> = sl.iter().map(|v| (6.0 * v) as i64 + 1).collect();
    println!("die rolls floor(6U) + 1: {:?}", die);
    assert!(u == sl);                         // two readings of the split
    println!("figure, x scale 30 + 300x px; dart at {:.2} px; digit-1 cells row 1 [0.5,1], row 2 [0.25,0.5] [0.75,1], row 3 [0.125,0.25] [0.375,0.5] [0.625,0.75] [0.875,1]",
             30.0 + 300.0 * 1809.0 / 2500.0);

    // ---- road 2: Lebesgue measure on the 4,096 cells of level 12 ----
    let m = 12usize;
    let cells: Vec<Vec<u64>> = (0..1u128 << m).map(|i| digits(2 * i + 1, 1 << (m + 1), m)).collect();
    let mut worst = 0i64;
    for n in 1..=m {
        let mut tally: HashMap<Vec<u64>, i64> = HashMap::new();
        for c in &cells { *tally.entry(c[..n].to_vec()).or_insert(0) += 1; }
        assert!(tally.len() == 1 << n);
        for &t in tally.values() { worst = worst.max((t * (1 << n) - (1 << m)).abs()); }
    }
    println!("all 8,190 words of lengths 1 to 12: measure = 0.5^n, largest gap {}", worst);
    let pair = cells.iter().filter(|c| c[1] == 1 && c[4] == 0 && c[6] == 1).count();
    println!("P(d2 = 1, d5 = 0, d7 = 1) = {} by counting cells; 0.5^3 = {}", pair as f64 / 4096.0, 0.5f64.powi(3));
    let combos: HashSet<Vec<u64>> = cells.iter().map(|c| split(c, 4, 12).iter().map(|v| v.to_bits()).collect()).collect();
    println!("U1..U4 read from 12 digits: 64 x 8 x 4 x 2 = {} value combinations, {} distinct, each measure 1/4096", 64 * 8 * 4 * 2, combos.len());
    let rect = cells.iter().filter(|c| { let v = split(c, 2, 12); v[0] < 0.5 && v[1] < 0.25 }).count();
    println!("P(U1 < 0.5, U2 < 0.25) = {} by counting cells; 0.5 x 0.25 = {}", rect as f64 / 4096.0, 0.5 * 0.25);
    assert!(worst == 0 && pair * 8 == 4096 && combos.len() == 4096 && rect * 8 == 4096);

    // ---- what breaks ----
    let mut corr = 0.0;
    for &mm in &[4u32, 8, 12, 16] {           // U from digits 1..m, V from digits 2..m: a reused digit
        let n = 1i128 << mm;
        let (mut sa, mut sb, mut saa, mut sbb, mut sab) = (0i128, 0i128, 0i128, 0i128, 0i128);
        for i in 0..n {
            let c = digits(2 * i as u128 + 1, 1 << (mm + 1), mm as usize);
            let a = c.iter().fold(0i128, |acc, &d| 2 * acc + d as i128);          // U = a / 2^m
            let b = c[1..].iter().fold(0i128, |acc, &d| 2 * acc + d as i128);     // V = b / 2^(m-1)
            sa += a; sb += b; saa += a * a; sbb += b * b; sab += a * b;
        }
        let cov = (n * sab - sa * sb) as f64;
        let (vu, vv) = ((n * saa - sa * sa) as f64, (n * sbb - sb * sb) as f64);
        corr = cov / (vu * vv).sqrt();
        println!("shifted digits, m = {:2}: correlation of U and V = {:.6}", mm, corr);
    }
    let (var, cov_d1) = (2i64, 9 - 6);        // in 24ths: Var U = 1/12; Cov(U, d1) = 3/8 - 1/4
    let limit = (2 * var - cov_d1) as f64 / var as f64; // V = 2U - d1, worked on the card
    println!("shifted digits, by hand: Var U = {:.6}, Cov(U, d1) = {:.6}, Cov(U, V) = {:.6}, limit {}",
             var as f64 / 24.0, cov_d1 as f64 / 24.0, (2 * var - cov_d1) as f64 / 24.0, limit);
    assert!((corr - limit).abs() < 1e-3);
    let cdf16 = |a4: i64| a4 * a4;            // density 2x: P(x <= a4/4) = a4^2 / 16
    let anti = [16 - cdf16(2), cdf16(2) - cdf16(1) + 16 - cdf16(3), 16 - cdf16(3)]; // sixteenths
    let mut mid = [0i64; 3];                  // the same three chances by midpoint sums, in 2^-24
    for (i, c) in cells.iter().enumerate() {
        let w = 2 * i as i64 + 1;
        mid[0] += w * c[0] as i64; mid[1] += w * c[1] as i64; mid[2] += w * (c[0] * c[1]) as i64;
    }
    println!("density-2x dart: P(d1 = 1) = {}, P(d2 = 1) = {}, P(both) = {}, product {}",
             anti[0] as f64 / 16.0, anti[1] as f64 / 16.0, anti[2] as f64 / 16.0, (anti[0] * anti[1]) as f64 / 256.0);
    assert!((0..3).all(|t| mid[t] == anti[t] << 20) && anti[2] * 16 != anti[0] * anti[1]);

    // ---- Kolmogorov's consistency condition ----
    let sticky = |w: &[u8]| -> i64 {          // numerator over 2 * 5^(n-1): repeat weighs 4, switch 1
        w.windows(2).map(|p| if p[0] == p[1] { 4 } else { 1 }).product()
    };
    let mut ok = true;
    for n in 1..10u32 {
        for code in 0..1u32 << n {
            let w: Vec<u8> = (0..n).map(|i| ((code >> i) & 1) as u8).collect();
            let (h, t) = ([&w[..], &[1]].concat(), [&w[..], &[0]].concat());
            ok &= sticky(&h) + sticky(&t) == 5 * sticky(&w);
        }
    }
    println!("sticky coin, consistent for n = 1 to 10: {}; mu_3(HHH) = {}", if ok { "yes" } else { "no" },
             sticky(&[1, 1, 1]) as f64 / 50.0);
    let parity = |w: &[u8]| -> f64 {          // uniform on the words with an even number of heads
        if w.iter().filter(|&&d| d == 1).count() % 2 == 0 { 1.0 / 2f64.powi(w.len() as i32 - 1) } else { 0.0 }
    };
    let (p1, p2) = (parity(&[1]), parity(&[1, 1]) + parity(&[1, 0]));
    println!("parity family: mu_1(H) = {:.2}, but mu_2 gives the first toss H with {:.2}", p1, p2);
    assert!(ok && p1 != p2);

    // ---- road 3: simulation ----
    let mut state: u64 = 20260929;
    let t = 200000usize;
    let (mut s1, mut s11, mut s2, mut s22, mut s12) = (0.0, 0.0, 0.0, 0.0, 0.0);
    let (mut three, mut six, mut hhh, mut darts) = (0usize, 0usize, 0usize, 0usize);
    for _ in 0..t {
        let hi = splitmix(&mut state) as u128;
        let x = (hi << 64) | splitmix(&mut state) as u128;
        let [u1, u2, u3, u4] = uniforms(x);
        s1 += u1; s11 += u1 * u1; s2 += u2; s22 += u2 * u2; s12 += u1 * u2;
        three += (u1 < 0.5 && u2 < 0.5 && u3 < 0.5) as usize;
        six += ((6.0 * u1) as i64 + 1 == 6) as usize;
        let t1 = u1 < 0.5;
        let t2 = if u2 < 0.8 { t1 } else { !t1 }; let t3 = if u3 < 0.8 { t2 } else { !t2 };
        hhh += (t1 && t2 && t3) as usize;
        darts += (u1 < 0.5 && u4 >= 0.5) as usize;
    }
    let tf = t as f64; let (m1, m2) = (s1 / tf, s2 / tf);
    let r = (s12 / tf - m1 * m2) / ((s11 / tf - m1 * m1) * (s22 / tf - m2 * m2)).sqrt();
    println!("simulated, {} darts: mean U1 {:.6}, correlation U1 U2 {:.6}", t, m1, r);
    let sims = [("P(U1, U2, U3 all < 0.5)", three, 0.125), ("P(die from U1 shows 6)", six, 1.0 / 6.0),
                ("P(sticky HHH)", hhh, 0.32), ("P(dart 1 left half, dart 2 top half)", darts, 0.25)];
    for (label, hits, exact) in sims {
        let (f, se) = (hits as f64 / tf, (exact * (1.0 - exact) / tf).sqrt());
        println!("simulated {} = {:.6}; exact {:.6}; standard error {:.6}", label, f, exact, se);
        assert!((f - exact).abs() < 4.0 * se);
    }
    assert!((m1 - 0.5).abs() < 4.0 * (1.0 / 12.0 / tf).sqrt() && r.abs() < 4.0 / tf.sqrt());
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-10-06 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
doubling 0.7236 four times: 1.4472, 0.8944, 1.7888, 1.5776
dart x = 0.7236 m, binary digits 1-16: 1 0 1 1 1 0 0 1 0 0 1 1 1 1 0 1
position 1-16 goes to uniform k:      1 2 1 3 1 2 1 4 1 2 1 3 1 2 1 5
U1..U4 from 20 digits each: 0.900990, 0.107787, 0.959763, 0.764359
dart 1 = (U1, U2) = (0.900990, 0.107787); dart 2 = (U3, U4) = (0.959763, 0.764359)
die rolls floor(6U) + 1: [6, 1, 6, 5]
figure, x scale 30 + 300x px; dart at 247.08 px; digit-1 cells row 1 [0.5,1], row 2 [0.25,0.5] [0.75,1], row 3 [0.125,0.25] [0.375,0.5] [0.625,0.75] [0.875,1]
all 8,190 words of lengths 1 to 12: measure = 0.5^n, largest gap 0
P(d2 = 1, d5 = 0, d7 = 1) = 0.125 by counting cells; 0.5^3 = 0.125
U1..U4 read from 12 digits: 64 x 8 x 4 x 2 = 4096 value combinations, 4096 distinct, each measure 1/4096
P(U1 < 0.5, U2 < 0.25) = 0.125 by counting cells; 0.5 x 0.25 = 0.125
shifted digits, m =  4: correlation of U and V = 0.497050
shifted digits, m =  8: correlation of U and V = 0.499989
shifted digits, m = 12: correlation of U and V = 0.500000
shifted digits, m = 16: correlation of U and V = 0.500000
shifted digits, by hand: Var U = 0.083333, Cov(U, d1) = 0.125000, Cov(U, V) = 0.041667, limit 0.5
density-2x dart: P(d1 = 1) = 0.75, P(d2 = 1) = 0.625, P(both) = 0.4375, product 0.46875
sticky coin, consistent for n = 1 to 10: yes; mu_3(HHH) = 0.32
parity family: mu_1(H) = 0.00, but mu_2 gives the first toss H with 0.50
simulated, 200000 darts: mean U1 0.499981, correlation U1 U2 -0.000449
simulated P(U1, U2, U3 all < 0.5) = 0.124015; exact 0.125000; standard error 0.000740
simulated P(die from U1 shows 6) = 0.166925; exact 0.166667; standard error 0.000833
simulated P(sticky HHH) = 0.320230; exact 0.320000; standard error 0.001043
simulated P(dart 1 left half, dart 2 top half) = 0.248970; exact 0.250000; standard error 0.000968
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves all three theorems in full: for every pattern, every distribution function, and every consistent family of laws on real sequences.

- Take a uniform dart and any pattern of n digits. Then the pattern has chance $2^{-n}$, the product of its digits' separate chances.
- Take a uniform dart on the unit interval. Then its digits $d_1, d_2, d_3, \dots$ are independent fair coins.
- Take the piles of the slot rule. Then $U_1, U_2, U_3, \dots$ are independent, and each is uniform on the unit interval.
- Take any distribution function F with quantile map Q. Then the draws $X_k = Q(U_k)$ are independent, each with law F.
- Suppose the laws $\mu_n$ are consistent. Then exactly one probability P on whole sequences has every $\mu_n$ as the law of its first n terms.
- The hand numbers hold exactly as whole numbers and fractions. These include the dart's digits, the piles, the 16 cells of Step 2, the die rolls 6, 1, 6, 5 and the sticky coin's 0.32.
- The break arithmetic holds too. The density-2x dart gives both digits 1 with chance 0.4375, not 0.46875, and the shared-digit correlation is 0.5.

The paired darts, the decimals, the coin-family checks and the simulations are left to the Python and Rust checks.

```lean
-- Infinitely many coin tosses: under length on [0, 1) the binary digits of a point are independent fair coins, dealing them into disjoint piles gives independent uniforms and hence independent draws of any law, and every consistent family of laws on the first n coordinates of a real sequence comes from exactly one probability on whole sequences.
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.MeasureTheory.Constructions.Pi
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.CDF
import Mathlib.Data.Fin.Tuple.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Algebra.Order.Floor.Semifield
import Mathlib.MeasureTheory.Function.Floor
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Probability.Independence.InfinitePi
import Mathlib.Probability.ProductMeasure
import Mathlib.Probability.Kernel.IonescuTulcea.Traj
import Mathlib.Probability.Kernel.Disintegration.StandardBorel

open MeasureTheory ProbabilityTheory
open scoped ENNReal

/-- The `n`-th binary digit of `x`: double `x` `n` times, keep the whole-number part, and
take its remainder on division by 2. This is the card's `d_n(x) = ⌊2^n x⌋ mod 2`. -/
noncomputable def binDigit (n : ℕ) (x : ℝ) : ℤ := ⌊(2 : ℝ) ^ n * x⌋ % 2

/-- Pile `k` of the splitting theorem, counted from 0: it takes as its `j`-th digit
(also counted from 0) the old digit at position `2^k (2j + 1)`. With `k` and `j` counted
from 1 this is the card's `U_k = Σ_j d_{2^(k-1)(2j-1)} 2^(-j)`. -/
noncomputable def pile (k : ℕ) (x : ℝ) : ℝ :=
  ∑' j : ℕ, (binDigit (2 ^ k * (2 * j + 1)) x : ℝ) / 2 ^ (j + 1)

namespace DigitAux

lemma binDigit_eq_nat (N i : ℕ) (hi : i < N) {x : ℝ} (hx : 0 ≤ x) :
    binDigit (i + 1) x = ((⌊(2:ℝ) ^ N * x⌋₊ / 2 ^ (N - 1 - i) % 2 : ℕ) : ℤ) := by
  have h2 : (2:ℝ) ^ N * x = (2:ℝ) ^ (i + 1) * x * ((2 ^ (N - 1 - i) : ℕ) : ℝ) := by
    push_cast
    rw [mul_right_comm, ← pow_add]
    congr 2
    omega
  have h3 : ⌊(2:ℝ) ^ (i + 1) * x⌋₊ = ⌊(2:ℝ) ^ N * x⌋₊ / 2 ^ (N - 1 - i) := by
    rw [← Nat.floor_div_natCast, h2, mul_div_cancel_right₀]
    positivity
  unfold binDigit
  rw [← Int.natCast_floor_eq_floor (by positivity), h3]
  push_cast
  rfl
#print axioms binDigit_eq_nat

lemma floor_set_eq (N m : ℕ) (hm : m < 2 ^ N) :
    {x ∈ Set.Ico (0:ℝ) 1 | ⌊(2:ℝ) ^ N * x⌋₊ = m}
      = Set.Ico ((m:ℝ) / 2 ^ N) (((m:ℝ) + 1) / 2 ^ N) := by
  have hpos : (0:ℝ) < 2 ^ N := by positivity
  have hm' : (m:ℝ) + 1 ≤ 2 ^ N := by exact_mod_cast hm
  ext x
  simp only [Set.mem_ofPred_eq, Set.mem_Ico]
  constructor
  · rintro ⟨⟨h0, h1⟩, hf⟩
    have := (Nat.floor_eq_iff (by positivity)).1 hf
    refine ⟨?_, ?_⟩
    · rw [div_le_iff₀ hpos]; linarith [this.1]
    · rw [lt_div_iff₀ hpos]; linarith [this.2]
  · rintro ⟨h1, h2⟩
    rw [div_le_iff₀ hpos] at h1
    rw [lt_div_iff₀ hpos] at h2
    have hx0 : 0 ≤ x := by
      have : (0:ℝ) ≤ m := Nat.cast_nonneg m
      nlinarith
    refine ⟨⟨hx0, ?_⟩, ?_⟩
    · nlinarith
    · rw [Nat.floor_eq_iff (by positivity)]
      constructor <;> linarith
#print axioms floor_set_eq

lemma vol_floor_eq (N : ℕ) (P : ℕ → Prop) [DecidablePred P] :
    volume {x ∈ Set.Ico (0:ℝ) 1 | P ⌊(2:ℝ) ^ N * x⌋₊} =
      ((Finset.range (2 ^ N)).filter P).card * ((2:ℝ≥0∞) ^ N)⁻¹ := by
  have hset : {x ∈ Set.Ico (0:ℝ) 1 | P ⌊(2:ℝ) ^ N * x⌋₊} =
      ⋃ m ∈ (Finset.range (2 ^ N)).filter P, {x ∈ Set.Ico (0:ℝ) 1 | ⌊(2:ℝ) ^ N * x⌋₊ = m} := by
    ext x
    simp only [Set.mem_ofPred_eq, Set.mem_iUnion, Finset.mem_filter, Finset.mem_range,
      exists_prop]
    constructor
    · rintro ⟨hx, hP⟩
      refine ⟨_, ⟨?_, hP⟩, hx, rfl⟩
      rw [Nat.floor_lt (by have := hx.1; positivity)]
      have := hx.2
      push_cast
      have : (0:ℝ) < 2 ^ N := by positivity
      nlinarith
    · rintro ⟨m, ⟨_, hP⟩, hx, rfl⟩
      exact ⟨hx, hP⟩
  rw [hset, measure_biUnion_finset]
  · have : ∀ m ∈ (Finset.range (2 ^ N)).filter P,
        volume {x ∈ Set.Ico (0:ℝ) 1 | ⌊(2:ℝ) ^ N * x⌋₊ = m} = ((2:ℝ≥0∞) ^ N)⁻¹ := by
      intro m hm
      rw [Finset.mem_filter, Finset.mem_range] at hm
      rw [floor_set_eq N m hm.1, Real.volume_Ico]
      have : ((m:ℝ) + 1) / 2 ^ N - m / 2 ^ N = ((2:ℝ) ^ N)⁻¹ := by
        field_simp; ring
      rw [this, ENNReal.ofReal_inv_of_pos (by positivity), ENNReal.ofReal_pow (by norm_num)]
      simp
    rw [Finset.sum_congr rfl this, Finset.sum_const, nsmul_eq_mul]
  · intro a _ b _ hab
    simp only [Function.onFun]
    rw [Set.disjoint_left]
    rintro x ⟨_, hxa⟩ ⟨_, hxb⟩
    exact hab (hxa.symm.trans hxb)
  · intro m _
    exact measurableSet_Ico.inter
      (measurableSet_eq_fun (Nat.measurable_floor.comp (measurable_const.mul measurable_id))
        measurable_const)
#print axioms vol_floor_eq

/-- How many of the two digits 0, 1 lie in `A`. -/

noncomputable def cnt (A : Set ℤ) : ℕ := by
  classical exact ((Finset.univ : Finset (Fin 2)).filter (fun b : Fin 2 => ((b:ℕ):ℤ) ∈ A)).card
#print axioms cnt

lemma count_eq (N : ℕ) (A : Fin N → Set ℤ) [DecidablePred
    (fun m : ℕ => ∀ i : Fin N, ((m / 2 ^ (N - 1 - i) % 2 : ℕ) : ℤ) ∈ A i)] :
    ((Finset.range (2 ^ N)).filter
      (fun m => ∀ i : Fin N, ((m / 2 ^ (N - 1 - i) % 2 : ℕ) : ℤ) ∈ A i)).card
      = ∏ i, cnt (A i) := by
  classical
  have h1 : ((Finset.range (2 ^ N)).filter
      (fun m => ∀ i : Fin N, ((m / 2 ^ (N - 1 - i) % 2 : ℕ) : ℤ) ∈ A i)).card
      = ((Finset.univ : Finset (Fin N → Fin 2)).filter
          (fun f => ∀ j, ((f j : ℕ) : ℤ) ∈ A (Fin.rev j))).card := by
    symm
    refine Finset.card_bij (fun f _ => (finFunctionFinEquiv f : ℕ)) ?_ ?_ ?_
    · intro f hf
      simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hf
      simp only [Finset.mem_filter, Finset.mem_range]
      refine ⟨(finFunctionFinEquiv f).2, fun i => ?_⟩
      have := finFunctionFinEquiv_symm_apply_val (finFunctionFinEquiv f) (Fin.rev i)
      rw [Equiv.symm_apply_apply, Fin.val_rev] at this
      have hN : N - 1 - (i : ℕ) = N - ((i : ℕ) + 1) := by omega
      rw [hN, ← this]
      simpa using hf (Fin.rev i)
    · intro f _ g _ hfg
      exact finFunctionFinEquiv.injective (Fin.ext hfg)
    · intro m hm
      simp only [Finset.mem_filter, Finset.mem_range] at hm
      refine ⟨finFunctionFinEquiv.symm ⟨m, hm.1⟩, ?_, by simp⟩
      simp only [Finset.mem_filter, Finset.mem_univ, true_and]
      intro j
      rw [finFunctionFinEquiv_symm_apply_val]
      have := hm.2 (Fin.rev j)
      have hN : N - 1 - ((Fin.rev j : Fin N) : ℕ) = (j : ℕ) := by
        rw [Fin.val_rev]; omega
      rwa [hN] at this
  rw [h1]
  have h2 : (Finset.univ : Finset (Fin N → Fin 2)).filter
      (fun f => ∀ j, ((f j : ℕ) : ℤ) ∈ A (Fin.rev j))
      = Fintype.piFinset (fun j => (Finset.univ : Finset (Fin 2)).filter
          (fun b : Fin 2 => ((b:ℕ):ℤ) ∈ A (Fin.rev j))) := by
    ext f
    simp [Fintype.mem_piFinset]
  rw [h2, Fintype.card_piFinset]
  rw [← Equiv.prod_comp Fin.revPerm (fun i => cnt (A i))]
  apply Finset.prod_congr rfl
  intro j _
  simp only [cnt, Fin.revPerm_apply]
#print axioms count_eq

lemma vol_digits (N : ℕ) (A : Fin N → Set ℤ) :
    volume {x ∈ Set.Ico (0:ℝ) 1 | ∀ i : Fin N, binDigit ((i:ℕ) + 1) x ∈ A i}
      = ∏ i, ((cnt (A i) : ℝ≥0∞) * 2⁻¹) := by
  classical
  have hset : {x ∈ Set.Ico (0:ℝ) 1 | ∀ i : Fin N, binDigit ((i:ℕ) + 1) x ∈ A i}
      = {x ∈ Set.Ico (0:ℝ) 1 | (fun m : ℕ => ∀ i : Fin N,
          ((m / 2 ^ (N - 1 - i) % 2 : ℕ) : ℤ) ∈ A i) ⌊(2:ℝ) ^ N * x⌋₊} := by
    ext x
    simp only [Set.mem_ofPred_eq]
    constructor
    · rintro ⟨hx, h⟩
      refine ⟨hx, fun i => ?_⟩
      rw [← binDigit_eq_nat N i i.2 hx.1]
      exact h i
    · rintro ⟨hx, h⟩
      refine ⟨hx, fun i => ?_⟩
      rw [binDigit_eq_nat N i i.2 hx.1]
      exact h i
  rw [hset, vol_floor_eq N (fun m : ℕ => ∀ i : Fin N, ((m / 2 ^ (N - 1 - i) % 2 : ℕ) : ℤ) ∈ A i),
    count_eq, Finset.prod_mul_distrib, Finset.prod_const,
    Finset.card_univ, Fintype.card_fin, ENNReal.inv_pow]
  push_cast
  rfl
#print axioms vol_digits

lemma cnt_univ : cnt Set.univ = 2 := by
  simp [cnt]
#print axioms cnt_univ

lemma vol_digit (n : ℕ) (B : Set ℤ) :
    volume {x ∈ Set.Ico (0:ℝ) 1 | binDigit (n + 1) x ∈ B} = (cnt B : ℝ≥0∞) * 2⁻¹ := by
  classical
  have h := vol_digits (n + 1) (fun i => if (i:ℕ) = n then B else Set.univ)
  have hset : {x ∈ Set.Ico (0:ℝ) 1 | ∀ i : Fin (n + 1), binDigit ((i:ℕ) + 1) x ∈
      (fun i : Fin (n + 1) => if (i:ℕ) = n then B else Set.univ) i}
      = {x ∈ Set.Ico (0:ℝ) 1 | binDigit (n + 1) x ∈ B} := by
    ext x
    simp only [Set.mem_ofPred_eq]
    constructor
    · rintro ⟨hx, h⟩
      refine ⟨hx, ?_⟩
      have := h (Fin.last n)
      simpa using this
    · rintro ⟨hx, h⟩
      refine ⟨hx, fun i => ?_⟩
      by_cases hi : (i:ℕ) = n
      · simp only [hi, ite_true]; exact h
      · simp [hi]
  rw [hset] at h
  rw [h, Fin.prod_univ_castSucc]
  simp only [Fin.val_castSucc, Fin.val_last, ite_true]
  have : ∀ i : Fin n, (if (i:ℕ) = n then B else Set.univ) = Set.univ := by
    intro i; simp [i.2.ne]
  simp only [this, cnt_univ]
  rw [Finset.prod_eq_one, one_mul]
  intro i _
  push_cast
  exact ENNReal.mul_inv_cancel (by norm_num) (by norm_num)
#print axioms vol_digit

lemma cnt_singleton (z : ℤ) (hz : z = 0 ∨ z = 1) : cnt {z} = 1 := by
  rcases hz with rfl | rfl
  · rw [cnt, Finset.card_eq_one]; exact ⟨0, by ext b; fin_cases b <;> simp⟩
  · rw [cnt, Finset.card_eq_one]; exact ⟨1, by ext b; fin_cases b <;> simp⟩
#print axioms cnt_singleton

instance isProbabilityMeasure_Ico : IsProbabilityMeasure (volume.restrict (Set.Ico (0:ℝ) 1)) :=
  ⟨by simp [Real.volume_Ico]⟩
#print axioms isProbabilityMeasure_Ico

end DigitAux

namespace PileAux

open DigitAux Filter Topology

lemma measurable_binDigit (n : ℕ) : Measurable (binDigit n) := by
  have h1 : Measurable (fun z : ℤ => z % 2) := Measurable.of_discrete
  exact h1.comp ((measurable_const.mul measurable_id).floor)
#print axioms measurable_binDigit

lemma binDigit_mod_two (n : ℕ) (x : ℝ) : binDigit n x % 2 = binDigit n x := by
  simp [binDigit]
#print axioms binDigit_mod_two

lemma vol_preimage (n : ℕ) (B : Set ℤ) :
    (volume.restrict (Set.Ico (0:ℝ) 1)) (binDigit (n + 1) ⁻¹' B) = (cnt B : ℝ≥0∞) * 2⁻¹ := by
  rw [Measure.restrict_apply' measurableSet_Ico, ← vol_digit n B]
  congr 1
  ext x
  simp [and_comm]
#print axioms vol_preimage

lemma law_digit (n : ℕ) :
    (volume.restrict (Set.Ico (0:ℝ) 1)).map (binDigit (n + 1))
      = (volume.restrict (Set.Ico (0:ℝ) 1)).map (binDigit (0 + 1)) := by
  ext B hB
  rw [Measure.map_apply (measurable_binDigit _) hB, Measure.map_apply (measurable_binDigit _) hB,
    vol_preimage, vol_preimage]
#print axioms law_digit

/-- The binary number read from a 0-1 sequence (reading each entry modulo 2). -/

noncomputable def Φ (ω : ℕ → ℤ) : ℝ := ∑' j : ℕ, ((ω j % 2 : ℤ) : ℝ) / 2 ^ (j + 1)
#print axioms Φ

lemma term_nonneg (ω : ℕ → ℤ) (j : ℕ) : 0 ≤ ((ω j % 2 : ℤ) : ℝ) / 2 ^ (j + 1) := by
  have : (0:ℤ) ≤ ω j % 2 := Int.emod_nonneg _ (by norm_num)
  positivity
#print axioms term_nonneg

lemma term_le (ω : ℕ → ℤ) (j : ℕ) : ((ω j % 2 : ℤ) : ℝ) / 2 ^ (j + 1) ≤ (1 / 2) ^ j := by
  have h1 : ω j % 2 < 2 := Int.emod_lt_of_pos _ (by norm_num)
  have h2 : ((ω j % 2 : ℤ) : ℝ) ≤ 1 := by exact_mod_cast (show ω j % 2 ≤ 1 by omega)
  rw [div_le_iff₀ (by positivity), one_div, inv_pow, pow_succ]
  have : ((2:ℝ) ^ j)⁻¹ * (2 ^ j * 2) = 2 := by field_simp
  rw [this]
  linarith
#print axioms term_le

lemma summable_term (ω : ℕ → ℤ) : Summable (fun j : ℕ => ((ω j % 2 : ℤ) : ℝ) / 2 ^ (j + 1)) :=
  Summable.of_nonneg_of_le (term_nonneg ω) (term_le ω) summable_geometric_two
#print axioms summable_term

lemma measurable_Φ : Measurable Φ := by
  refine measurable_of_tendsto_metrizable (f := fun N ω => ∑ j ∈ Finset.range N,
    ((ω j % 2 : ℤ) : ℝ) / 2 ^ (j + 1)) (fun N => ?_) ?_
  · refine Finset.measurable_sum _ (fun j _ => ?_)
    have h1 : Measurable (fun z : ℤ => ((z % 2 : ℤ) : ℝ) / 2 ^ (j + 1)) := Measurable.of_discrete
    exact h1.comp (measurable_pi_apply j)
  · rw [tendsto_pi_nhds]
    intro ω
    exact (summable_term ω).hasSum.tendsto_sum_nat
#print axioms measurable_Φ

lemma partial_sum (x : ℝ) (hx : x ∈ Set.Ico (0:ℝ) 1) (N : ℕ) :
    ∑ j ∈ Finset.range N, ((binDigit (j + 1) x % 2 : ℤ) : ℝ) / 2 ^ (j + 1)
      = (⌊(2:ℝ) ^ N * x⌋₊ : ℝ) / 2 ^ N := by
  induction N with
  | zero =>
    simp only [Finset.range_zero, Finset.sum_empty, pow_zero, one_mul, div_one]
    rw [Nat.floor_eq_zero.2 hx.2]
    simp
  | succ N ih =>
    rw [Finset.sum_range_succ, ih, binDigit_mod_two, binDigit_eq_nat (N + 1) N (by omega) hx.1]
    have hsub : N + 1 - 1 - N = 0 := by omega
    rw [hsub, pow_zero, Nat.div_one]
    set m := ⌊(2:ℝ) ^ (N + 1) * x⌋₊ with hm
    have hhalf : ⌊(2:ℝ) ^ N * x⌋₊ = m / 2 := by
      rw [hm, ← Nat.floor_div_natCast]
      congr 1
      push_cast
      ring
    rw [hhalf]
    have hdm : ((m:ℕ):ℝ) = 2 * ((m / 2 : ℕ) : ℝ) + ((m % 2 : ℕ) : ℝ) := by
      exact_mod_cast (Nat.div_add_mod m 2).symm
    rw [Int.cast_natCast, hdm]
    field_simp
    ring
#print axioms partial_sum

lemma hasSum_digits (x : ℝ) (hx : x ∈ Set.Ico (0:ℝ) 1) :
    HasSum (fun j : ℕ => ((binDigit (j + 1) x % 2 : ℤ) : ℝ) / 2 ^ (j + 1)) x := by
  rw [hasSum_iff_tendsto_nat_of_nonneg (fun j => term_nonneg (fun j => binDigit (j + 1) x) j)]
  simp_rw [partial_sum x hx]
  have hlow : Tendsto (fun N : ℕ => x - (1 / 2 : ℝ) ^ N) atTop (𝓝 x) := by
    have := (tendsto_pow_atTop_nhds_zero_of_lt_one (by norm_num : (0:ℝ) ≤ 1 / 2)
      (by norm_num : (1 / 2 : ℝ) < 1)).const_sub x
    simpa using this
  refine tendsto_of_tendsto_of_tendsto_of_le_of_le hlow tendsto_const_nhds (fun N => ?_)
    (fun N => ?_)
  · have hpos : (0:ℝ) < 2 ^ N := by positivity
    have := Nat.lt_floor_add_one ((2:ℝ) ^ N * x)
    simp only
    rw [le_div_iff₀ hpos, sub_mul, one_div, inv_pow, inv_mul_cancel₀ hpos.ne']
    linarith
  · have hpos : (0:ℝ) < 2 ^ N := by positivity
    have := Nat.floor_le (show 0 ≤ (2:ℝ) ^ N * x by have := hx.1; positivity)
    simp only
    rw [div_le_iff₀ hpos]
    linarith
#print axioms hasSum_digits

lemma Φ_digits (x : ℝ) (hx : x ∈ Set.Ico (0:ℝ) 1) :
    Φ (fun n => binDigit (n + 1) x) = x :=
  (hasSum_digits x hx).tsum_eq
#print axioms Φ_digits

/-- The odd-part decomposition `2^a (2b+1)` is unique. -/

lemma odd_part_inj {a b c d : ℕ} (h : 2 ^ a * (2 * b + 1) = 2 ^ c * (2 * d + 1)) (hac : a ≤ c) :
    a = c ∧ b = d := by
  obtain ⟨t, rfl⟩ := Nat.exists_eq_add_of_le hac
  rw [pow_add, mul_assoc] at h
  have h2 := Nat.eq_of_mul_eq_mul_left (by positivity) h
  cases t with
  | zero =>
    simp only [pow_zero, one_mul] at h2
    omega
  | succ t =>
    have : 2 * b + 1 = 2 * (2 ^ t * (2 * d + 1)) := by rw [h2]; ring
    omega
#print axioms odd_part_inj

def slot (q : ℕ × ℕ) : ℕ := 2 ^ q.1 * (2 * q.2 + 1) - 1
#print axioms slot

lemma slot_add_one (q : ℕ × ℕ) : slot q + 1 = 2 ^ q.1 * (2 * q.2 + 1) := by
  have : 1 ≤ 2 ^ q.1 * (2 * q.2 + 1) := Nat.one_le_iff_ne_zero.2 (by positivity)
  unfold slot
  omega
#print axioms slot_add_one

lemma slot_injective : Function.Injective slot := by
  intro q r h
  have h' : 2 ^ q.1 * (2 * q.2 + 1) = 2 ^ r.1 * (2 * r.2 + 1) := by
    rw [← slot_add_one, ← slot_add_one, h]
  rcases le_total q.1 r.1 with hle | hle
  · obtain ⟨h1, h2⟩ := odd_part_inj h' hle
    exact Prod.ext h1 h2
  · obtain ⟨h1, h2⟩ := odd_part_inj h'.symm hle
    exact Prod.ext h1.symm h2.symm
#print axioms slot_injective

/-- The generalized inverse of the distribution function. -/

noncomputable def quant (ν : Measure ℝ) (u : ℝ) : ℝ := sInf {t : ℝ | u ≤ cdf ν t}
#print axioms quant

lemma quant_le_iff (ν : Measure ℝ) [IsProbabilityMeasure ν] {u : ℝ} (hu0 : 0 < u) (hu1 : u < 1)
    (t : ℝ) : quant ν u ≤ t ↔ u ≤ cdf ν t := by
  have hne : {t : ℝ | u ≤ cdf ν t}.Nonempty := by
    obtain ⟨s, hs⟩ := ((tendsto_cdf_atTop ν).eventually (lt_mem_nhds hu1)).exists
    exact ⟨s, hs.le⟩
  have hbdd : BddBelow {t : ℝ | u ≤ cdf ν t} := by
    obtain ⟨t0, ht0⟩ := Filter.eventually_atBot.1
      ((tendsto_cdf_atBot ν).eventually (gt_mem_nhds hu0))
    refine ⟨t0, fun s hs => ?_⟩
    by_contra hlt
    push Not at hlt
    have := ht0 s hlt.le
    simp only [Set.mem_ofPred_eq] at hs
    linarith
  constructor
  · intro h
    have hall : ∀ s, t < s → u ≤ cdf ν s := by
      intro s hs
      obtain ⟨r, hr, hrs⟩ := exists_lt_of_csInf_lt hne (lt_of_le_of_lt h hs)
      exact hr.trans (monotone_cdf ν hrs.le)
    have hcont : Tendsto (cdf ν) (𝓝[>] t) (𝓝 (cdf ν t)) :=
      ((cdf ν).right_continuous t).tendsto.mono_left (nhdsWithin_mono _ Set.Ioi_subset_Ici_self)
    exact ge_of_tendsto hcont (eventually_nhdsWithin_of_forall hall)
  · intro h
    exact csInf_le hbdd h
#print axioms quant_le_iff

lemma quant_of_nonpos (ν : Measure ℝ) [IsProbabilityMeasure ν] {u : ℝ} (hu : u ≤ 0) :
    quant ν u = 0 := by
  have : {t : ℝ | u ≤ cdf ν t} = Set.univ := by
    ext t
    simp only [Set.mem_ofPred_eq, Set.mem_univ, iff_true]
    exact hu.trans (cdf_nonneg ν t)
  rw [quant, this, Real.sInf_of_not_bddBelow]
  rintro ⟨b, hb⟩
  have := hb (Set.mem_univ (b - 1))
  linarith
#print axioms quant_of_nonpos

lemma quant_of_one_lt (ν : Measure ℝ) [IsProbabilityMeasure ν] {u : ℝ} (hu : 1 < u) :
    quant ν u = 0 := by
  have : {t : ℝ | u ≤ cdf ν t} = ∅ := by
    ext t
    simp only [Set.mem_ofPred_eq, Set.mem_empty_iff_false, iff_false, not_le]
    exact (cdf_le_one ν t).trans_lt hu
  rw [quant, this, Real.sInf_empty]
#print axioms quant_of_one_lt

lemma measurable_quant (ν : Measure ℝ) [IsProbabilityMeasure ν] : Measurable (quant ν) := by
  refine measurable_of_Iic (fun t => ?_)
  set E := quant ν ⁻¹' Set.Iic t
  have hsplit : E = (E ∩ Set.Ioo 0 1) ∪ (E ∩ Set.Iic 0) ∪ (E ∩ Set.Ioi 1) ∪ (E ∩ {1}) := by
    ext u
    simp only [Set.mem_union, Set.mem_inter_iff, Set.mem_Ioo, Set.mem_Iic, Set.mem_Ioi,
      Set.mem_singleton_iff]
    constructor
    · intro hu
      rcases le_or_gt u 0 with h0 | h0
      · exact Or.inl (Or.inl (Or.inr ⟨hu, h0⟩))
      rcases lt_trichotomy u 1 with h1 | h1 | h1
      · exact Or.inl (Or.inl (Or.inl ⟨hu, h0, h1⟩))
      · exact Or.inr ⟨hu, h1⟩
      · exact Or.inl (Or.inr ⟨hu, h1⟩)
    · rintro (((⟨hu, _⟩ | ⟨hu, _⟩) | ⟨hu, _⟩) | ⟨hu, _⟩) <;> exact hu
  have h1 : E ∩ Set.Ioo 0 1 = Set.Iic (cdf ν t) ∩ Set.Ioo 0 1 := by
    ext u
    simp only [Set.mem_inter_iff, Set.mem_Ioo, Set.mem_Iic, Set.mem_preimage, E]
    constructor
    · rintro ⟨h, h0, h1⟩
      exact ⟨(quant_le_iff ν h0 h1 t).1 h, h0, h1⟩
    · rintro ⟨h, h0, h1⟩
      exact ⟨(quant_le_iff ν h0 h1 t).2 h, h0, h1⟩
  have h2 : E ∩ Set.Iic 0 = Set.Iic 0 ∩ {_u | 0 ≤ t} := by
    ext u
    simp only [Set.mem_inter_iff, Set.mem_Iic, Set.mem_preimage, E, Set.mem_ofPred_eq]
    constructor
    · rintro ⟨h, h0⟩
      rw [quant_of_nonpos ν h0] at h
      exact ⟨h0, h⟩
    · rintro ⟨h0, h⟩
      rw [quant_of_nonpos ν h0]
      exact ⟨h, h0⟩
  have h3 : E ∩ Set.Ioi 1 = Set.Ioi 1 ∩ {_u | 0 ≤ t} := by
    ext u
    simp only [Set.mem_inter_iff, Set.mem_Ioi, Set.mem_Iic, Set.mem_preimage, E,
      Set.mem_ofPred_eq]
    constructor
    · rintro ⟨h, h0⟩
      rw [quant_of_one_lt ν h0] at h
      exact ⟨h0, h⟩
    · rintro ⟨h0, h⟩
      rw [quant_of_one_lt ν h0]
      exact ⟨h, h0⟩
  have h4 : MeasurableSet (E ∩ {1}) :=
    (Set.subsingleton_singleton.anti Set.inter_subset_right).measurableSet
  rw [hsplit, h1, h2, h3]
  exact (((measurableSet_Iic.inter measurableSet_Ioo).union
    (measurableSet_Iic.inter (MeasurableSet.const _))).union
    (measurableSet_Ioi.inter (MeasurableSet.const _))).union h4
#print axioms measurable_quant

lemma map_quant (ν : Measure ℝ) [IsProbabilityMeasure ν] :
    (volume.restrict (Set.Ico (0:ℝ) 1)).map (quant ν) = ν := by
  refine Measure.ext_of_Iic _ _ (fun t => ?_)
  rw [Measure.map_apply (measurable_quant ν) measurableSet_Iic,
    Measure.restrict_apply' measurableSet_Ico, ← ofReal_cdf]
  set c := cdf ν t
  have hc0 : 0 ≤ c := cdf_nonneg ν t
  have hc1 : c ≤ 1 := cdf_le_one ν t
  apply le_antisymm
  · calc volume (quant ν ⁻¹' Set.Iic t ∩ Set.Ico 0 1) ≤ volume (Set.Icc 0 c) := by
          apply measure_mono
          rintro u ⟨hu, hu0, hu1⟩
          rcases eq_or_lt_of_le hu0 with h | h
          · subst h; exact ⟨le_rfl, hc0⟩
          · exact ⟨hu0, (quant_le_iff ν h hu1 t).1 hu⟩
      _ = ENNReal.ofReal c := by rw [Real.volume_Icc, sub_zero]
  · calc ENNReal.ofReal c = volume (Set.Ioo 0 c) := by rw [Real.volume_Ioo, sub_zero]
      _ ≤ volume (quant ν ⁻¹' Set.Iic t ∩ Set.Ico 0 1) := by
          apply measure_mono
          rintro u ⟨hu0, huc⟩
          have hu1 : u < 1 := lt_of_lt_of_le huc hc1
          exact ⟨(quant_le_iff ν hu0 hu1 t).2 huc.le, hu0.le, hu1⟩
#print axioms map_quant

end PileAux

namespace KolmoAux

/-- From the first `n + 1` terms as a `Fin`-tuple to the `Iic n` form. -/

def toIic (n : ℕ) (y : Fin (n + 1) → ℝ) : (Π _i : Finset.Iic n, ℝ) :=
  fun i => y ⟨i.1, Nat.lt_succ_of_le (Finset.mem_Iic.1 i.2)⟩
#print axioms toIic

def ofIic (n : ℕ) (z : Π _i : Finset.Iic n, ℝ) : Fin (n + 1) → ℝ :=
  fun i => z ⟨i.1, Finset.mem_Iic.2 (Nat.le_of_lt_succ i.2)⟩
#print axioms ofIic

lemma measurable_toIic (n : ℕ) : Measurable (toIic n) :=
  Measurable.of_eval (fun _ => measurable_pi_apply _)
#print axioms measurable_toIic

lemma measurable_ofIic (n : ℕ) : Measurable (ofIic n) :=
  Measurable.of_eval (fun _ => measurable_pi_apply _)
#print axioms measurable_ofIic

lemma measurable_init (n : ℕ) : Measurable (fun y : Fin (n + 1) → ℝ => Fin.init y) :=
  Measurable.of_eval (fun _ => measurable_pi_apply _)
#print axioms measurable_init

lemma measurable_firstN (n : ℕ) : Measurable (fun (ω : ℕ → ℝ) (i : Fin n) => ω i) :=
  Measurable.of_eval (fun _ => measurable_pi_apply _)
#print axioms measurable_firstN

lemma ofIic_toIic (n : ℕ) : ofIic n ∘ toIic n = id := by
  funext y i; rfl
#print axioms ofIic_toIic

lemma frestrictLe_eq (n : ℕ) :
    (Preorder.frestrictLe n : (ℕ → ℝ) → _) = toIic n ∘ (fun (ω : ℕ → ℝ) (i : Fin (n + 1)) => ω i) := by
  funext ω i; rfl
#print axioms frestrictLe_eq

lemma firstN_eq (n : ℕ) :
    (fun (ω : ℕ → ℝ) (i : Fin (n + 1)) => ω i) = ofIic n ∘ Preorder.frestrictLe n := by
  funext ω i; rfl
#print axioms firstN_eq

/-- If `Q` has the right finite-dimensional laws, its restriction to `Iic n` is determined. -/

lemma map_frestrictLe_of_prop (μ : ∀ n : ℕ, Measure (Fin n → ℝ)) (Q : Measure (ℕ → ℝ))
    (hQ : ∀ (n : ℕ) (A : Set (Fin n → ℝ)), MeasurableSet A →
        Q {ω : ℕ → ℝ | (fun i : Fin n => ω i) ∈ A} = μ n A) (n : ℕ) :
    Q.map (Preorder.frestrictLe n) = (μ (n + 1)).map (toIic n) := by
  have h1 : Q.map (fun (ω : ℕ → ℝ) (i : Fin (n + 1)) => ω i) = μ (n + 1) := by
    ext A hA
    rw [Measure.map_apply (measurable_firstN _) hA]
    exact hQ (n + 1) A hA
  rw [frestrictLe_eq, ← Measure.map_map (measurable_toIic n) (measurable_firstN _), h1]
#print axioms map_frestrictLe_of_prop

end KolmoAux

open DigitAux PileAux KolmoAux

/-- The digit theorem. Let a dart land on the interval `[0, 1)`, with chances given by
length. For every `n` and every pattern `e_1, …, e_n` of 0s and 1s, the set of points
whose first `n` binary digits are `e_1, …, e_n` has length `2^(-n)`, and that equals the
product of the lengths of the separate sets `{x : d_i(x) = e_i}`. Moreover, under length
on `[0, 1)` the digits `d_1, d_2, d_3, …` are independent, and each one equals 1 with
chance one half: they are independent fair coin tosses. -/
theorem binary_digits_are_independent_fair_coins :
    (∀ (n : ℕ) (e : Fin n → ℤ), (∀ i, e i = 0 ∨ e i = 1) →
      volume {x ∈ Set.Ico (0 : ℝ) 1 | ∀ i : Fin n, binDigit ((i : ℕ) + 1) x = e i}
          = (2⁻¹ : ℝ≥0∞) ^ n ∧
      volume {x ∈ Set.Ico (0 : ℝ) 1 | ∀ i : Fin n, binDigit ((i : ℕ) + 1) x = e i}
          = ∏ i : Fin n, volume {x ∈ Set.Ico (0 : ℝ) 1 | binDigit ((i : ℕ) + 1) x = e i}) ∧
    iIndepFun (fun (n : ℕ) (x : ℝ) => binDigit (n + 1) x) (volume.restrict (Set.Ico (0 : ℝ) 1)) ∧
    ∀ n : ℕ, volume.restrict (Set.Ico (0 : ℝ) 1) {x | binDigit (n + 1) x = 1} = 2⁻¹ := by
  refine ⟨?_, ?_, ?_⟩
  · intro n e he
    have hK := vol_digits n (fun i => {e i})
    simp only [Set.mem_singleton_iff] at hK
    have hc : ∀ i, cnt {e i} = 1 := fun i => cnt_singleton _ (he i)
    simp only [hc, Nat.cast_one, one_mul, Finset.prod_const, Finset.card_univ,
      Fintype.card_fin] at hK
    refine ⟨hK, ?_⟩
    rw [hK]
    have : ∀ i : Fin n, volume {x ∈ Set.Ico (0:ℝ) 1 | binDigit ((i:ℕ) + 1) x = e i} = 2⁻¹ := by
      intro i
      have := vol_digit (i:ℕ) {e i}
      simp only [Set.mem_singleton_iff, cnt_singleton _ (he i), Nat.cast_one, one_mul] at this
      exact this
    rw [Finset.prod_congr rfl (fun i _ => this i), Finset.prod_const, Finset.card_univ,
      Fintype.card_fin]
  · rw [iIndepFun_iff_measure_inter_preimage_eq_mul]
    intro S sets _
    classical
    let N := S.sup id + 1
    let A : Fin N → Set ℤ := fun i => if (i:ℕ) ∈ S then sets i else Set.univ
    have hS : ∀ i ∈ S, i < N := fun i hi => Nat.lt_succ_of_le (Finset.le_sup (f := id) hi)
    rw [Measure.restrict_apply' measurableSet_Ico]
    have hset : (⋂ i ∈ S, (fun x => binDigit (i + 1) x) ⁻¹' sets i) ∩ Set.Ico 0 1
        = {x ∈ Set.Ico (0:ℝ) 1 | ∀ i : Fin N, binDigit ((i:ℕ) + 1) x ∈ A i} := by
      ext x
      simp only [Set.mem_inter_iff, Set.mem_iInter, Set.mem_preimage, Set.mem_ofPred_eq, A]
      constructor
      · rintro ⟨h, hx⟩
        refine ⟨hx, fun i => ?_⟩
        split_ifs with hi
        · exact h i hi
        · trivial
      · rintro ⟨hx, h⟩
        refine ⟨fun i hi => ?_, hx⟩
        have := h ⟨i, hS i hi⟩
        simpa [hi] using this
    rw [hset, vol_digits]
    have hsingle : ∀ i, (volume.restrict (Set.Ico (0:ℝ) 1))
        ((fun x => binDigit (i + 1) x) ⁻¹' sets i) = cnt (sets i) * 2⁻¹ := by
      intro i
      rw [Measure.restrict_apply' measurableSet_Ico, ← vol_digit i (sets i)]
      congr 1
      ext x
      simp [and_comm]
    simp only [hsingle]
    rw [Fin.prod_univ_eq_prod_range
      (fun i => (cnt (if i ∈ S then sets i else Set.univ) : ℝ≥0∞) * 2⁻¹) N]
    have hsub : S ⊆ Finset.range N := fun i hi => Finset.mem_range.2 (hS i hi)
    rw [← Finset.prod_subset hsub]
    · apply Finset.prod_congr rfl
      intro i hi
      simp [hi]
    · intro i _ hi
      simp only [hi, ite_false, cnt_univ]
      push_cast
      exact ENNReal.mul_inv_cancel (by norm_num) (by norm_num)
  · intro n
    rw [Measure.restrict_apply' measurableSet_Ico]
    have := vol_digit n {1}
    rw [cnt_singleton 1 (Or.inr rfl)] at this
    simp only [Set.mem_singleton_iff, Nat.cast_one, one_mul] at this
    rw [← this]
    congr 1
    ext x
    simp [and_comm]

/-- The splitting theorem. Deal the digits of a uniform point of `[0, 1)` into piles, the
`j`-th digit of pile `k` being the old digit at position `2^(k-1)(2j - 1)`, and read each
pile as a binary number `U_k`. Then `U_1, U_2, U_3, …` are independent, and each is uniform
on the unit interval. Hence for every distribution function `F` (here the distribution
function `cdf μ` of a probability `μ` on the line), with quantile map
`Q(u) = inf {t : F(t) ≥ u}`, the draws `X_k = Q(U_k)` are independent and each has law `F`. -/
theorem piles_of_digits_are_independent_uniforms :
    iIndepFun pile (volume.restrict (Set.Ico (0 : ℝ) 1)) ∧
    (∀ k : ℕ, (volume.restrict (Set.Ico (0 : ℝ) 1)).map (pile k)
        = volume.restrict (Set.Ico (0 : ℝ) 1)) ∧
    ∀ (μ : Measure ℝ) [IsProbabilityMeasure μ],
      iIndepFun (fun (k : ℕ) (x : ℝ) => sInf {t : ℝ | pile k x ≤ cdf μ t})
          (volume.restrict (Set.Ico (0 : ℝ) 1)) ∧
      ∀ k : ℕ, (volume.restrict (Set.Ico (0 : ℝ) 1)).map
          (fun x => sInf {t : ℝ | pile k x ≤ cdf μ t}) = μ := by
  let β : Measure ℤ := (volume.restrict (Set.Ico (0:ℝ) 1)).map (binDigit (0 + 1))
  have hind := binary_digits_are_independent_fair_coins.2.1
  let D : ℝ → ℕ → ℤ := fun x n => binDigit (n + 1) x
  have hD : Measurable D := Measurable.of_eval (fun n => measurable_binDigit (n + 1))
  have hlawD : (volume.restrict (Set.Ico (0:ℝ) 1)).map D
      = Measure.infinitePi (fun _ : ℕ => β) := by
    have := hind.map_fun_eq_infinitePi_map (fun n => measurable_binDigit (n + 1))
    refine this.trans ?_
    congr 1
    funext n
    exact law_digit n
  let M : (ℕ → ℤ) → (ℕ × ℕ → ℤ) := fun ω q => ω (slot q)
  have hMm : Measurable M := Measurable.of_eval (fun q => measurable_pi_apply _)
  have hM : (Measure.infinitePi (fun _ : ℕ => β)).map M
      = Measure.infinitePi (fun _ : ℕ × ℕ => β) :=
    Measure.map_infinitePi_infinitePi_of_inj slot_injective
  let C := MeasurableEquiv.curry ℕ ℕ ℤ
  have hC : (Measure.infinitePi (fun _ : ℕ × ℕ => β)).map C
      = Measure.infinitePi (fun _ : ℕ => Measure.infinitePi (fun _ : ℕ => β)) :=
    Measure.infinitePi_map_curry (fun _ _ => β)
  let G : ℝ → ℕ → ℕ → ℤ := C ∘ M ∘ D
  have hGm : Measurable G := C.measurable.comp (hMm.comp hD)
  have hG : (volume.restrict (Set.Ico (0:ℝ) 1)).map G
      = Measure.infinitePi (fun _ : ℕ => Measure.infinitePi (fun _ : ℕ => β)) := by
    rw [← Measure.map_map C.measurable (hMm.comp hD), ← Measure.map_map hMm hD, hlawD, hM, hC]
  have hpile : ∀ k, pile k = Φ ∘ (fun ω => ω k) ∘ G := by
    intro k
    funext x
    simp only [pile, Φ, Function.comp_apply, G, C, M, D, MeasurableEquiv.curry_apply]
    congr 1
    funext j
    rw [binDigit_mod_two, slot_add_one]
  have hpm : ∀ k, Measurable (pile k) := by
    intro k
    rw [hpile]
    exact measurable_Φ.comp ((measurable_pi_apply k).comp hGm)
  have hΦlaw : (Measure.infinitePi (fun _ : ℕ => β)).map Φ = volume.restrict (Set.Ico (0:ℝ) 1) := by
    rw [← hlawD, Measure.map_map measurable_Φ hD]
    have : Φ ∘ D =ᵐ[volume.restrict (Set.Ico (0:ℝ) 1)] id :=
      (ae_restrict_mem measurableSet_Ico).mono (fun x hx => Φ_digits x hx)
    rw [Measure.map_congr this, Measure.map_id]
  have hlaw : ∀ k, (volume.restrict (Set.Ico (0:ℝ) 1)).map (pile k)
      = volume.restrict (Set.Ico (0:ℝ) 1) := by
    intro k
    rw [hpile, ← Measure.map_map measurable_Φ ((measurable_pi_apply k).comp hGm),
      ← Measure.map_map (measurable_pi_apply k) hGm, hG, Measure.infinitePi_map_eval, hΦlaw]
  have hindP : iIndepFun pile (volume.restrict (Set.Ico (0 : ℝ) 1)) := by
    rw [iIndepFun_iff_map_fun_eq_infinitePi_map hpm]
    have h1 : (fun k => (volume.restrict (Set.Ico (0:ℝ) 1)).map (pile k))
        = fun _ => volume.restrict (Set.Ico (0:ℝ) 1) := funext hlaw
    have h2 : (fun x k => pile k x) = (fun (ω : ℕ → ℕ → ℤ) k => Φ (ω k)) ∘ G := by
      funext x k
      rw [hpile]
      rfl
    have h3 : Measurable (fun (ω : ℕ → ℕ → ℤ) k => Φ (ω k)) :=
      Measurable.of_eval (fun k => measurable_Φ.comp (measurable_pi_apply k))
    rw [h1, h2, ← Measure.map_map h3 hGm, hG,
      Measure.infinitePi_map_pi _ (fun _ => measurable_Φ), hΦlaw]
  refine ⟨hindP, hlaw, fun ν _ => ⟨?_, fun k => ?_⟩⟩
  · exact hindP.comp (fun _ => quant ν) (fun _ => measurable_quant ν)
  · rw [show (fun x => sInf {t : ℝ | pile k x ≤ cdf ν t}) = quant ν ∘ pile k from rfl,
      ← Measure.map_map (measurable_quant ν) (hpm k), hlaw k, map_quant]

/-- Kolmogorov's extension theorem. For every `n` let `μ_n` be a probability on the Borel
sets of `ℝ^n`, the `n`-long lists of reals. Suppose the family is consistent: adding a
coordinate and asking nothing of it changes nothing, `μ_{n+1}(A × ℝ) = μ_n(A)` for every
`n` and every Borel set `A`. Then there is exactly one probability `P` on the whole
sequences `ℝ^ℕ`, with the product sigma-algebra, such that the chance that the first `n`
terms lie in `A` is `μ_n(A)`, for every `n` and every Borel set `A ⊆ ℝ^n`. -/
theorem kolmogorov_extension_theorem (μ : ∀ n : ℕ, Measure (Fin n → ℝ))
    [∀ n, IsProbabilityMeasure (μ n)]
    (hcons : ∀ (n : ℕ) (A : Set (Fin n → ℝ)), MeasurableSet A →
      μ (n + 1) {y : Fin (n + 1) → ℝ | Fin.init y ∈ A} = μ n A) :
    ∃! P : Measure (ℕ → ℝ), IsProbabilityMeasure P ∧
      ∀ (n : ℕ) (A : Set (Fin n → ℝ)), MeasurableSet A →
        P {ω : ℕ → ℝ | (fun i : Fin n => ω i) ∈ A} = μ n A := by
  -- consistency as an equality of measures
  have hc : ∀ n, (μ (n + 1)).map (fun y => Fin.init y) = μ n := by
    intro n
    ext A hA
    rw [Measure.map_apply (measurable_init n) hA]
    exact hcons n A hA
  -- the laws on `Iic n`
  let ν : ∀ n : ℕ, Measure (Π _i : Finset.Iic n, ℝ) := fun n => (μ (n + 1)).map (toIic n)
  -- the joint laws of (first n+1 terms, next term)
  let h : ∀ n : ℕ, (Fin (n + 2) → ℝ) → (Π _i : Finset.Iic n, ℝ) × ℝ :=
    fun n y => (toIic n (Fin.init y), y (Fin.last (n + 1)))
  have hmeas : ∀ n, Measurable (h n) := fun n =>
    ((measurable_toIic n).comp (measurable_init (n + 1))).prodMk (measurable_pi_apply _)
  let ρ : ∀ n : ℕ, Measure ((Π _i : Finset.Iic n, ℝ) × ℝ) := fun n => (μ (n + 2)).map (h n)
  have hρfst : ∀ n, (ρ n).fst = ν n := by
    intro n
    have h1 : (ρ n).fst = (μ (n + 2)).map (toIic n ∘ fun y => Fin.init y) :=
      Measure.fst_map_prodMk ((measurable_toIic n).comp (measurable_init (n + 1)))
        (measurable_pi_apply _)
    rw [h1, ← Measure.map_map (measurable_toIic n) (measurable_init (n + 1)), hc (n + 1)]
  let κ : ∀ n : ℕ, Kernel (Π _i : Finset.Iic n, ℝ) ℝ := fun n => (ρ n).condKernel
  let μ₀ : Measure ℝ := (μ 1).map (fun y => y 0)
  let P : Measure (ℕ → ℝ) := Kernel.trajMeasure (X := fun _ => ℝ) μ₀ κ
  have hP : ∀ a, P.map (Preorder.frestrictLe a) = ν a := by
    intro a
    induction a with
    | zero =>
      simp only [P, Kernel.trajMeasure]
      rw [Measure.map_comp _ _ (Preorder.measurable_frestrictLe 0), Kernel.traj_map_frestrictLe,
        Kernel.partialTraj_self, Measure.id_comp]
      simp only [μ₀, ν]
      rw [Measure.map_map (MeasurableEquiv.measurable _) (by fun_prop)]
      congr 1
      funext y i
      have hi : i = default := Subsingleton.elim _ _
      subst hi
      rfl
    | succ a ih =>
      let g : (Π _i : Finset.Iic a, ℝ) × ℝ → (Π _i : Finset.Iic (a + 1), ℝ) :=
        fun p i => if hi : i.1 ≤ a then p.1 ⟨i.1, Finset.mem_Iic.2 hi⟩ else p.2
      have hg : Measurable g := by
        refine Measurable.of_eval (fun i => ?_)
        by_cases hi : i.1 ≤ a
        · simp only [g, hi, dite_true]
          exact (measurable_pi_apply _).comp measurable_fst
        · simp only [g, hi, dite_false]
          exact measurable_snd
      have hsplit : (Preorder.frestrictLe (a + 1) : (ℕ → ℝ) → _)
          = g ∘ (fun x : ℕ → ℝ => (Preorder.frestrictLe a x, x (a + 1))) := by
        funext x i
        simp only [g, Function.comp_apply, Preorder.frestrictLe_apply]
        split_ifs with hi
        · rfl
        · have : i.1 = a + 1 := by
            have := Finset.mem_Iic.1 i.2
            omega
          simp [this]
      have hcomp : g ∘ h a = toIic (a + 1) := by
        funext y i
        simp only [g, h, Function.comp_apply, toIic]
        split_ifs with hi
        · rfl
        · have : i.1 = a + 1 := by
            have := Finset.mem_Iic.1 i.2
            omega
          congr 1
          ext
          simp [this]
      rw [hsplit, ← Measure.map_map hg (by fun_prop),
        ← Kernel.map_frestrictLe_trajMeasure_compProd_eq_map_trajMeasure, ih, ← hρfst,
        Measure.disintegrate, Measure.map_map hg (hmeas a), hcomp]
  have hprop : ∀ (n : ℕ) (A : Set (Fin n → ℝ)), MeasurableSet A →
      P {ω : ℕ → ℝ | (fun i : Fin n => ω i) ∈ A} = μ n A := by
    intro n A hA
    cases n with
    | zero =>
      by_cases hne : A.Nonempty
      · have hA' : A = Set.univ := by
          obtain ⟨y, hy⟩ := hne
          ext z
          simp only [Set.mem_univ, iff_true]
          rwa [Subsingleton.elim z y]
        subst hA'
        simp
      · rw [Set.not_nonempty_iff_eq_empty] at hne
        subst hne
        simp
    | succ a =>
      have : {ω : ℕ → ℝ | (fun i : Fin (a + 1) => ω i) ∈ A}
          = (fun (ω : ℕ → ℝ) (i : Fin (a + 1)) => ω i) ⁻¹' A := rfl
      rw [this, ← Measure.map_apply (measurable_firstN _) hA, firstN_eq,
        ← Measure.map_map (measurable_ofIic a) (Preorder.measurable_frestrictLe a), hP a]
      simp only [ν]
      rw [Measure.map_map (measurable_ofIic a) (measurable_toIic a), ofIic_toIic, Measure.map_id]
  refine ⟨P, ⟨inferInstance, hprop⟩, ?_⟩
  rintro Q ⟨hQprob, hQ⟩
  let F : ∀ I : Finset ℕ, Measure (Π _i : I, ℝ) := fun I => P.map I.restrict
  have hF : IsProjectiveMeasureFamily (α := fun _ : ℕ => ℝ) F := by
    intro I J hJI
    simp only [F]
    rw [Measure.map_map (Finset.measurable_restrict₂ hJI) (Finset.measurable_restrict I),
      Finset.restrict₂_comp_restrict]
  have hPlim : IsProjectiveLimit (α := fun _ : ℕ => ℝ) P F := fun I => rfl
  have hQlim : IsProjectiveLimit (α := fun _ : ℕ => ℝ) Q F := by
    rw [isProjectiveLimit_nat_iff hF]
    intro n
    simp only [F]
    rw [map_frestrictLe_of_prop μ Q hQ n]
    exact (map_frestrictLe_of_prop μ P hprop n).symm
  exact hQlim.unique hPlim

/-! The card's worked numbers, exactly. The dart is at 0.7236 = 1809/2500, so its `n`-th
binary digit is `⌊2^n · 1809 / 2500⌋ mod 2`, a whole-number computation. -/

-- The dart's first sixteen binary digits: 1 0 1 1 1 0 0 1 0 0 1 1 1 1 0 1.
example : (List.range 16).map (fun i => 2 ^ (i + 1) * 1809 / 2500 % 2)
    = [1, 0, 1, 1, 1, 0, 0, 1, 0, 0, 1, 1, 1, 1, 0, 1] := by decide

-- The same digits through the card's real definition, for the first three: 1, 0, 1.
example : binDigit 1 (1809 / 2500) = 1 ∧ binDigit 2 (1809 / 2500) = 0 ∧
    binDigit 3 (1809 / 2500) = 1 := by
  have h1 : ⌊(2 : ℝ) ^ 1 * (1809 / 2500)⌋ = 1 := by rw [Int.floor_eq_iff]; norm_num
  have h2 : ⌊(2 : ℝ) ^ 2 * (1809 / 2500)⌋ = 2 := by rw [Int.floor_eq_iff]; norm_num
  have h3 : ⌊(2 : ℝ) ^ 3 * (1809 / 2500)⌋ = 5 := by rw [Int.floor_eq_iff]; norm_num
  simp only [binDigit, h1, h2, h3]; decide

-- Step 1: the pattern 1, 0, 1 is m = 5 with n = 3, and the dart lies in [5/8, 6/8).
example : 2 ^ 3 * 1809 / 2500 = 5 ∧ (5 : ℚ) / 8 ≤ 1809 / 2500 ∧ (1809 : ℚ) / 2500 < 6 / 8 := by
  norm_num

-- Step 2: digits 2, 5, 7 fixed to 1, 0, 1 among the first seven: 16 of the 128 cells of
-- length 1/128, chance 16/128 = (1/2)^3. (Cell i has digit p equal to i / 2^(7-p) mod 2.)
example : ((Finset.range 128).filter
    (fun i => i / 2 ^ 5 % 2 = 1 ∧ i / 2 ^ 2 % 2 = 0 ∧ i % 2 = 1)).card = 16 := by decide
example : (16 : ℚ) / 128 = (1 / 2) ^ 3 := by norm_num

-- The code's count: all patterns of lengths 1 to 12 number 8,190.
example : ∑ n ∈ Finset.Icc 1 12, 2 ^ n = 8190 := by decide

-- Step 3: positions 1 to 16 go to piles 1 2 1 3 1 2 1 4 1 2 1 3 1 2 1 5; position n goes to
-- pile k exactly when 2^(k-1) divides n and leaves an odd number.
example : (List.range 16).zip [1, 2, 1, 3, 1, 2, 1, 4, 1, 2, 1, 3, 1, 2, 1, 5] |>.all
    (fun p => (p.1 + 1) % 2 ^ (p.2 - 1) = 0 ∧ (p.1 + 1) / 2 ^ (p.2 - 1) % 2 = 1) := by decide

-- The slot s(2, 3) = 2^(2-1) (2·3 - 1) = 10.
example : 2 ^ (2 - 1) * (2 * 3 - 1) = 10 := by norm_num

-- Step 5: twelve old digits give the four piles 6, 3, 2 and 1 digits: 64 × 8 × 4 × 2 = 4096.
example : 2 ^ 6 * 2 ^ 3 * 2 ^ 2 * 2 ^ 1 = 4096 ∧ 4096 = 2 ^ 12 := by norm_num

-- Step 6: the die rolls ⌊6 U_k⌋ + 1 from 20 digits of each of the first four piles are
-- 6, 1, 6, 5. Pile k (from 1) reads the dart's digits at positions 2^(k-1)(2j - 1).
set_option exponentiation.threshold 400 in
example : (List.range 4).map (fun k => 6 * (∑ j ∈ Finset.range 20,
    (2 ^ (2 ^ k * (2 * j + 1)) * 1809 / 2500 % 2) * 2 ^ (19 - j)) / 2 ^ 20 + 1)
    = [6, 1, 6, 5] := by decide

-- Step 7: the sticky coin gives three heads the chance (1/2)(4/5)(4/5) = 8/25 = 0.32.
example : (1 : ℚ) / 2 * (4 / 5) * (4 / 5) = 32 / 100 := by norm_num

-- When it holds: a dart with density 2x has P(d_1 = 1) = 1 - (1/2)^2 = 3/4,
-- P(d_2 = 1) = (1/2)^2 - (1/4)^2 + 1 - (3/4)^2 = 5/8, and P(both) = 1 - (3/4)^2 = 7/16,
-- which is not the product 3/4 × 5/8 = 15/32.
example : (1 : ℚ) - (1 / 2) ^ 2 = 3 / 4 ∧
    (1 / 2 : ℚ) ^ 2 - (1 / 4) ^ 2 + 1 - (3 / 4) ^ 2 = 5 / 8 ∧
    (1 : ℚ) - (3 / 4) ^ 2 = 7 / 16 ∧ (3 / 4 : ℚ) * (5 / 8) = 15 / 32 ∧
    (7 / 16 : ℚ) ≠ 15 / 32 := by norm_num

-- Shared digits: Var U = 1/12, Cov(U, d_1) = 3/8 - 1/4 = 1/8, Cov(U, V) = 2/12 - 1/8 = 1/24,
-- correlation (1/24) / (1/12) = 1/2.
example : (3 : ℚ) / 8 - 1 / 4 = 1 / 8 ∧ 2 * (1 / 12 : ℚ) - 1 / 8 = 1 / 24 ∧
    (1 / 24 : ℚ) / (1 / 12) = 1 / 2 := by norm_num

#print axioms binary_digits_are_independent_fair_coins
#print axioms piles_of_digits_are_independent_uniforms
#print axioms kolmogorov_extension_theorem
```

**Checked 2026-11-13 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'DigitAux.binDigit_eq_nat' depends on axioms: [propext, Classical.choice, Quot.sound]
'DigitAux.floor_set_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'DigitAux.vol_floor_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'DigitAux.cnt' depends on axioms: [propext, Classical.choice, Quot.sound]
'DigitAux.count_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'DigitAux.vol_digits' depends on axioms: [propext, Classical.choice, Quot.sound]
'DigitAux.cnt_univ' depends on axioms: [propext, Classical.choice, Quot.sound]
'DigitAux.vol_digit' depends on axioms: [propext, Classical.choice, Quot.sound]
'DigitAux.cnt_singleton' depends on axioms: [propext, Classical.choice, Quot.sound]
'DigitAux.isProbabilityMeasure_Ico' depends on axioms: [propext, Classical.choice, Quot.sound]
'PileAux.measurable_binDigit' depends on axioms: [propext, Classical.choice, Quot.sound]
'PileAux.binDigit_mod_two' depends on axioms: [propext, Classical.choice, Quot.sound]
'PileAux.vol_preimage' depends on axioms: [propext, Classical.choice, Quot.sound]
'PileAux.law_digit' depends on axioms: [propext, Classical.choice, Quot.sound]
'PileAux.Φ' depends on axioms: [propext, Classical.choice, Quot.sound]
'PileAux.term_nonneg' depends on axioms: [propext, Classical.choice, Quot.sound]
'PileAux.term_le' depends on axioms: [propext, Classical.choice, Quot.sound]
'PileAux.summable_term' depends on axioms: [propext, Classical.choice, Quot.sound]
'PileAux.measurable_Φ' depends on axioms: [propext, Classical.choice, Quot.sound]
'PileAux.partial_sum' depends on axioms: [propext, Classical.choice, Quot.sound]
'PileAux.hasSum_digits' depends on axioms: [propext, Classical.choice, Quot.sound]
'PileAux.Φ_digits' depends on axioms: [propext, Classical.choice, Quot.sound]
'PileAux.odd_part_inj' depends on axioms: [propext, Classical.choice, Quot.sound]
'PileAux.slot' depends on axioms: [propext]
'PileAux.slot_add_one' depends on axioms: [propext, Classical.choice, Quot.sound]
'PileAux.slot_injective' depends on axioms: [propext, Classical.choice, Quot.sound]
'PileAux.quant' depends on axioms: [propext, Classical.choice, Quot.sound]
'PileAux.quant_le_iff' depends on axioms: [propext, Classical.choice, Quot.sound]
'PileAux.quant_of_nonpos' depends on axioms: [propext, Classical.choice, Quot.sound]
'PileAux.quant_of_one_lt' depends on axioms: [propext, Classical.choice, Quot.sound]
'PileAux.measurable_quant' depends on axioms: [propext, Classical.choice, Quot.sound]
'PileAux.map_quant' depends on axioms: [propext, Classical.choice, Quot.sound]
'KolmoAux.toIic' depends on axioms: [propext, Classical.choice, Quot.sound]
'KolmoAux.ofIic' depends on axioms: [propext, Classical.choice, Quot.sound]
'KolmoAux.measurable_toIic' depends on axioms: [propext, Classical.choice, Quot.sound]
'KolmoAux.measurable_ofIic' depends on axioms: [propext, Classical.choice, Quot.sound]
'KolmoAux.measurable_init' depends on axioms: [propext, Classical.choice, Quot.sound]
'KolmoAux.measurable_firstN' depends on axioms: [propext, Classical.choice, Quot.sound]
'KolmoAux.ofIic_toIic' depends on axioms: [propext, Classical.choice, Quot.sound]
'KolmoAux.frestrictLe_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'KolmoAux.firstN_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'KolmoAux.map_frestrictLe_of_prop' depends on axioms: [propext, Classical.choice, Quot.sound]
'binary_digits_are_independent_fair_coins' depends on axioms: [propext, Classical.choice, Quot.sound]
'piles_of_digits_are_independent_uniforms' depends on axioms: [propext, Classical.choice, Quot.sound]
'kolmogorov_extension_theorem' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run the Python. The asserts are pinned to the card's numbers.
> - **Put two positions in one slot.** In `slot`, return `(k, (n + 1) // 4 + 1)`, which sends places 2 and 3 of every pile to one slot, and 4 and 5, and so on. The two readings of the split disagree and the first assert stops it.
> - **Break the sticky coin.** Change `Fr(4, 5)` to `Fr(3, 5)`. The weights after a toss add to 0.8, sums over the last toss stop matching, and the consistency assert fails.
> - **Drop the uniform dart.** In the simulation loop, square `u1` after it is read. U1 falls below 0.5 with chance about 0.71, and the first simulated assert stops the run.
> - **Tighten the tolerance.** In the assert inside the simulation's printing loop, change 4 standard errors to 1. The three-uniform event, 1.3 out, now fails: simulations drift by chance, and a band of one standard error is missed about one time in three.

---

## The usual mistake

> [!warning]
> **Thinking simulated random numbers settle the question.** A simulation draws finitely many digits. The laws of large numbers speak about the whole endless sequence, "the share of heads tends to 0.5 except on a set of chance zero", and that needs one probability on all sequences at once: the digit theorem or Kolmogorov's theorem.
>
> - **Reusing digits.** U from digits 1, 2, 3, … and V from 2, 3, 4, … are both uniform, yet correlated at 0.5.
> - **Assuming consistency.** Finite laws written one n at a time can contradict each other: the even-heads family gives the first toss heads with chance 0 and 0.5.
> - **Confusing the law with the space.** Kolmogorov fixes the law of the sequence, not where it lives: the digit construction and the product space carry the same coin-toss law.
> - **Asking uncountable questions.** Indexed by continuous time, "the path is continuous" is not an event of the product sigma-algebra.

---

## Where you meet it in real life

- **Random-number generators.** A 64-bit word from a generator is meant to be 64 fair coin tosses, and one word is routinely cut into several smaller numbers, as the simulation above deals 128 digits into four piles.
- **Monte Carlo pricing.** A simulation estimate of an option price, such as the call in [Black–Scholes call](../../12-Financial%20mathematics/08-The%20Black-Scholes%20call%20and%20put/01-black-scholes-call.md), averages over thousands of independent normal shocks, each a uniform sent through the normal quantile map.
- **Markov chains.** The sticky coin is a two-state Markov chain, whose next term depends only on the last. Queues, credit ratings and weather states are modelled this way, and Kolmogorov's theorem is why such a chain is one probability on whole paths.

> **Say it back**
> The binary digits of a uniform point are independent fair coins, because fixing n digits leaves one interval of length 2^-n. Every position is a power of 2 times an odd number in one way only, so the digits deal into infinitely many disjoint piles, each spelling an independent uniform. Quantile maps turn those into independent draws of any law, and pairs of them into independent darts. For dependent sequences, Kolmogorov's theorem gives one law on whole sequences whenever the laws of the first n terms fit together.

---

## What this builds on

- [Independence as a product](04-independence-as-a-product-measure.md): independence as products on every finite subfamily, checked on generating pi-systems.
- [Lebesgue measure](../02-Length%20Done%20Properly/03-lebesgue-measure.md): length on the unit interval, which measures every digit event.
- [The law of a random variable](../03-Measurable%20Functions/05-pushforward-and-the-law.md): the quantile map, turning one uniform into a draw of any law.
- [Countable sets](../../01-Foundations/09-Sizes%20of%20Infinity/02-countable-sets.md): pairs of whole numbers listed one-to-one against the whole numbers, which is the slot rule.

## Where this goes next

- [Kolmogorov's zero-one law](../10-The%20Limit%20Theorems%2C%20Proved/02-kolmogorov-zero-one-law.md): on this card's space of independent tosses, every event unaffected by any finite number of tosses has chance 0 or 1.

This card builds one space that carries a whole independent sequence; which of its events can have a chance strictly between 0 and 1 is the question [Kolmogorov's zero-one law](../10-The%20Limit%20Theorems%2C%20Proved/02-kolmogorov-zero-one-law.md) answers for the events that live far out in the tail.

---

## Sources

Verified 2026-09-29: every link below resolves to the publisher's or author's page.

- Borel, Émile. "Les probabilités dénombrables et leurs applications arithmétiques." *Rendiconti del Circolo Matematico di Palermo* 27 (1909), 247–271. [doi:10.1007/BF03019651](https://doi.org/10.1007/BF03019651). The normal-number paper, which treats binary digits as independent coin tosses.
- Kolmogoroff, A. *Grundbegriffe der Wahrscheinlichkeitsrechnung*. Springer, 1933. [doi:10.1007/978-3-642-49888-6](https://doi.org/10.1007/978-3-642-49888-6). The book that founded probability on measure; it proves the extension theorem for consistent families.
- Billingsley, Patrick. *Probability and Measure*, Anniversary Edition. Wiley, 2012. [Publisher page](https://www.wiley.com/en-us/Probability+and+Measure%2C+Anniversary+Edition-p-9781118122372). Opens with dyadic digits as coin tosses and proves Kolmogorov's existence theorem in Section 36.
- Durrett, Rick. *Probability: Theory and Examples*, 5th ed. [Author's page, with the full text](https://sites.math.duke.edu/~rtd/PTE/pte.html). States the extension theorem as Theorem 2.1.21 to build independent sequences, proves it as Theorem A.3.1, and notes in Chapter 7 that continuous paths are not an event of the product sigma-algebra.
