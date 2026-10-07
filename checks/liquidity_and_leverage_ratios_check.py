# Liquidity and leverage ratios -- the check behind the card.  Standard library only.
# One bank, money in millions of dollars.  Every number quoted on the card is printed here.
# Factors: Basel LCR (2013), NSFR (2014), leverage ratio (2017 revision), verified 28 Sep 2026.
ASSETS = {"cash": 80.0, "gov": 170.0, "l2a": 50.0, "l2b": 20.0, "mortgage": 600.0,
          "corp_short": 100.0, "corp_long": 300.0, "trading": 100.0, "other": 30.0}
FUNDING = {"stable": 500.0, "less_stable": 300.0, "corporate": 200.0, "interbank": 100.0,
           "bonds": 200.0, "other": 90.0, "equity": 60.0}
UNDRAWN, LOAN_DUE, RWA = 200.0, 40.0, 500.0     # committed credit lines; loan repayments due in 30 days
RUNOFF = {"stable": 0.05, "less_stable": 0.10, "corporate": 0.40, "interbank": 1.00}
SPREAD = {"stable": 30, "less_stable": 30, "corporate": 10, "interbank": 5}   # days each run takes
ASF = {"stable": 0.95, "less_stable": 0.90, "corporate": 0.50, "interbank": 0.0, "bonds": 1.0,
       "other": 0.0, "equity": 1.0, "interbank_90": 0.0}
RSF = {"cash": 0.0, "gov": 0.05, "l2a": 0.15, "l2b": 0.50, "mortgage": 0.65, "corp_short": 0.50,
       "corp_long": 0.85, "trading": 0.85, "other": 1.0}

def hqla(l1, l2a, l2b):                  # road 1: the Basel formula for the 15% and 40% caps
    adj15 = max(l2b - 15 / 85 * (l1 + l2a), l2b - 15 / 60 * l1, 0.0)
    adj40 = max(l2a + l2b - adj15 - 2 / 3 * l1, 0.0)
    return l1 + l2a + l2b - adj15 - adj40

def hqla_search(l1, l2a, l2b, h=0.05):   # road 2: try every countable amount, keep the largest legal one
    best = 0.0
    for i in range(int(round(l2a / h)) + 1):
        for j in range(int(round(l2b / h)) + 1):
            a, b = i * h, j * h
            tot = l1 + a + b
            if a + b <= 0.40 * tot + 1e-12 and b <= 0.15 * tot + 1e-12:
                best = max(best, tot)
    return best

def ratios(A, F):                        # all three ratios, straight from the definitions
    H = hqla(A["cash"] + A["gov"], 0.85 * A["l2a"], 0.50 * A["l2b"])
    out = sum(RUNOFF.get(k, 0.0) * v for k, v in F.items()) + 0.10 * UNDRAWN
    inflow = 0.50 * LOAN_DUE
    lcr = H / (out - min(inflow, 0.75 * out))
    nsfr = sum(ASF[k] * v for k, v in F.items()) / (sum(RSF[k] * v for k, v in A.items()) + 0.05 * UNDRAWN)
    lev = F["equity"] / (sum(A.values()) + 0.40 * UNDRAWN)
    return H, out, inflow, lcr, nsfr, lev

def stress_path(H, mult):                # road 2 for the LCR: live through the 30 days one day at a time
    stock = [H]
    for d in range(1, 31):
        out = sum(mult * RUNOFF[k] * FUNDING[k] / SPREAD[k] for k in RUNOFF if d <= SPREAD[k])
        out += mult * 0.10 * UNDRAWN / 20 if d <= 20 else 0.0      # credit lines drawn over 20 days
        stock.append(stock[-1] - out + (0.50 * LOAN_DUE if d == 30 else 0.0))   # loans repay on day 30
    return stock

def bisect(f, lo, hi):                   # root finder written out: f(lo) and f(hi) differ in sign
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if (f(lo) > 0) == (f(mid) > 0): lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

