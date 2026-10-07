// Black-Cox first-passage default -- the same check as the Python, in Rust.
// Standard library only, no crates.  Rust has no erf, so the bell-curve area is
// built by adding up thin slices under the curve (Simpson's rule), a different
// route from the Python power series.  The random numbers are the same
// xorshift64* stream, so the simulated counts match the Python run.
use std::f64::consts::PI;

const V0: f64 = 100.0; const D: f64 = 80.0; const T: f64 = 1.0; const R: f64 = 0.05; const SIG: f64 = 0.20;
const NU: f64 = R - 0.5 * SIG * SIG;

fn simpson<F: Fn(f64) -> f64>(f: F, lo: f64, hi: f64, n: usize) -> f64 {
    let h = (hi - lo) / n as f64;
    let mut s = f(lo) + f(hi);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(lo + i as f64 * h); }
    s * h / 3.0
}
fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn n_cdf(x: f64) -> f64 {                                   // area left of x
    if x.abs() > 7.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    0.5 + simpson(phi, 0.0, x, 4000)
}
fn black_cox(h: f64, nu: f64, sig: f64, t: f64) -> (f64, f64, f64) {   // road 1
    let (b, s) = ((h / V0).ln(), sig * t.sqrt());
    let finish = n_cdf((b - nu * t) / s);
    let mirror = (2.0 * nu * b / (sig * sig)).exp() * n_cdf((b + nu * t) / s);
    (finish, mirror, finish + mirror)
}
fn bc(h: f64) -> (f64, f64, f64) { black_cox(h, NU, SIG, T) }
fn by_density(h: f64, nu: f64) -> f64 {                     // road 2: first-touch times
    let b = (h / V0).ln();
    let f = |t: f64| if t == 0.0 { 0.0 } else {
        -b / (SIG * (2.0 * PI * t.powi(3)).sqrt()) * (-(b - nu * t).powi(2) / (2.0 * SIG * SIG * t)).exp() };
    simpson(f, 0.0, T, 4000)
}
fn mirror_by_bridge(h: f64) -> f64 {
    let (b, s) = ((h / V0).ln(), SIG * T.sqrt());
    let g = |y: f64| (-(y - NU * T).powi(2) / (2.0 * s * s)).exp() / (s * (2.0 * PI).sqrt());
    simpson(|y| g(y) * (2.0 * b * (y - b) / (s * s)).exp(), b, b + 12.0 * s, 6000)
}
fn whole_contract(h: f64) -> f64 {                          // touch H, or end below D
    let (b, d, s) = ((h / V0).ln(), (D / V0).ln(), SIG * T.sqrt());
    n_cdf((d - NU * T) / s) + (2.0 * NU * b / (SIG * SIG)).exp() * n_cdf((2.0 * b - d + NU * T) / s)
}
struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 {
        self.0 ^= self.0 >> 12; self.0 ^= self.0 << 25; self.0 ^= self.0 >> 27;
        (self.0.wrapping_mul(0x2545F4914F6CDD1D) >> 11) as f64 / 2f64.powi(53) + 2f64.powi(-54)
    }
}

