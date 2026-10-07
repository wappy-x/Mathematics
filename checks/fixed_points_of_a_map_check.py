# Fixed points of a map -- the check behind the card.  Standard library only.
# The map is the logistic rule g(x) = r x (1 - x): x is this summer's population
# as a fraction of what the habitat holds.  Every fixed point and slope is found
# twice: by formula, and by pressing the map, Newton's method or measurement.
def g(r, x): return r * x * (1 - x)

def press(r, x, n):                          # apply the map n times
    for _ in range(n): x = g(r, x)
    return x

def slope(f, x, h=1e-6): return (f(x + h) - f(x - h)) / (2 * h)

def newton_fixed(r, x):                      # Newton's method on G(x) = g(x) - x
    for k in range(1, 50):
        step = (g(r, x) - x) / (r * (1 - 2 * x) - 1)
        x -= step
        if abs(step) < 1e-15: return x, k
    return x, 50

def euler(h, n, x=0.2):                      # Euler steps of x' = x(1 - x), step h
    for _ in range(n): x += h * x * (1 - x)
    return x

def ratio(r): return (g(r, 1 - 1 / r + 1e-6) - (1 - 1 / r)) / 1e-6   # gap after / gap before
def gaps(r, n): return ", ".join(f"{(press(r, 1 - 1 / r + 0.02, k) - (1 - 1 / r)) * 100:.2f}" for k in range(n + 1))

fx28, it28 = 1 - 1 / 2.8, press(2.8, 0.2, 200)
m28, m32 = slope(lambda x: g(2.8, x), fx28), slope(lambda x: g(3.2, x), 0.6875)
win = [fx28 - 0.02 + 0.04 * i / 1000 for i in range(1001)]
L = max(abs(2.8 * (1 - 2 * x)) for x in win)
into = max(abs(g(2.8, x) - fx28) for x in win)
nw32, k32 = newton_fixed(3.2, 0.9)
a, b = sorted([press(3.2, 0.2, 1000), press(3.2, 0.2, 1001)])
cyc = sorted([euler(2.2, 1000), euler(2.2, 1001)])
cob, nx = [0.2], [1.0]
for _ in range(6): cob.append(g(2.8, cob[-1]))
for _ in range(4): nx.append(nx[-1] / 2 + 1 / nx[-1])
print(f"r = 2.8: fixed points 0 (slope r = 2.8) and 1 - 1/r = {fx28:.12f}")
print(f"r = 2.8: 200 presses of the map from x0 = 0.2 land on {it28:.12f}")
print(f"r = 2.8: slope 2 - r = {2 - 2.8:.6f}; measured by central difference {m28:.6f}; gap ratio {ratio(2.8):.6f}")
print(f"r = 2.8: window x* +/- 0.02: largest |slope| {L:.6f} (formula 0.8 + 2r(0.02) = {0.8 + 5.6 * 0.02:.6f}); largest |g(x) - x*| {into:.6f}")
print(f"r = 3.2: fixed point 1 - 1/r = {1 - 1 / 3.2:.12f}; Newton on g(x) - x from 0.9, {k32} steps: {nw32:.12f}")
print(f"r = 3.2: slope 2 - r = {2 - 3.2:.6f}; measured by central difference {m32:.6f}; gap ratio {ratio(3.2):.6f}")
print(f"r = 3.2: presses 1000 and 1001 from 0.2 alternate {a:.6f} and {b:.6f}, not 0.687500")
print(f"r = 3.0: slope -1; gap after 1000 presses from 0.2 {abs(press(3.0, 0.2, 1000) - 2 / 3):.6f}, after 4000 {abs(press(3.0, 0.2, 4000) - 2 / 3):.6f}")
print(f"chart, gap in hundredths, r = 2.8: {gaps(2.8, 12)}")
print(f"chart, gap in hundredths, r = 3.2: {gaps(3.2, 12)}")
print("figure, cobweb x0..x6 and x* at r = 2.8:", ", ".join(f"{v:.4f}" for v in cob + [fx28]), "| px 50 + 200x:", ", ".join(f"{50 + 200 * v:.1f}" for v in cob + [fx28]))
print("figure, curve y = g(x) at x = 0, 0.1, ..., 1, px 220 - 200y:", ", ".join(f"{220 - 200 * g(2.8, i / 10):.1f}" for i in range(11)))
print("Newton for x^2 = 2 from 1:", ", ".join(f"{v:.12f}" for v in nx[1:]))
print(f"Newton map x/2 + 1/x: slope at sqrt 2 measured {abs(slope(lambda t: t / 2 + 1 / t, 2 ** 0.5)):.6f}; errors",
      ", ".join(f"{abs(v - 2 ** 0.5):.9f}" for v in nx[1:4]))
print(f"Newton for (x - 1)^2 = 0: map (x + 1)/2, slope measured {slope(lambda t: t - (t - 1) / 2, 1.0):.6f}")
print(f"Euler steps of x' = x(1 - x): h = 1.8 lands on {euler(1.8, 200):.6f}; h = 2.2 alternates {cyc[0]:.6f}, {cyc[1]:.6f}")
print(f"mistake, slope read at x0 = 0.2 instead of x*: 2.8(1 - 0.4) = {2.8 * (1 - 0.4):.6f}")
assert abs(it28 - fx28) < 1e-12 and abs(nw32 - 0.6875) < 1e-12   # iteration and Newton find the formula's points
assert abs(ratio(2.8) - (2 - 2.8)) < 1e-4 and abs(m32 - (2 - 3.2)) < 1e-6   # measured slopes match 2 - r
assert L < 1 and abs(L - 0.912) < 1e-9 and into < 0.02 and abs(b - 0.6875) > 0.1   # window contracts at 2.8; 3.2 lets go
assert abs(cyc[0] - a * 3.2 / 2.2) + abs(cyc[1] - b * 3.2 / 2.2) < 1e-9 and abs(euler(1.8, 200) - 1) < 1e-9
print("ALL CHECKS PASS")
