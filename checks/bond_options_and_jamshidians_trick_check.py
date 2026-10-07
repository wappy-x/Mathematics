# Bond options and Jamshidian's trick -- the check behind the card.  Standard
# library only; the normal CDF, root finder, integrator and PDE solver are
# written here.  Hull-White fitted to the shelf's curve (Vasicek: reversion
# a = 0.3 to b = 5%, volatility 1%, short rate today 4%).  Money per 100 face.
from math import exp, log, sqrt, pi
a, b, sig, r0 = 0.3, 0.05, 0.01, 0.04
T, S, K = 1.0, 5.0, 83.0                       # 1-year call on the 5-year zero, strike 83
FLOWS = [(2.0, 5.0), (3.0, 5.0), (4.0, 5.0), (5.0, 105.0)]   # the 5-year 5% bond
X = 101.0                                      # 1-year call on it, strike 101

def N(x):                                      # bell-curve area left of x, by its series
    if abs(x) > 8.0: return 0.0 if x < 0 else 1.0
    term, total, n = x, x, 1
    while abs(term) > 1e-17 * abs(total) + 1e-300:
        term *= x * x / (2 * n + 1); total += term; n += 1
    return 0.5 + exp(-0.5 * x * x) / sqrt(2 * pi) * total
def Bf(tau): return (1 - exp(-a * tau)) / a
def vas(tau, r):                               # Vasicek bond price, tau years left, short rate r
    lnA = (b - sig * sig / (2 * a * a)) * (Bf(tau) - tau) - sig * sig * Bf(tau) ** 2 / (4 * a)
    return exp(lnA - Bf(tau) * r)
def P0(t, shift=0.0): return vas(t, r0) * exp(-shift * t)       # today's curve
def fwd(t, shift=0.0, h=1e-4): return -(log(P0(t + h, shift)) - log(P0(t - h, shift))) / (2 * h)
def hw_bond(t, u, r, shift=0.0, s=sig):        # Hull-White bond price at t, fitted to the curve
    Bu = Bf(u - t)
    return P0(u, shift) / P0(t, shift) * exp(Bu * fwd(t, shift) - s * s / (4 * a) * (1 - exp(-2 * a * t)) * Bu * Bu - Bu * r)
def sigma_p(t, u, s=sig): return s * Bf(u - t) * sqrt((1 - exp(-2 * a * t)) / (2 * a))
def zbc(t, u, k, shift=0.0, s=sig):            # ROAD 1: the closed form, strike k per 1 face
    PT, PU, sp = P0(t, shift), P0(u, shift), sigma_p(t, u, s)
    h = log(PU / (PT * k)) / sp + sp / 2
    return PU * N(h) - k * PT * N(h - sp)
def zbp(t, u, k):
    PT, PU, sp = P0(t), P0(u), sigma_p(t, u)
    h = log(PU / (PT * k)) / sp + sp / 2
    return k * PT * N(sp - h) - PU * N(-h)
def bisect(f, lo, hi):
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if (f(lo) > 0) == (f(mid) > 0): lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)
def jamshidian(shift=0.0, s=sig):              # coupon-bond call as a portfolio of zero calls
    rstar = bisect(lambda r: sum(c * hw_bond(T, u, r, shift, s) for u, c in FLOWS) - X, -0.5, 0.5)
    ks = [hw_bond(T, u, rstar, shift, s) for u, c in FLOWS]
    return rstar, ks, sum(c * zbc(T, u, k, shift, s) for (u, c), k in zip(FLOWS, ks))
# ROAD 2: average over the short rate on expiry day, jointly with the path's discount
e1, e2 = exp(-a * T), exp(-2 * a * T)
m_r, v_r = b + (r0 - b) * e1, sig * sig * (1 - e2) / (2 * a)
m_I = b * T + (r0 - b) * (1 - e1) / a
v_I = sig * sig / (a * a) * (T - 2 * (1 - e1) / a + (1 - e2) / (2 * a))
cov = sig * sig / (2 * a * a) * (1 - e1) ** 2
def by_integral(payoff, n=20000):
    lo, hi = m_r - 10 * sqrt(v_r), m_r + 10 * sqrt(v_r)
    h, tot = (hi - lo) / n, 0.0
    for i in range(n + 1):
        x = lo + i * h
        dens = exp(-(x - m_r) ** 2 / (2 * v_r)) / sqrt(2 * pi * v_r)
        disc = exp(-(m_I + cov / v_r * (x - m_r)) + 0.5 * (v_I - cov * cov / v_r))
        tot += (1 if i in (0, n) else 4 if i % 2 else 2) * dens * disc * payoff(x)
    return tot * h / 3
