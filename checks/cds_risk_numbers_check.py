# CDS risk numbers -- the check behind the card.  Standard library only.
# Northwind: $10m of five-year protection bought at par, quarterly premiums,
# hazard 2% flat, recovery 40%, riskless rate 5%.  Each risk number is found
# twice: move the market and revalue, and differentiate the leg formulas.
from math import exp

N, T, DT, LAM, R, RATE, BP = 10_000_000.0, 5.0, 0.25, 0.02, 0.40, 0.05, 1e-4
FAR = 1e9                                        # "for ever": the last knot of every curve

def flat(h):
    return [(FAR, h)]

def surv(curve, t):                              # Q(t): survival, curve = [(end year, hazard)]
    area, a = 0.0, 0.0
    for b, h in curve:
        area += h * (min(t, b) - a)
        if t <= b:
            break
        a = b
    return exp(-area)

def annuity(curve, mat, r):                      # A: 1 a year, paid quarterly while alive
    return sum(DT * exp(-r * t) * surv(curve, t) for t in [DT * (j + 1) for j in range(round(mat / DT))])

def protection(curve, mat, r, rec):              # road 1 for P: closed form, knot to knot
    total, a = 0.0, 0.0
    for b, h in curve:
        e, k = min(b, mat), r + h
        total += (1 - rec) * h / k * exp(-r * a) * surv(curve, a) * (1 - exp(-k * (e - a)))
        if b >= mat:
            break
        a = b
    return total

def simpson(f, a, b, n=400):                     # area under f from a to b, n even
    step = (b - a) / n
    return step / 3 * (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * step) for i in range(1, n)))

def protection_simpson(curve, mat, r, rec):      # road 2 for P: integrate the default density
    total, a = 0.0, 0.0
    for b, h in curve:
        e = min(b, mat)
        total += (1 - rec) * simpson(lambda t: h * exp(-r * t) * surv(curve, t), a, e)
        if b >= mat:
            break
        a = b
    return total

def value(curve, mat, r, rec, s0, prot=protection):   # buyer's value: protection minus premiums
    return N * (prot(curve, mat, r, rec) - s0 * annuity(curve, mat, r))

def par(curve, mat, r, rec):
    return protection(curve, mat, r, rec) / annuity(curve, mat, r)

def bisect(f, lo, hi):                           # root finder: halve the bracket 100 times
    for _ in range(100):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if f(lo) * f(mid) > 0 else (lo, mid)
    return 0.5 * (lo + hi)

def implied(s, r, rec, mat=T):                   # the flat hazard that reprices a quote
    return bisect(lambda h: par(flat(h), mat, r, rec) - s, 1e-9, 3.0)

def bumped(s_mkt, s0):                           # road 1: move the market, re-imply, revalue
    v = lambda s, r, rec: value(flat(implied(s, r, rec)), T, r, rec, s0)
    return (v(s_mkt + BP, RATE, R) - v(s_mkt, RATE, R),
            (v(s_mkt + BP, RATE, R) - v(s_mkt - BP, RATE, R)) / 2,
            (v(s_mkt, RATE + BP, R) - v(s_mkt, RATE - BP, R)) / 2,
            (v(s_mkt, RATE, R + 0.01) - v(s_mkt, RATE, R - 0.01)) / 2)

def analytic(lam, s0, r=RATE, rec=R):            # road 2: derivatives of the flat-hazard legs
    k, ts = r + lam, [DT * (j + 1) for j in range(round(T / DT))]
    A = sum(DT * exp(-k * t) for t in ts)
    A_k = -sum(DT * t * exp(-k * t) for t in ts)            # dA/dlambda = dA/dr
    G = (1 - exp(-k * T)) / k
    G_k = T * exp(-k * T) / k - G / k
    P, P_lam, P_r = (1 - rec) * lam * G, (1 - rec) * (G + lam * G_k), (1 - rec) * lam * G_k
    s_lam, s_r, s_rec = (P_lam * A - P * A_k) / A ** 2, (P_r * A - P * A_k) / A ** 2, -P / A / (1 - rec)
    V_lam = N * (P_lam - s0 * A_k)
    return (V_lam / s_lam * BP, (N * (P_r - s0 * A_k) - V_lam * s_r / s_lam) * BP,
            (-N * P / (1 - rec) - V_lam * s_rec / s_lam) * 0.01, N * A * BP)

