// Logistic regression -- the same check as the Python, in Rust, no crates.  500 loans drawn with
// SplitMix64 (seed 20260928, same draws as the Python), fitted by Newton's method, by a climb that
// nudges instead of using the slope formula, and for two groups by a 2x2 table; SEs two ways.
struct Rng(u64);
impl Rng {
    fn unif(&mut self) -> f64 {                   // SplitMix64: a uniform number in [0, 1)
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}
fn sig(z: f64) -> f64 {                           // the logistic curve, written to avoid overflow
    if z >= 0.0 { 1.0 / (1.0 + (-z).exp()) } else { z.exp() / (1.0 + z.exp()) }
}
fn dot(b: &[f64], x: &[f64]) -> f64 { b.iter().zip(x).fold(0.0, |s, (bj, xj)| s + bj * xj) }
fn loglik(b: &[f64], xs: &[Vec<f64>], y: &[u8]) -> f64 {   // sum of y*score - ln(1 + e^score)
    let mut s = 0.0;
    for (x, &yi) in xs.iter().zip(y) {
        let z = dot(b, x);
        s += yi as f64 * z - (z.max(0.0) + (1.0 + (-z.abs()).exp()).ln());
    }
    s
}
fn solve(a: &[Vec<f64>], v: &[f64]) -> Vec<f64> {   // Gaussian elimination with row swaps
    let k = v.len();
    let mut m: Vec<Vec<f64>> = (0..k).map(|i| { let mut r = a[i].clone(); r.push(v[i]); r }).collect();
    for c in 0..k {
        let mut r = c;
        for i in c + 1..k { if m[i][c].abs() > m[r][c].abs() { r = i } }
        m.swap(c, r);
        for i in c + 1..k {
            let f = m[i][c] / m[c][c];
            for j in 0..=k { m[i][j] = m[i][j] - f * m[c][j] }
        }
    }
    let mut out = vec![0.0; k];
    for i in (0..k).rev() {
        let mut s = m[i][k];
        for j in i + 1..k { s -= m[i][j] * out[j] }
        out[i] = s / m[i][i];
    }
    out
}
fn info(b: &[f64], xs: &[Vec<f64>], y: &[u8]) -> (Vec<f64>, Vec<Vec<f64>>) {  // slopes, curvature
    let k = b.len();
    let (mut g, mut h) = (vec![0.0; k], vec![vec![0.0; k]; k]);
    for (x, &yi) in xs.iter().zip(y) {
        let p = sig(dot(b, x)); let w = p * (1.0 - p);
        for j in 0..k {
            g[j] += x[j] * (yi as f64 - p);
            for m in 0..k { h[j][m] += w * x[j] * x[m] }
        }
    }
    (g, h)
}
fn newton(xs: &[Vec<f64>], y: &[u8], steps: usize) -> (Vec<f64>, usize) {  // from zero
    let mut b = vec![0.0; xs[0].len()];
    for it in 1..=steps {
        let (g, h) = info(&b, xs, y);
        let d = solve(&h, &g);
        for j in 0..b.len() { b[j] += d[j] }
        if d.iter().fold(0.0f64, |a, v| a.max(v.abs())) < 1e-10 { return (b, it) }
    }
    (b, steps)
}
fn ses(b: &[f64], xs: &[Vec<f64>], y: &[u8]) -> Vec<f64> {  // roots of inverse curvature's diagonal
    let h = info(b, xs, y).1;
    (0..b.len()).map(|j| solve(&h, &(0..b.len()).map(|i| if i == j { 1.0 } else { 0.0 }).collect::<Vec<f64>>())[j].sqrt()).collect()
}
fn nudge(c: &[f64], j: usize, e: f64) -> Vec<f64> { c.iter().enumerate().map(|(i, cj)| cj + if i == j { e } else { 0.0 }).collect() }
fn show(label: &str, v: f64) { println!("{:<48}{:>12.4}", label, v) }
fn row(label: &str, vs: &[f64]) { println!("{:<14}{}", label, vs.iter().map(|v| format!("{:5.2}", v)).collect::<Vec<_>>().join(" ")) }
fn main() {
    let tru = [-2.55, -0.03, 0.08];
    let mut rng = Rng(20260928);
    let (mut xs, mut y): (Vec<Vec<f64>>, Vec<u8>) = (vec![], vec![]);
    for _ in 0..500 {                             // income $25k-$125k, debt ratio 10%-60%
        let (inc, debt) = (25.0 + (101.0 * rng.unif()).floor(), 10.0 + (51.0 * rng.unif()).floor());
        xs.push(vec![1.0, inc, debt]);
        y.push(if rng.unif() < sig(tru[0] + tru[1] * inc + tru[2] * debt) { 1 } else { 0 });
    }
    let (n, ny) = (y.len() as f64, y.iter().map(|&v| v as usize).sum::<usize>());
    let first: Vec<String> = (0..4).map(|i| format!("({:.0}, {:.0}, {})", xs[i][1], xs[i][2], y[i])).collect();
    println!("loans {}; first four (income $k, debt %, default): {}", y.len(), first.join(", "));
    println!("defaults among the {}: {}, a share of {:.4}", y.len(), ny, ny as f64 / n);
    let (b, its) = newton(&xs, &y, 60);
    let g = info(&b, &xs, &y).0;
    let se = ses(&b, &xs, &y);
    let hinv: Vec<Vec<f64>> = (0..3).map(|j| solve(&info(&b, &xs, &y).1, &(0..3).map(|i| if i == j { 1.0 } else { 0.0 }).collect::<Vec<f64>>())).collect();
    let small = g.iter().fold(0.0f64, |a, v| a.max(v.abs())) < 1e-9;
    println!("Newton steps to converge: {}; largest slope below 1e-9: {}", its, if small { "yes" } else { "no" });
    show("log-likelihood at the peak", loglik(&b, &xs, &y));
    let mean = |j: usize| xs.iter().fold(0.0, |a, x| a + x[j]) / n;       // road 2: rescale, nudge, climb
    let (m1, m2) = (mean(1), mean(2));
    let sd = |j: usize, m: f64| (xs.iter().fold(0.0, |a, x| a + (x[j] - m).powi(2)) / n).sqrt();
    let (s1, s2) = (sd(1, m1), sd(2, m2));
    let zs: Vec<Vec<f64>> = xs.iter().map(|x| vec![1.0, (x[1] - m1) / s1, (x[2] - m2) / s2]).collect();
    let (mut c, h) = (vec![0.0; 3], 1e-5);
    for _ in 0..300 {
        let gr: Vec<f64> = (0..3).map(|j| (loglik(&nudge(&c, j, h), &zs, &y) - loglik(&nudge(&c, j, -h), &zs, &y)) / (2.0 * h) / n).collect();
        for j in 0..3 { c[j] = c[j] + 4.0 * gr[j] }
    }
    let climb = [c[0] - c[1] * m1 / s1 - c[2] * m2 / s2, c[1] / s1, c[2] / s2];
    let (mut reps, mut cover): (Vec<Vec<f64>>, usize) = (vec![], 0);   // road 3: 400 fresh loan books
    for _ in 0..400 {
        let ys: Vec<u8> = xs.iter().map(|x| if rng.unif() < sig(dot(&b, x)) { 1 } else { 0 }).collect();
        let r = newton(&xs, &ys, 60).0;
        if (r[2] - b[2]).abs() < 1.96 * ses(&r, &xs, &ys)[2] { cover += 1 }
        reps.push(r);
    }
    let rm: Vec<f64> = (0..3).map(|j| reps.iter().fold(0.0, |a, r| a + r[j]) / 400.0).collect();
    let sim: Vec<f64> = (0..3).map(|j| (reps.iter().fold(0.0, |a, r| a + (r[j] - rm[j]).powi(2)) / 399.0).sqrt()).collect();
    println!("coefficient     Newton   climb    truth    SE curvature  SE 400 refits");
    for (j, name) in ["b0 intercept", "b1 income", "b2 debt"].iter().enumerate() {
        println!("{:<13}{:9.4}{:9.4}{:9.4}{:11.4}{:15.4}", name, b[j], climb[j], tru[j], se[j], sim[j]);
    }
    show("coverage of b2 +/- 1.96 SE over 400 refits", cover as f64 / 400.0);
    for (lab, j) in [("+10 points of debt ratio", 2), ("+$10k of income", 1)] {
        println!("odds ratio, {:<25}{:.4}; 95% interval {:.4} to {:.4}", lab, (10.0 * b[j]).exp(),
                 (10.0 * (b[j] - 1.96 * se[j])).exp(), (10.0 * (b[j] + 1.96 * se[j])).exp());
    }
    for (lab, inc, debt) in [("A", 50.0, 45.0), ("A, debt 35", 50.0, 35.0), ("A, debt 55", 50.0, 55.0),
                             ("B", 100.0, 20.0), ("B, debt 30", 100.0, 30.0)] {
        let (z, xv) = (b[0] + b[1] * inc + b[2] * debt, [1.0, inc, debt]);
        let sz = (0..3).fold(0.0, |a, j| (0..3).fold(a, |a, k| a + xv[j] * xv[k] * hinv[j][k])).sqrt();
        println!("applicant {:<10} income part {:8.4}  debt part {:7.4}  score {:8.4}  odds {:7.4}  chance {:.4}, 95% {:.4} to {:.4}",
                 lab, b[1] * inc, b[2] * debt, z, z.exp(), sig(z), sig(z - 1.96 * sz), sig(z + 1.96 * sz));
    }
    show("mistake: odds ratio used on A's chance, debt 55", sig(b[0] + 50.0 * b[1] + 45.0 * b[2]) * (10.0 * b[2]).exp());
    show("mistake: intercept as a typical chance, Λ(b0)", sig(b[0]));
    let xtx: Vec<Vec<f64>> = (0..3).map(|j| (0..3).map(|k| xs.iter().fold(0.0, |a, r| a + r[j] * r[k])).collect()).collect();
    let xty: Vec<f64> = (0..3).map(|j| xs.iter().zip(&y).fold(0.0, |a, (r, &yi)| a + r[j] * yi as f64)).collect();
    let ls = solve(&xtx, &xty);                    // the straight line
    show("mistake: straight line, income 125, debt 10", ls[0] + 125.0 * ls[1] + 10.0 * ls[2]);
    show("mistake: straight line, income 25, debt 60", ls[0] + 25.0 * ls[1] + 60.0 * ls[2]);
    show("logistic model, income 125, debt 10", sig(b[0] + 125.0 * b[1] + 10.0 * b[2]));
    let gx: Vec<Vec<f64>> = xs.iter().map(|x| vec![1.0, if x[2] >= 40.0 { 1.0 } else { 0.0 }]).collect();
    let nh = gx.iter().filter(|r| r[1] == 1.0).count();
    let dh: usize = gx.iter().zip(&y).filter(|(r, _)| r[1] == 1.0).map(|(_, &v)| v as usize).sum();
    let (nl, dl) = (500 - nh, ny - dh);
    let bg = newton(&gx, &y, 60).0;
    let by_hand = (dh as f64 / (nh - dh) as f64).ln() - (dl as f64 / (nl - dl) as f64).ln();
    let (ol, oh) = (dl as f64 / (nl - dl) as f64, dh as f64 / (nh - dh) as f64);
    println!("two groups: debt under 40%: {} of {} defaulted, odds {:.4}; 40% or more: {} of {}, odds {:.4}; ratio {:.4}",
             dl, nl, ol, dh, nh, oh, oh / ol);
    show("two groups: slope, log of the odds ratio by hand", by_hand);
    show("two groups: slope, Newton", bg[1]);
    row("chart, debt", &(0..11).map(|i| 10.0 + 5.0 * i as f64).collect::<Vec<f64>>());
    for (lab, inc) in [("chart, $40k", 40.0), ("chart, $100k", 100.0)] {
        row(lab, &(0..11).map(|i| sig(b[0] + inc * b[1] + b[2] * (10.0 + 5.0 * i as f64))).collect::<Vec<f64>>());
    }
    let sx: Vec<Vec<f64>> = [20.0, 25.0, 30.0, 35.0, 45.0, 50.0, 55.0, 60.0].iter().map(|&d| vec![1.0, d]).collect();
    let sy: Vec<u8> = vec![0, 0, 0, 0, 1, 1, 1, 1];            // separated book
    for k in [5, 10, 15, 20, 25] {
        let bs = newton(&sx, &sy, k).0;
        println!("separated, {:2} Newton steps: slope {:.4}  log-lik {:.10}  SE of slope {:.1}",
                 k, bs[1], loglik(&bs, &sx, &sy), ses(&bs, &sx, &sy)[1]);
    }
    let ts: Vec<f64> = (0..9).map(|i| 0.1 * i as f64).collect();
    row("chart, t", &ts);
    row("chart, loglik", &ts.iter().map(|&t| loglik(&[-40.0 * t, t], &sx, &sy)).collect::<Vec<f64>>());
    assert!((0..3).all(|j| (b[j] - climb[j]).abs() < 1e-6), "Newton and the slope-free climb must agree");
    assert!((0..3).all(|j| (b[j] - tru[j]).abs() < 3.0 * se[j]), "fit within 3 SE of the truth");
    assert!((0..3).all(|j| (sim[j] / se[j] - 1.0).abs() < 0.15), "curvature SE must match the refits");
    assert!((bg[1] - by_hand).abs() < 1e-9, "two-group closed form");
    assert!(loglik(&newton(&sx, &sy, 25).0, &sx, &sy) > loglik(&newton(&sx, &sy, 20).0, &sx, &sy), "separation climbs");
    println!("ALL CHECKS PASS");
}
