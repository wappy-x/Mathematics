# Dynamic programming and the Bellman equation -- the check behind the card.  Nothing is
# imported.  A three-leg trip along a river: before each leg the car is on the north bank (0)
# or the south bank (1), and it stays on that bank's toll road (0) or takes the bridge first (1).
TOLL = [[(11, 16), (14, 13)],            # leg 1, dollars: [north (stay, cross), south (stay, cross)]
        [(19, 22), (12, 15)],            # leg 2
        [(21, 24), (19, 20)]]            # leg 3
MOVE = ("stay", "cross")

def backward(toll):                      # road one: the Bellman equation, finish to start
    n, comps = len(toll), 0
    value, plan, cand = [[0, 0] for _ in range(n + 1)], [[0, 0] for _ in toll], [[0, 0] for _ in toll]
    for k in range(n - 1, -1, -1):
        for x in (0, 1):
            a = cand[k][x] = [toll[k][x][c] + value[k + 1][x ^ c] for c in (0, 1)]
            plan[k][x], comps = (0 if a[0] <= a[1] else 1), comps + 1     # one comparison
            value[k][x] = a[plan[k][x]]
    return value, plan, comps, cand
def brute(toll, start):                  # road two: price every whole route, keep the cheapest
    costs = []
    for code in range(2 ** len(toll)):
        side, cost = start, 0
        for k in range(len(toll)):
            c = code >> (len(toll) - 1 - k) & 1
            cost, side = cost + toll[k][side][c], side ^ c
        costs.append(cost)
    return min(costs), costs
value, plan, comps, cand = backward(TOLL)
for k, leg in enumerate(TOLL):
    print(f"leg {k + 1} tolls: north stay {leg[0][0]}, cross {leg[0][1]}; south stay {leg[1][0]}, cross {leg[1][1]}")
print("V_3(N) = 0, V_3(S) = 0: nothing left to pay")
for k in range(2, -1, -1):
    (a, b), (c, d) = cand[k]
    print(f"V_{k}(N) = min({a}, {b}) = {value[k][0]}, V_{k}(S) = min({c}, {d}) = {value[k][1]}; choose {MOVE[plan[k][0]]} / {MOVE[plan[k][1]]}")
side, greedy_side, paid, moves, greedy = 0, 0, [], [], 0
for k, leg in enumerate(TOLL):           # follow the plan; alongside, mistake 1: cheapest toll now
    c, g = plan[k][side], 0 if leg[greedy_side][0] <= leg[greedy_side][1] else 1
    moves.append(MOVE[c]); paid.append(leg[side][c]); side ^= c
    greedy += leg[greedy_side][g]; greedy_side ^= g
blind = [min(min(t) for t in leg) for leg in TOLL]      # mistake 2: forget which bank the car is on
(best_n, costs_n), (best_s, _) = brute(TOLL, 0), brute(TOLL, 1)
print(f"backward induction: {comps} comparisons; cheapest from N {value[0][0]}, from S {value[0][1]}")
print(f"plan from N: {', '.join(moves)}; tolls {' + '.join(map(str, paid))} = {sum(paid)}")
print(f"brute force from N: {len(costs_n)} routes {costs_n}, {len(costs_n) - 1} comparisons, cheapest {best_n}; from S {best_s}")
print(f"mistake 1, cheapest toll each leg with no look ahead: {greedy}")
print(f"mistake 2, cheapest toll per leg ignoring the bank: {' + '.join(map(str, blind))} = {sum(blind)}, no such route")
print(f"drop 'costs add up', 15 dollar rebate for north stay, stay, stay: true cheapest {min(costs_n[0] - 15, best_n)}, table on the bank still {value[0][0]}")
seed = [2026]
def rnd():                               # second case: a home-made generator, tolls 5 to 29 dollars
    seed[0] = (seed[0] * 1103515245 + 12345) % 2 ** 31
    return 5 + seed[0] % 25
big = [[(rnd(), rnd()), (rnd(), rnd())] for _ in range(12)]
(bv, _, bc, _), (bb, bcosts) = backward(big), brute(big, 0)
print(f"{len(big)} legs: backward {bc} comparisons, cheapest {bv[0][0]}; brute force {len(bcosts)} routes, cheapest {bb}")
print("routes 2^n against comparisons 2n: " + "; ".join(f"n = {n}: {2 ** n} vs {2 * n}" for n in (3, 10, 30)))
print("states with d gauges of 10 levels: " + "; ".join(f"d = {d}: {10 ** d}" for d in (1, 3, 6)))
assert value[0][0] == best_n             # Bellman against every route, from the north bank
assert value[0][1] == best_s             # and from the south bank
assert sum(paid) == value[0][0]          # the plan's own tolls add up to the value
assert bv[0][0] == bb                    # 12 legs: 24 comparisons agree with 4096 routes
print("ALL CHECKS PASS")
