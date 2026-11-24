# Convertible risk -- the check behind the card.  Standard library only; nothing
# imported knows a convertible.  The bond: five years, face 100, 2% coupon paid
# yearly, convertible at any time into one Acme share.  Acme: 100 today, riskless
# rate 5%, dividend yield 2%.  The tree splits value Tsiveriotis-Fernandes style:
# the equity part is discounted at the riskless rate, the cash part at riskless
# plus the credit spread.  Converting forfeits the coupon due.  255 steps.
import math

R, Q, T, FACE, CPN, M, QUOTE = 0.05, 0.02, 5.0, 100.0, 2.0, 255, 108.0
CB04 = 103.8592                               # Convertible bonds: 1000 steps, exact last step

def cb(sig, spr, s0=100.0, m=M, ratio=1.0, split=True, smooth=True):
    """Price, equity part, cash part, d(price)/d(spread) and the first two rows."""
    dt = T / m; u = math.exp(sig * math.sqrt(dt)); d = 1.0 / u
    p = (math.exp((R - Q) * dt) - d) / (u - d)
    dr = math.exp(-R * dt) if split else math.exp(-(R + spr) * dt)
    dk = math.exp(-(R + spr) * dt); per = round(m / T)
    h, K = sig * math.sqrt(dt), FACE + CPN
    E, B, G = [], [], []                      # G = slope of the cash part in the spread
    for j in range(m + 1):
        s = s0 * u ** j * d ** (m - j)
        x0 = math.log(K / (ratio * s)) if ratio > 0 else h      # maturity: max(share, 102)
        if smooth and abs(x0) < h:                              # a cell across 102: average it
            e0, b0 = ratio * s * (math.exp(h) - math.exp(x0)) / (2 * h), K * (x0 + h) / (2 * h)
        else: e0, b0 = (ratio * s, 0.0) if x0 < 0 else (0.0, K)
        E.append(e0); B.append(b0); G.append(0.0)
    rows = {}
    for n in range(m - 1, -1, -1):
        cp = CPN if n % per == 0 and n > 0 else 0.0
        for j in range(n + 1):
            s = s0 * u ** j * d ** (n - j)
            e = dr * (p * E[j + 1] + (1 - p) * E[j])
            g = dk * (p * G[j + 1] + (1 - p) * G[j])
            b = dk * (p * B[j + 1] + (1 - p) * B[j])
            g -= dt * b                        # product rule on dk * (...)
            if not split: g -= dt * e
            b += cp                            # converting forfeits the coupon due
            if ratio * s > e + b: e, b, g = ratio * s, 0.0, 0.0
            E[j], B[j], G[j] = e, b, g
        if n <= 2: rows[n] = [(s0 * u ** j * d ** (n - j), E[j] + B[j]) for j in range(n + 1)]
    return E[0] + B[0], E[0], B[0], G[0], rows

def bisect(f, lo, hi, tol=1e-9):
    flo, k = f(lo), 1                         # k counts every tree priced
    while hi - lo > tol:
        mid = 0.5 * (lo + hi); fm = f(mid); k += 1
        if (fm > 0) == (flo > 0): lo, flo = mid, fm
        else: hi = mid
    return 0.5 * (lo + hi), k

def secant(f, a, b, tol=1e-12):
    fa, fb, k = f(a), f(b), 2
    while abs(b - a) > tol:
        a, b, fa = b, b - fb * (b - a) / (fb - fa), fb; fb = f(b); k += 1
    return b, k

print("convertible: 5 years, face 100, coupon 2, one share; Acme 100, r 5%, q 2%; tree", M, "steps")
floor = sum(CPN * math.exp(-(R + 0.03) * t) for t in range(1, 6)) + FACE * math.exp(-(R + 0.03) * T)
tf = cb(0.20, 0.03, ratio=0.0)[0]
print(f"bond floor at 3% spread: closed form {floor:.6f}  tree with no conversion {tf:.6f}")
assert abs(floor - tf) < 1e-9
p20, e20, b20, _, _ = cb(0.20, 0.03)
print(f"model price at vol 20%, spread 3%: {p20:.4f} (equity part {e20:.4f}, cash part {b20:.4f}); quote {QUOTE:.2f}")
p1005 = cb(0.20, 0.03, m=1005)[0]
print(f"same price on 1005 steps: {p1005:.4f}; on the 1000-step tree of Convertible bonds: {CB04:.4f}")
assert abs(p20 - p1005) < 0.01 and p20 > max(floor, 100.0)
assert abs(p20 - CB04) < 0.01                 # another tree, another smoothing, the same model

