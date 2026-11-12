# Assembly and error: a 4 m cable at tension 2000 N carries planters, 20 + 10x N/m.
# Anchored at x = 0 (essential: u = 0); a ring on a post at x = 4 m is pulled down by
# 40 N (natural: T u'(4) = 40). Linear elements. Python standard library only.
import math
T, L, P, PI = 2000.0, 4.0, 40.0, 3.141592653589793

def u_ex(x):  return (200.0 * x - 10.0 * x * x - 5.0 * x * x * x / 3.0) / T   # sag, m
def du_ex(x): return (200.0 - 20.0 * x - 5.0 * x * x) / T                     # slope

def assemble(n, a, b, p_end, lamps, add=True):
    """Add n element matrices and loads into a tridiagonal K (diagonal, off) and F."""
    h = L / n
    di, off, F = [0.0] * (n + 1), [0.0] * n, [0.0] * (n + 1)
    for e in range(n):
        k = T / h
        if add: di[e] += k; di[e + 1] += k
        else:   di[e] = k; di[e + 1] = k            # the bug: overwrite instead of add
        off[e] = -k
        fl, fr = a + b * e * h, a + b * (e + 1) * h   # load per metre at the element's ends
        F[e] += h * (2.0 * fl + fr) / 6.0            # integral of f times the left hat
        F[e + 1] += h * (fl + 2.0 * fr) / 6.0        # integral of f times the right hat
    for (q, xs) in lamps:                            # a point load shared by the two hats
        e = min(int(xs / h), n - 1); t = (xs - e * h) / h
        F[e] += q * (1.0 - t); F[e + 1] += q * t
    F[n] += p_end                                    # natural condition: one load entry
    return di, off, F

def thomas(di, off, F):
    """Tridiagonal elimination. Returns (solution or None, pivots up to the first zero)."""
    m = len(di); d, r = di[:], F[:]
    for i in range(1, m):
        if d[i - 1] == 0.0: return None, d[:i]
        w = off[i - 1] / d[i - 1]; d[i] -= w * off[i - 1]; r[i] -= w * r[i - 1]
    if d[-1] == 0.0: return None, d
    x = [0.0] * m; x[-1] = r[-1] / d[-1]
    for i in range(m - 2, -1, -1):
        x[i] = (r[i] - off[i] * x[i + 1]) / d[i]
    return x, d

def solve(n, a=20.0, b=10.0, p_end=P, lamps=()):
    di, off, F = assemble(n, a, b, p_end, lamps)
    x, _ = thomas(di[1:], off[1:], F[1:])            # essential: drop node 0's row and column
    return [0.0] + x

g1, g2 = (math.sqrt(3.0 / 7.0 + s * math.sqrt(6.0 / 5.0)) for s in (-2.0 / 7.0, 2.0 / 7.0))
w1, w2 = (18.0 + math.sqrt(30.0)) / 36.0, (18.0 - math.sqrt(30.0)) / 36.0
GAUSS = [(-g2, w2), (-g1, w1), (g1, w1), (g2, w2)]    # 4-point Gauss-Legendre on [-1, 1]

def errors(U, uf, duf, cuts=()):
    """RMS slope error and RMS sag error over the cable, element by element."""
    n = len(U) - 1; h = L / n; s1 = s0 = 0.0
    for e in range(n):
        xa, xb = e * h, (e + 1) * h
        pts = [xa] + [c for c in cuts if xa < c < xb] + [xb]
        for p, q in zip(pts, pts[1:]):
            for (z, w) in GAUSS:
                x = 0.5 * (p + q) + 0.5 * (q - p) * z; t = (x - xa) / h
                d1 = duf(x) - (U[e + 1] - U[e]) / h
                d0 = uf(x) - U[e] * (1.0 - t) - U[e + 1] * t
                s1 += 0.5 * (q - p) * w * d1 * d1; s0 += 0.5 * (q - p) * w * d0 * d0
    return math.sqrt(s1 / L), math.sqrt(s0 / L)

