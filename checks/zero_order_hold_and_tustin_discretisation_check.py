# Zero-order hold and Tustin -- the check behind the card.  Standard library only.
# A thermostat's sample cup: heater power u (W) in, sensor reading y (K above room) out.
#   dx1/dt = (R u - x1)/tau1  (cup),  dx2/dt = (x1 - x2)/tau2  (sensor),  y = x2.
#   G(s) = R / ((tau1 s + 1)(tau2 s + 1)),  sampled at fs = 10 Hz, T = 0.1 s.
# ZOH by three roads: Van Loan matrix exponential; closed form; RK4 over one held sample.
# Tustin by two: substitute s = (2/T)(z-1)/(z+1); trapezoid integration of the ODE.
import cmath, math

R, tau1, tau2, P, T = 0.5, 1.0, 0.25, 10.0, 0.1   # K/W, s, s, W step, s
p1, p2 = 1 / tau1, 1 / tau2                       # pole speeds, 1/s
A = [[-p1, 0.0], [p2, -p2]]; B = [R * p1, 0.0]

def mm(X, Y): return [[sum(X[i][k] * Y[k][j] for k in range(len(Y))) for j in range(len(Y[0]))] for i in range(len(X))]
def expm(M):                                      # scaling and squaring, then Taylor
    n, sq = len(M), 0
    while max(sum(abs(v) for v in r) for r in M) > 0.5: M = [[v / 2 for v in r] for r in M]; sq += 1
    E = [[float(i == j) for j in range(n)] for i in range(n)]; term = [r[:] for r in E]
    for k in range(1, 20):
        term = [[v / k for v in r] for r in mm(term, M)]; E = [[a + b for a, b in zip(r, q)] for r, q in zip(E, term)]
    for _ in range(sq): E = mm(E, E)
    return E
def zoh_vanloan(T):                               # exp([[A, B], [0, 0]] T) = [[Ad, Bd], [0, 1]]
    E = expm([[A[0][0] * T, A[0][1] * T, B[0] * T], [A[1][0] * T, A[1][1] * T, B[1] * T], [0.0, 0.0, 0.0]])
    return [E[0][:2], E[1][:2]], [E[0][2], E[1][2]]
def zoh_closed(T):                                # e^(At) written out for this lower-triangular A
    e1, e2, c = math.exp(-p1 * T), math.exp(-p2 * T), p2 / (p2 - p1)
    Ad = [[e1, 0.0], [c * (e1 - e2), e2]]
    return Ad, [R * (1 - e1), R * c * ((1 - e1) - p1 / p2 * (1 - e2))]
def f(x, u): return [A[0][0] * x[0] + B[0] * u, A[1][0] * x[0] + A[1][1] * x[1]]
def rk4(x, u, T, n=2000):                         # input held at u for one sample
    h = T / n
    for _ in range(n):
        k1 = f(x, u); k2 = f([a + h / 2 * k for a, k in zip(x, k1)], u)
        k3 = f([a + h / 2 * k for a, k in zip(x, k2)], u); k4 = f([a + h * k for a, k in zip(x, k3)], u)
        x = [a + h / 6 * (q + 2 * r + 2 * s + w) for a, q, r, s, w in zip(x, k1, k2, k3, k4)]
    return x
def zoh_rk4(T):
    c0, c1 = rk4([1.0, 0.0], 0.0, T), rk4([0.0, 1.0], 0.0, T)
    return [[c0[0], c1[0]], [c0[1], c1[1]]], rk4([0.0, 0.0], 1.0, T)
def tustin_coeffs(T, c=None):                     # G(s) = b0/(s^2 + a1 s + a0), s -> c (z-1)/(z+1)
    c = 2 / T if c is None else c
    b0, a1, a0 = R * p1 * p2, p1 + p2, p1 * p2
    den = [c * c + a1 * c + a0, 2 * a0 - 2 * c * c, c * c - a1 * c + a0]
    return [b0 / den[0] * k for k in (1, 2, 1)], [d / den[0] for d in den]
