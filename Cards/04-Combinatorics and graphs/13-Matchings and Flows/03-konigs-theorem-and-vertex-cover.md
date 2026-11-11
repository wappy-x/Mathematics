# Konig's theorem: in a two-sided graph the largest matching equals the smallest set of vertices touching every edge

[Syllabus](../../../SYLLABUS.md) → [Combinatorics and graphs](../README.md) → [Matchings and Flows](../README.md#s13) → Konig's theorem

---

## General Overview

A town sits on both banks of a river: four junctions on the west bank, W1 to W4, and four on the east, E1 to E4. Eight streets join them, each a bridge from west to east.

Guards at junctions must watch every street from at least one end. How few will do?

Three, at W4, E1 and E2: every street meets one of them. Two never do. The streets W1-E2, W2-E1 and W4-E3 share no junction, so each needs its own guard.

The two arguments meet at three. A set of streets no two of which share a junction is a **matching**. A set of junctions meeting every street is a **vertex cover**, or **cover** for short.

Dénes Kőnig proved in 1931 that they always meet in a **bipartite** graph: one whose dots split into two sides with every line crossing between them, as the river forces here ([Bipartite graphs](../09-Graphs%20-%20Dots%20and%20Lines/05-bipartite-graphs-and-odd-cycles.md)).

**In a bipartite graph the largest matching and the smallest vertex cover have the same size, so a matching is a receipt proving no cover can be cheaper.**

**What kind of fact this is:** a theorem, proved on this card in Why it works; matching, cover, independent set and edge cover are definitions.

### The picture: eight junctions, eight streets

```mermaid
flowchart LR
    W1["W1"] --- E1["E1"]
    W1 --- E2["E2"]
    W2["W2"] --- E1
    W2 --- E2
    W3["W3"] --- E2
    W4["W4"] --- E2
    W4 --- E3["E3"]
    W4 --- E4["E4"]
```

West bank left, east bank right. W1, W2 and W3 crowd onto E1 and E2, which holds the matching to three streets.

---

## The formula

A graph $G$ is a set of dots and a set of joined pairs ([Graphs](../09-Graphs%20-%20Dots%20and%20Lines/01-graphs-vertices-and-edges.md)): here junctions and streets. $n$ counts the junctions: 8. Four counts matter:

- $\nu$ ("nu"), the **matching number**: the most streets with no two sharing a junction.
- $\tau$ ("tau"), the **cover number**: the fewest junctions meeting every street.
- $\alpha$ ("alpha"), the **independence number**: the most junctions with no street between any two. Such a set is an **independent set**.
- $\rho$ ("rho"), the **edge-cover number**: the fewest streets reaching every junction. Such a set is an **edge cover**.

In every graph, two-sided or not:

$$\nu(G) \le \tau(G)$$

**Read it aloud:** the fewest guards is never less than the most streets sharing no junction.

Kőnig closes the gap on two sides:

$$\nu(G) = \tau(G) \qquad \text{when } G \text{ is bipartite}$$

**Read it aloud:** on a two-sided plan, the largest matching and the smallest cover are the same size.

Tibor Gallai's identities pair the counts:

$$\alpha(G) + \tau(G) = n, \qquad \nu(G) + \rho(G) = n$$

**Read it aloud:** the junctions a smallest cover leaves out form a largest independent set; and a largest matching and a smallest edge cover sum to the number of junctions.

Here $5 + 3 = 8$ and $3 + 5 = 8$. With Kőnig's $\nu = \tau$, they force $\alpha = \rho$: both 5.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $G$ | the plan as a graph | 8 junctions, 8 streets | — |
| $n$ | how many junctions | 8 | $\alpha + \tau$ and $\nu + \rho$ rise with it |
| $\nu$ | matching number | 3 | on two sides, so does $\tau$ |
| $\tau$ | cover number | 3 | $\alpha$ falls by as much |
| $\alpha$ | independence number | 5 | $\tau$ falls by as much |
| $\rho$ | edge-cover number | 5 | $\nu$ falls by as much |
| $S$, $N(S)$ | a set of west junctions; the east junctions its streets reach; bars count members | W1, W2, W3; E1, E2 | a bigger shortfall, a smaller matching |
| $M$, $Z$ | a largest matching; all its alternating walks reach (Step 2) | 3 streets; W1, W2, W3, E1, E2 | — |

### When it holds

- **Two sides, every street crossing.** A ring of three junctions has matching 1 but needs 2 guards; every odd ring fails so. Some other graphs reach equality by luck.
- **Guards counted, not priced.** If guards cost different amounts, the cheapest bill is Jenő Egerváry's weighted version, also 1931.
- **No junction without a street.** No edge cover reaches a junction with no street, so $\nu + \rho = n$ fails there. $\alpha + \tau = n$ survives.
- **Finitely many junctions.** The walk in Step 2 must stop; infinite plans need other arguments.

---

## Why it works

### Step 0: each matched street needs a guard of its own

Take any matching and any cover, in any graph. The cover meets every matched street, and no guard serves two of them, since they share no junction. So the cover has at least as many junctions as the matching has streets: $\nu \le \tau$. No sides were used; the reverse direction needs them.

### Step 1: the junctions a cover leaves out are independent

A street between two left-out junctions would have neither end guarded, so there is none: the leftovers are independent. Backwards too: if the leftovers have no street inside, every street has an end in the chosen set, so it is a cover. A smaller cover means a larger independent set, and $\alpha + \tau = n$: here $5 + 3 = 8$.

### Step 2: from a largest matching to a cover of the same size

Take a largest matching $M$: W1-E2, W2-E1, W4-E3, with W3 unmatched. From each unmatched west junction, walk **alternating**: out along a street not in $M$, back along one in $M$. From W3: to E2, back to its partner W1, out to E1, back to W2, then stop, since E2 is already reached. Call everything reached $Z$: W1, W2, W3, E1, E2.

Guard the west junctions the walk missed and the east junctions it reached:

$$\text{guards} \;=\; (\text{west}\setminus Z)\;\cup\;(\text{east}\cap Z)$$

That is W4, E1 and E2, the opening's guards. A street they missed would let the walk go one step further, so they meet every street. They hold one end of each street of $M$, so there are $\nu$ of them. So $\tau \le \nu$, and with Step 0, $\nu = \tau$.

<details>
<summary>Detailed proof: the guards meet every street, and there are exactly ν of them</summary>

**Every street is met.** A missed street has its west end in $Z$ and its east end outside. If it is in $M$, the walk reached its west end by stepping back along it, from its east end, which is then in $Z$. If not, the walk can step out along it, putting the east end in $Z$. Either way, a contradiction.

**Every guard is matched.** Unmatched west junctions are starting points, so they lie in $Z$ and get no guard. An unmatched east junction in $Z$ would end an alternating walk; swapping used and unused streets along it would give a bigger matching ([Matchings](01-matchings-and-augmenting-paths.md)), contradicting $M$ being largest.

**No street of $M$ is guarded at both ends.** That needs its east end in $Z$ and its west end outside, but the walk always steps from a matched east junction back to its partner. So the guards are one end of each street of $M$: exactly $\nu$.

</details>

### Step 3: the same guards, from Hall's shortfall

A second road starts from the obstruction. For a set $S$ of west junctions, $\lvert S\rvert - \lvert N(S)\rvert$ is its **shortfall** (Hall's defect). The worst shortfall is exactly how many west junctions go unmatched ([Hall's theorem](02-halls-marriage-theorem.md)). Here the worst set is W1, W2, W3, reaching only E1 and E2: shortfall 1, so $\nu = 4 - 1 = 3$ for the 4 west junctions.

Guard $N(S)$ and every west junction outside $S$:

$$\text{guards} \;=\; N(S)\;\cup\;(\text{west}\setminus S)$$

A street from inside $S$ lands in $N(S)$; every other street starts outside $S$. So this is a cover, with 4 minus the shortfall junctions: E1, E2 and W4 again, and no matching grown.

### Step 4: the streets that reach every junction

A largest matching reaches $2\nu$ junctions with $\nu$ streets: 6 with 3. Give each of the other $n - 2\nu$ junctions one of its streets: $n - \nu$ streets reach everything, so $\rho \le n - \nu$. Here $3 + 2 = 5$.

