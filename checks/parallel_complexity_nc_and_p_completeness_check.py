# NC and P-completeness -- the check behind the card.  Standard library only.
# Part 1: 1,024 transactions totalled and running-totalled in parallel rounds.  Part 2:
# a machine's run as a circuit (circuit value).  Part 3: Barrington's width-5 programs.
N, M32 = 1024, (1 << 32) - 1
amounts = [(i * 7919) % 20001 - 10000 for i in range(N)]       # pence, -100.00 to +100.00
def tree(xs, op):                        # each round combines neighbouring pairs at once
    rounds = ops = 0
    while len(xs) > 1:
        nxt = [op(xs[j], xs[j + 1]) for j in range(0, len(xs) - 1, 2)]
        xs, rounds, ops = nxt + xs[len(xs) - len(xs) % 2:], rounds + 1, ops + len(nxt)
    return xs[0], rounds, ops
def scan(xs, plan):                      # prefix sums: each round does x[j] += x[j - s]
    x, adds = xs[:], 0
    for s, starts in plan:               # the new list is built from the old one, all at once
        st, adds = set(starts), adds + len(starts)
        x = [v + x[j - s] if j in st else v for j, v in enumerate(x)]
    return x, sum(len(st) > 0 for _, st in plan), adds      # rounds that do work
L = (N - 1).bit_length()                 # 10 levels for 1,024
brent_kung = [(1 << d, range(2 * (1 << d) - 1, N, 2 << d)) for d in range(L)] + \
             [(1 << d, range(3 * (1 << d) - 1, N, 2 << d)) for d in range(L - 2, -1, -1)]
kogge_stone = [(1 << d, range(1 << d, N)) for d in range(L)]
def fa(a, b, c): return [a ^ b ^ c, (((a & b) | (a & c) | (b & c)) << 1) & M32]
def carry_save(xs):                      # three numbers in, two out: one fixed-depth layer
    xs, sizes = [x & M32 for x in xs], [len(xs)]
    while len(xs) > 2:
        xs = [v for j in range(0, len(xs) - 2, 3) for v in fa(*xs[j:j + 3])] + xs[len(xs) - len(xs) % 3:]
        sizes.append(len(xs))
    t = (xs[0] + xs[1]) & M32
    return (t - (1 << 32) if t >> 31 else t), sizes
# Part 2.  The machine walks right tracking odd (O) or even (E); at the blank it
# halts in A (odd) or R (even).  A cell is (symbol, state or -): 3 x 5 = 15 values.
SYMS, STATES = "01_", "-EOAR"
def flip(q, s): return "O" if (q == "O") != (s == "1") else "E"
def rule(l, m):                          # the new cell, from the cells above-left and above
    (ls, lq), (ms, mq) = divmod(l, 5), divmod(m, 5)
    if mq in (1, 2): return m - mq + (5 - mq if ms == 2 else 0)   # halt at blank, else leave
    if mq in (3, 4): return m
    if lq in (1, 2) and ls != 2: return m + STATES.index(flip(STATES[lq], SYMS[ls]))
    return m
def build_tableau(n):                    # the circuit a log-space machine writes
    gates, depth = [], []                # a gate is (op, inputs); inputs are gate numbers
    def gate(op, ins):
        gates.append((op, ins))
        depth.append(1 + max(depth[i] for i in ins) if ins else 0)
        return len(gates) - 1
    row = [[gate("IN", []) for _ in range(15)] for _ in range(n + 2)]   # cells 0..n, wall
    for _ in range(n + 1):               # one row per step, n + 1 steps
        new = []
        for i in range(n + 1):
            feeds = [[] for _ in range(15)]
            for u in range(15):
                for v in range(15):
                    feeds[rule(u, v)].append(gate("AND", [row[i - 1][u], row[i][v]]))
            new.append([gate("OR", f) for f in feeds])
        row = new + [row[-1]]            # row[-1], the blank wall, stays left of cell 0
    out = gate("OR", [c[s * 5 + 3] for c in row[:-1] for s in range(3)])
    return gates, depth[out], out
