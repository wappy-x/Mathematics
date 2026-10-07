# Absorption and first-step analysis -- the check behind the card.  Standard
# library only; Fraction is exact arithmetic, nothing more.  A 10-square
# snakes-and-ladders board, one six-sided die, ladder 3 -> 7, snake 8 -> 2,
# reaching or passing square 10 finishes.  Three roads to the expected turns
# and to the chance of meeting the snake before finishing: the first-step
# equations solved exactly, the chance mass pushed forward turn by turn, and a
# seeded simulation.  Then the fundamental matrix, the hand table, the mistakes.
from fractions import Fraction as Fr
L, SEED, GAMES, MASK = 10, 20260929, 100000, (1 << 64) - 1

def board(jumps, pit=None):              # resting squares and, for each, its six landings
    land = lambda s: L if s >= L else jumps.get(s, s)
    rest = [s for s in range(L) if s not in jumps]
    return rest, {s: ([s] * 6 if s == pit else [land(s + r) for r in range(1, 7)]) for s in rest}

def solve(A, b):                         # Gauss-Jordan elimination in exact fractions
    n = len(A); M = [row[:] + [v] for row, v in zip(A, b)]
    for c in range(n):
        p = next((r for r in range(c, n) if M[r][c] != 0), None)
        if p is None: return None        # singular: no unique answer
        M[c], M[p] = M[p], M[c]
        for r in range(n):
            if r != c and M[r][c] != 0:
                f = M[r][c] / M[c][c]; M[r] = [x - f * y for x, y in zip(M[r], M[c])]
    return [M[i][n] / M[i][i] for i in range(n)]

def first_step(jumps, trap=None, pit=None, one=1):   # road 1: t = one + Q t, or h = r + Q h
    rest, moves = board(jumps, pit)
    live = [s for s in rest if s != trap]; ix = {s: i for i, s in enumerate(live)}
    A = [[Fr(int(i == j)) for j in range(len(live))] for i in range(len(live))]; b = []
    for s in live:
        b.append(Fr(one) if trap is None else Fr(sum(e == trap for e in moves[s]), 6))
        for e in moves[s]:
            if e in ix: A[ix[s]][ix[e]] -= Fr(1, 6)
    return live, A, solve(A, b)

J = {3: 7, 8: 2}                         # the house board
rest, moves = board(J)
print("board: squares 0-9 then finish 10; ladder 3->7, snake 8->2; one die")
for s in rest: print(f"from {s}: rolls 1-6 land on {moves[s]}")
live, IQ, t = first_step(J)              # expected turns to finish
T = dict(zip(live, t))
print(f"road 1, exact: expected turns from 0 = {T[0]} = {float(T[0]):.6f}")
print("t by square " + " ".join(f"{s}:{float(v):.4f}" for s, v in T.items()))
J2 = {3: 7, 8: 8}; hl, A2, h = first_step(J2, trap=8)  # snake head made a trap
H = dict(zip(hl, h))
print(f"road 1, exact: chance of meeting the snake before finishing, from 0 = {H[0]} = {float(H[0]):.6f}")
print("h by square " + " ".join(f"{s}:{v}" for s, v in H.items()))
fin = solve(A2, [Fr(board(J2)[1][s].count(L), 6) for s in hl])[0]   # the finish column, own system
print(f"two traps from 0: snake {float(H[0]):.6f}, finish {float(fin):.6f}, sum {H[0] + fin}")
# fundamental matrix N = (I - Q)^-1, column by column
n = len(live); cols = [solve(IQ, [Fr(int(i == j)) for i in range(n)]) for j in range(n)]
N = [[cols[j][i] for j in range(n)] for i in range(n)]
ok = all(sum(N[i][k] * IQ[k][j] for k in range(n)) == int(i == j) for i in range(n) for j in range(n))
print("N row for square 0 (expected visits) " + " ".join(f"{s}:{float(v):.4f}" for s, v in zip(live, N[0])))
print(f"row sum = {float(sum(N[0])):.6f}; N (I - Q) = I exactly: {'yes' if ok else 'no'}")
N2 = [solve(A2, [Fr(int(i == j)) for i in range(len(hl))]) for j in range(len(hl))]   # N' = (I - Q')^-1, head a trap
B = [sum(N2[k][0] * board(J2)[1][hl[k]].count(e) for k in range(len(hl))) / 6 for e in (8, L)]   # row 0 of B = N' R'
print("N' row for square 0, head a trap (expected visits) " + " ".join(f"{s}:{float(N2[j][0]):.4f}" for j, s in enumerate(hl)) + f"; B = N' R': snake {float(B[0]):.6f}, finish {float(B[1]):.6f}")
snake_from = [Fr(board(J2)[1][s].count(8), 6) for s in live]      # chance one turn ends on the head
slides = sum(N[0][k] * snake_from[k] for k in range(n))
print(f"expected slides per game: N-row . slide chances = {float(slides):.6f}; h0/(1-h2) = {float(H[0] / (1 - H[2])):.6f}")
# hand table: carry x = t(2); each square is a + b x, worked from the top down
ab = {9: (Fr(1), Fr(0)), 2: (Fr(0), Fr(1)), L: (Fr(0), Fr(0))}
for s in (7, 6, 5, 4, 2):
    ab[s if s != 2 else "x"] = (1 + sum(ab[e][0] for e in moves[s]) / 6, sum(ab[e][1] for e in moves[s]) / 6)
x = ab["x"][0] / (1 - ab["x"][1])
for s in (7, 6, 5, 4):
    print(f"hand: t({s}) = {float(ab[s][0]):.4f} + {float(ab[s][1]):.4f} x = {float(ab[s][0] + ab[s][1] * x):.4f}")
