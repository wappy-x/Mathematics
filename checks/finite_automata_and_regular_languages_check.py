# Finite automata -- the check behind the card.  Nothing is imported.
# A coin machine reads 5p, 10p and 20p coins and accepts exactly 30p.  Its
# language is found three ways: running the machine, adding up each coin
# sequence, and a counting recurrence.  Then a product machine, a complement,
# and a bracket checker with fixed memory that the pigeonhole argument fools.
COINS, TARGET, OVER, DEPTH = [5, 10, 20], 30, -1, 3       # DEPTH: the bracket machine's limit
STATES = list(range(0, TARGET + 1, 5)) + [OVER]

def name(q):
    return "over" if q == OVER else str(q)

def step(q, a):                          # the rule delta(q, a): one coin, one move
    return OVER if q == OVER or q + a > TARGET else q + a

def run(w):                              # feed the coins one at a time, keep the trail
    trail = [0]
    for a in w:
        trail.append(step(trail[-1], a))
    return trail

def strings(alphabet, n):                # every string of length n, in a fixed order
    out = [[]]
    for _ in range(n):
        out = [w + [a] for w in out for a in alphabet]
    return out

def upto(alphabet, n):
    return [w for k in range(n + 1) for w in strings(alphabet, k)]

def text(w):
    return " ".join(str(a) for a in w)

bits = (len(STATES) - 1).bit_length()
print(f"coin machine: alphabet {COINS}; states {' '.join(name(q) for q in STATES)}; start 0; accept {TARGET}")
print(f"{len(STATES)} states fit in {bits} bits, however many coins arrive")
print("state: after 5, after 10, after 20")
for q in STATES:
    print(f"  {name(q)}: {', '.join(name(step(q, a)) for a in COINS)}")
for w in ([10, 5, 5, 10], [20, 5, 10], [10, 10]):
    t = run(w)
    verdict = "accept" if t[-1] == TARGET else "reject"
    print(f"run {text(w)}: {' -> '.join(name(q) for q in t)}, {len(w)} steps, {verdict}")

