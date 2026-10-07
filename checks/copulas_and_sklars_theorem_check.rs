// Copulas and Sklar's theorem: the check behind the card. Rust std only.
// Two markets' daily returns: A is normal with spread 1.0 percent, B normal with 1.5.
// Ranks agree with Kendall's tau = 0.5, joined by a Gaussian copula (rho = sin(pi/4)) or a
// Clayton copula (theta = 2). Roads: exact formulas, two unrelated integrals, seeded simulations.
use std::f64::consts::PI;

struct Rng(u64);
impl Rng {
    fn u(&mut self) -> f64 { // SplitMix64 -> uniform in (0, 1)
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53) + 2f64.powi(-54)
    }
    fn normal(&mut self) -> f64 { // Box-Muller, one of the pair
        let r = (-2.0 * self.u().ln()).sqrt();
        r * (2.0 * PI * self.u()).cos()
    }
}

fn phi(z: f64) -> f64 { (-z * z / 2.0).exp() / (2.0 * PI).sqrt() }
fn big_phi(z: f64) -> f64 { // series near 0, continued fraction in the tails
    if z < -3.0 {
        let (x, mut f) = (-z, -z);
        for k in (1..=200).rev() { f = x + k as f64 / f; }
        return phi(x) / f;
    }
    if z > 3.0 { return 1.0 - big_phi(-z); }
    let (mut a, mut total) = (z, z);
    for n in 1..100 {
        a *= -z * z / (2 * n) as f64;
        total += a / (2 * n + 1) as f64;
    }
    0.5 + total / (2.0 * PI).sqrt()
}
fn phi_inv(p: f64) -> f64 { // Newton's method on Phi
    let mut z = 0.0;
    for _ in 0..100 {
        let step = (big_phi(z) - p) / phi(z);
        z -= step;
        if step.abs() < 1e-14 { break; }
    }
    z
}
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = 0.0;
    for k in 1..n { s += (if k % 2 == 1 { 4.0 } else { 2.0 }) * f(a + k as f64 * h); }
    h / 3.0 * (f(a) + f(b) + s)
}

const TAU: f64 = 0.5;
const SA: f64 = 1.0; const SB: f64 = 1.5; // daily spreads of markets A and B, percent
fn clayton(u: f64, v: f64, th: f64) -> f64 { (u.powf(-th) + v.powf(-th) - 1.0).powf(-1.0 / th) }
fn gauss(a: f64, b: f64, rho: f64) -> f64 { // road 1: condition on market A's score
    let s = (1.0 - rho * rho).sqrt();
    simpson(|x| phi(x) * big_phi((b - rho * x) / s), -12.0, a, 4000)
}
fn gauss_angle(a: f64, rho: f64) -> f64 { // road 2: polar angle, Rayleigh radius
    let al = rho.acos();
    let g = |t: f64| {
        let m = (-t.cos()).min(-(t - al).cos());
        if m > 0.0 { (-a * a / (2.0 * m * m)).exp() } else { 0.0 }
    };
    simpson(g, PI / 2.0 + al, 1.5 * PI, 20000) / (2.0 * PI)
}

