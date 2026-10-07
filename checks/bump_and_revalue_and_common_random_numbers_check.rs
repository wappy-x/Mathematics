// Bump and revalue -- the same check as the Python, in Rust, std only, no crates.
// Nothing here already holds an answer: the bell-curve area is a series written
// out below, the random numbers come from an arithmetic generator written out
// below, and the tree and the simulation never look at the closed-form delta
// they are scored against.  Four roads reach the same delta, 0.586851.
use std::f64::consts::PI;
const EPS: f64 = f64::EPSILON;                    // machine epsilon, 2.220e-16
const S: f64 = 100.0; const K: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02;
const SIG: f64 = 0.20; const T: f64 = 1.0;
const NP: usize = 200000; const MODULUS: u64 = 1 << 32;
fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }   // height at x
fn n_area(x: f64) -> f64 {                        // bell-curve area to the left of x
    if x < -8.0 { return 0.0; }
    if x > 8.0 { return 1.0; }
    let (mut term, mut total) = (x, x);            // x + x^3/3 + x^5/(3*5) + ...
    for k in 1..120 { term *= x * x / (2.0 * k as f64 + 1.0); total += term; }
    0.5 + phi(x) * total
}
fn d_one(s: f64) -> f64 { ((s / K).ln() + (R - Q + 0.5 * SIG * SIG) * T) / (SIG * T.sqrt()) }
fn call(s: f64) -> f64 {                          // the pricer that gets bumped
    s * (-Q * T).exp() * n_area(d_one(s))
        - K * (-R * T).exp() * n_area(d_one(s) - SIG * T.sqrt())
}
fn central(h: f64) -> f64 { (call(S + h) - call(S - h)) / (2.0 * h) }
fn bump2(h: f64, v0: f64) -> f64 { (call(S + h) - 2.0 * v0 + call(S - h)) / (h * h) }
fn sci(v: f64) -> String {                        // one text shape in both languages
    let e = v.abs().log10().floor() as i32;
    format!("{:.3}e{}{:02}", v / 10f64.powf(e as f64),
            if e < 0 { '-' } else { '+' }, e.abs())
}
fn line(label: &str, v: f64, extra: &str) {
    println!("{}", format!("{:<40}{:>14.6}   {}", label, v, extra).trim_end());
}
fn tree(steps: usize) -> (f64, f64) {             // road three: no bump anywhere
    let dt = T / steps as f64;
    let u = (SIG * dt.sqrt()).exp(); let d = 1.0 / u;
    let p = (((R - Q) * dt).exp() - d) / (u - d); let disc = (-R * dt).exp();
    let mut v: Vec<f64> = (0..=steps)
        .map(|j| (S * u.powf(j as f64) * d.powf((steps - j) as f64) - K).max(0.0))
        .collect();
    for n in (2..=steps).rev() {
        v = (0..n).map(|j| disc * (p * v[j + 1] + (1.0 - p) * v[j])).collect();
    }
    (disc * (p * v[1] + (1.0 - p) * v[0]), (v[1] - v[0]) / (S * u - S * d))
}
fn draws(seed: u64) -> Vec<f64> {                 // own generator, then Box-Muller
    let (mut st, mut out) = (seed, Vec::new());
    for _ in 0..NP / 2 {
        st = (1664525 * st + 1013904223) % MODULUS;
        let u = (st as f64 + 0.5) / MODULUS as f64;
        st = (1664525 * st + 1013904223) % MODULUS;
        let v = (st as f64 + 0.5) / MODULUS as f64;
        let rad = (-2.0 * u.ln()).sqrt(); let ang = 2.0 * PI * v;
        out.push(rad * ang.cos()); out.push(rad * ang.sin());
    }
    out
}
fn stats(xs: &[f64]) -> (f64, f64) {              // mean and standard error, added in order
    let mut t = 0.0;
    for x in xs { t += x; }
    let m = t / NP as f64;
    t = 0.0;
    for x in xs { t += (x - m) * (x - m); }
    (m, (t / (NP - 1) as f64 / NP as f64).sqrt())
}
fn main() {
    let (v0, d1) = (call(S), d_one(S));
    let delta = (-Q * T).exp() * n_area(d1);       // closed-form delta, the score
    let gamma = (-Q * T).exp() * phi(d1) / (S * SIG * T.sqrt());
    let speed = -gamma / S * (d1 / (SIG * T.sqrt()) + 1.0);   // third derivative
    println!("--- 1. the score to beat: closed forms on the Acme call ---");
    line("call price  V(100)", v0, &format!("d1 = {:.4}", d1));
    line("delta   e^-qT N(d1)", delta, "");
    line("gamma   e^-qT phi(d1) / (S sigma sqrtT)", gamma, "");
    line("speed   dGamma/dS", speed, &sci(speed));
    println!("{:<40}{:>14}", "machine epsilon", sci(EPS));
    println!("--- 2. delta by central difference, eleven bump sizes ---");
    println!("{:>10} {:>10}   {:>16} {:>11} {:>13}", "h", "h/S", "central delta", "abs error", "digits right");
    let steps = [1.0, 0.1, 0.01, 1e-3, 1e-4, 1e-5, 1e-6, 1e-7, 1e-8, 1e-9, 1e-10];
    let mut sweep: Vec<(f64, f64, f64, f64)> = Vec::new();
    for h in steps {
        let est = central(h);
        let err = (est - delta).abs();
        sweep.push((h, est, err, -(err / delta).log10()));
        println!("{:>10} {:>10}   {:>16.12} {:>11} {:>13.2}", sci(h), sci(h / S), est, sci(err), -(err / delta).log10());
    }
    let best = sweep.iter().fold(sweep[0], |a, &b| if b.2 < a.2 { b } else { a });
    println!("best bump {}, error {}; rule of thumb eps^(1/3) S = {}; predicted {}",
             sci(best.0), sci(best.2), sci(EPS.powf(1.0 / 3.0) * S),
             sci((3.0 * EPS * v0 / speed.abs()).powf(1.0 / 3.0)));
    line("at h = 1e-15 the bumped prices collide", central(1e-15), "so delta comes out exactly zero");
    println!("--- 3. one-sided against two-sided, bump h = 1 dollar ---");
    let (up, dn) = (call(S + 1.0), call(S - 1.0));
    let (fwd, bwd, cen) = (up - v0, v0 - dn, central(1.0));
    println!("{:<40}{:>14.6}{:>12.6}{:>12.6}", "V(101), V(100), V(99)", up, v0, dn);
    line("forward   (V(101)-V(100))/h", fwd, &format!("error {}", sci(fwd - delta)));
    line("backward  (V(100)-V(99))/h", bwd, &format!("error {}", sci(bwd - delta)));
    line("central   (V(101)-V(99))/(2h)", cen, &format!("error {}", sci(cen - delta)));
    line("predicted one-sided bias  h Gamma/2", gamma / 2.0, &format!("central {}", sci(speed / 6.0)));
    let mut bars = String::from("one-sided error x 1000, h = 10, 4, 2, 1:");
    for h in [10.0, 4.0, 2.0, 1.0] {
        bars.push_str(&format!("{:>8.1}", 1000.0 * ((call(S + h) - v0) / h - delta)));
    }
    println!("{}", bars);
    println!("--- 4. gamma by bump of bump ---");
    println!("{:>10}   {:>16} {:>11}", "h", "gamma", "abs error");
    let mut grows: Vec<(f64, f64, f64)> = Vec::new();
    for h in [1.0, 0.1, 0.01, 1e-4, 1e-6] {
        grows.push((h, bump2(h, v0), (bump2(h, v0) - gamma).abs()));
        let g = grows[grows.len() - 1];
        println!("{:>10}   {:>16.12} {:>11}", sci(h), g.1, sci(g.2));
    }
    let gbest = grows.iter().fold(grows[0], |a, &b| if b.2 < a.2 { b } else { a });
    println!("best bump {}, error {}; rule of thumb eps^(1/4) S = {}",
             sci(gbest.0), sci(gbest.2), sci(EPS.powf(0.25) * S));
    println!("--- 5. a road with no bump at all: a 2000-step binomial tree ---");
    let (t_price, t_delta) = tree(2000);
    line("tree price, 2000 steps", t_price, &format!("formula {:.6}", v0));
    line("tree delta from the two step-1 nodes", t_delta, &format!("formula {:.6}", delta));
    let (disc, drift, vol) = ((-R * T).exp(), (R - Q - 0.5 * SIG * SIG) * T, SIG * T.sqrt());
    let grow = |seed: u64| -> Vec<f64> { draws(seed).iter().map(|z| (drift + vol * z).exp()).collect() };
    let (a, b, c) = (grow(20260919), grow(777), grow(4242));   // a shared; b, c fresh
    let pay = |x: f64, m: f64| disc * (x * m - K).max(0.0);     // one path's payoff
    let shared = |h: f64| -> (f64, f64) {
        stats(&a.iter().map(|m| (pay(S + h, *m) - pay(S - h, *m)) / (2.0 * h)).collect::<Vec<f64>>())
    };
    let fresh = |h: f64| -> (f64, f64) {
        let (u, su) = stats(&b.iter().map(|m| pay(S + h, *m)).collect::<Vec<f64>>());
        let (d, sd) = stats(&c.iter().map(|m| pay(S - h, *m)).collect::<Vec<f64>>());
        ((u - d) / (2.0 * h), (su * su + sd * sd).sqrt() / (2.0 * h))
    };
    println!("--- 6. a road through simulation: 200000 paths, shared and fresh draws ---");
    let (mc_p, mc_se) = stats(&a.iter().map(|m| pay(S, *m)).collect::<Vec<f64>>());
    line("simulated price", mc_p, &format!("+/- {:.6}, shared-draw se ceiling {:.6}", mc_se, 1.0 / (NP as f64).sqrt()));
    println!("{:>6} {:>14} {:>11} {:>13} {:>11} {:>10}",
             "h", "shared delta", "shared se", "fresh delta", "fresh se", "se ratio");
    let mut mc: Vec<(f64, f64, f64, f64, f64)> = Vec::new();
    for h in [5.0, 1.0, 0.1, 0.01] {
        let ((sdd, ss), (fd, fs)) = (shared(h), fresh(h));
        mc.push((h, sdd, ss, fd, fs));
        println!("{:>6.2} {:>14.6} {:>11.6} {:>13.6} {:>11.6} {:>10.1}", h, sdd, ss, fd, fs, fs / ss);
    }
    let (pw, pw_se) = stats(&a.iter().map(|m| if S * m > K { disc * m } else { 0.0 }).collect::<Vec<f64>>());
    line("pathwise delta, no bump at all", pw, &format!("+/- {:.6}", pw_se));
    println!("--- 7. what breaks ---");
    line("divide by h, not 2h", up - dn, "twice the true delta");
    line("one-sided bump at h = 1", fwd, &format!("bias {}", sci(fwd - delta)));
    line("bump half the spot, h = 50", central(50.0), "11 percent low");
    line("delta-sized bump for gamma, h = 1e-06", bump2(1e-6, v0), &format!("gamma is {:.6}", gamma));
    assert!((v0 - 9.227005508154).abs() < 1e-9, "the pricer reproduces the house call price");
    assert!((delta - 0.586851146135).abs() < 1e-9, "closed-form delta, the shelf's number");
    assert!((gamma - 0.018950578755).abs() < 1e-9, "closed-form gamma, the shelf's number");
    assert!(((cen - delta) - speed / 6.0).abs() < 0.02 * (speed / 6.0).abs(), "central bias is h^2 V'''/6");
    assert!(((fwd - delta) - gamma / 2.0).abs() < 0.02 * gamma / 2.0, "one-sided bias is half a bump of gamma");
    assert!((cen - delta).abs() < (fwd - delta).abs() / 100.0, "two-sided beats one-sided a hundredfold");
    assert!((gbest.1 - gamma).abs() < 1e-8, "bumped gamma at its best bump matches the formula");
    assert!(best.2 < (central(10.0) - delta).abs() / 1e4, "left arm: a huge bump is far worse");
    assert!(best.2 < (central(1e-10) - delta).abs() / 1e4, "right arm: a tiny bump is far worse");
    assert!(central(1e-15) == 0.0, "at h = 1e-15 the bumped prices are one number");
    assert!(gbest.0 > 1e-3, "gamma's best bump is far bigger than delta's");
    assert!((t_price - v0).abs() < 0.01, "tree price within a cent of the formula");
    assert!((t_delta - delta).abs() < 2e-4, "tree delta, read off nodes, matches the formula");
    assert!((mc[3].1 - delta).abs() < 3.0 * mc[3].2, "shared-draw delta within three standard errors");
    assert!(mc[3].4 > 100.0 * mc[3].2, "fresh draws are 100x noisier at h = 0.01");
    assert!((pw - delta).abs() < 3.0 * pw_se, "pathwise delta within three standard errors");
    println!("ALL CHECKS PASS");
}
