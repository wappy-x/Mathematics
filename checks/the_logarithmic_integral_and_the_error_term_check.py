# The logarithmic integral and the error term -- the check behind the card.  Standard library only.
# Primes by a sieve and by Legendre's count; li by its series and by an integral; the error of
# x/ln x against the expansion of li; Trudgian's explicit classical bound; the prime-square bias.
import math, functools

X = 10**7
flag = bytearray([1]) * (X + 1); flag[0] = flag[1] = 0
for p in range(2, 3163):                         # sieve of Eratosthenes up to 10^7
    if flag[p]:
        flag[p * p::p] = bytearray(len(range(p * p, X + 1, p)))
pi = lambda x: flag[:x + 1].count(1)             # pi(x): primes up to x, counted on the sieve
small = [p for p in range(3163) if flag[p]]      # the 446 primes up to sqrt(10^7)

@functools.lru_cache(None)
def phi(x, a):                                   # numbers up to x free of the first a primes
    if a == 0:
        return x
    if x < small[a - 1]:
        return 1 if x >= 1 else 0
    return phi(x, a - 1) - phi(x // small[a - 1], a - 1)

def legendre(x):                                 # Legendre: pi(x) = phi(x, a) + a - 1, a = pi(sqrt x)
    a = sum(1 for p in small if p * p <= x)
    return phi(x, a) + a - 1

gam = sum(1 / k for k in range(1, 1001)) - math.log(1000) - 1 / 2000 + 1 / 12e6 - 1 / 120e12  # Euler's constant

def li(x):                                       # li(x) = gamma + ln ln x + sum (ln x)^k / (k k!)
    L, term, s = math.log(x), 1.0, 0.0
    for k in range(1, 200):
        term *= L / k
        s += term / k
    return gam + math.log(L) + s

def Li_integral(x, n=20000):                     # Li(x) = integral of e^u / u, u from ln 2 to ln x (Simpson)
    a, b = math.log(2), math.log(x)
    h, f = (b - a) / n, lambda u: math.exp(u) / u
    return h / 3 * (f(a) + f(b) + sum((4 if k % 2 else 2) * f(a + k * h) for k in range(1, n)))

def iroot(x, k):                                 # largest r with r^k <= x, exactly
    r = int(round(x ** (1 / k)))
    while r ** k > x: r -= 1
    while (r + 1) ** k <= x: r += 1
    return r

def Pi(x):                                       # Riemann's weighted count: prime powers p^k weigh 1/k
    return sum(pi(iroot(x, k)) / k for k in range(1, x.bit_length()))

trud = lambda x: 0.2795 * x / math.log(x) ** 0.75 * math.exp(-math.sqrt(math.log(x) / 6.455))  # x >= 229
li2 = li(2)
print(f"li(2) = {li2:.5f}; li(10^6) = {li(10**6):.2f}, Li(10^6) = {li(10**6) - li2:.2f}; pi(10^6) = {pi(10**6)}")
print("x | pi sieve | pi Legendre | x/ln x | li series | Li integral + li(2) | li - pi | pi - x/ln x")
for e in range(3, 8):
    x = 10**e
    print(f"10^{e} | {pi(x)} | {legendre(x)} | {x / math.log(x):.2f} | {li(x):.2f} | "
          f"{Li_integral(x) + li2:.2f} | {li(x) - pi(x):.2f} | {pi(x) - x / math.log(x):.2f}")
L, P = math.log(X), pi(X)
print(f"at 10^7: ratio pi/(x/ln x) {P / (X / L):.5f}; x/ln x low by {100 * (1 - X / L / P):.2f} percent; "
      f"li high by {100 * (li(X) / P - 1):.3f} percent; Li(10^7) = {li(X) - li2:.2f}")
part, terms = 0.0, []
for k in range(5):
    part += math.factorial(k) * X / L ** (k + 1); terms.append(part)
print("expansion x/L (1 + 1/L + 2!/L^2 + 3!/L^3 + 4!/L^4), partial sums: " + ", ".join(f"{t:.2f}" for t in terms))
print(f"pi - x/ln x = {P - X / L:.2f}; x/L^2 = {X / L**2:.2f}; x/L^2 + 2x/L^3 + 6x/L^4 = {terms[3] - terms[0]:.2f}")
print(f"Legendre x/(L - 1.08366): {X / (L - 1.08366):.2f}, off {X / (L - 1.08366) - P:.2f}; "
      f"x/(L - 1): {X / (L - 1):.2f}, off {X / (L - 1) - P:.2f}; ln base 10: {X / math.log10(X):.2f}")
print(f"Trudgian's bound at 10^7: {trud(X):.2f}; true |pi - li| {li(X) - P:.2f}; RH bound sqrt(x) ln x/(8 pi) {math.sqrt(X) * L / (8 * math.pi):.2f}")
print("bound / (x/L^2) at L = " + ", ".join(f"{l}: {0.2795 * l ** 1.25 * math.exp(-math.sqrt(l / 6.455)):.3f}" for l in (16, 50, 100, 200, 400, 1000)))
first = next(l for l in range(16, 2000) if 0.2795 * l ** 1.25 * math.exp(-math.sqrt(l / 6.455)) < 1)
print(f"bound / (x/L^2), with L = ln x, first below 1 at L = {first}, x about 10^{first / math.log(10):.1f}")
u = math.sqrt(X) / L                             # the natural unit for the error: sqrt(x)/ln x
print(f"at 10^7: unit sqrt(x)/ln x {u:.2f}; Pi(x) {Pi(X):.2f}; li - Pi {li(X) - Pi(X):.2f}; "
      f"half pi(sqrt x) {pi(iroot(X, 2)) / 2:.1f}; Pi - pi {Pi(X) - P:.2f}")
miss = [pi(10**e) - 10**e / math.log(10**e) for e in range(3, 8)]
print(f"log 10 = {math.log(10):.6f}; log 10^7 = {L:.3f}; sqrt(10^7) = {math.sqrt(X):.2f}; primes up to it: {len(small)}; "
      f"x^0.9 at 10^7 = {X ** 0.9:.2f}")
print("x/ln x miss grows per factor 10: " + ", ".join(f"{b / a:.2f}" for a, b in zip(miss, miss[1:]))
      + f"; x/ln x miss / li miss {(P - X / L) / (li(X) - P):.1f}; Trudgian / true gap {trud(X) / (li(X) - P):.1f}")
print(f"in units at 10^7: Pi - pi {(Pi(X) - P) / u:.2f}; half pi(sqrt x) {pi(iroot(X, 2)) / 2 / u:.2f}; first wave 2/14.134725 = "
      f"{2 / 14.134725:.2f}; log log log(1.4 x 10^316) = {math.log(math.log(316 * math.log(10) + math.log(1.4))):.2f}")
pts = [10**3, 2 * 10**3, 5 * 10**3, 10**4, 2 * 10**4, 5 * 10**4, 10**5, 2 * 10**5, 5 * 10**5, 10**6, 2 * 10**6, 5 * 10**6, 10**7]
g1 = [(li(x) - pi(x)) / (math.sqrt(x) / math.log(x)) for x in pts]
g2 = [(li(x) - Pi(x)) / (math.sqrt(x) / math.log(x)) for x in pts]
print("chart (li - pi)/unit: " + ", ".join(f"{v:.2f}" for v in g1))
print("chart (li - Pi)/unit: " + ", ".join(f"{v:.2f}" for v in g2))
print("chart gap between the lines: " + ", ".join(f"{a - b:.2f}" for a, b in zip(g1, g2)))
assert P == legendre(X) == 664579 and pi(10**6) == 78498              # two counts and the table value
assert abs(li(X) - (Li_integral(X) + li2)) < 1e-4 and abs(li(10**6) - 78627.55) < 0.01  # series vs integral
assert abs((P - X / L) - (terms[3] - terms[0])) < X / L**4             # x/ln x misses by the expansion's terms
assert all(abs(li(x) - pi(x)) <= trud(x) for x in pts)                 # Trudgian's bound holds at every point
assert all(v > 0 for v in g1) and abs(g2[-1]) < 0.5 and g1[-1] > 1.5   # li overshoots; Pi carries no bias
print("ALL CHECKS PASS")
