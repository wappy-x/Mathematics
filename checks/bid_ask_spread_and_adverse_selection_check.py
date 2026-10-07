# The spread -- the check behind the card.  Standard library only.
# Glosten-Milgrom: quotes from Bayes' rule.  Roll: a spread read off trade prices.
# Money in cents.  Acme is worth 9980 or 10020 cents; 10% of traders know which.
from math import sqrt

LO, HI, PRIOR, MU, M64 = 9980.0, 10020.0, 0.5, 0.10, (1 << 64) - 1

def closed(prior, mu, gap=HI - LO):                 # road 1: the formula on the card
    d = 2 * prior - 1
    return gap * 4 * mu * prior * (1 - prior) / (1 - mu * mu * d * d)

def quotes(prior, mu, lo=LO, hi=HI):                # road 2: add up the four cells
    cell = {}
    for state, w in (("H", prior), ("L", 1 - prior)):
        for side in ("buy", "sell"):
            knows = (state == "H") == (side == "buy")
            cell[state, side] = w * (mu * knows + (1 - mu) / 2)
    pb, ps = cell["H", "buy"] + cell["L", "buy"], cell["H", "sell"] + cell["L", "sell"]
    ask = (hi * cell["H", "buy"] + lo * cell["L", "buy"]) / pb
    bid = (hi * cell["H", "sell"] + lo * cell["L", "sell"]) / ps
    return bid, ask, cell["H", "buy"] / pb, cell["H", "sell"] / ps

