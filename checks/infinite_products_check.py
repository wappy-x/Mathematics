# Infinite products -- the check behind the card.  Standard library only.
# The account: year n pays rate 1/n^2, so the balance multiplies by 1 + 1/n^2.  Road one multiplies
# the factors and adds the tail through its log; road two is sinh(pi)/pi from exponentials, which is
# Euler's sine product read at z = i.  Wallis is the same product at z = 1/2.
import math

def prod(a, n0, N):                            # (1 + a(n0)) (1 + a(n0 + 1)) ... (1 + a(N))
    p = 1
    for n in range(n0, N + 1):
        p *= 1 + a(n)
    return p
def cexp(w):                                   # e^w for complex w, from exp, cos and sin
    return math.exp(w.real) * complex(math.cos(w.imag), math.sin(w.imag))
def show(w):                                   # 'a + bi', six decimals, no -0.000000
    a, b = round(w.real, 6) + 0.0, round(w.imag, 6) + 0.0
    return f"{a:.6f} {'-' if b < 0 else '+'} {abs(b):.6f}i"
def sine_product(z, N):                        # pi z times N factors (1 - z^2/n^2), tail added by its log
    return math.pi * z * prod(lambda n: -z * z / n ** 2, 1, N) * cexp(-z * z * (1 / N - 1 / (2 * N * N)))
def sin_pi(z):                                 # sin(pi z) = (e^(i pi z) - e^(-i pi z)) / 2i
    return (cexp(1j * math.pi * z) - cexp(-1j * math.pi * z)) / 2j

N = 100000
S = sum(1 / n ** 2 for n in range(1, N + 1)) + 1 / N - 1 / (2 * N * N) + 1 / (6 * N ** 3)   # sum of the rates
road1 = prod(lambda n: 1 / n ** 2, 1, N) * math.exp(1 / N - 1 / (2 * N * N))
road2 = (math.exp(math.pi) - math.exp(-math.pi)) / (2 * math.pi)
logs = sum(math.log(1 + 1 / n ** 2) for n in range(1, N + 1)) + 1 / N
print(f"rate 1/n^2, balance per 1 after 10, 100, 1000 years: "
      + ", ".join(f"{prod(lambda n: 1 / n ** 2, 1, k):.6f}" for k in (10, 100, 1000)))
print(f"road one, factors multiplied plus tail: {road1:.6f}; road two, sinh(pi)/pi: {road2:.6f}")
print(f"sum of logs {logs:.6f}; sum of rates S = pi^2/6 {S:.6f}")
print(f"bounds: 1 + S = {1 + S:.6f} <= balance {road1:.6f} <= e^S = {math.exp(S):.6f}")
print(f"rate 1/n, balance after 10, 100, 1000 years: "
      + ", ".join(f"{prod(lambda n: 1 / n, 1, k):.6f}" for k in (10, 100, 1000)))
print("chart, rate 1/n^2, years 1-10: " + ", ".join(f"{prod(lambda n: 1 / n ** 2, 1, k):.2f}" for k in range(1, 11)))
print("chart, rate 1/n, years 1-10: " + ", ".join(f"{prod(lambda n: 1 / n, 1, k):.0f}" for k in range(1, 11)))
wallis = {k: prod(lambda n: 1 / (4 * n * n - 1), 1, k) for k in (10, 100, 1000)}
for k, w in wallis.items():
    print(f"Wallis, {k} factors: {w:.6f}, gap to pi/2 x N = {(math.pi / 2 - w) * k:.6f}")
wal_tail = wallis[1000] * math.exp(1 / (4 * 1000 + 2))
print(f"Wallis plus tail {wal_tail:.9f}; pi/2 {math.pi / 2:.9f}; pi/8 {math.pi / 8:.6f}")
z = complex(0.25, 0.5)
eu, sp = sine_product(z, 10000), sin_pi(z)
print(f"z = 1/4 + i/2: sine product {show(eu)}; sin(pi z) from exponentials {show(sp)}")
print(f"z = 3: sine product {show(sine_product(3, 10))}, the n = 3 factor is 1 - 9/9 = 0")
alt = lambda n: (-1) ** n / math.sqrt(n)       # gain 1/sqrt(n) in even years, lose it in odd ones
print(f"mistake, rates (-1)^n/sqrt(n) from year 2: sum of rates to 10^5 {sum(alt(n) for n in range(2, N + 1)):.6f}, "
      f"balance after 100, 10^4, 10^5: {prod(alt, 2, 100):.6f}, {prod(alt, 2, 10000):.6f}, {prod(alt, 2, N):.6f}")
print(f"mistake, adding the rates: {S:.6f}, not {road1:.6f}; rates -1/(n+1): {prod(lambda n: -1 / (n + 1), 1, 100):.6f} after 100 years")
print("figure, 60 per unit, 0 at (180, 140): zeros at x = " + ", ".join(f"{180 + 60 * k}" for k in range(-2, 3))
      + f"; 1/2 at ({180 + 60 * 0.5:.0f}, 140), i at (180, {140 - 60:.0f}), 1/4 + i/2 at ({180 + 60 * z.real:.0f}, {140 - 60 * z.imag:.0f})")
assert abs(road1 - road2) < 1e-9                                  # multiplying meets sinh(pi)/pi
assert abs(wal_tail - math.pi / 2) < 1e-9                          # Wallis meets pi/2
assert abs(eu - sp) < 1e-9                                         # Euler's product holds off the line
assert 1 + S < road1 < math.exp(S)                                 # the product sits between 1 + S and e^S
print("ALL CHECKS PASS")
