# Decomposition and inertia groups -- the check behind the card.  Imports only
# math.lcm.  L is the splitting field of x^3 - 2: a^3 = 2, w^2 + w + 1 = 0; the
# symmetry (s, t) sends a to w^s a and w to w^t, so root r_j = w^j a goes to
# r_(tj+s).  Road 1 factors subfield polynomials mod p and uses efg = n.  Road 2
# never factors: it builds GF(p^k), lists the points (a, b), and reads D and I
# off how the symmetries move one point.  The house field H = Q(sqrt-5, i) too.
from math import lcm
def mul(u, v, p, m):                     # product in GF(p^k) = GF(p)[z]/(m)
    k = len(m) - 1
    r = [sum(u[i] * v[d - i] for i in range(k) if 0 <= d - i < k) for d in range(2 * k - 1)]
    for d in range(2 * k - 2, k - 1, -1):
        c = r[d] % p
        r[d - k:d + 1] = [x - c * y for x, y in zip(r[d - k:d + 1], m)]
    return tuple(x % p for x in r[:k])
def pw(x, n, p, m):                      # x to the power n, one multiplication at a time
    return (1,) + (0,) * (len(m) - 2) if n == 0 else mul(pw(x, n - 1, p, m), x, p, m)
def ev(poly, x, p, m):                   # a whole-number polynomial at x, by Horner
    acc = (0,) * (len(m) - 1)
    for c in reversed(poly):
        acc = mul(acc, x, p, m)
        acc = ((acc[0] + c) % p,) + acc[1:]
    return acc
