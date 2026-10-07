# Quasi-Monte Carlo and the Brownian bridge -- the check behind the card.  Standard library only,
# and nothing imported that already knows an answer: the bell-curve area is a series written out
# here, its inverse is Newton's method on that series, the Sobol directions are built and their
# polynomials tested, and the pseudorandom stream is written out.  Acme: S = 100, K = 100,
# r = 5%, q = 2%, sigma = 20%, one year, a call, on a path cut into 16 steps.
from math import exp, log, pi, sqrt
S, K, R, Q, SIG, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
HOUSE = 9.227005508154                  # the shelf's Black-Scholes call price
D, WORD, MS = 16, 30, (8, 10, 12, 14, 16)
DT = T / D
POLYS = [3, 7, 11, 13, 19, 25, 37, 41, 47, 55, 59, 61, 67, 91, 97]   # x+1, x^2+x+1, x^3+x+1, ...
def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)          # bell-curve height at x
def ncdf(x):                            # area under the bell curve to the left of x
    z, term, tot, n = abs(x) / sqrt(2.0), 1.0, 1.0, 0
    while term > 1e-17 * tot:           # every term positive, so nothing cancels
        n, term = n + 1, term * 2.0 * z * z / (2 * n + 3)
        tot += term
    a = 2.0 * z * exp(-z * z) * tot / sqrt(pi)
    return 0.5 * (1.0 + a) if x >= 0.0 else 0.5 * (1.0 - a)
GN = 480                                # a coarse table of that area, to start Newton off
GP = [ncdf(-6.0 + 12.0 * i / GN) for i in range(GN + 1)]
def ninv(u):                            # the inverse: read the table, then Newton twice
    lo, hi = 0, GN
    while hi - lo > 1:
        mid = (lo + hi) // 2
        lo, hi = (mid, hi) if GP[mid] <= u else (lo, mid)
    x = -6.0 + 12.0 * lo / GN + (u - GP[lo]) * (12.0 / GN) / (GP[hi] - GP[lo])
    for _ in range(2): x -= (ncdf(x) - u) / phi(x)
    return x
def order(p):                           # multiplies by x that return to 1, in the ring
    s, x, k = p.bit_length() - 1, 1, 0
    while x != 1 or k == 0: x, k = ((x << 1) ^ p if ((x << 1) >> s) & 1 else x << 1), k + 1
    return k
def directions(poly):                   # direction integers from Sobol's recurrence
    s, v = poly.bit_length() - 1, [0] * (WORD + 1)
    for k in range(1, s + 1): v[k] = 1 << (WORD - k)     # every start 1: the simplest legal choice
    for k in range(s + 1, WORD + 1):
        v[k] = v[k - s] ^ (v[k - s] >> s)
        for i in range(1, s): v[k] ^= v[k - i] if (poly >> (s - i)) & 1 else 0
    return v
VS = [[1 << (WORD - k) if k else 0 for k in range(WORD + 1)]] + [directions(p) for p in POLYS]
def point(i, v):                        # one coordinate of Sobol point i: XOR its 1-bits
    a, j = 0, 1
    while i:
        a, i, j = (a ^ v[j] if i & 1 else a), i >> 1, j + 1
    return a
def grid(m):                            # the first 2^m points, each coordinate a whole step
    return [[point(i, v) >> (WORD - m) for v in VS] for i in range(1 << m)]
def natural(z):                         # the path in time order: each step adds one draw
    w = [sqrt(DT) * z[0]]
    for k in range(1, D): w.append(w[k - 1] + sqrt(DT) * z[k])
    return w
def bridge(z):                          # the end first, then midpoints, the gap halving
    w, j, gap = [0.0] * D + [sqrt(T) * z[0]], 1, D
    while gap > 1:
        half, a = gap // 2, 0
        while a + gap <= D:
            w[a + half] = 0.5 * (w[a] + w[a + gap]) + 0.5 * sqrt(gap * DT) * z[j]
            j, a = j + 1, a + gap
        gap = half
    return w[1:]
