// Futures against forwards -- the same check as futures_forward_convexity_check.py, in Rust.
// Standard library only, no crates.  Road 1: the closed formula.  Road 2: a trinomial
// tree fitted to the curve by itself.  Road 3: Monte Carlo with home-made random numbers.
use std::f64::consts::PI;

const KAPPA: f64 = 0.2; const SIGMA: f64 = 0.0143; const T: f64 = 3.0; const U: f64 = 3.25; const ALPHA: f64 = 0.25;
fn d(s: f64) -> f64 { (-0.03 * s - 0.002 * s * s).exp() }          // today's discount curve
fn b(k: f64, v: f64) -> f64 { (1.0 - (-k * v).exp()) / k }          // Hull-White loading

struct Closed { bh: f64, q: f64, c: f64, cc: f64, g: f64, k: f64, r: f64, cc_rate: f64 }
fn closed(k: f64, sig: f64, t: f64, u: f64, al: f64) -> Closed {   // road 1: the card's formula
    let h = u - t; let bh = b(k, h);
    let q = sig * sig * (1.0 - (-2.0 * k * t).exp()) / (2.0 * k);
    let c = sig * sig * b(k, t).powi(2) / 2.0;
    let cc = bh * bh * q + bh * c; let g = d(t) / d(u);
    Closed { bh, q, c, cc, g, k: (g - 1.0) / al, r: (g * cc.exp() - 1.0) / al, cc_rate: (cc - bh * bh * q / 2.0) / h }
}

fn tree(k: f64, sig: f64, t: f64, u: f64, al: f64, n: usize) -> (f64, f64) {   // road 2
    let dt = 1.0 / n as f64; let nt = (t * n as f64).round() as usize; let nu = (u * n as f64).round() as usize;
    let dx = sig * (3.0 * dt).sqrt(); let o = nu as i64 + 1; let w = 2 * nu + 3;
    let pr = |j: i64| { let a = -k * dt * j as f64;
        [(1i64, 1.0 / 6.0 + (a * a + a) / 2.0), (0, 2.0 / 3.0 - a * a), (-1, 1.0 / 6.0 + (a * a - a) / 2.0)] };
    let mut qv = vec![0.0; w]; qv[o as usize] = 1.0; let mut shift = Vec::new();
    for i in 0..nu {                                                 // fit each step's shift to D
        let ii = i as i64;
        let s: f64 = (-ii..=ii).map(|j| qv[(j + o) as usize] * (-(j as f64) * dx * dt).exp()).sum();
        let ai = (s / d((i + 1) as f64 * dt)).ln() / dt; shift.push(ai);
        let mut nq = vec![0.0; w];
        for j in -ii..=ii {
            let wt = qv[(j + o) as usize] * (-(ai + j as f64 * dx) * dt).exp();
            for (dj, p) in pr(j) { nq[(j + dj + o) as usize] += p * wt; }
        }
        qv = nq;
    }
    let back = |mut v: Vec<f64>, i1: usize, i0: usize, disc: bool| -> Vec<f64> {
        for i in (i0..i1).rev() {
            let mut nv = vec![0.0; w]; let ii = i as i64;
            for j in -ii..=ii {
                let df = if disc { (-(shift[i] + j as f64 * dx) * dt).exp() } else { 1.0 };
                nv[(j + o) as usize] = df * pr(j).iter().map(|(dj, p)| p * v[(j + dj + o) as usize]).sum::<f64>();
            }
            v = nv;
        }
        v
    };
    let p = back(vec![1.0; w], nu, nt, true);                         // bond T->U at every node
    let lv: Vec<f64> = p.iter().map(|x| if *x > 0.0 { (1.0 / x - 1.0) / al } else { 0.0 }).collect();
    let r = back(lv, nt, 0, false)[o as usize];                       // futures: no discounting
    let fra = back(p.iter().map(|x| 1.0 - x).collect(), nt, 0, true)[o as usize] / (al * d(u));
    (r, fra)
}

