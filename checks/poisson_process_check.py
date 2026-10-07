# Poisson process -- the check behind the card.  Standard library only; nothing
# imported holds the answer.  Calls reach a switchboard at 4 an hour.  The process
# is built from independent exponential gaps, and the count in the next quarter
# hour is reached four ways: the Poisson formula; a first-step recursion on the
# first gap, integrated on a grid; time cut into slots of length h, the error
# printed as h shrinks; and a seeded simulation (SplitMix64, seed 20260929).
from math import exp, log, sqrt

LAM, WIN, DAY = 4.0, 0.25, 2.0          # calls per hour; window and plotted span, hours
SEED, RUNS, KMAX = 20260929, 200_000, 5
M64 = (1 << 64) - 1
state = SEED

def uniform():                          # SplitMix64, turned into a number in (0, 1]
    global state
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return (((z ^ (z >> 31)) >> 11) + 1) / 2.0**53

def gap():                              # exponential gap, rate LAM, by inverse transform
    return -log(uniform()) / LAM

def fact(k):
    f = 1
    for i in range(2, k + 1):
        f *= i
    return f

def pois(k, m):                         # Road 1: the Poisson formula
    return exp(-m) * m**k / fact(k)

def by_first_gap(t, kmax, n=1000):      # Road 2: p_k(t) = int_0^t LAM e^(-LAM u) p_(k-1)(t-u) du
    h = t / n
    f = [LAM * exp(-LAM * i * h) for i in range(n + 1)]
    q = [exp(-LAM * i * h) for i in range(n + 1)]     # p_0: the first gap outlasts the time
    out = [q[n]]
    for k in range(1, kmax + 1):
        r = [0.0]
        for i in range(1, n + 1):                     # trapezoid rule over the first gap u
            s = 0.5 * (f[0] * q[i] + f[i] * q[0])
            for j in range(1, i):
                s += f[j] * q[i - j]
            r.append(s * h)
        q = r
        out.append(q[n])
    return out

def by_slots(t, h, k):                  # Road 3: slots of length h, one call each with chance LAM h
    m, p, c = round(t / h), LAM * h, 1
    for i in range(k):
        c = c * (m - i) // (i + 1)
    return c * p**k * (1 - p)**(m - k)

def two_windows(draw):                  # Road 4: counts in the first and second quarter hour
    t, c1, c2 = draw(), 0, 0
    while t <= WIN:
        c1, t = c1 + 1, t + draw()
    w = t - WIN                                       # wait from quarter past to the next call
    while t <= 2 * WIN:
        c2, t = c2 + 1, t + draw()
    return c1, c2, w

def simulate(draw):
    hist, both, s1, s2, s11, s22, s12, s3, s4, sw, sww = [0] * (KMAX + 2), 0, 0, 0, 0, 0, 0, 0, 0, 0.0, 0.0
    for _ in range(RUNS):
        c1, c2, w = two_windows(draw)
        hist[min(c1, KMAX + 1)] += 1
        both += c1 == 1 and c2 == 2
        s1, s2, s11, s22, s12 = s1 + c1, s2 + c2, s11 + c1 * c1, s22 + c2 * c2, s12 + c1 * c2
        s3, s4 = s3 + c1 * c1 * c1, s4 + c1 * c1 * c1 * c1
        sw, sww = sw + w, sww + w * w
    m1, m2 = s1 / RUNS, s2 / RUNS
    v1, v2, cv = s11 / RUNS - m1 * m1, s22 / RUNS - m2 * m2, s12 / RUNS - m1 * m2
    mw, m4 = sw / RUNS, s4 / RUNS - 4 * m1 * s3 / RUNS + 6 * m1 * m1 * s11 / RUNS - 3 * m1 * m1 * m1 * m1
    return (hist, both / RUNS, m1, v1, cv / sqrt(v1 * v2), (v1 + cv) / sqrt(v1 * (v1 + v2 + 2 * cv)),
            mw, sqrt((sww / RUNS - mw * mw) / RUNS), sqrt(v1 / RUNS), sqrt((m4 - v1 * v1) / RUNS))

def se(f):
    return sqrt(f * (1 - f) / RUNS)

path, t = [], gap()                     # one sample path over two hours, for the picture
while t <= DAY:
    path.append(t)
    t += gap()
grid = [3 * i for i in range(41)]                     # minutes
steps = [sum(1 for a in path if 60 * a <= g) for g in grid]

exact = [pois(k, LAM * WIN) for k in range(KMAX + 1)]
rec = by_first_gap(WIN, KMAX)
hist, both, m1, v1, r12, r1t, mw, sew, sem, sev = simulate(gap)
uhist, _, _, _, ur12, _, umw, usew, _, _ = simulate(lambda: 2 * uniform() / LAM)   # the mistake: same mean
pu = max(0.0, 1 - LAM * WIN / 2)                      # its exact chance of an empty first window
freq, ufreq = [c / RUNS for c in hist], [c / RUNS for c in uhist]
rse = 1 / sqrt(RUNS)                                  # standard error of a correlation near 0

