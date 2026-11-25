# Ext and extensions -- the check behind the card.  Nothing is imported.
# Ext^i(Z/m, N) over the integers, by four roads that share no step: the short
# free resolution, a wider free resolution, an injective resolution through
# Q/Z, and a brute-force count of the extensions themselves as symmetric carry
# rules (cocycles).  Then the glued groups E, the universal coefficient theorem
# on a disc glued four times round a loop, the ring Z/4, and what breaks.

def gcd(a, b):
    while b:
        a, b = b, a % b
    return abs(a)

def sizes(f, dom, zero):                 # (kernel size, cokernel size) of a map, by listing
    image = {f(x) for x in dom}
    kernel = sum(1 for x in dom if f(x) == zero)
    return kernel, len(dom) // len(image)

def road_short(m, n):                    # Hom(-, Z/n) on 0 -> Z --m--> Z: the map Z/n --m--> Z/n
    return sizes(lambda x: m * x % n, list(range(n)), 0)

def road_wide(m, n):                     # Z^2 --(1,-1),(m,0)--> Z^2 --(a,b) -> a+b--> Z/m
    dom = [(u, v) for u in range(n) for v in range(n)]
    return sizes(lambda p: ((p[0] - p[1]) % n, m * p[0] % n), dom, (0, 0))

def road_injective(m, n):                # Hom(Z/m, -) on 0 -> Z/n -> Q/Z --n--> Q/Z; k means k/m
    return sizes(lambda k: n * k % m, list(range(m)), 0)

