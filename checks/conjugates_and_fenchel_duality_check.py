# Convex conjugates and Fenchel duality -- the check behind the card.  Standard library only.
# A roaster needs D = 100 kg of blend from three estates.  Estate i charges f_i(x) = c_i x + q_i x^2 / 2
# pounds for x kg.  The cafe's contract charges k pounds per kg the delivery is off 100 kg, either way.
# Roads to the bill: equal slopes (the formula); every whole-kilo order (brute force); the Fenchel dual
# maximised by search.  Also checked: conjugates by search against their formulas; -y in dg.
NAMES, C, Q, D = ("Brazil", "Colombia", "Robusta"), (8.0, 9.0, 5.0), (0.1, 0.05, 0.2), 100.0

def f(i, x): return C[i] * x + Q[i] * x * x / 2           # estate i's cost of x kg, pounds
def f_formula(i, y): return (y - C[i]) ** 2 / (2 * Q[i])   # its conjugate, from Step 1
def g(z, k): return k * abs(z - D)                         # the contract's penalty on z kg delivered

def top(h, lo, hi):                    # largest value of a concave h on [lo, hi], by ternary search
    for _ in range(200):
        a, b = lo + (hi - lo) / 3, hi - (hi - lo) / 3
        lo, hi = (a, hi) if h(a) < h(b) else (lo, b)
    return h((lo + hi) / 2), (lo + hi) / 2

def f_star(i, y): return top(lambda x: y * x - f(i, x), -2000.0, 2000.0)[0]   # sup over x, by search
def g_star(w, k, R=1000.0):            # sup over z in [D - R, D + R] of w z - g(z): kink or an end
    return max(w * z - g(z, k) for z in (D - R, D, D + R))

def dual(y, k, fs=f_star): return -sum(fs(i, y) for i in range(3)) - g_star(-y, k)   # Fenchel's dual

def by_slopes(c, q, d, k):             # equal slopes: c_i + q_i x_i = y, sum x_i = d, y capped at k
    y = min(k, (d + sum(ci / qi for ci, qi in zip(c, q))) / sum(1 / qi for qi in q))
    x = [(y - ci) / qi for ci, qi in zip(c, q)]
    return y, x, sum(ci * xi + qi * xi * xi / 2 for ci, qi, xi in zip(c, q, x)) + k * abs(sum(x) - d)

def brute(k):                          # every whole-kilo order, 0 to 100 kg of each bean
    tab = [[f(i, x) for x in range(101)] for i in range(3)]
    return min((tab[0][a] + tab[1][b] + tab[2][r] + g(a + b + r, k), a, b, r)
               for a in range(101) for b in range(101) for r in range(101))

out = []
for k in (12.0, 10.0):
    y, x, cost = by_slopes(C, Q, D, k)
    bf = brute(k)
    d_star, y_star = top(lambda t: dual(t, k), -k, k)
    sub_g = (-k, k) if abs(sum(x) - D) < 1e-9 else ((-k, -k) if sum(x) < D else (k, k))   # dg at the total
    out.append((y, x, cost, bf, d_star, y_star, sub_g))
    print(f"k = {k:.0f}: price y = {y:.2f} pounds/kg; kg " + ", ".join(f"{n} {v:.2f}" for n, v in zip(NAMES, x))
          + f"; total {sum(x):.2f} kg")
    print(f"  primal, by slopes: {cost:.2f}; every whole-kilo order: {bf[0]:.2f} at {bf[1]}, {bf[2]}, {bf[3]} kg")
    print(f"  dual, by search: {d_star:.4f} at y = {y_star:.4f}")
    print(f"  certificate: slopes " + ", ".join(f"{C[i] + Q[i] * x[i]:.2f}" for i in range(3))
          + f"; -y = {-y:.2f} lies in dg = [{sub_g[0]:.0f}, {sub_g[1]:.0f}]")
(y, x, cost, bf, d_star, _, sub_g), low = out
for i in range(3):
    print(f"{NAMES[i]}: f({x[i]:.0f}) = {f(i, x[i]):.2f}; f*(11) formula {f_formula(i, 11.0):.2f}, by search"
          f" {f_star(i, 11.0):.4f}; sells y x - f = {11.0 * x[i] - f(i, x[i]):.2f}")
print(f"dual at 11 by hand: 100 x 11 - {sum(f_formula(i, 11.0) for i in range(3)):.2f} = {dual(11.0, 12.0, f_formula):.2f}")
inv, cq = sum(1 / q for q in Q), sum(c / q for c, q in zip(C, Q))
print(f"clearing: sum 1/q = {inv:.0f}, sum c/q = {cq:.0f}; dual = {cost:.0f} - {inv / 2:.1f} (y - 11)^2; average {cost / D:.2f}"
      f" pounds/kg; f1*(12) = {f_formula(0, 12.0):.2f}; k = 10: short by {D - sum(low[1]):.0f} kg; orders searched {101 ** 3}")
print(f"slope of f* at 11 (central difference) = kg offered: " +
      ", ".join(f"{(f_star(i, 11.001) - f_star(i, 10.999)) / 0.002:.4f}" for i in range(3)))
