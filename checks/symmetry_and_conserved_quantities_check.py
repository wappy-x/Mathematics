# Symmetry and conservation -- the check behind the card.  Standard library only.
# An electron spin in a 0.34 T ESR magnet, followed four independent ways:
# Road 1: the classical spin, moved by its Poisson bracket with H, stepped by RK4.
# Road 2: the quantum spin, Schrodinger's equation on two complex amplitudes, RK4.
# Road 3: the closed form, a cone swept at w = gamma B.
# Road 4: Noether's test: turn the spin a little and see whether H notices.
from math import sin, cos, pi, radians, sqrt
H_PL = 6.62607015e-34         # J s, exact
HBAR = H_PL / (2*pi)          # J s, h / 2 pi
GAMMA = 1.76085962784e11      # electron gyromagnetic ratio, rad/(s T), CODATA 2022
MU_B = 9.2740100657e-24       # Bohr magneton, J/T, CODATA 2022
M_E, EV = 9.1093837139e-31, 1.602176634e-19   # kg; J per eV
B0, TILT, DT = 0.34, radians(60), 1e-13       # T; spin starts 60 deg from the field; 0.1 ps step

def cross(a, b): return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])
def sci(x): m, e = ("%.1e" % x).split("e"); return "%se%d" % (m, int(e))   # 1.2e-12
def dot(a, b): return a[0]*b[0] + a[1]*b[1] + a[2]*b[2]
def bracket_rate(s, B):       # dS/dt = {S, H} with H = gamma B.S and {Sx, Sy} = Sz: gamma B x S
    return tuple(GAMMA * c for c in cross(B, s))
def rk4(f, y, h):
    k1 = f(y); k2 = f([a + h/2*b for a, b in zip(y, k1)])
    k3 = f([a + h/2*b for a, b in zip(y, k2)]); k4 = f([a + h*b for a, b in zip(y, k3)])
    return [a + h/6*(b + 2*c + 2*d + e) for a, b, c, d, e in zip(y, k1, k2, k3, k4)]
def classical(Bt, n):         # spin in units of hbar; Bt(t) gives the field; returns the path
    s, path = [0.5*sin(TILT), 0.0, 0.5*cos(TILT)], []
    for k in range(n + 1):
        path.append(s)
        s = rk4(lambda y: bracket_rate(y, Bt(k*DT)), s, DT)   # field held over one step
    return path
def quantum(B, n):            # i hbar dpsi/dt = H psi, H = gamma B.(hbar/2 sigma); <S> in hbar
    def f(p):                 # d(psi)/dt = -i gamma/2 (B.sigma) psi
        a, b = p
        return [-0.5j*GAMMA*(B[2]*a + (B[0]-1j*B[1])*b), -0.5j*GAMMA*((B[0]+1j*B[1])*a - B[2]*b)]
    p = [complex(cos(TILT/2)), complex(sin(TILT/2))]
    for _ in range(n): p = rk4(f, p, DT)
    a, b = p
    return ((a.conjugate()*b).real, (a.conjugate()*b).imag, 0.5*(abs(a)**2 - abs(b)**2))

Bz = (0.0, 0.0, B0)
w = GAMMA * B0; f_formula = w / (2*pi)
path = classical(lambda t: Bz, 10000)                     # 1 ns
up = [k*DT - path[k][1]*DT/(path[k+1][1]-path[k][1]) for k in range(10000)
      if path[k][1] < 0 <= path[k+1][1]]                  # Sy crossing zero upward
f_sim = (len(up) - 1) / (up[-1] - up[0])
sq = quantum(Bz, 10000)
sx_exact = 0.5*sin(TILT)*cos(w*1e-9)
sz_drift = max(abs(s[2] - path[0][2]) for s in path)
H0 = GAMMA*dot(Bz, path[0])*HBAR
size_drift = max(abs(sqrt(dot(s, s)) - 0.5) for s in path)

print("ESR magnet %.2f T, spin starts 60 deg from the field" % B0)
print("w = gamma B = %.5f x 10^10 rad/s" % (w/1e10))
print("f closed form       %.4f GHz" % (f_formula/1e9))
print("f from the bracket  %.4f GHz  (zero crossings, 1 ns of RK4)" % (f_sim/1e9))
print("period %.5f ns; level splitting hbar w = %.2f ueV" % (1e9/f_formula, HBAR*w/EV*1e6))
print("energy H = gamma B Sz = %.3f ueV, Sz = %.4f hbar" % (H0/EV*1e6, path[0][2]))
print("1 ns:  Sx classical %.6f  quantum %.6f  closed form %.6f hbar" % (path[-1][0], sq[0], sx_exact))
print("1 ns:  Sz classical %.6f  quantum %.6f hbar" % (path[-1][2], sq[2]))
print("largest drift over 1 ns: Sz %s, |S| %s hbar" % (sci(sz_drift), sci(size_drift)))
print("chart t (ns):  " + " ".join("%.2f" % (k/100) for k in range(11)))
for i, name in enumerate(("Sx", "Sy", "Sz")):
    print("chart %s (hbar): " % name + " ".join("%.3f" % (path[100*k][i] + 0.0) for k in range(11)))

