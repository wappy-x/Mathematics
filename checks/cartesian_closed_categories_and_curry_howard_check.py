# Cartesian closed categories -- the check behind the card.  Nothing is imported.
# Sets: currying matches rules A x B -> C with rules A -> C^B.  Typed lambda terms three ways: a type
# checker (types are formulas), the lambda-calculus card's environment evaluator (terms become arrows:
# functions between sets), and a proof search (Dyckhoff's rules), against truth and Kripke tables.

def functions(n, m):                      # every list of n outputs, each below m
    out = [()]
    for _ in range(n):
        out = [f + (v,) for f in out for v in range(m)]
    return out

NA, NB, NC = 2, 3, 2
AN, BN, CN = ["member", "guest"], ["S", "M", "L"], ["no", "yes"]
rules = functions(NA * NB, NC)            # a rule f: A x B -> C; f(a, b) is f[a * NB + b]
expo = functions(NB, NC)                  # C^B: the 8 functions B -> C, as points
curried = functions(NA, len(expo))        # A -> C^B: each value is a point of C^B
def curry(f): return tuple(expo.index(tuple(f[a * NB + b] for b in range(NB))) for a in range(NA))
def ev(h, b): return expo[h][b]          # eval: C^B x B -> C
def uncurry(g): return tuple(ev(g[a], b) for a in range(NA) for b in range(NB))
back1, back2 = sum(uncurry(curry(f)) == f for f in rules), sum(curry(uncurry(g)) == g for g in curried)
refill = (1, 1, 1, 0, 0, 1)
nat = sum(curry(tuple(f[u[a] * NB + b] for a in range(NA) for b in range(NB)))
          == tuple(curry(f)[u[a]] for a in range(NA)) for u in functions(NA, NA) for f in rules)
print("== currying in Set: A = 2 customer types, B = 3 cup sizes, C = {no, yes} ==")
print(f"rules A x B -> C, listed: {len(rules)}; points of C^B: {len(expo)}; rules A -> C^B, listed: {len(curried)}")
print(f"uncurry after curry gives back {back1} of 64; curry after uncurry gives back {back2} of 64")
print("refill rule on (member S, M, L, guest S, M, L):", " ".join(CN[v] for v in refill))
g = curry(refill)
print(f"curried: member -> point {g[0]} = ({', '.join(CN[v] for v in expo[g[0]])}), "
      f"guest -> point {g[1]} = ({', '.join(CN[v] for v in expo[g[1]])}); eval(guest's menu, L) = {CN[ev(g[1], 2)]}")
print(f"naturality in A, curry(f after (u x id)) = curry(f) after u: {nat} of {4 * len(rules)}")
print("both sides listed at |A|, |B|, |C| = " + "; ".join(f"{a}, {b}, {c}: {len(functions(a * b, c))} and "
      f"{len(functions(a, len(functions(b, c))))}" for a, b, c in [(1, 2, 3), (2, 2, 3), (3, 2, 2)]))
print(f"mistake, C^B read as B^C: {len(functions(NC, NB))} points, {len(functions(NA, len(functions(NC, NB))))} curried rules")
print(f"mistake, C^B read as pairs C x B: {NC * NB} points, {len(functions(NA, NC * NB))} curried rules")
def homs(n, m):                           # homomorphisms Z_n -> Z_m, by brute force
    return sum(all(f[(x + y) % n] == (f[x] + f[y]) % m for x in range(n) for y in range(n))
               for f in functions(n, m))
print("== groups are not cartesian closed ==")
print(f"Hom(1 x Z2, Z2) = Hom(Z2, Z2): {homs(2, 2)}; Hom(Z3, Z3): {homs(3, 3)}; "
      f"Hom(1, Z2): {homs(1, 2)}; Hom(1, Z3): {homs(1, 3)}")
P, Q, R, V = "P", "Q", "R", (lambda n: ("var", n))
AND, IMP = (lambda x, y: ("*", x, y)), (lambda x, y: ("->", x, y))   # a type is also a formula
def show(t, word):
    return t if isinstance(t, str) else "(" + show(t[1], word) + (" -> " if t[0] == "->" else word) + show(t[2], word) + ")"
