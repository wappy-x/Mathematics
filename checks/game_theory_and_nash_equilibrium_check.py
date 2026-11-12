# Nash equilibrium -- the check behind the card.  Nothing is imported.
# Game 1: a penalty kick.  Kicker and goalkeeper each pick Left or Right (both
# named from the kicker's side).  Entries are the kicker's chance of scoring, in
# percent: illustrative round numbers of the size measured in professional
# football.  The goalkeeper wants the opposite, so this is a zero-sum game.
# Game 2: two bakeries set a loaf price, High or Low; synthetic profits in pounds.
# Roads to the mixed equilibrium: (1) the indifference formula, (2) a brute-force
# grid over every mix in steps of 1/600, (3) fictitious play, 100,000 rounds.
A, B, C, D = 58, 95, 93, 70          # kick L/dive L, kick L/dive R, kick R/dive L, kick R/dive R
SIDES = ("L", "R")
PEN = {("L", "L"): A, ("L", "R"): B, ("R", "L"): C, ("R", "R"): D}

def pure_equilibria(rows, cols, pay_row, pay_col):
    """Every cell where neither player gains by switching alone."""
    found = []
    for r in rows:
        for c in cols:
            row_ok = all(pay_row(r, c) >= pay_row(r2, c) for r2 in rows)
            col_ok = all(pay_col(r, c) >= pay_col(r, c2) for c2 in cols)
            if row_ok and col_ok:
                found.append((r, c))
    return found

# best responses in the penalty, cell by cell
for g in SIDES:
    best = "L" if PEN[("L", g)] >= PEN[("R", g)] else "R"
    print(f"goalkeeper dives {g}: kicker's best reply is {best} ({PEN[(best, g)]}% against {PEN[('R' if best == 'L' else 'L', g)]}%)")
for k in SIDES:
    best = "L" if PEN[(k, "L")] <= PEN[(k, "R")] else "R"
    print(f"kicker shoots {k}: goalkeeper's best reply is {best} (lets in {PEN[(k, best)]}%)")
pen_pure = pure_equilibria(SIDES, SIDES, lambda r, c: PEN[(r, c)], lambda r, c: -PEN[(r, c)])
print(f"penalty, pure equilibria: {pen_pure if pen_pure else 'none'}")

# road 1: the indifference formula
den = B + C - A - D
p_star = (C - D) / den               # kicker's chance of shooting Left
q_star = (B - D) / den               # goalkeeper's chance of diving Left
value = (B * C - A * D) / den        # scoring chance at the equilibrium, percent
print(f"denominator b + c - a - d = {den}; bc - ad = {B * C} - {A * D} = {B * C - A * D}")
print(f"road 1, formula: kicker Left p* = {C - D}/{den} = {p_star:.4f}; keeper Left q* = {B - D}/{den} = {q_star:.4f}; scoring {value:.4f}%")
kick_L = q_star * A + (1 - q_star) * B
kick_R = q_star * C + (1 - q_star) * D
dive_L = p_star * A + (1 - p_star) * C
dive_R = p_star * B + (1 - p_star) * D
print(f"1 - q* = {1 - q_star:.4f}; 1 - p* = {1 - p_star:.4f}")
print(f"against q*, kicker scores {kick_L:.4f}% going L and {kick_R:.4f}% going R")
print(f"against p*, keeper lets in {dive_L:.4f}% diving L and {dive_R:.4f}% diving R")

# road 2: brute force over every mix k/600 (integers, so no rounding)
N = 600
def kicker_floor(k):                 # kicker mixes k/600 on L; keeper picks the worse side for him
    return min(A * k + C * (N - k), B * k + D * (N - k))
def keeper_ceiling(j):               # keeper mixes j/600 on L; kicker picks the better side
    return max(A * j + B * (N - j), C * j + D * (N - j))
k_best = j_best = 0
for i in range(N + 1):               # keep the first best, as the Rust does
    if kicker_floor(i) > kicker_floor(k_best):
        k_best = i
    if keeper_ceiling(i) < keeper_ceiling(j_best):
        j_best = i
print(f"road 2, grid: kicker's best guaranteed mix {k_best}/600 = {k_best / N:.4f}, scoring at least {kicker_floor(k_best) / N:.4f}%")
print(f"road 2, grid: keeper's best mix {j_best}/600 = {j_best / N:.4f}, conceding at most {keeper_ceiling(j_best) / N:.4f}%")

