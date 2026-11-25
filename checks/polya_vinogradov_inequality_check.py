# Polya-Vinogradov: a character sum over any stretch is below sqrt(q) log q -- the check behind the card.
# Road 1 adds the Legendre symbol (n/1019) over every stretch by brute force.  Road 2 rebuilds
# the symbol from its Gauss sum (the finite Fourier expansion) and sums the stretch in closed form.
# Road 3 walks the proof's chain of bounds.  Road 4 counts reduced quadratic forms to get the class
# number 13 another way.  Road 5 bounds the least non-residue mod 1009 and compares with the truth.
import math

def leg(a, p):                                  # Legendre symbol by Euler's criterion
    r = pow(a, (p - 1) // 2, p)
    return 0 if r == 0 else (1 if r == 1 else -1)
def isprime(n): return n > 1 and all(n % d for d in range(2, math.isqrt(n) + 1))
def f(x): return f"{x + 0.0:.9f}"
def sums(p): return list(acc(p))
def acc(p):                                     # partial sums S(0), S(1), ..., S(p - 1)
    s = 0; yield 0
    for n in range(1, p): s += leg(n, p); yield s
def classno(D):                                 # reduced forms ax^2 + bxy + cy^2 of discriminant D < 0
    h = 0
    for a in range(1, math.isqrt(-D // 3) + 1):
        for b in range(-a + 1, a + 1):
            if (b * b - D) % (4 * a) == 0:
                c = (b * b - D) // (4 * a)
                if c >= a and not (b < 0 and a == c) and math.gcd(math.gcd(a, abs(b)), c) == 1: h += 1
    return h

p = 1019; S = sums(p); bound = math.sqrt(p) * math.log(p)
top = max(S); n_top = S.index(top); low = min(S); n_low = S.index(low)
print(f"p = {p} = 8 x {p // 8} + {p % 8};  (n/{p}) for n = 1..12: " + " ".join("+" if leg(n, p) > 0 else "-" for n in range(1, 13)))
print(f"partial sums S(n): largest {top} at n = {n_top}, smallest {low} at n = {n_low};  S({p - 1}) = {S[-1]}")
res = sum(1 for n in range(1, n_top + 1) if leg(n, p) > 0)
print(f"n = 1..{n_top}: {res} residues, {n_top - res} non-residues, difference {2 * res - n_top}")
print(f"largest stretch sum: {top - low}, over n = {n_low + 1}..{n_top} (M = {n_low}, N = {n_top - n_low})")
print(f"bound sqrt({p}) ln {p} = {f(bound)};  largest stretch / bound = {f((top - low) / bound)}")
assert top == 39 and n_top == 509 and top - low == 40 and S[-1] == 0

# Road 2: the Fourier expansion through the Gauss sum g = sum (a/p) zeta^a
z = [complex(math.cos(2 * math.pi * k / p), math.sin(2 * math.pi * k / p)) for k in range(p)]
g = sum(leg(a, p) * z[a] for a in range(1, p))
err = max(abs(sum(leg(a, p) * z[a * n % p] for a in range(1, p)) / g - leg(n, p)) for n in range(p))
print(f"g = {f(g.real)} + {f(g.imag)}i;  sqrt {p} = {f(math.sqrt(p))};  expansion rebuilds every (n/{p}), worst error below 1e-9: {'yes' if err < 1e-9 else 'no'}")
def geo(a, M, N):                               # sum of zeta^(a n) for M < n <= M + N, closed form
    t = math.pi * a / p
    return complex(math.cos(t * (2 * M + N + 1)), math.sin(t * (2 * M + N + 1))) * math.sin(t * N) / math.sin(t)
four = sum(leg(a, p) * geo(a, 0, n_top) for a in range(1, p)) / g
four2 = sum(leg(a, p) * geo(a, n_low, n_top - n_low) for a in range(1, p)) / g
print(f"S({n_top}) through the expansion: {f(four.real)};  stretch {n_low + 1}..{n_top}: {f(four2.real)}")
assert abs(g.real) < 1e-8 and abs(g.imag - math.sqrt(p)) < 1e-8 and err < 1e-9 and abs(four - 39) < 1e-8 and abs(four2 - 40) < 1e-8

# Road 3: the chain of bounds in the proof
csc = sum(1 / math.sin(math.pi * a / p) for a in range(1, p)); H = sum(1 / a for a in range(1, (p - 1) // 2 + 1))
print(f"sum of 1/sin(pi a/{p}), a = 1..{p - 1}: {f(csc)};  {p} x H_{(p - 1) // 2} = {f(p * H)};  {p} ln {p} = {f(p * math.log(p))}")
print(f"so |stretch| <= {f(csc / math.sqrt(p))} <= {f(p * H / math.sqrt(p))} < {f(bound)}")
assert top - low < csc / math.sqrt(p) < p * H / math.sqrt(p) < bound
mh = (p - 1) // 2                               # H_m against Euler's expansion log m + gamma + 1/(2m) - 1/(12 m^2)
assert abs(H - (math.log(mh) + 0.5772156649015329 + 1 / (2 * mh) - 1 / (12 * mh * mh))) < 1e-9
worst, wp, cnt = 0.0, 0, 0
for q in range(3, 3000):
    if isprime(q):
        T = sums(q); r = (max(T) - min(T)) / (math.sqrt(q) * math.log(q)); cnt += 1
        if r > worst: worst, wp = r, q
print(f"all {cnt} odd primes below 3,000: largest stretch / (sqrt p ln p) is at most {f(worst)}, at p = {wp}")
assert worst < 1
r0 = next(r for r in range(2, p) if all(pow(r, (p - 1) // d, p) != 1 for d in (2, 509)))
ind = {pow(r0, k, p): k for k in range(p - 1)}; w, best = [0j], 0.0
for n in range(1, p):
    k = ind[n]; w.append(w[-1] + complex(math.cos(2 * math.pi * k / (p - 1)), math.sin(2 * math.pi * k / (p - 1))))
for i in range(p):
    for j in range(i + 1, p): best = max(best, abs(w[j] - w[i]))
print(f"complex character of order {p - 1} (chi({r0}) = zeta_{p - 1}): largest stretch {f(best)}")
assert best < bound

# Road 4: the 39 is three class numbers
h = classno(-p); ok, cnt = True, 0
for q in range(7, 2000):
    if isprime(q) and q % 4 == 3:
        cnt += 1; ok = ok and sums(q)[(q - 1) // 2] == (2 - leg(2, q)) * classno(-q)
print(f"class number of discriminant -{p} by reduced forms: {h};  3 x {h} = {3 * h} = S({(p - 1) // 2})")
print(f"S((p-1)/2) = (2 - (2/p)) h(-p) for all {cnt} primes p = 3 mod 4 from 7 to 2,000: {'yes' if ok else 'no'}")
assert h == 13 and 3 * h == top and ok

# Road 5: the least non-residue mod 1009
q = 1009; B = math.sqrt(q) * math.log(q)
n_q = next(n for n in range(2, q) if leg(n, q) < 0)
print(f"mod {q}: (n/{q}) for n = 2..{n_q}: " + " ".join("+" if leg(n, q) > 0 else "-" for n in range(2, n_q + 1)) + f";  least non-residue {n_q}")
big = [1] * q                                   # largest prime factor of each n below q
for d in range(2, q):
    if big[d] == 1:
        for k in range(d, q, d): big[k] = d
m = next(m for m in range(2, q) if max(N - 2 * sum(1 for n in range(2, N + 1) if big[n] >= m) for N in range(1, q)) >= B)
print(f"bounds on it: sqrt {q} ln {q} = {f(B)}, so direct Polya-Vinogradov {math.floor(B) + 1};  Vinogradov's trick {m - 1};  elementary sqrt {q} + 1 = {f(math.sqrt(q) + 1)};  true {n_q}")
print(f"exponents of p: elementary 0.5;  Vinogradov 1/(2 sqrt e) = {f(1 / (2 * math.sqrt(math.e)))};  Burgess 1/(4 sqrt e) = {f(1 / (4 * math.sqrt(math.e)))}")
assert n_q == 11 and m - 1 == 71 and n_q <= m - 1 < math.sqrt(q) * math.log(q) and m - 1 > math.sqrt(q) + 1

# What breaks
print(f"break, principal character mod {p}, n = 1..{p - 1}: {p - 1}, over the bound {f(bound)}")
sq = sum(leg(n * n, p) for n in range(1, n_top + 1))
print(f"break, (n^2/{p}) over n = 1..{n_top}, squares not a stretch: {sq}")
print(f"break, forget to divide by |g|: {f(csc)}, not {f(csc / math.sqrt(p))}")
z8 = [complex(math.cos(math.pi * k / 4), math.sin(math.pi * k / 4)) for k in range(8)]
g8 = sum(c * z8[a] for a, c in enumerate([0, 1, 0, -1, 0, 1, 0, -1]))
print(f"break, character mod 8 lifted from mod 4: g = {f(abs(g8))}, so the expansion divides by 0")
assert p - 1 > bound and sq == n_top and abs(g8) < 1e-12

for q in (1031, 100003):
    T = sums(q)
    print(f"try: p = {q} = {q % 8} mod 8: largest S = {max(T)} at n = {T.index(max(T))}, S({(q - 1) // 2}) = {T[(q - 1) // 2]}, stretch {max(T) - min(T)}, bound {f(math.sqrt(q) * math.log(q))}, h(-p) = {classno(-q)}, least non-residue {next(n for n in range(2, q) if leg(n, q) < 0)}")
print("chart, n: " + " ".join(str(k * (p - 1) // 30) for k in range(31)))
print("chart, S: " + " ".join(str(S[k * (p - 1) // 30]) for k in range(31)))
print("ALL CHECKS PASS")
