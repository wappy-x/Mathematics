# Friedrichs extension and energy forms -- the check behind the card.  Standard
# library only.  The bar runs from 0 to pi with both ends held at 0.  The energy
# is q(u) = integral of u'^2.  A spike of strength ALPHA sits at the middle, pi/2,
# and adds ALPHA * u(pi/2)^2 to the energy.  Every grid matrix is a truncation.
import math
PI, ALPHA = math.pi, 1.0

def count_below(d, off, x):                # Sturm count: eigenvalues of the tridiagonal matrix below x
    q, k = 1.0, 0
    for i in range(len(d)):
        q = d[i] - x - (off * off / q if i else 0.0)
        if q == 0.0:
            q = 1e-300
        k += q < 0
    return k

def kth_eig(d, off, k):                    # k-th smallest eigenvalue (k = 0, 1, ...) by bisection
    lo, hi = -1.0, 4.0 * max(d) + 1.0
    for _ in range(100):
        mid = 0.5 * (lo + hi)
        lo, hi = (lo, mid) if count_below(d, off, mid) > k else (mid, hi)
    return 0.5 * (lo + hi)

def simpson(f, a, b, m=2000):              # Simpson's rule, m even
    h = (b - a) / m
    s = f(a) + f(b) + sum((4 if j % 2 else 2) * f(a + j * h) for j in range(1, m))
    return s * h / 3

def root(g, lo, hi):                       # bisection for a sign change of g on (lo, hi)
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if g(lo) * g(mid) > 0 else (lo, mid)
    return 0.5 * (lo + hi)

def kink(k, a):                            # even mode: -u'' = k^2 u, slope jumps by a * u(pi/2)
    return 2 * k * math.cos(k * PI / 2) + a * math.sin(k * PI / 2)

k1, k3 = root(lambda k: kink(k, ALPHA), 1.0, 2.0), root(lambda k: kink(k, ALPHA), 3.0, 4.0)
exact = [k1 * k1, 4.0, k3 * k3]            # the odd mode sin 2x is 0 at pi/2, so 4 stays
print("road 1, exact: an even mode needs 2k cos(k pi/2) + alpha sin(k pi/2) = 0")
print(f"  alpha = {ALPHA:.0f}: k = {k1:.9f}, lowest = k^2 = {exact[0]:.9f}; levels {exact[0]:.6f}, "
      f"{exact[1]:.6f}, {exact[2]:.6f}")
print("road 2, grid: N inside points, h = pi/(N+1), spike adds alpha/h to the middle diagonal")
print("N     no spike: lam1    lam2        lam3        spike: lam1   lam2        lam3")
errs = []
for N in (9, 99, 999):
    h, m = PI / (N + 1), (N - 1) // 2      # point m sits at x = pi/2
    d = [2.0 / h**2] * N
    ds = d[:]
    ds[m] += ALPHA / h
    plain = [kth_eig(d, -1.0 / h**2, j) for j in range(3)]
    spike = [kth_eig(ds, -1.0 / h**2, j) for j in range(3)]
    print(f"{N:<5} {plain[0]:.6f}    {plain[1]:.6f}    {plain[2]:.6f}    {spike[0]:.6f}      "
          f"{spike[1]:.6f}    {spike[2]:.6f}")
    for j in range(3):                     # grid closed form 4/h^2 sin^2(n h/2) for the plain bar
        assert abs(plain[j] - 4 / h**2 * math.sin((j + 1) * h / 2)**2) < 1e-8 * plain[j]
    errs.append(abs(spike[0] - exact[0]))
print(f"spike lowest, grid error: N=9 {errs[0]:.3e}, N=99 {errs[1]:.3e}, N=999 {errs[2]:.3e}")
assert errs[2] < 1e-5 and errs[2] < errs[1] < errs[0]          # grid closes on the exact root
sq = simpson(lambda x: math.cos(x)**2, 0, PI)                  # q(sin) = integral of cos^2
nn = simpson(lambda x: math.sin(x)**2, 0, PI)                  # ||sin||^2
ray = (sq + ALPHA * math.sin(PI / 2)**2) / nn
print("road 3, Rayleigh bracket with the trial function sin x (in the form domain H^1_0):")
print(f"  q(sin) = {sq:.6f}, ||sin||^2 = {nn:.6f}, spike energy = {math.sin(PI / 2)**2:.6f}")
print(f"  1 <= lowest = {exact[0]:.6f} <= (q + spike)/||sin||^2 = {ray:.6f} = 1 + 2/pi = {1 + 2 / PI:.6f}")
assert 1.0 <= exact[0] <= ray and abs(ray - (1 + 2 / PI)) < 1e-9
print("why the energy route picks held ends: ramps from 0 up to the constant 1 within eps of each end")
print("eps      L2 distance to 1   energy q    (closed forms sqrt(2 eps/3), 2/eps)")
for eps in (0.1, 0.01, 0.001):
    M = 200000                             # midpoint sums over (0, pi)
    ramp = lambda x: min(1.0, x / eps, (PI - x) / eps)
    dist = math.sqrt(sum((1 - ramp((i + 0.5) * PI / M))**2 for i in range(M)) * PI / M)
    en = 0.0                               # energy: (rise over run)^2 times run, each straight piece cut in 1000
    for a, b in ((0.0, eps), (eps, PI - eps), (PI - eps, PI)):
        xs = [a + (b - a) * j / 1000 for j in range(1001)]
        en += sum((ramp(xs[j + 1]) - ramp(xs[j]))**2 / (xs[j + 1] - xs[j]) for j in range(1000))
    print(f"{eps:<8} {dist:.6f}           {en:.1f}")
    assert abs(dist - math.sqrt(2 * eps / 3)) < 1e-4
    assert abs(en - 2 / eps) < 1e-6 * en
