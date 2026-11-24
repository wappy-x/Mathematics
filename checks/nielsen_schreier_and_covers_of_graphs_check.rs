// Nielsen-Schreier -- the same check as the Python, in Rust.  No crates.
// The free group on a, b; A and B are the same loops run backwards.  A subgroup
// H is given only by a membership test.  Road 1 enumerates the cosets H w as a
// covering graph, grows a spanning tree, and reads a basis off the other edges.
// Road 2 rewrites every short word of H in that basis and tests freeness.
// The rank is then one count read three ways: by edges, by Schreier's formula, by Euler.
use std::collections::{BTreeMap, BTreeSet};

type Graph = (Vec<String>, BTreeMap<(usize, char), usize>, BTreeSet<(usize, char)>);

fn inv(c: char) -> char { if c.is_lowercase() { c.to_ascii_uppercase() } else { c.to_ascii_lowercase() } }

fn reduce(w: &str) -> String {                     // cancel neighbouring pairs such as aA
    let mut out: Vec<char> = Vec::new();
    for c in w.chars() {
        if out.last() == Some(&inv(c)) { out.pop(); } else { out.push(c); }
    }
    out.into_iter().collect()
}

fn inverse(w: &str) -> String { w.chars().rev().map(inv).collect() }
fn count(w: &str, c: char) -> i64 { w.chars().filter(|&d| d == c).count() as i64 }
fn even(w: &str) -> bool { w.len() % 2 == 0 }      // the card's subgroup: even length
fn turns3(w: &str) -> bool {                       // net turns, both posts, a multiple of 3
    (count(w, 'a') + count(w, 'b') - count(w, 'A') - count(w, 'B')).rem_euclid(3) == 0
}
fn net_zero(w: &str) -> bool { count(w, 'a') == count(w, 'A') && count(w, 'b') == count(w, 'B') }

fn coset_graph(member: fn(&str) -> bool, cap: usize) -> Graph {   // road 1: cosets H w
    let (mut reps, mut out, mut tree, mut i) = (vec![String::new()], BTreeMap::new(), BTreeSet::new(), 0);
    while i < reps.len() && reps.len() <= cap {
        for x in ['a', 'b'] {
            let w = reduce(&format!("{}{}", reps[i], x));   // same coset as r when w r^-1 is in H
            let found = reps.iter().position(|r| member(&reduce(&format!("{}{}", w, inverse(r)))));
            let j = match found {
                Some(j) => j,
                None => { reps.push(w); tree.insert((i, x)); reps.len() - 1 }
            };
            out.insert((i, x), j);
        }
        i += 1;
    }
    (reps, out, tree)
}

fn basis(g: &Graph) -> Vec<(usize, char, usize, String)> {        // one loop per non-tree edge
    let (reps, out, tree) = g;
    let mut b = Vec::new();
    for x in ['a', 'b'] {
        for u in 0..reps.len() {
            if tree.contains(&(u, x)) { continue }
            let v = out[&(u, x)];
            b.push((u, x, v, reduce(&format!("{}{}{}", reps[u], x, inverse(&reps[v])))));
        }
    }
    b
}

fn reduced_words(alphabet: &str, n: usize) -> Vec<String> {      // every reduced word, length 0 to n
    let (mut words, mut layer) = (vec![String::new()], vec![String::new()]);
    for _ in 0..n {
        let mut next = Vec::new();
        for w in &layer {
            for c in alphabet.chars() {
                if w.chars().last() != Some(inv(c)) { next.push(format!("{}{}", w, c)) }
            }
        }
        words.extend(next.iter().cloned());
        layer = next;
    }
    words
}

fn show(w: &str) -> String { if w.is_empty() { "1".to_string() } else { w.to_string() } }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }

