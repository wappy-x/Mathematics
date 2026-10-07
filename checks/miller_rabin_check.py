# Miller-Rabin -- the check behind the card.  Nothing is imported.  221 = 13 x 17, and
# 220 = 4 x 55, so every chain is one power then one squaring.  174 lies; 18 fools the
# older Fermat test and is caught here; 137 is caught by both.  Every power taken twice.
N, D = 221, 55
def fast(a, e):                  # square and multiply, on the 221 clock
    r, b = 1, a % N
    while e:
        if e % 2: r = r * b % N
        b = b * b % N; e //= 2
    return r
def slow(a, e):                  # the same power, one multiplication at a time
    r = 1
    for _ in range(e): r = r * a % N
    return r
def chain(a): f = fast(a, D); return [f, f * f % N]   # the base to the 55th, then squared
def passes(c): return c[0] == 1 or N - 1 in c         # not a witness: 1 first, or 220 anywhere
print("221 = 13 x 17, so composite; 220 = 4 x 55, so each chain is a power then a squaring")
print(f"square roots of 1 here: {[x for x in range(N) if x * x % N == 1]} -- a prime clock has only 1 and {N - 1}")
for a in (174, 18, 137):
    c, f = chain(a), fast(a, N - 1)
    v = "liar, says prime" if passes(c) else "witness, proves composite"
    print(f"base {a:>3}: to the 55th {c[0]:>3}, squared {c[1]:>3} -> {v:<25}; to the 220th {f:>3} -> Fermat says {'prime' if f == 1 else 'composite'}")
liars, fermat = [a for a in range(1, N) if passes(chain(a))], [a for a in range(1, N) if fast(a, N - 1) == 1]
print(f"of the 220 bases, {len(fermat)} fool Fermat but only {len(liars)} fool Miller-Rabin; a quarter of 220 is {(N - 1) // 4}")
assert chain(174) == [47, 220] and chain(18) == [86, 103] and chain(137) == [188, 205]
assert all(fast(a, D) == slow(a, D) for a in range(1, N)) and all(fast(a, 220) == slow(a, 220) for a in (174, 18, 137))
assert 13 * 17 == N and len(fermat) == 16 and 4 * len(liars) <= N - 1 and len(liars) == 6
print("ALL CHECKS PASS")
