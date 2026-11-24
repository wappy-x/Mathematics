// Propensity scores and weighting -- the same check as propensity_scores_and_weighting_check.py.
// Standard library only, no crates.  Kidney stones: A = open surgery, B = keyhole surgery.
use std::collections::BTreeMap;

fn logistic(z: f64) -> f64 { 1.0 / (1.0 + (-z).exp()) }

fn fit(xs: &[f64], ts: &[f64]) -> (f64, f64) { // logistic regression, Newton's method
    let (mut b0, mut b1) = (0.0f64, 0.0f64);
    for _ in 0..40 {
        let (mut g0, mut g1, mut h00, mut h01, mut h11) = (0.0, 0.0, 0.0, 0.0, 0.0);
        for (&x, &t) in xs.iter().zip(ts) {
            let p = logistic(b0 + b1 * x); let w = p * (1.0 - p);
            g0 += t - p; g1 += (t - p) * x; h00 += w; h01 += w * x; h11 += w * x * x;
        }
        let det = h00 * h11 - h01 * h01;
        b0 += (h11 * g0 - h01 * g1) / det; b1 += (h00 * g1 - h01 * g0) / det;
    }
    (b0, b1)
}

fn sum<I: Iterator<Item = f64>>(it: I) -> f64 { it.fold(0.0, |a, b| a + b) }

fn ipw(es: &[f64], ts: &[f64], ys: &[f64]) -> (f64, f64, f64, f64) {
    let n = ts.len() as f64;
    let z = || es.iter().zip(ts).zip(ys).map(|((&e, &t), &y)| (e, t, y));
    let ma = sum(z().map(|(e, t, y)| t * y / e)) / sum(z().map(|(e, t, _)| t / e));
    let mb = sum(z().map(|(e, t, y)| (1.0 - t) * y / (1.0 - e))) / sum(z().map(|(e, t, _)| (1.0 - t) / (1.0 - e)));
    let ss = sum(z().map(|(e, t, y)| { let v = t * (y - ma) / e - (1.0 - t) * (y - mb) / (1.0 - e); v * v }));
    (ma, mb, ma - mb, (ss / (n - 1.0) / n).sqrt())
}

fn matching(es: &[f64], ts: &[f64], ys: &[f64]) -> f64 { // nearest score in the other arm, ties averaged
    let mut pool: [BTreeMap<u64, (f64, f64)>; 2] = [BTreeMap::new(), BTreeMap::new()];
    for i in 0..ts.len() {
        let c = pool[ts[i] as usize].entry(es[i].to_bits()).or_insert((0.0, 0.0));
        c.0 += ys[i]; c.1 += 1.0;
    }
    let keys: Vec<Vec<f64>> = (0..2).map(|a| pool[a].keys().map(|&k| f64::from_bits(k)).collect()).collect();
    let mut total = 0.0;
    for i in 0..ts.len() {
        let (e, t, y) = (es[i], ts[i] as usize, ys[i]);
        let k = &keys[1 - t];
        let mut j = k.partition_point(|&v| v < e);
        if j == k.len() || (j > 0 && e - k[j - 1] <= k[j] - e) { j -= 1; }
        let c = pool[1 - t][&k[j].to_bits()]; let other = c.0 / c.1;
        total += if t == 1 { y - other } else { other - y };
    }
    total / ts.len() as f64
}

