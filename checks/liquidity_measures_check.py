"""Liquidity of three stocks: effective spread, Amihud illiquidity, depth, resilience."""
from math import sqrt, log, exp

M64 = (1 << 64) - 1
class Rng:                                     # splitmix64, written out so Rust can match it bit for bit
    def __init__(self, seed): self.x = seed
    def u(self):                               # uniform on [0, 1)
        self.x = (self.x + 0x9E3779B97F4A7C15) & M64
        z = self.x
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0

NAMES = ("Acme", "Beacon", "Cobble")
MID = (10000, 4000, 1000)                      # quote midpoint, cents
HALF = (1, 2, 1)                               # quoted half-spread, cents: bid = mid - half, ask = mid + half
DEPTH = (2000, 2500, 5000)                     # shares shown at each one-cent bid level
KAPPA = (0.7, 0.25, 0.07)                      # refill rate of the missing depth, per minute
DAYS = (  # (close-to-close return in bp, dollar volume in $ millions), five days each
    ((80, 100), (-150, 120), (60, 100), (-100, 100), (135, 100)),
    ((100, 25), (-160, 20), (60, 20), (-50, 25), (45, 15)),
    ((120, 10), (-200, 16), (70, 10), (-90, 12), (110, 10)))

def tape(i):                                   # (side: +1 buy, -1 sell; shares; price in cents)
    m, h = MID[i], HALF[i]
    return ((1, 500, m + h), (-1, 300, m - h), (1, 200, m))

def effective(i):                              # share-weighted 2 s (p - m) / m, in bp
    num = den = 0.0
    for s, q, p in tape(i):
        num += q * 2.0 * s * (p - MID[i]) / MID[i] * 1e4
        den += q
    return num / den

def amihud(i, scale=1.0, signed=False):        # mean over days of |r| / V, bp per $1 million
    tot = 0.0
    for r, v in DAYS[i]:
        tot += (r if signed else abs(r)) / (v * scale)
    return tot / len(DAYS[i])

def ratio_of_sums(i):                          # the wrong aggregation
    sr = sv = 0.0
    for r, v in DAYS[i]: sr += abs(r); sv += v
    return sr / sv

def sim(mid, h, keep, seed, n=20000):          # road 2 for the spread: a long tape, then Roll
    g, m, s, direct, psum, prices = Rng(seed), mid, 1, 0.0, 0.0, []
    for _ in range(n):
        m += h * (2.0 * g.u() - 1.0)           # the fair price wanders
        if g.u() >= keep: s = -s               # keep = 0.5 means independent buy/sell signs
        p = m + s * h
        direct += 2.0 * s * (p - m) / m * 1e4
        psum += p; prices.append(p)
    sx = sy = sxy = 0.0                        # covariance of each price change with the one before
    for k in range(1, n - 1):
        a, b = prices[k + 1] - prices[k], prices[k] - prices[k - 1]
        sx += a; sy += b; sxy += a * b
    c = n - 2; cov = sxy / c - (sx / c) * (sy / c)
    return direct / n, 2.0 * sqrt(-cov) / (psum / n) * 1e4

def walk(i, shares):                           # road 1 for depth: take the bid levels one by one
    left, k, cost = shares, 0, 0
    while left > 0:
        take = min(DEPTH[i], left)
        cost += take * (HALF[i] + k)           # cents below the midpoint at level k
        left -= take; k += 1
    return cost

