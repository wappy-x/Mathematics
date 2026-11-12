# Fixed points and contraction: the check behind the card.  Standard library only.
# A reservoir takes in 30 m^3/s and lets water out through a pipe, 12 sqrt(x), and a
# notch, 2 x^1.5, where x is the depth in metres.  Find the steady depth x* three ways,
# then test the rate, the one-step bounds, relaxation and the failures.
from math import sqrt, cbrt, log10
Q, a, b = 30.0, 12.0, 2.0
def sci(v, d=2):                              # 1.23e-4, the form Rust prints
    m, e = f"{v:.{d}e}".split("e")
    return f"{m}e{int(e)}"
def out(x): return a * sqrt(x) + b * x * sqrt(x)          # outflow, m^3/s
def gA(x, a=a, b=b):                          # keep the notch: x = ((Q - a sqrt x)/b)^(2/3)
    c = cbrt((Q - a * sqrt(x)) / b)
    return c * c
def gB(x):                                    # keep the pipe: x = ((Q - b x^1.5)/a)^2
    t = (Q - b * x * sqrt(x)) / a
    return t * t
def dgA(x): return -a / (3 * b * sqrt(x)) / cbrt((Q - a * sqrt(x)) / b)
def press(g, x, n, w=1.0):                    # relaxed press: (1 - w) x + w g(x)
    ys = [x]
    for _ in range(n): ys.append((1 - w) * ys[-1] + w * g(ys[-1]))
    return ys
def cardano(p, r):                            # road 1: Cardano on s = sqrt(x), s^3 + p s = r
    dd = sqrt(r * r / 4 + p * p * p / 27)
    s = cbrt(r / 2 + dd) + cbrt(r / 2 - dd)
    return s * s                              # x = s^2
def two_sum(u, v):                            # u + v = s + e exactly
    s = u + v; z = s - u
    return s, (u - (s - z)) + (v - z)
def two_prod(u, v):                           # u v = p + e exactly, by Dekker's split
    p = u * v; cu, cv = 134217729.0 * u, 134217729.0 * v
    uh, vh = cu - (cu - u), cv - (cv - v)
    return p, ((uh * vh - p) + uh * (v - vh) + (u - uh) * vh) + (u - uh) * (v - vh)
def cubic(x):                                 # b^2 x^3 + 2ab x^2 + a^2 x - Q^2 in double-double
    r, c = b * b, 0.0
    for k in (2 * a * b, a * a, -Q * Q):
        p, pe = two_prod(r, x); r, se = two_sum(p, k); c = c * x + (pe + se)
    return r + c
x1 = cardano(a / b, Q / b)
lo, hi, nh = 0.0, 6.25, 0                     # road 2: bisection on outflow - inflow
while lo < (lo + hi) / 2 < hi:
    mid = (lo + hi) / 2
    lo, hi, nh = (mid, hi, nh + 1) if out(mid) < Q else (lo, mid, nh + 1)
dlt = -cubic(lo) / (3 * b * b * lo * lo + 4 * a * b * lo + a * a)
xstar, xlo = two_sum(lo, dlt)                 # road 4: x* = xstar + xlo, to about 1e-30 m
def err(v): return (v - xstar) - xlo          # true error of a double v near x*
d2 = -cubic(hi) / (3 * b * b * hi * hi + 4 * a * b * hi + a * a)
assert abs((hi - xstar) + d2 - xlo) < 1e-29   # road 4 agrees from road 2's other end
xa = press(gA, 2.0, 150)                      # road 3: press g_A from 2 m
still = next(k for k in range(1, 151) if xa[k] == xa[k - 1])
print(f"inflow {Q:.0f} m^3/s; outflow = {a:.0f} sqrt(x) + {b:.0f} x^1.5; steady depth x* where they match")
print(f"road 1, Cardano: x* = {x1:.15f} m")
print(f"road 2, bisection: x* = {lo:.15f} m after {nh} halvings; outflow - inflow = {sci(out(lo) - Q)}, "
      f"next double up {sci(out(hi) - Q)}")
