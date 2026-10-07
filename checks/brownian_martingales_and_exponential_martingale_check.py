# Brownian martingales -- the check behind the card.  Standard library only.
# A pollen grain starts at 0 between walls at -2 and +3 micrometres.  Time is in
# seconds and W_t has variance t (square micrometres).  Roads: the formulas; exact
# first-step equations on a lattice walk at shrinking steps; Simpson's rule on the
# reflection-principle density; a seeded simulation (SplitMix64 + Box-Muller).
from math import sqrt, exp, log, cos, sin, cosh, pi

A, B, LAM = 2.0, 3.0, 0.02            # left wall at -A, right wall at +B, tracker-loss rate per second
TH = sqrt(2.0 * LAM)                  # theta, chosen so that theta^2 / 2 = lambda
MID, HALF = (B - A) / 2.0, (A + B) / 2.0

def lap(lam):                         # E[exp(-lam tau)] for the interval, from cosh(theta (W - MID))
    th = sqrt(2.0 * lam)
    return cosh(th * MID) / cosh(th * HALF)

# ---- road 1: the formulas ----
p_right, mean_exit = A / (A + B), A * B
lap_int, level = lap(LAM), exp(-B * TH)

# ---- road 2: a lattice walk, steps of h every h*h seconds, first-step equations solved exactly ----
def tridiag(K, c, r, left, right):
    # -(c/2) v[k-1] + v[k] - (c/2) v[k+1] = r for k = 1..K-1, v[0] = left, v[K] = right (Thomas)
    n, s = K - 1, -c / 2.0
    cp, dp = [0.0] * n, [0.0] * n
    for i in range(n):
        d = r - (s * left if i == 0 else 0.0) - (s * right if i == n - 1 else 0.0)
        den = 1.0 - (s * cp[i - 1] if i else 0.0)
        cp[i] = s / den
        dp[i] = (d - (s * dp[i - 1] if i else 0.0)) / den
    v = [0.0] * n
    v[-1] = dp[-1]
    for i in range(n - 2, -1, -1):
        v[i] = dp[i] - cp[i] * v[i + 1]
    return [left] + v + [right]

def lattice(h):
    K, k0, q = round((A + B) / h), round(A / h), exp(-LAM * h * h)
    side = tridiag(K, 1.0, 0.0, 0.0, 1.0)[k0]           # chance of leaving at +3
    time = tridiag(K, 1.0, h * h, 0.0, 0.0)[k0]         # mean seconds to leave
    disc = tridiag(K, q, 0.0, 1.0, 1.0)[k0]             # mean discount exp(-lam tau)
    K1 = round((100.0 + B) / h)                         # one level at +3, far wall at -100
    one = tridiag(K1, q, 0.0, 0.0, 1.0)[round(100.0 / h)]
    return side, time, disc, one

# ---- road 3: Simpson's rule on the first-passage density b / sqrt(2 pi t^3) exp(-b^2 / 2t) ----
def simpson(f, lo, hi, n=4000):
    w = (hi - lo) / n
    return (f(lo) + f(hi) + sum((4 if i % 2 else 2) * f(lo + i * w) for i in range(1, n))) * w / 3.0

def dens_u(u, power):                 # t = e^u; returns t^power * density(t) * dt/du
    t = exp(u)
    return t ** power * B / sqrt(2.0 * pi * t ** 3) * exp(-B * B / (2.0 * t)) * t

quad_level = simpson(lambda u: exp(-LAM * exp(u)) * dens_u(u, 0), -6.0, log(3000.0))
partial = [(T, simpson(lambda u: dens_u(u, 1), -6.0, log(T))) for T in (1e2, 1e4, 1e6)]

# ---- road 4: seeded simulation on a time grid ----
def normals(seed):
    s, M = seed, (1 << 64) - 1
    def u():
        nonlocal s
        s = (s + 0x9E3779B97F4A7C15) & M
        z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & M
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M
        return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53
    while True:
        r, a = sqrt(-2.0 * log(1.0 - u())), 2.0 * pi * u()
        yield r * cos(a)
        yield r * sin(a)

