# Young tableaux and hook lengths -- the check behind the card.  Five ballots, three yes and two
# no, fill the shape (3, 2).  Its standard tableaux are counted by listing fillings, by the hook
# formula, by the hook walk and by reflection; Schur polynomials come from semistandard tableaux.
from fractions import Fraction
from itertools import permutations, product
def fact(n): return n * fact(n - 1) if n > 1 else 1
def prod(xs): return xs[0] * prod(xs[1:]) if xs else 1
def choose(n, k): return fact(n) // (fact(k) * fact(n - k))
def cells(lam): return [(i, j) for i in range(len(lam)) for j in range(lam[i])]
def hook_cells(lam, c):                  # the cells right of c, then the cells below c
    return [(c[0], j) for j in range(c[1] + 1, lam[c[0]])] + [(i, c[1]) for i in range(c[0] + 1, len(lam)) if lam[i] > c[1]]
def hooks(lam): return [1 + len(hook_cells(lam, c)) for c in cells(lam)]
def by_hooks(lam): return fact(sum(lam)) // prod(hooks(lam))         # road one: the hook formula
def ok(T, lam, strict):                  # rows rise (strictly or weakly), columns rise strictly
    return all((j == 0 or T[i, j] > T[i, j - 1] or (not strict and T[i, j] == T[i, j - 1]))
               and (i == 0 or T[i, j] > T[i - 1, j]) for i, j in cells(lam))
def fillings(lam, vals, strict): return [T for p in vals if ok(T := dict(zip(cells(lam), p)), lam, strict)]
def standard(lam): return fillings(lam, permutations(range(1, sum(lam) + 1)), True)   # road two: try all
def schur(lam, m, strict=False):         # semistandard tableaux, entries 1..m, as monomial -> count
    es = [tuple(list(T.values()).count(v) for v in range(1, m + 1)) for T in fillings(lam, product(range(1, m + 1), repeat=sum(lam)), strict)]
    return {e: es.count(e) for e in es}
def walk(lam, c):                        # road three: exact chances of where a hook walk stops
    out, step = ({} if hook_cells(lam, c) else {c: Fraction(1)}), hook_cells(lam, c)
    for d in step:
        for k, p in walk(lam, d).items(): out[k] = out.get(k, 0) + p / len(step)
    return out
def shapes(n, top): return [()] if n == 0 else [(a,) + r for a in range(min(n, top), 0, -1) for r in shapes(n - a, a)]
show = lambda T, lam: "[" + "/".join(" ".join(str(T[i, j]) for j in range(lam[i])) for i in range(len(lam))) + "]"
poly = lambda P: " + ".join((f"{P[e]} " if P[e] > 1 else "") + " ".join(f"x{v + 1}" + (f"^{k}" if k > 1 else "")
                            for v, k in enumerate(e) if k) for e in sorted(P, reverse=True))
lam, n, H = (3, 2), 5, hooks((3, 2)); syt, ssyt = standard(lam), fillings((2, 1), product(range(1, 3), repeat=3), False)
ends = {c: sum(walk(lam, s).get(c, 0) for s in cells(lam)) / n for c in [(0, 2), (1, 1)]}
small = {c: (lam[0] - (c[0] == 0), lam[1] - (c[0] == 1)) for c in ends}; a, b = (len(standard(small[c])) for c in ends)
listed, hooked = [len(standard(mu)) for mu in shapes(n, n)], [by_hooks(mu) for mu in shapes(n, n)]
s21, s21x3, s32x5, s21s = schur((2, 1), 2), schur((2, 1), 3), schur(lam, 5), schur((2, 1), 2, True)
symmetric = all(s21x3[tuple(e[q] for q in sig)] == s21x3[e] for e in s21x3 for sig in permutations(range(3)))
print(f"shape {lam}, n = {n}; hook lengths by row: {H[:3]} {H[3:]}")
print(f"hook formula: {n}!/({'*'.join(map(str, H))}) = {fact(n)}/{prod(H)} = {by_hooks(lam)}")
print(f"standard tableaux by listing all {fact(n)} fillings: {len(syt)}\n  " + "  ".join(show(T, lam) for T in syt))
print("as ballot orders (row 1 = yes, row 2 = no): " + " ".join("".join("YN"[v in (T[1, 0], T[1, 1])] for v in range(1, 6)) for T in syt))
print(f"reflection count: C(5,2) - C(5,1) = {choose(5, 2)} - {choose(5, 1)} = {choose(5, 2) - choose(5, 1)}; "
      f"corner recurrence, by listing: f(2, 2) + f(3, 1) = {a} + {b} = {a + b}")
for c, p in ends.items():
    print(f"hook walk ends at corner ({c[0] + 1},{c[1] + 1}) with chance {p} = f{small[c]}/f{lam} = {Fraction(by_hooks(small[c]), by_hooks(lam))}")
print(f"all shapes of 5, listed: {listed}; by hooks: {hooked}; squares add to {sum(f * f for f in listed)} = 5!")
print(f"rows lengthening downward, 2 over 3: {sum(p[0] < p[1] and p[2] < p[3] < p[4] and p[0] < p[2] and p[1] < p[3] for p in permutations(range(1, 6)))} "
      f"fillings by listing, but hooks give {fact(n)}/{(h23 := prod(hooks((2, 3))))} = {Fraction(fact(n), h23)}")
print(f"shape (10, 10): hook rows {(H10 := hooks((10, 10)))[0]}..{H10[9]} and {H10[10]}..{H10[19]}; hooks give {by_hooks((10, 10))}; "
      f"reflection C(20,10) - C(20,9) = {choose(20, 10)} - {choose(20, 9)} = {choose(20, 10) - choose(20, 9)}")
print(f"semistandard (2, 1), entries 1..2: {' '.join(show(T, (2, 1)) for T in ssyt)}; s(2,1)(x1,x2) = {poly(s21)}")
print(f"s(2,1)(x1,x2,x3): {sum(s21x3.values())} tableaux, symmetric under every swap of variables: {'yes' if symmetric else 'no'}; x1 x2 x3 coefficient {s21x3[1, 1, 1]} = f(2, 1)")
print(f"s(3,2) in 5 variables: x1 x2 x3 x4 x5 coefficient {s32x5[1, 1, 1, 1, 1]} = f(3, 2)")
print(f"mistake 1, columns ignored: {sum(1 for p in permutations(range(1, 6)) if p[0] < p[1] < p[2] and p[3] < p[4])}, not 5")
print(f"mistake 2, hooks counting only cells below: {fact(n)}/{prod(legs := [sum(lam[i] > j for i in range(r, 2)) for r, j in cells(lam)])} = {fact(n) // prod(legs)}, not 5")
print(f"mistake 3, rows strictly rising in a semistandard tableau: {sum(s21s.values())} tableau, {poly(s21s)}, not symmetric")
assert len(syt) == by_hooks(lam) == choose(5, 2) - choose(5, 1) == a + b and H == [4, 3, 1, 2, 1]
assert all(ends[c] == Fraction(by_hooks(small[c]), by_hooks(lam)) for c in ends) and sum(ends.values()) == 1
assert listed == hooked and sum(f * f for f in listed) == fact(n) and by_hooks((10, 10)) == choose(20, 10) - choose(20, 9)
assert symmetric and s21 == {(2, 1): 1, (1, 2): 1} and s21x3[1, 1, 1] == by_hooks((2, 1)) == 2 and s32x5[1, 1, 1, 1, 1] == 5
print("ALL CHECKS PASS")
