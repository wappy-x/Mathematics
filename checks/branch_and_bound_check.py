# Branch and bound on a festival booking -- the check behind the card.  Standard library only.
# Five acts, a £150k fee budget: book the acts that bring the most extra ticket sales (maximise).
# Every relaxation is solved in exact fractions; nothing imported knows the answer.
from fractions import Fraction as Fr
NAMES = "ABCDE"
FEE = [30, 80, 80, 30, 90]                      # f_j, the act's fee, £k
SALES = [70, 130, 115, 40, 90]                  # v_j, extra ticket sales it brings, £k
BUDGET, N = 150, 5
BY_RATIO = [0, 1, 2, 3, 4]                      # sales per £ of fee, best first (checked below)
BY_SALES = [1, 2, 4, 0, 3]                      # biggest sales first: the wrong fill, for "What breaks"
SELECT = "depth"                                # which node next: "depth" (newest) or "best" (highest ceiling)

def relax(fix, budget=BUDGET, order=BY_RATIO):
    """fix maps acts to 1 (booked) or 0 (skipped). Fill the rest in `order`, the first misfit in part."""
    left = budget - sum(FEE[j] for j in fix if fix[j])
    if left < 0:
        return None                             # the acts already booked break the budget
    z, took = Fr(sum(SALES[j] for j in fix if fix[j])), [j for j in fix if fix[j]]
    for j in order:
        if j in fix:
            continue
        if FEE[j] > left:
            return (z + Fr(SALES[j] * left, FEE[j]), j, took) if left else (z, None, took)
        left, z, took = left - FEE[j], z + SALES[j], took + [j]
    return z, None, took

def price_bound(fix, lam):
    """Road 2: charge lam per £k of fee. Every whole plan in the node earns at most this. No fill used."""
    left = BUDGET - sum(FEE[j] for j in fix if fix[j])
    return (sum(SALES[j] for j in fix if fix[j]) + lam * left
            + sum(max(Fr(0), SALES[j] - lam * FEE[j]) for j in range(N) if j not in fix))

def search(select="depth", branch="part", budget=BUDGET, order=BY_RATIO, first_whole=False):
    """Road 1. A node is solved when made, then closed or split when taken off the list."""
    todo, done, inc, plan = [({}, relax({}, budget, order), 0, -1)], [], Fr(-1), []
    while todo:
        k = len(todo) - 1                       # depth-first: the last one made
        if select == "best":                    # best-first: highest ceiling, oldest on a tie
            k = max(range(len(todo)), key=lambda i: (todo[i][1][0] if todo[i][1] else -1, -i))
        fix, r, depth, parent = todo.pop(k)
        if r is None:
            verdict = "infeasible"
        elif r[0] <= inc:
            verdict = "bound"
        elif r[1] is None:
            verdict, inc, plan = "whole", r[0], sorted(r[2])
        else:
            verdict = "split"
            j = r[1] if branch == "part" else min(i for i in range(N) if i not in fix)
            kids = [({**fix, j: v}, relax({**fix, j: v}, budget, order), depth + 1, len(done)) for v in (1, 0)]
            todo += kids if select == "best" else kids[::-1]     # depth-first takes "book it" first
        done.append((fix, r, depth, verdict, inc, parent))
        if first_whole and verdict == "whole":
            break
    return done, inc, plan

