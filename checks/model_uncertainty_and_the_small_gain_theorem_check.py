# Model uncertainty and the small gain rule -- the check behind the card.  Standard library only.
# Conveyor motor speed loop.  Torque command u (N m) -> drive lag 0.02 s -> roller and belt,
# inertia J (kg m^2), friction b (N m s/rad) -> speed v (rad/s).  PI controller on speed.
# Model error: the load inertia doubles, J0 = 0.2 -> 0.4 kg m^2, written as a percentage
# P = P0 (1 + W D), |D| <= 1, with envelope W(s) = 0.5 s / (s + 1).  Roads:
#   1. small gain: peak over frequency of |W T| < 1 (sweep plus golden-section refinement);
#   2. closed-loop poles of the true plant, by Durand-Kerner on the cubic, for many loads;
#   3. RK4 simulation: a sine at the peak frequency measures |T|; steps with both loads.
import cmath, math
J0, b, ta, Kp, Ki = 0.2, 0.4, 0.02, 10.0, 50.0
def P(s, J=J0): return 1 / ((J * s + b) * (ta * s + 1))
def C(s, kp=Kp, ki=Ki): return kp + ki / s
def T(s, kp=Kp, ki=Ki): L = P(s) * C(s, kp, ki); return L / (1 + L)
def Wk(s, k): return (1 - 1 / k) * s / (s + b / (k * J0))    # exact envelope for load x k
def W(s): return Wk(s, 2.0)                                   # = 0.5 s / (s + 1)
WS = [10 ** (-2 + 5 * i / 2000) for i in range(2001)]           # 0.01 to 1000 rad/s
def peak(f):                       # largest |f(jw)|: sweep, then golden section on log w
    i = max(range(len(WS)), key=lambda i: abs(f(1j * WS[i])))
    a, c = math.log(WS[max(i - 1, 0)]), math.log(WS[min(i + 1, 2000)])
    g = (math.sqrt(5) - 1) / 2
    for _ in range(80):
        x1, x2 = c - g * (c - a), a + g * (c - a)
        if abs(f(1j * math.exp(x1))) > abs(f(1j * math.exp(x2))): c = x2
        else: a = x1
    w = math.exp((a + c) / 2); return abs(f(1j * w)), w
print(f"plant: J0 {J0:.2f} kg m^2, b {b:.2f} N m s/rad, drive lag {ta:.3f} s; PI Kp {Kp:.1f} N m s/rad, Ki {Ki:.1f} N m/rad")
gap = max(abs((J0 - J) * s / (J * s + b)) - abs(W(s)) for J in [J0 * (1 + i / 20) for i in range(21)] for s in [1j * w for w in WS])
print(f"envelope covers every load 0.20 to 0.40 kg m^2: largest |error| - |W| = {gap:.4f}")
assert gap <= 1e-12
nWT, wWT = peak(lambda s: W(s) * T(s)); nT, wT = peak(T); nS, wS = peak(lambda s: 1 / (1 + P(s) * C(s)))
print(f"road 1: peak |W T| = {nWT:.4f} at {wWT:.2f} rad/s, so the envelope may grow x{1 / nWT:.3f}")
print(f"peak |T| = {nT:.4f} at {wT:.2f} rad/s; peak |S| = {nS:.4f} at {wS:.2f} rad/s")
s = 1j * wWT; L = P(s) * C(s)
for lab, v in [("|J0 jw + b|", abs(J0 * s + b)), ("|ta jw + 1|", abs(ta * s + 1)), ("|C(jw)|", abs(C(s))),
               ("|L|", abs(L)), ("phase of L (deg)", math.degrees(cmath.phase(L))), ("|1 + L|", abs(1 + L)),
               ("|T| = |L| / |1 + L|", abs(L / (1 + L))), ("|W|", abs(W(s))), ("|W T|", abs(W(s) * L / (1 + L)))]:
    print(f"  at {wWT:.2f} rad/s  {lab:22s} {v:9.4f}")
assert abs(nWT - abs(W(1j * wT)) * nT) < 1e-3     # W is nearly flat at the peak
def roots(c):                       # Durand-Kerner: all roots of a polynomial, highest power first
    c = [x / c[0] for x in c]; n = len(c) - 1; z = [(0.4 + 0.9j) ** k for k in range(n)]
    for _ in range(500):
        for i in range(n):
            num = sum(c[k] * z[i] ** (n - k) for k in range(n + 1)); den = 1
            for j in range(n):
                if j != i: den *= z[i] - z[j]
            z[i] -= num / den
    return sorted(z, key=lambda r: -r.real)
def cubic(J): return [J * ta, J + b * ta, b + Kp, Ki]   # (J s + b)(ta s + 1) s + Kp s + Ki
for k in [1, 2, 5, 100]:
    r = roots(cubic(k * J0)); print(f"road 2: load x{k:<3d} rightmost closed-loop pole {r[0].real:.4f} +/- {abs(r[0].imag):.4f}j /s")
    assert r[0].real < 0 and abs(sum(c * r[0] ** (3 - i) for i, c in enumerate(cubic(k * J0)))) < 1e-6
