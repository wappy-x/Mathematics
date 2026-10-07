# Replication and self-financing -- the check behind the card.  Nothing is imported that
# already knows the answer: the tree, the hedge ledger and the binomial weights are
# written out here; the bell-curve area is built from math.erf.  Acme starts at 100.00, a call struck at 100.00
# runs one year, the bank pays 5 percent, jumpiness is 20 percent, equal steps.
from math import exp, log, sqrt, erf

S0, K, R, SIG, T = 100.0, 100.0, 0.05, 0.20, 1.0

def lattice(n, q):
    """One step of n: up and down factors, the bank's growth over a step, and the factor
    a share holding grows by when its dividends are put back in."""
    u = exp(SIG * sqrt(T / n))
    return u, 1.0 / u, exp(R * T / n), exp(q * T / n)

def payoff(s):                            # the call: the gap above the strike, or nothing
    return max(s - K, 0.0)

def tree(n, q=0.0):
    """Every price Acme can reach: row m is the date m steps in, j ups so far."""
    u, d, _, _ = lattice(n, q)
    rows = [[S0]]
    for m in range(1, n + 1):
        rows.append([rows[m - 1][0] * d] + [rows[m - 1][j - 1] * u for j in range(1, m + 1)])
    return rows

def replicate(n, q=0.0):
    """Road 1.  Work backwards.  At each node two demands -- match the option if Acme
    rises, match it if Acme falls -- fix the share count h and the bank balance c.  What
    that pair costs is the node's wealth.  No probability anywhere in it."""
    u, d, grow, div = lattice(n, q)
    price = tree(n, q)
    v = [payoff(s) for s in price[n]]
    ledger = []
    for m in range(n - 1, -1, -1):
        w, row = [], []
        for j in range(m + 1):
            su, sd = price[m + 1][j + 1], price[m + 1][j]
            h = (v[j + 1] - v[j]) / (su - sd) / div
            c = (v[j + 1] - h * div * su) / grow
            row.append((h, c))
            w.append(h * price[m][j] + c)
        ledger.append(row)
        v = w
    ledger.reverse()
    return v[0], ledger, price

def by_weights(n, q=0.0):
    """Road 2.  No hedging at all.  Weight each ending price by the number that reproduces
    today's share price, average the payoff over those weights, discount it."""
    u, d, grow, div = lattice(n, q)
    p = (grow / div - d) / (u - d)
    ends, total, coeff = tree(n, q)[n], 0.0, 1.0
    for j in range(n + 1):
        total += coeff * p ** j * (1.0 - p) ** (n - j) * payoff(ends[j])
        coeff = coeff * (n - j) / (j + 1)
    return total / grow ** n

def walk(n, q=0.0):
    """Road 3.  Run the ledger forward down every path.  At each trading date, compare what
    the holdings arriving are worth with what the new ones cost: the difference is money
    from outside, and self-financing means it is zero."""
    u, d, grow, div = lattice(n, q)
    v0, ledger, price = replicate(n, q)
    gap, outside, rows = 0.0, 0.0, []
    for path in range(2 ** n):
        j, name = 0, ""
        h, c = ledger[0][0]
        for m in range(1, n + 1):
            up = (path >> (n - m)) & 1
            j += up
            name += ("-" if m > 1 else "") + ("up" if up else "down")
            marked = h * div * price[m][j] + c * grow
            if m < n:
                h, c = ledger[m][j]
                outside = max(outside, abs(h * price[m][j] + c - marked))
        gap = max(gap, abs(marked - payoff(price[n][j])))
        rows.append((name, marked, payoff(price[n][j])))
    return v0, gap, outside, rows

def normal_cdf(x):                        # bell-curve area to the left of x
    return 0.5 * (1.0 + erf(x / sqrt(2.0)))

def black_scholes(q=0.0):                 # the limit a refined tree walks toward
    wiggle = SIG * sqrt(T)
    d1 = (log(S0 / K) + (R - q + 0.5 * SIG * SIG) * T) / wiggle
    return S0 * exp(-q * T) * normal_cdf(d1) - K * exp(-R * T) * normal_cdf(d1 - wiggle)

