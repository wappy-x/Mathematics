# Reduced forms and class numbers.  Nothing is imported.  A form (a, b, c) is ax^2 + bxy + cy^2, D = b^2 - 4ac < 0.
def shift(f, k): a, b, c = f; return (a, b + 2 * a * k, a * k * k + b * k + c)      # x -> x + ky
def turn(f): a, b, c = f; return (c, -b, a)                                           # x -> -y, y -> x
def reduce(f):                                    # apply the two moves until -a < b <= a <= c
    a, b, c = f
    if not -a < b <= a: return [f] + reduce(shift(f, (a - b) // (2 * a)))
    if a > c or (a == c and b < 0): return [f] + reduce(turn(f))
    return [f]
def gcd(x, y): return gcd(y, x % y) if y else abs(x)
def classes(D, lo=1):                             # list the primitive reduced forms directly; 3a^2 <= -D
    out = [(a, b, (b * b - D) // (4 * a)) for a in range(1, int((-D / 3) ** 0.5) + 1) for b in range(lo - a, a + 1) if (b * b - D) % (4 * a) == 0]
    return [(a, b, c) for a, b, c in out if c >= a and (b >= 0 or a < c) and gcd(gcd(a, b), c) == 1]
def ends(D): return {reduce((a, b, (b * b - D) // (4 * a)))[-1] for a in range(1, 40) for b in range(-40, 41) if (b * b - D) % (4 * a) == 0 and gcd(gcd(a, b), (b * b - D) // (4 * a)) == 1}
def values(f, top): return sorted({f[0] * x * x + f[1] * x * y + f[2] * y * y for x in range(-9, 10) for y in range(-9, 10)} & set(range(1, top + 1)))
def sub(f, p, q, r, s): a, b, c = f; return (a*p*p + b*p*r + c*r*r, 2*a*p*q + b*(p*s + q*r) + 2*c*r*s, a*q*q + b*q*s + c*s*s)
def dirichlet(p): return sum(1 if pow(k, (p - 1) // 2, p) == 1 else -1 for k in range(1, (p + 1) // 2)) // (1 if p % 8 == 7 else 3)
path, R, run = reduce((3, 8, 7)), range(-2, 3), [n for n in range(41) if all((n * n + n + 41) % d for d in range(2, n * n + n + 41))]
hits = [(p, q, r, s) for p in R for q in R for r in R for s in R if p * s - q * r == 1 and sub((3, 8, 7), p, q, r, s) == (2, 2, 3)]
print(f"(3, 8, 7), D = {8 * 8} - {4 * 3 * 7} = {8 * 8 - 4 * 3 * 7}: " + " -> ".join(map(str, path)))
print("search, entries -2 to 2, determinant 1: {} substitutions, e.g. x -> ({})x + ({})y, y -> ({})x + ({})y".format(len(hits), *hits[0]))
for D in (-4, -20, -23, -32, -163): print(f"h({D}) = {len(classes(D))}: " + ", ".join(map(str, classes(D))) + f"   reducing every primitive form in a box lands on {len(ends(D))}")
print(f"values up to 15: (1, 0, 5) {values((1, 0, 5), 15)}, (2, 2, 3) {values((2, 2, 3), 15)}")
print(f"Dirichlet's sum, a second road: h(-23) = {dirichlet(23)}, h(-163) = {dirichlet(163)}")
print(f"n^2 + n + 41 is prime for n = 0 to {len(run) - 1}; n = 40 gives {40 * 40 + 40 + 41} = 41 x 41")
print(f"mistakes: plain swap h(-23) = {len({(a, abs(b), c) for a, b, c in classes(-23)})}; b = -a let in h(-20) = {len(classes(-20, 0))}; c left alone D = {2 * 2 - 4 * 3 * 7}")
assert path == [(3, 8, 7), (3, 2, 2), (2, -2, 3), (2, 2, 3)] and (-1, -2, 1, 1) in hits
assert all(set(classes(D)) == ends(D) for D in (-4, -20, -23, -32, -163)) and [dirichlet(p) for p in (23, 163)] == [3, 1] and len(classes(-32)) == 2
assert values((3, 8, 7), 60) == values((2, 2, 3), 60) != values((1, 0, 5), 60) and run == list(range(40))
print("ALL CHECKS PASS")
