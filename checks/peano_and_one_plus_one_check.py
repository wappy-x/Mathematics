# Peano's three rules -- the check behind the card.  Nothing is imported.  A
# number is a rope: () is the rope before any knot, (r,) is one more knot tied
# after r.  Addition is the two rules alone, and 1 + 1 lands where it lands.
def nxt(r): return (r,)                      # the next knot after the rope r
def knots(r): return 0 if r == () else knots(r[0]) + 1      # the ruler, not the arithmetic
def add(m, n):                               # rule one: m + 0 = m.  rule two: m + next(n) = next(m + n)
    return m if n == () else nxt(add(m, n[0]))
def dropped_next(m, n):                      # a mistake: rule two without the outer next
    return m if n == () else dropped_next(m, n[0])
def walk(k, times, nextf):                   # second road: take the next knot, once per knot
    for _ in range(times): k = nextf(k)
    return k
zero = ()
one, two, three = nxt(zero), nxt(nxt(zero)), nxt(nxt(nxt(zero)))
def row(name, value): print(f"{name:<40}{value:>4}")
row("zero, the rope before any knot", knots(zero))
row("one, the knot after zero", knots(one))
row("two, the knot after one", knots(two))
row("1 + 1 by the two rules", knots(add(one, one)))
row("2 + 3 by the two rules", knots(add(two, three)))
row("2 + 3 by tying one knot at a time", knots(walk(two, knots(three), nxt)))
print(f"1 + 1 lands on two, knot for knot: {add(one, one) == two}")
print(f"the three mistakes come out at {walk(2, 3, lambda k: (k + 1) % 4)},",
      f"{walk(2, 3, lambda k: min(k + 1, 3))} and {knots(dropped_next(two, three))}")
assert knots(add(one, one)) == 2 and add(one, one) == two
assert knots(add(two, three)) == 5 and add(two, three) == walk(two, knots(three), nxt)
assert knots(zero) == 0 and knots(one) == 1 and knots(nxt(three)) == 4
print("ALL CHECKS PASS")
