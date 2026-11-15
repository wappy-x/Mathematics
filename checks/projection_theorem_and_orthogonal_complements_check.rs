// Projection theorem and orthogonal complements -- the same check as the Python,
// in Rust.  No crates.  The seven-day record is done in exact fractions (a small
// struct below); the alternating projections and the infinite tail run in floats.
use std::ops::{Add, Div, Mul, Neg, Sub};

#[derive(Clone, Copy, PartialEq, Debug)]
struct Q(i64, i64);                                   // numerator, denominator > 0, in lowest terms
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i64, d: i64) -> Q { let g = gcd(n, d).max(1) * d.signum(); Q(n / g, d / g) }
impl Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.0 * o.1 + o.0 * self.1, self.1 * o.1) } }
impl Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { q(self.0 * o.1 - o.0 * self.1, self.1 * o.1) } }
impl Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.0 * o.0, self.1 * o.1) } }
impl Div for Q { type Output = Q; fn div(self, o: Q) -> Q { q(self.0 * o.1, self.1 * o.0) } }
impl Neg for Q { type Output = Q; fn neg(self) -> Q { Q(-self.0, self.1) } }
impl PartialOrd for Q {
    fn partial_cmp(&self, o: &Q) -> Option<std::cmp::Ordering> { (self.0 * o.1).partial_cmp(&(o.0 * self.1)) }
}
fn z(n: i64) -> Q { Q(n, 1) }
fn f(x: Q) -> f64 { x.0 as f64 / x.1 as f64 }

fn dot(u: &[Q], v: &[Q]) -> Q { u.iter().zip(v).fold(z(0), |s, (a, b)| s + *a * *b) }
fn sub(u: &[Q], v: &[Q]) -> Vec<Q> { u.iter().zip(v).map(|(a, b)| *a - *b).collect() }
fn num(x: Q) -> String {
    if x.1 == 1 { return format!("{}", x.0) }
    format!("{:.4}", f(x)).trim_end_matches('0').trim_end_matches('.').to_string()
}
fn vec(v: &[Q]) -> String { format!("({})", v.iter().map(|x| num(*x)).collect::<Vec<_>>().join(", ")) }
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
fn line(a: Q, b: Q) -> Vec<Q> { (-3..4).map(|s| a + b * z(s)).collect() }
fn fit(v: &[Q]) -> Vec<Q> {                           // P_M: nearest straight line
    let t: Vec<Q> = (-3..4).map(z).collect();
    line(dot(v, &[z(1); 7]) / z(7), dot(v, &t) / z(28))
}
fn fit_f(v: &[f64]) -> Vec<f64> {                     // the same, in floats, same order of operations
    let (mut sa, mut sb) = (0.0, 0.0);
    for i in 0..7 { sa += v[i] * 1.0; sb += v[i] * (i as f64 - 3.0) }
    let (a, b) = (sa / 7.0, sb / 28.0);
    (-3..4).map(|s| a + b * s as f64).collect()
}
fn front(v: &[f64]) -> Vec<f64> {                     // P_2: one level days 1-3, one days 4-7
    let (lo, hi) = ((v[0] + v[1] + v[2]) / 3.0, (v[3] + v[4] + v[5] + v[6]) / 4.0);
    (0..7).map(|i| if i < 3 { lo } else { hi }).collect()
}
fn front_q(v: &[Q]) -> Vec<Q> {
    let (lo, hi) = ((v[0] + v[1] + v[2]) / z(3), (v[3] + v[4] + v[5] + v[6]) / z(4));
    (0..7).map(|i| if i < 3 { lo } else { hi }).collect()
}
fn warming(v: &[Q]) -> Vec<Q> {                       // P_C: pool adjacent violators
    let mut blocks: Vec<(Q, i64)> = Vec::new();       // each block: (sum, count)
    for &x in v {
        blocks.push((x, 1));
        while blocks.len() > 1 && {
            let (l, m) = (blocks[blocks.len() - 2], blocks[blocks.len() - 1]);
            l.0 / z(l.1) > m.0 / z(m.1)
        } {
            let (s, n) = blocks.pop().unwrap();
            let last = blocks.last_mut().unwrap();
            *last = (last.0 + s, last.1 + n);
        }
    }
    blocks.iter().flat_map(|&(s, n)| vec![s / z(n); n as usize]).collect()
}

