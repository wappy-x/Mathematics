# Energy methods -- the check behind the card.  Standard library only.
# A 1 m x 1 m steel plate, edges held.  w = difference of two plates' temperatures.
# Roads to the energy E(t) = (1/2) * integral of w^2: closed form by modes, midpoint
# quadrature of the series, an explicit grid; dE/dt by centred differences against
# -kappa * integral |grad w|^2 (+ 2aE with a heat source).  Then the wave equation.
import math
PI = math.pi
KAPPA = 1.2e-5                        # steel's diffusivity, m^2/s
MODES = [(1, 1, 0.5), (2, 3, 0.3)]    # the starting difference: (m, n, amplitude in C)

def sci(x):                           # same digits in Python and Rust: 1.234e+31
    e = math.floor(math.log10(abs(x)))
    m = x / 10 ** e
    if round(abs(m), 3) >= 10: m, e = m / 10, e + 1
    return f"{m:.3f}e{'+' if e >= 0 else '-'}{abs(e):02d}"

def lam(m, n): return PI * PI * (m * m + n * n)          # mode's -Laplacian eigenvalue, 1/m^2

def w(x, y, t, a=0.0):                # series solution of w_t = kappa*Lap w + a*w
    return sum(A * math.exp((a - KAPPA * lam(m, n)) * t) * math.sin(m * PI * x) * math.sin(n * PI * y)
               for m, n, A in MODES)

def E_closed(t, a=0.0):               # each mode: (1/2)(A^2/4) e^{2(a - kappa*lam) t}
    return sum(A * A / 8 * math.exp(2 * (a - KAPPA * lam(m, n)) * t) for m, n, A in MODES)

def E_edge(t, M=11):                  # frames 0.5 C apart: w = 0.5 - v, v the zero-edge solution from 0.5,
    s = 0.0                           # odd modes 8/(pi^2 m n); E = (1/2)(1/4 - int v + int v^2)
    for m in range(1, M, 2):
        for n in range(1, M, 2):
            g = math.exp(-KAPPA * lam(m, n) * t)
            s += 16 / (PI * PI * PI * PI * m * m * n * n) * (g * g - 2 * g)
    return 0.5 * (0.25 + s)

def quad(f, M=60):                    # midpoint rule on the unit square
    h = 1 / M
    return sum(f((i + .5) * h, (j + .5) * h) for i in range(M) for j in range(M)) * h * h

def E_quad(t, a=0.0): return quad(lambda x, y: 0.5 * w(x, y, t, a) ** 2)

def grad2(t, a=0.0, d=1e-5):          # integral of |grad w|^2, gradient by centred differences
    return quad(lambda x, y: ((w(x + d, y, t, a) - w(x - d, y, t, a)) / (2 * d)) ** 2
                + ((w(x, y + d, t, a) - w(x, y - d, t, a)) / (2 * d)) ** 2)

def grid(t_end, N=40, dt=12.0, edge=0.0, start=None, track=False):   # explicit scheme
    h = 1 / N; r = KAPPA * dt / h / h
    u = [[edge if i in (0, N) or j in (0, N) else start[i][j] if start else w(i * h, j * h, 0)
          for j in range(N + 1)] for i in range(N + 1)]
    wt = lambda i: 0.5 if i in (0, N) else 1.0                       # trapezoid: edge nodes count half
    En = lambda: 0.5 * h * h * sum(wt(i) * wt(j) * u[i][j] ** 2 for i in range(N + 1) for j in range(N + 1))
    rises, last = 0, En()
    for _ in range(round(t_end / dt)):
        u = [[u[i][j] if i in (0, N) or j in (0, N) else u[i][j] + r * (u[i + 1][j] + u[i - 1][j]
              + u[i][j + 1] + u[i][j - 1] - 4 * u[i][j]) for j in range(N + 1)] for i in range(N + 1)]
        e = En(); rises += track and e > last + 1e-15; last = e
    return last, rises, r

print("heat: kappa = 1.2e-5 m^2/s; difference 0.5 C in mode (1,1), 0.3 C in mode (2,3)")
print("t (min) | E closed | E quadrature | E grid | dE/dt by differences | -kappa*int|grad w|^2  (E in C^2 m^2, rates per s)")
for mins in (0, 30, 60, 120):
    t = 60 * mins
    dEdt = (E_quad(t + 1) - E_quad(t - 1)) / 2
    D = KAPPA * grad2(t)
    Eg = grid(t)[0]
    print(f"{mins:3d} | {E_closed(t):.6f} | {E_quad(t):.6f} | {Eg:.6f} | {sci(dEdt)} | {sci(-D)}")
    assert abs(E_quad(t) - E_closed(t)) < 1e-9 and abs(Eg - E_closed(t)) < 1e-2 * E_closed(t)
    assert abs(dEdt + D) < 1e-4 * D                       # the energy identity, two roads
print(f"grid: h = 0.025 m, dt = 12 s, r = kappa dt / h^2 = {grid(0)[2]:.4f} (limit 0.25)")
print(f"rms difference: start {math.sqrt(2 * E_closed(0)):.4f} C, 60 min {math.sqrt(2 * E_closed(3600)):.4f} C")
print(f"decay bound E(0)e^(-2 kappa 2 pi^2 t) at 60 min: {E_closed(0) * math.exp(-4 * PI * PI * KAPPA * 3600):.6f}")
k11, k23 = KAPPA * lam(1, 1), KAPPA * lam(2, 3)
print(f"hand: kappa*lam(1,1) = {sci(k11)} /s; 60 min: 2*kappa*lam*t = {7200 * k11:.4f} and {7200 * k23:.4f},"
      f" factors {math.exp(-7200 * k11):.4f} and {sci(math.exp(-7200 * k23))}")
