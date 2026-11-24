# Normal forms -- the check behind the card.  Nothing is imported.  The club door: E = not A or I
# (A: after 9 pm, I: shows ID), rebuilt as a DNF, a CNF, NAND alone and NOR alone; then every table.
def rows(n): return [tuple(k >> (n - 1 - j) & 1 for j in range(n)) for k in range(2 ** n - 1, -1, -1)]
nand = lambda x, y: 1 - x * y; nor = lambda x, y: 1 - max(x, y)   # NAND: false only on 1, 1
def dnf(x, trues): return int(any(all(v == r for v, r in zip(x, row)) for row in trues))
def cnf(x, falses): return int(all(any(v != r for v, r in zip(x, row)) for row in falses))
def nand_only(x, trues):                                  # the DNF, wired from NAND gates only
    one = nand(x[0], nand(x[0], x[0])); acc = nand(one, one)   # wires that are always 1 and 0
    for row in trues:
        term = one
        for v, r in zip(x, row): t = nand(term, v if r else nand(v, v)); term = nand(t, t)  # and
        acc = nand(nand(acc, acc), nand(term, term))     # or
    return acc
def split(R, t): return [r for r, b in zip(R, t) if b], [r for r, b in zip(R, t) if not b]
def rebuilt(n, t):                                        # 1 if all three roads give table t
    R = rows(n); tr, fa = split(R, t)
    return int(all(dnf(x, tr) == b == cnf(x, fa) == nand_only(x, tr) for x, b in zip(R, t)))
R = rows(2); E = [int((not a) or i) for a, i in R]; trues, falses = split(R, E)   # road 1: the sign
cols = [[dnf(x, trues), cnf(x, falses), nand(x[0], nand(x[1], x[1])), nor(nor(nor(x[0], x[0]), x[1]), nor(nor(x[0], x[0]), x[1]))] for x in R]
print("A I  NAND(I,I)  rule  DNF  CNF  NAND  NOR")
for (a, i), e, c in zip(R, E, cols): print(f"{a} {i}  {nand(i, i):>9}{e:>6}{c[0]:>5}{c[1]:>5}{c[2]:>6}{c[3]:>5}")
print(f"DNF terms (one per true row): {len(trues)}; CNF clauses (one per false row): {len(falses)}")
ok = {n: sum(rebuilt(n, [c >> k & 1 for k in range(2 ** n)]) for c in range(2 ** 2 ** n)) for n in (2, 3)}
for n in (2, 3): print(f"{n}-input tables rebuilt by DNF, CNF and NAND alone: {ok[n]} of {2 ** 2 ** n}")
bad = [sum(m == e for m, e in zip(b, E)) for b in ([cnf(x, trues) for x in R], [dnf(x, trues[1:]) for x in R], [nand(*x) for x in R], [int(all(any(v == r for v, r in zip(x, row)) for row in falses)) for x in R])]
print(f"the four mistakes agree with the rule on {bad[0]}, {bad[1]}, {bad[2]} and {bad[3]} of 4 rows")
assert E == [1, 0, 1, 1] and all(c == [e] * 4 for c, e in zip(cols, E))   # four roads, one table
assert ok == {2: 16, 3: 256}                              # every table has a DNF, a CNF and a NAND form
assert bad == [0, 3, 2, 2]                                # the mistakes, counted by hand
print("ALL CHECKS PASS")
