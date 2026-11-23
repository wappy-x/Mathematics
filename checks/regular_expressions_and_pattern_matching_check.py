# Regular expressions -- the check behind the card.  Nothing is imported: no re.  A postcode
# shape is a pattern over L (capital letter), D (digit) and _ (space).  It is compiled into a
# machine (Thompson), run, made guess-free (subset construction) and read back (elimination).
EPS = ('eps',)
def sym(c): return ('sym', c)
def cat(a, b): return None if a is None or b is None else b if a == EPS else a if b == EPS else ('cat', a, b)
def alt(a, b): return b if a is None else a if b is None or a == b else ('alt', a, b)
def star(a): return EPS if a in (None, EPS) else a if a[0] == 'star' else ('star', a)
def seq(*rs): return EPS if not rs else cat(rs[0], seq(*rs[1:]))   # None means "no route at all"
def show(r, p=0):                     # write a pattern out, brackets only where needed
    k = r[0]
    if k in ('eps', 'sym'): return 'ε' if k == 'eps' else r[1]
    if k == 'star': return show(r[1], 3) + '*'
    s = show(r[1], 2) + show(r[2], 2) if k == 'cat' else show(r[1], 1) + '|' + show(r[2], 1)
    return '(' + s + ')' if (k == 'cat' and p > 2) or (k == 'alt' and p > 1) else s
def pieces(r): return (r[0] != 'cat') + sum(pieces(x) for x in r[1:] if isinstance(x, tuple))  # all but joins
def thompson(r, m):                   # m = [states used, arrows]; returns (entry, exit)
    k = r[0]
    if k == 'cat':                    # joining: exit of the first -> entry of the second
        a, b = thompson(r[1], m), thompson(r[2], m)
        m[1].append((a[1], None, b[0]))
        return a[0], b[1]
    s, e = m[0], m[0] + 1; m[0] += 2  # every other piece gets a new entry s and exit e
    if k in ('eps', 'sym'): m[1].append((s, r[1] if k == 'sym' else None, e))
    elif k == 'alt':
        a, b = thompson(r[1], m), thompson(r[2], m)
        m[1] += [(s, None, a[0]), (s, None, b[0]), (a[1], None, e), (b[1], None, e)]
    else:                             # star: skip it, or go round again
        a = thompson(r[1], m)
        m[1] += [(s, None, a[0]), (s, None, e), (a[1], None, a[0]), (a[1], None, e)]
    return s, e
def compile_nfa(r):                   # the machine: (state count, arrows, entry, exit)
    m = [0, []]
    s, e = thompson(r, m)
    return m[0], m[1], s, e
def close(states, arrows):            # add every state reachable by free moves
    out, todo = set(states), list(states)
    while todo:
        q = todo.pop()
        new = {b for a, c, b in arrows if a == q and c is None} - out
        out |= new; todo += new
    return frozenset(out)
def step(states, c, arrows): return close({b for a, x, b in arrows if a in states and x == c}, arrows)
def nfa_accepts(nfa, w, trace=None):  # run every guess at once: keep the set of live states
    cur = close({nfa[2]}, nfa[1])
    for c in w:
        cur = step(cur, c, nfa[1])
        if trace is not None: trace.append(len(cur))
    return nfa[3] in cur
def search_ends(nfa, w):              # searching text: a fresh start at every position
    start = cur = close({nfa[2]}, nfa[1])
    out = []
    for i, c in enumerate(w):
        cur = step(cur, c, nfa[1]) | start
        if nfa[3] in cur: out.append(i + 1)
    return out
def subset_dfa(nfa, sigma):           # each guess-free state is a set of Thompson states
    first = close({nfa[2]}, nfa[1])
    names, delta, todo = {first: 0}, {}, [first]
    while todo:
        cur = todo.pop(0)
        for c in sigma:
            nxt = step(cur, c, nfa[1])
            if nxt:
                if nxt not in names: names[nxt] = len(names); todo.append(nxt)
                delta[(names[cur], c)] = names[nxt]
    return len(names), delta, {i for st, i in names.items() if nfa[3] in st}
def dfa_accepts(d, w, q=0):           # one state at a time; -1 means "fell off the machine"
    for c in w: q = d[1].get((q, c), -1)
    return q in d[2]
def read_back(d, keep_loop=True):     # state elimination: machine -> pattern
    n, delta, acc = d
    R = {(i, j): None for i in range(n + 2) for j in range(n + 2)}
    R[(n, 0)] = EPS                   # new start n, new finish n + 1
    for q in acc: R[(q, n + 1)] = EPS
    for (q, c), t in delta.items(): R[(q, t)] = alt(R[(q, t)], sym(c))
    for k in reversed(range(n)):      # remove state k, rerouting every path through it
        rest = [i for i in range(n + 2) if i < k or i >= n]
        loop = star(R[(k, k)]) if keep_loop else EPS
        for i in rest:
            for j in rest: R[(i, j)] = alt(R[(i, j)], seq(R[(i, k)], loop, R[(k, j)]))
    return R[(n, n + 1)]
def backtrack(r, w, i, k, cnt):       # how most regex libraries run: try, undo, retry
    cnt[0] += 1
    t = r[0]
    if t in ('eps', 'sym'): return k(i) if t == 'eps' else w[i:i + 1] == r[1] and k(i + 1)
    if t == 'cat': return backtrack(r[1], w, i, lambda j: backtrack(r[2], w, j, k, cnt), cnt)
    if t == 'alt': return backtrack(r[1], w, i, k, cnt) or backtrack(r[2], w, i, k, cnt)
    return backtrack(r[1], w, i, lambda j: j > i and backtrack(r, w, j, k, cnt), cnt) or k(i)
