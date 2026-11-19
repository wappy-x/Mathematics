# Hilbert's basis theorem -- the check behind the card.  Only exact fractions are
# imported.  A fair four-sided die has hidden faces x, y, z, w.  Equation n says
# the faces' n-th powers add to s_n = 1 + 2^n + 3^n + 4^n, for n = 1, 2, 3, ...
# Field: the rationals.  Order: lex, x > y > z > w (Python compares tuples in lex).
from fractions import Fraction as Q
FACES, NV, TOP, NAMES = (1, 2, 3, 4), 4, 12, "xyzw"

def s(n): return sum(f ** n for f in FACES)
def unit(i, n, nv=NV): return tuple(n if j == i else 0 for j in range(nv))
def eq(n):                                    # f_n = x^n + y^n + z^n + w^n - s_n
    p = {unit(i, n): Q(1) for i in range(NV)}
    p[(0,) * NV] = Q(-s(n))
    return p
def shift(m, a, sign=1): return tuple(u + sign * v for u, v in zip(m, a))
def addm(p, q, c, m):                         # p + c * (monomial m) * q
    out = dict(p)
    for e, a in q.items():
        k = shift(e, m)
        out[k] = out.get(k, 0) + c * a
        if out[k] == 0: del out[k]
    return out
def divides(a, b): return all(u <= v for u, v in zip(a, b))
def nf(p, G):                                 # the remainder of p on division by G
    p, r = dict(p), {}
    while p:
        m = max(p)                            # leading monomial
        g = next((g for g in G if divides(max(g), m)), None)
        if g is None: r[m] = p.pop(m); continue
        p = addm(p, g, -p[m] / g[max(g)], shift(m, max(g), -1))
    return r
def spoly(f, g):
    a, b = max(f), max(g); l = tuple(map(max, a, b))
    return addm(addm({}, f, 1 / f[a], shift(l, a, -1)), g, -1 / g[b], shift(l, b, -1))
def buchberger(F):
    G, pairs, checked, added = list(F), [(i, j) for j in range(len(F)) for i in range(j)], 0, []
    while pairs:
        i, j = pairs.pop(0); checked += 1
        r = nf(spoly(G[i], G[j]), G)
        if r:                                 # a new leading term: the chain grows
            pairs += [(k, len(G)) for k in range(len(G))]; G.append(r); added.append(max(r))
    keep = []
    for g in sorted(G, key=max):              # drop any whose leading term is divisible
        if not any(divides(max(h), max(g)) for h in keep): keep.append(g)
    red = [nf(g, [h for h in keep if h is not g]) for g in keep]
    return [{m: c / r[max(r)] for m, c in r.items()} for r in red][::-1], checked, added
def mono(m): return "*".join(NAMES[i] + (f"^{k}" if k > 1 else "") for i, k in enumerate(m) if k) or "1"
def show(p):
    out = ""
    for m in sorted(p, reverse=True):
        c = p[m]; body = mono(m) if any(m) else ""
        a = abs(c); txt = (f"{a}*{body}" if a != 1 else body) if body else f"{a}"
        out += (("-" if c < 0 else "") if not out else (" - " if c < 0 else " + ")) + txt
    return out
def h(d, k):                                  # every monomial of degree d in variables k..w
    if k == NV - 1: return [unit(k, d)]
    return [shift(unit(k, j), e) for j in range(d, -1, -1) for e in h(d - j, k + 1)]
def perms(t): return [t] if len(t) < 2 else [(t[i],) + r for i in range(len(t)) for r in perms(t[:i] + t[i + 1:])]
def ev(p, pt): return sum(c * Q(pt[0]) ** m[0] * Q(pt[1]) ** m[1] * Q(pt[2]) ** m[2] * Q(pt[3]) ** m[3] for m, c in p.items())

c = [Q(1)]                                    # coefficients of (t - 1)(t - 2)(t - 3)(t - 4)
for f in FACES: c = [a - f * b for a, b in zip(c + [0], [0] + c)]
c = [abs(a) for a in c]                       # e_0 .. e_4 of the faces
formula = [{} for _ in range(NV)]             # g_k = sum_j (-1)^j e_j h_(k-j)(x_k..w)
for k in range(1, NV + 1):
    for j in range(k + 1):
        for m in h(k - j, k - 1): formula[k - 1] = addm(formula[k - 1], {(0,) * NV: Q((-1) ** j) * c[j]}, 1, m)
G, checked, added = buchberger([eq(n) for n in range(1, 5)])
print(f"field Q, lex order x > y > z > w; true faces {list(FACES)}; e_1..e_4 = {[int(a) for a in c[1:]]}")
print(f"power sums s_1..s_{TOP}: {[s(n) for n in range(1, TOP + 1)]}")
print(f"Buchberger on f_1..f_4: {checked} pairs checked, {len(added)} remainders added, leading terms {', '.join(mono(m) for m in added)}")
for k, g in enumerate(G): print(f"g_{k + 1} = {show(g)}")
print(f"the closed formula gives the same four: {'yes' if G == formula else 'no'}")
grow = []
for k in range(1, 4):
    Gk = buchberger([eq(n) for n in range(1, k + 1)])[0]
    r = nf(eq(k + 1), Gk); grow.append(len(r))
    print(f"I_{k} < I_{k + 1}: f_{k + 1} leaves a remainder of {len(r)} terms, leading {mono(max(r))}")
