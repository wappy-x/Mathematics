// Separating hyperplanes -- the same check as the Python, in Rust.  No crates;
// a small rational type does the exact arithmetic.  Each bean is a point
// (caffeine in g/kg, cost in pounds/kg); a blend mixes them with weights >= 0
// adding to 1.  The spec, 18 g/kg at 5.50 a kilo, is shown out of reach three
// ways: the closest-point wall, every blend on a 1/360 grid, and Farkas'
// certificate against the blend equations.  Then four ways to go wrong.
use std::cmp::Ordering;
use std::ops::{Add, Div, Mul, Sub};

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
struct Q { n: i128, d: i128 }                       // n/d in lowest terms, d > 0
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q {
    let g = gcd(n, d) * if d < 0 { -1 } else { 1 };
    Q { n: n / g, d: d / g }
}
fn z(n: i128) -> Q { q(n, 1) }
impl Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.n * o.d + o.n * self.d, self.d * o.d) } }
impl Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { q(self.n * o.d - o.n * self.d, self.d * o.d) } }
impl Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.n * o.n, self.d * o.d) } }
impl Div for Q { type Output = Q; fn div(self, o: Q) -> Q { q(self.n * o.d, self.d * o.n) } }
impl PartialOrd for Q { fn partial_cmp(&self, o: &Q) -> Option<Ordering> { Some(self.cmp(o)) } }
impl Ord for Q { fn cmp(&self, o: &Q) -> Ordering { (self.n * o.d).cmp(&(o.n * self.d)) } }
impl std::fmt::Display for Q {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        if self.d == 1 { write!(f, "{}", self.n) } else { write!(f, "{}/{}", self.n, self.d) }
    }
}
impl Q { fn f(self) -> f64 { self.n as f64 / self.d as f64 } }

