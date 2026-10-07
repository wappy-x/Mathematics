# Stiff equations and backward Euler -- the check behind the card.  No imports
# beyond math.  The fast intermediate: y' = -1000(y - cos t) - sin t, y(0) = 0,
# t in s.  Exact solution y = cos t - e^(-1000t).  Road 1: three stepping rules
# against that closed form.  Road 2: nudge the start and measure the factor each
# rule applies to the gap from the slow curve, against the algebra 1 + z,
# 1/(1 - z) and (1 + z/2)/(1 - z/2) with z = -1000h.
from math import cos, sin, exp
K = 1000.0
def g(t): return K * cos(t) - sin(t)                  # f(t, y) = -K y + g(t)
def forward(t, y, h): return y + h * (-K * y + g(t))
def backward(t, y, h): return (y + h * g(t + h)) / (1 + K * h)     # solved for the destination
def trapezoid(t, y, h): return ((1 - K * h / 2) * y + h / 2 * (g(t) + g(t + h))) / (1 + K * h / 2)
def exact(t): return cos(t) - exp(-K * t)
def run(step, h, n, y=0.0):
    ys = [y]
    for i in range(n): ys.append(step(i * h, ys[-1], h))
    return ys
def sci(x, d=3): m, e = f"{x:.{d}e}".split("e"); return f"{m}e{int(e)}"
def err(step, h, n, y=0.0): return run(step, h, n, y)[-1] - (cos(n * h) - (1 - y) * exp(-K * n * h))
steps, names = [forward, backward, trapezoid], ["forward", "backward", "trapezoid"]
h = 0.01; z = -K * h
print("one step, h=0.01, from y=0: " + ", ".join(f"{n} {s(0, 0.0, h):.6f}" for n, s in zip(names, steps)) + f", exact {exact(h):.6f}")
algebra = [1 + z, 1 / (1 - z), (1 + z / 2) / (1 - z / 2)]
nudged = [(s(0, 1e-3, h) - s(0, 0.0, h)) / 1e-3 for s in steps]
print("gap factor, algebra: " + ", ".join(f"{n} {a:.6f}" for n, a in zip(names, algebra)) + f", exact e^z {exp(z):.6f}")
print("gap factor, measured: " + ", ".join(f"{n} {m:.6f}" for n, m in zip(names, nudged)))
assert all(abs(a - m) < 1e-9 for a, m in zip(algebra, nudged))
print(f"forward shrinks the gap only while |1 - 1000h| < 1, so h < 2/1000 = {2 / K:.3f}")
print("figure, t: " + ", ".join(f"{i * h:.2f}" for i in range(11)))
print("figure, exact: " + ", ".join(f"{exact(i * h):.2f}" for i in range(11)))
for n, s in zip(names[1:], steps[1:]):
    print(f"figure, {n}: " + ", ".join(f"{y:.2f}" for y in run(s, h, 10)))
print(f"forward h=0.01: y at t=0.1 {sci(run(forward, h, 10)[-1])}, at t=1 {sci(run(forward, h, 100)[-1])}")
print(f"forward h=0.01 from y=1, already on the slow curve: error at t=0.1 {sci(err(forward, h, 10, 1.0))}")
for hh in (0.0019, 0.0021):
    print(f"forward h={hh}: factor {1 - K * hh:.1f}, 500 steps reach t={500 * hh:.2f}, error {sci(err(forward, hh, 500))}")
eb = [err(backward, hh, round(1 / hh)) for hh in (0.01, 0.005, 0.0025)]
et = [err(trapezoid, hh, round(1 / hh)) for hh in (0.01, 0.005, 0.0025)]
print("error at t=1, h=0.01, 0.005, 0.0025: backward " + ", ".join(sci(e) for e in eb) + f"; ratios {eb[0] / eb[1]:.2f}, {eb[1] / eb[2]:.2f}")
print("error at t=1, h=0.01, 0.005, 0.0025: trapezoid " + ", ".join(sci(e) for e in et) + f"; ratios {et[0] / et[1]:.2f}, {et[1] / et[2]:.2f}")
assert 1.9 < eb[0] / eb[1] < 2.1 and 3.9 < et[1] / et[2] < 4.1 and all(   # orders 1 and 2; errors within the proved bounds
    abs(e) <= x / (2 * K) + exp(-K) + (1 + K * x) ** -round(1 / x) for e, x in zip(eb, (0.01, 0.005, 0.0025))) and abs(err(forward, 0.0019, 500)) <= 0.9 ** 500 + 0.0019 ** 2 / 2 / 0.1
hs = [0.001, 0.01, 0.1, 1.0, 10.0]
fac = [(backward(0, 1e-3, x) - backward(0, 0.0, x)) / 1e-3 for x in hs]
print("backward gap factor, h=0.001 to 10: " + ", ".join(f"{f:.6f}" for f in fac))
assert all(abs(f - 1 / (1 + K * x)) < 1e-9 and 0 < f < 1 for f, x in zip(fac, hs))
tr = [err(trapezoid, 0.1, n) for n in (1, 2, 3, 10)]
print("h=0.1, trapezoid error at t=0.1, 0.2, 0.3, 1: " + ", ".join(f"{e:.4f}" for e in tr) + f"; backward at t=1 {sci(err(backward, 0.1, 10))}")
assert abs(tr[-1] + (-49 / 51) ** 10) < 0.01             # the start gap -1, times (-49/51) ten times
v, its = 0.0, []
for _ in range(3): v = 0.0 + h * (-K * v + g(h)); its.append(v)     # plug-in iteration, not a solve
print("backward step by plug-in iteration: " + ", ".join(f"{x:.3f}" for x in its) + f"; solved {backward(0, 0.0, h):.6f}")
print("ALL CHECKS PASS")
