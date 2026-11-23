# Unique games conjecture -- the check behind the card.  Standard library only.
# A small unique game solved two ways, max-cut as the two-label case, and the
# dictator test behind "UGC makes 0.878 optimal" computed exactly.
from math import cos, sin, acos, pi
from itertools import product

def met(edges, k, lab):  # how many edge rules lab[v] = lab[u] + c (mod k) hold
    return sum(1 for u, v, c in edges if (lab[v] - lab[u] - c) % k == 0)

def brute(n, edges, k, ok=met):  # road 1: try every labelling
    scores = [ok(edges, k, lab) for lab in product(range(k), repeat=n)]
    return max(scores), scores.count(max(scores))

def propagate(n, edges, k):  # road 2: fix node 0, each rule forces the next label
    best, full = 0, 0
    for start in range(k):
        lab = [start] + [0] * (n - 1)
        for u, v, c in edges[:n - 1]:
            lab[v] = (lab[u] + c) % k
        s = met(edges, k, lab)
        best, full = max(best, s), full + (s == len(edges))
    return best, full

def ring(offsets):
    n = len(offsets)
    return [(i, (i + 1) % n, c) for i, c in enumerate(offsets)]

good, bad = ring([1, 2, 0, 1, 2]), ring([1, 2, 0, 1, 1])
for name, g in (("consistent ring", good), ("one rule changed", bad)):
    bb, bc = brute(5, g, 3)
    pb, pf = propagate(5, g, 3)
    print(f"{name:17s} offsets sum mod 3 = {sum(c for _, _, c in g) % 3}  "
          f"best {bb}/5 = {bb / 5:.6f}  best labellings {bc} of {3 ** 5}  propagation full {pf}")
    assert bb == pb and (bb == 5) == (sum(c for _, _, c in g) % 3 == 0)
lab = [0]
for u, v, c in good[:4]:
    lab.append((lab[-1] + c) % 3)
print("labels forced on the consistent ring from camera 0 at 0:", *lab)
assert brute(5, bad, 3) == (4, 15) and propagate(5, good, 3) == (5, 3)

# max-cut is the unique game with 2 labels and every rule "differ" (offset 1)
cut, ncut = brute(5, ring([1] * 5), 2)
sdp = 5 * (1 - cos(4 * pi / 5)) / 2  # the ring's relaxation, from the SDP card
print(f"max-cut on the 5-ring: best {cut}/5 ({ncut} best splits), SDP bound {sdp:.6f}, "
      f"ratio {cut / sdp:.6f}, GW expected cut {5 * (4 * pi / 5) / pi:.6f}")
lap = lambda v: [2 * v[i] - v[i - 1] - v[(i + 1) % 5] for i in range(5)]  # the ring's Laplacian times v
v = [1.0, 0.0, 0.0, 0.0, 0.0]  # road 2 for the bound: power iteration finds the top eigenvalue
for _ in range(200):
    w = lap(v)
    v = [x / max(abs(y) for y in w) for x in w]
top = sum(a * b for a, b in zip(lap(v), v)) / sum(x * x for x in v)
print(f"dual bound: top Laplacian eigenvalue {top:.6f}, times 5/4 = {5 * top / 4:.6f}")
assert (cut, ncut) == (5 - 1, 2 * 5)  # odd ring: one link left uncut (5 ways), two colourings each
assert abs(sdp - 5 * top / 4) < 1e-9  # primal vectors and dual prices meet, so 4.522542 is the optimum

# a rule that is not unique: 'differ' with 3 colours (proper 3-colouring)
neq = lambda edges, k, lab: sum(1 for u, v, _ in edges if lab[u] != lab[v])
full3, cnt3 = brute(5, ring([0] * 5), 3, neq)
print(f"'differ' with 3 colours on the ring: {cnt3} labellings meet all {full3} rules; "
      f"each rule leaves 2 choices, so nothing is forced")
assert cnt3 == 2 ** 5 - 2  # chromatic polynomial of a 5-cycle at 3: (k-1)^5 - (k-1)

