// The Galois correspondence -- the check behind the card.  std only.
// L is the splitting field of x^4 - 2: every number in it is a rational mix of the 8 basis
// numbers α^j i^k (j = 0..3, k = 0..1), where α = 2^(1/4).  An array of 8 integers is one number.
use std::collections::BTreeSet;
type V = [i64; 8]; type Gp = (i64, i64);
const A4: i64 = 2; // the polynomial is x^4 - A4
fn mul(u: &V, v: &V) -> V { // multiply two numbers of L, using α^4 = 2 and i^2 = -1
    let mut w = [0i64; 8];
    for p in 0..8 { for q in 0..8 {
        let (mut j, mut k, mut c) = (p % 4 + q % 4, p / 4 + q / 4, u[p] * v[q]);
        if j >= 4 { j -= 4; c *= A4; }
        if k == 2 { k = 0; c = -c; }
        w[j + 4 * k] += c; } }
    w
}
fn apply(g: Gp, u: &V) -> V { // g = (r, s): α -> i^r α, i -> i^s, extended to all of L
    let mut w = [0i64; 8]; for p in 0..8 {
        let m = (g.0 * (p as i64 % 4) + g.1 * (p as i64 / 4)).rem_euclid(4);
        w[p % 4 + 4 * (m as usize % 2)] += if m >= 2 { -u[p] } else { u[p] };
    }
    w
}
fn compose(g: Gp, h: Gp) -> Gp { ((g.0 + g.1 * h.0).rem_euclid(4), (g.1 * h.1).rem_euclid(4)) }
fn inv(g: Gp) -> Gp { ((-g.1 * g.0).rem_euclid(4), g.1) }
fn name(g: Gp) -> String { let s = format!("{}{}", ["", "σ", "σ²", "σ³"][g.0 as usize],
    if g.1 == 3 { "τ" } else { "" }); if s.is_empty() { "1".to_string() } else { s } }