def run_tf(num, den, u, n):                       # y[k] = sum num u[k-i] - sum den[i] y[k-i]
    y = []
    for k in range(n):
        y.append(sum(num[i] * u for i in range(3) if k - i >= 0) - sum(den[i] * y[k - i] for i in (1, 2) if k - i >= 0))
    return y
def run_trap(T, u, n):                            # x[k] = x[k-1] + T/2 (f(x[k-1], u[k-1]) + f(x[k], u[k]))
    a, c, d = 1 - A[0][0] * T / 2, -A[1][0] * T / 2, 1 - A[1][1] * T / 2   # I - AT/2, lower triangular
    x, up, ys = [0.0, 0.0], 0.0, []
    for _ in range(n):
        fx = f(x, up)
        r = [x[0] + T / 2 * (fx[0] + B[0] * u), x[1] + T / 2 * fx[1]]
        x0 = r[0] / a; x = [x0, (r[1] - c * x0) / d]; up = u; ys.append(x[1])
    return ys
def run_ss(Ad, Bd, u, n):
    x, ys = [0.0, 0.0], []
    for _ in range(n):
        ys.append(x[1]); x = [Ad[0][0] * x[0] + Bd[0] * u, Ad[1][0] * x[0] + Ad[1][1] * x[1] + Bd[1] * u]
    return ys
def y_exact(t): return P * R * (1 - p2 / (p2 - p1) * math.exp(-p1 * t) + p1 / (p2 - p1) * math.exp(-p2 * t))
def G(s): return R / ((tau1 * s + 1) * (tau2 * s + 1))
def Gzoh(z, Ad, Bd):                              # C (zI - Ad)^-1 Bd
    a, b, c, d = z - Ad[0][0], -Ad[0][1], -Ad[1][0], z - Ad[1][1]
    return (-c * Bd[0] + a * Bd[1]) / (a * d - b * c)
def Gzoh_step(z):                                 # (1 - 1/z) times the z-transform of the sampled step response
    e1, e2 = math.exp(-p1 * T), math.exp(-p2 * T)
    return R * (1 - p2 / (p2 - p1) * (z - 1) / (z - e1) + p1 / (p2 - p1) * (z - 1) / (z - e2))
def Gt(z, num, den): return (num[0] * z * z + num[1] * z + num[2]) / (den[0] * z * z + den[1] * z + den[2])
def db(g): return 20 * math.log10(abs(g))
def tiny(x): return "below 1e-12" if x < 1e-12 else f"{x:.2e}"

Av, Bv = zoh_vanloan(T); Ac, Bc = zoh_closed(T); Ar, Br = zoh_rk4(T)
print(f"inputs: R = {R} K/W, tau1 = {tau1} s, tau2 = {tau2} s, step {P:.0f} W, fs = {1 / T:.0f} Hz, T = {T} s, Nyquist {0.5 / T:.0f} Hz")
print(f"G(s) = {R * p1 * p2:.1f} / (s^2 + {p1 + p2:.1f} s + {p1 * p2:.1f});  steady rise {P * R:.1f} K")
for lab, (Ad, Bd) in (("Van Loan", (Av, Bv)), ("closed  ", (Ac, Bc)), ("RK4     ", (Ar, Br))):
    print(f"ZOH {lab}  Ad = [{Ad[0][0]:.9f} {Ad[0][1]:.9f}; {Ad[1][0]:.9f} {Ad[1][1]:.9f}]  Bd = [{Bd[0]:.9f} {Bd[1]:.9f}]")
