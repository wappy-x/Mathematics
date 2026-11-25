# The direct method -- the check behind the card.  Standard library only.
# A shear-thickening liquid (power-law index 3) flows between two plates 5 cm
# apart, pushed by 1600 Pa/m; consistency 0.01 Pa s^3 (illustrative).  Scaled
# (x by the gap, u by the speed scale) the flow minimises
# J(u) = int_0^1 (u'^4/4 - u) dx with u(0) = u(1) = 0.  Then Bolza's energy
# B(u) = int_0^1 ((u'^2 - 1)^2 + u^2) dx, which has no minimiser.
import math

def cbrt(t): return math.copysign(abs(t) ** (1.0 / 3.0), t)
def sci(v):                                   # 1.234e-05 in both languages
    if v == 0: return "0.000e+00"
    e = math.floor(math.log10(abs(v))); m = v / 10 ** e
    if abs(m) >= 9.9995: m, e = m / 10, e + 1
    return f"{m:.3f}e{'-' if e < 0 else '+'}{abs(e):02d}"
def simpson(f, a, b, n=2000):
    h = (b - a) / n; s = f(a) + f(b)
    for i in range(1, n): s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3

D, MC, F = 0.05, 0.01, 1600.0                 # gap m, consistency Pa s^3, push Pa/m
U = (F * D ** 4 / MC) ** (1 / 3)              # speed scale, m/s
C = 2 ** (-4 / 3)
def u(x): return 0.75 * (C - abs(x - 0.5) ** (4 / 3))
def up(x): return cbrt(0.5 - x)                # u' ; u'^3 = 1/2 - x
peak, area, jmin = 0.75 * C, 3 / 7 * C, -9 / 28 * C
print(f"speed scale U = {U:.4f} m/s; peak {peak:.6f} -> {peak * U:.4f} m/s at mid-gap")
print(f"(1/2)^(4/3) = {C:.6f}; slope at the plates u'(0) = {up(0):.6f}; int u'^2 = {1.2 * 2 ** (-5 / 3):.6f}")
q4 = simpson(lambda x: up(x) ** 4, 0, 0.5) * 2
qa = simpson(u, 0, 0.5) * 2
print(f"int u = {area:.6f} (quadrature {qa:.6f}); int u'^4 = {q4:.6f}; flow {area * D * U * 1000:.3f} L/s per m")
print(f"J(min) = {jmin:.6f} (quadrature {q4 / 4 - qa:.6f}); norm of u' in L^4 = {area ** 0.25:.5f}")
assert abs(qa - area) < 1e-9 and abs(q4 - area) < 1e-6 and abs(q4 / 4 - qa - jmin) < 1e-6
print(f"coercivity: J >= t^4/4 - t >= {-0.75:.4f}; J <= 0 forces t <= {4 ** (1 / 3):.4f}")
assert q4 ** 0.25 <= 4 ** (1 / 3) and q4 / 4 - qa >= -0.75

# Road 2: the direct method on a grid -- Newton steps that only ever lower the energy.
def energy(v, h): return sum(h * ((v[i + 1] - v[i]) / h) ** 4 / 4 - h * v[i + 1] for i in range(len(v) - 1))
def grid(N):
    h = 1 / N; v = [(i * h) * (1 - i * h) for i in range(N + 1)]; hist = [energy(v, h)]
    for it in range(200):
        s = [(v[i + 1] - v[i]) / h for i in range(N)]
        g = [s[j - 1] ** 3 - s[j] ** 3 - h for j in range(1, N)]
        a = [3 * (s[j - 1] ** 2 + s[j] ** 2) / h for j in range(1, N)]
        b = [-3 * s[j] ** 2 / h for j in range(1, N - 1)]
        cp, dp = [0.0] * (N - 1), [0.0] * (N - 1)        # Thomas solve of H d = g
        for j in range(N - 1):
            den = a[j] - (b[j - 1] * cp[j - 1] if j else 0)
            cp[j] = b[j] / den if j < N - 2 else 0
            dp[j] = (g[j] - (b[j - 1] * dp[j - 1] if j else 0)) / den
        d = dp[:]
        for j in range(N - 3, -1, -1): d[j] -= cp[j] * d[j + 1]
        t, e0 = 1.0, hist[-1]
        while True:
            w = [0.0] + [v[j + 1] - t * d[j] for j in range(N - 1)] + [0.0]
            if energy(w, h) <= e0 or t < 1e-12: break
            t /= 2
        v = w; hist.append(energy(v, h))
        assert hist[-1] <= hist[-2] + 1e-15            # the energy never rises
        if max(abs(x) for x in d) * t < 1e-13: break
    return v, hist
def exact_grid(N):                             # discrete Euler-Lagrange, solved by hand
    h = 1 / N; v = [0.0]
    for i in range(N): v.append(v[-1] + h * cbrt(0.5 - (i + 0.5) * h))
    return v
