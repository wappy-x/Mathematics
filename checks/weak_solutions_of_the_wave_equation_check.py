# Weak waves on a 65 cm guitar string plucked 4 mm at 16 cm from the bridge.
# Roads: d'Alembert with mirror images; Galerkin sine sums with N = 10, 40, 160 modes;
# energy by closed form, by mode sums and by quadrature; the L2 gap by quadrature and
# by the tail series; the weak form's residual by centred differences in time.
from math import pi, sin, cos, sqrt, exp, log

L, F1 = 0.65, 329.63                   # string length, m; open high E string, Hz
C = 2 * L * F1                         # wave speed, m/s
RHO = 7850 * pi * 0.000127 ** 2        # mass per metre, kg/m: steel wire 0.254 mm across
TEN = RHO * C * C                      # tension, N
A, H, T1 = 0.16, 0.004, 1e-3           # pluck point, m; pluck height, m; time watched, s
KAPPA = 1.110e-4                       # copper's diffusivity, m^2/s, for the heat contrast
NS = (10, 40, 160)

def f(x): return H * x / A if x <= A else H * (L - x) / (L - A)
def df(x): return H / A if x < A else -H / (L - A)
def wrap(s): return (s + L) % (2 * L) - L          # odd mirror images about both ends
def big_f(s): s = wrap(s); return f(s) if s >= 0 else -f(-s)
def big_df(s): return df(abs(wrap(s)))
def u(x, t): return (big_f(x - C * t) + big_f(x + C * t)) / 2
def ux(x, t): return (big_df(x - C * t) + big_df(x + C * t)) / 2
def ut(x, t): return C * (big_df(x + C * t) - big_df(x - C * t)) / 2
def kinks(t, lo=0.0, hi=L):            # where the corners are: x -/+ c t = +/- A + 2 L m
    pts = {lo, hi}
    for s in (A, -A):
        for m in range(-3, 4):
            for x in (s + C * t + 2 * L * m, s - C * t + 2 * L * m):
                if lo < x < hi: pts.add(x)
    return sorted(pts)
def simpson(g, a, b, n):                # ends nudged inward, so a corner is seen from inside
    h, e = (b - a) / n, (b - a) * 1e-12
    return h / 3 * sum((1 if i in (0, n) else 4 if i % 2 else 2) * g(min(max(a + i * h, a + e), b - e))
                       for i in range(n + 1))
def pieces(g, t, n=2000, lo=0.0, hi=L):            # Simpson on each corner-free piece
    p = kinks(t, lo, hi)
    return sum(simpson(g, p[i], p[i + 1], n) for i in range(len(p) - 1))

def kk(k): return k * pi / L
def om(k): return C * kk(k)
def b_closed(k): return 2 * H * L * L * sin(kk(k) * A) / (k * k * pi * pi * A * (L - A))
B = [0.0] + [b_closed(k) for k in range(1, 100001)]
def mode_e(k): return TEN * L / 4 * kk(k) ** 2 * B[k] ** 2   # each mode's energy, J, forever
def galerkin(x, t, n):                 # u_N, its slope and its speed
    s = sx = st = 0.0
    for k in range(1, n + 1):
        ck, sk = cos(om(k) * t), sin(om(k) * t)
        s += B[k] * ck * sin(kk(k) * x); sx += B[k] * ck * kk(k) * cos(kk(k) * x)
        st -= B[k] * om(k) * sk * sin(kk(k) * x)
    return s, sx, st
def trap_energy(n, t, m=1000):         # trapezoid rule: exact for these sine products
    tot = 0.0
    for i in range(m + 1):
        _, sx, st = galerkin(i * L / m, t, n)
        tot += (0.5 if i in (0, m) else 1) * (RHO / 2 * st * st + TEN / 2 * sx * sx)
    return tot * L / m

