# Filtrations and martingales -- the check behind the card.  Standard library
# only.  Part 1: a poker night of three fair even-money hands.  $100 to start;
# stakes $20, then $20 after a first win or $40 after a first loss, then $10.
# The filtration is listed set by set, and the forecast M_n = E[Y | F_n] of the
# final bankroll Y is reached by three roads.  Part 2: the loaded die of the
# Radon-Nikodym card rolled three times; its density process Z_n by three roads.
# Part 3: SplitMix64 poker nights, seed 2026.  Part 4: the mistakes, computed.
from fractions import Fraction as F
from itertools import product
import math

H = list(product("WL", repeat=3))                 # the 8 histories, WWW first

def forward(h):                                   # road 3: add up the stakes
    b = [F(100)]
    for n, r in enumerate(h):
        stake = 20 if n == 0 else 10 if n == 2 else 20 if h[0] == "W" else 40
        b.append(b[-1] + (stake if r == "W" else -stake))
    return b

Y = {h: forward(h)[3] for h in H}
AHEAD = {h: F(int(Y[h] > 100)) for h in H}

def cell_avg(X, h, n):                            # road 1: average over h's cell
    cell = [g for g in H if g[:n] == h[:n]]
    return sum(X[g] for g in cell) / len(cell)

def fold_back(X):                                 # road 2: two children at a time
    V, out = dict(X), {3: dict(X)}
    for n in (2, 1, 0):
        V = {h[:n]: (V[h[:n] + ("W",)] + V[h[:n] + ("L",)]) / 2 for h in H}
        out[n] = {h: V[h[:n]] for h in H}
    return out

M = {n: {h: cell_avg(Y, h, n) for h in H} for n in range(4)}
A = {n: {h: cell_avg(AHEAD, h, n) for h in H} for n in range(4)}
MB, AB = fold_back(Y), fold_back(AHEAD)

def sigma(n):                                     # F_n: every union of time-n cells
    cells = sorted({sum(1 << i for i, g in enumerate(H) if g[:n] == h[:n]) for h in H})
    return {sum(c for k, c in enumerate(cells) if s >> k & 1) for s in range(1 << len(cells))}

FS = [sigma(n) for n in range(4)]
nested = all(FS[n] <= FS[n + 1] for n in range(3))
closed = all(255 ^ a in S and a | b in S for S in FS for a in S for b in S)
def adapted(X, n):                                # every set {X = c} lies in F_n
    return all(sum(1 << i for i, g in enumerate(H) if X[g] == c) in FS[n] for c in set(X.values()))

fmt = lambda x: str(int(x)) if x.denominator == 1 else str(float(x))
print("sets in F_0, F_1, F_2, F_3:", ", ".join(str(len(S)) for S in FS),
      "| each inside the next:", "yes" if nested else "no", "| closed:", "yes" if closed else "no")
print("history | Y | M_0 M_1 M_2 M_3 | ahead forecast A_0 A_1 A_2 A_3")
for h in H:
    print("".join(h), "|", fmt(Y[h]), "|", " ".join(fmt(M[n][h]) for n in range(4)), "|",
          " ".join(fmt(A[n][h]) for n in range(4)))
print("figure, nodes (hand: $):", "; ".join(f"{n}: " + ", ".join(
      fmt(v) for v in sorted({M[n][h] for h in H}, reverse=True)) for n in range(4)))
print("figure, svg x = 50 + 90 x hand:", ", ".join(str(50 + 90 * n) for n in range(4)))
print("figure, svg y = 220 - 1.4 x (bankroll - 20) for $150, $100, $30:",
      ", ".join(fmt(220 - F(14, 10) * (v - 20)) for v in (150, 100, 30)))
print("E[M_n] for n = 0..3:", ", ".join(fmt(sum(M[n].values()) / 8) for n in range(4)),
      "| E[A_n]:", ", ".join(fmt(sum(A[n].values()) / 8) for n in range(4)))
print("adapted to F_n: M_n", "yes" if all(adapted(M[n], n) for n in range(4)) else "no",
      "| M_(n+1), read at time n:", "yes" if any(adapted(M[n + 1], n) for n in range(3)) else "no")

P1, Q1 = [F(1, 6)] * 6, [F(1, 10)] * 4 + [F(2, 10), F(4, 10)]
RATE = [q / p for q, p in zip(Q1, P1)]
ROLLS = list(product(range(6), repeat=3))
PRE = sorted({r[:n] for r in ROLLS for n in range(4)})
def ends(pre): return [pre + t for t in product(range(6), repeat=3 - len(pre))]
def z_ratio(pre):                                 # road A: Q(cell) / P(cell)
    return sum(math.prod(Q1[f] for f in e) for e in ends(pre)) / sum(math.prod(P1[f] for f in e) for e in ends(pre))
def z_prod(pre): return math.prod((RATE[f] for f in pre), start=F(1))   # road B: rates multiplied
def z_cond(pre): return sum(z_prod(e) for e in ends(pre)) / len(ends(pre))  # road C: E_P[Z_3 | F_n]
print("P per history:", fmt(F(1, 8)), "| loaded die Q:", ", ".join(fmt(q) for q in Q1),
      "| rates dQ/dP:", ", ".join(fmt(r) for r in RATE))
