# Hilbert's syzygy theorem -- the check behind the card.  Standard library only.
# The twisted cubic: S = Q[x, y, z, w], I = <xz - y^2, xw - yz, yw - z^2>, order lex x > y > z > w.
# Road 1: Schreyer's method turns each S-polynomial reduction into a syzygy (a relation).
# Road 2: exact ranks count every relation in each degree and test that two generate them all.
# Road 3: Koszul homology gives the Betti numbers by a route that never builds a resolution.
from itertools import combinations
from math import comb, gcd, prod
V = 4
def mm(a, b): return tuple(u + v for u, v in zip(a, b))
def add(p, q, c=1):
    r = dict(p)
    for m, a in q.items():
        r[m] = r.get(m, 0) + c * a
        if r[m] == 0: del r[m]
    return r
def mul(p, q):
    r = {}
    for m, c in q.items(): r = add(r, {mm(k, m): c * v for k, v in p.items()})
    return r
def lt(p): return max(p)                # lex: tuples compare powers of x, then y, z, w
def divides(a, b): return all(u <= v for u, v in zip(a, b))
def quo(b, a): return tuple(v - u for u, v in zip(a, b))
def var(i): return {tuple(int(k == i) for k in range(V)): 1}
x, y, z, w = (var(i) for i in range(V))
F = [add(mul(x, z), mul(y, y), -1), add(mul(x, w), mul(y, z), -1), add(mul(y, w), mul(z, z), -1)]
def divide(p, G):                       # division algorithm; every leading coefficient here is +1 or -1
    q, r = [{} for _ in G], {}
    while p:
        m = lt(p); c = p[m]
        for k, g in enumerate(G):
            if divides(lt(g), m):
                t = {quo(m, lt(g)): c * g[lt(g)]}
                q[k] = add(q[k], t); p = add(p, mul(t, g), -1); break
        else:
            r[m] = c; del p[m]
    return q, r
def mstr(m): return ''.join(v + (f'^{e}' if e > 1 else '') for v, e in zip('xyzw', m) if e) or '1'
def pstr(p):
    s = ''
    for m in sorted(p, reverse=True):
        c, t = p[m], mstr(m)
        b = t if abs(c) == 1 and t != '1' else str(abs(c)) + (t if t != '1' else '')
        s += ((' - ' if c < 0 else ' + ') if s else ('-' if c < 0 else '')) + b
    return s or '0'
def vstr(v): return '(' + ', '.join(pstr(p) for p in v) + ')'
def slt(v, G):                          # Schreyer's order: m e_k ranks by m * LT(g_k), ties to the smaller k
    return max((mm(m, lt(G[k])), -k, m, k) for k, p in enumerate(v) for m in p)
def schreyer(G):
    out = []
    for i, j in combinations(range(len(G)), 2):
        L = tuple(max(a, b) for a, b in zip(lt(G[i]), lt(G[j])))
        ti, tj = {quo(L, lt(G[i])): G[j][lt(G[j])]}, {quo(L, lt(G[j])): -G[i][lt(G[i])]}
        q, r = divide(add(mul(ti, G[i]), mul(tj, G[j])), G)
        v = [add(add(ti if k == i else {}, tj if k == j else {}), q[k], -1) for k in range(len(G))]
        p0 = next(p for p in v if p)
        out.append(((i + 1, j + 1), r, v if p0[lt(p0)] > 0 else [{u: -c for u, c in p.items()} for p in v]))
    return out
def monos(d, n=V):
    if d < 0: return []
    return [(d,)] if n == 1 else [(a,) + m for a in range(d, -1, -1) for m in monos(d - a, n - 1)]
