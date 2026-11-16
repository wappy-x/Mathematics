# Subharmonic functions and Perron's method -- the check behind the card.  Standard library only.
# A long metal box, cross-section 1 m x 1 m.  Lid (x2 = 1 m) at 100 V, sides and floor grounded.
# The floor is rough: five sawtooth teeth, 10 cm tall, 20 cm wide.  u = potential, V.
# Roads: under and over shapes in closed form (Fourier series); the discrete Perron lift from
# below and from above; SOR grids at four steps with observed order; mean-value tests.
import math

V0, TOOTH, PI = 100.0, 0.1, math.pi

def sci(v, d=1):                             # e-notation with the same digits in Rust
    e = math.floor(math.log10(abs(v))); m = v / 10 ** e
    return f"{m:.{d}f}e{'-' if e < 0 else '+'}{abs(e):02d}"

def floor(x):                                # height of the rough floor at x1 = x, m
    return TOOTH - abs(x % (2 * TOOTH) - TOOTH)

def box(x, y, top, lid=V0, n=200):          # flat-floored box [0,1] x [0,top], lid at `lid` V
    s = 0.0
    for m in range(n):
        k = (2 * m + 1) * PI
        s += 4 * lid / k * math.sin(k * x) * math.exp(k * (y - top)) * (1 - math.exp(-2 * k * y)) / (1 - math.exp(-2 * k * top))
    return s

def omitted(x, y, top, n=200):              # first term the series leaves out
    k = (2 * n + 1) * PI
    return 4 * V0 / k * abs(math.sin(k * x)) * math.exp(k * (y - top))

def under(x, y):                             # rectangle above the tooth tips, glued to 0 below: subharmonic
    return box(x, y - TOOTH, 1 - TOOTH) if y > TOOTH else 0.0

def over(x, y): return box(x, y, 1.0)        # the flat-floored square: harmonic, >= 0 on the teeth

def setup(n, rough=True, lid=V0, fill=0.0):  # grid of step 1/n m: walls fixed, inside filled
    fl = [round(floor(i / n) * n) if rough else 0 for i in range(n + 1)]
    u = [[0.0] * (n + 1) for _ in range(n + 1)]
    for i in range(1, n):
        u[i][n] = lid
        for j in range(fl[i] + 1, n): u[i][j] = fill
    return u, fl

def sweep(u, fl, w):                          # one pass: each value moves to (w times) its neighbours' average
    n, d = len(u) - 1, 0.0
    for i in range(1, n):
        a, b, c = u[i - 1], u[i], u[i + 1]
        for j in range(fl[i] + 1, n):
            r = 0.25 * (a[j] + c[j] + b[j - 1] + b[j + 1]) - b[j]
            b[j] += w * r; d = max(d, abs(r))
    return d

def grid(n, rough=True, lid=V0):              # SOR to convergence
    u, fl = setup(n, rough, lid); w = 2 / (1 + math.sin(PI / n)); count = 1
    while sweep(u, fl, w) > 1e-10: count += 1
    return u, count

c = (0.5, 0.5)
lo, hi = under(*c), over(*c)
print(f"under shape (rectangle above the tips) at centre: {lo:.4f} V; first omitted term {sci(omitted(0.5, 0.4, 0.9))} V")
sh = lambda z: (math.exp(z) - math.exp(-z)) / 2
terms = [4 * V0 / (k * PI) * math.sin(k * PI / 2) * sh(0.4 * k * PI) / sh(0.9 * k * PI) for k in (1, 3, 5)]
print(f"by hand: 400/pi = {4 * V0 / PI:.3f} V; sinh(0.4 pi) = {sh(0.4 * PI):.4f}, sinh(0.9 pi) = {sh(0.9 * PI):.4f}; terms k = 1, 3, 5: "
      + ", ".join(f"{t:.4f}" for t in terms) + f" V; sum {sum(terms):.4f} V")
