# P/poly -- the check behind the card.  Standard library only.  Four constructions: a circuit
# family (one adder per input length), a unary set given by one advice bit per length, Adleman's
# step on a real coin-flipping test (one coin string right on every input), and the
# self-reduction inside Karp-Lipton.  Nothing here decides halting; capped runs say so.

def adder(k):                         # ripple-carry adder, as built on the Boolean circuits card
    gates = []                        # (op, x, y); wires 0..k-1 are a, wires k..2k-1 are b
    def g(op, x, y=0): gates.append((op, x, y)); return 2 * k + len(gates) - 1
    def xor(x, y): both = g("AND", x, y); return g("AND", g("OR", x, y), g("NOT", both)), both
    s, c = xor(0, k); out = [s]
    for i in range(1, k):
        t, h = xor(i, k + i); s, u = xor(t, c); out.append(s); c = g("OR", h, u)
    return gates, out + [c]
def run(gates, outs, bits):
    v = list(bits)
    for op, x, y in gates: v.append(1 - v[x] if op == "NOT" else v[x] & v[y] if op == "AND" else v[x] | v[y])
    return sum(v[o] << i for i, o in enumerate(outs))
def bits(a, b, k): return [a >> i & 1 for i in range(k)] + [b >> i & 1 for i in range(k)]
for k in (1, 2, 3, 4):
    gates, outs = adder(k)
    right = sum(run(gates, outs, bits(a, b, k)) == a + b for a in range(2 ** k) for b in range(2 ** k))
    print(f"adder family: n={2 * k} input bits, {len(gates)} gates, right on {right} of {4 ** k} inputs")
    assert right == 4 ** k and len(gates) == (4 if k == 1 else 9 * k - 5)

def program(n):                       # program number n: its base-4 digits, lowest first
    p = []
    while n: p.append(n % 4); n //= 4
    return p
NAME = ["INC", "DEC", "JNZ", "JMP"]   # c+1; c-1 (not below 0); if c > 0 go back one; go to start
CAP = 1000                            # step cap for the runs below
def status(p, cap):                   # "1" halted, "0" a configuration repeated (proof of a loop),
    pc, c, seen = 0, 0, set()         # "?" still running after cap steps: no claim either way
    for step in range(cap):
        if pc == len(p): return "1", step, c
        if (pc, c) in seen: return "0", step, c
        seen.add((pc, c)); op = p[pc]
        if op == 0: c += 1; pc += 1
        elif op == 1: c = max(c - 1, 0); pc += 1
        elif op == 2: pc = max(pc - 1, 0) if c > 0 else pc + 1
        else: pc = 0
    return "?", cap, c
advice = "".join(status(program(n), CAP)[0] for n in range(64))
print(f"advice bits a_0..a_63: {advice}")
print(f"  {advice.count('1')} halt, {advice.count('0')} loop (a configuration repeats), "
      f"{advice.count('?')} still running after {CAP} steps")
for n in (3, 12, 36):
    s, t, c = status(program(n), CAP)
    print(f"  program {n} = {' '.join(NAME[d] for d in program(n))}: "
          + {"1": f"halts after {t} steps", "0": f"repeats a configuration at step {t}",
             "?": f"still running after {t} steps, counter {c}"}[s])
checked = 0
for n in range(1, 13):                # both circuits for length n: AND of all inputs, or constant 0
    for bit in (0, 1):
        acc = []
        for x in range(2 ** n):       # input bit i is x >> i & 1; run the circuit gate by gate
            v = x & 1
            for i in range(1, n): v &= x >> i & 1
            if (v if bit else (x & 1) & (1 - (x & 1))): acc.append(x)
        assert acc == ([2 ** n - 1] if bit else []); checked += 2 ** n
print(f"unary circuits, n=1..12: AND of the n inputs accepts only 1^n, the 0-circuit accepts nothing; "
      f"{checked} runs checked; gates n-1 = 11 at n=12")
assert (advice.count("1"), advice.count("0"), advice.count("?")) == (21, 31, 12) and advice[:4] == "1110"
assert [status(program(n), 1000) for n in (3, 12, 36)] == [("0", 1, 0), ("?", 1000, 500), ("1", 3, 0)]   # traced by hand

def mv(m, r):                         # 2x2 table mod 2 (bits e00 e01 e10 e11) times a 0/1 column r
    return (bin(m & 3 & r).count("1") & 1) | (bin(m >> 2 & r).count("1") & 1) << 1
def mm(a, b):                         # product of two tables mod 2, column by column
    cols = [mv(a, (b >> j & 1) | (b >> (2 + j) & 1) << 1) for j in (0, 1)]
    return (cols[0] & 1) | (cols[1] & 1) << 1 | (cols[0] >> 1) << 2 | (cols[1] >> 1) << 3
N = 12                                # input: A, B, C, 4 bits each; the question is "is AB = C?"
truth = [mm(x & 15, x >> 4 & 15) == x >> 8 for x in range(2 ** N)]
passes = [sum(1 << r for r in range(4) if mv(x & 15, mv(x >> 4 & 15, r)) == mv(x >> 8, r)) for x in range(2 ** N)]
no = [x for x in range(2 ** N) if not truth[x]]
worst = max(bin(passes[x]).count("1") for x in no) / 4
half = sum(bin(passes[x]).count("1") == 2 for x in no)
print(f"Freivalds test mod 2: {2 ** N} inputs, {2 ** N - len(no)} with AB = C, {len(no)} without; one run wrongly passes "
      f"a wrong C with chance at most {worst:.2f}; {half} wrong inputs reach it, {len(no) - half} sit at 0.25")
