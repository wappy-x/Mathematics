# Limits of holomorphic functions -- the check behind the card.  Standard library only.
# The tower: f(z) = sum of z^n/n^2 over n = 1, 2, 3, ... on the closed unit disc; floor n never
# exceeds M_n = 1/n^2.  Values on the rim: stacked floors against pi^2/6 and -pi^2/12.  Slope inside:
# floors differentiated one by one, against Cauchy's formula on a circle, against -log(1 - z)/z.
import math

def S(z, N):                                   # the first N floors
    return sum(z ** n / n ** 2 for n in range(1, N + 1))
def dS(z, N):                                  # the same floors, each differentiated
    return sum(z ** (n - 1) / n for n in range(1, N + 1))
def show(w):                                   # 'a + bi', six decimals, no -0.000000
    a, b = round(w.real, 6) + 0.0, round(w.imag, 6) + 0.0
    return f"{a:.6f} {'-' if b < 0 else '+'} {abs(b):.6f}i"
def log(w):                                    # principal log from ln|w| and atan2
    return complex(math.log(abs(w)), math.atan2(w.imag, w.real))

N = 1000                                       # rim values: stack 1000 floors, add the tail's size
f1 = S(1, N) + 1 / N - 1 / (2 * N ** 2) + 1 / (6 * N ** 3)
fm1 = (S(-1, 100000) + S(-1, 100001)) / 2      # alternating floors: average two neighbours
print(f"f(1): floors {f1:.6f}, pi^2/6 {math.pi ** 2 / 6:.6f}")
print(f"f(-1): floors {fm1:.6f}, -pi^2/12 {-math.pi ** 2 / 12:.6f}; mistake -f(1) = {-f1:.6f}")
for n in (10, 100, 1000):                      # worst gap on the closed disc sits at z = 1
    print(f"N = {n}: worst gap after N floors {math.pi ** 2 / 6 - S(1, n):.6f}, M-test bound 1/N {1 / n:.6f}")
z0, rho = 0.5, 0.4                             # the slope at 1/2, Cauchy circle of radius 0.4 round it
termwise, closed = dS(z0, 80), -math.log(1 - z0) / z0
print(f"f'(1/2): floors differentiated {termwise:.6f}, -log(1 - z)/z = 2 ln 2 = {closed:.6f}")
for m in (8, 32, 128):                         # trapezoid sum of Cauchy's formula, m points on the circle
    pts = [rho * complex(math.cos(2 * math.pi * k / m), math.sin(2 * math.pi * k / m)) for k in range(m)]
    cauchy = sum(S(z0 + p, 400) / p for p in pts) / m
    print(f"Cauchy's formula, {m} points: {show(cauchy)}, error {abs(cauchy - closed):.9f}")
err10, est10 = abs(dS(z0, 10) - termwise), (1 / 10) / rho
print(f"slope error after 10 floors {err10:.6f}, Cauchy estimate (1/10)/0.4 = {est10:.6f}")
w = 0.5j
tw_i, cl_i = dS(w, 80), -log(1 - w) / w
print(f"f'(i/2): floors differentiated {show(tw_i)}, -log(1 - z)/z {show(cl_i)}")
print("rim slope at z = 1, harmonic sums: " + ", ".join(f"N = {n}: {dS(1, n):.6f}" for n in (10, 100, 1000)))
for n in (16, 64):                             # sin(nx)/n: tiny on the real line, huge at i/4
    sh = (math.exp(n / 4) - math.exp(-n / 4)) / 2 / n
    print(f"sin(nz)/n, n = {n}: real-line size <= {1 / n:.6f}, slope at 0 = 1, size at i/4 = {sh:.6f}")
s = complex(2, 3)                              # the zeta link: |n^-s| = n^-(Re s)
t = math.exp(-s.real * math.log(5)) * complex(math.cos(-s.imag * math.log(5)), math.sin(-s.imag * math.log(5)))
print(f"zeta link: 5^-(2+3i) = {show(t)}, size {abs(t):.6f} = 1/5^2")
print(f"figure, centre (180, 120), 80 per unit: z = 1 at ({180 + 80 * 1}, 120), z = -1 at ({180 - 80 * 1}, 120), "
      f"z0 at ({180 + 80 * z0:.0f}, 120), Cauchy radius {80 * rho:.0f}, i/2 at (180, {120 - 80 * 0.5:.0f})")
assert abs(f1 - math.pi ** 2 / 6) < 1e-12 and abs(fm1 + math.pi ** 2 / 12) < 1e-9   # floors meet pi
assert all(math.pi ** 2 / 6 - S(1, n) <= 1 / n for n in (10, 100, 1000))            # M-test bound holds
assert abs(cauchy - termwise) < 1e-10 and abs(termwise - closed) < 1e-12 and err10 <= est10
assert abs(tw_i - cl_i) < 1e-12 and dS(1, 1000) > 7                                 # i/2 case; rim slope runs off
print("ALL CHECKS PASS")
