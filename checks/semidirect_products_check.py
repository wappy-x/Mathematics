# Semidirect products -- the check behind the card.  Nothing is imported.
# A move is a pair (a, s): a on an n-clock, s on an m-clock.  The twisted
# rule is (a, s)(b, t) = (a + u^s b, s + t), u a multiplier on the n-clock.
# Road two never uses the rule: the pair is the map x -> u^s x + a on the n
# points, and two maps compose point by point, the right-hand map first.
def mul(n, m, u, x, y):
    return ((x[0] + pow(u, x[1], n) * y[0]) % n, (x[1] + y[1]) % m)

bad_mul = lambda n, m, u, x, y: ((x[0] + pow(u, y[1], n) * y[0]) % n, (x[1] + y[1]) % m)
yn = lambda claim: "yes" if claim else "no"        # bad_mul: the mistake, twisting by t

def facts(n, m, u, rule=mul):
    G = [(a, s) for s in range(m) for a in range(n)]
    f = lambda x, y: rule(n, m, u, x, y)
    pts = {x: tuple((pow(u, x[1], n) * p + x[0]) % n for p in range(n)) for x in G}
    agree = all(pts[f(x, y)] == tuple(pts[x][q] for q in pts[y]) for x in G for y in G)
    broken = sum(f(f(x, y), z) != f(x, f(y, z)) for x in G for y in G for z in G)
    commute = sum(f(x, y) == f(y, x) for x in G for y in G)
    return G, f, agree and len(set(pts.values())) == len(G), broken, commute

def order(f, x):                         # repeats of x until the identity (0, 0)
    k, y = 1, x
    while y != (0, 0):
        k, y = k + 1, f(y, x)
    return k

T, tf, tok, tbroken, tcomm = facts(4, 2, 3)
flip, quarter, N = (0, 1), (1, 0), [(a, 0) for a in range(4)]
inv = {g: next(y for y in T if tf(g, y) == (0, 0)) for g in T}
stay, undo = all(tf(tf(g, x), inv[g]) in N for g in T for x in N), inv[quarter]
print(f"tile, u = 3: rule matches the corner maps on 64 products: {yn(tok)}")
print(f"flip, quarter turn, flip = {tf(tf(flip, quarter), flip)}; undo of a quarter turn = {undo}")
print(f"turn then flip = {tf(flip, quarter)}; flip then turn = {tf(quarter, flip)}")
print(f"commuting pairs: tile {tcomm} of 64, untwisted (u = 1) {facts(4, 2, 1)[4]} of 64")
print(f"turns keep their shape under all 32 conjugations: {yn(stay)}")
for name, K in [("flips {r0, f}", [(0, 0), flip]), ("half turn {r0, r2}", [(0, 0), (2, 0)])]:
    print(f"turns with {name}: share {len(set(N) & set(K))}, products give {len({tf(x, y) for x in N for y in K})}")
S, sf, sok, sbroken, scomm = facts(7, 3, 2)
ords = [order(sf, x) for x in S]
n7, n3 = ords.count(7) // 6, ords.count(3) // 2
print(f"order 21, u = 2, 2^3 = 8 = {8 % 7} mod 7: matches maps {yn(sok)}, broken triples {sbroken}")
print(f"orders: 1 x{ords.count(1)}, 3 x{ords.count(3)}, 7 x{ords.count(7)}; commuting pairs {scomm} of 441")
print(f"subgroups of order 7: {n7}; of order 3: {n3}; (1, 1) twice {sf((1, 1), (1, 1))}, thrice {sf(sf((1, 1), (1, 1)), (1, 1))}")
Z, zf, _, _, zcomm = facts(7, 3, 1)
longest = max(order(zf, x) for x in Z)
ff = facts(7, 3, 4)[1]
same = all((sf(x, y)[0], 2 * sf(x, y)[1] % 3) == ff((x[0], 2 * x[1] % 3), (y[0], 2 * y[1] % 3)) for x in S for y in S)
print(f"u = 1: longest order {longest}, commuting pairs {zcomm}; u = 4 is u = 2 relabelled: {yn(same)}")
for p, q in [(7, 3), (5, 3), (3, 2)]:
    us = [u for u in range(1, p) if pow(u, q, p) == 1]
    print(f"order {p * q}: u with u^{q} = 1 mod {p}: {us}; {q} divides {p - 1}: {yn((p - 1) % q == 0)}")
    assert (len(us) > 1) == ((p - 1) % q == 0) and len(us) in (1, q)   # two roads
bbroken, wbroken = facts(7, 3, 3)[3], facts(4, 2, 3, bad_mul)[3]
print(f"mistake, u = 3 on the 7-clock, 3^3 = {27 % 7} mod 7: broken triples {bbroken} of 9261")
print(f"mistake, twisting by the right-hand flip: broken triples {wbroken} of 512")
assert tok and sok and tbroken == 0 and sbroken == 0          # rule = composed maps
assert tf(tf(flip, quarter), flip) == undo and stay and tcomm < 64
assert n7 == 1 and n3 % 3 == 1 and 7 % n3 == 0 and longest == 21 > max(ords)
assert same and bbroken > 0 and wbroken > 0
print("ALL CHECKS PASS")
