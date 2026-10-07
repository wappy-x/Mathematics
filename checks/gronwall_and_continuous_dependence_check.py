# Gronwall's inequality -- the check behind the card.  Nothing is imported
# but math.exp, math.sqrt and math.log.  Two rumours in a 1,000-pupil school,
# P' = 0.8 P (1 - P/1000), started at 10 and 11 pupils, t in days; two cups
# of coffee, T' = -0.1 (T - 20), poured at 80 C and 81 C, t in minutes.
# Road one: the closed-form solutions.  Road two: Euler's small steps along
# the slope, which never call exp.  The bound is gap(0) * e^(L t).
from math import exp, sqrt, log
R, K, L = 0.8, 1000.0, 0.8

def rumour(p): return R * p * (1 - p / K)
def coffee(T): return -0.1 * (T - 20)
def closed_rumour(p0, t): return K / (1 + (K / p0 - 1) * exp(-R * t))
def closed_coffee(T0, t): return 20 + (T0 - 20) * exp(-0.1 * t)

def euler(f, y0, t, h):                          # step along the slope, h at a time
    y = y0
    for _ in range(round(t / h)): y += h * f(y)
    return y

def gaps(f, a, b, days, h):                      # stepped gap at whole times
    return [euler(f, b, t, h) - euler(f, a, t, h) for t in days]

days = range(0, 11)
closed = [closed_rumour(11, t) - closed_rumour(10, t) for t in days]
stepped = gaps(rumour, 10.0, 11.0, days, 0.001)
bound = [exp(L * t) for t in days]
slopes = [abs(rumour(p + 1e-4) - rumour(p - 1e-4)) / 2e-4 for p in range(0, 1001, 5)]
err = [gaps(rumour, 10.0, 11.0, [6], h)[0] - closed[6] for h in (0.02, 0.01, 0.005)]
cup = [0, 10, 30, 60]
cup_closed = [closed_coffee(81, t) - closed_coffee(80, t) for t in cup]
cup_step = gaps(coffee, 80.0, 81.0, cup, 0.001)
print("rumours from 10 and 11 pupils, P' = 0.8 P (1 - P/1000), days 0 to 10")
print(f"largest slope |f'(P)| on 0..1000 by differences: L = {max(slopes):.6f} per day")
print("gap, closed form: ", " ".join(f"{g:.2f}" for g in closed))
print("gap, Euler h=0.001:", " ".join(f"{g:.2f}" for g in stepped))
print("bound e^(0.8 t):  ", " ".join(f"{b:.2f}" for b in bound))
top = max(range(1101), key=lambda i: closed_rumour(11, i / 100) - closed_rumour(10, i / 100))
print(f"bound passes 1000 pupils at day ln(1000)/0.8 = {log(K) / L:.2f}")
print(f"widest gap: {closed_rumour(11, top / 100) - closed_rumour(10, top / 100):.2f} pupils at day {top / 100:.2f}")
print("Euler gap error at day 6, h = 0.02, 0.01, 0.005:", " ".join(f"{e:.4f}" for e in err))
print("coffee from 80 and 81 C, minutes 0, 10, 30, 60")
print("gap, closed e^(-0.1 t):", " ".join(f"{g:.4f}" for g in cup_closed))
print("gap, Euler h=0.001:    ", " ".join(f"{g:.4f}" for g in cup_step))
print("crude bound e^(0.1 t): ", " ".join(f"{exp(0.1 * t):.4f}" for t in cup))
z, t = 1.01, 0.98                              # y' = y^2: L = 2 read at the start
print(f"y' = y^2 from 1 and 1.01 at t = 0.98: gap {1 / (1 / z - t) - 1 / (1 - t):.2f}, start-slope bound {0.01 * exp(2 * t):.4f}")
back = lambda q: 0.2 * sqrt(q)                   # the bucket run backwards from empty
g2 = lambda s: (0.1 * s) ** 2                    # its second solution besides g = 0
fd = [(g2(s + 1e-3) - g2(s - 1e-3)) / 2e-3 for s in (10, 30, 50)]
print(f"bucket reversed, g' = 0.2 sqrt(g), g(0) = 0: g = 0 or (0.1 s)^2 = {g2(50):.2f} at s = 50")
print(f"slope of (0.1 s)^2 at s = 30: differences {fd[1]:.4f}, law 0.2 sqrt(g) = {back(g2(30)):.4f}; Euler from 0 stays at {euler(back, 0.0, 50, 0.01):.2f}")
assert abs(max(slopes) - L) < 1e-6                                    # L found by scanning
assert all(abs(a - b) < 0.05 and b <= c for a, b, c in zip(closed, stepped, bound))   # two roads; the theorem
assert all(abs(a - b) < 1e-4 and a <= 1 for a, b in zip(cup_closed, cup_step))       # coffee within 1 C
assert all(abs(d - back(g2(s))) < 1e-6 for d, s in zip(fd, (10, 30, 50))) and 1.9 < err[0] / err[1] < 2.1   # second solution; order one
print("ALL CHECKS PASS")
