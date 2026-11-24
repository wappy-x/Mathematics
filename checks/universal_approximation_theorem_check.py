# Universal approximation -- the check behind the card.  Only math is imported.
# A one-hidden-layer ReLU network with 10 units is built to equal the straight-
# line join of sin x at 11 points on [0, pi].  Roads: the network against the
# join read off piece by piece; the error measured at 10,001 points against the
# bound h^2/8 and a midpoint formula; four broken hypotheses, two of them with a
# lower bound proved by a divided difference (a sum that wipes out every
# straight line or every parabola); and a training run whose units are dead.
import math

PI = math.pi
GRID = [i * PI / 10000 for i in range(10001)]          # the 10,001 test points

def relu(z):
    return z if z > 0.0 else 0.0

def build(f, n):     # unit k computes relu(1 * x - x_k); output c + sum of a_k * unit k
    xs = [k * PI / n for k in range(n + 1)]
    ys = [f(x) for x in xs]
    s = [(ys[k + 1] - ys[k]) / (xs[k + 1] - xs[k]) for k in range(n)]
    a = [s[0]] + [s[k] - s[k - 1] for k in range(1, n)]
    return ys[0], a, xs[:n], xs, ys

def net(c, a, kinks, x):
    out = c
    for ak, bk in zip(a, kinks):
        out += ak * relu(x - bk)
    return out

def join(xs, ys, x):     # road two: find the piece, draw its chord; no network
    j = 0
    while j < len(xs) - 2 and x > xs[j + 1]:
        j += 1
    t = (x - xs[j]) / (xs[j + 1] - xs[j])
    return ys[j] + t * (ys[j + 1] - ys[j])

def max_err(f, n):
    c, a, kinks, _, _ = build(f, n)
    return max((abs(f(x) - net(c, a, kinks, x)), x) for x in GRID)

def bound(n):                                     # M h^2 / 8 with M = 1 for sin
    return (PI / n) ** 2 / 8

def ddiff(pts, f):   # |divided difference| / (sum of |weights|): a lower bound on
    w = []           # the miss of every polynomial of degree len(pts) - 2
    for i in range(len(pts)):
        p = 1.0
        for j in range(len(pts)):
            if j != i:
                p *= pts[i] - pts[j]
        w.append(1.0 / p)
    return abs(sum(wi * f(x) for wi, x in zip(w, pts))) / sum(abs(wi) for wi in w)

c, a, kinks, xs, ys = build(math.sin, 10)
gap = max(abs(net(c, a, kinks, x) - join(xs, ys, x)) for x in GRID)
err, at = max_err(math.sin, 10)
mid = math.sin(0.45 * PI) * (1 - math.cos(PI / 20))
h = PI / 10
print("sin x on [0, pi]: 10 hidden ReLU units, kinks at x_k = k*pi/10, k = 0 to 9")
print("output weights a_k:", " ".join(f"{v:.4f}" for v in a))
print("numbers in the network: 10 weights + 10 biases + 10 output weights + 1 output bias = 31")
print(f"network against the chord join, largest gap over 10,001 points below 1e-12: {'yes' if gap < 1e-12 else 'no'}")
print(f"h = pi/10 = {h:.6f}; h^2 = {h * h:.6f}; bound h^2/8 = {bound(10):.6f}")
print(f"measured max error at 10,001 points: {err:.6f} at x = {at:.4f}")
print(f"midpoint formula sin(0.45 pi)(1 - cos(pi/20)): {mid:.6f}")
print(f"measured / bound: {err / bound(10):.4f}")
print("units | max error | bound h^2/8 | error ratio to the row above")
errs = {}
for n in [5, 10, 20, 40, 80]:
    errs[n] = max_err(math.sin, n)[0]
    ratio = f"{errs[n // 2] / errs[n]:.4f}" if n // 2 in errs else "-"
    print(f"{n} | {errs[n]:.6f} | {bound(n):.6f} | {ratio}")
target = bound(10) / 2
need = PI / math.sqrt(8 * target)
n_half = 10
while bound(n_half) > target:
    n_half += 1
print(f"halve the error: target {target:.6f}; formula pi/sqrt(8 target) = {need:.2f} units, "
      f"{need / 10:.4f} times 10; bound at 14 = {bound(14):.6f}, at 15 = {bound(15):.6f}; smallest: {n_half}")
for eps in [0.01, 0.001, 0.0001]:
    n = math.ceil(PI / math.sqrt(8 * eps))
    print(f"error {eps}: units by the bound {n}; measured error {max_err(math.sin, n)[0]:.6f}")