def evaluate(gates, w, out):             # circuit value: one gate after another, in order
    cells = [SYMS.index(s) * 5 + (i == 0) for i, s in enumerate(w + "_")] + [10]
    val = [int(c == v) for c in cells for v in range(15)]
    for op, ins in gates[len(val):]:
        val.append(int(any(val[i] for i in ins)) if op == "OR" else int(all(val[i] for i in ins)))
    return val[out]
# Part 3.  Permutations of 0..4 as tuples; compose(p, q) does p first, then q.
def compose(p, q): return tuple(q[i] for i in p)
def inv(p): return tuple(sorted(range(len(p)), key=lambda i: p[i]))
def comm(a, b): return compose(compose(compose(a, b), inv(a)), inv(b))
def conj(t, p): return compose(compose(inv(t), p), t)
def perms(w): return [(i,) + tuple(x + (x >= i) for x in p) for i in range(w) for p in perms(w - 1)] if w else [()]
def cycles(p):
    seen, out = set(), []
    for i in range(len(p)):
        c = []
        while i not in seen: seen.add(i); c.append(i + 1); i = p[i]
        if c: out.append(c)
    return out
def ctype(p): return sorted(len(c) for c in cycles(p))
def show(p): return "".join("(" + " ".join(map(str, c)) + ")" for c in cycles(p) if len(c) > 1) or "e"
S5, E5, A0 = perms(5), tuple(range(5)), (1, 2, 3, 4, 0)       # A0 is (1 2 3 4 5)
B0 = next(b for b in S5 if ctype(b) == [5] and ctype(comm(A0, b)) == [5])
def build(f, s, commute=False):          # a program computing f "via s": s when 1, e when 0
    if f[0] == "x": return [(f[1], E5, s)]
    if f[0] == "not":                    # compute f via s^-1, then do s once more at the end
        p = build(f[1], inv(s), commute)
        return p[:-1] + [(p[-1][0], compose(p[-1][1], s), compose(p[-1][2], s))]
    t = next(t for t in S5 if conj(t, comm(A0, B0)) == s)
    a, b = (s, s) if commute else (conj(t, A0), conj(t, B0))   # commute: the broken AND
    return sum((build(g, h, commute) for g, h in ((f[1], a), (f[2], b), (f[1], inv(a)), (f[2], inv(b)))), [])
def run_program(prog, bits):
    r = E5
    for i, p0, p1 in prog: r = compose(r, p1 if bits[i] else p0)
    return r
def OR(f, g): return ("not", ("and", ("not", f), ("not", g)))
a0, a1, b0, b1 = (("x", i) for i in range(4))
CARRY = OR(("and", a1, b1), ("and", OR(a1, b1), ("and", a0, b0)))
running, total = [], 0
for a in amounts:                        # road one for Part 1: one add at a time
    total += a; running.append(total)
t_sum, t_rounds, t_adds = tree(amounts, lambda x, y: x + y)
(bk, bk_rounds, bk_adds), (ks, ks_rounds, ks_adds) = scan(amounts, brent_kung), scan(amounts, kogge_stone)
cs_total, cs_sizes = carry_save(amounts)
yn = lambda c: "yes" if c else "no"
print(f"statement: {N} lines, from {min(amounts)} to {max(amounts)} pence; closing balance {total} pence")
print(f"one at a time: {N - 1} adds in {N - 1} rounds; balanced tree: {t_adds} adds in {t_rounds} rounds, total {t_sum}")
up = [len(st) for _, st in brent_kung[:L] if st]       # up-sweep rounds that do work, and their adds
print(f"running balances, Brent-Kung: {bk_adds} adds in {bk_rounds} rounds ({sum(up)} in {len(up)} up, "
      f"{bk_adds - sum(up)} in {bk_rounds - len(up)} down); all {N} match: {yn(bk == running)}")
