# Euler's product -- the check behind the card.  Nothing is imported.  Eight identical marbles go
# into unmarked cups, none empty: 22 ways.  The count is reached twice, by listing every split and
# by multiplying one geometric bracket per cup size, and a third time at n = 50 by Euler's
# pentagonal recurrence.  All-different and all-odd splits are counted by listing and by products.
N, MARBLES = 50, 8
def splits(total, largest):                  # every non-increasing list of parts summing to total
    if total == 0: return [()]
    return [(k,) + rest for k in range(min(largest, total), 0, -1) for rest in splits(total - k, k)]
def times(a, b):                             # multiply two coefficient lists, degrees over N dropped
    return [sum(a[i] * b[d - i] for i in range(d + 1)) for d in range(N + 1)]
def product(factors):                        # multiply a run of brackets, starting from 1
    out = [1] + [0] * N
    for f in factors: out = times(out, f)
    return out
def any_number_of(k):                        # 1 + x^k + x^(2k) + ... : any number of cups of size k
    return [1 if d % k == 0 else 0 for d in range(N + 1)]
def at_most_one(k):                          # 1 + x^k : size k used once or not at all
    return [1 if d in (0, k) else 0 for d in range(N + 1)]
def pentagonal(upto, paired=True):           # p(n) = p(n-1) + p(n-2) - p(n-5) - p(n-7) + ...
    p = [1] + [0] * upto
    for n in range(1, upto + 1):
        total, j = 0, 1
        while j * (3 * j - 1) // 2 <= n:
            s = -1 if paired and j % 2 == 0 else 1
            total += sum(s * p[n - w] for w in (j * (3 * j - 1) // 2, j * (3 * j + 1) // 2) if w <= n)
            j += 1
        p[n] = total
    return p
def grid(name, values): print(f"{name:<40}" + "".join(f"{v:>6}" for v in values))
def show(rows): return "; ".join("+".join(str(k) for k in r) for r in rows)
euler, pent = product(any_number_of(k) for k in range(1, N + 1)), pentagonal(N)
listed, all8 = [len(splits(n, n)) for n in range(11)], splits(MARBLES, MARBLES)
distinct, odd = product(at_most_one(k) for k in range(1, N + 1)), product(any_number_of(k) for k in range(1, N + 1, 2))
diff8, odd8 = [s for s in all8 if len(set(s)) == len(s)], [s for s in all8 if all(k % 2 for k in s)]
running = [product(any_number_of(k) for k in range(1, m + 1))[MARBLES] for m in range(1, MARBLES + 1)]
comps = [1] + [0] * MARBLES
for n in range(1, MARBLES + 1): comps[n] = sum(comps[n - k] for k in range(1, n + 1))
print(f"{MARBLES} identical marbles into unmarked cups, none empty; cup sizes 1 to {MARBLES}")
grid("marbles to share, n", list(range(11)))
grid("splits listed one by one", listed)
grid("coefficient of x^n in the product", euler[:11])
grid("the same, by the pentagonal recurrence", pent[:11])
grid("all cups different, from 1+x^k", distinct[:11])
grid("all cups odd, from odd sizes only", odd[:11])
print(f"the x^{MARBLES} coefficient as sizes 1 to {MARBLES} are added: {running}")
print(f"the {len(diff8)} all-different splits of {MARBLES}: {show(diff8)}")
print(f"the {len(odd8)} all-odd splits of {MARBLES}: {show(odd8)}")
print(f"p({N}) from the product: {euler[N]}")
print(f"p({N}) from the pentagonal recurrence: {pent[N]}")
print(f"mistake 1, order counted: {comps[MARBLES]} ordered writings of {MARBLES}, not {euler[MARBLES]}")
print(f"mistake 2, sizes stopped at 4: {running[3]}, not {euler[MARBLES]}")
print(f"mistake 3, every size at most once: {distinct[MARBLES]}, not {euler[MARBLES]}")
print(f"mistake 4, pentagonal signs all plus: {pentagonal(MARBLES, False)[MARBLES]}, not {euler[MARBLES]}")
assert listed == euler[:11] and euler[:11] == pent[:11]              # listing, product, recurrence
assert euler[MARBLES] == 22 and euler[N] == 204226                   # the published partition numbers
assert distinct == odd and distinct[MARBLES] == len(diff8) == len(odd8) == 6
assert running == [1, 5, 10, 15, 18, 20, 21, 22] and comps[MARBLES] == 2 ** (MARBLES - 1)
print("ALL CHECKS PASS")
