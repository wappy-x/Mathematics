# State prices and risk-neutral pricing in one period -- the check behind the
# card.  Nothing is imported.  Acme is 100.00 today; in a year it is 120.00 or
# 90.00, and a dollar in the bank becomes 1.05.  Every price below is reached
# by roads that meet only at the answer: the two tickets, a share-and-cash copy,
# the fake coin, whole numbers over 21, and 200,000 flips of a built coin.
S0, SU, SD, R, P_UP = 100.0, 120.0, 90.0, 1.05, 0.7
D = 1.0 / R                                        # today's price of a sure dollar
FLIPS, SEED, TWO32 = 200000, 20260914, 4294967296.0

def solve2(a11, a12, a21, a22, b1, b2):            # 2x2 solve, Cramer's rule
    det = a11 * a22 - a12 * a21
    return ((b1 * a22 - a12 * b2) / det, (a11 * b2 - b1 * a21) / det)

psi_u, psi_d = solve2(SU, SD, 1.0, 1.0, S0, D)     # road 1: solve the market's two equations

def by_tickets(hu, hd):                            # road 1, applied to any payoff
    return psi_u * hu + psi_d * hd

def by_copy(hu, hd):                               # road 2: copy the payoff with shares and cash
    delta, cash = solve2(SU, R, SD, R, hu, hd)     # delta*SU + cash*R = hu, and the same down
    return delta, cash, delta * S0 + cash

q_u = (R * S0 - SD) / (SU - SD)                    # road 3: the fake coin
q_d = 1.0 - q_u

def by_coin(hu, hd):
    return D * (q_u * hu + q_d * hd)

# road 4: whole numbers only.  The bank turns 20 into 21, so a sure dollar
# costs 20/21 and both ticket prices can be written over that same 21.
SU_I, SD_I, S0_I, NUM, DEN = 120, 90, 100, 20, 21
det_i = SU_I - SD_I
a_num, b_num = S0_I * DEN - SD_I * NUM, SU_I * NUM - S0_I * DEN
a_i, b_i = a_num // det_i, b_num // det_i          # 21 x each ticket price
call_i, put_i = a_i * 20, b_i * 10                 # 21 x each contract price

def coin_flips(threshold):                         # road 5: a coin built from scratch
    x, ups = SEED, 0
    for _ in range(FLIPS):
        x = (6364136223846793005 * x + 1442695040888963407) & 0xFFFFFFFFFFFFFFFF
        if (x >> 32) < threshold:
            ups += 1
    return ups

def yn(claim):
    return "yes" if claim else "no"

def row(label, value):
    print(f"  {label:<40}{value:>11.6f}")

CONTRACTS = (("call K=100", 20.0, 0.0), ("put K=100", 0.0, 10.0),
             ("forward K=105", 15.0, -15.0), ("one share", 120.0, 90.0),
             ("sure dollar", 1.0, 1.0))
call_p, put_p = by_copy(20.0, 0.0)[2], by_copy(0.0, 10.0)[2]
du, cu, ku = by_copy(1.0, 0.0)
dd, cd, kd = by_copy(0.0, 1.0)
eq_s1, ep_s1 = q_u * SU + q_d * SD, P_UP * SU + (1.0 - P_UP) * SD
ups_q, ups_p = coin_flips(int(q_u * TWO32)), coin_flips(int(P_UP * TWO32))
mc_q, mc_p = D * (ups_q / FLIPS) * 20.0, D * (ups_p / FLIPS) * 20.0
naive_bank = D * (P_UP * 20.0 + (1.0 - P_UP) * 0.0)          # real odds, bank rate
naive_share = (P_UP * 20.0) / (ep_s1 / S0)                   # real odds, Acme's own return
no_discount = q_u * 20.0 + q_d * 0.0                         # fake coin, forgot to discount
needed_rate = ((P_UP * 20.0) / call_p - 1.0) * 100.0         # the only real-odds rate that works
R_HIGH = 1.25                                                # a bank that beats Acme everywhere
psi_hi_u = (R_HIGH * S0 - SD) / ((SU - SD) * R_HIGH)
psi_hi_d = (SU - R_HIGH * S0) / ((SU - SD) * R_HIGH)
free_up, free_dn = S0 * R_HIGH - SU, S0 * R_HIGH - SD
grid = [(85 + 5 * i) / 100.0 for i in range(9)]
band = [((g * S0 - SD) / ((SU - SD) * g), (SU - g * S0) / ((SU - SD) * g)) for g in grid]

