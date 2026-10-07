# Boundary layers and singular perturbation -- the check behind the card.
# Standard library only (math gives exp, sqrt and e).  Part 1 solves the model
# layer  eps*y'' + y' + y = 0,  y(0) = 0,  y(1) = 1  three ways: exact roots,
# finite differences, and the matched inner-outer composite.  Part 2 takes the
# same steps on a drone wing: Blasius's inner equation solved by shooting two
# ways, then the skin-friction drag by two independent roads.
from math import exp, sqrt, e

def exact(x, eps):                       # road 1: roots of eps r^2 + r + 1 = 0
    d = sqrt(1.0 - 4.0 * eps)
    r1, r2 = (-1.0 + d) / (2.0 * eps), (-1.0 - d) / (2.0 * eps)
    return (exp(r1 * x) - exp(r2 * x)) / (exp(r1) - exp(r2))

def finite_diff(eps, n):                 # road 2: central differences, Thomas sweep
    h = 1.0 / n
    a, b, c = eps / h**2 - 0.5 / h, 1.0 - 2.0 * eps / h**2, eps / h**2 + 0.5 / h
    cp = [0.0] * n                       # y(0) = 0 and zero right side: y_i = -cp_i y_(i+1)
    for i in range(1, n):
        cp[i] = c / (b - a * cp[i - 1])
    y = [0.0] * (n + 1)
    y[n] = 1.0
    for i in range(n - 1, 0, -1):
        y[i] = -cp[i] * y[i + 1]
    return y

def outer(x):        return exp(1.0 - x)                   # eps dropped, keeps y(1) = 1
def inner(x, eps):   return e * (1.0 - exp(-x / eps))      # X = x/eps, keeps y(0) = 0
def composite(x, eps): return outer(x) + inner(x, eps) - e  # minus the shared value e

N = 4000
def worst(eps, f):                       # largest gap from the exact answer on the grid
    return max(abs(f(i / N, i) - exact(i / N, eps)) for i in range(N + 1))

eps = 0.05
y_fd = finite_diff(eps, N)
print("part 1: model layer, eps = 0.05")
print(f"{'x':>6} {'exact':>9} {'fin-diff':>9} {'outer':>9} {'inner':>9} {'composite':>9}")
for x in (0.0, 0.01, 0.02, 0.05, 0.1, 0.2, 0.5, 1.0):
    print(f"{x:6.2f} {exact(x, eps):9.4f} {y_fd[round(x * N)]:9.4f} {outer(x):9.4f} "
          f"{inner(x, eps):9.4f} {composite(x, eps):9.4f}")
fd_gap = worst(eps, lambda x, i: y_fd[i])
print(f"worst gap, finite differences vs exact   {fd_gap:.8f}")
print("eps     worst gap, composite vs exact   gap / eps   overlap gap at x = sqrt(eps)")
gaps = {}
for ep in (0.2, 0.1, 0.05, 0.02, 0.01, 0.001):
    gaps[ep] = worst(ep, lambda x, i: composite(x, ep))
    s = sqrt(ep)
    print(f"{ep:<7.3f} {gaps[ep]:28.4f} {gaps[ep] / ep:11.3f} {abs(outer(s) - inner(s, ep)):16.4f}")
print(f"e x eps at eps = 0.01: {e * 0.01:.4f}")
print(f"mistake, outer only, value at the wall x = 0:   {outer(0.0):.4f}  (truth 0)")
print(f"mistake, inner + outer, no subtraction, x = 1:  {outer(1.0) + inner(1.0, eps):.4f}  (truth 1)")
print("chart, x      " + " ".join(f"{0.05 * k:5.2f}" for k in range(11)))
for lab, f in (("chart, outer  ", outer), ("chart, inner  ", lambda x: inner(x, eps)),
               ("chart, compos.", lambda x: composite(x, eps))):
    print(lab + " " + " ".join(f"{f(0.05 * k):5.2f}" for k in range(11)))

# ---- part 2: the drone wing, chord 0.20 m at 15 m/s in air at 20 C ----
R, M, T, p, mu = 8.314462618, 0.0289644, 293.15, 101325.0, 1.82e-5
rho = p * M / (R * T)                    # ideal gas
nu, U, c = mu / rho, 15.0, 0.20
Re = U * c / nu

def blasius(s, eta_max, h):              # f''' = -f f''/2, f(0) = f'(0) = 0, f''(0) = s; RK4
    def rhs(v): return (v[1], v[2], -0.5 * v[0] * v[2])
    v, path = (0.0, 0.0, s), [(0.0, 0.0, 0.0, 0.0)]  # (eta, f, f', integral of f'(1 - f'))
    for k in range(round(eta_max / h)):
        k1 = rhs(v)
        k2 = rhs(tuple(v[j] + 0.5 * h * k1[j] for j in range(3)))
        k3 = rhs(tuple(v[j] + 0.5 * h * k2[j] for j in range(3)))
        k4 = rhs(tuple(v[j] + h * k3[j] for j in range(3)))
        w = tuple(v[j] + h / 6 * (k1[j] + 2 * k2[j] + 2 * k3[j] + k4[j]) for j in range(3))
        mom = path[-1][3] + 0.5 * h * (v[1] * (1 - v[1]) + w[1] * (1 - w[1]))
        v = w
        path.append(((k + 1) * h, v[0], v[1], mom))
    return v, path