# ---- four element matrices added into one system ----
di, off, F = assemble(4, 20.0, 10.0, P, ())
print("element matrix, N/m  " + " ".join(f"{v:7.0f}" for v in (T, -T, -T, T)))
for i in range(5):
    row = [di[i] if j == i else (off[min(i, j)] if abs(i - j) == 1 else 0.0) for j in range(5)]
    print(f"K row {i}              " + " ".join(f"{v:7.0f}" for v in row))
print(f"nonzeros of 25       {3 * 5 - 2:7d}")
print("F, N                 " + " ".join(f"{v:7.3f}" for v in F))
U = solve(4)
print("FE sag at nodes, mm  " + " ".join(f"{1000.0 * v:7.3f}" for v in U))
print("exact sag, mm        " + " ".join(f"{1000.0 * u_ex(float(i)):7.3f}" for i in range(5)))
carried, tele, acc = [0.0] * 4, [0.0], 0.0
for i in range(3, -1, -1): acc += F[i + 1]; carried[i] = acc   # load each element carries
for i in range(4): tele.append(tele[-1] + carried[i] / T)
print("load carried, N      " + " ".join(f"{v:7.3f}" for v in carried))
print("telescoped sag, mm   " + " ".join(f"{1000.0 * v:7.3f}" for v in tele))
R = di[0] * U[0] + off[0] * U[1] - F[0]
print(f"anchor force, N      {R:9.3f}   slope there {-R / T:.3f}")
print(f"thomas flops 8n-7    n=4: {8 * 4 - 7}   n=1024: {8 * 1024 - 7}   dense 2n^3/3: {2.0 * 1024.0 ** 3 / 3.0:.3e}")
se = [0.0] * 4
for e in range(4):
    for (z, w) in GAUSS: se[e] += 0.5 * w * (du_ex(e + 0.5 + 0.5 * z) - (U[e + 1] - U[e]))
orth = max(abs(se[i - 1] - (se[i] if i < 4 else 0.0)) for i in range(1, 5))  # a(u - U, hat_i)
print(f"orthogonality, max   {orth:.1e}")
# ---- what breaks ----
do, oo, Fo = assemble(4, 20.0, 10.0, P, (), add=False)
_, piv_over = thomas(do[1:], oo[1:], Fo[1:])         # overwrite instead of add
no_p = solve(4, p_end=0.0)                           # the 40 N natural load left out
x3, _ = thomas(di[1:4], off[1:3], F[1:4])            # ring treated as fixed: drop node 4 too
_, piv = thomas(di, off, F)                          # node 0 kept: no essential condition
print(f"wrong: overwrite, zero pivot in row {len(piv_over)} of 4")
print(f"wrong: drop 40 N, tip mm    {1000.0 * no_p[4]:9.3f}")
print(f"wrong: ring fixed, mid mm   {1000.0 * x3[1]:9.3f}")
print(f"wrong: no anchor, zero pivot in row {len(piv)} of 5")
# ---- error against element size ----
c2 = 0.0
for (z, w) in GAUSS: c = (20.0 + 10.0 * (2.0 + 2.0 * z)) / T; c2 += 2.0 * w * c * c
rms_curv = math.sqrt(c2 / L); print(f"RMS load, N/m        {T * rms_curv:9.3f}   RMS u'', 1/m {rms_curv:.4e}")
print("   n      h slope err     bound ratio sag err mm     bound ratio  ord1  ord2 node err m")
rows, prev = [], None
for k in range(2, 11):
    n = 2 ** k; h = L / n; U = solve(n)
    e1, e0 = errors(U, u_ex, du_ex)
    b1, b0 = h / PI * rms_curv, (h / PI) * (h / PI) * rms_curv
    node = max(abs(U[i] - u_ex(i * h)) for i in range(n + 1))
    o1, o0 = (math.log2(prev[0] / e1), math.log2(prev[1] / e0)) if prev else (0.0, 0.0)
    ords = f"{o1:5.3f} {o0:5.3f}" if prev else "    -     -"
    print(f"{n:4d} {h:6.4f} {e1:9.3e} {b1:9.3e} {b1 / e1:5.3f} {1000.0 * e0:9.3e} "
          f"{1000.0 * b0:9.3e} {b0 / e0:5.3f} {ords} {node:8.1e}")
    rows.append((n, e1, b1, e0, b0, o1, o0)); prev = (e1, e0)
