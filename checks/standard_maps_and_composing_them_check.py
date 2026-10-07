# The standard maps -- the check behind the card.  Standard library only.  Road one: polar
# form, from math's cos, sin, exp, log, atan2.  Road two: algebra only -- multiplying out, the
# exponential's series, the log's odd-power series, dividing by the conjugate.  Grids test "onto".
import math
PI, N = math.pi, 30
def cis(t): return complex(math.cos(t), math.sin(t))
def ang(z): return math.atan2(z.imag, z.real)
def pol_pow(z, a): return abs(z) ** a * cis(a * ang(z))            # road one
def pol_exp(z): return math.exp(z.real) * cis(z.imag)
def pol_log(w): return complex(math.log(abs(w)), ang(w))
def cay1(w): return abs(w - 1j) / abs(w + 1j) * cis(ang(w - 1j) - ang(w + 1j))
def cdiv(a, b):                                                    # road two
    return complex(a.real * b.real + a.imag * b.imag, a.imag * b.real - a.real * b.imag) / (b.real ** 2 + b.imag ** 2)
def cay2(w): return cdiv(w - 1j, w + 1j)
def ser_exp(z):                                  # 1 + z + z^2/2! + z^3/3! + ...
    s, t = 0j, 1 + 0j
    for k in range(1, 80): s, t = s + t, t * z / k
    return s
def ser_log(w):          # quarter turn -iw, then Log v = 2(u + u^3/3 + ...), u = (v-1)/(v+1)
    u = cdiv(-1j * w - 1, -1j * w + 1)
    s, p, k = 0j, u, 1
    while abs(p) / k > 1e-18: s, p, k = s + p / k, p * u * u, k + 2
    return 1j * PI / 2 + 2 * s
def fmt(z):                                       # 'a + bi', six decimals, no minus zero
    a, b = [0.0 if abs(v) < 5e-7 else v for v in (z.real, z.imag)]
    return f"{a:.6f} {'-' if b < 0 else '+'} {abs(b):.6f}i"
lot = [complex(0.1 * i, 0.1 * j) for i in range(1, N + 1) for j in range(1, N + 1)]
half = [complex(-3 + 0.2 * i, 0.1 * j) for i in range(N) for j in range(1, N + 1)]
corr = [complex(-3 + 0.2 * i, PI * (j + 0.5) / N) for i in range(N) for j in range(N)]
wedge = [0.1 * i * cis(PI / 4 * (j + 0.5) / N) for i in range(1, N + 1) for j in range(N)]
gap = max([abs(pol_pow(z, 2) - z * z) for z in lot] + [abs(pol_pow(z, 4) - (z * z) * (z * z)) for z in wedge] +
          [abs(pol_exp(z) - ser_exp(z)) for z in corr] + [abs(pol_log(w) - ser_log(w)) + abs(cay1(w) - cay2(w)) for w in half])
onto = [sum(pol_pow(z, 2).imag > 0 for z in lot),
        sum(q.real > 0 and q.imag > 0 and abs(q * q - w) < 1e-9 for w in half for q in [pol_pow(w, 0.5)]),
        sum(pol_exp(z).imag > 0 for z in corr), sum(0 < pol_log(w).imag < PI for w in half),
        sum(pol_pow(z, 4).imag > 0 for z in wedge), sum(abs(cay1(w)) < 1 for w in half)]
z, p, c, w = 1 + 2j, 2 * cis(PI / 8), complex(math.log(2), PI / 3), -3 + 4j
chain1, centre = cay1(pol_pow(z, 2)), cay2(ser_exp(1j * PI / 2))
xi, yi = 1 * 1 - 2 * 2, 2 * 1 * 2                              # integer road: (1 + 2i)^2
num, den = (xi * xi + (yi - 1) * (yi + 1), (yi - 1) * xi - xi * (yi + 1)), xi * xi + (yi + 1) ** 2
print(f"corner lot, 1 + 2i: distance {abs(z):.6f}, angle {ang(z):.6f}; squared, distance {abs(z * z):.6f}, angle {ang(z * z):.6f}; z^2 by polar {fmt(pol_pow(z, 2))}, by multiplying {fmt(z * z)}")
print(f"wedge, 2e^(i pi/8) = {fmt(p)}; z^4 by polar {fmt(pol_pow(p, 4))}; by squaring twice {fmt((p * p) * (p * p))}")
for lab, q in (("ln 2 + i pi/3", c), ("i pi/2", 1j * PI / 2)): print(f"corridor, e^z at {lab}: polar {fmt(pol_exp(q))}; series {fmt(ser_exp(q))}")
print(f"log of -3 + 4i: atan2 {fmt(pol_log(w))}; series {fmt(ser_log(w))}")
print(f"Cayley of -3 + 4i: polar {fmt(cay1(w))}; conjugate {fmt(cay2(w))}; modulus {abs(cay2(w)):.6f}")
print(f"chain, lot to disc at 1 + 2i: {fmt(chain1)}; integer road {num[0]}/{den} + {num[1]}/{den} i\nchain, corridor to disc at i pi/2: {fmt(centre)}, the centre")
print(f"largest gap between the two roads over every grid point below 1e-10: {'yes' if gap < 1e-10 else 'no'}")
print("of 900 grid points each: lot to half plane {}, half plane back to lot {}, corridor to half plane {}, half plane to corridor {}, wedge to half plane {}, half plane to disc {}".format(*onto))
e1, e2 = pol_pow(2 * cis(PI / 4), 2), pol_pow(2 * cis(3 * PI / 16), 8)
left, below = sum(pol_pow(q, 2).real < 0 for q in wedge), sum(pol_pow(q, 8).imag < 0 for q in wedge)
print(f"mistake 1, wedge opened by z^2: top edge 2e^(i pi/4) lands at {fmt(e1)}, angle {ang(e1):.6f}; grid points reaching the left half: {left}")
print(f"mistake 2, wedge opened by z^8: 2e^(i 3pi/16) lands at {fmt(e2)}; grid points thrown below the axis: {below}")
print(f"mistake 3, Cayley upside down, (w + i)/(w - i) at -3 + 4i: modulus {abs(cdiv(w + 1j, w - 1j)):.6f}")
print(f"figure, left 30 per unit, 0 at (40, 200): 1 + 2i at ({40 + 30 * z.real:.2f}, {200 - 30 * z.imag:.2f}), arc radius {30 * abs(z):.2f}; right 16 per unit, 0 at (270, 200): -3 + 4i at ({270 + 16 * w.real:.2f}, {200 - 16 * w.imag:.2f}), arc radius {16 * abs(w):.2f}")
assert gap < 1e-10                                             # the two roads agree everywhere
assert onto == [N * N] * 6                                     # every grid point lands, and pulls back
assert abs(chain1 - complex(num[0], num[1]) / den) < 1e-12     # floating chain against whole numbers
assert abs(centre) < 1e-12                                     # the corridor's midline centre goes to 0
print("ALL CHECKS PASS")
