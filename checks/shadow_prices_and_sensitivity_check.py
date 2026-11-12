# Shadow prices and sensitivity -- the check behind the card.  Standard library only.
# A bakery's daily plan: x1 batches of sponge (30 pounds margin), x2 batches of loaf
# cake (27 pounds).  Limits: oven hours, flour (kg), van loads.  No solver is imported:
# every LP here is solved by visiting every corner.  Three roads to the shadow prices:
# (1) solve the binding rows, (2) re-solve with one more unit, (3) solve the dual LP.
def gauss(M, v):                         # solve M z = v; None if M is singular
    n = len(v)
    a = [M[i][:] + [v[i]] for i in range(n)]
    for k in range(n):
        p = k
        for i in range(k + 1, n):
            if abs(a[i][k]) > abs(a[p][k]): p = i
        if abs(a[p][k]) < 1e-12: return None
        a[k], a[p] = a[p], a[k]
        for i in range(n):
            if i != k:
                f = a[i][k] / a[k][k]
                a[i] = [a[i][j] - f * a[k][j] for j in range(n + 1)]
    return [a[i][n] / a[i][i] for i in range(n)]

def best_corner(c, G, h):                # max c.z subject to G z <= h, trying every corner
    n, best, arg = len(c), None, None
    for mask in range(1 << len(G)):
        rows = [i for i in range(len(G)) if mask >> i & 1]
        if len(rows) != n: continue
        z = gauss([G[i] for i in rows], [h[i] for i in rows])
        if z is None: continue
        if any(sum(G[i][j] * z[j] for j in range(n)) > h[i] + 1e-9 for i in range(len(G))): continue
        val = sum(c[j] * z[j] for j in range(n))
        if best is None or val > best + 1e-9: best, arg = val, z
    return best, arg

NAMES = ["oven", "flour", "vans"]
A = [[2.0, 1.0], [10.0, 15.0], [0.6, 0.6]]   # oven hours, flour kg, van loads per batch
B0, C0 = [60.0, 600.0, 30.0], [30.0, 27.0]

def plan(b, c=C0):                       # the bakery LP, with x1, x2 >= 0 as two more rows
    return best_corner(c, A + [[-1.0, 0.0], [0.0, -1.0]], b + [0.0, 0.0])

def bump(i, t, b=B0):                    # the limits with limit i moved by t
    return [b[k] + (t if k == i else 0.0) for k in range(3)]

def prices(b, c=C0):                     # road 1: solve the binding rows for the prices
    P, x = plan(b, c)
    G, h = A + [[-1.0, 0.0], [0.0, -1.0]], b + [0.0, 0.0]
    bind = [i for i in range(5) if h[i] - G[i][0] * x[0] - G[i][1] * x[1] < 1e-9]
    yb = gauss([[G[i][j] for i in bind] for j in range(2)], c)   # needs exactly 2 binding rows
    return P, x, [yb[bind.index(i)] + 0.0 if i in bind else 0.0 for i in range(3)]

print("setting: 4 ovens x 15 h =", 4 * 15, "oven hours; per batch sponge 2 h, 10 kg, 0.6 van load;"
      " loaf 1 h, 15 kg, 0.6 van load; 30 vans")
P, x, y = prices(B0)
used = [A[i][0] * x[0] + A[i][1] * x[1] for i in range(3)]
print(f"plan: sponge {x[0]:.2f} batches, loaf {x[1]:.2f} batches, profit {P:.2f}")
for i in range(3):
    print(f"{NAMES[i]:5}: limit {B0[i]:7.2f}, used {used[i]:7.2f}, slack {B0[i] - used[i]:6.2f}")
bind = [i for i in range(3) if B0[i] - used[i] < 1e-9]
yb = [y[i] for i in bind]
for i in range(3):
    up, down = plan(bump(i, 1.0))[0] - P, P - plan(bump(i, -1.0))[0]       # road 2
    print(f"{NAMES[i]:5}: shadow price {y[i]:.2f}; re-solve +1 gains {up:.2f}, -1 loses {down:.2f}")
    assert abs(up - y[i]) < 1e-9 and abs(down - y[i]) < 1e-9