XS, Q, lamp = 4.0 / 3.0, 100.0, []                   # one 100 N lamp at x = 4/3 m instead
for k in range(2, 11):
    n = 2 ** k; h = L / n; U = solve(n, 0.0, 0.0, 0.0, [(Q, XS)])
    e1, _ = errors(U, lambda x: Q * min(x, XS) / T, lambda x: Q / T if x < XS else 0.0, (XS,))
    lamp.append((n, e1, Q / T * math.sqrt(2.0 * h / 9.0 / L)))
print(f"lamp n=4 slope err   {lamp[0][1]:.4e}  closed form {lamp[0][2]:.4e}")
print(f"lamp order 1024/512  {math.log2(lamp[-2][1] / lamp[-1][1]):.3f}")
U = solve(4, 20.0, 0.0, 0.0)                         # uniform 20 N/m, ring free: road check
e1u, _ = errors(U, lambda x: (80.0 * x - 10.0 * x * x) / T, lambda x: (80.0 - 20.0 * x) / T)
cf = 20.0 / (2.0 * T) / math.sqrt(3.0); print(f"uniform n=4 slope    {e1u:.6e}  closed form {cf:.6e}")
s2, be = 0.0, 5.0 / (3.0 * T)                        # planters, n = 4: error on element e is s(1 - s)(a + be s)
for e in range(4): a = be + (10.0 + 5.0 * e) / T; s2 += (a * a + a * be) / 30.0 + be * be / 105.0   # its exact integral
cs = math.sqrt(s2 / L); print(f"planter n=4 sag, mm  {1000.0 * rows[0][3]:.6e}  closed form {1000.0 * cs:.6e}")
print("figure, node px " + " ".join(f"({20 + 80 * i},{40.0 + 500.0 * u_ex(float(i)):.1f})" for i in range(5)))
print("figure, curve px " + " ".join(f"{40.0 + 500.0 * u_ex(0.25 * j):.1f}" for j in range(17)))
for name, v in (("log10 h", [L / r[0] for r in rows]), ("log10 slope", [r[1] for r in rows]),
                ("log10 sag", [r[3] for r in rows]), ("log10 lamp", [r[1] for r in lamp])):
    print(f"chart, {name:<14}" + " ".join(f"{math.log10(x):6.2f}" for x in v))
assert max(abs(solve(4)[i] - u_ex(float(i))) for i in range(5)) < 1e-15, "nodes = exact sag"
assert max(abs(a - b) for a, b in zip(solve(4), tele)) < 1e-15, "force balance = the solve"
assert abs(R + 20.0 * 4.0 + 5.0 * 16.0 + P) < 1e-9, "anchor holds all 200 N"
assert all(r[1] <= r[2] and r[3] <= r[4] for r in rows), "true errors under the bounds"
assert abs(rows[-1][5] - 1.0) < 0.01 and abs(rows[-1][6] - 2.0) < 0.01, "orders 1 and 2"
assert all(abs(e - c) < 1e-12 for _, e, c in lamp), "lamp error = its closed form"
assert abs(e1u - cf) < 1e-15, "error integrator = the uniform-load closed form"
assert abs(rows[0][3] - cs) < 1e-15, "planters' sag error = its exact integral"
assert orth < 1e-15 and len(piv) == 5 and len(piv_over) == 2, "orthogonality; zero pivots"
print("ALL CHECKS PASS")
