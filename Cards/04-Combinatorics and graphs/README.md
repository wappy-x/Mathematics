<a name="top"></a>

[Syllabus](../../SYLLABUS.md) → Combinatorics and graphs

# 04 · Combinatorics and graphs

Count any finite arrangement (orderings, selections, distributions, partitions) by formula and by brute-force listing, and turn a step rule or a counting problem into a recurrence or a generating function and read the answer off. Model a network as a graph and compute or prove the standard facts: degrees, paths and connectivity, trees and cheapest routes, Euler and Hamilton tours, planarity, colourings, matchings and flows, with Ramsey and extremal results in outline.

14 shelves · **82 of 82 cards ready to read**

Click a shelf to jump to its cards, then click a card's title to read it.

| Shelf | Cards |
| --- | ---: |
| [01 · Counting Principles](#s01) | 6 |
| [02 · Repeats, Groups and Double Counting](#s02) | 5 |
| [03 · Binomial Coefficients and Identities](#s03) | 7 |
| [04 · Inclusion-Exclusion and Pigeonhole](#s04) | 5 |
| [05 · Recurrences](#s05) | 7 |
| [06 · Lattice Paths and Catalan Numbers](#s06) | 5 |
| [07 · Generating Functions](#s07) | 5 |
| [08 · Partitions](#s08) | 6 |
| [09 · Graphs: Dots and Lines](#s09) | 7 |
| [10 · Trees and Cheapest Routes](#s10) | 6 |
| [11 · Tours: Euler and Hamilton](#s11) | 5 |
| [12 · Planarity and Colouring](#s12) | 6 |
| [13 · Matchings and Flows](#s13) | 7 |
| [14 · Ramsey and Extremal, in Outline](#s14) | 5 |

<a name="s01"></a>

## 01 · Counting Principles · 6 cards

*Sum and product rules with dependent choices, strings with repetition and the power set, factorials, ordered picks, n choose k, and counting the complement. Needs only wing 01 arithmetic, sets and functions.*

1. [The rules of sum and product: add the options when they cannot overlap, multiply when they come in stages](01-Counting%20Principles/01-rules-of-sum-and-product.md)
2. [Strings with repetition: when every position may reuse the options, the count is a power](01-Counting%20Principles/02-strings-and-powers.md)
3. [Factorials: the number of ways to line things up, and how fast it explodes](01-Counting%20Principles/03-factorial.md)
4. [Ordered picks: choosing k of n in order is the falling factorial n(n-1)...(n-k+1)](01-Counting%20Principles/04-ordered-picks.md)
5. [Combinations, n choose k: unordered picks are ordered picks divided by k!, the workhorse of counting](01-Counting%20Principles/05-n-choose-k.md)
6. [Counting the complement: when 'at least one' is hard, count 'none' and subtract from everything](01-Counting%20Principles/06-complementary-counting.md)

[↑ Back to the shelves](#top)

<a name="s02"></a>

## 02 · Repeats, Groups and Double Counting · 5 cards

*Arrangements with repeated items, distributing identical items (stars and bars, compositions), splitting into named and unnamed groups, circular arrangements, and proving a count by bijection or by counting twice.*

1. [Arranging with repeats: divide out the orderings of the identical copies](02-Repeats%2C%20Groups%20and%20Double%20Counting/01-multiset-permutations.md)
2. [Stars and bars: identical items into labelled boxes, counted by placing dividers](02-Repeats%2C%20Groups%20and%20Double%20Counting/02-stars-and-bars.md)
3. [Splitting into groups: the multinomial coefficient for named piles, and divide by k! when the piles are not named](02-Repeats%2C%20Groups%20and%20Double%20Counting/03-splitting-into-groups.md)
4. [Round tables and bracelets: fix one seat to kill the rotations, halve again if flipping counts the same](02-Repeats%2C%20Groups%20and%20Double%20Counting/04-circular-arrangements.md)
5. [Bijections and double counting: match two collections one-to-one, or count one collection two ways, and the numbers must agree](02-Repeats%2C%20Groups%20and%20Double%20Counting/05-bijection-and-double-counting.md)

[↑ Back to the shelves](#top)

<a name="s03"></a>

## 03 · Binomial Coefficients and Identities · 7 cards

*Pascal's rule and triangle, the binomial theorem with the multinomial version, Vandermonde, hockey stick, the committee-chair (absorption) identity, alternating sums and binomial inversion, the central binomial coefficient and crude bounds.*

1. [Pascal's rule: each entry is the sum of the two above it, so the whole triangle builds itself and each row sums to 2^n](03-Binomial%20Coefficients%20and%20Identities/01-pascals-rule-and-the-triangle.md)
2. [The binomial theorem: (a + b)^n expands with choice counts as coefficients, and so does (a + b + c)^n](03-Binomial%20Coefficients%20and%20Identities/02-binomial-theorem.md)
3. [Vandermonde's identity: choosing from two merged groups splits by how many come from each](03-Binomial%20Coefficients%20and%20Identities/03-vandermonde-identity.md)
4. [The hockey stick: adding down a diagonal of the triangle lands one step below and right](03-Binomial%20Coefficients%20and%20Identities/04-hockey-stick-identity.md)
5. [Committee and chair: k C(n,k) = n C(n-1,k-1), so the weighted row sum is n 2^(n-1)](03-Binomial%20Coefficients%20and%20Identities/05-committee-chair-identity.md)
6. [Alternating sums: a row added with alternating signs cancels to zero, which lets you undo a binomial sum](03-Binomial%20Coefficients%20and%20Identities/06-alternating-sums-and-binomial-inversion.md)
7. [The middle of the row: C(2n,n) is the biggest entry, and cheap bounds size any choice count without computing it](03-Binomial%20Coefficients%20and%20Identities/07-central-binomial-and-bounds.md)

[↑ Back to the shelves](#top)

<a name="s04"></a>

## 04 · Inclusion-Exclusion and Pigeonhole · 5 cards

*The n-set inclusion-exclusion formula, derangements, counting onto functions, stopping the sieve early (union bound and Bonferroni), and the pigeonhole principle extended beyond wing 01.*

1. [Inclusion-exclusion for any number of sets: add, subtract the pairs, add the triples, and every element ends up counted once](04-Inclusion-Exclusion%20and%20Pigeonhole/01-inclusion-exclusion-for-n-sets.md)
2. [Derangements: shuffles where nothing lands in its own place, counted by the sieve](04-Inclusion-Exclusion%20and%20Pigeonhole/02-derangements.md)
3. [Onto functions: hand out every item so nobody is left empty-handed, counted by the sieve](04-Inclusion-Exclusion%20and%20Pigeonhole/03-counting-surjections.md)
4. [Stopping the sieve early: the first term over-counts, two terms under-count, and both are guaranteed bounds](04-Inclusion-Exclusion%20and%20Pigeonhole/04-union-bound-and-bonferroni.md)
5. [Pigeonhole, extended: n items in k boxes force a box with at least n/k rounded up, and choosing the boxes is the whole trick](04-Inclusion-Exclusion%20and%20Pigeonhole/05-pigeonhole-extended.md)

[↑ Back to the shelves](#top)

<a name="s05"></a>

## 05 · Recurrences · 7 cards

*Step rules: Fibonacci and tilings, finite differences and telescoping sums, first-order affine recurrences and loan schedules, the characteristic equation and Binet, driving terms, recurrences as matrix powers, and divide-and-conquer recurrences with the master theorem.*

1. [Recurrences: a rule for the next term from the last few, with Fibonacci as the first example](05-Recurrences/01-recurrences-and-fibonacci.md)
2. [Finite differences: the jump from one term to the next, and sums that collapse because consecutive terms cancel](05-Recurrences/02-finite-differences-and-telescoping-sums.md)
3. [First-order recurrences: multiply by a factor and add a constant, the fixed point is the anchor, and a loan is the model](05-Recurrences/03-first-order-recurrences-and-loans.md)
4. [The characteristic equation: try r^n, solve a quadratic, and any two-term step rule becomes a formula](05-Recurrences/04-characteristic-equation-and-binet.md)
5. [Recurrences with a driving term: guess a particular solution of the same shape, add the homogeneous part, fit the seeds](05-Recurrences/05-nonhomogeneous-recurrences.md)
6. [A recurrence is a matrix: stack the last two terms, multiply by a fixed matrix, and matrix powers jump far ahead](05-Recurrences/06-recurrences-as-matrix-powers.md)
7. [Divide-and-conquer recurrences: split the job in half, and the master theorem reads off the total work](05-Recurrences/07-divide-and-conquer-recurrences.md)

[↑ Back to the shelves](#top)

<a name="s06"></a>

## 06 · Lattice Paths and Catalan Numbers · 5 cards

*Grid routes as choice counts, the reflection principle and the ballot problem, Catalan numbers and the structures they count, and the path counts a random walk needs.*

1. [Lattice paths: routes across a grid are choice counts, and Pascal's triangle is the map](06-Lattice%20Paths%20and%20Catalan%20Numbers/01-lattice-paths.md)
2. [The reflection principle: mirror the bad paths onto ones that are easy to count, and the ballot problem falls out](06-Lattice%20Paths%20and%20Catalan%20Numbers/02-reflection-principle-and-ballot-problem.md)
3. [Catalan numbers: paths that never dip below the start, balanced brackets, and the formula C(2n,n)/(n+1)](06-Lattice%20Paths%20and%20Catalan%20Numbers/03-catalan-numbers.md)
4. [Catalan everywhere: brackets, mountain ranges, binary trees, polygon triangulations and non-crossing handshakes are the same count](06-Lattice%20Paths%20and%20Catalan%20Numbers/04-catalan-bijections.md)
5. [Counting coin-flip paths: how many end at a given height, how many return to zero, how many never touch it](06-Lattice%20Paths%20and%20Catalan%20Numbers/05-random-walk-path-counts.md)

[↑ Back to the shelves](#top)

<a name="s07"></a>

## 07 · Generating Functions · 5 cards

*Ordinary generating functions as formal bookkeeping, products as convolutions and constrained counting, solving recurrences, exponential generating functions for labelled objects, and the Catalan generating function.*

1. [Generating functions: hang a sequence on powers of x, and adding or multiplying series does the counting](07-Generating%20Functions/01-ordinary-generating-functions.md)
2. [Counting by multiplying series: each constraint is a factor, and the answer is one coefficient](07-Generating%20Functions/02-counting-with-generating-functions.md)
3. [Solving a recurrence with a generating function: the step rule becomes an equation for the series, and a ratio of polynomials falls out](07-Generating%20Functions/03-generating-functions-solve-recurrences.md)
4. [Exponential generating functions: divide each count by n! and the series multiplies labelled objects correctly](07-Generating%20Functions/04-exponential-generating-functions.md)
5. [The Catalan generating function: the first-return recurrence becomes C = 1 + x C^2, solved by iteration](07-Generating%20Functions/05-catalan-generating-function.md)

[↑ Back to the shelves](#top)

<a name="s08"></a>

## 08 · Partitions · 6 cards

*Integer partitions and Ferrers diagrams, Euler's product, set partitions and Bell numbers, Stirling numbers of the second kind, permutations counted by cycles, and the twelvefold way as the wing's counting map.*

1. [Integer partitions: a number as a sum of whole parts with order ignored, drawn as rows of dots](08-Partitions/01-integer-partitions.md)
2. [Euler's product: one geometric factor per part size, and the coefficients count partitions](08-Partitions/02-partitions-generating-function.md)
3. [Set partitions and Bell numbers: splitting distinct people into unnamed teams of any sizes](08-Partitions/03-set-partitions-and-bell-numbers.md)
4. [Stirling numbers of the second kind: distinct items into exactly k unnamed non-empty groups](08-Partitions/04-stirling-numbers-second-kind.md)
5. [Counting shuffles by their loops: Stirling numbers of the first kind, and derangements are the no-short-loop case](08-Partitions/05-permutations-by-cycles.md)
6. [The twelvefold way: every 'put n things into k boxes' question in one table](08-Partitions/06-twelvefold-way.md)

[↑ Back to the shelves](#top)

<a name="s09"></a>

## 09 · Graphs: Dots and Lines · 7 cards

*Graphs and the named families, degrees and the handshaking lemma, walks/paths/cycles with distance, connectivity and breadth-first search, bipartite graphs and odd cycles, directed graphs and DAGs with topological order, and the adjacency matrix.*

1. [Graphs: dots joined by lines, the named families, and when two drawings are the same graph](09-Graphs%20-%20Dots%20and%20Lines/01-graphs-vertices-and-edges.md)
2. [Degrees and the handshaking lemma: the degrees add to twice the edges, so the odd-degree vertices come in pairs](09-Graphs%20-%20Dots%20and%20Lines/02-degree-and-handshaking.md)
3. [Walks, paths and cycles: a wander, a route with no repeats, and a closed loop, with distance measured in steps](09-Graphs%20-%20Dots%20and%20Lines/03-walks-paths-and-cycles.md)
4. [Connected or not: breadth-first search explores ring by ring, finds the pieces, and gives shortest routes when every step costs the same](09-Graphs%20-%20Dots%20and%20Lines/04-connectivity-and-breadth-first-search.md)
5. [Bipartite graphs: two sides with no edges inside a side, exactly when there is no odd cycle](09-Graphs%20-%20Dots%20and%20Lines/05-bipartite-graphs-and-odd-cycles.md)
6. [Directed graphs: arrows instead of lines, and a graph with no way back can be lined up so every arrow points forward](09-Graphs%20-%20Dots%20and%20Lines/06-directed-graphs-and-topological-order.md)
7. [The adjacency matrix: a grid of ones and zeros, and its powers count walks of each length](09-Graphs%20-%20Dots%20and%20Lines/07-adjacency-matrix-and-walk-counting.md)

[↑ Back to the shelves](#top)

<a name="s10"></a>

## 10 · Trees and Cheapest Routes · 6 cards

*Trees and their characterisations, rooted and binary trees, spanning trees and Cayley's formula, minimum spanning trees by Kruskal and Prim, Dijkstra, and Bellman-Ford with negative cycles as currency arbitrage.*

1. [Trees: connected with no cycles, exactly one fewer edge than vertices, and one route between any two points](10-Trees%20and%20Cheapest%20Routes/01-trees.md)
2. [Rooted trees: hang a tree from one vertex and you get parents, children, depth and the shape behind every file system](10-Trees%20and%20Cheapest%20Routes/02-rooted-and-binary-trees.md)
3. [Spanning trees: a loop-free skeleton reaching every vertex, and K(n) has n^(n-2) of them](10-Trees%20and%20Cheapest%20Routes/03-spanning-trees-and-cayleys-formula.md)
4. [The cheapest skeleton: Kruskal adds the cheapest safe edge, Prim grows from one vertex, and the cut property says both are right](10-Trees%20and%20Cheapest%20Routes/04-minimum-spanning-trees.md)
5. [Dijkstra's algorithm: settle the cheapest unsettled point, relax its neighbours, and the cheapest routes appear when no cost is negative](10-Trees%20and%20Cheapest%20Routes/05-dijkstra.md)
6. [Bellman-Ford: relax every edge n - 1 times, negative costs allowed, and a loop that still improves is a money machine](10-Trees%20and%20Cheapest%20Routes/06-bellman-ford-and-arbitrage.md)

[↑ Back to the shelves](#top)

<a name="s11"></a>

## 11 · Tours: Euler and Hamilton · 5 cards

*Euler circuits and trails with Hierholzer's construction, the Chinese postman problem, Hamiltonian cycles with Dirac's condition, the travelling salesman problem in outline, and de Bruijn sequences.*

1. [Euler circuits: a closed route using every edge once exists exactly when the graph is connected and every degree is even](11-Tours%20-%20Euler%20and%20Hamilton/01-euler-circuits.md)
2. [The Chinese postman: when no Euler circuit exists, pair up the odd vertices as cheaply as possible and walk those streets twice](11-Tours%20-%20Euler%20and%20Hamilton/02-chinese-postman.md)
3. [Hamiltonian cycles: visit every vertex once and return, with no quick test, but enough edges guarantee one](11-Tours%20-%20Euler%20and%20Hamilton/03-hamiltonian-cycles.md)
4. [The travelling salesman: the cheapest Hamiltonian cycle, brute force for a few cities, and why nobody has a fast method](11-Tours%20-%20Euler%20and%20Hamilton/04-travelling-salesman-in-outline.md)
5. [De Bruijn sequences: an Euler circuit that packs every possible code into one shortest string](11-Tours%20-%20Euler%20and%20Hamilton/05-de-bruijn-sequences.md)

[↑ Back to the shelves](#top)

<a name="s12"></a>

## 12 · Planarity and Colouring · 6 cards

*Planar graphs and Euler's formula, the edge bound and Kuratowski's two forbidden graphs, vertex colouring and the chromatic number, the chromatic polynomial, the five- and four-colour theorems, and edge colouring with round-robin fixtures.*

1. [Planar graphs: drawn flat with no crossings, and vertices minus edges plus faces is always 2](12-Planarity%20and%20Colouring/01-planar-graphs-and-eulers-formula.md)
2. [Why some graphs cannot be drawn flat: at most 3V - 6 edges, so K(5) and the three-utilities graph fail, and Kuratowski says those two are the only obstacles](12-Planarity%20and%20Colouring/02-edge-bound-and-kuratowski.md)
3. [Colouring: give joined vertices different colours, and the fewest colours needed is the size of the timetable](12-Planarity%20and%20Colouring/03-vertex-colouring-and-chromatic-number.md)
4. [The chromatic polynomial: count the colourings with q colours, by deleting an edge and contracting it](12-Planarity%20and%20Colouring/04-chromatic-polynomial.md)
5. [Colouring maps: five colours always suffice by a short argument, four by a famous long one](12-Planarity%20and%20Colouring/05-five-and-four-colour-theorems.md)
6. [Edge colouring: colour the edges so no two at a vertex match, and a league fixture list is exactly this](12-Planarity%20and%20Colouring/06-edge-colouring-and-round-robin.md)

[↑ Back to the shelves](#top)

<a name="s13"></a>

## 13 · Matchings and Flows · 7 cards

*Matchings and augmenting paths, Hall's theorem, Konig's theorem and vertex covers, stable matching by Gale-Shapley, flow networks with Ford-Fulkerson, the max-flow min-cut theorem, and connectivity with Menger's theorem.*

1. [Matchings: pair up vertices with no one used twice, and a matching is largest exactly when no alternating route can improve it](13-Matchings%20and%20Flows/01-matchings-and-augmenting-paths.md)
2. [Hall's theorem: everyone on the left can be matched exactly when no group of them shares too few options](13-Matchings%20and%20Flows/02-halls-marriage-theorem.md)
3. [Konig's theorem: in a two-sided graph the largest matching equals the smallest set of vertices touching every edge](13-Matchings%20and%20Flows/03-konigs-theorem-and-vertex-cover.md)
4. [Stable matching: pair two sides by preference so no two would both rather swap, and the proposers get their best stable deal](13-Matchings%20and%20Flows/04-stable-matching-gale-shapley.md)
5. [Flows: pipes with capacities from a source to a sink, and pushing along leftover routes, including undoing an earlier choice](13-Matchings%20and%20Flows/05-flow-networks-and-ford-fulkerson.md)
6. [Max-flow min-cut: the most you can push equals the cheapest way to sever the network, and matching is a flow](13-Matchings%20and%20Flows/06-max-flow-min-cut.md)
7. [How many cuts break a network: bridges, cut vertices, and Menger's theorem that separate routes equal the blocks needed](13-Matchings%20and%20Flows/07-connectivity-and-mengers-theorem.md)

[↑ Back to the shelves](#top)

<a name="s14"></a>

## 14 · Ramsey and Extremal, in Outline · 5 cards

*Friends and strangers, Ramsey numbers and the theorem in outline, Erdos's counting lower bound as the first probabilistic-method argument, Erdos-Szekeres with Dilworth folded, and Mantel and Turan on triangle-free and clique-free graphs.*

1. [Friends and strangers: among any six people, three all know each other or three are all strangers, and five is not enough](14-Ramsey%20and%20Extremal%2C%20in%20Outline/01-friends-and-strangers.md)
2. [Ramsey numbers: the size at which a pattern is forced, known exactly for only a handful of cases](14-Ramsey%20and%20Extremal%2C%20in%20Outline/02-ramsey-numbers.md)
3. [Erdos's counting trick: if the bad colourings are fewer than all colourings, a good one exists, so R(k,k) grows at least like 2^(k/2)](14-Ramsey%20and%20Extremal%2C%20in%20Outline/03-probabilistic-method-by-counting.md)
4. [Erdos-Szekeres: any long enough list of numbers has a long rising run or a long falling run, by labelling and pigeonhole](14-Ramsey%20and%20Extremal%2C%20in%20Outline/04-erdos-szekeres.md)
5. [Mantel and Turan: more than n^2/4 edges force a triangle, and the balanced multipartite graph is the most you can have without a clique](14-Ramsey%20and%20Extremal%2C%20in%20Outline/05-mantel-and-turan.md)

[↑ Back to the shelves](#top)

---

[← 03 · Algebra](../03-Algebra/README.md) · [All wings](../../SYLLABUS.md) · [05 · Geometry and trig →](../05-Geometry%20and%20trig/README.md)
