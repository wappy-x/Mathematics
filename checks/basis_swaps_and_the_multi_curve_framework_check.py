# Multi-curve and the 3s6s basis -- the check behind the card.  Standard library only.
# One discount curve, two forecast curves, three roads: coupon-by-coupon sums with a
# bisection root finder, closed forms, and the single-curve telescope as a control.
from math import exp, log

N, K, T = 10_000_000.0, 0.0450, 5           # the house swap: 10 million, pay fixed 4.5% annual, 5 years
OIS = [0.0420, 0.0440, 0.0455, 0.0462, 0.0465]  # the house curve's par rates, read as OIS, 1 to 5 years
S3, BASIS = 0.0475, 0.0008                  # 5y par rate against the 3m index; 5y 3s6s basis quote

def bisect(f, lo, hi):                      # our own root finder: halve the bracket 200 times
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if f(lo) * f(mid) <= 0: hi = mid
        else: lo = mid
    return 0.5 * (lo + hi)

def market(ois, s3, basis):
    P, B = [1.0], 0.0                       # bootstrap: D_n = (1 - S_n B_n) / (1 + S_n)
    for s in ois:
        d = (1 - s * B) / (1 + s); P.append(d); B += d
    def D(t):                               # log-linear between pillars: flat overnight rate each year
        k = min(int(t), len(ois) - 1); w = t - k
        return exp((1 - w) * log(P[k]) + w * log(P[k + 1]))
    dates = lambda a, n: [a * i for i in range(1, round(n / a) + 1)]
    ann = lambda a, n: sum(a * D(t) for t in dates(a, n))
    def fwd(a, b, t):                       # index forward for (t - a, t) off H(u) = D(u) e^{-bu}
        H = lambda u: D(u) * exp(-b * u)
        return (H(t - a) / H(t) - 1) / a
    leg = lambda a, b, n: sum(a * fwd(a, b, t) * D(t) for t in dates(a, n))              # road 1
    starts = lambda a, n: sum(D(t - a) for t in dates(a, n))
    closed = lambda a, b, n: (1 - D(n)) + (exp(b * a) - 1) * starts(a, n)               # road 2
    m = dict(P=P, D=D, fwd=fwd, leg=leg, closed=closed, ann=ann)
    m["Af"], m["A3"], m["A6"] = ann(1.0, T), ann(0.25, T), ann(0.5, T)
    m["b3"] = bisect(lambda b: leg(0.25, b, T) - s3 * m["Af"], -0.05, 0.05)
    m["b3c"] = 4 * log(1 + (s3 * m["Af"] - (1 - D(T))) / starts(0.25, T))
    m["C3"] = leg(0.25, m["b3"], T)
    m["b6"] = bisect(lambda b: leg(0.5, b, T) - m["C3"] - basis * m["A3"], -0.05, 0.05)
    m["b6c"] = 2 * log(1 + (s3 * m["Af"] + basis * m["A3"] - (1 - D(T))) / starts(0.5, T))
    m["C6"] = leg(0.5, m["b6"], T)
    H3 = lambda u: D(u) * exp(-m["b3"] * u)
    m["V"] = N * (m["C3"] - K * m["Af"])                          # multi-curve value to the payer, road 1
    m["Vq"] = N * (s3 - K) * m["Af"]                              # road 2: straight off the quote
    m["Vois"] = N * ((1 - D(T)) - K * m["Af"])                  # forecast off the discount curve
    m["Vold"] = N * ((1 - H3(T)) - K * sum(H3(k) for k in range(1, T + 1)))   # one 3m curve does both
    m["S6"] = m["C6"] / m["Af"]
    return m

m = market(OIS, S3, BASIS)
D, P, leg, closed, ann, fwd = m["D"], m["P"], m["leg"], m["closed"], m["ann"], m["fwd"]
bp = 1e4
def row(label, v, fmt="{:.6f}"): print(f"{label:<44}" + fmt.format(v))

