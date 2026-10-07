# Complex vectors and matrices -- the check behind the card.  Standard library only.
# Quarter turn R = [[0, -1], [1, 0]], v = (1, i), w = (1, -i), H = [[2, i], [-i, 2]],
# drone pair x = (3 + 4i, 1 + 2i).  Eigenvalues by the quadratic formula and by test.
import math
def fmt(z):
    re, im = z.real + 0.0, z.imag + 0.0
    return f"{re:.6f} {'-' if im < 0 else '+'} {abs(im):.6f}i"
def star(a): return [[a[j][i].conjugate() for j in range(2)] for i in range(2)]   # conjugate transpose
def mv(a, x): return [a[0][0] * x[0] + a[0][1] * x[1], a[1][0] * x[0] + a[1][1] * x[1]]
def mm(a, b): return [[a[i][0] * b[0][j] + a[i][1] * b[1][j] for j in range(2)] for i in range(2)]
def dot_t(x, y): return x[0] * y[0] + x[1] * y[1]                               # transpose: no flip
def dot_c(x, y): return x[0].conjugate() * y[0] + x[1].conjugate() * y[1]       # x* y
def same(a, b): return max(abs(a[i][j] - b[i][j]) for i in range(2) for j in range(2)) < 1e-12
def pair(x): return f"({fmt(x[0])}, {fmt(x[1])})"
def csqrt(z):                                   # square root of a complex number, from its modulus
    r = abs(z)
    return complex(math.sqrt((r + z.real) / 2), math.copysign(math.sqrt((r - z.real) / 2), z.imag))
def eig(a):                                     # road one: roots of t^2 - trace t + det = 0
    tr, det = a[0][0] + a[1][1], a[0][0] * a[1][1] - a[0][1] * a[1][0]
    s = csqrt(tr * tr - 4 * det)
    return tr, det, tr * tr - 4 * det, [(tr + s) / 2, (tr - s) / 2]

I2 = [[1 + 0j, 0j], [0j, 1 + 0j]]
R, H, S = [[0j, -1 + 0j], [1 + 0j, 0j]], [[2 + 0j, 1j], [-1j, 2 + 0j]], [[0j, 1j], [1j, 0j]]
v, w, x = [1 + 0j, 1j], [1 + 0j, -1j], [3 + 4j, 1 + 2j]
trR, detR, discR, lamR = eig(R)
R4 = mm(mm(R, R), mm(R, R))                     # road two: four quarter turns are no turn, so lam^4 = 1
passes = [l for l in (1, 1j, -1, -1j) if max(abs(p - l * q) for p, q in zip(mv(R, [1, -l]), [1, -l])) < 1e-12]
trH, detH, discH, lamH = eig(H)
viaR = [2 - 1j * l for l in lamR]               # H = 2I - iR, so H's eigenvalues are 2 - i lam
ray = [dot_c(u, mv(H, u)) / dot_c(u, u) for u in (w, v)]
Rw, Rx = mv(R, w), mv(R, x)
sq4 = sum(c * c for z in v for c in (z.real, z.imag))
px = lambda o, z: f"({o + 60 * z.real:.0f}, {120 - 60 * z.imag:.0f})"
print(f"figure, 60 px per unit; left origin (90, 120): w1 {px(90, w[0])}, (Rw)1 {px(90, Rw[0])}; right origin (270, 120): w2 {px(270, w[1])}, (Rw)2 {px(270, Rw[1])}")
print(f"v = (1, i): v^T v = {fmt(dot_t(v, v))}; v* v = {fmt(dot_c(v, v))}; four real squares = {sq4:.6f}")
print(f"R: trace {fmt(trR)}, determinant {fmt(detR)}, discriminant {fmt(discR)}")
print(f"eigenvalues of R, quadratic formula: {fmt(lamR[0])} and {fmt(lamR[1])}")
print(f"R four times = I: {'yes' if same(R4, I2) else 'no'}; fourth roots passing R(1, -lam) = lam(1, -lam): {', '.join(fmt(complex(l)) for l in passes)}")
print(f"R w = {pair(Rw)}; i w = {pair([1j * c for c in w])}")
print(f"R v = {pair(mv(R, v))}; -i v = {pair([-1j * c for c in v])}")
print(f"w* v = {fmt(dot_c(w, v))}; w^T v = {fmt(dot_t(w, v))}")
print(f"H* = H: {'yes' if same(star(H), H) else 'no'}; H = 2I - iR: {'yes' if same(H, [[2 * I2[i][j] - 1j * R[i][j] for j in range(2)] for i in range(2)]) else 'no'}")
print(f"H: trace {fmt(trH)}, determinant {fmt(detH)}, discriminant {fmt(discH)}")
print(f"eigenvalues of H, quadratic formula: {fmt(lamH[0])} and {fmt(lamH[1])}")
print(f"eigenvalues of H as 2 - i lam: {fmt(viaR[0])} and {fmt(viaR[1])}; w* H w / w* w = {fmt(ray[0])}; v* H v / v* v = {fmt(ray[1])}")
print(f"R* R = I: {'yes' if same(mm(star(R), R), I2) else 'no'}; R* = R: {'yes' if same(star(R), R) else 'no'}")
print(f"drone pair x = {pair(x)}: x* x = {dot_c(x, x).real:.6f}, |x| = {math.sqrt(dot_c(x, x).real):.6f}; R x = {pair(Rx)}, |R x| = {math.sqrt(dot_c(Rx, Rx).real):.6f}")
print(f"mistake 1, transpose for the length of v: {fmt(dot_t(v, v))}, not {fmt(dot_c(v, v))}")
print(f"mistake 2, transpose for perpendicular: w^T v = {fmt(dot_t(w, v))}, not {fmt(dot_c(w, v))}")
print(f"mistake 3, S = [[0, i], [i, 0]] with S^T = S: S* = S {'yes' if same(star(S), S) else 'no'}; eigenvalues {fmt(eig(S)[3][0])} and {fmt(eig(S)[3][1])}")
print(f"mistake 4, a real eigenvalue for R: det(R - tI) over t from -3 to 3 never drops below {min(eig([[R[0][0] - t / 1000, R[0][1]], [R[1][0], R[1][1] - t / 1000]])[1].real for t in range(-3000, 3001)):.6f}")
assert sorted(passes, key=lambda z: complex(z).imag) == sorted(lamR, key=lambda z: z.imag)   # two roads to +-i
assert max(abs(a - b) for a, b in zip(lamH + lamH, viaR + ray)) < 1e-12        # three roads to 3 and 1
assert abs(dot_c(v, v) - sq4) < 1e-12                                           # length of v, two roads
assert abs(dot_c(Rx, Rx) - dot_c(x, x)) < 1e-12                                 # R keeps the drone pair's length
print("ALL CHECKS PASS")
