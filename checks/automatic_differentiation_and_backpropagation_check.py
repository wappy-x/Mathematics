# Automatic differentiation on the Rosenbrock valley: the check behind the card.
# Standard library only.  Four roads to the gradient: forward mode (dual numbers),
# reverse mode (a tape swept backwards), the hand formula, and finite differences.
# Every arithmetic operation on a number is counted, so the costs are measured.
from math import log10

OPS = [0]                          # operations counted so far
TAPE = []                          # reverse mode: one entry per operation

class Dual:                        # a + b*eps with eps*eps = 0: a value and its tangent
    def __init__(s, a, b=0.0): s.a, s.b = a, b
    def __add__(s, o): OPS[0] += 2; return Dual(s.a + o.a, s.b + o.b)
    def __sub__(s, o): OPS[0] += 2; return Dual(s.a - o.a, s.b - o.b)
    def __mul__(s, o): OPS[0] += 4; return Dual(s.a * o.a, s.a * o.b + s.b * o.a)

class Node:                        # a value, plus its parents and local slopes on the tape
    def __init__(s, v, parents=()): s.v, s.i = v, len(TAPE); TAPE.append(parents)
    def __add__(s, o): OPS[0] += 1; return Node(s.v + o.v, ((s.i, 1.0), (o.i, 1.0)))
    def __sub__(s, o): OPS[0] += 1; return Node(s.v - o.v, ((s.i, 1.0), (o.i, -1.0)))
    def __mul__(s, o): OPS[0] += 1; return Node(s.v * o.v, ((s.i, o.v), (o.i, s.v)))

def backward(out, overwrite=False):  # the reverse sweep: adjoints, last operation first
    adj = [0.0] * len(TAPE)
    adj[out.i] = 1.0
    for k in range(len(TAPE) - 1, -1, -1):
        for p, slope in TAPE[k]:
            OPS[0] += 2
            adj[p] = adj[k] * slope if overwrite else adj[p] + adj[k] * slope
    return adj

def rosen(x, K):                   # chained Rosenbrock; K turns a constant into the number type
    f = None
    for i in range(len(x) - 1):
        s = x[i] * x[i]; d = x[i + 1] - s; c = K(1.0) - x[i]
        dd = d * d; t = K(100.0) * dd; u = c * c; term = t + u
        f = term if f is None else f + term
        if i == 0: first = (s, d, c, dd, t, u, term)
    return f, first

def hand(x):                       # the gradient written out by hand
    n = len(x); g = [0.0] * n
    for j in range(n):
        if j < n - 1: g[j] += -400.0 * x[j] * (x[j + 1] - x[j] * x[j]) - 2.0 * (1.0 - x[j])
        if j > 0: g[j] += 200.0 * (x[j] - x[j - 1] * x[j - 1])
    return g

def forward_mode(x):               # one pass per input, seeding that input's tangent with 1
    return [rosen([Dual(v, 1.0 if i == j else 0.0) for i, v in enumerate(x)], Dual)[0].b
            for j in range(len(x))]

def reverse_mode(x, overwrite=False):  # one recorded pass, one backward sweep
    TAPE.clear()
    xs = [Node(v) for v in x]
    f, first = rosen(xs, Node)
    adj = backward(f, overwrite)
    return [adj[n.i] for n in xs], first, adj

def plain(x): return rosen(x, float)[0]

# ---- the 2-D valley at the classic start (-1.2, 1), traced line by line ----
x2 = [-1.2, 1.0]
_, fx = rosen([Dual(-1.2, 1.0), Dual(1.0)], Dual)
_, fy = rosen([Dual(-1.2), Dual(1.0, 1.0)], Dual)
g_rev, first, adj = reverse_mode(x2)
print("2-D valley at (x, y) = (-1.2, 1); tangents seeded x-dot = 1")
print(f"{'line':<12}{'value':>12}{'tangent':>13}{'adjoint':>13}")
names = ["s = x*x", "d = y - s", "c = 1 - x", "dd = d*d", "t = 100*dd", "u = c*c", "f = t + u"]
for name, dv, nd in zip(names, fx, first):
    print(f"{name:<12}{dv.a:12.6f}{dv.b:13.6f}{adj[nd.i]:13.6f}")
g_hand = hand(x2)
print(f"df/dx: forward {fx[6].b:.6f}  reverse {g_rev[0]:.6f}  hand {g_hand[0]:.6f}")
print(f"df/dy: forward {fy[6].b:.6f}  reverse {g_rev[1]:.6f}  hand {g_hand[1]:.6f}")
assert abs(fx[6].b - (-215.6)) < 1e-12 and abs(fy[6].b - (-88.0)) < 1e-12
assert abs(g_rev[0] - g_hand[0]) < 1e-12 and abs(g_rev[1] - g_hand[1]) < 1e-12

# ---- finite differences: the step size has no right answer ----
def fd(h, central):
    up = plain([-1.2 + h, 1.0])
    down = plain([-1.2 - h, 1.0]) if central else plain(x2)
    return (up - down) / (2.0 * h if central else h)