# ROAD 3: Crank-Nicolson on the term-structure equation, backwards from expiry
def by_pde(payoff, M=400, steps=200):
    h, dt = 0.0005, T / steps
    rs = [r0 - 0.1 + i * h for i in range(M + 1)]
    V = [payoff(r) for r in rs]
    lo = [0.5 * sig * sig / h ** 2 - a * (b - r) / (2 * h) for r in rs]
    di = [-sig * sig / h ** 2 - r for r in rs]
    up = [0.5 * sig * sig / h ** 2 + a * (b - r) / (2 * h) for r in rs]
    for _ in range(steps):
        rhs = [V[i] + 0.5 * dt * (lo[i] * V[i - 1] + di[i] * V[i] + up[i] * V[i + 1]) for i in range(1, M)]
        A_ = [-0.5 * dt * lo[i] for i in range(1, M)]; B_ = [1 - 0.5 * dt * di[i] for i in range(1, M)]
        C_ = [-0.5 * dt * up[i] for i in range(1, M)]
        for j in range(1, M - 1):              # Thomas algorithm, forward sweep
            w = A_[j] / B_[j - 1]; B_[j] -= w * C_[j - 1]; rhs[j] -= w * rhs[j - 1]
        x = [0.0] * (M - 1); x[-1] = rhs[-1] / B_[-1]
        for j in range(M - 3, -1, -1): x[j] = (rhs[j] - C_[j] * x[j + 1]) / B_[j]
        V = [2 * x[0] - x[1]] + x + [2 * x[-1] - x[-2]]
    return V[200]
zpay = lambda r: max(100 * vas(S - T, r) - K, 0.0)
cpay = lambda r: max(sum(c * vas(u - T, r) for u, c in FLOWS) - X, 0.0)
C1, C2, C3 = 100 * zbc(T, S, K / 100), by_integral(zpay), by_pde(zpay)
P1, P2 = 100 * zbp(T, S, K / 100), by_integral(lambda r: max(K - 100 * vas(S - T, r), 0.0))
rstar, ks, J1 = jamshidian()
J2, J3 = by_integral(cpay), by_pde(cpay)
fwd_cb = sum(c * P0(u) for u, c in FLOWS) / P0(T)
kpr = [X / fwd_cb * P0(u) / P0(T) for u, c in FLOWS]           # strikes split pro rata to forwards
prorata = sum(c * zbc(T, u, k) for (u, c), k in zip(FLOWS, kpr))
theta = [(fwd(t + 1e-3) - fwd(t - 1e-3)) / 2e-3 + a * fwd(t) + sig ** 2 / (2 * a) * (1 - exp(-2 * a * t)) for t in (0.5, 1.0, 3.0)]
def black(sp, F=P0(S) / P0(T), k=K / 100):    # Black-76 on a forward F, strike k, discount P(0,1)
    h = log(F / k) / sp + sp / 2
    return 100 * P0(T) * (F * N(h) - k * N(h - sp))
hh = log(P0(S) / (P0(T) * K / 100)) / sigma_p(T, S) + sigma_p(T, S) / 2
rows = [("P(0,1)  curve today", P0(T)), ("P(0,5)", P0(S)), ("  E[exp(-integral of r)] to year 1", exp(-m_I + 0.5 * v_I)),
        ("theta(0.5) read off the curve", theta[0]), ("theta(3)", theta[2]),
        ("forward price of the zero at year 1", 100 * P0(S) / P0(T)), ("B(1,5)", Bf(S - T)),
        ("P(1,5) at r = 5%, Hull-White fitted", hw_bond(T, S, 0.05)), ("P(1,5) at r = 5%, Vasicek direct", vas(S - T, 0.05)), ("damping sqrt((1-e^-2aT)/2a)", sqrt((1 - e2) / (2 * a))), ("sigma_P", sigma_p(T, S)),
        ("ln(forward / strike)", log(P0(S) / P0(T) / (K / 100))), ("h", hh), ("N(h)", N(hh)), ("N(h - sigma_P)", N(hh - sigma_p(T, S))),
        ("bond leg   100 P(0,5) N(h)", 100 * P0(S) * N(hh)), ("strike leg K P(0,1) N(h - sigma_P)", K * P0(T) * N(hh - sigma_p(T, S))),
        ("zero call 1 formula", C1), ("zero call 2 integral", C2), ("zero call 3 PDE", C3),
        ("zero put formula", P1), ("zero put integral", P2), ("  C - P", C1 - P1), ("  P(0,5)*100 - K P(0,1)", 100 * P0(S) - K * P0(T)),
        ("forward price of the coupon bond", fwd_cb), ("r* where the bond is worth 101", rstar)]
