# Callable swap = plain swap + Bermudan swaption -- the check behind the card.
# Standard library only: the tree, its fitting, the root finder and the path
# enumeration are all written out here.  Money in dollars, rates as decimals.
from math import exp

N, K0, Y, SIG, YEARS = 10_000_000.0, 0.05, 0.05, 0.20, 10
CALL = range(2, 10)                    # cancel just after the coupon of years 2..9

def bisect(f, lo, hi):                 # root of an increasing-or-decreasing f on [lo, hi]
    flo = f(lo)
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if (f(mid) > 0) == (flo > 0): lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

def tree(y, sig):
    # Black-Derman-Toy: one-year rate at year i, node j (j = up-moves so far) is a_i*exp(2*sig*j).
    # Each a_i is solved so the tree reprices the flat curve's zero bond (1+y)^-(i+1).
    R, Q = [], [1.0]                   # Q: today's price of $1 paid only at each node
    for i in range(YEARS):
        f = lambda a: sum(q / (1 + a * exp(2 * sig * j)) for j, q in enumerate(Q)) - (1 + y) ** -(i + 1)
        a = bisect(f, 1e-6, 1.0)
        R.append([a * exp(2 * sig * j) for j in range(i + 1)])
        nq = [0.0] * (i + 2)
        for j, q in enumerate(Q):
            nq[j] += 0.5 * q / (1 + R[i][j]); nq[j + 1] += 0.5 * q / (1 + R[i][j])
        Q = nq
    return R

def marks(R, K):                       # M[i][j]: value at (i, j), just after coupon i, of coupons i+1..10
    M = [[0.0] * (YEARS + 1)]
    for i in range(YEARS - 1, -1, -1):
        nx = M[0]
        M.insert(0, [(N * (R[i][j] - K) + 0.5 * (nx[j] + nx[j + 1])) / (1 + R[i][j]) for j in range(i + 1)])
    return M

def bermudan(R, M, sign, dates):       # right to enter the swap of sign*M: reward (sign*M)^+
    B, stop = [0.0] * (YEARS + 1), {}
    for i in range(YEARS - 1, -1, -1):
        new = []
        for j in range(i + 1):
            cont = 0.5 * (B[j] + B[j + 1]) / (1 + R[i][j])
            reward = max(sign * M[i][j], 0.0) if i in dates else 0.0
            stop[i, j] = reward > cont
            new.append(max(reward, cont))
        B = new
    return B[0], stop

def direct(R, K, side):                # road 2: roll the cancellable contract itself, no option in sight
    W = [0.0] * (YEARS + 1)
    for i in range(YEARS - 1, -1, -1):
        c = [(N * (R[i][j] - K) + 0.5 * (W[j] + W[j + 1])) / (1 + R[i][j]) for j in range(i + 1)]
        W = [(max(x, 0.0) if side > 0 else min(x, 0.0)) if i in CALL else x for x in c]
    return W[0]

def ledger(R, K, stop):                # road 3: all 512 rate paths, actual coupons paid until cancelled
    total, when = 0.0, [0.0] * (YEARS + 1)
    for bits in range(1 << 9):
        j, df, pv = 0, 1.0, 0.0
        for y in range(1, YEARS + 1):
            df /= 1 + R[y - 1][j]
            pv += N * (R[y - 1][j] - K) * df
            if y < YEARS: j += (bits >> (y - 1)) & 1
            if y in CALL and stop(y, j):
                when[y] += 1 / 512; break
        total += pv / 512
    return total, when

def closed_swap(y, K, n=YEARS):        # road 4: plain swap straight from a flat curve, no tree
    P = [(1 + y) ** -t for t in range(1, n + 1)]
    return N * (1 - P[-1] - K * sum(P))

def price(y, sig, K):
    R = tree(y, sig); M = marks(R, K)
    return R, M, M[0][0], bermudan(R, M, -1, CALL), bermudan(R, M, +1, CALL)

