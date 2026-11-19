# Dirichlet characters mod 10 and the primes ending in 3 -- the check behind the card.
# Nothing is imported.  A character value i^k is stored exactly as k mod 4, and
# every sum is a Gaussian integer (re, im), so no rounding enters.
# Road one counts primes by last digit.  Road two adds each character over the
# primes and filters with orthogonality.  The characters themselves are found
# twice: from the generator 3, and by trying every possible table.
Q, X = 10, 10**6
IPOW = [(1, 0), (0, 1), (-1, 0), (0, -1)]       # i^0, i^1, i^2, i^3

def gcd(a, b):                                  # Euclid's algorithm, written out
    while b:
        a, b = b, a % b
    return a

def gadd(a, b): return (a[0] + b[0], a[1] + b[1])
def gmul(a, b): return (a[0] * b[0] - a[1] * b[1], a[0] * b[1] + a[1] * b[0])
def conj(a): return (a[0], -a[1])
def yn(claim): return "yes" if claim else "no"

def show(z):                                    # a Gaussian integer as text: 24 + 44i
    re, im = z
    if im == 0:
        return str(re)
    i_part = ("" if abs(im) == 1 else str(abs(im))) + "i"
    if re == 0:
        return ("-" if im < 0 else "") + i_part
    return f"{re} {'-' if im < 0 else '+'} {i_part}"

