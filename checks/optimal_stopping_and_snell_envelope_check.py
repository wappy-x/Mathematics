# Optimal stopping and the Snell envelope -- the check behind the card.  Standard library only.
# Selling a house: one offer a month for 3 months, 380,000, 400,000 or 430,000 dollars with
# chances 0.3, 0.5, 0.2, independent month to month.  Holding the house costs 3,000 dollars a
# month; the month-3 offer must be taken.  Three roads to the best average result: backward
# induction on the tree (the Snell envelope), brute force over every stopping rule, simulation.
from math import sqrt

X, WT, COST, N = [380000, 400000, 430000], [3, 5, 2], 3000, 3   # offers, chances in tenths
MASK = (1 << 64) - 1

def splitmix(s):                                  # SplitMix64: new state and 64 random bits
    s = (s + 0x9E3779B97F4A7C15) & MASK
    z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return s, z ^ (z >> 31)

def nodes(n):                                     # every history of n offers, as index tuples
    out = [()]
    for _ in range(n): out = [h + (i,) for h in out for i in range(3)]
    return out

def Z(h): return X[h[-1]] - COST * len(h)        # reward for selling now: offer minus costs
def avg(vals):                                    # E[ . | F_n] over the three next offers
    t = sum(w * v for w, v in zip(WT, vals)); assert t % 10 == 0; return t // 10

# Road 1: the Snell envelope, backward from month 3.  C = value of waiting one more month.
U, C = {}, {}
for n in range(N, -1, -1):
    for h in nodes(n):
        if n < N: C[h] = avg([U[h + (i,)] for i in range(3)])
        U[h] = Z(h) if n == N else (C[h] if n == 0 else max(Z(h), C[h]))

def is_envelope_above(V):                         # V >= Z everywhere, and V >= E[next V]
    dom = all(V[h] >= Z(h) for n in range(1, N + 1) for h in nodes(n))
    sup = all(10 * V[h] >= sum(w * V[h + (i,)] for i, w in enumerate(WT)) for n in range(N) for h in nodes(n))
    return dom and sup

paths = nodes(N)
def weight(p):
    r = 1
    for i in p: r *= WT[i]
    return r
def value(stop):                                  # 1000 x expected reward of a rule, all 27 paths
    tot = 0
    for p in paths:
        n = next(k for k in range(1, N + 1) if k == N or stop(p[:k]))
        tot += weight(p) * Z(p[:n])
    return tot

