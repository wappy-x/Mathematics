# Reading a currency quote -- the check behind the card.  Standard library only.
# A pair "AB" at price q means: 1 unit of A (the base, the thing) costs q units of B (the money).
# Road 1: the cross-rate formulas written by hand (multiply, divide, invert).
# Road 2: a ledger that walks real amounts through each trade, reading each quote's direction.
# Road 3: every possible loop through the three currencies, tried one by one.
from itertools import permutations

def convert(amount, frm, to, book):
    # Sell `amount` of frm for to, using whichever way round the pair is quoted.
    if frm + to in book: return amount * book[frm + to]     # selling the base: multiply
    if to + frm in book: return amount / book[to + frm]     # buying the base: divide
    raise KeyError(frm + to)

EURUSD, USDJPY, GBPUSD, BROKER = 1.1000, 150.00, 1.2500, 165.50
book = {"EURUSD": EURUSD, "USDJPY": USDJPY, "GBPUSD": GBPUSD, "EURJPY": BROKER}
fair = {"EURUSD": EURUSD, "USDJPY": USDJPY, "GBPUSD": GBPUSD}

# ---- Road 1: formulas ----
usdeur    = 1.0 / EURUSD                    # invert: euros per dollar
eurjpy    = EURUSD * USDJPY                 # USD cancels: (USD/EUR) x (JPY/USD)
eurgbp    = EURUSD / GBPUSD                 # USD on the money side of both: divide
edge      = BROKER / eurjpy - 1.0           # how rich the broker is, as a fraction
pips      = (BROKER - eurjpy) / 0.01        # a yen-pair pip is 0.01
# ---- Road 2: ledger ----
eurjpy_l  = convert(convert(1.0, "EUR", "USD", fair), "USD", "JPY", fair)
eurgbp_l  = convert(convert(1.0, "EUR", "USD", fair), "USD", "GBP", fair)
usdeur_l  = convert(1.0, "USD", "EUR", fair)
jpy0 = 16_500_000.0
usd1 = convert(jpy0, "JPY", "USD", book)    # buy dollars with yen
eur2 = convert(usd1, "USD", "EUR", book)    # buy euros with dollars
jpy3 = convert(eur2, "EUR", "JPY", book)    # sell euros for yen at the broker
profit_l  = jpy3 / jpy0 - 1.0
pip_pnl   = 50 * 0.01 * eur2                # 50 pips on the euros sold, in yen
# ---- Road 3: every loop ----
loops = []
for a, b, c in permutations(["EUR", "USD", "JPY"]):
    end = convert(convert(convert(1.0, a, b, book), b, c, book), c, a, book)
    loops.append((f"{a}>{b}>{c}>{a}", end - 1.0))
best = max(loops, key=lambda t: t[1])      # first winner found, in permutation order

# ---- bid and ask: a dealer buys the base at the bid, sells it at the ask ----
eb, ea, jb, ja = 1.0999, 1.1001, 149.99, 150.01
x_bid, x_ask = eb * jb, ea * ja             # cross: bid x bid, ask x ask
inv_bid, inv_ask = 1.0 / ea, 1.0 / eb       # inverting swaps the sides
inv_bid_l = convert(1.0, "USD", "EUR", {"EURUSD": ea})        # euros got for 1 USD sold to the dealer
inv_ask_l = 1.0 / convert(1.0, "EUR", "USD", {"EURUSD": eb})  # euros paid per USD bought from the dealer
sold = convert(convert(1.0, "EUR", "USD", {"EURUSD": eb}), "USD", "JPY", {"USDJPY": jb})
bought = convert(convert(1.0, "JPY", "USD", {"USDJPY": ja}), "USD", "EUR", {"EURUSD": ea})
profit_sp = BROKER / x_ask - 1.0

# ---- what breaks ----
w_mult  = EURUSD * GBPUSD                   # multiplied where it should divide
w_div   = EURUSD / USDJPY                   # divided where it should multiply
w_ib, w_ia = 1.0 / eb, 1.0 / ea             # inverted without swapping sides
w_pips  = (BROKER - eurjpy) / 0.0001        # counted yen pips at 0.0001
worst = min(loops, key=lambda t: t[1])
up_eur = 1.12 / 1.10 - 1.0                  # EURUSD 1.10 -> 1.12: the euro's gain
dn_usd = (1 / 1.12) / (1 / 1.10) - 1.0      # the same move, the dollar's loss

