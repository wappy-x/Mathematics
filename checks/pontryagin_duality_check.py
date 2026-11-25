# Pontryagin duality -- the check behind the card.  Standard library only, and
# only cmath and math from it.  Four groups with their duals: the 12-hour clock
# Z/12, the circle, the integers Z and the line R.  Every transform is written out.
import cmath, math
PI, N = math.pi, 12

def fx(x, d=6):                                  # fixed decimals, no "-0"
    return f"{0.0 if abs(x) < 0.5 * 10 ** -d else x:.{d}f}"

def fc(z):
    return f"{fx(z.real)} {'-' if z.imag < -5e-7 else '+'} {fx(abs(z.imag))}i"

def simpson(g, a, b, m):                         # Simpson's rule, m even
    h = (b - a) / m
    s = g(a) + g(b) + sum((4 if j % 2 else 2) * g(a + j * h) for j in range(1, m))
    return s * h / 3

def chi(k, x):                                   # character k of the clock at hour x
    return cmath.exp(2j * PI * k * x / N)

def dft(f):                                      # f-hat(k): sum over hours, counting measure
    return [sum(f[x] * chi(k, x).conjugate() for x in range(N)) for k in range(N)]

# 1. The clock's dual: a character is fixed by z = chi(1), and z^12 must be 1.
roots = [cmath.exp(2j * PI * k / N) for k in range(N)]
print(f"clock: characters found {len(roots)}; chi_1 at hour 3 = {fc(chi(1, 3))}; chi_2 at hour 3 = {fc(chi(2, 3))}")
mult = max(abs(chi(a, x) * chi(b, x) - chi((a + b) % N, x)) for a in range(N) for b in range(N) for x in range(N))
print(f"chi_a times chi_b = chi_(a+b), largest gap {fx(mult, 12)}")
# 2. The double dual: a character psi of the dual is fixed by w = psi(chi_1), w^12 = 1;
# find for each such psi the one hour x with chi_k(x) = w^k for every k.
match = []
for w in roots:
    hits = [x for x in range(N) if max(abs(chi(k, x) - w ** k) for k in range(N)) < 1e-9]
    match.append(hits)
print(f"double dual: {len(match)} characters of the dual, each equal to evaluation at hours {[h[0] for h in match]}")
sep = [abs(chi(1, x) - 1) for x in range(1, N)]
print(f"characters separate hours: smallest |chi_1(x) - 1| over x = 1..11 is {fx(min(sep))}")
# 3. The clock inside the circle: marks at angle 2 pi x / 12.
marks = [2 * PI * x / N for x in range(N)]
gap13 = max(abs(cmath.exp(13j * a) - cmath.exp(1j * a)) for a in marks)
ann = [n for n in range(-30, 31) if max(abs(cmath.exp(1j * n * a) - 1) for a in marks) < 1e-9]
print(f"circle characters on the 12 marks: e^(13ix) minus e^(ix), largest gap {fx(gap13, 12)}; annihilator in Z, |n| <= 30: {ann}")
# 4. The line's characters: chi(t) = e^(2 pi i xi t) with xi = 0.5 Hz, rebuilt from
# chi(delta) and the integral over [0, delta], as in Step 2.
xi, dl = 0.5, 0.3
c = simpson(lambda t: cmath.exp(2j * PI * xi * t), 0, dl, 200)
a = (cmath.exp(2j * PI * xi * dl) - 1) / c
print(f"line: chi'(0) rebuilt from chi(0.3) and its integral = {fc(a)}, and 2 pi xi = {fx(2 * PI * xi)}")
# 5. Plancherel and inversion on each pair.
f = list(range(N))
F = dft(f)
e_g, e_d = sum(v * v for v in f), sum(abs(v) ** 2 for v in F) / N
inv = max(abs(sum(F[k] * chi(k, x) for k in range(N)) / N - f[x]) for x in range(N))
print(f"Z/12, f(x) = x: energy on the clock {e_g}; on the dual, weight 1/12 each: {fx(e_d)}; inversion error {fx(inv, 12)}")
print(f"  f-hat(0) = {fx(F[0].real)}, its share {fx(abs(F[0]) ** 2 / N)}; f-hat(4) = {fc(F[4])}; f-hat(8) = {fc(F[8])}")
M = 20000
saw = sum(((j + 0.5) * 2 * PI / M - PI) ** 2 for j in range(M)) / M
c3 = sum(x * cmath.exp(-3j * x) for x in [(j + 0.5) * 2 * PI / M - PI for j in range(M)]) / M
K = 100000
basel = 2 * sum(1 / (n * n) for n in range(1, K + 1))
print(f"circle, f(x) = x: f-hat(3) = {fc(c3)}; energy (1/2 pi) int x^2 dx = {fx(saw)}; pi^2/3 = {fx(PI * PI / 3)}")
print(f"  on Z: sum of 1/n^2 over 0 < |n| <= {K} = {fx(basel, 9)}; gap {fx(PI * PI / 3 - basel, 9)}, tail bound 2/{K} = {fx(2 / K, 9)}")
cz = 2 * sum(0.25 ** n for n in range(1, 61)) + 1
P = lambda x: 0.75 / (1.25 - math.cos(x))
ez = sum(P(2 * PI * j / 64) ** 2 for j in range(64)) / 64
c3z = sum(P(2 * PI * j / 64) * math.cos(3 * 2 * PI * j / 64) for j in range(64)) / 64
print(f"Z, c_n = 2^-|n|: energy {fx(cz, 12)}; on the circle, 64 points: {fx(ez, 12)}; c_3 rebuilt = {fx(c3z, 12)}")
fl = simpson(lambda t: math.exp(-2 * abs(t)), -40, 40, 80000)
fh = simpson(lambda t: math.exp(-abs(t)) * math.cos(2 * PI * xi * t), -40, 40, 80000)
X = 100.0
fhe = simpson(lambda s: (2 / (1 + 4 * PI * PI * s * s)) ** 2, -X, X, 200000)
print(f"R, f(t) = e^-|t|: energy {fx(fl, 9)}; f-hat(0.5) by the integral {fx(fh, 9)}, by 2/(1 + pi^2) {fx(2 / (1 + PI * PI), 9)}")
print(f"  energy of f-hat on |xi| <= {X:.0f} Hz: {fx(fhe, 9)}; tail bound 1/(6 pi^4 X^3) = {fx(1 / (6 * PI ** 4 * X ** 3), 12)}")
# 6. The Fourier transform turns convolution into multiplication (Gelfand).
g = [1 if x % 3 == 0 else 0 for x in range(N)]
conv = [sum(f[y] * g[(x - y) % N] for y in range(N)) for x in range(N)]
G, C = dft(g), dft(conv)
print(f"clock convolution: (f * g)-hat minus f-hat g-hat, largest gap {fx(max(abs(C[k] - F[k] * G[k]) for k in range(N)), 9)}")
# 7. Poisson summation: a subgroup H and its annihilator.
gs = lambda x: math.exp(-PI * x * x)
def ghat(s):                                     # trapezoid, step 1/16 on [-8, 8]
    return sum(gs(j / 16) * math.cos(2 * PI * s * j / 16) for j in range(-128, 129)) / 16
