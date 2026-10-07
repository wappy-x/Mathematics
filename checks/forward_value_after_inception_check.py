# An old forward -- the check behind the card.  Standard library only, and
# nothing is imported that already holds the answer: the root finder is a
# bisection written out below, the pretend world's average is Simpson's rule
# written out below, and the copy is stepped hour by hour on a bank account
# paying simple interest.  Acme: spot 100.00 the morning the contract was
# signed, bank rate 5 percent, dividend yield 2 percent, one year to delivery.
# A month later the forward price for that same delivery day is 106.00.
from math import exp, sqrt, pi

S0, R, Q, T = 100.0, 0.05, 0.02, 1.0
FT, TAU = 106.0, 11.0 / 12.0
HOURS, YEAR = 8030, 8760                 # hours in eleven months, hours in a year
SCEN = (80.0, 95.0, 110.0, 130.0)        # four ways Acme could land on delivery day
PATH = [100.00, 0.00, 104.00, 101.50, 98.00, 97.00, 99.50,
        102.00, 105.00, 106.50, 104.00, 102.50, 101.00]   # month by month; month 1 filled in below
GRID = (96.0, 98.0, 100.0, 102.0, 104.0, 106.0, 108.0, 110.0)
LEFT = (11, 9, 6, 3, 0)                  # months still to run, for the clock bars


def mark(spot, strike, r, q, tau):       # the copy's cost: the shares, less the loan
    return spot * exp(-q * tau) - strike * exp(-r * tau)


def clean(v):                            # a residue under a millionth of a cent is zero
    return v if abs(v) > 1e-8 else 0.0


def bisect(f, lo, hi):                   # a root finder, written out here
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        if f(lo) * f(mid) <= 0.0:
            hi = mid
        else:
            lo = mid
    return 0.5 * (lo + hi)


def simpson(f, a, b, n):                 # thin slices under a curve
    h, s = (b - a) / n, f(a) + f(b)
    for i in range(1, n):
        s += (4.0 if i % 2 else 2.0) * f(a + i * h)
    return s * h / 3.0


def average_delivery(spot, sigma, tau):  # the pretend world's average price on delivery day
    def slice_at(z):
        bell = exp(-0.5 * z * z) / sqrt(2.0 * pi)
        return spot * exp((R - Q - 0.5 * sigma * sigma) * tau + sigma * sqrt(tau) * z) * bell
    return simpson(slice_at, -10.0, 10.0, 40000)


def hourly(rate):                        # one dollar, interest added hour by hour for eleven months
    grown = 1.0
    for _ in range(HOURS):
        grown *= 1.0 + rate / YEAR
    return grown


def row(name, text):
    print(f"{name:<50}{text:>24}")


K = S0 * exp((R - Q) * T)                # cash and carry, the morning it was signed
St = FT * exp(-(R - Q) * TAU)            # today's spot, read back from today's forward price
D, drag = exp(-R * TAU), exp(-Q * TAU)
gap_form, spot_form = (FT - K) * D, mark(St, K, R, Q, TAU)
grow_q, grow_r = hourly(Q), hourly(R)
shares_end, debt_end = drag * grow_q, K * D * grow_r
worst = max(abs((shares_end * x - debt_end) - (x - K)) for x in SCEN)
cost_hourly = St / grow_q - K / grow_r
avg20, avg60 = average_delivery(St, 0.20, TAU), average_delivery(St, 0.60, TAU)
v20, v60 = (avg20 - K) * D, (avg60 - K) * D
s_zero = bisect(lambda s: mark(s, K, R, Q, TAU), 50.0, 200.0)
h, hr = 0.01, 0.0001
delta = (mark(St + h, K, R, Q, TAU) - mark(St - h, K, R, Q, TAU)) / (2.0 * h)
gamma = (mark(St + h, K, R, Q, TAU) - 2.0 * spot_form + mark(St - h, K, R, Q, TAU)) / (h * h)
theta = (mark(St, K, R, Q, TAU - h) - mark(St, K, R, Q, TAU + h)) / (2.0 * h)
rho = (mark(St, K, R + hr, Q, TAU) - mark(St, K, R - hr, Q, TAU)) / (2.0 * hr) / 100.0
qsens = (mark(St, K, R, Q + hr, TAU) - mark(St, K, R, Q - hr, TAU)) / (2.0 * hr) / 100.0
PATH[1] = St
marks = [mark(PATH[m], K, R, Q, (12 - m) / 12.0) for m in range(13)]