R, M, swap, (bR, stopR), (bP, stopP) = price(Y, SIG, K0)
holder, bank = direct(R, K0, +1), direct(R, K0, -1)
path_holder, when = ledger(R, K0, lambda y, j: stopR[y, j])
path_greedy, _ = ledger(R, K0, lambda y, j: M[y][j] < 0)
euro = [bermudan(R, M, -1, {e})[0] for e in CALL]
k_hold = bisect(lambda k: direct(tree(Y, SIG), k, +1), 0.05, 0.08)
k_bank = bisect(lambda k: direct(tree(Y, SIG), k, -1), 0.02, 0.05)
Rk = tree(Y, SIG)
def c2(x): return 0.0 if abs(x) < 0.005 else x          # print a zero that is zero to the cent as 0.00
up, dn = price(Y + 1e-4, SIG, K0), price(Y - 1e-4, SIG, K0)   # curve moved 1 basis point each way
d_swap, d_rec = (up[2] - dn[2]) / 2, (up[3][0] - dn[3][0]) / 2
vega = (price(Y, SIG + 0.01, K0)[3][0] - price(Y, SIG - 0.01, K0)[3][0]) / 2
ann = sum((1 + Y) ** -t for t in range(1, YEARS + 1))       # annuity: $1 a year for 10 years, today
k_naive = K0 + bR / (N * ann)                                # premium spread evenly over the annuity

rows = [
    ("tree rate year 0 %", 100 * R[0][0]), ("tree rate year 2, lowest node %", 100 * R[2][0]), ("tree rate year 2, highest node %", 100 * R[2][2]),
    ("curve: 1 - P(0,10)", 1 - (1 + Y) ** -YEARS), ("curve: annuity", ann),
    ("year 2 low node: remaining swap", M[2][0]),
    ("1 plain swap, tree", c2(swap)), ("1 plain swap, curve", c2(closed_swap(Y, K0))),
    ("1 receiver Bermudan B_R", bR), ("1 swap + B_R", swap + bR),
    ("2 callable, rolled directly", holder), ("3 callable, 512 paths", path_holder),
    ("1 payer Bermudan B_P", bP), ("1 swap - B_P", swap - bP), ("2 bank-cancellable, rolled", bank),
    ("max European (one date)", max(euro)), ("sum of Europeans", sum(euro)),
    ("wrong: European year 2 only", euro[0]), ("wrong: cancel when mark < 0", path_greedy),
    ("breakeven fixed, holder cancels %", 100 * k_hold), ("breakeven fixed, bank cancels %", 100 * k_bank),
    ("naive breakeven, premium / annuity %", 100 * k_naive), ("callable at naive breakeven", direct(Rk, k_naive, +1)),
    ("swap at holder breakeven, tree", marks(Rk, k_hold)[0][0]), ("swap at holder breakeven, curve", closed_swap(Y, k_hold)),
    ("rate delta per bp: swap", d_swap), ("rate delta per bp: B_R", d_rec), ("rate delta per bp: callable", d_swap + d_rec),
    ("vega per vol point: B_R = callable", vega),
]
for name, v in rows: print(f"{name:<36} {v:>16.4f}")
print("\nyear  European B_R  cancel at rates up to %  chance cancelled then")
for e, v in zip(CALL, euro):
    edge = max([R[e][j] for j in range(e + 1) if stopR[e, j]], default=0.0)
    print(f"{e:>4} {v:>14.2f} {100 * edge:>18.4f} {when[e]:>21.4f}")
print(f"never cancelled {1 - sum(when):.4f}")
print("\npayoff at year 2, $ thousands: flat rate %, remaining swap, with cancel right")
for yy in range(2, 9):
    m = c2(closed_swap(yy / 100, K0, 8) / 1000)
    print(f"{yy:>4} {m:>14.2f} {max(m, 0.0):>14.2f}")

assert abs(holder - (swap + bR)) < 1e-6 * N, "decomposition, holder side"
assert abs(bank - (swap - bP)) < 1e-6 * N, "decomposition, bank side"
assert abs(path_holder - holder) < 1e-6 * N, "path ledger vs rollback"
assert abs(marks(Rk, k_hold)[0][0] - closed_swap(Y, k_hold)) < 1e-4, "tree vs curve"
assert max(euro) <= bR <= sum(euro), "Bermudan between best European and all Europeans"
assert path_greedy < holder, "greedy exercise must lose value"
assert abs(direct(Rk, k_hold, +1)) < 1e-2, "holder break-even is a root"
assert abs(direct(Rk, k_bank, -1)) < 1e-2, "bank break-even is a root"
print("all checks passed")
