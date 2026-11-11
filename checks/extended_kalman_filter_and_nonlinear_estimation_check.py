# Extended and unscented filters on a pole swung far from upright -- the check behind the card.  Standard library only.
# Roads: the step's slope matrix by series, by closed form and by finite differences; the unscented step against
# the exact mean of a sine and against 200,000 random draws; every filter scored against simulated truth.
import math
DT, GL = 0.01, 16.0                 # 100 hertz; g/l (per s^2) for a pole 9.81/16 = 0.613125 m long
SA, SR = 1.0, 0.005                 # random angular acceleration sd (rad/s^2); encoder sd (rad)
TH0, P0 = 0.3, [[0.05 ** 2, 0.0], [0.0, 0.5 ** 2]]      # let go 0.3 rad from upright; the filter's start belief
gv = [DT * DT / 2, DT]              # what a held angular acceleration of 1 rad/s^2 adds in one step
Q = [[SA * SA * gv[i] * gv[j] for j in range(2)] for i in range(2)]
R, M64 = SR * SR, (1 << 64) - 1

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
def f(x):                                        # one 0.01 s step of theta'' = 16 sin(theta): RK4 in 4 slices
    th, om, h = x[0], x[1], DT / 4
    for _ in range(4):
        a1, b1 = om, GL * math.sin(th)
        a2, b2 = om + h / 2 * b1, GL * math.sin(th + h / 2 * a1)
        a3, b3 = om + h / 2 * b2, GL * math.sin(th + h / 2 * a2)
        a4, b4 = om + h * b3, GL * math.sin(th + h * a3)
        th, om = th + h / 6 * (a1 + 2 * a2 + 2 * a3 + a4), om + h / 6 * (b1 + 2 * b2 + 2 * b3 + b4)
    return [th, om]
def jac(th, k=None):                             # e^(A dt), A = [[0, 1], [k, 0]], k = 16 cos(theta): A^2 = k I
    k = GL * math.cos(th) if k is None else k
    c = s = 0.0; t = 1.0
    for m in range(8):
        c += t; s += t * DT / (2 * m + 1); t *= k * DT * DT / ((2 * m + 1) * (2 * m + 2))
    return [[c, s], [k * s, c]]
def fpf(F, P, q):
    FP = [[F[i][0] * P[0][j] + F[i][1] * P[1][j] for j in range(2)] for i in range(2)]
    return [[FP[i][0] * F[j][0] + FP[i][1] * F[j][1] + q * Q[i][j] for j in range(2)] for i in range(2)]
def sigma(x, P):                                 # 2n + 1 = 5 points, n + kappa = 3: weights 1/3, then 1/6 each
    a = math.sqrt(P[0][0]); b = P[1][0] / a; c = math.sqrt(max(P[1][1] - b * b, 0.0)); r3 = math.sqrt(3.0)
    pts = [x, [x[0] + r3 * a, x[1] + r3 * b], [x[0] - r3 * a, x[1] - r3 * b], [x[0], x[1] + r3 * c], [x[0], x[1] - r3 * c]]
    return pts, [1 / 3, 1 / 6, 1 / 6, 1 / 6, 1 / 6]
def predict(kind, x, P, q):
    if kind == "ekf": return f(x), fpf(jac(x[0]), P, q)     # move the centre exactly; slope matrix at the centre
    if kind == "lin":                                        # last card's filter: slope matrix frozen at upright
        F = jac(0.0); return [F[0][0] * x[0] + F[0][1] * x[1], F[1][0] * x[0] + F[1][1] * x[1]], fpf(F, P, q)
    pts, w = sigma(x, P); ys = [f(p) for p in pts]           # unscented: push the five points, refit
    m = [sum(w[j] * ys[j][i] for j in range(5)) for i in range(2)]
    return m, [[sum(w[j] * (ys[j][i] - m[i]) * (ys[j][l] - m[l]) for j in range(5)) + q * Q[i][l] for l in range(2)] for i in range(2)]
