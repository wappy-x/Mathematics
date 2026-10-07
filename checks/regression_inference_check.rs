// Regression error bars -- the same check as the Python, in Rust.  No crates.  A cafe logged
// midday temperature and iced coffees sold on ten summer days.  Roads: the slope's standard error
// from deviations and from the 2x2 matrix inverse; t from the slope and F from dropping the slope;
// t tail areas from a finite series and from Simpson's rule; a seeded simulation (SplitMix64,
// Box-Muller) that refits thousands of cafes and counts coverage.
use std::f64::consts::PI;

const X: [f64; 10] = [16.0, 18.0, 20.0, 22.0, 24.0, 26.0, 28.0, 30.0, 32.0, 34.0];
const Y: [f64; 10] = [37.0, 33.0, 34.0, 31.0, 35.0, 49.0, 40.0, 53.0, 50.0, 38.0];
const N: usize = 10;
const NU: u32 = 8;
const X0: f64 = 30.0;

fn fit(x: &[f64], y: &[f64]) -> (f64, f64, f64, f64, f64) {
    let n = x.len() as f64;
    let mx = x.iter().sum::<f64>() / n;
    let my = y.iter().sum::<f64>() / n;
    let sxx: f64 = x.iter().map(|a| (a - mx).powi(2)).sum();
    let sxy: f64 = x.iter().zip(y).map(|(a, b)| (a - mx) * b).sum();
    let b1 = sxy / sxx;
    let b0 = my - b1 * mx;
    let sse: f64 = x.iter().zip(y).map(|(a, b)| (b - b0 - b1 * a).powi(2)).sum();
    (b0, b1, sse, sxx, mx)
}
fn t_inside(t: f64, v: u32) -> f64 {              // P(|T| <= t), even v: finite series in the angle
    let th = (t / (v as f64).sqrt()).atan();
    let c = th.cos().powi(2);
    let (mut term, mut tot) = (1.0, 1.0);
    for k in 1..(v / 2) {
        term *= c * (2 * k - 1) as f64 / (2 * k) as f64;
        tot += term;
    }
    th.sin() * tot
}
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {
    let m = 2000;
    let h = (b - a) / m as f64;
    let inner: f64 = (1..m).map(|i| (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h)).sum();
    h / 3.0 * (f(a) + f(b) + inner)
}
fn t_dens(t: f64) -> f64 {                         // Gamma(9/2) / (sqrt(8 pi) Gamma(4)), by hand
    let v = 8.0;
    let g = 3.5 * 2.5 * 1.5 * 0.5 * PI.sqrt() / ((v * PI).sqrt() * 6.0);
    g * (1.0 + t * t / v).powf(-(v + 1.0) / 2.0)
}
fn z_dens(z: f64) -> f64 { 2.718281828459045f64.powf(-z * z / 2.0) / (2.0 * PI).sqrt() }
fn bisect(f: &dyn Fn(f64) -> f64, target: f64, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..100 {
        let mid = (lo + hi) / 2.0;
        if f(mid) < target { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}
struct Rng(u64);                                   // SplitMix64, the same stream as the Python
impl Rng {
    fn u01(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53)
    }
    fn gauss(&mut self) -> f64 {                   // Box-Muller, one draw per call
        let mut u = self.u01();
        while u == 0.0 { u = self.u01(); }
        (-2.0 * u.ln()).sqrt() * (2.0 * PI * self.u01()).cos()
    }
}
fn main() {
    let (b0, b1, sse, sxx, mx) = fit(&X, &Y);
    let n = N as f64;
    let s = (sse / NU as f64).sqrt();
    let se1 = s / sxx.sqrt();
    let se0 = s * (1.0 / n + mx * mx / sxx).sqrt();
    let sx: f64 = X.iter().sum();                   // road 2: (X'X)^-1 from raw sums, no deviations
    let sxx_raw: f64 = X.iter().map(|a| a * a).sum();
    let det = n * sxx_raw - sx * sx;
    let (g11, g12, g22) = (sxx_raw / det, -sx / det, n / det);
    let t = b1 / se1;
    let ybar = Y.iter().sum::<f64>() / n;
    let syy: f64 = Y.iter().map(|b| (b - ybar).powi(2)).sum();   // road 2 for t: the flat line's SSE
    let f_stat = (syy - sse) / (sse / NU as f64);
    let tq = bisect(&|q| t_inside(q, NU), 0.95, 0.0, 20.0);
    let (p_ser, p_simp) = (1.0 - t_inside(t, NU), 1.0 - 2.0 * simpson(&t_dens, 0.0, t));
    let h = 1.0 / n + (X0 - mx).powi(2) / sxx;
    let h_mat = g11 + 2.0 * X0 * g12 + X0 * X0 * g22;
    let (yhat0, hw_m, hw_p) = (b0 + b1 * X0, tq * s * h.sqrt(), tq * s * (1.0 + h).sqrt());
    let row = |v: &[f64]| v.iter().map(|a| format!("{:>3}", a)).collect::<Vec<_>>().join(" ");
    println!("data, temperature C  {}", row(&X));
    println!("data, iced coffees   {}", row(&Y));
    println!("sums: mean x {:.4}, mean y {:.4}, Sxx {:.4}, Sxy {:.4}, Syy {:.4}", mx, ybar, sxx, b1 * sxx, syy);
    println!("fit: slope {:.4} coffees per degree, intercept {:.4}", b1, b0);
    let res: Vec<String> = X.iter().zip(&Y).map(|(a, b)| format!("{:.1}", b - b0 - b1 * a)).collect();
    println!("residuals {}", res.join(" "));
    println!("SSE {:.4}; s^2 = SSE/8 {:.4}; s {:.4}", sse, s * s, s);
    println!("hand: sqrt(Sxx) {:.4}; weights at 16 and 34 C {:.4} {:.4}; h at 0 C {:.4}", sxx.sqrt(), (16.0 - mx) / sxx, (34.0 - mx) / sxx, 1.0 / n + mx * mx / sxx);
    println!("road 1, SE(slope) = s/sqrt(Sxx)        {:.4}", se1);
    println!("road 2, SE(slope) = s sqrt(G22)        {:.4}", s * g22.sqrt());
    println!("SE(intercept) {:.4}; road 2 {:.4}", se0, s * g11.sqrt());
    println!("road 1, t = slope / SE                 {:.4}; t^2 {:.4}", t, t * t);
    println!("road 2, F = (Syy - SSE) / s^2          {:.4}; Syy - SSE {:.4}", f_stat, syy - sse);
    println!("cutoff t* for 95%, 8 df                {:.4}; Simpson area outside it {:.4}", tq, 1.0 - 2.0 * simpson(&t_dens, 0.0, tq));
    println!("p-value, t on 8 df: series {:.4}; Simpson {:.4}", p_ser, p_simp);
    println!("95% interval for the slope: {:.4} to {:.4} (half-width {:.4})", b1 - tq * se1, b1 + tq * se1, tq * se1);
    println!("at 30 C: fitted {:.4}; h {:.4}; h from the matrix {:.4}", yhat0, h, h_mat);
    println!("mean sales at 30 C: {:.2} to {:.2} (SE {:.4}, half-width {:.2})", yhat0 - hw_m, yhat0 + hw_m, s * h.sqrt(), hw_m);
    println!("one new 30 C day:   {:.2} to {:.2} (SE {:.4}, half-width {:.2})", yhat0 - hw_p, yhat0 + hw_p, s * (1.0 + h).sqrt(), hw_p);
    let (p_z, s_n) = (1.0 - 2.0 * simpson(&z_dens, 0.0, t), (sse / n).sqrt());
    println!("mistake, normal cutoff: p {:.4}; true false-alarm rate of 1.96 on 8 df {:.4}", p_z, 1.0 - t_inside(1.96, NU));
    let tn = b1 / (s_n / sxx.sqrt());
    println!("mistake, SSE/n: s {:.4}, SE {:.4}, t {:.4}, p {:.4}", s_n, s_n / sxx.sqrt(), tn, 1.0 - t_inside(tn, NU));
    let cov_mix = t_inside(tq * (h / (1.0 + h)).sqrt(), NU);
    println!("mistake, mean interval for one new day: closed-form coverage {:.4}", cov_mix);

    let mut rng = Rng(20260928);
    let mut cafes = |slope: f64, rho: f64, m: usize| -> ([f64; 5], f64, f64) {
        let (mut hits, mut sb, mut sb2, mut ss2) = ([0usize; 5], 0.0, 0.0, 0.0);
        for _ in 0..m {
            let mut e = s * rng.gauss();
            let mut errs = vec![e];
            for _ in 0..N - 1 { e = rho * e + s * (1.0 - rho * rho).sqrt() * rng.gauss(); errs.push(e); }
            let y: Vec<f64> = X.iter().zip(&errs).map(|(a, ea)| b0 + slope * a + ea).collect();
            let (c0, c1, cse, _, _) = fit(&X, &y);
            let cs = (cse / NU as f64).sqrt();
            let cse1 = cs / sxx.sqrt();
            let new = b0 + slope * X0 + s * rng.gauss();
            let mid = c0 + c1 * X0;
            sb += c1; sb2 += c1 * c1; ss2 += cs * cs;
            hits[0] += ((c1 - slope).abs() <= tq * cse1) as usize;
            hits[1] += ((c1 - slope).abs() <= 1.96 * cse1) as usize;
            hits[2] += ((mid - (b0 + slope * X0)).abs() <= tq * cs * h.sqrt()) as usize;
            hits[3] += ((mid - new).abs() <= tq * cs * (1.0 + h).sqrt()) as usize;
            hits[4] += ((mid - new).abs() <= tq * cs * h.sqrt()) as usize;
        }
        let mf = m as f64;
        (hits.map(|k| k as f64 / mf), (sb2 / mf - (sb / mf).powi(2)).sqrt(), ss2 / mf)
    };
    let m = 20000usize;
    let mf = m as f64;
    let (rates, sd1, ms2) = cafes(b1, 0.0, m);
    let e = |r: f64| (r * (1.0 - r) / mf).sqrt();
    println!("simulation, {} cafes, seed 20260928, true slope 0.8, s as sigma:", m);
    println!("  spread of fitted slopes {:.4} (+/- {:.4}); formula sigma/sqrt(Sxx) {:.4}", sd1, sd1 / (2.0 * mf).sqrt(), s / sxx.sqrt());
    println!("  average s^2 {:.4} (+/- {:.4}); true sigma^2 {:.4}; average SSE/n {:.4}", ms2, s * s * (2.0 / NU as f64 / mf).sqrt(), s * s, ms2 * NU as f64 / n);
    let names = ["t interval holds the slope", "1.96 interval holds the slope", "mean interval holds the mean",
                 "prediction interval holds the new day", "mean interval holds the new day"];
    for (nm, r) in names.iter().zip(rates.iter()) { println!("  {:<38}{:.4} (+/- {:.4})", nm, r, e(*r)); }
    let (bad, _, _) = cafes(0.0, 0.8, m);
    println!("drop independence: rho 0.8 day to day, true slope 0; t test rejects {:.4} (+/- {:.4}) of cafes", 1.0 - bad[0], e(bad[0]));
    let px = |a: f64| 40.0 + 15.0 * (a - 15.0);
    let py = |v: f64| 200.0 - 3.0 * (v - 10.0);
    let band = |a: f64, one: f64| tq * s * (one + 1.0 / n + (a - mx).powi(2) / sxx).sqrt();
    let pts: Vec<String> = X.iter().zip(&Y).map(|(a, b)| format!("{:.1},{:.1}", px(*a), py(*b))).collect();
    println!("figure, points {}", pts.join(" "));
    println!("figure, fit line {:.1},{:.1} {:.1},{:.1}", px(16.0), py(b0 + b1 * 16.0), px(34.0), py(b0 + b1 * 34.0));
    for (lab, one, sg) in [("mean band upper", 0.0, 1.0), ("mean band lower", 0.0, -1.0), ("prediction upper", 1.0, 1.0), ("prediction lower", 1.0, -1.0)] {
        let v: Vec<String> = X.iter().map(|a| format!("{:.1},{:.1}", px(*a), py(b0 + b1 * a + sg * band(*a, one)))).collect();
        println!("figure, {} {}", lab, v.join(" "));
    }
    assert!((t * t - f_stat).abs() < 1e-9 && (s * g22.sqrt() - se1).abs() < 1e-12);   // two roads to t, to the SE
    assert!((p_ser - p_simp).abs() < 1e-8 && (h - h_mat).abs() < 1e-12);            // series vs Simpson; h two ways
    assert!((b1 - 0.8).abs() < 1e-12 && (sse - 342.8).abs() < 1e-9);                // the hand table's numbers
    assert!((sd1 - s / sxx.sqrt()).abs() < 4.0 * sd1 / (2.0 * mf).sqrt() && (ms2 - s * s).abs() < 4.0 * s * s * (2.0 / NU as f64 / mf).sqrt());
    for (r, want) in rates.iter().zip([0.95, t_inside(1.96, NU), 0.95, 0.95, cov_mix]) { assert!((r - want).abs() < 4.0 * e(want)); }
    assert!(1.0 - bad[0] > 0.05 + 4.0 * e(0.05));                                   // dependence breaks the 5 percent
    println!("ALL CHECKS PASS");
}
