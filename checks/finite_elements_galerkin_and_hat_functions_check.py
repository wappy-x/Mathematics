# Finite elements: Galerkin with hat functions -- the check behind the card.  Standard library only.
# Cable on a bed of springs: -y'' + y = 0 for 0 <= x <= 1 m, y(0) = 1 cm, y(1) = 2 cm.
# Road one: the closed form y = cosh x + s sinh x.  Road two: Galerkin with hats, n elements,
# solved by the Thomas sweep.  Road three: energy identities (Ritz minimum, best fit) and the bound.
from math import cosh, sinh, cos, sin, sqrt, pi, log2, log10

S = (2 - cosh(1)) / sinh(1)                          # starting slope of the exact cable
def y(x): return cosh(x) + S * sinh(x)
def dy(x): return sinh(x) + S * cosh(x)
def sci(x, d=3):                                     # 8.067e-4, the same in Rust
    m, e = f"{x:.{d}e}".split("e")
    return f"{m}e{int(e)}"
def row(v, d=6): return ", ".join(f"{x:.{d}f}" for x in v)
def thomas(a, b, c, r):                              # sub-, main and super-diagonal, right side
    b, r = b[:], r[:]
    for i in range(1, len(b)):
        w = a[i] / b[i-1]; b[i] -= w * c[i-1]; r[i] -= w * r[i-1]
    u = [0.0] * len(b); u[-1] = r[-1] / b[-1]
    for i in range(len(b) - 2, -1, -1): u[i] = (r[i] - c[i] * u[i+1]) / b[i]
    return u
def galerkin(n, ks=1.0, km=1.0, lump=False, ends=True):
    # ks multiplies the y'v' part, km the y v part; lump puts all of y v on the diagonal
    h = 1.0 / n
    d = ks * 2 / h + km * (h if lump else 4 * h / 6)          # a(phi_i, phi_i)
    o = -ks / h + (0.0 if lump else km * h / 6)               # a(phi_i, phi_(i+1))
    r = [0.0] * (n - 1)
    if ends: r[0] -= o * 1.0; r[-1] -= o * 2.0                # the end hats carry 1 cm and 2 cm
    return [1.0] + thomas([o] * (n - 1), [d] * (n - 1), [o] * (n - 1), r) + [2.0], d, o, r
G3 = [(-sqrt(0.6), 5 / 9), (0.0, 8 / 9), (sqrt(0.6), 5 / 9)]   # 3-point Gauss rule on [-1, 1]
def errors(U):                                       # L2 error and energy error of the broken line U
    n = len(U) - 1; h = 1.0 / n; e2 = d2 = 0.0
    for k in range(n):
        sl = (U[k+1] - U[k]) / h
        for t, w in G3:
            x = (k + 0.5 + t / 2) * h
            e2 += w * h / 2 * (y(x) - U[k] - sl * (x - k * h)) ** 2
            d2 += w * h / 2 * (dy(x) - sl) ** 2
    return sqrt(e2), sqrt(e2 + d2)
def energy(U):                                       # a(y_h, y_h), element by element
    n = len(U) - 1; h = 1.0 / n
    return sum((U[k+1] - U[k]) ** 2 / h + h / 3 * (U[k] ** 2 + U[k] * U[k+1] + U[k+1] ** 2) for k in range(n))
def nodal(U): n = len(U) - 1; return max(abs(U[i] - y(i / n)) for i in range(n + 1))

print(f"cable: -y'' + y = 0, y(0) = 1 cm, y(1) = 2 cm; exact starting slope s = {S:.8f}")
U4, d, o, r = galerkin(4)
ex = [y(i / 4) for i in range(5)]
print(f"n = 4, h = 0.25: diagonal 2/h + 4h/6 = {d:.6f}, off-diagonal -1/h + h/6 = {o:.6f}")
print(f"right side from the end hats: {row(r)}")
print(f"Galerkin nodes: {row(U4)}")
print(f"exact nodes:    {row(ex)}")
print("nodal error, Galerkin minus exact: " + ", ".join(sci(U4[i] - ex[i]) for i in (1, 2, 3)))
F4 = galerkin(4, lump=True)[0]
print(f"lumped springs = finite differences: {row(F4)}; errors " + ", ".join(sci(F4[i] - ex[i]) for i in (1, 2, 3)))
l2, en = errors(U4)
ay = 2 * dy(1) - dy(0)                               # a(y, y) = y(1)y'(1) - y(0)y'(0)
print(f"energy: exact cable a(y,y) = {ay:.10f}, Galerkin a(y_h,y_h) = {energy(U4):.10f}")
print(f"energy error: by quadrature {sci(en, 6)}, by sqrt(a(y_h,y_h) - a(y,y)) {sci(sqrt(energy(U4) - ay), 6)}")
I4 = ex[:]
print(f"energy error of the broken line through the exact nodes: {sci(errors(I4)[1], 6)} (Galerkin {sci(en, 6)})")
t = 0.01; P = U4[:]; P[2] += t
print(f"Ritz: nudge node 2 by 0.01 cm, energy/2 rises {sci((energy(P) - energy(U4)) / 2)}; t^2 d/2 = {sci(t * t * d / 2)}")
Y2 = 0.5 + sinh(2) / 4 + S * sinh(1) ** 2 + S * S * (sinh(2) / 4 - 0.5)   # integral of y^2 = y''^2
print(f"||y''|| = ||y|| = {sqrt(Y2):.6f} (closed form), {errors([0.0] * 65)[0]:.6f} (quadrature)")
NS = [4, 8, 16, 32, 64, 128, 256, 512, 1024]
tab = []
print("n, nodal max error, L2 error, energy error, energy bound, bound / energy error")
for n in NS:
    U = galerkin(n)[0]; l2n, enn = errors(U); h = 1.0 / n
    b = h / pi * sqrt(1 + (h / pi) ** 2) * sqrt(Y2)
    tab.append((nodal(U), l2n, enn, b))
    print(f"  {n:4d}  {sci(nodal(U))}  {sci(l2n)}  {sci(enn)}  {sci(b)}  {b / enn:.3f}")