def correct(x, P, y, rr=1.0):                    # the encoder reads the angle: the last card's correction
    S = P[0][0] + rr * R; K = [P[0][0] / S, P[1][0] / S]; nu = y - x[0]
    Pn = [[P[0][0] - K[0] * P[0][0], P[0][1] - K[0] * P[0][1]], [P[1][0] - K[1] * P[0][0], P[1][1] - K[1] * P[0][1]]]
    return [x[0] + K[0] * nu, x[1] + K[1] * nu], Pn, nu, S, K
def run(seed, steps, variants, blind=()):         # variants: (kind, Q factor, R factor); blind: steps with no reading
    r = Rng(seed); t = [TH0, 0.0]
    est = [([TH0, 0.0], [row[:] for row in P0]) for _ in variants]; out = []
    for k in range(1, steps + 1):
        w = SA * r.n(); t = f(t); t = [t[0] + gv[0] * w, t[1] + gv[1] * w]; y = t[0] + SR * r.n(); rec = []
        for i, (kind, q, rr) in enumerate(variants):
            x, P = predict(kind, est[i][0], est[i][1], q); nu = S = None
            if k not in blind: x, P, nu, S, _ = correct(x, P, y, rr)
            est[i] = (x, P); rec.append((x, P, nu, S))
        out.append((t, y, rec))
    return out
def show(rows):
    for label, v in rows: print(f"{label:<44} {v:>12.6f}")
# ---- the slope matrix three ways, and the integrator's energy drift ----
def fd(x, e=1e-6):                               # finite differences of the actual step, column by column
    up, dn = [f([x[0] + e * (i == 0), x[1] + e * (i == 1)]) for i in range(2)], [f([x[0] - e * (i == 0), x[1] - e * (i == 1)]) for i in range(2)]
    return [[(up[j][i] - dn[j][i]) / (2 * e) for j in range(2)] for i in range(2)]
Fup, Fbot, Fhor, Fd_bot, Fd_hor = jac(0.0), jac(math.pi), jac(math.pi / 2), fd([math.pi, 0.0]), fd([math.pi / 2, 0.0])
x = [TH0, 0.0]
for _ in range(300): x = f(x)
drift = abs(x[1] ** 2 / 2 + GL * math.cos(x[0]) - GL * math.cos(TH0))
show([("pole length l = 9.81 / 16 (m)", 9.81 / GL), ("start angle 0.3 rad in degrees", math.degrees(TH0)), ("wide belief sd 0.5 rad in degrees", math.degrees(0.5)),
      ("slope at upright, cosh 0.04", Fup[0][0]), ("  4 sinh 0.04 (per s)", Fup[1][0]), ("slope at bottom, cos 0.04", Fbot[0][0]),
      ("  -4 sin 0.04 (per s)", Fbot[1][0]), ("  by finite differences", Fd_bot[1][0]), ("slope at horizontal, angle per rate (s)", Fhor[0][1]),
      ("  rate per angle (per s)", Fhor[1][0]), ("  by finite differences", Fd_hor[1][0]), ("energy drift over 3 s, no noise (per s^2)", drift)])
# ---- one extended step by hand, from the start belief ----
xp, Pp = predict("ekf", [TH0, 0.0], P0, 1.0); F1 = jac(TH0)
y1 = run(1, 1, [("ekf", 1, 1)])[0][1]; x1, P1, nu1, S1, K1 = correct(xp, Pp, y1)
show([("step 1: k = 16 cos 0.3 (per s^2)", GL * math.cos(TH0)), ("step 1: slope, diagonal", F1[0][0]), ("step 1: slope, angle per rate (s)", F1[0][1]),
      ("step 1: slope, rate per angle (per s)", F1[1][0]), ("step 1: predicted angle (rad)", xp[0]), ("step 1: predicted rate (rad/s)", xp[1]),
      ("step 1: predicted angle var", Pp[0][0]), ("step 1: predicted covariance", Pp[0][1]), ("step 1: reading (rad)", y1), ("step 1: S", S1),
      ("step 1: gain on angle", K1[0]), ("step 1: gain on rate (per s)", K1[1]), ("step 1: angle estimate (rad)", x1[0]), ("step 1: rate estimate (rad/s)", x1[1])])