u, d, grow, _ = lattice(2, 0.0)
v0, gap, outside, paths = walk(2)
price, ledger = tree(2), replicate(2)[1]
print(f"Acme {S0:.2f}, call struck at {K:.2f}, one year, bank {R * 100:.0f} percent, jumpiness {SIG * 100:.0f} percent")
print(f"two six-month steps: up factor {u:.6f}, down factor {d:.6f}, bank factor per step {grow:.6f}")
print(f"Acme after six months: up {price[1][1]:.6f}, down {price[1][0]:.6f}")
print(f"Acme at expiry: up-up {price[2][2]:.6f}, up-down {price[2][1]:.6f}, down-down {price[2][0]:.6f}")
print(f"call payoff at expiry: up-up {payoff(price[2][2]):.6f}, "
      f"up-down {payoff(price[2][1]):.6f}, down-down {payoff(price[2][0]):.6f}")
print()
print(f"{'the ledger':<13}{'Acme':>12}{'shares':>11}{'bank':>13}{'wealth':>12}")
for label, m, j in (("start", 0, 0), ("after an up", 1, 1), ("after a down", 1, 0)):
    h, c = ledger[m][j]
    print(f"{label:<13}{price[m][j]:>12.6f}{h:>11.6f}{c:>13.6f}{h * price[m][j] + c:>12.6f}")
print()
print(f"{'path':<13}{'wealth at expiry':>18}{'the payoff owed':>17}")
for name, wealth, owed in paths:
    print(f"{name:<13}{wealth:>18.6f}{owed:>17.6f}")
print()
print(f"road 1, backward replication, cost today       {v0:>12.6f}")
print(f"road 2, binomial weights, no hedging at all    {by_weights(2):>12.6f}")
print(f"road 3, worst gap between wealth and payoff    {gap:>12.6f}")
print(f"road 3, worst money from outside at a trade    {outside:>12.6f}")
print("\nthe same recipe, the year cut into more steps")
for n in (2, 4, 16, 64, 256, 1024):
    print(f"  {n:>4} steps: no dividend {replicate(n)[0]:>10.6f}    2 percent dividend {replicate(n, 0.02)[0]:>10.6f}")
print(f"  the limit: no dividend {black_scholes():>10.6f}    2 percent dividend {black_scholes(0.02):>10.6f}")
(h0, c0), (hu, cu) = ledger[0][0], ledger[1][1]
frozen = [h0 * s + c0 * exp(R * T) for s in price[2]]
ratio = (hu * price[1][1] + cu) / price[1][1]
deposit = -(cu - c0 * grow)
print("\nwhat breaks")
print(f"  never rebalanced: expiry wealth {frozen[0]:.6f} / {frozen[1]:.6f} / {frozen[2]:.6f},"
      f" payoff owed {payoff(price[2][0]):.6f} / {payoff(price[2][1]):.6f} / {payoff(price[2][2]):.6f}")
print(f"  hedge by value over price at the up node, {ratio:.6f} shares and no loan: pays"
      f" {ratio * price[2][2]:.6f} at up-up and {ratio * price[2][1]:.6f} at up-down")
print(f"  new money at the trade: {deposit:.6f} deposited, up-up ends at"
      f" {hu * price[2][2] + c0 * grow * grow:.6f}, {deposit * grow:.6f} of it the deposit grown")
print()
spots = [60.0 + 10.0 * i for i in range(9)]
print(f"{'chart, Acme at expiry':<25}" + " ".join(f"{s:7.2f}" for s in spots))
print(f"{'chart, call payoff':<25}" + " ".join(f"{payoff(s):7.2f}" for s in spots))
print(f"{'chart, never rebalanced':<25}" + " ".join(f"{h0 * s + c0 * exp(R * T):7.2f}" for s in spots))
assert abs(v0 - by_weights(2)) < 1e-10          # hedge ledger against probability weights
assert gap < 1e-9                               # the copy pays what the call pays, on every path
assert outside < 1e-9                           # and never takes a cent from outside
assert abs(replicate(1024)[0] - black_scholes()) < 0.01           # refinement reaches the limit
assert abs(replicate(1024, 0.02)[0] - 9.227005508154) < 0.01      # and the wing's house call
assert abs(frozen[2] - payoff(price[2][2])) > 5.0                 # a frozen hedge really does fail
print("ALL CHECKS PASS")
