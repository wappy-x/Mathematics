# Categories and functors -- the check behind the card.  Nothing is imported.
# Two finite categories are built and every law is tested on every arrow:
# SET, the sets {0}, {0,1}, {0,1,2} with every function between them, and GRP,
# four small groups with every homomorphism between them.  Then the flip-pattern
# functor F, from sets to groups, is built and its laws are tested on every pair.
# A function is a list: entry x is where x goes.  A group is its table: T[x][y].

def all_functions(a, b):                 # every list of a outputs, each below b
    out = [[]]
    for _ in range(a):
        out = [f + [y] for f in out for y in range(b)]
    return out

def compose(g, f):                       # g after f: do f first, then g
    return [g[x] for x in f]

def ident(n):
    return list(range(n))

def check_category(objs, size, hom):     # identity laws, closure, associativity
    pairs = triples = 0
    for a in objs:
        for b in objs:
            for f in hom[a, b]:
                assert compose(ident(size[b]), f) == f == compose(f, ident(size[a]))
                for c in objs:
                    for g in hom[b, c]:
                        gf = compose(g, f)
                        assert gf in hom[a, c]
                        pairs += 1
                        for d in objs:
                            for h in hom[c, d]:
                                assert compose(h, gf) == compose(compose(h, g), f)
                                triples += 1
    return sum(len(hom[a, b]) for a in objs for b in objs), pairs, triples

def isos(objs, size, hom):               # arrows with an arrow back undoing them
    return [(a, b) for a in objs for b in objs for f in hom[a, b]
            if any(compose(g, f) == ident(size[a]) and compose(f, g) == ident(size[b])
                   for g in hom[b, a])]

def clock(n):                            # the n-hour clock: add, wrap at n
    return [[(x + y) % n for y in range(n)] for x in range(n)]

def flips(k):                            # patterns of k switches, as bits; combining
    return [[x ^ y for y in range(2 ** k)] for x in range(2 ** k)]   # keeps a switch flipped in exactly one

def is_hom(f, A, B):
    return all(f[A[x][y]] == B[f[x]][f[y]] for x in range(len(A)) for y in range(len(A)))

def times(B, b, m):                      # b combined with itself m times
    x = 0
    for _ in range(m):
        x = B[x][b]
    return x

def formula(a, B):                       # a homomorphism is fixed by where generators go
    if a == "V":
        return sum(1 for b in range(len(B)) if B[b][b] == 0) ** 2
    return sum(1 for b in range(len(B)) if times(B, b, int(a[1])) == 0)

def F(f, b):                             # F(f): flipped switches -> lamps that toggle
    out = []
    for p in range(2 ** len(f)):
        lamps = 0
        for t in range(b):
            hits = sum(1 for s in range(len(f)) if p >> s & 1 and f[s] == t)
            if hits % 2 == 1:
                lamps |= 1 << t
        out.append(lamps)
    return out

def image(f, b):                         # the tempting wrong rule: lamps touched at all
    return [sum(1 << t for t in range(b) if any(p >> s & 1 and f[s] == t for s in range(len(f))))
            for p in range(2 ** len(f))]

def show(p, k):
    return "{" + ",".join(str(s) for s in range(k) if p >> s & 1) + "}"

def table(m, a):
    return ", ".join(show(p, a) + " -> " + show(m[p], 2) for p in range(2 ** a))

S = [1, 2, 3]
hom_s = {(a, b): all_functions(a, b) for a in S for b in S}
print("SET objects: {0}, {0,1}, {0,1,2}; arrows: every function")
print(f"Hom sizes by search {[[len(hom_s[a, b]) for b in S] for a in S]}, by |B|^|A| {[[b ** a for b in S] for a in S]}")
n_s, p_s, t_s = check_category(S, {k: k for k in S}, hom_s)
print(f"SET: {n_s} arrows, identity laws on all {n_s}, {p_s} composable pairs closed, associativity on all {t_s} triples")
iso_s = isos(S, {k: k for k in S}, hom_s)
fact = [1, 1 * 2, 1 * 2 * 3]
print(f"SET isomorphisms by search: {len(iso_s)}; bijections {' + '.join(map(str, fact))} = {sum(fact)}")
G = {"C2": clock(2), "C3": clock(3), "C4": clock(4), "V": flips(2)}
hom_g = {(a, b): [f for f in all_functions(len(G[a]), len(G[b])) if is_hom(f, G[a], G[b])] for a in G for b in G}
print("GRP objects: C2, C3, C4, V; arrows: every homomorphism")
print(f"Hom sizes by search {[[len(hom_g[a, b]) for b in G] for a in G]}, by generators {[[formula(a, G[b]) for b in G] for a in G]}")
n_g, p_g, t_g = check_category(list(G), {k: len(G[k]) for k in G}, hom_g)
print(f"GRP: {n_g} arrows (rows {[sum(len(hom_g[a, b]) for b in G) for a in G]}), identity laws on all {n_g}, {p_g} composable pairs closed, associativity on all {t_g} triples")
iso_g = isos(list(G), {k: len(G[k]) for k in G}, hom_g)
bij_g = sum(1 for (a, b), fs in hom_g.items() for f in fs if sorted(f) == ident(len(G[b])))
print(f"GRP isomorphisms by search: {len(iso_g)} ({', '.join(f'{k} {iso_g.count((k, k))}' for k in G)}); "
      f"between different groups {sum(1 for a, b in iso_g if a != b)}; bijective homomorphisms {bij_g}")
