# Busy beaver -- the check behind the card.  Standard library only.  A tape
# machine has n states, A, B, C, ..., and the symbols 0 and 1.  It starts in
# state A on a blank tape (all 0).  BB(n) is the most steps any n-state machine
# takes before it halts; the halting step counts.  Code never decides halting in
# general: a run either halts, or prints a proof that it never will, or prints
# 'still running' at its cap.  The tape machine is explained on the Turing card.
import itertools, math
KINDS = ['halt', 'repeats', 'repeats shifted', 'no exit', 'running']

def parse(text):                      # "1RB1LB_1LA1RZ": per state, the rule for 0, then for 1
    tab = []
    for part in text.split('_'):
        for c in (part[0:3], part[3:6]):
            tab.append(None if c == '---' else (int(c[0]), 1 if c[1] == 'R' else -1, -1 if c[2] == 'Z' else ord(c[2]) - 65))
    return tab

def show(tab):                        # the same text form back; Z is halt, --- a rule never needed
    cells = ['---' if x is None else str(x[0]) + 'LR'[x[1] > 0] + ('Z' if x[2] < 0 else chr(65 + x[2])) for x in tab]
    return '_'.join(cells[i] + cells[i + 1] for i in range(0, len(cells), 2))

def no_exit(tab, q):                  # proof 3: from state q no halting or missing rule can be reached
    reach, todo = {q}, [q]
    while todo:
        s = todo.pop()
        for x in tab[2 * s: 2 * s + 2]:
            if x is None or x[2] < 0: return False
            if x[2] not in reach: reach.add(x[2]); todo.append(x[2])
    return True

def run(tab, cap, prove=False):       # at most cap steps: (verdict, steps, ones, rule index or state)
    tape = bytearray(2 * cap + 3); h = lo = hi = cap + 1; q = t = 0
    seen, records, path = set(), {}, [h]
    while t < cap:
        k = 2 * q + tape[h]
        if tab[k] is None: return 'undefined', t, sum(tape), k
        w, m, q2 = tab[k]; tape[h] = w; h += m; t += 1; path.append(h)
        if q2 < 0: return 'halt', t, sum(tape), k
        q = q2
        if not prove: continue
        if lo <= h <= hi:             # proof 1: the whole configuration comes back
            key = (q, h, lo, bytes(tape[lo:hi + 1]))
            if key in seen: return 'repeats', t, 0, q
            seen.add(key); continue
        side = 1 if h > hi else -1; lo, hi = min(lo, h), max(hi, h)
        for t1, p1, old in records.get((side, q), []):   # proof 2: same state at two new edges,
            d = p1 - min(path[t1:]) if side == 1 else max(path[t1:]) - p1   # same cells within reach
            a, b = (p1 - d, h - d) if side == 1 else (p1, h)
            if old[a:a + d + 1] == tape[b:b + d + 1]: return 'repeats shifted', t, 0, q
        records.setdefault((side, q), []).append((t, h, bytes(tape)))
    return ('no exit' if prove and no_exit(tab, q) else 'running'), t, sum(tape), q

def tree(n, cap):                     # road 2: rules are chosen only when a run first needs one
    tally, most, todo, broken = dict.fromkeys(KINDS, 0), [(0, ''), (0, '')], [[None] * (2 * n)], 0
    while todo:
        tab = todo.pop(); verdict, t, ones, k = run(tab, cap, True)
        if verdict != 'undefined':    # each proof is tested by a plain run twice as long
            tally[verdict] += 1; broken += verdict != 'running' and run(tab, 2 * cap)[0] != 'running'; continue
        tally['halt'] += 1            # choice 1: the missing rule writes 1, moves R and halts
        done = tab[:]; done[k] = (1, 1, -1)
        if t + 1 > most[0][0]: most[0] = (t + 1, show(done))
        if ones + 1 - k % 2 > most[1][0]: most[1] = (ones + 1 - k % 2, show(done))
        used = 1 + max([x[2] for x in tab if x] + [0])
        for q2 in range(min(used + 1, n)):    # choice 2: any rule, states named in order of use
            for w in (0, 1):
                for m in (-1, 1):
                    child = tab[:]; child[k] = (w, m, q2); todo.append(child)
    return tally, most, broken

def brute(n, cap):                    # road 1: every complete rule table, one by one
    rules = [(w, m, q) for w in (0, 1) for m in (1, -1) for q in range(-1, n)]
    tally, most, early, broken = dict.fromkeys(KINDS, 0), [0, 0], 0, 0
    for tab in itertools.product(rules, repeat=2 * n):
        verdict, t, ones, _ = run(list(tab), cap, True); tally[verdict] += 1
        if verdict == 'halt': most = [max(most[0], t), max(most[1], ones)]; early += t <= 6
        else: broken += run(list(tab), 2 * cap)[0] != 'running'
    return tally, most, early, broken

