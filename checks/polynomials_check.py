# Polynomials -- the check behind the card.  Nothing is imported.  A football
# kicked straight up at 20 m/s is 20t - 5t^2 metres up after t seconds.  A
# coefficient list runs from the plain number upward: the ball is [0, 20, -5],
# a second ball thrown off a 3 m wall is [3, 12, -5].
BALL, WALL = [0, 20, -5], [3, 12, -5]
def plain(c, t):                    # one road: work out each power, then add
    total = 0.0
    for i, a in enumerate(c):
        power = 1.0
        for _ in range(i): power *= t
        total += a * power
    return total
def nested(c, t):                   # second road: multiply and add, no powers
    total = 0.0
    for a in reversed(c): total = total * t + a
    return total
def add(c, d):                      # line the lists up, add what sits together
    return [(c[i] if i < len(c) else 0) + (d[i] if i < len(d) else 0)
            for i in range(max(len(c), len(d)))]
def mul(c, d):                      # every term of one times every term of the other
    out = [0] * (len(c) + len(d) - 1)
    for i, a in enumerate(c):
        for j, b in enumerate(d): out[i + j] += a * b
    return out
def degree(c): return max(i for i, a in enumerate(c) if a != 0)
def row(name, vals): print(f"{name:<15}" + "".join(f"{v:>7}" for v in vals))
ts = [i / 2 for i in range(13)]     # 0, 0.5, 1.0 ... 6.0 seconds
row("t, seconds", [f"{t:.1f}" for t in ts])
row("height, m", [f"{plain(BALL, t):.2f}" for t in ts])
print(f"degree {degree(BALL)}; coefficients {BALL[2]} for t^2, {BALL[1]} for t, {BALL[0]} plain")
print("height at t = 1, 2, 3, 4: "
      + ", ".join(f"{plain(BALL, t):.2f}" for t in (1.0, 2.0, 3.0, 4.0)) + " metres")
print("the piece 20t: " + ", ".join(f"{20 * t:.2f}" for t in (1.0, 2.0, 3.0, 4.0))
      + "; the piece 5t^2: " + ", ".join(f"{5 * t * t:.2f}" for t in (1.0, 2.0, 3.0, 4.0)))
print("the roots, where the height is zero: t = 0 and t = 4")
far = max(abs(plain(BALL, t) - nested(BALL, t)) for t in ts)
print(f"the nested route gives the same heights; biggest difference {far:.8f}")
print(f"far end at t = 10: 20t is {20 * 10.0:.2f}, 5t^2 is {5 * 100.0:.2f}, "
      f"height {plain(BALL, 10.0):.2f}")
e = mul([0, 5], [4, -1])
print(f"5t times (4 - t): plain {e[0]}, t coefficient {e[1]}, t^2 coefficient {e[2]}; "
      f"degrees add, 1 + 1 = {degree(e)}")
print(f"second ball: plain {WALL[0]}, t coefficient {WALL[1]}, t^2 coefficient {WALL[2]}, "
      f"degree {degree(WALL)}")
d = add(WALL, [-a for a in BALL])
print(f"the gap between them: plain {d[0]}, t coefficient {d[1]}, t^2 coefficient {d[2]}, "
      f"degree {degree(d)}")
level = 3 / 8
print(f"the balls are level at t = {level:.3f} s, both at {plain(BALL, level):.6f} m")
print("h(2 + s) = 20 - 5s^2, so at s = 0, 1, 2 the heights are "
      + ", ".join(f"{plain(BALL, 2 + s):.2f}" for s in (0.0, 1.0, 2.0)))
print(f"three mistakes at t = 3: {20 * 3.0 - (5 * 3.0) ** 2:.2f}, {20 - 3.0 * 3.0:.2f} and "
      f"{20 * (2 + 1.0) - 5 * (4 + 1.0 * 1.0):.2f} instead of {plain(BALL, 3.0):.2f}")
assert [plain(BALL, t) for t in (1.0, 2.0, 3.0, 4.0)] == [15, 20, 15, 0]
assert far == 0.0 and degree(BALL) == 2 and degree(d) == 1 and e == BALL
assert d == [3, -8, 0] and mul([0, 5], [4, -1]) == mul([4, -1], [0, 5])
assert all(plain(BALL, 2 + s) == 20 - 5 * s * s for s in (0.0, 1.0, 2.0))
print("ALL CHECKS PASS")