fy = [(f(0, a) + f_star(0, b) - a * b, a, b) for a in range(0, 61, 5) for b in range(6, 15)]   # 117 pairs
eq = [(a, b) for v, a, b in fy if abs(v) < 1e-6]
print(f"Fenchel-Young, Brazil: 30 kg at 11: {f(0, 30) + f_formula(0, 11) - 330:.4f}; 30 kg at 12: "
      f"{f(0, 30) + f_formula(0, 12) - 360:.4f}; grid of 117: {sum(v < -1e-9 for v, _, _ in fy)} below 0, equal at " + ", ".join(f"{a} kg/{b}" for a, b in eq))
print(f"abs conjugate, k = 12: g*(-11) = {g_star(-11, 12):.2f}; g*(13) with R = 1000, 2000: "
      f"{g_star(13, 12):.0f}, {g_star(13, 12, 2000.0):.0f}")
bic = top(lambda t: 30 * t - f_formula(0, t), -100.0, 100.0)
print(f"biconjugate, Brazil at 30 kg: f**(30) = {bic[0]:.4f} at slope {bic[1]:.4f}")
print("chart, dual value at y = 9 to 12 by 0.5: " + ", ".join(f"{dual(9 + t / 2, 12.0, f_formula):.3f}" for t in range(7)))

def sacks(s, k=12.0):                   # Robusta only in whole sacks of s kg: 0 or s
    f3 = lambda t: max(0.0, s * t - f(2, s))                   # its conjugate: max of y x - f over {0, s}
    pr = min(f(2, r) + by_slopes(C[:2], Q[:2], D - r, k)[2] for r in (0.0, s))
    du = top(lambda t: -f_formula(0, t) - f_formula(1, t) - f3(t) - g_star(-t, k), -k, k)
    env = top(lambda t: 30 * t - f3(t), -100.0, 100.0)[0]
    return pr, du[0], du[1], env
s60, s50, ns = sacks(60.0), sacks(50.0), by_slopes(C[:2], Q[:2], D, 12.0)   # ns: no Robusta at all
bf60 = min((f(0, a) + f(1, b) + f(2, r) + g(a + b + r, 12.0), a, b, r)
           for a in range(101) for b in range(101) for r in (0, 60))
print(f"sacks of 60 kg: primal {s60[0]:.2f} (whole kilos {bf60[0]:.2f} at {bf60[1]}, {bf60[2]}, {bf60[3]} kg); "
      f"no sack {ns[2]:.2f} at {ns[1][0]:.0f}, {ns[1][1]:.0f} kg; dual {s60[1]:.2f} at y = {s60[2]:.2f}; gap {s60[0] - s60[1]:.2f}; f3**(30) = {s60[3]:.2f}")
wrong_half = 1100 - sum((11.0 - C[i]) ** 2 / Q[i] for i in range(3))
no_cap = 100 * 11.0 - sum(f_formula(i, 11.0) for i in range(3))
print(f"wrong: no 1/2 in f*: Brazil f*(11) = {(11.0 - 8) ** 2 / 0.1:.2f}, dual at 11 = {wrong_half:.2f}")
print(f"wrong: k = 10 but -g*(-y) taken as 100 y everywhere: 'bound' {no_cap:.2f} above the true {low[2]:.2f}")
print(f"wrong: kilos fed to f*: f1*(30) = {f_formula(0, 30.0):.2f}")
for label, c, q, d in (("try: D = 120", C, Q, 120.0), ("try: Brazil q = 0.2", C, (0.2, 0.05, 0.2), D)):
    ty, tx, tc = by_slopes(c, q, d, 12.0)
    print(f"{label}: y = {ty:.4f}, kg " + ", ".join(f"{v:.2f}" for v in tx) + f", cost {tc:.2f}")
print(f"try: sacks of 50 kg: primal {s50[0]:.2f}, dual {s50[1]:.2f} at y = {s50[2]:.2f}")
pts = lambda cs: " ".join(f"{50 + 6.5 * a:.1f},{190 - 0.4 * b:.1f}" for a, b in cs)   # 6.5 per kg, 0.4 per pound
print("figure, Brazil cost:", pts((a, f(0, a)) for a in range(0, 41, 5)))
print("figure, slope-11 line:", pts(((0, -45.0), (40, 11 * 40 - 45.0))), "| touch", pts([(30, f(0, 30))]))

assert abs(bf[0] - cost) < 1e-9 and abs(low[3][0] - low[2]) < 1e-9          # formula = every whole-kilo order
assert abs(d_star - cost) < 1e-6 and abs(low[4] - low[2]) < 1e-6              # Fenchel dual meets the primal
assert all(abs(f_star(i, t) - f_formula(i, t)) < 1e-6 for i in range(3) for t in (6.0, 9.5, 11.0, 13.0))
assert min(fy)[0] > -1e-9 and eq == [(a, 8 + a // 10) for a in range(0, 61, 10)] and abs(f(0, 30) + f_formula(0, 12) - 360 - 0.05 * (30 - 40) ** 2) < 1e-9
assert g_star(13, 12, 2000.0) > g_star(13, 12) > 1000 and abs(bic[0] - f(0, 30)) < 1e-6
assert abs(bf60[0] - s60[0]) < 1e-9 and abs(ns[2] - s60[0]) < 1e-9 and s60[0] - s60[1] > 10 and abs(s50[0] - s50[1]) < 1e-6
assert no_cap > low[2] + 10 and sub_g[0] <= -y <= sub_g[1] and low[6][0] <= -low[0] <= low[6][1]   # -y in dg
print("ALL CHECKS PASS")
