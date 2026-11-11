# Local minima are global when convex -- the check behind the card.  Nothing is
# imported.  A roaster blends Brazil, Colombia and Sumatra beans.  The shares
# x = (xB, xC, xE) add to 1, the blend's strength score must reach 7, and each
# bean's price per kilo climbs 50p for every tenth of the blend it supplies.
BASE, RISE, SCORE, NEED = (6.0, 9.0, 11.0), 5.0, (5, 6, 9), 7
FLAT = (9.5, 11.0, 15.5)                      # a second quote: flat prices, no rise
E, P, Q = (0.0, 0.0, 1.0), (0.5, 0.0, 0.5), (0.0, 2 / 3, 1 / 3)   # corners of the allowed set

def cost(x): return sum(a * v + RISE * v * v for a, v in zip(BASE, x))   # pounds a kilo
def flat(x): return sum(p * v for p, v in zip(FLAT, x))
def strength(x): return sum(s * v for s, v in zip(SCORE, x))
def allowed(x, need=NEED, least=0.0):         # least > 0: the minimum-order rule
    if min(x) < -1e-12 or strength(x) < need - 1e-12: return False
    return not any(1e-12 < v < least - 1e-12 for v in x)
def mix(x, y, th): return tuple(th * a + (1 - th) * b for a, b in zip(x, y))
def edge(c): return ((2 - 3 * c) / 4, c, (2 - c) / 4)   # strength exactly 7, Colombia share c
def show(x): return "(" + ", ".join(f"{v:.3f}" for v in x) + ")"

MOVES = [tuple(1.0 if k == i else -1.0 if k == j else 0.0 for k in range(3))
         for i in range(3) for j in range(3) if i != j]          # six swaps between two beans
MOVES += [(-0.75, 1.0, -0.25), (0.75, -1.0, 0.25)]                # two moves along strength 7

def compass(x, need=NEED, least=0.0):         # road 1: compass search, looks only nearby
    h, steps = 0.1, 0
    while h > 1e-7:
        tries = [tuple(v + h * d for v, d in zip(x, m)) for m in MOVES]
        tries = [y for y in tries if allowed(y, need, least) and cost(y) < cost(x) - 1e-15]
        if tries:
            x, steps = min(tries, key=cost), steps + 1
        else:
            h /= 2                            # nothing nearby is cheaper: look closer
    return x, steps

def grid(n, least=0.0, price=cost):           # road 4: every blend in steps of 1/n
    pts = [(i / n, j / n, (n - i - j) / n) for i in range(n + 1) for j in range(n + 1 - i)]
    pts = [x for x in pts if allowed(x, NEED, least)]
    best = min(price(x) for x in pts)
    return best, [x for x in pts if price(x) < best + 1e-9], len(pts)

print("bean prices at zero share, pounds a kilo:", BASE, f"; rise per tenth of the blend: {RISE / 10:.2f}")
print("strength scores:", SCORE, "; the blend needs at least", NEED)
print("corners of the allowed set: E", show(E), "P", show(P), "Q", show(Q))
print("cost at the corners:", f"{cost(E):.3f}, {cost(P):.3f}, {cost(Q):.3f}")
runs = []
for name, start in (("E", E), ("P", P), ("Q", Q)):
    x, n = compass(start)
    runs.append(x)
    print(f"compass search from {name}: {show(x)} cost {cost(x):.3f} after {n} moves")
xs = runs[0]
c0, c1, c2 = cost(edge(0.0)), cost(edge(1 / 3)), cost(edge(2 / 3))   # road 2: by hand on the edge
A = (c2 - 2 * c1 + c0) * 9 / 2                # cost along the edge = c0 + B c + A c^2
B = (c1 - c0) * 3 - A / 3
cv = -B / (2 * A)
print(f"along the strength-7 edge: cost = {c0:.3f} + ({B:.3f}) xC + {A:.3f} xC^2")
print(f"slope zero at xC = {cv:.3f}: blend {show(edge(cv))} cost {cost(edge(cv)):.3f}")
print(f"at x*: base part {sum(a * v for a, v in zip(BASE, xs)):.3f}, rise part "
      f"{sum(RISE * v * v for v in xs):.3f}")
g = tuple(a + 2 * RISE * v for a, v in zip(BASE, xs))   # road 3: the certificate
hd = 1e-5
gd = [(cost(tuple(v + (hd if k == i else 0) for k, v in enumerate(xs)))
       - cost(tuple(v - (hd if k == i else 0) for k, v in enumerate(xs)))) / (2 * hd) for i in range(3)]
