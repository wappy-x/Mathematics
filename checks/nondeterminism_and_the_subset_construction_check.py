# Guessing machines -- the check behind the card.  Nothing is imported.
# A guessing machine (NFA) watches a payment log for "cash" or "card".  The
# subset construction turns it into an ordinary machine (DFA) whose states are
# sets of guessing-machine states.  Three roads must agree on every string:
# the DFA, a search that tries every guess in turn, and a written-out scan.
SIGMA = "abcdefghijklmnopqrstuvwxyz0123456789 .:"      # 39 symbols in the log
NAMES = ["S", "A0", "A1", "A2", "A3", "A4", "B0", "B1", "B2", "B3", "B4"]
EPS = ""                                               # the label of an epsilon-move

def payment_nfa():                       # S, then A watches for cash, B for card
    d = {}
    def add(p, a, q):
        d.setdefault((p, a), set()).add(q)
    for q in (1, 6):
        add(0, EPS, q)                       # S guesses: run A and B, both at once
    for base, word in ((1, "cash"), (6, "card")):
        for a in SIGMA:
            add(base, a, base)                         # not started yet: wait
            add(base + 4, a, base + 4)                 # word seen: stay happy
        for i, ch in enumerate(word):
            add(base + i, ch, base + i + 1)            # one more letter matched
    return d, 0, {5, 10}

def closure(d, states):                  # add everything epsilon-moves reach
    seen, todo = set(states), list(states)
    while todo:
        for q in d.get((todo.pop(), EPS), ()):
            if q not in seen:
                seen.add(q)
                todo.append(q)
    return frozenset(seen)

def step(d, states, a):
    return closure(d, {q for p in states for q in d.get((p, a), ())})

def subset_construction(d, start, alphabet):          # road one
    first = closure(d, {start})
    table, seen, todo = {}, {first}, [first]
    while todo:
        T = todo.pop()
        for a in alphabet:
            U = step(d, T, a)
            table[(T, a)] = U
            if U not in seen:
                seen.add(U)
                todo.append(U)
    return first, table

def run(first, table, w):                # follow the DFA table, one symbol a step
    T = first
    for a in w:
        T = table[(T, a)]
    return T

def dfa_accepts(first, table, accept, w):
    return bool(run(first, table, w) & accept)

def guess_accepts(d, accept, p, w, i=0):              # road two: try every guess
    if i == len(w) and p in accept:
        return True
    if any(guess_accepts(d, accept, q, w, i) for q in d.get((p, EPS), ())):
        return True
    return i < len(w) and any(guess_accepts(d, accept, q, w, i + 1)
                              for q in d.get((p, w[i]), ()))

def contains(w, word):                                # road three: plain scan
    return any(all(w[s + j] == word[j] for j in range(len(word))) for s in range(len(w) - len(word) + 1))

def naive(w):                            # the usual mistake: reset on a mismatch
    for word in ("cash", "card"):
        k = 0
        for a in w:
            k = k + 1 if a == word[k] else 0
            if k == len(word):
                return True
    return False

def show(T): return "{" + " ".join(NAMES[q] for q in sorted(T)) + "}"
def yn(b): return "yes" if b else "no"

d, s, F = payment_nfa()
first, table = subset_construction(d, s, SIGMA)
reached = sorted({T for (T, a) in table}, key=lambda T: sorted(T))
happy = [T for T in reached if T & F]
print(f"guessing machine: {len(NAMES)} states, {len(SIGMA)} symbols, {2 ** len(NAMES)} possible sets")
print(f"subset construction reaches {len(reached)} sets, {len(happy)} of them accepting; "
      f"table {len(reached)} x {len(SIGMA)} = {len(reached) * len(SIGMA)} entries")
for T in reached:
    print(f"  set {show(T)}{' accept' if T & F else ''}")
kinds = sorted({show(T - {1, 5, 6, 10}) for T in reached if 0 not in T})   # drop A0, A4, B0, B4
print(f"after the start set, partial matches beside A0 B0 A4 B4: {len(kinds)} kinds, {' '.join(kinds)}")
w, T = "paid ccard", first
print(f"trace of '{w}': start {show(T)}")
for a in w:
    T = table[(T, a)]
    print(f"  read '{a}' -> {show(T)}")
logs = ["09:14 latte 3.20 card", "09:20 cashback 5.00", "09:31 cart refund 2.80",
        "09:40 paid ccard 4.10", "09:52 voucher 1.50"]
verdicts = []
for line in logs:
    v = [dfa_accepts(first, table, F, line), guess_accepts(d, F, s, line),
         contains(line, "cash") or contains(line, "card"), naive(line)]
    verdicts.append(v)
    print(f"log '{line}': dfa {yn(v[0])}, guesses {yn(v[1])}, scan {yn(v[2])}, reset-scan {yn(v[3])}")
small, words = "cashrdx", [""]                    # x stands for every other symbol
for n in range(6):
    words += [u + a for u in words if len(u) == n for a in small]
agree = sum(dfa_accepts(first, table, F, u) == guess_accepts(d, F, s, u)
            == (contains(u, "cash") or contains(u, "card")) for u in words)
naive_wrong = sum(naive(u) != dfa_accepts(first, table, F, u) for u in words)
print(f"all {len(words)} strings over '{small}' up to length 6: three roads agree on {agree}; "
      f"the reset-scan disagrees on {naive_wrong}")
T = frozenset({s})                               # two more mistakes, on the card line
for a in logs[0]:
    T = step(d, T, a)
no_closure, all_must = bool(T & F), run(first, table, logs[0]) <= F
print(f"mistakes on '{logs[0]}': start without epsilon-moves {yn(no_closure)}, "
      f"every guess must accept {yn(all_must)}")
growth = []
for k in range(1, 11):                   # "the k-th symbol from the end is c"
    dk = {(i, a): {0} if i == 0 else {i + 1} for i in range(k) for a in "cx"}   # 0 waits, 1.. count
    dk[(0, "c")] = {0, 1}                                     # at a c, guess "this is the one"
    fk, tk = subset_construction(dk, 0, "cx")
    growth.append(len({T for (T, a) in tk}))
    if k == 3:                           # where the 8 strings of length 3 end up
        ends = {run(fk, tk, a + b + c) for a in "cx" for b in "cx" for c in "cx"}
        pair = ["accept" if dfa_accepts(fk, tk, {3}, u) else "reject" for u in ("ccxx", "cxxx")]
    print(f"k = {k:2}: guessing machine {k + 1:2} states, subset machine {growth[-1]:4} states")
assert agree == len(words) == 137257                          # three roads, every string
assert [v[0] for v in verdicts] == [True, True, False, True, False]
assert all(v[0] == v[1] == v[2] for v in verdicts) and not verdicts[3][3]
assert growth == [2 ** k for k in range(1, 11)]               # the blow-up is real
assert len(reached) == 1 + 5 * 2 * 2 and len(happy) == 5 * 3 and naive_wrong > 0   # the count by hand
assert step({(0, "c"): {1}, (1, EPS): {2}}, {0}, "c") == {1, 2}   # epsilon after a symbol: closure needed
print(f"k = 3: the 8 strings of length 3 end in {len(ends)} different sets; with 4 states two share one, "
      f"such as ccx and cxx, yet the ending x needs ccxx {pair[0]}, cxxx {pair[1]}")
assert not no_closure and not all_must and len(ends) == 8 and pair == ["accept", "reject"]   # each piece is needed
print("ALL CHECKS PASS")