print(f"over shape (flat-floored square) at centre: {hi:.4f} V; exact by symmetry 25 V")
assert abs(hi - 25) < 1e-12                      # four rotated lids add to a constant 100 V
print("grid | h cm | SOR sweeps | u(centre) V | flat floor V")
vals = []
for n in (20, 40, 80, 160):
    u, cnt = grid(n); f = grid(n, rough=False)[0][n // 2][n // 2]
    vals.append(u[n // 2][n // 2]); assert abs(f - 25) < 1e-6 and lo < vals[-1] < hi
    print(f"grid | {100 / n:.3f} | {cnt} | {vals[-1]:.4f} | {f:.4f}")
    if n == 160: fine = u
orders = [math.log2((vals[i] - vals[i + 1]) / (vals[i + 1] - vals[i + 2])) for i in range(2)]
p = orders[-1]; best = vals[-1] + (vals[-1] - vals[-2]) / (2 ** p - 1)
assert all(1.1 < q < 1.5 for q in orders)          # sharp tips: about 4/3, not 2
print(f"observed order {orders[0]:.2f}, {orders[1]:.2f}; extrapolated centre {best:.4f} V, last step off by {best - vals[-1]:.4f} V")
assert lo < best < hi
print(f"by hand: last two grids differ by {vals[-1] - vals[-2]:.4f} V; 2^p - 1 = {2 ** p - 1:.3f}; teeth pull the centre down by {hi - best:.4f} V")

print("Perron lift on the 5 cm grid | sweeps | from below V | from above V | gap V")
(a, fl), (b, _) = setup(20, fill=0.0), setup(20, fill=V0)
k, prev_lo, prev_hi = 0, -1.0, 1e9
while b[10][10] - a[10][10] >= 0.01:
    k += 1; sweep(a, fl, 1.0); sweep(b, fl, 1.0)
    al, bh = a[10][10], b[10][10]
    assert prev_lo <= al <= vals[0] <= bh <= prev_hi; prev_lo, prev_hi = al, bh
    assert all(a[i][j] <= 0.25 * (a[i-1][j] + a[i+1][j] + a[i][j-1] + a[i][j+1]) + 1e-12
               for i in range(1, 20) for j in range(fl[i] + 1, 20))   # every lower iterate is a discrete under shape
    if k == 20: stop20 = al
    if k in (10, 40, 160): print(f"lift | {k} | {al:.4f} | {bh:.4f} | {bh - al:.4f}")
print(f"lift | {k} | {al:.4f} | {bh:.4f} | {bh - al:.4f}  (first sweep with gap under 0.01 V)")

ys = [round(0.1 * i, 1) for i in range(1, 11)]
print("chart, x1 = 0.5 m, x2 = 0.1..1.0 m, under: " + ", ".join(f"{under(0.5, y) if y < 1 else V0:.2f}" for y in ys))
print("chart, rough box (1/160 m grid): " + ", ".join(f"{fine[80][round(160 * y)]:.2f}" for y in ys))
print("chart, over: " + ", ".join(f"{over(0.5, y) if y < 1 else V0:.2f}" for y in ys))
print(f"first omitted term at x2 = 0.9 m: {sci(omitted(0.5, 0.9, 1.0))} V")

def avg(f, x, y, r, m=720): return sum(f(x + r * math.cos(2 * PI * t / m), y + r * math.sin(2 * PI * t / m)) for t in range(m)) / m
ac = avg(over, 0.5, 0.5, 0.3); assert abs(ac - hi) < 1e-9          # harmonic: equal to its average
ag = avg(under, 0.2, 0.1, 0.05); assert ag > under(0.2, 0.1) + 0.1  # glued shape: strictly below its average
print(f"mean values: over shape at centre {hi:.4f} V, circle of 30 cm {ac:.4f} V; glued under shape at (0.2, 0.1) m {under(0.2, 0.1):.4f} V, circle of 5 cm {ag:.4f} V")

def barrier(x, y):                               # sqrt(r) cos(phi/2), phi measured from straight up at the tip
    dx, dy = x - 0.5, y - TOOTH
    return math.sqrt(math.hypot(dx, dy)) * math.cos(math.atan2(dx, dy) / 2)
bd = [(i / 1000, floor(i / 1000)) for i in range(1001)] + [(0.0, j / 1000) for j in range(1001)] + [(1.0, j / 1000) for j in range(1001)] + [(i / 1000, 1.0) for i in range(1001)]
bd += [(0.5 + s * 0.05 / math.sqrt(2), TOOTH - 0.05 / math.sqrt(2)) for s in (-1, 1)]   # the two edge points exactly 5 cm away
mb = min(barrier(x, y) for x, y in bd if math.hypot(x - 0.5, y - TOOTH) >= 0.05 - 1e-12)
ab = avg(barrier, 0.5, 0.3, 0.1); assert abs(ab - barrier(0.5, 0.3)) < 1e-9 and mb > 0
assert abs(mb - math.sqrt(0.05) * math.cos(3 * PI / 8)) < 1e-12   # least value: on the tooth edge, 5 cm out
print(f"barrier at the tip (0.5, 0.1) m: {barrier(0.5, 0.3):.6f} at (0.5, 0.3), circle average {ab:.6f}; least on walls 5 cm or more away {mb:.4f}; on the tooth edge cos(67.5 deg) = {math.cos(3 * PI / 8):.4f}")
cap = V0 / mb; near = fine[80][17]                # over shape cap * barrier: >= 0 near the tip, >= 100 V beyond 5 cm
assert near <= cap * barrier(0.5, 0.10625)
print(f"barrier over shape {cap:.1f} x barrier: at 0.625 cm above the tip {cap * barrier(0.5, 0.10625):.2f} V (grid {near:.4f} V); at 1 mm {cap * barrier(0.5, 0.101):.2f} V; at 1 um {cap * barrier(0.5, 0.100001):.4f} V")

R, r = 0.5, 0.25                                 # grounded tube, thin wire on its axis at 100 V
tube = lambda a, s=r: V0 * math.log(R / s) / math.log(R / a)
for a in (1e-3, 1e-6, 1e-12):
    t = 1e-4; res = (tube(a, r + t) - 2 * tube(a, r) + tube(a, r - t)) / t ** 2 + (tube(a, r + t) - tube(a, r - t)) / (2 * t * r)
    assert abs(res) < 1e-4 * tube(a)
    print(f"tube: wire radius {sci(a, 0)} m, u at r = 25 cm: {tube(a):.4f} V; residual u_rr + u_r/r = {sci(abs(res))} V/m^2")
assert tube(1e-300) < 0.25
print(f"wire shrunk to a point (radius 1e-300 m): {tube(1e-300):.4f} V; Perron's answer 0 V, not 100 V")

dome = lambda x, y: 50 * math.sin(PI * x) * math.sin(PI * (y - TOOTH) / (1 - TOOTH))
print("what breaks, at the centre:")
print(f"  floor taken as flat: {hi:.4f} V, not {best:.4f}")
print(f"  a dome under the walls taken as an under shape: {dome(0.5, 0.5):.4f} V, above the answer")
print(f"  lift stopped after 20 sweeps: {stop20:.4f} V, a floor, not the answer")
print(f"  bowl 100 x2^2 taken as an under shape: {V0 * 0.25:.4f} V; it pokes {V0 * 1.0:.0f} V above the side walls at the top")
print(f"try: lid at 50 V, centre {grid(80, lid=50.0)[0][40][40]:.4f} V; wire 1e-9 m: {tube(1e-9):.4f} V")
print("ALL CHECKS PASS")
