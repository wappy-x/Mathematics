# Stokes on manifolds -- the check behind the card.  Standard library only.  The manifold M is a
# dome-tent panel: the upper half of a sphere, R = 1.5 m, whose edge (its hem) is the circle on the
# ground.  The valley wind is a one-form w = P dx + Q dy + S dz: a 3 m/s breeze east, plus an eddy
# turning at k = 0.4 per second at the ground and faster higher up.  Stokes: integral of dw over M
# equals integral of w round the hem.  Road A walks the hem.  Road B takes d in space, then pulls it
# back to the globe chart.  Road C pulls w back to a second chart, then takes d there.
import math
PI, R, K0, BREEZE = math.pi, 1.5, 0.4, 3.0

def simpson(f, a, b, n=64):                          # weights 1, 4, 2, ..., 4, 1 times spacing / 3
    h = (b - a) / n
    return h / 3 * sum((1 if j in (0, n) else 4 if j % 2 else 2) * f(a + j * h) for j in range(n + 1))

def wind(p):                                         # (P, Q, S): the form's dx, dy, dz parts, in m/s
    k = K0 * (1 + p[2] / R)
    return (BREEZE - k * p[1], k * p[0], 0.0)

def angle(p):                                        # the carousel's angle form d(theta), no units
    s = p[0] ** 2 + p[1] ** 2
    return (-p[1] / s, p[0] / s, 0.0)

def dot(a, b):
    return sum(x * y for x, y in zip(a, b))

def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])

def rate(f, t, h=1e-5):                              # velocity of a moving point, by difference quotient
    return [(a - b) / (2 * h) for a, b in zip(f(t + h), f(t - h))]

def d(w, p, h=1e-4):                                 # exterior derivative: the dy^dz, dz^dx, dx^dy parts
    def nudge(c, s):
        return [p[k] + s * h * (k == c) for k in range(3)]
    j = [[(w(nudge(c, 1))[i] - w(nudge(c, -1))[i]) / (2 * h) for c in range(3)] for i in range(3)]
    return (j[2][1] - j[1][2], j[0][2] - j[2][0], j[1][0] - j[0][1])

def edge(w, c, t0=0.0, t1=2 * PI, n=64):             # road A: add w along a curve
    return simpson(lambda t: dot(w(c(t)), rate(c, t)), t0, t1, n)

def circle(phi, turn=1):                             # the circle phi down from the top, anticlockwise from above
    return lambda t: (R * math.sin(phi) * math.cos(t), turn * R * math.sin(phi) * math.sin(t), R * math.cos(phi))

def globe(ph, th):                                   # chart one: angle down from the top, longitude
    return (R * math.sin(ph) * math.cos(th), R * math.sin(ph) * math.sin(th), R * math.cos(ph))

def stereo(rho, th):                                 # chart two: the floor disc, lifted from the bottom pole
    u, v, s = rho * math.cos(th), rho * math.sin(th), R * R + rho * rho
    return (2 * R * R * u / s, 2 * R * R * v / s, R * (R * R - rho * rho) / s)

def d_then_pull(w, chart, a0, a1, n=64):             # road B: d in space, pulled back by r_a x r_t
    def g(a, t):
        ra, rt = rate(lambda s: chart(s, t), a), rate(lambda s: chart(a, s), t)
        return dot(d(w, chart(a, t)), cross(ra, rt))
    return simpson(lambda a: simpson(lambda t: g(a, t), 0, 2 * PI, n), a0, a1, n)

def pull(w, chart, a, t):                            # the pulled-back form: its da and dt parts
    p = chart(a, t)
    return (dot(w(p), rate(lambda s: chart(s, t), a)), dot(w(p), rate(lambda s: chart(a, s), t)))

def pull_then_d(w, chart, a0, a1, n=96, h=1e-4):     # road C: d of the pullback, in the chart's numbers
    def g(a, t):
        db_da = (pull(w, chart, a + h, t)[1] - pull(w, chart, a - h, t)[1]) / (2 * h)
        da_dt = (pull(w, chart, a, t + h)[0] - pull(w, chart, a, t - h)[0]) / (2 * h)
        return db_da - da_dt
    return simpson(lambda a: simpson(lambda t: g(a, t), 0, 2 * PI, n), a0, a1, n)

def f(x):                                            # fixed decimals, with no minus sign on a zero
    return f"{0.0 if abs(x) < 5e-7 else x:.6f}"

def gee(ph):                                         # on the sphere, w = 3 dx + gee(phi) d(theta)
    return K0 * R ** 2 * (1 + math.cos(ph)) * math.sin(ph) ** 2

