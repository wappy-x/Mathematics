# Locally convex and Frechet spaces: smooth motion profiles on [0, 1] s, sized by every derivative.
# Standard library only.  Every number quoted on the card is printed here.
import math

GRID = [j / 1000 for j in range(1001)]  # 1001 sample times across [0, 1] s


def fd(f, k, t, h=1e-3):  # road 2: k-th central difference, built from samples of f alone
    return sum((-1) ** (k - j) * math.comb(k, j) * f(t + (j - k / 2) * h) for j in range(k + 1)) / h ** k


def p_fd(f, k):  # seminorm p_k(f) = max |f^(k)(t)| over the grid, derivative by differences
    return max(abs(fd(f, k, t)) for t in GRID)


def p_poly(c, k):  # road 1: differentiate integer coefficients k times, then take the grid maximum
    for _ in range(k):
        c = [i * c[i] for i in range(1, len(c))]
    return max(abs(sum(a * t ** i for i, a in enumerate(c))) for t in GRID) if c else 0.0


def dist(ps):  # the Frechet metric from a list of seminorm values p_0, p_1, ...
    return sum(2.0 ** -k * min(1.0, x) for k, x in enumerate(ps))


def cheb(N):  # finite rehearsal: integer coefficients of T_N(2t - 1), from T_(k+1) = 2(2t - 1) T_k - T_(k-1)
    a, b = [1], [-1, 2]
    for _ in range(N - 1):
        a, b = b, [4 * x - 2 * y - z for x, y, z in zip([0] + b, b + [0], a + [0, 0])]
    return b


print("smooth functions on [0, 1]: p_k(f) = max |f^(k)(t)|, d(f, g) = sum 2^-k min(1, p_k(f - g))")
print("elevator move f(t) = t^3 m, t in s")
print("   k   p_k exact   p_k from samples only")
cube = [0, 0, 0, 1]
exact = [p_poly(cube, k) for k in range(41)]
for k in range(5):
    by_fd = f"{p_fd(lambda t: t ** 3, k):22.6f}" if k < 4 else "        (not sampled)"
    print(f"{k:4d} {exact[k]:11.6f} {by_fd}")
assert exact[:5] == [1, 3, 6, 6, 0]  # the hand values
assert all(abs(p_fd(lambda t: t ** 3, k) - exact[k]) < 1e-5 for k in range(4))
assert abs(dist(exact) - 1.875) < 1e-15  # 1 + 1/2 + 1/4 + 1/8, every later term zero
print(f"d(t^3, 0) = 1 + 1/2 + 1/4 + 1/8 = {dist(exact):.6f}")
print(f"slope at the end f'(1) = {fd(lambda t: t ** 3, 1, 1.0):.6f}, bounded by p_1 = {exact[1]:.6f}")
print(f"wall f''(1) = {fd(lambda t: t ** 3, 2, 1.0):.6f}; gauge of U = max(p_0..p_3) = {max(exact[:4]):.6f}")
print("finite rehearsal, polynomials of degree <= N: T_N(2t - 1), where T_N(cos th) = cos(N th)")
print("   N  p_0(T_N)   p_1(T_N)  2N^2")
for N in (1, 3, 10):
    q0, q1 = p_poly(cheb(N), 0), p_poly(cheb(N), 1)
    assert abs(q0 - 1) < 1e-9 and abs(q1 - 2 * N * N) < 1e-9  # closed forms: |T_N| <= 1, slope 2N^2 at t = 1
    print(f"{N:4d} {q0:9.6f} {q1:10.6f} {2 * N * N:5d}")


def ripple_p(n, k):  # closed form for g_n(t) = sin(n t) / n^2 on [0, 1], n >= 2
    return float(n) ** (k - 2)


g10 = lambda t: math.sin(10 * t) / 100
print("ripple g_n(t) = sin(n t)/n^2, n = 10, seminorms from samples: "
      + ", ".join(f"p_{k} {p_fd(g10, k):.6f}" for k in range(3)))
assert all(abs(p_fd(g10, k) / ripple_p(10, k) - 1) < 1e-3 for k in range(3))
print("   n    p_0(g_n)    p_1(g_n)  p_2(g_n)  p_3(g_n)  d(g_n, 0) by 60 terms  0.5 + 1/(2n) + 1/n^2")
chart_d, chart_p0 = [], []
for n in (2, 4, 8, 10, 16, 32, 64):
    d60 = dist([ripple_p(n, k) for k in range(60)])
    closed = 0.5 + 1 / (2 * n) + 1 / n ** 2
    assert abs(d60 - closed) < 2.0 ** -58  # the truncated sum misses at most the tail 2^-59 + ...
    if n != 10:
        chart_d.append(f"{d60:.4f}")
        chart_p0.append(f"{ripple_p(n, 0):.4f}")
    print(f"{n:4d} {ripple_p(n, 0):11.6f} {ripple_p(n, 1):11.6f} {ripple_p(n, 2):9.0f} {ripple_p(n, 3):9.0f}"
          f" {d60:22.6f} {closed:21.6f}")
print(f"chart: n 2, 4, 8, 16, 32, 64")
print(f"chart: d(g_n, 0) {', '.join(chart_d)}")
print(f"chart: p_0(g_n) {', '.join(chart_p0)}")

