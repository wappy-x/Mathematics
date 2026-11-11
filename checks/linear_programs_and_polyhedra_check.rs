// Linear programs and polyhedra -- the same check as the Python, in Rust.  No
// crates: a small exact fraction type is written out below.  A workshop makes x1
// tables and x2 chairs a week and maximises profit 19 x1 + 20 x2 pounds, limited
// by timber, labour and finish.  The corners are found by two roads that share
// no code: crossing the picture's boundary lines two at a time, and choosing 3
// basic columns of the standard form A x = b, x >= 0.  Faces follow from tightness.
use std::cmp::Ordering;
use std::ops::{Add, Div, Mul, Sub};
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
struct Q { n: i64, d: i64 }                              // n / d, d > 0, lowest terms
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i64, d: i64) -> Q { let g = gcd(n, d) * d.signum(); Q { n: n / g, d: d / g } }
fn z(n: i64) -> Q { q(n, 1) }
impl Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.n * o.d + o.n * self.d, self.d * o.d) } }
impl Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { q(self.n * o.d - o.n * self.d, self.d * o.d) } }
impl Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.n * o.n, self.d * o.d) } }
impl Div for Q { type Output = Q; fn div(self, o: Q) -> Q { q(self.n * o.d, self.d * o.n) } }
impl Ord for Q { fn cmp(&self, o: &Q) -> Ordering { (self.n * o.d).cmp(&(o.n * self.d)) } }
impl PartialOrd for Q { fn partial_cmp(&self, o: &Q) -> Option<Ordering> { Some(self.cmp(o)) } }
type P = (Q, Q);
const NAME: [&str; 5] = ["x1", "x2", "s1", "s2", "s3"];  // tables, chairs, 3 slacks
const A: [[i64; 5]; 3] = [[4, 2, 1, 0, 0], [3, 1, 0, 1, 0], [1, 2, 0, 0, 1]];
const B: [i64; 3] = [160, 120, 64];

fn fmt(v: Q) -> String {                                 // exact: a short decimal, else a fraction
    let mut k = 0u32;
    while (v.n.abs() * 10i64.pow(k)) % v.d != 0 && k < 4 { k += 1 }
    if (v.n.abs() * 10i64.pow(k)) % v.d != 0 { return format!("{}/{}", v.n, v.d) }
    let s = format!("{:0>w$}", v.n.abs() * 10i64.pow(k) / v.d, w = k as usize + 1);
    let body = if k > 0 { format!("{}.{}", &s[..s.len() - k as usize], &s[s.len() - k as usize..]) } else { s };
    format!("{}{}", if v.n < 0 { "-" } else { "" }, body)
}
fn pt(p: &[Q]) -> String { format!("({})", p.iter().map(|&v| fmt(v)).collect::<Vec<_>>().join(", ")) }
fn pp(p: P) -> String { pt(&[p.0, p.1]) }
fn value(p: P, w: [i64; 2]) -> Q { z(w[0]) * p.0 + z(w[1]) * p.1 }
fn lhs(g: [i64; 2], p: P) -> Q { z(g[0]) * p.0 + z(g[1]) * p.1 }
fn inside(p: P, gs: &[([i64; 2], i64)]) -> bool { gs.iter().all(|&(g, h)| lhs(g, p) <= z(h)) }
fn crossings(gs: &[([i64; 2], i64)]) -> Vec<P> {         // road 1: two boundary lines at a time
    let mut pts = Vec::new();
    for i in 0..5 { for j in i + 1..5 {
        let ((a, h), (c, k)) = (gs[i], gs[j]);
        let det = a[0] * c[1] - a[1] * c[0];
        if det != 0 { pts.push((q(h * c[1] - a[1] * k, det), q(a[0] * k - h * c[0], det))) }
    } }
    pts
}
fn solve(m: Vec<Vec<i64>>, r: &[i64]) -> Option<Vec<Q>> { // Gaussian elimination, exact
    let n = m.len();
    let mut m: Vec<Vec<Q>> = m.iter().zip(r).map(|(row, &x)| row.iter().map(|&v| z(v)).chain([z(x)]).collect()).collect();
    for col in 0..n {
        let piv = (col..n).find(|&i| m[i][col] != z(0))?;
        m.swap(col, piv);
        for i in 0..n { if i != col {
            let f = m[i][col] / m[col][col];
            let pivot_row = m[col].clone();
            for (a, b) in m[i].iter_mut().zip(pivot_row) { *a = *a - f * b }
        } }
    }
    Some((0..n).map(|i| m[i][n] / m[i][i]).collect())
}
fn basics(b: &[i64]) -> Vec<([usize; 3], [Q; 5])> {     // road 2: 3 basic columns at a time
    let mut out = Vec::new();
    for i in 0..5 { for j in i + 1..5 { for k in j + 1..5 {
        let mut x = [z(0); 5];
        for (c, v) in [i, j, k].iter().zip(solve(A.iter().map(|row| vec![row[i], row[j], row[k]]).collect(), b).unwrap()) { x[*c] = v }
        out.push(([i, j, k], x));
    } } }
    out
}
fn uniq(mut v: Vec<P>) -> Vec<P> { v.sort(); v.dedup(); v }
fn join(v: &[P], sep: &str) -> String { v.iter().map(|&p| pp(p)).collect::<Vec<_>>().join(sep) }

