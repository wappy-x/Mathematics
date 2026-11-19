# Differential form: a signed measurement of the box that directions span

[Syllabus](../../../SYLLABUS.md) → [Differential geometry and Lie groups](../README.md) → [Differential Forms](../README.md#s04) → Differential form

---

## General Overview

A weather map shows a rain band moving across a region around a valley. Its leading edge runs 120 km east and 50 km north. Over three hours the wind carries the whole edge 30 km east and 90 km north. A forecaster wants to know how much ground the edge has swept over, because every square kilometre it crossed has had rain.

The answer is 9300 square kilometres. It comes from one small calculation on the two arrows: 120 × 90 − 50 × 30. Take the arrows in the other order and the same calculation gives −9300. The sign records which way the edge moved: positive means the band moved to the left of the edge's direction, turning anticlockwise from the edge to the wind.

A rule that takes two directions and returns a signed area like this is a **two-form**. The one on the map is written $`dx \wedge dy`$, read "d x wedge d y". In three dimensions a tilted patch casts three shadows, on the ground and on two walls. A two-form keeps the three shadow areas separately and gives each its own weight. Rain falling on a sloping field is measured exactly this way.

**A differential form is a rule, attached to every point of a space, that takes some directions and returns the signed size of the box they span, built from shadow areas, and the wedge product multiplies such rules with a sign that flips whenever two directions swap.**

**What kind of fact this is:** definitions (one-form, two-form, k-form, the wedge product) and theorems proved on this card in Why it works: every two-form is a sum of shadow areas, the wedge of two one-forms is a two-by-two determinant, and swapping a k-form and an l-form multiplies by $`(-1)^{kl}`$. All of it is local: it is algebra at one point at a time.

### The picture: a hillside field's three shadows in the rain

A field on the valley side has a level edge 40 m east and 10 m north, and a second edge 6 m west, 24 m north and 18 m up the slope. Rain falls at 6 mm per hour while the wind drifts it 1.5 mm/h east and 2 mm/h south (water crossing each square metre of an upright wall per hour). A rate of 1 mm/h means 1 litre per square metre per hour.

```
shadow                  signed area (m²)                       rain through it (L/h)
north–up wall  dy∧dz    ██                               180   +270
up–east wall   dz∧dx    ████████                        −720   +1440
ground         dx∧dy    ███████████                     1020   −6120
whole field             the form adds the three columns        −4410
```

Each bar is one shadow's area; the sign beside it says which way that shadow faces. The rain form weights each shadow by the rain's motion across it and adds the three. The total, −4410 litres per hour, is the water landing on the field: negative because it crosses downward, against the side the field faces. The field faces south and up, and the wind blows the rain south, so the field sits partly in the lee. It catches less than the 6120 L/h that falls on its 1020 m² ground shadow.

---

## The formula

Notation first, in words. A point of space has coordinates $`x`$ (east), $`y`$ (north) and $`z`$ (up). In a space of any dimension $`n`$ they are $`x^1, \dots, x^n`$, and the raised numbers are labels, not powers. A direction at a point is an arrow there, a tangent vector ([Tangent space and differential](../03-Manifolds/03-tangent-spaces-and-differentials.md)). Arrows are $`u`$ and $`v`$, with parts $`u_1, u_2, u_3`$ east, north and up.

- A **one-form** takes one direction and returns a number, and doubling the direction doubles the number. The coordinate one-form $`dx`$ reads off the east part: $`dx(u) = u_1`$. Likewise $`dy(u) = u_2`$ and $`dz(u) = u_3`$. Any one-form is a weighted sum, $`\alpha = a_1\,dx + a_2\,dy + a_3\,dz`$; [Covectors and tensor fields](../03-Manifolds/05-covectors-and-tensor-fields.md) treats them in full.
- A **k-form** takes $`k`$ directions and returns a number. It is linear in each direction, and it flips sign when any two directions swap.
- The **wedge** $`\wedge`$ joins forms into larger ones. It is not the logical "and".
- A **differential form** is a k-form at every point, whose weights vary smoothly from place to place, like the rain rate across a valley.

The wedge of two one-forms, and the shadow form it gives:

```math
(\alpha \wedge \beta)(u, v) = \alpha(u)\,\beta(v) - \alpha(v)\,\beta(u), \qquad (dx \wedge dy)(u, v) = u_1 v_2 - u_2 v_1
```

**Read it aloud:** the wedge measures the first direction with the first form and the second with the second, then subtracts the same thing with the directions swapped; for $`dx`$ and $`dy`$ that is the signed area of the box's ground shadow.

Every two-form in three dimensions is three shadows with weights:

```math
\omega = P\,dy \wedge dz + Q\,dz \wedge dx + R\,dx \wedge dy, \qquad \omega = \sum_{i<j} \omega_{ij}\,dx^i \wedge dx^j \ \text{in } n \text{ dimensions}
```

**Read it aloud:** a two-form adds the box's shadow on each coordinate plane, each multiplied by its own weight; in $`n`$ dimensions there is one shadow for every pair of axes.

The sign rule, for a k-form $`\alpha`$ and an l-form $`\beta`$:

```math
\alpha \wedge \beta = (-1)^{kl}\,\beta \wedge \alpha, \qquad dx \wedge dx = 0
```

**Read it aloud:** swapping two one-forms flips the sign, and a one-form wedged with itself is zero: an edge paired with itself spans no area.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $`u`$, $`v`$; $`u_1, u_2, u_3`$ | two directions at one point, in order; their east, north and up parts | band: (120, 50) and (30, 90) km; field: (40, 10, 0) and (−6, 24, 18) m | the area grows with each edge; swapping them flips the sign |
| $`dx`$, $`dy`$, $`dz`$ | coordinate one-forms: read off one part of a direction | $`dx(u) = 120`$ | — |
| $`\alpha`$, $`\beta`$; $`a_i`$, $`b_i`$ | one-forms and their weights | $`dT`$ and $`dp`$ below | — |
| $`\wedge`$ | the wedge product | — | — |
| $`dx \wedge dy`$ | signed area of the ground shadow | 9300 km² for the band | — |
| $`\omega`$; $`P, Q, R`$ | a two-form and its three weights | the rain form: 1.5, −2, −6 mm/h | more weight, more water through that shadow |
| $`x^i`$, $`n`$, $`\omega_{ij}`$ | coordinates, dimension, a two-form's weight on axes $`i, j`$ | $`n = 3`$; three weights | a two-form has $`n(n-1)/2`$ weights |
| $`k`$, $`l`$ | the number of directions a form takes | rain form: $`k = 2`$ | $`(-1)^{kl}`$ is −1 only when both are odd |
| $`q = (q_1, q_2, q_3)`$ | the rain's flow: water per square metre per hour, moving east, north, up | (1.5, −2, −6) mm/h | more water on the field facing into it |
| $`T`$, $`p`$; $`t`$ | temperature (°C) and air pressure (hPa) on the map, where this $`T`$ is not the unit tangent; time, a fourth coordinate | $`dT \wedge dp = -0.0011\,dx \wedge dy`$ | steeper changes, a larger wedge |
| $`v_j`$, $`e_i`$, $`I`$, $`\sigma`$, $`\omega_I`$ | in the proof: the edges, the unit arrow along axis $`i`$, a sorted list of axes, a reordering, a k-form's weight on $`I`$ | — | — |
| $`S`$ | entropy, in the engine example | — | — |

### When it holds

- **All directions sit at the same point.** A form at a point measures arrows at that point. Across a large region the weights change, and adding up small boxes is integration: [Integration on an oriented manifold](05-integration-on-manifolds.md). The 40 m field is small enough to treat the rain as uniform.
- **The measurement is linear in each direction.** Ordinary unsigned area is not: the edges (1, 0) and (0, 1) span area 1, and (1, 0) with (0, −1) also spans 1, but (1, 0) with their sum (0, 0) spans 0, not 2. Only the signed version adds up, which is why forms carry signs.
- **The coordinate order is fixed.** The sign of $`dx \wedge dy`$ depends on calling east first and north second. A chart that lists north first negates (and reorders) every two-form's weights, because $`dy \wedge dx = -dx \wedge dy`$; the form's value on the same two arrows does not change. Mixing weights from one chart with arrow parts from the other gives a wrong answer. How forms move between charts is [Pullback](02-pullback-and-change-of-variables.md).
- **There are at least $`k`$ dimensions.** A box with more edges than the space has dimensions is flat, so every 3-form on the map is zero.
- **Three is the only dimension where a two-form is an arrow.** In four dimensions a two-form has six weights, and some, such as $`dx \wedge dy + dz \wedge dt`$, match no single plane at all (Step 5).

---

## Why it works

### Step 0: linear and sign-flipping forces the shadows

Ask for any measurement of a two-edged box with two properties. It is linear in each edge, so splitting an edge into parts splits the answer. And it flips sign when the edges swap. Write each edge as its east, north and up parts and expand. Every term pairs two coordinate directions. A pair repeated, such as east with east, must give zero: swapping it changes nothing yet must flip the sign. A pair in reverse order is the negative of the pair in order. What is left is one weight for each pair of axes, times that pair's shadow area. So such a measurement has no freedom except the weights.

### Step 1: the shadow form is a two-by-two determinant

The ground shadow of the box on $`u`$ and $`v`$ keeps only east and north. Its signed area is the determinant $`u_1 v_2 - u_2 v_1`$ ([Determinants](../../03-Algebra/05-Solving%20Systems/04-determinants.md)). That is exactly $`(dx \wedge dy)(u, v)`$. A determinant is linear in each column and flips sign when columns swap, so the shadow form has both properties of Step 0.

For the band, $`120 \times 90 - 50 \times 30 = 10800 - 1500 = 9300`$ km². The shoelace formula on the four corners of the swept parallelogram gives 9300 too, and so does counting 1 km grid cells whose centres lie inside it.

The [Cross product](../../05-Geometry%20and%20trig/05-Vectors%20in%20Space/01-cross-product-and-oriented-area.md) already writes each of its three parts as one of these shadow determinants. A two-form keeps the shadows as separate measurements, and that works in any dimension.

### Step 2: every two-form is a sum of weighted shadows

Expand $`\omega(u, v)`$ by Step 0. Each pair of axes $`i < j`$ contributes $`\omega_{ij}\,(u_i v_j - u_j v_i)`$, where $`\omega_{ij}`$ is the value of $`\omega`$ on the unit arrows along axes $`i`$ and $`j`$. That is the formula $`\omega = \sum_{i<j} \omega_{ij}\,dx^i \wedge dx^j`$. There is one weight per pair of axes: $`n(n-1)/2`$ of them, so 1, 3, 6, 10 in two, three, four and five dimensions.

On the field the three shadows are 180, −720 and 1020 m². The rain form has weights $`P = 1.5`$, $`Q = -2`$, $`R = -6`$:

```math
\omega(u, v) = 1.5 \times 180 + (-2) \times (-720) + (-6) \times 1020 = 270 + 1440 - 6120 = -4410
```

A second road: the water crossing the field in one hour fills a slanted slab with edges $`u`$, $`v`$ and the rain's hourly motion. Its signed volume is the three-by-three determinant of the rain's flow $`q = (1.5, -2, -6)`$ mm/h, $`u`$ and $`v`$, and it comes to −4410 litres too.

### Step 3: the wedge of two one-forms

Multiply out $`\alpha \wedge \beta`$ for $`\alpha = a_1\,dx + a_2\,dy`$ and $`\beta = b_1\,dx + b_2\,dy`$. The wedge distributes like ordinary multiplication but keeps the order. The terms $`dx \wedge dx`$ and $`dy \wedge dy`$ vanish, and $`dy \wedge dx = -dx \wedge dy`$. What survives is

```math
\alpha \wedge \beta = (a_1 b_2 - a_2 b_1)\,dx \wedge dy
```

The determinant again, now of the two forms' weights. On the map, temperature changes by $`dT = -0.04\,dx + 0.03\,dy`$ °C per km and pressure by $`dp = 0.01\,dx + 0.02\,dy`$ hPa per km. Then $`dT \wedge dp = (-0.04 \times 0.02 - 0.03 \times 0.01)\,dx \wedge dy = -0.0011\,dx \wedge dy`$. On the swept band it gives $`-0.0011 \times 9300 = -10.23`$ °C·hPa.

The defining formula gives the same: $`dT(u)\,dp(v) - dT(v)\,dp(u) = (-3.3)(2.1) - (1.5)(2.2) = -10.23`$. Forecasters use this wedge to find where air starts to circulate (see Where you meet it in real life).

### Step 4: the sign rule

Wedge the one-forms in the other order and every swap flips once: $`dp \wedge dT = +10.23`$ on the band. A k-form built from $`k`$ one-forms and an l-form built from $`l`$ trade places one one-form at a time. Each of the $`l`$ pieces moves past all $`k`$ pieces, so there are $`kl`$ swaps, and the sign is $`(-1)^{kl}`$.

Three consequences:

- A one-form wedged with itself is zero: $`\alpha \wedge \alpha = -\alpha \wedge \alpha`$.
- A two-form commutes with everything, since $`kl`$ is even. On the field, $`dz \wedge \omega`$ and $`\omega \wedge dz`$ are both $`-6\,dx \wedge dy \wedge dz`$: only the $`R`$ term survives, and $`dz \wedge dx \wedge dy`$ takes two swaps to sort.
- The rain form's middle term is $`Q\,dz \wedge dx = -Q\,dx \wedge dz`$. Sorting the axes costs a sign, and code that stores forms in sorted order must pay it.

### Step 5: why three dimensions is special

A two-form has $`n(n-1)/2`$ weights and an arrow has $`n`$. They match only when $`n = 3`$, so only there can a two-form be traded for an arrow: the cross product. In four dimensions, with time $`t`$ as the fourth coordinate, a two-form has six weights.

Some four-dimensional two-forms are not even one plane's shadows. A test: wedge the form with itself. A single plane's form, $`\alpha \wedge \beta`$, gives $`\alpha \wedge \beta \wedge \alpha \wedge \beta = 0`$, because moving the second $`\alpha`$ next to the first costs a sign and then $`\alpha \wedge \alpha = 0`$. But $`(dx \wedge dy + dz \wedge dt) \wedge (dx \wedge dy + dz \wedge dt) = 2\,dx \wedge dy \wedge dz \wedge dt`$, not zero. No single plane, and no arrow, carries it.

<details>
<summary>Detailed proof: a k-form on k edges is the sum of its weights times k-by-k determinants</summary>

Let $`\omega`$ be linear in each of its $`k`$ slots and flip sign whenever two slots swap. Write each edge $`v_j`$ as $`\sum_i (v_j)_i\,e_i`$, where $`e_i`$ is the unit arrow along axis $`i`$. Linearity gives

$`\displaystyle \omega(v_1, \dots, v_k) = \sum_{i_1, \dots, i_k} (v_1)_{i_1} \cdots (v_k)_{i_k}\;\omega(e_{i_1}, \dots, e_{i_k}).`$

A term with a repeated axis is zero, since swapping the two equal slots must flip a value that does not change. Every other term lists $`k`$ different axes in some order. Sort them into increasing order $`I = (i_1 < \dots < i_k)`$; each swap costs a sign, so the term is $`\mathrm{sign}(\sigma)\,\omega(e_{i_1}, \dots, e_{i_k})`$ for the reordering $`\sigma`$. Grouping the terms with the same sorted set $`I`$ gives

$`\displaystyle \omega(v_1, \dots, v_k) = \sum_{I} \omega_I \sum_{\sigma} \mathrm{sign}(\sigma)\,(v_{\sigma(1)})_{i_1} \cdots (v_{\sigma(k)})_{i_k} = \sum_I \omega_I \det\big[(v_j)_{i_m}\big],`$

because the inner sum is the Leibniz formula for the determinant of the $`k \times k`$ table of the edges' parts along the axes in $`I`$. The basic form $`dx^{i_1} \wedge \dots \wedge dx^{i_k}`$ is that determinant, so $`\omega = \sum_I \omega_I\,dx^{i_1} \wedge \dots \wedge dx^{i_k}`$.

The wedge of a k-form and an l-form is defined on these basic forms by joining the index lists, $`(dx^I) \wedge (dx^J) = dx^{I \cup J}`$ with the sign of the sorting, and zero if an index repeats. It is associative because joining lists is, and sorting signs multiply. The sign rule follows from counting swaps, as in Step 4. Spivak's and Lee's books, in Sources, give the same construction.

</details>

---

## Worked numbers, by hand

The band on the map, then the field on the hillside, then the wedge on the map.

| Step | Arithmetic | Value |
| --- | --- | --- |
| ground shadow of the band, $`u_1 v_2 - u_2 v_1`$ | 120 × 90 − 50 × 30 = 10800 − 1500 | **9300 km²** |
| arrows swapped | 30 × 50 − 90 × 120 | −9300 km² |
| field, north–up wall shadow $`dy \wedge dz`$ | 10 × 18 − 0 × 24 | 180 m² |
| field, up–east wall shadow $`dz \wedge dx`$ | 0 × (−6) − 40 × 18 | −720 m² |
| field, ground shadow $`dx \wedge dy`$ | 40 × 24 − 10 × (−6) | 1020 m² |
| field's true area | square root of 180² + 720² + 1020² | 1261.4278 m² |
| rain form on the field | 1.5 × 180 + (−2) × (−720) + (−6) × 1020 = 270 + 1440 − 6120 | **−4410 L/h** |
| depth of rain on the slope | 4410 ÷ 1261.4278 | 3.4960 mm/h, against 6 mm/h on a level gauge |
| $`dT \wedge dp`$ weight | (−0.04)(0.02) − (0.03)(0.01) | −0.0011 °C·hPa per km² |
| $`dT \wedge dp`$ on the band | −0.0011 × 9300 | **−10.23 °C·hPa** |

The field receives 4410 litres of rain an hour. Spread over its sloping surface that is 3.4960 mm an hour, a little over half of what the rain gauge on level ground reports.

The field's edges are square to each other (their dot product is 0). So its true area is also the product of the two edge lengths, which is Lagrange's identity, and that road gives 1261.4278 m² too.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Treat $`dy \wedge dx`$ as $`+dx \wedge dy`$: area $`u_1 v_2 + u_2 v_1`$ | 12300 km² | The order of the directions was ignored; the swept area is 9300 |
| Write the rain form's $`Q\,dz \wedge dx`$ as $`Q\,dx \wedge dz`$ | −7290 L/h | Sorting the axes costs a sign; the field gets 4410 |
| Keep only the ground shadow | −6120 L/h | The wind's slant across the two wall shadows is lost |
| Add each shadow's water as a positive amount (270 + 1440 + 6120) | 7830 L/h | More water than falls on the footprint, and it no longer adds up over pieces |
| Use unsigned area as a form | 2 for two pieces, 0 for their sum | Unsigned area is not linear, so it cannot be a form |

The code prints every row.

---

## Code, from first principles, and it actually runs

The code stores a form as a table from sorted lists of axes to weights. It takes **three independent roads** to each number. Road 1 wedges forms by joining index lists and sorting with a sign, and evaluates them by determinants of minors (cofactor expansion). Road 2 evaluates by brute force: the alternating sum over every ordering of the edges, which uses no determinant routine. Road 3 is geometry: the shoelace formula and a grid count for the band, Lagrange's identity for the field's area, and the three-by-three volume of the rain slab. It also checks each shadow against the cross product's parts, the sign rule, $`\alpha \wedge \alpha = 0`$ and the four-dimensional test of Step 5, and prints every row of What breaks.

### Python

```python
# Differential forms and the wedge product -- the check behind the card.
# Standard library only.  A k-form is a dict {sorted index tuple: coefficient}.
# Road 1: wedge by sorting indices with a sign, evaluate by determinants of minors.
# Road 2: evaluate by the brute-force alternating sum over every ordering of the edges.
# Road 3: geometry: shoelace corners, a grid count, Lagrange's identity, a prism volume.

def perms(n):                                   # every ordering of 0..n-1, with its sign
    if n == 0:
        return [((), 1)]
    out = []
    for p, s in perms(n - 1):
        for k in range(n):                      # insert n-1 at place k: n-1-k swaps
            out.append((p[:k] + (n - 1,) + p[k:], s * (-1) ** (n - 1 - k)))
    return out

def sort_sign(idx):                             # bubble sort; each swap flips the sign
    idx, sign = list(idx), 1
    for i in range(len(idx)):
        for j in range(len(idx) - 1 - i):
            if idx[j] > idx[j + 1]:
                idx[j], idx[j + 1] = idx[j + 1], idx[j]
                sign = -sign
    return tuple(idx), sign

def wedge(a, b):                                # road 1: concatenate, sort, drop repeats
    out = {}
    for i, x in a.items():
        for j, y in b.items():
            idx, s = sort_sign(i + j)
            if len(set(idx)) == len(idx):
                out[idx] = out.get(idx, 0.0) + s * x * y
    return {k: v for k, v in out.items() if abs(v) > 1e-15}

def det(m):                                     # cofactor expansion along the top row
    if len(m) == 1:
        return m[0][0]
    return sum((-1) ** c * m[0][c] * det([r[:c] + r[c + 1:] for r in m[1:]]) for c in range(len(m)))

def ev(form, vs):                               # road 1: sum of coefficient x minor
    return sum(c * det([[v[i] for v in vs] for i in idx]) for idx, c in form.items())

def ev_brute(form, vs):                         # road 2: alternating sum over orderings
    return sum(c * s * prod_(vs[p[j]][idx[j]] for j in range(len(idx)))
               for idx, c in form.items() for p, s in perms(len(vs)))

def prod_(xs):
    r = 1.0
    for x in xs:
        r *= x
    return r

def one(cs):                                    # one-form a1 dx^1 + a2 dx^2 + ...
    return {(i,): c for i, c in enumerate(cs) if c != 0}

def f(v):
    return f"{v + 0.0:.4f}"

X, Y, Z, T = 0, 1, 2, 3
dxdy = {(X, Y): 1.0}
# ---- 1. the rain band on the weather map: edge u, swept by the wind for 3 hours ----
u, v = (120.0, 50.0), (30.0, 90.0)
A = ev(dxdy, [u, v])
corners = [(0, 0), u, (u[0] + v[0], u[1] + v[1]), v]
shoe = 0.5 * sum(corners[i][0] * corners[i - 3][1] - corners[i - 3][0] * corners[i][1] for i in range(4))
def grid(h):                                    # count cell centres inside the swept band
    n = 0
    for i in range(int(150 / h)):
        for j in range(int(140 / h)):
            px, py = (i + 0.5) * h, (j + 0.5) * h
            s = (px * v[1] - py * v[0]) / A     # solve p = s u + t v
            t = (u[0] * py - u[1] * px) / A
            n += 0 <= s < 1 and 0 <= t < 1
    return n * h * h
print("map: dx^dy(u,v) swept area km2", f(A), " dx^dy(v,u)", f(ev(dxdy, [v, u])))
print("map: u1v2 u2v1", f(u[0] * v[1]), f(u[1] * v[0]), " shoelace", f(shoe), " grid h=2", f(grid(2.0)), " grid h=1", f(grid(1.0)))
dT, dp = one([-0.04, 0.03]), one([0.01, 0.02])
TP = wedge(dT, dp)
print("map: dT(u) dT(v) dp(u) dp(v)", f(ev(dT, [u])), f(ev(dT, [v])), f(ev(dp, [u])), f(ev(dp, [v])))
print("map: dT^dp coefficient", f"{TP[(X, Y)]:.6f}", " on band", f(ev(TP, [u, v])),
      " dp^dT on band", f(ev(wedge(dp, dT), [u, v])))
assert abs(A - shoe) < 1e-9 and abs(ev(dxdy, [v, u]) + A) < 1e-9
assert abs(grid(1.0) - A) < 0.01 * A
assert abs(ev(TP, [u, v]) - (ev(dT, [u]) * ev(dp, [v]) - ev(dT, [v]) * ev(dp, [u]))) < 1e-12
# ---- 2. a hillside field in the rain: three shadows kept separately ----
U, V = (40.0, 10.0, 0.0), (-6.0, 24.0, 18.0)
sh = [ev({(Y, Z): 1.0}, [U, V]), -ev({(X, Z): 1.0}, [U, V]), ev(dxdy, [U, V])]
area = sum(s * s for s in sh) ** 0.5
lag = (sum(a * a for a in U) * sum(b * b for b in V) - sum(a * b for a, b in zip(U, V)) ** 2) ** 0.5
q = (1.5, -2.0, -6.0)                           # rain: mm/h east, north, up (falling)
rain = {(Y, Z): q[0], (X, Z): -q[1], (X, Y): q[2]}   # q2 dz^dx = -q2 dx^dz
W = ev(rain, [U, V])
prism = det([list(q), list(U), list(V)])        # water slab swept in one hour
print("hill: shadows dy^dz dz^dx dx^dy m2", f(sh[0]), f(sh[1]), f(sh[2]))
print("hill: true area", f(area), " Lagrange", f(lag), " u.v", f(sum(a * b for a, b in zip(U, V))))
print("hill: rain per shadow L/h", f(q[0] * sh[0]), f(q[1] * sh[1]), f(q[2] * sh[2]))
print("hill: rain form on field L/h", f(W), " brute", f(ev_brute(rain, [U, V])), " prism", f(prism))
print("hill: depth on slope mm/h", f(-W / area), " level gauge mm/h", f(-q[2]))
assert abs(area - lag) < 1e-9 and abs(W - prism) < 1e-9
assert abs(W - ev_brute(rain, [U, V])) < 1e-9
cross = (U[1] * V[2] - U[2] * V[1], U[2] * V[0] - U[0] * V[2], U[0] * V[1] - U[1] * V[0])   # U x V by components
assert all(abs(s - c) < 1e-9 for s, c in zip(sh, cross)) and abs(sum(a * b for a, b in zip(q, sh)) - W) < 1e-9
# ---- 3. what breaks ----
print("wrong: no sign flip, u1v2+u2v1", f(u[0] * v[1] + u[1] * v[0]))
print("wrong: dz^dx read as dx^dz", f(q[0] * sh[0] + q[1] * (-sh[1]) + q[2] * sh[2]))
print("wrong: ground shadow only", f(q[2] * sh[2]), " water all positive", f(sum(abs(a * b) for a, b in zip(q, sh))))
print("wrong: edges swapped", f(ev(rain, [V, U])))
e1, f1, f2 = (1.0, 0.0), (0.0, 1.0), (0.0, -1.0)
un = lambda a, b: abs(ev(dxdy, [a, b]))
print("fails: unsigned area of (e1,f1)+(e1,f2)", f(un(e1, f1) + un(e1, f2)), " of (e1,f1+f2)", f(un(e1, (f1[0] + f2[0], f1[1] + f2[1]))))
# ---- 4. the sign rule ----
al, be = one([1.0, 2.0, 0.0]), one([0.0, 3.0, -1.0])
ab, ba = wedge(al, be), wedge(be, al)
print("rule: a^b", [f(ab[k]) for k in sorted(ab)], " b^a", [f(ba[k]) for k in sorted(ba)])
print("rule: a^a terms", len(wedge(al, al)), " dz^rain", f(wedge(one([0, 0, 1.0]), rain)[(X, Y, Z)]),
      " rain^dz", f(wedge(rain, one([0, 0, 1.0]))[(X, Y, Z)]))
P = [(3.0, -1.0, 2.0), (0.5, 4.0, 1.0)]
assert all(abs(ab[k] + ba[k]) < 1e-12 for k in ab) and wedge(al, al) == {}
assert abs(ev(ab, P) - (ev(al, [P[0]]) * ev(be, [P[1]]) - ev(al, [P[1]]) * ev(be, [P[0]]))) < 1e-12
# ---- 5. four dimensions: x, y, z, t ----
sig = wedge(one([1.0, 2.0, 0.0, 0.0]), one([0.0, 0.0, 3.0, -1.0]))
tau = {(X, Y): 1.0, (Z, T): 1.0}
cnt = [len(wedge(one([1.0] * n), one([(i + 1.0) ** 2 for i in range(n)]))) for n in (2, 3, 4, 5)]
print("4D: components of a two-form, n = 2 3 4 5:", cnt)
assert cnt == [n * (n - 1) // 2 for n in (2, 3, 4, 5)]
print("4D: sig^sig", len(wedge(sig, sig)), "terms;  tau^tau", f(wedge(tau, tau)[(X, Y, Z, T)]))
Q4 = [(1.0, 0.0, 0.0, 0.0), (0.0, 1.0, 0.0, 0.0), (0.0, 0.0, 1.0, 0.0), (0.0, 0.0, 0.0, 1.0)]
print("4D: tau^tau on the unit box, brute", f(ev_brute(wedge(tau, tau), Q4)))
assert wedge(sig, sig) == {} and abs(ev_brute(wedge(tau, tau), Q4) - 2.0) < 1e-12
# ---- 6. try changing ----
print("try: wind along the edge", f(ev(dxdy, [u, (60.0, 25.0)])),
      " parallel isotherms", f(ev(wedge(one([-0.02, -0.04]), dp), [u, v])))
print("try: crosswind north -4", f(ev({(Y, Z): 1.5, (X, Z): 4.0, (X, Y): -6.0}, [U, V])))
print("ALL CHECKS PASS")
```

**Ran 2026-11-19 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
map: dx^dy(u,v) swept area km2 9300.0000  dx^dy(v,u) -9300.0000
map: u1v2 u2v1 10800.0000 1500.0000  shoelace 9300.0000  grid h=2 9300.0000  grid h=1 9300.0000
map: dT(u) dT(v) dp(u) dp(v) -3.3000 1.5000 2.2000 2.1000
map: dT^dp coefficient -0.001100  on band -10.2300  dp^dT on band 10.2300
hill: shadows dy^dz dz^dx dx^dy m2 180.0000 -720.0000 1020.0000
hill: true area 1261.4278  Lagrange 1261.4278  u.v 0.0000
hill: rain per shadow L/h 270.0000 1440.0000 -6120.0000
hill: rain form on field L/h -4410.0000  brute -4410.0000  prism -4410.0000
hill: depth on slope mm/h 3.4960  level gauge mm/h 6.0000
wrong: no sign flip, u1v2+u2v1 12300.0000
wrong: dz^dx read as dx^dz -7290.0000
wrong: ground shadow only -6120.0000  water all positive 7830.0000
wrong: edges swapped 4410.0000
fails: unsigned area of (e1,f1)+(e1,f2) 2.0000  of (e1,f1+f2) 0.0000
rule: a^b ['3.0000', '-1.0000', '-2.0000']  b^a ['-3.0000', '1.0000', '2.0000']
rule: a^a terms 0  dz^rain -6.0000  rain^dz -6.0000
4D: components of a two-form, n = 2 3 4 5: [1, 3, 6, 10]
4D: sig^sig 0 terms;  tau^tau 2.0000
4D: tau^tau on the unit box, brute 2.0000
try: wind along the edge 0.0000  parallel isotherms 0.0000
try: crosswind north -4 -2970.0000
ALL CHECKS PASS
```

Every road agrees: 9300 km² by the form, the shoelace and both grid counts, and −4410 L/h by the form, the brute-force sum and the slab volume. The 1 km and 2 km grid counts both land exactly on 9300, because the band's corners sit on grid points. Copies of the band then tile the map in step with the grid, so each copy holds exactly one cell centre per cell of area. The line `rule: a^b` is $`(dx + 2\,dy) \wedge (3\,dy - dz) = 3\,dx \wedge dy - dx \wedge dz - 2\,dy \wedge dz`$, and `b^a` is its negative.

### Rust

Same checks, same inputs, the same output to the character. A form is a sorted map from index lists to weights. No crates.

```rust
// Differential forms and the wedge product -- the same check as the Python, in Rust.
// Standard library only, no crates.  A k-form is a map {sorted index list: coefficient}.
// Road 1: wedge by sorting indices with a sign, evaluate by determinants of minors.
// Road 2: evaluate by the brute-force alternating sum over every ordering of the edges.
// Road 3: geometry: shoelace corners, a grid count, Lagrange's identity, a prism volume.
use std::collections::BTreeMap;
type Form = BTreeMap<Vec<usize>, f64>;

fn perms(n: usize) -> Vec<(Vec<usize>, f64)> {   // every ordering of 0..n-1, with its sign
    if n == 0 { return vec![(vec![], 1.0)]; }
    let mut out = vec![];
    for (p, s) in perms(n - 1) {
        for k in 0..n {                            // insert n-1 at place k: n-1-k swaps
            let mut q = p.clone();
            q.insert(k, n - 1);
            out.push((q, if (n - 1 - k) % 2 == 0 { s } else { -s }));
        }
    }
    out
}

fn sort_sign(mut idx: Vec<usize>) -> (Vec<usize>, f64) {   // bubble sort; each swap flips the sign
    let mut sign = 1.0;
    let n = idx.len();
    for i in 0..n {
        for j in 0..n - 1 - i {
            if idx[j] > idx[j + 1] { idx.swap(j, j + 1); sign = -sign; }
        }
    }
    (idx, sign)
}

fn wedge(a: &Form, b: &Form) -> Form {            // road 1: concatenate, sort, drop repeats
    let mut out = Form::new();
    for (i, x) in a {
        for (j, y) in b {
            let (idx, s) = sort_sign([i.clone(), j.clone()].concat());
            let mut d = idx.clone();
            d.dedup();
            if d.len() == idx.len() { *out.entry(idx).or_insert(0.0) += s * x * y; }
        }
    }
    out.into_iter().filter(|(_, v)| v.abs() > 1e-15).collect()
}

fn det(m: &Vec<Vec<f64>>) -> f64 {                // cofactor expansion along the top row
    if m.len() == 1 { return m[0][0]; }
    (0..m.len()).map(|c| {
        let minor: Vec<Vec<f64>> = m[1..].iter().map(|r| [&r[..c], &r[c + 1..]].concat()).collect();
        (if c % 2 == 0 { 1.0 } else { -1.0 }) * m[0][c] * det(&minor)
    }).sum()
}

fn ev(form: &Form, vs: &[&[f64]]) -> f64 {        // road 1: sum of coefficient x minor
    form.iter().map(|(idx, c)| c * det(&idx.iter().map(|&i| vs.iter().map(|v| v[i]).collect()).collect())).sum()
}

fn ev_brute(form: &Form, vs: &[&[f64]]) -> f64 {  // road 2: alternating sum over orderings
    let mut t = 0.0;
    for (idx, c) in form {
        for (p, s) in perms(vs.len()) {
            let mut r = 1.0;
            for j in 0..idx.len() { r *= vs[p[j]][idx[j]]; }
            t += c * s * r;
        }
    }
    t
}

fn one(cs: &[f64]) -> Form {                      // one-form a1 dx^1 + a2 dx^2 + ...
    cs.iter().enumerate().filter(|(_, c)| **c != 0.0).map(|(i, c)| (vec![i], *c)).collect()
}
fn mk(t: &[(&[usize], f64)]) -> Form { t.iter().map(|(k, c)| (k.to_vec(), *c)).collect() }
fn f(v: f64) -> String { format!("{:.4}", v + 0.0) }
fn lst(m: &Form) -> String { format!("[{}]", m.values().map(|v| format!("'{}'", f(*v))).collect::<Vec<_>>().join(", ")) }

fn main() {
    let (x, y, z, t) = (0usize, 1usize, 2usize, 3usize);
    let dxdy = mk(&[(&[x, y], 1.0)]);
    // ---- 1. the rain band on the weather map: edge u, swept by the wind for 3 hours ----
    let (u, v) = ([120.0, 50.0], [30.0, 90.0]);
    let a = ev(&dxdy, &[&u, &v]);
    let c = [[0.0, 0.0], u, [u[0] + v[0], u[1] + v[1]], v];
    let shoe = 0.5 * (0..4).map(|i| { let k = (i + 1) % 4; c[i][0] * c[k][1] - c[k][0] * c[i][1] }).sum::<f64>();
    let grid = |h: f64| -> f64 {                  // count cell centres inside the swept band
        let mut n = 0.0;
        for i in 0..(150.0 / h) as usize {
            for j in 0..(140.0 / h) as usize {
                let (px, py) = ((i as f64 + 0.5) * h, (j as f64 + 0.5) * h);
                let s = (px * v[1] - py * v[0]) / a;
                let tt = (u[0] * py - u[1] * px) / a;
                if 0.0 <= s && s < 1.0 && 0.0 <= tt && tt < 1.0 { n += 1.0; }
            }
        }
        n * h * h
    };
    println!("map: dx^dy(u,v) swept area km2 {}  dx^dy(v,u) {}", f(a), f(ev(&dxdy, &[&v, &u])));
    println!("map: u1v2 u2v1 {} {}  shoelace {}  grid h=2 {}  grid h=1 {}", f(u[0] * v[1]), f(u[1] * v[0]), f(shoe),
             f(grid(2.0)), f(grid(1.0)));
    let (dt, dp) = (one(&[-0.04, 0.03]), one(&[0.01, 0.02]));
    let tp = wedge(&dt, &dp);
    println!("map: dT(u) dT(v) dp(u) dp(v) {} {} {} {}", f(ev(&dt, &[&u])), f(ev(&dt, &[&v])), f(ev(&dp, &[&u])), f(ev(&dp, &[&v])));
    println!("map: dT^dp coefficient {:.6}  on band {}  dp^dT on band {}", tp[&vec![x, y]], f(ev(&tp, &[&u, &v])),
             f(ev(&wedge(&dp, &dt), &[&u, &v])));
    assert!((a - shoe).abs() < 1e-9 && (ev(&dxdy, &[&v, &u]) + a).abs() < 1e-9);
    assert!((grid(1.0) - a).abs() < 0.01 * a);
    assert!((ev(&tp, &[&u, &v]) - (ev(&dt, &[&u]) * ev(&dp, &[&v]) - ev(&dt, &[&v]) * ev(&dp, &[&u]))).abs() < 1e-12);
    // ---- 2. a hillside field in the rain: three shadows kept separately ----
    let (uu, vv) = ([40.0, 10.0, 0.0], [-6.0, 24.0, 18.0]);
    let sh = [ev(&mk(&[(&[y, z], 1.0)]), &[&uu, &vv]), -ev(&mk(&[(&[x, z], 1.0)]), &[&uu, &vv]), ev(&dxdy, &[&uu, &vv])];
    let area = sh.iter().map(|s| s * s).sum::<f64>().sqrt();
    let dot = |p: &[f64], q: &[f64]| p.iter().zip(q).map(|(a, b)| a * b).sum::<f64>();
    let lag = (dot(&uu, &uu) * dot(&vv, &vv) - dot(&uu, &vv).powi(2)).sqrt();
    let q = [1.5, -2.0, -6.0];                    // rain: mm/h east, north, up (falling)
    let rain = mk(&[(&[y, z], q[0]), (&[x, z], -q[1]), (&[x, y], q[2])]);   // q2 dz^dx = -q2 dx^dz
    let w = ev(&rain, &[&uu, &vv]);
    let prism = det(&vec![q.to_vec(), uu.to_vec(), vv.to_vec()]);   // water slab swept in one hour
    println!("hill: shadows dy^dz dz^dx dx^dy m2 {} {} {}", f(sh[0]), f(sh[1]), f(sh[2]));
    println!("hill: true area {}  Lagrange {}  u.v {}", f(area), f(lag), f(dot(&uu, &vv)));
    println!("hill: rain per shadow L/h {} {} {}", f(q[0] * sh[0]), f(q[1] * sh[1]), f(q[2] * sh[2]));
    println!("hill: rain form on field L/h {}  brute {}  prism {}", f(w), f(ev_brute(&rain, &[&uu, &vv])), f(prism));
    println!("hill: depth on slope mm/h {}  level gauge mm/h {}", f(-w / area), f(-q[2]));
    assert!((area - lag).abs() < 1e-9 && (w - prism).abs() < 1e-9);
    assert!((w - ev_brute(&rain, &[&uu, &vv])).abs() < 1e-9);
    let cross = [uu[1] * vv[2] - uu[2] * vv[1], uu[2] * vv[0] - uu[0] * vv[2], uu[0] * vv[1] - uu[1] * vv[0]];   // U x V by components
    assert!((0..3).all(|i| (sh[i] - cross[i]).abs() < 1e-9) && ((0..3).map(|i| q[i] * sh[i]).sum::<f64>() - w).abs() < 1e-9);
    // ---- 3. what breaks ----
    println!("wrong: no sign flip, u1v2+u2v1 {}", f(u[0] * v[1] + u[1] * v[0]));
    println!("wrong: dz^dx read as dx^dz {}", f(q[0] * sh[0] + q[1] * (-sh[1]) + q[2] * sh[2]));
    println!("wrong: ground shadow only {}  water all positive {}", f(q[2] * sh[2]), f((0..3).map(|i| (q[i] * sh[i]).abs()).sum()));
    println!("wrong: edges swapped {}", f(ev(&rain, &[&vv, &uu])));
    let (e1, f1, f2) = ([1.0, 0.0], [0.0, 1.0], [0.0, -1.0]);
    let un = |p: &[f64], q: &[f64]| ev(&dxdy, &[p, q]).abs();
    println!("fails: unsigned area of (e1,f1)+(e1,f2) {}  of (e1,f1+f2) {}", f(un(&e1, &f1) + un(&e1, &f2)),
             f(un(&e1, &[f1[0] + f2[0], f1[1] + f2[1]])));
    // ---- 4. the sign rule ----
    let (al, be) = (one(&[1.0, 2.0, 0.0]), one(&[0.0, 3.0, -1.0]));
    let (ab, ba) = (wedge(&al, &be), wedge(&be, &al));
    println!("rule: a^b {}  b^a {}", lst(&ab), lst(&ba));
    let dz = one(&[0.0, 0.0, 1.0]);
    println!("rule: a^a terms {}  dz^rain {}  rain^dz {}", wedge(&al, &al).len(), f(wedge(&dz, &rain)[&vec![x, y, z]]),
             f(wedge(&rain, &dz)[&vec![x, y, z]]));
    let (p0, p1) = ([3.0, -1.0, 2.0], [0.5, 4.0, 1.0]);
    assert!(ab.iter().all(|(k, v)| (v + ba[k]).abs() < 1e-12) && wedge(&al, &al).is_empty());
    assert!((ev(&ab, &[&p0, &p1]) - (ev(&al, &[&p0]) * ev(&be, &[&p1]) - ev(&al, &[&p1]) * ev(&be, &[&p0]))).abs() < 1e-12);
    // ---- 5. four dimensions: x, y, z, t ----
    let sig = wedge(&one(&[1.0, 2.0, 0.0, 0.0]), &one(&[0.0, 0.0, 3.0, -1.0]));
    let tau = mk(&[(&[x, y], 1.0), (&[z, t], 1.0)]);
    let tt = wedge(&tau, &tau);
    let cnt: Vec<usize> = [2usize, 3, 4, 5].iter()
        .map(|&n| wedge(&one(&vec![1.0; n]), &one(&(1..=n).map(|i| (i * i) as f64).collect::<Vec<_>>())).len()).collect();
    println!("4D: components of a two-form, n = 2 3 4 5: [{}]", cnt.iter().map(|c| c.to_string()).collect::<Vec<_>>().join(", "));
    assert!(cnt.iter().zip([2usize, 3, 4, 5]).all(|(c, n)| *c == n * (n - 1) / 2));
    println!("4D: sig^sig {} terms;  tau^tau {}", wedge(&sig, &sig).len(), f(tt[&vec![x, y, z, t]]));
    let q4: Vec<Vec<f64>> = (0..4).map(|i| (0..4).map(|j| if i == j { 1.0 } else { 0.0 }).collect()).collect();
    let q4r: Vec<&[f64]> = q4.iter().map(|r| &r[..]).collect();
    println!("4D: tau^tau on the unit box, brute {}", f(ev_brute(&tt, &q4r)));
    assert!(wedge(&sig, &sig).is_empty() && (ev_brute(&tt, &q4r) - 2.0).abs() < 1e-12);
    // ---- 6. try changing ----
    println!("try: wind along the edge {}  parallel isotherms {}", f(ev(&dxdy, &[&u, &[60.0, 25.0]])),
             f(ev(&wedge(&one(&[-0.02, -0.04]), &dp), &[&u, &v])));
    println!("try: crosswind north -4 {}", f(ev(&mk(&[(&[y, z], 1.5), (&[x, z], 4.0), (&[x, y], -6.0)]), &[&uu, &vv])));
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-19 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
map: dx^dy(u,v) swept area km2 9300.0000  dx^dy(v,u) -9300.0000
map: u1v2 u2v1 10800.0000 1500.0000  shoelace 9300.0000  grid h=2 9300.0000  grid h=1 9300.0000
map: dT(u) dT(v) dp(u) dp(v) -3.3000 1.5000 2.2000 2.1000
map: dT^dp coefficient -0.001100  on band -10.2300  dp^dT on band 10.2300
hill: shadows dy^dz dz^dx dx^dy m2 180.0000 -720.0000 1020.0000
hill: true area 1261.4278  Lagrange 1261.4278  u.v 0.0000
hill: rain per shadow L/h 270.0000 1440.0000 -6120.0000
hill: rain form on field L/h -4410.0000  brute -4410.0000  prism -4410.0000
hill: depth on slope mm/h 3.4960  level gauge mm/h 6.0000
wrong: no sign flip, u1v2+u2v1 12300.0000
wrong: dz^dx read as dx^dz -7290.0000
wrong: ground shadow only -6120.0000  water all positive 7830.0000
wrong: edges swapped 4410.0000
fails: unsigned area of (e1,f1)+(e1,f2) 2.0000  of (e1,f1+f2) 0.0000
rule: a^b ['3.0000', '-1.0000', '-2.0000']  b^a ['-3.0000', '1.0000', '2.0000']
rule: a^a terms 0  dz^rain -6.0000  rain^dz -6.0000
4D: components of a two-form, n = 2 3 4 5: [1, 3, 6, 10]
4D: sig^sig 0 terms;  tau^tau 2.0000
4D: tau^tau on the unit box, brute 2.0000
try: wind along the edge 0.0000  parallel isotherms 0.0000
try: crosswind north -4 -2970.0000
ALL CHECKS PASS
```

### Lean

Lean proves the three theorems of Why it works, in every dimension, and checks the worked numbers.

- Take a k-form $`\omega`$ in $`n`$ dimensions and $`k`$ edges. Then $`\omega`$ on the edges is the sum over sorted lists $`I`$ of $`\omega_I`$ times the determinant of the edges' parts along $`I`$.
- Take two one-forms $`\alpha`$, $`\beta`$ and two directions $`u`$, $`v`$. Then $`(\alpha \wedge \beta)(u, v) = \alpha(u)\,\beta(v) - \alpha(v)\,\beta(u)`$.
- Take a k-form $`\alpha`$ and an l-form $`\beta`$. Then $`\alpha \wedge \beta = (-1)^{kl}\,\beta \wedge \alpha`$.
- The band's ground shadow is 9300 km², and −9300 km² with the arrows swapped.
- The field's three shadows are 180, −720 and 1020 m².
- The rain form gives −4410 L/h on the field, and the slab determinant gives −4410 too.
- A two-form in two, three, four and five dimensions has 1, 3, 6 and 10 weights.

The grid count, the shoelace, the weather wedge, the four-dimensional test and the decimals are left to the Python and Rust checks.

```lean
-- Differential form: every k-form is a sum of its weights times shadow determinants, the wedge of two one-forms is a two-by-two determinant, and swapping a k-form and an l-form multiplies by (-1)^(kl).
import Mathlib.LinearAlgebra.ExteriorPower.Pairing
import Mathlib.LinearAlgebra.ExteriorPower.Basis
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Data.Finset.Sort
import Mathlib.Data.Real.Basic

open scoped BigOperators

/-- A k-form at a point of n-dimensional space (a rule that takes k directions, is linear in
each, and flips sign when two directions swap) is fixed by its weights: on any k edges it equals
the sum, over every sorted list `I` of k different axes, of its value on the unit arrows along
those axes times the k-by-k determinant of the edges' parts along the axes in `I`, the signed
size of the box's shadow on that coordinate k-plane. For k = 2 this says every two-form is
`∑_{i<j} ω_ij dx^i ∧ dx^j`. -/
theorem k_form_eq_sum_weights_mul_shadow_dets {n k : ℕ}
    (ω : (Fin n → ℝ) [⋀^Fin k]→ₗ[ℝ] ℝ) (v : Fin k → Fin n → ℝ) :
    ω v = ∑ I : {I : Finset (Fin n) // I.card = k},
      ω (fun m => Pi.single (I.1.orderEmbOfFin I.2 m) (1 : ℝ)) *
        Matrix.det (Matrix.of fun m j => v j (I.1.orderEmbOfFin I.2 m)) := by
  set b := Pi.basisFun ℝ (Fin n)
  set B := b.exteriorPower k
  set φ := exteriorPower.alternatingMapLinearEquiv ω
  rw [← exteriorPower.alternatingMapLinearEquiv_apply_ιMulti ω v, ← B.sum_repr
    (exteriorPower.ιMulti ℝ k v), map_sum]
  refine Fintype.sum_equiv (ι := ↥(Set.powersetCard (Fin n) k))
    (κ := {I : Finset (Fin n) // I.card = k}) (Equiv.refl _) _ _ ?_
  intro s
  rw [map_smul, smul_eq_mul, mul_comm, exteriorPower.basis_repr_apply,
    exteriorPower.ιMultiDual_apply_ιMulti, exteriorPower.basis_apply,
    exteriorPower.ιMulti_family, exteriorPower.alternatingMapLinearEquiv_apply_ιMulti,
    ← Matrix.det_transpose, Set.powersetCard.ofFinEmbEquiv_symm_apply]
  congr 2
  funext m
  simp [b]
  rfl

/-- The wedge of two one-forms, taken in Mathlib's exterior algebra of the dual space, measures
two directions by `(α ∧ β)(u, v) = α(u) β(v) - α(v) β(u)`: the first form on the first direction
times the second form on the second, minus the same with the directions swapped. -/
theorem wedge_of_one_forms_apply {V : Type*} [AddCommGroup V] [Module ℝ V]
    (α β : Module.Dual ℝ V) (u v : V) :
    exteriorPower.pairingDual ℝ V 2 (exteriorPower.ιMulti ℝ 2 ![α, β])
        (exteriorPower.ιMulti ℝ 2 ![u, v]) = α u * β v - α v * β u := by
  rw [exteriorPower.pairingDual_ιMulti_ιMulti, Matrix.det_fin_two]
  simp
  ring

/-- The sign rule: for a k-form `α` and an l-form `β`, `α ∧ β = (-1)^(kl) β ∧ α`. -/
theorem wedge_comm_sign {V : Type*} [AddCommGroup V] [Module ℝ V] {k l : ℕ}
    (α : ⋀[ℝ]^k (Module.Dual ℝ V)) (β : ⋀[ℝ]^l (Module.Dual ℝ V)) :
    (α : ExteriorAlgebra ℝ (Module.Dual ℝ V)) * β =
      (-1 : ℝ) ^ (k * l) • ((β : ExteriorAlgebra ℝ (Module.Dual ℝ V)) * α) := by
  have amem : α.1 ∈ ⋀[ℝ]^k (Module.Dual ℝ V) := α.2
  have bmem : β.1 ∈ ⋀[ℝ]^l (Module.Dual ℝ V) := β.2
  rw [← (Submodule.ext_iff.mp (ExteriorAlgebra.ιMulti_span_fixedDegree ℝ _))] at amem bmem
  refine Submodule.span_induction₂ (p := fun x y _ _ ↦
    x * y = (-1 : ℝ) ^ (k * l) • (y * x)) ?_ ?_ ?_ ?_ ?_ ?_ ?_ amem bmem
  · rintro x y ⟨mx, rfl⟩ ⟨my, rfl⟩
    rw [ExteriorAlgebra.ιMulti_mul_ιMulti_anticomm, Units.smul_def, Units.val_pow_eq_pow_val,
      Units.val_neg, Units.val_one, ← Int.cast_smul_eq_zsmul ℝ]
    push_cast
    rw [mul_comm]
  all_goals try simp +contextual [add_mul, mul_add, smul_add]
  all_goals intro r x y _ _ h; rw [smul_comm]

-- The band on the weather map: u = (120, 50) km, v = (30, 90) km; the ground shadow
-- u₁v₂ - u₂v₁ is 9300 km², and -9300 km² with the arrows swapped.
example : Matrix.det !![(120 : ℤ), 30; 50, 90] = 9300 := by
  norm_num [Matrix.det_fin_two]
example : Matrix.det !![(30 : ℤ), 120; 90, 50] = -9300 := by
  norm_num [Matrix.det_fin_two]

-- The hillside field: u = (40, 10, 0) m, v = (-6, 24, 18) m; its three shadows
-- dy∧dz, dz∧dx, dx∧dy are 180, -720 and 1020 m².
example : (10 : ℤ) * 18 - 0 * 24 = 180 := by norm_num
example : (0 : ℤ) * (-6) - 40 * 18 = -720 := by norm_num
example : (40 : ℤ) * 24 - 10 * (-6) = 1020 := by norm_num

-- The rain form with weights P = 3/2, Q = -2, R = -6 (mm/h) on the field: -4410 L/h,
-- and the same from the three-by-three slab determinant of q, u and v.
example : (3 / 2 : ℚ) * 180 + (-2) * (-720) + (-6) * 1020 = -4410 := by norm_num
example : Matrix.det !![(3 / 2 : ℚ), -2, -6; 40, 10, 0; -6, 24, 18] = -4410 := by
  norm_num [Matrix.det_fin_three]

-- A two-form in n dimensions has one weight per pair of axes: 1, 3, 6, 10 for n = 2, 3, 4, 5.
example : [2, 3, 4, 5].map (fun n => n * (n - 1) / 2) = [1, 3, 6, 10] := by decide
example : Fintype.card {I : Finset (Fin 4) // I.card = 2} = 6 := by decide

#print axioms k_form_eq_sum_weights_mul_shadow_dets
#print axioms wedge_of_one_forms_apply
#print axioms wedge_comm_sign
```

**Checked 2026-11-19 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'k_form_eq_sum_weights_mul_shadow_dets' depends on axioms: [propext, Classical.choice, Quot.sound]
'wedge_of_one_forms_apply' depends on axioms: [propext, Classical.choice, Quot.sound]
'wedge_comm_sign' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> - Guess first: what if the wind blows along the band's edge, 60 km east and 25 km north? Change `v` in the area line. Answer: 0 km². The edge slides along itself and sweeps nothing.
> - Guess first: what if the isotherms run parallel to the isobars? Use $`dT = -0.02\,dx - 0.04\,dy`$, which is a multiple of $`dp`$. Answer: $`dT \wedge dp = 0`$ on the band: no solenoids, so no circulation is driven.
> - Guess first: what if the rain drifts south at 4 mm/h instead of 2? Change $`q_2`$ to −4. Answer: −2970 L/h. The field sits further in the lee.
> - Guess first: what if the rain falls straight down? Set $`q_1 = q_2 = 0`$. Answer: −6120 L/h, the ground shadow times 6 mm/h.

---

## The usual mistake

> [!warning]
> **The biggest trap is reading $`dx \wedge dy`$ as an ordinary product, where order does not matter.** It is a signed area, and $`dy \wedge dx = -dx \wedge dy`$. Ignoring the order turns the band's 9300 km² into 12300 km², because the term that should be subtracted is added.
>
> - **Edges in the wrong order.** The rain form on $`(v, u)`$ gives +4410 L/h: the same amount of water, reported as rising off the field.
> - **Sorting without paying the sign.** Rewriting $`Q\,dz \wedge dx`$ as $`Q\,dx \wedge dz`$ gives −7290 L/h instead of −4410.
> - **Taking $`dx \wedge dx`$ as "dx squared".** It is 0: an edge with itself spans nothing.
> - **Taking every two-form for an arrow.** That works only in three dimensions. In four, $`dx \wedge dy + dz \wedge dt`$ wedged with itself gives $`2\,dx \wedge dy \wedge dz \wedge dt`$, not 0, so it is not one plane, and no arrow stands for it.

---

## Where you meet it in real life

- **Rain on hillsides.** Hydrologists correct gauge readings for slope and wind. A slope facing into wind-driven rain catches more than a level gauge, and a slope in the lee catches less, as the field's 3.4960 against 6 mm/h shows. The calculation is the rain two-form on the slope's edges.
- **Weather maps and circulation.** Bjerknes's circulation theorem counts solenoids: the small boxes formed by crossing isobars with lines of equal specific volume (volume per kilogram of air), which at one pressure moves in step with temperature. That count is a wedge like $`dT \wedge dp`$. It is zero when the lines run parallel, and its sign sets which way a sea breeze turns.
- **Engine cycles.** On a temperature–entropy chart, the area a heat engine's cycle encloses is the net work per cycle. That area is the two-form $`dT \wedge dS`$, with $`S`$ the entropy, and the sign tells an engine from a refrigerator.
- **Computer graphics.** A renderer finds whether a triangle faces the camera from the sign of $`dx \wedge dy`$ on two of its edges on the screen, and skips the back faces.
- **Electromagnetism.** In space and time, the electric and magnetic fields together form one two-form with six weights, three electric and three magnetic: [Hodge star](09-hodge-star-and-maxwell-in-forms.md).

> **Say it back**
> A one-form reads one number off a direction, such as its east part. The wedge of one-forms measures the signed size of the box their directions span, and swapping two directions flips the sign. A two-form is a weighted sum of a box's shadow areas on the coordinate planes, with one weight per pair of axes. A k-form does the same with k directions and k-by-k determinants. Swapping a k-form with an l-form multiplies by minus one to the power kl.

---

## What this builds on

- [Cross product](../../05-Geometry%20and%20trig/05-Vectors%20in%20Space/01-cross-product-and-oriented-area.md) writes each part of the cross product as the signed area of a shadow on a coordinate plane. A two-form keeps those shadows as separate measurements.
- [Determinants](../../03-Algebra/05-Solving%20Systems/04-determinants.md) gives signed area and volume, linear in each column and flipping sign on a swap. Every form here is built from them.

---

## Where this goes next

- [Pullback](02-pullback-and-change-of-variables.md), the next card, carries a form backwards through a map. It explains why a change of coordinates multiplies a two-form by a Jacobian determinant.
- [Exterior derivative](03-exterior-derivative.md) turns a k-form into a (k+1)-form, with the wedge's sign rule built in.
- [Integration on an oriented manifold](05-integration-on-manifolds.md) adds up a form over a whole surface, where the weights change from point to point.
- [Symplectic form](10-symplectic-form-and-hamiltonian-flow.md) is one particular two-form, the one behind Hamiltonian mechanics.

The question this card leaves open: when the weights change from point to point, which rates of change of a form mean something regardless of the chart?

---

## Sources

Verified 2026-11-19: every link below resolves to the publisher's page.

- Spivak, M. *Calculus on Manifolds*. CRC Press, 2018 reissue. [doi:10.1201/9780429501906](https://doi.org/10.1201/9780429501906). Chapter 4 builds alternating tensors, the wedge product and its sign rule from first principles.
- Lee, J. M. *Introduction to Smooth Manifolds*, 2nd ed. Springer, 2012. [doi:10.1007/978-1-4419-9982-5](https://doi.org/10.1007/978-1-4419-9982-5). Chapters 12 and 14 give k-covectors, the determinant formula for basic forms, and differential forms as fields.
- Thorpe, A. J., Volkert, H. and Ziemiański, M. J. "The Bjerknes' circulation theorem: a historical perspective." *Bulletin of the American Meteorological Society* 84 (2003), 471–480. [doi:10.1175/BAMS-84-4-471](https://doi.org/10.1175/BAMS-84-4-471). The solenoid count on weather charts.
- Sharon, D. "The distribution of hydrologically effective rainfall incident on sloping ground." *Journal of Hydrology* 46 (1980), 165–188. [doi:10.1016/0022-1694(80)90041-4](https://doi.org/10.1016/0022-1694%2880%2990041-4). Rain caught by slopes facing toward and away from the wind.
