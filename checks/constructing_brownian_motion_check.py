# Building Brownian motion on [0, 1] by Levy's midpoint construction -- the check behind the card.
# Standard library only.  The grain: W(0) = 0, W(1) = 1.2 um.  Level n fills the midpoints of the 2^(n-1) gaps,
# each the average of its two ends plus a normal kick of variance 2^-(n+1).
# Road 1: the kick variance against the bridge formula.  Road 2: the Schauder series' covariance, summed exactly.
# Road 3: one path built by midpoints and again by the tent series.  Road 4: 1000 seeded paths to level 12.
from math import cos, exp, log, pi, sqrt

W1, L, M = 1.2, 12, 1000
def tail(x, m=4000):                       # P(Z > x) for a standard normal Z, Simpson's rule on [x, x + 12]
    h = 12 / m
    return h / 3 * sum((1 if i in (0, m) else 4 if i % 2 else 2) * exp(-(x + i * h) ** 2 / 2) for i in range(m + 1)) / sqrt(2 * pi)
def cf(x):                                 # P(Z > x) a second way: Laplace's continued fraction, 200 levels deep
    f = x
    for k in range(200, 0, -1): f = x + k / f
    return exp(-x * x / 2) / sqrt(2 * pi) / f
def moment(p, m=4000):                     # E[Z^p] by Simpson's rule on [-12, 12]
    h = 24 / m
    return h / 3 * sum((1 if i in (0, m) else 4 if i % 2 else 2) * (i * h - 12) ** p * exp(-(i * h - 12) ** 2 / 2) for i in range(m + 1)) / sqrt(2 * pi)
def tent(n, k, t):                         # Schauder tent of level n, gap k: peak 2^-(n+1)/2 at the gap's midpoint
    w = 2.0 ** (1 - n); u = (t - k * w) / w
    return 2 ** (-(n + 1) / 2) * (1 - abs(2 * u - 1)) if 0 <= u <= 1 else 0.0
def gap(n, t): return min(int(t * 2 ** (n - 1)), 2 ** (n - 1) - 1)
def tent_cov(s, t, N): return sum(tent(n, gap(n, s), s) * tent(n, gap(n, s), t) for n in range(1, N + 1))
def qv_exact(var, q=W1 ** 2):              # mean sum of squared steps after each level: q -> q/2 + 2^(n-1) * 2 * var(n)
    for n in range(1, L + 1): q = q / 2 + 2 ** n * var(n)
    return q
MASK, state = (1 << 64) - 1, 20261123
def unif():                                # SplitMix64, top 53 bits, never exactly 0 or 1
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return (((z ^ (z >> 31)) >> 11) + 0.5) / 2 ** 53
def normal():                              # Box-Muller, one normal from two uniforms
    r = sqrt(-2 * log(unif())); return r * cos(2 * pi * unif())
def build():                               # levels 1..L of midpoint kicks; returns the path at k/2^L and the kicks
    p, Z = [0.0, W1], []
    for n in range(1, L + 1):
        sd, q, zn = 2 ** (-(n + 1) / 2), [0.0], []
        for a, b in zip(p, p[1:]):
            z = normal(); zn.append(z); q += [(a + b) / 2 + sd * z, b]
        p = q; Z.append(zn)
    return p, Z
def coarse(p, N, i):                       # the level-N picture (straight lines between its points) at grid point i
    s = 2 ** (L - N); j = i // s; f = (i - j * s) / s
    return p[j * s] if f == 0 else p[j * s] * (1 - f) + p[(j + 1) * s] * f
def ok(x): return "ok" if x else "FAIL"

print("level | gap      | kick variance | bridge formula | kick spread")
for n in (1, 2, 3, 10):
    g = 2.0 ** (1 - n); v = 2.0 ** -(n + 1); bv = g / 2 * (g / 2) / g
    assert abs(v - bv) < 1e-15
    print(f"{n:5d} | {g:.6f} | {v:.6f}      | {bv:.6f}       | {sqrt(v):.4f}")
pz = tail(1.2)
assert abs(pz - cf(1.2)) < 1e-9
print(f"W(1/2) = 0.6 + 0.5 Z; P(W(1/2) > 1.2) = P(Z > 1.2) = {pz:.4f}")
print("Schauder series at s = 0.3, t = 0.4: levels N | Cov st + tents | Var at 0.3 | pinned Var, tents only")
for N in (1, 2, 4, 8, 16, 30):
    c, v = tent_cov(0.3, 0.4, N), tent_cov(0.3, 0.3, N); print(f"  N = {N:2d} | {0.12 + c:.6f} | {0.09 + v:.6f} | {v:.6f}")
