# Modes of convergence -- the check behind the card.  Standard library only.
# Four sequences, each number found twice: by the formula the card derives and
# by counting grid cells that every step of the functions lines up with.  A
# grid point is the midpoint t/D of a cell, t odd.  The code checks finite
# stages only; every statement about the limit rests on the proofs.
from fractions import Fraction as Q

L = 5040                                 # cells per unit on [0, 1); 1..10, 16 divide it
D = 2 * L
TS = range(1, D, 2)

def tw(n, t):                            # typewriter f_n: 1 on [k/M, (k+1)/M)
    M = 1 << (n.bit_length() - 1)
    k = n - M
    return 1 if D * k <= t * M < D * (k + 1) else 0

def spike(n, t):                         # growing spike g_n: n on [0, 1/n)
    return n if t * n < D else 0

def g_int(f, n, p=1):                    # integral of f_n^p, cell by cell
    return Q(sum(f(n, t) ** p for t in TS), L)

def g_len(f, n):                         # length of {f_n > 1/2}, cell by cell
    return Q(sum(1 for t in TS if 2 * f(n, t) > 1), L)

def dec(q):
    return f"{float(q):.4f}".rstrip("0").rstrip(".")

markov = []                              # (length above 1/2, integral) pairs
print("typewriter f_n on [0, 1): n = M + k, M = 2^m, f_n = 1 on [k/M, (k+1)/M)")
tw_formula, tw_grid = [], []
for n in range(1, 32):
    M = 1 << (n.bit_length() - 1)
    k = n - M
    tw_formula.append(Q(1, M))
    tw_grid.append(g_int(tw, n))
    markov.append((g_len(tw, n), tw_grid[-1]))
    at_third = tw(n, D // 3)                  # the seat x = 1/3 is the grid value t = D/3
    if n <= 16:
        print(f"n={n:2d} m={M.bit_length() - 1} [{k}/{M}, {k + 1}/{M}) integral "
              f"{float(tw_formula[-1]):.4f} grid {float(tw_grid[-1]):.4f} f_n(1/3)={at_third}")
once = all(sum(tw(n, t) for n in range(1 << m, 2 << m)) == 1 for m in range(5) for t in TS)
print(f"every one of {L} grid points is hit exactly once in each stage m=0..4: {'yes' if once else 'no'}")
hits = [n for n in range(1, 128) if tw(n, D // 3) == 1]
hits_formula = [(1 << m) + (1 << m) // 3 for m in range(7)]
print("x = 1/3 is hit at n =", ", ".join(map(str, hits)), "(one per stage m=0..6)")

# Riesz: pick n_j with length{f_n > 2^-j} at most 2^-j, then look at the tail sets
riesz = [next(n for n in range(1, 32) if g_len(tw, n) <= Q(1, 2 ** j)) for j in range(1, 5)]
print("subsequence n_j, j=1..4, by search:", ", ".join(map(str, riesz)),
      "; by formula 2^j:", ", ".join(str(2 ** j) for j in range(1, 5)))
tails = []
for J in range(1, 5):
    union = Q(sum(1 for t in TS if any(tw(riesz[j - 1], t) for j in range(J, 5))), L)
    tails.append(union)
    print(f"J={J}: length of union of bad sets j>=J (to j=4) {union}, bound sum 2^-j = {Q(2, 2 ** J)}")

print("growing spike g_n = n on [0, 1/n): n, integral, length{g_n > 1/2}, integral g_n^2, g_n(1/10)")
sp_formula, sp_grid = [], []
for n in (1, 2, 4, 8, 16):
    sp_formula.append((Q(1), Q(1, n), Q(n)))
    sp_grid.append((g_int(spike, n), g_len(spike, n), g_int(spike, n, 2)))
    markov.append((sp_grid[-1][1], sp_grid[-1][0]))
    print(f"n={n:2d}: {sp_grid[-1][0]}, {sp_grid[-1][1]}, {sp_grid[-1][2]}, {spike(n, D // 10)}")
sp_all = [g_int(spike, n) for n in list(range(1, 11)) + [16]]
print("spike integral, n = 1..16, by formula: 1 each; by grid, n = 1..10 and 16:", " ".join(map(str, sp_all)))
EN = [Q(sum(1 for t in TS if any(2 * spike(n, t) > 1 for n in range(N, 65))), L) for N in (1, 2, 4, 8)]
print("E_N = union over n >= N of {g_n > 1/2}, lengths N=1,2,4,8:", ", ".join(map(str, EN)))
egorov = [next(n for n in range(1, 500) if all(spike(n, t) == 0 for t in TS if t * d >= D)) for d in (10, 100)]
sup9 = max(spike(9, t) for t in TS if 10 * t >= D)
print(f"Egorov: g_n = 0 on [1/10, 1) from n = {egorov[0]}; on [1/100, 1) from n = {egorov[1]}; sup of g_9 on [1/10, 1) = {sup9}")

C, W = 8, 64                             # the half-line, cut at W, C cells per unit
XS = range(1, 2 * C * W, 2)              # midpoints s/(2C)
bump = lambda n, s: 1 if 2 * C * n <= s < 2 * C * (n + 1) else 0
spread = lambda n, s: Q(1, n) if s < 2 * C * n else Q(0)
print(f"sliding bump h_n = 1 on [n, n+1) and flat spread w_n = 1/n on [0, n), on [0, {W}), cells of 1/{C}:")
hw = []
for n in (1, 2, 4, 8, 16, 32):
    bl, bi = Q(sum(1 for s in XS if 2 * bump(n, s) > 1), C), Q(sum(bump(n, s) for s in XS), C)
    sl, si = Q(sum(1 for s in XS if 2 * spread(n, s) > 1), C), sum(spread(n, s) for s in XS) / C
    markov += [(bl, bi), (sl, si)]
    hw.append((bl, bi, sl, si))
    print(f"n={n:2d}: bump length{{>1/2}} {bl}, integral {bi}; spread sup {Q(1, n)}, length{{>1/2}} {sl}, integral {si}")
wins = [Q(sum(1 for s in range(1, 2 * C * w, 2) if any(bump(n, s) for n in range(4, w))), C) for w in (W, 2 * W)]
print(f"bump E_4 inside [0, W): W={W} gives {wins[0]}, W={2 * W} gives {wins[1]}; formula W - 4")
print(f"Markov: length{{|f_n| > 1/2}} <= 2 x integral held in all {len(markov)} rows: "
      f"{'yes' if all(a <= 2 * b for a, b in markov) else 'no'}; typewriter n=10: {markov[9][0]} <= "
      f"{2 * markov[9][1]}; spike n=16: {markov[35][0]} <= {2 * markov[35][1]}")
px = lambda q: dec(40 + 280 * q)            # figure: [0, 1) drawn from x=40 to x=320
shade = [f"{px(Q(n - (1 << m), 1 << m))}-{px(Q(n - (1 << m) + 1, 1 << m))}" for m, n in enumerate(hits[:4])]
print(f"figure, 280 per metre from x=40; x=1/3 at {float(px(Q(1, 3))):.2f}; rows m=0..3 at y 50, 95, 140, 185; "
      f"shaded n = {', '.join(map(str, hits[:4]))}: x {', '.join(shade)}")

assert tw_grid == tw_formula                              # two roads to each integral
assert once and hits == hits_formula                      # every point hit every stage
assert [(a, b, c) for a, b, c in sp_grid] == sp_formula  # spike: grid against formula
assert riesz == [2 ** j for j in range(1, 5)] and tails == [Q(1, 2 ** J) for J in range(1, 5)]
assert EN == [Q(1, N) for N in (1, 2, 4, 8)] and egorov == [10, 100] and sup9 == 9
assert wins == [W - 4, 2 * W - 4] and all(a <= 2 * b for a, b in markov) and sp_all == [1] * 11
assert hw == [(1, 1, Q(1 if n == 1 else 0), 1) for n in (1, 2, 4, 8, 16, 32)]  # bump, spread
