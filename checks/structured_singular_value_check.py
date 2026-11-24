# Structured singular value -- the check behind the card.  Standard library only.
# One speed controller sends 80 % of its current command to the head drive and 20 % to the tail
# drive; torque constants 0.5 and 2.0 N m/A, each up to 20 % off, independently.  Divided by that
# 20 %, the errors are delta1, delta2, each of size at most 1.  Loop gain L(s) = (1/(3 s)) 4/(s^2 + 0.4 s + 4).
# At 2 rad/s, where its phase is -180 deg, the errors see the matrix M.  The loop breaks where det(I - M Delta) = 0.
# Roads: 1. the definition, by brute force;  2. the bounds rho(M) <= mu <= sigma_max(D M D^-1), the best d
# by golden-section search;  3. the rank-one formula |m11| + |m22|.  Then M from the loop, mu over frequency, poles.
import math

TOL = 20.0                                       # each drive's gain tolerance, %
M = [[0.5, 2.0], [0.125, 0.5]]
FLIP = [[0.5, -2.0], [0.125, -0.5]]              # same sizes, second column negated
SPLIT, KT, KL, WN, ZT = (0.8, 0.2), (0.5, 2.0), 1 / 3, 2.0, 0.1   # current shares; N m/A; 1/s; rad/s; damping

def csqrt(z):                                    # principal square root of a complex number
    z = complex(z); r = abs(z)
    re = math.sqrt((r + z.real) / 2); im = math.sqrt(max(r - z.real, 0.0) / 2)
    return complex(re, im if z.imag >= 0 else -im)

def eig2(m):                                     # both eigenvalues of a 2x2, quadratic formula
    (a, b), (c, d) = m
    tr, det = a + d, a * d - b * c
    disc = csqrt(tr * tr / 4 - det)
    return tr / 2 + disc, tr / 2 - disc

def rho(m): return max(abs(z) for z in eig2(m))   # spectral radius: largest |eigenvalue|

def smax(m):                                     # largest singular value: top eigenvalue of M^H M
    (a, b), (c, d) = m
    p, q = abs(a) ** 2 + abs(c) ** 2, abs(b) ** 2 + abs(d) ** 2
    r = complex(a).conjugate() * b + complex(c).conjugate() * d
    return math.sqrt((p + q) / 2 + math.sqrt(((p - q) / 2) ** 2 + abs(r) ** 2))

def scaled(m, d): return [[m[0][0], m[0][1] * d], [m[1][0] / d, m[1][1]]]   # D M D^-1, D = diag(d, 1)
def rank1(m): return abs(m[0][0]) + abs(m[1][1])  # road 3: mu of a rank-one matrix

def golden(f, lo, hi, n=200):                    # the minimum of f on [lo, hi], golden-section search
    g = (math.sqrt(5) - 1) / 2
    for _ in range(n):
        x1, x2 = hi - g * (hi - lo), lo + g * (hi - lo)
        if f(x1) < f(x2): hi = x2
        else: lo = x1
    return (lo + hi) / 2
def best_d(m):                                   # road 2: golden-section search on log d
    d = math.exp(golden(lambda x: smax(scaled(m, math.exp(x))), math.log(1e-3), math.log(1e3)))
    return d, smax(scaled(m, d))
def loop_M(w, tol=TOL):                          # m_ik = -w a_i k_k T / b at s = j w, with T = L / (1 + L)
    s = 1j * w; L = KL / s * WN ** 2 / (s * s + 2 * ZT * WN * s + WN ** 2); b = SPLIT[0] * KT[0] + SPLIT[1] * KT[1]
    return [[-tol / 100 * SPLIT[i] * KT[k] * L / (1 + L) / b for k in range(2)] for i in range(2)], L
def max_pole(g):                                 # s^3 + 0.4 s^2 + 4 s + (4/3) g: real root by bisection, then s^2 + p s + q
    c0, c1, c2, lo, hi = 2 * ZT * WN, WN ** 2, KL * WN ** 2 * g, -10.0, 0.0
    for _ in range(200):
        m_ = (lo + hi) / 2; lo, hi = (m_, hi) if m_ * m_ * m_ + c0 * m_ * m_ + c1 * m_ + c2 < 0 else (lo, m_)
    p = c0 + lo; q = c1 + lo * p; r = csqrt(p * p / 4 - q)
    return max(lo, -p / 2 + r.real), r.imag

