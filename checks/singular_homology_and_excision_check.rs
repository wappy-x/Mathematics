// Singular homology and excision -- the check behind the card.  std only, no crates.
// Road 1: barycentric subdivision done exactly on a dome panel (an equilateral
//         triangle of side 1 m), every small triangle measured, against the bound.
// Road 2: every small triangle tested against a cover of 11 strips whose
//         Lebesgue number is 0.1 m; the bound predicts the round that is enough.
// Road 3: local homology by exact ranks over Q, two ways: the whole space against
//         the excised piece, and both against the exact sequence (reduced counts).
use std::collections::{BTreeMap, BTreeSet};
const S: i64 = 2_985_984; // 12^6: barycentric weights scaled by S stay whole for 6 rounds
const DEN: i128 = 2 * (S as i128) * (S as i128); // squared distances are num / (2 S^2)
type Simp = Vec<Vec<i64>>;
type Cx = BTreeSet<Vec<usize>>;
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn frac(n: i128, d: i128) -> String { let g = gcd(n, d); if d / g == 1 { format!("{}", n / g) } else { format!("{}/{}", n / g, d / g) } }
fn sqrtf(n: i128, d: i128) -> f64 { (n as f64 / d as f64).sqrt() }
fn bary(pts: &[Vec<i64>]) -> Vec<i64> {
    let m = pts.len() as i64;
    (0..pts[0].len()).map(|i| { let t: i64 = pts.iter().map(|p| p[i]).sum(); assert!(t % m == 0); t / m }).collect()
}
fn perms(items: &[usize]) -> Vec<Vec<usize>> { // every ordering, first item chosen first
    if items.is_empty() { return vec![vec![]]; }
    items.iter().enumerate().flat_map(|(i, &x)| {
        let rest: Vec<usize> = items.iter().enumerate().filter(|&(j, _)| j != i).map(|(_, &y)| y).collect();
        perms(&rest).into_iter().map(move |mut p| { p.insert(0, x); p }) }).collect()
}
fn combos<T: Clone>(v: &[T], k: usize) -> Vec<Vec<T>> {
    if k == 0 || v.len() < k { return if k == 0 { vec![vec![]] } else { vec![] }; }
    let mut out: Vec<Vec<T>> = combos(&v[1..], k - 1).into_iter().map(|mut c| { c.insert(0, v[0].clone()); c }).collect();
    out.extend(combos(&v[1..], k));
    out
}
fn subdivide(s: &Simp) -> Vec<Simp> {
    let idx: Vec<usize> = (0..s.len()).collect();
    perms(&idx).iter().map(|o| (0..s.len()).map(|m| bary(&o[..m + 1].iter().map(|&i| s[i].clone()).collect::<Vec<_>>())).collect()).collect()
}
fn diam2(s: &Simp) -> i128 { // numerator over 2 S^2 of the squared diameter, side 1 m
    combos(s, 2).iter().map(|pq| pq[0].iter().zip(&pq[1]).map(|(a, b)| ((a - b) as i128).pow(2)).sum::<i128>()).max().unwrap()
}
fn rounds(n: usize, r: usize) -> Vec<Vec<Simp>> {
    let corners: Simp = (0..=n).map(|j| (0..=n).map(|i| if i == j { S } else { 0 }).collect()).collect();
    let mut levels = vec![vec![corners]];
    let (fa, fb) = ((n * n) as i128, ((n + 1) * (n + 1)) as i128);
    for _ in 0..r {
        let mut nxt = vec![];
        for s in levels.last().unwrap() {
            let kids = subdivide(s);
            assert!(kids.iter().all(|c| diam2(c) * fb <= fa * diam2(s))); // the one-round bound
            nxt.extend(kids);
        }
        levels.push(nxt);
    }
    levels
}
fn misfits(level: &[Simp]) -> usize {
    level.iter().filter(|s| {
        let xs: Vec<i64> = s.iter().map(|w| 20 * w[1] + 10 * w[2]).collect(); // 20 S times x
        let (lo, hi) = (*xs.iter().min().unwrap(), *xs.iter().max().unwrap());
        !(0..11).any(|j: i64| 2 * S * (j - 1) < lo && hi < 2 * S * (j + 1))
    }).count()
}
fn rank(mut m: Vec<Vec<i128>>) -> i64 { // exact over Q, fraction-free elimination
    let (mut rk, cols) = (0, if m.is_empty() { 0 } else { m[0].len() });
    for col in 0..cols {
        let Some(p) = (rk..m.len()).find(|&i| m[i][col] != 0) else { continue };
        m.swap(rk, p);
        for i in rk + 1..m.len() {
            if m[i][col] == 0 { continue; }
            let (a, b) = (m[rk][col], m[i][col]);
            let row: Vec<i128> = (0..cols).map(|j| a * m[i][j] - b * m[rk][j]).collect();
            let g = row.iter().fold(0, |g, &x| gcd(g, x)).max(1);
            m[i] = row.iter().map(|x| x / g).collect();
        }
        rk += 1;
    }
    rk as i64
}
fn closure(tops: &[Vec<usize>]) -> Cx {
    let mut out = Cx::new();
    for t in tops { let mut t = t.clone(); t.sort(); for k in 1..=t.len() { out.extend(combos(&t, k)); } }
    out
}
fn betti(x: &Cx, a: &Cx) -> Vec<i64> { // Betti numbers of x relative to a, over Q
    let rel: Vec<Vec<Vec<usize>>> = (0..6).map(|k| x.difference(a).filter(|s| s.len() == k + 1).cloned().collect()).collect();
    let bd = |k: usize| -> i64 {
        if k == 0 || k >= 6 || rel[k].is_empty() || rel[k - 1].is_empty() { return 0; }
        let row: BTreeMap<&Vec<usize>, usize> = rel[k - 1].iter().enumerate().map(|(i, s)| (s, i)).collect();
        let mut mat = vec![vec![0i128; rel[k].len()]; rel[k - 1].len()];
        for (j, s) in rel[k].iter().enumerate() {
            for i in 0..s.len() {
                let mut f = s.clone(); f.remove(i);
                if let Some(&r) = row.get(&f) { mat[r][j] = if i % 2 == 0 { 1 } else { -1 }; }
            }
        }
        rank(mat)
    };
    let top = (0..6).filter(|&k| !rel[k].is_empty()).max().unwrap_or(0);
    (0..=top).map(|k| rel[k].len() as i64 - bd(k) - bd(k + 1)).collect()
}
fn shifted_reduced(b: &[i64]) -> Vec<i64> { let mut v = vec![0, b[0] - 1]; v.extend(&b[1..]); v }
fn main() {
    let tri = rounds(2, 6);
    let c = bary(&tri[0][0]);
    let r3 = 3f64.sqrt();
    println!("figure, panel corners (0,0) (1,0) (0.5,{:.4}); centroid ({:.4},{:.4}) m", r3 / 2.0,
             (c[1] as f64 + c[2] as f64 / 2.0) / S as f64, c[2] as f64 * r3 / 2.0 / S as f64);
    let big: Vec<i128> = tri.iter().map(|lev| lev.iter().map(diam2).max().unwrap()).collect();
    let bad: Vec<usize> = tri.iter().map(|lev| misfits(lev)).collect();
    for (r, lev) in tri.iter().enumerate() {
        println!("round {}: {} triangles, largest diameter {:.4} m (squared {}), bound (2/3)^{} = {:.4}, in no strip {}",
                 r, lev.len(), sqrtf(big[r], DEN), frac(big[r], DEN), r, 2f64.powi(r as i32) / 3f64.powi(r as i32), bad[r]);
    }
    let need = (0..20u32).find(|&r| 10 * 2i128.pow(r) < 3i128.pow(r)).unwrap() as usize;
    let half = (0..20u32).find(|&r| 10 < 2i128.pow(r)).unwrap() as usize;
    println!("bound first below 0.1 m at round {}; first round with every triangle in a strip {}", need, bad.iter().position(|&b| b == 0).unwrap());
    assert!((0..7u32).all(|r| big[r as usize] * 9i128.pow(r) <= DEN * 4i128.pow(r))); // road 1
    assert!(big[1] * 3 == DEN); // corner to centre, 1/sqrt(3), by hand
    assert!((need, half) == (6, 4)); // by hand: (2/3)^5 > 0.1 > (2/3)^6; (1/2)^3 > 0.1 > (1/2)^4
    assert!(bad[need] == 0 && bad[0] == 1); // road 2
    for (n, r) in [(1usize, 4usize), (3, 3)] {
        let ds: Vec<i128> = rounds(n, r).iter().map(|lev| lev.iter().map(diam2).max().unwrap()).collect();
        assert!(ds.iter().enumerate().all(|(k, &d)| d * ((n + 1) as i128).pow(2 * k as u32) <= DEN * (n as i128).pow(2 * k as u32)));
        let txt: Vec<String> = ds.iter().map(|&d| format!("{:.4}", sqrtf(d, DEN))).collect();
        println!("{}-simplex, {} rounds: largest diameters {} m; bound ratio {}/{}", n, r, txt.join(", "), n, n + 1);
    }
    // ---- homology: the dome, an icosahedron with each face cut in 4 ----
    let nb = |i: usize| 1 + (i + 1) % 5;
    let mut ico: Vec<[usize; 3]> = vec![];
    for i in 0..5 { ico.extend([[0, 1 + i, nb(i)], [11, 6 + i, 5 + nb(i)], [1 + i, nb(i), 6 + i], [nb(i), 6 + i, 5 + nb(i)]]); }
    let edges: BTreeSet<(usize, usize)> = ico.iter().flat_map(|f| { let mut g = *f; g.sort(); [(g[0], g[1]), (g[0], g[2]), (g[1], g[2])] }).collect();
    let mut mid = BTreeMap::new();
    for (k, &(a, b)) in edges.iter().enumerate() { mid.insert((a, b), 12 + k); mid.insert((b, a), 12 + k); }
    let mut panels: Vec<Vec<usize>> = vec![];
    for &[a, b, c] in &ico {
        let (ab, bc, ca) = (mid[&(a, b)], mid[&(b, c)], mid[&(c, a)]);
        panels.extend([vec![a, ab, ca], vec![b, ab, bc], vec![c, bc, ca], vec![ab, bc, ca]]);
    }
    let (dome, p, none) = (closure(&panels), panels[0].clone(), Cx::new());
    let star: Vec<Vec<usize>> = panels.iter().filter(|q| q.contains(&0)).cloned().collect();
    let rim = closure(&combos(&p, 2));
    let counts: Vec<usize> = (0..3).map(|k| dome.iter().filter(|s| s.len() == k + 1).count()).collect();
    println!("dome: simplices {:?}, Betti {:?}; joint 0 has {} panels", counts, betti(&dome, &none), star.len());
    let link: Vec<Vec<usize>> = star.iter().flat_map(|q| combos(q, 2)).filter(|e| !e.contains(&0)).collect();
    let away: Vec<Vec<usize>> = panels.iter().filter(|q| !q.contains(&0)).cloned().collect();
    let pairs = [("dome rel dome minus one open panel", betti(&dome, &closure(&panels[1..]))),
                 ("one panel rel its rim", betti(&closure(&[p.clone()]), &rim)),
                 ("dome rel dome minus open star of joint 0", betti(&dome, &closure(&away))),
                 ("star of joint 0 rel its link", betti(&closure(&star), &closure(&link)))];
    for (name, b) in &pairs { println!("local, {}: {:?}", name, b); }
    let les = shifted_reduced(&betti(&rim, &none));
    println!("local, the rim's reduced counts shifted up one: {:?}", les);
    assert!(counts == vec![42, 120, 80] && betti(&dome, &none) == vec![1, 0, 1]);
    assert!(pairs.iter().all(|(_, b)| *b == vec![0, 0, 1] && *b == les)); // road 3
    for n in 1..5usize {
        let simplex = closure(&[(0..=n).collect()]);
        let edge: Cx = simplex.iter().filter(|s| s.len() <= n).cloned().collect();
        let (rel, les) = (betti(&simplex, &edge), shifted_reduced(&betti(&edge, &none)));
        let mut want = vec![0i64; n]; want.push(1);
        assert!(rel == les && les == want); // Z only in degree n, two ways
        println!("n = {}: simplex rel rim {:?}; S^{} reduced, shifted {:?}", n, rel, n - 1, les);
    }
    let bds: Vec<i64> = (0..7).map(|k| if k > 0 && k % 2 == 0 { 1 } else { 0 }).collect(); // a point
    println!("point, singular chains to degree 5: Betti {:?}", (0..6).map(|k| 1 - bds[k] - bds[k + 1]).collect::<Vec<_>>());
    println!("mistake, shrink factor 1/2: bound below 0.1 m at round {}; round {} truly {:.4} m, {} triangles in no strip",
             half, half, sqrtf(big[half], DEN), bad[half]);
    let mut unred = vec![0i64]; unred.extend(betti(&rim, &none));
    println!("mistake, unreduced rim shifted: {:?}, true {:?}", unred, pairs[1].1);
    println!("mistake, excise the whole rim: panel alone {:?}, true {:?}", betti(&closure(&[p.clone()]), &none), pairs[1].1);
    assert!(bad[half] > 0 && unred != pairs[1].1);
    println!("ALL CHECKS PASS");
}
