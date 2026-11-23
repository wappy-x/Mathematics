# Monoids and monads -- the check behind the card.  Nothing is imported.
# Part 1 folds a basket of prices, in pence, with a monoid, and checks the
# answer three ways: left to right, every bracketing, and two tills.
# Part 2 chains lookups that may fail with the Maybe monad, checks the chain
# against plain nested ifs, and checks the monad laws on every case.
PRICES = [("tea", 249), ("milk", 120), ("coffee", 375), ("bread", 89)]
ORDERS = {"1001": "C17", "1002": "C42", "1003": "C99"}   # order -> customer
CUSTOMERS = {"C17": "LS1", "C42": "M60"}                  # customer -> postcode
ZONES = {"LS1": "Z2"}                                     # postcode -> zone
CHARGES = {"Z1": "299", "Z2": "450", "Z3": "650"}         # zone -> pence
STEPS = [ORDERS, CUSTOMERS, ZONES, CHARGES]

def fold(op, e, xs):                    # start at the identity, combine left to right
    acc = e
    for x in xs:
        acc = op(acc, x)
    return acc

def brackets(op, xs):                   # every way to put brackets on xs
    if len(xs) == 1:
        return [xs[0]]
    return [op(a, b) for k in range(1, len(xs))
            for a in brackets(op, xs[:k]) for b in brackets(op, xs[k:])]

def add(a, b): return a + b
def sub(a, b): return a - b
def big(a, b): return a if a >= b else b
def pair(a, b): return (a[0] + b[0], a[1] + b[1])        # (sum, count)

def monoid(op, e, xs):                  # the two laws on every pair and triple
    ident = all(op(e, a) == a and op(a, e) == a for a in xs)
    assoc = all(op(op(a, b), c) == op(a, op(b, c)) for a in xs for b in xs for c in xs)
    return ident and assoc

def yn(claim): return "yes" if claim else "no"

pence = [p for _, p in PRICES]
total = fold(add, 0, pence)
trees = brackets(add, pence)
till_a, till_b = fold(add, 0, pence[:3]), fold(add, 0, pence[3:])
print("basket:", ", ".join(f"{n} {p}p" for n, p in PRICES))
print(f"fold with +, from 0, left to right: {total}p = £{total // 100}.{total % 100:02d}")
print("running total:", ", ".join(str(fold(add, 0, pence[:k])) for k in range(1, 5)))
print(f"all {len(trees)} bracketings give: {sorted(set(trees))}; with one more item, "
      f"{len(brackets(add, pence + [195]))} bracketings")
print(f"two tills: {till_a} + {till_b} = {till_a + till_b}")
print(f"empty basket folds to the identity: {fold(add, 0, [])}")
sample = pence + [0, 1000]
print(f"laws hold for +, 0 on {len(sample)}^3 triples: {yn(monoid(add, 0, sample))}")
print(f"laws hold for max, 0: {yn(monoid(big, 0, sample))}; dearest item {fold(big, 0, pence)}p")
words = ["", "LS", "1", "M6"]
print(f"laws hold for joining text, '': {yn(monoid(add, '', words))}")
undo = [q for q in range(0, 1001) if big(375, q) == 0]
print(f"+ has undos (249 + -249 = {249 + -249}); max undo for 375 among 0..1000: {len(undo)}")
subs = brackets(sub, pence)
print(f"minus, left to right: {subs[-1]}; right to left: {subs[0]}")
print(f"minus over {len(subs)} bracketings: {len(set(subs))} different answers {sorted(set(subs))}")
mean_all = total / 4
mean_of_means = (till_a / 3 + till_b / 1) / 2
print(f"mean price {mean_all:.2f}p; mean of the two tills' means {mean_of_means:.2f}p")
s, c = fold(pair, (0, 0), [(p, 1) for p in pence])
s1, c1 = fold(pair, (0, 0), [(p, 1) for p in pence[:3]])
s2, c2 = fold(pair, (0, 0), [(p, 1) for p in pence[3:]])
print(f"fold (sum, count): ({s}, {c}) = {s / c:.2f}p; two tills ({s1}, {c1}) + ({s2}, {c2})")
print(f"start + at 1 instead of 0: one till {fold(add, 1, pence)}, two tills "
      f"{fold(add, 1, pence[:3]) + fold(add, 1, pence[3:])}")

