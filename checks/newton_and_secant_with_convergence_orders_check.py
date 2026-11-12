# Newton and secant: the check behind the card.  Standard library only.
# Solve x^3 = 2 (the side of a cube that holds 2 cubic metres) both ways, measure
# each error against a bisection root, and test the error laws and the orders.
from math import log, log10, sqrt
def sci(v, d=2):                              # 1.23e-10, the form Rust prints
    m, e = f"{v:.{d}e}".split("e")
    return f"{m}e{int(e)}"
def bisect(f, a, b):                          # road one: signs only, to the last bit
    n = 0
    while a < (a + b) / 2 < b:
        c = (a + b) / 2
        a, b = (c, b) if (f(c) < 0) == (f(a) < 0) else (a, c)
        n += 1
    return (a if abs(f(a)) <= abs(f(b)) else b), n
def newton(f, df, x, steps):                  # stops if it lands on a zero of f
    xs = [x]
    for _ in range(steps):
        if f(xs[-1]) == 0: break
        xs.append(xs[-1] - f(xs[-1]) / df(xs[-1]))
    return xs
def secant(f, x0, x1, steps):                 # stops if the chord is flat
    xs, fs = [x0, x1], [f(x0), f(x1)]
    for _ in range(steps):
        d = fs[-1] - fs[-2]
        if d == 0: return xs, len(xs) - 1
        xs.append(xs[-1] - fs[-1] * (xs[-1] - xs[-2]) / d); fs.append(f(xs[-1]))
    return xs, None
def order(e, k): return log(e[k + 1] / e[k]) / log(e[k] / e[k - 1])
f, df = (lambda x: x * x * x - 2), (lambda x: 3 * x * x)
r, halvings = bisect(f, 1.0, 2.0)
phi = (1 + sqrt(5)) / 2
C = r * r / 2                                 # f''(r)/(2 f'(r)) = 1/r = r^2/2
print(f"root by bisection on [1, 2]: r = {r:.16f} after {halvings} halvings; r^3 - 2 = {sci(f(r))}")
print(f"constants: C = f''(r)/(2 f'(r)) = 1/r = {C:.4f}; golden ratio phi = {phi:.4f}; C^(phi-1) = {C ** (phi - 1):.4f}")
xn = newton(f, df, 1.0, 5)
en = [abs(x - r) for x in xn]
print("Newton from x0 = 1    k  x_k                 error e_k  digits  e_k/e_(k-1)^2  order")
for k in range(5):
    if k: assert abs(en[k - 1] * en[k - 1] * (2 * xn[k - 1] + r) / (3 * xn[k - 1] * xn[k - 1]) - en[k]) <= 1e-4 * en[k]
    ratio = f"{en[k] / (en[k - 1] * en[k - 1]):.4f}" if k else "-"     # the exact error law, run in floats
    p = f"{order(en, k - 1):.3f}" if k >= 2 else "-"
    print(f"{'':21} {k}  {xn[k]:.16f}  {sci(en[k]):>9}  {-log10(en[k]):6.2f}  {ratio:>13}  {p:>5}")
xs, _ = secant(f, 1.0, 2.0, 6)
es = [abs(x - r) for x in xs]
print("secant from 1 and 2   k  x_k                 error e_k  digits  e_k/(e e)  e_k/e^phi  order")
q = [1.0] * 8
for k in range(8):
    if k >= 2:
        a, b = xs[k - 2], xs[k - 1]
        assert abs(es[k - 2] * es[k - 1] * (a + b + r) / (a * a + a * b + b * b) - es[k]) <= 1e-4 * es[k]
        q[k] = es[k] / es[k - 1] ** phi
    ratio = f"{es[k] / (es[k - 1] * es[k - 2]):.4f}" if k >= 2 else "-"
    qs = f"{q[k]:.4f}" if k >= 2 else "-"
    p = f"{order(es, k - 1):.3f}" if k >= 2 else "-"
    print(f"{'':21} {k}  {xs[k]:.16f}  {sci(es[k]):>9}  {-log10(es[k]):6.2f}  {ratio:>9}  {qs:>9}  {p:>5}")
