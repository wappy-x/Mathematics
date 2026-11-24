// Dividend futures and swaps -- the check behind the card.  std only, no crates.
// Every number quoted on the card is printed here.  Nothing imported knows the answer:
// the bell-curve area is a series written out, the brute-force prices are Simpson's
// rule written out, and the dividend list that built the quotes is checked, never reused.
const S: f64 = 100.0;
const R: f64 = 0.05;
const SIG: f64 = 0.20;
const K: f64 = 100.0;
const EXP: [f64; 3] = [1.0, 2.0, 3.0]; // option expiries, years
type Divs = [(f64, f64); 3]; // (paid at, dollars)
const DIVS: Divs = [(0.75, 2.00), (1.75, 2.10), (2.75, 2.20)]; // hidden truth

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * std::f64::consts::PI).sqrt() }
fn n(x: f64) -> f64 { // x + x^3/3 + x^5/(3*5) + ..., times the bell-curve height
    if x < -8.0 { return 0.0; }
    if x > 8.0 { return 1.0; }
    let (mut s, mut t, mut k) = (x, x, 1.0);
    while s + t * x * x / (2.0 * k + 1.0) != s { t *= x * x / (2.0 * k + 1.0); s += t; k += 1.0; }
    0.5 + s * phi(x)
}
fn pv_divs(t_exp: f64, d: &Divs) -> f64 { d.iter().filter(|p| p.0 < t_exp).map(|p| p.1 * (-R * p.0).exp()).sum() }
fn d1(t: f64, k: f64, d: &Divs) -> f64 { (((S - pv_divs(t, d)) / k).ln() + (R + 0.5 * SIG * SIG) * t) / (SIG * t.sqrt()) }
fn bs(t: f64, k: f64, d: &Divs, b: f64) -> (f64, f64) { // escrowed spot; fee b a year on the share's value
    let ss = S * (-b * t).exp() - d.iter().filter(|p| p.0 < t).map(|p| p.1 * (-R * p.0 - b * (t - p.0)).exp()).sum::<f64>();
    let a = ((ss / k).ln() + (R + 0.5 * SIG * SIG) * t) / (SIG * t.sqrt());
    let c = a - SIG * t.sqrt();
    (ss * n(a) - k * (-R * t).exp() * n(c), k * (-R * t).exp() * n(-c) - ss * n(-a))
}
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64) -> f64 {
    let m = 2000; let h = (b - a) / m as f64;
    let w = |i: usize| if i == 0 || i == m { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
    h / 3.0 * (0..=m).map(|i| w(i) * f(a + i as f64 * h)).sum::<f64>()
}
fn simpson_pair(t: f64, k: f64, d: &Divs) -> (f64, f64) { // road 2: both legs by brute force
    let (ss, v) = (S - pv_divs(t, d), SIG * t.sqrt());
    let st = |z: f64| ss * ((R - 0.5 * SIG * SIG) * t + v * z).exp();
    let zk = ((k / ss).ln() - (R - 0.5 * SIG * SIG) * t) / v; // where the payoff kinks
    let c = simpson(|z| (st(z) - k) * phi(z), zk, 9.0);
    let p = simpson(|z| (k - st(z)) * phi(z), -9.0, zk);
    ((-R * t).exp() * c, (-R * t).exp() * p)
}
fn strip(q: &[(f64, f64)], k: f64) -> Vec<f64> { // road 1: parity solved for the dividends
    EXP.iter().zip(q).map(|(t, (c, p))| S - k * (-R * t).exp() - (c - p)).collect()
}
fn futures(dc: &[f64], tpay: &[f64]) -> Vec<f64> { // difference, then carry to the pay date
    (0..3).map(|i| (dc[i] - if i == 0 { 0.0 } else { dc[i - 1] }) * (R * tpay[i]).exp()).collect()
}
fn join(v: &[f64], f: fn(&f64) -> String, sep: &str) -> String { v.iter().map(f).collect::<Vec<_>>().join(sep) }
fn f6(x: &f64) -> String { format!("{:.6}", x) }
fn s4(x: &f64) -> String { format!("{:+.4}", x) }

fn main() {
    let quotes: Vec<(f64, f64)> = EXP.iter().map(|&t| bs(t, K, &DIVS, 0.0)).collect();
    let dd = strip(&quotes, K);
    let tpay: Vec<f64> = DIVS.iter().map(|p| p.0).collect();
    let fut = futures(&dd, &tpay);
    for i in 0..3 {
        let (c, p) = quotes[i];
        println!("expiry {:.0}y: call {:.6}  put {:.6}  C-P {:.6}  K e^-rT {:.6}  PV of dividends {:.6}", EXP[i], c, p, c - p, K * (-R * EXP[i]).exp(), dd[i]);
    }
    let pvs = [dd[0], dd[1] - dd[0], dd[2] - dd[1]];
    for i in 0..3 {
        println!("year {}: PV {:.6}  carry e^(r*{}) {:.6}  dividend future {:.6}", i + 1, pvs[i], tpay[i], (R * tpay[i]).exp(), fut[i]);
        assert!((fut[i] - DIVS[i].1).abs() < 1e-5); // recovers the hidden dividend list
    }
    println!("3-year dividend swap fair strike {:.6}", fut.iter().sum::<f64>());

    // road 2: brute-force prices at a different strike, same parity inversion
    let q90: Vec<(f64, f64)> = EXP.iter().map(|&t| simpson_pair(t, 90.0, &DIVS)).collect();
    let d2 = strip(&q90, 90.0);
    println!("road 2, Simpson prices at strike 90: {}", join(&d2, f6, "  "));
    assert!((0..3).all(|i| (dd[i] - d2[i]).abs() < 1e-5));
    // road 3: forwards from parity, dividends from forward differences
    let f: Vec<f64> = (0..3).map(|i| K + (quotes[i].0 - quotes[i].1) * (R * EXP[i]).exp()).collect();
    let fut3: Vec<f64> = (0..3).map(|i| {
        let pf = if i == 0 { S } else { f[i - 1] };
        (pf * R.exp() - f[i]) * (-R * (EXP[i] - tpay[i])).exp()
    }).collect();
    println!("road 3, forwards {}  futures {}", join(&f, f6, "  "), join(&fut3, f6, "  "));
    assert!((0..3).all(|i| (fut[i] - fut3[i]).abs() < 1e-9));
    assert!((fut3.iter().sum::<f64>() - DIVS.iter().map(|p| p.1).sum::<f64>()).abs() < 1e-5); // swap strike = listed total

    // dividend delta: dollars of option per $1 more on dividend i
    println!("dividend delta of the calls (rows: expiry; columns: year-1, year-2, year-3 dividend)");
    for &t in EXP.iter() {
        let row: Vec<f64> = tpay.iter().map(|&tp| if tp < t { -n(d1(t, K, &DIVS)) * (-R * tp).exp() } else { 0.0 }).collect();
        let bump: Vec<f64> = (0..3).map(|i| {
            let (mut up, mut dn) = (DIVS, DIVS);
            up[i].1 += 0.01; dn[i].1 -= 0.01;
            (simpson_pair(t, K, &up).0 - simpson_pair(t, K, &dn).0) / 0.02
        }).collect();
        assert!((0..3).all(|i| (row[i] - bump[i]).abs() < 1e-4));
        println!("  {:.0}y call  formula {}  bump {}  total {:+.4}", t, join(&row, s4, " "), join(&bump, s4, " "), row.iter().sum::<f64>());
    }
    let nd = n(d1(3.0, K, &DIVS));
    let row3: Vec<f64> = tpay.iter().map(|&tp| -nd * (-R * tp).exp()).collect();
    let mut cut = DIVS;
    for p in cut.iter_mut() { p.1 *= 0.9; }
    let gain = bs(3.0, K, &cut, 0.0).0 - quotes[2].0;
    let pred: f64 = (0..3).map(|i| -row3[i] * 0.1 * DIVS[i].1).sum();
    println!("3y call N(d1) {:.6}; all dividends cut 10%: call gains {:.6}, delta predicts {:.6}", nd, gain, pred);
    let putd: Vec<f64> = tpay.iter().map(|&tp| n(-d1(3.0, K, &DIVS)) * (-R * tp).exp()).collect();
    println!("3y put dividend delta {}", join(&putd, s4, " "));

    // what breaks
    println!("break: future left at PV, year 2 {:.6}", dd[1] - dd[0]);
    println!("break: carried to year end, year 2 {:.6}", (dd[1] - dd[0]) * (R * 2.0).exp());
    println!("break: swap strike as sum of PVs {:.6}; carried to year 3 {:.6}", dd[2], dd[2] * (3.0 * R).exp());
    let qb: Vec<(f64, f64)> = EXP.iter().map(|&t| bs(t, K, &DIVS, 0.01)).collect();
    let fb = futures(&strip(&qb, K), &tpay);
    println!("break: 1% borrow fee read as dividends, futures {}", join(&fb, f6, "  "));
    assert!(fb[1] - fut[1] > 0.9); // the fee shows up as about $1 a year
    println!("house: forward with borrow {:.4}, without {:.4}", S * 0.02f64.exp(), S * 0.03f64.exp());

    // try changing
    let q120: Vec<(f64, f64)> = EXP.iter().map(|&t| bs(t, 120.0, &DIVS, 0.0)).collect();
    println!("try: strike 120 strip {}", join(&strip(&q120, 120.0), f6, "  "));
    let hi: Divs = [(0.75, 2.00), (1.75, 2.10), (2.75, 2.50)];
    println!("try: year-3 dividend 2.50: 3y call {:.6} from {:.6}", bs(3.0, K, &hi, 0.0).0, quotes[2].0);
    let d80: Vec<f64> = tpay.iter().map(|&tp| -n(d1(3.0, 80.0, &DIVS)) * (-R * tp).exp()).collect();
    let full: Vec<f64> = tpay.iter().map(|&tp| -(-R * tp).exp()).collect();
    println!("try: strike 80: 3y call delta {}  full short {}", join(&d80, s4, " "), join(&full, s4, " "));
    println!("ALL CHECKS PASS");
}
