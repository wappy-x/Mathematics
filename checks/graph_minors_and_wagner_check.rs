// Graph minors and Wagner's theorem -- the same check as the Python, in Rust.  No crates.  Road one counts:
// a flat drawing with no ring shorter than g has E <= g(V - 2)/(g - 2).  Road two contracts Petersen's five
// spokes by hand.  Road three knows no theory: it tries every split of the dots into connected branch sets.
use std::collections::BTreeSet;
type Edges = Vec<(usize, usize)>;
fn adj(n: usize, es: &[(usize, usize)]) -> Vec<BTreeSet<usize>> {
    (0..n).map(|u| es.iter().filter(|e| e.0 == u || e.1 == u).map(|e| if e.0 == u { e.1 } else { e.0 }).collect()).collect()
}
fn complete(n: usize) -> Edges { (0..n).flat_map(|u| (u + 1..n).map(move |v| (u, v))).collect() }
fn perms(xs: &[usize]) -> Vec<Vec<usize>> {
    if xs.is_empty() { return vec![vec![]] }
    (0..xs.len()).flat_map(|i| { let mut r = xs.to_vec(); let x = r.remove(i);
        perms(&r).into_iter().map(move |p| { let mut o = vec![x]; o.extend(p); o }).collect::<Vec<_>>() }).collect()
}
fn girth(n: usize, es: &Edges) -> usize {         // shortest ring: drop a line, walk round to its ends
    es.iter().map(|&(u, v)| { let rest: Edges = es.iter().copied().filter(|&e| e != (u, v)).collect();
        let a = adj(n, &rest); let (mut dist, mut todo, mut i) = (vec![usize::MAX; n], vec![u], 0); dist[u] = 0;
        while i < todo.len() { let x = todo[i]; i += 1;
            for &y in &a[x] { if dist[y] == usize::MAX { dist[y] = dist[x] + 1; todo.push(y) } } }
        if dist[v] == usize::MAX { n + 1 } else { dist[v] + 1 } }).min().unwrap_or(n + 1)
}
fn fuse(lab: &[i64], es: &Edges) -> BTreeSet<(i64, i64)> {   // each set becomes one dot; loops and repeats vanish
    es.iter().map(|&(u, v)| (lab[u].min(lab[v]), lab[u].max(lab[v]))).filter(|&(a, b)| a != b && a >= 0).collect()
}
fn connected(block: &[usize], a: &[BTreeSet<usize>]) -> bool {
    let (mut seen, mut todo, mut i) = (BTreeSet::from([block[0]]), vec![block[0]], 0);
    while i < todo.len() { let x = todo[i]; i += 1;
        for &y in &a[x] { if block.contains(&y) && seen.insert(y) { todo.push(y) } } }
    seen.len() == block.len()
}
fn go(v: usize, lab: &mut Vec<i64>, used: usize, n: usize, es: &Edges, k: usize, h: &Edges, a: &[BTreeSet<usize>], ps: &[Vec<usize>], out: &mut Vec<Vec<Vec<usize>>>) {
    if n - v < k - used { return }
    if v == n {
        let blocks: Vec<Vec<usize>> = (0..k).map(|b| (0..n).filter(|&x| lab[x] == b as i64).collect()).collect();
        let q = fuse(lab, es);
        if blocks.iter().all(|b| connected(b, a)) && ps.iter().any(|p| h.iter().all(|&(x, y)| q.contains(&(p[x].min(p[y]) as i64, p[x].max(p[y]) as i64)))) {
            let mut m: Vec<Vec<usize>> = blocks.into_iter().filter(|b| b.len() > 1).collect(); m.sort(); out.push(m);
        }
        return;
    }
    for c in -1..=(used.min(k - 1) as i64) { lab.push(c); go(v + 1, lab, used.max((c + 1) as usize), n, es, k, h, a, ps, out); lab.pop(); }
}
fn models(n: usize, es: &Edges, k: usize, h: &Edges) -> Vec<Vec<Vec<usize>>> {   // road three
    let (a, ps, mut out) = (adj(n, es), perms(&(0..k).collect::<Vec<usize>>()), Vec::new());
    go(0, &mut Vec::new(), 0, n, es, k, h, &a, &ps, &mut out); out
}
fn matchings(free: &BTreeSet<usize>, a: &[BTreeSet<usize>]) -> Vec<Vec<Vec<usize>>> {   // straight from the lines
    let Some(&u) = free.iter().next() else { return vec![vec![]] };
    a[u].iter().filter(|v| free.contains(v)).flat_map(|&v| { let mut rest = free.clone(); rest.remove(&u); rest.remove(&v);
        matchings(&rest, a).into_iter().map(move |m| { let mut o = vec![vec![u, v]]; o.extend(m); o }) }).collect()
}
fn main() {
    let ring: Edges = (0..5).map(|i| (i, (i + 1) % 5)).collect();
    let pet: Edges = ring.iter().copied().chain((0..5).map(|i| (5 + i, 5 + (i + 2) % 5))).chain((0..5).map(|i| (i, 5 + i))).collect();
    let cube: Edges = (0..4).map(|i| (i, (i + 1) % 4)).chain((0..4).map(|i| (4 + i, 4 + (i + 1) % 4))).chain((0..4).map(|i| (i, 4 + i))).collect();
    let (k5, k4): (Edges, Edges) = (complete(5), complete(4)); let k33: Edges = (0..3).flat_map(|u| (3..6).map(move |v| (u, v))).collect();
    let (v, e, g) = (10usize, pet.len(), girth(10, &pet)); let spoked = fuse(&[0, 1, 2, 3, 4, 0, 1, 2, 3, 4], &pet); let nv = spoked.iter().flat_map(|&(a, b)| [a, b]).collect::<BTreeSet<i64>>().len();
    let k5set: BTreeSet<(i64, i64)> = k5.iter().map(|&(a, b)| (a as i64, b as i64)).collect();
    let (k5_pet, k33_pet) = (models(10, &pet, 5, &k5), models(10, &pet, 6, &k33));
    let mut pm = matchings(&(0..10).collect(), &adj(10, &pet)); pm.sort(); let mut k5s = k5_pet.clone(); k5s.sort();
    let cubes = [models(8, &cube, 5, &k5).len(), models(8, &cube, 6, &k33).len(), models(8, &cube, 4, &k4).len()]; let k5e: Edges = k5.iter().copied().filter(|&x| x != (3, 4)).collect();
    let big = adj(v, &pet).iter().filter(|s| s.len() >= 4).count(); let degs: BTreeSet<usize> = adj(v, &pet).iter().map(|s| s.len()).collect();
    let sizes: BTreeSet<usize> = k5_pet.iter().flat_map(|m| m.iter().map(|s| s.len())).collect(); let gb = (g * (v - 2)) as f64 / (g - 2) as f64; let yn = |b: bool| if b { "yes" } else { "no" };
    println!("Petersen: V = {}, E = {}, degrees {:?}, girth {}", v, e, degs.iter().collect::<Vec<_>>(), g);
    println!("edge ceiling 3V - 6 = {}: {} lines fit, so the count is silent", 3 * v - 6, e);
    println!("girth ceiling {}(V - 2)/{} = {:.2}: {} lines is over; {} sides fill at most {} regions, Euler needs {}", g, g - 2, gb, e, 2 * e, 2 * e / g, e - v + 2);
    println!("contract the {} spokes: V = {}, E = {}, pairs among {} dots = {}, K(5): {}", v - nv, nv, spoked.len(), nv, nv * (nv - 1) / 2, yn(spoked == k5set));
    println!("search for K(5) in Petersen: {} families, set sizes {:?}", k5_pet.len(), sizes.iter().collect::<Vec<_>>());
    println!("perfect matchings of Petersen, counted directly: {}; the same line sets: {}", pm.len(), yn(pm == k5s));
    println!("search for K(3,3) in Petersen: {} families", k33_pet.len());
    println!("cube, 8 dots and {} lines: K(5) {} families, K(3,3) {}, K(4) {}", cube.len(), cubes[0], cubes[1], cubes[2]);
    println!("mistake 1, the edge ceiling as permission: {} <= {}, yet K(5) is a minor", e, 3 * v - 6);
    println!("mistake 2, the ring-of-four ceiling 2V - 4 = {}: {} fits; girth {} gives {:.2}", 2 * v - 4, e, g, gb);
    println!("mistake 3, hunting only for K(5) with dots along its lines: {} dots of degree 4, yet {} K(3,3) families", big, k33_pet.len());
    println!("mistake 4, closure read backwards: K(5) minus one line has {} K(5) and {} K(3,3) families, so it is flat", models(5, &k5e, 5, &k5).len(), models(5, &k5e, 6, &k33).len());
    assert!(g == 5 && e as f64 > gb && e <= 3 * v - 6);                    // counting: silent, then decisive
    assert!(spoked == k5set && k5_pet.len() == 6 && pm.len() == 6 && pm == k5s);   // three roads, one K(5)
    assert!(big == 0 && !k33_pet.is_empty() && cubes[0] == 0 && cubes[1] == 0 && cubes[2] > 0);   // Petersen fails, cube passes
    println!("ALL CHECKS PASS");
}
