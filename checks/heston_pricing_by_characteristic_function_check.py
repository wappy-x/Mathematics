# Pricing Heston exactly -- the check behind the card. Standard library only: cmath does the complex
# arithmetic; Simpson's rule, the normal CDF, bisection and the random numbers are written here.
import cmath
from math import log, exp, sqrt, pi, cos, sin, atan2

S, K, r, q, T = 100.0, 100.0, 0.05, 0.02, 1.0           # the house market
P = (0.04, 2.0, 0.04, 0.3, -0.7)                         # Heston: v0, kappa, theta, xi, rho
V0, KAP, TH, XI, RHO = P

def parts(u, T, p=P, trap=False, mu=r - q):              # beta, d, g, e^-dT, A, B at frequency u
    v0, kap, th, xi, rho = p
    beta = kap - rho * xi * 1j * u
    d = cmath.sqrt(beta * beta + xi * xi * (u * u + 1j * u))   # principal root: real part >= 0
    if trap: d = -d                                      # Heston's 1993 layout: the other root
    g = (beta - d) / (beta + d)
    e = cmath.exp(-d * T)
    A = mu * 1j * u * T + kap * th / (xi * xi) * ((beta - d) * T - 2 * cmath.log((1 - g * e) / (1 - g)))
    B = (beta - d) / (xi * xi) * (1 - e) / (1 - g * e)
    return beta, d, g, e, A, B

def phi(u, T=T, p=P, trap=False, mu=r - q):              # E[exp(i u ln S_T)], closed form
    A, B = parts(u, T, p, trap, mu)[4:]
    return cmath.exp(1j * u * log(S) + A + B * p[0])

def phi_ode(u, T, steps=4000):                           # same fingerprint: solve B' and A' by RK4
    beta = KAP - RHO * XI * 1j * u
    f = lambda B: 0.5 * XI * XI * B * B - beta * B - 0.5 * (u * u + 1j * u)
    h, A, B = T / steps, 0j, 0j
    for _ in range(steps):
        k1 = f(B); b2 = B + h / 2 * k1; k2 = f(b2); b3 = B + h / 2 * k2; k3 = f(b3); b4 = B + h * k3
        A += h * ((r - q) * 1j * u + KAP * TH * (B + 2 * b2 + 2 * b3 + b4) / 6)
        B += h / 6 * (k1 + 2 * k2 + 2 * k3 + f(b4))
    return cmath.exp(1j * u * log(S) + A + B * V0)

def simpson(f, a, b, n):
    h = (b - a) / n
    s = f(a) + f(b)
    for k in range(1, n):
        s += (4 if k % 2 else 2) * f(a + k * h)
    return s * h / 3

def integrand(u, T=T, p=P, trap=False, mu=r - q, same=False):
    top = phi(u, T, p, trap, mu) if same else phi(u - 1j, T, p, trap, mu)
    return (cmath.exp(-1j * u * log(K)) * (top - K * phi(u, T, p, trap, mu)) / (1j * u)).real

def call(T=T, p=P, n=200, U=100.0, trap=False, mu=r - q, same=False, half=1.0):
    I = simpson(lambda u: integrand(u, T, p, trap, mu, same), 1e-8, U, n)
    return half * 0.5 * (S * exp(-q * T) - K * exp(-r * T)) + exp(-r * T) / pi * I

def lewis(n, U=100.0):                                   # road 2: integrate along Im u = -1/2
    F = S * exp((r - q) * T)
    f = lambda u: (cmath.exp(1j * u * log(F / K)) * phi(u - 0.5j)
                   / cmath.exp(1j * (u - 0.5j) * log(F))).real / (u * u + 0.25)
    return S * exp(-q * T) - sqrt(S * K) * exp(-(r + q) * T / 2) / pi * simpson(f, 0.0, U, n)

def prob(shift):                                         # P2 (shift 0) or P1 (shift 1), one integral
    f = lambda u: (cmath.exp(-1j * u * log(K)) * phi(u - 1j * shift) / (1j * u * phi(-1j * shift))).real
    return 0.5 + simpson(f, 1e-8, 100.0, 200) / pi

def N(x): return 0.5 + simpson(lambda z: exp(-0.5 * z * z) / sqrt(2 * pi), 0.0, x, 2000)
def bs(sig):
    d1 = (log(S / K) + (r - q + 0.5 * sig * sig) * T) / (sig * sqrt(T))
    return S * exp(-q * T) * N(d1) - K * exp(-r * T) * N(d1 - sig * sqrt(T))
def implied(price):                                      # bisection on the Black-Scholes price
    lo, hi = 0.01, 1.0
    for _ in range(60):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if bs(mid) < price else (lo, mid)
    return 0.5 * (lo + hi)

def mc(paths, steps=100, seed=12345):                    # road 3: full-truncation Euler
    st, M, dt = seed, (1 << 64) - 1, T / steps
    sr, sw = sqrt(1 - RHO * RHO), sqrt(dt)
    s = s2 = hit = sh = 0.0
    for _ in range(paths):
        x, v = log(S), V0
        for _ in range(steps):
            st = (6364136223846793005 * st + 1442695040888963407) & M      # 64-bit LCG
            u1 = ((st >> 11) + 0.5) / 9007199254740992.0
            st = (6364136223846793005 * st + 1442695040888963407) & M
            rad, ang = sqrt(-2.0 * log(u1)), 2.0 * pi * ((st >> 11) / 9007199254740992.0)
            z1, z2 = rad * cos(ang), rad * sin(ang)                          # Box-Muller
            vp = v if v > 0.0 else 0.0                                       # full truncation
            sv = sqrt(vp) * sw
            x += (r - q - 0.5 * vp) * dt + sv * z1
            v += KAP * (TH - vp) * dt + XI * sv * (RHO * z1 + sr * z2)
        ST = exp(x)
        if ST > K:
            s += ST - K; s2 += (ST - K) * (ST - K); hit += 1.0; sh += ST
    m = s / paths
    return (exp(-r * T) * m, exp(-r * T) * sqrt((s2 / paths - m * m) / paths),
            sh / paths / (S * exp((r - q) * T)), hit / paths)

