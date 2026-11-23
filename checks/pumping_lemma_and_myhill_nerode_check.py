# Pumping and Myhill-Nerode -- the check behind the card.  Nothing is imported.
# Language: bracket strings that never close more than they opened, end at depth
# 0 and never nest past a cap.  The reference is a plain counter; machines,
# pumping splits and class counts are each checked against it.
F3 = "=IF(A1>0,SUM((B1+C1)*(D1-E1)),0)"
F4 = "=ROUND(IF(A1>0,SUM((B1+C1)*(D1-E1)),0),2)"
BIG = 10**6                                   # a cap no test string reaches

def brackets(formula):
    return "".join(c for c in formula if c in "()")

def balanced(w, cap):                         # the reference: one counter
    depth = 0
    for c in w:
        depth += 1 if c == "(" else -1
        if depth < 0 or depth > cap:
            return False
    return depth == 0

def words(n, letters="()"):                   # every string, length 0..n
    out, layer = [""], [""]
    for _ in range(n):
        layer = [w + c for w in layer for c in letters]
        out += layer
    return out

def draft(cap):           # first draft: remembers the depth AND the last bracket
    start, delta, states, todo = (0, ""), {}, [(0, ""), "dead"], [(0, ""), "dead"]
    while todo:
        s = todo.pop()
        for c in "()":
            d = BIG if s == "dead" else s[0] + (1 if c == "(" else -1)
            t = (d, c) if 0 <= d <= cap else "dead"
            delta[s, c] = t
            if t not in states:
                states.append(t)
                todo.append(t)
    return states, start, [s for s in states if s != "dead" and s[0] == 0], delta

def counter_machine(cap):        # the small machine: states 0..cap, then "dead"
    delta = {}
    for s in list(range(cap + 1)) + ["dead"]:
        for c in "()":
            d = BIG if s == "dead" else s + (1 if c == "(" else -1)
            delta[s, c] = d if 0 <= d <= cap else "dead"
    return list(range(cap + 1)) + ["dead"], 0, [0], delta

def run(machine, w):
    states, s, accept, delta = machine
    for c in w:
        s = delta[s, c]
    return s in accept

def minimise(machine):           # Moore: split blocks until no letter splits one
    states, _, accept, delta = machine
    label = {s: int(s in accept) for s in states}
    sizes = [len(set(label.values()))]
    while True:
        sig = {s: (label[s], label[delta[s, "("]], label[delta[s, ")"]]) for s in states}
        keys = sorted(set(sig.values()))
        sizes.append(len(keys))
        if len(keys) == sizes[-2]:
            return len(keys), sizes
        label = {s: keys.index(sig[s]) for s in states}

def classes(cap, n):             # Myhill-Nerode by brute force: distinct futures
    tails = words(n)
    return len({tuple(balanced(x + z, cap) for z in tails) for x in words(n)})

def abc(w):                      # a^i b^j c^k with i = 0 or j = k
    i = j = k = 0
    for c in w:
        if c == "a" and j == k == 0: i += 1
        elif c == "b" and k == 0: j += 1
        elif c == "c": k += 1
        else: return False
    return i == 0 or j == k

def show(w): return w if w else "empty"
def yn(claim): return "yes" if claim else "no"

# ---- depth at most 3: the formula, the 5-state machine and the draft ----
m3, d3 = counter_machine(3), draft(3)
agree = all(balanced(w, 3) == run(m3, w) == run(d3, w) for w in words(12))
n_min, sizes = minimise(d3)
print(f"formula {F3} -> brackets {brackets(F3)}, length {len(brackets(F3))}, deepest 3")
print(f"counter, 5-state machine, {len(d3[0])}-state draft agree on all {len(words(12))} strings to length 12: {yn(agree)}")
print(f"Moore refinement of the draft, blocks after each round: {', '.join(map(str, sizes))}")
print(f"smallest machine: {n_min} states; Myhill-Nerode classes (strings to length 8): {classes(3, 8)}")
reps, pairs = ["", "(", "((", "(((", ")"], []
for a in range(5):
    for b in range(a + 1, 5):
        z = next(z for z in words(6) if balanced(reps[a] + z, 3) != balanced(reps[b] + z, 3))
        pairs.append((a, b, z))
        print(f"  {show(reps[a])} vs {show(reps[b])}: told apart by z = {show(z)}")
