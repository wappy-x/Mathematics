// Poisson process -- the same check in Rust.  No crates.  Calls reach a
// switchboard at 4 an hour.  The process is built from independent exponential
// gaps, and the count in the next quarter hour is reached four ways: the Poisson
// formula; a first-step recursion on the first gap, integrated on a grid; time
// cut into slots of length h, the error printed as h shrinks; and a seeded
// simulation (SplitMix64, seed 20260929).
const LAM: f64 = 4.0;                   // calls per hour
const WIN: f64 = 0.25;                  // the window, hours
const DAY: f64 = 2.0;                   // the plotted span, hours
const RUNS: usize = 200_000;
const KMAX: usize = 5;

struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 {      // SplitMix64, turned into a number in (0, 1]
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) + 1) as f64 / 2f64.powi(53)
    }
    fn gap(&mut self, uniform_gaps: bool) -> f64 {
        if uniform_gaps { 2.0 * self.uniform() / LAM }  // the mistake: uniform on 0 to 2/LAM, same mean
        else { -self.uniform().ln() / LAM }              // exponential gap, by inverse transform
    }
}

fn fact(k: usize) -> f64 { (2..=k).fold(1u64, |f, i| f * i as u64) as f64 }

fn pois(k: usize, m: f64) -> f64 { (-m).exp() * m.powf(k as f64) / fact(k) }   // Road 1

fn by_first_gap(t: f64, kmax: usize, n: usize) -> Vec<f64> {   // Road 2
    let h = t / n as f64;
    let f: Vec<f64> = (0..=n).map(|i| LAM * (-LAM * i as f64 * h).exp()).collect();
    let mut q: Vec<f64> = (0..=n).map(|i| (-LAM * i as f64 * h).exp()).collect();
    let mut out = vec![q[n]];
    for _ in 1..=kmax {
        let mut r = vec![0.0];
        for i in 1..=n {                                 // trapezoid rule over the first gap u
            let mut s = 0.5 * (f[0] * q[i] + f[i] * q[0]);
            for j in 1..i { s += f[j] * q[i - j] }
            r.push(s * h);
        }
        q = r;
        out.push(q[n]);
    }
    out
}

fn by_slots(t: f64, h: f64, k: usize) -> f64 {  // Road 3: one call per slot, chance LAM h
    let (m, p) = ((t / h).round() as u64, LAM * h);
    let mut c: u64 = 1;
    for i in 0..k as u64 { c = c * (m - i) / (i + 1) }
    c as f64 * p.powf(k as f64) * (1.0 - p).powf((m - k as u64) as f64)
}

fn two_windows(g: &mut Rng, u: bool) -> (u64, u64, f64) {   // Road 4
    let (mut t, mut c1, mut c2) = (g.gap(u), 0u64, 0u64);
    while t <= WIN { c1 += 1; t += g.gap(u) }
    let w = t - WIN;                                     // wait from quarter past to the next call
    while t <= 2.0 * WIN { c2 += 1; t += g.gap(u) }
    (c1, c2, w)
}

fn simulate(g: &mut Rng, u: bool) -> (Vec<u64>, f64, f64, f64, f64, f64, f64, f64, f64, f64) {
    let (mut hist, mut both) = (vec![0u64; KMAX + 2], 0u64);
    let (mut s1, mut s2, mut s11, mut s22, mut s12, mut sw, mut sww) = (0u64, 0u64, 0u64, 0u64, 0u64, 0.0, 0.0);
    let (mut s3, mut s4) = (0u64, 0u64);
    for _ in 0..RUNS {
        let (c1, c2, w) = two_windows(g, u);
        hist[(c1 as usize).min(KMAX + 1)] += 1;
        if c1 == 1 && c2 == 2 { both += 1 }
        s1 += c1; s2 += c2; s11 += c1 * c1; s22 += c2 * c2; s12 += c1 * c2;
        s3 += c1 * c1 * c1; s4 += c1 * c1 * c1 * c1;
        sw += w; sww += w * w;
    }
    let n = RUNS as f64;
    let (m1, m2) = (s1 as f64 / n, s2 as f64 / n);
    let (v1, v2, cv) = (s11 as f64 / n - m1 * m1, s22 as f64 / n - m2 * m2, s12 as f64 / n - m1 * m2);
    let (mw, m4) = (sw / n, s4 as f64 / n - 4.0 * m1 * s3 as f64 / n + 6.0 * m1 * m1 * s11 as f64 / n - 3.0 * m1 * m1 * m1 * m1);
    (hist, both as f64 / n, m1, v1, cv / (v1 * v2).sqrt(), (v1 + cv) / (v1 * (v1 + v2 + 2.0 * cv)).sqrt(),
     mw, ((sww / n - mw * mw) / n).sqrt(), (v1 / n).sqrt(), ((m4 - v1 * v1) / n).sqrt())
}

fn se(f: f64) -> f64 { (f * (1.0 - f) / RUNS as f64).sqrt() }

fn join<T>(v: &[T], f: impl Fn(&T) -> String) -> String { v.iter().map(f).collect::<Vec<_>>().join(", ") }

