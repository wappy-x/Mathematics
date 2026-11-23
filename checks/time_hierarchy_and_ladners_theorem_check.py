# Hierarchy and Ladner: the diagonal language D, run on every two-state machine.
# Standard library only. A machine is a 16-bit code: four rules, one per
# (state, symbol), each 4 bits = write, move (1 = right), next (0 A, 1 B, 2 accept, 3 reject).
# The tape is binary and blank cells read 0. The tape machine itself is explained
# on the Turing machines card; this file copies only the stepping rule.

def c(x):                                    # integers with commas, as on the card
    return f"{x:,}"

def run_direct(i, w, budget):
    """Road 1: rules decoded from the integer i; returns (1 accept, 0 reject, 2 still running), steps."""
    rules = [(i >> (12 - 4 * e)) & 15 for e in range(4)]
    tape = {k: int(ch) for k, ch in enumerate(w)}
    head, state = 0, 0
    for step in range(1, budget + 1):
        r = rules[2 * state + tape.get(head, 0)]
        tape[head] = r >> 3
        head += 1 if (r >> 2) & 1 else -1
        if r & 3 >= 2:
            return (1 if r & 3 == 2 else 0), step
        state = r & 3
    return 2, budget

def run_universal(w, budget):
    """Road 2: the machine D runs. It reads the rules from the first 16 symbols of
    its own input, every step, and keeps a clock. Returns (outcome, simulated steps)."""
    n = len(w)
    tape = [0] * (n + 2 * budget + 2)
    for k in range(n):
        tape[budget + 1 + k] = 1 if w[k] == "1" else 0
    head, state, steps = budget + 1, 0, 0
    while steps < budget:
        steps += 1
        at = 4 * (2 * state + tape[head])
        tape[head] = 1 if w[at] == "1" else 0
        head += 1 if w[at + 1] == "1" else -1
        nxt = 2 * (w[at + 2] == "1") + (w[at + 3] == "1")
        if nxt >= 2:
            return (1 if nxt == 2 else 0), steps
        state = nxt
    return 2, steps

def D(w, clock):
    """Accept w exactly when the machine coded by w's first 16 symbols does NOT accept w within clock(n) steps."""
    if len(w) < 16:
        return 0, 0
    out, steps = run_universal(w, clock(len(w)))
    return (0 if out == 1 else 1), steps

tt = lambda n: n * n * (n.bit_length() - 1)   # D's clock: n^2 times log2 n, rounded down
print("family: every two-state machine, 16-bit codes, blank reads 0; D's clock n^2 log2 n")
tally, latest, late_accepts = [0, 0, 0], (0, 0), []
d_yes = agree = 0
for i in range(65536):
    w = format(i, "016b")
    out, steps = run_direct(i, w, tt(16))
    tally[out] += 1
    if out != 2 and steps > latest[0]:
        latest = (steps, i)
    if out == 1 and steps > 16:
        late_accepts.append((i, steps))
    d, _ = D(w, tt)
    d_yes += d
    agree += (d == 1) == (out == 1)
print(f"road 1, direct: on its own code within 1,024 steps: accept {c(tally[1])}, reject {c(tally[0])}, still running {c(tally[2])}")
print(f"road 1, latest halt on its own code: step {latest[0]}, machine {c(latest[1])}")
print(f"road 2, universal: D accepts {c(d_yes)} codes; reject + still running = {c(tally[0] + tally[2])}")
print(f"road 2, D agrees with the coded machine on {agree} of {c(65536)} codes")
assert d_yes == tally[0] + tally[2]         # two simulators, written apart, must match
assert agree == 0                            # the diagonal: every machine loses on its own code
assert latest[0] < tt(16)                      # every halting run fits inside the clock

names = [("first bit 1", 0x7E77), ("second bit 1", 0x5D7E), ("always yes", 0x6E66),
         ("walks left", 0x0000), ("first bit 0", 0x6F77)]