cert = [sum(gi * (ci - xi) for gi, ci, xi in zip(g, c, xs)) for c in (E, P, Q)]
print("gradient at x*:", show(g), "; by central difference:", show(gd))
print("slope from x* toward E, P, Q:", ", ".join(f"{round(v, 9) + 0.0:.3f}" for v in cert))
best, arg, npts = grid(200)
print(f"every allowed blend in steps of 1/200: {npts} blends, cheapest {best:.3f} at {show(arg[0])}")
for th in (0.9, 0.5):                         # the chord bound on the segment from x* to E
    m = mix(xs, E, th)
    print(f"{th:.0%} x* + {1 - th:.0%} E = {show(m)}, strength {strength(m):.3f}, "
          f"cost {cost(m):.3f}, chord {th * cost(xs) + (1 - th) * cost(E):.3f}")
print(f"flat quote at P, Q, their midpoint, E: {flat(P):.3f}, {flat(Q):.3f}, "
      f"{flat(mix(P, Q, 0.5)):.3f}, {flat(E):.3f}")
print("flat quote minus 2, divided by 1.5:", show([(p - 2) / 1.5 for p in FLAT]), "= the strength scores")
fbest, ties, _ = grid(60, price=flat)
print(f"flat quote, every blend in steps of 1/60: {len(ties)} tie at {fbest:.3f}, "
      f"strengths {min(strength(x) for x in ties):.3f} to {max(strength(x) for x in ties):.3f}")
print("cost along the edge, xC = 0 to 0.6:", ", ".join(f"{cost(edge(k / 10)):.3f}" for k in range(7)))
print("flat quote along the edge:         ", ", ".join(f"{flat(edge(k / 10)):.3f}" for k in range(7)))
u, _ = compass(E, need=0)                     # what breaks 1: the strength rule dropped
gu = tuple(a + 2 * RISE * v for a, v in zip(BASE, u))   # gradient at the dip: equal entries, not zero
print(f"mistake 1, no strength rule: {show(u)} cost {cost(u):.3f}, strength {strength(u):.3f}, gradient {show(gu)}")
s1, _ = compass(E, least=0.4)                 # what breaks 2 and 3: the 40% minimum order
s2, _ = compass((0.0, 0.4, 0.6), least=0.4)
r_best, r_arg, _ = grid(200, least=0.4)
print(f"mistake 2, 40% rule, search from E: stuck at {show(s1)} cost {cost(s1):.3f}")
print(f"mistake 3, 40% rule, search from (0, 0.4, 0.6): stuck at {show(s2)} cost {cost(s2):.3f}")
print(f"40% rule, every allowed blend in steps of 1/200: cheapest {r_best:.3f} at {show(r_arg[0])}")
m = mix(E, P, 0.9)
print(f"the broken step: 90% E + 10% P = {show(m)} cost {cost(m):.3f}, "
      f"allowed under the 40% rule: {'yes' if allowed(m, NEED, 0.4) else 'no'}")
print("figure, E (0, 0), P (0.5, 0), Q (0, 0.667), x* (0.35, 0.2), dip",
      f"({u[0]:.2f}, {u[1]:.2f}), in (xB, xC)")

assert all(max(abs(a - b) for a, b in zip(r, (0.35, 0.2, 0.45))) < 1e-5 for r in runs)
assert abs(cv - 0.2) < 1e-9 and abs(cost(edge(cv)) - cost(xs)) < 1e-9      # by hand = search
assert min(cert) > -1e-6 and max(abs(a - b) for a, b in zip(g, gd)) < 1e-6  # certificate
assert abs(best - cost(xs)) < 1e-9 and arg == [(0.35, 0.2, 0.45)]          # enumeration
assert len(ties) == 11 and all(abs(strength(x) - NEED) < 1e-9 for x in ties)
assert abs(cost(u) - 9.7) < 1e-9 and strength(u) < NEED                    # the dip is not allowed
assert max(gu) - min(gu) < 1e-6 and min(gu) > 0          # its gradient: level along every swap, yet not zero
assert cost(s1) > cost(s2) > r_best + 1 and not allowed(m, NEED, 0.4) and cost(m) < cost(E)
print("ALL CHECKS PASS")
