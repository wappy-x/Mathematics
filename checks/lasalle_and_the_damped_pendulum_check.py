# LaSalle and the damped swing -- the check behind the card.  Only math is
# imported.  theta'' + c theta' + sin(theta) = 0, time in units of sqrt(l/g).
# Road one steps the swing by Runge-Kutta 4 and records where it ends.  Road
# two books the energy lost against c times the integral of v^2 (Simpson),
# and the late swings against the eigenvalues of the swing near the bottom.
from math import sin, cos, sqrt, pi, exp
C, TH0, T, DEG, UNIT = 0.5, pi / 3, 40.0, 180 / pi, sqrt(1 / 9.81)

def f(th, v, c): return v, -sin(th) - c * v
def energy(th, v): return 0.5 * v * v + 1 - cos(th)

def run(th, v, c, h):                    # RK4 steps; a turnaround is where v flips sign
    out, turns = [(th, v)], []
    for k in range(round(T / h)):
        a1, b1 = f(th, v, c); a2, b2 = f(th + h/2*a1, v + h/2*b1, c)
        a3, b3 = f(th + h/2*a2, v + h/2*b2, c); a4, b4 = f(th + h*a3, v + h*b3, c)
        t2, v2 = th + h/6*(a1 + 2*a2 + 2*a3 + a4), v + h/6*(b1 + 2*b2 + 2*b3 + b4)
        if v * v2 < 0: turns.append((k*h + h*v/(v - v2), th + (t2 - th)*v/(v - v2)))
        th, v = t2, v2; out.append((th, v))
    return out, turns

def lost(out, c, h):                     # c times the integral of v^2, by Simpson's rule
    w = [1] + [4 if i % 2 else 2 for i in range(1, len(out) - 1)] + [1]
    return c * h / 3 * sum(wi * v * v for wi, (_, v) in zip(w, out))

def widest(e):                           # bisection: the angle where 1 - cos(theta) = e
    lo, hi = 0.0, pi
    for _ in range(60):
        m = (lo + hi) / 2
        lo, hi = (m, hi) if 1 - cos(m) < e else (lo, m)
    return lo

E0 = energy(TH0, 0.0)
print(f"time unit {UNIT:.4f} s; release: V0 = {E0:.3f}, V' = {sin(TH0) * 0.0 + 0.0 * f(TH0, 0.0, C)[1]:.3f}, v' = {f(TH0, 0.0, C)[1]:.3f}")
print(f"trap: |theta| <= {widest(E0) * DEG:.2f} deg, |v| <= {sqrt(2 * E0):.3f}, top V(pi, 0) = {energy(pi, 0.0):.3f}")
w, s = sqrt(4 - C * C) / 2, sqrt(C * C + 4)          # bottom: trace -c, det 1; top: det -1
print(f"eigenvalues: bottom {-C / 2:.3f} +- {w:.4f}i, top {(-C + s) / 2:.3f} and {(-C - s) / 2:.3f}")
out, turns = run(TH0, 0.0, C, 0.05)
print("turnarounds (t, deg): " + ", ".join(f"({t:.2f}, {a * DEG:.2f})" for t, a in turns[:5]))
ratios = [abs(turns[i + 1][1] / turns[i][1]) for i in range(len(turns) - 1)]
pred = exp(-C / 2 * pi / w)              # linear swing: each half swing shrinks by this
print(f"half-swing ratio: first {abs(turns[0][1] / TH0):.4f}, 6th {ratios[5]:.4f}, from eigenvalues {pred:.4f}")
first = next(t for t, a in turns if abs(a) * DEG < 1)
print(f"turnarounds under 1 deg from t = {first:.2f}, which is {first * UNIT:.2f} s")
print(f"at t = 40: theta = {out[-1][0]:.6f}, v = {out[-1][1]:.6f}, widest ever {max(abs(a) for a, _ in out) * DEG:.2f} deg")
d = [E0 - energy(*o[-1]) - lost(o, C, h) for h in (0.1, 0.05) for o in [run(TH0, 0.0, C, h)[0]]]
print(f"V0 - V(40) = {E0 - energy(*out[-1]):.6f}; c * integral of v^2 = {lost(out, C, 0.05):.6f}")
print(f"bookkeeping gap in millionths: h = 0.1 {d[0] * 1e6:.3f}, h = 0.05 {d[1] * 1e6:.3f}, ratio {d[0] / d[1]:.1f}")
print("chart, V at t = 0, 0.5, ..., 12: " + ", ".join(f"{energy(*p):.2f}" for p in out[:241:10]))
print("figure, spiral x = 180 + 45 theta, y = 120 - 45 v: " + " ".join(f"{180 + 45 * a:.1f},{120 - 45 * b:.1f}" for a, b in out[:241:5]))
print("figure, eye edge v = 2 cos(theta/2), theta = -pi..pi by pi/8: " + " ".join(f"{2 * cos(k * pi / 16):.2f}" for k in range(-8, 9)))
free, free_turns = run(TH0, 0.0, 0.0, 0.05)
print(f"c = 0: V(40) = {energy(*free[-1]):.6f}, last turnaround {abs(free_turns[-1][1]) * DEG:.2f} deg")
ends = {v0: run(0.0, v0, C, 0.05)[0][-1][0] for v0 in (3.0, 3.5)}
print("push from the bottom: " + ", ".join(f"v0 = {v0:.1f} (V0 = {energy(0.0, v0):.3f}) ends in well {round(e / (2 * pi))}" for v0, e in ends.items()))
assert abs(d[1]) < 1e-6 and 12 < d[0] / d[1] < 20       # energy book balances, at RK4's order
assert abs(ratios[5] / pred - 1) < 0.01                  # late swings obey the eigenvalues
assert abs(out[-1][0]) < 1e-3 and abs(out[-1][1]) < 1e-3 and max(abs(a) for a, _ in out) <= widest(E0) + 1e-9
assert abs(energy(*free[-1]) - E0) < 1e-6 and abs(ends[3.5] - 2 * pi) < 1e-3
print("ALL CHECKS PASS")