print(f"running balances, Kogge-Stone: {ks_adds} adds in {ks_rounds} rounds; all {N} match: {yn(ks == running)}")
print(f"balances after lines 1, 2, 3: {running[0]}, {running[1]}, {running[2]}; lowest {min(running)}, highest {max(running)}")
print(f"carry-save: numbers left {' '.join(map(str, cs_sizes))}; total {cs_total}")
print(f"carry-save gate depth: {len(cs_sizes) - 1} layers x 6 + 13 for the last add = {(len(cs_sizes) - 1) * 6 + 13}")
print(f"OR of {N} bits: depth 1 with one unbounded gate; depth {L} with {N - 1} two-input gates")
for n, words in ((4, 16), (5, 32), (8, 256), (16, 4)):
    gates, dep, out = build_tableau(n)
    size = sum(op != "IN" for op, _ in gates)
    ws = [format(v * 4369 + 1 if n == 16 else v, f"0{n}b") for v in range(words)]   # n=16: 1, 4, 5, 7 ones
    right = sum(evaluate(gates, w, out) == w.count("1") % 2 for w in ws)   # against counting
    print(f"tableau n={n}: {size} gates, 240(n+1)^2+1 = {240 * (n + 1) ** 2 + 1}; depth {dep}, 2(n+1)+1 = {2 * n + 3}; right on {right} of {words}")
    assert size == 240 * (n + 1) ** 2 + 1 and dep == 2 * n + 3 and right == words
fives = [p for p in S5 if ctype(p) == [5]]
good = sum(ctype(comm(a, b)) == [5] for a in fives for b in fives)
print(f"S5: {len(S5)} permutations, {len(fives)} five-cycles; pairs whose commutator is a five-cycle: {good} of {len(fives) ** 2}")
print(f"chosen pair: a = {show(A0)}, b = {show(B0)}; a then b then a^-1 then b^-1 = {show(comm(A0, B0))}")
U = {w: sum(ctype(a) == ctype(b) == ctype(comm(a, b)) != [1] * w for a in perms(w) for b in perms(w)) for w in (3, 4, 5)}
for w in U: print(f"width {w}: pairs a, b in one class other than e, commutator in that class too: {U[w]}")
inputs = [(a & 1, a >> 1, b & 1, b >> 1) for a in range(4) for b in range(4)]
carry = [int(x[0] + 2 * x[1] + x[2] + 2 * x[3] >= 4) for x in inputs]
prog, bad = build(CARRY, A0), build(CARRY, A0, commute=True)
outs = [run_program(prog, x) for x in inputs]
ok = sum(o == (A0 if c else E5) for o, c in zip(outs, carry))
print(f"carry-out program: length {len(prog)}, bound 4^3 = 64; right on {ok} of 16, carry 1 on {sum(carry)}")
top, rounds, _ = tree([p1 for _, _, p1 in prog], compose)
print(f"its {len(prog)} permutations multiplied in a balanced tree: {rounds} rounds; same product: {yn(top == run_program(prog, (1, 1, 1, 1)))}")
wrong = sum((run_program(bad, x) == A0) == c for x, c in zip(inputs, carry))
print(f"what breaks, a commuting pair in the AND step: right on {wrong} of 16")
assert t_sum == total == cs_total == sum(amounts) and t_rounds == L
assert bk == running and ks == running and (bk_rounds, bk_adds, ks_adds) == (2 * L - 1, 2 * N - L - 2, L * N - N + 1)
assert U[3] == U[4] == 0 < good <= U[5] and good == len(fives) * sum(ctype(comm(A0, b)) == [5] for b in fives)   # by symmetry
assert top == run_program(prog, (1, 1, 1, 1)) and ok == 16 and rounds == 6 and wrong < 16
print("ALL CHECKS PASS")
