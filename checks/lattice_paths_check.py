# Lattice paths -- the check behind the card.  Nothing is imported.  A museum stands 7
# blocks east and 4 blocks north of a hotel, and a walk steps east or north only.  The
# 330 routes are counted three ways that share no arithmetic: a choose formula, a listing
# of every order of the steps, and a map of corner counts built by addition alone.
EAST, NORTH, CAFE = 7, 4, (3, 2)
STEPS, CUT = EAST + NORTH, CAFE[0] + CAFE[1]   # CUT: blocks walked to the cafe

def choose(n, k):                     # C(n, k), built from a running product
    out = 1 if 0 <= k <= n else 0
    for i in range(max(k, 0)):
        out = out * (n - i) // (i + 1)
    return out
def every_walk(east, north):          # road two: every order of the steps, 1 = north
    orders = ([(c >> i) & 1 for i in range(east + north)] for c in range(2 ** (east + north)))
    return [w for w in orders if sum(w) == north]
def corners(walk):                    # the corners one route stands on, the start included
    return [(i - sum(walk[:i]), sum(walk[:i])) for i in range(len(walk) + 1)]
def by_addition(east, north):         # road three: west neighbour plus south neighbour
    g = [[1] * (east + 1) for _ in range(north + 1)]
    for b in range(1, north + 1):
        for a in range(1, east + 1):
            g[b][a] = g[b][a - 1] + g[b - 1][a]
    return g

routes = every_walk(EAST, NORTH)
listed, formula = len(routes), choose(STEPS, NORTH)
grid = by_addition(EAST, NORTH)
grid_f = [[choose(a + b, b) for a in range(EAST + 1)] for b in range(NORTH + 1)]
west_in, south_in = grid[NORTH][EAST - 1], grid[NORTH - 1][EAST]
to_cafe, from_cafe = choose(CUT, CAFE[1]), choose(STEPS - CUT, NORTH - CAFE[1])
product = to_cafe * from_cafe
through = sum(1 for w in routes if CAFE in corners(w))
avoid = sum(1 for w in routes if CAFE not in corners(w))
diag = [(CUT - b, b) for b in range(NORTH + 1)]
terms = [choose(CUT, b) * choose(STEPS - CUT, NORTH - b) for b in range(NORTH + 1)]
seen_diag = [sum(1 for w in routes if c in corners(w)) for c in diag]
whole_map = sum(choose(a + b, b) * choose(STEPS - a - b, NORTH - b) for b in range(NORTH + 1) for a in range(EAST + 1))
ordered = 1                                 # the north steps wrongly treated as labelled
for i in range(NORTH): ordered = ordered * (STEPS - i)
square, sq = every_walk(5, 5), choose(10, 5)
never = sum(1 for w in square if all(e >= n for e, n in corners(w)))
print(f"hotel to museum: {EAST} blocks east, {NORTH} north, {STEPS} steps in all")
print(f"routes: formula C({STEPS},{NORTH}) = {formula}; listing {listed} of {2 ** STEPS} step orders")
print("routes to each corner, by addition alone (east 0 at the left):")
for b in range(NORTH, -1, -1): print(f"n={b} |" + "".join(f"{v:>7}" for v in grid[b]))
print(f"the same map from the formula: {'yes' if grid == grid_f else 'no'}")
print(f"last step into the museum: {west_in} from the west + {south_in} from the south = {formula}")
print(f"the cafe at ({CAFE[0]},{CAFE[1]}): {to_cafe} routes to it x {from_cafe} on = {product}; by listing: {through}")
print(f"routes avoiding the cafe: {formula} - {product} = {formula - product}; by listing: {avoid}")
print(f"the diagonal {CUT} blocks out: " + ", ".join(f"({a},{b}) {t}" for (a, b), t in zip(diag, terms)))
print(f"those five add to {sum(terms)}; by listing: " + ", ".join(str(c) for c in seen_diag))
print(f"mistake 1, the north steps taken as ordered picks: {ordered}, not {formula}")
print(f"mistake 2, the cafe halves added: {to_cafe} + {from_cafe} = {to_cafe + from_cafe}, not {product}")
print(f"mistake 3, through-counts added over all {(EAST+1)*(NORTH+1)} corners: {whole_map} = {STEPS + 1} x {formula}")
print(f"a square grid, 5 by 5: C(10,5) = {sq}, by listing {len(square)}; {never} never cross the diagonal")
assert formula == listed and sq == len(square) and never == sq - choose(10, 4)   # listings vs formulas
assert grid == grid_f                               # addition against the formula
assert through == product and avoid == formula - product
assert seen_diag == terms and sum(terms) == listed  # Vandermonde, both roads
print("ALL CHECKS PASS")
