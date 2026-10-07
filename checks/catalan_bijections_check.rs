// Catalan bijections -- the same check as the Python, in Rust.  No crates.  At size 4 five families are counted
// separately, each by its own rule: 8-step paths that never dip, bracket words that cancel away, plane binary
// trees, cuttings of a hexagon, handshakes among 8 with no arms crossing.  The recipes then carry each across.
#[derive(Clone)] enum T { Leaf, Fork(Box<T>, Box<T>) }
type P = (usize, usize);
fn dips(w: &str) -> bool { let (mut h, mut lo) = (0i32, 0i32); for c in w.bytes() { h += if c == b'(' { 1 } else { -1 }; if h < lo { lo = h } } lo < 0 }
fn cancels(w: &str) -> bool { let mut w = w.to_string(); while let Some(i) = w.find("()") { w.replace_range(i..i + 2, "") } w.is_empty() }
fn cross(p: P, q: P) -> bool { (p.0 < q.0 && q.0 < p.1 && p.1 < q.1) || (q.0 < p.0 && p.0 < q.1 && q.1 < p.1) }
fn untree(t: &T) -> String { match t { T::Leaf => String::new(), T::Fork(l, r) => format!("({}){}", untree(l), untree(r)) } }
fn fold(t: &T) -> String { match t { T::Leaf => ".".to_string(), T::Fork(l, r) => { let (a, b) = (fold(l), fold(r)); if a <= b { format!("({}{})", a, b) } else { format!("({}{})", b, a) } } } }
fn shakeword(p: &[P], k: usize) -> String { (0..k).map(|i| if p.iter().any(|&(a, _)| a == i) { '(' } else { ')' }).collect() }
fn fact(j: u64) -> u64 { if j == 0 { 1 } else { j * fact(j - 1) } }
fn cat(j: u64) -> u64 { fact(2 * j) / (fact(j) * fact(j)) / (j + 1) }
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
fn sorted(mut v: Vec<String>) -> Vec<String> { v.sort(); v }
fn grow(n: usize) -> Vec<T> {                  // rule three: plane binary trees, grown as trees
    if n == 0 { return vec![T::Leaf] }         // a fork for every split of n - 1 between the two branches
    let mut out = Vec::new();
    for i in 0..n { for l in grow(i) { for r in grow(n - 1 - i) { out.push(T::Fork(Box::new(l.clone()), Box::new(r))) } } } out
}
fn tree(w: &str) -> T {                        // a bracket word -> a tree, cut at the first return
    if w.is_empty() { return T::Leaf }         let (b, mut h, mut i) = (w.as_bytes(), 0i32, 0usize);
    for j in 0..b.len() { h += if b[j] == b'(' { 1 } else { -1 }; if h == 0 { i = j; break } }
    T::Fork(Box::new(tree(&w[1..i])), Box::new(tree(&w[i + 1..])))
}
fn cuttings(m: usize) -> Vec<Vec<P>> {         // rule four: sets of m-3 diagonals, none crossing
    let ds: Vec<P> = (0..m).flat_map(|a| (a + 2..m).map(move |b| (a, b))).filter(|&d| d != (0, m - 1)).collect();
    (0..(1u32 << ds.len())).map(|j| (0..ds.len()).filter(|i| j >> i & 1 == 1).map(|i| ds[i]).collect::<Vec<P>>())
        .filter(|p| p.len() == m - 3 && !p.iter().any(|&x| p.iter().any(|&y| cross(x, y)))).collect()
}
fn apex(cut: &[P], m: usize, a: usize, b: usize) -> usize {     // the corner the triangle on edge a-b points at
    let side = |p: usize, q: usize| q == p + 1 || cut.contains(&(p, q)) || (p, q) == (0, m - 1);
    (a + 1..b).find(|&c| side(a, c) && side(c, b)).unwrap()
}
fn cutword(cut: &[P], m: usize, a: usize, b: usize) -> String {  // one piece of the cut polygon, read as brackets
    if b == a + 1 { return String::new() }
    let c = apex(cut, m, a, b); format!("({}){}", cutword(cut, m, a, c), cutword(cut, m, c, b))
}
fn pairings(s: &[usize]) -> Vec<Vec<P>> {      // rule five: every pairing of the seats, crossings and all
    if s.is_empty() { return vec![Vec::new()] }  let mut out = Vec::new();   // the lowest free seat takes each partner
    for i in 1..s.len() { let mut rest = s[1..i].to_vec(); rest.extend_from_slice(&s[i + 1..]);
        for mut r in pairings(&rest) { r.insert(0, (s[0], s[i])); out.push(r) } }
    out
}
fn census(n: usize) -> (Vec<String>, Vec<String>, usize, Vec<T>, Vec<Vec<P>>, Vec<Vec<P>>) {
    let ws: Vec<String> = (0..(1u32 << (2 * n))).map(|j| (0..2 * n).map(|i| if j >> i & 1 == 1 { ')' } else { '(' }).collect()).collect();
    let level: Vec<String> = ws.iter().filter(|w| w.matches('(').count() == n).cloned().collect();
    let sh: Vec<Vec<P>> = pairings(&(0..2 * n).collect::<Vec<usize>>()).into_iter().filter(|p| !p.iter().any(|&x| p.iter().any(|&y| cross(x, y)))).collect();
    (level.clone(), level.iter().filter(|w| !dips(w)).cloned().collect(), ws.iter().filter(|w| cancels(w)).count(), grow(n), cuttings(n + 2), sh)
}
fn main() {
    let (level, dyck, brack, forest, cuts, shakes) = census(4);
    let (l5, d5, b5, f5, c5, s5) = census(5);  // the second worked case, at five pairs
    let (fan, nest): (Vec<P>, Vec<P>) = (vec![(0, 2), (0, 3), (0, 4)], vec![(0, 7), (1, 6), (2, 5), (3, 4)]);
    let (cw, sw) = (sorted(cuts.iter().map(|c| cutword(c, 6, 0, 5)).collect()), sorted(shakes.iter().map(|p| shakeword(p, 8)).collect()));
    let (back, ds) = (sorted(forest.iter().map(untree).collect()), sorted(dyck.clone()));
    let (byapex, prods): (Vec<u64>, Vec<u64>) = ((1..=4).map(|j| cuts.iter().filter(|c| apex(c, 6, 0, 5) == j).count() as u64).collect(), (0..4u64).map(|i| cat(i) * cat(3 - i)).collect());
    let mut shapes = sorted(forest.iter().map(fold).collect()); shapes.dedup();
    println!("size 4: a hexagon, corners 0 to 5, base edge 0-5, 3 diagonals, 4 triangles; 8 seats; 8 steps");
    println!("words of 8 marks with 4 opens: {}; of those, never dipping below the start: {}", level.len(), dyck.len());
    println!("each family by its own rule -- paths {}, words that cancel away {}, trees {}, cuttings {}, handshakes {}; \
and by the closed form, {} divided by 4 + 1 = {}", dyck.len(), brack, forest.len(), cuts.len(), shakes.len(), level.len(), cat(4));
    println!("the {} bracket words in order: {}", cat(4), ds.join(" "));
    println!("word -> tree -> word returns every one of them: {}; the {} grown trees give back those same {} words: {}; \
the fan cut from corner 0, diagonals {:?}, reads {}, and so do the nested handshakes {:?}: {}", yn(dyck.iter().all(|w| untree(&tree(w)) == *w)),
             forest.len(), cat(4), yn(back == ds), fan, cutword(&fan, 6, 0, 5), nest, yn(shakeword(&nest, 8) == cutword(&fan, 6, 0, 5)));
    println!("every cutting's word, and every handshake's word, lands on all {}, one apiece: {} and {}", cat(4), yn(cw == ds), yn(sw == ds));
    println!("the {} cuttings by the corner the base triangle points at (1, 2, 3, 4): {:?}; Cat(i) x Cat(3-i): {:?}", cat(4), byapex, prods);
    println!("at size 5, the shelf's 10-step paths: {} words come back level, {} never dip, and paths, words, trees, \
cuttings of a 7-gon, handshakes among 10 count {}, {}, {}, {}, {}", l5.len(), d5.len(), d5.len(), b5, f5.len(), c5.len(), s5.len());
    println!("mistake 1, a hexagon read as size 6: {}, not {}; mistake 2, arms allowed to cross: {} pairings of 8 people, not {}",
             cat(6), cat(4), pairings(&(0..8).collect::<Vec<usize>>()).len(), shakes.len());
    println!("mistake 3, both branches of every fork swapped freely: {} shapes, not {}; mistake 4, every word with 4 opens, \
dips included: {}, not {}", shapes.len(), forest.len(), level.len(), dyck.len());
    assert!(dyck.len() == brack && brack == forest.len() && forest.len() == cuts.len() && cuts.len() == shakes.len() && shakes.len() as u64 == cat(4) && level.len() as u64 == fact(8) / (fact(4) * fact(4)));
    assert!(cw == ds && sw == ds && back == ds && dyck.iter().all(|w| untree(&tree(w)) == *w));
    assert!(cuts.contains(&fan) && shakes.contains(&nest) && cutword(&fan, 6, 0, 5) == shakeword(&nest, 8) && pairings(&(0..8).collect::<Vec<usize>>()).iter().all(|p| ds.contains(&shakeword(p, 8))));
    assert!(byapex == prods && d5.len() == b5 && b5 == f5.len() && f5.len() == c5.len() && c5.len() == s5.len() && s5.len() as u64 == cat(5));
    println!("ALL CHECKS PASS");
}
