// Conjugacy and the class equation -- the same check as the Python, in Rust.  No crates.  A group
// is its members and a rule combining two, b first.  Tile move r_k sends position i to i + k, r_kf
// to k - i, wrapped at 4.  Road one conjugates; road two counts what commutes (orbit-stabiliser).
type M = Vec<i64>;
type Mul = fn(&M, &M) -> M;
fn perm(a: &M, b: &M) -> M { b.iter().map(|&i| a[i as usize]).collect() }
fn heis(u: &M, v: &M) -> M { vec![(u[0] + v[0]) % 3, (u[1] + v[1]) % 3, (u[2] + v[2] + u[0] * v[1]) % 3] }
fn idx(g: &[M], x: &M) -> usize { g.iter().position(|y| y == x).unwrap() }
fn undo(g: &[M], mul: Mul) -> (M, Vec<M>) {           // the do-nothing member, and every undo
    let e = g.iter().find(|x| g.iter().all(|y| mul(x, y) == *y)).unwrap().clone();
    (e.clone(), g.iter().map(|x| g.iter().find(|y| mul(x, y) == e).unwrap().clone()).collect())
}
fn conj(g: &[M], mul: Mul, a: &M, xs: &[M]) -> Vec<M> {
    let mut v: Vec<M> = xs.iter().map(|x| mul(&mul(a, x), &undo(g, mul).1[idx(g, a)])).collect();
    v.sort_by_key(|y| idx(g, y)); v.dedup(); v
}
fn classes(g: &[M], mul: Mul) -> Vec<Vec<M>> {        // road one: every g x g^-1, deduplicated
    let mut out: Vec<Vec<M>> = Vec::new();
    for x in g {
        let mut c: Vec<M> = g.iter().map(|a| conj(g, mul, a, &[x.clone()])[0].clone()).collect();
        c.sort_by_key(|y| idx(g, y)); c.dedup();
        if !out.contains(&c) { out.push(c) } }
    out.sort_by_key(|c| (c.len(), idx(g, &c[0]))); out
}
fn cent(g: &[M], mul: Mul, x: &M) -> Vec<M> { g.iter().filter(|a| mul(a, x) == mul(x, a)).cloned().collect() }
fn centre(g: &[M], mul: Mul) -> Vec<M> { g.iter().filter(|z| cent(g, mul, z).len() == g.len()).cloned().collect() }
fn upper(g: &[M], mul: Mul) -> Vec<usize> {           // sizes of Z0 = {e}, Z1 = centre, Z2, ...
    let (e, inv) = undo(g, mul); let (mut z, mut sizes) = (vec![e], vec![1]);
    loop {
        let z2: Vec<M> = g.iter().enumerate().filter(|(i, a)| g.iter().enumerate().all(|(j, x)|
            z.contains(&mul(&mul(a, x), &mul(&inv[*i], &inv[j]))))).map(|(_, a)| a.clone()).collect();
        if z2.len() == z.len() { return sizes }
        z = z2; sizes.push(z.len()); } }
fn derived(g: &[M], h: &[M], mul: Mul) -> Vec<M> {    // all commutators, closed under combining
    let (inv, mut s) = (undo(g, mul).1, Vec::new());
    let add = |s: &mut Vec<M>, x: M| if !s.contains(&x) { s.push(x) };
    for a in h { for b in h { add(&mut s, mul(&mul(a, b), &mul(&inv[idx(g, a)], &inv[idx(g, b)]))) } }
    loop {
        let n = s.len(); for a in s.clone() { for b in s.clone() { add(&mut s, mul(&a, &b)) } }
        if s.len() == n { return s } } }
