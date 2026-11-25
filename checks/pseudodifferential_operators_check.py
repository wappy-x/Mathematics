# Pseudodifferential operators: a parametrix for P = -d/dx((2 + sin x) d/dx) + 1, and an L2 bound.
import math, cmath

class J:  # a function of x with its first two x-derivatives (a 2-jet), complex values
    def __init__(s, a, b=0, c=0): s.v = (complex(a), complex(b), complex(c))
    def __add__(s, o):
        o = o if isinstance(o, J) else J(o)
        return J(*(x + y for x, y in zip(s.v, o.v)))
    __radd__ = __add__
    def __mul__(s, o):
        if not isinstance(o, J): return J(*(o * x for x in s.v))
        a, b, c = s.v; d, e, f = o.v
        return J(a * d, a * e + b * d, a * f + 2 * b * e + c * d)
    __rmul__ = __mul__
    def inv(s):
        a, b, c = s.v
        return J(1 / a, -b / a ** 2, 2 * b * b / a ** 3 - c / a ** 2)

def coef(x, base):  # c = base + sin x and c' = cos x, as jets
    return J(base + math.sin(x), math.cos(x), -math.sin(x)), J(math.cos(x), -math.sin(x), -math.cos(x))

def qsym(x, k, base, terms):  # parametrix symbol q0 (+ q1), k = angular wavenumber
    c, c1 = coef(x, base)
    q0 = (k * k * c + 1).inv()
    if terms == 1: return q0
    return q0 + (-1j * k) * c1 * q0 * q0 * q0 * (k * k * c + (-1))

def err_symbol(x, k, base, terms):  # road A: composition formula p#q - 1, exact x-derivatives
    c, c1 = coef(x, base)
    q = qsym(x, k, base, terms).v
    c0, d0 = c.v[0], c1.v[0]
    return (k * k * c0 + 1 - 1j * k * d0) * q[0] - (2j * k * c0 + d0) * q[1] - c0 * q[2] - 1

def err_direct(x, k, base, terms):  # road B: apply P to w = q(x,k) e^{ikx} by finite differences
    W = lambda s: qsym(x + s, k, base, terms).v[0] * cmath.exp(1j * k * s)  # w(x+s) e^{-ikx}
    cc = lambda s: base + math.sin(x + s)
    def Pw(h):
        return -(cc(h / 2) * (W(h) - W(0)) - cc(-h / 2) * (W(0) - W(-h))) / h ** 2 + W(0)
    d = [Pw(0.02 / k / 2 ** j) for j in range(3)]  # step halved twice, then Richardson twice
    r = [(4 * d[j + 1] - d[j]) / 3 for j in range(2)]  # cancels the h^2 error
    return (16 * r[1] - r[0]) / 15 - 1  # cancels the h^4 error

XS = [2 * math.pi * j / 720 for j in range(720)]  # every half degree along one period of the rod
def maxerr(k, base, terms, road, xs=XS):
    return max(abs(road(x, k, base, terms)) for x in xs)

print("parametrix error: max over x of |(PQ - I) e^{ikx}| / |e^{ikx}|, 720 points per period")
print("k (rad/m) | Q = q0: road A, road B, k*err | Q = q0 + q1: road A, road B, k^2*err")
for k in [10, 100, 1000]:
    a0, b0 = maxerr(k, 2, 1, err_symbol), maxerr(k, 2, 1, err_direct)
    a1, b1 = maxerr(k, 2, 2, err_symbol), maxerr(k, 2, 2, err_direct)
    gap = lambda t: max(abs(err_symbol(x, k, 2, t) - err_direct(x, k, 2, t)) for x in XS)  # point by point
    assert gap(1) < 1e-6 * a0 and gap(2) < 1e-4 * a1
    print(f"{k:4d} | {a0:.10f} {b0:.10f} {k * a0:.6f} | {a1:.10f} {b1:.10f} {k * k * a1:.6f}")
lim = 1 / math.sqrt(3)
print(f"predicted limit of k*err: max of |cos x|/(2 + sin x) = 1/sqrt(3) = {lim:.6f}")
assert abs(1000 * maxerr(1000, 2, 1, err_symbol) - lim) < 1e-5
assert maxerr(1000, 2, 2, err_symbol) < maxerr(1000, 2, 1, err_symbol) / 100
assert abs(1000 ** 2 * maxerr(1000, 2, 2, err_symbol) - 1) < 1e-3  # by hand: k^2 r -> -1 at x = 3pi/2
xbad = max(XS, key=lambda x: abs(err_symbol(x, 1000, 2, 2)))
print(f"q0 + q1 at k = 1000: worst point x = {xbad / math.pi:.6f} pi")
print("chart, log10 k: log10 err(q0), log10 err(q0 + q1)")
for e in [1, 1.5, 2, 2.5, 3]:
    k = 10 ** e
    print(f"chart,{e:.1f},{math.log10(maxerr(k, 2, 1, err_symbol)):.3f},{math.log10(maxerr(k, 2, 2, err_symbol)):.3f}")

x0, k = 7 * math.pi / 6, 100  # by hand: where |cos x|/(2 + sin x) is largest
c, c1 = coef(x0, 2)
q = qsym(x0, k, 2, 1).v
terms = [-1j * k * c1.v[0] * q[0], -2j * k * c.v[0] * q[1], -c1.v[0] * q[1], -c.v[0] * q[2]]
print(f"by hand, x = 7pi/6, k = 100: c = {c.v[0].real:.6f}, c' = {c1.v[0].real:.6f}, q0 = {q[0].real:.9f}, "
      f"q0' = {q[1].real:.9f}, q0'' = {q[2].real:.9f}")
