# Embedded pairs on a model rocket's climb: where the Dormand-Prince weights come from,
# and what a tolerance does and does not control.  Standard library only.
# Road 1, exact fractions: each rooted tree with up to 5 nodes gives one linear order
#   condition, sum of b_i Phi_i(tree) = 1/gamma(tree); solving them gives the weights.
# Road 2, closed form: the climb is tanh while the motor burns and tan while it coasts,
#   checked against the adaptive solver that runs on the weights from road 1.
from fractions import Fraction as Q
from math import sqrt, tanh, tan, atan, cosh, cos, log, log10, prod
A = [[], [Q(1, 5)], [Q(3, 40), Q(9, 40)], [Q(44, 45), Q(-56, 15), Q(32, 9)],
     [Q(19372, 6561), Q(-25360, 2187), Q(64448, 6561), Q(-212, 729)],
     [Q(9017, 3168), Q(-355, 33), Q(46732, 5247), Q(49, 176), Q(-5103, 18656)],
     [Q(35, 384), Q(0), Q(500, 1113), Q(125, 192), Q(-2187, 6784), Q(11, 84)]]
S, FREE = 7, [0, 1, 2, 3, 4, 5, 6]         # seven stages, all seven weights free
C = [sum(row, Q(0)) for row in A]           # stage times c_i, as fractions of the step
def forests(n):                             # every sorted list of trees with n nodes in all
    out = set() if n else {()}
    for k in range(1, n + 1):
        for t in trees(k):
            for f in forests(n - k): out.add(tuple(sorted(f + (t,))))
    return sorted(out)
def trees(n): return ["[" + "".join(f) + "]" for f in forests(n - 1)]
def kids(s):                                # the subtrees hanging from the root
    out, depth, start = [], 0, 1
    for i in range(1, len(s) - 1):
        depth += 1 if s[i] == "[" else -1
        if depth == 0: out.append(s[start:i + 1]); start = i + 1
    return out
def phi(s):                                 # Phi_i(tree) for every stage i
    v = [Q(1)] * S
    for k in kids(s):
        p = phi(k)
        v = [v[i] * sum((A[i][j] * p[j] for j in range(i)), Q(0)) for i in range(S)]
    return v
def gamma(s): return s.count("[") * prod(gamma(k) for k in kids(s))
def conditions(p): return [[phi(t)[j] for j in FREE] + [Q(1, gamma(t))] for n in range(1, p + 1) for t in trees(n)]
def solve(rows):                            # exact Gauss-Jordan: rank, and weights if unique
    M, rk = [r[:] for r in rows], 0
    for col in range(len(FREE)):
        piv = next((r for r in range(rk, len(M)) if M[r][col] != 0), None)
        if piv is None: continue
        M[rk], M[piv] = M[piv], M[rk]
        p = M[rk][col]; M[rk] = [x / p for x in M[rk]]
        for r in range(len(M)):
            if r != rk and M[r][col] != 0:
                f = M[r][col]; M[r] = [a - f * b for a, b in zip(M[r], M[rk])]
        rk += 1
    assert all(r[-1] == 0 for r in M[rk:])  # the conditions do not contradict each other
    w = [Q(0)] * S
    if rk == len(FREE):
        for i, j in enumerate(FREE): w[j] = M[i][-1]
    return rk, w
