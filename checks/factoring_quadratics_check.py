# Factoring quadratics -- the check behind the card.  Nothing is imported.
# A football kicked straight up at 20 m/s stands 20t - 5t^2 metres high after
# t seconds.  A square slab x metres a side, trimmed 5 m one way and 6 m the
# other, leaves x^2 - 11x + 30 square metres.  Each is worked two ways: the
# sum form term by term, and the product form with the brackets multiplied.
def height_sum(t): return 20 * t - 5 * t * t        # the football, as a sum
def height_prod(t): return 5 * t * (4 - t)          # the same, as a product
def patio_sum(x): return x * x - 11 * x + 30        # the slab, as a sum
def patio_prod(x): return (x - 5) * (x - 6)         # the same, as a product

def pairs(c):                                       # whole-number pairs multiplying to c
    return [(d, c // d) for d in range(1, abs(c) + 1) if c % d == 0 and d * d <= abs(c)]

def brackets(b, c):                                 # hunt p, q with p + q = b and p * q = c
    for d, e in pairs(c):
        for p, q in ((d, e), (-d, -e)):
            if p + q == b: return p, q
    return None

times = [i / 2 for i in range(9)]                   # 0.0, 0.5, ... 4.0 seconds
print("football height 20t - 5t^2, t = 0.0 to 4.0 in half seconds: "
      + " ".join(f"{height_sum(t):.2f}" for t in times))
same = sum(1 for t in times if height_sum(t) == height_prod(t))
print(f"sum and product forms agree at all {same} of those times")
print("20t - 5t^2 = 5t(4 - t), so the factors vanish at t = 0 and t = 4")
print("whole-number pairs multiplying to 30: "
      + ", ".join(f"{d} and {e}" for d, e in pairs(30)))
p, q = brackets(-11, 30)
print(f"the pair adding to -11 is {p} and {q}, so x^2 - 11x + 30 = (x - {-p})(x - {-q})")
print(f"the brackets vanish at x = {-p} and x = {-q}")
agree = sum(1 for x in range(-4, 16) if patio_sum(x) == patio_prod(x))
print(f"sum and product forms agree at all {agree} whole x from -4 to 15")
print(f"patio at x = 11: sum form {patio_sum(11)}, product form 6 * 5 = {patio_prod(11)}")
print(f"pond patio at x = 11: x^2 - 9 gives {11 * 11 - 9}, "
      f"(x + 3)(x - 3) gives 14 * 8 = {(11 + 3) * (11 - 3)}")
print("x^2 + 9: no whole-number pair, so no brackets" if brackets(0, 9) is None
      else "x^2 + 9 factors, which cannot happen")
print(f"the four mistakes come out at {patio_sum(35)}, {(11 - 3) * (11 - 10)}, "
      f"{(11 + 3) * (11 - 3)} and {5 * (4 - 2)}")
print(f"against the right answers {patio_sum(0)}, {patio_sum(11)}, "
      f"{11 * 11 + 9} and {int(height_sum(2))}")
assert brackets(-11, 30) == (-5, -6) and p + q == -11 and p * q == 30
assert agree == 20 and same == 9
assert height_sum(0) == 0 and height_sum(4) == 0 and height_sum(2) == 20
assert brackets(0, 9) is None and patio_sum(0) == 30 and patio_sum(5) == 0 and patio_sum(6) == 0
print("ALL CHECKS PASS")