print(f"road 3, pressing g_A from 2: {xa[150]:.15f} m; stops moving at step {still}")
print(f"road 4, one Newton step from road 2 on the squared balance, in double-double: nearest double {xstar:.16f} m")
print(f"   true errors: Cardano {sci(err(x1))}, bisection {sci(err(lo))}, g_A {sci(err(xa[150]))};"
      f" spacing of doubles here {sci(2.0 ** -51)}")
assert abs(x1 - xstar) < 4e-15 and abs(lo - xstar) < 4e-15 and xa[150] == xstar  # g_A ends on the nearest double
qs = a / (3 * b * xstar)                         # |g_A'(x*)|, from the formula at the fixed point
dq = (gA(xstar + 1e-5) - gA(xstar - 1e-5)) / 2e-5
print(f"slope of g_A at x*: -a/(3 b x*) = {-qs:.6f}; difference quotient {dq:.6f}; slope of g_B: {-1 / qs:.6f}")
assert abs(dq + qs) < 1e-8 and abs(dgA(xstar) + qs) < 1e-12
grid = [2 + 1.5 * k / 300 for k in range(301)]  # the interval I = [2, 3.5]
qI = max(abs(dgA(x)) for x in grid)
chord = max(abs(gA(u) - gA(v)) / (v - u) for u in grid for v in grid if v > u)
print(f"g_A sends [2, 3.5] into [{gA(3.5):.6f}, {gA(2.0):.6f}]; worst slope q = {qI:.6f} at x = 2; widest chord {chord:.6f}")
assert 2 < gA(3.5) < gA(2.0) < 3.5 and chord <= qI and abs(qI - abs(dgA(2.0))) < 1e-15
print(f"multipliers: q/(1-q) = {qI / (1 - qI):.6f}, q/(1+q) = {qI / (1 + qI):.6f}")
print(" k  x_k        error e_k  step d_k  e_k/e_(k-1)  q/(1-q)|d|  q/(1+q)|d|  estimate")
for k in (1, 2, 3, 4, 5, 6, 10, 15, 20):
    e, ep, d, dp = xa[k] - xstar, xa[k - 1] - xstar, xa[k] - xa[k - 1], xa[k - 1] - xa[k - 2] if k > 1 else 0
    qh = d / dp if k > 1 else 0.0             # signed step ratio, the estimate of g'(x*)
    est = sci(qh / (qh - 1) * d) if k > 1 else "-"
    print(f"{k:2}  {xa[k]:.6f}  {sci(e):>9}  {sci(d):>8}  {e / ep:11.4f}  {sci(qI / (1 - qI) * abs(d)):>10}"
          f"  {sci(qI / (1 + qI) * abs(d)):>10}  {est:>8}")
assert all(abs(xa[k] - xstar) <= qI / (1 + qI) * abs(xa[k] - xa[k - 1]) for k in range(1, 40))
e20, d20 = abs(xa[20] - xstar), abs(xa[20] - xa[19])
print(f"at k = 20, bound / true error: q/(1-q) gives {qI / (1 - qI) * d20 / e20:.2f}, q/(1+q) gives {qI / (1 + qI) * d20 / e20:.2f}; "
      f"step ratio d_20/d_19 = {(xa[20] - xa[19]) / (xa[19] - xa[18]):.4f}")
assert abs((xa[20] - xstar) / (xa[19] - xstar) + qs) < 1e-3   # the rate is the slope at x*, sign and all
d1 = abs(xa[1] - xa[0])
first = lambda ok: next(n for n in range(1, 151) if ok(n))
print(f"to 1e-6 m: first-step bound promises n = {first(lambda n: qI ** n / (1 - qI) * d1 <= 1e-6)}, "
      f"q/(1+q) step bound stops at {first(lambda n: qI / (1 + qI) * abs(xa[n] - xa[n - 1]) <= 1e-6)}, "
      f"true error at {first(lambda n: abs(xa[n] - xstar) <= 1e-6)}")