fn main() {
    let rho = (PI * TAU / 2.0).sin(); // Gaussian parameter with this tau
    let th = 2.0 * TAU / (1.0 - TAU); // Clayton parameter with this tau
    let c = |u: f64, v: f64| clayton(u, v, th);
    assert!((c(0.3, 1.0) - 0.3).abs() < 1e-12); // a copula's margin is uniform: C(u, 1) = u
    println!("tau {:.3}  gaussian rho {:.6}  clayton theta {:.3}", TAU, rho, th);
    let a01 = phi_inv(0.01);
    assert!((a01 - -2.3263478740408408).abs() < 1e-12); // published 1st percentile of the bell
    println!("worst 1-in-100 day: A below {:.3}%, B below {:.3}%", SA * a01, SB * a01);
    let (g1, g2, c01) = (gauss(a01, a01, rho), gauss_angle(a01, rho), c(0.01, 0.01));
    assert!((g1 - g2).abs() < 1e-9 * g1); // two unrelated integrals agree
    let d = 2.0 * 0.01f64.powf(-2.0) - 1.0; // the Clayton value by hand
    println!("by hand: 0.01^-2 = {:.0}, doubled minus 1 = {:.0}, root {:.3}, C = {:.6}", 0.01f64.powf(-2.0), d, d.sqrt(), 1.0 / d.sqrt());
    println!("both crash, p=0.01: independent {:.6}  gaussian {:.6} (angle road {:.6})  clayton {:.6}", 0.01 * 0.01, g1, g2, c01);

    let nsim = 400000; // three seeded simulations
    let mut rng = Rng(20260928);
    let s = (1.0 - rho * rho).sqrt();
    let (mut kg, mut kc, mut kd, mut kc2, mut kd2) = (0u64, 0u64, 0u64, 0u64, 0u64); // kc2, kd2: both ranks below 0.5
    for _ in 0..nsim {
        let (z1, z2) = (rng.normal(), rng.normal()); // Gaussian copula: correlated scores
        if z1 <= a01 && rho * z1 + s * z2 <= a01 { kg += 1; }
        let z = rng.normal(); let w = z * z / 2.0; // Clayton by a shared calm level W ~ Gamma(1/2)
        let (e1, e2) = (-rng.u().ln(), -rng.u().ln());
        let (uc, vc) = ((1.0 + e1 / w).powf(-1.0 / th), (1.0 + e2 / w).powf(-1.0 / th));
        kc += (uc <= 0.01 && vc <= 0.01) as u64; kc2 += (uc <= 0.5 && vc <= 0.5) as u64;
        let (u, t) = (rng.u(), rng.u()); // Clayton by conditional inversion
        let v = (u.powf(-th) * (t.powf(-th / (1.0 + th)) - 1.0) + 1.0).powf(-1.0 / th);
        kd += (u <= 0.01 && v <= 0.01) as u64; kd2 += (u <= 0.5 && v <= 0.5) as u64;
    }
    for (lab, k, exact) in [("gaussian", kg, g1), ("clayton, shared calm", kc, c01), ("clayton, inversion", kd, c01),
                            ("clayton 0.5, shared calm", kc2, c(0.5, 0.5)), ("clayton 0.5, inversion", kd2, c(0.5, 0.5))] {
        let est = k as f64 / nsim as f64;
        let se = (est * (1.0 - est) / nsim as f64).sqrt();
        assert!((est - exact).abs() < 4.0 * se);
        println!("simulated {:24} {:.6} +/- {:.6}  exact {:.6}", lab, est, se, exact);
    }

    println!("given A has its worst 1-in-N day, chance B does too (percent):");
    println!("  worst day     independent   gaussian    clayton");
    for p in [0.1, 0.05, 0.01, 0.001, 0.0001] {
        let q = phi_inv(p);
        let (cg, cc) = (gauss(q, q, rho) / p, c(p, p) / p);
        println!("  1 in {:<6} {:9.2} {:10.2} {:10.2}", (1.0 / p).round() as i64, 100.0 * p, 100.0 * cg, 100.0 * cc);
    }
    let lam = c(1e-6, 1e-6) / 1e-6;
    assert!((lam - 2f64.powf(-1.0 / th)).abs() < 1e-6); // formula's limit vs 2^(-1/theta)
    let q6 = phi_inv(1e-6);
    assert!((q6 - -4.753424308822899).abs() < 1e-10); // published 1-in-a-million quantile: tests the tail fraction
    println!("at p=1e-6: clayton {:.6} (limit 2^(-1/theta) {:.6}), gaussian {:.6} (limit 0)", lam, 2f64.powf(-1.0 / th), gauss(q6, q6, rho) / 1e-6);
    let up = (1.0 - 2.0 * 0.99 + c(0.99, 0.99)) / 0.01;
    println!("clayton upper tail, B in its best 1% given A is: {:.2} percent", 100.0 * up);

    let n = 4000usize; // sixteen years of days from the Clayton world
    let mut rng = Rng(7);
    let (mut xa, mut xb) = (Vec::new(), Vec::new());
    for _ in 0..n {
        let z = rng.normal(); let w = z * z / 2.0;
        let (e1, e2) = (-rng.u().ln(), -rng.u().ln());
        xa.push(SA * phi_inv((1.0 + e1 / w).powf(-1.0 / th)));
        xb.push(SB * phi_inv((1.0 + e2 / w).powf(-1.0 / th)));
    }
    let rank = |x: &Vec<f64>| { // ranks 1..n, lowest return = 1
        let mut idx: Vec<usize> = (0..n).collect();
        idx.sort_by(|&i, &j| x[i].partial_cmp(&x[j]).unwrap());
        let mut r = vec![0i64; n];
        for (k, &i) in idx.iter().enumerate() { r[i] = k as i64 + 1; }
        r
    };
    let (ra, rb) = (rank(&xa), rank(&xb));
    let conc: i64 = (0..n).map(|i| (0..i).map(|j| if (ra[i] - ra[j]) * (rb[i] - rb[j]) > 0 { 1 } else { -1 }).sum::<i64>()).sum();
    let tau_hat = conc as f64 / ((n * (n - 1)) as f64 / 2.0);
    assert!((tau_hat - TAU).abs() < 0.03); // Clayton's tau = theta/(theta+2), met by data
    let sc: Vec<f64> = (1..=n).map(|r| phi_inv(r as f64 / (n + 1) as f64)).collect(); // normal scores of the ranks
    let (sa, sb): (Vec<f64>, Vec<f64>) = ((0..n).map(|i| sc[ra[i] as usize - 1]).collect(), (0..n).map(|i| sc[rb[i] as usize - 1]).collect());
    let (sab, saa): (f64, f64) = (sa.iter().zip(&sb).map(|(p, q)| p * q).sum(), sa.iter().map(|p| p * p).sum());
    let (rho_ns, rho_tau) = (sab / saa, (PI * tau_hat / 2.0).sin());
    println!("from ranks: tau-hat {:.4}, rho by tau {:.4}, rho by normal scores {:.4}", tau_hat, rho_tau, rho_ns);
    let m = n / 100; let k = (0..n).filter(|&i| ra[i] <= m as i64 && rb[i] <= m as i64).count();
    let pred = gauss(a01, a01, rho_tau) / 0.01;
    let (fk, fm) = (k as f64, m as f64);
    println!("worst {} days of each: both on the same day {} times ({:.1}% +/- {:.1}); fitted gaussian copula expects {:.1} ({:.1}%)",
        m, k, 100.0 * fk / fm, 100.0 * (fk / fm * (1.0 - fk / fm) / fm).sqrt(), fm * pred, 100.0 * pred);
    let (fa, fb) = (big_phi(-2.0 / SA), big_phi(-2.4 / SB)); let h = c(fa, fb); // Sklar: H(x, y) = C(F(x), G(y))
    println!("sklar by hand: F^-2 = {:.1}, G^-2 = {:.1}, sum minus 1 = {:.1}", fa.powf(-th), fb.powf(-th), fa.powf(-th) + fb.powf(-th) - 1.0);
    let k2 = (0..n).filter(|&i| xa[i] <= -2.0 && xb[i] <= -2.4).count(); let (se2, f2) = ((h * (1.0 - h) / n as f64).sqrt(), k2 as f64 / n as f64);
    assert!((f2 - h).abs() < 4.0 * se2);
    println!("sklar: F(-2%) {:.6}, G(-2.4%) {:.6}, C(F, G) {:.6}; days with both {}/{} = {:.6} +/- {:.6}; gaussian copula {:.6}",
        fa, fb, h, k2, n, f2, se2, gauss(-2.0 / SA, -2.4 / SB, rho));
    let patch = |u: f64, v: f64| [(0.0, 0.0), (0.0, 1.0), (1.0, 0.0), (1.0, 1.0)].iter().map(|&(i, j): &(f64, f64)| (2.0 * u - i).min(2.0 * v - j).clamp(0.0, 1.0)).sum::<f64>() / 4.0;
    let q = |i: usize| i as f64 / 20.0;
    assert!((0..=20).all(|i| (patch(q(i), 1.0) - q(i)).abs() < 1e-12 && (patch(1.0, q(i)) - q(i)).abs() < 1e-12));
    assert!((0..20).all(|i| (0..20).all(|j| patch(q(i + 1), q(j + 1)) - patch(q(i + 1), q(j)) - patch(q(i), q(j + 1)) + patch(q(i), q(j)) > -1e-12))); // patchwork: uniform margins, no negative rectangle, a copula
    let h_coin = |x: usize, y: usize| (0..4).filter(|&w| w / 2 <= x && w % 2 <= y).count() as f64 * 0.25; // two fair coins, F(0) = 0.5, F(1) = 1
    let fc = |x: usize| (x + 1) as f64 / 2.0;
    assert!((0..4).all(|w| (fc(w / 2) * fc(w % 2) - h_coin(w / 2, w % 2)).abs() < 1e-12)); // the product uv
    assert!((0..4).all(|w| (patch(fc(w / 2), fc(w % 2)) - h_coin(w / 2, w % 2)).abs() < 1e-12)); // the patchwork
    let coin = (0..2).filter(|&x| fc(x) <= 0.25).count() as f64 * 0.5;
    println!("coin tosses: P(F(X) <= 0.25) = {:.2}, not 0.25; copulas uv and patchwork (min(u,v)/2 near 0) give C(0.5,0.5) = {:.4} = {:.4}, but at (0.25,0.25) {:.4} vs {:.4}",
        coin, 0.5 * 0.5, patch(0.5, 0.5), 0.25 * 0.25, patch(0.25, 0.25));
    println!("ALL CHECKS PASS");
}
