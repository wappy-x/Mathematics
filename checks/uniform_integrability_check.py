# Uniform integrability -- the check behind the card.  Standard library only.
# Ticket n pays n dollars with probability 1/n: X_n = n on {U < 1/n}, U uniform on [0, 1).
# Roads: (1) value x probability summed over each ticket's law, in fractions where exact;
# (2) the area under the survival curve P(X > t), a midpoint sum over t, with P(X > t) measured
# on [0, 1) from the ticket as a function of U, not from its law; (3) brute-force
# suprema over tickets 1..N_MAX against closed forms; (4) a SplitMix64 simulation.
from fractions import Fraction as F

C, N_MAX = 100, 100_000                      # capped jackpot; tickets searched by brute force

def lottery(n):  return [(0, 1 - F(1, n)), (n, F(1, n))]           # (value, probability)
def capped(n):   return [(0, 1 - F(1, n)), (min(n, C), F(1, n))]
def root(n):     return [(0, 1 - F(1, n)), (n ** 0.5, F(1, n))]    # pays sqrt(n)
def disjoint(n): return [(0, 1 - F(1, n * (n + 1))), (n, F(1, n * (n + 1)))]
FAMILIES = [("lottery", lottery), ("capped", capped), ("root", root), ("disjoint", disjoint)]

def tail(law, K):                             # road 1: E[X 1{X > K}] as value x probability
    return sum(v * p for v, p in law if v > K)

V = {"lottery": lambda n: n, "capped": lambda n: min(n, C), "root": lambda n: n ** 0.5, "disjoint": lambda n: n}
S = {"lottery": lambda n: (0.0, 1 / n), "capped": lambda n: (0.0, 1 / n), "root": lambda n: (0.0, 1 / n),
     "disjoint": lambda n: (1 / (n + 1), 1 / n)}     # ticket as a function of U: V(n) on [a, b), 0 elsewhere

def survival_area(name, n, M=1000):           # road 2: midpoint sum over t of P(X_n > t), read off [0, 1)
    v, (a, b) = V[name](n), S[name](n)
    surv = lambda t: (b - a) if v > t else 0.0  # length of {U : X_n(U) > t}, for t >= 0
    h = 2 * v / M                               # P(X_n > t) = 0 from t = v on
    return sum(surv((j + 0.5) * h) * h for j in range(M))

def ln(y):                                    # natural log by the series 2(z + z^3/3 + ...)
    z = (y - 1) / (y + 1); p, total, i = z, 0.0, 0
    while abs(p) > 1e-17:
        total += p / (2 * i + 1); p, i = p * z * z, i + 1
    return 2 * total

print("n, P(ticket pays), mean by law, mean by survival area, mean capped at 100, mean of sqrt(n) ticket")
chart = {name: [] for name, _ in FAMILIES[:3]}
for n in (1, 10, 100, 1000, 10_000, 100_000, 1_000_000):
    means = [float(tail(f(n), 0)) for _, f in FAMILIES]
    for (name, _), m in zip(FAMILIES, means):
        assert abs(m - survival_area(name, n)) < 1e-12                 # roads 1 and 2 agree
    assert abs(survival_area("root", n) - n ** -0.5) < 1e-12        # E R_n = 1/sqrt(n), off the survival curve
    print(f"{n:7d}, {1 / n:.6f}, {means[0]:.4f}, {survival_area('lottery', n):.4f}, "
          f"{means[1]:.4f}, {means[2]:.4f}")
    if n <= 10_000:
        for name, m in zip(chart, means): chart[name].append(m)
for name in chart: print(f"chart, {name}:", ", ".join(f"{v:.2f}" for v in chart[name]))

def brute(value, piece, K=None, delta=None):  # road 3: sup over n of E[X_n 1{X_n > K}] or E[X_n 1{U < delta}]
    best = 0.0
    for n in range(1, N_MAX + 1):
        v, (a, b) = value(n), piece(n)
        mass = (b - a) if delta is None else max(0.0, min(b, delta) - a)
        if (K is None or v > K): best = max(best, v * mass)
    return best

