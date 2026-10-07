# Bellman-Ford and arbitrage -- the check behind the card.  Nothing is imported.
# Three currencies, three quoted rates: USD->EUR 0.90, EUR->GBP 0.85, GBP->USD
# 1.32.  Road one adds costs, minus the log of each rate, relaxing every quoted
# rate n-1 rounds and once more.  Road two multiplies rates along every route.
CUR = ["USD", "EUR", "GBP"]
ARB = [("GBP", "USD", 1.32), ("EUR", "GBP", 0.85), ("USD", "EUR", 0.90)]
CLEAN = [("GBP", "USD", 1.30), ("EUR", "GBP", 0.85), ("USD", "EUR", 0.90)]
INF, SRC = float("inf"), "USD"
def ln(x):                        # natural log, from the series in (x-1)/(x+1)
    y = (x - 1.0) / (x + 1.0)
    total, term = 0.0, y
    for k in range(1, 40, 2):
        total, term = total + term / k, term * y * y
    return 2.0 * total
def ln_area(x):                   # the same log as the area under 1/t, by Simpson's rule
    h, total = (x - 1.0) / 2000, 1.0 + 1.0 / x
    for i in range(1, 2000):
        total += (4.0 if i % 2 else 2.0) / (1.0 + i * h)
    return total * h / 3.0
def rounds(market, extra):        # road one: relax every quoted rate, round after round
    d = {c: (0.0 if c == SRC else INF) for c in CUR}
    table, improved = [dict(d)], False
    for r in range(len(CUR) - 1 + extra):
        for a, b, rate in market:
            if d[a] < INF and d[a] - ln(rate) < d[b] - 1e-12:
                d[b], improved = d[a] - ln(rate), improved or r == len(CUR) - 1
        table.append(dict(d))
    return table, improved
def walks(market, legs):          # road two: every route of at most `legs` legs, rates multiplied
    best, frontier = {SRC: 1.0}, [(SRC, 1.0)]
    for _ in range(legs):
        frontier = [(b, m * rate) for c, m in frontier for a, b, rate in market if a == c]
        for c, m in frontier:
            best[c] = max(best.get(c, 0.0), m)
    return best
def trip(market): return market[0][2] * market[1][2] * market[2][2]
def cost_sum(market): return sum(-ln(rate) for _, _, rate in market)

(tab, neg), (tabc, negc) = rounds(ARB, 1), rounds(CLEAN, 1)
p, pc = trip(ARB), trip(CLEAN)
print("quoted market: " + ",  ".join(f"{a}->{b} {r:.2f}" for a, b, r in reversed(ARB)))
print("costs, minus the log of each rate: " + ",  ".join(f"{a}->{b} {-ln(r):.6f}" for a, b, r in reversed(ARB)))
print("scan order inside every round: " + ", ".join(f"{a}->{b}" for a, b, _ in ARB))
print(f"{'round':<6}" + "".join(f"{c:>10}" for c in CUR))
for lab, d in (("start", tab[0]), ("1", tab[1]), ("2", tab[2]), ("3", tab[3])):
    print(f"{lab:<6}" + "".join(f"{'inf':>10}" if d[c] == INF else f"{d[c]:10.6f}" for c in CUR))
print(f"round 3 still improves {SRC}, {tab[3][SRC]:.6f} against {tab[2][SRC]:.6f}, so a loop pays: {'yes' if neg else 'no'}")
print(f"loop USD->EUR->GBP->USD: costs added {cost_sum(ARB):.6f}, rates multiplied {p:.6f} ({(p - 1) * 100:+.2f}%)")
print(f"minus the log of {p:.6f} is {-ln(p):.6f}; best multiplier home over routes of at most 3 legs {walks(ARB, 3)[SRC]:.6f}")
print(f"the log of 1.32 by the series {ln(1.32):.6f}, by the area under 1/t {ln_area(1.32):.6f}")
print(f"market with GBP->USD at 1.30: rates multiplied {pc:.6f} ({(pc - 1) * 100:+.2f}%), costs added {cost_sum(CLEAN):.6f}")
print(f"its rounds 1 and 2 read as above; round 3 offers {SRC} {tabc[2]['GBP'] - ln(1.30):.6f}, no improvement, loop pays: {'yes' if negc else 'no'}")
print(f"mistake 1, stopping after 2 rounds: {SRC} reads {tab[2][SRC]:.6f}, not {tab[3][SRC]:.6f}")
print(f"mistake 2, thresholds crossed over: the losing market clears both, {pc:.6f} > 0 and {cost_sum(CLEAN):.6f} < 1")
print(f"mistake 3, plus the log instead of minus: the loop totals {-cost_sum(ARB):.6f}, above zero, arbitrage missed")
assert neg == (p > 1.0) and negc == (pc > 1.0)            # detector against multiplied rates
assert abs(cost_sum(ARB) + ln(p)) < 1e-12 and abs(cost_sum(CLEAN) + ln(pc)) < 1e-12
assert max(abs(ln(r) - ln_area(r)) for _, _, r in ARB) < 1e-9      # series against area
assert all(abs(tabc[2][c] + ln(walks(CLEAN, 2)[c])) < 1e-12 for c in CUR) and abs(tab[3][SRC] + ln(walks(ARB, 3)[SRC])) < 1e-12
print("ALL CHECKS PASS")