def all_characters(q):                          # brute force: every table that is multiplicative
    units = [n for n in range(1, q) if gcd(n, q) == 1]
    m, found = len(units), []                   # values are m-th roots of unity, m = phi(q)
    for code in range(m ** m):
        e = {u: (code // m ** j) % m for j, u in enumerate(units)}
        if e[1] == 0 and all(e[a * b % q] == (e[a] + e[b]) % m for a in units for b in units):
            found.append(tuple(e[u] for u in units))
    return units, m, found

units = [n for n in range(1, Q) if gcd(n, Q) == 1]
ind, k, g = {}, 0, 1                            # road A: powers of the generator 3
while g not in ind:
    ind[g], g, k = k, g * 3 % Q, k + 1
chars = [{u: (j * ind[u]) % 4 for u in units} for j in range(4)]
def chi(j, n):                                  # value of chi_j at any integer n, or None for 0
    return None if gcd(n, Q) > 1 else chars[j][n % Q]
def val(j, n):
    c = chi(j, n)
    return (0, 0) if c is None else IPOW[c]

print(f"units mod 10: {units}; powers of 3: {[3 ** k % Q for k in range(4)]}")
print("n       " + "".join(f"{u:>4}" for u in units))
for j in range(4):
    print(f"chi_{j}   " + "".join(f"{show(IPOW[chars[j][u]]):>4}" for u in units))
_, _, brute = all_characters(Q)                 # road B: try all 4^4 = 256 tables
from_gen = sorted(tuple(c[u] for u in units) for c in chars)
print(f"characters mod 10 by trying all 256 tables: {len(brute)}; same as from the generator: {yn(sorted(brute) == from_gen)}")
assert sorted(brute) == from_gen
for q in (7, 8, 12):
    us, m, found = all_characters(q)
    real = sum(1 for f in found if all(2 * v % m == 0 for v in f))
    print(f"mod {q}: phi = {m}, characters found = {len(found)}, real ones = {real}")
    assert len(found) == m                       # as many characters as units

mult = all(val(j, a * b) == gmul(val(j, a), val(j, b)) for j in range(4) for a in range(1, 201) for b in range(1, 201))
print(f"chi(ab) = chi(a) chi(b) for every a, b up to 200 and every chi: {yn(mult)}")
assert mult
rows = [[(0, 0)] * 4 for _ in range(4)]
for j in range(4):
    for kk in range(4):
        s = (0, 0)
        for u in units:
            s = gadd(s, gmul(val(j, u), conj(val(kk, u))))
        rows[j][kk] = s
print("sum over n of chi_j(n) times conj chi_k(n): " + " | ".join(" ".join(show(z) for z in r) for r in rows))
filt = []
for n in range(1, 11):
    s = (0, 0)
    for j in range(4):
        s = gadd(s, gmul(conj(val(j, 3)), val(j, n)))
    filt.append(show(s))
print(f"sum over chi of conj chi(3) chi(n), n = 1..10: {' '.join(filt)}")
assert all(rows[j][kk] == ((4, 0) if j == kk else (0, 0)) for j in range(4) for kk in range(4))
assert filt == ["0", "0", "4", "0", "0", "0", "0", "0", "0", "0"]

sieve = bytearray([1]) * X                      # primes below a million
sieve[0] = sieve[1] = 0
for p in range(2, int(X ** 0.5) + 1):
    if sieve[p]:
        sieve[p * p::p] = bytearray(len(range(p * p, X, p)))
print("x        primes  end 1  end 3  end 7  end 9  S(chi_0)  S(chi_1)  S(chi_2)  4 x end 3 - S(chi_0)  ratio")
count, S, pi, results = {d: 0 for d in range(10)}, [(0, 0)] * 4, 0, {}
for p in range(2, X):
    if sieve[p]:
        pi += 1
        count[p % 10] += 1                       # road one: read the last digit
        S = [gadd(S[j], val(j, p)) for j in range(4)]   # road two: add each character
    if p + 1 in (10**4, 10**5, 10**6):
        print(f"{p + 1:<8} {pi:>6} {count[1]:>6} {count[3]:>6} {count[7]:>6} {count[9]:>6} {show(S[0]):>9} "
              f"{show(S[1]):>9} {show(S[2]):>9}  {4 * count[3] - S[0][0]:>19}  {count[3] / (S[0][0] / 4):.6f}")
print(f"S(chi_3) = {show(S[3])}, the conjugate of S(chi_1); primes ending in 2 or 5: {count[2] + count[5]}")
print("filter: end digit a, (1/4) sum of conj chi(a) S(chi), direct count")
for a in units:
    tot = (0, 0)
    for j in range(4):
        tot = gadd(tot, gmul(conj(val(j, a)), S[j]))
    print(f"  {a}: {show(tot)} / 4 = {tot[0] // 4}, direct {count[a]}")
    assert tot[1] == 0 and tot[0] == 4 * count[a]   # road two against road one, each class
terms = [gmul(conj(val(j, 3)), S[j]) for j in range(4)]
print(f"ending in 3, term by term: {' + '.join('(' + show(t) + ')' for t in terms)} = {sum(t[0] for t in terms)}")
dft = [(0, 0)] * 4                              # the same sums as a 4-point transform of the counts
for j in range(4):
    for kk in range(4):
        dft[j] = gadd(dft[j], gmul((count[3 ** kk % Q], 0), IPOW[j * kk % 4]))
print(f"transform of counts at 1, 3, 9, 7: {' '.join(show(z) for z in dft)}")
assert dft == S                                  # characters on a cyclic group are DFT columns
print(f"chart, bars {count[1]} {count[3]} {count[7]} {count[9]}, line {S[0][0] // 4}")
lead = sum(t[0] for t in terms[1:]) // 4         # the three non-trivial terms, divided by 4
print(f"lead of ending 3 over an even quarter: ({' + '.join(str(t[0]) for t in terms[1:])}) / 4 = {lead}; "
      f"largest gap from {S[0][0] // 4}: {100 * max(abs(count[a] - S[0][0] / 4) for a in units) / (S[0][0] / 4):.2f} percent")

wrong1 = sum(gmul(val(j, 3), S[j])[0] for j in range(4)) // 4
wrong2 = sum(t[0] for t in terms) // 10
wrong3 = (terms[0][0] + terms[2][0]) // 4
wrong4 = sum(gmul(conj(val(j, 5)), S[j])[0] for j in range(4)) // 4
print(f"mistake 1, no conjugate: {wrong1}, the count ending in 7, not {count[3]}")
print(f"mistake 2, divide by q = 10, not phi(10) = 4: {wrong2}, not {count[3]}")
print(f"mistake 3, real characters only: {wrong3}, the average of {count[3]} and {count[7]}")
print(f"mistake 4, class 5, which shares a factor with 10: {wrong4}, though the prime 5 ends in 5")
naive = {1: 0, 3: 1, 7: 2, 9: 3}                 # 1, i, -1, -i in order of size
bad = next((a, b) for a in units for b in units if naive[a * b % Q] != (naive[a] + naive[b]) % 4)
print(f"pattern 1, i, -1, -i on 1, 3, 7, 9: fails at {bad[0]} x {bad[1]}: f({bad[0] * bad[1] % Q}) = "
      f"{show(IPOW[naive[bad[0] * bad[1] % Q]])}, f({bad[0]}) f({bad[1]}) = {show(IPOW[(naive[bad[0]] + naive[bad[1]]) % 4])}")
assert wrong1 == count[7] and wrong4 == 0
print("ALL CHECKS PASS")
