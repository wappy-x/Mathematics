# Floating-rate notes and the discount margin -- the check behind the card.
# Standard library only; the forward rates, the two pricings and both root
# finders are written out here.  The note: 3 years, annual, pays the 1-year rate
# plus a quoted margin of 1.00% on a face of 100.  Every rate compounds once a year.
# Independent roads: the telescoping identity (par, exactly 100) against both
# pricings; on the flat curve, the bond formula F + F(m - d) x annuity against the
# solved margin; bisection against Newton's method.  The backward walk is the
# payment-by-payment sum regrouped, so comparing the two catches coding slips.
from math import exp, log

FACE, QM, YEARS = 100.0, 0.01, 3
FLAT = [0.04, 0.04, 0.04]                  # spot rates, 1 to 3 years: a flat 4% curve
SLOPED = [0.03, 0.04, 0.05]                # spot rates on a rising curve, for the contrast

def forwards(spot):                        # the 1-year rate each later year is priced at
    out, prev = [], 1.0
    for t, s in enumerate(spot, start=1):
        grow = (1.0 + s) ** t
        out.append(grow / prev - 1.0)
        prev = grow
    return out

def price_sum(fwd, dm, qm=QM):             # road one: each payment, discounted down the chain
    pv, chain = 0.0, 1.0
    for f in fwd:
        chain *= 1.0 + f + dm
        pv += FACE * (f + qm) / chain
    return pv + FACE / chain

def price_back(fwd, dm, qm=QM):            # road two: start at maturity, step back a reset at a time
    value = FACE
    for f in reversed(fwd):
        value = (FACE * (f + qm) + value) / (1.0 + f + dm)
    return value

def slope(fwd, dm, qm=QM):                 # d price / d dm, differentiated by hand, for Newton
    total, chain, run = 0.0, 1.0, 0.0
    for i, f in enumerate(fwd):
        chain *= 1.0 + f + dm
        run += 1.0 / (1.0 + f + dm)
        cash = FACE * (f + qm) + (FACE if i == len(fwd) - 1 else 0.0)
        total -= cash / chain * run
    return total

def bisect(g, lo=-0.5, hi=1.0):            # g falls from positive at lo to negative at hi
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if g(mid) > 0.0 else (lo, mid)
    return 0.5 * (lo + hi)

def newton(g, gp, x=0.0):
    for _ in range(60):
        x -= g(x) / gp(x)
    return x

def zspread(spot, fwd, p, cont=False):     # one extra rate on each date's own spot rate
    def pv(z):
        out = 0.0
        for t, (s, f) in enumerate(zip(spot, fwd), start=1):
            d = exp(-(log(1.0 + s) + z) * t) if cont else (1.0 + s + z) ** -t
            out += (FACE * (f + QM) + (FACE if t == len(spot) else 0.0)) * d
        return out
    return bisect(lambda z: pv(z) - p)

ff, fs = forwards(FLAT), forwards(SLOPED)
dm_bis = bisect(lambda d: price_sum(ff, d) - 99.0)
dm_new = newton(lambda d: price_back(ff, d) - 99.0, lambda d: slope(ff, d))
annuity5 = sum(1.05 ** -t for t in range(1, YEARS + 1))
hand = QM + (FACE - 99.0) / (FACE * annuity5)
annuity_dm = sum((1.0 + FLAT[0] + dm_bis) ** -t for t in range(1, YEARS + 1))   # at 4% plus the answer
dm_s = bisect(lambda d: price_sum(fs, d) - 99.0)
z_s = zspread(SLOPED, fs, 99.0)
z_par = zspread(SLOPED, fs, 100.0)
simple = QM + (FACE - 99.0) / FACE / YEARS
no_qm = bisect(lambda d: price_sum(ff, d, qm=0.0) - 99.0)
z_cont = zspread(FLAT, ff, 99.0, cont=True)
fixed = lambda y: sum(5.0 / (1.0 + y) ** t for t in range(1, 4)) + FACE / (1.0 + y) ** 3
after_fix = (FACE * (0.04 + QM) + price_back([0.05, 0.05], QM)) / (1.0 + 0.05 + QM)
pct = lambda x: f"{x * 100:.4f}%"
def show(label, v, unit=""): print(f"{label:<50}{v:>12}{unit}")