def miss(w, t): return sum((wi * pi for wi, pi in zip(w, phi(t))), Q(0)) - Q(1, gamma(t))
fr = lambda w: ", ".join(str(x) for x in w)
print("trees with 1..5 nodes:", " ".join(str(len(trees(n))) for n in range(1, 6)))
r4, r5 = solve(conditions(4))[0], solve(conditions(5))
print(f"order 4: {len(conditions(4))} conditions, rank {r4}; order 5: {len(conditions(5))} conditions, rank {r5[0]}")
w5 = r5[1]
print("order-5 weights b:", fr(w5))
assert w5 == A[6] + [Q(0)]                  # the published fifth-order weights, b_7 = 0
w4 = solve(conditions(4) + [[Q(0)] * 6 + [Q(1), Q(1, 40)]])[1]
print("order-4 weights with bhat_7 = 1/40:", fr(w4))
assert w4 == [Q(5179, 57600), 0, Q(7571, 16695), Q(393, 640), Q(-92097, 339200), Q(187, 2100), Q(1, 40)]
print(f"bhat misses order 5: bushy tree {miss(w4, '[[][][][]]')}, tall tree {miss(w4, '[[[[[]]]]]')}")
print(f"bhat misses order 5 on {sum(1 for t in trees(5) if miss(w4, t) != 0)} of 9 trees; b on {sum(1 for t in trees(5) if miss(w5, t) != 0)}")
# ---- the rocket: 50 m/s^2 of thrust for 1.5 s, gravity, drag 0.00225 v^2 per metre ----
Af = [[float(x) for x in row] for row in A]; Cf = [float(x) for x in C]
B5, B4 = [float(x) for x in w5], [float(x) for x in w4]
G, THRUST, TB, K = 9.81, 50.0, 1.5, 0.00225
print(f"stage times c: {fr(C)}; rocket: thrust {THRUST} m/s^2 for {TB} s, gravity {G} m/s^2, drag {K} v^2 per metre")
def rate(on, y): return [y[1], (THRUST if on else 0.0) - G - K * y[1] * abs(y[1])]
def dot(w, k, n):
    s = 0.0
    for a, q in zip(w, k): s += a * q[n]
    return s
def pair(t, y, h, blind, b4):               # one step: fifth-order and fourth-order answers
    k = []
    for i in range(S):
        yi = [y[n] + h * dot(Af[i], k, n) for n in range(2)]
        k.append(rate((t + Cf[i] * h < TB) if blind else (t < TB), yi))
    return [y[n] + h * dot(B5, k, n) for n in range(2)], [y[n] + h * dot(b4, k, n) for n in range(2)]
def exact(t):                               # closed form, valid until the top at 6.26 s
    a = THRUST - G; w1, v1 = sqrt(a * K), sqrt(a / K)
    if t <= TB: return [log(cosh(w1 * t)) / K, v1 * tanh(w1 * t)]
    yb, vb = log(cosh(w1 * TB)) / K, v1 * tanh(w1 * TB)
    w, vg = sqrt(G * K), sqrt(G / K); ph = atan(vb / vg); s = t - TB
    return [yb + log(cos(ph - w * s) / cos(ph)) / K, vg * tan(ph - w * s)]
def ratio(y, y5, y4, tol):                  # worst gap over its allowance tol (1 + size)
    e = 0.0
    for n in range(2): e = max(e, abs(y5[n] - y4[n]) / (tol * (1 + max(abs(y[n]), abs(y5[n])))))
    return e
def run(tol, unit=False, keep5=True, blind=False, b4=B4, T=6.0, h=0.1):
    t, y, ends, lens, path, rej = 0.0, [0.0, 0.0], [], [], [], 0
    while t < T - 1e-12:
        hs = min(h, T - t, TB - t) if (t < TB and not blind) else min(h, T - t)
        y5, y4 = pair(t, y, hs, blind, b4)
        err = ratio(y, y5, y4, tol) / (hs if unit else 1.0)
        fac = 5.0 if err == 0 else min(5.0, max(0.2, 0.9 * (1 / err) ** (0.25 if unit else 0.2)))
        if err <= 1:
            t += hs; y = y5 if keep5 else y4; ends.append(t); lens.append(hs); path.append(y)
            h = max(h, hs * fac) if hs < h else hs * fac
        else: rej += 1; h = hs * fac
    return y, ends, lens, rej, path
