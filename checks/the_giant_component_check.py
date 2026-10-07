# The giant component -- the check behind the card.  Only math primitives are
# imported.  1,000 people; each pair are friends, independently, with chance
# p = c/999, so c is the average number of friends.  Four roads to the share
# of people in the giant: bisection on z = 1 - e^(-c z), the extinction chance
# generation by generation, a simulated family tree, and simulated networks.
from math import exp, log, floor, sqrt

M64 = (1 << 64) - 1
class Rng:                                  # SplitMix64 with a stated seed; Rust uses the same
    def __init__(self, seed): self.s = seed
    def u(self):                            # a uniform number in [0, 1)
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = ((self.s ^ (self.s >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return ((z ^ (z >> 31)) >> 11) / 2.0 ** 53

def zeta_bisect(c):                         # road 1: the root of 1 - e^(-c z) - z above 0
    if c <= 1: return 0.0
    lo, hi = 1e-6, 1.0                      # the gap is positive at lo, negative at 1
    for _ in range(100):
        mid = (lo + hi) / 2
        if 1 - exp(-c * mid) - mid > 0: lo = mid
        else: hi = mid
    return (lo + hi) / 2

def extinction(c, gens):                    # road 2: q_k = e^(c (q_(k-1) - 1)), q_0 = 0
    q, path = 0.0, []
    for _ in range(gens):
        q = exp(c * (q - 1)); path.append(q)
    return path

def poisson(rng, lam):                      # Knuth: multiply uniforms until below e^-lam
    k, t, stop = 0, rng.u(), exp(-lam)
    while t > stop:
        k += 1; t *= rng.u()
    return k

def survives(rng, c):                       # road 3: one family line, Poisson(c) children each
    alive = 1
    while 0 < alive < 50:                   # at 50 alive, dying out has chance below 1e-18
        alive = poisson(rng, c * alive)     # a generation's children, all drawn at once
    return alive > 0

def sizes(n, edges):                        # union-find: component sizes, largest first
    parent = list(range(n))
    def root(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]; x = parent[x]
        return x
    for a, b in edges:
        ra, rb = root(a), root(b)
        if ra != rb: parent[ra] = rb
    count = [0] * n
    for x in range(n): count[root(x)] += 1
    return sorted((s for s in count if s > 0), reverse=True)

def network(rng, n, p):                     # road 4: every pair (v, w), w < v, visited by
    edges, v, w, lq = [], 1, -1, log(1 - p) # geometric jumps between friendships
    while v < n:
        w += 1 + floor(log(1 - rng.u()) / lq)
        while w >= v and v < n:
            w -= v; v += 1
        if v < n: edges.append((v, w))
    return edges

def stubs(rng, count, deg):                 # 'count' people with 'deg' friends each, paired at random
    s = [i for i in range(count) for _ in range(deg)]
    for i in range(len(s) - 1, 0, -1):      # Fisher-Yates shuffle, then pair neighbours
        j = floor(rng.u() * (i + 1)); s[i], s[j] = s[j], s[i]
    return [(s[k], s[k + 1]) for k in range(0, len(s), 2)]

def mean_se(xs):                            # plain left-to-right sums, as in Rust (Python's
    t = 0.0                                 # own sum() compensates rounding since 3.12)
    for x in xs: t += x
    m, v = t / len(xs), 0.0
    for x in xs: v += (x - m) * (x - m)
    return m, sqrt(v / (len(xs) - 1) / len(xs))

n, runs, rng = 1000, 40, Rng(2026)
keep = {}
print("c, theory %, simulated largest % (40 networks), s.e. %")
for i in range(1, 13):
    c = 0.25 * i
    got = [sizes(n, network(rng, n, c / (n - 1))) for _ in range(runs)]
    keep[i] = got
    m, se = mean_se([g[0] / n for g in got])
    print(f"sweep, {c:.2f}, {100 * zeta_bisect(c):.2f}, {100 * m:.2f}, {100 * se:.2f}")

c = 1.5
path = extinction(c, 200)
z1, z2 = zeta_bisect(c), 1 - path[-1]
print("extinction chance by generation, c = 1.5: " + ", ".join(f"{q:.4f}" for q in path[:5]))
print(f"limit q = {path[-1]:.6f}; road 2 share 1 - q = {z2:.6f}; road 1 bisection = {z1:.6f}")
print(f"setup: n = {n}, pairs {n * (n - 1) // 2}, c = 1.5, p = c/999 = {c / (n - 1):.6f}")
print(f"check: exponent 1.5 x {z1:.4f} = {c * z1:.4f}; 1 - e^(-{c * z1:.4f}) = {1 - exp(-c * z1):.4f}; giant about {z1 * n:.0f}, outside {(1 - z1) * n:.0f}")
lines = 10000
alive = [1.0 if survives(rng, c) else 0.0 for _ in range(lines)]
zs, zse = mean_se(alive)
print(f"road 3: {lines} family lines at c = 1.5 survive {zs:.4f}, s.e. {zse:.4f}, gap {(zs - z1) / zse:.1f} s.e.")
low = sum(1 for _ in range(2000) if survives(rng, 0.5))
print(f"road 3 at c = 0.5: {low} of 2000 lines survive")
m6, s6 = mean_se([g[0] / n for g in keep[6]])
m6b, _ = mean_se([g[1] for g in keep[6]])
print(f"road 4: largest share at c = 1.5 {m6:.4f}, s.e. {s6:.4f}; second largest {m6b:.1f} people")

g2 = keep[2]                                # c = 0.5, below the switch
big = max(g[0] for g in g2)
avg_big, _ = mean_se([g[0] for g in g2])
own, own_se = mean_se([sum(s * s for s in g) / n for g in g2])
rate = 0.5 - 1 - log(0.5)
k = floor(2 * log(n) / rate) + 1
print(f"c = 0.5: largest island mean {avg_big:.1f}, biggest in 40 networks {big}")
print(f"c = 0.5: a person's own island {own:.4f} (s.e. {own_se:.4f}); bound 1/(1 - c) = {1 / (1 - 0.5):.4f}")
print(f"c = 0.5: rate I = {rate:.4f}; ln n = {log(n):.4f}; 2 ln n / I = {2 * log(n) / rate:.2f}; k = {k}")
print(f"c = 0.5: chance any island tops k is at most n e^(-k I) = {n * exp(-k * rate):.6f}")
crit, _ = mean_se([g[0] for g in keep[4]])
print(f"c = 1: largest mean {crit:.1f} people; n^(2/3) = {n ** (2 / 3):.1f}")

quads = [(4 * g + a, 4 * g + b) for g in range(250) for a in range(4) for b in range(a + 1, 4)]
qs = sizes(n, quads)
hub, _ = mean_se([sizes(n, stubs(rng, 300, 3))[0] for _ in range(runs)])
print(f"breaks: 250 foursomes, average {2 * len(quads) / n:.1f} friends, largest {qs[0]}; theory {zeta_bisect(3) * n:.0f}")
print(f"breaks: 300 people with 3 friends, 700 with none, average {900 / n:.1f}, new friends per friend {3 * 2 * 300 / 900:.1f}, largest mean {hub:.1f}")
print(f"breaks: straight line 2(c - 1) at c = 1.5 gives {2 * (c - 1):.4f}; at c = 1.1 {2 * 0.1:.4f} vs {zeta_bisect(1.1):.4f}")
print(f"try: c = 2 share {zeta_bisect(2):.4f}; c = 3 share {zeta_bisect(3):.4f}")
print(f"try: outside the giant at c = 1.5, friends per person c q = {c * path[-1]:.4f}")
print(f"try: c = 6.9, expected loners n e^(-c) = {n * exp(-6.9):.4f}")

assert abs(z1 - z2) < 1e-9                  # bisection against the generation limit
assert abs(zs - z1) < 4 * zse               # simulated family lines against the formula
assert abs(m6 - z1) < 4 * s6                # networks of 1,000 against the formula
assert own < 1 / (1 - 0.5) + 3 * own_se     # the proven mean-size bound below the switch
assert big < k                              # the proven largest-island bound below the switch
