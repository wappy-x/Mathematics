# Ergodicity and mixing -- the check behind the card.  Standard library only:
# math gives pi, sqrt, sin and floor.  Maps on [0, 1), sizes measured by length:
# rotation x -> x + alpha mod 1, and doubling x -> 2x mod 1.
import math

ALPHA, GRID = math.sqrt(2) - 1, 100000           # the irrational turn; grid points

def frac(x):
    return x - math.floor(x)

def dist(t):                                      # distance to the nearest whole number
    return abs(t - math.floor(t + 0.5))

def doubling_overlap(a, b, n):                    # road 1: m(D^-n [0,a) and [0,b)) by intervals
    w = 2.0 ** -n                                 # D^-n [0,a) is 2^n strips [j w, (j + a) w)
    return sum(max(0.0, min(j * w + a * w, b) - j * w) for j in range(2 ** n) if j * w < b)

def doubling_grid(a3, b3, n, bits):               # road 2: count grid points j / 2^bits
    full, hits = 1 << bits, 0                     # a3, b3: set is [0, 1/a3), shifting is exact
    for j in range(full):
        y = (j << n) & (full - 1)
        hits += a3 * y < full and b3 * j < full
    return hits / full

def rotation_overlap(b, n):                       # m(R^-n [0,b) and [0,b)), formula for b <= 1/2
    return max(0.0, b - dist(n * ALPHA))

def rotation_grid(b, n):                          # the same overlap by counting grid midpoints
    pts = ((i + 0.5) / GRID for i in range(GRID))
    return sum(1 for x in pts if x < b and frac(x + n * ALPHA) < b) / GRID

def bits_stream(count, s=88172645463325252):     # xorshift64: the binary digits of one start
    out = []
    for _ in range(count):
        s ^= (s << 13) & 0xFFFFFFFFFFFFFFFF
        s ^= s >> 7
        s ^= (s << 17) & 0xFFFFFFFFFFFFFFFF
        out.append(s >> 63)
    return out

def yn(c):
    return "yes" if c else "no"

print("-- rotation by 1/2; A = [0,1/4) and [1/2,3/4), as quarter cells")
cells = [0, 2]
back = [c for c in range(4) if (c + 2) % 4 in cells]  # x in R^-1 A when x + 1/2 lands in A
print(f"cells of A {cells}; cells of R^-1 A {back}; invariant: {yn(back == cells)}; m(A) = {len(cells) / 4:.6f}")
print("|e^(2 pi i k/2) - 1| for k = 1..4: " + " ".join(f"{2 * abs(math.sin(math.pi * k / 2)):.6f}" for k in range(1, 5)))
def coeff(k, m=40000):                            # road 2: c_k by a midpoint sum, as |re + i im|
    xs = [(i + 0.5) / m for i in range(m) if int(4 * (i + 0.5) / m) in cells]
    return math.hypot(sum(math.cos(2 * math.pi * k * x) for x in xs) / m,
                      sum(math.sin(2 * math.pi * k * x) for x in xs) / m)
ck = [coeff(k) for k in (1, 2, 3)]
print(f"|c_1|, |c_2|, |c_3| of the indicator, by integration: {ck[0]:.6f} {ck[1]:.6f} {ck[2]:.6f}; 1/pi = {1 / math.pi:.6f}")
pars = 0.25 + 2 * sum((1 / (math.pi * j)) ** 2 for j in range(1, 2000, 2))
print(f"Parseval: c_0^2 + sum of |c_k|^2 for 0 < |k| < 4000 = {pars:.6f}, against m(A) = 0.5")
share = [sum(int(4 * frac(x0 + 0.5 * n)) in cells for n in range(10000)) / 10000 for x0 in (0.1, 0.3)]
print(f"share of 10000 orbit points in A: start 0.1 -> {share[0]:.4f}, start 0.3 -> {share[1]:.4f}")

print(f"-- rotation by alpha = sqrt2 - 1 = {ALPHA:.6f}")
gaps = [2 * abs(math.sin(math.pi * k * ALPHA)) for k in range(1, 1001)]
kmin = 1 + gaps.index(min(gaps))
pell = [1, 2]                                     # second road: the continued fraction [0; 2, 2, 2, ...]
while pell[-1] < 1000:
    pell.append(2 * pell[-1] + pell[-2])
print(f"|e^(2 pi i k alpha) - 1|: k = 1 -> {gaps[0]:.6f}, k = 2 -> {gaps[1]:.6f}; smallest for k <= 1000: k = {kmin} -> {min(gaps):.6f}")
print(f"denominators of the continued fraction: {pell[:-1]}")
sh = sum(frac(0.1 + n * ALPHA) < 0.5 for n in range(10000)) / 10000
print(f"share of 10000 orbit points in [0,1/2), start 0.1: {sh:.4f}")

print("-- doubling, A = B = [0,1/2): m(D^-n A and B) by intervals, by a 2^16 grid")
for n in range(1, 6):
    print(f"n = {n}: {doubling_overlap(0.5, 0.5, n):.6f} {doubling_grid(2, 2, n, 16):.6f}")
print(f"doubling swaps 1/3 and 2/3: D(1/3) = {frac(2 / 3):.6f}, D(2/3) = {frac(4 / 3):.6f}")
d_int = [doubling_overlap(0.5, 0.5, n) for n in range(1, 6)]

