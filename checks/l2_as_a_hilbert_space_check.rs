// L2 as a Hilbert space -- the same check as the Python, in Rust.  No crates.
// Turbine A's week of daily mean wind speeds (m/s), Monday to Sunday, is a
// function on 7 days.  Projection three ways: normal equations, cell averages,
// grid search.  The Riesz representer two ways: the rule applied to each day,
// and the proof's direction perpendicular to the rule's kernel.  A hand-written
// rational type keeps every rational answer exact; floats only for square roots.
use std::fmt;

#[derive(Clone, Copy, PartialEq, Debug)]
struct Q(i64, i64); // numerator, denominator > 0, in lowest terms

fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i64, d: i64) -> Q { let (g, s) = (gcd(n, d).max(1), if d < 0 { -1 } else { 1 }); Q(s * n / g, s * d / g) }
fn add(a: Q, b: Q) -> Q { q(a.0 * b.1 + b.0 * a.1, a.1 * b.1) }
fn sub(a: Q, b: Q) -> Q { q(a.0 * b.1 - b.0 * a.1, a.1 * b.1) }
fn mul(a: Q, b: Q) -> Q { q(a.0 * b.0, a.1 * b.1) }
fn div(a: Q, b: Q) -> Q { q(a.0 * b.1, a.1 * b.0) }
fn fl(a: Q) -> f64 { a.0 as f64 / a.1 as f64 }
impl fmt::Display for Q {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        if self.1 == 1 { write!(f, "{}", self.0) } else { write!(f, "{}/{}", self.0, self.1) }
    }
}
fn show(v: &[Q]) -> String { format!("[{}]", v.iter().map(|a| a.to_string()).collect::<Vec<_>>().join(", ")) }
fn qs(v: &[i64]) -> Vec<Q> { v.iter().map(|&a| q(a, 1)).collect() }

