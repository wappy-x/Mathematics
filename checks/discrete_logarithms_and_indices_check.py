# Indices on the 13-clock, nothing imported.  Road one: try every x.  Road two: k i = ind a (mod 12).
P, G, N = 13, 2, 12                                      # the clock, the base, the index clock
def gcd(a, b): return a if b == 0 else gcd(b, a % b)
power = [1]
for _ in range(N - 1): power.append(power[-1] * G % P)    # 2^0 .. 2^11 on the clock
ind = {v: i for i, v in enumerate(power)}                  # the index table: power read backwards
def brute(k, a): return [x for x in range(1, P) if x ** k % P == a]       # road one
def by_index(k, a):                      # road two: solve k i = ind a (mod 12), then x = 2^i
    d = gcd(k, N); m = N // d
    if ind[a] % d: return []
    inv = next(t for t in range(m) if k // d * t % m == 1 % m)
    return [ind[a] // d * inv % m + m * t for t in range(d)]
print("index table, base 2 mod 13: " + " ".join(f"{a}:{ind[a]}" for a in range(1, P)))
s, q = (ind[7] + ind[11]) % N, (ind[5] - ind[7] + N) % N
print(f"7 x 11: indices {ind[7]} + {ind[11]} = {ind[7] + ind[11]} = {s} (mod 12), 2^{s} = {power[s]}; direct 77 mod 13 = {77 % P}")
print(f"5 / 7: indices {ind[5]} - {ind[7]} = {ind[5] - ind[7]} = {q} (mod 12), 2^{q} = {power[q]}; check 7 x {power[q]} mod 13 = {7 * power[q] % P}")
for k, a in [(5, 7), (3, 5), (3, 2)]:
    i, d = by_index(k, a), gcd(k, N)
    print(f"x^{k} = {a}: {k}i = {ind[a]} (mod 12), gcd {d}, test {a}^{N // d} = {a ** (N // d) % P}; "
          f"i = {i}, x = {[power[j] for j in i]}; trying all x: {brute(k, a)}")
agree = sum(sorted(power[i] for i in by_index(k, a)) == brute(k, a) and len(brute(k, a)) ==
            (gcd(k, N) if a ** (N // gcd(k, N)) % P == 1 else 0) for k in range(1, P) for a in range(1, P))
print(f"rule against trying every x, k and a from 1 to 12: {agree} of 144 cases agree")
w = ind[7] * next(t for t in range(P) if 5 * t % P == 1) % P            # the index worked mod 13
print(f"mistakes: index mod 13 gives x = {power[w]}, and {power[w]}^5 = {power[w] ** 5 % P}; first answer only: "
      f"{power[by_index(3, 5)[0]]}; multiplying indices: 2^{ind[7] * ind[11] % N} = {power[ind[7] * ind[11] % N]}; base 3 reaches only {sorted({3 ** i % P for i in range(N)})}")
assert agree == 144 and by_index(5, 7) == [7] and power[7] == 11 and brute(5, 7) == [11]
assert sorted(power[i] for i in by_index(3, 5)) == [7, 8, 11] == brute(3, 5) and brute(3, 2) == []
assert power[s] == 12 and power[s] == 77 % P and 7 * power[q] % P == 5 and len(set(power)) == N
print("ALL CHECKS PASS")
