# Runge-Kutta and Butcher tableaux -- the check behind the card.  Python standard
# library only; math.tanh, math.cosh and math.log feed the closed form, nothing else.
# Rocket while the motor burns (illustrative): H' = v, v' = 40 - 0.004 v^2, from rest.
import math
def sci(x, d=2):                                  # e-notation spelled the way Rust spells it
    m, e = f"{x:.{d}e}".split("e"); return f"{m}e{int(e)}"
def rocket(t, s): return [s[1], 40 - 0.004 * s[1] * s[1]]
def exact(t): return [250 * math.log(math.cosh(0.4 * t)), 100 * math.tanh(0.4 * t)]
def step(tab, f, t, s, h):                        # one explicit step, read off a tableau (c, A, b)
    c, A, b = tab; ks = []
    for i in range(len(b)):
        Y = [s[m] + h * sum(A[i][j] * ks[j][m] for j in range(i)) for m in range(len(s))]
        ks.append(f(t + c[i] * h, Y))
    return [s[m] + h * sum(b[i] * ks[i][m] for i in range(len(b))) for m in range(len(s))], ks
def run(tab, f, s, h, n):
    for i in range(n): s = step(tab, f, i * h, s, h)[0]
    return s
def three_stage(c2, c3):                          # Step 4: solve the four order-3 conditions
    b2 = (2 - 3 * c3) / (6 * c2 * (c2 - c3)) + 0.0; b3 = (2 - 3 * c2) / (6 * c3 * (c3 - c2))
    a32 = 1 / (6 * b3 * c2)
    return ([0, c2, c3], [[], [c2], [c3 - a32, a32]], [1 - b2 - b3, b2, b3])
TAB = {"Euler": ([0], [[]], [1]), "midpoint": ([0, 0.5], [[], [0.5]], [0, 1]),
       "Heun": ([0, 1], [[], [1]], [0.5, 0.5]), "Kutta3": three_stage(0.5, 1),
       "Heun3": three_stage(1 / 3, 2 / 3),
       "RK4": ([0, 0.5, 0.5, 1], [[], [0.5], [0, 0.5], [0, 0, 1]], [1 / 6, 1 / 3, 1 / 3, 1 / 6]),
       "equal-b": ([0, 0.5, 1], [[], [0.5], [-1, 2]], [1 / 3, 1 / 3, 1 / 3]),
       "a32=1": ([0, 0.5, 1], [[], [0.5], [0, 1]], [1 / 6, 2 / 3, 1 / 6])}
h = 0.1
s1, ks = step(TAB["RK4"], rocket, 0, [0, 0], h)
print(f"rocket: H' = v, v' = 40 - 0.004 v^2, terminal speed {math.sqrt(40 / 0.004):.0f} m/s; one step h = 0.1 s from rest")
for i, k in enumerate(ks):
    print(f"RK4 stage {i + 1}: c = {TAB['RK4'][0][i]:.1f}, height slope {k[0]:.9f}, speed slope {k[1]:.9f}")
wsl = [sum(w * k[m] for w, k in zip([1, 2, 2, 1], ks)) / 6 for m in (0, 1)]
print(f"RK4 weighted slopes (1, 2, 2, 1)/6: height {wsl[0]:.9f}, speed {wsl[1]:.9f}")
ex = exact(h)
print(f"exact after 0.1 s: height {ex[0]:.9f} m, speed {ex[1]:.9f} m/s")
one = {}
for name in ("Euler", "midpoint", "Heun", "Kutta3", "Heun3", "RK4", "equal-b", "a32=1"):
    s = step(TAB[name], rocket, 0, [0, 0], h)[0]; one[name] = [ex[0] - s[0], ex[1] - s[1]]
    print(f"{name:<9}height {s[0]:.9f} error {sci(one[name][0])}, speed {s[1]:.9f} error {sci(one[name][1])}")
assert abs(s1[0] - ex[0]) < 1e-8 and abs(s1[1] - ex[1]) < 1e-6 and abs(one["Euler"][0]) > 0.19
K3 = TAB["Kutta3"]; H3 = TAB["Heun3"]
for tb in (K3, H3):                               # c2 and c3 read off the tableau itself
    print(f"three-stage, c2 = {tb[0][1]:.4f}, c3 = {tb[0][2]:.4f}: b =", " ".join(f"{x:.6f}" for x in tb[2]),
          f"a31 = {tb[1][2][0]:.6f} a32 = {tb[1][2][1]:.6f}")
assert max(abs(p - q) for p, q in zip(K3[2] + K3[1][2], [1 / 6, 2 / 3, 1 / 6, -1, 2])) < 1e-15
# rooted trees: a tree is a multiset of child trees; trees[i] = (nodes, children indices)
trees = [(1, [])]
def forests(m, start, pool):                      # multisets of trees from pool, total m nodes
    if m == 0: yield []; return
    for i in range(start, len(pool)):
        if pool[i][0] <= m:
            for rest in forests(m - pool[i][0], i, pool): yield [i] + rest
for n in range(2, 7):
    pool = list(trees); trees += [(n, f) for f in forests(n - 1, 0, pool)]
def name(i): return "[" + "".join(name(j) for j in trees[i][1]) + "]"
def gamma(i): return trees[i][0] * math.prod(gamma(j) for j in trees[i][1])
counts = [sum(1 for t in trees if t[0] == n) for n in range(1, 7)]
print("rooted trees with 1..6 nodes:", " ".join(map(str, counts)), "; conditions for order 1..6:",
      " ".join(str(sum(counts[:p])) for p in range(1, 7)))
