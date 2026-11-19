# Three distances -- the check behind the card.  Standard library only; sqrt and
# floor are the only imports.  A sequencer adds one hit per bar, alpha = 0.618...
# of a loop further on each time (a step of the golden ratio, 1.618 loops, lands
# in the same place).  The gaps between hits are found by three roads:
# road 1 sorts the hits and measures every gap; road 2 is the neighbour rule,
# built from the two closest returns a and b; road 3 reads the gaps off the
# Fibonacci numbers, the golden ratio's convergent denominators.
from math import sqrt, floor

LOOP = 2000.0                                   # one 4/4 bar at 120 bpm, in ms
PHI = (1 + sqrt(5)) / 2
ALPHA = PHI - 1
STEPS = [("golden", ALPHA), ("sqrt2-1", sqrt(2) - 1),
         ("e-2", 2.718281828459045 - 2), ("pi-3", 3.141592653589793 - 3)]

def frac(x):                                    # {x}: the part after the point
    return x - floor(x)

def gaps(pts):                                  # road 1: sort, measure round the loop
    s = sorted(pts)
    return [s[i + 1] - s[i] for i in range(len(s) - 1)] + [1 - s[-1] + s[0]]

def tally(gs):                                  # distinct lengths with their counts
    out = []
    for g in sorted(gs):
        if out and g - out[-1][0] < 1e-9:
            out[-1][1] += 1
        else:
            out.append([g, 1])
    return out

def rule(alpha, n):                             # road 2: closest returns either side
    a = min(range(1, n), key=lambda k: frac(k * alpha))
    b = max(range(1, n), key=lambda k: frac(k * alpha))
    u, v = frac(a * alpha), 1 - frac(b * alpha)
    t = sorted([[u, n - a], [v, n - b], [u + v, a + b - n]])
    return a, b, u, v, [x for x in t if x[1] > 0]

def fib_rule(n):                                # road 3: F_k < n <= F_(k+1)
    F = [0, 1]
    while F[-1] < n:
        F.append(F[-1] + F[-2])
    k = len(F) - 2
    t = [[PHI ** -k, n - F[k]], [PHI ** (1 - k), n - F[k - 1]], [PHI ** (2 - k), F[k + 1] - n]]
    return [x for x in t if x[1] > 0]

def same(t1, t2):
    return len(t1) == len(t2) and all(c1 == c2 and abs(g1 - g2) < 1e-9
                                      for (g1, c1), (g2, c2) in zip(t1, t2))

def ms(t):
    return ", ".join(f"{g * LOOP:.3f} ms x {c}" for g, c in t)

def yn(b):
    return "yes" if b else "no"

def cfrac(x, terms):                            # whole part, then flip
    out = []
    for _ in range(terms):
        out.append(floor(x))
        x = 1 / (x - floor(x))
    return out

print(f"step alpha = {ALPHA:.12f} of a {LOOP:.0f} ms loop; continued fraction {cfrac(ALPHA, 10)}")
F = [1, 1]
while len(F) < 12:
    F.append(F[-1] + F[-2])
print(" q   q x alpha  nearest  distance   phi^-k     side of the downbeat")
for k, q in enumerate(F[1:9], start=2):
    d = q * ALPHA - round(q * ALPHA)
    print(f"{q:2d} {q * ALPHA:10.6f} {round(q * ALPHA):5d}  {abs(d):9.6f} {PHI ** -k:9.6f}"
          f"    {'after' if d > 0 else 'before'}")
N = 10
pts = [frac(n * ALPHA) for n in range(N)]
print("hit of bar n, ms:", " ".join(f"{p * LOOP:.1f}" for p in pts))
print("gaps round the loop from the downbeat, ms:", " ".join(f"{g * LOOP:.1f}" for g in gaps(pts)))
brute = tally(gaps(pts))
a, b, u, v, pred = rule(ALPHA, N)
p, r = floor(a * ALPHA), floor(b * ALPHA) + 1
print(f"road 1, sorted gaps: {len(brute)} lengths: {ms(brute)}")
print(f"road 2, a = {a}, u = {u * LOOP:.3f} ms; b = {b}, v = {v * LOOP:.3f} ms; "
      f"counts N-a = {N - a}, N-b = {N - b}, a+b-N = {a + b - N}")
print(f"road 3, F = 8 < N <= 13: {ms(fib_rule(N))}")
print(f"longest = u + v: {u * LOOP:.3f} + {v * LOOP:.3f} = {(u + v) * LOOP:.3f} ms")
print(f"p = {p}, r = {r}: a*r - b*p = {a * r - b * p}; b*u + a*v = {b * u + a * v:.12f}")
print(" N  lengths   a   b  shortest, ms  longest, ms")
for n in range(2, 15):
    t, (a2, b2) = tally(gaps([frac(k * ALPHA) for k in range(n)])), rule(ALPHA, n)[:2]
    print(f"{n:2d}  {len(t):5d}  {a2:3d} {b2:3d}  {t[0][0] * LOOP:11.3f}  {t[-1][0] * LOOP:10.3f}")
TOP, ok, worst, det, fib_ok = 2000, True, {}, True, True
for name, al in STEPS:
    w, three = 1.0, 0
    for n in range(2, TOP + 1):
        t = tally(gaps([frac(k * al) for k in range(n)]))
        a2, b2, u2, v2, pr = rule(al, n)
        ok = ok and len(t) <= 3 and same(t, pr)
        det = det and a2 * (floor(b2 * al) + 1) - b2 * floor(a2 * al) == 1
        if name == "golden":
            fib_ok = fib_ok and same(t, fib_rule(n))
        three += len(t) == 3
        w = max(w, t[-1][0] / t[0][0])
    worst[name] = w
    print(f"{name:8s} N = 2..{TOP}: three lengths at {three} N; worst longest/shortest {w:.6f}")
print(f"continued fraction of pi-3: {cfrac(STEPS[3][1], 5)}")
print(f"road 1 = road 2 at every N, never more than 3 lengths: {yn(ok)}; a*r - b*p = 1 always: {yn(det)}")
print(f"road 1 = road 3 for the golden step, N = 2..{TOP}: {yn(fib_ok)}")
two = [n for n in range(2, 101) if len(tally(gaps([frac(k * ALPHA) for k in range(n)]))) == 2]
print(f"N up to 100 with only two lengths: {two}")
q16 = [frac(n * 10 / 16) for n in range(N)]
sq = tally(gaps([frac(n * n * ALPHA) for n in range(N)]))
M, s, rnd = 2 ** 64 - 1, 2026, []
for _ in range(N):
    s = (s + 0x9E3779B97F4A7C15) & M
    z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & M
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M
    rnd.append(((z ^ (z >> 31)) >> 11) / 2 ** 53)
rt = tally(gaps(rnd))
print(f"mistake 1, step rounded to 10/16 of the loop: {len(set(q16))} places for {N} hits")
print(f"mistake 2, bar n at n*n*alpha: {len(sq)} lengths, longest/shortest {sq[-1][0] / sq[0][0]:.6f}")
print(f"mistake 3, {N} random places (SplitMix64, seed 2026): {len(rt)} lengths, "
      f"longest/shortest {rt[-1][0] / rt[0][0]:.6f}")
assert same(brute, pred) and same(brute, fib_rule(N)) and [a, b] == [5, 8]
assert ok and det and fib_ok and abs(worst["golden"] - PHI ** 2) < 1e-6
assert two == [f for f in F[2:] if f <= 100]
assert len(set(q16)) == 8 and len(sq) > 3 and len(rt) == N
print("ALL CHECKS PASS")
