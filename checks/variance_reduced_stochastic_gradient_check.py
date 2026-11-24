# SVRG and SAGA -- the check behind the card.  Standard library only.
# A 10-stock index tracker refit on 250 daily returns (synthetic, SplitMix64 seed 2026).
# The card MINIMISES f(w) = average over days of (1/2)(tracker return - index return)^2,
# in percent squared, with the weights summing to 1.  Put w10 = 1 - (w1 + ... + w9): the
# free variables are v = (w1, ..., w9) and day t's loss is f_t(v) = (1/2)(a_t . v - b_t)^2.
import functools, math
M64 = (1 << 64) - 1
class Rng:                                  # SplitMix64, written out so Rust can match it
    def __init__(self, seed): self.s = seed
    def next(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64; z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return z ^ (z >> 31)
    def u(self): return (self.next() >> 11) * 2.0 ** -53
N, S, D, R3, rng = 250, 10, 9, 1.7320508075688772, Rng(2026)
beta = [0.8 + 0.4 * rng.u() for _ in range(S)]       # each stock's market sensitivity
sig = [1.0 + rng.u() for _ in range(S)]              # its own noise, sd in % a day
A, B = [], []
for t in range(N):
    m = 0.04 + R3 * (2 * rng.u() - 1)                # market move, % (sd 1)
    r = [beta[j] * m + sig[j] * R3 * (2 * rng.u() - 1) for j in range(S)]
    y = m + 0.3 * R3 * (2 * rng.u() - 1)             # the index's return, %
    A.append([r[j] - r[S - 1] for j in range(D)]); B.append(y - r[S - 1])
def tot(xs): return functools.reduce(lambda s, x: s + x, xs, 0.0)   # left to right, as in Rust
def dot(u, v): return tot(p * q for p, q in zip(u, v))
def res(t, v): return dot(A[t], v) - B[t]           # day t's miss, %; its gradient is res * a_t
def full(v): q = [res(t, v) for t in range(N)]; return [tot(q[t] * A[t][k] / N for t in range(N)) for k in range(D)]   # N calls
def fval(v): return tot(res(t, v) ** 2 / (2 * N) for t in range(N))
H = [[dot([A[t][i] for t in range(N)], [A[t][j] for t in range(N)]) / N for j in range(D)] for i in range(D)]
def mul(v): return [dot(H[k], v) for k in range(D)]
def solve(b):                                        # H x = b by Gaussian elimination, partial pivots
    M = [H[i][:] + [b[i]] for i in range(D)]
    for k in range(D):
        p = max(range(k, D), key=lambda r: abs(M[r][k])); M[k], M[p] = M[p], M[k]
        for r in range(k + 1, D):
            f = M[r][k] / M[k][k]
            for q in range(k, D + 1): M[r][q] -= f * M[k][q]
    x = [0.0] * D
    for k in range(D - 1, -1, -1): x[k] = (M[k][D] - dot(M[k][k + 1:D], x[k + 1:D])) / M[k][k]
    return x
vs = solve([dot([A[t][i] for t in range(N)], B) / N for i in range(D)]); fs = fval(vs)
def gap(v):                                          # f(v) - f*, exact for a quadratic
    e = [v[k] - vs[k] for k in range(D)]; return 0.5 * dot(e, mul(e))
def unit(x): n = math.sqrt(dot(x, x)); return [q / n for q in x]
x, z = [1.0] * D, [1.0] * D
for _ in range(300): x, z = unit(solve(x)), unit(mul(z))      # inverse and plain power iteration
mu, Lf = 1 / math.sqrt(dot(solve(x), solve(x))), math.sqrt(dot(mul(z), mul(z)))
Lmax = max(dot(A[t], A[t]) for t in range(N))                  # the steepest single day
sig2 = tot(res(t, vs) ** 2 * dot(A[t], A[t]) / N for t in range(N))   # SGD's noise at the optimum
w, v0 = vs + [1.0 - dot(vs, [1.0] * D)], [0.1] * D
print("optimal weights, %:", " ".join("%.2f" % (100 * q) for q in w))
print("f* = %.4f, tracking error sqrt(2 f*) = %.4f %% a day" % (fs, math.sqrt(2 * fs)))
print("start (equal weights): f - f* = %.6f by subtraction, %.6f by the quadratic form" % (fval(v0) - fs, gap(v0)))
print("L_max %.2f  L_f %.2f  mu %.4f  kappa_max %.1f  kappa_f %.1f  sigma^2 %.4f" % (Lmax, Lf, mu, Lmax / mu, Lf / mu, sig2))
print("steps: 0.1/L_max = %.6f, 1/(2 L_max) = %.6f, 1/(3 L_max) = %.6f, 1/L_f = %.4f" % (0.1 / Lmax, 0.5 / Lmax, 1 / (3 * Lmax), 1 / Lf))
assert min(w) > 0 and max(abs(q) for q in full(vs)) < 1e-12 and abs(fval(v0) - fs - gap(v0)) < 1e-12
d = [lambda x: 2 * (x - 1), lambda x: 2 * (x + 1)]  # by hand: f1 = (x-1)^2, f2 = (x+1)^2, f'(x) = 2x
for x, s in ((0.0, 0.0), (0.5, 0.0), (0.25, 0.5)):  # the point, and where the stored slopes were taken
    e, sgv = [g(x) - g(s) + (d[0](s) + d[1](s)) / 2 for g in d], ((d[0](x) - 2 * x) ** 2 + (d[1](x) - 2 * x) ** 2) / 2
    print("hand x = %.2f, stored at %.1f: SGD %+.1f %+.1f (variance %.0f), corrected %+.1f %+.1f, f'(x) %+.1f" % (x, s, d[0](x), d[1](x), sgv, e[0], e[1], 2 * x))
    assert e[0] == e[1] == 2 * x and sgv == 4
def table(pts): return [res(t, p) for t, p in enumerate(pts)]   # each day's miss at its stored point
def variance(v, tab):                                # mean square of (estimate - grad f) over the day drawn
    gv, gs, sg, sv = full(v), [tot(tab[t] * A[t][k] / N for t in range(N)) for k in range(D)], 0.0, 0.0
    for t in range(N):
        q, p = res(t, v), tab[t]
        e1 = [q * A[t][k] - gv[k] for k in range(D)]; e2 = [(q - p) * A[t][k] + gs[k] - gv[k] for k in range(D)]
        sg += dot(e1, e1) / N; sv += dot(e2, e2) / N
    return sg, sv
for name, v, snap in (("start, snapshot start", v0, v0), ("optimum, snapshot start", vs, v0), ("optimum, snapshot optimum", vs, vs)):
    sg, sv = variance(v, table([snap] * N)); bound = 4 * Lmax * (gap(v) + gap(snap))
    print("variance at %-25s SGD %.4f  SVRG %.6f  bound %.6f" % (name, sg, sv, bound))
    assert sv <= bound + 1e-12
assert abs(variance(vs, table([vs] * N))[0] - sig2) < 1e-12 and variance(vs, table([v0] * N))[1] > 0
for name, pts in (("at the start", [v0] * N), ("half at optimum", [vs if t % 2 else v0 for t in range(N)]), ("at the optimum", [vs] * N)):
    sv = variance(vs, table(pts))[1]; bound = 4 * Lmax * gap(vs) + 2 * tot((res(t, p) - res(t, vs)) ** 2 * dot(A[t], A[t]) / N for t, p in enumerate(pts))
    print("variance at optimum, SAGA table %-15s SAGA %.6f  bound %.6f" % (name, sv, bound)); assert sv <= bound + 1e-12
def run(method, calls, alpha, m=500, refresh=True, snap_days=N, avg=False, seed=7):
    r, v, c, marks, epochs = Rng(seed), v0[:], 0, [gap(v0)], []   # marks: gap every 1000 calls
    snap, gs, tab, tavg = v0[:], None, None, None
    def tick(n, u):
        nonlocal c
        for _ in range(n):
            c += 1
            if c % 1000 == 0: marks.append(gap(u))
    while c < calls:
        if method == "gd": g = full(v); v = [v[k] - alpha * g[k] for k in range(D)]; tick(N, v)
        elif method == "sgd":
            t = r.next() % N; q = res(t, v); v = [v[k] - alpha * q * A[t][k] for k in range(D)]; tick(1, v)
        elif method == "saga" and tab is None: tab = [res(t, v) for t in range(N)]; tavg = full(v); tick(N, v)
        elif method == "saga":                       # the table holds each day's miss at its last visit
            t = r.next() % N; q = res(t, v); dq = q - tab[t]; tab[t] = q
            v = [v[k] - alpha * (dq * A[t][k] + tavg[k]) for k in range(D)]
            tavg = [tavg[k] + dq * A[t][k] / N for k in range(D)]; tick(1, v)
        else:                                        # svrg: one epoch of m inner steps
            if gs is None or refresh:
                days = [r.next() % N for _ in range(snap_days)] if snap_days < N else list(range(N))
                gs = [0.0] * D
                for t in days:
                    q = res(t, snap)
                    for k in range(D): gs[k] += q * A[t][k] / len(days)
                tick(snap_days, snap)
            v, acc = snap[:], [0.0] * D
            for _ in range(m):
                acc = [acc[k] + v[k] / m for k in range(D)]
                t = r.next() % N; q = res(t, v) - res(t, snap)
                v = [v[k] - alpha * (q * A[t][k] + gs[k]) for k in range(D)]; tick(2, v)
            if refresh: snap = acc if avg else v[:]
            epochs.append(gap(snap))
    return marks, epochs, gap(v)
a = 0.1 / Lmax
runs = [("GD, step 1/L_f", run("gd", 10000, 1 / Lf)), ("SGD, step 0.1/L_max", run("sgd", 10000, a)),
        ("SVRG, step 0.1/L_max, m 500", run("svrg", 10000, a)), ("SAGA, step 1/(3 L_max)", run("saga", 10000, 1 / (3 * Lmax)))]
print("log10(f - f*) after 0, 1000, ..., 10000 gradient calls:")
for name, h in runs: print("%-28s" % name, " ".join("%.2f" % math.log10(q) for q in h[0]))
end = [h[2] for _, h in runs]; assert end[2] < 1e-3 * end[1] and end[2] < end[0] and end[3] < end[2]
r, v, fl = Rng(11), vs[:], 0.0                       # SGD's floor: time average from the optimum
for k in range(200000):
    t = r.next() % N; q = res(t, v); v = [v[j] - a * q * A[t][j] for j in range(D)]; fl += gap(v) / 200000
print("SGD floor at step 0.1/L_max: time average %.6f, formula alpha sigma^2 / 4 = %.6f" % (fl, a * sig2 / 4))
assert abs(fl / (a * sig2 / 4) - 1) < 0.1
def ratio(al, m): return 1 / (mu * al * (1 - 2 * Lmax * al) * m) + 2 * Lmax * al / (1 - 2 * Lmax * al)   # the theorem's R
assert abs(ratio(0.1 / Lmax, 20 * Lmax / mu) - 0.875) < 1e-12              # the textbook setting, by hand: 1/1.6 + 1/4
for m in (500, math.ceil(20 * Lmax / mu)):          # the epoch theorem, snapshot = the epoch's average
    bound = ratio(a, m)
    ep = run("svrg", 6 * (N + 2 * m), a, m=m, avg=True, seed=5)[1]
    meas = (ep[-1] / gap(v0)) ** (1 / len(ep))
    print("m = %d (%d calls an epoch): theorem's ratio %.4f; measured, mean of %d epochs %.4f" % (m, N + 2 * m, bound, len(ep), meas))
    assert meas < 1 and (bound > 1 or meas <= bound)
stale, batch = run("svrg", 10000, a, refresh=False)[2], run("svrg", 10000, a, snap_days=25)[2]
big = run("svrg", 2500, 5 / Lmax)[2]                 # far past the theorem's step limit 1/(2 L_max)
print("SVRG gap: snapshot never refreshed %.6f; snapshot gradient from 25 days %.6f; step 5/L_max %.1f" % (stale, batch, big))
assert stale > 1e3 * end[2] and batch > gap(v0) and big > 1e5 * gap(v0); need = []
for name, h in (("GD", run("gd", 60000, 1 / Lf)), ("SVRG", run("svrg", 60000, a)), ("SAGA", run("saga", 60000, 1 / (3 * Lmax)))):
    need.append(1000 * min(i for i, q in enumerate(h[0]) if q < 1e-10)); print("calls to reach f - f* < 1e-10: %s %d" % (name, need[-1]))
print("calls per factor e in the bounds: GD n kappa_f = %.0f; SVRG, SAGA of order n + kappa_max = %.0f" % (N * Lf / mu, N + Lmax / mu))
print("SAGA bound per step: 1 - min(1/(4n) = %.6f, mu/(3 L_max) = %.6f)" % (1 / (4 * N), mu / (3 * Lmax)))
assert need[2] < need[1] < need[0]; print("SAGA table: %d numbers here (one miss a day); a general gradient table for 2,000 assets: %d" % (N, N * 2000))
print("ALL CHECKS PASS")