def num(x):                                     # an exact decimal: every number here has one
    assert 10000 % x.denominator == 0
    v = x.numerator * (10000 // x.denominator)
    return f"{v // 10000}.{v % 10000:04d}".rstrip("0").rstrip(".")

acts = lambda p: " ".join(NAMES[j] for j in sorted(p))
fees = lambda p: sum(FEE[j] for j in p)
sales = lambda p: sum(SALES[j] for j in p)
assert all(SALES[a] * FEE[b] > SALES[b] * FEE[a] for a, b in zip(BY_RATIO, BY_RATIO[1:]))
print("acts (fee, sales, per £):", ", ".join(f"{NAMES[j]} {FEE[j]} {SALES[j]} "
      f"{(2000 * SALES[j] + FEE[j]) // (2 * FEE[j]) / 1000:.3f}" for j in range(N)))
done, best, plan = search(select=SELECT)
for n, (fix, r, depth, verdict, inc, _) in enumerate(done, 1):
    what = f"split on {NAMES[r[1]]}" if verdict == "split" else verdict
    if r is not None and r[1] is not None:      # road 2 at every node with an act booked in part
        lam = Fr(SALES[r[1]], FEE[r[1]])
        assert price_bound(fix, lam) == r[0] and price_bound(fix, lam + Fr(1, 8)) > r[0]
        what += f", price {num(lam)}"
    lab = " ".join(("+" if fix[j] else "-") + NAMES[j] for j in fix) or "root"
    print(f"node {n}  {lab:<9} ceiling {'none' if r is None else num(r[0]):>7}  {what:<24}"
          f" best so far {'none' if inc < 0 else num(inc)}")
kinds = [d[3] for d in done]
print(f"{SELECT}-first: {len(done)} nodes, {kinds.count('split')} split, {len(done) - kinds.count('split')} pruned "
      f"({kinds.count('infeasible')} infeasible, {kinds.count('bound')} bound, {kinds.count('whole')} whole)")
print(f"answer: book {acts(plan)}, sales {num(best)}, fees {fees(plan)}; root ceiling {num(done[0][1][0])}, "
      f"integrality gap {num(done[0][1][0] - best)}")

# How the search moves: after each node, the most any plan still on the list could earn, and the best in hand
hi, lo = [done[0][1][0]], [Fr(0)]
for n in range(len(done)):
    lo.append(max(done[n][4], Fr(0)))
    hi.append(max([d[1][0] for m, d in enumerate(done) if m > n and d[1] and d[5] <= n] + [lo[-1]]))
for name, row in [("most still possible", hi), ("best found", lo), ("search gap", [a - b for a, b in zip(hi, lo)])]:
    print(f"{name + ':':<20}", " ".join(num(x) for x in row))

# Road 3: all 32 plans, and a check that the closed nodes hold each plan exactly once
plans = [[j for j in range(N) if m >> j & 1] for m in range(1 << N)]
fits = [p for p in plans if fees(p) <= BUDGET]
top = max(sales(p) for p in fits)
winners = [p for p in fits if sales(p) == top]
leaves = [(d[0], d[1]) for d in done if d[3] != "split"]
for p in plans:
    home = [r for fix, r in leaves if all((j in p) == bool(fix[j]) for j in fix)]
    assert len(home) == 1 and (p not in fits or (home[0] is not None and sales(p) <= home[0][0]))
print(f"every plan: {len(plans)} plans, {len(fits)} fit, best {top} = {acts(winners[0])}, winners {len(winners)}")
print(f"the {len(leaves)} closed nodes hold all {len(plans)} plans once each; none beats its node's ceiling")
assert best == top and winners == [plan] and (len(done), len(leaves), kinds.count("whole")) == (9, 5, 2)

# Other choices of node and of branching act: same answer, different work
for name, kw in [("best-first", dict(select="best")), ("branch in order A to E", dict(branch="order"))]:
    d, b, p = search(**kw)
    assert b == top and p == plan
    print(f"{name}: {len(d)} nodes, answer {num(b)}")

# What breaks
d, b, p = search(first_whole=True)
print(f"stop at the first whole plan: {acts(p)}, sales {num(b)}, after {len(d)} nodes")
r = relax({})
print(f"round the root down: {acts(r[2])}, sales {sales(r[2])}; round it up: {acts(r[2] + [r[1]])}, "
      f"fees {fees(r[2] + [r[1]])} against {BUDGET}")
d, b, p = search(order=BY_SALES)
print(f"fill biggest sales first: root 'ceiling' {num(d[0][1][0])}, answer {acts(p)} {num(b)}")
assert b < top and d[0][1][0] < top < relax({})[0] and sales(r[2]) < top < sales(r[2] + [r[1]])
real = lambda p: sales(p) - (30 if 0 in p and 1 in p else 0)          # A and B pull the same crowd
alt = max(fits, key=real)
print(f"A and B share fans, £30k less together: {acts(plan)} really earns {real(plan)}; best is {acts(alt)} {real(alt)}")

# Try changing the budget
for bud in (140, 130):
    d, b, p = search(budget=bud)
    print(f"budget {bud}: {len(d)} nodes, book {acts(p)}, sales {num(b)}")

# Figure: leaves 80 apart left to right, each parent above the middle of its two children
pos, nxt = {}, [40]
def place(i):
    kids = sorted([k for k, d in enumerate(done) if d[5] == i], key=lambda k: -list(done[k][0].values())[-1])
    xs = [place(k) for k in kids]
    x = (xs[0] + xs[1]) // 2 if xs else nxt[0]
    nxt[0] += 0 if xs else 80
    pos[i + 1] = (x, 28 + 55 * done[i][2])
    return x
place(0)
print("figure,", " ".join(f"{n}:{pos[n][0]},{pos[n][1]}" for n in sorted(pos)))
print("ALL CHECKS PASS")
