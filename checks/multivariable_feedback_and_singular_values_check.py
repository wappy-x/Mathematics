# Multivariable feedback and singular values -- the check behind the card.  Standard library only.
# Two drives share one conveyor belt.  Inputs u1, u2: drive speed commands, % of full speed.
# Outputs y1, y2: belt speed at the two drive pulleys, % of the nominal 2.0 m/s (1 % = 0.02 m/s).
# G(s) = g(s) [[1, k h(s)], [k h(s), 1]]: g = 1/(TAU s + 1) drive lag, h = 1/(TC s + 1) belt lag, k = 0.8.
# Roads: singular values three ways; zeros by formula and bisection; RGA by formula and by simulation;
# stability by the generalised Nyquist winding count, by polynomial roots and by RK4 simulation.
from math import sqrt, atan2, pi, log, exp, cos, sin

TAU, TC, KC, KP, KI = 0.2, 0.5, 0.8, 1.0, 5.0      # s, s, coupling, %/%, %/(% s)
def G(s, k=KC):
    g, h = 1 / (TAU * s + 1), 1 / (TC * s + 1)
    return [[g, k * g * h], [k * g * h, g]]
def svals(M):                     # road 1: square roots of the eigenvalues of M^H M (trace, determinant)
    (a, b), (c, d) = M
    p, q = abs(a) ** 2 + abs(b) ** 2 + abs(c) ** 2 + abs(d) ** 2, abs(a * d - b * c) ** 2
    r = sqrt(max(p * p / 4 - q, 0.0)); return sqrt(p / 2 + r), sqrt(max(p / 2 - r, 0.0))
def stretch(M, n=360, m=72):      # road 2: measure |M v| for unit inputs v = (cos t, e^(j f) sin t)
    hi, lo = 0.0, 1e9
    for i in range(n + 1):
        t = pi / 2 * i / n
        for f in range(m):
            v = (cos(t), complex(cos(2 * pi * f / m), sin(2 * pi * f / m)) * sin(t))
            n2 = sqrt(abs(M[0][0] * v[0] + M[0][1] * v[1]) ** 2 + abs(M[1][0] * v[0] + M[1][1] * v[1]) ** 2)
            hi, lo = max(hi, n2), min(lo, n2)
    return hi, lo
def rga11(M):                     # relative gain: loop 1 with loop 2 open, over loop 1 with loop 2 held perfectly
    (a, b), (c, d) = M; return a / (a - b * c / d)
def pmul(p, q):                   # polynomials as coefficient lists, highest power first
    r = [0.0] * (len(p) + len(q) - 1)
    for i, x in enumerate(p):
        for j, y in enumerate(q): r[i + j] += x * y
    return r
def padd(p, q):
    n = max(len(p), len(q)); return [x + y for x, y in zip([0.0] * (n - len(p)) + p, [0.0] * (n - len(q)) + q)]
def roots(p):                     # Durand-Kerner: all roots of a polynomial at once
    p = [c / p[0] for c in p]; n = len(p) - 1
    z = [complex(0.4, 0.9) ** k for k in range(n)]
    for _ in range(500):
        for i in range(n):
            den = 1
            for j in range(n): den *= (z[i] - z[j]) if j != i else 1
            z[i] -= sum(c * z[i] ** (n - k) for k, c in enumerate(p)) / den
    return sorted((complex(r.real, r.imag if abs(r.imag) > 1e-6 else 0.0) for r in z), key=lambda r: (round(r.real, 6), r.imag))
def closed_poly(swap, k=KC, kp=KP, ki=KI):  # det(s d I + N kn) with d = (TAU s+1)(TC s+1), kn = kp s + ki
    sd, kn = pmul([TAU, 1.0], pmul([TC, 1.0], [1.0, 0.0])), [kp, ki]
    diag, off = padd(sd, pmul([TC, 1.0], kn)), pmul([k], kn)
    if swap: diag, off = padd(sd, pmul([k], kn)), pmul([TC, 1.0], kn)
    return padd(pmul(diag, diag), [-c for c in pmul(off, off)])
def winding(swap):                # generalised Nyquist: turns of det(I + G K) round 0, contour indented at s = 0
    pts = [complex(0, -10 ** (4 - 8 * i / 4000)) for i in range(4001)]
    pts += [1e-4 * complex(cos(a), sin(a)) for a in (-pi / 2 + pi * i / 2000 for i in range(1, 2000))]
    pts += [complex(0, 10 ** (-4 + 8 * i / 4000)) for i in range(4001)]
    total, prev = 0.0, None
    for s in pts:
        kk, ((a, b), (c, d)) = KP + KI / s, G(s)
        if swap: a, b, c, d = b, a, d, c                     # K = k(s) [[0, 1], [1, 0]]: columns swap
        v = (1 + a * kk) * (1 + d * kk) - b * c * kk * kk
        if prev is not None: q = v / prev; total += atan2(q.imag, q.real)
        prev = v
    return round(-total / (2 * pi))   # clockwise turns
