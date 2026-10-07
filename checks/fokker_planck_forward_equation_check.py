# Fokker-Planck forward equation -- the check behind the card.  Standard library only.
# Roads: (1) the known densities put into the equation by finite differences; (2) the
# adjoint identity integrated numerically; (3) the equation solved on a grid; (4) a seeded
# simulation.  Units: speck in micrometres and seconds; OU rate in percentage points
# and years.  Every number quoted on the card is printed here.
from math import exp, sqrt, log, cos, sin, pi

K, TH, S, R0 = 0.5, 4.0, 2.0, 6.0          # OU pull speed /yr, level, noise, start (points)
def gauss(y, m, v): return exp(-(y - m) ** 2 / (2 * v)) / sqrt(2 * pi * v)
def bm(t, y): return gauss(y, 0.0, t)                                   # speck, sigma = 1
def ou_mv(t): return TH + (R0 - TH) * exp(-K * t), S * S / (2 * K) * (1 - exp(-2 * K * t))
def ou(t, y): m, v = ou_mv(t); return gauss(y, m, v)
def simpson(f, a, b, n=2000):
    h = (b - a) / n
    return h / 3 * (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n)))

def residual(p, mu, s2, t, y, h, op="adj"):                 # p_t minus the right-hand side
    pt = (p(t + h, y) - p(t - h, y)) / (2 * h)
    dif = s2 / 2 * (p(t, y + h) - 2 * p(t, y) + p(t, y - h)) / (h * h)
    if op == "adj": adv = -(mu(y + h) * p(t, y + h) - mu(y - h) * p(t, y - h)) / (2 * h)
    else: adv = mu(y) * (p(t, y + h) - p(t, y - h)) / (2 * h)              # generator L used by mistake
    return pt - (adv + dif)

mu_ou = lambda y: K * (TH - y)
mu_0 = lambda y: 0.0
print("figure 1, speck density per um at y = -4..4:")
for t in (0.5, 1.0, 4.0):
    print(f"  t={t:.1f} s: " + " ".join(f"{bm(t, y):.2f}" for y in range(-4, 5)) + f"  peak {bm(t, 0):.4f}")
print("residual of the forward equation, formula put in, step h:")
res = []
for h in (0.1, 0.05, 0.025):
    a, b = residual(bm, mu_0, 1.0, 1.0, 1.0, h), residual(ou, mu_ou, S * S, 1.0, 5.0, h)
    c = residual(ou, mu_ou, S * S, 1.0, 5.0, h, "gen")
    res.append((a, b, c))
    print(f"  h={h:.3f}  BM(1,1) {a:+.7f}  OU(1,5) {b:+.7f}  OU with L instead {c:+.5f}")
assert abs(res[2][0]) < 1e-4, "BM density fails the heat equation"
assert abs(res[2][1]) < 1e-4, "OU density fails the forward equation"
assert 3.5 < res[1][1] / res[2][1] < 4.5, "residual not shrinking like h^2"
assert abs(res[2][2]) > 0.05, "generator should not fit the density"

m1, v1 = ou_mv(1.0); sd1 = sqrt(v1); lo, hi = m1 - 12 * sd1, m1 + 12 * sd1; e = 1e-3
f = lambda y: y * y
Lf = lambda y: mu_ou(y) * 2 * y + S * S / 2 * 2
Lstar_p = lambda y: (-(mu_ou(y + e) * ou(1, y + e) - mu_ou(y - e) * ou(1, y - e)) / (2 * e)
                     + S * S / 2 * (ou(1, y + e) - 2 * ou(1, y) + ou(1, y - e)) / (e * e))
dEdt = (simpson(lambda y: f(y) * ou(1 + e, y), lo, hi) - simpson(lambda y: f(y) * ou(1 - e, y), lo, hi)) / (2 * e)
I_back, I_fwd = simpson(lambda y: Lf(y) * ou(1, y), lo, hi), simpson(lambda y: f(y) * Lstar_p(y), lo, hi)
exact = (S * S - 2 * K * v1) + 2 * m1 * K * (TH - m1)
print("adjoint identity, OU at t=1 yr, f(y)=y^2:")
print(f"  d/dt E[f] by differencing {dEdt:.5f}\n  integral of (Lf) p        {I_back:.5f}")
print(f"  integral of f (L* p)      {I_fwd:.5f}\n  from mean and variance    {exact:.5f}")
print(f"  by hand: e^-0.5 {exp(-0.5):.5f} mean {m1:.5f} slope {K * (TH - m1):+.5f} variance {v1:.5f} slope {S * S - 2 * K * v1:+.5f}")
print(f"  E[X^2] {v1 + m1 * m1:.5f}  2 kappa theta mean {2 * K * TH * m1:.5f}  2 mean slope {2 * m1 * K * (TH - m1):+.5f}")
assert abs(I_back - I_fwd) < 1e-4, "adjoint"
assert abs(dEdt - exact) < 1e-4, "rate of E[f]"

def solve(mu, ylo, yhi, dy, t0, t1, p0, sgn=-1, gen=False, s2=S * S):  # explicit grid, zero at both ends
    n = round((yhi - ylo) / dy); ys = [ylo + i * dy for i in range(n + 1)]
    steps = round((t1 - t0) / (0.2 * dy * dy / s2)); dt = (t1 - t0) / steps
    p = [p0(y) for y in ys]; p[0] = p[-1] = 0.0; m = [mu(y) for y in ys]; d2 = s2 / 2 / (dy * dy)
    for _ in range(steps):
        q = p[:]
        for i in range(1, n):
            adv = (m[i] * (p[i + 1] - p[i - 1]) if gen else sgn * (m[i + 1] * p[i + 1] - m[i - 1] * p[i - 1])) / (2 * dy)
            q[i] = p[i] + dt * (adv + d2 * (p[i + 1] - 2 * p[i] + p[i - 1]))
        p = q
    return ys, p, steps
