// Exponential waiting times -- the check behind the card, std only.
// Help desk: emails arrive at a steady 12 per hour, rate LAM = 0.2 per minute.
// Roads: the closed form exp(-LAM t); thin time slices with chance LAM*d each;
// Simpson integration of the density; and a seeded stream of emails dropped at
// random moments, whose gaps and window counts never use the exponential formula.
const LAM: f64 = 0.2;

fn surv(t: f64) -> f64 { (-LAM * t).exp() }            // road one
fn dens(t: f64) -> f64 { LAM * (-LAM * t).exp() }
fn slices(t: f64, d: f64) -> f64 {                     // road two: t/d slices, chance LAM*d each
    (1.0 - LAM * d).powf((t / d).round())
}
fn simpson<G: Fn(f64) -> f64>(g: G, a: f64, b: f64, n: usize) -> f64 {   // road three
    let w = (b - a) / n as f64;
    let mut total = g(a) + g(b);
    for j in 1..n {
        total += (if j % 2 == 1 { 4.0 } else { 2.0 }) * g(a + j as f64 * w);
    }
    total * w / 3.0
}
struct SplitMix64 { s: u64 }                            // road four: same numbers as Python
impl SplitMix64 {
    fn uniform(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}
fn frac_se(hits: usize, n: usize) -> (f64, f64) {
    let p = hits as f64 / n as f64;
    (p, (p * (1.0 - p) / n as f64).sqrt())
}
fn mean_se(xs: &[f64]) -> (f64, f64) {
    let n = xs.len() as f64;
    let m = xs.iter().sum::<f64>() / n;
    let v = xs.iter().map(|x| (x - m) * (x - m)).sum::<f64>() / (n - 1.0);
    (m, (v / n).sqrt())
}
fn join(v: &[f64]) -> String { v.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(", ") }

fn main() {
    println!("rate {} emails per minute = {:.0} per hour", LAM, LAM * 60.0);
    println!("mean wait 1/rate = {:.4} min; median ln2/rate = {:.4} min", 1.0 / LAM, 2f64.ln() / LAM);
    println!("wait with 0.9 of waits below: -ln(0.1)/rate = {:.4} min", -(0.1f64).ln() / LAM);
    println!("P(T > 5) = {:.4}; P(T > 10) = {:.4}; P(T > 15) = {:.4}", surv(5.0), surv(10.0), surv(15.0));
    println!("P(T <= 1) = {:.4}; P(T <= 5) = {:.4}", 1.0 - surv(1.0), 1.0 - surv(5.0));
    println!("memoryless: P(T > 15 | T > 10) = {:.4} = P(T > 5) = {:.4}", surv(15.0) / surv(10.0), surv(5.0));
    println!("hazard f(t)/S(t) at t = 0, 5, 20: {:.4}, {:.4}, {:.4}",
             dens(0.0) / surv(0.0), dens(5.0) / surv(5.0), dens(20.0) / surv(20.0));
    for d in [1.0f64, 0.1, 0.01, 0.001] {
        println!("slices of {:?} min: P(no email in 10 min) = {:.6}", d, slices(10.0, d));
    }
    println!("closed form exp(-2)                  = {:.6}", surv(10.0));
    let mass = simpson(dens, 0.0, 200.0, 20000);
    let mean = simpson(|t| t * dens(t), 0.0, 200.0, 20000);
    let sq = simpson(|t| t * t * dens(t), 0.0, 200.0, 20000);
    let upto10 = simpson(dens, 0.0, 10.0, 2000);
    println!("Simpson: total area {:.8}; mean {:.8}; E[T^2] {:.8}; variance {:.8}", mass, mean, sq, sq - mean * mean);
    println!("Simpson: standard deviation {:.4} min", (sq - mean * mean).sqrt());
    println!("Simpson: 1 - area up to 10 min = {:.8}", 1.0 - upto10);
    let poisson0 = (-LAM * 10.0).exp();                 // Poisson count with mean 2: chance of zero
    let mut pmf = vec![poisson0];
    for k in 1..7 { let last = pmf[k - 1]; pmf.push(last * (LAM * 10.0) / k as f64); }
    println!("Poisson(2): P(N = 0) = {:.4}, the same event as T > 10", poisson0);

    let mut rng = SplitMix64 { s: 2026 };
    let (k_n, span) = (24000usize, 120000.0f64);        // 24,000 emails at random moments
    let mut times: Vec<f64> = (0..k_n).map(|_| span * rng.uniform()).collect();
    times.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let mut gaps = vec![times[0]];
    for i in 1..k_n { gaps.push(times[i] - times[i - 1]); }
    let (m, se) = mean_se(&gaps);
    println!("simulated, seed 2026: {} emails over {:.0} minutes, {} per minute", k_n, span, k_n as f64 / span);
    println!("simulated: mean gap {:.4} (se {:.4})", m, se);
    let (p10, se10) = frac_se(gaps.iter().filter(|&&g| g > 10.0).count(), k_n);
    println!("simulated: P(gap > 10) = {:.4} (se {:.4})", p10, se10);
    let long: Vec<f64> = gaps.iter().cloned().filter(|&g| g > 10.0).collect();
    let (pc, sec) = frac_se(long.iter().filter(|&&g| g > 15.0).count(), long.len());
    let rests: Vec<f64> = long.iter().map(|g| g - 10.0).collect();
    let (rest, serest) = mean_se(&rests);
    println!("simulated: {} gaps passed 10 min; of those, P(> 15) = {:.4} (se {:.4})", long.len(), pc, sec);
    println!("simulated: mean wait still to come after 10 quiet minutes = {:.4} (se {:.4})", rest, serest);
    let mut counts = vec![0usize; 12000];               // emails in each 10-minute window
    for &x in &times { counts[(x / 10.0) as usize] += 1; }
    let hist: Vec<f64> = (0..7).map(|k| counts.iter().filter(|&&c| c == k).count() as f64 / 12000.0).collect();
    println!("windows: {} of 10 minutes each", counts.len());
    let ks: Vec<String> = (0..7).map(|k| format!("{:6}", k)).collect();
    println!("window counts k:       {}", ks.join(" "));
    let row = |v: &[f64]| v.iter().map(|p| format!("{:6.2}", 100.0 * p)).collect::<Vec<_>>().join(" ");
    println!("Poisson(2) percent:    {}", row(&pmf));
    println!("simulated percent:     {}", row(&hist));
    let grid: Vec<f64> = (0..11).map(|i| 2.0 * i as f64).collect();
    let gs: Vec<String> = grid.iter().map(|t| format!("{}", t)).collect();
    println!("figure, minutes:       {}", gs.join(", "));
    println!("figure, exact %:       {}", join(&grid.iter().map(|&t| 100.0 * surv(t)).collect::<Vec<_>>()));
    println!("figure, slices %:      {}", join(&grid.iter().map(|&t| 100.0 * slices(t, 1.0)).collect::<Vec<_>>()));
    let simp: Vec<f64> = grid.iter().map(|&t| 100.0 * gaps.iter().filter(|&&g| g > t).count() as f64 / k_n as f64).collect();
    println!("figure, simulated %:   {}", join(&simp));
    println!("mistake, rate read as a 12-minute mean wait: P(T > 10) = {:.4}", (-10.0f64 / 12.0).exp());
    println!("mistake, forgetting the condition: P(T > 15) = {:.4}, not {:.4}", surv(15.0), surv(5.0));
    println!("mistake, mean read as median: P(T <= 5) = {:.4}, not 0.5", 1.0 - surv(5.0));
    let (u, fresh) = ((10.0 - 7.0) / (10.0 - 5.0), (10.0 - 2.0) / 10.0);   // a sender who always writes within 10 min
    println!("with memory, uniform wait up to 10 min: P(T > 7 | T > 5) = {:.4}, fresh P(T > 2) = {:.4}", u, fresh);
    assert!((mass - 1.0).abs() < 1e-9 && (mean - 1.0 / LAM).abs() < 1e-8);   // integration vs algebra
    assert!((sq - mean * mean - 1.0 / (LAM * LAM)).abs() < 1e-6);
    assert!(((1.0 - upto10) - poisson0).abs() < 1e-10);                     // integral vs Poisson zero term
    assert!((slices(10.0, 0.001) - surv(10.0)).abs() < 1e-4 && 1e-4 < (slices(10.0, 1.0) - surv(10.0)).abs());
    assert!((p10 - surv(10.0)).abs() < 4.0 * se10 && (pc - surv(5.0)).abs() < 4.0 * sec);   // simulation vs formula
    assert!((m - 1.0 / LAM).abs() < 4.0 * se && (rest - 1.0 / LAM).abs() < 4.0 * serest);
    assert!((0..7).all(|k| (hist[k] - pmf[k]).abs() < 4.0 * (pmf[k] * (1.0 - pmf[k]) / 12000.0).sqrt()));
    println!("ALL CHECKS PASS");
}
