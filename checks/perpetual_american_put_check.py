# Perpetual American put -- the check behind the card.  Standard library only.
# Every number on the card is printed here.  Nothing imported knows the answer:
# the root finders, the ODE integrator, the tree and the normal CDF are all
# written out below.  House market: S = K = 100, r = 5%, q = 2%, sigma = 20%.
from math import exp, log, sqrt, pi

S, K, r, q, sig = 100.0, 100.0, 0.05, 0.02, 0.20

def roots(r, q, sig):                         # road 1: the quadratic formula
    a, b, c = 0.5 * sig * sig, r - q - 0.5 * sig * sig, -r
    disc = sqrt(b * b - 4 * a * c)
    return (-b - disc) / (2 * a), (-b + disc) / (2 * a)

def perp(s, K, r, q, sig):                    # the closed form: boundary and value
    lam = roots(r, q, sig)[0]
    b = K * lam / (lam - 1)
    return (b, K - s if s <= b else (K - b) * (s / b) ** lam)

def golden_max(f, lo, hi, n=200):             # road 2: best barrier, no smooth pasting
    g = (sqrt(5) - 1) / 2
    for _ in range(n):
        m1, m2 = hi - g * (hi - lo), lo + g * (hi - lo)
        if f(m1) < f(m2): lo = m1
        else: hi = m2
    return 0.5 * (lo + hi)

def shoot(b, x_end, n=4000):                  # road 3: RK4 on the time-free equation in x = ln s
    a, nu = 0.5 * sig * sig, r - q - 0.5 * sig * sig
    f = lambda u, v: (v, (r * u - nu * v) / a)          # u = price, v = s * slope
    x, u, v = log(b), K - b, -b                         # value matching and smooth pasting
    h = (x_end - x) / n
    for _ in range(n):
        k1 = f(u, v); k2 = f(u + h / 2 * k1[0], v + h / 2 * k1[1])
        k3 = f(u + h / 2 * k2[0], v + h / 2 * k2[1]); k4 = f(u + h * k3[0], v + h * k3[1])
        u += h / 6 * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0])
        v += h / 6 * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1])
    return u

def bisect(f, lo, hi, n=200):
    for _ in range(n):
        mid = 0.5 * (lo + hi)
        if (f(lo) > 0) == (f(mid) > 0): lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

def tree(T, n, american=True):                # road 4: Cox-Ross-Rubinstein tree, finite life T
    dt = T / n
    u = exp(sig * sqrt(dt)); d = 1 / u
    p = (exp((r - q) * dt) - d) / (u - d); df = exp(-r * dt)
    v = [max(K - S * u ** (2 * j - n), 0.0) for j in range(n + 1)]
    for m in range(n - 1, -1, -1):
        s, nv = S * u ** (-m), []
        for j in range(m + 1):
            c = df * (p * v[j + 1] + (1 - p) * v[j])
            if american and K - s > c: c = K - s
            nv.append(c); s *= u * u
        v = nv
    return v[0]

def ncdf(x, n=2000):                          # bell-curve area left of x, by Simpson's rule
    h = x / n
    ph = lambda z: exp(-0.5 * z * z) / sqrt(2 * pi)
    tot = ph(0.0) + ph(x) + sum((4 if i % 2 else 2) * ph(i * h) for i in range(1, n))
    return 0.5 + tot * h / 3

def euro_put(T):
    d1 = (log(S / K) + (r - q + 0.5 * sig * sig) * T) / (sig * sqrt(T)); d2 = d1 - sig * sqrt(T)
    return K * exp(-r * T) * ncdf(-d2) - S * exp(-q * T) * ncdf(-d1)

