# Interest rate swaps -- the check behind the card.  Standard library only;
# nothing imported that already knows an answer.  One 5-year swap, 4.5 percent
# fixed paid annually against a 12-month floating rate, 10,000,000 notional,
# valued on the bootstrapped curve by three roads that share no shortcut:
#   road 1, two bonds: the floating note at par, less a fixed-coupon bond;
#   road 2, a strip of forwards: each year's net payment at its forward rate;
#   road 3, a rate tree fitted to the curve, where the floating rates are random,
#           summing each node's net payment at today's price for that node.
N, K, YEARS = 10_000_000.0, 0.045, 5          # notional, fixed rate, annual payments
SWAPS = ((2, 0.0440), (3, 0.0455), (4, 0.0462), (5, 0.0465))   # par quotes, the curve card

def curve(bump):                              # bump: added to every quote
    D = [1.0, 1.0 / (1.042 + bump)]           # today, and the 12-month deposit at 4.2%
    for n, S in SWAPS:                        # the ladder, one rung per quote
        D.append((1.0 - (S + bump) * sum(D[1:n])) / (1.0 + S + bump))
    return D

def strip(D):                                 # road 2 on any curve: net forwards, discounted
    return sum(N * (D[i - 1] / D[i] - 1.0 - K) * D[i] for i in range(1, YEARS + 1))

D = curve(0.0)
F = [D[i - 1] / D[i] - 1.0 for i in range(1, YEARS + 1)]   # forward rate for year i

# road 1: pay fixed = own a floating-rate note, owe a fixed-coupon bond
fixed_coupons = sum(K * N * D[i] for i in range(1, YEARS + 1))
fixed_bond = fixed_coupons + N * D[YEARS]
note = N                                      # worth par on a reset date: the card's claim
road1 = note - fixed_bond

# road 2: each year's net payment, set at its forward rate, discounted
net = [N * (F[i - 1] - K) for i in range(1, YEARS + 1)]
pv = [net[i - 1] * D[i] for i in range(1, YEARS + 1)]
road2 = sum(pv)
float_leg = sum(N * F[i - 1] * D[i] for i in range(1, YEARS + 1))

def bisect(f, lo, hi):                        # f(lo) and f(hi) differ in sign
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if (f(lo) > 0) == (f(mid) > 0): lo = mid
        else: hi = mid
    return 0.5 * (lo + hi)

def tree(sigma):                              # additive rate tree, fitted to D by bisection
    rates, Q, prices = [], [1.0], []          # Q: today's price of 1 paid at each node
    for i in range(YEARS):
        f = lambda th: sum(q / (1 + th + sigma * (2 * j - i)) for j, q in enumerate(Q)) - D[i + 1]
        th = bisect(f, -0.5, 0.5)
        r = [th + sigma * (2 * j - i) for j in range(i + 1)]
        rates.append(r); prices.append(Q)
        nQ = [0.0] * (i + 2)
        for j, q in enumerate(Q):
            nQ[j] += 0.5 * q / (1 + r[j]); nQ[j + 1] += 0.5 * q / (1 + r[j])
        Q = nQ
    return rates, prices

def strip_on_tree(sigma):                     # each node's net payment, known at the node
    rates, prices = tree(sigma)
    return sum(q * N * (r - K) / (1 + r) for i in range(YEARS)
               for q, r in zip(prices[i], rates[i]))

def by_tree(rates, principal):                # roll back: returns note and fixed bond at each node
    note = [principal * (1 + r) / (1 + r) for r in rates[-1]]   # last payment: N plus N r
    bond = [(principal * (1 + K)) / (1 + r) for r in rates[-1]]
    layers = [(note, bond)]
    for i in range(YEARS - 2, -1, -1):
        r, (n1, b1) = rates[i], layers[0]
        note = [(0.5 * (n1[j] + n1[j + 1]) + principal * r[j]) / (1 + r[j]) for j in range(i + 1)]
        bond = [(0.5 * (b1[j] + b1[j + 1]) + principal * K) / (1 + r[j]) for j in range(i + 1)]
        layers.insert(0, (note, bond))
    return layers

