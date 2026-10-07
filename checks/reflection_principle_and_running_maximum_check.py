# Reflection principle for Brownian motion -- the check behind the card.  Standard library only.
# A pollen grain's position W_t along one axis, in micrometres, spreading by 1 um^2 of variance a second.
# Does it reach 3 um within 10 seconds?  Road 1: the formula 2(1 - Phi(3/sqrt 10)), with Phi built
# by Simpson's rule.  Road 2: exact coin-flip walks, finer and finer, no mirror used.  Road 3: seeded
# Gaussian paths (SplitMix64 + Box-Muller, written out) on grids of 1, 0.1 and 0.01 seconds.
from math import sqrt, exp, log, cos, sin, pi

A, T = 3.0, 10.0                                  # level (um) and horizon (seconds)
def phi(x): return exp(-0.5 * x * x) / sqrt(2 * pi)
def simpson(f, a, b, n):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n): s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3
def Phi(x):                                       # standard normal CDF: half, plus the area from 0 to x
    if x > 12: return 1.0
    if x < -12: return 0.0
    return 0.5 + simpson(phi, 0.0, x, 2000)
def touch(a, t): return 2 * (1 - Phi(a / sqrt(t)))          # the reflection principle: P(M_t >= a)
def drift_touch(a, t, mu):                         # with drift mu (um per second), for the what-breaks row
    return 1 - Phi((a - mu * t) / sqrt(t)) + exp(2 * mu * a) * Phi((-a - mu * t) / sqrt(t))
def either_side(a, t):                             # P(|W| reaches a by t): mirrors in both walls, alternating
    stay = sum((-1) ** k * (Phi((2 * k + 1) * a / sqrt(t)) - Phi((2 * k - 1) * a / sqrt(t))) for k in range(-8, 9))
    return 1 - stay

def walk(n, j, p=0.5, two_sided=False):           # road 2: coin walk, n steps of +-h, h = sqrt(T/n); does it reach j steps?
    lo = -j + 1 if two_sided else -(j + int(12 * sqrt(n)) + 2)
    w = [0.0] * (j - lo); w[-lo] = 1.0; hit = 0.0
    for _ in range(n):
        hit += p * w[-1] + ((1 - p) * w[0] if two_sided else 0.0)
        w = [(p * w[i - 1] if i else 0.0) + ((1 - p) * w[i + 1] if i + 1 < len(w) else 0.0) for i in range(len(w))]
    return hit

MASK = (1 << 64) - 1
state = 20260930
def u01():                                        # SplitMix64, top 53 bits, never exactly 0
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return (((z ^ (z >> 31)) >> 11) + 0.5) / 9007199254740992.0

PATHS, STEPS = 10000, 1000                        # 1000 steps of 0.01 s; every 10th is the 0.1 s grid, every 100th the 1 s grid
grid_hits = {1: 0, 10: 0, 100: 0}; max_sum = max_sq = 0.0; joint = 0
first_sec = [0] * 11; first_fine = [0] * 11      # first second-mark by which the path has reached 3
for _ in range(PATHS):
    x, top, k, fine_t, sec_t = 0.0, 0.0, 0, 0, 0
    tops = {1: 0.0, 10: 0.0, 100: 0.0}
    while k < STEPS:
        r = sqrt(-2 * log(u01())); th = 2 * pi * u01()
        for z in (r * cos(th), r * sin(th)):
            x += 0.1 * z; k += 1
            for g in (1, 10, 100):
                if k % g == 0 and x > tops[g]: tops[g] = x
            if not fine_t and x >= A: fine_t = (k + 99) // 100
            if not sec_t and k % 100 == 0 and x >= A: sec_t = k // 100
    for g in (1, 10, 100): grid_hits[g] += tops[g] >= A
    max_sum += tops[1]; max_sq += tops[1] ** 2; joint += tops[1] >= A and x <= 1.0
    if fine_t: first_fine[fine_t] += 1
    if sec_t: first_sec[sec_t] += 1
def est(c): p = c / PATHS; return p, sqrt(p * (1 - p) / PATHS)
BETA = 1.4603545088 / sqrt(2 * pi)                 # -zeta(1/2)/sqrt(2 pi): a grid sees the level as if shifted up by BETA*sqrt(dt)

p1 = touch(A, T)
print(f"{'sqrt(t), typical spread at 10 s':<44}{sqrt(T):>11.6f}")
print(f"{'a / sqrt(t)':<44}{A / sqrt(T):>11.6f}")
print(f"{'Phi(a / sqrt(t)), Simpson':<44}{Phi(A / sqrt(T)):>11.6f}")
print(f"{'1 formula 2(1 - Phi)':<44}{p1:>11.6f}")
print(f"{'  ends at or above 3, P(W_10 >= 3)':<44}{1 - Phi(A / sqrt(T)):>11.6f}")
print("2 coin walk, exact      steps n     P(reach)      error")
errs = []
for j in (3, 6, 12, 24, 48, 96):
    n = 10 * j * j // 9; v = walk(n, j); errs.append(abs(v - p1))
    print(f"{'':<24}{n:>7d}   {v:>10.6f}   {v - p1:>+9.6f}")
print(f"{'BETA = -zeta(1/2) / sqrt(2 pi)':<44}{BETA:>11.6f}")
print("3 simulation, 10000 paths   grid      P(reach)   std err   grid-corrected formula")
sims = {}
for g, dt in ((100, 1.0), (10, 0.1), (1, 0.01)):
    p, se = est(grid_hits[g]); sims[g] = (p, se, touch(A + BETA * sqrt(dt), T))
    print(f"{'':<28}{dt:>4.2f} s   {p:>9.4f}   {se:>7.4f}   {sims[g][2]:>9.4f}")
