# The Haar wavelet on the whole line: eight days of bakery sales as averages and differences.
# Standard library only.  Roads: the averages-and-differences ladder, integrals of f times
# each Haar function on the time line (midpoint sums, exact for these steps), and energy.
from fractions import Fraction as Fr
sales = [820, 760, 900, 980, 1240, 1300, 640, 600]  # dollars, day 1 = t in [0, 1) days
H = 1 / 8                                            # grid step in days for the integrals
def phi(x): return 1.0 if 0 <= x < 1 else 0.0
def psi(x): return 1.0 if 0 <= x < 0.5 else (-1.0 if 0.5 <= x < 1 else 0.0)
def unit(g, j, k): return lambda t: 2 ** (-j / 2) * g(2 ** (-j) * t - k)
def f(t): return float(sales[int(t)]) if 0 <= t < 8 else 0.0
def integral(u, a, b): return sum(u(a + (i + 0.5) * H) for i in range(int((b - a) / H))) * H
def inner(u, v, a=0, b=16): return integral(lambda t: u(t) * v(t), a, b)
def close(a, b, tol=1e-9): return abs(a - b) <= tol
def ladder(x, levels):  # averages and half-differences, as on a till roll
    s, out = list(x), []
    for _ in range(levels):
        h = len(s) // 2
        out.append([(s[2 * i] - s[2 * i + 1]) / 2 for i in range(h)])
        s = [(s[2 * i] + s[2 * i + 1]) / 2 for i in range(h)]
    return s, out  # coarsest averages, then half-differences from level 1 up
def row(xs, d=0): return " ".join(f"{x:.{d}f}" for x in xs)
print("sales, dollars, days 1..8:", row(sales))
energy = sum(x * x for x in sales)
print(f"total {sum(sales)}  energy sum f^2 {energy} dollars^2/day")
avg3, half = ladder(sales, 3)
for j in range(3):
    print(f"level {j + 1} averages: {row(ladder(sales, j + 1)[0])}   half-differences: {row(half[j])}")
# road 1: coefficient = 2^(j/2) * average or half-difference;  road 2: integral on the line
coarse = inner(f, unit(phi, 3, 0))
print(f"<f, phi_3,0> integral {coarse:.6f}  ladder {2 ** 1.5 * avg3[0]:.6f}")
assert close(coarse, 2 ** 1.5 * avg3[0])
level_energy = []
for j in (3, 2, 1):
    c = [inner(f, unit(psi, j, k)) for k in range(8 >> j)]
    print(f"<f, psi_{j},k> integral: {row(c, 6)}")
    for k in range(8 >> j):
        assert close(c[k], 2 ** (j / 2) * half[j - 1][k])
    level_energy.append(sum(x * x for x in c))
print(f"energy by part: coarse {coarse ** 2:.1f}  level 3 {level_energy[0]:.1f}  level 2 {level_energy[1]:.1f}"
      f"  level 1 {level_energy[2]:.1f}  sum {coarse ** 2 + sum(level_energy):.1f}")
assert close(coarse ** 2 + sum(level_energy), energy, 1e-6)
# rebuild day 1..8 from the coefficients: f = sum c phi + sum d psi
basis = [(coarse, unit(phi, 3, 0))] + [(inner(f, unit(psi, j, k)), unit(psi, j, k)) for j in (1, 2, 3) for k in range(8 >> j)]
rebuilt = [sum(c * u(d + 0.5) for c, u in basis) for d in range(8)]
print("rebuilt days:", row(rebuilt, 6))
assert max(abs(a - b) for a, b in zip(rebuilt, sales)) < 1e-9
dropped = [sum(c * u(d + 0.5) for c, u in basis[1:]) for d in range(8)]
print("details only, no coarse box:", row(dropped, 1), f" energy {sum(level_energy):.1f}"
      f" = {100 * sum(level_energy) / energy:.2f}%")
