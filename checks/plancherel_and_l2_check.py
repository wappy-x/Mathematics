# Plancherel -- the check behind the card.  Standard library only.
# The note: f(t) = A e^(-t/tau) sin(2 pi f0 t) for t >= 0, 0 before the pluck,
# with A = 1 V, f0 = 110 Hz, tau = 1 s (illustrative).  Hertz form:
# fhat(xi) = integral f(t) e^(-2 pi i xi t) dt, xi in hertz, energy in V^2 s.
# Roads: energy in time, closed form and Simpson; in frequency, Simpson on the
# closed-form fhat; a written-out FFT; smoothed notes built in time by Simpson.
# Nothing imported knows the answer: math gives exp, sin, cos, atan, tan, sqrt, pi.
import math
PI, A, F0, TAU = math.pi, 1.0, 110.0, 1.0
AL = 1 / TAU                                   # decay rate, per second
S = complex(-AL, 2 * PI * F0)                  # the note is Im(A e^(S t)) for t >= 0
cis = lambda a: complex(math.cos(a), math.sin(a))

def simpson(g, a, b, m):                       # Simpson's rule, m even slices
    h, s = (b - a) / m, g(a) + g(b)
    for k in range(1, m):
        s += (4 if k % 2 else 2) * g(a + k * h)
    return s * h / 3

def note(t): return A * math.exp(-t / TAU) * math.sin(2 * PI * F0 * t) if t >= 0 else 0.0

def fhat(xi):                                  # closed form, a complex number
    p, q = 1 / complex(AL, 2 * PI * (xi - F0)), 1 / complex(AL, 2 * PI * (xi + F0))
    return A * (p - q) / 2j
power = lambda xi: abs(fhat(xi)) ** 2

def band(lo, hi, w, m):                       # integral of power * w over lo..hi Hz
    th = lambda xi: math.atan(2 * PI * (xi - F0) / AL)  # xi = F0 + (AL/2pi) tan(th):
    def g(u):                                           # flattens the peak at F0
        xi = F0 + AL / (2 * PI) * math.tan(u)
        return power(xi) * w(xi) * AL / (2 * PI) / math.cos(u) ** 2
    return simpson(g, th(lo), th(hi), m)

def freq_int(w, m):                            # all xi: power is even in xi
    cuts = (0, F0 - 1, F0 + 1, 1e3)            # three pieces, peak in the middle
    top = lambda u: power(1e3 / u ** 4) * w(1e3 / u ** 4) * 4e3 / u ** 5 if u else 0.0
    s = sum(band(cuts[i], cuts[i + 1], w, m) for i in range(3)) + simpson(top, 0, 1, m)
    return 2 * s                               # last piece: xi = 1 kHz / u^4, out to infinity

def in_time(e, c):                             # energy of c f - f_eps, in time: no transform
    m, G = 6 * e, lambda u: math.exp(-PI * u * u / (e * e)) / e   # the bell, cut at 6 eps
    fe = lambda t: simpson(lambda u: note(t - u) * G(u), -m, min(t, m), 400) if t > -m else 0.0
    g = lambda t: (c * note(t) - fe(t)) ** 2   # fe(t) = f_eps(t) = integral f(t - u) G(u) du
    K = simpson(lambda u: cis(-S.imag * u) * math.exp(AL * u) * G(u), -m, m, 400)
    D, E = A * (c - K), cis(2 * S.imag * m) * math.exp(-2 * AL * m)  # past m: Im(D e^(S t))
    far = (abs(D) ** 2 * math.exp(-2 * AL * m) / (2 * AL) + (D * D * E / (2 * S)).real) / 2
    return simpson(g, -m, 0, 400) + simpson(g, 0, m, 400) + far   # near part split at the kink

