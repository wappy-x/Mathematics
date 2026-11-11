# Second-order conditions on a pipe's capacity surface, checked five ways.
# Standard library only.  Maximise the power a water main delivers, P = C*q*H,
# written as minimising f0 = -P, subject to f1 = H + R*q^2 - RATING <= 0.
import math
C = 0.00981        # kW per (L/s * m): water weighs 9.81 kN per m^3, 1 L/s = 0.001 m^3/s
R = 0.000125       # m of friction head per (L/s)^2: 20 m lost at 400 L/s
RATING = 60.0      # m of head the main is rated for at the pump end

def power(q, H): return C * q * H
def f0(q, H): return -power(q, H)
def f1(q, H, r=R, rating=RATING): return H + r * q * q - rating
def grad_f0(q, H): return (-C * H, -C * q)
def grad_f1(q, H, r=R): return (2 * r * q, 1.0)
def hess_f0(): return ((0.0, -C), (-C, 0.0))
def hess_f1(r=R): return ((2 * r, 0.0), (0.0, 0.0))
def add(A, B, s): return tuple(tuple(A[i][j] + s * B[i][j] for j in range(2)) for i in range(2))
def quad(M, d): return sum(d[i] * M[i][j] * d[j] for i in range(2) for j in range(2))
def dot(u, v): return u[0] * v[0] + u[1] * v[1]
def eig2(M):       # eigenvalues of a symmetric 2x2 matrix, smallest first
    m = (M[0][0] + M[1][1]) / 2
    s = math.sqrt((M[0][0] - M[1][1]) * (M[0][0] - M[1][1]) / 4 + M[0][1] * M[0][1])
    return m - s, m + s
def on_surface(q, r=R, rating=RATING): return rating - r * q * q   # H on the surface
def best(r=R, rating=RATING):    # dP/dq along the surface = C*(rating - 3*r*q^2) = 0
    q = math.sqrt(rating / (3 * r))
    return q, on_surface(q, r, rating)
def tangent(q, r=R):             # a step of 10 L/s that keeps f1 = 0 to first order
    g = grad_f1(q, 0.0, r)
    return (10.0, -10.0 * g[0] / g[1])
def F(x, n=4): return f"{x:.{n}f}"

# ---- road 1: KKT, then the critical cone and the Lagrangian's curvature on it ----
q, H = best()
g0, g1 = grad_f0(q, H), grad_f1(q, H)
lam = -g0[1] / g1[1]                       # the H-row of grad f0 + lam * grad f1 = 0
res = (g0[0] + lam * g1[0], g0[1] + lam * g1[1])
W = add(hess_f0(), hess_f1(), lam)         # Hessian of the Lagrangian f0 + lam*f1
d = tangent(q)
part_f0, part_bend = quad(hess_f0(), d), lam * quad(hess_f1(), d)
along = quad(W, d)
print(f"maximise P = {C:.5f}*q*H kW subject to H + {R:.6f}*q^2 <= {RATING:.0f} m")
print(f"x* = ({F(q, 1)} L/s, {F(H)} m), friction {F(R * q * q)} m, P = {F(power(q, H))} kW")
print(f"grad f0 = ({F(g0[0])}, {F(g0[1])}), grad f1 = ({F(g1[0])}, {F(g1[1])})")
print(f"lambda = {F(lam)} kW per m of rating; KKT residual {F(abs(res[0]), 6)}, {F(abs(res[1]), 6)}")
h, worst = 1e-3, 0.0                       # derivatives against central differences
for fn, gr in ((f0, grad_f0), (f1, grad_f1)):
    nd = ((fn(q + h, H) - fn(q - h, H)) / (2 * h), (fn(q, H + h) - fn(q, H - h)) / (2 * h))
    worst = max(worst, abs(nd[0] - gr(q, H)[0]), abs(nd[1] - gr(q, H)[1]))
print(f"gradients against central differences: largest gap {worst:.1e}")
print(f"Hessian of the Lagrangian: {F(W[0][0], 6)}, {F(W[0][1], 6)} / {F(W[1][0], 6)}, {F(W[1][1], 6)}")
print(f"critical cone: lambda > 0, so 0.1*dq + dH = 0: d = ({F(d[0], 1)}, {F(d[1], 1)})")
print(f"along the surface d'Wd = {F(part_f0)} (cost) + {F(part_bend)} (bend) = {F(along)} kW")
out, inn = (10.0, 1.0), (-10.0, -1.0)
print(f"across, outward (10, 1): d'Wd = {F(quad(W, out))}, pump-end head +{F(dot(g1, out))} m: not allowed")
print(f"across, inward (-10, -1): d'Wd = {F(quad(W, inn))}, P falls {F(dot(g0, inn))} kW at first order")
# ---- road 2: walk along the surface itself and take a second difference ----
fs = [f0(x, on_surface(x)) for x in (q - 10, q, q + 10)]
second = fs[0] - 2 * fs[1] + fs[2]
print(f"road 2, second difference of f0 along the surface: {F(second)} kW")
acc = (0.0, -2 * R * d[0] * d[0])          # the path H = 60 - R*q^2 bends by this much
print(f"bend: path acceleration (0, {F(acc[1], 3)}) m; grad f0 . a = {F(dot(g0, acc))}"
      f" = lambda * d'(Hess f1)d = {F(part_bend)}")
