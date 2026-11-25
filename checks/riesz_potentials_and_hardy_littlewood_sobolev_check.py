# Riesz potentials and Hardy-Littlewood-Sobolev -- the check behind the card.  Standard
# library only.  Space has n = 3 dimensions and I2 f(x) = integral of f(y) / |x - y| dy, so
# the Newtonian potential is I2 f / (4 pi).  Example: f = 1 on a ball of radius R.  Roads:
# closed-form potentials against the defining integral by midpoint sums; exact polynomial
# norms against Simpson sums; the scaling law against rescaled balls; Lieb's Gamma formula
# against the bell (1 + r^2)^(-5/2); Hedberg's near-far split against the true values.
import math
PI = math.pi
def gam(x):  # Gamma at a whole or half-whole number, from Gamma(x + 1) = x Gamma(x)
    g, y = (1.0, 1.0) if x == round(x) else (math.sqrt(PI), 0.5)
    while y < x - 1e-9:
        g, y = g * y, y + 1
    return g
def add(vals):  # plain left-to-right sum, as in the Rust twin
    t = 0.0
    for v in vals:
        t += v
    return t
def simpson(fn, a, b, m=2000):
    h = (b - a) / m
    return h / 3 * add((1 if k in (0, m) else 4 if k % 2 else 2) * fn(a + k * h) for k in range(m + 1))
def pot(r, R):  # I2 of the ball of radius R, from the shell theorem (Poisson's equation card)
    return 2 * PI / 3 * (3 * R * R - r * r) if r <= R else 4 * PI * R ** 3 / (3 * r)
def kernel(r, nodes, n=400):  # defining integral, x at distance r: sum of w(s) / |x - y|
    tot = 0.0
    for s, w in nodes:
        for j in range(n):
            c = -1 + (j + 0.5) * 2 / n
            tot += w / math.sqrt(r * r + s * s - 2 * r * s * c)
    return tot * 2 * PI * 2 / n
N0 = 400
ball = [((i + 0.5) / N0, ((i + 0.5) / N0) ** 2 / N0) for i in range(N0)]
for r in (0.0, 0.5, 1.0, 2.0):
    a, b = kernel(r, ball), pot(r, 1.0)
    print(f"ball potential I2f({r:.1f}): defining integral {a:.6f}, closed form {b:.6f}")
    assert abs(a - b) < 2e-3 * b
def exact_qq(q):  # ||I2 f||_q^q for the unit ball, q a whole number above 3, exactly
    J = add(math.comb(q, k) * 3 ** (q - k) * (-1) ** k / (2 * k + 3) for k in range(q + 1))
    return (2 * PI / 3) ** q * 4 * PI * J + (4 * PI / 3) ** q * 4 * PI / (q - 3), J
def ratio(q, R):  # ||I2 f_R||_q / ||f_R||_(6/5) by Simpson sums; outside, r = R / t
    inner = simpson(lambda r: pot(r, R) ** q * 4 * PI * r * r, 0, R)
    outer = simpson(lambda t: (4 * PI * R * R / 3) ** q * 4 * PI * R ** 3 * t ** (q - 4), 0, 1)
    return (inner + outer) ** (1 / q) / (4 * PI * R ** 3 / 3) ** (5 / 6)
q6, J6 = exact_qq(6)
nf = (4 * PI / 3) ** (5 / 6)
rb = q6 ** (1 / 6) / nf
print(f"J = {J6:.6f}; ||I2f||_6^6 = {q6:.4f}; ||I2f||_6 = {q6 ** (1 / 6):.6f}; ||f||_6/5 = {nf:.6f}")
print(f"inner part {(2 * PI / 3) ** 6 * 4 * PI * J6:.4f}, outer part {(4 * PI / 3) ** 6 * 4 * PI / 3:.4f}")
print(f"ball ratio ||I2f||_6 / ||f||_6/5 = {rb:.6f}; Newtonian u = I2f/(4 pi): {rb / (4 * PI):.6f}")
assert abs(ratio(6, 1.0) - rb) < 1e-9 * rb
for q in (4, 6, 8):
    e, row = 2 + 3 / q - 5 / 2, [ratio(q, 10 ** (k / 2 - 2)) for k in range(9)]
    print(f"chart,q={q},exponent {e:+.3f}," + ",".join(f"{v:.4f}" for v in row))
    assert abs(row[8] / row[4] - 100 ** e) < 1e-9 * row[8] / row[4]
    assert abs(row[4] - exact_qq(q)[0] ** (1 / q) / nf) < 1e-9 * row[4]
lieb = PI ** 0.5 * gam(1) / gam(2.5) * (gam(1.5) / gam(3)) ** (-2 / 3)
bell = 4 * PI / 3 * (4 / PI ** 2) ** (2 / 3)
print(f"Lieb's sharp constant {lieb:.6f}; bell ratio {bell:.6f}; ball / sharp {rb / lieb:.6f}")
assert abs(lieb - bell) < 1e-12 and rb < lieb
bn = [(math.tan(p), math.sin(p) ** 2 * math.cos(p) * PI / 2 / N0)
      for p in ((i + 0.5) * PI / 2 / N0 for i in range(N0))]
