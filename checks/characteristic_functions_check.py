# Characteristic functions -- the check behind the card.  Standard library only.
# Nothing imported knows a characteristic function: every average below is a
# finite sum or a Simpson integral written here, and each closed form on the
# card is compared with it.  Dice totals are counted exactly with integers.
from fractions import Fraction
from math import cos, sin, exp, sqrt, pi

def e(x): return complex(cos(x), sin(x))          # the point at angle x on the unit circle

def cf_die(t):                                    # road 1: the definition, six points averaged
    return sum(e(t * k) for k in range(1, 7)) / 6
def cf_die6(t): return sum(e(t * k) for k in range(7, 13)) / 6   # die + 6, from its own faces 7 to 12

def cf_die_closed(t):                             # road 2: the geometric series summed
    return e(3.5 * t) * sin(3 * t) / (6 * sin(t / 2))

def c(s):                                         # the centred die, X - 3.5: a real number
    return sin(3 * s) / (6 * sin(s / 2)) if s != 0 else 1.0

def simpson(f, a, b, n):
    h = (b - a) / n
    return (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))) * h / 3
def dens(x): return exp(-x * x / 2) / sqrt(2 * pi)              # standard normal density
def cf_normal_int(t): return simpson(lambda x: cos(t * x) * dens(x), -12.0, 12.0, 2400)

def cf_normal_ode(t, steps=1000):                 # road 3: solve phi' = -s phi, phi(0) = 1 (RK4)
    h, y, s = t / steps, 1.0, 0.0
    for _ in range(steps):
        k1 = -s * y; k2 = -(s + h / 2) * (y + h / 2 * k1)
        k3 = -(s + h / 2) * (y + h / 2 * k2); k4 = -(s + h) * (y + h * k3)
        y, s = y + h * (k1 + 2 * k2 + 2 * k3 + k4) / 6, s + h
    return y

def ways(n):                                      # exact number of ways to roll each total
    w = [1]
    for _ in range(n):
        new = [0] * (len(w) + 6)
        for s, m in enumerate(w):
            for k in range(1, 7):
                new[s + k] += m
        w = new
    return w                                      # w[s] = ways to total s; 6^n in all
def cz(z): return f"{z.real:+.6f} {z.imag:+.6f}i"
def row(label, *vals): print(f"{label:<50}" + "  ".join(vals))

# ---- the die at t = 0.5: six points on the circle, and their average ----
t = 0.5
d1, d2 = cf_die(t), cf_die_closed(t)
print("die at t = 0.5, cos then sin of 0.5k:", " ".join(f"{f(t * k):.4f}" for f in (cos, sin) for k in range(1, 7)))
row("die phi(0.5): six points averaged / closed form", cz(d1), cz(d2))
row("size |phi(0.5)| = sin 1.5 / (6 sin 0.25)", f"{c(t):.6f}", f"{abs(d1):.6f}")
pts = [(180 + 90 * cos(t * k), 130 - 90 * sin(t * k)) for k in range(1, 7)]
print("figure, points 1-6 (x y):", " ".join(f"{x:.1f} {y:.1f}" for x, y in pts))
print(f"figure, average (x y): {180 + 90 * d1.real:.1f} {130 - 90 * d1.imag:.1f}")
assert abs(d1 - d2) < 1e-12                       # the sum against the closed form

# ---- the uniform on [0, 1] and the standard normal, each two or three ways ----
u_int = simpson(lambda x: e(x), 0.0, 1.0, 200)    # t = 1: integral of e^(ix) against length
u_closed = (e(1.0) - 1) / 1j
row("uniform phi(1), Simpson / (e^i - 1)/i", cz(u_int), cz(u_closed))
n_int, n_ode = cf_normal_int(1.0), cf_normal_ode(1.0)
row("normal phi(1), Simpson / ODE / e^(-1/2)", f"{n_int:.9f}", f"{n_ode:.9f}", f"{exp(-0.5):.9f}")
assert abs(u_int - u_closed) < 1e-9               # Simpson against the integral done by hand
assert max(abs(n_int - n_ode), abs(n_ode - exp(-0.5))) < 1e-9  # three roads to the normal's phi(1)

# ---- moments from derivatives at 0, against exact sums ----
h = 1e-4
m1 = ((cf_die(h) - cf_die(-h)) / (2 * h)).imag
m2 = -((cf_die(h) - 2 + cf_die(-h)) / (h * h)).real
ex1, ex2 = sum(Fraction(k, 6) for k in range(1, 7)), sum(Fraction(k * k, 6) for k in range(1, 7))
row("die E X: phi'(0)/i, exact 21/6", f"{m1:.4f}", f"{float(ex1):.6f}")
row("die E X^2: -phi''(0), exact 91/6", f"{m2:.4f}", f"{float(ex2):.6f}")
row("die variance 91/6 - 3.5^2 = 35/12", f"{float(ex2 - ex1 ** 2):.6f}", f"sd {sqrt(35 / 12):.6f}")
assert abs(m1 - float(ex1)) < 1e-6                 # slope at 0 against the exact mean
assert abs(m2 - float(ex2)) < 1e-4                 # curvature at 0 against the exact E X^2

