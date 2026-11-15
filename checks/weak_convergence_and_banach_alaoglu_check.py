# Weak convergence and Banach-Alaoglu -- the check behind the card.  Standard library only.
# A pace profile x(t) is a 10 km race's pace minus the 240 s/km target, in s/km, at
# fraction t of the distance.  Profiles live in L2(0, 1) with the orthonormal cosines
# c_k(t) = sqrt2 cos(k pi t).  Race n (illustrative numbers):
#   x_n = 6 cos(n) c_1 + 4 sin(n sqrt2) c_2 + 6 c_(n+2)     (start term, middle term, swaps)
# The code holds coefficients and finite grids only: it checks instances and trends;
# the infinite-dimensional claims rest on the proofs on the card.
import math

R2, M = math.sqrt(2), 200000

def split1(k):           # km-1 time lost by c_k, in s: 10 * integral of c_k over [0, 0.1]
    return 10 * R2 * math.sin(k * math.pi / 10) / (k * math.pi)

def grid(f, a, b, G):    # midpoint rule for the integral of f over [a, b]
    h = (b - a) / G
    return h * sum(f(a + (i + 0.5) * h) for i in range(G))

# 1. The picture: pure swap profiles 6 c_m.  Splits fade, size and peak stay.
print("swap profile 6 c_m: m | km-1 split s (formula, grid) | RMS s/km (grid) | peak | total")
chart = []
for m in (1, 2, 4, 8, 16, 32, 64):
    f = lambda t, m=m: 6 * R2 * math.cos(m * math.pi * t)
    s_a, s_g = 6 * split1(m), 10 * grid(f, 0, 0.1, 10000)
    rms = math.sqrt(grid(lambda t: f(t) ** 2, 0, 1, 20000))
    tot = 10 * grid(f, 0, 1, 20000)
    chart.append(s_a)
    print(f"  m={m:2d} | {s_a:7.3f} {s_g:7.3f} | {rms:.4f} | {6 * R2:.4f} | {abs(tot):.4f}")
    assert abs(s_a - s_g) < 1e-6 and abs(rms - 6) < 1e-9 and abs(tot) < 1e-6
print("  chart row:", ", ".join(f"{v:.2f}" for v in chart))

# 2. The races themselves: the start and middle terms jump about, so x_n has no weak limit.
start = [6 * math.cos(n) for n in range(1, M + 1)]
middle = [4 * math.sin(n * R2) for n in range(1, M + 1)]
def km1(n):              # km-1 split of race n, from the three coefficients
    return start[n - 1] * split1(1) + middle[n - 1] * split1(2) + 6 * split1(n + 2)
def rms(n):
    return math.sqrt(start[n - 1] ** 2 + middle[n - 1] ** 2 + 36)
print("races 1-8: start ", ", ".join(f"{start[n - 1]:.2f}" for n in range(1, 9)))
print("           middle", ", ".join(f"{middle[n - 1]:.2f}" for n in range(1, 9)))
print("           km-1  ", ", ".join(f"{km1(n):.2f}" for n in range(1, 9)))
print(f"  bound B = sqrt(36 + 16 + 36) = {math.sqrt(88):.4f}; largest RMS seen {max(rms(n) for n in range(1, M + 1)):.4f}")

# 3. The diagonal: halve the start term's range 6 times, then the middle term's inside it,
#    each time keeping the half that holds more of the later races, and pick the next race.
def inside(n, box, upto):
    return all(box[j][0] <= (start, middle)[j][n - 1] <= box[j][1] for j in range(upto + 1))
