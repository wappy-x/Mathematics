# The isomorphism theorems and the correspondence theorem -- the check behind the card.
# No imports.  A group is its table: T[a][b] is a combined with b.  A set of members is a
# bit mask, and a pile (coset) is the mask of one member combined with every member of N.
def mask(it): return sum(1 << i for i in set(it))
def mem(m): return [i for i in range(m.bit_length()) if m >> i & 1]
def size(m): return bin(m).count("1")
def prod(T, A, B): return mask(T[a][b] for a in mem(A) for b in mem(B))  # all a with all b
def is_sub(T, S): return S > 0 and prod(T, S, S) & ~S == 0      # finite: closed is enough
def subs(T): return [S for S in range(1, 1 << len(T)) if is_sub(T, S)]  # brute force
def piles(T, N): return list(dict.fromkeys(prod(T, 1 << g, N) for g in range(len(T))))
def quotient(T, N):                 # the piles and their table; a product that is not one
    P = piles(T, N)                 # whole pile stops the program at P.index
    return P, [[P.index(prod(T, A, B)) for B in P] for A in P]
def above(T, N):                    # which unions of N's piles are subgroups of T itself
    P = piles(T, N); return [m for m in range(1, 1 << len(P)) if is_sub(T, mask(x for i in mem(m) for x in mem(P[i])))]
def diamond(T, H, N):               # sizes of HN and of the overlap, then both pile counts
    HN, ov = prod(T, H, N), H & N
    pairs = {(prod(T, 1 << h, ov), prod(T, 1 << h, N)) for h in mem(H)}
    left, right = {a for a, _ in pairs}, {b for _, b in pairs}
    onto = right == {prod(T, 1 << g, N) for g in mem(HN)}
    return size(HN), size(ov), len(right), len(left), len(pairs) == len(left) == len(right) and onto
def pile(P, x): return mem(next(p for p in P if p >> x & 1))     # the pile holding x
Z24, Z12 = [[[(a + b) % n for b in range(n)] for a in range(n)] for n in (24, 12)]
M = [(r, f) for f in (0, 1) for r in range(4)]          # the tile: f flips first, then r turns
D4 = [[M.index(((a[0] + (-1) ** a[1] * b[0]) % 4, a[1] ^ b[1])) for b in M] for a in M]
K, N4, H6 = mask([0, 12]), mask(range(0, 24, 4)), mask(range(0, 24, 6))
(P1, Q1), (P3, Q3) = quotient(Z24, K), quotient(Z24, N4)
NK = mask(i for i, p in enumerate(P1) if p & ~N4 == 0)      # the piles inside N: N over K
P2, Q2 = quotient(Q1, NK)
unpack = [mask(x for i in mem(A) for x in mem(P1[i])) for A in P2]
u = [P3.index(m) if m in P3 else -1 for m in unpack]
keeps = all(u[Q2[a][b]] == Q3[u[a]][u[b]] for a in range(len(P2)) for b in range(len(P2)))
print(f"24-hour clock by {mem(K)}: {len(P1)} piles; those by {sorted(min(mem(P1[i])) for i in mem(NK))}: {len(P2)}; at once by the {size(N4)} multiples of 4: {len(P3)}")
print(f"N over K: {[mem(P1[i]) for i in mem(NK)]}; 22:00 is in {pile(P1, 22)}, which lies in {pile(P3, 22)}")
print(f"22:00 reads {pile(P1, 22)[0]}, then {pile(unpack, 22)[0]}; at once {pile(P3, 22)[0]}. Two-stage piles unpack to one-stage piles {sorted(unpack) == sorted(P3)}, sums kept on {len(P2) ** 2} pairs {keeps}")
dz, dt = diamond(Z24, H6, N4), diamond(D4, mask([0, 4]), mask(range(4)))
print(f"diamond on the clock: H = multiples of 6 ({size(H6)}), N = multiples of 4 ({size(N4)}), overlap {dz[1]}, H + N {dz[0]} = {size(H6)} x {size(N4)} / {dz[1]}")
print(f"  H + N over N: {dz[2]} piles; H over the overlap: {dz[3]} piles; matched one to one and onto {dz[4]}")
print(f"diamond on the tile: H = [r0, r0f], N = the 4 turns, overlap {dt[1]}, HN {dt[0]} = {size(mask([0, 4]))} x {size(mask(range(4)))} / {dt[1]} moves; piles {dt[2]} and {dt[3]}, matched {dt[4]}")
s12, divs, a24 = subs(Z12), [d for d in range(1, 13) if 12 % d == 0], above(Z24, K)
up = sorted(mask(x % 12 for i in mem(m) for x in mem(P1[i])) for m in a24)
print(f"subgroups of the 12-hour clock, brute force over {2 ** 12} subsets: {len(s12)}, sizes {sorted(map(size, s12))}")
print(f"  the multiples of each d in {divs}: the same {len(divs)} sets {s12 == sorted(mask(range(0, 12, d)) for d in divs)}")
print(f"  subgroups of the 24-hour clock containing {mem(K)}: {len(a24)}; read mod 12 they are those {up == s12}; pile for pile {a24 == subs(Q1)}")
sD4, inv = subs(D4), [row.index(0) for row in D4]
normal = [S for S in sD4 if all(prod(D4, prod(D4, 1 << g, S), 1 << inv[g]) == S for g in range(8))]
print(f"tile: {len(sD4)} subgroups, {len(normal)} of them normal")
rows = []
for N in normal:
    P, Q = quotient(D4, N)
    rows.append((len(subs(Q)), len([S for S in sD4 if S & N == N]), above(D4, N) == subs(Q)))
    print(f"  by [{', '.join(['r0', 'r1', 'r2', 'r3', 'r0f', 'r1f', 'r2f', 'r3f'][i] for i in mem(N))}]: piles {len(P)}, subgroups of the quotient {rows[-1][0]}, tile subgroups containing it {rows[-1][1]}, matched {rows[-1][2]}")
bad, st = mask([0, 4, 8]), prod(D4, mask([0, 4]), mask([0, 5])); copies = len({prod(Z24, 1 << g, bad) for g in range(24)})
print(f"mistakes: {mem(bad)} in the 24-hour clock is a subgroup {is_sub(Z24, bad)}, {copies} copies x 3 = {copies * 3} slots for 24; H + N as {size(H6)} x {size(N4)} = {size(H6) * size(N4)}")
print(f"  every tile subgroup counted for the quotient by [r0, r2]: {len(sD4)}, not {rows[1][0]}; [r0, r0f] times [r0, r1f]: {size(st)} moves, a subgroup {is_sub(D4, st)}")
assert sorted(unpack) == sorted(P3) and len(P1) == 12 and len(P2) == len(P3) == 4 and keeps
assert dz[0] * dz[1] == size(H6) * size(N4) and dz[2:] == (2, 2, True) and dt == (8, 1, 2, 2, True)
assert s12 == sorted(mask(range(0, 12, d)) for d in divs) and len(s12) == 6 and up == s12 and a24 == subs(Q1)
assert len(sD4) == 10 and [r[:2] for r in rows] == [(10, 10), (5, 5), (2, 2), (2, 2), (2, 2), (1, 1)] and all(r[2] for r in rows)
print("ALL CHECKS PASS")
