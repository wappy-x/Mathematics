# Line search, Armijo and Wolfe -- the check behind the card.  Nothing is
# imported.  The cost is the Rosenbrock banana f(x, y) = (1 - x)^2 + 100 (y - x^2)^2,
# minimised; the start is (-1.2, 1); the direction is straight downhill, d = -grad f.
C1, C2 = 1e-4, 0.9                    # sufficient-decrease and curvature constants

def f(p):
    x, y = p
    return (1 - x) * (1 - x) + 100 * (y - x * x) * (y - x * x)

def grad(p):                           # the slope in x and in y, by hand
    x, y = p
    return (-2 * (1 - x) - 400 * x * (y - x * x), 200 * (y - x * x))

def dot(a, b): return a[0] * b[0] + a[1] * b[1]
def move(p, a, d): return (p[0] + a * d[0], p[1] + a * d[1])
def yn(b): return "yes" if b else "no"

def checks(p, d, a, c1=C1, c2=C2):     # Armijo test, curvature test, new slope
    g0, q = grad(p), move(p, a, d)
    s0, s1 = dot(g0, d), dot(grad(q), d)
    return f(q) <= f(p) + c1 * a * s0, s1 >= c2 * s0, s1

def backtrack(p, d, c1=C1, cut=2):     # halve (or cut) until the Armijo test passes
    a, n = 1.0, 0
    while not checks(p, d, a, c1)[0]:
        a, n = a / cut, n + 1
    return a, n

def wolfe(p, d, c2=C2):                # bisection search for both Wolfe tests
    lo, hi, a, trials = 0.0, None, 1.0, []
    while True:
        arm, cur, _ = checks(p, d, a, C1, c2)
        trials.append(a)
        if not arm: hi = a
        elif not cur: lo = a
        else: return a, trials
        a = (lo + hi) / 2 if hi is not None else 2 * lo

x0 = (-1.2, 1.0)
g0 = grad(x0); d0 = (-g0[0], -g0[1]); slope0 = dot(g0, d0)
h = 1e-6                               # road 2 for the slope: central differences
cd = ((f((x0[0] + h, x0[1])) - f((x0[0] - h, x0[1]))) / (2 * h),
      (f((x0[0], x0[1] + h)) - f((x0[0], x0[1] - h))) / (2 * h))
print(f"start (-1.2, 1), cost {f(x0):.4f}; gradient ({g0[0]:.2f}, {g0[1]:.2f}); "
      f"by central differences ({cd[0]:.2f}, {cd[1]:.2f})")
print(f"direction d = ({d0[0]:.2f}, {d0[1]:.2f}); slope along d at step 0: {slope0:.2f}")
print("halvings  step              cost after   Armijo bar  Armijo  curvature")
for j in range(16):
    a = 0.5 ** j
    arm, cur, _ = checks(x0, d0, a)
    print(f"{j:>8}  1/{2 ** j:<6} {f(move(x0, a, d0)):>22.4f} {f(x0) + C1 * a * slope0:>11.4f}"
          f"  {yn(arm):>6}  {yn(cur):>9}")
a0, n0 = backtrack(x0, d0)
x1 = move(x0, a0, d0)
print(f"backtracking: {n0} halvings, step 1/{round(1 / a0)}, lands at ({x1[0]:.4f}, {x1[1]:.4f}), "
      f"cost {f(x1):.4f}")
# Road 2: phi(a) = f(x0 + a d0) as a quartic, coefficients built by polynomial algebra
u = [1 - x0[0], -d0[0]]                                   # 1 - x
v = [x0[1] - x0[0] ** 2, d0[1] - 2 * x0[0] * d0[0], -d0[0] ** 2]   # y - x^2
def pmul(p, q):
    out = [0.0] * (len(p) + len(q) - 1)
    for i, pi in enumerate(p):
        for k, qk in enumerate(q): out[i + k] += pi * qk
    return out
uu, vv = pmul(u, u), pmul(v, v)
phi = [vv[i] * 100 + (uu[i] if i < 3 else 0) for i in range(5)]
def pval(a): return sum(c * a ** i for i, c in enumerate(phi))
print("phi(a) coefficients, a^0..a^4: " + ", ".join(f"{c:.1f}" for c in phi))
lo, hi = 0.5 ** 12, 0.5 ** 6              # Armijo holds at lo, fails at hi
for _ in range(60):
    mid = (lo + hi) / 2
    if pval(mid) <= phi[0] + C1 * mid * phi[1]: lo = mid
    else: hi = mid
gap = max(abs(pval(0.5 ** j) - f(move(x0, 0.5 ** j, d0))) / f(move(x0, 0.5 ** j, d0)) for j in range(16))
print(f"phi'(0) = {phi[1]:.2f}; Armijo holds up to a = {lo:.7f} = 1/{1 / lo:.1f}; "
      f"quartic matches f to 1e-9: {yn(gap < 1e-9)}")
def descend(c1=C1, cut=2):             # gradient descent with backtracking, to |grad| < 1e-4; watch the sign of s.y
    p, k, evals, bad = x0, 0, 0, []
    while dot(grad(p), grad(p)) ** 0.5 >= 1e-4:
        g = grad(p); d = (-g[0], -g[1])
        a, n = backtrack(p, d, c1, cut); evals += n + 1
        q = move(p, a, d); gq = grad(q)
        if a * (dot(gq, d) - dot(g, d)) <= 0: bad.append(k)
        p, k = q, k + 1
    return p, k, evals, bad
