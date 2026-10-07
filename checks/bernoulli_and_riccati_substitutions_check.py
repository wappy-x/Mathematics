# Bernoulli and Riccati equations -- the check behind the card.  Standard
# library only.  Bernoulli: the rumour P' = 0.8 P (1 - P/1000), P(0) = 10,
# through v = 1/P.  Riccati: a skydiver's scaled velocity y' = y^2 - 1 from
# rest, through y = 1 + 1/w and again through y = -1 + 1/w.  Second road:
# plain Euler steps on each equation, error printed at three step sizes.
import math

def bernoulli(t):                         # v' + 0.8 v = 0.0008 solved, then P = 1/v
    return 1 / (0.001 + (0.1 - 0.001) * math.exp(-0.8 * t))

def no_factor(t):                         # the (1 - n) dropped: v' - 0.8 v = -0.0008
    return 1 / (0.001 + (0.1 - 0.001) * math.exp(0.8 * t))

def euler(f, y, t_end, h):                # plain small steps along the slope
    for _ in range(round(t_end / h)):
        y = y + h * f(y)
    return y

rumour = lambda p: 0.8 * p * (1 - p / 1000)
linear_v = lambda v: 0.0008 - 0.8 * v     # the equation v = 1/P obeys
riccati = lambda y: y * y - 1

def from_plus_one(t, y0):                 # y = 1 + 1/w: y = (1 + C e^(2t)) / (1 - C e^(2t))
    c = (y0 - 1) / (y0 + 1)
    return (1 + c * math.exp(2 * t)) / (1 - c * math.exp(2 * t))

def from_minus_one(t, y0):                # y = -1 + 1/w, w' = 2w - 1, w = 1/2 + B e^(2t)
    return -1 + 1 / (0.5 + (1 / (y0 + 1) - 0.5) * math.exp(2 * t))

days = list(range(13))
errs = [abs(euler(rumour, 10.0, 5, h) - bernoulli(5)) for h in (0.1, 0.05, 0.025)]
p_by_v = 1 / euler(linear_v, 0.1, 5, 0.001)
y_errs = [abs(euler(riccati, 0.0, 1, h) - from_plus_one(1, 0.0)) for h in (0.01, 0.005, 0.0025)]
y, n = 3.0, 0                             # a start above y = 1: step until it runs off
while y < 1e6:
    y, n = y + 1e-5 * riccati(y), n + 1
print("day               ", days)
print("P, Bernoulli      ", [round(bernoulli(t)) for t in days])
print("P, (1 - n) dropped", [round(no_factor(t)) for t in days])
print(f"P(5): Bernoulli {bernoulli(5):.4f}; Euler on P {euler(rumour, 10.0, 5, 0.001):.4f}; Euler on v, inverted {p_by_v:.4f}")
print("Euler error in P(5), h = 0.1, 0.05, 0.025:", " ".join(f"{e:.4f}" for e in errs))
print(f"error ratios on halving h: {errs[0] / errs[1]:.3f} {errs[1] / errs[2]:.3f}")
print(f"half the school: ln(99) / 0.8 = {math.log(99) / 0.8:.4f} days; 1/P - 1/1000 at day 5 = {0.099 * math.exp(-4):.6f}")
print(f"mistake, (1 - n) dropped: P(5) = {no_factor(5):.4f} pupils; nobody-knows start stays at {euler(rumour, 0.0, 5, 0.001):.1f}")
print(f"skydiver y(1): from y = 1 {from_plus_one(1, 0.0):.6f}; from y = -1 {from_minus_one(1, 0.0):.6f}; Euler h = 0.001 {euler(riccati, 0.0, 1, 0.001):.6f}")
print("Euler error in y(1), h = 0.01, 0.005, 0.0025:", " ".join(f"{e:.6f}" for e in y_errs))
print(f"in metres per second: V(5 s) = {49 * from_plus_one(1, 0.0):.2f}; 95% of 49 m/s at {5 * 0.5 * math.log(1.95 / 0.05):.2f} s")
print(f"mistake, w^2 term dropped: y = 1 - e^(2t), V(5 s) = {49 * (1 - math.exp(2)):.2f} m/s")
print(f"start y(0) = 3: C = 0.5, runs off at ln(2)/2 = {math.log(2) / 2:.4f}; Euler passes 10^6 at {n * 1e-5:.4f}")
assert abs(euler(rumour, 10.0, 5, 0.001) - bernoulli(5)) < 0.5 and abs(p_by_v - bernoulli(5)) < 0.5
assert all(1.8 < a / b < 2.2 for a, b in ((errs[0], errs[1]), (errs[1], errs[2]), (y_errs[0], y_errs[1])))
assert abs(from_plus_one(1, 0.0) - from_minus_one(1, 0.0)) < 1e-12
assert abs(n * 1e-5 - math.log(2) / 2) < 1e-3   # blow-up time, by steps and by formula
print("ALL CHECKS PASS")
