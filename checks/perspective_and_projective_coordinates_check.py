# Perspective and projective coordinates -- the check behind the card.  Nothing
# imported.  A camera, lens 1.5 m above the ground, looks level along a track
# whose rails run at X = -0.5 and 0.5 m.  Focal length 50 mm.  Three roads to the
# vanishing point: meet the rails' image lines, project their shared direction,
# and send the rails' meeting point on the ground through a ground-to-photo map.
F, H = 50.0, 1.5
P = [[F, 0, 0, 0], [0, F, 0, 0], [0, 0, 1, 0]]          # camera matrix, 3 x 4
G = [[F, 0, 0], [0, 0, -F * H], [0, 1, 0]]              # ground (x, z, w) to photo

def apply(m, v): return [sum(r[i] * v[i] for i in range(len(v))) for r in m]
def cross(a, b): return [a[1]*b[2] - a[2]*b[1], a[2]*b[0] - a[0]*b[2], a[0]*b[1] - a[1]*b[0]]
def photo(q): return [q[0] / q[2], q[1] / q[2]]           # divide by the last entry
def shot(x, z): return apply(P, [x, -H, z, 1])            # a ground point, X across, Z ahead
def pt(x, z): return photo(shot(x, z)) + [1.0]            # its image as (u, v, 1)
def line(x0, x1, z0, z1): return cross(pt(x0, z0), pt(x1, z1))
def num(x):
    s = f"{x:.6f}".rstrip("0").rstrip(".")
    return "0" if s == "-0" else s
def tri(v): return "(" + ", ".join(num(x) for x in v) + ")"
def close(a, b): return all(abs(p - q) < 1e-9 for p, q in zip(a, b))

print(f"camera: f = {num(F)} mm, lens {num(H)} m above the ground, rails at X = -0.5 and 0.5 m, sensor 36 x 24 mm")
print(f"left rail at 10 m: {tri(shot(-0.5, 10))} -> {tri(photo(shot(-0.5, 10)))}; twice as far along "
      f"its ray, {tri(apply(P, [-1, -3, 20, 1]))} -> {tri(photo(apply(P, [-1, -3, 20, 1])))}")
print(f"left rail at 20 m -> {tri(pt(-0.5, 20)[:2])}; right rail at 10 m -> "
      f"{tri(pt(0.5, 10)[:2])}, at 20 m -> {tri(pt(0.5, 20)[:2])}")
left, right = line(-0.5, -0.5, 10, 20), line(0.5, 0.5, 10, 20)
print(f"image lines: left {tri(left)}, right {tri(right)}")
road1 = cross(left, right)
print(f"road 1, meet of the image lines: {tri(road1)} -> {tri(photo(road1))}")
print(f"photo lines u = 1 and u = 2 meet at {tri(cross([1, 0, -1], [1, 0, -2]))}: at infinity")
road2 = apply(P, [0, 0, 1, 0])
print(f"road 2, camera matrix on the direction (0, 0, 1, 0): {tri(road2)} -> {tri(photo(road2))}")
ground = cross([1, 0, 0.5], [1, 0, -0.5])              # X = -0.5 and X = 0.5 on the ground
road3 = apply(G, ground)
print(f"road 3, rails meet on the ground at {tri(ground)}; ground-to-photo sends it to {tri(road3)} -> {tri(photo(road3))}")
far = [photo(shot(-0.5, z))[0] for z in (100, 1000, 1000000)]
print(f"left rail farther out, u at 100, 1000 and 1000000 m: {' '.join(num(u) for u in far)}")
branch_hom = apply(P, [1, 0, 4, 0])
branch_dir = photo(branch_hom)                          # 1 m across for every 4 m ahead
branch_meet = photo(cross(line(2.5, 4.5, 8, 16), line(3.5, 5.5, 8, 16)))
print(f"branch line, camera matrix on the direction (1, 0, 4, 0): {tri(branch_hom)} -> {tri(branch_dir)}")
print(f"branch line, meet of its two rails' image lines -> {tri(branch_meet)}")
print(f"horizon, the line through both vanishing points: {tri(cross(photo(road2) + [1], branch_dir + [1]))}")
print(f"mistake, no divide: left rail u = {num(F * -0.5)} at 10 m and at 20 m, so the rails never meet")
print(f"mistake, midpoints: the sleeper at 15 m sits at v = {num(pt(0, 15)[1])}; halfway on the photo "
      f"between 10 m and 20 m is v = {num((pt(0, 10)[1] + pt(0, 20)[1]) / 2)}")
print(f"mistake, joining (2.5, -7.5, 1) to (5, -15, 2): {tri(cross([2.5, -7.5, 1], [5, -15, 2]))}, no line")
fig = lambda q: f"({num(180 + 10 * q[0])}, {num(120 - 10 * q[1])})"
print(f"figure, 1 mm = 10 units: V {fig(photo(road1))} V' {fig(branch_dir)} rails enter 6.25 m out at {fig(pt(-0.5, 6.25))} "
      f"{fig(pt(0.5, 6.25))} branch from {fig(pt(2.0625, 6.25))} marks at 10 m {fig(pt(0.5, 10))} 20 m {fig(pt(0.5, 20))}")
assert close(photo(shot(-0.5, 10)), [F * -0.5 / 10, F * -H / 10])   # matrix = u = fX/Z, v = fY/Z
assert close(photo(road1), photo(road2)) and ground[2] == 0 and close(photo(road3), photo(road1))
assert close(branch_meet, branch_dir) and abs(branch_dir[1]) < 1e-12
assert abs(far[2]) < 1e-4 and abs(far[2]) < abs(far[1]) < abs(far[0])
print("ALL CHECKS PASS")
