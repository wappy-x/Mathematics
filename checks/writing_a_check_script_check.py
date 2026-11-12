# The check script -- the check behind the card.  Standard library only.
# Re-derives this wing's EOQ and queue numbers two ways each, compares them with the
# card to half a unit in the last printed digit, and exits 1 on any failure.
# Then it breaks things on purpose and confirms each break is caught.
import sys, subprocess
from math import sqrt, log

CARD = [  # copied by hand from the cards, exactly as printed; never computed here
    ("EOQ order size Q*, cases", "707.1"), ("EOQ yearly cost, pounds", "1838.48"),
    ("EOQ best whole order, cases", "707"), ("EOQ deliveries a year", "7.35"),
    ("queue busy share rho", "0.9167"), ("queue Lq, people in line", "10.083"),
    ("queue Wq, minutes in line", "11.00"), ("queue W, minutes in shop", "12.00"),
    ("two tills P(wait)", "0.2881"), ("two tills Wq, minutes", "0.27"),
]
K, D, H, LAM, MU, MASK = 125.0, 5200.0, 2.60, 55.0, 60.0, (1 << 64) - 1

def cuts(lam, mu, c, nmax=4000):  # balance state by state: lam p[n] = min(n+1, c) mu p[n+1]
    p = [1.0]
    for n in range(nmax): p.append(p[-1] * lam / (min(n + 1, c) * mu))
    s = sum(p)
    p = [x / s for x in p]
    L = sum(n * x for n, x in enumerate(p))
    Lq = sum((n - c) * p[n] for n in range(c, len(p)))
    return p, L, Lq

def derive(lam=LAM, mu=MU, bug=""):  # road 1 = closed form, road 2 = a different computation
    two = 1.0 if bug == "drop the 2" else 2.0
    q1 = sqrt(two * K * D / H)
    lo, hi = 1.0, 1e5                  # road 2: bisect on "holding cost = ordering cost"
    for _ in range(200):
        mid = (lo + hi) / 2
        if H * mid / 2 < K * D / mid: lo = mid
        else: hi = mid
    cost = lambda q: K * D / q + H * q / 2
    best = min(range(1, 5001), key=cost)  # every whole order size from 1 to 5,000
    rho = lam / mu
    p1, L1, Lq1 = cuts(lam, mu, 1)
    wq = 1 / (mu - lam) if bug == "W for Wq" else rho / (mu - lam)
    a = lam / mu
    top = a * a / 2 / (1 - a / 2)      # Erlang C with two tills
    pw = top / (1 + a + top)
    p2, L2, Lq2 = cuts(lam, mu, 2)
    return [(q1, lo), (sqrt(two * K * D * H), cost(lo)), (round(q1), best), (D / q1, D / lo),
            (rho, 1 - p1[0]), (rho * rho / (1 - rho), Lq1), (60 * wq, 60 * Lq1 / lam),
            (60 / (mu - lam), 60 * L1 / lam), (pw, 1 - p2[0] - p2[1]), (60 * pw / (2 * mu - lam), 60 * Lq2 / lam)]

def decimals(s): return len(s.split(".")[1]) if "." in s else 0

def compare(card, vals, rule="half-unit"):  # the labels of every claim that fails
    fails = []
    for (label, printed), (r1, r2) in zip(card, vals):
        if rule == "itself": ok = abs(r1 - r1) <= 1e-9   # the tautology, kept only to show it
        else:
            tol = 0.5 * 10.0 ** -decimals(printed) if rule == "half-unit" else 0.01 * abs(float(printed))
            ok = all(abs(r - float(printed)) <= tol * (1 + 1e-9) for r in (r1, r2))
        if not ok: fails.append(label)
    return fails

def edit(card, label, printed): return [(l, printed if l == label else p) for l, p in card]

if "--break" in sys.argv:  # run as a child with one card number mistyped; the exit code is the verdict
    sys.exit(1 if compare(edit(CARD, CARD[0][0], "701.7"), derive()) else 0)

def splitmix(seed):
    s = seed
    while True:
        s = (s + 0x9E3779B97F4A7C15) & MASK
        z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        yield ((z ^ (z >> 31)) >> 11) / 9007199254740992.0

