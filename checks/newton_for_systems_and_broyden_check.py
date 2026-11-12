# Newton for systems and Broyden: the check behind the card.  Standard library only.
# Two mixing tanks: find the stock flow p and water flow q (L/s) that hold tank 1 at
# 4 mg/L and tank 2 at 2.5 mg/L.  A closed form, Newton and Broyden must all agree.
from math import sqrt, log, log10

C0, C1, C2, K, B1, B2 = 10.0, 4.0, 2.5, 0.002, 4.0, 40.0  # mg/L x3, decay 1/s, tank sizes s^2/L
def sci(v):                                   # 1.25e-9, the form Rust prints
    m, e = f"{v:.2e}".split("e")
    return f"{m}e{int(e)}"
def F(v):                                     # the two balances, mg/s: in - out - decayed
    s = v[0] + v[1]
    return [C0 * v[0] - C1 * s * (1 + K * B1 * s), C1 * s - C2 * s * (1 + K * B2 * s)]
def J(v):                                     # Jacobian: one row per balance, one column per flow
    s = v[0] + v[1]
    h, g = C1 * (1 + 2 * K * B1 * s), C1 - C2 * (1 + 2 * K * B2 * s)
    return [[C0 - h, -h], [g, g]]
def det(A): return A[0][0] * A[1][1] - A[0][1] * A[1][0]
def inv(A):
    d = det(A)
    return [[A[1][1] / d, -A[0][1] / d], [-A[1][0] / d, A[0][0] / d]]
def mv(A, v): return [A[0][0] * v[0] + A[0][1] * v[1], A[1][0] * v[0] + A[1][1] * v[1]]
def mm(A, B): return [[A[i][0] * B[0][j] + A[i][1] * B[1][j] for j in range(2)] for i in range(2)]
def sub(a, b): return [a[0] - b[0], a[1] - b[1]]
def nrm(v): return sqrt(v[0] * v[0] + v[1] * v[1])
def norm2(A):                                 # largest stretch of a 2x2 matrix
    t = sum(a * a for row in A for a in row)
    return sqrt((t + sqrt(t * t - 4 * det(A) * det(A))) / 2)
def closed(c2, k):                            # road 1: tank 2 fixes the total, tank 1 the split
    u = (C1 / c2 - 1) / (k * B2)
    return u, C1 * u * (1 + k * B1 * u) / C0
s_, x_ = closed(C2, K)
root = [x_, s_ - x_]
err = lambda v: nrm(sub(v, root))
print(f"closed form: total {s_:.4f} L/s, stock p* = {root[0]:.4f}, water q* = {root[1]:.4f} L/s")
print(f"tanks at the answer: {B1 * s_ * s_:.1f} L and {B2 * s_ * s_:.1f} L, stays {B1 * s_:.1f} s and {B2 * s_:.1f} s")
Js = J(root)
print(f"J(x*) = [[{Js[0][0]:.2f}, {Js[0][1]:.2f}], [{Js[1][0]:.2f}, {Js[1][1]:.2f}]], det {det(Js):.2f}, "
      f"||J^-1|| = {norm2(inv(Js)):.4f}, kappa = {norm2(Js) * norm2(inv(Js)):.2f}")
m1, m2 = 2 * C1 * K * B1, 2 * C2 * K * B2
L = 2 * sqrt(m1 * m1 + m2 * m2)   # Lipschitz constant of J
x0 = [2.0, 6.0]                               # yesterday's settings
def conc(v):                                  # what the two tanks read at flows v
    s = v[0] + v[1]; c = C0 * v[0] / (s * (1 + K * B1 * s))
    return c, c / (1 + K * B2 * s)
J0 = J(x0); st = mv(inv(J0), F(x0))
print(f"Newton step 1 by hand: J(x0) = [[{J0[0][0]:.3f}, {J0[0][1]:.3f}], [{J0[1][0]:.3f}, {J0[1][1]:.3f}]], "
      f"det {det(J0):.3f}, step ({-st[0]:.6f}, {-st[1]:.6f})")
print("yesterday's flows (2, 6) give tanks %.4f and %.4f mg/L; residual F = (%.4f, %.4f) mg/s" % (*conc(x0), *F(x0)))

def newton(v, n):
    out = [v]
    for _ in range(n):
        if F(v) == [0.0, 0.0]: break
        v = sub(v, mv(inv(J(v)), F(v))); out.append(v)
    return out

