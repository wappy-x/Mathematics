# Jensen's inequality and supporting planes -- the check behind the card.  Standard
# library only.  A blend is (x, y): the Brazil and Colombia shares, Ethiopia the rest.
# Cost in pounds a kilo = the beans + a taste penalty for missing strength 6, acidity 5.
def parts(x, y):                       # bean cost, strength score, acidity score
    e = 1 - x - y
    return 7 * x + 9 * y + 12 * e, 8 * x + 6 * y + 4 * e, 2 * x + 6 * y + 8 * e
def cost(x, y):
    b, s, a = parts(x, y)
    return b + (s - 6) ** 2 + (a - 5) ** 2
def grad(x, y):                        # the gradient, by the chain rule
    _, s, a = parts(x, y)
    return (-5 + 8 * (s - 6) - 12 * (a - 5), -3 + 4 * (s - 6) - 4 * (a - 5))
HESS = [[104, 40], [40, 16]]           # 2(g g' + h h'), g = (4, 2), h = (-6, -2)
def quad(dx, dy):                      # d' H d
    return HESS[0][0] * dx * dx + 2 * HESS[0][1] * dx * dy + HESS[1][1] * dy * dy
def plane(m, s, x, y):                 # supporting plane at m with slopes s
    return cost(*m) + s[0] * (x - m[0]) + s[1] * (y - m[1])
def grid(step):                        # every blend with shares on the grid
    n = round(1 / step)
    return [(i / n, j / n) for i in range(n + 1) for j in range(n + 1 - i)]
def surcharge(x, y): return cost(x, y) + 4 * max(0.0, (1 - x - y) - 0.25)
def two_style(x, y):                   # NOT convex: two strengths are paid for
    b, s, _ = parts(x, y)
    return b + 4 * min((s - 6) ** 2, (s - 7) ** 2)
f2 = lambda v: f"{v:.2f}"
f4 = lambda v: f"{0.0 if abs(v) < 1e-12 else v:.4f}"   # no "-0.0000" from rounding noise
BOLD, BRIGHT = (0.7, 0.1), (0.3, 0.4)
MIX = ((BOLD[0] + BRIGHT[0]) / 2, (BOLD[1] + BRIGHT[1]) / 2)
print("beans in pounds a kilo: Brazil 7, Colombia 9, Ethiopia 12; targets: strength 6, acidity 5")
print(f"{'blend':<14}{'Brazil':>7}{'Colomb':>7}{'Ethiop':>7}{'beans':>7}{'strgth':>7}"
      f"{'acid':>7}{'penalty':>8}{'cost':>7}")
for name, z in [("Bold", BOLD), ("Bright", BRIGHT), ("half and half", MIX)]:
    b, s, a = parts(*z)
    print(f"{name:<14}" + "".join(f"{v:>7.2f}" for v in (z[0], z[1], 1 - z[0] - z[1], b, s, a))
          + f"{cost(*z) - b:>8.2f}{cost(*z):>7.2f}")
avg2 = (cost(*BOLD) + cost(*BRIGHT)) / 2                   # road 1: cost the blends
d = (BOLD[0] - BRIGHT[0], BOLD[1] - BRIGHT[1])
print(f"average of the two costs {f2(avg2)}; cost of the mix {f2(cost(*MIX))}; "
      f"gap {f2(avg2 - cost(*MIX))}; by the Hessian, d = ({f2(d[0])}, {f2(d[1])}), d'Hd = {f2(quad(*d))}, /8 = {f2(quad(*d) / 8)}")
h = 1e-5                                                   # road 2: the plane
gn = ((cost(MIX[0] + h, MIX[1]) - cost(MIX[0] - h, MIX[1])) / (2 * h),
      (cost(MIX[0], MIX[1] + h) - cost(MIX[0], MIX[1] - h)) / (2 * h))
g = grad(*MIX)
print(f"gradient at the mix, formula ({f2(g[0])}, {f2(g[1])}); central difference "
      f"({f2(gn[0])}, {f2(gn[1])})")
k = 1e-3
def second(i, j):
    def at(a, b): return cost(MIX[0] + a, MIX[1] + b)
    e = [(k, 0), (0, k)]
    p, q = e[i], e[j]
    return (at(p[0] + q[0], p[1] + q[1]) - at(p[0] - q[0], p[1] - q[1])
            - at(q[0] - p[0], q[1] - p[1]) + at(-p[0] - q[0], -p[1] - q[1])) / (4 * k * k)
hn = [[second(i, j) for j in range(2)] for i in range(2)]
det = HESS[0][0] * HESS[1][1] - HESS[0][1] ** 2
print(f"Hessian, formula {HESS}; second differences [[{hn[0][0]:.2f}, {hn[0][1]:.2f}], "
      f"[{hn[1][0]:.2f}, {hn[1][1]:.2f}]]; determinant {det}, trace {HESS[0][0] + HESS[1][1]}")
pb, pr = plane(MIX, g, *BOLD), plane(MIX, g, *BRIGHT)
print(f"plane at the mix: {f2(cost(*MIX))} + {f2(g[0])}(x - 0.50) + {f2(g[1])}(y - 0.25); "
      f"at Bold {f2(pb)}, at Bright {f2(pr)}, average {f2((pb + pr) / 2)}")
