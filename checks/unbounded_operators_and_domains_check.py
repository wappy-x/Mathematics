# Unbounded operators and domains -- the check behind the card.  Standard library only.
# Space: H = L2(0, 1), real signals on a 1 m bar, <f, g> = integral of f*g.
# Roads: closed forms against Simpson's rule, a Sturm-count eigenvalue search on
# the grid matrix, and an explicit matrix transpose against summation by parts.
import math

PI = math.pi

def simpson(f, a, b, m):
    h = (b - a) / m
    s = f(a) + f(b)
    for k in range(1, m):
        s += (4 if k % 2 else 2) * f(a + k * h)
    return s * h / 3

def l2(f, m=200000):
    return math.sqrt(simpson(lambda x: f(x) ** 2, 0.0, 1.0, m))

def close(a, b, tol):
    assert abs(a - b) <= tol * max(1.0, abs(b)), (a, b)

# 1. Differentiation is unbounded: sin(n pi x) keeps size 1/sqrt2, its slope grows like n pi.
print("unbounded, n, size of sin(n pi x), size of its derivative, ratio, n pi")
for n in (1, 10, 100, 1000):
    a = l2(lambda x: math.sin(n * PI * x))
    b = l2(lambda x: n * PI * math.cos(n * PI * x))
    close(a, 1 / math.sqrt(2), 1e-9)
    close(b / a, n * PI, 1e-9)
    print(f"unbounded, {n}, {a:.6f}, {b:.6f}, {b / a:.6f}, {n * PI:.6f}")
u, du = l2(lambda x: 10 * math.sin(PI * x)), l2(lambda x: 10 * PI * math.cos(PI * x))
r, dr = l2(lambda x: 0.01 * math.sin(1000 * PI * x)), l2(lambda x: 10 * PI * math.cos(1000 * PI * x))
close(dr, du, 1e-9)
print(f"bar, profile 10 sin(pi x): size {u:.6f} K, gradient size {du:.6f} K/m")
print(f"bar, ripple 0.01 sin(1000 pi x): size {r:.6f} K, gradient size {dr:.6f} K/m")

# 2. The finite rehearsal: forward differences on N cells, ends held at 0.
#    D_N^T D_N = N^2 tridiag(-1, 2, -1); its eigenvalues found by Sturm counts.
def count_below(n, x):
    c, d = 0, 2.0 - x
    for k in range(n):
        if k:
            d = 2.0 - x - 1.0 / (d if d != 0 else 1e-300)
        if d < 0:
            c += 1
    return c

def kth_eig(n, k):
    lo, hi = 0.0, 4.0
    for _ in range(64):
        mid = (lo + hi) / 2
        if count_below(n, mid) >= k:
            hi = mid
        else:
            lo = mid
    return (lo + hi) / 2

print("grid, N, largest gain, closed form, largest/N, smallest gain, closed form")
chart_top, chart_bot = [], []
for N in (10, 100, 1000, 10000):
    top, bot = N * math.sqrt(kth_eig(N - 1, N - 1)), N * math.sqrt(kth_eig(N - 1, 1))
    close(top, 2 * N * math.cos(PI / (2 * N)), 1e-10)
    close(bot, 2 * N * math.sin(PI / (2 * N)), 1e-8)
    chart_top.append(f"{math.log10(top):.3f}")
    chart_bot.append(f"{math.log10(bot):.3f}")
    print(f"grid, {N}, {top:.6f}, {2 * N * math.cos(PI / (2 * N)):.6f}, {top / N:.6f}, {bot:.6f}, {2 * N * math.sin(PI / (2 * N)):.6f}")
    if N == 10:
        gain10 = top
print("chart, log10 N, 1, 2, 3, 4")
print("chart, log10 largest gain, " + ", ".join(chart_top))
print("chart, log10 smallest gain, " + ", ".join(chart_bot))

# 3. The grid adjoint: transpose the matrix entry by entry, compare with minus a backward difference.
N, h = 10, 0.1
D = [[0.0] * (N - 1) for _ in range(N)]        # row k: (f[k+1] - f[k]) / h, f[0] = f[N] = 0
for k in range(N):
    if k >= 1:
        D[k][k - 1] = -1 / h
    if k <= N - 2:
        D[k][k] = 1 / h
