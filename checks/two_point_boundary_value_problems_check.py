# Two-point boundary value problems -- the check behind the card.  Standard
# library only.  The strut y'' + y = 0 (x in m, y in cm) has every solution
# A cos x + B sin x.  Road one fits A and B to both ends with sin and cos.
# Road two never calls them: RK4 steps v, the solution with v(0) = 0 and
# v'(0) = 1, to the far end, and fits B from its value and slope there.
# u, with u(0) = 1 and u'(0) = 0, is stepped for the Neumann case.
import math

def rk4(L, n, y=0.0, p=1.0):         # step (y, y') across [0, L] in n steps
    h = L / n
    for _ in range(n):
        k1 = (p, -y); k2 = (p + h / 2 * k1[1], -(y + h / 2 * k1[0]))
        k3 = (p + h / 2 * k2[1], -(y + h / 2 * k2[0])); k4 = (p + h * k3[1], -(y + h * k3[0]))
        y += h / 6 * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0])
        p += h / 6 * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1])
    return y, p

def sci(x, d):                       # 7.16e-7, the way Rust prints {:.2e}
    e = math.floor(math.log10(abs(x)))
    return f"{x / 10 ** e:.{d}f}e{e}"

s1, c1, pi = math.sin(1), math.cos(1), math.pi
v1, dv1 = rk4(1, 100)                # road two at x = 1 m, h = 0.01
vpi, dvpi = rk4(pi, 314)             # road two at x = pi m
upi, dupi = rk4(pi, 314, 1.0, 0.0)   # u at x = pi m
B, Bn, Br = 1 / s1, 1 / c1, 1 / (s1 + c1)
errs = [abs(1 / rk4(1, n)[0] - B) for n in (10, 20, 40)]
pts = lambda f, xs: " ".join(f"{40 + 300 / pi * x:.1f},{190 - 120 * f(x):.1f}" for x in xs)
print("strut y'' + y = 0, every solution y = A cos x + B sin x; x in m, y in cm")
print(f"[0, 1], ends 0 and 1: D = sin 1 = {s1:.6f}; A = 0, B = 1/sin 1 = {B:.6f}")
print(f"  road two, stepped v(1) = {v1:.6f}, B = {1 / v1:.6f}; midpoint y(0.5) = {math.sin(0.5) * B:.6f} cm")
print(f"  RK4 error in B at h = 0.1 0.05 0.025: {sci(errs[0], 2)} {sci(errs[1], 2)} {sci(errs[2], 2)}; ratios {errs[0] / errs[1]:.1f} {errs[1] / errs[2]:.1f}")
print(f"[0, pi], ends 0 and 0: D = sin pi = 0 exactly (floating sin(pi) = {sci(math.sin(pi), 2)}, stepped v(pi) = {sci(vpi, 2)})")
fam = [rk4(pi, 314, 0.0, c)[0] for c in (0.5, 1, 2)]
print(f"  C sin x for C = 0.5 1 2, stepped y(pi): {sci(fam[0], 1)} {sci(fam[1], 1)} {sci(fam[2], 1)}: every C fits, infinitely many")
print(f"[0, pi], ends 0 and 1: y(pi) = -A = 1 but A = 0: none; naive B = 1/sin(pi) = {sci(1 / math.sin(pi), 2)}, 1/v(pi) = {sci(1 / vpi, 2)}")
print(f"house form -y'' = lambda y on [0, 1]: L = pi is lambda = pi^2 = {pi * pi:.6f}, the first eigenvalue")
print(f"Neumann [0, pi], y'(0) = y'(pi) = 0: B = 0 and -B = 0, A free: y = C cos x; stepped u'(pi) = {sci(dupi, 1)}")
print(f"Dirichlet-Neumann [0, 1], y(0) = 0, y'(1) = 1: B = 1/cos 1 = {Bn:.6f}; stepped 1/v'(1) = {1 / dv1:.6f}")
print(f"Robin [0, 1], y(0) = 0, y(1) + y'(1) = 1: B = 1/(sin 1 + cos 1) = {Br:.6f}; stepped {1 / (v1 + dv1):.6f}")
print(f"mistake, Robin sign flipped, y(1) - y'(1) = 1: B = {1 / (s1 - c1):.4f}, not {Br:.4f}")
print(f"hypothesis dropped, condition squared y(1)^2 = 1: B = +{B:.6f} or -{B:.6f}, exactly two; stepped y(1)^2 = {(B * v1) ** 2:.6f}")
print("figure, scale 95.49 px per m across, 120 px per cm up, origin (40, 190)")
print(f"figure, sin x on [0, pi]: {pts(math.sin, [pi * k / 12 for k in range(13)])}")
print(f"figure, 0.5 sin x: {pts(lambda x: 0.5 * math.sin(x), [pi * k / 12 for k in range(13)])}")
print(f"figure, sin x / sin 1 on [0, 1]: {pts(lambda x: math.sin(x) * B, [k / 4 for k in range(5)])}; target (pi, 1) at {pts(lambda x: 1, [pi])}")
assert abs(1 / v1 - B) < 1e-8 and abs(1 / dv1 - Bn) < 1e-8     # stepping meets the sine fit
assert 12 < errs[0] / errs[1] < 20 and abs(1 / (v1 + dv1) - Br) < 1e-8  # fourth order; Robin by both roads
assert max(abs(f) for f in fam) < 1e-8 and abs(dvpi + 1) < 1e-8 and abs(dupi) < 1e-8  # at pi: v = 0, v' = -1, u' = 0
print("ALL CHECKS PASS")
