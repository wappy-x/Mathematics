# Worst, average and amortised cost -- the check behind the card.  Standard library only.
# A playlist array that doubles when it fills.  Cost is counted in element writes and
# comparisons, never timed.  Every number on the card is printed here.
N = 1_000_000                                   # tracks added to the playlist, one at a time

def c(x):                                       # 1000000 -> "1,000,000"
    return f"{x:,}"

def new_cap(cap):                               # the growth rule: double when full
    return max(1, 2 * cap)

def append_run(n):
    """Really build the array: copy every element on a resize, count every write."""
    slots, size, total, worst, bank, resizes, first = [], 0, 0, 0, 0, 0, []
    for i in range(n):
        cost = 1                                # writing the new track's id
        if size == len(slots):                  # full: allocate a bigger block, copy all across
            bigger = [None] * new_cap(len(slots))
            for j in range(size):
                bigger[j] = slots[j]
                cost += 1
            slots, resizes = bigger, resizes + 1
        slots[size] = i
        size += 1
        total += cost
        worst = max(worst, cost)
        bank += 3 - cost                        # charge 3 per append, pay the true cost
        assert bank >= 2 * size - len(slots) >= 0   # savings cover the potential, every step
        if i < 20:
            first.append(cost)
    assert all(slots[k] == k for k in (0, 1, n // 2, n - 1))   # nothing lost in the copies
    return total, worst, len(slots), resizes, bank, first

def count_run(n, grow, size=0, cap=0):          # second simulator: counts, moves nothing
    total = 0
    for _ in range(n):
        if size == cap:
            total += size
            cap = grow(cap)
        total += 1
        size += 1
    return total

def doubling_formula(n):                        # n writes + copies 1 + 2 + 4 + ... below n
    return n + (1 << (n - 1).bit_length()) - 1

# ---- amortised: one million appends ----
total, worst, cap, resizes, bank, first = append_run(N)
print("playlist array, doubling, n = 1,000,000 appends, cost = element writes")
print(f"{'writes of new tracks':34}{c(N):>14}")
print(f"{'copies during resizes':34}{c(total - N):>14}")
print(f"{'total, counted in the real run':34}{c(total):>14}")
print(f"{'total, second simulator':34}{c(count_run(N, new_cap)):>14}")
print(f"{'total, closed form':34}{c(doubling_formula(N)):>14}")
print(f"{'resizes':34}{resizes:>14}")
print(f"{'final capacity':34}{c(cap):>14}")
print(f"{'worst single append':34}{c(worst):>14}")
print(f"{'amortised cost per append':34}{total / N:>14.2f}")
print(f"{'bank left from 3 per append':34}{c(bank):>14}")
print(f"{'potential 2 x size - capacity':34}{c(2 * N - cap):>14}")
big = 1_048_577                                 # one past a power of two: the bound is tight
tb = doubling_formula(big)
print(f"tight case n = {c(big)}: total {c(tb)}, per append {tb / big:.6f}")
assert total == doubling_formula(N) == count_run(N, new_cap) == 2_048_575
assert worst == (1 << (N - 1).bit_length() - 1) + 1 == 524_289 and cap == 1_048_576
assert total <= 3 * N and tb == count_run(big, new_cap) == 3_145_728 and tb < 3 * big
assert doubling_formula(1 << 20) == count_run(1 << 20, new_cap) == 2_097_151   # exactly full
run = [0]
for x in first:
    run.append(run[-1] + x)
print("chart, cost of appends 1 to 20:", ", ".join(str(x) for x in first))
print("chart, running average:", ", ".join(f"{run[i] / i:.2f}" for i in range(1, 21)))

# ---- worst against average: find a track by checking slots in order ----
def search(lst, target):
    comps = 0
    for x in lst:
        comps += 1
        if x == target:
            return comps
    return comps                                # absent: every slot checked

small = list(range(1000))
every = [search(small, t) for t in small]       # exhaustive: search for every track
playlist = list(range(N))
best, last, absent = search(playlist, 0), search(playlist, N - 1), search(playlist, -1)
summed = skew10 = 0                             # slot pos costs pos comparisons
for pos in range(1, N + 1):                     # every slot, one by one
    summed += pos                               # each slot equally likely
    skew10 += pos * (901 if pos > N - 10_000 else 1)   # 9 in 10 for the newest 10,000 (x 10N)
print()
print("linear search, n = 1,000,000 tracks, cost = comparisons")
print(f"{'best case, track in slot 1':40}{c(best):>12}")
print(f"{'worst case, track in the last slot':40}{c(last):>12}")
print(f"{'worst case, track absent':40}{c(absent):>12}")
print(f"{'average, every slot equally likely':40}{summed / N:>12,.1f}")
print(f"{'average, formula (n + 1) / 2':40}{(N + 1) / 2:>12,.1f}")
print(f"{'mean slot of the newest 10,000':40}{(2 * N - 9_999) / 2:>12,.1f}")
print(f"{'average, 9 in 10 for newest 10,000':40}{skew10 / (10 * N):>12,.1f}")
print(f"small playlist n = 1,000, every track searched: average {sum(every) / 1000:.1f}, worst {c(max(every))}")
assert best == 1 and last == absent == N and summed * 2 == N * (N + 1)
assert sum(every) * 2 == 1000 * 1001 and max(every) == 1000
assert skew10 * 2 == 9 * N * (2 * N - 9_999) + N * (N + 1)   # 0.9 x newest mean + 0.1 x all

# ---- what breaks ----
fixed = count_run(N, lambda cap: cap + 1000)    # grow by a fixed 1,000 slots
x15 = count_run(N, lambda cap: max(1, cap + (cap + 1) // 2))   # grow by half instead of doubling
k = (N - 1) // 1000
def thrash(shrink_at):                          # 10 add/undo pairs at a full 524,288-slot array
    size = cap = 1 << 19
    total = 0
    for _ in range(10):
        total += 1
        if size == cap:
            total += size
            cap *= 2
        size += 1
        total += 1                              # the undo
        size -= 1
        if size <= cap // shrink_at:
            total += size
            cap //= 2
    return total / 20
half, quarter = thrash(2), thrash(4)
print()
print(f"fixed +1,000 growth: total {c(fixed)}, closed form {c(N + 1000 * k * (k + 1) // 2)}, per append {fixed / N:.2f}")
print(f"growth x1.5 instead of x2: total {c(x15)}, per append {x15 / N:.2f}")
print(f"shrink at half full, 10 add/undo pairs at 524,288 tracks: per op {half:,.2f}")
print(f"shrink at quarter full, same 20 operations: per op {quarter:,.2f}")
print(f"worst append quoted as the per-append cost: predicts {c(worst * N)} writes")
assert fixed == N + 1000 * k * (k + 1) // 2 == 500_500_000 and 3 * N < x15 <= 4 * N
assert half == (1 << 19) + 1 and quarter * 20 == (1 << 19) + 20
print("ALL CHECKS PASS")