assert abs(0.12 + tent_cov(0.3, 0.4, 30) - 0.3) < 1e-8 and abs(tent_cov(0.3, 0.3, 30) - 0.3 * 0.7) < 1e-8
assert abs(0.09 + tent_cov(0.3, 0.3, 8) - 0.3) > 1e-4
print("  limits: min(s, t) = 0.300000, Var W(0.3) = 0.300000, pinned 0.3 x 0.7 = 0.210000")
m4, m8 = moment(4), moment(8)
assert abs(m4 - 3) < 1e-9 and abs(m8 - 105) < 1e-7
print(f"E[Z^4] = {m4:.6f}, E[Z^8] = {m8:.6f}: E|W(t)-W(s)|^(2p) = (2p-1)!! h^p, Kolmogorov exponent < (p-1)/(2p)")
for p in (2, 4, 10): print(f"  p = {p:2d}: alpha = {2 * p}, beta = {p - 1}, paths Holder of every order below {(p - 1) / (2 * p):.4f}")
h = 2.0 ** -10; pm = sum(k ** 4 * exp(-h) * h ** k / exp(sum(log(j) for j in range(1, k + 1))) for k in range(1, 30))
assert abs(pm - (h + 7 * h ** 2 + 6 * h ** 3 + h ** 4)) < 1e-15
print(f"Poisson rate 1, h = 2^-10: E[N_h^4] / h = {pm / h:.6f}, never below C h^(1+beta)")
fails = [2 * tail(2 * sqrt(n)) for n in range(1, 61)]
assert all(abs(f / (2 * cf(2 * sqrt(n))) - 1) < 1e-6 for n, f in zip(range(1, 61), fails))
union = sum(2 ** (n - 1) * f for n, f in zip(range(1, 61), fails))
pfail = 1 - exp(sum(2 ** (n - 1) * log(1 - f) for n, f in zip(range(1, L + 1), fails)))
for n in (1, 2, 3, 11): print(f"  level {n:2d}: {2 ** (n - 1):4d} kicks, P(|Z| > 2 sqrt n) = {fails[n - 1]:.3e} <= exp(-2n) = {exp(-2 * n):.3e}")
assert all(f <= exp(-2 * n) for n, f in zip(range(1, 61), fails)) and pfail <= union
print(f"Borel-Cantelli sum over all levels {union:.4f}; exact P(some level 1..{L} breaks the cap) {pfail:.4f}")
print(f"P(a level after 10 breaks it) <= {sum(2 ** (n - 1) * f for n, f in zip(range(1, 61), fails) if n > 10):.3e}")
bound = {N: sum(2 * sqrt(n) * 2 ** (-(n + 1) / 2) for n in range(N + 1, 200)) for N in (4, 8, 10, 20)}
for N, b in bound.items():                 # ratio test: after the first cap left, each next one is 1/sqrt 2 to sqrt((N+2)/(N+1)/2) times the last
    first = 2 * sqrt(N + 1) * sqrt(2.0 ** -N / 4)   # 2 sqrt n times the spread of a kick on a gap of 2^-N
    assert first / (1 - sqrt(0.5)) < b < first / (1 - sqrt((N + 2) / (N + 1) / 2))
print(f"2/e^2 = {2 / exp(2):.4f}; 2 sqrt 11 = {2 * sqrt(11):.3f}; points after level 10: {2 ** 10 + 1}")
print("cap on how far levels after N can move the path: " + ", ".join(f"N = {N}: {b:.4f}" for N, b in bound.items()))

S = dict.fromkeys(["half", "half2", "five", "five2", "above", "qv", "q4"], 0.0); brk = 0
sup = {4: [], 8: []}; hol = {(n, g): 0.0 for n in (4, 8, 12) for g in (0.25, 0.6)}
for k in range(M):
    p, Z = build()
    if k == 0:
        diff = max(abs(p[i] - (i / 2 ** L * W1 + sum(Z[n - 1][gap(n, i / 2 ** L)] * tent(n, gap(n, i / 2 ** L), i / 2 ** L)
                   for n in range(1, L + 1)))) for i in range(0, 2 ** L + 1, 37))
        assert diff < 1e-12
        print(f"path 1: kick at 1/2 = {Z[0][0]:.4f}, W(1/2) = {p[2048]:.4f}; midpoints vs tent series at {len(range(0, 2 ** L + 1, 37))} times, largest gap {diff:.1e}")
        for N in (1, 2, 4): print(f"chart, level {N}: " + ", ".join(f"{coarse(p, N, i * 256):.2f}" for i in range(17)))
    bad = any(max(abs(z) for z in Z[n - 1]) > 2 * sqrt(n) for n in range(1, L + 1)); brk += bad
    S["half"] += p[2048]; S["half2"] += p[2048] ** 2; S["five"] += p[1280]; S["five2"] += p[1280] ** 2; S["above"] += p[2048] > 1.2
    d = [y - x for x, y in zip(p, p[1:])]; S["qv"] += sum(x * x for x in d); S["q4"] += sum(x ** 4 for x in d) * 2 ** L
    for N in sup:
        sup[N].append(max(abs(p[i] - coarse(p, N, i)) for i in range(2 ** L + 1)))
        assert bad or sup[N][-1] <= bound[N]
    for (n, g) in hol: s = 2 ** (L - n); hol[(n, g)] += max(abs(p[i + s] - p[i]) for i in range(0, 2 ** L, s)) * 2 ** (n * g) / M
