# Wiener's Tauberian theorem -- the check behind the card.  Standard library only;
# math gives exp, cos, sin, sqrt and pi.  The pulse f(t) = exp(-|t|), t in s, has
# transform 2/(1 + 4 pi^2 xi^2), xi in Hz, never 0, so sums of its shifts reach the
# 1-second gate.  The odd pulse p(t) = t exp(-t^2) has transform 0 at 0 Hz, so its sums
# never come closer than 1 V*s.  Roads: closed forms against Simpson's rule at two steps,
# exact weight sums against areas, least-squares fits checked by their normal equations
# and squared errors, and the Tauberian readings.  Every cut-off prints its tail bound.
from math import exp, cos, sin, sqrt, pi

def f(t):    return exp(-abs(t))
def p(t):    return t * exp(-t * t)
def gate(t): return 1.0 if abs(t) < 0.5 else (0.5 if abs(t) == 0.5 else 0.0)
def total(xs):                       # plain left-to-right sum, as in the Rust twin
    s = 0.0
    for x in xs: s += x
    return s
def simpson(g, a, b, n):
    h = (b - a) / n
    return (g(a) + g(b) + total((4 if i % 2 else 2) * g(a + i * h) for i in range(1, n))) * h / 3
def pieces(g, cuts, n):              # Simpson on each piece between sorted cut points
    return total(simpson(g, a, b, n) for a, b in zip(cuts, cuts[1:]))
def sq(v): return v * v

print("transforms, closed form against Simpson on [-40, 40] s (tail below 2e-17):")
for xi in [0.0, 0.5, 1.0]:
    num = 2 * simpson(lambda t: f(t) * cos(2 * pi * xi * t), 0, 40, 40000)
    print(f"  f-hat({xi:.2f} Hz) closed {2 / (1 + 4 * pi * pi * xi * xi):.6f}  Simpson {num:.6f}  1/f-hat {(1 + 4 * pi * pi * xi * xi) / 2:.6f}")
    assert abs(num - 2 / (1 + 4 * pi * pi * xi * xi)) < 1e-9
pn = -simpson(lambda t: p(t) * sin(2 * pi * 0.25 * t), -10, 10, 20000)   # imaginary part
print(f"  p-hat(0.25 Hz) closed -i {pi ** 1.5 * 0.25 * exp(-pi * pi / 16):.6f}  Simpson -i {-pn:.6f} on [-10, 10] s, tail <= e^-100 = {exp(-100):.1e}")
assert abs(-pn - pi ** 1.5 * 0.25 * exp(-pi * pi / 16)) < 1e-9
xs = [0.25 * k for k in range(9)]
print("chart xi:", " ".join(f"{x:.2f}" for x in xs))
print("chart f-hat:", " ".join(f"{2 / (1 + 4 * pi * pi * x * x):.3f}" for x in xs))
print("chart gate-hat:", " ".join(f"{round(sin(pi * x) / (pi * x) if x else 1.0, 3) + 0.0:.3f}" for x in xs))
print("chart |p-hat|:", " ".join(f"{pi ** 1.5 * x * exp(-pi * pi * x * x):.3f}" for x in xs))

