# Fourier coefficients and orthogonality -- the check behind the card.
# Standard library only. Complex numbers are Python's own; every integral is
# a midpoint sum written out, and every closed form is coded separately.
import math, cmath

PI = math.pi
F = 220.0              # cycles a second: the siren flips 440 times a second
P = 1.0 / F            # one period, in seconds

def fx(x):             # print x to 6 decimals, never "-0.000000"
    return f"{(0.0 if abs(x) < 5e-7 else x):.6f}"

def cx(z):
    return f"{fx(z.real)} {'-' if z.imag < -5e-7 else '+'} {fx(abs(z.imag))}i"

def pulse(t, d):       # +1 V for the first fraction d of each period, -1 V after
    return 1.0 if (t / P) % 1.0 < d else -1.0

def coef_t(sig, n, M, T=P, nu=None):
    # (1/T) * integral over [0, T) of sig(t) e^(-2 pi i nu t) dt, M midpoint slices
    nu = n / P if nu is None else nu
    h = T / M
    s = sum(sig((k + 0.5) * h) * cmath.exp(-2j * PI * nu * (k + 0.5) * h) for k in range(M))
    return s * h / T

def coef_exact(n, d):  # closed form for the pulse of duty d
    if n == 0:
        return complex(2 * d - 1, 0)
    return (1 - cmath.exp(-2j * PI * n * d)) / (1j * PI * n)

def real_ab(sig, n, M):  # a_n, b_n from their own real integrals over one period
    h = P / M
    a = sum(sig((k + .5) * h) * math.cos(2 * PI * n * (k + .5) * h / P) for k in range(M))
    b = sum(sig((k + .5) * h) * math.sin(2 * PI * n * (k + .5) * h / P) for k in range(M))
    return 2 * a * h / P, 2 * b * h / P

print(f"period P = 1/220 s = {fx(P * 1000)} ms; flips a second = {2 * F:.0f}")

# ---- road check: the square wave, b_n = 4/(pi n) for odd n ----
sq = lambda t: pulse(t, 0.5)
print("square wave n, b_n numeric, 4/(pi n)")
for n in (1, 2, 3, 5):
    a, b = real_ab(sq, n, 40000)
    want = 4 / (PI * n) if n % 2 else 0.0
    print(f"  {n} {fx(b)} {fx(want)}  a_n {fx(a)}")
    assert abs(b - want) < 1e-5 and abs(a) < 1e-9

# ---- orthonormality: <e_m, e_n> = (1/2pi) int e^(imx) e^(-inx) dx ----
def inner(m, n, M=4000):
    h = 2 * PI / M      # x runs over -pi <= x < pi
    xs = [-PI + (k + .5) * h for k in range(M)]
    return sum(cmath.exp(1j * m * x) * cmath.exp(-1j * n * x) for x in xs) * h / (2 * PI)
worst = max(abs(inner(m, n) - (1 if m == n else 0)) for m in range(-3, 4) for n in range(-3, 4))
print(f"gram matrix n = -3..3: largest gap from identity {fx(worst)}")
assert worst < 1e-9
leak = inner(1.5, 1, 200000)
print(f"<e^(1.5ix), e^(ix)> = {cx(leak)} (closed form 2/pi = {fx(2 / PI)})")
assert abs(leak - 2 / PI) < 1e-6

# ---- the worked signal: 25% pulse, +1 V for 1.136 ms, -1 V for 3.409 ms ----
D = 0.25
print(f"pulse high for {fx(D * P * 1000)} ms, low for {fx((1 - D) * P * 1000)} ms")
print("n, Hz, c_n closed form, error at M=400, error at M=4000")
for n in range(0, 9):
    c = coef_exact(n, D)
    e1, e2 = abs(coef_t(lambda t: pulse(t, D), n, 400) - c), abs(coef_t(lambda t: pulse(t, D), n, 4000) - c)
    print(f"  {n} {n * 220} {cx(c)} {e1:.9f} {e2:.9f}")
    assert e2 < e1 / 50 or e1 < 1e-12
    assert e2 < 1e-6