print("chart, E every 15 min:", ", ".join(f"{E_closed(900 * k):.4f}" for k in range(9)))

s = 0x2026111500000007                # SplitMix64: random starting differences on a 10 x 10 grid
def rnd():
    global s
    s = (s + 0x9E3779B97F4A7C15) & (2 ** 64 - 1); z = s
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & (2 ** 64 - 1)
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & (2 ** 64 - 1)
    return ((z ^ (z >> 31)) >> 11) / 2 ** 53
total = 0
for trial in range(20):
    st = [[2 * rnd() - 1 for j in range(11)] for i in range(11)]
    total += grid(2500, N=10, dt=250 / 1.2, start=st, track=True)[1]
print(f"random starts: 20 trials x 12 steps at r = 0.25; steps where E rose: {total}")
assert total == 0
same = grid(3600, start=[[0.0] * 41 for _ in range(41)])[0]
print(f"identical data: E of the difference at 60 min = {same:.6f}")

A_HEAT = 1e-4                         # heated plate: w_t = kappa Lap w + a w
def gron(t, a): return E_closed(0) * math.exp(2 * a * t)     # Gronwall: E(t) <= E(0) e^{2at}
for mins in (30, 60):
    t = 60 * mins
    tru, bound = E_closed(t, A_HEAT), gron(t, A_HEAT)
    dEdt = (E_quad(t + 1, A_HEAT) - E_quad(t - 1, A_HEAT)) / 2
    rhs = -KAPPA * grad2(t, A_HEAT) + 2 * A_HEAT * E_quad(t, A_HEAT)
    print(f"heated, a = 1e-4 /s, {mins} min: E true {tru:.6f}, Gronwall factor {math.exp(2 * A_HEAT * t):.4f},"
          f" bound {bound:.6f}, dE/dt {sci(dEdt)} vs {sci(rhs)}")
    assert tru <= bound and abs(dEdt - rhs) < 1e-4 * abs(rhs)

print("what breaks:")
print(f"  backward heat, 1e-6 C in mode (10,10), 60 min: exponent {KAPPA * lam(10, 10) * 3600:.2f}, {sci(1e-6 * math.exp(KAPPA * lam(10, 10) * 3600))} C")
Es = E_edge(3600)
Eb, Eb2 = (grid(3600, N=n, dt=dt, edge=0.5, start=[[0.0] * (n + 1) for _ in range(n + 1)])[0]
           for n, dt in ((40, 12.0), (20, 48.0)))
print(f"  edges 0.5 C apart, same start: E from 0 to {Es:.6f} at 60 min by series, first omitted term "
      f"{sci(16 / (PI * PI * PI * PI * 121) * math.exp(-KAPPA * lam(11, 1) * 3600))}")
print(f"  same case on the grid: h = 0.05 m, dt = 48 s {Eb2:.6f}; h = 0.025 m, dt = 12 s {Eb:.6f}; "
      f"error ratio {(Eb2 - Es) / (Eb - Es):.2f}")
assert abs(Eb - Es) < 0.005 * Es and 3.5 < (Eb2 - Es) / (Eb - Es) < 4.5   # two roads; second order in h
big = E_closed(3600, 5e-4)
print(f"  a = 5e-4 /s, no Gronwall factor: claimed E <= {E_closed(0):.6f}, true {big:.6f}; Gronwall bound {gron(3600, 5e-4):.6f}")
assert E_closed(0) < big <= gron(3600, 5e-4)

RHO, C, B, AMP = 15.7, 100.0, 1.0, 0.001     # wave: kg/m^2, m/s, damping /s, 1 mm in mode (1,1)
w11 = C * PI * math.sqrt(2)
def wave(t, b):                       # damped mode: displacement amplitude and its rate
    wd = math.sqrt(w11 ** 2 - b * b / 4); e = math.exp(-b * t / 2)
    return (AMP * e * (math.cos(wd * t) + b / (2 * wd) * math.sin(wd * t)),
            -AMP * e * (w11 ** 2 / wd) * math.sin(wd * t))
def wave_E(t, b, c2=C * C):           # (rho/2) int (w_t^2 + c^2 |grad w|^2); sin^2 integrates to 1/4
    q, p = wave(t, b)
    return RHO / 2 * (p * p + c2 * lam(1, 1) * q * q) / 4
print(f"wave: mode (1,1) {w11:.2f} rad/s = {w11 / (2 * PI):.2f} Hz, rho_s = {RHO} kg/m^2, c = {C:.0f} m/s, E(0) = {wave_E(0, 0):.6f} J")
for t in (0.25, 0.5, 1.0):
    dE = (wave_E(t + 1e-6, B) - wave_E(t - 1e-6, B)) / 2e-6
    loss = -B * RHO * wave(t, B)[1] ** 2 / 4
    print(f"  t = {t:.2f} s: E undamped {wave_E(t, 0):.6f} J, damped {wave_E(t, B):.6f} J, dE/dt {dE:.6f} vs {loss:.6f} J/s")
    assert abs(wave_E(t, 0) - wave_E(0, 0)) < 1e-12 and abs(dE - loss) < 1e-5
q4 = PI / (2 * w11)
print(f"  energy without c^2: {sci(wave_E(0, 0, 1.0))} J at t = 0, {sci(wave_E(q4, 0, 1.0))} J a quarter period on")
print("ALL CHECKS PASS")