fn main() {
    let g = coset_graph(even, 60);
    let (reps, out, tree) = (&g.0, &g.1, &g.2);
    let (k, v_n, e_n) = (reps.len(), reps.len() as i64, out.len() as i64);
    let b = basis(&g);
    let mut names: BTreeMap<(usize, char), char> = BTreeMap::new();
    let mut meaning: BTreeMap<char, String> = BTreeMap::new();
    for (i, (u, x, _, w)) in b.iter().enumerate() {
        let n = ['x', 'y', 'z'][i];
        names.insert((*u, *x), n);
        meaning.insert(n, w.clone());
    }
    let rewrite = |w: &str| -> (usize, String) {   // road 2: walk w, note each non-tree edge
        let (mut v, mut word) = (0usize, String::new());
        for c in w.chars() {
            if c == 'a' || c == 'b' {
                if let Some(n) = names.get(&(v, c)) { word.push(*n) }
                v = out[&(v, c)];
            } else {
                let u = (0..k).find(|&u| out[&(u, inv(c))] == v).unwrap();
                if let Some(n) = names.get(&(u, inv(c))) { word.push(inv(*n)) }
                v = u;
            }
        }
        (v, word)
    };
    let expand = |word: &str| -> String {
        reduce(&word.chars().map(|c| match meaning.get(&c) {
            Some(m) => m.clone(),
            None => inverse(&meaning[&inv(c)]),
        }).collect::<String>())
    };
    println!("subgroup H: reduced words of even length in a, b (A, B: a, b run backwards)");
    println!("cosets found by enumeration: {}, representatives {}", k,
             reps.iter().map(|r| show(r)).collect::<Vec<_>>().join(", "));
    for (u, x) in tree.iter() { println!("edge {} -{}-> {}: spanning tree", u, x, out[&(*u, *x)]) }
    for (u, x, v, w) in &b {
        println!("edge {} -{}-> {}: loop {}.{}.{} = {}, named {}", u, x, v, show(&reps[*u]), x,
                 show(&inverse(&reps[*v])), w, names[&(*u, *x)]);
    }
    let cover = (0..k).all(|v| ['a', 'b'].iter().all(|&x| (0..k).filter(|&u| out[&(u, x)] == v).count() == 1));
    println!("one a-edge and one b-edge out of and into every vertex (a cover): {}", yn(cover));
    println!("each basis loop lies in H: {}", yn(b.iter().all(|t| even(&t.3))));
    let b2: Vec<String> = basis(&(vec![String::new(), "b".to_string()], out.clone(), [(0, 'b')].into_iter().collect())).into_iter().map(|t| t.3).collect(); // tree: b-edge 0 -> 1
    println!("another spanning tree, the b-edge from 0 to 1: basis {}, again {} words", b2.join(", "), b2.len());
    let chi = v_n - e_n;
    let ki = k as i64;
    println!("rank three ways: E - V + 1 = {} - {} + 1 = {}; Schreier 1 + {} x (2 - 1) = {}; Euler chi = {} x (1 - 2) = {}, rank 1 - chi = {}",
             e_n, v_n, e_n - v_n + 1, k, 1 + ki * (2 - 1), k, chi, 1 - chi);
    for w in ["bb", "ba", "abab"] {
        let (end, word) = rewrite(w);
        println!("rewrite {}: path ends at vertex {}, crosses {}; expands back to {}", w, end, word, expand(&word));
    }
    let f = reduced_words("abAB", 6);
    let ok = f.iter().filter(|w| even(w) && { let (e, r) = rewrite(w); e == 0 && expand(&r) == **w }).count();
    let closes = f.iter().all(|w| (rewrite(w).0 == 0) == even(w));
    println!("reduced words up to length 6: {}; walk closes exactly for the even ones: {}", f.len(), yn(closes));
    println!("even ones rewritten in x, y, z and expanded back unchanged: {} of {}", ok,
             f.iter().filter(|w| even(w)).count());
    let gw = reduced_words("xyzXYZ", 4);
    let images: BTreeSet<String> = gw.iter().map(|w| expand(w)).collect();
    let trivial: Vec<&String> = gw.iter().filter(|w| expand(w).is_empty()).collect();
    println!("reduced words in x, y, z up to length 4: {}; distinct words in a, b they expand to: {}; only the empty word gives 1: {}",
             gw.len(), images.len(), yn(trivial.len() == 1 && trivial[0].is_empty()));
    let g3 = coset_graph(turns3, 60);
    let b3: Vec<String> = basis(&g3).into_iter().map(|t| t.3).collect();
    let (k3, e3) = (g3.0.len() as i64, g3.1.len() as i64);
    println!("second subgroup, net turns a multiple of 3: index {}, basis {}", k3, b3.join(", "));
    println!("  rank: E - V + 1 = {} - {} + 1 = {}; Schreier 1 + {} x (2 - 1) = {}", e3, k3, e3 - k3 + 1, k3, 1 + k3);
    println!("figure, vertex 0 at (330, 120), vertex 1 at (490, 120), tree edge a from 0 to 1, base eight at (120, 120)");
    println!("mistake 1, keep the tree edge as a generator: its loop 1.a.A = {}, the empty word",
             show(&reduce(&format!("a{}", inverse(&reps[1])))));
    println!("mistake 2, edges minus vertices with no + 1: {} - {} = {}, true rank {}", e_n, v_n, e_n - v_n, e_n - v_n + 1);
    let gc = coset_graph(net_zero, 60);
    let pt: Vec<(i64, i64)> = gc.0.iter().map(|r| (count(r, 'a') - count(r, 'A'), count(r, 'b') - count(r, 'B'))).collect(); // (net a, net b)
    let grid = pt.iter().collect::<BTreeSet<_>>().len() == pt.len() && gc.1.iter().all(|(&(i, x), &j)| pt[j] == (pt[i].0 + (x == 'a') as i64, pt[i].1 + (x == 'b') as i64));
    let boxes: Vec<i64> = (2..6i64).map(|n| { let inb = |v: usize| (0..n).contains(&pt[v].0) && (0..n).contains(&pt[v].1);
        gc.1.iter().filter(|(&(i, _), &j)| inb(i) && inb(j)).count() as i64 - (0..pt.len()).filter(|&v| inb(v)).count() as i64 + 1 }).collect(); // edges - vertices + 1
    println!("mistake 3, infinite index (net turns 0 round each post): cosets still growing at {}; each is a grid point (net a, net b), each arrow one step: {}; n by n boxes of it, n = 2 to 5, hold {:?} loops",
             gc.0.len(), yn(grid), boxes);
    let vec = |w: &str| (count(w, 'a') - count(w, 'A'), count(w, 'b') - count(w, 'B'));
    let (vx, vy, vz) = (vec("aa"), vec("bA"), vec("ab"));
    let rel = vx.0 == vz.0 - vy.0 && vx.1 == vz.1 - vy.1;
    println!("mistake 4, the torus group Z x Z: x, y, z become {:?}, {:?}, {:?}, and x = z - y there: {}; in F2, x = z y^-1 reads {}, not aa",
             vx, vy, vz, yn(rel), expand("zY"));
    assert!(k == 2 && b.iter().map(|t| t.3.as_str()).collect::<Vec<_>>() == ["aa", "bA", "ab"] && b2 == ["aB", "ba", "bb"]); // by hand
    assert!(b.len() as i64 == 1 + ki * (2 - 1) && b.len() == 3);   // the verified basis has Schreier's count
    assert!(closes && ok == 1 + 12 + 108 + 972);                   // generates H, 1093 words
    assert!(images.len() == gw.len() && gw.len() == 1 + 6 + 30 + 150 + 750);   // no hidden relation
    assert!(b3 == ["aaa", "bA", "abAA", "aab"] && gc.0.len() > 60);
    assert!(grid && boxes == [1, 4, 9, 16] && rel && expand("zY") != "aa");
    println!("ALL CHECKS PASS");
}