def long_run(tab, skip):              # a fixed tape of 40,000 cells, head starting in the middle
    tape = bytearray(40000); h = 20000; q = t = passes = 0
    while q >= 0:
        passes += 1; r = tape[h]; w, m, q2 = tab[2 * q + r]
        if skip and r == w == 1 and q2 == q:   # road 4: a rule that keeps its state and its 1
            j = tape.find(0, h) if m == 1 else tape.rfind(0, 0, h)   # crosses the run of 1s at once
            t += abs(j - h); h = j; continue
        tape[h] = w; h += m; q = q2; t += 1
    return t, sum(tape), passes

def tally_text(c): return ', '.join(f'{k} {c[k]}' for k in KINDS)
print('choices for one rule, 1 to 5 states:', ', '.join(str(4 * (n + 1)) for n in range(1, 6)))
print('machines with 1 to 5 states:', ', '.join(str((4 * (n + 1)) ** (2 * n)) for n in range(1, 6)))
b1, b2 = brute(1, 100), brute(2, 100)
for n, (c, most, _, broken) in ((1, b1), (2, b2)):
    print(f'every {n}-state machine, cap 100: {tally_text(c)}; most steps {most[0]}, most ones {most[1]}')
    print(f'  proofs that a plain run to step 200 contradicts: {broken}')
print(f'halting test built on BB(2) = 6: halted by step 6 {b2[2]}, halted later {b2[0]["halt"] - b2[2]}, proved never to halt {sum(b2[0][k] for k in KINDS[1:4])}')
found = {}
for n, cap in ((1, 100), (2, 100), (3, 300)):
    c, most, broken = found[n] = tree(n, cap)
    print(f'tree search, {n} state{"s" * (n > 1)}, cap {cap}: {tally_text(c)}')
    print(f'  proofs that a plain run to step {2 * cap} contradicts: {broken}')
    print(f'  most steps {most[0][0]} by {most[0][1]}; most ones {most[1][0]} by {most[1][1]}')
two = parse('1RB1LB_1LA1RZ'); tape, h, q = {}, 0, 0
for step in range(1, 7):              # the two-state champion, step by step, cells -2 to 1
    r = tape.get(h, 0); w, m, q2 = two[2 * q + r]; tape[h] = w; h += m
    cells = ' '.join(f'[{tape.get(i, 0)}]' if i == h else str(tape.get(i, 0)) for i in range(-2, 2))
    print(f'step {step}: state {"AB"[q]} reads {r}, writes {w}, moves {"LR"[m > 0]}, next {"ABZ"[q2]}; tape {cells}')
    q = q2
four = parse('1RB1LB_1LA0LC_1RZ1LD_1RD0RA'); five = parse('1RB1LC_1RC1RB_1RD0LE_1LA1LD_1RZ0LA')
v100, v4 = run(four, 100), run(four, 1000)
print(f'four-state champion, cap 100: {"still running after 100 steps" if v100[0] == "running" else v100[0]}')
print(f'four-state champion, cap 1000: {"halts" if v4[0] == "halt" else v4[0]} after {v4[1]} steps, {v4[2]} ones')
p5, s5 = long_run(five, False), long_run(five, True)
print(f'five-state champion, one step at a time: halts after {p5[0]} steps, {p5[2]} loop passes, {p5[1]} ones')
print(f'five-state champion, runs of 1s crossed at once: halts after {s5[0]} steps, {s5[2]} loop passes, {s5[1]} ones')
print(f'mistakes: cap 100 on the four-state champion says {v100[0]}; ones instead of steps {v4[2]} and {p5[1]};'
      f' halting step not counted {found[2][1][0][0] - 1}; never-halting 1RA1RA let in at cap 100: {run(parse("1RA1RA"), 100)[1]}')
print('chart, log10 BB(n):', ', '.join(f'{math.log10(x):.3f}' for x in [found[n][1][0][0] for n in (1, 2, 3)] + [v4[1], p5[0]]))
print('n^n for n = 1 to 5:', ', '.join(str(n ** n) for n in range(1, 6)))
print('chart, log10 n^n:  ', ', '.join(f'{math.log10(n ** n):.3f}' for n in range(1, 6)))
assert b1[1] == [1, 1] and b2[1] == [6, 4] and b2[0]['running'] == 0 and b2[2] == b2[0]['halt']
assert b1[3] == b2[3] == 0 and [found[n][2] for n in (1, 2, 3)] == [0, 0, 0]   # proofs against plain runs
assert [found[n][1][0][0] for n in (1, 2, 3)] == [1, 6, 21] and [found[n][1][1][0] for n in (1, 2, 3)] == [1, 4, 6]
assert found[2][0]['running'] == 0 and v100[0] == 'running' and v4[:3] == ('halt', 107, 13)
assert p5[:2] == s5[:2] == (47176870, 4098) and s5[2] < p5[2]     # published 2024 value, two roads
assert [sum(b[0].values()) for b in (b1, b2)] == [(4 * (n + 1)) ** (2 * n) for n in (1, 2)]   # every table run
assert [b2[0][k] for k in KINDS] == [9784, 430, 10510, 12, 0] and found[3][0]['running'] == 110   # card's tallies
print('ALL CHECKS PASS')