snell_rule = lambda h: U[h] == Z(h)
# Road 2: every stopping rule.  For each month-1 offer: sell (0), or wait and choose, for each
# month-2 offer, sell or wait (1 + 3-bit mask).  9 choices for each of 3 offers: 729 rules.
best, nbest, count, snell_seen = None, 0, 0, False
for code in range(9 ** 3):
    ch = [(code // 9 ** i) % 9 for i in range(3)]
    stop = lambda h, ch=ch: ch[h[0]] == 0 if len(h) == 1 else (((ch[h[0]] - 1) >> h[1]) & 1) == 1
    v = value(stop); count += 1
    if best is None or v > best: best, nbest = v, 0
    if v == best: nbest += 1
    if all(stop(h) == snell_rule(h) for n in (1, 2) for h in nodes(n) if n == 1 or not snell_rule(h[:1])): snell_seen = v
assert best == 1000 * U[()]                       # road 1 = road 2, exact dollars
assert nbest == 1                                 # exactly one rule attains the best value ...
assert snell_seen == best                         # ... and it is the envelope's rule
assert is_envelope_above(U)
lowered = 0
for n in range(N + 1):
    for h in nodes(n):
        V = dict(U); V[h] -= 1; lowered += not is_envelope_above(V)
assert lowered == 40                              # lower U by 1 dollar anywhere and it fails
prophet = {h: sum(weight(p[len(h):]) * max(Z(p[:k]) for k in range(max(1, len(h)), N + 1))
                  for p in paths if p[:len(h)] == h) // 10 ** (N - len(h)) for n in range(N + 1) for h in nodes(n)}
assert is_envelope_above(prophet)                 # another supermartingale above Z ...
assert all(prophet[h] >= U[h] for h in prophet)   # ... sits above U at every node
print(f"house: offers {X[0]} / {X[1]} / {X[2]} dollars, chances {WT[0] / 10} / {WT[1] / 10} / {WT[2] / 10}, cost {COST} a month")
print(f"Snell value U_0, backward induction    {U[()]}")
print(f"best of {count} stopping rules, brute force {best // 1000}  (rules attaining it: {nbest})")
for n in (1, 2, 3):
    h = (0,) * (n - 1)
    row = "  ".join(f"{X[i]}->{'sell' if snell_rule(h + (i,)) else 'wait'} U={U[h + (i,)]}" for i in range(3))
    print(f"month {n}: wait value {C[h + (0,)] if n < N else '-'}  {row}")
print(f"supermartingale and above Z at all nodes: {is_envelope_above(U)}; lowered by 1 dollar and broken at {lowered} of 40 nodes")
print(f"prophet's process (sees all offers) at month 0: {prophet[()]}, at least U at all 40 nodes")

rules = [("Snell rule", snell_rule), ("myopic: sell if Z_n >= E[Z_n+1]", lambda h: Z(h) >= avg(X) - COST * (len(h) + 1)),
         ("hold out for 430000", lambda h: h[-1] == 2), ("take the first offer", lambda h: True)]
for name, r in rules: print(f"rule value  {name:34s} {value(r) // 1000}  chart {value(r) / 1e6:.2f}")
print(f"rule value  {'prophet (not a stopping time)':34s} {prophet[()]}  chart {prophet[()] / 1000:.2f}")
when = [sum(weight(p) for p in paths if next(k for k in range(1, 4) if k == 3 or snell_rule(p[:k])) == m) for m in (1, 2, 3)]
etau = sum(m * w for m, w in zip((1, 2, 3), when))       # 1000 x E[tau]
price = sum(weight(p) * X[p[next(k for k in range(1, 4) if k == 3 or snell_rule(p[:k])) - 1]] for p in paths)
assert price == 1000 * U[()] + COST * etau               # price = net value + costs paid
print(f"Snell rule sells in month 1/2/3 with chance {when[0] / 1000:.2f} / {when[1] / 1000:.2f} / {when[2] / 1000:.2f}; E[tau] {etau / 1000:.2f} months; E[price] {price // 1000}")
print(f"rewards Z_n = offer - {COST} n, months 1/2/3: " + "; ".join(" ".join(str(X[i] - COST * n) for i in range(3)) for n in (1, 2, 3)))
print(f"gaps: waiting on 400000 in month 1 beats selling by {U[(1,)] - Z((1,))}; prophet minus Snell {prophet[()] - U[()]}; average costs paid {COST * etau // 1000}")

# Road 3: simulation of sellers using the envelope's rule.
P, seed, s = 100000, 20260930, 20260930
tot, tot2, ntau, ntau2, nprice, nprice2 = 0, 0, 0, 0, 0, 0
for j in range(P):
    h = ()
    while True:
        s, z = splitmix(s); u = (z >> 11) / 9007199254740992.0
        h += (0 if u < WT[0] / 10 else (1 if u < (WT[0] + WT[1]) / 10 else 2),)
        if len(h) == N or snell_rule(h): break
    r = Z(h); tot += r; tot2 += r * r; ntau += len(h); nprice += X[h[-1]]
    ntau2 += len(h) * len(h); nprice2 += X[h[-1]] * X[h[-1]]
m = tot / P; se = sqrt((tot2 / P - m * m) / P)
mt, mp = ntau / P, nprice / P; se_t, se_p = sqrt((ntau2 / P - mt * mt) / P), sqrt((nprice2 / P - mp * mp) / P)
assert abs(m - U[()]) < 4 * se
print(f"simulation, {P} sellers, seed {seed}: mean {m:.2f}  se {se:.2f}  mean month {mt:.4f}  se {se_t:.4f}  mean price {mp:.2f}  se {se_p:.2f}")

# The deadline: V_k = best value with k offers to come (iid shortcut), then the limit with none.
vk, VK = 0.0, []
for k in range(1, 61):
    vk = sum(c / 10 * x for c, x in zip(WT, X)) - COST if k == 1 else sum(c / 10 * max(x, vk) for c, x in zip(WT, X)) - COST
    VK.append(vk)
assert abs(VK[2] - U[()]) < 1e-6                   # iid shortcut = full tree
lim = (WT[2] / 10 * X[2] - COST) / (1 - (WT[0] + WT[1]) / 10)   # fixed point between 400000 and 430000
assert X[1] <= lim <= X[2] and abs(VK[59] - lim) < 1.0
print("chart, deadline months  " + " ".join(f"{k:7d}" for k in range(1, 13)))
print("chart, value (thousand) " + " ".join(f"{VK[k - 1] / 1000:7.2f}" for k in range(1, 13)))
print(f"deadline 24: {VK[23]:.2f}  deadline 60: {VK[59]:.2f}  no deadline (fixed point): {lim:.2f}")
print("no deadline, no cost, bids 430000 - 30000/n: " + " ".join(f"n={n}:{430000 - 30000 // n}" for n in (1, 2, 3, 4, 12, 100)) + "; sup 430000, never reached")
fy = lambda x: 210 - (x - 370000) / 400
print("figure, node x " + " ".join(str(80 + 100 * (n - 1)) for n in (1, 2, 3)) + "; node y " + " ".join(f"{fy(x):.1f}" for x in X)
      + f"; bar y {fy(VK[1]):.2f} {fy(VK[0]):.2f}")
