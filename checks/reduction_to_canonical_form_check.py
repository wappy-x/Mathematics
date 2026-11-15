# Canonical form -- the check behind the card.  Only math is imported.
# Road 1: exact integer algebra.  The chain rule gives the new coefficients
#   A' = A a1^2 + B a1 b1 + C b1^2,  B' = 2A a1 a2 + B(a1 b2 + b1 a2) + 2C b1 b2,
#   C' = A a2^2 + B a2 b2 + C b2^2   for xi = a1 p + b1 q, eta = a2 p + b2 q.
# Road 2: bisection finds the characteristic speeds without the quadratic formula.
# Road 3: centred differences test the solutions in the ORIGINAL coordinates.
# Road 4: the strip's tone three ways: closed form, round trip, far-end scan.
import math

def transform(A, B, C, D, E, a1, b1, a2, b2):
    return (A*a1*a1 + B*a1*b1 + C*b1*b1, 2*A*a1*a2 + B*(a1*b2 + b1*a2) + 2*C*b1*b2,
            A*a2*a2 + B*a2*b2 + C*b2*b2, D*a1 + E*b1, D*a2 + E*b2, a1*b2 - b1*a2)

def bisect(f, lo, hi):
    for _ in range(200):
        mid = (lo + hi) / 2
        if (f(lo) < 0) == (f(mid) < 0): lo = mid
        else: hi = mid
    return (lo + hi) / 2

def residual(co, u, p, q, hp, hq):  # relative size of A u_pp + B u_pq + C u_qq + D u_p + E u_q
    A, B, C, D, E = co
    upp = (u(p + hp, q) - 2*u(p, q) + u(p - hp, q)) / hp**2
    uqq = (u(p, q + hq) - 2*u(p, q) + u(p, q - hq)) / hq**2
    upq = (u(p+hp, q+hq) - u(p+hp, q-hq) - u(p-hp, q+hq) + u(p-hp, q-hq)) / (4*hp*hq)
    up = (u(p + hp, q) - u(p - hp, q)) / (2*hp); uq = (u(p, q + hq) - u(p, q - hq)) / (2*hq)
    terms = [A*upp, B*upq, C*uqq, D*up, E*uq]
    return abs(sum(terms)) / sum(abs(x) for x in terms)

def sci(v):
    e = math.floor(math.log10(v)); m = v / math.pow(10, e)
    if round(m, 2) >= 10: m /= 10; e += 1
    return f"{m:.2f}e{e:+03d}"

def ladder(co, u, p, q, h, k):  # residual at three steps and the observed order
    r = [residual(co, u, p, q, h / 2**i, k / 2**i) for i in range(3)]
    return r, math.log2(r[1] / r[2])

# ---- the moving steel strip: wave speed c on the strip, line speed V, span L ----
c, V, L = 80, 20, 2                      # m/s, m/s, m (illustrative)
A, B, C = 1, 2*V, -(c*c - V*V)          # u_tt + 2V u_xt - (c^2 - V^2) u_xx = 0, variables (t, x)
disc = B*B - 4*A*C
print(f"strip: c = {c} m/s, V = {V} m/s, L = {L} m")
print(f"strip: A, B, C = {A}, {B} m/s, {C} m^2/s^2; B^2 - 4AC = {disc} m^2/s^2")
quad = lambda lam: A*lam*lam - B*lam + C          # A' for xi = x - lam t
r = math.isqrt(disc); assert r * r == disc
lp, lm = (B + r) // (2*A), (B - r) // (2*A)
bp, bm = bisect(quad, B / (2*A), 1e4), bisect(quad, -1e4, B / (2*A))
print(f"speeds: formula {lp} and {lm} m/s; bisection {bp:.9f} and {bm:.9f} m/s")
assert abs(bp - (V + c)) < 1e-9 and abs(bm - (V - c)) < 1e-9
Ap, Bp, Cp, _, _, J = transform(A, B, C, 0, 0, -lp, 1, -lm, 1)
print(f"xi = x - {lp} t, eta = x + {-lm} t: A', B', C' = {Ap}, {Bp}, {Cp}; J = {J} m/s")
print(f"invariant: B'^2 - 4A'C' = {Bp*Bp - 4*Ap*Cp} = J^2 (B^2 - 4AC) = {J*J} x {disc}")
assert (Ap, Cp) == (0, 0) and Bp*Bp - 4*Ap*Cp == J*J*disc
S = transform(A, B, C, 0, 0, -V, 1, c, 0)  # s = (xi + eta)/2 = x - V t, r = (eta - xi)/2 = c t
print(f"s = x - {V} t, r = {c} t: A', B', C' = {S[0]}, {S[1]}, {S[2]}  (v_rr = v_ss)")
assert S[1] == 0 and S[0] == -S[2]
F = lambda z: math.exp(-(z / 0.1)**2); G = lambda z: 0.5 * math.exp(-((z - 0.7) / 0.2)**2)
good = lambda t, x: F(x - lp*t) + G(x - lm*t)
bad = lambda t, x: F(x - c*t) + G(x + c*t)          # still-strip speeds, flow ignored
rg, og = ladder((A, B, C, 0, 0), good, 0.004, 0.5, 0.0002, 0.02)
rb, ob = ladder((A, B, C, 0, 0), bad, 0.004, 0.5, 0.0002, 0.02)
print(f"residual at x = 0.5 m, t = 0.004 s; space steps 0.02, 0.01, 0.005 m, time step = space step / ({lp} m/s):")
print(f"  F(x - {lp}t) + G(x + {-lm}t): {', '.join(sci(v) for v in rg)}; order {og:.2f}")
print(f"  F(x - {c}t) + G(x + {c}t):  {', '.join(sci(v) for v in rb)}; order {ob:.2f}")
assert 1.9 < og < 2.1 and rg[2] < 0.01 * rb[2] and min(rb) > 0.1