def mu_search(m, nr=2000, na=720, rmax=4.0):     # road 1: the definition, by brute force
    (a, b), (c, d) = m
    det = a * d - b * c
    best = (math.inf, 0j, 0j)
    for k in range(na):
        t = 2 * math.pi * k / na
        e = complex(math.cos(t), math.sin(t))
        for j in range(1, nr + 1):
            d2 = (rmax * j / nr) * e
            den = a - det * d2
            if abs(den) < 1e-12: continue
            d1 = (1 - d * d2) / den              # det(I - M Delta) = 0, solved for delta1
            size = max(abs(d1), abs(d2))
            if size < best[0]: best = (size, d1, d2)
    return 1 / best[0], best[1], best[2]

def rho_turned(m, n=3600):                       # sharper lower bound: max over phi of rho(M U)
    best = (0.0, 0.0)
    for k in range(n):
        t = 2 * math.pi * k / n
        e = complex(math.cos(t), math.sin(t))
        r = rho([[m[0][0], m[0][1] * e], [m[1][0], m[1][1] * e]])
        if r > best[0] + 1e-12: best = (r, 360 * k / n)
    return best

def row(name, value): print(f"{name:<46}{value:>10}")
def mat(m): return "[[" + ", ".join(f"{x:.4f}" for x in m[0]) + "], [" + ", ".join(f"{x:.4f}" for x in m[1]) + "]]"