print("K, worst tail E[X_n 1{X_n > K}] over tickets: lottery, capped, root, disjoint; bound 1/K for root")
for K in (1, 10, 100, 300):
    got = [brute(V[k], S[k], K=K) for k in V]
    closed = [1.0, 1.0 if K < C else 0.0, 1 / (K * K + 1) ** 0.5, 1 / (K + 2)]
    assert all(abs(g - c) < 1e-12 for g, c in zip(got, closed))       # brute force = closed form
    assert got[2] <= 1 / K and abs(float(tail(root(K * K + 1), K)) - got[2]) < 1e-12
    print(f"{K:3d}, " + ", ".join(f"{g:.4f}" for g in got) + f"; {1 / K:.4f}")

print("delta, worst E[X_n 1{U < delta}] over tickets: lottery, capped, root, disjoint")
for delta in (0.01, 0.001, 0.0001):
    got = [brute(V[k], S[k], delta=delta) for k in V]
    closed = [1.0, min(1.0, C * delta), delta ** 0.5, delta / (1 + delta)]
    assert all(abs(g - c) < 1e-9 for g, c in zip(got, closed))
    print(f"{delta}, " + ", ".join(f"{g:.4f}" for g in got))

eps = 0.01                                     # Vitali's bound for the capped tickets
for n in (1000, 10_000, 100_000):
    bound = eps + brute(V["capped"], S["capped"], delta=1 / n)
    actual = survival_area("capped", n)                             # E|Y_n - 0| by road 2, not from the law
    assert actual <= bound                                           # Vitali's bound: road 2 against road 3
    assert abs(bound - eps - min(1, C / n)) < 1e-12                   # road 3 = eps + min(1, C/n)
    print(f"vitali, capped n = {n}: E|Y_n - 0| = {actual:.4f} <= eps + worst mass on P = 1/n: {bound:.4f}")

print("N, integral of the envelope sup_n W_n up to ticket N, bounds ln((N + 2)/2) and ln(N + 1)")
for N in (10, 100, 1000, 10_000, 100_000):
    env = sum(float(tail(disjoint(n), 0)) for n in range(1, N + 1))    # pieces are disjoint
    assert ln((N + 2) / 2) <= env <= ln(N + 1)                       # integral test, both sides
    print(f"{N:6d}, {env:.4f}, {ln((N + 2) / 2):.4f}, {ln(N + 1):.4f}")

for n in (1, 10, 100):                         # infinite measure: height 1/n on [0, n) of the line
    M = 1024; h = 1 / 8                         # one grid for every n: cells of 1/8 on [0, 128)
    cells = [1 / n if (i + 0.5) * h < n else 0.0 for i in range(M)]
    area, over = sum(c * h for c in cells), sum(c * h for c in cells if c > 1)
    assert abs(area - 1) < 1e-9                                      # grid area against the closed form 1
    print(f"line, n = {n}: height {1 / n:.4f}, area {area:.4f}, tail above K = 1: {over:.4f}")

MASK = (1 << 64) - 1
def splitmix(state):
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return state, (z ^ (z >> 31)) >> 11
state, DRAWS = 20260929, 200_000
us = []
for _ in range(DRAWS):
    state, r = splitmix(state); us.append(r / 2 ** 53)
for n in (10, 1000, 1_000_000):
    wins = sum(1 for u in us if u < 1 / n)
    mean, se = wins * n / DRAWS, ((n - 1) / DRAWS) ** 0.5
    if n <= 1000: assert abs(mean - 1) <= 4 * se                  # road 4 within 4 standard errors
    print(f"simulate n = {n}: {DRAWS} tickets, {wins} winners, sample mean {mean:.4f}, standard error {se:.4f}")
PX_U, PX_D = 280, 40                           # figure scale: px for all of [0, 1), px per dollar
print("figure, rect widths px " + ", ".join(str(PX_U // n) for n in (1, 2, 4)) + "; heights px "
      + ", ".join(str(PX_D * n) for n in (1, 2, 4)) + "; base y 200")
print("ALL CHECKS PASS")
