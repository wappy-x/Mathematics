# Sums, products, sups and limits of measurable functions -- the check behind the card.
# Standard library only.  Three roads.  (1) A four-point space: every function with
# values 0, 1, 2 is tested for measurability two ways, then every sum, product, max
# and min.  (2) A toy river gauge on [0, 1): the events the card names are measured
# by exact fractions and, separately, by counting a grid of 60000 years hour by hour.
# (3) The rationals: Riemann's upper sums on a pointwise limit that never settle.
from fractions import Fraction as Fr

# ---- road 1: a four-point space ----
B1, B2 = [{0, 1}, {2, 3}], [{0, 2}, {1, 3}]            # the blocks of two sigma-algebras
def events(blocks):                                     # every union of blocks
    return [set().union(*(b for j, b in enumerate(blocks) if m >> j & 1)) for m in range(4)]
F1, F2 = events(B1), events(B2)
def measurable(h, F):                                   # threshold test: {h > c} allowed, every cut c
    return all({w for w in range(4) if h[w] > c} in F for c in sorted(set(h)) + [min(h) - 1])
def block_constant(h, blocks):                          # second road: one value on each block
    return all(len({h[w] for w in b}) == 1 for b in blocks)
funcs = [(a, b, c, d) for a in range(3) for b in range(3) for c in range(3) for d in range(3)]
good = [h for h in funcs if measurable(h, F1)]
agree = all(measurable(h, F1) == block_constant(h, B1) for h in funcs)
ops = {"sum": lambda x, y: x + y, "product": lambda x, y: x * y, "max": max, "min": min}
closed = {k: all(measurable(tuple(map(op, f, g)), F1) for f in good for g in good) for k, op in ops.items()}
u, v = (0, 0, 1, 1), (2, 2, 1, 1)                       # f_n = v + (-1)^n u, both measurable
tail = [tuple(v[w] + (-1) ** n * u[w] for w in range(4)) for n in range(10, 12)]
lim_set = {w for w in range(4) if tail[0][w] == tail[1][w]}
f, g = (1, 1, 0, 0), (1, 0, 1, 0)                       # f fits F1, g fits F2
s = tuple(map(ops["sum"], f, g))
good2 = [h for h in funcs if measurable(h, F2)]
neither = sum(1 for a in good for b in good2
              if not measurable(tuple(map(ops["sum"], a, b)), F1) and not measurable(tuple(map(ops["sum"], a, b)), F2))
yn = lambda c: "yes" if c else "no"
print(f"four points, blocks {{0,1}} {{2,3}}: {len(funcs)} functions, {len(good)} measurable")
print(f"threshold test and block test agree on all {len(funcs)}: {yn(agree)}")
for k in ops:
    print(f"{k:8s} of all {len(good) ** 2} measurable pairs is measurable: {yn(closed[k])}")
print(f"f_n = v + (-1)^n u: limit exists on {sorted(lim_set)}, an allowed event: {yn(lim_set in F1)}")
print(f"mixing: f = {f} fits blocks {{0,1}} {{2,3}}, g = {g} fits {{0,2}} {{1,3}}, f + g = {s}")
print(f"  f + g measurable for the first: {yn(measurable(s, F1))}, for the second: {yn(measurable(s, F2))}")
print(f"  pairs (one of each kind) whose sum fits neither: {neither} of {len(good) * len(good2)}")

# ---- road 2: the river gauge, w = the year's wetness, uniform on [0, 1) ----
def level(w, n):                                        # metres at hour n
    s = max(0.0, w - 0.75)                              # the sluice swing, wettest years only
    return 2 + 2 * w * (1 - 0.5 ** n) + (s if n % 2 == 0 else -s)
def exact_flood(N):                                     # length of {max of hours 1..N > 4}
    n = N - N % 2                                       # only even hours can pass 4 m
    return max(Fr(0), 1 - Fr(11, 4) / (3 - Fr(2) ** (1 - n))) if n else Fr(0)
M, H = 60000, 41
first_hour, spread, f2f3, cover = [], [], [], {D: 0 for D in (1, 10, 100, 1000)}
for i in range(M):
    w = (i + 0.5) / M
    lv = [level(w, n) for n in range(1, H + 1)]
    first_hour.append(next((n for n in range(1, H) if lv[n - 1] > 4), None))
    spread.append(abs(lv[H - 1] - lv[H - 2]))          # the swing still present at hours 40, 41
    f2f3.append(lv[1] + lv[2] < 6)
    for D in cover:                                     # a rational k/D with f2 < k/D < 6 - f3?
        k = int(lv[1] * D) + 1
        cover[D] += k / D < 6 - lv[2]
