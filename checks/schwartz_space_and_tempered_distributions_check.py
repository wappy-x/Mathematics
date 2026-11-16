# Schwartz space and tempered distributions -- the check behind the card.
# Standard library only.  Units: time t in ms, frequency xi in kHz, so xi*t is a
# pure number.  Convention: f-hat(xi) = integral of f(t) e^(-2 pi i xi t) dt.
# Every transform and pairing is computed here.  Roads: closed forms against the
# defining integral by Simpson's rule, the probe's own transform against the
# principal-value integral, a Dawson series, and damped stand-ins that settle.
import math

def simpson(f, a, b, n):  # n even
    w = (b - a) / n
    tot = f(a) + f(b)
    for k in range(1, n):
        tot += (4 if k % 2 else 2) * f(a + k * w)
    return tot * w / 3
def sinc(u): return 1.0 if u == 0 else math.sin(math.pi * u) / (math.pi * u)
def arrow(x): return complex(math.cos(x), math.sin(x))  # e^(ix), written out
def snap(x): return 0.0 if abs(x) < 5e-10 else x
def c(z): return f"{snap(z.real):.6f} {'-' if z.imag < 0 else '+'} {abs(z.imag):.6f}i"
XI0, R = 0.25, 6.0  # the probe's centre, 250 Hz; cut-off 6 kHz or 6 ms
def phi(x): return math.exp(-math.pi * (x - XI0) ** 2)  # probe in frequency
# its transform is e^(-pi t^2) e^(-2 pi i XI0 t): the bell is its own transform
TAIL = math.exp(-math.pi * (R - XI0) ** 2)  # bound on any probe tail past R
print(f"probe phi(xi) = exp(-pi (xi - 0.25)^2), cut-off {R:.0f}, tail below {TAIL:.1e}")

# 1. Schwartz space: weighted slopes p_ab = sup |t^a phi^(b)(t)| of the bell
g0 = lambda t: math.exp(-math.pi * t * t)
grid = [k / 100000 for k in range(500001)]
p10 = max(t * g0(t) for t in grid); p20 = max(t * t * g0(t) for t in grid)
p01 = max(2 * math.pi * t * g0(t) for t in grid)
ex10, ex20 = math.exp(-0.5) / math.sqrt(2 * math.pi), 1 / (math.pi * math.e)
print(f"bell weighted slopes: p00 1.000000, p10 {p10:.6f} (exact {ex10:.6f}),"
      f" p20 {p20:.6f} (exact {ex20:.6f}), p01 {p01:.6f} (exact {2 * math.pi * ex10:.6f})")
assert abs(p10 - ex10) < 1e-9 and abs(p20 - ex20) < 1e-9 and abs(p01 - 2 * math.pi * ex10) < 1e-8
bell_self = simpson(lambda t: g0(t) * math.cos(2 * math.pi * 0.5 * t), -R, R, 4000)
print(f"bell transform at 0.5 kHz: Simpson {bell_self:.6f}, bell itself {g0(0.5):.6f}")
assert abs(bell_self - g0(0.5)) < 1e-12
print("1/(1+t^2), weight t^3: " + ", ".join(f"t={t}: {t ** 3 / (1 + t * t):.6f}" for t in (10, 100, 1000)))
bump = lambda t: math.exp(-1 / (1 - t * t)) if abs(t) < 1 else 0.0
for xi in (2.0, 3.0):
    b1 = simpson(lambda t: bump(t) * math.cos(2 * math.pi * xi * t), -1, 1, 4000)
    b2 = simpson(lambda t: bump(t) * math.cos(2 * math.pi * xi * t), -1, 1, 8000)
    print(f"bump zero outside 1 ms, transform at {xi:.0f} kHz: {b1:.6f} ms (n=4000), {b2:.6f} ms (n=8000)")
    assert abs(b1 - b2) < 1e-9 and abs(b1) > 1e-4

# 2. delta and constant: delta-hat = 1, 1-hat = delta
for w in (1.0, 0.1, 0.01):  # a flash w ms long, height 1/w: area 1
    s = simpson(lambda t: math.cos(2 * math.pi * XI0 * t) / w, -w / 2, w / 2, 200)
    print(f"flash {w} ms at 250 Hz: closed form {sinc(w * XI0):.6f}, Simpson {s:.6f}, delta gives 1")
    assert abs(s - sinc(w * XI0)) < 1e-9
target = phi(0)  # 1-hat = delta, so 1-hat(phi) = phi(0)
print(f"lamp on for good, paired with probe: delta(phi) = phi(0) = {target:.6f}")
for L in (1, 2, 4):  # lamp on for L ms, transform L sinc(L xi)
    fr = simpson(lambda x: L * sinc(L * x) * phi(x), -R, R, 6000 * L)
    tm = simpson(lambda t: g0(t) * math.cos(2 * math.pi * XI0 * t), -L / 2, L / 2, 2000)
    gap = 2 * math.exp(-math.pi * L * L / 4) / (math.pi * L)
    print(f"lamp {L} ms: frequency side {fr:.6f}, time side {tm:.6f}, gap {abs(target - tm):.1e} <= bound {gap:.1e}")
    assert abs(fr - tm) < 1e-8 and abs(target - tm) <= gap
print("lamp transform at 100 Hz, pointwise: " + ", ".join(f"L={L} ms: {L * sinc(L * 0.1):.6f}" for L in (5, 15, 25)))

