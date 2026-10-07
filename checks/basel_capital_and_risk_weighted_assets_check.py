# Basel capital -- the check behind the card.  Standard library only.
# Every number quoted on the card is printed here.  Three roads to the CET1 ratio,
# two to the payout limit, two to each breaking point, two to the CET1 a bank needs.
# Money in millions of dollars; ratios as decimals inside, percent when printed.

LOANS = [(400.0, 0.30),   # mortgages, loan-to-value 60-80%: 30% weight
         (400.0, 1.00),   # unrated corporate loans: 100% weight
         (200.0, 0.75)]   # regulatory retail loans: 75% weight
K_M = 12.0                # market-risk capital charge on the 100m trading book
K_O = 0.12 * 120.0        # operational-risk charge: 12% of a 120m business indicator
CET1, AT1, T2 = 120.0, 0.0, 0.0
MIN_C, MIN_T1, MIN_TOT, CCB = 0.045, 0.06, 0.08, 0.025
TABLE = [(0.05125, 1.00), (0.0575, 0.80), (0.06375, 0.60), (0.07, 0.40)]   # buffer-table CET1 up to, share kept

def rwa(loans, km, ko):                          # road 1: weight each loan, turn charges into RWA
    return sum(e * w for e, w in loans) + 12.5 * (km + ko)

def ratio_by_charges(c, loans, km, ko):          # road 2: add the 8% charges, then compare
    charge = sum(MIN_TOT * e * w for e, w in loans) + km + ko
    return MIN_TOT * c / charge

def exact_bp(c_k, loans_k, charges_k):           # road 3: whole thousands of dollars, whole-percent weights
    r_k = sum(e * w for e, w in loans_k) // 100 + charges_k * 25 // 2
    return c_k * 10000 // r_k, c_k * 10000 % r_k, r_k

def cet1_for_minima(r, a1, t2):                  # CET1 must fill whatever the other tiers leave empty
    return max(MIN_C * r, MIN_T1 * r - a1, MIN_TOT * r - a1 - t2)

def cet1_for_minima_scan(r_k, a1_k, t2_k):       # second road: count up a thousand dollars at a time
    c = 0
    while not (1000 * c >= 45 * r_k and 1000 * (c + a1_k) >= 60 * r_k and 1000 * (c + a1_k + t2_k) >= 80 * r_k):
        c += 1
    return c

def keep_by_table(c, r, a1=0.0, t2=0.0):         # payout rule, road A: the Basel table on CET1 ratios
    q = MIN_C + (c - cet1_for_minima(r, a1, t2)) / r
    if q < MIN_C - 1e-12: return None             # below a minimum: not a buffer question any more
    for top, keep in TABLE:
        if q <= top + 1e-12: return keep
    return 0.0

def keep_by_dollars(c_k, r_k):                    # payout rule, road B: which quarter of the buffer is still full
    excess, buf = c_k - 80 * r_k // 1000, 25 * r_k // 1000
    if excess < 0: return None
    for j, keep in ((1, 1.00), (2, 0.80), (3, 0.60), (4, 0.40)):
        if 4 * excess <= j * buf: return keep
    return 0.0

def bisect(f, lo, hi, n=200):                     # root finder: f(lo) < 0 <= f(hi)
    for _ in range(n):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if f(mid) < 0 else (lo, mid)
    return hi

R = rwa(LOANS, K_M, K_O)
credit = sum(e * w for e, w in LOANS)
ratio1 = CET1 / R
ratio2 = ratio_by_charges(CET1, LOANS, K_M, K_O)
bp, rem, r_k = exact_bp(120000, [(400000, 30), (400000, 100), (200000, 75)], 12000 + 14400)
need = (cet1_for_minima(R, AT1, T2) + CCB * R) / R
loss_formula = CET1 - need * R
lo, hi = 0, 120000
while lo < hi:
    mid = (lo + hi) // 2
    lo, hi = (mid + 1, hi) if keep_by_dollars(120000 - mid, r_k) == 0.0 else (lo, mid)
