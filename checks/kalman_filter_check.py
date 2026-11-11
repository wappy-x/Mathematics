# Kalman filter on the balancing pendulum -- the check behind the card.  Standard library only.
# Roads: the gain formula and its Riccati recursion; a brute-force search over fixed gains;
# the information (precision) form of the correction; 2000 simulated runs; innovation statistics.
import math
DT, L = 0.01, 9.81 / 16             # 100 hertz; pole length l (m), so g/l = 16 per second squared
SA, SR = 1.0, 0.005                 # random angular acceleration sd (rad/s^2); encoder sd (rad)
ch, sh = math.cosh(0.04), math.sinh(0.04)
F = [[ch, sh / 4], [4 * sh, ch]]    # exact 0.01 s step of theta'' = 16 theta, from the matrix exponential
g = [(ch - 1) / 16, sh / 4]         # what a held angular acceleration of 1 rad/s^2 adds in one step
G = [-g[0] / L, -g[1] / L]          # a cart acceleration a pushes the pole by -a/l
Q = [[SA * SA * g[i] * g[j] for j in range(2)] for i in range(2)]
R, P0, M64 = SR * SR, [[0.05 * 0.05, 0.0], [0.0, 0.5 * 0.5]], (1 << 64) - 1
class Rng:                                       # SplitMix64 bits, Box-Muller normals
    def __init__(s, seed): s.s = seed
    def u(s):
        s.s = (s.s + 0x9E3779B97F4A7C15) & M64
        z = ((s.s ^ (s.s >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return ((z ^ (z >> 31)) >> 11) / 2.0 ** 53
    def n(s):
        a = 1.0 - s.u()
        return math.sqrt(-2.0 * math.log(a)) * math.cos(2.0 * math.pi * s.u())
def predict(x, P, u, q=1.0, use_u=True):
    x = [F[0][0] * x[0] + F[0][1] * x[1] + use_u * G[0] * u, F[1][0] * x[0] + F[1][1] * x[1] + use_u * G[1] * u]
    FP = [[F[i][0] * P[0][j] + F[i][1] * P[1][j] for j in range(2)] for i in range(2)]
    return x, [[FP[i][0] * F[j][0] + FP[i][1] * F[j][1] + q * Q[i][j] for j in range(2)] for i in range(2)]
def correct(x, P, y, K=None):                    # the encoder reads the angle only: H = [1, 0]
    S = P[0][0] + R
    if K is None: K = [P[0][0] / S, P[1][0] / S]
    nu, A = y - x[0], [[1 - K[0], 0.0], [-K[1], 1.0]]           # Joseph form: right for any gain
    AP = [[A[i][0] * P[0][j] + A[i][1] * P[1][j] for j in range(2)] for i in range(2)]
    Pn = [[AP[i][0] * A[j][0] + AP[i][1] * A[j][1] + K[i] * K[j] * R for j in range(2)] for i in range(2)]
    return [x[0] + K[0] * nu, x[1] + K[1] * nu], Pn, nu, S, K
def inv2(P): d = P[0][0] * P[1][1] - P[0][1] * P[1][0]; return [[P[1][1] / d, -P[0][1] / d], [-P[1][0] / d, P[0][0] / d]]
def info_correct(x, P, y):                       # precisions add; means weighted by precision
    I = inv2(P); I2 = [[I[0][0] + 1 / R, I[0][1]], [I[1][0], I[1][1]]]; Pn = inv2(I2)
    b = [I[0][0] * x[0] + I[0][1] * x[1] + y / R, I[1][0] * x[0] + I[1][1] * x[1]]
    return [Pn[0][0] * b[0] + Pn[0][1] * b[1], Pn[1][0] * b[0] + Pn[1][1] * b[1]], Pn
def bend(t, u, w, n=10):                         # the curved pole: theta'' = 16 sin theta - (u/l) cos theta + w, RK4
    f, h = lambda s: [s[1], 16 * math.sin(s[0]) - u / L * math.cos(s[0]) + w], DT / n
    for _ in range(n):
        k1 = f(t); k2 = f([t[0] + h / 2 * k1[0], t[1] + h / 2 * k1[1]]); k3 = f([t[0] + h / 2 * k2[0], t[1] + h / 2 * k2[1]])
        k4 = f([t[0] + h * k3[0], t[1] + h * k3[1]]); t = [t[i] + h / 6 * (k1[i] + 2 * k2[i] + 2 * k3[i] + k4[i]) for i in range(2)]
    return t
def run(seed, steps, variants, th0=0.0, curved=False):   # variant 0 is the true filter and drives the cart
    r = Rng(seed)
    t = [th0 + math.sqrt(P0[0][0]) * r.n(), math.sqrt(P0[1][1]) * r.n()]
    est = [([th0, 0.0], [row[:] for row in P0]) for _ in variants]
    out, yprev = [], None
    for k in range(1, steps + 1):
        u = L * (32 * est[0][0][0] + 8 * est[0][0][1])          # a = l (32 th + 8 om), from Pole placement
        w = SA * r.n()
        t = bend(t, u, w) if curved else [F[0][0] * t[0] + F[0][1] * t[1] + G[0] * u + g[0] * w, F[1][0] * t[0] + F[1][1] * t[1] + G[1] * u + g[1] * w]
        y = t[0] + SR * r.n()
        rec = []
        for i, (q, use_u, K) in enumerate(variants):
            x, P = predict(est[i][0], est[i][1], u, q, use_u)
            x, P, nu, S, _ = correct(x, P, y, K)
            est[i] = (x, P); rec.append((x, nu, S))
        fd = (y - yprev) / DT if yprev is not None else 0.0
        out.append((t, y, fd, rec)); yprev = y
    return out
def show(label, v): print(f"{label:<44} {v:>12.6f}")
# ---- step 1, by hand ----
xp, Pp = predict([0.0, 0.0], P0, 0.0); y1 = run(1, 1, [(1.0, True, None)])[0][1]
x1, P1, nu1, S1, K1 = correct(xp, Pp, y1); xi, Pi = info_correct(xp, Pp, y1)
for lab, v in [("pole length l (m)", L), ("push: angular acceleration sd (rad/s^2)", SA), ("F: cosh 0.04", F[0][0]), ("F: sinh 0.04 / 4 (s)", F[0][1]), ("F: 4 sinh 0.04 (per s)", F[1][0]),
               ("G: angle per m/s^2 of cart", G[0]), ("G: rate per m/s^2 of cart", G[1]),
               ("Q: angle sd added per step (rad)", math.sqrt(Q[0][0])), ("Q: rate sd added per step", math.sqrt(Q[1][1])),
               ("step 1 predicted angle var P-", Pp[0][0]), ("step 1 predicted rate var", Pp[1][1]),
               ("step 1 predicted covariance", Pp[0][1]), ("step 1 reading y1 (rad)", y1), ("step 1 S = P- + R", S1),
               ("step 1 gain on angle", K1[0]), ("step 1 gain on rate (per s)", K1[1]),
               ("step 1 angle estimate", x1[0]), ("  by precisions", xi[0]), ("step 1 rate estimate", x1[1]),
               ("  by precisions", xi[1]), ("step 1 rate sd after", math.sqrt(P1[1][1])), ("  by precisions", math.sqrt(Pi[1][1]))]:
    show(lab, v)
# ---- the steady gain: Riccati recursion, then a brute-force search over fixed gains ----
P, settle = P0, []
for k in range(1, 1001):
    _, Pm = predict([0, 0], P, 0.0)
    _, P, _, Sinf, Kinf = correct([0, 0], Pm, 0.0)
    if k in (1, 2, 3, 5, 10, 20, 50, 100): settle.append((k, Kinf[1], math.sqrt(P[1][1]), math.sqrt(Pm[1][1])))
print("settling, step      " + "".join(f"{s[0]:>8d}" for s in settle))
print("  gain on rate      " + "".join(f"{s[1]:>8.3f}" for s in settle))
print("  rate sd predicted " + "".join(f"{s[3]:>8.4f}" for s in settle))
print("  rate sd (rad/s)   " + "".join(f"{s[2]:>8.4f}" for s in settle))
def cost(K):                                    # steady error of a fixed gain, iterated to rest
    E = P0
    for _ in range(1500):
        _, E = predict([0, 0], E, 0.0); _, E, _, _, _ = correct([0, 0], E, 0.0, K)
    return E[0][0] / (DT * DT) + E[1][1]
Ks, step, rounds = [0.5, 5.0], [0.1, 1.0], 0; best = cost(Ks)
while step[0] > 1e-7 and rounds < 200:          # pattern search; it needs 35 rounds, give up after 200
    moved, rounds = False, rounds + 1
    for i in range(2):
        for sgn in (1, -1):
            trial = Ks[:]; trial[i] += sgn * step[i]
            if trial[0] < 1 and (c := cost(trial)) < best: Ks, best, moved = trial, c, True
    if not moved: step = [s / 2 for s in step]
for lab, v in [("steady gain on angle", Kinf[0]), ("  by search", Ks[0]), ("steady gain on rate (per s)", Kinf[1]),
               ("  by search", Ks[1]), ("steady angle sd (rad)", math.sqrt(P[0][0])), ("steady rate sd (rad/s)", math.sqrt(P[1][1])),
               ("steady innovation sd (rad)", math.sqrt(Sinf)), ("rate sd from differencing (rad/s)", math.sqrt(2 * R) / DT)]:
    show(lab, v)
# ---- 2000 runs of 2 seconds: errors and surprises over the last second ----
VAR = [(1.0, True, None), (0.01, True, None), (1.0, False, None), (1.0, True, [2 * Kinf[0], 2 * Kinf[1]])]
NAMES = ["the filter", "Q 100 times too small", "input left out of predict", "twice the steady gain"]
acc = [[0.0] * 5 for _ in VAR]; fd2 = 0.0; n = 0
for seed in range(1, 2001):
    out = run(seed, 200, VAR)
    for k in range(100, 200):
        t, y, fd, rec = out[k]; n += 1; fd2 += (fd - t[1]) ** 2
        for i, (x, nu, S) in enumerate(rec):
            z, zp = nu / math.sqrt(S), out[k - 1][3][i][1] / math.sqrt(out[k - 1][3][i][2])
            a = acc[i]; a[0] += (x[0] - t[0]) ** 2; a[1] += (x[1] - t[1]) ** 2; a[2] += z * z; a[3] += z * zp
st = [(math.sqrt(a[0] / n), math.sqrt(a[1] / n), a[2] / n, a[3] / a[2]) for a in acc]
for nm, (ea, er, nis, c1) in zip(NAMES, st):
    print(f"{nm:<26} angle rms {ea:.6f}  rate rms {er:.4f}  surprise^2/S {nis:.3f}  lag-1 {c1:+.3f}")
print(f"differencing the encoder   rate rms {math.sqrt(fd2 / n):.4f}")
# ---- one run (seed 1) for the chart: every 0.1 s ----
story = run(1, 200, VAR[:1])
for lab, f in [("chart, time (s)", lambda o, k: (k + 1) * DT), ("chart, true rate", lambda o, k: o[0][1]),
               ("chart, filter rate", lambda o, k: o[3][0][0][1]), ("chart, differenced", lambda o, k: o[2])]:
    print(f"{lab:<19}" + " ".join(f"{f(story[k], k):5.2f}" for k in range(9, 200, 10)))
E, T, A = [[1.0, 0.0], [0.0, 1.0]], [[1.0, 0.0], [0.0, 1.0]], [[0.0, DT], [16 * DT, 0.0]]   # e^(A dt) by its series
for j in range(1, 15): T = [[(T[i][0] * A[0][c] + T[i][1] * A[1][c]) / j for c in range(2)] for i in range(2)]; E = [[E[i][c] + T[i][c] for c in range(2)] for i in range(2)]
assert max(abs(E[i][c] - F[i][c]) for i in range(2) for c in range(2)) < 1e-14, "cosh-sinh step vs the series"
assert max(abs(x1[i] - xi[i]) for i in range(2)) < 1e-12 and abs(P1[1][1] - Pi[1][1]) < 1e-12, "gain form vs precisions"
assert abs(Kinf[0] - Ks[0]) < 1e-5 and abs(Kinf[1] - Ks[1]) < 1e-4, "Riccati gain vs brute-force search"
assert abs(st[0][1] / math.sqrt(P[1][1]) - 1) < 0.03 and abs(st[0][0] / math.sqrt(P[0][0]) - 1) < 0.03, "simulated vs P"
assert abs(st[0][2] - 1) < 0.015 and abs(st[0][3]) < 0.01, "the filter's surprises: right size, uncorrelated"
assert st[1][2] > 1.5 and st[1][3] > 0.3 and st[3][3] < -0.1, "mis-tuned filters leave a pattern in the surprises"
assert abs(math.sqrt(fd2 / n) / (math.sqrt(2 * R) / DT) - 1) < 0.02, "differencing noise vs its formula"
assert min(v[1] for v in st) == st[0][1], "no variant beats the filter on the rate"
assert step[0] <= 1e-7, "the brute-force gain search did not settle"
cs = []                                          # 200 runs from a 0.5 rad lean, first 0.5 s: straight pole, then curved pole
for cv in (False, True):
    o = [s for seed in range(1, 201) for s in run(seed, 50, VAR[:1], 0.5, cv)]
    cs.append((math.sqrt(sum((s[3][0][0][1] - s[0][1]) ** 2 for s in o) / len(o)), sum(s[3][0][1] ** 2 / s[3][0][2] for s in o) / len(o)))
print(f"from 0.5 rad, first 0.5 s: straight pole rate rms {cs[0][0]:.4f} surprise^2/S {cs[0][1]:.3f}; curved pole {cs[1][0]:.4f} and {cs[1][1]:.3f}")
assert abs(cs[0][1] - 1) < 0.05 and cs[1][1] > 1.15, "straight pole: right-sized surprises; curved pole: too big"
print("ALL CHECKS PASS")
