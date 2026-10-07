# Erdos's counting trick -- the check behind the card.  Nothing is imported.  A
# server hall of 32 machines, every pair joined by copper or by fibre.  The plans
# with ten machines joined all one way are over-counted by formula, then the same
# argument is re-run by listing every plan of K(4) and K(5).
K, N = 10, 32

def falling(n, k):                        # n x (n-1) x ... x (n-k+1); falling(k, k) is k!
    out = 1
    for i in range(k): out *= n - i
    return out
def choose(n, k): return falling(n, k) // falling(k, k)       # road one to C(n, k)
def pascal(n, k):                         # road two to C(n, k): Pascal's rule, row by row
    row = [1]
    for _ in range(n): row = [1] + [row[i] + row[i + 1] for i in range(len(row) - 1)] + [1]
    return row[k]
def bound(n, k, colours=2):               # witnesses x plans per witness: the over-count
    return colours * choose(n, k) * 2 ** (choose(n, 2) - choose(k, 2))
def share(n, k): return 2 * choose(n, k) / 2 ** choose(k, 2)  # the over-count over all plans
def bad_by_listing(n, k):                 # every plan of K(n), searched for a one-type k-set
    pairs = [(i, j) for i in range(n) for j in range(i + 1, n)]
    sets = [s for s in range(1 << n) if bin(s).count("1") == k]
    masks = [sum(1 << e for e, (i, j) in enumerate(pairs) if s >> i & 1 and s >> j & 1) for s in sets]
    bad = sum(1 for c in range(1 << len(pairs)) if any(c & m in (0, m) for m in masks))
    return bad, 1 << len(pairs)
def root(k):                              # the whole part of 2^(k/2), by counting up
    n = 1
    while (n + 1) * (n + 1) <= 1 << k: n += 1
    return n
def yn(claim): return "yes" if claim else "no"

cn2, ck2 = choose(N, 2), choose(K, 2)
c_fall, c_pas = choose(N, K), pascal(N, K)
exact, loose = share(N, K), 2 ** (1 + K // 2) / falling(K, K)
top = N
while share(top + 1, K) < 1: top += 1   # the largest hall the exact test still clears
(b44, a44), (b54, a54), (b53, a53) = bad_by_listing(4, 4), bad_by_listing(5, 4), bad_by_listing(5, 3)
ks = range(3, 17)

print(f"k = {K}, n = {N}: {cn2} pairs, {ck2} inside a ten-set, 2^{cn2} plans, a number of {len(str(2 ** cn2))} digits")
print(f"ten-sets C({N},{K}) = {c_fall} by falling product, {c_pas} by Pascal's rule")
print(f"bad plans at most 2 x {c_fall} x 2^{cn2 - ck2}, a share of {c_fall}/2^{ck2 - 1} = {exact:.8f}")
print(f"loose form 2^{1 + K // 2}/{K}! = {2 ** (1 + K // 2)}/{falling(K, K)} = {loose:.8f}")
print(f"loose form under 1 from k = 3 on: 2^5 = {2 ** 5} < (3!)^2 = {falling(3, 3) ** 2}")
print(f"good plans at least {1 - exact:.8f} x 2^{cn2}, so one exists: {yn(exact < 1)}")
print(f"largest hall the exact test clears at k = {K}: {top} (share {share(top, K):.4f}); {top + 1} gives {share(top + 1, K):.4f}")
print(f"listed, k = 4 on K(4): {a44} plans, {b44} bad, bound {bound(4, 4)}")
print(f"listed, k = 4 on K(5): {a54} plans, {b54} bad, bound {bound(5, 4)}, so {a54 - b54} good")
print(f"listed, k = 3 on K(5): {a53} plans, {b53} bad, {a53 - b53} good = 5!/(5 x 2); bound {bound(5, 3)}, over the total")
print(f"n = whole part of 2^(k/2), k = 3 to 16: {[root(k) for k in ks]}")
print(f"exact test passes at every one of them: {yn(all(bound(root(k), k) < 2 ** choose(root(k), 2) for k in ks))}")
print(f"mistake, ordered lists of ten: {falling(N, K)}/2^{ck2 - 1} = {falling(N, K) / 2 ** (ck2 - 1):.2f}")
print(f"mistake, one colour only: {exact / 2:.8f}; on K(4) it allows {bound(4, 4, 1)} bad plan, listing finds {b44}")
assert c_fall == c_pas                                   # two roads to the ten-sets
assert b44 == bound(4, 4) and b54 <= bound(5, 4) and a53 - b53 == falling(5, 5) // 10  # listing
assert exact <= loose < 1                                # the exact share sits under the loose form
assert all(root(k) ** 2 <= 1 << k < (root(k) + 1) ** 2 and bound(root(k), k) < 2 ** choose(root(k), 2) for k in ks)
print("ALL CHECKS PASS")
