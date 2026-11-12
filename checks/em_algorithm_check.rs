// EM for two kinds of shopper -- the same check as em_algorithm_check.py, in Rust.
// Standard library only, no crates.  The 20,000 order totals are synthetic (SplitMix64, Box-Muller).
// psum adds a list the way Python's sum() does (Neumaier's compensated sum), so both print the same digits.
// Compile: rustc --edition 2021 -O em_algorithm_check.rs -o /tmp/em_algorithm_check
use std::f64::consts::PI;
type Th = [f64; 5]; // weekly share, top-up mean, top-up sd, weekly mean, weekly sd

struct SplitMix64 { s: u64 }
impl SplitMix64 {
    fn next(&mut self) -> u64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let z = (self.s ^ (self.s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn uniform(&mut self) -> f64 { (self.next() >> 11) as f64 / 9007199254740992.0 }
    fn normal(&mut self) -> f64 { // Box-Muller: two uniforms -> one bell draw
        let (u1, u2) = (1.0 - self.uniform(), self.uniform());
        (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos()
    }
}

fn orders(n: usize, share: f64, m1: f64, s1: f64, m2: f64, s2: f64) -> (Vec<f64>, Vec<bool>) {
    let mut g = SplitMix64 { s: 2026 };
    let (mut xs, mut weekly) = (Vec::new(), Vec::new());
    for _ in 0..n {
        let w = g.uniform() < share;
        xs.push(if w { m2 + s2 * g.normal() } else { m1 + s1 * g.normal() }); weekly.push(w);
    }
    (xs, weekly)
}

fn psum<I: Iterator<Item = f64>>(it: I) -> f64 {
    let (mut f, mut c) = (0.0f64, 0.0f64);
    for x in it { let t = f + x; c += if f.abs() >= x.abs() { (f - t) + x } else { (x - t) + f }; f = t; }
    if c != 0.0 && c.is_finite() { f + c } else { f }
}
fn log_bell(x: f64, m: f64, s: f64) -> f64 { -0.5 * ((x - m) / s) * ((x - m) / s) - (s * (2.0 * PI).sqrt()).ln() }
fn mix(x: f64, th: &Th) -> (f64, f64) { // ln of the two-bell density at x, and r = chance x is weekly
    let (l1, l2) = ((1.0 - th[0]).ln() + log_bell(x, th[1], th[2]), th[0].ln() + log_bell(x, th[3], th[4]));
    let hi = l1.max(l2);
    let (e1, e2) = ((l1 - hi).exp(), (l2 - hi).exp());
    (hi + (e1 + e2).ln(), e2 / (e1 + e2))
}
fn loglik(xs: &[f64], th: &Th) -> f64 { psum(xs.iter().map(|&x| mix(x, th).0)) }

fn m_step(xs: &[f64], rs: &[f64]) -> Th { // weighted maximum likelihood: order i counts r_i as weekly
    let p = || rs.iter().zip(xs.iter());
    let n2 = psum(rs.iter().cloned()); let n1 = xs.len() as f64 - n2;
    let m1 = psum(p().map(|(r, x)| (1.0 - r) * x)) / n1;
    let m2 = psum(p().map(|(r, x)| r * x)) / n2;
    let s1 = (psum(p().map(|(r, x)| (1.0 - r) * (x - m1) * (x - m1))) / n1).sqrt();
    let s2 = (psum(p().map(|(r, x)| r * (x - m2) * (x - m2))) / n2).sqrt();
    [n2 / xs.len() as f64, m1, s1, m2, s2]
}
fn em_round(xs: &[f64], th: &Th, hard: bool, share_in_e: bool) -> Th {
    let mut t = *th; if !share_in_e { t[0] = 0.5 } // mistake: E-step ignores the share
    let mut rs: Vec<f64> = xs.iter().map(|&x| mix(x, &t).1).collect();
    if hard { rs = rs.iter().map(|&r| if r > 0.5 { 1.0 } else { 0.0 }).collect() } // mistake: hard labels
    m_step(xs, &rs)
}
fn run(xs: &[f64], start: Th, hard: bool, share_in_e: bool) -> (Th, Vec<f64>, usize, Vec<Th>) {
    let (mut th, mut lls, mut path, mut k) = (start, vec![loglik(xs, &start)], vec![start], 0);
    for kk in 1..=1000 {
        let new = em_round(xs, &th, hard, share_in_e);
        let moved = (0..5).map(|i| (th[i] - new[i]).abs()).fold(0.0f64, f64::max);
        th = new; k = kk;
        lls.push(loglik(xs, &th)); path.push(th);
        if moved < 1e-9 { break }
    }
    (th, lls, k, path)
}
fn bound(xs: &[f64], rs: &[f64], th: &Th) -> f64 { // the lower bound B: sum of r ln(part / r)
    let mut b = 0.0; for (&r, &x) in rs.iter().zip(xs.iter()) {
        if r < 1.0 { b += (1.0 - r) * ((1.0 - th[0]).ln() + log_bell(x, th[1], th[2]) - (1.0 - r).ln()) }
        if r > 0.0 { b += r * (th[0].ln() + log_bell(x, th[3], th[4]) - r.ln()) }
    } b
}
fn slopes(xs: &[f64], th: &Th) -> f64 { // road 2: largest slope of ln-likelihood by nudging
    let h = 1e-5;
    (0..5).map(|i| {
        let (mut up, mut dn) = (*th, *th); up[i] += h; dn[i] -= h;
        ((loglik(xs, &up) - loglik(xs, &dn)) / (2.0 * h)).abs()
    }).fold(0.0f64, f64::max)
}
fn show(t: &Th) -> String { format!("share {:.4}  top-up {:.2} sd {:.2}  weekly {:.2} sd {:.2}", t[0], t[1], t[2], t[3], t[4]) }
fn join(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(" ") }

fn main() {
    // ---- by hand: six orders, one round from a start of 20 and 60, spread 10, share 0.5 ----
    let six = [15.0, 22.0, 28.0, 40.0, 60.0, 75.0];
    let start6: Th = [0.5, 20.0, 10.0, 60.0, 10.0];
    let r6: Vec<f64> = six.iter().map(|&x| mix(x, &start6).1).collect();
    for (&x, &r) in six.iter().zip(r6.iter()) { println!("hand E  order {:5.2}  x-40 {:6.2}  odds e^(0.4(x-40)) {:15.6}  r {:.6}", x, x - 40.0, (0.4 * (x - 40.0)).exp(), r) }
    let new6 = m_step(&six, &r6);
    println!("hand M  soft count weekly {:.6}  top-up {:.6}", psum(r6.iter().cloned()), 6.0 - psum(r6.iter().cloned()));
    println!("hand M  sum of r*spend weekly {:.6}  top-up {:.6}", psum(r6.iter().zip(six.iter()).map(|(r, x)| r * x)), psum(r6.iter().zip(six.iter()).map(|(r, x)| (1.0 - r) * x)));
    println!("hand M  {}", show(&new6));
    let (l_old, b_old, b_new, l_new) = (loglik(&six, &start6), bound(&six, &r6, &start6), bound(&six, &r6, &new6), loglik(&six, &new6));
    println!("hand ln-lik before {:.6}  bound before {:.6}  bound after {:.6}  ln-lik after {:.6}", l_old, b_old, b_new, l_new);
    let (fit6, lls6, k6, _) = run(&six, start6, false, true);
    println!("six orders settle after {} rounds: {}  ln-lik {:.6}", k6, show(&fit6), lls6[lls6.len() - 1]);

    // ---- the shop: 20,000 orders, 35% weekly shoppers N(70, 15), the rest top-ups N(25, 6) ----
    let (xs, weekly) = orders(20000, 0.35, 25.0, 6.0, 70.0, 15.0);
    let (lo_x, hi_x) = xs.iter().fold((f64::MAX, f64::MIN), |(a, b), &x| (a.min(x), b.max(x)));
    println!("orders {}  hidden weekly {}  smallest {:.2}  largest {:.2}", xs.len(), weekly.iter().filter(|&&w| w).count(), lo_x, hi_x);
    let start: Th = [0.5, 30.0, 20.0, 50.0, 20.0];
    let (fit, lls, rounds, path) = run(&xs, start, false, true);
    for k in [0usize, 1, 2, 3, 5, 10, 20] { println!("round {:2}  {}  ln-lik {:.1}", k, show(&path[k]), lls[k]) }
    println!("settled after {} rounds: {}  ln-lik {:.1}", rounds, show(&fit), lls[lls.len() - 1]);
    let gains: Vec<f64> = (0..rounds).map(|k| lls[k + 1] - lls[k]).collect();
    println!("chart, ln-lik rounds 0-15: {}", join(&lls[..16], 0));
    println!("rounds where ln-lik fell: {} of {}", gains.iter().filter(|&&g| g < -1e-9).count(), rounds);
    let lab = m_step(&xs, &weekly.iter().map(|&w| if w { 1.0 } else { 0.0 }).collect::<Vec<f64>>());
    println!("labels known: {}", show(&lab));
    let (sl_fit, sl_start) = (slopes(&xs, &fit), slopes(&xs, &start));
    println!("largest slope at the fit {:.6}  at the start {:.1}", sl_fit, sl_start);
    let rr: Vec<f64> = [30.0, 35.0, 40.0, 45.0, 50.0].iter().map(|&x| mix(x, &fit).1).collect();
    println!("r at 30 35 40 45 50: {}", join(&rr, 3));
    let (mut lo, mut hi) = (30.0f64, 60.0f64);
    for _ in 0..60 { let mid = (lo + hi) / 2.0; if mix(mid, &fit).1 < 0.5 { lo = mid } else { hi = mid } }
    println!("an order is even odds at {:.2}", lo);

    // ---- what breaks ----
    let hard = run(&xs, start, true, true).0;
    println!("hard labels: {}  ln-lik {:.1}", show(&hard), loglik(&xs, &hard));
    let noshare = run(&xs, start, false, false).0;
    println!("share left out of E: {}  ln-lik {:.1}", show(&noshare), loglik(&xs, &noshare));
    let (sym, lsym, ks, _) = run(&xs, [0.5, 40.0, 20.0, 40.0, 20.0], false, true);
    println!("same start for both: {}  ln-lik {:.1}  after {} rounds", show(&sym), lsym[lsym.len() - 1], ks);
    let (mut th, mut sig, mut ll): (Th, Vec<f64>, Vec<f64>) = ([0.05, 40.0, 25.0, 130.0, 2.0], vec![], vec![]);
    while th[4] > 0.0 && sig.len() < 12 { // run until the spread is exactly zero
        th = em_round(&xs, &th, false, true); sig.push(th[4]);
        ll.push(if th[4] > 0.0 { loglik(&xs, &th) } else { f64::NAN });
    }
    let n = sig.len();
    println!("needle start: weekly sd by round {} then {:.2e}, then exactly {:.1}", join(&sig[..n - 2], 4), sig[n - 2], sig[n - 1]);
    println!("needle start: ln-lik by round {} then none: the bell formula divides by the zero spread", join(&ll[..ll.len() - 1], 1));
    println!("needle start: weekly bell sits on {:.2}, share {:.6}", th[3], th[0]);

    // ---- the picture: spend histogram in 10-pound bins, and the fitted two-bell curve ----
    let counts: Vec<String> = (0..14).map(|b| xs.iter().filter(|&&x| 10.0 * b as f64 <= x && x < 10.0 * b as f64 + 10.0).count().to_string()).collect();
    let area = |a: f64, b: f64| {
        let n = 100;
        psum((0..=n).map(|j| (if j == 0 || j == n { 1.0 } else if j % 2 == 1 { 4.0 } else { 2.0 })
            * mix(a + j as f64 * (b - a) / n as f64, &fit).0.exp())) * (b - a) / (3 * n) as f64
    };
    println!("chart, orders per bin: {}", counts.join(" "));
    let fitted: Vec<f64> = (0..14).map(|b| 20000.0 * area(10.0 * b as f64, 10.0 * b as f64 + 10.0)).collect();
    println!("chart, fitted per bin: {}", join(&fitted, 0));

    // ---- try changing ----
    let (near, _) = orders(20000, 0.35, 25.0, 6.0, 45.0, 15.0);
    let (fnear, _, kn2, _) = run(&near, start, false, true);
    println!("try: weekly mean 45, rounds {}: {}", kn2, show(&fnear));
    let (small, _) = orders(200, 0.35, 25.0, 6.0, 70.0, 15.0);
    println!("try: 200 orders: {}", show(&run(&small, start, false, true).0));
    println!("try: starts swapped: {}", show(&run(&xs, [0.5, 50.0, 20.0, 30.0, 20.0], false, true).0));

    assert!(gains.iter().all(|&g| g > -1e-9) && lls6.windows(2).all(|w| w[1] - w[0] > -1e-9), "EM never lowers ln-lik");
    assert!((b_old - l_old).abs() < 1e-9 && l_old < b_new && b_new <= l_new, "bound touches before, sandwiched after");
    assert!(sl_fit < 0.01 && 0.01 < sl_start, "fit is a flat point; start is not");
    assert!((fit[0] - lab[0]).abs() < 0.01 && (1..5).all(|i| (fit[i] - lab[i]).abs() < 0.5), "EM finds the labelled fit");
    assert!((sym[1] - sym[3]).abs() < 1e-9 && lsym[lsym.len() - 1] < lls[lls.len() - 1] - 1000.0, "identical start never splits");
    assert!(sig[n - 1] == 0.0 && ll[..n - 1].windows(2).all(|w| w[1] > w[0]), "needle start climbs, then collapses onto one order");
    println!("ALL CHECKS PASS");
}
