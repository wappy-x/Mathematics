# Random graphs G(n, p) -- the check behind the card.  Nothing is imported but
# the math primitives.  1,000 people; each of the 499,500 pairs becomes a
# friendship with chance 0.003, every pair on its own coin.  Three roads: the
# formulas, every outcome of a 4-person network enumerated, and 40 networks
# drawn from a SplitMix64 generator written out here (seed 20260929).
import math

N, P = 1000, 0.003
def pairs(n):                                  # unordered pairs, n(n - 1)/2
    return n * (n - 1) // 2

PAIRS = pairs(N)
LAM = (N - 1) * P                              # average friends per person
MASK = (1 << 64) - 1
state = 20260929

def splitmix():                                # 64 random bits per call
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return z ^ (z >> 31)

def binom_pmf(m, p):                           # P(X = k) for k = 0..m, ratio rule
    out = [(1 - p) ** m]
    for k in range(m):
        out.append(out[-1] * (m - k) / (k + 1) * p / (1 - p))
    return out

def poisson_pmf(lam, kmax):                    # P(Y = k) for k = 0..kmax
    out = [math.exp(-lam)]
    for k in range(kmax):
        out.append(out[-1] * lam / (k + 1))
    return out

def tv(a, b):                                  # half the summed gaps between two laws
    return 0.5 * sum(abs(x - y) for x, y in zip(a, b))

def mean_se(xs):                               # average and its standard error
    m = sum(xs) / len(xs)
    var = sum((x - m) ** 2 for x in xs) / (len(xs) - 1)
    return m, math.sqrt(var / len(xs))

# ---- road 1: the formulas ----
bin_d, poi_d = binom_pmf(N - 1, P), poisson_pmf(LAM, N - 1)
e_edges, sd_edges = PAIRS * P, math.sqrt(PAIRS * P * (1 - P))
e_loners = N * bin_d[0]                        # each friendless with chance (1-p)^(n-1)
TRIPLES = N * (N - 1) * (N - 2) // 6
e_tri = TRIPLES * P ** 3
print(f"people {N}, chance per pair {P}, pairs C({N},2) = {PAIRS}")
print(f"expected friendships {e_edges:.1f}, standard deviation {sd_edges:.4f}")
print(f"friends per person ~ Binomial({N - 1}, {P}): mean {LAM:.3f}, variance {LAM * (1 - P):.6f}")
print(f"expected people with no friends {e_loners:.4f}; expected triangles {TRIPLES} x {P}^3 = {e_tri:.6f}")
dist, bound = tv(bin_d, poi_d), (N - 1) * P * (1 - math.exp(-P))
print(f"gap between Binomial and Poisson laws {dist:.6f}; coupling bound {bound:.6f}; (n-1)p^2 = {(N - 1) * P * P:.6f}")

# ---- road 2: a 4-person network with p = 0.3, all 2^6 = 64 outcomes ----
pairs4 = [(i, j) for i in range(4) for j in range(i + 1, 4)]
e4, deg0 = 0.0, [0.0] * 4
for mask in range(64):
    on = [pairs4[b] for b in range(6) if mask >> b & 1]
    w = 0.3 ** len(on) * 0.7 ** (6 - len(on))
    e4 += w * len(on)
    deg0[sum(1 for e in on if 0 in e)] += w
b4 = binom_pmf(3, 0.3)
print(f"4 people, p = 0.3, enumerated: expected friendships {e4:.6f}, formula C(4,2)p = {pairs(4) * 0.3:.6f}")
print("  person 1's friend count, enumerated: " + ", ".join(f"{x:.4f}" for x in deg0))
print("  Binomial(3, 0.3) formula:            " + ", ".join(f"{x:.4f}" for x in b4))

