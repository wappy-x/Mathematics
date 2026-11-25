# Formal proofs and soundness: a checker for natural-deduction lines, and truth in every small structure.
from itertools import product
VARS = "xyz"  # variables; any other name, such as a, is a constant
def A(p, *ts): return ("atom", p, ts)
Imp, All, Ex = (lambda f, g: ("imp", f, g)), (lambda v, f: ("all", v, f)), (lambda v, f: ("ex", v, f))
tf = lambda b: "true" if b else "false"

def show(f):
    if f[0] == "atom": return f[1] + "(" + ", ".join(f[2]) + ")"
    if f[0] == "imp": return "(" + show(f[1]) + " -> " + show(f[2]) + ")"
    return ("forall " if f[0] == "all" else "exists ") + f[1] + " " + show(f[2])

def free(f):  # free names: free variables and constants
    if f[0] == "atom": return set(f[2])
    if f[0] == "imp": return free(f[1]) | free(f[2])
    return free(f[2]) - {f[1]}

def sub(f, x, t):  # f with t put in for the free x; None if a quantifier would capture t
    if f[0] == "atom": return ("atom", f[1], tuple(t if s == x else s for s in f[2]))
    if f[0] == "imp":
        l, r = sub(f[1], x, t), sub(f[2], x, t)
        return None if l is None or r is None else ("imp", l, r)
    if f[1] == x or x not in free(f[2]): return f
    if f[1] == t: return None
    b = sub(f[2], x, t)
    return None if b is None else (f[0], f[1], b)

def check(lines, side=True):  # each line is (rule, uses, claim); gives (open assumptions, claim) per line, or why it fails
    done = []
    for n, (rule, u, claim) in enumerate(lines, 1):
        bad = lambda why: "rejected at line %d: %s" % (n, why)
        if rule in ("AE", "EE", "EI") and (claim if rule == "EI" else done[u[0] - 1][1])[0] != ("all" if rule == "AE" else "ex"): return bad("wrong shape for " + rule)
        if rule == "assume": G, f = frozenset([claim]), claim
        elif rule == "->E":
            (G1, f1), (G2, f2) = done[u[0] - 1], done[u[1] - 1]
            if f1[0] != "imp" or f1[1] != f2: return bad("line %d is not the if-part of line %d" % (u[1], u[0]))
            G, f = G1 | G2, f1[2]
        elif rule == "->I": G1, f1 = done[u[0] - 1]; G, f = G1 - {u[1]}, Imp(u[1], f1)
        elif rule == "AE":
            G, f1 = done[u[0] - 1]; f = sub(f1[2], f1[1], u[1])
            if f is None: return bad(u[1] + " is not free for " + f1[1])
        elif rule == "AI":
            G, f1 = done[u[0] - 1]; f = All(u[1], f1)
            if side and any(u[1] in free(h) for h in G): return bad(u[1] + " is free in an open assumption")
        elif rule == "EI":
            G, f1 = done[u[0] - 1]; f = claim
            if sub(claim[2], claim[1], u[1]) != f1: return bad("line %d is not an instance" % u[0])
        elif rule == "EE":
            (G1, f1), (G2, f2) = done[u[0] - 1], done[u[1] - 1]; w = u[2]
            rest = G2 - {sub(f1[2], f1[1], w)}
            if side and any(w in free(h) for h in [f1, f2, *rest]): return bad("witness " + w + " is not new")
            G, f = G1 | rest, f2
        if f != claim: return bad("the rule gives " + show(f))
        done.append((G, f))
    return done

def holds(f, M, g):  # M = (size, relations, constants); g gives values to free variables
    n, rel, con = M
    if f[0] == "atom": return tuple(g[t] if t in g else con[t] for t in f[2]) in rel[f[1]]
    if f[0] == "imp": return not holds(f[1], M, g) or holds(f[2], M, g)
    vals = [holds(f[2], M, {**g, f[1]: d}) for d in range(n)]
    return all(vals) if f[0] == "all" else any(vals)

def structures(sig, nmax):  # sig: (name, places); 0 places is a constant. Every structure on {0, ..., n-1}
    for n in range(1, nmax + 1):
        for pick in product(*[range(n) if k == 0 else range(2 ** n ** k) for _, k in sig]):
            rel, con = {}, {}
            for (name, k), c in zip(sig, pick):
                if k == 0: con[name] = c
                else: rel[name] = {t for i, t in enumerate(product(range(n), repeat=k)) if c >> i & 1}
            yield (n, rel, con)

def cases(G, f, sig, nmax):  # every (structure, values) checked, and those making all of G true and f false
    vs = sorted({x for h in [*G, f] for x in free(h) if x in VARS})
    total, bad = 0, []
    for M in structures(sig, nmax):
        for vals in product(range(M[0]), repeat=len(vs)):
            g = dict(zip(vs, vals)); total += 1
            if all(holds(h, M, g) for h in G) and not holds(f, M, g): bad.append((M, g))
    return total, bad

def showM(M, g):
    n, rel, con = M
    s = ["%s = {%s}" % (r, ", ".join(",".join(map(str, t)) if len(t) == 1 else "(%d,%d)" % t for t in sorted(v))) for r, v in rel.items()]
    s += ["%s = %d" % kv for kv in con.items()] + ["%s = %d" % kv for kv in g.items()]
    return "domain {%s}: " % ", ".join(map(str, range(n))) + ", ".join(s)

