# The sum-product problem -- the check behind the card.  Standard library only.
# Road 1 builds each sumset and product set as a set of values.  Road 2 gets
# the same counts without the set: a closed form, or a divisor test per number.
# Then a model of the 2026 recipe A = G.P in the whole numbers of Q(sqrt 2),
# computed exactly on pairs (a, b) meaning a + b sqrt 2, and the 2026 bound
# read at fixed degree.  Nothing here proves the conjecture or its refutation.
import math
from fractions import Fraction

def sums(A): return {a + b for a in A for b in A}
def prods(A): return {a * b for a in A for b in A}

def products_by_test(n):              # road 2: k is a product when some a <= n divides it with k/a <= n
    return sum(1 for k in range(1, n * n + 1)
               if any(k % a == 0 and k // a <= n for a in range(1, n + 1)))

def expo(size, n): return math.log(size) / math.log(n)

def mul(x, y): return (x[0] * y[0] + 2 * x[1] * y[1], x[0] * y[1] + x[1] * y[0])
def norm(x): return x[0] * x[0] - 2 * x[1] * x[1]

def at_least(a, b, s, t):             # is a + s*b*sqrt2 >= t?  exact, no square roots
    r = t - a
    if s * b >= 0:
        return r <= 0 or 2 * b * b >= r * r
    return r < 0 and 2 * b * b <= r * r

def in_box(x, lo, hi):                # both real images, a + b sqrt2 and a - b sqrt2, in [lo, hi)
    return all(at_least(x[0], x[1], s, lo) and not at_least(x[0], x[1], s, hi) for s in (1, -1))

line = list(range(1, 11))
pow2 = [2 ** i for i in range(10)]
n = 10
s_line, p_line = len(sums(line)), len(prods(line))
s_pow, p_pow = len(sums(pow2)), len(prods(pow2))
print(f"A = 1..10:        |A+A| = {s_line} (closed form 2n-1 = {2 * n - 1}), |AA| = {p_line} (divisor test {products_by_test(10)})")
print(f"A = 1, 2, ..., 512: |A+A| = {s_pow} (closed form n(n+1)/2 = {n * (n + 1) // 2}), |AA| = {p_pow} (closed form 2n-1 = {2 * n - 1})")
print(f"ordered pairs 10 x 10 = {n * n}; distinct sums of 1..10 only {s_line}")
table = {}
for m in (10, 100, 1000):
    table[m] = len(prods(range(1, m + 1)))
    print(f"multiplication table 1..{m}: {table[m]} distinct products of {m * m}; exponent {expo(table[m], m):.4f}")
print(f"multiplication table 1..100 by divisor test: {products_by_test(100)}")

Q = [Fraction(1, 2), Fraction(1, 3), Fraction(2, 3), Fraction(3, 4), Fraction(5, 6), Fraction(1)]
D = 12                                # common denominator of the six fractions
Z = [int(q * D) for q in Q]
print(f"fractions {[str(q) for q in Q]} times {D} = {Z}")
print(f"  sums {len(sums(Q))} and {len(sums(Z))}; products {len(prods(Q))} and {len(prods(Z))}")

X, L, Y = 30, 30, 3                   # the box [X, X+L) for both images; units u^k with |k| <= Y
P = [(a, b) for a in range(0, 4 * X) for b in range(-3 * X, 3 * X) if in_box((a, b), X, X + L)]
G, g, h = [(1, 0)], (1, 0), (1, 0)
for _ in range(Y):
    g, h = mul(g, (1, 1)), mul(h, (-1, 1))   # 1 + sqrt2 and its inverse -1 + sqrt2
    G += [g, h]
A = {mul(u, p) for u in G for p in P}
PP = {(x[0] + y[0], x[1] + y[1]) for x in P for y in P}
SA = {(x[0] + y[0], x[1] + y[1]) for x in A for y in A}
MA = {mul(x, y) for x in A for y in A}
N = len(A)
inter = len(prods(range(1, N + 1)))
print(f"Q(sqrt2) model, box [{X}, {X + L}), units (1+sqrt2)^k for |k| <= {Y}:")
print(f"  |P| = {len(P)}, |G| = {len(G)}, |A| = |G||P| = {len(G) * len(P)}, counted {N}")
print(f"  |P+P| = {len(PP)} = {len(PP) / len(P):.2f} x |P|, all inside the box [{2 * X}, {2 * X + 2 * L}): "
      f"{all(in_box(x, 2 * X, 2 * X + 2 * L) for x in PP)}")
print(f"  |A+A| = {len(SA)} = {len(SA) / N:.1f} x |A|, |AA| = {len(MA)}; max exponent {expo(max(len(SA), len(MA)), N):.4f}")
print(f"  interval 1..{N}: |A+A| = {2 * N - 1}, |AA| = {inter}; max exponent {expo(inter, N):.4f}")
B = {2 ** k * p for k in range(2 * Y + 1) for p in range(len(P), 2 * len(P))}   # the same recipe in Z
SB, MB = len(sums(B)), len(prods(B))
print(f"  whole numbers 2^k x [{len(P)}, {2 * len(P)}), 0 <= k <= {2 * Y}: |A| = {len(B)}, |A+A| = {SB}, |AA| = {MB}; "
      f"max exponent {expo(max(SB, MB), len(B)):.4f}")
print("2026 bound |AA| <= 2^-d |A|^2, saving 2^-d written as |A|^-s:")
for k in (3, 6, 9):
    print(f"  |A| = 1e{k}: d = 1 gives s = {math.log(2) / math.log(10 ** k):.4f}, d = 2 gives s = {2 * math.log(2) / math.log(10 ** k):.4f}")
print(f"exponent windows: proved floor 4/3 + 2/1167 = {4 / 3 + 2 / 1167:.6f}; claimed floor 4/3 + 10/4407 = "
      f"{4 / 3 + 10 / 4407:.6f}; claimed ceiling over the reals 2 - 0.00000087 = {2 - 0.00000087:.8f}")
for name, e in (("1..10", expo(p_line, 10)), ("1, 2, ..., 512", expo(s_pow, 10)),
                ("1..1000", expo(table[1000], 1000)), (f"1..{N}", expo(inter, N)),
                ("Z, 2^k x box", expo(max(SB, MB), len(B))), ("Q(sqrt2) model", expo(max(len(SA), len(MA)), N))):
    print(f"  {name:<15} {'#' * round(40 * (e - 1)):<40} {e:.4f}")

assert (s_line, p_line, s_pow, p_pow) == (2 * n - 1, products_by_test(10), n * (n + 1) // 2, 2 * n - 1)
assert table[100] == products_by_test(100) == 2906
assert (len(sums(Q)), len(prods(Q))) == (len(sums(Z)), len(prods(Z)))
assert N == len(G) * len(P) and all(norm(mul(x, y)) == norm(x) * norm(y) for x in P[:40] for y in G)
assert all(in_box(x, 2 * X, 2 * X + 2 * L) for x in PP) and len(PP) <= 4 * len(P)
assert max(len(SA), len(MA)) < inter and len(B) == N
print("ALL CHECKS PASS")