def simulate(seed, n=1000000, batches=20):  # Lindley: next wait = max(0, wait + service - gap)
    u, w, acc, means = splitmix(seed), 0.0, 0.0, []
    for i in range(n):
        acc += w
        if (i + 1) % (n // batches) == 0: means.append(60 * acc / (n // batches)); acc = 0.0
        w = max(0.0, w - log(1 - next(u)) / MU + log(1 - next(u)) / LAM)
    m = sum(means) / batches
    return m, sqrt(sum((x - m) ** 2 for x in means) / (batches - 1) / batches)

bad = []
def check(ok, what):  # an assert that survives python -O: it records, and the exit code reports
    if not ok: bad.append(what); print("FAIL", what)

vals = derive()
for (label, printed), (r1, r2) in zip(CARD, vals):
    d = decimals(printed)
    print(f"{label}: card {printed}, road 1 {r1:.4f}, road 2 {r2:.4f}, allowed +/- {0.5 * 10.0 ** -d:.{d + 1}f}")
check(compare(CARD, vals) == [], "every card number within half a unit, both roads")
q, lq = vals[0][0], vals[5][0]
print(f"by hand: Q* off by {abs(q - 707.1):.4f} from 707.1, {abs(q - 701.7):.4f} from 701.7; "
      f"Lq off by {abs(lq - 10.083):.4f} from 10.083, {abs(lq - 10.038):.4f} from 10.038; 1% of 10.038 is {0.01 * 10.038:.4f}")
print(f"by hand: drop the 2 and Q* is {derive(bug='drop the 2')[0][0]:.4f}; W for Wq gives {derive(bug='W for Wq')[6][0]:.4f} min")
m, se = simulate(2026)
print(f"road 3, simulated Wq, 1,000,000 customers, seed 2026: {m:.2f} min, standard error {se:.2f}")
check(abs(m - vals[6][0]) <= 4 * se, "simulation within 4 standard errors of 11.00")

BREAKS = [("card typo: Q* 707.1 -> 701.7", edit(CARD, CARD[0][0], "701.7"), "", "half-unit", 0),
          ("code drops the 2 in Q*", CARD, "drop the 2", "half-unit", 0),
          ("code uses W for Wq", CARD, "W for Wq", "half-unit", 6),
          ("card typo: Lq 10.083 -> 10.038", edit(CARD, CARD[5][0], "10.038"), "", "half-unit", 5),
          ("card typo: Lq 10.083 -> 10.038", edit(CARD, CARD[5][0], "10.038"), "", "1% rel", 5),
          ("code drops the 2 in Q*", CARD, "drop the 2", "itself", 0)]
hits = []
for name, card, bug, rule, target in BREAKS:  # is the broken number itself among the failures?
    fails = compare(card, derive(bug=bug), rule)
    hits.append(CARD[target][0] in fails)
    print(f"break: {name:<31} rule {rule:<9} failing {len(fails)}  {'caught' if hits[-1] else 'MISSED'}")
check(hits == [True, True, True, True, False, False], "half-unit catches all four breaks; 1% and itself miss")
print(f"false alarm under the 1% rule: {', '.join(compare(CARD, vals, '1% rel'))}, off by {0.27 - vals[9][0]:.4f}, allowed {0.01 * 0.27:.4f}")
check(compare(CARD, vals, "1% rel") == [CARD[9][0]], "the 1% rule flags the correct 0.27")

child = subprocess.run([sys.executable, "-B", __file__, "--break"], capture_output=True).returncode
stripped = subprocess.run([sys.executable, "-O", "-c", "assert 707.1 == 701.7"], capture_output=True).returncode
print(f"exit code, this script run on the mistyped card: {child}")
print(f"exit code, a false assert the optimiser strips: {stripped}")
check(child == 1, "a broken card makes the script exit 1")
check(stripped == 0, "the stripped assert lets a false claim exit 0")

n59 = compare(CARD, derive(lam=59.0))
print(f"try: 59 arrivals an hour, card unchanged: {len(n59)} failing, Wq now {derive(lam=59.0)[6][0]:.2f} min")
check(len(n59) == 6, "every queue number moves when the arrival rate does")
print(f"try: simulated Wq held to +/- 0.005: off by {abs(m - 11.0):.2f}, {'pass' if abs(m - 11.0) <= 0.005 else 'fail'}")
m2, se2 = simulate(7)
print(f"try: seed 7: simulated Wq {m2:.2f} min, standard error {se2:.2f}, within 4 se: {'yes' if abs(m2 - 11.0) <= 4 * se2 else 'no'}")

if bad:
    print(f"{len(bad)} CHECKS FAILED")
    sys.exit(1)
print("ALL CHECKS PASS")
