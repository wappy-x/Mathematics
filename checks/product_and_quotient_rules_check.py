# Product and quotient rules -- the check behind the card.  Nothing imported.
# A roaster's bag of coffee: price p = 12 + 0.5t dollars, bags sold a week
# q = 200 - 4t, t in weeks.  Revenue R = p * q.  Road one: the rules.
# Road two: difference quotients with a shrinking step h, straight from the limit.
def p(t): return 12 + 0.5 * t
def q(t): return 200 - 4 * t
def R(t): return p(t) * q(t)
dp, dq = 0.5, -4.0                           # the two rates, per week
def rate(t): return dp * q(t) + p(t) * dq    # product rule
def dquot(f, t, h): return (f(t + h) - f(t)) / h
def pw(x, n):                                # x multiplied in n times
    out = 1.0
    for _ in range(n): out *= x
    return out
def power_by_products(x, n):                 # d(x^n) from x^n = x * x^(n-1), step by step
    d = 1.0
    for k in range(2, n + 1): d = 1.0 * pw(x, k - 1) + x * d
    return d
t = 4.0
print(f"week 4: price {p(t):.2f}, bags {q(t):.0f}, revenue {R(t):.2f}")
print(f"product rule: 0.5*184 + 14*(-4) = {dp * q(t):.2f} + ({p(t) * dq:.2f}) = {rate(t):.2f}")
for h in (4.0, 1.0, 0.1, 0.01, 0.001):
    print(f"h = {h:g}: revenue quotient {dquot(R, t, h):.6f}, gap to rule {dquot(R, t, h) - rate(t):.6f}")
H = 4.0; ddp, ddq = p(t + H) - p(t), q(t + H) - q(t)
print(f"step of 4 weeks: {p(t + H):.2f} x {q(t + H):.0f} = {R(t + H):.2f}; change {R(t + H) - R(t):.2f} = {ddp * q(t):.2f} "
      f"+ ({p(t) * ddq:.2f}) + ({ddp * ddq:.2f}); strips {ddp * q(t + H):.2f} and {p(t) * ddq:.2f}")
print(f"figure, 20 units a dollar, 1 a bag: old right {20 + 20 * p(t):.0f} top {220 - q(t):.0f}, "
      f"new right {20 + 20 * p(t + H):.0f} top {220 - q(t + H):.0f}")
quot = (rate(t) * q(t) - R(t) * dq) / (q(t) * q(t))           # price = revenue / bags
def price_back(s): return R(s) / q(s)
print(f"quotient by hand: 36*184 = {rate(t) * q(t):.0f}, 2576*(-4) = {R(t) * dq:.0f}, top {rate(t) * q(t) - R(t) * dq:.0f}, "
      f"184^2 = {q(t) * q(t):.0f}; bags reach 0 at week {-q(0) / dq:.0f}")
print(f"quotient rule on revenue/bags: {quot:.6f}; quotient h = 0.001: {dquot(price_back, t, 0.001):.6f}")
print(f"cube at 2: rule {3 * pw(2, 2):.6f}, repeated products {power_by_products(2.0, 3):.6f}, "
      f"h = 0.001: {dquot(lambda x: pw(x, 3), 2.0, 0.001):.6f}")
recip = lambda x: 1 / pw(x, 2)
print(f"1/x^2 at 2: rule {-2 / pw(2, 3):.6f}, h = 0.001: {dquot(recip, 2.0, 0.001):.6f}")
lo, hi = 0.0, 50.0                          # bisection: where the product-rule rate is zero
for _ in range(60):
    mid = (lo + hi) / 2
    lo, hi = (mid, hi) if rate(mid) > 0 else (lo, mid)
grid = max((R(k / 1000), k / 1000) for k in range(50001))
print(f"revenue peaks: rate zero at week {lo:.3f} by bisection, grid maximum at {grid[1]:.3f}, revenue {grid[0]:.2f}")
print(f"mistakes: product of rates {dp * dq:.2f}; reversed quotient {(R(t) * dq - rate(t) * q(t)) / (q(t) * q(t)):.6f}; "
      f"unsquared {(rate(t) * q(t) - R(t) * dq) / q(t):.6f}")
def R_corner(s): return (12 + 0.5 * max(s - 4, 0) + 2) * q(s)  # price flat at 14 until week 4, then rising
print(f"price with a corner at week 4: left quotient {dquot(R_corner, t, -0.001):.6f}, right quotient {dquot(R_corner, t, 0.001):.6f}")
print("chart revenue:", ", ".join(f"{R(s):.0f}" for s in range(0, 21, 2)))
print("chart tangent:", ", ".join(f"{R(t) + rate(t) * (s - t):.0f}" for s in range(0, 21, 2)))
assert abs(dquot(R, t, 0.001) - rate(t)) < 0.003                  # rule against the limit
assert abs(quot - dquot(price_back, t, 0.001)) < 1e-6              # quotient rule against the limit
assert all(abs(power_by_products(2.0, n) - n * pw(2, n - 1)) < 1e-9 for n in range(1, 9))
assert abs(lo - grid[1]) < 0.002                                   # rate zero where revenue tops out
print("ALL CHECKS PASS")