def acme(w): return S * exp((R - Q - 0.5 * SIG * SIG) * T + SIG * w[D - 1])   # Acme at one year
def payoff(w): return exp(-R * T) * max(acme(w) - K, 0.0)   # the discounted call payoff
def columns(build):                     # column i: the path built from draw i alone
    return [build([1.0 if j == i else 0.0 for j in range(D)]) for i in range(D)]
def cov_gap(cols):                      # the built covariance against min(t_i, t_j)
    return max(abs(sum(cols[i][k] * cols[i][l] for i in range(D)) - min(k + 1, l + 1) * DT)
               for k in range(D) for l in range(D))
def carried(cols):                      # share of the path's wiggle in the first 1, 2, 4, 8
    sq = [sum(v * v for v in c) for c in cols]
    return " ".join(f"{100.0 * sum(sq[:k]) / sum(sq):.2f}" for k in (1, 2, 4, 8))
def bs_call():                          # road one: the closed formula, own bell-curve area
    d1 = (log(S / K) + (R - Q + 0.5 * SIG * SIG) * T) / (SIG * sqrt(T))
    return S * exp(-Q * T) * ncdf(d1) - K * exp(-R * T) * ncdf(d1 - SIG * sqrt(T))
STATE = [20260919]                      # road four: pseudorandom paths, an LCG written out
def nxt():                              # one step of that stream, then one kick
    STATE[0] = (6364136223846793005 * STATE[0] + 1442695040888963407) % 2 ** 64
    return ninv(((STATE[0] >> 11) + 0.5) * 2.0 ** -53)
def row(label, value, tail=""): print(f"{label:<52}{value:>12.6f}{tail}")
exact, cn, cb = bs_call(), columns(natural), columns(bridge)
later = max(abs(cb[i][D - 1]) for i in range(1, D))
print(f"Acme: S {S:.2f}  K {K:.2f}  r 5%  q 2%  sigma 20%  T 1 year, a call on a {D}-step path")
row("road one, the closed formula", exact, f"   the shelf's house number {HOUSE:.6f}")
row("our bell-curve area at 1", ncdf(1.0), f"   known 0.841345, and the 97.5% point {ninv(0.975):.6f}")
print(f"{'primitive polynomial degrees, dimensions 2 to 16':<52}{[p.bit_length() - 1 for p in POLYS]}")
for j in (1, 2): print(f"{'direction integers m_1 to m_5, dimension ' + str(j + 1):<52}{[VS[j][k] >> (WORD - k) for k in range(1, 6)]}")
print(f"{'worst gap against min(t_i, t_j)':<52}time order {cov_gap(cn):.6f}, bridge {cov_gap(cb):.6f}")
row("the bridge's end point from draw one alone", cb[0][D - 1], f"   from every later draw {later:.6f}")
print(f"{'share of the wiggle in draws 1, 2, 4, 8, bridge':<52}{carried(cb)}")
print(f"{'the same shares in time order':<52}{carried(cn)}")
print("\nby hand, four points in bridge order: cell middle, kick, Acme at one year, payoff")
raw, z4 = 0.0, [ninv((b + 0.5) / 4.0) for b in range(4)]
for p in grid(2):
    st = acme(bridge([z4[b] for b in p]))
    raw += max(st - K, 0.0)
    print(f"   {(p[0] + 0.5) / 4.0:>10.6f} {z4[p[0]]:>11.6f} {st:>13.6f} {max(st - K, 0.0):>12.6f}")
