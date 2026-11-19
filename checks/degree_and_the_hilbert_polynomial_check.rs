// Degree and the Hilbert polynomial -- the same check as the Python, in Rust.
// No crates.  Fractions are an i128 struct using checked_mul and checked_add, so overflow stops the run.
// The twisted cubic (u, u^2, u^3) is the projective curve (x : y : z : w) = (a^2 b : a b^2 : b^3 : a^3).
// Road 1: HF(t) = monomials of degree t minus the rank of the ideal's degree-t part.
// Road 2: substitute the curve and count the distinct monomials a^i b^j it reaches.
// Road 3: count standard monomials, those outside the leading terms x^2, xy, y^2.
// Then planes slice the curve, and Hilbert polynomials are fitted and read.
use std::collections::BTreeSet;
use std::fmt;
#[derive(Clone, Copy, PartialEq, Debug)]
struct Q { n: i128, d: i128 }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d).max(1); let s = if d < 0 { -1 } else { 1 }; Q { n: s * n / g, d: s * d / g } }
fn m(a: i128, b: i128) -> i128 { a.checked_mul(b).expect("overflow") }
fn add(a: Q, b: Q) -> Q { q(m(a.n, b.d).checked_add(m(b.n, a.d)).expect("overflow"), m(a.d, b.d)) }
fn sub(a: Q, b: Q) -> Q { add(a, Q { n: -b.n, d: b.d }) }
fn mul(a: Q, b: Q) -> Q { q(m(a.n, b.n), m(a.d, b.d)) }
fn div(a: Q, b: Q) -> Q { assert!(b.n != 0); q(m(a.n, b.d), m(a.d, b.n)) }
fn i(n: i128) -> Q { Q { n, d: 1 } }
impl fmt::Display for Q { fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
    if self.d == 1 { write!(f, "{}", self.n) } else { write!(f, "{}/{}", self.n, self.d) } } }
