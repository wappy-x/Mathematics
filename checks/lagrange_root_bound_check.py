# Lagrange's root bound -- the check behind the card.  Nothing is imported.  A
# polynomial is its list of coefficients, constant first; a root on the n-clock
# is a number from 0 to n - 1 where the polynomial reads 0 once clocks come off.
def roots(f, n): return [x for x in range(n) if sum(c * x ** k for k, c in enumerate(f)) % n == 0]
def peel(f, r, n):                       # divide by (x - r) on the n-clock
    q, carry = [0] * (len(f) - 1), 0
    for k in range(len(f) - 1, 0, -1): carry = (carry * r + f[k]) % n; q[k - 1] = carry
    return q, (carry * r + f[0]) % n     # the quotient, and the remainder
SQ, TOP = [-1, 0, 1], [-1, 0, 0, 0, 0, 0, 1]          # x^2 - 1 and x^6 - 1
print("x^2 = 1 on the 7-clock, roots:", *roots(SQ, 7), f"| 6 x 6 = {6 * 6} reads {6 * 6 % 7}")
print("x^2 = 1 on the 8-clock, roots:", *roots(SQ, 8), f"| 3 x 3 = 9 reads {3 * 3 % 8}, (3 - 1) x (3 + 1) = 8 reads {(3 - 1) * (3 + 1) % 8}")
counts = [len(roots(SQ, n)) for n in range(3, 17)]
print("roots of x^2 = 1 on clocks 3 to 16:", *counts)
quads = [[c, b, a] for a in range(1, 7) for b in range(7) for c in range(7)]
most = max(len(roots(f, 7)) for f in quads)            # brute force, every quadratic
print(f"quadratics on the 7-clock: {len(quads)}, most roots any one has: {most}")
full = [1]                                             # (x - 1)(x - 2)...(x - 6), in full
for r in range(1, 7): full = [b - r * a for a, b in zip(full + [0], [0] + full)]
print("x^6 - 1 on the 7-clock, roots:", *roots(TOP, 7))
print("(x - 1)...(x - 6), constant first:", *full, "| on the 7-clock:", *[c % 7 for c in full])
left, rems = TOP, []
for r in range(1, 7): left, rem = peel(left, r, 7); rems.append(rem)
print("peel x - 1 to x - 6 off x^6 - 1, remainders:", *rems, "| left over:", *left)
fact = 1 * 2 * 3 * 4 * 5 * 6                          # 6!, the long way
print(f"6! = {fact} = {(fact + 1) // 7} x 7 - 1, reads {fact % 7}, which is -1")
print(f"traps: 7x^2 - 7 has {len(roots([-7, 0, 7], 7))} roots, -720 reads {-fact % 7}, x^2 + 1 has {len(roots([1, 0, 1], 7))}")
assert roots(SQ, 7) == [1, 6] and roots(SQ, 8) == [1, 3, 5, 7] and len(quads) == 294 and most == 2
assert [c % 7 for c in full] == [c % 7 for c in TOP] and rems == [0] * 6 and left == [1]
assert full[0] == fact and full[0] == 103 * 7 - 1 and sum(full) == 0 and all(c == 2 for n, c in zip(range(3, 17), counts) if all(n % d for d in range(2, n)))
print("ALL CHECKS PASS")
