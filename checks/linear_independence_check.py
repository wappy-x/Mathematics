# Linear independence -- the check behind the card.  Nothing is imported.
# Fertiliser bag A = (10, 5), bag B = (2, 8) and a third blend C = (12, 13),
# counted in kg of nitrogen and kg of phosphorus.  Is any one of the three
# already a mix of the other two?
A, B, C = (10, 5), (2, 8), (12, 13)

def mix(x, y, z):                       # x bags of A, y of B, z of C
    return (x * A[0] + y * B[0] + z * C[0], x * A[1] + y * B[1] + z * C[1])

def cross(u, v):                        # the cross-number of two vectors
    return u[0] * v[1] - v[0] * u[1]

def eliminate(z):                       # road one: fix z, solve the two slots
    f = A[1] / A[0]                     # scale the nitrogen row by this to kill x
    r0, r1 = -z * C[0], -z * C[1]       # what the C bags leave on the right
    y = (r1 - f * r0) / (B[1] - f * B[0])
    x = (r0 - B[0] * y) / A[0]          # back-substitute
    return x, y

def gcd(a, b):
    while b: a, b = b, a % b
    return abs(a)

def term(k, name):                      # "+ 1 x B" or "- 1 x C"
    return f"{'+' if k >= 0 else '-'} {abs(k)} x {name}"

def tup(v): return f"({v[0]}, {v[1]})"

print(f"bag A = {tup(A)}, bag B = {tup(B)}, bag C = {tup(C)}, in kg of nitrogen and kg of phosphorus")
print(f"the cross-numbers: A with B = {cross(A, B)}, A with C = {cross(A, C)}, B with C = {cross(B, C)}")
x1, y1 = eliminate(-1)
print(f"road one, elimination on the two slots: x = {x1:.4f}, y = {y1:.4f}, z = -1.0000")
n, m, p = cross(B, C), cross(C, A), cross(A, B)   # road two: the exact relation
g = gcd(gcd(n, m), p)
n, m, p = n // g, m // g, p // g
if n < 0: n, m, p = -n, -m, -p
print(f"road two, from the cross-numbers:       x = {n}, y = {m}, z = {p}")
r = mix(n, m, p)
print(f"the relation rebuilt: {n} x A {term(m, 'B')} {term(p, 'C')} = {tup(r)} -> A, B, C are dependent")
print(f"C is one bag of A plus one bag of B: 1 x A + 1 x B = {tup(mix(1, 1, 0))}")
x0, y0 = eliminate(0)
print(f"the pair A and B alone: cross-number {cross(A, B)}, and the only mix landing on (0, 0) is x = {x0:.4f}, y = {y0:.4f}")
trio = [mix(t, t, -t) for t in range(4)]
pair = [mix(t, t, 0) for t in range(4)]
print("left over from t bags of A, t of B and t of C taken back out, t = 0, 1, 2, 3")
print("  nitrogen, kg     " + ", ".join(str(v[0]) for v in trio))
print("  phosphorus, kg   " + ", ".join(str(v[1]) for v in trio))
print("left over from t bags of A and t of B, no C, t = 0, 1, 2, 3")
print("  nitrogen, kg     " + ", ".join(str(v[0]) for v in pair))
print("  phosphorus, kg   " + ", ".join(str(v[1]) for v in pair))
print(f"the two mistakes come out at {tup(mix(0, 0, 0))} for the all-zero mix and {tup(mix(1, 1, 1))} for all three added")
print(f"dropping A instead of C: the cross-number of B and C is {cross(B, C)}, still not zero")
assert (n, m, p) == (1, 1, -1) and r == (0, 0) and mix(1, 1, 0) == (12, 13)
assert abs(x1 - 1) < 1e-12 and abs(y1 - 1) < 1e-12 and (x0, y0) == (0.0, 0.0)
assert (cross(A, B), cross(A, C), cross(B, C)) == (70, 70, -70) and mix(1, 1, 1) == (24, 26)
assert [v[0] for v in trio] == [0, 0, 0, 0] and [v[0] for v in pair] == [0, 12, 24, 36]
print("ALL CHECKS PASS")
