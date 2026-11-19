# Gauss-Bonnet: total curvature counts the holes

[Syllabus](../../../SYLLABUS.md) → [Differential geometry and Lie groups](../README.md) → [Surfaces](../README.md#s02) → Gauss-Bonnet

---

## General Overview

A match football is sewn from 32 panels: 12 pentagons and 20 hexagons. Pumped up, it is close to a sphere of radius 11 cm. Every point of it is curved the same amount. The **Gaussian curvature** $`K`$ (the product of the two principal curvatures, the most and the least bending at a point, in 1/m²) is $`1/(0.11 \text{ m})^2`$ = 82.644628 1/m² everywhere.

Multiply curvature by area and add it up panel by panel. One pentagon panel, 35.703744 cm², holds 0.295072 rad (16.906395°) of curvature. One hexagon panel, 54.604296 cm², holds 0.451275 rad (25.856163°). The 12 pentagons hold 202.876744° and the 20 hexagons 517.123256°. The ball's total is **720°**, which is $`4\pi`$ = 12.566371 rad.

That total does not depend on the ball. A rugby ball is sharply curved at its tips and gently curved at its waist, yet its total is also 720°. A bicycle inner tube, the same size as a wheel, has a total of 0°. The total depends only on how many holes the surface has.

**Add up Gaussian curvature over a closed surface and the answer is always $`2\pi`$ times its Euler characteristic, the whole number vertices minus edges plus faces of any cutting into polygons: 720° for every ball, 0° for every inner tube, whatever the size and shape.**

**What kind of fact this is:** a theorem, proved on this card in Why it works. The local form (one patch with its edges) is proved in a fold. The global form follows by cutting the surface into patches. Four results are stated with a source, not proved here: the existence of a chart with square grid lines around every point, Liouville's formula for $`\kappa_g`$, the turning-tangent theorem, and the fact that every closed surface can be cut into triangles. The result is global: it needs the whole surface, closed and without a rim.

### The picture: where the 720° sits

```
football, 12 pentagons        ##########                            202.876744°
football, 20 hexagons         ##########################            517.123256°
flat-panel ball, 60 corners   ####################################  720°
inner tube, outer half        ####################################  720.000000°
inner tube, inner half        ------------------------------------  -720.000000°
```

Each `#` is 20° of curvature; each `-` is 20° of negative curvature. The first two bars add to 720°. A ball sewn from flat, unstretched panels has the same 720°, all packed into its 60 corners. On the inner tube the outer half curves like a ball, the inner half like a saddle, and the two cancel.

---

## The formula

Notation first, in words.

- $`K`$ is the **Gaussian curvature** at a point ([Principal, mean and Gaussian curvature](05-principal-mean-and-gaussian-curvature.md)): positive on a dome, negative on a saddle, in 1/m². In wing 05, $`K`$ is also a triangle's area; here it means only curvature.
- $`dA`$ is a small piece of area. In a chart $`r(u, v)`$ it is $`\sqrt{EG - F^2}\, du\, dv`$ ([Surface area](03-surface-area-from-the-first-fundamental-form.md)).
- $`\chi`$ ("chi") is the **Euler characteristic** ([Euler characteristic](../../17-Topology/03-Surfaces%20and%20Manifolds/04-euler-characteristic-and-triangulations.md)): cut the surface into polygons and count vertices $`V`$ minus edges $`E`$ plus faces $`F`$. In this one formula $`E`$ and $`F`$ count edges and faces, not the first fundamental form.
- $`g`$ is the **genus**, the number of holes, as in [Closed surfaces classified](../../17-Topology/03-Surfaces%20and%20Manifolds/02-surfaces-and-the-classification-theorem.md). For a two-sided closed surface, $`\chi = 2 - 2g`$. Elsewhere $`g`$ is gravity; here it counts holes.

The global theorem, for a closed surface:

```math
\iint_S K\, dA = 2\pi\,\chi(S) = 4\pi\,(1 - g)
```

**Read it aloud:** "Curvature times area, added over the whole closed surface, is two pi times its Euler characteristic, which is four pi times one minus the number of holes."

The local theorem, for one patch $`P`$ shaped like a disc, with an edge made of smooth pieces:

```math
\iint_P K\, dA + \int_{\partial P} \kappa_g\, ds + \sum_i \theta_i = 2\pi
```

**Read it aloud:** "The curvature inside the patch, plus the bending of its edge, plus the turns at its corners, is one full turn."

Here $`\partial P`$ is the patch's edge, walked once with the patch on the left. $`\kappa_g`$ is the edge's **geodesic curvature** ([Geodesic on a surface](09-geodesics-on-surfaces.md)): how fast it bends left within the surface, in 1/m; it is zero along a geodesic, the straightest path on the surface. $`s`$ is arc length along the edge, and $`\theta_i`$ is the turn made at corner $`i`$: 180° minus the inside angle there.

On a flat sheet $`K = 0`$, and the formula says a walk round any loop turns once, 360° ([Turning and winding numbers](../01-Curves/08-turning-number-and-winding-number.md)). On a curved surface, the curvature inside makes up part of the turn.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $`K`$ | Gaussian curvature, 1/m² | 82.644628 on the ball; 258.131844 at a rugby ball's tip | the total stays put; the area shrinks to match |
| $`dA`$ | a small piece of area | the ball's 0.152053 m² in all | the total stays put; $`K`$ shrinks to match |
| $`\chi`$ | Euler characteristic, $`V - E + F`$ | 60 − 90 + 32 = 2 on the ball | total up by $`2\pi`$ per unit |
| $`V`$, $`E`$, $`F`$ | vertices, edges, faces of a cutting | 60, 90, 32 on the ball | $`\chi`$ itself never moves |
| $`P`$, $`\partial P`$ | a disc-shaped patch; its edge, walked with $`P`$ on the left | the half dome; its rim and cut | — |
| $`g`$ | genus: number of holes | 0 for a ball, 1 for the inner tube | total down by $`4\pi`$ per hole |
| $`\kappa_g`$ | geodesic curvature of the edge, 1/m | 0.022222 on the half dome's rim; 0 on a seam | less curvature needed inside |
| $`s`$ | arc length along the edge, m | 113.097336 m of rim | — |
| $`\theta_i`$ | turn at a corner of the edge | 90° at each corner of the half dome | less curvature needed inside |
| $`\alpha`$, $`n`$ | inside angle at a panel corner; sides of the panel | 111.381279° and 5 on a pentagon | more excess, more curvature |
| $`R`$, $`\varphi_0`$ | radius of a sphere; the rim's angle down from the top | 0.11 m ball; 60 m dome with $`\varphi_0`$ = 36.869898° | $`K = 1/R^2`$ falls, total stays |
| $`H`$ | mean curvature, 1/m (half the sum of the principal curvatures) | 9.090909 on the ball | its total grows with size |

### When it holds

- **Closed: no rim.** A patch with an edge obeys the local theorem instead. The half dome alone holds only 36° of curvature; its edge carries the other 324°.
- **Smooth, or corners counted.** On a ball sewn from flat panels $`K = 0`$ on every panel, so the smooth integral gives 0. The 720° sits in the 60 corners as point curvature, 12° each.
- **Edge bending counted.** The angle-sum form $`\iint K\,dA = \sum \alpha - (n-2)\pi`$ needs geodesic edges. On the half dome, whose rim bends, dropping the $`\kappa_g`$ term from the local theorem gives 216° instead of 360°.
- **Signed curvature.** Saddle points count as negative. Adding $`\lvert K\rvert`$ on the inner tube gives 25.132741 rad ($`8\pi`$), not 0.
- **Gaussian curvature, not mean curvature.** The mean curvature $`H`$ is half the sum of the principal curvatures, in 1/m. Its total over a ball is $`4\pi R`$, which grows with size. Only $`K`$ gives a total fixed by shape.

---

## Why it works

### Step 0: curvature is the turn a walker cannot explain

Walk round a loop on a flat floor and come back facing the way you started. Your heading has turned exactly 360°. The turn came from bending your path and from turning at corners.

On a curved surface, walk round a loop and add up the same turns. They come to less than 360° on a dome and more on a saddle. The shortfall is the curvature inside the loop. That is the local theorem. The global theorem adds the local one over pieces that cover a closed surface. The edges cancel and only a count of pieces is left.

### Step 1: a panel with straight seams

Each seam on the pumped-up football runs along a great circle (a circle round the ball's centre), so it is a geodesic and $`\kappa_g = 0`$. The local theorem keeps only the corner turns. A pentagon has 5 corners, each turning $`\pi - \alpha`$:

```math
\iint_{\text{pentagon}} K\, dA = 2\pi - 5(\pi - \alpha) = 5\alpha - 3\pi
```

The pumped-up pentagon's corner is 111.381279°, so the curvature is 5 × 111.381279° − 540° = 16.906395°. That is the corner angles' **excess** over a flat pentagon's 540°. For a sphere this is Girard's theorem, proved by lunes in [Triangles on a sphere](../../05-Geometry%20and%20trig/06-Beyond%20Euclid/01-triangles-on-a-sphere.md): excess times $`R^2`$ is area. The local theorem says the same for any surface and any $`K`$.

### Step 2: a patch with a bending edge

The half dome over the east end of the stadium roof is part of a sphere of radius $`R`$ = 60 m with a rise of 12 m. Its round rim has radius 36 m; its straight edge is the cut over the top. This is the roof from [Surface area](03-surface-area-from-the-first-fundamental-form.md).

- **Inside:** $`K = 1/60^2`$ = 0.000277778 1/m², added over the half dome: 0.628319 rad, 36°.
- **The rim:** a circle of latitude, not a great circle. It bends toward the top with $`\kappa_g = \cot\varphi_0 / R`$ = 0.022222 1/m ($`\varphi_0`$ is the rim's angle down from the top). Over 113.097336 m it bends 2.513274 rad, 144°.
- **The cut:** a great circle, so $`\kappa_g = 0`$ over its 77.220133 m.
- **The two corners:** rim and cut meet square, so each corner turns 90°.

Total: 36° + 144° + 0° + 90° + 90° = 360°.

The proof of the local theorem has three moves. Choose a chart whose grid lines cross square. Write $`\kappa_g`$ as the turn of the edge against the grid, plus the turn of the grid itself. Green's theorem then turns the grid's total turn round the edge into the curvature inside.

<details>
<summary>Detailed proof: the local theorem, from Green's theorem</summary>

Take a chart $`r(u, v)`$ on the patch with $`F = 0`$, so the grid lines cross square. Such a chart exists around every point (do Carmo, section 3-4), so a small enough patch fits inside one. Let $`e_1 = r_u/\sqrt{E}`$ and $`e_2 = r_v/\sqrt{G}`$ be the unit arrows along the grid. Walk the edge at unit speed with tangent $`T`$, and let $`\beta`$ be the angle from $`e_1`$ to $`T`$ (not $`\varphi`$, which is the angle down from the top).

The edge bends partly because $`\beta`$ changes and partly because the grid arrows themselves turn along the way. Liouville's formula gives the split (do Carmo, chapter 4):

$`\displaystyle \kappa_g = \frac{d\beta}{ds} + \frac{1}{2\sqrt{EG}}\Big(G_u \frac{dv}{ds} - E_v \frac{du}{ds}\Big).`$

Integrate round the edge. Green's theorem, $`\oint P\,du + Q\,dv = \iint (Q_u - P_v)\,du\,dv`$, applies to the second part with $`P = -E_v/(2\sqrt{EG})`$ and $`Q = G_u/(2\sqrt{EG})`$:

$`\displaystyle \oint \frac{G_u\,dv - E_v\,du}{2\sqrt{EG}} = \iint \Big[\Big(\frac{G_u}{2\sqrt{EG}}\Big)_u + \Big(\frac{E_v}{2\sqrt{EG}}\Big)_v\Big] du\,dv = -\iint K\sqrt{EG}\;du\,dv.`$

The last equality is Gauss's formula for $`K`$ in a square grid, from [Theorema Egregium](08-theorema-egregium.md). The right side is $`-\iint K\,dA`$.

The tangent of a simple closed edge turns once in all, counting the jumps $`\theta_i`$ at the corners. This is Hopf's turning-tangent theorem (do Carmo, chapter 4), the surface form of [Turning and winding numbers](../01-Curves/08-turning-number-and-winding-number.md):

$`\displaystyle \oint \frac{d\beta}{ds}\,ds + \sum_i \theta_i = 2\pi.`$

Put the two together: $`\oint \kappa_g\,ds = 2\pi - \sum_i \theta_i - \iint K\,dA`$, which rearranges to the local theorem.

</details>

### Step 3: add the panels, and the edges cancel

Cut a closed surface into polygons, each small enough to be a patch. Walk every polygon's edge with it on the left. Then apply the local theorem to each polygon and add.

- **Edges cancel.** Each edge is walked twice, once in each direction. Reversing the walk flips the sign of $`\kappa_g`$, so the edge integrals cancel in pairs.
- **Corners add up.** A polygon with $`n`$ corners turns $`\sum(\pi - \alpha) = n\pi - \sum \alpha`$. The sides of all polygons number $`2E`$, so all polygons together turn $`2\pi E - \sum \alpha`$.
- **Angles round a vertex make a full turn.** The inside angles meeting at one vertex fill it, so $`\sum \alpha = 2\pi V`$.

Adding up:

```math
\iint_S K\,dA = 2\pi F - (2\pi E - 2\pi V) = 2\pi (V - E + F) = 2\pi\chi
```

On the football: $`2\pi \times 32 - \pi \times 180 + 2\pi \times 60`$ = 12.566371 rad, 720°. The 180 is the panels' sides, $`2E`$.

The cut into polygons was arbitrary, and the left side does not mention it. So every cutting gives the same $`V - E + F`$: a second proof of what [Euler characteristic](../../17-Topology/03-Surfaces%20and%20Manifolds/04-euler-characteristic-and-triangulations.md) proves by counting.

### Step 4: a corner gap is curvature packed into a point

[Polyhedra](../../05-Geometry%20and%20trig/02-Circles%20and%20Solids/06-polyhedra-and-eulers-formula.md) already showed that a football sewn from flat panels has a 12° gap at each of its 60 corners, 720° in all, which is Euler's count in degrees. This card names that gap: the **angle defect** at a corner is 360° minus the angles that meet there.

A flat panel has $`K = 0`$, and a seam between two flat panels can be unfolded flat. So all the curvature sits at the corners, and the defect is the curvature packed into each one. Round off a corner and the same 12° spreads over a small cap. Pump up the ball and it spreads over every panel: the pentagons keep 202.876744°, the hexagons take 517.123256°.

The same works on any smooth surface. Pin a mesh of flat triangles to a rugby ball and add the defects near a tip. They approach the smooth integral as the mesh refines (Worked numbers).

### Step 5: why the count is the holes

By the classification of surfaces, a two-sided closed surface is a sphere with $`g`$ handles, and $`\chi = 2 - 2g`$. So the total is $`4\pi(1 - g)`$.

The inner tube shows how a hole cancels the curvature. Its outer half curves like a ball: $`K`$ = 101.010101 1/m² at the outer equator. Its inner half curves like a saddle: $`K`$ = −123.456790 1/m² at the inner equator. Along the top and bottom circles $`K = 0`$. The outer half holds +720°, the inner half −720°, and the total is 0.

A surface with two holes has $`\chi = -2`$ and a total of −720°: it must be saddle-shaped on balance. No amount of reshaping can change that.

---

## Worked numbers, by hand

**One pentagon panel, then the whole ball.** The ball has radius 0.11 m. The pumped-up pentagon's corner angle comes from the code (it is where three seams meet on the sphere).

| Step | Arithmetic | Value |
| --- | --- | --- |
| curvature | $`K = 1/0.11^2`$ | 82.644628 1/m² |
| pentagon excess | 5 × 111.381279° − 540° | 16.906395° = 0.295072 rad |
| pentagon area | 0.295072 ÷ 82.644628, in cm² | 35.703744 cm² |
| hexagon excess | 6 × 124.309360° − 720° | 25.856163° = 0.451275 rad |
| one corner closes | 111.381279° + 2 × 124.309360° | 360° |
| the whole ball | 12 × 16.906395° + 20 × 25.856163° | 202.876744° + 517.123256° = **720°** |
| the count | $`2\pi(60 - 90 + 32)`$ | 12.566371 rad = **720°** |

The 32 panels hold 12.566371 rad of curvature, exactly $`2\pi`$ times the ball's count of 2.

**The rugby ball.** Model it as a stretched sphere (an ellipsoid of revolution) with half-width 0.095 m and half-length 0.145 m. Its curvature is 258.131844 1/m² at each tip but only 47.562426 1/m² round the waist. The total, added in a chart by the code, is still 12.566371 rad. Each tip cap, out to the ring 0.102530 m along the axis from the centre, holds 162.710547°.

**The rugby ball as a mesh.** Pin flat triangles to it and add up the angle defects.

| Mesh | Corners, triangles | All defects | Tip cap | Error against 2.839835 rad |
| --- | --- | --- | --- | --- |
| 16 rings | 482, 960 | 12.566371 rad | 2.839164 rad | −0.000670 |
| 32 rings | 1986, 3968 | 12.566371 rad | 2.839656 rad | −0.000178 |

The defects always total exactly $`2\pi \times 2`$, whatever the mesh. Near the tip they are an approximation to the smooth curvature, and halving the step cuts the error by 3.758447, close to 4.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Half dome without the edge term | 3.769911 rad = 216°, not 360° | The rim is not a geodesic; its 144° of bending is missing |
| Flat panels, smooth curvature only | 0 rad, not 12.566371 | All the curvature sits in the corners; the 12° defects carry it |
| Flat 108° and 120° corners on pumped-up panels | 0 rad | Flat angles have no excess; on the ball they are 111.381279° and 124.309360° |
| $`\lvert K\rvert`$ on the inner tube | 25.132741 rad = $`8\pi`$, not 0 | Saddle curvature is negative; dropping its sign hides the hole |
| Mean curvature in place of $`K`$ | 1.382301 m on the football, 80,060.347184 km on the Earth | $`H`$ is in 1/m, so its total grows with size |

The code prints all five.

---

## Code, from first principles, and it actually runs

The code adds up curvature on four surfaces and gets each total by at least two **independent roads**. On the football: $`K\sqrt{EG - F^2}`$ added over each panel in a chart, against the corner-angle excess, against the flat ball's 60 corner defects, against the count $`V - E + F`$. On the half dome: the curvature inside, the rim's $`\kappa_g`$ found from the curve's own derivatives, and the corner turns, against $`2\pi`$. On the rugby ball and the inner tube: $`K`$ from the two fundamental forms, added in a chart, against the angle defects of a flat-triangle mesh. The mesh is approximate: its tip-cap error is printed at two step sizes.

### Python

```python
# Gauss-Bonnet -- the check behind the card.  Standard library only.
# A football, a stadium's half dome, a rugby ball and an inner tube: total curvature
# in a chart, against corner angles, mesh angle defects and the count V - E + F.
import math
PI, TAU = math.pi, 2 * math.pi
def dot(a, b): return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
def cross(a, b): return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])
def sub(a, b): return (a[0] - b[0], a[1] - b[1], a[2] - b[2])
def scale(a, k): return (a[0] * k, a[1] * k, a[2] * k)
def unit(a): return scale(a, 1 / math.sqrt(dot(a, a)))
def ang(a, b): return math.acos(max(-1.0, min(1.0, dot(unit(a), unit(b)))))
def simpson(f, a, b, n):
    h = (b - a) / n
    return h / 3 * sum((1 if i in (0, n) else 4 if i % 2 else 2) * f(a + i * h) for i in range(n + 1))
def f6(x): return f"{(0.0 if abs(x) < 5e-7 else x):.6f}"
def deg(x): return f6(math.degrees(x))
def KdA(pr, t):                              # surface of revolution, profile (rho, z) and derivatives in t
    r, z, r1, z1, r2, z2 = pr(t)             # chart (t, theta), worked at theta = 0
    rt, rq, rtt, rtq, rqq = (r1, 0, z1), (0, r, 0), (r2, 0, z2), (0, r1, 0), (-r, 0, 0)
    n = cross(rt, rq); s = math.sqrt(dot(n, n))
    if s == 0: return 0.0, 0.0               # a pole of the chart: no area
    n = scale(n, 1 / s)
    E, F, G, L, M, N = dot(rt, rt), dot(rt, rq), dot(rq, rq), dot(rtt, n), dot(rtq, n), dot(rqq, n)
    return (L * N - M * M) / (E * G - F * F), s          # K = (LN - M^2)/(EG - F^2), and sqrt(EG - F^2)
def total(pr, a, b, turn=TAU): return turn * simpson(lambda t: KdA(pr, t)[0] * KdA(pr, t)[1], a, b, 400)

# 1. The football: a truncated icosahedron (edge 1) pumped onto a sphere of radius RB.
RB = 0.11                                    # m: a size-5 ball, circumference 69.12 cm
RC = math.sqrt(1 + 9 * ((1 + math.sqrt(5)) / 2) ** 2) / 2   # corner (0, 1, 3 phi)/2, phi the golden ratio
def face(n):                                 # flat n-sided face: circumradius, apothem, distance from centre
    c = 1 / (2 * math.sin(PI / n))
    return c, c * math.cos(PI / n), math.sqrt(RC * RC - c * c)
def panel_curv(n):                           # chart: flat face point x -> ball point RB x/|x|; add K dA
    c, h, d = face(n)
    def strip(psi):
        def f(s):
            x, xs, xp = (s * h, s * h * math.tan(psi), d), (h, h * math.tan(psi), 0), (0, s * h / math.cos(psi) ** 2, 0)
            L = math.sqrt(dot(x, x))
            ps = scale(sub(scale(xs, L * L), scale(x, dot(x, xs))), RB / L ** 3)
            pp = scale(sub(scale(xp, L * L), scale(x, dot(x, xp))), RB / L ** 3)
            return math.sqrt(dot(cross(ps, pp), cross(ps, pp))) / RB ** 2     # K times sqrt(EG - F^2)
        return simpson(f, 0.0, 1.0, 120)
    return 2 * n * simpson(strip, 0.0, PI / n, 120)
def panel_angle(n):                          # corner angle between two seams, which are great-circle arcs
    c, h, d = face(n)
    p = [unit((c * math.cos(TAU * k / n), c * math.sin(TAU * k / n), d)) for k in (-1, 0, 1)]
    t = lambda w: sub(w, scale(p[1], dot(w, p[1])))      # tangent at p[1] toward w
    return ang(t(p[0]), t(p[2]))
print("ball radius m", f6(RB), "K 1/m^2", f6(K := 1 / RB ** 2), "area m^2", f6(4 * PI * RB * RB), "K x area", f6(K * 4 * PI * RB * RB), "H 1/m", f6(1 / RB))
tot = 0.0
for n, cnt, name in ((5, 12, "pentagon"), (6, 20, "hexagon")):
    a, ci = panel_angle(n), panel_curv(n)
    ex = n * a - (n - 2) * PI
    print(name, "corner deg", deg(a), "excess rad", f6(ex), "deg", deg(ex), "chart integral rad", f6(ci),
          "area cm^2", f6(ci / K * 1e4), "all", cnt, "deg", deg(cnt * ci))
    assert abs(ex - ci) < 1e-8
    tot += cnt * ci
aP, aH = panel_angle(5), panel_angle(6)
print("corner sum deg", deg(aP + 2 * aH))
assert abs(aP + 2 * aH - TAU) < 1e-12
V, E, F = 60, 90, 32
print("32 panels rad", f6(tot), "deg", deg(tot), "V-E+F", V - E + F, "2 pi chi", f6(TAU * (V - E + F)))
print("panels summed: 2 pi F - pi (sides 180) + 2 pi V", f6(TAU * F - PI * (5 * 12 + 6 * 20) + TAU * V))
print("flat-panel ball: defect deg", 360 - 108 - 240, "x 60 corners", 60 * 12, "rad", f6(60 * math.radians(12)), "flat sheet K dA", f6(total(lambda t: (t, 0, 1, 0, 0, 0), 0, 1)))
assert abs(tot - TAU * (V - E + F)) < 1e-8 and abs(60 * math.radians(12) - tot) < 1e-8

# 2. The half dome: sphere radius 60 m, rise 12 m, cut along a great circle through its top.
def half_dome(R, H):
    p0 = math.acos((R - H) / R); b, z0 = R * math.sin(p0), R * math.cos(p0)
    sph = lambda p: (R * math.sin(p), R * math.cos(p), R * math.cos(p), -R * math.sin(p), -R * math.sin(p), -R * math.cos(p))
    kdA = total(sph, 0.0, p0, PI)            # theta over half a turn
    kg_rim = dot((-b, 0.0, 0.0), cross(unit((b, 0.0, z0)), (0.0, b, 0.0))) / b ** 3   # g'' . (n x g') / |g'|^3
    m0, m1, m2 = (R * math.sin(0.3), 0.0, R * math.cos(0.3)), (R * math.cos(0.3), 0.0, -R * math.sin(0.3)), (-R * math.sin(0.3), 0.0, -R * math.cos(0.3))
    kg_mer = dot(m2, cross(unit(m0), m1)) / R ** 3
    corner = ang((z0, 0.0, -b), (0.0, 1.0, 0.0))         # arrive down the cut, leave along the rim
    return p0, b, kdA, kg_rim, kg_rim * PI * b, kg_mer, corner
p0, b, kdA, kgr, rim, kgm, corner = half_dome(R := 60.0, 12.0)
print("half dome: R m", f6(R), "rise m", f6(12.0), "rim radius m", f6(b), "K 1/m^2", f"{1 / R ** 2:.9f}", "integral K dA rad", f6(kdA), "deg", deg(kdA))
print("rim: phi0 deg", deg(p0), "k_g 1/m", f6(kgr), "cot(phi0)/R", f6(1 / (R * math.tan(p0))), "length m", f6(PI * b), "integral k_g ds rad", f6(rim), "deg", deg(rim))
print("cut: k_g", f6(kgm), "length m", f6(2 * R * p0), "turn at each corner deg", deg(corner))
print("total rad", f6(kdA + rim + 2 * corner), "deg", deg(kdA + rim + 2 * corner))
assert abs(kdA + rim + 2 * corner - TAU) < 1e-9
assert abs(kgr - 1 / (R * math.tan(p0))) < 1e-12 and abs(kgm) < 1e-12

# 3. A rugby ball and an inner tube, K from the two fundamental forms.
A, C = 0.095, 0.145                          # rugby ball: half-width, half-length (m)
rug = lambda t: (A * math.sin(t), C * math.cos(t), A * math.cos(t), -C * math.sin(t), -A * math.sin(t), -C * math.cos(t))
TA, TB = 0.30, 0.03                          # inner tube: centre circle and tube radius (m)
tube = lambda v: (TA + TB * math.cos(v), TB * math.sin(v), -TB * math.sin(v), TB * math.cos(v), -TB * math.cos(v), -TB * math.sin(v))
print("rugby ball: half-width m", f6(A), "half-length m", f6(C), "K tip", f6(KdA(rug, 1e-6)[0]), "C^2/A^4", f6(C * C / A ** 4), "K waist", f6(KdA(rug, PI / 2)[0]), "1/C^2", f6(1 / C ** 2))
rt, rc = total(rug, 0, PI), total(rug, 0, PI / 4)
print("rugby ball total rad", f6(rt), "tip cap to ring z", f6(C * math.cos(PI / 4)), "rad", f6(rc), "deg", deg(rc))
print("inner tube: centre circle m", f6(TA), "tube radius m", f6(TB), "K outer", f6(KdA(tube, 0)[0]), "K inner", f6(KdA(tube, PI)[0]), "K top", f6(KdA(tube, PI / 2)[0]))
to, ti = total(tube, -PI / 2, PI / 2), total(tube, PI / 2, 3 * PI / 2)
print("inner tube outer half deg", deg(to), "inner half", deg(ti), "total rad", f6(to + ti), "with |K|", f6(to - ti))
assert abs(rt - 2 * TAU) < 1e-8 and abs(to - 2 * TAU) < 1e-8 and abs(to + ti) < 1e-8

# 4. Meshes of flat triangles pinned to the surface: all curvature sits in the corners as angle defects.
def defects(pts, tris):
    d = [TAU] * len(pts)
    for t in tris:
        for k in range(3):
            o, p, q = pts[t[k]], pts[t[(k + 1) % 3]], pts[t[(k + 2) % 3]]
            d[t[k]] -= ang(sub(p, o), sub(q, o))
    edges = {tuple(sorted((t[k], t[(k + 1) % 3]))) for t in tris for k in range(3)}
    return d, len(pts) - len(edges) + len(tris)
def rugby_mesh(m):                           # m rings from tip to tip, 2m corners round each ring
    w = 2 * m
    P = [(0, 0, C)] + [(A * math.sin(j * PI / m) * math.cos(TAU * k / w), A * math.sin(j * PI / m) * math.sin(TAU * k / w),
                        C * math.cos(j * PI / m)) for j in range(1, m) for k in range(w)] + [(0, 0, -C)]
    ix = lambda j, k: 1 + (j - 1) * w + k % w
    T = [(0, ix(1, k), ix(1, k + 1)) for k in range(w)] + [(len(P) - 1, ix(m - 1, k + 1), ix(m - 1, k)) for k in range(w)]
    T += [t for j in range(1, m - 1) for k in range(w) for t in ((ix(j, k), ix(j + 1, k), ix(j + 1, k + 1)), (ix(j, k), ix(j + 1, k + 1), ix(j, k + 1)))]
    d, chi = defects(P, T)
    cap = d[0] + sum(d[ix(j, k)] for j in range(1, m // 4) for k in range(w)) + sum(d[ix(m // 4, k)] for k in range(w)) / 2
    return sum(d), chi, cap, len(P), len(T)
errs = []
for m in (16, 32):
    s, chi, cap, nv, nf = rugby_mesh(m)
    print(f"rugby mesh {m}: corners {nv} triangles {nf} chi {chi} defects rad", f6(s), "tip cap", f6(cap), "error", f6(cap - rc))
    assert abs(s - TAU * chi) < 1e-9 and chi == 2
    errs.append(cap - rc)
print("error ratio", f6(errs[0] / errs[1]))
assert abs(errs[1]) < abs(errs[0]) / 3
nt, mt = 24, 12                              # inner tube mesh: 24 rings of 12 corners
P = [((TA + TB * math.cos(TAU * j / mt)) * math.cos(TAU * k / nt), (TA + TB * math.cos(TAU * j / mt)) * math.sin(TAU * k / nt),
      TB * math.sin(TAU * j / mt)) for k in range(nt) for j in range(mt)]
q = lambda k, j: (k % nt) * mt + j % mt
d, chi = defects(P, [t for k in range(nt) for j in range(mt) for t in ((q(k, j), q(k + 1, j), q(k + 1, j + 1)), (q(k, j), q(k + 1, j + 1), q(k, j + 1)))])
print("tube mesh 24 x 12: chi", chi, "defects rad", f6(sum(d)), "most, least deg", deg(max(d)), deg(min(d)))
assert abs(sum(d)) < 1e-9 and chi == 0

print("breaks: half dome without k_g rad", f6(kdA + 2 * corner), "deg", deg(kdA + 2 * corner))
print("breaks: flat 180-degree panel sums rad", f6(12 * (5 * math.radians(108) - 3 * PI) + 20 * (6 * math.radians(120) - 4 * PI)))
print("breaks: mean curvature, football m", f6(4 * PI * RB), "Earth km", f6(4 * PI * 6371))
print("try: rugby ball half-length 0.20: K tip", f6(0.2 ** 2 / A ** 4), "total", f6(total(lambda t: (A * math.sin(t), 0.2 * math.cos(t), A * math.cos(t), -0.2 * math.sin(t), -A * math.sin(t), -0.2 * math.cos(t)), 0, PI)))
r18 = half_dome(R, 18.0)
print("try: dome rise 18 m: K dA", f6(r18[2]), "rim", f6(r18[4]), "total", f6(r18[2] + r18[4] + 2 * r18[6]))
print("ALL CHECKS PASS")
```

**Ran 2026-11-19 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
ball radius m 0.110000 K 1/m^2 82.644628 area m^2 0.152053 K x area 12.566371 H 1/m 9.090909
pentagon corner deg 111.381279 excess rad 0.295072 deg 16.906395 chart integral rad 0.295072 area cm^2 35.703744 all 12 deg 202.876744
hexagon corner deg 124.309360 excess rad 0.451275 deg 25.856163 chart integral rad 0.451275 area cm^2 54.604296 all 20 deg 517.123256
corner sum deg 360.000000
32 panels rad 12.566371 deg 720.000000 V-E+F 2 2 pi chi 12.566371
panels summed: 2 pi F - pi (sides 180) + 2 pi V 12.566371
flat-panel ball: defect deg 12 x 60 corners 720 rad 12.566371 flat sheet K dA 0.000000
half dome: R m 60.000000 rise m 12.000000 rim radius m 36.000000 K 1/m^2 0.000277778 integral K dA rad 0.628319 deg 36.000000
rim: phi0 deg 36.869898 k_g 1/m 0.022222 cot(phi0)/R 0.022222 length m 113.097336 integral k_g ds rad 2.513274 deg 144.000000
cut: k_g 0.000000 length m 77.220133 turn at each corner deg 90.000000
total rad 6.283185 deg 360.000000
rugby ball: half-width m 0.095000 half-length m 0.145000 K tip 258.131844 C^2/A^4 258.131844 K waist 47.562426 1/C^2 47.562426
rugby ball total rad 12.566371 tip cap to ring z 0.102530 rad 2.839835 deg 162.710547
inner tube: centre circle m 0.300000 tube radius m 0.030000 K outer 101.010101 K inner -123.456790 K top 0.000000
inner tube outer half deg 720.000000 inner half -720.000000 total rad 0.000000 with |K| 25.132741
rugby mesh 16: corners 482 triangles 960 chi 2 defects rad 12.566371 tip cap 2.839164 error -0.000670
rugby mesh 32: corners 1986 triangles 3968 chi 2 defects rad 12.566371 tip cap 2.839656 error -0.000178
error ratio 3.758447
tube mesh 24 x 12: chi 0 defects rad 0.000000 most, least deg 7.743890 -7.743890
breaks: half dome without k_g rad 3.769911 deg 216.000000
breaks: flat 180-degree panel sums rad 0.000000
breaks: mean curvature, football m 1.382301 Earth km 80060.347184
try: rugby ball half-length 0.20: K tip 491.095065 total 12.566371
try: dome rise 18 m: K dA 0.942478 rim 2.199115 total 6.283185
ALL CHECKS PASS
```

### Rust

The same roads and the same numbers, printed in the same format. No crates.

```rust
// Gauss-Bonnet -- the check behind the card.  std only, no crates.
// A football, a stadium's half dome, a rugby ball and an inner tube: total curvature
// in a chart, against corner angles, mesh angle defects and the count V - E + F.
use std::collections::BTreeSet;
use std::f64::consts::PI;
const TAU: f64 = 2.0 * PI;
type V3 = [f64; 3];
type Prof = dyn Fn(f64) -> [f64; 6];

fn dot(a: V3, b: V3) -> f64 { a[0] * b[0] + a[1] * b[1] + a[2] * b[2] }
fn cross(a: V3, b: V3) -> V3 { [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]] }
fn sub(a: V3, b: V3) -> V3 { [a[0] - b[0], a[1] - b[1], a[2] - b[2]] }
fn scale(a: V3, k: f64) -> V3 { [a[0] * k, a[1] * k, a[2] * k] }
fn unit(a: V3) -> V3 { scale(a, 1.0 / dot(a, a).sqrt()) }
fn ang(a: V3, b: V3) -> f64 { dot(unit(a), unit(b)).clamp(-1.0, 1.0).acos() }
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    h / 3.0 * (0..=n).map(|i| (if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h)).sum::<f64>()
}
fn f6(x: f64) -> String { format!("{:.6}", if x.abs() < 5e-7 { 0.0 } else { x }) }
fn deg(x: f64) -> String { f6(x.to_degrees()) }
fn kda(pr: &Prof, t: f64) -> (f64, f64) { // surface of revolution, profile (rho, z) and derivatives in t; chart (t, theta), worked at theta = 0
    let [r, _z, r1, z1, r2, z2] = pr(t);
    let (rt, rq, rtt, rtq, rqq) = ([r1, 0.0, z1], [0.0, r, 0.0], [r2, 0.0, z2], [0.0, r1, 0.0], [-r, 0.0, 0.0]);
    let (n, s) = (cross(rt, rq), dot(cross(rt, rq), cross(rt, rq)).sqrt());
    if s == 0.0 { return (0.0, 0.0); } // a pole of the chart: no area
    let n = scale(n, 1.0 / s);
    let (e, f, g, l, m, nn) = (dot(rt, rt), dot(rt, rq), dot(rq, rq), dot(rtt, n), dot(rtq, n), dot(rqq, n));
    ((l * nn - m * m) / (e * g - f * f), s) // K = (LN - M^2)/(EG - F^2), and sqrt(EG - F^2)
}
fn total(pr: &Prof, a: f64, b: f64, turn: f64) -> f64 { turn * simpson(&|t| { let (k, s) = kda(pr, t); k * s }, a, b, 400) }

const RB: f64 = 0.11; // m: a size-5 ball, circumference 69.12 cm
fn rc() -> f64 { let phi = (1.0 + 5f64.sqrt()) / 2.0; (1.0 + 9.0 * phi * phi).sqrt() / 2.0 }
// flat n-sided face: circumradius, apothem, distance from centre
fn face(n: usize) -> (f64, f64, f64) { let c = 1.0 / (2.0 * (PI / n as f64).sin()); (c, c * (PI / n as f64).cos(), (rc() * rc() - c * c).sqrt()) }
fn panel_curv(n: usize) -> f64 { // chart: flat face point x -> ball point RB x/|x|; add K dA
    let (_c, h, d) = face(n);
    let strip = |psi: f64| simpson(&|s: f64| {
        let (x, xs, xp) = ([s * h, s * h * psi.tan(), d], [h, h * psi.tan(), 0.0], [0.0, s * h / psi.cos().powi(2), 0.0]);
        let l = dot(x, x).sqrt();
        let ps = scale(sub(scale(xs, l * l), scale(x, dot(x, xs))), RB / l.powi(3));
        let pp = scale(sub(scale(xp, l * l), scale(x, dot(x, xp))), RB / l.powi(3));
        dot(cross(ps, pp), cross(ps, pp)).sqrt() / (RB * RB) // K times sqrt(EG - F^2)
    }, 0.0, 1.0, 120);
    2.0 * n as f64 * simpson(&strip, 0.0, PI / n as f64, 120)
}
fn panel_angle(n: usize) -> f64 { // corner angle between two seams, which are great-circle arcs
    let (c, _h, d) = face(n);
    let p: Vec<V3> = [-1.0, 0.0, 1.0].iter().map(|k| unit([c * (TAU * k / n as f64).cos(), c * (TAU * k / n as f64).sin(), d])).collect();
    let t = |w: V3| sub(w, scale(p[1], dot(w, p[1]))); // tangent at p[1] toward w
    ang(t(p[0]), t(p[2]))
}
fn half_dome(r: f64, hh: f64) -> (f64, f64, f64, f64, f64, f64, f64) {
    let p0 = ((r - hh) / r).acos(); let (b, z0) = (r * p0.sin(), r * p0.cos());
    let sph = move |p: f64| [r * p.sin(), r * p.cos(), r * p.cos(), -r * p.sin(), -r * p.sin(), -r * p.cos()];
    let kda_ = total(&sph, 0.0, p0, PI); // theta over half a turn
    let kg_rim = dot([-b, 0.0, 0.0], cross(unit([b, 0.0, z0]), [0.0, b, 0.0])) / b.powi(3); // g'' . (n x g') / |g'|^3
    let (sn, cs) = (0.3f64.sin(), 0.3f64.cos());
    let (m0, m1, m2) = ([r * sn, 0.0, r * cs], [r * cs, 0.0, -r * sn], [-r * sn, 0.0, -r * cs]);
    let kg_mer = dot(m2, cross(unit(m0), m1)) / r.powi(3);
    let corner = ang([z0, 0.0, -b], [0.0, 1.0, 0.0]); // arrive down the cut, leave along the rim
    (p0, b, kda_, kg_rim, kg_rim * PI * b, kg_mer, corner)
}
fn defects(pts: &[V3], tris: &[[usize; 3]]) -> (Vec<f64>, i64) {
    let (mut d, mut edges) = (vec![TAU; pts.len()], BTreeSet::new());
    for t in tris { for k in 0..3 {
        let (o, p, q) = (pts[t[k]], pts[t[(k + 1) % 3]], pts[t[(k + 2) % 3]]);
        d[t[k]] -= ang(sub(p, o), sub(q, o));
        edges.insert((t[k].min(t[(k + 1) % 3]), t[k].max(t[(k + 1) % 3])));
    } }
    (d, pts.len() as i64 - edges.len() as i64 + tris.len() as i64)
}
const A: f64 = 0.095; // rugby ball: half-width (m)
const C: f64 = 0.145; // rugby ball: half-length (m)
fn rugby_mesh(m: usize) -> (f64, i64, f64, usize, usize) { // m rings from tip to tip, 2m corners round each ring
    let w = 2 * m;
    let mut p: Vec<V3> = vec![[0.0, 0.0, C]];
    for j in 1..m { for k in 0..w {
        let (tj, tk) = (j as f64 * PI / m as f64, TAU * k as f64 / w as f64);
        p.push([A * tj.sin() * tk.cos(), A * tj.sin() * tk.sin(), C * tj.cos()]);
    } }
    p.push([0.0, 0.0, -C]);
    let ix = |j: usize, k: usize| 1 + (j - 1) * w + k % w;
    let mut t: Vec<[usize; 3]> = (0..w).map(|k| [0, ix(1, k), ix(1, k + 1)]).collect();
    t.extend((0..w).map(|k| [p.len() - 1, ix(m - 1, k + 1), ix(m - 1, k)]));
    for j in 1..m - 1 { for k in 0..w { t.extend([[ix(j, k), ix(j + 1, k), ix(j + 1, k + 1)], [ix(j, k), ix(j + 1, k + 1), ix(j, k + 1)]]); } }
    let (d, chi) = defects(&p, &t);
    let cap = d[0] + (1..m / 4).flat_map(|j| (0..w).map(move |k| (j, k))).map(|(j, k)| d[ix(j, k)]).sum::<f64>()
        + (0..w).map(|k| d[ix(m / 4, k)]).sum::<f64>() / 2.0;
    (d.iter().sum(), chi, cap, p.len(), t.len())
}

fn main() {
    // 1. The football: a truncated icosahedron (edge 1) pumped onto a sphere of radius RB.
    let k = 1.0 / (RB * RB);
    println!("ball radius m {} K 1/m^2 {} area m^2 {} K x area {} H 1/m {}", f6(RB), f6(k), f6(4.0 * PI * RB * RB), f6(k * 4.0 * PI * RB * RB), f6(1.0 / RB));
    let mut tot = 0.0;
    for (n, cnt, name) in [(5usize, 12usize, "pentagon"), (6, 20, "hexagon")] {
        let (a, ci) = (panel_angle(n), panel_curv(n));
        let ex = n as f64 * a - (n as f64 - 2.0) * PI;
        println!("{} corner deg {} excess rad {} deg {} chart integral rad {} area cm^2 {} all {} deg {}",
                 name, deg(a), f6(ex), deg(ex), f6(ci), f6(ci / k * 1e4), cnt, deg(cnt as f64 * ci));
        assert!((ex - ci).abs() < 1e-8);
        tot += cnt as f64 * ci;
    }
    let (ap, ah) = (panel_angle(5), panel_angle(6));
    println!("corner sum deg {}", deg(ap + 2.0 * ah));
    assert!((ap + 2.0 * ah - TAU).abs() < 1e-12);
    let (v, e, f) = (60i64, 90i64, 32i64);
    println!("32 panels rad {} deg {} V-E+F {} 2 pi chi {}", f6(tot), deg(tot), v - e + f, f6(TAU * (v - e + f) as f64));
    println!("panels summed: 2 pi F - pi (sides 180) + 2 pi V {}", f6(TAU * f as f64 - PI * (5.0 * 12.0 + 6.0 * 20.0) + TAU * v as f64));
    println!("flat-panel ball: defect deg {} x 60 corners {} rad {} flat sheet K dA {}", 360 - 108 - 240, 60 * 12, f6(60.0 * 12f64.to_radians()), f6(total(&|t: f64| [t, 0.0, 1.0, 0.0, 0.0, 0.0], 0.0, 1.0, TAU)));
    assert!((tot - TAU * (v - e + f) as f64).abs() < 1e-8 && (60.0 * 12f64.to_radians() - tot).abs() < 1e-8);

    // 2. The half dome: sphere radius 60 m, rise 12 m, cut along a great circle through its top.
    let r = 60.0;
    let (p0, b, kdav, kgr, rim, kgm, corner) = half_dome(r, 12.0);
    println!("half dome: R m {} rise m {} rim radius m {} K 1/m^2 {:.9} integral K dA rad {} deg {}", f6(r), f6(12.0), f6(b), 1.0 / (r * r), f6(kdav), deg(kdav));
    println!("rim: phi0 deg {} k_g 1/m {} cot(phi0)/R {} length m {} integral k_g ds rad {} deg {}", deg(p0), f6(kgr), f6(1.0 / (r * p0.tan())), f6(PI * b), f6(rim), deg(rim));
    println!("cut: k_g {} length m {} turn at each corner deg {}", f6(kgm), f6(2.0 * r * p0), deg(corner));
    println!("total rad {} deg {}", f6(kdav + rim + 2.0 * corner), deg(kdav + rim + 2.0 * corner));
    assert!((kdav + rim + 2.0 * corner - TAU).abs() < 1e-9);
    assert!((kgr - 1.0 / (r * p0.tan())).abs() < 1e-12 && kgm.abs() < 1e-12);

    // 3. A rugby ball and an inner tube, K from the two fundamental forms.
    let rug = |t: f64| [A * t.sin(), C * t.cos(), A * t.cos(), -C * t.sin(), -A * t.sin(), -C * t.cos()];
    let (ta, tb) = (0.30, 0.03); // inner tube: centre circle and tube radius (m)
    let tube = move |v: f64| [ta + tb * v.cos(), tb * v.sin(), -tb * v.sin(), tb * v.cos(), -tb * v.cos(), -tb * v.sin()];
    println!("rugby ball: half-width m {} half-length m {} K tip {} C^2/A^4 {} K waist {} 1/C^2 {}", f6(A), f6(C), f6(kda(&rug, 1e-6).0), f6(C * C / A.powi(4)), f6(kda(&rug, PI / 2.0).0), f6(1.0 / (C * C)));
    let (rt, rcap) = (total(&rug, 0.0, PI, TAU), total(&rug, 0.0, PI / 4.0, TAU));
    println!("rugby ball total rad {} tip cap to ring z {} rad {} deg {}", f6(rt), f6(C * (PI / 4.0).cos()), f6(rcap), deg(rcap));
    println!("inner tube: centre circle m {} tube radius m {} K outer {} K inner {} K top {}", f6(ta), f6(tb), f6(kda(&tube, 0.0).0), f6(kda(&tube, PI).0), f6(kda(&tube, PI / 2.0).0));
    let (to, ti) = (total(&tube, -PI / 2.0, PI / 2.0, TAU), total(&tube, PI / 2.0, 3.0 * PI / 2.0, TAU));
    println!("inner tube outer half deg {} inner half {} total rad {} with |K| {}", deg(to), deg(ti), f6(to + ti), f6(to - ti));
    assert!((rt - 2.0 * TAU).abs() < 1e-8 && (to - 2.0 * TAU).abs() < 1e-8 && (to + ti).abs() < 1e-8);

    // 4. Meshes of flat triangles pinned to the surface: all curvature sits in the corners as angle defects.
    let mut errs = vec![];
    for m in [16usize, 32] {
        let (s, chi, cap, nv, nf) = rugby_mesh(m);
        println!("rugby mesh {}: corners {} triangles {} chi {} defects rad {} tip cap {} error {}", m, nv, nf, chi, f6(s), f6(cap), f6(cap - rcap));
        assert!((s - TAU * chi as f64).abs() < 1e-9 && chi == 2);
        errs.push(cap - rcap);
    }
    println!("error ratio {}", f6(errs[0] / errs[1]));
    assert!(errs[1].abs() < errs[0].abs() / 3.0);
    let (nt, mt) = (24usize, 12usize); // inner tube mesh: 24 rings of 12 corners
    let (mut p, mut tr): (Vec<V3>, Vec<[usize; 3]>) = (vec![], vec![]);
    let q = |kk: usize, j: usize| (kk % nt) * mt + j % mt;
    for kk in 0..nt { for j in 0..mt {
        let (a, c) = (TAU * j as f64 / mt as f64, TAU * kk as f64 / nt as f64);
        p.push([(ta + tb * a.cos()) * c.cos(), (ta + tb * a.cos()) * c.sin(), tb * a.sin()]);
        tr.extend([[q(kk, j), q(kk + 1, j), q(kk + 1, j + 1)], [q(kk, j), q(kk + 1, j + 1), q(kk, j + 1)]]);
    } }
    let (d, chi) = defects(&p, &tr);
    let (sd, mx, mn) = (d.iter().sum::<f64>(), d.iter().cloned().fold(f64::MIN, f64::max), d.iter().cloned().fold(f64::MAX, f64::min));
    println!("tube mesh 24 x 12: chi {} defects rad {} most, least deg {} {}", chi, f6(sd), deg(mx), deg(mn));
    assert!(sd.abs() < 1e-9 && chi == 0);

    println!("breaks: half dome without k_g rad {} deg {}", f6(kdav + 2.0 * corner), deg(kdav + 2.0 * corner));
    println!("breaks: flat 180-degree panel sums rad {}", f6(12.0 * (5.0 * 108f64.to_radians() - 3.0 * PI) + 20.0 * (6.0 * 120f64.to_radians() - 4.0 * PI)));
    println!("breaks: mean curvature, football m {} Earth km {}", f6(4.0 * PI * RB), f6(4.0 * PI * 6371.0));
    let rug2 = |t: f64| [A * t.sin(), 0.2 * t.cos(), A * t.cos(), -0.2 * t.sin(), -A * t.sin(), -0.2 * t.cos()];
    println!("try: rugby ball half-length 0.20: K tip {} total {}", f6(0.2 * 0.2 / A.powi(4)), f6(total(&rug2, 0.0, PI, TAU)));
    let r18 = half_dome(r, 18.0);
    println!("try: dome rise 18 m: K dA {} rim {} total {}", f6(r18.2), f6(r18.4), f6(r18.2 + r18.4 + 2.0 * r18.6));
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-19 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
ball radius m 0.110000 K 1/m^2 82.644628 area m^2 0.152053 K x area 12.566371 H 1/m 9.090909
pentagon corner deg 111.381279 excess rad 0.295072 deg 16.906395 chart integral rad 0.295072 area cm^2 35.703744 all 12 deg 202.876744
hexagon corner deg 124.309360 excess rad 0.451275 deg 25.856163 chart integral rad 0.451275 area cm^2 54.604296 all 20 deg 517.123256
corner sum deg 360.000000
32 panels rad 12.566371 deg 720.000000 V-E+F 2 2 pi chi 12.566371
panels summed: 2 pi F - pi (sides 180) + 2 pi V 12.566371
flat-panel ball: defect deg 12 x 60 corners 720 rad 12.566371 flat sheet K dA 0.000000
half dome: R m 60.000000 rise m 12.000000 rim radius m 36.000000 K 1/m^2 0.000277778 integral K dA rad 0.628319 deg 36.000000
rim: phi0 deg 36.869898 k_g 1/m 0.022222 cot(phi0)/R 0.022222 length m 113.097336 integral k_g ds rad 2.513274 deg 144.000000
cut: k_g 0.000000 length m 77.220133 turn at each corner deg 90.000000
total rad 6.283185 deg 360.000000
rugby ball: half-width m 0.095000 half-length m 0.145000 K tip 258.131844 C^2/A^4 258.131844 K waist 47.562426 1/C^2 47.562426
rugby ball total rad 12.566371 tip cap to ring z 0.102530 rad 2.839835 deg 162.710547
inner tube: centre circle m 0.300000 tube radius m 0.030000 K outer 101.010101 K inner -123.456790 K top 0.000000
inner tube outer half deg 720.000000 inner half -720.000000 total rad 0.000000 with |K| 25.132741
rugby mesh 16: corners 482 triangles 960 chi 2 defects rad 12.566371 tip cap 2.839164 error -0.000670
rugby mesh 32: corners 1986 triangles 3968 chi 2 defects rad 12.566371 tip cap 2.839656 error -0.000178
error ratio 3.758447
tube mesh 24 x 12: chi 0 defects rad 0.000000 most, least deg 7.743890 -7.743890
breaks: half dome without k_g rad 3.769911 deg 216.000000
breaks: flat 180-degree panel sums rad 0.000000
breaks: mean curvature, football m 1.382301 Earth km 80060.347184
try: rugby ball half-length 0.20: K tip 491.095065 total 12.566371
try: dome rise 18 m: K dA 0.942478 rim 2.199115 total 6.283185
ALL CHECKS PASS
```

The two outputs agree line for line.

### Lean

Lean proves Step 3 and Step 4 for any closed surface cut into polygons, taking the local theorem as given, and checks the card's counts.

- Suppose each polygon obeys the local theorem, each edge's bending cancels between its two walks, and the angles round each vertex fill $`2\pi`$. Then the curvature of all the polygons adds to $`2\pi(V - E + F)`$.
- Suppose a closed surface is sewn from flat panels, so a panel with $`n`$ corners has angles adding to $`(n - 2)\pi`$. Then the angle defects at all its corners add to $`2\pi(V - E + F)`$, whatever the mesh.
- Take the football's 60 corners, 90 seams and 32 panels. Then $`V - E + F = 2`$, and its 180 panel sides are $`2 \times 90`$.
- Take a corner where one flat 108° angle and two flat 120° angles meet. Then its gap is 12°, and 60 such gaps total 720° = 360° × 2.
- Take the half dome's 36° inside, 144° on the rim, 0° on the cut and two 90° corners. Then they add to 360°; without the rim's 144° they give 216°.
- Take the inner tube's outer half, +720°, and inner half, −720°. Then the total is 0° = 360° × (2 − 2 × 1), and adding $`\lvert K\rvert`$ instead gives 1440°.
- Take a surface with two holes. Then $`\chi = 2 - 2 \times 2 = -2`$, and its total is −720°.
- Take any genus $`g`$. Then $`2\pi(2 - 2g) = 4\pi(1 - g)`$.

The curvature integrals in a chart, the pumped-up corner angles and the meshes are left to the Python and Rust checks.

```lean
-- Gauss-Bonnet: on a closed surface cut into polygon patches, the local theorem on each patch adds up to a total curvature of 2π times V - E + F, and the angle defects of a mesh of flat panels total the same 2π times V - E + F.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Data.Fintype.Card

open Finset Real

/-- Global Gauss-Bonnet from the local theorem (the card's Step 3, "add the panels, and the
edges cancel"). A closed surface, with no rim, is cut into `F` polygon patches with `V` corners
and `E` edges. Each patch's edge is walked with the patch on the left and split into sides
(the type `H`); side `h` lies on patch `face h`, starts at corner `start h`, runs along edge
`edge h`, and `α h` is the patch's inside angle at that starting corner. Every edge borders
exactly two sides, walked in opposite directions (`twin`), so reversing the walk flips the
sign of the edge's bending `kg` (its integral of geodesic curvature). If every patch obeys the
local theorem, curvature inside plus edge bending plus corner turns `π - α` equals `2π`, and
the angles round every corner make a full turn `2π`, then the total curvature of the surface
is `2π (V - E + F)`. -/
theorem total_curvature_eq_two_pi_mul_euler_char
    {V E F H : Type*} [Fintype V] [Fintype E] [Fintype F] [Fintype H]
    [DecidableEq V] [DecidableEq E] [DecidableEq F]
    (face : H → F) (start : H → V) (edge : H → E) (twin : H → H)
    (htwin : ∀ h, twin (twin h) = h) (htwin_ne : ∀ h, twin h ≠ h)
    (htwin_edge : ∀ h, edge (twin h) = edge h)
    (htwo : ∀ e, #{h | edge h = e} = 2)
    (curv : F → ℝ) (kg : H → ℝ) (α : H → ℝ)
    (hkg : ∀ h, kg (twin h) = -kg h)
    (hlocal : ∀ f, curv f + ∑ h with face h = f, kg h + ∑ h with face h = f, (π - α h) = 2 * π)
    (hvertex : ∀ v, ∑ h with start h = v, α h = 2 * π) :
    ∑ f, curv f =
      2 * π * ((Fintype.card V : ℝ) - Fintype.card E + Fintype.card F) := by
  have hH : (Fintype.card H : ℝ) = 2 * Fintype.card E := by
    have := Finset.card_eq_sum_card_fiberwise (f := edge) (s := (univ : Finset H))
      (t := (univ : Finset E)) (fun _ _ => mem_univ _)
    simp only [htwo, sum_const, card_univ, smul_eq_mul] at this
    rw [this]
    push_cast; ring
  have hkg0 : ∑ h, kg h = 0 := by
    have e : ∑ h, kg (twin h) = ∑ h, kg h :=
      Equiv.sum_comp (Function.Involutive.toPerm twin htwin) kg
    simp only [hkg, sum_neg_distrib] at e
    linarith
  have hα : ∑ h, α h = 2 * π * Fintype.card V := by
    rw [← Finset.sum_fiberwise univ start α]
    simp only [hvertex, sum_const, card_univ, nsmul_eq_mul]
    ring
  have hsum := Finset.sum_congr rfl (fun f (_ : f ∈ (univ : Finset F)) => hlocal f)
  rw [sum_add_distrib, sum_add_distrib, Finset.sum_fiberwise univ face kg,
    Finset.sum_fiberwise univ face (fun h => π - α h), sum_sub_distrib, hkg0, hα] at hsum
  simp only [sum_const, card_univ, nsmul_eq_mul] at hsum
  rw [hH] at hsum
  linarith

/-- A corner gap is curvature packed into a point (the card's Step 4). A closed surface, with
no rim, is built from `F` flat polygon panels with `V` corners and `E` edges; corner `h` of
panel `face h` sits at the surface corner `start h` with inside angle `α h`, and every edge
borders exactly two panel sides. A flat panel with `n` corners has angles adding to
`(n - 2) π`. Then the angle defects, `2π` minus the angles meeting at each corner, add up to
`2π (V - E + F)`, whatever the mesh. -/
theorem sum_angle_defects_eq_two_pi_mul_euler_char
    {V E F H : Type*} [Fintype V] [Fintype E] [Fintype F] [Fintype H]
    [DecidableEq V] [DecidableEq E] [DecidableEq F]
    (face : H → F) (start : H → V) (edge : H → E)
    (htwo : ∀ e, #{h | edge h = e} = 2)
    (α : H → ℝ)
    (hflat : ∀ f, ∑ h with face h = f, α h = ((#{h | face h = f} : ℝ) - 2) * π) :
    ∑ v, (2 * π - ∑ h with start h = v, α h) =
      2 * π * ((Fintype.card V : ℝ) - Fintype.card E + Fintype.card F) := by
  have hH : (Fintype.card H : ℝ) = 2 * Fintype.card E := by
    have := Finset.card_eq_sum_card_fiberwise (f := edge) (s := (univ : Finset H))
      (t := (univ : Finset E)) (fun _ _ => mem_univ _)
    simp only [htwo, sum_const, card_univ, smul_eq_mul] at this
    rw [this]
    push_cast; ring
  have hF : ∑ f, ((#{h | face h = f} : ℝ)) = Fintype.card H := by
    have := Finset.card_eq_sum_card_fiberwise (f := face) (s := (univ : Finset H))
      (t := (univ : Finset F)) (fun _ _ => mem_univ _)
    simp only [card_univ] at this
    rw [this]
    push_cast; rfl
  have hα : ∑ h, α h = π * Fintype.card H - 2 * π * Fintype.card F := by
    rw [← Finset.sum_fiberwise univ face α]
    simp only [hflat, ← sum_mul, sum_sub_distrib, hF, sum_const, card_univ, nsmul_eq_mul]
    ring
  rw [sum_sub_distrib, Finset.sum_fiberwise univ start α, hα, hH]
  simp only [sum_const, card_univ, nsmul_eq_mul]
  ring

-- The football: 60 corners, 90 seams, 32 panels, so V - E + F = 2.
example : (60 : ℤ) - 90 + 32 = 2 := by norm_num
-- Its panels have 5 x 12 + 6 x 20 = 180 sides, each seam counted twice: 180 = 2 x 90.
example : 5 * 12 + 6 * 20 = 180 ∧ 180 = 2 * 90 := by decide
-- Panels summed: 2π x 32 - π x 180 + 2π x 60 = 4π = 2π x 2.
example : 2 * π * 32 - π * 180 + 2 * π * 60 = 2 * π * 2 := by ring
-- Flat-panel ball: a 12-degree gap at each corner (360 - 108 - 2 x 120), 60 corners, 720 degrees = 360 x 2.
example : 360 - 108 - 2 * 120 = 12 ∧ 60 * 12 = 720 ∧ 720 = 360 * 2 := by decide
-- Half dome, in degrees: 36 inside + 144 on the rim + 0 on the cut + 90 + 90 at the corners = 360.
example : 36 + 144 + 0 + 90 + 90 = 360 := by decide
-- Without the rim's bending: 36 + 90 + 90 = 216, not 360.
example : 36 + 90 + 90 = 216 := by decide
-- Inner tube, in degrees: outer half +720, inner half -720, total 0 = 360 x chi with chi = 2 - 2 x 1;
-- adding |K| instead gives 1440 degrees, which is 8π.
example : (720 : ℤ) + (-720) = 0 ∧ (0 : ℤ) = 360 * (2 - 2 * 1) ∧ (720 : ℤ) + 720 = 1440 := by norm_num
-- Two holes: chi = 2 - 2 x 2 = -2, total -720 degrees.
example : (2 : ℤ) - 2 * 2 = -2 ∧ (360 : ℤ) * (-2) = -720 := by norm_num
-- 2π chi = 4π (1 - g) for every genus g.
example (g : ℝ) : 2 * π * (2 - 2 * g) = 4 * π * (1 - g) := by ring

#print axioms total_curvature_eq_two_pi_mul_euler_char
#print axioms sum_angle_defects_eq_two_pi_mul_euler_char
```

**Checked 2026-11-19 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'total_curvature_eq_two_pi_mul_euler_char' depends on axioms: [propext, Classical.choice, Quot.sound]
'sum_angle_defects_eq_two_pi_mul_euler_char' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> - Guess first: does a longer, pointier rugby ball hold more curvature? Set the half-length to 0.20 m. The tip curvature rises to 491.095065 1/m², and the total stays **12.566371** rad.
> - Guess first: if the half dome rises 18 m instead of 12, where does the extra curvature inside come from? Use `half_dome(R, 18.0)`. Inside rises to 0.942478 rad, the rim's bending falls to 2.199115 rad, and the total stays **6.283185** rad.
> - Guess first: how much does a finer mesh help near the tip? Compare 16 rings with 32 rings. The error falls from −0.000670 to **−0.000178** rad.

---

## The usual mistake

> [!warning]
> **Thinking a bigger ball holds more curvature.** A larger sphere is flatter: $`K = 1/R^2`$ falls exactly as the area $`4\pi R^2`$ grows. The football and the Earth both hold 12.566371 rad, 720°. A quantity whose total grows with size, like the mean curvature (1.382301 m on the football, 80,060.347184 km on the Earth), is not this one.
>
> Smaller traps:
> - **Reading the total as a local fact.** The rugby ball has 258.131844 1/m² at its tips and 47.562426 at its waist. The theorem fixes only the sum.
> - **Forgetting the edge.** On the half dome, curvature and corners alone give 216°, not 360°.
> - **Counting saddles as positive.** Adding $`\lvert K\rvert`$ over the inner tube gives 25.132741 rad, not 0.
> - **Using flat corner angles on curved panels.** 108° and 120° give zero excess; the pumped-up panels have 111.381279° and 124.309360°.

---

## Where you meet it in real life

- **Footballs and carbon cages.** Every closed ball of pentagons and hexagons, three at a corner, has 12 pentagons. Pumping it up spreads their 720° of corner curvature over all the panels. The carbon-60 molecule has the same pattern.
- **Computer graphics and 3D scanning.** Software treats the angle defect at each mesh corner as discrete Gaussian curvature. The defects must total $`2\pi\chi`$, so a wrong total flags a hole or a tear in a scanned surface.
- **Tensile and shell roofs.** A designer cannot make a closed, dome-only shape with a hole. Saddle-shaped regions, like the middle of the stadium roof, are where negative curvature must appear.
- **Surveying and gyroscopes.** The angles of a large surveyed triangle on the Earth add to more than 180°, by its enclosed curvature. A gyroscope carried round a loop comes back turned by the same amount ([Parallel transport](../05-Riemannian%20Geometry/03-parallel-transport-and-holonomy.md)).
- **Cell membranes and crystals on curved surfaces.** A closed membrane must hold 720° of curvature whatever its shape. A crystal grown on a sphere must hold point defects whose curvature adds to the same 720°.

> **Say it back**
> Gaussian curvature times area, added over a closed surface, is $`2\pi`$ times its Euler characteristic. For a patch with an edge, the curvature inside plus the edge's bending plus its corner turns is one full turn. Cut a closed surface into patches and add: the edges cancel and the corners leave $`2\pi(V - E + F)`$. A football holds 720° whether its panels are flat with 12° corner gaps or pumped up round. An inner tube holds 0°, because its saddle-shaped inside cancels its ball-shaped outside.

---

## What this builds on

- [Principal, mean and Gaussian curvature](05-principal-mean-and-gaussian-curvature.md): defines $`K`$, the quantity this card adds up.
- [Geodesic on a surface](09-geodesics-on-surfaces.md): defines $`\kappa_g`$, the edge bending in the local theorem, and the geodesics that make it zero.
- [Polyhedra](../../05-Geometry%20and%20trig/02-Circles%20and%20Solids/06-polyhedra-and-eulers-formula.md): the football's count, 60 − 90 + 32 = 2, and its 720° of corner gaps.
- [Closed surfaces classified](../../17-Topology/03-Surfaces%20and%20Manifolds/02-surfaces-and-the-classification-theorem.md): every closed two-sided surface is a sphere with $`g`$ handles, so $`\chi = 2 - 2g`$.
- [Euler characteristic](../../17-Topology/03-Surfaces%20and%20Manifolds/04-euler-characteristic-and-triangulations.md): $`V - E + F`$ does not depend on the cutting, and it tells a torus from a sphere.
- [Triangles on a sphere](../../05-Geometry%20and%20trig/06-Beyond%20Euclid/01-triangles-on-a-sphere.md): Girard's theorem, the constant-curvature case of Step 1.

## Where this goes next

- [Hairy ball theorem](../06-Lie%20Groups/09-vector-field-zeros-and-the-hairy-ball.md): every wind pattern on a ball has a calm point, because the indices of a field's zeros on a surface also add up to $`\chi`$.
- [Parallel transport](../05-Riemannian%20Geometry/03-parallel-transport-and-holonomy.md): the turn of a carried arrow round a loop, which the local theorem equates with the curvature inside.

The question this card leaves open: Gauss-Bonnet ties curvature to a count on surfaces, so what plays the same role on spaces of higher dimension?

---

## Sources

Verified 2026-11-19: every link below resolves to the publisher's page.

- do Carmo, Manfredo P. *Differential Geometry of Curves and Surfaces*, revised and updated 2nd ed. Dover, 2016. [Publisher page](https://store.doverpublications.com/products/9780486806990). Section 4-5 proves the local and global Gauss-Bonnet theorems by Green's theorem, with Liouville's formula and the turning-tangent theorem; it also states that every closed surface can be cut into triangles, and section 3-4 builds charts whose grid lines cross square.
- Pressley, Andrew. *Elementary Differential Geometry*, 2nd ed. Springer, 2010. [doi:10.1007/978-1-84882-891-9](https://doi.org/10.1007/978-1-84882-891-9). The Gauss-Bonnet theorem for simple closed curves, polygons and compact surfaces, with worked examples.
- Meyer, Mark, Mathieu Desbrun, Peter Schröder and Alan H. Barr. "Discrete Differential-Geometry Operators for Triangulated 2-Manifolds." In *Visualization and Mathematics III*, Springer, 2003. [doi:10.1007/978-3-662-05105-4_2](https://doi.org/10.1007/978-3-662-05105-4_2). The angle defect as discrete Gaussian curvature on a mesh, the third road in the code.
- The International Football Association Board. *Laws of the Game*, Law 2: The Ball. [IFAB page](https://www.theifab.com/laws/latest/the-ball/). A match ball's circumference is 68 to 70 cm, which sets the 11 cm radius used here.
