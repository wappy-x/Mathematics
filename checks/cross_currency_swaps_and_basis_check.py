# Cross-currency swap with a basis -- the check behind the card.  Standard library only.
# EUR against USD, 5 years, annual payments, EUR 100m against USD 110m at spot 1.10.
# Road 1: bootstrap the dollar-collateral euro curve from the quoted basis, then the par formula.
# Road 2: a ledger in dollars, every euro flow converted at its FX forward; bisection for the spread.
# Road 3: simulated spot paths, every euro flow converted at the simulated spot.
from math import exp, log, sqrt, cos, pi

S, NF, ND, RD, RF, Q, T = 1.10, 100e6, 110e6, 0.05, 0.03, -0.0015, 5
DD = [exp(-RD * i) for i in range(T + 1)]                # dollar discount factors
PF = [exp(-RF * i) for i in range(T + 1)]                # euro OIS curve, projects the euro fixings
FE = [PF[i - 1] / PF[i] - 1 for i in range(1, T + 1)]    # euro floating rate paid each year
FD = [DD[i - 1] / DD[i] - 1 for i in range(1, T + 1)]    # dollar floating rate paid each year

def bootstrap(q):                       # euro discount factors that make a q-basis swap fair at every maturity
    dx = [1.0]
    for i in range(1, T + 1):
        dx.append(dx[-1] / (1 + FE[i - 1] + q))
    return dx

def par_basis(dx, n=T):                 # road 1: spread that puts the euro leg at par
    return (1 - dx[n] - sum(FE[i - 1] * dx[i] for i in range(1, n + 1))) / sum(dx[1:n + 1])

def ledger(dx, s, x=S, dollar_spread=0.0, principal=True, fx=None):
    # road 2: value in dollars to the euro lender (receives euro leg, pays dollar leg)
    fwd = fx or [x * dx[i] / DD[i] for i in range(T + 1)]
    v = 0.0
    for i in range(1, T + 1):
        v += NF * (FE[i - 1] + s) * fwd[i] * DD[i] - ND * (FD[i - 1] + dollar_spread) * DD[i]
    if principal:
        v += NF * fwd[T] * DD[T] - ND * DD[T] + (ND - NF * S)   # final swap back, plus the start at 1.10
    return v

def bisect(f, lo, hi):
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if (f(lo) < 0) == (f(mid) < 0): lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

DX = bootstrap(Q)
AX, AD, AF = sum(DX[1:]), sum(DD[1:]), sum(PF[1:])
b1 = par_basis(DX)
b2 = bisect(lambda s: ledger(DX, s), -0.01, 0.01)
Y = -log(DX[T]) / T                                        # implied euro rate, continuously compounded
F5, F5CIP = S * DX[T] / DD[T], S * PF[T] / DD[T]
yf_from_fwd = RD - log(F5 / S) / T                          # the implied-yield card's formula
v0_closed = S * NF * (0 - Q) * AX
v0_ledger = ledger(DX, 0.0)
usd_eq_closed = -Q * S * NF * AX / (ND * AD)
usd_eq_bisect = bisect(lambda x: ledger(DX, 0.0, dollar_spread=x), -0.01, 0.01)

# road 3: spot follows a random walk in logs whose average matches the FX forwards (dollar pricing)
state = 20260927
def rnd():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
VOL, PATHS = 0.08, 100000
tot = tot2 = 0.0
for _ in range(PATHS):
    u1, u2 = rnd(), rnd()
    zs = [sqrt(-2 * log(1 - u1)) * cos(2 * pi * u2)]
    for _ in range(T - 1):
        u1, u2 = rnd(), rnd()
        zs.append(sqrt(-2 * log(1 - u1)) * cos(2 * pi * u2))
    for sign in (1, -1):
        lx, leg = log(S), 0.0
        for i in range(1, T + 1):
            lx += (RD - Y - 0.5 * VOL * VOL) + VOL * sign * zs[i - 1]
            leg += NF * ((FE[i - 1] + Q) + (1 if i == T else 0)) * exp(lx) * DD[i]
        tot += leg; tot2 += leg * leg
n = 2 * PATHS
mc = tot / n
se = sqrt(tot2 / n - mc * mc) / sqrt(n)

leg_fwd = S * NF * (sum((FE[i - 1] + Q) * DX[i] for i in range(1, T + 1)) + DX[T])