# completeness: Taylor sums s_N of e^t are Cauchy in d and close in on e^t, which is smooth
print("Taylor sums s_N of e^t\n   N  d(s_N, e^t)  d(s_N, s_2N)")
for N in (2, 4, 8, 16):
    def gap(M, k):  # p_k(e^t - s_M): the tail of the series for e from j = M - k + 1, largest at t = 1
        rem = sum(1 / math.factorial(j) for j in range(max(0, M - k + 1), 80))
        if k <= M:  # road 2: e minus the partial sum, and Taylor's bound 1/(m+1)! <= rem <= e/(m+1)!
            assert abs(rem - (math.e - sum(1 / math.factorial(j) for j in range(M - k + 1)))) < 1e-14
            assert 1 / math.factorial(M - k + 1) <= rem <= math.e / math.factorial(M - k + 1)
        return rem
    d_lim = dist([gap(N, k) for k in range(60)])
    d_cau = dist([gap(N, k) - gap(2 * N, k) for k in range(60)])  # s_2N - s_N, all terms positive
    assert d_cau <= d_lim + 1e-15
    print(f"{N:4d} {d_lim:12.6f} {d_cau:13.6f}")
assert d_lim < 1e-4

# one norm is not enough: smoothed corners f_w(t) = sqrt((t - 1/2)^2 + w^2) are Cauchy in p_0 only
fine = [j / 200000 for j in range(200001)]
slope = lambda w, t: (t - 0.5) / math.sqrt((t - 0.5) ** 2 + w * w)
lo, hi = 0.0, 5.0  # road 2 for the stuck slope gap: ternary search of u/sqrt(u^2+1/4) - u/sqrt(u^2+1)
phi = lambda u: u / math.sqrt(u * u + 0.25) - u / math.sqrt(u * u + 1)
for _ in range(200):
    a, b = lo + (hi - lo) / 3, hi - (hi - lo) / 3
    lo, hi = (a, hi) if phi(a) < phi(b) else (lo, b)
print("corner:      w  p_0(f_w - |t - 1/2|)  p_0(f_w - f_w/2)  p_1(f_w - f_w/2)")
for w in (0.1, 0.01, 0.001):
    p0_lim = max(math.sqrt((t - 0.5) ** 2 + w * w) - abs(t - 0.5) for t in fine)
    p0_cau = max(math.sqrt((t - 0.5) ** 2 + w * w) - math.sqrt((t - 0.5) ** 2 + w * w / 4) for t in fine)
    p1_cau = max(abs(slope(w, t) - slope(w / 2, t)) for t in fine)
    assert abs(p0_lim - w) < 1e-15 and abs(p0_cau - w / 2) < 1e-15 and abs(p1_cau - phi(lo)) < 1e-5
    print(f"{w:15.3f} {p0_lim:21.6f} {p0_cau:17.6f} {p1_cau:17.6f}")
assert abs(phi(lo) - (2 ** (1 / 3) - 1)) < 1e-12  # road 3: the closed form 2^(1/3) - 1, where phi'(u) = 0
print(f"  slope gap by search over u = (t - 1/2)/w: {phi(lo):.6f} at every w; closed form 2^(1/3) - 1 = {2 ** (1 / 3) - 1:.6f}")

# no norm: U(0.1, 2) = {p_0, p_1, p_2 < 0.1} holds g_n / 20 for every n, yet p_3 grows
print("U(0.1, 2) holds g_n/20: p_0..p_2 at most 0.05, p_3 = "
      + ", ".join(f"{ripple_p(n, 3) / 20:.1f}" for n in (10, 100, 1000)) + " at n = 10, 100, 1000")

# Schwartz space: the bell e^(-t^2/2) and the seminorms max |t^a f^(b)(t)|
bell = lambda t: math.exp(-t * t / 2)
wide = [-10 + j / 1000 for j in range(20001)]
s10 = max(abs(t * bell(t)) for t in wide)
s01 = max(abs(fd(bell, 1, t)) for t in wide)
s20 = max(t * t * bell(t) for t in wide)
assert abs(s10 - math.exp(-0.5)) < 1e-6 and abs(s01 - math.exp(-0.5)) < 1e-6 and abs(s20 - 2 / math.e) < 1e-6
print(f"bell: p_(1,0) = {s10:.6f}, p_(0,1) = {s01:.6f}, p_(2,0) = {s20:.6f}")
tails = [max(abs(t ** 3 / (1 + t * t)) for t in (M * j / 1000 for j in range(1001))) for M in (10, 100, 1000)]
assert all(abs(x - M ** 3 / (1 + M * M)) < 1e-9 * M for x, M in zip(tails, (10, 100, 1000)))
print("1/(1+t^2): max |t^3 f(t)| over |t| <= 10, 100, 1000: " + ", ".join(f"{x:.3f}" for x in tails))

# what breaks
print(f"no weights, e^t: sum of min(1, p_k) over K terms = {sum(min(1, math.e) for _ in range(10)):.0f} at K = 10, "
      f"{sum(min(1, math.e) for _ in range(100)):.0f} at K = 100")
e2 = [p_fd(lambda t: math.exp(2 * t), k) for k in range(4)]
assert all(abs(x / (2 ** k * math.e ** 2) - 1) < 1e-5 for k, x in enumerate(e2))
print(f"no min(1, .), e^(2t): p_k = 2^k e^2, so sum 2^-k p_k over 10 terms = {10 * math.e ** 2:.6f}")
for n in (4, 100):  # L^(1/2): size of n times the indicator of [0, 1/n), by a midpoint sum
    size = sum(math.sqrt(n) for i in range(100000) if (i + 0.5) / 100000 < 1 / n) / 100000
    assert abs(size - 1 / math.sqrt(n)) < 1e-9
    print(f"not convex, L^(1/2): 1 on [0, 1] is the average of {n} pieces of size {size:.6f}")
print("ALL CHECKS PASS")