NOTHING = None                          # Maybe: None, or a 1-tuple (x,) = "just x"
def unit(x): return (x,)
def bind(m, f):                         # pass nothing on; feed a value to the next step
    return NOTHING if m is NOTHING else f(m[0])
def step(table): return lambda k: unit(table[k]) if k in table else NOTHING
def show(m): return "nothing" if m is NOTHING else f"just {m[0]}"
def chain(order):
    m = unit(order)
    for t in STEPS:
        m = bind(m, step(t))
    return m
def nested(order):                      # the second road: plain nested ifs
    if order not in ORDERS: return "stops at step 1"
    if ORDERS[order] not in CUSTOMERS: return "stops at step 2"
    if CUSTOMERS[ORDERS[order]] not in ZONES: return "stops at step 3"
    return "just " + CHARGES[ZONES[CUSTOMERS[ORDERS[order]]]]
def lenient(order):                     # the mistake: a missing key read as 0, no Maybe
    k = order
    for t in STEPS:
        k = t.get(k, "0")
    return int(k)
def kleisli(f, g):                      # table f, then table g, as one table
    return {k: g[v] for k, v in f.items() if v in g}

ids = ["1001", "1002", "1003", "1004"]
for o in ids:
    print(f"order {o}: chain {show(chain(o))}; nested ifs {nested(o)}")
fee = int(chain("1001")[0])
bill = total + fee
print(f"order 1001 bill: {total} + {fee} = {bill}p = £{bill // 100}.{bill % 100:02d}")
free = lenient("1002")
print(f"order 1002 with a missing lookup read as 0: delivery {free}p, bill {total + free}p")
dom = sorted({k for t in STEPS for k in t} | {v for t in STEPS for v in t.values()} | {"1004"})
ID = {k: k for k in dom}                # unit, written as a table on the domain
ts = STEPS + [ID]
fs = [step(t) for t in ts]
ms = [NOTHING] + [unit(a) for a in dom]
left = all(bind(unit(a), f) == f(a) for a in dom for f in fs)
right = all(bind(m, unit) == m for m in ms)
assoc = all(bind(bind(m, f), g) == bind(m, lambda x: bind(f(x), g))
            for m in ms for f in fs for g in fs)
print(f"domain {len(dom)} keys, {len(ms)} Maybe values, {len(fs)} steps")
print(f"left identity: {yn(left)}; right identity: {yn(right)}; "
      f"associativity on {len(ms) * len(fs) ** 2} cases: {yn(assoc)}")
def flat(mm): return NOTHING if mm is NOTHING else mm[0]      # Maybe Maybe -> Maybe
def fmap(f, m): return NOTHING if m is NOTHING else unit(f(m[0]))
via_mu = all(flat(fmap(f, m)) == bind(m, f) for m in ms for f in fs)
print(f"bind equals flatten after map on {len(ms) * len(fs)} cases: {yn(via_mu)}")
kid = all(kleisli(ID, t) == t and kleisli(t, ID) == t for t in ts)
kas = all(kleisli(kleisli(f, g), h) == kleisli(f, kleisli(g, h)) for f in ts for g in ts for h in ts)
print(f"tables under >=>: identity {yn(kid)}; associativity on {len(ts) ** 3} triples {yn(kas)}")
whole = fold(kleisli, ID, STEPS)
print("fold of the four steps with >=>, from unit:",
      ", ".join(f"{k} -> {v}" for k, v in sorted(whole.items())))
same = all(show(chain(o)) == show(step(whole)(o)) for o in dom)
print(f"that one table answers every key as the chain does: {yn(same)}")
assert sorted(set(trees)) == [total]                # every bracketing, one answer
assert till_a + till_b == total and total == 833    # two tills; the hand sum
assert len(trees) == 5 and len(set(subs)) == 4 and undo == [] and subs[0] != subs[-1]
assert s / c == mean_all and mean_of_means != mean_all
assert [show(chain(o)) for o in ids] == [nested("1001"), "nothing", "nothing", "nothing"]
assert [nested(o) for o in ids[1:]] == ["stops at step 3", "stops at step 2", "stops at step 1"]
assert left and right and assoc and via_mu and kid and kas and same
assert monoid(add, 0, sample) and monoid(big, 0, sample) and monoid(add, "", words)
assert whole == {"1001": "450"} and bill == 1283
assert lenient("1001") == fee and free == 0         # the default hides the failure
print("ALL CHECKS PASS")