struct Rng(u64);
impl Rng {
    fn unif(&mut self) -> f64 {                                       // splitmix64, written out
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15); let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn gauss(&mut self) -> f64 { let a = self.unif(); let c = self.unif(); (-2.0 * a.ln()).sqrt() * (2.0 * PI * c).cos() }
}

fn monte_carlo(k: f64, sig: f64, t: f64, u: f64, al: f64, pairs: usize, rng: &mut Rng) -> (f64, f64, f64, f64) {
    let steps = 60; let dt = t / steps as f64; let e = (-k * dt).exp();
    let sd = sig * ((1.0 - e * e) / (2.0 * k)).sqrt(); let bh = b(k, u - t);
    let phi = |s: f64| 0.03 + 0.004 * s + sig * sig * b(k, s).powi(2) / 2.0;   // fitted drift of r
    let m = 600; let hs = t / m as f64;
    let int_phi = hs / 3.0 * (phi(0.0) + phi(t) + (1..m).map(|i| if i % 2 == 1 { 4.0 } else { 2.0 } * phi(i as f64 * hs)).sum::<f64>());
    let ln_a = (d(u) / d(t)).ln() - bh * bh * sig * sig * (1.0 - (-2.0 * k * t).exp()) / (4.0 * k)
        - bh * sig * sig * b(k, t).powi(2) / 2.0;                    // bond formula from the Hull-White card
    let mut rec: Vec<[(f64, f64); 2]> = Vec::with_capacity(pairs);
    for _ in 0..pairs {
        let zs: Vec<f64> = (0..steps).map(|_| rng.gauss()).collect(); let mut pair = [(0.0, 0.0); 2];
        for (idx, sgn) in [1.0, -1.0].iter().enumerate() {           // antithetic twin
            let (mut x, mut i) = (0.0f64, 0.0f64);
            for z in &zs { let xn = x * e + sd * sgn * z; i += 0.5 * (x + xn) * dt; x = xn; }
            let p = (ln_a - bh * x).exp();
            pair[idx] = ((1.0 / p - 1.0) / al, p * (-int_phi - i).exp());   // rate, weight P/B_T
        }
        rec.push(pair);
    }
    let n = 2.0 * pairs as f64;
    let r = rec.iter().flat_map(|pr| pr.iter()).map(|(l, _)| l).sum::<f64>() / n;
    let wm = rec.iter().flat_map(|pr| pr.iter()).map(|(_, w)| w).sum::<f64>() / n;
    let kf = rec.iter().flat_map(|pr| pr.iter()).map(|(l, w)| l * w).sum::<f64>() / n / wm;
    let v: Vec<f64> = rec.iter().map(|pr| pr.iter().map(|(l, w)| l * (1.0 - w / wm)).sum::<f64>() / 2.0).collect();
    let mu = v.iter().sum::<f64>() / pairs as f64;
    let se = (v.iter().map(|x| (x - mu).powi(2)).sum::<f64>() / (pairs - 1) as f64 / pairs as f64).sqrt();
    (r, kf, wm, se)
}

