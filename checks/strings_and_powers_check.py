# Strings with repetition -- the check behind the card.  Nothing is imported.
# A 4-digit PIN, a licence plate of 3 letters then 3 digits, and the travelling
# parties from a 20-player squad.  Every count is reached twice: once by
# building every string and counting them, once by a road that lists nothing.
DIGITS, LETTERS = "0123456789", "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

def strings(options, k):            # road one: build every string, a position at a time
    out = [""]
    for _ in range(k):
        out = [s + ch for s in out for ch in options]
    return out

def product(factors):               # multiply whole numbers together, nothing else
    out = 1
    for f in factors:
        out *= f
    return out

def power(n, k): return product([n] * k)                  # road two: n multiplied in k times
def falling(n, k): return product(range(n, n - k, -1))    # no repeats: options used up
def c(n): return f"{n:,}"                                 # separators, as the card quotes them

def triangle_row(n):                # road three: additions only, nothing multiplied
    row = [1]
    for _ in range(n):
        row = [a + b for a, b in zip([0] + row, row + [0])]
    return row

small, pins = strings("012", 2), strings(DIGITS, 4)
stages = [len(strings(DIGITS, k)) for k in range(5)]   # 0 to 4 positions, built each time
plate_letters, plate_digits = strings(LETTERS, 3), strings(DIGITS, 3)
plate = len(plate_letters) * len(plate_digits)
parties = triangle_row(20)
total = sum(parties)
alldiff = sum(1 for s in pins if len(set(s)) == 4)
print(f"small case, 2 positions over the digits 0, 1, 2: 3 x 3 = {len(small)} strings")
print("the nine of them: " + " ".join(small))
print("PIN stages, 0 to 4 positions built: " + ", ".join(c(v) for v in stages))
print(f"PIN: 10 digits, 4 positions -> built {c(len(pins))} strings, 10^4 = {c(power(10, 4))}")
print(f"the first and the last PIN built: {pins[0]} and {pins[-1]}")
print(f"plate letters: built {c(len(plate_letters))}, 26^3 = {c(power(26, 3))}")
print(f"plate digits: built {c(len(plate_digits))}, 10^3 = {c(power(10, 3))}")
print(f"whole plate: {c(len(plate_letters))} x {c(len(plate_digits))} = {c(plate)}")
print(f"squad of 20, each player in or out: 2^20 = {c(power(2, 20))}")
print(f"the same total by adding only, row 20 of the sum triangle: {c(total)}")
print(f"parties by size, the first six entries of that row: {parties[:6]}")
print(f"12-player squad both ways: built {c(len(strings('io', 12)))} strings, "
      f"row 12 totals {c(sum(triangle_row(12)))}")
print(f"a byte, 8 positions over 2 options: 2^8 = {c(power(2, 8))}")
print(f"mistake 1, adding the options: 10 + 10 + 10 + 10 = {10 * 4}, not {c(len(pins))}")
print(f"mistake 2, no digit reused: 10 x 9 x 8 x 7 = {c(falling(10, 4))}, "
      f"and the built PINs with four different digits number {c(alldiff)}")
print(f"mistake 3, options and positions swapped: 4^10 = {c(power(4, 10))}, not {c(power(10, 4))}")
print(f"mistake 4, the plate read as one 36-symbol alphabet: 36^6 = {c(power(36, 6))}, not {c(plate)}")
assert len(pins) == power(10, 4) == 10000 and stages == [power(10, k) for k in range(5)]
assert len(plate_letters) * len(plate_digits) == power(26, 3) * power(10, 3) == 17576000
assert total == power(2, 20) and sum(triangle_row(12)) == len(strings("io", 12))
assert alldiff == falling(10, 4) and alldiff < len(pins)
print("ALL CHECKS PASS")