print("grid of 10 pieces per axis:", "; ".join(f"d = {d}: {10 ** d}" for d in [1, 2, 3]) + "; d = 784: 10^784")
step = lambda x: 1.0 if x >= 1.6 else 0.0
jump = [max_err(step, n)[0] for n in [10, 20, 40, 80]]
print("break 1, a jump of 1 at x = 1.6, max error at 10, 20, 40, 80 units:", " ".join(f"{v:.3f}" for v in jump))
print(f"break 2, outside [0, pi]: network at 2 pi = {net(c, a, kinks, 2 * PI):.4f}, sin 2 pi = 0; "
      f"at 4: network {net(c, a, kinks, 4.0):.4f}, sin {math.sin(4.0):.4f}")
line_low = ddiff([0.0, PI / 2, PI], math.sin)
line_hi = max(abs(math.sin(x) - 0.5) for x in GRID)
print(f"break 3, no kink (identity units): every line misses by >= {line_low:.6f}; the constant 0.5 misses by {line_hi:.6f}")
G = 48
par_low, best = 0.0, None
for i in range(G + 1):
    for j in range(i + 1, G + 1):
        for k in range(j + 1, G + 1):
            for l in range(k + 1, G + 1):
                v = ddiff([i * PI / G, j * PI / G, k * PI / G, l * PI / G], math.sin)
                if v > par_low:
                    par_low, best = v, (i, j, k, l)
para = lambda x: 4 * x * (PI - x) / (PI * PI)
miss = max(abs(math.sin(x) - para(x)) for x in GRID)
par_hi = max(abs(math.sin(x) - (para(x) - miss / 2)) for x in GRID)
print(f"break 4, square units, any width: every parabola misses by >= {par_low:.6f} "
      f"(points {best} x pi/48); parabola through 0, pi/2, pi misses by {miss:.6f}; lowered by half: {par_hi:.6f}")
tx = [j * PI / 100 for j in range(101)]                     # 101 training points
ta, tw, tb, tc, dead = [0.5] * 10, [1.0] * 10, [-4.0] * 10, 0.0, 0.0
for _ in range(300):                                      # gradient descent, rate 0.1
    ga, gw, gb, gc = [0.0] * 10, [0.0] * 10, [0.0] * 10, 0.0
    for x in tx:
        z = [tw[k] * x + tb[k] for k in range(10)]
        d = 2 * (tc + sum(ta[k] * relu(z[k]) for k in range(10)) - math.sin(x)) / 101
        gc += d
        for k in range(10):
            on = 1.0 if z[k] > 0 else 0.0
            ga[k] += d * relu(z[k]); gw[k] += d * ta[k] * on * x; gb[k] += d * ta[k] * on
    dead = max([dead] + [abs(g) for g in ga + gw + gb])
    tc -= 0.1 * gc
    ta = [ta[k] - 0.1 * ga[k] for k in range(10)]
closed = 1 / math.tan(PI / 200) / 101                  # sum of sin(j pi/100) = cot(pi/200)
stuck = max(abs(math.sin(x) - tc) for x in GRID)
print(f"training with every kink at x = 4: largest unit gradient over 300 steps {dead:.1f}; "
      f"output bias {tc:.6f}; mean of sin at the 101 points {closed:.6f}; max error {stuck:.6f}")
fit40 = lambda x: net(c, a, kinks, x) + sum(relu(x - xs[j]) - 2 * relu(x - xs[j] - h / 2) + relu(x - xs[j + 1]) for j in range(10)) * 2 / h
memo, wild = (max(abs(fit40(x) - math.sin(x)) for x in pts) for pts in (xs, GRID))   # 30 more units: a tent on each piece
print(f"generalisation, 10 units + 30 tent units: error at the 11 samples below 1e-12: {'yes' if memo < 1e-12 else 'no'}; "
      f"max error at 10,001 points {wild:.6f}")
fig = [abs(math.sin(i * PI / 40) - net(c, a, kinks, i * PI / 40)) for i in range(41)]
print("figure, error at x = i*pi/40, i = 0 to 40:", " ".join(f"{v:.4f}" for v in fig))
assert gap < 1e-12                                     # network = chord join
assert 0.98 * bound(10) < err <= bound(10)             # bound holds and is nearly tight
assert abs(err - mid) < 1e-6                           # scan agrees with the formula
assert all(3.9 < errs[n // 2] / errs[n] < 4.1 for n in [10, 20, 40, 80])
assert n_half == 15 and abs(need / 10 - math.sqrt(2)) < 1e-9
assert min(jump) >= 0.5                                # continuity: no width helps
assert abs(line_low - 0.5) < 1e-12 and abs(line_hi - 0.5) < 1e-12
assert par_low <= par_hi < par_low + 1e-4 and par_low > 2 * bound(10)
assert dead == 0.0 and abs(tc - closed) < 1e-12 and abs(stuck - closed) < 1e-12
assert memo < 1e-12 and abs(wild - (1 - math.sin(PI / 20) * (1 - math.cos(PI / 20)))) < 1e-9   # tent 1 minus the smallest midpoint gap
print("ALL CHECKS PASS")
