# Residual connections and normalisation -- the check behind the card.  Standard library only.
# A synthetic 50-layer, 4-wide network: each plain layer turns its input (a random rotation,
# SplitMix64 seed 2026) and scales it by 0.9.  Three roads to the gradient that reaches layer 0:
# the closed form 0.9^50, backpropagation through the layers, and a central difference.
from math import cos, sin, tanh, sqrt, log, pi

D, L, MASK = 4, 50, (1 << 64) - 1
def splitmix(state):                     # SplitMix64: returns (new state, uniform in [0, 1))
    state = (state + 0x9E3779B97F4A7C15) & MASK; z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return state, ((z ^ (z >> 31)) >> 11) / 2.0 ** 53

def rotations(seed):                     # 50 random 4-by-4 rotations, four plane turns each
    out, s = [], seed
    for _ in range(L):
        A = [[1.0 if i == j else 0.0 for j in range(D)] for i in range(D)]
        for i, j in ((0, 1), (2, 3), (0, 2), (1, 3)):
            s, u = splitmix(s); c, t = cos(2 * pi * u), sin(2 * pi * u)
            for r in A: r[i], r[j] = c * r[i] - t * r[j], t * r[i] + c * r[j]
        out.append(A)
    return out
Q = rotations(2026)
mv = lambda A, x: [sum(A[i][j] * x[j] for j in range(D)) for i in range(D)]
mtv = lambda A, x: [sum(A[j][i] * x[j] for j in range(D)) for i in range(D)]
norm = lambda v: sqrt(sum(t * t for t in v))

def forward(x, s, a):                    # a = 0: plain layer h = s Q h; else h = h + a tanh(s Q h)
    hs = [x]
    for l in range(L):
        z = [s * t for t in mv(Q[l], x)]
        x = z if a == 0 else [x[i] + a * tanh(z[i]) for i in range(D)]
        hs.append(x)
    return hs

def backward(x, s, a):                   # loss = first entry of h_50, so its gradient is (1, 0, 0, 0)
    hs, g, sizes = forward(x, s, a), [1.0, 0.0, 0.0, 0.0], [1.0]
    for l in reversed(range(L)):
        if a == 0: g = [s * t for t in mtv(Q[l], g)]
        else:
            z = [s * t for t in mv(Q[l], hs[l])]
            side = mtv(Q[l], [a * (1 - tanh(z[i]) ** 2) * g[i] * s for i in range(D)])
            g = [g[i] + side[i] for i in range(D)]   # identity path plus side branch
        sizes.append(norm(g))
    return g, sizes

def central(x, s, a, e=1e-6):
    return [(forward([x[j] + (e if j == i else 0) for j in range(D)], s, a)[-1][0]
             - forward([x[j] - (e if j == i else 0) for j in range(D)], s, a)[-1][0]) / (2 * e)
            for i in range(D)]

X0 = [0.1, 0.2, 0.3, 0.4]
row = lambda label, *vals: print(f"{label:<42}" + "".join(f"{v + 0.0:>11.6f}" for v in vals))
row("chain: 0.9^50, 1.1^50", 0.9 ** 50, 1.1 ** 50)
row("chain: 50 ln 0.9, exp of it", 50 * log(0.9), 2.718281828459045 ** (50 * log(0.9)))
res = {}
for name, s, a in (("plain 0.9", 0.9, 0), ("residual a=0.1", 0.9, 0.1),
                   ("plain 1.1", 1.1, 0), ("residual a=1", 0.9, 1.0)):
    g, sizes = backward(X0, s, a); cd = central(X0, s, a)
    res[name] = (g, cd, sizes)
    row(f"{name}: backprop |g0|, central |g0|", norm(g), norm(cd))
row("residual a=0.1: bounds 0.91^50, 1.09^50", 0.91 ** 50, 1.09 ** 50)
print("chart, layers back: plain 0.9 | residual a=0.1")
for k in range(0, L + 1, 5):
    row(f"  {k} layers back", res["plain 0.9"][2][k], res["residual a=0.1"][2][k])

def layer_norm(x, eps=0.0, n_minus_1=False):
    d = len(x); mu = sum(x) / d
    var = sum((t - mu) ** 2 for t in x) / (d - 1 if n_minus_1 else d)
    return [(t - mu) / sqrt(var + eps) for t in x], mu, var

def batch_norm(batch, eps=0.0):          # each feature (column) normalised over the batch
    cols = [layer_norm([ex[f] for ex in batch], eps)[0] for f in range(len(batch[0]))]
    return [[cols[f][b] for f in range(len(cols))] for b in range(len(batch))]