# what breaks
wb_ois = ledger(PF, Q)                                      # euros discounted on the euro OIS curve
wb_ois_basis = par_basis(PF)
wb_noprin = bisect(lambda s: ledger(DX, s, principal=False), -0.1, 0.1)
DC = [exp(-(RF + Q) * i) for i in range(T + 1)]
wb_cc = ledger(DC, Q)                                       # -15bp read as a continuous-rate shift
wb_usd15 = ledger(DX, 0.0, dollar_spread=-Q)
wb_spot = ledger(DX, Q, fx=[S] * (T + 1))

print("curve by year: t, euro fixing, dollar fixing, D_d, D_x, FX forward, FX forward if CIP held")
for i in range(1, T + 1):
    print(f"  {i}  {FE[i-1]*100:.4f}%  {FD[i-1]*100:.4f}%  {DD[i]:.6f}  {DX[i]:.6f}  {S*DX[i]/DD[i]:.6f}  {S*PF[i]/DD[i]:.6f}")
rows = [
    ("euro coupon rate with basis, f + s (%)", (FE[0] + Q) * 100),
    ("euro coupon paid each year (EUR)", NF * (FE[0] + Q)),
    ("dollar coupon paid each year (USD)", ND * FD[0]),
    ("euro annuity A_x (years)", AX), ("dollar annuity A_d (years)", AD), ("euro OIS annuity (years)", AF),
    ("1 fair basis, par formula (bp)", b1 * 1e4), ("2 fair basis, ledger + bisection (bp)", b2 * 1e4),
    ("3 euro leg in USD, simulated (USD)", mc), ("  simulation standard error (USD)", se),
    ("  euro leg in USD, forwards (USD)", leg_fwd),
    ("implied euro rate y, continuous (%)", Y * 100), ("  y from the 5-year forward (%)", yf_from_fwd * 100),
    ("funding difference y - r_f (bp)", (Y - RF) * 1e4),
    ("5-year forward with basis", F5), ("5-year forward if CIP held", F5CIP), ("  gap (pips)", (F5 - F5CIP) * 1e4),
    ("PV of the basis per year, EUR 150,000 (EUR)", -Q * NF * AX),
    ("value of a zero-basis swap, closed (USD)", v0_closed), ("  same, ledger (USD)", v0_ledger),
    ("dollar-leg equivalent spread, closed (bp)", usd_eq_closed * 1e4),
    ("  same, bisection (bp)", usd_eq_bisect * 1e4),
    ("wrong: euro OIS discounting, swap value (USD)", wb_ois), ("  its fair basis (bp)", wb_ois_basis * 1e4),
    ("wrong: no final principal, fair basis (bp)", wb_noprin * 1e4),
    ("wrong: -15bp as continuous shift (USD)", wb_cc),
    ("wrong: 15bp moved to dollar leg (USD)", wb_usd15),
    ("wrong: euro flows at today's spot (USD)", wb_spot),
]
for name, v in rows:
    print(f"{name:<46} {v:>16.4f}")
print("spot moves (value to euro lender, USD m): spot, whole swap, coupons only")
for x in (1.00, 1.05, 1.10, 1.15, 1.20):
    coup = ledger(DX, Q, x=x, principal=False)
    print(f"  {x:.2f}  {ledger(DX, Q, x=x) / 1e6:8.2f}  {coup / 1e6:8.2f}")
print("basis moves (value of the -15bp swap to euro lender, USD k)")
for qn in (-0.0030, -0.0020, -0.0010, 0.0):
    print(f"  {qn*1e4:6.1f}bp  {ledger(bootstrap(qn), Q) / 1e3:10.1f}")

assert abs(b1 - Q) < 1e-12                                           # bootstrap reproduces the 5-year quote
assert abs(par_basis(DX, 3) - Q) < 1e-12                             # and the 3-year one
assert abs(b2 - b1) < 1e-10                                          # road 2 agrees with road 1
assert abs(mc - NF * S) < 4 * se                                     # road 3: euro leg worth its notional
assert abs(v0_closed - v0_ledger) < 1e-4                             # closed value vs ledger
assert abs(usd_eq_closed - usd_eq_bisect) < 1e-10
assert abs((Y - RF) - log(1 + Q / (1 + FE[0]))) < 1e-12              # funding gap = ln((1+f+s)/(1+f))
assert max(abs(a - b) for a, b in zip(bootstrap(0.0), PF)) < 1e-14   # zero basis gives back the euro curve
print("all checks passed")