H, out, inflow, lcr, nsfr, lev = ratios(ASSETS, FUNDING)
path = stress_path(H, 1.0)
lcr_sim = H / (H - path[30])
lam_closed = (H + inflow) / out
lam_bisect = bisect(lambda m: stress_path(H, m)[30], 0.5, 3.0)
lam_day = H / (sum(RUNOFF[k] * FUNDING[k] * min(29, SPREAD[k]) / SPREAD[k] for k in RUNOFF) + 0.10 * UNDRAWN)
lam_day_b = bisect(lambda m: min(stress_path(H, m)), 0.5, 3.0)   # every day, not just day 30
hard = stress_path(H, 1.5)
dry_day = next(d for d, s in enumerate(hard) if s < 0)
asf = sum(ASF[k] * v for k, v in FUNDING.items())
rsf = sum(RSF[k] * v for k, v in ASSETS.items()) + 0.05 * UNDRAWN
total = sum(FUNDING.values())            # road 2 for the NSFR: start from the whole balance sheet
unstable = sum((1 - ASF[k]) * v for k, v in FUNDING.items())
free = sum((1 - RSF[k]) * v for k, v in ASSETS.items())
nsfr2 = (total - unstable) / (total - free + 0.05 * UNDRAWN)
exp_assets = sum(ASSETS.values()) + 0.40 * UNDRAWN
exp_funding = total + 0.40 * UNDRAWN     # road 2 for the leverage exposure: the funding side
T1 = FUNDING["equity"]
x_closed = (T1 - 0.03 * exp_assets) / 0.97
x_bisect = bisect(lambda x: (T1 - x) / (exp_assets - x) - 0.03, 0.0, T1)

def scen(dA, dF):
    A2, F2 = dict(ASSETS), dict(FUNDING)
    for k, v in dA.items(): A2[k] = A2.get(k, 0.0) + v
    for k, v in dF.items(): F2[k] = F2.get(k, 0.0) + v
    return ratios(A2, F2)

sA = scen({}, {"bonds": -200.0, "interbank": 200.0})                # 1-week money replaces 2-year bonds
sB = scen({"mortgage": 400.0}, {"interbank_90": 400.0})            # mortgages on 90-day interbank money
sC = scen({"gov": 500.0}, {"bonds": 500.0})                         # government bonds bought with bonds

L1, L2A, L2B = ASSETS["cash"] + ASSETS["gov"], 0.85 * ASSETS["l2a"], 0.50 * ASSETS["l2b"]
print(f"{'HQLA: level 1, level 2A, level 2B':<42}{L1:9.2f}{L2A:9.2f}{L2B:9.2f}")
print(f"{'HQLA, cap formula / cap search':<42}{H:9.2f}{hqla_search(L1, L2A, L2B):9.2f}")
a15 = max(60.0 - 15 / 85 * 200.0, 60.0 - 15 / 60 * 100.0, 0.0)
print(f"{'caps bite (100, 100, 60): cuts':<42}{a15:9.2f}{max(160.0 - a15 - 200 / 3, 0.0):9.2f}")
print(f"{'caps bite (100, 100, 60): formula':<42}{hqla(100.0, 100.0, 60.0):9.2f}{hqla_search(100.0, 100.0, 60.0):9.2f}")
names = {"interbank": "interbank", "corporate": "corporate", "less_stable": "less stable retail", "stable": "stable retail"}
for k, v in [(names[k], RUNOFF[k] * FUNDING[k]) for k in names] + [("credit lines", 0.10 * UNDRAWN)]:
    print(f"{'  30-day outflow, ' + k:<42}{v:9.2f}")
print(f"{'outflows, inflows, net':<42}{out:9.2f}{inflow:9.2f}{out - min(inflow, 0.75 * out):9.2f}")
print(f"{'LCR % formula / day-by-day':<42}{100 * lcr:9.2f}{100 * lcr_sim:9.2f}")
print("stress day      " + "".join(f"{d:9d}" for d in range(0, 31, 5)))
print("stock, 1.0x run " + "".join(f"{path[d]:9.2f}" for d in range(0, 31, 5)))
print("stock, 1.5x run " + "".join(f"{hard[d]:9.2f}" for d in range(0, 31, 5)))
print(f"{'lowest stock, day':<42}{min(path):9.2f}{path.index(min(path)):9d}")
print(f"{'largest run: day 30 x2, every day x2':<42}{lam_closed:9.4f}{lam_bisect:9.4f}{lam_day:9.4f}{lam_day_b:9.4f}")
print(f"{'1.5x run: stock day 29, 30; dry day':<42}{hard[29]:9.2f}{hard[30]:9.2f}{dry_day:9d}")
F, A = FUNDING, ASSETS
print(f"{'ASF: long-term, stable, less, corporate':<42}{F['equity'] + F['bonds']:9.2f}{0.95 * F['stable']:9.2f}"
      f"{0.90 * F['less_stable']:9.2f}{0.50 * F['corporate']:9.2f}")
