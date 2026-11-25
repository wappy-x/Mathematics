# Quantum error correction -- the check behind the card.  Standard library only.
# State vectors as on the Qubits card: n qubits are 2^n amplitudes, qubit 1 is the
# leftmost bit, and every amplitude here is real.  An error or a check is a pair of
# bit masks (x, z): Z on the z-qubits first, then X on the x-qubits.
import math
def mask(n, qs): return sum(1 << (n - q) for q in qs)       # qubits 1..n -> bit mask
def pop(v): return bin(v).count("1")
def pauli(s, x, z): return [(-1) ** pop((i ^ x) & z) * s[i ^ x] for i in range(len(s))]   # X^x Z^z
def dot(s, t): return sum(a * b for a, b in zip(s, t))
def ket(n, bits): return [float(i == int(bits, 2)) for i in range(1 << n)]
def mix(pairs): return [sum(c * v[i] for c, v in pairs) for i in range(len(pairs[0][1]))]
def kron(a, b): return [x * y for x in a for y in b]
def fid(s, t): return dot(s, t) ** 2 / (dot(s, s) * dot(t, t))
def syn(s, checks): return tuple(round(dot(s, pauli(s, x, z)) / dot(s, s)) for x, z in checks)
def anti(e, c): return (pop(e[0] & c[1]) + pop(e[1] & c[0])) % 2   # 1: error and check anticommute
def singles(n): return [(f"{k}{q}", (mask(n, [q]) * (k != "Z"), mask(n, [q]) * (k != "X")))
                        for q in range(1, n + 1) for k in ("X", "Z", "XZ")]
def table(n, checks):        # syndrome -> repair, from anticommuting alone (no state needed)
    t = {tuple(1 for _ in checks): ("none", (0, 0))}
    for name, e in singles(n): t.setdefault(tuple(1 - 2 * anti(e, c) for c in checks), (name, e))
    return t
def repair(s, checks, t): name, e = t[syn(s, checks)]; return name, pauli(s, *e)
def signs(sy): return "".join("+" if v > 0 else "-" for v in sy)
def pm(sy): return "(" + ", ".join(f"{v:+d}" for v in sy) + ")"
def sci(x): m, e = f"{x:.3e}".split("e"); return f"{m}e{int(e)}"
def all_singles(n, code, checks, t):
    return sum(fid(repair(pauli(code, *e), checks, t)[1], code) > 1 - 1e-12 for _, e in singles(n))
c0, c1 = 0.8, 0.6                                           # the coin qubit from the Qubits card
L3 = mix([(c0, ket(3, "000")), (c1, ket(3, "111"))])
bc = [(0, mask(3, [1, 2])), (0, mask(3, [2, 3]))]           # checks Z1 Z2 and Z2 Z3
bt = table(3, bc)
print("two copies of the coin: " + " ".join(f"{a:.4f}" for a in kron([c0, c1], [c0, c1])) + "; coin then CNOT: "
      + " ".join(f"{a:.4f}" for a in mix([(c0, ket(2, "00")), (c1, ket(2, "11"))])))
print(f"bit-flip code: 0.8|000> + 0.6|111>; checks Z1Z2, Z2Z3 read {pm(syn(L3, bc))}")
for q in (1, 2, 3):
    bad = pauli(L3, mask(3, [q]), 0)
    name, back = repair(bad, bc, bt)
    print(f"X on qubit {q}: checks read {pm(syn(bad, bc))}, repair {name}, fidelity {fid(back, L3):.4f}")
s5 = kron(pauli(L3, mask(3, [1]), 0), ket(2, "00"))         # road two: two helper qubits, four CNOTs
for c, t in ((1, 4), (2, 4), (2, 5), (3, 5)):
    s5 = [s5[i ^ (1 << (5 - t))] if i & (1 << (5 - c)) else a for i, a in enumerate(s5)]
p10 = sum(a * a for i, a in enumerate(s5) if i & 3 == 2)
print(f"helper qubits after four CNOTs read 1 0 with chance {p10:.4f}; data amplitudes "
      f"{s5[int('10010', 2)]:.4f} on |100>, {s5[int('01110', 2)]:.4f} on |011>")
