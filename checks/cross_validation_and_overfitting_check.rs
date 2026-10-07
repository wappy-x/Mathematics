// Overfitting and cross-validation -- the same check as the Python, in Rust, std only.
// A tide gauge reads the harbour level at hours 0 to 9.  The true level is
// sin(pi t / 6) metres; each reading adds gauge noise of SD 0.3 m (SplitMix64
// and Box-Muller, written out) and is rounded to the centimetre.  Polynomials
// of degree 0 to 9 are fitted by least squares and judged by several roads.
use std::f64::consts::PI;

const N: usize = 10;
const SIG: f64 = 0.3;
const SEED: u64 = 20260922; const FRESH: usize = 50000; const RECORDS: usize = 10000;

fn splitmix64(s: &mut u64) -> u64 {             // the generator both languages share
    *s = s.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = (*s ^ (*s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}
fn uniform(s: &mut u64) -> f64 { ((splitmix64(s) >> 11) + 1) as f64 * 2f64.powi(-53) }
fn normal(s: &mut u64) -> f64 {                 // Box-Muller, cosine half only
    let (u1, u2) = (uniform(s), uniform(s));
    (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos()
}
fn tide(t: f64) -> f64 { (PI * t / 6.0).sin() }  // the true level, known because we built it
fn powers(t: f64, d: usize) -> Vec<f64> { (0..=d).map(|j| ((t - 4.5) / 4.5).powf(j as f64)).collect() }
fn solve(a: &[Vec<f64>], b: &[f64]) -> Vec<f64> { // Gaussian elimination with partial pivoting
    let p = b.len();
    let mut m: Vec<Vec<f64>> = (0..p).map(|i| { let mut r = a[i].clone(); r.push(b[i]); r }).collect();
    for c in 0..p {
        let k = (c..p).fold(c, |k, r| if m[r][c].abs() > m[k][c].abs() { r } else { k });
        m.swap(c, k);
        for r in c + 1..p {
            let f = m[r][c] / m[c][c];
            for j in c..=p { m[r][j] -= f * m[c][j] }
        }
    }
    let mut x = vec![0.0; p];
    for c in (0..p).rev() {
        let s: f64 = (c + 1..p).map(|j| m[c][j] * x[j]).fold(0.0, |u, v| u + v);
        x[c] = (m[c][p] - s) / m[c][c];
    }
    x
}
fn sum(v: impl Iterator<Item = f64>) -> f64 { v.fold(0.0, |a, b| a + b) }
fn gram(ts: &[f64], d: usize) -> (Vec<Vec<f64>>, Vec<Vec<f64>>) { // the rows of X, and X'X
    let rows: Vec<Vec<f64>> = ts.iter().map(|&t| powers(t, d)).collect();
    let a = (0..=d).map(|i| (0..=d).map(|j| sum(rows.iter().map(|r| r[i] * r[j]))).collect()).collect();
    (rows, a)
}
fn fit(ts: &[f64], ys: &[f64], d: usize) -> Vec<f64> { // least squares by the normal equations
    let (rows, a) = gram(ts, d);
    let b: Vec<f64> = (0..=d).map(|i| sum(rows.iter().zip(ys).map(|(r, y)| r[i] * y))).collect();
    solve(&a, &b)
}
fn pred(c: &[f64], t: f64) -> f64 { sum(c.iter().zip(powers(t, c.len() - 1)).map(|(a, b)| a * b)) }
fn hat(ts: &[f64], d: usize) -> Vec<Vec<f64>> {  // H = X (X'X)^-1 X': readings in, fitted values out
    let (rows, a) = gram(ts, d);
    let v: Vec<Vec<f64>> = rows.iter().map(|r| solve(&a, r)).collect();
    (0..N).map(|i| (0..N).map(|j| sum(rows[i].iter().zip(&v[j]).map(|(x, y)| x * y))).collect()).collect()
}
fn lagrange(ts: &[f64], ys: &[f64], t: f64) -> f64 { // degree 9 through all ten readings
    sum(ts.iter().zip(ys).map(|(&ti, &y)| {
        y * ts.iter().filter(|&&s| s != ti).fold(1.0, |acc, &s| acc * ((t - s) / (ti - s)))
    }))
}
fn loo(ts: &[f64], ys: &[f64], d: usize, i: usize) -> f64 { // refit without reading i
    let (mut t2, mut y2) = (ts.to_vec(), ys.to_vec());
    (t2.remove(i), y2.remove(i));
    ys[i] - pred(&fit(&t2, &y2, d), ts[i])
}
fn fold(ts: &[f64], ys: &[f64], d: usize, k: usize) -> f64 { // fold k holds out hours k and k + 5
    let keep: Vec<usize> = (0..N).filter(|j| j % 5 != k).collect();
    let tk: Vec<f64> = keep.iter().map(|&j| ts[j]).collect();
    let yk: Vec<f64> = keep.iter().map(|&j| ys[j]).collect();
    let c = fit(&tk, &yk, d);
    sum([k, k + 5].iter().map(|&i| (ys[i] - pred(&c, ts[i])).powi(2)))
}
fn mean_se(xs: &[f64]) -> (f64, f64) {          // an average and its standard error
    let n = xs.len() as f64;
    let m = sum(xs.iter().copied()) / n;
    (m, (sum(xs.iter().map(|x| (x - m).powi(2))) / (n - 1.0) / n).sqrt())
}
fn f4(v: f64) -> String { if v.is_nan() { "        -".to_string() } else { format!("{:9.4}", v) } }
fn join(v: impl Iterator<Item = String>) -> String { v.collect::<Vec<String>>().join(" ") }

fn main() {
    let ts: Vec<f64> = (0..N).map(|t| t as f64).collect();
    let mut state = SEED;
    let ys: Vec<f64> = ts.iter().map(|&t| ((tide(t) + SIG * normal(&mut state)) * 100.0 + 0.5).floor() / 100.0).collect();
    let fresh: Vec<(f64, f64)> = (0..FRESH).map(|_| {       // fresh readings at random hours in [0, 9]
        let u = uniform(&mut state);
        (9.0 * u, tide(9.0 * u) + SIG * normal(&mut state))
    }).collect();
    let recs: Vec<Vec<(f64, f64)>> = (0..RECORDS).map(|_| ts.iter().map(|&t| {
        let (z, z2) = (normal(&mut state), normal(&mut state));
        (tide(t) + SIG * z, tide(t) + SIG * z2)
    }).collect()).collect();
    println!("setup: {} readings at hours 0 to 9, gauge noise SD {} m, noise variance {:.4}, seed {}", N, SIG, SIG * SIG, SEED);
    println!("record, hour  {}", ts.iter().map(|t| format!("{:7.0}", t)).collect::<String>());
    println!("record, level {}", ys.iter().map(|y| format!("{:7.2}", y)).collect::<String>());
    println!("deg     train   5-fold  LOO-refit  LOO-hat   LOO-se  true-int  true-sim   sim-se  optim-sim  2s2p/n   opt-se");
    let (mut fits, mut rr, mut levs) = (Vec::new(), Vec::new(), Vec::<Vec<f64>>::new()); // rr: columns as pushed
    for d in 0..N {
        let c = fit(&ts, &ys, d);
        let h = hat(&ts, d);
        let train = sum(ts.iter().zip(&ys).map(|(&t, y)| (y - pred(&c, t)).powi(2))) / N as f64;
        let k2 = 1800usize;                               // Simpson's rule on the squared gap to the truth
        let integ = sum((0..=k2).map(|k| {
            let w = if k == 0 || k == k2 { 1.0 } else if k % 2 == 1 { 4.0 } else { 2.0 };
            let t = (k * 9) as f64 / k2 as f64;
            w * (tide(t) - pred(&c, t)).powi(2)
        })) * (9.0 / k2 as f64) / 3.0 / 9.0 + SIG * SIG;
        let (sim, sim_se) = mean_se(&fresh.iter().map(|&(t, y)| (y - pred(&c, t)).powi(2)).collect::<Vec<f64>>());
        let (mut kf, mut lr, mut lh, mut lse) = (f64::NAN, f64::NAN, f64::NAN, f64::NAN);
        if d <= 7 { kf = sum((0..5).map(|k| fold(&ts, &ys, d, k))) / N as f64 }
        if d <= 8 {
            let e2: Vec<f64> = (0..N).map(|i| loo(&ts, &ys, d, i).powi(2)).collect();
            (lr, lse) = mean_se(&e2);
            lh = sum((0..N).map(|i| ((ys[i] - pred(&c, ts[i])) / (1.0 - h[i][i])).powi(2))) / N as f64;
        }
        let gaps: Vec<f64> = recs.iter().map(|one| {        // new reading's error minus training error
            let yh: Vec<f64> = (0..N).map(|i| sum((0..N).map(|j| h[i][j] * one[j].0))).collect();
            sum((0..N).map(|i| (one[i].1 - yh[i]).powi(2) - (one[i].0 - yh[i]).powi(2))) / N as f64
        }).collect();
        let (gap, gse) = mean_se(&gaps);
        let p = 2.0 * SIG * SIG * (d + 1) as f64 / N as f64;
        levs.push((0..N).map(|i| h[i][i]).collect());
        let trace = sum(levs[d].iter().copied());
        println!("{:3} {:9.4}{}{}{}{}{:9.4}{:10.4}{:9.4}{:10.4}{:9.4}{:9.4}",
                 d, train, f4(kf), f4(lr), f4(lh), f4(lse), integ, sim, sim_se, gap, p, gse);
        rr.push([train, kf, lr, lh, integ, sim, sim_se, gap, gse, p, trace]);
        fits.push(c);
    }
    let argmin = |col: usize, top: usize| (0..top).fold(0, |b, d| if rr[d][col] < rr[b][col] { d } else { b });
    let (b_train, b_kf, b_lr, b_integ) = (argmin(0, 10), argmin(1, 8), argmin(2, 9), argmin(4, 10));
    println!("lowest training error: degree {}; lowest 5-fold: degree {}; lowest LOO: degree {}; lowest true error: degree {}",
             b_train, b_kf, b_lr, b_integ);
    println!("degree 9 true error / degree 3 true error: {:.2}", rr[9][4] / rr[3][4]);
    println!("degree 3, 5-fold held-out squared errors by fold (hours k, k+5): {}",
             join((0..5).map(|k| format!("{:.4}", fold(&ts, &ys, 3, k)))));
    let (e0, h0) = (ys[0] - pred(&fits[3], 0.0), levs[3][0]);
    println!("degree 3, hour 0: residual {:.4}, leverage {:.4}, residual/(1 - leverage) {:.4}, refit without it {:.4}",
             e0, h0, e0 / (1.0 - h0), loo(&ts, &ys, 3, 0));
    for d in [3, 9] {
        println!("degree {}, leverages: {}; sum {:.4}", d, join(levs[d].iter().map(|h| format!("{:.4}", h))), rr[d][10]);
    }
    let (p9, l9) = (pred(&fits[9], 8.75), lagrange(&ts, &ys, 8.75));
    println!("degree 9 at hour 8.75: normal equations {:.6}, Lagrange {:.6}, truth {:.4}", p9, l9, tide(8.75));
    let (t2, y2): (Vec<f64>, Vec<f64>) = (ts.iter().chain(&ts).copied().collect(), ys.iter().chain(&ys).copied().collect());
    let leak: Vec<f64> = (0..N).map(|d| sum((0..2 * N).map(|i| loo(&t2, &y2, d, i).powi(2))) / (2 * N) as f64).collect();
    println!("leak, LOO with every reading entered twice, degree 0..9: {}", join(leak.iter().map(|v| format!("{:.4}", v))));
    for (name, col) in [("training error", 0), ("true error    ", 4)] {
        println!("chart, {} {}", name, join((0..N).map(|d| format!("{:.2}", rr[d][col]))));
    }
    let xy = |t: f64, v: f64| format!("{:.1},{:.1}", 40.0 + 32.0 * t, 20.0 + 40.0 * (1.4 - v));
    println!("figure, readings {}", join(ts.iter().zip(&ys).map(|(&t, &y)| xy(t, y))));
    let curves: [(&str, Box<dyn Fn(f64) -> f64>); 3] = [("truth", Box::new(tide)),
        ("degree 3", Box::new(|t| pred(&fits[3], t))), ("degree 9", Box::new(|t| pred(&fits[9], t)))];
    for (name, g) in curves.iter() {
        println!("figure, {} {}", name, join((0..37).map(|k| xy(k as f64 / 4.0, g(k as f64 / 4.0)))));
    }
    for d in 0..9 { assert!((rr[d][2] - rr[d][3]).abs() < 1e-7 * rr[d][2].max(1.0), "LOO shortcut vs refit") }
    for d in 0..N {
        assert!((rr[d][4] - rr[d][5]).abs() < 4.0 * rr[d][6], "Simpson vs fresh readings");
        assert!((rr[d][7] - rr[d][9]).abs() < 4.0 * rr[d][8], "simulated optimism vs 2 sigma^2 p / n");
        assert!((rr[d][10] - (d + 1) as f64).abs() < 1e-8, "sum of leverages vs number of coefficients");
    }
    assert!((p9 - l9).abs() < 1e-6, "normal equations vs Lagrange at degree 9");
    assert!(b_lr == b_integ, "leave-one-out picks the degree with the lowest true error");
    println!("ALL CHECKS PASS");
}
