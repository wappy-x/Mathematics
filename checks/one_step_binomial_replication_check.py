# One-step binomial replication -- the check behind the card.  Nothing imported
# knows an option price.  Acme: S = 100, K = 100, one year, r = 5%, q = 2%,
# sigma = 20%, so the share ends at 122.14 or 81.87.  The holding and the bank
# balance that copy the call are found four ways: elimination; a bisection that
# never divides by u - d; the regrouped weights; exact fractions on a toy market.
from math import exp, sqrt

S, K, r, q, sigma, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
u = exp(sigma * sqrt(T))                      # up factor: one year of 20% jumpiness
d = 1.0 / u                                   # down factor
disc, grow = exp(-r * T), exp(r * T)          # the bank, backward and forward
drag = exp(-q * T)                            # shares to buy today to hold one at delivery
Su, Sd = S * u, S * d                         # the two delivery prices
Hu, Hd = max(Su - K, 0.0), max(Sd - K, 0.0)   # the call's two payoffs

def solved(hu, hd, s, uu, dd):                # road 1: subtract, then substitute
    return (hu - hd) / (s * (uu - dd)), disc * (uu * hd - dd * hu) / (uu - dd)

def cost(delta, bank, s=S):                   # what the pair costs today
    return delta * s * drag + bank

def bank_for_down(delta):                     # the cash that matches the down state alone
    return (Hd - delta * Sd) * disc

def up_shortfall(delta):                      # what the up state is then still short
    return delta * Su + bank_for_down(delta) * grow - Hu

def bisect(f, lo, hi):                        # road 2: a search, written out here
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if (f(lo) > 0.0) == (f(mid) > 0.0):
            lo = mid
        else:
            hi = mid
    return 0.5 * (lo + hi)

def reduced(n, m):                            # a fraction in lowest terms
    a, b = abs(n), abs(m)
    while b:
        a, b = b, a % b
    return n // a, m // a

def clean(v):                                 # a residue below a billionth is zero
    return 0.0 if abs(v) < 1e-9 else v

def row(name, v):
    print(f"  {name:<43}{v:>12.6f}")

delta, bank = solved(Hu, Hd, S, u, d)
V = cost(delta, bank)
copy_up, copy_down = delta * Su + bank * grow, delta * Sd + bank * grow
delta_b = bisect(up_shortfall, 0.0, 2.0)                    # road 2
V_b = cost(delta_b, bank_for_down(delta_b))
fwd = exp((r - q) * T)                                      # the forward's growth factor
w_up, w_down = (fwd - d) / (u - d), (u - fwd) / (u - d)     # road 3
V_w = disc * (w_up * Hu + w_down * Hd)
d80, b80 = solved(max(Su - 80.0, 0.0), max(Sd - 80.0, 0.0), S, u, d)  # both states pay
sold = 11.50                                                # a call sold too dear
banked = sold - V
arb_up = copy_up - Hu + banked * grow
arb_down = copy_down - Hd + banked * grow
spread = delta * drag * 0.20                                # a 20-cent wider share price
un, dn, ud, rn, rd, s0, hu0 = 6, 4, 5, 21, 20, 100, 20      # road 4: the toy market
dl_n, dl_d = reduced(hu0 * ud, s0 * (un - dn))
cs_n, cs_d = reduced(-dn * hu0 * rd, rn * (un - dn))
v_n, v_d = reduced(dl_n * s0 * cs_d + cs_n * dl_d, dl_d * cs_d)
wrong_gap = (Hu - Hd) / (u - d)                             # share price left out
wrong_drag = delta * S + bank                               # a whole share per Delta
wrong_face = delta * S * drag + (u * Hd - d * Hu) / (u - d)  # the debt at face value
Sx = S * drag
dx, bx = solved(max(Sx * u - K, 0.0), max(Sx * d - K, 0.0), Sx, u, d)
wrong_twice = (dx * Sx + bx) * drag                         # dividend taken out twice
wrong_coin = disc * 0.5 * (Hu + Hd)                         # a fair coin instead of a hedge