x = [1.0, 2.0, 3.0, 4.0]
y, mu, var = layer_norm(x)
row("layer norm: mean, variance, sd", mu, var, sqrt(var))
row("layer norm of (1, 2, 3, 4)", *y)
row("  with eps = 1e-5", *layer_norm(x, 1e-5)[0])
row("  output mean, output variance", sum(y) / 4, sum(t * t for t in y) / 4)
big = [117.390853 * t for t in x]
row("layer norm of 117.39 x (1, 2, 3, 4)", *layer_norm(big)[0])
J = [[(float(i == j) - 0.25 - y[i] * y[j] / 4) / sqrt(var) for j in range(D)] for i in range(D)]
Jcd = [(layer_norm([x[j] + (1e-6 if j == k else 0) for j in range(D)])[0][0]
        - layer_norm([x[j] - (1e-6 if j == k else 0) for j in range(D)])[0][0]) / 2e-6 for k in range(D)]
row("LN slopes of y1: formula", *J[0])
row("LN slopes of y1: central difference", *Jcd)
Jbig = [(float(0 == j) - 0.25 - y[0] * y[j] / 4) / sqrt(layer_norm(big)[2]) for j in range(D)]
row("LN slopes of y1, input x 117.39", *Jbig)
frac = norm(J[0]) / norm(x) / (norm(Jbig) / norm(big))   # a step's size over the input's size, scale 1 over scale 117.39
row("  step fraction ratio, 1 vs 117.39", frac)
batch = [[1.0, 2.0, 3.0, 4.0], [2.0, 4.0, 6.0, 8.0], [3.0, 0.0, 3.0, 0.0]]
bn = batch_norm(batch)
row("batch norm, image A in batch A B C", *bn[0])
bn2 = batch_norm([batch[0], batch[1], [9.0, 9.0, 9.0, 9.0]])
row("batch norm, image A, C now (9,9,9,9)", *bn2[0])
row("layer norm, image B = 2 x image A", *layer_norm(batch[1])[0])
row("wrong: batch norm, batch of one", *batch_norm([x], 1e-5)[0])
wrong = layer_norm(x, n_minus_1=True)[0]
row("wrong: divide by d - 1", *wrong)
row("  its output variance", sum(t * t for t in wrong) / 4)
flat = [5.0, 5.0, 5.0, 5.0]
row("flat (5,5,5,5) with eps = 1e-5", *layer_norm(flat, 1e-5)[0])
print("flat (5,5,5,5) with eps = 0: variance 0, division by zero")

gp, cp, sp = res["plain 0.9"]; gr, cr, sr = res["residual a=0.1"]
assert abs(norm(gp) - 0.9 ** 50) < 1e-12, "plain net: backprop against the closed form 0.9^50"
assert abs(norm(res["plain 1.1"][0]) - 1.1 ** 50) < 1e-9, "plain net, 1.1: closed form 1.1^50"
for g, cd, _ in res.values():
    assert max(abs(g[i] - cd[i]) for i in range(D)) < 1e-6 * max(1.0, norm(g)), "backprop vs central"
assert 0.5 < norm(gr) < 2.0 and 0.91 ** 50 < norm(gr) < 1.09 ** 50, "residual gradient stays near 1"
assert norm(res["residual a=1"][0]) > 10, "a full-size side branch explodes"
assert max(abs(y[i] - c) for i, c in enumerate((-3 / sqrt(5), -1 / sqrt(5), 1 / sqrt(5), 3 / sqrt(5)))) < 1e-12
assert abs(sum(y)) < 1e-12 and abs(sum(t * t for t in y) / 4 - 1) < 1e-12, "LN output: mean 0, variance 1"
assert max(abs(J[0][k] - Jcd[k]) for k in range(D)) < 1e-8, "LN Jacobian formula vs central difference"
assert max(abs(a - b) for a, b in zip(layer_norm(big)[0], y)) < 1e-12, "LN ignores overall scale"
assert max(abs(Jbig[k] - J[0][k] / 117.390853) for k in range(D)) < 1e-12, "slopes shrink by the scale"
assert abs(frac - 117.390853 ** 2) < 1e-6, "a step's fraction shrinks by the scale squared"
assert max(abs(a - b) for a, b in zip(bn[0], (-sqrt(1.5), 0.0, -1 / sqrt(2), 0.0))) < 1e-12, "batch norm by hand"
assert max(abs(bn2[0][i] + 3 / sqrt((9 + (i - 2) ** 2 + (5 - i) ** 2) / 3)) for i in range(D)) < 1e-12, "C changed, by hand"
assert all(t == 0.0 for t in batch_norm([x], 1e-5)[0]), "batch of one: every output is 0"
assert abs(sum(t * t for t in wrong) / 4 - 0.75) < 1e-12, "n - 1 spread gives variance (d-1)/d"
print("ALL CHECKS PASS")