def moments(ys, p, dy):
    m0 = sum(p) * dy; m = sum(y * q for y, q in zip(ys, p)) * dy / m0
    return m0, m, sqrt(sum((y - m) ** 2 * q for y, q in zip(ys, p)) * dy / m0)

print("grid solve, OU from the formula at t=0.1 yr to t=1 yr, y in [-6,16]:")
errs = []
for dy in (0.2, 0.1, 0.05):
    ys, p, n = solve(mu_ou, -6.0, 16.0, dy, 0.1, 1.0, lambda y: ou(0.1, y))
    errs.append(max(abs(q - ou(1.0, y)) for y, q in zip(ys, p))); mass, mg, sg = moments(ys, p, dy)
    print(f"  dy={dy:.2f} steps={n} max error {errs[-1]:.6f} mass {mass:.6f} mean {mg:.4f} sd {sg:.4f}")
assert errs[2] < errs[1] < errs[0] and 3.0 < errs[1] / errs[2] < 5.0, "grid not converging"
ys, p, n = solve(mu_ou, -6.0, 16.0, 0.1, 0.1, 1.0, lambda y: ou(0.1, y), gen=True)
mg_gen = moments(ys, p, 0.1)[0]
ys, p, n = solve(mu_ou, -6.0, 26.0, 0.1, 0.1, 1.0, lambda y: ou(0.1, y), sgn=1)
mean_flip = moments(ys, p, 0.1)[1]
ys, p, n = solve(mu_0, -1.0, 9.0, 0.05, 0.05, 1.0, lambda y: bm(0.05, y) - bm(0.05, y + 2), s2=1.0)
surv = moments(ys, p, 0.05)[0]; surv_img = 1 - 2 * (0.5 - simpson(lambda y: bm(1, y), -1, 0))
print(f"what breaks:\n  generator L on the density: mass at 1 yr {mg_gen:.4f}  (e^(0.9 kappa) = {exp(0.9 * K):.4f})")
print(f"  drift term with the wrong sign: mean at 1 yr {mean_flip:.4f}  (theta + 2 e^(0.8 kappa) = {TH + (R0 - TH) * exp(0.8 * K):.4f})")
print(f"  drop the 1/2: BM peak at 1 s {gauss(0, 0, 2):.4f}  (right: {bm(1, 0):.4f})")
print(f"  wall at -1 um: grid survival {surv:.4f}  images {surv_img:.4f}  free bell 1.0000")
assert abs(mg_gen - exp(0.9 * K)) < 0.01, "generator mass"
assert abs(mean_flip - (TH + (R0 - TH) * exp(0.8 * K))) < 0.01, "flipped drift"
assert abs(surv - surv_img) < 2e-3, "wall"

g = lambda y: simpson(lambda u: 2 * mu_ou(u) / (S * S), TH, y, 40)   # zero flux: (ln p)' = 2 mu / s^2
Z = simpson(lambda y: exp(g(y)), -16, 24, 400)
sd_inf = sqrt(simpson(lambda y: (y - TH) ** 2 * exp(g(y)), -16, 24, 400) / Z)
below = simpson(lambda y: exp(g(y)), -16, 0, 400) / Z
print(f"stationary, zero flux: sd {sd_inf:.4f} (formula {sqrt(S * S / (2 * K)):.4f})  P(rate<0) {below:.4f}")
assert abs(sd_inf - sqrt(S * S / (2 * K))) < 1e-4, "stationary spread"

state = 20260930
def rnd():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF; z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53 + 2.0 ** -54
N, M = 10000, 1000; dt = 1.0 / M; ends = []
for _ in range(N):
    r = R0
    for _ in range(M // 2):
        a = sqrt(-2 * log(rnd())); b = 2 * pi * rnd()
        r += K * (TH - r) * dt + S * sqrt(dt) * a * cos(b)
        r += K * (TH - r) * dt + S * sqrt(dt) * a * sin(b)
    ends.append(r)
mean = sum(ends) / N; sd = sqrt(sum((x - mean) ** 2 for x in ends) / N)
print(f"OU at 1 yr: formula mean {m1:.4f} sd {sd1:.4f} peak {ou(1, m1):.4f} per point")
print(f"simulated {N} paths x {M} steps, seed 20260930: mean {mean:.4f} (se {sd / sqrt(N):.4f}) sd {sd:.4f} (se {sd / sqrt(2 * N):.4f})")
assert abs(mean - m1) < 4 * sd / sqrt(N) and abs(sd - sd1) < 4 * sd / sqrt(2 * N)
print("figure 2, percent of paths per 1-point bin [a, a+1):")
for a in range(1, 10):
    fr = sum(1 for x in ends if a <= x < a + 1) / N; se = sqrt(fr * (1 - fr) / N)
    ex = simpson(lambda y: ou(1, y), a, a + 1, 200)
    print(f"  [{a},{a + 1}) simulated {100 * fr:.2f} (se {100 * se:.2f}) formula {100 * ex:.2f}")
    assert abs(fr - ex) < 4 * se + 1e-9, "histogram off the forward-equation density"
print("all checks passed")
