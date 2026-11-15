# Spectral theorem for bounded self-adjoint operators: the check behind the card.
# Standard library only. The code holds finite rehearsals: the fade on N samples,
# the blur on a click, the blur on N samples. Integrals and the eigen solver are written out.
import math

def close(a, b, tol, what):
    assert abs(a - b) <= tol, (what, a, b)

def sci(x):
    e = math.floor(math.log10(abs(x)))
    m = x / 10.0 ** e
    if abs(m) >= 9.9995:
        m, e = m / 10, e + 1
    return f"{m:.3f}e{e:+03d}"

def dot(xs, ys):  # a plain loop, so the additions run in the same order as in Rust
    s = 0.0
    for x, y in zip(xs, ys):
        s += x * y
    return s

def jacobi(a):  # eigenvalues, and eigenvectors as the columns of q, of a symmetric matrix
    n, a = len(a), [r[:] for r in a]
    q = [[1.0 if i == j else 0.0 for j in range(n)] for i in range(n)]
    for sweep in range(12):
        for p in range(n - 1):
            for r in range(p + 1, n):
                if abs(a[p][r]) < 1e-300:
                    continue
                th = (a[r][r] - a[p][p]) / (2 * a[p][r])
                t = (1.0 if th >= 0 else -1.0) / (abs(th) + math.sqrt(th * th + 1))
                c = 1 / math.sqrt(t * t + 1)
                s = t * c
                for m in (a, q):  # rotate columns p and r
                    for k in range(n):
                        m[k][p], m[k][r] = c * m[k][p] - s * m[k][r], s * m[k][p] + c * m[k][r]
                for k in range(n):  # rotate rows p and r of a
                    a[p][k], a[r][k] = c * a[p][k] - s * a[r][k], s * a[p][k] + c * a[r][k]
    return [a[i][i] for i in range(n)], q

blur = lambda N: [[0.5 if i == j else 0.25 if abs(i - j) == 1 else 0.0 for j in range(N)] for i in range(N)]

print("fade-in M: (M u)(t) = t u(t) on a 1 s clip; steady note u = 1, energy 1")
print("N      <u, M u>   |M u|^2    |P u|^2 (gains in [0.5, 1])   |M u|^2 - 1/3")
for N in (10, 100, 1000, 44100):
    a = b = c = 0.0
    for k in range(N):
        t = (k + 0.5) / N  # sample k sits mid-slot; each slot holds energy 1/N
        a += t / N
        b += t * t / N
        c += 1.0 / N if t >= 0.5 else 0.0
    print(f"{N:<6} {a:.6f}   {b:.6f}   {c:.6f}                      {sci(b - 1 / 3)}")
    close(b - 1 / 3, -1 / (12 * N * N), 1e-12, "midpoint error is -1/(12 N^2)")
    close(c, 0.5, 1e-9, "upper half of the gains holds half the energy")

print("no eigenvector: spike phi of width w at t = 0.5, energy 1; residual |(M - 0.5) phi|")
for w in (0.1, 0.01, 0.001):
    ts = [(k + 0.5) * w / 1000 - w / 2 for k in range(1000)]  # t - 0.5 across the spike
    r = math.sqrt(dot(ts, ts) / 1000)  # phi^2 = 1/w on the spike, slot width w/1000
    print(f"w = {w:<6} residual {sci(r)} (closed form w/(2 sqrt3) = {sci(w / (2 * math.sqrt(3)))})")
    close(r / (w / (2 * math.sqrt(3))), 1.0, 1e-5, "spike residual")
d = min(abs(k / 1000 - 1.2) for k in range(1001))
print(f"lambda = 1.2: distance to the gains [0, 1] = {d:.6f}, so |R(1.2, M)| = {1 / d:.6f}")
close(1 / d, 5.0, 1e-9, "resolvent norm outside the spectrum")

G = 60000  # midpoint grid on the frequency circle (-pi, pi); the click has flat energy 1/G per point
xi = [-math.pi + (j + 0.5) * 2 * math.pi / G for j in range(G)]
g = [math.cos(x / 2) * math.cos(x / 2) for x in xi]  # the blur's multiplier cos^2(xi/2)
print("energy by gain band   fade, steady note   blur, click (grid)   blur, click (exact)")
for lo, hi in ((0, 0.25), (0.25, 0.5), (0.5, 0.75), (0.75, 1.0)):
    grid = len([v for v in g if lo <= v < hi or v == hi == 1.0])
    exact = 2 / math.pi * (math.asin(math.sqrt(hi)) - math.asin(math.sqrt(lo)))
    print(f"[{lo:.2f}, {hi:.2f})         {hi - lo:.6f}            {grid / G:.6f}             {exact:.6f}")
    close(grid / G, exact, 1e-4, "click's spectral measure is the arcsine law")

