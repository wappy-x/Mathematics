# Yang-Mills on one lattice site -- the check behind the card.  Standard library only.
# An SU(2) element is a unit quaternion (w, x, y, z).  An su(2) element F = f1 T1 + f2 T2 + f3 T3 is
# the 3-vector f, with T_k = -i sigma_k / 2: then [T_a, T_b] = T_c is the cross product, |F|^2 = -2 tr(F F) = |f|^2,
# and Re tr U = 2w.  Nothing imported knows any gauge theory.
from math import sin, cos, acos, sqrt, pi

def qmul(p, q):
    a, b, c, d = p; e, f, g, h = q
    return (a*e - b*f - c*g - d*h, a*f + b*e + c*h - d*g, a*g - b*h + c*e + d*f, a*h + b*g - c*f + d*e)
def conj(q): return (q[0], -q[1], -q[2], -q[3])
def expT(v):                           # exp(v1 T1 + v2 T2 + v3 T3) in closed form: half angle, unit axis
    n = sqrt(v[0]**2 + v[1]**2 + v[2]**2)
    if n == 0.0: return (1.0, 0.0, 0.0, 0.0)
    return (cos(n / 2), sin(n / 2) * v[0] / n, sin(n / 2) * v[1] / n, sin(n / 2) * v[2] / n)
def cross(a, b): return (a[1]*b[2] - a[2]*b[1], a[2]*b[0] - a[0]*b[2], a[0]*b[1] - a[1]*b[0])
def dot(a, b): return a[0]*b[0] + a[1]*b[1] + a[2]*b[2]
def plaquette(Ux, Uy):                 # one site, wrapped round: along x, along y, back x, back y
    return qmul(qmul(Ux, Uy), qmul(conj(Ux), conj(Uy)))
def wilson(beta, N, Up): return beta * (1.0 - 2.0 * Up[0] / N)    # beta (1 - Re tr U_p / N)
def energy(Ax, Ay, g2):                # continuum Yang-Mills density for constant fields: F_xy = [A_x, A_y]
    F = cross(Ax, Ay)
    return dot(F, F) / (2.0 * g2)
def f6(v): return f"{v:.6f}"
def vec(v): return "(" + ", ".join(f6(c) for c in v) + ")"

beta, N = 2.4, 2
g2 = 2.0 * N / beta                    # coupling squared g^2, from beta = 2N / g^2
alpha, a = 5.0, 0.1                    # field size in 1/fm, lattice spacing in fm
Ax, Ay = (alpha, 0.0, 0.0), (0.0, alpha, 0.0)
F = cross(Ax, Ay)
E = energy(Ax, Ay, g2)
print("g^2 =", f6(g2), "  A_x =", vec(Ax), "  A_y =", vec(Ay), "  per fm")
print("F_xy = [A_x, A_y] =", vec(F), "per fm^2   |F_xy| =", f6(sqrt(dot(F, F))), "  |F_xy|^2 =", f6(dot(F, F)))
print("continuum energy density |F|^2/(2 g^2) =", f6(E), "per fm^4")

# road 1: the lattice.  Links U = exp(a A), plaquette product, Wilson action, at two spacings
err, ang = [], []
for sp in (a, a / 2):
    th = sp * alpha
    Up = plaquette(expT((th, 0.0, 0.0)), expT((0.0, th, 0.0)))
    S = wilson(beta, N, Up)
    closed = 2.0 * beta * sin(th / 2)**4             # by hand: Re of the quaternion commutator is 1 - 2 sin^4
    phi = 2.0 * acos(Up[0])                          # turning angle of the plaquette
    print(f"a = {sp:.3f} fm  theta = {th:.3f}  U_p = ({f6(Up[0])}, {f6(Up[1])}, {f6(Up[2])}, {f6(Up[3])})")
    print(f"   Wilson S_p = {S:.8f}  closed form 2 beta sin^4(theta/2) = {closed:.8f}  continuum a^4 E = {sp**4 * E:.8f}")
    print(f"   S_p / a^4 = {f6(S / sp**4)} per fm^4  error {f6(E - S / sp**4)}   plaquette angle {f6(phi)} rad = {phi * 180 / pi:.4f} deg, a^2 |F| = {f6(sp * sp * sqrt(dot(F, F)))}")
    assert abs(S - closed) < 1e-12
    err.append(E - S / sp**4); ang.append(phi)
