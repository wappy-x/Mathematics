# Catalan numbers -- the check behind the card.  Nothing is imported.  Ten people queue for a $5
# ticket, five holding a $5 note (F) and five a $10 note (T), the till empty to start.  The orders
# that never strand the cashier are counted four ways: by listing every order, by the closed form,
# by the reflection difference, and by the first-return recurrence.  A queue of 3 and 3 warms up.
PAIRS, SMALL, GOOD, BAD = 5, 3, "FTFTFTFTFT", "FTTFFTFTFT"
def choose(n, k):                            # C(n, k), from the product formula
    if k < 0 or k > n: return 0
    out = 1
    for i in range(k): out = out * (n - i) // (i + 1)
    return out
def orders(n):                               # every order of n fives and n tens
    words = ("".join("F" if (m >> i) & 1 else "T" for i in range(2 * n)) for m in range(1 << (2 * n)))
    return sorted(w for w in words if w.count("F") == n)
def till(w):                                 # $5 notes in the till after each customer
    out = [0]
    for c in w: out.append(out[-1] + (1 if c == "F" else -1))
    return out
def flip(w):                                 # reflection: swap the notes after the first failure
    cut = min(i for i, h in enumerate(till(w)) if h < 0)
    return w[:cut] + "".join("T" if c == "F" else "F" for c in w[cut:])
def catalan(upto):                           # first return: Cat(n+1) = sum Cat(i) Cat(n-i)
    cat = [1]
    for n in range(upto): cat.append(sum(cat[i] * cat[n - i] for i in range(n + 1)))
    return cat
def factorial(m):                            # 1 x 2 x ... x m
    out = 1
    for i in range(2, m + 1): out *= i
    return out
def row(label, values):
    print(f"{label:<52}" + "".join(f"{v:>3}" for v in values))
N, all5 = 2 * PAIRS, orders(PAIRS)
safe5, bad5 = [w for w in all5 if min(till(w)) >= 0], [w for w in all5 if min(till(w)) < 0]
flipped, safe3 = sorted({flip(w) for w in bad5}), [w for w in orders(SMALL) if min(till(w)) >= 0]
cat, listed = catalan(10), [len([w for w in orders(n) if min(till(w)) >= 0]) for n in range(7)]
closed, refl = choose(N, PAIRS) // (PAIRS + 1), choose(N, PAIRS) - choose(N, PAIRS + 1)
terms = " + ".join(f"{cat[i]}x{cat[PAIRS - 1 - i]}" for i in range(PAIRS))
print(f"{N} in the queue, {PAIRS} with a $5 note and {PAIRS} with a $10 note, ticket $5, till starts empty")
print(f"warm-up with {SMALL} of each: {choose(2 * SMALL, SMALL)} orders in all, {len(safe3)} of them safe")
print(f"the {len(safe3)} safe orders of {SMALL}: " + " ".join(safe3))
row("customers served", list(range(N + 1)))
row(f"safe     {' '.join(GOOD)}, $5 notes in the till", till(GOOD))
row(f"stranded {' '.join(BAD)}, $5 notes in the till", till(BAD))
print(f"road 1, listing every order of {PAIRS} and {PAIRS}: {len(all5)} orders, {len(safe5)} safe, {len(bad5)} stranded")
print(f"road 2, closed form: C({N},{PAIRS})/({PAIRS}+1) = {choose(N, PAIRS)}/{PAIRS + 1} = {closed}")
print(f"road 3, reflection: C({N},{PAIRS}) - C({N},{PAIRS + 1}) = {choose(N, PAIRS)} - {choose(N, PAIRS + 1)} = {refl}")
print(f"the flip turns the {len(bad5)} stranded orders into {len(flipped)} different orders with {PAIRS + 1} tens and {PAIRS - 1} fives, and C({N},{PAIRS + 1}) = {choose(N, PAIRS + 1)} counts those")
print(f"road 4, first return: {terms} = {cat[PAIRS]}")
print("Cat(0) to Cat(9): " + " ".join(str(c) for c in cat[:10]))
print("safe orders by listing, n = 0 to 6: " + " ".join(str(c) for c in listed))
print(f"mistake 1, dividing by n instead of n + 1: {choose(N, PAIRS)}/{PAIRS} = {choose(N, PAIRS) / PAIRS:.1f}, not a whole number")
print(f"mistake 2, dropping the never-negative rule: {len(all5)}")
print(f"mistake 3, n read as the {N} customers, not the {PAIRS} pairs: Cat({N}) = {cat[N]}")
print(f"mistake 4, the {N} customers told apart: {len(safe5)} x {factorial(PAIRS)} x {factorial(PAIRS)} = {len(safe5) * factorial(PAIRS) ** 2}")
assert len(safe5) == closed and closed == refl                      # listing, formula, reflection
assert len(bad5) == choose(N, PAIRS + 1) == len(flipped) and all(w.count("T") == PAIRS + 1 for w in flipped)
assert listed == cat[:7] and cat[PAIRS] == len(safe5)               # recurrence against listing
assert cat[:10] == [1, 1, 2, 5, 14, 42, 132, 429, 1430, 4862]       # the published sequence
print("ALL CHECKS PASS")
