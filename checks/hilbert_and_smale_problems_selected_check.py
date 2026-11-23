# Hilbert's and Smale's lists -- the check behind the card.  Standard library only.
# The ledger: both lists' statuses, typed twice (row by row, and as problem numbers
# under each status) and cross-checked, then tallied.  Then three computations, each
# against a second road: Matiyasevich's 1970 Fibonacci lemma, by direct remainders and
# by the card's formula; limit cycles of a degree-7 field, by a computed return map
# against the exact radii; Newton's method on x^5 - x - 1 against bisection.
import math
HIL = "SMSVSVSOMSMMMSVOSSSVSSV"   # S answered: proved, M partly, O open, V kind note
SMA = "OSOOOMOVOMMMOSOMSV"
BY_STATUS = {"hilbert": ("1 3 5 7 10 14 17 18 19 21 22", "2 9 11 12 13", "8 16", "4 6 15 20 23"),
             "smale": ("2 14 17", "6 10 11 12 16", "1 3 4 5 7 9 13 15", "8 18")}   # typed again, by status
PICKS = [("Hilbert 8", "O", "Riemann hypothesis, Goldbach, twin primes", "open"),
         ("Hilbert 10", "S", "a test for whole-number solutions", "no test exists: proved 1970"),
         ("Hilbert 16", "O", "most limit cycles at degree n", "open; degree 2 has at least 4, 1979"),
         ("Smale 3", "O", "P versus NP", "open"),
         ("Smale 15", "O", "Navier-Stokes smooth for all time", "open; a 2026-09 forced blow-up claim is unrefereed"),
         ("Smale 17", "S", "polynomial roots fast on average", "proved: randomised 2009, deterministic 2017")]
for name, codes in (("hilbert", HIL), ("smale", SMA)):
    t = [codes.count(c) for c in "SMOV"]
    print(f"{name:<7} 1-{len(codes)}: {' '.join(codes)}")
    print(f"{name:<7} tally: proved {t[0]}, partly {t[1]}, open {t[2]}, kind note {t[3]}, total {sum(t)}")
    rows = [" ".join(str(i + 1) for i, x in enumerate(codes) if x == c) for c in "SMOV"]
    assert sum(t) == len(codes) and tuple(rows) == BY_STATUS[name]   # the two typings agree
print("on both lists: Hilbert 8 = Smale 1 (Riemann), Hilbert 16 = Smale 13 (limit cycles)")
assert HIL[7] == SMA[0] and HIL[15] == SMA[12]   # one problem, typed in both lists
for name, code, what, status in PICKS:
    lst, num = name.split()
    assert (HIL if lst == "Hilbert" else SMA)[int(num) - 1] == code   # lines match ledger
    print(f"{name:<11}{what:<43}{status}")
print("unknowns over 0,1,2,...: 1 decidable; 9 undecidable; 2 to 8 open")

def fib(m):                                   # exact Fibonacci number F_m
    a, b = 0, 1
    for _ in range(m): a, b = b, a + b
    return a
sols = [(a, b) for b in range(1, 1001) for a in range(b + 1) if (b * b - a * b - a * a) ** 2 == 1]
nbr = [(fib(k), fib(k + 1)) for k in range(30) if fib(k + 1) <= 1000]
print(f"(b^2 - ab - a^2)^2 = 1 with 0 <= a <= b <= 1000: {len(sols)} solutions, (F_k, F_k+1) for k = 0..{len(nbr) - 1}")
assert sols == nbr                            # neighbouring Fibonacci pairs, and nothing else
print("F_5k for k = 1..5:", " ".join(str(fib(5 * k)) for k in range(1, 6)),
      "| remainders mod 25:", " ".join(str(fib(5 * k) % 25) for k in range(1, 6)))
form = [k * 5 * 3 ** (k - 1) for k in range(1, 6)]
print("formula k F_5 F_4^(k-1):", " ".join(map(str, form)), "| mod 25:", " ".join(str(v % 25) for v in form),
      f"| F_25 = 25 x {fib(25) // 25}")
N_MAX, K_MAX = 20, 200
road1 = road2 = rule = plain = 0
for n in range(3, N_MAX + 1):
    fn, fm1 = fib(n), fib(n - 1)
    sq, a, b = fn * fn, 0, 1                  # F_m mod F_n^2, stepping m upward
    for m in range(1, n * K_MAX + 1):
        a, b = b, (a + b) % sq
        if m % n: continue
        k = m // n
        d1 = a == 0                           # road 1: the remainder itself
        rem = k * fn * pow(fm1, k - 1, sq) % sq   # road 2: the card's formula
        d2 = rem == 0
        d3 = k % fn == 0                      # the rule: F_n divides k
        assert rem == a and d1 == d2 == d3   # formula = true remainder
        road1 += d1; road2 += d2; rule += d3; plain += a % fn == 0
