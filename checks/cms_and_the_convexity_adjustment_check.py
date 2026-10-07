# CMS convexity adjustment -- the check behind the card.  Standard library only.
# One CMS coupon: the 10-year annual swap rate fixed in 5 years, paid 1 year later.
# Roads: (1) static replication in swaptions, (2) direct integral over the rate,
# (3) Monte Carlo with a hand-made generator, (4) the linear quick formula.
from math import exp, log, sqrt, pi, cos

F, SIG, T, N_SWAP, L = 0.045, 0.20, 5.0, 10, 10_000_000.0

def N(x):                                   # normal CDF from its Taylor series
    if x > 9: return 1.0
    if x < -9: return 0.0
    term, total, k = x, x, 0
    while abs(term) > 1e-17 * max(1.0, abs(total)):
        k += 1
        term *= x * x / (2 * k + 1)
        total += term
    return 0.5 + exp(-x * x / 2) / sqrt(2 * pi) * total

def phi(z): return exp(-z * z / 2) / sqrt(2 * pi)
def G(s): return sum((1 + s) ** -i for i in range(1, N_SWAP + 1))   # annuity at rate s
def w(s, d=1): return (1 + s) ** -d / G(s)  # payment bond / annuity, paid d years after fixing
def h(s, d=1): return (s - F) * (w(s, d) - w(F, d))

def second(f, k, e=1e-4): return (f(k + e) - 2 * f(k) + f(k - e)) / (e * e)

def black(k, sig, payer):                   # swaption value in annuity units
    v = sig * sqrt(T)
    d1 = (log(F / k) + v * v / 2) / v
    d2 = d1 - v
    if payer: return F * N(d1) - k * N(d2)
    return k * N(-d2) - F * N(-d1)

def simpson(f, a, b, m):
    step = (b - a) / m
    tot = f(a) + f(b)
    for i in range(1, m):
        tot += (4 if i % 2 else 2) * f(a + i * step)
    return tot * step / 3

def by_strip(sig=SIG, d=1):                 # receivers below F, payers above F
    def otm(k): return black(k, sig, k > F) if k > 0 else 0.0
    def num(k): return second(lambda s: h(s, d), k) * otm(k)
    def den(k): return second(lambda s: w(s, d), k) * otm(k)
    rec, pay = simpson(num, 0.0, F, 600), simpson(num, F, 1.0, 4000)
    bot = w(F, d) + simpson(den, 0.0, F, 600) + simpson(den, F, 1.0, 4000)
    return rec / bot, pay / bot, bot        # adjustment = rec + pay, bot = E[w]

def by_integral(sig=SIG, d=1, f0=F, t=T):
    v = sig * sqrt(t)
    def S(z): return f0 * exp(-v * v / 2 + v * z)
    top = simpson(lambda z: S(z) * w(S(z), d) * phi(z), -9, 9, 4000)
    bot = simpson(lambda z: w(S(z), d) * phi(z), -9, 9, 4000)
    return top / bot - f0

