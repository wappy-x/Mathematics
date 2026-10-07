# OIS discounting and collateral -- the check behind the card.  Standard library only.
# Every number quoted on the card is printed here.  Three roads to the swap's value once
# discounting moves to the overnight curve: (1) rebuild the forecasts so every quote is
# still worth zero and add up the discounted coupons, (2) par rate minus fixed rate, times
# the annuity, (3) roll the collateral account back one year at a time.
from math import exp

N, K, S = 10_000_000.0, 0.01, 0.0025                 # notional, the old swap's fixed rate, term-minus-overnight gap
DEP1 = 0.042                                          # one-year deposit, simple rate
PAR = {2: 0.044, 3: 0.0455, 4: 0.0462, 5: 0.0465}     # par swap quotes, annual coupons

L = [1.0, 1.0 / (1.0 + DEP1)]                         # term curve: the old way, one curve does everything
for n in range(2, 6):
    L.append((1.0 - PAR[n] * sum(L[1:n])) / (1.0 + PAR[n]))
D = [L[j] * exp(S * j) for j in range(6)]             # overnight (collateral) curve, 0.25% lower at every date

def forecasts(disc):                                  # index rates that keep every quote at zero on `disc`
    F = [0.0, DEP1]
    for n in range(2, 6):
        F.append((PAR[n] * sum(disc[1:n + 1]) - sum(disc[j] * F[j] for j in range(1, n))) / disc[n])
    return F

def value(disc, F, k):                                # receive floating, pay fixed k, from today
    return N * sum(disc[j] * (F[j] - k) for j in range(1, 6))

F_old, F_new = forecasts(L), forecasts(D)
F_ois = [0.0] + [D[j - 1] / D[j] - 1.0 for j in range(1, 6)]
A_L, A_D = sum(L[1:]), sum(D[1:])
print("year   term L_j   overnight D_j   g_f      g_c      F old %   F new %")
for j in range(1, 6):
    print(f"{j:>4}   {L[j]:.8f}   {D[j]:.8f}   {L[j-1]/L[j]:.6f} {D[j-1]/D[j]:.6f} "
          f"{100*F_old[j]:8.4f}  {100*F_new[j]:8.4f}")
print(f"annuity on the term curve       {A_L:.8f}")
print(f"annuity on the overnight curve  {A_D:.8f}")

# ---- the one-period model: the first coupon alone, paid in one year ----
X = N * (DEP1 - K)
gf, gc = 1.0 + DEP1, D[0] / D[1]
V_none, V_full = X / gf, X / gc
V_half_formula = X / (0.5 * gf + 0.5 * gc)
lo, hi = 0.0, X                                       # bisection on g_f (V - C) = X - g_c C with C = V / 2
for _ in range(200):
    mid = 0.5 * (lo + hi)
    if gf * (mid - 0.5 * mid) - (X - gc * 0.5 * mid) < 0: lo = mid
    else: hi = mid
print()
print(f"one period: coupon X                   {X:14.2f}")
print(f"one period: g_f, g_c                   {gf:.8f}  {gc:.8f}")
print(f"one period: no collateral   X / g_f    {V_none:14.2f}")
print(f"one period: half collateral            {V_half_formula:14.2f}  bisection {0.5*(lo+hi):.2f}")
print(f"one period: full collateral X / g_c    {V_full:14.2f}")
print(f"one period: bought at X / g_f, surplus in a year {X - gc * V_none:10.2f}")

# ---- the seasoned swap: three roads to the new value ----
V_old = value(L, F_old, K)
V1 = value(D, F_new, K)
V2 = N * (PAR[5] - K) * A_D
V3 = 0.0
for j in range(5, 0, -1):                             # road 3: collateral account, rolled back a year at a time
    V3 = (N * (F_new[j] - K) + V3) / (D[j - 1] / D[j])
print()
print(f"swap, old single curve                 {V_old:14.2f}")
print(f"swap, old way by par-minus-fixed       {N * (PAR[5] - K) * A_L:14.2f}")
print(f"road 1: new forecasts, overnight disc  {V1:14.2f}")
print(f"road 2: (par - fixed) x N x annuity    {V2:14.2f}")
print(f"road 3: collateral rolled back         {V3:14.2f}")
print(f"the move when discounting switches     {V1 - V_old:14.2f}")
print(f"the move, to the nearest thousand      {1000.0 * round((V1 - V_old) / 1000.0):14.2f}")
print(f"par minus fixed, S_5 - K               {PAR[5] - K:14.4f}")

# ---- the collateral ledger, year by year, with values from direct sums ----
def value_at(i):                                      # value just after year i's coupon, summed directly
    return N * sum(D[j] / D[i] * (F_new[j] - K) for j in range(i + 1, 6))
print("year   coupon in      collateral+interest out   new collateral in   |net|")
worst = 0.0
for i in range(1, 6):
    cpn, back, new = N * (F_new[i] - K), D[i - 1] / D[i] * value_at(i - 1), value_at(i)
    worst = max(worst, abs(cpn - back + new))
    print(f"{i:>4}   {cpn:12.2f}   {back:24.2f}   {new:17.2f}   {abs(cpn - back + new):6.2f}")
bars = [N * (D[j] * (F_new[j] - K) - L[j] * (F_old[j] - K)) for j in range(1, 6)]
print("the move, year by year: " + "  ".join(f"{b:.2f}" for b in bars))

# ---- what breaks ----
print()
print(f"wrong: new discount, old forecasts     {value(D, F_old, K):14.2f}")
print(f"wrong: forecast off overnight curve    {value(D, F_ois, K):14.2f}")
print(f"wrong: collateral earns no interest    {N * sum(F_new[j] - K for j in range(1, 6)):14.2f}")
print(f"house swap at 4.50%: old {value(L, F_old, 0.045):.2f}  new {value(D, F_new, 0.045):.2f}"
      f"  move {value(D, F_new, 0.045) - value(L, F_old, 0.045):.2f}")
print(f"try: gap 0.50%, fixed 1.00%: move {N * (PAR[5] - K) * (sum(L[j] * exp(0.005 * j) for j in range(1, 6)) - A_L):.2f}")
print(f"try: fixed 8.00%: move {value(D, F_new, 0.08) - value(L, F_old, 0.08):.2f}")
ks = [0.0, 0.01, 0.02, 0.03, 0.04, 0.045, 0.05, 0.06]
print("chart, fixed rate %   " + " ".join(f"{100*k:8.2f}" for k in ks))
print("chart, move           " + " ".join(f"{value(D, F_new, k) - value(L, F_old, k):8.2f}" for k in ks))

assert abs(V1 - V2) < 1e-6,                           "rebuilt forecasts vs par-minus-fixed times annuity"
assert abs(V3 - V1) < 1e-6,                           "collateral roll-back vs discounted sum"
assert max(abs(F_old[j] - (L[j - 1] / L[j] - 1.0)) for j in range(1, 6)) < 1e-12, "single curve: forecasts are its own forwards"
assert abs(0.5 * (lo + hi) - V_half_formula) < 1e-6,  "bisection vs the partial-collateral formula"
assert worst < 1e-6,                                  "collateral ledger nets to zero every year"
assert abs((V1 - V_old) - 12000.0) < 500.0,           "the move is about 12,000"
print("ALL CHECKS PASS")
