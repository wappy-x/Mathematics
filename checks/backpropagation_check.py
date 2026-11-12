# Backpropagation -- the check behind the card.  Standard library only.
# A 2-3-1 network (2 inputs, 3 tanh hidden units, 1 output) on one synthetic order.
# Three roads to the gradient: backprop (reverse), forward mode (a derivative carried
# alongside every value), and central differences.  Every multiply outside act() is counted.
from math import tanh

COUNT = [0]
def mul(a, b):                       # every multiply outside act() goes through here, counted
    COUNT[0] += 1
    return a * b

def act(z, kind):                    # squashing function and its slope: one step, not counted
    if kind == "tanh":
        t = tanh(z); return t, 1.0 - t * t
    return (z, 1.0) if z > 0 else (0.0, 0.0)          # ReLU; slope at the kink taken as 0

def unpack(p, n, H):                 # parameter list -> W1 (H rows of n), b1, W2, b2
    W1 = [p[j * n:(j + 1) * n] for j in range(H)]
    return W1, p[H * n:H * n + H], p[H * n + H:H * n + 2 * H], p[-1]

def forward(p, x, y, n, H, kind="tanh"):
    W1, b1, W2, b2 = unpack(p, n, H)
    z = [b1[j] + sum(mul(W1[j][i], x[i]) for i in range(n)) for j in range(H)]
    h = [act(zj, kind)[0] for zj in z]
    yhat = b2 + sum(mul(W2[j], h[j]) for j in range(H))
    return z, h, yhat, mul(0.5, mul(yhat - y, yhat - y))

def backward(p, x, y, n, H, kind="tanh", slip=None):
    W1, b1, W2, b2 = unpack(p, n, H)
    z, h, yhat, loss = forward(p, x, y, n, H, kind)
    start = COUNT[0]
    d_out = yhat - y                                   # dloss/dyhat for loss = (yhat - y)^2 / 2
    gW2 = [mul(d_out, h[j]) for j in range(H)]
    d_h = []
    for j in range(H):
        slope = act(z[j], kind)[1]
        if slip == "no slope":   slope = 1.0           # mistake: skip the activation's slope
        if slip == "slope at h": slope = act(h[j], kind)[1]   # mistake: slope read at h, not z
        d_h.append(mul(mul(W2[j], d_out), slope))
    gW1 = [mul(d_h[j], x[i]) for j in range(H) for i in range(n)]
    return gW1 + d_h + gW2 + [d_out], COUNT[0] - start, loss

def forward_mode(p, x, y, n, H, k):  # carry (value, derivative wrt parameter k) through every step
    dp = [1.0 if m == k else 0.0 for m in range(len(p))]
    W1, b1, W2, b2 = unpack(p, n, H); dW1, db1, dW2, db2 = unpack(dp, n, H)
    yhat, dyhat = b2, db2
    for j in range(H):
        z = b1[j] + sum(mul(W1[j][i], x[i]) for i in range(n))
        dz = db1[j] + sum(mul(dW1[j][i], x[i]) for i in range(n))
        t, s = act(z, "tanh")
        yhat += mul(W2[j], t); dyhat += mul(dW2[j], t) + mul(W2[j], mul(s, dz))
    return mul(yhat - y, dyhat)

def central(p, x, y, n, H, k, step=1e-5, kind="tanh"):
    up = p[:]; up[k] += step; dn = p[:]; dn[k] -= step
    return (forward(up, x, y, n, H, kind)[3] - forward(dn, x, y, n, H, kind)[3]) / (2 * step)

# ---- the order: basket £100 and 5 items in, next month's spend £120 out (units of £100, tens) ----
X, Y, N, H = [1.0, 0.5], 1.2, 2, 3
P = [0.5, -0.4, 0.3, 0.8, -0.6, 0.2,   0.1, -0.2, 0.0,   0.7, -0.5, 0.4,   0.6]
NAMES = ["w11", "w12", "w21", "w22", "w31", "w32", "b1", "b2", "b3", "v1", "v2", "v3", "c"]
z, h, yhat, loss = forward(P, X, Y, N, H)
g = backward(P, X, Y, N, H)[0]
gf = [forward_mode(P, X, Y, N, H, k) for k in range(13)]
gc = [central(P, X, Y, N, H, k) for k in range(13)]
rows = [(f"z{j+1}", z[j]) for j in range(3)] + [(f"h{j+1} = tanh(z{j+1})", h[j]) for j in range(3)]
rows += [("yhat, in hundreds of pounds", yhat), ("yhat, in pounds", 100 * yhat), ("loss (yhat - y)^2 / 2", loss), ("delta_out = yhat - y", yhat - Y)]
rows += [(f"delta_h{j+1}", g[6 + j]) for j in range(3)] + [("tanh slope 1 - h1^2", 1 - h[0] ** 2)]
print("\n".join(f"{a:<34} {v:>14.6f}" for a, v in rows))
print(f"{'param':<6}{'backprop':>16}{'forward mode':>16}{'central diff':>16}")
for k in range(13):
    print(f"{NAMES[k]:<6}{g[k]:>16.10f}{gf[k]:>16.10f}{gc[k]:>16.10f}")
