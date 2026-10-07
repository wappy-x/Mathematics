# Stirling's formula -- the check behind the card.  Standard library only.
# Road one: the gamma integral, t^s e^(-t) from 0 to infinity, summed by
# trapezoids after t = e^v.  Road two: values known without that integral --
# whole-number products, the half-integer ladder down to sqrt(pi), and
# |Gamma(1 + iy)|^2 = pi y / sinh(pi y).  Stirling is then measured against both.
import math

def fact(s):                                   # s! = Gamma(s + 1), road one
    h, total = 0.005, 0j
    for k in range(-8000, 1401):               # v from -40 to 7
        v = k * h
        total += math.exp((s.real + 1) * v - math.exp(v)) * complex(math.cos(s.imag * v), math.sin(s.imag * v))
    return total * h

def clog(z): return complex(math.log(abs(z)), math.atan2(z.imag, z.real))
def cexp(z): return math.exp(z.real) * complex(math.cos(z.imag), math.sin(z.imag))
def stirling(s): return cexp(0.5 * clog(2 * math.pi * s) + s * (clog(s) - 1))
def ladder(s):                                 # road two for half-integers: s(s-1)...(1/2) sqrt(pi)
    out = math.sqrt(math.pi)
    while s > 0: out, s = out * s, s - 1
    return out
def product(n):                                # road two for whole numbers
    out = 1
    for k in range(2, n + 1): out *= k
    return out
def sci(x, d=4):
    e = math.floor(math.log10(abs(x))); return f"{x / 10 ** e:.{d}f} x 10^{e}"
def cf(z): return f"{z.real:.6f} {'+' if z.imag >= 0 else '-'} {abs(z.imag):.6f}i"

for n in (10, 52):
    ex, it, st = product(n), fact(complex(n)).real, stirling(complex(n)).real
    print(f"{n}!: product {sci(ex, 6)}, integral {sci(it, 6)}, Stirling {sci(st, 6)}, low by {100 * (1 - st / ex):.4f}%")
    assert abs(it / ex - 1) < 1e-9                                # road one meets road two
print(f"52! minus Stirling: {sci(ex - st)}, a ratio of {st / ex:.6f}")
for s in (0.5, 4.5):
    tr, it, st = ladder(s), fact(complex(s)).real, stirling(complex(s)).real
    print(f"{s}!: ladder {tr:.6f}, integral {it:.6f}, Stirling {st:.6f}, ratio {tr / st:.6f}, 1 + 1/(12s) {1 + 1 / (12 * s):.6f}")
    assert abs(it / tr - 1) < 1e-9
L = 52 * math.log(52); H = 0.5 * math.log(2 * math.pi * 52); T = (L - 52 + H) / math.log(10)
print(f"52 by hand: 52 ln 52 = {L:.4f}, half ln(2 pi 52) = {H:.4f}, total {L - 52 + H:.4f}, over ln 10 = {T:.6f}, 10^{T - 67:.6f} = {10 ** (T - 67):.4f}")
print(f"Laplace at s = 10: peak t = 10, height {10 ** 10 * math.exp(-10):.4f}, width sqrt(10) = {math.sqrt(10):.6f}, sqrt(2 pi 10) = {math.sqrt(20 * math.pi):.6f}")
ts = range(0, 25, 2)
print("chart, t:", " ".join(str(t) for t in ts))
print("chart, bump:", " ".join(f"{t ** 10 * math.exp(-t):.0f}" for t in ts))
print("chart, bell:", " ".join(f"{10 ** 10 * math.exp(-10 - (t - 10) ** 2 / 20):.0f}" for t in ts))
ss = (0.5, 1, 2, 4.5, 10, 20, 52)
low = [100 * (1 - stirling(complex(s)).real / fact(complex(s)).real) for s in ss]
print("chart, s:", " ".join(str(s) for s in ss))
print("chart, percent low:", " ".join(f"{x:.2f}" for x in low))
print("chart, 100/(12s):", " ".join(f"{100 / (12 * s):.2f}" for s in ss))
for s in ss: g = math.log(fact(complex(s)).real / stirling(complex(s)).real); assert 0 < g < 1 / (12 * s)
z = 10j; it, st = fact(z), stirling(z); cl = 10 * math.pi / math.sinh(10 * math.pi)
print(f"s = {z.imag:g}i: |integral|^2 {sci(abs(it) ** 2, 6)}, pi y/sinh(pi y) {sci(cl, 6)}, ratio {cf(it / st)}, 1 + 1/(12s) {cf(1 + 1 / (12 * z))}")
assert abs(abs(it) ** 2 / cl - 1) < 1e-8 and abs(it / st - 1 - 1 / (12 * z)) < 1e-4
print(f"mistake, no sqrt(2 pi n): (10/e)^10 = {(10 / math.e) ** 10:.2f} against 3628800")
print(f"mistake, Stirling at 10 read as Gamma(10) = 9! = {product(9)}: off by {stirling(10 + 0j).real / product(9):.4f} times")
print(f"mistake, s = -4.5: truth Gamma(-3.5) = {math.sqrt(math.pi) / (-0.5 * -1.5 * -2.5 * -3.5):.6f}, Stirling's size {abs(stirling(-4.5 + 0j)):.6f}")
print("ALL CHECKS PASS")