print(f"hand: x = {float(ab['x'][0]):.4f} + {float(ab['x'][1]):.4f} x, so x = {x} = {float(x):.4f}")
# road 2: push the chance mass forward one turn at a time
dist, alive, ET, pT, hit = {0: 1.0}, 1.0, 0.0, [], 0.0
for turn in range(1, 200):
    ET += alive; new, done = {}, 0.0
    for s, m in dist.items():
        for e in moves[s]:
            if e == L: done += m / 6
            else: new[e] = new.get(e, 0.0) + m / 6
    pT.append(done); dist = new; alive = sum(new.values())
dist2 = {0: 1.0}
for turn in range(200):
    new = {}
    for s, m in dist2.items():
        for e in board(J2)[1][s]:
            if e == 8: hit += m / 6
            elif e != L: new[e] = new.get(e, 0.0) + m / 6
    dist2 = new
print(f"road 2, mass pushed 199 turns: expected turns {ET:.6f}; snake-first chance {hit:.6f}; mass left {alive:.1e}")
print("chart, percent of games ending on turn 1-10: " + " ".join(f"{100 * p:.2f}" for p in pT[:10]))
print(f"chart, percent ending after turn 10: {100 * sum(pT[10:]):.2f}")
eta = min(sum(1 for e1 in moves[s] for e2 in ([L] * 6 if e1 == L else moves[e1]) if e2 == L) for s in rest)
print(f"finiteness: worst chance of finishing within 2 turns = {eta}/36, so E[turns] <= 2*36/{eta} = {72 / eta:.1f}")
# road 3: seeded simulation, SplitMix64
state = SEED
def roll():
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK; z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK; z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return 1 + (((z ^ (z >> 31)) >> 32) * 6 >> 32)
sT = sT2 = sH = sS = sS2 = 0
for g in range(GAMES):
    pos, turns, met, sl = 0, 0, 0, 0
    while pos < L:
        pos += roll(); turns += 1
        if pos == 8: met, sl = 1, sl + 1
        pos = J.get(pos, pos)
    sT += turns; sT2 += turns * turns; sH += met; sS += sl; sS2 += sl * sl
m = sT / GAMES; se = ((sT2 / GAMES - m * m) / GAMES) ** 0.5; ph = sH / GAMES; seh = (ph * (1 - ph) / GAMES) ** 0.5
ms = sS / GAMES; ses = ((sS2 / GAMES - ms * ms) / GAMES) ** 0.5
print(f"road 3, {GAMES} games, seed {SEED}: turns {m:.4f} +/- {se:.4f}; met snake {ph:.4f} +/- {seh:.4f}")
print(f"road 3, slides per game {ms:.4f} +/- {ses:.4f}")
# mistakes and variations
print(f"mistake, drop the 1 for the turn played: t(0) = {float(first_step(J, one=0)[2][0]):.4f}")
print(f"mistake, 10 squares / 3.5 per roll = {10 / 3.5:.4f}")
pay = {s: ([J[s]] * 6 if s in J else board({})[1][s]) for s in range(L)}
A = [[Fr(int(i == j)) - Fr(pay[i].count(j), 6) for j in range(L)] for i in range(L)]
print(f"mistake, a turn spent on each climb or slide: t(0) = {float(solve(A, [Fr(1)] * L)[0]):.4f}")
pl, pA, pt = first_step({3: 7}, pit=8)
print(f"broken, a pit on 8 instead of the snake: row 8 of I - Q = {' '.join(str(v) for v in pA[pl.index(8)])}; unique solution: {'none' if pt is None else 'yes'}")
fl, _, fh = first_step({3: 7}, trap=8, pit=None)
print(f"broken, pit as a trap: chance of reaching the finish from 0 = {float(1 - dict(zip(fl, fh))[0]):.6f}")
print(f"try, no snake: t(0) = {float(first_step({3: 7})[2][0]):.4f}; no ladder: t(0) = {float(first_step({8: 2})[2][0]):.4f}")
print(f"try, snake 8->0: t(0) = {float(first_step({3: 7, 8: 0})[2][0]):.4f}")
print(f"try, plain board: t(0) = {float(first_step({})[2][0]):.4f}")
print(f"figure, square centres x = 20 + 32 s: ladder 3->7 at {20 + 32 * 3}->{20 + 32 * 7}, snake 8->2 at {20 + 32 * 8}->{20 + 32 * 2}")
assert abs(float(T[0]) - ET) < 1e-12                  # exact solve against mass flow
assert abs(float(H[0]) - hit) < 1e-12                 # the same for the snake chance
assert ok and sum(N[0]) == T[0]                       # N inverts I - Q, and N times ones is t
assert abs(m - float(T[0])) < 4 * se                  # simulation within 4 standard errors
assert abs(ph - float(H[0])) < 4 * seh
assert abs(ms - float(slides)) < 4 * ses
assert H[0] + fin == 1                                # two traps: the chances add to 1
assert B == [H[0], fin]                               # B = N' R' against the two solved systems
assert slides == H[0] / (1 - H[2])                    # two routes to the expected slides
assert pt is None                                     # the pit board has no unique answer
assert x == T[2] and all(ab[s][0] + ab[s][1] * x == T[s] for s in (7, 6, 5, 4))   # hand table = exact solve
assert all(ab[s][1] == H[s] for s in (7, 6, 5, 4)) and ab["x"][1] == H[2]          # Step 5: multiples of x are h
assert abs(sum(pT) - 1) < 1e-12 and abs(sum((k + 1) * p for k, p in enumerate(pT)) - ET) < 1e-9  # chart law
print("ALL CHECKS PASS")
