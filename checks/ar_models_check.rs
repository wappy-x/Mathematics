// Autoregression, AR(1) and AR(2): X_t = 0.1 + 0.8 X_(t-1) + shock, sd 1.2.
// The same check as the Python, std only.  Every random draw comes from SplitMix64 (seed 2026) and
// Box-Muller, written out here, so both languages draw the same numbers.
const PHI: f64 = 0.8; const C: f64 = 0.1; const SIG: f64 = 1.2; const X_NOW: f64 = 4.5;
const N: usize = 365; const YEARS: usize = 2000; const PATHS: usize = 20000;

struct Rng(u64);
impl Rng {
    fn u01(&mut self) -> f64 {               // SplitMix64, mapped into (0, 1)
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 2f64.powi(53)
    }
    fn gauss(&mut self) -> f64 {             // Box-Muller: one standard normal draw
        let (u1, u2) = (self.u01(), self.u01());
        (-2.0 * u1.ln()).sqrt() * (2.0 * std::f64::consts::PI * u2).cos()
    }
}

fn mu() -> f64 { C / (1.0 - PHI) }
fn var() -> f64 { SIG.powf(2.0) / (1.0 - PHI.powf(2.0)) }

fn cdf(x: f64) -> f64 {                      // Phi(x): 1/2 plus a Simpson integral
    let (n, h) = (2000, x / 2000.0);
    let mut s = 0.0;
    for i in 0..=n {
        let w = if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        s += w * (-(i as f64 * h).powf(2.0) / 2.0).exp();
    }
    0.5 + s * h / 3.0 / (2.0 * std::f64::consts::PI).sqrt()
}

fn year(rng: &mut Rng) -> (Vec<f64>, Vec<f64>) { // day 0 from the stationary law, then 365 days
    let (mut x, mut eps) = (vec![mu() + var().sqrt() * rng.gauss()], Vec::new());
    for _ in 0..N {
        eps.push(SIG * rng.gauss());
        let next = C + PHI * x[x.len() - 1] + eps[eps.len() - 1]; x.push(next);
    }
    (x[1..].to_vec(), eps)
}

fn mean(v: &[f64]) -> f64 { v.iter().fold(0.0, |s, x| s + x) / v.len() as f64 }

fn ls_ar1(x: &[f64]) -> (f64, f64, f64, f64) { // road one: least squares, today on yesterday
    let (a, b) = (&x[..x.len() - 1], &x[1..]);
    let (ma, mb) = (mean(a), mean(b));
    let sxx = a.iter().fold(0.0, |s, u| s + (u - ma).powf(2.0));
    let slope = a.iter().zip(b).fold(0.0, |s, (u, v)| s + (u - ma) * (v - mb)) / sxx;
    let icpt = mb - slope * ma;
    let s2 = a.iter().zip(b).fold(0.0, |s, (u, v)| s + (v - icpt - slope * u).powf(2.0)) / (a.len() - 2) as f64;
    (slope, icpt, s2.sqrt(), (s2 / sxx).sqrt())
}

fn acf(x: &[f64], k: usize) -> (f64, f64, Vec<f64>) { // road two: sample autocorrelations
    let m = mean(x);
    let g: Vec<f64> = (0..=k).map(|h| (h..x.len())
        .fold(0.0, |s, t| s + (x[t] - m) * (x[t - h] - m)) / x.len() as f64).collect();
    (m, g[0], g.iter().map(|gh| gh / g[0]).collect())
}
fn top_root(p1: f64, p2: f64) -> f64 {       // largest |lambda| with lambda^2 = p1 lambda + p2
    let d = p1 * p1 + 4.0 * p2;
    if d >= 0.0 { (p1.abs() + d.sqrt()) / 2.0 } else { (-p2).sqrt() }
}
fn triangle(p1: f64, p2: f64) -> bool { p1 + p2 < 1.0 && p2 - p1 < 1.0 && p2.abs() < 1.0 }
fn row(label: &str, vals: &[f64], dp: usize) {
    let body: Vec<String> = vals.iter().map(|v| format!("{:.*}", dp, v)).collect();
    println!("{:<36}{}", label, body.join(" "));
}

fn fm(h: usize) -> f64 { mu() + PHI.powf(h as f64) * (X_NOW - mu()) }
fn fs(h: usize) -> f64 { SIG * ((1.0 - PHI.powf(2.0 * h as f64)) / (1.0 - PHI.powf(2.0))).sqrt() }