class Rng:                                           # splitmix64, written out
    def __init__(self, seed): self.s = seed
    def u(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0

def show(label, *vals):
    print(f"{label:<34}" + "".join(f"{v:>13.6f}" for v in vals))

(bid, ask, hb, hs), s1 = quotes(PRIOR, MU), closed(PRIOR, MU)
show("1 formula: spread", s1)
show("2 Bayes cells: bid, ask", bid, ask)
show("  P(high | buy), P(high | sell)", hb, hs)
take, pay = MU * ((HI - LO) / 2 - s1 / 2), (1 - MU) * s1 / 2
show("3 informed take, uninformed pay", take, pay)
assert abs((ask - bid) - s1) < 1e-9, "Bayes cells must match the formula"
assert abs(take - pay) < 1e-12, "the books must balance at the formula's spread"
rng, n, prof, naive, vbuy, nbuy = Rng(2026), 200_000, 0.0, 0.0, 0.0, 0
for _ in range(n):                                   # road 4: simulate one-trade rounds
    high = rng.u() < PRIOR
    v = HI if high else LO
    buy = high if rng.u() < MU else rng.u() < 0.5
    if buy: prof += ask - v; naive += 10000 - v; vbuy += v; nbuy += 1
    else:   prof += v - bid; naive += v - 10000
show("4 simulated E[V | buy], profit", vbuy / nbuy, prof / n)
assert abs(vbuy / nbuy - ask) < 0.3, "simulated E[V | buy] must land on the ask"
show("wrong: quote 10000 both, sim/exact", naive / n, -MU * (HI - LO) / 2)
show("wrong: everyone informed", closed(PRIOR, 1.0))
b2, a2, hb2, hs2 = quotes(0.75, 0.2)
show("try: prior 3/4, 20% informed", b2, a2, a2 - b2)
show("try: 50% informed; gap 100", closed(PRIOR, 0.5), closed(PRIOR, MU, 100.0))
mus = [i / 10 for i in range(11)]
print("chart, informed share      " + " ".join(f"{m:5.1f}" for m in mus))
for p in (0.5, 0.75):
    print(f"chart, spread, prior {p:<5}  " + " ".join(f"{closed(p, m):5.2f}" for m in mus))
for p10 in range(1, 10):                             # grid: formula = cells, rises with mu
    last = -1.0
    for m in mus:
        b, a, _, _ = quotes(p10 / 10, m)
        assert abs((a - b) - closed(p10 / 10, m)) < 1e-9, "cells must match the formula"
        assert a - b > last, "spread must rise with the informed share"
        last = a - b

print("path: trade, side, bid-10000, ask-10000, spread, P(high)")
prior = PRIOR
for k, side in enumerate(" BBSBBBSBBB"):
    if side != " ":
        prior = hb if side == "B" else hs
    b, a, hb, hs = quotes(prior, MU)
    print(f"  {k:>2} {side} {b - 10000:9.2f} {a - 10000:9.2f} {a - b:9.2f} {prior:9.4f}")

def belief(d):                                       # P(high) after d more buys than sells
    x = 1.0
    for _ in range(abs(d)): x *= 9.0 / 11.0
    return 1.0 / (1.0 + x) if d >= 0 else x / (1.0 + x)
assert abs(belief(6) - prior) < 1e-12, "net buys must match trade-by-trade Bayes"
checks, T = (0, 25, 50, 100, 200, 400), 400
dist, exact = {0: 1.0}, {}
for t in range(T + 1):                               # exact: walk the distribution of d
    if t in checks: exact[t] = sum(p * closed(belief(d), MU) for d, p in dist.items())
    nxt = {}
    for d, p in dist.items():
        nxt[d + 1] = nxt.get(d + 1, 0.0) + p * (1 + MU) / 2
        nxt[d - 1] = nxt.get(d - 1, 0.0) + p * (1 - MU) / 2
    dist = nxt
days, sim = 2000, {t: 0.0 for t in checks}
for _ in range(days):                                # simulated: true value high, 2000 days
    d = 0
    for t in range(T + 1):
        if t in checks: sim[t] += closed(belief(d), MU) / days
        buy = True if rng.u() < MU else rng.u() < 0.5
        d += 1 if buy else -1
print("expected spread after n trades, value high: exact, simulated")
for t in checks:
    print(f"  after {t:>3} trades {exact[t]:9.2f} {sim[t]:9.2f}")
    assert abs(exact[t] - sim[t]) < 0.1, "walk and simulation must agree"

for c in range(5):                                   # Roll, exact: 32 equally likely cases
    tot = 0
    for e1 in (-1, 1):
        for e0 in (-1, 1):
            for q2 in (-1, 1):
                for q1 in (-1, 1):
                    for q0 in (-1, 1):
                        tot += (e1 + c * (q2 - q1)) * (e0 + c * (q1 - q0))
    assert tot == -32 * c * c, "Roll: lag covariance must be -c^2"
    if c == 2: show("Roll exact, c = 2: covariance", tot / 32)
m, p_prev, r, w = 10000.0, 10002.0, [], sqrt(3.0)
for _ in range(200_000):                             # Roll, simulated: c = 2, 1-cent news
    m += w * (2 * rng.u() - 1)
    q = 1 if rng.u() < 0.5 else -1
    p = m + 2 * q
    r.append(p - p_prev); p_prev = p
mean = sum(r) / len(r)
g = sum((r[t] - mean) * (r[t - 1] - mean) for t in range(1, len(r))) / (len(r) - 1)
show("Roll simulated: covariance, spread", g, 2 * sqrt(-g))
assert abs(2 * sqrt(-g) - 4.0) < 0.1, "Roll estimate must land near the 4-cent spread"
show("wrong: forgot the 2", sqrt(-g))
ch = [-2, -2, 2, 2]                                   # a short record: covariance positive
show("short record: sample covariance", sum(ch[t] * ch[t - 1] for t in range(1, 4)) / 3)
noise = sum((z2 - z1) * (z1 - z0) for z2 in (-1, 1) for z1 in (-1, 1) for z0 in (-1, 1)) / 8
show("no spread: cov, fake spread", noise, 2 * sqrt(-noise))
e2 = e3 = e23 = 0.0                                  # Roll on Glosten-Milgrom trade prices
for high in (True, False):
    for h in range(8):
        sides, pr, prob, path = [(h >> k) & 1 for k in range(3)], PRIOR, 0.5, [10000.0]
        for sd in sides:
            b, a, hb, hs = quotes(pr, MU)
            prob *= (1 + MU) / 2 if (sd == 1) == high else (1 - MU) / 2
            path.append(a if sd else b); pr = hb if sd else hs
        d2, d3 = path[2] - path[1], path[3] - path[2]
        e2 += prob * d2; e3 += prob * d3; e23 += prob * d2 * d3
show("GM trade prices: lag covariance", round(e23 - e2 * e3, 9) + 0.0)
assert abs(e23 - e2 * e3) < 1e-9, "Glosten-Milgrom trade prices must not bounce"
print("ALL CHECKS PASS")