# ---- the n-roll total: its law's average equals phi^n ----
w2, w100 = ways(2), ways(100)
row("two dice, P(total 7): count / 36", f"{w2[7]}/36 = {w2[7] / 36:.6f}")
t = 0.05
direct = sum(m * e(t * s) for s, m in enumerate(w100)) / 6 ** 100
row("100 rolls phi(0.05): from the law / phi^100", cz(direct), cz(cf_die(t) ** 100))
assert abs(direct - cf_die(t) ** 100) < 1e-12
row("100 rolls: mean, variance, sd", "350", f"{100 * 35 / 12:.2f}", f"{sqrt(100 * 35 / 12):.2f}")

# ---- reading the law back: inversion on the integers ----
M = 1024
inv = sum(e(-350 * 2 * pi * j / M) * cf_die(2 * pi * j / M) ** 100 for j in range(M)).real / M
exact = Fraction(w100[350], 6 ** 100)
row("P(100 rolls total 350): exact / inversion", f"{float(exact):.9f}", f"{inv:.9f}")
assert abs(inv - float(exact)) < 1e-12

# ---- Levy in action: the scaled total W_n = (S_n - 3.5n)/sqrt(35n/12) ----
sd1 = sqrt(35 / 12)
def cf_w(n, t): return c(t / (sd1 * sqrt(n))) ** n
row("phi_Wn(1), n = 1, 10, 100, 1000", *(f"{cf_w(n, 1.0):.6f}" for n in (1, 10, 100, 1000)))
row("  limit e^(-1/2)", f"{exp(-0.5):.6f}")
Phi1 = 0.5 + simpson(dens, 0.0, 1.0, 200)
cdf = []
for n in (10, 100, 400):
    w = ways(n)
    cut = int(3.5 * n + sqrt(35 * n / 12))    # W_n <= 1 exactly when S_n <= this total
    cdf.append(sum(w[: cut + 1]) / 6 ** n)
row("P(W_n <= 1), n = 10, 100, 400", *(f"{p:.6f}" for p in cdf))
row("  normal Phi(1)", f"{Phi1:.6f}")
row("running average: phi(1/n)^n, n = 10, 100, 1000", *(cz(cf_die(1 / n) ** n) for n in (10, 100, 1000)))
row("  the constant 3.5: e^(3.5i)", cz(e(3.5)))
assert abs(cf_w(1000, 1.0) - n_ode) < 1e-3        # the die's phi against the normal's

# ---- what breaks ----
indep, copy = cf_die(0.5) ** 2, cf_die(1.0)
row("two dice vs one die doubled, |phi(0.5)|", f"{abs(indep):.6f}", f"{abs(copy):.6f}")
gap, gap1 = max(abs(cf_die6(k * pi / 3) - cf_die(k * pi / 3)) for k in range(1, 13)), abs(cf_die6(1.0) - cf_die(1.0))
row("die vs die + 6: max gap at t = k pi/3, k<=12", f"{gap:.6f}")
row("die vs die + 6: gap at t = 1", f"{gap1:.6f}")
assert gap < 1e-12                                 # die + 6 from its own faces agrees at every k pi/3
assert abs(gap1 - 2 * abs(sin(3.0)) * abs(cf_die(1.0))) < 1e-12   # and at t = 1 differs by |e^(6i) - 1| |phi(1)|
near = []
for n in (4, 36, 400):
    w, m = ways(n), round(3.5 * n)
    near.append(sum(w[m - 5: m + 6]) / 6 ** n)
row("unscaled T_n = S_n - 3.5n, |phi(0.5)|, n=4,36,400", *(f"{abs(c(0.5)) ** n:.6f}" for n in (4, 36, 400)))
row("  P(|T_n| <= 5), n = 4, 36, 400", *(f"{p:.6f}" for p in near))
bw = simpson(lambda s: 1 - cf_w(100, s), -1.0, 1.0, 2000)
bt = simpson(lambda s: 1 - c(s) ** 400, -1.0, 1.0, 2000)
w4 = ways(400)
tail_t = 1 - sum(w4[1398:1403]) / 6 ** 400
tail_w = 1 - sum(w100[s] for s in range(6 * 100 + 1) if abs(s - 350) <= 2 * 10 * sd1) / 6 ** 100
row("tail bound u=1: W_100 P(|W|>2) <= integral", f"{tail_w:.6f}", f"{bw:.6f}")
row("tail bound u=1: T_400 P(|T|>2) <= integral", f"{tail_t:.6f}", f"{bt:.6f}")
assert tail_w <= bw                                # the tail inequality, exact side <= integral
assert tail_t <= bt

# ---- the two charts ----
print("figure, |phi(t)| at t = k pi/12:", " ".join(f"{abs(cf_die(k * pi / 12)):.2f}" for k in range(25)))
print("figure, |phi(t)|^4:            ", " ".join(f"{abs(cf_die(k * pi / 12)) ** 4:.2f}" for k in range(25)))
print("figure, t labels:               ", " ".join(f"{k * pi / 12:.2f}" for k in range(25)))
for n in (1, 4):
    print(f"figure, phi_W{n}(t), t = 0..3:", " ".join(f"{cf_w(n, k / 4):.2f}" for k in range(13)))
print("figure, normal e^(-t^2/2):", " ".join(f"{cf_normal_int(k / 4):.2f}" for k in range(13)))
