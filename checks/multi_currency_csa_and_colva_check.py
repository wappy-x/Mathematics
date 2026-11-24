# Multi-currency CSA and ColVA -- the check behind the card.  Standard library only.
# A 5-year USD swap whose CSA lets the poster deliver USD cash (earns SOFR) or EUR cash
# (earns ESTR, worth SOFR + s in dollars).  The spread s is normal: today 10 bp, vol 15 bp a year.
# Road 1: Bachelier on each instant, integrated by Simpson.  Road 2: quadrature over the bell
# curve.  Road 3: Monte Carlo spread paths.  Nothing imported knows the answer.
from math import exp, sqrt, pi, log, cos

def phi(x): return exp(-x * x / 2) / sqrt(2 * pi)
def N(x):  # normal CDF, Hart's rational approximation (double precision)
    a = abs(x); e = exp(-a * a / 2)
    if a > 37: c = 0.0
    elif a < 7.07106781186547:
        p = (((((0.0352624965998911 * a + 0.700383064443688) * a + 6.37396220353165) * a + 33.912866078383) * a + 112.079291497871) * a + 221.213596169931) * a + 220.206867912376
        s = ((((((0.0883883476483184 * a + 1.75566716318264) * a + 16.064177579207) * a + 86.7807322029461) * a + 296.564248779674) * a + 637.333633378831) * a + 793.826512519948) * a + 440.413735824752
        c = e * p / s
    else: c = e / (a + 1 / (a + 2 / (a + 3 / (a + 4 / (a + 0.65))))) / 2.506628274631
    return 1 - c if x > 0 else c

def simpson(f, a, b, n):
    h = (b - a) / n
    return h / 3 * sum((1 if i in (0, n) else 4 if i % 2 else 2) * f(a + i * h) for i in range(n + 1))

SOFR, ESTR, Y = 0.04, 0.02, 0.019        # continuous rates; Y = euro rate implied by the FX forward
S0, SIG = ESTR - Y, 0.0015                # spread of EUR collateral over SOFR today; normal vol a year
NOT, K, T = 100e6, 0.05, 5                # notional, fixed rate received, years
g = exp(SOFR) - 1                         # SOFR compounded over a year: the floating forecast
cf = NOT * (K - g)                        # the bank's net cash flow each year end
bp = 1e-4

def call(t, s0=S0, sig=SIG):  # Bachelier: E[max(s_t, 0)], the switch option's rate at date t
    sd = sig * sqrt(t)
    if sd == 0: return max(s0, 0.0)
    return s0 * N(s0 / sd) + sd * phi(s0 / sd)

def M(t, s0=S0, sig=SIG):  # integral of the switch rate from 0 to t: the CTD curve's extra yield,
    # over w = sqrt(u), which smooths the sqrt(u) kink at the start: du = 2w dw
    return simpson(lambda w: 2 * w * call(w * w, s0, sig), 0.0, sqrt(t), 2000) if t > 0 else 0.0

def D(i): return exp(-SOFR * i)
def value(extra): return sum(cf * D(i) * exp(-extra(i)) for i in range(1, T + 1))
def colva(s0, sig): return value(lambda i: M(i, s0, sig)) - value(lambda i: 0.0)

print(f"EUR collateral in dollars: ESTR + (SOFR - implied) {100 * (ESTR + SOFR - Y):.4f}%")
print(f"  FX swap pickup, SOFR - implied euro rate, % {100 * (SOFR - Y):.4f}")
print(f"spread over SOFR today, bp                    {S0 / bp:.2f}")
print(f"floating forecast g, %                        {100 * g:.4f}")
print(f"net cash flow a year, dollars                 {cf:.2f}")

# ---- One period: the poster of collateral against the first cash flow picks the higher rate ----
usd1, eur1 = cf * exp(-SOFR), cf * exp(-(SOFR + S0))
print(f"first cash flow valued with USD collateral    {usd1:.2f}")
print(f"first cash flow valued with EUR collateral    {eur1:.2f}")
print(f"  poster's saving by delivering EUR           {usd1 - eur1:.2f}")

print(f"sigma sqrt(t), bp, and d at 1 and 5 years    {SIG / bp:.2f} {S0 / SIG:.4f}  {SIG * sqrt(5) / bp:.2f} {S0 / (SIG * sqrt(5)):.4f}")
# ---- Road 2: E[max(s_t, 0)] by Simpson over the spread's bell curve, no Bachelier formula ----
print("year  switch rate bp: Bachelier  quadrature  intrinsic   time value")
for t in range(1, T + 1):
    sd = SIG * sqrt(t)
    q = simpson(lambda x: x * phi((x - S0) / sd) / sd, 0.0, S0 + 12 * sd, 4000)
    assert abs(q - call(t)) < 1e-12
    print(f"  {t}       {call(t) / bp:10.4f}  {q / bp:10.4f}  {max(S0, 0) / bp:9.4f}  {(call(t) - max(S0, 0)) / bp:9.4f}")

# ---- Road 3: Monte Carlo spread paths, weekly, antithetic pairs ----
st = 0x2545F4914F6CDD1D; MASK = (1 << 64) - 1
def unif():  # xorshift64*, top 53 bits, never 0
    global st
    st ^= st >> 12; st ^= (st << 25) & MASK; st ^= st >> 27
    return ((((st * 2685821657736338717) & MASK) >> 11) + 0.5) / 9007199254740992.0