print(f"market: Acme {S0:.2f} today, {SU:.2f} up or {SD:.2f} down; bank 1.00 -> {R:.2f}")
print("the two tickets, from the two prices the market already quotes")
row(f"up ticket, pays 1.00 if Acme is {SU:.2f}", psi_u)
row(f"down ticket, pays 1.00 if Acme is {SD:.2f}", psi_d)
row("the two together, a sure dollar", psi_u + psi_d)
row("a sure dollar the other way, 1 / 1.05", D)
print(f"  in whole numbers: up {a_i}/{DEN}, down {b_i}/{DEN}, sure dollar {NUM}/{DEN}")
print("the same two tickets, copied with shares and cash")
print(f"  up ticket   {du:>10.6f} shares and {cu:>10.6f} cash, cost {ku:>10.6f}")
print(f"  down ticket {dd:>10.6f} shares and {cd:>10.6f} cash, cost {kd:>10.6f}")
print(f"the fake coin: each ticket price divided by {D:.6f}")
print(f"  weight on up {q_u:.6f}, weight on down {q_d:.6f}, sum {q_u + q_d:.6f}")
row("fake average of Acme in a year", eq_s1)
row(f"the bank turning {S0:.2f} into", S0 * R)
row(f"real average of Acme, up chance {P_UP:.2f}", ep_s1)
print(f"  that is a real return of {(ep_s1 / S0 - 1.0) * 100.0:.2f} percent, "
      f"against the bank's 5.00")
print()
print(f"{'contract':<16}{'pays up':>10}{'pays down':>11}{'tickets':>12}{'copy':>12}{'fake coin':>12}")
for name, hu, hd in CONTRACTS:
    print(f"{name:<16}{hu:>10.2f}{hd:>11.2f}{by_tickets(hu, hd):>12.6f}"
          f"{by_copy(hu, hd)[2]:>12.6f}{by_coin(hu, hd):>12.6f}")
print(f"call minus put {call_p - put_p:.6f}, and Acme minus 100 sure dollars "
      f"{S0 - 100.0 * D:.6f}")
print(f"in whole numbers: call {call_i}/{DEN}, put {put_i}/{DEN}, difference {call_i - put_i}/{DEN}")
print()
print(f"the coin flipped {FLIPS} times by the script's own generator, seed {SEED}")
print(f"  fake coin, weight {q_u:.2f}: up {ups_q} times, share {ups_q / FLIPS:.6f}, "
      f"call {mc_q:>9.6f} against {call_p:.6f}")
print(f"  real coin, chance {P_UP:.2f}: up {ups_p} times, share {ups_p / FLIPS:.6f}, "
      f"call {mc_p:>9.6f} against {call_p:.6f}")
print()
print(f"what breaks, against the call's {call_p:.6f}")
print(f"  real odds, discounted at the bank's 5 percent   {naive_bank:>10.6f}")
print(f"  real odds, discounted at Acme's 11 percent      {naive_share:>10.6f}")
print(f"  the fake coin with no discounting               {no_discount:>10.6f}")
print(f"  the only rate that makes real odds work         {needed_rate:>10.6f} percent")
print(f"  bank at 25 percent: up ticket {psi_hi_u:.6f}, down ticket {psi_hi_d:.6f}")
print(f"    free money there: sell one share, lend {S0:.2f}; up {free_up:.2f}, down {free_dn:.2f}")
print()
print("chart, bank factor  " + "".join(f"{g:>7.2f}" for g in grid))
print("chart, up ticket    " + "".join(f"{p[0]:>7.2f}" for p in band))
print("chart, down ticket  " + "".join(f"{p[1]:>7.2f}" for p in band))
print("chart, both positive" + "".join(f"{yn(p[0] > 0.0 and p[1] > 0.0):>7}" for p in band))
print(f"bars, the call four ways: {call_p:.2f}, {no_discount:.2f}, "
      f"{naive_share:.2f}, {naive_bank:.2f}")

assert abs(NUM / DEN - D) < 1e-15, "the whole-number road's sure dollar against 1 / R"
assert abs(psi_u - a_i / DEN) < 1e-12, "float solve against the whole-number solve, up ticket"
assert abs(psi_d - b_i / DEN) < 1e-12, "float solve against the whole-number solve, down ticket"
assert abs(by_tickets(20.0, 0.0) - call_p) < 1e-12, "tickets against the share-and-cash copy"
assert abs(by_coin(20.0, 0.0) - call_p) < 1e-12, "fake coin against the share-and-cash copy"
assert abs(mc_q - call_p) < 0.05, "200,000 flips of the fake coin land on the price"
assert abs((call_p - put_p) - (S0 - 100.0 * D)) < 1e-12, "call minus put against Acme minus cash"
assert abs(eq_s1 - S0 * R) < 1e-12, "under the fake coin Acme earns the bank rate"
assert abs(naive_bank - 40.0 / 3.0) < 1e-12, "the real-odds answer, by an independent fraction"
for g, (pu, pd) in zip(grid, band):
    assert (pu > 0.0 and pd > 0.0) == (SD / S0 < g < SU / S0), "positive tickets = no free money"
print("ALL CHECKS PASS")
