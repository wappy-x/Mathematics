# P versus NP, the Clay problem -- the check behind the card.  Standard library only.
# One payment, twenty open invoices: which invoices does it pay?  That is SUBSET SUM,
# an NP-complete problem.  Checking a claimed answer is a few additions; finding one
# is a search.  Four roads find the same answer; then the costs are grown to 60 and
# 100 invoices, and the poll counts behind "most believe" are turned into percentages.
from bisect import bisect_left, bisect_right

def c(x): return f"{x:,}"
def cash(cents): return f"${cents // 100:,}.{cents % 100:02d}"

A = [48215, 112040, 23999, 375010, 89950, 154281, 61830, 298000, 17465, 205590,
     73320, 131085, 44700, 260415, 98760, 186230, 35580, 142900, 67125, 228860]
S, m = 832530, len(A)                    # the payment, in cents; m invoices
print(f"invoices: m = {m}, open total {cash(sum(A))}; payment S = {cash(S)}")

# 0. The verifier: a claimed list of invoices is checked by adding them up.
claim = [1, 4, 6, 9, 13, 16, 18]          # invoice numbers counted from 0
total, adds = 0, 0
for i in claim:
    total, adds = total + A[i], adds + 1
print(f"certificate check: {len(claim)} invoices, {adds} additions, sum {cash(total)}, matches {total == S}")

# 1. Brute force: every subset.  sums[mask] is the total of the invoices whose bits are set.
sums = [0]
for a in A:
    sums += [s + a for s in sums]
brute = [mask for mask, s in enumerate(sums) if s == S]
print(f"brute force: {c(len(sums))} subsets, {len(brute)} match; "
      f"invoices {[i for i in range(m) if brute[0] >> i & 1]}")

# 2. Meet in the middle (1974): all sums of each half, sorted, then matched.
def half_sums(xs):
    out = [0]
    for a in xs:
        out += [s + a for s in out]
    return out
left, right = half_sums(A[:m // 2]), sorted(half_sums(A[m // 2:]))
mitm = sum(bisect_right(right, S - s) - bisect_left(right, S - s) for s in left)
print(f"meet in the middle: {c(len(left))} + {c(len(right))} half-sums, {mitm} match")

# 3. The amount table (pseudo-polynomial): bit t of reach is 1 when t cents can be made.
reach, mask_s = 1, (1 << (S + 1)) - 1
for a in A:
    reach = (reach | (reach << a)) & mask_s
cells = m * (S + 1)
print(f"amount table: {c(S + 1)} columns x {m} rows = {c(cells)} cells, payable {bool(reach >> S & 1)}")
print(f"every invoice 1,000 times larger: {c(m * (1000 * S + 1))} cells; brute force still {c(len(sums))}")

# 4. Search from decision: a yes/no oracle, asked once per invoice, recovers the list.
def decide(xs, t):                       # yes/no only, by meet in the middle
    h = len(xs) // 2
    r = set(half_sums(xs[h:]))
    return any(t - s in r for s in half_sums(xs[:h]))
keep, rest, asks = [], S, 0
for i in range(m):
    asks += 1
    if not decide(A[i + 1:], rest):      # the rest cannot pay it without invoice i
        keep.append(i)
        rest -= A[i]
print(f"search from decision: {asks} yes/no questions, invoices {keep}, left over {rest}")

# 5. Growth: brute force against meet in the middle, at a billion subsets a second.
YEAR = 31557600                          # seconds in a year of 365.25 days
for k in (20, 40, 60, 100):
    ms, tenths = 2 ** k // 10 ** 6, 10 * 2 ** k // (10 ** 9 * YEAR)
    print(f"m = {k}: subsets {c(2 ** k)}; half-sums {c(2 ** (k // 2))}; at 1e9 subsets/s "
          f"{ms // 1000:,}.{ms % 1000:03d} s = {tenths // 10:,}.{tenths % 10} years")
print(f"bars, log10 of work at m = 60: brute {len(str(2 ** 60)) - 1}, half-sums {len(str(2 ** 30)) - 1}, check {len(str(60)) - 1}")

# 6. Opinion is not proof: three polls of researchers, P != NP answers over all answers.
polls = [(2002, 61, 9, 100), (2012, 126, 12, 152), (2019, 109, 15, 124)]
for year, ne, eq, n in polls:
    pct = lambda x: f"{(1000 * x + n // 2) // n // 10}.{(1000 * x + n // 2) // n % 10}%"
    print(f"poll {year}: {ne} of {n} say P != NP ({pct(ne)}), {eq} say P = NP ({pct(eq)})")
print(f"Clay fund: 7 problems x $1,000,000 = ${7 * 1000000:,}; solved 1, open {7 - 1}")

assert total == S and brute == [sum(1 << i for i in claim)]  # verifier against brute force
assert mitm == len(brute) == 1                               # two searches agree
sumset = set(sums)                                           # table against brute force:
assert all((reach >> t & 1) == (t in sumset) for t in range(0, S + 1, 997)) and reach >> S & 1
assert keep == claim and rest == 0                           # decision oracle rebuilds the list
assert 2 ** 60 // (10 ** 9 * YEAR) == 36                    # by hand: 1.15e18 s / 3.16e16
print("ALL CHECKS PASS")
