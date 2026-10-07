# Open-top box holding 4 cubic metres: base x by y metres, height 4/(xy).
V = 4.0
S = lambda x, y: x * y + 2 * V / x + 2 * V / y          # sheet area, square metres
grad = lambda x, y: (y - 2 * V / x**2, x - 2 * V / y**2)
hess = lambda x, y: (4 * V / x**3, 1.0, 4 * V / y**3)     # A, B, C from the formula
x, y = 1.0, 3.0                                           # road 1: Newton on gradient = 0
for step in range(8):
    (gx, gy), (a, b, c) = grad(x, y), hess(x, y)
    d = a * c - b * b
    x, y = x - (c * gx - b * gy) / d, y - (a * gy - b * gx) / d
gx, gy = grad(x, y)
print(f"newton from (1,3), 8 steps: x={x:.6f} y={y:.6f} gradient size={(gx*gx+gy*gy)**0.5:.9f}")
print(f"stationary box: base {x:.6f} by {y:.6f}, height {V/(x*y):.6f}, area {S(x,y):.6f}")
def dq(f, x, y, h=1e-3):                                    # second difference quotients
    return ((f(x+h, y) - 2*f(x, y) + f(x-h, y)) / h**2,
            (f(x+h, y+h) - f(x+h, y-h) - f(x-h, y+h) + f(x-h, y-h)) / (4*h*h),
            (f(x, y+h) - 2*f(x, y) + f(x, y-h)) / h**2)
cls = lambda a, d: "saddle" if d < 0 else "no verdict" if d == 0 else "strict local minimum" if a > 0 else "strict local maximum"
A, B, C = hess(x, y); fxx, fxy, fyy = dq(S, x, y)
assert max(abs(fxx-A), abs(fxy-B), abs(fyy-C)) < 1e-4
print(f"hessian formula A={A:.6f} B={B:.6f} C={C:.6f}; difference quotients {fxx:.6f} {fxy:.6f} {fyy:.6f}")
D, T = A*C - B*B, A + C
lam = ((T + (T*T - 4*D)**0.5) / 2, (T - (T*T - 4*D)**0.5) / 2)
print(f"D={D:.6f} trace={T:.6f} eigenvalues {lam[0]:.6f} and {lam[1]:.6f}: {cls(A, D)}")
print(f"sign flip, minus the area: A={-A:.6f} D={D:.6f}: {cls(-A, D)}")
for hx, hy in ((0.1, 0.1), (0.1, -0.1)):
    rise, quad = S(x+hx, y+hy) - S(x, y), 0.5 * (A*hx*hx + 2*B*hx*hy + C*hy*hy)
    assert abs(rise - quad) < 0.1 * quad
    print(f"step ({hx},{hy}): actual rise {rise:.6f}, half h'Hh {quad:.6f}")
M = 13.0                                                     # any area above the best
lo, hi = 2*V / M, M * M / (2*V)                              # fence: area > M outside
edge = [S(e, t) for e in (lo, hi) for t in (lo + (hi-lo)*k/400 for k in range(401))]
print(f"fence: x or y = {lo:.6f} or {hi:.6f} gives area >= {M:.0f}; lowest edge value {min(edge):.6f}")
best = min((S(0.05*i, 0.05*j), 0.05*i, 0.05*j) for i in range(int(lo*20)+1, int(hi*20)+1) for j in range(int(lo*20)+1, int(hi*20)+1))
best = min((S(best[1] + 0.001*i, best[2] + 0.001*j), best[1] + 0.001*i, best[2] + 0.001*j) for i in range(-60, 61) for j in range(-60, 61))
assert abs(best[1] - x) < 2e-3 and abs(best[2] - y) < 2e-3 and best[0] >= S(x, y) - 1e-12
print(f"road 2, grid search over the fence: best ({best[1]:.3f}, {best[2]:.3f}) area {best[0]:.6f}")
print("chart square base y=x:", ", ".join(f"{S(s, s):.2f}" for s in (1, 1.5, 2, 2.5, 3, 3.5, 4)))
print("chart y fixed at 2:", ", ".join(f"{S(s, 2):.2f}" for s in (1, 1.5, 2, 2.5, 3, 3.5, 4)))
f3 = lambda x, y: x*x + 3*x*y + y*y                           # A = C = 2, cross term 3
a3, b3, c3 = dq(f3, 0.0, 0.0); d3 = a3*c3 - b3*b3
assert cls(a3, d3) == "saddle" and f3(0.1, 0.1) > 0 > f3(0.1, -0.1)
print(f"breaks, x^2+3xy+y^2: D={d3:.0f}, rise along (0.1,0.1) {f3(0.1,0.1):.6f}, along (0.1,-0.1) {f3(0.1,-0.1):.6f}: {cls(a3, d3)}")
print(f"breaks, flat Hessian: x^4+y^4 at (0.1,0) {0.1**4:.6f}; x^4-y^4 at (0,0.1) {-0.1**4:.6f}")
g = lambda x, y: x*x + y*y - x**4
print(f"breaks, x^2+y^2-x^4: value 0 at the local minimum (0,0), g(2,0) = {g(2, 0):.6f}")
