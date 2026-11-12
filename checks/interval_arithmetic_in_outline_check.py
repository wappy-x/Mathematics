# Interval arithmetic -- the check behind the card.  Standard library only.
# A footbridge support reaction from toleranced inputs, carried as intervals
# [lo, hi] with every endpoint rounded outward; then two long computations: the
# tracker's ten-million-step total and a solver update whose interval explodes.
import math, struct
F, I = struct.Struct('<d'), struct.Struct('<q')

def step(x, d):                          # the neighbouring double: d = +1 up, -1 down
    if x == 0.0: return d * 5e-324
    b = I.unpack(F.pack(x))[0]
    return F.unpack(I.pack(b + (d if x > 0 else -d)))[0]

def out(lo, hi): return (step(lo, -1), step(hi, 1))   # round outward, one double each way
def add(x, y): return out(x[0] + y[0], x[1] + y[1])
def sub(x, y): return out(x[0] - y[1], x[1] - y[0])
def mul(x, y):
    p = [x[0] * y[0], x[0] * y[1], x[1] * y[0], x[1] * y[1]]
    return out(min(p), max(p))
def div(x, y):
    assert y[0] > 0 or y[1] < 0, "divisor interval contains zero"
    p = [x[0] / y[0], x[0] / y[1], x[1] / y[0], x[1] / y[1]]
    return out(min(p), max(p))
def iv(mid, tol): return out(mid - tol, mid + tol)
def show(name, x, d=6): print(f"{name:<36}[{x[0]:.{d}f}, {x[1]:.{d}f}]  width {x[1] - x[0]:.{d}f}")
def dec6(num, den): q = (2 * num * 10**6 + den) // (2 * den); return f"{q // 10**6}.{q % 10**6:06d}"

# ---- the footbridge: reaction at support A, R = P (L - a) / L ----
cart, cargo = iv(30.0, 1.0), iv(20.0, 1.0)              # kN
P = add(cart, cargo)                                    # load on the deck, kN
L, a = iv(20.0, 0.05), iv(8.0, 0.10)                    # span and load position, m
naive = div(mul(P, sub(L, a)), L)                       # as written: L appears twice
tight = mul(P, sub((1.0, 1.0), div(a, L)))              # rewritten: each input once
show("load P = cart + cargo, kN", P)
show("span L, m", L)
show("position a, m", a)
show("L - a, m", sub(L, a))
show("P (L - a), kN m", mul(P, sub(L, a)))
show("a / L", div(a, L))
show("1 - a / L", sub((1.0, 1.0), div(a, L)))
print(f"{'nominal reaction 50 x 12 / 20, kN':<36}{50.0 * (20.0 - 8.0) / 20.0:.6f}")
show("as written, P (L - a) / L", naive)
show("rewritten, P (1 - a / L)", tight)
lo_n, lo_d, hi_n, hi_d = 48 * 1185, 1995, 52 * 1215, 2005   # exact corners, a and L in cm
print(f"{'exact range, whole numbers':<36}[{dec6(lo_n, lo_d)}, {dec6(hi_n, hi_d)}]  width {dec6(hi_n * lo_d - lo_n * hi_d, lo_d * hi_d)}")
grid = [p * (l - x) / l for p in (48.0, 49.0, 50.0, 51.0, 52.0)
        for x in [7.9 + 0.02 * k for k in range(11)] for l in [19.95 + 0.01 * k for k in range(11)]]
print(f"{'brute force, 605 input points':<36}[{min(grid):.6f}, {max(grid):.6f}]")
print(f"over-width of the as-written form: {(naive[1] - naive[0]) / (tight[1] - tight[0]):.4f} times")
for name, x in [("nominal", (30.0, 30.0)), ("exact range", (lo_n / lo_d, hi_n / hi_d)),
                ("rewritten", tight), ("as written", naive)]:
    s, e = int((x[0] - 28.0) / 0.08 + 0.5), int((x[1] - 28.0) / 0.08 + 0.5)
    print(f"{name:<12}{x[0]:7.3f} |" + "." * s + "#" * (e - s + 1) + "." * (50 - e) + f"| {x[1]:.3f}")
