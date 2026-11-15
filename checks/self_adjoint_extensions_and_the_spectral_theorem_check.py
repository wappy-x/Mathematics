# Self-adjoint extensions -- the check behind the card.  Standard library only.
# A 1 m bar; the operator is A = -d^2/dx^2 (minus the bending).  Two choices of
# boundary condition: ends held at 0 C (Dirichlet) or ends insulated (Neumann).
import math
PI = math.pi

def z(x):                                  # print a tiny rounding residue as 0
    return 0.0 if abs(x) < 5e-7 else x

def count_below(d, e, x):                  # Sturm count: eigenvalues of the tridiagonal matrix below x
    q, k = 1.0, 0
    for i in range(len(d)):
        q = d[i] - x - (e * e / q if i else 0.0)
        if q == 0.0:
            q = 1e-300
        k += q < 0
    return k

def kth_eig(d, e, k):                      # k-th smallest eigenvalue (k = 0, 1, ...) by bisection
    lo, hi = -1.0, 4.0 * max(d) + 1.0
    for _ in range(100):
        mid = 0.5 * (lo + hi)
        lo, hi = (lo, mid) if count_below(d, e, mid) > k else (mid, hi)
    return 0.5 * (lo + hi)

def simpson(f, a, b, m=2000):              # Simpson's rule, m even
    h = (b - a) / m
    s = f(a) + f(b) + sum((4 if j % 2 else 2) * f(a + j * h) for j in range(1, m))
    return s * h / 3

print("finite rehearsal: the bar on a grid; every grid matrix is symmetric, domain = all vectors")
print("N     held: lam1     error vs pi^2   insulated: lam0  lam1")
for N in (10, 100, 1000):
    h = 1.0 / (N + 1)                      # held ends: N inside points, end values 0
    dD, hN = [2.0 / h**2] * N, 1.0 / N     # insulated ends: N cells, mirror at each end
    dN = [1.0 / hN**2] + [2.0 / hN**2] * (N - 2) + [1.0 / hN**2]
    l1, n0, n1 = kth_eig(dD, -1.0 / h**2, 0), kth_eig(dN, -1.0 / hN**2, 0), kth_eig(dN, -1.0 / hN**2, 1)
    print(f"{N:<5} {l1:.9f}   {l1 - PI**2:.3e}      {z(n0):.9f}      {n1:.9f}")
    assert abs(l1 - 4 / h**2 * math.sin(PI * h / 2)**2) < 1e-6 * l1          # discrete closed form
    assert 0 < PI**2 - l1 < 1.1 * PI**4 * h**2 / 12 and abs(n0) < 1e-6        # error falls like h^2
print(f"limits: held n^2 pi^2 = {PI**2:.9f}, {4*PI**2:.9f}, {9*PI**2:.9f}; insulated adds 0")
print("boundary form <Au, v> - <u, Av> on (0, 1): Simpson against the end terms [-u'v + u v']")
pairs = [("held/held", lambda x: x*(1-x), lambda x: 1-2*x, lambda x: 2.0, lambda x: math.sin(PI*x),
          lambda x: PI*math.cos(PI*x), lambda x: PI**2*math.sin(PI*x)),
         ("insulated/insulated", lambda x: x*x - 2*x**3/3, lambda x: 2*x - 2*x*x, lambda x: 4*x - 2,
          lambda x: math.cos(PI*x), lambda x: -PI*math.sin(PI*x), lambda x: PI**2*math.cos(PI*x)),
         ("held/insulated", lambda x: x*(1-x), lambda x: 1-2*x, lambda x: 2.0, lambda x: 1.0,
          lambda x: 0.0, lambda x: 0.0)]                 # (u, u', Au, v, v', Av), Au = -u''
for name, u, du, Au, v, dv, Av in pairs:
    lhs = simpson(lambda x: Au(x)*v(x) - u(x)*Av(x), 0.0, 1.0)
    rhs = (-du(1)*v(1) + u(1)*dv(1)) - (-du(0)*v(0) + u(0)*dv(0))
    print(f"  {name:<20} Simpson {z(lhs):.6f}   end terms {z(rhs):.6f}")
    assert abs(lhs - rhs) < 1e-9
