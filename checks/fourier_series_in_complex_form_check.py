# Fourier series of a square wave -- the check behind the card.  Standard library.
# f(x) = +1 on (0, pi), -1 on (-pi, 0), repeating every 2 pi: a synthesiser's square tone.
# Road 1: the closed form c_n = 2/(i pi n) for odd n, 0 for even n.
# Road 2: each c_n as an average, (1/2 pi) times the integral of f(x) e^(-inx), by Simpson's rule.
# Parseval, the mean-square error and the Gibbs peak each get a second road as well.
import math
PI = math.pi

def show(w):                                  # 'a + bi', six decimals, no -0.000000
    a, b = round(w.real, 6) + 0.0, round(w.imag, 6) + 0.0
    return f"{a:.6f} {'-' if b < 0 else '+'} {abs(b):.6f}i"

def simpson(g, a, b, m=2000):                 # m even panels
    h = (b - a) / m
    return (g(a) + g(b) + sum((4 if k % 2 else 2) * g(a + k * h) for k in range(1, m))) * h / 3

def spin(n, x): return complex(math.cos(n * x), math.sin(n * x))                  # e^(inx)
def average(g): return (simpson(g, 0, PI) - simpson(g, -PI, 0)) / (2 * PI)        # of f(x) g(x)
def closed(n): return 2 / (1j * PI * n) if n % 2 else 0j
def partial(x, N): return sum(closed(n) * spin(n, x) for n in range(-N, N + 1)).real  # S_N(x)

ns = range(-7, 8)
numeric = {n: average(lambda x: spin(-n, x)) for n in ns}
print("c_n closed form, n = 1, 3, 5: " + ", ".join(show(closed(n)) for n in (1, 3, 5)))
print("c_n by averaging, n = 1, 3, 5: " + ", ".join(show(numeric[n]) for n in (1, 3, 5)))
print("c_n by averaging, n = 0, 2, -1: " + ", ".join(show(numeric[n]) for n in (0, 2, -1)))
b_conv = [(1j * (closed(n) - closed(-n))).real for n in (1, 3, 5)]
b_real = [average(lambda x: math.sin(n * x)) * 2 for n in (1, 3, 5)]
print("b_n = i(c_n - c_-n), n = 1, 3, 5: " + ", ".join(f"{b:.6f}" for b in b_conv) + "; by (1/pi) int f sin nx: " + ", ".join(f"{b:.6f}" for b in b_real))
print(f"a_n = c_n + c_-n, n = 1, 3: {(closed(1) + closed(-1)).real:.6f}, {(closed(3) + closed(-3)).real:.6f}; tone 220 Hz: harmonics at {220}, {3 * 220}, {5 * 220} Hz")
xs = [k * PI / 8 for k in range(17)]
print("chart, square wave: " + ", ".join(f"{(0 if k % 8 == 0 else 1 if k < 8 else -1):.2f}" for k in range(17)))
for N, name in ((1, "first harmonic S_1"), (5, "three harmonics S_5")):
    print(f"chart, {name}: " + ", ".join(f"{round(partial(x, N), 2) + 0.0:.2f}" for x in xs))
arrow, partner = closed(1) * spin(1, PI / 4), closed(-1) * spin(-1, PI / 4)
print(f"arrows at x = pi/4: {show(arrow)} + {show(partner)} = {show(arrow + partner)}; |c_1| = {abs(closed(1)):.6f}")
print(f"figure, 160 per unit, origin (120, 120), arrow ({120 + 160 * arrow.real:.2f}, {120 - 160 * arrow.imag:.2f}), partner ({120 + 160 * partner.real:.2f}, {120 - 160 * partner.imag:.2f}), sum ({120 + 160 * (arrow + partner).real:.2f}, 120), radius {160 * abs(closed(1)):.2f}")
p5 = sum(abs(closed(n)) ** 2 for n in range(-5, 6))
odd = sum(1 / n ** 2 for n in range(1, 2 * 10 ** 6, 2)) + 1 / (4 * 10 ** 6)    # plus the tail, about 1/(2N)
print(f"Parseval: 1 + 1/9 + 1/25 = {1 + 1 / 9 + 1 / 25:.6f}; odd n to 2e6 plus tail = {odd:.9f}; pi^2/8 = {PI ** 2 / 8:.9f}")
S5 = lambda x: partial(x, 5)
msq = (simpson(lambda x: (1 - S5(x)) ** 2, 0, PI) + simpson(lambda x: (-1 - S5(x)) ** 2, -PI, 0)) / (2 * PI)
print(f"S_5: sum |c_n|^2 = {p5:.6f}; mean-square error by Parseval {1 - p5:.6f}, by integrating (f - S_5)^2 {msq:.6f}")
peaks = [max(partial(k * 4 * PI / ((N + 1) * 2000), N) for k in range(1, 2001)) for N in (5, 21, 101)]
gibbs = 2 / PI * simpson(lambda t: math.sin(t) / t if t else 1.0, 0, PI)
print("Gibbs peak of S_N, N = 5, 21, 101: " + ", ".join(f"{p:.6f}" for p in peaks) + f"; limit (2/pi) Si(pi) = {gibbs:.6f}")
print(f"hypothesis dropped, at the jump x = 0: S_5 = {partial(0, 5):.6f}, S_101 = {partial(0, 101):.6f}; f is -1 just left, +1 just right")
print(f"mistake, 1/pi for 1/2 pi: c_1 = {show(2 * closed(1))}, S_5(pi/2) = {2 * S5(PI / 2):.6f}; true S_5(pi/2) = {S5(PI / 2):.6f}")
flip = {n: average(lambda x: spin(n, x)) for n in range(-5, 6)}                    # e^(+inx) in the average
print(f"mistake, e^(+inx) in the average: c_1 = {show(flip[1])}, S_5(pi/2) = {sum(flip[n] * spin(n, PI / 2) for n in flip).real:.6f}")
half = sum(closed(n) * spin(n, PI / 2) for n in range(1, 200001, 2))
print(f"mistake, n > 0 only, n to 200000, at x = pi/2: {half.real:.4f} instead of 1")
assert all(abs(numeric[n] - closed(n)) < 1e-9 for n in ns)                        # average against formula
assert all(abs(u - v) < 1e-9 for u, v in zip(b_conv, b_real))                     # complex form against real form
assert abs(msq - (1 - p5)) < 1e-9 and abs(odd - PI ** 2 / 8) < 1e-9               # Parseval, two ways
assert peaks[0] > peaks[1] > peaks[2] > gibbs and peaks[2] - gibbs < 1e-3         # Gibbs does not go away
print("ALL CHECKS PASS")