struct Rng(u64);
impl Rng {
    fn next(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}

fn main() {
    // (stone large?, got A?, patients, cured)
    let table = [(0usize, 1usize, 87usize, 81usize), (1, 1, 263, 192), (0, 0, 270, 234), (1, 0, 80, 55)];
    let (mut xs, mut ts, mut ys) = (vec![], vec![], vec![]);
    let mut cnt = [[(0.0f64, 0.0f64); 2]; 2]; // cnt[large][a] = (patients, cured)
    for &(l, a, n, c) in &table {
        for i in 0..n { xs.push(l as f64); ts.push(a as f64); ys.push(if i < c { 1.0 } else { 0.0 }); }
        cnt[l][a] = (n as f64, c as f64);
    }
    let nn = ts.len() as f64;
    let na = sum(ts.iter().cloned());
    let naive_a = sum(ts.iter().zip(&ys).map(|(t, y)| t * y)) / na;
    let naive_b = sum(ts.iter().zip(&ys).map(|(t, y)| (1.0 - t) * y)) / (nn - na);
    println!("patients {}; naive cure rate A {:.4}, B {:.4}, gap {:+.2} points", nn, naive_a, naive_b, 100.0 * (naive_a - naive_b));
    for (l, name) in [(0usize, "small"), (1, "large")] {
        let ((n1, c1), (n0, c0)) = (cnt[l][1], cnt[l][0]);
        println!("{}: A {}/{} = {:.4}, B {}/{} = {:.4}, e = {}/{} = {:.4}, weights 1/e = {:.4}, 1/(1-e) = {:.4}",
            name, c1, n1, c1 / n1, c0, n0, c0 / n0, n1, n1 + n0, n1 / (n1 + n0), (n1 + n0) / n1, (n1 + n0) / n0);
    }
    let e_count: Vec<f64> = (0..2).map(|l| cnt[l][1].0 / (cnt[l][1].0 + cnt[l][0].0)).collect();
    let (b0, b1) = fit(&xs, &ts);
    let e_fit: Vec<f64> = (0..2).map(|l| logistic(b0 + b1 * l as f64)).collect();
    println!("logistic fit: b0 {:.4}, b1 {:.4}; e(small) {:.4}, e(large) {:.4}", b0, b1, e_fit[0], e_fit[1]);
    let es: Vec<f64> = xs.iter().map(|&x| e_fit[x as usize]).collect();
    let (ma, mb, ate, se) = ipw(&es, &ts, &ys);
    println!("1 IPW over {} records: A {:.4}, B {:.4}, ATE {:+.2} points (SE {:.2})", nn, ma, mb, 100.0 * ate, 100.0 * se);
    for (a, arm) in [(1usize, "A"), (0, "B")] {
        let f = |e: f64| if a == 1 { 1.0 / e } else { 1.0 / (1.0 - e) };
        let parts: Vec<(f64, f64, f64)> = (0..2).map(|l| (cnt[l][a].1, f(e_fit[l]), cnt[l][a].0)).collect();
        let cured: Vec<String> = parts.iter().map(|&(c, w, _)| format!("{} x {:.4} = {:.1}", c, w, c * w)).collect();
        let wts: Vec<String> = parts.iter().map(|&(_, w, n)| format!("{} x {:.4} = {:.1}", n, w, n * w)).collect();
        println!("  {}: cured {} -> {:.1} / {}; weights {}", arm, cured.join(" + "), sum(parts.iter().map(|&(c, w, _)| c * w)), nn, wts.join(" + "));
    }
    let share: Vec<f64> = (0..2).map(|l| (cnt[l][0].0 + cnt[l][1].0) / nn).collect();
    let rate = |l: usize, a: usize| cnt[l][a].1 / cnt[l][a].0; // cure rate by size and arm
    let (bd_a, bd_b) = (sum((0..2).map(|l| share[l] * rate(l, 1))), sum((0..2).map(|l| share[l] * rate(l, 0))));
    let se_bd = (sum((0..2).map(|l| share[l] * ((rate(l, 1) - rate(l, 0) - bd_a + bd_b).powi(2) + rate(l, 1) * (1.0 - rate(l, 1)) / e_fit[l]
        + rate(l, 0) * (1.0 - rate(l, 0)) / (1.0 - e_fit[l])))) / nn).sqrt(); // size by size: score counted as fitted
    println!("2 back-door: A {:.4}, B {:.4}, ATE {:+.2} points (SE {:.2}, size by size); size shares {:.4}, {:.4}", bd_a, bd_b, 100.0 * (bd_a - bd_b), 100.0 * se_bd, share[0], share[1]);
    let m = matching(&es, &ts, &ys);
    println!("3 matching on the score, every patient: ATE {:+.2} points", 100.0 * m);
    let r = |i: usize| (xs[i] as usize, ts[i], ys[i], es[i]);
    let n = ts.len();
    let attm = sum((0..n).map(|i| { let (x, t, y, _) = r(i); t * (y - cnt[x][0].1 / cnt[x][0].0) })) / na;
    let wb: Vec<f64> = (0..n).map(|i| { let (_, t, _, e) = r(i); (1.0 - t) * e / (1.0 - e) }).collect();
    let att_w = naive_a - sum((0..n).map(|i| wb[i] * ys[i])) / sum(wb.iter().cloned());
    println!("ATT (A patients only): matching {:+.2} points, odds weights e/(1-e) {:+.2} points", 100.0 * attm, 100.0 * att_w);
    let wsum_a = sum((0..n).map(|i| ts[i] / es[i]));
    let wsum_b = sum((0..n).map(|i| (1.0 - ts[i]) / (1.0 - es[i])));
    let bal = [sum((0..n).map(|i| ts[i] * xs[i])) / na, sum((0..n).map(|i| (1.0 - ts[i]) * xs[i])) / (nn - na),
        sum((0..n).map(|i| ts[i] * xs[i] / es[i])) / wsum_a, sum((0..n).map(|i| (1.0 - ts[i]) * xs[i] / (1.0 - es[i]))) / wsum_b];
    println!("weights add to: A {:.1}, B {:.1}", wsum_a, wsum_b);
    println!("bars, cure percent, raw A, raw B, weighted A, weighted B: {}", [naive_a, naive_b, ma, mb].iter().map(|v| format!("{:.1}", 100.0 * v)).collect::<Vec<_>>().join(", "));
    println!("large-stone share, raw A, raw B, weighted A, weighted B: {}", bal.iter().map(|v| format!("{:.1}", 100.0 * v)).collect::<Vec<_>>().join(", "));
    let ess_a = wsum_a * wsum_a / sum((0..n).map(|i| (ts[i] / es[i]).powi(2)));
    let ess_b = wsum_b * wsum_b / sum((0..n).map(|i| ((1.0 - ts[i]) / (1.0 - es[i])).powi(2)));
    let maxw = |es: &[f64], ts: &[f64]| es.iter().zip(ts).map(|(&e, &t)| t / e + (1.0 - t) / (1.0 - e)).fold(0.0, f64::max);
    println!("overlap: e from {:.4} to {:.4}; largest weight {:.4}; effective sizes A {:.1} of {}, B {:.1} of {}",
        es.iter().cloned().fold(1.0, f64::min), es.iter().cloned().fold(0.0, f64::max), maxw(&es, &ts), ess_a, na, ess_b, nn - na);
    let e_a = sum((0..n).map(|i| ts[i] * es[i] * ys[i])) / sum((0..n).map(|i| ts[i] * es[i]));
    let e_b = sum((0..n).map(|i| (1.0 - ts[i]) * (1.0 - es[i]) * ys[i])) / sum((0..n).map(|i| (1.0 - ts[i]) * (1.0 - es[i])));
    let one_b = sum((0..n).map(|i| (1.0 - ts[i]) * ys[i] / es[i])) / nn;
    println!("wrong: weight by e, not 1/e: A {:.4}, B {:.4}, gap {:+.2} points", e_a, e_b, 100.0 * (e_a - e_b));
    println!("wrong: 1/e for B patients too: B 'cure rate' {:.4}", one_b);

    // simulation: stone diameter in mm, a covariate with no strata
    let mut rng = Rng(20261123);
    let ns = 20000usize;
    println!("simulation: SplitMix64 seed 20261123, {} patients, diameter 2-20 mm", ns);
    let mut res = vec![];
    for (label, slope) in [("mild", 0.25f64), ("steep", 0.9)] {
        let (mut d, mut t, mut y, mut truth) = (vec![], vec![], vec![], 0.0);
        for _ in 0..ns {
            let x = 2.0 + 18.0 * rng.next();
            let (pa, pb) = (logistic(3.2 - 0.2 * x), logistic(2.6 - 0.2 * x));
            let a = if rng.next() < logistic(slope * (x - 11.0)) { 1.0 } else { 0.0 };
            let u = rng.next();
            d.push(x); t.push(a); y.push(if u < (if a == 1.0 { pa } else { pb }) { 1.0 } else { 0.0 }); truth += pa - pb;
        }
        truth /= ns as f64;
        let (_c0, c1) = fit(&d, &t);
        let es: Vec<f64> = d.iter().map(|&x| logistic(_c0 + c1 * x)).collect();
        let (_, _, sate, sse) = ipw(&es, &t, &y);
        let (sm, na) = (matching(&es, &t, &y), sum(t.iter().cloned()));
        let nv = sum(t.iter().zip(&y).map(|(a, v)| a * v)) / na - sum(t.iter().zip(&y).map(|(a, v)| (1.0 - a) * v)) / (ns as f64 - na);
        println!("  {}: fitted slope {:.4} (true {}); truth {:+.2}; naive {:+.2}; IPW {:+.2} (SE {:.2}); matching {:+.2}",
            label, c1, slope, 100.0 * truth, 100.0 * nv, 100.0 * sate, 100.0 * sse, 100.0 * sm);
        for g in [1.0, 0.0] { // each arm: the weight each patient carries, effective size, balance
            let r: Vec<(f64, f64)> = (0..ns).filter(|&i| t[i] == g).map(|i| (g / es[i] + (1.0 - g) / (1.0 - es[i]), d[i])).collect();
            let (tw, top, nr) = (sum(r.iter().map(|p| p.0)), r.iter().map(|p| p.0).fold(0.0, f64::max), r.len() as f64);
            println!("    arm {}: largest weight {:.1} ({:.1}% of the arm's weight); effective size {:.0} of {}; mean diameter {:.2} mm raw, {:.2} weighted", if g == 1.0 { "A" } else { "B" },
                top, 100.0 * top / tw, tw * tw / sum(r.iter().map(|p| p.0 * p.0)), nr, sum(r.iter().map(|p| p.1)) / nr, sum(r.iter().map(|p| p.0 * p.1)) / tw);
        }
        res.push((truth, nv, sate, sse, sm));
    }

    assert!((0..2).all(|l| (e_fit[l] - e_count[l]).abs() < 1e-9), "logistic fit must reproduce the counted shares");
    assert!((ma - bd_a).abs() < 1e-12 && (mb - bd_b).abs() < 1e-12, "IPW over records must equal the back-door formula");
    assert!((m - (bd_a - bd_b)).abs() < 1e-12, "matching on the score must equal the back-door ATE");
    assert!((attm - att_w).abs() < 1e-12, "ATT by matching must equal ATT by odds weights");
    assert!((bal[2] - share[1]).abs() < 1e-12 && (bal[3] - share[1]).abs() < 1e-12, "weighting must balance stone size");
    assert!(naive_a < naive_b && bd_a > bd_b, "Simpson reversal: B looks better raw, A is better adjusted");
    for &(truth, nv, sate, sse, sm) in &res {
        assert!((sate - truth).abs() < 4.0 * sse && (sm - truth).abs() < 4.0 * sse, "IPW and matching within 4 SE of truth");
        assert!((nv - truth).abs() > 4.0 * sse, "the naive gap must be visibly biased");
    }
    assert!(res[1].3 > res[0].3, "poorer overlap must widen the standard error");
    println!("ALL CHECKS PASS");
}
