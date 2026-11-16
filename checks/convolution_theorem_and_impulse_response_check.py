# The convolution theorem and the hall's echo -- the check behind the card.
# Standard library only. Every transform, echo sum and blend is written out here.
from math import cos, sin, exp, pi, atan2, degrees, log
A, T, SIG = 0.5, 0.05, 1e-4           # echo strength, echo delay (s), clap width (s, standard deviation)
LO, HI = -0.025, 0.175                # the recording window w: 1 from LO to HI seconds, 0 outside
L, MID = HI - LO, (LO + HI) / 2       # window length 0.2 s, window centre 0.075 s

def cmul(p, q): return (p[0] * q[0] - p[1] * q[1], p[0] * q[1] + p[1] * q[0])
def turn(x): return (cos(x), sin(x))                       # e^(ix)
def size(p): return (p[0] ** 2 + p[1] ** 2) ** 0.5
def hhat(xi, a=A, d=T):                                    # frequency response, closed form 1/(1 - a e^(-2 pi i xi d))
    re, im = 1 - a * cos(2 * pi * xi * d), a * sin(2 * pi * xi * d)
    m = re * re + im * im
    return (re / m, -im / m)
def chat(xi, s=SIG): return exp(-2 * pi * pi * s * s * xi * xi)   # transform of the clap bump, area 1
def echo_sum(xi, n, a=A):                                  # first n+1 arrivals: sum of a^k e^(-2 pi i xi k T)
    re = im = 0.0
    for k in range(n + 1):
        re += a ** k * cos(2 * pi * xi * k * T); im -= a ** k * sin(2 * pi * xi * k * T)
    return (re, im)
def show(w):                                           # size and turn, a turn under 0.005 deg printed as 0
    ang = degrees(atan2(w[1], w[0]))
    return f"{size(w):.6f} at {(ang if abs(ang) >= 0.005 else 0.0):+.2f} deg"

# Road 1: play a steady tone in the hall, sample by sample, and measure what reaches the seat.
def tone_gain(xi, a=A, echoes=30, fs=8820):
    D, N = round(T * fs), fs                               # 441 samples between echoes; measure over 1 s
    sx = sy = (0.0, 0.0)
    for n in range(echoes * D, echoes * D + N):
        x = cos(2 * pi * xi * n / fs)
        y = sum(a ** k * cos(2 * pi * xi * (n - k * D) / fs) for k in range(echoes + 1))
        p = turn(-2 * pi * xi * n / fs)
        sx = (sx[0] + x * p[0], sx[1] + x * p[1]); sy = (sy[0] + y * p[0], sy[1] + y * p[1])
    m = sx[0] ** 2 + sx[1] ** 2                            # complex ratio of output to input at xi
    return ((sy[0] * sx[0] + sy[1] * sx[1]) / m, (sy[1] * sx[0] - sy[0] * sx[1]) / m)

# Road 2: the clap recording r(t) = sum a^k c(t - kT), transformed by its defining integral (Simpson).
def rhat_integral(xi, s=SIG, echoes=40, n=200):
    re = im = 0.0
    for k in range(echoes + 1):
        a0, h = k * T - 8 * s, 16 * s / n
        for j in range(n + 1):
            t = a0 + j * h
            wt = (1 if j in (0, n) else 4 if j % 2 else 2) * h / 3
            v = A ** k * exp(-(t - k * T) ** 2 / (2 * s * s)) / (s * (2 * pi) ** 0.5)
            re += wt * v * cos(2 * pi * xi * t); im -= wt * v * sin(2 * pi * xi * t)
    return (re, im)

# Road 3: the reverse direction. The cut recording r.w has transform (rhat * what)(xi), a blend over eta.
def whatf(nu):                                             # transform of the window: e^(-2 pi i nu MID) sin(pi nu L)/(pi nu)
    amp = L if abs(nu) < 1e-12 else sin(pi * nu * L) / (pi * nu)
    p = turn(-2 * pi * nu * MID)
    return (amp * p[0], amp * p[1])
def blend(F, G, xi, M=20000.0, step=0.5):                  # integral of F(eta) G(xi - eta) d eta, trapezoid
    re = im = 0.0
    for j in range(int(2 * M / step) + 1):
        eta = -M + j * step
        q = cmul(F(eta), G(xi - eta))
        wt = step / 2 if j in (0, int(2 * M / step)) else step
        re += wt * q[0]; im += wt * q[1]
    return (re, im)
def rhat(eta): return cmul((chat(eta), 0.0), hhat(eta))

print(f"1 frequency response of the hall (walls {343 * T / 2:.3f} m apart, peaks every {1 / T:.0f} Hz), closed form against a played tone")
for xi in (440, 430, 435):
    print(f"  {xi} Hz  formula {show(hhat(xi))}   tone {show(tone_gain(xi))}")
