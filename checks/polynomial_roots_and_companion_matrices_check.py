# Every root at once -- the check behind the card.  Standard library only: math gives sqrt.
# Roots of a lease's degree-6 polynomial by bisection, Newton with deflation, and companion eigenvalues.
import math
U = 2.0 ** -53                                     # the unit roundoff u of a double
def sci(v, d=2):                                   # 1.49e-11, the form Rust prints
    m, e = f"{v:.{d}e}".split("e")
    return f"{m}e{int(e)}"
class Z(complex):                                  # complex arithmetic written out, as in the Rust
    def __add__(s, o): o = complex(o); return Z(s.real + o.real, s.imag + o.imag)
    def __sub__(s, o): o = complex(o); return Z(s.real - o.real, s.imag - o.imag)
    def __mul__(s, o): o = complex(o); return Z(s.real * o.real - s.imag * o.imag, s.real * o.imag + s.imag * o.real)
    def __truediv__(s, o):
        o = complex(o); d = o.real * o.real + o.imag * o.imag
        return Z((s.real * o.real + s.imag * o.imag) / d, (s.imag * o.real - s.real * o.imag) / d)
    def conjugate(s): return Z(s.real, -s.imag)
def cabs(z): return math.sqrt(z.real * z.real + z.imag * z.imag)
def csqrt(z):
    m = cabs(z)
    return Z(math.sqrt(max(0.0, (m + z.real) / 2)), math.copysign(math.sqrt(max(0.0, (m - z.real) / 2)), z.imag))
def horner(a, z):                                  # a: highest power first; p(z), p'(z), quotient
    b, d, z, q = Z(a[0]), Z(0), Z(z), []
    for c in a[1:]:
        q.append(b)                                # the partial sums are the quotient p/(x - z)
        d, b = d * z + b, b * z + c
    return b, d, q
def backward(a, z):                                # |p(z)| / sum |a_k| |z|^k, in units of u
    return cabs(horner(a, z)[0]) / sum(abs(c) * cabs(z) ** (len(a) - 1 - k) for k, c in enumerate(a)) / U
def newton(a, z, steps=60):
    for k in range(steps):
        f, d, _ = horner(a, z)
        s = f / d
        z = z - s
        if cabs(s) <= 4 * U * cabs(z): return z, k + 1
    return z, steps
def companion(a, sign=-1.0):                       # top row -a_(n-1)/a_n ... -a_0/a_n, ones below
    C = [[Z(1) if i == j + 1 else Z(0) for j in range(len(a) - 1)] for i in range(len(a) - 1)]
    C[0] = [Z(sign * c / a[0]) for c in a[1:]]
    return C
def eig(H):                                        # shifted QR by Givens rotations on Hessenberg H
    m, out, steps, mults = len(H), [], 0, 0
    while m > 1:
        if cabs(H[m - 1][m - 2]) <= U * (cabs(H[m - 1][m - 1]) + cabs(H[m - 2][m - 2])):
            out.append(H[m - 1][m - 1]); m -= 1; continue
        a, b, c, d = H[m - 2][m - 2], H[m - 2][m - 1], H[m - 1][m - 2], H[m - 1][m - 1]
        g = csqrt((a - d) * (a - d) * 0.25 + b * c)  # shift: eigenvalue of the corner nearer d
        mu, steps = min(((a + d) * 0.5 + g, (a + d) * 0.5 - g), key=lambda t: cabs(t - d)), steps + 1
        for i in range(m): H[i][i] = H[i][i] - mu
        rots = []; assert steps < 1000              # QR must converge, never loop forever
        for k in range(m - 1):                     # H - mu I = Q R, one rotation per column
            x, y = H[k][k], H[k + 1][k]
            r = math.sqrt(x.real * x.real + x.imag * x.imag + y.real * y.real + y.imag * y.imag)
            cs, sn = (x / r, y / r) if r > 0 else (Z(1), Z(0))
            for j in range(k, m):
                u, v = H[k][j], H[k + 1][j]
                H[k][j], H[k + 1][j] = cs.conjugate() * u + sn.conjugate() * v, cs * v - sn * u
            rots.append((cs, sn)); mults += 4 * (m - k)
        for k, (cs, sn) in enumerate(rots):        # then R Q + mu I: same eigenvalues
            for i in range(min(k + 2, m)):
                u, v = H[i][k], H[i][k + 1]
                H[i][k], H[i][k + 1] = u * cs + v * sn, v * cs.conjugate() - u * sn.conjugate()
            mults += 4 * min(k + 2, m)
        for i in range(m): H[i][i] = H[i][i] + mu
    return out + [H[0][0]], steps, mults