lam, mu = roots(r, q, sig)
bstar, P = perp(S, K, r, q, sig)
b_gold = golden_max(lambda b: (K - b) * (S / b) ** lam, 1.0, K)
b_shoot = bisect(lambda b: shoot(b, log(1e6)), 40.0, 90.0)
P_shoot = shoot(b_shoot, log(S))
steps = lambda T: max(1000, 50 * T)
mats = [1, 2, 5, 10, 20, 30, 50, 100]
amer = [tree(T, steps(T)) for T in mats]
euro = [euro_put(T) for T in mats]
h = 0.01
dP = lambda s: perp(s, K, r, q, sig)[1]
delta, gamma = lam * P / S, lam * (lam - 1) * P / S ** 2
delta_b = (dP(S + h) - dP(S - h)) / (2 * h)
gamma_b = (dP(S + h) - 2 * P + dP(S - h)) / h ** 2
theta = r * P - 0.5 * sig ** 2 * S ** 2 * gamma_b - (r - q) * S * delta_b   # what the clock takes: zero
assert abs(b_shoot - bstar) < 1e-6 and abs(b_gold - bstar) < 1e-6   # two roads to the boundary
assert abs(P_shoot - P) < 1e-6                                     # the ODE, no power guessed
assert 0 < P - amer[5] < 0.5 and abs(amer[7] - P) < 0.01           # tree rises to the formula
assert abs(delta_b - delta) < 1e-6 and abs(theta) < 1e-4           # slope, and no time decay
vega = (perp(S, K, r, q, sig + 1e-4)[1] - perp(S, K, r, q, sig - 1e-4)[1]) / 2e-4
rho = (perp(S, K, r + 1e-4, q, sig)[1] - perp(S, K, r - 1e-4, q, sig)[1]) / 2e-4
wrong_mu_b = K * mu / (mu - 1)
wrong_q0 = perp(S, K, r, 0.0, sig)
wrong_b80 = (K - 80.0) * (S / 80.0) ** lam

a2, b1 = 0.5 * sig * sig, r - q - 0.5 * sig * sig
rows = [("sigma^2 / 2", a2), ("r - q - sigma^2 / 2", b1),
        ("discriminant b^2 - 4ac", b1 * b1 + 4 * a2 * r), ("  its square root", sqrt(b1 * b1 + 4 * a2 * r)),
        ("lambda, the negative root", lam), ("mu, the positive root", mu),
        ("boundary S* = K lambda / (lambda - 1)", bstar), ("payoff at the boundary K - S*", K - bstar),
        ("S / S*", S / bstar), ("(S / S*)^lambda", (S / bstar) ** lam),
        ("1 formula, value at S = 100", P), ("2 best barrier, golden section", b_gold),
        ("3 boundary by shooting the ODE", b_shoot), ("3 value by shooting the ODE", P_shoot),
        ("4 tree, 30 years, 1500 steps", amer[5]), ("4 tree, 100 years, 5000 steps", amer[7]),
        ("delta = lambda P / S", delta), ("  delta by bump", delta_b),
        ("gamma = lambda (lambda - 1) P / S^2", gamma), ("  gamma by bump", gamma_b),
        ("theta from the equation, size", abs(theta)), ("vega, per point of sigma", vega / 100), ("rho, per point of r", rho / 100),
        ("r K - q S*, waiting cost at S*", r * K - q * bstar),
        ("wrong: positive root, boundary", wrong_mu_b), ("wrong: forgot q, boundary", wrong_q0[0]),
        ("wrong: forgot q, value", wrong_q0[1]), ("wrong: exercise at 80, value", wrong_b80),
        ("wrong: European 30-year put", euro[5]),
        ("try: sigma = 0.30, boundary", perp(S, K, r, q, 0.30)[0]), ("try: sigma = 0.30, value", perp(S, K, r, q, 0.30)[1]),
        ("try: r = 0.08, boundary", perp(S, K, 0.08, q, sig)[0]), ("try: r = 0.08, value", perp(S, K, 0.08, q, sig)[1]),
        ("try: q = 0, value at 200", perp(200.0, K, r, 0.0, sig)[1])]
for name, v in rows:
    print(f"{name:<38} {v:>12.6f}")
print()
print("maturity (years)  " + " ".join(f"{T:>7d}" for T in mats))
print("American, tree    " + " ".join(f"{v:>7.2f}" for v in amer))
print("European, formula " + " ".join(f"{v:>7.2f}" for v in euro))
spots = [40.0 + 10.0 * i for i in range(13)]
print("chart, share price" + " ".join(f"{s:>7.0f}" for s in spots))
print("chart, perpetual  " + " ".join(f"{dP(s):>7.2f}" for s in spots))
print("chart, exercise   " + " ".join(f"{max(K - s, 0.0):>7.2f}" for s in spots))

print("ALL CHECKS PASS")
