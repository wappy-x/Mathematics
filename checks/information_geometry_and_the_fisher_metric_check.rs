// Fisher metric: a family of models as a curved space.  std only, no crates.
// Coin family: distance three ways, then exact error rates.  Normal family:
// Fisher matrix four ways, curvature, Fisher-Rao distance, natural-gradient steps.
use std::f64::consts::PI;

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut tot = 0.0;
    for i in 0..=n {
        let w = if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        tot += w * f(a + i as f64 * h);
    }
    h / 3.0 * tot
}
// ---- coins: ds^2 = dp^2 / (p(1-p)) per flip ----
fn d_arc(p0: f64, p1: f64) -> f64 { 2.0 * (p1.sqrt().asin() - p0.sqrt().asin()).abs() }
fn d_p(p0: f64, p1: f64) -> f64 { simpson(&|p: f64| 1.0 / (p * (1.0 - p)).sqrt(), p0, p1, 2000) }
fn d_logodds(p0: f64, p1: f64) -> f64 {
    let e = |p: f64| (p / (1.0 - p)).ln();
    simpson(&|t: f64| t.exp().sqrt() / (1.0 + t.exp()), e(p0), e(p1), 2000)
}
fn exact_error(p0: f64, p1: f64, n: usize) -> f64 { // best rule: pick the model with higher likelihood
    let mut lf = vec![0.0; n + 1];
    for k in 1..=n { lf[k] = lf[k - 1] + (k as f64).ln(); }
    let mut e = 0.0;
    for k in 0..=n {
        let (kf, rf) = (k as f64, (n - k) as f64);
        let c = lf[n] - lf[k] - lf[n - k];
        let l0 = c + kf * p0.ln() + rf * (1.0 - p0).ln();
        let l1 = c + kf * p1.ln() + rf * (1.0 - p1).ln();
        e += if l1 > l0 { l0.exp() } else { l1.exp() };
    }
    e / 2.0
}
fn phi(x: f64) -> f64 { simpson(&|z: f64| (-z * z / 2.0).exp() / (2.0 * PI).sqrt(), -12.0, x, 2000) }
// ---- normal family N(mu, sigma^2): coin weights in grams ----
const M: f64 = 5.670; const S: f64 = 0.020; // batch mean and standard deviation (divide by n)
const MU0: f64 = 5.600; const SG0: f64 = 0.050; // starting guess
fn avg_ll(mu: f64, sg: f64) -> f64 { -sg.ln() - (S * S + (M - mu).powi(2)) / (2.0 * sg * sg) - 0.5 * (2.0 * PI).ln() }
fn grad(mu: f64, sg: f64, u: f64) -> (f64, f64) { // u = 1000 when every length is in milligrams
    let v = (S * u).powi(2) + (M * u - mu).powi(2);
    ((M * u - mu) / sg.powi(2), -1.0 / sg + v / sg.powi(3))
}
fn g(_mu: f64, sg: f64) -> (f64, f64) { (1.0 / sg.powi(2), 2.0 / sg.powi(2)) } // diag(g_11, g_22), g_12 = 0
fn score(x: f64, mu: f64, sg: f64) -> (f64, f64) { let z = (x - mu) / sg; (z / sg, (z * z - 1.0) / sg) }
fn dens(z: f64) -> f64 { (-z * z / 2.0).exp() / (2.0 * PI).sqrt() }
struct Rng(u64); // SplitMix64 for the simulation road
impl Rng {
    fn u01(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 2f64.powi(53)
    }
}
fn kl(m1: f64, s1: f64, m2: f64, s2: f64) -> f64 { (s2 / s1).ln() + (s1 * s1 + (m1 - m2).powi(2)) / (2.0 * s2 * s2) - 0.5 }
fn curv(mu: f64, sg: f64, r: f64) -> f64 { // Brioschi with F = 0, every slope numerical
    let e = sg * r;
    let ee = |y: f64| g(mu, y).0; let gg = |y: f64| g(mu, y).1;
    let f = |y: f64| (ee(y + e) - ee(y - e)) / (2.0 * e) / (ee(y) * gg(y)).sqrt(); // E_sigma / sqrt(EG); G_mu = 0
    -(f(sg + e) - f(sg - e)) / (2.0 * e) / (2.0 * (ee(sg) * gg(sg)).sqrt())
}
fn d_closed(m1: f64, s1: f64, m2: f64, s2: f64) -> f64 {
    2f64.sqrt() * (1.0 + ((m1 - m2).powi(2) / 2.0 + (s1 - s2).powi(2)) / (2.0 * s1 * s2)).acosh()
}
fn length(path: &dyn Fn(f64) -> (f64, f64), n: usize) -> f64 { // Fisher length of a path t -> (mu, sigma), t in [0, 1]
    let ds = |t: f64| {
        let e = 1e-6; let (a1, b1) = path(t - e); let (a2, b2) = path(t + e);
        ((a2 - a1).powi(2) + 2.0 * (b2 - b1).powi(2)).sqrt() / (2.0 * e) / path(t).1
    };
    simpson(&ds, 0.0, 1.0, n) // Simpson's rule with n steps
}
fn natural(q: (f64, f64), eta: f64, u: f64) -> (f64, f64) {
    let (a, b) = grad(q.0, q.1, u); let (aa, bb) = g(q.0, q.1); (q.0 + eta * a / aa, q.1 + eta * b / bb)
}
fn plain(q: (f64, f64), eta: f64, u: f64) -> (f64, f64) { let (a, b) = grad(q.0, q.1, u); (q.0 + eta * a, q.1 + eta * b) }
fn first(qs: &[(f64, f64)]) -> usize { qs.iter().position(|q| (q.0 - M).abs() < 1e-4 && (q.1 - S).abs() < 1e-4).unwrap() }
fn run(start: (f64, f64), steps: usize, step: &dyn Fn((f64, f64)) -> (f64, f64)) -> Vec<(f64, f64)> {
    let mut v = vec![start];
    for _ in 0..steps { let q = step(*v.last().unwrap()); v.push(q); }
    v
}

