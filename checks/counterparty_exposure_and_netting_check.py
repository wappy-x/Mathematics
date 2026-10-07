# Counterparty exposure and netting -- the check behind the card.  Standard library only.
# Every number quoted on the card is printed here.  Nothing imported knows the answer:
# the bell-curve area is Simpson's rule written out, the random numbers are our own.
from math import exp, sqrt, pi

V = [5.0, -3.0, 2.0]        # the three Northwind trades, value to the bank, $ millions
R = 0.40                    # recovery: share of a claim on Northwind the bank gets back

def pos(x): return x if x > 0 else 0.0                       # the floor: x+ = max(x, 0)

def exposure(v, sets):      # road 1: add inside each netting set, floor, add the sets
    return sum(pos(sum(v[i] for i in s)) for s in sets)

def ledger(v, sets, rec):   # road 2: follow the cash on the day Northwind fails
    cash = 0.0
    for s in sets:
        amount = sum(v[i] for i in s)                         # close-out: one amount per set
        cash += rec * amount if amount > 0 else amount        # claim recovers R; debt paid in full
    return sum(v) - cash, cash                                # loss = worth if it survived - cash

def pairing(v, sets):       # road 3: cancel a cent owed to the bank against a cent it owes
    left = 0
    for s in sets:
        owed = sum(round(100 * v[i]) for i in s if v[i] > 0)
        owes = sum(round(-100 * v[i]) for i in s if v[i] < 0)
        while owed > 0 and owes > 0:
            owed -= 1; owes -= 1
        left += owed
    return left / 100.0

ONE, SEP = [[0, 1, 2]], [[0, 2], [1]]                      # one master agreement; -3 trade apart
EACH = [[0], [1], [2]]
gross, net, sep = exposure(V, EACH), exposure(V, ONE), exposure(V, SEP)
P = sum(pos(x) for x in V); Q = sum(pos(-x) for x in V)
loss_net, cash_net = ledger(V, ONE, R)
loss_sep, cash_sep = ledger(V, SEP, R)
loss_each, cash_each = ledger(V, EACH, R)

# ---- the house example: Acme options bought from and sold to Northwind ----
S, K, r, q, sig, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
def Ncdf(x, n=2000):        # bell-curve area left of x: 1/2 plus Simpson's rule from 0 to x
    h = x / n
    f = lambda z: exp(-0.5 * z * z) / sqrt(2.0 * pi)
    s = f(0.0) + f(x) + sum((4 if k % 2 else 2) * f(k * h) for k in range(1, n))
    return 0.5 + s * h / 3.0
def ln(x, n=4000):          # natural log as the area under 1/t from 1 to x (Simpson again)
    h = (x - 1.0) / n
    s = 1.0 + 1.0 / x + sum((4 if k % 2 else 2) / (1.0 + k * h) for k in range(1, n))
    return s * h / 3.0
d1 = (ln(S / K) + (r - q + 0.5 * sig * sig) * T) / (sig * sqrt(T)); d2 = d1 - sig * sqrt(T)
call = S * exp(-q * T) * Ncdf(d1) - K * exp(-r * T) * Ncdf(d2)
put = K * exp(-r * T) * Ncdf(-d2) - S * exp(-q * T) * Ncdf(-d1)
fwd = S * exp(-q * T) - K * exp(-r * T)                       # parity: no bell curve needed
acme_net = exposure([call, -put], [[0, 1]]); acme_sep = exposure([call, -put], [[0], [1]])

# ---- road 4: 20,000 random books, our own random numbers (a linear congruential generator) ----
seed = 20260928
def rnd(m):
    global seed
    seed = (1103515245 * seed + 12345) % 2147483648
    return seed % m