rows += [(f"  strike K_{int(u)} (per 100 face)", 100 * k) for (u, c), k in zip(FLOWS, ks)]
rows += [(f"  leg {int(u)}: {c:g} x call on $1 due yr {int(u)}", c * zbc(T, u, k)) for (u, c), k in zip(FLOWS, ks)]
rows += [("  sum c_i K_i", sum(c * k for (u, c), k in zip(FLOWS, ks))),
         ("coupon call 1 Jamshidian", J1), ("coupon call 2 integral", J2), ("coupon call 3 PDE", J3),
         ("wrong: sigma*sqrt(T) as bond vol", black(sig * sqrt(T))), ("wrong: B(0,5) not B(1,5)", black(sig * Bf(S) * sqrt((1 - e2) / (2 * a)))),
         ("wrong: sqrt(T), no damping", black(sig * Bf(S - T) * sqrt(T))), ("wrong: coupon bond at the zero's vol", black(sigma_p(T, S), fwd_cb / 100, X / 100)),
         ("wrong: pro-rata strikes, coupon", prorata),
         ("greek: zero call, +1bp curve", 100 * (zbc(T, S, K / 100, 1e-4) - zbc(T, S, K / 100))),
         ("greek: coupon call, +1bp curve", jamshidian(1e-4)[2] - J1),
         ("greek: zero call, sigma +0.1pt", 100 * (zbc(T, S, K / 100, 0.0, sig + 0.001) - zbc(T, S, K / 100))),
         ("greek: coupon call, sigma +0.1pt", jamshidian(0.0, sig + 0.001)[2] - J1)]
for name, v in rows: print(f"{name:<38} {v:>12.6f}")
rgrid = [0.02 + 0.005 * i for i in range(9)]
pairs = list(zip(FLOWS, ks))                   # each cash flow with its Jamshidian strike
def legs(ps, r): return sum(c * max(vas(u - T, r) - k, 0.0) for (u, c), k in ps)
print("chart, r at expiry %  " + " ".join(f"{100 * r:6.1f}" for r in rgrid))
print("chart, coupon payoff  " + " ".join(f"{cpay(r):6.2f}" for r in rgrid))
print("chart, Jamshidian sum " + " ".join(f"{legs(pairs, r):6.2f}" for r in rgrid))
print("chart, final-year leg " + " ".join(f"{legs(pairs[3:], r):6.2f}" for r in rgrid))
print("chart, 3 coupon legs  " + " ".join(f"{legs(pairs[:3], r):6.2f}" for r in rgrid))
print("chart, expiry (years) " + " ".join(f"{0.5 * i:6.1f}" for i in range(11)))
print("chart, sigma_P %      " + " ".join(f"{100 * sigma_p(0.5 * i, S):6.2f}" for i in range(11)))
assert abs(exp(-m_I + 0.5 * v_I) - P0(T)) < 1e-12, "path discount must rebuild the curve"
assert all(abs(t - a * b) < 1e-6 for t in theta), "fitted drift must be a*b on a Vasicek curve"
assert abs(hw_bond(T, S, 0.05) - vas(S - T, 0.05)) < 1e-9, "fitted Hull-White bond vs Vasicek bond"
assert abs(C1 - C2) < 1e-6, "zero call: formula vs integral"
assert abs(C1 - C3) < 2e-4, "zero call: formula vs PDE"
assert abs((C1 - P2) - (100 * P0(S) - K * P0(T))) < 1e-6, "parity with the integral's put"
assert abs(J1 - J2) < 1e-6, "coupon call: Jamshidian vs integral"
assert abs(J1 - J3) < 2e-4, "coupon call: Jamshidian vs PDE"
assert prorata > J1 + 1e-4, "a sum of options beats an option on the sum unless strikes line up"
print("ALL CHECKS PASS")
