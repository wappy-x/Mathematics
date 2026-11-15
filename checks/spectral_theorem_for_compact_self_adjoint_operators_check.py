# Compact and symmetric -- the check behind the card.  Standard library only;
# fractions does exact rational arithmetic, math gives sqrt, sin and pi.
# The sag operator of a 1 m string, K f(x) = integral of k(x, y) f(y) dy with
# k(x, y) = min(x, y)(1 - max(x, y)), is diagonalised three ways: the Rayleigh
# ratio on polynomials in exact rationals, a written-out Jacobi eigenvalue
# solver on an N-point grid, and the grid's closed form 1/(4(N+1)^2 sin^2(.)).
from fractions import Fraction as Fr
import math

C, TENSION, MU1 = 220.0, 100.0, 1 / math.pi ** 2   # wave speed m/s, tension N (illustrative)
def note(mu): return C / (2 * math.pi * math.sqrt(mu))     # Hz, since mu = 1/lambda

def pmul(a, b):                       # polynomials: lists of Fractions, index = power
    out = [Fr(0)] * (len(a) + len(b) - 1)
    for i, x in enumerate(a):
        for j, y in enumerate(b): out[i + j] += x * y
    return out
def integ(a): return [Fr(0)] + [c / (k + 1) for k, c in enumerate(a)]
def at1(a): return sum(a)
def inner(a, b): return at1(integ(pmul(a, b)))     # <a, b> = integral over [0, 1]
def sag(f):                           # K f: solve -u'' = f with u(0) = u(1) = 0
    p = integ(integ(f))
    u = [-c for c in p]; u[1] += at1(p)
    return u
def ratio(f): return inner(f, sag(f)) / inner(f, f)

def kern(x, y): return min(x, y) * (1 - max(x, y))
def grid(n):                          # K_N = h k(x_i, x_j) at x_i = i h, h = 1/(N+1)
    h = 1 / (n + 1)
    return [[h * kern(i * h, j * h) for j in range(1, n + 1)] for i in range(1, n + 1)]
def jacobi(a):                        # cyclic Jacobi rotations until off-diagonal is ~0
    n = len(a); a = [r[:] for r in a]
    v = [[1.0 if i == j else 0.0 for j in range(n)] for i in range(n)]
    for _ in range(60):
        off = sum(a[i][j] ** 2 for i in range(n) for j in range(i + 1, n))
        if off < 1e-30: break
        for p in range(n - 1):
            for q in range(p + 1, n):
                if a[p][q] == 0.0: continue
                th = (a[q][q] - a[p][p]) / (2 * a[p][q])
                t = (1.0 if th >= 0 else -1.0) / (abs(th) + math.sqrt(th * th + 1))
                c = 1 / math.sqrt(t * t + 1); s = t * c
                for m in (a, v):
                    for k in range(n):
                        x, y = m[k][p], m[k][q]; m[k][p] = c * x - s * y; m[k][q] = s * x + c * y
                for k in range(n):
                    x, y = a[p][k], a[q][k]; a[p][k] = c * x - s * y; a[q][k] = s * x + c * y
    order = sorted(range(n), key=lambda i: -a[i][i])
    return [a[i][i] for i in order], [[v[k][i] for k in range(n)] for i in order]
def closed(n, j):                     # exact eigenvalues of K_N (it inverts the second difference)
    return 1 / (4 * (n + 1) ** 2 * math.sin(j * math.pi / (2 * (n + 1))) ** 2)
def fr(q): return f"{q.numerator}/{q.denominator}"

one, bump = [Fr(1)], [Fr(0), Fr(1), Fr(-1)]          # trial loads 1 and x(1 - x)
r1, r2, r3 = ratio(one), ratio(bump), ratio(sag(bump))
print(f"string kernel min(x,y)(1-max(x,y)); c = {C:.0f} m/s; tension {TENSION:.0f} N")
print(f"push 1 N at the middle: middle moves {1000 * kern(0.5, 0.5) / TENSION:.3f} mm")
print(f"R(1) = {fr(r1)} = {float(r1):.6f} -> note {note(float(r1)):.2f} Hz")
print(f"R(x(1-x)) = {fr(r2)} = {float(r2):.6f} -> note {note(float(r2)):.2f} Hz")
print(f"R(K x(1-x)) = {fr(r3)} = {float(r3):.8f} -> note {note(float(r3)):.4f} Hz")
print(f"true top eigenvalue 1/pi^2 = {MU1:.8f} -> note {note(MU1):.4f} Hz")
errs, mats = [], {}
for n in (7, 15, 31, 63):
    vals, vecs = jacobi(grid(n)); mats[n] = (vals, vecs); errs.append(vals[0] - MU1)
    print(f"N {n:2d}: mu1 by Jacobi {vals[0]:.8f}, closed form {closed(n, 1):.8f}, "
          f"minus 1/pi^2 {vals[0] - MU1:.8f}")
    assert all(abs(vals[j] - closed(n, j + 1)) < 1e-12 for j in range(n))
shrink = [errs[i] / errs[i + 1] for i in range(3)]
print("error shrinks by " + ", ".join(f"{s:.3f}" for s in shrink) + " per doubling of N")
vals, vecs = mats[63]; h = 1 / 64; A = grid(63)
print("N 63, top five: " + ", ".join(f"{m:.6f}" for m in vals[:5]))
print("true, 1/(n pi)^2: " + ", ".join(f"{1 / (n * math.pi) ** 2:.6f}" for n in range(1, 6)))
e1 = vecs[0] if sum(vecs[0]) > 0 else [-x for x in vecs[0]]
gap = max(abs(e1[i] - math.sqrt(2 * h) * math.sin(math.pi * (i + 1) * h)) for i in range(63))
orth = max(abs(sum(vecs[a][k] * vecs[b][k] for k in range(63)) - (a == b))
           for a in range(63) for b in range(63))
