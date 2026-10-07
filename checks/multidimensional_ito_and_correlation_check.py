# Several Brownian motions -- the check behind the card.  Only math is imported.
# Share A: $100, drift 0.08, vol 0.20.  Share B: $50, drift 0.05, vol 0.30.
# Noise correlation RHO = 0.5; time in years.  Cholesky: W2 = RHO Z1 + sqrt(1 - RHO^2) Z2.
# Roads: (A) formulas; (B) an integral against the joint bell curve, no Ito;
# (C) one fine path; (D) 20000 simulated paths; (E) Euler steps of the product.
# Floats are added in plain loops, in the same order as the Rust twin.
import math

A0, MU1, S1, B0, MU2, S2, RHO, T, SEED = 100.0, 0.08, 0.20, 50.0, 0.05, 0.30, 0.5, 1.0, 20260930
MASK = (1 << 64) - 1
state = SEED
C22 = math.sqrt(1.0 - RHO * RHO)               # Cholesky factor: rows (1, 0), (RHO, C22)

def uniform():                                 # SplitMix64, top 53 bits
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0

def normal():                                  # Box-Muller, cosine half only
    u1 = 1.0 - uniform()
    u2 = uniform()
    return math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2)

def prices(t, w1, w2):                         # each share's exact solution (one-dimensional Ito)
    return (A0 * math.exp((MU1 - 0.5 * S1 * S1) * t + S1 * w1),
            B0 * math.exp((MU2 - 0.5 * S2 * S2) * t + S2 * w2))

def mean_se(xs):
    m = 0.0
    for x in xs: m += x
    m /= len(xs)
    v = 0.0
    for x in xs: v += (x - m) * (x - m)
    return m, math.sqrt(v / (len(xs) - 1) / len(xs))

def ncdf(x):                                   # bell-curve area left of x: Simpson from 0 to x
    n, h, s = 2000, x / 2000, 0.0
    for k in range(n + 1):
        s += (1 if k in (0, n) else (4 if k % 2 else 2)) * math.exp(-0.5 * (k * h) * (k * h))
    return 0.5 + s * h / 3.0 / math.sqrt(2.0 * math.pi)

def row(label, v): print(f"{label:<44}{v:>12.6f}")
def row_se(label, m, se): print(f"{label:<44}{m:>12.6f}  se {se:.6f}")

print("A  formulas")
g = MU1 + MU2 + RHO * S1 * S2                  # drift of the product, cross term included
vp = math.sqrt(S1 * S1 + S2 * S2 + 2.0 * RHO * S1 * S2)
ep, ep_ind = A0 * B0 * math.exp(g * T), A0 * B0 * math.exp((MU1 + MU2) * T)
er = A0 / B0 * math.exp((MU1 - MU2 + S2 * S2 - RHO * S1 * S2) * T)   # the ratio A / B
pbelow = ncdf(-(g - 0.5 * vp * vp) * math.sqrt(T) / vp)
row("Cholesky entry under the diagonal", RHO); row("Cholesky diagonal entry sqrt(1 - rho^2)", C22)
row("drift of P = AB, with cross term", g); row("volatility of P", vp)
row("E[P_1], multidimensional Ito", ep); row("E[P_1], cross term dropped = E[A_1]E[B_1]", ep_ind)
row("Cov(A_1, B_1) = difference", ep - ep_ind); row("median P_1", A0 * B0 * math.exp((g - 0.5 * vp * vp) * T))
row("P(P_1 < 5000)", pbelow); row("E[A_1 / B_1], ratio drift 0.09", er)
row("E[W1_1 W2_1]: Ito rho T; ordinary rule 0", RHO * T); row("yearly price correlation Corr(A_1, B_1)", (math.exp(RHO * S1 * S2 * T) - 1) / math.sqrt((math.exp(S1 * S1 * T) - 1) * (math.exp(S2 * S2 * T) - 1)))
vw = RHO * RHO + (1 - RHO) * (1 - RHO)         # wrong mix: weights RHO and 1 - RHO
row("wrong mix rho, 1 - rho: variance of W2", vw); row("wrong mix: correlation it delivers", RHO / math.sqrt(vw))
print(f"hand: rho s1 s2 {RHO * S1 * S2:.4f}, mu1 + mu2 {MU1 + MU2:.4f}, var of P {vp * vp:.4f}, "
      f"log drift {g - 0.5 * vp * vp:.4f}, z {-(g - 0.5 * vp * vp) / vp:.6f}; try rho -0.5: {A0 * B0 * math.exp((MU1 + MU2 - 0.5 * S1 * S2) * T):.4f}")
print(f"figure, origin 60 200, Z1 tip 210 200, W2 tip {60 + 150 * RHO:.2f} {200 - 150 * C22:.2f}")

h, qp, qr, qxy, dn = 0.04, 0.0, 0.0, 0.0, 2.0 * math.pi * C22   # B: midpoint rule on [-8, 8]^2
for i in range(400):
    x = -8.0 + (i + 0.5) * h
    for j in range(400):
        y = -8.0 + (j + 0.5) * h
        wt = math.exp(-(x * x - 2.0 * RHO * x * y + y * y) / (2.0 * C22 * C22)) / dn * h * h
        a, b = prices(T, math.sqrt(T) * x, math.sqrt(T) * y)
        qp += a * b * wt; qr += a / b * wt; qxy += x * y * wt