def broyden(v, H, n):                         # H tracks the inverse of B by Sherman-Morrison
    out, f, B, hb, tab = [v], F(v), inv(H), 0.0, []
    for _ in range(n):
        d = mv(H, f); d = [-d[0], -d[1]]
        w = [v[0] + d[0], v[1] + d[1]]; fw = F(w); y = sub(fw, f)
        if d == [0.0, 0.0] or y == [0.0, 0.0]: break
        Hy = mv(H, y); sH = [d[0] * H[0][0] + d[1] * H[1][0], d[0] * H[0][1] + d[1] * H[1][1]]; tab.append((B, d))
        den, u, r = d[0] * Hy[0] + d[1] * Hy[1], sub(d, Hy), sub(y, mv(B, d))
        H = [[H[i][j] + u[i] * sH[j] / den for j in range(2)] for i in range(2)]
        B = [[B[i][j] + r[i] * d[j] / (d[0] * d[0] + d[1] * d[1]) for j in range(2)] for i in range(2)]
        P = mm(H, B); hb = max(hb, abs(P[0][0] - 1) + abs(P[0][1]) + abs(P[1][0]) + abs(P[1][1] - 1))
        if len(out) == 3: sec = sub(mv(B, d), y); s3 = nrm(y)  # secant condition B s = y, in floats
        v, f = w, fw; out.append(v)
    return out, hb, B, sec, s3, tab                # tab: each B_k with its step s_k

def order(e, k): return log(e[k + 1] / e[k]) / log(e[k] / e[k - 1])
N = newton(x0, 6); en = [err(v) for v in N]
print("Newton from (2, 6)  k  stock p   water q   residual   error     e_k/e_(k-1)^2  bound")
for k in range(5):
    rat = f"{en[k] / (en[k - 1] * en[k - 1]):.4f}" if 0 < k < 4 else ("-" if k == 0 else "floor")
    bd = L / 2 * norm2(inv(J(N[k - 1]))) * en[k - 1] * en[k - 1] if 0 < k < 4 else 0
    if bd: assert en[k] <= bd                 # the theorem's bound holds at every step above the floor
    print(f"{'':19} {k}  {N[k][0]:.6f}  {N[k][1]:.6f}  {sci(nrm(F(N[k]))):>9}  {sci(en[k]):>9}  "
          f"{rat:>13}  {sci(bd) if bd else '-':>8}")
print(f"order at steps 2, 3: {order(en, 1):.3f}, {order(en, 2):.3f}; constant (L/2)||J*^-1|| = "
      f"{L / 2 * norm2(inv(Js)):.4f}, L = 2 sqrt({m1:.3f}^2 + {m2:.3f}^2) = {L:.4f}")
print(f"guaranteed start radius 1/(2 L ||J*^-1||) = {1 / (2 * L * norm2(inv(Js))):.2f} L/s; yesterday's start is {sci(en[0])} away")
print("bound / true error at steps 2, 3:", ", ".join(f"{L / 2 * norm2(inv(J(N[k - 1]))) * en[k - 1] * en[k - 1] / en[k]:.4f}" for k in (2, 3)))
est = nrm(F(N[3])) * norm2(inv(J(N[3])))
print(f"error estimate at step 3: residual x ||J^-1|| = {sci(est)}, true error {sci(en[3])}, ratio {est / en[3]:.4f}")
assert en[3] <= est < 1.1 * en[3]
Bs, hb, B, sec, s3, tab = broyden(x0, inv(J(x0)), 7); eb = [err(v) for v in Bs]
print("Broyden from (2, 6) k  stock p   water q   residual   error     e_k/e_(k-1)")
for k in range(6):
    print(f"{'':19} {k}  {Bs[k][0]:.6f}  {Bs[k][1]:.6f}  {sci(nrm(F(Bs[k]))):>9}  {sci(eb[k]):>9}  "
          f"{sci(eb[k] / eb[k - 1]) if k else '-':>11}")
print(f"orders at steps 3, 4: {order(eb, 2):.3f}, {order(eb, 3):.3f}; secant miss |B s - y| = {sci(nrm(sec))} "
      f"of |y| = {sci(s3)}")
dm = [nrm(sub(mv(Bk, d), mv(Js, d))) / nrm(d) for Bk, d in tab]   # B_k's error along its own step
gap, B5 = [norm2([[Bk[i][j] - Js[i][j] for j in range(2)] for i in range(2)]) for Bk, _ in tab], tab[5][0]
print(f"Sherman-Morrison: largest |H B - I| over the run = {sci(hb)}; "
      f"B_5 = [[{B5[0][0]:.2f}, {B5[0][1]:.2f}], [{B5[1][0]:.2f}, {B5[1][1]:.2f}]] against J(x*) above")
print("Dennis-More, k = 0-5: |(B_k - J*) s_k|/|s_k| = " + ", ".join(sci(v) for v in dm[:6])
      + "; ||B_k - J*|| = " + ", ".join(f"{v:.4f}" for v in gap[:6]))
