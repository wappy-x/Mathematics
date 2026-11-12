# Runge's phenomenon and Chebyshev nodes -- the check behind the card.  Standard library only.
# A resonance peak f(x) = 1/(1 + 25 x^2), x = detuning in MHz from 100.0 MHz, read at 21 frequencies
# and joined by the one polynomial of degree 20 through them: once at equal spacing, once at Chebyshev nodes.
# Roads: Lagrange form; Newton divided differences; the exact error formula for this bell.
from math import cos, sin, pi, log10, log

def e(x, d=3):                                    # e-notation, printed the same way in Rust
    m, p = f"{x:.{d}e}".split("e")
    return m + "e" + str(int(p))
def f(x): return 1.0 / (1.0 + 25.0 * x * x)
def equal(n): return [-1.0 + 2.0 * j / n for j in range(n + 1)]
def cheb(n): return [cos((2 * j + 1) * pi / (2 * n + 2)) for j in range(n + 1)]
def lagrange(xs, ys, x):                          # sum of y_j times the basis l_j(x)
    s = 0.0
    for j in range(len(xs)):
        l = 1.0
        for k in range(len(xs)):
            if k != j:
                l = l * (x - xs[k]) / (xs[j] - xs[k])
        s = s + ys[j] * l
    return s
def newton(xs, ys):                               # divided differences, then nested evaluation
    c, n = list(ys), len(xs)
    for k in range(1, n):
        for j in range(n - 1, k - 1, -1):
            c[j] = (c[j] - c[j - 1]) / (xs[j] - xs[j - k])
    def p(x):
        v = c[n - 1]
        for j in range(n - 2, -1, -1):
            v = v * (x - xs[j]) + c[j]
        return v
    return p
def omega(xs, x):                                 # node polynomial: product of (x - x_j)
    w = 1.0
    for xj in xs:
        w = w * (x - xj)
    return w
def big_p(xs):                                    # P = product over positive nodes of (x_k^2 + 0.04) = 5 |omega(i/5)|
    w = 1.0
    for xj in sorted(xs):
        if xj > 1e-12:
            w = w * (xj * xj + 0.04)
    return w
def exact_err(xs, x): return -x * omega(xs, x) / (big_p(xs) * (x * x + 0.04))  # f - p, symmetric nodes, odd count
GRID = [-1.0 + i / 1000.0 for i in range(2001)]
def worst(xs, g=f, lim=1.0):                      # largest |g - p| on the grid with |x| <= lim, and where
    ys = [g(x) for x in xs]
    return max((abs(g(x) - lagrange(xs, ys, x)), abs(x)) for x in GRID if abs(x) <= lim + 1e-12)

N = 20
xe, xc = equal(N), cheb(N)
ye, yc = [f(x) for x in xe], [f(x) for x in xc]
print(f"degree {N}, {N + 1} readings; equal gap h {xe[1] - xe[0]:.6f}")
print(f"Chebyshev nodes: outer {xc[0]:.6f} {xc[1]:.6f} {xc[2]:.6f}, middle {xc[10]:.6f} {xc[9]:.6f};"
      f" gap at end {xc[0] - xc[1]:.6f}, in middle {xc[9] - xc[10]:.6f}")
we, wc = worst(xe), worst(xc)
print(f"worst error on grid: equal {e(we[0])} at |x| {we[1]:.3f} | Chebyshev {e(wc[0])} at |x| {wc[1]:.3f}")
assert we[0] > 50.0 and wc[0] < 0.02            # the blow-up, and the repair
x = 0.975
pe, pc = lagrange(xe, ye, x), lagrange(xc, yc, x)
print(f"at x {x}: f {f(x):.6f} | equal p {pe:.6f} | Chebyshev p {pc:.6f}")
dn = max(max(abs(lagrange(xs, ys, t) - newton(xs, ys)(t)) for t in GRID) for xs, ys in ((xe, ye), (xc, yc)))
dx = max(max(abs(f(t) - lagrange(xs, ys, t) - exact_err(xs, t)) for t in GRID) for xs, ys in ((xe, ye), (xc, yc)))
print("roads agree on grid: Lagrange vs Newton", e(dn), "| Lagrange vs exact error formula", e(dx))
assert dn < 1e-9 and dx < 1e-9
for name, xs, p in (("equal", xe, pe), ("Chebyshev", xc, pc)):
    w, P, r = omega(xs, x), big_p(xs), x / (x * x + 0.04)
    print(f"hand, {name}: omega(x) {e(w, 6)} P {e(big_p(xs), 6)} x/(x^2+0.04) {r:.6f}"
          f" error {e(-r * w / P, 7)} | f - p {e(f(x) - p, 7)}")
oe = max((abs(omega(xe, t)), abs(t)) for t in GRID)
oc = max(abs(omega(xc, t)) for t in GRID)
print(f"max |omega|: equal {e(oe[0])} at |x| {oe[1]:.3f}, |omega(0.05)| {e(abs(omega(xe, 0.05)))}"
      f" ratio {oe[0] / abs(omega(xe, 0.05)):.0f} | Chebyshev {e(oc)} | 2^-20 {e(2.0 ** -20)}")
