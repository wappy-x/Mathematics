# Arranging with repeats -- the check behind the card.  Nothing is imported.
# Two lines that repeat: a six-slot drum bar of 3 kicks, 2 snares and 1 hat,
# and the eleven letters of MISSISSIPPI.  Each count is reached three ways that
# share no arithmetic: the factorial formula, a product of binomial
# coefficients built by addition alone, and a listing of the arrangements.
DRUM, WORD = (3, 2, 1), (1, 4, 4, 2)
def factorial(m):                             # road one's only ingredient
    out = 1
    for i in range(2, m + 1):
        out *= i
    return out
def by_formula(counts):                       # road one: n! divided by each block
    out = factorial(sum(counts))
    for a in counts:
        out //= factorial(a)
    return out
def choose(n, k):                             # Pascal's triangle: addition only
    row = [1]
    for _ in range(n):
        row = [1] + [row[i] + row[i + 1] for i in range(len(row) - 1)] + [1]
    return row[k]
def by_positions(counts):                     # road two: one kind's places at a time
    left, steps, labels, out = sum(counts), [], [], 1
    for a in counts:
        steps.append(choose(left, a)); labels.append(f"C({left},{a})")
        out *= steps[-1]; left -= a
    return out, steps, labels
def by_listing(counts):                       # road three: build every arrangement
    if sum(counts) == 0: return 1
    return sum(by_listing(counts[:i] + (a - 1,) + counts[i + 1:])
               for i, a in enumerate(counts) if a)

drum_p, drum_s, drum_c = by_positions(DRUM)
word_p, word_s, word_c = by_positions(WORD)
drum_n, word_n = sum(DRUM), sum(WORD)
inside_drum, inside_word = factorial(drum_n) // by_formula(DRUM), factorial(word_n) // by_formula(WORD)
no_division, by_sum = factorial(11), factorial(4) + factorial(4) + factorial(2)
one_block = no_division // (factorial(4) * factorial(4))
drum_f, word_f = " x ".join(f"{a}!" for a in DRUM), " x ".join(f"{a}!" for a in WORD if a > 1)
print(f"factorials in play: 2! = {factorial(2)}, 3! = {factorial(3)}, 4! = {factorial(4)}, 6! = {factorial(6)}, 11! = {no_division}")
print("drum bar, 6 slots: 3 kicks, 2 snares, 1 hat")
print(f"  numbered orderings {factorial(drum_n)}, each bar counted {drum_f} = {inside_drum} times, {factorial(drum_n)} / {inside_drum} = {by_formula(DRUM)}")
print(f"  road 2, one kind at a time: {' x '.join(drum_c)} = {' x '.join(map(str, drum_s))} = {drum_p}")
print(f"  road 3, distinct bars built one by one: {by_listing(DRUM)}")
print("MISSISSIPPI, 11 letters: M 1, I 4, S 4, P 2")
print(f"  numbered orderings {factorial(word_n)}, each word counted {word_f} = {inside_word} times, {factorial(word_n)} / {inside_word} = {by_formula(WORD)}")
print(f"  road 2, one kind at a time: {' x '.join(word_c)} = {' x '.join(map(str, word_s))} = {word_p}")
print(f"  road 3, distinct words built one by one: {by_listing(WORD)}")
print(f"grid paths, 5 steps right and 3 steps up: 8! / (5! 3!) = {by_formula((5, 3))}, and C(8,3) = {choose(8, 3)}")
print(f"mistake 1, no division at all: {no_division}")
print(f"mistake 2, the two P's left undivided: {one_block}")
print(f"mistake 3, dividing by 4! + 4! + 2! = {by_sum}: {no_division // by_sum}")
print(f"mistake 4, counting only where the four S's go, C(11,4): {choose(11, 4)}")
print(f"try changing: 3 kicks and 3 snares gives {by_formula((3, 3))}; a second M in MISSISSIPPI gives {by_formula((2, 4, 4, 2))}")
assert by_formula(DRUM) == drum_p == by_listing(DRUM) == 60          # three roads, one bar
assert by_formula(WORD) == word_p == by_listing(WORD) == 34650       # the same three roads
assert one_block == 2 * by_formula(WORD) == 69300                    # dropping 2! double counts
assert by_formula((5, 3)) == choose(8, 3) == 56                      # formula meets Pascal
print("ALL CHECKS PASS")
