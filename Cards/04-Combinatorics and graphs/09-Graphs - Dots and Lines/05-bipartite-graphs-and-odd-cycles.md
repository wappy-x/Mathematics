# Bipartite graphs: two sides with no edges inside a side, exactly when there is no odd cycle

[Syllabus](../../../SYLLABUS.md) → [Combinatorics and graphs](../README.md) → [Graphs - Dots and Lines](../README.md#s09) → Bipartite graphs

---

## General Overview

A catering firm has five staff — Ana, Ben, Cleo, Dan, Eve — and four shifts this week: Mon-am, Mon-pm, Tue-am, Tue-pm. Each has claimed the shifts they can work: nine claims.

Draw a dot per person, a dot per shift, a line per claim. Every line runs from a person to a shift, never between two people or two shifts. So the nine dots fall into two heaps, all nine lines crossing between them. A graph like that is **bipartite**.

Five cafes round a small square give the other half of the story: Bean, Crema, Drip, Grind and Latte, each competing with the two next door, so the five rivalries close a ring. Splitting them over two tasting nights, no two rivals sharing a night, asks for the same two heaps. It cannot be had: colour round the ring and the colours alternate, until the fifth line closes it on two cafes of one colour. Five is odd, and that is the obstruction.

**A graph's dots split into two sides with every line crossing exactly when the graph holds no closed route of odd length.**

**What kind of fact this is:** a theorem, proved both ways in Why it works; "bipartite" and "odd cycle" are definitions.

### The picture: nine dots, two heaps, nine lines

```mermaid
flowchart LR
    Ana["Ana"] --- S1["Mon-am"]
    Ana --- S2["Mon-pm"]
    Ben["Ben"] --- S1
    Ben --- S3["Tue-am"]
    Cleo["Cleo"] --- S2
    Cleo --- S4["Tue-pm"]
    Dan["Dan"] --- S3
    Dan --- S4
    Eve["Eve"] --- S1
```

Staff left, shifts right. Every line crosses the gap.

---

## The formula

Notation first, in words. A graph $G$ is two lists: the dots, collected as $V$, and the joined pairs, the lines, collected as $E$ ([Graphs](01-graphs-vertices-and-edges.md)). A **bipartition** names two heaps, $X$ and $Y$.

$$V = X \cup Y, \qquad X \cap Y = \{\,\}, \qquad \text{every line joins a dot of } X \text{ to a dot of } Y$$

**Read it aloud:** every dot sits in $X$ or in $Y$, none in both, and each line runs from one heap to the other.

A graph with such a cut is **bipartite**. A **cycle** is a closed route repeating no dot, its length its number of lines ([Walks, paths and cycles](03-walks-paths-and-cycles.md)); a length is odd when halving it leaves one over ([Even and odd](../../02-Number%20theory/01-Divisibility%20and%20Primes/02-even-and-odd.md)). The theorem is one line:

$$G \text{ is bipartite} \qquad\Longleftrightarrow\qquad G \text{ has no cycle of odd length}$$

**Read it aloud:** the two heaps exist exactly when no closed route uses an odd number of lines.

Finding the heaps means counting steps. Pick a starting dot, the **root**, and let $d(v)$ be the fewest lines from the root to the dot $v$ ([Connected or not](04-connectivity-and-breadth-first-search.md)). Colour $v$ by whether that count is even or odd, its remainder after division by two:

$$c(v) = d(v) \bmod 2$$

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $G$ | one graph: dots and joined pairs | the roster | — |
| $V$, $E$ | the dots; the lines | 9 dots; 9 lines | more lines, a clash grows likelier |
| $X$, $Y$ | the two heaps, no line inside either | 5 staff; 4 shifts | — |
| $d(v)$ | steps from the root, by the shortest route | Dan is 4 from Ana | more layers, same rule |
| $c(v)$ | 0 if $d(v)$ is even, 1 if odd | Dan 0, Tue-am 1 | — |
| $u$, $v$, $w$ | a line's ends; where their routes last met | Drip, Grind, Bean | — |

### When it holds

- **Plain lines.** No arrows, one line per pair at most, none from a dot to itself: that last is a closed route of length one, odd, and kills every cut.
- **Every piece of the sheet.** A graph in two pieces cuts only if both pieces do: roster and cafes on one sheet give 0 working cuts of 16384.
- **Two sides, not two equal sides.** Five staff face four shifts; only a graph with no lines at all can leave a heap empty.

---

## Why it works

### Step 0: along any route the side alternates

Suppose the two heaps exist. One line changes side; two return to the starting side. So a dot's side is fixed by the parity of the steps used to reach it, and by nothing else. Step 1 runs that forwards, Step 2 backwards.

### Step 1: a cut forbids odd cycles

Each line of a cycle flips the side, so an odd number of lines ends on the far side. A cycle ends where it began, so its length is even.

The pentagon fails on sight. Name the nights A and B: Bean A, Crema B, Drip A, Grind B, Latte A — and the fifth line joins Latte back to Bean, both on A.

### Step 2: no odd cycle forces a cut

The other direction builds the cut from distances: colour every dot by the parity of $d(v)$. Every dot gets a colour: the search covers the root's whole piece, and any dot left over becomes a new root. What remains is to check that no line joins two dots of one colour.

Suppose the line from $u$ to $v$ did. Each dot records the one dot it was reached from, so each has a single route back to the root, and that route is a shortest one. Let $w$ be the last dot the two routes share; past $w$ they have parted for good. Shortest routes make the stretch from $w$ to $u$ count $d(u) - d(w)$ lines. That stretch, the line, and the stretch from $v$ back to $w$ close a loop of

$$(d(u) - d(w)) + 1 + (d(v) - d(w)) \text{ lines}$$

Equal parities make $d(u)$ and $d(v)$ add to an even number; taking off twice $d(w)$ keeps it even; the extra line makes the count odd. That is an odd cycle, which the assumption forbids, so the colours are the heaps.

In the pentagon the search from Bean puts Crema and Latte one step out, Drip and Grind two. The line between those two joins dots at equal distance: 2 + 1 + 2 = 5 lines, the ring itself.

### The picture: the pentagon, and where the colours clash

```mermaid
flowchart LR
    Bean["Bean, 0 steps"] --- Crema["Crema, 1 step"]
    Crema --- Drip["Drip, 2 steps"]
    Drip --- Grind["Grind, 2 steps"]
    Grind --- Latte["Latte, 1 step"]
    Latte --- Bean
```

Steps out from Bean, the 2 and 2 the check prints for the clash.

<details>
<summary>Detailed proof: the two stretches really are a cycle</summary>

Both stretches are pieces of shortest routes, so neither repeats a dot; past $w$ they share none, each dot having one recorded route; and each meets the line only at its end. So the figure really is a cycle, of odd length by the count above. Disconnected graphs need nothing extra: heaps are named piece by piece and pooled.

</details>

### Step 3: the odd cycle is a certificate

"This graph has no cut" reads like a claim about every pair of heaps. The clash line makes it checkable: that line plus the routes back to the meeting dot is a short list of dots, and three cheap tests settle it — no dot twice, at least three dots, every neighbouring pair joined. The check prints Drip Crema Bean Latte Grind, runs all three, and pins the count at 5, odd.

The second road drops parity and tries every cut of the dots into two heaps: 2 of 512 work for the roster, 0 of 32 for the pentagon. Trying every cut stops being practical past about thirty dots; the layers read each line once. The recorded routes form a tree spanning the piece, and the same proof runs from any spanning tree.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| dots and lines | 5 staff + 4 shifts; the claims | 9 dots, 9 of the 20 pairs |
| lines at each dot | 2 2 2 2 1, then 3 2 2 2 | 9 and 9 |
| the search from Ana | 0 Ana; 1 Mon-am Mon-pm; 2 Ben Cleo Eve; 3 Tue-am Tue-pm; 4 Dan | **5 staff \| 4 shifts** |
| roster cuts tried | all 512 | **2**: the cut and its mirror |
| pentagon cuts tried | all 32 | **0** |
| the clash, and its loop | both ends 2 steps out; 2 + 1 + 2 | **5 lines, odd** |
| the shelf's metro map, stations A to F | 8 lines, 64 cuts | **A C E \| B D F**, 2 work |

The even layers are the staff, the odd ones the shifts, and both tallies come to 9, each line counted once from each side ([Degrees and the handshaking lemma](02-degree-and-handshaking.md)). The pentagon has no heaps, and its five-line loop is the proof.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| "No triangle" read as "cuts in two" | cafes: triangles 0, cuts 0 of 32 | A triangle is the shortest odd cycle, not the only one |
| A line inside a side: Ana covers Ben | 0 of 512 cuts; a 3-line loop, Ben Ana Mon-am | It closes an odd cycle through Mon-am |
| Only the piece reached first coloured | roster and cafes on a sheet: 0 of 16384 | Every piece must cut, not the first alone |

The code prints all three.

---

## Code, from first principles, and it actually runs

Nothing is imported. Five graphs run: the roster, the cafes, this shelf's metro map, the roster with a line inside a side, and the roster and cafes as one graph. Two roads share no arithmetic. One colours dots by the parity of their distance from a root, found by breadth-first search (BFS in the code). The other tries every cut into two heaps and keeps those with no line inside a heap. Where the colours clash, a third step builds the loop and checks it is a real cycle.

### Python

```python
# Bipartite graphs -- the check behind the card.  Nothing is imported.  The roster joins 5
# workers to the 4 shifts they can cover; the cafes are 5 rivals in a ring.  "Does it split
# in two?" is answered twice: BFS layers by parity of steps, and trying every cut of the dots.
ROSTER = ("Ana Ben Cleo Dan Eve Mon-am Mon-pm Tue-am Tue-pm".split(),
          [(0, 5), (0, 6), (1, 5), (1, 7), (2, 6), (2, 8), (3, 7), (3, 8), (4, 5)])
CAFES = ("Bean Crema Drip Grind Latte".split(), [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)])
METRO = (list("ABCDEF"), [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (1, 4), (2, 5)])
COVER = (ROSTER[0], ROSTER[1] + [(0, 1)])          # Ana covers Ben: a line inside a side
BOTH = (ROSTER[0] + CAFES[0], ROSTER[1] + [(u + 9, v + 9) for u, v in CAFES[1]])
def adj(names, edges):                             # who is joined to whom
    a = [[] for _ in names]
    for u, v in edges: a[u].append(v); a[v].append(u)
    return a
def layers(names, edges):                          # road one: BFS, colour = parity of steps out
    a, dist, parent = adj(names, edges), [-1] * len(names), [-1] * len(names)
    for root in range(len(names)):                 # every component gets its own root
        if dist[root] >= 0: continue
        dist[root], queue = 0, [root]
        while queue:
            v = queue.pop(0)
            for w in [w for w in a[v] if dist[w] < 0]: dist[w], parent[w] = dist[v] + 1, v; queue.append(w)
    clash = next(((u, v) for u, v in edges if dist[u] % 2 == dist[v] % 2), None)
    return dist, parent, clash
def odd_loop(parent, clash):                       # the clash line, plus both routes to the root
    def route(x, out=()):
        return route(parent[x], out + (x,)) if x >= 0 else list(out)
    ru, rv = route(clash[0]), route(clash[1])
    meet = next(x for x in ru if x in rv)          # the last dot the two routes share
    return ru[:ru.index(meet) + 1] + rv[:rv.index(meet)][::-1]
real = lambda a, c: len(set(c)) == len(c) >= 3 and all(c[(i + 1) % len(c)] in a[c[i]] for i in range(len(c)))
def cuts(names, edges):                            # road two: try every cut of the dots in two
    ok = [m for m in range(1 << len(names)) if all((m >> u & 1) != (m >> v & 1) for u, v in edges)]
    return len(ok), (ok[0] if ok else 0)
show = lambda names, keep: " ".join(n for i, n in enumerate(names) if keep(i))
CASES, kept = [("roster", ROSTER), ("cafes", CAFES), ("metro map", METRO),
               ("roster, Ana covers Ben", COVER), ("roster and cafes at once", BOTH)], {}
for label, (names, edges) in CASES:
    a, (good, first) = adj(names, edges), cuts(names, edges)
    dist, parent, clash = layers(names, edges)
    loop = odd_loop(parent, clash) if clash else []
    kept[label] = (good, first, dist, loop, clash)
    tri = sum(1 for u in range(len(names)) for v in a[u] for w in a[v] if u < v < w and u in a[w])
    clash_s = "none" if not clash else f"{names[clash[0]]}-{names[clash[1]]}, steps out {dist[clash[0]]} and {dist[clash[1]]}"
    tail = (f"heaps {show(names, lambda i: first >> i & 1)} | {show(names, lambda i: not first >> i & 1)}" if good
            else f"odd loop {' '.join(names[i] for i in loop)}, {len(loop)} lines, real cycle {'yes' if real(a, loop) else 'no'}")
    print(f"{label}: {len(names)} dots, {len(edges)} lines; working cuts {good} of {1 << len(names)}; "
          f"triangles {tri}; clash {clash_s}; {tail}")
names, deg, (_, first_r, dist_r, _, _) = ROSTER[0], [len(r) for r in adj(*ROSTER)], kept["roster"]
even, odd = show(names, lambda i: dist_r[i] % 2 == 0), show(names, lambda i: dist_r[i] % 2 == 1)
cut_a, cut_b = show(names, lambda i: first_r >> i & 1), show(names, lambda i: not first_r >> i & 1)
print(f"roster: 5 workers, 4 shifts, {len(ROSTER[1])} of the {5 * 4} possible pairs; lines per worker "
      f"{' '.join(map(str, deg[:5]))} = {sum(deg[:5])}, per shift {' '.join(map(str, deg[5:]))} = {sum(deg[5:])}")
print("BFS from Ana: " + " | ".join(f"{d} " + show(names, lambda i: dist_r[i] == d) for d in range(max(dist_r) + 1)))
print(f"even steps out {even}; odd steps out {odd}; the same two heaps as the first working cut of "
      f"{1 << len(names)}: {'yes' if {even, odd} == {cut_a, cut_b} else 'no'}")
assert {even, odd} == {cut_a, cut_b}                                       # two roads, one cut
assert real(adj(*CAFES), kept["cafes"][3]) and len(kept["cafes"][3]) == 5  # the certificate holds
assert sum(deg[:5]) == sum(deg[5:]) == len(ROSTER[1])                      # each side counts every line
assert all((v[4] is None) == (v[0] > 0) for v in kept.values())            # the roads agree, 5 graphs
print("ALL CHECKS PASS")
```

**Ran 2026-09-19 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
roster: 9 dots, 9 lines; working cuts 2 of 512; triangles 0; clash none; heaps Ana Ben Cleo Dan Eve | Mon-am Mon-pm Tue-am Tue-pm
cafes: 5 dots, 5 lines; working cuts 0 of 32; triangles 0; clash Drip-Grind, steps out 2 and 2; odd loop Drip Crema Bean Latte Grind, 5 lines, real cycle yes
metro map: 6 dots, 8 lines; working cuts 2 of 64; triangles 0; clash none; heaps A C E | B D F
roster, Ana covers Ben: 9 dots, 10 lines; working cuts 0 of 512; triangles 1; clash Ben-Mon-am, steps out 1 and 1; odd loop Ben Ana Mon-am, 3 lines, real cycle yes
roster and cafes at once: 14 dots, 14 lines; working cuts 0 of 16384; triangles 0; clash Drip-Grind, steps out 2 and 2; odd loop Drip Crema Bean Latte Grind, 5 lines, real cycle yes
roster: 5 workers, 4 shifts, 9 of the 20 possible pairs; lines per worker 2 2 2 2 1 = 9, per shift 3 2 2 2 = 9
BFS from Ana: 0 Ana | 1 Mon-am Mon-pm | 2 Ben Cleo Eve | 3 Tue-am Tue-pm | 4 Dan
even steps out Ana Ben Cleo Dan Eve; odd steps out Mon-am Mon-pm Tue-am Tue-pm; the same two heaps as the first working cut of 512: yes
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Bipartite graphs -- the same check as the Python, in Rust.  No crates.  The roster joins 5 workers
// to the 4 shifts they can cover, the cafes are 5 rivals in a ring; both roads run on every graph.
fn adj(n: usize, edges: &[(usize, usize)]) -> Vec<Vec<usize>> {    // who is joined to whom
    let mut a = vec![Vec::new(); n]; for &(u, v) in edges { a[u].push(v); a[v].push(u) } a
}
fn layers(n: usize, edges: &[(usize, usize)]) -> (Vec<i64>, Vec<i64>, Option<(usize, usize)>) {
    let (a, mut dist, mut parent) = (adj(n, edges), vec![-1i64; n], vec![-1i64; n]);
    for root in 0..n {                             // every component gets its own root
        if dist[root] >= 0 { continue }
        dist[root] = 0; let (mut queue, mut head) = (vec![root], 0);
        while head < queue.len() {
            let v = queue[head]; head += 1;
            for w in a[v].clone() { if dist[w] < 0 { dist[w] = dist[v] + 1; parent[w] = v as i64; queue.push(w) } }
        }
    }
    (dist.clone(), parent, edges.iter().copied().find(|&(u, v)| dist[u] % 2 == dist[v] % 2))
}
fn odd_loop(parent: &[i64], clash: (usize, usize)) -> Vec<usize> {   // the clash line, plus both routes
    let route = |mut x: i64| { let mut o = Vec::new(); while x >= 0 { o.push(x as usize); x = parent[x as usize] } o };
    let (ru, rv) = (route(clash.0 as i64), route(clash.1 as i64));
    let meet = *ru.iter().find(|x| rv.contains(x)).unwrap();         // the last dot the two routes share
    let (iu, iv) = (ru.iter().position(|&x| x == meet).unwrap(), rv.iter().position(|&x| x == meet).unwrap());
    [&ru[..=iu], &rv[..iv].iter().rev().copied().collect::<Vec<usize>>()[..]].concat()
}
fn real(a: &[Vec<usize>], c: &[usize]) -> bool {   // dots all different, every step a line
    let mut s = c.to_vec(); s.sort(); s.dedup();
    s.len() == c.len() && c.len() >= 3 && (0..c.len()).all(|i| a[c[i]].contains(&c[(i + 1) % c.len()]))
}
fn cuts(n: usize, edges: &[(usize, usize)]) -> (usize, usize) {     // road two: try every cut
    let ok: Vec<usize> = (0..1usize << n).filter(|m| edges.iter().all(|&(u, v)| (m >> u & 1) != (m >> v & 1))).collect();
    (ok.len(), if ok.is_empty() { 0 } else { ok[0] })
}
fn show(names: &[&str], keep: impl Fn(usize) -> bool) -> String {   // the dots named, in index order
    names.iter().enumerate().filter(|&(i, _)| keep(i)).map(|(_, n)| *n).collect::<Vec<&str>>().join(" ")
}
fn main() {
    let rnames: Vec<&str> = "Ana Ben Cleo Dan Eve Mon-am Mon-pm Tue-am Tue-pm".split(' ').collect();
    let redges = vec![(0, 5), (0, 6), (1, 5), (1, 7), (2, 6), (2, 8), (3, 7), (3, 8), (4, 5)];
    let cnames: Vec<&str> = "Bean Crema Drip Grind Latte".split(' ').collect();
    let cedges = vec![(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)];
    let mnames: Vec<&str> = "A B C D E F".split(' ').collect();
    let medges = vec![(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (1, 4), (2, 5)];
    let cover = [redges.clone(), vec![(0, 1)]].concat();            // Ana covers Ben: a line inside a side
    let bnames: Vec<&str> = rnames.iter().chain(cnames.iter()).copied().collect();
    let bedges = [redges.clone(), cedges.iter().map(|&(u, v)| (u + 9, v + 9)).collect()].concat();
    let cases = vec![("roster", &rnames, &redges), ("cafes", &cnames, &cedges), ("metro map", &mnames, &medges),
                     ("roster, Ana covers Ben", &rnames, &cover), ("roster and cafes at once", &bnames, &bedges)];
    let mut kept = Vec::new();
    for (label, names, edges) in &cases {
        let (n, a, (good, first)) = (names.len(), adj(names.len(), edges), cuts(names.len(), edges));
        let (dist, parent, clash) = layers(n, edges);
        let cycle = match clash { Some(c) => odd_loop(&parent, c), None => Vec::new() };
        let mut tri = 0; for u in 0..n { for &v in &a[u] { for &w in &a[v] { if u < v && v < w && a[w].contains(&u) { tri += 1 } } } }
        let clash_s = match clash { Some((u, v)) => format!("{}-{}, steps out {} and {}", names[u], names[v], dist[u], dist[v]), None => "none".to_string() };
        let tail = if good > 0 { format!("heaps {} | {}", show(names, |i| first >> i & 1 == 1), show(names, |i| first >> i & 1 == 0)) }
            else { format!("odd loop {}, {} lines, real cycle {}", cycle.iter().map(|&i| names[i]).collect::<Vec<&str>>().join(" "), cycle.len(), if real(&a, &cycle) { "yes" } else { "no" }) };
        println!("{}: {} dots, {} lines; working cuts {} of {}; triangles {}; clash {}; {}",
                 label, n, edges.len(), good, 1usize << n, tri, clash_s, tail);
        kept.push((good, first, dist, cycle, clash));
    }
    let (first_r, dist_r) = (kept[0].1, kept[0].2.clone());
    let deg: Vec<usize> = adj(rnames.len(), &redges).iter().map(|r| r.len()).collect();
    let (wsum, ssum) = (deg[..5].iter().sum::<usize>(), deg[5..].iter().sum::<usize>());
    let jn = |d: &[usize]| d.iter().map(|x| x.to_string()).collect::<Vec<String>>().join(" ");
    let (even, odd) = (show(&rnames, |i| dist_r[i] % 2 == 0), show(&rnames, |i| dist_r[i] % 2 == 1));
    let (ca, cb) = (show(&rnames, |i| first_r >> i & 1 == 1), show(&rnames, |i| first_r >> i & 1 == 0));
    let agree = (even == ca && odd == cb) || (even == cb && odd == ca);
    println!("roster: 5 workers, 4 shifts, {} of the {} possible pairs; lines per worker {} = {}, per shift {} = {}",
             redges.len(), 5 * 4, jn(&deg[..5]), wsum, jn(&deg[5..]), ssum);
    println!("BFS from Ana: {}", (0..=*dist_r.iter().max().unwrap())
             .map(|d| format!("{} {}", d, show(&rnames, |i| dist_r[i] == d))).collect::<Vec<String>>().join(" | "));
    println!("even steps out {}; odd steps out {}; the same two heaps as the first working cut of {}: {}",
             even, odd, 1usize << rnames.len(), if agree { "yes" } else { "no" });
    assert!(agree);                                                       // two roads, one cut
    assert!(real(&adj(5, &cedges), &kept[1].3) && kept[1].3.len() == 5);  // the certificate holds
    assert!(wsum == ssum && ssum == redges.len());                        // each side counts every line
    assert!(kept.iter().all(|k| k.4.is_none() == (k.0 > 0)));             // the roads agree, 5 graphs
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-19 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
roster: 9 dots, 9 lines; working cuts 2 of 512; triangles 0; clash none; heaps Ana Ben Cleo Dan Eve | Mon-am Mon-pm Tue-am Tue-pm
cafes: 5 dots, 5 lines; working cuts 0 of 32; triangles 0; clash Drip-Grind, steps out 2 and 2; odd loop Drip Crema Bean Latte Grind, 5 lines, real cycle yes
metro map: 6 dots, 8 lines; working cuts 2 of 64; triangles 0; clash none; heaps A C E | B D F
roster, Ana covers Ben: 9 dots, 10 lines; working cuts 0 of 512; triangles 1; clash Ben-Mon-am, steps out 1 and 1; odd loop Ben Ana Mon-am, 3 lines, real cycle yes
roster and cafes at once: 14 dots, 14 lines; working cuts 0 of 16384; triangles 0; clash Drip-Grind, steps out 2 and 2; odd loop Drip Crema Bean Latte Grind, 5 lines, real cycle yes
roster: 5 workers, 4 shifts, 9 of the 20 possible pairs; lines per worker 2 2 2 2 1 = 9, per shift 3 2 2 2 = 9
BFS from Ana: 0 Ana | 1 Mon-am Mon-pm | 2 Ben Cleo Eve | 3 Tue-am Tue-pm | 4 Dan
even steps out Ana Ben Cleo Dan Eve; odd steps out Mon-am Mon-pm Tue-am Tue-pm; the same two heaps as the first working cut of 512: yes
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves three facts for every graph with plain lines, then checks the card's roster, cafes and metro map.

- A graph is bipartite exactly when it has no cycle of odd length.
- With no odd cycle and any root, each line in the root's piece joins a dot with even $d(v)$ to one with odd $d(v)$.
- Two graphs on one sheet cut in two exactly when each of them does.
- The roster has 9 lines: 2 2 2 2 1 at the staff, 3 2 2 2 at the shifts.
- Staff against shifts is a working cut, and exactly 2 of the roster's 512 cuts work.
- The search from Ana gives 0 Ana; 1 Mon-am Mon-pm; 2 Ben Cleo Eve; 3 Tue-am Tue-pm; 4 Dan.
- The cafes hold no triangle, yet none of their 32 cuts works.
- From Bean, Crema and Latte are 1 step out, and Drip and Grind are 2.
- Drip Crema Bean Latte Grind is a real cycle of 5 lines.
- When Ana covers Ben, none of the 512 cuts works, and Ben Ana Mon-am is a 3-line cycle.
- On the metro map, 2 of the 64 cuts work, and A C E against B D F is one.

The search code, the triangle counts and the 0 of 16384 cuts for roster and cafes together are left to the Python and Rust checks.

<details>
<summary>The Lean proof, 319 lines</summary>

```lean
-- Bipartite graphs: a graph's dots split into two sides with every line crossing exactly when it has no cycle of odd length, the parity of the distance from a root gives the sides, a graph in two pieces splits only when both pieces do, and the card's roster, cafes and metro map have the cuts, distances and odd cycle it claims.
import Mathlib.Combinatorics.SimpleGraph.Paths
import Mathlib.Combinatorics.SimpleGraph.Metric
import Mathlib.Combinatorics.SimpleGraph.Sum
import Mathlib.Combinatorics.SimpleGraph.Clique
import Mathlib.Combinatorics.SimpleGraph.Coloring.Constructions

open SimpleGraph

/-- A bipartition of `G` into the heaps `X` and `Y`: every dot sits in `X` or in `Y`, none in
both, and every line joins a dot of `X` to a dot of `Y`. -/
def IsTwoSideCut {V : Type*} (G : SimpleGraph V) (X Y : Set V) : Prop :=
  X ∪ Y = Set.univ ∧ Disjoint X Y ∧ ∀ u v, G.Adj u v → (u ∈ X ∧ v ∈ Y) ∨ (u ∈ Y ∧ v ∈ X)

/-- Without an odd cycle, shortening a walk to a path keeps the parity of its length. -/
theorem bip_bypass_length_mod_two {V : Type*} [DecidableEq V] (G : SimpleGraph V)
    (h : ¬ ∃ (u : V) (c : G.Walk u u), c.IsCycle ∧ Odd c.length) :
    ∀ {a b : V} (p : G.Walk a b), p.bypass.length % 2 = p.length % 2 := by
  intro a b p
  induction p with
  | nil => rfl
  | @cons a c b ha p ih =>
    simp only [Walk.bypass]
    split_ifs with hs
    · have hlen := congrArg Walk.length (p.bypass.take_spec hs)
      rw [Walk.length_append] at hlen
      have hq : (p.bypass.takeUntil a hs).IsPath := (Walk.bypass_isPath p).takeUntil hs
      have hodd : (p.bypass.takeUntil a hs).length % 2 = 1 := by
        by_contra hev
        have hne : (p.bypass.takeUntil a hs).length ≠ 0 := by
          intro h0
          exact ha.ne (Walk.eq_of_length_eq_zero h0).symm
        apply h
        refine ⟨a, Walk.cons ha (p.bypass.takeUntil a hs), ?_, ?_⟩
        · rw [Walk.isCycle_iff_isPath_tail_and_le_length]
          refine ⟨?_, ?_⟩
          · simpa [Walk.tail_cons] using hq
          · simp only [Walk.length_cons]; omega
        · simp only [Walk.length_cons]
          rw [Nat.odd_iff]; omega
      simp only [Walk.length_cons]
      omega
    · simp only [Walk.length_cons]
      omega

/-- Without an odd cycle, every closed walk has even length. -/
theorem bip_even_of_no_odd_cycle {V : Type*} (G : SimpleGraph V)
    (h : ¬ ∃ (u : V) (c : G.Walk u u), c.IsCycle ∧ Odd c.length) (u : V) (w : G.Walk u u) :
    Even w.length := by
  classical
  have h1 := bip_bypass_length_mod_two G h w
  have h2 : w.bypass.length = 0 := (Walk.nil_bypass w).length_eq_zero
  rw [Nat.even_iff]; omega

/-- Along a walk in a graph cut into `X` and its complement, membership in `X` flips at each step. -/
theorem bip_walk_parity {V : Type*} (G : SimpleGraph V) (X : Set V)
    (hX : ∀ u v, G.Adj u v → (u ∈ X ↔ v ∉ X)) :
    ∀ {a b : V} (p : G.Walk a b), ((a ∈ X ↔ b ∈ X) ↔ Even p.length) := by
  intro a b p
  induction p with
  | nil => simp
  | @cons a c b ha p ih =>
    rw [Walk.length_cons, Nat.even_add_one, ← ih]
    have := hX a c ha
    tauto

/-- Distances from a root given by a potential that rises by at most one along each line and
has a predecessor one lower at every other dot. -/
theorem bip_dist_eq_of_potential {V : Type*} (G : SimpleGraph V) (r : V) (f : V → ℕ)
    (h0 : f r = 0) (hadj : ∀ a b, G.Adj a b → f b ≤ f a + 1)
    (hpred : ∀ b, b ≠ r → ∃ a, G.Adj a b ∧ f a + 1 = f b) (v : V) :
    G.dist r v = f v := by
  have hlow : ∀ {a b : V} (p : G.Walk a b), f b ≤ f a + p.length := by
    intro a b p
    induction p with
    | nil => simp
    | @cons a c b ha p ih =>
      have := hadj a c ha
      simp only [Walk.length_cons]; omega
  have hup : ∀ n, ∀ b, f b = n → ∃ p : G.Walk r b, p.length = n := by
    intro n
    induction n with
    | zero =>
      intro b hb
      by_cases hbr : b = r
      · subst hbr; exact ⟨Walk.nil, rfl⟩
      · obtain ⟨a, _, ha⟩ := hpred b hbr; omega
    | succ n ih =>
      intro b hb
      have hbr : b ≠ r := by rintro rfl; omega
      obtain ⟨a, hab, ha⟩ := hpred b hbr
      obtain ⟨p, hp⟩ := ih a (by omega)
      exact ⟨p.concat hab, by simp [hp]⟩
  obtain ⟨p, hp⟩ := hup (f v) v rfl
  have hle := SimpleGraph.dist_le p
  obtain ⟨q, hq⟩ := (p.reachable).exists_walk_length_eq_dist
  have := hlow q
  omega

/-- The theorem of the card. A graph's dots split into two heaps with every line crossing between
them exactly when the graph has no cycle (a closed route repeating no dot) of odd length. -/
theorem two_sides_iff_no_odd_cycle {V : Type*} (G : SimpleGraph V) :
    (∃ X Y : Set V, IsTwoSideCut G X Y) ↔
      ¬ ∃ (u : V) (c : G.Walk u u), c.IsCycle ∧ Odd c.length := by
  constructor
  · rintro ⟨X, Y, hU, hD, hA⟩ ⟨u, c, -, hodd⟩
    have hY : ∀ w, w ∈ Y ↔ w ∉ X := by
      intro w
      constructor
      · intro hw hwX
        exact Set.disjoint_left.mp hD hwX hw
      · intro hw
        have : w ∈ X ∪ Y := by rw [hU]; trivial
        rcases this with h | h
        · exact absurd h hw
        · exact h
    have hX : ∀ u v, G.Adj u v → (u ∈ X ↔ v ∉ X) := by
      intro u v huv
      rcases hA u v huv with ⟨h1, h2⟩ | ⟨h1, h2⟩
      · rw [hY] at h2; tauto
      · rw [hY] at h1; tauto
    exact (Nat.not_even_iff_odd.mpr hodd) ((bip_walk_parity G X hX c).mp Iff.rfl)
  · intro h
    obtain ⟨c⟩ : G.Colorable 2 :=
      two_colorable_iff_forall_loop_even.mpr (bip_even_of_no_odd_cycle G h)
    refine ⟨{v | c v = 0}, {v | c v = 1}, ?_, ?_, ?_⟩
    · ext v
      simp only [Set.mem_union, Set.mem_ofPred_eq, Set.mem_univ, iff_true]
      generalize c v = x
      fin_cases x <;> simp
    · rw [Set.disjoint_left]
      intro v h1 h2
      simp only [Set.mem_ofPred_eq] at h1 h2
      rw [h1] at h2
      exact absurd h2 (by decide)
    · intro u v huv
      have hne := c.valid huv
      simp only [Set.mem_ofPred_eq]
      revert hne
      generalize c u = x
      generalize c v = y
      fin_cases x <;> fin_cases y <;> simp

/-- Colouring by the parity of the distance from a root works. In a graph with no odd cycle, take
any root: for every line from `u` to `v` in the root's piece, the fewest steps from the root to
`u` and to `v` have different remainders on division by two, so no line joins two dots of one
colour. -/
theorem distance_parity_colours_are_the_sides {V : Type*} (G : SimpleGraph V)
    (h : ¬ ∃ (u : V) (c : G.Walk u u), c.IsCycle ∧ Odd c.length) (root u v : V)
    (hu : G.Reachable root u) (huv : G.Adj u v) :
    G.dist root u % 2 ≠ G.dist root v % 2 := by
  have hv : G.Reachable root v := hu.trans huv.reachable
  obtain ⟨p, hp⟩ := hu.exists_walk_length_eq_dist
  obtain ⟨q, hq⟩ := hv.exists_walk_length_eq_dist
  have he := bip_even_of_no_odd_cycle G h root ((p.concat huv).append q.reverse)
  rw [Walk.length_append, Walk.length_concat, Walk.length_reverse, hp, hq, Nat.even_iff] at he
  omega

/-- Every piece of the sheet must cut. Two graphs drawn side by side on one sheet split into two
heaps with every line crossing exactly when each of the two graphs does. -/
theorem side_by_side_cuts_iff_both_cut {V W : Type*} (G : SimpleGraph V) (H : SimpleGraph W) :
    (∃ X Y : Set (V ⊕ W), IsTwoSideCut (G ⊕g H) X Y) ↔
      (∃ X Y : Set V, IsTwoSideCut G X Y) ∧ (∃ X Y : Set W, IsTwoSideCut H X Y) := by
  constructor
  · rintro ⟨X, Y, hU, hD, hA⟩
    refine ⟨⟨Sum.inl ⁻¹' X, Sum.inl ⁻¹' Y, ?_, ?_, ?_⟩,
      ⟨Sum.inr ⁻¹' X, Sum.inr ⁻¹' Y, ?_, ?_, ?_⟩⟩
    · rw [← Set.preimage_union, hU, Set.preimage_univ]
    · exact hD.preimage _
    · intro u v huv
      simpa using hA (Sum.inl u) (Sum.inl v) (by simpa using huv)
    · rw [← Set.preimage_union, hU, Set.preimage_univ]
    · exact hD.preimage _
    · intro u v huv
      simpa using hA (Sum.inr u) (Sum.inr v) (by simpa using huv)
  · rintro ⟨⟨X1, Y1, hU1, hD1, hA1⟩, ⟨X2, Y2, hU2, hD2, hA2⟩⟩
    refine ⟨{s | Sum.elim (· ∈ X1) (· ∈ X2) s}, {s | Sum.elim (· ∈ Y1) (· ∈ Y2) s}, ?_, ?_, ?_⟩
    · ext (a | b)
      · simpa using (Set.ext_iff.mp hU1 a)
      · simpa using (Set.ext_iff.mp hU2 b)
    · rw [Set.disjoint_left]
      rintro (a | b) h1 h2
      · exact Set.disjoint_left.mp hD1 h1 h2
      · exact Set.disjoint_left.mp hD2 h1 h2
    · rintro (a | b) (a' | b') huv
      · simpa using hA1 a a' (by simpa using huv)
      · simp at huv
      · simp at huv
      · simpa using hA2 b b' (by simpa using huv)

/-! The card's graphs. The roster: Ana, Ben, Cleo, Dan, Eve are 0 to 4, and the shifts Mon-am,
Mon-pm, Tue-am, Tue-pm are 5 to 8. The cafes: Bean, Crema, Drip, Grind, Latte are 0 to 4.
The metro map: stations A to F are 0 to 5. In the cut counts, a set `X` of dots stands for the
cut `X` against the rest, and the cut works when every line has one end in `X` and one outside. -/

/-- The nine claims of the roster, each listed once. -/
def rosterLines : List (Fin 9 × Fin 9) :=
  [(0, 5), (0, 6), (1, 5), (1, 7), (2, 6), (2, 8), (3, 7), (3, 8), (4, 5)]

/-- The roster as a graph: a person and a shift are joined when the person claimed the shift. -/
def roster : SimpleGraph (Fin 9) where
  Adj a b := (a, b) ∈ rosterLines ∨ (b, a) ∈ rosterLines
  symm := ⟨fun _ _ h => h.symm⟩
  loopless := ⟨by decide⟩

instance : DecidableRel roster.Adj := fun a b =>
  inferInstanceAs (Decidable ((a, b) ∈ rosterLines ∨ (b, a) ∈ rosterLines))

/-- The roster with one line inside a side: Ana covers Ben. -/
def coverLines : List (Fin 9 × Fin 9) := rosterLines ++ [(0, 1)]

def cover : SimpleGraph (Fin 9) where
  Adj a b := (a, b) ∈ coverLines ∨ (b, a) ∈ coverLines
  symm := ⟨fun _ _ h => h.symm⟩
  loopless := ⟨by decide⟩

instance : DecidableRel cover.Adj := fun a b =>
  inferInstanceAs (Decidable ((a, b) ∈ coverLines ∨ (b, a) ∈ coverLines))

/-- The five rivalries of the cafes, closing a ring. -/
def cafeLines : List (Fin 5 × Fin 5) := [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]

def cafes : SimpleGraph (Fin 5) where
  Adj a b := (a, b) ∈ cafeLines ∨ (b, a) ∈ cafeLines
  symm := ⟨fun _ _ h => h.symm⟩
  loopless := ⟨by decide⟩

instance : DecidableRel cafes.Adj := fun a b =>
  inferInstanceAs (Decidable ((a, b) ∈ cafeLines ∨ (b, a) ∈ cafeLines))

/-- The eight lines of the metro map. -/
def metroLines : List (Fin 6 × Fin 6) :=
  [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (1, 4), (2, 5)]

def metro : SimpleGraph (Fin 6) where
  Adj a b := (a, b) ∈ metroLines ∨ (b, a) ∈ metroLines
  symm := ⟨fun _ _ h => h.symm⟩
  loopless := ⟨by decide⟩

instance : DecidableRel metro.Adj := fun a b =>
  inferInstanceAs (Decidable ((a, b) ∈ metroLines ∨ (b, a) ∈ metroLines))

/-- The odd loop the check prints: Drip, Crema, Bean, Latte, Grind and back to Drip. -/
def cafeLoop : cafes.Walk 2 2 :=
  .cons (v := 1) (by decide) <| .cons (v := 0) (by decide) <| .cons (v := 4) (by decide) <|
    .cons (v := 3) (by decide) <| .cons (v := 2) (by decide) .nil

/-- The 3-line loop made by Ana covering Ben: Ben, Ana, Mon-am and back to Ben. -/
def coverLoop : cover.Walk 1 1 :=
  .cons (v := 0) (by decide) <| .cons (v := 5) (by decide) <| .cons (v := 1) (by decide) .nil

-- The roster: 9 lines, 5 staff with 2 2 2 2 1 lines and 4 shifts with 3 2 2 2, both tallies 9.
example : roster.edgeFinset.card = 9 := by decide
example : (List.ofFn fun i : Fin 9 => roster.degree i) = [2, 2, 2, 2, 1, 3, 2, 2, 2] := by decide
-- Staff against shifts is a working cut.
example : IsTwoSideCut roster {0, 1, 2, 3, 4} {5, 6, 7, 8} := by
  refine ⟨?_, ?_, ?_⟩
  · ext x
    simp only [Set.mem_union, Set.mem_insert_iff, Set.mem_singleton_iff, Set.mem_univ, iff_true]
    revert x
    decide
  · rw [Set.disjoint_left]
    simp only [Set.mem_insert_iff, Set.mem_singleton_iff]
    decide
  · simp only [Set.mem_insert_iff, Set.mem_singleton_iff]
    decide
-- Of the 512 cuts of the roster's 9 dots, exactly 2 work: the cut and its mirror.
example : (Finset.univ.filter (fun X : Finset (Fin 9) =>
    ∀ u v, roster.Adj u v → (u ∈ X ↔ v ∉ X))).card = 2 := by decide +kernel
-- The search from Ana: 0 Ana; 1 Mon-am Mon-pm; 2 Ben Cleo Eve; 3 Tue-am Tue-pm; 4 Dan.
example : (List.ofFn fun i : Fin 9 => roster.dist 0 i) = [0, 2, 2, 4, 2, 1, 1, 3, 3] := by
  have key := bip_dist_eq_of_potential roster 0 (![0, 2, 2, 4, 2, 1, 1, 3, 3] : Fin 9 → ℕ) (by decide) (by decide) (by decide)
  simp only [key]
  decide
-- The cafes: none of the 32 cuts works, and there is no triangle.
example : (Finset.univ.filter (fun X : Finset (Fin 5) =>
    ∀ u v, cafes.Adj u v → (u ∈ X ↔ v ∉ X))).card = 0 := by decide +kernel
example : cafes.CliqueFree 3 := by
  unfold CliqueFree
  decide
-- The search from Bean: Crema and Latte 1 step out, Drip and Grind 2.
example : (List.ofFn fun i : Fin 5 => cafes.dist 0 i) = [0, 1, 2, 2, 1] := by
  have key := bip_dist_eq_of_potential cafes 0 (![0, 1, 2, 2, 1] : Fin 5 → ℕ) (by decide) (by decide) (by decide)
  simp only [key]
  decide
-- The clash Drip-Grind closes a loop of 2 + 1 + 2 = 5 lines, a real cycle.
example : cafeLoop.IsCycle ∧ cafeLoop.length = 5 := by
  refine ⟨?_, rfl⟩
  rw [Walk.isCycle_iff_isPath_tail_and_le_length, Walk.isPath_def]
  decide
-- Ana covers Ben: none of the 512 cuts works, and Ben Ana Mon-am is a 3-line cycle.
example : (Finset.univ.filter (fun X : Finset (Fin 9) =>
    ∀ u v, cover.Adj u v → (u ∈ X ↔ v ∉ X))).card = 0 := by decide +kernel
example : coverLoop.IsCycle ∧ coverLoop.length = 3 := by
  refine ⟨?_, rfl⟩
  rw [Walk.isCycle_iff_isPath_tail_and_le_length, Walk.isPath_def]
  decide
-- The metro map: 2 of the 64 cuts work, and A C E against B D F is one of them.
example : (Finset.univ.filter (fun X : Finset (Fin 6) =>
    ∀ u v, metro.Adj u v → (u ∈ X ↔ v ∉ X))).card = 2 := by decide +kernel
example : IsTwoSideCut metro {0, 2, 4} {1, 3, 5} := by
  refine ⟨?_, ?_, ?_⟩
  · ext x
    simp only [Set.mem_union, Set.mem_insert_iff, Set.mem_singleton_iff, Set.mem_univ, iff_true]
    revert x
    decide
  · rw [Set.disjoint_left]
    simp only [Set.mem_insert_iff, Set.mem_singleton_iff]
    decide
  · simp only [Set.mem_insert_iff, Set.mem_singleton_iff]
    decide

#print axioms bip_bypass_length_mod_two
#print axioms bip_even_of_no_odd_cycle
#print axioms bip_walk_parity
#print axioms bip_dist_eq_of_potential
#print axioms two_sides_iff_no_odd_cycle
#print axioms distance_parity_colours_are_the_sides
#print axioms side_by_side_cuts_iff_both_cut
```

</details>

**Checked 2026-11-11 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'bip_bypass_length_mod_two' depends on axioms: [propext, Classical.choice, Quot.sound]
'bip_even_of_no_odd_cycle' depends on axioms: [propext, Classical.choice, Quot.sound]
'bip_walk_parity' depends on axioms: [propext, Classical.choice, Quot.sound]
'bip_dist_eq_of_potential' depends on axioms: [propext, Classical.choice, Quot.sound]
'two_sides_iff_no_odd_cycle' depends on axioms: [propext, Classical.choice, Quot.sound]
'distance_parity_colours_are_the_sides' depends on axioms: [propext, Classical.choice, Quot.sound]
'side_by_side_cuts_iff_both_cut' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **Give Eve a second shift.** Add `(4, 8)`: 10 lines, working cuts still 2 of 512, nothing inside a side.
> - **Make the ring even.** Give the cafes a sixth rival and a six-line ring: the clash vanishes and 2 of 64 cuts work, the heaps Bean Drip Latte against the rest. Even rings cut, odd rings never do; the certificate assert then stops the run.
> - **Spoil the metro map.** Add `(0, 2)`, joining A and C, which share a heap: working cuts fall from 2 to 0, and the clash on B-C rebuilds the 3-line loop B A C.

---

## The usual mistake

> [!warning]
> **Taking "no triangle" for "cuts in two".** The five cafes hold no triangle — the check prints triangles 0 — and not one of the 32 cuts works. The ring of five is the obstruction, and any odd length would do.
>
> - **Stopping at the piece the search started in.** From Ana it colours the roster and never sees the cafes.
> - **Reading the clash line as the cycle.** The clash is one line; the cycle is that line plus both routes back to where they last met: 5 lines for the cafes.
> - **Calling a crossed drawing unsplittable.** Crossings on paper are not lines inside a side: K(3, 3), three dots each joined to three others, needs crossings and cuts in two ([Why some graphs cannot be drawn flat](../12-Planarity%20and%20Colouring/02-edge-bound-and-kuratowski.md)).

---

## Where you meet it in real life

- **Rosters and assignment.** Staff to shifts, lorries to depots, exams to rooms: a dot per item, a line per allowed pairing; who takes which is [Matchings](../13-Matchings%20and%20Flows/01-matchings-and-augmenting-paths.md).
- **Purchase data.** Customers one side, products the other, a line per purchase — the structure [Communities](../../14-Applied%20and%20computational/07-Network%20Science%20and%20Spectral%20Graphs/06-community-detection.md) hunts in messier networks.
- **Splitting a group in two.** Incompatible chemicals, players who must not share a team: a line per conflict, and [Colouring](../12-Planarity%20and%20Colouring/03-vertex-colouring-and-chromatic-number.md) for how many groups suffice.
- **Chessboards and dominoes.** Squares are dots, a line joins squares sharing an edge, light against dark is the cut. A domino covers one light and one dark square, so a board whose counts differ cannot be tiled.

> **Say it back**
> A graph is bipartite when its dots fall into two heaps with every line crossing between them, as staff and shifts do. Walking a line changes heap, so every closed route uses an even number of lines. It runs backwards too: colour each dot by the parity of its distance from a starting dot, and the colours are the heaps unless some line joins two of one colour. That line, plus the routes back to where they last met, is a closed route of odd length. Five cafes in a ring are the smallest case.

---

## What this builds on

- [Connected or not](04-connectivity-and-breadth-first-search.md): the search in layers, the distance $d(v)$, and the record of where each dot was reached from.
- [Even and odd](../../02-Number%20theory/01-Divisibility%20and%20Primes/02-even-and-odd.md): why a parity, once fixed, settles the question.

## Where this goes next

- [Why some graphs cannot be drawn flat](../12-Planarity%20and%20Colouring/02-edge-bound-and-kuratowski.md): no odd cycle means every loop is even, which tightens the ceiling on lines a flat drawing allows.
- [Colouring](../12-Planarity%20and%20Colouring/03-vertex-colouring-and-chromatic-number.md): three colours or more, where no clean test survives.
- [Matchings](../13-Matchings%20and%20Flows/01-matchings-and-augmenting-paths.md): pairing the sides one to one.
- [Mantel and Turan](../14-Ramsey%20and%20Extremal%2C%20in%20Outline/05-mantel-and-turan.md): how many lines a triangle-free graph carries, its record holders bipartite.
- [Communities](../../14-Applied%20and%20computational/07-Network%20Science%20and%20Spectral%20Graphs/06-community-detection.md): groups in a network where no split is clean.

This card decides whether two heaps exist; who works which shift, one each, is the matching card's question.

---

## Sources

Verified 19 Sep 2026: every link below resolves to the publisher's page.

- König, Dénes. "Über Graphen und ihre Anwendung auf Determinantentheorie und Mengenlehre." *Mathematische Annalen* 77 (1916): 453–465. [doi:10.1007/BF01456961](https://doi.org/10.1007/BF01456961). Credited with the characterisation.
- Diestel, Reinhard. *Graph Theory*, 5th ed. Springer GTM 173, 2017. [doi:10.1007/978-3-662-53622-3](https://doi.org/10.1007/978-3-662-53622-3). Section 1.6 states and proves the characterisation.
- Bondy, J. A., and U. S. R. Murty. *Graph Theory*. Springer, 2008. [doi:10.1007/978-1-84628-970-5](https://doi.org/10.1007/978-1-84628-970-5). The spanning-tree route of Step 3.
- Levin, Oscar. *Discrete Mathematics: An Open Introduction*, 3rd ed. [Colouring section, free and complete](https://discrete.openmathbooks.org/dmoi3/sec_coloring.html). The colouring side, with exercises.