rest = [len(nf(eq(n), G)) for n in range(5, TOP + 1)]
print(f"f_5..f_{TOP} on division by g_1..g_4 leave remainder sizes {rest}")
rec = all(s(n) == c[1] * s(n - 1) - c[2] * s(n - 2) + c[3] * s(n - 3) - c[4] * s(n - 4) for n in range(5, TOP + 1))
print(f"the strong-induction step s_n = 10 s_(n-1) - 35 s_(n-2) + 50 s_(n-3) - 24 s_(n-4), n = 5..{TOP}: {'yes' if rec else 'no'}")
std = [m for a in range(5) for b in range(5) for cc in range(5) for d in range(5)
       if not any(divides(max(g), m := (a, b, cc, d)) for g in G)]
dice = perms(FACES)
ok = all(ev(p, t) == 0 for t in dice for p in G + [eq(n) for n in range(1, TOP + 1)])
print(f"monomials under the staircase x, y^2, z^3, w^4: {len(std)}; orderings of 1, 2, 3, 4: {len(dice)}; all satisfy every equation: {'yes' if ok else 'no'}")
S = {(a, b) for a in range(31) for b in range(31) if a * b >= 6}
corners = sorted(m for m in S if not any(n != m and divides(n, m) for n in S))
a0, b0 = 2, 3                                 # Dickson's proof: one member, then finitely many rows and columns
picked = {(a0, b0)} | {(min(a for a in range(31) if (a, b) in S), b) for b in range(b0) if any((a, b) in S for a in range(31))}
picked |= {(a, min(b for b in range(31) if (a, b) in S)) for a in range(a0) if any((a, b) in S for b in range(31))}
dickson = sorted(m for m in picked if not any(n != m and divides(n, m) for n in picked))
print(f"monomials x^a y^b with a*b >= 6: corners {corners}; Dickson's proof from (2, 3) finds {dickson}")
print(f"figure, corners {' '.join(f'{a},{b}' for a, b in corners)}; curve a*b = 6 through (1,6) (1.5,4) (2,3) (3,2) (4,1.5) (6,1)")
w = Q(3, 2); P = [None, s(1) - w, s(2) - w ** 2, s(3) - w ** 3]   # mistake 1: only three moments
e1 = P[1]; e2 = (e1 * P[1] - P[2]) / 2; e3 = (e2 * P[1] - e1 * P[2] + P[3]) / 3
p4 = e1 * P[3] - e2 * P[2] + e3 * P[1] + w ** 4
print(f"mistake 1, three moments only: faces 3/2, 7/2, (5 - 6^(1/2))/2 = {(5 - 6 ** 0.5) / 2:.4f}, "
      f"(5 + 6^(1/2))/2 = {(5 + 6 ** 0.5) / 2:.4f}; cubic t^3 - {e1} t^2 + {e2} t - {e3} = (t - 7/2)(t^2 - {e1 - Q(7, 2)} t + {e3 / Q(7, 2)}); "
      f"fourth sum {p4} = {float(p4)}, not {s(4)}")
chain = [len(nf({unit(n, 1, 9): Q(1)}, [{unit(i, 1, 9): Q(1)} for i in range(n)])) for n in range(1, 9)]
print(f"mistake 2, endless variables x_1, x_2, ...: x_(n+1) outside <x_1..x_n> for n = 1..8, remainder sizes {chain}")
r, g, steps = {2: 1}, {1: 1, 2: -1}, []       # mistake 3: lowest degree leads; divide x^2 by x - x^2
for _ in range(5):
    m = min(r); q = r.pop(m) // g[1]          # the "leading" term is the lowest power
    for e, a in g.items():
        if e > 1: r[e + m - 1] = r.get(e + m - 1, 0) - q * a
    steps.append(f"{r[min(r)]}*x^{min(r)}" if r[min(r)] != 1 else f"x^{min(r)}")
print(f"mistake 3, lowest-degree-first order, x^2 divided by x - x^2: remainders {' -> '.join(steps)} -> ... never ends")
assert G == formula and [mono(max(g)) for g in G] == ["x", "y^2", "z^3", "w^4"]   # two roads, one basis
assert min(grow) > 0 and rest == [0] * (TOP - 4) and rec                             # chain stops at 4
assert len(std) == len(dice) == 24 and ok and ev(eq(1), (1, 2, 3, 5)) == 1   # substitution
assert corners == dickson == [(1, 6), (2, 3), (3, 2), (6, 1)] and min(chain) == 1 and steps[-1] == "x^7"
assert (e1, e2, e3) == (Q(7, 2) + 5, Q(19, 4) + Q(35, 2), Q(7, 2) * Q(19, 4)) and p4 == Q(1401, 4)
print("ALL CHECKS PASS")