fn join<T: ToString>(v: &[T], sep: &str) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(sep) }
fn main() {
    let tile: Vec<M> = [1i64, -1].iter().flat_map(|&s| (0..4).map(move |k| (0..4).map(|i| (s * i + k).rem_euclid(4)).collect())).collect();
    let names = ["r0", "r1", "r2", "r3", "r0f", "r1f", "r2f", "r3f"];
    let show = |c: &[M]| format!("{{{}}}", c.iter().map(|x| names[idx(&tile, x)]).collect::<Vec<_>>().join(" "));
    let s3: Vec<M> = (0..3).flat_map(|a| (0..3).filter(move |&b| b != a).map(move |b| vec![a, b, 3 - a - b])).collect();
    let hs: Vec<M> = (0..27).map(|n| vec![n / 9, n / 3 % 3, n % 3]).collect();
    let (cl, z) = (classes(&tile, perm), centre(&tile, perm));
    let sizes: Vec<usize> = cl.iter().map(|c| c.len()).collect();
    let by_cent: Vec<usize> = cl.iter().map(|c| 8 / cent(&tile, perm, &c[0]).len()).collect();
    println!("classes by conjugating: {}", cl.iter().map(|c| show(c)).collect::<Vec<_>>().join(" "));
    println!("class sizes: {:?} | 8 / centraliser size: {:?}", sizes, by_cent);
    println!("centralisers: {}", cl[2..].iter().map(|c| format!("{} {}", names[idx(&tile, &c[0])], show(&cent(&tile, perm, &c[0])))).collect::<Vec<_>>().join("; "));
    let big: Vec<usize> = sizes.iter().filter(|&&n| n > 1).cloned().collect();
    println!("centre, commuting with all 8: {}; class equation 8 = {} + {}", show(&z), z.len(), join(&big, " + "));
    let h = vec![tile[0].clone(), tile[4].clone()];
    let norm: Vec<M> = tile.iter().filter(|g| conj(&tile, perm, g, &h) == h).cloned().collect();
    let mut subs: Vec<Vec<M>> = tile.iter().map(|g| conj(&tile, perm, g, &h)).collect(); subs.sort(); subs.dedup();
    println!("normaliser of {}: {}; 8 / {} = {} conjugate subgroups: {}", show(&h), show(&norm), norm.len(), 8 / norm.len(), subs.iter().map(|c| show(c)).collect::<Vec<_>>().join(" "));
    for (nm, g, mul) in [("S3", &s3, perm as Mul), ("order 27", &hs, heis as Mul)] {
        let sz: Vec<usize> = classes(g, mul).iter().map(|c| c.len()).collect();
        let k = sz.iter().filter(|&&n| n == 1).count(); let terms: Vec<usize> = std::iter::once(k).chain(sz[k..].iter().cloned()).collect();
        println!("{}: {} = {}; centre {}", nm, g.len(), join(&terms, " + "), centre(g, mul).len());
    }
    let a3 = derived(&s3, &s3, perm);
    println!("upper central series sizes: tile {:?} | S3 {:?} | order 27 {:?}", upper(&tile, perm), upper(&s3, perm), upper(&hs, heis));
    println!("S3 solvable: its commutators make a subgroup of {}, theirs of {}", a3.len(), derived(&s3, &a3, perm).len());
    let mut tc: Vec<Vec<M>> = tile.iter().map(|x| { let mut c: Vec<M> = tile[..4].iter().map(|g| conj(&tile, perm, g, &[x.clone()])[0].clone()).collect(); c.sort(); c.dedup(); c }).collect(); tc.sort(); tc.dedup();
    println!("mistakes: 8 / 5 classes = {}; conjugating by turns only gives {} classes; centre as one term 1 + {} = {}; centralisers added = {}",
             8.0 / 5.0, tc.len(), big.iter().sum::<usize>(), 1 + big.iter().sum::<usize>(), cl.iter().map(|c| cent(&tile, perm, &c[0]).len()).sum::<usize>());
    assert!(sizes == by_cent && by_cent.iter().sum::<usize>() == 8);     // two roads, one count
    assert!(z == cl.iter().filter(|c| c.len() == 1).map(|c| c[0].clone()).collect::<Vec<M>>() && z.len() == 2);
    assert!(centre(&hs, heis).len() == 3 && centre(&s3, perm).len() == 1);
    assert!(*upper(&tile, perm).last().unwrap() == 8 && upper(&hs, heis) == vec![1, 3, 27] && upper(&s3, perm) == vec![1]);
    assert!(norm.len() * subs.len() == 8 && a3.len() == 3);
    println!("ALL CHECKS PASS");
}