fn main() {
    let mut g = Rng(20260929);
    let (mut path, mut t) = (vec![], g.gap(false));      // one sample path over two hours
    while t <= DAY { path.push(t); t += g.gap(false) }
    let grid: Vec<u64> = (0..41).map(|i| 3 * i).collect();                  // minutes
    let steps: Vec<usize> = grid.iter().map(|&m| path.iter().filter(|&&a| 60.0 * a <= m as f64).count()).collect();

    let exact: Vec<f64> = (0..=KMAX).map(|k| pois(k, LAM * WIN)).collect();
    let rec = by_first_gap(WIN, KMAX, 1000);
    let (hist, both, m1, v1, r12, r1t, mw, sew, sem, sev) = simulate(&mut g, false);
    let (uhist, _, _, _, ur12, _, umw, usew, _, _) = simulate(&mut g, true);
    let freq: Vec<f64> = hist.iter().map(|&c| c as f64 / RUNS as f64).collect();
    let ufreq: Vec<f64> = uhist.iter().map(|&c| c as f64 / RUNS as f64).collect();
    let rse = 1.0 / (RUNS as f64).sqrt();                // standard error of a correlation near 0
    let pu = (1.0 - LAM * WIN / 2.0).max(0.0);           // uniform gaps: exact chance of an empty first window

    println!("rate {:.0} calls an hour; window {} hour; mean count LAM t = {:.4}", LAM, WIN, LAM * WIN);
    println!("calls in the quarter hour: formula, first-gap recursion, simulated +- se");
    for k in 0..=KMAX {
        println!("  {}: {:.6}  {:.6}  {:.4} +- {:.4}", k, exact[k], rec[k], freq[k], se(freq[k]));
    }
    let f4: f64 = freq[4..].iter().sum();
    println!("P(4 or more): formula {:.4}; simulated {:.4} +- {:.4}", 1.0 - exact[..4].iter().sum::<f64>(), f4, se(f4));
    println!("mean and variance of the count, simulated: {:.4} +- {:.4}, {:.4} +- {:.4}", m1, sem, v1, sev);
    let mut errs = vec![];
    for (name, h) in [("1 minute", 1.0 / 60.0), ("10 seconds", 1.0 / 360.0), ("1 second", 1.0 / 3600.0)] {
        errs.push((0..=KMAX).map(|k| (by_slots(WIN, h, k) - exact[k]).abs()).fold(0.0, f64::max));
        println!("slots of {}: P(0) = {:.6}, largest error {:.6}", name, by_slots(WIN, h, 0), errs[errs.len() - 1]);
    }
    println!("wait from quarter past to the next call: {:.2} +- {:.2} minutes (mean gap 15)", 60.0 * mw, 60.0 * sew);
    println!("P(1 call, then 2 calls): formula {:.4}; simulated {:.4} +- {:.4}", exact[1] * exact[2], both, se(both));
    println!("corr(first quarter, second quarter): {:.4} +- {:.4}; formula 0", r12, rse);
    println!("corr(N(0.25), N(0.5)): {:.4} +- {:.4}; formula sqrt(1/2) = {:.4}", r1t, (1.0 - r1t * r1t) * rse, 0.5f64.sqrt());
    println!("P(N(0.5) = 3) = {:.4}; Cov(N(0.25), N(0.5)) = LAM x 0.25 = {:.4}", pois(3, 2.0 * LAM * WIN), LAM * WIN);
    println!("mistake, totals as independent: P(N(0.25) = 1 and N(0.5) = 2) = {:.4}, product of the two laws {:.4}",
             exact[1].powf(2.0), exact[1] * pois(2, 2.0 * LAM * WIN));
    println!("mistake, 1 - LAM t for no call: quarter hour {:.4} vs {:.4}; one hour {:.4} vs {:.4}",
             1.0 - LAM * WIN, exact[0], 1.0 - LAM, (-LAM).exp());
    println!("mistake, gaps uniform on 0 to {:.0} minutes: P(no call in first quarter) exact {:.4}, simulated {:.4} +- {:.4}",
             120.0 / LAM, pu, ufreq[0], se(ufreq[0]));
    println!("  its corr(first quarter, second quarter): {:.4} +- {:.4}; wait from quarter past: {:.2} +- {:.2} minutes",
             ur12, rse, 60.0 * umw, 60.0 * usew);
    println!("sample path, arrival minutes: {}", join(&path, |a| format!("{:.1}", 60.0 * a)));
    println!("chart, minutes: {}", join(&grid, |m| m.to_string()));
    println!("chart, calls so far: {}", join(&steps, |c| c.to_string()));
    println!("chart, mean 4t: {}", join(&grid, |&m| format!("{:.2}", m as f64 / 15.0)));
    println!("chart, formula: {}", join(&exact, |p| format!("{:.2}", p)));
    println!("chart, simulated exponential gaps: {}", join(&freq[..=KMAX], |p| format!("{:.2}", p)));
    println!("chart, simulated uniform gaps (se at most {:.4}): {}", ufreq.iter().map(|&p| se(p)).fold(0.0, f64::max),
             join(&ufreq[..=KMAX], |p| format!("{:.2}", p)));

    assert!((0..=KMAX).all(|k| (rec[k] - exact[k]).abs() < 1e-6));           // recursion against formula
    assert!(errs[0] > errs[1] && errs[1] > errs[2] && errs[2] < 5e-4);       // slots close in on the formula
    assert!((0..=KMAX).all(|k| (freq[k] - exact[k]).abs() < 4.0 * se(exact[k])) && (m1 - v1).abs() < 4.0 * sev);
    assert!((both - exact[1] * exact[2]).abs() < 4.0 * se(both));           // increments multiply
    assert!(r12.abs() < 4.0 * rse && (r1t - 0.5f64.sqrt()).abs() < 4.0 * (1.0 - r1t * r1t) * rse); // increments vs totals
    assert!((mw - 1.0 / LAM).abs() < 4.0 * sew);                            // the restart at a fixed time
    assert!((ufreq[0] - pu).abs() <= 4.0 * se(pu) && ur12.abs() > 4.0 * rse); // uniform gaps break it
    println!("ALL CHECKS PASS");
}