fn main() {
    let bp = 1e4; let c = closed(KAPPA, SIGMA, T, U, ALPHA);
    let (r80, k80) = tree(KAPPA, SIGMA, T, U, ALPHA, 80);
    let (r160, k160) = tree(KAPPA, SIGMA, T, U, ALPHA, 160);
    let r_rich = 2.0 * r160 - r80;                                    // Richardson: cancel the step-size error
    let mut rng = Rng(20260928);
    let (rm, km, wm, se) = monte_carlo(KAPPA, SIGMA, T, U, ALPHA, 25000, &mut rng);
    let h = U - T;
    let hull_cc = (c.bh / h) * (c.bh * (1.0 - (-2.0 * KAPPA * T).exp()) + 2.0 * KAPPA * b(KAPPA, T).powi(2))
        * SIGMA.powi(2) / (4.0 * KAPPA);                              // Hull's textbook form, typed separately
    let ho_lee = 0.5 * SIGMA.powi(2) * T * U;
    let tiny = closed(1e-6, SIGMA, T, U, ALPHA).cc_rate;              // mean reversion switched off
    let pay_only = (c.g * (c.bh.powi(2) * c.q).exp() - 1.0) / ALPHA - c.k;
    let mut rows: Vec<(&str, f64)> = vec![
        ("b(h), h = 0.25", c.bh), ("b(T), T = 3", b(KAPPA, T)), ("q_T  variance of X_T", c.q),
        ("c_T  covariance with bank log", c.c), ("C = b^2 q + b c", c.cc), ("G0 = D(T)/D(U)", c.g),
        ("1 FRA rate K", c.k), ("1 futures rate R0", c.r), ("1 R0 - K, bp", (c.r - c.k) * bp),
        ("  futures quote 100(1-R0)", 100.0 * (1.0 - c.r)), ("  FRA as a quote 100(1-K)", 100.0 * (1.0 - c.k)),
        ("2 tree n=80, R0 - K, bp", (r80 - k80) * bp), ("2 tree n=160, R0 - K, bp", (r160 - k160) * bp),
        ("2 tree extrapolated, bp", (r_rich - k160) * bp), ("3 Monte Carlo R0 - K, bp", (rm - km) * bp),
        ("  Monte Carlo std error, bp", se * bp), ("  MC weight vs D(U)", wm), ("  D(U)", d(U)),
        ("4 cc adjustment, bp", c.cc_rate * bp), ("  Hull textbook form, bp", hull_cc * bp),
        ("5 kappa -> 0, cc, bp", tiny * bp), ("  Ho-Lee 1/2 s^2 T U, bp", ho_lee * bp),
        ("piece: payment date only, bp", pay_only * bp), ("piece: bank account, bp", (c.r - c.k - pay_only) * bp),
        ("dollars per contract, $25/bp", (c.r - c.k) * bp * 25.0),
        ("wrong: sign flipped, FRA est.", c.r + (c.r - c.k)), ("wrong: Ho-Lee rule, bp", ho_lee * bp),
        ("wrong: cc formula on simple, bp", c.cc_rate * bp)];
    for (sig, lab) in [(0.0286, "try: sigma doubled, bp"), (0.01, "try: sigma = 0.01, bp")] {
        let x = closed(KAPPA, sig, T, U, ALPHA); rows.push((lab, (x.r - x.k) * bp));
    }
    let x = closed(0.05, SIGMA, T, U, ALPHA); rows.push(("try: kappa = 0.05, bp", (x.r - x.k) * bp));
    for (name, v) in &rows { println!("{:<34} {:>14.8}", name, v); }
    let ts = [0.5, 1.0, 2.0, 3.0, 4.0, 5.0, 7.0, 10.0];
    let join = |f: &dyn Fn(f64) -> f64, p: usize| ts.iter().map(|t| format!("{:6.*}", p, f(*t))).collect::<Vec<_>>().join(" ");
    println!("\nchart, fixing year      {}", join(&|t| t, 1));
    println!("chart, exact simple bp  {}", join(&|t| { let x = closed(KAPPA, SIGMA, t, t + h, ALPHA); (x.r - x.k) * bp }, 2));
    println!("chart, Hull-White cc bp {}", join(&|t| closed(KAPPA, SIGMA, t, t + h, ALPHA).cc_rate * bp, 2));
    println!("chart, Ho-Lee rule bp   {}", join(&|t| 0.5 * SIGMA.powi(2) * t * (t + h) * bp, 2));

    assert!(((r_rich - k160) - (c.r - c.k)).abs() < 0.01 / bp, "tree, fitted by itself, lands on the formula");
    assert!(((rm - km) - (c.r - c.k)).abs() < 4.0 * se, "Monte Carlo within four standard errors");
    assert!((wm / d(U) - 1.0).abs() < 1e-3, "simulated bank reprices the curve");
    assert!((hull_cc - c.cc_rate).abs() < 1e-12, "Hull's printed formula equals the derived one");
    assert!((tiny - ho_lee).abs() < 1e-3 * ho_lee, "no mean reversion gives the Ho-Lee rule");
    println!("ALL CHECKS PASS");
}