print("table: row machine run on column code, 1 = accepts within the clock, 0 = not")
codes = [format(k, "016b") for _, k in names]
diag = []
for r, (name, k) in enumerate(names):
    row = [1 if run_direct(k, w, tt(16))[0] == 1 else 0 for w in codes]
    diag.append(row[r])
    print(f"  {name:<13} {format(k, '04X')}  " + " ".join(str(x) for x in row))
drow = [D(w, tt)[0] for w in codes]
print("  D            flips diagonal " + " ".join(str(x) for x in diag) + " -> " + " ".join(str(x) for x in drow))
assert drow == [1 - x for x in diag]

print("cost model of D on a never-halting code: n, clock n^2 log2 n, counter bits k, simulated steps, cost clock x 2(16 + k), n^3")
for n in (16, 64, 256, 1024):
    _, steps = D("0" * n, tt)
    k = tt(n).bit_length()
    cost = steps * 2 * (16 + k)
    assert steps == n * n * (n.bit_length() - 1)                   # the never-halting code uses its whole clock
    print(f"  n {n:>5}  clock {c(tt(n)):>10}  k {k:>2}  steps {c(steps):>10}  cost {c(cost):>11}  n^3 {c(n ** 3):>13}")
n0 = next(n for n in range(16, 10 ** 4) if all(2 * (16 + tt(m).bit_length()) * (m.bit_length() - 1) <= m for m in range(n, 10 ** 4)))
print(f"cost <= n^3 for every n from {n0} on, though D's clock outgrows c n^2 for every constant c")
assert n0 == 702
for kk in (3, 10):
    x = next(n for n in range(2, 120) if all(2 ** m > m ** kk for m in range(n, 120)))
    print(f"P inside TIME(2^n): 2^n passes n^{kk} for good at n = {x}: 2^{x} = {c(2 ** x)} > {x}^{kk} = {c(x ** kk)}")

print(f"wrong: clock of n steps, not n^2 log2 n: {len(late_accepts)} machines accept their own code after step 16; D agrees with each")
lin_agree = sum(1 for i, _ in late_accepts if D(format(i, '016b'), lambda n: n)[0] == 1)
assert lin_agree == len(late_accepts) == 6
last = max(late_accepts, key=lambda t: t[1])
print(f"  latest: machine {c(last[0])}, accepts at step {last[1]}")
out, steps = run_direct(0, "0" * 16, 10000)
assert out == 2
print(f"wrong: no clock: machine 0 on its own code is still running after {c(steps)} steps")
cost64 = tt(64) * 2 * (16 + tt(64).bit_length())
print(f"wrong: hoping D itself fits in n^2 steps: at n = 64, D costs {c(cost64)} steps, against n^2 = {c(64 * 64)}")
assert cost64 > 64 * 64
m = 48
print(f"Ladner padding, a 4 by 4 sudoku of m = {m} bits, padding tail of m^H bits: "
      + ", ".join(f"H {h}: {c(m ** h)}" for h in (1, 2, 3, 4)))
n32 = next(n for n in range(16, 10 ** 4) if all(2 * (32 + tt(m).bit_length()) * (m.bit_length() - 1) <= m for m in range(n, 10 ** 4)))
x5 = next(n for n in range(2, 120) if all(2 ** m > m ** 5 for m in range(n, 120)))
print(f"try: clock 100 at n = 16: {sum(1 for _, s in late_accepts if s > 100)} machine accepts after it; 32-cell rule block: cost <= n^3 from n = {n32}")
print(f"try: 2^n passes n^5 for good at n = {x5}: 2^{x5} = {c(2 ** x5)} > {x5}^5 = {c(x5 ** 5)}; H 5: {c(m ** 5)}")
print(f"budgets at n = 1,000: n^2 = {c(1000 ** 2)}, n^3 = {c(1000 ** 3)}")
print("ALL CHECKS PASS")
