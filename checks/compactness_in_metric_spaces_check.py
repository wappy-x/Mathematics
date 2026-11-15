# Compactness three ways -- the check behind the card.  Standard library only.
# The plot is 40 m by 30 m, fence included, held in whole centimetres so the
# distances compare as integers.  Finite runs illustrate; only the exhaustive
# check of the 1023 finite subfamilies is a proof, of that finite claim.
from fractions import Fraction as F
from math import gcd, isqrt, pi, sqrt

W, H, DIAG = 4000, 3000, 5000            # the plot and its diagonal, in cm


def cm(v):                               # whole centimetres printed as metres
    return f"{v // 100}.{v % 100:02d}"

def m(v):                                # an exact metre value, zeros trimmed
    return f"{v:.5f}".rstrip("0").rstrip(".")

def frac(n, d):                          # a fraction, reduced
    g = gcd(n, d)
    return f"{n // g}/{d // g}"

def sq(p, q):                            # squared straight-line distance, cm^2
    return (p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2


# ---- the plot's three distances, corner to corner ----
print(f"corner to corner: walk {cm(W + H)} m, straight {cm(isqrt(W * W + H * H))} m, "
      f"worst-case {cm(max(W, H))} m")

# ---- road one to total boundedness: squares, each inside one open ball ----
test = [(x, y) for x in range(0, W + 1, 25) for y in range(0, H + 1, 25)]
for eps in (1000, 500, 100):
    nx, ny = -(-W // eps), -(-H // eps)
    worst = 0
    for (x, y) in test:                  # the centre of the square holding (x, y)
        c = (min(x // eps, nx - 1) * eps + eps // 2, min(y // eps, ny - 1) * eps + eps // 2)
        worst = max(worst, sq((x, y), c))
    print(f"net, radius {cm(eps)} m: {nx} x {ny} = {nx * ny} balls; farthest test point "
          f"{sqrt(worst) / 100:.2f} m from its centre")
    assert worst < eps * eps             # strictly inside: open balls cover
    if eps == 1000:                      # room left inside a disc: a Lebesgue number
        print(f"any ball of radius below {10 - sqrt(worst) / 100:.4f} m lies inside one of the 12 discs")
print(f"test points: every 0.25 m, {len(test)} of them, fence included")

# ---- road two: a greedy net, built from the test points themselves ----
eps = 500
greedy = []
for p in test:
    if all(sq(p, c) >= eps * eps for c in greedy):
        greedy.append(p)
ceiling = int((W + eps) * (H + eps) / (pi * eps * eps / 4))
floor = -(-(W * H) // int(pi * eps * eps))   # the plot's area over one disc's area
print(f"greedy net, radius {cm(eps)} m: {len(greedy)} balls; centres pairwise at least {eps // 100} m apart; "
      f"area floor {floor}, packing ceiling {ceiling}")
assert all(any(sq(p, c) < eps * eps for c in greedy) for p in test)
assert floor <= len(greedy) <= ceiling

# ---- a wandering list of stakes, and a settling subsequence by quartering ----
def splitmix(seed):                      # SplitMix64, written out
    s = seed
    while True:
        s = (s + 0x9E3779B97F4A7C15) & (2 ** 64 - 1)
        z = s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & (2 ** 64 - 1)
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & (2 ** 64 - 1)
        yield z ^ (z >> 31)


gen = splitmix(2026)
stakes = []
for _ in range(50000):
    r = next(gen)
    stakes.append(((r & 0xFFFFFFFF) % (W + 1), (r >> 32) % (H + 1)))

def cell(p, j):                          # which of the 2^j by 2^j boxes holds p
    return (min(p[0] * 2 ** j // W, 2 ** j - 1), min(p[1] * 2 ** j // H, 2 ** j - 1))

alive, picks, box, boxes = list(range(len(stakes))), [], (0, 0), []
for j in range(7):
    if j > 0:                            # keep the quarter with the most later stakes
        kids = [(2 * box[0] + a, 2 * box[1] + b) for b in (0, 1) for a in (0, 1)]
        counts = [sum(1 for i in alive if i > picks[-1] and cell(stakes[i], j) == k) for k in kids]
        box = kids[counts.index(max(counts))]
        alive = [i for i in alive if cell(stakes[i], j) == box]
    later = [i for i in alive if not picks or i > picks[-1]]
    picks.append(later[0])
    d = 100 * 2 ** j                      # cm per metre, times the halvings
    boxes.append((m(box[0] * W / d), m(box[1] * H / d), m(W / d), m(H / d)))
    p = stakes[later[0]]
    print(f"level {j}: box x {m(box[0] * W / d)}..{m((box[0] + 1) * W / d)}, y {m(box[1] * H / d)}.."
          f"{m((box[1] + 1) * H / d)} m, diagonal {m(DIAG / d)} m; {len(later)} later stakes; "
          f"pick #{later[0]} at ({cm(p[0])}, {cm(p[1])})")
for j in range(len(picks)):              # each later pick sits in every earlier box
    for k in range(j + 1, len(picks)):
        assert sq(stakes[picks[j]], stakes[picks[k]]) * 4 ** j <= DIAG * DIAG
assert picks == sorted(set(picks))
gap = sqrt(sq(stakes[picks[5]], stakes[picks[6]])) / 100
print(f"picks 5 and 6 are {gap:.2f} m apart, inside the level-5 diagonal {m(DIAG / 3200)} m")
close = min(sq(stakes[a], stakes[b]) for a in range(49) for b in range(a))
print(f"pigeonhole: of the first 49 stakes, the closest two are {sqrt(close) / 100:.2f} m apart "
      f"(at most {sqrt(2 * 500 * 500) / 100:.2f} m guaranteed)")
assert close <= 2 * 500 * 500

# ---- what breaks 1: the fence line without its end posts, (0, 40) ----
# Stake k sits at 40/2^k m; cover set U_m is the open stretch (40/2^m, 40).
uncovered = 0
for mask in range(1, 2 ** 10):          # every finite subfamily of U_1 .. U_10
    chosen = [m for m in range(1, 11) if mask >> (m - 1) & 1]
    if any(all(not (F(40, 2 ** m) < F(40, 2 ** k) < 40) for m in chosen) for k in range(1, 12)):
        uncovered += 1                   # some stake k lies in none of the chosen sets
print(f"open fence (0, 40): U_1..U_10 reach down to {frac(40, 2 ** 10)} m; stake 11 at "
      f"{frac(40, 2 ** 11)} m is outside; subfamilies leaving a stake out: {uncovered} of 1023")
assert uncovered == 2 ** 10 - 1
print(f"stakes 10 and 11 differ by {frac(40, 2 ** 11)} m; the list heads for 0, not in (0, 40)")

# ---- what breaks 2: a road with no end, stakes every 40 m ----
road = [40 * k for k in range(100)]
print(f"endless road: closest two of 100 stakes {min(b - a for a, b in zip(road, road[1:]))} m apart")
assert min(abs(a - b) for a in road for b in road if a != b) == 40

# ---- what breaks 3: a hub with n streets, each 100 m; d = s + t across streets ----
def hub(p, q):
    return abs(p[1] - q[1]) if p[0] == q[0] or 0 in (p[1], q[1]) else p[1] + q[1]

for n in (3, 12, 48):
    ends = [(i, 100) for i in range(n)]
    centres = [(i, t) for i in range(n) for t in range(101)]
    most = max(sum(1 for e in ends if hub(c, e) < 100) for c in centres)
    far = min(hub(a, b) for a in ends for b in ends if a != b)
    print(f"hub, {n} streets: all within 100 m of the hub; ends {far} m apart; "
          f"one open 100 m ball holds at most {most} end, so {n} balls needed")
    assert most == 1 and far == 200

# ---- what breaks 4: covering by single points, which are closed, not open ----
print(f"one-point cover: whole-centimetre points alone need {(W + 1) * (H + 1)} sets")
print("figure, plot 0 0 40 30; net centres x 5 15 25 35, y 5 15 25, radius 10; boxes x y w h "
      + "; ".join(" ".join(b) for b in boxes[:4]) + "; picks "
      + "; ".join(f"{cm(stakes[i][0])} {cm(stakes[i][1])}" for i in picks[:4]))
print("ALL CHECKS PASS")