def rank(rows):                         # exact rank over Q: integer elimination, each row divided by its gcd
    rows, rk = [r[:] for r in rows if any(r)], 0
    for c in range(len(rows[0]) if rows else 0):
        piv = next((i for i in range(rk, len(rows)) if rows[i][c]), None)
        if piv is None: continue
        rows[rk], rows[piv] = rows[piv], rows[rk]
        for i in range(rk + 1, len(rows)):
            if rows[i][c]:
                a, b = rows[rk][c], rows[i][c]
                row = [a * u - b * v for u, v in zip(rows[i], rows[rk])]
                g = gcd(*row)
                rows[i] = [u // g for u in row] if g else row
        rk += 1
    return rk
def rank_I(d, gens):                    # rank of the degree-d part of the ideal: all monomial multiples
    return rank([[mul(f, {m: 1}).get(c, 0) for c in monos(d)] for f in gens for m in monos(d - 2)])
def rank_syz(d, syz):                   # rank of the degree-d multiples of the syzygies, coordinates in S^3
    return rank([[mul(p, {m: 1}).get(c, 0) for p in s for c in monos(d - 2)] for s in syz for m in monos(d - 3)])
def std(e, G): return [m for m in monos(e) if not any(divides(lt(g), m) for g in G)]
def koszul_rank(i, j, G):               # rank of the Koszul map K_i -> K_(i-1) in degree j, over S/<G>
    if i < 1 or i > V or j < i: return 0
    tgt = {bm: n for n, bm in enumerate((B, m) for B in combinations(range(V), i - 1) for m in std(j - i + 1, G))}
    rows = []
    for A in combinations(range(V), i):
        for m in std(j - i, G):
            row = [0] * len(tgt)
            for r, a in enumerate(A):
                for u, c in divide({mm(m, lt(var(a))): 1}, G)[1].items():
                    row[tgt[(A[:r] + A[r + 1:], u)]] += (-1) ** r * c
            rows.append(row)
    return rank(rows)
def tor(i, j, G): return comb(V, i) * len(std(j - i, G)) - koszul_rank(i, j, G) - koszul_rank(i + 1, j, G)
def dimS(e): return comb(e + 3, 3) if e >= 0 else 0
def ev(p, pt): return sum(c * prod(b ** e for b, e in zip(pt, m)) for m, c in p.items())
def hf(betti, t): return sum((-1) ** i * sum(dimS(t - a) for a in shifts) for i, shifts in enumerate(betti))

print("generators: " + ", ".join(pstr(f) for f in F) + "; leading terms " + ", ".join(mstr(lt(f)) for f in F))
syz = schreyer(F)
for pair, r, v in syz:
    _, _, m, k = slt(v, F)
    back = add(add(mul(v[0], F[0]), mul(v[1], F[1])), mul(v[2], F[2]))
    print(f"S-pair {pair}: remainder {pstr(r)}; syzygy {vstr(v)}, Schreyer lead {mstr(m)} e{k + 1}, put back: {pstr(back)}")
s12, s23, s13 = syz[0][2], syz[2][2], syz[1][2]
combo = [add(mul(y, a), mul(z, b), -1) for a, b in zip(s12, s23)]
pt, vals = (1, 2, 3, 4), [ev(f, (1, 2, 3, 4)) for f in F]
print(f"at (1, 2, 3, 4): f = {vals}; first relation {sum(ev(a, pt) * b for a, b in zip(s12, vals))}, "
      f"second {sum(ev(a, pt) * b for a, b in zip(s23, vals))}")
print(f"third syzygy = y*(first) - z*(second): {'yes' if combo == s13 else 'no'}; minimal syzygies: 2, both of degree 3")
ks, ls = [], []
for d in range(2, 7):
    ks.append(3 * comb(d + 1, 3) - rank_I(d, F)); ls.append(rank_syz(d, [s12, s23]))
print(f"degree d = 2..6: all relations {ks}, spanned by the two {ls}, 2C(d,3) = {[2 * comb(d, 3) for d in range(2, 7)]}")
table = [[tor(i, j, F) for j in range(7)] for i in range(V + 1)]
for i in range(V + 1):
    print(f"Koszul road, Tor_{i}(S/I, k) in degrees 0..6: {table[i]}")
on_s, on_k = ([sum(tor(i, j, G) for j in range(6)) for i in range(V + 1)] for G in ([], [x, y, z, w]))
print(f"Koszul complex on S: homology {on_s}; on k: Betti {on_k}")
betti, triv = [[0], [2, 2, 2], [3, 3]], [[0], [2, 2, 2], [4, 4, 4], [6]]
r1 = [hf(betti, t) for t in range(7)]
r2 = [dimS(t) - rank_I(t, F) for t in range(7)]
r3 = [len(std(t, F)) for t in range(7)]
print(f"HF(t), t = 0..6: from the resolution {r1}; monomials minus rank {r2}; standard monomials {r3}")
print(f"chart, all monomials {[dimS(t) for t in range(7)]}; first-step multiples 3C(t+1,3) {[3 * dimS(t - 2) for t in range(7)]}; "
      f"relations 2C(t,3) {[2 * dimS(t - 3) for t in range(7)]}")
print(f"t = 3 by hand: 20 - 12 + 2 = {dimS(3) - 3 * dimS(1) + 2 * dimS(0)}; HP = 3t + 1, degree 3; length 2 <= n = {V}")
print(f"break, twists dropped: (1 - 3 + 2) * C(6,3) = {(1 - 3 + 2) * dimS(3)} at t = 3, not 10")
print(f"break, syzygies ignored (1, 3): HF(3) = {hf([[0], [2, 2, 2]], 3)}, HF(6) = {hf([[0], [2, 2, 2]], 6)}, not 10 and 19")
print(f"break, trivial syzygies only (1, 3, 3, 1): HF(3) = {hf(triv, 3)}, HF(6) = {hf(triv, 6)}, not 10 and 19")
print(f"break, Schreyer's 3 syzygies kept (1, 3, 3): HF(4) = {hf([[0], [2, 2, 2], [3, 3, 4]], 4)}, not 13")
ker2, im2 = [a for a in range(4) if 2 * a % 4 == 0], sorted({2 * a % 4 for a in range(4)})
print(f"break, Z/2 over the ring Z/4: kernel of x2 = {ker2}, image of x2 = {im2}: each step repeats, never ends")
drop = [dimS(t) - rank_I(t, F[:2]) for t in range(1, 5)]
print(f"break, f3 dropped: HF(1..4) = {drop}; resolution 1, 2, 1 predicts {[hf([[0], [2, 2], [4]], t) for t in range(1, 5)]}; degree 4")
assert all(not r for _, r, _ in syz) and combo == s13                      # Buchberger, then the redundant third
assert all(not add(add(mul(v[0], F[0]), mul(v[1], F[1])), mul(v[2], F[2])) for _, _, v in syz)
assert ks == ls == [2 * comb(d, 3) for d in range(2, 7)]                    # two syzygies give every relation
assert table[0][0] == 1 and table[1][2] == 3 and table[2][3] == 2 and sum(map(sum, table)) == 6 and on_k == [comb(V, i) for i in range(V + 1)]
assert r1 == r2 == r3 == [3 * t + 1 for t in range(7)]                      # three roads to HF
assert drop == [hf([[0], [2, 2], [4]], t) for t in range(1, 5)] == [4, 8, 12, 16]
print("ALL CHECKS PASS")