# ---- a wide belief at the horizontal pole: gravity's push 16 sin(theta), angle sd 0.5 rad ----
SD = 0.5; pts, w = sigma([math.pi / 2, 0.0], [[SD * SD, 0.0], [0.0, 0.01]])
pu = [GL * math.sin(p[0]) for p in pts]; mu = sum(a * b for a, b in zip(w, pu))
sdu = math.sqrt(sum(a * (b - mu) ** 2 for a, b in zip(w, pu)))
ex, exsd = GL * math.exp(-SD * SD / 2), GL * (1 - math.exp(-SD * SD)) / math.sqrt(2)
r = Rng(7); mc = [GL * math.sin(math.pi / 2 + SD * r.n()) for _ in range(200000)]
mcm = sum(mc) / len(mc); mcsd = math.sqrt(sum((v - mcm) ** 2 for v in mc) / len(mc))
show([("wide belief: sigma point angle offset (rad)", math.sqrt(3) * SD), ("  push at the offset points", pu[1]), ("  push, unscented mean", mu),
      ("  push, exact mean 16 exp(-sd^2/2)", ex), ("  push, 200000 draws", mcm), ("  push, extended (tangent) mean", GL), ("  sd, unscented", sdu),
      ("  sd, exact", exsd), ("  sd, 200000 draws", mcsd), ("  sd, extended (tangent)", abs(GL * math.cos(math.pi / 2)) * SD)])
# ---- 300 runs of 3 s at 100 hertz, scored from 0.5 s on ----
VAR = [("ekf", 1, 1), ("ukf", 1, 1), ("lin", 1, 1), ("ekf", 0.01, 1), ("ekf", 0.1, 1), ("ekf", 100, 1), ("ekf", 1, 100)]
NAMES = ["extended filter", "unscented filter", "frozen at upright", "extended, Q / 100", "extended, Q / 10", "extended, Q x 100", "extended, R x 100"]
acc = [[0.0] * 5 for _ in VAR]; n = 0
for seed in range(1, 301):
    out = run(seed, 300, VAR)
    for k in range(50, 300):
        t, _, rec = out[k]; n += 1
        for i, (x, P, nu, S) in enumerate(rec):
            z, zp = nu / math.sqrt(S), out[k - 1][2][i][2] / math.sqrt(out[k - 1][2][i][3])
            a = acc[i]; a[0] += (x[0] - t[0]) ** 2; a[1] += (x[1] - t[1]) ** 2; a[2] += z * z; a[3] += z * zp; a[4] += P[1][1]
st = [(math.sqrt(a[0] / n), math.sqrt(a[1] / n), a[2] / n, a[3] / a[2], math.sqrt(a[4] / n)) for a in acc]
for nm, (ea, er, nis, c1, cl) in zip(NAMES, st):
    print(f"{nm:<19} angle rms {ea:.4f}  rate rms {er:.4f}  claimed {cl:.4f}  surprise^2/S {nis:8.3f}  lag-1 {c1:+.3f}")
# ---- the encoder drops out after 0.5 s; one reading comes back; runs split by whether the pole tipped over ----
drop, tl = {}, [[0.0] * 8 for _ in range(2)]     # drop[blind, group, filter]: runs, beyond 3 sd, sum nu^2, sum S; tl: at 1.7, 2.3, 2.5, 2.9 s
for D in (100, 250):
    for seed in range(1, 301):
        out = run(seed, 50 + D, VAR[:2], blind=range(51, 50 + D)); tip = any(not 0 < o[0][0] < 2 * math.pi for o in out)
        for i, (x, P, nu, S) in enumerate(out[-1][2]):
            for g in ("all", "tipped" if tip else "not tipped"):
                a = drop.setdefault((D, g, i), [0, 0, 0.0, 0.0]); a[0] += 1; a[1] += nu * nu > 9 * S; a[2] += nu * nu; a[3] += S
            for j, k in enumerate((169, 229, 249, 289) if D == 250 else ()): o = out[k]; tl[i][2 * j] += o[2][i][1][0][0]; tl[i][2 * j + 1] += (o[2][i][0][0] - o[0][0]) ** 2
