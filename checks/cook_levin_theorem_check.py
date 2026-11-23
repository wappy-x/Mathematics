# Cook-Levin: write a checker's whole run as clauses (an AND of ORs), then test it.
# The tape machine follows the Turing-machines card: state, read, write, move, next.
from itertools import product
DIG, SYM, ST, W = "1234", "1234X#", ["P", "C1", "C2", "C3", "C4", "B", "A", "R"], 5
ROW = "1__4#"                      # top row of a 4 by 4 sudoku; _ is an empty square

def delta(q, s):                   # (write, move, next); None = no rule
    if q == "P" and s in DIG: return ("X", 1, "C" + s)
    if q == "P" and s == "#": return ("#", -1, "A")
    if q[0] == "C" and s in DIG: return (s, 1, q) if s != q[1] else (s, 1, "R")
    if q[0] == "C" and s == "#": return ("#", -1, "B")
    if q == "B" and s in DIG: return (s, -1, "B")
    if q == "B" and s == "X": return ("X", 1, "P")
    return None

def run(tape, T):                  # road 1: run the machine; A and R stay put
    tape, q, h, rows = list(tape), "P", 0, []
    for i in range(T + 1):
        rows.append((q, h, "".join(tape)))
        if q in "AR" or i == T: continue
        r = delta(q, tape[h])
        if r is None: return rows, False
        tape[h], h, q = r[0], h + r[1], r[2]
    return rows, q == "A"

def fill(c):                      # the row with its two empty squares filled from c
    it = iter(c); return "".join(next(it) if x == "_" else x for x in ROW)

def formula(T, cert=DIG, frame=True, accept=True):
    V, C = {}, []
    def v(*k): return V.setdefault(k, len(V) + 1)
    def one(xs):                   # exactly one: at least one, and no two
        C.append(xs)
        C.extend([-xs[a], -xs[b]] for a in range(len(xs)) for b in range(a + 1, len(xs)))
    for i in range(T + 1):
        for j in range(W): one([v("c", i, j, s) for s in SYM])
        one([v("q", i, q) for q in ST]); one([v("h", i, j) for j in range(W)])
    C += [[v("q", 0, "P")], [v("h", 0, 0)]]
    for j, s in enumerate(ROW):    # start row: givens fixed, empty squares from cert
        C.append([v("c", 0, j, s)] if s != "_" else [v("c", 0, j, d) for d in cert])
    for i, j, q, s in product(range(T), range(W), ST, SYM):
        pre = [-v("h", i, j), -v("q", i, q), -v("c", i, j, s)]
        r = (s, 0, q) if q in "AR" else delta(q, s)
        if r is None or not 0 <= j + r[1] < W: C.append(pre); continue
        C += [pre + [v("c", i + 1, j, r[0])], pre + [v("q", i + 1, r[2])], pre + [v("h", i + 1, j + r[1])]]
    if frame:                      # a cell away from the head keeps its symbol
        C += [[v("h", i, j), -v("c", i, j, s), v("c", i + 1, j, s)] for i, j, s in product(range(T), range(W), SYM)]
    if accept: C.append([v("q", T, "A")])
    return V, C

def solve(V, C, fix=(), limit=10 ** 9):   # roads 2 and 3: a small SAT solver that counts models
    occ, val, models = {}, {}, []
    for k, c in enumerate(C):
        for x in c: occ.setdefault(-x, []).append(k)
    def setlit(x, trail):          # make x true, then follow every forced literal
        stack = [x]
        while stack:
            x = stack.pop()
            if val.get(abs(x)) is not None:
                if val[abs(x)] != (x > 0): return False
                continue
            val[abs(x)] = x > 0; trail.append(abs(x))
            for k in occ.get(x, []):
                if any(val.get(abs(y)) == (y > 0) for y in C[k]): continue
                free = [y for y in C[k] if val.get(abs(y)) is None]
                if not free: return False
                if len(free) == 1: stack.append(free[0])
        return True
    def go(n):
        if len(models) >= limit: return
        x = next((a for a in range(n, len(V) + 1) if val.get(a) is None), None)
        if x is None: models.append(dict(val)); return
        solve.branches += 1        # a branch: try x true, then x false
        for lit in (x, -x):
            trail = []
            if setlit(lit, trail): go(x + 1)
            for a in trail: val[a] = None
    if all(setlit(x, []) for x in [c[0] for c in C if len(c) == 1] + list(fix)): go(1)
    return models
solve.branches = 0                 # branches the solver has taken so far

def bound(T, W, S, Q):             # clause count from the recipe, without building anything
    one = lambda m: 1 + m * (m - 1) // 2
    return (T + 1) * (W * one(S) + one(Q) + one(W)) + T * W * S * (3 * Q + 1) + 2 + W + 1

