# Church-Turing thesis: double a recipe in three models, then run one model inside another.
# Standard library only. The tape machine is explained on the Turing machines card.
from math import log10
SYM, RT, LT = '_1XY', 1, -1      # symbols 0..3: blank, one, done-mark X, copy-mark Y
TM = {('mark', 1): (2, RT, 'end'), ('mark', 3): (1, RT, 'fix'), ('mark', 0): (0, RT, 'halt'),
      ('end', 1): (1, RT, 'end'), ('end', 3): (3, RT, 'end'), ('end', 0): (3, LT, 'back'),
      ('back', 1): (1, LT, 'back'), ('back', 3): (3, LT, 'back'), ('back', 2): (2, RT, 'mark'),
      ('fix', 3): (1, RT, 'fix'), ('fix', 0): (0, LT, 'home'),
      ('home', 1): (1, LT, 'home'), ('home', 2): (1, LT, 'home'), ('home', 0): (0, RT, 'halt')}

def tape_run(n, cells=10**6, trace=None):
    """Model 1, a Turing machine on a list. Cell p sits at index p + 1. Returns reads, ones, steps."""
    tape, h, q, reads = [0] + [1] * n + [0] * (2 * n + 2), 1, 'mark', []
    while q != 'halt':
        if h >= cells:
            return reads, None, len(reads)           # ran off a tape of cells -1 to cells - 2
        s = tape[h]
        w, m, q2 = TM[(q, s)]
        reads.append((q, s))
        tape[h], h = w, h + m
        if trace is not None:
            trace.append((len(reads), q, SYM[s], SYM[w], 'R' if m == RT else 'L', q2, h - 1,
                          ''.join(SYM[c] for c in tape[1:6])))
        q = q2
    return reads, tape.count(1), len(reads)

def arith_start(n, b):
    return sum(b ** i for i in range(n))       # n ones, read as base-b digits

def arith_run(n, b, cap=10**5, trace=None):
    """Road 2: the same machine on two whole numbers, as a counter machine would hold it.
    rgt = the head's cell and everything right of it, in base b, head cell lowest digit.
    lft = everything left of the head, nearest cell lowest digit. Moves are *b, //b, %b."""
    lft, rgt, q, reads = 0, arith_start(n, b), 'mark', []
    while q != 'halt' and len(reads) < cap and (q, rgt % b) in TM:
        s = rgt % b
        w, m, q2 = TM[(q, s)]
        reads.append((q, s))
        rgt = rgt - s + w
        if m == RT:
            lft, rgt = lft * b + w, rgt // b
        else:
            lft, rgt = lft // b, rgt * b + lft % b
        if trace is not None:
            trace.append((lft, rgt))
        q = q2
    ones, x = 0, rgt
    while x > 0:
        ones, x = ones + (x % b == 1), x // b
    return reads, ones

DOUBLE = [('JZ', 'a', 5), ('DEC', 'a'), ('INC', 'b'), ('INC', 'b'), ('JZ', 'z', 0), ('HALT',)]
TRIPLE = [('JZ', 'a', 6), ('DEC', 'a'), ('INC', 'b'), ('INC', 'b'), ('INC', 'b'), ('JZ', 'z', 0), ('HALT',)]

def cm_run(prog, n):
    """Model 2, a counter machine: registers a, b and z (always 0), three instructions."""
    reg, pc, steps = {'a': n, 'b': 0, 'z': 0}, 0, 0
    while prog[pc][0] != 'HALT':
        op, steps = prog[pc], steps + 1
        if op[0] == 'INC':
            reg[op[1]], pc = reg[op[1]] + 1, pc + 1
        elif op[0] == 'DEC':
            reg[op[1]], pc = reg[op[1]] - 1, pc + 1
        else:
            pc = op[2] if reg[op[1]] == 0 else pc + 1
    return reg['b'], steps

