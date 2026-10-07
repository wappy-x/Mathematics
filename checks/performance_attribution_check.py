# Brinson attribution -- the check behind the card.  Standard library only.
# Every number quoted on the card is printed here, in percentage points (pp).
# Roads: direct totals, the per-sector formula, four notional portfolios,
# two one-decision-at-a-time paths, and 1,000 random ledgers.

def total(weights, returns):                      # a portfolio's return: weights times returns, added
    return sum(w * x for w, x in zip(weights, returns))

def effects(w, W, r, b):                          # Brinson-Fachler, one row per sector
    B = total(W, b)
    A = [(w[i] - W[i]) * (b[i] - B) for i in range(len(w))]
    S = [W[i] * (r[i] - b[i]) for i in range(len(w))]
    I = [(w[i] - W[i]) * (r[i] - b[i]) for i in range(len(w))]
    return A, S, I

def pp(x):                                        # decimal return -> percentage points
    return f"{100 * x + 0.0:+.4f}"

def show(label, x):
    print(f"{label:<44} {pp(x)}")

# ---- the example: shares and bonds, one month ----
w = [0.60, 0.40]        # fund's weights at the start
W = [0.50, 0.50]        # benchmark's weights
r = [0.068, -0.022]     # fund's return inside each sector
b = [0.060, -0.020]     # benchmark's return inside each sector
R, B = total(w, r), total(W, b)
A, S, I = effects(w, W, r, b)
show("fund return R", R)
show("benchmark return B", B)
show("road 1  active return R - B", R - B)
for k, name in enumerate(["shares", "bonds"]):
    show(f"{name}: allocation", A[k])
    show(f"{name}: selection", S[k])
    show(f"{name}: interaction", I[k])
show("allocation A", sum(A))
show("selection S", sum(S))
show("interaction I", sum(I))
show("road 2  A + S + I", sum(A) + sum(S) + sum(I))

# ---- road 3: four notional portfolios, whole-portfolio returns only ----
Q1, Q2, Q3, Q4 = total(W, b), total(w, b), total(W, r), total(w, r)
show("Q1 benchmark weights, benchmark returns", Q1)
show("Q2 fund weights, benchmark returns", Q2)
show("Q3 benchmark weights, fund returns", Q3)
show("Q4 fund weights, fund returns", Q4)
show("road 3  allocation Q2 - Q1", Q2 - Q1)
show("road 3  selection Q3 - Q1", Q3 - Q1)
show("road 3  interaction Q4 - Q3 - Q2 + Q1", Q4 - Q3 - Q2 + Q1)

# ---- road 4: change one decision at a time, in both orders ----
sel_at_fund_w = sum(w[k] * (r[k] - b[k]) for k in range(2))
alloc_at_fund_r = sum((w[k] - W[k]) * r[k] for k in range(2))
show("allocation first: then selection", sel_at_fund_w)
show("selection first: then allocation", alloc_at_fund_r)
show("staircase: benchmark", B)
show("staircase: + allocation", B + sum(A))
show("staircase: + selection", B + sum(A) + sum(S))
show("staircase: + interaction = fund", B + sum(A) + sum(S) + sum(I))

# ---- what breaks ----
uncentred = [(w[k] - W[k]) * b[k] for k in range(2)]
show("wrong: drop interaction", sum(A) + sum(S))
show("wrong: fund-weight selection + interaction", sum(A) + sel_at_fund_w + sum(I))
show("uncentred allocation, shares", uncentred[0])
show("uncentred allocation, bonds", uncentred[1])

# ---- try changing ----
show("try: copy benchmark weights, active", sum(sum(e) for e in effects(W, W, r, b)))
show("try: copy benchmark returns, active", sum(sum(e) for e in effects(w, W, b, b)))
show("try: flip to 40/60, allocation", sum(effects([0.4, 0.6], W, r, b)[0]))
show("try: flip to 40/60, active", total([0.4, 0.6], r) - B)