p = 0.01
fails, pl_enum = [], 0.0
for pat in range(8):                                        # road two: all 8 flip patterns, run quantum
    after = repair(pauli(L3, pat, 0), bc, bt)[1]
    if fid(after, L3) < 0.999: fails.append(f"{pat:03b}"); pl_enum += p ** pop(pat) * (1 - p) ** (3 - pop(pat))
f = lambda p: 3 * p * p - 2 * p ** 3
print(f"patterns that fail: {', '.join(fails)}")
print(f"p = 0.01: logical error 3p^2 - 2p^3 = {f(p):.8f}; over all 8 patterns = {pl_enum:.8f}")
print("chance of 0, 1, 2, 3 flips: " + ", ".join(f"{math.comb(3, k) * p ** k * (1 - p) ** (3 - k):.6f}" for k in range(4)))
M64 = (1 << 64) - 1
def splitmix64(s):                                          # SplitMix64, written out in both languages
    while True:
        s = (s + 0x9E3779B97F4A7C15) & M64
        z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        yield z ^ (z >> 31)
RUNS, gen, mc = 1000000, splitmix64(2026), 0
for _ in range(RUNS):                                       # road three: random flips, same decoder
    pat = sum(1 << b for b in range(3) if (next(gen) >> 11) / 2.0 ** 53 < p)
    fix = bt[tuple(1 - 2 * anti((pat, 0), c) for c in bc)][1][0]
    mc += (pat ^ fix) == 7
se = math.sqrt(RUNS * f(p) * (1 - f(p)))
print(f"{RUNS} random runs, seed 2026: {mc} logical errors; expected {RUNS * f(p):.1f}, standard error {se:.1f}")
print(f"try: p = 0.001 gives {f(0.001):.8f}; p = 0.1 gives {f(0.1):.8f}")
lv, hv = [p], [0.6]
for _ in range(3): lv.append(f(lv[-1])); hv.append(f(hv[-1]))
print("levels 0-3 from p = 0.01: " + ", ".join(sci(v) for v in lv))
print("  bound (3p)^(2^k)/3:     " + ", ".join(sci((3 * p) ** (2 ** k) / 3) for k in range(4)))
print("levels 0-3 from p = 0.6:  " + ", ".join(f"{v:.4f}" for v in hv))
lo, hi = 0.01, 0.99
for _ in range(60):                                         # threshold: where f(p) = p, by bisection
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if f(mid) < mid else (lo, mid)
print(f"threshold of the level map, by bisection: {lo:.6f}")
xs = [k / 10 for k in range(11)]
print("chart p:      " + " ".join(f"{x:.2f}" for x in xs))
print("chart level 1 " + " ".join(f"{f(x):.2f}" for x in xs))
print("chart level 2 " + " ".join(f"{f(f(x)):.2f}" for x in xs))
k, q = 0, p
while q > 1e-11: q, k = f(q), k + 1
print(f"need 1e-11 per step (1% over 1e9 steps) from p = 0.01: level {k}; qubits per logical qubit 3^{k} = {3 ** k}, Steane 7^{k} = {7 ** k}")
plus, minus = mix([(1, ket(3, "000")), (1, ket(3, "111"))]), mix([(1, ket(3, "000")), (-1, ket(3, "111"))])
L9 = mix([(c0, kron(kron(plus, plus), plus)), (c1, kron(kron(minus, minus), minus))])
L9 = [a / math.sqrt(dot(L9, L9)) for a in L9]
sc = [(0, mask(9, pr)) for pr in ([1, 2], [2, 3], [4, 5], [5, 6], [7, 8], [8, 9])]
sc += [(mask(9, range(1, 7)), 0), (mask(9, range(4, 10)), 0)]
st = table(9, sc)
print(f"Shor code: 9 qubits ({len(L9)} amplitudes), 8 checks, all read {signs(syn(L9, sc))} on the coin")
for name in ("X1", "Z1", "Z5", "XZ5"):
    e = dict(singles(9))[name]
    print(f"  {name:<3} -> checks {signs(syn(pauli(L9, *e), sc))}, repair {repair(pauli(L9, *e), sc, st)[0]}")
