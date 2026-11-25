# Hilbert-Smith conjecture -- the check behind the card.  Standard library only,
# nothing imported.  The 3-adic integers are modelled by their last N = 6 digits,
# the clock Z/729; the circle is modelled by angles in hundredths of a degree.
# Roads: brute-force search against a counting formula, at every step.
N, M = 6, 3 ** 6                                     # six 3-adic digits, 729 points

def val(x):                                          # how many 3s divide x (N if x = 0)
    x %= M
    return N if x == 0 else next(k for k in range(N) if x % 3 ** (k + 1))

def digits(x):                                       # base-3 digits, last digit first
    return [x // 3 ** k % 3 for k in range(N)]

def pos(x):                                          # the Cantor map, in units of 1/5^6
    return sum(2 * d * 5 ** (N - 1 - k) for k, d in enumerate(digits(x)))

def show(x): return "".join(str(d) for d in reversed(digits(x)))

half = next(x for x in range(M) if 2 * x % M == 1)
print(f"-1 is ...{show(M - 1)}, 1/2 is ...{show(half)}, check 2 x {half} = {2 * half} = 1 + {M}")
print(f"3-adic size: |1| = 1, |3| = 1/3, |81| = 1/{3 ** val(81)}, |162| = 1/{3 ** val(162)}")

# 1. The Cantor picture: level n has 3^n pieces, each 1/5^n long, with gaps between.
print("level, pieces, piece length, total length, smallest gap")
for n in range(4):
    starts = sorted({sum(2 * (x // 3 ** k % 3) * 5 ** (N - 1 - k) for k in range(n)) for x in range(3 ** n)})
    L = 5 ** (N - n)
    gap = min(b - (a + L) for a, b in zip(starts, starts[1:])) if n else 0
    print(f"  {n}, {len(starts)}, 1/{5 ** n}, {3 ** n}/{5 ** n}, " + (f"{gap}/{5 ** N}" if n else "none"))
    assert len(starts) == 3 ** n and (n == 0 or gap == 5 ** (N - n)) and max(starts) + L <= 5 ** N
lo, hi = [5 ** N] * N, [0] * N                       # line distance against 3-adic distance
for x in range(M):
    for y in range(x + 1, M):
        v, d = val(y - x), abs(pos(y) - pos(x))
        lo[v], hi[v] = min(lo[v], d), max(hi[v], d)
print("agree in last v digits: 3-adic distance, line distance range (units of 1/5^6)")
for v in range(N):
    print(f"  v = {v}: 1/{3 ** v}, {lo[v]} to {hi[v]}")
    assert lo[v] == 5 ** (N - 1 - v) + 1 and hi[v] == 5 ** (N - v) - 1   # by the tail bound
assert all(hi[v + 1] < lo[v] for v in range(N - 1))   # closer 3-adically = closer on the line
px = lambda p: f"{20 + 480 * p / 5 ** N:.2f}"
print("figure," + ";".join(" ".join(px(sum(2 * (x // 3 ** k % 3) * 5 ** (N - 1 - k) for k in range(n)))
      for x in range(3 ** n)) for n in (1, 2, 3)) + f";widths {480 / 5:.1f} {480 / 25:.1f} {480 / 125:.2f}")

# 2. Small subgroups: every subgroup of the clock, found by generating, against divisors.
subs = sorted({frozenset(g * k % M for k in range(M)) for g in range(M)}, key=len, reverse=True)
print(f"subgroups of Z/{M} found by search: {len(subs)}; divisors of {M}: {sum(1 for d in range(1, M + 1) if M % d == 0)}")
for H in subs:
    n = min(val(x) for x in H)
    print(f"  3^{n} Z: {len(H)} point{"s" * (len(H) > 1)}, index {M // len(H)}, every point of size at most 1/{3 ** n}")
    assert H == {x for x in range(M) if val(x) >= n} and len(H) == 3 ** (N - n)   # ball = subgroup
ball = [x for x in range(M) if val(x) >= 1]
assert all(val(a + b) >= 1 and val(-a) >= 1 for a in ball for b in ball)       # closed, by brute force
least = min(val(81 * k) for k in range(1, M))       # fewest 3s dividing any multiple
print(f"multiples of 81 stay small: largest size among 81k is 1/{3 ** least}")
orders = [next(k for k in range(1, 3 ** m + 1) if 81 * k % 3 ** m == 0) for m in (6, 7, 8)]
print("order of 81 in Z/3^N for N = 6, 7, 8: " + ", ".join(map(str, orders)))
assert orders == [3 ** (m - 4) for m in (6, 7, 8)] and least == 4    # no finite bound

# 3. No small subgroups in the circle: every angle in the quarter-turn ball escapes it.
Q = 9000                                             # 90.00 degrees, in hundredths
esc = []
for a in range(1, Q):
    k, t = 1, a
    while min(t, 36000 - t) < Q:
        k, t = k + 1, (t + a) % 36000
    esc.append(k)
assert esc == [-(-Q // a) for a in range(1, Q)]       # brute force = ceil(9000 / a)
print(f"circle: all {len(esc)} angles 0.01 to {(Q - 1) / 100:.2f} degrees escape the ball of {Q // 100} degrees; "
      f"1 degree after {esc[99]} steps, 0.01 degrees after {esc[0]}")

# 4. Any homomorphism from the clock to the circle: a subgroup landing in the ball lands on 0.
inball = trivial = 0
for j in range(M):                                   # x -> j x / 729 of a turn
    for n in range(N + 1):
        img = {j * 3 ** n * k % M for k in range(M)}
        if all(min(i, M - i) * 4 < M for i in img):
            inball += 1; trivial += img == {0}
print(f"homomorphisms x -> jx/729 turn, subgroups 3^n Z: {inball} images inside the ball, {trivial} of them just 0")
assert inball == trivial == sum(1 for j in range(M) for n in range(N + 1) if j * 3 ** n % M == 0)

# 5. What breaks.
ker = [x for x in range(M) if x % 27 == 0]        # x acts as a turn of x/27: a 13.33 degree step
print(f"turn by x/27: {len(ker)} of {M} points act as no turn at all (kernel 27Z, index {M // len(ker)}); "
      f"step {36000 / 27 / 100:.2f} degrees")
orbit, x = 1, 1                                      # adding 1, the odometer, on the Cantor set
while x != 0:
    x, orbit = (x + 1) % M, orbit + 1
print(f"adding 1 on the Cantor set: one orbit of {orbit} points; ...{show(M - 1)} + 1 = ...{show(0)}")
fixers = [g for g in range(M) if any((y + g) % M == y for y in range(M))]
assert orbit == M and fixers == [0] and len(ker) == 27
print("dimension n, Yang's orbit-space dimension n + 2, status 2026-11-24")
for n, s in [(1, "proved, 1955"), (2, "proved, 1955"), (3, "proved, 2013"), (4, "open")]:
    print(f"  {n}{' and up' * (n == 4)}, {n + 2}{' and up' * (n == 4)}, {s}")
print("ALL CHECKS PASS")
