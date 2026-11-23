# Sunflowers and union-closed families -- the check behind the card.
# Standard library only. Sets are bitmasks: bit k set means point k is in.
# Every search is written out; asserts check instances and two roads agreeing.
import math
from itertools import combinations

def pts(m):                                  # the points of a bitmask, from 1
    return [k + 1 for k in range(31) if m >> k & 1]

def bits(*ks):
    return sum(1 << (k - 1) for k in ks)

def flower(a, b, c):                         # three sets, one shared core
    return a & b == a & c == b & c

# ---- the three bus routes: 1 Central, 2 Market, 3 Airport, 4 Harbour, 5 Stadium
A, B, C = bits(1, 2, 3), bits(1, 2, 4), bits(1, 2, 5)
print("routes", pts(A), pts(B), pts(C), "cores", pts(A & B), pts(A & C), pts(B & C), "sunflower", flower(A, B, C))
X, Y, Z = bits(1, 2, 3), bits(1, 2, 4), bits(1, 3, 4)
print("near miss", pts(X), pts(Y), pts(Z), "cores", pts(X & Y), pts(X & Z), pts(Y & Z), "sunflower", flower(X, Y, Z))
assert flower(A, B, C) and not flower(X, Y, Z) and X & Y & Z == bits(1)

# ---- Erdos-Rado bound w!(p-1)^w for p = 3 petals
er = [math.factorial(w) * 2 ** w for w in range(1, 5)]
print("Erdos-Rado bound, p=3, w=1..4:", er)
assert er == [2, 8, 48, 384]

# ---- two-stop routes are edges; largest family with no 3 petals, two roads
def edges(n):
    return [bits(i, j) for i, j in combinations(range(1, n + 1), 2)]

def brute(n):                                # road 1: every set of edges
    E = edges(n)
    bad = [(1 << i) | (1 << j) | (1 << k) for i, j, k in combinations(range(len(E)), 3)
           if flower(E[i], E[j], E[k])]
    return max(bin(s).count("1") for s in range(1 << len(E)) if all(s & t != t for t in bad))

def search(n):                               # road 2: grow sunflower-free sets
    E, best = edges(n), [0]
    def grow(chosen, start):
        best[0] = max(best[0], len(chosen))
        for i in range(start, len(E)):
            if len(chosen) + len(E) - i <= best[0]:
                return
            if all(not flower(a, b, E[i]) for a, b in combinations(chosen, 2)):
                grow(chosen + [E[i]], i + 1)
    grow([], 0)
    return best[0]

bf = [brute(n) for n in range(3, 7)]
se = [search(n) for n in range(3, 8)]
print("largest 3-sunflower-free graph, brute force, n=3..6:", bf)
print("largest 3-sunflower-free graph, search, n=3..7:", se)
assert bf == se[:4] and se == [3, 4, 5, 6, 6]

T = [bits(1, 2), bits(1, 3), bits(2, 3), bits(4, 5), bits(4, 6), bits(5, 6)]
extra = [e for e in edges(6) if e not in T]
hits = [e for e in extra if any(flower(a, b, e) for a, b in combinations(T, 2))]
star = [pts(t) for t in T if t & bits(1, 4) == bits(1)][:2]
print("two triangles:", len(T), "edges; missing edges that force a sunflower:", len(hits), "of", len(extra))
print("seventh edge [1, 4] with", star, "core [1]")
assert len(hits) == len(extra) == 9

P = [a | b << 6 for a in T for b in T]       # product: triangle pair x triangle pair
trip = sum(1 for a, b, c in combinations(P, 3) if flower(a, b, c))
print("product family, w=4:", len(P), "sets,", math.comb(len(P), 3), "triples, sunflowers among them:", trip)
assert len(P) == 36 and trip == 0

print("log10 bars, p=3: w, construction 6^(w/2), Erdos-Rado w!2^w")
for w in range(2, 11, 2):
    lo, hi = 6 ** (w // 2), math.factorial(w) * 2 ** w
    print(f"w={w:2d} {lo:6d} {math.log10(lo):.3f} {hi:11d} {math.log10(hi):.3f}")

# ---- union-closed: the stops served by any non-empty set of running routes
U = sorted({x | y | z for x in (0, A) for y in (0, B) for z in (0, C)} - {0})
cnt = [sum(1 for s in U if s >> k & 1) for k in range(5)]
print("route combinations:", len(U), "sets; stop counts 1..5:", cnt)
assert all(a | b in U for a in U for b in U) and cnt == [7, 7, 4, 4, 4]

def share(F, n):                             # best element: (its count, |F|)
    return max(sum(1 for s in F if s >> k & 1) for k in range(n)), len(F)

def closed_families(n):                      # every family of subsets of n points
    for f in range(1 << (1 << n)):
        F = [s for s in range(1 << n) if f >> s & 1]
        if all(f >> (a | b) & 1 for a in F for b in F):
            yield F

for n in range(1, 5):
    fams = list(closed_families(n))
    withe = sum(1 for F in fams if 0 in F)
    worst = min((share(F, n) for F in fams if any(F)), key=lambda t: t[0] / t[1])
    sing = [F for F in fams if any(bin(s).count("1") == 1 for s in F)]
    ok = all(2 * sum(1 for s in F if s & x) >= len(F) for F in sing
             for x in F if bin(x).count("1") == 1)
    print(f"n={n}: union-closed families {len(fams)}, with empty set {withe},"
          f" lowest best share {worst[0]}/{worst[1]}, singleton rule holds in {len(sing)}: {ok}")
    assert 2 * withe == len(fams) and 2 * worst[0] == worst[1] and ok

for F in ([bits(1), bits(2), bits(3)], [0]):
    c, m = share(F, 3)
    print("breaks:", [pts(s) for s in F], f"best share {c}/{m} = {c / m:.6f}")

# ---- Gilmer's barrier: H(2p - p^2) = H(p), solved two ways
def H(q):                                    # binary entropy, in bits
    return -q * math.log2(q) - (1 - q) * math.log2(1 - q)

lo, hi = 0.1, 0.45                           # H(2p-p^2) - H(p): + at 0.1, - at 0.45
for _ in range(60):
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if H(2 * mid - mid * mid) > H(mid) else (lo, mid)
exact = (3 - math.sqrt(5)) / 2
print(f"entropy crossing: bisection {lo:.12f}, closed form (3-sqrt5)/2 {exact:.12f}, H there {H(exact):.12f}")
assert abs(lo - exact) < 1e-12 and abs(2 * exact - exact ** 2 - (1 - exact)) < 1e-15
print(f"Gilmer 0.01, a week later {exact:.5f}, Frankl asks 0.5")
ang = [270, 30, 150]                         # the figure: petal centres 75 px out
cen = " ".join(f"({210 + 75 * math.cos(math.radians(d)):.1f},{170 + 75 * math.sin(math.radians(d)):.1f})" for d in ang)
print("figure, centre (210,170), core radius 34, petal centres 75 px out:", cen)
print("ALL CHECKS PASS")
