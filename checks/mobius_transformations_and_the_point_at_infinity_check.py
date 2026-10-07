# Mobius transformations -- the check behind the card.  Standard library only.
# A map (az + b)/(cz + d) is kept as its matrix (a, b, c, d); a point is a pair (s, t)
# standing for s/t, so infinity is (1, 0).  Road 1 works point by point with the
# fraction; road 2 works on matrices and circle equations.
M, INF = (1, -1j, 1, 1j), (1, 0)                 # the Cayley map (z - i)/(z + i)
def mul(A, B): return (A[0]*B[0] + A[1]*B[2], A[0]*B[1] + A[1]*B[3], A[2]*B[0] + A[3]*B[2], A[2]*B[1] + A[3]*B[3])
def adj(A): return (A[3], -A[1], -A[2], A[0])    # undoes A, up to a scale
def act(A, p): return (A[0]*p[0] + A[1]*p[1], A[2]*p[0] + A[3]*p[1])
def pt(p): return None if p[1] == 0 else p[0] / p[1]      # None is infinity
def frac(A, z):                                  # road 1: the fraction and its two rules
    if z is None: return A[0] / A[2] if A[2] != 0 else None
    return None if A[2]*z + A[3] == 0 else (A[0]*z + A[1]) / (A[2]*z + A[3])
def r6(x): return f"{round(x, 6) + 0.0:.6f}"
def show(w): return "infinity" if w is None else f"{r6(w.real)} {'-' if round(w.imag, 6) < 0 else '+'} {abs(round(w.imag, 6)):.6f}i"
def to_0_1_inf(p1, p2, p3):                      # cross-ratio map: p1, p2, p3 to 0, 1, infinity
    k1, k3 = p3[1]*p2[0] - p3[0]*p2[1], p1[1]*p2[0] - p1[0]*p2[1]
    return (k1*p1[1], -k1*p1[0], k3*p3[1], -k3*p3[0])
def carry(H, A):          # road 2: alpha|z|^2 + 2Re(beta z) + gamma = 0, pushed through A
    al, be, ga = H; N = adj(A); n1, n2 = (N[0], N[2]), (N[1], N[3])
    q = lambda u, v: u[0].conjugate()*(al*v[0] + be.conjugate()*v[1]) + u[1].conjugate()*(be*v[0] + ga*v[1])
    return q(n1, n1).real, q(n2, n1), q(n2, n2).real
def through3(a, b, c):                           # road 1: the circle through three image points
    num = abs(a)**2*(b - c) + abs(b)**2*(c - a) + abs(c)**2*(a - b)
    cen = num / (a.conjugate()*(b - c) + b.conjugate()*(c - a) + c.conjugate()*(a - b)); return cen, abs(a - cen)
