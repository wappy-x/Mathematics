# Valuing an old currency forward -- the check behind the card.  Standard
# library only.  Nothing imported holds the answer: the pricing-world average
# is Simpson's rule written out, the discount is also rebuilt by compounding a
# deposit step by step, and the flat rate of a book is found by bisection.
# A year ago: bought EUR 10,000,000 for delivery in 15 months at 1.1500 USD/EUR.
# Today: three months left, spot 1.1000, three-month forward quoted 1.1055.
from math import exp, log, sqrt, pi

A, K, tau = 10_000_000.0, 1.1500, 0.25     # euros bought, contract rate, years left
S, F, rd = 1.1000, 1.1055, 0.05            # spot, today's forward quote, dollar rate
rf = rd - log(F / S) / tau                 # euro rate the quote implies (parity)
F_house = S * exp((rd - 0.03) * tau)       # the shelf's house forward at 3% euros
Dd, Df = exp(-rd * tau), exp(-rf * tau)    # discount factors, dollars and euros

def mark_usd(s, t, a=A, k=K):              # spot form: euros on deposit minus dollar loan
    return a * (s * exp(-rf * t) - k * exp(-rd * t))

# Road 1: the formula, gap to today's forward discounted at the dollar rate
per_eur = (F - K) * Dd
V_usd = A * per_eur
V_eur = V_usd / S                          # restated at today's spot
# Road 2: close out.  Sell EUR 10m forward at 1.1055: the euros cancel and a
# fixed dollar sum is left for delivery day.  Discount it by compounding a
# dollar deposit in 100,000 small steps instead of calling exp.
locked = A * F - A * K
grow = 1.0
for _ in range(100_000):
    grow *= 1.0 + rd * tau / 100_000
V_close = locked / grow
# Road 3: count in euros from the start.  The dollars owed at delivery, turned
# into euros at the forward, then discounted at the euro rate.
locked_eur = A - A * K / F
V_eur_road = locked_eur * Df
# Road 4: the pricing-world average of the payoff, by Simpson, at two vols
def by_simpson(vol, n=4000):
    lo, hi = -10.0, 10.0
    h = (hi - lo) / n
    def f(z):
        ST = S * exp((rd - rf - 0.5 * vol * vol) * tau + vol * sqrt(tau) * z)
        return (ST - K) * exp(-0.5 * z * z) / sqrt(2.0 * pi)
    tot = f(lo) + f(hi)
    for i in range(1, n):
        tot += (4 if i % 2 else 2) * f(lo + i * h)
    return A * exp(-rd * tau) * tot * h / 3.0
V_simp8, V_simp16 = by_simpson(0.08), by_simpson(0.16)
# Road 5: sensitivities by formula, then by nudging the spot form
pip, bp = 0.0001, 0.0001
dF_pip = A * Dd * pip
dS_pip = A * Df * pip
dS_bump = (mark_usd(S + pip, tau) - mark_usd(S - pip, tau)) / 2.0
drd_bp = A * K * tau * Dd * bp
rd_bump = (A * K * exp(-(rd - bp) * tau) - A * K * exp(-(rd + bp) * tau)) / 2.0
drf_bp = -A * S * tau * Df * bp
rf_bump = (A * S * exp(-(rf + bp) * tau) - A * S * exp(-(rf - bp) * tau)) / 2.0
eur_dS = A * K * Dd / (S * S) * pip        # the euro-counted mark moves too
eur_bump = (mark_usd(S + pip, tau) / (S + pip) - mark_usd(S - pip, tau) / (S - pip)) / 2.0
# The book: long EUR 10m at 1.1500, short EUR 4m at 1.1300, same delivery day
legs = [(10_000_000.0, 1.1500), (-4_000_000.0, 1.1300)]
def book(f): return sum(a * (f - k) for a, k in legs) * Dd
F_flat = sum(a * k for a, k in legs) / sum(a for a, _ in legs)
lo, hi = 0.5, 2.0                          # bisection: value rises with f, one root
for _ in range(80):
    mid = 0.5 * (lo + hi)
    lo, hi = (mid, hi) if book(mid) < 0 else (lo, mid)
S_flat = K * exp(-(rd - rf) * tau)         # spot at which the single contract is flat

rows = [("house forward, 3% euros", F_house), ("forward premium ln(F/S)/tau", log(F / S) / tau),
        ("implied euro rate", rf), ("gap F - K", F - K), ("K / F", K / F),
        ("dollar discount", Dd), ("euro discount", Df),
        ("1 per euro, USD", per_eur), ("1 mark, USD", V_usd), ("  restated, EUR", V_eur),
        ("2 USD paid, old contract", A * K),
        ("  USD received, new contract", A * F), ("  locked at delivery, USD", locked), ("  compounded deposit", grow),
        ("  close-out today, USD", V_close), ("3 locked at delivery, EUR", locked_eur),
        ("  counted in euros, EUR", V_eur_road), ("4 Simpson, vol 8%, USD", V_simp8),
        ("  Simpson, vol 16%, USD", V_simp16), ("5 per pip of forward, USD", dF_pip),
        ("  per pip of spot, USD", dS_pip), ("  by bump", dS_bump),
        ("  per bp dollar rate, USD", drd_bp), ("  by bump", rd_bump),
        ("  per bp euro rate, USD", drf_bp), ("  by bump", rf_bump),
        ("  EUR mark per pip of spot", eur_dS), ("  by bump", eur_bump),
        ("6 book value, USD", book(F)), ("  flat forward, weights", F_flat),
        ("  flat forward, bisection", hi), ("  flat spot, one contract", S_flat),
        ("wrong: no discount", locked), ("wrong: euro discount", A * (F - K) * Df),
        ("wrong: spot for forward", A * (S - K) * Dd),
        ("wrong: to EUR at forward", V_usd / F), ("wrong: to EUR at contract", V_usd / K)]
for name, v in rows:
    print(f"{name:<28} {v:>17.6f}")
print()
print("mark in thousands, by spot today (3 months left, at delivery, EUR count)")
for s in (1.06, 1.08, 1.10, 1.12, 1.14, 1.16, 1.18):
    print(f"spot {s:.2f}  {mark_usd(s, tau) / 1e3:9.2f}  {A * (s - K) / 1e3:9.2f}"
          f"  {mark_usd(s, tau) / s / 1e3:9.2f}")
print("mark in thousands USD, spot stuck at 1.1000, by months left")
for m in (3, 2, 1, 0):
    print(f"months {m}  {mark_usd(S, m / 12.0) / 1e3:9.2f}")

assert abs(V_close - V_usd) < 0.01, "close-out by compounding must match the formula"
assert abs(V_eur_road - V_eur) < 0.01, "counting in euros must match the dollar mark over spot"
assert abs(V_simp8 - V_usd) < 0.01, "pricing-world average must match, vol 8%"
assert abs(V_simp16 - V_usd) < 0.01, "pricing-world average must match, vol 16%"
assert abs(dS_bump - dS_pip) < 1e-6, "spot nudge must match the spot slope"
assert abs(rd_bump - drd_bp) < 1e-3, "dollar-rate nudge must match its slope"
assert abs(rf_bump - drf_bp) < 1e-3, "euro-rate nudge must match its slope"
assert abs(eur_bump - eur_dS) < 1e-3, "euro-count nudge must match its slope"
assert abs(hi - F_flat) < 1e-12, "bisection must find the weighted delivery rate"
assert abs(round(F_house, 4) - F) < 1e-12, "the quote is the house forward rounded to the pip"
print("PASS")
