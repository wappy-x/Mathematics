// Support vector machines -- the same check as kernels_and_support_vector_machines_check.py, in Rust.
// Standard library only, no crates.  Same SMO solver, same SplitMix64 data.
use std::f64::consts::PI;
type P = (f64, f64);

struct Rng(u64);                                          // SplitMix64, seed stated below
impl Rng {
    fn u(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15); let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}

fn ring(rng: &mut Rng, n: usize, lo: f64, hi: f64) -> Vec<P> {   // n orders, uniform where lo <= distance < hi
    let mut out = Vec::new();
    while out.len() < n {
        let (a, b) = (6.0 * rng.u() - 3.0, 6.0 * rng.u() - 3.0); if lo * lo <= a * a + b * b && a * a + b * b < hi * hi { out.push((a, b)); }
    }
    out
}
fn dot(p: P, q: P) -> f64 { p.0 * q.0 + p.1 * q.1 }
fn rbf(g: f64) -> impl Fn(P, P) -> f64 { move |p: P, q: P| (-g * ((p.0 - q.0).powi(2) + (p.1 - q.1).powi(2))).exp() }

fn smo(x: &[P], y: &[f64], k: &dyn Fn(P, P) -> f64, c: f64) -> (Vec<f64>, f64, Vec<Vec<f64>>) {
    let n = x.len();
    let kx: Vec<Vec<f64>> = x.iter().map(|&p| x.iter().map(|&q| k(p, q)).collect()).collect();
    let (mut al, mut g) = (vec![0.0; n], vec![-1.0; n]);  // g: slope of the dual, tracked as al moves
    loop {
        let (mut i, mut j, mut hi, mut lo) = (n, n, f64::NEG_INFINITY, f64::INFINITY);
        for t in 0..n {
            let v = -y[t] * g[t];
            if ((y[t] > 0.0 && al[t] < c) || (y[t] < 0.0 && al[t] > 0.0)) && v > hi { i = t; hi = v; }
            if ((y[t] < 0.0 && al[t] < c) || (y[t] > 0.0 && al[t] > 0.0)) && v < lo { j = t; lo = v; }
        }
        if hi - lo < 1e-9 { return (al, (hi + lo) / 2.0, kx); }   // no pair can still raise the dual
        let mut t = (hi - lo) / (kx[i][i] + kx[j][j] - 2.0 * kx[i][j]).max(1e-12);
        t = t.min(if y[i] > 0.0 { c - al[i] } else { al[i] }).min(if y[j] > 0.0 { al[j] } else { c - al[j] });
        al[i] += y[i] * t; al[j] -= y[j] * t;
        for m in 0..n { g[m] += y[m] * t * (kx[m][i] - kx[m][j]); }
    }
}
fn score(x: &[P], y: &[f64], al: &[f64], b: f64, k: &dyn Fn(P, P) -> f64, p: P) -> f64 {
    (0..x.len()).filter(|&m| al[m] > 0.0).map(|m| al[m] * y[m] * k(x[m], p)).sum::<f64>() + b
}
fn errors(x: &[P], y: &[f64], al: &[f64], b: f64, k: &dyn Fn(P, P) -> f64, t: &[P], z: &[f64]) -> usize {
    t.iter().zip(z).filter(|(p, s)| **s * score(x, y, al, b, k, **p) <= 0.0).count()
}
fn weights(x: &[P], y: &[f64], al: &[f64]) -> P {
    (0..x.len()).fold((0.0, 0.0), |w, m| (w.0 + al[m] * y[m] * x[m].0, w.1 + al[m] * y[m] * x[m].1))
}

fn widest_by_scan(h: &[P], f: &[P]) -> (f64, f64) {           // road 2: try every direction round the circle, 0.01 degree apart
    let (mut best, mut at) = (-1e9, 0);
    for k in 0..36000 {
        let u = ((k as f64 * PI / 18000.0).cos(), (k as f64 * PI / 18000.0).sin());
        let gap = f.iter().map(|&p| dot(u, p)).fold(f64::INFINITY, f64::min) - h.iter().map(|&p| dot(u, p)).fold(f64::NEG_INFINITY, f64::max);
        if gap > best { best = gap; at = k; }
    }
    (best, at as f64 / 100.0)
}

