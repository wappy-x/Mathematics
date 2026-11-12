// Loss and empirical risk -- the check behind the card.  std only, no crates.
// Data: 20,000 SYNTHETIC orders from a stated rule and seed (SplitMix64, written out).
struct SplitMix64 { x: u64 }
impl SplitMix64 {
    fn u(&mut self) -> f64 {                       // a uniform number in [0, 1)
        self.x = self.x.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.x;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}
// the hidden rule: bias 4, then one weight per number; 5 of the 12 numbers do nothing
const TRUE: [f64; 13] = [4.0, 6.0, 1.1, 0.4, -0.05, 0.0, 0.0, 3.0, 0.0, 2.0, 0.0, 0.0, 0.2];
type Row = (Vec<f64>, f64);

fn nsum<I: Iterator<Item = f64>>(it: I) -> f64 {  // compensated sum, the same as Python's sum()
    let (mut s, mut c) = (0.0f64, 0.0f64);
    for x in it {
        let t = s + x;
        if s.abs() >= x.abs() { c += (s - t) + x; } else { c += (x - t) + s; }
        s = t;
    }
    s + c
}
fn dot(w: &[f64], x: &[f64]) -> f64 { nsum(w.iter().zip(x).map(|(a, b)| a * b)) }
fn flag(c: bool) -> f64 { if c { 1.0 } else { 0.0 } }
fn order(g: &mut SplitMix64) -> Row {   // 1, items, avg price, past orders, days since last, ...
    let x = vec![1.0, 1.0 + (8.0 * g.u()).floor(), 5.0 + 40.0 * g.u(), (21.0 * g.u()).floor(),
        (91.0 * g.u()).floor(), flag(g.u() < 0.6), (24.0 * g.u()).floor(), flag(g.u() < 0.25),
        1.0 + 49.0 * g.u(), flag(g.u() < 0.3), 10.0 * g.u(), flag(g.u() < 0.4), 1.0 + (40.0 * g.u()).floor()];
    let y = dot(&TRUE, &x) - 30.0 * (1.0 - g.u()).ln();          // skewed extra spend
    (x, y)
}
fn sq_risk(c: f64, ys: &[f64]) -> f64 { nsum(ys.iter().map(|y| (y - c).powi(2))) / ys.len() as f64 }
fn abs_risk(c: f64, ys: &[f64]) -> f64 { nsum(ys.iter().map(|y| (y - c).abs())) / ys.len() as f64 }
fn median(ys: &[f64]) -> f64 {
    let mut s = ys.to_vec(); s.sort_by(|a, b| a.partial_cmp(b).unwrap()); let n = s.len();
    if n % 2 == 1 { s[n / 2] } else { (s[n / 2 - 1] + s[n / 2]) / 2.0 }
}
fn ternary(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {   // road 2: search the bowl
    for _ in 0..200 {
        let (a, b) = (lo + (hi - lo) / 3.0, hi - (hi - lo) / 3.0);
        if f(a) <= f(b) { hi = b; } else { lo = a; }
    }
    (lo + hi) / 2.0
}
fn fit(rows: &[Row]) -> Vec<f64> {                 // least squares: solve (X^T X) w = X^T y
    let p = rows[0].0.len();
    let mut a = vec![vec![0.0f64; p + 1]; p];
    for (x, y) in rows {
        for i in 0..p {
            for j in 0..p { a[i][j] += x[i] * x[j]; }
            a[i][p] += x[i] * y;
        }
    }
    for c in 0..p {                                // Gaussian elimination, partial pivoting
        let mut r = c;
        for k in c..p { if a[k][c].abs() > a[r][c].abs() { r = k; } }
        a.swap(c, r);
        for k in c + 1..p {
            let f = a[k][c] / a[c][c];
            for j in c..p + 1 { a[k][j] -= f * a[c][j]; }
        }
    }
    let mut w = vec![0.0f64; p];
    for c in (0..p).rev() {
        w[c] = (a[c][p] - nsum((c + 1..p).map(|j| a[c][j] * w[j]))) / a[c][c];
    }
    w
}
fn risk(w: &[f64], rows: &[Row]) -> f64 { nsum(rows.iter().map(|(x, y)| (y - dot(w, x)).powi(2))) / rows.len() as f64 }
fn show(label: &str, vals: &[f64], d: usize) {
    let v: Vec<String> = vals.iter().map(|v| format!("{:10.*}", d, v)).collect();
    println!("{:<36}{}", label, v.join(" "));
}
fn line(label: &str, vals: &[f64], width: usize, d: usize) {
    let v: Vec<String> = vals.iter().map(|v| format!("{:width$.d$}", v, width = width, d = d)).collect();
    println!("{}{}", label, v.join(" "));
}

fn main() {
    let five = [14.0, 22.0, 27.0, 35.0, 102.0];    // worked by hand on the card
    let (m5, d5) = (nsum(five.iter().copied()) / 5.0, median(&five));
    show("five orders: mean, median", &[m5, d5], 2);
    show("five: squared sum at mean, median", &[5.0 * sq_risk(m5, &five), 5.0 * sq_risk(d5, &five)], 2);
    show("five: absolute sum at mean, median", &[5.0 * abs_risk(m5, &five), 5.0 * abs_risk(d5, &five)], 2);
    for c in [m5, d5] {
        line(&format!("{:<36}", format!("five at {:.0}: squared misses", c)), &five.map(|y: f64| (y - c).powi(2)), 7, 0);
        line(&format!("{:<36}", format!("five at {:.0}: absolute misses", c)), &five.map(|y: f64| (y - c).abs()), 7, 0);
    }
    show("five: squared risk at mean, median", &[sq_risk(m5, &five), sq_risk(d5, &five)], 2);
    show("five: absolute risk at mean, median", &[abs_risk(m5, &five), abs_risk(d5, &five)], 2);
    assert!(sq_risk(m5, &five) < sq_risk(d5, &five) && abs_risk(d5, &five) < abs_risk(m5, &five));

    let mut g = SplitMix64 { x: 20261111 };
    let rows: Vec<Row> = (0..20000).map(|_| order(&mut g)).collect();
    let (train, test) = (&rows[..16000], &rows[16000..]);   // the last 4,000 are never used to fit
    let ys: Vec<f64> = train.iter().map(|r| r.1).collect();
    let yt: Vec<f64> = test.iter().map(|r| r.1).collect();
    let (mean, med) = (nsum(ys.iter().copied()) / 16000.0, median(&ys));
    let t_sq = ternary(&|c| sq_risk(c, &ys), 0.0, 500.0);
    let t_ab = ternary(&|c| abs_risk(c, &ys), 0.0, 500.0);
    show("train: mean, median order value", &[mean, med], 2);
    show("ternary search: squared, absolute", &[t_sq, t_ab], 2);
    show("constant = mean: sq risk, abs risk", &[sq_risk(mean, &ys), abs_risk(mean, &ys)], 2);
    show("constant = median: sq risk, abs risk", &[sq_risk(med, &ys), abs_risk(med, &ys)], 2);
    assert!((t_sq - mean).abs() < 1e-6 && (abs_risk(t_ab, &ys) - abs_risk(med, &ys)).abs() < 1e-9);
    assert!(sq_risk(mean, &ys) < sq_risk(med, &ys) && abs_risk(med, &ys) < abs_risk(mean, &ys));
    let gap = sq_risk(med, &ys) - sq_risk(mean, &ys);    // Step 1: the gap is exactly (median - mean)^2
    show("sq risk gap, (median - mean)^2", &[gap, (med - mean).powi(2)], 2);
    assert!((gap - (med - mean).powi(2)).abs() < 1e-6);
    let grid: Vec<f64> = (0..15).map(|i| 60.0 + 5.0 * i as f64).collect();
    line("chart, constant guess (pounds)     ", &grid, 6, 0);
    line("chart, root mean square miss       ", &grid.iter().map(|&c| sq_risk(c, &ys).powf(0.5)).collect::<Vec<_>>(), 6, 2);
    line("chart, mean absolute miss          ", &grid.iter().map(|&c| abs_risk(c, &ys)).collect::<Vec<_>>(), 6, 2);

    let w = fit(train);                            // 13 weights: bias + one per number
    show("fitted bias, items, avg price", &[w[0], w[1], w[2]], 2);
    show("fitted mobile, hour, distance", &[w[5], w[6], w[8]], 2);
    let mut truth = TRUE.to_vec(); truth[0] += 30.0;
    let (r_tr, r_te, r_true) = (risk(&w, train), risk(&w, test), risk(&truth, test));
    show("12 numbers: train risk, test risk", &[r_tr, r_te], 2);
    show("true rule + 30 on test; 900(1+13/n)", &[r_true, 900.0 * (1.0 + 13.0 / 16000.0)], 2);
    assert!((w[1] - 6.0).abs() < 0.3 && (w[2] - 1.1).abs() < 0.05 && w[6].abs() < 0.1);   // the truth comes back
    assert!((r_te - 900.0 * (1.0 + 13.0 / 16000.0)).abs() < 4.0 * 8f64.sqrt() * 900.0 / 4000f64.sqrt()); // 4 SEs; (E - 30)^2 has SD sqrt(8) * 900
    assert!(r_tr < sq_risk(mean, &ys));
    let grad: Vec<f64> = (0..13).map(|i| nsum(train.iter().map(|(x, y)| 2.0 * (dot(&w, x) - y) * x[i])) / 16000.0).collect();
    let gmax = grad.iter().fold(0.0f64, |m, v| m.max(v.abs()));
    show("largest slope of risk at the fit", &[gmax], 2);
    assert!(gmax < 1e-6);
    let pred = nsum(test.iter().map(|(x, _)| dot(&w, x)));
    show("test revenue: actual, linear", &[nsum(yt.iter().copied()), pred], 2);
    show("test revenue: x mean, x median", &[4000.0 * mean, 4000.0 * med], 2);
    let act = nsum(yt.iter().copied());
    show("pred - actual: linear, mean, median", &[pred - act, 4000.0 * mean - act, 4000.0 * med - act], 2);

    let w20 = fit(&train[..20]);                   // what breaks: 13 weights from 20 orders
    show("20-order fit: train risk, test risk", &[risk(&w20, &train[..20]), risk(&w20, test)], 2);
    assert!(risk(&w20, &train[..20]) < 0.5 * r_tr && risk(&w20, test) > 1.5 * r_te);
    for k in [13, 100] {                           // try: as many orders as weights, then more
        let wk = fit(&train[..k]); show(&format!("try: {}-order fit: train, test risk", k), &[risk(&wk, &train[..k]), risk(&wk, test)], 2);
    }
    let typo: Vec<f64> = ys.iter().enumerate().map(|(i, y)| if i < 100 { y * 100.0 } else { *y }).collect();
    let tmean = nsum(typo.iter().copied()) / 16000.0;   // 100 orders keyed in pence, not pounds
    let shift = 99.0 * nsum(ys[..100].iter().copied()) / 16000.0;
    show("100 typos: mean, median", &[tmean, median(&typo)], 2);
    show("mean shift: run, 99*sum(first 100)/n", &[tmean - mean, shift], 2);
    assert!((tmean - mean - shift).abs() < 1e-9 && median(&typo) - med < 1.0);

    let margins = [-2.0, -1.0, 0.0, 1.0, 2.0, 3.0];   // yes/no: will the order be returned?
    line("margin m = y*s       ", &margins, 7, 4);
    line("zero-one loss        ", &margins.map(|m: f64| flag(m <= 0.0)), 7, 4);
    line("hinge max(0, 1-m)    ", &margins.map(|m: f64| (1.0 - m).max(0.0)), 7, 4);
    line("log ln(1+e^-m)       ", &margins.map(|m: f64| (1.0 + (-m).exp()).ln()), 7, 4);
    let ll = |p: f64, q: f64| -(q * p.ln() + (1.0 - q) * (1.0 - p).ln());   // average log loss when a chance q comes true
    let hinge = |s: f64, q: f64| q * (1.0 - s).max(0.0) + (1.0 - q) * (1.0 + s).max(0.0);
    for q in [0.1, 0.4] {                          // 1 in 10 such orders comes back; try 4 in 10
        let mut best_p = 0.001;
        for k in 1..1000 { let p = k as f64 / 1000.0; if ll(p, q) < ll(best_p, q) { best_p = p; } }
        let mut best_s = -3.0;
        for k in -300..301 { let s = k as f64 / 100.0; if hinge(s, q) < hinge(best_s, q) { best_s = s; } }
        show(&format!("q = {}: best p by grid, its log loss", q), &[best_p, ll(best_p, q)], 4);
        show(&format!("q = {}: best score, its hinge", q), &[best_s, hinge(best_s, q)], 4);
        assert!((best_p - q).abs() < 1e-9 && (best_s + 1.0).abs() < 1e-9 && (hinge(best_s, q) - 2.0 * q).abs() < 1e-9);
    }
    show("q = 0.1: log loss at p = 0.3, 0.5", &[ll(0.3, 0.1), ll(0.5, 0.1)], 4);
    println!("ALL CHECKS PASS");
}