C, P1, P2 = call(), prob(1.0), prob(0.0)
mcC, mcSE, mcP1, mcP2 = mc(200000)
smC, smSE = mc(20000)[:2]
col, bs20 = call(p=(0.04, 2.0, 0.04, 1e-4, 0.0)), bs(0.2)
good5, bad5, ode5 = phi(4.0, 5.0), phi(4.0, 5.0, trap=True), phi_ode(4.0, 5.0)
turn = atan2((bad5 / good5).imag, (bad5 / good5).real)
gmax = max(abs(parts(0.5 * k - 1j * s, T)[2]) for k in range(201) for s in (0, 1))   # |g| at u and u - i
zs = list(zip(("u=1 beta", "u=1 d", "u=1 g", "u=1 e^-dT", "u=1 A", "u=1 B"), parts(1.0, T))) + [("u=1 phi, closed form", phi(1.0)),
      ("u=1 phi, RK4 on the equations", phi_ode(1.0, T)), ("T=5 u=4 phi, closed form", good5), ("T=5 u=4 phi, RK4", ode5), ("T=5 u=4 phi, 1993 layout", bad5)]
for name, z in zs: print(f"{name:<34}{z.real:>+14.6f}{z.imag:>+13.6f}i")
print(f"{'|phi| at u=100':<34}{abs(phi(100.0)):>14.3e}")
for name, v in (("forward S e^(r-q)T", S * exp((r - q) * T)), ("phi(0)", phi(0.0).real), ("phi(-i)", phi(-1j).real),
        ("largest |g|, u and u-i to 100", gmax), ("T=5 u=4 turn, 1993 vs stable", turn), ("  4 pi (kappa theta/xi^2 - 1)", 4 * pi * (KAP * TH / (XI * XI) - 1)),
        ("half-gap", 0.5 * (S * exp(-q * T) - K * exp(-r * T))), ("the integral, 200 slices", call(half=0.0) * pi / exp(-r * T)),
        ("e^-rT/pi x integral", call(half=0.0)), ("1 HESTON CALL, 200 slices", C),
        ("  same, 2000 slices to u=200", call(n=2000, U=200.0)), ("2 Lewis integral, 2000 slices", lewis(2000)),
        ("3 P1, counted in shares", P1), ("  P1 by simulation", mcP1), ("  P2, counted in dollars", P2), ("  P2 by simulation", mcP2),
        ("4 simulation, 200000 paths", mcC), ("  standard error", mcSE),
        ("5 Heston at xi=1e-4, rho=0", col), ("  Black-Scholes at 20%", bs20), ("implied vol of the Heston call", implied(C)),
        ("wrong: no half-gap", call(half=0.0)), ("wrong: phi(u) in both slots", call(same=True)),
        ("wrong: dividend left out of phi", call(mu=r)), ("wrong: Lewis with 200 slices", lewis(200)),
        ("wrong: integral stopped at u=10", call(U=10.0)),
        ("try: xi = 0.6", call(p=(0.04, 2.0, 0.04, 0.6, -0.7))), ("try: rho = 0", call(p=(0.04, 2.0, 0.04, 0.3, 0.0))),
        ("try: 20 slices", call(n=20)), ("try: simulation, 20000 paths", smC), ("  standard error", smSE)):
    print(f"{name:<34}{v:>14.6f}")
years, us = range(1, 11), range(0, 21, 2)
print("chart, years      " + "".join(f"{t:7d}" for t in years))
print("chart, stable     " + "".join(f"{call(T=t):7.2f}" for t in years))
print("chart, 1993 layout" + "".join(f"{call(T=t, trap=True):7.2f}" for t in years))
print("chart, u          " + "".join(f"{u:7d}" for u in us))
print("chart, integrand  " + "".join(f"{integrand(max(u, 1e-8)):7.2f}" for u in us))

assert abs(phi(-1j) - S * exp((r - q) * T)) < 1e-9,              "phi(-i) must be the forward"
assert abs(phi(1.0) - phi_ode(1.0, T)) < 1e-10,                  "closed form vs the equations solved by RK4"
assert abs(good5 - ode5) < 1e-10,                                "at five years the stable layout matches the equations"
assert abs(bad5 - ode5) > 0.1,                                   "at five years the 1993 layout misses"
assert gmax < 1.0,                                               "stable layout: |g| < 1 keeps the log off its cut"
assert abs(turn - 4 * pi * (KAP * TH / (XI * XI) - 1)) < 1e-9,       "the 1993 error is one whole turn of the log"
assert abs(C - call(n=2000, U=200.0)) < 1e-6,                    "200 slices must already be converged"
assert abs(C - lewis(2000)) < 1e-6,                              "Lewis's integral must agree"
assert abs(mcC - C) < 3 * mcSE,                                  "simulation within 3 standard errors"
assert abs(mcP2 - P2) < 3 * sqrt(P2 * (1 - P2) / 200000),        "exercise chance: integral vs simulation"
assert abs(col - bs20) < 1e-6,                                   "no vol-of-vol: Heston becomes Black-Scholes"
assert abs(bs20 - 9.227005508154) < 1e-8,                        "the house Black-Scholes call"
print("ALL CHECKS PASS")
