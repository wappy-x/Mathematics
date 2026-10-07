# Arrival times given the count -- the check behind the card.  Standard library only.
# Calls reach a switchboard at 4 an hour.  Exactly 4 calls came in one hour: when did they come?
# Road 1: the formula, 4 uniform draws sorted.  Road 2: Poisson counts with independent increments,
# integrated by Simpson's rule written out.  Road 3: the hour cut into m slots, counted exactly.
# Road 4: two seeded simulations (SplitMix64, written out): exponential gaps, and a count scattered.
from math import comb, exp, factorial, log, sqrt

LAM, T, N, H = 4.0, 1.0, 4, 200000       # calls per hour, one hour, calls seen, simulated hours
def pois(mu, j): return exp(-mu) * mu ** j / factorial(j)
def simpson(f, a, b, m=600):
    h = (b - a) / m
    return h / 3 * sum((1 if i in (0, m) else 4 if i % 2 else 2) * f(a + i * h) for i in range(m + 1))
def surv_inc(k, s):                      # road 2: P(T_k > s | N(1) = 4) = P(fewer than k calls by s | 4 in all)
    return sum(pois(LAM * s, j) * pois(LAM * (T - s), N - j) for j in range(k)) / pois(LAM * T, N)
def window_inc(j, a, lam):               # road 2: P(j of the 4 calls come before time a | N(1) = 4), rate lam
    return pois(lam * a, j) * pois(lam * (T - a), N - j) / pois(lam * T, N)
def dens(k, s, n=N):                     # road 1: density of T_k given n calls, per hour
    return factorial(n) / (factorial(k - 1) * factorial(n - k)) * (s / T) ** (k - 1) * (1 - s / T) ** (n - k) / T

MASK, state = (1 << 64) - 1, 20260929
def unif():                              # SplitMix64, top 53 bits, never exactly 0 or 1
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return (((z ^ (z >> 31)) >> 11) + 0.5) / 2 ** 53
def hour_by_gaps():                      # recipe A: add exponential gaps until the hour is over
    ts, s = [], -log(unif()) / LAM
    while s <= T: ts.append(s); s -= log(unif()) / LAM
    return ts, False
def hour_by_scatter():                   # recipe B: draw the count, then scatter that many uniform times
    u, n, p = unif(), 0, exp(-LAM * T); c = p
    while u > c: n += 1; p *= LAM * T / n; c += p
    raw = [T * unif() for _ in range(n)]
    return sorted(raw), raw == sorted(raw)

print(f"{'density of (T_1..T_4) given 4 calls, 4!/1^4, per hour^4':<58}{factorial(N) / T ** N:>10.6f}")
print(f"{'chance of exactly 4 calls in the hour, e^-4 4^4 / 4!':<58}{pois(LAM * T, N):>10.6f}")
print("mean time of call k given 4 calls, minutes   k   k 60/5     from counts")
mean_inc = [60 * simpson(lambda s: surv_inc(k, s), 0, T) for k in range(1, N + 1)]
for k in range(1, N + 1): print(f"{'':<45}{k}{60 * k / (N + 1):>11.6f}{mean_inc[k - 1]:>14.6f}")
print("calls in the first half-hour, given 4       j   C(4,j)/16  counts, rate 4  counts, rate 10")
for j in range(N + 1):
    print(f"{'':<45}{j}{comb(N, j) / 2 ** N:>11.6f}{window_inc(j, 0.5, 4.0):>14.6f}{window_inc(j, 0.5, 10.0):>15.6f}")
