# Kolmogorov's zero-one law -- the check behind the card.  Standard library only.
# A fair die rolled forever.  No code reaches infinity, so the check takes two
# roads to finite-n numbers whose trend the proof then settles: exact arithmetic
# (fractions, and the exact law of the total by convolution), and a simulation of
# independent paths from a SplitMix64 generator written out here.
from fractions import Fraction as Fr
from math import sqrt

MASK = (1 << 64) - 1

class Gen:                                    # SplitMix64, seeded
    def __init__(self, seed):
        self.s = seed
    def next(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return z ^ (z >> 31)
    def below(self, k):                       # 0 .. k-1: the high word of next * k
        return (self.next() * k) >> 64

def fair(g):
    return g.below(6) + 1

def loaded(g):                                # a six with chance 0.5, faces 1 to 5 with 0.1 each
    r = g.below(10)
    return r + 1 if r < 5 else 6

def law_of_total(n_max, keep):                # exact law of the total, one roll at a time, in floats
    dist, out = [1.0], {}
    for n in range(1, n_max + 1):
        new = [0.0] * (len(dist) + 6)
        for t, p in enumerate(dist):
            for f in range(1, 7):
                new[t + f] += p / 6.0
        dist = new
        if n in keep:
            out[n] = sum(dist[:34 * n // 10 + 1])        # P(total <= 3.4n)
    return out

PATHS, N = 400, 10000
CHECK = [1, 2, 5, 10, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000]
g = Gen(20260929)
tot_at = {n: [] for n in (100, 400, 10000)}
lines, dips, far, no_six_10, no_six_100, first_six = [], [0, 0, 0], [0.0, 0.0], 0, 0, 0
for path in range(PATHS):
    s, last_six, line, dipped, worst = 0, 0, [], [False] * 3, [0.0, 0.0]
    for n in range(1, N + 1):
        x = fair(g)
        s += x
        if x == 6:
            last_six = n
            first_six += n == 1
        a = s / n
        if n in tot_at: tot_at[n].append(s)
        if n in CHECK: line.append(a)
        for i, n0 in enumerate((10, 100, 1000)):
            if n >= n0 and 10 * s <= 34 * n: dipped[i] = True
        for i, n0 in enumerate((100, 1000)):
            if n >= n0: worst[i] = max(worst[i], abs(a - 3.5))
    if path < 3: lines.append(line)
    dips = [d + b for d, b in zip(dips, dipped)]
    far = [max(f, w) for f, w in zip(far, worst)]
    no_six_10 += last_six <= N - 10
    no_six_100 += last_six <= N - 100

mean = sum(Fr(f, 6) for f in range(1, 7))
var = sum(Fr(f * f, 6) for f in range(1, 7)) - mean ** 2
assert mean == Fr(7, 2) and var == Fr(35, 12)
print(f"house example: mean {float(mean)}, variance {var} = {float(var):.6f}; "
      f"sd of the total after 100 rolls {sqrt(100 * var):.2f}")
for i, line in enumerate(lines):
    print(f"path {i + 1} running average at n = {CHECK}:")
    print("  " + ", ".join(f"{a:.2f}" for a in line))
print(f"largest distance of any of {PATHS} averages from 3.5, rolls 100 to {N}: {far[0]:.4f}; "
      f"rolls 1000 to {N}: {far[1]:.4f}")
for n in (100, 10000):
    avgs = [s / n for s in tot_at[n]]
    m = sum(avgs) / PATHS
    sd = sqrt(sum((a - m) ** 2 for a in avgs) / (PATHS - 1))
    print(f"spread of the {PATHS} averages at n = {n}: sd {sd:.6f}; sqrt(35/12/n) = {sqrt(35 / 12 / n):.6f}")
    assert abs(sd / sqrt(35 / 12 / n) - 1) < 0.15            # the limit is not random
exact = law_of_total(400, (25, 100, 400))
print(f"P(total <= 3.4n) at n = 25: exact {exact[25]:.6f}")
for n in (100, 400):
    sim = sum(10 * s <= 34 * n for s in tot_at[n]) / PATHS
    print(f"P(total <= 3.4n) at n = {n}: exact {exact[n]:.6f}; simulated {sim:.4f}")
    assert abs(sim - exact[n]) < 4 * sqrt(exact[n] * (1 - exact[n]) / PATHS)
print(f"share of paths whose total is at or below 3.4n somewhere in rolls 10, 100, 1000 to {N}: "
      + ", ".join(f"{d / PATHS:.4f}" for d in dips))
p10, p100 = Fr(5, 6) ** 10, Fr(5, 6) ** 100
print(f"P(no six in 10 given rolls) = (5/6)^10 = {p10.numerator}/{p10.denominator} = {float(p10):.6f}")
print(f"P(no six in 100 given rolls) = (5/6)^100 = {float(p100):.14f}")
print(f"simulated: no six in rolls {N - 9} to {N}: {no_six_10 / PATHS:.4f}; "
      f"no six in rolls {N - 99} to {N}: {no_six_100} of {PATHS} paths")
assert abs(no_six_10 / PATHS - float(p10)) < 4 * sqrt(float(p10) * (1 - float(p10)) / PATHS)
print(f"not a tail event, first roll a six: exact {float(Fr(1, 6)):.6f}; simulated {first_six / PATHS:.4f}")

g = Gen(7)                                    # the mystery die: which die is fixed once, then rolled forever
M, bins, above, hi = 2000, [0] * 14, 0, []
for path in range(PATHS):
    roll = loaded if g.next() >> 63 else fair
    s = sum(roll(g) for _ in range(M))
    a = s / M
    above += a > 4.0
    if a > 4.0: hi.append(a)
    b = int((a - 3.3) * 10) if a >= 3.3 else -1
    if 0 <= b < 14: bins[b] += 1
print(f"mystery die, loaded mean 0.1 x (1+2+3+4+5) + 0.5 x 6 = {Fr(1, 10) * 15 + Fr(1, 2) * 6}")
print(f"mystery die, {PATHS} paths of {M} rolls: share with average above 4.0 = {above / PATHS:.4f}; exact 0.5")
print(f"mystery die, mean of the averages above 4.0: {sum(hi) / len(hi):.4f}; loaded mean 4.5")
assert abs(sum(hi) / len(hi) - 4.5) < 0.015            # the upper cluster sits at the loaded mean
print("mystery die, averages in bins of 0.1 from 3.3 to 4.7: " + ", ".join(str(c) for c in bins))
assert abs(above / PATHS - 0.5) < 4 * sqrt(0.25 / PATHS)     # a tail event at 0.5
print(f"mystery die, runs ending with average from 3.7 to 4.3: {sum(bins[4:10])}")
assert sum(bins[4:10]) == 0                   # none in the middle: two clusters

def ten_s_minus_34n(first, reps):             # 10 x (total - 3.4n), in whole numbers, along a path
    path, out, s = [first] + [4, 3, 4, 3, 3] * reps, [], 0
    for n, x in enumerate(path, 1):
        s += x
        out.append(10 * s - 34 * n)
    return out
a, b = ten_s_minus_34n(6, 20), ten_s_minus_34n(1, 20)
print(f"path 6 then (4,3,4,3,3) repeated: total - 3.4n over 101 rolls runs from {min(a) / 10} to {max(a) / 10}")
print(f"same path, first roll 1:          total - 3.4n over 101 rolls runs from {min(b) / 10} to {max(b) / 10}")
assert a[-5:] == a[1:6] and b[-5:] == b[1:6]  # the pattern repeats, so the range holds for ever
assert min(a) > 0 > max(b)                    # one changed roll moves the path out of the event
print("ALL CHECKS PASS")
