# Jordan content and Fubini in n dimensions -- the check behind the card.  Nothing is imported.
# Catchment T: the triangle (0, 0), (4, 0), (0, 3) km; slanted edge y = 3 - 3x/4.  Rain depth 10 + 2x mm.
# Roads to 76: hand antiderivatives in both orders; the centroid; square counts and lower/upper sums
# on a grid; column strips trapped between those sums; horizontal layers of the 3D body of water.
depth = lambda x: 10 + 2 * x                  # rain depth in mm, x km east
def mid(g, a, b, n):                           # midpoint sum of g on [a, b], n pieces
    h = (b - a) / n
    return sum(g(a + (k + 0.5) * h) for k in range(n)) * h
def grid(N):                                   # squares of side 1/N km on the box [0, 4] x [0, 3]
    h, cin, cout, lo, hi = 1 / N, 0, 0, 0.0, 0.0
    for i in range(4 * N):
        for j in range(3 * N):
            if 3 * (i + 1) + 4 * (j + 1) <= 12 * N:      # far corner in T: whole square inside
                cin += 1
                lo += depth(i * h) * h * h
            if 3 * i + 4 * j <= 12 * N:                  # near corner in T: square meets T
                cout += 1
                hi += depth(min((i + 1) * h, 4 - 4 * j * h / 3)) * h * h
    return cin, cout, lo, hi
def brute(N, m=3):                             # lowest and highest F over 16 sample points per square
    cells = [[depth((m * i + a) / N / m) * (3 * (m * i + a) + 4 * (m * j + b) <= 12 * N * m)
              for a in range(m + 1) for b in range(m + 1)] for i in range(4 * N) for j in range(3 * N)]
    return sum(map(min, cells)) / N**2, sum(map(max, cells)) / N**2
def layer(z):                                  # area of the water's horizontal slice at height z mm
    return 6.0 if z <= 10 else 3 / 8 * (4 - (z - 10) / 2) ** 2
column = lambda x: 30 - 1.5 * x - 1.5 * x * x                    # hand: north strip, (10 + 2x)(3 - 3x/4)
row = lambda y: 10 * (4 - 4 * y / 3) + (4 - 4 * y / 3) ** 2      # hand: east strip, x from 0 to 4 - 4y/3
x_first = 30 * 4 - 1.5 * 4 ** 2 / 2 - 1.5 * 4 ** 3 / 3          # integral of column from 0 to 4
y_first = 10 * 6 + 4 ** 2 * 3 / 3                                # 10 x area, plus (4 - 4y/3)^2 from 0 to 3
centroid = 10 * 6 + 2 * 6 * 4 / 3                                # depth at x = 4/3, times area 6
print(f"catchment: area {4 * 3 / 2:.0f} km^2, centroid x = {4 / 3:.4f} km; depth {depth(0):.0f} to {depth(4):.0f} mm")
print(f"strips: north at x = 2 carries {column(2):.3f}, east at y = 1.5 carries {row(1.5):.3f}")
assert all(abs(column(t) - mid(lambda y: depth(t), 0, 3 - 0.75 * t, 8)) < 1e-9 and
           abs(row(t / 4 * 3) - mid(depth, 0, 4 - t, 8)) < 1e-9 for t in (0.5, 2, 3.5))
print(f"exact: north strips {x_first:.4f}, east strips {y_first:.4f}, centroid {centroid:.4f} mm km^2")
assert abs(x_first - y_first) < 1e-9 and abs(x_first - centroid) < 1e-9
for N in (10, 100, 1000):
    cin, cout, lo, hi = grid(N)
    s_lo = sum(column((i + 1) / N) for i in range(4 * N)) / N   # column rain falls with x:
    s_hi = sum(column(i / N) for i in range(4 * N)) / N         # lowest at the right side
    print(f"N = {N}: squares inside {cin}, touching {cout}; content {cin / N**2:.6f} to {cout / N**2:.6f}")
    print(f"  rain: lower {lo:.4f} <= strips {s_lo:.4f} to {s_hi:.4f} <= upper {hi:.4f}; gap {hi - lo:.4f}")
    assert cin == 6 * N * N - 3 * N and cout == 6 * N * N + 4 * N - 1     # the edge costs 7N - 1 squares
    assert lo <= s_lo <= x_first <= s_hi <= hi and hi - lo <= 138 / N   # Fubini's squeeze, and the gap
b_lo, b_hi = brute(10)                                           # brute force, no corner formulas
print(f"brute force, N = 10, 16 points per square: lower {b_lo:.4f}, upper {b_hi:.4f}")
assert abs(b_lo - grid(10)[2]) < 1e-9 and abs(b_hi - grid(10)[3]) < 1e-9
print(f"edge squares at N = 1000: {cout - cin}, area {(cout - cin) / N**2:.6f} km^2, under 7/N = {7 / N:.6f}")
layers = mid(layer, 0, 18, 1800)
print(f"layers: slice area at z = 14 mm is {layer(14):.4f} km^2; layers added {layers:.4f} mm km^2")
assert abs(layers - x_first) < 1e-3
print(f"water: {x_first:.0f} mm km^2 = {x_first * 1000:.0f} m^3")
wit = [b for b in (0, 0.5) if 2 * b * b <= 1]     # points ((i + b sqrt 2)/N, j/N): in square (i, j) iff 2b^2 <= 1; a fraction iff b = 0
print(f"rational points, any N: each square holds a fraction point and a point that is not: upper {max(b == 0 for b in wit):d}, lower {min(b == 0 for b in wit):d}")
print(f"mistake, box limits 0..4 by 0..3: {mid(lambda x: 3 * depth(x), 0, 4, 64):.2f}; "
      f"every layer the whole triangle: {6 * 18:.2f}")
g4 = grid(4)
print(f"figure, 80 px per km, N = 4; corners (40,280), (360,280), (40,40); inside {g4[0]} "
      f"({g4[0] / 16:.4f} km^2), meeting T {g4[1]} ({g4[1] / 16:.4f} km^2), on the edge {g4[1] - g4[0]}")
print("ALL CHECKS PASS")
