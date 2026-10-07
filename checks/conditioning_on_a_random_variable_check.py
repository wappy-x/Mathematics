# Conditioning on a random variable -- the check behind the card.  Standard
# library only.  Monthly rainfall X (mm) and temperature Y (deg C) at one
# station are jointly normal: means 55 and 15, spreads 20 and 5, correlation
# -0.6.  E[X | Y] = g(Y) is found from the line, from the density ratio
# f(x, y)/f_Y(y) integrated numerically, and from simulated months; the
# defining property is checked on the event {Y > 20}; the kernel gives a joint
# chance; the abstract Bayes formula re-weights by Z = exp(a X)/E[exp(a X)].
# A four-season table in exact fractions runs Bayes with Z = X/55.
import math
from fractions import Fraction as F

MX, SX, MY, SY, RHO, A = 55.0, 20.0, 15.0, 5.0, -0.6, 0.025
SC = SX * math.sqrt(1 - RHO * RHO)                 # spread left once Y is known

def simpson(f, a, b, n):                          # n even
    h = (b - a) / n
    s = f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))
    return s * h / 3

def phi(z):                                       # standard normal density
    return math.exp(-z * z / 2) / math.sqrt(2 * math.pi)

def cdf(z):                                       # standard normal CDF, by Simpson
    return 0.5 + math.copysign(simpson(phi, 0.0, abs(z), 400), z)

def joint(x, y):                                  # the bivariate normal density
    u, v = (x - MX) / SX, (y - MY) / SY
    q = (u * u - 2 * RHO * u * v + v * v) / (1 - RHO * RHO)
    return math.exp(-q / 2) / (2 * math.pi * SX * SY * math.sqrt(1 - RHO * RHO))

def line(y):                                      # road 1: the regression line
    return MX + RHO * SX / SY * (y - MY)

def xint(f, y):                                   # integral over x of f(x) joint(x, y)
    return simpson(lambda x: f(x) * joint(x, y), MX - 10 * SX, MX + 10 * SX, 2000)

def ratio(y, w=lambda x: 1.0):                    # road 2: int w x f(x,y) dx / int w f(x,y) dx
    return xint(lambda x: w(x) * x, y) / xint(w, y)

M64 = (1 << 64) - 1
def splitmix(s):                                  # SplitMix64: (new state, 64 random bits)
    s = (s + 0x9E3779B97F4A7C15) & M64
    z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return s, z ^ (z >> 31)

def row(v, k=2):
    return ", ".join(f"{t:.{k}f}" for t in v)

r9 = -0.9                                         # the first "try changing" row, by formula
s9 = SX * math.sqrt(1 - r9 * r9)
# 1. E[X | Y = y] by the line and by the density ratio
ys = [5.0, 10.0, 15.0, 20.0, 25.0]
print(f"means {MX:.0f} mm and {MY:.0f} C, spreads {SX:.0f} mm and {SY:.0f} C, correlation {RHO:.2f}; tilt a = {A}")
print(f"slope rho*sx/sy = {RHO * SX / SY:.4f}; spread given Y = {SC:.4f} mm, variance {SC * SC:.2f}")
print("chart, E[X|Y=y] by the line, y = 5..25:", row([line(y) for y in ys]))
dens = [ratio(y) for y in ys]
print("E[X|Y=y] by f(x,y)/f_Y(y), y = 5..25:", row(dens, 4))
fy20 = xint(lambda x: 1.0, 20.0)
print(f"f_Y(20) by integrating out x = {fy20:.6f}; by the normal formula = {phi(1.0) / SY:.6f}")
for yc in (10.0, 15.0, 20.0):                     # conditional densities, % per mm
    fy = xint(lambda x: 1.0, yc)
    print(f"chart, f(x|y={yc:.0f}) x 100, x = 0..110:", row([100 * joint(x, yc) / fy for x in range(0, 111, 10)]))

