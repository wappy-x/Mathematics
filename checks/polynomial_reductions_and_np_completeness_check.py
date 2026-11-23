# Polynomial reductions and NP-completeness -- the check behind the card.  Nothing is imported.
# A school timetable becomes a clash graph (the map f) and a graph becomes a timetable (the map g).
# Each map is run, its cost is counted, and on every small instance it sends yes to yes and no to no:
# a search over timetables and a search over colourings give the same answers.
EXAMS = ["Art", "Biology", "Chemistry", "Drama", "English", "French", "Geography"]
SCHOOL = [[0, 1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6, 0], [1, 4], [3, 4]]
M64 = (1 << 64) - 1

def f(students):                       # timetable -> graph: one line per pair of exams one student sits
    pairs, lines = 0, set()
    for s in students:
        for i in range(len(s)):
            for j in range(i + 1, len(s)):
                pairs += 1
                lines.add((min(s[i], s[j]), max(s[i], s[j])))
    return pairs, sorted(lines)

def g(lines):                          # graph -> timetable: one student per line, sitting its two ends
    return [[a, b] for a, b in lines]

def assignments(m, k):                 # every way to hand m exams one of k sessions
    for code in range(k ** m):
        out = []
        for _ in range(m):
            out.append(code % k)
            code //= k
        yield out

def count_tt(students, m, k):          # road one: timetables, checked student by student
    return sum(1 for a in assignments(m, k)
               if all(len({a[e] for e in s}) == len(s) for s in students))

def count_col(lines, m, k):            # road two: proper colourings, checked line by line
    return sum(1 for a in assignments(m, k) if all(a[u] != a[v] for u, v in lines))

def fewest(lines, m):                  # the smallest session count with a timetable
    return next(k for k in range(1, m + 1) if count_col(lines, m, k) > 0)

def two_sessions_bfs(lines, m):        # 2 sessions in polynomial time: spread out, alternate sessions
    adj = [[v for v in range(m) if (u, v) in lines or (v, u) in lines] for u in range(m)]
    side, steps, ok = [-1] * m, 0, True
    for start in range(m):
        if side[start] >= 0:
            continue
        side[start], queue = 0, [start]
        while queue:
            u = queue.pop(0)
            steps += 1
            for v in adj[u]:
                steps += 1
                if side[v] < 0:
                    side[v] = 1 - side[u]
                    queue.append(v)
                elif side[v] == side[u]:
                    ok = False
    return ok, steps

def splitmix(state):
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return state, z ^ (z >> 31)

def random_school(state, m, students, size):
    school = []
    for _ in range(students):
        s = []
        while len(s) < size:
            state, z = splitmix(state)
            if z % m not in s:
                s.append(z % m)
        school.append(s)
    return state, school