NN = 100                                   # insulated ends: N cells, mirror at each end
hn = PI / NN
dn = [1.0 / hn**2] + [2.0 / hn**2] * (NN - 2) + [1.0 / hn**2]
n0, n1 = kth_eig(dn, -1.0 / hn**2, 0), kth_eig(dn, -1.0 / hn**2, 1)
print(f"insulated ends (form on all of H^1), N=100: lowest {abs(n0):.6f}, next {n1:.6f}")
assert abs(n0) < 1e-6 and abs(n1 - 1.0) < 1e-3
print("form bound: u(pi/2)^2 <= ||u|| ||u'|| <= a ||u'||^2 + ||u||^2/(4a) for every a > 0")
for name, w in (("sin x", PI / 2), ("tent, half-width 0.1", 0.1), ("tent, half-width 0.001", 0.001)):
    u = (lambda t: math.cos(t)) if name == "sin x" else (lambda t: 1 - t / w)   # t = distance from pi/2
    du = (lambda t: math.sin(t)) if name == "sin x" else (lambda t: 1 / w)
    nrm, slope = math.sqrt(2 * simpson(lambda t: u(t)**2, 0, w)), math.sqrt(2 * simpson(lambda t: du(t)**2, 0, w))
    print(f"  {name:<24} u(pi/2)^2 = {u(0)**2:.6f} <= ||u|| ||u'|| = {nrm * slope:.6f}")
    assert u(0)**2 <= nrm * slope
print("the spike is not an operator on L2: its output on sin x has grid size alpha/sqrt(h)")
for N in (9, 99, 999):
    h, m = PI / (N + 1), (N - 1) // 2
    u = [math.sin((i + 1) * h) for i in range(N)]
    vu = math.sqrt(h * (ALPHA / h * u[m])**2)
    print(f"  N={N:<4} size {vu:.6f}, closed form sqrt((N+1)/pi) = {math.sqrt((N + 1) / PI):.6f}; "
          f"its energy alpha u(pi/2)^2 = {ALPHA * u[m]**2:.6f}")
    assert abs(vu - math.sqrt((N + 1) / PI)) < 1e-9 * vu
print("a point couple u'(pi/2)^2 is not form-bounded: bump of half-width w, ratio pi^2/(pi^2 w + w^3)")
for w in (0.1, 0.01, 0.001):
    qb = simpson(lambda x: (PI * math.cos(PI * x / w))**2, -w, w)
    nb = simpson(lambda x: (w * math.sin(PI * x / w))**2, -w, w)
    print(f"  w={w:<6} q = {qb:.6f}, ||u||^2 = {nb:.3e}, u'(pi/2)^2/(q + ||u||^2) = {PI**2 / (qb + nb):.4f}")
    assert abs(PI**2 / (qb + nb) - PI**2 / (PI**2 * w + w**3)) < 1e-6 / w
nrm2 = simpson(lambda x: math.sin(k1 * x)**2, 0, PI / 2) * 2   # ground state is even about pi/2
assert abs(nrm2 - (PI / 2 - math.sin(k1 * PI) / (2 * k1))) < 1e-9
chart = lambda x: math.sin(k1 * min(x, PI - x)) / math.sqrt(nrm2)
print("chart, x = j pi/8, j = 0..8, both of unit L2 size")
print("  with spike: " + ", ".join(f"{chart(j * PI / 8):.3f}" for j in range(9)))
print("  sin x:      " + ", ".join(f"{math.sin(j * PI / 8) / math.sqrt(PI / 2):.3f}" for j in range(9)))
print(f"slowest heat pattern, half-life ln 2/lowest: no spike {math.log(2):.6f}, spike {math.log(2) / exact[0]:.6f}")
print(f"mistake, energy not divided by ||sin||^2: {sq + ALPHA:.6f}, which is no level of the bar")
print("ALL CHECKS PASS")