worst_c = max(abs(g[k] - gc[k]) for k in range(13)); worst_f = max(abs(g[k] - gf[k]) for k in range(13))
print(f"all 13 agree with central diff to 1e-9: {'yes' if worst_c < 1e-9 else 'NO'}")
print(f"all 13 agree with forward mode to 1e-12: {'yes' if worst_f < 1e-12 else 'NO'}")

# ---- one step downhill, learning rate 0.1 ----
eta = 0.1
loss_down = forward([P[k] - eta * g[k] for k in range(13)], X, Y, N, H)[3]
loss_up = forward([P[k] + eta * g[k] for k in range(13)], X, Y, N, H)[3]
predicted = eta * sum(gk * gk for gk in g)
more = [("step: loss after", loss_down), ("step: actual drop", loss - loss_down),
        ("step: predicted drop eta*|g|^2", predicted), ("wrong sign: loss after", loss_up)]

# ---- what breaks ----
no_slope = backward(P, X, Y, N, H, slip="no slope")[0][0]
at_h = backward(P, X, Y, N, H, slip="slope at h")[0][0]
fwd_big = (forward([P[0] + 0.1] + P[1:], X, Y, N, H)[3] - loss) / 0.1
R = P[:]; R[8] = -sum(R[4 + i] * X[i] for i in range(N))   # ReLU net: unit 3 sits on its kink
R_bp = backward(R, X, Y, N, H, kind="relu")[0][4] + 0.0   # + 0.0 turns -0.0 into 0.0
R_cd = central(R, X, Y, N, H, 4, kind="relu")
R_right = (forward(R[:4] + [R[4] + 1e-6] + R[5:], X, Y, N, H, "relu")[3]
           - forward(R, X, Y, N, H, "relu")[3]) / 1e-6
more += [("wrong: no tanh slope, dL/dw11", no_slope), ("wrong: slope read at h, dL/dw11", at_h),
         ("wrong: forward diff step 0.1", fwd_big), ("relu kink z3 = 0: backprop dL/dw31", R_bp),
         ("relu kink: central diff", R_cd), ("relu kink: slope from the right", R_right)]
print("\n".join(f"{a:<34} {v:>14.6f}" for a, v in more))

# ---- cost: multiplies for one full gradient; 12 inputs = an order's 12 numbers ----
print(f"{'network':<9}{'params':>7}{'forward':>9}{'backprop':>10}{'fwd mode':>10}{'central':>10}{'ratio':>7}")
costs = {}
for nn, HH in ((2, 3), (12, 4), (12, 16), (12, 64)):
    pp = [0.01 * ((7 * m) % 11 - 5) for m in range(nn * HH + 2 * HH + 1)]
    xx = [0.1 * (i + 1) for i in range(nn)]
    COUNT[0] = 0; forward(pp, xx, 1.0, nn, HH); fc = COUNT[0]
    bc = backward(pp, xx, 1.0, nn, HH)[1]
    COUNT[0] = 0
    for k in range(len(pp)): forward_mode(pp, xx, 1.0, nn, HH, k)
    fm = COUNT[0]
    COUNT[0] = 0
    for k in range(len(pp)): central(pp, xx, 1.0, nn, HH, k)
    cc = COUNT[0]
    costs[HH] = (nn, len(pp), fc, bc, cc)
    print(f"{f'{nn}-{HH}-1':<9}{len(pp):>7}{fc:>9}{fc + bc:>10}{fm:>10}{cc:>10}{cc / (fc + bc):>7.1f}")
_, P16, f16, b16, c16 = costs[16]
print(f"20,000 orders, 12-16-1, backprop: {20000 * (f16 + b16):,} multiplies")
print(f"20,000 orders, 12-16-1, central:  {20000 * c16:,} multiplies")

assert abs(g[0] - (-0.4491751254)) < 1e-9, "the hand-worked gradient for w11"
assert worst_c < 1e-9, "backprop vs central differences, all 13 parameters"
assert worst_f < 1e-12, "backprop vs forward mode, all 13 parameters"
assert abs((loss - loss_down) - predicted) < 0.2 * predicted, "first-order drop prediction"
assert loss_up > loss > loss_down, "downhill lowers the loss, uphill raises it"
assert abs(R_cd - 0.5 * R_right) < 1e-6, "at the kink, central diff averages the two sides"
assert abs(R_bp - R_cd) > 0.1, "at the kink, backprop and central diff disagree"
for HH, (nn, PP, fc, bc, cc) in costs.items():
    assert fc == (nn + 1) * HH + 2, "counted forward multiplies vs (n + 1)H + 2"
    assert fc + bc == 2 * PP, "counted backprop multiplies vs two per parameter"
    assert cc == 2 * PP * fc, "counted central-difference multiplies vs 2 x params x forward"
print("ALL CHECKS PASS")