v16, hist = grid(16)
print("grid N=16, energy by Newton step:", " ".join(f"{e:.6f}" for e in hist[:7]), f"... {len(hist) - 1} steps")
errs = []
for N in (16, 32, 64):
    v, _ = grid(N); ve = exact_grid(N)
    gap = max(abs(p - q) for p, q in zip(v, ve)); errs.append(abs(v[N // 2] - peak))
    print(f"grid N={N}: peak {v[N // 2]:.6f}, energy {energy(v, 1 / N):.6f}, peak error {sci(errs[-1])}, Newton = exact grid to 1e-12")
    assert gap < 1e-12 and errs[-1] < 0.01
print(f"observed order: {math.log2(errs[0] / errs[1]):.3f}, {math.log2(errs[1] / errs[2]):.3f}")
assert errs[2] < errs[1] < errs[0]

# Road 3: the Euler-Lagrange equation, weakly and by differences, and rivals cost more.
for k in (1, 3):
    v = lambda x: math.sin(k * math.pi * x); dv = lambda x: k * math.pi * math.cos(k * math.pi * x)
    r = simpson(lambda x: up(x) ** 3 * dv(x) - v(x), 0, 0.5) + simpson(lambda x: up(x) ** 3 * dv(x) - v(x), 0.5, 1)
    print(f"weak form with v = sin({k} pi x): |int (u'^3 v' - v)| below 1e-10")
    assert abs(r) < 1e-10
for hd in (0.01, 0.005):
    x = 0.25; fl = lambda y: ((u(y + hd / 2) - u(y - hd / 2)) / hd) ** 3
    res = -(fl(x + hd / 2) - fl(x - hd / 2)) / hd - 1
    print(f"-(u'^3)' - 1 at x = 0.25 by differences, step {hd}: {sci(res)}")
    assert abs(res) < 1e-3
def J(f, df): return simpson(lambda x: df(x) ** 4 / 4 - f(x), 0, 0.5) + simpson(lambda x: df(x) ** 4 / 4 - f(x), 0.5, 1)
for t in (0.1, -0.1):
    gp = J(lambda x: u(x) + t * math.sin(math.pi * x), lambda x: up(x) + t * math.pi * math.cos(math.pi * x)) - jmin
    print(f"rival u + ({t:+.1f}) sin(pi x): energy higher by {gp:.6f}")
    assert gp > 0
for dd in (0.01, 0.0001):                      # u'' = -(1/3)|x - 1/2|^(-2/3) blows up at the middle
    fd = (up(0.5 - dd + dd / 100) - up(0.5 - dd - dd / 100)) / (dd / 50)
    print(f"u'' at {dd} from the middle: {fd:.3f} by differences, {-(dd ** (-2 / 3)) / 3:.3f} by formula")
    assert abs(fd + dd ** (-2 / 3) / 3) < 1e-3 * dd ** (-2 / 3)

# Weak lower semicontinuity: wiggles of slope +-0.5 shrink to nothing, energy drops.
A = 0.5
lim = jmin + 1.5 * A * A * 1.2 * 2 ** (-5 / 3) + A ** 4 / 4
for n in (4, 16, 64):
    tot = 0.0
    for i in range(2 * n):                     # exact: int_a^b u'^k = 3/(k+3) (u'(a)^(k+3) - u'(b)^(k+3))
        a0, b0, sg = i / (2 * n), (i + 1) / (2 * n), 1 if i % 2 == 0 else -1
        I = [3 / (k + 3) * (up(a0) ** (k + 3) - up(b0) ** (k + 3)) for k in range(5)]  # u = (3/4)(C - u'^4)
        tot += sum(math.comb(4, k) * (sg * A) ** (4 - k) * I[k] for k in range(5)) / 4 - 0.75 * (C * I[0] - I[4]) - A * I[0] ** 2 / 2
    print(f"u + zigzag, slope +-{A}, {n} teeth: energy {tot:.6f}")
print(f"limit of those energies {lim:.6f} >= energy of the limit {jmin:.6f}")
assert abs(tot - lim) < 0.01 * A and tot > jmin

# Bolza: zigzags of slope +-1 and n teeth; B = 1/(12 n^2) -> 0, never reached.
def bolza(s, w): return (s * s - 1) ** 2 + w * w
for n in (1, 10, 100):
    bq = sum(simpson(lambda x: bolza(1.0, x - i / (2 * n) if i % 2 == 0 else (i + 1) / (2 * n) - x),
                     i / (2 * n), (i + 1) / (2 * n), 2) for i in range(2 * n))
    print(f"Bolza zigzag n={n}: B = {sci(bq)} (formula {sci(1 / (12 * n * n))}); measurement int u' x dx = {-1 / (4 * n):.4f}")
    assert abs(bq - 1 / (12 * n * n)) < 1e-12
print(f"Bolza at the limit u = 0: B = {simpson(lambda x: bolza(0.0, 0.0), 0, 1):.4f}; convexified integrand at slope 0: {max(0.0, 0.0 - 1) ** 2:.4f}")
for e in (0.1, 0.01, 0.001):                    # slopes cost only |u'|: ramp of width e to u(1) = 1
    r = simpson(lambda x: 1 / e + ((x - 1 + e) / e) ** 2, 1 - e, 1, 2)
    print(f"p = 1, int (|u'| + u^2), ramp width {e}: {r:.6f} (formula {1 + e / 3:.6f})")
    assert abs(r - 1 - e / 3) < 1e-12
print(f"no fixed ends, J(constant 10) = {simpson(lambda x: 0.0 ** 4 / 4 - 10.0, 0, 1):.4f}")
pk = lambda f, d: 0.75 * C * (f * d ** 4 / MC) ** (1 / 3)
print(f"try: push 3200 Pa/m -> peak {pk(3200, D):.4f} m/s; gap 10 cm -> peak {pk(F, 0.1):.4f} m/s;"
      f" grid N=128 peak error {sci(abs(grid(128)[0][64] - peak))}; wiggle slope 1 -> limit {jmin + 1.5 * 1.2 * 2 ** (-5 / 3) + 0.25:.6f}")
print("chart, minimiser:", " ".join(f"{u(i / 10):.4f}" for i in range(11)))
print("chart, parabola of equal peak:", " ".join(f"{4 * peak * (i / 10) * (1 - i / 10):.4f}" for i in range(11)))
print("chart, zigzag n=2:", " ".join(f"{min(i % 4, 4 - i % 4) / 8:.4f}" for i in range(9)))
print("chart, zigzag n=4:", " ".join(f"{(i % 2) / 8:.4f}" for i in range(9)))
print("ALL CHECKS PASS")