print("-- the overlap as n grows, A = B = [0,1/3), as a multiple of m(A)m(B) = 1/9")
print(" n  doubling  rotation")
rows = [(n, 9 * doubling_overlap(1 / 3, 1 / 3, n), 9 * rotation_overlap(1 / 3, n)) for n in range(1, 13)]
for n, d, r in rows:
    print(f"{n:2d}  {d:.5f}   {r:.5f}")
grid_gap = max(abs(doubling_grid(3, 3, n, 18) - d / 9) for n, d, _ in rows[:8])
rot_gap = max(abs(rotation_grid(1 / 3, n) - r / 9) for n, _, r in rows)

print("-- rotation by alpha is never mixing: A = B = [0,1/2), target m(A)m(B) = 0.25")
for n in (3, 70, 169, 985):
    print(f"n = {n:3d}: distance of n alpha to a whole number {dist(n * ALPHA):.6f}; overlap {rotation_overlap(0.5, n):.6f}")

print("-- Kac: mean return time to A")
pr = [2.0 ** -n for n in range(1, 61)]            # doubling, A = [0,1/2): return at n is n - 1 ones, then a 0
series = sum(n * p for n, p in zip(range(1, 61), pr))
digits = bits_stream(1000000)
nxt, nxt00 = [None] * (len(digits) + 1), [None] * (len(digits) + 1)
for i in range(len(digits) - 1, -1, -1):         # next 0 digit, and next "00", at or after i
    nxt[i] = i if digits[i] == 0 else nxt[i + 1]
    nxt00[i] = i if digits[i] == 0 and i + 1 < len(digits) and digits[i + 1] == 0 else nxt00[i + 1]
def mean_wait(table, starts):
    w = [table[i + 1] - i for i in starts if table[i + 1] is not None]
    return sum(w) / len(w)
in_a = [i for i in range(len(digits) - 1) if digits[i] == 0]
in_a4 = [i for i in range(len(digits) - 1) if digits[i] == 0 and digits[i + 1] == 0]
ret2, ret4 = mean_wait(nxt, in_a), mean_wait(nxt00, in_a4)
wait4 = mean_wait(nxt00, range(len(digits) - 1))
print(f"doubling, A = [0,1/2): P(r = n) for n = 1..4: " + " ".join(f"{p:.4f}" for p in pr[:4]))
print(f"  mean by the series {series:.6f}; along 10^6 digits of one orbit {ret2:.4f}")
L1, L2 = 0.5 - ALPHA, 2 * ALPHA - 0.5             # rotation by alpha: lengths with r = 1 (and 3), r = 2
def ret_rot(x, turn, b):
    n = 1
    while frac(x + n * turn) >= b:
        n += 1
    return n
gr = [ret_rot((i + 0.5) / GRID, ALPHA, 0.5) for i in range(GRID // 2)]
print(f"rotation by alpha, A = [0,1/2): length with r = 1: {L1:.6f}, r = 2: {L2:.6f}, r = 3: {L1:.6f}")
print(f"  mean by lengths {(L1 + 2 * L2 + 3 * L1) / 0.5:.6f}; by a grid of 50000 starts {sum(gr) / len(gr):.6f}")
half = [ret_rot((i + 0.5) / GRID, 0.5, 0.25) for i in range(GRID // 4)]
e1 = (1 + 0.5) / (1 - 0.75)                       # pattern "00": expected digits to complete it
print(f"mistake 1: rotation by 1/2, A = [0,1/4): every return time is {min(half)} (largest {max(half)}), not 1/m(A) = 4")
print(f"mistake 2: rotation by alpha, A = [0,1/2): n = 3 gives {rotation_overlap(0.5, 3):.4f}, n = 70 gives {rotation_overlap(0.5, 70):.4f}")
print(f"mistake 3: doubling, A = [0,1/4): return {ret4:.4f}; wait from a random start {wait4:.4f}; exact {e1 - 1:.6f}")
print(f"mistake 4: rotation by 1/2 from 0.1 spends {share[0]:.4f} of its time in A, not m(A) = 0.5")
assert back == cells and abs(ck[1] - 1 / math.pi) < 1e-6 and abs(ck[0]) < 1e-9  # A invariant, c_2 = 1/pi
assert abs(pars - 0.5) < 1e-4                     # Parseval's total meets the cell count m(A)
assert kmin == pell[-2] and min(gaps) > 0         # near-returns sit at the continued-fraction q
assert all(abs(d - 0.25) < 1e-12 for d in d_int)  # exact mixing for dyadic sets, by intervals ...
assert all(doubling_grid(2, 2, n, 16) == 0.25 for n in range(1, 16))  # ... and by the grid
assert grid_gap < 2e-3 and rot_gap < 1e-4 and abs(rows[-1][1] - 1) < 1e-3
assert abs(series - 2) < 1e-12 and abs(ret2 - 2) < 0.02 and abs(sum(gr) / len(gr) - 2) < 1e-3
assert abs((L1 + 2 * L2 + 3 * L1) / 0.5 - sum(gr) / len(gr)) < 1e-3   # turner: lengths against the grid
assert abs(ret4 - 4) < 0.05 and abs(wait4 - 5) < 0.05 and min(half) == max(half) == 2
assert abs(sh - 0.5) < 0.01 and rotation_overlap(0.5, 985) > 0.49
print("ALL CHECKS PASS")
