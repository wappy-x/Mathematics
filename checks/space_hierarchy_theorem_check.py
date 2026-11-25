# Space hierarchy: the diagonal language D with a memory budget, run on every two-state machine.
# Standard library only. A machine is a 16-bit code: four rules, one per (state, symbol),
# each 4 bits = write, move (1 = right), next (0 A, 1 B, 2 accept, 3 reject). Blank cells read 0.
# The stepping rule is copied from the Hierarchy and Ladner card. New here: a run is confined
# to the first `cells` tape cells, and a run that repeats a configuration is proved to loop.
from math import log2
ACC, REJ, OUT, LOOP, RUN = 1, 0, 2, 3, 4      # accept, reject, left the cells, loops, still running

def c(x):                                      # integers with commas, as on the card
    return f"{x:,}"

def run_direct(i, w, cells, cap=None, detect=True):
    """Road 1: rules decoded from the integer i, tape held as one integer, every configuration
    (state, head, tape) remembered. Returns (outcome, steps, cells used, step first seen)."""
    rules = [(i >> (12 - 4 * e)) & 15 for e in range(4)]
    tape = sum(1 << k for k, ch in enumerate(w) if ch == "1")
    head = state = step = 0
    far, seen = len(w) - 1, {}
    while cap is None or step < cap:
        if detect:
            key = (state, head, tape)
            if key in seen:
                return LOOP, step, far + 1, seen[key]
            seen[key] = step
        far = max(far, head)
        r = rules[2 * state + ((tape >> head) & 1)]
        tape = (tape & ~(1 << head)) | ((r >> 3) << head)
        head += 1 if (r >> 2) & 1 else -1
        step += 1
        if r & 3 >= 2:
            return (ACC if r & 3 == 2 else REJ), step, far + 1, 0
        if head < 0 or head >= cells:
            return OUT, step, far + 1, 0
        state = r & 3
    return RUN, step, far + 1, 0

def floyd(w, cells):
    """Road 2: the machine D runs. It reads the rules from the first 16 symbols of its input
    at every step and keeps only two configurations, a slow copy and a fast copy (Floyd's
    tortoise and hare), so its memory stays at two windows of `cells` cells."""
    def step(cfg):
        state, head, tape = cfg
        at = 4 * (2 * state + tape[head])
        tape[head] = 1 if w[at] == "1" else 0
        head += 1 if w[at + 1] == "1" else -1
        nxt = 2 * (w[at + 2] == "1") + (w[at + 3] == "1")
        if nxt >= 2:
            return ACC if nxt == 2 else REJ
        if head < 0 or head >= cells:
            return OUT
        cfg[0], cfg[1] = nxt, head
        return None
    start = [1 if ch == "1" else 0 for ch in w] + [0] * (cells - len(w))
    slow, fast = [0, 0, start[:]], [0, 0, start[:]]
    while True:
        for _ in range(2):
            out = step(fast)
            if out is not None:
                return out
        step(slow)
        if slow == fast:
            return LOOP

def D(w, cells):
    """Accept w exactly when the coded machine does NOT accept w inside the first `cells` cells."""
    return 0 if floyd(w, cells) == ACC else 1

W = 20                                         # D's window in this run: 20 cells, so every run ends
print(f"family: every two-state machine, 16-bit codes, run on its own code; D's window {W} cells")
tally, used_max, rep_max, d_yes, agree, late_acc, same = [0] * 4, 0, (0, 0, 0), 0, 0, [], 0
for i in range(65536):
    w = format(i, "016b")
    out, steps, used, first = run_direct(i, w, W)
    tally[out] += 1
    if out != OUT:
        used_max = max(used_max, used)
    if out == LOOP:
        rep_max = max(rep_max, (steps, i, first))
    if out == ACC and steps > 16:
        late_acc.append(i)
    d = D(w, W)
    d_yes += d
    agree += (d == 1) == (out == ACC)
    same += floyd(w, W) == out                 # road 2's full outcome, not just yes or no
print(f"road 1, every configuration remembered: accept {c(tally[ACC])}, reject {c(tally[REJ])}, "
      f"leave the {W} cells {c(tally[OUT])}, loop inside {c(tally[LOOP])}")
