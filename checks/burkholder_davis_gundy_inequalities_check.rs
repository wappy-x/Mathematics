// Burkholder-Davis-Gundy -- the same check as the Python, in Rust.  No crates.
// House example: M_t = int_0^t B dB = (B_t^2 - t)/2 on [0, 1], a fair game whose
// clock is <M>_t = int_0^t B_s^2 ds.  Roads: exact Gaussian moments by algebra and
// by Simpson's rule; 10,000 simulated paths of left-point Ito sums; the closed
// form (B_t^2 - t)/2 along the same paths; the clock as M's summed squared steps.
// The same paths read every 4th step show how low the grid reads the peak.
const PATHS: usize = 10000;
const STEPS: usize = 1000;
const SEED: u64 = 20261123;
const PS: [f64; 5] = [0.5, 1.0, 2.0, 3.0, 4.0];
struct Rng { state: u64, spare: Option<f64> }
impl Rng {
    fn uniform(&mut self) -> f64 { // SplitMix64, a uniform number strictly between 0 and 1
        self.state = self.state.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.state;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 2f64.powf(53.0)
    }
    fn normal(&mut self) -> f64 { // Box-Muller, both outputs used
        if let Some(x) = self.spare.take() { return x; }
        let r = (-2.0 * self.uniform().ln()).sqrt();
        let a = 2.0 * std::f64::consts::PI * self.uniform();
        self.spare = Some(r * a.sin());
        r * a.cos()
    }
}
fn simpson(f: &dyn Fn(f64) -> f64, lo: f64, hi: f64, n: usize) -> f64 {
    let h = (hi - lo) / n as f64;
    let mut s = 0.0;
    for k in 0..=n {
        let w = if k == 0 || k == n { 1.0 } else if k % 2 == 1 { 4.0 } else { 2.0 };
        s += w * f(lo + k as f64 * h);
    }
    h / 3.0 * s
}
fn gauss_moment(f: &dyn Fn(f64) -> f64) -> f64 {
    simpson(&|z: f64| f(z) * (-z * z / 2.0).exp() / (2.0 * std::f64::consts::PI).sqrt(), -12.0, 12.0, 4000)
}
fn bdg_upper(p: f64) -> f64 { (p * (p - 1.0) / 2.0 * (p / (p - 1.0)).powf(p)).powf(p / 2.0) }
fn mean_se(xs: &[f64]) -> (f64, f64) {
    let n = xs.len() as f64;
    let m = xs.iter().sum::<f64>() / n;
    let v = xs.iter().map(|x| (x - m) * (x - m)).sum::<f64>() / (n - 1.0) / n;
    (m, v.sqrt())
}
fn main() {
    let dt = 1.0 / STEPS as f64;
    let mut rng = Rng { state: SEED, spare: None };
    // ---- road 1: exact moments ----
    let (ec1, ec2) = (0.5, 0.25 + 2.0 * (1.0 / 6.0));
    let (em2, em4) = ((3.0 - 2.0 + 1.0) / 4.0, (105.0 - 60.0 + 18.0 - 4.0 + 1.0) / 16.0);
    let sm2 = gauss_moment(&|z: f64| ((z * z - 1.0) / 2.0).powf(2.0));
    let sm4 = gauss_moment(&|z: f64| ((z * z - 1.0) / 2.0).powf(4.0));
    println!("exact  E<M>_1 = {:.6}   E<M>_1^2 = {:.6}   E M_1^2 = {:.6}   E M_1^4 = {:.6}", ec1, ec2, em2, em4);
    println!("Simpson over the bell curve:          E M_1^2 = {:.6}   E M_1^4 = {:.6}", sm2, sm4);
    assert!((sm2 - em2).abs() < 1e-9 && (sm4 - em4).abs() < 1e-9);
    // ---- road 2: 10,000 paths, Ito sums on 1,000 steps ----
    let (mut peak, mut clock, mut end, mut gap) = (vec![], vec![], vec![], vec![]);
    let (mut qvgap, mut atpeak, mut ends4, mut peakc, mut peak4) = (vec![], vec![], vec![], vec![], vec![]);
    for _ in 0..PATHS {
        let (mut b, mut m, mut c, mut qv, mut top, mut topc, mut c_at) = (0.0f64, 0.0f64, 0.0, 0.0, 0.0f64, 0.0f64, 0.0);
        let mut top4 = 0.0f64;
        for k in 0..STEPS {
            let db = rng.normal() * dt.sqrt();
            let dm = b * db; // holding b, chosen before the step
            c += b * b * dt; qv += dm * dm; b += db; m += dm;
            if m.abs() > top { top = m.abs(); c_at = c; }
            if k % 4 == 3 { top4 = top4.max(m.abs()); } // the same path, read every 4th step
            topc = topc.max(((b * b - (k + 1) as f64 * dt) / 2.0).abs());
        }
        peak.push(top); clock.push(c); end.push(m); gap.push((topc - top).abs());
        qvgap.push((qv - c).abs()); atpeak.push((top * top, c_at)); ends4.push(m.powf(4.0));
        peakc.push(topc); peak4.push(top4);
    }
    let n = PATHS as f64;
    let (sc, sc_se) = mean_se(&clock);
    let (se2, se2_se) = mean_se(&end.iter().map(|x| x * x).collect::<Vec<_>>());
    let (sp2, sp2_se) = mean_se(&peak.iter().map(|x| x * x).collect::<Vec<_>>());
    let (sp4, sp4_se) = mean_se(&peak.iter().map(|x| x.powf(4.0)).collect::<Vec<_>>());
    let (e4, e4_se) = mean_se(&ends4);
    let (sc2, sc2_se) = mean_se(&clock.iter().map(|x| x * x).collect::<Vec<_>>());
    let spc = peakc.iter().map(|x| x * x).sum::<f64>() / n;
    let sp2q = peak4.iter().map(|x| x * x).sum::<f64>() / n; // the peak read every 4th step: a coarser grid
    let (ext, ext_se) = mean_se(&peak.iter().zip(peak4.iter()).map(|(x, y)| 2.0 * x * x - y * y).collect::<Vec<_>>()); // grid error ~ sqrt(step)
    println!("simulated E<M>_1  = {:.4} +- {:.4}   (exact 0.5)", sc, sc_se);
    println!("simulated E<M>_1^2 = {:.4} +- {:.4}   (exact 7/12)", sc2, sc2_se);
    println!("simulated E M_1^2 = {:.4} +- {:.4}   (exact 0.5)", se2, se2_se);
    println!("simulated E M_1^4 = {:.4} +- {:.4}   (exact 3.75)", e4, e4_se);
    println!("mean |sum of squared steps of M - clock| = {:.5}", qvgap.iter().sum::<f64>() / n);
    println!("mean |peak from (B^2-t)/2 - peak from Ito sums| = {:.5}", gap.iter().sum::<f64>() / n);
    println!("E sup M^2 from (B^2-t)/2 = {:.4}, from Ito sums = {:.4}", spc, sp2);
    println!("p = 2:  lower bound E<M>_1 = {:.4}   E sup M^2 = {:.4} +- {:.4}   upper bound 4 x 0.5 = {:.4}", ec1, sp2, sp2_se, 4.0 * ec1);
    println!("        ratio E sup M^2 / E<M>_1 = {:.4}", sp2 / ec1);
    println!("grid: E sup M^2 read every 4th step = {:.4}; continuous, 2 x {:.4} - {:.4} = {:.4} +- {:.4}", sp2q, sp2, sp2q, ext, ext_se);
    assert!((sc - ec1).abs() < 4.0 * sc_se && (se2 - em2).abs() < 4.0 * se2_se && (sc2 - ec2).abs() < 4.0 * sc2_se);
    assert!(qvgap.iter().sum::<f64>() / n < 2.0 * dt.sqrt() && gap.iter().sum::<f64>() / n < 2.0 * dt.sqrt());
    assert!((spc - sp2).abs() < dt.sqrt()); // same paths: the two forms differ by the grid's rounding
    assert!(ec1 < sp2 - 4.0 * sp2_se && sp2 + 4.0 * sp2_se < 4.0 * ec1);
    // ---- every p: the peak against the clock ----
    println!("    p   E sup|M|^p   E <M>_1^(p/2)   ratio");
    let mut ratios = vec![];
    for &p in PS.iter() {
        let a = peak.iter().map(|x| x.powf(p)).sum::<f64>() / n;
        let c = clock.iter().map(|x| x.powf(p / 2.0)).sum::<f64>() / n;
        ratios.push(a / c);
        let label = if p.fract() == 0.0 { format!("{}", p as i64) } else { format!("{}", p) };
        println!("{:>5}   {:10.4}   {:13.4}   {:5.3}", label, a, c, a / c);
    }
    for p in [2.0, 3.0, 4.0] { println!("upper constant from the proof, p = {}: C_p = {:.4}", p as i64, bdg_upper(p)); }
    println!("p = 4:  E sup M^4 = {:.4} +- {:.4}   bound C_4 x 7/12 = {:.4}   Doob (4/3)^4 x 3.75 = {:.4}",
             sp4, sp4_se, bdg_upper(4.0) * ec2, (4.0f64 / 3.0).powf(4.0) * em4);
    println!("chart, ratio by p: {}", ratios.iter().map(|r| format!("{:.3}", r)).collect::<Vec<_>>().join(", "));
    assert!((bdg_upper(2.0) - 4.0).abs() < 1e-12 && (bdg_upper(3.0) - (81.0f64 / 8.0).powf(1.5)).abs() < 1e-9); // hand forms
    assert!(1.0 < ratios[2] && ratios[2] < 4.0 && ratios[3] < bdg_upper(3.0) && ratios[4] < bdg_upper(4.0) && sp4 < (4.0f64 / 3.0).powf(4.0) * em4);
    // ---- what breaks ----
    let peak_at = atpeak.iter().map(|&(x, _)| x).sum::<f64>() / n;
    let clock_at = atpeak.iter().map(|&(_, c)| c).sum::<f64>() / n;
    println!("mistake, endpoint for peak: E M_1^2 = {:.4} against E sup M^2 = {:.4}", se2, sp2);
    println!("mistake, isometry at the time of the peak: E M^2 = {:.4} but E<M> = {:.4}", peak_at, clock_at);
    let drift = em2 + 2.0f64.powf(2.0); // X = M + 2t: same clock, E X_1^2 = 0.5 + 4
    println!("mistake, a drift 2t added, same clock: E X_1^2 = {:.4}, above the bound {:.4}", drift, 4.0 * ec1);
    let bad = peak.iter().zip(clock.iter()).filter(|&(x, c)| x * x > 4.0 * c).count();
    println!("mistake, path by path: {} of {} paths have sup M^2 > 4 <M>_1", bad, PATHS);
    assert!(peak_at > clock_at + 0.1 && se2 < sp2 - 0.1 && bad > 0);
    println!("ALL CHECKS PASS");
}
