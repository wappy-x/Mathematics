# Particle filter on a hanging pole whose sensor sees only the size of the angle -- the check behind the card. Standard
# library only. Roads: closed form, fine grid and particles for the first reading; particles against a two-filter bank.
import math
GL, DT, SV, SA = 16.0, 0.01, 0.05, 1.0      # g/l (1/s^2); step (s); sensor sd (rad); random push sd (rad/s^2)
N, NT, KICK, STEPS = 1000, 500, 4.893, 1000  # particles; resample when ESS < NT; kick a/l (rad/s^2) from 1.0 to 1.1 s
S0, W0, Y0, PHI0 = 0.5, 0.1, 0.6, -0.6      # prior sd of angle (rad) and rate (rad/s); first reading; true release angle
M64, Q = (1 << 64) - 1, [SA * SA * DT ** 4 / 4, SA * SA * DT ** 3 / 2, SA * SA * DT * DT]
class Rng:                                  # SplitMix64 bits, Box-Muller normals
    def __init__(s, seed): s.x = seed
    def u(s):
        s.x = (s.x + 0x9E3779B97F4A7C15) & M64
        z = ((s.x ^ (s.x >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return (((z ^ (z >> 31)) >> 11) + 0.5) / 2.0 ** 53
    def n(s): u1 = s.u(); u2 = s.u(); return math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2)
def kick(j): return KICK if 100 <= j < 110 else 0.0
def step(p, w, j, a=0.0):                   # RK4 over one 0.01 s step; a = random angular acceleration held for the step
    f = lambda q: -GL * math.sin(q) - kick(j) * math.cos(q) + a
    k1p, k1w = w, f(p)
    k2p, k2w = w + DT / 2 * k1w, f(p + DT / 2 * k1p)
    k3p, k3w = w + DT / 2 * k2w, f(p + DT / 2 * k2p)
    k4p, k4w = w + DT * k3w, f(p + DT * k3p)
    return p + DT / 6 * (k1p + 2 * k2p + 2 * k3p + k4p), w + DT / 6 * (k1w + 2 * k2w + 2 * k3w + k4w)
tr = Rng(1); truth = [(PHI0, 0.0)]; ys = [Y0]
for j in range(STEPS): p, w = step(*truth[-1], j, SA * tr.n()); truth.append((p, w)); ys.append(abs(p) + SV * tr.n())
def right(x, k):                            # nearer the true state than its mirror image (-angle, -rate)?
    P, W = truth[k]; return (x[0] - P) ** 2 + ((x[1] - W) / 4) ** 2 < (x[0] + P) ** 2 + ((x[1] + W) / 4) ** 2
def systematic(wt, u):                      # one uniform u in [0, 1/n); returns the index picked by each pointer
    n = len(wt); c, j, out = wt[0], 0, []
    for i in range(n):
        while u + i / n > c and j < n - 1: j += 1; c += wt[j]
        out.append(j)
    return out
def pf(n, thr, jit=True, seed=2026, keep=None):
    rng = Rng(seed); xs = []
    for _ in range(n): a = S0 * rng.n(); xs.append((a, W0 * rng.n()))
    wt = [1.0 / n] * n; rec = []; nres = 0
    for k in range(STEPS + 1):
        if k > 0: xs = [step(p, w, k - 1, SA * rng.n() if jit else 0.0) for p, w in xs]      # predict
        wt = [wi * math.exp(-(ys[k] - abs(p)) ** 2 / (2 * SV * SV)) for wi, (p, w) in zip(wt, xs)]  # weight
        s = sum(wt); wt = [wi / s for wi in wt]
        ess = 1.0 / sum(wi * wi for wi in wt)
        m = sum(wi * p for wi, (p, w) in zip(wt, xs)); size = sum(wi * abs(p) for wi, (p, w) in zip(wt, xs))
        sd = math.sqrt(sum(wi * (p - m) ** 2 for wi, (p, w) in zip(wt, xs)))
        rec.append((m, sd, sum(wi for wi, x in zip(wt, xs) if right(x, k)), ess, len(set(xs)), size))
        if ess < thr:                                                                       # resample
            idx = systematic(wt, rng.u() / n)
            if keep is not None and k == 0: keep.extend([wt, idx, xs])
            xs = [xs[i] for i in idx]; wt = [1.0 / n] * n; nres += 1
    return rec, nres
def ekf(x, P, y, j=None):                   # extended filter; P = [angle var, covariance, rate var]
    if j is not None:
        k = -GL * math.cos(x[0]) + kick(j) * math.sin(x[0]); c, s = 1 + k * DT * DT / 2, DT + k * DT ** 3 / 6
        a, b, d = P; ks = k * s
        P = [c * c * a + 2 * c * s * b + s * s * d + Q[0], c * ks * a + (c * c + s * ks) * b + s * c * d + Q[1],
             ks * ks * a + 2 * ks * c * b + c * c * d + Q[2]]
        x = step(*x, j)
    h = (x[0] > 0) - (x[0] < 0); a, b, d = P; S = a + SV * SV; nu = y - abs(x[0])
    k0, k1 = h * a / S, h * b / S; return (x[0] + k0 * nu, x[1] + k1 * nu), [a - k0 * h * a, b - k0 * h * b, d - k1 * h * b], \
        math.exp(-nu * nu / (2 * S)) / math.sqrt(2 * math.pi * S)
def sigma(x, P):                            # centre, then centre +- sqrt(3) times each column of a square root of P
    l1 = math.sqrt(P[0]); l2 = P[1] / l1; l3 = math.sqrt(P[2] - l2 * l2); r = math.sqrt(3.0)
    return [x, (x[0] + r * l1, x[1] + r * l2), (x[0] - r * l1, x[1] - r * l2), (x[0], x[1] + r * l3), (x[0], x[1] - r * l3)]
def wsum(a, b): return sum(w * u * v for w, u, v in zip([1 / 3] + [1 / 6] * 4, a, b))    # weights 1/3, then 1/6
def ukf(x, P, y, j=None):                   # unscented filter, five sigma points, weights 1/3 and 1/6
    if j is not None:
        ch = [step(*c, j) for c in sigma(x, P)]; one = [1.0] * 5
        x = (wsum(one, [c[0] for c in ch]), wsum(one, [c[1] for c in ch]))
        ep, ew = [c[0] - x[0] for c in ch], [c[1] - x[1] for c in ch]
        P = [wsum(ep, ep) + Q[0], wsum(ep, ew) + Q[1], wsum(ew, ew) + Q[2]]
    ch = sigma(x, P); Y = [abs(c[0]) for c in ch]; my = wsum([1.0] * 5, Y)
    ep, ew, ey = [c[0] - x[0] for c in ch], [c[1] - x[1] for c in ch], [v - my for v in Y]
    S = wsum(ey, ey) + SV * SV; k0, k1 = wsum(ep, ey) / S, wsum(ew, ey) / S; nu = y - my
    return (x[0] + k0 * nu, x[1] + k1 * nu), [P[0] - k0 * k0 * S, P[1] - k0 * k1 * S, P[2] - k1 * k1 * S]
# ---- road 1: the first reading in closed form, and on a fine grid ----
V = S0 * S0 + SV * SV; cen, hsd = Y0 * S0 * S0 / V, math.sqrt(S0 * S0 * SV * SV / V)
def mw(s): return [2 * v / math.sqrt(s * s + v * v) * math.exp(-Y0 * Y0 / (2 * (s * s + v * v))) for v in (SV, SV / math.sqrt(2))]
EL, EL2 = mw(S0)                            # mean weight and mean squared weight over a start belief of sd S0
g = [(-3 + i * 0.0005) for i in range(12001)]
gp = [math.exp(-q * q / (2 * S0 * S0)) for q in g]; gl = [math.exp(-(Y0 - abs(q)) ** 2 / (2 * SV * SV)) for q in g]
Z = sum(a * b for a, b in zip(gp, gl)); gc = sum(a * b * abs(q) for a, b, q in zip(gp, gl, g)) / Z
gsd = math.sqrt(sum(a * b * (abs(q) - gc) ** 2 for a, b, q in zip(gp, gl, g)) / Z)
gneg = sum(a * b for a, b, q in zip(gp, gl, g) if q < 0) / Z; gess = Z * Z / sum(gp) / sum(a * b * b for a, b in zip(gp, gl))
print(f"setup: g/l {GL} 1/s^2 (pole {9.81 / GL} m), 0.6 rad = {math.degrees(0.6):.1f} deg, start sd {S0} rad and {W0} rad/s, step {DT} s, sensor sd {SV} rad, push sd {SA} rad/s^2, {N} particles, resample below {NT}")
print(f"first reading {Y0} rad, closed form: prior + sensor variance {V:.4f} rad^2, hump centres +-{cen:.6f} rad, hump sd {hsd:.6f} rad, each hump 0.500000")
print(f"first reading {Y0} rad, fine grid:   hump centres +-{gc:.6f} rad, hump sd {gsd:.6f} rad, negative hump {gneg:.6f}")
print(f"weight of a particle at -0.55 / 0.60 / 0.20 rad: {math.exp(-0.05 ** 2 / (2 * SV * SV)):.6f} / 1.000000 / {math.exp(-0.4 ** 2 / (2 * SV * SV)):.3e}")
print(f"mean weight {EL:.6f}, mean squared weight {EL2:.6f}, expected ESS fraction: closed form {EL * EL / EL2:.6f}, grid {gess:.6f}, so {N * EL * EL / EL2:.1f} particles; start sd 0.6 / 0.8 rad: " + " / ".join(f"{N * a * a / b:.1f}" for a, b in (mw(0.6), mw(0.8))) + " particles")
assert abs(gc - cen) < 1e-5 and abs(gsd - hsd) < 1e-5 and abs(gneg - 0.5) < 1e-9 and abs(gess - EL * EL / EL2) < 1e-5
keep = []; rec, nres = pf(N, NT, keep=keep); w0, idx0, xs0 = keep; cp = [idx0.count(i) for i in range(N)]
neg = sum(1 for i in idx0 if xs0[i][0] < 0); big = max(range(N), key=lambda i: w0[i])
print(f"particles after reading 1: ESS {rec[0][3]:.1f} of {N}, so resample; largest N*w {N * w0[big]:.3f} gets {cp[big]} copies")
print(f"after resampling: {neg} particles on the negative hump, {N - neg} on the positive (split sd from the ESS: {N * math.sqrt(0.25 / rec[0][3]):.1f} particles); every copy count within 1 of N*w: {all(abs(c - N * w) < 1 for c, w in zip(cp, w0))}")
assert all(abs(c - N * w) < 1 for c, w in zip(cp, w0)) and abs(rec[0][3] / N - EL * EL / EL2) < 0.03 and abs(neg - N / 2) < 3 * N * math.sqrt(0.25 / rec[0][3])
hist = [sum(1 for i in idx0 if math.floor((xs0[i][0] + 1.0) / 0.1) == b) for b in range(20)]
def Phi(z):                                 # normal CDF, Abramowitz and Stegun 7.1.26 (error below 1.5e-7)
    x = abs(z) / math.sqrt(2.0); t = 1.0 / (1.0 + 0.3275911 * x)
    e = 1.0 - t * (0.254829592 + t * (-0.284496736 + t * (1.421413741 + t * (-1.453152027 + t * 1.061405429)))) * math.exp(-x * x)
    return 0.5 * (1.0 + e) if z >= 0 else 0.5 * (1.0 - e)
ex = [N * 0.5 * sum(Phi((-0.9 + 0.1 * b - s * cen) / hsd) - Phi((-1 + 0.1 * b - s * cen) / hsd) for s in (1, -1)) for b in range(20)]
print("figure, particles per 0.1 rad bin from -1.0 to 1.0 rad:", hist)
print("figure, exact belief, expected per bin:", "[" + ", ".join(f"{e:.0f}" for e in ex) + "]")
assert sum((h - e) ** 2 / e for h, e in zip(hist, ex) if e > 5) * rec[0][3] / N < 25   # chi-square, scaled by ESS / N
toy = systematic([0.1, 0.4, 0.05, 0.3, 0.15], 0.07)
print(f"systematic resampling, weights 0.1 0.4 0.05 0.3 0.15, pointers 0.07 + i/5: picks particles {[i + 1 for i in toy]}")
# ---- road 2: the run, particles against a bank of two extended filters, one per hump ----
bank = [[(s * cen, 0.0), [hsd * hsd, 0.0, W0 * W0], 0.5] for s in (1, -1)]; bw = [0.5]
xe, Pe, _ = ekf((0.001, 0.0), [S0 * S0, 0.0, W0 * W0], Y0); xu, Pu = ukf((0.0, 0.0), [S0 * S0, 0.0, W0 * W0], Y0)
be, ee, ue, es, us = [0.0], [xe[0]], [xu[0]], [math.sqrt(Pe[0])], [math.sqrt(Pu[0])]
for k in range(1, STEPS + 1):
    for b in bank: b[0], b[1], lik = ekf(b[0], b[1], ys[k], k - 1); b[2] *= lik
    s = sum(b[2] for b in bank)
    for b in bank: b[2] /= s
    bw.append(sum(b[2] for b in bank if right(b[0], k))); be.append(sum(b[2] * b[0][0] for b in bank))
    xe, Pe, _ = ekf(xe, Pe, ys[k], k - 1); xu, Pu = ukf(xu, Pu, ys[k], k - 1)
    ee.append(xe[0]); ue.append(xu[0]); es.append(math.sqrt(Pe[0])); us.append(math.sqrt(Pu[0]))
rms = lambda e, a=600, b=STEPS: math.sqrt(sum((e[k] - truth[k][0]) ** 2 for k in range(a, b + 1)) / (b - a + 1))
claim = lambda s, a=600, b=STEPS: math.sqrt(sum(s[k] ** 2 for k in range(a, b + 1)) / (b - a + 1))
pm, ps = [r[0] for r in rec], [r[1] for r in rec]
print("t (s) | true angle | particle mean | particle sd | right-hump weight: particles / bank | ESS")
for k in (0, 50, 100, 110, 115, 120, 150, 1000):
    print(f"{k * DT:.2f} | {truth[k][0]:+.3f} | {rec[k][0]:+.3f} | {rec[k][1]:.3f} | {rec[k][2]:.3f} / {bw[k]:.3f} | {rec[k][3]:.1f}")
for lab, ws in (("particles", [r[2] for r in rec]), ("bank     ", bw)):
    print(f"chart, right-hump weight every 0.1 s, {lab}: [" + ", ".join(f"{ws[k]:.2f}" for k in range(0, 201, 10)) + "]")
m0 = [truth[100], (-truth[100][0], -truth[100][1])]
for j in range(100, 115): m0 = [step(p, w, j) for p, w in m0]
print(f"kick: cart {KICK / GL * 9.81:.3f} m/s^2 for 0.1 s; true state and its mirror at 1 s, both swinging toward 0 at {abs(truth[100][1]):.3f} rad/s, pushed alike, sizes at 1.15 s {abs(m0[0][0]):.3f} and {abs(m0[1][0]):.3f} rad")
dec = lambda ws: next(k for k in range(STEPS + 1) if ws[k] > 0.99) * DT
print(f"right hump passes 0.99 at: particles {dec([r[2] for r in rec]):.2f} s, bank {dec(bw):.2f} s; resamplings {nres} in {STEPS + 1} readings")
sz = math.sqrt(sum((rec[k][5] - abs(truth[k][0])) ** 2 for k in range(101)) / 101)
print(f"0 to 1 s, rms error: size of angle, particles {sz:.4f}; angle, particle mean {rms(pm, 0, 100):.4f}, extended {rms(ee, 0, 100):.4f}, unscented {rms(ue, 0, 100):.4f} rad")
print(f"unscented at 1 s: angle {ue[100]:+.6f} rad, claims sd {us[100]:.4f} rad; extended at 1 s: {ee[100]:+.4f} rad, claims sd {es[100]:.4f} rad")
print(f"6 to 10 s, rms error / claimed sd: particles {rms(pm):.4f} / {claim(ps):.4f}, bank {rms(be):.4f}, extended {rms(ee):.4f} / {claim(es):.4f}, unscented {rms(ue):.4f} / {claim(us):.4f} rad; extended against the mirror image of the truth {rms([-v for v in ee]):.4f} rad")
assert abs(dec([r[2] for r in rec]) - dec(bw)) < 0.05 and all(abs(bw[k] - 0.5) < 1e-9 for k in range(101))
assert rms(pm) < 0.02 and 0.67 < rms(pm) / claim(ps) < 1.5 and abs(rms(pm) - rms(be)) < 0.003 and rms(ee) > 0.5 and rms([-v for v in ee]) < 0.02
for lab, (r, nr) in (("never resample", pf(N, 0)), ("no random push", pf(N, NT, jit=False))):
    e, c = rms([x[0] for x in r]), claim([x[1] for x in r])
    print(f"what breaks, {lab}: ESS at 10 s {r[STEPS][3]:.1f}, distinct particles {r[STEPS][4]}, rms error {e:.4f} / claimed sd {c:.4f} rad")
    assert e > 2 * rms(pm) and c < e / 3
print("ALL CHECKS PASS")
