# Stock borrow and repo -- the check behind the card.  Standard library only, and
# nothing imported that already holds the answer: the random numbers, the option
# integrals (Simpson's rule) and the root finder are all written out here.
# Acme trades at 100.00, the bank rate is 5%, the dividend yield 2%, the fee to
# borrow the share 1% a year, delivery one year out.  Four roads to one forward.
import math

S, r, q, b, T = 100.0, 0.05, 0.02, 0.01, 1.0

def fwd(S, r, q, b, T):
    """Road 1, the formula: spot carried at the bank rate less dividend less fee."""
    return S * math.exp((r - q - b) * T)

def rng(seed):
    """A small linear congruential generator, then Box-Muller for bell-curve draws."""
    while True:
        seed = (seed * 6364136223846793005 + 1442695040888963407) % 2**64
        u1 = (seed >> 11) / 2**53 + 1e-300
        seed = (seed * 6364136223846793005 + 1442695040888963407) % 2**64
        u2 = (seed >> 11) / 2**53
        yield math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)

def ledger(seed, fee, side, days=365, sigma=0.3):
    """Roads 2 and 3: run the hedge day by day down a random Acme path.
    Long: borrow cash at r, buy shares, lend them out; dividends and fee buy more.
    Short: borrow shares and sell them; the cash stays with the lender as collateral
    and earns the rebate r - fee; dividends owed are paid by shorting a sliver more.
    Returns the break-even forward (cash per share at delivery) and the last price."""
    dt, z, price = T / days, rng(seed), S
    grow = q + fee if side == "long" else q          # what the share count grows by
    rate = r if side == "long" else r - fee          # what the cash grows at
    shares = math.exp(-grow * T)             # start small, grow into one share
    cash = shares * price                    # loan (long) or collateral (short)
    for _ in range(days):
        price *= math.exp((r - q - 0.5 * sigma**2) * dt + sigma * math.sqrt(dt) * next(z))
        cash *= math.exp(rate * dt)
        income = shares * price * (math.exp(grow * dt) - 1)   # cash value, this day
        shares += income / price             # bought (long) or owed (short)
    assert abs(shares - 1) < 1e-12           # exactly one share at delivery
    return cash, price

def simpson(f, a, c, n=2000):
    h = (c - a) / n
    s = f(a) + f(c) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))
    return s * h / 3

def option(K, kind, rr, carry, sigma=0.2):
    """Road 4's inputs: a call or put priced by averaging its payoff over the bell
    curve, never by a closed form.  'carry' is everything the share pays its holder."""
    m, v = math.log(S) + (rr - carry - 0.5 * sigma**2) * T, sigma * math.sqrt(T)
    dens = lambda z: math.exp(-z * z / 2) / math.sqrt(2 * math.pi)
    zk = (math.log(K) - m) / v               # split at the kink, so Simpson is exact-ish
    if kind == "call":
        f, a, c = (lambda z: (math.exp(m + v * z) - K) * dens(z)), zk, 10.0
    else:
        f, a, c = (lambda z: (K - math.exp(m + v * z)) * dens(z)), -10.0, zk
    return math.exp(-rr * T) * simpson(f, a, c)

def bisect(g, lo, hi):
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if g(lo) * g(mid) > 0 else (lo, mid)
    return 0.5 * (lo + hi)

out = lambda label, x, d=4: print(f"{label:<46}{x:>14.{d}f}")
print("Acme 100.00, r 5%, q 2%, borrow fee 1%, T 1 year")
F, F0 = fwd(S, r, q, b, T), fwd(S, r, q, 0, T)
out("forward with the borrow fee", F); out("forward ignoring the fee", F0)
out("gap the fee makes", F0 - F)
out("share fraction to buy, exp(-(q+b)T)", math.exp(-(q + b) * T), 6)
out("cost of that fraction, prepaid forward", S * math.exp(-(q + b) * T))
out("repo rate rho = r - b, percent", 100 * (r - b))
out("forward as S exp((rho - q)T)", S * math.exp((r - b - q) * T))
assert abs(F - 102.0201) < 5e-5 and abs(F0 - 103.0455) < 5e-5