print(f"Newton step 5: x = {xn[5]:.16f}, error {sci(en[5])}; secant x_8: error {sci(abs(secant(f, 1.0, 2.0, 7)[0][8] - r))}")
print("both exact error laws matched the measured errors at every step, to 1 part in 10,000")
assert abs(en[4] / (en[3] * en[3]) - C) < 0.001 and abs(es[7] / (es[6] * es[5]) - C) < 0.001
assert en[3] > 1e-9 > en[4] and es[6] > 1e-9 > es[7] and en[5] < 2.3e-16
assert abs(order(en, 3) - 2) < 0.02 and abs(order(es, 6) - phi) < 0.05
gap = [abs(log(v / C ** (phi - 1))) for v in q]            # e/e^phi settles, swinging
assert gap[7] < gap[5] < gap[3] and gap[6] < gap[4] and gap[7] < 0.1
d = [-log10(es[5]), -log10(es[6])]            # model: run the law e' = C e e in logs
for _ in range(30): d.append(d[-1] + d[-2] - log10(C))
pm = (d[-1] - d[-2]) / (d[-2] - d[-3])
print(f"the law alone, 30 more steps in logs (no rounding floor): order {pm:.6f}")
assert abs(pm - phi) < 1e-6
ew = 1.0                                      # bisection: halvings until half the width is under 1e-9
nb = 0
while ew / 2 > 1e-9: ew, nb = ew / 2, nb + 1
print(f"evaluations to an error under 1e-9: bisection 2 + {nb} halvings = {2 + nb}; Newton 4 steps = 8 (4 of f, 4 of f'); secant 6 steps = 7")
lo, hi = 0.0, 2.0                             # break-even derivative cost, by bisection
while hi - lo > 1e-12:
    t = (lo + hi) / 2
    lo, hi = (t, hi) if 2 ** (1 / (1 + t)) > phi else (lo, t)
print(f"digits multiply per evaluation: secant {phi:.4f}; Newton 2^(1/(1+t)), f' costing t evaluations of f:")
print("   " + ", ".join(f"t = {s}: {2 ** (1 / (1 + float(s))):.4f}" for s in ("0", "0.5", "1", "2")))
print(f"break-even t: bisection {lo:.4f}, formula log(2)/log(phi) - 1 = {log(2) / log(phi) - 1:.4f}")
assert abs(lo - (log(2) / log(phi) - 1)) < 1e-9
print(f"from 1 correct digit to 16: Newton {log(16) / log(2):.2f} steps, secant {log(16) / log(phi):.2f} steps")
f2, df2 = (lambda x: f(x) * f(x)), (lambda x: 6 * x * x * f(x))   # the double root
gn = newton(f2, df2, 1.0, 60); gs, _ = secant(f2, 1.0, 2.0, 80)
first = lambda xs: next(k for k, x in enumerate(xs) if abs(x - r) < 1e-9)
kn, ks = first(gn), first(gs)
qn = abs(gn[kn] - r) / abs(gn[kn - 1] - r); qs = abs(gs[ks] - r) / abs(gs[ks - 1] - r)
print(f"break 1, double root (x^3-2)^2: Newton {kn} steps, ratio {qn:.4f}; secant {ks - 1} steps, ratio {qs:.4f}")
assert abs(qn - 0.5) < 0.01 and abs(qs - (phi - 1)) < 0.03
fx = [1.0]                                    # chord always drawn from the fixed end 2
for _ in range(60): fx.append(fx[-1] - f(fx[-1]) * (fx[-1] - 2) / (f(fx[-1]) - f(2.0)))
kf = first(fx); qf = abs(fx[kf] - r) / abs(fx[kf - 1] - r)
qth = (2 - r) * (2 + 2 * r) / (4 + 2 * r + r * r)
print(f"break 2, one end frozen at 2: {kf} steps, ratio {qf:.4f}, theory (2-r)(2+2r)/(4+2r+r^2) = {qth:.4f}")
assert abs(qf - qth) < 0.001
xl, stall = secant(f, 1.0, 2.0, 20)
print(f"break 3, secant with no stop: x_{stall} = x_{stall - 1}, so f(x_{stall}) - f(x_{stall - 1}) = "
      f"{f(xl[stall]) - f(xl[stall - 1]):.1f} and the step to x_{stall + 1} is 0/0")
X, Y = (lambda x: 40 + 250 * (x - 0.9)), (lambda y: 182.5 - 25 * y)
print(f"figure, start ({X(1):.1f}, {Y(-1):.1f}), (2, 6) at ({X(2):.1f}, {Y(6):.1f}), tangent lands {xn[1]:.3f} at "
      f"{X(xn[1]):.1f}, chord lands {xs[2]:.3f} at {X(xs[2]):.1f}, root {r:.3f} at {X(r):.1f}, axis y {Y(0):.1f}")
print("ALL CHECKS PASS")
