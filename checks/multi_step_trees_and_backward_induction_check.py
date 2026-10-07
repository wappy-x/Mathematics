# Multi-step binomial tree, priced by backward induction -- the check behind the
# card.  Standard library only; nothing imported that already knows the answer.
# Acme: S = 100, K = 100, r = 5%, q = 2%, sigma = 20%, one year cut into four
# quarterly steps.  Five roads to one price: the backward roll with the risk-
# neutral weight; the same roll done by solving for shares and cash, with no
# weight anywhere; a sum over the five end prices with path counts; a sum over
# all sixteen histories; and the hedge carried forward down every one of them.
from math import exp, sqrt

S, K, r, q, sigma, T, N = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0, 4
BS = 9.227005508154                        # the same option, priced by the formula card
dt = T / N
u = exp(sigma * sqrt(dt))                  # up factor for one step
d = 1.0 / u                                # down factor, its reciprocal
disc = exp(-r * dt)                        # one step of discounting
grow = exp(q * dt)                         # dividends reinvested over one step
p = (exp((r - q) * dt) - d) / (u - d)      # the risk-neutral weight
paths = [tuple((m >> i) & 1 for i in range(N)) for m in range(2 ** N)]

def spot(step, ups): return S * u ** ups * d ** (step - ups)   # Acme's price at a node

def call(x): return max(x - K, 0.0)        # what the call pays at an end price

def roll(weight, pay):                     # road 1: roll a payoff back with a weight
    layers = [[pay(spot(N, k)) for k in range(N + 1)]]
    for j in range(N - 1, -1, -1):
        nxt = layers[0]
        layers.insert(0, [disc * (weight * nxt[k + 1] + (1.0 - weight) * nxt[k])
                          for k in range(j + 1)])
    return layers

def replicate():                           # road 2: shares and cash; no weight is used
    layers, shares, banks = [[call(spot(N, k)) for k in range(N + 1)]], [], []
    for j in range(N - 1, -1, -1):
        nxt, sh, ba, vals = layers[0], [], [], []
        for k in range(j + 1):
            s0 = spot(j, k)
            delta = (nxt[k + 1] - nxt[k]) / (grow * s0 * (u - d))
            bank = disc * (u * nxt[k] - d * nxt[k + 1]) / (u - d)
            sh.append(delta); ba.append(bank); vals.append(delta * s0 + bank)
        shares.insert(0, sh); banks.insert(0, ba); layers.insert(0, vals)
    return layers, shares, banks

def choose(n, k):                          # path counts, built here
    out = 1
    for i in range(k):
        out = out * (n - i) // (i + 1)
    return out

def tree_price(steps, strike, vol):        # the same machine at other settings
    h = T / steps
    uu = exp(vol * sqrt(h)); dd = 1.0 / uu
    ww = (exp((r - q) * h) - dd) / (uu - dd); ds = exp(-r * h)
    row = [max(S * uu ** k * dd ** (steps - k) - strike, 0.0) for k in range(steps + 1)]
    for j in range(steps - 1, -1, -1):
        row = [ds * (ww * row[k + 1] + (1.0 - ww) * row[k]) for k in range(j + 1)]
    return row[0]

def first_up(j, k):                        # $10 at expiry if the first quarter was up
    vals = [disc ** (N - j) * (10.0 if pp[0] else 0.0) for pp in paths if sum(pp[:j]) == k]
    return sum(vals) / len(vals)

def show(rows):
    for name, v in rows: print(f"{name:<45}{v:12.6f}")

lat = roll(p, call)
rep, shares, banks = replicate()
v_roll, v_rep = lat[0][0], rep[0][0]
v_nodes = disc ** N * sum(choose(N, k) * p ** k * (1 - p) ** (N - k) * call(spot(N, k))
                          for k in range(N + 1))
v_hist, mass = 0.0, 0.0
for path in paths:                         # road 4: walk each history from today
    price, w = S, 1.0
    for mv in path:
        price, w = (price * u, w * p) if mv else (price * d, w * (1.0 - p))
    v_hist += w * call(price); mass += w
v_hist *= disc ** N
worst = 0.0                                # road 5: carry the hedge forward
for path in paths:
    k, wealth = 0, v_rep
    for j, mv in enumerate(path):
        delta = shares[j][k]
        bank = wealth - delta * spot(j, k)
        k += mv
        wealth = delta * grow * spot(j + 1, k) + bank / disc
    worst = max(worst, abs(wealth - call(spot(N, k))))
