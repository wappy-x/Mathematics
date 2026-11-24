# The Kuramoto model -- the check behind the card.  Only math is imported.  2,000 oscillators,
# Lorentzian frequencies of half-width 0.5, so K_c = 1.  Three roads to r: the closed form, the
# self-consistency integral (Simpson, bisection) and RK4, starting phases from our own LCG.
import math
G, N, DT, T_END, T_AVG = 0.5, 2000, 0.1, 100.0, 50.0
g = lambda w: G / (math.pi * (w * w + G * G))     # the Lorentzian density
KC = 2 / (math.pi * g(0.0))                       # the critical coupling
theory = lambda K: math.sqrt(max(0.0, 1 - KC / K))
def lcg(seed):                                    # 64-bit LCG, uniform in [0, 1)
    while True:
        seed = (6364136223846793005 * seed + 1442695040888963407) % 2**64
        yield (seed >> 11) / 2**53
def self_consistent(K, m=400):                    # road two: solve the self-consistency
    def excess(r):                                # locked-crowd integral / r - 1, Simpson
        h, x = math.pi / m, lambda j: -math.pi / 2 + j * math.pi / m
        tot = sum((1 if j in (0, m) else 4 if j % 2 else 2) * math.cos(x(j)) ** 2
                  * g(K * r * math.sin(x(j))) for j in range(m + 1))
        return K * tot * h / 3 - 1
    lo, hi = 0.0, 1.0                             # no positive root: hi falls to 0
    for _ in range(60):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if excess(mid) > 0 else (lo, mid)
    return (lo + hi) / 2
def simulate(K, om, th):                          # road three: RK4 on every oscillator
    def f(th):                                    # theta' = omega + K r sin(psi - theta)
        c = [math.cos(t) for t in th]; s = [math.sin(t) for t in th]
        C, S = sum(c) / len(th), sum(s) / len(th) # r cos psi and r sin psi
        return [w + K * (S * ci - C * si) for w, ci, si in zip(om, c, s)], math.hypot(C, S)
    rs, steps, mid = [], round(T_END / DT), th
    for n in range(steps):
        k1, r = f(th)
        if n == steps - round(T_AVG / DT): mid = th
        if n >= steps - round(T_AVG / DT): rs.append(r)
        k2, _ = f([t + DT / 2 * k for t, k in zip(th, k1)])
        k3, _ = f([t + DT / 2 * k for t, k in zip(th, k2)])
        k4, _ = f([t + DT * k for t, k in zip(th, k3)])
        th = [t + DT / 6 * (a + 2 * b + 2 * c + d) for t, a, b, c, d in zip(th, k1, k2, k3, k4)]
    return sum(rs) / len(rs), th, mid
om = [G * math.tan(math.pi * ((i + 0.5) / N - 0.5)) for i in range(N)]   # Lorentzian quantiles
u = lcg(2026); th0 = [2 * math.pi * next(u) for _ in range(N)]
print(f"half-width {G}, g(0) = {g(0):.4f}, K_c = 2/(pi g(0)) = {KC:.4f}")
sims = {}; print(f"K      closed form  integral   simulated, N = {N}")
for K in (0.5, 0.8, 1.0, 1.2, 1.5, 2.0, 3.0, 4.0):
    sims[K], th, mid = simulate(K, om, th0)
    print(f"{K:<6} {theory(K):<12.4f} {self_consistent(K):<10.4f} {sims[K]:.4f}")
    if K == 2.0: locked = sum(abs(a - b) / T_AVG < 0.01 for a, b in zip(th, mid)) / N
a = 2.0 * theory(2.0); lock_th = 2 / math.pi * math.atan(a / G)     # a = K r at K = 2
print(f"K = 2 by hand: K r = {a:.4f}; sqrt((K r)^2 + {G}^2) = {math.hypot(a, G):.4f}; "
      f"(that - {G}) / (K r) = {(math.hypot(a, G) - G) / a:.4f}")
print(f"K = 0.8: simulated r = {sims[0.8]:.4f}; 1/sqrt(N) = {1 / math.sqrt(N):.4f}")
print(f"K = 2: share locked, simulated {locked:.4f}; theory (2/pi) atan(K r / 0.5) = {lock_th:.4f}")
_, pair, _ = simulate(1.0, [0.25, -0.25], [0.0, 0.0])
print(f"two oscillators, gap 0.5, K = 1: phase gap settles at {math.degrees(pair[0] - pair[1]):.2f} degrees")
print(f"mistakes at K = 2: gamma = 1 gives K_c = {2 * KC:.4f} and r = {math.sqrt(max(0.0, 1 - 2 * KC / 2)):.4f}; "
      f"no square root {1 - KC / 2:.4f}; no 1/N {theory(2.0 * N):.4f}")
assert all(abs(self_consistent(K) - theory(K)) < 1e-6 for K in sims)        # road 2 = road 1
assert abs(sims[2.0] - theory(2.0)) < 0.02 and abs(sims[4.0] - theory(4.0)) < 0.02
assert sims[0.8] < 5 / math.sqrt(N) and abs(locked - lock_th) < 0.02
assert abs(math.degrees(pair[0] - pair[1]) - 30.0) < 0.01                   # the house pair
print("ALL CHECKS PASS")
