# The perceptron and its stack -- the check behind the card.  Standard library only.
# Every number on the card is printed here.  The orders are synthetic: eight made up
# by hand, and 1,000 drawn by SplitMix64 (seed 2026) from a stated rule.
from math import sqrt, exp

M64 = (1 << 64) - 1
def splitmix64(state):                                   # returns (new state, uniform in [0, 1))
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return state, ((z ^ (z >> 31)) >> 11) / 9007199254740992.0

def train(data, eta=1.0, max_passes=1000, strict=False, use_bias=True, log=None):
    # The perceptron rule: on a mistake, w <- w + eta*y*x and b <- b + eta*y.
    w1 = w2 = b = 0.0
    updates, per_pass = 0, []
    for p in range(max_passes):
        mistakes = 0
        for name, x1, x2, y in data:
            s = w1 * x1 + w2 * x2 + b
            if (y * s < 0) if strict else (y * s <= 0):
                w1 += eta * y * x1; w2 += eta * y * x2
                if use_bias: b += eta * y
                mistakes += 1; updates += 1
                if log is not None: log.append((updates, p + 1, name, s, w1, w2, b))
        per_pass.append(mistakes)
        if mistakes == 0: break
    return w1, w2, b, updates, per_pass

def correct(data, w1, w2, b):                             # fraud if the score is above 0
    return sum(1 for _, x1, x2, y in data if (1 if w1 * x1 + w2 * x2 + b > 0 else -1) == y)

def bound(data, u):                                       # the stopping bound: updates <= (R / gamma)^2
    n = sqrt(u[0] ** 2 + u[1] ** 2 + u[2] ** 2)
    R = max(sqrt(x1 * x1 + x2 * x2 + 1.0) for _, x1, x2, _ in data)
    g = min(y * (u[0] * x1 + u[1] * x2 + u[2]) / n for _, x1, x2, y in data)
    return R, g, (R / g) ** 2

# ---- eight orders: value in pounds, distance billing-to-delivery in km, fraud +1 / normal -1 ----
RAW = [("A", 100, 100, -1), ("B", 800, 600, 1), ("C", 700, 100, -1), ("D", 200, 600, -1),
       ("E", 500, 500, 1), ("F", 600, 400, 1), ("G", 400, 200, -1), ("H", 300, 400, -1)]
ORD = [(n, (v - 400) / 100, (d - 300) / 100, y) for n, v, d, y in RAW]   # centred on £400, 300 km
log = []
w1, w2, b, k, per_pass = train(ORD, log=log)
for u, p, name, s, a1, a2, a3 in log:
    print(f"update {u}  pass {p}  order {name}  score {s:+.0f}  ->  w = ({a1:.0f}, {a2:.0f})  b = {a3:.0f}")
print(f"mistakes per pass {per_pass}; updates {k}; right {correct(ORD, w1, w2, b)} of 8")
print("settled scores " + " ".join(f"{n} {w1 * x1 + w2 * x2 + b:+.0f}" for n, x1, x2, _ in ORD))
print(f"order A's score just after update 1: {3 * -3 + 2 * -2 - 1:+d}")
R, g, B8 = bound(ORD, (w1, w2, b))
print(f"8 orders: R = {R:.4f}  gamma = {g:.4f}  bound (R/gamma)^2 = {B8:.1f}")
print(f"8 orders, plane only (no constant 1): farthest {max(sqrt(x1 * x1 + x2 * x2) for _, x1, x2, _ in ORD):.4f}  "
      f"gap {min(y * (w1 * x1 + w2 * x2 + b) for _, x1, x2, y in ORD) / sqrt(w1 * w1 + w2 * w2):.4f}")

# ---- 1,000 synthetic orders, labelled by the rule 0.6 x1 + 0.8 x2 > 1.4, gap 0.25 kept clear ----
st, BIG = 2026, []
while len(BIG) < 1000:
    st, a = splitmix64(st); st, c = splitmix64(st)
    x1, x2 = -5.0 + 10.0 * a, -4.0 + 8.0 * c
    m = 0.6 * x1 + 0.8 * x2 - 1.4
    if abs(m) >= 0.25: BIG.append(("o", x1, x2, 1 if m > 0 else -1))
v1, v2, vb, kb, pp = train(BIG)
Rb, gb, Bb = bound(BIG, (0.6, 0.8, -1.4))
print(f"1000 orders: fraud {sum(1 for o in BIG if o[3] == 1)}  updates {kb}  passes {len(pp)}  "
      f"right {correct(BIG, v1, v2, vb)}  R = {Rb:.4f}  gamma = {gb:.4f}  bound = {Bb:.1f}")

# ---- XOR: card abroad? device abroad? fraud when exactly one is ----
XOR = [("UK card, UK device", 0, 0, -1), ("UK card, device abroad", 0, 1, 1),
       ("card abroad, UK device", 1, 0, 1), ("card abroad, device abroad", 1, 1, -1)]
xl = []
x_w1, x_w2, x_b, xk, xpp = train(XOR, max_passes=1000, log=xl)
print(f"XOR one perceptron: passes {len(xpp)}  updates {xk}  mistakes in each of the first 5 passes "
      f"{xpp[:5]}  weights after every pass ({x_w1:.0f}, {x_w2:.0f}, {x_b:.0f})")