ALL = upto(COINS, 8)
by_machine = [w for w in ALL if run(w)[-1] == TARGET]          # road one: the machine
by_sum = [w for w in ALL if sum(w) == TARGET]                   # road two: add the coins
c = [1]                                                         # road three: in 5p units,
for k in range(1, TARGET // 5 + 1):                             # last coin 5p, 10p or 20p
    c.append(sum(c[k - d] for d in (1, 2, 4) if k - d >= 0))
print(f"coin sequences of 0 to 8 coins checked: {len(ALL)}")
print(f"accepted by the machine: {len(by_machine)}; by adding the coins: {len(by_sum)}")
print(f"recurrence c(k) = c(k-1) + c(k-2) + c(k-4), k in 5p units: {' '.join(str(x) for x in c)}")
for n in range(1, 9):
    found = [text(w) for w in by_machine if len(w) == n]
    if found:
        print(f"  {n} coins ({len(found)}): {' | '.join(found)}")
longest = max(len(w) for w in by_machine)
print(f"longest accepted: {longest} coins; any {longest + 1} coins make at least {5 * (longest + 1)}p")

def count_step(k, a):                    # machine B: how many coins, 0 1 2 3 or 4+
    return min(k + 1, 4)

pairs, todo = {(0, 0)}, [(0, 0)]          # product machine: run both side by side
while todo:
    q, k = todo.pop()
    for a in COINS:
        nxt = (step(q, a), count_step(k, a))
        if nxt not in pairs:
            pairs.add(nxt)
            todo.append(nxt)

def product_accepts(w):
    q, k = 0, 0
    for a in w:
        q, k = step(q, a), count_step(k, a)
    return q == TARGET and k <= 3

both = [w for w in ALL if product_accepts(w)]
both_brute = [w for w in by_sum if len(w) <= 3]
either = [w for w in ALL if w in by_sum or len(w) <= 3]
print(f"product machine, exactly {TARGET}p AND at most 3 coins: {len(STATES)} x 5 = {len(STATES) * 5} pairs, {len(pairs)} reachable")
print(f"  accepted by the product: {len(both)}; by brute force: {len(both_brute)}: {' | '.join(text(w) for w in both)}")
six = upto(COINS, 6)
flipped = [w for w in six if run(w)[-1] != TARGET]
partial = [w for w in six if OVER not in run(w) and run(w)[-1] != TARGET]
print(f"complement on 0 to 6 coins: {len(six)} strings - {len(by_machine)} = {len(flipped)} accepted after swapping accept states")
print(f"mistake 1, swap accept states with no over state: accepts {len(partial)}, not {len(flipped)}")
print(f"mistake 2, accept if either test passes: {len(either)} accepted on 0 to 8 coins, not {len(both)}")
print(f"empty string: in the complement {'yes' if [] in flipped else 'no'}; left out, the complement counts {len([w for w in flipped if w])}, not {len(flipped)}")

def bracket_dfa(w, depth):               # fixed memory: open count 0..depth, else dead (OVER)
    q = 0
    for s in w:
        if q == OVER:
            break
        q = q + 1 if s == "(" else q - 1
        if q < 0 or q > depth:
            q = OVER
    return q

def depth(w):                            # deepest nesting, read off prefix counts
    return max(w[:t].count("(") - w[:t].count(")") for t in range(len(w) + 1))

def counter_ok(w):                       # unbounded memory: an integer counter
    d = 0
    for s in w:
        d += 1 if s == "(" else -1
        if d < 0:
            return False
    return d == 0

B = ["".join(w) for w in upto(["(", ")"], 8)]
good = [w for w in B if counter_ok(w)]
dfa = [w for w in B if bracket_dfa(w, DEPTH) == 0]
wrong = [w for w in B if counter_ok(w) != (bracket_dfa(w, DEPTH) == 0)]
print(f"brackets, 0 to 8 symbols: {len(B)} strings; balanced by the counter: {len(good)}; "
      f"depth-{DEPTH} machine accepts {len(dfa)}")
print(f"mistake 3, depth-{DEPTH} machine ({DEPTH + 2} states) wrong on {len(wrong)}: {' '.join(wrong)}")
seen = [bracket_dfa("(" * i, DEPTH) for i in range(DEPTH + 3)]
i, j = next((a, b) for b in range(DEPTH + 3) for a in range(b) if seen[a] == seen[b])
print(f"pigeonhole: after 0 to {DEPTH + 2} opens the states are {' '.join('dead' if q == OVER else str(q) for q in seen)}; "
      f"first repeat at {i} and {j} opens")
x, y = "(" * i + ")" * i, "(" * j + ")" * i
for w in (x, y):
    print(f"  {w}: balanced {'yes' if counter_ok(w) else 'no'}, machine {'accept' if bracket_dfa(w, DEPTH) == 0 else 'reject'}")
cat = [1]                                                       # Catalan numbers, by their
for n in range(4):                                              # own recurrence
    cat.append(sum(cat[t] * cat[n - t] for t in range(n + 1)))
assert by_machine == by_sum                                     # road one against road two
assert len(by_sum) == c[-1]                                     # road two against road three
assert both == both_brute                                       # product against brute force
assert pairs == {(run(w)[-1], min(len(w), 4)) for w in ALL}     # reachable pairs, by brute force
assert len(flipped) + len([w for w in by_sum if len(w) <= 6]) == len(six)
assert len(partial) == sum(c[:-1])                              # totals 0p to 25p, counted
assert [] in flipped and [] not in by_machine                   # no coins: the complement accepts
assert len(good) == sum(cat)                                    # counter against Catalan
assert wrong == [w for w in good if depth(w) > DEPTH]           # wrong exactly when too deep
assert bracket_dfa(y, DEPTH) == bracket_dfa(x, DEPTH)                   # same state, same answer,
assert counter_ok(x) != counter_ok(y)                           # but only one is balanced
print("ALL CHECKS PASS")
