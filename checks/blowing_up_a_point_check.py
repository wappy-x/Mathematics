# Blowing up a point -- the check behind the card.  Standard library only.
# A curve F(x, y) = 0 over Q is a dict {(i, j): c} for its terms c x^i y^j.
# Blowing up the origin in the chart y = t x turns x^i y^j into x^(i+j) t^j;
# dividing out x^m, m the lowest degree present, leaves the strict transform.

def show(F, a="x", v="y"):                     # lex order, second letter first
    out = ""
    for (i, j), c in sorted(F.items(), key=lambda k: (-k[0][1], -k[0][0])):
        mono = (f"{a}^{i}" if i > 1 else a if i else "") + (f"{v}^{j}" if j > 1 else v if j else "")
        mag = str(abs(c)) if abs(c) != 1 or not mono else ""
        out += (" - " if c < 0 else " + ") + mag + mono
    return out[3:] if out[1] == "+" else "-" + out[3:]

def add(F, k, c):
    F[k] = F.get(k, 0) + c
    if F[k] == 0: del F[k]

def mult(F): return min(i + j for i, j in F)
def ev(F, a, b): return sum(c * a**i * b**j for (i, j), c in F.items())
def swap(F): return {(j, i): c for (i, j), c in F.items()}
def blow(F, m): return {(i + j - m, j): c for (i, j), c in F.items()}   # chart y = t x
def deriv(F, k):                               # k = 0: d/dx, k = 1: d/d(second letter)
    D = {}
    for (i, j), c in F.items():
        e = (i, j)[k]
        if e: add(D, (i - 1 + k, j - k), c * e)
    return D

def shift(F, r):                               # F(x, t + r), by Pascal's triangle
    G = {}
    for (i, j), c in F.items():
        row = [1]
        for _ in range(j): row = [1] + [row[n] + row[n + 1] for n in range(len(row) - 1)] + [1]
        for k in range(j + 1): add(G, (i, k), c * row[k] * r**(j - k))
    return G

def directions(F, m):                          # integer roots t of F_m(1, t)
    cone = {(0, j): c for (i, j), c in F.items() if i + j == m}
    assert cone.get((0, m)) == 1               # monic: no vertical direction, rational roots are integers
    H = max(abs(c) for c in cone.values()) + 1
    return [r for r in range(-H, H + 1) if ev(cone, 0, r) == 0]

def order(C, r):                               # how many times t = r is a root of C(0, t)
    k = 0
    while ev(C, 0, r) == 0: C, k = deriv(C, 1), k + 1
    return k

