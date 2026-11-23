# Boolean circuits -- the check behind the card.  Standard library only.  A k-bit adder
# is built from AND, OR and NOT gates three ways: a ripple-carry circuit that shares gates,
# the same adder as a formula (a tree: a shared part is copied each time it is used) and a
# carry-lookahead circuit.  Each runs on real sums; sizes and depths are counted, not assumed.

class Circuit:                        # a gate list; inputs and gates are numbered
    def __init__(s, n): s.ops, s.ins = [("IN", i) for i in range(n)], list(range(n))
    def add(s, *op): s.ops.append(op); return len(s.ops) - 1
    def AND(s, x, y): return s.add("AND", x, y)
    def OR(s, x, y): return s.add("OR", x, y)
    def NOT(s, x): return s.add("NOT", x)
    def size(s): return len(s.ops) - len(s.ins)
    def depths(s):                    # depth: gates on the longest path from an input
        d = []
        for op, *a in s.ops: d.append(0 if op == "IN" else 1 + max(d[x] for x in a))
        return d
    def run(s, bits):
        v = []
        for op, *a in s.ops:
            v.append(bits[a[0]] if op == "IN" else 1 - v[a[0]] if op == "NOT"
                     else v[a[0]] & v[a[1]] if op == "AND" else v[a[0]] | v[a[1]])
        return v

class Formula:                        # a tree: nothing is shared, every use is a copy
    def __init__(s, n): s.ins = [("IN", i) for i in range(n)]
    def AND(s, x, y): return ("AND", x, y)
    def OR(s, x, y): return ("OR", x, y)
    def NOT(s, x): return ("NOT", x)
def t_size(t): return 0 if t[0] == "IN" else 1 + sum(t_size(c) for c in t[1:])
def t_depth(t): return 0 if t[0] == "IN" else 1 + max(t_depth(c) for c in t[1:])
def t_eval(t, bits):
    if t[0] == "IN": return bits[t[1]]
    v = [t_eval(c, bits) for c in t[1:]]
    return 1 - v[0] if t[0] == "NOT" else v[0] & v[1] if t[0] == "AND" else v[0] | v[1]

def xor(m, x, y):                     # (x OR y) AND NOT(x AND y): 4 gates, depth 3
    both = m.AND(x, y)
    return m.AND(m.OR(x, y), m.NOT(both)), both

def ripple(m, k):                     # inputs a0..a(k-1), then b0..b(k-1), low bit first
    a, b = m.ins[:k], m.ins[k:]
    s, c = xor(m, a[0], b[0])         # bit 0: sum bit, and carry a0 AND b0
    out = [s]
    for i in range(1, k):
        t, h = xor(m, a[i], b[i])     # t = a XOR b, h = a AND b
        s, u = xor(m, t, c)           # sum bit, and u = t AND carry-in
        out.append(s); c = m.OR(h, u)
    return out + [c]
def lookahead(m, k):                  # Kogge-Stone: each round doubles the span a carry covers
    a, b = m.ins[:k], m.ins[k:]
    g = [m.AND(a[i], b[i]) for i in range(k)]            # bit i makes a carry
    p = [m.OR(a[i], b[i]) for i in range(k)]             # bit i passes a carry on
    x = [m.AND(p[i], m.NOT(g[i])) for i in range(k)]     # a XOR b
    G, P, d = g, p, 1
    while d < k:
        G, P = ([G[i] if i < d else m.OR(G[i], m.AND(P[i], G[i - d])) for i in range(k)],
                [P[i] if i < d or 2 * d >= k else m.AND(P[i], P[i - d]) for i in range(k)])
        d *= 2
    return [x[0]] + [xor(m, x[i], G[i - 1])[0] for i in range(1, k)] + [G[k - 1]]
def bits_of(a, b, k): return [a >> i & 1 for i in range(k)] + [b >> i & 1 for i in range(k)]
def value(bits): return sum(v << i for i, v in enumerate(bits))
def build(k, how): m = Circuit(2 * k); return m, how(m, k)
def run_sum(m, outs, a, b, k): v = m.run(bits_of(a, b, k)); return value([v[o] for o in outs])

m, outs = build(2, ripple); dep = m.depths()
def name(j): return ["a0", "a1", "b0", "b1"][j] if j < 4 else f"g{j - 3}"
print(f"2-bit adder circuit: {m.size()} gates, depth {max(dep)}; output depths "
      + " ".join(f"s{i}={dep[o]}" for i, o in enumerate(outs)))
ok = sum(run_sum(m, outs, a, b, 2) == a + b for a in range(4) for b in range(4))
print(f"circuit right on {ok} of 16 inputs")
v = m.run(bits_of(1, 3, 2))
print("trace 1 + 3: " + " ".join(f"{name(j)}={v[j]}" for j in range(4, len(v)))
      + f" -> s2 s1 s0 = {v[outs[2]]}{v[outs[1]]}{v[outs[0]]} = {value([v[o] for o in outs])}")
cols = [" ".join(name(j) for j in range(len(dep)) if dep[j] == c) for c in range(max(dep) + 1)]
print("figure, depth columns: " + " | ".join(f"{c}: {s}" for c, s in enumerate(cols)))
fo = ripple(Formula(4), 2)
fs, fd = [t_size(t) for t in fo], [t_depth(t) for t in fo]
fok = sum(value([t_eval(t, bits_of(a, b, 2)) for t in fo]) == a + b for a in range(4) for b in range(4))
print(f"formula: s0={fs[0]} s1={fs[1]} s2={fs[2]} gates, {sum(fs)} in all; "
      f"depths {fd[0]}, {fd[1]}, {fd[2]}; right on {fok} of 16 inputs")