def simulate(dt, paths, seed):
    nx, sd, every = normals(seed).__next__, sqrt(dt), round(0.25 / dt)
    S, Q, pic = [0.0] * 6, [0.0] * 6, None
    for _ in range(paths):
        x, n, trace = 0.0, 0, [0.0]
        while -A < x < B:
            x += sd * nx()
            n += 1
            if n % every == 0: trace.append(x)
        tau = n * dt
        vals = (1.0 if x >= B else 0.0, tau, x, x * x - tau, exp(TH * x - LAM * tau), exp(-LAM * tau))
        for i, v in enumerate(vals):
            S[i] += v
            Q[i] += v * v
        if pic is None and abs(tau - 6.0) <= 0.5: pic = (trace + ([x] if n % every else []), tau)
    m = [s / paths for s in S]
    return m, [sqrt((q / paths - mi * mi) / paths) for q, mi in zip(Q, m)], pic

print(f"walls -{A:.0f} and +{B:.0f} um, lambda {LAM} per s, theta {TH:.4f}")
print(f"formula   P(leave at +3) {p_right:.6f}   E[tau] {mean_exit:.6f}   E[e^-lam tau] {lap_int:.6f}   level price {level:.6f}")
print(f"by hand   theta*{MID} = {TH * MID:.1f}, cosh {cosh(TH * MID):.6f}   theta*{HALF} = {TH * HALF:.1f}, cosh {cosh(TH * HALF):.6f}")
print("lattice   h      P(+3)      E[tau]   E[e^-lam tau]       error  level price       error")
lat = []
for h in (1.0, 0.5, 0.25, 0.125, 0.0625):
    lat.append(lattice(h))
    s1, t1, d1, o1 = lat[-1]
    print(f"lattice {h:6.4f} {s1:10.6f} {t1:10.6f} {d1:12.6f} {d1 - lap_int:+11.7f} {o1:12.6f} {o1 - level:+11.7f}")
print(f"Simpson on the first-passage density: level price {quad_level:.6f}")
for T, m in partial:
    print(f"mean of tau_3 cut at {T:9.0f} s: {m:10.2f}   3 sqrt(2T/pi) - 9 = {B * sqrt(2 * T / pi) - B * B:10.2f}")
print(f"(1 - E[e^-lam tau]) / lam at lam = 1e-6: {(1 - lap(1e-6)) / 1e-6:.4f}")
print(f"wrong theta = sqrt(lam), no 1/2: level price {exp(-B * sqrt(LAM)):.6f}")
print(f"wrong side b/(a+b): {B / (A + B):.6f}")
print(f"E[W_tau^2] = 0.4*9 + 0.6*4 = {p_right * B * B + (1 - p_right) * A * A:.6f}")
for a in (2.0, 20.0, 200.0, 2000.0):
    print(f"left wall at -{a:.0f}: E[tau] = {a * B:.0f} s, P(+3 first) = {a / (a + B):.6f}")
labels = ("P(leave at +3)", "E[tau]", "E[W_tau]", "E[W_tau^2 - tau]", "E[exp(th W - lam tau)]", "E[e^-lam tau]")
for dt, paths in ((0.04, 10000), (0.01, 10000)):
    m, se, pic = simulate(dt, paths, 20260930)
    print(f"simulation dt {dt} s, {paths} paths, seed 20260930")
    for lab, mi, si in zip(labels, m, se):
        print(f"  {lab:<24} {mi:10.4f}  se {si:.4f}")
    assert abs(m[2]) < 4 * se[2], "W is fair at the grid exit time"
    assert abs(m[3]) < 4 * se[3], "W^2 - t is fair at the grid exit time"
    assert abs(m[4] - 1.0) < 4 * se[4], "exponential martingale averages 1 at the grid exit time"
trace, tau = pic                      # first dt = 0.01 path leaving within 0.5 s of 6 s
print("figure, t " + " ".join(f"{min(0.25 * i, tau):.2f}" for i in range(len(trace))))
print("figure, W " + " ".join(f"{w:.2f}" for w in trace))

s5, t5, d5, o5 = lat[-1]
assert abs(s5 - p_right) < 1e-9, "lattice side vs a/(a+b)"
assert abs(t5 - mean_exit) < 1e-9, "lattice time vs ab"
assert abs(d5 - lap_int) < 1e-5, "lattice discount vs cosh formula"
assert abs(lat[0][2] - lap_int) > 100 * abs(d5 - lap_int), "lattice error shrinks like h^2"
assert abs(o5 - level) < 1e-5, "lattice one-level price vs exp(-b sqrt(2 lam))"
assert abs(quad_level - level) < 1e-6, "reflection density vs exponential martingale"
assert abs(partial[-1][1] - (B * sqrt(2 * 1e6 / pi) - B * B)) < 0.1, "partial means grow like sqrt(T)"
print("ALL CHECKS PASS")