print(f"string: c = {C:.3f} m/s, rho = {RHO * 1e3:.4f} g/m, tension = {TEN:.2f} N")
E0 = TEN / 2 * H * H * (1 / A + 1 / (L - A))
print(f"pluck: slopes {H / A:.6f} and {-H / (L - A):.6f}; energy (T/2) H^2 (1/a + 1/(L - a)) = {E0 * 1e3:.6f} mJ")
for k in (1, 2, 3):
    bq = 2 / L * (simpson(lambda x: f(x) * sin(kk(k) * x), 0, A, 2000) + simpson(lambda x: f(x) * sin(kk(k) * x), A, L, 2000))
    print(f"b_{k}: closed form {B[k] * 1e3:.9f} mm, Simpson projection {bq * 1e3:.9f} mm")
print(f"corners at 1 ms: " + ", ".join(f"{x * 100:.2f} cm" for x in kinks(T1)[1:-1]))
print(" N | energy kept mJ | at 0 ms by quadrature | at 0.5 ms | at 1 ms | missing mJ")
EN, CONS = {}, []
for n in NS:
    EN[n] = sum(mode_e(k) for k in range(1, n + 1))
    q = [trap_energy(n, t) for t in (0.0, T1 / 2, T1)]
    CONS.append(max(abs(e - EN[n]) for e in q) / EN[n])
    print(f"{n:3d} | {EN[n] * 1e3:.10f} | {q[0] * 1e3:.10f} | {q[1] * 1e3:.10f} | {q[2] * 1e3:.10f} | {(E0 - EN[n]) * 1e3:.6f}")
EALL = sum(mode_e(k) for k in range(1, 100001))
TAIL = TEN * L / 4 * (pi / L) ** 2 * (2 * H * L * L / (pi * pi * A * (L - A))) ** 2 / 100000
print(f"modes 1 to 100000 carry {EALL * 1e3:.6f} mJ; the rest at most {TAIL * 1e6:.4f} uJ")
print(f"first omitted energy terms, modes 11, 41, 161: " + ", ".join(f"{mode_e(n + 1) * 1e6:.4f}" for n in NS) + " uJ")
print(" N | RMS gap at 1 ms, quadrature um | by tail series um | difference energy at 1 ms mJ")
GQ, GT, DE = [], [], []
for n in NS:
    gq = pieces(lambda x: (galerkin(x, T1, n)[0] - u(x, T1)) ** 2, T1)
    gt = L / 2 * sum(B[k] ** 2 * cos(om(k) * T1) ** 2 for k in range(n + 1, 100001))
    de = pieces(lambda x: (lambda g: RHO / 2 * (g[2] - ut(x, T1)) ** 2 + TEN / 2 * (g[1] - ux(x, T1)) ** 2)(galerkin(x, T1, n)), T1)
    GQ.append(sqrt(gq / L)); GT.append(sqrt(gt / L)); DE.append(de)
    print(f"{n:3d} | {GQ[-1] * 1e6:.6f} | {GT[-1] * 1e6:.6f} | {de * 1e3:.6f}")
ORD = [log(GQ[i] / GQ[i + 1]) / log(4) for i in (0, 1)]
ORE = [log(DE[i] / DE[i + 1]) / log(4) / 2 for i in (0, 1)]
print(f"observed order in N: L2 gap {ORD[0]:.3f}, {ORD[1]:.3f}; energy-norm gap {ORE[0]:.3f}, {ORE[1]:.3f}")
V = lambda x: sin(pi * (x - 0.20) / 0.20) ** 2     # test shape on 20 cm to 40 cm
VX = lambda x: pi / 0.20 * sin(2 * pi * (x - 0.20) / 0.20)
mom = lambda t: pieces(lambda x: u(x, t) * V(x), t, 400, 0.20, 0.40)
stiff = C * C * pieces(lambda x: ux(x, T1) * VX(x), T1, 400, 0.20, 0.40)
RES = []
for d in (2e-5, 1e-5):
    acc = (mom(T1 + d) - 2 * mom(T1) + mom(T1 - d)) / (d * d)
    RES.append(abs(acc + stiff) / abs(stiff))
    print(f"weak form at 1 ms, step {d * 1e3:.2f} ms: (u, v)'' = {acc:.4f} m^2/s^2, -c^2 (u_x, v_x) = {-stiff:.4f} m^2/s^2, "
          f"residual {RES[-1] * 100:.4f}%")