w, f, g = [0, 0], [0, 1, 0], [0, 0]
print(f"stairs: w = {w}; F(w): {table(F(w, 1), 2)}")
print(f"landing: f = {f}, g = {g}")
for label, m, a in [("F(f)", F(f, 2), 3), ("F(g)", F(g, 1), 2), ("F(g o f)", F(compose(g, f), 1), 3),
                    ("F(g) o F(f)", compose(F(g, 1), F(f, 2)), 3)]:
    print(f"{label}: {table(m, a)}")
homs = sum(1 for (a, b), fs in hom_s.items() for h in fs if is_hom(F(h, b), flips(a), flips(b)))
ids = sum(1 for k in S if F(ident(k), k) == ident(2 ** k))
comp = sum(1 for a in S for b in S for c in S for h in hom_s[a, b] for k in hom_s[b, c]
           if F(compose(k, h), c) == compose(F(k, c), F(h, b)))
print(f"functor: F(f) a homomorphism for {homs} of {n_s} functions; F(id) = id for {ids} of 3 sets; "
      f"F(g o f) = F(g) o F(f) on {comp} of {p_s} pairs")
grp = {1: "C2", 2: "V"}
road2 = 0
for a in [1, 2]:
    for b in [1, 2]:
        for h in hom_s[a, b]:                # search GRP's list; no parity counted
            found = [m for m in hom_g[grp[a], grp[b]] if all(m[1 << s] == 1 << h[s] for s in range(a))]
            road2 += found == [F(h, b)]
print(f"second road: F(f) is the only homomorphism sending each single switch to its lamp, {road2} of 8 arrows")
iso_f = sum(1 for a in S for h in hom_s[a, a] if sorted(h) == ident(a) and sorted(F(h, a)) == ident(2 ** a))
print(f"bijections carried to isomorphisms: {iso_f} of {len(iso_s)}")
bad = sum(1 for (a, b), fs in hom_s.items() for h in fs if not is_hom(image(h, b), flips(a), flips(b)))
inj = sum(1 for fs in hom_s.values() for h in fs if len(set(h)) == len(h))
print(f"mistake 1, lamps touched instead of parity: not a homomorphism for {bad} of {n_s} functions, {inj} injective; "
      f"stairs, both flipped: {show(image(w, 1)[3], 1)}, not {show(F(w, 1)[3], 1)}")
zero_c = sum(1 for a in S for b in S for c in S for h in hom_s[a, b] for k in hom_s[b, c]
             if [0] * 2 ** a == compose([0] * 2 ** b, [0] * 2 ** a))
zero_i = sum(1 for k in S if [0] * 2 ** k == ident(2 ** k))
print(f"mistake 2, every function sent to 'change nothing': composition on {zero_c} of {p_s} pairs, identity on {zero_i} of 3")
bij = sum(1 for h in all_functions(4, 4) if sorted(h) == ident(4))
print(f"mistake 3, all functions as arrows: C4 to V, {bij} bijections, {iso_g.count(('C4', 'V'))} group isomorphisms")
assert [[len(hom_s[a, b]) for b in S] for a in S] == [[b ** a for b in S] for a in S]
assert [[len(hom_g[a, b]) for b in G] for a in G] == [[formula(a, G[b]) for b in G] for a in G]
assert len(iso_s) == sum(fact) and len(iso_g) == bij_g == 11
assert homs == n_s and comp == p_s                        # F keeps every law
assert ids == 3 and road2 == 8 and iso_f == len(iso_s)
assert bad == n_s - inj and bij == 24
print("ALL CHECKS PASS")
