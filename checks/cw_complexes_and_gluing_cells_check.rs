// CW complexes -- the same check as the Python, in Rust.  No crates.
// A complex is a recipe: vertices, edges (name: tail, head) and 2-cells, each
// 2-cell the word read round its rim.  Lower case runs an edge forwards and the
// capital runs it backwards, so A is a^-1.  Road 1 reads the loop group off the
// recipe: a spanning tree of edges is shrunk, the other edges are generators and
// each 2-cell gives one relation.  Road 2 lifts every short loop to a cover where
// a loop shrinks only if its lift closes up: the square grid for the torus, the
// branching tree for the figure eight.  The closed lifts are counted against
// formulas.  Chi is counted from the cells and, separately, from triangles.
use std::collections::BTreeSet;

struct Cx { v: Vec<&'static str>, e: Vec<(char, &'static str, &'static str)>, f: Vec<&'static str>, c3: i64 }

fn chi(x: &Cx) -> i64 { x.v.len() as i64 - x.e.len() as i64 + x.f.len() as i64 - x.c3 }   // + - + -

fn find(boss: &[usize], x: usize) -> usize { if boss[x] == x { x } else { find(boss, boss[x]) } }

fn presentation(x: &Cx) -> (Vec<char>, Vec<String>) {     // road 1: shrink a spanning tree
    let mut boss: Vec<usize> = (0..x.v.len()).collect();
    let ix = |n: &str| x.v.iter().position(|&w| w == n).unwrap();
    let mut gens = vec![];
    for &(name, tail, head) in &x.e {
        let (t, h) = (find(&boss, ix(tail)), find(&boss, ix(head)));
        if t == h { gens.push(name) } else { boss[t] = h }  // a generator, or a tree edge
    }
    let rels = x.f.iter().map(|w| w.chars().filter(|c| gens.contains(&c.to_ascii_lowercase())).collect()).collect();
    (gens, rels)
}

fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }

fn det(m: &[Vec<i64>]) -> i64 {                            // whole-number determinant, by rows
    if m.is_empty() { return 1 }
    (0..m.len()).filter(|&j| m[0][j] != 0).map(|j| {
        let minor: Vec<Vec<i64>> = m[1..].iter().map(|r| r.iter().enumerate().filter(|&(c, _)| c != j).map(|(_, &x)| x).collect()).collect();
        (if j % 2 == 0 { 1 } else { -1 }) * m[0][j] * det(&minor)
    }).sum()
}

fn combos(n: usize, k: usize) -> Vec<Vec<usize>> {         // k-element subsets of 0..n, in order
    if k == 0 { return vec![vec![]] }
    (0..n).flat_map(|i| combos(n, k - 1).into_iter().filter(move |c| c.iter().all(|&x| x < i)).map(move |mut c| { c.push(i); c })).collect()
}

fn count(w: &str, c: char) -> i64 { w.chars().filter(|&x| x == c).count() as i64 }

fn abelianised(gens: &[char], rels: &[String]) -> (usize, Vec<i64>) {   // rank and torsion, from gcds of minors
    let m: Vec<Vec<i64>> = rels.iter().map(|w| gens.iter().map(|&g| count(w, g) - count(w, g.to_ascii_uppercase())).collect()).collect();
    let (mut d, mut inv) = (vec![1i64], vec![]);
    for k in 1..=m.len().min(gens.len()) {
        let mut g = 0;
        for rows in combos(m.len(), k) {
            for cols in combos(gens.len(), k) {
                g = gcd(g, det(&rows.iter().map(|&r| cols.iter().map(|&c| m[r][c]).collect()).collect::<Vec<_>>()));
            }
        }
        if g == 0 { break }
        inv.push(g / d[d.len() - 1]);
        d.push(g);
    }
    (gens.len() - inv.len(), inv.into_iter().filter(|&t| t > 1).collect())
}

fn show(label: &str, x: &Cx) -> String {
    let (gens, rels) = presentation(x);
    let (rank, tors) = abelianised(&gens, &rels);
    let mut rel = rels.iter().map(|r| if r.is_empty() { "1".to_string() } else { r.clone() }).collect::<Vec<_>>().join(", ");
    if rel.is_empty() { rel = "no relations".to_string() }
    let g = gens.iter().map(|c| c.to_string()).collect::<Vec<_>>().join(", ");
    format!("{}: cells {}, {}, {}, {}; chi {}; pi1 = <{} | {}>; abelianised rank {}, torsion {:?}",
            label, x.v.len(), x.e.len(), x.f.len(), x.c3, chi(x), g, rel, rank, tors)
}

