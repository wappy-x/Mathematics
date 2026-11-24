# Cheyette (quasi-Gaussian) check: x and y carry the whole forward curve.  Standard library only; nothing imported
# knows an answer.  Roads: (1) Hull-White's closed-form bond call; (2) a 2-D (x, y) grid stepped back from expiry;
# (3) Monte Carlo of x and y; (4) the bond formula against Hull-White's, and y's equation by RK4 against its closed form.
from math import exp, log, sqrt, cos, pi

DEPOSITS = ((0.5, 0.0400), (1.0, 0.0420))            # the Hull-White card's six quotes
SWAPS = ((2, 0.0440), (3, 0.0455), (4, 0.0462), (5, 0.0465))
KAP, S0, SKEW = 0.03, 0.01, 0.2       # pull speed, base volatility, slope of vol in x
TE, TM, STRIKES = 1.0, 5.0, (0.79, 0.81, 0.83, 0.85, 0.87)   # option expiry, bond maturity, strikes

D = {0.0: 1.0}                        # the bootstrap ladder
for T, r in DEPOSITS: D[T] = 1.0 / (1.0 + T * r)
for n, S in SWAPS: D[float(n)] = (1.0 - S * sum(D[float(j)] for j in range(1, n))) / (1.0 + S)
PIL = sorted(D); FW = [log(D[PIL[i]] / D[PIL[i + 1]]) / (PIL[i + 1] - PIL[i]) for i in range(6)]
def f0(t): return FW[min(sum(1 for p in PIL[1:] if t >= p), 5)]
def G(t, T, k=KAP): return (1.0 - exp(-k * (T - t))) / k
def ybar(t): return S0 * S0 * (1.0 - exp(-2.0 * KAP * t)) / (2.0 * KAP)   # y when b = 0
def recon(t, T, x, y):                # P(t,T) = D(T)/D(t) exp(-G x - G^2 y / 2)
    g = G(t, T); return D[T] / D[t] * exp(-g * x - 0.5 * g * g * y)
def hw(t, T, r):                      # the Hull-White card's A, B formula with a = kappa
    B = G(t, T)
    return D[T] / D[t] * exp(B * f0(t) - S0 * S0 / (4 * KAP) * (1 - exp(-2 * KAP * t)) * B * B - B * r)
def vol(x, b): return max(S0 + b * x, 0.001)  # local volatility, floored at 0.1 percent

def ncdf(z, n=2000):                  # bell-curve area by Simpson's rule
    a = abs(z); h = a / n; g = lambda u: exp(-u * u / 2) / sqrt(2 * pi)
    s = h / 3 * (g(0.0) + g(a) + sum((4 if k % 2 else 2) * g(k * h) for k in range(1, n)))
    return 0.5 + s if z > 0 else 0.5 - s
def zbc(K, sig, k=KAP):               # road 1: Hull-White call on the zero, expiry TE
    sp = sig * sqrt((1 - exp(-2 * k * TE)) / (2 * k)) * G(TE, TM, k)
    h = log(D[TM] / (D[TE] * K)) / sp + sp / 2
    return D[TM] * ncdf(h) - K * D[TE] * ncdf(h - sp), sp, h
def implied(K, p):                    # Hull-White sigma that reproduces a price, by bisection
    lo, hi = 0.001, 0.05
    for _ in range(50): mid = 0.5 * (lo + hi); lo, hi = (mid, hi) if zbc(K, mid)[0] < p else (lo, mid)
    return 0.5 * (lo + hi)