def resolve(F, pad="  "):                      # blow up until smooth: (blow-ups, sum m(m-1)/2, branches)
    m = mult(F)
    if m == 1: return 0, 0, 1
    G, roots = blow(F, m), directions(F, m)
    print(f"{pad}m = {m}, strict transform {show(G, 'x', 't')}, meets E at t = {roots}")
    on_E = {k: c for k, c in G.items() if k[0] == 0}   # strict transform at x = 0: F_m(1, t)
    assert sum(order(on_E, r) for r in roots) == m     # all m slopes found, with repeats: none irrational
    totals = [1, m * (m - 1) // 2, 0]
    for r in roots:
        totals = [s + n for s, n in zip(totals, resolve(shift(G, r), pad + "  "))]
    return tuple(totals)

def sing(F, p):                                # points over F_p where F and both slopes vanish
    return [(a, b) for a in range(p) for b in range(p)
            if all(ev(P, a, b) % p == 0 for P in (F, deriv(F, 0), deriv(F, 1)))]

def count(F, p): return sum(ev(F, a, b) % p == 0 for a in range(p) for b in range(p))

F = {(0, 2): 1, (3, 0): -1, (2, 0): -1}        # the nodal cubic y^2 = x^2(x + 1)
m = mult(F)
G = blow(F, m)
print(f"curve {show(F)} = 0 over Q; multiplicity at (0, 0): m = {m}")
print(f"chart y = t x: F(x, t x) = x^{m} * ({show(G, 'x', 't')})")
roots = directions(F, m)
print(f"strict transform meets E (x = 0) at t = {roots}, the two tangent slopes")
for r in roots:
    print(f"  at (0, {r}): gradient ({ev(deriv(G, 0), 0, r)}, {ev(deriv(G, 1), 0, r)}), not zero: smooth")
G2 = blow(swap(F), m)                          # chart x = s y: letters (s, y)
print(f"chart x = s y: strict transform {show(swap(G2), 's', 'y')}; on E (y = 0) "
      f"s = {[s for s in range(-2, 3) if ev(G2, 0, s) == 0]}, "
      f"so s = 1/t; vertical s = 0 gives {ev(G2, 0, 0)}")
X, Y = {2: 1, 0: -1}, {3: 1, 1: -1}            # road 2: lines y = t x through the node
def pmul(A, B):
    C = {}
    for a, u in A.items():
        for b, w in B.items(): C[a + b] = C.get(a + b, 0) + u * w
    return {k: c for k, c in C.items() if c}
def ppow(A, n):
    out = {0: 1}
    for _ in range(n): out = pmul(out, A)
    return out
sub = {}
for (i, j), c in F.items():
    for k, w in pmul(ppow(X, i), ppow(Y, j)).items(): sub[k] = sub.get(k, 0) + c * w
sub = {k: w for k, w in sub.items() if w}
over = [t for t in range(-3, 4) if ev({(i, 0): c for i, c in X.items()}, t, 0) == 0
        and ev({(i, 0): c for i, c in Y.items()}, t, 0) == 0]
print(f"road 2: x = t^2 - 1, y = t^3 - t; F(x(t), y(t)) has {len(sub)} nonzero coefficients; "
      f"parameters at the node t = {over}")
p, Gp = 7, blow(F, 2)                          # road 3: count over F_7
image = {(a, a * b % p) for a in range(p) for b in range(p) if ev(Gp, a, b) % p == 0}
print(f"over F_{p}: curve {count(F, p)} points, singular {sing(F, p)}; strict transform "
      f"{count(Gp, p)} points, singular {sing(Gp, p)}; image of (x, t) -> (x, t x): {len(image)} points")
print("resolving, chart by chart:")
chains = [("node", F), ("cusp", {(0, 2): 1, (3, 0): -1}),
          ("tacnode", {(0, 2): 1, (4, 0): -1, (5, 0): -1}), ("y^2 = x^5", {(0, 2): 1, (5, 0): -1}),
          ("triple point", {(0, 3): 1, (2, 1): -1, (4, 0): 1})]
results = {}
for name, C in chains:
    print(f"{name}: {show(C)}")
    results[name] = resolve(C)
    print(f"  -> blow-ups {results[name][0]}, sum of m(m - 1)/2 = {results[name][1]}, branches {results[name][2]}")
print(f"genus of the nodal cubic: (3 - 1)(3 - 2)/2 - sum = 1 - {results['node'][1]} = {1 - results['node'][1]}")
T, once = {(2, 2): 1, (3, 0): -1, (2, 0): -1}, {(1, 2): 1, (2, 0): -1, (1, 0): -1}
smooth_pt = swap(shift(swap(F), -1))           # F moved so (-1, 0) sits at the origin
K = {(0, 2): 1, (3, 0): -1, (2, 0): -2}
print(f"mistake 1, keep the total transform {show(T, 'x', 't')}: {len(sing(T, 7))} singular points over F_7")
print(f"mistake 2, divide by x once, {show(once, 'x', 't')}: {len(sing(once, 7))} singular points over F_7")
print(f"mistake 3, blow up the smooth point (-1, 0): m = {mult(smooth_pt)}; node still singular: "
      f"{'yes' if (0, 0) in sing(F, 7) else 'no'}")
print(f"mistake 4, {show(K)} over Q: rational points over the node {directions(K, 2)}; "
      f"slopes are +-{2 ** 0.5:.12g}")
q = 11
print(f"over F_{q}: curve {count(F, q)} points, strict transform {count(blow(F, 2), q)} points")
a, b = 3, 2                                    # figure: the parameter t = a/b = 3/2 ends both drawings
xe, ye = f"{a * a - b * b}/{b * b}", f"{a ** 3 - a * b * b}/{b ** 3}"
print(f"figure, node (0, 0); loop end (-1, 0); arm ends ({xe}, -{ye}), ({xe}, {ye}); "
      f"over the node (0, -1), (0, 1); parabola ends ({xe}, -{a}/{b}), ({xe}, {a}/{b})")
assert G == {(0, 2): 1, (1, 0): -1, (0, 0): -1} and roots == [-1, 1]      # t^2 - x - 1, slopes -1, 1
assert sub == {} and over == [-1, 1]           # the parametrisation lies on F; two parameters at the node
assert count(F, 7) == len(image) == count(Gp, 7) - 1 and sing(Gp, 7) == [] and sing(F, 7) == [(0, 0)]
assert [results[n] for n, _ in chains] == [(1, 1, 2), (1, 1, 1), (2, 2, 2), (2, 2, 1), (1, 3, 3)]
assert len(sing(T, 7)) == 7 and len(sing(once, 7)) == 2 and directions(K, 2) == []
print("ALL CHECKS PASS")