a, b = kernel(1.0, bn), 4 * PI / 3 / math.sqrt(2)
print(f"bell potential I2h(1): defining integral {a:.6f}, closed form {b:.6f}")
assert abs(a - b) < 2e-3 * b
D = simpson(lambda r: pot(r, 1.0) * 4 * PI * r * r, 0, 1)
print(f"self-energy D = {D:.6f} (32 pi^2/15 = {32 * PI ** 2 / 15:.6f}); D/||f||^2 = {D / nf ** 2:.6f}")
assert abs(D - 32 * PI ** 2 / 15) < 1e-9 and D / nf ** 2 < lieb
A, Bc = 2 * PI, (4 * PI / 3) ** (1 / 6)
print(f"Hedberg constants: A = 2 pi = {A:.6f}, B = (4 pi/3)^(1/6) = {Bc:.6f}")
def lens(d, s):  # volume shared by the unit ball and a ball of radius s, centres d apart
    if d >= 1 + s: return 0.0
    if d <= abs(1 - s): return 4 * PI / 3 * min(1.0, s) ** 3
    return PI * (1 + s - d) ** 2 * (d * d + 2 * d * (1 + s) - 3 * (1 - s) ** 2) / (12 * d)
def maxf(r, K=20000):
    if r < 1: return 1.0
    return max(lens(r, s) / (4 * PI * s ** 3 / 3) for s in (r - 1 + 2 * k / K for k in range(1, K + 1)))
for r in (0.0, 1.5, 2.0, 3.0):
    M = maxf(r)
    d = (Bc * nf / (4 * A * M)) ** 0.4
    bnd = A * d * d * M + Bc * nf / math.sqrt(d)
    scan = min(A * x * x * M + Bc * nf / math.sqrt(x) for x in (k / 1000 for k in range(1, 5000)))
    print(f"Hedberg at r = {r:.1f}: Mf {M:.6f}, delta {d:.6f}, bound {bnd:.6f}, true {pot(r, 1):.6f}, ratio {pot(r, 1) / bnd:.6f}")
    assert pot(r, 1) <= bnd <= scan + 1e-9 and scan - bnd < 1e-4
    if r == 0:
        dc = d
near, far = simpson(lambda s: 4 * PI * s * s / s, 1e-12, dc), simpson(lambda s: 4 * PI * s * s / s, dc, 1)  # shells 4 pi s^2, kernel 1/s
print(f"centre split: near {near:.6f} <= {A * dc * dc:.6f}; far {far:.6f} <= {Bc * nf / math.sqrt(dc):.6f}")
assert abs(near - A * dc * dc) < 1e-9 and far <= Bc * nf / math.sqrt(dc) and abs(near + far - pot(0, 1)) < 1e-9
g2 = simpson(lambda r: (r / 3) ** 2 * 4 * PI * r * r, 0, 1) + simpson(lambda t: 4 * PI / 9, 0, 1)
print(f"field energy ||grad u||_2^2: integral {g2:.6f}, D/(4 pi) {D / (4 * PI):.6f}")
assert abs(g2 - D / (4 * PI)) < 1e-9
tal = 1 / math.sqrt(3 * PI) * (gam(3) / gam(1.5)) ** (1 / 3)
m6 = add(math.sin(p) ** 2 * math.cos(p) ** 2 for p in ((i + 0.5) * PI / 2 / N0 for i in range(N0))) * PI / 2 / N0
m2 = add(math.sin(p) ** 4 for p in ((i + 0.5) * PI / 2 / N0 for i in range(N0))) * PI / 2 / N0
sb, sbell = q6 ** (1 / 6) / (4 * PI) / math.sqrt(g2), (4 * PI * m6) ** (1 / 6) / math.sqrt(4 * PI * m2)
print(f"Sobolev ||u||_6/||grad u||_2: ball {sb:.6f}, bell {sbell:.6f}, sharp {tal:.6f}, ball / sharp {sb / tal:.6f}")
assert sb < tal and abs(sbell - tal) < 1e-12
n5, r2 = 100000, 2.0
inn = simpson(lambda s: s / 3 * s * s * 2 * PI / (r2 * s) * math.log((r2 + s) / (r2 - s)), 1e-12, 1)
out = add(2 * PI / (3 * r2 * t) * math.log((1 + r2 * t) / abs(1 - r2 * t)) for t in ((k + 0.5) / n5 for k in range(n5))) / n5
c0 = (simpson(lambda r: 4 * PI * r / 3, 0, 1) + simpson(lambda t: 4 * PI / 3, 0, 1)) / (4 * PI)
print(f"u <= I1|grad u|/(4 pi): centre {pot(0, 1) / (4 * PI):.6f} <= {c0:.6f}; r = 2: {pot(2, 1) / (4 * PI):.6f} <= {(inn + out) / (4 * PI):.6f}")
assert abs(c0 - pot(0, 1) / (4 * PI)) < 1e-9 and pot(2, 1) / (4 * PI) < (inn + out) / (4 * PI)
c1 = simpson(lambda r: ((3 - r * r) / 2) ** 3 * 4 * PI * r * r, 0, 1)
print("p = 1, unit mass ball, ||I2f||_3 out to L = 10, 1e3, 1e6: " + ", ".join(f"{(c1 + 4 * PI * math.log(L)) ** (1 / 3):.6f}" for L in (10, 1e3, 1e6)))
for k in (2, 8, 32):
    v = k * math.log(10)
    num = 4 * PI * add(1 / (1 + (k + 0.5) * v / 10000) for k in range(10000)) * v / 10000
    print(f"p = 3/2, cut at 10^-{k}: I2f(0) = {4 * PI * math.log(1 + v):.6f} (sum {num:.6f})")
    assert abs(num - 4 * PI * math.log(1 + v)) < 1e-4
print("ALL CHECKS PASS")
