# P versus NP: what is known -- the check behind the card.  Standard library only.
# One plain DPLL solver solves a staff rota, factors a number and stalls on pigeonhole
# formulas; an adversary fools an oracle machine.  A clause lists literals, +v or -v.

def dpll(clauses, nvars):                # returns (assignment or None, search nodes)
    val, nodes = [0] * (nvars + 1), [0]  # val: +1 true, -1 false, 0 not set yet
    def setlit(lit, trail):
        val[abs(lit)] = 1 if lit > 0 else -1
        trail.append(abs(lit))
    def propagate(trail):                # a clause with one free literal forces it
        changed = True
        while changed:
            changed = False
            for cl in clauses:
                if any(val[abs(l)] * l > 0 for l in cl):
                    continue
                free = [l for l in cl if val[abs(l)] == 0]
                if not free:
                    return False         # every literal false: a dead end
                if len(free) == 1:
                    setlit(free[0], trail)
                    changed = True
        return True
    def search(lit):
        nodes[0] += 1
        trail = []
        if lit: setlit(lit, trail)
        if propagate(trail):
            free = [v for v in range(1, nvars + 1) if val[v] == 0]
            if not free or search(free[0]) or search(-free[0]):
                return True
        for v in trail:
            val[v] = 0
        return False
    return ([v > 0 for v in val] if search(0) else None), nodes[0]

def satisfied(clauses, a):               # the verifier V(x, c): one pass, no search
    return all(any(a[abs(l)] == (l > 0) for l in cl) for cl in clauses)
yn = lambda t: "yes" if t else "no"

# 1. The rota: staff A, B, C; shifts Mon-early, Mon-late, Tue-early, Tue-late.
x = lambda s, t: 1 + 4 * s + t
rota = [[x(s, t) for s in range(3)] for t in range(4)]                 # each shift covered
rota += [[-x(s, t), -x(r, t)] for t in range(4) for s in range(3) for r in range(s + 1, 3)]
rota += [[-x(s, d), -x(s, d + 1)] for s in range(3) for d in (0, 2)]   # one shift a day
rota += [[-x(1, 0)]]                                                   # B not Mon-early
rsol, rnodes = dpll(rota, 12)
shifts = ["Mon-early", "Mon-late", "Tue-early", "Tue-late"]
found = [f"{'ABC'[s]}:{shifts[t]}" for t in range(4) for s in range(3) if rsol[x(s, t)]]
cube = [[0] + [(m >> i) & 1 for i in range(12)] for m in range(4096)]
brute = sum(satisfied(rota, [a == 1 for a in pt]) for pt in cube)
def poly(a, p):                          # arithmetised rota: clause -> 1 - prod(1 - literal)
    out = 1
    for cl in rota:
        miss = 1
        for l in cl:
            miss = miss * (1 - a[l] if l > 0 else a[-l]) % p
        out = out * (1 - miss) % p
    return out
psum = sum(poly(pt, 1009) for pt in cube)
print(f"rota: 12 variables, {len(rota)} clauses; DPLL nodes {rnodes}; verifier says {yn(satisfied(rota, rsol))}")
print("rota found: " + ", ".join(found))
print(f"valid rotas: brute force over 2^12 = 4096 settings {brute}; polynomial summed over them {psum}")
print(f"the polynomial at x = 2 for every variable, mod 97: {poly([2] * 13, 97)}")

# 2. Factoring as satisfiability: bits of p and q, a school multiplier of AND, XOR and
#    majority gates (one clause per truth-table row), the product's bits pinned to N.
def factor_cnf(n, b):
    cl, top = [], [2 * b]
    def gate(f, ins):
        top[0] += 1
        for m in range(1 << len(ins)):
            bits = [(m >> i) & 1 for i in range(len(ins))]
            cl.append([-v if bit else v for v, bit in zip(ins, bits)] + [top[0] if f(bits) else -top[0]])
        return top[0]
    AND, XOR, MAJ = (lambda t: t[0] & t[1]), (lambda t: sum(t) % 2), (lambda t: int(sum(t) >= 2))
    acc = [gate(AND, [1 + j, b + 1]) for j in range(b)]
    for i in range(1, b):                # add row i, shifted i places, with ripple carries
        row = [gate(AND, [1 + j, b + 1 + i]) for j in range(b)]
        out, c = acc[:i], None
        for j in range(b):
            pair = [u for u in (acc[i + j] if i + j < len(acc) else None, row[j], c) if u is not None]
            out.append(gate(XOR, pair))
            c = gate(MAJ if len(pair) == 3 else AND, pair)
        acc = out + [c]
    cl += [[acc[k] if (n >> k) & 1 else -acc[k]] for k in range(2 * b)]
    cl += [list(range(2, b + 1)), list(range(b + 2, 2 * b + 1))]       # p >= 2, q >= 2
    return cl, top[0]
