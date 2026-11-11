# Saddle points and minimax -- the check behind the card.  Standard library only.
# Two pumps must deliver at least 100 L/s.  The PLANNER picks flows x = (x1, x2) in L/s to MINIMISE the
# power f0(x) = 0.02 x1^2 + 0.03 x2^2 kW.  The PRICE SETTER picks a price lam >= 0 (kW per L/s) to MAXIMISE
# the Lagrangian L(x, lam) = f0(x) + lam (100 - x1 - x2): the power, plus lam for every L/s short.
# Road 1: the saddle, where the two best replies meet.  Road 2: min-max and max-min by brute force on grids.
# Road 3: the price setter climbs q(lam) by Danskin's slope, the shortfall, until demand is met.
A, D, KWH = [0.02, 0.03], 100.0, 0.20     # kW per (L/s)^2; L/s demanded; pounds per kWh
f0 = lambda x: A[0] * x[0] ** 2 + A[1] * x[1] ** 2
L = lambda x, lam: f0(x) + lam * (D - x[0] - x[1])
reply = lambda lam: [lam / (2 * A[0]), lam / (2 * A[1])]   # planner: each pump's marginal cost = the price
q = lambda lam: L(reply(lam), lam)                           # the planner's best bill at price lam
short = lambda lam: D - sum(reply(lam))                      # L/s short when the planner replies to lam
f4 = lambda v: ", ".join(f"{u + 0.0:.4f}" for u in v)       # + 0.0 turns -0 into 0

# ---- road 1: the planner's reply, then the price that leaves no shortfall ----
print(f"problem: minimise {A[0]} x1^2 + {A[1]} x2^2 kW subject to x1 + x2 >= {D:g} L/s; tariff {KWH:.2f} pounds per kWh")
per = 1 / (2 * A[0]) + 1 / (2 * A[1])                        # L/s delivered per kW per L/s of price
lam_s = D / per
xs = reply(lam_s)
print(f"planner's reply: x1 = {1 / (2 * A[0]):.4f} lam, x2 = {1 / (2 * A[1]):.4f} lam, total {per:.4f} lam L/s")
print(f"q(lam) = {D:.4f} lam - {per / 2:.4f} lam^2; slope {D:.4f} - {per:.4f} lam = shortfall")
print(f"saddle: lam* = {D:.4f} / {per:.4f} = {lam_s:.4f} kW per L/s, x* = ({f4(xs)}) L/s")
print(f"power {A[0] * xs[0] ** 2:.4f} + {A[1] * xs[1] ** 2:.4f} = {f0(xs):.4f} kW, {KWH * f0(xs):.4f} pounds per hour")
print(f"q(lam*) = {D * lam_s:.4f} - {per / 2 * lam_s ** 2:.4f} = {q(lam_s):.4f} kW; gap {f0(xs) - q(lam_s):.4f} kW")

# ---- road 2: brute force, both orders, on grids ----
xg = [(i / 2, j / 2) for i in range(201) for j in range(201)]   # flows 0 to 100 L/s in half litres
lg = [k / 10 for k in range(51)]                                 # prices 0 to 5 kW per L/s
mm_val, mm_x = min((max(L(x, l) for l in lg), x) for x in xg)
lam_g = max(lg, key=lambda l: min(L(x, l) for x in xg))
xm_val = min(L(x, lam_g) for x in xg)
print(f"road 2, planner first (min over x of max over lam): {mm_val:.4f} kW at x = ({f4(mm_x)})")
print(f"road 2, price setter first (max over lam of min over x): {xm_val:.4f} kW at lam = {lam_g:.4f}")
up = max(L(xs, l) for l in lg) - L(xs, lam_s)
down = min(L(x, lam_s) for x in xg) - L(xs, lam_s)
print(f"saddle test on the grids: best price gain {up + 0.0:.4f} kW, best plan gain {down + 0.0:.4f} kW")
assert abs(mm_val - 120) < 1e-9 and abs(xm_val - 120) < 1e-9 and abs(lam_g - lam_s) < 1e-12
assert mm_x == (60.0, 40.0) and up < 1e-9 and down > -1e-9 and abs(f0(xs) - q(lam_s)) < 1e-9

# ---- road 3: price adjustment by Danskin's slope ----
h = 1e-4
print(f"Danskin at lam = 1: shortfall {short(1.0):.4f} L/s, central difference of q {(q(1 + h) - q(1 - h)) / (2 * h):.4f}")
assert abs((q(1 + h) - q(1 - h)) / (2 * h) - short(1.0)) < 1e-6
def adjust(alpha):                         # from lam = 0: the final price, the step count and the prices visited
    lam, k, trace = 0.0, 0, []
    while abs(short(lam)) >= 1e-9 and k < 1000:
        trace.append(lam)
        lam, k = max(0.0, lam + alpha * short(lam)), k + 1
    return lam, k, trace
