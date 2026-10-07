# Double no-touch and double knock-out call -- the check behind the card.  Standard library only.
# Roads: (1) the image series, (2) the sine-wave series, (3) a Crank-Nicolson grid,
# (4) a bridge-corrected simulation with its own random numbers.  N(x) is a written-out series.
from math import log, sqrt, exp, sin, cos, pi

def N(x):                                            # bell-curve area left of x (Marsaglia's series)
    if x < -8.0: return 0.0
    if x > 8.0: return 1.0
    term, tot, k = x, x, 0
    while abs(term) > 1e-17 * abs(tot):
        k += 1; term *= x * x / (2 * k + 1); tot += term
    return 0.5 + tot * exp(-0.5 * x * x) / sqrt(2.0 * pi)
S, rd, rf, sig, T, L, U, K = 1.10, 0.05, 0.03, 0.10, 1.0, 1.05, 1.20, 1.10
def images(S, T, L, U, lo, hi, jmax, sig=sig, rd=rd, rf=rf):
    """Road 1. Returns (cash leg, asset leg): discounted values of 1 USD and of 1 EUR paid
    if the path never leaves (L, U) and log(S_T/S) ends in (lo, hi); images up to jmax reflections."""
    nu, s2 = rd - rf - 0.5 * sig * sig, sig * sig * T
    a, b = log(L / S), log(U / S); w = b - a
    out = [0.0, 0.0]
    for j in range(jmax + 1):
        if j == 0: imgs = [(0.0, 1.0)]
        elif j % 2: imgs = [(2 * b + (j - 1) * w, -1.0), (2 * a - (j - 1) * w, -1.0)]
        else: imgs = [(j * w, 1.0), (-j * w, 1.0)]
        for c, sg in imgs:
            for e in (0, 1):                         # e = 1 weights each outcome by S_T / S
                al = nu / (sig * sig) + e
                m = c + al * s2
                out[e] += sg * exp(al * c + 0.5 * al * al * s2) * (N((hi - m) / sqrt(s2)) - N((lo - m) / sqrt(s2)))
    f = exp(-rd * T - nu * nu * T / (2 * sig * sig))
    return f * out[0], f * S * out[1]
def dnt(S, T=T, L=L, U=U, jmax=8, sig=sig):
    if S <= L or S >= U: return 0.0
    return images(S, T, L, U, log(L / S), log(U / S), jmax, sig)[0]
def dko(S, T=T, L=L, U=U, jmax=8, sig=sig):
    if S <= L or S >= U: return 0.0
    cash, asset = images(S, T, L, U, log(max(K, L) / S), log(U / S), jmax, sig)
    return asset - K * cash

def dnt_sine(S, modes):                              # road 2: heat-equation modes that vanish at both walls
    nu = rd - rf - 0.5 * sig * sig; be = nu / (sig * sig)
    a, w = log(L / S), log(U / L); tot = 0.0
    for k in range(1, modes + 1):
        m = k * pi / w
        tot += (2 / w) * sin(-m * a) * exp(-0.5 * m * m * sig * sig * T) * m * (1 - (-1) ** k * exp(be * w)) / (be * be + m * m)
    return exp(-rd * T - nu * nu * T / (2 * sig * sig) + be * a) * tot

def grid(payoff, J=400, steps=400):                  # road 3: Crank-Nicolson in log-spot, zero at both walls
    a, b = log(L / S), log(U / S); h, dt = (b - a) / J, T / steps
    nu = rd - rf - 0.5 * sig * sig
    V = [0.0] + [payoff(S * exp(a + i * h)) for i in range(1, J)] + [0.0]
    lo, di, up = 0.5 * sig * sig / h ** 2 - nu / (2 * h), -sig * sig / h ** 2 - rd, 0.5 * sig * sig / h ** 2 + nu / (2 * h)
    for th, k in [(1.0, dt / 2)] * 4 + [(0.5, dt)] * (steps - 2):   # 4 implicit half steps calm the jump (Rannacher)
        rhs = [V[i] + (1 - th) * k * (lo * V[i - 1] + di * V[i] + up * V[i + 1]) for i in range(1, J)]
        A, B, C = -th * k * lo, 1 - th * k * di, -th * k * up
        cp, dp = [0.0] * (J - 1), [0.0] * (J - 1)    # Thomas algorithm for the tridiagonal solve
        for i in range(J - 1):
            den = B - A * (cp[i - 1] if i else 0.0)
            cp[i] = C / den; dp[i] = (rhs[i] - A * (dp[i - 1] if i else 0.0)) / den
        for i in range(J - 2, -1, -1):
            V[i + 1] = dp[i] - (cp[i] * V[i + 2] if i < J - 2 else 0.0)
    i = int(-a / h); t = -a / h - i                  # quadratic interpolation at log-spot 0, today's spot
    return V[i] * (t - 1) * (t - 2) / 2 - V[i + 1] * t * (t - 2) + V[i + 2] * t * (t - 1) / 2

