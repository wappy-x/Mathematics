# The quadratic formula -- the check behind the card.  Nothing is imported; the
# square root is built here by Newton's method.  A football is kicked straight up
# at 20 m/s, so its height t seconds later is 20t - 5t^2 metres.  Asking when the
# ball is H metres up means solving 5t^2 - 20t + H = 0.
def root(v):                                   # square root, built from scratch
    g = v if v > 1.0 else 1.0
    for _ in range(60):                        # Newton: average a guess with v/guess
        g = (g + v / g) / 2.0
    return g

def height(t): return 20 * t - 5 * t * t       # the ball, t seconds after the kick

def poly(t): return 5 * t * t - 20 * t + 15    # 5t^2 - 20t + 15, the 15 m question

def formula(a, b, c):                          # road one: the quadratic formula
    d = b * b - 4 * a * c
    if d < 0:
        return d, []
    if d == 0:
        return d, [-b / (2 * a)]
    s = root(float(d))
    return d, [(-b - s) / (2 * a), (-b + s) / (2 * a)]

def by_square(a, b, c):                        # road two: completing the square
    p, q = b / a, c / a                        # divide through: t^2 + p*t + q = 0
    m = -p / 2.0                               # the middle, halfway between answers
    k = m * m - q                              # (t - m)^2 = k
    return m, k, [m - root(k), m + root(k)]

ts = [0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0]
print("the ball's height, 20t - 5t^2 metres")
print("t, seconds      " + "".join(f"{t:>7.1f}" for t in ts))
print("height, metres  " + "".join(f"{height(t):>7.2f}" for t in ts))
words = ["no answers", "one answer", "two answers"]
for want in (15, 20, 25):
    d, r = formula(5, -20, want)
    shown = " and ".join(f"{x:.2f}" for x in r) if r else "never"
    print(f"{want} m up:  5t^2 - 20t + {want} = 0   b^2 = {20 * 20}   4ac = {4 * 5 * want}"
          f"   D = {d:>4}   t = {shown:<17} ({words[len(r)]})")
r15 = formula(5, -20, 15)[1]
mid, k, sq = by_square(5, -20, 15)
print(f"the 15 m arithmetic:  -b = {20},  2a = {2 * 5},  the root of D = {root(100.0):.2f},"
      f"  so t = ({20} - {root(100.0):.2f}) / {2 * 5} and ({20} + {root(100.0):.2f}) / {2 * 5}")
print(f"completing the square:  (t - {mid:.2f})^2 = {k:.2f}, so t = {mid:.2f} minus "
      f"{root(k):.2f} and {mid:.2f} plus {root(k):.2f}, landing on {sq[0]:.2f} and {sq[1]:.2f}")
print(f"put each answer back into 5t^2 - 20t + 15:  {poly(r15[0]):.2f} at t = {r15[0]:.2f}, "
      f"{poly(r15[1]):.2f} at t = {r15[1]:.2f}")
print(f"sum and product:  {r15[0]:.2f} + {r15[1]:.2f} = {r15[0] + r15[1]:.2f} = -b/a,  "
      f"{r15[0]:.2f} x {r15[1]:.2f} = {r15[0] * r15[1]:.2f} = c/a")
split = root(400.0) - root(300.0)                       # rooting b^2 and 4ac apart
m1 = [(-20 - 10) / 10, (-20 + 10) / 10]                 # the minus sign on -b dropped
m2 = [20 - 10 / 10, 20 + 10 / 10]                       # only the root divided by 2a
m3 = [(20 - split) / 10, (20 + split) / 10]
print(f"the three mistakes come out at:  {m1[0]:.2f} and {m1[1]:.2f}, {m2[0]:.2f} and "
      f"{m2[1]:.2f}, {m3[0]:.2f} and {m3[1]:.2f}")
assert abs(r15[0] - 1.0) < 1e-12 and abs(r15[1] - 3.0) < 1e-12
assert abs(sq[0] - 1.0) < 1e-12 and abs(sq[1] - 3.0) < 1e-12 and abs(poly(r15[0])) < 1e-12
assert abs(r15[0] + r15[1] - 20 / 5) < 1e-12 and abs(r15[0] * r15[1] - 15 / 5) < 1e-12
assert [formula(5, -20, h)[0] for h in (15, 20, 25)] == [100, 0, -100]
print("ALL CHECKS PASS")
