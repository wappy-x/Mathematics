# RTS smoothing and square-root filters on the balancing pendulum -- the check behind the card. Standard library only. Roads: RTS
# vs batch conditioning on all 50 readings, both vs 2000 simulated runs; single-precision updates vs double precision.
import math, struct; from functools import reduce
L, SA, SR, N = 9.81 / 16, 1.0, 0.005, 50                 # pole (m); push sd (rad/s^2); encoder sd (rad); readings at 100 Hz
ch, sh = math.cosh(0.04), math.sinh(0.04)
F, g = [[ch, sh / 4], [4 * sh, ch]], [(ch - 1) / 16, sh / 4]   # one 0.01 s step; what a 1 rad/s^2 push adds
G, R, P0, M64 = [-g[0] / L, -g[1] / L], SR * SR, [[0.0025, 0.0], [0.0, 0.25]], (1 << 64) - 1
def Qm(q): return [[q * SA * SA * g[i] * g[j] for j in range(2)] for i in range(2)]
class Rng:                                                  # SplitMix64 bits, Box-Muller normals (as on The Kalman filter)
    def __init__(s, seed): s.s = seed
    def u(s):
        s.s = (s.s + 0x9E3779B97F4A7C15) & M64
        z = ((s.s ^ (s.s >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return ((z ^ (z >> 31)) >> 11) / 2.0 ** 53
    def n(s): a = 1.0 - s.u(); return math.sqrt(-2.0 * math.log(a)) * math.cos(2.0 * math.pi * s.u())
def tot(it): return reduce(lambda a, b: a + b, it, 0.0)     # plain left-to-right sum, as in Rust
def mm(A, B): return [[A[i][0] * B[0][j] + A[i][1] * B[1][j] for j in range(2)] for i in range(2)]
def tr(A): return [[A[0][0], A[1][0]], [A[0][1], A[1][1]]]
def add(A, B, s=1.0): return [[A[i][j] + s * B[i][j] for j in range(2)] for i in range(2)]
def inv(A): d = A[0][0] * A[1][1] - A[0][1] * A[1][0]; return [[A[1][1] / d, -A[0][1] / d], [-A[1][0] / d, A[0][0] / d]]
def mv(A, v): return [A[0][0] * v[0] + A[0][1] * v[1], A[1][0] * v[0] + A[1][1] * v[1]]
def fstep(x, P, u, y, q=1.0):                              # one predict-and-correct step of The Kalman filter
    xm = [a + b * u for a, b in zip(mv(F, x), G)]; Pm = add(mm(mm(F, P), tr(F)), Qm(q))
    S = Pm[0][0] + R; K = [Pm[0][0] / S, Pm[1][0] / S]; nu = y - xm[0]
    return xm, Pm, [xm[0] + K[0] * nu, xm[1] + K[1] * nu], [[Pm[i][j] - K[i] * Pm[0][j] for j in range(2)] for i in range(2)]
def filt(ys, us, q=1.0):                                    # forward pass; index 0 is the start, 1..N the readings
    xf, Pf, xm, Pm = [[0.0, 0.0]], [P0], [None], [None]
    for k in range(1, N + 1):
        a, b, c, d = fstep(xf[-1], Pf[-1], us[k], ys[k], q); xm.append(a); Pm.append(b); xf.append(c); Pf.append(d)
    return xf, Pf, xm, Pm
def smooth(xf, Pf, xm, Pm, us, use_u=True):                 # the RTS backward pass
    xs, Ps, Cs = [None] * N + [xf[N]], [None] * N + [Pf[N]], [None] * (N + 1)
    for k in range(N - 1, -1, -1):
        C = mm(mm(Pf[k], tr(F)), inv(Pm[k + 1])); Cs[k] = C
        pred = xm[k + 1] if use_u else mv(F, xf[k])
        d = mv(C, [xs[k + 1][0] - pred[0], xs[k + 1][1] - pred[1]]); xs[k] = [xf[k][0] + d[0], xf[k][1] + d[1]]
        Ps[k] = add(Pf[k], mm(mm(C, add(Ps[k + 1], Pm[k + 1], -1.0)), tr(C)))
    return xs, Ps, Cs
def run(seed):                                              # the cart balances on the right filter's estimates
    r = Rng(seed); t = [0.05 * r.n(), 0.5 * r.n()]; ts, ys, us = [t], [0.0], [0.0]; x, P = [0.0, 0.0], P0
    for k in range(1, N + 1):
        u = L * (32 * x[0] + 8 * x[1]); w = SA * r.n()
        t = [a + b * u + c * w for a, b, c in zip(mv(F, t), G, g)]; y = t[0] + SR * r.n()
        ts.append(t); ys.append(y); us.append(u); _, _, x, P = fstep(x, P, u, y)
    return ts, ys, us
def batch(ys, us):                                          # condition the joint normal law of all states on all readings
    Fp, m, Sg = [[[1.0, 0.0], [0.0, 1.0]]], [[0.0, 0.0]], [P0]
    for k in range(1, N + 1):
        Fp.append(mm(F, Fp[-1])); m.append([a + b * us[k] for a, b in zip(mv(F, m[-1]), G)]); Sg.append(add(mm(mm(F, Sg[-1]), tr(F)), Qm(1.0)))
    def cxy(k, i):                                          # covariance of state k with reading i
        if i <= k: M = mm(Fp[k - i], Sg[i]); return (M[0][0], M[1][0])
        M = mm(Fp[i - k], Sg[k]); return (M[0][0], M[0][1])
    A = [[cxy(j, i)[0] + (R if i == j else 0.0) for j in range(1, N + 1)] for i in range(1, N + 1)]
    Lc = [[0.0] * N for _ in range(N)]                      # Cholesky A = Lc Lc^T, then two triangular solves
    for i in range(N):
        for j in range(i + 1):
            s = A[i][j] - tot(Lc[i][p] * Lc[j][p] for p in range(j))
            Lc[i][j] = math.sqrt(s) if i == j else s / Lc[j][j]
    def solve(b):                                           # forward, then backward substitution
        z = [0.0] * N
        for i in range(N): z[i] = (b[i] - tot(Lc[i][p] * z[p] for p in range(i))) / Lc[i][i]
        for i in range(N - 1, -1, -1): z[i] = (z[i] - tot(Lc[p][i] * z[p] for p in range(i + 1, N))) / Lc[i][i]
        return z
    a, out = solve([ys[i] - m[i][0] for i in range(1, N + 1)]), []
    for k in range(N + 1):                                  # mean and the two variances of state k given every reading
        c = [cxy(k, i) for i in range(1, N + 1)]; bb = [solve([v[j] for v in c]) for j in range(2)]
        out.append(([m[k][j] + tot(c[i][j] * a[i] for i in range(N)) for j in range(2)], [Sg[k][j][j] - tot(c[i][j] * bb[j][i] for i in range(N)) for j in range(2)]))
    return out
def sci(v): m, e = f"{v:.3e}".split("e"); return f"{m}e{int(e)}"
# ---- one record of 50 readings (seed 1): forward filter, backward pass, batch conditioning ----
ts, ys, us = run(1); xf, Pf, xm, Pm = filt(ys, us); xs, Ps, Cs = smooth(xf, Pf, xm, Pm, us); bt = batch(ys, us)
C, D = Cs[49], add(Ps[50], Pm[50], -1.0); T = [C[1][0] ** 2 * D[0][0], 2 * C[1][0] * C[1][1] * D[0][1], C[1][1] ** 2 * D[1][1]]
for lab, v in [("reading 1 (rad)", ys[1]), ("C49 rate<-angle (1/s)", C[1][0]), ("C49 rate<-rate", C[1][1]),
               ("D50 angle var x1e6", 1e6 * D[0][0]), ("D50 angle-rate cov x1e6", 1e6 * D[0][1]), ("D50 rate var x1e6", 1e6 * D[1][1]),
               ("term c10^2 D00 x1e6", 1e6 * T[0]), ("term 2 c10 c11 D01 x1e6", 1e6 * T[1]), ("term c11^2 D11 x1e6", 1e6 * T[2]),
               ("step 49 filtered rate var x1e6", 1e6 * Pf[49][1][1]), ("step 49 smoothed rate var x1e6", 1e6 * Ps[49][1][1]),
               ("  by batch conditioning", 1e6 * bt[49][1][1]), ("step 50 angle: smoothed - predicted", xs[50][0] - xm[50][0]),
               ("step 50 rate: smoothed - predicted", xs[50][1] - xm[50][1]), ("step 49 filtered rate (rad/s)", xf[49][1]),
               ("step 49 smoothed rate (rad/s)", xs[49][1]), ("  by batch conditioning", bt[49][0][1]), ("step 49 true rate (rad/s)", ts[49][1])]: print(f"{lab:<40} {v:>12.6f}")
gap = max(max(abs(xs[k][j] - bt[k][0][j]) for j in range(2)) + max(abs(Ps[k][j][j] - bt[k][1][j]) for j in range(2)) for k in range(N + 1))
print(f"largest gap, RTS vs batch, over all 51 steps   {sci(gap)}")
print("step              " + " ".join(f"{k:6d}" for k in range(5, N + 1, 5)))
for lab, P in [("rate sd, filtered ", Pf), ("rate sd, smoothed ", Ps)]: print(lab + " ".join(f"{math.sqrt(P[k][1][1]):6.3f}" for k in range(5, N + 1, 5)))
for lab, X in [("seed 1 true rate  ", ts), ("seed 1 filter rate", xf), ("seed 1 smooth rate", xs)]: print(lab + " ".join(f"{X[k][1]:6.2f}" for k in range(5, N + 1, 5)))
print("step 25 rate variance, smoothed / filtered, Q x1 x10 x100:", *(f"{smooth(*f, us)[1][25][1][1] / f[1][25][1][1]:.3f}" for f in (filt(ys, us, q) for q in (1.0, 10.0, 100.0))))
# ---- 2000 records: actual errors against the claimed sd, and two broken smoothers ----
acc, n = [0.0] * 4, 0
for seed in range(1, 2001):
    ts, ys, us = run(seed); fw, fq = filt(ys, us), filt(ys, us, 0.01); n += N
    for i, e in enumerate([fw[0], smooth(*fw, us)[0], smooth(*fw, us, False)[0], smooth(*fq, us)[0]]): acc[i] += tot((e[k][1] - ts[k][1]) ** 2 for k in range(1, N + 1))
cl = [math.sqrt(tot(P[k][1][1] for k in range(1, N + 1)) / N) for P in (Pf, Ps, Ps, smooth(*filt(ys, us, 0.01), us)[1])]
st, NM = [math.sqrt(a / n) for a in acc], ["forward filter", "RTS smoother", "smoother, G u left out", "smoother, Q 100x too small"]
for nm, e, c in zip(NM, st, cl): print(f"{nm:<27} rate rms {e:.4f}  claimed {c:.4f} rad/s")
# ---- single precision: a precise encoder (R = 1e-8 rad^2), no modelled push (Q = 0), 300 steps of the covariance alone ----
def f32(x): return struct.unpack("f", struct.pack("f", x))[0]
def rot(M, r):                                              # Givens rotations on columns: lower-triangular T with T T^T = M M^T
    M = [row[:] for row in M]
    for i in range(len(M)):
        for k in range(i + 1, len(M[0])):
            a, b = M[i][i], M[i][k]
            if b == 0.0: continue
            h = r(math.sqrt(r(r(a * a) + r(b * b)))); c, s = r(a / h), r(b / h)
            for row in M: row[i], row[k] = r(r(c * row[i]) + r(s * row[k])), r(r(c * row[k]) - r(s * row[i]))
    return M
def lmin(P):                                                # smallest eigenvalue of the symmetric part, as det / largest
    a, b, d = P[0][0], (P[0][1] + P[1][0]) / 2, P[1][1]; return (a * d - b * b) / ((a + d + math.sqrt((a - d) ** 2 + 4 * b * b)) / 2)
def cov32(form, r, steps=300, Rv=1e-8):
    Ff, Rf, P, Lf, sR, first, out = [[r(v) for v in row] for row in F], r(Rv), [[r(P0[0][0]), 0.0], [0.0, r(P0[1][1])]], [[r(0.05), 0.0], [0.0, r(0.5)]], r(math.sqrt(Rv)), None, {}
    for k in range(1, steps + 1):
        if form == "square root":                           # predict: rotate [F L]; correct: rotate [[sqrt R, H L], [0, L]]
            FL = [[r(r(Ff[i][0] * Lf[0][j]) + r(Ff[i][1] * Lf[1][j])) for j in range(2)] for i in range(2)]
            Lm = rot(FL, r); post = rot([[sR, Lm[0][0], 0.0], [0.0, Lm[0][0], 0.0], [0.0, Lm[1][0], Lm[1][1]]], r)
            Lf = [[post[1][1], 0.0], [post[2][1], post[2][2]]]; P = mm(Lf, tr(Lf))
        else:
            FP = [[r(r(Ff[i][0] * P[0][j]) + r(Ff[i][1] * P[1][j])) for j in range(2)] for i in range(2)]
            Pm = [[r(r(FP[i][0] * Ff[j][0]) + r(FP[i][1] * Ff[j][1])) for j in range(2)] for i in range(2)]
            S = r(Pm[0][0] + Rf); K = [r(Pm[0][0] / S), r(Pm[1][0] / S)]
            if form == "plain": P = [[r(Pm[i][j] - r(K[i] * Pm[0][j])) for j in range(2)] for i in range(2)]
            else:                                           # Joseph: (I - K H) P- (I - K H)^T + K R K^T
                A = [[r(1.0 - K[0]), 0.0], [r(-K[1]), 1.0]]; AP = [[r(r(A[i][0] * Pm[0][j]) + r(A[i][1] * Pm[1][j])) for j in range(2)] for i in range(2)]
                P = [[r(r(r(AP[i][0] * A[j][0]) + r(AP[i][1] * A[j][1])) + r(r(K[i] * K[j]) * Rf)) for j in range(2)] for i in range(2)]
        if first is None and lmin(P) < 0: first = k
        if k % 50 == 0: out[k] = lmin(P)
    return out, first, P
ref = cov32("plain", lambda v: v); res = {fm: cov32(fm, f32) for fm in ("plain", "Joseph", "square root")}
print("smallest eigenvalue   step " + "".join(f"{k:>11d}" for k in ref[0]))
for nm, (o, fi, _) in [("double precision", ref)] + [(f"single, {fm}", v) for fm, v in res.items()]:
    print(f"{nm:<26} " + "".join(f"{sci(v):>11}" for v in o.values()) + f"   first negative: {fi if fi else 'never'}")
lmx = ref[2][0][0] + ref[2][1][1] - ref[0][300]             # largest eigenvalue: trace minus smallest
print(f"step 300: largest eigenvalue {sci(lmx)}, ratio {sci(lmx / ref[0][300])}; for the factor {sci(math.sqrt(lmx / ref[0][300]))}")
print(f"single-precision unit roundoff {sci(2.0 ** -24)}; per-step shrink of the smallest, steps 250 to 300: {(ref[0][300] / ref[0][250]) ** 0.02:.6f}, e^-0.08 = {math.exp(-0.08):.6f}")
assert gap < 1e-10, "RTS backward pass vs batch conditioning on all 50 readings"
assert all(Ps[k][j][j] < Pf[k][j][j] for k in range(1, N) for j in range(2)) and all(abs(Pf[N][j][j] - bt[N][1][j]) < 1e-12 for j in range(2)), "smoothed below filtered; filter equals batch at the end"
assert all(abs(e / c - 1) < 0.03 for e, c in zip(st[:2], cl[:2])), "simulated errors vs the claimed sd: filter and smoother"
assert st[2] > 3 * cl[2] and st[3] > 3 * cl[3], "broken smoothers claim far less error than they make"
assert all(abs(res["square root"][0][k] / v - 1) < 0.01 for k, v in ref[0].items()), "single-precision square root vs double"
assert ref[1] is None and res["plain"][1] is not None and res["Joseph"][1] is not None, "double holds; plain and Joseph go negative"
assert abs(cov32("square root", lambda v: v)[0][300] / ref[0][300] - 1) < 1e-3, "square-root form vs plain form, both in double"
print("ALL CHECKS PASS")