print("roads 2 and 3: day-by-day ledgers on random paths, sigma 30%")
for seed in (1, 2, 3):
    c_long, p_end = ledger(seed, b, "long")
    c_short, _ = ledger(seed, b, "short")
    print(f"  path {seed}: Acme ends {p_end:8.2f}  long break-even {c_long:9.4f}"
          f"  short break-even {c_short:9.4f}")
    assert abs(c_long - F) < 1e-6 and abs(c_short - F) < 1e-6

print("arbitrage ledgers, profit on delivery day")
out("  quote 103.0455 (fee ignored): carry and lend", F0 - F)
out("  quote 101.0000: short, pay the fee", F - 101.0)
lo_, hi_ = fwd(S, r, q, 0.010, T), fwd(S, r, q, 0.008, T)
out("band, shorts pay 1.00%: lowest forward", lo_)
out("band, lenders get 0.80%: highest forward", hi_)
assert lo_ < F0 and lo_ < hi_ < F0

print("inverse 1: a listed forward 102.0201, SOFR 5%, known dividend 2%")
Fq = 102.0201
carry = math.log(Fq / S) / T
out("carry ln(F/S)/T, percent", 100 * carry)
out("implied yield r - carry, percent", 100 * (r - carry))
out("implied repo rho = q + carry, percent", 100 * (q + carry))
b_log = r - q - carry
b_bis = bisect(lambda x: fwd(S, r, q, x, T) - Fq, -0.5, 0.5)
out("implied borrow fee, by logarithm, percent", 100 * b_log)
out("implied borrow fee, by bisection, percent", 100 * b_bis)
assert abs(b_log - 0.01) < 1e-5 and abs(b_bis - b_log) < 1e-9

print("inverse 2: box spread and parity, options priced with r 5%, q+b 3%")
g = {}
for K in (90, 100, 110):
    c, p = option(K, "call", r, q + b), option(K, "put", r, q + b)
    g[K] = c - p
    print(f"  strike {K}: call {c:8.4f}  put {p:8.4f}  call - put {g[K]:8.4f}")
D = (g[90] - g[110]) / 20
rb = -math.log(D) / T
Fb = 100 + g[100] / D
out("box: discount factor D", D, 6); out("box: rate -ln(D)/T, percent", 100 * rb)
out("parity at 100: forward 100 + (C - P)/D", Fb)
out("implied repo q + ln(F/S)/T, percent", 100 * (q + math.log(Fb / S) / T))
out("implied borrow fee, percent", 100 * (rb - q - math.log(Fb / S) / T))
assert abs(rb - r) < 1e-6 and abs(Fb - F) < 1e-5
assert abs(rb - q - math.log(Fb / S) / T - b) < 1e-6

print("what breaks")
out("  fee left out", F0)
out("  fee added to the cost of carry", fwd(S, r, q, -b, T))
out("  whole implied yield read as dividend, %", 100 * (r - carry))
out("  dividend forgotten, fee read as, %", 100 * (r - carry))
out("  short-dated 1-month quote 0.01 low: fee, %", 100 * (r - q - math.log(
    (fwd(S, r, q, b, 1 / 12) - 0.01) / S) * 12))

print("how it moves: one-year forward against the fee")
for fee in (0.0, 0.01, 0.05, 0.10, 0.25):
    out(f"  fee {100 * fee:5.1f}%", fwd(S, r, q, fee, T), 2)
print("chart, years      " + "".join(f"{t:>8d}" for t in range(6)))
print("chart, no fee     " + "".join(f"{fwd(S, r, q, 0, t):8.2f}" for t in range(6)))
print("chart, fee 1%     " + "".join(f"{fwd(S, r, q, b, t):8.2f}" for t in range(6)))
print("ALL CHECKS PASS")
