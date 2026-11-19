# Killing field: a direction in which the geometry does not change

[Syllabus](../../../SYLLABUS.md) → [Differential geometry and Lie groups](../README.md) → [Lie Groups](../README.md#s06) → Killing field

---

## General Overview

The Earth turns once about its polar axis every sidereal day of 86164.0905 s, one turn measured against the equinox (the direction star charts count from). In six sidereal hours, London and New York each swing a quarter turn east. The distance between them stays 5570.22 km, the great-circle distance found on [Riemannian metric](../05-Riemannian%20Geometry/01-riemannian-metrics.md).

The spin gives every point an arrow: the direction and speed that point moves. A rule that puts one arrow at every point is a **vector field** ([Vector field and its flow](../03-Manifolds/07-vector-fields-and-flows.md)). The spin's arrows are 289.2 m/s long at London, 352.1 m/s at New York and zero at the poles.

Not every field is so kind to the map. Push every point 0.5 rad south along its meridian, and London and New York end up 7855.38 km apart. Let the spin rate fade toward the poles, a twist, and they end up 5313.35 km apart.

A field whose motion keeps every distance is a **Killing field**, after Wilhelm Killing, who studied them in 1892. This card does two things.

- It checks that a spin leaves the globe's metric untouched, by a formula and by moving real points.
- It finds all of them: on the round globe there are exactly three independent ones, the spins about three axes. Every other Killing field is a mix of these, a spin about some tilted axis.

On the real, slightly flattened Earth, two of the three die. Only the spin about the polar axis survives.

**A Killing field is a vector field whose motion changes no length; on a round globe these are exactly the spins about axes through the centre, three independent directions, one for each turn rate.**

**What kind of fact this is:** a Killing field is a definition. The test $`\mathcal{L}_X g = 0`$, the count of three on the round globe and the count of one on the flattened Earth are theorems, proved on this card in Why it works. Both counts are local as well as global: they hold on the whole surface and on any connected patch of it. The Earth as a sphere of radius 6371 km is a model.

### The picture: London to New York after 0.5 unit of each motion

```
spin about the polar axis z  |######################          5570.22 km   Killing: yes
spin about the axis x        |######################          5570.22 km   Killing: yes
spin about the axis y        |######################          5570.22 km   Killing: yes
slide south                  |############################### 7855.38 km   Killing: no
twist, rate sin(phi)         |#####################           5313.35 km   Killing: no
```

One mark is 250 km. The checks print these lines. The three spins leave the distance alone; the slide and the twist do not.

---

## The formula

Notation first, in words. On the globe the chart is $`(\varphi, \theta)`$: $`\varphi`$ (phi) is the angle down from the North Pole and $`\theta`$ (theta) is the longitude east, both in radians. The metric (the rule for the length of a small step) is the table $`g_{ij}`$ with $`g_{\varphi\varphi} = R^2`$, $`g_{\theta\theta} = R^2 \sin^2\varphi`$ and $`g_{\varphi\theta} = 0`$.

A vector field $`X`$ has two components in the chart, $`X^\varphi`$ and $`X^\theta`$: how fast each coordinate changes, in radians per unit time. Its **flow** $`\varphi_t`$ moves every point for time $`t`$ along the arrows. With a subscript, $`\varphi_t`$ is the flow; alone, $`\varphi`$ stays the polar angle.

The **Lie derivative** $`\mathcal{L}_X g`$, met on [Lie bracket](../03-Manifolds/08-lie-brackets-and-frobenius-theorem.md), is the rate at which the metric changes when it is carried along the flow. Take a small step $`u`$ at a point. The flow carries it to a small step at the moved point. $`(\mathcal{L}_X g)(u, u)`$ is the rate of change of that step's squared length at $`t = 0`$. A Killing field is one where this rate is zero for every step:

```math
\mathcal{L}_X g = 0
```

**Read it aloud:** carried along the field's motion, no small step gets longer or shorter, and no angle opens or closes.

In a chart this becomes three equations, one for each entry of the symmetric table. Here $`\partial_i`$ is the rate of change along chart direction $`i`$, and the repeated index $`k`$ is summed over $`\varphi`$ and $`\theta`$:

```math
(\mathcal{L}_X g)_{ij} = X^k\,\partial_k g_{ij} + g_{kj}\,\partial_i X^k + g_{ik}\,\partial_j X^k = 0
```

**Read it aloud:** the change in the table as the point moves, plus how much the motion stretches each of the two step directions, adds to zero.

On the round globe the three equations have exactly one family of solutions. Write $`\omega = (\omega_x, \omega_y, \omega_z)`$ for a turn rate about the three axes through the centre, as on [Lie algebra](02-lie-algebras-and-the-exponential-map.md). Then every Killing field is

```math
X^\varphi = \omega_y \cos\theta - \omega_x \sin\theta, \qquad X^\theta = \omega_z - \cot\varphi\,\big(\omega_x \cos\theta + \omega_y \sin\theta\big)
```

**Read it aloud:** every Killing field of the round globe is the spin about one axis through the centre; three numbers fix it, so there are three independent fields.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $`R`$, $`\varphi`$, $`\theta`$ | the globe's radius; angle down from the North Pole; longitude east, in radians | 6371 km; New York at 49.2872°, −74.0060° | — |
| $`g`$, $`g_{ij}`$ | the metric; its table in the chart, km² per radian² | $`g_{\varphi\varphi} = R^2`$, $`g_{\theta\theta} = R^2\sin^2\varphi`$ | — |
| $`X`$, $`X^\varphi`$, $`X^\theta`$, $`X^k`$ | a vector field; its components, radians per unit time | spin about x at New York: (0.961291, −0.237106) | a faster field moves points faster; Killing or not stays the same |
| $`\partial_i`$, $`i`$, $`j`$, $`k`$ | rate of change along chart direction $`i`$; labels running over $`\varphi`$ and $`\theta`$ | $`\partial_\theta g_{ij} = 0`$ on the globe | — |
| $`\varphi_t`$, $`t`$, $`s`$ | the flow: every point moved for time $`t`$ (or $`s`$) | 0.5 unit; $`\pi/2`$ is six sidereal hours of Earth spin | Killing flows keep every distance for every $`t`$ |
| $`u`$, $`v`$ | small steps at one point | the chart's unit steps | — |
| $`\mathcal{L}_X g`$ | the rate the metric changes along the flow | 0 for spins; (0, 0.988823, 0) × $`R^2`$ for the slide south | the further from zero, the faster lengths change |
| $`\omega_x`$, $`\omega_y`$, $`\omega_z`$ | turn rate about each axis, radians per unit time | Earth: (0, 0, 7.292116 × 10⁻⁵ rad/s) | faster spin |
| $`[X, Y]`$ | the Lie bracket of two fields | [spin x, spin y] = − spin z | — |
| $`T`$, $`\alpha`$ | unit tangent of a route; heading, clockwise from north | 288.33° leaving London | — |
| $`a`$, $`b`$, $`K`$ | the flattened Earth's equatorial and polar radii; Gaussian curvature, 1/km² | 6378.137 km and 6356.752 km | the bigger the gap, the more the tilted spins fail |
| $`n`$ | the dimension of the space | 2 for a surface | at most $`n(n+1)/2`$ Killing fields: 3 here |

This card introduces one piece of notation: $`\mathcal{L}_X g = 0`$ for a Killing field. Later cards use it freely.

### When it holds

- **The metric must be exactly the one tested.** The spins about x and y are symmetries of the round model only. On the flattened Earth a quarter turn about x sinks the North Pole 21.385 km below the surface, and those two fields stop being Killing.
- **The patch must be in one piece.** The proofs use only the equations near each point, so any connected patch has the same counts as the whole surface. On two separate patches each can spin on its own, and the count doubles. The formula's $`\cot\varphi`$ blows up at the poles, but that is the chart failing, not the field: seen in space, a spin moves every point smoothly, at most $`R\lvert\omega\rvert`$.
- **Sums and constant multiples only.** The equation is linear, so a sum of Killing fields is Killing: that is how tilted axes arise. A Killing field times a function is not. The twist is the polar spin times $`\sin\varphi`$, and it pulls London and New York to 5313.35 km.
- **Lengths, not points.** A Killing flow keeps every distance, but it moves points, and its arrows need not all be the same length. The polar spin moves New York at 352.1 m/s and the pole not at all.

---

## Why it works

### Step 0: a symmetry that never starts to change never changes

A flow has a group property: moving for time $`s`$ and then for time $`t`$ is moving for time $`s + t`$. So the rate at which lengths change at time $`t`$ is the rate at time 0, measured at the points the flow has reached.

If the rate is zero at every point at time 0, it is zero at every later time. Every small step keeps its length, so every path keeps its length, and every distance is kept. That is why one first-instant test, $`\mathcal{L}_X g = 0`$, decides the whole motion.

<details>
<summary>Detailed proof: zero rate at the start means zero rate forever</summary>

Write $`\ell_t(u) = g(\text{carried } u, \text{carried } u)`$ for the squared length, at time $`t`$, of a step $`u`$ carried by the flow. By the group property, carrying for time $`t + h`$ is carrying for time $`t`$ and then for time $`h`$. So

$`\displaystyle \frac{d}{dt}\,\ell_t(u) = (\mathcal{L}_X g)(w, w), \qquad w = \text{the step } u \text{ carried for time } t`$

The right side is zero by assumption, so $`\ell_t(u) = \ell_0(u)`$ for every $`t`$. A path's length is the integral of the square roots of these squared lengths, so every path keeps its length. Distance is the shortest length, so every distance is kept.

</details>

### Step 1: where the three terms come from

Follow a small step for a short time $`t`$. Two things happen.

1. Its start point moves by $`t X`$. The metric's table there differs by $`t\, X^k \partial_k g_{ij}`$.
2. Its two ends move at slightly different speeds. The step grows by $`t`$ times the rate of change of $`X`$ along it: that gives the two $`\partial_i X^k`$ terms, one for each slot of the metric.

The first term is the table changing; the other two are the motion stretching. A field is Killing when the two effects cancel.

<details>
<summary>Detailed proof: the coordinate formula</summary>

A step $`u`$ at point $`p`$ runs from $`p`$ to $`p + u`$. After time $`t`$ its ends sit at $`p + tX(p)`$ and $`p + u + tX(p + u)`$, to first order in $`t`$. The new step is $`u + t\,u^i \partial_i X`$, to first order in the step size. Its squared length uses the table at the new point:

$`\displaystyle \big(g_{ij} + t\,X^k\partial_k g_{ij}\big)\big(u^i + t\,u^m\partial_m X^i\big)\big(u^j + t\,u^m\partial_m X^j\big)`$

Expand and keep the terms with one factor of $`t`$:

$`\displaystyle t\,\big(X^k\partial_k g_{ij} + g_{kj}\,\partial_i X^k + g_{ik}\,\partial_j X^k\big)\,u^i u^j`$

The bracket is $`(\mathcal{L}_X g)_{ij}`$. The step's squared length fixes the symmetric table, since $`g(u, v)`$ is recovered from squared lengths of $`u`$, $`v`$ and $`u + v`$.

</details>

### Step 2: the spins pass, the others fail

The polar spin has components $`X = (0, 1)`$. They are constant, so both stretch terms vanish. The table depends on $`\varphi`$ only, and the spin moves only $`\theta`$, so the first term vanishes too.

The spin about the x-axis is the interesting test. At New York its components are (0.961291, −0.237106). The first term of $`(\mathcal{L}_X g)_{\theta\theta}`$, divided by $`R^2`$, is +0.950546: the spin carries New York south, where circles of latitude are longer. The stretch term is −0.950546: the spin squeezes the east-west step by exactly as much. They cancel.

The code checks all five fields a second way, by the definition. It moves two nearby points in space, measures the squared chord between them before and after, and divides. The two roads agree to 0.000000019 for every field. The slide south gives $`(\mathcal{L}_X g)_{\theta\theta}`$ = 0.988823 $`R^2`$, and the twist gives $`(\mathcal{L}_X g)_{\varphi\theta}`$ = 0.374758 $`R^2`$.

### Step 3: find all of them

Write the three equations on the globe, divided by $`R^2`$:

```math
\partial_\varphi X^\varphi = 0, \qquad \sin\varphi\cos\varphi\, X^\varphi + \sin^2\!\varphi\;\partial_\theta X^\theta = 0, \qquad \partial_\theta X^\varphi + \sin^2\!\varphi\;\partial_\varphi X^\theta = 0
```

The first says $`X^\varphi`$ depends on longitude only. The second then fixes how $`X^\theta`$ changes with longitude. The third ties the two together. Solving them leaves exactly three free constants, $`\omega_x`$, $`\omega_y`$ and $`\omega_z`$, in the formula above.

<details>
<summary>Detailed proof: the three equations leave three constants</summary>

The first equation gives $`X^\varphi = A'(\theta)`$ for some function $`A`$ of longitude, written as a derivative for convenience. The second gives $`\partial_\theta X^\theta = -\cot\varphi\, A'(\theta)`$, so

$`\displaystyle X^\theta = -\cot\varphi\, A(\theta) + B(\varphi)`$

for some function $`B`$ of $`\varphi`$ alone. Put both into the third equation. Since $`\partial_\varphi(-\cot\varphi) = 1/\sin^2\varphi`$, it reads

$`\displaystyle A''(\theta) + A(\theta) = -\sin^2\!\varphi\; B'(\varphi)`$

The left side depends on $`\theta`$ only and the right side on $`\varphi`$ only, so both equal one constant $`k`$. Then $`B = k\cot\varphi + c`$ and $`A = k + \omega_x \cos\theta + \omega_y \sin\theta`$ for constants $`c`$, $`\omega_x`$, $`\omega_y`$. The $`k`$ terms cancel in $`X^\theta`$, and with $`c = \omega_z`$:

$`\displaystyle X^\varphi = \omega_y\cos\theta - \omega_x\sin\theta, \qquad X^\theta = \omega_z - \cot\varphi\,(\omega_x\cos\theta + \omega_y\sin\theta)`$

Each of the three is a spin about an axis, so each extends smoothly over the poles. All three survive on the whole globe.

</details>

The code counts a second way, without solving anything. It builds 50 trial fields from products of $`1, \sin\varphi, \cos\varphi, \cot\varphi, 1/\sin\varphi`$ with $`1, \cos\theta, \sin\theta, \cos 2\theta, \sin 2\theta`$. It imposes the three equations at 48 points and counts the independent solutions by elimination. The count is 3, and the three spins lie in the family, so they are exactly the solutions it contains. The count alone covers only the family; the proof above covers every field.

Three is the most any connected surface can have. A Killing field is fixed by its arrow at one point and by how fast it turns there: two numbers plus one in two dimensions, $`n(n+1)/2`$ in $`n`$ dimensions. This card states that bound and cites its proof (Sources: Petersen).

### Step 4: the flattened Earth keeps only one

The real Earth bulges at the equator: radius 6378.137 km there, 6356.752 km at the poles. A quarter turn about the x-axis would carry the North Pole into the equator's plane, still 6356.752 km from the centre, while the true equator sits at 6378.137 km. The pole lands 21.385 km inside the surface, so that spin is no symmetry.

The same 50 trial fields, with the flattened metric, give 1 solution: the polar spin, as the proof below shows for every field.

<details>
<summary>Detailed proof: only the polar spin survives the flattening</summary>

Use the chart $`r = (a\sin\varphi\cos\theta,\ a\sin\varphi\sin\theta,\ b\cos\varphi)`$, with $`a > b`$. Its table is $`g_{\varphi\varphi} = a^2\cos^2\varphi + b^2\sin^2\varphi`$, $`g_{\theta\theta} = a^2\sin^2\varphi`$, $`g_{\varphi\theta} = 0`$, and its Gaussian curvature is

$`\displaystyle K = \frac{b^2}{(a^2\cos^2\varphi + b^2\sin^2\varphi)^2}`$

A Killing flow is made of isometries, which keep $`K`$ ([Theorema Egregium](../02-Surfaces/08-theorema-egregium.md)). So $`X^\varphi\,\partial_\varphi K = 0`$. Here $`K`$ changes with $`\varphi`$ everywhere except at the poles and the equator, so $`X^\varphi = 0`$ there, and by continuity everywhere. The off-diagonal equation becomes $`g_{\theta\theta}\,\partial_\varphi X^\theta = 0`$, so $`X^\theta`$ depends on $`\theta`$ only. The $`\theta\theta`$ equation becomes $`2g_{\theta\theta}\,\partial_\theta X^\theta = 0`$, so $`X^\theta`$ is a constant. That constant times $`\partial_\theta`$ is the polar spin.

</details>

### Step 5: the three spins are the rotation group's Lie algebra

The bracket of two fields, $`[X, Y]`$, measures how their flows fail to commute. The code computes it at New York in the chart: [spin about x, spin about y] = (0, −1), which is minus the spin about z.

This is the cross-product table of [Lie algebra](02-lie-algebras-and-the-exponential-map.md), $`[L_x, L_y] = L_z`$, with the sign flipped. The flip is the usual one between brackets of matrices and brackets of the fields they generate. So the Killing fields of the globe form a copy of $`\mathfrak{so}(3)`$: they are the turn rates of the rotation group $`SO(3)`$, acting on the globe as on [Group action and homogeneous space](06-homogeneous-spaces-and-group-actions.md). $`SO(3)`$ is the part of the globe's isometry group (all its distance-keeping maps) that can be reached by moving continuously from doing nothing; mirror images keep distances too, but no flow reaches them.

### Step 6: each Killing field gives a number kept along every straight route

Along a geodesic (a locally shortest path) with unit tangent $`T`$, the number $`g(X, T)`$ stays fixed when $`X`$ is Killing. The reason is short: the geodesic does not turn, and a Killing field's rate of change is a pure rotation, which gives no component along $`T`$. [Noether](08-noethers-theorem.md) turns this into the general rule linking symmetries to conserved quantities.

For the polar spin, $`g(X, T) = R\sin\varphi\,\sin\alpha`$, where $`\alpha`$ is the heading: the distance from the axis times the sine of the heading. This is Clairaut's relation, proved on [Geodesic on a surface](../02-Surfaces/09-geodesics-on-surfaces.md). On the London–New York great circle it is −3764.20 km at the start, halfway and the end, though the heading turns from 288.33° through 255.39° to 231.21°.

The constant also finds the route's highest latitude. There the heading is due west, $`\sin\alpha = -1`$, so $`R\sin\varphi`$ = 3764.20 km. That gives 53.78° N, the same peak found by adding up the metric on [Riemannian metric](../05-Riemannian%20Geometry/01-riemannian-metrics.md).

---

## Worked numbers, by hand

The spin about the x-axis, tested at New York.

| Step | Arithmetic | Value |
| --- | --- | --- |
| New York's $`\varphi`$ | 90 − 40.7128 | 49.2872° |
| $`X^\varphi`$ | $`-\sin(-74.0060°)`$ | 0.961291 |
| $`X^\theta`$ | $`-\cot 49.2872° \times \cos(-74.0060°)`$ | −0.237106 |
| table term, over $`R^2`$ | $`X^\varphi \times 2\sin\varphi\cos\varphi`$ = 0.961291 × 0.988823 | +0.950546 |
| stretch term, over $`R^2`$ | $`2\sin^2\varphi\;\partial_\theta X^\theta = 2\sin\varphi\cos\varphi\sin\theta`$ | −0.950546 |
| $`(\mathcal{L}_X g)_{\theta\theta}`$ | sum of the two | **0** |
| London–New York after 0.5 unit of spin | great-circle distance of the moved points | **5570.22 km** |
| independent Killing fields, round globe | elimination over 50 trial fields | **3** |

The spin moves New York south and squeezes its east-west steps by the same amount, so no length changes: the spin is a symmetry, and one of exactly three.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Slide every point 0.5 rad south | 7855.38 km; $`(\mathcal{L}_X g)_{\theta\theta}`$ = 0.988823 $`R^2`$ | Equal steps in $`\varphi`$ carry points onto longer circles of latitude |
| Twist: polar spin times $`\sin\varphi`$ | 5313.35 km; $`(\mathcal{L}_X g)_{\varphi\theta}`$ = 0.374758 $`R^2`$ | A Killing field times a function shears neighbouring latitudes |
| Test only the table term $`X^k\partial_k g_{ij}`$ | +0.950546 $`R^2`$ for the x-spin, a true symmetry | The two stretch terms were dropped |
| Tilted spin on the flattened Earth | pole 21.385 km below the surface; count 1, not 3 | The round model's symmetry is not the real Earth's |

The code prints all four.

---

## Code, from first principles, and it actually runs

The code tests five fields on a globe of radius 6371 km. It takes four independent roads. First, the chart formula for $`\mathcal{L}_X g`$ against the definition, done by moving pairs of nearby points in space with Rodrigues' turn formula (the rule for turning a point about an axis) and timing their squared chords. Second, London–New York distances after a finite motion. Third, a count of all Killing fields by elimination over 50 trial fields, on the round globe and on the flattened Earth. Fourth, Clairaut's number at three points of the great circle, with the bracket of two spins as a cross-check on the Lie algebra.

### Python

```python
# Killing fields -- the check behind the card.  Standard library only.
# The globe is a sphere of radius 6371 km in the chart (phi, theta): phi is the
# angle down from the North Pole, theta the longitude east, both in radians.
# Each field is tested by the chart formula for L_X g, by moving real points
# in space, and by counting every solution of the Killing equation.
from math import sin, cos, acos, asin, atan2, sqrt, radians, degrees, pi
R = 6371.0
LON = (radians(90 - 51.5074), radians(-0.1278))         # London (phi, theta)
NYC = (radians(90 - 40.7128), radians(-74.0060))        # New York (phi, theta)
A_WGS, B_WGS = 6378.137, 6378.137 * (1 - 1 / 298.257223563)   # the real Earth, km

def embed(p):                                           # chart point -> space, km
    f, t = p
    return (R * sin(f) * cos(t), R * sin(f) * sin(t), R * cos(f))
def turn(k, s, v):                                      # Rodrigues: turn v by s rad about unit k
    c = (k[1]*v[2] - k[2]*v[1], k[2]*v[0] - k[0]*v[2], k[0]*v[1] - k[1]*v[0])
    d = sum(a * b for a, b in zip(k, v))
    return tuple(v[i]*cos(s) + c[i]*sin(s) + k[i]*d*(1 - cos(s)) for i in range(3))
def dist(u, v):                                         # great-circle distance between space points, km
    return R * acos(max(-1.0, min(1.0, sum(a * b for a, b in zip(u, v)) / R**2)))

# name, field X = (X^phi, X^theta) in rad per unit time, its flow in space
FIELDS = [
    ("spin about the polar axis z", lambda p: (0.0, 1.0), lambda p, s: turn((0, 0, 1), s, embed(p))),
    ("spin about the axis x", lambda p: (-sin(p[1]), -cos(p[0]) / sin(p[0]) * cos(p[1])),
     lambda p, s: turn((1, 0, 0), s, embed(p))),
    ("spin about the axis y", lambda p: (cos(p[1]), -cos(p[0]) / sin(p[0]) * sin(p[1])),
     lambda p, s: turn((0, 1, 0), s, embed(p))),
    ("slide south", lambda p: (1.0, 0.0), lambda p, s: embed((p[0] + s, p[1]))),
    ("twist, rate sin(phi)", lambda p: (0.0, sin(p[0])), lambda p, s: embed((p[0], p[1] + s * sin(p[0])))),
]

def lie_formula(X, p):      # (L_X g)_ij / R^2 from the chart formula, g11 = 1, g22 = sin^2 phi
    h, (f, t) = 1e-5, p
    P, Q = X(p)
    Pf = (X((f + h, t))[0] - X((f - h, t))[0]) / (2 * h)
    Pt = (X((f, t + h))[0] - X((f, t - h))[0]) / (2 * h)
    Qf = (X((f + h, t))[1] - X((f - h, t))[1]) / (2 * h)
    Qt = (X((f, t + h))[1] - X((f, t - h))[1]) / (2 * h)
    return (2 * Pf, P * 2 * sin(f) * cos(f) + 2 * sin(f)**2 * Qt, Pt + sin(f)**2 * Qf), P * 2 * sin(f) * cos(f)

def lie_flow(flow, p):      # the definition: rate of change of squared tiny lengths under the flow
    h, t = 1e-4, 1e-4
    def q(u):
        a = (p[0] - h * u[0] / 2, p[1] - h * u[1] / 2)
        b = (p[0] + h * u[0] / 2, p[1] + h * u[1] / 2)
        d = lambda s: sum((x - y)**2 for x, y in zip(flow(a, s), flow(b, s)))
        return (d(t) - d(-t)) / (2 * t * h * h * R * R)
    q11, q22 = q((1, 0)), q((0, 1))
    return (q11, q22, (q((1, 1)) - q11 - q22) / 2)

def count_killing(a, b, steps=(8, 6)):   # nullity of the Killing equation over 50 trial fields
    FB = [lambda f: (1.0, 0.0), lambda f: (sin(f), cos(f)), lambda f: (cos(f), -sin(f)),
          lambda f: (cos(f) / sin(f), -1 / sin(f)**2), lambda f: (1 / sin(f), -cos(f) / sin(f)**2)]
    TB = [lambda t, k=k: (cos(k * t), -k * sin(k * t)) for k in (0, 1, 2)] + \
         [lambda t, k=k: (sin(k * t), k * cos(k * t)) for k in (1, 2)]
    rows = []
    for i in range(steps[0]):
        for j in range(steps[1]):
            f, t = 0.3 + 2.5 * i / (steps[0] - 1), 2 * pi * j / steps[1]
            g11, g22 = a*a*cos(f)**2 + b*b*sin(f)**2, a*a*sin(f)**2
            d11, d22 = 2 * (b*b - a*a) * sin(f) * cos(f), 2 * a*a * sin(f) * cos(f)
            r11, r22, r12 = [], [], []
            for comp in (0, 1):
                for F in FB:
                    for T in TB:
                        (u, uf), (v, vt) = F(f), T(t)
                        U, Uf, Ut = u * v, uf * v, u * vt
                        r11.append(U * d11 + 2 * g11 * Uf if comp == 0 else 0.0)
                        r22.append(U * d22 if comp == 0 else 2 * g22 * Ut)
                        r12.append(g11 * Ut if comp == 0 else g22 * Uf)
            rows += [r11, r22, r12]
    rank, n = 0, len(rows[0])
    scale = max(abs(x) for r in rows for x in r)
    for c in range(n):                                  # Gaussian elimination, partial pivoting
        piv = max(range(rank, len(rows)), key=lambda r: abs(rows[r][c]))
        if abs(rows[piv][c]) < 1e-9 * scale:
            continue
        rows[rank], rows[piv] = rows[piv], rows[rank]
        for r in range(rank + 1, len(rows)):
            m = rows[r][c] / rows[rank][c]
            rows[r] = [x - m * y for x, y in zip(rows[r], rows[rank])]
        rank += 1
    return n - rank

fmt = lambda v: "(" + ", ".join(f"{(x if abs(x) > 5e-7 else 0.0):+.6f}" for x in v) + ")"
print("L_X g at New York divided by R^2, components (11, 22, 12):")
worst, results = 0.0, {}
for name, X, flow in FIELDS:
    a, naive = lie_formula(X, NYC)
    b = lie_flow(flow, NYC)
    worst = max(worst, max(abs(x - y) for x, y in zip(a, b)))
    d = dist(flow(LON, 0.5), flow(NYC, 0.5))
    results[name] = (a, naive, d)
    print(f"  {name:<28} formula {fmt(a)}  moving points {fmt(b)}")
print(f"largest gap between the two roads: {worst:.9f}")
d0 = dist(embed(LON), embed(NYC))
print(f"London-New York before any flow: {d0:.2f} km; after 0.5 unit of each flow:")
for name, (a, naive, d) in results.items():
    print(f"  {name:<28} |{'#' * round(d / 250):<32}{d:.2f} km   Killing: {'yes' if max(map(abs, a)) < 1e-6 else 'no'}")
print(f"6 sidereal hours of Earth spin (pi/2 rad): {dist(FIELDS[0][2](LON, pi/2), FIELDS[0][2](NYC, pi/2)):.2f} km")

Px, Qx = FIELDS[1][1](NYC)
print(f"spin about x at New York: X = ({Px:+.6f}, {Qx:+.6f}); naive term X^phi d_phi g_22 = "
      f"{results['spin about the axis x'][1]:+.6f}, stretch term {2 * sin(NYC[0]) * cos(NYC[0]) * sin(NYC[1]):+.6f}")
X1, X2 = FIELDS[1][1], FIELDS[2][1]                       # bracket [X, Y]^k = X^i d_i Y^k - Y^i d_i X^k
def grad(Y, p, k, h=1e-5):
    return ((Y((p[0] + h, p[1]))[k] - Y((p[0] - h, p[1]))[k]) / (2 * h),
            (Y((p[0], p[1] + h))[k] - Y((p[0], p[1] - h))[k]) / (2 * h))
br = [sum(X1(NYC)[i] * grad(X2, NYC, k)[i] - X2(NYC)[i] * grad(X1, NYC, k)[i] for i in (0, 1)) for k in (0, 1)]
print(f"bracket [spin x, spin y] at New York, in the chart: {fmt(br)} = minus the spin about z")
n_sphere, n_egg = count_killing(1.0, 1.0), count_killing(A_WGS / R, B_WGS / R)
print(f"Killing fields among 50 trial fields: round globe {n_sphere}, flattened Earth {n_egg}; most possible in 2D: {2 * 3 // 2}")
pole = turn((1, 0, 0), pi / 2, (0.0, 0.0, B_WGS))
print(f"flattened Earth, North Pole turned 90 deg about x: {sqrt(sum(x * x for x in pole)):.3f} km from the centre,"
      f" equator at {A_WGS:.3f} km, off the surface by {A_WGS - B_WGS:.3f} km")
OMEGA = 2 * pi / 86164.0905                              # Earth's spin, rad/s: one turn per sidereal day
print(f"Earth's spin field: one turn per {86164.0905:.4f} s, {OMEGA * 1e5:.6f} x 10^-5 rad/s; ground speed London {R * sin(LON[0]) * OMEGA * 1000:.1f} m/s,"
      f" New York {R * sin(NYC[0]) * OMEGA * 1000:.1f} m/s, pole 0.0 m/s")
A, B = embed(LON), embed(NYC)                             # Clairaut: the polar spin's conserved number
c = acos(sum(x * y for x, y in zip(A, B)) / R**2)
clair = []
for s in (0.0, 0.5, 1.0):
    r = [(sin((1 - s) * c) * a + sin(s * c) * b) / sin(c) for a, b in zip(A, B)]
    T = [-cos((1 - s) * c) * a + cos(s * c) * b for a, b in zip(A, B)]
    T = [x / sqrt(sum(y * y for y in T)) for x in T]
    f, t = acos(r[2] / R), atan2(r[1], r[0])
    east, north = (-sin(t), cos(t), 0.0), (-cos(f) * cos(t), -cos(f) * sin(t), sin(f))
    head = atan2(sum(x * y for x, y in zip(T, east)), sum(x * y for x, y in zip(T, north))) % (2 * pi)
    clair.append(R * sin(f) * sin(head))
    print(f"great circle at {s:.1f} of the way: latitude {90 - degrees(f):.2f} deg, heading {degrees(head):.2f} deg,"
          f" g(spin z, T) = R sin(phi) sin(heading) = {clair[-1]:.2f} km")
print(f"highest latitude on the route, where the heading is due west: {90 - degrees(asin(-clair[0] / R)):.2f} deg")
assert worst < 1e-6                                                  # formula against moving points
assert all(abs(results[n][2] - d0) < 1e-6 for n, _, _ in FIELDS[:3])   # spins keep the distance
assert abs(results["slide south"][2] - d0) > 100 and abs(results["twist, rate sin(phi)"][2] - d0) > 100
assert n_sphere == 3 and n_egg == 1                                  # two counts of the symmetries
assert abs(br[0]) < 1e-6 and abs(br[1] + 1) < 1e-6                   # [X_x, X_y] = -X_z
assert max(clair) - min(clair) < 1e-6                                # conserved along the geodesic
print("ALL CHECKS PASS")
```

**Ran 2026-11-19 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
L_X g at New York divided by R^2, components (11, 22, 12):
  spin about the polar axis z  formula (+0.000000, +0.000000, +0.000000)  moving points (+0.000000, +0.000000, +0.000000)
  spin about the axis x        formula (+0.000000, +0.000000, +0.000000)  moving points (+0.000000, +0.000000, +0.000000)
  spin about the axis y        formula (+0.000000, +0.000000, +0.000000)  moving points (+0.000000, +0.000000, +0.000000)
  slide south                  formula (+0.000000, +0.988823, +0.000000)  moving points (+0.000000, +0.988823, +0.000000)
  twist, rate sin(phi)         formula (+0.000000, +0.000000, +0.374758)  moving points (+0.000000, +0.000000, +0.374758)
largest gap between the two roads: 0.000000019
London-New York before any flow: 5570.22 km; after 0.5 unit of each flow:
  spin about the polar axis z  |######################          5570.22 km   Killing: yes
  spin about the axis x        |######################          5570.22 km   Killing: yes
  spin about the axis y        |######################          5570.22 km   Killing: yes
  slide south                  |############################### 7855.38 km   Killing: no
  twist, rate sin(phi)         |#####################           5313.35 km   Killing: no
6 sidereal hours of Earth spin (pi/2 rad): 5570.22 km
spin about x at New York: X = (+0.961291, -0.237106); naive term X^phi d_phi g_22 = +0.950546, stretch term -0.950546
bracket [spin x, spin y] at New York, in the chart: (+0.000000, -1.000000) = minus the spin about z
Killing fields among 50 trial fields: round globe 3, flattened Earth 1; most possible in 2D: 3
flattened Earth, North Pole turned 90 deg about x: 6356.752 km from the centre, equator at 6378.137 km, off the surface by 21.385 km
Earth's spin field: one turn per 86164.0905 s, 7.292116 x 10^-5 rad/s; ground speed London 289.2 m/s, New York 352.1 m/s, pole 0.0 m/s
great circle at 0.0 of the way: latitude 51.51 deg, heading 288.33 deg, g(spin z, T) = R sin(phi) sin(heading) = -3764.20 km
great circle at 0.5 of the way: latitude 52.37 deg, heading 255.39 deg, g(spin z, T) = R sin(phi) sin(heading) = -3764.20 km
great circle at 1.0 of the way: latitude 40.71 deg, heading 231.21 deg, g(spin z, T) = R sin(phi) sin(heading) = -3764.20 km
highest latitude on the route, where the heading is due west: 53.78 deg
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Killing fields -- the same check as the Python, in Rust.  No crates.
// The globe is a sphere of radius 6371 km in the chart (phi, theta): phi is the
// angle down from the North Pole, theta the longitude east, both in radians.
// Each field is tested by the chart formula for L_X g, by moving real points
// in space, and by counting every solution of the Killing equation.
use std::f64::consts::PI;
const R: f64 = 6371.0;
type P = (f64, f64);
const NAMES: [&str; 5] = ["spin about the polar axis z", "spin about the axis x", "spin about the axis y",
                          "slide south", "twist, rate sin(phi)"];

fn embed(p: P) -> [f64; 3] { [R * p.0.sin() * p.1.cos(), R * p.0.sin() * p.1.sin(), R * p.0.cos()] }
fn dot(a: &[f64; 3], b: &[f64; 3]) -> f64 { a[0] * b[0] + a[1] * b[1] + a[2] * b[2] }
fn turn(k: [f64; 3], s: f64, v: [f64; 3]) -> [f64; 3] {         // Rodrigues: turn v by s rad about unit k
    let c = [k[1] * v[2] - k[2] * v[1], k[2] * v[0] - k[0] * v[2], k[0] * v[1] - k[1] * v[0]];
    let d = dot(&k, &v);
    [0, 1, 2].map(|i| v[i] * s.cos() + c[i] * s.sin() + k[i] * d * (1.0 - s.cos()))
}
fn dist(u: [f64; 3], v: [f64; 3]) -> f64 { R * (dot(&u, &v) / (R * R)).clamp(-1.0, 1.0).acos() }
fn field(i: usize, p: P) -> P {                                  // X = (X^phi, X^theta), rad per unit time
    let cot = p.0.cos() / p.0.sin();
    match i { 0 => (0.0, 1.0), 1 => (-p.1.sin(), -cot * p.1.cos()), 2 => (p.1.cos(), -cot * p.1.sin()),
              3 => (1.0, 0.0), _ => (0.0, p.0.sin()) }
}
fn flow(i: usize, p: P, s: f64) -> [f64; 3] {                    // the field's flow, as points in space
    match i { 0 => turn([0.0, 0.0, 1.0], s, embed(p)), 1 => turn([1.0, 0.0, 0.0], s, embed(p)),
              2 => turn([0.0, 1.0, 0.0], s, embed(p)), 3 => embed((p.0 + s, p.1)),
              _ => embed((p.0, p.1 + s * p.0.sin())) }
}
fn grad(i: usize, p: P, k: usize) -> P {                         // d/dphi and d/dtheta of component k
    let h = 1e-5;
    let c = |q: P| { let x = field(i, q); if k == 0 { x.0 } else { x.1 } };
    ((c((p.0 + h, p.1)) - c((p.0 - h, p.1))) / (2.0 * h), (c((p.0, p.1 + h)) - c((p.0, p.1 - h))) / (2.0 * h))
}
fn lie_formula(i: usize, p: P) -> ([f64; 3], f64) {    // (L_X g)_ij / R^2 from the chart formula
    let (f, (pp, _)) = (p.0, field(i, p));
    let ((pf, pt), (qf, qt)) = (grad(i, p, 0), grad(i, p, 1));
    ([2.0 * pf, pp * 2.0 * f.sin() * f.cos() + 2.0 * f.sin().powi(2) * qt, pt + f.sin().powi(2) * qf],
     pp * 2.0 * f.sin() * f.cos())
}
fn lie_flow(i: usize, p: P) -> [f64; 3] {    // the definition: rate of change of squared tiny lengths
    let (h, t) = (1e-4, 1e-4);
    let q = |u: P| {
        let a = (p.0 - h * u.0 / 2.0, p.1 - h * u.1 / 2.0);
        let b = (p.0 + h * u.0 / 2.0, p.1 + h * u.1 / 2.0);
        let d = |s: f64| { let (x, y) = (flow(i, a, s), flow(i, b, s)); (0..3).map(|k| (x[k] - y[k]).powi(2)).sum::<f64>() };
        (d(t) - d(-t)) / (2.0 * t * h * h * R * R)
    };
    let (q11, q22) = (q((1.0, 0.0)), q((0.0, 1.0)));
    [q11, q22, (q((1.0, 1.0)) - q11 - q22) / 2.0]
}
fn count_killing(a: f64, b: f64) -> usize {   // nullity of the Killing equation over 50 trial fields
    let fb = |n: usize, f: f64| -> P { match n { 0 => (1.0, 0.0), 1 => (f.sin(), f.cos()), 2 => (f.cos(), -f.sin()),
        3 => (f.cos() / f.sin(), -1.0 / f.sin().powi(2)), _ => (1.0 / f.sin(), -f.cos() / f.sin().powi(2)) } };
    let tb = |n: usize, t: f64| -> P { let k = [0.0, 1.0, 2.0, 1.0, 2.0][n];
        if n < 3 { ((k * t).cos(), -k * (k * t).sin()) } else { ((k * t).sin(), k * (k * t).cos()) } };
    let mut rows: Vec<Vec<f64>> = Vec::new();
    for i in 0..8 { for j in 0..6 {
        let (f, t) = (0.3 + 2.5 * i as f64 / 7.0, 2.0 * PI * j as f64 / 6.0);
        let (g11, g22) = (a * a * f.cos().powi(2) + b * b * f.sin().powi(2), a * a * f.sin().powi(2));
        let (d11, d22) = (2.0 * (b * b - a * a) * f.sin() * f.cos(), 2.0 * a * a * f.sin() * f.cos());
        let (mut r11, mut r22, mut r12) = (vec![], vec![], vec![]);
        for comp in 0..2 { for fi in 0..5 { for ti in 0..5 {
            let ((u, uf), (v, vt)) = (fb(fi, f), tb(ti, t));
            let (uu, ufv, utv) = (u * v, uf * v, u * vt);
            r11.push(if comp == 0 { uu * d11 + 2.0 * g11 * ufv } else { 0.0 });
            r22.push(if comp == 0 { uu * d22 } else { 2.0 * g22 * utv });
            r12.push(if comp == 0 { g11 * utv } else { g22 * ufv });
        } } }
        rows.push(r11); rows.push(r22); rows.push(r12);
    } }
    let (mut rank, n) = (0, rows[0].len());
    let scale = rows.iter().flatten().fold(0.0f64, |m, x| m.max(x.abs()));
    for c in 0..n {                                              // Gaussian elimination, partial pivoting
        let mut piv = rank;
        for r in rank..rows.len() { if rows[r][c].abs() > rows[piv][c].abs() { piv = r } }
        if rows[piv][c].abs() < 1e-9 * scale { continue }
        rows.swap(rank, piv);
        for r in rank + 1..rows.len() {
            let m = rows[r][c] / rows[rank][c];
            for k in 0..n { rows[r][k] -= m * rows[rank][k] }
        }
        rank += 1;
    }
    n - rank
}
fn fmt(v: &[f64]) -> String {
    let s: Vec<String> = v.iter().map(|&x| format!("{:+.6}", if x.abs() > 5e-7 { x } else { 0.0 })).collect();
    format!("({})", s.join(", "))
}

fn main() {
    let lon: P = ((90.0f64 - 51.5074).to_radians(), (-0.1278f64).to_radians());    // London (phi, theta)
    let nyc: P = ((90.0f64 - 40.7128).to_radians(), (-74.0060f64).to_radians());   // New York (phi, theta)
    let (a_wgs, b_wgs) = (6378.137, 6378.137 * (1.0 - 1.0 / 298.257223563));       // the real Earth, km
    println!("L_X g at New York divided by R^2, components (11, 22, 12):");
    let (mut worst, mut res) = (0.0f64, vec![]);
    for i in 0..5 {
        let (a, naive) = lie_formula(i, nyc);
        let b = lie_flow(i, nyc);
        for k in 0..3 { worst = worst.max((a[k] - b[k]).abs()) }
        res.push((a, naive, dist(flow(i, lon, 0.5), flow(i, nyc, 0.5))));
        println!("  {:<28} formula {}  moving points {}", NAMES[i], fmt(&a), fmt(&b));
    }
    println!("largest gap between the two roads: {:.9}", worst);
    let d0 = dist(embed(lon), embed(nyc));
    println!("London-New York before any flow: {:.2} km; after 0.5 unit of each flow:", d0);
    for i in 0..5 {
        let k = res[i].0.iter().all(|x| x.abs() < 1e-6);
        let bar = "#".repeat((res[i].2 / 250.0).round() as usize);
        println!("  {:<28} |{:<32}{:.2} km   Killing: {}", NAMES[i], bar, res[i].2, if k { "yes" } else { "no" });
    }
    println!("6 sidereal hours of Earth spin (pi/2 rad): {:.2} km", dist(flow(0, lon, PI / 2.0), flow(0, nyc, PI / 2.0)));
    let (px, qx) = field(1, nyc);
    println!("spin about x at New York: X = ({:+.6}, {:+.6}); naive term X^phi d_phi g_22 = {:+.6}, stretch term {:+.6}",
             px, qx, res[1].1, 2.0 * nyc.0.sin() * nyc.0.cos() * nyc.1.sin());
    let (x1, x2) = (field(1, nyc), field(2, nyc));             // bracket [X, Y]^k = X^i d_i Y^k - Y^i d_i X^k
    let br: Vec<f64> = (0..2).map(|k| { let (g2, g1) = (grad(2, nyc, k), grad(1, nyc, k));
        x1.0 * g2.0 + x1.1 * g2.1 - (x2.0 * g1.0 + x2.1 * g1.1) }).collect();
    println!("bracket [spin x, spin y] at New York, in the chart: {} = minus the spin about z", fmt(&br));
    let (n_sphere, n_egg) = (count_killing(1.0, 1.0), count_killing(a_wgs / R, b_wgs / R));
    println!("Killing fields among 50 trial fields: round globe {}, flattened Earth {}; most possible in 2D: {}", n_sphere, n_egg, 2 * 3 / 2);
    let pole = turn([1.0, 0.0, 0.0], PI / 2.0, [0.0, 0.0, b_wgs]);
    println!("flattened Earth, North Pole turned 90 deg about x: {:.3} km from the centre, equator at {:.3} km, off the surface by {:.3} km",
             dot(&pole, &pole).sqrt(), a_wgs, a_wgs - b_wgs);
    let omega = 2.0 * PI / 86164.0905;                          // Earth's spin, rad/s: one turn per sidereal day
    println!("Earth's spin field: one turn per {:.4} s, {:.6} x 10^-5 rad/s; ground speed London {:.1} m/s, New York {:.1} m/s, pole 0.0 m/s",
             86164.0905, omega * 1e5, R * lon.0.sin() * omega * 1000.0, R * nyc.0.sin() * omega * 1000.0);
    let (a, b) = (embed(lon), embed(nyc));                      // Clairaut: the polar spin's conserved number
    let c = (dot(&a, &b) / (R * R)).acos();
    let mut clair: Vec<f64> = vec![];
    for s in [0.0, 0.5, 1.0f64] {
        let r = [0, 1, 2].map(|k| (((1.0 - s) * c).sin() * a[k] + (s * c).sin() * b[k]) / c.sin());
        let t0 = [0, 1, 2].map(|k| -((1.0 - s) * c).cos() * a[k] + (s * c).cos() * b[k]);
        let tn = dot(&t0, &t0).sqrt();
        let tv = t0.map(|x| x / tn);
        let (f, t) = ((r[2] / R).acos(), r[1].atan2(r[0]));
        let (east, north) = ([-t.sin(), t.cos(), 0.0], [-f.cos() * t.cos(), -f.cos() * t.sin(), f.sin()]);
        let head = dot(&tv, &east).atan2(dot(&tv, &north)).rem_euclid(2.0 * PI);
        clair.push(R * f.sin() * head.sin());
        println!("great circle at {:.1} of the way: latitude {:.2} deg, heading {:.2} deg, g(spin z, T) = R sin(phi) sin(heading) = {:.2} km",
                 s, 90.0 - f.to_degrees(), head.to_degrees(), clair[clair.len() - 1]);
    }
    println!("highest latitude on the route, where the heading is due west: {:.2} deg", 90.0 - (-clair[0] / R).asin().to_degrees());
    assert!(worst < 1e-6);                                                      // formula against moving points
    assert!((0..3).all(|i| (res[i].2 - d0).abs() < 1e-6));                      // spins keep the distance
    assert!((res[3].2 - d0).abs() > 100.0 && (res[4].2 - d0).abs() > 100.0);
    assert!(n_sphere == 3 && n_egg == 1);                                       // two counts of the symmetries
    assert!(br[0].abs() < 1e-6 && (br[1] + 1.0).abs() < 1e-6);                  // [X_x, X_y] = -X_z
    let (mx, mn) = clair.iter().fold((f64::MIN, f64::MAX), |(a, b), &x| (a.max(x), b.min(x)));
    assert!(mx - mn < 1e-6);                                                    // conserved along the geodesic
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-19 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
L_X g at New York divided by R^2, components (11, 22, 12):
  spin about the polar axis z  formula (+0.000000, +0.000000, +0.000000)  moving points (+0.000000, +0.000000, +0.000000)
  spin about the axis x        formula (+0.000000, +0.000000, +0.000000)  moving points (+0.000000, +0.000000, +0.000000)
  spin about the axis y        formula (+0.000000, +0.000000, +0.000000)  moving points (+0.000000, +0.000000, +0.000000)
  slide south                  formula (+0.000000, +0.988823, +0.000000)  moving points (+0.000000, +0.988823, +0.000000)
  twist, rate sin(phi)         formula (+0.000000, +0.000000, +0.374758)  moving points (+0.000000, +0.000000, +0.374758)
largest gap between the two roads: 0.000000019
London-New York before any flow: 5570.22 km; after 0.5 unit of each flow:
  spin about the polar axis z  |######################          5570.22 km   Killing: yes
  spin about the axis x        |######################          5570.22 km   Killing: yes
  spin about the axis y        |######################          5570.22 km   Killing: yes
  slide south                  |############################### 7855.38 km   Killing: no
  twist, rate sin(phi)         |#####################           5313.35 km   Killing: no
6 sidereal hours of Earth spin (pi/2 rad): 5570.22 km
spin about x at New York: X = (+0.961291, -0.237106); naive term X^phi d_phi g_22 = +0.950546, stretch term -0.950546
bracket [spin x, spin y] at New York, in the chart: (+0.000000, -1.000000) = minus the spin about z
Killing fields among 50 trial fields: round globe 3, flattened Earth 1; most possible in 2D: 3
flattened Earth, North Pole turned 90 deg about x: 6356.752 km from the centre, equator at 6378.137 km, off the surface by 21.385 km
Earth's spin field: one turn per 86164.0905 s, 7.292116 x 10^-5 rad/s; ground speed London 289.2 m/s, New York 352.1 m/s, pole 0.0 m/s
great circle at 0.0 of the way: latitude 51.51 deg, heading 288.33 deg, g(spin z, T) = R sin(phi) sin(heading) = -3764.20 km
great circle at 0.5 of the way: latitude 52.37 deg, heading 255.39 deg, g(spin z, T) = R sin(phi) sin(heading) = -3764.20 km
great circle at 1.0 of the way: latitude 40.71 deg, heading 231.21 deg, g(spin z, T) = R sin(phi) sin(heading) = -3764.20 km
highest latitude on the route, where the heading is due west: 53.78 deg
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves both counts of Killing fields and the bracket of two spins, in the chart, at every point off the poles.

- Take a smooth field $`X`$ on a round globe of radius $`R > 0`$. Then $`\mathcal{L}_X g = 0`$ exactly when $`X`$ is the spin for exactly one turn rate $`\omega`$. So the round globe has three independent Killing fields.
- Take the flattened Earth with radii $`a > b > 0`$, and a smooth field $`X`$. Then $`\mathcal{L}_X g = 0`$ exactly when $`X = (0, c)`$, the polar spin at one rate $`c`$.
- Take the spin about the x-axis and the spin about the y-axis. Then their bracket is minus the spin about the z-axis, at every point off the poles.
- Take the turn rate $`\omega = (0, 0, 1)`$. Then its spin has components $`(0, 1)`$ everywhere: it is the polar spin.
- Take $`n = 2`$. Then $`n(n+1)/2`$ is exactly 3.

Distances, the moving-point test, the counts over 50 trial fields and Clairaut's number are left to the Python and Rust checks.

```lean
-- Killing field: in the globe's chart, the fields that solve the Killing equation are exactly the spins about axes through the centre, one for each turn rate (three independent ones), on the flattened Earth only the polar spin survives, and two spins bracket to minus the third.
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Analysis.Calculus.FDeriv.Symmetric
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.Analysis.Calculus.Deriv.Prod

open Real Set
open scoped ContDiff

/-! The chart is `(φ, θ)`: a point `p : ℝ × ℝ` has `p.1 = φ`, the angle down from the North
Pole, and `p.2 = θ`, the longitude east, both in radians. Index `0` is `φ` and index `1` is `θ`.
A vector field `X` has components `X 0 = X^φ` and `X 1 = X^θ`. A metric is its table
`g i j`, a function of the point. All are functions on the chart. -/

/-- The chart's unit steps: `0` is a step in `φ`, `1` a step in `θ`. -/
def chartStep : Fin 2 → ℝ × ℝ := ![(1, 0), (0, 1)]

/-- `∂_i f`: the rate of change of `f` along chart direction `i`. -/
noncomputable def pd (i : Fin 2) (f : ℝ × ℝ → ℝ) (p : ℝ × ℝ) : ℝ :=
  fderiv ℝ f p (chartStep i)

/-- The card's chart formula for the Lie derivative of a metric along a field:
`(ℒ_X g)_ij = X^k ∂_k g_ij + g_kj ∂_i X^k + g_ik ∂_j X^k`, summed over `k`. -/
noncomputable def lieDerivMetric (g : Fin 2 → Fin 2 → ℝ × ℝ → ℝ) (X : Fin 2 → ℝ × ℝ → ℝ)
    (i j : Fin 2) (p : ℝ × ℝ) : ℝ :=
  ∑ k : Fin 2, (X k p * pd k (g i j) p + g k j p * pd i (X k) p + g i k p * pd j (X k) p)

/-- The Lie bracket of two fields in the chart: `[X, Y]^k = X^i ∂_i Y^k - Y^i ∂_i X^k`. -/
noncomputable def lieBracketChart (X Y : Fin 2 → ℝ × ℝ → ℝ) (k : Fin 2) (p : ℝ × ℝ) : ℝ :=
  ∑ i : Fin 2, (X i p * pd i (Y k) p - Y i p * pd i (X k) p)

/-- The round globe of radius `R`: `g_φφ = R²`, `g_θθ = R² sin² φ`, `g_φθ = 0`. -/
noncomputable def roundMetric (R : ℝ) : Fin 2 → Fin 2 → ℝ × ℝ → ℝ :=
  fun i j p => !![R ^ 2, 0; 0, R ^ 2 * sin p.1 ^ 2] i j

/-- The flattened Earth with equatorial radius `a` and polar radius `b`, in the chart
`r = (a sin φ cos θ, a sin φ sin θ, b cos φ)`: `g_φφ = a² cos² φ + b² sin² φ`,
`g_θθ = a² sin² φ`, `g_φθ = 0`. -/
noncomputable def flattenedMetric (a b : ℝ) : Fin 2 → Fin 2 → ℝ × ℝ → ℝ :=
  fun i j p => !![a ^ 2 * cos p.1 ^ 2 + b ^ 2 * sin p.1 ^ 2, 0; 0, a ^ 2 * sin p.1 ^ 2] i j

/-- The spin with turn rate `ω = (ωx, ωy, ωz)` about the three axes through the centre:
`X^φ = ωy cos θ - ωx sin θ`, `X^θ = ωz - cot φ (ωx cos θ + ωy sin θ)`. -/
noncomputable def spinField (wx wy wz : ℝ) : Fin 2 → ℝ × ℝ → ℝ :=
  fun k p => ![wy * cos p.2 - wx * sin p.2,
               wz - cos p.1 / sin p.1 * (wx * cos p.2 + wy * sin p.2)] k

/-- The chart's domain: every point of the globe except the two poles, `0 < φ < π`. -/
noncomputable def chartDomain : Set (ℝ × ℝ) := Ioo 0 π ×ˢ univ

/-! Helper lemmas for the proofs below. -/

lemma kf_isOpen_chartDomain : IsOpen chartDomain := isOpen_Ioo.prod isOpen_univ

lemma kf_mem_chartDomain {p : ℝ × ℝ} : p ∈ chartDomain ↔ 0 < p.1 ∧ p.1 < π := by
  simp [chartDomain]

lemma kf_hasDerivAt_pd0 {f : ℝ × ℝ → ℝ} {p : ℝ × ℝ} (hf : DifferentiableAt ℝ f p) :
    HasDerivAt (fun x => f (x, p.2)) (pd 0 f p) p.1 := by
  have h1 : HasDerivAt (fun x : ℝ => (x, p.2)) ((1 : ℝ), (0 : ℝ)) p.1 :=
    HasDerivAt.prodMk (hasDerivAt_id _) (hasDerivAt_const _ _)
  have := hf.hasFDerivAt.comp_hasDerivAt (x := p.1) h1
  have e : pd 0 f p = fderiv ℝ f p ((1 : ℝ), (0 : ℝ)) := by simp [pd, chartStep]
  rw [e]; exact this

lemma kf_hasDerivAt_pd1 {f : ℝ × ℝ → ℝ} {p : ℝ × ℝ} (hf : DifferentiableAt ℝ f p) :
    HasDerivAt (fun y => f (p.1, y)) (pd 1 f p) p.2 := by
  have h1 : HasDerivAt (fun y : ℝ => (p.1, y)) ((0 : ℝ), (1 : ℝ)) p.2 :=
    HasDerivAt.prodMk (hasDerivAt_const _ _) (hasDerivAt_id _)
  have := hf.hasFDerivAt.comp_hasDerivAt (x := p.2) h1
  have e : pd 1 f p = fderiv ℝ f p ((0 : ℝ), (1 : ℝ)) := by simp [pd, chartStep]
  rw [e]; exact this

lemma kf_pd0_eq {f : ℝ × ℝ → ℝ} {p : ℝ × ℝ} {d : ℝ} (hf : DifferentiableAt ℝ f p)
    (h : HasDerivAt (fun x => f (x, p.2)) d p.1) : pd 0 f p = d :=
  (kf_hasDerivAt_pd0 hf).unique h

lemma kf_pd1_eq {f : ℝ × ℝ → ℝ} {p : ℝ × ℝ} {d : ℝ} (hf : DifferentiableAt ℝ f p)
    (h : HasDerivAt (fun y => f (p.1, y)) d p.2) : pd 1 f p = d :=
  (kf_hasDerivAt_pd1 hf).unique h

lemma kf_pd_congr {f g : ℝ × ℝ → ℝ} {p : ℝ × ℝ} (i : Fin 2) (h : f =ᶠ[nhds p] g) :
    pd i f p = pd i g p := by
  simp only [pd, h.fderiv_eq]

lemma kf_pd_congr_dom {f g : ℝ × ℝ → ℝ} {p : ℝ × ℝ} (i : Fin 2) (hp : p ∈ chartDomain)
    (h : ∀ q ∈ chartDomain, f q = g q) : pd i f p = pd i g p :=
  kf_pd_congr i (Filter.eventually_of_mem (kf_isOpen_chartDomain.mem_nhds hp) h)

lemma kf_pd_symm {f : ℝ × ℝ → ℝ} {p : ℝ × ℝ} (hf : ContDiffAt ℝ ∞ f p) :
    pd 0 (pd 1 f) p = pd 1 (pd 0 f) p := by
  have hs := hf.isSymmSndFDerivAt (by simp)
  have hd : DifferentiableAt ℝ (fderiv ℝ f) p :=
    (hf.fderiv_right (m := 1) (by simp)).differentiableAt (by simp)
  have key : ∀ (v w : ℝ × ℝ), fderiv ℝ (fun q => fderiv ℝ f q w) p v = fderiv ℝ (fderiv ℝ f) p v w := by
    intro v w
    have := hd.hasFDerivAt.clm_apply (hasFDerivAt_const w p)
    rw [this.fderiv]
    simp
  show fderiv ℝ (fun q => fderiv ℝ f q (chartStep 1)) p (chartStep 0) =
    fderiv ℝ (fun q => fderiv ℝ f q (chartStep 0)) p (chartStep 1)
  rw [key, key]
  exact hs _ _

lemma kf_pd_differentiableAt {f : ℝ × ℝ → ℝ} {p : ℝ × ℝ} (i : Fin 2) (hf : ContDiffAt ℝ ∞ f p) :
    DifferentiableAt ℝ (pd i f) p := by
  have hd : DifferentiableAt ℝ (fderiv ℝ f) p :=
    (hf.fderiv_right (m := 1) (by simp)).differentiableAt (by simp)
  exact (hd.hasFDerivAt.clm_apply (hasFDerivAt_const (chartStep i) p)).differentiableAt

lemma kf_pd_fst {P : ℝ → ℝ} {P' : ℝ} {p : ℝ × ℝ} (hP : HasDerivAt P P' p.1) :
    pd 0 (fun q => P q.1) p = P' ∧ pd 1 (fun q => P q.1) p = 0 := by
  have hd : DifferentiableAt ℝ (fun q : ℝ × ℝ => P q.1) p :=
    hP.differentiableAt.comp p differentiableAt_fst
  exact ⟨kf_pd0_eq hd hP, kf_pd1_eq hd (hasDerivAt_const p.2 (P p.1))⟩

lemma kf_lie_diag (P Q : ℝ → ℝ) (P' Q' : ℝ) (g : Fin 2 → Fin 2 → ℝ × ℝ → ℝ)
    (hg : g = fun i j q => !![P q.1, 0; 0, Q q.1] i j)
    (X : Fin 2 → ℝ × ℝ → ℝ) (p : ℝ × ℝ)
    (hP : HasDerivAt P P' p.1) (hQ : HasDerivAt Q Q' p.1) :
    lieDerivMetric g X 0 0 p = X 0 p * P' + 2 * P p.1 * pd 0 (X 0) p ∧
    lieDerivMetric g X 1 1 p = X 0 p * Q' + 2 * Q p.1 * pd 1 (X 1) p ∧
    lieDerivMetric g X 0 1 p = P p.1 * pd 1 (X 0) p + Q p.1 * pd 0 (X 1) p ∧
    lieDerivMetric g X 1 0 p = P p.1 * pd 1 (X 0) p + Q p.1 * pd 0 (X 1) p := by
  subst hg
  obtain ⟨h0P, h1P⟩ := kf_pd_fst hP
  obtain ⟨h0Q, h1Q⟩ := kf_pd_fst hQ
  have hz : ∀ k, pd k (fun _ : ℝ × ℝ => (0:ℝ)) p = 0 := by intro k; simp [pd]
  refine ⟨?_, ?_, ?_, ?_⟩ <;>
    simp [lieDerivMetric, Fin.sum_univ_two, h0P, h1P, h0Q, h1Q, hz] <;> ring

lemma kf_spin0 (wx wy wz : ℝ) :
    spinField wx wy wz 0 = fun q => wy * cos q.2 - wx * sin q.2 := by
  funext q; simp [spinField]

lemma kf_spin1 (wx wy wz : ℝ) :
    spinField wx wy wz 1 = fun q => wz - cos q.1 / sin q.1 * (wx * cos q.2 + wy * sin q.2) := by
  funext q; simp [spinField]

lemma kf_spin_pd (wx wy wz : ℝ) {p : ℝ × ℝ} (hs : sin p.1 ≠ 0) :
    pd 0 (spinField wx wy wz 0) p = 0 ∧
    pd 1 (spinField wx wy wz 0) p = -wy * sin p.2 - wx * cos p.2 ∧
    pd 0 (spinField wx wy wz 1) p = (wx * cos p.2 + wy * sin p.2) / sin p.1 ^ 2 ∧
    pd 1 (spinField wx wy wz 1) p = -(cos p.1 / sin p.1) * (-wx * sin p.2 + wy * cos p.2) := by
  rw [kf_spin0, kf_spin1]
  have d0 : DifferentiableAt ℝ (fun q : ℝ × ℝ => wy * cos q.2 - wx * sin q.2) p := by fun_prop
  have d1 : DifferentiableAt ℝ
      (fun q : ℝ × ℝ => wz - cos q.1 / sin q.1 * (wx * cos q.2 + wy * sin q.2)) p := by
    fun_prop (disch := exact hs)
  refine ⟨?_, ?_, ?_, ?_⟩
  · exact kf_pd0_eq d0 (hasDerivAt_const p.1 (wy * cos p.2 - wx * sin p.2))
  · apply kf_pd1_eq d0
    have := ((hasDerivAt_cos p.2).const_mul wy).sub ((hasDerivAt_sin p.2).const_mul wx)
    convert this using 1; ring
  · apply kf_pd0_eq d1
    have := (((hasDerivAt_cos p.1).div (hasDerivAt_sin p.1) hs).mul_const
      (wx * cos p.2 + wy * sin p.2)).const_sub wz
    convert this using 1
    field_simp
    have := sin_sq_add_cos_sq p.1
    linear_combination (-(wx * cos p.2 + wy * sin p.2)) * this
  · apply kf_pd1_eq d1
    have := ((((hasDerivAt_cos p.2).const_mul wx).add ((hasDerivAt_sin p.2).const_mul wy)).const_mul
      (cos p.1 / sin p.1)).const_sub wz
    convert this using 1; ring

lemma kf_const_Ioo {F : ℝ → ℝ} (hF : ∀ x ∈ Ioo 0 π, HasDerivAt F 0 x) {x y : ℝ}
    (hx : x ∈ Ioo 0 π) (hy : y ∈ Ioo 0 π) : F x = F y :=
  isOpen_Ioo.is_const_of_deriv_eq_zero isPreconnected_Ioo
    (fun z hz => (hF z hz).differentiableAt.differentiableWithinAt)
    (fun z hz => (hF z hz).deriv) hx hy

lemma kf_pi2_mem : π / 2 ∈ Ioo 0 π := ⟨by positivity, by linarith [pi_pos]⟩

lemma kf_pi4_mem : π / 4 ∈ Ioo 0 π := ⟨by positivity, by linarith [pi_pos]⟩

lemma kf_line_smooth {u : ℝ × ℝ → ℝ} (hu : ContDiffOn ℝ ∞ u chartDomain) {x : ℝ}
    (hx : x ∈ Ioo 0 π) : ContDiff ℝ ∞ (fun y => u (x, y)) := by
  have : ContDiff ℝ ∞ (u ∘ fun y : ℝ => (x, y)) :=
    hu.comp_contDiff (by fun_prop) (fun y => by simpa [chartDomain] using hx)
  exact this

lemma kf_smooth_derivs {f : ℝ → ℝ} (hf : ContDiff ℝ ∞ f) :
    (∀ x, HasDerivAt f (deriv f x) x) ∧ (∀ x, HasDerivAt (deriv f) (deriv (deriv f) x) x) := by
  obtain ⟨h1, h2⟩ := contDiff_infty_iff_deriv.1 hf
  obtain ⟨h3, -⟩ := contDiff_infty_iff_deriv.1 h2
  exact ⟨fun x => (h1 x).hasDerivAt, fun x => (h3 x).hasDerivAt⟩

lemma kf_cdAt {u : ℝ × ℝ → ℝ} (hu : ContDiffOn ℝ ∞ u chartDomain) {p : ℝ × ℝ}
    (hp : p ∈ chartDomain) : ContDiffAt ℝ ∞ u p :=
  hu.contDiffAt (kf_isOpen_chartDomain.mem_nhds hp)

lemma kf_dAt {u : ℝ × ℝ → ℝ} (hu : ContDiffOn ℝ ∞ u chartDomain) {p : ℝ × ℝ}
    (hp : p ∈ chartDomain) : DifferentiableAt ℝ u p :=
  (kf_cdAt hu hp).differentiableAt (by simp)

lemma kf_cot_deriv {x : ℝ} (hs : sin x ≠ 0) :
    HasDerivAt (fun t => cos t / sin t) (-1 / sin x ^ 2) x := by
  have := (hasDerivAt_cos x).div (hasDerivAt_sin x) hs
  convert this using 1
  congr 1
  linear_combination sin_sq_add_cos_sq x

lemma kf_sin_ne {p : ℝ × ℝ} (hp : p ∈ chartDomain) : sin p.1 ≠ 0 := by
  rw [kf_mem_chartDomain] at hp
  exact (sin_pos_of_pos_of_lt_pi hp.1 hp.2).ne'

lemma kf_spin_unique {w w' : ℝ × ℝ × ℝ}
    (h : ∀ p ∈ chartDomain, ∀ k,
      spinField w.1 w.2.1 w.2.2 k p = spinField w'.1 w'.2.1 w'.2.2 k p) : w = w' := by
  have m1 : ((π / 2, 0) : ℝ × ℝ) ∈ chartDomain := by simpa [chartDomain] using kf_pi2_mem
  have m2 : ((π / 2, π / 2) : ℝ × ℝ) ∈ chartDomain := by simpa [chartDomain] using kf_pi2_mem
  have h1 := h _ m1 0
  have h2 := h _ m2 0
  have h3 := h _ m1 1
  obtain ⟨a, b, c⟩ := w
  obtain ⟨a', b', c'⟩ := w'
  simp [spinField] at h1 h2 h3
  simp [h1, h2, h3]

lemma kf_round_lie (R : ℝ) (X : Fin 2 → ℝ × ℝ → ℝ) (p : ℝ × ℝ) :
    lieDerivMetric (roundMetric R) X 0 0 p = X 0 p * 0 + 2 * R ^ 2 * pd 0 (X 0) p ∧
    lieDerivMetric (roundMetric R) X 1 1 p =
      X 0 p * (2 * R ^ 2 * sin p.1 * cos p.1) + 2 * (R ^ 2 * sin p.1 ^ 2) * pd 1 (X 1) p ∧
    lieDerivMetric (roundMetric R) X 0 1 p =
      R ^ 2 * pd 1 (X 0) p + R ^ 2 * sin p.1 ^ 2 * pd 0 (X 1) p ∧
    lieDerivMetric (roundMetric R) X 1 0 p =
      R ^ 2 * pd 1 (X 0) p + R ^ 2 * sin p.1 ^ 2 * pd 0 (X 1) p := by
  have hQ : HasDerivAt (fun x => R ^ 2 * sin x ^ 2) (2 * R ^ 2 * sin p.1 * cos p.1) p.1 := by
    have := ((hasDerivAt_sin p.1).pow 2).const_mul (R ^ 2)
    convert this using 1; simp; ring
  exact kf_lie_diag (fun _ => R ^ 2) (fun x => R ^ 2 * sin x ^ 2) 0 _ (roundMetric R) rfl X p
    (hasDerivAt_const _ _) hQ

lemma kf_flat_P_deriv (a b x : ℝ) :
    HasDerivAt (fun x => a ^ 2 * cos x ^ 2 + b ^ 2 * sin x ^ 2)
      (2 * (b ^ 2 - a ^ 2) * sin x * cos x) x := by
  have := (((hasDerivAt_cos x).pow 2).const_mul (a ^ 2)).add
    (((hasDerivAt_sin x).pow 2).const_mul (b ^ 2))
  convert this using 1; simp; ring

lemma kf_flat_lie (a b : ℝ) (X : Fin 2 → ℝ × ℝ → ℝ) (p : ℝ × ℝ) :
    lieDerivMetric (flattenedMetric a b) X 0 0 p =
      X 0 p * (2 * (b ^ 2 - a ^ 2) * sin p.1 * cos p.1) +
        2 * (a ^ 2 * cos p.1 ^ 2 + b ^ 2 * sin p.1 ^ 2) * pd 0 (X 0) p ∧
    lieDerivMetric (flattenedMetric a b) X 1 1 p =
      X 0 p * (2 * a ^ 2 * sin p.1 * cos p.1) + 2 * (a ^ 2 * sin p.1 ^ 2) * pd 1 (X 1) p ∧
    lieDerivMetric (flattenedMetric a b) X 0 1 p =
      (a ^ 2 * cos p.1 ^ 2 + b ^ 2 * sin p.1 ^ 2) * pd 1 (X 0) p +
        a ^ 2 * sin p.1 ^ 2 * pd 0 (X 1) p ∧
    lieDerivMetric (flattenedMetric a b) X 1 0 p =
      (a ^ 2 * cos p.1 ^ 2 + b ^ 2 * sin p.1 ^ 2) * pd 1 (X 0) p +
        a ^ 2 * sin p.1 ^ 2 * pd 0 (X 1) p := by
  have hP : HasDerivAt (fun x => a ^ 2 * cos x ^ 2 + b ^ 2 * sin x ^ 2)
      (2 * (b ^ 2 - a ^ 2) * sin p.1 * cos p.1) p.1 := by
    have := (((hasDerivAt_cos p.1).pow 2).const_mul (a ^ 2)).add
      (((hasDerivAt_sin p.1).pow 2).const_mul (b ^ 2))
    convert this using 1; simp; ring
  have hQ : HasDerivAt (fun x => a ^ 2 * sin x ^ 2) (2 * a ^ 2 * sin p.1 * cos p.1) p.1 := by
    have := ((hasDerivAt_sin p.1).pow 2).const_mul (a ^ 2)
    convert this using 1; simp; ring
  exact kf_lie_diag (fun x => a ^ 2 * cos x ^ 2 + b ^ 2 * sin x ^ 2) (fun x => a ^ 2 * sin x ^ 2)
    _ _ (flattenedMetric a b) rfl X p hP hQ

lemma kf_flat_pos {a b : ℝ} (hb : 0 < b) (hab : b < a) (x : ℝ) :
    b ^ 2 ≤ a ^ 2 * cos x ^ 2 + b ^ 2 * sin x ^ 2 := by
  have h1 : b ^ 2 ≤ a ^ 2 := by nlinarith
  nlinarith [mul_nonneg (sub_nonneg.2 h1) (sq_nonneg (cos x)), sin_sq_add_cos_sq x]

/-- Killing fields of the round globe are exactly the spins: on a globe of radius `R > 0`,
a smooth field `X` in the chart satisfies `ℒ_X g = 0` at every point off the poles if and
only if it is the spin about some axis through the centre, and the turn rate
`ω = (ωx, ωy, ωz)` is then unique, so there are exactly three independent Killing fields. -/
theorem killing_fields_of_round_globe_are_spins (R : ℝ) (hR : 0 < R)
    (X : Fin 2 → ℝ × ℝ → ℝ) (hX : ∀ k, ContDiffOn ℝ ∞ (X k) chartDomain) :
    (∀ p ∈ chartDomain, ∀ i j, lieDerivMetric (roundMetric R) X i j p = 0) ↔
      ∃! w : ℝ × ℝ × ℝ, ∀ p ∈ chartDomain, ∀ k, X k p = spinField w.1 w.2.1 w.2.2 k p := by
  have hR2 : R ^ 2 ≠ 0 := by positivity
  have memD : ∀ x y, x ∈ Ioo 0 π → ((x, y) : ℝ × ℝ) ∈ chartDomain := by
    intro x y hx; simpa [chartDomain] using hx
  constructor
  · intro H
    have E00 : ∀ p ∈ chartDomain, pd 0 (X 0) p = 0 := by
      intro p hp
      have h := H p hp 0 0
      rw [(kf_round_lie R X p).1] at h
      have : R ^ 2 * pd 0 (X 0) p = 0 := by linarith
      exact (mul_eq_zero.1 this).resolve_left hR2
    have E11 : ∀ p ∈ chartDomain, pd 1 (X 1) p = -(cos p.1 / sin p.1) * X 0 p := by
      intro p hp
      have hs := kf_sin_ne hp
      have h := H p hp 1 1
      rw [(kf_round_lie R X p).2.1] at h
      field_simp
      have : R ^ 2 * sin p.1 * (sin p.1 * pd 1 (X 1) p + cos p.1 * X 0 p) = 0 := by
        linear_combination h / 2
      have := (mul_eq_zero.1 this).resolve_left (mul_ne_zero hR2 hs)
      linear_combination this
    have E01 : ∀ p ∈ chartDomain, pd 0 (X 1) p = -pd 1 (X 0) p / sin p.1 ^ 2 := by
      intro p hp
      have hs := kf_sin_ne hp
      have h := H p hp 0 1
      rw [(kf_round_lie R X p).2.2.1] at h
      field_simp
      have : R ^ 2 * (pd 1 (X 0) p + sin p.1 ^ 2 * pd 0 (X 1) p) = 0 := by
        linear_combination h
      have := (mul_eq_zero.1 this).resolve_left hR2
      linear_combination this
    -- Step 1: X 0 does not depend on φ
    have hu : ∀ x ∈ Ioo 0 π, ∀ y, X 0 (x, y) = X 0 (π / 2, y) := by
      intro x hx y
      refine kf_const_Ioo (F := fun x => X 0 (x, y)) (fun z hz => ?_) hx kf_pi2_mem
      have := kf_hasDerivAt_pd0 (kf_dAt (hX 0) (memD z y hz))
      rwa [E00 _ (memD z y hz)] at this
    set f : ℝ → ℝ := fun y => X 0 (π / 2, y) with hf_def
    have hf : ContDiff ℝ ∞ f := kf_line_smooth (hX 0) kf_pi2_mem
    obtain ⟨hf1, hf2⟩ := kf_smooth_derivs hf
    have hu' : ∀ x ∈ Ioo 0 π, (fun y => X 0 (x, y)) = f := by
      intro x hx; funext y; exact hu x hx y
    -- Step 2: the θ-rate of X 0 is f'
    have huθ : ∀ x ∈ Ioo 0 π, ∀ y, pd 1 (X 0) (x, y) = deriv f y := by
      intro x hx y
      apply kf_pd1_eq (kf_dAt (hX 0) (memD x y hx))
      show HasDerivAt (fun y => X 0 (x, y)) (deriv f y) y
      rw [hu' x hx]; exact hf1 y
    -- Step 3: the form of X 1
    have hv : ∀ x ∈ Ioo 0 π, ∀ y, X 1 (x, y) = deriv f y * (cos x / sin x) + X 1 (π / 2, y) := by
      intro x hx y
      have key := kf_const_Ioo (F := fun x => X 1 (x, y) - deriv f y * (cos x / sin x))
        (fun z hz => ?_) hx kf_pi2_mem
      · simp only [cos_pi_div_two, zero_div, mul_zero, sub_zero] at key
        linarith
      · have hs : sin z ≠ 0 := (sin_pos_of_pos_of_lt_pi hz.1 hz.2).ne'
        have h1 := kf_hasDerivAt_pd0 (kf_dAt (hX 1) (memD z y hz))
        rw [E01 _ (memD z y hz), huθ z hz y] at h1
        have h2 := h1.sub ((kf_cot_deriv hs).const_mul (deriv f y))
        convert h2 using 1
        simp only
        field_simp
        ring
    set h : ℝ → ℝ := fun y => X 1 (π / 2, y) with hh_def
    have hh : ContDiff ℝ ∞ h := kf_line_smooth (hX 1) kf_pi2_mem
    obtain ⟨hh1, -⟩ := kf_smooth_derivs hh
    -- Step 4: the θ-equation
    have hθ : ∀ x ∈ Ioo 0 π, ∀ y,
        deriv (deriv f) y * (cos x / sin x) + deriv h y = -(cos x / sin x) * f y := by
      intro x hx y
      have e1 := E11 _ (memD x y hx)
      have e2 : pd 1 (X 1) (x, y) = deriv (deriv f) y * (cos x / sin x) + deriv h y := by
        apply kf_pd1_eq (kf_dAt (hX 1) (memD x y hx))
        show HasDerivAt (fun y => X 1 (x, y)) _ y
        have : (fun y => X 1 (x, y)) = fun y => deriv f y * (cos x / sin x) + h y := by
          funext y; exact hv x hx y
        rw [this]
        exact ((hf2 y).mul_const _).add (hh1 y)
      rw [e2, hu x hx y] at e1
      exact e1
    have hh' : ∀ y, deriv h y = 0 := by
      intro y
      have := hθ _ kf_pi2_mem y
      simpa using this
    have hff : ∀ y, deriv (deriv f) y = -f y := by
      intro y
      have := hθ _ kf_pi4_mem y
      rw [hh' y, cos_pi_div_four, sin_pi_div_four, div_self (by positivity)] at this
      linarith
    have hconst : ∀ y, h y = h 0 := fun y =>
      is_const_of_deriv_eq_zero (hh.differentiable (by simp)) hh' y 0
    -- Step 5: f solves f'' = -f
    set A := f 0
    set B := deriv f 0
    have hsol : ∀ y, f y = A * cos y + B * sin y ∧ deriv f y = -A * sin y + B * cos y := by
      let E : ℝ → ℝ := fun y => (f y - (A * cos y + B * sin y)) ^ 2 +
        (deriv f y - (-A * sin y + B * cos y)) ^ 2
      have hE : ∀ y, HasDerivAt E 0 y := by
        intro y
        have d1 := (hf1 y).sub (((hasDerivAt_cos y).const_mul A).add ((hasDerivAt_sin y).const_mul B))
        have d2 := (hf2 y).sub (((hasDerivAt_sin y).const_mul (-A)).add
          ((hasDerivAt_cos y).const_mul B))
        have := (d1.pow 2).add (d2.pow 2)
        convert this using 1
        rw [hff y]; simp; ring
      intro y
      have : E y = E 0 := is_const_of_deriv_eq_zero (fun z => (hE z).differentiableAt)
        (fun z => (hE z).deriv) y 0
      have h0 : E 0 = 0 := by simp [E, A, B]
      rw [h0] at this
      simp only [E] at this
      constructor
      · nlinarith [sq_nonneg (f y - (A * cos y + B * sin y)),
          sq_nonneg (deriv f y - (-A * sin y + B * cos y))]
      · nlinarith [sq_nonneg (f y - (A * cos y + B * sin y)),
          sq_nonneg (deriv f y - (-A * sin y + B * cos y))]
    -- Step 6: the turn rate
    have hspin : ∀ p ∈ chartDomain, ∀ k, X k p = spinField (-B) A (h 0) k p := by
      rintro ⟨x, y⟩ hp k
      have hx : x ∈ Ioo 0 π := by simpa [chartDomain] using hp
      fin_cases k
      · simp only [Fin.zero_eta, kf_spin0]
        rw [hu x hx y]
        show f y = _
        rw [(hsol y).1]; ring
      · simp only [Fin.mk_one, kf_spin1]
        rw [hv x hx y]
        show deriv f y * (cos x / sin x) + h y = _
        rw [(hsol y).2, hconst y]; ring
    refine ⟨(-B, A, h 0), hspin, fun w' hw' => ?_⟩
    exact kf_spin_unique (fun p hp k => by rw [← hw' p hp k, hspin p hp k])
  · rintro ⟨w, hw, -⟩ p hp i j
    have hs := kf_sin_ne hp
    have hval : ∀ k, X k p = spinField w.1 w.2.1 w.2.2 k p := hw p hp
    have hpd : ∀ i k, pd i (X k) p = pd i (spinField w.1 w.2.1 w.2.2 k) p :=
      fun i k => kf_pd_congr_dom i hp (fun q hq => hw q hq k)
    obtain ⟨l00, l11, l01, l10⟩ := kf_round_lie R X p
    obtain ⟨a1, a2, a3, a4⟩ := kf_spin_pd w.1 w.2.1 w.2.2 hs
    fin_cases i <;> fin_cases j
    · simp only [Fin.zero_eta, l00, hpd, a1]; ring
    · simp only [Fin.zero_eta, Fin.mk_one, l01, hpd, a2, a3]
      field_simp; ring
    · simp only [Fin.zero_eta, Fin.mk_one, l10, hpd, a2, a3]
      field_simp; ring
    · simp only [Fin.mk_one, l11, hpd, hval, a4]
      simp only [kf_spin0]
      field_simp; ring

/-- The flattened Earth keeps only the polar spin: when the equatorial radius `a` exceeds
the polar radius `b > 0`, a smooth field `X` in the chart satisfies `ℒ_X g = 0` at every
point off the poles if and only if it is a constant spin about the polar axis,
`X = (0, c)`, for exactly one rate `c`. -/
theorem killing_fields_of_flattened_earth_are_polar_spins (a b : ℝ) (hb : 0 < b) (hab : b < a)
    (X : Fin 2 → ℝ × ℝ → ℝ) (hX : ∀ k, ContDiffOn ℝ ∞ (X k) chartDomain) :
    (∀ p ∈ chartDomain, ∀ i j, lieDerivMetric (flattenedMetric a b) X i j p = 0) ↔
      ∃! c : ℝ, ∀ p ∈ chartDomain, X 0 p = 0 ∧ X 1 p = c := by
  have ha : 0 < a := hb.trans hab
  have ha2 : a ^ 2 ≠ 0 := by positivity
  have memD : ∀ x y, x ∈ Ioo 0 π → ((x, y) : ℝ × ℝ) ∈ chartDomain := by
    intro x y hx; simpa [chartDomain] using hx
  have Ppos : ∀ x, 0 < a ^ 2 * cos x ^ 2 + b ^ 2 * sin x ^ 2 := fun x =>
    lt_of_lt_of_le (by positivity) (kf_flat_pos hb hab x)
  constructor
  · intro H
    have E00 : ∀ p ∈ chartDomain, pd 0 (X 0) p =
        -(2 * (b ^ 2 - a ^ 2) * sin p.1 * cos p.1) * X 0 p /
          (2 * (a ^ 2 * cos p.1 ^ 2 + b ^ 2 * sin p.1 ^ 2)) := by
      intro p hp
      have h := H p hp 0 0
      rw [(kf_flat_lie a b X p).1] at h
      have := Ppos p.1
      field_simp
      linear_combination h / 2
    have E11 : ∀ p ∈ chartDomain, pd 1 (X 1) p = -(cos p.1 / sin p.1) * X 0 p := by
      intro p hp
      have hs := kf_sin_ne hp
      have h := H p hp 1 1
      rw [(kf_flat_lie a b X p).2.1] at h
      field_simp
      have : a ^ 2 * sin p.1 * (sin p.1 * pd 1 (X 1) p + cos p.1 * X 0 p) = 0 := by
        linear_combination h / 2
      have := (mul_eq_zero.1 this).resolve_left (mul_ne_zero ha2 hs)
      linear_combination this
    have E01 : ∀ p ∈ chartDomain, pd 0 (X 1) p =
        -(a ^ 2 * cos p.1 ^ 2 + b ^ 2 * sin p.1 ^ 2) * pd 1 (X 0) p / (a ^ 2 * sin p.1 ^ 2) := by
      intro p hp
      have hs := kf_sin_ne hp
      have h := H p hp 0 1
      rw [(kf_flat_lie a b X p).2.2.1] at h
      field_simp
      linear_combination h
    -- the mixed second partials of X 1 agree
    have hstar : ∀ p ∈ chartDomain,
        X 0 p / sin p.1 ^ 2 - (cos p.1 / sin p.1) * pd 0 (X 0) p =
          -(a ^ 2 * cos p.1 ^ 2 + b ^ 2 * sin p.1 ^ 2) * pd 1 (pd 1 (X 0)) p /
            (a ^ 2 * sin p.1 ^ 2) := by
      intro p hp
      have hs := kf_sin_ne hp
      have hsym := kf_pd_symm (kf_cdAt (hX 1) hp)
      have L : pd 0 (pd 1 (X 1)) p =
          X 0 p / sin p.1 ^ 2 - (cos p.1 / sin p.1) * pd 0 (X 0) p := by
        rw [kf_pd_congr_dom 0 hp (g := fun q => -(cos q.1 / sin q.1) * X 0 q) E11]
        have du := kf_dAt (hX 0) hp
        have dd : DifferentiableAt ℝ (fun q : ℝ × ℝ => -(cos q.1 / sin q.1) * X 0 q) p := by
          fun_prop (disch := exact hs)
        apply kf_pd0_eq dd
        have : HasDerivAt (fun x => -(cos x / sin x) * X 0 (x, p.2))
            (-(-1 / sin p.1 ^ 2) * X 0 p + -(cos p.1 / sin p.1) * pd 0 (X 0) p) p.1 :=
          ((kf_cot_deriv hs).neg).mul (kf_hasDerivAt_pd0 du)
        convert this using 1
        field_simp
        ring
      have Rr : pd 1 (pd 0 (X 1)) p =
          -(a ^ 2 * cos p.1 ^ 2 + b ^ 2 * sin p.1 ^ 2) * pd 1 (pd 1 (X 0)) p /
            (a ^ 2 * sin p.1 ^ 2) := by
        rw [kf_pd_congr_dom 1 hp (g := fun q => -(a ^ 2 * cos q.1 ^ 2 + b ^ 2 * sin q.1 ^ 2) *
          pd 1 (X 0) q / (a ^ 2 * sin q.1 ^ 2)) E01]
        have d2 := kf_pd_differentiableAt 1 (kf_cdAt (hX 0) hp)
        have dd : DifferentiableAt ℝ (fun q : ℝ × ℝ => -(a ^ 2 * cos q.1 ^ 2 + b ^ 2 * sin q.1 ^ 2) *
            pd 1 (X 0) q / (a ^ 2 * sin q.1 ^ 2)) p := by
          fun_prop (disch := exact mul_ne_zero ha2 (pow_ne_zero 2 hs))
        apply kf_pd1_eq dd
        exact ((kf_hasDerivAt_pd1 d2).const_mul (-(a ^ 2 * cos p.1 ^ 2 + b ^ 2 * sin p.1 ^ 2))).div_const
          (a ^ 2 * sin p.1 ^ 2)
      rw [← L, ← Rr]; exact hsym
    -- √P · X 0 does not change along φ
    have hroot : ∀ x ∈ Ioo 0 π, ∀ y,
        √(a ^ 2 * cos x ^ 2 + b ^ 2 * sin x ^ 2) * X 0 (x, y) = b * X 0 (π / 2, y) := by
      intro x hx y
      have key := kf_const_Ioo
        (F := fun x => √(a ^ 2 * cos x ^ 2 + b ^ 2 * sin x ^ 2) * X 0 (x, y))
        (fun z hz => ?_) hx kf_pi2_mem
      · rw [key]
        simp [cos_pi_div_two, sin_pi_div_two, Real.sqrt_sq hb.le]
      · have hsq := (kf_flat_P_deriv a b z).sqrt (Ppos z).ne'
        have h1 := kf_hasDerivAt_pd0 (kf_dAt (hX 0) (memD z y hz))
        rw [E00 _ (memD z y hz)] at h1
        have := hsq.mul h1
        convert this using 1
        simp only
        have hr2 := Real.sq_sqrt (Ppos z).le
        have hrpos := Real.sqrt_pos.2 (Ppos z)
        set r := √(a ^ 2 * cos z ^ 2 + b ^ 2 * sin z ^ 2) with hr
        rw [← hr2]
        field_simp
        ring
    set g : ℝ → ℝ := fun y => X 0 (π / 2, y) with hg_def
    have hg : ContDiff ℝ ∞ g := kf_line_smooth (hX 0) kf_pi2_mem
    obtain ⟨hg1, hg2⟩ := kf_smooth_derivs hg
    have hform : ∀ x ∈ Ioo 0 π, (fun y => X 0 (x, y)) =
        fun y => b / √(a ^ 2 * cos x ^ 2 + b ^ 2 * sin x ^ 2) * g y := by
      intro x hx; funext y
      have h := hroot x hx y
      have hpos := Real.sqrt_pos.2 (Ppos x)
      field_simp
      linear_combination h
    have hval : ∀ x ∈ Ioo 0 π, ∀ y,
        X 0 (x, y) = b / √(a ^ 2 * cos x ^ 2 + b ^ 2 * sin x ^ 2) * g y :=
      fun x hx y => congrFun (hform x hx) y
    have hθθ : ∀ x ∈ Ioo 0 π, ∀ y, pd 1 (pd 1 (X 0)) (x, y) =
        b / √(a ^ 2 * cos x ^ 2 + b ^ 2 * sin x ^ 2) * deriv (deriv g) y := by
      intro x hx y
      have hθ : (fun y => pd 1 (X 0) (x, y)) =
          fun y => b / √(a ^ 2 * cos x ^ 2 + b ^ 2 * sin x ^ 2) * deriv g y := by
        funext y
        apply kf_pd1_eq (kf_dAt (hX 0) (memD x y hx))
        show HasDerivAt (fun y => X 0 (x, y)) _ y
        rw [hform x hx]
        exact (hg1 y).const_mul _
      apply kf_pd1_eq (kf_pd_differentiableAt 1 (kf_cdAt (hX 0) (memD x y hx)))
      show HasDerivAt (fun y => pd 1 (X 0) (x, y)) _ y
      rw [hθ]
      exact (hg2 y).const_mul _
    have heq : ∀ x ∈ Ioo 0 π, ∀ y,
        g y / sin x ^ 2 + (cos x / sin x) * (2 * (b ^ 2 - a ^ 2) * sin x * cos x) * g y /
          (2 * (a ^ 2 * cos x ^ 2 + b ^ 2 * sin x ^ 2)) +
          (a ^ 2 * cos x ^ 2 + b ^ 2 * sin x ^ 2) * deriv (deriv g) y / (a ^ 2 * sin x ^ 2) = 0 := by
      intro x hx y
      have h := hstar (x, y) (memD x y hx)
      have e0 := E00 (x, y) (memD x y hx)
      simp only at h e0
      rw [e0, hθθ x hx y, hval x hx y] at h
      have hc : b / √(a ^ 2 * cos x ^ 2 + b ^ 2 * sin x ^ 2) ≠ 0 := by
        have := Real.sqrt_pos.2 (Ppos x); positivity
      have : b / √(a ^ 2 * cos x ^ 2 + b ^ 2 * sin x ^ 2) *
          (g y / sin x ^ 2 + (cos x / sin x) * (2 * (b ^ 2 - a ^ 2) * sin x * cos x) * g y /
          (2 * (a ^ 2 * cos x ^ 2 + b ^ 2 * sin x ^ 2)) +
          (a ^ 2 * cos x ^ 2 + b ^ 2 * sin x ^ 2) * deriv (deriv g) y / (a ^ 2 * sin x ^ 2)) = 0 := by
        linear_combination h
      exact (mul_eq_zero.1 this).resolve_left hc
    have hg0 : ∀ y, g y = 0 := by
      intro y
      have e1 := heq _ kf_pi2_mem y
      have e2 := heq _ kf_pi4_mem y
      simp [sin_pi_div_two, cos_pi_div_two] at e1
      rw [cos_pi_div_four, sin_pi_div_four] at e2
      have h2 : √2 ^ 2 = 2 := Real.sq_sqrt (by norm_num)
      have hgg : deriv (deriv g) y = -(a ^ 2 * g y) / b ^ 2 := by
        field_simp
        field_simp at e1
        linear_combination e1
      rw [hgg] at e2
      field_simp at e2
      rw [h2] at e2
      have hab2 : 0 < a ^ 2 - b ^ 2 := by nlinarith
      have hk : (a ^ 2 - b ^ 2) * (a ^ 2 + 2 * b ^ 2) ≠ 0 := by positivity
      have : g y * ((a ^ 2 - b ^ 2) * (a ^ 2 + 2 * b ^ 2)) = 0 := by
        linear_combination (-1 / 2 : ℝ) * e2
      exact (mul_eq_zero.1 this).resolve_right hk
    have hu0 : ∀ p ∈ chartDomain, X 0 p = 0 := by
      rintro ⟨x, y⟩ hp
      have hx : x ∈ Ioo 0 π := by simpa [chartDomain] using hp
      rw [hval x hx y, hg0 y, mul_zero]
    have hv1 : ∀ p ∈ chartDomain, pd 1 (X 1) p = 0 := by
      intro p hp; rw [E11 p hp, hu0 p hp, mul_zero]
    have hv0 : ∀ p ∈ chartDomain, pd 0 (X 1) p = 0 := by
      intro p hp
      have : pd 1 (X 0) p = 0 := by
        rw [kf_pd_congr_dom 1 hp (g := fun _ => 0) hu0]; simp [pd]
      rw [E01 p hp, this]; simp
    have hvc : ∀ p ∈ chartDomain, X 1 p = X 1 (π / 2, 0) := by
      rintro ⟨x, y⟩ hp
      have hx : x ∈ Ioo 0 π := by simpa [chartDomain] using hp
      have s1 : X 1 (x, y) = X 1 (x, 0) :=
        is_const_of_deriv_eq_zero ((kf_line_smooth (hX 1) hx).differentiable (by simp))
          (fun z => by
            rw [(kf_hasDerivAt_pd1 (kf_dAt (hX 1) (memD x z hx))).deriv]
            exact hv1 _ (memD x z hx)) y 0
      have s2 : X 1 (x, 0) = X 1 (π / 2, 0) :=
        kf_const_Ioo (F := fun x => X 1 (x, 0)) (fun z hz => by
          have := kf_hasDerivAt_pd0 (kf_dAt (hX 1) (memD z 0 hz))
          rwa [hv0 _ (memD z 0 hz)] at this) hx kf_pi2_mem
      rw [s1, s2]
    refine ⟨X 1 (π / 2, 0), fun p hp => ⟨hu0 p hp, hvc p hp⟩, fun c' hc' => ?_⟩
    exact ((hc' _ (memD _ 0 kf_pi2_mem)).2).symm
  · rintro ⟨c, hc, -⟩ p hp i j
    have h0 : ∀ i, pd i (X 0) p = 0 := fun i => by
      rw [kf_pd_congr_dom i hp (g := fun _ => 0) (fun q hq => (hc q hq).1)]; simp [pd]
    have h1 : ∀ i, pd i (X 1) p = 0 := fun i => by
      rw [kf_pd_congr_dom i hp (g := fun _ => c) (fun q hq => (hc q hq).2)]; simp [pd]
    obtain ⟨l00, l11, l01, l10⟩ := kf_flat_lie a b X p
    fin_cases i <;> fin_cases j <;> simp [l00, l11, l01, l10, h0, h1, (hc p hp).1]

/-- The three spins form the rotation group's Lie algebra with the sign flipped:
the bracket of the spin about `x` and the spin about `y` is minus the spin about `z`,
at every point off the poles. -/
theorem bracket_spin_x_spin_y_eq_neg_spin_z :
    ∀ p ∈ chartDomain, ∀ k,
      lieBracketChart (spinField 1 0 0) (spinField 0 1 0) k p = - spinField 0 0 1 k p := by
  intro p hp k
  rw [kf_mem_chartDomain] at hp
  have hs : sin p.1 ≠ 0 := (sin_pos_of_pos_of_lt_pi hp.1 hp.2).ne'
  obtain ⟨a1, a2, a3, a4⟩ := kf_spin_pd 1 0 0 hs
  obtain ⟨b1, b2, b3, b4⟩ := kf_spin_pd 0 1 0 hs
  fin_cases k
  · simp only [lieBracketChart, Fin.sum_univ_two, Fin.zero_eta, a1, a2, b1, b2]
    simp [spinField]; ring
  · simp only [lieBracketChart, Fin.sum_univ_two, Fin.mk_one, a3, a4, b3, b4]
    simp [spinField]
    field_simp
    linear_combination (cos p.1 ^ 2 - 1) * sin_sq_add_cos_sq p.2 + sin_sq_add_cos_sq p.1

/-! Worked examples from the card, checked exactly. -/

-- The most Killing fields a connected surface can have: n(n+1)/2 with n = 2 is 3.
example : 2 * (2 + 1) / 2 = 3 := by decide

-- The polar spin is the spin with ω = (0, 0, 1): its components are (0, 1) everywhere.
example (p : ℝ × ℝ) : spinField 0 0 1 0 p = 0 ∧ spinField 0 0 1 1 p = 1 := by
  simp [spinField]

#print axioms killing_fields_of_round_globe_are_spins
#print axioms killing_fields_of_flattened_earth_are_polar_spins
#print axioms bracket_spin_x_spin_y_eq_neg_spin_z
#print axioms kf_isOpen_chartDomain
#print axioms kf_mem_chartDomain
#print axioms kf_hasDerivAt_pd0
#print axioms kf_hasDerivAt_pd1
#print axioms kf_pd0_eq
#print axioms kf_pd1_eq
#print axioms kf_pd_congr
#print axioms kf_pd_congr_dom
#print axioms kf_pd_symm
#print axioms kf_pd_differentiableAt
#print axioms kf_pd_fst
#print axioms kf_lie_diag
#print axioms kf_spin0
#print axioms kf_spin1
#print axioms kf_spin_pd
#print axioms kf_const_Ioo
#print axioms kf_pi2_mem
#print axioms kf_pi4_mem
#print axioms kf_line_smooth
#print axioms kf_smooth_derivs
#print axioms kf_cdAt
#print axioms kf_dAt
#print axioms kf_cot_deriv
#print axioms kf_sin_ne
#print axioms kf_spin_unique
#print axioms kf_round_lie
#print axioms kf_flat_P_deriv
#print axioms kf_flat_lie
#print axioms kf_flat_pos
```

**Checked 2026-11-19 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'killing_fields_of_round_globe_are_spins' depends on axioms: [propext, Classical.choice, Quot.sound]
'killing_fields_of_flattened_earth_are_polar_spins' depends on axioms: [propext, Classical.choice, Quot.sound]
'bracket_spin_x_spin_y_eq_neg_spin_z' depends on axioms: [propext, Classical.choice, Quot.sound]
'kf_isOpen_chartDomain' depends on axioms: [propext, Classical.choice, Quot.sound]
'kf_mem_chartDomain' depends on axioms: [propext, Classical.choice, Quot.sound]
'kf_hasDerivAt_pd0' depends on axioms: [propext, Classical.choice, Quot.sound]
'kf_hasDerivAt_pd1' depends on axioms: [propext, Classical.choice, Quot.sound]
'kf_pd0_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'kf_pd1_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'kf_pd_congr' depends on axioms: [propext, Classical.choice, Quot.sound]
'kf_pd_congr_dom' depends on axioms: [propext, Classical.choice, Quot.sound]
'kf_pd_symm' depends on axioms: [propext, Classical.choice, Quot.sound]
'kf_pd_differentiableAt' depends on axioms: [propext, Classical.choice, Quot.sound]
'kf_pd_fst' depends on axioms: [propext, Classical.choice, Quot.sound]
'kf_lie_diag' depends on axioms: [propext, Classical.choice, Quot.sound]
'kf_spin0' depends on axioms: [propext, Classical.choice, Quot.sound]
'kf_spin1' depends on axioms: [propext, Classical.choice, Quot.sound]
'kf_spin_pd' depends on axioms: [propext, Classical.choice, Quot.sound]
'kf_const_Ioo' depends on axioms: [propext, Classical.choice, Quot.sound]
'kf_pi2_mem' depends on axioms: [propext, Classical.choice, Quot.sound]
'kf_pi4_mem' depends on axioms: [propext, Classical.choice, Quot.sound]
'kf_line_smooth' depends on axioms: [propext, Classical.choice, Quot.sound]
'kf_smooth_derivs' depends on axioms: [propext, Classical.choice, Quot.sound]
'kf_cdAt' depends on axioms: [propext, Classical.choice, Quot.sound]
'kf_dAt' depends on axioms: [propext, Classical.choice, Quot.sound]
'kf_cot_deriv' depends on axioms: [propext, Classical.choice, Quot.sound]
'kf_sin_ne' depends on axioms: [propext, Classical.choice, Quot.sound]
'kf_spin_unique' depends on axioms: [propext, Classical.choice, Quot.sound]
'kf_round_lie' depends on axioms: [propext, Classical.choice, Quot.sound]
'kf_flat_P_deriv' depends on axioms: [propext, Classical.choice, Quot.sound]
'kf_flat_lie' depends on axioms: [propext, Classical.choice, Quot.sound]
'kf_flat_pos' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it. The asserts are pinned to the card's numbers, so expect some changes to stop the program.
> - **Make the twist rigid.** In the twist's line, replace `sin(p[0])` with `2.0` in both places. Guess first: is a spin at one rate everywhere Killing? Yes: the twist now prints 5570.22 km and "Killing: yes", and the third assert stops the run.
> - **Round off the Earth.** Change `count_killing(A_WGS / R, B_WGS / R)` to `count_killing(1.0, 1.0)`. Guess first: how many fields survive? All 3, and the fourth assert stops the run.
> - **Spin further.** Change both `0.5` in the distance line to `3.0`. Guess first: does a long spin ever change the distance? No: the spins still give 5570.22 km, while the slide gives 4682.90 km and the twist 3990.84 km. The run passes.
> - **Sample too few points.** Change `steps=(8, 6)` to `steps=(4, 3)`. Guess first: 36 equations for 50 unknowns. The count jumps to 17 on both shapes, and the fourth assert stops the run.

---

## The usual mistake

> [!warning]
> **Asking that the metric's numbers stay the same along the field.** The table $`g_{ij}`$ belongs to the chart, not to the globe. The spin about x carries New York south, and $`g_{\theta\theta}`$ grows there at rate 0.950546 $`R^2`$, yet no length changes: the stretch term, −0.950546 $`R^2`$, cancels it. Only the full $`\mathcal{L}_X g`$ decides.
>
> - **Expecting a Killing field to have one length everywhere.** Earth's spin moves London at 289.2 m/s, New York at 352.1 m/s and the pole at 0.0 m/s. It is still a symmetry.
> - **Multiplying a Killing field by a function.** The polar spin times $`\sin\varphi`$ is the twist, and it pulls London and New York to 5313.35 km.
> - **Taking equal coordinate steps as a symmetry.** Sliding every point 0.5 rad south sends the pair to 7855.38 km.
> - **Counting three on the real Earth.** The flattening leaves one; a tilted spin sinks the pole 21.385 km below the surface.

---

## Where you meet it in real life

- **Geodesy.** Distances on the Earth's ellipsoid are computed with Clairaut's constant, the conserved number of the polar spin. It survives the flattening because the polar spin is the one Killing field that does.
- **Map projections.** A transverse or oblique projection turns the globe before it projects. On a round model this works because its tilted spins are symmetries.
- **Mechanics.** A force that shares a Killing symmetry conserves the matching number: a satellite around a round planet keeps its angular momentum about every axis. See [Noether](08-noethers-theorem.md).
- **Relativity.** The same equation $`\mathcal{L}_X g = 0`$, applied to the metric of spacetime around a star, gives Killing fields for time shifts and for spins. Their conserved numbers are an orbit's energy and angular momentum.
- **A camera gimbal.** The directions a drone's camera can point form a sphere. Rolling, pitching or yawing the drone moves all those directions rigidly: the three Killing fields of that sphere are the three turn rates of [Rotation group](04-rotations-so3-and-quaternions.md).

> **Say it back**
> A Killing field is a vector field whose motion changes no length, tested by $`\mathcal{L}_X g = 0`$. In a chart, the change of the metric's table along the field and the field's stretching of steps must cancel. On the round globe the solutions are exactly the spins about axes through the centre: three independent fields, matching the three turn rates of $`SO(3)`$. Spinning the globe keeps London and New York 5570.22 km apart, while a slide or a twist does not. On the flattened Earth only the polar spin survives, and its conserved number along a great circle is Clairaut's constant.

---

## What this builds on

- [Group action and homogeneous space](06-homogeneous-spaces-and-group-actions.md): the rotation group acting on the globe, whose turn rates become the Killing fields here.
- [Riemannian metric](../05-Riemannian%20Geometry/01-riemannian-metrics.md): the table $`g_{ij}`$, the globe's metric, and the 5570.22 km London–New York distance the spins keep.

## Where this goes next

- [Noether](08-noethers-theorem.md): every continuous symmetry gives a conserved quantity, of which Clairaut's constant is one case.

The round globe has three Killing fields and the flattened Earth one; how few symmetries can a shape have before its geometry pins every point down?

---

## Sources

Verified 2026-11-19: every link below resolves to the publisher's page.

- Killing, Wilhelm. "Ueber die Grundlagen der Geometrie." *Journal für die reine und angewandte Mathematik* 109 (1892), 121–186. [doi:10.1515/crll.1892.109.121](https://doi.org/10.1515/crll.1892.109.121). The infinitesimal motions of a space that keep its lengths.
- Lee, John M. *Introduction to Riemannian Manifolds*, 2nd ed. Springer, Graduate Texts in Mathematics 176, 2018. [doi:10.1007/978-3-319-91755-9](https://doi.org/10.1007/978-3-319-91755-9). Killing fields, the Lie derivative of a metric, and the Killing equation in coordinates.
- Petersen, Peter. *Riemannian Geometry*, 3rd ed. Springer, Graduate Texts in Mathematics 171, 2016. [doi:10.1007/978-3-319-26654-1](https://doi.org/10.1007/978-3-319-26654-1). A Killing field is fixed by its value and derivative at one point, which bounds their number by $`n(n+1)/2`$.
- Karney, Charles F. F. "Algorithms for geodesics." *Journal of Geodesy* 87 (2013), 43–55. [doi:10.1007/s00190-012-0578-z](https://doi.org/10.1007/s00190-012-0578-z). Geodesics on the Earth's ellipsoid, built on Clairaut's constant, with the radii used here.