A0, P0 = annuity(flat(LAM), T, RATE), protection(flat(LAM), T, RATE, R)
s0 = P0 / A0                                     # the contract spread, fixed from today on
cs_up, cs_c, ir_c, rec_c = bumped(s0, s0)
cs_a, ir_a, rec_a, cs_nA = analytic(LAM, s0)
V_dead = value(flat(1e7), T, RATE, R, s0)        # hazard so large that default is immediate
lam200 = implied(0.02, RATE, R)
V200 = value(flat(lam200), T, RATE, R, s0)
_, w_c, w_ir, w_rec = bumped(0.02, s0)
w_cs_a, w_ir_a, w_rec_a, _ = analytic(lam200, s0)
lam1 = implied(0.01, RATE, R, 4.0)               # rising curve: 4y quotes 100 bp, 5y at s0
lam2 = bisect(lambda h: par([(4.0, lam1), (FAR, h)], T, RATE, R) - s0, 1e-9, 3.0)
rise = [(4.0, lam1), (FAR, lam2)]
rows = [("risky annuity A", A0, 6), ("protection leg P per $1", P0, 6), ("contract spread s0, bp", s0 / BP, 4),
        ("CS01 bump +1bp", cs_up, 2), ("CS01 bump +-1bp", cs_c, 2), ("CS01 derivative", cs_a, 2),
        ("  N x A x 1bp", cs_nA, 2), ("IR01 bump +-1bp", ir_c, 2), ("IR01 derivative", ir_a, 2),
        ("Rec01 bump +-1pt", rec_c, 2), ("Rec01 derivative", rec_a, 2),
        ("JTD (1-R)N - V", N * (1 - R) - value(flat(LAM), T, RATE, R, s0), 2), ("JTD hazard 1e7", V_dead, 2),
        ("JTD per recovery point", -N * 0.01, 2),
        ("widened: hazard at 200 bp", lam200, 6), ("widened: value V", V200, 2),
        ("widened: value, Simpson", value(flat(lam200), T, RATE, R, s0, protection_simpson), 2),
        ("widened: CS01 bump +-1bp", w_c, 2), ("widened: CS01 derivative", w_cs_a, 2),
        ("widened: IR01 bump +-1bp", w_ir, 2), ("widened: IR01 derivative", w_ir_a, 2),
        ("widened: Rec01 bump +-1pt", w_rec, 2), ("widened: Rec01 derivative", w_rec_a, 2),
        ("widened: JTD", N * (1 - R) - V200, 2), ("widened: JTD hazard 1e7", V_dead - V200, 2),
        ("carry paid per quarter", s0 * N * DT, 2), ("expected payout, first quarter", N * (1 - R) * (1 - surv(flat(LAM), DT)), 2),
        ("flat: par spread 4.75y, bp", par(flat(LAM), 4.75, RATE, R) / BP, 4),
        ("flat: roll-down", value(flat(LAM), 4.75, RATE, R, s0), 2),
        ("rising: hazard to 4y", lam1, 6), ("rising: hazard 4y to 5y", lam2, 6),
        ("rising: par spread 4.75y, bp", par(rise, 4.75, RATE, R) / BP, 4),
        ("rising: roll-down", value(rise, 4.75, RATE, R, s0), 2),
        ("rising: roll-down, Simpson", value(rise, 4.75, RATE, R, s0, protection_simpson), 2),
        ("wrong: Rec01 hazard held", value(flat(LAM), T, RATE, R + 0.01, s0) - value(flat(LAM), T, RATE, R, s0), 2),
        ("wrong: IR01 hazard held", value(flat(LAM), T, RATE + BP, R, s0) - value(flat(LAM), T, RATE, R, s0), 2),
        ("wrong: CS01, riskless annuity", N * BP * annuity(flat(0.0), T, RATE), 2),
        ("wrong: V at 200 bp from CS01", cs_a * (0.02 - s0) / BP, 2)]
for name, v, d in rows:
    print(f"{name:<32}{(v if abs(v) >= 0.5 * 10 ** -d else 0.0):>18.{d}f}")
print()
spreads = [40, 80, 120, 160, 200, 240, 280, 320]
print("chart, 5y spread bp  " + "".join(f"{s:>9d}" for s in spreads))
print("chart, value $k      " + "".join(f"{value(flat(implied(s * BP, RATE, R)), T, RATE, R, s0) / 1e3:>9.2f}" for s in spreads))
print("chart, CS01 line $k  " + "".join(f"{cs_a * (s * BP - s0) / BP / 1e3:>9.2f}" for s in spreads))
for s in (200, 400, 800):
    lam_s = implied(s * BP, RATE, R)
    print(f"bars, CS01 at {s:>3d} bp  bump {bumped(s * BP, s0)[1]:>10.2f}  derivative {analytic(lam_s, s0)[0]:>10.2f}")
assert abs(cs_c - cs_a) < 0.01, "CS01: central bump vs derivative of the legs"
assert abs(cs_a - cs_nA) < 1e-6, "CS01 at par: derivative vs N x A x 1bp"
assert abs(w_ir - w_ir_a) < 0.01, "IR01, widened: bump vs derivative"
assert abs(w_rec - w_rec_a) < 0.5, "Rec01, widened: bump vs derivative (bump is 1 point wide)"
assert abs(N * (1 - R) - V_dead) < 1.0, "JTD: formula vs revalue at an immediate default"
assert max(abs(ir_c), abs(ir_a), abs(rec_c), abs(rec_a)) < 0.01, "at par: IR01 and Rec01 vanish, both roads"
assert abs(V200 - value(flat(lam200), T, RATE, R, s0, protection_simpson)) < 0.01, "value at 200 bp, two roads"
assert abs(par(flat(LAM), 4.75, RATE, R) - s0) < 1e-12, "flat curve: par spread does not depend on maturity"
assert w_c < cs_up < cs_c, "CS01 falls as the spread widens"
assert abs(value(rise, 4.75, RATE, R, s0) - value(rise, 4.75, RATE, R, s0, protection_simpson)) < 0.01, "roll-down, two roads"
print("ALL CHECKS PASS")