def sim(J, ref, tend, dt=1e-4):     # RK4: speed v, delivered torque m, integral of error z
    def f(t, x): u = Kp * (ref(t) - x[0]) + Ki * x[2]; return [(x[1] - b * x[0]) / J, (u - x[1]) / ta, ref(t) - x[0]]
    x, t, out = [0.0, 0.0, 0.0], 0.0, []
    for _ in range(round(tend / dt)):
        k1 = f(t, x); k2 = f(t + dt / 2, [a + dt / 2 * d for a, d in zip(x, k1)])
        k3 = f(t + dt / 2, [a + dt / 2 * d for a, d in zip(x, k2)]); k4 = f(t + dt, [a + dt * d for a, d in zip(x, k3)])
        x = [a + dt / 6 * (p + 2 * q + 2 * r + w) for a, p, q, r, w in zip(x, k1, k2, k3, k4)]; t += dt; out.append((t, x[0]))
    return out
amp = max(abs(v) for t, v in sim(J0, lambda t: math.sin(wT * t), 3.0) if t > 2.5)
print(f"road 3: sine of 1 rad/s at {wT:.2f} rad/s comes back {amp:.4f} rad/s (|T| = {nT:.4f})")
assert abs(amp - nT) < 1e-3
for k in [1, 2]:
    y = sim(k * J0, lambda t: 1.0, 2.0); top = max(v for t, v in y)
    ts = max(t for t, v in y if abs(v - 1) > 0.02)
    print(f"1 rad/s speed step, load x{k}: overshoot {100 * (top - 1):.2f}%, within 2% after {ts:.3f} s")
    assert abs(y[-1][1] - 1) < 1e-3
lo, hi = 2.0, 50.0                  # largest load the exact-envelope test still certifies
for _ in range(50):
    m = (lo + hi) / 2; lo, hi = (m, hi) if peak(lambda s: Wk(s, m) * T(s))[0] < 1 else (lo, m)
print(f"certified up to load x{lo:.2f}; Routh term J (b + Kp - ta Ki) = J x {b + Kp - ta * Ki:.1f} > 0: stable for every load")
def wgc():                          # gain crossover |L| = 1 by halving on log w
    lo, hi = 1.0, 1000.0
    for _ in range(100): m = math.sqrt(lo * hi); lo, hi = (m, hi) if abs(P(1j * m) * C(1j * m)) > 1 else (lo, m)
    return lo
wc = wgc(); dm = (math.pi + cmath.phase(P(1j * wc) * C(1j * wc))) / wc
lo, hi = 0.0, 0.1                   # small gain for a delay: envelope |e^(-jw th) - 1|
for _ in range(40):
    m = (lo + hi) / 2; lo, hi = (m, hi) if peak(lambda s: (cmath.exp(-s * m) - 1) * T(s))[0] < 1 else (lo, m)
print(f"delay: small gain certifies {1000 * lo:.2f} ms; true delay margin {1000 * dm:.2f} ms at {wc:.2f} rad/s")
def newton(th, s):                  # a root of (J0 s + b)(ta s + 1) s + (Kp s + Ki) e^(-s th)
    for _ in range(60):
        e = cmath.exp(-s * th); f = (J0 * s + b) * (ta * s + 1) * s + (Kp * s + Ki) * e
        d = J0 * (ta * s + 1) * s + ta * (J0 * s + b) * s + (J0 * s + b) * (ta * s + 1) + (Kp - th * (Kp * s + Ki)) * e
        s -= f / d
    return s
z = newton(dm, 1j * wc); assert abs(z.real) < 1e-9 and abs(z.imag - wc) < 1e-6 and lo < dm
z = newton(0.025, 1j * wc); print(f"25 ms delay, light load: closed-loop pole {z.real:+.4f} {z.imag:+.4f}j /s")
assert z.real > 0
print(f"break: L in place of T, peak |W L| = {peak(lambda s: W(s) * P(s) * C(s))[0]:.2f}")
lump, wl = peak(lambda s: P(s, 2 * J0) - P(s))
print(f"break: flat lump {lump:.4f} (rad/s)/(N m) (peak at {wl:.2f} rad/s), peak |lump C S| = {peak(lambda s: lump * C(s) / (1 + P(s) * C(s)))[0]:.2f}")
print(f"break: true lump with |P0 W| as envelope, peak |P0 W C S| = {peak(lambda s: P(s) * W(s) * C(s) / (1 + P(s) * C(s)))[0]:.4f}")
for lab, kp, ki in [("try: Kp 20, Ki 100", 20, 100), ("try: Kp 5, Ki 25", 5, 25)]:
    print(f"{lab}: peak |W T| = {peak(lambda s: W(s) * T(s, kp, ki))[0]:.4f}")
print(f"try: load x3, exact envelope: peak |W T| = {peak(lambda s: Wk(s, 3) * T(s))[0]:.4f}")
FW = [0.1, 0.3, 1, 3, 10, 20, 35.6, 60, 100, 300, 1000]
print("chart |W|   ", ", ".join(f"{abs(W(1j * w)):.3f}" for w in FW))
print("chart 1/|T| ", ", ".join(f"{1 / abs(T(1j * w)):.3f}" for w in FW))
print("ALL CHECKS PASS")
