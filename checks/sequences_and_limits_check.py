# Sequences and limits -- the check behind the card.  Standard library only;
# math.sqrt is the one primitive used.  Each cutoff N is found by a formula and
# by walking the terms; the climb to 2 is met by iterating and by algebra.
import math

def cutoff_formula(p, q):             # tolerance p/q: 1/n < p/q exactly when n > q/p
    return q // p

def cutoff_scan(p, q):                # walk n up, remember the last term not inside
    last = 0
    for n in range(1, 10 * q):        # 1/n only shrinks, so no later term can fail
        if 1 / n >= p / q:
            last = n
    return last

def two(xs):
    return " ".join(f"{x:.2f}" for x in xs)

print("sequence a_n = 1/n, heading for L = 0")
print("chart, 1/n for n = 1..12:", two(1 / n for n in range(1, 13)))
for p, q in ((1, 10), (1, 100), (3, 1000)):
    nf, ns = cutoff_formula(p, q), cutoff_scan(p, q)
    print(f"tolerance {p}/{q}: N by formula {nf}, N by scan {ns}")
    assert nf == ns                                            # two roads, one cutoff
print(f"term 10 misses by {1 / 10:.6f}, term 11 is inside at {1 / 11:.6f}")
print(f"mistake, cutoff 9 for tolerance 1/10: term 10 sits at {1 / 10:.6f}, not below 0.1")
alt = [(-1) ** n for n in (101, 102)]
print(f"mistake, bounded is not convergent: (-1)^n at n = 101, 102 gives {alt[0]}, {alt[1]}; "
      f"gap {alt[1] - alt[0]} > 2 x 0.1")
x = 1 + 1 / 11
f = (x * x - 1) / (x - 1)                                      # the uncancelled fraction
print(f"house example, (x^2 - 1)/(x - 1) at x = 1 + 1/11: {f:.6f}, off 2 by {f - 2:.6f}")
assert abs((f - 2) - 1 / 11) < 1e-12                           # fraction road vs 1/n road
c, climb = 0.0, []
for n in range(1, 21):                                         # c_1 = 0, c_(n+1) = sqrt(2 + c_n)
    climb.append(c)
    c = math.sqrt(2 + c)
print("climb c_n, n = 1..6:", " ".join(f"{v:.6f}" for v in climb[:6]))
print("gap 2 - c_n, n = 1..6:", " ".join(f"{2 - v:.6f}" for v in climb[:6]))
print("chart, c_n for n = 1..5:", two(climb[:5]))
up = all(a < b for a, b in zip(climb, climb[1:])) and all(v < 2 for v in climb)
print(f"every step up and every term below 2, n = 1..20: {'yes' if up else 'no'}")
root = (1 + math.sqrt(1 + 8)) / 2                              # road 2: L*L = 2 + L
print(f"road 2, L = sqrt(2 + L) so L^2 - L - 2 = 0: L = {root:.6f} or {(1 - math.sqrt(1 + 8)) / 2:.6f}")
assert up and abs(climb[-1] - root) < 1e-10                    # iteration vs algebra
print(f"first climb term within 0.1 of 2: n = {next(n for n, v in enumerate(climb, 1) if 2 - v < 0.1)}")
d = 1
for _ in range(19):
    d *= 2
print(f"mistake, no ceiling: d_(n+1) = 2 d_n from 1 has 'fixed point' 0, yet d_20 = {d}")
h = sum(1 / k for k in range(1, 1025))                         # road 1: add every term
print(f"mistake, steps shrink but no ceiling: 1 + 1/2 + ... + 1/1024 = {h:.6f}, "
      f"doubling-block bound 1 + 10/2 = {1 + 10 / 2:.6f}, last step {1 / 1024:.6f}")
assert h >= 1 + 10 / 2                                         # road 2: blocks of 1/2
print("ALL CHECKS PASS")
