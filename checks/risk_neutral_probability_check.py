# The risk-neutral probability -- the check behind the card.  Nothing is
# imported that already knows an option price.  One year, one step, on the
# house market: Acme at 100, strike 100, cash paying 5 percent, a 2 percent
# dividend yield, 20 percent volatility.  The weight q is found twice, the put
# is priced twice, and the no-arbitrage claim is tested market by market.
from math import exp, sqrt

S, K, r, y, sigma, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0   # the house market
u, d = exp(sigma * sqrt(T)), exp(-sigma * sqrt(T))           # up and down factors
R, bank = exp((r - y) * T), exp(r * T)                       # share factor, cash factor

def bisect(f, lo, hi, rounds=200):          # our own root finder: halve the bracket
    for _ in range(rounds):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if (f(lo) > 0) == (f(mid) > 0) else (lo, mid)
    return 0.5 * (lo + hi)

def solve2(a11, a12, a21, a22, b1, b2):     # two equations, two unknowns: Cramer's rule
    det = a11 * a22 - a12 * a21
    return (b1 * a22 - a12 * b2) / det, (a11 * b2 - b1 * a21) / det

def copy_cost(pay_u, pay_d, ignored_p=None):   # shares + cash that match both payoffs
    sh, cs = solve2(S * u * exp(y * T), bank, S * d * exp(y * T), bank, pay_u, pay_d)
    return sh, cs, sh * S + cs                 # the real-world odds are never consulted

def weighted(pay_u, pay_d, w):              # discounted average, weight w on the up branch
    return (w * pay_u + (1.0 - w) * pay_d) / bank

def one(name, v): print(f"{name:<44}{v:>14.6f}")

put_u, put_d = max(K - S * u, 0.0), max(K - S * d, 0.0)
call_u, call_d = max(S * u - K, 0.0), max(S * d - K, 0.0)
q = (R - d) / (u - d)                                           # road 1: the formula
q_bis = bisect(lambda w: w * u + (1.0 - w) * d - R, -2.0, 2.0)  # road 2: solve for it
put_q = weighted(put_u, put_d, q)                               # road 1: the q-average
sh, cs, put_copy = copy_cost(put_u, put_d)                      # road 2: the copy's bill
call_q = weighted(call_u, call_d, q)
parity_left, parity_right = call_q - put_q, S * exp(-y * T) - K * exp(-r * T)

print("Acme, one year, one step: S 100, K 100, r 5 percent, dividend 2 percent, vol 20 percent")
one("u, the up factor", u)
one("d, the down factor", d)
one("u - d, the width of the fork", u - d)
one("R, the share's growth factor e^((r-y)T)", R)
one("R - d, how far R sits above the down factor", R - d)
one("the bank's growth factor e^(rT)", bank)
one("up node, S times u", S * u)
one("down node, S times d", S * d)
one("put payoff up, max(K - Su, 0)", put_u)
one("put payoff down, max(K - Sd, 0)", put_d)
one("call payoff up, max(Su - K, 0)", call_u)
one("1 q by the formula (R - d)/(u - d)", q)
one("2 q by bisection on q u + (1-q) d = R", q_bis)
one("  1 - q, the weight on the down branch", 1.0 - q)
one("3 put by the discounted q-average", put_q)
one("4 put by the copy, shares plus cash", put_copy)
one("  shares in the copy", sh)
one("  cash in the copy", cs)
one("5 call by the discounted q-average", call_q)
one("  call minus put", parity_left)
one("  S e^(-yT) - K e^(-rT)", parity_right)
one("6 q-average of the share, q Su + (1-q) Sd", q * S * u + (1.0 - q) * S * d)
one("  the same, discounted at the bank rate", (q * S * u + (1.0 - q) * S * d) / bank)
one("  S e^(-yT), the prepaid share", S * exp(-y * T))

