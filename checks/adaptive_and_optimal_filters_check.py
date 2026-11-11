# Wiener and LMS -- the check behind the card.  Standard library only.  Nothing imported knows
# the answer: the random numbers, the 2x2 solve and both filters are written out below.
# A hands-free microphone hears a voice plus engine noise; a second microphone at the engine
# hears the noise alone.  A two-tap filter turns the second signal into the first one's noise.
from math import sqrt, log10

FS, SECONDS = 8000, 10                      # samples per second, length of the recording
N = FS * SECONDS
H = (0.8, 0.4)                              # the path from engine to cabin microphone, unknown to the filter
A = 0.5                                     # the voice: a random signal of power A*A = 0.25
MU = 0.01                                   # the LMS step size

def rng(seed):                              # xorshift64, scaled to uniform on [-sqrt 3, sqrt 3]: power 1
    s = seed
    while True:
        s ^= (s << 13) & 0xFFFFFFFFFFFFFFFF; s ^= s >> 7; s ^= (s << 17) & 0xFFFFFFFFFFFFFFFF
        yield ((s >> 11) / 9007199254740992.0 * 2.0 - 1.0) * sqrt(3.0)

def recording():                            # x: engine mic, d: cabin mic, s: the voice alone
    g, talk = rng(2026), rng(7)             # engine and voice come from separate generators
    u_prev = next(g); x, d, s = [(u_prev + next(g)) / sqrt(2.0)], [0.0], [0.0]   # x[0] is x[-1]
    u_prev = next(g)
    for n in range(N):                      # list index n + 1 holds sample n
        u = next(g); xn = (u + u_prev) / sqrt(2.0); u_prev = u   # smooth rumble: neighbours alike
        sn = A * next(talk)
        x.append(xn); s.append(sn); d.append(sn + H[0] * xn + H[1] * x[-2])
    return x, d, s

def solve2(a, b, c, e, f):                  # [[a, b], [c, e]] w = f, by Cramer's rule
    det = a * e - b * c
    return ((f[0] * e - b * f[1]) / det, (a * f[1] - c * f[0]) / det)

def cost(w, r0, r1, p, sd2):                # the bowl J(w) = E[d^2] - 2 p.w + w.R w
    return sd2 - 2 * (p[0] * w[0] + p[1] * w[1]) + r0 * (w[0] * w[0] + w[1] * w[1]) + 2 * r1 * w[0] * w[1]

def steepest(mu, steps, r0, r1, p):         # road 3: walk downhill on the exact bowl
    w = [0.0, 0.0]
    for _ in range(steps):
        g0 = p[0] - r0 * w[0] - r1 * w[1]; g1 = p[1] - r1 * w[0] - r0 * w[1]
        w = [w[0] + mu * g0, w[1] + mu * g1]
    return w

def lms(x, d, s, mu, sign=1.0, stop=N, marks=()):   # road 4: learn sample by sample
    w0 = w1 = 0.0; out, err2, left2, avg0, avg1 = {}, 0.0, 0.0, 0.0, 0.0
    for n in range(stop):
        if n in marks: out[n] = (w0, w1)
        e = d[n + 1] - (w0 * x[n + 1] + w1 * x[n])  # the output: voice plus leftover noise
        if n >= stop - FS:                  # score the last second
            err2 += e * e; left2 += (e - s[n + 1]) * (e - s[n + 1]); avg0 += w0; avg1 += w1
        w0 += sign * mu * e * x[n + 1]; w1 += sign * mu * e * x[n]
    return (w0, w1), (avg0 / FS, avg1 / FS), err2 / FS, left2 / FS, out

