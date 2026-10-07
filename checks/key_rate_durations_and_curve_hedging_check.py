# Key-rate durations and curve hedging -- the check behind the card.  Standard library only.
# The curve is bootstrapped from its par quotes; key-rate DV01s are reached by bumping and
# repricing, and separately by mapping each cash flow onto the pillars by hand.  The hedge
# is solved twice (elimination on one matrix, Cramer's rule on the other) and then tested.
from math import exp, log

QUOTES = [0.042, 0.044, 0.0455, 0.0462, 0.0465, 0.0467, 0.0468, 0.0469, 0.0470, 0.0471]
BP, F, C, NB = 0.0001, 10_000_000.0, 0.05, 7          # 1bp; bond face, coupon, years
PILLARS, SWAPS = (2, 5, 10), (2, 5, 10)

D, acc = [], 0.0
for s in QUOTES:                                       # D(n) = (1 - S_n (D(1)+...+D(n-1))) / (1 + S_n)
    D.append((1.0 - s * acc) / (1.0 + s)); acc += D[-1]
Z = [-log(D[i]) / (i + 1) for i in range(10)]          # zero rate for year i+1, continuously compounded

def w(k, t):                                           # tent k: 1 at its pillar, 0 at the neighbours
    lo = PILLARS[k - 1] if k > 0 else None
    hi = PILLARS[k + 1] if k < 2 else None
    p = PILLARS[k]
    if t <= p: return 1.0 if lo is None else max(0.0, (t - lo) / (p - lo))
    return 1.0 if hi is None else max(0.0, (hi - t) / (hi - p))

def flows_bond(): return [(t, F * C + (F if t == NB else 0.0)) for t in range(1, NB + 1)]
def flows_payer(n, k):                                 # pay fixed k, receive floating = +1 now, -1 at n
    return [(t, -k - (1.0 if t == n else 0.0)) for t in range(1, n + 1)]
def pv(flows, z): return sum(cf * exp(-z[t - 1] * t) for t, cf in flows)
def shifted(k, s): return [Z[i] + s * w(k, i + 1) for i in range(10)]

def kr_bump(flows, k):                                 # road 1: tent k up 1bp and down 1bp, reprice
    return -(pv(flows, shifted(k, BP)) - pv(flows, shifted(k, -BP))) / 2.0
def kr_map(flows, k):                                  # road 2: each flow's t*CF*D*1bp, split by tent
    return sum(w(k, t) * t * cf * exp(-Z[t - 1] * t) * BP for t, cf in flows)

par = {n: (1.0 - D[n - 1]) / sum(D[:n]) for n in SWAPS}
bond = flows_bond()
P0 = pv(bond, Z)
print("year  quote %   D(t)        zero %    tent 2  tent 5  tent 10")
for i in range(10):
    print(f"{i + 1:>4}  {100 * QUOTES[i]:6.4f}  {D[i]:.8f}  {100 * Z[i]:7.4f}   "
          + "  ".join(f"{w(k, i + 1):6.2f}" for k in range(3)))
print(f"bond: 10,000,000 face, 5% annual coupon, 7 years; price {P0:,.2f}")
print("year  cash flow      D(t)        t*CF*D*1bp   to 2y     to 5y     to 10y")
for t, cf in bond:
    x = t * cf * D[t - 1] * BP
    print(f"{t:>4}  {cf:>12,.2f}  {D[t - 1]:.8f}  {x:>10,.2f}  "
          + "  ".join(f"{w(k, t) * x:>8,.2f}" for k in range(3)))

KRb = [kr_bump(bond, k) for k in range(3)]
KRm = [kr_map(bond, k) for k in range(3)]
par_dv01 = -(pv(bond, [z + BP for z in Z]) - pv(bond, [z - BP for z in Z])) / 2.0
print("\nkey-rate DV01 of the bond, dollars lost per 1bp rise")
for k in range(3):
    print(f"  {PILLARS[k]:>2}-year pillar   bump {KRb[k]:>10,.2f}   mapped {KRm[k]:>10,.2f}   duration {KRb[k] / (P0 * BP):.4f}")
print(f"  sum of the three {sum(KRb):>10,.2f}   parallel bump of every zero {par_dv01:>10,.2f}   duration {par_dv01 / (P0 * BP):.4f}")

Mb = [[-kr_bump(flows_payer(n, par[n]), k) * 1e6 for n in SWAPS] for k in range(3)]
Mm = [[-kr_map(flows_payer(n, par[n]), k) * 1e6 for n in SWAPS] for k in range(3)]
print("\npay-fixed par swaps, dollars gained per 1bp rise per million, by pillar")
print("pillar      2y swap    5y swap   10y swap")
for k in range(3):
    print(f"{PILLARS[k]:>6}  " + " ".join(f"{Mb[k][j]:>10,.2f}" for j in range(3)))

def gauss(A, b):                                       # elimination with partial pivoting
    n = len(b); M = [row[:] + [b[i]] for i, row in enumerate(A)]
    for c in range(n):
        p = max(range(c, n), key=lambda r: abs(M[r][c])); M[c], M[p] = M[p], M[c]
        for r in range(c + 1, n):
            f = M[r][c] / M[c][c]
            M[r] = [M[r][j] - f * M[c][j] for j in range(n + 1)]
    x = [0.0] * n
    for r in range(n - 1, -1, -1):
        x[r] = (M[r][n] - sum(M[r][j] * x[j] for j in range(r + 1, n))) / M[r][r]
    return x