<details>
<summary>Detailed proof: why an edge cover cannot beat n − ν</summary>

In a smallest edge cover, every street has an end no other street of the cover reaches, or it could be dropped. So each piece of the cover is a **star**: a centre with streets out to ends touching nothing else. A star has one street fewer than junctions, so $\rho$ streets over $n$ junctions make $n - \rho$ stars. One street per star is a matching: $\nu \ge n - \rho$. With Step 4's bound $\rho \le n - \nu$, this gives $\nu + \rho = n$.

</details>

```mermaid
flowchart LR
    M["largest matching, 3 streets"] -->|"Konig: two banks only"| C["fewest guards, 3 junctions"]
    C -->|"take the leftovers"| I["largest independent set, 5 junctions"]
    M -->|"one street per junction left over"| R["smallest edge cover, 5 streets"]
    I -->|"5 + 3"| N["8 junctions"]
    R -->|"3 + 5"| N
```

A third road treats the plan as a network carrying one unit per street, where the smallest cover is the cheapest cut ([Max-flow min-cut](06-max-flow-min-cut.md)).

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| the plan | 4 west + 4 east | n = 8 |
| a matching, so every cover has at least 3 | W1-E2, W2-E1, W4-E3 | matching 3 |
| a cover of that size | W4, E1, E2 | **3** |
| Hall's worst west set | W1, W2, W3 reach only E1, E2 | shortfall 1 |
| the matching, from the shortfall | 4 − 1 | **3** |
| the junctions left over | 8 − 3 | independent set 5 |
| Gallai | 5 + 3 and 3 + 5 | **8** |

Three guards is not merely the best found; the three separate streets prove nothing smaller exists.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Both ends of each matched street guarded | 6 guards | One end per street is enough |
| One whole bank guarded | 4 guards | A cover, not a smallest one |
| Streets reaching every junction counted | 5 streets | That is $\rho$, a different job |
| Kőnig applied to a ring of three | matching 1, guards 2 | Not two-sided |

---

## Code, from first principles, and it actually runs

Nothing is imported. Road one tries all 256 sets of junctions and all 256 sets of streets. Road two grows a matching by alternating walks and reads the guards off it. Road three builds guards from Hall's worst west set. The asserts compare the roads.

### Python

```python
# Konig's theorem -- the check behind the card.  Nothing is imported.  The town plan: eight
# junctions, four on the west bank (W1-W4) and four on the east (E1-E4), joined by eight
# streets, each one a bridge.  A triangle of streets is the second case, where equality fails.
NAMES = ["W1", "W2", "W3", "W4", "E1", "E2", "E3", "E4"]
WESTM, EASTM = 0b1111, 0b11110000                  # the two banks, one bit per junction
ST = [(0, 4), (0, 5), (1, 4), (1, 5), (2, 5), (3, 5), (3, 6), (3, 7)]
TRI = [(0, 1), (1, 2), (0, 2)]                     # three junctions in a ring, so no two banks
show = lambda m: ", ".join(NAMES[i] for i in range(8) if m >> i & 1)
def brute(n, st):                                  # ROAD ONE: every set of junctions, every set of streets
    pc, touch = int.bit_count, lambda p: {x for i, (u, v) in enumerate(st) if p >> i & 1 for x in (u, v)}
    cov = [m for m in range(1 << n) if all(m >> u & 1 or m >> v & 1 for u, v in st)]
    tau = min(map(pc, cov))
    alpha = max(pc(m) for m in range(1 << n) if all(not (m >> u & 1 and m >> v & 1) for u, v in st))
    nu = max(pc(p) for p in range(1 << len(st)) if len(touch(p)) == 2 * pc(p))
    rho = min(pc(p) for p in range(1 << len(st)) if len(touch(p)) == n)
    return nu, tau, alpha, rho, [m for m in cov if pc(m) == tau]
def grow(a, mate, seen, nbr):                      # one alternating walk out of a west junction
    for b in nbr[a]:
        if b in seen: continue
        seen.add(b)
        if b not in mate or grow(mate[b], mate, seen, nbr): mate[b] = a; return True
    return False
def built(st):                                     # ROAD TWO: grow a matching, then read the guards off it
    nbr, mate = {a: [b for u, b in st if u == a] for a in range(4)}, {}   # mate: east -> west partner
    for a in range(4): grow(a, mate, set(), nbr)
    stack = [a for a in range(4) if a not in mate.values()]               # west junctions left unmatched
    z = set(stack)                                                       # all an alternating walk reaches
    while stack:
        for b in nbr[stack.pop()]:
            if b in z: continue
            z.add(b)
            if b in mate and mate[b] not in z: z.add(mate[b]); stack.append(mate[b])
    cover = sum(1 << x for x in range(8) if (x not in z if x < 4 else x in z))
    return sorted((a, b) for b, a in mate.items()), cover
def hall(st):                                      # ROAD THREE: the west set Hall's test fails worst on
    nbrs = lambda m: {b for u, b in st if m >> u & 1}
    bad = max(range(16), key=lambda m: int.bit_count(m) - len(nbrs(m)))
    gap, side = int.bit_count(bad) - len(nbrs(bad)), sum(1 << b for b in nbrs(bad))
    return gap, bad, side, side + sum(1 << a for a in range(4) if not bad >> a & 1)
(nu, tau, alpha, rho, mins), (pairs, cover), (gap, bad, side, hcover) = brute(8, ST), built(ST), hall(ST)
t_nu, t_tau = brute(3, TRI)[:2]
print(f"plan: {len(NAMES)} junctions, west {show(WESTM)} and east {show(EASTM)}; {len(ST)} streets, each a bridge")
print(f"road one, all {1 << 8} sets of junctions: fewest guards tau = {tau}, largest independent set alpha = {alpha}")
print(f"road one, all {1 << len(ST)} sets of streets: largest matching nu = {nu}, smallest edge cover rho = {rho}")
print(f"road one, guard sets of size {tau}: {len(mins)}, namely {show(mins[0])}")
print("road two, matching grown by alternating walks: " + "; ".join(f"{NAMES[a]}-{NAMES[b]}" for a, b in pairs))
print(f"road two, guards read off that matching: {show(cover)}")
print(f"road three, worst west set for Hall's test: {show(bad)} reaching only {show(side)}; shortfall {gap}; guards from it: {show(hcover)}")
print(f"Konig: largest matching {nu} = fewest guards {tau}")
print(f"Gallai: alpha + tau = {alpha} + {tau} = {alpha + tau}, and nu + rho = {nu} + {rho} = {nu + rho}")
print(f"mistakes: both ends of each matched street {2 * nu} guards; one whole bank {int.bit_count(WESTM)} guards; an edge cover {rho} streets, not {tau}")
print(f"a triangle of streets: nu = {t_nu} but tau = {t_tau}, so Konig needs two banks")
assert nu == tau == len(pairs) == 3                  # Konig: brute force meets the alternating walk
assert cover == mins[0] and len(mins) == 1           # the built guard set is the only smallest one
assert hcover == cover and nu == 4 - gap             # Hall's shortfall names the same guards
assert alpha + tau == 8 and nu + rho == 8 and (t_nu, t_tau) == (1, 2)
print("ALL CHECKS PASS")
```