lhs = sum(gs(n) for n in range(-6, 7))
rhs = sum(ghat(k) for k in range(-6, 7))
print(f"Poisson, H = Z in R: sum of e^(-pi n^2), |n| <= 6 = {lhs:.14f}; tail below {3 * math.exp(-49 * PI):.1e}")
print(f"  sum over the annihilator Z of f-hat(k), each by the integral = {rhs:.14f}; gap {fx(abs(lhs - rhs), 12)}")
l2 = 2 * sum(gs(2 * n) for n in range(-6, 7))
r2 = sum(ghat(k / 2) for k in range(-12, 13))
print(f"Poisson, H = 2Z: 2 x sum of f(2n) = {l2:.12f}; sum over (1/2)Z of f-hat = {r2:.12f}")
H = [0, 3, 6, 9]
Hp = [k for k in range(N) if all(abs(chi(k, h) - 1) < 1e-9 for h in H)]
ps = sum(F[k] for k in Hp) * len(H) / N
print(f"Poisson on the clock: H = {H}, annihilator {Hp}; sum of f on H = {sum(f[h] for h in H)}; |H|/12 x sum of f-hat there = {fc(ps)}")
# 8. What breaks.
print(f"mistake 1, counting measure on both sides: dual energy {fx(e_d * N)}, not {e_g}")
print(f"mistake 2, all of Z as the clock's dual, k = 0..23: dual energy {fx(sum(abs(F[k % N]) ** 2 for k in range(24)) / N)}")
print(f"mistake 3, no weight 2 on the points of 2Z: {l2 / 2:.12f}, not {r2:.12f}")
# S3, the six shuffles of three things, is not abelian: its characters
# send r (a 3-cycle) and s (a swap) to sixth roots with r^3 = s^2 = 1, s r s = r^-1.
six = [cmath.exp(2j * PI * k / 6) for k in range(6)]
s3 = [(u, v) for u in six for v in six if abs(u ** 3 - 1) < 1e-9 and abs(v * v - 1) < 1e-9 and abs(v * u * v - 1 / u) < 1e-9]
print(f"mistake 4, S3 is not abelian: characters found {len(s3)} for 6 members; delta at a swap: energy 1, dual energy {fx(len(s3) / 6)}")
assert len(set(h[0] for h in match)) == N and all(len(h) == 1 for h in match)      # double dual
assert ann == [-24, -12, 0, 12, 24] and abs(a - 2j * PI * xi) < 1e-9 and min(sep) > 0.5
assert abs(e_d - 506) < 1e-9 and inv < 1e-9 and abs(c3 - 1j * (-1) ** 3 / 3) < 1e-6
assert abs(saw - PI * PI / 3) < 1e-6 and 0 < PI * PI / 3 - basel < 2 / K
assert abs(ez - 5 / 3) < 1e-12 and abs(cz - 5 / 3) < 1e-12 and abs(c3z - 0.125) < 1e-12
assert abs(fh - 2 / (1 + PI * PI)) < 1e-9 and abs(fl - 1) < 1e-9 and abs(fhe + 1 / (6 * PI ** 4 * X ** 3) - 1) < 1e-9
assert abs(lhs - rhs) < 1e-15 and abs(l2 - r2) < 1e-14 and Hp == [0, 4, 8] and abs(ps - 18) < 1e-9
assert len(s3) == 2
print("ALL CHECKS PASS")