print(f"M = {mat(M)}, each drive's tolerance {TOL:.0f} %")
LM, Lw = loop_M(WN)
print(f"loop at {WN:.1f} rad/s: b = {SPLIT[0] * KT[0] + SPLIT[1] * KT[1]:.2f} N m/A, L = {Lw.real:.4f}, T = {(Lw / (1 + Lw)).real:.4f}; M from the loop {mat([[x.real for x in rw] for rw in LM])}")
l1, l2 = eig2(M)
print(f"eigenvalues of M: {l1.real:.4f} and {l2.real:.4f}")
r, s = rho(M), smax(M)
row("spectral radius rho(M), lower bound", f"{r:.4f}")
row("largest singular value sigma_max(M)", f"{s:.4f}")
d, up = best_d(M)
row("best scaling d (golden-section search)", f"{d:.4f}")
print(f"D M D^-1 at that d: {mat(scaled(M, d))}")
row("sigma_max(D M D^-1), upper bound", f"{up:.4f}")
mu, d1, d2 = mu_search(M)
print(f"road 1, smallest pair that breaks the loop: delta1 = {d1.real:.3f}, delta2 = {d2.real:.3f}")
row("mu from the definition", f"{mu:.4f}")
r1 = rank1(M)
row("mu from the rank-one formula |m11| + |m22|", f"{r1:.4f}")
det_I = (1 - M[0][0]) * (1 - M[1][1]) - M[0][1] * M[1][0]
row("det(I - M) at delta1 = delta2 = 1", f"{det_I:.4f}")
row("tolerance survived, from mu (%)", f"{TOL / up:.2f}")
row("tolerance certified by sigma_max (%)", f"{TOL / s:.2f}")
ds = [2 ** (k / 2) / 16 for k in range(11)]
print("chart d:     " + " ".join(f"{x:>7.4f}" for x in ds))
print("chart sigma: " + " ".join(f"{smax(scaled(M, x)):>7.4f}" for x in ds))
ws = [1.0, 1.5, 1.8, 1.9, 2.0, 2.1, 2.2, 2.5, 3.0]
print("mu sweep w:  " + " ".join(f"{w:>7.4f}" for w in ws))
print("mu sweep mu: " + " ".join(f"{best_d(loop_M(w)[0])[1]:>7.4f}" for w in ws))
wp = golden(lambda w: -best_d(loop_M(w)[0])[1], 1.5, 2.5, 100); mp = best_d(loop_M(wp)[0])[1]; r1p = rank1(loop_M(wp)[0])
print(f"mu peak {mp:.4f} at {wp:.4f} rad/s, rank-one formula {r1p:.4f}; complex errors survived there {TOL / mp:.2f} %")
ps = [max_pole(1 + TOL / 100 * dl) for dl in (0.95, 1.0, 1.05)]
print("poles, both drives drifting together: " + "; ".join(f"delta {dl:.2f}: largest real part {p[0]:+.4f}, imag {p[1]:.4f}" for dl, p in zip((0.95, 1.0, 1.05), ps)))
print("what breaks:")
print(f"1. small gain on the full matrix: margin {1 / s:.4f}, {TOL / s:.2f} % instead of {TOL / up:.2f} %")
fr = rho(FLIP); fmu, f1, f2 = mu_search(FLIP); fd, fup = best_d(FLIP); ft, fphi = rho_turned(FLIP)
print(f"2. flipped M: rho = {fr:.4f}, but mu = {fmu:.4f} (delta1 = {f1.real:.3f}, delta2 = {f2.real:.3f}), rank-one formula {rank1(FLIP):.4f}")
print(f"   flipped M: D-scaled bound {fup:.4f}, phase-turned rho {ft:.4f} at phi = {fphi:.1f} deg")
row("3. scaling the wrong way, d = 4: sigma_max", f"{smax(scaled(M, 4.0)):.4f}")
u, v = [1.0, M[1][0] / M[0][0]], [M[0][0], M[0][1]]   # M = u v^T, a rank-one matrix
nu, nv = u[0] ** 2 + u[1] ** 2, v[0] ** 2 + v[1] ** 2
full = [[v[i] * u[j] / (nu * nv) for j in range(2)] for i in range(2)]   # Delta = v u^T / (|u|^2 |v|^2)
mf = [[sum(M[i][k] * full[k][j] for k in range(2)) for j in range(2)] for i in range(2)]
det_f = (1 - mf[0][0]) * (1 - mf[1][1]) - mf[0][1] * mf[1][0]
print(f"4. full-matrix error: size {smax(full):.4f}, det(I - M Delta) = {abs(det_f):.4f}; D-scaling would claim {1 / up:.4f}")
big = [[x * 25 / TOL for x in rw] for rw in M]
row("5. tolerance 25 %: mu (D-scaled)", f"{best_d(big)[1]:.4f}")
row("   margin 1/mu", f"{1 / best_d(big)[1]:.4f}")
assert all(abs(M[i][j] - u[i] * v[j]) < 1e-12 for i in range(2) for j in range(2))
assert abs(mu - r1) < 1e-3 and abs(mu - up) < 1e-3 and abs(d - math.sqrt(abs(M[1][0] / M[0][1]))) < 1e-6
assert r <= mu + 1e-9 and up <= s and abs(s - math.sqrt(sum(x * x for rw in M for x in rw))) < 1e-12
assert abs(det_I) < 1e-12 and abs(d1 - 1) < 1e-9 and abs(d2 - 1) < 1e-9 and abs(l1 + l2 - 1) < 1e-12 and abs(l1 * l2) < 1e-12
assert fr < 1e-12 and abs(fmu - 1) < 1e-3 and abs(fup - 1) < 1e-6 and abs(ft - 1) < 1e-9 and abs(f2 + 1) < 1e-9
assert abs(rank1(FLIP) - fmu) < 1e-3 and all(abs(LM[i][k] - M[i][k]) < 1e-12 for i in range(2) for k in range(2))
assert abs(Lw.imag) < 1e-12 and abs(mp - r1p) < 1e-6 and 1 < mp < 1.05 and abs(wp - WN) < 0.02 and ps[0][0] < 0 < ps[2][0] and abs(ps[1][0]) < 1e-9 and abs(ps[1][1] - WN) < 1e-9
assert abs(det_f) < 1e-12 and abs(smax(full) * s - 1) < 1e-12
assert abs(best_d(big)[1] - 1.25 * up) < 1e-9
print("ALL CHECKS PASS")
