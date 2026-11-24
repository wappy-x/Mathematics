# Delay equations -- the check behind the card.  Standard library only.  Shower: x is the
# water temperature above target (C) leaving the valve; the skin feels it tau seconds
# later, and the hand turns the valve at the rate x'(t) = -k x(t - tau), with k = 1 per s.
from math import exp, cos, sin, pi, e
def root(k, tau, re=0.0, im=1.2):      # Newton on f(lam) = lam + k e^(-lam tau) = 0
    for _ in range(60):
        er, ei = exp(-re * tau) * cos(im * tau), -exp(-re * tau) * sin(im * tau)
        fr, fi, dr, di = re + k * er, im + k * ei, 1 - k * tau * er, -k * tau * ei
        d2 = dr * dr + di * di         # Newton step: lam - f / f', in complex arithmetic
        re, im = re - (fr * dr + fi * di) / d2, im - (fi * dr - fr * di) / d2
    return re, im
def run(tau, T, k=1.0, M=1000):        # trapezoid stepper on a grid holding the history
    h, x = tau / M, [1.0] * (M + 1)
    for n in range(int(round(T / h))):
        x.append(x[-1] - k * h * (x[-1 - M] + x[-M]) / 2)
    return x[M:], h
def yn(c): return "yes" if c else "no"
def at(x, h, t): i = int(t / h); return x[i] + (x[i + 1] - x[i]) * (t / h - i)   # read between grid points
def peaks(x, h): return [(i * h, x[i]) for i in range(1, len(x) - 1) if x[i - 1] < x[i] >= x[i + 1]]
def steps(n, p):                       # method of steps, tau = 1: exact polynomial pieces
    ends = []                          # p = piece on [j, j+1] as coefficients of s = t - j
    for _ in range(n):
        ends.append(sum(p)); p = [ends[-1]] + [-c / (m + 1) for m, c in enumerate(p)]
    return [round(v, 4) + 0.0 for v in ends]
ex = steps(4, [1.0, -1.0]); xs, h = run(1.0, 4.0)
num = [round(xs[int(round(j / h))], 4) + 0.0 for j in (1, 2, 3, 4)]
print("method of steps, tau = 1: x(1..4) = " + ", ".join(f"{v:.4f}" for v in ex))
print("trapezoid stepper,        x(1..4) = " + ", ".join(f"{v:.4f}" for v in num))
assert ex == num and ex[1] == -0.5
for tau in (1.0, pi / 2, 2.0):
    re, im = root(1.0, tau); P = 2 * pi / im
    (t1, a1), (t2, a2) = peaks(*run(tau, 60.0, M=2000))[3:5]
    xc, hc = run(tau, 21.0)
    print(f"chart tau {tau:.4f}: " + ", ".join(f"{round(at(xc, hc, j), 2) + 0.0:.2f}" for j in range(21)))
    print(f"tau = {tau:.4f}: root {round(re, 4) + 0.0:+.4f} {im:+.4f}i, period {P:.4f} s, peak ratio {exp(re * P):.4f}; "
          f"simulated period {t2 - t1:.4f} s, ratio {a2 / a1:.4f}")
    assert abs(t2 - t1 - P) < 2e-3 and abs(a2 / a1 - exp(re * P)) < 2e-3
lo, hi = 1.0, 2.0                      # bisection: the delay where the root's real part is 0
for _ in range(50): mid = (lo + hi) / 2; lo, hi = (mid, hi) if root(1.0, mid)[0] < 0 else (lo, mid)
print(f"Hopf delay by bisection {lo:.4f} s; pi/2 = {pi / 2:.4f}; "
      f"lam = i solves it at tau = pi/2: {yn(abs(cos(pi / 2)) + abs(1 - sin(pi / 2)) < 1e-12)}")
assert abs(lo - pi / 2) < 1e-6
cross = [min(run(t, 30.0)[0]) < 0 for t in (0.30, 0.45)]
print(f"oscillation starts at k tau = 1/e = {1 / e:.4f}: crosses zero at tau 0.30? {yn(cross[0])}; at 0.45? {yn(cross[1])}")
assert cross == [False, True]
def hutch(tau, T, r=0.5, K=1000.0, M=2000):  # N' = r N (1 - N(t - tau)/K), Heun on a grid
    h, N = tau / M, [900.0] * (M + 1)
    for n in range(int(round(T / h))):
        f = r * N[-1] * (1 - N[-1 - M] / K); p = N[-1] + h * f
        N.append(N[-1] + h / 2 * (f + r * p * (1 - N[-M] / K)))
    return N[M:], h
N2, _ = hutch(2.0, 120.0); N4, h4 = hutch(4.0, 400.0); tail = N4[len(N4) // 2:]
pk = peaks(N4, h4)
print(f"Hutchinson r = 0.5/day, K = 1000: tau 2 d (r tau = 1) N(120) = {N2[-1]:.1f}; tau 4 d (r tau = 2) "
      f"swings {min(tail):.1f} to {max(tail):.1f}, period {pk[-1][0] - pk[-2][0]:.2f} d")
assert abs(N2[-1] - 1000) < 0.1 and max(tail) > 1500
print(f"mistake 1, drop the delay: x(2) = {exp(-2):.4f}, not {ex[1]:.4f}")
print(f"mistake 2, history 0 with only x(0) = 1: x(2) = {steps(2, [1.0])[1]:.4f}")
print(f"mistake 3, delay as half a swing: threshold pi = {pi:.4f} s, but tau = 2 already grows at {root(1.0, 2.0)[0]:+.4f} per s")
print("ALL CHECKS PASS")