Rt, Ct = 20.0, 2.5                                # card 08's soldering tip, one lump: degC/W, J/degC
Et = expm([[-T / (Rt * Ct), T / Ct], [0.0, 0.0]])  # Van Loan for dx/dt = -x/(Rt Ct) + u/Ct
print(f"card 08 tip, tau = {Rt * Ct:.0f} s, ZOH by Van Loan: a = {Et[0][0]:.6f}, b = {Et[0][1]:.6f} degC per W per tick")
num, den = tustin_coeffs(T)
c, a1, a0 = 2 / T, p1 + p2, p1 * p2
print(f"Tustin, c = 2/T = {c:.0f}: raw den = [{c * c + a1 * c + a0:.0f} {2 * a0 - 2 * c * c:.0f} {c * c - a1 * c + a0:.0f}], raw num = [{R * a0:.0f} {2 * R * a0:.0f} {R * a0:.0f}]")
print(f"Tustin  num = [{num[0]:.9f} {num[1]:.9f} {num[2]:.9f}]  den = [1 {den[1]:.9f} {den[2]:.9f}]")
print(f"poles   s = -1, -4   ZOH e^(sT) = {Ac[0][0]:.6f}, {Ac[1][1]:.6f}   Tustin (1+sT/2)/(1-sT/2) = {(1 - p1 * T / 2) / (1 + p1 * T / 2):.6f}, {(1 - p2 * T / 2) / (1 + p2 * T / 2):.6f}")
N = 31
yz, yt, ytr = run_ss(Ac, Bc, P, N), run_tf(num, den, P, N), run_trap(T, P, N)
ex = [y_exact(k * T) for k in range(N)]
ez, et = max(abs(a - b) for a, b in zip(yz, ex)), max(abs(a - b) for a, b in zip(yt, ex))
print(f"step 10 W: max |ZOH - exact| over 3 s {tiny(ez)} K;  max |Tustin - exact| = {et * 1000:.3f} mK")
print(f"first samples (K): exact {ex[1]:.7f} {ex[2]:.7f}  ZOH {yz[1]:.7f} {yz[2]:.7f}  Tustin {yt[0]:.7f} {yt[1]:.7f} {yt[2]:.7f}")
print(f"Tustin: difference equation vs trapezoid ODE, max gap {tiny(max(abs(a - b) for a, b in zip(yt, ytr)))} K")
for k in range(0, N, 3):
    print(f"chart, t = {k * T:3.1f} s  exact {ex[k]:5.2f} K  ZOH {yz[k]:5.2f} K  Tustin {yt[k]:5.2f} K  Tustin error {1000 * (yt[k] - ex[k]):+7.3f} mK")
print(f"Tustin vs exact shifted half a sample earlier, max gap {1000 * max(abs(a - y_exact(k * T + T / 2)) for k, a in enumerate(yt)):.3f} mK")
# ---- frequency response on the unit circle, z = e^(j w T) ----
gap_zoh = gap_warp = 0.0
for fhz in (0.1, 0.5, 1.0, 2.0, 3.0, 4.0, 4.5):
    w = 2 * math.pi * fhz; z = cmath.exp(1j * w * T); wa = 2 / T * math.tan(w * T / 2)
    gz, gt = Gzoh(z, Ac, Bc), Gt(z, num, den)
    gap_zoh = max(gap_zoh, abs(gz - Gzoh_step(z))); gap_warp = max(gap_warp, abs(gt - G(1j * wa)))
    print(f"chart, f = {fhz:3.1f} Hz  G {db(G(1j * w)):7.2f} dB  ZOH {db(gz):7.2f} dB  Tustin {db(gt):7.2f} dB  (= G at {wa / (2 * math.pi):5.2f} Hz)")
print(f"ZOH: state-space vs step-response z-transform, max gap {tiny(gap_zoh)};  Tustin vs G at warped frequency, max gap {tiny(gap_warp)}")
w1 = 2 * math.pi; z1 = cmath.exp(1j * w1 * T)
ph = lambda g: math.degrees(cmath.phase(g))
print(f"phase at 1 Hz: G {ph(G(1j * w1)):.2f} deg, ZOH {ph(Gzoh(z1, Ac, Bc)):.2f} deg, G - wT/2 {ph(G(1j * w1)) - math.degrees(w1 * T / 2):.2f} deg, Tustin {ph(Gt(z1, num, den)):.2f} deg; hold delay T/2 = {T / 2} s = {math.degrees(w1 * T / 2):.2f} deg")
w0 = 2 * math.pi * 2.0; numw, denw = tustin_coeffs(T, w0 / math.tan(w0 * T / 2)); z0 = cmath.exp(1j * w0 * T)
print(f"prewarp at {w0 / (2 * math.pi):.0f} Hz: Tustin {db(Gt(z0, num, den)):.3f} dB, prewarped {db(Gt(z0, numw, denw)):.3f} dB, G {db(G(1j * w0)):.3f} dB")
# ---- what breaks ----
Te = 0.6; xe, ye = [0.0, 0.0], []
for k in range(21):
    ye.append(xe[1]); dx = f(xe, P); xe = [xe[0] + Te * dx[0], xe[1] + Te * dx[1]]
