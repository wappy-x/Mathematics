# Big-M and yes-or-no switches -- the check behind the card.  Standard library only.
# A festival books acts from a shortlist of 12.  The main stage holds 8; a ninth
# act needs stage 2, which costs a fixed £40k to open.  Maximise net takings, £k.
# Road 1 lists every plan.  Road 2 sorts.  The relaxations are solved by a greedy
# fill and certified by a dual price.  Then an either-or rule on set times.
from fractions import Fraction as Fr

V = [62, 55, 48, 41, 37, 33, 30, 26, 18, 14, 11, 6]   # acts A..L: takings minus fee, £k
K, S2, F, NAMES = 8, 6, 40, "ABCDEFGHIJKL"             # slots on stages 1 and 2, charge

def best_plan(allowed):                                # road 1: all 2^12 x 2 plans
    best = None
    for mask in range(1 << len(V)):
        n = bin(mask).count("1")
        for y in (0, 1):
            if allowed(n, y):
                val = sum(v for i, v in enumerate(V) if mask >> i & 1) - F * y
                if best is None or val > best[0]:
                    best = (val, n, y)
    return best

def relax(M):                                         # greedy fill: past 8 acts each
    toll, n, val = Fr(F, M), Fr(0), Fr(0)              # unit of an act costs F/M
    for v in V:                                        # V is sorted, best first
        free = min(Fr(1), max(Fr(0), K - n))
        extra = min(1 - free, K + M - n - free) if v > toll else Fr(0)
        n, val = n + free + extra, val + v * free + (v - toll) * extra
    return val, n, max(Fr(0), (n - K) / M)

def dual_bound(M):                                    # price pi on n - M*y <= 8
    pi = Fr(F, M)
    return K * pi + sum(max(Fr(0), v - pi) for v in V) + max(Fr(0), pi * M - F)

def pct(a, b):
    return f"{100 * float(Fr(a) - b) / float(b):.2f}%"

true_rule = lambda n, y: n <= K + S2 * y               # the real rule: 8 slots, or 8 + 6
z_ip, n_ip, y_ip = best_plan(true_rule)
shut, opened = best_plan(lambda n, y: y == 0 and n <= K), best_plan(lambda n, y: y == 1 and n <= K + S2)
by_sort = (sum(V[:K]), sum(V[:K + S2]) - F)            # road 2: best 8, or best 14 less F
m_small = max(n - K for n in range(min(len(V), K + S2) + 1))  # most n - 8 reaches
print("acts A-L, net value in £k:", *V, f"(sum {sum(V)})")
print(f"main stage slots {K}; stage 2 opening charge £{F}k; plans listed: {(1 << len(V)) * 2}")
print(f"road 1, every plan: best £{z_ip}k, {n_ip} acts, stage 2 open = {y_ip}")
print(f"best with stage 2 shut £{shut[0]}k (acts {NAMES[:K]}); best with it open £{opened[0]}k")
print(f"road 2, by sorting: shut £{by_sort[0]}k, open £{by_sort[1]}k")
print(f"smallest valid M = most that n - 8 can reach = {m_small}")
print("M        relaxed  y         acts n  toll F/M  dual bound  gap to IP")
rows = {}
for M in (2, 4, 6, 12, 100, 10**6):
    val, n, y = relax(M)
    rows[M] = (val, n, y)
    print(f"{M:<8} {float(val):7.2f}  {float(y):.6f}  {float(n):6.2f}  {float(Fr(F, M)):8.5f}"
          f"  {float(dual_bound(M)):10.2f}  {pct(val, z_ip)}")
v4, n4, y4 = rows[4]
print(f"tight relaxation by hand: 332 + (18-10) + (14-10) + (11-10) = {float(v4):.2f}")
parts = [v - 10 for v in V if v > 10]
print(f"price bound at M = 4: 8 x 10 + ({' + '.join(map(str, parts))}) = 80 + {sum(parts)} = {80 + sum(parts)}")
print(f"gap in £k: M = 4 {float(v4 - z_ip):.2f}, M = 100 {float(rows[100][0] - z_ip):.2f}")
no_link = best_plan(lambda n, y: True)
too_small = best_plan(lambda n, y: n <= K + 2 * y)
print(f"mistake 1, no link from n to y: claims £{no_link[0]}k with {no_link[1]} acts, y = {no_link[2]}")
print(f"mistake 2, M = 2: at most {K + 2} acts; best £{too_small[0]}k, {too_small[1]} acts, loses £{z_ip - too_small[0]}k")
print(f"mistake 3, M = 100: right plan, but bound {float(rows[100][0]):.2f}, gap {pct(rows[100][0], z_ip)}")
yb = rows[10**6][2]
print(f"mistake 4, M = 1000000: y = {float(yb):.6f}, under a 0.00001 tolerance it reads 0;"
      f" plan claims £{float(rows[10**6][0]):.5f}k, 12 acts, stage 2 shut")
# either-or: headliners A (90 min) and B (60 min) share one sound crew, between
# 18:00 and 23:00.  Times in quarter hours after 18:00.  w = 1 means A plays first.
dA, dB, END = 6, 4, 20
pairs = [(a, b) for a in range(END - dA + 1) for b in range(END - dB + 1)]
truth = [(a, b) for a, b in pairs if a + dA <= b or b + dB <= a]
mE = max(max(a + dA - b, b + dB - a) for a, b in pairs)
def passes(a, b, M, w):
    return a + dA - b <= M * (1 - w) and b + dB - a <= M * w
model = lambda M: [(a, b) for a, b in pairs if passes(a, b, M, 0) or passes(a, b, M, 1)]
clash_half = [p for p in pairs if p not in truth and passes(*p, mE, Fr(1, 2))]
print(f"either-or: {len(pairs)} start pairs on the quarter hour, {len(truth)} without a clash")
print(f"smallest valid M = {mE} quarter hours = {mE // 4} hours; that model keeps {len(model(mE))}")
print(f"M = 4 hours keeps {len(model(16))}; B at 18:00, A at 21:30 kept: {'yes' if (14, 0) in model(16) else 'no'}")
print(f"relaxed w = 0.5 with M = 5 hours loosens both rules by {mE / 8} hours;"
      f" lets {len(clash_half)} of {len(pairs) - len(truth)} clashes through")
px = lambda n: 60 + 20 * float(n)
py = lambda y: 200 - 140 * float(y)
print(f"figure, tight edge ({px(8):.0f},{py(0):.0f})-({px(12):.0f},{py(1):.0f}); loose M=100 edge"
      f" ({px(8):.0f},{py(0):.0f})-({px(12):.0f},{py(Fr(4, 100)):.1f}); optima ({px(n4):.0f},{py(y4):.0f})"
      f" and ({px(12):.0f},{py(rows[100][2]):.1f})")
assert (z_ip, n_ip, y_ip) == (341, 12, 1) and (shut[0], opened[0]) == by_sort  # two roads
assert all(relax(M)[0] == dual_bound(M) for M in rows)                      # LP certified
assert m_small == 4 and v4 == 345 and v4 == 80 + sum(parts) and y4 == Fr(3, 4) and too_small[0] == 332
assert [rows[M][0] for M in (4, 6, 12, 100, 10**6)] == sorted(rows[M][0] for M in (4, 6, 12, 100, 10**6))
assert mE == 20 and sorted(model(mE)) == sorted(truth) and len(model(16)) < len(truth)
print("ALL CHECKS PASS")