for step in (10.0, 50.0):
    loss = power(q, H) - power(q + step, on_surface(q + step))
    print(f"slide {F(step, 0)} L/s along: true power loss {F(loss)} kW, quadratic model "
          f"{F(0.5 * along * (step / 10) * (step / 10))} kW")
# ---- road 3: the bordered Hessian, a determinant that needs no tangent ----
B = ((0.0, g1[0], g1[1]), (g1[0], W[0][0], W[0][1]), (g1[1], W[1][0], W[1][1]))
det = (B[0][0] * (B[1][1] * B[2][2] - B[1][2] * B[2][1]) - B[0][1] * (B[1][0] * B[2][2] - B[1][2] * B[2][0])
       + B[0][2] * (B[1][0] * B[2][1] - B[1][1] * B[2][0]))
print(f"road 3, bordered Hessian determinant {F(det, 6)} (negative: a strict minimum of f0)")
# ---- road 4: every feasible point on a 1 L/s by 0.1 m grid ----
top, arg, n = -1.0, None, 0
for i in range(701):
    for j in range(601):
        qq, HH = float(i), j / 10
        if f1(qq, HH) <= 1e-9:
            n += 1
            if power(qq, HH) > top:
                top, arg = power(qq, HH), (qq, HH)
print(f"road 4, {n} feasible grid points: best ({F(arg[0], 0)}, {F(arg[1], 1)}), P = {F(top)} kW")
print(f"drop q, H >= 0: q = H = -1000 gives f1 = {F(f1(-1000.0, -1000.0), 1)} m, P = {F(power(-1000.0, -1000.0), 2)} kW")
# ---- road 5: lambda read back as a price, by moving the rating ----
Pr = [power(*best(rating=RATING + s)) for s in (-1.0, 1.0)]
price = (Pr[1] - Pr[0]) / 2
print(f"road 5, (P*(61 m) - P*(59 m)) / 2 = {F(price, 5)} kW per m")
# ---- what breaks ----
e0, eW = eig2(hess_f0()), eig2(W)
print(f"mistake 1, Hessian of f0 alone, every direction: {F(e0[0], 6)}, {F(e0[1], 6)} -> 'saddle'")
print(f"mistake 2, Lagrangian Hessian, every direction: {F(eW[0], 6)}, {F(eW[1], 6)} -> 'no minimum'")
print(f"mistake 3, bend dropped: along-surface curvature {F(part_f0)}, model loss {F(part_f0 / 2)} kW;"
      f" lambda's sign flipped {F(part_f0 - part_bend)}")
q3 = 300.0
H3 = on_surface(q3)
lam3 = -grad_f0(q3, H3)[1]
curv3 = quad(add(hess_f0(), hess_f1(), lam3), tangent(q3))
slope3 = C * (RATING - 3 * R * q3 * q3)
print(f"mistake 4, at q = {F(q3, 0)}, H = {F(H3, 2)}: curvature {F(curv3)} > 0, yet P still rises"
      f" {F(slope3)} kW per L/s")
# ---- try changing ----
for label, r, rating in (("rating 80 m", R, 80.0), ("pipe twice as rough", 2 * R, RATING)):
    qa, Ha = best(r, rating)
    la = C * qa
    Wa = add(hess_f0(), hess_f1(r), la)
    print(f"try, {label}: x* = ({F(qa, 1)}, {F(Ha, 2)}), P = {F(power(qa, Ha), 2)} kW, lambda = {F(la)},"
          f" friction share {F(r * qa * qa / rating, 4)}, d'Wd = {F(quad(Wa, tangent(qa, r)))}")
print(f"figure, x*=({F(q, 1)},{F(H, 1)}), surface (0,60)-({F(math.sqrt(RATING / R), 1)},0),"
      f" contours qH={F(q * H, 0)} through x* and {F(q * H / 2, 0)}, tangent ({F(q - 100, 0)},{F(H + 10, 0)})-({F(q + 100, 0)},{F(H - 10, 0)})")

assert abs(q - 400) < 1e-9 and abs(H - 40) < 1e-9          # one-third rule: 20 m of 60 lost
assert lam > 0 and max(abs(res[0]), abs(res[1])) < 1e-12   # KKT, with the right sign
assert worst < 1e-6                                        # gradients agree with differences
assert along > 0 and abs(second - along) < 1e-9            # road 1 = road 2: positive curvature
assert abs(dot(g0, acc) - part_bend) < 1e-12               # the bend is lambda times f1's curvature
assert det < 0 and abs(det + along / 100) < 1e-12          # road 3 agrees with road 1
assert arg == (400.0, 40.0) and abs(top - power(q, H)) < 1e-9  # road 4: no grid point beats x*
assert f1(-1000.0, -1000.0) <= 0 and power(-1000.0, -1000.0) > top  # the floors q, H >= 0 matter
assert abs(price - lam) < 1e-4                             # road 5: lambda is the rating's price
assert eW[0] < 0 and quad(W, inn) < 0                      # the Lagrangian's full-space test misleads
assert slope3 > 0 and curv3 > 0                            # curvature alone proves nothing
print("ALL CHECKS PASS")