hs, p = [], 1.0
for k in range(1, 15):
    p *= 10.0; hs.append(1.0 / p)
fwd_err = [log10(abs(fd(h, False) - (-215.6))) for h in hs]
cen_err = [log10(abs(fd(h, True) - (-215.6))) for h in hs]
print("chart, log10 h            " + " ".join(f"{-k:6d}" for k in range(1, 15)))
print("chart, forward, log10 err " + " ".join(f"{e:6.2f}" for e in fwd_err))
print("chart, central, log10 err " + " ".join(f"{e:6.2f}" for e in cen_err))
best_f, best_c = min(fwd_err), min(cen_err)
print(f"best forward difference error 10^{best_f:.2f} at h = 1e-{fwd_err.index(best_f) + 1}; "
      f"best central 10^{best_c:.2f} at h = 1e-{cen_err.index(best_c) + 1}")
assert fwd_err[0] > 1.0 and fwd_err[13] > -1.0 and best_f < -5.0   # too big, too small, middle

# ---- what breaks ----
bad, _, _ = reverse_mode(x2, overwrite=True)
both = rosen([Dual(-1.2, 1.0), Dual(1.0, 1.0)], Dual)[0].b
print(f"mistake, = instead of +=: df/dx {bad[0]:.6f}  df/dy {bad[1]:.6f}")
print(f"mistake, both tangents seeded at once: {both:.6f}")
print(f"mistake, forward difference h = 0.1: {fd(0.1, False):.6f}")
print(f"mistake, forward difference h = 1e-12: {fd(hs[11], False):.6f}")
assert abs(both - (g_hand[0] + g_hand[1])) < 1e-12 and abs(bad[0] - g_hand[0]) > 100.0

def sq(x): return Dual(1.0) if x.a == 1.0 else x * x    # same function, one shortcut branch
ad_kink, true_kink = sq(Dual(1.0, 1.0)).b, (Dual(1.0, 1.0) * Dual(1.0, 1.0)).b   # branch; plain x * x
fd_kink = (sq(Dual(1.0 + 1e-6)).a - sq(Dual(1.0 - 1e-6)).a) / 2e-6          # through the routine itself
print(f"branch x == 1: AD says {ad_kink:.6f}, true {true_kink:.6f}, central difference {fd_kink:.6f}")
assert ad_kink == 0.0 and abs(true_kink - 2.0) < 1e-12 and abs(fd_kink - true_kink) < 1e-6

# ---- 50 inputs: every partial, and what each road costs ----
def cost(x):                       # operations: one evaluation, forward mode, reverse mode
    TAPE.clear(); OPS[0] = 0; rosen([Node(v) for v in x], Node); L = OPS[0]
    OPS[0] = 0; g_f = forward_mode(x); c_f = OPS[0]
    OPS[0] = 0; g_r = reverse_mode(x)[0]; c_r = OPS[0]
    print(f"operations at n = {len(x)}: evaluation {L}, forward mode {c_f}, "
          f"central differences {2 * len(x) * L}, reverse mode {c_r}")
    assert L == 8 * (len(x) - 1) - 1 and c_r == 5 * L   # 7 a link, plus the joining additions
    return L, c_f, c_r, g_f, g_r

n = 50
x = [-1.2 if i % 2 == 0 else 1.0 for i in range(n)]
f50 = plain(x); g_h = hand(x); h = 1e-6
g_cd = [(plain(x[:j] + [x[j] + h] + x[j + 1:]) - plain(x[:j] + [x[j] - h] + x[j + 1:])) / (2 * h)
        for j in range(n)]
print(f"50-D valley, start (-1.2, 1, -1.2, 1, ...): f = {f50:.6f}")
cost(x2)
L, c_fwd, c_rev, g_fwd, g_r = cost(x)
print(f"at n = 50, in evaluations: forward {c_fwd / L:.1f}, central {2 * n:.1f}, reverse {c_rev / L:.1f}")
gap_fr = max(abs(a - b) for a, b in zip(g_fwd, g_r))
gap_rh = max(abs(a - b) for a, b in zip(g_r, g_h))
gap_ch = max(abs(a - b) for a, b in zip(g_cd, g_h))
print("partials 1, 2, 3, 49, 50: " + ", ".join(f"{g_r[j]:.6f}" for j in (0, 1, 2, 48, 49)))
print(f"largest gap: forward vs reverse {gap_fr:.12f}, reverse vs hand {gap_rh:.12f}")
print(f"largest gap: central difference (h = 1e-6) vs hand {gap_ch:.6f}")
assert gap_fr < 1e-9 and gap_rh < 1e-9 and gap_ch < 1e-3
assert abs(f50 - 12221.0) < 1e-9 and abs(g_r[1] - 792.0) < 1e-9 and abs(g_r[2] + 655.6) < 1e-9
print("ALL CHECKS PASS")
