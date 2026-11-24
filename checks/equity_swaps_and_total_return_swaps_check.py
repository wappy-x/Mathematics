# Total return swap on Acme -- the check behind the card.  Standard library only.
# Road 1: the closed forms (fair spread f - b, and the mark).  Road 2: the dealer's hedge
# ledger, cash item by item, on 2,000 random paths, plus bisection on that ledger for the
# spread.  Road 3: the dealer's hedge book at the reset, against the mark.
from math import exp

n, S0 = 10_000.0, 100.0                 # shares, Acme's price at the start: notional 1,000,000
a, L = 0.25, 0.05                       # quarter as a year fraction; SOFR, simple, flat
f, b = 0.004, 0.01                      # dealer's funding spread over SOFR; borrow fee
d = 0.50                                # Acme's dividend per share, paid on each reset date
s_fair = f - b                          # road 1: the fair spread

def hedge_quarter(Sa, Sb, div, Lq, s, fee=b, fund=f):
    # Road 2: the dealer's quarter, one cash item at a time; returns its net cash at the end.
    loan = n * Sa                       # borrow at SOFR + f to buy n shares at the reset
    cash = n * Sb + n * div             # sell the shares at the next reset; dividends received
    cash += n * Sa * a * fee            # fee for lending the shares out over the quarter
    cash -= loan * (1 + a * (Lq + fund))  # repay the loan with interest
    cash -= n * (Sb - Sa) + n * div     # pay the receiver: price return plus dividends
    cash += loan * a * (Lq + s)         # collect the funding leg: SOFR + s on the reset notional
    return cash

def mark(St, tau, N_prev, s, cash_now=0.0):
    # Road 1: value to the receiver, tau years before the next reset.
    owed = N_prev * (1 + a * (L + s))   # the funding leg plus the reset notional, due at the reset
    return (n * St * (1 + tau * (L + s_fair)) + cash_now - owed) / (1 + L * tau)

M = (1 << 64) - 1
state = 88172645463325252
def rnd():                              # xorshift64, the same generator as the Rust check
    global state
    state ^= (state << 13) & M; state ^= state >> 7; state ^= (state << 17) & M
    return (state >> 11) / 9007199254740992.0

def random_path():
    S, out = S0, []
    for _ in range(4):
        z = sum(rnd() for _ in range(12)) - 6.0          # roughly a bell-curve draw
        S1 = S * exp(0.10 * z)                           # 20% a year volatility, one quarter
        out.append((S, S1, rnd(), 0.03 + 0.04 * rnd()))  # dividend 0 to 1, SOFR fixing 3% to 7%
        S = S1
    return out

worst_fair, worst_leak, first = 0.0, 0.0, None
for _ in range(2000):
    p = random_path()
    first = first or p
    worst_fair = max(worst_fair, abs(sum(hedge_quarter(*q, s_fair) for q in p)))
    leak = sum(hedge_quarter(*q, s_fair + 0.001) for q in p)
    worst_leak = max(worst_leak, abs(leak - sum(n * q[0] * a * 0.001 for q in p)))
lo, hi = -0.05, 0.05                    # bisection on the ledger of the first path
for _ in range(100):
    mid = 0.5 * (lo + hi)
    if sum(hedge_quarter(*q, mid) for q in first) < 0: lo = mid
    else: hi = mid
s_bisect = 0.5 * (lo + hi)

N1, S3 = n * S0, 105.0                  # the 3-month reset: Acme at 105, dividend just paid
v3 = mark(S3, 0.0, N1, s_fair, n * d)
book = n * S3 + n * d + N1 * a * b - N1 * (1 + a * (L + f))   # road 3: the dealer's hedge book
v4, tau4 = mark(107.0, 2 / 12, n * S3, s_fair), 2 / 12   # month 4: a new dealer hedges from 107
worst4 = 0.0
for _ in range(100):                    # its book at the reset, item by item, for random endings
    S6, div = 107.0 * exp(0.1 * (rnd() - 0.5)), rnd()
    book4 = n * S6 + n * div + n * 107.0 * tau4 * b - n * 107.0 * (1 + tau4 * (L + f))
    book4 += -(n * (S6 - S3) + n * div) + n * S3 * a * (L + s_fair)
    worst4 = max(worst4, abs(book4 + v4 * (1 + L * tau4)))
