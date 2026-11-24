# Weierstrass factorization -- the check behind the card.  Standard library only.
# Zeros at -1, -2, -3, ...  Road one multiplies the factors E_1(z/a_n) = (1 + z/n) e^(-z/n), tail added
# through its log.  Road two is 1/(z Gamma(z) e^(gamma z)), with Gamma(z) and Euler's constant gamma
# each an area summed by trapezoids after t = e^u; road two multiplies no factors.
import math, cmath

def E(p, w):                                   # elementary factor (1 - w) e^(w + w^2/2 + ... + w^p/p)
    return (1 - w) * cmath.exp(sum(w ** k / k for k in range(1, p + 1)))
def P(z, N=100000):                            # road one: N factors E_1(-z/n), tail e^(-z^2/2N)
    p = 1
    for n in range(1, N + 1):
        p *= E(1, -z / n)
    return p * cmath.exp(-z * z / (2 * N))
def area(f, lo=-150.0, hi=5.0, h=0.05):        # trapezoids in u; both ends are negligible
    return h * sum(f(lo + k * h) for k in range(round((hi - lo) / h) + 1))
gam = -area(lambda u: u * math.exp(u - math.exp(u)))       # gamma = -(area under ln t e^(-t))
def road2(z):                                  # Gamma(z) = area under t^(z-1) e^(-t)
    return 1 / (z * area(lambda u: cmath.exp(z * u - math.exp(u))) * cmath.exp(gam * z))
def show(w):                                   # 'a + bi', six decimals, no -0.000000
    a, b = round(w.real, 6) + 0.0, round(w.imag, 6) + 0.0
    return f"{a:.6f} {'-' if b < 0 else '+'} {abs(b):.6f}i"
def partial(p, a, Ns):                         # partial products of E_p(1/a(n)) at z = 1, kept at each N in Ns
    q, out = 1.0, []
    for n in range(1, max(Ns) + 1):
        q *= E(p, -1 / a(n)).real
        if n in Ns: out.append(q)
    return out

plain = partial(0, lambda n: n, [10, 100, 1000])
fixed = partial(1, lambda n: n, [1, 10, 100, 1000])
H = lambda N: sum(1 / n for n in range(1, N + 1))
by_hand = [(N + 1) * math.exp(-H(N)) for N in (1, 10, 100, 1000)]
print("plain factors (1 + 1/n), N = 10, 100, 1000: " + ", ".join(f"{x:.6f}" for x in plain))
print("factors (1 + 1/n) e^(-1/n), N = 1, 10, 100, 1000: " + ", ".join(f"{x:.6f}" for x in fixed))
print("the same as (N + 1) e^(-H_N): " + ", ".join(f"{x:.6f}" for x in by_hand))
print("chart, plain, N = 1-10: " + ", ".join(f"{x:.0f}" for x in partial(0, lambda n: n, list(range(1, 11)))))
print("chart, corrected, N = 1-10: " + ", ".join(f"{x:.2f}" for x in partial(1, lambda n: n, list(range(1, 11)))))
print(f"Euler's constant gamma, by area: {gam:.6f}; e^(-gamma) = {math.exp(-gam):.6f}; e^gamma = {math.exp(gam):.6f}")
pts = [1, 0.5, complex(0.25, 0.5)]
r1, r2 = [P(z) for z in pts], [road2(z) for z in pts]
for z, a, b in zip(["1", "1/2", "1/4 + i/2"], r1, r2):
    print(f"z = {z}: product, road one {show(a)}; road two {show(b)}")
house, sine = r1[2] * P(-pts[2]), cmath.sin(math.pi * pts[2]) / (math.pi * pts[2])
print(f"house, P(z) P(-z) at 1/4 + i/2: {show(house)}; sin(pi z)/(pi z): {show(sine)}")
grid = [r / 20 * cmath.exp(2j * math.pi * k / 72) for r in range(1, 21) for k in range(72)]
ratio = [max(abs(1 - E(p, w)) / abs(w) ** (p + 1) for w in grid) for p in (0, 1, 2)]
print("lemma, largest |1 - E_p(w)| / |w|^(p+1) on |w| <= 1, p = 0, 1, 2: " + ", ".join(f"{x:.6f}" for x in ratio))
rebuilt = math.exp(gam / 2) * 0.5 * r1[1].real
print(f"1/Gamma rebuilt, e^(gamma z) z P(z) at z = 1/2: {rebuilt:.6f}; 1/sqrt(pi) = {1 / math.sqrt(math.pi):.6f}")
print(f"mistake, e^g dropped: z P(z) at z = 1 is {r1[0].real:.6f}, not 1/Gamma(1) = 1")
e1, e2 = (partial(p, math.sqrt, [100, 10000, 1000000]) for p in (1, 2))
print("mistake, zeros at -sqrt(n), N = 10^2, 10^4, 10^6, with E_1: " + ", ".join(f"{x:.6f}" for x in e1)
      + "; with E_2: " + ", ".join(f"{x:.6f}" for x in e2))
assert all(abs(a - b) < 1e-8 for a, b in zip(r1, r2))                # the product meets 1/(z Gamma e^(gamma z))
assert abs(house - sine) < 1e-8                                       # paired factors rebuild the sine product
assert abs(rebuilt - 1 / math.sqrt(math.pi)) < 1e-8                   # e^g z^m P is 1/Gamma
assert all(abs(a - b) < 1e-12 for a, b in zip(fixed, by_hand))        # the telescoping by hand
assert max(ratio) <= 1 + 1e-12 and plain[-1] > 1000                   # the lemma; plain factors diverge
assert e1[-1] < e1[0] / 50 and e2[2] - e2[1] < (e2[1] - e2[0]) / 5   # E_1 sinks for -sqrt(n), E_2 settles
print("ALL CHECKS PASS")