def simulate(paths=400000, steps=52, seed=2026):     # road 4: weekly steps, Brownian-bridge survival between them
    nu, dt = rd - rf - 0.5 * sig * sig, T / steps
    a, b, v = log(L / S), log(U / S), sig * sig * dt
    st, tot = seed, [0.0] * 5                         # sums: bridge weight, its square, call, call^2, nodes-only
    for p in range(paths):
        x, wt, raw = 0.0, 1.0, 1.0
        for i in range(steps):
            st = (st * 6364136223846793005 + 1442695040888963407) % 2 ** 64; u1 = ((st >> 11) + 0.5) / 2 ** 53
            st = (st * 6364136223846793005 + 1442695040888963407) % 2 ** 64; u2 = ((st >> 11) + 0.5) / 2 ** 53
            y = x + nu * dt + sqrt(v) * sqrt(-2 * log(u1)) * cos(2 * pi * u2)
            if y <= a or y >= b: wt = raw = 0.0; break
            wt *= max(0.0, 1 - exp(-2 * (b - x) * (b - y) / v) - exp(-2 * (x - a) * (y - a) / v))
            x = y
        c = wt * max(S * exp(x) - K, 0.0)
        for j, val in enumerate((wt, wt * wt, c, c * c, raw)): tot[j] += val
    D, m = exp(-rd * T), [t / paths for t in tot]
    return D * m[0], D * sqrt((m[1] - m[0] ** 2) / paths), D * m[2], D * sqrt((m[3] - m[2] ** 2) / paths), D * m[4]

def reflect_nt(S, H):                                # single-wall no-touch by reflection, the sibling card's formula
    nu, s, h = rd - rf - 0.5 * sig * sig, sig * sqrt(T), log(H / S)
    sgn = 1.0 if H > S else -1.0
    return exp(-rd * T) * (N(sgn * (h - nu * T) / s) - exp(2 * nu * h / sig ** 2) * N(sgn * (-h - nu * T) / s))
def bs_call(S):
    s = sig * sqrt(T); d1 = (log(S / K) + (rd - rf + 0.5 * sig * sig) * T) / s
    return S * exp(-rf * T) * N(d1) - K * exp(-rd * T) * N(d1 - s)
def reflect_doc(S):                                  # down-and-out call, one wall, by reflection (K above L)
    return bs_call(S) - (L / S) ** (2 * (rd - rf - 0.5 * sig * sig) / sig ** 2) * bs_call(L * L / S)

D, V_dnt, V_dko = exp(-rd * T), dnt(S), dko(S)
nu, s, a, b = rd - rf - 0.5 * sig * sig, sig * sqrt(T), log(L / S), log(U / S)
print(f"inputs: a {a:.6f}  b {b:.6f}  width {b - a:.6f}  2w {2 * (b - a):.6f}  nu {nu:.6f}  sigma*sqrt(T) {s:.6f}  D {D:.6f}")
for c in (0.0, 2 * b, 2 * a):                         # the three nearest images, by hand: D x tilt x bracket
    tilt, br = exp(nu * c / sig ** 2), N((b - c - nu * T) / s) - N((a - c - nu * T) / s)
    print(f"image at {c:+.6f}: tilt {tilt:.6f}  bracket N({(c - a + nu * T) / s:+.6f}) - N({(c - b + nu * T) / s:+.6f}) = {br:.6f}  D x tilt x bracket {D * tilt * br:.6f}")