def closed(i, shares):                         # road 2: the arithmetic series in one line
    d, h = DEPTH[i], HALF[i]
    n, r = divmod(shares, d)
    return d * (n * h + n * (n - 1) // 2) + r * (h + n)

def cost_bp(i, dollars_m, road=walk):
    shares = int(dollars_m * 1e6 * 100) // MID[i]
    return road(i, shares) / shares / MID[i] * 1e4

def depth_dollars(i, band_bp=20):              # dollars bid within band_bp of the midpoint
    tot, k = 0, 0
    while (HALF[i] + k) * 10000 <= band_bp * MID[i]:
        tot += DEPTH[i] * (MID[i] - HALF[i] - k); k += 1
    return tot / 100.0

def median_refill(kappa, seed, n=20001):       # road 2 for resilience: each gap refills at a random time
    g = Rng(seed)
    t = sorted(-log(1.0 - g.u()) / kappa for _ in range(n))
    return t[n // 2]

R = range(3)
eff = [effective(i) for i in R]
sims = [sim(MID[i] / 100.0, eff[i] / 2e4 * MID[i] / 100.0, 0.5, 11 + i) for i in R]
split = sim(100.0, eff[0] / 2e4 * 100.0, 0.8, 99)
ami = [amihud(i) for i in R]
hl = [log(2.0) / KAPPA[i] for i in R]
hl_mc = [median_refill(KAPPA[i], 21 + i) for i in R]
cost1 = [cost_bp(i, 1.0) for i in R]
dep = [depth_dollars(i) for i in R]

def row(label, vals, d=4):
    print(f"{label:<40}" + "".join(f"{v:>11.{d}f}" for v in vals))
print(f"{'measure':<40}" + "".join(f"{n:>11}" for n in NAMES))
row("quoted spread, bp", [2e4 * HALF[i] / MID[i] for i in R])
for i in (0, 2):
    row(f"{NAMES[i]} tape, each trade, bp", [2.0 * s * (p - MID[i]) / MID[i] * 1e4 for s, q, p in tape(i)])
row("effective spread, 3-trade tape, bp", eff)
row("long tape: effective, direct, bp", [s[0] for s in sims])
row("long tape: Roll, prices only, bp", [s[1] for s in sims])
for i in (0, 2):
    row(f"{NAMES[i]} days, |r| / V", [abs(r) / v for r, v in DAYS[i]])
row("Amihud, bp per $1m", ami)
row("depth within 20 bp of mid, $", dep, 2)
for m in (0.25, 0.5, 1.0, 2.0):
    row(f"sell ${m:.2f}m, walk the book, bp", [cost_bp(i, m) for i in R], 2)
row("sell $1.00m, closed form, bp", [cost_bp(i, 1.0, closed) for i in R], 2)
row("$1m sale: shares; then levels walked", [10**8 // MID[i] for i in R] + [10**8 // MID[i] / DEPTH[i] for i in R], 0)
row("half-life ln2/kappa, minutes", hl)
row("half-life, median of 20001 gaps", hl_mc)
for t in range(11):
    row(f"refilled %, minute {t}", [100.0 * (1.0 - exp(-KAPPA[i] * t)) for i in R], 2)
row("shares a day, millions", [sum(v for _, v in DAYS[i]) / 5 / (MID[i] / 100.0) for i in R])
row("wrong: Amihud as ratio of sums", [ratio_of_sums(i) for i in R])
row("wrong: Amihud with signed returns", [amihud(i, signed=True) for i in R])
row("wrong: half-spread reported, bp", [e / 2 for e in eff])
row("wrong: split orders: true, Roll, ratio", [split[0], split[1], split[1] / split[0]])
row("Amihud with volumes x10", [amihud(i, 10.0) for i in R])
row("house: sell 100,000 Acme: bp, $, levels", [walk(0, 100000) / 100000 / MID[0] * 1e4,
                                              walk(0, 100000) / 100.0, 100000 / DEPTH[0]], 2)
row("Cobble/Acme: eff, Amihud, $1m sell", [eff[2] / eff[0], ami[2] / ami[0], cost1[2] / cost1[0]], 2)
row("half-life C/A, sim C/A; depth A/C", [hl[2] / hl[0], hl_mc[2] / hl_mc[0], dep[0] / dep[2]], 2)

assert all(abs(a - b) < 1e-9 for a, b in zip(eff, (1.6, 8.0, 16.0))), "tape vs the hand table"
assert all(abs(s[1] / s[0] - 1.0) < 0.05 for s in sims), "Roll from prices alone within 5% of the direct spread"
assert all(abs(a - b) < 1e-12 for a, b in zip(ami, (1.0, 4.0, 10.0))), "Amihud vs the hand table"
assert all(abs(amihud(i, 10.0) * 10.0 - ami[i]) < 1e-12 for i in R), "ten times the dollars, a tenth the measure"
assert all(walk(i, s) == closed(i, s) for i in R for s in (2500, 6250, 25000, 99999, 200000)), "book walk vs series"
assert all(abs(hl_mc[i] / hl[i] - 1.0) < 0.04 for i in R), "simulated median refill vs ln2/kappa"
assert abs(split[1] / split[0] - 0.4) < 0.08, "split orders: theory says Roll reads 2h sqrt(0.16) = 0.4 of the truth"
assert eff[0] < eff[1] < eff[2] and ami[0] < ami[1] < ami[2] and dep[0] > dep[1] > dep[2], "one ranking"
print("ranking, most liquid first: Acme, Beacon, Cobble on every measure")
print("ALL CHECKS PASS")