fn main() {
    let g: Vec<([i64; 2], i64)> = vec![([-1, 0], 0), ([0, -1], 0), ([4, 2], 160), ([3, 1], 120), ([1, 2], 64)];
    println!("maximise 19 x1 + 20 x2 pounds; timber {} m, labour {} h, finish {} litres", B[0], B[1], B[2]);
    println!("standard form: minimise c.x, c = (-19, -20, 0, 0, 0), x = (x1, x2, s1, s2, s3)");
    let pts = crossings(&g);
    let corners = uniq(pts.iter().copied().filter(|&p| inside(p, &g)).collect());
    println!("road 1: {} line crossings, {} distinct points, {} feasible", pts.len(), uniq(pts.clone()).len(), corners.len());
    let mut bases: Vec<P> = Vec::new();
    for (cols, x) in basics(&B) {
        let ok = x.iter().all(|&v| v >= z(0));
        if ok { bases.push((x[0], x[1])) }
        println!("basis {} {} {}: x = {}  {}", NAME[cols[0]], NAME[cols[1]], NAME[cols[2]], pt(&x), if ok { "corner" } else { "infeasible" });
    }
    println!("road 2: 10 bases, {} feasible, {} distinct corners", bases.len(), uniq(bases.clone()).len());
    println!("corners, both roads: {}", join(&corners, " "));
    let tight = |p: P| -> Vec<usize> { (0..5).filter(|&k| lhs(g[k].0, p) == z(g[k].1)).collect() };
    let (mut faces, mut hit): (Vec<(Vec<P>, Vec<usize>)>, usize) = (Vec::new(), 0);
    for mask in 0..32 {                                   // every set of limits made tight
        let vs: Vec<P> = corners.iter().copied().filter(|&v| (0..5).all(|k| mask >> k & 1 == 0 || tight(v).contains(&k))).collect();
        if !vs.is_empty() { hit += 1 }
        if vs.is_empty() || faces.iter().any(|f| f.0 == vs) { continue }
        let common = (0..5).filter(|k| vs.iter().all(|&v| tight(v).contains(k))).collect();
        faces.push((vs, common));
    }
    faces.sort_by(|a, b| (a.0.len(), &a.0).cmp(&(b.0.len(), &b.0)));
    println!("faces: 32 sets of walls made tight, {} distinct non-empty faces", faces.len());
    for (vs, zero) in &faces {
        let zs = if zero.is_empty() { "none".to_string() } else { zero.iter().map(|&k| NAME[k]).collect::<Vec<_>>().join(" ") };
        println!("face, dim {}: {:<22} zero: {}", (vs.len() - 1).min(2), join(vs, " "), zs);
    }
    let lab: Vec<P> = corners.iter().copied().filter(|&v| tight(v).contains(&3)).collect();
    let red: Vec<Q> = (0..2).map(|i| q(3, 4) * z(g[2].0[i]) + q(1, 2) * z(g[1].0[i])).collect();
    println!("labour tight only at {}; 3/4 timber + 1/2 (x2 >= 0): {} x1 + {} x2 <= {}", join(&lab, " "), fmt(red[0]), fmt(red[1]), fmt(q(3, 4) * z(B[0])));
    let best = *corners.iter().max_by_key(|&&p| value(p, [19, 20])).unwrap();
    let y = [3, 0, 7];                                    // prices on timber, labour, finish
    let ya: Vec<Q> = (0..5).map(|c| z((0..3).map(|r| y[r] * A[r][c]).sum())).collect();
    let bound: i64 = (0..3).map(|r| y[r] * B[r]).sum();
    let mut grid = z(0);
    for a in 0..65 { for b in 0..81 { let p = (z(a), z(b)); if inside(p, &g) && value(p, [19, 20]) > grid { grid = value(p, [19, 20]) } } }
    println!("profit at corners: {}", corners.iter().map(|&v| format!("{} {}", pp(v), fmt(value(v, [19, 20])))).collect::<Vec<_>>().join(", "));
    println!("best: {}, {} pounds; standard-form p* = {}", pp(best), fmt(value(best, [19, 20])), fmt(z(0) - value(best, [19, 20])));
    println!("certificate y = (3, 0, 7): y.A = {}, y.b = {}; whole-number grid best {}", pt(&ya), bound, fmt(grid));
    let top = corners.iter().map(|&u| value(u, [19, 38])).max().unwrap();
    let tie: Vec<P> = corners.iter().copied().filter(|&v| value(v, [19, 38]) == top).collect();
    println!("chairs at 38: best set {}, {} each: the finish edge", join(&tie, " to "), fmt(top));
    let mut flip = g.clone();                             // mistake 1: surplus on timber
    flip[2] = ([-4, -2], -160);
    let fc: Vec<P> = crossings(&flip).into_iter().filter(|&p| inside(p, &flip)).collect();
    let fb = *fc.iter().max_by_key(|&&p| value(p, [19, 20])).unwrap();
    let edges = (0..5).filter(|&k| corners.iter().filter(|&&v| tight(v).contains(&k)).count() > 1).count(); // mistake 2
    let eq = solve(vec![vec![4, 2], vec![3, 1]], &B[..2]).unwrap();         // mistake 4
    println!("mistake, timber slack signed as surplus: {}, {}, uses {} m", pp(fb), fmt(value(fb, [19, 20])), fmt(lhs([4, 2], fb)));
    println!("mistake, one edge per wall: {} claimed, {} walls tight along an edge, labour at {} corner", g.len(), edges, lab.len());
    println!("mistake, every set of walls counted as a face: 32, but {} are empty and {} give {} faces", 32 - hit, hit, faces.len());
    println!("mistake, no slacks: timber and labour force {}, finish {} not 64", pt(&eq), fmt(lhs([1, 2], (eq[0], eq[1]))));
    let ends: Vec<String> = ["timber", "labour", "finish"].iter().zip(&g[2..]).zip([45, 45, 32])   // where each
        .map(|((nm, &(a, h)), top)| format!("{} {}-{}", nm, pp((q(h - a[1] * top, a[0]), z(top))), pp((q(h, a[0]), z(0))))).collect();
    println!("figure, corners {}; {}; 928 line {}-{}", join(&corners, " "), ends.join("; "),   // line leaves the box
             pp((z(16), q(928 - 19 * 16, 20))), pp((z(48), q(928 - 19 * 48, 20))));
    for h in [130i64, 110] {                              // Try changing: move the labour wall
        let mut gt = g.clone(); gt[3].1 = h;
        let ct = uniq(crossings(&gt).into_iter().filter(|&p| inside(p, &gt)).collect());
        let on = |k: usize| { let v: Vec<P> = ct.iter().copied().filter(|&p| lhs(gt[k].0, p) == z(gt[k].1)).collect(); if v.is_empty() { "none".to_string() } else { join(&v, " ") } };
        let bt = *ct.iter().max_by_key(|&&p| value(p, [19, 20])).unwrap();
        let nb = basics(&[160, h, 64]).iter().filter(|(_, x)| x.iter().all(|&v| v >= z(0))).count();
        println!("try labour {} h: {} feasible bases, {} corners; labour tight at {}; timber at {}; best {}, {}", h, nb, ct.len(), on(3), on(2), pp(bt), fmt(value(bt, [19, 20])));
    }
    let dear = *corners.iter().max_by_key(|&&p| value(p, [19, 40])).unwrap();
    println!("try chairs at 40: best {}, {}; prices (3, 0, 7) value a chair at {}", pp(dear), fmt(value(dear, [19, 40])), fmt(ya[1]));
    assert!(corners == uniq(bases.clone()) && corners.len() == 4);               // two roads, one shape
    assert!(ya[..2] == [z(19), z(20)] && ya[2..].iter().all(|&v| v >= z(0)) && z(bound) == value(best, [19, 20]) && grid == z(928) && bound == 928);
    assert!(red == vec![z(3), z(1)] && q(3, 4) * z(B[0]) == z(B[1]) && lab == vec![(z(40), z(0))]);   // labour is redundant
    let fin = faces.iter().find(|f| f.0 == tie).unwrap();
    assert!(fin.1 == vec![4] && faces.len() == 9 && hit == 13 && edges == 4 && fb == (q(176, 5), q(72, 5)));
    println!("ALL CHECKS PASS");
}