print("image series, partial sums     reflections  double no-touch  knock-out call")
for j in range(5): print(f"  images with up to {j} reflections {j:>9d} {dnt(S, jmax=j):16.6f} {dko(S, jmax=j):15.6f}")
print("sine series, modes 1 2 3       " + " ".join(f"{dnt_sine(S, m):.10f}" for m in (1, 2, 3)))
mc = simulate()
g_dnt, g_dko = grid(lambda s: 1.0), grid(lambda s: max(s - K, 0.0))
rng_dig = images(S, T, 1e-9, 1e9, log(L / S), log(U / S), 0)[0]
nt_up, nt_dn = reflect_nt(S, U), reflect_nt(S, L)
rows = [("1 image series, 8 reflections  DNT", V_dnt), ("1 image series, 8 reflections  DKO", V_dko),
        ("2 sine series, 3 modes         DNT", dnt_sine(S, 3)),
        ("3 Crank-Nicolson 400 x 400     DNT", g_dnt), ("3 Crank-Nicolson 400 x 400     DKO", g_dko),
        ("4 simulation 400k paths        DNT", mc[0]), ("  its standard error           DNT", mc[1]),
        ("4 simulation 400k paths        DKO", mc[2]), ("  its standard error           DKO", mc[3]),
        ("check: upper wall at 100, DKO", dko(S, U=100.0)), ("  one-wall reflection, DOC", reflect_doc(S)),
        ("check: upper wall at 100, DNT", dnt(S, U=100.0)), ("  one-wall no-touch at 1.05", nt_dn),
        ("check: lower wall at 0.01, DNT", dnt(S, L=0.01)), ("  one-wall no-touch at 1.20", nt_up),
        ("  one-touch at 1.20", D - nt_up), ("vanilla EUR call, K = 1.10", bs_call(S)),
        ("double knock-in = vanilla - DKO", bs_call(S) - V_dko), ("double one-touch = D - DNT", D - V_dnt),
        ("range bet: ends in 1.05-1.20", rng_dig), ("DNT payout / premium", 1.0 / V_dnt),
        ("wrong: NT(1.20) x NT(1.05) / D", nt_up * nt_dn / D), ("wrong: NT(1.20) + NT(1.05) - D", nt_up + nt_dn - D),
        ("wrong: simulation, no bridge", mc[4]),
        ("try: walls 1.00 / 1.25", dnt(S, L=1.00, U=1.25)), ("try: six months", dnt(S, T=0.5)),
        ("try: vol 8%", dnt(S, sig=0.08)), ("try: DKO, vol 8%", dko(S, sig=0.08))]
for name, v in rows: print(f"{name:<36} {v:>12.6f}")
h = 0.01                                             # Greeks by bumping road 1: spot by 0.01, vol by one point, one day
for nm, f in (("DNT", dnt), ("DKO", dko)):
    print(f"greeks {nm}: delta/0.01 {(f(S + h) - f(S - h)) / 2:+.6f}  gamma/0.01 {f(S + h) - 2 * f(S) + f(S - h):+.6f}"
          f"  vega/1pt {(f(S, sig=sig + 0.01) - f(S, sig=sig - 0.01)) / 2:+.6f}  theta/day {f(S, T=T - 1 / 365) - f(S):+.6f}")
spots = [1.05 + 0.01 * i for i in range(16)]
print("chart, spot       " + " ".join(f"{x:6.2f}" for x in spots))
print("chart, DNT 12m    " + " ".join(f"{dnt(x):6.4f}" for x in spots))
print("chart, DNT 3m     " + " ".join(f"{dnt(x, T=0.25):6.2f}" for x in spots))
print("chart, DKO payoff " + " ".join(f"{(max(x - K, 0.0) if L < x < U - 1e-9 else 0.0):6.4f}" for x in spots))

assert abs(V_dnt - dnt_sine(S, 3)) < 1e-10,          "two different series must give one price"
assert abs(V_dnt - g_dnt) < 1e-4,                     "grid within a pip of the series, DNT"
assert abs(V_dko - g_dko) < 1e-4,                     "grid within a pip of the series, DKO"
assert abs(V_dko - mc[2]) < 3 * mc[3],               "simulation within three standard errors, DKO"
assert abs(V_dnt - mc[0]) < 3 * mc[1],                "simulation within three standard errors, DNT"
assert abs(dko(S, U=100.0) - 0.041661) < 5e-7,       "far upper wall: the one-wall house knock-out"
assert abs(dnt(S, U=100.0) - nt_dn) < 1e-9,          "far upper wall: the one-wall no-touch at 1.05"
assert abs(D - dnt(S, L=0.01) - 0.4142) < 5e-5,      "far lower wall: the house one-touch at 1.20"
assert V_dnt < min(nt_up, nt_dn, rng_dig),           "two walls must cost less than any one of them"
print("ALL CHECKS PASS")
