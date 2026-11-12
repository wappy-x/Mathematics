# Cost in practice: count the operations, then let arrays do them at once

[Syllabus](../../../SYLLABUS.md) → [Applied and computational](../README.md) → [Scientific Computing Practice](../README.md#s08) → Cost in practice

---

## General Overview

A check script in this library has to answer a question about luck. Bet £1 on a fair coin 64 times in a row. What share of people who do this end at least £16 up? Ending £16 up means at least 40 heads out of 64. The script answers by simulation (running the experiment on made-up random numbers): it plays out 1,000,000 paths, one path being one person's 64 bets, and counts the paths that end £16 up.

Each path costs the same short list of work. Turn the path's number into 64 random bits, one bit per coin: 13 operations. Count the heads: 1 operation. Compare with 40: 1 operation. Add the result to the running total: 1 operation. That is 16 operations on one number each, so 16,000,000 for the whole run. Count the operations first, because that number is fixed by the method: running the same instructions as a loop or as arrays does not change it.

How the 16,000,000 operations are launched is a separate cost. Written as a loop in Python, the **interpreter** (the program that reads Python and carries it out, line by line) handles every one of them separately. Each time it reads the instruction, checks what kind of numbers it holds, makes a new number for the result and stores it. That bookkeeping costs more than the arithmetic itself. Written as **array work**, each of the 16 instructions is launched once for all 1,000,000 paths together, and the repetition happens inside compiled code (code already turned into the machine's own instructions). The arithmetic stays at 16,000,000 operations. The launches fall from 16,000,000 to 16, counted by a small interpreter the script builds for the purpose: a table of 15 instructions and a runner that reads them. Launching is the only bookkeeping that arrays of Python's own numbers remove. Each number still has its type checked and a new number made for its result. Removing that too takes arrays of bare machine numbers of one type, such as NumPy's, which this standard-library card describes but cannot run. A plain loop in Rust needs no interpreter at all: the compiler turned it into machine instructions before the run.

All three versions find the same 30,037 paths, about 3 in 100. The exact answer, worked out without any simulation, is 0.029971.

**Count the operations a computation needs; then make the interpreter launch each kind of operation once for a whole array, not once per number: the arithmetic stays the same, and the launches fall from one per number to one per array.**

**What kind of fact this is:** the counts are exact, proved in Why it works and counted by the code. That the bookkeeping, not the arithmetic, dominates an interpreted loop is a model of how interpreters behave: widely observed, not a law. This card measures no times.

### The picture: same arithmetic, different bookkeeping

```
Element operations, 1,000,000 paths
loop, path by path        ████████████████████████████████████████  16,000,000
arrays, all paths a step  ████████████████████████████████████████  16,000,000

Interpreter steps, 1,000,000 paths
loop, path by path        ████████████████████████████████████████  16,000,000
arrays, all paths a step                                                    16
plain Rust loop, compiled                                                    0
```

The two top bars are equal: arrays do not reduce the arithmetic. In the lower group the array bar is too short to draw, 16 against 16,000,000, and the compiled Rust loop has no interpreter steps at all. All bars share one scale, and every value is printed by the code below.

---

## The formula

$$\text{cost} \approx s \cdot D + e \cdot E, \qquad E = k\,n, \qquad D = \begin{cases} k\,n & \text{loop, path by path} \\ k\,\lceil n/b \rceil & \text{arrays, } b \text{ paths at a time} \\ 0 & \text{compiled loop} \end{cases}$$

**Read it aloud:** the cost is the price of each interpreter step times the number of steps, plus the price of each element operation times the number of those; the element operations are always k per path, but the steps are k per path in a loop and only k per batch with arrays.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $n$ | paths simulated | 1,000,000 | E grows in step; D grows with it for a loop, not for one array |
| $k$ | element operations per path: 15 instructions plus 1 add to the total | 16 | E and D both grow in step |
| $b$ | paths launched together in one array, the **chunk size** | 1,000,000 (one chunk); also 100 and 10,000 | fewer steps, but b numbers held in memory at once |
| $E$ | **element operations**: arithmetic or logic on one number | 16,000,000 | — |
| $D$ | **interpreter steps**: instructions the interpreter reads and launches | loop 16,000,000; arrays 16 | — |
| $s$ | price of one interpreter step | not measured on this card | the loop suffers, arrays barely notice |
| $e$ | price of one element operation in compiled code | not measured on this card | every version suffers equally |
| $\lceil x \rceil$ | x rounded up to a whole number | ⌈1,000,000 / 100⌉ = 10,000 chunks | — |
| $p$ | exact probability that a path ends at least £16 up | 0.029971 | — |
| $h$ | hits: paths that end at least £16 up | 30,037 | — |
| SE | standard error: the typical size of the gap between h/n and p, √(p(1 − p)/n) | 0.000171 | shrinks as n grows |
| $2^{64}$ | the number of different 64-coin sequences | the bottom of the fraction p | — |

The prices s and e depend on the machine, so this card counts D and E and never times them; [Big-O](../01-Algorithms%20and%20Growth/01-big-o-and-growth-rates.md) explains why counts, not stopwatch readings, are the honest measure. The model says only this: when s is far larger than e, cutting D is where the saving lies. That needs arrays of bare machine numbers, where e is a machine instruction or two. This card's standard-library arrays hold Python's own numbers, so each element operation still checks types and makes a new number: their e is not small, and cutting D alone may save nothing (Step 3).

### When it holds

- **The paths are independent.** Arrays work across paths because no path needs another path's result. One shared stream, where each draw needs the one before, cannot be launched for all paths in one step. This script gives path i its own counter, i, and mixes that instead.
- **Each array operation runs in compiled code.** Python's `map` with a built-in operation such as `operator.mul` loops in compiled code. Hand it a Python function, or write a list comprehension, and the interpreter runs every element again: D climbs back to 16,000,000.
- **There is memory for b numbers at once.** One chunk of 1,000,000 holds 1,000,000 numbers per array. Chunks of 10,000 hold 10,000 and cost 1,600 steps instead of 16, still far below the loop's 16,000,000.
- **The arithmetic is exact.** Integer results do not depend on order, so every version finds 30,037. Floating-point sums do depend on order, and array libraries often add in a different order from a loop, so their last digits can differ ([Floating point](01-floating-point-in-practice.md)).
- **The numbers behave the same in both languages.** Rust's 64-bit integers wrap round (keep only the low 64 bits) for free. Python's integers never wrap, so the Python code masks after each multiply: three extra operations per path, 16 against 13.

---

## Why it works

### Step 0: the work is a grid, and either order covers it

Lay the work out as a grid. Each row is one path; each column is one of the 16 instructions. The whole run is 1,000,000 rows by 16 columns, and every cell is one element operation. A loop walks the grid row by row: path 1's 16 cells, then path 2's. Array work walks it column by column: instruction 1 for every path, then instruction 2 for every path. Inside a row the order matters, because each instruction uses the one before. Across rows it does not, because no path reads another. So both walks fill in exactly the same cells with exactly the same values. What differs is how many times the interpreter has to start something: once per cell, or once per column.

### Step 1: element operations are k times n, in any order

Every cell is computed once, whichever way the grid is walked. So

$$E = k\,n = 16 \times 1{,}000{,}000 = 16{,}000{,}000.$$

The code counts E as it goes, adding 1 per cell in the loop and adding the array's length per array instruction, and both counts come out at 16,000,000. Vectorising (rewriting a loop as array work) never removes arithmetic. It only moves the repetition from the interpreter into compiled code.

### Step 2: interpreter steps are k per path, or k per chunk

In the loop the interpreter launches every cell separately, so D = k n = 16,000,000. In array work it launches one whole column per step. With the paths cut into chunks of b, there are ⌈n/b⌉ chunks and k steps for each:

$$D = k \lceil n/b \rceil.$$

For b = 100 that is 16 × 10,000 = 160,000 steps; for b = 10,000, 1,600; for one chunk of all 1,000,000 paths, 16. Setting b = 1 gives back the loop's 16,000,000, which is why a loop is just arrays of length one. The code counts D both ways and meets the formula at each b.

The doubling test from [Big-O](../01-Algorithms%20and%20Growth/01-big-o-and-growth-rates.md) shows the difference in growth. At 1,000 paths the loop takes 16,000 steps and arrays take 16; at 2,000 paths the loop takes 32,000 and arrays still 16. The loop's steps are order n; one array's steps are order 1, a fixed count whatever n is.

### Step 3: why a step costs so much more than the arithmetic

Python decides almost nothing before the program runs. A name such as `z` might hold a small integer, a huge one or a string, so before every `*` the interpreter looks up what `z` holds, checks both types, picks the right multiply, makes a new number object for the result and stores it. The multiply itself, for numbers that fit in 64 bits, is one machine instruction. The bookkeeping is many.

Array work removes only the reading and launching: one launch per array instead of one per number. The rest of the bookkeeping belongs to the numbers themselves. This card's arrays are lists of Python integers, so `map` with `operator.mul` still checks the types and makes a new number object for every element: inside compiled code, but once per number. Arrays built for numerical work, such as NumPy's (Sources), store bare 64-bit numbers of one type in one block of memory. They check the type once per array, and the loop over the numbers costs a few machine instructions each. A standard-library card can describe them but not run them. A compiled language such as Rust does all the bookkeeping once, at compile time, for the whole program: it knows `z` is always a 64-bit integer, so the loop body becomes a handful of machine instructions and D = 0.

This is the model behind the formula: s, the price of a step, is many times e, the price of an element operation on bare machine numbers. It is how array libraries are designed (see Sources), but it is a statement about machines, so the card leaves it as a model and asserts no time. For this card's lists of Python integers, e carries the per-number bookkeeping too, so the model promises them no saving; what the card checks is the counts, D and E.

The Python script does ask the interpreter itself for one confirmation. Python offers a trace hook (a function it calls before running each line of Python). The script counts those calls: for the loop they grow in step with the number of paths, and for the array runner they stay the same when the paths double. That check is asserted but not printed, because Rust has no such hook.

### Step 4: the simulated answer meets the exact one

A path ends at least £16 up when it has at least 40 heads among 64 fair coins. Each of the 2⁶⁴ head-and-tail sequences is equally likely. The number of sequences with exactly j heads is entry j of row 64 of Pascal's triangle (each row made by adding neighbours in the row above). Adding entries 40 to 64 gives 552,859,891,708,071,949 sequences, so

$$p = \frac{552{,}859{,}891{,}708{,}071{,}949}{2^{64}} = 0.029971,$$

and 1,000,000 paths should give about 29,970.6 hits. The simulation's hits h are the total of a million yes-or-no results, so h/n has standard error SE = √(p(1 − p)/n) = 0.000171. The run gives h = 30,037, an estimate of 0.030037, which is 0.39 standard errors above p. A correct simulation almost always lands within 4 standard errors of p; the code asserts the gap is under 4.

The random bits come from SplitMix64 (a small generator of 64-bit random numbers written out in full; [Seeds](03-reproducible-simulation-and-seeds.md) covers how its seed makes a run repeatable). Path i uses the generator's i-th output from seed 2026. Before trusting it, the code checks it against a SplitMix64 test vector (five known outputs written into the script): from seed 1234567 the first is 6,457,827,717,110,365,317.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| element operations per path | 15 instructions + 1 add to the total | 16 |
| element operations, whole run | 16 × 1,000,000 | 16,000,000 |
| interpreter steps, loop | one per element operation | 16,000,000 |
| interpreter steps, one array chunk | 16 × ⌈1,000,000 / 1,000,000⌉ | 16 |
| interpreter steps, chunks of 10,000 | 16 × 100 | 1,600 |
| steps saved, loop ÷ one chunk | 16,000,000 ÷ 16 | 1,000,000 |
| exact probability | 552,859,891,708,071,949 ÷ 2⁶⁴ | 0.029971 |
| simulated hits | counted by all three versions | **30,037** |

Every version did the same 16,000,000 operations and agreed on 30,037 hits; the array version needed 1,000,000 times fewer of the script's interpreter steps to launch them.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Dropping the last 64-bit mask in Python | 999,991 hits: nearly every path, not 3 in 100 | Python integers never wrap, so z grew past 64 bits and its bit count counted coins that do not exist |
| Giving every path the same counter | 0 hits | all 1,000,000 paths drew the same 64 coins: one path copied a million times, which here missed |
| Quoting the array version's cost as its 16 steps | 16, against 16,000,000 element operations | arrays move the arithmetic into compiled code; they do not remove it |

The code prints all three.

---

## Code, from first principles, and it actually runs

The script writes one path's work as a table of 15 instructions and runs it two ways, each counting its own element operations and interpreter steps: path by path, and instruction by instruction across an array, in chunks of 100, 10,000 and 1,000,000. A plain loop written the ordinary way finds the same hits. The roads to the answer are independent: the exact probability from Pascal's triangle, with no random numbers; the simulation, which must land within 4 standard errors of it; and the counts, which must meet the formulas k n and k⌈n/b⌉. The generator also meets a SplitMix64 test vector, and in Python the interpreter's own trace hook confirms that the loop's work grows with n while the array runner's does not. In Python, `operator` supplies single operations such as multiply and shift, and `itertools.repeat` hands the same constant to every element; neither knows the answer.

### Python

```python
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
```

**Ran 2026-11-11 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
paths n = 1000000, seed 2026; 64 bets of £1 each; question: share ending >= £16 up (>= 40 heads)
exact: 552859891708071949 of 2^64 coin sequences, p = 0.029971; expected paths 29970.6
SplitMix64 seed 1234567, first output 6457827717110365317
per path: 15 instructions + 1 add to the total = 16 element ops
loop, path by path:     hits 30037, element ops 16000000, interpreter steps 16000000
arrays, all paths a step: hits 30037, element ops 16000000, interpreter steps 16
plain loop, no table: hits 30037; per path 16 element ops with masks, 13 where numbers wrap at 64 bits (13 x n = 13000000); in Rust it is compiled, 0 interpreter steps
estimate 0.030037; standard error 0.000171; off by 0.39 SE (allowed: under 4)
steps saved: loop / arrays = 1000000
doubling test, counted:
  n = 1000: loop steps 16000, array steps 16
  n = 2000: loop steps 32000, array steps 16
chunks of b paths at a time, n = 1000000:
  b = 100: steps 160000 (formula 16 n / b = 160000), numbers held 100, hits 30037
  b = 10000: steps 1600 (formula 16 n / b = 1600), numbers held 10000, hits 30037
  b = 1000000: steps 16 (formula 16 n / b = 16), numbers held 1000000, hits 30037
mistake, last mask dropped (Python ints never wrap): hits 999991 (steps 15, element ops 15000000)
mistake, every path given the same counter: hits 0
mistake, quoting the array version's cost as its steps: 16 against 16000000 element ops
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`. The instruction table runs on 128-bit integers with explicit masks, exactly as Python's integers behave; the plain loop uses 64-bit integers, which wrap on their own.

```rust
// Cost in practice -- the same check as the Python, in Rust.  No crates.  The
// instruction table runs on u128 with explicit masks, exactly as Python's
// integers do; the plain loop uses u64, whose arithmetic wraps at 64 bits.
// A cost here is a count, never a time: element operations, and interpreter
// steps (instructions the table runner has to read and launch).
const M64: u128 = (1u128 << 64) - 1;
const GAMMA: u64 = 0x9E3779B97F4A7C15;
const C1: u64 = 0xBF58476D1CE4E5B9;
const C2: u64 = 0x94D049BB133111EB;
const SEED: u64 = 2026;
const N: u64 = 1000000;
const LEVEL: u32 = 40;

#[derive(Clone, Copy)]
enum Arg { Reg(usize), K(u128), Nothing }
use Arg::*;
type Ins = (&'static str, usize, usize, Arg);       // (operation, destination, a, b)
const Z: usize = 0;
const T: usize = 1;

fn program(seed: u64, mask: bool, upto: usize) -> Vec<Ins> { // one path's work
    let p: Vec<Ins> = vec![("mul", Z, Z, K(GAMMA as u128)), ("add", Z, Z, K(seed as u128)),
        ("and", Z, Z, K(M64)), ("shr", T, Z, K(30)), ("xor", Z, Z, Reg(T)),
        ("mul", Z, Z, K(C1 as u128)), ("and", Z, Z, K(M64)), ("shr", T, Z, K(27)),
        ("xor", Z, Z, Reg(T)), ("mul", Z, Z, K(C2 as u128)), ("and", Z, Z, K(M64)),
        ("shr", T, Z, K(31)), ("xor", Z, Z, Reg(T)), ("pop", Z, Z, Nothing),
        ("ge", Z, Z, K(LEVEL as u128))];
    p.into_iter().enumerate().filter(|(k, _)| mask || *k != 10)  // 10: the last mask
        .map(|(_, s)| s).take(upto).collect()
}

fn apply(name: &str, x: u128, y: u128) -> u128 {    // one element operation
    match name {
        "mul" => x.wrapping_mul(y), "add" => x + y, "and" => x & y, "shr" => x >> y,
        "xor" => x ^ y, "pop" => x.count_ones() as u128, "ge" => (x >= y) as u128,
        _ => panic!("unknown operation"),
    }
}

fn run_loop(n: u64, prog: &[Ins]) -> (u128, u64, u64) { // for each path: each instruction
    let (mut steps, mut elems, mut total) = (0u64, 0u64, 0u128);
    for i in 1..=n {
        let mut reg = [i as u128, 0];
        for &(name, dst, a, b) in prog {
            let y = match b { Reg(r) => reg[r], K(k) => k, Nothing => 0 };
            reg[dst] = apply(name, reg[a], y);
            steps += 1;
            elems += 1;
        }
        total += reg[Z];
        steps += 1;
        elems += 1;
    }
    (total, steps, elems)
}

// for each instruction: every path in the chunk at once
fn run_arrays(n: u64, prog: &[Ins], chunk: u64) -> (u128, u64, u64, u64, Vec<u128>) {
    let (mut steps, mut elems, mut total, mut peak) = (0u64, 0u64, 0u128, 0u64);
    let mut last = Vec::new();
    let mut lo = 1;
    while lo <= n {
        let hi = (lo + chunk).min(n + 1);
        let mut reg: [Vec<u128>; 2] = [(lo..hi).map(|i| i as u128).collect(), Vec::new()];
        let size = hi - lo;
        peak = peak.max(size);
        for &(name, dst, a, b) in prog {
            let out: Vec<u128> = (0..size as usize).map(|j| {
                let y = match b { Reg(r) => reg[r][j], K(k) => k, Nothing => 0 };
                apply(name, reg[a][j], y)
            }).collect();
            reg[dst] = out;
            steps += 1;                              // one step launches a whole array
            elems += size;
        }
        total += reg[Z].iter().sum::<u128>();
        steps += 1;
        elems += size;
        last = reg[Z].clone();
        lo = hi;
    }
    (total, steps, elems, peak, last)
}

fn plain_loop(n: u64) -> u64 {                       // the loop as a person writes it
    let mut hits = 0;
    for i in 1..=n {
        let mut z = i.wrapping_mul(GAMMA).wrapping_add(SEED);
        z = (z ^ (z >> 30)).wrapping_mul(C1);
        z = (z ^ (z >> 27)).wrapping_mul(C2);
        hits += ((z ^ (z >> 31)).count_ones() >= LEVEL) as u64;
    }
    hits
}

fn main() {
    // Road 1: the exact answer, from a row of Pascal's triangle.
    let mut row: Vec<u128> = vec![1];
    for _ in 0..64 {
        let mut next = vec![1u128; row.len() + 1];
        for k in 1..row.len() { next[k] = row[k - 1] + row[k] }
        row = next;
    }
    let ways: u128 = row[LEVEL as usize..].iter().sum();
    let p = ways as f64 / 2f64.powi(64);
    let nf = N as f64;
    let se = (p * (1.0 - p) / nf).sqrt();
    println!("paths n = {}, seed {}; 64 bets of £1 each; question: share ending >= £16 up (>= {} heads)",
             N, SEED, LEVEL);
    println!("exact: {} of 2^64 coin sequences, p = {:.6}; expected paths {:.1}", ways, p, nf * p);
    let vec5 = run_arrays(5, &program(1234567, true, 13), 5).4;
    println!("SplitMix64 seed 1234567, first output {}", vec5[0]);
    // Road 2: the same program run three ways, each counting its own operations.
    let prog = program(SEED, true, 99);
    let lp = run_loop(N, &prog);
    let arr = run_arrays(N, &prog, N);
    let plain = plain_loop(N);
    println!("per path: {} instructions + 1 add to the total = {} element ops", prog.len(), lp.2 / N);
    println!("loop, path by path:     hits {}, element ops {}, interpreter steps {}", lp.0, lp.2, lp.1);
    println!("arrays, all paths a step: hits {}, element ops {}, interpreter steps {}", arr.0, arr.2, arr.1);
    println!("plain loop, no table: hits {}; per path 16 element ops with masks, \
              13 where numbers wrap at 64 bits (13 x n = {}); in Rust it is compiled, 0 interpreter steps", plain, 13 * N);
    let est = lp.0 as f64 / nf;
    println!("estimate {:.6}; standard error {:.6}; off by {:.2} SE (allowed: under 4)", est, se, (est - p) / se);
    println!("steps saved: loop / arrays = {}", lp.1 / arr.1);
    println!("doubling test, counted:");
    for n in [1000u64, 2000] {
        println!("  n = {}: loop steps {}, array steps {}", n, run_loop(n, &prog).1, run_arrays(n, &prog, n).1);
    }
    println!("chunks of b paths at a time, n = 1000000:");
    let chunks: Vec<(u64, (u128, u64, u64, u64, Vec<u128>))> =
        [100u64, 10000, N].iter().map(|&b| (b, run_arrays(N, &prog, b))).collect();
    for (b, r) in &chunks {
        println!("  b = {}: steps {} (formula 16 n / b = {}), numbers held {}, hits {}",
                 b, r.1, 16 * N / b, r.3, r.0);
    }
    // What breaks.
    let nomask = run_arrays(N, &program(SEED, false, 99), N);
    let mut forced: Vec<Ins> = vec![("add", Z, Z, K(0)), ("mul", Z, Z, K(0)), ("add", Z, Z, K(1))];
    forced.extend(prog.iter().cloned());             // every path's counter forced to 1
    let same = run_arrays(N, &forced, N);
    println!("mistake, last mask dropped (Python ints never wrap): hits {} (steps {}, element ops {})",
             nomask.0, nomask.1, nomask.2);
    println!("mistake, every path given the same counter: hits {}", same.0);
    println!("mistake, quoting the array version's cost as its steps: {} against {} element ops",
             arr.1, arr.2);
    assert!(vec5 == vec![6457827717110365317, 3203168211198807973, 9817491932198370423,
                         4593380528125082431, 16408922859458223821]);
    assert!(lp.0 == arr.0 && lp.0 == plain as u128 && lp.0 == chunks[0].1 .0 && lp.0 == chunks[1].1 .0);
    assert!((est - p).abs() < 4.0 * se);
    assert!(lp.1 == 16 * N && lp.2 == 16 * N && arr.2 == 16 * N && arr.1 == 16);
    assert!(chunks.iter().all(|(b, r)| r.1 == 16 * N / b));
    assert!(nomask.0 as f64 > nf * p + 10.0 * nf * se && (same.0 == 0 || same.0 == N as u128));
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-11 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
paths n = 1000000, seed 2026; 64 bets of £1 each; question: share ending >= £16 up (>= 40 heads)
exact: 552859891708071949 of 2^64 coin sequences, p = 0.029971; expected paths 29970.6
SplitMix64 seed 1234567, first output 6457827717110365317
per path: 15 instructions + 1 add to the total = 16 element ops
loop, path by path:     hits 30037, element ops 16000000, interpreter steps 16000000
arrays, all paths a step: hits 30037, element ops 16000000, interpreter steps 16
plain loop, no table: hits 30037; per path 16 element ops with masks, 13 where numbers wrap at 64 bits (13 x n = 13000000); in Rust it is compiled, 0 interpreter steps
estimate 0.030037; standard error 0.000171; off by 0.39 SE (allowed: under 4)
steps saved: loop / arrays = 1000000
doubling test, counted:
  n = 1000: loop steps 16000, array steps 16
  n = 2000: loop steps 32000, array steps 16
chunks of b paths at a time, n = 1000000:
  b = 100: steps 160000 (formula 16 n / b = 160000), numbers held 100, hits 30037
  b = 10000: steps 1600 (formula 16 n / b = 1600), numbers held 10000, hits 30037
  b = 1000000: steps 16 (formula 16 n / b = 16), numbers held 1000000, hits 30037
mistake, last mask dropped (Python ints never wrap): hits 999991 (steps 15, element ops 15000000)
mistake, every path given the same counter: hits 0
mistake, quoting the array version's cost as its steps: 16 against 16000000 element ops
ALL CHECKS PASS
```

The two outputs match line for line.

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **Guess first:** how many interpreter steps do arrays need for twice as many paths? Set `N = 2000000`. The loop's steps double to 32,000,000; one array chunk still takes 16. Hits become 60,046, an estimate of 0.030023, and every assert passes.
> - **Guess first:** what do chunks of 1,000 cost? Change `(100, 10000, N)` to `(1000, 10000, N)`. The steps are 16,000 and each array holds 1,000 numbers; the hits stay 30,037.
> - **Guess first:** does a different seed give the same hits? Set `SEED = 7` in the line with `N`. Hits become 30,194, an estimate of 0.030194, 1.31 standard errors above p. The estimate moves; the counts do not.
> - **Guess first:** what share end at least £8 up, 36 heads or more? Set `LEVEL = 36`. The exact p becomes 0.190866 and the run finds 191,542 hits, 1.72 standard errors above, and every assert still passes.

---

## The usual mistake

> [!warning]
> **Believing that arrays do less work.** They do the same work with less bookkeeping. The array version still performs 16,000,000 element operations; it launches them in 16 steps instead of 16,000,000. So vectorising a method speeds it up by a fixed factor at best, and never changes its growth rate. A method whose operation count is too big stays too big. Count the operations first, choose a method with a smaller count, and only then vectorise it.
>
> Smaller traps:
> - **A list comprehension is not array work.** It is a loop written on one line: the interpreter still runs every element, 16,000,000 steps, the same as the loop.
> - **Forgetting that Python integers never wrap.** Rust's 64-bit multiply keeps the low 64 bits for free. Drop Python's mask after the last multiply and the run reports 999,991 hits instead of 30,037.
> - **Copying one generator state into every path.** Give every path the same starting counter, as happens when one generator's state is copied into a whole array, and every path draws the same coins: 0 hits.
> - **Timing one run and calling it the cost.** A stopwatch reading mixes s, e, the machine and whatever else is running. The counts, 16,000,000 operations and 16 or 16,000,000 steps, are the same on every machine.

---

## Where you meet it in real life

- **Array libraries for science and data.** Python's numerical array libraries hold numbers of one type in one block of memory and run each operation over the whole block in compiled code. That is the column-by-column walk of Step 0, and the reason analysts write `prices * rate` on a whole array instead of a loop.
- **Processor vector instructions.** A modern processor has instructions that add or multiply several numbers in one go. A compiler can turn a plain loop over independent elements, like this card's Rust loop, into such instructions, so independence pays twice.
- **Graphics cards.** A graphics card runs the same instruction on thousands of numbers at once. Simulations with millions of independent paths, like this one, suit them well; a calculation where each step needs the last does not.
- **Database engines.** Many analytic databases process a column in batches of values instead of one row at a time, for the same reason: the per-row bookkeeping shrinks to per-batch.
- **This library's check scripts.** They use the standard library only, so their loops are plain and readable. When a Python check is slow, the first question is how many operations it does, the second how many steps launch them.

> **Say it back**
> First count the operations: here 16 per path, 16,000,000 for a million paths. An interpreted loop launches each one separately, and that bookkeeping costs more than the arithmetic. Array work launches each instruction once for a whole array of paths, so the steps fall from 16,000,000 to 16 while the arithmetic stays at 16,000,000. Arrays of Python's own numbers still check a type and make a new number for each element; arrays of bare machine numbers, such as NumPy's, drop that too. It needs independent paths, compiled array operations and memory for the arrays; chunks trade a few more steps for less memory. A compiled loop has no interpreter steps at all, and every version finds the same 30,037 paths, close to the exact 0.029971.

---

## What this builds on

- [Big-O](../01-Algorithms%20and%20Growth/01-big-o-and-growth-rates.md): cost as a count of a named operation, growing with n, never a stopwatch reading; the doubling test used in Step 2.
- [Floating point](01-floating-point-in-practice.md): why a floating-point sum depends on its order, so a loop and an array library can disagree in the last digits where this card's integer counts cannot.

## Where this goes next

- [The check script](07-writing-a-check-script.md): the asserts, roads and printed outputs that every card's script carries, including this one's.
- [Counting the work](../../16-Numerical%20analysis/01-Floating%20Point%20and%20Error/08-operation-counts-and-cost.md): turning a loop into a cost formula line by line.

This card counts steps and operations but prices neither: how large s and e really are on a given machine, and what memory traffic adds, is left open.

---

## Sources

Verified 2026-11-11: every link below resolves to the publisher's page.

- van der Walt, Stéfan, S. Chris Colbert, and Gaël Varoquaux. "The NumPy Array: A Structure for Efficient Numerical Computation." *Computing in Science & Engineering* 13, no. 2 (2011): 22–30. [doi:10.1109/MCSE.2011.37](https://doi.org/10.1109/MCSE.2011.37). How one array operation replaces a Python loop, and why that removes interpreter overhead.
- Harris, Charles R., et al. "Array programming with NumPy." *Nature* 585 (2020): 357–362. [doi:10.1038/s41586-020-2649-2](https://doi.org/10.1038/s41586-020-2649-2). Array programming as the standard way numerical Python is written, and the operations it vectorises.
- Behnel, Stefan, et al. "Cython: The Best of Both Worlds." *Computing in Science & Engineering* 13, no. 2 (2011): 31–39. [doi:10.1109/MCSE.2010.118](https://doi.org/10.1109/MCSE.2010.118). Where an interpreter's per-operation cost comes from, and what compiling with known types removes.
- Steele, Guy L., Doug Lea, and Christine H. Flood. "Fast splittable pseudorandom number generators." *OOPSLA 2014*: 453–472. [doi:10.1145/2660193.2660195](https://doi.org/10.1145/2660193.2660195). SplitMix64, whose i-th output depends only on i and the seed, which is what lets every path draw its coins at once.