lo, hi = 0.1, 1.0                        # road A: bisect on f''(0) until f'(10) = 1
for _ in range(60):
    mid = 0.5 * (lo + hi)
    lo, hi = (mid, hi) if blasius(mid, 10.0, 0.01)[0][1] < 1.0 else (lo, mid)
s_shoot = 0.5 * (lo + hi)
lam = blasius(1.0, 8.0, 0.005)[0][1]     # road B: one run with f''(0) = 1, then rescale
s_scale = lam ** -1.5
_, path = blasius(s_shoot, 10.0, 0.01)
i99 = next(i for i, q in enumerate(path) if q[2] >= 0.99)
(e0, _, u0, _), (e1, _, u1, _) = path[i99 - 1], path[i99]
eta99 = e0 + (0.99 - u0) * (e1 - e0) / (u1 - u0)
disp, theta = path[-1][0] - path[-1][1], path[-1][3]

def u_over_U(eta):                       # f'(eta) read off the stored run
    i = min(int(eta / 0.01), len(path) - 2)
    t = (eta - path[i][0]) / 0.01
    return path[i][2] + t * (path[i + 1][2] - path[i][2])

delta = c / sqrt(Re)                     # the layer's thickness scale at the trailing edge
D_wall = 2.0 * mu * U * s_shoot * sqrt(U * c / nu)   # road 1: wall shear integrated along the chord
D_mom = rho * U * U * theta * delta                  # road 2: momentum the layer has lost
print("part 2: drone wing, chord 0.20 m, 15 m/s, air at 20 C")
print(f"rho {rho:.4f} kg/m^3   nu {nu * 1e6:.4f} mm^2/s   Re {Re:.0f}   1/Re {1e6 / Re:.3f} per million")
print(f"mu {mu * 1e5:.2f}e-5 Pa s; Sutherland's law, as on card 04, gives "
      f"{100 * (1.458e-6 * T ** 1.5 / (T + 110.4) - mu) / mu:+.1f} %")
print(f"laminar on a smooth plate in a quiet stream up to Re about 500000; this wing {Re:.0f}, "
      f"{'inside' if Re < 5e5 else 'OUTSIDE'}")
print(f"f''(0) by bisection shooting {s_shoot:.6f}   by rescaling one run {s_scale:.6f}")
print(f"eta at 99% of U {eta99:.4f}   eta - f far out {disp:.4f}   momentum integral {theta:.6f}")
print(f"thickness scale c/sqrt(Re) {delta * 1e3:.4f} mm   99% thickness {eta99 * delta * 1e3:.3f} mm")
print(f"displacement thickness {disp * delta * 1e3:.3f} mm   wrong scale c/Re {c / Re * 1e6:.3f} um")
print(f"average skin-friction coefficient 4 f''(0)/sqrt(Re) {4 * s_shoot / sqrt(Re):.6f}   4 f''(0) {4 * s_shoot:.3f}")
print(f"drag per metre of span, one side, by wall shear {D_wall:.5f} N/m   by momentum lost {D_mom:.5f} N/m")
print(f"drag per metre of span, both sides {2 * D_wall:.4f} N/m   inviscid outer flow alone 0.0000 N/m")
Re2 = 60.0 * 1.5 / nu                    # outside the range: light-aircraft wing, laminar formula misused
print(f"outside range: chord 1.5 m at 60 m/s, Re {Re2:.0f}; laminar 4 f''(0)/sqrt(Re) "
      f"{4 * s_shoot / sqrt(Re2):.6f} vs turbulent fit 0.074 Re^-0.2 {0.074 * Re2 ** -0.2:.6f}")
heights = [0.25 * k for k in range(13)]
print("chart, height above skin (mm)  " + " ".join(f"{y:4.2f}" for y in heights))
print("chart, u/U Blasius inner       " + " ".join(f"{u_over_U(y / (delta * 1e3)):4.2f}" for y in heights))
print("chart, u/U outer (inviscid)    " + " ".join(f"{1.0:4.2f}" for y in heights))

assert fd_gap < 1e-4, "finite differences must land on the exact roots"
assert gaps[0.01] < gaps[0.1] / 4, "composite error shrinks with eps"
assert abs(gaps[0.001] / 0.001 - e) < 0.1, "first outer correction eps (1 - x) e^(1 - x) predicts e eps"
assert abs(s_shoot - s_scale) < 1e-6 and abs(s_shoot - 0.332057) < 1e-5, "two shooting roads, and Howarth's value"
assert abs(D_wall - D_mom) < 1e-4 * D_wall, "wall shear and momentum deficit must give one drag"
assert abs(eta99 - 4.91) < 0.01, "99% thickness at eta near 4.91"
print("ALL CHECKS PASS")
