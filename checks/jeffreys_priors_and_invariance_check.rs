// Jeffreys priors -- the same check as the Python, in Rust.  No crates.
// Fisher information is found by brute force (finite-difference score, squared,
// averaged over outcomes), in three ways of writing the coin's chance.  Each
// posterior is found twice: by the conjugate formula, and by a grid integral on
// the scale where the information is constant.  The coin also gets a simulation.
use std::f64::consts::PI;

fn midpoint_m(f: &dyn Fn(f64) -> f64, a: f64, b: f64, m: usize) -> f64 {
    let h = (b - a) / m as f64;
    h * (0..m).map(|i| f(a + (i as f64 + 0.5) * h)).sum::<f64>()
}
fn midpoint(f: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 { midpoint_m(f, a, b, 20000) }

fn info(ll: &dyn Fn(f64, f64) -> f64, t: f64, outcomes: &[(f64, f64)]) -> f64 {
    let d = 1e-5;
    outcomes.iter().map(|&(x, p)| p * ((ll(t + d, x) - ll(t - d, x)) / (2.0 * d)).powi(2)).sum()
}
fn flip_ll(th: f64, x: f64) -> f64 { x * th.ln() + (1.0 - x) * (1.0 - th).ln() }
fn coin_info(th: f64, to_theta: &dyn Fn(f64) -> f64, at: f64) -> f64 {
    info(&|a, x| flip_ll(to_theta(a), x), at, &[(1.0, th), (0.0, 1.0 - th)])
}
fn lo(a: f64) -> f64 { 1.0 / (1.0 + (-a).exp()) }

fn lgamma(x: f64) -> f64 {                       // Lanczos, g = 7, nine terms
    const C: [f64; 9] = [0.99999999999980993, 676.5203681218851, -1259.1392167224028,
        771.32342877765313, -176.61502916214059, 12.507343278686905,
        -0.13857109526572012, 9.9843695780195716e-6, 1.5056327351493116e-7];
    if x < 0.5 { return (PI / (PI * x).sin()).ln() - lgamma(1.0 - x) }
    let x = x - 1.0;
    let mut a = C[0];
    let t = x + 7.5;
    for i in 1..9 { a += C[i] / (x + i as f64) }
    0.5 * (2.0 * PI).ln() + (x + 0.5) * t.ln() - t + a.ln()
}

fn main() {
    println!("Fisher information per flip, by brute force, and Jeffreys mapped back to theta");
    for &th in &[0.1f64, 0.3, 0.5, 0.7, 0.9] {
        let i_th = coin_info(th, &|a| a, th);
        let j_psi = coin_info(th, &|a: f64| a.sqrt(), th * th).sqrt() * 2.0 * th;
        let j_phi = coin_info(th, &lo, (th / (1.0 - th)).ln()).sqrt() / (th * (1.0 - th));
        let exact = 1.0 / (th * (1.0 - th)).sqrt();
        println!("theta {:.1}: I {:.4} (formula {:.4}); sqrt I {:.4}; via theta^2 {:.4}; via log-odds {:.4}; flat-in-theta^2 gives {:.4}",
                 th, i_th, 1.0 / (th * (1.0 - th)), exact, j_psi, j_phi, 2.0 * th);
        assert!((i_th * th * (1.0 - th) - 1.0).abs() < 1e-6 && (j_psi / exact - 1.0).abs() < 1e-6 && (j_phi / exact - 1.0).abs() < 1e-6);
    }
    let xs: Vec<f64> = (0..10).map(|i| 0.05 + 0.1 * i as f64).collect();
    let jf: Vec<String> = xs.iter().map(|x| format!("{:.2}", 1.0 / (PI * (x * (1.0 - x)).sqrt()))).collect();
    let fq: Vec<String> = xs.iter().map(|x| format!("{:.2}", 2.0 * x)).collect();
    println!("figure, Jeffreys prior density: {}", jf.join(", "));
    println!("figure, flat-in-theta^2 prior density: {}", fq.join(", "));

    // The coin on the even-information scale u, theta = sin^2 u: there Jeffreys is flat.
    let (n, s) = (10.0f64, 7.0f64);
    let lik = |th: f64| th.powf(s) * (1.0 - th).powf(n - s);
    let coin_post = |w: &dyn Fn(f64) -> f64, g: &dyn Fn(f64) -> f64| -> f64 {
        let top = midpoint(&|u: f64| g(u.sin().powi(2)) * w(u) * lik(u.sin().powi(2)), 0.0, PI / 2.0);
        top / midpoint(&|u: f64| w(u) * lik(u.sin().powi(2)), 0.0, PI / 2.0)
    };
    let above = |t: f64| if t > 0.5 { 1.0 } else { 0.0 };
    let priors: Vec<(&str, f64, f64, Box<dyn Fn(f64) -> f64>)> = vec![
        ("Jeffreys Beta(1/2,1/2)", 0.5, 0.5, Box::new(|_u| 1.0)),
        ("flat in theta Beta(1,1)", 1.0, 1.0, Box::new(|u: f64| (2.0 * u).sin())),
        ("flat in theta^2 Beta(2,1)", 2.0, 1.0, Box::new(|u: f64| 2.0 * u.sin().powi(2) * (2.0 * u).sin())),
        ("I not its root Beta(0,0)", 0.0, 0.0, Box::new(|u: f64| 4.0 / (2.0 * u).sin()))];
    println!("coin, {} heads in {}: prior, posterior, mean by formula and by grid, P(theta > 0.5)", s, n);
    let mut jeff_mean = 0.0;
    for (name, a, b, w) in &priors {
        let form = (a + s) / (a + b + n);
        let grid = coin_post(w.as_ref(), &|t| t);
        if *a == 0.5 { jeff_mean = form }
        println!("  {}: Beta({},{}) mean {:.4} grid {:.4} P {:.4}", name, a + s, b + n - s, form, grid, coin_post(w.as_ref(), &above));
        assert!((form - grid).abs() < 1e-6);
    }
    let (aa, bb) = (7.5f64, 3.5f64);
    let sd = (aa * bb / ((aa + bb).powi(2) * (aa + bb + 1.0))).sqrt();
    println!("Jeffreys posterior sd {:.4}; flat prior posterior sd {:.4}", sd, (32.0f64 / (144.0 * 13.0)).sqrt());
    // Invariance: Jeffreys built directly on the log-odds scale, information by brute force.
    let wphi = |f: f64| coin_info(lo(f), &lo, f).sqrt();
    let top = midpoint_m(&|f: f64| (if f > 0.0 { 1.0 } else { 0.0 }) * wphi(f) * lik(lo(f)), -30.0, 30.0, 6000);
    let p_phi = top / midpoint_m(&|f: f64| wphi(f) * lik(lo(f)), -30.0, 30.0, 6000);
    let p_th = coin_post(&|_u| 1.0, &above);
    println!("P(theta > 0.5) under Jeffreys built on theta {:.4}, built on log-odds {:.4}", p_th, p_phi);
    assert!((p_phi - p_th).abs() < 1e-4);
    println!("prior P(theta < 0.5): flat in theta {:.4}, flat in theta^2 {:.4}, Jeffreys {:.4}",
             0.5, 0.25, midpoint(&|_u| 1.0, 0.0, PI / 4.0) / (PI / 2.0));
    println!("Jeffreys prior P(theta < 0.1 or > 0.9) {:.4}; flat 0.2000",
             2.0 * midpoint(&|_u| 1.0, 0.0, 0.1f64.sqrt().asin()) / (PI / 2.0));
    // Wrong likelihood: flip until the 7th head (negative binomial) gives Beta(7, 3.5).
    let inb: Vec<f64> = [0.1f64, 0.5, 0.9].iter().map(|&th| info(&|t, f| 7.0 * t.ln() + f * (1.0 - t).ln(), th, // its information, by brute force over f tails
        &(0..3000).map(|f| { let f = f as f64; (f, (lgamma(f + 7.0) - lgamma(7.0) - lgamma(f + 1.0) + 7.0 * th.ln() + f * (1.0 - th).ln()).exp()) }).collect::<Vec<_>>())).collect();
    let fnb: Vec<f64> = [0.1f64, 0.5, 0.9].iter().map(|&th| 7.0 / (th * th * (1.0 - th))).collect();
    println!("flip-until-7th-head information by brute force at theta 0.1, 0.5, 0.9: {:.4}, {:.4}, {:.4}; formula 7/(theta^2(1-theta)) {:.4}, {:.4}, {:.4}", inb[0], inb[1], inb[2], fnb[0], fnb[1], fnb[2]);
    assert!(inb.iter().zip(&fnb).all(|(i, f)| (i / f - 1.0).abs() < 1e-6));
    println!("Jeffreys for flip-until-7th-head: Beta(7,3.5) mean {:.4}; grid {:.4}", 7.0 / 10.5,
             coin_post(&|u: f64| 1.0 / u.sin().powi(2) / (1.0 - u.sin().powi(2)).powf(0.5) * (2.0 * u).sin(), &|t| t));
    // Simulation: theta from Jeffreys by theta = sin^2(pi U / 2), ten flips, keep 7 heads.
    let mut state: u64 = 20261123;
    let mut rnd = || {
        state = state.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = state;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    };
    let (mut kept, mut total) = (0u64, 0.0f64);
    for _ in 0..200000 {
        let th = (PI * rnd() / 2.0).sin().powi(2);
        let heads = (0..10).filter(|_| rnd() < th).count();
        if heads == 7 { kept += 1; total += th }
    }
    println!("simulation: 200000 coins, {} showed 7 heads, mean chance {:.4}", kept, total / kept as f64);
    assert!((total / kept as f64 - jeff_mean).abs() < 4.0 * sd / (kept as f64).sqrt());

    // Poisson rate: 45 emails in 3 hours.  Even-information scale v = sqrt(lambda).
    let (k, h) = (45.0f64, 3.0f64);
    let outc: Vec<(f64, f64)> = (0..200).map(|j| { let j = j as f64; (j, (j * 15f64.ln() - 15.0 - lgamma(j + 1.0)).exp()) }).collect();
    println!("Poisson rate: I(15) by brute force {:.4}, formula {:.4}",
             info(&|l, j| j * l.ln() - l - lgamma(j + 1.0), 15.0, &outc), 1.0 / 15.0);
    let rate_post = |w: &dyn Fn(f64) -> f64, k: f64, g: &dyn Fn(f64) -> f64| -> f64 {
        let off = if k > 0.0 { k * (k / h).ln() - k } else { 0.0 };
        let f = |v: f64| w(v) * (k * (v * v).ln() - h * v * v - off).exp();
        midpoint(&|v| g(v * v) * f(v), 1e-9, 12.0) / midpoint(&f, 1e-9, 12.0)
    };
    let rates: Vec<(&str, f64, Box<dyn Fn(f64) -> f64>)> = vec![
        ("Jeffreys lambda^(-1/2)", 0.5, Box::new(|_v| 1.0)), ("flat in lambda", 1.0, Box::new(|v: f64| 2.0 * v)),
        ("flat in log lambda", 0.0, Box::new(|v: f64| 2.0 / v))];
    for (name, a, w) in &rates {
        let g = rate_post(w.as_ref(), k, &|l| l);
        println!("  {}: Gamma({},{}) mean {:.4} grid {:.4}", name, k + a, h, (k + a) / h, g);
        assert!((g - (k + a) / h).abs() < 1e-6);
    }
    println!("Jeffreys sd {:.4}; zero emails in 3 hours: Jeffreys mean {:.4} grid {:.4}",
             (k + 0.5).sqrt() / h, 0.5 / h, rate_post(&|_v| 1.0, 0.0, &|l| l));
    for (eps, label) in [(1e-2f64, "0.01"), (1e-4, "0.0001"), (1e-6, "1e-06")] {
        println!("  flat in log lambda, zero emails, area above sqrt(lambda) = {}: {:.4}", label,
                 midpoint(&|t: f64| 2.0 * (-h * (2.0 * t).exp()).exp(), eps.ln(), 12f64.ln()));
    }

    // Normal spread, mean known 0: fill errors 1, -3, 2, -1, 1 ml.  Scale t = log sigma.
    let xd = [1.0f64, -3.0, 2.0, -1.0, 1.0];
    let (nb, q) = (xd.len() as f64, xd.iter().map(|x| x * x).sum::<f64>());
    let nll = |s: f64, x: f64| -s.ln() - x * x / (2.0 * s * s);
    let i2 = midpoint(&|x: f64| (-x * x / 8.0).exp() / (8.0 * PI).sqrt() * ((nll(2.0 + 1e-5, x) - nll(2.0 - 1e-5, x)) / 2e-5).powi(2), -40.0, 40.0);
    println!("normal spread, n {}, sum of squares {}: I(2) by brute force {:.4}, formula 2/sigma^2 {:.4}", nb, q, i2, 2.0 / 4.0);
    let spread_post = |w: &dyn Fn(f64) -> f64, g: &dyn Fn(f64) -> f64| -> f64 {
        let f = |t: f64| w(t) * (-nb * t - q / (2.0 * (2.0 * t).exp()) + nb * (q / nb).sqrt().ln() + nb / 2.0).exp();
        midpoint(&|t: f64| g(t.exp()) * f(t), -6.0, 20.0) / midpoint(&f, -6.0, 20.0)
    };
    println!("plain estimate sqrt(Q/n) {:.4} ml", (q / nb).sqrt());
    let spreads: Vec<(&str, f64, Box<dyn Fn(f64) -> f64>)> = vec![
        ("Jeffreys 1/sigma", nb / 2.0, Box::new(|_t| 1.0)), ("flat in sigma", (nb - 1.0) / 2.0, Box::new(|t: f64| t.exp())),
        ("flat in sigma^2", (nb - 2.0) / 2.0, Box::new(|t: f64| (2.0 * t).exp()))];
    for (name, a, w) in &spreads {
        let es = (q / 2.0).sqrt() * (lgamma(a - 0.5) - lgamma(*a)).exp();
        let (gs, gv) = (spread_post(w.as_ref(), &|s| s), spread_post(w.as_ref(), &|s| s * s));
        println!("  {}: 1/sigma^2 ~ Gamma({},{}); E sigma {:.4} grid {:.4}; E sigma^2 {:.4} grid {:.4}",
                 name, a, q / 2.0, es, gs, q / 2.0 / (a - 1.0), gv);
        assert!((es - gs).abs() < 1e-5 && (q / 2.0 / (a - 1.0) - gv).abs() < 1e-4);
    }
    assert!((i2 - 0.5).abs() < 1e-6);
    let iu: Vec<f64> = [0.1f64, 0.5, 0.9].iter().map(|&th| coin_info(th, &|a: f64| a.sin().powi(2), th.sqrt().asin())).collect();
    let iv = info(&|v, j| j * (v * v).ln() - v * v - lgamma(j + 1.0), 15f64.sqrt(), &outc);
    let it = midpoint(&|x: f64| (-x * x / 8.0).exp() / (8.0 * PI).sqrt() * ((nll((2f64.ln() + 1e-5).exp(), x) - nll((2f64.ln() - 1e-5).exp(), x)) / 2e-5).powi(2), -40.0, 40.0);
    println!("information on the even scales: u = asin(sqrt(theta)) at theta 0.1, 0.5, 0.9: {:.4}, {:.4}, {:.4}; v = sqrt(lambda) at 15: {:.4}; log sigma at 2: {:.4}",
             iu[0], iu[1], iu[2], iv, it);
    println!("try: 10 heads in 10, Jeffreys mean {:.4}, flat {:.4}; 70 in 100, Jeffreys {:.4}, flat {:.4}", 10.5 / 11.0, 11.0 / 12.0, 70.5 / 101.0, 71.0 / 102.0);
    assert!(iu.iter().all(|x| (x - 4.0).abs() < 1e-5) && (iv - 4.0).abs() < 1e-5 && (it - 2.0).abs() < 1e-5);
    println!("ALL CHECKS PASS");
}
