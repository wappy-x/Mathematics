# Limits and continuity with distances -- the check behind the card.  Standard
# library only.  Two spreadsheet cells refer to each other: bonus B = (P - B - T)/10
# and tax T = (P - B)/4, with profit P = 43000 dollars.  Recalculating from blank
# cells gives readings x_n, kept as exact fractions.  Road one iterates; road two
# solves the two equations by Cramer's rule; road three is the proved bound
# 10000/4^n.  Floats appear only in the log10 chart points and the running total.
from fractions import Fraction as Fr
import math

P = Fr(43000)
def F(x): return ((P - x[0] - x[1]) / 10, (P - x[0]) / 4)   # one recalculation
def dinf(x, y): return max(abs(x[0] - y[0]), abs(x[1] - y[1]))  # largest change in any cell
def d1(x, y): return abs(x[0] - y[0]) + abs(x[1] - y[1])        # total change over the cells
def ddisc(x, y): return 0 if x == y else 1                       # the discrete metric
def dbonus(x, y): return abs(x[0] - y[0])                        # watches the bonus cell only
def g(x): return x / 2 if x > 0 else Fr(1)                       # IF(x > 0, x/2, 1)
def show(q, k=4):                       # exact fraction to k decimals, half away from zero
    s, m = 10 ** k, (abs(q.numerator) * 10 ** k * 2 + q.denominator) // (2 * q.denominator)
    return f"{'-' if q < 0 and m else ''}{m // s}.{m % s:0{k}d}"

det = 11 * 4 - 1 * 1                       # 11B + T = P and B + 4T = P
star = ((4 * P - P) / det, (11 * P - P) / det)
print(f"road two, Cramer's rule on 11B + T = P, B + 4T = P: B = {show(star[0])}, T = {show(star[1])}")
xs = [(Fr(0), Fr(0))]
for n in range(16):
    xs.append(F(xs[-1]))
err = [dinf(x, star) for x in xs]
bound = [Fr(10000, 4 ** n) for n in range(17)]
step = [None] + [dinf(xs[n], xs[n - 1]) for n in range(1, 17)]
print("n | bonus B | tax T | max change from limit | proved bound | step change")
for n in range(13):
    st = show(step[n]) if n else "-"
    print(f"{n} | {show(xs[n][0])} | {show(xs[n][1])} | {show(err[n])} | {show(bound[n])} | {st}")
eps = Fr(1, 1000)
def cutoffs(e):                            # first n with every later reading under e; first n with the bound under e
    return (next(n for n in range(17) if all(x < e for x in err[n:])), next(n for n in range(17) if bound[n] < e))
first_err, first_bound = cutoffs(eps)
m = next(n for n in range(1, 17) if step[n] < eps)
print(f"powers of 4 either side of 10^7: 4^11 = {4 ** 11}, 4^12 = {4 ** 12}")
print(f"tolerance {float(eps):g}: every reading within it from n = {first_err}; the bound promises n = {first_bound}")
print(f"try: tolerance 0.01: every reading within it from n = {cutoffs(Fr(1, 100))[0]}; "
      f"the bound promises n = {cutoffs(Fr(1, 100))[1]}")
print(f"step change first under {float(eps):g} at n = {m}: step {show(step[m], 6)}, true miss {show(err[m], 6)}, "
      f"at most step/3 = {show(step[m] / 3, 6)}")
r = [d1(x, star) / dinf(x, star) for x in xs[:13]]
print(f"total change / max change, n = 0 to 12: lowest {show(min(r))}, highest {show(max(r))}")
print(f"discrete metric, distance to the limit for n = 0 to 12: {[ddisc(x, star) for x in xs[:13]]}")
fake = (Fr(3000), Fr(0))
print(f"bonus-only distance at n = 12: to (3000, 10000) {show(dbonus(xs[12], star), 6)}, to (3000, 0) "
      f"{show(dbonus(xs[12], fake), 6)}; the two points are {dbonus(star, fake)} apart")
print(f"F(limit) = ({show(F(star)[0])}, {show(F(star)[1])}); sequence test: d(F(x_5), F(limit)) = "
      f"d(x_6, limit) = {show(dinf(F(xs[5]), F(star)))}")
best, cases = (Fr(0), None), 0             # exhaustive: every whole-dollar offset up to 200
for e1 in range(-200, 201):
    for e2 in range(-200, 201):
        if e1 or e2:
            cases += 1
            p = (star[0] + e1, star[1] + e2)       # run F itself on the offset point
            q = dinf(F(p), F(star)) / dinf(p, star)
            if q > best[0]:
                best = (q, (e1, e2))
print(f"largest output change / input change over {cases} offsets: {best[0]} at offset {best[1]}")
a_off = (star[0] + 4, star[1])
print(f"epsilon 1 dollar, delta 4 dollars: offset (4, 0) moves the output {show(dinf(F(a_off), star))}")
ys = [Fr(8)]
for n in range(14):
    ys.append(g(ys[-1]))
print(f"IF cell from 8: x_14 = {show(ys[14], 6)}, g(x_14) = {show(g(ys[14]), 6)}, g(0) = {g(Fr(0))}")
for dl in (Fr(1), Fr(1, 10), Fr(1, 1000)):
    print(f"epsilon 1/2, delta {show(dl, 3)}: input {show(dl / 2, 4)} lands {show(1 - g(dl / 2), 5)} from g(0)")
two = [tuple(c - t for c, t in zip(F(F((star[0] + u, star[1] + v))), star)) for u, v in ((1, 0), (0, 1))]
even = all(x[1] < star[1] for x in xs[::2])                # Step 6: the even readings, n = 0, 2, ..., 16
print(f"two recalculations send miss (1, 0) to ({two[0][0]}, {two[0][1]}) and (0, 1) to ({two[1][0]}, "
      f"{two[1][1]}); tax under 10000 at every even n to 16: {'yes' if even else 'no'}")
s, n = 0.0, 0
while True:
    n += 1
    s += 1 / n
    if 1 / n < 0.001:
        break
s_at, nstop = s, n
while n < 1000000:
    n += 1
    s += 1 / n
    if n == 500000:
        s_half = s
print(f"running total of 1/n: step first under 0.001 at n = {nstop}, total {s_at:.4f}; at n = {n}, {s:.4f}; "
      f"minus the total at n = 500000, {s - s_half:.4f}")
print("chart, log10 of max change from limit:", ", ".join(f"{math.log10(e):.2f}" for e in err[:13]))
print("chart, log10 of proved bound:", ", ".join(f"{math.log10(b):.2f}" for b in bound[:13]))
assert star == F(star) and star == (Fr(3000), Fr(10000))           # road two is road one's resting point
assert all(err[n] <= bound[n] for n in range(17)) and err[16] > 0     # road three bounds road one, never exact
assert first_err <= first_bound == 12 and err[m] <= step[m] / 3       # proved cutoffs hold
assert best[0] == Fr(1, 4) and all(1 <= q <= 2 for q in r)            # Lipschitz 1/4; d1, dinf equivalent
assert g(ys[14]) < Fr(1, 1000) and g(Fr(0)) == 1                      # the IF cell fails the sequence test
assert dbonus(xs[12], fake) < Fr(1, 10000) and dinf(xs[12], fake) > 9999  # bonus-only: near a far point too
assert s > 14 and s - s_half > 0.5                                    # steps shrink, totals stay apart
assert even and min(two[0] + two[1]) > 0                              # Step 6: two passes mix misses positively
print("ALL CHECKS PASS")
