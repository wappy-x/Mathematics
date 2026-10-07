# Solving a recurrence with a generating function -- the check behind the card.
# Nothing is imported.  A bar of n beats is filled with one-beat and two-beat
# notes and counted three ways: by listing every pattern, by dividing the series
# x by 1 - x - x^2, and by the two geometric pieces that fraction splits into.
# The whole-number case 2^n + 3^n out of (2 - 5x) / (1 - 5x + 6x^2) follows.
def rhythms(n):                                   # road one: list every pattern
    if n == 0: return [""]
    return [str(s) + w for s in (1, 2) if s <= n for w in rhythms(n - s)]
def times(p, q):                                  # multiply two polynomials
    return [sum(p[i] * q[k - i] for i in range(len(p)) if 0 <= k - i < len(q))
            for k in range(len(p) + len(q) - 1)]
def series(num, den, N):                          # road two: coefficients of num / den
    out = []
    for j in range(N + 1):
        c = num[j] if j < len(num) else 0
        for k in range(1, min(j, len(den) - 1) + 1): c -= den[k] * out[j - k]
        out.append(c)
    return out
def solve2(p1, q1, r1, p2, q2, r2):               # two equations, two unknowns
    d = p1 * q2 - p2 * q1
    return (r1 * q2 - r2 * q1) / d, (p1 * r2 - p2 * r1) / d
def sqrt(x):                                      # Newton's method, nothing imported
    g = x
    for _ in range(60): g = (g + x / g) / 2
    return g
def pw(x, k):                                     # powers by repeated multiplying
    return 1.0 if k == 0 else x * pw(x, k - 1)
def row(name, xs): print(f"{name:<40}" + " ".join(str(x) for x in xs))
S5 = sqrt(5.0)
PHI, PSI = (1 + S5) / 2, (1 - S5) / 2
FIB = series([0, 1], [1, -1, -1], 13)             # x / (1 - x - x^2)
LIST = [len(rhythms(n)) for n in range(13)]
A, B = solve2(1, 1, 0, -PSI, -PHI, 1)             # A + B = 0 and -A psi - B phi = 1
def binet(n): return A * pw(PHI, n) + B * pw(PSI, n)          # road three
NUM2, DEN2 = [2, -5], [1, -5, 6]
rates = [r for r in range(1, 10) if r * r + DEN2[1] * r + DEN2[2] == 0]
C, D = solve2(1, 1, NUM2[0], -rates[1], -rates[0], NUM2[1])
SECOND = series(NUM2, DEN2, 8)
CLOSED = [round(C) * rates[0] ** n + round(D) * rates[1] ** n for n in range(9)]
print(f"sqrt(5) = {S5:.10f}, phi = {PHI:.10f}, psi = {PSI:.10f}")
row("bars of n beats, patterns listed:", LIST)
row("the same, coefficients of x/(1-x-x^2):", FIB)
print("a 4-beat bar, every pattern: " + " ".join(rhythms(4)))
print(f"a 12-beat bar: {LIST[12]} patterns listed, coefficient of x^13 = {FIB[13]}")
print(f"phi + psi = {PHI + PSI:.10f}, phi x psi = {PHI * PSI:.10f}, so (1 - phi x)(1 - psi x) = 1 - x - x^2")
print(f"the split: A = {A:.10f}, B = {B:.10f}; 1/sqrt(5) = {1 / S5:.10f}")
print(f"phi^13/sqrt(5) = {pw(PHI, 13) / S5:.10f}, psi^13/sqrt(5) = {pw(PSI, 13) / S5:.10f}, F(13) = {binet(13):.10f}")
row("F(0)..F(13) from the split, rounded:", [round(binet(n)) for n in range(14)])
row("coefficients of (2-5x)/(1-5x+6x^2):", SECOND)
print(f"growth rates by search: {rates}, and (1 - {rates[0]}x)(1 - {rates[1]}x) = {times([1, -rates[0]], [1, -rates[1]])}")
row(f"the same list from {round(C)} x 2^n + {round(D)} x 3^n:", CLOSED)
print(f"mistake 1, numerator 1 not x: coefficient of x^12 = {series([1], [1, -1, -1], 13)[12]}, not {FIB[12]}")
print(f"mistake 2, denominator signs copied across: a(4) = {series(NUM2, [1, -5, -6], 8)[4]}, not {SECOND[4]}")
print(f"mistake 3, split fitted to the constant only: a(4) = {2 * rates[0] ** 4}, not {SECOND[4]}")
assert LIST == FIB[1:]                                        # listing against the divided series
assert [round(binet(n)) for n in range(14)] == FIB            # the geometric pieces against it
assert SECOND == CLOSED                                       # rates and weights against it
assert abs(A - 1 / S5) < 1e-12 and abs(B + 1 / S5) < 1e-12    # the solve against 1/sqrt(5)
assert times([1, -rates[0]], [1, -rates[1]]) == DEN2          # the factoring, multiplied out
print("ALL CHECKS PASS")
