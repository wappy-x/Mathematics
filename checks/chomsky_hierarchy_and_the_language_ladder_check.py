# The language ladder -- the check behind the card.  Standard library only.
# Four patterns over a and b, one per rung; each machine meets its definition and a generated list.
from itertools import product
def strings(n): return [''.join(p) for p in product('ab', repeat=n)]
# rung 3, fixed memory: A = only a's so far, B = b's have started, D = dead
DFA = {('A', 'a'): 'A', ('A', 'b'): 'B', ('B', 'a'): 'D', ('B', 'b'): 'B', ('D', 'a'): 'D', ('D', 'b'): 'D'}
def dfa(w):
    q = 'A'
    for c in w: q = DFA[(q, c)]
    return q != 'D'
# rung 2, one stack: push for each a, pop for each b, never an a after a b
def stack_run(w):
    st, seen_b, high = [], False, 0
    for c in w:
        if c == 'a' and seen_b: return False, high
        if c == 'a': st.append('a'); high = max(high, len(st))
        elif not st: return False, high
        else: seen_b = True; st.pop()
    return not st, high

# rung 1, a tape no longer than the input: the Turing machines card's simulator, cut down (no cap or trace; rows may
# share a line, split at ';'), with one rule added: the head may read the blank past each end but never write or go on.
def table(text): return {(s, r): (w, m, n) for s, r, w, m, n in (l.split() for l in text.replace('\n', ';').split(';') if l.strip())}
def run_tm(rules, word, state):
    tape, head, steps, used = dict(enumerate(word)), 0, 0, set()
    while (state, tape.get(head, '_')) in rules:
        write, move, state = rules[(state, tape.get(head, '_'))]
        assert (0 <= head < len(word) or write == '_') and -1 <= head + (1 if move == 'R' else -1) <= len(word)
        if write != '_': used.add(head)
        tape[head] = write; head += 1 if move == 'R' else -1; steps += 1
    return state == 'accept', steps, len(used)  # stopping in any state but accept means no
