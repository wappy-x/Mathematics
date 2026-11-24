# Time-independent perturbation theory -- the check behind the card.
# Standard library only.  An electron in a 1 nm box with a 0.1 eV step over its
# right half.  Three roads to the shifted levels: the perturbation series, an
# exact 50-state diagonalisation (Jacobi rotations), and shooting the equation
# itself (RK4 plus bisection).  Then a degenerate pair in a square 1 nm box.
import math

H = 6.62607015e-34          # Planck constant, J s (exact in SI)
HBAR = H / (2 * math.pi)    # reduced Planck constant, J s
ME = 9.1093837139e-31       # electron mass, kg (CODATA 2022)
EV = 1.602176634e-19        # one electronvolt, J (exact in SI)
HC = H * 299792458.0 / EV * 1e9   # h c in eV nm
E1 = H * H / (8 * ME * 1e-18) / EV              # ground level of the 1 nm box, eV
K = 2 * ME * EV * 1e-18 / HBAR ** 2             # phi'' = -K (E - V) phi, x in nm, E in eV
V0, N = 0.1, 50                                 # step height, eV; basis size

def I(m, n):                # integral over the right half of phi_m phi_n (1 nm box)
    if m == n: return 0.5
    if (m - n) % 2 == 0: return 0.0
    return (math.sin((m + n) * math.pi / 2) / (m + n) - math.sin((m - n) * math.pi / 2) / (m - n)) / math.pi

def simpson(f, a, b, n=2000):
    h = (b - a) / n
    return (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))) * h / 3

def phi(n): return lambda x: math.sqrt(2.0) * math.sin(n * math.pi * x)

def jacobi(A):              # eigenvalues and eigenvectors of a symmetric matrix by rotations
    n = len(A); A = [r[:] for r in A]; Q = [[float(i == j) for j in range(n)] for i in range(n)]
    for _ in range(30):
        if sum(A[i][j] ** 2 for i in range(n) for j in range(n) if i != j) < 1e-26: break
        for p in range(n - 1):
            for q in range(p + 1, n):
                if A[p][q] == 0.0: continue
                th = (A[q][q] - A[p][p]) / (2 * A[p][q])
                t = (1.0 if th >= 0 else -1.0) / (abs(th) + math.sqrt(th * th + 1))
                c = 1 / math.sqrt(t * t + 1); s = t * c
                for M in (A, Q):
                    for k in range(n):
                        a, b = M[k][p], M[k][q]; M[k][p], M[k][q] = c * a - s * b, s * a + c * b
                for k in range(n):
                    a, b = A[p][k], A[q][k]; A[p][k], A[q][k] = c * a - s * b, s * a + c * b
    order = sorted(range(n), key=lambda i: A[i][i])
    return [A[i][i] for i in order], [[Q[k][i] for k in range(n)] for i in order]

def shoot(E, V, steps=2000):  # phi(0)=0, phi'(0)=1, RK4 across 1 nm with the step; returns phi(1 nm)
    dx, y, v = 1.0 / steps, 0.0, 1.0
    for i in range(steps):
        k = -K * (E - (V if (i + 0.5) * dx > 0.5 else 0.0))
        k1y, k1v = v, k * y
        k2y, k2v = v + dx / 2 * k1v, k * (y + dx / 2 * k1y)
        k3y, k3v = v + dx / 2 * k2v, k * (y + dx / 2 * k2y)
        k4y, k4v = v + dx * k3v, k * (y + dx * k3y)
        y += dx / 6 * (k1y + 2 * k2y + 2 * k3y + k4y); v += dx / 6 * (k1v + 2 * k2v + 2 * k3v + k4v)
    return y

def root_from(V, E):        # first sign change of shoot above E, scanned in 0.02 eV, then bisected
    f = lambda e: shoot(e, V)
    while (f(E) < 0) == (f(E + 0.02) < 0): E += 0.02
    a, b, fa = E, E + 0.02, f(E)
    for _ in range(60):
        m = (a + b) / 2; fm = f(m)
        if (fm < 0) == (fa < 0): a, fa = m, fm
        else: b = m
    return (a + b) / 2