print("XOR pass 1, weights after each update: " + "  ".join(f"({a:.0f}, {c:.0f}, {d:.0f})" for _, _, _, _, a, c, d in xl[:4]))
grid = [i / 2 for i in range(-8, 9)]                      # every line with w1, w2, b in -4 .. 4, step 0.5
best_x = max(correct(XOR, p, q, r) for p in grid for q in grid for r in grid)
best_8 = max(correct(ORD, p, q, r) for p in grid for q in grid for r in grid)
print(f"brute force over {len(grid) ** 3} lines: best on XOR {best_x} of 4, best on the 8 orders {best_8} of 8")

# ---- two layers: h = step(W1 x + b1), out = step(W2 h + b2) ----
W1, B1, W2, B2 = [[1.0, 1.0], [1.0, 1.0]], [-0.5, -1.5], [1.0, -1.0], -0.5
step = lambda s: 1.0 if s > 0 else 0.0
lam = lambda s: 1.0 / (1.0 + exp(-s))                     # the logistic squashing function
def matvec(W, x): return [sum(W[i][j] * x[j] for j in range(len(x))) for i in range(len(W))]
def net(x, f, k=1.0):
    h = [f(k * (s + c)) for s, c in zip(matvec(W1, x), B1)]
    return h, f(k * (W2[0] * h[0] + W2[1] * h[1] + B2))
xor_ok = 0
for name, x1, x2, y in XOR:
    h, o = net([x1, x2], step)
    _, ol = net([x1, x2], lam, 10.0)
    _, o1 = net([x1, x2], lam, 1.0)
    xor_ok += (o == (1.0 if x1 != x2 else 0.0))
    print(f"{name:<27} h1 {h[0]:.0f}  h2 {h[1]:.0f}  out {o:.0f}  logistic x10 {ol:.4f}  logistic x1 {o1:.4f}")
c1 = matvec([W2], [W1[0][0], W1[1][0]])[0]; c2 = matvec([W2], [W1[0][1], W1[1][1]])[0]
c0 = W2[0] * B1[0] + W2[1] * B1[1] + B2
lin_right = sum(1 for _, x1, x2, y in XOR if (1 if c1 * x1 + c2 * x2 + c0 > 0 else -1) == y)
print(f"no squashing: W2 W1 = ({c1:.0f}, {c2:.0f}), bias {c0:.1f}, every score {c0:.1f}, right {lin_right} of 4")
print(f"shop network, 12 inputs, 8 hidden, 1 out: parameters {8 * 12 + 8 + 8 + 1}")

# ---- what breaks ----
nb = train(ORD, max_passes=100, use_bias=False)
st_ = train(ORD, strict=True)
RAWU = [(n, v / 100, d / 100, y) for n, v, d, y in RAW]
rw = train(RAWU)
_, _, Br = bound(RAWU, (1.0, 1.0, -9.0))
print(f"wrong: no bias: mistakes in pass 100 {nb[4][-1]}, right {correct(ORD, nb[0], nb[1], nb[2])} of 8")
print(f"wrong: score 0 counted right: updates {st_[3]}, w = ({st_[0]:.0f}, {st_[1]:.0f}) b = {st_[2]:.0f}, right {correct(ORD, *st_[:3])} of 8")
print(f"wrong: raw units, not centred: updates {rw[3]}  passes {len(rw[4])}  bound {Br:.0f}")

# ---- try changing ----
th = train(ORD, eta=0.5); rv = train(ORD[::-1])
bad = train(ORD + [("I", -2.0, -2.0, 1)], max_passes=200)
print(f"try: eta 0.5 -> updates {th[3]}, w = ({th[0]:.1f}, {th[1]:.1f}) b = {th[2]:.1f}")
print(f"try: reversed order -> updates {rv[3]}, w = ({rv[0]:.0f}, {rv[1]:.0f}) b = {rv[2]:.0f}")
print(f"try: add fraud at £200, 100 km -> mistakes in pass 200: {bad[4][-1]}")
pts = " ".join(f"{n}({50 + 0.28 * v:.0f},{205 - 0.225 * d:.1f})" for n, v, d, _ in RAW)
print(f"figure, {pts} line ({50 + 0.28 * 100:.0f},{205 - 0.225 * 800:.1f})-({50 + 0.28 * 900:.0f},{205 - 0.225 * 0:.1f})")

assert (k, w1, w2, b) == (6, 2.0, 2.0, -4.0), "hand trace: 6 updates ending at w = (2, 2), b = -4"
assert correct(ORD, w1, w2, b) == 8 and correct(BIG, v1, v2, vb) == 1000, "settled lines get every order right"
assert abs(B8 - 26 * 24 / 4) < 1e-9, "bound by hand: R^2 = 26, gamma = 2 / sqrt(24)"
assert k <= B8 and kb <= Bb, "the stopping promise: updates never exceed (R / gamma)^2"
assert best_x == 3 and best_8 == 8, "no line gets XOR fully right; some line gets the 8 orders right"
assert xpp[-1] == 4 and len(xpp) == 1000, "one perceptron never settles on XOR"
assert xor_ok == 4 and lin_right == 2, "two layers do XOR; without squashing they collapse"
assert nb[4][-1] > 0 and rw[3] > k, "dropping the bias or the centring costs"
print("ALL CHECKS PASS")
