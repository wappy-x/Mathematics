# Hadamard factorization -- the check behind the card.  Imports only math.
# sin(pi z) has order 1, so it is e^(az + b) pi z times the product of
# (1 - z^2/n^2); the code finds a = 0 and b = 0, checks the second-derivative
# identity the proof rests on, reads off Wallis, then does the same for xi.
from math import pi, sin, sinh, log, exp, cos
N = 1000

def prod(z, n=N):                    # pi z times the first n paired factors
    p = pi * z
    for k in range(1, n + 1):
        p *= 1 - z * z / (k * k)
    return p * exp(-z * z / (n + 0.5))   # the tail's size, about z^2/(n + 1/2)

def logmax(r, steps=20000):          # largest log|sin(pi z)| on |z| = r, by sampling
    best = 0.0
    for j in range(steps + 1):
        x, y = r * cos(pi * j / steps), r * sin(pi * j / steps)
        best = max(best, 0.5 * log(sin(pi * x) ** 2 + sinh(pi * y) ** 2))
    return best

def zero_sum(z, n=100000):           # minus the sum over every integer of 1/(z - n)^2
    s = sum(1 / (z - k) ** 2 + 1 / (z + k) ** 2 for k in range(1, n + 1))
    return -(1 / z ** 2 + s + 2 / (n + 0.5))

def lgam(x):                         # log Gamma: shift up 8, then Stirling's series
    s = -sum(log(x + k) for k in range(8)); y = x + 8
    return s + (y - 0.5) * log(y) - y + 0.5 * log(2 * pi) + 1 / (12 * y) - 1 / (360 * y ** 3) + 1 / (1260 * y ** 5)

def log_xi(s, n=20):                 # log xi(s), with (s - 1) zeta(s) by Euler-Maclaurin
    t = sum(k ** -s for k in range(1, n)) + n ** -s / 2 + s * n ** (-s - 1) / 12 - s * (s + 1) * (s + 2) * n ** (-s - 3) / 720
    return log(s / 2) + log((s - 1) * t + n ** (1 - s)) - s / 2 * log(pi) + lgam(s / 2)

print(f"log M(r)/r at r = 10, 100: {logmax(10) / 10:.6f}, {logmax(100) / 100:.6f}; closed form {log(sinh(10 * pi)) / 10:.6f}, {log(sinh(100 * pi)) / 100:.6f}")
jb = 10 * exp(1) * pi - log(2) - log(10 * exp(1) * pi)
print(f"zeros of sin(pi z)/(pi z) in |z| <= 10: 20; Jensen's bound {jb:.2f}")
print(f"sum of 1/|n| over 0 < |n| <= {N}: {2 * sum(1 / k for k in range(1, N + 1)):.4f}; of 1/n^2: {2 * sum(1 / k ** 2 for k in range(1, N + 1)):.6f}")
for z in (0.5, 1 / 3):
    print(f"second log-derivative at z = {z:.4f}: -pi^2/sin^2 = {-(pi / sin(pi * z)) ** 2:.6f}, zero sum = {zero_sum(z):.6f}")
a = (log(sin(0.7 * pi) / prod(0.7)) - log(sin(0.3 * pi) / prod(0.3))) / 0.4
b = log(sin(0.3 * pi) / prod(0.3)) - 0.3 * a
print(f"fitted from the product at z = 0.3 and 0.7: a = {abs(a):.6f}, e^b = {exp(b):.6f}")
w = [prod(0.5, n) / (pi / 2) * exp(0.25 / (n + 0.5)) for n in (10, 100, 1000)]
print(f"Wallis partial products, N = 10, 100, 1000: {w[0]:.6f}, {w[1]:.6f}, {w[2]:.6f}")
print(f"tail-corrected at N = 1000: {prod(0.5) / (pi / 2):.6f}; 2/pi = {2 / pi:.6f}")
xi1 = exp(log_xi(1.0))
gam = sum(1 / k for k in range(1, 10001)) - log(10000) - 1 / 20000 + 1 / (12 * 10000 ** 2)
B1, B2 = -1 - gam / 2 + log(4 * pi) / 2, -(log_xi(1.001) - log_xi(0.999)) / 0.002
print(f"xi(0) = xi(1) = {xi1:.6f}, so e^A = {xi1:.6f}")
print(f"Euler's constant from 1 + 1/2 + ... + 1/n - ln n: {gam:.6f}")
print(f"B = -1 - gamma/2 + ln(4 pi)/2 = {B1:.6f}; B from the slope of ln xi at 1: {B2:.6f}")
q = exp(sum(log(1 - 0.5 / k) for k in range(1, N + 1)))
print(f"mistake 1, positive zeros only, no e^(z/n): product at 1/2 = {q:.6f} and falling")
print(f"mistake 2, e^z sin(pi z) has the same zeros: at 1/2 it reads {exp(0.5) * sin(pi / 2):.6f}, not 1")
print(f"mistake 3, dropping the pi: z times the product at 1/2 = {0.5 * 2 / pi:.6f}, not 1")
assert abs(logmax(10) - log(sinh(10 * pi))) < 1e-6 and abs(logmax(10 * exp(1)) - log(10 * exp(1) * pi) - jb) < 1e-6
assert abs(zero_sum(0.5) + pi ** 2) < 1e-9 and abs(zero_sum(1 / 3) + 4 * pi ** 2 / 3) < 1e-9
assert abs(a) < 1e-6 and abs(exp(b) - 1) < 1e-6 and abs(prod(0.5) / (pi / 2) - 2 / pi) < 1e-7
assert abs(xi1 - 0.5) < 1e-9 and abs(B1 - B2) < 1e-6 and B1 < 0
print("ALL CHECKS PASS")