def road_z(m, den=12):                   # N = Z by 0 -> Z -> Q -> Q/Z, fractions a/b with b <= den
    hom_q = {(a, b) for b in range(1, den + 1) for a in range(-den, den + 1) if m * a == 0 and gcd(a, b) == 1}
    hom_qz = {(a // gcd(a, b), b // gcd(a, b)) for b in range(1, den + 1) for a in range(b) if m * a % b == 0}
    return sum(1 for a, b in hom_q if b == 1), len(hom_qz) // len({(a % b, b) for a, b in hom_q})

def road_cocycles(m, n):                 # symmetric carry rules f(a, b) on Z/m, values in Z/n
    pairs = [(a, b) for a in range(1, m) for b in range(a, m)]
    def f_of(vals):
        table = [[0] * m for _ in range(m)]
        for (a, b), v in zip(pairs, vals):
            table[a][b] = table[b][a] = v
        return table
    def is_cocycle(t):
        return all((t[a][b] + t[(a + b) % m][c] - t[b][c] - t[a][(b + c) % m]) % n == 0
                   for a in range(1, m) for b in range(1, m) for c in range(1, m))
    count, vals = 0, [0] * len(pairs)
    while True:                          # every table of values, as a counter in base n
        count += is_cocycle(f_of(vals))
        i = 0
        while i < len(vals) and vals[i] == n - 1:
            vals[i], i = 0, i + 1
        if i == len(vals):
            break
        vals[i] += 1
    bounds, homs = set(), 0              # coboundaries g(a) + g(b) - g(a + b) of g with g(0) = 0
    for code in range(n ** (m - 1)):
        g = [0] + [code // n ** j % n for j in range(m - 1)]
        d = tuple((g[a] + g[b] - g[(a + b) % m]) % n for a, b in pairs)
        bounds.add(d)
        homs += all(x == 0 for x in d)
    return homs, count // len(bounds), count, len(bounds)

def glued(n0, c, m):                     # E = (N + Z) / <(c, -m)>, N = Z/n0 (n0 = 0: N = Z), by Smith form
    d1, det = gcd(gcd(n0, c), m), abs(n0 * m)
    parts = ["Z"] if det == 0 else []
    parts += [f"Z/{d}" for d in (d1, det // d1 if det else 0) if d > 1]
    return " + ".join(parts) if parts else "0"

def name(k):
    return "0" if k == 1 else f"Z/{k}"

print("Ext(Z/m, N) by four roads: |Hom| |Ext^1|, then the counts behind the last road")
results, cases = {}, [(4, 6), (4, 9), (3, 3)]
for m, n in cases:
    rs = [road_short(m, n), road_wide(m, n), road_injective(m, n), road_cocycles(m, n)]
    results[(m, n)] = rs
    print(f"Z/{m} by Z/{n}: short {rs[0][0]} {rs[0][1]}; wide {rs[1][0]} {rs[1][1]}; "
          f"injective {rs[2][0]} {rs[2][1]}; carries {rs[3][0]} {rs[3][1]} "
          f"({rs[3][2]} cocycles / {rs[3][3]} coboundaries)")
print(f"Z/4 by Z/6, times 4 on Z/6: {[4 * x % 6 for x in range(6)]}, kernel {[x for x in range(6) if 4 * x % 6 == 0]}, "
      f"image {sorted({4 * x % 6 for x in range(6)})}")
for m in (2, 3, 4):                      # N = Z: coker of Z --m--> Z, residues of -60..60 left by m
    hz, ez = road_z(m)
    print(f"Ext^1(Z/{m}, Z): Z/{m}Z has {len({x % m for x in range(-60, 61)})} elements, through Q/Z {ez}; "
          f"Hom(Z/{m}, Z) = {sum(1 for x in range(-60, 61) if m * x == 0) - 1} nonzero maps, through Q {hz - 1}")
print("the glued groups E_c = (N + Z)/<(c, -m)>: c, its class, E")
for n0, m in [(0, 2), (0, 3), (6, 4), (9, 4), (3, 3)]:
    nn = n0 if n0 else m                 # the class of c lives in N/mN
    cls = [c % gcd(nn, m) for c in range(nn)]
    rows = [f"{c}:{cls[c]}:{glued(n0, c, m)}" for c in range(nn)]
    print(f"Z/{m} by {'Z' if n0 == 0 else f'Z/{n0}'}: " + ", ".join(rows))
s_ok = [s for s in (1, -1) if s * 3 == 3 and all(2 * s * z % 3 == z % 3 for z in range(3))]
print(f"equivalences between c = 1 and c = 2 for Z/3 by Z (s = +1 or -1): {len(s_ok)}")
print("disc glued 4 times round a loop: H_0 = Z, H_1 = Z/4, H_2 = 0")
for n in (6, 9):
    h1, h2 = road_short(4, n)            # cochains: G --0--> G --4--> G
    hom, ext = road_injective(4, n)      # Hom(Z/4, G) and Ext(Z/4, G), another road
    print(f"coefficients Z/{n}: cochains H^1 = {name(h1)}, H^2 = {name(h2)}; "
          f"Hom(H_1) + Ext(H_0) = {name(hom)} + 0, Hom(H_2) + Ext(H_1) = 0 + {name(ext)}")
z1 = sum(1 for x in range(-60, 61) if 4 * x == 0)       # cochains Z --0--> Z --4--> Z: kernel of 4, from a window
z2 = len({x % 4 for x in range(-60, 61)})                # Z / 4Z
hz, ez = road_z(4)                                       # Hom(H_1, Z) and Ext(H_1, Z), through Q and Q/Z
print(f"coefficients Z: cochains H^1 = {name(z1)}, H^2 = {name(z2)}; Hom(H_1) + Ext(H_0) = {name(hz)} + 0, "
      f"Hom(H_2) + Ext(H_1) = 0 + {name(ez)}")
r = list(range(4))                       # over the ring Z/4: ... --2--> Z/4 --2--> Z/4 -> Z/2
exact = {2 * x % 4 for x in r} == {x for x in r if 2 * x % 4 == 0}
homs = [v for v in range(2) if 4 * v % 2 == 0]           # Z/4 -> Z/2 is fixed by where 1 goes
ds, ext_z4 = [2] * 6, []                                  # d_1 .. d_6, each times 2; Hom(d_i) precomposes
for i in range(5):                                        # Ext^i = kernel of Hom(d_(i+1)) / image of Hom(d_i)
    kept = sum(1 for v in homs if ds[i] * v % 2 == 0)
    ext_z4.append(kept // (len({ds[i - 1] * v % 2 for v in homs}) if i else 1))
print(f"ring Z/4: kernel of 2 = image of 2: {'yes' if exact else 'no'}; "
      f"Ext^0..Ext^4(Z/2, Z/2) sizes {ext_z4}")
fake = sum(1 for x in range(-60, 61) if 4 * x == 0) - 1  # nonzero maps Z/4 -> Z: none
print(f"mistake 1, 0 -> Z/2 -> Z/4 -> Z/2 as a resolution: Hom(Z/4, Z) has {fake} nonzero maps, "
      f"so it reads Ext^1(Z/2, Z) = 0, not Z/2")
mids = {glued(0, c, 3) for c in range(3)}
classes3 = road_z(3)[1]                                  # Ext^1(Z/3, Z), through Q/Z
print(f"mistake 2, Z/3 by Z counted by the group E: {len(mids)} groups, but {classes3} classes")
same = len({glued(9, c, 4) for c in range(9)})
print(f"mistake 3, Z/4 by Z/9 read as no extension: there is {results[(4, 9)][0][1]}, the split one; "
      f"all 9 values of c give {same} group, Z/9 + Z/4 = {glued(9, 0, 4)}")
print(f"mistake 4, over Z/4 Ext^2(Z/2, Z/2) has {ext_z4[2]} elements, not 1;"
      f" Ext^1(Z, Z/2) = 0 since Z is free")
h2z = sum(1 for x in range(-60, 61) if 4 * x == 0)      # H_2 = kernel of the boundary x4 = 0, so Hom(H_2, Z) = 0
print(f"mistake 5, H^2(disc glued 4 times; Z) as Hom(H_2, Z) alone: {name(h2z)}, not {name(z2)}")
for m, n in cases:
    rs, g = results[(m, n)], gcd(m, n)
    assert [x[:2] for x in rs] == [(g, g)] * 4                 # four roads, one answer
    assert rs[3][2] == rs[3][3] * g                            # cocycles = coboundaries x |Ext|
assert glued(0, 0, 2) == "Z + Z/2" and glued(0, 1, 2) == "Z"   # split and times-2
assert len({glued(6, c, 4) for c in range(6)}) == 2 and glued(6, 1, 4) == "Z/24"
assert glued(6, 0, 4) == "Z/2 + Z/12" and glued(6, 2, 4) == "Z/2 + Z/12"    # 2 is in 4N: split
assert len(mids) == 2 and classes3 == 3 and s_ok == [] and same == 1 and (z1, z2) == (hz, ez)   # cochains = UCT
assert all(road_z(m) == (1, m) for m in (2, 3, 4))                            # Hom(Z/m, Z) = 0, Ext^1 = Z/m
assert exact and ext_z4 == [2] * 5 and fake == 0
print("ALL CHECKS PASS")