print("price against volatility, spread 3%:", " ".join(f"{v}%:{cb(v / 100, 0.03)[0]:.2f}" for v in (10, 20, 30, 40)))
print("price against spread, vol 20%:     ", " ".join(f"{s}%:{cb(0.20, s / 100)[0]:.2f}" for s in (0, 2, 4, 6)))
fv = lambda v: cb(v, 0.03)[0] - QUOTE
iv, kb = bisect(fv, 0.05, 0.60); iv2, ks = secant(fv, 0.20, 0.30)
print(f"implied vol at 3% spread: bisection {100 * iv:.4f}% in {kb} trees, secant {100 * iv2:.4f}% in {ks} trees")
fs = lambda s: cb(0.20, s)[0] - QUOTE
isp, kb = bisect(fs, -0.01, 0.10); isp2, ks = secant(fs, 0.03, 0.02)
print(f"implied spread at 20% vol: bisection {1e4 * isp:.2f} bp in {kb} trees, secant {1e4 * isp2:.2f} bp in {ks} trees")
assert abs(iv - iv2) < 1e-7 and abs(isp - isp2) < 1e-7
assert abs(cb(iv, 0.03)[0] - QUOTE) < 1e-6 and abs(cb(0.20, isp)[0] - QUOTE) < 1e-6
pairs = [(s, bisect(lambda v: cb(v, s / 100)[0] - QUOTE, 0.05, 0.60, 1e-6)[0]) for s in (1, 2, 3, 4, 5, 6)]
print("chart, spread and the vol that reprices 108:", " ".join(f"{s}%:{100 * v:.2f}" for s, v in pairs))
assert all(a[1] < b[1] for a, b in zip(pairs, pairs[1:]))

V, E0, B0, G0, rows = cb(iv, 0.03)
print(f"at the implied vol: price {V:.4f} = equity part {E0:.4f} + cash part {B0:.4f}")
uu = math.exp(iv * math.sqrt(T / M)); pp = (math.exp((R - Q) * T / M) - 1 / uu) / (uu - 1 / uu)
print(f"tree factors: up u {uu:.6f}  down d {1 / uu:.6f}  up weight p {pp:.6f}")
(s10, v10), (s11, v11) = rows[1]; (s20, v20), (s21, v21), (s22, v22) = rows[2]
print(f"one step in:  Acme {s10:.4f} {s11:.4f}  bond {v10:.4f} {v11:.4f}")
print(f"two steps in: Acme {s20:.4f} {s21:.4f} {s22:.4f}  bond {v20:.4f} {v21:.4f} {v22:.4f}")
delta = (v11 - v10) / (s11 - s10)
hp, hm = s22 - s21, s21 - s20
gamma = 2 * ((v22 - v21) / hp - (v21 - v20) / hm) / (hp + hm)
u2 = math.exp(2 * iv * math.sqrt(T / M))          # two lattice steps: the kink stays put
a, b, c = cb(iv, 0.03, 100 * u2)[0], V, cb(iv, 0.03, 100 / u2)[0]
kp, km = 100 * u2 - 100, 100 - 100 / u2
tdelta = (km * km * (a - b) + kp * kp * (b - c)) / (kp * km * (kp + km))
tgamma = 2 * ((a - b) / kp - (b - c) / km) / (kp + km)
print(f"three trees from Acme {100 / u2:.4f}, 100, {100 * u2:.4f}: prices {c:.4f} {b:.4f} {a:.4f}")
print(f"delta: nodes {delta:.4f}  three trees {tdelta:.4f};  gamma: nodes {gamma:.6f}  three trees {tgamma:.6f}")
assert abs(delta - tdelta) < 0.002 and abs(gamma / tgamma - 1) < 0.02
vega = (cb(iv + 0.01, 0.03)[0] - cb(iv - 0.01, 0.03)[0]) / 2
cs01, cs1 = 5 * (cb(iv, 0.03001)[0] - cb(iv, 0.02999)[0]), (cb(iv, 0.0301)[0] - cb(iv, 0.0299)[0]) / 2
cs10 = (cb(iv, 0.031)[0] - cb(iv, 0.029)[0]) / 20   # reprice 10 bp either side: the line moves too
print(f"vega per vol point {vega:.4f};  credit per +1 bp: bump 10 bp {cs10:.6f}  bump 1 bp {cs1:.6f}  bump 0.1 bp {cs01:.6f}")
g1005, c1005 = cb(iv, 0.03, m=1005)[3] * 1e-4, (cb(iv, 0.031, m=1005)[0] - cb(iv, 0.029, m=1005)[0]) / 20
print(f"  slope with the conversion line held {G0 * 1e-4:.6f};  on 1005 steps {g1005:.6f}, bump 10 bp {c1005:.6f}")
assert G0 * 1e-4 < cs10 < 0.97 * G0 * 1e-4 and g1005 < c1005 < 0.97 * g1005   # held line: too steep, < 3%
print(f"cash part's spread duration: {-cs10 / (B0 * 1e-4):.4f} years ({-G0 / B0:.4f} with the line held)")

