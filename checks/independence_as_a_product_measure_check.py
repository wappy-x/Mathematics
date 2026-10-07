# Independence as a product -- the check behind the card.  Standard library
# only; Fraction does exact arithmetic.  A dart lands uniformly on a 1 m by
# 1 m board at (x, y).  Three roads: exact formulas in fractions, finite grids
# listed in full, and 200000 simulated darts from SplitMix64, seed 20260929.
from fractions import Fraction as Fr
from math import sqrt

MASK, N = (1 << 64) - 1, 200000
state = 20260929

def uniform():                        # SplitMix64, top 53 bits scaled into [0, 1)
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return ((z ^ (z >> 31)) >> 11) / 2.0 ** 53

def g(s, t):                          # exact P(x <= s, x + y <= t): integrate min(1, max(0, t - x)) over x in [0, s]
    full = max(Fr(0), min(s, t - 1))
    a, b = max(Fr(0), t - 1), min(s, t)
    return full + (t * (b - a) - (b * b - a * a) / 2 if b > a else 0)

def lower_sum(n, h):                  # integral of the simple function h(lower-left corner) on an n by n grid
    return Fr(sum(h(i, j) for i in range(n) for j in range(n)), n ** 4)

def count(pairs, test):
    return sum(1 for u, v in pairs if test(u, v))

def ray_pairs(pairs, nv):             # rays {first <= a} and {second <= b}; 16 equally likely cells
    return sum(16 * count(pairs, lambda u, v: u <= a and v <= b)
               == count(pairs, lambda u, v: u <= a) * count(pairs, lambda u, v: v <= b)
               for a in range(4) for b in range(nv)), 4 * nv

def set_pairs(pairs, nv):             # every set of first values against every set of second values
    return sum(16 * count(pairs, lambda u, v: A >> u & 1 and B >> v & 1)
               == count(pairs, lambda u, v: A >> u & 1) * count(pairs, lambda u, v: B >> v & 1)
               for A in range(16) for B in range(1 << nv)), 16 << nv

def show(q):
    return f"{q.numerator}/{q.denominator} = {float(q):.6f}"

half, quarter = Fr(1, 2), Fr(1, 4)
ex, ex2 = half, Fr(1, 3)                          # exact moments of one uniform coordinate
var = ex2 - ex * ex
rays = [(quarter, half), (half, half), (half, Fr(3, 4)), (Fr(3, 4), quarter)]
sums = [0.0] * 5                                  # xy, (xy)^2, x + y, (x + y)^2, x(x + y)
hits = [0] * 11                                   # 4 ray rectangles, x marginal at 1/4 1/2 3/4, y marginal at 1/4 1/2 3/4, x + y <= 1/2
both = [0, 0, 0]                                  # {x <= 1/2 and x + y <= 1/2}, {u <= -1/4}, {u <= -1/4 and w <= 1/16}
w_hits, uw_sum = 0, 0.0
for _ in range(N):
    x = uniform(); y = uniform()
    for k, v in enumerate((x * y, x * y * x * y, x + y, (x + y) * (x + y), x * (x + y))):
        sums[k] += v
    for k, (s, t) in enumerate(rays):
        hits[k] += x <= s and y <= t
    for k, c in enumerate((0.25, 0.5, 0.75)):
        hits[4 + k] += x <= c; hits[7 + k] += y <= c
    hits[10] += x + y <= 0.5
    u = x - 0.5; w = u * u
    both[0] += x <= 0.5 and x + y <= 0.5; both[1] += u <= -0.25; both[2] += u <= -0.25 and w <= 0.0625
    w_hits += w <= 0.0625; uw_sum += u * w
m = [v / N for v in sums]
se_xy = sqrt((m[1] - m[0] * m[0]) / N)
sim_var = m[3] - m[2] * m[2]
marg = {Fr(1, 4): 0, Fr(1, 2): 1, Fr(3, 4): 2}
print(f"dart: x and y uniform on [0, 1] m; {N} simulated darts, seed 20260929")
print(f"exact E[x] = 1/2, E[x^2] = 1/3, Var(x) = {var.numerator}/{var.denominator}")
print(f"exact E[x]E[y] = {show(ex * ex)}")
low = [lower_sum(n, lambda i, j: i * j) for n in (4, 16, 64, 256)]
print("lower sums of xy, n by n grid: " + ", ".join(f"n={n} {float(q):.6f}" for n, q in zip((4, 16, 64, 256), low)))
print(f"simulated E[xy] = {m[0]:.6f}, standard error {se_xy:.6f}")
print(f"exact Var(x + y) = Var(x) + Var(y) = {show(2 * var)}; simulated {sim_var:.6f}")
for k, (s, t) in enumerate(rays):
    sim_prod = hits[4 + marg[s]] / N * (hits[7 + marg[t]] / N)
    print(f"ray rectangle x <= {float(s):.2f}, y <= {float(t):.2f}: exact {show(s * t)}; "
          f"simulated joint {hits[k] / N:.6f}, product {sim_prod:.6f}")