Az6, _ = zoh_closed(Te)
print(f"forward Euler at T = {Te} s: poles {1 - p1 * Te:.2f}, {1 - p2 * Te:.2f}; sensor after 20 steps {ye[20]:.1f} K (exact {y_exact(20 * Te):.4f} K); ZOH poles {Az6[0][0]:.4f}, {Az6[1][1]:.4f}; Euler needs T < 2 tau2 = {2 * tau2:.2f} s")
n1, d1 = tustin_coeffs(1.0); A1, B1 = zoh_closed(1.0)
y1t, y1z = run_tf(n1, d1, P, 8), run_ss(A1, B1, P, 8)
print(f"fs = 1 Hz: max |Tustin - exact| {max(abs(a - y_exact(k)) for k, a in enumerate(y1t)):.3f} K; max |ZOH - exact| {tiny(max(abs(a - y_exact(k)) for k, a in enumerate(y1z)))} K")
z4 = cmath.exp(1j * 2 * math.pi * 4.0 * T)
print(f"Tustin read at 4 Hz: {db(Gt(z4, num, den)):.2f} dB vs G at 4 Hz {db(G(2j * math.pi * 4.0)):.2f} dB, error {db(Gt(z4, num, den)) - db(G(2j * math.pi * 4.0)):.2f} dB")
fl = math.atan(2 * math.pi * 4.0 * T / 2) / (math.pi * T); zl = cmath.exp(2j * math.pi * fl * T)   # (2/T) atan(wT/2), in Hz
print(f"G's 4 Hz lands in Tustin at (2/T) atan(wT/2) = {fl:.2f} Hz: Tustin there {db(Gt(zl, num, den)):.2f} dB, G at 4 Hz {db(G(2j * math.pi * 4.0)):.2f} dB")
print(f"heater only heats: holding 2.0 K below room needs u = {-2.0 / R:.1f} W")
n5, d5 = tustin_coeffs(0.5)
print(f"try: fs = 2 Hz: max |Tustin - exact| {max(abs(a - y_exact(k * 0.5)) for k, a in enumerate(run_tf(n5, d5, P, 12))):.3f} K")

assert max(abs(a - b) for a, b in zip(Av[0] + Av[1] + Bv, Ac[0] + Ac[1] + Bc)) < 1e-12   # series vs closed form
assert max(abs(a - b) for a, b in zip(Ar[0] + Ar[1] + Br, Ac[0] + Ac[1] + Bc)) < 1e-10   # RK4 vs closed form
assert ez < 1e-12                                 # ZOH samples vs the exact step response
assert max(abs(a - b) for a, b in zip(yt, ytr)) < 1e-12   # Tustin difference equation vs trapezoid ODE
assert gap_zoh < 1e-12                             # two ZOH transfer functions agree
assert gap_warp < 1e-12                            # Tustin on the circle = G at the warped frequency
assert abs(db(Gt(z0, numw, denw)) - db(G(1j * w0))) < 1e-9   # prewarped Tustin is exact at 2 Hz
assert abs(ph(Gzoh(z1, Ac, Bc)) - ph(G(1j * w1)) + math.degrees(w1 * T / 2)) < 0.1   # ZOH phase = G - wT/2 at 1 Hz
assert abs(ye[20] - y_exact(20 * Te)) > 100       # Euler at 0.6 s runs away
print("ALL CHECKS PASS")
