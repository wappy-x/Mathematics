# Sampling and the Dirac comb -- the check behind the card.  Standard library only.
# Digital audio at 44,100 samples a second, and a 20-microsecond click as the probe.
# Roads: a finite comb's DFT summed out against its closed form; Poisson summation,
# samples side against spectrum side; the sampled spectrum summed directly against
# its copies; the click's transform by Simpson's rule against its closed form.
import math

FS = 44100.0                      # samples a second
DT = 1.0 / FS                     # spacing between samples, seconds
WS = 2.0 * math.pi / DT           # copy spacing, rad/s
SIG = 20e-6                       # the click's width, seconds (illustrative)
B = 20000.0                       # top of hearing, Hz

def click(t, s=SIG):              # x(t): peak 1, width s
    return math.exp(-t * t / (2.0 * s * s))

def click_hat(w, s=SIG):          # closed-form transform, seconds
    return s * math.sqrt(2.0 * math.pi) * math.exp(-s * s * w * w / 2.0)

def simpson_hat(w, s=SIG, m=4000):  # the transform by Simpson's rule on [-12s, 12s]
    a, h = -12.0 * s, 24.0 * s / m
    tot = sum((1 if j in (0, m) else 4 if j % 2 else 2) * click(a + j * h, s)
              * math.cos(w * (a + j * h)) for j in range(m + 1))
    return tot * h / 3.0

def sampled(f, dt=DT, s=SIG):     # dt * sum_n x(n dt) e^{-i w n dt}: real, since x is even
    w = 2.0 * math.pi * f
    return dt * sum(click(n * dt, s) * math.cos(w * n * dt) for n in range(-60, 61))

def copies(f, dt=DT, s=SIG):      # sum_k xhat(w - k ws): the comb's prediction
    w, ws = 2.0 * math.pi * f, 2.0 * math.pi / dt
    return sum(click_hat(w - k * ws, s) for k in range(-6, 7))

def alias(f, fs):                 # distance to the nearest multiple of fs
    return abs(f - round(f / fs) * fs)

def dft(v):                       # the DFT written out, real and imaginary parts
    n = len(v)
    return [(sum(v[j] * math.cos(2 * math.pi * j * k / n) for j in range(n)),
             -sum(v[j] * math.sin(2 * math.pi * j * k / n) for j in range(n))) for k in range(n)]

def ints(z):
    return " ".join(str(round(c[0])) for c in z)

print("== audio at 44,100 samples a second ==")
print(f"spacing dt = {DT * 1e6:.6f} microseconds")
print(f"copy spacing 2 pi / dt = {WS:.4f} rad/s = {WS / (2 * math.pi):.0f} Hz")
print(f"Nyquist frequency {FS / 2:.0f} Hz; rate needed for a {B:.0f} Hz band {2 * B:.0f} Hz")
print(f"first copy of the band starts at {FS - B:.0f} Hz; guard gap {FS - 2 * B:.0f} Hz")
tone = [abs(math.cos(2 * math.pi * 30000 * n * DT) - math.cos(2 * math.pi * alias(30000, FS) * n * DT))
        for n in range(50)]
print(f"30000 Hz tone aliases to {alias(30000, FS):.0f} Hz; largest sample difference {max(tone):.9f}")
assert alias(30000, FS) == 14100 and max(tone) < 1e-9

