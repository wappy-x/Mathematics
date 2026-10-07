# Convergence tests -- the check behind the card.  Standard library only;
# math.log is a primitive, and every sum is added here one term at a time.
from math import log

def partial(term, N):                        # road one: add the terms
    s = 0.0
    for n in range(1, N + 1):
        s += term(n)
    return s

harm = lambda n: 1.0 / n                     # the harmonic series
sq = lambda n: 1.0 / (n * n)                 # the squares
tele = lambda n: 1.0 / (n * (n + 1))         # shifted one place, caps a square
half = lambda n: n / 2.0 ** n                # a case the ratio test settles
f2 = lambda v: " ".join(f"{x:.2f}" for x in v)

print("tests on the harmonic series 1/n and the squares 1/n^2")
pts = [2 ** k for k in range(11)]
print("figure, n:", " ".join(str(n) for n in pts))
print("figure, harmonic partial sums:", f2(partial(harm, n) for n in pts))
print("figure, doubling floor 1 + k/2:", f2(1 + k / 2 for k in range(11)))
print("figure, squares partial sums:", f2(partial(sq, n) for n in pts))

for N in (1000, 1000000):                    # road two: area under 1/x is log x
    H, lo, hi = partial(harm, N), log(N + 1), 1 + log(N)
    assert lo <= H <= hi
    print(f"harmonic N={N}: sum {H:.6f}, integral bounds {lo:.6f} to {hi:.6f}")

for N in (10, 1000):                         # road two: area under 1/x^2 is 1/N
    S = partial(sq, N)
    print(f"squares N={N}: sum {S:.6f}, whole sum between {S + 1 / (N + 1):.6f} and {S + 1 / N:.6f}")

def atan(x):                                 # arctangent by its own series
    return sum((-1) ** k * x ** (2 * k + 1) / (2 * k + 1) for k in range(30))
pi = 16 * atan(1 / 5) - 4 * atan(1 / 239)    # Machin's formula builds pi
euler, S = pi * pi / 6, partial(sq, 1000)
assert S + 1 / 1001 <= euler <= S + 1 / 1000 # Euler's value lands in the box
print(f"Euler's value pi^2/6, pi built by Machin: {euler:.6f}, inside the N=1000 bounds")
T = 1 + partial(tele, 999)                   # 1 + sum of 1/((n-1)n), n = 2..1000
assert abs(T - (2 - 1 / 1000)) < 1e-12 and S <= T  # telescoping, then the ceiling
print(f"squares ceiling by comparison, N=1000: added {T:.6f}, telescoped 2 - 1/N = {2 - 1 / 1000:.6f}")

n = 1000
print(f"ratio at n={n}: harmonic {harm(n + 1) / harm(n):.6f}, squares {sq(n + 1) / sq(n):.6f}")
print(f"root at n={n}: harmonic {harm(n) ** (1 / n):.6f}, squares {sq(n) ** (1 / n):.6f}")

h20, closed = partial(half, 20), 2 - 22 / 2.0 ** 20
assert abs(h20 - closed) < 1e-12             # adding against the induction formula
print(f"n/2^n: ratio at n=2 {half(3) / half(2):.6f}, at n=20 {half(21) / half(20):.6f}, root at n=20 {half(20) ** (1 / 20):.6f}")
print(f"n/2^n, N=20: added {h20:.6f}, closed form 2 - 22/2^20 = {closed:.6f}")
print(f"integral of 1/x^2 from 1 to 1000000: {1 - 1 / 1000000:.6f}")
print("All 4 asserts passed.")