fn main() {
    let (mut flips, mut errs) = (vec![], vec![]);
    for (p0, p1) in [(0.50, 0.51), (0.98, 0.99)] {
        let (a, b, c) = (d_arc(p0, p1), d_p(p0, p1), d_logodds(p0, p1));
        let n = (3.0 / a).powi(2).round() as usize; flips.push(n);
        let klc = p0 * (p0 / p1).ln() + (1.0 - p0) * ((1.0 - p0) / (1.0 - p1)).ln();
        let er = exact_error(p0, p1, n); errs.push(er);
        println!("coin {:.2} vs {:.2}: distance arcsin {:.6} | p-chart {:.6} | log-odds chart {:.6}", p0, p1, a, b, c);
        println!("  flips for 3 standard errors {} | exact error {:.6} | KL {:.6} | d^2/2 {:.6}", n, er, klc, a * a / 2.0);
        assert!((a - b).abs() < 1e-6 && (a - c).abs() < 1e-6);
    }
    println!("normal approximation of that error Phi(-1.5) = {:.6} | whole coin family length {:.6}", phi(-1.5), d_arc(0.0, 1.0));
    assert!((errs[0] - phi(-1.5)).abs() < 0.002 && (errs[1] - phi(-1.5)).abs() < 0.002);
    println!("ratios, 0.98 pair over 0.50 pair: distance {:.2} | flips {:.1}", d_arc(0.98, 0.99) / d_arc(0.50, 0.51), flips[0] as f64 / flips[1] as f64);
    let pts: Vec<String> = [0.01, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 0.98].iter()
        .map(|&p| format!("{:.2}:{:.0}", p, (3.0 / d_arc(p, p + 0.01)).powi(2))).collect();
    println!("chart flips: {}", pts.join(", "));

    let fs: [fn((f64, f64)) -> f64; 3] = [|t| t.0 * t.0, |t| t.1 * t.1, |t| t.0 * t.1];
    let quad: Vec<f64> = fs.iter().map(|f| simpson(&|z: f64| f(score(MU0 + SG0 * z, MU0, SG0)) * dens(z), -12.0, 12.0, 2000)).collect();
    let mut rng = Rng(20261119);
    let nn = 200000usize; let nf = nn as f64;
    let mut mc = [0.0f64; 3];
    for _ in 0..nn / 2 {
        let r = (-2.0 * (1.0 - rng.u01()).ln()).sqrt(); let t = 2.0 * PI * rng.u01();
        for z in [r * t.cos(), r * t.sin()] {
            let (a, b) = score(MU0 + SG0 * z, MU0, SG0); mc[0] += a * a / nf; mc[1] += b * b / nf; mc[2] += a * b / nf;
        }
    }
    let h = 1e-4;
    let klg = ((kl(MU0, SG0, MU0 + h, SG0) + kl(MU0, SG0, MU0 - h, SG0)) / (h * h),
               (kl(MU0, SG0, MU0, SG0 + h) + kl(MU0, SG0, MU0, SG0 - h)) / (h * h));
    let gm0 = g(MU0, SG0);
    println!("Fisher at (5.600, 0.050): formula {:.4} {:.4} 0 | quadrature {:.4} {:.4} {:.4}", gm0.0, gm0.1, quad[0], quad[1], quad[2].abs());
    println!("  simulated {:.1} {:.1} {:.1} | KL both sides / h^2 {:.2} {:.2}", mc[0], mc[1], mc[2], klg.0, klg.1);
    assert!((quad[0] - gm0.0).abs() < 1e-6 && (quad[1] - gm0.1).abs() < 1e-6 && quad[2].abs() < 1e-9);
    assert!((mc[0] - gm0.0).abs() < 5.0 * gm0.0 * (2.0 / nf).sqrt() && (mc[1] - gm0.1).abs() < 5.0 * gm0.1 * (8.0 / nf).sqrt());
    assert!((klg.0 - gm0.0).abs() < 0.1 && (klg.1 - gm0.1).abs() < 0.5);
    println!("curvature K, slope steps 1% and 0.1% of sigma: start {:.6} {:.6} | fit {:.6} {:.6}",
             curv(MU0, SG0, 1e-2), curv(MU0, SG0, 1e-3), curv(M, S, 1e-2), curv(M, S, 1e-3));
    assert!((curv(MU0, SG0, 1e-3) + 0.5).abs() < 1e-5 && (curv(M, S, 1e-3) + 0.5).abs() < 1e-5);

    let (x1, x2) = (MU0 / 2f64.sqrt(), M / 2f64.sqrt()); // geodesic: half circle in (mu/sqrt2, sigma)
    let c = (x2 * x2 + S * S - x1 * x1 - SG0 * SG0) / (2.0 * (x2 - x1)); let rr = ((x1 - c).powi(2) + SG0 * SG0).sqrt();
    let (t1, t2) = (SG0.atan2(x1 - c), S.atan2(x2 - c));
    let arc = |t: f64| (2f64.sqrt() * (c + rr * (t1 + (t2 - t1) * t).cos()), rr * (t1 + (t2 - t1) * t).sin());
    let line = |t: f64| (MU0 + (M - MU0) * t, SG0 + (S - SG0) * t);
    let (dc, da, db, dl, dm) = (d_closed(MU0, SG0, M, S), length(&arc, 20), length(&arc, 40), length(&line, 20), length(&line, 40));
    let lc = ((M - MU0).powi(2) + 2.0 * (S - SG0).powi(2)).sqrt() / (SG0 - S) * (SG0 / S).ln(); // straight line, closed form
    println!("Fisher-Rao distance start to fit: closed form {:.6} | along geodesic, 20 and 40 steps {:.6} {:.6}", dc, da, db);
    println!("  straight line: 20 and 40 steps {:.6} {:.6} | closed form {:.6}", dl, dm, lc);
    assert!((dc - db).abs() < 1e-5 && (dc - db).abs() < (dc - da).abs() / 8.0 && (dm - lc).abs() < 1e-6 && lc > dc); // halving the step

    let (gm, gs) = grad(MU0, SG0, 1.0);
    let nat = (gm / gm0.0, gs / gm0.1); // natural gradient g^ij dL/dtheta^j
    let score_dir = |k: usize| { let a = k as f64 * PI / 18000.0; gm * a.cos() / gm0.0.sqrt() + gs * a.sin() / gm0.1.sqrt() };
    let mut best = 0; for k in 0..36000 { if score_dir(k) > score_dir(best) { best = k; } }
    let th = best as f64 * PI / 18000.0; let dirn = (th.cos() / gm0.0.sqrt(), th.sin() / gm0.1.sqrt()); // best unit-Fisher-length step
    println!("gradient {:.4} {:.4} | natural step {:.6} {:.6} | slope ratio formula {:.4}, search {:.4}", gm, gs, nat.0, nat.1, nat.1 / nat.0, dirn.1 / dirn.0);
    assert!((nat.1 / nat.0 - dirn.1 / dirn.0).abs() < 1e-3);
    let pn = run((MU0, SG0), 30, &|q| natural(q, 1.0, 1.0));
    let pp = run((MU0, SG0), 30, &|q| plain(q, 0.0002, 1.0));
    for k in 0..7 { println!("natural step {}: mu {:.6} sigma {:.6} avg log-lik {:.6}", k, pn[k].0, pn[k].1, avg_ll(pn[k].0, pn[k].1)); }
    let ch = |v: &[(f64, f64)]| v[..11].iter().map(|q| format!("{:.3}", avg_ll(q.0, q.1))).collect::<Vec<_>>().join(", ");
    println!("chart natural: {}\nchart plain:   {}", ch(&pn), ch(&pp));
    let q4 = run((MU0, SG0), 31, &|q| plain(q, 0.0004, 1.0));
    println!("steps to within 0.0001 g: natural {} | plain eta 0.0002 {} | plain eta 0.0004 sigma at 30, 31: {:.6} {:.6}", first(&pn), first(&pp), q4[30].1, q4[31].1);
    assert!(first(&pn) == 5 && first(&pp) > 20 && (pn[1].0 - M).abs() < 1e-12);

    // ---- what breaks ----
    let mg = plain((MU0 * 1000.0, SG0 * 1000.0), 0.0002, 1000.0); // same eta, coordinates in milligrams
    let nmg = natural((MU0 * 1000.0, SG0 * 1000.0), 1.0, 1000.0);
    let one = SG0 + gs * SG0 * SG0; // Fisher entry for sigma taken as 1/sigma^2
    let tau = SG0.ln() + SG0 * gs / 2.0; // natural step in chart (mu, ln sigma): g = diag(1/sigma^2, 2)
    let small = (SG0 + 0.01 * gs / gm0.1, (SG0.ln() + 0.01 * SG0 * gs / 2.0).exp());
    println!("plain step in g {:.6} | same eta in mg, back in g {:.10} | natural in mg, back in g {:.6}", pp[1].0 - MU0, (mg.0 - MU0 * 1000.0) / 1000.0, (nmg.0 - MU0 * 1000.0) / 1000.0);
    println!("sigma after one step: right {:.6} | missing the 2 {:.6} | chart ln sigma {:.6} | eta 0.01 both charts {:.7} {:.7}", pn[1].1, one, tau.exp(), small.0, small.1);
    assert!(((nmg.0 - MU0 * 1000.0) / 1000.0 - nat.0).abs() < 1e-9 && (small.0 - small.1).abs() < 1e-6 && 1e-6 < (tau.exp() - pn[1].1).abs());

    // ---- try changing ----
    let nh = run((MU0, SG0), 30, &|q| natural(q, 0.5, 1.0));
    let nw = run((MU0, 0.010), 30, &|q| natural(q, 1.0, 1.0));
    println!("try: 0.50 vs 0.51 at 4 standard errors {:.0} flips | natural eta 0.5 steps {} | start sigma 0.010: step 1 sigma {:.6}, steps {}",
             (4.0 / d_arc(0.50, 0.51)).powi(2), first(&nh), nw[1].1, first(&nw));
    println!("ALL CHECKS PASS");
}