print(f"Acme: S = {S:.2f}  K = {K:.2f}  T = {T:.0f} year  r = 5%  q = 2%  sigma = 20%")
row("up factor u = e^(sigma sqrt T)", u)
row("down factor d = 1/u", d)
row("share at delivery, up state", Su)
row("share at delivery, down state", Sd)
row("the gap between the two, S u - S d", Su - Sd)
row("call payoff, up state", Hu)
row("call payoff, down state", Hd)
print(f"  bank growth e^rT {grow:.6f}, discount e^-rT {disc:.6f}, "
      f"dividend drag e^-qT {drag:.6f}")
print("road 1, the two delivery equations solved")
row("Delta, shares held at delivery", delta)
row("shares bought today, Delta e^-qT", delta * drag)
row("the share leg costs today", delta * S * drag)
row("B, cash in the bank today", bank)
row("the debt at delivery, B e^rT", bank * grow)
row("V, what the pair costs today", V)
row("the copy at delivery, up state", clean(copy_up))
row("the call pays, up state", Hu)
row("the copy at delivery, down state", clean(copy_down))
row("the call pays, down state", Hd)
print("road 2, bisection for Delta, no formula used")
row("Delta", delta_b)
row("V", V_b)
print("road 3, the two payoffs regrouped as weights")
row("weight on the up payoff", w_up)
row("weight on the down payoff", w_down)
row("the two weights add to", w_up + w_down)
row("V", V_w)
row("the weights price the share itself", disc * (w_up * Su + w_down * Sd))
print(f"the band: d {d:.6f} < forward factor {fwd:.6f} < u {u:.6f}")
print(f"sell the call at {sold:.2f} and build the copy")
row("banked today", banked)
row("at delivery, up state", arb_up)
row("at delivery, down state", arb_down)
row("a 0.20 wider share price costs", spread)
print("road 4, whole-number fractions, toy market u = 6/5, d = 4/5, bank x 21/20")
print(f"  Delta = {dl_n}/{dl_d}   cash = {cs_n}/{cs_d}   "
      f"cost = {v_n}/{v_d} = {v_n / v_d:.6f}")
print("hedge ratio by strike, shares at delivery per call")
for strike in (80.0, 90.0, 100.0, 110.0, 120.0, 130.0):
    row(f"strike {strike:.0f}", (max(Su - strike, 0.0) - max(Sd - strike, 0.0)) / (S * (u - d)))
print("what breaks")
row("payoff gap over factor gap, shares", wrong_gap)
row("dividend ignored on the share leg", wrong_drag)
row("the debt borrowed at its face value", wrong_face)
row("the dividend taken out twice", wrong_twice)
row("a fair coin instead of the hedge", wrong_coin)
grid = [70.0, 80.0, 90.0, 100.0, 110.0, 120.0, 130.0]
print("chart, delivery price   " + " ".join(f"{x:6.2f}" for x in grid))
print("chart, the copy         " + " ".join(f"{delta * x + bank * grow:6.2f}" for x in grid))
print("chart, the call's payoff" + " ".join(f"{max(x - K, 0.0):6.2f}" for x in grid))

assert abs(V - 11.073540703840) < 1e-9          # the cost the card quotes
assert abs(copy_up - Hu) < 1e-9                 # the copy really pays the call, up state
assert abs(copy_down - Hd) < 1e-9               # and down
assert max(abs(d80 - 1.0), abs(b80 + 80.0 * disc)) < 1e-10   # a strike both states clear
assert abs(V_b - V) < 1e-10                     # the search lands on the solved road
assert abs(V_w - V) < 1e-12                     # the weights land there too
assert abs(disc * (w_up * Su + w_down * Sd) - S * drag) < 1e-10  # they price the share too
assert abs(arb_up - arb_down) < 1e-12           # a mispriced call pays the same either way
assert arb_up > 0.0                             # and the difference is a gain out of nothing
assert d < fwd < u                              # the band that makes a cost a price
assert (v_n, v_d) == (250, 21)                  # the toy market, in exact fractions
print("ALL CHECKS PASS")