s2 = math.sqrt(2.0)
ar, ai = 1 / s2, -1 / s2                    # a = (1 - i)/sqrt 2, so a^2 = -i and -u'' = i u for u = e^(a x)
def ue(x, sign=1.0):                       # e^(sign a x) as (real, imaginary)
    return (math.exp(sign*ar*x)*math.cos(sign*ai*x), math.exp(sign*ar*x)*math.sin(sign*ai*x))
def rayleigh(u, hh=1e-3):                  # pointwise eigen-check: <u, Au>/<u, u>, Au by differences
    num_r = num_i = den = 0.0
    for j in range(1, 1000):
        x, w = j * hh, (2 if j % 2 == 0 else 4)
        (ur, ui), (pr, pq), (mr, mq) = u(x), u(x + hh), u(x - hh)
        Ar, Ai = -(pr - 2*ur + mr) / hh**2, -(pq - 2*ui + mq) / hh**2
        num_r, num_i = num_r + w*(ur*Ar + ui*Ai), num_i + w*(ur*Ai - ui*Ar)   # conjugate first slot
        den += w * (ur*ur + ui*ui)
    return num_r / den, num_i / den
def sh(x):                                 # e^(a x) - e^(-a x): zero at the left end only
    return (ue(x)[0] - ue(x, -1.0)[0], ue(x)[1] - ue(x, -1.0)[1])
rr, ri = rayleigh(ue)
print(f"no conditions at all: u = e^(a x), a = (1 - i)/sqrt2; <u, Au>/<u, u> = {z(rr):.6f} + {ri:.6f}i")
assert abs(rr) < 1e-5 and abs(ri - 1) < 1e-5
print("deficiency count: squared size int_0^R |u|^2 dx of the two solutions of -u'' = i u")
print("R     decaying e^(-a x)          growing e^(a x)")
size = {}
for R in (1, 5, 10, 20):
    dec = simpson(lambda x: math.exp(-s2*x), 0.0, float(R))
    gro = simpson(lambda x: math.exp(s2*x), 0.0, float(R), 20000)
    size[R] = (dec, gro)
    print(f"{R:<5} {dec:.6f} (exact {(1-math.exp(-s2*R))/s2:.6f})  {gro:.6e} (exact {(math.exp(s2*R)-1)/s2:.6e})")
    assert abs(dec - (1 - math.exp(-s2*R)) / s2) < 1e-9 and abs(gro / ((math.exp(s2*R) - 1) / s2) - 1) < 1e-8
settled = [size[20][k] - size[10][k] < 1e-3 for k in (0, 1)]   # does the size stop growing?
n_bar = sum(math.isfinite(v) for v in size[1])                # on the bar (0, 1) both squared sizes are finite
n_half, n_line = sum(settled), sum(settled[k] and settled[1 - k] for k in (0, 1))
print(f"so n+ = n- = {n_bar} on the bar (0, 1), {n_half} on the half-line, {n_line} on the whole line; "
      f"bar extensions: {n_bar} x {n_bar} = {n_bar * n_bar} real parameters")
assert (n_half, n_line) == (1, 0)
sa = [(p - m) / 2 for p, m in zip(ue(1.0), ue(1.0, -1.0))]   # sinh(a); v(0) = 0 leaves sinh(a x), v'(0) = 0 cosh(a x)
print(f"+-i test on the bar: held ends need sinh(a) = 0, insulated ends a sinh(a) = 0; "
      f"sinh(a) = {sa[0]:.6f} - {-sa[1]:.6f}i, so n+ = n- = 0 for both")