print(f"rate {LAM:.0f} calls an hour; window {WIN} hour; mean count LAM t = {LAM * WIN:.4f}")
print("calls in the quarter hour: formula, first-gap recursion, simulated +- se")
for k in range(KMAX + 1):
    print(f"  {k}: {exact[k]:.6f}  {rec[k]:.6f}  {freq[k]:.4f} +- {se(freq[k]):.4f}")
print(f"P(4 or more): formula {1 - sum(exact[:4]):.4f}; simulated {sum(freq[4:]):.4f} +- {se(sum(freq[4:])):.4f}")
print(f"mean and variance of the count, simulated: {m1:.4f} +- {sem:.4f}, {v1:.4f} +- {sev:.4f}")
errs = []
for name, h in (("1 minute", 1 / 60), ("10 seconds", 1 / 360), ("1 second", 1 / 3600)):
    errs.append(max(abs(by_slots(WIN, h, k) - exact[k]) for k in range(KMAX + 1)))
    print(f"slots of {name}: P(0) = {by_slots(WIN, h, 0):.6f}, largest error {errs[-1]:.6f}")
print(f"wait from quarter past to the next call: {60 * mw:.2f} +- {60 * sew:.2f} minutes (mean gap 15)")
print(f"P(1 call, then 2 calls): formula {exact[1] * exact[2]:.4f}; simulated {both:.4f} +- {se(both):.4f}")
print(f"corr(first quarter, second quarter): {r12:.4f} +- {rse:.4f}; formula 0")
print(f"corr(N(0.25), N(0.5)): {r1t:.4f} +- {(1 - r1t * r1t) * rse:.4f}; formula sqrt(1/2) = {sqrt(0.5):.4f}")
print(f"P(N(0.5) = 3) = {pois(3, 2 * LAM * WIN):.4f}; Cov(N(0.25), N(0.5)) = LAM x 0.25 = {LAM * WIN:.4f}")
print(f"mistake, totals as independent: P(N(0.25) = 1 and N(0.5) = 2) = {exact[1] ** 2:.4f}, "
      f"product of the two laws {exact[1] * pois(2, 2 * LAM * WIN):.4f}")
print(f"mistake, 1 - LAM t for no call: quarter hour {1 - LAM * WIN:.4f} vs {exact[0]:.4f}; "
      f"one hour {1 - LAM:.4f} vs {exp(-LAM):.4f}")
print(f"mistake, gaps uniform on 0 to {120 / LAM:.0f} minutes: P(no call in first quarter) exact {pu:.4f}, "
      f"simulated {ufreq[0]:.4f} +- {se(ufreq[0]):.4f}")
print(f"  its corr(first quarter, second quarter): {ur12:.4f} +- {rse:.4f}; "
      f"wait from quarter past: {60 * umw:.2f} +- {60 * usew:.2f} minutes")
print("sample path, arrival minutes: " + ", ".join(f"{60 * a:.1f}" for a in path))
print("chart, minutes: " + ", ".join(str(g) for g in grid))
print("chart, calls so far: " + ", ".join(str(c) for c in steps))
print("chart, mean 4t: " + ", ".join(f"{g / 15:.2f}" for g in grid))
print("chart, formula: " + ", ".join(f"{p:.2f}" for p in exact))
print("chart, simulated exponential gaps: " + ", ".join(f"{p:.2f}" for p in freq[:KMAX + 1]))
print(f"chart, simulated uniform gaps (se at most {max(se(p) for p in ufreq):.4f}): "
      + ", ".join(f"{p:.2f}" for p in ufreq[:KMAX + 1]))

assert max(abs(rec[k] - exact[k]) for k in range(KMAX + 1)) < 1e-6   # recursion against formula
assert errs[0] > errs[1] > errs[2] and errs[2] < 5e-4                # slots close in on the formula
assert all(abs(freq[k] - exact[k]) < 4 * se(exact[k]) for k in range(KMAX + 1)) and abs(m1 - v1) < 4 * sev
assert abs(both - exact[1] * exact[2]) < 4 * se(both)               # increments multiply
assert abs(r12) < 4 * rse and abs(r1t - sqrt(0.5)) < 4 * (1 - r1t * r1t) * rse   # increments vs totals
assert abs(mw - 1 / LAM) < 4 * sew                                     # the restart at a fixed time
assert abs(ufreq[0] - pu) <= 4 * se(pu) and abs(ur12) > 4 * rse      # uniform gaps break it
print("ALL CHECKS PASS")