def typeof(t, ctx):                       # the type checker; None means rejected
    k = t[0]
    if k == "var": return ctx.get(t[1])
    if k == "lam":
        body = typeof(t[3], {**ctx, t[1]: t[2]})
        return body and IMP(t[2], body)
    a = typeof(t[1], ctx)
    if k in ("fst", "snd"):
        return a[1 if k == "fst" else 2] if isinstance(a, tuple) and a[0] == "*" else None
    b = typeof(t[2], ctx)
    if k == "pair": return a and b and AND(a, b)
    return a[2] if isinstance(a, tuple) and a[0] == "->" and a[1] == b else None
def run(t, env):                          # values: ints, ("pr", x, y), closures, tables
    k = t[0]
    if k == "var": return env[t[1]]
    if k == "lam": return ("clo", t[1], t[3], env)
    if k == "pair": return ("pr", run(t[1], env), run(t[2], env))
    if k in ("fst", "snd"): return run(t[1], env)[1 if k == "fst" else 2]
    return apply(run(t[1], env), run(t[2], env))
def apply(f, x):
    return f[1][x] if f[0] == "tab" else run(f[2], {**f[3], f[1]: x})
terms = {
    "swap": ("lam", "p", AND(P, Q), ("pair", ("snd", V("p")), ("fst", V("p")))),
    "curry": ("lam", "f", IMP(AND(P, Q), R), ("lam", "a", P, ("lam", "b", Q,
              ("app", V("f"), ("pair", V("a"), V("b")))))),
    "uncurry": ("lam", "g", IMP(P, IMP(Q, R)), ("lam", "p", AND(P, Q),
                ("app", ("app", V("g"), ("fst", V("p"))), ("snd", V("p"))))),
    "const": ("lam", "x", P, ("lam", "y", Q, V("x"))),
    "same": ("lam", "p", AND(P, Q), ("pair", ("fst", V("p")), ("snd", V("p")))),
    "bad": ("lam", "p", P, ("fst", V("p"))),
    "bad apply": ("lam", "f", IMP(P, Q), ("lam", "r", R, ("app", V("f"), V("r"))))}
print("== simply typed terms: each type is a formula ==")
for name, t in terms.items():
    ty = typeof(t, {})
    print(f"{name}: " + (f"type {show(ty, ' x ')[1:-1]}, formula {show(ty, ' and ')[1:-1]}" if ty else "rejected"))
print("== terms as arrows in Set, with P = A, Q = B, R = C ==")
pr = [("pr", a, b) for a in range(NA) for b in range(NB)]
sw = run(terms["swap"], {})
swap_table = tuple(apply(sw, x)[1] * NA + apply(sw, x)[2] for x in pr)   # (b, a) coded b * NA + a
print(f"[[swap]] sends (guest, M) to ({BN[apply(sw, pr[4])[1]]}, {AN[apply(sw, pr[4])[2]]})")
cu, un = run(terms["curry"], {}), run(terms["uncurry"], {})
curry_ok = sum(apply(apply(apply(cu, ("tab", dict(zip(pr, f)))), a), b) == ev(curry(f)[a], b)
               for f in rules for a in range(NA) for b in range(NB))
un_ok = sum(all(apply(apply(un, apply(cu, ("tab", dict(zip(pr, f))))), x) == f[i] for i, x in enumerate(pr))
            for f in rules)
print(f"[[curry]] agrees with the listed curry on {curry_ok} of {64 * 6} entries; "
      f"[[uncurry]] after [[curry]] gives back {un_ok} of 64 rules")
