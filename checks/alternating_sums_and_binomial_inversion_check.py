# Alternating sums and binomial inversion -- the check behind the card.  Nothing is
# imported.  Five tunes -- Anchor, Bramble, Cinder, Dovetail, Ember -- and a setlist is
# a running order of some of them.  Pascal's rows come from addition alone, and every
# count is reached twice: once by listing the things, once by a formula.
ROWS, N = 10, 5
TUNES = ["Anchor", "Bramble", "Cinder", "Dovetail", "Ember"]
def triangle(top):                         # rows 0 to top, each entry from the two above
    out = [[1]]
    for n in range(1, top + 1):
        out.append([1] + [out[-1][k - 1] + out[-1][k] for k in range(1, n)] + [1])
    return out
def factorial(m): return 1 if m < 2 else m * factorial(m - 1)     # 1 x 2 x ... x m, 0! = 1
def subsets(n):                            # every in-or-out choice over n tunes
    return [[i for i in range(n) if m >> i & 1] for m in range(2 ** n)]
def setlists(pool):                        # every running order of some of the pool
    out = [[]]
    for i, t in enumerate(pool):
        for rest in setlists(pool[:i] + pool[i + 1:]): out.append([t] + rest)
    return out
def signs(row):                            # the row written out with its signs
    return " ".join(("+" if k % 2 == 0 else "-") + str(x) for k, x in enumerate(row))
def yn(claim): return "yes" if claim else "no"

tri = triangle(ROWS)
signed = [sum((-1) ** k * tri[n][k] for k in range(n + 1)) for n in range(ROWS + 1)]
plain = [sum(tri[n]) for n in range(ROWS + 1)]
evens = [sum(1 for s in subsets(n) if len(s) % 2 == 0) for n in range(ROWS + 1)]
odds = [sum(1 for s in subsets(n) if len(s) % 2 == 1) for n in range(ROWS + 1)]
diff = [e - o for e, o in zip(evens, odds)]                       # road two to the signed sums
exact = [factorial(k) for k in range(N + 1)]                      # a(k) = k!
by_order = [sum(1 for s in setlists(TUNES[:k]) if len(s) == k) for k in range(N + 1)]
b_listed = [len(setlists(TUNES[:n])) for n in range(N + 1)]       # road one: list every setlist
b_sum = [sum(tri[n][k] * exact[k] for k in range(n + 1)) for n in range(N + 1)]
back = [sum((-1) ** (n - k) * tri[n][k] * b_listed[k] for k in range(n + 1)) for n in range(N + 1)]
terms = [(-1) ** (N - k) * tri[N][k] * b_listed[k] for k in range(N + 1)]
sizes = [tri[N][k] * exact[k] for k in range(N + 1)]
unsigned = sum(tri[N][k] * b_listed[k] for k in range(N + 1))     # mistake one: no signs
early = sum((-1) ** k * tri[N][k] for k in range(N))              # mistake two: row cut short
no_zero = sum((-1) ** (N - k) * tri[N][k] * b_listed[k] for k in range(1, N + 1))
run = str(terms[0]) + "".join(f" {'+' if t > 0 else '-'} {abs(t)}" for t in terms[1:])
print(f"five tunes: {', '.join(TUNES)} -- a setlist is a running order of some of them")
print(f"row 5 signed: {signs(tri[5])} -> {signed[5]}; unsigned -> {plain[5]}")
print(f"row 10 signed: {signs(tri[10])} -> {signed[10]}; unsigned -> {plain[10]}")
print(f"signed row sums, rows 0 to {ROWS}: {signed}")
print(f"even-size picks, by listing: {evens}")
print(f"odd-size picks, by listing:  {odds}")
print(f"each signed row sum is even-size minus odd-size: {yn(signed == diff)}")
print(f"setlists of exactly k tunes from {N}, k = 0 to {N}: {sizes}")
print(f"'at most' counts b(n) for pools of 0 to {N} tunes, by listing every setlist: {b_listed}")
print(f"the same counts from b(n) = sum C(n,k) k!: {yn(b_listed == b_sum)}")
print(f"inverting with signs: a(n) = {back}; k! by multiplying, and by listing running orders: "
      f"{yn(exact == by_order)}")
print(f"the inverse at n = {N}, term by term: {run} = {sum(terms)}")
print(f"mistakes: inverting without signs gives {unsigned}, not {back[N]}; stopping row {N} one "
      f"term early gives {early}, not {signed[N]}; dropping the k = 0 term gives {no_zero}, not {back[N]}")
assert signed == diff                                # signed rows against counts of picks by parity
assert b_listed == b_sum and by_order == exact       # listing against the forward sum
assert back == exact                                 # the signed inverse against k! by multiplying
assert (unsigned, early, no_zero) == (872, 1, 121)   # the three mistakes, worked by hand
print("ALL CHECKS PASS")