F_house = S0 * exp((L + (0.0 - b) - 0.02) * 1.0)               # f = 0: financing at SOFR - 1%
F_noborrow = S0 * exp((L - 0.02) * 1.0)
rows = [
    ("fair spread f - b, %", 100 * s_fair), ("fair spread by bisection on the ledger, %", 100 * s_bisect),
    ("worst |dealer P&L| at fair spread, 2000 paths", worst_fair),
    ("worst |leak - predicted| at fair + 0.10%", worst_leak),
    ("3m: price return", n * (S3 - S0)), ("3m: dividends", n * d),
    ("3m: funding leg SOFR + s", N1 * a * (L + s_fair)),
    ("3m: mark before the exchange", v3), ("3m: dealer's hedge book", book),
    ("3m hedge: fee for lending the shares", N1 * a * b), ("3m hedge: loan repaid", N1 * (1 + a * (L + f))),
    ("3m: mark after the exchange", mark(S3, a, n * S3, s_fair)),
    ("4m: Acme 107 carried to the reset", n * 107.0 * (1 + 2 / 12 * (L + s_fair))),
    ("4m: owed at the reset", n * S3 * (1 + a * (L + s_fair))),
    ("4m: gap at the reset", n * 107.0 * (1 + 2 / 12 * (L + s_fair)) - n * S3 * (1 + a * (L + s_fair))),
    ("4m: SOFR growth to the reset", 1 + L * 2 / 12),
    ("4m: mark, the gap discounted", v4), ("4m: worst |takeover hedge - mark|", worst4),
    ("wrong: spread = dealer funding only", mark(S3, 0.0, N1, f, n * d)),
    ("wrong: dividends left out", mark(S3, 0.0, N1, s_fair)),
    ("wrong: funding leg forgotten", n * (S3 - S0) + n * d),
    ("house: 1y forward financed at SOFR - 1%", F_house), ("house: 1y forward, no borrow fee", F_noborrow),
    ("try: borrow fee 0.25%, fair spread %", 100 * (f - 0.0025)),
    ("try: borrow fee 5%, fair spread %", 100 * (f - 0.05)),
    ("try: dealer funds at SOFR, fair spread %", 100 * (0.0 - b)),
    ("try: Acme at 95 at 3m, mark", mark(95.0, 0.0, N1, s_fair, n * d)),
]
for name, v in rows:
    print(f"{name:<46} {v:>14.4f}")

print()
print("month  Acme  quarter-start notional  mark to the receiver  cash paid at reset")
path = [100, 102, 101, 105, 107, 104, 106, 103, 101, 98, 100, 103, 104]
Nq, total, marks = n * S0, 0.0, []
for m in range(13):
    reset = m > 0 and m % 3 == 0
    St, tau = float(path[m]), 0.0 if reset else (3 - m % 3) / 12.0
    v = mark(St, tau, Nq, s_fair, n * d if reset else 0.0)
    marks.append(v)
    paid = v if reset else 0.0
    total += paid
    print(f"{m:>5} {St:5.0f} {Nq:>23,.2f} {v:>21,.2f} {paid:>19,.2f}")
    if reset: Nq = n * St
print(f"cash to the receiver over the year {total:,.2f}")
print("chart, mark in thousands " + " ".join(f"{v / 1000:.1f}" for v in marks))

assert abs(s_bisect - s_fair) < 1e-12,  "bisection on the hedge ledger lands on f - b"
assert worst_fair < 1e-6,               "the hedge at the fair spread is flat on every path"
assert worst_leak < 1e-6,               "an off-market spread leaks exactly n S a (s - s*) a quarter"
assert abs(v3 - book) < 1e-6,           "the mark at the reset equals the dealer's hedge book"
assert worst4 < 1e-6,                   "between resets: the takeover hedge pays the mark, path by path"
assert abs(v3 - 44_000.0) < 1e-6,       "the card's worked number"
assert abs(F_house - 102.0201) < 1e-4,  "the shelf's house forward"
print("ALL CHECKS PASS")