def good(seed, k):                    # right on every input? a wrong C escapes only if every r_i passes it
    used = sum(1 << v for v in {seed >> 2 * i & 3 for i in range(k)})
    return all(used & ~passes[x] for x in no)
for k in (1, 2, 3):
    g = sum(good(s, k) for s in range(4 ** k))
    print(f"k={k} runs: {g} of {4 ** k} coin strings right on all {2 ** N} inputs; formula (2^k-1)(2^k-2) = {(2 ** k - 1) * (2 ** k - 2)}")
    assert g == (2 ** k - 1) * (2 ** k - 2)
for k in (2, 12, 13):
    bad, err = 3 * 2 ** k - 2, sum(bin(passes[x]).count("1") ** k for x in no) / 4 ** k
    print(f"k={k}: union bound {2 ** N} x 2^-{k} = {2 ** N / 2 ** k:.1f}; sum of per-input errors "
          f"{err:.6f}; exact bad share {bad}/{4 ** k} = {bad / 4 ** k:.6f}")
    assert bad / 4 ** k <= err <= 2 ** N * worst ** k   # exact bad share <= summed errors <= union bound
assert worst == 0.5 and half == 2304

state = 2026                          # SplitMix64, seed 2026: 26-bit coin strings for k = 13
def splitmix():
    global state
    M = (1 << 64) - 1; state = (state + 0x9E3779B97F4A7C15) & M; z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M; z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M
    return z ^ (z >> 31)
draws = [splitmix() & (2 ** 26 - 1) for _ in range(2000)]
first = draws[0]
right = sum((all(passes[x] >> (first >> 2 * i & 3) & 1 for i in range(13))) == truth[x] for x in range(2 ** N))
cols = " ".join(f"{first >> 2 * i & 1}{first >> 2 * i + 1 & 1}" for i in range(13))
print(f"advice for n=12: first drawn coin string, columns r_1..r_13 = {cols}")
print(f"  {2 * 13} advice bits, right on {right} of {2 ** N} inputs; one bit per input would need {2 ** N}")
print(f"  {sum(not good(s, 13) for s in draws)} of {len(draws)} drawn coin strings fail some input")
lame = 2 ** 26 - 1                    # every r_i = 11: a bad coin string, built on purpose
x = next(x for x in no if not good(lame, 13) and passes[x] >> 3 & 1)
def tab(m): return f"{m & 1}{m >> 1 & 1}/{m >> 2 & 1}{m >> 3 & 1}"   # row 1 / row 2
print(f"mistake, every column r = 11: passes A={tab(x & 15)} B={tab(x >> 4 & 15)} C={tab(x >> 8)}, "
      f"though AB = {tab(mm(x & 15, x >> 4 & 15))}")
def vec(v): return f"{v & 1}{v >> 1 & 1}"                          # top entry, bottom entry
print("hand trace: " + "; ".join(f"r={vec(r)}: Br={vec(mv(x >> 4 & 15, r))} A(Br)={vec(mv(x & 15, mv(x >> 4 & 15, r)))} "
      f"Cr={vec(mv(x >> 8, r))} " + ("passes" if passes[x] >> r & 1 else "caught") for r in (1, 3)))
assert right == 2 ** N and not good(lame, 13) and good(first, 13) and passes[x] == 0b1001

g2, o2 = adder(2)                     # Karp-Lipton's inner step: a yes/no box for SAT gives the answer
def honest(fixed, target):            # is there a completion of the fixed bits with a + b = target?
    free = 4 - len(fixed)
    return any(run(g2, o2, fixed + [r >> i & 1 for i in range(free)]) == target for r in range(2 ** free))
def liar(fixed, target): return True
def self_reduce(box, target):
    calls = 1
    if not box([], target): return None, calls
    fixed = []
    for _ in range(4): calls += 1; fixed.append(1 if box(fixed + [1], target) else 0)
    return fixed, calls
for name, box, target in (("honest box", honest, 4), ("honest box", honest, 7), ("liar box", liar, 7)):
    w, calls = self_reduce(box, target)
    got = None if w is None else (w[0] + 2 * w[1], w[2] + 2 * w[3], run(g2, o2, w))
    print(f"self-reduction, {name}, a + b = {target}: questions asked {calls}; "
          + ("says no" if w is None else f"a={got[0]} b={got[1]}, adder gives {got[2]}: "
             + ("checks" if got[2] == target else "caught, the answer fails the check")))
sols = {t: [(a, b) for a in range(4) for b in range(4) if a + b == t] for t in (4, 7)}
print(f"brute force: {len(sols[4])} of 16 pairs give 4, none gives 7")
w = self_reduce(honest, 4)[0]         # the answers must agree with the brute force
assert (w[0] + 2 * w[1], w[2] + 2 * w[3]) in sols[4] and len(sols[4]) == 3 and (self_reduce(honest, 7)[0] is None) == (not sols[7])
print("ALL CHECKS PASS")
