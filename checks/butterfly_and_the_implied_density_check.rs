// The butterfly and the implied density -- the check behind the card.  Rust std only.
// Same rows, same labels as the Python check.  The normal CDF is Marsaglia's series,
// the random numbers are xorshift64*, the density comes from second differences of prices.
use std::f64::consts::PI;

const S: f64 = 100.0;
const R: f64 = 0.05;
const Q: f64 = 0.02;
const SIG: f64 = 0.20;
const T: f64 = 1.0;

fn n_cdf(x: f64) -> f64 {
    // bell-curve area left of x, summed as a series
    if x < -10.0 { return 0.0; }
    if x > 10.0 { return 1.0; }
    let (mut s, mut t, mut b, q, mut i) = (x, 0.0, x, x * x, 1.0);
    while s != t { i += 2.0; b *= q / i; t = s; s = t + b; }
    0.5 + s * (-0.5 * q - 0.91893853320467274178).exp()
}
fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn disc() -> f64 { (-R * T).exp() }
fn call_at(k: f64, v: f64, s0: f64) -> f64 {
    let d1 = ((s0 / k).ln() + (R - Q + 0.5 * v * v) * T) / (v * T.sqrt());
    s0 * (-Q * T).exp() * n_cdf(d1) - k * disc() * n_cdf(d1 - v * T.sqrt())
}
fn call(k: f64) -> f64 { call_at(k, SIG, S) }
fn d2(k: f64) -> f64 { ((S / k).ln() + (R - Q - 0.5 * SIG * SIG) * T) / (SIG * T.sqrt()) }
fn dens(k: f64) -> f64 { phi(d2(k)) / (k * SIG * T.sqrt()) }
fn fly(k: f64, h: f64, c: &dyn Fn(f64) -> f64) -> f64 { c(k - h) - 2.0 * c(k) + c(k + h) }
fn smile(k: f64, f: f64) -> f64 {
    let x = (k / f).ln();
    SIG - 0.05 * x + 0.30 * x * x / (1.0 + 4.0 * x * x)
}

