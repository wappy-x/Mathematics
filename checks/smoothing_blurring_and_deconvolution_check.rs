// Blurring and unblurring -- the same check as the Python, in Rust.  No crates.
// One 64-pixel row of a shaken photo: sky 200, lamp post 40, power wire 60.  The
// shake spreads each point into a bell of standard deviation 2 pixels.  The photo
// is stored as whole grey levels.  Road 1 divides frequency by frequency, with
// and without damping; road 2 solves the same equations pixel by pixel.
use std::f64::consts::PI;
const N: usize = 64;
const SIG: f64 = 2.0;
#[derive(Clone, Copy)]
struct Cx { re: f64, im: f64 }                   // a complex number
fn tot(xs: &[f64]) -> f64 { let mut s = 0.0; for v in xs { s += *v; } s }
fn kernel(sd: f64) -> Vec<f64> {
    let w: Vec<f64> = (0..N).map(|n| { let d = n.min(N - n) as f64; (-(d * d) / (2.0 * sd * sd)).exp() }).collect();
    let t = tot(&w); w.iter().map(|v| v / t).collect()
}
struct Tw { c: Vec<f64>, s: Vec<f64> }
impl Tw {
    fn dft(&self, x: &[Cx]) -> Vec<Cx> {         // X[k] = sum x[n] e^(-2 pi i k n / N)
        (0..N).map(|k| {
            let re: Vec<f64> = (0..N).map(|n| x[n].re * self.c[k * n % N] + x[n].im * self.s[k * n % N]).collect();
            let im: Vec<f64> = (0..N).map(|n| x[n].im * self.c[k * n % N] - x[n].re * self.s[k * n % N]).collect();
            Cx { re: tot(&re), im: tot(&im) } }).collect()
    }
    fn idft(&self, x: &[Cx]) -> Vec<f64> {
        let c: Vec<Cx> = x.iter().map(|z| Cx { re: z.re, im: -z.im }).collect();
        self.dft(&c).iter().map(|z| z.re / N as f64).collect()
    }
    fn damped(&self, y: &[Cx], h: &[Cx], lam: f64) -> Vec<f64> {   // conj(h-hat) y-hat / (|h-hat|^2 + lam)
        let q: Vec<Cx> = (0..N).map(|k| { let d = h[k].re * h[k].re + h[k].im * h[k].im + lam;
            Cx { re: (h[k].re * y[k].re + h[k].im * y[k].im) / d, im: (h[k].re * y[k].im - h[k].im * y[k].re) / d } }).collect();
        self.idft(&q)
    }
}
fn cx(v: &[f64]) -> Vec<Cx> { v.iter().map(|&r| Cx { re: r, im: 0.0 }).collect() }
fn conv(a: &[f64], b: &[f64]) -> Vec<f64> {
    (0..N).map(|k| { let t: Vec<f64> = (0..N).map(|m| a[m] * b[(k + N - m) % N]).collect(); tot(&t) }).collect()
}
fn sci(x: f64) -> String {
    let e = x.abs().log10().floor() as i32;
    let m = format!("{:.3}", x / 10f64.powf(e as f64));
    if m.parse::<f64>().unwrap().abs() < 10.0 { format!("{}e{}", m, e) } else { format!("{:.3}e{}", x / 10f64.powf((e + 1) as f64), e + 1) }
}
fn under(x: f64, b: &str) -> String { if x < b.parse::<f64>().unwrap() { format!("under {}", b) } else { sci(x) } }
fn fx(x: f64) -> String { if x.abs() >= 0.005 { format!("{:.2}", x + 0.0) } else { "0.00".to_string() } }
fn join(v: &[String]) -> String { v.join(", ") }
fn mn(v: &[f64]) -> f64 { v.iter().cloned().fold(f64::INFINITY, f64::min) }
fn mx(v: &[f64]) -> f64 { v.iter().cloned().fold(f64::NEG_INFINITY, f64::max) }
fn solve(a: &[Vec<f64>], b: &[f64]) -> Vec<f64> {      // Gaussian elimination, partial pivoting
    let mut a: Vec<Vec<f64>> = a.iter().enumerate().map(|(i, r)| { let mut r = r.clone(); r.push(b[i]); r }).collect();
    for c in 0..N {
        let mut p = c;
        for r in c..N { if a[r][c].abs() > a[p][c].abs() { p = r; } }
        a.swap(c, p);
        for r in c + 1..N { let q = a[r][c] / a[c][c]; for j in 0..=N { a[r][j] = a[r][j] - q * a[c][j]; } }
    }
    let mut x = vec![0.0; N];
    for r in (0..N).rev() { let t: Vec<f64> = (r + 1..N).map(|j| a[r][j] * x[j]).collect(); x[r] = (a[r][N] - tot(&t)) / a[r][r]; }
    x
}
fn main() {
    let mut f = vec![200.0; N];                      // the true row, illustrative
    for k in 28..36 { f[k] = 40.0; }                 // lamp post, 8 pixels wide
    for k in [44, 45] { f[k] = 60.0; }               // power wire, 2 pixels wide
    let rms = |a: &[f64]| { let t: Vec<f64> = (0..N).map(|i| (a[i] - f[i]) * (a[i] - f[i])).collect(); (tot(&t) / N as f64).sqrt() };
    let h = kernel(SIG);
    let tw = Tw { c: (0..N).map(|m| (2.0 * PI * m as f64 / N as f64).cos()).collect(), s: (0..N).map(|m| (2.0 * PI * m as f64 / N as f64).sin()).collect() };
    let blur = conv(&f, &h);
    let y: Vec<f64> = blur.iter().map(|v| v.round_ties_even()).collect();
    let (hh, yh) = (tw.dft(&cx(&h)), tw.dft(&cx(&y)));
    println!("kernel: area {:.6}, sd {:.1} px, full width at half maximum {:.3} sd = {:.2} px", tot(&h), SIG, 2.0 * (2.0 * 2f64.ln()).sqrt(), 2.0 * (2.0 * 2f64.ln()).sqrt() * SIG);
    let ks: Vec<usize> = (0..33).step_by(4).collect();
    println!("chart, xi = k/64 at k = 0, 4, ..., 32: {}", join(&ks.iter().map(|&k| format!("{:.4}", k as f64 / N as f64)).collect::<Vec<_>>()));
    println!("h-hat by the DFT: {}", join(&ks.iter().map(|&k| sci(hh[k].re)).collect::<Vec<_>>()));
    let gauss = |xi: f64| (-2.0 * PI * PI * SIG * SIG * xi * xi).exp();
    println!("h-hat closed form exp(-2 pi^2 sd^2 xi^2): {}", join(&ks.iter().map(|&k| sci(gauss(k as f64 / N as f64))).collect::<Vec<_>>()));
    let (gq, gn) = ((hh[16].re - gauss(0.25)).abs(), (hh[32].re - gauss(0.5) - gauss(-0.5)).abs());
    println!("gap at xi = 1/4: {}; at xi = 1/2 the DFT is {}, twice the closed form: the alias at -1/2 adds {}, gap {}",
             under(gq, "1e-15"), sci(hh[32].re), sci(gauss(-0.5)), under(gn, "1e-15"));
    let noise: Vec<f64> = (0..N).map(|i| y[i] - blur[i]).collect();
    let nn: Vec<f64> = noise.iter().map(|v| v * v).collect();
    println!("photo: rounding error, largest {:.3}, rms {:.3} grey levels", mx(&noise.iter().map(|v| v.abs()).collect::<Vec<_>>()), (tot(&nn) / N as f64).sqrt());
    let ints = |v: &[f64]| join(&v.iter().map(|x| format!("{:.0}", x)).collect::<Vec<_>>());
    println!("chart, pixels 20 to 52, true: {}", ints(&f[20..53]));
    println!("chart, the photo: {}", ints(&y[20..53]));
    let exact = tw.damped(&tw.dft(&cx(&blur)), &hh, 0.0);
    let naive = tw.damped(&yh, &hh, 0.0);
    println!("plain division, unrounded blur: rms error {} grey levels", under(rms(&exact), "0.0001"));
    println!("plain division, the photo: rms error {:.0}, pixels from {:.0} to {:.0}", rms(&naive), mn(&naive), mx(&naive));
    let e = tw.dft(&cx(&noise));
    let sq = |z: Cx| z.re * z.re + z.im * z.im;
    let terms: Vec<f64> = (0..N).map(|k| sq(e[k]) / sq(hh[k])).collect();
    let pars = (tot(&terms) / N as f64 / N as f64).sqrt();
    let mut top = 0;
    for k in 0..N / 2 + 1 { if terms[k] > terms[top] { top = k; } }
    println!("Parseval: rms of noise / h-hat over all 64 frequencies {:.0}; largest term k = {}, where noise {:.4} / h-hat {}", pars, top, sq(e[top]).sqrt() / N as f64, sci(hh[top].re));
    println!("{:>12}{:>11}{:>9}{:>10}{:>8}", "damping lam", "rms error", "darkest", "brightest", "mean");
    println!("{:>12}{:>11.2}{:>9.1}{:>10.1}{:>8.2}", "no repair", rms(&y), mn(&y), mx(&y), tot(&y) / N as f64);
    let mut sweep = vec![0.0; 11];
    for p in 1..11 {
        let est = tw.damped(&yh, &hh, 10f64.powf(-(p as f64))); sweep[p] = rms(&est);
        println!("{:>12}{:>11.2}{:>9.1}{:>10.1}{:>8.2}", format!("1e-{}", p), sweep[p], mn(&est), mx(&est), tot(&est) / N as f64);
    }
    let mut best = 1;
    for p in 1..11 { if sweep[p] < sweep[best] { best = p; } }
    let sharp = tw.damped(&yh, &hh, 1e-4);
    println!("best of the ten: lam = 1e-{}; wire pixel 44 at {:.1} (photo {:.0}, true 60)", best, sharp[44], y[44]);
    println!("chart, sharpened at lam = 1e-4: {}", ints(&sharp[20..53]));
    println!("chart, log10 gain, plain division: {}", join(&ks.iter().map(|&k| fx(-hh[k].re.log10())).collect::<Vec<_>>()));
    let gd = |k: usize, lam: f64| hh[k].re / (hh[k].re * hh[k].re + lam);
    println!("chart, log10 gain, lam = 1e-4: {}", join(&ks.iter().map(|&k| fx(gd(k, 1e-4).log10())).collect::<Vec<_>>()));
    println!("gain at xi = 1/4: plain {:.1}, damped {:.2}; at xi = 1/2: plain {}, damped {}", 1.0 / hh[16].re, gd(16, 1e-4), sci(1.0 / hh[32].re), sci(gd(32, 1e-4)));
    for lam in [1e-4, 1e-8] {
        println!("lam = {}: largest gain over all 64 frequencies {:.2}, bound 1/(2 sqrt(lam)) {:.2}", sci(lam), mx(&(0..N).map(|k| gd(k, lam)).collect::<Vec<_>>()), 1.0 / (2.0 * lam.sqrt()));
    }
    let g: Vec<Vec<f64>> = (0..N).map(|i| (0..N).map(|j| h[(i + N - j) % N]).collect()).collect();   // the blur as a matrix
    let gg: Vec<Vec<f64>> = (0..N).map(|i| (0..N).map(|j| { let t: Vec<f64> = (0..N).map(|k| g[k][i] * g[k][j]).collect(); tot(&t) + if i == j { 1e-4 } else { 0.0 } }).collect()).collect();
    let gy: Vec<f64> = (0..N).map(|i| { let t: Vec<f64> = (0..N).map(|k| g[k][i] * y[k]).collect(); tot(&t) }).collect();
    let xs = solve(&gg, &gy);
    let gap = mx(&(0..N).map(|i| (xs[i] - sharp[i]).abs()).collect::<Vec<_>>());
    println!("road 2, (G^T G + lam I) x = G^T y by elimination at lam = 1e-4: largest gap to road 1 {}", under(gap, "1e-6"));
    let again = conv(&naive, &h);
    let res = mx(&(0..N).map(|i| (again[i] - y[i]).abs()).collect::<Vec<_>>());
    println!("plain-division row blurred again: largest gap to the photo {} grey levels", under(res, "1e-6"));
    let wrong = tw.damped(&yh, &tw.dft(&cx(&kernel(2.5))), 1e-4);
    println!("mistake, shake guessed as sd 2.5 px: rms {:.2}, pixels from {:.0} to {:.0}", rms(&wrong), mn(&wrong), mx(&wrong));
    println!("heat: sd 2 px is heat flow for kappa t = sd^2 / 2 = {:.0} px^2", SIG * SIG / 2.0);
    assert!((hh[16].re - gauss(0.25)).abs() < 1e-12 && (hh[32].re - 2.0 * gauss(0.5)).abs() < 1e-15);
    assert!(rms(&exact) < 1e-3 && rms(&naive) > 1e6 && (pars - rms(&naive)).abs() < 1e-6 * pars);
    assert!(best == 4 && sweep[4] < rms(&y) && rms(&y) < sweep[1] && sweep[8] > 5.0 * sweep[4]);
    assert!([1e-4, 1e-8].iter().all(|&lam| (0..N).all(|k| gd(k, lam) <= 1.0 / (2.0 * lam.sqrt()))));
    assert!(gap < 1e-6 && res < 1e-3 && rms(&wrong) > sweep[4]);
    println!("ALL CHECKS PASS");
}
