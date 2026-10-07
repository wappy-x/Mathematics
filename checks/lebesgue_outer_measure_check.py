# Outer measure -- the check behind the card.  Standard library only: exact
# fractions for the rationals, whole micrometres (um) on the fence, and random
# covers from SplitMix64 written out here.  The fence is [0, 3000000] um.
from fractions import Fraction as Fr

M, MASK = 10**6, (1 << 64) - 1
SPOTS = [30000 * k for k in range(1, 101)]              # a rust spot every 3 cm

def metres(um):                                          # whole um as metres, zeros trimmed
    s = f"{abs(um) // M}.{abs(um) % M:06d}".rstrip("0").rstrip(".")
    return "-" + s if um < 0 else s

def dec(num, den, digits):                               # long division, no float; cuts off, never rounds
    out = f"{num // den}."
    for _ in range(digits):
        num = num % den * 10
        out += str(num // den)
    return out

def merge(ivs):                        # road one: the union as disjoint open pieces
    out = []
    for c, d in sorted(ivs):
        if out and c < out[-1][1]:     # open ends that only touch leave that point out
            out[-1][1] = max(out[-1][1], d)
        else:
            out.append([c, d])
    return out

def covers(ivs, a, b):
    return any(c < a and d > b for c, d in merge(ivs))

def chain(ivs, a, b):                  # road two: the proof's walk, furthest reach each time
    x, used = a, []
    while True:
        here = [iv for iv in ivs if iv[0] < x < iv[1]]
        if not here:
            return None
        best = max(here, key=lambda iv: (iv[1], iv[0]))
        used.append(best)
        if best[1] > b:
            return used
        x = best[1]

def rationals(count):                  # 0, 1, 1/2, 1/3, 2/3, 1/4, ... each once
    out, q = [], 1
    while len(out) < count:
        out += [Fr(p, q) for p in range(q + 1) if Fr(p, q).denominator == q]
        q += 1
    return out[:count]

def splitmix(state):
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return state, z ^ (z >> 31)

fence = [(-1000, 3001000)]
spot_cover = [(s - 50, s + 50) for s in SPOTS]
gap_cover = [(-1000, 30000)] + [(s - 30000, s) for s in SPOTS[1:]]
size = lambda ivs: sum(d - c for c, d in ivs)
pieces = merge(gap_cover)
holes = [(0, pieces[0][0])] * (pieces[0][0] >= 0) + [(pieces[-1][1], 3 * M)]
holes[-1:-1] = [(d, c2) for (c, d), (c2, d2) in zip(pieces, pieces[1:])]
missed = [d for d, c2 in holes if d == c2]                   # holes of one point each
print(f"fence [0, 3] m; {len(SPOTS)} rust spots at 0.03, 0.06, ..., {metres(SPOTS[-1])} m")
print(f"cover of the fence: (-0.001, 3.001), total {metres(size(fence))} m")
print(f"cover of the spots: 100 intervals of {metres(100)} m, total {metres(size(spot_cover))} m")
print(f"cover of the fence minus the spots: {len(gap_cover)} gaps, total {metres(size(gap_cover))} m")
print(f"points of the fence the gap cover misses: {len(missed)}, exactly the spots: "
      f"{'yes' if missed == SPOTS else 'no'}")
print(f"fence minus spots, lower bound by subadditivity: 3 - 0.01 = {metres(3 * M - size(spot_cover))} m")
tiny_gaps = [(-1, 30000)] + gap_cover[1:]
tiny_spots = [(s - 1, s + 1) for s in SPOTS]
print(f"shrunk: gap cover {metres(size(tiny_gaps))} m above, 3 - {metres(size(tiny_spots))} = "
      f"{metres(3 * M - size(tiny_spots))} m below")

qs = rationals(40)
print("rationals in [0, 1], first ten: " + ", ".join(str(q) for q in qs[:10]))
print("rational number k gets an interval of length 0.01 / 2^k around it")
for n in (10, 20, 40):
    by_terms = sum(Fr(1, 100 * 2**k) for k in range(1, n + 1))
    closed = Fr(2**n - 1, 100 * 2**n)
    assert by_terms == closed                                  # geometric series, two roads
    print(f"total after {n} intervals: {dec(by_terms.numerator, by_terms.denominator, 15)}, "
          f"short of 0.01 by 0.01 / 2^{n}")

example = [(-200000, 1100000), (800000, 1900000), (1000000, 1400000),
           (1500000, 2600000), (2400000, 3300000)]
x = lambda um: 40 + 9 * um // 100000                          # 90 figure units per metre
print("figure, fence 0 to 3 m drawn from x=40 to x=310, 90 units per metre")
print("figure, " + "; ".join(f"({metres(c)}, {metres(d)}) m at x {x(c)} to {x(d)}" for c, d in example))
walk = chain(example, 0, 3 * M)
print("chain from the proof: " + ", ".join(f"({metres(c)}, {metres(d)})" for c, d in walk)
      + f"; chain total {metres(size(walk))} m, all five {metres(size(example))} m")
assert walk == [example[i] for i in (0, 1, 3, 4)] and size(walk) == 4400000   # the figure

seed, per, trials = 2026, 6, 20000                            # seed, tapes per family, families
state, hits, agree, low_total, low_chain = seed, 0, True, None, None
for _ in range(trials):
    fam = []
    for _ in range(per):
        state, r1 = splitmix(state)
        state, r2 = splitmix(state)
        c = -300000 + r1 % 3200001
        fam.append((c, c + 300000 + r2 % 1200001))
    walked = chain(fam, 0, 3 * M)
    agree = agree and (walked is not None) == covers(fam, 0, 3 * M)
    if walked is not None:
        hits += 1
        assert size(fam) >= size(walked) > 3 * M              # the theorem, one cover at a time
        low_total = size(fam) if low_total is None else min(low_total, size(fam))
        low_chain = size(walked) if low_chain is None else min(low_chain, size(walked))
print(f"random families of {per} open intervals (SplitMix64, seed {seed}): {trials}")
print(f"families covering [0, 3]: {hits}; union test and chain walk agree on every one: {'yes' if agree else 'no'}")
print(f"smallest total among covers: {metres(low_total)} m; smallest chain total: {metres(low_chain)} m")

first = lambda n: next(q for q in rationals(n + 60) if all(abs(q - c) >= Fr(1, 200 * 2**k)
                       for k, c in enumerate(qs[:n], start=1)))
print(f"mistake 1, finitely many intervals: the first 10 miss {first(10)}, the first 40 miss {first(40)}; "
      "a finite cover of every rational in [0, 1] totals at least 1")
print(f"mistake 2, adding overlapping pieces: (0, 2) and (1, 3) give 2 + 2 = 4 m; "
      f"their union is {metres(size(merge([(0, 2 * M), (M, 3 * M)])))} m")
print("mistake 3, 'no interval inside, so size 0': irrationals in [0, 1] at least "
      + ", ".join(f"1 - {metres(e)} = {metres(M - e)}" for e in (10000, 100, 1)))
assert agree and hits > 0                                     # two roads to "is it a cover"
assert missed == SPOTS and len(holes) == len(missed)          # the gaps miss exactly the spots
assert size(merge([(0, 2 * M), (M, 3 * M)])) == 3 * M          # the union is (0, 3)
touch = [(-M, 3 * M // 2), (3 * M // 2, 4 * M)]                # meet at 1.5 m, leave it out
assert chain(touch, 0, 3 * M) is None and not covers(touch, 0, 3 * M)
for bare in ((0, 3 * M + 1000), (-1000, 3 * M)):               # one tape, one fence end left out
    assert chain([bare], 0, 3 * M) is None and not covers([bare], 0, 3 * M)
print("ALL CHECKS PASS")
