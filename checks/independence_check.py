# Independence -- the check behind the card. Standard library only.
# Roads: the product formula, a count over every outcome, a seeded simulation.
from math import sqrt

M64 = (1 << 64) - 1
def splitmix(s):                     # SplitMix64: returns (new state, 64-bit draw)
    s = (s + 0x9E3779B97F4A7C15) & M64
    z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return s, z ^ (z >> 31)
def uniform(s):
    s, z = splitmix(s)
    return s, (z >> 11) / 9007199254740992.0

def f4(x): return f"{x:.4f}"
def prob(outcomes, event):          # enumerated road: add the weights of outcomes in the event
    tot = sum(w for _, w in outcomes)
    return sum(w for o, w in outcomes if event(o)) / tot

# ---- two fair coins, a quarter and a dime: 4 outcomes, weight 1 each ----
coins = [((q, d), 1) for q in (1, 0) for d in (1, 0)]
A = lambda o: o[0] == 1              # quarter heads
B = lambda o: o[1] == 1              # dime heads
C = lambda o: o[0] == o[1]           # the coins match
Ac = lambda o: not A(o)
both = lambda e, f: (lambda o: e(o) and f(o))
pA, pB, pAB = prob(coins, A), prob(coins, B), prob(coins, both(A, B))
assert abs(pAB - pA * pB) < 1e-12    # counted overlap equals the product of the counted chances
print("two coins: P(A) =", f4(pA), " P(B) =", f4(pB), " P(A and B) =", f4(pAB), " product =", f4(pA * pB))
print("given the dime: P(A | B) =", f4(pAB / pB))
pABc = prob(coins, both(A, lambda o: not B(o)))
assert abs(pABc - pA * (1 - pB)) < 1e-12 and prob(coins, both(A, Ac)) == 0 < pA * (1 - pA)
print("A with not-B: joint =", f4(pABc), " product =", f4(pA * (1 - pB)))
print("A with itself: joint =", f4(prob(coins, both(A, A))), " product =", f4(pA * pA))
print("A with not-A: joint =", f4(prob(coins, both(A, Ac))), " product =", f4(pA * (1 - pA)))

# ---- pairwise versus mutual ----
def equations(outcomes, events):     # every choice of two or more events: does the product rule hold?
    held, n = 0, len(events)
    subsets = [m for m in range(1, 1 << n) if bin(m).count("1") >= 2]
    for m in subsets:
        chosen = [events[i] for i in range(n) if m >> i & 1]
        joint = prob(outcomes, lambda o: all(e(o) for e in chosen))
        prod = 1.0
        for e in chosen: prod *= prob(outcomes, e)
        held += abs(joint - prod) < 1e-12
    return held, len(subsets)
h3, t3 = equations(coins, [A, B, C])
pABC = prob(coins, lambda o: A(o) and B(o) and C(o))
assert (h3, t3) == (3, 4) and abs(pABC - 0.125) > 0.1   # pairs pass, the triple fails
print("match event: P(C) =", f4(prob(coins, C)), " P(A and C) =", f4(prob(coins, both(A, C))), " P(B and C) =", f4(prob(coins, both(B, C))))
print("triple: P(A and B and C) =", f4(pABC), " product =", f4(0.5 ** 3), f" equations holding = {h3} of {t3}")
three = [((q, d, k), 1) for q in (1, 0) for d in (1, 0) for k in (1, 0)]
h, t = equations(three, [lambda o: o[0] == 1, lambda o: o[1] == 1, lambda o: o[2] == 1])
assert (h, t) == (4, 4)                 # three separate coins pass every equation
print(f"three separate coins: equations holding = {h} of {t}")

# ---- conditioning can break independence: learn 'at least one head' ----
Mh = lambda o: A(o) or B(o)
pM = prob(coins, Mh)
pAM, pBM, pABM = [prob(coins, both(e, Mh)) / pM for e in (A, B, both(A, B))]
assert abs(pABM - pAM * pBM) > 0.1       # given M the product rule fails
print("given M: P(A | M) =", f4(pAM), " P(A and B | M) =", f4(pABM), " product =", f4(pAM * pBM))