def diagonal(depth):
    box, last, picks, steps = [[-6.0, 6.0], [-4.0, 4.0]], 0, [], []
    for coord in (0, 1):
        vals = (start, middle)[coord]
        for _ in range(depth):
            lo, hi = box[coord]
            mid = (lo + hi) / 2
            cand = [n for n in range(last + 1, M + 1) if inside(n, box, coord)]
            low = sum(1 for n in cand if vals[n - 1] < mid)
            box[coord] = [lo, mid] if low >= len(cand) - low else [mid, hi]
            last = next(n for n in cand if box[coord][0] <= vals[n - 1] <= box[coord][1])
            picks.append(last)
            steps.append((coord, list(box[coord])))
    return box, picks, steps
box, picks, steps = diagonal(6)
print("picks n_k =", ", ".join(map(str, picks)))
print(f"  start box [{box[0][0]:.4f}, {box[0][1]:.4f}], middle box [{box[1][0]:.4f}, {box[1][1]:.4f}]")
a1, a2 = sum(box[0]) / 2, sum(box[1]) / 2
inbox = [n for n in range(1, M + 1) if inside(n, box, 1)]
law = ((math.acos(box[0][0] / 6) - math.acos(box[0][1] / 6)) / math.pi
       * (math.asin(box[1][1] / 4) - math.asin(box[1][0] / 4)) / math.pi)
print(f"  races n <= {M} in both boxes: {len(inbox)}; equidistribution predicts {M * law:.1f}")
print(f"  limit x = {a1:.4f} c_1 {a2:+.4f} c_2; km-1 split {a1 * split1(1) + a2 * split1(2):.4f} s;"
      f" RMS {math.hypot(a1, a2):.4f} s/km")
print(f"  by hand: c_1 reads {split1(1):.4f} s on km 1, c_2 {split1(2):.4f}; {a1 * split1(1):.4f} {a2 * split1(2):+.4f};"
      f" RMS^2 {a1 * a1:.4f} + {a2 * a2:.4f} = {a1 * a1 + a2 * a2:.4f}")
sq = [sorted(v * v for v in b) for b in box]                    # squared coefficients allowed by each box
print(f"  known only to the boxes: limit's km-1 split {box[0][0] * split1(1) + box[1][0] * split1(2):.4f} to"
      f" {box[0][1] * split1(1) + box[1][1] * split1(2):.4f} s; any race in both boxes has RMS"
      f" {math.sqrt(sq[0][0] + sq[1][0] + 36):.4f} to {math.sqrt(sq[0][1] + sq[1][1] + 36):.4f} s/km")

# 4. Along the subsequence every split settles; the size does not fall to the limit's.
lim1, limrms = a1 * split1(1) + a2 * split1(2), math.hypot(a1, a2)
tail = [n for n in inbox if n > picks[-1]]
print("tail j | race n | km-1 split | gap to limit | allowed gap | RMS")
for j in (1, 10, 100, 1000):
    n = tail[j - 1]
    gap = abs(km1(n) - lim1)
    allow = 0.09375 * split1(1) + 0.0625 * abs(split1(2)) + 60 * R2 / (math.pi * (n + 2))
    print(f"  {j:4d} | {n:6d} | {km1(n):8.4f} | {gap:.4f} | {allow:.4f} | {rms(n):.4f}")
    assert gap <= allow + 1e-12
n0 = tail[0]                    # a second road to the sizes: integrate the profiles squared on a grid
prof = lambda t: R2 * (start[n0 - 1] * math.cos(math.pi * t) + middle[n0 - 1] * math.cos(2 * math.pi * t)
                       + 6 * math.cos((n0 + 2) * math.pi * t))
g_race = grid(lambda t: prof(t) ** 2, 0, 1, 20 * (n0 + 2))
g_lim = grid(lambda t: 2 * (a1 * math.cos(math.pi * t) + a2 * math.cos(2 * math.pi * t)) ** 2, 0, 1, 2000)
print(f"  RMS on a grid: race {n0} {math.sqrt(g_race):.4f} (Pythagoras {rms(n0):.4f}),"
      f" limit {math.sqrt(g_lim):.4f} (Pythagoras {limrms:.4f})")