print(f"Shor code repairs {all_singles(9, L9, sc, st)} of 27 single-qubit errors")
m5 = mask(9, [5])
mess = mix([(0.9, L9), (0.3, pauli(L9, m5, 0)), (0.3, pauli(L9, 0, m5)), (0.1, pauli(L9, m5, m5))])
tot, bf = 0.0, []                                           # measuring the checks picks one branch
for sy, (name, _) in st.items():
    br = mess
    for (x, z), sg in zip(sc, sy): br = [(a + sg * b) / 2 for a, b in zip(br, pauli(br, x, z))]
    pr = dot(br, br)
    if pr > 1e-12:
        tot += pr; bf.append(fid(repair(br, sc, st)[1], L9))
        print(f"  messy error on qubit 5, branch {signs(sy)}: chance {pr:.4f}, repair {name}, fidelity {bf[-1]:.4f}")
print(f"  branch chances add to {tot:.4f}")
rows = [mask(7, [j for j in range(1, 8) if j >> r & 1]) for r in range(3)]   # Hamming check matrix
print("Steane: row overlaps " + ", ".join(str(pop(rows[a] & rows[b])) for a, b in ((0, 1), (0, 2), (1, 2)))
      + "; row weights " + ", ".join(str(pop(r)) for r in rows))
words = sorted({(rows[0] if a else 0) ^ (rows[1] if b else 0) ^ (rows[2] if c else 0) for a in (0, 1) for b in (0, 1) for c in (0, 1)})
print("Steane |0_L> words: " + " ".join(f"{w:07b}" for w in words))
z0 = [(i in words) / math.sqrt(8) for i in range(128)]
L7 = mix([(c0, z0), (c1, pauli(z0, 127, 0))])
tc = [(0, r) for r in rows] + [(r, 0) for r in rows]
tt = table(7, tc)
num = lambda sy: sum(1 << i for i, v in enumerate(sy) if v < 0)
print("Steane, X on qubit 1-7, Z-checks spell: " + " ".join(str(num(syn(pauli(L7, mask(7, [j]), 0), tc)[:3])) for j in range(1, 8)))
print("Steane, Z on qubit 1-7, X-checks spell: " + " ".join(str(num(syn(pauli(L7, 0, mask(7, [j])), tc)[3:])) for j in range(1, 8)))
print(f"Steane code ({len(L7)} amplitudes): checks on the coin {signs(syn(L7, tc))}; repairs {all_singles(7, L7, tc, tt)} of 21 single-qubit errors")
ph = pauli(L3, 0, mask(3, [1]))
two = repair(pauli(L3, mask(3, [1, 2]), 0), bc, bt)
print(f"mistake 1, read the data: fidelity on average {sum(L3[i] ** 2 * fid(ket(3, f'{i:03b}'), L3) for i in (0, 7)):.4f}")
print(f"mistake 2, X1 X2: repair {two[0]}, chances now {two[1][0] ** 2:.4f} and {two[1][7] ** 2:.4f}, fidelity {fid(two[1], L3):.4f}")
print(f"mistake 3, Z1 on the bit-flip code: checks {pm(syn(ph, bc))}, fidelity {fid(ph, L3):.4f}")
print("surface code, distance 3 5 7: qubits (2d-1)^2 = " + " ".join(str((2 * d - 1) ** 2) for d in (3, 5, 7))
      + "; error powers (d+1)/2 = " + " ".join(str((d + 1) // 2) for d in (3, 5, 7)) + "; cited threshold 0.57% per step")
assert abs(f(p) - pl_enum) < 1e-15 and fails == ["011", "101", "110", "111"]          # formula = all patterns
assert abs(mc - RUNS * f(p)) < 4 * se                                                  # simulation agrees
assert abs(p10 - 1) < 1e-12 and abs(f(p) - 0.000298) < 1e-12                           # 3(0.0001) - 2(0.000001)
assert abs(lo - 0.5) < 1e-9 and f(0.6) > 0.6 and f(0.4) < 0.4                         # threshold 1/2
assert all_singles(9, L9, sc, st) == 27 and all_singles(7, L7, tc, tt) == 21
assert abs(tot - 1) < 1e-12 and len(bf) == 4 and min(bf) > 1 - 1e-12                 # every branch repaired
assert all(pop(a & b) % 2 == 0 for a in rows for b in rows)                            # X and Z checks commute
assert [num(syn(pauli(L7, mask(7, [j]), 0), tc)[:3]) for j in range(1, 8)] == list(range(1, 8))
assert abs(fid(ph, L3) - (c0 * c0 - c1 * c1) ** 2) < 1e-12                             # (0.64 - 0.36)^2
print("ALL CHECKS PASS")
