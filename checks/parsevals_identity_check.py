# Parseval's identity -- the check behind the card.  Standard library only;
# math gives pi, sin and cos, nothing more.  The signal is the sawtooth f(x) = x
# on (-pi, pi).  Its coefficients come from numerical integration and from the
# closed form, and the energy ledger is balanced by two independent roads.
import math
PI, M, BIG = math.pi, 40000, 10 ** 6        # M midpoints across one cycle
DX = 2 * PI / M
XS = [-PI + (k + 0.5) * DX for k in range(M)]

def integral(g):                            # midpoint rule over one cycle
    return sum(g(x) for x in XS) * DX

def b(n):                                   # sawtooth sine coefficient, integrated
    return integral(lambda x: x * math.sin(n * x)) / PI

def a(n):                                   # triangle |x| cosine coefficient, integrated
    return integral(lambda x: abs(x) * math.cos(n * x)) / PI

def partial(N, p=2, start=1, step=1):       # sum of 1/n^p for start <= n <= N
    return sum(1 / n ** p for n in range(start, N + 1, step))

def row(v, d=2):
    return " ".join(f"{t:.{d}f}" for t in v)

energy = integral(lambda x: x * x) / PI                   # (1/pi) times the integral of f^2
bs = [b(n) for n in range(1, 9)]
closed = [2 * (-1) ** (n + 1) / n for n in range(1, 9)]
share = [t * t for t in bs]
run = [sum(share[:k + 1]) for k in range(8)]
resid = integral(lambda x: (x - sum(bs[n - 1] * math.sin(n * x) for n in (1, 2, 3))) ** 2) / PI
direct = partial(BIG) + 1 / BIG - 1 / (2 * BIG * BIG)     # tail of 1/n^2 past BIG, estimated
a0, a1, a3 = a(0), a(1), a(3)
quart = (energy - a0 ** 2 / 2) * PI ** 2 / 15            # Parseval on |x|: odd n, times 16/15
quart_direct = partial(20000, 4)
tri_tail = [16 / PI ** 2 * partial(20001, 4, N + 1 + N % 2, 2) for N in (10, 100)]
print(f"sawtooth energy (1/pi) int f^2, midpoint rule: {energy:.6f}; 2 pi^2/3 = {2 * PI ** 2 / 3:.6f}")
print("b_n, n=1..4, integrated:", row(bs[:4], 6), "; closed form 2(-1)^(n+1)/n:", row(closed[:4], 6))
print("harmonic share b_n^2, n=1..8:", row(share))
print("running total, n=1..8:", row(run))
print("running total 4 sum 1/n^2 at N = 10, 100, 1000:", row([4 * partial(N) for N in (10, 100, 1000)], 4))
print("shortfall from 2 pi^2/3 at N = 10, 100, 1000:", row([energy - 4 * partial(N) for N in (10, 100, 1000)], 4))
print(f"ledger after 3 harmonics: {run[2]:.6f}; missed, integrated: {resid:.6f}; energy minus ledger: {energy - run[2]:.6f}")
print(f"sum 1/n^2 by Parseval, energy/4: {energy / 4:.9f}")
print(f"sum 1/n^2 added directly to 10^6, plus tail: {direct:.9f}; pi^2/6 = {PI ** 2 / 6:.9f}")
print(f"1-ohm reading: mean power {energy / 2:.4f} W; harmonics 1, 2, 3 give {row([s / 2 for s in share[:3]], 4)} W; "
      f"2 and up {(energy - share[0]) / 2:.4f} W")
print(f"triangle |x|: a_0 = {a0:.6f}, a_1 = {a1:.6f}, a_3 = {a3:.6f}; -4/pi = {-4 / PI:.6f}")
print(f"sum 1/n^4 by Parseval on |x|: {quart:.9f}; added directly: {quart_direct:.9f}")
print("decay at n = 1, 9, 99: sawtooth n |b_n|", row([n * abs(b(n)) for n in (1, 9, 99)], 4),
      "; triangle n^2 |a_n|", row([n * n * abs(a(n)) for n in (1, 9, 99)], 4))
print("triangle energy missed after N = 10, 100:", row(tri_tail, 7))
print(f"mistake 1, no 1/pi in front: sum 1/n^2 would be {energy * PI / 4:.4f}")
print(f"mistake 2, a_0^2 not halved: sum 1/n^4 would be {(energy - a0 ** 2) * PI ** 2 / 15:.4f}")
sines = sum((integral(lambda x: abs(x) * math.sin(n * x)) / PI) ** 2 for n in range(1, 9))
print(f"mistake 3, sines only for |x|: ledger {sines:.4f} against energy {energy:.4f}")
assert all(abs(u - v) < 1e-6 for u, v in zip(bs, closed))      # integration against closed form
assert abs(energy / 4 - direct) < 1e-7                          # Parseval against direct summing
assert abs(resid - (energy - run[2])) < 1e-6                    # Pythagoras for the leftover
assert abs(quart - quart_direct) < 1e-7                         # second case, 1/n^4
print("ALL CHECKS PASS")