rows = [
    ("EURUSD, USD per EUR", EURUSD), ("USDJPY, JPY per USD", USDJPY), ("GBPUSD, USD per GBP", GBPUSD),
    ("USDEUR = 1/EURUSD", usdeur), ("  ledger: 1 USD -> EUR", usdeur_l),
    ("EURJPY = EURUSD x USDJPY", eurjpy), ("  ledger: 1 EUR -> USD -> JPY", eurjpy_l),
    ("EURGBP = EURUSD / GBPUSD", eurgbp), ("  ledger: 1 EUR -> USD -> GBP", eurgbp_l),
    ("broker EURJPY", BROKER), ("broker rich by, yen", BROKER - eurjpy), ("broker rich by, pips of 0.01", pips), ("broker rich by, %", 100 * edge),
    ("loop: start JPY", jpy0), ("  -> USD", usd1), ("  -> EUR", eur2), ("  -> JPY", jpy3),
    ("  kept, JPY", jpy3 - jpy0), ("  kept, %", 100 * profit_l), ("  50 pips on the euros, JPY", pip_pnl),
    ("spread: EURUSD bid", eb), ("spread: EURUSD ask", ea), ("spread: USDJPY bid", jb), ("spread: USDJPY ask", ja),
    ("spread: EURJPY bid = bid x bid", x_bid), ("  ledger: sell 1 EUR", sold),
    ("spread: EURJPY ask = ask x ask", x_ask), ("  ledger: buy 1 EUR costs", 1.0 / bought),
    ("spread: USDEUR bid = 1/ask", inv_bid), ("spread: USDEUR ask = 1/bid", inv_ask),
    ("spread: loop kept, %", 100 * profit_sp),
    ("wrong: EURGBP multiplied", w_mult), ("wrong: EURJPY divided", w_div),
    ("wrong: USDEUR bid not swapped", w_ib), ("wrong: USDEUR ask not swapped", w_ia),
    ("wrong: yen pips at 0.0001", w_pips), ("wrong: loop run backwards, %", 100 * worst[1]),
    ("EURUSD 1.10 -> 1.12: euro, %", 100 * up_eur), ("  same move: dollar, %", 100 * dn_usd),
    ("try: USDJPY 140 -> EURJPY", EURUSD * 140.0), ("try: GBPUSD 1.35 -> EURGBP", EURUSD / 1.35),
    ("try: broker 164.50 -> kept, %", 100 * (eurjpy / 164.50 - 1.0)),
]
for name, v in rows:
    print(f"{name:<34} {v:>18.6f}")
print()
print("every loop, starting with 1 unit       kept, %")
for name, p in loops:
    print(f"  {name:<32} {100 * p:>+10.4f}")
print(f"  best: {best[0]}")
qs = [164.00 + 0.25 * i for i in range(9)]
print("chart, broker EURJPY  " + " ".join(f"{q:7.2f}" for q in qs))
print("chart, kept % no sprd " + " ".join(f"{100 * max(q / eurjpy - 1, eurjpy / q - 1):7.2f}" for q in qs))
print("chart, kept % spread  " + " ".join(f"{100 * max(q / x_ask - 1, x_bid / q - 1, 0):7.2f}" for q in qs))

assert abs(eurjpy - eurjpy_l) < 1e-9,                "cross: formula vs ledger"
assert abs(eurgbp - eurgbp_l) < 1e-12,               "divide: formula vs ledger"
assert abs(usdeur - usdeur_l) < 1e-12,               "invert: formula vs ledger"
assert abs(profit_l - edge) < 1e-12,                 "ledger loop keeps what the formula says"
assert abs(best[1] - edge) < 1e-12,                  "search: best loop keeps the formula's edge"
assert sum(p > 0 for _, p in loops) == 3,            "search: one direction wins, from any start"
assert abs(worst[1] - (1 / (1 + edge) - 1)) < 1e-12, "backwards loop loses 1/(1+e) - 1"
assert abs(pip_pnl - (jpy3 - jpy0)) < 1e-6,          "pips x pip size x euros = ledger profit"
assert abs(sold - x_bid) < 1e-9,                     "cross bid: formula vs ledger"
assert abs(1 / bought - x_ask) < 1e-9,               "cross ask: formula vs ledger"
assert abs(inv_bid - inv_bid_l) < 1e-12,             "inverted bid: formula vs ledger"
assert abs(inv_ask - inv_ask_l) < 1e-12,             "inverted ask: formula vs ledger"
assert inv_bid_l < inv_ask_l,                        "inverted quote keeps bid below ask"
assert abs((jpy3 - jpy0) - 50_000.0) < 1e-6,         "the card's loop keeps 50,000 yen"
assert not (165.00 > x_ask or 166.00 < x_bid),     "two-sided broker 165.00/166.00: no loop pays"
print("ALL CHECKS PASS")
