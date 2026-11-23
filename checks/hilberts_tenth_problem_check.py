# Hilbert's tenth problem -- the check behind the card.  Standard library only.
# It never tries to decide which equations have whole-number solutions: no
# program can.  It runs the three pieces of the proof that no program can.
# Part 1: x^3 + y^3 + z^3 = k, by a mod 9 proof, by search, and by checking
#         published record solutions in two independent ways.
# Part 2: a program that reads a machine and writes arithmetic conditions that
#         a few whole numbers pass exactly when they pack a halting run.
# Part 3: Pell's equation forcing an exponential: 2^10 read off a solution.
B = 1000
cube = {c * c * c: c for c in range(-B, B + 1)}

def search(k):                      # every x <= y <= z with |x|, |y|, |z| <= B
    found = []
    for x in range(-B, B + 1):
        for y in range(x, B + 1):
            z = cube.get(k - x * x * x - y * y * y)
            if z is not None and z >= y:
                found.append((x, y, z))
    return found

print("part 1: x^3 + y^3 + z^3 = k")
res9 = sorted({a * a * a % 9 for a in range(9)})
miss = [r for r in range(9) if r not in {(p + q + w) % 9 for p in res9 for q in res9 for w in res9}]
print("cubes mod 9 are only:", *res9, "  sums of three cubes mod 9 miss:", *miss)
assert miss == [4, 5], "the mod 9 table must rule out exactly 4 and 5"
for k in (3, 4, 6, 29, 33, 42):
    f = search(k)
    tag = "ruled out by mod 9" if k % 9 in miss else "allowed by mod 9"
    best = " ".join(map(str, min(f, key=lambda t: max(map(abs, t))))) if f else f"none up to {B}"
    print(f"k = {k:>2}  {tag:<18}  triples found: {len(f)}  smallest: {best}")
    assert not (k % 9 in miss and f), "search contradicts the mod 9 proof"
    if k == 33: none33 = not f
RECORD = {33: (8866128975287528, -8778405442862239, -2736111468807040),
          42: (-80538738812075974, 80435758145817515, 12602123297335631)}
MODS = (2 ** 62, 2 ** 62 - 1, 2 ** 62 - 3)  # pairwise coprime; product above 9 x 10^55
for k, (x, y, z) in RECORD.items():
    r = [((x % m) ** 3 % m + (y % m) ** 3 % m + (z % m) ** 3 % m - k) % m for m in MODS]
    print(f"{k} = ({x})^3 + ({y})^3 + ({z})^3   remainders of the difference:", *r)
    assert r == [0, 0, 0] and x ** 3 + y ** 3 + z ** 3 == k, "record solution fails"

print("part 2: a machine run packed into whole numbers")
DOUBLE = [("DEC", 0, 1, 3), ("INC", 1, 2), ("INC", 1, 0), ("HALT",)]
FOREVER = [("INC", 0, 0), ("HALT",)]

def run(prog, regs, cap):           # (line, registers) at each step, and halted?
    line, regs, trace = 0, list(regs), []
    for _ in range(cap + 1):
        trace.append((line, list(regs)))
        ins = prog[line]
        if ins[0] == "HALT": return trace, True
        if ins[0] == "INC": regs[ins[1]] += 1; line = ins[2]
        elif regs[ins[1]] > 0: regs[ins[1]] -= 1; line = ins[2]
        else: line = ins[3]
    return trace, False

def pack(prog, trace, Q):           # one number per line, one per register
    L = [sum(Q ** t for t, (ln, _) in enumerate(trace) if ln == i) for i in range(len(prog))]
    R = [sum(rg[r] * Q ** t for t, (_, rg) in enumerate(trace)) for r in range(2)]
    return len(trace), L, R

