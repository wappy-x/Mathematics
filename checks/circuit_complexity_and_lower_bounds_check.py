# Circuit lower bounds -- the check behind the card.  Standard library only; itertools only lists
# orderings.  The rota: 8 staff, one bit each (on nights or not); flag it when the count is odd.
from itertools import permutations
from math import log2
M = (1 << 64) - 1
def parity(x):
    return bin(x).count("1") % 2
def implicant_widths(n, f):          # every AND term (3^n of them) that never fires wrongly
    out = []
    for t in range(3 ** n):
        mask = val = 0
        for i in range(n):
            d = t // 3 ** i % 3
            mask, val = (mask | 1 << i, val | (d - 1) << i) if d else (mask, val)
        if mask and all(f(x) for x in range(2 ** n) if x & mask == val):
            out.append(bin(mask).count("1"))
    return out
def build(n, ks):                    # parity as layers of AND/OR, NOT only on inputs
    gates, nodes = [], [[[-2 * i - 1], [-2 * i - 2]] for i in range(n)]
    for lvl, k in enumerate(ks, 1):  # node[v] = gates that together say "this block = v"
        odd, new = lvl % 2 == 1, []
        for b in range(0, len(nodes), k):
            kids, node = nodes[b:b + k], [[], []]
            for v in ((1,) if len(nodes) == k else (0, 1)):
                for a in range(2 ** k):
                    bits = [a >> j & 1 for j in range(k)]
                    if (sum(bits) % 2 == v) != odd:
                        continue     # odd level: OR of ANDs; even level: AND of ORs
                    ins = [r for j, kid in enumerate(kids) for r in kid[bits[j] if odd else 1 - bits[j]]]
                    gates.append((odd, ins)); node[v].append(len(gates) - 1)
            new.append(node)
        nodes = new
    gates.append((len(ks) % 2 == 0, nodes[0][1]))
    return gates