# 2. the defining property on B = {Y > 20}, and the kernel
top = MY + 10 * SY
lhs = simpson(lambda y: xint(lambda x: x, y), 20.0, top, 600)            # E[X 1_B], joint
rhs = simpson(lambda y: line(y) * phi((y - MY) / SY) / SY, 20.0, top, 600)  # E[g(Y) 1_B]
closed = MX * (1 - cdf(1.0)) + RHO * SX * phi(1.0)
print(f"E[X 1(Y>20)]: joint density {lhs:.4f}; E[g(Y) 1(Y>20)] {rhs:.4f}; closed form {closed:.4f}")
kern = simpson(lambda y: (1 - cdf((70 - line(y)) / SC)) * phi((y - MY) / SY) / SY, 20.0, top, 600)
dbl = simpson(lambda y: simpson(lambda x: joint(x, y), 70.0, MX + 10 * SX, 400), 20.0, top, 400)
print(f"P(X>70, Y>20): kernel {kern:.5f}; double integral {dbl:.5f}")

# 3. abstract Bayes: Q has density Z = exp(a X)/E[exp(a X)] against P
qx, qy = MX + A * SX * SX, MY + A * RHO * SX * SY  # the Q-means: X up 10, Y down 1.5
def h_line(y):                                    # road 1 under Q: Q is normal again
    return qx + RHO * SX / SY * (y - qy)
bayes = [ratio(y, lambda x: math.exp(A * (x - MX))) for y in ys]
print(f"Var X {SX * SX:.2f}, Cov(X,Y) {RHO * SX * SY:.2f}; Q-means: X {qx:.2f} mm, Y {qy:.2f} C")
print(f"conditional shift a*sc^2 = {A * SC * SC:.2f} mm")
print("chart, E_Q[X|Y=y] by the Q-line, y = 5..25:", row([h_line(y) for y in ys]))
print("E_Q[X|Y=y] by E_P[ZX|Y]/E_P[Z|Y], y = 5..25:", row(bayes, 4))
ez20 = xint(lambda x: math.exp(A * (x - MX) - A * A * SX * SX / 2), 20.0) / fy20
print(f"E_P[Z|Y=20] = {ez20:.4f}; forgetting to divide: E_P[ZX|Y=20] = {bayes[3] * ez20:.2f}")
print(f"try rho -0.9: spread {s9:.4f}, shift {A * s9 * s9:.2f}, h(20) {qx + r9 * SX / SY * (20 - MY - A * r9 * SX * SY):.2f}")
bx, by = MX + 0.1 * RHO * SX * SY, MY + 0.1 * SY * SY  # Z = exp(0.1 Y)/E[exp(0.1 Y)] instead
print(f"Z from Y alone, exp(0.1 Y): Q-means {bx:.2f}, {by:.2f}; E_Q[X|Y=20] = {bx + RHO * SX / SY * (20 - by):.4f}")
print(f"mistake: unconditional shift 43 + 10 = {line(20) + A * SX * SX:.2f}; "
      f"E[Y|X] line inverted at y = 20: {MX + (20 - MY) / (RHO * SY / SX):.2f}")

# 4. simulated months, SplitMix64 seed 2026, Box-Muller normals
st, N, S = 2026, 200000, [0.0] * 11
for _ in range(N):
    st, u = splitmix(st)
    st, v = splitmix(st)
    r = math.sqrt(-2 * math.log(((u >> 11) + 0.5) / 2 ** 53))
    z1, z2 = r * math.cos(2 * math.pi * (v >> 11) / 2 ** 53), r * math.sin(2 * math.pi * (v >> 11) / 2 ** 53)
    y = MY + SY * z1
    x = MX + SX * (RHO * z1 + math.sqrt(1 - RHO * RHO) * z2)
    b, z = (1.0 if y > 20 else 0.0), math.exp(A * (x - MX) - A * A * SX * SX / 2)
    near = 1.0 if abs(y - 20) < 0.25 else 0.0
    d1, d2 = (x - line(y)) * b, z * (x - h_line(y)) * b      # the two gaps, for standard errors
    for i, t in enumerate((x * b, line(y) * b, (x - line(y)) * (x - line(y)), (x - MX) * (x - MX),
                           b * (x > 70), near, near * x, z * x * b, z * h_line(y) * b, d1 * d1, d2 * d2)):
        S[i] += t