# ---- two months: link before adding ----
r2, b2 = [0.000, -0.025], [0.030, -0.010]      # month 2, same starting weights
R2, B2 = total(w, r2), total(W, b2)
A2, S2, I2 = effects(w, W, r2, b2)
show("month 2: fund", R2)
show("month 2: benchmark", B2)
show("month 2: allocation", sum(A2))
show("month 2: selection", sum(S2))
show("month 2: interaction", sum(I2))
naive = (R - B) + (R2 - B2)
compound = (1 + R) * (1 + R2) - (1 + B) * (1 + B2)
f1, f2 = 1 + B2, 1 + R                          # month 1 scaled by later benchmark growth, month 2 by earlier fund growth
linked = [sum(A) * f1 + sum(A2) * f2, sum(S) * f1 + sum(S2) * f2, sum(I) * f1 + sum(I2) * f2]
show("two months: sum of monthly active", naive)
show("two months: compounded fund", (1 + R) * (1 + R2) - 1)
show("two months: compounded benchmark", (1 + B) * (1 + B2) - 1)
show("two months: compounded active", compound)
show("linked allocation", linked[0])
show("linked selection", linked[1])
show("linked interaction", linked[2])
show("linked total", sum(linked))

# ---- road 5: 1,000 random ledgers, five sectors, home-made random numbers ----
state = 20260928
def rnd():
    global state
    state = (6364136223846793005 * state + 1442695040888963407) % 2**64
    return (state >> 11) / 2**53
worst = 0.0
for trial in range(1000):
    raw_w = [rnd() for _ in range(5)]; raw_W = [rnd() for _ in range(5)]
    tw = [x / sum(raw_w) for x in raw_w]; tW = [x / sum(raw_W) for x in raw_W]
    tr = [0.4 * rnd() - 0.2 for _ in range(5)]; tb = [0.4 * rnd() - 0.2 for _ in range(5)]
    a, s, i = effects(tw, tW, tr, tb)
    worst = max(worst, abs(sum(a) + sum(s) + sum(i) - (total(tw, tr) - total(tW, tb))))
print(f"{'1000 random ledgers reconcile to 1e-12':<44} {'yes' if worst < 1e-12 else 'no'}")

# ---- mutants: break the formula three ways; each must fail to reconcile ----
mutants = {
    "interaction dropped": lambda k: (w[k] - W[k]) * (b[k] - B) + W[k] * (r[k] - b[k]),
    "selection at fund weights": lambda k: (w[k] - W[k]) * (b[k] - B) + w[k] * (r[k] - b[k]) + (w[k] - W[k]) * (r[k] - b[k]),
    "allocation at fund returns": lambda k: (w[k] - W[k]) * (r[k] - B) + W[k] * (r[k] - b[k]) + (w[k] - W[k]) * (r[k] - b[k]),
}
caught = 0
for name, f in mutants.items():
    caught += abs(sum(f(k) for k in range(2)) - (R - B)) > 1e-9
print(f"{'mutants caught (of 3)':<44} {caught}")

# ---- asserts: each side computed a different way ----
assert abs((R - B) - 0.012) < 1e-12                                 # the headline, from the example's statement
assert abs(sum(A) + sum(S) + sum(I) - (R - B)) < 1e-12              # formula vs direct totals
assert abs(sum(A) - (Q2 - Q1)) < 1e-12                              # centred sector formula vs notional portfolios
assert abs(sum(I) - (Q4 - Q3 - Q2 + Q1)) < 1e-12
for k in range(2):                                                  # per sector: effects miss the raw contribution by (w - W) B
    assert abs(A[k] + S[k] + I[k] + (w[k] - W[k]) * B - (w[k] * r[k] - W[k] * b[k])) < 1e-12
assert abs(sum(I) - (alloc_at_fund_r - sum(A))) < 1e-12              # interaction = how much the order matters
assert abs(sum(linked) - compound) < 1e-12                          # linking vs compounding
assert worst < 1e-12                                                # 1,000 ledgers nobody chose
assert caught == 3                                                  # every broken formula fails to reconcile
print("all checks passed")
