# Undetermined coefficients -- the check behind the card.  Standard library only.
# A swing pushed every 6.28 s: y'' + 2y' + 5y = 10 cos t, y in dm, t in s, from
# rest.  Road one: trial A cos t + B sin t, its equations solved by Cramer's rule.
# Road two: A and B from the left side applied numerically to cos t and sin t.
# Road three: plain Euler steps on the raw law, which never guesses a shape.
import math

C, K, F, W = 2.0, 5.0, 10.0, 1.0          # damping, stiffness, push size, push rate
def law(t, y, v): return F * math.cos(W * t) - C * v - K * y   # acceleration
def L(f, t, d=1e-4):                      # y'' + 2y' + 5y by finite differences
    a, b, m = f(t), f(t + d), f(t - d)
    return (b - 2 * a + m) / d**2 + C * (b - m) / (2 * d) + K * a

p, q = K - W * W, C * W                   # coefficient equations: pA + qB = F, -qA + pB = 0
A, B = F * p / (p * p + q * q), F * q / (p * p + q * q)          # Cramer's rule
m11, m12, m21, m22 = L(math.cos, 0), L(math.sin, 0), L(math.cos, 1), L(math.sin, 1)
det = m11 * m22 - m12 * m21               # road two: L[A cos + B sin] = 10 cos at t = 0, 1
A2, B2 = (F * m22 - m12 * F * math.cos(1)) / det, (m11 * F * math.cos(1) - m21 * F) / det
C1, C2 = -A, (-A - B) / 2                 # y(0) = 0 and y'(0) = 0 fix the transient
steady = lambda t: A * math.cos(t) + B * math.sin(t)
def closed(t): return steady(t) + math.exp(-t) * (C1 * math.cos(2 * t) + C2 * math.sin(2 * t))

def euler(n, h, y=0.0, v=0.0, t=0.0, track=False):   # plain small steps along the slope
    best = (-1e9, 0.0)
    for _ in range(n):
        y, v, t = y + h * v, v + h * law(t, y, v), t + h
        best = max(best, (y, t)) if track else best
    return y, v, best

errs = [abs(euler(round(10 / h), h)[0] - closed(10)) for h in (0.01, 0.005, 0.0025)]
h, n0 = 0.001, round(6 * math.pi / 0.001)
y6, v6, _ = euler(n0, h)                  # by t = 6 pi the transient is e^(-18.8) small
_, _, (top, t_top) = euler(round(2 * math.pi / h), h, y6, v6, n0 * h, True)
ramp = L(lambda t: t - 0.4, 1.5)          # forcing 5t, trial At + B gives A = 1, B = -0.4
expo = L(lambda t: math.exp(t), 1.0)      # forcing 8e^t, trial Ae^t gives 8A = 8
plain = L(lambda t: math.exp(-t) * math.cos(2 * t), 1.0)
times_t = L(lambda t: t / 4 * math.exp(-t) * math.sin(2 * t), 1.0)
print("t (s)      ", list(range(13)))
print("swing (dm) ", ", ".join(f"{closed(t):.2f}" for t in range(13)))
print("steady (dm)", ", ".join(f"{steady(t):.2f}" for t in range(13)))
print(f"characteristic roots: {-C / 2:.4f} +/- {math.sqrt(4 * K - C * C) / 2:.4f}i; own ring every {2 * math.pi / (math.sqrt(4 * K - C * C) / 2):.2f} s, push every {2 * math.pi / W:.2f} s")
print(f"coefficient equations {p:.0f}A + {q:.0f}B = {F:.0f}, {-q:.0f}A + {p:.0f}B = 0: det {p * p + q * q:.0f}, Cramer A = {A:.4f}, B = {B:.4f}")
print(f"operator applied numerically to cos t, sin t: A = {A2:.4f}, B = {B2:.4f}")
print(f"steady height sqrt(A^2 + B^2) = {math.hypot(A, B):.4f} dm; lag atan(B/A) = {math.atan2(B, A):.4f} s")
print(f"transient from rest: C1 = {C1:.4f}, C2 = {C2:.4f}, at most {math.hypot(C1, C2):.2f}e^(-t); under 0.1 dm after ln 25 = {math.log(25):.2f} s")
print(f"y(1): closed {closed(1):.4f}, Euler h = 0.001 {euler(1000, 0.001)[0]:.4f}; y(10): closed {closed(10):.4f}, Euler h = 0.0025 {euler(4000, 0.0025)[0]:.4f}")
print("Euler error at t = 10, h = 0.01, 0.005, 0.0025:", " ".join(f"{e:.5f}" for e in errs))
print(f"error ratios on halving h: {errs[0] / errs[1]:.3f} {errs[1] / errs[2]:.3f}")
print(f"Euler, one late cycle: height {top:.4f} dm, peak {t_top - 6 * math.pi:.3f} s after the push peak")
print(f"ramp 5t, trial t - 0.4: left side at t = 1.5 is {ramp:.4f}; 5t = {7.5:.4f}")
print(f"exponential 8e^t, trial e^t: left side at t = 1 is {expo:.4f}; 8e = {8 * math.e:.4f}")
print(f"collision e^(-t) cos 2t at t = 1: plain trial gives {abs(plain):.4f}; (t/4)e^(-t) sin 2t gives {times_t:.4f}; target {math.exp(-1) * math.cos(2):.4f}")
print(f"mistake, cosine-only trial 2.5 cos t: left side minus push at t = pi/2 is {L(lambda t: 2.5 * math.cos(t), math.pi / 2) - F * math.cos(math.pi / 2):.4f}")
print(f"mistake, start fitted before adding the steady part: y(0) = {steady(0):.2f}, y'(0) = {B:.2f}, not 0")
print(f"mistake, height read as A + B = {A + B:.2f}; truth {math.hypot(A, B):.2f}")
assert abs(A2 - A) < 1e-5 and abs(B2 - B) < 1e-5                                   # roads one, two
assert 1.8 < errs[0] / errs[1] < 2.2 and 1.8 < errs[1] / errs[2] < 2.2 and errs[2] < 0.01 and abs(euler(1000, 0.001)[0] - closed(1)) < 0.005
assert abs(top - math.hypot(A, B)) < 0.01 and abs(t_top - 6 * math.pi - math.atan2(B, A)) < 0.01
assert abs(ramp - 7.5) < 1e-5 and abs(times_t - math.exp(-1) * math.cos(2)) < 1e-5 and abs(plain) < 1e-5 and abs(expo - 8 * math.e) < 1e-5
print("ALL CHECKS PASS")