def formula_size(b):                     # counted by hand on the card
    return 3 * b * b, 20 * b * b - 22 * b + 2

built = [(factor_cnf(1, b)[1], len(factor_cnf(1, b)[0])) for b in range(2, 9)]
N, B = 60491, 8
cl, nv = factor_cnf(N, B)
sol, nodes = dpll(cl, nv)
p, q = (sum(1 << j for j in range(B) if sol[off + 1 + j]) for off in (0, B))
trial = next(d for d in range(2, N) if N % d == 0)
v, c = formula_size(1024)
print(f"formula sizes built for b = 2..8 match 3b^2 and 20b^2 - 22b + 2: {yn(built == [formula_size(b) for b in range(2, 9)])}")
print(f"b = {B} bits each: b^2 = {B * B}, 20b^2 = {20 * B * B}, 22b = {22 * B}; product bits {2 * B}, below 2^{2 * B} = {2 ** (2 * B)}")
print(f"factor N = {N}: {nv} variables, {len(cl)} clauses; DPLL nodes {nodes}; p = {p}, q = {q}")
print(f"trial division finds {trial} x {N // trial}; check p x q = {p * q}")
print(f"2048-bit RSA modulus as a formula: {v:,} variables, {c:,} clauses")

# 3. Where the solver stalls: n + 1 pigeons into n holes, which can never fit.
php_nodes = []
for n in range(1, 7):
    y = lambda i, h: 1 + n * i + h
    php = [[y(i, h) for h in range(n)] for i in range(n + 1)]
    php += [[-y(i, h), -y(j, h)] for h in range(n) for i in range(n + 1) for j in range(i + 1, n + 1)]
    res, k = dpll(php, n * (n + 1))
    php_nodes.append(k)
    print(f"pigeonhole {n + 1} into {n}: {n * (n + 1)} variables, {len(php)} clauses, "
          f"satisfiable {yn(res is not None)}, DPLL nodes {k}")

# 4. Relativisation: an oracle is a set of strings, asked about one at a time.  "Does it
#    hold a string of length L?" is easy with a guess; fewer than 2^L questions are fooled.
def machine(oracle, length, budget, asked):   # asks strings 0, 1, 2, ... while the budget lasts; logs each
    return any(asked.add(s) or s in oracle for s in range(min(budget, 2 ** length)))
L, budget, asked = 10, 2 ** 10 - 1, set()
says_empty = machine(set(), L, budget, asked)                     # the adversary watches this run
hidden = set(sorted(set(range(2 ** L)) - asked)[:1])              # and hides one string never asked
says_hidden = machine(hidden, L, budget, set())
print(f"oracle, L = {L}: {2 ** L} strings of length {L}; machine asks {len(asked)}, answers {yn(says_empty)} on the empty oracle")
print(f"adversary adds {', '.join(format(s, 'b') for s in hidden) or 'nothing'}: machine still answers {yn(says_hidden)}; "
      f"the truth is {yn(len(hidden) > 0)}; the certificate check asks 1 question")

# 5. Brute force against a polynomial budget.
for m in (10, 20, 40, 60):
    print(f"n = {m}: 2^n = {2 ** m:,}; n^3 = {m ** 3:,}")
cross = next(m for m in range(2, 100) if all(2 ** k > k ** 3 for k in range(m, 100)))
print(f"2^n passes n^3 for good at n = {cross}; at n = 9: {2 ** 9} vs {9 ** 3}")

assert brute == psum == 24 and satisfied(rota, rsol)               # three roads to the rota
assert p * q == N and sorted([p, q]) == [trial, N // trial]        # solver against trial division
assert built == [formula_size(b) for b in range(2, 9)]             # construction against count
assert all(php_nodes[i + 1] > 6 * php_nodes[i] for i in range(2, 5))  # each step over 6x
assert not says_empty and says_hidden != (len(hidden) > 0)      # the adversary wins
assert cross == 10
print("ALL CHECKS PASS")