print(f"road 1, every run that stays inside uses at most {used_max} cells; latest first repeat: "
      f"step {rep_max[0]}, machine {c(rep_max[1])}, back to its step-{rep_max[2]} configuration")
print(f"road 2, two configurations only: D accepts {c(d_yes)}; reject + leave + loop = "
      f"{c(tally[REJ] + tally[OUT] + tally[LOOP])}")
print(f"road 2, D agrees with the coded machine on {agree} of {c(65536)} codes; "
      f"its outcome (accept, reject, leave or loop) equals road 1's on {c(same)}")
assert d_yes == tally[REJ] + tally[OUT] + tally[LOOP]      # two simulators, written apart, must match
assert agree == 0                                          # the diagonal: every machine loses on its own code
assert same == 65536                                       # all four outcomes match, code by code
for name, v in [("accept", tally[ACC]), ("reject", tally[REJ]), ("leave", tally[OUT]), ("loop", tally[LOOP])]:
    print(f"  {name:<7} {'#' * round(40 * v / 65536):<40} {c(v)}")

print("the counter machine 508D (20,621): steps until it steps out of the first s cells")
prev = None
for s in range(16, 22):
    out, steps, used, _ = run_direct(0x508D, format(0x508D, "016b"), s, detect=False)
    assert out == OUT and (prev is None or steps == prev + 2 ** s - 1)   # pattern: each cell adds 2^s - 1 steps
    print(f"  s {s}: {c(steps)} steps, {c(2 * s * 2 ** s)} configurations")
    prev = steps
big = 40422 + sum(2 ** s - 1 for s in range(17, 257))
print(f"  the pattern carried to 256 cells: more than 2^{big.bit_length() - 1} steps (an extrapolation, not a run)")

print("D's memory model: rule block 16 + window g + step counter k bits, k = bits of 2 g 2^g")
for n in (16, 64, 256, 1024):
    g = n * n
    k = (2 * g * 2 ** g).bit_length()
    total = 16 + g + k
    print(f"  n {n:>5}  g = n^2 {c(g):>9}  k {c(k):>9}  cells {c(total):>9}  cells / g {total / g:.3f}")

print("the ladder at three input lengths: log2 n, (log2 n)^2, n, n^2")
for e in (10, 20, 30):
    n = 2 ** e
    print(f"  n = 2^{e}: {e}, {c(e * e)}, {c(n)}, {c(n * n)}")
cross = next(n for n in range(2, 10 ** 4) if all(log2(m) ** 2 <= m for m in range(n, 10 ** 4)))
print(f"(log2 n)^2 <= n for every n from {cross} on; at n = 15 it is {log2(15) ** 2:.3f}")
assert cross == 16

k16 = (2 * 16 * 2 ** 16).bit_length()
print(f"wrong: D squeezed into the machines' own n = 16 cells: it needs 16 + 16 + {k16} = {32 + k16} cells")
i, r, f = rep_max[1], rep_max[0], rep_max[2]
out, steps, used, _ = run_direct(i, format(i, "016b"), W, cap=10 ** 6, detect=False)
assert out == RUN
print(f"wrong: no loop check: machine {c(i)} is still running after {c(steps)} steps inside {used} cells")
print(f"  proof that it never stops: at step {r} it is back in its step-{f} configuration")
late_cap = sum(1 for i in late_acc if run_direct(i, format(i, "016b"), W, cap=16)[0] == RUN)
print(f"wrong: counter capped at n = 16 steps: {len(late_acc)} machines accept after step 16; "
      f"the capped D cuts off {late_cap}, calls them loops and agrees with them")
assert late_cap == len(late_acc) == 4
t16 = [0] * 4
for i in range(65536):
    t16[run_direct(i, format(i, "016b"), 16)[0]] += 1
print(f"try: window 16 cells: accept {c(t16[ACC])}, reject {c(t16[REJ])}, leave {c(t16[OUT])}, loop {c(t16[LOOP])}")
print(f"budgets at n = 1,024: log2 n = 10, (log2 n)^2 = 100, n = 1,024, n^2 = {c(1024 * 1024)}")
print("ALL CHECKS PASS")
