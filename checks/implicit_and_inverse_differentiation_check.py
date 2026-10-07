# Implicit and inverse differentiation -- the check behind the card.  Only sqrt,
# sin and cos are imported; every inverse is found by halving an interval.  A
# round pond, radius 5 m, centre at the origin, x metres east, y metres north.
from math import sqrt, sin, cos
R, X, Y, U = 5.0, 3.0, 4.0, 0.6          # the marker post at (3, 4); U = 3/5

def inv(f, v, lo, hi):                    # solve f(t) = v for increasing f, by halving
    for _ in range(200):
        mid = (lo + hi) / 2
        if f(mid) < v: lo = mid
        else: hi = mid
    return (lo + hi) / 2
def asin_(u): return inv(sin, u, -1.5, 1.5)
def atan_(u): return inv(lambda t: sin(t) / cos(t), u, -1.5, 1.5)
def acos_(u): return inv(lambda t: -cos(t), -u, 0.0, 3.0)
def cq(f, x, h=1e-5): return (f(x + h) - f(x - h)) / (2 * h)   # central quotient

implicit = -X / Y                                     # road 1: 2x + 2y y' = 0
branch = cq(lambda t: sqrt(R * R - t * t), X)         # road 2: upper half as a graph
radius = Y / X; perp = -1 / radius                    # road 3: square to the radius
lower = cq(lambda t: -sqrt(R * R - t * t), X)
side = cq(lambda s: sqrt(R * R - s * s), 0.0)         # east side, x as a graph of y
print(f"post at ({X:.0f}, {Y:.0f}): {X:.0f}^2 + {Y:.0f}^2 = {X * X + Y * Y:.0f} = {R:.0f}^2")
print(f"slope: road 1, -x/y = {implicit:.6f}; road 2, upper branch {branch:.6f}; road 3, radius slope {radius:.6f}, square to it {perp:.6f}")
print(f"at (3, -4): -x/y = {-X / -Y:.6f}, lower branch {lower:.6f}; at (5, 0): dx/dy = {side:.6f}")
print(f"crossing lines y^2 = x^2 at (0, 0): relation gives 0 = 0; the lines' slopes {cq(lambda t: t, 0.0):.6f} and {cq(lambda t: -t, 0.0):.6f}")
th = asin_(U); rule1 = 1 / cos(th); rule2 = 1 / sqrt(1 - U * U)
print(f"bearing: arcsin({U}) = {th:.6f} rad = {th * 45 / atan_(1.0):.2f} deg; sin {sin(th):.6f}, cos {cos(th):.6f}")
print(f"arcsin rate: road 1, 1/cos(theta) = {rule1:.6f}; road 2, 1/sqrt(1 - u^2) = {rule2:.6f}; per metre east {rule1 / R:.6f}")
errs = []
for k in (0.1, 0.01, 0.001, 0.0001):                   # road 3: shrinking output steps
    q = (asin_(U + k) - th) / k
    errs.append(q - rule1)
    print(f"road 3, output step k = {k}: quotient {q:.6f}, error {q - rule1:.6f}")
lo, hi = 0.0, 0.1                                     # largest step within 0.001
for _ in range(60):
    mid = (lo + hi) / 2
    if (asin_(U + mid) - th) / mid - rule1 < 0.001: lo = mid
    else: hi = mid
print(f"tolerance: every output step under {lo:.5f} lands within 0.001 of {rule1:.2f}")
a = atan_(1.0); ac = acos_(U)
print(f"second case: arctan(1) = {a:.6f} rad; rule 1/(1 + u^2) = cos^2 = {cos(a) ** 2:.6f}; central quotient {cq(atan_, 1.0):.6f}")
print(f"arccos(0.6) = {ac:.6f}; rate 1/(-sin) = {-1 / sin(ac):.6f}; central quotient {cq(acos_, U):.6f}")
print(f"mistake 1, minus sign dropped: {X / Y:.6f}; mistake 2, chain factor dropped: 2*3 + 2*4 = {2 * X + 2 * Y:.0f}, not 0")
print(f"mistake 3, forward rate read at the output: 1/cos(0.6) = {1 / cos(U):.6f}; mistake 4, forward rate kept: {cos(th):.6f}")
cube = [inv(lambda t: t * t * t, h ** 3, -1.0, 1.0) / h ** 3 for h in (0.1, 0.01)]
print(f"cube at 0, forward rate 0: inverse quotients for h = 0.1, 0.01: {cube[0]:.1f}, {cube[1]:.1f}")
S, CX, CY = 20, 150, 125                              # figure: 20 px per metre, y down
tan_end = [(CX + S * x, CY - S * (Y + implicit * (x - X))) for x in (1.0, 5.0)]
arc = (CX + 30 * sin(th), CY - 30 * cos(th))
print(f"figure, {S} px per m: centre ({CX}, {CY}), radius {S * R:.0f}, post ({CX + S * X:.0f}, {CY - S * Y:.0f}), "
      f"tangent ({tan_end[0][0]:.0f}, {tan_end[0][1]:.0f}) to ({tan_end[1][0]:.0f}, {tan_end[1][1]:.0f}), "
      f"north tip ({CX}, {CY - S * R:.0f}), angle arc ({CX}, {CY - 30}) to ({arc[0]:.0f}, {arc[1]:.0f})")
assert abs(implicit - branch) < 1e-8 and abs(perp - branch) < 1e-8   # three roads, one slope
assert abs(errs[-1]) < 1e-3 and 9 < errs[1] / errs[2] < 11            # quotients close in
assert abs(cos(a) ** 2 - cq(atan_, 1.0)) < 1e-8                        # arctan rule vs quotient
assert cube[1] / cube[0] > 50                                          # no finite inverse rate
print("ALL CHECKS PASS")