# 3. the sign function: sgn-hat = p.v. 1/(pi i xi)
time_side = -2j * simpson(lambda t: g0(t) * math.sin(2 * math.pi * XI0 * t), 0, R, 6000)
odd = lambda x: (phi(x) - phi(-x)) / x if x else 4 * math.pi * XI0 * phi(0)
pv = simpson(odd, 0, R, 6000) / (math.pi * 1j)
x, term, dawson, n = math.sqrt(math.pi) * XI0, math.sqrt(math.pi) * XI0, 0.0, 0
while abs(term) > 1e-17:  # Dawson series D(x) = sum (-2x^2)^n x / (1*3*...*(2n+1))
    dawson += term; n += 1; term *= -2 * x * x / (2 * n + 1)
series = -2j * dawson / math.sqrt(math.pi)
print(f"sgn-hat on probe: time side {c(time_side)}, p.v. side {c(pv)}, Dawson series {c(series)}")
assert abs(time_side - pv) < 1e-10 and abs(pv - series) < 1e-12
last = 1.0
for eps in (1.0, 0.1, 0.01, 0.001):  # damped sign e^(-eps|t|) sgn(t): transform -4 pi i xi/(eps^2 + 4 pi^2 xi^2)
    k = lambda x: (phi(x) - phi(-x)) * x / (eps ** 2 + 4 * math.pi ** 2 * x * x)
    pair = -4j * math.pi * simpson(k, 0, R, 400000)
    point = -4j * math.pi * XI0 / (eps ** 2 + 4 * math.pi ** 2 * XI0 ** 2)
    print(f"damped sign eps={eps}/ms: at 250 Hz {c(point)} ms, on probe {c(pair)}, gap {abs(pair - pv):.6f}")
    assert abs(pair - pv) < last / 5; last = abs(pair - pv)
assert last < 5e-4 and abs(point - 1 / (math.pi * 1j * XI0)) < 1e-6
print(f"sgn-hat at 250 Hz: 1/(pi i xi) = {c(1 / (math.pi * 1j * XI0))} ms")
uneven = (simpson(lambda x: phi(x) / x, 0.002, R, 400000) + simpson(lambda x: phi(x) / x, -R, -0.001, 400000)) / (math.pi * 1j)
print(f"uneven gap (-1 Hz, 2 Hz) instead of p.v.: {c(uneven)}, shift {c(uneven - pv)}, limit as the gap shrinks {c(-phi(0) * math.log(2) / (math.pi * 1j))}")
assert abs(uneven - pv + phi(0) * math.log(2) / (math.pi * 1j)) < 2e-3

# 4. the step H = (1 + sgn)/2: H-hat = delta/2 + p.v. 1/(2 pi i xi)
h_time = simpson(g0, 0, R, 6000)  # centred bell: H(bell-hat) = integral over t > 0
print(f"H-hat on the centred bell: time side {h_time:.6f}, formula 1/2 + 0 = 0.500000, without delta/2 0.000000")
assert abs(h_time - 0.5) < 1e-12
h_probe = simpson(lambda t: g0(t) * arrow(-2 * math.pi * XI0 * t), 0, R, 6000)  # H(phi-hat)
print(f"H-hat on probe: time side {c(h_probe)}, phi(0)/2 + p.v./2 {c(phi(0) / 2 + pv / 2)}")
assert abs(h_probe - (phi(0) / 2 + pv / 2)) < 1e-10
print(f"H-hat at 250 Hz, away from 0: 1/(2 pi i xi) = {c(1 / (2 * math.pi * 1j * XI0))} ms")
wrong = 2 * math.pi * target
print(f"1-hat = 2 pi delta in hertz (the omega-form factor): {wrong:.6f} instead of {target:.6f}")

# 5. the 1 ms shutter g = H(t + 1/2) - H(t - 1/2), and its slope: two spikes
T = 1.0
steps = (arrow(math.pi * XI0 * T) - arrow(-math.pi * XI0 * T)) / (2 * math.pi * 1j * XI0)
direct = simpson(lambda t: math.cos(2 * math.pi * XI0 * t), -T / 2, T / 2, 400)
print(f"shutter at 250 Hz: from two steps {c(steps)}, T sinc(T xi) {T * sinc(T * XI0):.6f}, Simpson {direct:.6f} ms")
assert abs(steps - direct) < 1e-9 and abs(direct - T * sinc(T * XI0)) < 1e-10  # two steps against Simpson
spikes = arrow(math.pi * XI0 * T) - arrow(-math.pi * XI0 * T)  # delta(t+1/2) - delta(t-1/2)
print(f"shutter slope at 250 Hz: two spikes {c(spikes)}, 2 pi i xi g-hat {c(2j * math.pi * XI0 * T * sinc(T * XI0))}, pointwise slope 0")
assert abs(spikes - 2j * math.pi * XI0 * direct) < 1e-9  # the jumps against 2 pi i xi times Simpson's g-hat
print("chart, xi kHz      " + " ".join(f"{k / 20:6.2f}" for k in range(1, 21)))
for eps in (1.0, 0.25):
    print(f"chart, eps={eps:<4}    " + " ".join(f"{4 * math.pi * (k / 20) / (eps ** 2 + 4 * math.pi ** 2 * (k / 20) ** 2):6.3f}" for k in range(1, 21)))
print("chart, 1/(pi xi)   " + " ".join(f"{1 / (math.pi * k / 20):6.3f}" for k in range(1, 21)))
print("ALL CHECKS PASS")