fn ip(u: &[Q], v: &[Q], w: Q) -> Q {             // <u, v> = sum of u times v times each day's weight
    mul(u.iter().zip(v).fold(q(0, 1), |s, (&a, &b)| add(s, mul(a, b))), w)
}
fn sqrt(x: f64) -> f64 {                          // square root by Newton's method, written out
    let mut r = x.max(1.0);
    for _ in 0..60 { r = (r + x / r) / 2.0 } r
}
fn dist2(u: &[Q], v: &[Q], w: Q) -> Q { let d: Vec<Q> = u.iter().zip(v).map(|(&a, &b)| sub(a, b)).collect(); ip(&d, &d, w) }
fn project(f: &[Q], basis: &[Vec<Q>]) -> Vec<Q> { // road 1: normal equations, Cramer's rule
    let one = q(1, 1);
    let g: Vec<Vec<Q>> = basis.iter().map(|b| basis.iter().map(|c| ip(b, c, one)).collect()).collect();
    let r: Vec<Q> = basis.iter().map(|b| ip(f, b, one)).collect();
    let a = if basis.len() == 1 { vec![div(r[0], g[0][0])] } else {
        let det = sub(mul(g[0][0], g[1][1]), mul(g[0][1], g[1][0]));
        vec![div(sub(mul(r[0], g[1][1]), mul(g[0][1], r[1])), det), div(sub(mul(g[0][0], r[1]), mul(g[1][0], r[0])), det)]
    };
    (0..7).map(|i| a.iter().zip(basis).fold(q(0, 1), |s, (&ak, b)| add(s, mul(ak, b[i])))).collect()
}
fn cell_average(f: &[i64], cells: &[Vec<usize>]) -> Vec<Q> { // road 2: average f over each cell
    let mut out = vec![q(0, 1); 7];
    for cell in cells {
        for &i in cell { out[i] = q(cell.iter().map(|&j| f[j]).sum(), cell.len() as i64) }
    }
    out
}
fn grid(f: &[i64], cells: &[Vec<usize>]) -> (Q, Vec<Q>) { // road 3: every height 0.0, 0.1, ..., 10.0
    let tries: Vec<Vec<i64>> = if cells.len() == 1 { (0..101).map(|k| vec![k]).collect() }
        else { (0..101).flat_map(|k| (0..101).map(move |j| vec![k, j])).collect() };
    let mut best: Option<(i64, Vec<i64>)> = None;
    for ks in tries {
        let s: i64 = ks.iter().zip(cells).map(|(&k, c)| c.iter().map(|&i| (10 * f[i] - k).pow(2)).sum::<i64>()).sum();
        if best.as_ref().map_or(true, |b| s < b.0) { best = Some((s, ks)) }
    }
    let b = best.unwrap(); (q(b.0, 100), b.1.iter().map(|&k| q(k, 10)).collect())
}
fn rule(h: &[Q]) -> Q {                           // weekend mean minus weekday mean
    let wd = h[..5].iter().fold(q(0, 1), |s, &a| add(s, a));
    sub(div(add(h[5], h[6]), q(2, 1)), div(wd, q(5, 1)))
}
fn rule_f(h: &[f64]) -> f64 { (h[5] + h[6]) / 2.0 - (h[0] + h[1] + h[2] + h[3] + h[4]) / 5.0 }
fn unit(i: usize) -> Vec<Q> { (0..7).map(|j| q((j == i) as i64, 1)).collect() }
fn riesz_by_kernel(w: Q) -> Vec<Q> {              // road 2: the proof's construction
    let phi: Vec<Q> = (0..7).map(|i| rule(&unit(i))).collect();
    let mut basis: Vec<Vec<Q>> = Vec::new();      // Gram-Schmidt: an orthogonal basis of the kernel
    for i in 1..7 {
        let mut v: Vec<Q> = (0..7).map(|j| sub(unit(i)[j], mul(div(phi[i], phi[0]), unit(0)[j]))).collect();
        for b in &basis {
            let c = div(ip(&v, b, w), ip(b, b, w));
            v = v.iter().zip(b).map(|(&x, &y)| sub(x, mul(c, y))).collect();
        }
        basis.push(v);
    }
    let mut z = unit(0);                           // z = e_Mon minus its projection onto the kernel
    for b in &basis {
        let c = div(ip(&unit(0), b, w), ip(b, b, w));
        z = z.iter().zip(b).map(|(&x, &y)| sub(x, mul(c, y))).collect();
    }
    let k = div(rule(&z), ip(&z, &z, w));
    z.iter().map(|&x| mul(k, x)).collect()
}

