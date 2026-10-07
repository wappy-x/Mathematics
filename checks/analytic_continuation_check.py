# Analytic continuation -- the check behind the card.  Standard library only.
# A perpetuity pays $1 a year for ever; z = 1/(1 + r) discounts a year at rate r.
# Road one adds the payments, or walks a chain of discs carrying one number, the
# value v; road two is the closed form 1/r.  The walk never uses 1/(1 - z).
import math

def disc_series(c, v, z, terms=600):   # the series at centre c, coefficients v^(k+1)
    total, term = 0j, v
    for _ in range(terms):
        total, term = total + term, term * v * (z - c)
    return total

def paid(r, n_years):                  # road one: add up n_years discounted payments
    return sum((1 + r) ** -n for n in range(1, n_years + 1))

def show(w):                           # 'a + bi', six decimals, no -0.000000
    a, b = round(w.real, 6) + 0.0, round(w.imag, 6) + 0.0
    return f"{a:.6f} {'-' if b < 0 else '+'} {abs(b):.6f}i"

print(f"r = 5%: z = {1 / 1.05:.6f}; 3000 payments add to {paid(0.05, 3000):.6f}; 1/r = {1 / 0.05:.6f}")
r = -0.005
z = 1 / (1 + r)
print(f"r = -0.5%: z = {z:.6f}, outside the unit disc; 1/r = {1 / r:.6f}")
for n in (100, 1000):
    print(f"  {n} payments add to {paid(r, n):.6f}; -200 + 200 z^{n} = {-200 + 200 * z ** n:.6f}")
centres, v = [0j, 0.5 + 0.5j, 1 + 0.4j, 1.2 + 0.1j, 1.02 + 0j], 1 + 0j
for a, b in zip(centres, centres[1:]):
    new_v = disc_series(a, v, b)
    print(f"  disc at {show(a)}, radius 1/|v| = {1 / abs(v):.6f}, step ratio "
          f"{abs(v * (b - a)):.6f}, hands on v = {show(new_v)}")
    v = new_v
f_T = disc_series(centres[-1], v, z)
last = f_T - 1
print(f"chain of discs: f(T) = {show(f_T)}, so P = f(T) - 1 = {show(last)}; last disc radius "
      f"{1 / abs(v):.6f}, ratio {abs(v * (z - centres[-1])):.6f}")
rival = lambda r: 1 / r + math.sin(math.pi / r)          # agrees with 1/r at r = 1/n only
print(f"rival 1/r + sin(pi/r): at 5% {rival(0.05):.6f}, at 50% {rival(0.5):.6f}; "
      f"at -0.75% {rival(-0.0075):.6f} against 1/r = {1 / -0.0075:.6f}")
print(f"mistake, payment now counted too: 1/(1 - z) at 5% = {1 / (1 - 1 / 1.05):.6f}, not 20")
t = 0.01
smooth = sum(n * math.exp(-n * t) for n in range(1, 6000))
print(f"1 + 2 + ... + 100 = {sum(range(101))}; sum of n e^(-nt) at t = {t}, minus 1/t^2 = "
      f"{smooth - 1 / t ** 2:.6f}; -1/12 = {-1 / 12:.6f}")
print("figure, discs " + " ".join(f"({110 + 100 * c.real:.1f},{135 - 100 * c.imag:.1f},r{100 * abs(1 - c):.1f})"
      for c in centres) + f"; pole (210.0,135.0); T ({110 + 100 * z:.1f},135.0)")
assert abs(paid(0.05, 3000) - 20) < 1e-9 and abs(paid(r, 1000) / ((1 - z ** 1000) / r) - 1) < 1e-12
assert abs(last - 1 / r) < 1e-8                                  # the walk lands on 1/r
assert abs(smooth - 1 / t ** 2 + 1 / 12) < 1e-5                  # the smoothed constant
assert abs(rival(0.05) - 20) < 1e-9 and abs(rival(-0.0075) - 1 / -0.0075) > 0.5
print("ALL CHECKS PASS")