# ---- a bag: fair coin or bent coin (heads 0.9), chosen 50/50, tossed twice ----
qb = 0.9
bag = [(("fair", a, b), 25) for a in (1, 0) for b in (1, 0)]        # weights out of 200
bag += [(("bent", a, b), (9 if a else 1) * (9 if b else 1)) for a in (1, 0) for b in (1, 0)]
H1 = lambda o: o[1] == 1; H2 = lambda o: o[2] == 1
eH1, eHH = prob(bag, H1), prob(bag, lambda o: H1(o) and H2(o))
fH1, fHH = 0.5 * 0.5 + 0.5 * qb, 0.5 * 0.5 ** 2 + 0.5 * qb ** 2        # formula road: total probability
assert abs(eH1 - fH1) < 1e-12 and abs(eHH - fHH) < 1e-12 and eHH - eH1 * eH1 > 0.03   # dependent
print("bag: P(H1) =", f4(eH1), " P(H1 and H2) =", f4(eHH), " product =", f4(eH1 * eH1), " P(H2 | H1) =", f4(eHH / eH1))
for c in ("fair", "bent"):
    sub = [x for x in bag if x[0][0] == c]
    print(f"given {c}: P(H1 and H2) =", f4(prob(sub, lambda o: H1(o) and H2(o))), " product =", f4(prob(sub, H1) * prob(sub, H2)))
print("chart, all n tosses heads: n, true, if independent")
for n in range(1, 9):
    print(f"chart, {n}, {0.5 * 0.5 ** n + 0.5 * qb ** n:.2f}, {fH1 ** n:.2f}")
print("eight heads: true", f4(0.5 * 0.5 ** 8 + 0.5 * qb ** 8), " if independent", f4(fH1 ** 8))

# ---- simulation road, seed 20260928, 100000 trials each ----
s, N = 20260928, 100000
print(f"simulation: seed {s}, {N} trials")
kAB = kHH = 0
for _ in range(N):
    s, u1 = uniform(s); s, u2 = uniform(s)
    kAB += (u1 < 0.5) and (u2 < 0.5)
    s, u0 = uniform(s); p = 0.5 if u0 < 0.5 else qb
    s, u1 = uniform(s); s, u2 = uniform(s)
    kHH += (u1 < p) and (u2 < p)
for name, k, exact in (("coins P(A and B)", kAB, pAB), ("bag P(H1 and H2)", kHH, eHH)):
    est = k / N; se = sqrt(est * (1 - est) / N)
    assert abs(est - exact) < 4 * se     # simulation agrees within four standard errors
    print(f"simulated {name} = {f4(est)}, standard error {f4(se)}")

# ---- Simpson: two mints, quarters and dimes, accepted by a counting machine ----
mint = {"X": ((90, 100), (250, 400)), "Y": ((340, 400), (60, 100))}   # (accepted, struck): quarters, dimes
pool = {}
for m, ((aq, nq), (ad, nd)) in mint.items():
    wq = nq / (nq + nd)
    pool[m] = wq * aq / nq + (1 - wq) * ad / nd                          # weighted road
    assert abs(pool[m] - (aq + ad) / (nq + nd)) < 1e-12                # direct count road
    print(f"mint {m}: quarters {aq}/{nq} = {f4(aq / nq)}, dimes {ad}/{nd} = {f4(ad / nd)}, all {aq + ad}/{nq + nd}, quarter share {f4(wq)}, pooled {f4(pool[m])}")
(xq, xd), (yq, yd) = [(a / n, b / k) for (a, n), (b, k) in mint.values()]
wx, wy = [n / (n + k) for (_, n), (_, k) in mint.values()]
within = wx * (xq - yq) + (1 - wx) * (xd - yd); mix = (wx - wy) * (yq - yd)
assert xq > yq and xd > yd and pool["X"] < pool["Y"] and abs(within + mix - (pool["X"] - pool["Y"])) < 1e-12
print("gap X - Y: quarters", f4(xq - yq), " dimes", f4(xd - yd))
print("gap X - Y: within types =", f4(within), " mix =", f4(mix), " total =", f4(within + mix))
print("same 50/50 mix: X =", f4((xq + xd) / 2), " Y =", f4((yq + yd) / 2))

# ---- a real misuse: one cot death in 8,543 squared for two ----
print("squared 1 in 8543: 1 in", 8543 ** 2)
x0, y0, side = 60, 20, 200                                            # the picture, drawn to scale
print(f"figure, square x {x0}-{x0 + side}, A x {x0}-{x0 + round(side * pA)}, B y {y0}-{y0 + round(side * pB)}, overlap share {f4(pAB)}")
