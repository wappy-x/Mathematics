// Tangency portfolio and capital market line: house market (shares, bonds, gold), riskless rate 2%.
// Roads: (1) solve Sigma z = d; (2) sqrt(d.z); (3) grid search on the Sharpe ratio;
// (4) frontier geometry from a, b, c; (5) least variance for a target return, bank allowed.
const N: usize = 3;
const MU: [f64; N] = [0.08, 0.04, 0.05]; // expected one-year returns
const SD: [f64; N] = [0.20, 0.06, 0.15]; // standard deviations
const RHO: [[f64; N]; N] = [[1.0, 0.2, 0.1], [0.2, 1.0, 0.0], [0.1, 0.0, 1.0]];
const RF: f64 = 0.02; // riskless one-year return

// Gaussian elimination with partial pivoting
fn solve(a: &Vec<Vec<f64>>, b: &[f64]) -> Vec<f64> {
    let m = b.len();
    let mut mm: Vec<Vec<f64>> = (0..m).map(|i| { let mut r = a[i].clone(); r.push(b[i]); r }).collect();
    for c in 0..m {
        let mut p = c;
        for r in c + 1..m { if mm[r][c].abs() > mm[p][c].abs() { p = r; } }
        mm.swap(c, p);
        for r in 0..m {
            if r != c {
                let f = mm[r][c] / mm[c][c];
                let pivot = mm[c].clone();
                for k in 0..=m { mm[r][k] -= f * pivot[k]; }
            }
        }
    }
    (0..m).map(|i| mm[i][m] / mm[i][i]).collect()
}
fn dot(x: &[f64], y: &[f64]) -> f64 { x.iter().zip(y).fold(0.0, |s, (a, b)| s + a * b) }
fn quad(w: &[f64], cov: &Vec<Vec<f64>>) -> f64 {
    let mut v = 0.0;
    for i in 0..N { for j in 0..N { v += w[i] * cov[i][j] * w[j]; } }
    v
}
fn sharpe(w: &[f64], r: f64, s: &Vec<Vec<f64>>) -> f64 { (dot(w, &MU) - r) / quad(w, s).sqrt() }
// w_T = Sigma^-1 d / (1' Sigma^-1 d)
fn tangency(r: f64, cov: &Vec<Vec<f64>>) -> (Vec<f64>, f64, Vec<f64>) {
    let d: Vec<f64> = MU.iter().map(|x| x - r).collect();
    let z = solve(cov, &d);
    let t = z.iter().fold(0.0, |s, x| s + x);
    (z.iter().map(|x| x / t).collect(), t, z)
}
fn row(label: &str, vals: &[f64], p: usize) {
    let mut s = format!("{:<38}", label);
    for v in vals { s += &format!("{:>11.*}", p, v); }
    println!("{}", s);
}