print("blur B: (B u)_n = (u_(n-1) + 2 u_n + u_(n+1))/4 on a click; <click, B^k click>")
print("k    direct conv.   spectral integral   C(2k,k)/4^k")
for k in (1, 2, 10):
    u = [1.0]
    for _ in range(k):
        u = [0.0, 0.0] + u + [0.0, 0.0]
        u = [(u[i - 1] + 2 * u[i] + u[i + 1]) / 4 for i in range(1, len(u) - 1)]
    spec = 0.0
    for v in g:
        spec += v ** k / G
    binom = math.comb(2 * k, k) / 4 ** k
    print(f"{k:<4} {u[len(u) // 2]:.6f}       {spec:.6f}            {binom:.6f}")
    close(u[len(u) // 2], binom, 1e-12, "convolution vs binomial")
    close(spec, binom, 1e-9, "spectral integral vs binomial")

print("half-blur sqrt(B): kernel c_n = (1/2pi) int sqrt(g) cos(n xi) dxi")
c = lambda n: 2 / math.pi * (-1) ** n / (1 - 4 * n * n)
for n in range(4):
    num = dot([math.sqrt(v) / G for v in g], [math.cos(n * x) for x in xi])
    print(f"c_{n} = {num:.6f} (closed form (2/pi)(-1)^n/(1 - 4n^2) = {c(n):.6f})")
    close(num, c(n), 1e-8, "half-blur kernel")
print("K      (c*c)_0 - 1/2   (c*c)_1 - 1/4   (kernel cut to |n| <= K)")
for K in (10, 100, 1000):
    s0 = dot([c(n) for n in range(-K, K + 1)], [c(n) for n in range(-K, K + 1)])
    s1 = dot([c(n) for n in range(1 - K, K + 1)], [c(1 - n) for n in range(1 - K, K + 1)])
    print(f"{K:<6} {sci(s0 - 0.5)}      {sci(s1 - 0.25)}")
    close(s0, 0.5, 1 / K ** 3, "half-blur twice is the blur, centre")
    close(s1, 0.25, 1 / K ** 3, "half-blur twice is the blur, neighbour")

print("blur on N samples, zero past the ends: Jacobi eigenvalues against cos^2(j pi/(2(N+1)))")
for N in (8, 16, 32):
    lam, Q = jacobi(blur(N))
    exact = sorted(math.cos(j * math.pi / (2 * N + 2)) ** 2 for j in range(1, N + 1))
    close(max(abs(x - y) for x, y in zip(sorted(lam), exact)), 0.0, 1e-12, "Jacobi vs closed form")
    print(f"N = {N:<3} top {max(lam):.6f}, 1 - top {1 - max(lam):.6f}, every eigenvalue matches to 1e-12")
f = lambda h: [[dot([Q[i][k] * h(lam[k]) for k in range(N)], [Q[j][k] for k in range(N)]) for j in range(N)] for i in range(N)]
mul = lambda X, Y: [[dot(X[i], [Y[k][j] for k in range(N)]) for j in range(N)] for i in range(N)]
B, R, F2 = blur(N), f(math.sqrt), f(lambda x: x * x)
BB, RR = mul(B, B), mul(R, R)
err = max(abs(F2[i][j] - BB[i][j]) + abs(RR[i][j] - B[i][j]) for i in range(N) for j in range(N))
close(err, 0.0, 1e-12, "functions through the eigenvectors")
print(f"N = 32: Q L^2 Q^T = B B and (Q sqrt(L) Q^T)^2 = B to 1e-12; half-blur centre {R[15][15]:.6f}")

print("what breaks")
for eps in (0.1, 0.01, 0.001):
    n, top, s = 400000, math.pi - eps, 0.0
    for j in range(n):
        x = (j + 0.5) * top / n
        s += 1 / (math.cos(x / 2) ** 2) * top / n / math.pi
    exact = 2 / math.pi / math.tan(eps / 2)
    print(f"unblur 1/lambda, cut {eps} from xi = pi: {s:.2f} (closed form (2/pi)cot(eps/2) = {exact:.2f})")
    close(s / exact, 1.0, 1e-3, "unblur blows up")
T = [[0.0, 1.0], [0.0, 0.0]]  # the Jordan block: not symmetric
TtT = [[dot([T[0][i], T[1][i]], [T[0][j], T[1][j]]) for j in range(2)] for i in range(2)]  # T^T T, multiplied out
tr, det, nJ = T[0][0] + T[1][1], T[0][0] * T[1][1] - T[0][1] * T[1][0], math.sqrt(max(jacobi(TtT)[0]))
print(f"Jordan block [[0, 1], [0, 0]]: trace {tr:.1f}, det {det:.1f}, so spectrum {{0}}, but its norm is sqrt(top of T^T T) = {nJ:.6f}")
close(abs(tr) + abs(det), 0.0, 0.0, "trace 0 and det 0: both eigenvalues are 0")
close(nJ, 1.0, 1e-12, "non-symmetric norm")
print(f"blur's click with length on [0, 1] as its measure: {b:.6f}, not {dot(g, g) / G:.6f}")  # b: t^2 against length, N = 44100
close(dot(g, g) / G - b, 0.375 - 1 / 3, 1e-9, "length is not the click's measure")

print("chart: cumulative spectral measure at lambda = 0, 0.1, ..., 1")
print("fade, steady note: " + ", ".join(f"{j / 10:.3f}" for j in range(11)))
print("blur, click:       " + ", ".join(f"{2 / math.pi * math.asin(math.sqrt(j / 10)):.3f}" for j in range(11)))
print("ALL CHECKS PASS")