def elems(p, k):                         # every k-tuple mod p, first entry slowest
    return [tuple(i // p ** (k - 1 - j) % p for j in range(k)) for i in range(p ** k)]
def modulus(p, k):                       # a rootless monic of degree 2 or 3 is irreducible
    return (0, 1) if k == 1 else next(t + (1,) for t in elems(p, k) if all(
        sum(c * r ** i for i, c in enumerate(t + (1,))) % p for r in range(p)))
def pattern(poly, p):                    # [(degree, exponent)] of poly's factors mod p
    c, out = [x % p for x in poly], []
    for r in range(p):
        e = 0
        while len(c) > 1 and sum(x * r ** i for i, x in enumerate(c)) % p == 0:
            q = [0] * (len(c) - 1)       # divide by (x - r), top coefficient first
            for i in range(len(c) - 1, 0, -1):
                q[i - 1] = (c[i] + r * (q[i] if i < len(q) else 0)) % p
            c, e = q, e + 1
        out += [(1, e)] if e else []
    return out + ([(len(c) - 1, 1)] if len(c) > 1 else [])
def road1(F, p):                         # e, f only grow up a tower; efg = n pins them
    pats = [pattern(s, p) for s in F["subs"]]
    le, lf = lcm(*[e for pt in pats for _, e in pt]), lcm(*[d for pt in pats for d, _ in pt])
    n, gmax = F["n"], max(len(pt) for pt in pats)
    return [(e, f, n // (e * f)) for e in range(1, n + 1) for f in range(1, n + 1)
            if n % (e * f) == 0 and e % le == 0 and f % lf == 0 and n // (e * f) >= gmax
            and (le > 1 or (e, f) == (1, lf))]
def act(F, g, pt, p, m):                 # the point pt composed with the symmetry g
    a, b = pt
    if F["n"] == 6:
        return (mul(pw(b, g[0], p, m), a, p, m), pw(b, g[1], p, m))
    flip = lambda x, s, c=0: x if s > 0 else tuple(((c if j == 0 else 0) - y) % p for j, y in enumerate(x))
    return (flip(a, g[1]), flip(b, g[0] * g[1], 1)) if "phi" in F else (flip(a, g[0]), flip(b, g[1]))
def road2(F, p):
    for k in (1, 2, 3):                  # the smallest GF(p^k) holding a point
        m = modulus(p, k)
        roots = [[x for x in elems(p, k) if ev(poly, x, p, m) == (0,) * k] for poly in (F["px"], F["py"])]
        pts = [(x, y) for x in roots[0] for y in roots[1]]
        if pts:
            break
    orbits, seen = [], set()
    for pt in pts:                       # Frobenius orbits: one per prime ideal above p
        if pt not in seen:
            o = [pt]
            while (nxt := (pw(o[-1][0], p, p, m), pw(o[-1][1], p, p, m))) != pt:
                o.append(nxt)
            orbits.append(o)
            seen.update(o)
    D_of = lambda o: [g for g in F["G"] if act(F, g, o[0], p, m) in o]
    O, f = orbits[0], len(orbits[0])
    D = D_of(O)
    kk = {g: O.index(act(F, g, O[0], p, m)) for g in D}     # g acts on GF(p^f) as Frob^kk
    I = [g for g in D if act(F, g, O[0], p, m) == O[0]]
    ok = (all(O.index(act(F, h, act(F, g, O[0], p, m), p, m)) == (kk[g] + kk[h]) % f for g in D for h in D)
          and sorted(set(kk.values())) == list(range(f)) and [g for g in D if kk[g] == 0] == I
          and sorted({act(F, g, O[0], p, m) for g in F["G"]}) == sorted(pts))
    return dict(k=k, npts=len(pts), e=len(I), f=f, g=len(orbits), D=D, I=I, ok=ok,
                frob=[g for g in D if kk[g] == 1 % f], allD=[D_of(o) for o in orbits])
perm = lambda g, j: (g[1] * j + g[0]) % 3
def cyc(g):                              # a cubic symmetry as cycles of r0, r1, r2
    out, seen = "", set()
    for j in range(3):
        c = [j]
        while j not in seen and perm(g, c[-1]) != j:
            c.append(perm(g, c[-1]))
        seen.update(c)
        out += "(" + " ".join(f"r{x}" for x in c) + ")" if len(c) > 1 else ""
    return out or "id"
nest = lambda g, n, j: j if n == 0 else nest(g, n - 1, perm(g, j))      # g applied n times
order = lambda g: min(n for n in range(1, 7) if all(nest(g, n, j) == j for j in range(3)))
orbit_sizes = lambda D: sorted(len(o) for o in {frozenset(perm(g, j) for g in D) for j in range(3)})
CUBIC = dict(n=6, px=(-2, 0, 0, 1), py=(1, 1, 1), subs=[(-2, 0, 0, 1), (1, 1, 1)],
             G=[(s, t) for t in (1, 2) for s in range(3)])
HOUSE = dict(n=4, px=(5, 0, 1), py=(1, 0, 1), subs=[(5, 0, 1), (1, 0, 1), (-1, -1, 1)],
             G=[(u, v) for u in (1, -1) for v in (1, -1)])
FULL = dict(HOUSE, px=(1, 0, 1), py=(-1, -1, 1), phi=1)   # all of O_H: Z[i, phi], phi = (1 + sqrt5)/2; g sends phi to 1 - phi if g0 g1 = -1
sg = lambda g: ("+" if g[0] > 0 else "-") + ("+" if g[1] > 0 else "-")
show = lambda S, nm: "{" + ", ".join(nm(g) for g in S) + "}"
print("L = splitting field of x^3 - 2, n = 6, G = S3 on r0 = a, r1 = w a, r2 = w^2 a")
print(f"by hand: 4^3 = {4 ** 3} = 2 + 2 x 31; roots of x^3 - 2 mod 31: {[r for r in range(31) if (r ** 3 - 2) % 31 == 0]}; of x^2 + x + 1 mod 31: {[r for r in range(31) if (r * r + r + 1) % 31 == 0]}")
print(f"(degree, power) of the factors of x^3 - 2 and x^2 + x + 1 mod 31, 5, 7, 2, 3: {[(pattern(CUBIC['px'], p), pattern(CUBIC['py'], p)) for p in (31, 5, 7, 2, 3)]}")
R = {p: road2(CUBIC, p) for p in (31, 5, 7, 2, 3)}
for p, x in R.items():
    print(f"p={p}: road 1 (e,f,g) = {road1(CUBIC, p)[0]} | road 2 {(x['e'], x['f'], x['g'])}, {x['npts']} "
          f"point{'s' * (x['npts'] > 1)} in GF({p}^{x['k']}) | D = {show(x['D'], cyc)} | I = {show(x['I'], cyc)}")
print(f"p=5: the 3 primes above 5 have D = {', '.join(show(D, cyc) for D in R[5]['allD'])}")
print(f"Frobenius at 31, 5, 7: {cyc(R[31]['frob'][0])}, {cyc(R[5]['frob'][0])}, {cyc(R[7]['frob'][0])}; "
      f"at 2, {len(R[2]['frob'])} symmetries act as Frobenius on GF(4): {show(R[2]['frob'], cyc)}")
o3 = sorted(order(g) for g in R[3]["I"])
print(f"p=3: orders in I = S3: {o3}; none is 6, so I is not cyclic")
sweep = [p for p in range(2, 50) if all(p % d for d in range(2, p))]
rows = {p: road2(CUBIC, p) for p in sweep}
agree = all(road1(CUBIC, p) == [(rows[p]["e"], rows[p]["f"], rows[p]["g"])] and rows[p]["ok"] for p in sweep)
orb = all(orbit_sizes(rows[p]["D"]) == sorted(d * e for d, e in pattern(CUBIC["px"], p)) for p in sweep)
print(f"primes below 50: road 1 = road 2, D onto Gal(GF(p^f)/GF(p)) with kernel I, G moves one point to all: "
      f"{'yes' if agree else 'no'}\nprimes below 50: D's orbits on r0, r1, r2 = factors of x^3 - 2 mod p: {'yes' if orb else 'no'}")
for size in (1, 2, 3): print(f"  |D| = {size}, unramified: {[p for p in sweep if p > 3 and len(rows[p]['D']) == size]}")
print("house H = Q(sqrt-5, i), O_H = Z[i, (1+sqrt5)/2], n = 4, symmetry = (sign on sqrt-5, sign on i), Gal(H/K) = {++, +-}")
for p in (29, 3, 5, 2):
    x = road2(FULL, p)
    print(f"p={p}: e={x['e']} f={x['f']} g={x['g']} | D = {show(x['D'], sg)} | I = {show(x['I'], sg)}")
    assert road1(HOUSE, p) == [(x["e"], x["f"], x["g"])] and x["ok"]
h2, i5, r2 = road1(HOUSE, 2), road2(HOUSE, 5)["I"], road2(FULL, 2)
clean = [i for i, s in enumerate(HOUSE["subs"]) if all(e == 1 for _, e in pattern(s, 2))]
im = [g for g in HOUSE["G"] if all((g[0], g[1], g[0] * g[1])[j] == 1 for j in clean)]   # g's sign on sqrt-5, i, sqrt5
print(f"p=2 by road 1: (e,f,g) = {h2[0]}; 2 is unramified only in Q(sqrt5), so I = {show(im, sg)}")
meet = [len([g for g in I if g[0] == 1]) for I in (r2["I"], i5)]
print(f"I meets Gal(H/K) in {meet[0]} symmetry at 2 and {meet[1]} at 5: H/K is unramified at 2 and 5")
hsweep = [p for p in sweep if p > 2 and road2(HOUSE, p)["D"] == [(1, 1)]]
print(f"odd primes below 50 with D trivial in H: {hsweep}")
k5, b2 = pattern(CUBIC["px"], 5), road2(HOUSE, 2)
print(f"mistake 1, Q(a) not Galois: x^3 - 2 mod 5 has factor degrees {[d for d, _ in k5]}; e f g from the first prime = 1 x {k5[0][0]} x {len(k5)} = {k5[0][0] * len(k5)}, not 3")
print(f"mistake 2, I read as D at 2: e = {len(R[2]['D'])}, e f g = {len(R[2]['D']) * 2}, not 6")
print(f"mistake 3, Z[sqrt-5, i] taken as all integers of H at 2: {b2['npts']} point, fixed by {b2['e']}: e = {b2['e']}, f = {b2['f']}; truly e = {r2['e']}, f = {r2['f']}")
assert all(road1(CUBIC, p) == [(x["e"], x["f"], x["g"])] and x["ok"] for p, x in R.items())
assert [len(x["D"]) for x in R.values()] == [1, 2, 3, 6, 6] and [len(x["I"]) for x in R.values()] == [1, 1, 1, 3, 6]
assert agree and orb and len({tuple(D) for D in R[5]["allD"]}) == 3 and o3 == [1, 2, 2, 2, 3, 3]
assert [p for p in sweep if p > 3 and len(rows[p]["D"]) == 2] == [p for p in sweep if p % 3 == 2 and p > 2]
assert h2 == [(2, 2, 1)] and clean == [2] and im == r2["I"] and meet == [1, 1] and hsweep == [p for p in sweep if p % 20 in (1, 9)]
assert (b2["e"], b2["f"]) == (4, 1) and sorted(R[2]["frob"]) == sorted(set(R[2]["D"]) - set(R[2]["I"])) and [order(R[p]["frob"][0]) for p in (31, 5, 7)] == [1, 2, 3]
assert all(b[0] ** j * a[0] % 31 == 5 ** perm(g, j) * 4 % 31 for g in CUBIC["G"] for a, b in [act(CUBIC, g, ((4,), (5,)), 31, (0, 1))] for j in range(3))   # act agrees with perm
print("ALL CHECKS PASS")