# ---- road 3: 40 networks, each pair tossed on its own coin ----
T = int(P * 2 ** 64)                           # a draw below T has chance P
G = 40
edges_s, loners_s, tri_s, hist = [], [], [], [0] * 1000
for g in range(G):
    nbr = [[] for _ in range(N)]
    for i in range(N):
        for j in range(i + 1, N):
            if splitmix() < T:
                nbr[i].append(j)
                nbr[j].append(i)
    deg = [len(a) for a in nbr]
    edges_s.append(sum(deg) // 2)
    loners_s.append(deg.count(0))
    for d in deg:
        hist[d] += 1
    s = [set(a) for a in nbr]
    tri_s.append(sum(len(s[i] & s[j]) for i in range(N) for j in nbr[i] if j > i) // 3)
me, se = mean_se(edges_s)
ml, sl = mean_se(loners_s)
mt, st = mean_se(tri_s)
print(f"simulated, {G} networks: friendships {me:.2f} +/- {se:.2f} (formula {e_edges:.1f})")
print(f"  friends per person {2 * me / N:.4f} +/- {2 * se / N:.4f} (formula {LAM:.3f})")
print(f"  people with no friends {ml:.2f} +/- {sl:.2f} (formula {e_loners:.2f})")
print(f"  triangles {mt:.3f} +/- {st:.3f} (formula {e_tri:.3f}); most friends seen {max(k for k in range(1000) if hist[k])}")
print("k, Binomial, Poisson, simulated share +/- se")
ok, shares = True, []
for k in range(11):
    f = hist[k] / (G * N)
    shares.append(f)
    sf = math.sqrt(bin_d[k] * (1 - bin_d[k]) / (G * N))   # se if the law is right
    ok = ok and abs(f - bin_d[k]) < 4 * sf + 1e-12
    print(f"{k}, {bin_d[k]:.4f}, {poi_d[k]:.4f}, {f:.4f} +/- {sf:.4f}")
print("chart, to 2 places, Poisson " + " ".join(f"{x:.2f}" for x in poi_d[:11]) +
      "; simulated " + " ".join(f"{x:.2f}" for x in shares))

# ---- what breaks ----
print(f"mistake 1, n^2 p counts ordered pairs and self-pairs: {N * N * P:.1f}, not {e_edges:.1f}")
print(f"mistake 2, n x average friends, not halved: {N * LAM:.1f} friendships, not {e_edges:.1f}")
dep = [1 - P] + [0.0] * (N - 2) + [P]          # one coin decides every pair at once
dep_mean = sum(k * x for k, x in enumerate(dep))
print(f"mistake 3, one coin for all pairs: mean friends {dep_mean:.3f}, chance of none {dep[0]:.4f} (own coins: {bin_d[0]:.4f})")
e4dep, none_dep = 0.0, 0.0                     # 4 people, one shared coin: all 6 pairs or none
for on, w in (([], 0.7), (pairs4, 0.3)):
    e4dep += w * len(on)
    none_dep += w * (sum(1 for e in on if 0 in e) == 0)
print(f"  same, 4 people enumerated: friendships {e4dep:.6f} (own coins {e4:.6f}), person 1 has none {none_dep:.4f} (own coins {deg0[0]:.4f})")
b11, p11 = binom_pmf(10, 0.3), poisson_pmf(3.0, 10)
print(f"mistake 4, 11 people at p = 0.3: chance of no friends {b11[0]:.4f}, Poisson says {p11[0]:.4f}; gap {tv(b11, p11) + 0.5 * (1 - sum(p11)):.4f}")

# ---- the picture: 8 people, p = 0.3, one draw (seed 8) ----
state, T8 = 8, int(0.3 * 2 ** 64)
pts = [(180 + 90 * math.sin(2 * math.pi * i / 8), 120 - 90 * math.cos(2 * math.pi * i / 8)) for i in range(8)]
fig_edges = [(i + 1, j + 1) for i in range(8) for j in range(i + 1, 8) if splitmix() < T8]
print("figure, people at " + " ".join(f"({x:.1f},{y:.1f})" for x, y in pts))
print("figure, friendships " + " ".join(f"{i}-{j}" for i, j in fig_edges) + f"; {len(fig_edges)} of 28, expected 8.4")
print("figure, friend counts " + " ".join(str(sum(v in e for e in fig_edges)) for v in range(1, 9)))

assert abs(e4 - pairs(4) * 0.3) < 1e-12 and max(abs(x - y) for x, y in zip(deg0, b4)) < 1e-12
assert abs(me - e_edges) < 4 * se and abs(ml - e_loners) < 4 * sl and abs(mt - e_tri) < 4 * st
assert ok                                      # every share within 4 standard errors
assert dist < bound                            # the coupling bound holds
assert abs(e4dep - e4) < 1e-12 and none_dep > deg0[0] + 0.3   # average kept, law changed
print("ALL CHECKS PASS")