NX, NY, NT, XM, YM = 161, 41, 160, 0.06, 3e-4       # the grid: x from -6% to 6%, y to 3e-4
XS = [-XM + 2 * XM * i / (NX - 1) for i in range(NX)]; DX = XS[1] - XS[0]
YS = [YM * j / (NY - 1) for j in range(NY)]; DY = YS[1]
def grid(payoffs, b, by=None, ex=None):   # road 2: step V(t, x, y) back from TE to 0; y carried at vol(x, by)
    dt, by = TE / NT, b if by is None else by
    Vs = [[[p(x, y) for y in YS] for x in XS] for p in payoffs]
    for n in range(NT - 1, -1, -1):
        rf = f0(n * dt); th = 1.0 if n >= NT - 4 else 0.5; c = (1 - th) * dt   # 4 implicit steps, then Crank-Nicolson
        for V in Vs:
            W = [[0.0] * NY for _ in range(NX)]          # 1: carry y along dy = (s^2 - 2 k y) dt
            for i, x in enumerate(XS):
                s2 = vol(x, by) * vol(x, by)
                for j, y in enumerate(YS):
                    q = min(y + (s2 - 2 * KAP * y) * dt, YM) / DY; m = min(int(q), NY - 2)
                    W[i][j] = V[i][m] + (q - m) * (V[i][m + 1] - V[i][m])
            for j, y in enumerate(YS):                   # 2: theta-scheme in x, row by row
                L = []
                for i, x in enumerate(XS):
                    mu = y - KAP * x; d = 0.5 * vol(x, b) * vol(x, b) / (DX * DX)
                    if i == 0: L.append((0.0, -(rf + x) - mu / DX, mu / DX))
                    elif i == NX - 1: L.append((-mu / DX, -(rf + x) + mu / DX, 0.0))
                    else: L.append((d - mu / (2 * DX), -2 * d - rf - x, d + mu / (2 * DX)))
                rh = [W[i][j] + c * ((L[i][0] * W[i - 1][j] if i > 0 else 0.0) + L[i][1] * W[i][j]
                      + (L[i][2] * W[i + 1][j] if i < NX - 1 else 0.0)) for i in range(NX)]
                lo, di, up = [-th * dt * l[0] for l in L], [1 - th * dt * l[1] for l in L], [-th * dt * l[2] for l in L]
                for i in range(1, NX):                   # Thomas algorithm
                    w = lo[i] / di[i - 1]; di[i] -= w * up[i - 1]; rh[i] -= w * rh[i - 1]
                V[NX - 1][j] = rh[NX - 1] / di[NX - 1]
                for i in range(NX - 2, -1, -1): V[i][j] = (rh[i] - up[i] * V[i + 1][j]) / di[i]
        if ex and n == NT // 2: Vs[-1] = [[max(v, ex(x, y)) for v, y in zip(r, YS)] for r, x in zip(Vs[-1], XS)]   # Bermudan
    return [V[NX // 2][0] for V in Vs]

state = 20261123                                    # 64-bit LCG, then Box-Muller
def unif():
    global state; state = (state * 6364136223846793005 + 1442695040888963407) % 2**64
    return ((state >> 11) + 0.5) / 2**53
def gauss(): u1 = unif(); u2 = unif(); return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2)
def monte_carlo(b, pairs=10000, steps=100):         # road 3: Euler steps of x and y, from the same seed each call
    global state; state = 20261123; dt = TE / steps; acc = [[0.0, 0.0] for _ in range(len(STRIKES) + 3)]
    for _ in range(pairs):
        zs = [gauss() for _ in range(steps)]; vals = []
        for sgn in (1.0, -1.0):
            x = y = ix = 0.0
            for z in zs:
                s = vol(x, b); nx = x + (y - KAP * x) * dt + s * sqrt(dt) * sgn * z
                y += (s * s - 2 * KAP * y) * dt; ix += 0.5 * dt * (x + nx); x = nx
            disc = D[TE] * exp(-ix); p = recon(TE, TM, x, y)
            vals.append([disc * max(p - K, 0.0) for K in STRIKES] + [disc * p, disc, y])
        for k in range(len(acc)):
            v = 0.5 * (vals[0][k] + vals[1][k]); acc[k][0] += v; acc[k][1] += v * v
    return [(s / pairs, sqrt(max(q / pairs - (s / pairs) * (s / pairs), 0.0) / pairs)) for s, q in acc]

y, h, fy = 0.0, 0.001, lambda y: S0 * S0 - 2 * KAP * y   # road 4a: dy/dt = s^2 - 2 k y by RK4
for _ in range(1000):
    k1 = fy(y); k2 = fy(y + h / 2 * k1); k3 = fy(y + h / 2 * k2); y += h / 6 * (k1 + 2 * k2 + 2 * k3 + fy(y + h * k3))
g15 = G(TE, TM); fwd = D[TM] / D[TE]
print(f"curve: D(1) {D[1.0]:.8f}  D(5) {D[5.0]:.8f}  forward bond D(5)/D(1) {fwd:.6f}")
print(f"kappa {KAP}  G(1,5) {g15:.6f}  y(1) closed {ybar(1.0):.10f}  RK4 {y:.10f}")
assert abs(y - ybar(1.0)) < 1e-13
print("t=1 bond to 5 y: x %, short rate %, Cheyette P(1,5), Hull-White P(1,5)")
for x in (-0.02, 0.0, 0.02):                         # road 4b: same prices, two formulas
    pc, ph = recon(TE, TM, x, ybar(TE)), hw(TE, TM, f0(TE) + x)
    print(f"  {100 * x:+.1f}  {100 * (f0(TE) + x):.4f}  {pc:.8f}  {ph:.8f}")
    assert abs(pc - ph) < 1e-12
c83, sp, hh = zbc(0.83, S0)
print(f"by hand, K 0.83: sigma_p {sp:.6f}  h {hh:.6f}  N(h) {ncdf(hh):.6f}  N(h-sp) {ncdf(hh - sp):.6f}  call {c83:.6f}")
print("local vol % at x = -2, -1, 0, 1, 2 %: " + " ".join(f"{100 * vol(x, SKEW):.2f}" for x in (-0.02, -0.01, 0.0, 0.01, 0.02)))
pays = [lambda x, y, K=K: max(recon(TE, TM, x, y) - K, 0.0) for K in STRIKES]
pays += [lambda x, y: recon(TE, TM, x, y)]; put = lambda t: lambda x, y: max(0.83 - recon(t, TM, x, y), 0.0)
g0, g1, o1 = grid(pays, 0.0), grid(pays, SKEW), grid(pays, SKEW, by=0.0)   # o1: one state, y kept on ybar(t)
mc, mc0 = monte_carlo(SKEW), monte_carlo(0.0)
print("strike: HW closed, grid b=0, implied % | grid b=0.2, MC b=0.2 (se), implied %")
iv0, iv1 = [], []
for k, K in enumerate(STRIKES):
    cf = zbc(K, S0)[0]; iv0.append(implied(K, g0[k])); iv1.append(implied(K, g1[k]))
    print(f"  {K:.2f}  {cf:.6f}  {g0[k]:.6f}  {100 * iv0[k]:.4f} | {g1[k]:.6f}  {mc[k][0]:.6f} ({mc[k][1]:.6f})  {100 * iv1[k]:.4f}")
    assert abs(g0[k] - cf) < 3e-6 and abs(iv0[k] - S0) < 2e-5
    assert abs(g1[k] - mc[k][0]) < 4 * mc[k][1]
assert iv1[0] > iv1[2] > iv1[4] and iv1[0] - iv1[4] > 0.002; nb = len(STRIKES)
print(f"5-y zero through the grid: b=0 {g0[nb]:.8f}  b=0.2 {g1[nb]:.8f}  market {D[5.0]:.8f}")
assert abs(g0[nb] - D[5.0]) < 3e-6 and abs(g1[nb] - D[5.0]) < 3e-6
print(f"MC b=0.2: D(1) {mc[nb + 1][0]:.6f} ({mc[nb + 1][1]:.6f})  D(5) {mc[nb][0]:.6f} ({mc[nb][1]:.6f})"
      f"  mean y(1) {mc[nb + 2][0]:.10f}")
print(f"MC b=0, same draws: D(1) {mc0[nb + 1][0]:.8f} ({mc0[nb + 1][1]:.8f})  D(5) {mc0[nb][0]:.8f} ({mc0[nb][1]:.8f})"
      f"  call 0.83 {mc0[2][0]:.6f} ({mc0[2][1]:.6f})")
for m in (mc, mc0): assert abs(m[nb + 1][0] - D[1.0]) < 4 * m[nb + 1][1] and abs(m[nb][0] - D[5.0]) < 4 * m[nb][1]
assert all(abs(mc0[k][0] - zbc(K, S0)[0]) < 4 * mc0[k][1] for k, K in enumerate(STRIKES))
eu, bm = grid([put(TE), put(TE)], SKEW, ex=put(0.5))       # put on the 5-y zero; the second may also be exercised at 0.5 y
print(f"put K 0.83, b=0.2: European {eu:.6f}  (parity {g1[2] - g1[nb] + 0.83 * D[TE]:.6f})  Bermudan, also at 0.5 y {bm:.6f}")
assert abs(eu - (g1[2] - g1[nb] + 0.83 * D[TE])) < 3e-6 and bm > eu + 1e-3
print("one state, y held at ybar(t), minus two states, on 10,000,000 face: 5-y zero " + " ".join(
      f"{1e7 * (o1[k] - g1[k]):.2f}" for k in (nb, 0, 2, 4)) + "  (calls 0.79, 0.83, 0.87)")
assert abs(o1[nb] - g1[nb]) > 2e-6
i5 = sum(G(TE * (k + 0.5) / 1000, TM) ** 2 for k in range(1000)) * TE / 1000     # integral of G(s,5)^2 over [0, TE]
nod, noc = D[TM] * exp(0.5 * S0 * S0 * i5 - 0.5 * g15 * g15 * ybar(TE)), D[TM] * exp(0.5 * g15 * g15 * ybar(TE))
print("what breaks, on 10,000,000 face (b=0, closed form):")
print(f"  drop y from x's drift: 5-y zero {nod:.8f}, error {1e7 * (nod - D[5.0]):.2f}")
print(f"  drop the G^2 y / 2 term: 5-y zero {noc:.8f}, error {1e7 * (noc - D[5.0]):.2f}")
c3 = zbc(0.83, S0, 0.3)[0]; print(f"  kappa 0.3 not 0.03, K 0.83: call {c3:.6f}, error {1e7 * (c3 - c83):.2f}")
print(f"  flat Hull-White on the skewed market, K 0.87: {zbc(0.87, S0)[0]:.6f} vs {g1[4]:.6f}, error {1e7 * (zbc(0.87, S0)[0] - g1[4]):.2f}")
assert abs(nod - D[5.0]) > 1e-4 and abs(c3 - c83) > 1e-3
print("chart, implied %: b=0 " + " ".join(f"{100 * v:.2f}" for v in iv0) + " | b=0.2 " + " ".join(f"{100 * v:.2f}" for v in iv1))
print("ALL CHECKS PASS")
