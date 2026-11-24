# Poincare maps -- the check behind the card.  Standard library only.
# The law is x'' + 0.2 x' + x = cos t: state z = (x, v), position and velocity.
# Watching it once every forcing period 2 pi turns the flow into a map P(z) = M z + c.
# Road one builds P by Runge-Kutta steps; road two builds M and the steady
# oscillation by hand formulas.  They must agree.
import math
TAU, B, N = 2 * math.pi, 0.2, 4000                    # forcing period, damping, steps per period

def f(t, z): return (z[1], -B * z[1] - z[0] + math.cos(t))

def flow(z, t0, span, n):                             # Runge-Kutta 4 from time t0 for a time span
    h, t = span / n, t0
    for _ in range(n):
        k1 = f(t, z); k2 = f(t + h / 2, [z[i] + h / 2 * k1[i] for i in (0, 1)])
        k3 = f(t + h / 2, [z[i] + h / 2 * k2[i] for i in (0, 1)]); k4 = f(t + h, [z[i] + h * k3[i] for i in (0, 1)])
        z, t = [z[i] + h / 6 * (k1[i] + 2 * k2[i] + 2 * k3[i] + k4[i]) for i in (0, 1)], t + h
    return z

def P(z): return flow(z, 0.0, TAU, N)                 # the once-per-period (stroboscopic) map
def fmt(z): return "({:.4f}, {:.4f})".format(*(round(v, 4) + 0.0 for v in z))   # no "-0.0000"

c = P([0.0, 0.0]); p1, p2 = P([1.0, 0.0]), P([0.0, 1.0])
M = [[p1[0] - c[0], p2[0] - c[0]], [p1[1] - c[1], p2[1] - c[1]]]   # columns: where each unit push goes
w = math.sqrt(1 - B * B / 4); s, k = math.sin(TAU * w) / w, math.exp(-B / 2 * TAU)
Mh = [[k * (math.cos(TAU * w) + s * B / 2), k * s], [-k * s, k * (math.cos(TAU * w) - s * B / 2)]]
d = (1 - M[0][0]) * (1 - M[1][1]) - M[0][1] * M[1][0]               # solve (I - M) z = c by Cramer
zs = [(c[0] * (1 - M[1][1]) + M[0][1] * c[1]) / d, ((1 - M[0][0]) * c[1] + M[1][0] * c[0]) / d]
amp = 1 / B                                           # steady x = a cos t + b sin t forces a = 0, b = 1/0.2
T, D = M[0][0] + M[1][1], M[0][0] * M[1][1] - M[0][1] * M[1][0]
size, ang = math.sqrt(D), math.atan2(math.sqrt(D - T * T / 4), T / 2)
gaps, z = [], [0.0, 0.0]
for n in range(9): gaps.append(math.dist(z, zs)); z = P(z)
half = flow([0.0, amp], 0.0, TAU / 2, N // 2)
print(f"law x'' + {B}x' + x = cos t; eigenvalues of A: {-B / 2} +/- {w:.6f}i")
print(f"P(0, 0) = c = {fmt(c)}")
print(f"M by Runge-Kutta: [[{M[0][0]:.6f}, {M[0][1]:.6f}], [{M[1][0]:.6f}, {M[1][1]:.6f}]]")
print(f"M by formula:     [[{Mh[0][0]:.6f}, {Mh[0][1]:.6f}], [{Mh[1][0]:.6f}, {Mh[1][1]:.6f}]]")
print(f"fixed point of P: {fmt(zs)}; steady oscillation (1/B) sin t at t = 0: (0.0000, {amp:.4f})")
print(f"trace of M {T:.6f}, determinant {D:.6f} = exp(-2 pi B) {math.exp(-TAU * B):.6f}")
print(f"multipliers: size {size:.4f}, angle +/- {ang:.4f} rad; exp(-pi B) = {k:.4f}, 2 pi (1 - w) = {TAU * (1 - w):.4f}")
print("gap to fixed point after n periods from rest:", ", ".join(f"{g:.4f}" for g in gaps))
print("prediction (1/B) exp(-pi B)^n:               ", ", ".join(f"{amp * k ** n:.4f}" for n in range(9)))
print(f"chart, x(t) every quarter period from rest: " + ", ".join(f"{flow([0.0, 0.0], 0.0, j * TAU / 4, j * N // 4 + 1)[0]:.2f}" for j in range(25)))
print(f"mistake, forcing dropped: fixed point (0.0000, 0.0000), amplitude 0 not {amp:.0f}")
print(f"mistake, per-time factor exp(-0.1) = {math.exp(-B / 2):.4f} as per-period: gap after 5 periods {amp * math.exp(-B / 2) ** 5:.4f}, true {gaps[5]:.4f}")
print(f"mistake, sampling every pi: steady state at t = pi is {fmt(half)}, so samples flip; not a 2-cycle")
assert max(abs(M[i][j] - Mh[i][j]) for i in (0, 1) for j in (0, 1)) < 1e-9    # numeric map = matrix exponential
assert abs(zs[0]) + abs(zs[1] - amp) < 1e-9 and math.dist(P(zs), zs) < 1e-9     # fixed point = steady oscillation
assert abs(size - math.exp(-B * math.pi)) < 1e-9 and abs(ang - TAU * (1 - w)) < 1e-6   # Floquet multipliers
assert abs(gaps[8] / gaps[7] - k) < 0.01 and abs(half[1] + amp) < 1e-9          # gap ratio tends to exp(-pi B)
print("ALL CHECKS PASS")