for n in range(1, T + 1): row(f"D({n}) discount factor", P[n], "{:.8f}")
for n in range(1, T + 1): row(f"  OIS {n}y par rate repriced, percent", 100 * (1 - P[n]) / sum(P[1:n + 1]), "{:.4f}")
row("annuity, annual fixed leg", m["Af"]); row("annuity, quarterly leg", m["A3"]); row("annuity, half-yearly leg", m["A6"])
row("sum of quarter-start discounts", sum(D(0.25 * (i - 1)) for i in range(1, 21)))
row("sum of half-year-start discounts", sum(D(0.5 * (i - 1)) for i in range(1, 11)))
row("b3 by bisection, bp", m["b3"] * bp); row("b3 closed form, bp", m["b3c"] * bp)
row("b6 by bisection, bp", m["b6"] * bp); row("b6 closed form, bp", m["b6c"] * bp)
row("3m leg, coupon by coupon", m["C3"]); row("3m leg, closed form", closed(0.25, m["b3"], T))
row("6m leg, coupon by coupon", m["C6"]); row("6m leg, closed form", closed(0.5, m["b6"], T))
row("OIS floater 1 - D(5)", 1 - D(T)); row("3m leg with b = 0 (telescope)", leg(0.25, 0.0, T))
row("fair 5y basis, sums, bp", (m["C6"] - m["C3"]) / m["A3"] * bp)
row("fair 5y basis, closed forms, bp", (closed(0.5, m["b6c"], T) - closed(0.25, m["b3c"], T)) / m["A3"] * bp)
row("single-curve basis (b = 0), bp", round((leg(0.5, 0.0, T) - leg(0.25, 0.0, T)) / m["A3"] * bp, 9) + 0.0)
for n in (1, 2, 3, 4):
    row(f"fair {n}y basis off the curves, bp", (leg(0.5, m["b6"], n) - leg(0.25, m["b3"], n)) / ann(0.25, n) * bp)
row("house swap, multi-curve, sums", m["V"], "{:.2f}"); row("house swap, off the 4.75% quote", m["Vq"], "{:.2f}")
row("wrong: forecast off OIS", m["Vois"], "{:.2f}"); row("wrong: one 3m curve does both", m["Vold"], "{:.2f}")
row("implied 5y par rate vs 6m, percent", 100 * m["S6"], "{:.4f}")
row("wrong: 4.75% + 8 bp, percent", 100 * (S3 + BASIS), "{:.4f}")
row("  cost of that slip on 10m, dollars", N * (m["S6"] - S3 - BASIS) * m["Af"], "{:.2f}")
row("wrong leg: fair spread on the 6m leg, bp", -(m["C6"] - m["C3"]) / m["A6"] * bp)
Vbs = N * (m["C3"] + 0.0010 * m["A3"] - m["C6"])
row("basis swap struck at 10 bp, sums", Vbs, "{:.2f}"); row("basis swap struck at 10 bp, 2 bp x A3", N * 0.0002 * m["A3"], "{:.2f}")
for label, mm in (("try: basis 15 bp, 6m par percent", market(OIS, S3, 0.0015)),
                  ("try: OIS all +10 bp, house swap", market([x + 0.001 for x in OIS], S3, BASIS)),
                  ("try: 3m par 4.65%, house swap", market(OIS, 0.0465, BASIS))):
    v = 100 * mm["S6"] if "6m" in label else mm["V"]
    row(label, v, "{:.4f}" if "6m" in label else "{:.2f}")
ends = [0.5 * i for i in range(1, 11)]
print(f"{'chart, period ends (years)':<44}" + " ".join(f"{t:.1f}" for t in ends))
for label, a, b in (("chart, OIS 3m forward %", 0.25, 0.0), ("chart, 3m index forward %", 0.25, m["b3"]),
                    ("chart, 6m index forward %", 0.5, m["b6"])):
    print(f"{label:<44}" + " ".join(f"{100 * fwd(a, b, t):.2f}" for t in ends))

assert abs(m["b3"] - m["b3c"]) < 1e-12, "3m spread: root finder vs closed form"
assert abs(m["b6"] - m["b6c"]) < 1e-12, "6m spread: root finder vs closed form"
assert abs(closed(0.5, m["b6"], T) - m["C6"]) < 1e-12, "6m leg: closed form vs coupon sum"
assert abs(m["V"] - m["Vq"]) < 1e-6, "coupon sums vs the quote identity (S3 - K) x annuity"
assert abs(leg(0.25, 0.0, T) - (1 - D(T))) < 1e-14, "single curve: the coupons must telescope"
assert all(abs((1 - P[n]) / sum(P[1:n + 1]) - OIS[n - 1]) < 1e-14 for n in range(1, T + 1)), "curve reprices OIS"
assert abs(Vbs - N * 0.0002 * m["A3"]) < 1e-6, "off-market basis swap: sums vs spread annuity"
assert abs(P[T] - 0.79621728) < 5e-9 and abs(m["Vois"] - 65736.36) < 0.005, "house curve: D(5), card 01 value"
print("ALL CHECKS PASS")