print(f"{'RSF: liquid, mortgage, corp, rest, lines':<42}{0.05 * A['gov'] + 0.15 * A['l2a'] + 0.5 * A['l2b']:9.2f}"
      f"{0.65 * A['mortgage']:9.2f}{0.5 * A['corp_short'] + 0.85 * A['corp_long']:9.2f}"
      f"{0.85 * A['trading'] + A['other']:9.2f}{0.05 * UNDRAWN:9.2f}")
print(f"{'ASF, RSF':<42}{asf:9.2f}{rsf:9.2f}")
print(f"{'NSFR % by factors / by identity':<42}{100 * nsfr:9.2f}{100 * nsfr2:9.2f}")
print(f"{'exposure: on balance sheet, credit lines':<42}{sum(A.values()):9.2f}{0.40 * UNDRAWN:9.2f}")
print(f"{'exposure: asset side / funding side':<42}{exp_assets:9.2f}{exp_funding:9.2f}")
print(f"{'leverage %, CET1 % on RWA 500':<42}{100 * lev:9.2f}{100 * T1 / RWA:9.2f}")
print(f"{'assets per dollar of Tier 1':<42}{exp_assets / T1:9.2f}")
print(f"{'loss that breaches 3%, closed / bisect':<42}{x_closed:9.2f}{x_bisect:9.2f}")
print("scenario: LCR %, NSFR %, leverage %")
for name, s in (("A, 1-week money", sA), ("B, 90-day mortgages", sB), ("C, bonds for bonds", sC)):
    print(f"{'  ' + name:<42}{100 * s[3]:9.2f}{100 * s[4]:9.2f}{100 * s[5]:9.2f}")
wrong = [("wrong: no haircuts on level 2", 100 * (L1 + ASSETS["l2a"] + ASSETS["l2b"]) / (out - inflow)),
         ("wrong: loan inflows at 100%", 100 * H / (out - LOAN_DUE)),
         ("wrong: credit lines left out of lev.", 100 * T1 / sum(ASSETS.values())),
         ("wrong: 90-day money as 50% ASF (B)", 100 * scen({"mortgage": 400.0}, {"corporate": 400.0})[4])]
for name, v in wrong:
    print(f"{name:<42}{v:9.2f}")
tA = scen({}, {"less_stable": -100.0, "stable": 100.0})
tB = scen({"trading": -100.0, "gov": 100.0}, {})
tC = scen({"other": -15.0}, {"equity": -15.0})
print(f"{'try: 100 made stable, LCR NSFR %':<42}{100 * tA[3]:9.2f}{100 * tA[4]:9.2f}")
print(f"{'try: trading into gov, LCR NSFR lev %':<42}{100 * tB[3]:9.2f}{100 * tB[4]:9.2f}{100 * tB[5]:9.2f}")
print(f"{'try: 15 lost, leverage %':<42}{100 * tC[5]:9.2f}")

assert abs(sum(ASSETS.values()) - total) < 1e-9, "balance sheet must balance"
assert abs(lcr - lcr_sim) < 1e-9, "LCR formula vs the day-by-day stress"
assert abs(lam_closed - lam_bisect) < 1e-9, "largest run passing day 30: closed form vs bisection"
assert abs(lam_day - lam_day_b) < 1e-9 and lam_day < lam_closed, "every-day survival: closed vs bisection"
assert abs(hqla(100.0, 100.0, 60.0) - hqla_search(100.0, 100.0, 60.0)) < 0.06, "cap formula vs search"
assert abs(nsfr - nsfr2) < 1e-12, "NSFR: factor sums vs the balance-sheet identity"
assert abs(x_closed - x_bisect) < 1e-9, "breach loss: closed form vs bisection"
for s, i in ((sA, 3), (sB, 4), (sC, 5)): assert [s[3] < 1, s[4] < 1, s[5] < 0.03] == [j == i for j in (3, 4, 5)], "each change fails only its own rule"
print("ALL CHECKS PASS")