print("error ratio, a halved:", f6(err[0] / err[1]))
assert 3.8 < err[0] / err[1] < 4.1                   # second-order: halve a, quarter the error
assert abs(ang[1] - (a / 2)**2 * 25.0) < abs(ang[0] - a * a * 25.0) / 10

# road 2: gauge invariance.  A gauge change h at the site turns every link U into h U h^-1
Ux, Uy = expT((0.5, 0.0, 0.0)), expT((0.0, 0.5, 0.0))
h = expT((0.7, 0.2, -1.1))
Ux2, Uy2 = qmul(qmul(h, Ux), conj(h)), qmul(qmul(h, Uy), conj(h))
P1, P2 = plaquette(Ux, Uy), plaquette(Ux2, Uy2)
print("gauge: U_x =", vec(Ux), "->", vec(Ux2))
print("gauge: Re tr U_p =", f6(2 * P1[0]), "->", f6(2 * P2[0]), "  Wilson", f6(wilson(beta, N, P1)), "->", f6(wilson(beta, N, P2)))
assert max(abs(Ux[i] - Ux2[i]) for i in range(4)) > 0.1
assert abs(P1[0] - P2[0]) < 1e-12

# road 3: the field equations.  dE/dA_x = (1/g^2) [A_y, F_xy] = -(1/g^2) D_mu F_mu,x, against finite differences
def grads(Ax, Ay):
    F = cross(Ax, Ay)
    return [c / g2 for c in cross(Ay, F)], [c / g2 for c in cross(F, Ax)]
def numgrad(Ax, Ay, eps=1e-5):
    out = []
    for which in (0, 1):
        row = []
        for k in range(3):
            up = [list(Ax), list(Ay)]; dn = [list(Ax), list(Ay)]
            up[which][k] += eps; dn[which][k] -= eps
            row.append((energy(*up, g2) - energy(*dn, g2)) / (2 * eps))
        out.append(row)
    return out
DF = [0.0 - c for c in cross(Ay, F)]                      # D_mu F_mu,x = [A_y, F_yx] = -[A_y, F_xy]
print("D_mu F_mu,x =", vec(DF), "per fm^3  (zero for a solution)")
gx, gy = grads(Ax, Ay)
print("dE/dA_x =", vec(gx), "  dE/dA_y =", vec(gy))
B1, B2 = (0.3, -1.1, 0.8), (0.9, 0.4, -0.5)          # a lopsided field, to test every component
ga, na = grads(B1, B2), numgrad(B1, B2)
gap = max(abs(ga[i][k] - na[i][k]) for i in range(2) for k in range(3))
print("lopsided field: dE/dA_x =", vec(ga[0]), " finite differences =", vec(na[0]))
assert gap < 1e-8
step = [Ax[k] - 0.001 * gx[k] for k in range(3)]
E_down = energy(step, Ay, g2)
print("one downhill step of 0.001: energy", f6(E), "->", f6(E_down))
assert E_down < E - 0.1

# what breaks, and the special cases
Uc = expT((0.0, 0.0, 0.5))                           # commuting links: U(1) inside SU(2)
Pc = plaquette(Uc, Uc)
print("U(1): U_p =", vec(Pc[:3]), "+ ...  Wilson", f6(wilson(beta, N, Pc)), "  bracket dropped: F_xy = 0, energy", f6(0.0))
print("commuting fields A_x = (0,0,5), A_y = (0,0,3): energy", f6(energy((0, 0, 5.0), (0, 0, 3.0), g2)))
assert abs(wilson(beta, N, Pc)) < 1e-12 and energy((0, 0, 5.0), (0, 0, 3.0), g2) == 0.0
print("wrong: forgot 1/N:", f6(beta * (1 - 2 * P1[0])), "  wrong: beta = 1/g^2:", f6(0.6 * (1 - P1[0])),
      "per plaquette,", f6(0.6 * (1 - P1[0]) / a**4), "per fm^4")
print("non-compact SL(2,R), X = diag(1,-1): -2 tr(X X) =", f6(-2 * (1 + 1)))

# try changing
Ut = plaquette(expT((1.0, 0, 0)), expT((0, 1.0, 0)))
print("try: a = 0.2 fm  S_p / a^4 =", f6(wilson(beta, N, Ut) / 0.2**4), "  A_y = (3,4,0): energy", f6(energy(Ax, (3.0, 4.0, 0.0), g2)),
      "  A_y = (0,0,5): energy", f6(energy(Ax, (0, 0, 5.0), g2)))
print("figure, square side 220 px = a 0.1 fm, corners (100,60) (320,60) (320,280) (100,280)")
print("ALL CHECKS PASS")