def simulate(mode, eps1=0.0, r=(1.0, 0.0), t_end=30.0, dt=1e-3):
    """RK4.  States: drive lags a1, a2; belt lags b1, b2; PI integrals z1, z2; decoupler lags p1, p2."""
    def f(x):
        a1, a2, b1, b2, z1, z2, p1, p2 = x
        y1, y2 = a1 + KC * b2, a2 + KC * b1
        e1, e2 = r[0] - y1, r[1] - y2
        w1, w2 = KP * e1 + KI * z1, KP * e2 + KI * z2
        u1, u2 = (w2, w1) if mode == "swap" else (w1, w2)
        if mode == "decoupled": u1, u2 = w1 - KC * p1, w2 - KC * p2   # D(s) = [[1, k h], [k h, 1]]^-1
        return [((1 + eps1) * u1 - a1) / TAU, (u2 - a2) / TAU, (a1 - b1) / TC, (a2 - b2) / TC,
                e1, e2, (u2 - p1) / TC, (u1 - p2) / TC], (y1, y2, u1, u2)
    x, log_ = [0.0] * 8, []
    for k in range(int(round(t_end / dt)) + 1):
        d, out = f(x); log_.append((k * dt,) + out)
        k2 = f([a + dt / 2 * v for a, v in zip(x, d)])[0]; k3 = f([a + dt / 2 * v for a, v in zip(x, k2)])[0]
        k4 = f([a + dt * v for a, v in zip(x, k3)])[0]
        x = [a + dt / 6 * (p + 2 * q + 2 * s + t) for a, p, q, s, t in zip(x, d, k2, k3, k4)]
    settle = max((row[0] for row in log_ if abs(row[1] - r[0]) > 0.02), default=0.0) + dt
    return log_, settle, max(abs(row[2]) for row in log_)

G0 = G(0)
s1, s2 = svals(G0); b1_, b2_ = stretch(G0)
print(f"steady gain G(0) = [[{G0[0][0]:.1f}, {G0[0][1]:.1f}], [{G0[1][0]:.1f}, {G0[1][1]:.1f}]] (% per %)")
print(f"singular values: {s1:.4f} together, {s2:.4f} against; condition number {s1 / s2:.4f}; measured {b1_:.4f}, {b2_:.4f}")
assert abs(s1 - (1 + KC)) < 1e-12 and abs(s2 - (1 - KC)) < 1e-12 and abs(b1_ - s1) < 1e-3 and abs(b2_ - s2) < 1e-3
print(f"inputs for a 1 % speed difference: +-{0.5 / s2:.2f} %; for 1 % together: {1 / s1:.4f} % each")
w1 = G(1j); a, b = svals(w1); m1, m2 = stretch(w1)
print(f"at 1 rad/s: |g| = {abs(w1[0][0]):.4f}, |h| = {abs(1 / (TC * 1j + 1)):.4f}; sigma {a:.4f}, {b:.4f}; measured {m1:.4f}, {m2:.4f}")
assert abs(m1 - a) < 2e-3 and abs(m2 - b) < 2e-3
print("chart: w (rad/s), sigma_max, sigma_min, |lambda11|")
for w in (0.01, 0.03, 0.1, 0.3, 1, 3, 10, 30, 100):
    M = G(1j * w); a, b = svals(M); g, h = abs(M[0][0]), 1 / (TC * 1j * w + 1)
    assert abs(a - g * abs(1 + KC * h)) < 1e-9 and abs(b - g * abs(1 - KC * h)) < 1e-9   # road 3: sum and difference
    print(f"chart, {w:6.2f}, {a:.3f}, {b:.3f}, {abs(rga11(M)):.3f}")
lam = rga11(G0)
print(f"RGA at s = 0: lambda11 = {lam:.4f}, lambda12 = {1 - lam:.4f}; 1/lambda11 = {1 / lam:.4f}")
z, found, f = sorted([(-1 + KC) / TC, (-1 - KC) / TC]), [], lambda s: (TC * s + 1) ** 2 - KC ** 2
for lo, hi in ((-1.9999, -1e-9), (-10.0, -2.0001)):      # road 2: bisection on (TC s + 1)^2 - k^2
    for _ in range(80): mid = (lo + hi) / 2; lo, hi = (mid, hi) if f(lo) * f(mid) > 0 else (lo, mid)
    found.append(lo)
