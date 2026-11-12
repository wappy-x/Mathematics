# Absolute and relative error -- the check behind the card.  Standard library only.
# A 3,000 mm beam and a 20 mm bolt, each cut 2 mm short.  Lengths are whole
# millimetres, so the misses and the digit test are exact integer arithmetic;
# the relative error is a float, checked against the integers and a bracket.
from math import log10


def sci(v, d):                       # e-notation printed the same way as Rust: 6.667e-4
    m, e = f"{v:.{d}e}".split("e")
    return m + "e" + str(int(e))


def lead_power(x):                   # k with 10^k <= x < 10^(k+1): the power in scientific notation
    k = 0
    while 10 ** (k + 1) <= x:
        k += 1
    return k


def digits(x, miss):                 # road 1: p correct digits when miss <= half a unit in digit p
    k, p = lead_power(x), 0
    while p < 17 and 2 * miss * 10 ** p <= 10 ** k:
        p += 1
    return p


def half_unit(x, p):                 # half a unit in digit p of x: 1/2 x 10^(k-p+1)
    k = lead_power(x)
    return 5 * 10 ** (k - p) if k >= p else 5 / 10 ** (p - k)


def bracket(rel):                    # road 2: what the relative error alone allows
    lo = hi = 0
    while lo < 17 and rel * 10 ** (lo + 2) <= 5:   # rel <= 5 x 10^-(p+1) guarantees p digits
        lo += 1
    while hi < 17 and rel * 10 ** (hi + 1) <= 5:   # p digits forces rel <= 5 x 10^-p
        hi += 1
    return lo, hi


def matching(a, b):                  # the wrong test: count leading characters that agree
    n = 0
    for c, d in zip(str(a), str(b)):
        if c != d:
            break
        n += 1
    return n


def report(name, x, xhat):
    miss = abs(xhat - x)             # absolute error, exact
    rel = miss / x                   # relative error
    p, (lo, hi) = digits(x, miss), bracket(rel)
    print(f"{name}: true {x}, got {xhat}, abs {miss}, rel {sci(rel, 3)}, "
          f"percent {100 * rel:.4f}, digits {p}, bracket {lo}-{hi}, -log10 {-log10(rel):.3f}, "
          f"half-units at digits {p} and {p + 1}: {half_unit(x, p)}, {half_unit(x, p + 1)}")
    assert abs(rel * x - miss) < 1e-12 * x            # converting back gives the integer miss
    assert (p == 0 or miss <= half_unit(x, p)) and miss > half_unit(x, p + 1)
    assert lo <= p <= hi and hi - lo <= 1             # the relative error pins digits within one
    assert -log10(rel) - 1.302 < p <= -log10(rel) + 0.699
    return miss, rel, p


beam_abs, beam_rel, beam_p = report("beam", 3000, 2998)
bolt_abs, bolt_rel, bolt_p = report("bolt", 20, 18)
print(f"same miss, bolt rel / beam rel = {bolt_rel / beam_rel:.1f}")
print(f"kept digits: beam {2998 / 1000:.{beam_p - 1}f} m, bolt {sci(18, bolt_p - 1)} mm")
assert beam_abs == bolt_abs == 2 and beam_p == 3 and bolt_p == 1
assert abs(bolt_rel / beam_rel - 3000 / 20) < 1e-9

# units: metres change the absolute error, not the relative one
m_abs, m_rel = abs(2.998 - 3.0), abs(2.998 - 3.0) / 3.0
print(f"beam in metres: abs {m_abs:.6f} m, rel {sci(m_rel, 3)}")
assert abs(m_rel - beam_rel) < 1e-12 and abs(m_abs * 1000 - beam_abs) < 1e-9

# converting: a tape rated 0.1 percent, as millimetres on each part
for name, x in (("beam", 3000), ("bolt", 20)):
    print(f"0.1 percent of the {name}: {0.001 * x:.3f} mm")

# same relative error 4e-4, one digit apart
r1, r2 = report("10 m rail", 10000, 9996), report("97.5 m rail", 97500, 97461)
assert r1[1] == r2[1] == 4e-4 and (r1[2], r2[2]) == (4, 3)

# what breaks
print(f"wrong: divide by the cut length, bolt {100 * 2 / 18:.4f} percent, beam {sci(2 / 2998, 3)}")
assert abs(2 / 18 - bolt_rel / (1 - bolt_rel)) < 1e-15        # dividing by xhat gives rel/(1 - rel)
print(f"wrong: count matching digits of 2998 and 3000: {matching(2998, 3000)}")
gap = report("clearance in a 3001 mm opening", 3001 - 3000, 3001 - 2998)
assert gap[1] == 2.0 and gap[2] == 0

# try changing
tries = [report(name, x, xhat)[2] for name, x, xhat in (
    ("beam, 1 mm miss", 3000, 2999), ("beam, 6 mm miss", 3000, 2994),
    ("200 mm bolt, 2 mm miss", 200, 198), ("30 m girder, 2 mm miss", 30000, 29998))]
assert tries == [3, 2, 2, 4]                                   # the digit counts found by hand

# the shelf's house example: a tracker adds 0.1 ten million times
total = 0.0
for _ in range(10_000_000):
    total += 0.1
t_abs = abs(total - 1_000_000)
t_rel = t_abs / 1_000_000
t_p, (t_lo, t_hi) = digits(1_000_000, t_abs), bracket(t_rel)
print(f"tracker: total {total:.6f}, abs {sci(t_abs, 3)}, rel {sci(t_rel, 3)}, digits {t_p}, bracket {t_lo}-{t_hi}")
assert 1e-4 < t_abs < 2e-4 and t_p == 10 and t_lo <= t_p <= t_hi
print("ALL CHECKS PASS")
