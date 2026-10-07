# The elementary functions in the plane -- the check behind the card.  Standard library only.
# Road one: e^z summed from its own series; cos z and sin z built from it by the exponential rules.
# Road two: the separate power series of cos and sin, summed straight at a complex input.
# Road three: the real cosh and sinh, from math.exp, averaged and halved by hand.
import math

def exp_s(z, terms=60):                      # 1 + z + z^2/2! + ..., each term the last times z/n
    total, term = 0j, 1 + 0j
    for n in range(1, terms + 1):
        total, term = total + term, term * z / n
    return total

def cos_e(z): return (exp_s(1j * z) + exp_s(-1j * z)) / 2
def sin_e(z): return (exp_s(1j * z) - exp_s(-1j * z)) / 2j

def trig_s(z, start, terms=40):              # start 0: 1 - z^2/2! + ...; start 1: z - z^3/3! + ...
    total, term = 0j, z ** start + 0j
    for k in range(terms):
        n = start + 2 * k
        total, term = total + term, -term * z * z / ((n + 1) * (n + 2))
    return total

def show(w):                                 # 'a + bi', six decimals, no -0.000000
    a, b = round(w.real, 6) + 0.0, round(w.imag, 6) + 0.0
    return f"{a:.6f} {'-' if b < 0 else '+'} {abs(b):.6f}i"

ch = lambda y: (math.exp(y) + math.exp(-y)) / 2
sh = lambda y: (math.exp(y) - math.exp(-y)) / 2
print(f"wave cos 1 = {math.cos(1):.6f}; cable cosh 1 = {ch(1):.6f}; sinh 1 = {sh(1):.6f}")
print(f"cos(i): exponentials {show(cos_e(1j))}; own series {show(trig_s(1j, 0))}")
print(f"sin(i): exponentials {show(sin_e(1j))}; own series {show(trig_s(1j, 1))}")
w = 1 + 3j
print(f"sin(1 + 3i): exponentials {show(sin_e(w))}; sin 1 cosh 3 + i cos 1 sinh 3 = "
      f"{show(complex(math.sin(1) * ch(3), math.cos(1) * sh(3)))}")
print("size of sin(iy), y = 1, 3, 10: " + ", ".join(f"{abs(sin_e(1j * y)):.6f}" for y in (1, 3, 10)))
z = 1 + 1j
ez = exp_s(z)
print(f"e^z at z = 1 + i: series {show(ez)}; e(cos 1 + i sin 1) = {show(math.e * complex(math.cos(1), math.sin(1)))}")
gaps = {}
for name, u in (("real", 1), ("imaginary", 1j), ("diagonal", (1 + 1j) / math.sqrt(2))):
    gaps[name] = [abs((exp_s(z + s * u) - ez) / (s * u) - ez) for s in (0.1, 0.001, 0.00001)]
    print(f"slope of e^z at 1 + i, step {name}: gap from e^z at size 0.1, 0.001, 0.00001: "
          + ", ".join(f"{g:.6f}" for g in gaps[name]))
print(f"e^z times e^-z: {show(ez * exp_s(-z))}; e^(z + 2 pi i): {show(exp_s(z + 2j * math.pi))}")
bar = lambda v: exp_s(v.conjugate())
qr, qi = [(bar(z + d) - bar(z - d)) / (2 * d) for d in (1e-4, 1e-4j)]   # centred slopes
print(f"mistake, e^(z-bar): slope along real {show(qr)}, along imaginary {show(qi)}")
print(f"mistake, dividing by 2 not 2i at z = i: {show((exp_s(-1) - exp_s(1)) / 2)}")
print(f"mistake, period 2 pi read as real: e^(z + 2 pi) / e^z = {abs(exp_s(z + 2 * math.pi) / ez):.6f}")
ts = [k / 2 for k in range(7)]
print("chart, wave cos t: " + ", ".join(f"{math.cos(t):.2f}" for t in ts))
print("chart, cable cos(it): " + ", ".join(f"{cos_e(1j * t).real:.2f}" for t in ts))
assert abs(cos_e(1j) - trig_s(1j, 0)) < 1e-12 and abs(sin_e(1j) - trig_s(1j, 1)) < 1e-12
assert all(abs(cos_e(1j * t) - ch(t)) < 1e-12 and abs(sin_e(1j * t) - 1j * sh(t)) < 1e-12 for t in ts)
assert abs(ez - math.e * complex(math.cos(1), math.sin(1))) < 1e-12 and all(
    g[0] > g[1] > g[2] and g[2] < 1e-4 for g in gaps.values())
assert abs(exp_s(z + 2j * math.pi) - ez) < 1e-12 and abs(qr + qi) < 1e-4 < abs(qr)
print("ALL CHECKS PASS")
