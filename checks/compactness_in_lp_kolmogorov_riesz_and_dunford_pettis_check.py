# Compactness in Lp -- the check behind the card.  Standard library only.
# A one-second audio clip is a function on the loop [0, 1): time in seconds, the end joined
# to the start, amplitudes illustrative.  Click f_n = n on [0, 1/n), else 0, so its L1 size
# is 1.  Tone g_n(x) = sin(2 pi n x).  Blur: average over the last eps = 0.05 s.
# Delay: (tau_h f)(x) = f(x - h), wrapping round the loop.  The code holds finitely many
# clips and grids, so it checks instances and trends; the theorems rest on the card's proofs.
# Roads: closed forms against midpoint grids lined up with every jump and corner,
# bin averages against a counting rule, and exact ramp-and-plateau shift values.
import math

def grid(f, a, b, G):                    # midpoint rule for the integral of f over [a, b]
    w = (b - a) / G
    return w * sum(f(a + (i + 0.5) * w) for i in range(G))

def click(n, height=None):
    c = float(n) if height is None else height
    return lambda x: c if x % 1.0 < 1.0 / n else 0.0

def blur_click(n, eps=0.05):             # (B f_n)(x) = (1/eps) * integral of f_n over [x - eps, x]
    def u(x):
        x %= 1.0
        return n * max(0.0, min(x, 1.0 / n) - max(x - eps, 0.0)) / eps
    return u

def l1_shift(u, h, a, b, G):
    return grid(lambda x: abs(u(x - h) - u(x)), a, b, G)

# 1. Clicks fail the shift test: ||tau_h f_n - f_n||_1 = 2 min(nh, 1).
sizes = [grid(click(n), 0, 1, 20000) for n in (10, 100, 1000, 10000)]
assert all(abs(v - 1) < 1e-9 for v in sizes)
print("clicks f_n: L1 sizes at n = 10, 100, 1000, 10000 (grid): " + ", ".join(f"{v:.4f}" for v in sizes))
print("clicks f_n: L1 distance to the shift by h (formula; a grid agrees)")
print("  h     | n=10   | n=100  | n=1000 | n=10000")
for h in (0.1, 0.01, 0.001):
    row = [2 * min(n * h, 1.0) for n in (10, 100, 1000, 10000)]
    for n, v in zip((10, 100, 1000, 10000), row):
        assert abs(v - l1_shift(click(n), h, 0, 1, 20000)) < 1e-9
    print(f"  {h:.3f} | " + " | ".join(f"{v:.4f}" for v in row))
for M in (100, 1000):
    print(f"  finite family n <= {M}: worst shift distance at h = 0.001 is {max(2 * min(n * 0.001, 1.0) for n in range(1, M + 1)):.4f}")
pairs = [(10, 20), (10, 40), (100, 200), (100, 10000)]
d = [grid(lambda x, n=n, m=m: abs(click(n)(x) - click(m)(x)), 0, 1, 20000) for n, m in pairs]
for (n, m), v in zip(pairs, d):
    assert abs(v - 2 * (1 - n / m)) < 1e-9
print("  ||f_n - f_m||_1 for (n, m) = " + ", ".join(f"({n}, {m}) {v:.4f}" for (n, m), v in zip(pairs, d)))

# 2. The finite rehearsal: average each click over N equal bins (an N-sample clip).
def binned_gap(n, N):                    # || P_N f_n - P_N f_2n ||_1 = sum over bins of |mass difference|
    tot = 0.0
    for j in range(N):
        lo, hi = j / N, (j + 1) / N
        tot += abs(n * max(0.0, min(hi, 1 / n) - lo) - 2 * n * max(0.0, min(hi, 1 / (2 * n)) - lo))
    return tot