fn main() {
    let s: Vec<Vec<f64>> = (0..N).map(|i| (0..N).map(|j| RHO[i][j] * SD[i] * SD[j]).collect()).collect();
    // road 1: the formula
    let d: Vec<f64> = MU.iter().map(|x| x - RF).collect();
    let (wt, dd, z) = tangency(RF, &s);
    let (mt, st) = (dot(&wt, &MU), quad(&wt, &s).sqrt());
    let sht = (mt - RF) / st;
    for i in 0..N { row(&format!("covariance Sigma, row {}", i + 1), &s[i], 6); }
    row("excess returns d = mu - rf", &d, 6);
    row("road 1  z solving Sigma z = d", &z, 6);
    row("        D = sum of z", &[dd], 6);
    row("        tangency weights w_T", &wt, 6);
    row("        terms w_i mu_i", &wt.iter().zip(&MU).map(|(w, m)| w * m).collect::<Vec<_>>(), 6);
    row("        mean, sd of w_T", &[mt, st], 6);
    row("        Sharpe (mu_T - rf)/sigma_T", &[sht], 6);
    // road 2: Sharpe as a quadratic form, no weights
    let h = dot(&d, &z);
    row("road 2  terms d_i z_i", &d.iter().zip(&z).map(|(p, q)| p * q).collect::<Vec<_>>(), 6);
    row("        H = d . z, sqrt(H)", &[h, h.sqrt()], 6);
    // road 3: zooming grid search over w1, w2 (w3 = 1 - w1 - w2)
    let (mut c1, mut c2, mut half) = (1.0 / 3.0, 1.0 / 3.0, 1.0);
    for _ in 0..60 {
        let mut best = (-1e9, c1, c2);
        for i in -10..=10 {
            for j in -10..=10 {
                let w1 = c1 + half * (i as f64) / 10.0;
                let w2 = c2 + half * (j as f64) / 10.0;
                let sh = sharpe(&[w1, w2, 1.0 - w1 - w2], RF, &s);
                if sh > best.0 { best = (sh, w1, w2); }
            }
        }
        c1 = best.1; c2 = best.2;
        half *= 0.5;
    }
    let wg = [c1, c2, 1.0 - c1 - c2];
    row("road 3  grid-search weights", &wg, 6);
    row("        grid-search Sharpe", &[sharpe(&wg, RF, &s)], 6);
    // road 4: the risky-only frontier, sigma^2 = (a m^2 - 2 b m + c) / (a c - b^2)
    let (za, zb) = (solve(&s, &[1.0; N]), solve(&s, &MU));
    let (a, b, c) = (za.iter().sum::<f64>(), zb.iter().sum::<f64>(), dot(&MU, &zb));
    let dl = a * c - b * b;
    let mf = (c - b * RF) / (b - a * RF);
    let sf = ((a * mf * mf - 2.0 * b * mf + c) / dl).sqrt();
    let slope = dl * sf / (a * mf - b);
    row("road 4  a, b, c", &[a, b, c], 6);
    row("        min-variance mean, sd", &[b / a, 1.0 / a.sqrt()], 6);
    row("        mean where CML meets frontier", &[mf], 6);
    row("        frontier slope at that point", &[slope], 6);
    // road 5: least variance for a target return with the bank; two-fund separation
    let mut outs: Vec<(Vec<f64>, f64, f64, f64)> = Vec::new();
    for (label, target) in [("cautious 3%", 0.03), ("bold 8%", 0.08)] {
        let mut a4: Vec<Vec<f64>> = (0..N).map(|i| { let mut r = s[i].clone(); r.push(-d[i]); r }).collect();
        let mut last = d.clone(); last.push(0.0); a4.push(last);
        let x: Vec<f64> = solve(&a4, &[0.0, 0.0, 0.0, target - RF])[..N].to_vec();
        let y: f64 = x.iter().sum();
        let sx = quad(&x, &s).sqrt();
        row(&format!("road 5  {}: risky y, bank", label), &[y, 1.0 - y], 6);
        row(&format!("        {}: mix x / y", label), &x.iter().map(|v| v / y).collect::<Vec<_>>(), 6);
        row(&format!("        {}: sd, CML sd", label), &[sx, (target - RF) / h.sqrt()], 6);
        let mut dol: Vec<f64> = x.iter().map(|v| 10000.0 * v).collect(); dol.push(10000.0 * (1.0 - y));
        row(&format!("        {}: dollars of 10,000", label), &dol, 2);
        outs.push((x, y, sx, target));
    }
    // single assets and other mixes, by Sharpe
    let gmv: Vec<f64> = za.iter().map(|v| v / a).collect();
    let third = 1.0 / 3.0;
    let mixes: [(&str, Vec<f64>); 6] = [("shares", vec![1.0, 0.0, 0.0]), ("bonds", vec![0.0, 1.0, 0.0]),
        ("gold", vec![0.0, 0.0, 1.0]), ("equal thirds", vec![third; 3]), ("min-variance", gmv.clone()), ("tangency", wt.clone())];
    for (name, w) in mixes.iter() { row(&format!("Sharpe: {}", name), &[sharpe(w, RF, &s)], 4); }
    // what breaks: each wrong fund, levered to the bold investor's sd
    let w0 = tangency(0.0, &s).0;
    let diag: Vec<Vec<f64>> = (0..N).map(|i| (0..N).map(|j| if i == j { s[i][j] } else { 0.0 }).collect()).collect();
    let wd = tangency(RF, &diag).0;
    let (yb, sb) = (outs[1].1, outs[1].2);
    row("wrong: forgot rf, weights", &w0, 6);
    row("wrong: no correlations, weights", &wd, 6);
    for (name, w) in [("forgot rf", &w0), ("no correlations", &wd), ("min-variance fund", &gmv)] {
        let sh = sharpe(w, RF, &s);
        row(&format!("wrong: {}, Sharpe, mean", name), &[sh, RF + sh * sb], 6);
    }
    row("wrong: borrow at 4%, bold mean", &[yb * mt - (yb - 1.0) * 0.04], 6);
    let fr4 = (b + (dl * (a * sb * sb - 1.0)).sqrt()) / a; // borrowing dear: the curve itself is best at sd sb
    row("borrow at 4%: frontier mean at bold sd", &[fr4], 6);
    // try changing the riskless rate
    for r in [0.01, 0.03] {
        let (mut w, _, _) = tangency(r, &s);
        let sh = sharpe(&w, r, &s);
        w.push(sh);
        row(&format!("try: rf = {:.2}, weights, Sharpe", r), &w, 4);
    }
    let (w5, d5, _) = tangency(0.05, &s);
    row("try: rf = 0.05, D, excess mean", &[d5, dot(&w5, &MU) - 0.05], 6);
    // chart: upper frontier and CML, sd 6..20 percent
    let xs = [0.06, 0.08, 0.10, 0.12, 0.14, 0.16, 0.18, 0.20];
    row("chart, sd %", &xs.iter().map(|x| 100.0 * x).collect::<Vec<_>>(), 2);
    row("chart, frontier mean %", &xs.iter().map(|x| 100.0 * (b + (dl * (a * x * x - 1.0)).sqrt()) / a).collect::<Vec<_>>(), 2);
    row("chart, CML mean %", &xs.iter().map(|x| 100.0 * (RF + h.sqrt() * x)).collect::<Vec<_>>(), 2);

    assert!(wg.iter().zip(&wt).all(|(p, q)| (p - q).abs() < 1e-6), "grid search must find the formula's weights");
    assert!((sht - h.sqrt()).abs() < 1e-12, "Sharpe from weights vs quadratic form");
    assert!((mf - mt).abs() < 1e-12 && (slope - sht).abs() < 1e-9, "frontier touches the CML at w_T");
    for (x, y, sx, tg) in &outs {
        assert!(x.iter().zip(&wt).all(|(v, t)| (v / y - t).abs() < 1e-10), "every efficient mix holds w_T");
        assert!((sx - y * st).abs() < 1e-12 && (sx - (tg - RF) / h.sqrt()).abs() < 1e-12, "on the CML");
    }
    assert!((dd - (b - RF * a)).abs() < 1e-12, "D from Sigma^-1 d vs b - rf a");
    let levered4 = yb * mt - (yb - 1.0) * 0.04;
    assert!(RF + h.sqrt() * sb > fr4 && fr4 > levered4, "CML above curve above levering at 4%");
    assert!(d5 < 0.0 && dot(&w5, &MU) < 0.05, "rf above b/a: D < 0, lower branch");
    let pct: Vec<f64> = wt.iter().map(|v| (1000.0 * v).round() / 10.0).collect();
    assert!(pct == vec![15.8, 67.6, 16.6] && (1000.0 * h.sqrt()).round() / 1000.0 == 0.446, "prose figures");
    println!("ALL CHECKS PASS");
}