row("   their average payoff", raw / 4.0, f"   discounted {exp(-R * T) * raw / 4.0:.6f}, error {exp(-R * T) * raw / 4.0 - exact:+.6f}")
print(f"\n{'N':>6}  {'Monte Carlo':>12}{'its error bar':>15}  {'Sobol, time order':>18}  {'Sobol, bridge':>14}")
res, perm = {}, True
for m in MS:
    n, qn, qb, sq, tot, tsq = 1 << m, 0.0, 0.0, 0.0, 0.0, 0.0
    ints = grid(m)
    perm = perm and all(sorted(p[j] for p in ints) == list(range(n)) for j in range(D))
    zs = [ninv((b + 0.5) / n) for b in range(n)]
    for p in ints:
        z = [zs[b] for b in p]
        v = payoff(bridge(z))
        qn, qb, sq = qn + payoff(natural(z)), qb + v, sq + v * v
    for _ in range(n):
        v = payoff(natural([nxt() for _ in range(D)]))
        tot, tsq = tot + v, tsq + v * v
    mc, qb = tot / n, qb / n
    bar = sqrt(max(tsq / n - mc * mc, 0.0) / (n - 1))
    fake = sqrt(max(sq / n - qb * qb, 0.0) / (n - 1))
    res[m] = (mc - exact, bar, qn / n - exact, qb - exact, fake)
    print(f"{n:>6}  {res[m][0]:>+12.6f}{bar:>15.6f}  {res[m][2]:>+18.6f}  {res[m][3]:>+14.6f}")
sl = [log(abs(res[MS[-1]][c] / res[MS[0]][c])) / log(2.0) / (MS[-1] - MS[0]) for c in (1, 2, 3)]
print(f"{'every coordinate a permutation of its own grid':<52}{'yes' if perm else 'no'}, on {len({tuple(v) for v in VS})} different direction rows")
print(f"error halvings per doubling, 256 to 65536: error bar {sl[0]:+.4f}, time order {sl[1]:+.4f}, bridge {sl[2]:+.4f}")
print(f"{'chart, log2 of the budget':<41}" + " ".join(f"{m:>6}" for m in MS))
for lab, c in (("Monte Carlo error bar", 1), ("Sobol in time order", 2), ("Sobol in bridge order", 3)):
    print(f"{'chart, log2 error, ' + lab:<41}" + " ".join(f"{log(abs(res[m][c])) / log(2.0):>6.2f}" for m in MS))
print()
row("right: Sobol in bridge order, 4,096 points", exact + res[12][3], f"   error {res[12][3]:+.6f}")
row("wrong: Sobol in time order, 4,096 points", exact + res[12][2], f"   error {res[12][2]:+.6f}, {abs(res[12][2] / res[12][3]):.0f} times the bridge's")
row("wrong: time order at 16,384 against bridge at 4,096", exact + res[14][2], f"   error {res[14][2]:+.6f}, {abs(res[14][2] / res[12][3]):.0f} times")
row("wrong: payoff scatter over root N as an error bar", res[12][4], f"   true error {res[12][3]:+.6f}")
assert all(order(p) == (1 << (p.bit_length() - 1)) - 1 for p in POLYS)   # every one primitive
assert abs(exact - HOUSE) < 1e-9                    # our own formula vs the shelf's number
assert abs(ncdf(1.0) - 0.8413447460685429) < 1e-12 and abs(ninv(0.975) - 1.959963984540054) < 1e-9
assert cov_gap(cn) < 1e-12 and cov_gap(cb) < 1e-12  # both maps rebuild min(t_i, t_j)
assert abs(cb[0][D - 1] - sqrt(T)) < 1e-15 and later < 1e-15   # the end point is one draw
assert perm and len({tuple(v) for v in VS}) == D    # stratified, and 16 different rows
assert abs(res[16][0]) < 3.0 * res[16][1]           # the random road inside three error bars
assert abs(res[12][3]) < 0.001                      # the bridge, inside a tenth of a cent
assert abs(res[12][3]) < 0.01 * abs(res[12][2])     # a hundred times closer than time order
assert abs(res[12][3]) < 0.1 * abs(res[14][2])      # beating time order at four times the budget
assert -0.55 < sl[0] < -0.45 and sl[2] < -0.9       # the two rates, measured
assert res[12][4] > 100.0 * abs(res[12][3])         # the fake error bar is not an error
print("ALL CHECKS PASS")