N = 100_000
short = round(N * delta)
print(f"hedge: buy {N} bonds (face 10,000,000, cost {N * V:,.0f}), short {short} shares")
for k in (-3, -2, -1, 1, 2, 3):                  # moves onto the tree's own price levels
    s = 100 * u2 ** k
    full = N * (cb(iv, 0.03, s)[0] - V) - short * (s - 100)
    taylor = N * (0.5 * tgamma * (s - 100) ** 2) + (N * tdelta - short) * (s - 100)
    print(f"  Acme jumps to {s:6.2f} (move {s - 100:+6.2f}): hedged P&L full {full:9,.0f}   delta-gamma estimate {taylor:9,.0f}")
    assert full > 0 and abs(full - taylor) < 0.25 * taylor
wide = N * (cb(iv, 0.04)[0] - V)
print(f"  spread widens 100 bp, Acme still: hedged P&L {wide:,.0f}")

print("chart, Acme price:   ", " ".join(f"{s:6d}" for s in range(60, 161, 20)))
curve = [cb(iv, 0.03, s) for s in range(60, 161, 20)]
print("chart, bond price:   ", " ".join(f"{c[0]:6.2f}" for c in curve))
dl = [(r[1][1][1] - r[1][0][1]) / (r[1][1][0] - r[1][0][0]) for *_, r in curve]
print("chart, node delta:   ", " ".join(f"{x:6.3f}" for x in dl))
assert all(a < b for a, b in zip(dl, dl[1:])) and all(c[0] >= max(floor, s) for c, s in zip(curve, range(60, 161, 20)))

print("what breaks")
bump = (cb(iv, 0.03, 101)[0] - cb(iv, 0.03, 99)[0]) / 2
print(f"  delta from a plain bump of 1 dollar     {bump:.4f}")
rough = [cb(iv, 0.03, x, smooth=False)[0] for x in (101, 100, 99)]
print(f"  last step not smoothed: price {rough[1]:.4f}, 1-dollar bump delta {(rough[0] - rough[2]) / 2:.4f}")
print(f"  implied vol solved at zero spread       {100 * bisect(lambda v: cb(v, 0.0)[0] - QUOTE, 0.05, 0.6)[0]:.4f}%")
print(f"  gamma with the two gaps taken as equal  {((v22 - v21) - (v21 - v20)) / ((hp + hm) / 2) ** 2:.5f}")
print(f"  hedge one share per bond, Acme to {100 * u2:.2f} {N * (a - V) - N * (100 * u2 - 100):,.0f}")
nos = cb(iv, 0.03, split=False)
print(f"  whole bond at the risky rate: price {nos[0]:.4f}, credit per bp {nos[3] * 1e-4:.6f}")
print("ALL CHECKS PASS")
