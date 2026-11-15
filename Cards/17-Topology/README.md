<a name="top"></a>

[Syllabus](../../SYLLABUS.md) → Topology

# 17 · Topology

Work in a metric or an abstract topological space, and prove the compactness and connectedness facts that every analysis wing has been leaning on. Classify a closed surface by hand, compute a fundamental group and a homology group on a concrete example, and run persistent homology on real data while saying honestly what it is worth.

6 shelves · **28 of 51 cards ready to read**

Click a shelf to jump to its cards, then click a card's title to read it. A title without a link is planned and not written yet.

| Shelf | Cards | Ready to read |
| --- | ---: | ---: |
| [01 · Metric Spaces](#s01) | 10 | 10 of 10 |
| [02 · Topological Spaces](#s02) | 10 | 10 of 10 |
| [03 · Surfaces and Manifolds](#s03) | 8 | 8 of 8 |
| [04 · Homotopy](#s04) | 8 | 0 of 8 · planned |
| [05 · Homology](#s05) | 8 | 0 of 8 · planned |
| [06 · Topological Data Analysis](#s06) | 7 | 0 of 7 · planned |

<a name="s01"></a>

## 01 · Metric Spaces · 10 cards

*The three distance rules, the vocabulary they generate, and the four theorems that need completeness*

1. [Metric space: the three rules that make a distance mean something](01-Metric%20Spaces/01-metric-spaces.md)
2. [The distance menu: straight-line, taxicab, worst-case, and distance between whole shapes](01-Metric%20Spaces/02-distances-on-vectors-and-functions.md)
3. [Open balls, open sets and closed sets: the vocabulary a distance hands you](01-Metric%20Spaces/03-open-and-closed-sets.md)
4. [Limits and continuity with distances: epsilon and delta in any metric space](01-Metric%20Spaces/04-convergence-and-continuity-in-metric-spaces.md)
5. [Complete space: bunched-up sequences land somewhere, and how to fill in the gaps](01-Metric%20Spaces/05-completeness-and-completion.md)
6. [Compactness three ways: finite covers, convergent subsequences, closed and bounded](01-Metric%20Spaces/06-compactness-in-metric-spaces.md)
7. [Uniform continuity: one tolerance for the whole space, and free on a compact set](01-Metric%20Spaces/07-uniform-continuity-and-heine-cantor.md)
8. [Banach's fixed point theorem: a shrinking map on a complete space has one fixed point](01-Metric%20Spaces/08-banach-fixed-point-in-metric-spaces.md)
9. [Arzela-Ascoli: when a whole family of functions has a convergent subsequence](01-Metric%20Spaces/09-arzela-ascoli.md)
10. [Baire category theorem: a complete space is never a countable pile of thin sets](01-Metric%20Spaces/10-baire-category-theorem.md)

[↑ Back to the shelves](#top)

<a name="s02"></a>

## 02 · Topological Spaces · 10 cards

*Nearness with no distances at all, the three standard constructions, and the separation and compactness theorems*

1. [Topological space: you name the open sets, and a basis generates them](02-Topological%20Spaces/01-topological-spaces-and-bases.md)
2. [Closure, interior and boundary: the solid inside, the edge, and everything a set touches](02-Topological%20Spaces/02-closure-interior-and-boundary.md)
3. [Continuity by pre-images, and homeomorphism: when two shapes are the same for topology](02-Topological%20Spaces/03-continuity-and-homeomorphism.md)
4. [Subspace, product and quotient: cutting a piece out, pairing up, gluing points together](02-Topological%20Spaces/04-subspace-product-and-quotient-topologies.md)
5. [Hausdorff and its ladder: how far apart open sets can pry two points](02-Topological%20Spaces/05-separation-axioms-and-hausdorff.md)
6. [Compactness with no distances, and Tychonoff: any product of compact spaces is compact](02-Topological%20Spaces/06-compactness-and-tychonoff.md)
7. [Connected and path-connected: one piece, and one piece you can walk across](02-Topological%20Spaces/07-connectedness-and-path-connectedness.md)
8. [What compactness and connectedness buy: attained maxima, crossed values, free inverses](02-Topological%20Spaces/08-images-of-compact-and-connected-sets.md)
9. [The test spaces: discrete, indiscrete, cofinite, the Cantor set, and what each one breaks](02-Topological%20Spaces/09-standard-examples-and-counterexamples.md)
10. [Urysohn and Tietze: a dial between closed sets, and when a space is secretly metric](02-Topological%20Spaces/10-urysohn-tietze-and-metrisation.md)

[↑ Back to the shelves](#top)

<a name="s03"></a>

## 03 · Surfaces and Manifolds · 8 cards

*Spaces that look flat up close, the complete list of closed surfaces, and the invariants that separate them*

1. [Topological manifold: a space that looks like ordinary flat space up close](03-Surfaces%20and%20Manifolds/01-topological-manifolds.md)
2. [Closed surfaces classified: a sphere with handles or crosscaps, and nothing else](03-Surfaces%20and%20Manifolds/02-surfaces-and-the-classification-theorem.md)
3. [Orientability: whether a surface has two sides, and the famous ones that do not](03-Surfaces%20and%20Manifolds/03-orientability-mobius-strip-and-klein-bottle.md)
4. [Euler characteristic: vertices minus edges plus faces, the number bending cannot change](03-Surfaces%20and%20Manifolds/04-euler-characteristic-and-triangulations.md)
5. [Jordan curve theorem: a simple closed loop cuts the plane into an inside and an outside](03-Surfaces%20and%20Manifolds/05-jordan-curve-theorem.md)
6. [Knots and links: closed loops in space, their flat diagrams, and what an invariant is](03-Surfaces%20and%20Manifolds/06-knots-and-invariants-in-outline.md)
7. [Reidemeister moves and the three-colour test: proof that the trefoil cannot be untied](03-Surfaces%20and%20Manifolds/07-reidemeister-moves-and-tricolourability.md)
8. [Knot polynomials in outline: one skein rule turns a diagram into a polynomial](03-Surfaces%20and%20Manifolds/08-knot-polynomials-in-outline.md)

[↑ Back to the shelves](#top)

<a name="s04"></a>

## 04 · Homotopy · 8 cards · planned

*Deforming maps continuously, the group of loops, and the two fixed-point theorems it pays for*

1. Homotopy: sliding one map into another, and spaces that squash into each other
2. Contractible and simply connected: no holes at all, and every loop can be shrunk
3. The fundamental group: loops at a point, multiplied by running one after the other
4. The circle's fundamental group is the integers: winding number does all the counting
5. Covering spaces: unroll a space so its loops become paths you can follow
6. Van Kampen's theorem: glue two pieces together and glue their loop groups together
7. CW complexes: build a space by gluing cells, then read its invariants off the recipe
8. Brouwer and Borsuk-Ulam: a disc map fixes a point, and antipodes give equal readings

[↑ Back to the shelves](#top)

<a name="s05"></a>

## 05 · Homology · 8 cards · planned

*Counting holes with linear algebra: chains, cycles, boundaries, and the sequences that compute them*

1. Simplicial complexes and chains: triangles glued up, with a boundary that squares to zero
2. Homology groups: cycles that are not boundaries, one hole count per dimension
3. Smith normal form: the matrix routine that turns boundary matrices into hole counts
4. Homotopy invariance: spaces you can deform into each other have identical hole counts
5. Cellular homology: hole counts read straight off the gluing recipe, quick by hand
6. Mayer-Vietoris and exact sequences: the holes of a whole from two overlapping pieces
7. Homology of spheres, and degree: how many times one sphere wraps around another
8. Cohomology and the cup product in outline: the dual view, carrying a multiplication

[↑ Back to the shelves](#top)

<a name="s06"></a>

## 06 · Topological Data Analysis · 7 cards · planned

*Turning data into shapes at every scale, reading the diagram, and knowing when to believe it*

1. Filtration and persistent homology: watch each hole appear and close as the scale grows
2. Vietoris-Rips, Cech and alpha complexes: three ways to make a shape out of points
3. The persistence algorithm: column reduction pairs every birth with its death
4. Persistence diagram and stability: noise in the data moves the picture only a little
5. Comparing diagrams: bottleneck distance, landscapes, images, and honest error bars
6. Mapper and Reeb graphs: a network summary of a dataset along a chosen lens
7. Persistence in practice: the shape of a time series, and what that shape is worth

[↑ Back to the shelves](#top)

---

[← 16 · Numerical analysis](../16-Numerical%20analysis/README.md) · [All wings](../../SYLLABUS.md) · [18 · Functional analysis →](../18-Functional%20analysis/README.md)