fn main() {
    let d = disc();
    let fwd = S * ((R - Q) * T).exp();
    let k = 100.0;
    let ckk = d * dens(k); // road 1
    let gam = (-Q * T).exp() * phi(d2(k) + SIG * T.sqrt()) / (S * SIG * T.sqrt()); // road 3
    let gam_bump = (call_at(k, SIG, S + 0.01) - 2.0 * call(k) + call_at(k, SIG, S - 0.01)) / 1e-4;
    let mut rows: Vec<(String, f64)> = vec![
        ("house call C(100)".into(), call(k)), ("call at K = 99".into(), call(99.0)),
        ("call at K = 101".into(), call(101.0)), ("discount e^-rT".into(), d),
        ("K sig rt T".into(), k * SIG * T.sqrt()), ("d2 at K = 100".into(), d2(k)),
        ("phi(d2)".into(), phi(d2(k))), ("1 closed form e^-rT phi(d2)/(K sig rt T)".into(), ckk),
        ("  density f(100) = e^rT x that".into(), dens(k)), ("3 spot gamma formula at S = K".into(), gam),
        ("  spot gamma by bumping S".into(), gam_bump),
    ];
    let mut errs = Vec::new();
    for h in [8.0, 4.0, 2.0, 1.0, 0.5] {
        // road 2: butterflies of shrinking width
        let b = fly(k, h, &call) / (h * h);
        errs.push(b - ckk);
        rows.push((format!("2 butterfly/h^2, h = {}", h), b));
    }
    rows.push(("  error ratio h = 2 over h = 1".into(), errs[2] / errs[3]));
    rows.push(("  error ratio h = 1 over h = 0.5".into(), errs[3] / errs[4]));
    let dig = -(call(k + 0.01) - call(k - 0.01)) / 0.02;
    rows.push(("minus dC/dK: cash digital".into(), dig));
    rows.push(("  e^-rT N(d2)".into(), d * n_cdf(d2(k))));

    // road 4: simulate S_T, count the $1 bin at 100
    let mut st: u64 = 88172645463325252;
    let mut unif = || {
        st ^= st >> 12;
        st ^= st << 25;
        st ^= st >> 27;
        (st.wrapping_mul(0x2545F4914F6CDD1D) >> 11) as f64 * 2f64.powi(-53) + 2f64.powi(-54)
    };
    let (n, drift, vol) = (1_000_000u64, S.ln() + (R - Q - 0.5 * SIG * SIG) * T, SIG * T.sqrt());
    let mut hits = 0u64;
    for _ in 0..n / 2 {
        let rad = (-2.0 * unif().ln()).sqrt();
        let ang = 2.0 * PI * unif();
        for z in [rad * ang.cos(), rad * (ang - 0.5 * PI).cos()] {
            let s_t = (drift + vol * z).exp();
            if (99.5..100.5).contains(&s_t) { hits += 1; }
        }
    }
    let p = hits as f64 / n as f64;
    let mc = d * p;
    let se = d * (p * (1.0 - p) / n as f64).sqrt();
    rows.push(("4 simulated share in [99.5, 100.5) x e^-rT".into(), mc));
    rows.push(("  its standard error".into(), se));

    let bf = fly(k, 10.0, &call);
    let b10 = bf / 100.0;
    let bad = fly(k, 1.0, &|x: f64| call(x) + if x == 100.0 { 0.03 } else { 0.0 });
    rows.push(("butterfly 90/100/110 price".into(), bf));
    rows.push(("  largest payoff, at 100".into(), 10.0));
    rows.push(("wrong: no e^rT, density read as".into(), ckk));
    rows.push(("wrong: h = 10 used as it stands".into(), b10 / d));
    rows.push(("wrong: divided by h, not h^2".into(), bf / 10.0 / d));
    rows.push(("wrong: spot gamma read at K = 120".into(),
        (-Q * T).exp() * phi(d2(120.0) + SIG * T.sqrt()) / (S * SIG * T.sqrt())));
    rows.push(("  right: e^-rT f(120)".into(), d * dens(120.0)));
    rows.push(("wrong: C(100) marked 3 cents high".into(), bad / d));
    let fb = |s0: f64, v: f64| call_at(90.0, v, s0) - 2.0 * call_at(100.0, v, s0) + call_at(110.0, v, s0);
    rows.push(("fly delta, bump S by 1 cent".into(), (fb(S + 0.01, SIG) - fb(S - 0.01, SIG)) / 0.02));
    rows.push(("fly gamma, bump S by 1 cent".into(), (fb(S + 0.01, SIG) - 2.0 * fb(S, SIG) + fb(S - 0.01, SIG)) / 1e-4));
    rows.push(("fly vega, per vol point".into(), (fb(S, SIG + 1e-4) - fb(S, SIG - 1e-4)) / 2e-4 / 100.0));

    // whole density from a strike grid, flat and smiling
    let hh = 0.5;
    let ks: Vec<f64> = (1..=1200).map(|i| hh * i as f64).collect();
    let grid = |vol: &dyn Fn(f64) -> f64| -> Vec<(f64, f64)> {
        let c: Vec<f64> = ks.iter().map(|&x| call_at(x, vol(x), S)).collect();
        (1..ks.len() - 1).map(|i| (ks[i], (c[i - 1] - 2.0 * c[i] + c[i + 1]) / (hh * hh) / d)).collect()
    };
    let gf = grid(&|_x| SIG);
    let gs = grid(&|x| smile(x, fwd));
    for (name, g) in [("flat", &gf), ("smile", &gs)] {
        let mass: f64 = g.iter().map(|&(_, f)| f).sum::<f64>() * hh;
        let mean: f64 = g.iter().map(|&(x, f)| x * f).sum::<f64>() * hh;
        let negs = g.iter().filter(|&&(_, f)| f < -1e-9).count() as f64;
        let lo: f64 = g.iter().filter(|&&(x, _)| x < 70.0).map(|&(_, f)| f).sum::<f64>() * hh;
        let hi: f64 = g.iter().filter(|&&(x, _)| x > 150.0).map(|&(_, f)| f).sum::<f64>() * hh;
        rows.push((format!("{}: total probability", name), mass));
        rows.push((format!("{}: mean, compare forward", name), mean));
        rows.push((format!("{}: grid strikes with density < 0", name), negs));
        rows.push((format!("{}: P(S_T < 70)", name), lo));
        rows.push((format!("{}: P(S_T > 150)", name), hi));
    }
    rows.push(("forward F = S e^(r-q)T".into(), fwd));
    for x in [60.0, 100.0, 160.0] {
        rows.push((format!("smile vol at K = {}", x), smile(x, fwd)));
    }
    let worst = gf.iter().map(|&(x, f)| (f - dens(x)).abs()).fold(0.0, f64::max);
    rows.push(("flat grid vs lognormal, worst gap".into(), worst));
    for (name, v) in &rows {
        println!("{:<44} {:>12.6}", name, v);
    }
    let xs: Vec<f64> = (0..12).map(|i| 50.0 + 10.0 * i as f64).collect();
    let at = |g: &Vec<(f64, f64)>, x: f64| g[(x / hh) as usize - 2].1; // grid starts at K = 1.0
    let mut line = String::from("chart, strike           ");
    for &x in &xs { line += &format!("{:>6.0}", x); }
    println!("{}", line);
    for (name, g) in [("chart, flat % per $    ", &gf), ("chart, smile % per $   ", &gs)] {
        let mut line = String::from(name);
        for &x in &xs { line += &format!("{:>6.2}", 100.0 * at(g, x)); }
        println!("{}", line);
    }
    let pay: Vec<f64> = (0..9).map(|i| (10.0 - (80.0 + 5.0 * i as f64 - 100.0f64).abs()).max(0.0)).collect();
    let mut l1 = String::from("chart, butterfly payoff ");
    let mut l2 = String::from("chart, payoff less price");
    for &p in &pay {
        l1 += &format!("{:>6.2}", p);
        l2 += &format!("{:>6.2}", p - bf);
    }
    println!("{}\n{}", l1, l2);

    assert!((fly(k, 1.0, &call) - ckk).abs() < 1e-5, "a $1 butterfly lands on the closed-form curvature");
    assert!(errs[3] / errs[4] > 3.9 && errs[3] / errs[4] < 4.1, "halving h cuts the error by four");
    assert!((gam - ckk).abs() < 1e-12, "spot gamma formula equals strike curvature at S = K");
    assert!((gam_bump - ckk).abs() < 1e-6, "bumped spot gamma lands on it too");
    assert!((mc - ckk).abs() < 4.0 * se, "simulated bin count agrees with the formula");
    assert!((dig - 0.494581).abs() < 1e-6, "first difference is the shelf's cash digital");
    assert!(worst < 1e-5, "density read off flat prices matches the lognormal formula at every strike");
    assert!(gs.iter().all(|&(_, f)| f > -1e-9), "the smile's density stays non-negative: no butterfly arbitrage");
    let tail = |g: &Vec<(f64, f64)>| g.iter().filter(|&&(x, _)| x < 70.0 || x > 150.0).map(|&(_, f)| f).sum::<f64>() * hh;
    assert!(tail(&gs) > 1.3 * tail(&gf), "the smile fattens the tails");
    assert!(bad < 0.0, "three cents on one quote turns the density negative");
    for g in [&gf, &gs] {
        assert!((g.iter().map(|&(_, f)| f).sum::<f64>() * hh - 1.0).abs() < 1e-9, "total probability is 1");
        assert!((g.iter().map(|&(x, f)| x * f).sum::<f64>() * hh - fwd).abs() < 1e-6, "the mean is the forward");
    }
    println!("ALL CHECKS PASS");
}