def rec_run(n):
    """Model 3, recursive equations d(0) = 0 and d(S(x)) = S(S(d(x))), applied by rewriting text."""
    t, steps = 'd(' + 'S(' * n + '0' + ')' * n + ')', 0
    while 'd(' in t:
        i = t.index('d(')
        if t[i + 2] == '0':
            t = t[:i] + '0' + t[i + 4:]
        else:
            j, depth = i + 4, 1                      # find the ')' that closes the S( at i + 2
            while depth > 0:
                depth += {'(': 1, ')': -1}.get(t[j], 0)
                j += 1
            t = t[:i] + 'S(S(d(' + t[i + 4:j - 1] + ')))' + t[j + 1:]
        steps += 1
    return t.count('S'), steps

checks = 0
for n in range(61):                                  # three models, one answer, n = 0..60
    reads, ones, tms = tape_run(n)
    assert ones == 2 * n and cm_run(DOUBLE, n)[0] == 2 * n and rec_run(n)[0] == 2 * n
    assert cm_run(DOUBLE, n)[1] == 5 * n + 1 and rec_run(n)[1] == n + 1
    assert n == 0 or tms == 2 * (n + 1) ** 2         # closed form proved on the card
    if n <= 30:                                      # simulation: same reads at every step
        areads, aones = arith_run(n, 4)
        assert areads == reads and aones == 2 * n
    checks += 1
print('agree: tape, counters, equations all give 2n for n = 0..60;', checks, 'values')
print('closed forms: tape 2(n+1)^2 steps, counters 5n+1, equations n+1 rewrites')
print('simulation: tape and two base-4 numbers make the same reads at every step, n = 0..30')
print('recipe,n,doubled,tape_steps,counter_steps,rewrites')
for name, n in [('flour g', 200), ('milk ml', 300), ('eggs', 2), ('sugar g', 25)]:
    _, ones, tms = tape_run(n)
    print(f'{name},{n},{ones},{tms},{cm_run(DOUBLE, n)[1]},{rec_run(n)[1]}')
trace, nums = [], []
tape_run(2, trace=trace)
arith_run(2, 4, trace=nums)
print('run,step,state,read,write,move,next,head,cells 0-4,left,right')
print(f'run,0,mark,-,-,-,-,0,{SYM[1] * 2 + SYM[0] * 3},0,{arith_start(2, 4)}')
for row, (lf, rg) in zip(trace, nums):
    print('run,' + ','.join(str(v) for v in row) + f',{lf},{rg}')
for n in [25, 50, 100, 200, 300]:
    a, b, c = tape_run(n)[2], cm_run(DOUBLE, n)[1], rec_run(n)[1]
    print(f'chart,{n},{log10(a):.2f},{log10(b):.2f},{log10(c):.2f}')
reads, _ = arith_run(2, 4)
bad, _ = arith_run(2, 3, cap=200)
k = next(i for i in range(len(bad)) if bad[i] != reads[i])
assert (k + 1, SYM[bad[k][1]], SYM[reads[k][1]]) == (7, '_', 'Y')   # traced by hand on the card
print(f'break,base 3 for 4 symbols: first wrong read at step {k + 1}: '
      f'read {SYM[bad[k][1]]} where the tape holds {SYM[reads[k][1]]}')
big = max(n for n in range(100) if tape_run(n, cells=64)[1] == 2 * n)
off = tape_run(200, cells=64)
assert big == 31 and off[1] is None
print(f'break,tape of 64 cells: largest n doubled {big}; flour 200 runs off at step {off[2]}')
for steps in [10, 30]:
    print(f'break,zeno: step k takes 2^-k s; after {steps} steps {1 - 2.0 ** -steps:.10f} s')
print(f'try,triple program on flour: {cm_run(TRIPLE, 200)[0]} in {cm_run(TRIPLE, 200)[1]} steps')
print(f'try,base 5 agrees for n = 0..20: {all(arith_run(n, 5)[0] == tape_run(n)[0] for n in range(21))}')
print('ALL CHECKS PASS')