assert abs(g_race - rms(n0) ** 2) < 1e-9 and abs(g_lim - limrms ** 2) < 1e-9    # sizes, two roads
lost = rms(tail[999]) ** 2 - limrms ** 2
print(f"  lost energy at tail 1000: {rms(tail[999]) ** 2:.4f} - {limrms ** 2:.4f} = {lost:.4f} (s/km)^2; swap energy 6^2 = 36; peak of swaps {6 * R2:.4f}")

# 5. Mazur: averages of the swap parts converge in norm.  RMS of (6/N)(c_3 + ... + c_(N+2)).
print("Mazur average of N swap parts: N | RMS by Parseval | RMS by grid")
for N in (1, 4, 16, 100):
    par = 6 / math.sqrt(N)
    g = math.sqrt(grid(lambda t: (6 / N * sum(R2 * math.cos(k * math.pi * t) for k in range(3, N + 3))) ** 2, 0, 1, 4000))
    print(f"  {N:3d} | {par:.4f} | {g:.4f}")
    assert abs(par - g) < 1e-9

# 6. Weak-star in the dual of C[0, 1]: averages over [0.4, 0.4 + 1/n] tend to the reading at 0.4.
p = lambda t: 240 + 6 * R2 * math.cos(math.pi * t)
P = lambda t: 240 * t + 6 * R2 * math.sin(math.pi * t) / math.pi          # antiderivative of p
print(f"pace p(t) = 240 + 6 sqrt2 cos(pi t); reading at the 4 km mark p(0.4) = {p(0.4):.4f} s/km")
for n in (10, 100, 1000):
    exact, g = n * (P(0.4 + 1 / n) - P(0.4)), n * grid(p, 0.4, 0.4 + 1 / n, 1000)
    print(f"  window 1/{n:<4d} of the race: average {exact:.4f} (grid {g:.4f}), gap {abs(exact - p(0.4)):.4f}")
    assert abs(exact - g) < 1e-8 and abs(exact - p(0.4)) <= 6 * R2 * math.pi / (2 * n)

# 7. No countable dense set: coordinate readings on l-infinity, against a list built
#    to alternate on any chosen subsequence (here 2, 5, 9, 14, 20, 27).
chosen = [2, 5, 9, 14, 20, 27]
xinf = {n: (1 if k % 2 == 0 else -1) for k, n in enumerate(chosen)}
print("l-infinity readings on the chosen subsequence:", ", ".join(str(xinf[n]) for n in chosen))

b8, p8, _ = diagonal(8)
print(f"try: 8 halvings each: last pick {p8[-1]}, limit {sum(b8[0]) / 2:.4f} c_1 {sum(b8[1]) / 2:+.4f} c_2,"
      f" races in both boxes {sum(1 for n in range(1, M + 1) if inside(n, b8, 1))}")
print(f"try: swap 6 c_m at m = 10, 20, 30: |km-1 split| {abs(6 * split1(10)):.4f}, {abs(6 * split1(20)):.4f}, {abs(6 * split1(30)):.4f}")
print(f"try: unbounded start term 6m c_1, m = 1, 10, 100: km-1 split {6 * split1(1):.3f}, {60 * split1(1):.3f}, {600 * split1(1):.3f}")

assert abs(len(inbox) - M * law) < 4 * math.sqrt(M * law)          # equidistribution, two roads
assert all(lo <= (start, middle)[c][n - 1] <= hi for n, (c, (lo, hi)) in zip(picks, steps)) and picks == sorted(set(picks))
assert abs(box[0][1] - box[0][0] - 12 / 64) < 1e-12 and abs(box[1][1] - box[1][0] - 8 / 64) < 1e-12
assert abs(lost - 36) < 1.0 and limrms < rms(tail[999])         # energy lost, about the swaps' 36
assert max(start[:8]) - min(start[:8]) > 10                     # the whole sequence does not settle
print("ALL CHECKS PASS")
