# Mortgage-backed securities in outline -- the check behind the card.  Standard
# library only: the random numbers, the rate model and the waterfall are written
# here.  Pool: $100 of 30-year loans at 6%, monthly.  Slices: sequential A, B, C
# and an interest-only / principal-only pair.  Prices by simulating rate paths.
from math import exp, log, sqrt, cos, pi

FACE, N, DT = 100.0, 360, 1.0 / 12.0
I = 0.06 / 12.0                                   # the note rate, per month
SIZES = (40.0, 35.0, 25.0)                        # tranches A, B, C, paid in this order
KAPPA, THETA, SIG, R0, SPREAD = 0.15, 0.05, 0.01, 0.05, 0.01
PAIRS, M64 = 500, (1 << 64) - 1

def smm(cpr):                                     # yearly prepayment rate -> monthly
    return 1.0 - (1.0 - cpr) ** (1.0 / 12.0)

def cpr_of(m):                                    # cheaper new loans -> faster prepayment
    return min(0.50, max(0.03, 0.08 + 8.0 * (0.06 - m)))

def month(bal, k, s):                             # one month: interest and all principal
    sched = bal * I / (1.0 - (1.0 + I) ** -(N - k + 1)) - I * bal
    return I * bal, sched + s * (bal - sched)

def split(tb, prin):                              # principal to A until retired, then B, then C
    out = []
    for j in range(3):
        x = min(tb[j], prin)
        tb[j] -= x
        prin -= x
        out.append(x)
    return out

def det(s, vm):          # road 1: one fixed path, monthly prepayment s, monthly discount vm
    bal, tb, d, pool, io, wal, bals = FACE, list(SIZES), 1.0, 0.0, 0.0, [0.0] * 3, []
    for k in range(1, N + 1):
        if (k - 1) % 24 == 0:
            bals.append(list(tb))
        d *= vm
        interest, prin = month(bal, k, s)
        for j, x in enumerate(split(tb, prin)):
            wal[j] += k / 12.0 * x / SIZES[j]
        pool, io, bal = pool + d * (interest + prin), io + d * interest, bal - prin
    bals.append(list(tb))
    return pool, io, pool - io, bals, wal

def io_closed(s, v):     # road 2: the IO as two geometric sums, no month loop
    g, q = 1.0 + I, (1.0 - s) * v
    first = v * (1.0 - q ** N) / (1.0 - q)
    second = g ** -N * v * (1.0 - (q * g) ** N) / (1.0 - q * g)
    return I * FACE / (1.0 - g ** -N) * (first - second)

