# Gram-Schmidt -- the check behind the card.  Nothing is imported.  Two survey
# lines on a building site, (3, 1) and (2, 2), are straightened into
# perpendicular unit directions, and a stake at (4, 2) is then read off by dot
# products.  A second case adds a mast, (1, 1, 1), to make a third direction.
def dot(u, v): return sum(a * b for a, b in zip(u, v))
def length(u): return dot(u, u) ** 0.5
def scale(k, u): return tuple(k * a for a in u)
def minus(u, v): return tuple(a - b for a, b in zip(u, v))
def plus(u, v): return tuple(a + b for a, b in zip(u, v))
def gram_schmidt(vs):                        # peel off shadows, then scale to 1
    qs = []
    for v in vs:
        for q in qs:
            v = minus(v, scale(dot(v, q), q))
        qs.append(scale(1.0 / length(v), v))
    return qs

def num(x): return f"{0.0 if abs(x) < 5e-7 else x:.6f}"   # no -0.000000
def vec(u): return "(" + ", ".join(num(x) for x in u) + ")"
def row(name, *cells): print(f"{name:<44}" + "  ".join(cells))

a1, a2, b = (3.0, 1.0), (2.0, 2.0), (4.0, 2.0)
q1, q2 = gram_schmidt([a1, a2])
shadow = scale(dot(a2, q1), q1)
left = minus(a2, shadow)
c1, c2 = dot(b, q1), dot(b, q2)              # one road: coordinates are dots
rebuilt = plus(scale(c1, q1), scale(c2, q2))
det = q1[0] * q2[1] - q2[0] * q1[1]          # second road: solve for the two
e1 = (b[0] * q2[1] - q2[0] * b[1]) / det     # coordinates by elimination, with
e2 = (q1[0] * b[1] - b[0] * q1[1]) / det     # no dot product anywhere in it
skew = a1[0] * a2[1] - a2[0] * a1[1]         # the same solve on the raw lines
s1, s2 = (b[0] * a2[1] - a2[0] * b[1]) / skew, (a1[0] * b[1] - b[0] * a1[1]) / skew
row("survey lines (3, 1), (2, 2), lengths", num(length(a1)), num(length(a2)))
row("q1 = first line / its length", vec(q1))
row("a2 . q1, and the shadow it casts", num(dot(a2, q1)), vec(shadow))
row("leftover a2 - shadow, and its length", vec(left), num(length(left)))
row("q2 = leftover / length, (-1, 3)/3.162278", vec(q2))
row("q1 . q1, q2 . q2, q1 . q2", num(dot(q1, q1)), num(dot(q2, q2)), num(dot(q1, q2)))
row("stake b = (4, 2), coordinates by dots", num(c1), num(c2))
row("the same two by elimination", num(e1), num(e2))
row("b rebuilt from its coordinates", vec(rebuilt))
row("b . b, and c1^2 + c2^2", num(dot(b, b)), num(c1 * c1 + c2 * c2))
row("b on the raw skewed lines, solved", num(s1), num(s2))
row("Q^T Q rows, and det Q", vec((dot(q1, q1), dot(q1, q2))),
    vec((dot(q2, q1), dot(q2, q2))), num(det))
row("quarter turn (0, 1) and (-1, 0), det", num(0.0 * 0.0 - (-1.0) * 1.0))
row("flip (1, 0) and (0, -1), det", num(1.0 * -1.0 - 0.0 * 0.0))
row("mistake: no divide by a1 . a1", vec(minus(a2, scale(dot(a2, a1), a1))))
row("mistake: leftover never scaled",
    vec(plus(scale(dot(b, a1), a1), scale(dot(b, left), left))))
row("mistake: a2 = (6, 2), leftover", vec(minus((6.0, 2.0), scale(dot((6.0, 2.0), q1), q1))))
m = gram_schmidt([(3.0, 1.0, 0.0), (2.0, 2.0, 0.0), (1.0, 1.0, 1.0)])
row("mast (1, 1, 1) added, q3", vec(m[2]))
row("mast Q^T Q, largest off-diagonal",
    num(max(abs(dot(m[i], m[j])) for i in range(3) for j in range(3) if i != j)))
assert abs(dot(q1, q1) - 1) < 1e-12 and abs(dot(q2, q2) - 1) < 1e-12 and abs(dot(q1, q2)) < 1e-12
assert abs(c1 - 14 / 10 ** 0.5) < 1e-12 and abs(c2 - 2 / 10 ** 0.5) < 1e-12
assert abs(e1 - c1) < 1e-12 and abs(e2 - c2) < 1e-12 and abs(rebuilt[0] - 4) < 1e-12 and abs(rebuilt[1] - 2) < 1e-12
assert abs(dot(b, b) - 20) < 1e-12 and abs(c1 * c1 + c2 * c2 - 20) < 1e-12 and abs(m[2][2] - 1) < 1e-12
print("ALL CHECKS PASS")