print("  cycles per echo delay: " + " ".join(f"{xi * T:.2f}" for xi in (440, 430, 435)))
print(f"  h-hat(435) = {hhat(435)[0]:.6f} + {hhat(435)[1]:.6f}i")
print(f"  decay to a thousandth of the clap's size: {T * log(1000) / log(1 / A):.4f} s")
print("  echo build-up, arrivals 0..5:")
for xi in (440, 430):
    print(f"   {xi} Hz " + " ".join(f"{echo_sum(xi, n)[0]:.4f}" for n in range(6)))
print("2 clap recording at 440 Hz: c-hat times h-hat against the defining integral")
print(f"  product {show(rhat(440))}   integral {show(rhat_integral(440))}")
print(f"  c-hat(440) = exp(-{2 * pi * pi * SIG * SIG * 440 * 440:.6f}) = {chat(440):.6f}")
print("  settling as the clap shortens (2 c-hat(440)):")
for s in (1e-3, 3e-4, 1e-4, 3e-5):
    print(f"   width {s * 1000:.2f} ms  {2 * chat(440, s):.6f}")
print(f"3 cut to 0.2 s (window spectrum first zero {1 / L:.1f} Hz, blend over {int(40000 / 0.5) + 1} frequencies)")
print(f"  tail beyond 20000 Hz: clap factor there {chat(20000):.1e}, tail bound {0.8 * chat(20000) / (4 * pi * pi * SIG * SIG * 20000):.1e}")
cut = {}
for xi in (440, 430):
    closed = cmul((chat(xi), 0.0), echo_sum(xi, 3))
    cut[xi] = blend(rhat, whatf, xi)
    print(f"  {xi} Hz  closed {show(closed)}   blend {show(cut[xi])}   full {size(rhat(xi)):.6f}")
print("4 window times itself is itself (L2 only), tails cut beyond 20000 Hz")
gg = {}
for xi in (0.0, 2.5):
    gg[xi] = blend(whatf, whatf, xi)
    print(f"  {xi} Hz  blend {size(gg[xi]):.6f}   what {size(whatf(xi)):.6f}   tail bound {2 / (pi * pi * 20000):.7f}")
print("5 what breaks")
print(f"  echo sizes added, delays ignored, 430 Hz   {echo_sum(0, 40)[0]:.6f}")
print(f"  omega form, reverse without 1/2pi, 440 Hz  {2 * pi * size(cut[440]):.6f}")
print(f"  walls keep everything, 440 Hz after 1 s    {size(echo_sum(440, 20, 1.0)):.6f}")
print(f"  same walls, a = 0.5, after 1 s             {size(echo_sum(440, 20)):.6f}")
print(f"  clap 1 ms wide taken as the kick, 440 Hz   {2 * chat(440, 1e-3):.6f}")
print("6 try changing")
print(f"  a = 0.8: 440 Hz {size(hhat(440, 0.8)):.6f}  430 Hz {size(hhat(430, 0.8)):.6f}")
print(f"  T = 0.1 s (walls {343 * 0.1 / 2:.3f} m apart): 430 Hz {size(hhat(430, A, 0.1)):.6f}")
print(f"  window to 0.375 s (8 arrivals), 440 Hz {size(echo_sum(440, 7)):.6f}")
xs = [400 + 2.5 * j for j in range(33)]
print("chart, hall " + " ".join(f"{size(hhat(x)):.3f}" for x in xs))
print("chart, cut  " + " ".join(f"{size(echo_sum(x, 3)):.3f}" for x in xs))

assert abs(size(hhat(440)) - echo_sum(440, 60)[0]) < 1e-12, "comb peak: closed form against 61 arrivals"
assert abs(size(hhat(430)) - echo_sum(430, 60)[0]) < 1e-12, "comb dip: closed form against 61 arrivals"
for xi in (440, 430, 435):                                  # played tone against the closed form
    g, f = tone_gain(xi), hhat(xi)
    assert size((g[0] - f[0], g[1] - f[1])) < 1e-8, "road 1"
p, q = rhat(440), rhat_integral(440)
assert size((p[0] - q[0], p[1] - q[1])) < 1e-9, "forward theorem on the clap recording"
for xi in (440, 430):
    c = cmul((chat(xi), 0.0), echo_sum(xi, 3))
    assert size((c[0] - cut[xi][0], c[1] - cut[xi][1])) < 1e-6, "reverse theorem, cut recording"
for xi in (0.0, 2.5):
    w = whatf(xi)
    assert size((gg[xi][0] - w[0], gg[xi][1] - w[1])) < 2 / (pi * pi * 20000), "reverse theorem in L2"
assert size(echo_sum(440, 20, 1.0)) > 20, "no absorption: no settling"
print("ALL CHECKS PASS")