print("unfolding bound, size <= 2^depth - 1: " + ", ".join(f"{a} <= {2 ** d - 1}" for a, d in zip(fs, fd)))
assert ok == 16 and fok == 16 and fd == [dep[o] for o in outs] and all(a <= 2 ** d - 1 for a, d in zip(fs, fd)) and sum(fs) == 2 * m.size()

A, B, ALL, XOR, CARRY = 0b1100, 0b1010, 0b1111, 0b0110, 0b1000   # truth tables, rows ab = 00..11
def fits(nodes, targets, left):       # can `left` more gates reach every target?
    if all(t in nodes for t in targets): return True
    if left == 0: return False
    n = len(nodes)
    new = [ALL ^ x for x in nodes] + [f for i in range(n) for j in range(i + 1, n)
                                     for f in (nodes[i] & nodes[j], nodes[i] | nodes[j])]
    return any(fits(nodes + [w], targets, left - 1) for w in new)
def least_gates(targets): return next(g for g in range(9) if fits([A, B], targets, g))
def least_depth(t):
    level, d = {A, B}, 0
    while t not in level:
        level = (level | {ALL ^ x for x in level} | {x & y for x in level for y in level}
                 | {x | y for x in level for y in level})
        d += 1
    return d
lx, dx, lh = least_gates([XOR]), least_depth(XOR), least_gates([XOR, CARRY])
xc = Circuit(2); xor(xc, 0, 1)
print(f"search: XOR needs {lx} gates (none with {lx - 1}) and depth {dx}; "
      f"half adder (sum and carry) needs {lh} gates")
assert lx == xc.size() and dx == max(xc.depths()) and lh == lx

state = 2026                          # SplitMix64, seed 2026, for test sums
def splitmix():
    global state
    M = (1 << 64) - 1; state = (state + 0x9E3779B97F4A7C15) & M; z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M; z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M
    return z ^ (z >> 31)
for k in (1, 2, 4, 8, 16, 32, 64):
    r, ro = build(k, ripple); l, lo = build(k, lookahead); fo = ripple(Formula(2 * k), k)
    fsz, rd, ld, top = sum(t_size(t) for t in fo), max(r.depths()), max(l.depths()), (1 << k) - 1
    pairs = ([(a, b) for a in range(top + 1) for b in range(top + 1)] if k <= 4 else
             [(top, 1)] + [(splitmix() & top, splitmix() & top) for _ in range(40)])
    good = sum(run_sum(r, ro, a, b, k) == a + b == run_sum(l, lo, a, b, k)
               == value([t_eval(t, bits_of(a, b, k)) for t in fo]) for a, b in pairs)
    print(f"k={k}: ripple {r.size()} gates, depth {rd}; formula {fsz} gates; "
          f"lookahead {l.size()} gates, depth {ld}; {good} of {len(pairs)} sums right")
    assert good == len(pairs) and r.size() == 9 * k - 5 and fsz == 7 * k * k - 2
    assert rd == (3 if k == 1 else 2 * k + 2) == max(t_depth(t) for t in fo) and ld <= 2 * (k - 1).bit_length() + 4

def adder2(a, b, slip):               # the 2-bit adder in plain bit arithmetic, one piece swapped
    a0, a1, b0, b1 = a & 1, a >> 1, b & 1, b >> 1
    c0 = 0 if slip == "carry into bit 1 dropped" else a0 & b0
    s0 = a0 | b0 if slip == "OR for the sum bit" else a0 ^ b0
    s2 = (a1 & b1) | ((a1 ^ b1) & c0)
    s2 = 0 if slip == "answer cut to two bits" else a1 & b1 if slip == "carry out as a1 AND b1" else s2
    return s0 + 2 * (a1 ^ b1 ^ c0) + 4 * s2
miss = [sum(adder2(a, b, "none") != a + b for a in range(4) for b in range(4))]
for slip in ("OR for the sum bit", "carry into bit 1 dropped", "carry out as a1 AND b1", "answer cut to two bits"):
    bad = [(a, b) for a in range(4) for b in range(4) if adder2(a, b, slip) != a + b]
    a, b = bad[-1]; miss.append(len(bad))
    print(f"mistake, {slip}: wrong on {len(bad)} of 16, e.g. {a} + {b} -> {adder2(a, b, slip)}")
wide = ("OR", *[("AND", *[("IN", 3 * i + j) for j in range(3)]) for i in range(3)])   # gates with 3 inputs
print(f"mistake, gates with 3 inputs: an OR of three ANDs, depth {t_depth(wide)}, {t_size(wide)} gates; bound 2^{t_depth(wide)} - 1 = {2 ** t_depth(wide) - 1}")
assert miss == [0, 4, 4, 2, sum(a + b >= 4 for a in range(4) for b in range(4))]
assert t_size(wide) == (3 ** t_depth(wide) - 1) // 2 > 2 ** t_depth(wide) - 1      # a 3-input tree beats the bound
print("ALL CHECKS PASS")
