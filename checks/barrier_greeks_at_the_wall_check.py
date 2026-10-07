# Barrier Greeks at the wall -- the check behind the card.  Standard library only.
# Roads: (1) the down-and-out formula differentiated by hand, (2) bump and revalue
# on the formula, (3) a Crank-Nicolson grid that never sees the formula,
# (4) static replication when r = q.  The normal CDF is built from math.erf.
from math import log, sqrt, exp, erf, pi

def N(x):   return 0.5 * (1.0 + erf(x / sqrt(2.0)))
def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)
def d12(S, K, r, q, s, T):
    d1 = (log(S / K) + (r - q + 0.5 * s * s) * T) / (s * sqrt(T)); return d1, d1 - s * sqrt(T)
def call(S, K, r, q, s, T):
    d1, d2 = d12(S, K, r, q, s, T); return S * exp(-q * T) * N(d1) - K * exp(-r * T) * N(d2)
def put(S, K, r, q, s, T):
    d1, d2 = d12(S, K, r, q, s, T); return K * exp(-r * T) * N(-d2) - S * exp(-q * T) * N(-d1)
def digital(S, K, r, q, s, T): return exp(-r * T) * N(d12(S, K, r, q, s, T)[1])
def vanilla_greeks(S, K, r, q, s, T):          # delta, gamma, vega of the plain call
    d1 = d12(S, K, r, q, s, T)[0]; e = exp(-q * T)
    return e * N(d1), e * phi(d1) / (S * s * sqrt(T)), S * e * phi(d1) * sqrt(T)

def down_out(S, K, B, r, q, s, T):             # K above B: call minus its mirror image
    if S <= B: return 0.0
    a = 2 * (r - q) / (s * s) - 1
    return call(S, K, r, q, s, T) - (B / S) ** a * call(B * B / S, K, r, q, s, T)
def up_out(S, K, H, r, q, s, T):               # K below H: capped payoff minus its mirror image
    if S >= H: return 0.0
    a = 2 * (r - q) / (s * s) - 1
    w = lambda x: call(x, K, r, q, s, T) - call(x, H, r, q, s, T) - (H - K) * digital(x, H, r, q, s, T)
    return w(S) - (H / S) ** a * w(H * H / S)

def down_out_greeks(S, K, B, r, q, s, T):      # road 1: the formula differentiated by hand
    a = 2 * (r - q) / (s * s) - 1
    x, p = B * B / S, (B / S) ** a
    dx, ddx, dp, ddp = -x / S, 2 * x / (S * S), -a * p / S, a * (a + 1) * p / (S * S)
    Dv, Gv, Vv = vanilla_greeks(S, K, r, q, s, T)
    Dx, Gx, Vx = vanilla_greeks(x, K, r, q, s, T); Cx = call(x, K, r, q, s, T)
    delta = Dv - (dp * Cx + p * Dx * dx)
    gamma = Gv - (ddp * Cx + 2 * dp * Dx * dx + p * Gx * dx * dx + p * Dx * ddx)
    vega = Vv - (p * log(B / S) * (-4 * (r - q) / s ** 3) * Cx + p * Vx)
    return delta, gamma, vega

def bump(f, S, s, h=0.01, hs=0.0001):          # road 2: nudge and reprice
    delta = (f(S + h, s) - f(S - h, s)) / (2 * h)
    gamma = (f(S + h, s) - 2 * f(S, s) + f(S - h, s)) / (h * h)
    return delta, gamma, (f(S, s + hs) - f(S, s - hs)) / (2 * hs)