t1 = tree(0.01)[0]
layers = by_tree(t1, N)
road3, road3b = strip_on_tree(0.01), strip_on_tree(0.02)

# the rows the card quotes
print(f"swap: notional {N:.2f}, fixed {100 * K:.2f}%, coupon {K * N:.2f} a year, {YEARS} years")
print("year  discount factor  forward rate  net to fixed payer  worth today")
for i in range(1, YEARS + 1):
    print(f"{i:>4}  {D[i]:15.8f}  {100 * F[i - 1]:11.4f}%  {net[i - 1]:18.2f}  {pv[i - 1]:11.2f}")
print("chart, forward rate %  " + " ".join(f"{100 * f:.2f}" for f in F) + "   fixed 4.50")
A = sum(D[1:])
print(f"annuity, sum of D                  {A:18.6f}")
print(f"par rate on this curve (1-D5)/A    {100 * (1 - D[5]) / A:17.4f}%")
print(f"fixed leg, coupons only            {fixed_coupons:18.2f}")
print(f"floating leg, forwards             {float_leg:18.2f}")
print(f"floating leg, N(1 - D5)            {N * (1 - D[5]):18.2f}")
print(f"fixed bond, principal part N D5   {N * D[YEARS]:18.2f}")
print(f"fixed bond, coupons + principal    {fixed_bond:18.2f}")
print(f"floating note, principal included  {note:18.2f}")
print(f"road 1, note - fixed bond          {road1:18.2f}")
print(f"road 2, strip of forwards          {road2:18.2f}")
print(f"road 3, rate tree, sigma 1%        {road3:18.2f}")
print(f"road 3, rate tree, sigma 2%        {road3b:18.2f}")
print(f"tree, today: note and fixed bond   {layers[0][0][0]:18.2f} {layers[0][1][0]:14.2f}")
for j in range(3):
    print(f"tree, year 2 node {j}: rate {100 * t1[2][j]:6.4f}%  note {layers[2][0][j]:14.2f}  bond {layers[2][1][j]:14.2f}")
print(f"wrong: net payments not discounted {sum(net):18.2f}")
wrong_par = sum(N * (S - K) * D[n] for n, S in ((1, 0.042),) + SWAPS)
print(f"wrong: par quotes used as forwards {wrong_par:18.2f}")
print(f"wrong: note at par, bond no principal {N - fixed_coupons:15.2f}")
at_par = round(sum(N * (f - 0.0465) * D[i + 1] for i, f in enumerate(F)), 2) + 0.0
print(f"try: fixed rate 4.65%, strip       {at_par:18.2f}")
print(f"try: receive fixed instead         {-road2:18.2f}")
Du, Dd = curve(0.0001), curve(-0.0001)             # every quote up, and down, 1 bp
up, down = strip(Du) - road2, strip(Dd) - road2
print(f"all quotes up 1 bp, change         {up:18.2f}")
print(f"all quotes down 1 bp, change       {down:18.2f}")
print(f"DV01, (up - down) / 2              {(up - down) / 2:18.2f}")
print(f"tree sigma 1% to 2%, change        {round(road3b - road3, 2) + 0.0:18.2f}")

assert abs(road1 - road2) < 1e-6, "two bonds and the strip of forwards agree"
assert abs(road3 - road2) < 1e-4 and abs(road3b - road2) < 1e-4, "the rate tree lands on the strip"
assert all(abs(v - N) < 1e-4 for v in layers[2][0]), "the note is worth par at every year-2 reset"
assert abs(float_leg - N * (1 - D[5])) < 1e-6, "forwards telescope to N(1 - D5)"
assert abs(layers[0][1][0] - fixed_bond) < 1e-4, "the tree reprices the fixed bond"
assert abs((1 - D[5]) / A - 0.0465) < 1e-12, "the curve reprices the 5-year par quote"
assert abs((1 - Du[5]) / sum(Du[1:]) - 0.0466) < 1e-12, "the bumped curve reprices the bumped quote"
assert up > 0 > down and abs(up + down) < 0.01 * up, "payer gains as rates rise, nearly linearly"
print("ALL CHECKS PASS")
