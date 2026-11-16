# Weak solutions: the tent-shaped sheet, a kinked rope pulse and a Burgers shock.
# Standard library only. Simpson's rule, the bumps and the grid solve are written out here.
import math

T, A, H = 200.0, 0.5, 0.05           # tension N/m, half-side m (1 m square), apex height m
SL = H / A                           # slope of each face
Q = math.sqrt(2) * T * SL            # load per metre of rod, N/m (Step 3)

def simpson(f, lo, hi, n=200):       # composite Simpson's rule, n even
    if hi <= lo:
        return 0.0
    s, d = f(lo) + f(hi), (hi - lo) / n
    for i in range(1, n):
        s += (4 if i % 2 else 2) * f(lo + i * d)
    return s * d / 3

def z(x):                            # print a rounding-level number as 0
    return 0.0 if abs(x) < 5e-7 else x

def tent(x, y):                      # the sheet's height, m
    return H * (1 - max(abs(x), abs(y)) / A)

def bump(cx, cy, r):                 # smooth test function: height 1, zero outside radius r
    def v(x, y):
        p2 = ((x - cx) ** 2 + (y - cy) ** 2) / r ** 2
        return math.e * math.exp(-1 / (1 - p2)) if p2 < 1 else 0.0
    def grad(x, y):
        p2 = ((x - cx) ** 2 + (y - cy) ** 2) / r ** 2
        if p2 >= 1:
            return 0.0, 0.0
        g = v(x, y) * -2 / (1 - p2) ** 2 / r ** 2
        return g * (x - cx), g * (y - cy)
    return v, grad, (cx - r, cx + r, cy - r, cy + r)

# road 1: a(u, v) = T * integral of grad u . grad v, face by face, iterated Simpson
FACES = [((-SL, 0.0), lambda s, t: (s, t), 0, 1), ((SL, 0.0), lambda s, t: (-s, t), 0, -1),
         ((0.0, -SL), lambda s, t: (t, s), 2, 1), ((0.0, SL), lambda s, t: (t, -s), 2, -1)]
def a_form(grad, box):
    total = 0.0
    for (gx, gy), pt, k, sg in FACES:  # face = {s in (0, A), |t| < s}, mapped to the sheet by pt
        lo, hi = sorted((sg * box[k], sg * box[k + 1]))
        tlo, thi = box[2 - k], box[3 - k]
        def inner(s):
            f = lambda t: gx * grad(*pt(s, t))[0] + gy * grad(*pt(s, t))[1]
            return simpson(f, max(-s, tlo), min(s, thi))
        total += T * simpson(inner, max(0.0, lo), min(A, hi), 400)
    return total

# road 2: l(v) = Q * integral of v along both rods (the diagonals)
def l_form(v):
    L = 2 * math.sqrt(2) * A
    d1 = simpson(lambda s: v(-A + s / math.sqrt(2), -A + s / math.sqrt(2)), 0, L, 800)
    d2 = simpson(lambda s: v(-A + s / math.sqrt(2), A - s / math.sqrt(2)), 0, L, 800)
    return Q * (d1 + d2)

print(f"sheet: 1 m square, T = {T:.0f} N/m, apex {H*100:.0f} cm, face slope {SL:.2f}, rod load q = {Q:.4f} N/m")
print(f"hand: slope jump across a rod {math.sqrt(2)*SL:.6f}, rod length 2 x {2*math.sqrt(2)*A:.4f} m, area under the rods {2*math.sqrt(2)*A*H:.6f} m^2")
print(f"total lift: rods q x {4*math.sqrt(2)*A:.4f} m = {Q*4*math.sqrt(2)*A:.4f} N; frame T x slope x {8*A:.0f} m = {T*SL*8*A:.4f} N")
assert abs(Q * 4 * math.sqrt(2) * A - T * SL * 8 * A) < 1e-9   # force balance: the rods lift what the frame pulls down
rows = []
for name, (cx, cy, r) in [("A apex", (0.0, 0.0, 0.3)), ("B on a rod", (0.25, 0.25, 0.15)), ("C inside a face", (0.3, 0.0, 0.1))]:
    v, g, box = bump(cx, cy, r)
    av, lv = a_form(g, box), l_form(v)
    rows.append((av, lv))
    print(f"bump {name:16s} centre ({cx:.2f}, {cy:.2f}) m r {r:.2f} m: a(u,v) = {z(av):8.4f} N, l(v) = {z(lv):8.4f} N")
assert all(abs(av - lv) < 1e-6 for av, lv in rows)          # the tent solves the weak form
assert abs(rows[0][0]) > 1 and abs(rows[2][0]) < 1e-9          # free sheet (f = 0) fails bump A only
au = T * SL ** 2 * (2 * A) ** 2                                  # v = u itself, an H^1_0 test
lu = 2 * Q * simpson(lambda s: tent(-A + s / math.sqrt(2), -A + s / math.sqrt(2)), 0, 2 * math.sqrt(2) * A, 800)
print(f"test with v = u: a(u,u) = {au:.4f} J, l(u) = {lu:.4f} J; stored energy {au/2:.4f} J; slope integral {au/T:.4f} m^2")
assert abs(au - lu) < 1e-9
# strong form at a rod point: centred-difference Laplacian has no limit
for d in (0.01, 0.001, 0.0001):
    x = y = 0.25
    lap = (tent(x + d, y) + tent(x - d, y) + tent(x, y + d) + tent(x, y - d) - 4 * tent(x, y)) / d ** 2
    lap2 = (tent(0.3 + d, 0) + tent(0.3 - d, 0) + tent(0.3, d) + tent(0.3, -d) - 4 * tent(0.3, 0)) / d ** 2
    print(f"step {d:.4f} m: -T x Laplacian on a rod {-T*lap:10.1f} N/m^2, inside a face {abs(T*lap2):.1f} N/m^2")
    assert abs(-T * lap - 2 * T * H / (A * d)) < 1e-6 * T / d
