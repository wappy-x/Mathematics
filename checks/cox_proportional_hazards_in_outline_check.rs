// Cox regression in outline -- the check behind the card.  Rust std only.  One covariate,
// x = 1 for a smoker, 0 for a non-smoker.  The fit on ten men is reached three ways: by hand (the score
// is zero at hazard ratio 2), Newton's method on risk-set counts, and a golden-section climb on the raw
// partial-likelihood product.  Simulated cohorts use SplitMix64, seed 20260929, the same draws as Python.
type Row = (f64, u32, u32); // (years followed, 1 = died / 0 = left alive, 1 = smoker / 0 = non-smoker)
struct Rng(u64);
impl Rng { fn unif(&mut self) -> f64 { // SplitMix64: a uniform number in [0, 1)
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0 } }
fn sorted(data: &[Row]) -> Vec<Row> { // latest time first; the sort is stable
    let mut rows = data.to_vec(); rows.sort_by(|a, b| b.0.partial_cmp(&a.0).unwrap()); rows }
// road 1: risk sets counted from the latest time back; men with equal times join together
fn score(b: f64, rows: &[Row]) -> (f64, f64) {
    let r = b.exp();
    let (mut n0, mut n1, mut u, mut info, mut i) = (0u32, 0u32, 0.0, 0.0, 0usize);
    while i < rows.len() {
        let mut j = i;
        while j < rows.len() && rows[j].0 == rows[i].0 { n1 += rows[j].2; n0 += 1 - rows[j].2; j += 1; }
        let m = n1 as f64 * r / (n0 as f64 + n1 as f64 * r); // expected smoker share of a death here
        for &(_, d, x) in &rows[i..j] { if d == 1 { u += x as f64 - m; info += m * (1.0 - m); } }
        i = j;
    }
    (u, info)
}
fn fit(data: &[Row]) -> (f64, f64) { // Newton's method: step = score / information
    let rows = sorted(data);
    let (mut b, mut info) = (0.0, 0.0);
    for _ in 0..60 {
        let (u, i) = score(b, &rows);
        info = i; b += u / i;
        if u.abs() < 1e-12 { break; }
    }
    (b, 1.0 / info.sqrt())
}
fn logpl(b: f64, data: &[Row]) -> f64 { // road 2: the partial likelihood as a raw product
    let mut s = 0.0;
    for &(t, d, x) in data {
        if d == 0 { continue; }
        let den: f64 = data.iter().filter(|r| r.0 >= t).map(|r| (b * r.2 as f64).exp()).sum();
        s += ((b * x as f64).exp() / den).ln();
    }
    s
}
fn golden(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 { // no slope formula
    let g = (5.0f64.sqrt() - 1.0) / 2.0;
    for _ in 0..200 {
        let (a, c) = (hi - g * (hi - lo), lo + g * (hi - lo));
        if f(a) > f(c) { hi = c; } else { lo = a; }
    }
    (lo + hi) / 2.0
}
fn show(label: &str, v: &[f64]) { let s: String = v.iter().map(|x| format!("{:>11.4}", x)).collect(); println!("{:<44}{}", label, s); }
fn h0cum(t: f64, k: f64) -> f64 { 0.25 * (t / 10.0).powf(k) } // baseline: 0.25 by year 10
fn draw_time(g: &mut Rng, x: u32, k: f64, early: bool) -> f64 { // invert S(T) = a uniform draw
    let (e, h5) = (-(1.0 - g.unif()).ln(), h0cum(5.0, k));
    let h = if x == 1 && early { if e < 4.0 * h5 { e / 4.0 } else { e - 3.0 * h5 } }
            else { e / (if x == 1 { 2.0 } else { 1.0 }) };
    10.0 * (h / 0.25).powf(1.0 / k)
}
fn cohort(g: &mut Rng, n: usize, k: f64, early: bool) -> Vec<Row> { // 10 years, 3% a year drop out
    (0..n).map(|i| {
        let x = (i % 2) as u32; let t = draw_time(g, x, k, early);
        let c = (-(1.0 - g.unif()).ln() / 0.03).min(10.0);
        (t.min(c), if t <= c { 1 } else { 0 }, x)
    }).collect()
}
fn main() {
    let men: Vec<Row> = vec![(1.0, 1, 1), (2.0, 0, 0), (3.0, 1, 1), (4.0, 1, 1), (5.0, 1, 0),
                             (6.0, 0, 1), (7.0, 1, 0), (8.0, 1, 0), (9.0, 1, 1), (10.0, 0, 0)];
    let mut g = Rng(20260929);
    println!("event year, smokers at risk, non-smokers at risk, died a smoker?, at HR 2: smoker share m, m(1-m)");
    let (mut tot, mut inf) = (0.0, 0.0);
    for &(t, d, x) in &men {
        if d == 1 {
            let n1 = men.iter().filter(|r| r.0 >= t && r.2 == 1).count();
            let n0 = men.iter().filter(|r| r.0 >= t && r.2 == 0).count();
            let m = (2 * n1) as f64 / (2 * n1 + n0) as f64; tot += m; inf += m * (1.0 - m);
            println!("  {:>2} {:>3} {:>3} {:>3} {:>9.4}{:>9.4}", t as u32, n1, n0, x, m, m * (1.0 - m));
        }
    }
    let obs: u32 = men.iter().map(|r| r.1 * r.2).sum();
    show("hand: expected, observed smoker deaths; info", &[tot, obs as f64, inf]);
    let (b1, se1) = fit(&men);
    show("1 Newton: beta, HR, SE of beta", &[b1, b1.exp(), se1]);
    let b2 = golden(&|b| logpl(b, &men), -3.0, 3.0);
    let h = 1e-3;
    let se2 = 1.0 / (-(logpl(b2 + h, &men) - 2.0 * logpl(b2, &men) + logpl(b2 - h, &men)) / (h * h)).sqrt();
    show("2 golden climb: beta, HR, SE by curvature", &[b2, b2.exp(), se2]);
    show("hand: ln 2", &[2.0f64.ln()]);
    show("95% interval for the HR", &[(b1 - 1.96 * se1).exp(), (b1 + 1.96 * se1).exp()]);
    show("log partial likelihood at beta = 0, at fit", &[logpl(0.0, &men), logpl(b1, &men)]);
    let (u0, i0) = score(0.0, &sorted(&men));
    show("score test at HR 1 (log-rank): z", &[u0 / i0.sqrt()]);
    assert!((b1 - 2.0f64.ln()).abs() < 1e-10);
    assert!((b2 - b1).abs() < 1e-7);
    assert!((se2 - se1).abs() < 1e-5);
    let (n, mut s) = (200000, 0); // race of two, falling baseline: who dies first?
    for _ in 0..n {
        let ts = draw_time(&mut g, 1, 0.5, false);
        if ts < draw_time(&mut g, 0, 0.5, false) { s += 1; }
    }
    let p = s as f64 / n as f64;
    let (nn, a, bb) = (20000, 0.0, 8.0); // the same race by Simpson's rule, rising baseline, t = 10 u^2
    let mut tot = 0.0;
    for i in 0..=nn {
        let u = a + i as f64 * (bb - a) / nn as f64; let t = 10.0 * u * u;
        let f = 2.0 * 0.0375 * u * (-3.0 * h0cum(t, 1.5)).exp() * 20.0 * u;
        tot += f * (if i == 0 || i == nn { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 });
    }
    let integ = tot * (bb - a) / nn as f64 / 3.0;
    let sep = (p * (1.0 - p) / n as f64).sqrt();
    show("race: exact 2/3, Simpson (rising h0)", &[2.0 / 3.0, integ]);
    show("race: simulated (falling h0), SE", &[p, sep]);
    assert!((integ - 2.0 / 3.0).abs() < 1e-9);
    assert!((p - 2.0 / 3.0).abs() < 4.0 * sep);
    let big = cohort(&mut g, 1000, 1.5, false);
    let (bbig, sebig) = fit(&big);
    let deaths: u32 = big.iter().map(|r| r.1).sum();
    println!("{:<44}{:>11.4}{:>11.4}", format!("1,000 men: {} deaths", deaths), bbig, sebig);
    show("1,000 men: HR and its 95% interval", &[bbig.exp(), (bbig - 1.96 * sebig).exp(), (bbig + 1.96 * sebig).exp()]);
    for &k in &[1.5, 0.5] {
        let (mut bs, mut ses) = (Vec::new(), Vec::new());
        for _ in 0..400 {
            let (bk, sk) = fit(&cohort(&mut g, 200, k, false)); bs.push(bk); ses.push(sk);
        }
        let mb = bs.iter().sum::<f64>() / 400.0;
        let sd = (bs.iter().map(|v| (v - mb) * (v - mb)).sum::<f64>() / 399.0).sqrt();
        let mse = ses.iter().sum::<f64>() / 400.0;
        show(&format!("400 cohorts of 200, k={}: mean beta, SE", k), &[mb, sd / 20.0]);
        show("  spread of beta, average reported SE", &[sd, mse]);
        assert!((mb - 2.0f64.ln()).abs() < 4.0 * sd / 20.0);
        assert!((mse - sd).abs() < 0.15 * sd);
    }
    let w1: Vec<Row> = men.iter().map(|r| (r.0, 1, r.2)).collect();
    let w2: Vec<Row> = men.iter().filter(|r| r.1 == 1).cloned().collect();
    show("wrong: count leavers as deaths, HR", &[fit(&w1).0.exp()]);
    show("wrong: drop the leavers, HR", &[fit(&w2).0.exp()]);
    show("doctors: risk 0.24; doubled; rate doubled", &[0.24, 2.0 * 0.24, 1.0 - (1.0 - 0.24) * (1.0 - 0.24)]);
    let (r0, r1) = (1.0 - (-0.25f64).exp(), 1.0 - (-0.5f64).exp());
    show("10-year risk: non-smoker, smoker, ratio", &[r0, r1, r1 / r0]);
    let cr = cohort(&mut g, 2000, 1.5, true);
    show("crossing: fitted HR overall", &[fit(&cr).0.exp()]);
    let early: Vec<Row> = cr.iter().map(|r| (r.0.min(5.0), if r.0 <= 5.0 { r.1 } else { 0 }, r.2)).collect();
    let late: Vec<Row> = cr.iter().map(|r| (r.0, if r.0 > 5.0 { r.1 } else { 0 }, r.2)).collect();
    show("  first 5 years, after year 5", &[fit(&early).0.exp(), fit(&late).0.exp()]);
    println!("chart hazard per 1,000 a year, years 1..10:");
    for c in [1.0, 2.0] {
        let v: Vec<String> = (1..=10).map(|t| format!("{:.2}", c * 1000.0 * 0.375 * (t as f64 / 10.0).powf(0.5) / 10.0)).collect();
        println!("  {}", v.join(", "));
    }
    println!("chart survival, years 0..10:");
    for c in [1.0, 2.0] {
        let v: Vec<String> = (0..=10).map(|t| format!("{:.2}", (-c * h0cum(t as f64, 1.5)).exp())).collect();
        println!("  {}", v.join(", "));
    }
    let ends: Vec<String> = men.iter().map(|r| (60 + 28 * r.0 as u32).to_string()).collect();
    println!("figure, line ends x = 60 + 28 t: {}", ends.join(", "));
    let ys: Vec<String> = (0..10).map(|i| (20 + 20 * i).to_string()).collect();
    println!("figure, rows y = 20 + 20 i: {}", ys.join(", "));
    let f6: Vec<Row> = men.iter().map(|r| (r.0, if r.0 == 6.0 { 1 } else { r.1 }, r.2)).collect();
    show("try: F dies at 6 instead of leaving, HR", &[fit(&f6).0.exp()]);
    let twice: Vec<Row> = men.iter().chain(men.iter()).cloned().collect();
    let (bd, sed) = fit(&twice); show("try: every man counted twice, HR, SE", &[bd.exp(), sed]);
    let flip: Vec<Row> = men.iter().map(|r| (r.0, r.1, 1 - r.2)).collect();
    let bn = fit(&flip).0; show("try: code non-smokers as 1, beta, HR", &[bn, bn.exp()]);
    println!("ALL CHECKS PASS");
}