fn main() {
    const PATHS: usize = 40000; const STEPS: usize = 12;
    let bars = [80.0_f64, 70.0, 60.0];
    let dt = T / STEPS as f64;
    let lb: Vec<f64> = bars.iter().map(|h| (h / V0).ln()).collect();
    let ld = (D / V0).ln();
    let mut rng = Rng(0x2026092843050001);
    let (mut bridge, mut grid, mut whole) = ([0usize; 3], [0usize; 3], [0usize; 3]);
    let (mut qtr, mut end, mut month_hit) = (0usize, 0usize, [0usize; STEPS]);
    for _ in 0..PATHS {
        let (mut x, mut hit, mut seen, mut first, mut q) = (0.0_f64, [false; 3], [false; 3], STEPS, false);
        for k in 0..STEPS {
            let z = (-2.0 * rng.uniform().ln()).sqrt() * (2.0 * PI * rng.uniform()).cos();
            let y = x + NU * dt + SIG * dt.sqrt() * z;
            let u = rng.uniform();
            for j in 0..3 {
                if y <= lb[j] { hit[j] = true; seen[j] = true; }
                else if !hit[j] && u < (-2.0 * (x - lb[j]) * (y - lb[j]) / (SIG * SIG * dt)).exp() { hit[j] = true; }
            }
            q = q || (k % 3 == 2 && y <= lb[0]);
            if hit[0] && first == STEPS { first = k; }
            x = y;
        }
        for j in 0..3 {
            bridge[j] += hit[j] as usize; grid[j] += seen[j] as usize; whole[j] += (hit[j] || x <= ld) as usize;
        }
        qtr += q as usize; end += (x <= lb[0]) as usize;
        if first < STEPS { month_hit[first] += 1; }
    }
    let mc = |c: usize| c as f64 / PATHS as f64;
    let se = |p: f64| (p * (1.0 - p) / PATHS as f64).sqrt();

    let merton = n_cdf(((D / V0).ln() - NU * T) / (SIG * T.sqrt()));
    println!("inputs: V0 {:.0}, D {:.0}, T {:.0}, r {:.2}, sigma {:.2}, nu {:.6}, weight exponent {:.6}", V0, D, T, R, SIG, NU, 2.0 * NU / (SIG * SIG));
    println!("Merton, below 80 at year end        {:.6}", merton);
    println!("barrier   finish    mirror    Black-Cox  by density  bridge MC  monthly MC  whole contract  its MC");
    let mut rows = Vec::new();
    for j in 0..3 {
        let (fin, mir, b) = bc(bars[j]); let dens = by_density(bars[j], NU); rows.push((fin, mir, b, dens));
        println!("{:7.0}  {:.6}  {:.6}  {:.6}   {:.6}    {:.4}     {:.4}      {:.6}    {:.4}",
                 bars[j], fin, mir, b, dens, mc(bridge[j]), mc(grid[j]), whole_contract(bars[j]), mc(whole[j]));
    }
    let wt = (2.0 * NU * lb[0] / (SIG * SIG)).exp();
    let n_beta = n_cdf((lb[0] + NU * T) / SIG);
    println!("H 80: b = ln(H/V0) {:.6}, alpha {:.6}, beta {:.6}", lb[0], (lb[0] - NU * T) / SIG, (lb[0] + NU * T) / SIG);
    println!("weight (H/V0)^(2nu/sigma^2), H 80   {:.6}", wt);
    println!("N((b + nu T)/sigma sqrt T), H 80    {:.6}", n_beta);
    println!("mirror term by bridge integral, 80  {:.6}", mirror_by_bridge(80.0));
    println!("MC {} paths, {} monthly steps; standard error at 0.2224  {:.4}", PATHS, STEPS, se(rows[0].2));
    let shift = 80.0 * (-0.5826 * SIG * dt.sqrt()).exp();
    println!("monitoring at H 80, %: year end formula, year end MC, quarterly MC, monthly MC, monthly by shifted barrier, continuous formula, bridge MC");
    println!("  {:.2}  {:.2}  {:.2}  {:.2}  {:.2}  {:.2}  {:.2}", 100.0 * merton, 100.0 * mc(end), 100.0 * mc(qtr), 100.0 * mc(grid[0]),
             100.0 * bc(shift).2, 100.0 * rows[0].2, 100.0 * mc(bridge[0]));
    println!("  shifted barrier 80 exp(-0.5826 sigma sqrt(1/12))  {:.4}", shift);
    println!("wrong: drop the mirror term         {:.6}", rows[0].0);
    println!("wrong: mirror without the weight    {:.6}", rows[0].0 + n_beta);
    println!("wrong: weight with flipped sign     {:.6}", rows[0].0 + n_beta / wt);
    let hs: Vec<f64> = (0..8).map(|i| 60.0 + 5.0 * i as f64).collect();
    let line = |v: Vec<String>| v.join(" ");
    println!("chart, barrier $m      {}", line(hs.iter().map(|h| format!("{:6.0}", h)).collect()));
    println!("chart, Black-Cox %     {}", line(hs.iter().map(|h| format!("{:6.2}", 100.0 * bc(*h).2)).collect()));
    println!("chart, year-end at H % {}", line(hs.iter().map(|h| format!("{:6.2}", 100.0 * bc(*h).0)).collect()));
    println!("chart, month           {}", line((1..13).map(|m| format!("{:5}", m)).collect()));
    println!("chart, touched by m %  {}", line((1..13).map(|m| format!("{:5.2}", 100.0 * black_cox(80.0, NU, SIG, m as f64 / 12.0).2)).collect()));
    println!("chart, MC touched by m {}", line((1..13).map(|m| format!("{:5.2}", 100.0 * mc(month_hit[..m].iter().sum()))).collect()));
    println!("chart, below 80 at m % {}", line((1..13).map(|m| format!("{:5.2}", 100.0 * black_cox(80.0, NU, SIG, m as f64 / 12.0).0)).collect()));
    let z0 = black_cox(80.0, 0.0, SIG, T);
    println!("try: r 0.02 so nu 0: first-touch density {:.6}, twice finish-below {:.6}", by_density(80.0, 0.0), 2.0 * z0.0);
    println!("try: sigma 0.30: Black-Cox {:.6}, year end {:.6}", black_cox(80.0, 0.005, 0.30, T).2, black_cox(80.0, 0.005, 0.30, T).0);
    println!("try: T 5 years: Black-Cox {:.6}, year-5 end {:.6}", black_cox(80.0, NU, SIG, 5.0).2, black_cox(80.0, NU, SIG, 5.0).0);
    println!("try: real-world drift 8%: Black-Cox {:.6}, year end {:.6}", black_cox(80.0, 0.06, SIG, T).2, black_cox(80.0, 0.06, SIG, T).0);

    assert!((merton - 0.1028).abs() < 5e-5, "the shelf's Merton default chance, 10.28%");
    for row in &rows { assert!((row.2 - row.3).abs() < 1e-8, "reflection formula vs adding up first-touch times"); }
    for j in 0..3 { assert!((mc(bridge[j]) - rows[j].2).abs() < 4.0 * se(rows[j].2) + 1e-3, "bridge-corrected simulation vs formula"); }
    assert!((mirror_by_bridge(80.0) - rows[0].1).abs() < 1e-8, "mirror term vs integral of bridge chances");
    assert!((mc(end) - merton).abs() < 4.0 * se(merton), "simulated year-end check vs Merton");
    assert!(mc(end) < mc(qtr) && mc(qtr) < mc(grid[0]) && mc(grid[0]) < mc(bridge[0]), "more watching finds more defaults");
    assert!((2.0 * z0.0 - by_density(80.0, 0.0)).abs() < 1e-8, "no drift: twice the finish-below chance, by first-touch times");
    println!("ALL CHECKS PASS");
}