assert abs(oc / 2.0 ** -20 - 1.0) < 1e-9 and oe[0] > 100.0 * oc
dt = 0.0
for t in GRID:                                   # T_21 by the recurrence T_(k+1) = 2x T_k - T_(k-1), against 2^20 omega
    a, b = 1.0, t
    for k in range(1, N + 1):
        a, b = b, 2.0 * t * b - a
    dt = max(dt, abs(b - 2.0 ** N * omega(xc, t)))
print("T_21 by recurrence vs 2^20 omega_Chebyshev, max diff", e(dt))
assert dt < 1e-12
rho = 0.2 + (1.04) ** 0.5                         # pole at i/5: rho = 1/5 + sqrt(1 + 1/25)
a, b = 1.0, 0.2                                   # T_k(i/5) = i^k t_k with t_(k+1) = 0.4 t_k + t_(k-1)
for k in range(1, N + 1):
    a, b = b, 0.4 * b + a
print(f"rho {rho:.6f}; |T_21(i/5)| {b:.6f} = (rho^21 - rho^-21)/2 {(rho ** 21 - rho ** -21) / 2:.6f}"
      f" | 2^20 P/5 {2.0 ** N * big_p(xc) / 5:.6f} | equal P {e(big_p(xe))}")
assert abs(b / (2.0 ** N * big_p(xc) / 5) - 1.0) < 1e-12
assert abs((rho ** 21 - rho ** -21) / 2 / b - 1.0) < 1e-12
for name, xs, wo in (("equal", xe, we[0]), ("Chebyshev", xc, wc[0])):
    bound = 2.5 * max(abs(omega(xs, t)) for t in GRID) / big_p(xs)  # max of |x|/(x^2+0.04) is 2.5, at x = 0.2
    print(f"bound {name}: 2.5 max|omega|/P {e(bound)}, true {e(wo)}, ratio true/bound {wo / bound:.3f}")
    assert wo <= bound
print("chart, log10 worst error, n = 4, 8, ..., 40: equal | Chebyshev | equal, |x| <= 0.5 only")
ns = list(range(4, 41, 4))
ce = [worst(equal(n))[0] for n in ns]
cc = [worst(cheb(n))[0] for n in ns]
cm = [worst(equal(n), lim=0.5)[0] for n in ns]
for row in (ce, cc, cm):
    print("  ", " ".join(f"{log10(v):.2f}" for v in row))
assert ce[-1] > 1e4 and cc[-1] < 1e-3 and cm[-1] < cm[0]
obs = (cc[-1] / cc[4]) ** (1.0 / 20.0)            # error shrink per degree, n = 20 to 40
print(f"Chebyshev shrink per degree, n 20 to 40: observed {obs:.4f}, theory 1/rho {1 / rho:.4f}")
assert abs(obs * rho - 1.0) < 0.01
def lebesgue(xs):
    m = 0.0
    for t in GRID:
        s = 0.0
        for j in range(len(xs)):
            s = s + abs(lagrange(xs, [1.0 if k == j else 0.0 for k in range(len(xs))], t))
        m = max(m, s)
    return m
le, lc = lebesgue(xe), lebesgue(xc)
print(f"Lebesgue constant on grid, n=20: equal {le:.1f} | Chebyshev {lc:.4f}, bound 2/pi log 21 + 1 {2 / pi * log(21) + 1:.4f}")
assert le > 1000.0 and lc < 2 / pi * log(21) + 1
print(f"flops per point, n={N}: Lagrange form (n+1)(4n+2) {(N + 1) * (4 * N + 2)} | Newton 3n {3 * N},"
      f" after 3n(n+1)/2 {3 * N * (N + 1) // 2} once | barycentric 5(n+1)+1 {5 * (N + 1) + 1}")
nz = [0.001 * (-1) ** j for j in range(N + 1)]    # reading errors of +-0.001, alternating
print("noise +-0.001, change in p at x 0.975: equal", f"{lagrange(xe, nz, x):.6f}", "| Chebyshev", f"{lagrange(xc, nz, x):.6f}")
print("n=40 worst: equal", e(worst(equal(40))[0]), "| Chebyshev", e(cc[-1]))
for n in (20, 40):
    print(f"break: kink |x| on Chebyshev nodes, n={n} worst {e(worst(cheb(n), g=abs)[0])}")
print("try: wide bell 1/(1 + x^2), equal nodes n=20 worst", e(worst(xe, g=lambda t: 1.0 / (1.0 + t * t))[0]))
print("figure, circle centre (180, 175) radius 150, Chebyshev dots (x, y):",  # x = 180 + 150 cos, y = 175 - 150 sin
      " ".join(f"{180 + 150 * cos((2 * j + 1) * pi / 42):.1f},{175 - 150 * sin((2 * j + 1) * pi / 42):.1f}" for j in range(21)))
print("ALL CHECKS PASS")