p, k, evals, bad = descend()
print(f"descent + backtracking: {k} iterations, {evals} cost evaluations, ends at "
      f"({p[0]:.4f}, {p[1]:.4f}), cost {f(p):.11f}; steps with s.y <= 0: {bad}")
p = x0
for _ in range(bad[0]): g = grad(p); p = move(p, backtrack(p, (-g[0], -g[1]))[0], (-g[0], -g[1]))
g = grad(p); d = (-g[0], -g[1]); sl = dot(g, d)
a, n = backtrack(p, d); arm, cur, s1 = checks(p, d, a)
s = (a * d[0], a * d[1]); q = move(p, a, d); yv = (grad(q)[0] - g[0], grad(q)[1] - g[1])
sy, ss = dot(s, yv), dot(s, s)
print(f"step {bad[0]}: at ({p[0]:.4f}, {p[1]:.4f}), cost {f(p):.4f}, slope {sl:.2f}")
print(f"  Armijo step 1/{round(1 / a)}: cost {f(q):.4f}, new slope {s1:.2f}, "
      f"curvature {yn(cur)}, s.y = {sy:.2f}")
B = [[(i == j) - s[i] * s[j] / ss + yv[i] * yv[j] / sy for j in range(2)] for i in range(2)]
sBs = sum(s[i] * B[i][j] * s[j] for i in range(2) for j in range(2))
det = B[0][0] * B[1][1] - B[0][1] * B[1][0]
gq = grad(q); dn = (-(B[1][1] * gq[0] - B[0][1] * gq[1]) / det, -(B[0][0] * gq[1] - B[1][0] * gq[0]) / det)
print(f"  BFGS update from B = I: s.B.s = {sBs:.2f}; next direction "
      f"({dn[0]:.4f}, {dn[1]:.4f}), slope {dot(gq, dn):.2f} (uphill)")
aw, tr = wolfe(p, d); qw = move(p, aw, d)
syw = aw * (dot(grad(qw), d) - sl)
print("  Wolfe trials: " + ", ".join(f"{t:.5f}" for t in tr) +
      f"; accepted {aw:.5f}, cost {f(qw):.4f}, s.y = {syw:.2f}, "
      f"floor (1 - c2) a |slope| = {(1 - C2) * aw * -sl:.4f}")
# The three mistakes, and the fixed step for comparison
tiny = move(x0, 1e-6, d0); arm_t, cur_t, s_t = checks(x0, d0, 1e-6)
pf, kf = x0, 0
while dot(grad(pf), grad(pf)) ** 0.5 >= 1e-4:
    g = grad(pf); pf, kf = move(pf, -a0, g), kf + 1
print(f"mistake 1, no search, step 1: lands at ({x0[0] + d0[0]:.1f}, {x0[1] + d0[1]:.1f}), "
      f"cost {f(move(x0, 1, d0)):.1f}")
print(f"mistake 2, start at step 1e-6: cost {f(tiny):.4f}; Armijo {yn(arm_t)}, curvature {yn(cur_t)}"
      f" (slope {s_t:.2f} against bar {C2 * slope0:.2f})")
print(f"mistake 3, fixed step 1/1024 throughout: {kf} iterations, against {k} with backtracking")
# Try changing: c1 = 0.5; cutting the step by 10; c2 = 0.1 (the run above is unchanged)
a5, n5 = backtrack(x0, d0, 0.5)
print(f"try c1 = 0.5: first search {n5} halvings, step 1/{round(1 / a5)}, cost {f(move(x0, a5, d0)):.4f}; {descend(0.5)[1]} iterations")
a10 = backtrack(x0, d0, C1, 10)[0]; _, k10, _, bad10 = descend(C1, 10)
print(f"try cut by 10: first step 1/{round(1 / a10)}, cost {f(move(x0, a10, d0)):.4f}; {k10} iterations; steps with s.y <= 0: {bad10}")
fails = [j for j in range(16) if not checks(x0, d0, 0.5 ** j, C1, 0.1)[1]]
both = [j for j in range(16) if all(checks(x0, d0, 0.5 ** j, C1, 0.1)[:2])]
aw1 = wolfe(p, d, 0.1)[0]
print(f"try c2 = 0.1: curvature fails after halvings {fails}, both pass only after {both}; "
      f"step {bad[0]} Wolfe accepts {aw1:.5f}, floor {(1 - 0.1) * aw1 * -sl:.4f}")
print("figure, start (-1.2, 1); trials 7-10 at " +
      "; ".join(f"({move(x0, 0.5 ** j, d0)[0]:.3f}, {move(x0, 0.5 ** j, d0)[1]:.3f})" for j in range(7, 11)) +
      "; minimum (1, 1)")
assert abs(cd[0] - g0[0]) < 1e-4 and abs(cd[1] - g0[1]) < 1e-4    # slope: formula vs differences
assert n0 == 10 and 2 * a0 > lo >= a0                             # backtracking vs quartic boundary
assert gap < 1e-9 and abs(phi[1] - slope0) < 1e-6                 # quartic vs direct cost
assert checks(x0, d0, lo * (1 - 1e-6))[0] and not checks(x0, d0, hi * (1 + 1e-6))[0]  # direct test vs quartic
assert sy < 0 and abs(sBs - sy) < 1e-6 * abs(sy) and dot(gq, dn) > 0   # secant: s.B.s = s.y
assert syw >= (1 - C2) * aw * -sl > 0 and f(qw) < f(q)
assert arm_t and not cur_t and kf > 2 * k
print("ALL CHECKS PASS")
