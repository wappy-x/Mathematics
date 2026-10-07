# The middle of the row -- the check behind the card.  Nothing is imported.  A shop stocks
# 20 cheeses and a tasting board holds 10.  The count of boards is reached four ways, then
# trapped between bounds that never compute it; and again for 5 from 100.
N, K, M, J = 20, 10, 100, 5           # the board; and a second case, k far from the middle
def triangle_row(n, width):           # road one: each entry is the sum of the two above it
    row = [1] + [0] * width           # row 0, kept to its first width + 1 entries
    for _ in range(n):
        row = [1] + [row[j - 1] + row[j] for j in range(1, width + 1)]
    return row
def falling(n, k):                    # n(n-1)...(n-k+1): k slots filled in order
    out = 1
    for i in range(k): out *= n - i
    return out
def factorial(m):                     # 1 x 2 x ... x m
    out = 1
    for i in range(2, m + 1): out *= i
    return out
def by_listing(n):                    # road three: one bit per cheese, in or out
    counts = [0] * (n + 1)
    for m in range(1 << n): counts[m.bit_count()] += 1
    return counts

row, ten, hundred = triangle_row(N, N), triangle_row(K, K), triangle_row(M, J)
listed = by_listing(N)
central = falling(N, K) // factorial(K)                 # road two: the product formula
vander = sum(x * x for x in ten)                        # road four: row 10 squared and added
c100 = falling(M, J) // factorial(J)
total, avg = sum(row), sum(row) / (2 * K + 1)
peak = max(k for k in range(N + 1) if N - k + 1 > k)    # the last k whose neighbour ratio beats 1
rises = all(row[k] > row[k - 1] for k in range(1, K + 1))
falls = all(row[k] < row[k - 1] for k in range(K + 1, N + 1))
hi20, hi100 = N ** K / factorial(K), M ** J / factorial(J)
print(f"{N} cheeses on the counter, a tasting board holds {K} of them")
print(f"four roads to the count: adding down the triangle {row[K]}, the product formula {central}, "
      f"listing all {1 << N} selections {listed[K]}, squaring and adding row {K} {vander}")
print(f"row {N}: " + " ".join(str(x) for x in row))
print(f"neighbour ratios at the middle: {row[K]}/{row[K - 1]} = {row[K] / row[K - 1]:.3f} above 1, "
      f"{row[K + 1]}/{row[K]} = {row[K + 1] / row[K]:.3f} below 1")
print(f"the row rises to k = {peak} and falls after it: {'yes' if rises and falls else 'no'}; biggest entry {max(row)}")
print(f"row {N} adds to {total} = 4^{K}, and the listing found {sum(listed)} selections in all")
print(f"upper bound, one entry cannot beat the whole row: {row[K]} <= {total}")
print(f"lower bound, {2 * K + 1} entries so the biggest beats the average: "
      f"{total}/{2 * K + 1} = {avg:.2f} <= {row[K]}")
print(f"the same lower bound cleared of fractions: {total} <= {2 * K + 1} x {row[K]} = {(2 * K + 1) * row[K]}")
print(f"the middle entry is {row[K] / total:.4f} of its row; it beats the average by "
      f"{row[K] / avg:.2f} and misses the whole row by {total / row[K]:.2f}")
print(f"digit counts: lower bound {len(str(int(avg)))}, the count {len(str(row[K]))}, upper bound {len(str(total))}")
print(f"bounds at n = {N}, k = {K}: ({N}/{K})^{K} = {(N // K) ** K} <= {row[K]} <= {N}^{K}/{K}! = {hi20:.2f}")
print(f"bounds at n = {M}, k = {J}: ({M}/{J})^{J} = {(M // J) ** J} <= {c100} <= {M}^{J}/{J}! = {hi100:.2f}")
print(f"upper bound divided by the truth: {hi20 / row[K]:.2f} at k = {K} of {N}, {hi100 / c100:.2f} at k = {J} of {M}")
print(f"house row {K}: " + " ".join(str(x) for x in ten) + f" adds to {sum(ten)} = 4^{K // 2}")
print(f"house row {K} sandwich: {sum(ten)}/{K + 1} = {sum(ten) / (K + 1):.2f} <= {ten[K // 2]} <= {sum(ten)}")
print(f"mistakes: half the row gives {total // 2}; 2^{K} in place of 4^{K} gives {2 ** K}; "
      f"the average {avg:.2f} read as the count")
assert row == listed and row[K] == central and row[K] == vander and c100 == hundred[J]
assert peak == K and row[K] == max(row) and rises and falls
assert total == 4 ** K and sum(listed) == total and row[K] <= total and (2 * K + 1) * row[K] >= total
assert (factorial(K) * row[K] <= N ** K and K ** K * row[K] >= N ** K
        and factorial(J) * c100 <= M ** J and J ** J * c100 >= M ** J)
print("ALL CHECKS PASS")