cert = all(run(m3, reps[a] + z) != run(m3, reps[b] + z) for a, b, z in pairs)
print(f"  {len(pairs)} pairs, each also told apart by the 5-state machine: {yn(cert)}")
for cap in [1, 2, 3, 4, 5, 6, 64]:
    print(f"cap {cap}: draft {len(draft(cap)[0])} states, smallest {minimise(draft(cap))[0]} states")
# ---- the pigeonhole inside the pumping lemma, run on the 5-state machine ----
w, trace = brackets(F3), [0]
for c in w:
    trace.append(m3[3][trace[-1], c])
first = next((a, b) for b in range(6) for a in range(b) if trace[a] == trace[b])
x, y, z = w[:first[0]], w[first[0]:first[1]], w[first[1]:]
pumped = [x + y * i + z for i in range(4)]
print(f"run on {w}: states {', '.join(map(str, trace))}; state {trace[first[0]]} after {first[0]} and {first[1]} letters, inside the first 6 states")
print(f"x = {x}, y = {y}, z = {z}; pumped i = 0..3: {', '.join(pumped)}")
print(f"all pumped words accepted: {yn(all(run(m3, v) for v in pumped))}")
# ---- unbounded brackets: pumping refuted, classes without end ----
fails = {}
for p in range(1, 13):
    w = "(" * p + ")" * p
    splits = [(j, k) for k in range(1, p + 1) for j in range(p - k + 1)]
    fails[p] = (len(splits), sum(not balanced(w[:j] + w[j + k:], BIG) for j, k in splits))
print(f"w = (^5)^5: splits with |xy| <= 5, |y| >= 1: {fails[5][0]}; failing at i = 0: {fails[5][1]}")
print(f"every split fails, for every p from 1 to 12: {yn(all(a == b for a, b in fails.values()))}")
told = all(balanced("(" * j + ")" * j, BIG) and not balanced("(" * k + ")" * j, BIG)
           for j in range(7) for k in range(7) if j != k)
grow = [classes(BIG, n) for n in (2, 4, 6, 8)]
print(f"(^0 .. (^6: all 21 pairs told apart by )^j: {yn(told)}")
print(f"classes seen with strings to length n = 2, 4, 6, 8: {', '.join(map(str, grow))}")
# ---- what breaks ----
b4 = brackets(F4)
print(f"depth-3 machine on {F4} = {b4}: counter {yn(balanced(b4, BIG))}, machine {yn(run(m3, b4))}")
mid = ["((((" + "()" * i + "))))" for i in range(5)]
print(f"y = () from the middle of (^5)^5, i = 0..4: {sum(balanced(v, BIG) for v in mid)} of 5 balanced, no contradiction")
in_l = [w for w in words(7, "abc") if abc(w) and w]
pumps = all(abc(w[0] * i + w[1:]) for w in in_l for i in range(5))
ab = ["a" + "b" * j for j in range(6)]
apart = all(abc(ab[j] + "c" * j) and not abc(ab[k] + "c" * j) for j in range(6) for k in range(6) if j != k)
print(f"a^i b^j c^k, i = 0 or j = k: all {len(in_l)} words to length 7 pump with p = 1: {yn(pumps)}")
print(f"  yet a, ab, .., ab^5 are pairwise told apart by c^j: {yn(apart)}")
print(f"draft read as the minimum: {len(d3[0])} states, true minimum {n_min}")
assert agree and n_min == 5 and classes(3, 8) == 5          # three roads to 5 states
assert cert and all(minimise(draft(c))[0] == c + 2 for c in [1, 2, 3, 4, 5, 6, 64])
assert all(a == b for a, b in fails.values()) and told      # brackets are not regular
assert grow == [4, 6, 8, 10] and fails[5] == (15, 15)
assert balanced(b4, BIG) and not run(m3, b4) and pumps and apart
print("ALL CHECKS PASS")
