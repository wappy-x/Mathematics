# Polynomial long division -- the check behind the card.  Nothing is imported.  A box
# holds x^3 + 6x^2 + 11x + 6 cubic cm, one edge is x + 1 cm.  Coefficients are listed
# highest power first: [1, 6, 11, 6] is the volume, [1, 1] the edge.  Both divisors start with 1.
P, D, E = [1, 6, 11, 6], [1, 1], [1, -2]      # the volume, the edge x + 1, and x - 2

def show(c):                                  # coefficients back into readable form
    out = ""
    for i, a in enumerate(c):
        k = len(c) - 1 - i                    # the power this coefficient sits on
        if a == 0: continue
        t = ("" if abs(a) == 1 and k else str(abs(a))) + ("x" if k else "") + (f"^{k}" if k > 1 else "")
        out += (" + " if a > 0 else " - ") + t if out else (("-" if a < 0 else "") + t)
    return out or "0"
def divide(p, d):                             # long division, one leading term a step
    q, s, steps = [], list(p), []
    while len(s) >= len(d):
        c = s[0] // d[0]                      # the term that kills the leading term
        q.append(c)
        for i in range(len(d)): s[i] -= c * d[i]
        s.pop(0)                              # the leading term is now zero: drop it
        steps.append(show(s))
    return q, s, steps
def value(p, x): return sum(a * x ** (len(p) - 1 - i) for i, a in enumerate(p))
def mul(a, b):                                # multiply two polynomials back together
    out = [0] * (len(a) + len(b) - 1)
    for i, u in enumerate(a):
        for j, w in enumerate(b): out[i + j] += u * w
    return out
def add(a, b): return [u + w for u, w in zip(a, [0] * (len(a) - len(b)) + b)]
def line(name, text): print(f"{name:<30}{text}")

q, s, steps = divide(P, D)                    # one road: divide by the edge x + 1
q2, s2, _ = divide(P, E)                      # the same box divided by x - 2
line("p(x), the volume", show(P))
line("d(x), the edge", show(D))
line("leftovers as the loop runs", " | ".join(steps))
line("q(x), the cross-section", show(q))
line("s(x), the remainder", show(s))
line("d(x) q(x) + s(x)", show(add(mul(D, q), s)))
line("(x + 2)(x + 3) multiplied out", show(mul([1, 2], [1, 3])))
line("p(-1), at the root of x + 1", value(P, -1))
edge = [value(D, 2), value([1, 2], 2), value([1, 3], 2)]
print(f"at x = 2 the box is {edge[0]} by {edge[1]} by {edge[2]}, volume {value(P, 2)}")
ten = [value(D, 10), value([1, 2], 10), value([1, 3], 10)]   # second road: plain numbers
print(f"at x = 10 the box is {ten[0]} by {ten[1]} by {ten[2]}: {value(P, 10)} / {ten[0]} = "
      f"{value(P, 10) // ten[0]} remainder {value(P, 10) % ten[0]}")
line("divide p(x) by x - 2", f"{show(q2)}   remainder {show(s2)}")
line("p(2), at the root of x - 2", value(P, 2))
roots = list(range(-3, 4))
line("r", "".join(f"{r:>4}" for r in roots))
line("remainder, dividing by x - r", "".join(f"{divide(P, [1, -r])[1][0]:>4}" for r in roots))
line("p(r)", "".join(f"{value(P, r):>4}" for r in roots))
print(f"stopping a step early: quotient {show(q[:2] + [0])}, leftover {steps[1]}")
print(f"dropping the remainder 60 leaves {value(mul(q2, E), 2)} at x = 2; "
      f"the root of x + 1 read as 1 gives p(1) = {value(P, 1)}")
assert q == mul([1, 2], [1, 3]) and s == [0]        # the cross-section, from the factors
assert add(mul(D, q), s) == P and add(mul(E, q2), s2) == P
assert [divide(P, [1, -r])[1][0] for r in roots] == [value(P, r) for r in roots]
assert value(P, 10) == 1716 and value(P, 10) // ten[0] == value(q, 10) and value(P, 10) % ten[0] == 0
print("ALL CHECKS PASS")
