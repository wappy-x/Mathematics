// Homology of spheres, and degree -- the same check as the Python, in Rust.  No crates.
// Spheres are triangulated two ways; their homology over Z comes from an integer Smith form.
// Degrees come three ways: the fundamental cycle pushed through the map, preimages counted
// with signs, and the real map's turning angle added up.  Exact except the angle sums.
use std::collections::{BTreeMap, BTreeSet};
use std::f64::consts::PI;
type Chain = BTreeMap<Vec<usize>, i64>;

fn combos(items: &[usize], k: usize) -> Vec<Vec<usize>> {  // the k-subsets of items
    (0..1usize << items.len()).filter(|m| m.count_ones() as usize == k)
        .map(|m| (0..items.len()).filter(|i| m >> i & 1 == 1).map(|i| items[i]).collect()).collect()
}
fn closure(tops: &[Vec<usize>]) -> Vec<Vec<Vec<usize>>> {   // every face, by dimension
    let mut cells: Vec<BTreeSet<Vec<usize>>> = vec![BTreeSet::new(); tops[0].len()];
    for t in tops { for k in 1..=t.len() { cells[k - 1].extend(combos(t, k)) } }
    cells.into_iter().map(|c| c.into_iter().collect()).collect()
}
fn face(s: &[usize], i: usize) -> Vec<usize> { let mut f = s.to_vec(); f.remove(i); f }
fn boundary(rows: &[Vec<usize>], cols: &[Vec<usize>]) -> Vec<Vec<i64>> {
    let mut m = vec![vec![0i64; cols.len()]; rows.len()];
    for (j, s) in cols.iter().enumerate() {
        for i in 0..s.len() { m[rows.iter().position(|x| *x == face(s, i)).unwrap()][j] = 1 - 2 * (i % 2) as i64 }
    }
    m
}
fn fdiv(a: i64, b: i64) -> i64 { if b > 0 { a.div_euclid(b) } else { (-a).div_euclid(-b) } }  // floor
fn smith(mut m: Vec<Vec<i64>>) -> Vec<i64> {                // nonzero Smith diagonal
    let mut diag = vec![];
    while !m.is_empty() && !m[0].is_empty() && m.iter().flatten().any(|&v| v != 0) {
        let mut best = (i64::MAX, 0, 0);
        for (i, r) in m.iter().enumerate() {                 // the smallest nonzero entry
            for (j, &v) in r.iter().enumerate() { if v != 0 && (v.abs(), i, j) < best { best = (v.abs(), i, j) } }
        }
        let (_, i, j) = best; m.swap(0, i);
        for r in m.iter_mut() { r.swap(0, j) }
        let p = m[0][0];
        for i in 1..m.len() {                                // clear the column, then the row
            let (q, top) = (fdiv(m[i][0], p), m[0].clone());
            for (a, b) in m[i].iter_mut().zip(top) { *a -= q * b }
        }
        let q: Vec<i64> = m[0].iter().map(|&v| fdiv(v, p)).collect();
        for r in m.iter_mut() { let r0 = r[0]; for j in 1..r.len() { r[j] -= q[j] * r0 } }
        if m[1..].iter().any(|r| r[0] != 0) || m[0][1..].iter().any(|&v| v != 0) { continue }
        match m[1..].iter().find(|r| r[1..].iter().any(|v| v % p != 0)).cloned() {
            Some(bad) => { for (a, b) in m[0].iter_mut().zip(bad) { *a += b } }
            None => { diag.push(p.abs()); m = m[1..].iter().map(|r| r[1..].to_vec()).collect() }
        }
    }
    diag
}
fn homology(tops: &[Vec<usize>]) -> (Vec<(usize, Vec<i64>)>, Vec<usize>) {
    let c = closure(tops);
    let sf: Vec<Vec<i64>> = std::iter::once(vec![]).chain((1..c.len())
        .map(|k| smith(boundary(&c[k - 1], &c[k])))).chain(std::iter::once(vec![])).collect();
    let hs = (0..c.len()).map(|k| (c[k].len() - sf[k].len() - sf[k + 1].len(),
        sf[k + 1].iter().copied().filter(|&d| d > 1).collect())).collect();
    (hs, c.iter().map(|x| x.len()).collect())
}
fn name(rank: usize, tors: &[i64]) -> String {
    let mut out: Vec<String> = if rank > 1 { vec![format!("Z^{}", rank)] } else { vec!["Z".to_string(); rank] };
    out.extend(tors.iter().map(|d| format!("Z/{}", d)));
    if out.is_empty() { "0".to_string() } else { out.join(" + ") }
}
fn groups(hs: &[(usize, Vec<i64>)]) -> String {
    hs.iter().enumerate().map(|(k, h)| format!("H{} {}", k, name(h.0, &h.1))).collect::<Vec<_>>().join(", ")
}
fn is_cycle(chain: &Chain) -> bool {                        // does the chain have zero boundary?
    let mut rim: Chain = BTreeMap::new();
    for (s, c) in chain { for i in 0..s.len() { *rim.entry(face(s, i)).or_insert(0) += if i % 2 == 0 { *c } else { -*c } } }
    rim.values().all(|&v| v == 0)
}
fn degree(src: &Chain, tgt: &Chain, f: &dyn Fn(usize) -> usize) -> i64 {
    let mut img: Chain = BTreeMap::new();
    for (s, c) in src {
        let im: Vec<usize> = s.iter().map(|&v| f(v)).collect();
        let mut key = im.clone(); key.sort(); key.dedup();
        if key.len() < im.len() { continue }                // a squashed simplex gives nothing
        let inv = (0..im.len()).flat_map(|a| (a + 1..im.len()).map(move |b| (a, b)))
            .filter(|&(a, b)| im[a] > im[b]).count();      // the reordering sign
        *img.entry(key).or_insert(0) += if inv % 2 == 0 { *c } else { -*c };
    }
    let ratios: BTreeSet<i64> = tgt.iter().map(|(t, c)| img.get(t).copied().unwrap_or(0) * c).collect();
    assert!(ratios.len() == 1 && img.iter().all(|(t, &v)| v == 0 || tgt.contains_key(t)));
    *ratios.iter().next().unwrap()
}
fn ring(n: usize) -> Chain {                                // fundamental cycle of an n-gon
    (0..n - 1).map(|k| (vec![k, k + 1], 1)).chain([(vec![0, n - 1], -1)]).collect()
}
fn cross(n: usize) -> Chain {                               // the cross-polytope S^n
    (0..1usize << (n + 1)).map(|mask| ((0..=n).map(|i| 2 * i + (mask >> i & 1)).collect(),
        if mask.count_ones() % 2 == 0 { 1 } else { -1 })).collect()
}
fn signs(n_src: usize, f: &dyn Fn(usize) -> usize) -> Vec<i64> {
    (0..n_src).map(|k| (f(k), f((k + 1) % n_src)))
        .filter(|&h| h == (0, 1) || h == (1, 0)).map(|h| if h == (0, 1) { 1 } else { -1 }).collect()
}
fn turns(g: &dyn Fn(f64) -> (f64, f64)) -> Vec<f64> {      // running total turn round 0
    let pts: Vec<(f64, f64)> = (0..=720).map(|s| g(2.0 * PI * s as f64 / 720.0)).collect();
    let (mut out, mut tot) = (vec![0.0], 0.0);
    for w in pts.windows(2) {
        let ((ar, ai), (br, bi)) = (w[0], w[1]);
        tot += (bi * ar - br * ai).atan2(br * ar + bi * ai);      // the small turn between values
        out.push(tot / (2.0 * PI));
    }
    out
}
fn power(n: i64) -> impl Fn(f64) -> (f64, f64) { move |t| ((n as f64 * t).cos(), (n as f64 * t).sin()) }
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn last(v: Vec<f64>) -> i64 { v[v.len() - 1].round() as i64 }
fn main() {
    println!("homology over Z of S^n, triangulated as the boundary of an (n+1)-simplex:");
    for n in 0..5usize {
        let (hs, cnt) = homology(&combos(&(0..n + 2).collect::<Vec<_>>(), n + 1));
        let chi: i64 = cnt.iter().enumerate().map(|(k, &c)| if k % 2 == 0 { c as i64 } else { -(c as i64) }).sum();
        println!("S{}: simplices {:?}, chi {}; {}", n, cnt, chi, groups(&hs));
        let want: Vec<(usize, Vec<i64>)> = (0..=n).map(|k| (if k == 0 { if n == 0 { 2 } else { 1 } } else { (k == n) as usize }, vec![])).collect();
        let alt: i64 = hs.iter().enumerate().map(|(k, h)| if k % 2 == 0 { h.0 as i64 } else { -(h.0 as i64) }).sum();
        assert!(hs == want && chi == alt && chi == 1 + if n % 2 == 0 { 1 } else { -1 });
    }
    for n in 1..4usize {                                    // the square, the octahedron, the 16-cell
        let (hs, cnt) = homology(&cross(n).keys().cloned().collect::<Vec<_>>());
        println!("S{} as a cross-polytope: simplices {:?}; {}", n, cnt, groups(&hs));
        let want: Vec<(usize, Vec<i64>)> = (0..=n).map(|k| (if k == 0 { 1 } else { (k == n) as usize }, vec![])).collect();
        let mut flipped = cross(n); flipped.insert((0..=n).map(|i| 2 * i).collect(), -1);
        assert!(hs == want && is_cycle(&cross(n)) && !is_cycle(&flipped));
    }
    let clock = |k: usize| k % 3;                           // hour hand at 10k degrees, minute hand at 120k
    let (d_chain, sg, d_turn) = (degree(&ring(36), &ring(3), &clock), signs(36, &clock), last(turns(&power(12))));
    println!("clock, z^12 as a 36-gon onto a triangle: fundamental cycle goes to {} x the target's", d_chain);
    println!("clock: source edges laid on target edge 0-1: {}, signs sum {}; angle turns {}", sg.len(), sg.iter().sum::<i64>(), d_turn);
    println!("clock: minute hand at 12 when the hour hand is at {:?} degrees", (0..12).map(|h| 30 * h).collect::<Vec<i64>>());
    let ns: Vec<i64> = (-3..13).collect();
    let map = |n: i64| move |k: usize| ((n.signum() * k as i64).rem_euclid(3)) as usize;
    let size = |n: i64| 3 * n.unsigned_abs().max(1) as usize;
    let by_chain: Vec<i64> = ns.iter().map(|&n| degree(&ring(size(n)), &ring(3), &map(n))).collect();
    let by_signs: Vec<i64> = ns.iter().map(|&n| signs(size(n), &map(n)).iter().sum()).collect();
    let by_turns: Vec<i64> = ns.iter().map(|&n| last(turns(&power(n)))).collect();
    println!("z^n for n = -3..12, by chain map: {:?}", by_chain);
    println!("same, by signed preimages: {}; by angle turns: {}", yn(by_signs == ns), yn(by_turns == ns));
    let mirror = |k: usize| (12 - k) % 12;
    let zig = |k: usize| [0, 1, 2, 3, 0, 1, 2, 3, 0, 3, 2, 1][k];
    let zigzag = |t: f64| { let a = if t <= 4.0 * PI / 3.0 { 3.0 * t } else { 8.0 * PI - 3.0 * t }; (a.cos(), a.sin()) };
    let (m_turn, z_turn) = (turns(&power(-1)), turns(&zigzag));
    let (dm, dz) = (degree(&ring(12), &ring(12), &mirror), degree(&ring(12), &ring(4), &zig));
    println!("mirror, z to conj(z) on a 12-gon: chain {}, preimage signs {:?}, turns {}", dm, signs(12, &mirror), last(m_turn.clone()));
    println!("zigzag, 2 turns on then 1 back: chain {}, preimage signs {:?}, turns {}", dz, signs(12, &zig), last(z_turn.clone()));
    let (d2, d3) = (degree(&ring(18), &ring(9), &|k| k % 9), degree(&ring(9), &ring(3), &|k| k % 3));
    let d6 = degree(&ring(18), &ring(3), &|k| k % 9 % 3);
    println!("z^3 after z^2: degrees {} and {}, composite {}; added instead: {}", d2, d3, d6, d2 + d3);
    let anti: Vec<i64> = (1..4).map(|n| degree(&cross(n), &cross(n), &|v| v ^ 1)).collect();
    let refl: Vec<Vec<i64>> = (1..4usize).map(|n| (0..=n)
        .map(|i| degree(&cross(n), &cross(n), &move |v| v ^ (v / 2 == i) as usize)).collect()).collect();
    let prods: Vec<i64> = refl.iter().map(|r| r.iter().product()).collect();
    println!("antipode on S1, S2, S3 by chain map: {:?}", anti);
    println!("reflections in one axis each: {:?}; products {:?}", refl, prods);
    let quad = |r: f64| move |t: f64| { let (x, y) = (r * t.cos(), r * t.sin()); (x * x - y * y - 4.0 * x + 5.0, 2.0 * x * y - 4.0 * y) };
    let fta: Vec<i64> = [1.0, 2.0, 3.0, 10.0].iter().map(|&r| last(turns(&quad(r)))).collect();
    println!("z^2 - 4z + 5 round radius 1, 2, 3, 10: turns {:?}; roots 2 +- i at radius {:.3}", fta, 5f64.sqrt());
    println!("chart, turns so far at each twelfth of the walk:");
    for (label, tr) in [("clock", turns(&power(12))), ("zigzag", z_turn.clone()), ("mirror", m_turn.clone())] {
        println!("{} {}", label, (0..13).map(|k| format!("{:.2}", tr[60 * k])).collect::<Vec<_>>().join(" "));
    }
    assert!(d_chain == 12 && sg.iter().sum::<i64>() == 12 && d_turn == 12 && sg.len() == 12);   // the clock
    assert!(by_chain == ns && by_signs == ns && by_turns == ns);                             // z^n has degree n
    assert!(dm == -1 && signs(12, &mirror).iter().sum::<i64>() == -1 && last(m_turn) == -1);
    assert!(dz == 1 && signs(12, &zig).iter().sum::<i64>() == 1 && last(z_turn) == 1);
    assert!(d6 == d2 * d3 && d6 == 6 && anti == prods && anti == vec![1, -1, 1]);
    assert!(fta == vec![0, 0, 2, 2]);
    println!("ALL CHECKS PASS");
}