print("real-world odds move the guess, not the copy's bill:")
print(f"{'p, the real chance of an up move':<34}{'copy cost':>12}{'p-average of the put':>22}")
for p in (0.30, 0.50, 0.70):
    print(f"{p:<34.2f}{copy_cost(put_u, put_d, p)[2]:>12.6f}{weighted(put_u, put_d, p):>22.6f}")

print("borrow S e^(-yT), hold one share, owe S R at the end.  Gains, by state:")
print(f"{'u':>8}{'d':>8}{'R':>8}{'q':>9}{'up':>9}{'down':>9}   the free trade, if any")
for uu, dd, RR in [(u, d, R), (u, d, 1.30), (u, d, 0.80), (u, d, u), (1.10, 0.95, R), (u, d, d)]:
    qq = (RR - dd) / (uu - dd)
    up_gain, down_gain = S * uu - S * RR, S * dd - S * RR
    if min(up_gain, down_gain) >= 0.0 and max(up_gain, down_gain) > 0.0:
        move = "borrow the cash, hold the share"
    elif max(up_gain, down_gain) <= 0.0 and min(up_gain, down_gain) < 0.0:
        move = "short the share, lend the cash"
    else:
        move = "none: each trade loses in one state"
    print(f"{uu:>8.4f}{dd:>8.4f}{RR:>8.4f}{qq:>9.4f}{up_gain:>9.2f}{down_gain:>9.2f}   {move}")
    assert (0.0 < qq < 1.0) == (dd < RR < uu)
    if 0.0 < qq < 1.0:
        assert min(up_gain, down_gain) < 0.0 < max(up_gain, down_gain)
    else:
        assert min(up_gain, down_gain) >= 0.0 or max(up_gain, down_gain) <= 0.0
        assert max(abs(up_gain), abs(down_gain)) > 0.0

print("the weight drifts towards a half as the step shrinks:")
print(f"{'steps in the year':>18}{'u':>12}{'d':>12}{'q':>12}")
fine = []
for n in (1, 2, 4, 12, 252):
    dt = T / n
    un, dn = exp(sigma * sqrt(dt)), exp(-sigma * sqrt(dt))
    fine.append((exp((r - y) * dt) - dn) / (un - dn))
    print(f"{n:>18d}{un:>12.6f}{dn:>12.6f}{fine[-1]:>12.6f}")

q_nodiv = (bank - d) / (u - d)
one("wrong: the real odds p = 0.70 as the weight", weighted(put_u, put_d, 0.70))
one("wrong: no dividend, q = (e^(rT) - d)/(u - d)", q_nodiv)
one("  the put it gives", weighted(put_u, put_d, q_nodiv))
one("wrong: q and 1 - q swapped", weighted(put_u, put_d, 1.0 - q))
one("wrong: the average, never discounted", q * put_u + (1.0 - q) * put_d)

print("chart, R across        " + "".join(f"{0.80 + 0.05 * i:>7.2f}" for i in range(10)))
print("chart, q down          " + "".join(f"{((0.80 + 0.05 * i) - d) / (u - d):>7.2f}" for i in range(10)))
print("the put under weights 0.30, q, 0.50, 0.70 " + "".join(
      f"{weighted(put_u, put_d, w):>8.2f}" for w in (0.30, q, 0.50, 0.70)))

assert abs(q_bis - q) < 1e-12                             # two roads to the weight
assert abs(put_copy - put_q) < 1e-10                      # the copy's bill vs the q-average
assert abs(sh * S * u * exp(y * T) + cs * bank - put_u) < 1e-10      # copy matches up
assert abs(sh * S * d * exp(y * T) + cs * bank - put_d) < 1e-10      # copy matches down
assert abs(parity_left - parity_right) < 1e-10            # an identity the weights never see
assert abs((q * S * u + (1.0 - q) * S * d) / bank - S * exp(-y * T)) < 1e-10   # the share too
assert abs(fine[-1] - 0.5) < abs(fine[0] - 0.5)           # finer steps, flatter weight
print("ALL CHECKS PASS")