books = merges = 0
for _ in range(20000):
    n = 1 + rnd(6)
    v = [float(rnd(19) - 9) for _ in range(n)]
    lab = [rnd(3) for _ in range(n)]
    sets = [[i for i in range(n) if lab[i] == g] for g in range(3)]
    sets = [s for s in sets if s]
    x = exposure(v, sets)
    assert exposure(v, [list(range(n))]) <= x <= exposure(v, [[i] for i in range(n)])
    assert abs(pairing(v, sets) - x) < 1e-9 and abs(ledger(v, sets, R)[0] - (1 - R) * x) < 1e-9
    if len(sets) > 1:                                      # merge the first two agreements
        assert exposure(v, [sets[0] + sets[1]] + sets[2:]) <= x
        merges += 1
    books += 1

rows = [
    ("trade 1", V[0]), ("trade 2", V[1]), ("trade 3", V[2]),
    ("gross: floor each trade, add", gross), ("net: add, then floor", net),
    ("net by cent pairing", pairing(V, ONE)), ("P  owed to the bank, trade by trade", P),
    ("Q  owed by the bank, trade by trade", Q), ("gross - net", gross - net),
    ("min(P, Q)", min(P, Q)), ("net-to-gross ratio", net / gross),
    ("separate: -3 trade apart", sep), ("  still owed by the bank", -sum(V[i] for i in SEP[1])),
    ("partition {1,2}{3}", exposure(V, [[0, 1], [2]])), ("  set {1,2} total", V[0] + V[1]),
    ("partition {2,3}{1}", exposure(V, [[1, 2], [0]])), ("  set {2,3} total", V[1] + V[2]),
    ("R  recovery", R), ("LGD = 1 - R", 1 - R),
    ("loss, one agreement, ledger", loss_net), ("  (1-R) x net", (1 - R) * net),
    ("  cash the bank ends with", cash_net),
    ("loss, -3 apart, ledger", loss_sep), ("  (1-R) x separate", (1 - R) * sep),
    ("  claim recovered, -3 apart", R * sep), ("  cash the bank ends with", cash_sep),
    ("loss, no agreement, ledger", loss_each), ("  cash the bank ends with", cash_each),
    ("Acme call bought", call), ("Acme put", put), ("exposure, call bought only", exposure([call], [[0]])),
    ("exposure, put sold only", exposure([-put], [[0]])),
    ("exposure, call bought + put sold, one set", acme_net), ("  S e^-qT - K e^-rT", fwd),
    ("exposure, the two apart", acme_sep),
    ("wrong: floor each, one agreement", gross), ("wrong: net across two agreements", net),
    ("wrong: no floor, trade 2 = -9", sum([5.0, -9.0, 2.0])), ("wrong: sizes |V| added", sum(abs(x) for x in V)),
    ("try: trade 2 = -9, net", exposure([5.0, -9.0, 2.0], ONE)),
    ("try: trade 2 = -9, bank owes", -sum([5.0, -9.0, 2.0])),
    ("try: R = 0, loss one agreement", ledger(V, ONE, 0.0)[0]),
    ("try: +2 trade apart", exposure(V, [[0, 1], [2]])),
    ("try: trade 2 = +3, net", exposure([5.0, 3.0, 2.0], ONE)),
]
for name, x in rows:
    print(f"{name:<42} {x:>11.6f}")
print(f"random books checked {books}, merges checked {merges}")
xs = list(range(-10, 5))
print("chart, trade 2 value " + " ".join(f"{x:5d}" for x in xs))
print("chart, net           " + " ".join(f"{exposure([5.0, x, 2.0], ONE):5.2f}" for x in xs))
print("chart, gross         " + " ".join(f"{exposure([5.0, x, 2.0], EACH):5.2f}" for x in xs))

assert abs(net - pairing(V, ONE)) < 1e-12,            "floor formula vs cent pairing"
assert abs(gross - net - min(P, Q)) < 1e-12,          "netting saves exactly min(P, Q)"
assert abs(loss_net - (1 - R) * net) < 1e-12,         "cash ledger vs (1-R) x exposure"
assert abs(acme_net - fwd) < 1e-9,                    "netted Acme pair vs put-call parity"
assert abs(call - 9.227005508154) < 1e-9,             "house call value"
print("ALL CHECKS PASS")