def matches(r, w): return backtrack(r, w, 0, lambda j: j == len(w), [0])   # reads the pattern itself
def by_words(w): return len(w) >= 5 and w[-3:] == 'DLL' and w[:-3].rstrip('_') in ('LD', 'LDD', 'LDL', 'LLD', 'LLDD', 'LLDL')  # the rule in words
def classes(text): return ''.join('L' if c.isupper() else 'D' if c.isdigit() else '_' if c == ' ' else '?' for c in text)
def strings_of(sigma, n): return [''] if n == 0 else [w + c for w in strings_of(sigma, n - 1) for c in sigma]
def yn(ok): return 'accept' if ok else 'reject'
L, D, SP = sym('L'), sym('D'), sym('_')
POST, N = seq(L, alt(L, EPS), D, alt(L, alt(D, EPS)), star(SP), D, L, L), 9
back = read_back(dfa := subset_dfa(nfa := compile_nfa(POST), 'LD_'))
print(f"pattern {show(POST)}: {pieces(POST)} pieces, so {2 * pieces(POST)} Thompson states")
print(f"Thompson machine: {nfa[0]} states, {len(nfa[1])} arrows, {sum(e[1] is None for e in nfa[1])} of them free moves")
for text in ['SW1A 1AA', 'M1 1AE', 'SW1A1AA', 'SW1A 1A']:
    ok = nfa_accepts(nfa, classes(text), tr := [])
    print(f"{text:9} reads {classes(text):9} live states after each symbol {tr}: {yn(ok)}")
print(f"guess-free machine: {dfa[0]} states, accepting {sorted(dfa[2])}")
for q in range(dfa[0]):
    print(f"  state {q}: " + (', '.join(f"{c} -> {dfa[1][(q, c)]}" for c in 'LD_' if (q, c) in dfa[1]) or 'no moves'))
print(f"read back: {show(back)}")
print(f"round trip of {show(small := seq(star(SP), D, L, L))} through a {(sd := subset_dfa(compile_nfa(small), 'LD_'))[0]}-state machine: {show(read_back(sd))}")
words = [w for n in range(N + 1) for w in strings_of('LD_', n)]
spec = [by_words(w) for w in words]
roads = {'Thompson machine': [nfa_accepts(nfa, w) for w in words], 'guess-free machine': [dfa_accepts(dfa, w) for w in words],
         'pattern read directly': [matches(POST, w) for w in words], 'pattern read back': [matches(back, w) for w in words]}
groups = [sum(s and len(w) - w.count('_') == h + 3 for w, s in zip(words, spec)) for h in (2, 3, 4)]
print(f"all {len(words)} strings of L, D, _ up to length {N}: {sum(spec)} pass the rule in words; first half 2, 3, 4 long: {groups}")
for name, got in roads.items():
    print(f"  {name:22} accepts {sum(got)}, disagrees with the rule on {sum(a != b for a, b in zip(got, spec))}")
note = 'SEND TO SW1A 1AA TODAY'
found = search_ends(nfa, classes(note))
starts = [j for j in range(found[0]) if by_words(classes(note)[j:found[0]])]
print(f"search {note!r}: a match ends at {found}; it can start at {starts}: {[note[j:found[0]] for j in starts]}")
print(f"the whole note as a postcode: {yn(nfa_accepts(nfa, classes(note)))}")
one = seq(L, alt(L, EPS), D, alt(L, alt(D, EPS)), SP, D, L, L)
print(f"mistake 1, one space in place of _*: accepts {sum(matches(one, w) for w in words)}; SW1A1AA: {yn(matches(one, 'LLDLDLL'))}")
bad = read_back(dfa, keep_loop=False)
miss = [w for w, s in zip(words, spec) if s and not matches(bad, w)]
print(f"mistake 2, elimination without the loop: accepts {sum(matches(bad, w) for w in words)}, loses {len(miss)}, e.g. {miss[0]}")
evil, cost = seq(star(seq(sym('a'), star(sym('a')))), sym('b')), []
for n in (5, 10, 15, 20):
    ok = backtrack(evil, 'a' * n, 0, lambda j: j == n, cnt := [0])
    cost.append((n, cnt[0], sum(tr) if nfa_accepts(compile_nfa(evil), 'a' * n, tr := []) == ok else -1))
    print(f"mistake 3, {show(evil)} on {n} a's: backtracking takes {cnt[0]:,} steps, the live-state run {cost[-1][2]}")
def depth(k): return EPS if k == 0 else star(seq(sym('('), depth(k - 1), sym(')')))
b3 = compile_nfa(depth(3))
print(f"mistake 4, depth-3 pattern, {b3[0]} states (depth 4 needs {compile_nfa(depth(4))[0]}): "
      f"((())) {yn(nfa_accepts(b3, '((()))'))}, (((()))) {yn(nfa_accepts(b3, '(((())))'))}")
for name, got in roads.items(): assert got == spec, name           # four roads against the rule in words
assert nfa[0] == 2 * pieces(POST) and dfa[0] == 10                  # Thompson's count, from the pattern alone
assert starts == [8, 9] and not nfa_accepts(nfa, classes(note))     # search finds it; a whole match does not
assert all(c == 3 * 2 ** (n + 1) - 1 and t == 8 * n - 1 for n, c, t in cost)  # exponential against linear
assert nfa_accepts(b3, '((()))') and not nfa_accepts(b3, '(((())))')  # fixed depth, fixed memory
print("ALL CHECKS PASS")