fine = grid(0.01)
low = min(fine, key=lambda z: cost(*z) - plane(MIX, g, *z))
print(f"cost minus plane over {len(fine)} blends on a 0.01 grid: smallest "
      f"{f4(cost(*low) - plane(MIX, g, *low))}, at ({f2(low[0])}, {f2(low[1])})")
coarse = grid(0.05)                                        # a plane at every blend
margin = min(cost(*z) - plane(p, grad(*p), *z) for p in coarse for z in coarse if p != z)
print(f"tangent plane at each of {len(coarse)} blends, against the other {len(coarse) - 1}: "
      f"smallest margin {f4(margin)}")
week = [(5, -5), (-5, 0), (0, 5), (5, 5), (-5, -5)]       # road 3: the week's batches
costs = [cost(MIX[0] + a / 100, MIX[1] + b / 100) for a, b in week]
print("week, batch misses in points (Brazil, Colombia), cost: "
      + "; ".join(f"({a:+d}, {b:+d}) {f2(c)}" for (a, b), c in zip(week, costs)))
wavg = sum(costs) / len(costs)
spread = sum(quad(a / 100, b / 100) for a, b in week) / len(week) / 2
print(f"week average {f2(wavg)}; floor from the recipe alone {f2(cost(*MIX))}; "
      f"gap {f2(wavg - cost(*MIX))}; by half the average d'Hd {f2(spread)}")
ts = [i / 10 for i in range(11)]                            # the chart, Bright to Bold
seg = [(BRIGHT[0] + t * d[0], BRIGHT[1] + t * d[1]) for t in ts]
print("chart, share of Bold " + ", ".join(f"{t:.1f}" for t in ts))
print("chart, cost          " + ", ".join(f2(cost(*z)) for z in seg))
print("chart, chord         " + ", ".join(f2(cost(*BRIGHT) + t * (cost(*BOLD) - cost(*BRIGHT))) for t in ts))
print("chart, plane         " + ", ".join(f2(plane(MIX, g, *z)) for z in seg))
worst = {}                                                  # a crease at the mix
for lam in (0.0, 0.5, 1.0, 1.25):
    s = (g[0] - 4 * lam, g[1] - 4 * lam)
    worst[lam] = min(surcharge(*z) - plane(MIX, s, *z) for z in fine)
    print(f"crease, slopes ({f2(s[0])}, {f2(s[1])}): smallest cost minus plane "
          f"{f4(worst[lam])}")
cav = (surcharge(*BOLD) + surcharge(*BRIGHT)) / 2
print(f"crease, Jensen: Bold {f2(surcharge(*BOLD))}, Bright {f2(surcharge(*BRIGHT))}, "
      f"mix {f2(surcharge(*MIX))}, average {f2(cav)}")
wm = (0.4 * (BOLD[0] + BRIGHT[0]), 0.4 * (BOLD[1] + BRIGHT[1]))   # weights 0.4 and 0.4: not shares
print(f"weights 0.4 and 0.4, adding to 0.8: blend ({f2(wm[0])}, {f2(wm[1])}) costs {f2(cost(*wm))}, against "
      f"0.4 x {f2(cost(*BOLD))} + 0.4 x {f2(cost(*BRIGHT))} = {f2(0.4 * cost(*BOLD) + 0.4 * cost(*BRIGHT))}")
tb, tr, tm = two_style(*BOLD), two_style(*BRIGHT), two_style(*MIX)
print(f"mistake 1, two-style cost: Bold {f2(tb)}, Bright {f2(tr)}, mix {f2(tm)}, average {f2((tb + tr) / 2)}")
bb, br, bm = (parts(*z)[0] for z in (BOLD, BRIGHT, MIX))
print(f"mistake 2, beans only: mix {f2(bm)}, average {f2((bb + br) / 2)}; true mix cost "
      f"{f2(cost(*MIX))}, true week average {f2(wavg)}")
print(f"mistake 3, recipe cost as a ceiling: {f2(cost(*MIX))} against the week's {f2(wavg)}")
assert abs(avg2 - cost(*MIX) - quad(*d) / 8) < 1e-9 and abs(avg2 - cost(*MIX) - 1.06) < 1e-9
assert all(abs(g[i] - gn[i]) < 1e-6 and abs(hn[i][j] - HESS[i][j]) < 1e-3 for i in range(2) for j in range(2))
assert pb < cost(*BOLD) and pr < cost(*BRIGHT)
assert abs(cost(*low) - plane(MIX, g, *low)) < 1e-12 and low == (0.5, 0.25) and margin > 0
assert abs(wavg - cost(*MIX) - spread) < 1e-9 and abs(wavg - 9.39) < 1e-9
assert min(worst[0.0], worst[0.5], worst[1.0]) > -1e-12 and worst[1.25] < -0.01 and cav > surcharge(*MIX)
assert cost(*wm) > 0.4 * cost(*BOLD) + 0.4 * cost(*BRIGHT)
assert tm > (tb + tr) / 2
print("ALL CHECKS PASS")