def by_monte_carlo(paths=200_000, seed=20260928):
    x = seed; M = (1 << 64) - 1; v = SIG * sqrt(T)
    def unif():
        nonlocal x
        x ^= (x << 13) & M; x ^= x >> 7; x ^= (x << 17) & M
        return ((x >> 11) + 0.5) / 2.0 ** 53
    sh = sw = sh2 = 0.0
    for _ in range(paths // 2):
        z = sqrt(-2 * log(unif())) * cos(2 * pi * unif())
        for zz in (z, -z):                  # antithetic pair
            s = F * exp(-v * v / 2 + v * zz)
            sh += h(s); sw += w(s); sh2 += h(s) ** 2
    mh, mw = sh / paths, sw / paths
    se = sqrt((sh2 / paths - mh * mh) / paths) / mw
    return mh / mw, se

def quick(sig=SIG, d=1, t=T):               # linear weight: F^2 (e^{sig^2 T} - 1) w'(F)/w(F)
    slope = (w(F + 1e-5, d) - w(F - 1e-5, d)) / 2e-5
    return F * F * (exp(sig * sig * t) - 1) * slope / w(F, d)

bp = 1e4
DU = 1.045 ** -6                            # payment bond on a flat 4.5% annual curve
A0 = sum(1.045 ** -i for i in range(6, 16))
rec, pay, ew = by_strip(); a1 = rec + pay; a2 = by_integral(); a3, se = by_monte_carlo(); a4 = quick()
print(f"inputs: forward, vol, expiry           {F:.3f}  {SIG:.2f}  {T:.1f}")
print(f"payment weight w(F) = D(U)/A0          {w(F):.6f}  {DU / A0:.6f}")
print(f"weight slope w'(F)/w(F)                {(w(F + 1e-5) - w(F - 1e-5)) / 2e-5 / w(F):.6f}")
print(f"annuity at the forward G(F); D(U); A0  {G(F):.6f}  {DU:.6f}  {A0:.6f}")
print(f"e^(sig^2 T) - 1; rate variance F^2(..)  {exp(SIG * SIG * T) - 1:.6f}  {F * F * (exp(SIG * SIG * T) - 1):.8f}")
print(f"parity at k=6%: payer - receiver       {black(0.06, SIG, True) - black(0.06, SIG, False):.8f}")
print(f"1 strip of swaptions, bp               {a1 * bp:.4f}")
print(f"2 direct integral, bp                  {a2 * bp:.4f}")
print(f"3 Monte Carlo 200k paths, bp           {a3 * bp:.4f}  (se {se * bp:.4f})")
print(f"4 linear quick formula, bp             {a4 * bp:.4f}")
print(f"CMS rate, percent                      {(F + a2) * 100:.4f}")
print(f"adjustment on $10m, dollars            {L * DU * a2:.2f}")
print(f"coupon at forward, no adjustment, $    {L * DU * F:.2f}")
print(f"CMS coupon on $10m, dollars            {L * DU * (F + a2):.2f}")
print(f"strip: receivers below F, bp           {rec * bp:.4f}")
print(f"strip: payers above F, bp              {pay * bp:.4f}")
print(f"average weight E[w] under annuity law  {ew:.6f}")
print("expiry sweep, adjustment bp (direct, quick):")
for t in (1, 2, 3, 5, 7, 10):
    print(f"  T = {t:>2}                                {by_integral(t=t) * bp:.2f}  {quick(t=t) * bp:.2f}")
print(f"quick formula shortfall at 5y, 10y, %   {(1 - a4 / a2) * 100:.1f}  {(1 - quick(t=10) / by_integral(t=10)) * 100:.1f}")
print("payoff counted in annuities, S w(S)/w(F) against S, percent:")
for s in (0.01, 0.03, 0.045, 0.07, 0.10, 0.13):
    print(f"  S = {s * 100:>4.1f}                              {s * w(s) / w(F) * 100:.3f}")
up = by_integral(f0=F + 1e-4); dn = by_integral(f0=F - 1e-4)
print(f"delta: CMS rate per 1bp of forward     {(2e-4 + up - dn) / 2e-4:.4f}")
print(f"vega: adjustment bp per vol point      {(by_integral(sig=SIG + 0.005) - by_integral(sig=SIG - 0.005)) * bp:.4f}")
print(f"wrong: no adjustment, bp               {0.0:.4f}")
print(f"wrong: paid on fixing date, bp         {by_integral(d=0) * bp:.4f}")
print(f"wrong: paid at swap's end, bp          {by_integral(d=10) * bp:.4f}")
print(f"try: vol 30%, bp                       {by_integral(sig=0.30) * bp:.4f}")
print(f"try: vol 10%, bp                       {by_integral(sig=0.10) * bp:.4f}")
end = sum(by_strip(d=10)[:2])
print(f"try: strip, paid at swap's end, bp     {end * bp:.4f}")

assert abs(a1 - a2) < 1e-7                  # replication against direct integral
assert abs(a3 - a2) < 4 * se                # simulation against direct integral
assert abs(a4 - a2) < 0.03 * a2             # quick formula within 3 percent
assert abs(black(0.06, SIG, True) - black(0.06, SIG, False) - (F - 0.06)) < 1e-12
assert abs(w(F) - DU / A0) < 1e-12         # flat-curve weight matches today's curve
assert abs(end - by_integral(d=10)) < 1e-7  # replication still holds when the sign flips
assert by_integral(d=10) < 0                # paying late flips the sign
assert by_integral(d=0) > a2                # paying early makes it bigger
print("all checks passed")
