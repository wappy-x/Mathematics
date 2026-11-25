# Polynomial long division -- the check behind the card.  Nothing is imported.  An open tray
# folded from a 30 by 20 cm card, after cutting an x cm square from each corner, holds
# x(30 - 2x)(20 - 2x) cubic cm: one litre where p(x) = 4x^3 - 100x^2 + 600x - 1000 is zero.
P, D, E = [4, -100, 600, -1000], [1, -5], [1, -4]   # p highest power first, x - 5, x - 4

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

q, s, steps = divide(P, D)                    # one road: divide by x - 5
q2, s2, _ = divide(P, E)                      # the same p divided by x - 4
line("p(x), volume minus 1000", show(P))
line("leftovers as the loop runs", " | ".join(steps))
line("q(x), the quotient", show(q))
line("s(x), the remainder", show(s))
line("d(x) q(x) + s(x)", show(add(mul(D, q), s)))
print(f"a 5 cm cut: 5 by {30 - 2 * 5} by {20 - 2 * 5} cm, volume {5 * (30 - 2 * 5) * (20 - 2 * 5)}")
disc = q[1] * q[1] - 4 * q[0] * q[2]          # the quotient's zeros, by the quadratic formula
lo, hi = (-q[1] - disc ** 0.5) / (2 * q[0]), (-q[1] + disc ** 0.5) / (2 * q[0])
print(f"q(x) = 0 at x = {lo:.2f} and x = {hi:.2f}; two {hi:.2f} cm squares do not fit across 20 cm")
print(f"a {lo:.2f} cm cut: {lo:.2f} by {30 - 2 * lo:.2f} by {20 - 2 * lo:.2f} cm, "
      f"volume {lo * (30 - 2 * lo) * (20 - 2 * lo):.2f}")
print(f"at x = 20: p = {value(P, 20)}, x - 5 = 15, {value(P, 20)} / 15 = {value(P, 20) // 15} "
      f"remainder {value(P, 20) % 15}, and q(20) = {value(q, 20)}")   # second road: plain numbers
line("divide p(x) by x - 4", f"{show(q2)}   remainder {show(s2)}")
line("p(4), at the root of x - 4", value(P, 4))
roots = list(range(0, 11))
line("r", "".join(f"{r:>6}" for r in roots))
line("remainder, dividing by x - r", "".join(f"{divide(P, [1, -r])[1][0]:>6}" for r in roots))
line("p(r)", "".join(f"{value(P, r):>6}" for r in roots))
print(f"stopping a step early: quotient {show(q[:2] + [0])}, leftover {steps[1]}")
print(f"dropping the remainder 56 leaves {value(mul(q2, E), 4)} at x = 4; "
      f"the root of x - 5 read as -5 gives p(-5) = {value(P, -5)}")
assert s == [0] and add(mul(D, q), s) == P and add(mul(E, q2), s2) == P
assert [divide(P, [1, -r])[1][0] for r in roots] == [value(P, r) for r in roots]
assert s2 == [56] and value(P, 4) == 4 * 22 * 12 - 1000 and value(P, -5) == -7000
assert abs(lo * (30 - 2 * lo) * (20 - 2 * lo) - 1000) < 1e-9 and 20 - 2 * hi < 0 and value(P, 20) == 15 * value(q, 20)
print("ALL CHECKS PASS")