r0, r1, voice = 1.0, 0.5, A * A             # engine noise: power 1, next-sample correlation 0.5
p = (H[0] * r0 + H[1] * r1, H[0] * r1 + H[1] * r0)       # E[d x(n)], E[d x(n-1)]
noise = r0 * (H[0] * H[0] + H[1] * H[1]) + 2 * r1 * H[0] * H[1]  # h.R h, engine noise reaching the cabin mic
sd2 = voice + noise
w_ex = solve2(r0, r1, r1, r0, p)
j_ex = cost(w_ex, r0, r1, p, sd2)
x, d, s = recording()
sxx = sum(v * v for v in x[1:]); sx1 = sum(x[n + 1] * x[n] for n in range(N)); s11 = sum(v * v for v in x[:-1])
pd0 = sum(d[n + 1] * x[n + 1] for n in range(N)); pd1 = sum(d[n + 1] * x[n] for n in range(N))
w_dat = solve2(sxx, sx1, sx1, s11, (pd0, pd1))           # road 2: least squares on the recording
mic_noise = sum((d[n + 1] - s[n + 1]) * (d[n + 1] - s[n + 1]) for n in range(N)) / N
e_true = [d[n + 1] - (H[0] * x[n + 1] + H[1] * x[n]) for n in range(N)]
orth0 = sum(e_true[n] * x[n + 1] for n in range(N)) / N; orth1 = sum(e_true[n] * x[n] for n in range(N)) / N
w_sd = steepest(0.5, 60, r0, r1, p)
marks = (0, 50, 100, 200, 400, 800, 1600)
w_end, w_avg, mse, left, path = lms(x, d, s, MU, marks=marks)
misadj = MU * (r0 + r0) / 2                 # mu * trace(R) / 2
fast, slow = r0 + r1, r0 - r1               # eigenvalues of R: along (1, 1) and along (1, -1)
print(f"setup: {FS} samples/s, {SECONDS} s = {N} samples, engine path h = ({H[0]:.1f}, {H[1]:.1f})")
print(f"R = [[{r0:.4f}, {r1:.4f}], [{r1:.4f}, {r0:.4f}]]   eigenvalues {fast:.4f}, {slow:.4f}   trace {r0 + r0:.4f}")
print(f"p = ({p[0]:.4f}, {p[1]:.4f})   determinant of R {r0 * r0 - r1 * r1:.4f}")
print(f"power: voice {voice:.4f}   engine noise at mic {noise:.4f}   mic total {sd2:.4f}")
print(f"measured engine noise at mic over 10 s {mic_noise:.4f}")
print(f"hand: h.R h = {r0 * H[0] * H[0]:.4f} + {r0 * H[1] * H[1]:.4f} + {2 * r1 * H[0] * H[1]:.4f}   Cramer tops {p[0] * r0 - r1 * p[1]:.4f}, {r0 * p[1] - r1 * p[0]:.4f}")
print(f"hand: p.w {p[0] * w_ex[0] + p[1] * w_ex[1]:.4f}   step bound 2/lmax {2 / fast:.4f}   decay per sample {1 - MU * fast:.4f}, {1 - MU * slow:.4f}   misadjustment {misadj:.4f}")
print(f"road 1 Wiener from the statistics    w = ({w_ex[0]:.4f}, {w_ex[1]:.4f})   Jmin {j_ex:.4f}")
print(f"road 2 Wiener from the 10 s of data  w = ({w_dat[0]:.4f}, {w_dat[1]:.4f})")
print(f"  orthogonality, true w: E[e x(n)] {orth0:+.4f}   E[e x(n-1)] {orth1:+.4f}")
print(f"road 3 steepest descent, mu 0.5, 60 steps  w = ({w_sd[0]:.6f}, {w_sd[1]:.6f})")
print(f"road 4 LMS, mu {MU}: last sample w = ({w_end[0]:.4f}, {w_end[1]:.4f})   last-second mean ({w_avg[0]:.4f}, {w_avg[1]:.4f})")
print(f"  output power, last second {mse:.4f}   predicted Jmin (1 + mu trR/2) {j_ex * (1 + misadj):.4f}")
print(f"  noise left in output {left:.4f}   predicted {j_ex * misadj:.4f}")
print(f"  SNR at mic {10 * log10(voice / noise):.2f} dB   after LMS {10 * log10(voice / left):.2f} dB")
print(f"  time constants: fast {1 / (MU * fast):.2f} samples = {1000 / (MU * fast) / FS:.2f} ms   slow {1 / (MU * slow):.2f} samples = {1000 / (MU * slow) / FS:.2f} ms")
print(f"wrong: one tap, w = {p[0] / r0:.4f}   J {cost((p[0] / r0, 0.0), r0, r1, p, sd2):.4f}")
print(f"wrong: taps solved separately, w = ({p[0] / r0:.4f}, {p[1] / r0:.4f})   J {cost((p[0] / r0, p[1] / r0), r0, r1, p, sd2):.4f}")
w_big = steepest(1.4, 40, r0, r1, p)
print(f"wrong: mu 1.4 > 2/1.5, factor {1 - 1.4 * fast:.2f}, 40 steps   w = ({w_big[0]:.2f}, {w_big[1]:.2f})")
w_flip = lms(x, d, s, MU, sign=-1.0, stop=1000)[0]
print(f"wrong: LMS sign flipped, 1000 samples   w = ({w_flip[0]:.0f}, {w_flip[1]:.0f})")
print("learning:  sample     ms   LMS w0  LMS w1   mean w0  mean w1   fast gap  slow gap")
for n in marks:
    m = steepest(MU, n, r0, r1, p)
    gf = (w_ex[0] + w_ex[1]) * (1 - MU * fast) ** n; gs = (w_ex[0] - w_ex[1]) * (1 - MU * slow) ** n
    print(f"  {n:>14} {1000 * n / FS:>6.2f} {path[n][0]:>8.4f} {path[n][1]:>7.4f} {m[0]:>9.4f} {m[1]:>8.4f} {gf:>10.4f} {gs:>9.4f}")
    assert abs(m[0] + m[1] + gf - 1.2) < 1e-9 and abs(m[0] - m[1] + gs - 0.4) < 1e-9, "modes"
for mu in (0.05, 0.001):
    t = lms(x, d, s, mu)
    print(f"try: mu {mu}: last-second mean w = ({t[1][0]:.4f}, {t[1][1]:.4f})   output power {t[2]:.4f} (predicted {j_ex * (1 + mu * r0):.4f})   slow time constant {1000 / (mu * slow) / FS:.2f} ms")

assert abs(w_ex[0] - 0.8) < 1e-12 and abs(w_ex[1] - 0.4) < 1e-12, "Wiener must recover the path"
assert abs(j_ex - voice) < 1e-12,                "with the path matched, only the voice is left"
assert abs(mic_noise - noise) < 0.03,            "simulated noise power vs h.R h"
assert max(abs(w_dat[0] - 0.8), abs(w_dat[1] - 0.4)) < 0.02, "data road lands on the statistics road"
assert max(abs(w_sd[0] - w_ex[0]), abs(w_sd[1] - w_ex[1])) < 1e-6, "steepest descent reaches the bottom"
assert max(abs(w_avg[0] - 0.8), abs(w_avg[1] - 0.4)) < 0.02, "LMS learns the path"
assert abs(left - j_ex * misadj) < 0.001,        "noise left in output vs the misadjustment rule"
assert abs(w_big[0]) > 10 and abs(w_flip[0]) > 1e3, "unstable steps must blow up"
print("ALL CHECKS PASS")
