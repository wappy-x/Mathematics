# Building the integers and fractions -- the check behind the card.  Nothing is imported.  An integer is a pair
# (paid in, owed), a fraction a pair (top, bottom).  Every rule is tried on every choice of same pairs.
zsame, qsame = (lambda p, q: p[0] + q[1] == q[0] + p[1]), (lambda p, q: p[0] * q[1] == p[1] * q[0])  # plus only; times only
zadd, zmul = (lambda p, q: (p[0] + q[0], p[1] + q[1])), (lambda p, q: (p[0] * q[0] + p[1] * q[1], p[0] * q[1] + p[1] * q[0]))
qadd, qmul = (lambda p, q: (p[0] * q[1] + p[1] * q[0], p[1] * q[1])), (lambda p, q: (p[0] * q[0], p[1] * q[1]))
zval, qval, add, mul = (lambda p: p[0] - p[1]), (lambda p: p[0] / p[1]), (lambda x, y: x + y), (lambda x, y: x * y)  # road 2
gcd = lambda a, b: gcd(b, a % b) if b else abs(a); low = lambda p: (p[0] // gcd(*p), p[1] // gcd(*p)); yn = lambda t: "yes" if t else "no"
def test(same, rule, pairs, val, op):            # choices tried, answers that depend on the pick, answers off road 2
    t = [(rule(p, q), rule(p2, q2), val(p), val(q)) for p in pairs for p2 in pairs if same(p, p2) for q in pairs for q2 in pairs if same(q, q2)]
    return len(t), sum(not same(r, r2) for r, r2, _, _ in t), sum(abs(val(r) - op(u, v)) > 1e-9 for r, _, u, v in t)
Z, Q = [(a, b) for a in range(6) for b in range(6)], [(a, b) for a in range(-3, 4) for b in range(1, 5)]
rows = [("integer +", zsame, zadd, Z, zval, add), ("integer x", zsame, zmul, Z, zval, mul), ("fraction +", qsame, qadd, Q, qval, add),
        ("fraction x", qsame, qmul, Q, qval, mul), ("broken fraction +", qsame, zadd, Q, qval, add), ("broken integer x", zsame, qmul, Z, zval, mul)]
res = [test(*r[1:]) for r in rows]                # the broken rules swap the families' rules: each is the other's
A, B, H, H2, H3, T, T2, O, F, V = (3, 5), (0, 2), (1, 2), (2, 4), (3, 6), (1, 3), (2, 6), (0, 0), (3, 4), (33, 100)
print(f"{A} ~ {B}: {yn(zsame(A, B))}, as {A[0]} + {B[1]} = {A[0] + B[1]} = {B[0]} + {A[1]}; road 2 gives {zval(A)} and {zval(B)}")
print(f"{A} + {B} = {zadd(A, B)} and {B} + {B} = {zadd(B, B)}, worth {zval(zadd(A, B))} and {zval(zadd(B, B))}")
print(f"{A} x {B} = {zmul(A, B)} and {B} x {B} = {zmul(B, B)}, worth {zval(zmul(A, B))} and {zval(zmul(B, B))}")
print(f"{H} ~ {H2} ~ {H3}: {yn(qsame(H, H2) and qsame(H2, H3))}, as {H[0]} x {H2[1]} = {H[0] * H2[1]} = {H[1]} x {H2[0]} and {H2[0]} x {H3[1]} = {H2[0] * H3[1]} = {H2[1]} x {H3[0]}")
print(f"{H} + {T} = {qadd(H, T)} and {H2} + {T2} = {qadd(H2, T2)}: {qadd(H2, T2)[0]} x {qadd(H, T)[1]} = {qadd(H2, T2)[0] * qadd(H, T)[1]} = {qadd(H2, T2)[1]} x {qadd(H, T)[0]}")
print(f"{H} x {T} = {qmul(H, T)} and {H2} x {T2} = {qmul(H2, T2)}; lowest terms {low(qadd(H2, T2))} and {low(qmul(H2, T2))}")
for i in (0, 2, 4):
    (a, n, d, o), (b, m, e, f) = (rows[i][0],) + res[i], (rows[i + 1][0],) + res[i + 1]
    print(f"{a} and {b}: {n} and {m} choices of same pairs; {d} and {e} answers depend on the pick; {o} and {f} miss road 2")
print(f"broken fraction +: {H} + {T} = {zadd(H, T)} but {H} + {T2} = {zadd(H, T2)}, and {zadd(H, T)[0]} x {zadd(H, T2)[1]} = {zadd(H, T)[0] * zadd(H, T2)[1]}, not {zadd(H, T)[1] * zadd(H, T2)[0]}; to two places {T} and {V} give {qval(T):.2f} and {qval(V):.2f}, but {T} ~ {V}: {yn(qsame(T, V))}")
print(f"broken integer x: {B} x {B} = {qmul(B, B)}, worth {zval(qmul(B, B))}; bottom zero: {H} ~ {O} ~ {F}: {yn(qsame(H, O) and qsame(O, F))}, but {H} ~ {F}: {yn(qsame(H, F))}")
assert zval(zadd(A, B)) == -4 == zval(zadd(B, B)) and zval(zmul(A, B)) == 4 == zval(A) * zval(B) and zsame(A, B) and not zsame(A, (5, 3))
assert low(qadd(H2, T2)) == (5, 6) == low(qadd(H, T)) and low(qmul(H2, T2)) == (1, 6) and qsame(qadd(H, T), qadd(H2, T2)) and not qsame(H, F) and not qsame(T, V)
assert [r[1:] for r in res[:4]] == [(0, 0)] * 4 and res[4][1] > 0 and res[5][1] > 0 and qsame(H, O) and qsame(O, F) and zval(qmul(B, B)) == -4
print("ALL CHECKS PASS")