Mz = G(z[1])
print(f"transmission zeros: {z[1]:.4f} and {z[0]:.4f} rad/s; bisection {found[0]:.4f}, {found[1]:.4f};"
      f" |G(z) (1, -1)| = {abs(Mz[0][0] - Mz[0][1]):.6f}, sigma_min there {svals(Mz)[1]:.6f}")
assert abs(found[0] - z[1]) < 1e-9 and abs(found[1] - z[0]) < 1e-9 and svals(Mz)[1] < 1e-9
for swap in (False, True):
    rt = roots(closed_poly(swap)); name = "swapped" if swap else "diagonal"
    print(f"{name} pairing: det(I+L) turns clockwise round 0: {winding(swap)}; closed-loop poles "
          + ", ".join(f"{p.real:.4f}{p.imag:+.4f}j" for p in rt))
    assert winding(swap) == sum(1 for p in rt if p.real > 0) == (1 if swap else 0)
print(f"by hand: s^2 + 7 s + 2 -> {(-7 + sqrt(41)) / 2:.4f}, {(-7 - sqrt(41)) / 2:.4f}; s^2 + 7 s + 18 -> -3.5000 +- {sqrt(23) / 2:.4f}j;"
      f" s^2 - 3 s - 2 -> {(3 + sqrt(17)) / 2:.4f}; one swapped loop alone: s^2 + 2 s + 8 -> -1.0000 +- {sqrt(7):.4f}j")
for mode in ("separate", "decoupled"):
    lg, ts, pk2 = simulate(mode)
    e10, e20 = 1 - lg[10000][1], 1 - lg[20000][1]
    print(f"{mode:9s} step r1 = 1 %: y1(0.5 s) = {lg[500][1]:.3f} %, 2% settle {ts:.2f} s, peak |y2| {pk2:.3f} %,"
          f" final u = {lg[-1][3]:.3f}, {lg[-1][4]:.3f} %")
    if mode == "separate":
        print(f"  slow mode from the run: {-log(e10 / e20) / 10:.4f} rad/s; in m/s: y2 peak {pk2 * 0.02:.4f} m/s")
        assert abs(-log(e10 / e20) / 10 - (-7 + sqrt(41)) / 2) < 1e-3 and abs(lg[-1][3] - lam) < 1e-3
    else:
        assert pk2 < 1e-6 and ts < 1.0 and abs(lg[-1][3] - lam) < 5e-3
lg, _, _ = simulate("swap", t_end=4.0); gr = log(abs(lg[4000][1] / lg[3000][1]))
print(f"swapped pairing: y1 at 1 s {lg[1000][1]:.1f} %, at 2 s {lg[2000][1]:.1f} %; growth {gr:.4f} per s")
assert abs(gr - (3 + sqrt(17)) / 2) < 1e-3
(_, tw, dw), (_, _, sw) = simulate("decoupled", -0.2), simulate("separate", -0.2)   # drive 1 really 20 % weak
print(f"drive 1 20 % weak: G (I+E) G^-1 at s = 0 = [[{1 - 0.2 * lam:.4f}, {0.2 * KC * lam:.4f}], [{-0.2 * KC * lam:.4f}, {1 + 0.2 * KC * KC * lam:.4f}]];"
      f" decoupled: y1 settles {tw:.2f} s, peak |y2| {dw:.3f} %; separate: peak |y2| {sw:.3f} %")
LV = [[87.8, -86.4], [108.2, -109.6]]; a, b = svals(LV); lv = rga11(LV)
print(f"distillation LV: sigma {a:.2f}, {b:.4f}; condition number {a / b:.1f}; lambda11 {lv:.2f};"
      f" decoupled loop gain with a 20 % weak input {1 - 0.2 * lv:.2f}")
assert 1 - 0.2 * lam > 0 > 1 - 0.2 * lv                    # small RGA survives the error, large RGA flips a sign
for k in (0.5, 0.95):
    p = [r.real for r in roots(closed_poly(False, k)) if abs(r.imag) < 1e-9]
    print(f"try k = {k}: sigma {1 + k:.2f}, {1 - k:.2f}; condition {(1 + k) / (1 - k):.1f}; lambda11 {rga11(G(0, k)):.3f};"
          f" slowest pole {max(p):.4f} rad/s")
print("ALL CHECKS PASS")