# alpha_GW = min over theta of (theta/pi) / ((1 - cos theta)/2), three roads
r = lambda t: 2 * t / (pi * (1 - cos(t)))
lo, hi = 0.5, pi  # road 1: golden-section search
for _ in range(200):
    m1, m2 = hi - (hi - lo) / 1.618033988749895, lo + (hi - lo) / 1.618033988749895
    lo, hi = (lo, m2) if r(m1) < r(m2) else (m1, hi)
t_gold = (lo + hi) / 2
lo, hi = 2.0, 3.0  # road 2: bisection on the slope's zero, (1 - cos t) = t sin t
for _ in range(100):
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if (1 - cos(mid)) - mid * sin(mid) < 0 else (lo, mid)
t_bis = (lo + hi) / 2
grid = min((acos(-i / 100000) / pi) / ((1 + i / 100000) / 2) for i in range(1, 100001))
alpha, rho = r(t_bis), cos(t_bis)  # road 3 above: a grid over rho, -1 < rho <= 0
print(f"theta* {t_bis:.6f} rad = {t_bis * 180 / pi:.4f} deg, rho* {rho:.6f}")
print(f"alpha_GW: golden {r(t_gold):.6f}  bisection {alpha:.6f}  rho grid {grid:.6f}")
assert abs(t_gold - t_bis) < 1e-6 and abs(grid - alpha) < 1e-8 and grid >= alpha - 1e-12

# the dictator test at correlation rho: x uniform in {-1,1}^n, each bit of y is
# x's bit flipped with chance q = (1 - rho)/2; f passes when f(x) != f(y)
def maj_pass(n, rho):  # exact, by counting +1s: a in x, j of them flipped, l of the rest
    q, C = (1 - rho) / 2, [[1]]
    for i in range(n):
        C.append([1] + [C[i][j] + C[i][j + 1] for j in range(i)] + [1])
    b = lambda m, j: C[m][j] * q ** j * (1 - q) ** (m - j)
    return sum(C[n][a] / 2 ** n * b(a, j) * b(n - a, l) for a in range(n + 1)
               for j in range(a + 1) for l in range(n - a + 1)
               if (2 * a > n) != (2 * (a - j + l) > n))

def maj_brute(n, rho):  # every x and every flip pattern, weighted
    q, tot = (1 - rho) / 2, 0.0
    for x in product((-1, 1), repeat=n):
        for f in product((0, 1), repeat=n):
            y = [-xi if fi else xi for xi, fi in zip(x, f)]
            if (sum(x) > 0) != (sum(y) > 0):
                tot += q ** sum(f) * (1 - q) ** (n - sum(f)) / 2 ** n
    return tot

limit = acos(rho) / pi  # Sheppard: majority of many bits, the random-plane chance
for n in (1, 3, 9, 27, 81):
    print(f"majority of {n:2d} bits passes {maj_pass(n, rho):.6f}")
for n in (1, 3, 5):
    assert abs(maj_pass(n, rho) - maj_brute(n, rho)) < 1e-12
print(f"dictator passes (1-rho)/2 = {(1 - rho) / 2:.6f}; many-bit limit arccos(rho)/pi = "
      f"{limit:.6f}; ratio {limit / ((1 - rho) / 2):.6f}")
assert abs(maj_pass(1, rho) - (1 - rho) / 2) < 1e-12
assert maj_pass(3, rho) > maj_pass(81, rho) > limit and maj_pass(81, rho) - limit < 0.01
print(f"rho = -1: dictator {maj_pass(1, -1.0):.6f}, majority of 81 {maj_pass(81, -1.0):.6f}, "
      f"limit {acos(-1.0) / pi:.6f}: no gap")
rs = [-1 + i / 10 for i in range(11)]
print("chart dictator", " ".join(f"{(1 - x) / 2:.3f}" for x in rs))
print("chart majority-limit", " ".join(f"{acos(x) / pi:.3f}" for x in rs))
print("ALL CHECKS PASS")