XF, TF = 0.50, 0.5e-3
VEL = [galerkin(XF, TF, n)[2] for n in NS]
print(f"finite speed: corner reaches 50 cm at {(XF - A) / C * 1e3:.4f} ms; at 0.5 ms d'Alembert u = {u(XF, TF) * 1e3:.6f} mm, "
      f"u_t = {ut(XF, TF):.6f} m/s")
print("  Galerkin u_t there, N = 10, 40, 160: " + ", ".join(f"{v:.6f}" for v in VEL) + " m/s")
BW0 = [L / 2 * sum(kk(k) ** 4 * B[k] ** 2 for k in range(1, n + 1)) for n in NS]
BW1 = [L / 2 * sum(kk(k) ** 4 * B[k] ** 2 * cos(om(k) * T1) ** 2 for k in range(1, n + 1)) for n in NS]
BH = [L / 2 * sum(kk(k) ** 4 * B[k] ** 2 * exp(-2 * KAPPA * kk(k) ** 2 * 1.0) for k in range(1, n + 1)) for n in NS]
print("bending integral of u_N_xx^2, 1/m, N = 10, 40, 160: wave at 0 ms " + ", ".join(f"{b:.6f}" for b in BW0)
      + "; wave at 1 ms " + ", ".join(f"{b:.6f}" for b in BW1) + "; heat in copper after 1 s " + ", ".join(f"{b:.6f}" for b in BH))
SH = 0.5 * TEN * L / 2
JE = [sum(SH * kk(k) ** 2 * (2 * H / (k * pi) * (1 - cos(kk(k) * A))) ** 2 for k in range(1, n + 1)) for n in NS]
print("wrong: a 4 mm plateau from the bridge to 16 cm (not in H1_0), energy of N = 10, 40, 160: " + ", ".join(f"{e:.4f}" for e in JE) + " J")
print(f"wrong: expect order 2, gap at N = 160 would be {GQ[0] * 1e6 / 256:.6f} um, not {GQ[2] * 1e6:.6f} um")
XS = [0.05 * i for i in range(14)]
print("chart, cm: " + ", ".join(f"{x * 100:.0f}" for x in XS))
print("chart, d'Alembert at 1 ms, mm: " + ", ".join(f"{u(x, T1) * 1e3:.3f}" for x in XS))
print("chart, Galerkin N = 10 at 1 ms, mm: " + ", ".join(f"{galerkin(x, T1, 10)[0] * 1e3:.3f}" for x in XS))
assert all(abs(b_closed(k) - 2 / L * simpson(lambda x: f(x) * sin(kk(k) * x), 0, A, 2000)
           - 2 / L * simpson(lambda x: f(x) * sin(kk(k) * x), A, L, 2000)) < 1e-9 * H for k in (1, 2, 3)), "projection"
assert max(CONS) < 1e-12, "each Galerkin sum must keep its energy to rounding"
assert 0 < E0 - EALL < TAIL, "modes must carry the pluck's energy"
assert all(abs(q - t) < 1e-4 * t for q, t in zip(GQ, GT)), "L2 gap: quadrature against tail series"
assert all(abs(d - (E0 - EN[n])) < 1e-4 * (E0 - EN[n]) for d, n in zip(DE, NS)), "difference keeps its starting energy"
assert all(1.4 < o < 1.6 for o in ORD) and all(0.4 < o < 0.6 for o in ORE), "observed orders 1.5 and 0.5"
assert RES[1] < 1e-3 and 3.5 < RES[0] / RES[1] < 4.5, "weak-form residual must fall as step^2"
assert abs(ut(XF, TF)) < 1e-15 and abs(VEL[2]) < abs(VEL[0]), "the limit is still before the corner arrives"
assert BW0[2] > 3 * BW0[1] > 9 * BW0[0] and BH[2] < 1.01 * BH[1], "the wave never smooths; heat does"
assert JE[2] > 3 * JE[1] > 9 * JE[0], "a jump has no finite energy"
print("ALL CHECKS PASS")