alpha = 0.01
lam, k, trace = adjust(alpha)
print(f"price adjustment, step {alpha} from lam = 0, lam_k for k = 0..5:", f4(trace[:6]))
print("shortfall at those prices, L/s:", f4([short(l) for l in trace[:6]]))
print(f"error ratio {(trace[5] - lam_s) / (trace[4] - lam_s):.4f}, steps below 2 / {per:.4f} = {2 / per:.4f} converge; shortfall below 1e-9 L/s after {k} steps, lam = {lam:.4f}")
assert abs(lam - lam_s) < 1e-9 and abs((trace[5] - lam_s) / (trace[4] - lam_s) - (1 - alpha * per)) < 1e-9
print("chart, q(lam) kW at lam = 0, 0.4, ..., 4.8:", " ".join(f"{round(q(0.4 * i), 9) + 0.0:.4f}" for i in range(13)))
print(f"figure, power of T L/s split the cheap way {1 / (2 * per):.4f} T^2 kW; T 70..130 L/s, lam 1.6..3.2; saddle ({sum(xs):.4f}, {lam_s:.4f}); best reply (70, {70 / per:.4f})"
      f" to (130, {130 / per:.4f}); L = 120 on T = 100 and from (70, {lam_s - 30 / (2 * per):.4f}) to (130, {lam_s + 30 / (2 * per):.4f})")

# ---- what breaks ----
M = [[58, 95], [93, 70]]                   # penalty kick: kicker's scoring percent; rows shoot L, R; columns dive L, R
ps = [i / 600 for i in range(601)]
pure = (max(min(r) for r in M), min(max(M[0][c], M[1][c]) for c in (0, 1)))
mixed = (max(min(p * M[0][c] + (1 - p) * M[1][c] for c in (0, 1)) for p in ps),
         min(max(p * M[r][0] + (1 - p) * M[r][1] for r in (0, 1)) for p in ps))
(a, b), (c, d) = M
V = (b * c - a * d) / (b + c - a - d)
print(f"penalty {M}, plain choices only: kicker can guarantee {pure[0]:.4f}%, keeper can hold the kicker to {pure[1]:.4f}%")
print(f"penalty, mixing allowed: {mixed[0]:.4f}% and {mixed[1]:.4f}%; formula {V:.4f}%")
assert pure == (70, 93) and abs(mixed[0] - V) < 1e-9 and abs(mixed[1] - V) < 1e-9
g = [i / 100 for i in range(101)]
F = lambda x, y: (x - y) ** 2              # convex in y too: the y player is not concave
print(f"F = (x - y)^2 on [0, 1]: min over x of max over y {min(max(F(x, y) for y in g) for x in g):.4f};"
      f" max over y of min over x {max(min(F(x, y) for x in g) for y in g):.4f}")
assert min(max(F(x, y) for y in g) for x in g) == 0.25 and max(min(F(x, y) for x in g) for y in g) == 0
xc = reply(2.0)
print(f"price capped at 2: planner's reply ({f4(xc)}) L/s, {sum(xc):.4f} delivered, {short(2.0):.4f} short;"
      f" its worst bill {max(L(xc, l / 100) for l in range(201)):.4f} = q(2) {q(2.0):.4f} kW")
assert abs(max(L(xc, l / 100) for l in range(201)) - q(2.0)) < 1e-9 and short(2.0) > 16
xx = [i / 100000 - 1 for i in range(200001)]   # minimise x on [-1, 1] subject to x^2 <= 0
qq = [min(x + l * x * x for x in xx) for l in (1, 10, 100, 1000)]
print("min x subject to x^2 <= 0: p* = 0; q(lam) at lam = 1, 10, 100, 1000:", ", ".join(f"{v:.6f}" for v in qq))
assert all(abs(v + 1 / (4 * l)) < 1e-8 for v, l in zip(qq, (1, 10, 100, 1000)))
def spiral(eta):                           # F = x y: simultaneous descent in x, ascent in y, step eta, from (1, 1)
    x, y, dist = 1.0, 1.0, []
    for k in range(101):
        if k % 25 == 0: dist.append((x * x + y * y) ** 0.5)
        x, y = x - eta * y, y + eta * x
    return dist
eta = 0.1
dist = spiral(eta)
print(f"F = x y, simultaneous steps of {eta} from (1, 1): distance from the saddle at k = 0, 25, 50, 75, 100:", f4(dist))
assert abs(dist[4] / dist[0] - (1 + eta * eta) ** 50) < 1e-9

# ---- try changing ----
def saddle(a, d):                          # road 1 for other pumps or demand: price, plan, power, dual value
    pr = 1 / (2 * a[0]) + 1 / (2 * a[1])
    lt = d / pr
    xt = [lt / (2 * a[0]), lt / (2 * a[1])]
    return lt, xt, a[0] * xt[0] ** 2 + a[1] * xt[1] ** 2, d * lt - pr / 2 * lt ** 2
for at, dt in (([0.02, 0.02], D), (A, 120.0)):
    lt, xt, pt, qt = saddle(at, dt)
    print(f"try, A = {at}, D = {dt:g}: lam* = {lt:.4f}, x* = ({f4(xt)}) L/s, power {pt:.4f} kW, "
          f"{KWH * pt:.4f} pounds per hour, dual value {qt:.4f} kW")
la, ka, ta = adjust(0.04)
print(f"try, alpha = 0.04: lam_k for k = 0..3: {f4(ta[:4])}; error ratio {(ta[5] - lam_s) / (ta[4] - lam_s):.4f}; "
      f"shortfall below 1e-9 L/s after {ka} steps")
la, ka, ta = adjust(0.05)
print(f"try, alpha = 0.05: lam_k for k = 0..3: {f4(ta[:4])}; still short after {ka} steps, lam = {la:.4f}")
print(f"try, eta = 0.01: distance from the saddle at k = 0, 25, 50, 75, 100: {f4(spiral(0.01))}")
print("ALL CHECKS PASS")