fn main() {
    let y: Vec<Q> = [8, 10, 9, 11, 12, 12, 15].iter().map(|&v| z(v)).collect();
    let t: Vec<Q> = (-3..4).map(z).collect();
    let one = vec![z(1); 7];
    // ---- the split y = P y + r, three roads to the same line ----
    let (a, b) = (dot(&y, &one) / z(7), dot(&y, &t) / z(28));
    let p = line(a, b);
    let r = sub(&y, &p);
    let h28: Vec<Vec<i64>> = (0..7).map(|i| (0..7).map(|j| 4 + (i - 3) * (j - 3)).collect()).collect();
    let hh: Vec<Vec<i64>> = (0..7).map(|i| (0..7).map(|j| (0..7).map(|k| h28[i][k] * h28[k][j]).sum()).collect()).collect();
    let pmat_y: Vec<Q> = (0..7).map(|i| (0..7).fold(z(0), |s, j| s + z(h28[i][j]) * y[j]) / z(28)).collect();
    let pp_ok = (0..7).all(|i| (0..7).all(|j| hh[i][j] == 28 * h28[i][j]));
    let sym = (0..7).all(|i| (0..7).all(|j| h28[i][j] == h28[j][i]));
    let tr = q((0..7).map(|i| h28[i][i]).sum(), 28);
    let grid: Vec<(Q, Q)> = (0..5).flat_map(|i| (0..5).map(move |j| (z(10) + q(i, 2), q(1, 2) + q(j, 4)))).collect();
    let miss = |g: &(Q, Q)| { let e = sub(&y, &line(g.0, g.1)); dot(&e, &e) };
    let formula_ok = grid.iter().all(|g| miss(g) == z(4) + z(7) * (g.0 - z(11)) * (g.0 - z(11)) + z(28) * (g.1 - z(1)) * (g.1 - z(1)));
    let best = grid.iter().fold(grid[0], |m, g| if miss(g) < miss(&m) { *g } else { m });
    println!("record y, deg C: {}; days t = {}", vec(&y), vec(&t));
    println!("line fit: a = <y,1>/<1,1> = {}/7 = {}, b = <y,t>/<t,t> = {}/28 = {}", num(dot(&y, &one)), num(a), num(dot(&y, &t)), num(b));
    println!("trend P y = {}", vec(&p));
    println!("residual r = y - P y = {}", vec(&r));
    println!("<r,1> = {}, <r,t> = {}", num(dot(&r, &one)), num(dot(&r, &t)));
    println!("Pythagoras: |y|^2 = {} = |P y|^2 {} + |r|^2 {}", num(dot(&y, &y)), num(dot(&p, &p)), num(dot(&r, &r)));
    println!("P y by the matrix 28P = 4J + t t^T: {}; same: {}", vec(&pmat_y), yn(pmat_y == p));
    println!("P P = P exactly: {}; P symmetric: {}", yn(pp_ok), yn(sym));
    println!("trace P = {}, trace (I - P) = {}", num(tr), num(z(7) - tr));
    println!("P(P y) = P y: {}; P r = {}", yn(fit(&p) == p), vec(&fit(&r)));
    println!("25 rival lines: least squared miss {} at a = {}, b = {}; 4 + 7(a - 11)^2 + 28(b - 1)^2 on all 25: {}",
             num(miss(&best)), num(best.0), num(best.1), yn(formula_ok));
    // ---- the warming-only records: a closed convex cone, not a subspace ----
    let pc = warming(&y);
    let rc = sub(&y, &pc);
    let cert = (1..7).map(|j| dot(&rc, &(0..7).map(|i| z((i >= j) as i64)).collect::<Vec<Q>>()))
        .fold(z(-1000), |m, v| if v > m { v } else { m });
    let neg_y: Vec<Q> = y.iter().map(|v| -*v).collect();
    let neg_pc: Vec<Q> = pc.iter().map(|v| -*v).collect();
    println!("warming-only fit P_C y = {}, squared miss {}", vec(&pc), num(dot(&rc, &rc)));
    println!("certificate: <r,1> = {}, <r,P_C y> = {}, largest <r,s_j> = {}", num(dot(&rc, &one)), num(dot(&rc, &pc)), num(cert));
    println!("P_C(P_C y) = P_C y: {}; P_C(-y) = {}; -P_C y = {}", yn(warming(&pc) == pc), vec(&warming(&neg_y)), vec(&neg_pc));
    // ---- alternating projections: lines, then front steps, then lines ... ----
    let w: Vec<Q> = (0..7).map(|i| z((i >= 3) as i64) - q(4, 7)).collect();
    let cos2 = dot(&t, &w) * dot(&t, &w) / (dot(&t, &t) * dot(&w, &w));
    let fy = front_q(&y);
    let ef = sub(&y, &fy);
    println!("front fit P_2 y = {}, squared miss {}", vec(&fy), num(dot(&ef, &ef)));
    println!("angle between the two fits: cos^2 = {}, angle {:.4} deg", num(cos2), f(cos2).sqrt().acos().to_degrees());
    let mut x: Vec<f64> = y.iter().map(|v| f(*v)).collect();
    let mut dist: Vec<f64> = Vec::new();
    for k in 1..51 {
        x = if k % 2 == 1 { fit_f(&x) } else { front(&x) };
        let mut sq = 0.0;
        for v in &x { sq += (v - 11.0) * (v - 11.0) }
        dist.push(sq.sqrt());
    }
    println!("step k: distance from the all-11 record, closed form sqrt(28) (3/4)^((k-1)/2)");
    for k in (1..9).chain([20, 50]) {
        println!("  {:2}: {:.4}  {:.4}", k, dist[k - 1], 28f64.sqrt() * 0.75f64.powf((k - 1) as f64 / 2.0));
    }
    // ---- what breaks if you drop a piece ----
    let qline = |v: &[Q]| line((v[0] + v[6]) / z(2), (v[6] - v[0]) / z(6));   // line through days 1 and 7
    let ql = qline(&y);
    let rq = sub(&y, &ql);
    let qq = qline(&ql);
    println!("mistake 1, endpoint line: a = {}, b = {}; Q Q = Q: {}; squared miss {}; <r,1> = {}, <r,t> = {}",
             num(ql[3]), num(ql[4] - ql[3]), yn(qq == ql), num(dot(&rq, &rq)), num(dot(&rq, &one)), num(dot(&rq, &t)));
    let fy1 = fit(&y);
    let x3 = fit(&front_q(&fy1));
    println!("mistake 2, one round taken as the answer: slope {}, {:.4} from the all-11 record", num(x3[4] - x3[3]), dist[2]);
    println!("mistake 3, finite records against the tail 1, 1/2, 1/3, ... in l2:");
    let basel = std::f64::consts::PI * std::f64::consts::PI / 6.0;
    let mut tails: Vec<f64> = Vec::new();
    for n in [1u64, 10, 100, 1000, 10000] {
        let (mut head, mut road2, kk) = (0.0f64, 0.0f64, 2000000u64);
        for k in (1..=n).rev() { head += 1.0 / ((k * k) as f64) }
        for k in (n + 1..=kk).rev() { road2 += 1.0 / ((k * k) as f64) }   // summed smallest first
        let road1 = basel - head;
        let kf = kk as f64;
        road2 += 1.0 / kf - 0.5 / (kf * kf) + 1.0 / (6.0 * kf * kf * kf);  // Euler-Maclaurin tail past K
        tails.push(road1.sqrt());
        println!("  N = {:5}: best miss {:.6} (direct sum {:.6}), sqrt(N) x miss {:.4}",
                 n, road1.sqrt(), road2.sqrt(), (n as f64 * road1).sqrt());
        assert!((road1 - road2).abs() < 1e-9);
    }
    println!("closed subspace of l2: keep the even places of the tail, cut at N");
    for n in [10u64, 100, 1000, 10000] {
        let (mut ev, mut od) = (0.0f64, 0.0f64);
        for k in 1..=n { if k % 2 == 1 { od += 1.0 / ((k * k) as f64) } else { ev += 1.0 / ((k * k) as f64) } }
        println!("  N = {:5}: |P y|^2 {:.6}, |r|^2 {:.6}, cut to P y {:.6}", n, ev, od, (basel / 4.0 - ev).sqrt());
        assert!((ev - basel / 4.0).abs() < 1.0 / n as f64 && (od - 3.0 * basel / 4.0).abs() < 1.0 / n as f64);
    }
    println!("  limits: pi^2/24 {:.6} + pi^2/8 {:.6} = pi^2/6 {:.6}; miss {:.6}", basel / 4.0, 3.0 * basel / 4.0, basel, (3.0 * basel / 4.0).sqrt());
    let pts: Vec<String> = dist[..6].iter().enumerate().map(|(k, d)| {
        let (u, v) = if k % 2 == 0 { (40.0 + 70.0 * d, 220.0) } else { (40.0 + 70.0 * d * 0.75f64.sqrt(), 220.0 - 35.0 * d) };
        format!("({:.1}, {:.1})", u, v)
    }).collect();
    println!("figure, {}", pts.join("; "));

    assert!(a == z(11) && b == z(1) && pmat_y == p && best == (z(11), z(1)) && formula_ok);   // three roads, one line
    assert!(dot(&r, &one) == z(0) && dot(&r, &t) == z(0) && dot(&y, &y) == dot(&p, &p) + dot(&r, &r));
    assert!(pp_ok && fit(&r) == vec![z(0); 7]);                                            // P P = P, P r = 0
    assert!(dot(&rc, &one) == z(0) && dot(&rc, &pc) == z(0) && cert <= z(0) && warming(&pc) == pc);
    assert!(cos2 == q(3, 4) && dist.iter().enumerate().all(|(k, d)| (d - 28f64.sqrt() * 0.75f64.powf(k as f64 / 2.0)).abs() < 1e-12));
    assert!(qq == ql && dot(&rq, &rq) > dot(&r, &r) && tails.windows(2).all(|p| p[0] > p[1] && p[1] > 0.0));
    println!("ALL CHECKS PASS");
}