**Ran 2026-09-23 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
plan: 8 junctions, west W1, W2, W3, W4 and east E1, E2, E3, E4; 8 streets, each a bridge
road one, all 256 sets of junctions: fewest guards tau = 3, largest independent set alpha = 5
road one, all 256 sets of streets: largest matching nu = 3, smallest edge cover rho = 5
road one, guard sets of size 3: 1, namely W4, E1, E2
road two, matching grown by alternating walks: W1-E2; W2-E1; W4-E3
road two, guards read off that matching: W4, E1, E2
road three, worst west set for Hall's test: W1, W2, W3 reaching only E1, E2; shortfall 1; guards from it: W4, E1, E2
Konig: largest matching 3 = fewest guards 3
Gallai: alpha + tau = 5 + 3 = 8, and nu + rho = 3 + 5 = 8
mistakes: both ends of each matched street 6 guards; one whole bank 4 guards; an edge cover 5 streets, not 3
a triangle of streets: nu = 1 but tau = 2, so Konig needs two banks
ALL CHECKS PASS
```

### Rust

Built with `rustc --edition 2021 -O`.

```rust
// Konig's theorem -- the same check as the Python, in Rust.  No crates.  The town plan: eight
// junctions, four on the west bank (W1-W4) and four on the east (E1-E4), joined by eight
// streets, each one a bridge.  A triangle of streets is the second case, where equality fails.
const NAMES: [&str; 8] = ["W1", "W2", "W3", "W4", "E1", "E2", "E3", "E4"];
const WESTM: u32 = 0b1111; const EASTM: u32 = 0b11110000;    // banks, one bit per junction
const ST: [(usize, usize); 8] = [(0, 4), (0, 5), (1, 4), (1, 5), (2, 5), (3, 5), (3, 6), (3, 7)];
const TRI: [(usize, usize); 3] = [(0, 1), (1, 2), (0, 2)];   // three junctions in a ring
fn show(m: u32) -> String { (0..8).filter(|i| m >> i & 1 == 1).map(|i| NAMES[i]).collect::<Vec<&str>>().join(", ") }
fn brute(n: usize, st: &[(usize, usize)]) -> (u32, u32, u32, u32, Vec<u32>) {
    let (mut nu, mut tau, mut alpha, mut rho) = (0u32, n as u32, 0u32, st.len() as u32 + 1);
    let mut mins: Vec<u32> = Vec::new();
    for m in 0..1u32 << n {                        // ROAD ONE, part one: every set of junctions
        let (k, cov) = (m.count_ones(), st.iter().all(|&(u, v)| m >> u & 1 == 1 || m >> v & 1 == 1));
        if cov && k < tau { tau = k; mins.clear() } if cov && k == tau { mins.push(m) }
        if st.iter().all(|&(u, v)| m >> u & 1 == 0 || m >> v & 1 == 0) && k > alpha { alpha = k }
    }
    for p in 0..1u32 << st.len() {                 // ROAD ONE, part two: every set of streets
        let (k, mut touch) = (p.count_ones(), 0u32);
        for (i, &(u, v)) in st.iter().enumerate() { if p >> i & 1 == 1 { touch |= 1 << u | 1 << v } }
        if touch.count_ones() == 2 * k && k > nu { nu = k } if touch.count_ones() == n as u32 && k < rho { rho = k }
    }
    (nu, tau, alpha, rho, mins)
}
fn grow(a: usize, mate: &mut [i32; 8], seen: &mut Vec<usize>, nbr: &[Vec<usize>]) -> bool {
    for &b in &nbr[a] {                            // one alternating walk out of a west junction
        if seen.contains(&b) { continue }
        seen.push(b);
        let w = mate[b];
        if w < 0 || grow(w as usize, mate, seen, nbr) { mate[b] = a as i32; return true }
    }
    false
}
fn built(st: &[(usize, usize)]) -> (Vec<(usize, usize)>, u32) {   // ROAD TWO: a matching, then guards
    let nbr: Vec<Vec<usize>> = (0..4).map(|a| st.iter().filter(|&&(u, _)| u == a).map(|&(_, b)| b).collect()).collect();
    let mut mate = [-1i32; 8];                     // mate: east junction -> west partner
    for a in 0..4 { grow(a, &mut mate, &mut Vec::new(), &nbr); }
    let mut pairs: Vec<(usize, usize)> = (4..8).filter(|&b| mate[b] >= 0).map(|b| (mate[b] as usize, b)).collect();
    pairs.sort();
    let mut stack: Vec<usize> = (0..4).filter(|&a| !pairs.iter().any(|&(w, _)| w == a)).collect();
    let mut z = stack.clone();                     // all an alternating walk reaches
    while let Some(a) = stack.pop() {
        for &b in &nbr[a] {
            if z.contains(&b) { continue }
            z.push(b);
            let w = mate[b] as usize;
            if mate[b] >= 0 && !z.contains(&w) { z.push(w); stack.push(w) }
        }
    }
    (pairs, (0..8).filter(|&x| if x < 4 { !z.contains(&x) } else { z.contains(&x) }).fold(0u32, |c, x| c | 1 << x))
}
fn hall(st: &[(usize, usize)]) -> (i32, u32, u32, u32) {   // ROAD THREE: Hall's worst set of west junctions
    let nbrs = |m: u32| st.iter().filter(|&&(u, _)| m >> u & 1 == 1).fold(0u32, |c, &(_, b)| c | 1 << b);
    let def = |m: u32| m.count_ones() as i32 - nbrs(m).count_ones() as i32;
    let mut bad = 0u32;                            // the west set with the biggest shortfall
    for m in 1..16u32 { if def(m) > def(bad) { bad = m } }
    (def(bad), bad, nbrs(bad), nbrs(bad) | (0..4).filter(|a| bad >> a & 1 == 0).fold(0, |c, a| c | 1 << a))
}
fn main() {
    let (nu, tau, alpha, rho, mins) = brute(8, &ST);
    let (pairs, cover) = built(&ST);
    let (gap, bad, side, hcover) = hall(&ST);
    let (t_nu, t_tau, ..) = brute(3, &TRI);
    let matched = pairs.iter().map(|&(a, b)| format!("{}-{}", NAMES[a], NAMES[b])).collect::<Vec<String>>().join("; ");
    println!("plan: {} junctions, west {} and east {}; {} streets, each a bridge", NAMES.len(), show(WESTM), show(EASTM), ST.len());
    println!("road one, all {} sets of junctions: fewest guards tau = {}, largest independent set alpha = {}", 1 << 8, tau, alpha);
    println!("road one, all {} sets of streets: largest matching nu = {}, smallest edge cover rho = {}", 1 << ST.len(), nu, rho);
    println!("road one, guard sets of size {}: {}, namely {}", tau, mins.len(), show(mins[0]));
    println!("road two, matching grown by alternating walks: {}", matched);
    println!("road two, guards read off that matching: {}", show(cover));
    println!("road three, worst west set for Hall's test: {} reaching only {}; shortfall {}; guards from it: {}", show(bad), show(side), gap, show(hcover));
    println!("Konig: largest matching {} = fewest guards {}", nu, tau);
    println!("Gallai: alpha + tau = {} + {} = {}, and nu + rho = {} + {} = {}", alpha, tau, alpha + tau, nu, rho, nu + rho);
    println!("mistakes: both ends of each matched street {} guards; one whole bank {} guards; an edge cover {} streets, not {}", 2 * nu, WESTM.count_ones(), rho, tau);
    println!("a triangle of streets: nu = {} but tau = {}, so Konig needs two banks", t_nu, t_tau);
    assert!(nu == tau && nu as usize == pairs.len() && nu == 3);   // Konig: brute force meets the walk
    assert!(cover == mins[0] && mins.len() == 1);        // the built guard set is the only smallest one
    assert!(hcover == cover && nu as i32 == 4 - gap);    // Hall's shortfall names the same guards
    assert!(alpha + tau == 8 && nu + rho == 8 && (t_nu, t_tau) == (1, 2));
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-23 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
plan: 8 junctions, west W1, W2, W3, W4 and east E1, E2, E3, E4; 8 streets, each a bridge
road one, all 256 sets of junctions: fewest guards tau = 3, largest independent set alpha = 5
road one, all 256 sets of streets: largest matching nu = 3, smallest edge cover rho = 5
road one, guard sets of size 3: 1, namely W4, E1, E2
road two, matching grown by alternating walks: W1-E2; W2-E1; W4-E3
road two, guards read off that matching: W4, E1, E2
road three, worst west set for Hall's test: W1, W2, W3 reaching only E1, E2; shortfall 1; guards from it: W4, E1, E2
Konig: largest matching 3 = fewest guards 3
Gallai: alpha + tau = 5 + 3 = 8, and nu + rho = 3 + 5 = 8
mistakes: both ends of each matched street 6 guards; one whole bank 4 guards; an edge cover 5 streets, not 3
a triangle of streets: nu = 1 but tau = 2, so Konig needs two banks
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves Kőnig's theorem and Gallai's identities for every graph with finitely many junctions, and checks the town plan's counts exactly.

- Kőnig's theorem: in every bipartite graph, the largest matching and the smallest cover have the same size.
- Step 0, in every graph: no matching has more streets than any cover has junctions.
- Gallai: the independence number plus the cover number is the number of junctions, in every graph.
- Gallai again: when every junction has a street, the matching number plus the edge-cover number is the number of junctions.
- The town plan: a matching of 3 streets, and none of 4.
- The town plan: guards at W4, E1 and E2 meet every street, no 2 guards do, and no other 3 do.
- The town plan: Hall's worst shortfall is 1, the largest independent set is 5, and the smallest edge cover is 5.
- The ring of three: any two streets share a junction, yet every cover needs 2 guards.

Growing the matching by alternating walks, and the edits in the Try changing box, are left to the Python and Rust checks.

<details>
<summary>The Lean proof, 516 lines</summary>

```lean
-- Konig's theorem: in every finite bipartite graph the largest matching has as many lines as the smallest set of dots touching every line.
import Mathlib.Combinatorics.SimpleGraph.Matching
import Mathlib.Combinatorics.SimpleGraph.Bipartite
import Mathlib.Combinatorics.SimpleGraph.Clique
import Mathlib.Data.Fin.VecNotation
import Mathlib.Combinatorics.Hall.Basic
import Mathlib.Combinatorics.Enumerative.DoubleCounting

open SimpleGraph

/-! A matching is a `Subgraph` of `G` in which every dot it uses has exactly one partner
(Mathlib's `Subgraph.IsMatching`); its size is the number of its lines, `M.edgeSet.ncard`.
"Bipartite" is Mathlib's `G.IsBipartite`: the dots can be split into two sides with every line
crossing between them. -/

/-- A vertex cover (a "cover"): a set `C` of dots meeting every line of `G`. -/
def IsVertexCover {V : Type*} (G : SimpleGraph V) (C : Finset V) : Prop :=
  ∀ ⦃u v : V⦄, G.Adj u v → u ∈ C ∨ v ∈ C

/-- An edge cover: a set `F` of lines of `G` reaching every dot. -/
def IsEdgeCover {V : Type*} (G : SimpleGraph V) (F : Finset (Sym2 V)) : Prop :=
  (∀ e ∈ F, e ∈ G.edgeSet) ∧ ∀ v : V, ∃ e ∈ F, v ∈ e

/-- The matching number ν: the most lines in a matching. -/
noncomputable def matchingNumber {V : Type*} (G : SimpleGraph V) : ℕ :=
  sSup {k | ∃ M : G.Subgraph, M.IsMatching ∧ M.edgeSet.ncard = k}

/-- The cover number τ: the fewest dots in a vertex cover. -/
noncomputable def coverNumber {V : Type*} (G : SimpleGraph V) : ℕ :=
  sInf {k | ∃ C : Finset V, IsVertexCover G C ∧ C.card = k}

/-- The edge-cover number ρ: the fewest lines in an edge cover. -/
noncomputable def edgeCoverNumber {V : Type*} (G : SimpleGraph V) : ℕ :=
  sInf {k | ∃ F : Finset (Sym2 V), IsEdgeCover G F ∧ F.card = k}

/-! Helper lemmas. A matching is handled as a finite set of lines, no two sharing a dot. -/

/-- A finite set of lines of `G`, no two of which share a dot. -/
def FinMatching {V : Type*} (G : SimpleGraph V) (F : Finset (Sym2 V)) : Prop :=
  (∀ e ∈ F, e ∈ G.edgeSet) ∧ ∀ e ∈ F, ∀ f ∈ F, ∀ v : V, v ∈ e → v ∈ f → e = f

/-- The lines of a matching subgraph form a `FinMatching`. -/
theorem finMatching_of_isMatching {V : Type*} [Fintype V] {G : SimpleGraph V} {M : G.Subgraph}
    (hM : M.IsMatching) : FinMatching G M.edgeSet.toFinite.toFinset := by
  constructor
  · intro e he
    rw [Set.Finite.mem_toFinset] at he
    exact M.edgeSet_subset he
  · intro e he f hf v hve hvf
    rw [Set.Finite.mem_toFinset] at he hf
    induction e using Sym2.ind with
    | _ a b =>
    induction f using Sym2.ind with
    | _ c d =>
    rw [Subgraph.mem_edgeSet] at he hf
    rcases Sym2.mem_iff.mp hve with h1 | h1 <;> rcases Sym2.mem_iff.mp hvf with h2 | h2 <;>
      subst h1 <;> subst h2
    · rw [hM.eq_of_adj_left he hf]
    · rw [hM.eq_of_adj_left he hf.symm, Sym2.eq_swap]
    · rw [hM.eq_of_adj_left he.symm hf, Sym2.eq_swap]
    · rw [hM.eq_of_adj_left he.symm hf.symm]

/-- Every `FinMatching` is the set of lines of a matching subgraph. -/
theorem exists_isMatching_of_finMatching {V : Type*} {G : SimpleGraph V} {F : Finset (Sym2 V)}
    (hF : FinMatching G F) : ∃ M : G.Subgraph, M.IsMatching ∧ M.edgeSet = ↑F := by
  refine ⟨{ verts := {v | ∃ e ∈ F, v ∈ e}
            Adj := fun u v => s(u, v) ∈ F
            adj_sub := fun h => (G.mem_edgeSet).mp (hF.1 _ h)
            edge_vert := fun h => ⟨_, h, Sym2.mem_mk_left _ _⟩
            symm := ⟨fun u v h => by rw [Sym2.eq_swap]; exact h⟩ }, ?_, ?_⟩
  · intro v hv
    obtain ⟨e, he, hve⟩ := hv
    obtain ⟨w, rfl⟩ := Sym2.mem_iff_exists.mp hve
    refine ⟨w, he, fun w' hw' => ?_⟩
    have := hF.2 _ hw' _ he v (Sym2.mem_mk_left _ _) (Sym2.mem_mk_left _ _)
    exact Sym2.congr_right.mp this
  · ext e
    induction e using Sym2.ind with
    | _ a b => rw [Subgraph.mem_edgeSet, Finset.mem_coe]

/-- A `FinMatching` touches exactly twice as many dots as it has lines. -/
theorem card_covered_finMatching {V : Type*} [Fintype V] [DecidableEq V] {G : SimpleGraph V}
    {F : Finset (Sym2 V)} (hF : FinMatching G F) :
    (Finset.univ.filter (fun v => ∃ e ∈ F, v ∈ e)).card = 2 * F.card := by
  have h1 : Finset.univ.filter (fun v => ∃ e ∈ F, v ∈ e) =
      F.biUnion (fun e => Finset.univ.filter (· ∈ e)) := by
    ext v; simp
  rw [h1, Finset.card_biUnion]
  · rw [Finset.sum_const_nat (m := 2), mul_comm]
    intro e he
    have hd := hF.1 e he
    induction e using Sym2.ind with
    | _ a b =>
      have hab : a ≠ b := G.ne_of_adj hd
      have : Finset.univ.filter (· ∈ s(a, b)) = {a, b} := by ext; simp
      rw [this, Finset.card_pair hab]
  · intro e he f hf hne
    rw [Function.onFun, Finset.disjoint_left]
    intro v hv hv'
    simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hv hv'
    exact hne (hF.2 e he f hf v hv hv')

/-- A `FinMatching` has no more lines than any vertex cover has dots. -/
theorem finMatching_card_le_cover {V : Type*} {G : SimpleGraph V} {F : Finset (Sym2 V)}
    (hF : FinMatching G F) {C : Finset V} (hC : IsVertexCover G C) : F.card ≤ C.card := by
  refine Finset.card_le_card_of_forall_subsingleton (fun e v => v ∈ e) ?_ ?_
  · intro e he
    have hd := hF.1 e he
    induction e using Sym2.ind with
    | _ a b =>
      rcases hC hd with h | h
      · exact ⟨a, h, Sym2.mem_mk_left _ _⟩
      · exact ⟨b, h, Sym2.mem_mk_right _ _⟩
  · rintro v - e ⟨he, hve⟩ f ⟨hf, hvf⟩
    exact hF.2 e he f hf v hve hvf

/-- Matching sizes, read through `FinMatching`. -/
theorem mem_matchingSet_iff {V : Type*} [Fintype V] (G : SimpleGraph V) (k : ℕ) :
    k ∈ {k | ∃ M : G.Subgraph, M.IsMatching ∧ M.edgeSet.ncard = k} ↔
      ∃ F : Finset (Sym2 V), FinMatching G F ∧ F.card = k := by
  constructor
  · rintro ⟨M, hM, rfl⟩
    exact ⟨_, finMatching_of_isMatching hM, (Set.ncard_eq_toFinset_card M.edgeSet).symm⟩
  · rintro ⟨F, hF, rfl⟩
    obtain ⟨M, hM, hE⟩ := exists_isMatching_of_finMatching hF
    exact ⟨M, hM, by rw [hE, Set.ncard_coe_finset]⟩

/-- The matching number is reached, and bounds every matching. -/
theorem matchingNumber_spec {V : Type*} [Fintype V] (G : SimpleGraph V) :
    (∃ F : Finset (Sym2 V), FinMatching G F ∧ F.card = matchingNumber G) ∧
      ∀ F : Finset (Sym2 V), FinMatching G F → F.card ≤ matchingNumber G := by
  have hbdd : BddAbove {k | ∃ M : G.Subgraph, M.IsMatching ∧ M.edgeSet.ncard = k} := by
    refine ⟨Fintype.card V, fun k hk => ?_⟩
    obtain ⟨F, hF, rfl⟩ := (mem_matchingSet_iff G k).mp hk
    have := finMatching_card_le_cover hF (C := Finset.univ) (fun u _ _ => Or.inl (Finset.mem_univ u))
    simpa using this
  have hne : {k | ∃ M : G.Subgraph, M.IsMatching ∧ M.edgeSet.ncard = k}.Nonempty := by
    refine ⟨0, (mem_matchingSet_iff G 0).mpr ⟨∅, ⟨by simp, by simp⟩, rfl⟩⟩
  refine ⟨(mem_matchingSet_iff G _).mp (Nat.sSup_mem hne hbdd), fun F hF => ?_⟩
  exact le_csSup hbdd ((mem_matchingSet_iff G _).mpr ⟨F, hF, rfl⟩)

/-- The cover number is reached, and is at most the size of every vertex cover. -/
theorem coverNumber_spec {V : Type*} [Fintype V] (G : SimpleGraph V) :
    (∃ C : Finset V, IsVertexCover G C ∧ C.card = coverNumber G) ∧
      ∀ C : Finset V, IsVertexCover G C → coverNumber G ≤ C.card := by
  refine ⟨Nat.sInf_mem (s := {k | ∃ C : Finset V, IsVertexCover G C ∧ C.card = k}) ⟨_, Finset.univ, fun u _ _ => Or.inl (Finset.mem_univ u), rfl⟩,
    fun C hC => Nat.sInf_le ⟨C, hC, rfl⟩⟩

/-- In a finite bipartite graph some vertex cover is no larger than some matching
(Hall's theorem with a deficiency, by adding `d` extra dots joined to the whole left side). -/
theorem exists_cover_le_finMatching {V : Type*} [Fintype V] (G : SimpleGraph V)
    (hG : G.IsBipartite) :
    ∃ C : Finset V, IsVertexCover G C ∧ ∃ F : Finset (Sym2 V), FinMatching G F ∧ C.card ≤ F.card := by
  classical
  obtain ⟨c⟩ := hG
  set L : Finset V := Finset.univ.filter (fun v => c v = 0) with hLdef
  have hLadj : ∀ u v, G.Adj u v → (u ∈ L ↔ v ∉ L) := by
    intro u v h
    have hv := c.valid h
    simp only [hLdef, Finset.mem_filter, Finset.mem_univ, true_and]
    revert hv
    generalize c u = a
    generalize c v = b
    revert a b
    decide
  set N : Finset V → Finset V := fun S => S.biUnion (fun x => G.neighborFinset x) with hNdef
  obtain ⟨S, hSL, hSmax⟩ := Finset.exists_max_image L.powerset
    (fun S => (S.card : ℤ) - (N S).card) ⟨∅, Finset.empty_mem_powerset _⟩
  rw [Finset.mem_powerset] at hSL
  have hd0 : (0 : ℤ) ≤ S.card - (N S).card := by
    simpa [hNdef] using hSmax ∅ (Finset.empty_mem_powerset _)
  set d : ℕ := S.card - (N S).card with hd
  let t : L → Finset (V ⊕ Fin d) := fun x => (G.neighborFinset x).disjSum Finset.univ
  have hall : ∀ s : Finset L, s.card ≤ (s.biUnion t).card := by
    intro s
    rcases s.eq_empty_or_nonempty with rfl | ⟨x0, hx0⟩
    · simp
    set s' : Finset V := s.map (Function.Embedding.subtype _) with hs'
    have hs'L : s' ⊆ L := by
      intro v hv
      simp only [hs', Finset.mem_map, Function.Embedding.coe_subtype] at hv
      obtain ⟨x, -, rfl⟩ := hv
      exact x.2
    have hsub : (N s').disjSum (Finset.univ : Finset (Fin d)) ⊆ s.biUnion t := by
      intro z hz
      rw [Finset.mem_biUnion]
      rcases z with v | i
      · rw [Finset.inl_mem_disjSum] at hz
        simp only [hNdef, Finset.mem_biUnion] at hz
        obtain ⟨x', hx', hvx⟩ := hz
        simp only [hs', Finset.mem_map, Function.Embedding.coe_subtype] at hx'
        obtain ⟨x, hx, rfl⟩ := hx'
        exact ⟨x, hx, Finset.inl_mem_disjSum.mpr hvx⟩
      · exact ⟨x0, hx0, Finset.inr_mem_disjSum.mpr (Finset.mem_univ i)⟩
    have hmax := hSmax s' (Finset.mem_powerset.mpr hs'L)
    have hcard : s'.card = s.card := Finset.card_map _
    have h1 : s.card ≤ (N s').card + d := by
      omega
    calc s.card ≤ (N s').card + d := h1
      _ = ((N s').disjSum (Finset.univ : Finset (Fin d))).card := by
        rw [Finset.card_disjSum, Finset.card_univ, Fintype.card_fin]
      _ ≤ _ := Finset.card_le_card hsub
  obtain ⟨f, hfinj, hft⟩ := (Finset.all_card_le_biUnion_card_iff_exists_injective t).mp hall
  -- the pairs (x, v) with x on the left matched to a real dot v
  set P : Finset (L × V) := Finset.univ.filter (fun p => f p.1 = Sum.inl p.2) with hPdef
  have hPadj : ∀ p ∈ P, G.Adj p.1 p.2 := by
    intro p hp
    simp only [hPdef, Finset.mem_filter, Finset.mem_univ, true_and] at hp
    have := hft p.1
    rw [hp, Finset.inl_mem_disjSum, mem_neighborFinset] at this
    exact this
  have hPnotL : ∀ p ∈ P, p.2 ∉ L := fun p hp => (hLadj _ _ (hPadj p hp)).mp p.1.2
  set F : Finset (Sym2 V) := P.image (fun p => s(p.1.1, p.2)) with hFdef
  -- |L| ≤ |P| + d
  have hLP : L.card ≤ P.card + d := by
    have h1 : (Finset.univ.image f).card = L.card := by
      rw [Finset.card_image_of_injective _ hfinj, Finset.card_univ, Fintype.card_coe]
    have h2 : Finset.univ.image f ⊆ P.image (fun p => Sum.inl p.2) ∪
        (Finset.univ : Finset (Fin d)).image Sum.inr := by
      intro z hz
      rw [Finset.mem_image] at hz
      obtain ⟨x, -, rfl⟩ := hz
      rw [Finset.mem_union, Finset.mem_image, Finset.mem_image]
      rcases hfx : f x with v | i
      · exact Or.inl ⟨(x, v), by simp [hPdef, hfx], rfl⟩
      · exact Or.inr ⟨i, Finset.mem_univ _, rfl⟩
    calc L.card = (Finset.univ.image f).card := h1.symm
      _ ≤ _ := Finset.card_le_card h2
      _ ≤ (P.image (fun p => (Sum.inl p.2 : V ⊕ Fin d))).card +
          ((Finset.univ : Finset (Fin d)).image Sum.inr).card := Finset.card_union_le _ _
      _ ≤ P.card + d := by
        gcongr
        · exact Finset.card_image_le
        · exact Finset.card_image_le.trans (by simp)
  have hFcard : F.card = P.card := by
    rw [hFdef, Finset.card_image_of_injOn]
    intro p hp q hq hpq
    simp only at hpq
    rcases Sym2.eq_iff.mp hpq with ⟨h1, h2⟩ | ⟨h1, h2⟩
    · exact Prod.ext (Subtype.ext h1) h2
    · exact absurd (h1 ▸ p.1.2) (hPnotL q hq)
  have hFm : FinMatching G F := by
    constructor
    · intro e he
      rw [hFdef, Finset.mem_image] at he
      obtain ⟨p, hp, rfl⟩ := he
      exact hPadj p hp
    · intro e he e' he' u hu hu'
      rw [hFdef, Finset.mem_image] at he he'
      obtain ⟨p, hp, rfl⟩ := he
      obtain ⟨q, hq, rfl⟩ := he'
      have hpf : f p.1 = Sum.inl p.2 := by
        simpa [hPdef] using hp
      have hqf : f q.1 = Sum.inl q.2 := by
        simpa [hPdef] using hq
      rcases Sym2.mem_iff.mp hu with h1 | h1 <;> rcases Sym2.mem_iff.mp hu' with h2 | h2
      · have : p.1 = q.1 := Subtype.ext (h1.symm.trans h2)
        have h3 : p.2 = q.2 := by
          rw [this] at hpf
          exact Sum.inl_injective (hpf.symm.trans hqf)
        rw [this, h3]
      · have : q.2 ∈ L := by rw [← h2, h1]; exact p.1.2
        exact absurd this (hPnotL q hq)
      · have : p.2 ∈ L := by rw [← h1, h2]; exact q.1.2
        exact absurd this (hPnotL p hp)
      · have : p.1 = q.1 := hfinj (by rw [hpf, hqf, ← h1, ← h2])
        have h3 : p.2 = q.2 := h1.symm.trans h2
        rw [this, h3]
  refine ⟨(L \ S) ∪ N S, ?_, F, hFm, ?_⟩
  · intro u v h
    have key : ∀ a b, G.Adj a b → a ∈ L → a ∈ (L \ S) ∪ N S ∨ b ∈ (L \ S) ∪ N S := by
      intro a b hab ha
      by_cases haS : a ∈ S
      · right
        rw [Finset.mem_union]
        right
        simp only [hNdef, Finset.mem_biUnion]
        exact ⟨a, haS, (mem_neighborFinset _ _ _).mpr hab⟩
      · left
        exact Finset.mem_union_left _ (Finset.mem_sdiff.mpr ⟨ha, haS⟩)
    by_cases hu : u ∈ L
    · exact key u v h hu
    · have hv : v ∈ L := by
        by_contra hv
        exact hu ((hLadj u v h).mpr hv)
      exact (key v u h.symm hv).symm
  · have h1 := Finset.card_union_le (L \ S) (N S)
    have h2 := Finset.card_sdiff_add_card_eq_card hSL
    omega

#print axioms finMatching_of_isMatching
#print axioms exists_isMatching_of_finMatching
#print axioms card_covered_finMatching
#print axioms finMatching_card_le_cover
#print axioms mem_matchingSet_iff
#print axioms matchingNumber_spec
#print axioms coverNumber_spec
#print axioms exists_cover_le_finMatching

/-- Konig's theorem: in a finite bipartite graph, the largest matching and the smallest vertex
cover have the same size, ν(G) = τ(G). -/
theorem konig_matching_number_eq_cover_number {V : Type*} [Fintype V] (G : SimpleGraph V)
    (hG : G.IsBipartite) :
    matchingNumber G = coverNumber G := by
  obtain ⟨C, hC, F, hF, hCF⟩ := exists_cover_le_finMatching G hG
  obtain ⟨⟨F', hF', hF'c⟩, hν⟩ := matchingNumber_spec G
  obtain ⟨⟨C', hC', hC'c⟩, hτ⟩ := coverNumber_spec G
  apply le_antisymm
  · rw [← hF'c, ← hC'c]
    exact finMatching_card_le_cover hF' hC'
  · exact (hτ C hC).trans (hCF.trans (hν F hF))

/-- Step 0, in every finite graph, two-sided or not: every vertex cover has at least as many dots
as any matching has lines, since each matched line needs a guard of its own (so ν ≤ τ). -/
theorem matching_card_le_vertex_cover_card {V : Type*} [Fintype V] (G : SimpleGraph V)
    (M : G.Subgraph) (hM : M.IsMatching) (C : Finset V) (hC : IsVertexCover G C) :
    M.edgeSet.ncard ≤ C.card := by
  have h := finMatching_card_le_cover (finMatching_of_isMatching hM) hC
  rwa [← Set.ncard_eq_toFinset_card] at h

/-- Gallai's identities, in every finite graph: the independence number plus the cover number is
the number of dots, α + τ = n; and when no dot is without a line, the matching number plus the
edge-cover number is the number of dots, ν + ρ = n. -/
theorem gallai_identities {V : Type*} [Fintype V] (G : SimpleGraph V) :
    G.indepNum + coverNumber G = Fintype.card V ∧
      ((∀ v : V, ∃ w : V, G.Adj v w) → matchingNumber G + edgeCoverNumber G = Fintype.card V) := by
  classical
  obtain ⟨⟨C0, hC0, hC0c⟩, hτ⟩ := coverNumber_spec G
  obtain ⟨⟨F0, hF0, hF0c⟩, hν⟩ := matchingNumber_spec G
  have hn : ∀ s : Finset V, s.card ≤ Fintype.card V := fun s => Finset.card_le_univ s
  refine ⟨?_, fun hiso => ?_⟩
  · obtain ⟨s, hs⟩ := G.exists_isNIndepSet_indepNum
    have h1 : coverNumber G ≤ sᶜ.card := by
      apply hτ
      intro u v huv
      by_contra hcon
      push Not at hcon
      simp only [Finset.mem_compl, not_not] at hcon
      exact hs.isIndepSet hcon.1 hcon.2 (G.ne_of_adj huv) huv
    have h2 : C0ᶜ.card ≤ G.indepNum := by
      apply SimpleGraph.IsIndepSet.card_le_indepNum
      intro u hu v hv _ huv
      simp only [Finset.coe_compl, Set.mem_compl_iff, Finset.mem_coe] at hu hv
      rcases hC0 huv with h | h
      · exact hu h
      · exact hv h
    rw [Finset.card_compl] at h1 h2
    have := hs.card_eq
    have := hn s
    have := hn C0
    omega
  · set U := Finset.univ.filter (fun v => ∃ e ∈ F0, v ∈ e) with hU
    have hUc : U.card = 2 * F0.card := card_covered_finMatching hF0
    let g : V → Sym2 V := fun v => s(v, (hiso v).choose)
    set E := F0 ∪ Uᶜ.image g with hE
    have hEc : IsEdgeCover G E := by
      constructor
      · intro e he
        rcases Finset.mem_union.mp he with he | he
        · exact hF0.1 e he
        · obtain ⟨v, -, rfl⟩ := Finset.mem_image.mp he
          exact (hiso v).choose_spec
      · intro v
        by_cases hv : v ∈ U
        · obtain ⟨e, he, hve⟩ := (Finset.mem_filter.mp hv).2
          exact ⟨e, Finset.mem_union_left _ he, hve⟩
        · exact ⟨g v, Finset.mem_union_right _ (Finset.mem_image.mpr ⟨v, Finset.mem_compl.mpr hv, rfl⟩),
            Sym2.mem_mk_left _ _⟩
    have hρle : edgeCoverNumber G ≤ E.card := Nat.sInf_le ⟨E, hEc, rfl⟩
    have hEcard : E.card ≤ F0.card + Uᶜ.card :=
      (Finset.card_union_le _ _).trans (Nat.add_le_add_left Finset.card_image_le _)
    rw [Finset.card_compl] at hEcard
    have hUn := hn U
    obtain ⟨Fc, hFc, hFcc⟩ : ∃ Fc : Finset (Sym2 V), IsEdgeCover G Fc ∧ Fc.card = edgeCoverNumber G :=
      Nat.sInf_mem (s := {k | ∃ F : Finset (Sym2 V), IsEdgeCover G F ∧ F.card = k}) ⟨_, E, hEc, rfl⟩
    obtain ⟨M, hMmem, hMmax⟩ := Finset.exists_max_image (Fc.powerset.filter (FinMatching G))
      Finset.card ⟨∅, Finset.mem_filter.mpr ⟨Finset.empty_mem_powerset _, by simp [FinMatching]⟩⟩
    rw [Finset.mem_filter, Finset.mem_powerset] at hMmem
    obtain ⟨hMFc, hM⟩ := hMmem
    set W := (Finset.univ.filter (fun v => ∃ e ∈ M, v ∈ e))ᶜ with hW
    have hWc : W.card = Fintype.card V - 2 * M.card := by
      rw [hW, Finset.card_compl, card_covered_finMatching hM]
    have hWle : W.card ≤ (Fc \ M).card := by
      refine Finset.card_le_card_of_forall_subsingleton (fun w e => w ∈ e) ?_ ?_
      · intro w hw
        obtain ⟨e, he, hwe⟩ := hFc.2 w
        refine ⟨e, Finset.mem_sdiff.mpr ⟨he, fun heM => ?_⟩, hwe⟩
        simp only [hW, Finset.mem_compl, Finset.mem_filter, Finset.mem_univ, true_and] at hw
        exact hw ⟨e, heM, hwe⟩
      · rintro e he w1 ⟨hw1, hw1e⟩ w2 ⟨hw2, hw2e⟩
        by_contra hne
        rw [Finset.mem_sdiff] at he
        have hmem : ∀ u, u ∈ e → u ∉ Finset.univ.filter (fun v => ∃ e ∈ M, v ∈ e) := by
          intro u hu
          rw [(Sym2.mem_and_mem_iff hne).mp ⟨hw1e, hw2e⟩, Sym2.mem_iff] at hu
          rcases hu with rfl | rfl
          · exact Finset.mem_compl.mp hw1
          · exact Finset.mem_compl.mp hw2
        have hins : FinMatching G (insert e M) := by
          constructor
          · intro a ha
            rcases Finset.mem_insert.mp ha with rfl | ha
            · exact hFc.1 a he.1
            · exact hM.1 a ha
          · intro a ha b hb u hua hub
            rcases Finset.mem_insert.mp ha with rfl | ha' <;>
              rcases Finset.mem_insert.mp hb with rfl | hb'
            · rfl
            · exact absurd (Finset.mem_filter.mpr ⟨Finset.mem_univ _, b, hb', hub⟩) (hmem u hua)
            · exact absurd (Finset.mem_filter.mpr ⟨Finset.mem_univ _, a, ha', hua⟩) (hmem u hub)
            · exact hM.2 a ha' b hb' u hua hub
        have := hMmax (insert e M) (Finset.mem_filter.mpr
          ⟨Finset.mem_powerset.mpr (Finset.insert_subset he.1 hMFc), hins⟩)
        rw [Finset.card_insert_of_notMem he.2] at this
        omega
    have hsd := Finset.card_sdiff_add_card_eq_card hMFc
    have hMν := hν M hM
    have h2M : 2 * M.card ≤ Fintype.card V := (card_covered_finMatching hM) ▸ hn _
    omega

/-! The card's town plan. West junctions W1-W4 are `0`-`3` on the left, east junctions E1-E4
are `0`-`3` on the right. A street `(w, e)` is a bridge from west junction `w` to east junction
`e`. A matching is a set of streets with no junction used twice; a cover is a west set `A` and
an east set `B` together meeting every street. -/

/-- The eight streets: W1-E1, W1-E2, W2-E1, W2-E2, W3-E2, W4-E2, W4-E3, W4-E4. -/
def streets : Finset (Fin 4 × Fin 4) :=
  {(0, 0), (0, 1), (1, 0), (1, 1), (2, 1), (3, 1), (3, 2), (3, 3)}

/-- The same eight streets, numbered 0 to 7. -/
def street : Fin 8 → Fin 4 × Fin 4 :=
  ![(0, 0), (0, 1), (1, 0), (1, 1), (2, 1), (3, 1), (3, 2), (3, 3)]

example : ∀ i : Fin 8, street i ∈ streets := by decide

/-- A set of streets is a matching when no west and no east junction appears twice. -/
def IsTownMatching (S : Finset (Fin 4 × Fin 4)) : Prop :=
  S ⊆ streets ∧ (∀ a ∈ S, ∀ b ∈ S, a.1 = b.1 → a = b) ∧ (∀ a ∈ S, ∀ b ∈ S, a.2 = b.2 → a = b)

instance (S : Finset (Fin 4 × Fin 4)) : Decidable (IsTownMatching S) := by
  unfold IsTownMatching; infer_instance

/-- Guards at west set `A` and east set `B` watch every street. -/
def IsTownCover (A B : Finset (Fin 4)) : Prop := ∀ s ∈ streets, s.1 ∈ A ∨ s.2 ∈ B

instance (A B : Finset (Fin 4)) : Decidable (IsTownCover A B) := by
  unfold IsTownCover; infer_instance

/-- No street joins two junctions of west set `A` and east set `B`. -/
def IsTownIndep (A B : Finset (Fin 4)) : Prop := ∀ s ∈ streets, ¬ (s.1 ∈ A ∧ s.2 ∈ B)

instance (A B : Finset (Fin 4)) : Decidable (IsTownIndep A B) := by
  unfold IsTownIndep; infer_instance

/-- A set of streets reaches every junction on both banks. -/
def IsTownEdgeCover (F : Finset (Fin 4 × Fin 4)) : Prop :=
  F ⊆ streets ∧ (∀ w : Fin 4, ∃ s ∈ F, s.1 = w) ∧ (∀ e : Fin 4, ∃ s ∈ F, s.2 = e)

instance (F : Finset (Fin 4 × Fin 4)) : Decidable (IsTownEdgeCover F) := by
  unfold IsTownEdgeCover; infer_instance

/-- The east junctions reached by the streets out of west set `S`, Hall's `N(S)`. -/
def reach (S : Finset (Fin 4)) : Finset (Fin 4) := (streets.filter (·.1 ∈ S)).image (·.2)

-- 8 junctions, 8 streets.
example : 4 + 4 = 8 ∧ streets.card = 8 := by decide
-- The matching W1-E2, W2-E1, W4-E3 has 3 streets, and no matching has 4 or more.
example : IsTownMatching {(0, 1), (1, 0), (3, 2)} ∧ ({(0, 1), (1, 0), (3, 2)} : Finset _).card = 3 := by
  decide
-- A matching of 4 streets would give the 4 west junctions 4 different east partners along streets:
-- impossible, since W1, W2, W3 reach only E1 and E2.
example : ∀ a b c d : Fin 4, (0, a) ∈ streets → (1, b) ∈ streets → (2, c) ∈ streets →
    (3, d) ∈ streets → ¬ [a, b, c, d].Nodup := by decide
-- Guards at W4, E1, E2 watch every street, and no 2 guards do.
example : IsTownCover {3} {0, 1} := by decide
example : ∀ A B : Finset (Fin 4), IsTownCover A B → 3 ≤ A.card + B.card := by decide
-- Among the 256 sets of junctions, W4, E1, E2 is the only cover of 3.
example : ∀ A B : Finset (Fin 4), IsTownCover A B → A.card + B.card = 3 → A = {3} ∧ B = {0, 1} := by
  decide
-- Hall: W1, W2, W3 reach only E1, E2, shortfall 3 - 2 = 1, and no west set falls short by more.
example : reach {0, 1, 2} = {0, 1} ∧ ({0, 1, 2} : Finset (Fin 4)).card - (reach {0, 1, 2}).card = 1 := by
  decide
example : ∀ S : Finset (Fin 4), S.card ≤ (reach S).card + 1 := by decide
-- The guards from Hall's set: N(S) together with the west junctions outside S, W4, E1, E2.
example : IsTownCover ({0, 1, 2}ᶜ) (reach {0, 1, 2}) ∧ ({0, 1, 2}ᶜ : Finset (Fin 4)) = {3} := by decide
example : 4 - 1 = 3 := by norm_num
-- The 5 junctions the cover leaves out (W1, W2, W3, E3, E4) are independent; no 6 are.
example : IsTownIndep {0, 1, 2} {2, 3} := by decide
example : ∀ A B : Finset (Fin 4), IsTownIndep A B → A.card + B.card ≤ 5 := by decide
-- An edge cover of 5 streets, and none smaller.
example : IsTownEdgeCover {(0, 1), (1, 0), (3, 2), (2, 1), (3, 3)} := by decide
-- No 4 streets (repeats allowed, so also no 3 or fewer) reach all 8 junctions.
example : ∀ i j k l : Fin 8,
    ¬ ((∀ w : Fin 4, w = (street i).1 ∨ w = (street j).1 ∨ w = (street k).1 ∨ w = (street l).1) ∧
      (∀ e : Fin 4, e = (street i).2 ∨ e = (street j).2 ∨ e = (street k).2 ∨ e = (street l).2)) := by
  decide
-- Gallai: 5 + 3 = 8 and 3 + 5 = 8; Step 4: 3 + 2 = 5 with 8 - 2 * 3 = 2.
example : 5 + 3 = 8 ∧ 3 + 5 = 8 ∧ 8 - 2 * 3 = 2 ∧ 3 + 2 = 5 := by norm_num
-- Mistakes: both ends of each matched street is 6 guards; one whole bank is 4 guards.
example : IsTownCover {0, 1, 3} {1, 0, 2} ∧ ({0, 1, 3} : Finset (Fin 4)).card + ({1, 0, 2} : Finset (Fin 4)).card = 6 := by
  decide
example : IsTownCover Finset.univ ∅ ∧ (Finset.univ : Finset (Fin 4)).card = 4 := by decide

/-! A ring of three junctions, not two-sided: matching 1, but 2 guards. -/

/-- The three streets of the ring, as pairs of junctions `0`, `1`, `2`. -/
def ring : Finset (Fin 3 × Fin 3) := {(0, 1), (1, 2), (0, 2)}

-- Any two streets of the ring share a junction, so a matching has at most 1 street.
example : ∀ a ∈ ring, ∀ b ∈ ring, a ≠ b → (a.1 = b.1 ∨ a.1 = b.2 ∨ a.2 = b.1 ∨ a.2 = b.2) := by decide
-- Every set of junctions meeting all three streets has at least 2.
example : ∀ C : Finset (Fin 3), (∀ s ∈ ring, s.1 ∈ C ∨ s.2 ∈ C) → 2 ≤ C.card := by decide

#print axioms konig_matching_number_eq_cover_number
#print axioms matching_card_le_vertex_cover_card
#print axioms gallai_identities
```

</details>

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'finMatching_of_isMatching' depends on axioms: [propext, Classical.choice, Quot.sound]
'exists_isMatching_of_finMatching' depends on axioms: [propext, Classical.choice, Quot.sound]
'card_covered_finMatching' depends on axioms: [propext, Classical.choice, Quot.sound]
'finMatching_card_le_cover' depends on axioms: [propext, Classical.choice, Quot.sound]
'mem_matchingSet_iff' depends on axioms: [propext, Classical.choice, Quot.sound]
'matchingNumber_spec' depends on axioms: [propext, Classical.choice, Quot.sound]
'coverNumber_spec' depends on axioms: [propext, Classical.choice, Quot.sound]
'exists_cover_le_finMatching' depends on axioms: [propext, Classical.choice, Quot.sound]
'konig_matching_number_eq_cover_number' depends on axioms: [propext, Classical.choice, Quot.sound]
'matching_card_le_vertex_cover_card' depends on axioms: [propext, Classical.choice, Quot.sound]
'gallai_identities' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run. The asserts are pinned to this plan, so one will stop the program.
> - **Add a bridge W3-E3:** `(2, 6)` in `ST`. Do three guards still do? No: matching and guards both reach 4.
> - **Break the river:** put `(0, 1)`, a west-bank street, first in `ST`. Road one finds matching 3 against 4 guards.
> - **Move W3's bridge to E4:** `(2, 5)` becomes `(2, 7)`. The shortfall drops to 0, and 5 guard sets of size 4 tie.

---

## The usual mistake

> [!warning]
> **Believing the smallest cover is one whole side.** Each bank is a cover, since every street crosses. The west bank cannot even be shrunk, since each of its guards alone watches some street, yet it costs 4. The only 3-guard cover among the 256 sets is mixed: W4, E1, E2.
>
> - **Dropping the condition.** A ring of three: matching 1, guards 2.
> - **Guarding both ends of a largest matching.** That is a cover, and a common quick method, but it costs 6: twice the answer.
> - **Confusing what covers what.** Junctions meeting every street is $\tau$, 3. Streets reaching every junction is $\rho$, 5.

---

## Where you meet it in real life

- **Sensor placement.** A sensor at a pipe junction watches every pipe meeting it. The cheapest sensor set is a smallest cover.
- **Tables of zeros and ones.** Kőnig's own form: the fewest rows and columns crossing out every 1 equals the most 1s with no two in a row or column. The assignment methods of [The assignment problem](../../14-Applied%20and%20computational/05-Operations%20Research/05-assignment-and-the-hungarian-algorithm.md) run on that reading.
- **Where the ease stops.** On a general graph no fast method for a smallest cover is known (Karp's list). Two sides make it easy.

> **Say it back**
> A matching is streets sharing no junction; a cover is junctions meeting every street. Each matched street needs its own guard, so covers are never smaller. On two sides, alternating walks from a largest matching give a cover of equal size: 3 here. A cover's leftovers are independent, so 5 + 3 = 8; a largest matching and a smallest edge cover also sum to 8.

---

## What this builds on

- [Hall's theorem](02-halls-marriage-theorem.md): the shortfall that fixes the matching number and hands Step 3 its cover.

## Where this goes next

- [The assignment problem](../../14-Applied%20and%20computational/05-Operations%20Research/05-assignment-and-the-hungarian-algorithm.md): the cover as the fewest lines through every zero of a cost table, which tells the method where to move.
- [Approximation](../../14-Applied%20and%20computational/02-Randomised%20and%20Approximate%20Algorithms/06-approximation-algorithms.md): both ends of a matching as a cover at most twice the smallest, on graphs without two sides.
- Karp's list: smallest vertex cover as one of Karp's original hard problems, once the two sides are gone.
- Parameterised complexity: how fast a small cover can still be found on a general graph, with the cover's size as the dial.

The river makes a smallest cover easy to find; later cards ask how hard it is without one.

---

## Sources

Verified 23 Sep 2026: every link below resolves to the publisher's page.

- Diestel, Reinhard. *Graph Theory*, 5th ed. Springer, 2017. [doi:10.1007/978-3-662-53622-3](https://doi.org/10.1007/978-3-662-53622-3). Theorem 2.1.1: Kőnig's theorem, proved with alternating paths.
- Bondy, J. A., and U. S. R. Murty. *Graph Theory*. Springer, 2008. [doi:10.1007/978-1-84628-970-5](https://doi.org/10.1007/978-1-84628-970-5). Covers, independent sets, matchings, edge covers.
- Schrijver, Alexander. "On the History of Combinatorial Optimization (till 1960)." [Full text, CWI](https://homepages.cwi.nl/~lex/files/histco.pdf). Dates Kőnig's and Egerváry's 1931 papers.
- Karp, Richard M. "Reducibility among Combinatorial Problems." In *Complexity of Computer Computations*, Springer, 1972. [doi:10.1007/978-1-4684-2001-2_9](https://doi.org/10.1007/978-1-4684-2001-2_9). Vertex cover among the first hard problems.
