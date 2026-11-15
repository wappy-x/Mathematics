# Orthogonal polynomials from Gram-Schmidt -- the check behind the card.  Standard library only.
# A polynomial is a list of exact fractions, lowest power first.  Every integral is exact:
# over [-1, 1], x^k integrates to 2/(k+1) for even k and to 0 for odd k.
from fractions import Fraction as F
from math import sqrt, log10

def mom(k, lo):                        # integral of x^k from lo (-1 or 0) to 1
    if lo == 0: return F(1, k + 1)
    return F(2, k + 1) if k % 2 == 0 else F(0)
def mul(p, q):
    r = [F(0)] * (len(p) + len(q) - 1)
    for i, a in enumerate(p):
        for j, b in enumerate(q): r[i + j] += a * b
    return r
def add(p, q, s):                      # p + s q
    n = max(len(p), len(q))
    p, q = p + [F(0)] * (n - len(p)), q + [F(0)] * (n - len(q))
    return [a + s * b for a, b in zip(p, q)]
def ev(p, x): return sum(c * x ** k for k, c in enumerate(p))
def ip(p, q, lo=-1): return sum(c * mom(k, lo) for k, c in enumerate(mul(p, q)))
def ip3(p, q): return sum(ev(p, x) * ev(q, x) for x in (-1, 0, 1))   # three samples only
def ip_abs(p): return sum(c * F(2, k + 2) for k, c in enumerate(p) if k % 2 == 0)  # <|x|, p>
def power(m): return [F(0)] * m + [F(1)]
def gram_schmidt(n, inner):            # leftovers p_0..p_n of 1, x, ..., x^n
    ps = []
    for m in range(n + 1):
        v = power(m)
        for p in ps: v = add(v, p, -inner(power(m), p) / inner(p, p))
        ps.append(v)
    return ps
def show(p): return "[" + ", ".join(str(c) for c in p) + "]"
def err2(g): return F(2, 3) - 2 * ip_abs(g) + ip(g, g)        # ||f - g||^2, f = |x|

NMAX = 16
ps = gram_schmidt(NMAX, ip)
P = [[c / ev(p, 1) for c in p] for p in ps]                   # scaled so P_n(1) = 1
for n in range(4): print(f"p{n} leftover", show(ps[n]))
print("P2, P3 scaled to 1 at x = 1", show(P[2]), show(P[3]), " leftover sizes^2", show([ip(p, p) for p in ps[:4]]))
# Road 2: Bonnet's recurrence (n+1) P_{n+1} = (2n+1) x P_n - n P_{n-1}, no inner products
B = [power(0), power(1)]
for n in range(1, NMAX): B.append([k / (n + 1) for k in add([(2 * n + 1) * k for k in mul(power(1), B[n])], B[n - 1], -n)])
assert all(P[n] == B[n] for n in range(NMAX + 1)), "Gram-Schmidt must give Legendre"
G = [[ip(power(i), power(j)) for j in range(3)] for i in range(3)]
for i in range(3): print(f"Gram row {i} of 1, x, x^2", show(G[i]))
offdiag = max(abs(ip(P[i], P[j])) for i in range(NMAX + 1) for j in range(i))
assert offdiag == 0, "Legendre Gram matrix must be diagonal"
assert all(ip(P[n], P[n]) == F(2, 2 * n + 1) for n in range(NMAX + 1)), "norm 2/(2n+1)"
print("Legendre Gram diagonal", show([ip(P[n], P[n]) for n in range(4)]), "off-diagonal max", offdiag)
for n in (1, 2, 4, 8, 16):
    print(f"new part of x^{n}: |p_n|/|x^n|", f"{sqrt(ip(ps[n], ps[n]) / ip(power(n), power(n))):.6f}")

