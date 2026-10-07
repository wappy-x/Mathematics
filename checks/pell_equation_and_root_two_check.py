# Pell's equation x^2 - 2y^2 = 1 -- the check behind the card.  Nothing is
# imported.  Road one multiplies by 3 + 2 root 2 and reads the whole numbers
# off.  Road two searches every bottom number up to 10,000 and asks whether
# 1 + 2y^2 is a perfect square.  The two roads must hand back the same pairs.
LIMIT = 10000

def isqrt(n):                                   # whole-number square root, floor
    k = n
    while k * k > n:
        k = (k + n // k) // 2
    return k

def norm(p):                                    # x + y root 2 times its conjugate
    return p[0] * p[0] - 2 * p[1] * p[1]

def forward(x, y):                              # multiply by 3 + 2 root 2
    return 3 * x + 4 * y, 2 * x + 3 * y

def backward(x, y):                             # multiply by 3 - 2 root 2
    return 3 * x - 4 * y, 3 * y - 2 * x

def places_right(x, y):                         # decimals of x/y that match root 2
    k = 0
    while x * 10 ** (k + 1) // y == isqrt(2 * 10 ** (2 * k + 2)):
        k += 1
    return k

chain, x, y = [], 1, 0                          # road one: start at 1 + 0 root 2
while True:
    x, y = forward(x, y)
    if y > LIMIT:
        break
    chain.append((x, y))
found = [(isqrt(1 + 2 * t * t), t) for t in range(1, LIMIT + 1)   # road two
         if isqrt(1 + 2 * t * t) ** 2 == 1 + 2 * t * t]
root2 = 2 ** 0.5
over = [x / y - root2 for x, y in chain]
places = [places_right(x, y) for x, y in chain]

print(f"root 2 to seven places: {root2:.7f}")
for n, ((x, y), o, p) in enumerate(zip(chain, over, places), 1):
    print(f"step {n}: ({x:>4}, {y:>4})  {x * x:>8} - {2 * y * y:>8} = {norm((x, y))}"
          f"   {x:>4}/{y:<4} = {x / y:.7f}   over by {o:.10f}   places right {p}")
print(f"search to y = {LIMIT}: {len(found)} pairs, the same list in the same order")
print(f"backward step from (17, 12): {backward(17, 12)}, from (3, 2): {backward(3, 2)}")
print(f"overshoot bound at (99, 70): {1 / (2 * root2 * 70 * 70):.10f}, actual {over[2]:.10f}")
print(f"A4 paper, 297 over 210, reduces to {297 // 3}/{210 // 3}: step 3 exactly")
wrong = [norm((chain[1][0], 2 * chain[1][0] + 3 * chain[0][1])),   # new top, old bottom
         norm((141, 100)), norm((7, 5))]
print(f"mistakes: 17^2 - 2 x 40^2 = {wrong[0]}, 141^2 - 2 x 100^2 = {wrong[1]}, "
      f"7^2 - 2 x 5^2 = {wrong[2]}, none of them 1")
square = [t for t in range(1, LIMIT + 1) if isqrt(1 + 4 * t * t) ** 2 == 1 + 4 * t * t]
print(f"x^2 - 4y^2 = 1, bottom numbers 1 to {LIMIT}: {len(square)} solutions")
assert chain == found
assert [backward(x, y) for x, y in chain[1:]] == chain[:-1] and backward(3, 2) == (1, 0)
assert all(0 < o < 1 / (2 * root2 * y * y) for (x, y), o in zip(chain, over))
assert places == [0, 2, 4, 5, 6] and wrong == [-2911, -119, -1] and square == []
print("ALL CHECKS PASS")