roads_z = all(z_ratio(p) == z_prod(p) == z_cond(p) for p in PRE)
step_z = all(sum(z_prod(p + (f,)) for f in range(6)) / 6 == z_prod(p) for p in PRE if len(p) < 3)
EZ = [sum(z_prod(r[:n]) for r in ROLLS) / 216 for n in range(4)]
print(f"density process: {len(PRE)} cells; Q(cell)/P(cell) = product of rates = E_P[Z_3 | F_n]:",
      "yes" if roads_z else "no")
print("one-step average of Z_(n+1) over the next roll is Z_n:", "yes" if step_z else "no",
      "| E_P[Z_n] for n = 0..3:", ", ".join(fmt(z) for z in EZ))
for lab, path in (("6,6,6", (5, 5, 5)), ("6,1,5", (5, 0, 4)), ("1,1,1", (0, 0, 0))):
    print(f"figure, Z_n on rolls {lab}:", ", ".join(f"{float(z_prod(path[:n])):.2f}" for n in range(4)))
below = sum(1 for r in ROLLS if z_prod(r) < 1)
print(f"rolls with Z_3 below 1: {below} of 216 = {below / 216:.4f} under P")

state = 2026
def uniform():                                    # SplitMix64; 53 bits into [0, 1)
    global state
    state = (state + 0x9E3779B97F4A7C15) % 2**64
    z = state
    z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9 % 2**64
    z = (z ^ (z >> 27)) * 0x94D049BB133111EB % 2**64
    return ((z ^ (z >> 31)) >> 11) / 2.0**53
N, cnt, sm, sq, ahead = 200000, [0, 0], [0.0, 0.0], [0.0, 0.0], 0
for _ in range(N):
    h = tuple("W" if uniform() < 0.5 else "L" for _ in range(3))
    y, k = float(Y[h]), 0 if h[0] == "W" else 1
    cnt[k] += 1; sm[k] += y; sq[k] += y * y; ahead += y > 100
cm = [sm[k] / cnt[k] for k in (0, 1)]
se = [math.sqrt((sq[k] / cnt[k] - cm[k] ** 2) / cnt[k]) for k in (0, 1)]
fa = ahead / N
sea = math.sqrt(fa * (1 - fa) / N)
print(f"draws, seed 2026: {N} nights; mean Y after a first win {cm[0]:.2f} (s.e. {se[0]:.2f}),"
      f" after a first loss {cm[1]:.2f} (s.e. {se[1]:.2f})")
print(f"draws: share of nights finishing above $100 = {fa:.4f} (s.e. {sea:.4f})")

p = F(45, 100)                                    # a house edge: a win has chance 0.45
EH = [sum(math.prod(p if r == "W" else 1 - p for r in h) * forward(h)[n] for h in H) for n in range(4)]
by_stakes = 100 + (2 * p - 1) * (20 + p * 20 + (1 - p) * 40 + 10)
flip = {h: 200 - forward(h)[1] for h in H}        # N_2 = 200 - N_1: a forecast that flips
flip_after_win = cell_avg(flip, ("W", "W", "W"), 1)
one_roll = RATE[5] / 36                           # rate of roll 2 alone, on the event 6 then 6
print("house edge 0.45: mean bankroll after 0..3 hands:", ", ".join(fmt(e) for e in EH),
      "| from the stakes:", fmt(by_stakes))
print("flip process: means", ", ".join(fmt(x) for x in (F(100), sum(forward(h)[1] for h in H) / 8,
      sum(flip.values()) / 8)), f"| E[N_2 | F_1] after a first win = {fmt(flip_after_win)}, not 120")
print(f"one-roll rate as Z_2: E_P[Z'_2 on 6 then 6] = {one_roll:.4f}; Q(6 then 6) = {fmt(Q1[5] ** 2)}"
      f" | averaged under Q, E_Q[Z_1] = {fmt(sum(q * r for q, r in zip(Q1, RATE)))}, not 1")

assert all(M[n][h] == MB[n][h] == forward(h)[n] for n in range(4) for h in H)  # three roads to M_n
assert all(A[n][h] == AB[n][h] for n in range(4) for h in H)                   # the ahead forecast, two roads
assert [len(S) for S in FS] == [2 ** 2 ** n for n in range(4)] and nested and closed
assert roads_z and step_z and EZ == [z_ratio(()) for _ in range(4)]             # density, three roads
assert abs(cm[0] - 120) < 4 * se[0] and abs(cm[1] - 80) < 4 * se[1]           # draws against 120, 80
assert abs(fa - float(A[0][H[0]])) < 4 * sea                                   # draws against 5/8
assert EH[3] == by_stakes and flip_after_win != M[1][H[0]]                      # the mistakes are real
assert all(adapted(M[n], n) for n in range(4)) and not any(adapted(M[n + 1], n) for n in range(3))
print("ALL CHECKS PASS")