def det3(m): return (m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0])
                     + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]))
def cramer(A, b):
    d = det3(A)
    return [det3([[b[r] if c == j else A[r][c] for c in range(3)] for r in range(3)]) / d for j in range(3)]

H = [x * 1e6 for x in gauss(Mb, KRb)]                  # dollars of notional, paying fixed
Hc = [x * 1e6 for x in cramer(Mm, KRm)]
print("\nhedge notionals, pay fixed (negative = receive fixed)")
for j in range(3):
    print(f"  {SWAPS[j]:>2}-year swap   elimination {H[j]:>14,.2f}   Cramer {Hc[j]:>14,.2f}")
h10 = par_dv01 / (-sum(kr_bump(flows_payer(10, par[10]), k) for k in range(3)))
print(f"  back substitution: 10y swap covers {H[2] * Mb[1][2] / 1e6:,.2f} of the 5y pillar, leaving {KRb[1] - H[2] * Mb[1][2] / 1e6:,.2f}")
print(f"  one 10-year swap on total DV01 {h10:>14,.2f}   its parallel DV01 per million {par_dv01 / h10 * 1e6:,.2f}")

def pnl(z, hedge):                                     # bond plus pay-fixed swaps, change in value
    v = pv(bond, z) - P0
    for n, h in hedge:
        v += h * (pv(flows_payer(n, par[n]), z) - pv(flows_payer(n, par[n]), Z))
    return v
three, one = list(zip(SWAPS, H)), [(10, h10)]
two, diag = three[1:], [(n, KRb[j] / Mb[j][j] * 1e6) for j, n in enumerate(SWAPS)]
def move(m2, m5, m10): return [Z[i] + BP * (m2 * w(0, i + 1) + m5 * w(1, i + 1) + m10 * w(2, i + 1)) for i in range(10)]
hump = [Z[i] + (10 * BP if i == 6 else 0.0) for i in range(10)]
print("scenario P&L, dollars          bond alone     one swap   5y+10y only   three swaps")
for lab, z in (("parallel +25bp", move(25, 25, 25)), ("steepener 2y -20, 10y +20", move(-20, 0, 20)),
               ("front end 2y +20", move(20, 0, 0)), ("7-year zero alone +10", hump)):
    print(f"  {lab:<26}" + "".join(f"{pnl(z, h):>13,.2f}" for h in ([], one, two, three)))
sizes = [-40, -30, -20, -10, 0, 10, 20, 30, 40]
print("chart, steepener bp  " + " ".join(f"{s:>7d}" for s in sizes))
for lab, h in (("chart, bond alone   ", []), ("chart, one swap     ", one), ("chart, three swaps  ", three)):
    print(lab + " " + " ".join(f"{pnl(move(-s, 0, s), h) / 1e3:>7.2f}" for s in sizes))
def left(hedge): return "  ".join(f"{PILLARS[k]}y {KRb[k] - sum(h * Mb[k][SWAPS.index(n)] / 1e6 for n, h in hedge):>9,.2f}" for k in range(3))
print("what breaks, net key-rate DV01 left after the hedge, dollars per 1bp")
for lab, h in (("one 10y swap on total DV01", one), ("5y and 10y only", two), ("each pillar by its own swap", diag)):
    print(f"  {lab:<28}{left(h)}")

seed, worst = 20260928, [0.0, 0.0, 0.0]
def rnd():                                             # 64-bit linear congruential generator, in [-1, 1)
    global seed
    seed = (seed * 6364136223846793005 + 1442695040888963407) % 2**64
    return (seed >> 11) / 2**52 - 1.0
for _ in range(2000):
    z = move(20 * rnd(), 20 * rnd(), 20 * rnd())
    for i, h in enumerate(([], one, three)): worst[i] = max(worst[i], abs(pnl(z, h)))
print(f"2,000 random pillar moves up to 20bp, worst |P&L|: bond {worst[0]:,.2f}  one swap {worst[1]:,.2f}  three {worst[2]:,.2f}")
print(f"try: 7-year bond at a 3% coupon, 10y pillar DV01 {sum(w(2, t) * t * (F * 0.03 + (F if t == 7 else 0)) * D[t - 1] * BP for t in range(1, 8)):,.2f}")

assert abs(D[4] - 0.79621728) < 5e-9,                        "D(5) must match the swap and bootstrap cards"
assert all(abs(par[n] - QUOTES[n - 1]) < 1e-12 for n in SWAPS), "par formula on D(t) must give back each quote"
assert all(abs(KRb[k] - KRm[k]) < 0.01 for k in range(3)),   "bump road vs cash-flow mapping road"
assert abs(sum(KRb) - par_dv01) < 0.01,                      "tents sum to one, so key rates sum to the parallel DV01"
assert all(abs(H[j] - Hc[j]) < 1.0 for j in range(3)),       "elimination on bump matrix vs Cramer on mapped matrix"
assert worst[2] < 0.01 * worst[0],                           "three-swap hedge must cut every random move by 99%"
print("ALL CHECKS PASS")