cells_ij = [(i, j) for i in range(4) for j in range(4)]
cells_iw = [(i, i + j) for i in range(4) for j in range(4)]
r_ij, s_ij, r_iw, s_iw = ray_pairs(cells_ij, 4), set_pairs(cells_ij, 4), ray_pairs(cells_iw, 7), set_pairs(cells_iw, 7)
print(f"4 by 4 cells, (column, row): ray pairs multiplying {r_ij[0]} of {r_ij[1]}; set pairs {s_ij[0]} of {s_ij[1]}")
print(f"4 by 4 cells, (column, column + row): ray pairs {r_iw[0]} of {r_iw[1]}; set pairs {s_iw[0]} of {s_iw[1]}, "
      f"from 16 x {1 << 7} events")
c0, w0 = count(cells_iw, lambda u, v: u == 0), count(cells_iw, lambda u, v: v == 0)
print(f"  one failing pair: column 0 has {c0}/16, sum 0 has {w0}/16, both {count(cells_iw, lambda u, v: u == 0 and v == 0)}/16, "
      f"product {c0 * w0}/256")
gv, fv = g(half, half), g(Fr(1), half)
print(f"pair (x, x + y), rectangle x <= 1/2, x + y <= 1/2: exact {show(gv)}; product 1/2 x {fv} = {show(half * fv)}")
print(f"  simulated joint {both[0] / N:.6f}, product {hits[5] / N * (hits[10] / N):.6f}")
for t in (Fr(1), Fr(3, 2)):
    print(f"  ray x <= 1/2, x + y <= {float(t):.1f}: exact {show(g(half, t))}, product {show(half * g(Fr(1), t))}")
exy2 = ex2 + ex * ex                              # E[x(x + y)] = E[x^2] + E[x]E[y], since x and y are independent
low2 = lower_sum(256, lambda i, j: i * (i + j))
print(f"E[x(x + y)] exact {show(exy2)}; lower sum n=256 {float(low2):.6f}; simulated {m[4]:.6f}; "
      f"E[x]E[x + y] = 1/2 x {2 * ex} = {ex * 2 * ex}; covariance {exy2 - ex * 2 * ex}")
print(f"mistake, Var(x + x) read as Var(x) + Var(x): {show(2 * var)}; true Var(2x) {show(4 * var)}")
board = [(i, j) for i in range(2) for j in range(2)]                        # quadrants, 1/4 each
L, B, C = (lambda i, j: i == 0), (lambda i, j: j == 0), (lambda i, j: i == j)
p = lambda *evs: Fr(count(board, lambda i, j: all(e(i, j) for e in evs)), 4)
print(f"mistake, generators {{L, B}} and {{C}}: P(L and C) = {p(L, C)}, P(B and C) = {p(B, C)}, "
      f"P(L and B) = {p(L, B)}; P(L and B and C) = {p(L, B, C)}, not {p(L, B) * p(C)}")
lo, hi = max(Fr(0), quarter), min(quarter, Fr(3, 4))                  # {x <= 1/4} meets {1/4 <= x <= 3/4}
rect_uw = max(Fr(0), hi - lo)
print(f"mistake, u = x - 1/2, w = u^2: E[uw] = E[u^3] = 0 = E[u]E[w]; simulated E[uw] {uw_sum / N:.6f}")
print(f"  rectangle u <= -1/4, w <= 1/16: exact {rect_uw}, product {quarter * half}; "
      f"simulated {both[2] / N:.6f} and {both[1] / N * (w_hits / N):.6f}")
print("figure, 140 px per metre; left square 20..160, right 200..340, top 40, bottom 180; "
      f"left rectangle 70 by 70 px, area {float(half * half):.6f}; right triangle legs 70 px, area {float(gv):.6f}")
assert Fr(0) < ex * ex - low[-1] < Fr(1, 256)     # grid lower sums climb to the exact 1/4 within 1/n
assert abs(m[0] - 0.25) < 4 * se_xy               # 200000 darts agree with E[x]E[y] = 1/4
assert abs(sim_var - float(2 * var)) < 0.002      # about 4.5 standard errors of a sample variance
assert r_ij[0] == r_ij[1] and s_ij[0] == s_ij[1]   # rays multiply, and so does every set pair
assert r_iw[0] < r_iw[1] and s_iw[0] < s_iw[1]     # a failing ray pair shows up among the sets
assert abs(both[0] / N - float(gv)) < 4 * sqrt(float(gv * (1 - gv)) / N)   # simulation meets the exact 1/8
assert gv != half * fv                            # (x, x + y) fails on this rectangle
assert Fr(0) < exy2 - low2 < Fr(2, 256)           # upper minus lower sum of x^2 + xy is 2/n
assert p(L, B, C) != p(L, B) * p(C)               # pairs multiply, the generated sets do not
print("ALL CHECKS PASS")