print("n, a_n, b_n from real integrals, 2 Re c_n, -2 Im c_n, amplitude 2|c_n|")
for n in (1, 2, 3, 4):
    a, b = real_ab(lambda t: pulse(t, D), n, 4000)
    c = coef_exact(n, D)
    print(f"  {n} {fx(a)} {fx(b)} {fx(2 * c.real)} {fx(-2 * c.imag)} {fx(2 * abs(c))}")
    assert abs(a - 2 * c.real) < 1e-6 and abs(b + 2 * c.imag) < 1e-6
c1 = coef_exact(1, D)
peak = -cmath.phase(c1) / (2 * PI) * P * 1000
print(f"220 Hz share: |c_1| = {fx(abs(c1))}, 2 sin(pi d)/pi = {fx(2 * math.sin(PI * D) / PI)}, crest at t = {fx(peak)} ms")
assert abs(abs(c1) - 2 * math.sin(PI * D) / PI) < 1e-12 and abs(peak - D * P * 1000 / 2) < 1e-9

# ---- Pythagoras on a finite sum: ||S_3||^2 = sum |c_n|^2 ----
cs = {n: coef_exact(n, D) for n in range(-3, 4)}
S3 = lambda x: sum(cs[n] * cmath.exp(1j * n * x) for n in cs)
M = 4000
norm2 = sum(abs(S3(2 * PI * (k + .5) / M)) ** 2 for k in range(M)) / M
shares = sum(abs(c) ** 2 for c in cs.values())
print(f"||S_3||^2 by integral {fx(norm2)}, sum of |c_n|^2 {fx(shares)}, ||f||^2 = 1")
assert abs(norm2 - shares) < 1e-9 and shares < 1

# ---- what breaks ----
print(f"1/pi in the complex formula: |c_1| = {fx(2 * abs(c1))}, right {fx(abs(c1))}")
cp = coef_exact(-1, D)   # e^(+inx) reads off c_(-n), the conjugate
print(f"e^(+ix) instead of e^(-ix): b_1 = {fx(-2 * cp.imag)}, right {fx(-2 * c1.imag)}")
W = 0.004               # a 4 ms window: not a whole number of periods
wT = 2 * PI * F * W     # exact over [0, W): a_1 = -2 sin(wT)/wT, b_1 = 2 (3 + cos wT)/wT
aw, bw = -2 * math.sin(wT) / wT, 2 * (3 + math.cos(wT)) / wT
cw = [coef_t(sq, 1, M, T=W, nu=F) for M in (440, 4400)]   # the jump at P/2 lands on a slice edge
ew = [abs(complex(2 * c.real, -2 * c.imag) - complex(aw, bw)) for c in cw]
print(f"square wave over 4 ms: a_1 = {fx(aw)}, b_1 = {fx(bw)}, right 0, {fx(4 / PI)}")
print(f"  4 ms window, midpoint error at M=440 {ew[0]:.9f}, at M=4400 {ew[1]:.9f}")
assert ew[1] < ew[0] / 50 and ew[1] < 1e-6
assert abs(-2 * cw[1].imag - 4 / PI) > 0.05
for eps in (1e-3, 1e-6):
    print(f"1/|x| mean, cut at {eps:.6f}: (1/pi) log(pi/eps) = {fx(math.log(PI / eps) / PI)}")
print(f"on-off 0..1 V wave: mean {fx(0.5)}, b_1 = {fx(2 / PI)}, right for +-1 V {fx(4 / PI)}")
print(f"12.5% pulse: c_0 = {fx(coef_exact(0, .125).real)}, |c_8| = {fx(abs(coef_exact(8, .125)))}, |c_4| = {fx(abs(coef_exact(4, .125)))}")

# ---- pictures ----
print("chart t ms: " + " ".join(f"{(k + .5) * P * 1000 / 16:.2f}" for k in range(16)))
print("chart pulse: " + " ".join(f"{pulse((k + .5) * P / 16, D):.0f}" for k in range(16)))
print("chart S_3: " + " ".join(f"{S3(2 * PI * (k + .5) / 16).real:.2f}" for k in range(16)))
for n in range(1, 9):
    aq = 4 / (PI * n) if n % 2 else 0.0
    ap = 2 * abs(coef_exact(n, D))
    print(f"bars {n * 220} Hz square {fx(aq)} pulse {fx(ap)}")
print("ALL CHECKS PASS")