hand = 2 * PI * K0 * R ** 2
hem, A_breeze = edge(wind, circle(PI / 2)), edge(lambda p: (BREEZE, 0.0, 0.0), circle(PI / 2))
B, C = d_then_pull(wind, globe, 0, PI / 2), pull_then_d(wind, stereo, 0, R)
print(f"tent radius {R:.1f} m, R^2 {R * R:.2f} m^2; eddy speed at the hem {K0 * R:.3f} m/s; breeze {BREEZE:.1f} m/s east")
print(f"n = 1, breeze form 3 dx along the half hem, east to west: walked {f(edge(lambda p: (BREEZE, 0.0, 0.0), circle(PI / 2), 0, PI))}; "
      f"endpoints 3x(west) - 3x(east) = {f(BREEZE * (-R) - BREEZE * R)}")
print(f"road A, w round the hem: {f(hem)} m^2/s; the breeze's share {f(A_breeze)}")
print(f"road B, d then pull back, globe chart: {f(B)}")
print(f"road C, pull back then d, floor-disc chart: {f(C)}")
print(f"by hand, 2 pi k R^2 = {f(hand)}")
for deg in (30, 60, 90):
    ph = deg * PI / 180
    print(f"cap down to {deg:2d} deg: dw inside {f(d_then_pull(wind, globe, 0, ph))}; w round its edge "
          f"{f(edge(wind, circle(ph)))}; 2 pi gee {f(2 * PI * gee(ph))}; gee {f(gee(ph))}; "
          f"1 + cos {f(1 + math.cos(ph))}; sin^2 {f(math.sin(ph) ** 2)}")
for top in ((0.0, 0.0, R), (R, 0.0, 0.0)):
    print(f"dw at ({top[0]:.1f}, {top[1]:.1f}, {top[2]:.1f}): dy^dz, dz^dx, dx^dy = " + ", ".join(f(c) for c in d(wind, top)))
for n in (4, 8):
    print(f"road B with {n} Simpson strips a side: {f(d_then_pull(wind, globe, 0, PI / 2, n))}, "
          f"error {abs(d_then_pull(wind, globe, 0, PI / 2, n) - hand):.6f}")
rev = edge(wind, circle(PI / 2, -1))
vent_in, vent_edge = d_then_pull(wind, globe, PI / 6, PI / 2), edge(wind, circle(PI / 6, -1))
print(f"break 1, hem walked clockwise from above: {f(rev)} against {f(B)}")
print(f"break 2, vent cut down to 30 deg: dw inside {f(vent_in)}; hem alone {f(hem)}; "
      f"vent edge walked clockwise {f(vent_edge)}; both edges {f(hem + vent_edge)}")
ang_in = d_then_pull(angle, globe, PI / 180, PI / 2)
print(f"break 3, angle form: d at (1, 0.5, 0.8) " + ", ".join(f(c) for c in d(angle, (1, .5, .8)))
      + f"; dw inside, pole cut out {f(ang_in)}; hem {f(edge(angle, circle(PI / 2)))}; "
      f"circle 1 deg from the pole {f(edge(angle, circle(PI / 180)))}")
E, S, CX, CY = 25 * PI / 180, 120, 240, 230          # view 25 deg above the horizon, 120 px per m
scr = lambda p: (CX + S * p[0], CY - S * (p[1] * math.sin(E) + p[2] * math.cos(E)))
base, tip = scr(globe(PI / 4, 0)), scr([c * (R + 0.5) / R for c in globe(PI / 4, 0)])   # 0.5 m normal
hide = math.asin(math.tan(E) / math.tan(PI / 6))     # the vent circle is behind the top from hide to 180 deg - hide
v1, v2 = scr(circle(PI / 6)(hide)), scr(circle(PI / 6)(PI - hide))
print(f"figure, 120 px per m: hem ry {S * R * math.sin(E):.1f}; vent cy {scr((0, 0, R * math.cos(PI / 6)))[1]:.1f} "
      f"rx {S * R * math.sin(PI / 6):.1f} ry {S * R * math.sin(PI / 6) * math.sin(E):.1f}; "
      f"normal {base[0]:.1f},{base[1]:.1f} to {tip[0]:.1f},{tip[1]:.1f}; vent hidden {math.degrees(hide):.1f} "
      f"to {180 - math.degrees(hide):.1f} deg, {v1[0]:.1f},{v1[1]:.1f} to {v2[0]:.1f},{v2[1]:.1f}")
assert abs(hem - B) < 1e-6 and abs(hem - C) < 1e-6           # three roads, one number
assert abs(B - hand) < 1e-6 and abs(A_breeze) < 1e-9          # the hand count; an exact form round a closed loop
assert abs(vent_in - (hem + vent_edge)) < 1e-6 and abs(vent_in - (hand - 2 * PI * gee(PI / 6))) < 1e-6
assert rev < 0 and abs(ang_in) < 1e-6 and abs(edge(angle, circle(PI / 2)) - 2 * PI) < 1e-9
print("ALL CHECKS PASS")
