# Transfinite induction -- the check behind the card.  Nothing is imported.  Ordinal
# omega*w + n is the pair (w, n).  Values are whole numbers over D = 2^60; 1 is D.
D, N = 2 ** 60, 60
a = {(0, 0): 0}                                           # zero: a(0) = 0
cases = {"zero": int(a[0, 0] <= D), "successor": 0, "limit": 0}
for w in (0, 1, 2):
    if w > 0:                                             # limit: omega, omega+omega
        run = [a[w - 1, n] for n in range(N + 1)]         # the earlier values
        grid = min(k for k in range(1001) if all(v * 1000 <= k * D for v in run))
        tail = run[-1] + (run[-1] - run[-2])              # the halving steps still to come
        assert grid == 1000 and tail == D                 # two roads to the bound: 1
        a[w, 0] = tail
        cases["limit"] += all(v <= D for v in run) and a[w, 0] <= D
    for n in range(1, N + 1 if w < 2 else 1):
        a[w, n] = (D + a[w, n - 1]) // 2                  # successor: (1 + a) / 2
        cases["successor"] += a[w, n - 1] <= D and a[w, n] <= D
formula = all(a[0, n] == D - D // 2 ** n for n in range(N + 1))   # 1 - 1/2^n
first = min(n for n in range(N + 1) if a[0, n] * 1000 > 999 * D)
slip = 0
for _ in range(3): slip = 1 + slip                        # successor rule, halving dropped
print("a(n) for n = 0 to 4: " + ", ".join(f"{a[0, n] * 2 ** n // D}/{2 ** n}" for n in range(5)))
print(f"a(n) = 1 - 1/2^n for every n from 0 to {N}: " + ("yes" if formula else "no"))
print(f"a({first}) = {a[0, first] * 2 ** first // D}/{2 ** first} = {a[0, first] / D}, the first value above 0.999")
print(f"a(omega) = {a[1, 0] // D}, a(omega+1) = {a[1, 1] // D}, a(omega+5) = {a[1, 5] // D}, a(omega+omega) = {a[2, 0] // D}")
print(f"stages checked for a <= 1: zero {cases['zero']}, successor {cases['successor']}, limit {cases['limit']}")
print(f"mistakes: biggest of first ten {a[0, 9] / D}, sum of first ten {sum(a[0, n] for n in range(10)) / D}, no halving a(3) = {slip}")
assert formula and first == 10 and a[1, 1] == a[2, 0] == D
assert cases == {"zero": 1, "successor": 120, "limit": 2}
assert a[0, 9] * 512 == 511 * D and sum(a[0, n] for n in range(10)) * 512 == 4097 * D and slip == 3
print("ALL CHECKS PASS")