for j, name in enumerate(("nodal", "L2", "energy")):
    print(f"observed order, {name}: " + ", ".join(f"{log2(tab[i][j] / tab[i+1][j]):.2f}" for i in range(4)))
print("chart x, log10 h: " + ", ".join(f"{log10(1 / n):.2f}" for n in NS))
for j, name in enumerate(("nodal", "L2", "energy")):
    print(f"chart, log10 error, {name}: " + ", ".join(f"{log10(v[j]):.2f}" for v in tab))
fl = [nodal(galerkin(n)[0]) for n in (4096, 16384, 65536)]
print("rounding, nodal max error at n = 4096, 16384, 65536: " + ", ".join(sci(e, 1) for e in fl))
print(f"cost at n = 4: 3 unknowns, Thomas sweep 8(n-1) - 7 = {8 * 3 - 7} flops; at n = 1024: {8 * 1023 - 7} flops")
m1, m2, m3, m4 = galerkin(4, ks=0.0)[0], galerkin(4, km=0.0)[0], galerkin(4, ks=-1.0)[0], galerkin(4, ends=False)[0]
print(f"mistake 1, no integration by parts (only y v survives): {row(m1[1:4], 4)}")
print(f"mistake 2, springs dropped: {row(m2[1:4], 4)}")
print(f"mistake 3, sign slip, -y'v' + y v: {row(m3[1:4], 4)}")
print(f"mistake 4, end hats left out of the right side: {row(m4[1:4], 4)}")
w = sqrt(10); B = (2 - cos(w)) / sin(w)              # -y'' - 10 y = 0: springs push out
print(f"push-out springs, -y'' - 10 y = 0: middle, n = 4: {galerkin(4, km=-10.0)[0][2]:.4f}, "
      f"n = 64: {galerkin(64, km=-10.0)[0][32]:.4f}, exact {cos(w / 2) + B * sin(w / 2):.4f}")
A = [(U4[i] + F4[i]) / 2 - ex[i] for i in (1, 2, 3)]
print("try, average of Galerkin and finite differences, errors: " + ", ".join(sci(a) for a in A))
print(f"try, n = 8 middle node {galerkin(8)[0][4]:.6f}, exact {y(0.5):.6f}")
px = lambda x, v: f"({40 + 280 * x:.1f}, {125 - 100 * (v - 1):.1f})"
print("figure, Galerkin nodes px: " + " ".join(px(i / 4, U4[i]) for i in range(5)))
print("figure, exact curve px: " + " ".join(px(i / 8, y(i / 8)) for i in range(9)))
print("figure, hats: base y = 220.0, peaks " + " ".join(f"({40 + 70 * i:.1f}, 175.0)" for i in range(5)))

assert all(abs(U4[i] - ex[i]) < 1e-3 for i in range(5))              # Galerkin near the closed form
assert abs(en - sqrt(energy(U4) - ay)) < 1e-6                         # Gauss rule = energy identity
assert en < errors(I4)[1]                                             # best fit in energy beats the interpolant
assert abs((energy(P) - energy(U4)) / 2 - t * t * d / 2) < 1e-12      # Ritz: the nodes sit at the minimum
assert abs(sqrt(Y2) - errors([0.0] * 65)[0]) < 1e-9                   # closed-form norm = quadrature
assert all(e < b for _, _, e, b in tab)                               # the energy bound holds
assert all(1.95 < log2(tab[i][0] / tab[i+1][0]) < 2.05 for i in range(4))   # nodal order 2
assert all(0.98 < log2(tab[i][2] / tab[i+1][2]) < 1.02 for i in range(4))   # energy order 1
assert all(abs(A[k]) < abs(U4[k+1] - ex[k+1]) / 50 for k in range(3))        # the two h^2 terms cancel
assert fl[2] > fl[1]                                                  # rounding stops the fall
print("ALL CHECKS PASS")
