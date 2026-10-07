# Storage and the carry ceiling -- the check behind the card.  Standard library only.
# Wheat at 6.00 a bushel, a 0.30 warehouse bill paid today, 5% a year, one year.
# Road 1 is the formula.  Road 2 grows the cash-and-carry loan in 200,000 slices of
# simple interest.  Road 3 pays storage in kind, a sliver of grain per slice.  Road 4
# simulates delivery-day wheat prices and repays the loan from a home-made e^x series.
from math import exp, log, sqrt, cos, pi

def exp_series(x):                          # e^x from its Taylor series, no library
    term, total, k = 1.0, 1.0, 0
    while abs(term) > 1e-18:
        k += 1; term *= x / k; total += term
    return total

def ceiling(S, U, r, T):                    # road 1: (S + U) e^{rT}
    return (S + U) * exp(r * T)

def loan_by_slices(amount, r, T, n):        # road 2: the loan balance, compounded n times
    bal, dt = amount, T / n
    for _ in range(n): bal *= 1.0 + r * dt
    return bal

def forward_in_kind(S, u, r, T, n):         # road 3: warehouse keeps u*dt of the grain each slice
    left, dt = 1.0, T / n
    for _ in range(n): left *= 1.0 - u * dt
    bushels = 1.0 / left                    # buy this many today so one is left at delivery
    return loan_by_slices(bushels * S, r, T, n)

state = [20260927]
def uniform():                              # 64-bit linear congruential generator
    state[0] = (6364136223846793005 * state[0] + 1442695040888963407) % 2**64
    return ((state[0] >> 11) + 0.5) / 2**53
def normal():                               # Box-Muller
    return sqrt(-2.0 * log(uniform())) * cos(2.0 * pi * uniform())

S, U, r, T, n = 6.00, 0.30, 0.05, 1.0, 200000
F_hi, F_lo, sigma, paths = 6.80, 6.00, 0.25, 20000
C1 = ceiling(S, U, r, T)
C2 = loan_by_slices(S + U, r, T, n)
u = log((S + U) / S)                        # the storage rate that matches a 0.30 bill
C3_formula = S * exp((r + u) * T)
C3_kind = forward_in_kind(S, u, r, T, n)
loan = (S + U) * exp_series(r * T)          # what the carry trade owes at delivery

pnl_hi, pnl_lo = [], []
for _ in range(paths):
    ST = S * exp(-0.5 * sigma * sigma * T + sigma * sqrt(T) * normal())
    pnl_hi.append(ST + (F_hi - ST) - loan)  # sell the stored grain, settle the short forward
    pnl_lo.append(ST - F_lo)                # a grain-less buyer of the 6.00 forward

rows = [
    ("interest factor e^rT", exp(r * T)),
    ("storage bill grown, U e^rT", U * exp(r * T)),
    ("interest on 6.30, (S+U)(e^rT - 1)", (S + U) * (exp(r * T) - 1.0)),
    ("1 ceiling (S+U) e^rT", C1),
    ("2 loan run in 200000 slices", C2),
    ("  storage rate u = ln(6.30/6.00)", u),
    ("3 S e^(r+u)T", C3_formula),
    ("  in kind, 200000 slices", C3_kind),
    ("carry profit at 6.80, formula", F_hi - C1),
    ("4 sim: carry profit at 6.80, min", min(pnl_hi)),
    ("  sim: carry profit at 6.80, max", max(pnl_hi)),
    ("  sim: long 6.00 forward, min", min(pnl_lo)),
    ("  sim: long 6.00 forward, max", max(pnl_lo)),
    ("short sale gain at 6.00, S e^rT - F", S * exp(r * T) - F_lo),
    ("holder's gain at 6.00, ceiling - F", C1 - F_lo),
    ("wrong: no storage, S e^rT", S * exp(r * T)),
    ("wrong: bill not financed", S * exp(r * T) + U),
    ("wrong: u read as 5%", S * exp((r + 0.05) * T)),
    ("wrong: simple interest", (S + U) * (1.0 + r * T)),
    ("try: r = 10%", ceiling(S, U, 0.10, T)),
    ("try: storage 0.60", ceiling(S, 0.60, r, T)),
    ("try: 6 months, bill 0.15", ceiling(S, 0.15, r, 0.5)),
    ("try: wheat 4.00, bill 0.30", ceiling(4.00, U, r, T)),
]
for name, v in rows:
    print(f"{name:<36} {v:>12.6f}")
print()
print("chart, months      " + " ".join(f"{m:6d}" for m in (0, 3, 6, 9, 12)))
print("chart, ceiling     " + " ".join(f"{ceiling(S, U * m / 12, r, m / 12):6.2f}" for m in (0, 3, 6, 9, 12)))
print("chart, spot        " + " ".join(f"{S:6.2f}" for m in (0, 3, 6, 9, 12)))

assert abs(C1 - 6.623007907169) < 1e-9,            "formula vs the hand value 6.30 x 1.0512711"
assert abs(C2 - C1) < 1e-6,                        "sliced loan must land on the formula"
assert abs(C3_kind - C3_formula) < 1e-6,           "storage in kind must land on S e^(r+u)T"
assert abs(min(pnl_hi) - (F_hi - C1)) < 1e-9,      "carry profit is the same on every path"
assert abs(max(pnl_hi) - (F_hi - C1)) < 1e-9,      "...best path included"
assert min(pnl_lo) < 0.0 < max(pnl_lo),            "a forward below the ceiling offers no sure trade"
print("ALL CHECKS PASS")