fn show(c: &[i64]) -> String { // integer coefficients, constant first -> "x^4 - 2"
    let mut out = String::new();
    for n in (0..c.len()).rev() {
        let a = c[n]; if a == 0 { continue; }
        if out.is_empty() { if a < 0 { out.push('-'); } } else { out += if a < 0 { " - " } else { " + " }; }
        if a.abs() != 1 || n == 0 { out += &a.abs().to_string(); }
        if n > 0 { out.push('x'); } if n > 1 { out += &format!("^{}", n); }
    }
    out
}
fn e(ps: &[(usize, i64)]) -> V { let mut w = [0i64; 8]; for &(p, c) in ps { w[p] += c; } w }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn rank(rows: &[V]) -> usize { // rank over Q: integer elimination, rows kept small by gcd
    let mut m: Vec<Vec<i128>> = rows.iter().map(|r| r.iter().map(|&x| x as i128).collect()).collect();
    let mut r = 0;
    for c in 0..8 {
        let piv = match (r..m.len()).find(|&i| m[i][c] != 0) { Some(p) => p, None => continue };
        m.swap(r, piv);
        for i in 0..m.len() {
            if i != r && m[i][c] != 0 {
                let (a, b) = (m[r][c], m[i][c]);
                let row: Vec<i128> = (0..8).map(|t| a * m[i][t] - b * m[r][t]).collect();
                let g = row.iter().fold(0, |acc, &x| gcd(acc, x)).max(1);
                m[i] = row.iter().map(|&x| x / g).collect(); } }
        r += 1; }
    r
}
fn min_poly(orbit: &[V]) -> Vec<V> { // product of (x - c) over the conjugates c
    let mut poly = vec![e(&[(0, 1)])]; for c in orbit {
        let n = poly.len();
        poly = (0..=n).map(|t| {
            let lo = if t > 0 { poly[t - 1] } else { [0; 8] };
            let hi = if t < n { mul(c, &poly[t]) } else { [0; 8] };
            let mut w = [0; 8]; for q in 0..8 { w[q] = lo[q] - hi[q]; } w }).collect();
    }
    poly
}
fn rational(p: &[V]) -> bool { p.iter().all(|c| c[1..].iter().all(|&x| x == 0)) }
fn names(h: &[Gp]) -> String { format!("[{}]", h.iter().map(|&g| format!("'{}'", name(g))).collect::<Vec<_>>().join(", ")) }
fn list<T: std::fmt::Display>(v: &[T]) -> String { format!("[{}]", v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ")) }
fn main() {
    let basis: Vec<V> = (0..8).map(|p| e(&[(p, 1)])).collect();
    // ---- road 1: try all 16 ways to send α to a root i^r α and i to a power i^s; keep the ring maps
    let tried: Vec<Gp> = (0..4).flat_map(|r| (0..4).map(move |s| (r, s))).collect();
    let g_all: Vec<Gp> = tried.iter().cloned().filter(|&g| basis.iter().all(|u| basis.iter()
        .all(|v| apply(g, &mul(u, v)) == mul(&apply(g, u), &apply(g, v))))).collect();
    println!("maps tried {}, respect all {} basis products {}: {}", tried.len(), basis.len().pow(2), g_all.len(), names(&g_all));
    let order = |g: Gp| { let (mut x, mut n) = (g, 1); while x != (0, 1) { x = compose(g, x); n += 1; } n };
    println!("element orders: {}; τσ = {}, not στ: order matters; D4, the square's 8 symmetries",
             list(&g_all.iter().map(|&g| order(g)).collect::<Vec<_>>()), name(compose((0, 3), (1, 1))));
    // ---- road 2: the 4 roots as complex numbers; a symmetry must send -r to minus the image of r
    let a = (A4 as f64).powf(0.25);
    let (roots, mut keep) = ([(a, 0.0), (0.0, a), (-a, 0.0), (0.0, -a)], vec![]); // α, iα, -α, -iα
    for p0 in 0..4 { for p1 in 0..4 { for p2 in 0..4 { for p3 in 0..4 {
        let p = [p0, p1, p2, p3];
        if BTreeSet::from(p).len() == 4 && (0..4).all(|k| roots[p[(k + 2) % 4]] == (-roots[p[k]].0, -roots[p[k]].1)) { keep.push(p); }
    } } } }
    let on_roots: Vec<[usize; 4]> = g_all.iter().map(|&g| [0, 1, 2, 3].map(|k: i64| (g.1 * k + g.0).rem_euclid(4) as usize)).collect::<BTreeSet<_>>().into_iter().collect(); // road 1's maps on the 4 roots
    println!("α = {:.6}; root shuffles 24, keeping r -> -r pairs {}; failing {}; same as road 1's maps on the roots {}", a, keep.len(), 24 - keep.len(), if on_roots == keep { "True" } else { "False" });
    let theta = e(&[(1, 1), (4, 1)]); // α + i
    let conj: Vec<V> = g_all.iter().map(|&g| apply(g, &theta)).collect::<BTreeSet<_>>().into_iter().collect();
    let poly = min_poly(&conj);
    println!("α + i has {} distinct conjugates; min poly coefficients rational {}: {}, so [L:Q] = {}",
             conj.len(), if rational(&poly) { "True" } else { "False" },
             show(&poly.iter().map(|c| c[0]).collect::<Vec<_>>()), conj.len());
    let (re, im) = poly.iter().rev().fold((0.0f64, 0.0f64), |(x, y), c| (x * a - y + c[0] as f64, x + y * a));
    assert!(re.abs() + im.abs() < 1e-9); // α + i, as a float, is a root
    // ---- every subgroup, by brute force over the 256 subsets of the 8 symmetries
    let mut subs: Vec<Vec<Gp>> = (0..256u32).map(|m| (0..8).filter(|b| m >> b & 1 == 1)
        .map(|b| g_all[b]).collect::<Vec<Gp>>()).filter(|h| h.contains(&(0, 1))
        && h.iter().all(|&x| h.iter().all(|&y| h.contains(&compose(x, y))))).collect();
    subs.sort_by_key(|h| (h.len(), h.iter().map(|&g| name(g)).collect::<Vec<_>>()));
    let cands: Vec<(&str, V)> = vec![("1", e(&[(0, 1)])), ("i", e(&[(4, 1)])), ("√2", e(&[(2, 1)])),
        ("i√2", e(&[(6, 1)])), ("α", e(&[(1, 1)])), ("iα", e(&[(5, 1)])), ("(1+i)α", e(&[(1, 1), (5, 1)])),
        ("(1-i)α", e(&[(1, 1), (5, -1)])), ("√2 + i", e(&[(2, 1), (4, 1)])), ("α + i", theta)];
    println!("H | order | index | dim of fixed field: kernel, average | field | min poly | normal: H, field");
    let (mut fields, mut normals): (Vec<(Vec<Gp>, String)>, usize) = (vec![], 0);
    let label = |f: &Vec<(Vec<Gp>, String)>, h: &Vec<Gp>| -> String {
        let mut s = h.clone(); s.sort(); f.iter().find(|x| x.0 == s).unwrap().1.clone() };
    let is_normal = |h: &Vec<Gp>| g_all.iter().all(|&g| h.iter().all(|&x| h.contains(&compose(compose(g, x), inv(g)))));
    for h in &subs {
        let ker_rows: Vec<V> = h.iter().flat_map(|&g| basis.iter().map(move |u| {
            let w = apply(g, u); let mut d = [0; 8]; for q in 0..8 { d[q] = w[q] - u[q]; } d })).collect();
        let by_kernel = 8 - rank(&ker_rows);
        let avg: Vec<V> = basis.iter().map(|u| { let mut w = [0; 8];
            for &g in h { let x = apply(g, u); for q in 0..8 { w[q] += x[q]; } } w }).collect();
        let by_average = rank(&avg);
        let mut hs = h.clone(); hs.sort();
        let (lab, gen) = cands.iter().find(|(_, v)| g_all.iter().cloned()
            .filter(|&g| apply(g, v) == *v).collect::<Vec<_>>() == hs).unwrap();
        let orbit: Vec<V> = g_all.iter().map(|&g| apply(g, gen)).collect::<BTreeSet<_>>().into_iter().collect();
        let mp = min_poly(&orbit);
        let (grp_normal, tf) = (is_normal(h), |b: bool| if b { "True" } else { "False" });
        let fld_normal = g_all.iter().all(|&g| { let mut rows = avg.clone();
            rows.extend(avg.iter().map(|w| apply(g, w))); rank(&rows) == by_average });
        if grp_normal { normals += 1; }
        fields.push((hs, lab.to_string()));
        let hname = if h.len() < 8 { format!("{{{}}}", h.iter().map(|&g| name(g)).collect::<Vec<_>>().join(",")) } else { "all 8".to_string() };
        let fname = if h.len() < 8 { format!("Q({})", lab) } else { "Q".to_string() };
        println!("{:14} {} {} {} {}  {:10} {:26} {} {}", hname, h.len(), 8 / h.len(), by_kernel, by_average,
                 fname, show(&mp.iter().map(|c| c[0]).collect::<Vec<_>>()), tf(grp_normal), tf(fld_normal));
        assert!(by_kernel == by_average && by_average == 8 / h.len() && by_average == orbit.len());
        assert!(grp_normal == fld_normal && rational(&mp));
    }
    let distinct: BTreeSet<&String> = fields.iter().map(|x| &x.1).collect();
    println!("subgroups {} of 256 subsets, fields {}, normal {}", subs.len(), distinct.len(), normals);
    // ---- recover a field: start from Q(√2), find the symmetries fixing it, take their fixed field
    let fix_r2: Vec<Gp> = g_all.iter().cloned().filter(|&g| apply(g, &e(&[(2, 1)])) == e(&[(2, 1)])).collect();
    println!("Gal(L/Q(√2)) = {}, order {}; its fixed field is Q({}), degree {}", names(&fix_r2),
             fix_r2.len(), label(&fields, &fix_r2), 8 / fix_r2.len());
    // ---- what breaks
    let root = |k: usize| e(&[(1 + 4 * (k % 2), if k / 2 == 0 { 1 } else { -1 })]);
    let real_roots = (0..4).filter(|&k| apply((0, 3), &root(k)) == root(k)).count();
    let above_a: Vec<&Vec<Gp>> = subs.iter().filter(|h| h.contains(&(0, 3))).collect();
    println!("Q(α) alone: degree 4, roots of x^4 - 2 inside it {}, so automorphisms {}; its subgroups 2, but fields between Q and Q(α) {}",
             real_roots, real_roots, above_a.len());
    println!("sizes swapped: H = {{1,τ}} would give degree {}, true degree {}", above_a[0].len(), 8 / above_a[0].len());
    let (s2, s) = (subs.iter().find(|h| h.len() == 2 && h.contains(&(2, 1))).unwrap(),
                   subs.iter().find(|h| h.contains(&(1, 1))).unwrap());
    println!("bigger group, smaller field: {{1,σ²}} of order 2 fixes Q({}), degree 4; <σ> of order 4 fixes Q({}) of degree 2",
             label(&fields, s2), label(&fields, s));
    let moved: BTreeSet<String> = g_all.iter().map(|&g| label(&fields,
        &above_a[0].iter().map(|&x| compose(compose(g, x), inv(g))).collect())).collect();
    println!("non-normal {{1,τ}}: the symmetries carry Q(α) to {} fields [{}]", moved.len(),
             moved.iter().map(|x| format!("'{}'", x)).collect::<Vec<_>>().join(", "));
    // ---- a count against the group: roots of x^4 - 2 mod p, odd primes below 10,000
    let (n, mut tally) = (10000usize, [0usize; 5]); let mut sieve = vec![true; n];
    for p in 2..100 { if sieve[p] { let mut q = p * p; while q < n { sieve[q] = false; q += p; } } }
    for p in 3..n {
        if !sieve[p] { continue; } let sq: Vec<usize> = (0..p).map(|x| x * x % p).collect();
        tally[(0..p).filter(|&x| sq[sq[x]] == 2 % p).count()] += 1; }
    let fixed: Vec<usize> = g_all.iter().map(|&g| (0..4).filter(|&k| (g.1 * k + g.0).rem_euclid(4) == k).count()).collect();
    let pred: Vec<usize> = (0..5).map(|c| fixed.iter().filter(|&&f| f == c).count()).collect();
    println!("roots fixed by each symmetry {}: shares 0,1,2,3,4 roots = {} out of 8", list(&fixed), list(&pred));
    let total: usize = tally.iter().sum();
    println!("odd primes below 10,000: {},{:03}; with 0,1,2,3,4 roots of x^4 - 2: {}", total / 1000, total % 1000, list(&tally));
    println!("shares found {}; predicted {}",
             tally.iter().map(|&t| format!("{:.4}", t as f64 / total as f64)).collect::<Vec<_>>().join(", "),
             pred.iter().map(|&q| format!("{:.4}", q as f64 / 8.0)).collect::<Vec<_>>().join(", "));
    assert!(g_all.len() == 8 && keep.len() == 8 && on_roots == keep && conj.len() == 8 && subs.len() == 10 && normals == 6);
    assert!(fix_r2.len() == 4 && label(&fields, &fix_r2) == "√2" && real_roots == 2);
    assert!(tally.iter().zip(&pred).all(|(&t, &q)| (t as f64 / total as f64 - q as f64 / 8.0).abs() < 0.03));
    println!("ALL CHECKS PASS");
}