f = [math.sin(PI * j * h) for j in range(1, N)]
g = [(k * h + h / 2) ** 2 for k in range(N)]
Df = [sum(D[k][j] * f[j] for j in range(N - 1)) for k in range(N)]
DTg = [sum(D[k][j] * g[k] for k in range(N)) for j in range(N - 1)]
for j in range(N - 1):
    close(DTg[j], -(g[j + 1] - g[j]) / h, 1e-12)
left, right = h * sum(a * b for a, b in zip(Df, g)), h * sum(a * b for a, b in zip(f, DTg))
close(left, right, 1e-12)
print(f"grid adjoint, N = 10, <D f, g> = {left:.6f}, <f, D^T g> = {right:.6f}")

# 4. The continuous adjoint, A = d/dx with f(0) = f(1) = 0:  <f', g> = <f, -g'> for any g.
lhs = simpson(lambda x: PI * math.cos(PI * x) * x * x, 0, 1, 2000)
rhs = simpson(lambda x: -math.sin(PI * x) * 2 * x, 0, 1, 2000)
close(lhs, -2 / PI, 1e-10)
close(rhs, -2 / PI, 1e-10)
print(f"adjoint, f = sin(pi x), g = x^2: <f', g> = {lhs:.6f}, <f, -g'> = {rhs:.6f}, -2/pi = {-2 / PI:.6f}")
b1, b2 = simpson(lambda x: x * x, 0, 1, 2000), simpson(lambda x: -x * 2 * x, 0, 1, 2000)
close(b1 - b2, 1.0, 1e-10)
print(f"boundary, f = x, g = x^2: <f', g> = {b1:.6f}, <f, -g'> = {b2:.6f}, gap = {b1 - b2:.6f}, f(1)g(1) - f(0)g(0) = 1")

# 5. Is g = 1 in the adjoint's domain when A has no end conditions?  Test f_n = x^n.
print("domain test, n, size of x^n, 1/sqrt(2n+1), <f_n', 1>, ratio")
for n in (1, 10, 100, 1000):
    s = l2(lambda x: x ** n)
    p = simpson(lambda x: n * x ** (n - 1), 0, 1, 200000)
    close(s, 1 / math.sqrt(2 * n + 1), 1e-9)
    close(p, 1.0, 1e-9)
    print(f"domain test, {n}, {s:.6f}, {1 / math.sqrt(2 * n + 1):.6f}, {p:.6f}, {p / s:.6f}")

# 6. Closedness: smooth f_eps converge to the tent f(x) = 1/2 - |x - 1/2|, slopes to -sign(x - 1/2).
def tent_closed(e):
    S, q = 1 / (2 * e), math.sqrt(0.25 + e * e)
    c = q - 0.5
    iw = 0.5 * q + e * e * math.log((0.5 + q) / e) - 0.25
    iw2 = 2 * e ** 3 * (2 * S ** 3 / 3 + S - (2 / 3) * (S * S + 1) ** 1.5 + 2 / 3)
    d2 = 2 * e * (2 * S - math.atan(S) - 2 * math.sqrt(1 + S * S) + 2)
    return math.sqrt(c * c - 2 * c * iw + iw2), math.sqrt(d2)

print("closed, eps (m), size of f_eps - f, closed form, size of f_eps' - f', closed form")
for e in (0.1, 0.01, 0.001):
    a, b = tent_closed(e)
    q = math.sqrt(0.25 + e * e)
    sa = math.sqrt(2 * simpson(lambda x: (q - math.sqrt((x - .5) ** 2 + e * e) - x) ** 2, 0, .5, 20000))
    sb = math.sqrt(2 * simpson(lambda x: ((.5 - x) / math.sqrt((x - .5) ** 2 + e * e) - 1) ** 2, 0, .5, 20000))
    close(sa, a, 1e-6 * a)
    close(sb, b, 1e-6 * b)
    print(f"closed, {e}, {sa:.8f}, {a:.8f}, {sb:.6f}, {b:.6f}")
    if e == 0.001:
        slope_err = b

# 7. What breaks.
print(f"breaks, bound from the N = 10 grid: ripple gradient at most {gain10 * r:.6f} K/m, really {dr:.6f} K/m")
print(f"breaks, drop the end conditions of A only: <f', g> = {b1:.6f} but <f, -g'> = {b2:.6f}")
print(f"breaks, forget the minus sign: <f, +g'> = {-rhs:.6f}, true value {lhs:.6f}")
print(f"breaks, stay in C1: slopes f_eps' within {slope_err:.6f} of a limit that jumps from +1 to -1 at x = 0.5")
assert gain10 * r < dr / 100
print("ALL CHECKS PASS")
