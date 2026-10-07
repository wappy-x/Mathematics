# The Laplace transform -- the check behind the card.  Only math's exp, sin,
# cos and pi are imported.  Road one: the table, F(s) read off a formula.
# Road two: the defining integral of e^(-st) f(t), summed by Simpson's rule
# written out here and cut off where the weight has faded to e^(-40).
from math import exp, sin, cos, pi

S, B = 0.05, 2 * pi            # discount rate per year; one seasonal cycle a year

def simpson(g, T, n=200000):   # integral of g from 0 to T, n even
    h = T / n
    total = g(0) + g(T)
    for k in range(1, n):
        total += (4 if k % 2 else 2) * g(k * h)
    return total * h / 3

def laplace(f, s, a=0.0):      # road two, stopped where e^(-(s - a)T) = e^(-40)
    return simpson(lambda t: f(t) * exp(-s * t), 40 / (s - a))

def pv_to(f, s, T):            # present value of the stream f up to year T
    return simpson(lambda t: f(t) * exp(-s * t), T, 2000) if T else 0.0

rows = [("1", lambda t: 1.0, 1 / S, 0.0),
        ("t", lambda t: t, 1 / S**2, 0.0),
        ("e^(0.03t)", lambda t: exp(0.03 * t), 1 / (S - 0.03), 0.03),
        ("cos(2 pi t)", lambda t: cos(B * t), S / (S**2 + B**2), 0.0),
        ("sin(2 pi t)", lambda t: sin(B * t), B / (S**2 + B**2), 0.0)]
print(f"s = {S} per year: table F(s) against the integral, summed")
worst = 0.0
for name, f, table, a in rows:
    num = laplace(f, S, a)
    worst = max(worst, abs(num - table) / table)
    print(f"{name:12s} table {table:.8f}   integral {num:.8f}")
level, growing = 1000 * rows[0][2], 1000 * rows[2][2]
print(f"level 1000/s = {level:.2f} dollars; growing 1000 e^(0.03t): {growing:.2f} dollars")
mix_t = 1000 / S + 400 * rows[3][2]
mix_n = laplace(lambda t: 1000 + 400 * cos(B * t), S)
print(f"linearity, 1000 + 400 cos(2 pi t): table {mix_t:.4f}   integral {mix_n:.4f}")
d_exp = laplace(lambda t: 0.03 * exp(0.03 * t), S, 0.03)
d_cos = laplace(lambda t: -B * sin(B * t), S)
print(f"rate rule, e^(0.03t): L[f'] = {d_exp:.8f}   s F - f(0) = {S * rows[2][2] - 1:.8f}")
print(f"rate rule, cos(2 pi t): L[f'] = {d_cos:.8f}   s F - f(0) = {S * rows[3][2] - 1:.8f}")
grow = lambda t: 1000 * exp(0.03 * t)
for label, f, s in (("level at 5%", lambda t: 1000.0, S), ("growing at 5%", grow, S),
                    ("growing at 3%", grow, 0.03)):
    print(f"chart, {label}:", " ".join(f"{pv_to(f, s, T):.0f}" for T in range(0, 101, 10)))
stall = [pv_to(grow, 0.03, T) for T in (100, 200)]
print(f"mistake 1, growing stream at s = 0.03: {stall[0]:.0f} by year 100, {stall[1]:.0f} by year 200")
print(f"mistake 2, sign slip 1000/(s + 0.03) = {1000 / (S + 0.03):.2f}, not {growing:.2f}")
print(f"mistake 3, sine for cosine: 400 x {rows[4][2]:.6f} = {400 * rows[4][2]:.4f}, not {400 * rows[3][2]:.4f}")
sq = [simpson(lambda t: exp(t * t - S * t), T) for T in (2, 4, 6)]
print("mistake 4, e^(t^2) at s = 0.05, integral to T = 2, 4, 6:", "  ".join(f"{v:.4e}" for v in sq))
assert worst < 1e-7                                    # table = integral, five signals
assert abs(mix_n - mix_t) < 1e-6                        # linearity: the sum transforms as the sum
assert max(abs(d_exp - (S * rows[2][2] - 1)), abs(d_cos - (S * rows[3][2] - 1))) < 1e-7
assert stall[1] - stall[0] > 99000                      # no limit when s does not beat the growth
print("ALL CHECKS PASS")
