# Residue classes -- the check behind the card.  Nothing is imported.  The 12
# pitch classes: up a fifth twice, 7 + 7 = 14, which lands in bucket 2.  Then the
# mod 5 and mod 6 tables, built from the buckets and again from far-off members.
def bucket(x, n): return x % n           # which of the n buckets x falls in
def table(n, jump, times):               # jump 0 uses 0 to n-1, jump 3 uses far members
    pick = lambda i, s: i + s * jump * n
    return [[bucket(pick(a, 1) * pick(b, -2) if times else pick(a, 1) + pick(b, -2), n)
             for b in range(n)] for a in range(n)]
def walk(step, n):                       # step round the n buckets until back at bucket 0
    seen = [0]
    while bucket(seen[-1] + step, n):
        seen.append(bucket(seen[-1] + step, n))
    return seen
def row(name, rows):
    print(f"{name:<22}" + " | ".join(" ".join(str(v) for v in r) for r in rows))
def zero_pairs(n): return [(a, b) for a in range(1, n) for b in range(1, n) if bucket(a * b, n) == 0]
print(f"{'pitch classes in an octave':<38}{12:>4}")
print(f"{'up two fifths, 7 + 7 = 14, bucket':<38}{bucket(14, 12):>4}")
print(f"{'an octave up, 19 + 19 = 38, bucket':<38}{bucket(38, 12):>4}")
print("bucket 2 holds ... " + " ".join(str(2 + 12 * k) for k in (-2, -1, 0, 1, 2)) + " ...")
print(f"fifths walk by 7: {' '.join(map(str, walk(7, 12)))}, back to 0 after {len(walk(7, 12))} buckets")
print(f"walk by 8 instead: {' '.join(map(str, walk(8, 12)))}, back to 0 after {len(walk(8, 12))} buckets")
row("mod 5 add rows 0-4:", table(5, 0, False))
row("mod 5 times rows 0-4:", table(5, 0, True))
row("mod 6 times rows 0-5:", table(6, 0, True))
print(f"non-zero pairs multiplying to 0: mod 5: {len(zero_pairs(5))}, mod 6: {len(zero_pairs(6))}: " + ", ".join(f"{a} x {b}" for a, b in zero_pairs(6)))
assert bucket(14, 12) == 2 and bucket(38, 12) == 2 and bucket(-22, 12) == 2 and walk(7, 12) == [0, 7, 2, 9, 4, 11, 6, 1, 8, 3, 10, 5] and walk(8, 12) == [0, 8, 4]
assert table(5, 0, True) == [[0, 0, 0, 0, 0], [0, 1, 2, 3, 4], [0, 2, 4, 1, 3], [0, 3, 1, 4, 2], [0, 4, 3, 2, 1]] and zero_pairs(5) == []
assert zero_pairs(6) == [(2, 3), (3, 2), (3, 4), (4, 3)] and table(5, 0, True) == table(5, 3, True) and table(6, 0, True) == table(6, 3, True) and table(5, 0, False) == table(5, 3, False) and table(5, 0, False) == [[0, 1, 2, 3, 4], [1, 2, 3, 4, 0], [2, 3, 4, 0, 1], [3, 4, 0, 1, 2], [4, 0, 1, 2, 3]]
print("ALL CHECKS PASS")