fn main() {
    // ---- six orders: (amount score, hour score); honest -1, fraud +1 ----
    let (h, f): (Vec<P>, Vec<P>) = (vec![(0.0, 0.0), (1.0, 0.0), (0.0, 1.0)], vec![(2.0, 2.0), (3.0, 3.0), (4.0, 1.0)]);
    let (x6, y6): (Vec<P>, Vec<f64>) = (h.iter().chain(f.iter()).cloned().collect(), vec![-1.0, -1.0, -1.0, 1.0, 1.0, 1.0]);
    let (al6, b6, _) = smo(&x6, &y6, &dot, f64::INFINITY);
    let w6 = weights(&x6, &y6, &al6); let nw = dot(w6, w6).sqrt();
    let sum6: f64 = al6.iter().sum();
    let (scan, angle) = widest_by_scan(&h, &f);
    println!("hard margin: alphas {}", al6.iter().map(|a| format!("{:.4}", a)).collect::<Vec<_>>().join(" "));
    println!("w = ({:.4}, {:.4})  b = {:.4}  |w| = {:.4}  |w|^2 = {:.4}  sum of alphas = {:.4}", w6.0, w6.1, b6, nw, nw * nw, sum6);
    println!("widest margin: 2/|w| = {:.4}   scan = {:.4} at {:.2} deg   by hand 3/sqrt2 = {:.4}", 2.0 / nw, scan, angle, 3.0 / 2f64.sqrt());
    let (mut pw, mut pb, mut sweeps) = ((0.0, 0.0), 0.0, 0);      // a perceptron's line, for contrast
    while x6.iter().zip(&y6).any(|(&p, &s)| s * (dot(pw, p) + pb) <= 0.0) {
        sweeps += 1;
        for (&p, &s) in x6.iter().zip(&y6) { if s * (dot(pw, p) + pb) <= 0.0 { pw = (pw.0 + s * p.0, pw.1 + s * p.1); pb += s; } }
    }
    let pgap = x6.iter().zip(&y6).map(|(&p, &s)| s * (dot(pw, p) + pb)).fold(f64::INFINITY, f64::min) / dot(pw, pw).sqrt();
    println!("perceptron after {} sweeps: w = ({:.0}, {:.0}) b = {:.0}  nearest order {:.4} away, svm {:.4}", sweeps, pw.0, pw.1, pb, pgap, 1.0 / nw);
    println!("figure, centre x1 + x2 = {:.4}, edges x1 + x2 = {:.4} and {:.4}", -b6 / w6.0, (-1.0 - b6) / w6.0, (1.0 - b6) / w6.0);

    // ---- add a genuine big, late order in the middle of the fraud: slack ----
    let (mut x7, mut y7, mut h7) = (x6.clone(), y6.clone(), h.clone());
    x7.push((3.0, 2.0)); y7.push(-1.0); h7.push((3.0, 2.0));
    let (gap7, _) = widest_by_scan(&h7, &f);
    println!("with honest (3, 2): best hard gap, scan = {:.4}, by hand -1/sqrt5 = {:.4} (negative: no line works)", gap7, -1.0 / 5f64.sqrt());
    for c in [1.0, 0.1] {
        let (al, b, _) = smo(&x7, &y7, &dot, c);
        let w = weights(&x7, &y7, &al);
        let xi: Vec<String> = x7.iter().zip(&y7).map(|(&p, &s)| format!("{:.2}", (1.0 - s * score(&x7, &y7, &al, b, &dot, p)).max(0.0))).collect();
        println!("C = {:.1}: w = ({:.4}, {:.4}) b = {:.4} width {:.4} slacks {}", c, w.0, w.1, b, 2.0 / dot(w, w).sqrt(), xi.join(" "));
    }

    // ---- the kernel trick: the same number from features and from the shortcut ----
    let (p, q) = ((1.0, 0.0), (2.0, 2.0));
    let lift = |x: P| [x.0 * x.0, 2f64.sqrt() * x.0 * x.1, x.1 * x.1];
    let ld = |a: P, c: P| { let (s, t) = (lift(a), lift(c)); s[0] * t[0] + s[1] * t[1] + s[2] * t[2] };
    println!("(p.q)^2 = {:.4}  lift(p).lift(q) = {:.4}", dot(p, q).powi(2), ld(p, q));
    let (mut term, mut total) = (1.0, 0.0);                       // e^(p.q) as 1 + p.q + (p.q)^2/2! + ...
    for k in 1..31 { total += term; term = term * dot(p, q) / k as f64; }
    let series = (-0.5 * dot(p, p)).exp() * (-0.5 * dot(q, q)).exp() * total;
    println!("radial K(p, q), gamma 0.5: exp(-0.5*5) = {:.6}  as 30-term feature series = {:.6}", rbf(0.5)(p, q), series);
    let (mut rng, mut lifts) = (Rng(2026), 0.0f64);
    for _ in 0..200 {
        let (a, c) = ((6.0 * rng.u() - 3.0, 6.0 * rng.u() - 3.0), (6.0 * rng.u() - 3.0, 6.0 * rng.u() - 3.0));
        lifts = lifts.max((dot(a, c).powi(2) - ld(a, c)).abs());
    }
    println!("generator: honest within 1.6, fraud from 1.2 to 3.0; in the overlap honest is {:.2}x as dense", (120.0 / 2.56) / (40.0 / (9.0 - 1.44)));
    // ---- the fraud ring: 160 training orders, 400 test orders, all synthetic, seed 2026 ----
    let mut tr = ring(&mut rng, 120, 0.0, 1.6); tr.extend(ring(&mut rng, 40, 1.2, 3.0));
    let mut te = ring(&mut rng, 300, 0.0, 1.6); te.extend(ring(&mut rng, 100, 1.2, 3.0));
    let (ytr, yte): (Vec<f64>, Vec<f64>) = ((0..160).map(|i| if i < 120 { -1.0 } else { 1.0 }).collect(), (0..400).map(|i| if i < 300 { -1.0 } else { 1.0 }).collect());
    let run = |name: &str, k: &dyn Fn(P, P) -> f64, c: f64, tr: &[P], te: &[P]| {
        let (al, b, kx) = smo(tr, &ytr, k, c);
        let sv = al.iter().filter(|&&a| a > 1e-9).count();
        let miss = errors(tr, &ytr, &al, b, k, &te[300..], &yte[300..]);
        let alarm = errors(tr, &ytr, &al, b, k, &te[..300], &yte[..300]);
        println!("{:<25} SVs {:>3}  train errors {:>2}/160  test: missed fraud {:>3}/100, false alarms {:>2}/300, total {:>3}/400",
                 name, sv, errors(tr, &ytr, &al, b, k, tr, &ytr), miss, alarm, miss + alarm);
        (al, b, kx, miss)
    };
    let k5 = rbf(0.5);
    let (al, b, kx, miss_rbf) = run("radial, gamma 0.5, C 10", &k5, 10.0, &tr, &te);
    let (mut quad, mut hinge) = (0.0, 0.0);
    for i in 0..160 { for j in 0..160 { quad += al[i] * al[j] * ytr[i] * ytr[j] * kx[i][j]; } }
    for i in 0..160 { hinge += (1.0 - ytr[i] * score(&tr, &ytr, &al, b, &k5, tr[i])).max(0.0); }
    let (primal, dual) = (quad / 2.0 + 10.0 * hinge, al.iter().sum::<f64>() - quad / 2.0);
    println!("primal {:.6}  dual {:.6}  gap {:.9}", primal, dual, primal - dual);
    for (name, x) in [("100 pounds, usual hour", (2.0, 0.0)), ("5 pounds, 9pm", (-2.75, 0.5)), ("70 pounds, 7pm", (0.5, -0.5))] {
        println!("order {:<22} at ({:.2}, {:.2}): score {:+.4}", name, x.0, x.1, score(&tr, &ytr, &al, b, &k5, x));
    }
    let ideal = te[300..].iter().filter(|p| p.0 * p.0 + p.1 * p.1 < 1.6 * 1.6).count();
    println!("ideal rule, flag beyond 1.6, on the test orders: missed fraud {}/100, false alarms 0/300, total {}/400", ideal, ideal);
    let radii: Vec<f64> = (0..360).map(|d| { let a = d as f64 * PI / 180.0;
        (0..400).map(|r| r as f64 / 100.0).find(|&r| score(&tr, &ytr, &al, b, &k5, (r * a.cos(), r * a.sin())) > 0.0).unwrap() }).collect();
    let (rmin, rmax, rmean) = (radii.iter().cloned().fold(9.0, f64::min), radii.iter().cloned().fold(0.0, f64::max), radii.iter().sum::<f64>() / 360.0);
    println!("boundary radius on 360 rays: amount axis {:.2}, smallest {:.2}, largest {:.2}, mean {:.2}", radii[0], rmin, rmax, rmean);
    let (al_l, b_l, _, miss_line) = run("linear SVM, C 10", &dot, 10.0, &tr, &te); let w_l = weights(&tr, &ytr, &al_l);
    println!("linear SVM answer: |w| = {:.6}  b = {:.4}", dot(w_l, w_l).sqrt(), b_l);
    let mut cut = (161, 0, 0.0);                                  // every straight cut round the circle: the fewest training errors
    for k in 0..3600 {
        let u = ((2.0 * PI * k as f64 / 3600.0).cos(), (2.0 * PI * k as f64 / 3600.0).sin());
        let mut pr: Vec<(f64, f64)> = tr.iter().zip(&ytr).map(|(&x, &s)| (dot(u, x), s)).collect(); pr.sort_by(|p, q| p.partial_cmp(q).unwrap());
        let mut e = 120;                                              // cut below every order: all 120 honest flagged
        for &(t, s) in &pr { e += s as i32; if e < cut.0 { cut = (e, k, t); } }   // move the cut past this order; flag only u.x > t
    }
    let (cut_err, kc, tc) = cut; let uc = ((2.0 * PI * kc as f64 / 3600.0).cos(), (2.0 * PI * kc as f64 / 3600.0).sin());
    let flag = |pts: &[P]| pts.iter().filter(|&&p| dot(uc, p) > tc).count();
    let (cut_miss, cut_alarm, recount) = (100 - flag(&te[300..]), flag(&te[..300]), 40 - flag(&tr[120..]) + flag(&tr[..120]));
    println!("best straight cut, 3600 directions: flag u.x > {:.4} at {:.1} deg  train errors {}/160  test: missed fraud {}/100, false alarms {}/300, total {}/400",
             tc, kc as f64 / 10.0, cut_err, cut_miss, cut_alarm, cut_miss + cut_alarm);
    run("radial, gamma 50", &rbf(50.0), 10.0, &tr, &te);
    let (trp, tep): (Vec<P>, Vec<P>) = (tr.iter().map(|p| (20.0 * p.0, p.1)).collect(), te.iter().map(|p| (20.0 * p.0, p.1)).collect());
    run("radial, amount in pounds", &k5, 10.0, &trp, &tep);
    run("try: radial, C 0.1", &k5, 0.1, &tr, &te);
    run("try: radial, gamma 2", &rbf(2.0), 10.0, &tr, &te);
    println!("full shop: kernel table 20000 x 20000 = {:.0} million entries, {:.1} GB", 20000.0 * 20000.0 / 1e6, 20000.0 * 20000.0 * 8.0 / 1e9);

    assert!((2.0 / nw - 3.0 / 2f64.sqrt()).abs() < 1e-9 && (scan - 3.0 / 2f64.sqrt()).abs() < 1e-6, "dual, scan and hand must agree");
    assert!((nw * nw - sum6).abs() < 1e-9, "at the optimum |w|^2 equals the sum of the alphas");
    assert!(pgap < 1.0 / nw - 0.1, "the perceptron's line is a worse fit than the widest one");
    assert!((gap7 + 1.0 / 5f64.sqrt()).abs() < 1e-3, "scan meets the hand value: the seventh order makes the data inseparable");
    assert!(lifts < 1e-9 && (series - (-2.5f64).exp()).abs() < 1e-12, "kernel equals a dot product of features");
    assert!(0.0 <= primal - dual && primal - dual < 1e-6 * primal, "primal and dual meet at the optimum");
    assert!(recount as i32 == cut_err && miss_rbf < cut_miss && cut_miss < miss_line, "recount meets the sweep; the radial loop misses less than the best straight cut");
    assert!((rmean - 1.6).abs() < 0.2, "the radial loop sits near the circle the data were cut at");
    println!("ALL CHECKS PASS");
}
