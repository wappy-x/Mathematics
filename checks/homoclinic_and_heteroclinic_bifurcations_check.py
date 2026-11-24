# Homoclinic bifurcation: the check behind the card.  Standard library only.
# 1: the loop of x'' = x - 1.5x^2.  2: damping breaks the swing's top-to-top orbit.
# 3: in x' = y, y' = mu*y + x - x^2 + x*y a cycle grows until it touches the saddle.
from math import sqrt, log, acosh, sin, pi
def rk4(f, x, y, h):                                    # one Runge-Kutta step
    a1, b1 = f(x, y); a2, b2 = f(x + h / 2 * a1, y + h / 2 * b1)
    a3, b3 = f(x + h / 2 * a2, y + h / 2 * b2); a4, b4 = f(x + h * a3, y + h * b3)
    return x + h / 6 * (a1 + 2 * a2 + 2 * a3 + a4), y + h / 6 * (b1 + 2 * b2 + 2 * b3 + b4)
H, loop = 0.002, lambda x, y: (y, x - 1.5 * x * x)
x, y, t, worst, at = 1.0, 0.0, 0.0, 0.0, {}             # part 1: start at the loop's top
while x > 1e-4 and t < 30:
    px = x; x, y = rk4(loop, x, y, H); t += H
    worst = max(worst, abs(y * y - x * x + x ** 3))     # energy identity along the way
    for d in (1e-3, 1e-4):
        if px >= d > x: at[d] = t - H * (d - x) / (px - x)
def top(b):                                             # part 2: leave the top, 1e-6 off
    th, w = pi - 1e-6, 0.0
    while True:
        pw = w; th, w = rk4(lambda p, q: (q, -b * q - sin(p)), th, w, H)
        if pw < 0 <= w: return -th * 180 / pi           # far-side height, in degrees
eig = lambda mu: ((mu + sqrt(mu * mu + 4)) / 2, (mu - sqrt(mu * mu + 4)) / 2)
field = lambda mu: (lambda x, y: (y, mu * y + x - x * x + x * y))
def leave(mu, h, laps=0):                # follow the saddle's outgoing path
    x, y, t, cr, lo = 1e-7, 1e-7 * eig(mu)[0], 0.0, [], 1.0
    while t < 400:
        py = y; x, y = rk4(field(mu), x, y, h); t += h; lo = min(lo, x)
        if not laps and x < 0: return +1, t             # passes outside the saddle
        if not laps and py < 0 <= y and x < 1: return -1, t   # turns back inside
        if laps and py > 0 >= y and x > 1:              # one lap = right-side crossings
            cr.append(t - h * y / (y - py)); last, lo = lo, 1.0     # leftmost x of the lap just done
            if len(cr) == laps: return cr[-1] - cr[-2], last
def critical(h):                         # bisection on which side the path falls
    lo, hi = -0.87, -0.86
    for _ in range(34):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if leave(mid, h)[0] < 0 else (lo, mid)
    return (lo + hi) / 2
mc, mc2 = critical(H), critical(2 * H); lu, ls = eig(mc); gain = log(10) / lu
print("loop x = sech^2(t/2): saddle eigenvalues +1 and -1, top x = 1 at t = 0")
for d in (1e-3, 1e-4):
    print(f"time from the top to x = {d:g}: by steps {at[d]:.4f}, closed form {2 * acosh(d ** -0.5):.4f}")
print(f"tenfold closer adds {at[1e-4] - at[1e-3]:.4f}, near ln(10)/1 = {log(10):.4f}; energy identity (x')^2 = x^2 - x^3 kept to {worst:.1e}")
print(f"swing leaving the top climbs on the far side to: undamped {top(0):.4f} deg, damping 0.5 {top(0.5):.4f} deg")
print(f"cycle born by Hopf at mu = -1; touches the saddle at mu_c = {mc:.7f} (step {H}), {mc2:.7f} (step {2 * H})")
print(f"saddle at mu_c: lambda_u = {lu:.6f}, lambda_s = {ls:.6f}, sum {lu + ls:.6f} < 0, so the cycle attracts")
print(f"predicted extra time per tenfold step closer: ln(10)/lambda_u = {gain:.4f}")
L = {k: leave(mc - 10.0 ** -k, H, 6) for k in range(2, 7)}; T = {k: L[k][0] for k in L}   # 6th lap: settled
C = T[6] - log(1e6) / lu
for k in range(2, 7):
    print(f"mu_c - mu = 1e-{k}: period {T[k]:.4f}, formula {C + k * gain:.4f}, leftmost x {L[k][1]:.6f}" + (f", gain {T[k] - T[k - 1]:.4f}" if k > 2 else ""))
print(f"formula: period = {C:.4f} + ln(1/(mu_c - mu))/lambda_u")
print(f"mistake 1, base-10 log: 1/lambda_u = {1 / lu:.4f} per tenfold step, not {gain:.4f}")
print(f"mistake 2, square-root law from 1e-2: {T[2] * 100:.2f} at 1e-6, true {T[6]:.4f}")
print(f"mistake 3, looking past mu_c at mu = mu_c + 0.01: no cycle, the path crosses x = 0 at t = {leave(mc + 0.01, H)[1]:.2f} and runs off")
assert all(abs(at[d] - 2 * acosh(d ** -0.5)) < 1e-4 for d in (1e-3, 1e-4))  # steps vs closed form
assert worst < 1e-9 and abs(top(0) - 180) < 1e-3 and top(0.5) < 120   # energy kept; damping breaks it
assert abs(mc - mc2) < 1e-8 and abs(mc + 0.8645) < 1e-4              # published value -0.8645
assert abs((T[6] - T[5]) - gain) < 1e-3 and abs(T[4] - (C + 4 * gain)) < 1e-2   # log law
assert L[2][1] > L[4][1] > L[6][1] > 0 and L[6][1] < 1e-3            # the cycle closes on the saddle at x = 0
print("ALL CHECKS PASS")