print("flat 4% curve: forwards " + ", ".join(pct(f) for f in ff)
      + "; projected coupons " + ", ".join(f"{FACE * (f + QM):.2f}" for f in ff))
show("price at DM 1.00%, payment by payment", f"{price_sum(ff, QM):.6f}")
show("price at DM 1.00%, backwards from maturity", f"{price_back(ff, QM):.6f}")
show("price on the curve alone, DM 0", f"{price_sum(ff, 0.0):.6f}")
show("DM at a price of 99, bisection", pct(dm_bis))
show("DM at a price of 99, Newton", pct(dm_new))
show("the note repriced at that DM", f"{price_back(ff, dm_bis):.6f}")
show("hand estimate: annuity at 5%", f"{annuity5:.6f}")
show("hand estimate: 1.00% + 1.00 / (100 x annuity)", pct(hand))
print()
print("rising curve 3%, 4%, 5%: forwards " + ", ".join(pct(f) for f in fs)
      + "; coupons " + ", ".join(f"{FACE * (f + QM):.4f}" for f in fs))
show("price at DM 1.00%, payment by payment", f"{price_sum(fs, QM):.6f}")
show("price at DM 1.00%, backwards from maturity", f"{price_back(fs, QM):.6f}")
show("DM at a price of 99", pct(dm_s))
show("z-spread at a price of 99", pct(z_s))
show("z-spread minus DM", f"{(z_s - dm_s) * 10000:.4f}", " bp")
show("z-spread of the same note at 100", f"{z_par * 10000:.4f}", " bp")
print()
print("what breaks (the right DM is " + pct(dm_bis) + ")")
show("the 1.00 discount spread evenly, undiscounted", pct(simple))
show("quoted margin left out of the coupons", pct(no_qm))
show("continuously compounded z-spread read as DM", pct(z_cont))
print()
print("how it moves")
show("curve up to 5%, DM still 1.00%: the floater", f"{price_back(forwards([0.05] * 3), QM):.6f}")
show("a 3-year 5% fixed bond at a 5% yield", f"{fixed(0.05):.6f}")
show("curve up to 5%: a 3-year 5% fixed bond, yield 6%", f"{fixed(0.06):.6f}")
show("curve at 4%, DM widens to 2.00%: the floater", f"{price_back(ff, 0.02):.6f}")
show("curve jumps to 5% just after the fixing", f"{after_fix:.6f}")
dms = [0.0050, 0.0075, 0.0100, 0.0125, 0.0150, 0.0175, 0.0200]
print(f"{'chart, DM in percent':<26}" + "".join(f"{d * 100:>8.2f}" for d in dms))
print(f"{'chart, price':<26}" + "".join(f"{price_sum(ff, d):>8.2f}" for d in dms))
print()
print("try changing")
show("price 98 instead of 99: DM", pct(bisect(lambda d: price_sum(ff, d) - 98.0)))
show("quoted margin 0.50%, market DM 1.00%: price", f"{price_sum(ff, QM, qm=0.005):.6f}")
long = [0.03 + 0.005 * k for k in range(10)]                    # 10 years, 3.0% up to 7.5%
gap = zspread(long, forwards(long), 99.0) - bisect(lambda d: price_sum(forwards(long), d) - 99.0)
show("10-year note, rising 3% to 7.5%, price 99: z - DM", f"{gap * 10000:.4f}", " bp")
assert abs(price_sum(ff, QM) - FACE) < 1e-9 and abs(price_sum(fs, QM) - FACE) < 1e-9   # telescoping: par
assert abs(price_sum(fs, 0.0137) - price_back(fs, 0.0137)) < 1e-10   # forward sum against backward walk
assert abs(slope(fs, 0.0137) - (price_back(fs, 0.013701) - price_back(fs, 0.013699)) / 2e-6) < 1e-5  # P'(d)
assert abs(dm_bis - dm_new) < 1e-12                                  # bisection against Newton
assert round(dm_bis * 1e6) == 13698 and abs(hand - dm_bis) < 3e-5    # the card's 1.3698%, and the hand road
assert 0.0 < z_s - dm_s < 1e-5 and abs(z_par - QM) > 1e-7            # close to DM, but not the same measure
assert abs(FACE + FACE * (QM - dm_bis) * annuity_dm - 99.0) < 1e-9   # flat curve: the bond formula
print("ALL CHECKS PASS")
