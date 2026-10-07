# Chain rule in several variables -- the check behind the card.  Nothing is
# imported.  A hiker walks the path p(t) = (2t, t^2) km (east, north) after t
# hours.  The weather map G(x, y) = (13 - x - y^2, 5 + xy + 3y) gives air
# temperature A in C and wind w in km/h; the felt temperature is
# F(A, w) = A - 0.02 w (30 - A).  Rate of the felt temperature at t = 1.
def p(t): return (2 * t, t * t)
def G(x, y): return (13 - x - y * y, 5 + x * y + 3 * y)
def F(A, w): return A - 0.02 * w * (30 - A)
def felt(t): return F(*G(*p(t)))
def matmul(P, Q):                       # rows of P against columns of Q
    return [[sum(P[i][k] * Q[k][j] for k in range(len(Q))) for j in range(len(Q[0]))]
            for i in range(len(P))]
def fmt(v, d=2): return "[" + ", ".join(f"{x:.{d}f}" for x in v) + "]"
t = 1.0
x, y = p(t); A, w = G(x, y)
Jp = [[2.0], [2 * t]]                                   # 2 x 1: km/h east, north
JG = [[-1.0, -2 * y], [y, x + 3]]                       # 2 x 2: read at (x, y)
JF = [[1 + 0.02 * w, -0.02 * (30 - A)]]                 # 1 x 2: read at (A, w)
inner = matmul(JG, Jp)                                  # rates of A and w per hour
chain = matmul(JF, inner)[0][0]                         # road 1: matrices multiply
grad = matmul(JF, JG)[0]                                # felt C per km, east and north
print(f"at t = 1 h: position ({x:.0f}, {y:.0f}) km, air {A:.0f} C, wind {w:.0f} km/h, felt {F(A, w):.2f} C")
print(f"J_p = {fmt([r[0] for r in Jp], 0)}; J_G rows {fmt(JG[0], 0)}, {fmt(JG[1], 0)}; J_F = {fmt(JF[0], 1)}")
print(f"J_G J_p: air {inner[0][0]:.0f} C/h, wind {inner[1][0]:.0f} km/h per h")
print(f"road 1, J_F (J_G J_p) = {chain:.2f} C/h")
routes = [JF[0][i] * JG[i][j] * Jp[j][0] for i in range(2) for j in range(2)]
print(f"four routes t -> x or y -> A or w -> F: {fmt(routes)}, sum {sum(routes):.2f}")
print(f"grouped the other way, J_F J_G = {fmt(grad)} C/km, times J_p: {grad[0] * Jp[0][0] + grad[1] * Jp[1][0]:.2f}")
e = 1e-6                                               # felt gradient on the map, by nudges
fx = (F(*G(x + e, y)) - F(*G(x - e, y))) / (2 * e); fy = (F(*G(x, y + e)) - F(*G(x, y - e))) / (2 * e)
print(f"felt gradient by nudging x and y: {fmt([fx, fy], 4)} C/km")
errs = []
for h in (0.1, 0.01, 0.001):                           # road 2: secants of the composed walk
    qq = (felt(t + h) - felt(t)) / h; errs.append(qq - chain)
    print(f"road 2, secant over h = {h:g} h: {qq:.5f} C/h, misses by {qq - chain:.5f}")
lo, hi = 0.0, 0.1                                      # largest step within 0.01 C/h
for _ in range(60):
    mid = (lo + hi) / 2
    if abs((felt(t + mid) - felt(t)) / mid - chain) < 0.01: lo = mid
    else: hi = mid
print(f"tolerance: every forward step under {int(lo * 1e6) / 1e6:.6f} h ({int(lo * 360000) / 100:.2f} s) lands within 0.01 C/h")
central = (felt(t + 1e-5) - felt(t - 1e-5)) / 2e-5
print(f"road 2, central secant over h = 0.00001 h: {central:.6f} C/h")
JGbad = [[-1.0, -2 * 1.0], [1.0, 1.0 + 3]]              # J_G read at (1, 1), not (2, 1)
print(f"mistake 1, J_G read at (1, 1): {matmul(JF, matmul(JGbad, Jp))[0][0]:.2f} C/h")
JGT = [[JG[0][0], JG[1][0]], [JG[0][1], JG[1][1]]]      # rows and columns swapped
print(f"mistake 2, J_G transposed: {matmul(JF, matmul(JGT, Jp))[0][0]:.2f} C/h")
print(f"mistake 3, wind ignored, felt = air: {inner[0][0]:.2f} C/h")
def q(a, b): return 0.0 if a == b == 0 else a * a * b / (a * a + b * b)   # a crease at 0
qx, qy = (q(1e-6, 0) - q(0, 0)) / 1e-6, (q(0, 1e-6) - q(0, 0)) / 1e-6
walk = (q(1e-6, 1e-6) - q(0, 0)) / 1e-6
print(f"crease: partials at 0 are {qx:.2f}, {qy:.2f}, so chain gives {qx + qy:.2f}; walking the diagonal gives {walk:.2f}")
pts = [i / 4 for i in range(9)]
print("chart, felt C at t = 0, 0.25, ..., 2:", fmt([felt(s) for s in pts]))
print("chart, tangent at t = 1:", fmt([felt(t) + chain * (s - t) for s in pts]))
assert abs(chain - central) < 1e-6                     # matrices = the composed walk
assert 9 < errs[0] / errs[1] < 11 and abs(errs[2]) < 0.05   # secants close in, tenfold
assert abs(grad[0] - fx) < 1e-6 and abs(grad[1] - fy) < 1e-6   # J_F J_G = nudged gradient
assert abs(walk - 0.5) < 1e-9 and qx + qy == 0         # the crease breaks the rule
print("ALL CHECKS PASS")
