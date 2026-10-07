# The SIR model -- the check behind the card.  Nothing is imported but math.exp
# and math.log.  A flu in a town of 10,000: S, I, R are the shares susceptible,
# ill and recovered; S' = -bSI, I' = bSI - gI, R' = gI, time in days, one case
# on day 0.  Road one steps the equations (Runge-Kutta 4, written out); road two
# is the phase curve I + S - ln(S)/R0 = constant, which needs no stepping at all.
from math import exp, log
N, B, G = 10000, 0.625, 0.25                     # town, contact rate, recovery rate
R0, S0, I0 = B / G, 1 - 1 / N, 1 / N
def f(s, i): return -B * s * i, B * s * i - G * i
def rk4(s, i, h):                                # one Runge-Kutta 4 step
    a = f(s, i); b = f(s + h / 2 * a[0], i + h / 2 * a[1])
    c = f(s + h / 2 * b[0], i + h / 2 * b[1]); d = f(s + h * c[0], i + h * c[1])
    return s + h / 6 * (a[0] + 2 * b[0] + 2 * c[0] + d[0]), i + h / 6 * (a[1] + 2 * b[1] + 2 * c[1] + d[1])
def run(h, days):                                # every step, as (t, S, I)
    s, i, out = S0, I0, [(0.0, S0, I0)]
    for k in range(1, round(days / h) + 1): s, i = rk4(s, i, h); out.append((k * h, s, i))
    return out
def phase_i(s): return S0 + I0 - s + (log(s) - log(S0)) / R0      # road two: I on the phase curve
def bisect(fn, lo, hi):                          # root finder, written out
    for _ in range(200):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if fn(lo) * fn(mid) > 0 else (lo, mid)
    return (lo + hi) / 2
def eig(s, i, d=1e-6):                           # Jacobian by differences; 2x2 eigenvalues from trace and det
    j = [[(f(s + d, i)[r] - f(s - d, i)[r]) / (2 * d), (f(s, i + d)[r] - f(s, i - d)[r]) / (2 * d)] for r in (0, 1)]
    tr, det = j[0][0] + j[1][1], j[0][0] * j[1][1] - j[0][1] * j[1][0]
    q = (tr * tr / 4 - det) ** 0.5
    return tr / 2 - q, tr / 2 + q
path = run(0.01, 300)
k = max(range(len(path)), key=lambda n: path[n][2])
t_pk, s_pk, i_pk = path[k]
s_inf = bisect(lambda s: phase_i(s), 1e-9, 1 / R0)                # the phase curve meets I = 0
z = bisect(lambda z: 1 - exp(-R0 * z) - z, 0.5, 1)                 # vanishing-start form
err = [run(h, 300)[-1][1] - s_inf for h in (1, 0.5, 0.25)]
days = [row for row in path if abs(row[0] / 5 - round(row[0] / 5)) < 1e-6 and row[0] <= 60.001]
print(f"town {N}; b = {B}/day, g = {G}/day, illness 1/g = {1 / G:.0f} days; R0 = b/g = {R0}; one case on day 0")
print(f"early growth: I' = (b - g) I = {B - G:.3f} I per day; cases double every {log(2) / (B - G):.2f} days")
print("eigenvalues at (S, I) = (1, 0): {:+.4f} {:+.4f} per day".format(*eig(1, 0)))
print("eigenvalues at (S_inf, 0): {:+.4f} {:+.4f} per day".format(*eig(s_inf, 0)))
print(f"peak, phase curve at S = 1/R0 = {1 / R0}: I = {phase_i(1 / R0):.6f}, {N * phase_i(1 / R0):.0f} ill")
print(f"peak, Runge-Kutta h = 0.01: I = {i_pk:.6f}, {N * i_pk:.0f} ill on day {t_pk:.2f}, S there {s_pk:.4f}")
print(f"final size, phase curve meets I = 0: S_inf = {s_inf:.6f}; {N * (1 - s_inf):.0f} ever ill ({100 * (1 - s_inf):.1f}%), {N * s_inf:.0f} never")
print(f"final size, Runge-Kutta day 300: S = {path[-1][1]:.6f}; z = 1 - e^(-2.5 z) from a vanishing start: {z:.6f}")
print("Runge-Kutta error in never-ill people, day 300, h = 1, 0.5, 0.25: {:.7f} {:.7f} {:.7f}; ratios {:.1f} {:.1f}".format(*(N * e for e in err), err[0] / err[1], err[1] / err[2]))
print("chart days:", " ".join(f"{t:.0f}" for t, _, _ in days))
print("chart S:", " ".join(f"{N * s:.0f}" for _, s, _ in days))
print("chart I:", " ".join(f"{N * i:.0f}" for _, _, i in days))
print("chart R:", " ".join(f"{max(0.0, N * (1 - s - i)):.0f}" for _, s, i in days))
print(f"mistake 1, no depletion: e^({B - G} x {t_pk:.2f}) = {exp((B - G) * t_pk):.0f} ill at the peak day, in a town of {N}")
print(f"mistake 2, threshold 1 - 1/R0 = {1 - 1 / R0:.0%} read as the final size; overshoot {N * (1 - s_inf - (1 - 1 / R0)):.0f} people")
print(f"mistake 3, g = 4 per day (the period used as the rate): R0 = {B / 4:.4f}, no outbreak")
X = lambda s: 40 + 300 * s; Y = lambda i: 210 - 720 * i          # 300 units per unit S, 720 per unit I
print(f"figure, peak ({X(1 / R0):.1f}, {Y(phase_i(1 / R0)):.1f}); start x {X(S0):.1f}; end x {X(s_inf):.1f}")
print("figure, curve:", " ".join(f"{X(s):.1f},{Y(phase_i(s)):.1f}" for s in [S0] + [1 - 0.05 * n for n in range(1, 18)] + [s_inf]))
assert abs(i_pk - phase_i(1 / R0)) < 1e-6 and abs(s_pk - 1 / R0) < 0.002   # peak: stepping vs phase curve
assert abs(path[-1][1] - s_inf) < 1e-7                                     # final size: stepping vs root
assert 14 < err[0] / err[1] < 18                                            # fourth order: error / 16
assert abs(eig(1, 0)[1] - (B - G)) < 1e-6 and abs(eig(s_inf, 0)[0] - (B * s_inf - G)) < 1e-6   # vs hand Jacobian
print("ALL CHECKS PASS")