pairs = (N_MAX - 2) * K_MAX
print(f"pairs 3 <= n <= {N_MAX}, 1 <= k <= {K_MAX}: {pairs}; F_n^2 | F_nk in {road1} (remainder), "
      f"{road2} (formula), {rule} (F_n | k)")
print(f"square dropped: F_n | F_nk in {plain} of {pairs}")
print(f"n = 2: F_2 = {fib(2)} divides F_3 = {fib(3)}, but 2 does not divide 3")
print(f"n = {N_MAX}: F_n = {fib(N_MAX)}, so F_n^2 | F_m forces m to be a multiple of {N_MAX * fib(N_MAX)}")
assert rule == sum(K_MAX // fib(n) for n in range(3, N_MAX + 1)) and plain == pairs
assert fib(25) == 25 * 3001 and fib(2) == 1

TWO_PI = 6.283185307179586
def P(s): return (1 - s) * (4 - s) * (9 - s) / 10
def field(x, y):
    p = P(x * x + y * y)
    return -y + x * p, x + y * p
def turn(r0, steps=2000):                     # one full turn: theta' = 1, time 2 pi
    x, y, h = r0, 0.0, TWO_PI / steps
    for _ in range(steps):                    # classical Runge-Kutta, written out
        k1 = field(x, y)
        k2 = field(x + h / 2 * k1[0], y + h / 2 * k1[1])
        k3 = field(x + h / 2 * k2[0], y + h / 2 * k2[1])
        k4 = field(x + h * k3[0], y + h * k3[1])
        x += h / 6 * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0])
        y += h / 6 * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1])
    return math.sqrt(x * x + y * y) - r0     # return-map displacement d(r0)
grid = [0.55 + 0.3 * i for i in range(11)]
d = [turn(r) for r in grid]
print("r on the ray:", " ".join(f"{r:.2f}" for r in grid))
print("d(r) after one turn:", " ".join(f"{v:.3f}" for v in d))
cycles = []
for i in range(len(grid) - 1):
    if (d[i] > 0) != (d[i + 1] > 0):          # a sign change: a cycle in between
        lo, hi = grid[i], grid[i + 1]
        for _ in range(40):
            mid = (lo + hi) / 2
            if (turn(mid) > 0) == (d[i] > 0): lo = mid
            else: hi = mid
        cycles.append(((lo + hi) / 2, "stable" if d[i] > 0 else "unstable"))
print("degree-7 field, cycles found:", "; ".join(f"r = {r:.6f} {s}" for r, s in cycles))
coarse = [turn(r) > 0 for r in (0.55, 2.65, 3.55)]
print("coarse ray r = 0.55, 2.65, 3.55: sign changes", sum(coarse[i] != coarse[i + 1] for i in range(2)))
assert len(cycles) == 3 and all(abs(r - (j + 1)) < 1e-6 for j, (r, _) in enumerate(cycles))

def sci(v):                                   # 3 significant digits, same in Rust
    e = 0
    while v < 1: v, e = v * 10, e - 1
    return f"{v:.2f}e{e}"
f = lambda x: x * x * x * x * x - x - 1
lo, hi = 1.0, 2.0
for _ in range(60):                           # bisection: f(1) < 0 < f(2)
    mid = (lo + hi) / 2
    if f(mid) < 0: lo = mid
    else: hi = mid
root = lo
def newton(x, tol=1e-12):
    errs = [abs(x - root)]
    while errs[-1] > tol and len(errs) <= 1000:
        x -= f(x) / (5 * x * x * x * x - 1)
        errs.append(abs(x - root))
    return errs, x
e, _ = newton(1.0)
c = 10 * root * root * root / (5 * root * root * root * root - 1)   # f''/(2 f') at the root
print(f"x^5 - x - 1: root by bisection {root:.12f}")
print("Newton from 1, errors:", " ".join(sci(v) for v in e[:5]))
print(f"e4 / e3^2 = {e[4] / (e[3] * e[3]):.4f}, predicted f''/(2f') = {c:.4f}")
z, x = newton(0.0)
loop = [x]
while len(loop) < 10 and (len(loop) < 2 or abs(loop[-1] - loop[0]) > 1e-9):
    loop.append(loop[-1] - f(loop[-1]) / (5 * loop[-1] * loop[-1] * loop[-1] * loop[-1] - 1))
print(f"steps to 1e-12: from 1, {len(e) - 1}; from 0, none in {len(z) - 1}: it repeats",
      " ".join(f"{v:.4f}" for v in loop[:-1]))
assert abs(f(root)) < 1e-12 and abs(e[4] / (e[3] * e[3]) - c) < 0.02 * c and len(loop) == 4
print("ALL CHECKS PASS")