def sci(x):                            # 3 significant figures, rounded with integers only
    t = (x * 1000 // 10 ** (len(str(x)) - 1) + 5) // 10
    return f"{t // 100}.{t % 100:02d}e{len(str(x)) - 1}"

yn = lambda t: "yes" if t else "no"

m = len(EXAMS)
pairs, lines = f(SCHOOL)
print(f"school: {m} exams, {len(SCHOOL)} students, {pairs} pairs written, {len(lines)} clash lines")
print("clash lines: " + " ".join(EXAMS[u][0] + EXAMS[v][0] for u, v in lines))
written = "/".join("".join(EXAMS[e][0] for e in s) for s in SCHOOL)   # the input, one letter per exam
print(f"input written out: {written}, n = {len(written)} symbols; f writes {pairs} pairs, under n^2 = {len(written) ** 2}")
counts = {k: (count_tt(SCHOOL, m, k), count_col(lines, m, k)) for k in (2, 3)}
for k in (2, 3):
    print(f"{k} sessions: {counts[k][0]} timetables by students, {counts[k][1]} colourings of f(school)")
best = next(a for a in assignments(m, 3) if all(a[u] != a[v] for u, v in lines))
print(f"fewest sessions {fewest(lines, m)}; first timetable: "
      + ", ".join(f"{EXAMS[e]} {best[e] + 1}" for e in range(m)))
checks = sum(len(s) * (len(s) - 1) // 2 for s in SCHOOL)
print(f"verifier on that timetable: {checks} pair checks, accepted: "
      f"{yn(all(len({best[e] for e in s}) == len(s) for s in SCHOOL))}")
all_pairs = [(a, b) for a in range(4) for b in range(a + 1, 4)]
graphs = [[all_pairs[i] for i in range(6) if mask >> i & 1] for mask in range(64)]
agree_g = sum(1 for G in graphs for k in (1, 2, 3) if (count_col(G, 4, k) > 0) == (count_tt(g(G), 4, k) > 0))
round_trip = sum(1 for G in graphs if f(g(G))[1] == G)
print(f"g on all 64 graphs with 4 dots, k = 1, 2, 3: {agree_g} of 192 answers agree; f(g(G)) = G for {round_trip} of 64")
state, agree_f, yes = 2026, 0, 0
for _ in range(200):
    state, sc = random_school(state, 6, 5, 2 + state % 2)
    for k in (2, 3):
        direct = count_tt(sc, 6, k) > 0
        agree_f += direct == (count_col(f(sc)[1], 6, k) > 0)
        yes += direct
print(f"f on 200 random schools, k = 2 and 3: {agree_f} of 400 answers agree; {yes} yes, {400 - yes} no")
cost = []
for size in (10, 20, 40, 80):
    state, sc = random_school(7, size, 2 * size, 5)
    p, ls = f(sc)
    cost.append(p)
    print(f"cost at {size} exams, {2 * size} students of 5 exams: f writes {p} pairs, "
          f"{len(ls)} lines; search tries 3^{size} = {sci(3 ** size)}")
apex = sum(1 for G in graphs
           if (count_col(G, 4, 2) > 0) == (count_col(G + [(v, 4) for v in range(4)], 5, 3) > 0))
print(f"mistake 1, wrong direction: 2 sessions -> 3 sessions plus one all-clash exam agrees on {apex} of 64 graphs")
ok_full, st_full = two_sessions_bfs(lines, m)
dropped = f(SCHOOL[1:])[1]
ok_drop, st_drop = two_sessions_bfs(dropped, m)
print(f"  yet 2 sessions is easy: alternating search on the school {yn(ok_full)} in {st_full} steps, "
      f"without student 1 {yn(ok_drop)} in {st_drop} steps")
print(f"mistake 2, a 'reduction' that searches first: {3 ** m} assignments at {m} exams, {sci(3 ** 40)} at 40")
print(f"mistake 3, dropping student 1 is no reduction: fewest sessions {fewest(dropped, m)}, true answer {fewest(lines, m)}")
for k, r in ((4, 2), (9, 3)):                                     # k: the grid's side, also its colours
    cells = [(i, j) for i in range(k) for j in range(k)]
    e = sum(1 for x in range(k * k) for y in range(x + 1, k * k)
            if cells[x][0] == cells[y][0] or cells[x][1] == cells[y][1]
            or (cells[x][0] // r == cells[y][0] // r and cells[x][1] // r == cells[y][1] // r))
    print(f"sudoku {k} by {k} as colouring: {k * k} cells, {e} lines, {k} colours; "
          f"plus {k} digit dots joined in {k * (k - 1) // 2} lines")
    assert e == k * k * (3 * k - 2 * r - 1) // 2                     # count against a formula
assert counts[2] == (0, 0) and counts[3][0] == counts[3][1] > 0     # two searches, one answer
assert agree_g == 192 and round_trip == 64 and agree_f == 400        # yes to yes, no to no
assert apex == 64 and ok_full == (counts[2][0] > 0) and ok_drop == (fewest(dropped, m) == 2)
assert cost == [20 * s for s in (10, 20, 40, 80)] and pairs == checks and pairs <= len(written) ** 2
print("ALL CHECKS PASS")