# ---- parabolic and elliptic reductions, variables (x, y) ----
H = transform(1, 2, 1, 0, -1, -1, 1, 1, 0)   # u_xx + 2u_xy + u_yy - u_y; xi = y - x, eta = x
print(f"heat type: A, B, C, D, E = 1, 2, 1, 0, -1; B^2 - 4AC = {2*2 - 4*1*1}; xi = y - x, eta = x: A', B', C' = {H[0]}, {H[1]}, {H[2]}; "
      f"D', E' = {H[3]}, {H[4]}; J = {H[5]}")
assert H[:5] == (0, 0, 1, -1, 0)
rh, oh = ladder((1, 2, 1, 0, -1), lambda x, y: math.exp(-(y - x)) * math.sin(x), 0.5, 1.0, 0.1, 0.1)
print(f"  e^-(y-x) sin x: residual {', '.join(sci(v) for v in rh)}; order {oh:.2f}")
LA, LB, LC = 1, 2, 5                              # u_xx + 2u_xy + 5u_yy = 0
al, d4 = LB // (2*LA), 4*LA*LC - LB*LB           # roots alpha +- i beta of LA l^2 - LB l + LC
be = math.isqrt(d4) // (2*LA); assert (2*LA*be)**2 == d4 and 2*LA*al == LB
Lp = transform(LA, LB, LC, 0, 0, -al, 1, be, 0)   # xi = y - alpha x, eta = beta x
print(f"Laplace type: A, B, C = {LA}, {LB}, {LC}; B^2 - 4AC = {-d4}; alpha, beta = {al}, {be}; xi = y - alpha x, eta = beta x: A', B', C' = {Lp[0]}, {Lp[1]}, {Lp[2]}")
assert Lp[:3] == (d4 // (4*LA), 0, d4 // (4*LA))      # (4AC - B^2)/(4A) each
rl, ol = ladder((LA, LB, LC, 0, 0), lambda x, y: math.exp(y - al*x) * math.cos(be*x), 0.5, 1.0, 0.1, 0.1)
print(f"  e^(y - alpha x) cos(beta x): residual {', '.join(sci(v) for v in rl)}; order {ol:.2f}")
assert 1.9 < oh < 2.1 and 1.9 < ol < 2.1

# ---- the tone of the strip between two fixed rollers ----
f_still, f_form = c / (2*L), (c*c - V*V) / (2*L*c)
trip = L / (V + c) + L / (c - V)
print(f"tone: still strip c/2L = {f_still:.2f} Hz; moving, (c^2 - V^2)/(2Lc) = {f_form:.2f} Hz")
print(f"tone: round trip {L/(V+c):.4f} s + {L/(c-V):.4f} s = {trip:.4f} s, so {1/trip:.2f} Hz")
def far_end(f):   # largest |u(L, t)| over one period for the mode sin(wt - k1 x) - sin(wt - k2 x)
    w = 2*math.pi*f; k1, k2 = w / (V + c), w / (V - c)
    return max(abs(math.sin(w*t - k1*L) - math.sin(w*t - k2*L)) for t in [i / (200*f) for i in range(200)])
scan = [far_end(i / 100) for i in range(1, 5001)]  # 0.01 to 50 Hz
rise = next(i for i in range(5000) if scan[i] > 1)   # skip the zero at 0 Hz
first = next(i for i in range(rise, 5000) if scan[i] < 0.05)
best = min(range(first, first + 30), key=lambda i: scan[i]) + 1
print(f"tone: far-end scan 0.01 to 50 Hz finds {best/100:.2f} Hz; far end at {f_form:.2f} Hz {far_end(f_form):.6f}, "
      f"at {f_still:.2f} Hz {far_end(f_still):.6f}")
assert abs(best / 100 - f_form) < 0.006 and abs(1 / trip - f_form) < 1e-9
print("tone at line speed 0, 40, 80 m/s: " + ", ".join(f"{(c*c - v*v) / (2*L*c):.2f}" for v in (0, 40, 80)) + " Hz")

# ---- what breaks ----
W = transform(A, B, C, 0, 0, -c, 1, c, 1)
print(f"breaks: still-strip speeds {c} and {-c} m/s: A', C' = {W[0]}, {W[2]} (not 0)")
X = transform(A, B, C, 0, 0, lp, 1, lm, 1)
print(f"breaks: signs slipped, speeds {-lp} and {-lm} m/s: A', C' = {X[0]}, {X[2]}")
Y = transform(LA, LB, LC, 0, 0, -al, 1, 1, 0)
print(f"breaks: Laplace type with eta = x (beta dropped): A', B', C' = {Y[0]}, {Y[1]}, {Y[2]}")
Z = transform(1, 2, 1, 0, -1, -1, 1, -2, 2)
print(f"breaks: heat type with eta = 2(y - x): J = {Z[5]}")
tri = lambda y: 0*0 - 4*y*1                     # Tricomi y u_xx + u_yy: A = y, B = 0, C = 1
print(f"breaks: Tricomi y u_xx + u_yy: B^2 - 4AC = {tri(1)} at y = 1, {tri(-1)} at y = -1")
assert (W[0], W[2], X[0], X[2]) == (quad(c), quad(-c), quad(-lp), quad(-lm)) and W[0] != 0 and X[0] != 0
assert (Y[0], Y[1], Y[2]) == (LA*al*al - LB*al + LC, 0, LA) and Y[0] != Y[2] and Z[5] == 0
print(f"figure, round trip (m, s): (0, 0) -> ({L}, {L/(V+c):.7f}) -> (0, {trip:.7f})")
print("ALL CHECKS PASS")