m = [s / N for s in S]
print(f"sim, seed 2026, {N} months")
print(f"sim E[X 1(Y>20)] {m[0]:.4f}; sim E[g(Y) 1(Y>20)] {m[1]:.4f}; gap's standard error {math.sqrt(m[9] / N):.4f}")
se = math.sqrt(kern * (1 - kern) / N)
print(f"sim P(X>70, Y>20) {m[4]:.5f}, standard error {se:.5f}, off by {abs(m[4] - kern) / se:.1f} standard errors")
print(f"sim mean square error: of g(Y) {m[2]:.2f}; of the constant 55 {m[3]:.2f}")
print(f"sim months with Y within 0.25 of 20: {S[5]:.0f}, average rainfall {S[6] / S[5]:.4f}, standard error {SC / math.sqrt(S[5]):.2f}")
qclosed = qx * (1 - cdf(1.3)) + RHO * SX * phi(1.3)
print(f"sim E_Q[X 1(Y>20)] = E_P[Z X 1_B] {m[7]:.4f}; E_Q[h(Y) 1_B] {m[8]:.4f}; closed form {qclosed:.4f}")
print(f"sim gap E_Q[X 1_B] - E_Q[h(Y) 1_B]: standard error {math.sqrt(m[10] / N):.4f}")

# 5. four seasons, two kinds of month each, all 8 months equally likely; Z = X/55
seasons = [30, 60, 90, 40]
omega = [(s, mu + d) for s, mu in enumerate(seasons) for d in (-10, 10)]
P, Z = F(1, 8), {x: F(x, 55) for _, x in omega}
g = [sum(P * x for t, x in omega if t == s) / F(1, 4) for s in range(4)]
bay = [sum(P * Z[x] * x for t, x in omega if t == s) / sum(P * Z[x] for t, x in omega if t == s) for s in range(4)]
naive = [sum(P * Z[x] * x for t, x in omega if t == s) / F(1, 4) for s in range(4)]
qs = [sum(P * Z[x] for t, x in omega if t == s) for s in range(4)]   # Q(S = s)
eqx = sum(P * Z[x] * x for _, x in omega)                              # E_Q[X] = E_P[Z X], month by month
tower = sum(F(1, 4) * g[s] / 55 * bay[s] for s in range(4))           # Q(S=s) = P(S=s) E_P[X|S=s]/55
print(f"table months, each 0.125, each kind 0.5 within its season, rainfall by season: {'; '.join(', '.join(str(x) for t, x in omega if t == s) for s in range(4))}")
print(f"table g(s) = E_P[X|S=s]: {', '.join(str(t) for t in g)}")
print(f"table E_Q[X|S=s] by Bayes: {', '.join(str(t) for t in bay)}; without dividing: {', '.join(str(t) for t in naive)}")
print(f"table Q(S=s): {', '.join(str(q) for q in qs)}; E_Q[X] = {eqx} directly, {tower} by the tower")

assert max(abs(d - line(y)) for d, y in zip(dens, ys)) < 1e-6            # density ratio = line
assert abs(lhs - closed) < 1e-6 and abs(rhs - closed) < 1e-6              # defining property
assert abs(kern - dbl) < 1e-6 and abs(m[4] - kern) < 4 * math.sqrt(kern / N)  # kernel, 3 roads
assert max(abs(b - h_line(y)) for b, y in zip(bayes, ys)) < 1e-6          # Bayes = Q-line
assert abs(m[0] - m[1]) < 4 * math.sqrt(m[9] / N) and abs(m[7] - m[8]) < 4 * math.sqrt(m[10] / N)
assert [F(s * s + 100, s) for s in seasons] == bay and tower == eqx       # exact table; tower under Q
print("ALL CHECKS PASS")