quarters = pois(LAM / 4, 1) ** 4 / pois(LAM, N)
print(f"one call in each quarter-hour: 4! (1/4)^4 = {factorial(N) / 4 ** N:.6f}; from counts {quarters:.6f}")
print(f"first quarter-hour empty, given 4: (3/4)^4 = {0.75 ** N:.6f}; read as one uniform draw {0.75:.6f}")
print("slots m   mean first call, min   error      P(2 of 4 in first half)   error")
slots = []
for m in (60, 600, 6000):
    e1 = 60 * sum(j * comb(m - j, N - 1) for j in range(1, m + 1)) / comb(m, N) / m
    h2 = comb(m // 2, 2) ** 2 / comb(m, N)
    slots.append(e1 - 12); print(f"{m:>7}{e1:>18.6f}{e1 - 12:>13.6f}{h2:>20.6f}{h2 - 0.375:>16.6f}")

stats = {}
for name, recipe in (("gaps", hour_by_gaps), ("scatter", hour_by_scatter)):
    four = empty15 = half2 = inorder = two_first = gap20 = 0; s1 = [0.0] * N; s2 = [0.0] * N; fig = []
    for _ in range(H):
        ts, ordered = recipe()
        four += len(ts) == N; empty15 += not ts or ts[0] > 0.25; half2 += sum(t <= 0.5 for t in ts) == 2
        if len(ts) == N:
            inorder += ordered; two_first += sum(t <= 0.5 for t in ts) == 2; gap20 += ts[2] - ts[1] > 1 / 3
            for k in range(N): s1[k] += 60 * ts[k]; s2[k] += (60 * ts[k]) ** 2
            if len(fig) < 5: fig.append(ts)
    stats[name] = (four, empty15, half2, inorder, two_first, gap20, s1, s2, fig)
se = lambda p, n: sqrt(p * (1 - p) / n)
print(f"simulation, {H} hours each   P(N(1) = 4)    se        P(none by 15 min)  se        P(N(1/2) = 2)  se")
for name in ("gaps", "scatter"):
    f, e, h = (x / H for x in stats[name][:3])
    print(f"  {name:<27}{f:>9.6f}{se(f, H):>10.6f}{e:>15.6f}{se(e, H):>10.6f}{h:>15.6f}{se(h, H):>10.6f}")
print(f"  {'formula':<27}{pois(LAM, N):>9.6f}{'':>10}{exp(-LAM / 4):>15.6f}{'':>10}{pois(LAM / 2, 2):>15.6f}")
four, _, _, _, two_first, gap20, s1, s2, fig = stats["gaps"]
means = [s / four for s in s1]; ses = [sqrt((q / four - mu ** 2) / four) for q, mu in zip(s2, means)]
print(f"gaps, hours with 4 calls: {four}; mean T_1..T_4, minutes " + " ".join(f"{mu:.3f}" for mu in means))
print("  standard errors                                  " + " ".join(f"{x:.3f}" for x in ses))
p2 = two_first / four; pg = gap20 / four
print(f"gaps, given 4: P(2 in first half) {p2:.6f} se {se(p2, four):.6f}; P(gap 2 to 3 > 20 min) {pg:.6f} se {se(pg, four):.6f}")
four_b, inorder = stats["scatter"][0], stats["scatter"][3]
po = inorder / four_b
print(f"scatter, given 4: draws already in time order {po:.6f} se {se(po, four_b):.6f}; 1/4! = {1 / 24:.6f}")
big_l = lambda s: 2 * s if s <= 0.5 else 1 + 6 * (s - 0.5)      # rising rate: 2 an hour, then 6 an hour
rise_counts = pois(1.0, 2) * pois(3.0, 2) / pois(4.0, 4)
rise_e1 = 60 * simpson(lambda s: pois(big_l(s), 0) * pois(4 - big_l(s), 4) / pois(4.0, 4), 0, T)
rise_closed = 60 * (0.4 * (1 - 0.75 ** 5) + 0.75 ** 5 / 7.5)
print(f"rising rate, given 4: P(2 in first half) from counts {rise_counts:.6f}; binomial, p = 1/4 {comb(4, 2) / 16 * 9 / 16:.6f}")
print(f"rising rate, given 4: mean first call, minutes: Simpson {rise_e1:.6f}; closed form {rise_closed:.6f}")
grid = [5 * i for i in range(13)]
print("chart, minute          " + " ".join(f"{g:>5d}" for g in grid))
for k in (1, 4):
    print(f"chart, T_{k} %/min       " + " ".join(f"{100 * dens(k, g / 60) / 60:5.2f}" for g in grid))
print("chart, one call %/min   " + " ".join(f"{100 * dens(1, g / 60, 1) / 60:5.2f}" for g in grid))
print("chart, first half j %   " + " ".join(f"{100 * comb(N, j) / 16:5.2f}" for j in range(N + 1)))
for i, ts in enumerate(fig):             # the first five simulated hours with exactly 4 calls; svg x = 60 + 4.5 m
    print(f"figure, hour {i + 1}, minutes " + " ".join(f"{60 * t:5.2f}" for t in ts) + ";  x " + " ".join(f"{60 + 270 * t:5.1f}" for t in ts))
print(f"try: 8 calls, mean first call {60 / 9:.6f} min; first quarter empty {0.75 ** 8:.6f}; gap 2 to 3 > 20 min, 4 calls {(2 / 3) ** 4:.6f}")

assert all(abs(mean_inc[k - 1] - 60 * k / (N + 1)) < 1e-6 for k in range(1, N + 1)), "means: counts vs sorted uniforms"
assert all(abs(window_inc(j, 0.5, lam) - comb(N, j) / 16) < 1e-12 for j in range(N + 1) for lam in (4.0, 10.0)), "binomial"
assert abs(quarters - factorial(N) / 4 ** N) < 1e-12, "one call per quarter: counts vs n! times the volume"
assert slots[0] > slots[1] > slots[2] > 0 and abs(slots[2]) < 0.003, "slot error shrinks as the slots shrink"
assert abs(means[0] - 12) < 4 * ses[0] and abs(means[3] - 48) < 4 * ses[3], "gap recipe: mean first and last call"
assert abs(p2 - 0.375) < 4 * se(0.375, four) and abs(pg - (2 / 3) ** 4) < 4 * se(pg, four), "gap recipe, given 4"
for name in ("gaps", "scatter"):
    assert abs(stats[name][0] / H - pois(LAM, N)) < 4 * se(pois(LAM, N), H), "P(N = 4), simulated vs formula"
    assert abs(stats[name][1] / H - exp(-LAM / 4)) < 4 * se(exp(-LAM / 4), H), "no call in 15 minutes, simulated vs e^-1"
    assert abs(stats[name][2] / H - pois(LAM / 2, 2)) < 4 * se(pois(LAM / 2, 2), H), "2 calls in the first half-hour"
assert abs(po - 1 / 24) < 4 * se(1 / 24, four_b), "unsorted draws already in order 1 time in 4!"
assert abs(rise_counts - 54 / 256) < 1e-12 and abs(rise_e1 - rise_closed) < 1e-6, "rising rate, two roads"
print("ALL CHECKS PASS")