D, yd = best_corner([-v for v in B0], [[-A[i][j] for i in range(3)] for j in range(2)]
                    + [[-1.0 if k == i else 0.0 for k in range(3)] for i in range(3)], [-v for v in C0] + [0.0] * 3)
print(f"dual LP by its corners: prices {yd[0] + 0.0:.2f}, {yd[1] + 0.0:.2f}, {yd[2] + 0.0:.2f}; cost {-D:.2f}")  # road 3
assert all(abs(yd[i] - y[i]) < 1e-9 for i in range(3)) and abs(-D - P) < 1e-9
print(f"profit = 60 x {y[0]:.2f} + 600 x {y[1]:.2f} + 30 x {y[2]:.2f} = {sum(B0[i] * y[i] for i in range(3)):.2f}")
VAR = ["sponge", "loaf"]
rc = [C0[j] - sum(y[i] * A[i][j] for i in range(3)) for j in range(2)]   # margin minus value of what it uses
print("reduced cost: " + ", ".join(f"{VAR[j]} {round(rc[j], 9) + 0.0:.2f}" for j in range(2)))
for i in range(3):                       # ranging by formula: keep the same rows binding
    if i in bind:
        d = gauss([A[k] for k in bind], [1.0 if k == i else 0.0 for k in bind])
        moves = [(-x[j] / d[j], VAR[j] + " hits 0") for j in range(2) if abs(d[j]) > 1e-12]
        moves += [((B0[k] - used[k]) / (A[k][0] * d[0] + A[k][1] * d[1]), NAMES[k] + " binds")
                  for k in range(3) if k not in bind and abs(A[k][0] * d[0] + A[k][1] * d[1]) > 1e-12]
        lo = max(m for m in moves if m[0] < 0); hi = min(m for m in moves if m[0] > 0)
        rng = (B0[i] + lo[0], B0[i] + hi[0])
        print(f"{NAMES[i]:5}: price {y[i]:.2f} holds from {rng[0]:.2f} ({lo[1]}) to {rng[1]:.2f} ({hi[1]});"
              f" allowable increase {hi[0]:.2f}, decrease {-lo[0]:.2f}")
        print(f"{NAMES[i]:5}: each extra unit moves sponge by {d[0]:+.2f}, loaf by {d[1]:+.2f} batches, van loads by {0.6 * (d[0] + d[1]):+.2f}")
    else:
        rng = (used[i], float("inf"))
        print(f"{NAMES[i]:5}: price 0.00 holds from {used[i]:.2f} up, with no upper end; allowable decrease {B0[i] - used[i]:.2f}")
    t_up = t_dn = 0.0                    # ranging by scanning: re-solve one unit at a time
    while t_up < 3 * B0[i] and abs(plan(bump(i, t_up + 1))[0] - plan(bump(i, t_up))[0] - y[i]) < 1e-9: t_up += 1
    while abs(plan(bump(i, t_dn - 1))[0] - plan(bump(i, t_dn))[0] + y[i]) < 1e-9: t_dn -= 1
    print(f"{NAMES[i]:5}: scan agrees, price constant from {B0[i] + t_dn:.2f} to "
          + ("no end" if t_up >= 3 * B0[i] else f"{B0[i] + t_up:.2f}"))
    assert abs(B0[i] + t_dn - rng[0]) < 1e-6 and (t_up >= 3 * B0[i] or abs(B0[i] + t_up - rng[1]) < 1e-6)
for j in range(2):                       # margin ranges: the prices must stay >= 0
    dy = gauss([[A[i][k] for i in bind] for k in range(2)], [1.0 if k == j else 0.0 for k in range(2)])
    lo = max(-yb[k] / dy[k] for k in range(2) if dy[k] > 0); hi = min(-yb[k] / dy[k] for k in range(2) if dy[k] < 0)
    cl, ch = C0[j] + lo, C0[j] + hi
    print(f"{VAR[j]:6} margin: plan unchanged from {cl:.2f} to {ch:.2f} pounds; increase {hi:.2f}, decrease {-lo:.2f}")
    for cc, same in ((cl + 0.5, True), (cl - 0.5, False), (ch - 0.5, True), (ch + 0.5, False)):
        xx = plan(B0, [cc if k == j else C0[k] for k in range(2)])[1]
        assert (abs(xx[0] - x[0]) + abs(xx[1] - x[1]) < 1e-9) == same