def conditions(prog, start, s, Q, L, R, final):   # reads the program, writes the checks
    I, h = (Q ** s - 1) // (Q - 1), Q // 2
    out = [("one line per step", sum(L) == I), ("starts at line 0", L[0] % Q == 1),
           ("halts at the last step only", L[-1] == Q ** (s - 1))]
    out += [(f"L{i} digits are 0 or 1", L[i] & I == L[i]) for i in range(len(prog))]
    inc, dec = [0, 0], [0, 0]
    for i, ins in enumerate(prog):
        if ins[0] == "INC":
            out.append((f"line {i} leads to {ins[2]}", Q * L[i] & L[ins[2]] == Q * L[i]))
            inc[ins[1]] += L[i]
        elif ins[0] == "DEC":
            nz = L[i] & (L[ins[2]] // Q)            # steps that took the nonzero branch
            out.append((f"line {i} leads to {ins[2]} or {ins[3]}", Q * L[i] & (L[ins[2]] + L[ins[3]]) == Q * L[i]))
            out.append((f"line {i} tests r{ins[1]} for zero", (R[ins[1]] + (h - 1) * L[i]) & h * L[i] == h * nz))
            dec[ins[1]] += nz
    for r in range(2):
        out.append((f"r{r} digits below Q/2", R[r] & (h - 1) * I == R[r]))
        out.append((f"r{r} steps forward", R[r] + Q ** s * final[r] == start[r] + Q * (R[r] + inc[r] - dec[r])))
    return out

START = (3, 0)                      # r0 = 3 in, r1 = 0
tr, halted = run(DOUBLE, START, 100)
s, L, R = pack(DOUBLE, tr, 16)
fin = tr[-1][1]
print(f"double, r0 = {START[0]}: halts at step {s - 1} with r0 = {fin[0]}, r1 = {fin[1]}")
print("lines by step:", *[ln for ln, _ in tr])
print("r0 by step:   ", *[rg[0] for _, rg in tr])
print("r1 by step:   ", *[rg[1] for _, rg in tr])
print(f"base Q = 16, s = {s} digits: L0 = {L[0]}, L3 = {L[3]}, R0 = {R[0]}, R1 = {R[1]}")
good = conditions(DOUBLE, START, s, 16, L, R, fin)
print(f"conditions written from the program: {len(good)}, holding: {sum(ok for _, ok in good)}")
for j in range(0, len(good), 4): print("  " + "; ".join(n for n, _ in good[j:j + 4]))
assert all(ok for _, ok in good), "the true run must pass every condition"
bad = [n for n, ok in conditions(DOUBLE, START, s, 16, L, R, [0, 7]) if not ok]
print("claim r1 ends at 7, fails:", ", ".join(bad))
s8, L8, R8 = pack(DOUBLE, tr, 8)
bad8 = [n for n, ok in conditions(DOUBLE, START, s8, 8, L8, R8, fin) if not ok]
print("base Q = 8, fails:", ", ".join(bad8))
assert bad == ["r1 steps forward"] and bad8 == ["r1 digits below Q/2"], "tampering must be caught"
tf, hf = run(FOREVER, (0, 0), 20)
fails = 0
for n in range(1, 21):              # forever's first n steps, packed and tested
    sn, Ln, Rn = pack(FOREVER, tf[:n], 64)
    fails += not all(ok for _, ok in conditions(FOREVER, (0, 0), sn, 64, Ln, Rn, tf[n - 1][1]))
print(f"forever: {'halts' if hf else 'still running after 20 steps'}; packed runs of 1 to 20 steps that fail: {fails}")

print("part 3: Pell's equation x^2 - (a^2 - 1) y^2 = 1 forces powers")
def pell(a, n):                     # x_n + y_n root(a^2 - 1) = (a + root(a^2 - 1))^n
    x0, y0, x1, y1 = 1, 0, a, 1
    for _ in range(n): x0, y0, x1, y1 = x1, y1, 2 * a * x1 - x0, 2 * a * y1 - y0
    return x0, y0
ys, x = [], 1
for y in range(10001):              # brute force on a = 3: x^2 - 8y^2 = 1
    while x * x < 1 + 8 * y * y: x += 1
    if x * x == 1 + 8 * y * y: ys.append((x, y))
print("a = 3, search y <= 10000:", *ys)
assert ys == [pell(3, n) for n in range(len(ys))], "recurrence and search disagree"
for a, label in ((300, "a = 300"), (100, "wrong: a = 100")):
    x10, y10 = pell(a, 10); m = 4 * a - 5
    print(f"{label}: d = {a * a - 1}, y_10 = {y10}, y_10 mod {a - 1} = {y10 % (a - 1)}, (x_10 - {a - 2} y_10) mod {m} = {(x10 - (a - 2) * y10) % m}")
p = 1
for _ in range(10): p *= 2
print("2^10 by repeated doubling:", p)
assert (pell(300, 10)[0] - 298 * pell(300, 10)[1]) % 1195 == p, "Pell remainder must equal 2^10"
assert all((pell(300, n)[0] - (300 - k) * pell(300, n)[1] - k ** n) % (600 * k - k * k - 1) == 0
           for n in range(12) for k in range(1, 6)), "the Pell power congruence"
assert all(pell(300, n)[1] % 299 == n for n in range(12)), "y_n remembers n"
assert halted and not hf and none33 and fails == 20, "33 below 1000 and the capped forever machine"
print("ALL CHECKS PASS")