loss_bisect = lo / 1000.0
grow_formula = CET1 / (need * R) - 1.0
grow_bisect = bisect(lambda g: keep_by_table(CET1, R * (1 + g)) - 0.2, 0.0, 0.4)
mixed_a1, mixed_t2 = 15.0, 20.0
mixed_need = (cet1_for_minima(R, mixed_a1, mixed_t2) + CCB * R) / R
mixed_scan = (cet1_for_minima_scan(r_k, 15000, 20000) + 25 * r_k // 1000) / r_k

assert rem == 0 and abs(100 * ratio1 - bp / 100) < 1e-12, "road 1 against the exact integer road"
assert abs(ratio2 - ratio1) < 1e-12, "charges road against the weights road"
assert abs(mixed_need - mixed_scan) < 1e-12, "CET1 need, mixed bank: max formula against the scan"
assert abs(need - (cet1_for_minima_scan(r_k, 0, 0) + 25 * r_k // 1000) / r_k) < 1e-12, "CET1 need, CET1-only bank"
assert abs(loss_formula - loss_bisect) < 1e-9, "breach loss: formula against bisection on the dollar rule"
assert abs(grow_formula - grow_bisect) < 1e-9, "RWA growth: formula against bisection on the table rule"
for tenth in range(0, 401):                        # the two payout roads agree on every loss, 0 to 40m by 0.1m
    assert keep_by_table(CET1 - tenth / 10, R) == keep_by_dollars(120000 - 100 * tenth, r_k), tenth

rows = [
    ("credit RWA, sum of E w", credit), ("market RWA, 12.5 K_M", 12.5 * K_M),
    ("operational charge K_O", K_O), ("operational RWA, 12.5 K_O", 12.5 * K_O),
    ("CET1, C", CET1), ("Tier 1 floor, 6% of RWA", MIN_T1 * R), ("total RWA R, weights", R), ("credit charge, 8% of credit RWA", MIN_TOT * credit),
    ("  8% charges added up", MIN_TOT * R),
    ("CET1 ratio %, road 1 weights", 100 * ratio1), ("CET1 ratio %, road 2 charges", 100 * ratio2),
    ("CET1 ratio %, road 3 exact bp", bp / 100 + rem / r_k / 100),
    ("stack: CET1 minimum 4.5%", MIN_C * R), ("stack: fills AT1 slot 1.5%", (MIN_T1 - MIN_C) * R),
    ("stack: fills Tier 2 slot 2.0%", (MIN_TOT - MIN_T1) * R), ("stack: conservation buffer", CCB * R),
    ("buffer quarter", CCB * R / 4),
    ("stack: cushion above need", CET1 - need * R),
    ("CET1 need %, CET1-only bank", 100 * need), ("CET1 need %, mixed bank, formula", 100 * mixed_need),
    ("CET1 need %, mixed bank, scan", 100 * mixed_scan),
    ("buffer-breach loss, formula", loss_formula), ("buffer-breach loss, bisection", loss_bisect),
    ("minimum-breach loss", CET1 - MIN_TOT * R),
    ("RWA growth to breach %, formula", 100 * grow_formula), ("RWA growth to breach %, bisection", 100 * grow_bisect),
    ("payout at 20m loss, of 10m earnings", 10.0 * (1 - keep_by_table(CET1 - 20, R))),
    ("wrong: divide by loans + book %", 100 * CET1 / 1100.0), ("wrong: credit RWA only %", 100 * CET1 / credit),
    ("wrong: charges not times 12.5 %", 100 * CET1 / (credit + K_M + K_O)),
    ("wrong: 7% read as need, cushion", CET1 - (MIN_C + CCB) * R),
    ("try: CCyB 1%, need %", 100 * (need + 0.01)), ("try: CCyB 1%, cushion", CET1 - (need + 0.01) * R),
    ("try: loss 10 and RWA +5%, ratio %", 100 * (CET1 - 10) / (1.05 * R)),
    ("try: corporates at 75%, ratio %", 100 * CET1 / (R - 100.0)),
]
for name, v in rows:
    print(f"{name:<38} {v:>12.4f}")

print()
print("  loss   CET1   ratio%  table%  keep%  payout%")
for loss in range(0, 45, 5):
    c = CET1 - loss
    k = keep_by_table(c, R)
    q = MIN_C + (c - cet1_for_minima(R, AT1, T2)) / R
    kept = "below min" if k is None else f"{100 * k:5.0f}  {100 * (1 - k):7.0f}"
    print(f"{loss:6d} {c:6.0f} {100 * c / R:8.2f} {100 * q:7.3f}  {kept}")
chart = [keep_by_table(CET1 - 2.5 * i, R) for i in range(17)]
print("chart, loss 0..40 by 2.5 ", " ".join(f"{2.5 * i:g}" for i in range(17)))
print("chart, payout % of earnings", " ".join(f"{100 * (1 - k):.0f}" for k in chart))

print("ALL CHECKS PASS")