print("\nhour          " + " ".join(f"{n:5d}" for n in range(1, 13)))
for w in (0.45, 0.95):
    print(f"level, w={w:.2f} " + " ".join(f"{level(w, n):5.2f}" for n in range(1, 13)))
print("running max   " + " ".join(f"{max(level(0.95, m) for m in range(1, n + 1)):5.2f}" for n in range(1, 13)))
print("\nlength of {highest of hours 1..N above 4 m}: exact fraction, then the grid")
grid_flood = {}
for N in (2, 4, 6, 8, 12, 20):
    grid_flood[N] = sum(1 for h in first_hour if h is not None and h <= N) / M
    e = exact_flood(N)
    print(f"  N = {N:2d}   {str(e):>16s} = {float(e):.6f}   grid {grid_flood[N]:.6f}   band w > {1 - e}")
print(f"  ever above 4 m, the union: 1 - 11/12 = {float(Fr(1, 12)):.6f}")
print(f"  w = 11/12: 4 minus hour 10 = {4 - level(11 / 12, 10):.8f}, 4 minus hour 20 = "
      f"{4 - level(11 / 12, 20):.8f}; sup 4, never reached")
grid_lim = sum(1 for d in spread if d < 1e-9) / M
print(f"length of the limit set: exact 3/4 = 0.750000, grid {grid_lim:.6f}")
print(f"long-run level where it exists, w = 0.45: {2 + 2 * 0.45:.2f} m;"
      f" w = 0.95 swings between {2 + 2 * 0.95 - 0.2:.2f} and {2 + 2 * 0.95 + 0.2:.2f} m")
grid_sum = sum(f2f3) / M
print(f"{{hour 2 + hour 3 < 6 m}}: exact 8/13 = {8 / 13:.6f}, grid {grid_sum:.6f}")
for D, c in cover.items():
    print(f"  covered by the union over k/{D:<4d} {c / M:.6f}")
whole = max(min(Fr(q - 2) / Fr(3, 2), Fr(4 - q) / Fr(7, 4)) for q in range(2, 5))   # w < 0.75: f2 = 2 + 1.5w, f3 = 2 + 1.75w
print(f"  the k/1 union exactly: wetness below {whole} = {float(whole):.6f}")
print(f"figure, x of w = 0.75, N = 4, 6, 8 and 11/12: " + ", ".join(
    f"{30 + 300 * t:.1f}" for t in (0.75, *(1 - float(exact_flood(N)) for N in (4, 6, 8)), 11 / 12)))

# ---- road 3: Riemann on the rationals of [0, 1], listed by denominator ----
rats = sorted({Fr(p, q) for q in range(1, 101) for p in range(q + 1)}, key=lambda x: (x.denominator, x))
def upper(points, N):                                   # pieces [i/N, (i+1)/N] holding a point, over N
    hit = set()
    for x in points:                                    # x = p/q sits in piece floor(xN), and in the
        i, r = divmod(x.numerator * N, x.denominator)   # piece before when xN is a whole number
        hit |= {j for j in (i, i - 1 if r == 0 else i) if 0 <= j < N}
    return Fr(len(hit), N)
def upper2(points, N):                                  # second road: test each closed piece directly
    return Fr(sum(any(j * x.denominator <= x.numerator * N <= (j + 1) * x.denominator for x in points)
                  for j in range(N)), N)
first10 = rats[:10]
print("\nfirst 10 rationals: " + ", ".join(str(x) for x in first10))
ups = {N: upper(first10, N) for N in (10, 100, 1000)}
for N, U in ups.items():
    print(f"upper sum of the 10-point indicator, {N:4d} pieces: {float(U):.4f}; lower 0")
print(f"upper sum of the indicator of all rationals, 100 pieces: {float(upper(rats, 100)):.4f}; lower 0")

assert agree and len(good) == 3 * 3                     # two tests agree; 3 values on each of 2 blocks
assert all(closed.values()) and lim_set in F1
assert not measurable(s, F1) and not measurable(s, F2) and neither > 0
for N, gf in grid_flood.items():                        # grid count vs exact fraction, each stage
    assert abs(gf - float(exact_flood(N))) < 2 / M
assert abs(grid_lim - 0.75) < 2 / M and abs(grid_sum - 8 / 13) < 2 / M
cv = list(cover.values())
assert all(a < b for a, b in zip(cv, cv[1:])) and cv[-1] / M <= grid_sum and grid_sum - cv[-1] / M < 0.01
assert abs(cv[0] / M - float(whole)) < 2 / M            # whole-number q: grid against the exact union
assert all(U <= Fr(20, N) and U == upper2(first10, N) for N, U in ups.items())
assert upper(rats, 100) == upper2(rats, 100) == 1
print("ALL CHECKS PASS")