def order(rs): return sorted(rs, key=lambda z: (-round(z.real, 9), -z.imag))
def show(z): return f"{z.real:.10f}" + (f" {'+-'[z.imag < 0]} {abs(z.imag):.10f}i" if abs(z.imag) > 1e-12 else "")
# ---- the lease: p(x) = 10000x^6 - 1500x^5 - 2000x^4 - 2000x^3 - 2500x^2 - 2500x - 1500 ----
a = [10000.0, -1500.0, -2000.0, -2000.0, -2500.0, -2500.0, -1500.0]; n = len(a) - 1
p5, dp5, q5 = horner(a, 1.05)
p5, dp5, naive = p5.real, dp5.real, sum(a[k] * 1.05 ** (n - k) for k in range(n + 1))
print("Horner at x = 1.05: " + ", ".join(f"{b:.7f}".rstrip("0").rstrip(".") for b in [t.real for t in q5] + [p5]))
print(f"p(1.05) = {p5:.7f}; by powers {naive:.7f}; p'(1.05) = {dp5:.7f}; NPV at 5% = {-p5 / 1.05 ** 6:.2f} dollars; "
      f"cost {n} multiplications and {n} additions, by powers {n * (n + 1) // 2} multiplications")
assert abs(p5 - naive) < 1e-9 and abs(p5 + 140.9784375) < 1e-9
npv = [-horner(a, x)[0].real / (x * x * x * x * x * x) for x in [1.0 + k / 100 for k in range(11)]]
print("chart, NPV in dollars at 0% to 10%: " + " ".join(f"{v:.0f}" for v in npv))
lo, hi = 1.0, 1.1                                  # road 1: bisection, signs only, to the last bit
while lo < (lo + hi) / 2 < hi:
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if horner(a, mid)[0].real < 0 else (lo, mid)
xn, kn = newton(a, 1.05)
print(f"bisection root {lo:.16f}; Newton from 1.05: step 1 {1.05 - p5 / dp5:.10f}, root {xn.real:.16f} in {kn} steps")
pl, dpl, ql = horner(a, lo)
print("deflated quotient: " + ", ".join(f"{c.real:.4f}" for c in ql) + f"; remainder {sci(pl.real)}")
roads, nsteps, qd, drift = [], 0, a, 0.0           # road 2: Newton, deflate, polish on the full p
while len(qd) > 1:
    z, k = newton(qd, Z(0.5, 0.5))
    zp, k2 = newton(a, z)                          # polish: how far had the quotient's root drifted?
    roads.append(zp); nsteps += k + k2; qd = horner(qd, zp)[2]; drift = max(drift, cabs(zp - z))
C = companion(a)
print("companion top row: " + ", ".join(f"{C[0][j].real:.2f}" for j in range(n)))
ev, qsteps, qmults = eig(C)                        # road 3: eigenvalues of the companion matrix
ev, roads = order(ev), order(roads)
print(f"eigenvalues: {qsteps} QR steps, {qmults} complex multiplications; Newton + deflation: {nsteps} steps, polishing moved a root at most {sci(drift)}")
for z, w in zip(ev, roads):
    e1, e2 = backward(a, z), backward(a, w)
    print(f"  {show(z):<31} backward error {e1:4.1f} u, Newton's {e2:3.1f} u, gap {sci(cabs(z - w))}")
    assert e1 < 50 and e2 < 2 and cabs(z - w) < 1e-14
irr, s, pr = ev[0].real, Z(0), Z(1)
for z in ev: s, pr = s + z, pr * z
print(f"Vieta: sum of roots {s.real:.12f} (want 0.15), product {pr.real:.12f} (want -0.15)")
assert abs(s.real - 0.15) < 1e-13 and abs(pr.real + 0.15) < 1e-13 and abs(ev[0].imag) < 1e-14
S = sum(abs(c) * irr ** (n - k) for k, c in enumerate(a))
kap, rho = S / (irr * dpl.real), 2 * n * U / (1 - 2 * n * U) * S / dpl.real
est = kap * backward(a, ev[0]) * U * irr
print(f"IRR = {100 * (irr - 1):.4f}% a year; kappa = {kap:.4f}; noise radius {sci(rho)}; QR minus bisection "
      f"{sci(irr - lo)}, minus Newton {sci(irr - xn.real)}, estimate kappa eta x* {sci(est)}")