s0 = (gB(2.01) - gB(2.0)) / 0.01              # relax g_B: one nudge estimates its slope
w = 1 / (1 - s0)
xr = press(gB, 2.0, 12, w)
print(f"g_B nudged at 2: slope {s0:.6f}, so w = 1/(1 - slope) = {w:.6f}; relaxed slope at x*: {1 - w * (1 + 1 / qs):.6f}")
print("relaxed g_B errors: " + ", ".join(sci(abs(err(x))) for x in xr[:7]))
assert abs(abs(xr[4] - xstar) / abs(xr[3] - xstar) - abs(1 - w * (1 + 1 / qs))) < 1e-4 and abs(xr[6] - xstar) < 1e-15
xb = press(gB, 2.0, 40)
print("break 1, plain g_B depths: " + ", ".join(f"{x:.4f}" for x in xb[:9]) + f"; at step 40: {xb[39]:.4f}, {xb[40]:.4f}")
print(f"   2 x^1.5 at {xb[39]:.4f} is {b * xb[39] * sqrt(xb[39]):.4f} > 30, and the square hides the minus sign")
assert abs(gB(gB(xb[40])) - xb[40]) < 1e-9 and abs(xb[40] - xstar) > 2.8   # a false 2-cycle
xo = press(gB, 2.0, 10, 0.9)
print(f"break 2, over-relaxed w = 0.9, slope {1 - 0.9 * (1 + 1 / qs):.4f}; errors: " + ", ".join(f"{abs(x - xstar):.4f}" for x in xo))
assert abs(xo[10] - xstar) > 2 * abs(xo[0] - xstar)
print(f"break 3, rounding floor: g_A's step from step {still} is {xa[150] - xa[149]:.1f}, so q/(1+q)|d| = "
      f"{qI / (1 + qI) * abs(xa[150] - xa[149]):.1f}; the true error is {sci(err(xa[150]))}")
L, M, N = 300000.0, 1271.56, 300              # the shelf's mortgage, as on When to stop
def vN(i):                                    # (1 + i)^-N by repeated multiplying
    v = 1.0
    for _ in range(N): v /= 1 + i
    return v
gm = lambda i: M / L * (1 - vN(i))
lo, hi = 1e-5, 0.01
while lo < (lo + hi) / 2 < hi:
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if M * (1 - vN(mid)) / mid > L else (lo, mid)
im, qm = lo, M / L * N * vN(lo) / (1 + lo)
xm = press(gm, M / L, 200)
km = first(lambda n: abs(xm[n] - im) < 1e-12)
qh = (xm[10] - xm[9]) / (xm[9] - xm[8])       # step ratio at step 10
wm = 1 / (1 - qh)
ym = press(gm, xm[10], 30, wm)
kr = 10 + next(n for n in range(31) if abs(ym[n] - im) < 1e-12)
print(f"mortgage, {L:.0f} loan, {N} payments of {M:.2f}: rate {im:.15f} a month; slope of g at it {qm:.6f}; plain steps to 1e-12: {km}")
print(f"   step ratio at step 10 {qh:.6f}, w = {wm:.6f}; relaxed from step 10, steps to 1e-12: {kr}")
assert abs(qm - (xm[61] - im) / (xm[60] - im)) < 1e-4 and kr < km / 3
lg = lambda v: f"{log10(max(abs(err(v)), 1e-16)):.2f}"
print("chart, g_A plain:   " + ", ".join(lg(x) for x in xa[:13]))
print("chart, g_B relaxed: " + ", ".join(lg(x) for x in xr))
print("chart, g_B plain:   " + ", ".join(lg(x) for x in xb[:13]))
print(f"try: Q = 40 -> x* = {cardano(a / b, 40 / b):.6f}, slope {-a / (3 * b * cardano(a / b, 40 / b)):.6f}")
print(f"try: g_A relaxed, w = {1 / (1 + qs):.3f}: errors " + ", ".join(sci(abs(err(x))) for x in press(gA, 2.0, 3, 0.589)[1:]))
print(f"try: a = 30, b = 1 -> x* = {cardano(30.0, 30.0):.6f}; g_A from 2 ends at {press(lambda x: gA(x, 30.0, 1.0), 2.0, 150)[-1]:.3f}")
print("ALL CHECKS PASS")