ex_lo, ex_hi = lo_n / lo_d, hi_n / hi_d
(tn, td), (un, ud) = tight[0].as_integer_ratio(), tight[1].as_integer_ratio()   # the ends, exactly
assert tn * lo_d <= lo_n * td and hi_n * ud <= un * hi_d        # encloses the exact range, no rounding
assert ex_lo <= tight[0] + 1e-9 and tight[1] - 1e-9 <= ex_hi    # and hugs it
assert naive[0] < ex_lo - 0.1 and naive[1] > ex_hi + 0.1          # still encloses, but loose
assert tight[0] <= min(grid) and max(grid) <= tight[1] and abs(min(grid) - ex_lo) < 1e-12

# ---- multiplying across zero: an off-centre load, moment = P x c ----
c = out(-0.02, 0.03)                                    # offset of the load, m
M = mul(P, c)
show("moment P x c, four products, kN m", M, 4)
print(f"{'moment, lo x lo and hi x hi only':<36}[{P[0] * c[0]:.4f}, {P[1] * c[1]:.4f}]")
corners = [p * x for p in (48.0, 52.0) for x in (-0.02, 0.03)]
print("four corner products: " + ", ".join(f"{v:.4f}" for v in corners))
assert abs(M[0] - min(corners)) < 1e-12 and abs(M[0] - (-1.04)) < 1e-12 and P[0] * c[0] > M[0] + 0.05
print(f"wrong subtraction [L_lo - a_lo, L_hi - a_hi]: [{L[0] - a[0]:.2f}, {L[1] - a[1]:.2f}]")

# ---- the tracker: 0.1 added ten million times, as an interval ----
n, rat = 10_000_000, (0.1).as_integer_ratio()
tenth = (step(0.1, -1), 0.1)
lo_r = tenth[0].as_integer_ratio()
assert 10 * lo_r[0] < lo_r[1] and 10 * rat[0] > rat[1]  # the pair really brackets 1/10
total, plain = (0.0, 0.0), 0.0
for _ in range(n):
    total = add(total, tenth)                           # the interval rule, rounded outward
    plain += 0.1
s_lo, s_hi = total
print(f"{'tracker total, interval':<36}[{s_lo:.6f}, {s_hi:.6f}]  width {s_hi - s_lo:.6f}")
print(f"{'tracker total, plain sum':<36}{plain:.6f}  true error {1e6 - plain:.6f}")
print(f"bound over true error: {(s_hi - s_lo) / (1e6 - plain):.2f}")
assert s_lo < 1e6 < s_hi and s_lo <= plain <= s_hi and plain < 1e6 and s_hi - s_lo < 0.002

# ---- a solver update, x <- x - 0.5 (x - 10), twenty times ----
X0 = out(9.95, 10.05)
xa, xb, rows = X0, X0, []
for k in range(21):
    if k % 2 == 0: rows.append((k, math.log10(xa[1] - xa[0]), math.log10(xb[1] - xb[0])))
    xa = sub(xa, mul((0.5, 0.5), sub(xa, (10.0, 10.0))))   # as written: x twice
    xb = add(mul((0.5, 0.5), xb), (5.0, 5.0))             # rewritten: 0.5 x + 5
    if k == 19: wa, wb, A20, B20 = xa[1] - xa[0], xb[1] - xb[0], xa, xb
print("step                    " + "".join(f"{r[0]:>7}" for r in rows))
print("log10 width, as written " + "".join(f"{r[1]:>7.2f}" for r in rows))
print("log10 width, rewritten  " + "".join(f"{r[2]:>7.2f}" for r in rows))
show("after 20 steps, as written", A20, 3)
show("after 20 steps, rewritten", B20, 9)
assert abs(wa / (0.1 * 1.5**20) - 1) < 1e-9 and abs(wb / (0.1 * 0.5**20) - 1) < 1e-5
print(f"widths after 20 steps, as written over true: {wa / (0.1 * 0.5**20) / 1e9:.4f} billion")
print("ALL CHECKS PASS")