print(f"at the floor, k = 5, 6: |s_k| = {sci(nrm(tab[5][1]))}, {sci(nrm(tab[6][1]))}; "
      f"after them B_7 = [[{B[0][0]:.2f}, {B[0][1]:.2f}], [{B[1][0]:.2f}, {B[1][1]:.2f}]]")
assert abs(det(Js) - C0 * (C1 - C2 * (1 + 2 * K * B2 * s_))) < 1e-12   # det J = c0 g, by hand
assert nrm(F(root)) < 1e-12 and err(N[5]) < 1e-14 and err(Bs[6]) < 1e-14  # three roads meet
assert abs(order(en, 2) - 2) < 0.05 and abs(en[3] / (en[2] * en[2]) - en[2] / (en[1] * en[1])) < 0.01
assert eb[5] / eb[4] < eb[4] / eb[3] < eb[3] / eb[2] < 0.2         # Broyden: superlinear
assert nrm(sec) < 1e-14 * s3 and hb < 1e-12 and dm[4] < 1e-3 * dm[2] and gap[4] > 0.05  # B fits its steps, not J*
C = [x0]; Hc = inv(J(x0))                     # break: freeze the first Jacobian
while err(C[-1]) >= 1e-9: C.append(sub(C[-1], mv(Hc, F(C[-1]))))
ec = [err(v) for v in C]
first = lambda e: next(k for k, v in enumerate(e) if v < 1e-9)
print(f"to an error under 1e-9 L/s: Newton {first(en)} steps, Broyden {first(eb)}, frozen Jacobian {len(C) - 1}"
      f" (ratio {ec[-1] / ec[-2]:.4f})")
nn, nb, nc = first(en), first(eb), len(C) - 1
print(f"evaluations of F, a Jacobian column costing one: Newton {3 * nn}, Broyden {nb + 2}, frozen {nc + 2}")
assert (nn, nb) == (4, 5) and 0.1 < ec[-1] / ec[-2] < 0.13 and nc > 2 * nn
sg = (C1 / C2 - 1) / (2 * K * B2)             # where the tank-2 row of J vanishes
print(f"break 1, start total {sg:.2f} L/s, e.g. (1, {sg - 1:.2f}): det J = {det(J([1.0, sg - 1])):.1f}, no Newton step")
Z = newton([1.0, 2.0], 40)
print(f"break 2, start (1, 2): Newton ends at ({abs(Z[-1][0]):.1f}, {abs(Z[-1][1]):.1f}) after {len(Z) - 1} steps, "
      f"the empty plant, residual {sci(nrm(F(Z[-1])))}")
assert abs(det(J([1.0, sg - 1]))) < 1e-12 and err(Z[-1]) > 5 and nrm(Z[-1]) < 1e-12
I_ = broyden(x0, [[1.0, 0.0], [0.0, 1.0]], 20)[0]
print(f"break 3, Broyden with B0 = I: errors {sci(err(I_[1]))}, {sci(err(I_[5]))} at steps 1, 5; "
      f"step 20 at ({abs(I_[20][0]):.4f}, {abs(I_[20][1]):.4f}), error {sci(err(I_[20]))}")
assert err(I_[20]) > 5 and nrm(I_[20]) < 1e-3
u2, p2 = closed(2.0, K); u3, p3 = closed(C2, K / 2)
n3, b3 = newton([3.0, 3.0], 9), broyden([3.0, 3.0], inv(J([3.0, 3.0])), 9)[0]
print(f"try: tank 2 at 2.0 mg/L gives total {u2:.2f}, p {p2:.4f}, q {u2 - p2:.4f}; decay k halved gives total "
      f"{u3:.2f}, p {p3:.4f}, q {u3 - p3:.4f}")
print(f"try: from (3, 3), Newton {first([err(v) for v in n3])} steps, Broyden {first([err(v) for v in b3])}")
assert abs(p2 - 5.5) < 1e-12 and abs(u3 - 2 * s_) < 1e-12
for n in (2, 500):
    print(f"cost per step at n = {n}: Newton {n + 1} evaluations + about {2 * n ** 3 / 3:,.0f} flops; "
          f"Broyden 1 evaluation + about {8 * n * n:,} flops")
pt = lambda e: f"{log10(max(e, 1e-16)):.2f}"
print("chart, log10 error, steps 0-9: Newton", ", ".join(pt(e) for e in (en + [0.0] * 9)[:10]))
print("chart, Broyden", ", ".join(pt(e) for e in (eb + [0.0] * 9)[:10]))
print("chart, frozen ", ", ".join(pt(e) for e in ec[:10]))
print("ALL CHECKS PASS")