assert counts == [1, 1, 2, 4, 9, 20]
for i in range(8): print(f"tree {i + 1}: {name(i):<10} nodes {trees[i][0]}, gamma {gamma(i)}")
def misses(tab):                                  # b . Phi(tree) - 1/gamma(tree), every tree
    c, A, b = tab; s = len(b); Phi = []
    for t in trees:
        Phi.append([math.prod(sum(A[i][j] * Phi[k][j] for j in range(i)) for k in t[1]) for i in range(s)])
    return [sum(b[i] * P[i] for i in range(s)) - 1 / gamma(k) for k, P in enumerate(Phi)]
def order(tab):
    bad = [trees[k][0] for k, m in enumerate(misses(tab)) if abs(m) > 1e-12]
    return min(bad) - 1 if bad else 6
orders = {nm: order(TAB[nm]) for nm in TAB}
print("order from the trees:", ", ".join(f"{nm} {p}" for nm, p in orders.items()))
assert [orders[nm] for nm in TAB] == [1, 2, 2, 3, 3, 4, 2, 2]
m5 = misses(TAB["RK4"])[8:17]
print(f"RK4 on the 9 five-node trees: {sum(abs(m) > 1e-12 for m in m5)} missed, largest miss {sci(max(m5, key=abs))}")
print("stages s = 1..6, free numbers s(s+1)/2:", " ".join(str(s * (s + 1) // 2) for s in range(1, 7)))
g = {name(i): gamma(i) for i in range(len(trees))}; ga, gb = g["[[[[]]]]"], g["[[][[[]]]]"]
print(f"five-stage barrier: sum b_i (1 - c_i) a_ij a_jk c_k must be 1/{ga} - 1/{gb} = 1/{ga * gb // (gb - ga)}")
assert ga * gb == 120 * (gb - ga)
B7 = ([0, 1 / 3, 2 / 3, 1 / 3, 1 / 2, 1 / 2, 1], [[], [1 / 3], [0, 2 / 3], [1 / 12, 1 / 3, -1 / 12],   # Butcher's
      [-1 / 16, 9 / 8, -3 / 16, -3 / 8], [0, 9 / 8, -3 / 8, -3 / 4, 1 / 2],                       # 7 stages
      [9 / 44, -9 / 11, 63 / 44, 18 / 11, 0, -16 / 11]], [11 / 120, 0, 27 / 40, 27 / 40, -4 / 15, -4 / 15, 11 / 120])
print(f"Butcher's seven stages: order {order(B7)} from the trees, {sum(counts)} conditions met with {7 * 8 // 2} free numbers")
assert order(B7) == 6
print("exact at t = 2 s: height {:.6f} m, speed {:.6f} m/s".format(*exact(2)))
print("burn to t = 2 s, speed error (true error) at h = 0.2, 0.1, 0.05 s; slope readings at h = 0.05; observed order")
ex2 = exact(2)[1]
for nm in ("Euler", "Heun", "Kutta3", "RK4", "equal-b", "a32=1"):
    e = [ex2 - run(TAB[nm], rocket, [0, 0], hh, round(2 / hh))[1] for hh in (0.2, 0.1, 0.05)]
    obs = [math.log2(abs(e[i] / e[i + 1])) for i in range(2)]
    print(f"{nm:<8}{sci(e[0])} {sci(e[1])} {sci(e[2])}  readings {40 * len(TAB[nm][2])}  order {obs[0]:.2f} {obs[1]:.2f}")
    assert abs(obs[1] - orders[nm]) < 0.15        # the run agrees with the tree count
clock = lambda t, s: [3 * t * t]                  # y' = 3t^2, y(1) = 1: depends on t only
wrongc = ([0, 0.5, 0.5], K3[1], K3[2])           # Kutta3 with c3 copied wrong
for nm, tab in (("Kutta3", K3), ("Kutta3, c3 = 1/2", wrongc)):
    print(f"y' = 3t^2 to t = 1, h = 0.1, {nm}: y(1) = {run(tab, clock, [0], 0.1, 10)[0]:.9f}")
assert abs(run(K3, clock, [0], 0.1, 10)[0] - 1) < 1e-14 and abs(run(wrongc, clock, [0], 0.1, 10)[0] - 1) > 0.01
print(f"same Kutta3 rows on the rocket, h = 0.1: heights agree to {sci(abs(run(K3, rocket, [0, 0], 0.1, 20)[0] - run(wrongc, rocket, [0, 0], 0.1, 20)[0]))}")
def draw(i, x, y, out):                           # figure: leaves 22 apart, levels 26 up
    if not trees[i][1]: out.append((x, y)); return x + 22, x
    k = len(out); out.append(None); xs = []
    for j in trees[i][1]: x, cx = draw(j, x, y - 26, out); xs.append(cx)
    out[k] = ((xs[0] + xs[-1]) / 2, y); return x, out[k][0]
for i in range(8):
    pts = []; draw(i, 45 + 90 * (i % 4), 90 + 120 * (i // 4), pts)
    print(f"figure, tree {i + 1}:", " ".join(f"{px:.0f},{py:.0f}" for px, py in pts))
print("ALL CHECKS PASS")