STEPS, PAIRS = 52, 10000; dt = 1 / STEPS; sq = SIG * sqrt(dt)
sumf = [0.0] * (T + 1); sumf2 = [0.0] * (T + 1); sumI = 0.0; sumI2 = 0.0; sumE = 0.0
sumY = [0.0] * (T + 1); sumY2 = [0.0] * (T + 1)   # each path's extra yield I to year i, and I^2
for p in range(PAIRS):
    a = b = S0; Ia = Ib = Ea = Eb = 0.0
    for k in range(1, STEPS * T + 1):
        z = sqrt(-2 * log(unif())) * cos(2 * pi * unif())
        a2, b2 = a + sq * z, b - sq * z
        Ia += (max(a, 0) + max(a2, 0)) * dt / 2; Ib += (max(b, 0) + max(b2, 0)) * dt / 2
        Ea += (a + a2) * dt / 2; Eb += (b + b2) * dt / 2
        a, b = a2, b2
        if k % STEPS == 0:
            i = k // STEPS; f = (exp(-Ia) + exp(-Ib)) / 2
            sumf[i] += f; sumf2[i] += f * f; sumY[i] += Ia + Ib; sumY2[i] += Ia * Ia + Ib * Ib
    x = (Ia + Ib) / 2; sumI += x; sumI2 += x * x; sumE += (exp(-Ea) + exp(-Eb)) / 2
mc = [0.0] + [sumf[i] / PAIRS for i in range(1, T + 1)]
se = [0.0] + [sqrt((sumf2[i] / PAIRS - mc[i] ** 2) / PAIRS) for i in range(1, T + 1)]
mI = sumI / PAIRS; seI = sqrt((sumI2 / PAIRS - mI * mI) / PAIRS)
cvx = [0.0] + [exp(-M(i)) * (sumY2[i] / (2 * PAIRS) - (sumY[i] / (2 * PAIRS)) ** 2) / 2 for i in range(1, T + 1)]

print("year  period avg bp   D SOFR      D CTD      MC factor  first order  MC s.e.")
for i in range(1, T + 1):
    f1 = exp(-M(i))
    assert abs(mc[i] - f1) < 4 * se[i] + 2e-6    # convexity is about one standard error
    print(f"  {i}      {(M(i) - M(i - 1)) / bp:7.4f}   {D(i):.8f} {D(i) * f1:.8f}  {mc[i]:.8f} {f1:.8f}  {se[i]:.8f}")
print(f"convexity Var(I)/2 x factor, 5 years, MC     {cvx[T]:.8f}")
print(f"5-year extra yield, integral, bp-years        {M(T) / bp:.4f}")
print(f"  Monte Carlo average, s.e.                   {mI / bp:.4f}  {seI / bp:.4f}")
assert abs(mI - M(T)) < 4 * seI + 2e-7           # weekly trapezoid bias is tiny
eur_exact = exp(-S0 * T + SIG ** 2 * T ** 3 / 6)  # EUR-only CSA: Gaussian integral in closed form
print(f"EUR-only factor at 5 years: closed, MC        {eur_exact:.8f}  {sumE / PAIRS:.8f}")
assert abs(sumE / PAIRS - eur_exact) < 1e-5

V_usd = value(lambda i: 0.0)
V_frozen = value(lambda i: max(S0, 0) * i)
V_ctd = value(lambda i: M(i))
V_mc = sum(cf * D(i) * mc[i] for i in range(1, T + 1))
V_eur = value(lambda i: S0 * i - SIG ** 2 * i ** 3 / 6)
V_recv = value(lambda i: S0 * i - M(i))           # wrong: receiver picks, so min(s, 0)
A = sum(D(i) for i in range(1, T + 1))
annuity_check = NOT * (K - g) * A
assert abs(annuity_check - V_usd) < 1e-6
print(f"swap, USD-only CSA (SOFR)                     {V_usd:.2f}")
print(f"swap, EUR-only CSA                            {V_eur:.2f}")
print(f"swap, choice frozen at today's spread         {V_frozen:.2f}")
print(f"swap, choice with the switch option           {V_ctd:.2f}")
print(f"  same, Monte Carlo factors                   {V_mc:.2f}")
print(f"ColVA = choice minus USD-only                 {V_ctd - V_usd:.2f}")
print(f"  intrinsic part (10 bp frozen)               {V_frozen - V_usd:.2f}")
print(f"  switch option part (time value)             {V_ctd - V_frozen:.2f}")
print(f"  ColVA as running bp on notional             {(V_ctd - V_usd) / (NOT * A) / bp:.4f}")
print(f"  convexity's effect on ColVA, MC Var(I)      {sum(cf * D(i) * cvx[i] for i in range(1, T + 1)):.2f}")
assert V_ctd < V_frozen < V_usd and V_ctd < V_eur
assert abs(V_mc - V_ctd) < 4 * sum(abs(cf) * D(i) * se[i] for i in range(1, T + 1)) + 50
print(f"wrong: receiver chooses (min)                 {V_recv:.2f}")
print(f"  its ColVA                                   {V_recv - V_usd:.2f}")
print(f"wrong: compare raw ESTR with SOFR, ColVA      {value(lambda i: max(ESTR - SOFR, 0) * i) - V_usd:.2f}")
print(f"wrong: 5-year rate for every year, ColVA      {value(lambda i: call(T) * i) - V_usd:.2f}")
for s0, sig in ((0.0010, 0.0), (0.0010, 0.0030), (0.0, 0.0015), (-0.0010, 0.0015)):
    print(f"try: spread {s0 / bp:+3.0f} bp, vol {sig / bp:2.0f} bp, ColVA          {colva(s0, sig):.2f}")
assert abs(colva(0.0010, 0.0) - (V_frozen - V_usd)) < 1e-6
assert abs(M(T, 0.0) - SIG / sqrt(2 * pi) * 2 / 3 * T ** 1.5) < 1e-13   # spread 0: closed form
print("chart, switch rate bp at t = 0, 0.5, ..., 5:")
print("  " + " ".join(f"{call(j / 2) / bp:.2f}" for j in range(11)))
print("ALL CHECKS PASS")