print(f"  -ikc'q0 = {terms[0].imag:+.6f}i, -2ikc q0' = {terms[1].imag:+.6f}i, "
      f"-c'q0' = {terms[2].real:+.9f}, -c q0'' = {terms[3].real:+.9f}")
naive, true = terms[0], err_symbol(x0, k, 2, 1)
lead = math.cos(x0) / ((2 + math.sin(x0)) * k)  # large-k formula i c'/(ck)
print(f"x = 7pi/6, k = 100: naive pq - 1 = {naive.imag:+.6f}i, true PQ - I = {true.imag:+.6f}i, "
      f"large-k formula {lead:+.6f}i")
assert naive.imag * true.imag < 0 and abs(true.imag - lead) < 1e-5

def adjoint_gap(x, k):  # symbol of P*: sum over a of (1/a!) d_k^a (-i d_x)^a conj(p)
    c, c1, c2 = 2 + math.sin(x), math.cos(x), -math.sin(x)
    p = k * k * c - 1j * k * c1 + 1
    pstar = (k * k * c + 1j * k * c1 + 1) + (-1j) * (2 * k * c1 + 1j * c2) + (-1) * c2
    return abs(pstar - p)
gap = max(adjoint_gap(x, 100) for x in XS)
print(f"adjoint formula, k = 100: max |p* - p| = {gap:.9f}, so P is self-adjoint")
assert gap < 1e-9

print("degenerate rod c = 1 + sin x, zero at x = 3pi/2: max err of q0 near there")
for k in [10, 100, 1000]:
    near = [1.5 * math.pi + j / (20 * k) for j in range(-200, 201)]
    print(f"  k = {k:4d}: {maxerr(k, 1, 1, err_symbol, near):.6f}")
assert maxerr(1000, 1, 1, err_symbol, [1.5 * math.pi + j / 20000 for j in range(-200, 201)]) > 0.4
alpha = (math.sqrt(5) - 1) / 2
u = lambda y: abs(y) ** alpha
h = 1e-4
res = max(abs(-((y + h / 2) ** 2 * (u(y + h) - u(y)) - (y - h / 2) ** 2 * (u(y) - u(y - h))) / h ** 2 + u(y))
          for y in [-0.5, 0.3, 0.9])  # -(x^2 u')' + u by finite differences
print(f"model -(x^2 u')' + u = 0 is solved by u = |x|^{alpha:.6f}: residual {res:.9f}")
assert res < 1e-5

def opnorm(N, sym):  # grid quantisation (Au)_j = (1/N) sum_m a(x_j, m) uhat_m e^{i m x_j}
    xs = [2 * math.pi * j / N for j in range(N)]
    ms = range(-N // 2, N // 2)
    A = [[sum(sym(xj, m) * cmath.exp(1j * m * (xj - xl)) for m in ms) / N for xl in xs] for xj in xs]
    H = [[sum(A[j][p].conjugate() * A[j][q] for j in range(N)) for q in range(N)] for p in range(N)]  # A*A
    fro = sum(abs(z) ** 2 for row in A for z in row)  # trace of A*A: every rotation keeps it
    for sweep in range(31):  # Jacobi sweeps: each rotation clears the entry (p, q) of the Hermitian A*A
        if sum(abs(H[p][q]) ** 2 for p in range(N) for q in range(N) if p != q) < 1e-24 * fro * fro: break
        assert sweep < 30, "Jacobi sweeps converge"
        for p in range(N - 1):
            for q in range(p + 1, N):
                h = abs(H[p][q])
                if h == 0: continue
                e, th = H[p][q] / h, (H[q][q].real - H[p][p].real) / (2 * h)
                t = math.copysign(1, th) / (abs(th) + math.sqrt(th * th + 1))
                c = 1 / math.sqrt(t * t + 1); s = t * c
                for k in range(N):
                    H[k][p], H[k][q] = c * H[k][p] - s * e.conjugate() * H[k][q], s * H[k][p] + c * e.conjugate() * H[k][q]
                for k in range(N):
                    H[p][k], H[q][k] = c * H[p][k] - s * e * H[q][k], s * H[p][k] + c * e * H[q][k]
    assert abs(sum(H[j][j].real for j in range(N)) - fro) < 1e-9 * fro, "rotations keep the trace"
    return math.sqrt(max(H[j][j].real for j in range(N)))  # norm = square root of the largest eigenvalue of A*A

a0 = lambda x, m: 1 + 0.5 * math.cos(x) * m / math.sqrt(1 + m * m)
a1 = lambda x, m: 1 + 0.5 * math.cos(x) * m
def bound(N, sym, M=16):  # sum over x-harmonics n of sup_m |a_n(m)|, a_n by a 16-point DFT in x
    tot = 0
    for n in range(-M // 2, M // 2):
        tot += max(abs(sum(sym(2 * math.pi * j / M, m) * cmath.exp(-2j * math.pi * n * j / M)
                           for j in range(M)) / M) for m in range(-N // 2, N // 2))
    return tot
for N in [32, 64]:
    n0, n1, b = opnorm(N, a0), opnorm(N, a1), bound(N, a0)
    print(f"N = {N:3d}: order 0 norm {n0:.6f} <= bound {b:.6f} | order 1 norm {n1:.4f}")
    assert n0 <= b + 1e-9 and n0 > 1.4
assert opnorm(64, a1) > 1.8 * opnorm(32, a1)
print("ALL CHECKS PASS")