v = {n: frac(M, z) for n, z in [("i", 1j), ("0", 0j), ("infinity", None), ("-i", -1j), ("1", 1+0j), ("-1", -1+0j), ("2i", 2j), ("1 + i", 1+1j)]}
print(f"Cayley matrix (1, -i, 1, i), ad - bc = {show(M[0]*M[3] - M[1]*M[2])}")
print(", ".join(f"C({n}) = {show(w)}" for n, w in list(v.items())[:4]))
print(", ".join(f"C({n}) = {show(w)}" for n, w in list(v.items())[4:]))
twice, M2, M3 = frac(M, v["2i"]), mul(M, M), mul(M, mul(M, M))
print(f"C twice at 2i: by the fraction {show(twice)}; by the matrix product {show(pt(act(M2, (2j, 1))))}")
print(f"matrix cubed: ({', '.join(show(x) for x in M3)}); C three times at 2i: {show(frac(M, twice))}")
back = frac(adj(M), v["1 + i"])
print(f"adjugate (i, i, -1, 1) takes {show(v['1 + i'])} back to {show(back)}; matrix x adjugate diagonal {show(mul(M, adj(M))[0])}")
T = mul(adj(to_0_1_inf((0, 1), (-1, 1), (1, 1))), to_0_1_inf((1j, 1), (0, 1), INF))
print(f"map sending i, 0, infinity to 0, -1, 1 by cross-ratios, scaled to c = 1: ({', '.join(show(x / T[2]) for x in T)})")
crz, crw = pt(act(to_0_1_inf((1j, 1), (0, 1), INF), (2j, 1))), pt(act(to_0_1_inf((0, 1), (-1, 1), (1, 1)), (v["2i"], 1)))
print(f"cross-ratio of 2i against i, 0, infinity: {show(crz)}; of C(2i) against 0, -1, 1: {show(crw)}")
fits = []
for y in (0, 1):
    cen, rad = through3(*(frac(M, complex(x, y)) for x in (-2, 0, 2)))
    on = max(abs(abs(frac(M, complex(k / 4, y)) - cen) - rad) for k in range(-400, 401)) < 1e-12
    al, be, ga = carry((0, -0.5j, -y), M); cen2, rad2 = -be.conjugate() / al, (abs(be)**2 - al*ga) ** 0.5 / abs(al)
    fits.append((cen, rad, cen2, rad2, on))
    print(f"line Im z = {y}, road 1: circle through images of x = -2, 0, 2: centre {show(cen)}, radius {r6(rad)}; 801 more on it: {'yes' if on else 'no'}")
    print(f"line Im z = {y}, road 2: circle equation carried by the matrix: centre {show(cen2)}, radius {r6(rad2)}")
grid = [complex(x, k / 4) for x in range(-10, 10) for k in range(1, 21)]
gap = max(abs((1 - abs(frac(M, z))**2) - 4*z.imag / abs(z + 1j)**2) for z in grid)
print(f"at 1 + i: 1 - |C|^2 = {r6(1 - abs(v['1 + i'])**2)}, 4y/|z + i|^2 = {r6(4 / abs(1 + 2j)**2)}; {len(grid)} points above the axis all inside: {'yes' if max(abs(frac(M, z)) for z in grid) < 1 else 'no'}")
D, (al, be, ga) = (1, 2, 2, 4), carry((1, 0j, -1), M)
print(f"mistake, ad - bc = {r6((D[0]*D[3] - D[1]*D[2]).real)}: (z + 2)/(2z + 4) at 0, 1, i: {', '.join(show(frac(D, z)) for z in (0j, 1+0j, 1j))}")
print(f"mistake, circle |z| = 1 runs through the pole -i: alpha = {r6(al)}, beta = {show(be)}, gamma = {r6(ga)}: the line Re w = 0")
print(f"mistake, infinity left out: C(1000) = {show(frac(M, 1000+0j))}, still {r6(abs(frac(M, 1000+0j) - 1))} from 1, and C(-2i) = {show(frac(M, -2j))} lands outside")
L, R = lambda z: (90 + 40*z.real, 170 - 40*z.imag), lambda w: (270 + 70*w.real, 120 - 70*w.imag)
print("figure, left 40 per unit, right 70 per unit: " + ", ".join(f"{n} ({p[0]:.2f}, {p[1]:.2f})" for n, p in [("i", L(1j)), ("1 + i", L(1+1j)), ("C(0)", R(v["0"])), ("C(1 + i)", R(v["1 + i"])), ("centre", R(fits[1][0]))]) + f", radius {70*fits[1][1]:.2f}")
assert all(abs(T[j]*M[k] - T[k]*M[j]) < 1e-12 for j in range(4) for k in range(4))   # three points fix the map
assert abs(M3[1]) + abs(M3[2]) < 1e-12 and abs(M3[0] - M3[3]) < 1e-12 and abs(back - (1+1j)) < 1e-12
assert all(f[4] and abs(f[0] - f[2]) < 1e-12 and abs(f[1] - f[3]) < 1e-12 for f in fits)  # two roads, same circle
assert gap < 1e-12 and abs(al) < 1e-12 and abs(crz - crw) < 1e-12
print("ALL CHECKS PASS")