se = lambda m, m2: sqrt((m2 / M - (m / M) ** 2) / M)
mh, vh = S["half"] / M, S["half2"] / M - (S["half"] / M) ** 2; mf, vf = S["five"] / M, S["five2"] / M - (S["five"] / M) ** 2
pa = S["above"] / M; sa = sqrt(pa * (1 - pa) / M)
print(f"{M} paths to level {L} ({2 ** L} steps): W(1/2) mean {mh:.4f} (0.6), variance {vh:.4f} (0.25); W(5/16) mean {mf:.4f} (0.375), variance {vf:.4f} (0.2148)")
print(f"  P(W(1/2) > 1.2) {pa:.4f}, standard error {sa:.4f} (exact {pz:.4f})")
assert abs(mh - 0.6) < 4 * se(S["half"], S["half2"]) and abs(pa - pz) < 4 * sa and abs(vh - 0.25) < 4 * 0.25 * sqrt(2 / M)
hstep = 2.0 ** -L; v = hstep * (1 - hstep); mu = W1 * hstep; q4 = (3 * v * v + 6 * v * mu * mu + mu ** 4) / hstep ** 2
qr = qv_exact(lambda n: 2.0 ** -(n + 1))
print(f"  sum of squared steps {S['qv'] / M:.6f} (exact mean {qr:.6f}); mean step^4 / h^2 {S['q4'] / M:.4f} (exact {q4:.4f})")
assert abs(S["qv"] / M - qr) < 4 * sqrt(2 / 2 ** L / M) and abs(S["q4"] / M - q4) < 4 * sqrt(96 / 2 ** L / M)
sb = sqrt(brk / M * (1 - brk / M) / M)
print(f"  paths where some level broke the cap: {brk} of {M} = {brk / M:.4f}, standard error {sb:.4f} (exact {pfail:.4f})")
assert abs(brk / M - pfail) < 4 * sb
for N in sup: print(f"  level {N} to level {L}: largest move, mean over paths {sum(sup[N]) / M:.4f}, worst {max(sup[N]):.4f}, cap {bound[N]:.4f}")
for g in (0.25, 0.6): print(f"  largest step / h^{g}: " + ", ".join(f"level {n}: {hol[(n, g)]:.3f}" for n in (4, 8, 12)))
assert hol[(12, 0.25)] < hol[(4, 0.25)] and hol[(12, 0.6)] > hol[(4, 0.6)]
wrong = {"free variance h/2 for the kick": lambda n: 2.0 ** -n, "spread halving, not variance": lambda n: 0.25 * 4.0 ** (1 - n)}
for name, f in wrong.items(): print(f"wrong: {name}: sum of squared steps at level {L} = {qv_exact(f):.6f} (right {qr:.6f})")
c4 = 2 * tail(4)                           # a fixed cap of 4 at every level: the draws double, the cap does not grow
print(f"wrong: fixed cap 4: P(|Z| > 4) = {c4:.3e}; level 20 breaks it with chance {1 - (1 - c4) ** 2 ** 19:.4f}; Borel-Cantelli sum to level 20 {c4 * (2 ** 20 - 1):.1f}")
f3 = [2 * tail(3 * sqrt(n)) for n in range(1, L + 1)]
print(f"try: W1 = 0: squared steps {qv_exact(lambda n: 2.0 ** -(n + 1), 0.0):.6f}; W1 drawn N(0, 1): Var W(1/2) = {0.25 + tent_cov(0.5, 0.5, 30):.6f}")
print(f"try: cap 3 sqrt n: level 1 breaks it {f3[0]:.4f}, some level {1 - exp(sum(2 ** (n - 1) * log(1 - f) for n, f in zip(range(1, L + 1), f3))):.4f}, "
      f"caps after level 10 {sum(3 * sqrt(n) * 2 ** (-(n + 1) / 2) for n in range(11, 200)):.4f}")
print("ALL CHECKS PASS")
