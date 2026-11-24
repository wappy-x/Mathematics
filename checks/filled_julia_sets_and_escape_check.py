# Filled Julia sets -- the check behind the card.  Standard library only.
# The map is f(z) = z*z + c.  Road one: iterate and watch for |z| > max(2, |c|).
# Road two: exact algebra -- the golden-ratio edge for c = -1, the unit disc for c = 0.
import math

def orbit(z, c, steps):                     # z, f(z), f(f(z)), ... as a list
    out = [z]
    for _ in range(steps):
        out.append(out[-1] * out[-1] + c)
    return out

def escape_step(z, c, cap):                 # first n with |z_n| > max(2, |c|), else None
    r = max(2.0, abs(c))
    for n in range(cap + 1):
        if abs(z) > r:
            return n
        z = z * z + c
    return None
def row(zs):                                # orbits printed here are all real
    return ", ".join(f"{z.real:.6f}" for z in zs)
print(f"c = -1, start 0: {row(orbit(0j, -1, 4))}")
print(f"c = -1, start 2: {row(orbit(2 + 0j, -1, 3))}")
a, b, o = orbit(1.5 + 0j, -1, 6), orbit(1.7 + 0j, -1, 3), orbit(1.5 + 0j, -1, 1000)
print(f"start 1.5: {row(a)}")
print(f"start 1.5: largest |z_n| over 1000 steps {max(abs(z) for z in o):.6f}; steps 999 and 1000: {row(o[-2:])}")
print(f"start 1.7: {row(b)}; first beyond 2 at step {escape_step(1.7 + 0j, -1, 50)}")
bound = abs(b[2]) * (abs(b[2]) - 1)
print(f"escape lemma at step 2: |z_3| >= {abs(b[2]):.4f} x {abs(b[2]) - 1:.4f} = {bound:.6f}; actual {abs(b[3]):.6f}")
worst = min(abs(z * z + c) / (abs(z) * (abs(z) - 1))
            for c in (complex(x / 2, y / 2) for x in range(-8, 9) for y in range(-8, 9))
            for k in range(1, 11) for t in range(24)
            for z in [max(2, abs(c)) * (1 + k / 10) * complex(math.cos(t * math.pi / 12), math.sin(t * math.pi / 12))])
print(f"lemma on 69360 pairs (z, c) with |z| > max(2, |c|): smallest |f(z)| / (|z|(|z| - 1)) = {worst:.6f}")
lo, hi = 1.5, 1.7                          # bisection: 1.5 stays, 1.7 escapes
for _ in range(40):
    mid = (lo + hi) / 2
    lo, hi = (lo, mid) if escape_step(mid + 0j, -1, 1000) is not None else (mid, hi)
phi = (1 + math.sqrt(5)) / 2
print(f"edge of the filled set on the real line, by bisection: {lo:.6f}; golden ratio (1 + sqrt 5)/2 = {phi:.6f}")
near, stays = escape_step(1.6181 + 0j, -1, 1000), escape_step(1.618 + 0j, -1, 1000) is None
print(f"near the edge: start 1.6180 stays for 1000 steps: {'yes' if stays else 'no'}; start 1.6181 escapes at step {near}")
h, inside = 0.015, 0
for i in range(-100, 101):
    for j in range(-100, 101):
        inside += escape_step(complex(i * h, j * h), 0, 40) is None
print(f"c = 0 on a 201 x 201 grid, spacing {h}: {inside} points stay; area {inside * h * h:.4f}; unit disc pi = {math.pi:.4f}")
z6 = complex(0.5, math.sqrt(23) / 2)       # a root of z*z - z + 6 = 0: a fixed point for c = 6
w6 = z6 * z6 + 6
print(f"mistake 1, radius 2 when c = 6: z = {z6.real:.6f} + {z6.imag:.6f}i has |z| = {abs(z6):.6f} > 2, "
      f"yet f(z) = {w6.real:.6f} + {w6.imag:.6f}i: it never moves")
print(f"mistake 2, >= 2 instead of > 2, c = -2: start 2 gives {row(orbit(2 + 0j, -2, 3))}")
print(f"mistake 3, stop after 5 steps: 1.6181 is at {orbit(1.6181 + 0j, -1, 5)[5].real:.6f}, not out yet, but escapes at step {near}")
assert [z.real for z in orbit(0j, -1, 4)] == [0, -1, 0, -1, 0]            # the 2-cycle
assert abs(b[3].real - 5.61569841) < 1e-12 and escape_step(1.7 + 0j, -1, 50) == 2
assert escape_step(1.5 + 0j, -1, 1000) is None and abs(b[3]) >= bound and abs(w6 - z6) < 1e-12
assert escape_step(z6, 6, 10) is None and escape_step(2 + 0j, -2, 50) is None  # mistakes 1, 2 stay
assert worst >= 1 and abs(o[-1]) < 1e-9                                   # the lemma; 1.5 lands on the cycle
assert abs(lo - phi) < 1e-9 and stays and near == 8                         # bisection meets the algebra
assert abs(inside * h * h - math.pi) < 0.05                               # the grid meets the unit disc
print("ALL CHECKS PASS")