def run(gates, x):                   # literal -(2i+v)-1 means "staff i is v"
    out = []
    for is_and, ins in gates:
        vals = (out[r] if r >= 0 else (x >> (-r - 1) // 2 & 1) == (-r - 1) % 2 for r in ins)
        out.append(all(vals) if is_and else any(vals))
    return int(out[-1])
def depth(gates):
    d = []
    for _, ins in gates:
        d.append(1 + max([d[r] for r in ins if r >= 0] + [0]))
    return d[-1]
def log_road(n, top):                # largest s with s * log2(16 (n + s)^2) below 2^n
    lo, hi = 1, top
    while hi - lo > 1:
        mid = (lo + hi) // 2
        lo, hi = (mid, hi) if mid * log2(16 * (n + mid) ** 2) < 2.0 ** n else (lo, mid)
    return lo
def formula(n, ks):                  # closed-form gate count, no circuit built
    total, m = 1, n
    for k in ks:
        m //= k
        total += m * 2 ** k if m > 1 else 2 ** (k - 1)
    return total
def splitmix(s):
    s = (s + 0x9E3779B97F4A7C15) & M
    z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & M
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M
    return s, z ^ (z >> 31)
print("rota: 8 staff; flag the night when its headcount is odd (parity)")
print(f"rota with staff 1, 2, 5 on: count {bin(0b10011).count('1')}, parity {parity(0b10011)}, flag")
rows = [implicant_widths(n, lambda x: parity(x) == 1) for n in range(2, 9)]
print("depth 2, all 3^n AND terms tested: terms that never fire on an even rota")
print("  staff n      " + "".join(f"{n:>5}" for n in range(2, 9)))
print("  such terms   " + "".join(f"{len(r):>5}" for r in rows))
print("  narrowest    " + "".join(f"{min(r):>5}" for r in rows))
print(f"depth-2 circuit for 8 staff needs {len(rows[-1])} AND gates + 1 OR = {len(rows[-1]) + 1} gates")
seed, tests = 2026, []
for n, ks in [(8, [8]), (8, [4, 2]), (8, [2, 2, 2]), (64, [8, 8]), (64, [4, 4, 4]), (64, [2] * 6)]:
    g = build(n, ks)
    xs = range(256) if n == 8 else []
    if n == 64:
        for _ in range(64):
            seed, r = splitmix(seed); xs.append(r)
    ok = all(run(g, x) == parity(x) for x in xs)
    tests.append((n, depth(g), len(g), formula(n, ks), n * 2 ** max(ks), ok, len(ks) + 1))
    print(f"built n={n:>2} blocks {str(ks):<18} depth {tests[-1][1]} gates {len(g):>4} formula {formula(n, ks):>4}"
          f" bound n*2^k {n * 2 ** max(ks):>5} inputs tested {len(xs):>3} all right {'yes' if ok else 'no'}")
print(f"64 staff at depth 2: 2^63 + 1 = {formula(64, [64])} gates")
bad = 0
for t in range(3 ** 8):              # every restriction: fixed staff 0/1, the rest free
    fixed = [t // 3 ** i % 3 for i in range(8)]
    free = [i for i in range(8) if fixed[i] == 0]
    base = sum(1 << i for i in range(8) if fixed[i] == 2)
    vals = {parity(base | sum(1 << free[j] for j in range(len(free)) if a >> j & 1)) for a in range(2 ** len(free))}
    bad += (len(vals) == 1) != (not free)
print(f"all 6561 restrictions of 8 staff: parity settled only when nobody is free: {'yes' if bad == 0 else 'no'}")
N, cnt = 100000, [0, 0, 0]
for _ in range(N):                   # each staff: free 2/8, fixed off 3/8, fixed on 3/8
    pick = []
    for i in range(8):
        seed, r = splitmix(seed); pick.append(r % 8)
    nfree = sum(p < 2 for p in pick)
    cnt[0] += all(p < 2 or p >= 5 for p in pick[:4]) and any(p < 2 for p in pick[:4])
    cnt[1] += nfree > 0; cnt[2] += nfree
exact = [((5 / 8) ** 4 - (3 / 8) ** 4), 1 - (3 / 4) ** 8, 2.0]
print(f"random restrictions, {N} draws, seed 2026: exact, simulated")
for name, e, c in zip(["4-person AND term undecided", "parity of 8 undecided", "free staff per draw"], exact, cnt):
    print(f"  {name:<28} {e:.4f} {c / N:.4f}")
for i in range(2):                   # simulation within 4 standard errors of the exact chance
    assert abs(cnt[i] / N - exact[i]) < 4 * (exact[i] * (1 - exact[i]) / N) ** 0.5
s = 0
while (16 * (8 + s + 1) ** 2) ** (s + 1) < 2 ** 256:
    s += 1
bits, lo = (16 * (8 + s) ** 2) ** s, log_road(64, 1 << 62)
print(f"counting: 2^256 functions of 8 inputs; circuits of at most {s} two-input gates number below 2^{bits.bit_length()}")
print(f"  so at most 1 function in 2^{256 - bits.bit_length()} has a circuit of {s} gates; at {s + 1} the bound passes 2^256")
print(f"  64 inputs: some function needs more than about {str(lo)[0]}.{str(lo)[1]}e{len(str(lo)) - 1} gates")
print("  best proven for one named function: about 3.1 gates per input, once n is large")
worst = f8 = 0
for p in permutations(range(8)):     # binary insertion sort, counting comparisons
    done, c = [], 0
    for v in p:
        a, b = 0, len(done)
        while a < b:
            m = (a + b) // 2; c += 1
            a, b = (m + 1, b) if done[m] < v else (a, m)
        done.insert(a, v)
    worst, f8 = max(worst, c), f8 + 1
need = next(d for d in range(40) if 2 ** d >= f8)
print(f"sorting 8 staff: 8! = {f8} orders; 2^{need - 1} = {2 ** (need - 1)} leaves too few, so >= {need} comparisons; binary insertion worst {worst}")
print("what breaks:")
print("  a parity gate allowed: 1 gate, depth 1")
w7 = [x for x in range(256) if x & 127 == 127]
print(f"  term on staff 1-7 only: fires on {len(w7)} rotas, {sum(1 for x in w7 if parity(x) == 0)} of them even")
print(f"  no depth limit: 8 staff {tests[2][2]} gates at depth {tests[2][1]}; 64 staff {tests[5][2]} gates at depth {tests[5][1]}")
anyone = implicant_widths(8, lambda x: x > 0)
print(f"  'anyone on?' instead: {anyone.count(1)} one-person terms, so a single {anyone.count(1)}-input OR gate")
terms = [" ".join(("" if (-r - 1) % 2 else "~") + f"x{(-r - 1) // 2 + 1}" for r in ins) for _, ins in build(3, [3])[:-1]]
print("figure, inputs x=40 y=60,140,220; AND x=220 y=40,110,180,250; OR x=400 y=145; terms " + " | ".join(terms))
assert [len(r) for r in rows] == [2 ** (n - 1) for n in range(2, 9)]       # exhaustive = 2^(n-1)
assert all(min(r) == n for r, n in zip(rows, range(2, 9)))                  # every term names everyone
assert all(t[2] == t[3] for t in tests) and all(t[2] <= t[4] for t in tests)   # built = formula <= bound
assert all(t[5] for t in tests) and all(t[1] == t[6] for t in tests)        # right answers, right depth
assert bad == 0 and s == log_road(8, 256)                                   # restrictions; two counting roads
assert need <= worst == sum((i - 1).bit_length() for i in range(1, 9)) and anyone.count(1) == 8   # sorting; OR
print("ALL CHECKS PASS")