fn main() {
    let (sd, nf) = (var().sqrt(), N as f64);
    let (mut lo, mut hi) = (0.0f64, 5.0f64);     // the 95% point: bisect Phi(z) = 0.975
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if cdf(mid) < 0.975 { lo = mid } else { hi = mid }
    }
    let z95 = (lo + hi) / 2.0;
    let tail = SIG.powf(2.0) * (0..200).fold(0.0, |s, j| s + PHI.powf(2.0 * j as f64));
    row("model phi, c, sigma, z95", &[PHI, C, SIG, z95], 6);
    row("mean c/(1-phi), var, sd", &[mu(), var(), sd], 4);
    row("variance, 200 weights summed", &[tail], 4);
    row("hand: 1-phi,phi^2,1-phi^2,sig^2,gap", &[1.0 - PHI, PHI.powf(2.0), 1.0 - PHI.powf(2.0), SIG.powf(2.0), X_NOW - mu()], 4);
    row("hand: phi^h x gap h=1,2,10; phi^10", &[PHI * 4.0, PHI.powf(2.0) * 4.0, PHI.powf(10.0) * 4.0, PHI.powf(10.0)], 4);
    row("hand: 1+phi^2, var h=2", &[1.0 + PHI.powf(2.0), SIG.powf(2.0) * (1.0 + PHI.powf(2.0))], 4);
    let mut rng = Rng(2026);
    let (x, eps) = year(&mut rng);
    row("chart, AR(1) days 1-15", &x[0..15], 2);
    row("chart, AR(1) days 16-30", &x[15..30], 2);
    let alone: Vec<f64> = eps[0..30].iter().map(|e| mu() + e).collect();
    row("chart, shocks alone days 1-15", &alone[0..15], 2);
    row("chart, shocks alone days 16-30", &alone[15..30], 2);
    let (b, a, s, se) = ls_ar1(&x);
    let (m, g0, r) = acf(&x, 5);
    row("LS fit phi, c, sigma, se(phi)", &[b, a, s, se], 4);
    row("YW fit phi = r1, c = m(1-r1)", &[r[1], m * (1.0 - r[1])], 4);
    row("se formula sqrt((1-phi^2)/n)", &[((1.0 - PHI.powf(2.0)) / nf).sqrt()], 4);
    row("record mean, variance, se(mean)", &[m, g0, SIG / (1.0 - PHI) / nf.sqrt()], 4);
    row("acf lags 1-5, record", &r[1..], 3);
    let theory: Vec<f64> = (1..6).map(|h| PHI.powf(h as f64)).collect();
    row("acf lags 1-5, phi^h", &theory, 3);
    let y: Vec<f64> = x.iter().map(|v| v - m).collect();
    let big_s = |i: usize, j: usize| (2..N).fold(0.0, |acc, t| acc + y[t - i] * y[t - j]);
    let (s11, s12, s22, s01, s02) = (big_s(1, 1), big_s(1, 2), big_s(2, 2), big_s(0, 1), big_s(0, 2));
    let det = s11 * s22 - s12.powf(2.0);
    let (p1, p2) = ((s01 * s22 - s02 * s12) / det, (s02 * s11 - s01 * s12) / det);
    let res = (2..N).fold(0.0, |acc, t| acc + (y[t] - p1 * y[t - 1] - p2 * y[t - 2]).powf(2.0)) / (N - 5) as f64;
    let se2 = (res * s11 / det).sqrt();
    let den = 1.0 - r[1].powf(2.0);
    let (q1, q2) = (r[1] * (1.0 - r[2]) / den, (r[2] - r[1].powf(2.0)) / den);
    row("AR(2) LS phi1, phi2, se(phi2)", &[p1, p2, se2], 4);
    row("AR(2) YW phi1, phi2", &[q1, q2], 4);
    let (h1, h2) = ((r[1] * 1e3).round() / 1e3, (r[2] * 1e3).round() / 1e3); // Step 6 by hand, three-place r(1), r(2)
    row("hand: AR(2) YW 3dp; 1-r1^2; 2/sqrtn", &[h1 * (1.0 - h2) / (1.0 - h1.powf(2.0)), (h2 - h1.powf(2.0)) / (1.0 - h1.powf(2.0)), 1.0 - h1.powf(2.0), sd / nf.sqrt()], 4);
    println!("{:<36}{:.4} {}", "AR(2) fit: top |root|, in triangle", top_root(p1, p2),
             if triangle(p1, p2) { "yes" } else { "no" });
    let (mut fits, mut ends) = (Vec::new(), Vec::new());
    for _ in 0..YEARS {                      // road three: 2000 simulated years
        let (xs, es) = year(&mut rng);
        fits.push(ls_ar1(&xs).0);
        ends.push(es.iter().fold(0.0, |acc, e| acc + e)); // a random walk fed the same shocks
    }
    let mf = mean(&fits);
    let sf = (fits.iter().fold(0.0, |acc, f| acc + (f - mf).powf(2.0)) / (YEARS - 1) as f64).sqrt();
    let rw = (ends.iter().fold(0.0, |acc, e| acc + e * e) / YEARS as f64).sqrt();
    row("2000 years: mean phi_hat, sd", &[mf, sf], 4);
    row("theory: phi-(1+3phi)/n, se", &[PHI - (1.0 + 3.0 * PHI) / nf, ((1.0 - PHI.powf(2.0)) / nf).sqrt()], 4);
    row("random walk sd day 365: sim, rule", &[rw, nf.sqrt() * SIG], 2);
    let hs = [1usize, 2, 3, 5, 10];
    let mut got: Vec<Vec<f64>> = vec![Vec::new(); 11];
    for _ in 0..PATHS {                      // forecast paths from +4.5 today
        let mut v = X_NOW;
        for h in 1..=10 {
            v = C + PHI * v + SIG * rng.gauss();
            if hs.contains(&h) { got[h].push(v) }
        }
    }
    println!("h   mean    sd      lower   upper  | sim mean  sim sd  inside band");
    let pf = PATHS as f64;
    for &h in &hs {
        let (g, mm) = (&got[h], mean(&got[h]));
        let ss = (g.iter().fold(0.0, |acc, v| acc + (v - mm).powf(2.0)) / (pf - 1.0)).sqrt();
        let cov = g.iter().filter(|v| (*v - fm(h)).abs() <= z95 * fs(h)).count() as f64 / pf;
        println!("{:<3} {:<7.3} {:<7.3} {:<7.3} {:<6.3} | {:<9.3} {:<7.3} {:.4}",
                 h, fm(h), fs(h), fm(h) - z95 * fs(h), fm(h) + z95 * fs(h), mm, ss, cov);
        assert!((mm - fm(h)).abs() < 4.0 * fs(h) / pf.sqrt());
        assert!((ss - fs(h)).abs() < 4.0 * fs(h) / (2.0 * pf).sqrt());
        assert!((cov - 0.95).abs() < 4.0 * (0.95 * 0.05 / pf).sqrt());
    }
    row("chart, forecast h 0-10", &(0..11).map(fm).collect::<Vec<f64>>(), 2);
    row("chart, lower 95% h 0-10", &(0..11).map(|h| fm(h) - z95 * fs(h)).collect::<Vec<f64>>(), 2);
    row("chart, upper 95% h 0-10", &(0..11).map(|h| fm(h) + z95 * fs(h)).collect::<Vec<f64>>(), 2);
    let mut psi = vec![1.0, 0.5];            // a shock's echo in AR(2) with 0.5 and 0.6
    for j in 2..51 { let next = 0.5 * psi[j - 1] + 0.6 * psi[j - 2]; psi.push(next) }
    row("wrong: 0.5,0.6 root, ratio, echo 50", &[top_root(0.5, 0.6), psi[50] / psi[49], psi[50]], 4);
    row("wrong: 30-day forecast toward c", &[C, fm(30)], 4);
    row("wrong: h=1 half-band stationary sd", &[z95 * sd, z95 * fs(1)], 4);
    assert!((b - r[1]).abs() < 0.02 && (q2 - p2).abs() < 0.02);     // two estimators, one record
    assert!((b - PHI).abs() < 4.0 * se && (tail - var()).abs() < 1e-9);
    assert!((s - SIG).abs() < 4.0 * SIG / (2.0 * (N - 1) as f64).sqrt()); // residual spread recovers the shock's 1.2
    assert!((mf - (PHI - (1.0 + 3.0 * PHI) / nf)).abs() < 4.0 * sf / (YEARS as f64).sqrt());
    assert!((rw - nf.sqrt() * SIG).abs() < 4.0 * nf.sqrt() * SIG / (2.0 * YEARS as f64).sqrt());
    assert!((z95 - 1.959964).abs() < 1e-6 && (psi[50] / psi[49] - top_root(0.5, 0.6)).abs() < 1e-6);
    assert!(triangle(p1, p2) == (top_root(p1, p2) < 1.0) && triangle(0.5, 0.6) == (top_root(0.5, 0.6) < 1.0));
    println!("ALL CHECKS PASS");
}