assert abs(sa[0] - math.sinh(ar)*math.cos(ai)) < 1e-12 and abs(sa[1] - math.cosh(ar)*math.sin(ai)) < 1e-12 and math.hypot(*sa) > 0.5
mom = [simpson(lambda x: math.exp(-2*x), 0.0, float(R)) for R in (5, 20)]
print(f"momentum -i d/dx on the half-line: |e^(-x)|^2 to R = 5, 20: {mom[0]:.6f}, {mom[1]:.6f}; e^x unbounded: n+ = 1, n- = 0")
assert abs(mom[1] - 0.5) < 1e-9
print("spectral domain test for f = 1 (100 C everywhere), held-ends modes sqrt2 sin(n pi x)")
print("N      sum c_n^2    sum lam_n^2 c_n^2")
for N in (10, 100, 1000):
    c = [s2 * (1 - (-1)**n) / (n*PI) for n in range(1, N + 1)]
    s, sl = sum(t*t for t in c), sum((n*PI)**4 * c[n-1]**2 for n in range(1, N + 1))
    print(f"{N:<6} {s:.6f}     {sl:.6e}")
    assert 0 < 1 - s < 4.1 / (PI**2 * N)                  # Parseval: tends to ||f||^2 = 1
cs = [simpson(lambda x: s2 * math.sin(n*PI*x), 0.0, 1.0) for n in (1, 2, 3)]
print(f"c_1, c_2, c_3 by Simpson: {cs[0]:.6f}, {z(cs[1]):.6f}, {cs[2]:.6f}; closed form 2sqrt2/(n pi) for odd n")
assert abs(cs[0] - 2*s2/PI) < 1e-9 and abs(cs[2] - 2*s2/(3*PI)) < 1e-9
kap, T0 = 1.0e-4, 100.0                    # diffusivity m^2/s (illustrative, about copper's); start 100 C
def mid_series(t):                         # midpoint temperature, held ends, by the modes
    return T0 * sum(4/(n*PI) * (-1)**((n-1)//2) * math.exp(-kap*(n*PI)**2*t) for n in range(1, 400, 2))
def mean_series(t):
    return T0 * sum(8/(n*PI)**2 * math.exp(-kap*(n*PI)**2*t) for n in range(1, 400, 2))
h, dt = 0.01, 0.25                         # grid road: 99 inside points, explicit steps of 0.25 s
uD, uN = [T0] * 99, [T0] * 100
for _ in range(2400):                      # 600 s
    uD = [uD[i] + kap*dt/h**2 * ((uD[i-1] if i else 0.0) - 2*uD[i] + (uD[i+1] if i < 98 else 0.0)) for i in range(99)]
    uN = [uN[i] + kap*dt/h**2 * (uN[max(i-1, 0)] - 2*uN[i] + uN[min(i+1, 99)]) for i in range(100)]
e1 = kap * PI**2 * 600
print(f"by hand at 600 s: kappa pi^2 t = {e1:.6f}; e^(-that) = {math.exp(-e1):.6f}; modes 1, 3, 5 give "
      f"{400/PI*math.exp(-e1):.4f}, {-400/(3*PI)*math.exp(-9*e1):.4f}, {400/(5*PI)*math.exp(-25*e1):.6f} C")
print(f"after 600 s, ends held at 0 C: midpoint {mid_series(600):.4f} C by modes, {uD[49]:.4f} C by grid; mean {mean_series(600):.4f} C")
print(f"after 600 s, ends insulated: midpoint 100.0000 C by modes (only lam0 = 0 survives), {uN[50]:.4f} C by grid; mean {sum(uN)/100:.4f} C")
assert abs(mid_series(600) - uD[49]) < 0.02 and abs(sum(uN)/100 - T0) < 1e-9
print(f"mistake: held-ends modes used for the insulated bar give {mid_series(600):.4f} C, not 100.0000 C")
sr, si = rayleigh(sh)
print(f"mistake: only the left end held, u = e^(a x) - e^(-a x): <u, Au>/<u, u> = {z(sr):.6f} + {si:.6f}i, not real")
assert abs(sr) < 1e-5 and abs(si - 1) < 1e-5
print("chart, ends held: minutes 0,5,...,60 ->", ", ".join(["100.00"] + [f"{mid_series(60*m):.2f}" for m in range(5, 61, 5)]))
print("ALL CHECKS PASS")