print("B  integral against the joint bell curve, 400 x 400 cells")
row("E[P_1]", qp); row("E[A_1 / B_1]", qr); row("E[W1_1 W2_1]", qxy)

NF, dt, f1, f2, fw, cr = 4096, T / 4096, [], [], [], []   # fine steps of W1, W2, the wrong mix
for k in range(NF):
    z1, z2 = normal(), normal()
    f1.append(math.sqrt(dt) * z1); f2.append(math.sqrt(dt) * (RHO * z1 + C22 * z2))
    fw.append(math.sqrt(dt) * (RHO * z1 + (1 - RHO) * z2))
print("C  one path: steps, sum dW1 dW2, its predicted sd, sum (dW2 wrong mix)^2")
for n in (16, 64, 256, 1024, 4096):
    m, c, q = NF // n, 0.0, 0.0
    for k in range(n):
        d1, d2, dw = 0.0, 0.0, 0.0
        for j in range(k * m, (k + 1) * m): d1 += f1[j]; d2 += f2[j]; dw += fw[j]
        c += d1 * d2; q += dw * dw
    cr.append((c, q))
    print(f"   n {n:>5}   {c:>9.6f}   {math.sqrt((1 + RHO * RHO) * T / n):.6f}   {q:.6f}")

NP = 20000
pv, rv, xy, bl, w1s, wws, path = [], [], [], [], [], [], []
for i in range(NP):
    w1, w2, ww = 0.0, 0.0, 0.0
    for j in range(12):                        # monthly steps
        z1, z2 = normal(), normal()
        w1 += math.sqrt(T / 12) * z1; w2 += math.sqrt(T / 12) * (RHO * z1 + C22 * z2)
        ww += math.sqrt(T / 12) * (RHO * z1 + (1 - RHO) * z2)
        if i == 0: path.append(prices((j + 1) * T / 12, w1, w2))
    a, b = prices(T, w1, w2)
    pv.append(a * b); rv.append(a / b); xy.append(w1 * w2); bl.append(1.0 if a * b < A0 * B0 else 0.0)
    w1s.append(w1); wws.append(ww)
mp, mr, mxy, mbl = mean_se(pv), mean_se(rv), mean_se(xy), mean_se(bl)
mww = mean_se([x * x for x in wws]); mwx = mean_se([w1s[i] * wws[i] for i in range(NP)])
print("D  20000 paths, monthly steps")
row_se("E[P_1]", *mp); row_se("E[A_1 / B_1]", *mr); row_se("E[W1_1 W2_1]", *mxy)
row_se("P(P_1 < 5000)", *mbl)
row_se("wrong mix: E[W2_1^2]", *mww); row_se("wrong mix: E[W1_1 W2_1]", *mwx)
print("chart, path A " + " ".join(f"{v:.2f}" for v in [A0] + [p[0] for p in path]))
print("chart, path B " + " ".join(f"{v:.2f}" for v in [B0] + [p[1] for p in path]))

ns, ew, eo = (16, 64, 256, 1024, 4096), [0.0] * 5, [0.0] * 5
for i in range(200):
    g1, g2 = [0.0], [0.0]
    for k in range(NF):
        z1, z2 = normal(), normal()
        g1.append(g1[k] + math.sqrt(dt) * z1); g2.append(g2[k] + math.sqrt(dt) * (RHO * z1 + C22 * z2))
    a, b = prices(T, g1[NF], g2[NF])
    for s, n in enumerate(ns):
        m, pw, po = NF // n, A0 * B0, A0 * B0
        for k in range(n):
            d1, d2 = g1[(k + 1) * m] - g1[k * m], g2[(k + 1) * m] - g2[k * m]
            pw += pw * (g * T / n + S1 * d1 + S2 * d2)
            po += po * ((MU1 + MU2) * T / n + S1 * d1 + S2 * d2)
        ew[s] += abs(pw - a * b) / 200.0; eo[s] += abs(po - a * b) / 200.0
print("E  200 paths: mean |error| of Euler P_1; steps, with cross term, without")
for s, n in enumerate(ns): print(f"   n {n:>5}   {ew[s]:9.2f}   {eo[s]:9.2f}")

assert abs(qp - ep) < 1e-6 * ep and abs(qr - er) < 1e-6 * er, "integral agrees with Ito's drifts"
assert abs(qxy - RHO * T) < 1e-6, "joint bell curve has covariance rho T"
assert abs(mp[0] - ep) < 4 * mp[1], "simulated E[P_1] matches the cross-term formula"
assert abs(mp[0] - ep_ind) > 4 * mp[1], "and rules out the formula without it"
assert abs(mr[0] - er) < 4 * mr[1], "ratio drift includes s2^2 - rho s1 s2"
assert abs(mxy[0] - RHO * T) < 4 * mxy[1], "E[W1 W2] = rho T, not 0"
assert abs(mbl[0] - pbelow) < 4 * mbl[1], "chance of ending below 5000"
assert abs(cr[4][0] - RHO * T) < 4 * math.sqrt((1 + RHO * RHO) * T / NF), "cross sum tends to rho T"
assert abs(mww[0] - 0.5) < 4 * mww[1], "wrong mix: W2 has variance 0.5, not 1"
assert ew[4] < ew[0] / 4 and abs(eo[4] - (ep - ep_ind)) < 0.1 * (ep - ep_ind), "Euler needs the cross term"
print("ALL CHECKS PASS")
