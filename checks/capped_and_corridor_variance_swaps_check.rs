// Capped and corridor variance swaps -- the check behind the card. std only.
use std::f64::consts::PI;
const S: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02; const SIG: f64 = 0.20; const T: f64 = 1.0;
fn fwd() -> f64 { S * ((R - Q) * T).exp() } fn growth() -> f64 { (R * T).exp() }
fn n(x: f64) -> f64 { // normal CDF from the erf series that converges everywhere
    let z = x.abs() / 2f64.sqrt();
    let (mut term, mut total, mut k) = (z, z, 0.0);
    while z <= 9.0 && term > 1e-17 * total {
        k += 1.0;
        term *= 2.0 * z * z / (2.0 * k + 1.0);
        total += term;
    }
    let e = if z > 9.0 { 1.0 } else { 2.0 / PI.sqrt() * (-z * z).exp() * total };
    if x >= 0.0 { 0.5 * (1.0 + e) } else { 0.5 * (1.0 - e) }
}
fn bs(k: f64) -> (f64, f64) { // Black-Scholes call and put on Acme with the house r, q, T
    let sd = SIG * T.sqrt();
    let d1 = ((S / k).ln() + (R - Q + 0.5 * SIG * SIG) * T) / sd;
    (S * (-Q * T).exp() * n(d1) - k * (-R * T).exp() * n(d1 - sd),
     k * (-R * T).exp() * n(sd - d1) - S * (-Q * T).exp() * n(-d1))
}
fn otm(k: f64) -> f64 { let (c, p) = bs(k); if k < fwd() { p } else { c } }
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, m: usize) -> f64 {
    let h = (b - a) / m as f64;
    h / 3.0 * (f(a) + f(b) + (1..m).map(|i| (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h)).sum::<f64>())
}
fn strip(lo: f64, hi: f64, calls_only: bool) -> f64 { // road 1: the 1/K^2 strip on strikes lo..hi only
    let lf = fwd().ln();
    let g = |k: f64| { let (c, p) = bs(k.exp()); (if calls_only || k >= lf { c } else { p }) / k.exp() };
    let cuts = if lo < fwd() && fwd() < hi && !calls_only { vec![lo.ln(), lf, hi.ln()] } else { vec![lo.ln(), hi.ln()] };
    2.0 * growth() / T * cuts.windows(2).map(|w| simpson(&g, w[0], w[1], 2000)).sum::<f64>()
}
fn occupancy(lo: f64, hi: f64, on_share: bool) -> f64 { // road 2: sigma^2 times average chance inside
    let p = |u: f64| { // time t = u^2
        let (t, sh) = (u * u, if on_share { (R - Q) * (T - u * u) } else { 0.0 });
        let (sd, mu) = (SIG * t.sqrt(), fwd().ln() - 0.5 * SIG * SIG * t);
        2.0 * u * (n((hi.ln() + sh - mu) / sd) - n((lo.ln() + sh - mu) / sd))
    };
    SIG * SIG * simpson(&p, 1e-9, T.sqrt(), 400) / T
}
fn black_var(m: f64, c: f64, w: f64) -> f64 { // call on lognormal realised variance
    let d1 = ((m / c).ln() + 0.5 * w * w) / w;
    m * n(d1) - c * n(d1 - w)
}
fn simpson_var(m: f64, c: f64, w: f64) -> f64 {
    let f = |z: f64| (m * (w * z - 0.5 * w * w).exp() - c) * (-0.5 * z * z).exp() / (2.0 * PI).sqrt();
    simpson(&f, ((c / m).ln() + 0.5 * w * w) / w, 12.0, 4000)
}
struct Rng(u64);
impl Rng {
    fn u01(&mut self) -> f64 { // splitmix64
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 2f64.powi(53)
    }
    fn gauss(&mut self) -> f64 { let a = self.u01(); let b = self.u01(); (-2.0 * a.ln()).sqrt() * (2.0 * PI * b).cos() }
}
fn mean_se(a: &[f64]) -> (f64, f64) {
    let m = a.iter().sum::<f64>() / a.len() as f64;
    (m, (a.iter().map(|x| (x - m).powi(2)).sum::<f64>() / (a.len() - 1) as f64 / a.len() as f64).sqrt())
}
fn clamp(x: f64, lo: f64, hi: f64) -> f64 { x.max(lo).min(hi) }
fn gfun(x: f64, lo: f64, hi: f64) -> f64 { // corridor log contract: curvature 2/x^2 inside, flat at F
    let j = |y: f64| if y < lo { (y - lo) / lo } else if y <= hi { (y / lo).ln() } else { (hi / lo).ln() + (y - hi) / hi };
    2.0 * ((x - fwd()) / clamp(fwd(), lo, hi) - (j(x) - j(fwd())))
}
fn gslope(x: f64, lo: f64, hi: f64) -> f64 { 2.0 * (1.0 / clamp(fwd(), lo, hi) - 1.0 / clamp(x, lo, hi)) }
fn simulate(rng: &mut Rng, paths: usize, days: usize) -> Vec<Vec<f64>> { // road 3: corridor variance and hedge
    let books = [(80.0, 120.0), (1e-9, fwd())];
    let dt = T / days as f64;
    let mut out = vec![Vec::new(); 6];
    for _ in 0..paths {
        let (mut f, mut cv, mut pl, mut cs, mut rv) = (fwd(), [0.0; 2], [0.0; 2], 0.0, 0.0);
        for i in 0..days {
            let y = -0.5 * SIG * SIG * dt + SIG * dt.sqrt() * rng.gauss();
            let x2 = (y + (R - Q) * dt).powi(2) / T;
            rv += x2;
            for (j, &(lo, hi)) in books.iter().enumerate() {
                cv[j] += if lo <= f && f <= hi { x2 } else { 0.0 };
                pl[j] -= gslope(f, lo, hi) * (f * y.exp() - f);
            }
            let s_prev = f * (-(R - Q) * (T - i as f64 * dt)).exp();
            cs += if 80.0 <= s_prev && s_prev <= 120.0 { x2 } else { 0.0 };
            f *= y.exp();
        }
        for (j, &(lo, hi)) in books.iter().enumerate() {
            out[2 * j].push(cv[j]);
            out[2 * j + 1].push((gfun(f, lo, hi) + pl[j]) / T);
        }
        out[4].push(cs - cv[0]);
        out[5].push(rv);
    }
    out
}
fn simulate_cap(rng: &mut Rng, paths: usize, m: f64, w: f64, c: f64, days: usize) -> (f64, f64, f64, f64) {
    let dt = T / days as f64;
    let mut rvs = Vec::new();
    for _ in 0..paths {
        let v = (m * (w * rng.gauss() - 0.5 * w * w).exp()).sqrt();
        rvs.push((0..days).map(|_| (-0.5 * v * v * dt + v * dt.sqrt() * rng.gauss() + (R - Q) * dt).powi(2)).sum::<f64>() / T);
    }
    let (a, b) = (mean_se(&rvs.iter().map(|&x| x.min(c)).collect::<Vec<_>>()), mean_se(&rvs.iter().map(|&x| (x - c).max(0.0)).collect::<Vec<_>>()));
    (a.0, a.1, b.0, b.1)
}
fn out(name: &str, v: &[f64]) { println!("{:<52}{}", name, v.iter().map(|x| format!("{:>11.6}", x)).collect::<String>()); }
fn row(name: &str, v: &[f64], p: usize) { println!("{:<18}{}", name, v.iter().map(|x| format!("{:>8.*}", p, x)).collect::<String>()); }
fn main() {
    let f = fwd();
    let (l, u, w, cap) = (80.0, 120.0, 0.8, 2.5f64.powi(2) * 0.04);
    let plain = strip(f * (-4.0f64).exp(), f * 4.0f64.exp(), false);
    let (corr, corr_occ) = (strip(l, u, false), occupancy(l, u, false));
    let (down, down_occ) = (strip(f * (-4.0f64).exp(), f, false), occupancy(1e-9, f, false));
    let (up, shift) = (strip(f, f * 4.0f64.exp(), false), occupancy(l, u, true) - occupancy(l, u, false));
    let mut rng = Rng(0x2545F4914F6CDD1D);
    let sim = simulate(&mut rng, 4000, 252);
    let ((c_m, c_se), (d_m, d_se), (sh_m, sh_se)) = (mean_se(&sim[0]), mean_se(&sim[2]), mean_se(&sim[4]));
    let gap = |k: usize| sim[k].iter().zip(&sim[k + 1]).map(|(a, b)| (a - b).abs()).fold(0.0, f64::max);
    let gaps = [gap(0), gap(2)];
    let above = sim[5].iter().filter(|&&x| x > cap).count() as f64;
    let (c20, c20s, c60, c60s) = (black_var(0.04, cap, w), simpson_var(0.04, cap, w), black_var(0.36, cap, w), simpson_var(0.36, cap, w));
    let mut kc = 0.04;
    for _ in 0..60 { kc = 0.04 - black_var(0.04, 6.25 * kc, w); } // cap = 2.5^2 times the capped strike itself
    let (s20, s20e, t20, t20e) = simulate_cap(&mut rng, 4000, 0.04, w, cap, 252);
    let (s60, s60e, t60, t60e) = simulate_cap(&mut rng, 4000, 0.36, w, cap, 252);
    let ks = [85.0, 95.0, 105.0, 115.0];
    let hand: Vec<f64> = ks.iter().map(|&k| 10.0 / (k * k) * otm(k)).collect();
    let hs: f64 = hand.iter().sum();
    out("forward F", &[f]);
    out("plain strip, fair variance", &[plain]);
    out("corridor 80-120: strip, occupation, sim, se", &[corr, corr_occ, c_m, c_se]);
    out("  worst path gap; as a vol, percent; share of plain", &[gaps[0], 100.0 * corr.sqrt(), corr / plain]);
    out("down variance: strip, occupation, sim, se", &[down, down_occ, d_m, d_se]);
    out("  worst path gap; up variance; down + up", &[gaps[1], up, down + up]);
    out("cap; constant 20%: years above it", &[cap, above]);
    out("at 20: call on variance, Simpson, sim, se", &[c20, c20s, t20, t20e]);
    out("  capped strike, sim, se; as a vol", &[0.04 - c20, s20, s20e, 100.0 * (0.04 - c20).sqrt()]);
    let d1 = ((0.04 / cap).ln() + 0.5 * w * w) / w;
    out("  d1, d2, N(d1), N(d2)", &[d1, d1 - w, n(d1), n(d1 - w)]);
    out("  cap set off the capped strike itself", &[kc]);
    out("at 60: call on variance, Simpson, sim, se", &[c60, c60s, t60, t60e]);
    out("  capped strike, sim, se", &[0.36 - c60, s60, s60e]);
    out("by hand: P85, P95, C105, C115", &ks.iter().map(|&k| otm(k)).collect::<Vec<_>>());
    out("  each times 10/K^2", &hand);
    out("  sum; 2 e^rT / T; product", &[hs, 2.0 * growth() / T, 2.0 * growth() / T * hs]);
    out("wrong: calls across the corridor", &[strip(l, u, true)]);
    out("share-price corridor less forward: formula, sim, se", &[shift, sh_m, sh_se]);
    out("try: corridor 90-110; w = 1.2 capped strike", &[strip(90.0, 110.0, false), 0.04 - black_var(0.04, cap, 1.2)]);
    let bands: Vec<f64> = (0..11).map(|i| 50.0 + 10.0 * i as f64).collect();
    println!("{:<18}{}", "strike band x1000", bands.iter().map(|a| format!("{:>4.0}-{:<3.0}", a, a + 10.0)).collect::<String>());
    row("  contribution", &bands.iter().map(|&a| 1000.0 * strip(a, a + 10.0, false)).collect::<Vec<_>>(), 2);
    let mv = [20.0, 30.0, 40.0, 50.0, 60.0];
    row("market vol, pct", &mv, 0);
    row("  plain strike", &mv.iter().map(|v| v * v / 1e4).collect::<Vec<_>>(), 4);
    row("  capped strike", &mv.iter().map(|v| v * v / 1e4 - black_var(v * v / 1e4, cap, w)).collect::<Vec<_>>(), 4);
    let rvol = [10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0];
    row("realised vol", &rvol, 0);
    row("  plain, $000", &rvol.iter().map(|v| 2.5 * (v * v - 400.0)).collect::<Vec<_>>(), 1);
    row("  capped, $000", &rvol.iter().map(|v| 2.5 * ((v * v).min(2500.0) - 1e4 * (0.04 - c20))).collect::<Vec<_>>(), 2);
    assert!((plain - SIG * SIG).abs() < 1e-9, "the full strip returns the flat surface's variance");
    assert!((corr - corr_occ).abs() < 1e-6 && (down - down_occ).abs() < 1e-6, "restricted strip = variance x time inside");
    assert!((c_m - corr).abs() < 4.0 * c_se && (d_m - down).abs() < 4.0 * d_se, "simulated corridor variance averages to the strip");
    assert!(gaps[0] < 0.006 && gaps[1] < 0.006, "the corridor hedge tracks corridor variance path by path");
    assert!((sh_m - shift).abs() < 4.0 * sh_se + 1e-5, "the share-price corridor shift matches its formula");
    assert!((c20 - c20s).abs() < 1e-8 && (c60 - c60s).abs() < 1e-8, "Black on variance = direct integral");
    assert!((t20 - c20).abs() < 4.0 * t20e + 2e-5 && (t60 - c60).abs() < 4.0 * t60e + 2e-3, "simulated cap value agrees");
    assert!((s60 - (0.36 - c60)).abs() < 4.0 * s60e + 2e-3, "capped strike = plain minus the call");
    assert!(above == 0.0, "with no volatility of variance the cap never binds");
    println!("ALL CHECKS PASS");
}