# what breaks: prices used outside their range, added together, or replaced by averages
print(f"flour +200 kg: price predicts {P + 200 * y[1]:.2f}, re-solve gives {plan(bump(1, 200))[0]:.2f}")
both = plan([80.0, 700.0, 30.0])[0]
print(f"oven +20 and flour +100: prices predict {P + 20 * y[0] + 100 * y[1]:.2f}, re-solve gives {both:.2f}")
print(f"average flour value {P / 600:.2f} per kg predicts +{100 * P / 600:.2f} for 100 kg; true +{plan(bump(1, 100))[0] - P:.2f}")
print(f"average van value {P / 30:.2f} per load; a 31st load truly adds {plan(bump(2, 1))[0] - P:.2f}")
assert plan(bump(1, 200))[0] < P + 200 * y[1] - 1 and both < P + 20 * y[0] + 100 * y[1] - 1
print(f"flour already costs 0.50 per kg inside the margins: most to pay for an extra kg {0.50 + y[1]:.2f}")
oven_net, flour_net = 20 * (y[0] - 5.0), 100 * (y[1] - 0.80)
print(f"decision: 20 overtime hours at 5.00 net {oven_net:.2f}; 100 kg at 0.80 extra net {flour_net:.2f}; "
      f"both net {both - P - 100 - 80:.2f}")
P80 = plan([80.0, 600.0, 30.0])[0]
print(f"at 80 oven hours: profit {P80:.2f}; hour 81 adds {plan([81.0, 600.0, 30.0])[0] - P80:.2f}, "
      f"1 more kg flour adds {plan([80.0, 601.0, 30.0])[0] - P80:.2f}, 1 fewer loses {P80 - plan([80.0, 599.0, 30.0])[0]:.2f}")
pts = [plan([float(h), 600.0, 30.0])[0] for h in range(0, 121, 10)]
print("chart, profit at oven hours 0, 10, ..., 120:", ", ".join(f"{p:.0f}" for p in pts))
assert abs(pts[4] - 1080) < 1e-9 and abs(pts[8] - 1440) < 1e-9 and abs(pts[12] - pts[10]) < 1e-9
for h in (40.0, 80.0, 100.0):
    print(f"at {h:.0f} oven hours: sponge {plan([h, 600.0, 30.0])[1][0] + 0.0:.2f}, loaf {plan([h, 600.0, 30.0])[1][1] + 0.0:.2f}")
print("oven hour worth by stretch:", ", ".join(f"{lab} {(pts[k + 1] - pts[k]) / 10:.2f}"
      for lab, k in (("0-40 h", 0), ("40-80 h", 4), ("80-100 h", 8), ("past 100 h", 10))))
for label, b, c in (("flour 750", [60.0, 750.0, 30.0], C0), ("sponge margin 55", B0, [55.0, 27.0]),
                    ("vans 26", [60.0, 600.0, 26.0], C0)):
    Pt, xt, yt = prices(b, c)
    print(f"try {label}: plan {xt[0] + 0.0:.2f}, {xt[1] + 0.0:.2f}; profit {Pt:.2f}; prices {yt[0]:.2f}, {yt[1]:.2f}, {yt[2]:.2f}")
px = lambda u, v: f"({110 + 3.3 * u:.1f}, {215 - 3.3 * v:.1f})"
print("figure, 3.3 px per batch, origin (110, 215): corners", " ".join(px(*q) for q in ((0, 0), (30, 0), (15, 30), (0, 40))))
print("figure, line ends: oven", px(0, 60), px(30, 0), "flour", px(0, 40), px(60, 0),
      "flour 700", px(0, 700 / 15), px(60, 20 / 3), "vans", px(0, 50), px(50, 0))
print("ALL CHECKS PASS")