print("Acme the morning it was signed: spot 100.00, rate 5 percent, yield 2 percent, one year out")
row("K, the delivery price locked that morning", f"{K:.6f}")
row("the mark that morning, distance from zero", f"{clean(marks[0]):.6f}")
print("one month on, eleven months still to run")
row("F, today's forward price for that same day", f"{FT:.6f}")
row("S, Acme's spot price today", f"{St:.6f}")
row("tau, the years still to run", f"{TAU:.6f}")
row("D = e^-r tau, a dollar due on delivery, priced today", f"{D:.6f}")
row("e^-q tau, the share fraction that grows into one", f"{drag:.6f}")
row("1 the gap form, (F - K) x D", f"{gap_form:.6f}")
row("2 the spot form, S e^-q tau - K D", f"{St * drag:.6f} - {K * D:.6f} = {spot_form:.6f}")
print("close-out ledger: the old long at K, plus a new short signed at 106.00")
print(f"{'Acme on delivery day':>22}{'old long':>14}{'new short':>14}{'the pair':>14}")
for x in SCEN:
    print(f"{x:>22.2f}{x - K:>14.2f}{FT - x:>14.2f}{(x - K) + (FT - x):>14.2f}")
print("3 the copy, stepped hour by hour from today to delivery")
row("  shares held on delivery day", f"{shares_end:.6f}")
row("  the loan owed on delivery day", f"{debt_end:.6f}")
row("  worst gap, the copy's cash against S_T - K", f"{worst:.6f}")
row("  what that copy costs today", f"{cost_hourly:.6f}")
print("4 the pretend world's average delivery price, by thin slices")
row("  volatility 20 percent: average, then the mark", f"{avg20:.6f} {v20:.6f}")
row("  volatility 60 percent: average, then the mark", f"{avg60:.6f} {v60:.6f}")
row("5 the spot that puts the mark back at zero, hunted", f"{s_zero:.6f}")
row("  the same spot, K e^-(r-q)tau", f"{K * exp(-(R - Q) * TAU):.6f}")
row("the mark on delivery day, Acme at 101.00", f"{marks[12]:.6f}")
print("how the mark answers a nudge, with everything else held still")
row("  delta: bumped, then e^-q tau", f"{delta:.6f} {drag:.6f}")
row("  gamma and vega, distance from zero", f"{abs(gamma):.6f} {abs((v60 - v20) / 0.40):.6f}")
row("  theta a year, then a day", f"{theta:.6f} {theta / 365.0:.6f}")
row("  rho per 1 percent on r, then on q", f"{rho:.6f} {qsens:.6f}")
print("what breaks")
row("  spot minus strike", f"{St - K:.6f}")
row("  the gap left undiscounted", f"{FT - K:.6f}")
row("  the original year discounted, not the months left", f"{mark(St, K, R, Q, T):.6f}")
row("  the dividend yield forgotten", f"{St - K * D:.6f}")
row("  the long mark booked on a short, and the truth", f"{gap_form:.6f} {-gap_form:.6f}")
print(f"{'chart, months gone':<34}" + "".join(f"{m:>8d}" for m in range(13)))
print(f"{'chart, Acme spot that month':<34}" + "".join(f"{p:>8.2f}" for p in PATH))
print(f"{'chart, the mark that month':<34}" + "".join(f"{clean(v):>8.2f}" for v in marks))
print(f"{'chart, Acme spot today':<34}" + "".join(f"{s:>8.2f}" for s in GRID))
print(f"{'chart, the mark today':<34}" + "".join(f"{mark(s, K, R, Q, TAU):>8.2f}" for s in GRID))
print(f"{'clock, months still to run':<34}" + "".join(f"{m:>8d}" for m in LEFT))
print(f"{'clock, forward price for that day':<34}" + "".join(f"{St * exp((R - Q) * m / 12.0):>8.2f}" for m in LEFT))
print(f"{'clock, the mark, Acme frozen':<34}" + "".join(f"{mark(St, K, R, Q, m / 12.0):>8.2f}" for m in LEFT))
assert abs(gap_form - spot_form) < 1e-12               # the two forms of the formula agree
assert abs(shares_end - 1.0) < 1e-6                    # hour by hour, the shares grow into one
assert abs(debt_end - K) < 1e-3                        # and the loan grows into K
assert worst < 1e-3                                    # so the copy pays S_T - K on delivery day
assert abs(cost_hourly - gap_form) < 1e-4              # and it costs what the formula says
assert abs(v20 - gap_form) < 1e-6                      # the pretend-world average, at 20 percent
assert abs(v60 - gap_form) < 1e-6                      # and at 60: volatility never enters
assert abs(s_zero - K * exp(-(R - Q) * TAU)) < 1e-9    # break-even spot, hunted then derived
assert abs(delta - drag) < 1e-9                        # delta by bumping the spot
assert abs(theta - (Q * St * drag - R * K * D)) < 1e-6  # theta by bumping the clock
assert abs(marks[0]) < 1e-9                            # nothing changed hands at signing
print("ALL CHECKS PASS")