print("== finite rehearsal: a 12-point grid ==")
for sp in (3, 4):
    c = dft([1.0 if j % sp == 0 else 0.0 for j in range(12)])
    closed = [12 // sp if k % (12 // sp) == 0 else 0 for k in range(12)]
    print(f"DFT of comb spacing {sp}: {ints(c)}")
    assert all(abs(c[k][0] - closed[k]) < 1e-9 and abs(c[k][1]) < 1e-9 for k in range(12))
tone12 = [math.cos(2 * math.pi * 5 * j / 12) for j in range(12)]
X = dft(tone12)
Y = dft([tone12[j] if j % 3 == 0 else 0.0 for j in range(12)])
Yc = [sum(X[(k - 4 * r) % 12][0] for r in range(3)) / 3 for k in range(12)]
print(f"tone at bin 5, every 3rd point kept, DFT direct: {ints(Y)}")
print(f"same from copies (1/3) sum X[k - 4r]:          {ints([(v, 0) for v in Yc])}")
print(f"kept points heard at bin 5 mod 4 = {5 % 4}")
assert all(abs(Y[k][0] - Yc[k]) < 1e-9 for k in range(12))

print("== the comb's transform has no values ==")
Ns = (1, 2, 11, 100)
for f in (0.0, FS / 2):
    d = [sum(math.cos(2 * math.pi * f * n * DT) for n in range(-N, N + 1)) for N in Ns]
    print(f"partial sum at {f:.0f} Hz, N = 1 2 11 100: " + " ".join(f"{v:.3f}" for v in d))
    want = [2 * N + 1 if f == 0.0 else (-1) ** N for N in Ns]
    assert all(abs(d[i] - want[i]) < 1e-9 for i in range(4))

print("== tested on the 20-microsecond click: Poisson summation ==")
left = [sum(click(n * DT) for n in range(-N, N + 1)) for N in range(8)]
right = [sum(click_hat(k * WS) for k in range(-K, K + 1)) / DT for K in (0, 1)]
print("samples side, N = 0..7: " + " ".join(f"{v:.9f}" for v in left))
print(f"spectrum side, K = 0 and 1: {right[0]:.12f} {right[1]:.12f}")
print(f"copy weight xhat(ws) / xhat(0) = {click_hat(WS) / click_hat(0):.12f}")
assert abs(left[7] - right[1]) < 1e-12
assert abs(left[2] - right[1]) > 1e-3 and abs(right[0] - right[1]) > 1e-7

print("== sampled spectrum of the click, microseconds ==")
for f in (0.0, 10000.0, FS / 2):
    tr, sa, co, si = click_hat(2 * math.pi * f), sampled(f), copies(f), simpson_hat(2 * math.pi * f)
    print(f"f = {f:.0f} Hz: true {tr * 1e6:.6f} Simpson {si * 1e6:.6f} sampled {sa * 1e6:.6f} "
          f"copies {co * 1e6:.6f} ratio {sa / tr:.6f}")
    assert abs(tr - si) < 1e-15 and abs(sa - co) < 1e-15
assert abs(sampled(FS / 2) / click_hat(math.pi * FS) - 2) < 1e-6

print("== what breaks ==")
d8 = 1 / 8000.0
print(f"click sampled 8000 a second: sampled at 0 Hz {sampled(0, d8) * 1e6:.6f} vs true {click_hat(0) * 1e6:.6f}")
print(f"omega weight 2 pi / dt with hertz copies: sum reads {2 * math.pi * left[7]:.6f} not {left[7]:.6f}")
print(f"20000 Hz band at 32000 a second: copy starts {32000 - B:.0f} Hz, overlap {2 * B - 32000:.0f} Hz")
assert abs(sampled(0, d8) - copies(0, d8)) < 1e-12 and sampled(0, d8) > 2 * click_hat(0)

print("== try changing ==")
print(f"40000 Hz tone at 44100: heard at {alias(40000, FS):.0f} Hz")
print(f"at 48000: copy starts {48000 - B:.0f} Hz; 30000 Hz tone heard at {alias(30000, 48000):.0f} Hz")
print(f"10-microsecond click: copy weight {click_hat(WS, 10e-6) / click_hat(0, 10e-6):.12f}")

fk = [4.41 * i for i in range(21)]
print("chart, f kHz: " + " ".join(f"{v:.2f}" for v in fk))
print("chart, true: " + " ".join(f"{click_hat(2 * math.pi * v * 1e3) * 1e6:.2f}" for v in fk))
print("chart, sampled: " + " ".join(f"{sampled(v * 1e3) * 1e6:.2f}" for v in fk))
print("figure, sample heights n = 0..3: " + " ".join(f"{click(n * DT):.4f}" for n in range(4))
      + f"; copies centred at 0, {FS / 1e3:.1f}, {2 * FS / 1e3:.1f} kHz")
print("ALL CHECKS PASS")