def weights(N):                      # shifts at s = j h, h = 1/N: (h/2)(g_j - second difference)
    h = 1 / N
    g = lambda j: gate(j * h)
    return [(j * h, h / 2 * ((1 + 2 / h / h) * g(j) - (g(j - 1) + g(j + 1)) / h / h))
            for j in range(-N // 2 - 1, N // 2 + 2)]
def S(t, W): return total(w * f(t - s) for s, w in W)
def l1(F, cuts, n):                  # area between F and the gate; extra cuts where they cross
    out = 0.0
    for a, b in zip(cuts, cuts[1:]):
        c = gate((a + b) / 2); d = lambda t: F(t) - c
        pts = [a]
        for k in range(1, 41):
            u, v = a + (b - a) * (k - 1) / 40, a + (b - a) * k / 40
            if d(u) * d(v) < 0:
                for _ in range(60):
                    m = (u + v) / 2
                    if d(u) * d(m) <= 0: v = m
                    else: u = m
                pts.append((u + v) / 2)
        pts.append(b)
        for x0, x1 in zip(pts, pts[1:]): out += simpson(lambda t: abs(d(t)), x0, x1, n)
    return out
def cuts_of(W): return [-30.0, -10.0, -3.0] + [s for s, _ in W] + [3.0, 10.0, 30.0]    # cut off at +-30 s
def l1_gap(W, n): return l1(lambda t: S(t, W), cuts_of(W), n)

W = weights(2)
print("N = 2, h = 0.5 s: weights", " ".join(f"{s:+.1f}:{w:.6f}" for s, w in W))
print(f"  sum at 0 s {S(0, W):.6f}  at 1 s {S(1, W):.6f}  using", " ".join(f"e^-{u:.1f} {exp(-u):.6f}" for u in [0.5, 1, 1.5, 2]))
print("N | shifts | sum of weights | sum of |weights| | L1 gap to gate V*s | gap x N | area of sum | largest gap at 0.5 s -+ 1e-9 s | tail beyond +-30 s")
prev = 9.0
for N in [2, 4, 8, 16, 32, 64]:
    W = weights(N)
    e1, e2 = l1_gap(W, 200), l1_gap(W, 400)
    area = pieces(lambda t: S(t, W), cuts_of(W), 400)
    sw, sa = total(w for _, w in W), total(abs(w) for _, w in W)
    peak = max(abs(S(t, W) - gate(t)) for t in [0.5 - 1e-9, 0.5 + 1e-9])   # one instant each side
    tail = 2 * sa * exp(-(29.5 - 1 / N))                             # |S| <= sa e^-(|t| - 0.5 - 1/N)
    print(f"  {N:2d} | {len(W):2d} | {sw:.6f} | {sa:.6f} | {e2:.6f} | {e2 * N:.4f} | {area:.6f} | {peak:.6f} | {tail:.1e}")
    assert abs(e1 - e2) < 1e-7 and e2 < prev / 1.9 and 0.9 < e2 * N < 1.1 and peak >= 0.5
    assert abs(area - 2 * sw) < 1e-8 and abs(area - 1) < 1e-8     # S-hat(0) = f-hat(0) x sum
    assert tail < 1e-10
    prev = e2
ts = [round(-1.2 + 0.15 * k, 2) for k in range(17)]
print("chart t:", " ".join(f"{t:.2f}" for t in ts))
print("chart gate:", " ".join(f"{gate(t):.2f}" for t in ts))
for N in [4, 16]:
    print(f"chart sum N={N}:", " ".join(f"{round(S(t, weights(N)), 2) + 0.0:.2f}" for t in ts))

def solve(A, b):                     # Gaussian elimination with partial pivoting
    n = len(b); M = [A[i][:] + [b[i]] for i in range(n)]
    for c in range(n):
        r = max(range(c, n), key=lambda r: abs(M[r][c])); M[c], M[r] = M[r], M[c]
        for r in range(c + 1, n):
            m = M[r][c] / M[c][c]
            for k in range(c, n + 1): M[r][k] -= m * M[c][k]
    x = [0.0] * n
    for c in range(n - 1, -1, -1):
        x[c] = (M[c][n] - total(M[c][k] * x[k] for k in range(c + 1, n))) / M[c][c]
    return x
floor = 1.0                          # |gate-hat(0) - mix-hat(0)| = 1 for every mix of odd pulses
print(f"odd pulse t exp(-t^2): least-squares sums of shifts at spacing 0.5 s on [-R, R], cut at +-(R + 6) s, floor {floor:.6f} V*s")
print("R s | shifts | max |G c - rhs| | squared error: closed, Simpson | area of right half | L1 gap to gate V*s | gap / floor | tail")
for R in [1, 2, 4, 8]:
    ss = [0.5 * j for j in range(-2 * R, 2 * R + 1)]
    G = [[exp(-(a - b) * (a - b) / 2) * sqrt(pi / 2) * (1 - (a - b) * (a - b)) / 4 for b in ss] for a in ss]
    rhs = [(exp(-(0.5 + a) * (0.5 + a)) - exp(-(0.5 - a) * (0.5 - a))) / 2 for a in ss]   # area of gate x p(t - a)
    c = solve(G, rhs)
    res = max(abs(total(G[i][k] * c[k] for k in range(len(ss))) - rhs[i]) for i in range(len(ss)))
    H = lambda t: total(ci * p(t - a) for ci, a in zip(c, ss))
    half = lambda t: total(ci * p(t - a) for ci, a in zip(c, ss) if a > 0)   # one-sided: gains do not cancel
    cuts = [0.5 * k for k in range(-2 * R - 12, 2 * R + 13)]
    e2c = 1 - total(ci * r for ci, r in zip(c, rhs))                # ||gate||^2 - c.rhs, once G c = rhs
    e2s = total(simpson(lambda t: sq(H(t) - gate((a + b) / 2)), a, b, 200) for a, b in zip(cuts, cuts[1:]))
    g1, g2, ah = l1(H, cuts, 200), l1(H, cuts, 400), pieces(half, cuts, 200)
    tail = total(abs(ci) for ci in c) * exp(-36)                    # area of |H| beyond the cut
    print(f"  {R} | {len(ss):2d} | {res:.1e} | {e2c:.6f} {e2s:.6f} | {abs(ah):.6f} | {g2:.6f} | {g2 / floor:.4f} | {tail:.1e}")
    assert res < 1e-12 and abs(e2c - e2s) < 1e-9 and abs(ah) < 1e-9 and abs(g1 - g2) < 1e-7 and g2 >= floor
B = [(s, gate(s) / 128) for s, _ in weights(64)]                    # weights h g_j / 2
blur = l1_gap(B, 400)
print(f"what breaks: plain blur, no second difference, N = 64: L1 gap {blur:.6f}  limit 2(1 - 1/e) {2 * (1 - exp(-1)):.6f}  tail beyond +-30 s <= {2 * total(w for _, w in B) * exp(-(29.5 - 1 / 64)):.1e}")
assert abs(blur - 2 * (1 - exp(-1))) < 1e-3 and abs(blur - l1_gap(B, 200)) < 1e-7

y = lambda t: 1 + cos(t * t)         # steady 1 V plus a whistle rising in pitch
def read_exp(x, yy, n): return simpson(lambda s: f(s) / 2 * yy(x - s), -30, 0, n) + simpson(lambda s: f(s) / 2 * yy(x - s), 0, 30, n)
print(f"cut-offs, |y| <= 2: exp kernel at +-30 s, tail <= 2 e^-30 = {2 * exp(-30):.1e}; odd pulse at +-8 s, tail <= 2 e^-64 = {2 * exp(-64):.1e}")
print("Tauberian readings of y(t) = 1 + cos(t^2) V, each at two steps: x s | exp kernel | 1-s gate | odd pulse")
last = [1.0, 1.0]
for x in [5, 10, 20, 40]:
    r1, r2 = read_exp(x, y, 30000), read_exp(x, y, 60000)
    rg, rg2 = simpson(lambda s: y(x - s), -0.5, 0.5, 4000), simpson(lambda s: y(x - s), -0.5, 0.5, 8000)
    ro, ro2 = simpson(lambda s: p(s) * y(x - s), -8, 8, 16000), simpson(lambda s: p(s) * y(x - s), -8, 8, 32000)
    print(f"  {x:2d} | {r2:.6f} | {rg2:.6f} | {abs(ro2):.6f}")
    assert abs(r1 - r2) < 1e-8 and abs(rg - rg2) < 1e-9 and abs(ro - ro2) < 1e-9 and abs(ro2) < 1e-4
    last = [abs(r2 - 1), abs(rg2 - 1)]
assert last[0] < 1e-3 and last[1] < 0.01
hum = lambda t: 1 + cos(2 * pi * t)  # 1 V plus a 1 Hz hum: the gate's transform is 0 at 1 Hz
print("what breaks: gate as the starting kernel, y(t) = 1 + cos(2 pi t) V")
for x in [10, 10.25, 10.5]:
    rg, re = simpson(lambda s: hum(x - s), -0.5, 0.5, 4000), read_exp(x, hum, 30000)
    print(f"  x {x:5.2f} s: gate {rg:.6f}  exp kernel {re:.6f}  formula 1 + cos(2 pi x)/(1 + 4 pi^2) {1 + cos(2 * pi * x) / (1 + 4 * pi * pi):.6f}")
    assert abs(rg - 1) < 1e-9 and abs(re - 1 - cos(2 * pi * x) / (1 + 4 * pi * pi)) < 1e-9
print("ALL CHECKS PASS")