# The fit: the fade |x| projected onto 1, x, x^2.  Road 1: one ratio per coefficient.
c = [ip_abs(P[n]) / ip(P[n], P[n]) for n in range(3)]
print("<|x|, P_n>", show([ip_abs(P[n]) for n in range(3)]), " energy per piece", show([c[n] ** 2 * ip(P[n], P[n]) for n in range(3)]))
fit = add(add([c[0]], P[1], c[1]), P[2], c[2])
print("coefficients c0 c1 c2", show(c), " fit", show(fit))
# Road 2: the normal equations G a = b with the plain powers, solved by elimination.
A = [G[i][:] + [ip_abs(power(i))] for i in range(3)]
print("right side b = <|x|, x^i>", show([row[3] for row in A]))
for k in range(3):
    for i in range(k + 1, 3):
        m = A[i][k] / A[k][k]; A[i] = [a - m * b for a, b in zip(A[i], A[k])]
a = [F(0)] * 3
for i in (2, 1, 0): a[i] = (A[i][3] - sum(A[i][j] * a[j] for j in range(i + 1, 3))) / A[i][i]
assert a == fit, "projection by ratios must equal the normal-equations solve"
e_direct = err2(fit)
e_pyth = F(2, 3) - sum(c[n] ** 2 * ip(P[n], P[n]) for n in range(3))
assert e_direct == e_pyth == F(1, 96), "Pythagoras: leftover energy"
print("error^2 direct", e_direct, " by Pythagoras", e_pyth, " error", f"{sqrt(e_direct):.6f}")
print("per second", e_direct / 2, " rms error", f"{sqrt(e_direct / 2):.6f}", " energy of fade", F(2, 3))
print("mean loudness: fit integral / 2", ip(fit, power(0)) / 2, " c0", c[0])
r = 1 / sqrt(3)                                               # zeros of P2
print("zeros of P2", f"{-r:.6f} {r:.6f}")
print("2-point rule on fit", f"{float(ev(fit, -r) + ev(fit, r)):.6f}", " exact", ip(fit, power(0)))
print("2-point rule on |x|", f"{2 * r:.6f}", " exact", ip_abs(power(0)))
print("chart t, x, fade, fit")
for i in range(9):
    x = F(i - 4, 4)
    print(f"chart {float((x + 1) / 2):.3f} {float(x):6.2f} {float(abs(x)):.4f} {float(ev(fit, x)):.4f}")
errs = {}
for N in (2, 4, 8, 16):
    e2 = F(2, 3) - sum(ip_abs(P[n]) ** 2 / ip(P[n], P[n]) for n in range(N + 1))
    errs[N] = sqrt(e2)
    print(f"truncation N = {N:2d}  error {errs[N]:.6f}  log10 N {log10(N):.4f}  log10 error {log10(errs[N]):.4f}")
slope = log10(errs[8] / errs[16]) / log10(2)
print("error falls like N to the power", f"-{slope:.4f}")
assert 1.2 < slope < 1.5 and errs[16] < errs[8] < errs[4], "error must keep falling, slowly"

# What breaks.
bad1 = [F(1, 2), F(0), ip_abs(power(2)) / ip(power(2), power(2))]   # x^2 never straightened
bad2 = add([ip_abs(P[0])], P[2], ip_abs(P[2]))                       # no division by |P_n|^2
print("wrong: skip shadow on 1", show(bad1), f"error {sqrt(err2(bad1)):.6f}", " <1, x^2>", ip(power(0), power(2)))
print("wrong: no divide by |P_n|^2", show(bad2), f"error {sqrt(err2(bad2)):.6f}")
print("wrong: interval [0, 1]  <P0, P1>", ip(P[0], P[1], 0), " <P1, P2>", ip(P[1], P[2], 0))
print("on [0, 1] the leftovers are", " ".join(show(p) for p in gram_schmidt(2, lambda u, v: ip(u, v, 0))))
q = gram_schmidt(3, ip3)
print("wrong: three samples  x^3 leftover", show(q[3]), " size^2", ip3(q[3], q[3]), " true size^2", ip(ps[3], ps[3]))
assert ip3(q[3], q[3]) == 0 and ip(q[3], q[3]) > 0, "three samples miss x^3 - x"
assert err2(bad1) > err2(fit) and err2(bad2) > err2(fit), "the projection is the closest"
print("ALL CHECKS PASS")
