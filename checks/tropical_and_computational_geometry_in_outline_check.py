# Tropical geometry and computation -- the check behind the card.  Nothing is imported.
# Min-plus: a (+) b = min(a, b), a (.) b = a + b.  Roads to the tropical line: ties of the
# minimum, a walk round a box, Laurent series in t, the Newton triangle's normals.  Roads
# to the blow-up: Buchberger over F_p written out, against Bezout and standard monomials.
def winners(X, Y, terms, pick=min):             # which terms reach the minimum
    v = [c + i * X + j * Y for c, i, j in terms]
    return [k for k, a in enumerate(v) if a == pick(v)]
LINE = [(0, 0, 0), (-2, 1, 0), (-1, 0, 1)]      # (coefficient, power of x, power of y)
def ladd(*fs):                                  # Laurent polynomials in t: {exponent: integer}
    out = {}
    for f in fs:
        for e, c in f.items(): out[e] = out.get(e, 0) + c
    return {e: c for e, c in out.items() if c}
def lmul(f, g): return ladd(*({a + b: c * d} for a, c in f.items() for b, d in g.items()))
def show(f):                                    # a Laurent polynomial, lowest power first
    s = "".join(f" {'-' if c < 0 else '+'} {abs(c) if abs(c) > 1 else ''}t^{e}" for e, c in sorted(f.items()))
    return s[3:] if s[1] == "+" else "-" + s[3:]
def classical(x):                               # 1 + t^-2 x + t^-1 y = 0, solved for y
    return lmul({1: -1}, ladd({0: 1}, lmul({-2: 1}, x)))
print("== min-plus arithmetic ==")
R = range(-4, 5)
assert all(a + min(b, c) == min(a + b, a + c) for a in R for b in R for c in R)
assert all(2 * min(x, y) == min(2 * x, x + y, 2 * y) for x in R for y in R)
print("3 (+) 5 =", min(3, 5), "  3 (.) 5 =", 3 + 5, "  (x (+) y)^2 = x^2 (+) y^2 on all 81 pairs")
print("== the tropical line min(0, X - 2, Y - 1) ==")
for X, Y in [(1, 3), (3, 3), (3, 0), (2, 1)]:
    print(f"prices ({X}, {Y}): costs {[c + i * X + j * Y for c, i, j in LINE]} -> best {' = '.join(['nothing', 'A', 'B'][k] for k in winners(X, Y, LINE))}")