ends = [(h, k) for h in functions(NA, NA) for k in functions(NB, NB)]
perms = [(h, k) for h, k in ends if len(set(h)) == NA and len(set(k)) == NB]
def natural(f, maps):                     # f(h a, k b) = (k x h)(f(a, b)) for every pair (h, k)
    return all(f[h[a] * NB + k[b]] == k[f[a * NB + b] // NA] * NA + h[f[a * NB + b] % NA]
               for h, k in maps for a in range(NA) for b in range(NB))
cands = functions(NA * NB, NA * NB)
by_all = [f for f in cands if natural(f, ends)]
by_perm = sum(natural(f, perms) for f in cands)
print(f"functions A x B -> B x A: {len(cands)}; natural for all {len(functions(NA, NA))} x {len(functions(NB, NB))} = {len(ends)} "
      f"relabellings: {len(by_all)}, and it is [[swap]]: {'yes' if by_all == [swap_table] else 'no'}")
print(f"mistake, naturality tested on the {len(perms)} one-to-one relabellings only: {by_perm} pass")
def prove(G, goal):                       # Dyckhoff's search; the first six rules lose nothing
    for i, h in enumerate(G):
        rest = G[:i] + G[i + 1:]
        if isinstance(h, tuple) and h[0] == "*": return prove(rest + [h[1], h[2]], goal)
        if isinstance(h, tuple) and isinstance(h[1], tuple) and h[1][0] == "*":
            return prove(rest + [IMP(h[1][1], IMP(h[1][2], h[2]))], goal)
        if isinstance(h, tuple) and isinstance(h[1], str) and h[1] in rest: return prove(rest + [h[2]], goal)
    if goal in G: return True
    if isinstance(goal, tuple) and goal[0] == "*": return prove(G, goal[1]) and prove(G, goal[2])
    if isinstance(goal, tuple): return prove(G + [goal[1]], goal[2])
    for i, h in enumerate(G):             # the one rule that needs a choice: (C -> D) -> B
        if isinstance(h, tuple) and isinstance(h[1], tuple) and h[1][0] == "->":
            rest = G[:i] + G[i + 1:]
            if prove(rest + [IMP(h[1][2], h[2])], h[1]) and prove(rest + [h[2]], goal): return True
    return False
def value(t, v):          # two stages: 0 never true, 1 true only later, 2 true from the start
    if isinstance(t, str): return v[t]
    return min(value(t[1], v), value(t[2], v)) if t[0] == "*" else (2 if value(t[1], v) <= value(t[2], v) else value(t[2], v))
stages = [dict(zip("PQR", r)) for r in functions(3, 3)]   # 27 Kripke rows
rows = [v for v in stages if 1 not in v.values()]          # values 0 and 2 only: the 8 truth-table rows
forms = [(n, typeof(terms[n], {})) for n in ("swap", "curry", "uncurry", "const")]
forms += [("nested if", IMP(IMP(IMP(P, Q), R), IMP(Q, R))), ("Peirce's law", IMP(IMP(IMP(P, Q), P), P)), ("guess", IMP(IMP(P, Q), Q))]
print("== the formulas alone: proof search, truth table (8 rows of P, Q, R), two-stage Kripke table (27 rows) ==")
found, rows_true, kripke = {}, {}, {}
for name, t in forms:
    found[name], rows_true[name], kripke[name] = prove([], t), sum(value(t, v) == 2 for v in rows), sum(value(t, v) == 2 for v in stages)
    print(f"{name}: {show(t, ' and ')[1:-1]}: proof found {'yes' if found[name] else 'no'}; "
          f"true in {rows_true[name]} of 8 rows and {kripke[name]} of 27 two-stage rows")
assert len(rules) == NC ** (NA * NB) == 64 and len(curried) == len(expo) ** NA == 64   # count vs power law
assert back1 == back2 == 64 and len(set(map(curry, rules))) == 64 and nat == 256
assert g == (7, 1) and expo[7] == (1, 1, 1) and expo[1] == (0, 0, 1) and ev(g[1], 2) == 1
assert curry_ok == 384 and un_ok == 64 and by_all == [swap_table] and by_perm == 2   # interpreter; one natural arrow
assert homs(2, 2) == 2 and homs(3, 3) == 3 and homs(1, 2) == homs(1, 3) == 1
assert all(typeof(terms[n], {}) is None for n in ("bad", "bad apply")) and typeof(terms["same"], {}) != typeof(terms["swap"], {})
assert all(found[n] and rows_true[n] == 8 and kripke[n] == 27 for n, _ in forms[:5])   # provable means true everywhere
assert [(found[n], rows_true[n], kripke[n]) for n in ("Peirce's law", "guess")] == [(False, 8, 24), (False, 6, 18)]
print("ALL CHECKS PASS")
