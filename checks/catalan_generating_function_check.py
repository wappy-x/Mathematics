# The Catalan generating function -- the check behind the card.  Nothing is imported.  Six sorted
# stacks of envelopes stand in a row; each step merges two neighbouring stacks, so five merges finish
# the row, and a plan is the nesting of those merges.  The plans are counted three ways: by iterating
# C <- 1 + x C^2 on truncated series, by simulating every merge order and keeping the distinct
# nestings, and by the closed count C(2n, n)/(n + 1).  The closed form is then checked at x = 0.1.
DEG, DEEP, X = 5, 10, 0.1
def mul(a, b, deg):                      # series product, powers above x^deg dropped
    out = [0] * (deg + 1)
    for i, ai in enumerate(a):
        for j, bj in enumerate(b[:deg + 1 - i]): out[i + j] += ai * bj
    return out
def rnd(c, deg, lead=1):                 # one round of C <- lead + x C^2
    return [lead] + mul(c, c, deg)[:deg]
def plans(k):                            # every merge order of k stacks, simulated on strings
    rows = [tuple(chr(65 + i) for i in range(k))]
    for _ in range(k - 1):
        rows = [r[:i] + ("(" + r[i] + r[i + 1] + ")",) + r[i + 2:] for r in rows for i in range(len(r) - 1)]
    return [r[0] for r in rows]
def choose(n, k):                        # C(n, k), from the product formula
    out = 1
    for i in range(k): out = out * (n - i) // (i + 1)
    return out
def cat(upto): return [choose(2 * n, n) // (n + 1) for n in range(upto + 1)]   # the closed count
def heron(v):                            # square root, by Heron's own method
    g = 1.0
    for _ in range(60): g = (g + v / g) / 2
    return g
def row(label, values): print(f"{label:<46}" + "".join(f"{v:>4}" for v in values))
rounds = [[1] + [0] * DEG]                                    # road one: iterate the equation
for _ in range(DEG + 1): rounds.append(rnd(rounds[-1], DEG))
listed = [len(set(plans(k))) for k in range(1, DEG + 2)]      # road two: simulate every order
closed, deep = cat(DEG), cat(DEEP)                            # road three: the closed count
resid = [a - b for a, b in zip(rnd(deep, DEEP), deep)]        # does the closed count solve it?
dice = mul([0] + [1] * 6, [0] + [1] * 6, 12)                  # the shelf's two dice, as a check
root = heron(1 - 4 * X)
minus, plus = (1 - root) / (2 * X), (1 + root) / (2 * X)
back = 1 + X * minus * minus
total, p = 0.0, 1.0
for c in cat(30): total, p = total + c * p, p * X
dropped = [1] + [0] * DEG
for _ in range(DEG + 1): dropped = rnd(dropped, DEG, 0)
term = [1] + [c * c for c in rounds[DEG]][:DEG]
print(f"six sorted stacks in a row, five merges to finish: plans for 1 to {DEG + 1} stacks")
for k in range(1, DEG + 2): row(f"round {k} of C <- 1 + x C^2", rounds[k])
row("distinct nestings, by listing merge orders", listed)
row("the closed count C(2n,n)/(n+1)", closed)
print("the 5 plans for 4 stacks: " + " ".join(sorted(set(plans(4)))))
print(f"1 + x C^2 - C on the closed counts, x^0 to x^{DEEP}: " + " ".join(str(v) for v in resid))
print(f"the shelf's two dice, the square of x + ... + x^6: {dice[7]} at x^7, {sum(dice)} in all")
print(f"closed form at x = {X}: 1 - 4x = {1 - 4 * X:.1f}, its square root {root:.12f}, (1 - {root:.12f})/{2 * X:.1f} = {minus:.12f}")
print(f"that number back through 1 + x C^2: {back:.12f}; the counts summed at x = {X}, n = 0 to 30: {total:.12f}")
print(f"mistake 1, the plus root: (1 + {root:.12f})/{2 * X:.1f} = {plus:.12f}")
row("mistake 2, dropping the leading 1", dropped)
row("mistake 3, squaring coefficient by coefficient", term)
print(f"mistake 4, merge orders counted as plans, {DEG + 1} stacks: {len(plans(DEG + 1))}, not {listed[DEG]}")
assert rounds[DEG] == listed and listed == closed and rounds[DEG] == rounds[DEG + 1]   # three roads
assert resid == [0] * (DEEP + 1) and deep[DEG] == 42                  # the counts solve the equation
assert abs(back - minus) < 1e-12 and abs(total - minus) < 1e-12       # the closed form, as a number
assert dice[7] == 6 and sum(dice) == 36 and len(plans(DEG + 1)) > listed[DEG]
print("ALL CHECKS PASS")