class Rng:                                        # splitmix64, then Box-Muller
    def __init__(self, seed): self.s = seed
    def u(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return (((z ^ (z >> 31)) >> 11) + 0.5) / 2.0 ** 53
    def normal(self):
        return sqrt(-2.0 * log(self.u())) * cos(2.0 * pi * self.u())

def path(zs, shift, sig, fixed):  # road 3: one simulated rate path, every slice priced on it
    a = exp(-KAPPA * DT)
    sd = sig * sqrt((1.0 - a * a) / (2.0 * KAPPA))
    r, d, bal, tb, v = R0 + shift, 1.0, FACE, list(SIZES), [0.0] * 7
    for k in range(1, N + 1):
        rn = THETA + shift + (r - THETA - shift) * a + sd * zs[k - 1]
        d *= exp(-0.5 * (r + rn) * DT)            # trapezoid rule along the month
        s = smm(fixed if fixed else cpr_of(r + SPREAD))
        interest, prin = month(bal, k, s)
        coupons = [I * b for b in tb]
        for j, x in enumerate(split(tb, prin)):
            v[1 + j] += d * (coupons[j] + x)
        v[0] += d * (interest + prin)
        v[4] += d * interest
        v[5] += d * prin
        if k == 120:
            v[6] = d
        bal, r = bal - prin, rn
    return v

def price(shift, sig=SIG, fixed=None):            # antithetic pairs, same seed every time
    g, tot = Rng(2026), [0.0] * 7
    for _ in range(PAIRS):
        zs = [g.normal() for _ in range(N)]
        for sign in (1.0, -1.0):
            for j, x in enumerate(path([sign * z for z in zs], shift, sig, fixed)):
                tot[j] += x / (2 * PAIRS)
    return tot

def vasicek_zero(t):                              # the bond formula for the same rate model
    b = (1.0 - exp(-KAPPA * t)) / KAPPA
    return exp((THETA - SIG ** 2 / (2 * KAPPA ** 2)) * (b - t) - SIG ** 2 * b * b / (4 * KAPPA) - b * R0)

def row(label, x):
    print(f"{label:<44} {x:>12.6f}")

s8, v5, vn = smm(0.08), exp(-0.05 * DT), 1.0 / (1.0 + I)
pool5, io5, po5, bals, wal = det(s8, v5)
row("monthly prepayment rate at 8% CPR", s8)
it, pr = month(FACE, 1, 0.0)
print(f"first month per $100: payment {it + pr:.6f} = interest {it:.6f} + principal {pr:.6f}; prepaid {month(FACE, 1, s8)[1] - pr:.6f}")
row("flat 5%, 8% CPR: pass-through (loop)", pool5)
row("flat 5%, 8% CPR: IO (loop)", io5)
row("flat 5%, 8% CPR: IO (geometric sums)", io_closed(s8, v5))
row("flat 5%, 8% CPR: PO (loop)", po5)
print("at the 6% note rate: pass-through {:.6f} at 8% CPR, {:.6f} at 30%".format(det(s8, vn)[0], det(smm(0.3), vn)[0]))
print("chart, years      " + " ".join(f"{2 * i:6d}" for i in range(16)))
for j, name in enumerate("ABC"):
    print(f"chart, balance {name}  " + " ".join(f"{b[j]:6.2f}" for b in bals))
print("average life, years: A {:.2f}  B {:.2f}  C {:.2f}".format(*wal))
base = price(0.0)
for label, x in zip(("pool", "tranche A", "tranche B", "tranche C", "IO", "PO"), base):
    row("simulated, rates as today: " + label, x)
row("  A + B + C", base[1] + base[2] + base[3])
row("  IO + PO", base[4] + base[5])
row("10-year zero, simulated", base[6])
row("10-year zero, Vasicek formula", vasicek_zero(10.0))
shifts = {sh: base if sh == 0.0 else price(sh) for sh in (-0.02, -0.01, 0.0, 0.01, 0.02)}
for sh, p in shifts.items():
    print(f"shift {100 * sh:+.0f}%: pool {p[0]:7.2f}  IO {p[4]:6.2f}  PO {p[5]:6.2f}  A {p[1]:6.2f}  C {p[3]:6.2f}")
for label, j in (("pool", 0), ("IO", 4), ("PO", 5), ("tranche A", 1), ("tranche C", 3)):
    row("effective duration, years: " + label, (shifts[-0.01][j] - shifts[0.01][j]) / (0.02 * base[j]))
flat, fz0, fz1 = price(0.0, sig=0.0), price(0.0, fixed=0.08), price(0.01, fixed=0.08)
row("wrong: one flat path, no volatility: pool", flat[0])
row("wrong: one flat path, no volatility: PO", flat[5])
row("  flat-path pool minus simulated pool", flat[0] - base[0])
row("wrong: CPR / 12 as the monthly rate: IO", det(0.08 / 12.0, v5)[1])
print(f"wrong: prepayment frozen at 8%: pool {fz0[0]:.6f}, IO today {fz0[4]:.6f}")
row("wrong: prepayment frozen at 8%: IO at +1%", fz1[4])
row("wrong: pro rata, A's average life", sum(w * z for w, z in zip(wal, SIZES)) / FACE)
assert abs((1.0 - s8) ** 12 - 0.92) < 1e-12, "twelve months at the monthly rate must leave 92%"
assert abs(io5 - io_closed(s8, v5)) < 1e-9, "loop IO must equal the geometric-sum IO"
assert abs(det(smm(0.3), vn)[0] - FACE) < 1e-9, "at the note rate a pass-through is par"
assert abs(base[6] - vasicek_zero(10.0)) < 1e-3, "simulated zero must match the rate model's formula"
assert abs(flat[4] - io_closed(s8, v5)) < 1e-9, "zero volatility must collapse to the fixed path"
assert abs(base[1] + base[2] + base[3] - base[0]) < 1e-9, "tranches share out the pool, no more, no less"
assert shifts[0.01][4] > base[4] > shifts[-0.01][4], "the IO gains when rates rise"
assert bals[1][0] < SIZES[0] and all(b[1] == SIZES[1] for b in bals if b[0] > 0), "A is paid first; B waits"
print("ALL CHECKS PASS")