def grid(lo, hi, M, n, payoff, edge, r, q, s, T):   # road 3: Crank-Nicolson, Rannacher start
    dS = (hi - lo) / M; S = [lo + i * dS for i in range(M + 1)]
    V = [payoff(x) for x in S]
    A = [0.5 * s * s * x * x / dS ** 2 - 0.5 * (r - q) * x / dS for x in S]
    C = [0.5 * s * s * x * x / dS ** 2 + 0.5 * (r - q) * x / dS for x in S]
    steps = [(T / n / 2, 1.0)] * 4 + [(T / n, 0.5)] * (n - 2); tau = 0.0
    for dt, th in steps:
        tau += dt
        rhs = [V[i] + (1 - th) * dt * (A[i] * V[i - 1] - (A[i] + C[i] + r) * V[i] + C[i] * V[i + 1])
               for i in range(1, M)]
        lo_v, hi_v = edge(tau)
        rhs[0] += th * dt * A[1] * lo_v; rhs[-1] += th * dt * C[M - 1] * hi_v
        sub = [-th * dt * A[i] for i in range(1, M)]; sup = [-th * dt * C[i] for i in range(1, M)]
        dia = [1 + th * dt * (A[i] + C[i] + r) for i in range(1, M)]
        for j in range(1, M - 1):                    # Thomas algorithm, forward sweep
            m = sub[j] / dia[j - 1]; dia[j] -= m * sup[j - 1]; rhs[j] -= m * rhs[j - 1]
        x = [0.0] * (M - 1); x[-1] = rhs[-1] / dia[-1]
        for j in range(M - 3, -1, -1): x[j] = (rhs[j] - sup[j] * x[j + 1]) / dia[j]
        V = [lo_v] + x + [hi_v]
    def at(Sv):
        i = round((Sv - lo) / dS)
        return V[i], (V[i + 1] - V[i - 1]) / (2 * dS), (V[i + 1] - 2 * V[i] + V[i - 1]) / dS ** 2
    return at

K, B, H, r, q, s, T = 100.0, 80.0, 120.0, 0.05, 0.02, 0.20, 1.0
do = lambda S, sv: down_out(S, K, B, r, q, sv, T)
def do_grid(sv):
    return grid(B, 400.0, 800, 500, lambda x: max(x - K, 0.0),
                lambda t: (0.0, 400.0 * exp(-q * t) - K * exp(-r * t)), r, q, sv, T)
g0, gu, gd = do_grid(s), do_grid(s + 0.005), do_grid(s - 0.005)
out = lambda f, w: print(f"{f:<38}" + "".join(f"{v:>13.6f}" for v in w))
out("price at 100: DO, DO grid, vanilla", [do(100.0, s), g0(100.0)[0], call(100.0, K, r, q, s, T)])
out("a, B^2/S, (B/S)^a, C(64), mirror", [2 * (r - q) / s ** 2 - 1, B * B / 100.0, (B / 100.0) ** 0.5, call(B * B / 100.0, K, r, q, s, T),
    (B / 100.0) ** 0.5 * call(B * B / 100.0, K, r, q, s, T)])
print("house down-and-out call, B = 80    formula      bump      grid")
res = {}
for Sv in (100.0, 90.0, 82.0):
    an, bu = down_out_greeks(Sv, K, B, r, q, s, T), bump(do, Sv, s)
    gv = (gu(Sv)[0] - gd(Sv)[0]) / 0.01
    res[Sv] = (an, g0(Sv)[1:] + (gv,))
    for k, name in enumerate(("delta", "gamma", "vega")):
        if name != "vega" or Sv != 90.0:
            out(f"{name} at {Sv:.0f}", [an[k], bu[k], res[Sv][1][k]])
print("vanilla call, same market             delta        gamma         vega")
for Sv in (100.0, 90.0, 82.0): out(f"vanilla at {Sv:.0f}", vanilla_greeks(Sv, K, r, q, s, T))
wall = down_out_greeks(B, K, B, r, q, s, T)
out("at the wall: delta, gamma, vega", wall)
out("price at 82, at 80.1", [do(82.0, s), do(80.1, s)])
out("shares per $ of premium at 82, 80.1", [res[82.0][0][0] / do(82.0, s),
    down_out_greeks(80.1, K, B, r, q, s, T)[0] / do(80.1, s)])
out("wall: C(80), 2 Delta(80), a C(80)/B", [call(B, K, r, q, s, T), 2 * vanilla_greeks(B, K, r, q, s, T)[0], 0.5 * call(B, K, r, q, s, T) / B])
print("reverse knock-out: up-and-out call, H = 120"); uo = lambda S, sv, t=T, h=H: up_out(S, K, h, r, q, sv, t)
for t, lab in ((1.0, "1 year"), (0.25, "3 months"), (1 / 12, "1 month"), (1 / 52, "1 week")):
    out(f"UO delta at 119.9, {lab}", [bump(lambda S, sv: uo(S, sv, t), 119.9, s)[0]])