assert winners(2, 1, LINE) == [0, 1, 2]
q = [(2 * k + 1) / 4 for k in range(22)]          # half steps, offset a quarter: no ties
s = [(7, v - 4) for v in q] + [(7 - v, 7) for v in q] + [(-4, 7 - v) for v in q] + [(v - 4, -4) for v in q]
def turns(pick):                                # midpoints where the winner changes
    return [(int(x1 + x2) // 2, int(y1 + y2) // 2) for (x1, y1), (x2, y2) in zip(s, s[1:] + s[:1])
            if winners(x1, y1, LINE, pick) != winners(x2, y2, LINE, pick)]
def rays_of(walk): return sorted(((x - 2) // max(abs(x - 2), abs(y - 1)), (y - 1) // max(abs(x - 2), abs(y - 1))) for x, y in walk)
walk = turns(min); rays = rays_of(walk)
print("walk round the box from (-4, -4) to (7, 7): the winner changes at", walk)
assert rays == [(-1, -1), (0, 1), (1, 0)]
print("rays from (2, 1):", rays, " sum:", (sum(r[0] for r in rays), sum(r[1] for r in rays)))
newton = [(0, 0), (1, 0), (0, 1)]
# each edge, turned a quarter turn to the left, gives the inward normal
normals = [(newton[k][1] - newton[(k + 1) % 3][1], newton[(k + 1) % 3][0] - newton[k][0]) for k in range(3)]
assert sorted(normals) == rays
print("Newton triangle", newton, "edges' inward normals:", normals)
print("== classical points over Laurent series: x = t^a, then y ==")
found = set()
for a in [-1, 0, 1, 2, 3, 4]:
    x = {a: 1}; y = classical(x)
    assert ladd({0: 1}, lmul({-2: 1}, x), lmul({-1: 1}, y)) == {}
    X, Y = min(x), min(y); found.add((X, Y))
    assert len(winners(X, Y, LINE)) >= 2
    print(f"x = t^{a}: y = {show(y)} -> (val x, val y) = ({X}, {Y})")
assert not any(X == 2 and Y > 1 for X, Y in found)
for b in [3, 4]:
    x = {2: -1, b: 1}; y = classical(x)
    X, Y = min(x), min(y)
    assert (X, Y) == (2, b - 1) and winners(X, Y, LINE) == [0, 1]
    print(f"x = -t^2 + t^{b}: y = {show(y)} -> ({X}, {Y}), on the upward ray: needs the cancellation")
off = ladd({0: 1}, lmul({-2: 1}, {3: 1}), lmul({-1: 1}, {3: 1}))
assert winners(3, 3, LINE) == [0] and min(off) == 0
print("off the line: (3, 3) has the single winner [0]; x = y = t^3 gives", show(off), "!= 0")
print("== a smooth tropical cubic: bounded regions = genus ==")
def lattice(d): return [(i, j) for i in range(d + 1) for j in range(d + 1 - i)]
def regions(terms):                             # brute force on a 161 x 161 grid, X and Y in -10..10
    seen, edge = set(), set()
    for u in range(-80, 81):
        for w in range(-80, 81):
            k = winners((2 * u + 1) / 8, (2 * w + 1) / 8, terms)[0]; seen.add(k)
            if abs(u) == 80 or abs(w) == 80: edge.add(k)
    return len(seen), len(seen - edge)
for d in [1, 2, 3, 4]:
    total, bounded = regions([(i * i + i * j + j * j, i, j) for i, j in lattice(d)])
    inner = sum(1 for i, j in lattice(d) if i > 0 and j > 0 and i + j < d)
    assert total == len(lattice(d)) and bounded == inner == (d - 1) * (d - 2) // 2
    print(f"degree {d}: {total} regions, {bounded} bounded; interior lattice points {inner}; (d-1)(d-2)/2 = {(d - 1) * (d - 2) // 2}")
print("== Grobner bases over F_32003: dense quadrics in n variables ==")
P, M = 32003, (1 << 64) - 1
def splitmix(s):                                # SplitMix64: returns the new state and a number
    s = (s + 0x9E3779B97F4A7C15) & M; z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & M
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M; return s, z ^ (z >> 31)
def lead(f, lex): return max(f, key=lambda m: m if lex else (sum(m), tuple(-e for e in reversed(m))))
def divides(n, m): return all(a >= b for a, b in zip(m, n))
def monic(f, lex): c = pow(f[lead(f, lex)], P - 2, P); return {m: a * c % P for m, a in f.items()}
def sub(f, g, c, m, n):                         # f - c * (m / n) * g, in place
    for mm, cc in g.items():
        k = tuple(a + b - e for a, b, e in zip(mm, m, n))
        v = (f.get(k, 0) - c * cc) % P
        if v: f[k] = v
        else: f.pop(k, None)
def nf(f, G, lex):                              # the full remainder on division by G
    f, r = dict(f), {}
    while f:
        m = lead(f, lex)
        g = next((g for g in G if divides(lead(g, lex), m)), None)
        if g: sub(f, g, f[m], m, lead(g, lex))
        else: r[m] = f.pop(m)
    return r
def groebner(F, lex):                           # Buchberger, then the reduced basis
    G, done = [monic(f, lex) for f in F], 0
    pairs = [(i, j) for j in range(len(G)) for i in range(j)]
    while pairs:
        i, j = pairs.pop(0)
        a, b = lead(G[i], lex), lead(G[j], lex)
        if all(x == 0 or y == 0 for x, y in zip(a, b)): continue   # coprime leads: skip
        L = tuple(map(max, a, b)); s = {}
        sub(s, G[i], P - 1, L, a); sub(s, G[j], 1, L, b)
        r = nf(s, G, lex); done += 1
        if r: G.append(monic(r, lex)); pairs += [(k, len(G) - 1) for k in range(len(G) - 1)]
    G = [g for k, g in enumerate(G) if not any(divides(lead(h, lex), lead(g, lex)) and (lead(h, lex) != lead(g, lex) or h_ < k) for h_, h in enumerate(G) if h_ != k)]
    return [monic(nf(g, [h for h in G if h is not g], lex), lex) for g in G], done
def monomials(n, top):                          # every exponent tuple with entries 0..top
    return [()] if n == 0 else [m + (e,) for m in monomials(n - 1, top) for e in range(top + 1)]
seed = 2026
for n in [1, 2, 3, 4]:
    F = []
    for _ in range(n):
        f = {}
        for m in [m for m in monomials(n, 2) if sum(m) <= 2]:
            seed, z = splitmix(seed); f[m] = z % P
        F.append(f)
    for lex in [False, True]:
        G, done = groebner(F, lex)
        lts = [lead(g, lex) for g in G]
        std = sum(1 for m in monomials(n, 2 ** n) if not any(divides(t, m) for t in lts))
        assert std == 2 ** n                    # Bezout: 2^n solutions, counted with multiplicity
        if lex: assert max(g for t in lts for g in t[-1:]) == 2 ** n and len(G) == n and sum(map(len, G)) == n * (2 ** n + 1)   # shape lemma
        else: assert all(m == t or sum(t) > sum(m) or (sum(t) == sum(m) and [a - b for a, b in zip(t, m) if a != b][-1] < 0) for g, t in zip(G, lts) for m in g)   # grevlex, written another way
        name, top = "lex" if lex else "grevlex", max(sum(t) for t in lts)
        print(f"n = {n} {name:>7}: {len(G):>2} polynomials, top degree {top:>2}, {sum(map(len, G)):>3} terms, {done:>3} S-polynomials reduced; standard monomials {std} = 2^{n}")
print("growth shapes: n, Bezout 2^n, doubly exponential 2^(2^n):", [(n, 2 ** n, 2 ** 2 ** n) for n in range(1, 6)], " 2^10 =", 2 ** 10, " 2^20 =", 2 ** 20)
print("== what breaks ==")
print("max instead of min: the winner changes at", turns(max), "-> rays (-1, 0), (0, -1), (1, 1)")
assert rays_of(turns(max)) == [(-1, 0), (0, -1), (1, 1)]
print("call {trop f = 0} the curve: trop f(3, 3) =", min(0, 3 - 2, 3 - 1), " trop f(5, 4) =", min(0, 5 - 2, 4 - 1), "-> a whole quarter-plane, not a line")
flat = regions([(0, i, j) for i, j in lattice(3)])
assert flat == (3, 0)
print(f"cubic with every coefficient 0: only {flat[0]} of 10 terms ever win, {flat[1]} bounded -> the genus 1 is invisible")
print("monomial x = t^a only: rays reached", sorted({(1 if X > 2 else -1, 0 if Y == 1 else -1) for X, Y in found if (X, Y) != (2, 1)}), "-> the upward ray is missed")
print("figure, vertex (2, 1); box corners (-4, -4) (7, 7); ray ends (7, 1) (2, 7) (-3, -4); Newton triangle (0, 0) (1, 0) (0, 1)")
print("ALL CHECKS PASS")