P, Q = (lambda t: A("P", t)), (lambda t: A("Q", t))
SIG, rule, allP = [("P", 1), ("Q", 1), ("a", 0)], All("x", Imp(P("x"), Q("x"))), All("x", P("x"))
D = {"D1": [("assume", (), rule), ("assume", (), P("a")), ("AE", (1, "a"), Imp(P("a"), Q("a"))), ("->E", (3, 2), Q("a"))],
     "D2": [("assume", (), rule), ("assume", (), Ex("x", P("x"))), ("assume", (), P("y")), ("AE", (1, "y"), Imp(P("y"), Q("y"))),
            ("->E", (4, 3), Q("y")), ("EI", (5, "y"), Ex("x", Q("x"))), ("EE", (2, 6, "y"), Ex("x", Q("x")))],
     "D3": [("assume", (), rule), ("assume", (), allP), ("AE", (2, "x"), P("x")), ("AE", (1, "x"), Imp(P("x"), Q("x"))),
            ("->E", (4, 3), Q("x")), ("AI", (5, "x"), All("x", Q("x"))), ("->I", (6, allP), Imp(allP, All("x", Q("x"))))]}
print("road 1, the checker: every line names one rule and the lines it uses")
checks = 0
for name, lines in D.items():
    out = check(lines); assert isinstance(out, list), out
    print(name + ": line, rule, uses, open assumptions, claim")
    for n, ((r, u, c), (G, f)) in enumerate(zip(lines, out), 1):
        opn = ",".join(str(i) for i, l in enumerate(lines, 1) if l[0] == "assume" and l[2] in G)
        print("  %d %s %s {%s} %s" % (n, r, ",".join(str(x) for x in u if type(x) is int) or "-", opn, show(f)))
        total, bad = cases(G, f, SIG, 3); checks += total
        assert bad == [], (name, n)  # road 3: every accepted line is true in every case, the induction run line by line
print("road 3, soundness line by line: all %d lines of D1 to D3 true in every case: %d checks, 0 failures" % (sum(map(len, D.values())), checks))
M0 = (2, {"P": {(1,)}, "Q": {(1,)}}, {"a": 1})
row = [holds(Imp(P("x"), Q("x")), M0, {"x": d}) for d in (0, 1)]
print("the structure " + showM(M0, {}))
print("  P(x) -> Q(x) at x = 0: %s; at x = 1: %s; so forall x (P(x) -> Q(x)) is %s" % (tf(row[0]), tf(row[1]), tf(holds(rule, M0, {}))))
print("  P(a) is %s and Q(a) is %s" % (tf(holds(P("a"), M0, {})), tf(holds(Q("a"), M0, {}))))
assert row == [True, True] and holds(Q("a"), M0, {}) and not holds(P("x"), M0, {"x": 0})
allM = list(structures(SIG, 3))
prem = [M for M in allM if holds(rule, M, {}) and holds(P("a"), M, {})]
print("road 2, every structure on 1 to 3 elements: %d; both premises true in %d; Q(a) true in %d of those" %
      (len(allM), len(prem), sum(holds(Q("a"), M, {}) for M in prem)))
assert len(allM) == sum(n * 4 ** n for n in (1, 2, 3)) == 228  # n choices for a, 2^n for P, 2^n for Q
assert len(prem) == sum(n * 3 ** (n - 1) for n in (1, 2, 3)) == 34  # a in P, and P inside Q
assert all(holds(Q("a"), M, {}) for M in prem)
R = lambda s, t: A("R", s, t)
Fx, Rxy = Ex("x", P("x")), All("x", Ex("y", R("x", "y")))
F = {"F1 exists x P(x), so P(a)": ([("assume", (), Fx), ("assume", (), P("a")), ("EE", (1, 2, "a"), P("a"))], [Fx], SIG, 3),
     "F2 P(x), so forall x P(x)": ([("assume", (), P("x")), ("AI", (1, "x"), allP)], [P("x")], SIG, 3),
     "F3 forall x exists y R(x, y), so exists y R(y, y)": ([("assume", (), Rxy), ("AE", (1, "y"), Ex("y", R("y", "y")))], [Rxy], [("R", 2)], 2),
     "F4 P(a) -> Q(a) and Q(a), so P(a)": ([("assume", (), Imp(P("a"), Q("a"))), ("assume", (), Q("a")), ("->E", (1, 2), P("a"))], [Imp(P("a"), Q("a")), Q("a")], SIG, 3)}
print("forged proofs: the checker's verdict, then the first structure that refutes the claim")
for (name, (lines, prems, sig, nmax)), why in zip(F.items(), ["witness a is not new", "x is free in an open assumption", "y is not free for x", "line 2 is not the if-part of line 1"]):
    verdict = check(lines); assert verdict == "rejected at line %d: %s" % (len(lines), why), verdict  # caught by the test meant for it
    total, bad = cases(prems, lines[-1][2], sig, nmax)
    assert bad, name  # a countermodel, so by soundness no derivation of the claim exists at all
    print("  %s: %s\n    refuted in %d of %d cases, first: %s" % (name, verdict, len(bad), total, showM(*bad[0])))
_, bad1 = cases([Fx], P("a"), SIG, 3)
per = [sum(1 for M, g in bad1 if M[0] == n) for n in (1, 2, 3)]
print("F1 countermodels by size 1, 2, 3: %s; with the side conditions off, the checker gives %s" %
      (", ".join(map(str, per)), ", ".join(show(check(l, side=False)[-1][1]) for l, _, _, _ in list(F.values())[:2])))
assert per == [0, 8, 72] == [n * (2 ** (n - 1) - 1) * 2 ** n for n in (1, 2, 3)]  # a outside P, P not empty
assert showM(*bad1[0]) == "domain {0, 1}: P = {0}, Q = {}, a = 1"
four = list(structures(SIG, 4))
print("try changing, sizes up to 4: %d structures; premises of D1 true in %d; F1 refuted in %d" % (len(four),
      sum(holds(rule, M, {}) and holds(P("a"), M, {}) for M in four), len(cases([Fx], P("a"), SIG, 4)[1])))
print("ALL CHECKS PASS")
