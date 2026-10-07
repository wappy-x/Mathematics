# Zero-coupon inflation swap -- the check behind the card.  Standard library only.
# The 5-year par rate is reached three ways: (1) the ratio of two bond prices,
# (2) bisection on the two legs' values, (3) state-by-state sums in four random
# economies that agree on those two bond prices and on nothing else.
from math import log, exp, sqrt, cos, pi

N, F, C = 1_000_000.0, 1_000_000.0, 0.01           # swap notional; linker face and real coupon
Y = 0.01                                           # real zero yield, every maturity
NOM = {1: .0302, 2: .03222, 3: .033735, 4: .03525, 5: .03626, 7: .035755, 10: .03525}
J_SO_FAR, K_OLD, T_OLD = 1.06, 0.023, 7            # seasoned swap: index up 6%, struck at 2.3%, 7 years

def D(t): return (1 + NOM[t]) ** -t                # nominal zero: one dollar at t
def R(t): return (1 + Y) ** -t                     # real zero: pays the index ratio at t, in dollars
def par(t): return (R(t) / D(t)) ** (1 / t) - 1    # road 1: the ratio of the two bond prices
def A(t): return (1 + par(t)) ** t                 # index forward: today's price of the ratio, per D(t)

def bisect(f, lo, hi, n=100):                      # root finder, written out
    flo = f(lo)
    for _ in range(n):
        mid = 0.5 * (lo + hi); fm = f(mid)
        if (fm > 0) == (flo > 0): lo, flo = mid, fm
        else: hi = mid
    return 0.5 * (lo + hi)

def value(k, j0=1.0, e=5):                         # inflation receiver's value today, 5 years left
    return N * (j0 * R(5) - (1 + k) ** e * D(5))

class Rng:                                          # 64-bit linear congruential generator
    def __init__(self, seed): self.s = seed
    def u(self):
        self.s = (6364136223846793005 * self.s + 1442695040888963407) % 2 ** 64
        return ((self.s >> 11) + 0.5) / 2.0 ** 53
    def normal(self): return sqrt(-2 * log(self.u())) * cos(2 * pi * self.u())

def economy(seed, vol, tilt, S=4000):              # road 3: a made-up world of S states at year 5
    g = Rng(seed)
    z = [g.normal() for _ in range(S)]
    J = [exp(vol * sqrt(5) * x) for x in z]        # index ratio in each state
    w = [exp(tilt * x + 0.3 * g.normal()) for x in z]
    sw = sum(w)
    psi = [D(5) * x / sw for x in w]               # state prices: sum to the nominal bond
    sc = R(5) / sum(p * j for p, j in zip(psi, J)) # rescale so the real bond is priced right
    J = [j * sc for j in J]
    val = lambda k, j0=1.0, e=5: sum(p * N * (j0 * j - (1 + k) ** e) for p, j in zip(psi, J))
    plain = (sum(J) / S) ** 0.2 - 1                # equal-chance average: a forecast, not a price
    return plain, bisect(val, -0.5, 0.5), val(K_OLD, J_SO_FAR, T_OLD)

def show(name, v): print(f"{name:<40} {round(v, 6) + 0.0:>16.6f}")

print(f"inputs: notional {N:.2f}  real yield {100 * Y:.2f}%  index so far {J_SO_FAR:.2f}  old fixed {100 * K_OLD:.2f}% for {T_OLD}y")
k1, k2 = par(5), bisect(value, -0.5, 0.5)
seasoned = value(K_OLD, J_SO_FAR, T_OLD)
for name, v in (("nominal zero D(5)", D(5)), ("real zero R(5)", R(5)), ("index forward A(5)", A(5)),
                ("par rate, road 1 bond ratio %", 100 * k1), ("par rate, road 2 bisection %", 100 * k2),
                ("seasoned inflation leg, N 1.06 R(5)", N * J_SO_FAR * R(5)), ("old fixed factor 1.023^7", (1 + K_OLD) ** T_OLD),
                ("seasoned fixed leg, N 1.023^7 D(5)", N * (1 + K_OLD) ** T_OLD * D(5)), ("seasoned swap value, formula", seasoned)): show(name, v)
econ = [economy(11, .01, 0.0), economy(22, .02, -1.0), economy(33, .03, 1.0), economy(44, .04, 0.5)]
for i, (plain, kp, sv) in enumerate(econ, 1):
    print(f"economy {i}: plain average {100 * plain:.4f}%  par {100 * kp:.6f}%  seasoned {sv:.6f}")
payout = N * (1.15 - A(5))
show("receiver gets, index ratio 1.15", payout); show("zero linker plus pay-inflation swap", N * 1.15 - payout)

h, b, n5 = 1e-4, k1, NOM[5]                         # Greeks: +1 basis point, analytic then by bump
vb = lambda bb, j0, k, e: N * D(5) * (j0 * (1 + bb) ** 5 - (1 + k) ** e)
vn = lambda nn, j0, k, e: N * (1 + nn) ** -5 * (j0 * A(5) - (1 + k) ** e)
gaps = []
for tag, j0, k, e in (("par", 1.0, k1, 5), ("seasoned", J_SO_FAR, K_OLD, T_OLD)):
    v0 = vb(b, j0, k, e)
    be, be_b = N * D(5) * j0 * 5 * (1 + b) ** 4 * h, (vb(b + h, j0, k, e) - vb(b - h, j0, k, e)) / 2
    no, no_b = -5 * v0 / (1 + n5) * h, (vn(n5 + h, j0, k, e) - vn(n5 - h, j0, k, e)) / 2
    gaps += [abs(be - be_b), abs(no - no_b)]
    print(f"{tag:<9} breakeven01 {be:10.4f} bump {be_b:10.4f}  nominal01 {round(no, 4) + 0.0:9.4f} bump {round(no_b, 4) + 0.0:9.4f}"
          f"  index01 {N * R(5) * 0.001:9.4f}")