# Road 4: Noether's test, and the bracket that measures it
eps, s0 = 1e-6, path[200]     # the spin at t = 0.02 ns
def turn(s, axis, a):         # rotate s by angle a about a unit axis (Rodrigues)
    c = cross(axis, s); d = dot(axis, s)
    return tuple(s[i]*cos(a) + c[i]*sin(a) + axis[i]*d*(1 - cos(a)) for i in range(3))
for name, ax in (("z", (0, 0, 1)), ("x", (1, 0, 0))):
    dH = (dot(Bz, turn(s0, ax, eps)) - dot(Bz, turn(s0, ax, -eps))) / (2*eps) * GAMMA
    rate = bracket_rate(s0, Bz)["xyz".index(name)]        # dS/dt = {S, H}, from the bracket
    print("turn about %s: dH/dangle = %.4f ueV/rad;  -hbar {S%s, H} = %.4f ueV" % (
        name, dH*HBAR/EV*1e6 + 0.0, name, -rate*HBAR/EV*1e6 + 0.0))
    assert abs(dH + rate) < 1e-6 * w
# quantum: commutators of 2 x 2 matrices, hbar = 1
def mm(A, C): return [[sum(A[i][k]*C[k][j] for k in range(2)) for j in range(2)] for i in range(2)]
def comm(A, C): return [[x - y for x, y in zip(r, q)] for r, q in zip(mm(A, C), mm(C, A))]
Sx, Sy, Sz = [[0, .5], [.5, 0]], [[0, -.5j], [.5j, 0]], [[.5, 0], [0, -.5]]
Hm = [[GAMMA*B0*x for x in r] for r in Sz]
big = lambda M: max(abs(x) for r in M for x in r)
minus = lambda A, C, z: [[a - z*b for a, b in zip(r, q)] for r, q in zip(A, C)]
c_xy, c_zh, c_xh = big(minus(comm(Sx, Sy), Sz, 1j)), big(comm(Sz, Hm)), comm(Sx, Hm)
c_rule = big(minus(c_xh, Sy, -1j*w))     # Dirac: [Sx, H] = i hbar {Sx, H} = i hbar (-w Sy)
print("[Sx,Sy] - i Sz: %s;  [Sz,H]: %s;  [Sx,H] - i(-w Sy): %s;  |[Sx,H]|: %.4f x 10^10 /s" % (
    sci(c_xy), sci(c_zh), sci(c_rule), big(c_xh)/1e10))

# what breaks: tilt the field, ramp the field, f mixed with w, g taken as exactly 2
FTILT = 10                    # field tilt from z, degrees (the check below holds up to 30)
Bt = (B0*sin(radians(FTILT)), 0.0, B0*cos(radians(FTILT)))
tp = classical(lambda t: Bt, 10000)
along_drift = max(abs(dot(s, Bt) - dot(tp[0], Bt)) for s in tp) / B0
ramp = lambda t: (0.0, 0.0, B0 + 0.02*t/1e-9)   # 0.34 -> 0.36 T over 1 ns
rp = classical(ramp, 10000)
E_end = GAMMA*dot(ramp(1e-9), rp[-1])*HBAR
f_g2 = 2*MU_B*B0/H_PL
print("field tilted %d deg: Sz swings %.4f to %.4f hbar; S along B drifts %s" % (
    FTILT, min(s[2] for s in tp), max(s[2] for s in tp), sci(along_drift)))
print("field ramped 0.34 -> 0.36 T in 1 ns: H %.3f -> %.3f ueV, Sz %.4f -> %.4f hbar" % (
    H0/EV*1e6, E_end/EV*1e6, rp[0][2], rp[-1][2]))
print("w read as hertz: %.4f GHz;  g = 2 exactly: %.4f GHz (off by %.1f MHz)" % (
    w/1e9, f_g2/1e9, (f_formula - f_g2)/1e6))

# the house example: an electron in a 1 nm box (time shift kept, space shift broken)
L = 1e-9; E1 = H_PL**2/(8*M_E*L**2); p1 = H_PL/(2*L); v1 = p1/M_E
print("1 nm box: E1 = %.4f eV, |p| = %.4e kg m/s, v = %.0f m/s, wall to wall %.3f fs" % (
    E1/EV, p1, v1, L/v1*1e15))
print("1 nm box: each bounce hands the walls 2|p| = %.4e kg m/s, given back at the other wall" % (2*p1))

assert abs(f_sim/f_formula - 1) < 1e-6                     # road 1 against road 3
assert abs(sq[0] - path[-1][0]) < 1e-6 and abs(sq[0] - sx_exact) < 1e-6   # road 2 against 1 and 3
assert abs(sq[1] - path[-1][1]) < 1e-6 and abs(sq[2] - path[-1][2]) < 1e-6
assert sz_drift < 1e-9 and size_drift < 1e-9               # rotation about the field: Sz kept
assert abs(max(s[2] for s in tp) - 0.5*cos(TILT - 2*radians(FTILT))) < 1e-4 and along_drift < 1e-9
assert abs(E_end/H0 - (B0 + 0.02)/B0) < 1e-9 and abs(rp[-1][2] - rp[0][2]) < 1e-9
assert c_zh == 0 and big(c_xh) > 0.1*w and c_rule < 1e-6*w   # Sz kept, Sx not
assert c_xy < 1e-15                                        # the spin algebra itself
assert abs(E1/EV - 0.376) < 5e-4 and abs(f_formula/1e9 - 9.5285) < 1e-4
print("ALL CHECKS PASS")
