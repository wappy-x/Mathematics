# From one equation to a system -- the check behind the card.  Standard library
# only.  A 400 kg car corner on a test rig: spring 2000 N/m, damper 800 N s/m,
# so y'' + 2y' + 5y = 0 with y in cm, pushed down 10 cm and let go at rest.
# Road one: the characteristic-equation answer.  Road two: Euler steps on the
# state (y, v), x' = A x.  Second case: a third-order equation, same stepper.
import math

A = [[0.0, 1.0], [-5.0, -2.0]]                      # rows: y' = v, v' = -5y - 2v
def exact(t):                                       # y = e^-t (10 cos 2t + 5 sin 2t)
    return (math.exp(-t) * (10 * math.cos(2 * t) + 5 * math.sin(2 * t)),
            -25 * math.exp(-t) * math.sin(2 * t))   # v = y' = -25 e^-t sin 2t
def times(M, x):                                    # matrix times vector
    return [sum(M[i][j] * x[j] for j in range(len(x))) for i in range(len(M))]
def euler(M, x, t_end, h):                          # new state = state + h A state
    for _ in range(round(t_end / h)):
        x = [a + h * b for a, b in zip(x, times(M, x))]
    return x

def c(z):                                           # a complex number as a + bi
    return f"{z.real:g} {'-' if z.imag < 0 else '+'} {abs(z.imag):g}i"

x0 = [10.0, 0.0]
lam = complex(-1, 2)                                # root of r^2 + 2r + 5 = 0
Av = [A[0][0] + A[0][1] * lam, A[1][0] + A[1][1] * lam]   # A times (1, lam)
e1, e2 = euler(A, x0, 1, 1e-4), euler(A, x0, 2, 1e-4)
errs = [abs(euler(A, x0, 1, h)[0] - exact(1)[0]) for h in (0.01, 0.005, 0.0025)]
t1 = (math.pi - math.atan(2)) / 2                   # y = 0 when tan 2t = -2
C3 = [[0.0, 1.0, 0.0], [0.0, 0.0, 1.0], [-1.0, -3.0, -3.0]]  # y''' + 3y'' + 3y' + y = 0
y3 = math.exp(-1) * (1 + 1 + 0.5)                   # y = e^-t (1 + t + t^2/2) at t = 1
bad = euler([[0.0, 1.0], [5.0, 2.0]], x0, 1, 1e-4)[0]      # signs not flipped
swap = euler([[0.0, 1.0], [-2.0, -5.0]], x0, 1, 1e-4)[0]   # 2 and 5 swapped
pts = [(80 + 24 * exact(k / 10)[0], 60 - 12 * exact(k / 10)[1]) for k in range(31)]
print("rig: m 400 kg, c 800 N s/m, k 2000 N/m -> y'' + 2y' + 5y = 0 (c/m = 2, k/m = 5)")
print(f"A = {A}; state x = (y, v) = {x0}; A x = {times(A, x0)}")
print(f"roots of r^2 + 2r + 5: {c(lam)}, {c(lam.conjugate())}; A (1, lam) = ({c(Av[0])}, {c(Av[1])}), "
      f"lam (1, lam) = ({c(lam)}, {c(lam * lam)})")
print("y = e^-t (10 cos 2t + 5 sin 2t) cm, v = y' = -25 e^-t sin 2t cm/s; y = 0 where tan 2t = -2")
for t, e in ((1, e1), (2, e2)):
    print(f"t = {t} s: formula y {exact(t)[0]:.4f} cm, v {exact(t)[1]:.4f} cm/s; Euler h = 0.0001 y {e[0]:.4f}, v {e[1]:.4f}")
print("Euler error in y at t = 1, h = 0.01, 0.005, 0.0025:", " ".join(f"{e:.5f}" for e in errs))
print(f"error ratios on halving h: {errs[0] / errs[1]:.3f} {errs[1] / errs[2]:.3f}")
print("t (s) ", " ".join(f"{k / 4:.2f}" for k in range(13)))
print("y (cm)", " ".join(f"{exact(k / 4)[0]:.2f}" for k in range(13)))
print(f"y = 0 at t = {t1:.4f} s with v {exact(t1)[1]:.4f}, and at t = {t1 + math.pi / 2:.4f} s with v {exact(t1 + math.pi / 2)[1]:.4f}")
print(f"third order y''' + 3y'' + 3y' + y = 0 from (1, 0, 0): y(1) = e^-1 (1 + 1 + 1/2) = {y3:.4f}; Euler {euler(C3, [1.0, 0.0, 0.0], 1, 1e-4)[0]:.4f}")
print(f"mistake, bottom row [5, 2]: y(1) = {bad:.2f} cm; mistake, bottom row [-2, -5]: y(1) = {swap:.2f} cm")
for r in range(3):
    print("figure,", " ".join(f"{X:.1f},{Y:.1f}" for X, Y in pts[11 * r:11 * r + 11]))
assert abs(Av[0] - lam) < 1e-12 and abs(Av[1] - lam * lam) < 1e-12   # roots are A's eigenvalues
assert abs(e1[0] - exact(1)[0]) < 1e-3 and abs(e2[1] - exact(2)[1]) < 5e-3  # road two meets road one
assert all(1.8 < errs[i] / errs[i + 1] < 2.2 for i in range(2))        # error halves: order one
assert abs(euler(C3, [1.0, 0.0, 0.0], 1, 1e-4)[0] - y3) < 1e-3        # third order, both roads
print("ALL CHECKS PASS")