fn inv(c: char) -> char { if c.is_ascii_lowercase() { c.to_ascii_uppercase() } else { c.to_ascii_lowercase() } }

fn free_reduce(w: &str) -> String {                        // lift to the tree: cancel aA, Bb, ...
    let mut out: Vec<char> = vec![];
    for c in w.chars() { if out.last() == Some(&inv(c)) { out.pop(); } else { out.push(c) } }
    out.into_iter().collect()
}

fn grid_end(w: &str) -> (i64, i64) { (count(w, 'a') - count(w, 'A'), count(w, 'b') - count(w, 'B')) }

fn tree_closed(n: usize) -> i64 {                          // closed walks on the 4-branch tree, by depth
    let mut ways = vec![0i64; n + 1];
    ways[0] = 1;
    for _ in 0..n {
        let mut nw = vec![ways[1]];
        for d in 1..=n { nw.push(ways[d - 1] * if d == 1 { 4 } else { 3 } + if d < n { ways[d + 1] } else { 0 }) }
        ways = nw;
    }
    ways[0]
}

fn comb(n: i64, k: i64) -> i64 { (1..=k).fold(1, |acc, i| acc * (n - k + i) / i) }

fn main() {
    let lp = |n: char| (n, "v", "v");
    let one = || vec!["v"];
    let circle1 = Cx { v: one(), e: vec![lp('a')], f: vec![], c3: 0 };
    let circle2 = Cx { v: vec!["v", "w"], e: vec![('p', "v", "w"), ('q', "w", "v")], f: vec![], c3: 0 };
    let eight = Cx { v: one(), e: vec![lp('a'), lp('b')], f: vec![], c3: 0 };
    let torus = Cx { v: one(), e: vec![lp('a'), lp('b')], f: vec!["abAB"], c3: 0 };
    let sphere1 = Cx { v: one(), e: vec![], f: vec![""], c3: 0 };
    let sphere2 = Cx { v: vec!["n", "s"], e: vec![('p', "n", "s"), ('q', "n", "s")], f: vec!["pQ", "qP"], c3: 0 };
    let ball = Cx { v: one(), e: vec![], f: vec![""], c3: 1 };
    let klein = Cx { v: one(), e: vec![lp('a'), lp('b')], f: vec!["abAb"], c3: 0 };
    let rp2 = Cx { v: one(), e: vec![lp('a')], f: vec!["aa"], c3: 0 };
    let bx = Cx { v: one(), e: vec![lp('a'), lp('b'), lp('c')], f: vec!["abAB", "acAC", "bcBC"], c3: 1 };
    let twist = Cx { v: one(), e: vec![lp('a'), lp('b')], f: vec!["aabb", "aaBB"], c3: 0 };  // two torsion numbers: tests 2 x 2 minors
    for (label, x) in [("circle, 1 vertex + 1 edge", &circle1), ("circle, 2 vertices + 2 edges", &circle2),
                       ("figure eight, 1 vertex + 2 edges", &eight), ("torus, 1 vertex + 2 edges + 1 square", &torus),
                       ("sphere, 1 vertex + 1 disc", &sphere1), ("sphere, 2 vertices + 2 edges + 2 discs", &sphere2),
                       ("ball, sphere + 1 solid ball", &ball), ("klein bottle, square abAb", &klein),
                       ("projective plane, disc aa", &rp2), ("3-torus box, 1 + 3 + 3 + 1 cells", &bx),
                       ("two discs, rims aabb and aaBB", &twist)] {
        println!("{}", show(label, x));
    }
    let mut tor_tri: BTreeSet<Vec<usize>> = BTreeSet::new();
    for i in 0..3 { for j in 0..3 {
        let (i1, j1) = ((i + 1) % 3, (j + 1) % 3);
        for mut t in [vec![3 * i + j, 3 * i1 + j, 3 * i1 + j1], vec![3 * i + j, 3 * i + j1, 3 * i1 + j1]] { t.sort(); tor_tri.insert(t); }
    } }
    let edges_of = |tris: &Vec<Vec<usize>>| tris.iter().flat_map(|t| [(t[0], t[1]), (t[0], t[2]), (t[1], t[2])]).collect::<BTreeSet<_>>().len() as i64;
    let tor: Vec<Vec<usize>> = tor_tri.into_iter().collect();
    let tet: Vec<Vec<usize>> = combos(4, 3);
    let (te, ke) = (edges_of(&tor), edges_of(&tet));
    let (chi_tor, chi_tet) = (9 - te + tor.len() as i64, 4 - ke + tet.len() as i64);
    println!("chi from triangles: torus 9 - {} + {} = {}; sphere 4 - {} + {} = {}", te, tor.len(), chi_tor, ke, tet.len(), chi_tet);
    println!("loops of length n that shrink to a point (road 2, every word of n letters):");
    let mut counts = vec![];
    for n in [2usize, 4, 6] {
        let mut words = vec![String::new()];
        for _ in 0..n { words = words.iter().flat_map(|w| "aAbB".chars().map(move |c| format!("{}{}", w, c))).collect() }
        let t: BTreeSet<String> = words.iter().filter(|w| grid_end(w) == (0, 0)).cloned().collect();
        let e: BTreeSet<String> = words.iter().filter(|w| free_reduce(w).is_empty()).cloned().collect();
        let h = (n / 2) as i64;
        println!("  n {}: of {} words, torus {} (formula C({},{})^2 = {}), figure eight {} (tree walk {})",
                 n, words.len(), t.len(), n, h, comb(n as i64, h).pow(2), e.len(), tree_closed(n));
        counts.push((n, t.len() as i64, e.len() as i64, t.difference(&e).cloned().collect::<Vec<String>>()));
    }
    println!("  checked on {} words", counts.iter().map(|c| 4i64.pow(c.0 as u32)).sum::<i64>());
    let extra = counts[1].3.clone();
    let rims: Vec<String> = ["abAB", "baBA"].iter().flat_map(|r| (0..4).map(move |i| format!("{}{}", &r[i..], &r[..i]))).collect::<BTreeSet<_>>().into_iter().collect();
    println!("length 4, closed on the torus only: {} words: {}", extra.len(), extra.join(" "));
    println!("  the square's rim abAB read from each corner, either way round: {}", if extra == rims { "yes" } else { "no" });
    let plan = "aaaBB";
    println!("arm plan abAB: torus lift ends at {:?}, so it shrinks to staying at home", grid_end("abAB"));
    println!("arm plan {}: torus lift ends at {:?}, so shoulder 3 turns, elbow -2 turns", plan, grid_end(plan));
    let gens2: Vec<char> = circle2.e.iter().map(|e| e.0).collect();
    let (kg, kr) = presentation(&klein);
    let ka = abelianised(&kg, &kr);
    println!("mistake 1, square left out: abAB on the figure eight reduces to {}, not 1", free_reduce("abAB"));
    println!("mistake 2, every edge a generator on the 2-vertex circle: rank {}, not 1", abelianised(&gens2, &[]).0);
    println!("mistake 3, square read abAb (one arrow flipped): rank {}, torsion {:?}", ka.0, ka.1);
    println!("mistake 4, torus cells counted without signs: 1 + 2 + 1 = {}, not {}", torus.v.len() + torus.e.len() + torus.f.len(), chi(&torus));
    println!("figure, schematic square side 200 at (40, 40); grid unit 40, origin (330, 200); abAB corners (0, 0) (1, 0) (1, 1) (0, 1); {} ends {:?}", plan, grid_end(plan));
    assert!([&circle1, &circle2, &torus, &sphere1, &sphere2, &ball, &bx].iter().map(|x| chi(x)).collect::<Vec<_>>() == vec![0, 0, 0, 2, 2, 1, 0]);
    assert!(chi(&torus) == chi_tor && chi(&sphere1) == chi_tet);                   // cells against triangles
    assert!(counts.iter().all(|c| c.1 == comb(c.0 as i64, c.0 as i64 / 2).pow(2) && c.2 == tree_closed(c.0)));
    assert!(extra == rims && free_reduce("abAB") == "abAB" && grid_end("abAB") == (0, 0));
    assert!(presentation(&circle2) == (vec!['q'], vec![]) && presentation(&sphere2) == (vec!['q'], vec!["Q".to_string(), "q".to_string()]));
    let ab: Vec<(usize, Vec<i64>)> = [&circle2, &torus, &sphere2, &klein, &rp2, &bx, &twist].iter().map(|x| { let (g, r) = presentation(x); abelianised(&g, &r) }).collect();
    assert!(ab == vec![(1, vec![]), (2, vec![]), (0, vec![]), (1, vec![2]), (0, vec![2]), (3, vec![]), (0, vec![2, 4])]);
    println!("ALL CHECKS PASS");
}