TEN = [1, 2, 3, 4, 5, 7, 10]                        # the breakeven curve and its forward segments
fwd, prev = {}, 0
for t in TEN:
    fwd[t] = (A(t) / (A(prev) if prev else 1.0)) ** (1 / (t - prev)) - 1
    print(f"curve {t:>2}y  nominal {100 * NOM[t]:.4f}%  breakeven {100 * par(t):.4f}%  A {A(t):.6f}  forward {100 * fwd[t]:.4f}%")
    prev = t
print("chart, breakeven %  " + " ".join(f"{100 * par(t):.2f}" for t in TEN))
print("chart, forward %    " + " ".join(f"{100 * fwd[t]:.2f}" for t in TEN))
seg = lambda yr: fwd[min(t for t in TEN if t >= yr)]
rebuilt = 1.0
for yr in range(1, 11): rebuilt *= 1 + seg(yr)      # ten one-year forward factors, multiplied
show("10y rebuilt from forwards %", 100 * (rebuilt ** 0.1 - 1)); show("6y by flat forward %", 100 * ((A(5) * (1 + seg(6))) ** (1 / 6) - 1))

price = sum(C * F * R(t) for t in range(1, 6)) + F * R(5)          # the linker, real discounting
HEDGE = [10_000.0] * 4 + [1_010_000.0]              # pay-inflation swap notionals, as the card's table
locked = [n * A(t) for n, t in zip(HEDGE, range(1, 6))]
pv_locked = sum(l * D(t) for l, t in zip(locked, range(1, 6)))
g, worst, worst_p, floored, worst_floor = Rng(7), 0.0, 0.0, 0, 0.0
for _ in range(20000):                              # random inflation paths, hedged cash each year
    J = 1.0
    for t in range(1, 6):
        J *= 1 + 0.025 + 0.02 * g.normal()
        note = (C * F + (F if t == 5 else 0)) * J                   # the linker's cash this year
        worst = max(worst, abs(note + HEDGE[t - 1] * (A(t) - J) - locked[t - 1]))
        worst_p = max(worst_p, abs(note + (F * (A(5) - J) if t == 5 else 0) - locked[t - 1]))
    if J < 1: floored += 1; worst_floor = max(worst_floor, F * (1 - J))
show("linker price, real discounting", price); show("hedged cash, nominal discounting", pv_locked)
print("locked cash, years 1-5 " + " ".join(f"{x:.2f}" for x in locked))
print(f"paths 20000  worst hedge miss {worst:.6f}  paths under base {floored}  worst floor residue {worst_floor:.2f}")
show("floor residue, index ratio 0.95", F * max(0.95, 1) + F * (A(5) - 0.95) - F * A(5))

miss4 = sum(C * F * (1.04 ** t - A(t)) for t in range(1, 6))
for name, v in (("wrong: simple fixed leg, payout at 1.15", N * (1.15 - (1 + 5 * .026))),
                ("wrong: new swap valued with simple leg", N * (R(5) - (1 + 5 * .026) * D(5))),
                ("wrong: seasoned marked as new", value(K_OLD)),
                ("wrong: seasoned discounted at real rate", N * R(5) * (J_SO_FAR * A(5) - (1 + K_OLD) ** T_OLD)),
                ("wrong: principal-only hedge, 4% coupons", miss4),
                ("try: old swap at 2.5%, same dates", value(0.025)), ("try: payout if inflation is 2.6%", N * (1.026 ** 5 - A(5)))):
    show(name, v)
pis = [0.005 * i for i in range(11)]
print("chart, inflation % a year " + " ".join(f"{100 * p:.1f}" for p in pis))
print("chart, payout $000        " + " ".join(f"{N * ((1 + p) ** 5 - A(5)) / 1000:.2f}" for p in pis))

assert abs(k1 - 0.026) < 1e-12, "bond ratio must give the 2.6% quote"
assert abs(k2 - k1) < 1e-12, "bisection on the legs lands on the ratio"
assert all(abs(kp - k1) < 1e-10 and abs(sv - seasoned) < 1e-6 for _, kp, sv in econ), "every economy agrees"
assert max(p for p, _, _ in econ) - min(p for p, _, _ in econ) > 0.001, "forecasts differ, prices do not"
assert abs(payout - 13061.943239) < 1e-5, "audited payout at index ratio 1.15"
assert abs(rebuilt - 1.025 ** 10) < 1e-12, "forwards multiply back to the 10-year house breakeven"
assert abs(price - F) < 1e-6 and abs(pv_locked - F) < 1e-6, "coupon equals real yield: both roads price the linker at face"
assert worst < 1e-6 and worst_p > 100, "the strip hedge leaves no inflation on any path; principal-only does"
assert max(gaps) < 0.005, "every Greek matches its bump to the cent"
print("ALL CHECKS PASS")