def fft(x):                                    # radix-2, written out
    n = len(x)
    if n == 1:
        return x
    ev, od = fft(x[0::2]), fft(x[1::2])
    out = [0j] * n
    for k in range(n // 2):
        tw = cis(-2 * PI * k / n) * od[k]
        out[k], out[k + n // 2] = ev[k] + tw, ev[k] - tw
    return out

one = lambda w: 1.0
f6 = lambda v: f"{v:.6f}"
f9 = lambda v: f"{v:.9f}"
print("== the note: 1 V, 110 Hz, amplitude falls by e each second ==")
bt = 2 * PI * F0 * TAU
print(f"b = 2 pi f0 tau = {f6(bt)}; b^2/(1 + b^2) = {f9(bt * bt / (1 + bt * bt))}")
e_exact = TAU / 4 * bt * bt / (1 + bt * bt)
e_simp = simpson(lambda t: note(t) ** 2, 0, 10, 200000)
tail_t = TAU / 2 * math.exp(-20 / TAU)
print(f"energy in time, closed form (tau/4) b^2/(1 + b^2), b = 2 pi f0 tau: {f9(e_exact)} V^2 s")
print(f"energy in time, Simpson on 0..10 s: {f9(e_simp)}; tail beyond 10 s at most {tail_t:.2e}")
assert abs(e_simp - e_exact) < 1e-9                        # road 1 = road 2
e_f1, e_f2 = freq_int(one, 2000), freq_int(one, 4000)
print(f"energy in frequency, Simpson, 2000 and 4000 steps: {f9(e_f1)} and {f9(e_f2)} V^2 s")
assert abs(e_f2 - e_exact) < 1e-9                          # Plancherel on the note
assert abs(e_f1 - e_f2) < 1e-8
print(f"peak |fhat(110)| = {f6(abs(fhat(F0)))} V s; half-power half-width 1/(2 pi tau) = {f6(AL / (2 * PI))} Hz")
print("bars, share of the energy within d Hz of +-110 Hz: d | share")
for d in (0.1, 0.5, 1, 5, 50):
    print(f"bars, {d} | {100 * 2 * band(F0 - d, F0 + d, one, 2000) / e_exact:.4f} %")
print(f"Lorentz estimate for d = 1, (2/pi) atan(2 pi): {100 * 2 / PI * math.atan(2 * PI):.4f} %")

print("== the samples: 4096 a second for 8 s, N = 32768, written-out FFT ==")
fs, N = 4096, 32768
dt, dxi = 1 / fs, fs / N
x = [complex(note(n * dt), 0) for n in range(N)]
X = fft(x)
s_time, s_freq = 0.0, 0.0
for n in range(N):
    s_time += abs(x[n]) ** 2 * dt
    s_freq += abs(X[n] * dt) ** 2 * dxi
print(f"dt sum x^2 = {f9(s_time)}; dxi sum |dt X|^2 = {f9(s_freq)} V^2 s")
assert abs(s_time - s_freq) < 1e-12                        # finite Parseval, exact
print(f"gap from the true energy (sampling and the 8 s cut): {s_time - e_exact:.2e}")
assert abs(s_time - e_exact) < 1e-6
k = round(F0 / dxi)
cut = abs(fhat(F0)) * (1 - math.exp(-8 / TAU))  # the 8 s cut drops e^(-8) of the peak
print(f"bin {k} at {f6(k * dxi)} Hz: |dt X| = {f6(abs(X[k] * dt))}; |fhat| = {f6(abs(fhat(F0)))}, times 1 - e^-8 = {f6(cut)}")
assert abs(abs(X[k] * dt) - cut) < 1e-6                    # the FFT is the transform

print("== density: bell-smoothed notes f_eps, each rapidly decreasing ==")
print("eps ms | gain at 110 Hz | energy of f_eps | ||f - f_eps||^2 in time | in frequency | ||f_eps - f_prev||^2")
eps_list, dist, ens = (10, 1, 0.1, 0.01), [], []
for i, eps_ms in enumerate(eps_list):
    e, p = eps_ms / 1000, eps_list[i - 1] / 1000
    sm = lambda xi, e=e: math.exp(-PI * e * e * xi * xi)   # the bell's transform
    ens.append(freq_int(lambda xi: sm(xi) ** 2, 4000))
    dist.append(in_time(e, 1))                             # f is not in S: measured in time
    d_f = freq_int(lambda xi: (1 - sm(xi)) ** 2, 4000)
    c = "-" if i == 0 else f"{freq_int(lambda xi: (sm(xi) - sm(xi, p)) ** 2, 4000):.3e}"
    print(f"{eps_ms} | {f6(sm(F0))} | {f9(ens[i])} | {dist[i]:.3e} | {d_f:.3e} | {c}")
    assert abs(d_f - dist[i]) < 1e-3 * dist[i]             # time side = frequency side
assert dist[0] > dist[1] > dist[2] > dist[3] and dist[3] < 1e-5 * dist[0]
e_time = in_time(0.001, 0)                     # f_eps for eps = 1 ms, built in time
print(f"eps = 1 ms: energy of f_eps in time {f9(e_time)}, in frequency {f9(ens[1])} V^2 s")
assert abs(e_time - ens[1]) < 1e-8                         # Plancherel on a smooth note

print("== the shutter: 1 V for 1 ms; its spectrum sin(pi xi T)/(pi xi) ==")
T = 0.001
gate = lambda xi: T if xi == 0 else math.sin(PI * xi * T) / (PI * xi)
lobe = 2 * simpson(lambda xi: gate(xi) ** 2, 0, 1 / T, 2000)
print(f"gate energy {f6(T * 1000)} V^2 ms; main lobe |xi| < 1 kHz holds {100 * lobe / T:.4f} %")
area, edge, areas = 0.0, 0.0, []
for W in (10, 100, 1000):                      # in units of kHz; lobes of 1 kHz
    while edge < W:
        area += 2 * simpson(lambda xi: abs(gate(xi)), edge / T, (edge + 1) / T, 40)
        edge += 1
    print(f"area under |spectrum| for |xi| < {W} kHz: {f6(area)} V")
    areas.append(area)
grow = 4 / PI ** 2 * math.log(10)
print(f"growth per tenfold band: {f6(areas[2] - areas[1])} V; (4/pi^2) ln 10 = {f6(grow)}")
assert abs(areas[2] - areas[1] - grow) < 1e-3              # no finite area

print("== what breaks ==")
print(f"omega form, no 1/2pi: integral |F(omega)|^2 d omega = 2 pi x {f6(e_f2)} = {f6(2 * PI * e_f2)}")
for L in (1, 10, 100):
    print(f"string that never decays: energy over the first {L} s = {f6(simpson(lambda t: math.sin(2 * PI * F0 * t) ** 2, 0, L, 2000 * L))} V^2 s")
print(f"positive frequencies only: {f6(e_f2 / 2)} against {f6(e_exact)}")
print(f"because |fhat(-110)| = {f6(abs(fhat(-F0)))} = |fhat(110)|")
assert abs(power(-F0) - power(F0)) < 1e-12                 # a real note: even power
print("ALL CHECKS PASS")