print("N-sample clips: ||P_N f_n - P_N f_2n||_1")
print("  n      | N=10   | N=100  | N=1000 | no bins")
for n in (1, 3, 10, 100, 1000):
    row = [binned_gap(n, N) for N in (10, 100, 1000)]
    for N, v in zip((10, 100, 1000), row):     # 0 from n = N on; 1 when bin edges meet both ends
        want = 0.0 if n >= N else 1.0 if N % (2 * n) == 0 else None
        assert 0 < v < 1 if want is None else abs(v - want) < 1e-9
    nob = grid(lambda x, a=click(n), b=click(2 * n): abs(a(x) - b(x)), 0, 1, 60000)   # no bins
    assert abs(nob - 2 * (1 - n / (2 * n))) < 1e-9
    print(f"  n={n:<5d}| " + " | ".join(f"{v:.4f}" for v in row) + f" | {nob:.4f}")

# 3. Clicks are not uniformly integrable, so no subsequence converges weakly in L1.
tail = lambda n, K: grid(lambda x, c=click(n): c(x) if c(x) > K else 0.0, 0, 1, 20000)   # area above K
tails = [max(tail(n, K) for n in (K // 2, K, 2 * K, 10 * K)) for K in (10, 100, 1000)]
for K, t in zip((10, 100, 1000), tails):          # rule: click n keeps area 1 above K exactly when n > K
    assert abs(t - max(1.0 if n > K else 0.0 for n in range(1, 10 * K + 1))) < 1e-9 and abs(tail(K, K)) < 1e-9
print("  worst tail sup_n of the integral of f_n where f_n > K, at K = 10, 100, 1000: " + ", ".join(f"{t:.4f}" for t in tails))
first = [min(1.0, n * 0.001) for n in (10, 100, 1000, 10000)]
for n, v in zip((10, 100, 1000, 10000), first):
    assert abs(v - grid(click(n), 0, 0.001, 1000)) < 1e-9
print("  reading on the first millisecond, n = 10, 100, 1000, 10000: " + ", ".join(f"{v:.4f}" for v in first))

# 4. Tones g_n: bounded by 1, so uniformly integrable; weakly to 0; still not compact.
tone = lambda n: (lambda x: math.sin(2 * math.pi * n * x))
for n in (1, 10, 100):
    sz = math.sqrt(grid(lambda x: tone(n)(x) ** 2, 0, 1, 4000))
    sh = math.sqrt(grid(lambda x: (tone(n)(x - 1 / (2 * n)) - tone(n)(x)) ** 2, 0, 1, 4000))
    pr = math.sqrt(grid(lambda x: (tone(n)(x) - tone(2 * n)(x)) ** 2, 0, 1, 4000))
    sh1 = grid(lambda x: abs(tone(n)(x - 1 / (2 * n)) - tone(n)(x)), 0, 1, 200000)
    assert abs(sz - 1 / math.sqrt(2)) < 1e-9 and abs(sh - math.sqrt(2)) < 1e-9 and abs(pr - 1) < 1e-9 and abs(sh1 - 4 / math.pi) < 1e-6
    print(f"  tone n={n:<3d}: ||g_n||_2 {sz:.4f}; shift by 1/(2n): L2 {sh:.4f}, L1 {sh1:.4f}; ||g_n - g_2n||_2 {pr:.4f}")
F = lambda x: -math.cos(4 * math.pi * x) / (4 * math.pi) + math.cos(2 * math.pi * x) / (2 * math.pi)
cuts = [0, 1 / 6, 1 / 2, 5 / 6, 1]
gap1 = sum(abs(F(b) - F(a)) for a, b in zip(cuts, cuts[1:]))
for n in (1, 10):
    assert abs(gap1 - grid(lambda x: abs(tone(n)(x) - tone(2 * n)(x)), 0, 1, 200000)) < 1e-6
print(f"  ||g_n - g_2n||_1 = {gap1:.4f} at every n (antiderivative and grid)")
reads = []
for n in (1, 2, 3, 11, 101, 1001):
    r = (1 - math.cos(math.pi * n / 2)) / (2 * math.pi * n)
    assert abs(r - grid(tone(n), 0, 0.25, 200000)) < 1e-8
    reads.append(r)
print("  tone reading on the first quarter second, n = 1, 2, 3, 11, 101, 1001: " + ", ".join(f"{r:.6f}" for r in reads))

# 5. Blurred clicks pass: worst shift distance 2h/eps, and they converge to the box.
box = lambda x: 20.0 if x % 1.0 < 0.05 else 0.0
for n in (20, 100, 1000):
    v = grid(lambda x: abs(blur_click(n)(x) - box(x)), 0, 0.1, 100000)
    assert abs(v - 1 / (n * 0.05)) < 1e-9
    print(f"  blurred click n={n:<4d}: L1 distance to the box 20 on [0, 0.05) = {v:.4f}")
hs = (0.04, 0.02, 0.01, 0.005, 0.002, 0.001)
chart = [l1_shift(blur_click(10000), h, -0.05, 0.1, 150000) for h in hs]
for h, v in zip(hs, chart):
    assert abs(v - 40 * h) < 1e-6
clk = [max(2 * min(n * h, 1.0) for n in range(2, 10001)) for h in hs]          # worst over clicks 2..10^4
ton = [max(math.sqrt(2) * math.sin(math.pi * min(n * h, 0.5)) for n in range(1, 10001)) for h in hs]
for h, c, t in zip(hs, clk, ton):                # a grid at the worst member agrees
    m = math.ceil(1 / (2 * h))                   # tone m flips under the delay 1/(2m) <= h
    assert abs(c - l1_shift(click(round(1 / h)), h, 0, 1, 20000)) < 1e-9
    assert abs(t - math.sqrt(grid(lambda x: (tone(m)(x - 1 / (2 * m)) - tone(m)(x)) ** 2, 0, 1, 4000))) < 1e-9
print("chart h:            " + ", ".join(f"{h}" for h in hs))
print("  blurred, worst:   " + ", ".join(f"{v:.4f}" for v in chart))
print("  clicks, worst:    " + ", ".join(f"{v:.4f}" for v in clk))
print("  tones (L2), worst: " + ", ".join(f"{v:.4f}" for v in ton))
at01 = [l1_shift(blur_click(n), 0.01, -0.05, 0.35, 400000) for n in (5, 20, 10000)]
for n, v in zip((5, 20, 10000), at01):            # exact: ramps of width r and height H, plateau P
    r, H, P = min(0.05, 1 / n), n * min(0.05, 1 / n) / 0.05, abs(1 / n - 0.05)
    assert abs(v - (2 * H * 0.01 - H * max(0.0, 0.01 - P) ** 2 / (2 * r))) < 1e-9
print("  blurred at h = 0.01, n = 5, 20, 10000: " + ", ".join(f"{v:.4f}" for v in at01))

# 6. What breaks on the whole line: a box sliding away passes the shift test, yet never settles.
slide = lambda n: (lambda x: 1.0 if n <= x < n + 1 else 0.0)
s1 = grid(lambda x: abs(slide(3)(x - 0.01) - slide(3)(x)), 0, 10, 10000)
s2 = grid(lambda x: abs(slide(1)(x) - slide(5)(x)), 0, 10, 10000)
assert abs(s1 - 0.02) < 1e-9 and abs(s2 - 2) < 1e-9
print(f"sliding box on the line: shift by 0.01 gives {s1:.4f}; ||b_1 - b_5||_1 = {s2:.4f}")

# 7. Try changing.
v = l1_shift(blur_click(10000, 0.01), 0.001, -0.05, 0.1, 150000)
assert abs(v - 0.2) < 1e-6
print(f"try: blur over 0.01 s: worst shift distance at h = 0.001 is {v:.4f}")
sq = [2 * min(n * 0.01, 1.0) / math.sqrt(n) for n in range(1, 100001)]
best = max(range(len(sq)), key=lambda i: sq[i]) + 1
v = l1_shift(click(best, math.sqrt(best)), 0.01, 0, 1, 20000)
assert abs(v - max(sq)) < 1e-9 and abs(max(sq) - 2 * math.sqrt(0.01)) < 1e-9
print(f"try: height sqrt(n) clicks: worst shift distance at h = 0.01 is {max(sq):.4f}, at n = {best}")
print("ALL CHECKS PASS")