assert max(abs(irr - lo), abs(irr - xn.real), abs(lo - xn.real)) <= 2 * rho and 0.5 < abs(irr - xn.real) / est < 2
x2 = order(eig(companion([a[0] * 1.01] + [c * 0.99 for c in a[1:]]))[0])[0].real
print(f"price +1%, rents -1%: root moves {irr - x2:.6f}, first-order 0.01 kappa x* = {0.01 * kap * irr:.6f}, "
      f"IRR {100 * (x2 - 1):.4f}%")
assert 0.98 < (irr - x2) / (0.01 * kap * irr) < 1.0
dbl = order(eig(companion([1.0, -2.7, 2.3625, -0.6615]))[0])  # (x - 1.05)^2 (x - 0.6)
print(f"double root 1.05 of (x - 1.05)^2 (x - 0.6): computed {show(dbl[0])}, error {sci(cabs(dbl[0] - 1.05))}")
assert 1e-9 < cabs(dbl[0] - 1.05) < 1e-7
bad = eig(companion(a, +1.0))[0]                   # the top row without its minus signs
print(f"top row without minus signs: {sum(abs(z.imag) < 1e-9 for z in bad)} real eigenvalues, largest real part {max(z.real for z in bad):.4f}")
assert all(abs(z.imag) > 0.1 for z in bad)
same = {show(newton(a, Z(s, 0.5))[0]) for s in (-1.0, -0.6, -0.2, 0.2, 0.6, 1.0)}  # no deflation, six starts
print(f"no deflation: six Newton runs from x + 0.5i, x = -1 to 1, give {len(same)} distinct roots: " + ", ".join(sorted(same)))
w = [1]                                            # ---- Wilkinson's polynomial (x - 1)(x - 2)...(x - 20) ----
for k in range(1, 21): w = [s1 - k * s2 for s1, s2 in zip(w + [0], [0] + w)]
wf = [float(c) for c in w]
print(f"Wilkinson: x^19 coefficient {w[1]}, constant {w[20]}; {sum(float(c) != c for c in w)} of 21 not exact as doubles")
we = eig(companion(wf))[0]
errs = [min(cabs(z - k) for z in we) for k in range(1, 21)]
kw = [sum(abs(c) * k ** (20 - j) for j, c in enumerate(wf)) / (k * math.factorial(k - 1) * math.factorial(20 - k)) for k in range(1, 21)]
for k in (1, 5, 10, 16, 20):
    print(f"  root {k:>2}: kappa {sci(kw[k - 1])}, computed error {sci(errs[k - 1])}, u kappa x* {sci(U * kw[k - 1] * k)}")
assert all(errs[j] <= 50 * U * kw[j] * (j + 1) for j in range(20)) and max(errs) > 1e-3
print(f"  worst computed error {max(errs):.4f}, at root {errs.index(max(errs)) + 1}")
for z0 in (21.0, 0.0):                             # deflate without polishing, from the top and from the bottom
    qd, got = wf, []
    while len(qd) > 1: z = newton(qd, Z(z0, 0.0))[0]; got.append(z); qd = horner(qd, z)[2]
    dw = max(min(cabs(z - k) for z in got) for k in range(1, 21)); assert (dw > 1) == (z0 > 20)
    print(f"  unpolished deflation, Newton started at {z0:.0f}: worst error {dw:.4f}")
print(f"  first-order shift of root 16 for -2^-23 on x^19: {2.0 ** -23 * 16.0 ** 19 / horner(wf, 16.0)[1].real:.1f}")
pw = order([z for z in eig(companion([1.0, wf[1] - 2.0 ** -23] + wf[2:]))[0] if z.imag > -1e-6])
print("  roots after -2^-23 on x^19: " + ", ".join(f"{z.real:.2f}" + (f" +- {z.imag:.2f}i" if z.imag > 1e-6 else "") for z in reversed(pw)))
assert any(cabs(z - Z(16.730737466, 2.812624896)) < 1e-3 for z in pw)
print("ALL CHECKS PASS")