type V = (Q, Q);
fn dot(u: V, v: V) -> Q { u.0 * v.0 + u.1 * v.1 }
fn sub(u: V, v: V) -> V { (u.0 - v.0, u.1 - v.1) }
fn pt(v: V) -> String { format!("({:.2}, {:.2})", v.0.f(), v.1.f()) }
fn fl(xs: &[Q]) -> String { xs.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ") }

fn nearest_on_edge(x: V, a: V, b: V) -> (Q, V) {   // minimise |a + t(b - a) - x|^2, 0 <= t <= 1
    let d = sub(b, a);
    let t = (dot(sub(x, a), d) / dot(d, d)).max(z(0)).min(z(1));
    (t, (a.0 + t * d.0, a.1 + t * d.1))
}

fn solve3(rows: &[[Q; 3]; 3], rhs: [Q; 3]) -> [Q; 3] {   // Gauss-Jordan elimination, exact
    let mut m: Vec<Vec<Q>> = (0..3).map(|r| { let mut v = rows[r].to_vec(); v.push(rhs[r]); v }).collect();
    for c in 0..3 {
        let piv = (c..3).find(|&r| m[r][c] != z(0)).unwrap();
        m.swap(c, piv);
        for r in 0..3 {
            if r != c {
                let f = m[r][c] / m[c][c];
                let pivot_row = m[c].clone();
                for (x, y) in m[r].iter_mut().zip(pivot_row) { *x = *x - f * y; }
            }
        }
    }
    [m[0][3] / m[0][0], m[1][3] / m[1][1], m[2][3] / m[2][2]]
}
fn dot3(u: [Q; 3], v: [Q; 3]) -> Q { u[0] * v[0] + u[1] * v[1] + u[2] * v[2] }

fn main() {
    let names = ["Robusta", "Brazil", "Ethiopia"];
    let p: [V; 3] = [(z(22), z(5)), (z(13), z(8)), (z(11), z(14))];
    let (spec, easy, edge): (V, V, V) = ((z(18), q(11, 2)), (z(15), z(10)), (z(19), z(6)));
    let n: i128 = 360;                                      // grid step: 1/360 of a kilo
    let a_m = [[z(1), z(1), z(1)], [p[0].0, p[1].0, p[2].0], [p[0].1, p[1].1, p[2].1]];
    let col = |j: usize| [a_m[0][j], a_m[1][j], a_m[2][j]];

    println!("half Robusta, half Brazil: {}", pt(((p[0].0 + p[1].0) / z(2), (p[0].1 + p[1].1) / z(2))));
    // ---- road one: the closest blend, and the wall at right angles to it ----
    let mut best: Option<(Q, usize, usize, Q, V)> = None;
    for (i, j) in [(0, 1), (1, 2), (0, 2)] {
        let (t, c) = nearest_on_edge(spec, p[i], p[j]);
        let d2 = dot(sub(c, spec), sub(c, spec));
        if best.map_or(true, |b| d2 < b.0) { best = Some((d2, i, j, t, c)); }
    }
    let (d2, i, j, t, pc) = best.unwrap();
    let a = sub(pc, spec);                                  // normal: spec to closest blend
    let k = z(1) / a.0;                                     // rescale to whole numbers
    let y = (k * a.0, k * a.1);
    let (floor, spec_score) = (k * dot(a, pc), dot(y, spec));
    let bean_scores: Vec<Q> = p.iter().map(|&b| dot(y, b)).collect();
    println!("closest blend: {} {}, {} {}, at {}", names[i], z(1) - t, names[j], t, pt(pc));
    println!("squared distance {}, distance {:.4}", d2, d2.f().sqrt());
    println!("normal {}, scaled by {}: score = caffeine + {} x cost", pt(a), k, y.1);
    println!("bean scores {}; every blend >= {}", fl(&bean_scores), floor);
    println!("spec scores {:.1}; gap {:.1} = {} x {}; midway wall at {:.2}",
             spec_score.f(), (floor - spec_score).f(), k, d2, ((floor + spec_score) / z(2)).f());
    let (cheapest, strongest) = ((floor - spec.0) / y.1, floor - y.1 * spec.1);
    println!("price line: cost >= ({} - caffeine) / {}; at {} g/kg >= {} = {:.4}; at {} a kilo, caffeine >= {}",
             floor, y.1, spec.0, cheapest, cheapest.f(), spec.1.f(), strongest.f());

    // ---- road two: every blend on a 1/360 grid, in exact fractions ----
    let mut best_d: Option<(Q, i128, i128, i128)> = None;
    let (mut best_s, mut best_c): (Option<Q>, Option<(Q, i128, i128, i128)>) = (None, None);
    let (mut count, mut hits) = (0, 0);
    for r in 0..=n {
        for b in 0..=(n - r) {
            let mix = [q(r, n), q(b, n), q(n - r - b, n)];
            let x = (dot3(mix, a_m[1]), dot3(mix, a_m[2]));  // the blend's caffeine and cost
            let (dd, s) = (dot(sub(x, spec), sub(x, spec)), dot(y, x));
            count += 1;
            if dd == z(0) { hits += 1; }
            if best_d.map_or(true, |c| dd < c.0) { best_d = Some((dd, r, b, n - r - b)); }
            if best_s.map_or(true, |c| s < c) { best_s = Some(s); }
            if x.0 == spec.0 && best_c.map_or(true, |c| x.1 < c.0) { best_c = Some((x.1, r, b, n - r - b)); }
        }
    }
    let (best_d, best_s) = (best_d.unwrap(), best_s.unwrap());
    let (best_c, grid_d2) = (best_c.unwrap(), best_d.0);
    println!("grid: {} blends, {} hit the spec; closest ({}, {}, {}) / {}, squared distance {}",
             count, hits, best_d.1, best_d.2, best_d.3, n, grid_d2);
    println!("grid: lowest score {}; cheapest at exactly {} g/kg ({}, {}, {}) / {}, cost {}",
             best_s, spec.0, best_c.1, best_c.2, best_c.3, n, best_c.0);

    // ---- road three: Farkas, either a recipe with weights >= 0 or a certificate ----
    let w = solve3(&a_m, [z(1), spec.0, spec.1]);
    let cert = [z(0) - floor, y.0, y.1];
    let at_cert: Vec<Q> = (0..3).map(|j| dot3(cert, col(j))).collect();
    let by_spec = dot3(cert, [z(1), spec.0, spec.1]);
    println!("the only mix with exact numbers: {}; Ethiopia {:.5}", fl(&w), w[2].f());
    println!("certificate y = ({}): A^T y = ({}), b.y = {:.1}", fl(&cert), fl(&at_cert), by_spec.f());
    let w_easy = solve3(&a_m, [z(1), easy.0, easy.1]);
    let by_easy = dot3(cert, [z(1), easy.0, easy.1]);
    println!("reachable spec {}: weights {}, b.y = {}", pt(easy), fl(&w_easy), by_easy);

    // ---- what breaks ----
    let lo = |m: usize| p.iter().map(|v| if m == 0 { v.0 } else { v.1 }).min().unwrap();
    let hi = |m: usize| p.iter().map(|v| if m == 0 { v.0 } else { v.1 }).max().unwrap();
    println!("mistake 1, one number at a time: caffeine {} in [{}, {}], cost {} in [{}, {}]: both pass",
             spec.0, lo(0), hi(0), spec.1.f(), lo(1), hi(1));
    let nb = (0..3).min_by_key(|&m| dot(sub(p[m], spec), sub(p[m], spec))).unwrap();
    let zz = (z(2) * (p[nb].0 - spec.0), z(2) * (p[nb].1 - spec.1));
    let z_scores: Vec<Q> = p.iter().map(|&b| dot(zz, b)).collect();
    println!("mistake 2, wall from nearest bean {}: normal {}, beans {}, spec {:.1}",
             names[nb], pt(zz), fl(&z_scores), dot(zz, spec).f());
    let mut gaps: Vec<f64> = Vec::new();
    for deg in 0..360 {
        let u = ((deg as f64).to_radians().cos(), (deg as f64).to_radians().sin());
        gaps.push(p.iter().map(|&b| { let s = sub(b, easy); 0.0 + u.0 * s.0.f() + u.1 * s.1.f() })
                  .fold(f64::INFINITY, f64::min));
    }
    let max_gap = gaps.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
    println!("mistake 3, single origins only, spec {}: best gap over 360 directions {:.4}", pt(easy), max_gap);
    let edge_w = solve3(&a_m, [z(1), edge.0, edge.1]);
    let mut dists: Vec<f64> = Vec::new();
    for eps in [q(1, 10), q(1, 100), q(1, 1000)] {
        let mix: Vec<Q> = (0..3).map(|m| (z(1) - eps) * edge_w[m] + eps / z(3)).collect();
        let c = (dot3([mix[0], mix[1], mix[2]], a_m[1]), dot3([mix[0], mix[1], mix[2]], a_m[2]));
        dists.push(dot(sub(c, edge), sub(c, edge)).f().sqrt());
    }
    let ds: Vec<String> = dists.iter().map(|x| format!("{:.4}", x)).collect();
    println!("mistake 4, all three beans required, spec {} = {}: distances {}; wall gap {}",
             pt(edge), fl(&edge_w), ds.join(", "), dot(y, edge) - floor);
    let sx = |v: Q| z(40) + z(20) * (v - z(10));
    let sy = |v: Q| z(270) - z(20) * (v - z(3));
    let mid = (floor + spec_score) / z(2);
    let (w1, w2) = ((z(11), (mid - z(11)) / z(3)), (z(24), (mid - z(24)) / z(3)));
    let fig: Vec<String> = [p[0], p[1], p[2], spec, pc, w1, w2].iter()
        .map(|&v| format!("{:.2} {:.2}", sx(v.0).f(), sy(v.1).f())).collect();
    println!("figure, {}", fig.join(", "));

    assert!(d2 == grid_d2 && d2 == q(5, 8) && (best_d.1, best_d.2) == (210, 150));   // road one = road two
    assert!(bean_scores.iter().all(|&s| s >= floor) && spec_score < floor && hits == 0);
    assert!(best_s == floor && best_c.0 == cheapest);                  // bound is met
    assert!(w.iter().min().unwrap() < &z(0) && at_cert.iter().all(|&v| v >= z(0)) && by_spec < z(0));
    assert!(w_easy.iter().all(|&v| v >= z(0)) && by_easy >= z(0));
    assert!(max_gap <= 1e-12 && dot(y, edge) == floor);
    assert!(*z_scores.iter().min().unwrap() < dot(zz, spec));                        // nearest-bean line fails
    println!("ALL CHECKS PASS");
}
