# Cost in practice -- the check behind the card.  Standard library only:
# operator, itertools.repeat and int.bit_count are single operations done in
# compiled code; nothing imported knows the answer.  A cost here is a count,
# never a time: element operations, and interpreter steps (instructions the
# runner has to read and launch).  1,000,000 paths of 64 fair-coin £1 bets,
# random bits from SplitMix64; question: what share end at least £16 up?
import operator as op
import sys
from itertools import repeat

M64 = (1 << 64) - 1                              # keep the low 64 bits
GAMMA, C1, C2 = 0x9E3779B97F4A7C15, 0xBF58476D1CE4E5B9, 0x94D049BB133111EB
SEED, N, LEVEL = 2026, 1000000, 40               # 40 heads of 64 = £16 up

def program(seed, mask=True, upto=None):         # one path's work, as instructions
    p = [("mul", "z", "z", GAMMA), ("add", "z", "z", seed), ("and", "z", "z", M64),
         ("shr", "t", "z", 30), ("xor", "z", "z", "t"), ("mul", "z", "z", C1),
         ("and", "z", "z", M64), ("shr", "t", "z", 27), ("xor", "z", "z", "t"),
         ("mul", "z", "z", C2), ("and", "z", "z", M64), ("shr", "t", "z", 31),
         ("xor", "z", "z", "t"), ("pop", "z", "z", None), ("ge", "z", "z", LEVEL)]
    p = [s for k, s in enumerate(p) if mask or k != 10]  # 10: the last mask
    return p[:upto]

OPS = {"mul": op.mul, "add": op.add, "and": op.and_, "shr": op.rshift,
       "xor": op.xor, "pop": int.bit_count, "ge": op.ge}

def run_loop(n, prog, start=1):                  # for each path: for each instruction
    steps = elems = total = 0
    for i in range(start, start + n):
        reg = {"z": i}
        for name, dst, a, b in prog:
            y = reg[b] if isinstance(b, str) else b
            reg[dst] = OPS[name](reg[a]) if y is None else OPS[name](reg[a], y)
            steps += 1
            elems += 1
        total += reg["z"]                        # the running sum, one add per path
        steps += 1
        elems += 1
    return total, steps, elems

def run_arrays(n, prog, chunk, start=1):         # for each instruction: every path at once
    steps = elems = total = peak = 0
    for lo in range(start, start + n, chunk):
        reg = {"z": range(lo, min(lo + chunk, start + n))}
        size = len(reg["z"])
        peak = max(peak, size)
        for name, dst, a, b in prog:
            f, xs = OPS[name], reg[a]
            if b is None:
                reg[dst] = list(map(f, xs))
            elif isinstance(b, str):
                reg[dst] = list(map(f, xs, reg[b]))
            else:
                reg[dst] = list(map(f, xs, repeat(b)))
            steps += 1                           # one step launches a whole array
            elems += size
        total += sum(reg["z"])
        steps += 1
        elems += size
    return total, steps, elems, peak, reg["z"]

def plain_loop(n):                               # the loop as a person writes it
    hits = 0
    for i in range(1, n + 1):
        z = (i * GAMMA + SEED) & M64
        z = ((z ^ (z >> 30)) * C1) & M64
        z = ((z ^ (z >> 27)) * C2) & M64
        hits += (z ^ (z >> 31)).bit_count() >= LEVEL
    return hits

# Road 1: the exact answer, from a row of Pascal's triangle (no simulation).
row = [1]
for _ in range(64):
    row = [a + b for a, b in zip([0] + row, row + [0])]
ways = sum(row[LEVEL:])
p = ways / 2 ** 64
se = (p * (1 - p) / N) ** 0.5
print(f"paths n = {N}, seed {SEED}; 64 bets of £1 each; question: share ending >= £16 up (>= {LEVEL} heads)")
print(f"exact: {ways} of 2^64 coin sequences, p = {p:.6f}; expected paths {N * p:.1f}")
# The generator meets a SplitMix64 test vector (seed 1234567, first five outputs).
vec = run_arrays(5, program(1234567, upto=13), 5)[4]
print(f"SplitMix64 seed 1234567, first output {vec[0]}")
# Road 2: the same program run three ways, each counting its own operations.
loop = run_loop(N, program(SEED))
arr = run_arrays(N, program(SEED), N)
plain = plain_loop(N)
print(f"per path: {len(program(SEED))} instructions + 1 add to the total = {loop[2] // N} element ops")
print(f"loop, path by path:     hits {loop[0]}, element ops {loop[2]}, interpreter steps {loop[1]}")
print(f"arrays, all paths a step: hits {arr[0]}, element ops {arr[2]}, interpreter steps {arr[1]}")
print(f"plain loop, no table: hits {plain}; per path 16 element ops with masks, "
      f"13 where numbers wrap at 64 bits (13 x n = {13 * N}); in Rust it is compiled, 0 interpreter steps")
print(f"estimate {loop[0] / N:.6f}; standard error {se:.6f}; off by {(loop[0] / N - p) / se:.2f} SE (allowed: under 4)")
print(f"steps saved: loop / arrays = {loop[1] // arr[1]}")
print("doubling test, counted:")
for n in (1000, 2000):
    print(f"  n = {n}: loop steps {run_loop(n, program(SEED))[1]}, "
          f"array steps {run_arrays(n, program(SEED), n)[1]}")
print("chunks of b paths at a time, n = 1000000:")
chunks = [(b, run_arrays(N, program(SEED), b)) for b in (100, 10000, N)]
for b, r in chunks:
    print(f"  b = {b}: steps {r[1]} (formula 16 n / b = {16 * N // b}), numbers held {r[3]}, hits {r[0]}")
# What breaks.
nomask = run_arrays(N, program(SEED, mask=False), N)
same = run_arrays(N, [("add", "z", "z", 0), ("mul", "z", "z", 0), ("add", "z", "z", 1)]
                  + program(SEED), N)            # every path's counter forced to 1
print(f"mistake, last mask dropped (Python ints never wrap): hits {nomask[0]} "
      f"(steps {nomask[1]}, element ops {nomask[2]})")
print(f"mistake, every path given the same counter: hits {same[0]}")
print(f"mistake, quoting the array version's cost as its steps: {arr[1]} against "
      f"{arr[2]} element ops")
# Road 3: the interpreter's own trace hook counts Python lines run (asserted only).
def traced(fn, *args):
    count = [0]
    def tr(frame, event, arg):
        count[0] += event == "line"
        return tr
    sys.settrace(tr)
    fn(*args)
    sys.settrace(None)
    return count[0]
t_loop = [traced(run_loop, n, program(SEED)) for n in (200, 400)]
t_arr = [traced(run_arrays, n, program(SEED), n) for n in (200, 400)]
assert t_loop[1] - t_loop[0] == t_loop[0] - traced(run_loop, 0, program(SEED))  # grows with n
assert t_arr[0] == t_arr[1]                                    # flat: the work ran in C
assert vec == [6457827717110365317, 3203168211198807973, 9817491932198370423,
               4593380528125082431, 16408922859458223821]      # SplitMix64 test vector
assert loop[0] == arr[0] == plain == chunks[0][1][0] == chunks[1][1][0]  # three runs agree
assert abs(loop[0] / N - p) < 4 * se                           # simulation meets exact
assert loop[1] == loop[2] == arr[2] == 16 * N and arr[1] == 16  # counts meet formulas
assert all(r[1] == 16 * N // b for b, r in chunks)
assert nomask[0] > N * p + 10 * N * se and same[0] in (0, N)  # far from right
print("ALL CHECKS PASS")