fn main() {
    let fi = [3i64, 5, 8, 2, 6, 4, 7];
    let (f, one, wknd, c1w) = (qs(&fi), qs(&[1; 7]), qs(&[0, 0, 0, 0, 0, 1, 1]), q(1, 1));
    let p = q(1, 7);
    let cells = vec![vec![0usize, 1, 2, 3, 4], vec![5, 6]];
    println!("wind f = {:?} m/s, Mon to Sun; counting measure: <f, f> = {}, ||f|| = {:.4}", fi, ip(&f, &f, c1w), sqrt(fl(ip(&f, &f, c1w))));
    let c1 = project(&f, &[one.clone()]);
    let (g1, h1) = grid(&fi, &[(0..7).collect()]);
    let r1: Vec<Q> = f.iter().zip(&c1).map(|(&a, &b)| sub(a, b)).collect();
    println!("constants, normal equations: c = <f, 1>/<1, 1> = {}/{} = {}", ip(&f, &one, c1w), ip(&one, &one, c1w), c1[0]);
    println!("constants, grid search: best c = {}, least squared distance {}", h1[0], g1);
    println!("residual f - 5 = {}; <residual, 1> = {}", show(&r1), ip(&r1, &one, c1w));
    let d1 = dist2(&f, &c1, c1w);
    println!("residual norm sqrt({}) = {:.4}; Pythagoras {} + {} = {}", d1, sqrt(fl(d1)), ip(&c1, &c1, c1w), d1, add(ip(&c1, &c1, c1w), d1));
    let d4 = dist2(&f, &qs(&[4; 7]), c1w);
    println!("constant 4 instead: squared distance {} = 28 + 7 x 1^2, distance {:.4}", d4, sqrt(fl(d4)));
    let s1 = project(&f, &[one.clone(), wknd.clone()]);
    let s2 = cell_average(&fi, &cells);
    let (g2, h2) = grid(&fi, &cells);
    let r2: Vec<Q> = f.iter().zip(&s1).map(|(&a, &b)| sub(a, b)).collect();
    println!("steps, normal equations on 1 and the weekend indicator: {}", show(&s1));
    println!("steps, cell averages: weekday {} = {:.2}, weekend {} = {:.2}", s2[0], fl(s2[0]), s2[6], fl(s2[6]));
    println!("steps, grid search: best heights {} and {}, least squared distance {}", h2[0], h2[1], g2);
    println!("residual = {}; <residual, 1> = {}, <residual, weekend> = {}", show(&r2), ip(&r2, &one, c1w), ip(&r2, &wknd, c1w));
    let d2 = dist2(&f, &s1, c1w);
    println!("residual norm sqrt({}) = {:.4}; Pythagoras {} + {} = {}", d2, sqrt(fl(d2)), ip(&s1, &s1, c1w), d2, add(ip(&s1, &s1, c1w), d2));
    println!("nested: ||steps - constants||^2 = {} = 28 - 273/10", dist2(&s1, &c1, c1w));
    println!("uniform probability 1/7: residual norms {:.4} (constants), {:.4} (steps)", sqrt(fl(dist2(&f, &c1, p))), sqrt(fl(dist2(&f, &s1, p))));
    println!("chart, bars {:?}, constants line {:.2}, steps line {:.2} weekdays, {:.2} weekend", fi, fl(c1[0]), fl(s2[0]), fl(s2[6]));
    let s7 = sqrt(7.0);
    println!("figure, 16 px per m/s: O (40, 200), foot at c = 5 ({:.2}, 200), tip ({:.2}, {:.2}), c = 4 at ({:.2}, 200)",
             40.0 + 16.0 * 5.0 * s7, 40.0 + 16.0 * 5.0 * s7, 200.0 - 16.0 * sqrt(28.0), 40.0 + 16.0 * 4.0 * s7);
    let g_day: Vec<Q> = (0..7).map(|i| rule(&unit(i))).collect(); // road 1: the rule on each day's indicator
    let g_ker = riesz_by_kernel(c1w);
    println!("rule(f) = weekend mean - weekday mean = {}", rule(&f));
    println!("Riesz, rule on each day: g = {}", show(&g_day));
    println!("Riesz, perpendicular to the kernel: g = {}", show(&g_ker));
    let gg = ip(&g_ker, &g_ker, c1w);
    println!("<f, g> = {}; ||g||^2 = {}, ||g|| = {:.4}", ip(&f, &g_ker, c1w), gg, sqrt(fl(gg)));
    let gp = riesz_by_kernel(p);
    println!("uniform probability: g = {}; <f, g>_P = {}", show(&gp), ip(&f, &gp, p));
    let (mut seed, mut top) = (20260929u64, 0.0f64);
    for _ in 0..2000 {                             // SplitMix64 search for the rule's size
        let mut h = Vec::new();
        for _ in 0..7 {
            seed = seed.wrapping_add(0x9E3779B97F4A7C15);
            let mut z = (seed ^ (seed >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
            z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
            h.push(((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53) * 2.0 - 1.0);
        }
        top = top.max(rule_f(&h).abs() / sqrt(h.iter().fold(0.0, |s, x| s + x * x)));
    }
    let at_g = fl(rule(&g_ker)) / sqrt(fl(gg));
    println!("2000 random weeks, seed 20260929: largest |rule(h)|/||h|| = {:.4}; at h = g: {:.4}", top, at_g);
    println!("breaks 1, not closed: continuous ramps against the calm-to-wind step on [0, 1], Lebesgue measure");
    let mut ramps = Vec::new();                    // (n, squared distance) per ramp
    for (n, k) in [(2.0f64, 100000usize), (10.0, 100000), (100.0, 100000), (1000.0, 100000)] {
        let s: f64 = (k / 2..k).map(|j| (1.0 - ((((j as f64) + 0.5) / k as f64 - 0.5) * n).max(0.0).min(1.0)).powi(2)).sum::<f64>() / k as f64;
        println!("  ramp width 1/{}: distance by midpoint sums {:.4}, by formula sqrt(1/(3n)) {:.4}", n, sqrt(s), sqrt(1.0 / (3.0 * n)));
        ramps.push((n, s));
    }
    let cs = [4.0f64, 5.0, 5.5, 6.0, 7.0];
    let l1: Vec<String> = cs.iter().map(|c| format!("{}", (4.0 - c).abs() + (7.0 - c).abs())).collect();
    let l2: Vec<f64> = cs.iter().map(|c| sqrt((4.0 - c).powi(2) + (7.0 - c).powi(2))).collect();
    println!("breaks 2, L1: weekend readings 4 and 7, constants 4, 5, 5.5, 6, 7 at distance {}", l1.join(", "));
    println!("  L2 distances {}: one closest constant, 5.5", l2.iter().map(|x| format!("{:.4}", x)).collect::<Vec<_>>().join(", "));
    let par: Vec<(f64, f64)> = [1.0f64, 2.0, 3.0].iter().map(|&pp| (pp, [1.0f64, -1.0].iter().map(|sg| (0..7).map(|j| (fl(unit(0)[j]) + sg * fl(unit(1)[j])).abs().powf(pp)).sum::<f64>().powf(2.0 / pp)).sum::<f64>())).collect();
    for &(pp, lhs) in &par { println!("  parallelogram, Mon and Tue indicators, p = {}: {:.4} against 4", pp, lhs) } // squared p-sizes of Mon + Tue and Mon - Tue, added
    println!("breaks 3, counting-measure g used under 1/7: <f, g>_P = {}, not 7/10", ip(&f, &g_ker, p));
    let pw = project(&f, &[wknd.clone()]);
    let wrong: Vec<Q> = c1.iter().zip(&pw).map(|(&a, &b)| add(a, b)).collect();
    println!("breaks 4, separate projections added: {}, distance {:.4}", show(&wrong), sqrt(fl(dist2(&f, &wrong, c1w))));
    assert!(s1 == s2 && h2 == vec![s2[0], s2[6]] && g2 == dist2(&f, &s1, c1w)); // three roads, one projection
    assert!(h1 == vec![c1[0]] && g1 == q(28, 1) && ip(&r2, &one, c1w) == q(0, 1) && ip(&r2, &wknd, c1w) == q(0, 1));
    assert!(add(ip(&s1, &s1, c1w), d2) == q(fi.iter().map(|x| x * x).sum(), 1)); // Pythagoras against the raw sum
    assert!(g_day == g_ker && ip(&f, &g_ker, c1w) == rule(&f)); // two roads to the representer
    assert!(gp == g_day.iter().map(|&x| mul(q(7, 1), x)).collect::<Vec<Q>>() && ip(&f, &gp, p) == q(7, 10));
    assert!(top <= at_g + 1e-12 && (at_g - sqrt(0.7)).abs() < 1e-12);
    assert!(cs.iter().all(|c| (4.0 - c).abs() + (7.0 - c).abs() == 3.0) && ip(&f, &g_ker, p) == q(1, 10) && fl(dist2(&f, &wrong, c1w)) > 28.0 && l2.iter().all(|&x| x >= l2[2]) && l2[2] < l2[1]); // breaks
    assert!(ramps.iter().all(|&(n, s)| (sqrt(s) - sqrt(1.0 / (3.0 * n))).abs() < 1e-6)); // breaks 1: two roads to each ramp
    assert!(par.iter().all(|&(pp, x)| (x - 2.0 * 2f64.powf(2.0 / pp)).abs() < 1e-12) && wrong == [vec![q(5, 1); 5], vec![q(21, 2); 2]].concat()); // breaks 2 and 4
    println!("ALL CHECKS PASS");
}
