# Scientific notation -- the check behind the card.  Nothing is imported.  The
# distance to the Sun and the width of a red blood cell, each written out the
# long way and as a front number times a power of ten, then set side by side.

def times_ten(front, power):        # 1.5, 8 -> multiply 1.5 by ten, eight times
    value = front
    for _ in range(abs(power)):
        value = value * 10.0 if power > 0 else value / 10.0
    return value

def row(name, value):
    print(f"{name:<34}{value}")

row("distance to the Sun, km", f"{150000000.0:.0f}")
row("1.5 x 10^8 km, multiplied out", f"{times_ten(1.5, 8):.0f}")
row("distance to the Sun, m", f"{150000000000.0:.0f}")
row("1.5 x 10^11 m, multiplied out", f"{times_ten(1.5, 11):.0f}")
row("width of a red blood cell, m", f"{0.000007:.6f}")
row("7 x 10^-6 m, divided out", f"{times_ten(7.0, -6):.6f}")
long_way = 150000000000.0 / 0.000007                 # one road: plain division
front, power = 1.5 / 7.0 * 10.0, 11 - (-6) - 1       # the other: fronts, then powers
row("Sun over cell, plain division", f"{long_way / times_ten(1.0, 16):.6f} x 10^16")
row("Sun over cell, powers subtracted", f"{1.5 / 7.0:.7f} x 10^17 = {front:.6f} x 10^{power}")
print(f"the dot moves 8 places for the Sun in km and 6 for the cell; km to m adds 3; 11 - (-6) = {11 - (-6)}")
print("more to read: 6.02 x 10^23 slides the dot 23 places right, 1.5 x 10^-9 slides it 9 places left")
print(f"the mistakes come out at {times_ten(7.0, -5):.6f} m and {front:.6f} x 10^{11 + -6 - 1}")
assert times_ten(1.5, 8) == 150000000.0
assert abs(times_ten(7.0, -6) - 0.000007) < 1e-18
assert abs(long_way - times_ten(front, power)) < 1000000.0
print("ALL CHECKS PASS")