rebuild = max(abs(sum(vals[m] * vecs[m][i] * vecs[m][j] for m in range(63)) - A[i][j])
              for i in range(63) for j in range(63))
print(f"top vector against sampled sqrt(2) sin(pi x): within 1e-9: {'yes' if gap < 1e-9 else 'no'}")
print(f"Q^T Q = I and Q D Q^T = K_63 within 1e-12: {'yes' if max(orth, rebuild) < 1e-12 else 'no'}")
w = [i * h * (1 - i * h) for i in range(1, 64)]          # power iteration, a second road
for _ in range(200):
    kw = [sum(A[i][j] * w[j] for j in range(63)) for i in range(63)]
    pw = sum(a * b for a, b in zip(w, kw)) / sum(a * a for a in w)
    w = [x / math.sqrt(sum(b * b for b in kw)) for x in kw]
print(f"power iteration, ratio of K_63 w to w: {pw:.8f}")
tr, hs = sum(A[i][i] for i in range(63)), sum(x * x for r in A for x in r)
print(f"N 63: sum of eigenvalues {sum(vals):.6f}, trace {tr:.6f}; limit 1/6 = {1 / 6:.6f}")
print(f"N 63: sum of squares {sum(m * m for m in vals):.6f}, of entries {hs:.6f}; limit 1/90 = {1 / 90:.6f}")
ck = [sum(1 for m in mats[n][0] if m > 0.001) for n in (7, 15, 31, 63)]
cm = [sum(1 for i in range(1, n + 1) if 0.4 <= i / (n + 1) <= 0.6) for n in (7, 15, 31, 63)]
print(f"eigenvalues above 0.001, N 7/15/31/63: {ck}; true {sum(1 for n in range(1, 99) if MU1 / n ** 2 > 0.001)}")
print(f"multiplication by x, eigenvalues in [0.4, 0.6], N 7/15/31/63: {cm}")
sums, s = [], 0.0                                         # uniform load: 1 N/m on the string
for n in (1, 3, 5):
    s += MU1 / n ** 2 * (2 * math.sqrt(2) / (n * math.pi)) * math.sqrt(2) * math.sin(n * math.pi / 2)
    sums.append(1000 * s / TENSION)
print("midpoint sag, modes 1 / 1,3 / 1,3,5: " + ", ".join(f"{x:.4f}" for x in sums)
      + f" mm; exact {1000 * float(sag(one)[1] / 2 + sag(one)[2] / 4) / TENSION:.4f} mm")
vol1 = inner(one, integ(one)) / inner(one, one)           # Volterra V f(x) = integral 0..x of f
vw = [1.0] * 63; hv = 1 / 63
V = [[hv if j < i else (hv / 2 if j == i else 0.0) for j in range(63)] for i in range(63)]
for _ in range(300):
    y = [sum(V[i][j] * vw[j] for j in range(63)) for i in range(63)]
    z = [sum(V[i][j] * y[i] for i in range(63)) for j in range(63)]
    vn = math.sqrt(sum(a * a for a in z) / sum(a * a for a in vw))
    vw = [x / math.sqrt(sum(b * b for b in z)) for x in z]
print(f"running total V: best ratio {fr(vol1)} = {float(vol1):.6f}; norm at N 63 {math.sqrt(vn):.6f}, "
      f"2/pi = {2 / math.pi:.6f}; every grid eigenvalue {hv / 2:.6f}")
node = [Fr(0), Fr(1), Fr(-3), Fr(2)]                      # x(1 - x)(1 - 2x), a node at 1/2
r4 = ratio(node); raw = inner(bump, sag(bump))
print(f"trial with a node at the middle: R = {fr(r4)} = {float(r4):.6f} -> note {note(float(r4)):.2f} Hz")
print(f"top of the ratio left undivided: {fr(raw)} = {float(raw):.6f} -> note {note(float(raw)):.2f} Hz")
print("hand steps: K x(1-x) coefficients, x^0 to x^4: " + ", ".join(fr(c) for c in sag(bump)))
print(f"hand steps: <f,f> = {fr(inner(bump, bump))}; c/(2 pi) = {C / (2 * math.pi):.4f}; "
      f"17/168 falls short of 1/pi^2 by {100 * (MU1 - float(r2)) / MU1:.3f} %")
print("chart, n: true 1/(n pi)^2 | N 7 grid")
for n in range(1, 8):
    print(f"chart, {n}: {MU1 / n ** 2:.4f} | {mats[7][0][n - 1]:.4f}")
assert r1 < r2 < r3 < MU1 and r2 == Fr(17, 168)           # ratios climb to mu1 from below
assert all(3.9 < x < 4.1 for x in shrink) and gap < 1e-9 and max(orth, rebuild) < 1e-12
assert abs(pw - closed(63, 1)) < 1e-10 and abs(sum(vals) - tr) < 1e-12
assert abs(tr - 1 / 6) < 1e-4 and abs(hs - 1 / 90) < 2e-5 and ck[2:] == [10, 10]
assert cm[-1] > cm[0] and abs(sums[-1] - 1.25) < 0.003 and abs(math.sqrt(vn) - 2 / math.pi) < 1e-4
assert abs(float(r4) - MU1 / 4) < 0.001 and vol1 == Fr(1, 2)
print("ALL CHECKS PASS")