pj, sej = est(joint)
print(f"{'joint: reach 3, end <= 1; P(W_10 >= 5)':<44}{1 - Phi(5 / sqrt(T)):>11.6f}")
print(f"{'  grid-corrected, 0.01 s':<44}{1 - Phi((2 * (A + BETA * 0.1) - 1) / sqrt(T)):>11.6f}")
print(f"{'  simulated, 0.01 s grid, std err':<44}{pj:>11.4f}{sej:>8.4f}")
mean_f = sqrt(2 * T / pi); mean_i = simpson(lambda m: touch(m, T) if m > 0 else 1.0, 0.0, 40.0, 400)
print(f"{'mean of M_10: sqrt(2t/pi)':<44}{mean_f:>11.6f}")
print(f"{'  integral of P(M_10 >= m) dm':<44}{mean_i:>11.6f}")
m_bar = max_sum / PATHS; m_se = sqrt((max_sq / PATHS - m_bar ** 2) / PATHS)
print(f"{'  simulated 0.01 s + BETA sqrt(dt), std err':<44}{m_bar + BETA * 0.1:>11.4f}{m_se:>8.4f}")
lo, hi = 0.0, 10.0
for _ in range(60):
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if touch(mid, T) > 0.5 else (lo, mid)
print(f"{'median of M_10, bisection':<44}{lo:>11.6f}")
print(f"{'  median / sqrt(t)':<44}{lo / sqrt(T):>11.6f}")
two_dp, drift_dp = walk(10240, 96, two_sided=True), walk(10240, 96, p=0.5 * (1 + 0.2 * 3 / 96))
rows = [("wrong: double for either side", 2 * p1), ("  right, mirrors in both walls", either_side(A, T)),
        ("  right, coin walk n = 10240", two_dp),
        ("wrong: mirror with drift 0.2 / s", touch(A - 0.2 * T, T)), ("  right, drift formula", drift_touch(A, T, 0.2)),
        ("  right, coin walk n = 10240", drift_dp), ("wrong: formula at level -3, below the start", touch(-A, T)),
        ("try: level 6", touch(6.0, T)), ("try: 40 seconds", touch(A, 40.0)), ("try: 1000 seconds", touch(A, 1000.0))]
for name, v in rows: print(f"{name:<44}{v:>11.6f}")
ms = range(9)
print("chart, level m          " + " ".join(f"{m:>6d}" for m in ms))
print("chart, P(M_10 >= m) %   " + " ".join(f"{100 * (touch(m, T) if m else 1.0):6.2f}" for m in ms))
print("chart, coin walk 2560 % " + " ".join(f"{100 * (walk(2560, 16 * m) if m else 1.0):6.2f}" for m in ms))
print("chart, P(W_10 >= m) %   " + " ".join(f"{100 * (1 - Phi(m / sqrt(T))):6.2f}" for m in ms))
print("chart, second t         " + " ".join(f"{t:>6d}" for t in range(1, 11)))
print("chart, P(tau_3 <= t) %  " + " ".join(f"{100 * touch(A, t):6.2f}" for t in range(1, 11)))
print("chart, sim 0.01 s grid %" + " ".join(f"{100 * sum(first_fine[:t + 1]) / PATHS:6.2f}" for t in range(1, 11)))
print("chart, sim every sec %  " + " ".join(f"{100 * sum(first_sec[:t + 1]) / PATHS:6.2f}" for t in range(1, 11)))
path = [0, 0.6, 0.2, 1.1, 1.6, 1.2, 2.0, 2.4, 3.0, 2.5, 2.8, 2.1, 1.5, 1.9, 1.2, 0.7, 1.3, 0.9, 0.4, 1.1, 1.0]
hit = path.index(A)                                # a hand-drawn path on a 0.5 s grid, first at 3 at t = 4 s
print("figure, path            " + " ".join(f"{v:.1f}" for v in path))
print("figure, mirrored        " + " ".join(f"{v if i <= hit else 2 * A - v:.1f}" for i, v in enumerate(path)))
print("figure, x px            " + " ".join(f"{40 + 15 * i}" for i in range(len(path))))
print("figure, y px path       " + " ".join(f"{185 - 25 * v:.1f}" for v in path))
print("figure, y px mirrored   " + " ".join(f"{185 - 25 * (v if i <= hit else 2 * A - v):.1f}" for i, v in enumerate(path)))

assert abs(walk(10240, 96) - p1) < 0.005 and errs[1:] == sorted(errs[1:], reverse=True), "coin walks close in on the formula"
assert all(abs(p - c) < 4 * se for p, se, c in sims.values()), "each grid within 4 std errs of the grid-corrected formula"
assert abs(pj - (1 - Phi((2 * (A + BETA * 0.1) - 1) / sqrt(T)))) < 4 * sej, "joint law: simulation vs grid-corrected mirror"
assert abs(mean_i - mean_f) < 1e-6 and abs(m_bar + BETA * 0.1 - mean_f) < 4 * m_se, "mean of the maximum, three ways"
assert abs(two_dp - either_side(A, T)) < 0.005, "two walls: image series vs coin walk"
assert abs(drift_dp - drift_touch(A, T, 0.2)) < 0.005, "drift: formula vs coin walk"
assert abs(lo - 0.6744897502 * sqrt(T)) < 1e-6, "median of M_10 = median of |W_10|"
print("ALL CHECKS PASS")
