# Log laws and log scales -- the check behind the card.  Nothing is imported.  A
# village of 100, a town of 10,000, a city of 10,000,000, on a 1-10-100 axis.
VILLAGE, TOWN, CITY = 100, 10000, 10000000; REGION, COUNTRY = 100, 10000   # towns in a region, a country
def count_of_tens(x):                 # divide by ten until 1, counting the steps
    steps = 0
    while x > 1:
        assert x % 10 == 0, "not a whole power of ten"; x //= 10; steps += 1
    return steps
def tens_back(steps):                 # the road back: that many tens multiplied
    out = 1
    for _ in range(steps): out *= 10
    return out
for name, size in (("village", VILLAGE), ("town", TOWN), ("city", CITY)):
    print(f"{name:<9}{size:>9}   its count {count_of_tens(size)}")
v, t, c, r = count_of_tens(VILLAGE), count_of_tens(TOWN), count_of_tens(CITY), count_of_tens(REGION)
product, quotient, square = REGION * TOWN, CITY // VILLAGE, COUNTRY * TOWN   # the plain way
half = count_of_tens(product) // v                        # 6 / 2, the count in steps of 100
mid, rem = divmod(v + t, 2); assert rem == 0, "halfway is not a whole count"  # the halfway mark
print(f"100 towns          {REGION} x {TOWN} = {product:<9}count {count_of_tens(product)}")
print(f"the counts added instead     {r} + {t} = {r + t}")
print(f"city / village     {CITY} / {VILLAGE} = {quotient:<7}count {count_of_tens(quotient)}")
print(f"the counts subtracted        {c} - {v} = {c - v}")
print(f"10000 towns        {COUNTRY} x {TOWN} = {square:<10}count {count_of_tens(square)} = {t} + {t}")
print(f"in steps of 100   the product {count_of_tens(product)} / {v} = {half}, the city {c} / {v} = {c / v}")
print(f"halfway from {VILLAGE} to {TOWN}    count {mid}, the {tens_back(mid)} mark")
print(f"the three mistakes come out at {REGION + TOWN}, {(VILLAGE + TOWN) // 2} and {r * t}")
assert product == 1000000 and count_of_tens(product) == r + t and count_of_tens(square) == 2 * t
assert quotient == 100000 and count_of_tens(quotient) == c - v and square == 100000000
assert half == 3 and VILLAGE * VILLAGE * VILLAGE == product and tens_back(mid) == 1000
print("ALL CHECKS PASS")