ms = {key: (math.sqrt(a[2] / a[0]), math.sqrt(a[3] / a[0]), a[1] / a[0]) for key, a in drop.items()}   # miss rms, claimed, beyond 3 sd
for D, g in ((100, "all"), (250, "all"), (250, "tipped"), (250, "not tipped")):
    print(f"blind {D / 100:.1f} s, {g:<10} {drop[D, g, 0][0]:3d} runs" + "".join(f"  {NAMES[i].split()[0]}: miss rms {ms[D, g, i][0]:6.3f} rad, claimed {ms[D, g, i][1]:.3f} rad, beyond 3 sd {ms[D, g, i][2]:.3f}" for i in range(2)))
for i in range(2): print(f"blind 2.5 s, {NAMES[i].split()[0]:<9} claimed / real angle sd (rad) at 1.7, 2.3, 2.5, 2.9 s" + "".join(f"  {math.sqrt(tl[i][j] / 300):.3f} / {math.sqrt(tl[i][j + 1] / 300):.3f}" for j in range(0, 8, 2)))
# ---- one run (seed 1) for the chart: every 0.1 s ----
story = run(1, 300, VAR[:3])
for lab, g in [("chart, time (s)", lambda o, k: (k + 1) * DT), ("chart, true rate", lambda o, k: o[0][1]),
               ("chart, extended rate", lambda o, k: o[2][0][0][1]), ("chart, frozen rate", lambda o, k: o[2][2][0][1])]:
    print(f"{lab:<21}" + " ".join(f"{g(story[k], k):5.1f}" for k in range(9, 300, 10)))
E = [[math.cosh(0.04), math.sinh(0.04) / 4], [4 * math.sinh(0.04), math.cosh(0.04)]]
assert max(abs(Fup[i][j] - E[i][j]) for i in range(2) for j in range(2)) < 1e-14, "series vs cosh-sinh at upright"
assert abs(Fbot[1][0] + 4 * math.sin(0.04)) < 1e-14 and abs(Fd_bot[1][0] - Fbot[1][0]) < 1e-8, "slope at bottom: closed form, finite differences"
assert abs(Fd_hor[1][0] - Fhor[1][0]) < 1e-4 and drift < 1e-6, "frozen slope near the step's own; RK4 keeps energy"
assert abs(xp[0] - (TH0 + GL * math.sin(TH0) * DT * DT / 2)) < 1e-6, "predicted angle vs the hand formula"
assert abs(mu - ex) < 0.01 and abs(mcm - ex) < 4 * exsd / math.sqrt(2e5) and abs(sdu / exsd - 1) < 0.1, "unscented vs exact vs draws"
assert abs(st[0][1] / st[0][4] - 1) < 0.03 and abs(st[0][2] - 1) < 0.015 and abs(st[0][3]) < 0.01, "extended filter is honest"
assert abs(st[1][1] / st[0][1] - 1) < 0.01 and st[2][2] > 100, "unscented agrees; frozen filter diverges"
assert st[3][2] > st[4][2] > st[0][2] and st[3][3] > 0.3 and st[6][2] < 0.1 and st[6][3] > 0.3 and st[5][3] < -0.1, "mis-tuning shows in the surprises"
assert ms[100, "all", 0][2] < 0.02 and all(ms[250, "tipped", i][0] > 2 * math.pi and ms[250, "tipped", i][1] < 1.25 * ms[250, "not tipped", i][1] for i in range(2)), "both miss the tipped runs; neither claim marks them"
assert ms[250, "not tipped", 0][0] < ms[250, "not tipped", 1][0] < ms[250, "not tipped", 1][1] / 2 and all(abs(tl[i][2] / tl[i][3] - 1) < 0.2 for i in range(2)) and 9 * tl[0][6] < tl[0][7], "untipped runs; when the claims part"
print("ALL CHECKS PASS")