v_share, v_put = roll(p, lambda x: x)[0][0], roll(p, lambda x: max(K - x, 0.0))[0][0]
share_now, parity = S * exp(-q * T), S * exp(-q * T) - K * exp(-r * T)
v_fair = roll(0.5, call)[0][0]                              # a fair coin instead
v_noq = roll((exp(r * dt) - d) / (u - d), call)[0][0]       # dividend left out
v_flat = disc ** N * sum(call(spot(N, k)) for k in range(N + 1)) / (N + 1)
node_ud, node_du, node_mix = disc ** (N - 2) * 10.0, 0.0, first_up(2, 1)
hedge_mix = (first_up(3, 2) - first_up(3, 1)) / (grow * spot(2, 1) * (u - d))

print(f"Acme {S:.2f}, strike {K:.2f}, r {r:.0%}, q {q:.0%}, sigma {sigma:.0%}, {N} steps in {T:.0f} year")
print(f"step {dt:.6f} yr   up {u:.6f}   down {d:.6f}   weight p {p:.6f}   step discount {disc:.6f}")
print()
print("node table: step, ups, Acme, option value, hedge in shares, cash in the bank")
for j in range(N):
    for k in range(j + 1):
        print(f"  step {j} ups {k}   Acme {spot(j, k):7.2f}   option {lat[j][k]:6.2f}"
              f"   hedge {shares[j][k]:7.4f}   cash {banks[j][k]:8.2f}")
print("  step 4 Acme   " + " ".join(f"{spot(N, k):8.2f}" for k in range(N + 1)))
print("  step 4 payoff " + " ".join(f"{call(spot(N, k)):8.2f}" for k in range(N + 1)))
print()
show([("road 1  backward roll with the weight p", v_roll), ("road 2  backward replication, no weight", v_rep),
      ("road 3  five end prices with path counts", v_nodes), ("road 4  sixteen histories, one at a time", v_hist),
      ("road 5  hedge carried forward, worst miss", worst), ("        path weights add to", mass)])
print(f"        path counts across the end prices  {[choose(N, k) for k in range(N + 1)]}")
show([("        the share itself rolled back", v_share), ("        S e^-qT", share_now),
      ("        the put on the same tree", v_put), ("        call minus put", v_roll - v_put),
      ("        S e^-qT - K e^-rT", parity), ("        one step across the same year", tree_price(1, K, sigma)),
      ("        the same roll at 500 steps", tree_price(500, K, sigma)),
      ("        Black-Scholes reference, same option", BS)])
print()
show([("wrong: a fair coin, p = 0.5", v_fair), ("wrong: dividend left out of the weight", v_noq),
      ("wrong: five end prices weighted equally", v_flat)])
print(f"merge test, $10 if the first quarter was up: after up-down {node_ud:.4f},"
      f" after down-up {node_du:.4f}, merged {node_mix:.4f}")
print(f"merge test, merged hedge {hedge_mix:.4f} shares where both histories need 0.0000")
print()
print("chart, step                     0       1       2       3       4")
print("chart, up-up-down-down     " + " ".join(f"{lat[j][k]:7.2f}" for j, k in ((0, 0), (1, 1), (2, 2), (3, 2))) + f" {0.0:7.2f}")
print("chart, down-down-up-up     " + " ".join(f"{lat[j][k]:7.2f}" for j, k in ((0, 0), (1, 0), (2, 0), (3, 1))) + f" {0.0:7.2f}")
print("bars,  hedge up history    " + " ".join(f"{shares[j][k]:7.4f}" for j, k in ((0, 0), (1, 1), (2, 2), (3, 3))))
print("bars,  hedge down history  " + " ".join(f"{shares[j][k]:7.4f}" for j, k in ((0, 0), (1, 0), (2, 0), (3, 0))))
print()
show([("try: eight steps instead of four", tree_price(8, K, sigma)), ("try: strike 120", tree_price(N, 120.0, sigma)),
      ("try: sigma 40%", tree_price(N, K, 0.40))])

assert abs(v_roll - v_rep) < 1e-12, "the weighted roll and the replication roll must agree"
assert abs(v_nodes - v_roll) < 1e-12, "path counts over end prices must match the roll"
assert abs(v_hist - v_roll) < 1e-12, "sixteen histories must match the roll"
assert worst < 1e-9, "the hedge must land on the payoff down every history"
assert abs(mass - 1.0) < 1e-12, "the path weights are a probability"
assert abs(v_share - share_now) < 1e-12, "the share rolled back must be worth S e^-qT today"
assert abs((v_roll - v_put) - parity) < 1e-12, "call minus put on the tree must be the forward"
assert abs(tree_price(N, K, sigma) - v_roll) < 1e-12, "the machine rebuilt from scratch must give the same four-step price"
assert abs(tree_price(500, K, sigma) - BS) < 0.01, "500 steps must land within a cent of the Black-Scholes price"
print("ALL CHECKS PASS")