# road 3: relax the free sheet between the rods on a grid; it settles into the tent's flat faces
n = 20; dx = 2 * A / n
U = [[0.0] * (n + 1) for _ in range(n + 1)]
fixed = lambda i, j: i in (0, n) or j in (0, n) or i == j or i + j == n
for i in range(n + 1):
    U[i][i] = U[i][n - i] = tent(-A + i * dx, -A + i * dx)
for sweep in range(5000):
    ch = 0.0
    for i in range(1, n):
        for j in range(1, n):
            if not fixed(i, j):
                new = (U[i-1][j] + U[i+1][j] + U[i][j-1] + U[i][j+1]) / 4
                ch, U[i][j] = max(ch, abs(new - U[i][j])), new
    if ch < 1e-15:
        break
gap = max(abs(U[i][j] - tent(-A + i * dx, -A + j * dx)) for i in range(n + 1) for j in range(n + 1))
print(f"grid {n}x{n}, step {dx:.2f} m: relaxed sheet vs tent, largest gap {gap*1000:.6f} mm")
assert gap < 1e-9
print("chart x (m):", ", ".join(f"{-A+k*0.125:.3f}" for k in range(9)))
print("chart y=0 (cm):", ", ".join(f"{100*tent(-A+k*0.125,0):.2f}" for k in range(9)))
print("chart y=0.25 (cm):", ", ".join(f"{100*tent(-A+k*0.125,0.25):.2f}" for k in range(9)))
print(f"breaks: slope jump along x gives q = {T*SL:.4f} N/m, total {T*SL*4*math.sqrt(2)*A:.4f} N; v = 1: a = 0, l = {Q*4*math.sqrt(2)*A:.4f} N")

# 1D bumps for the space-time checks
def b(s):  return math.e * math.exp(-1 / (1 - s * s)) if abs(s) < 1 else 0.0
def b1(s): return b(s) * -2 * s / (1 - s * s) ** 2 if abs(s) < 1 else 0.0
def b2(s): return b(s) * ((-2 * s / (1 - s * s) ** 2) ** 2 - 2 / (1 - s * s) ** 2 - 8 * s * s / (1 - s * s) ** 3) if abs(s) < 1 else 0.0
# wave: a tent pulse on a rope, u = F(x - ct); very weak form: integral of u (v_tt - c^2 v_xx) = 0
C, HW, W = 10.0, 0.02, 0.2           # wave speed m/s, pulse height m, half-width m
X0, RX, T0, RT = 0.5, 0.4, 0.05, 0.04
def wave_res(speed):
    def inner(t):
        F = lambda x: HW * max(0.0, 1 - abs(x - speed * t) / W)
        f = lambda x: F(x) * (b((x - X0) / RX) * b2((t - T0) / RT) / RT**2 - C**2 * b2((x - X0) / RX) / RX**2 * b((t - T0) / RT))
        cuts = sorted([X0 - RX, X0 + RX] + [min(max(speed * t + k * W, X0 - RX), X0 + RX) for k in (-1, 0, 1)])
        return sum(simpson(f, cuts[k], cuts[k + 1]) for k in range(4))
    return simpson(inner, T0 - RT, T0 + RT, 400)
rw, rw12 = wave_res(10.0), wave_res(12.0)
print(f"wave c = 10 m/s, tent pulse {HW*100:.0f} cm high, {W:.1f} m half-width: kinked pulse at 10 m/s residual {z(rw):.6f} m^2/s; at 12 m/s {rw12:.6f} m^2/s")
assert abs(rw) < 1e-8 and abs(rw12) > 1e-4
# Burgers u_t + (u^2/2)_x = 0 (scaled): a jump from 1 to 0 moving at speed s
P0, RP, S0, RS = 0.5, 0.4, 1.0, 0.5
def burgers_res(s, left):            # brute force: integral of u v_t + (u^2/2) v_x over the plane
    def inner(t):
        g = lambda x: b((x - P0) / RP) * b1((t - S0) / RS) / RS + 0.5 * b1((x - P0) / RP) / RP * b((t - S0) / RS)
        k = min(max(s * t, P0 - RP), P0 + RP)
        return simpson(g, P0 - RP, k) if left else simpson(g, k, P0 + RP)
    return simpson(inner, S0 - RS, S0 + RS, 400)
def rh(s):                           # Rankine-Hugoniot road: (1/2 - s) x integral of v along the jump
    return (0.5 - s) * simpson(lambda t: b((s * t - P0) / RP) * b((t - S0) / RS), S0 - RS, S0 + RS, 400)
for s in (0.5, 1.0):
    print(f"Burgers jump 1 -> 0 at speed {s:.1f}: residual {z(burgers_res(s, True)):.6f}, Rankine-Hugoniot road {z(rh(s)):.6f}")
    assert abs(burgers_res(s, True) - rh(s)) < 1e-6
print(f"Burgers jump 0 -> 1 at speed 0.5: residual {z(burgers_res(0.5, False)):.6f} (also weak; entropy rules it out)")
assert abs(rh(1.0)) > 0.01 and abs(burgers_res(0.5, False)) < 1e-6
print("ALL CHECKS PASS")