def series(n, V, size=N):   # unperturbed, first order, second order for level n
    e0 = E1 * n * n
    e2 = sum((V * I(n, m)) ** 2 / (e0 - E1 * m * m) for m in range(1, size + 1) if m != n)
    return e0, e0 + V * I(n, n), e0 + V * I(n, n) + e2

def exact(V, size=N):
    return jacobi([[(E1 * (i + 1) ** 2 if i == j else 0.0) + V * I(i + 1, j + 1) for j in range(size)] for i in range(size)])

print("box 1 nm: E_1 = h^2/(8 m_e L^2) = %.5f eV; K = %.4f per eV per nm^2; step V0 = %.3f eV on 0.5-1 nm" % (E1, K, V0))
half = [simpson(lambda x: phi(n)(x) ** 2, 0.5, 1.0) for n in range(1, 6)]
print("chance in right half, levels 1-5 (Simpson): " + " ".join("%.6f" % h for h in half))
pairs = [(1, 1), (1, 2), (1, 4), (2, 3), (3, 4), (1, 6)]
num = [V0 * simpson(lambda x: phi(a)(x) * phi(b)(x), 0.5, 1.0) for a, b in pairs]
print("V_mn closed form / Simpson, eV: " + ", ".join("V_%d%d %.6f/%.6f" % (a, b, V0 * I(a, b), u) for (a, b), u in zip(pairs, num)))
terms = [(V0 * I(1, m)) ** 2 / (E1 - E1 * m * m) for m in (2, 4, 6)]
print("ground, second order: V_12^2 %.7f eV^2 / (E_1 - E_2) %.5f eV; V_14^2 %.7f eV^2 / (E_1 - E_4) %.5f eV"
      % ((V0 * I(1, 2)) ** 2, E1 - 4 * E1, (V0 * I(1, 4)) ** 2, E1 - 16 * E1))
print("ground, second order: m=2 %.7f, m=4 %.7f, m=6 %.7f, all m to 50 %.7f eV" % (*terms, series(1, V0)[2] - series(1, V0)[1]))
ev, vec = exact(V0)
shot = [root_from(V0, E1 * n * n) for n in range(1, 6)]
print("n  unperturbed  first order  second order  50-state exact  shooting  (eV)")
for n in range(1, 6):
    print("%d  %10.5f  %11.5f  %12.5f  %14.5f  %8.5f" % (n, *series(n, V0), ev[n - 1], shot[n - 1]))
for lab, col in (("first order", 1), ("second order", 2)):
    print("chart, shift %s, levels 1-8, meV: %s" % (lab, " ".join("%.2f" % (1000 * (series(n, V0)[col] - E1 * n * n)) for n in range(1, 9))))
print("chart, shift exact, levels 1-8, meV: %s" % " ".join("%.2f" % (1000 * (ev[n - 1] - E1 * n * n)) for n in range(1, 9)))
c = {m: V0 * I(1, m) / (E1 - E1 * m * m) for m in range(2, N + 1)}
print("ground state mix, amount per unit of phi_1: c_2 first order %.5f, exact %.5f; c_4 first order %.5f, exact %.5f"
      % (c[2], vec[0][1] / vec[0][0], c[4], vec[0][3] / vec[0][0]))