# orthonormality: every psi_{j,k} with support inside [0, 16), levels -1..3, by integration
fam = [(j, k) for j in (-1, 0, 1, 2, 3) for k in range(int(16 / 2 ** j))]
gap = max(abs(inner(unit(psi, *a), unit(psi, *b)) - (1.0 if a == b else 0.0)) for a in fam for b in fam)
print(f"Gram matrix of {len(fam)} Haar functions, levels -1..3 on [0,16): max |G - I| {gap:.12f}")
assert gap < 1e-12
cross = max(abs(inner(unit(phi, 3, 0), unit(psi, j, k))) for j in (1, 2, 3) for k in range(8 >> j))
print(f"coarse box against every finer detail: max |inner| {cross:.12f}")
assert cross < 1e-12
two_scale = max(max(abs(phi(t) - phi(2 * t) - phi(2 * t - 1)), abs(psi(t) - phi(2 * t) + phi(2 * t - 1)))
                for t in [(i + 0.5) / 64 - 1 for i in range(192)])
print(f"two-scale: phi(t) = phi(2t) + phi(2t-1), psi(t) = phi(2t) - phi(2t-1): max error {two_scale:.1f}")
assert two_scale == 0.0
# separation: the coarse part drains away, energy 7240^2 / 2^J, by formula and by the ladder
print("J | energy left in V_J: formula, ladder on [0, 4096) | share captured by details")
long_row = sales + [0] * (4096 - 8)
for J in (3, 4, 5, 6, 8, 10, 12):
    left = sum(sales) ** 2 / 2 ** J
    s, _ = ladder(long_row, J)
    by_ladder = sum((2 ** (J / 2) * a) ** 2 for a in s)
    assert close(left, by_ladder, 1e-6)
    print(f"{J:2d} | {left:.3f}  {by_ladder:.3f} | {100 * (1 - left / energy):.4f}%")
print(f"20 | {sum(sales) ** 2 / 2 ** 20:.3f}")
# what breaks
naive = sum(x * x for x in avg3) + sum(x * x for lv in half for x in lv)
print(f"averages and half-differences as coordinates: sum of squares {naive:.1f} (true {energy})")
assert not close(naive, energy, 1)
hs = inner(unit(psi, 0, 0), lambda t: psi(t - 0.5))  # a step against its half-day shift
print(f"half shift: <psi, psi(t - 1/2)> = {hs:.6f}")
assert close(hs, -0.5)
e4 = inner(lambda t: psi(t / 4), lambda t: psi(t / 4))  # width 4, height 1
print(f"no 2^(-j/2): energy of psi(t/4) = {e4:.6f}")
assert close(e4, 4.0)
shifted = [0] + sales + [0] * 7                      # the same week, one day later
for name, x in (("as recorded", sales + [0] * 8), ("one day later", shifted)):
    s, hd = ladder(x, 4)
    e = [sum((2 ** (j / 2) * v) ** 2 for v in hd[j - 1]) for j in (1, 2, 3, 4)]
    print(f"{name}: detail energy levels 1-4 {row(e, 1)}  coarse {(4 * s[0]) ** 2:.1f}")
    assert close(sum(e) + (4 * s[0]) ** 2, energy, 1e-6)
# converges in energy, not uniformly: a till opening at 8 a.m. (t = 1/3 day), boxes 2^-m wide
print("m | box days | worst gap | energy gap: by boxes, formula (2/9) 2^-m")
for m in (1, 2, 4, 8, 12):
    w = Fr(1, 2 ** m)
    kept = sum(w * (min(Fr(1), (i + 1) * w) - max(Fr(1, 3), i * w)) ** 2 / w ** 2
               for i in range(2 ** m) if (i + 1) * w > Fr(1, 3))
    worst = max(Fr(1, 3) % w / w, 1 - Fr(1, 3) % w / w)
    gap_e = Fr(2, 3) - kept                          # Pythagoras: |g|^2 - |projection|^2
    assert gap_e == Fr(2, 9) * w
    print(f"{m:2d} | {float(w):.6f} | {float(worst):.6f} | {float(gap_e):.9f}  {float(Fr(2, 9) * w):.9f}")
print("chart day:", row(range(1, 9)))
print("chart V_0:", row(sales))
print("chart V_1:", row([v for v in ladder(sales, 1)[0] for _ in range(2)]))
print("chart V_2:", row([v for v in ladder(sales, 2)[0] for _ in range(4)]))
print("ALL CHECKS PASS")