type Mono = Vec<i64>;
type Poly = Vec<(Mono, i128)>;
fn monos(n: usize, t: i64) -> Vec<Mono> {
    if n == 1 { return vec![vec![t]]; }
    (0..=t).rev().flat_map(|a| monos(n - 1, t - a).into_iter().map(move |r| [vec![a], r].concat())).collect()
}
fn grevlex(e: &Mono) -> (i64, Vec<i64>) { (e.iter().sum(), e.iter().rev().map(|c| -c).collect()) }
fn deg(p: &Poly) -> i64 { p[0].0.iter().sum() }
fn pivots(cols: &[Mono], rows: Vec<Vec<Q>>) -> Vec<Mono> {   // exact row reduction; leading columns
    let mut rows = rows; let mut piv: Vec<Mono> = vec![];
    for j in 0..cols.len() {
        let r = piv.len();
        let k = match (r..rows.len()).find(|&k| rows[k][j].n != 0) { Some(k) => k, None => continue };
        rows.swap(r, k); piv.push(cols[j].clone());
        for x in r + 1..rows.len() {
            if rows[x][j].n == 0 { continue; }
            let (f, base) = (div(rows[x][j], rows[r][j]), rows[r].clone());
            for (a, b) in rows[x].iter_mut().zip(base.iter()) { *a = sub(*a, mul(f, *b)); }
        }
    }
    piv
}
fn ideal_piece(gens: &[Poly], n: usize, t: i64) -> (Vec<Mono>, Vec<Mono>) {
    let mut cols = monos(n, t); cols.sort_by(|a, b| grevlex(b).cmp(&grevlex(a)));
    let mut rows = vec![];
    for g in gens { if deg(g) <= t { for mm in monos(n, t - deg(g)) {
        let mut row = vec![i(0); cols.len()];
        for (e, c) in g { let s: Mono = e.iter().zip(&mm).map(|(a, b)| a + b).collect();
            let k = cols.iter().position(|x| *x == s).unwrap(); row[k] = add(row[k], i(*c)); }
        rows.push(row);
    } } }
    let piv = pivots(&cols, rows); (cols, piv)
}
fn hf(gens: &[Poly], n: usize, t: i64) -> usize { let (c, p) = ideal_piece(gens, n, t); c.len() - p.len() }
fn fit(ts: &[i64], vs: &[usize]) -> Vec<Q> {          // Lagrange interpolation, lowest degree first
    let mut out = vec![i(0); ts.len()];
    for (&ti, &vi) in ts.iter().zip(vs) {
        let (mut b, mut den) = (vec![i(1)], i(1));
        for &tj in ts { if tj != ti {
            b = (0..=b.len()).map(|k| sub(if k > 0 { b[k - 1] } else { i(0) }, mul(i(tj as i128), if k < b.len() { b[k] } else { i(0) }))).collect();
            den = mul(den, i((ti - tj) as i128));
        } }
        for k in 0..out.len() { out[k] = add(out[k], div(mul(i(vi as i128), b[k]), den)); }
    }
    while out.len() > 1 && out[out.len() - 1].n == 0 { out.pop(); }
    out
}
fn show(p: &[Q]) -> String {
    let mut s = String::new();
    for k in (0..p.len()).rev() {
        let (c, a) = (p[k], Q { n: p[k].n.abs(), d: p[k].d }); if c.n == 0 { continue; }
        let num = if a.n == 1 && a.d == 1 && k > 0 { String::new() } else if a.d == 1 { a.to_string() } else { format!("({})", a) };
        let tp = if k > 1 { format!("t^{}", k) } else if k == 1 { "t".to_string() } else { String::new() };
        s += &format!("{}{}{}", if c.n < 0 { " - " } else { " + " }, num, tp);
    }
    if s.is_empty() { "0".into() } else if s.starts_with(" + ") { s[3..].to_string() } else { format!("-{}", &s[3..]) }
}
fn at(p: &[Q], t: i128) -> Q { p.iter().rev().fold(i(0), |acc, &c| add(mul(acc, i(t)), c)) }
fn ls<T: fmt::Display>(v: &[T]) -> String { format!("[{}]", v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ")) }
fn image(e: &Mono) -> (i64, i64) { (2 * e[0] + e[1] + 3 * e[3], e[0] + 2 * e[1] + 3 * e[2]) }
fn pl(t: &[(&[i64], i128)]) -> Poly { t.iter().map(|(e, c)| (e.to_vec(), *c)).collect() }
fn ldiv(p: &[Q], r: i128) -> (Vec<Q>, bool) {          // divide by (u - r) if r is a root
    let mut qv = vec![]; let mut acc = i(0);
    for &c in p.iter().rev() { acc = add(mul(acc, i(r)), c); qv.push(acc); }
    if acc.n == 0 { let mut o: Vec<Q> = qv[..qv.len() - 1].to_vec(); o.reverse(); (o, true) } else { (p.to_vec(), false) }
}
fn main() {
    let (x2, xy) = (pl(&[(&[2, 0, 0, 0], 1), (&[0, 1, 0, 1], -1)]), pl(&[(&[1, 1, 0, 0], 1), (&[0, 0, 1, 1], -1)]));
    let tc = vec![x2.clone(), xy.clone(), pl(&[(&[0, 2, 0, 0], 1), (&[1, 0, 1, 0], -1)])];
    println!("twisted cubic (u, u^2, u^3) = (x : y : z : w) = (a^2 b : a b^2 : b^3 : a^3); field Q, counts as over C");
    let vanish = tc.iter().all(|g| g.iter().all(|(e0, _)| g.iter().filter(|(e, _)| image(e) == image(e0)).map(|(_, c)| c).sum::<i128>() == 0));
    println!("equations x^2 - yw, xy - zw, y^2 - xz; each vanishes on the curve: {}", if vanish { "yes" } else { "no" });
    println!("t | monomials | ideal I_t | HF = monomials - ideal | images a^i b^j | standard monomials");
    let mut h: Vec<usize> = vec![];
    for t in 0..8 {
        let (cols, piv) = ideal_piece(&tc, 4, t);
        let ims: BTreeSet<(i64, i64)> = cols.iter().map(image).collect();
        let std: BTreeSet<Mono> = cols.iter().filter(|e| e[0] + e[1] <= 1).cloned().collect();
        assert!(piv.iter().cloned().collect::<BTreeSet<Mono>>() == cols.iter().filter(|e| !std.contains(*e)).cloned().collect());
        h.push(cols.len() - piv.len());
        println!("{} | {} | {} | {} | {} | {}", t, cols.len(), piv.len(), h[t as usize], ims.len(), std.len());
        assert!(cols.len() == ((t + 1) * (t + 2) * (t + 3) / 6) as usize && h[t as usize] == ims.len() && ims.len() == std.len());
    }
    let ts: Vec<i64> = (3..7).collect(); let hp = fit(&ts, &h[3..7]);
    println!("HP fitted through t = 3..6: {}; predicts HF(7) = {}, computed {}", show(&hp), at(&hp, 7), h[7]);
    println!("read off: dimension = degree of HP = {}; degree = leading coefficient x 1! = {}", hp.len() - 1, hp[hp.len() - 1]);
    assert!(hp == vec![i(1), i(3)] && at(&hp, 7) == i(h[7] as i128));
    let planes: [(&str, [i128; 4]); 5] = [("11x - 6y + z - 6w", [11, -6, 1, -6]), ("z - 8w, a slicer layer", [0, 0, 1, -8]),
        ("x = 0", [1, 0, 0, 0]), ("5x - 4y + z - 2w, tangent", [5, -4, 1, -2]), ("z = 0, triple touch", [0, 0, 1, 0])];
    let mut res: Vec<(Vec<i128>, Vec<Q>, usize)> = vec![];
    for (name, hv) in planes.iter() {
        let mut p: Vec<Q> = [hv[3], hv[0], hv[1], hv[2]].iter().map(|&c| i(c)).collect();
        while p[p.len() - 1].n == 0 { p.pop(); } let (inf, mut roots) = (3 - (p.len() - 1), vec![]);
        for r in -30..31i128 { let mut ok = true;
            while ok && p.len() > 1 { let (np, o) = ldiv(&p, r); p = np; ok = o; if ok { roots.push(r); } } }
        let left = p.len() - 1; let mut g = tc.clone();
        g.push((0..4).map(|k| { let mut e = vec![0; 4]; e[k] = 1; (e, hv[k]) }).collect());
        let sl: Vec<usize> = (0..5).map(|t| hf(&g, 4, t)).collect();
        println!("plane {}: rational roots u = {}; other complex {}; at infinity {}; total {}; slice HF t = 0..4: {}",
            name, ls(&roots), left, inf, roots.len() + left + inf, ls(&sl));
        assert!(roots.len() + left + inf == 3 && sl[1..] == [3, 3, 3, 3]);
        res.push((roots, p, inf));
    }
    let pts: Vec<[i128; 4]> = [1i128, 2, 3].iter().map(|&u| [u, u * u, u * u * u, 1]).collect();
    let ev: Vec<usize> = (1..5).map(|t| { let cols = monos(4, t);
        let rows = pts.iter().map(|p| cols.iter().map(|e| i((0..4).map(|k| p[k].pow(e[k] as u32)).product())).collect()).collect();
        pivots(&cols, rows).len() }).collect();
    println!("points (1, 1, 1), (2, 4, 8), (3, 9, 27): degree-t forms separate them, rank t = 1..4: {}", ls(&ev));
    assert!(ev == vec![3, 3, 3, 3]);
    let mut s: u64 = 2026;
    let mut splitmix = || { s = s.wrapping_add(0x9E3779B97F4A7C15); let mut z = s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9); z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB); z ^ (z >> 31) };
    let mut cnt = [0usize; 4]; for _ in 0..1000 {
        let hv: Vec<i128> = (0..4).map(|_| (splitmix() % 19) as i128 - 9).collect(); let (d, c, b, a) = (hv[3], hv[0], hv[1], hv[2]);
        let dd = 18 * a * b * c * d - 4 * b.pow(3) * d + b * b * c * c - 4 * a * c.pow(3) - 27 * a * a * d * d;
        cnt[if hv.iter().all(|&v| v == 0) { 3 } else if dd > 0 { 0 } else if dd < 0 { 1 } else { 2 }] += 1; // Sylvester: F_u, F_v
        let syl = [[3 * a, 2 * b, c, 0], [0, 3 * a, 2 * b, c], [b, 2 * c, 3 * d, 0], [0, b, 2 * c, 3 * d]].iter().map(|r| r.iter().map(|&v| i(v)).collect()).collect();
        assert!((pivots(&monos(4, 1), syl).len() < 4) == (dd == 0)); }
    println!("1000 random planes, SplitMix64 seed 2026, coefficients -9..9: three real {}, one real {}, repeated {}, zero plane {}", cnt[0], cnt[1], cnt[2], cnt[3]);
    assert!(cnt.iter().sum::<usize>() == 1000 && cnt[3] == 0);
    let cone = vec![pl(&[(&[2, 0, 0, 0], 1), (&[0, 2, 0, 0], 1), (&[0, 0, 2, 0], -1)])];
    let mut cs = cone.clone(); cs.push(pl(&[(&[0, 0, 1, 0], 1), (&[0, 0, 0, 1], -1)]));
    let models: Vec<(&str, Vec<Poly>, usize)> = vec![("P^3, no equations", vec![], 4), ("twisted cubic", tc.clone(), 4),
        ("cone x^2 + y^2 = z^2 in P^3", cone, 4), ("its slice z = w, a conic", cs, 4),
        ("plane cubic y^2 z = x^3 - x z^2", vec![pl(&[(&[0, 2, 1], 1), (&[3, 0, 0], -1), (&[1, 0, 2], 1)])], 3),
        ("two quadrics x^2 - yw, xy - zw", vec![x2, xy], 4)];
    let mut got: Vec<(Q, Vec<usize>, Q)> = vec![];
    for (k, (name, gens, n)) in models.iter().enumerate() {
        let v: Vec<usize> = if k == 1 { h.clone() } else { (0..8).map(|t| hf(gens, *n, t)).collect() };
        let p = fit(&ts, &v[3..7]); let d = p.len() - 1;
        assert!(at(&p, 7) == i(v[7] as i128));
        let dg = mul(p[d], i((1..=d as i128).product())); got.push((dg, v.clone(), p[d]));
        println!("{}: HF t = 0..7 {}; HP {}; dim {}; degree {}", name, ls(&v), show(&p), d, dg);
    }
    assert!(got.iter().map(|g| g.0).collect::<Vec<Q>>() == vec![i(1), i(3), i(2), i(2), i(3), i(4)] && got[4].1[0] == 1);
    let (rb, qb) = (&res[1].0, &res[1].1); let (rc, ic) = (&res[2].0, res[2].2); let rd = &res[3].0;
    let qd = sub(mul(qb[1], qb[1]), mul(i(4), mul(qb[0], qb[2])));
    println!("mistake 1, real points only: plane z = 8w, real roots {}, leftover u^2 + 2u + 4 has discriminant {}: {}, not 3", ls(rb), qd, rb.len());
    println!("mistake 2, affine chart only: plane x = 0 shows u = {} alone: {}, not 3; {} more lie at infinity", rc[0], rc.len(), ic);
    let dset: Vec<i128> = rd.iter().cloned().collect::<BTreeSet<i128>>().into_iter().collect();
    println!("mistake 3, distinct points only: the tangent plane shows u = {}: {}, not 3", ls(&dset), dset.len());
    assert!(qd.n < 0 && *qb == vec![i(4), i(2), i(1)] && rb.len() == 1 && rc.len() == 1 && dset.len() == 2 && res[4].0 == vec![0, 0, 0]);
    println!("mistake 4, drop y^2 - xz: degree {}, not 3; the line x = w = 0 joins in", got[5].0);
    println!("mistake 5, cone's leading coefficient as degree: {}, not {}; forgot the 2!", got[2].2, got[2].0);
    let mons: Vec<usize> = (0..7).map(|t| (t + 1) * (t + 2) * (t + 3) / 6).collect();
    let idl: Vec<usize> = (0..7).map(|t| mons[t] - h[t]).collect(); // the chart's three lines
    println!("chart, t = 0..6: monomials {}; ideal {}; HF {}", ls(&mons), ls(&idl), ls(&h[..7]));
    println!("ALL CHECKS PASS");
}