p1 = 0.5 + 2 * sum(c[m] * I(1, m) for m in c)
pex = sum(vec[0][i] * vec[0][j] * I(i + 1, j + 1) for i in range(N) for j in range(N))
print("ground, chance in right half: unperturbed 0.5000, first order %.4f, exact %.4f" % (p1, pex))
gaps = [E1 * 3, series(2, V0)[1] - series(1, V0)[1], series(2, V0)[2] - series(1, V0)[2], ev[1] - ev[0], shot[1] - shot[0]]
print("light 2->1, eV / nm: unperturbed, first, second, exact, shooting: " + ", ".join("%.5f/%.2f" % (g, HC / g) for g in gaps))
eps = abs(V0 * I(1, 2)) / (3 * E1)
print("small number eps = |V_12|/(E_2 - E_1) = %.4f" % eps)
st = [(a, b) for a in range(1, 9) for b in range(1, 9)]
H2 = [[(E1 * (a * a + b * b) if (a, b) == (p, q) else 0.0) + V0 * I(a, p) * I(b, q) for (p, q) in st] for (a, b) in st]
ev2, vec2 = jacobi(H2)
Vaa, Vab = V0 * I(1, 1) * I(2, 2), V0 * I(1, 2) * I(2, 1)
deg = [5 * E1 + Vaa + Vab, 5 * E1 + Vaa - Vab]
i12, i21 = st.index((1, 2)), st.index((2, 1))
print("square 1 nm x 1 nm, bump %.1f eV on corner x,y > 0.5 nm: pair (1,2),(2,1) at %.5f eV" % (V0, 5 * E1))
print("pair block [[%.6f, %.6f], [%.6f, %.6f]] eV; eigenvalues %.6f, %.6f eV" % (Vaa, Vab, Vab, Vaa, Vaa + Vab, Vaa - Vab))
su, sl = (1 if vec2[2][i12] > 0 else -1), (1 if vec2[1][i12] > 0 else -1)
print("exact good states on (1,2),(2,1): upper %.4f %.4f, lower %.4f %.4f"
      % (su * vec2[2][i12], su * vec2[2][i21], sl * vec2[1][i12], sl * vec2[1][i21]))
print("pair levels: degenerate theory %.5f, %.5f eV; 64-state exact %.5f, %.5f eV; split %.5f vs %.5f eV"
      % (deg[0], deg[1], ev2[2], ev2[1], 2 * Vab, ev2[2] - ev2[1]))
print("mistake, nondegenerate formula on the pair: c = %.6f / %.6f, division by zero" % (Vab, 5 * E1 - 5 * E1))
print("mistake, first order only: light 2->1 at %.2f nm, exact %.2f nm, %.2f nm shorter" % (HC / gaps[1], HC / gaps[3], HC / gaps[1] - HC / gaps[3]))
flip = series(1, V0)[1] - (series(1, V0)[2] - series(1, V0)[1])
print("mistake, denominator flipped: ground %.5f eV, exact %.5f eV" % (flip, ev[0]))
big = [(V, series(1, V)[2], root_from(V, 0.01)) for V in (0.5, 1.0, 2.0, 4.0)]
print("step not small, ground second order / exact, eV: " + ", ".join("V0 %.1f eps %.2f: %.4f/%.4f" % (V, V * eps / V0, s, x) for V, s, x in big))
print("try: V0 0.2 eV ground first order %.5f, second-order term %.7f eV; 10-state ground %.5f eV"
      % (series(1, 0.2)[1], series(1, 0.2)[2] - series(1, 0.2)[1], exact(V0, 10)[0][0]))

assert all(abs(h - 0.5) < 1e-9 for h in half)                                  # half the chance under the step
assert all(abs(V0 * I(a, b) - u) < 1e-9 for (a, b), u in zip(pairs, num))      # matrix elements by Simpson
assert all(abs(series(n, V0)[2] - ev[n - 1]) < 1e-5 for n in range(1, 6))       # second order meets 50 states
assert all(abs(shot[n] - ev[n]) / ev[n] < 1e-6 for n in range(5))              # shooting meets 50 states
assert abs(c[2] / (vec[0][1] / vec[0][0]) - 1) < 0.01 and abs(p1 - pex) < 1e-3         # state correction
assert all(abs(d - e) < 5e-4 for d, e in zip(deg, (ev2[2], ev2[1])))            # degenerate pair
assert abs(2 * Vab / (ev2[2] - ev2[1]) - 1) < 0.01
assert big[-1][2] - big[-1][1] > 1.0 and abs(big[0][1] - big[0][2]) < 0.002    # series fails when eps ~ 1
print("ALL CHECKS PASS")
