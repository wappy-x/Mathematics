# Lebesgue-Stieltjes measures -- the check behind the card.  Standard library
# only: exact fractions for F and for the grid on [0, 1), and SplitMix64 written
# out here for the simulated claims.  Money in dollars, probabilities as decimals.
from fractions import Fraction as Fr
from math import sqrt

MASK = (1 << 64) - 1
P0, TOP = Fr(3, 10), 1000                     # 0.3 chance of $0; else even on 0 to 1,000

def F(x):                                     # distribution function: P(claim <= x)
    x = Fr(x)
    if x < 0:
        return Fr(0)
    return P0 + (1 - P0) * x / TOP if x < TOP else Fr(1)

def G(x):                                     # the left-continuous version: P(claim < x)
    x = Fr(x)
    return Fr(0) if x <= 0 else F(x)

def mass(a, b, cdf=F):                        # road one: the formula on (a, b]
    return cdf(b) - cdf(a)

def dec(r, digits=15):                        # exact decimal, first 15 places, zeros trimmed
    r = Fr(r)
    sign, r = ("-" if r < 0 else ""), abs(r)
    out, num, den = f"{r.numerator // r.denominator}.", r.numerator % r.denominator, r.denominator
    for _ in range(digits):
        num *= 10
        out += str(num // den)
        num %= den
    return sign + out.rstrip("0").rstrip(".")

N = 10000                                     # road two: [0, 1) cut into N equal cells

def claim_of(w):                              # the claim as a function of a point w in [0, 1)
    return Fr(0) if w < P0 else TOP * (w - P0) / (1 - P0)

cells = [claim_of(Fr(2 * k + 1, 2 * N)) for k in range(N)]     # cell midpoints

def grid(test):                               # length of {w : test(claim(w))}, cell by cell
    return Fr(sum(1 for c in cells if test(c)), N)

def splitmix(state):
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return state, z ^ (z >> 31)

print("claim: $0 with probability 0.3, otherwise even over $0 to $1000")
print(f"F(-100) = {dec(F(-100))}, F(0) = {dec(F(0))}, F(200) = {dec(F(200))}, "
      f"F(500) = {dec(F(500))}, F(1000) = {dec(F(1000))}")
xs = [-200, -100, None, 0] + list(range(100, 1101, 100))
print("chart, F at -200, -100, just below 0, 0, 100, 200, ..., 1100: "
      + ", ".join(f"{float(F(-Fr(1, 10**9)) if x is None else F(x)):.2f}" for x in xs))
road1 = mass(200, 500)
road2 = grid(lambda c: 200 < c <= 500)
print(f"road 1, formula: mu((200, 500]) = F(500) - F(200) = {dec(road1)}")
print(f"road 2, length on [0, 1): {N} cells, {road2 * N} send the claim into (200, 500], mass {dec(road2)}")

state, n, hits, zeros = 2026, 100000, 0, 0
for _ in range(n):
    state, r1 = splitmix(state)
    state, r2 = splitmix(state)
    if (r1 >> 11) / 2**53 < 0.3:
        zeros += 1
        continue
    amount = 1000.0 * ((r2 >> 11) / 2**53)
    hits += 200.0 < amount <= 500.0
se = lambda p: sqrt(p * (1 - p) / n)
print(f"road 3, simulation (SplitMix64, seed 2026): {n} claims, {hits} in (200, 500], share "
      f"{dec(Fr(hits, n))}; 4 standard errors = {4 * se(0.21):.5f}")
print(f"         claims of exactly $0: {zeros}, share {dec(Fr(zeros, n))}; 4 standard errors = {4 * se(0.3):.5f}")

print("jump at 0: F(0) - F(0 - 1/2^n), n = 1, 5, 10: "
      + ", ".join(dec(F(0) - F(-Fr(1, 2**k))) for k in (1, 5, 10)) + f"; point mass {dec(F(0))}")
print(f"road 2, cells sending the claim to exactly $0: {grid(lambda c: c == 0) * N}, mass {dec(grid(lambda c: c == 0))}")
print("right limit at 0: F(0 + 1/2^n), n = 1, 5, 10: "
      + ", ".join(dec(F(Fr(1, 2**k))) for k in (1, 5, 10)))
print("no jump at 350: F(350) - F(350 - 1/2^n), n = 1, 5, 10: "
      + ", ".join(dec(F(350) - F(350 - Fr(1, 2**k))) for k in (1, 5, 10)))
print(f"claim above a $200 deductible: 1 - F(200) = {dec(1 - F(200))}")

pieces = lambda k: (Fr(500, 2**(k + 1)), Fr(500, 2**k))           # (0, 500] cut in halves
print("(0, 500] as the pieces (500/2^(k+1), 500/2^k], k = 0, 1, 2, ...")
for count in (10, 20, 40):
    total = sum(mass(*pieces(k)) for k in range(count))
    tail_free = Fr(7, 10) * (500 - Fr(500, 2**count)) / TOP        # the even part, measured directly
    assert total == tail_free                                     # two roads to a partial sum
    print(f"  sum of the first {count} pieces: {dec(total)}")
whole_F, whole_G = mass(0, 500), mass(0, 500, G)
open_left = grid(lambda c: 0 < c <= 500)
print(f"right-continuous F: F(500) - F(0) = {dec(whole_F)}; road 2 on the grid: {dec(open_left)}")
print(f"mistake 1, left-continuous G(x) = P(claim < x): G(500) - G(0) = {dec(whole_G)}, "
      f"pieces still sum to {dec(whole_F)}: additivity fails by {dec(whole_G - whole_F)}")
closed = grid(lambda c: 0 <= c <= 500)
print(f"mistake 2, closed [0, 500] as F(500) - F(0) = {dec(whole_F)}; "
      f"true F(500) - F(0-) = {dec(F(500) - F(-Fr(1, 10**9)))}; road 2: {dec(closed)}")
slopes = sum(F(x + 1) - F(x) for x in range(0, TOP))
print(f"mistake 3, density only: slope 0.0007 per dollar summed over (0, 1000) = {dec(slopes)}; "
      f"missing {dec(1 - slopes)}, the jump")
H = lambda x: F(x) - (Fr(1, 10) if Fr(x) >= 400 else 0)           # a function that dips at 400
print(f"mistake 4, a dip: H = F minus 0.1 from 400 on gives (350, 400] the mass {dec(mass(350, 400, H))}")

assert road1 == road2 and F(0) == grid(lambda c: c == 0)          # formula against pushforward
assert abs(Fr(hits, n) - road1) < 4 * se(0.21) and abs(Fr(zeros, n) - F(0)) < 4 * se(0.3)
assert whole_F == open_left and closed == F(500) and whole_G != open_left
assert mass(350, 400, H) < 0 and slopes == grid(lambda c: c > 0)   # mistakes 4 and 3: slopes vs the grid's spread
print("ALL CHECKS PASS")