def sci(x, d=3): m, e = f"{x:.{d}e}".split("e"); return f"{m}e{int(e)}"
def err6(y): return [y[0] - exact(6.0)[0], y[1] - exact(6.0)[1]]
yb, vb = exact(TB)
print(f"burnout, exact: height {yb:.6f} m, speed {vb:.6f} m/s; top at {TB + atan(vb / sqrt(G / K)) / sqrt(G * K):.4f} s")
y5, y4 = pair(TB, [yb, vb], 1.0, False, B4); ex = exact(TB + 1.0)
print(f"by hand, h = 1 s from burnout: fifth {y5[0]:.6f} m, {y5[1]:.6f} m/s; fourth {y4[0]:.6f} m, {y4[1]:.6f} m/s")
print(f"gaps {sci(y4[0] - y5[0])} m, {sci(y4[1] - y5[1])} m/s; allowances {sci(1e-6 * (1 + y5[0]))}, {sci(1e-6 * (1 + vb))}")
e = ratio([yb, vb], y5, y4, 1e-6)
print(f"worst ratio {e:.4f}: rejected; next try {min(5.0, max(0.2, 0.9 * (1 / e) ** 0.2)):.4f} s")
print(f"true errors at 2.5 s: fourth {sci(y4[0] - ex[0])} m, {sci(y4[1] - ex[1])} m/s; fifth {sci(y5[0] - ex[0])} m, {sci(y5[1] - ex[1])} m/s")
assert abs((y4[0] - y5[0]) / (y4[0] - ex[0]) - 1) < 0.05
y, ends, lens, rej, path = run(1e-6, blind=True)
i = next(j for j, t in enumerate(ends) if t > TB); yi = path[i]
print(f"blind, tol 1e-6: kept {len(ends)}, rejected {rej}, steps {min(lens):.5f} s to {max(lens):.4f} s")
print(f"blind: speed error after the burnout step {sci(yi[1] - exact(ends[i])[1])} m/s; at 6 s {sci(err6(y)[0])} m, {sci(err6(y)[1])} m/s")
print("figure, step ends t:", ", ".join(f"{t:.3f}" for t in ends))
print("figure, log10 step:", ", ".join(f"{log10(x):.2f}" for x in lens))
yl, el, ll, rl, _ = run(1e-6)
print(f"landing on burnout: kept {len(el)}, rejected {rl}; at 6 s {sci(err6(yl)[0])} m, {sci(err6(yl)[1])} m/s")
assert abs(err6(yl)[1]) * 100 < abs(err6(y)[1]) and abs(err6(yl)[0]) < 1e-4 and (len(el), rl) == (10, 0)
tols, slopes = [1e-4, 1e-5, 1e-6, 1e-7, 1e-8, 1e-9, 1e-10], {}
print("figure, log10 tol:", ", ".join(f"{log10(t):.2f}" for t in tols))
for unit in (False, True):
    for keep5 in (True, False):
        name = ("per unit step" if unit else "per step") + (", keep 5th" if keep5 else ", keep 4th")
        res = [run(tol, unit, keep5) for tol in tols]
        ys = [log10(abs(err6(r[0])[0])) for r in res]
        xm, ym = sum(log10(t) for t in tols) / 7, sum(ys) / 7
        sl = sum((log10(t) - xm) * (v - ym) for t, v in zip(tols, ys)) / sum((log10(t) - xm) ** 2 for t in tols)
        slopes[(unit, keep5)] = sl; assert len(res[-1][1]) == (81 if unit else 49)   # steps at 1e-10, quoted on the card
        th = (5 / 4 if unit else 1.0) if keep5 else (1.0 if unit else 4 / 5)   # Why it works, Step 5
        print(f"{name}: steps {' '.join(str(len(r[1])) for r in res)}; slope {sl:.2f}, theory {th:.2f}")
        print(f"  height error at 6 s: {' '.join(sci(err6(r[0])[0], 2) for r in res)}")
        print(f"  figure, log10 error: {', '.join(f'{v:.2f}' for v in ys)}")
assert 0.7 < slopes[(False, False)] < 0.9 and 0.85 < slopes[(True, False)] < 1.15 and 0.85 < slopes[(False, True)] < 1.15
yz, ez = run(1e-6, b4=B5)[:2]
print(f"breaks: bhat = b, so every estimate is 0: kept {len(ez)}, height error {sci(err6(yz)[0])} m")
print("ALL CHECKS PASS")