# Mark the ends inward to find the middle, then carry each second-half letter back to its partner (Y carried, X matched).
WW = table("""mark a A R right; mark b B R right; mark A Y L carrya; mark B Y L carryb; mark _ _ L accept
right a a R right; right b b R right; right A A L end; right B B L end; right _ _ L end
end a A L left; end b B L left; left a a L left; left b b L left; left A A R mark; left B B R mark
carrya Y Y L carrya; carrya A A L carrya; carrya B B L carrya; carrya X X R isa; carrya _ _ R isa
carryb Y Y L carryb; carryb A A L carryb; carryb B B L carryb; carryb X X R isb; carryb _ _ R isb
isa A X R fwd; isb B X R fwd; fwd A A R fwd; fwd B B R fwd; fwd Y Y R next; next Y Y R next; next A Y L carrya; next B Y L carryb; next _ _ L accept""")
# the plain definitions, and each language generated rather than tested
DEF = {'a*b*': lambda w: 'ba' not in w,
       'a^n b^n': lambda w: w == 'a' * (len(w) // 2) + 'b' * (len(w) // 2),
       'ww': lambda w: w[:len(w) // 2] == w[len(w) // 2:]}
def generate(name, n):
    if name == 'a*b*': return {'a' * i + 'b' * (n - i) for i in range(n + 1)}
    if name == 'a^n b^n':  # grammar S -> aSb | empty, applied n/2 times
        s = ''
        for _ in range(n // 2): s = 'a' + s + 'b'
        return {s} if n % 2 == 0 else set()
    return {u + u for u in strings(n // 2)} if n % 2 == 0 else set()
MACHINE = {'a*b*': dfa, 'a^n b^n': lambda w: stack_run(w)[0], 'ww': lambda w: run_tm(WW, w, 'mark')[0]}
for name in MACHINE:
    checked = 0
    for n in range(13):
        acc = {w for w in strings(n) if MACHINE[name](w)}
        assert acc == {w for w in strings(n) if DEF[name](w)} == generate(name, n), name
        checked += 2 ** n
    print(f"agree {name:<8} machine = definition = generated on {checked} strings, lengths 0 to 12")
print("of 4096 strings of length 12:", ", ".join(f"{k} {len(generate(k, 12))}" for k in MACHINE))
print("stack on aaaaabbbbb: accept", stack_run('aaaaabbbbb')[0], " highest stack", stack_run('aaaaabbbbb')[1])
yes = [w for n in range(13) for w in generate('ww', n)]; fit = sum(run_tm(WW, w, 'mark')[1] == len(w) ** 2 + 3 * len(w) + 1 for w in yes)
acc, k, cells = run_tm(WW, 'abbaabba', 'mark'); assert (acc, k, cells) == (True, 8 ** 2 + 3 * 8 + 1, len('abbaabba')) and fit == len(yes)
print(f"tape on abbaabba: accept {acc}  rows {len(WW)}, cells written {cells}, steps {k}; steps = |w|^2 + 3|w| + 1 on {fit} of {len(yes)} accepted")

# memory needed: how many length-k beginnings must be told apart (endings up to k letters)
def classes(name, k):
    ends = [e for m in range(k + 1) for e in strings(m)]
    return len({tuple(DEF[name](p + e) for e in ends) for p in strings(k)})
for k in (2, 4, 6, 8, 10):
    c = [classes(nm, k) for nm in MACHINE]
    assert c == [3, k // 2 + 2, 2 ** k], c
    print(f"classes after {k:>2} letters: a*b* {c[0]:>4}  a^n b^n {c[1]:>4}  ww {c[2]:>5}")

# ww is not context-free: pump s = a^p b^p a^p b^p at every split u v x y z
for p in range(1, 5):
    s, splits, survive = 'a' * p + 'b' * p + 'a' * p + 'b' * p, 0, 0
    for i in range(len(s)):
        for lv in range(p + 1):
            for lx in range(p + 1 - lv):
                for ly in range(p + 1 - lv - lx):
                    if lv + ly == 0 or i + lv + lx + ly > len(s): continue
                    u, v, x = s[:i], s[i:i + lv], s[i + lv:i + lv + lx]
                    y, z = s[i + lv + lx:i + lv + lx + ly], s[i + lv + lx + ly:]
                    splits += 1
                    survive += all(DEF['ww'](u + v * t + x + y * t + z) for t in range(4))
    assert survive == 0, p
    print(f"pump ww, p = {p}: {s} has {splits} splits, {survive} survive pumping")

# rung 0, this card's own small encoding: states 1 to k, 0 halts.  Header a^k b, then 2k rules in order
# (state 1 reads 0, state 1 reads 1, ...): write a/b = 0/1, move a/b = L/R, next a^j b (j = 0 halts)
def encode(M):
    return 'a' * (len(M) // 2) + 'b' + ''.join('ab'[w] + 'ab'[m == 'R'] + 'a' * nx + 'b' for w, m, nx in M)
def decode(c):
    k = c.index('b'); i, M = k + 1, []
    for _ in range(2 * k):
        j = c.index('b', i + 2)
        M.append(('ab'.index(c[i]), 'LR'['ab'.index(c[i + 1])], j - i - 2)); i = j + 1
    return M
def run(M, cap):
    tape, pos, q = {}, 0, 1
    for step in range(1, cap + 1):
        w, m, nx = M[2 * (q - 1) + tape.get(pos, 0)]
        tape[pos] = w; pos += 1 if m == 'R' else -1; q = nx
        if q == 0: return step, sum(tape.values())
    return None, None

RULES = [(w, m, nx) for w in (0, 1) for m in 'LR' for nx in (0, 1, 2)]
machines = [list(M) for M in product(RULES, repeat=4)]
assert all(decode(encode(M)) == M for M in machines)
res = {cap: [run(M, cap)[0] for M in machines] for cap in (5, 6, 100)}
halt = [s for s in res[100] if s is not None]
champ = [(1, 'R', 2), (1, 'L', 2), (1, 'L', 1), (1, 'R', 0)]
print(f"2-state machines {len(machines)} = {len(RULES)}^4: halt within 100 steps {len(halt)}, longest {max(halt)}, still running {len(machines) - len(halt)}")
print("champion", encode(champ), "halts at step", run(champ, 100)[0], "with ones", run(champ, 100)[1])
assert max(halt) == 6 and run(champ, 100) == (6, 4)
print("tape-bounded configurations q |w| g^|w|, q = 10, |w| = 20, g = 4:", 10 * 20 * 4 ** 20)

# what breaks
def depth3(w):  # fixed memory sized for nesting 3: a count of a's up to 3, then of b's, plus dead
    a = b = 0
    for c in w:
        if c == 'a' and (b or a == 3): return False
        if c == 'a': a += 1
        else: b += 1
    return a == b
def stack_ww(w):  # push the first half, pop against the second: tests w then w reversed
    h = len(w) // 2
    return len(w) % 2 == 0 and w[:h][::-1] == w[h:]
miss3 = [w for n in range(13) for w in strings(n) if depth3(w) != DEF['a^n b^n'](w)]
wrong = [w for n in range(0, 13, 2) for w in strings(n) if stack_ww(w) != DEF['ww'](w)]
assert miss3 == ['aaaabbbb', 'aaaaabbbbb', 'aaaaaabbbbbb'] and 'abab' in wrong and 'abba' in wrong
E8 = [e for m in range(9) for e in strings(m)]; st3 = len({tuple(depth3(p + e) for e in E8) for p in E8}); assert st3 == 4 + 3 + 1
def bal3(w): return all(0 <= w[:i].count('a') - w[:i].count('b') <= 3 for i in range(len(w) + 1)) and w.count('a') == w.count('b')
st5 = len({tuple(bal3(p + e) for e in E8) for p in E8}); assert st5 == 4 + 1  # all brackets to depth 3: depth 0..3, then dead
print(f"break: depth-3 checker ({st3} states; {st5} for all brackets to depth 3) misses", len(miss3), "strings up to 12 letters, first", miss3[0])
print("break: stack used for ww wrong on", len(wrong), "even strings up to 12; abab says", stack_ww('abab'), "abba says", stack_ww('abba'))
print("break: cap 5 misses", sum(1 for a, b in zip(res[5], res[100]) if a != b),
      "halting machines; champion at cap 5:", "still running after 5 steps" if run(champ, 5)[0] is None else "halts",
      "| try: cap 6 misses", sum(1 for a, b in zip(res[6], res[100]) if a != b))
print("figure, boxes x y w h:", "; ".join(f"{10 + 30 * i} {10 + 50 * i} {620 - 60 * i} {380 - 80 * i}" for i in range(4)))
print("ALL CHECKS PASS")