m1 = lambda S, sv: uo(S, sv, 1 / 12)
out("UO 1 month: price 100, 115", [m1(100.0, s), m1(115.0, s)])
out("UO 1 month: vega at 100, 115", [bump(m1, 100.0, s)[2], bump(m1, 115.0, s)[2]])
ug = [grid(0.0, H, 480, 500, lambda x: max(x - K, 0.0) if x < H else 0.0,
           lambda t: (0.0, 0.0), r, q, sv, 1 / 12) for sv in (s, s + 0.005, s - 0.005)]
out("UO grid: price 115, delta 115", ug[0](115.0)[:2])
out("UO grid: vega at 100, 115", [(ug[1](x)[0] - ug[2](x)[0]) / 0.01 for x in (100.0, 115.0)])
out("UO 1 year: vega at 80, 100", [bump(uo, 80.0, s)[2], bump(uo, 100.0, s)[2]])
print("barrier shift, 1 month: price with H = 120 and 122")
out("UO price at 100, shifted at 100", [m1(100.0, s), uo(100.0, s, 1 / 12, 122.0)])
out("shifted option worth at 120", [uo(120.0, s, 1 / 12, 122.0)])
sh = bump(lambda S, sv: uo(S, sv, 1 / 12, 122.0), 120.0, s)[0]
out("shifted delta at 120, slippage covered", [sh, -uo(120.0, s, 1 / 12, 122.0) / sh])
print("static replication when r = q = 0.02: put strike B^2/K = 64, ratio K/B = 1.25"); rq = 0.02
out("formula, replication at 100", [down_out(100.0, K, B, rq, rq, s, T),
    call(100.0, K, rq, rq, s, T) - K / B * put(100.0, B * B / K, rq, rq, s, T)])
out("at the wall: call, 1.25 puts", [call(B, K, rq, rq, s, T), K / B * put(B, B * B / K, rq, rq, s, T)])
print("what breaks")
out("vega with a held fixed, at 100", [vanilla_greeks(100.0, K, r, q, s, T)[2]
    - (B / 100.0) ** 0.5 * vanilla_greeks(B * B / 100.0, K, r, q, s, T)[2]])
out("bump h = 5 across the wall, at 82", [bump(do, 82.0, s, h=5.0)[0]])
out("try: DO delta at wall, T = 0.25", [down_out_greeks(B, K, B, r, q, s, 0.25)[0]])
print("chart, S        " + "".join(f"{x:>7.0f}" for x in (80, 82, 85, 90, 95, 100, 110, 120)))
print("chart, DO x100  " + "".join(f"{100 * down_out_greeks(x, K, B, r, q, s, T)[0]:>7.2f}" for x in (80, 82, 85, 90, 95, 100, 110, 120)))
print("chart, van x100 " + "".join(f"{100 * vanilla_greeks(x, K, r, q, s, T)[0]:>7.2f}" for x in (80, 82, 85, 90, 95, 100, 110, 120)))

assert abs(do(100.0, s) - 9.133306) < 1e-6, "house down-and-out price"
for Sv in (100.0, 90.0, 82.0):
    assert abs(res[Sv][0][0] - res[Sv][1][0]) < 1e-3, "analytic delta vs grid"
    assert abs(res[Sv][0][1] - res[Sv][1][1]) < 1e-4, "analytic gamma vs grid"
    assert abs(res[Sv][0][2] - res[Sv][1][2]) < 0.05, "analytic vega vs grid"
Dw = 2 * vanilla_greeks(B, K, r, q, s, T)[0] + (2 * (r - q) / s ** 2 - 1) * call(B, K, r, q, s, T) / B
assert abs(wall[0] - Dw) < 1e-9, "wall delta = 2 Delta(B) + a C(B)/B"
assert abs(wall[1] + 2 * (r - q) / s ** 2 / B * Dw) < 1e-9, "wall gamma = -(1 + a)/B times wall delta"
assert res[82.0][1][1] < 0, "grid gamma negative at 82"
assert res[100.0][1][1] > 0, "grid gamma positive at 100"
assert abs(m1(115.0, s) - ug[0](115.0)[0]) < 5e-3, "up-and-out formula vs grid"
assert ug[1](115.0)[0] - ug[2](115.0)[0] < 0, "grid vega negative at 115"
assert ug[1](100.0)[0] - ug[2](100.0)[0] > 0, "grid vega positive at 100"
assert abs(call(B, K, rq, rq, s, T) - K / B * put(B, B * B / K, rq, rq, s, T)) < 1e-9, "replication at the wall"
print("ALL CHECKS PASS")