def sat_fillings(F, alphabet):     # fillings of the two empty squares whose formula is satisfiable
    V, C = F
    return ["".join(c) for c in product(alphabet, repeat=2)
            if solve(V, C, [V[("c", 0, 1, c[0])], V[("c", 0, 2, c[1])]], 1)]

T = next(i for i, r in enumerate(run("1234#", 99)[0]) if r[0] == "A")
print("machine: 8 states, 6 tape symbols; row", ROW[:4], "; steps to accept:", T)
print("the run on the row 1 2 3 4, one row per step:")
for i, (q, h, t) in enumerate(run("1234#", T)[0]):
    print((f"step {i:2d} state {q:2s} tape " + "".join(f"[{c}]" if k == h else f" {c} " for k, c in enumerate(t))).rstrip())
V, C = formula(T)
cl = [len(c) for c in C]
print("variables", len(V), "clauses", len(C), "literals", sum(cl))
print("clauses by length:", ", ".join(f"{k}: {cl.count(k)}" for k in sorted(set(cl))))
acc = sum(1 for c in C if c == [V[("q", T, "A")]])
fam = [sum(1 for c in C if (len(c) == 2 and c[0] < 0) or (min(c) > 0 and len(c) >= 5)),
       sum(1 for c in C if min(c) > 0 and len(c) <= 4) - acc, sum(1 for c in C if len(c) == 4 and c[0] < 0),
       sum(1 for c in C if len(c) == 3 and max(c) < 0), sum(1 for c in C if len(c) == 3 and c[0] > 0), acc]
print("families: exactly-one", fam[0], "start", fam[1], "rule", fam[2], "forbidden", fam[3], "frame", fam[4], "accept", fam[5])
print("recipe bound on clauses", bound(T, W, 6, 8), "built", len(C))
direct = ["".join(c) for c in product(DIG, repeat=2) if run(fill(c), T)[1]]
print("road 1, run the machine on all 16 fillings: accepted", *direct)
fixed, branched = sat_fillings((V, C), DIG), solve.branches
print("road 2, formula with each filling fixed: satisfiable", *fixed, "; solver branches", branched)
models = solve(V, C)
read = ["".join(d for j in (1, 2) for d in DIG if m[V[("c", 0, j, d)]]) for m in models]
print("road 3, formula left free: satisfying assignments", len(models), "read back as", *read)
for t in (10, 100, 1000):
    print(f"growth: {t} steps on {2 * t + 1} cells: variables {(t + 1) * (7 * (2 * t + 1) + 8)}, clauses at most {bound(t, 2 * t + 1, 6, 8)}")
assert direct == fixed == sorted(read) == ["23", "32"] and len(models) == 2 and branched == 0
assert len(V) == (T + 1) * (6 * W + 8 + W) and bound(T, W, 6, 8) == len(C) + 2 * fam[3] and sum(fam) == len(C)
for m, filling in zip(models, read):  # each assignment, read row by row, is the machine's own run
    tab = [(next(q for q in ST if m[V[("q", i, q)]]), next(j for j in range(W) if m[V[("h", i, j)]]),
            "".join(s for j in range(W) for s in SYM if m[V[("c", i, j, s)]])) for i in range(T + 1)]
    assert tab == run(fill(filling), T)[0]
short = solve(*formula(T - 1))
anys = sat_fillings(formula(T, SYM), SYM)
anyrun = ["".join(c) for c in product(SYM, repeat=2) if run(fill(c), T)[1]]
noacc = sat_fillings(formula(T, accept=False), DIG)
def assign(V, tab):                # the variables that a table of rows makes true
    on = {("q", i, q) for i, (q, h, t) in enumerate(tab)} | {("h", i, h) for i, (q, h, t) in enumerate(tab)}
    on |= {("c", i, j, s) for i, (q, h, t) in enumerate(tab) for j, s in enumerate(t)}
    return {V[k]: k in on for k in V}
good = run("1234#", T)[0]
fakes = [[("P", 0, fill(c))] + good[1:] for c in product(DIG, repeat=2)]
Vn, Cn = formula(T, frame=False)
holds = lambda C, a: all(any(a[abs(x)] == (x > 0) for x in c) for c in C)
noframe = [f[0][2][1:3] for f in fakes if holds(Cn, assign(Vn, f))]
assert len(noframe) == 16 and not holds(C, assign(V, fakes[0])) and holds(C, assign(V, good))
assert anys == anyrun and len(short) == 0 and len(noacc) == 16
print("break: step bound", T - 1, "instead of", T, ": satisfying assignments", len(short))
print("break: empty squares may hold any tape symbol: satisfiable", len(anys), "of 36:", *anys)
print("break: no accept clause: satisfiable fillings", len(noacc), "of 16")
print("break: no frame clauses: satisfied by a faked run for", len(noframe), "of 16 fillings")
print("ALL CHECKS PASS")