# road 3: fictitious play -- each round, each side best-replies to the other's past frequencies
kL = kR = gL = gR = 0
ROUNDS = 100000
for t in range(ROUNDS):
    k_move = "L" if A * gL + B * gR >= C * gL + D * gR else "R"
    g_move = "L" if A * kL + C * kR <= B * kL + D * kR else "R"
    kL, kR = kL + (k_move == "L"), kR + (k_move == "R")
    gL, gR = gL + (g_move == "L"), gR + (g_move == "R")
print(f"road 3, fictitious play over {ROUNDS} rounds: kicker Left {kL / ROUNDS:.4f}, keeper Left {gL / ROUNDS:.4f}")
print(f"road 3 misses the formula by {abs(kL / ROUNDS - p_star):.4f} and {abs(gL / ROUNDS - q_star):.4f}")

# what breaks
def keeper_reply_score(p):           # the keeper sees the kicker's mix and dives to the side letting in less
    return min(p * A + (1 - p) * C, p * B + (1 - p) * D)
def kicker_reply_score(q):
    return max(q * A + (1 - q) * B, q * C + (1 - q) * D)
half = keeper_reply_score(0.5)
swapped = keeper_reply_score(q_star)
pure_best = max(min(A, B), min(C, D))
keeper_half = kicker_reply_score(0.5)
print(f"mistake, kicker goes 50-50: keeper lets in {0.5 * A + 0.5 * C:.4f}% diving L, {0.5 * B + 0.5 * D:.4f}% diving R; scoring {half:.4f}%")
print(f"mistake, kicker uses the keeper's number {q_star:.4f}: scoring {swapped:.4f}%")
print(f"mistake, kicker always picks one side: best is always R, scoring {pure_best}%")
print(f"mistake, keeper goes 50-50: kicker always shoots R, scoring {keeper_half:.4f}%")
print(f"mixing beats one side by {value - pure_best:.4f} points; the 50-50 keeper gives away {keeper_half - value:.4f}")

# game 2: the bakery price war (row = our bakery, column = the rival), profits in pounds a day
P = ("High", "Low")
OURS = {("High", "High"): 1200, ("High", "Low"): 700, ("Low", "High"): 1500, ("Low", "Low"): 900}
THEIRS = {(r, c): OURS[(c, r)] for r in P for c in P}
bake_pure = pure_equilibria(P, P, lambda r, c: OURS[(r, c)], lambda r, c: THEIRS[(r, c)])
for c in P:
    best = "High" if OURS[("High", c)] >= OURS[("Low", c)] else "Low"
    other = "Low" if best == "High" else "High"
    print(f"rival prices {c}: our best reply is {best} ({OURS[(best, c)]} against {OURS[(other, c)]})")
print(f"bakeries, pure equilibria: {', '.join(f'({r}, {c})' for r, c in bake_pure)}")
print(f"at (Low, Low) each makes {OURS[('Low', 'Low')]}; at (High, High) each would make {OURS[('High', 'High')]}")
print(f"from (High, High), our bakery gains {OURS[('Low', 'High')] - OURS[('High', 'High')]} by cutting alone")

# the figure: best-reply lines in a 200 by 200 square, origin at (60, 230)
fx, fy = 60 + 200 * p_star, 230 - 200 * q_star
print(f"figure, crossing at ({fx:.1f}, {fy:.1f}); kicker's jump at y = {fy:.1f}; keeper's jump at x = {fx:.1f}")

assert pen_pure == [] and bake_pure == [("Low", "Low")]          # exhaustive cell search
assert k_best * den == (C - D) * N and j_best * den == (B - D) * N      # grid meets formula
assert abs(kicker_floor(k_best) / N - value) < 1e-9 and abs(keeper_ceiling(j_best) / N - value) < 1e-9
assert abs(kick_L - kick_R) < 1e-9 and abs(dive_L - dive_R) < 1e-9   # indifference holds
assert abs(kL / ROUNDS - p_star) < 0.01 and abs(gL / ROUNDS - q_star) < 0.01
assert half < value and swapped < value and pure_best < value and keeper_half > value
print("ALL CHECKS PASS")
