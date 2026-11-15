// Normed and Banach spaces -- the check behind the card.  Rust std only.
// A week is 168 hourly prices in GBP/MWh (illustrative), read as a step function of time t in hours.

fn sup(x: &[f64]) -> f64 { x.iter().fold(0.0, |m, v| m.max(v.abs())) } // worst hour, GBP/MWh
fn one(x: &[f64]) -> f64 { x.iter().map(|v| v.abs()).sum::<f64>() * 1.0 } // GBP/MW
fn two(x: &[f64]) -> f64 { (x.iter().map(|v| v * v).sum::<f64>() * 1.0).sqrt() }
fn add(x: &[f64], y: &[f64]) -> Vec<f64> { x.iter().zip(y).map(|(a, b)| a + b).collect() }
fn scale(c: f64, x: &[f64]) -> Vec<f64> { x.iter().map(|a| c * a).collect() }
fn sq(x: &[f64]) -> f64 { x.iter().map(|v| v * v).sum() }
fn half(x: &[f64]) -> f64 { x.iter().map(|v| v.abs().sqrt()).sum::<f64>().powi(2) }

struct SplitMix(u64);
impl SplitMix {
    fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
}

const T0: f64 = 41.0;
const H: f64 = 100.0;
const GRID: usize = 3840; // cells per hour, all ramp ends land on it
fn ramp(n: f64, t: f64) -> f64 { H * 1.0f64.min(0.0f64.max((t - T0) * n)) }
fn dist1(n: f64, m: f64) -> f64 {
    let g = GRID as f64;
    (0..GRID).map(|k| (ramp(n, T0 + (k as f64 + 0.5) / g) - ramp(m, T0 + (k as f64 + 0.5) / g)).abs()).sum::<f64>() / g
}
fn distsup(n: f64, m: f64) -> f64 {
    let g = GRID as f64;
    (0..=GRID).map(|k| (ramp(n, T0 + k as f64 / g) - ramp(m, T0 + k as f64 / g)).abs()).fold(0.0, f64::max)
}

fn main() {
    let blocks = [55.0, 70.0, 90.0, 75.0, 120.0, 80.0];
    let forecast: Vec<f64> = (0..168).map(|h| blocks[(h % 24) / 4]).collect();
    let spikes = [(41, 60.0), (42, 80.0), (43, 40.0), (131, -20.0), (132, -20.0), (133, -20.0), (134, -20.0)];
    let mut err = vec![0.0; 168];
    for &(h, v) in spikes.iter() { err[h] = v; }
    let actual = add(&forecast, &err);
    let wind: Vec<f64> = (0..168).map(|h| if h < 100 { err[h] } else { 0.0 }).collect();
    let sun: Vec<f64> = (0..168).map(|h| if h >= 100 { err[h] } else { 0.0 }).collect();
    let norms: [(&str, fn(&[f64]) -> f64); 3] = [("sup", sup), ("1", one), ("2", two)];
    let r168 = 168f64.sqrt();

    println!("the week (illustrative): forecast blocks [55, 70, 90, 75, 120, 80] GBP/MWh, every day");
    println!("forecast: peak {}  ||f||_1 = {:.0} GBP/MW  RMS {:.2} GBP/MWh", sup(&forecast), one(&forecast), two(&forecast) / r168);
    println!("actual:   peak {}  ||f||_1 = {:.0} GBP/MW  RMS {:.2} GBP/MWh", sup(&actual), one(&actual), two(&actual) / r168);
    let (s, a, r) = (sup(&err), one(&err), two(&err));
    println!("error e:  ||e||_sup = {} GBP/MWh  ||e||_1 = {:.0} GBP/MW  ||e||_2 = {:.3}", s, a, r);
    // second road: the hand formula, from the seven non-zero hours only
    assert!(s == 80.0 && a == 60.0 + 80.0 + 40.0 + 4.0 * 20.0);
    assert!((r - (3600.0f64 + 6400.0 + 1600.0 + 4.0 * 400.0).sqrt()).abs() < 1e-12);
    let bsq: f64 = blocks.iter().map(|b| b * b).sum();
    assert!((two(&actual).powi(2) - (28.0 * bsq + 54800.0 - 11000.0)).abs() < 1e-6);
    println!("bars: worst hour {:.2}, RMS {:.2}, mean absolute {:.2} GBP/MWh", s, r / r168, a / 168.0);

    println!("rule 2, scale by c = 0.1 (to p/kWh) and c = -1:");
    for (name, n) in norms.iter() {
        for c in [0.1, -1.0] { assert!((n(&scale(c, &err)) - c.abs() * n(&err)).abs() < 1e-9); }
        println!("  ||0.1 e||_{} = {:.4}   ||-e||_{} = {:.4}", name, n(&scale(0.1, &err)), name, n(&scale(-1.0, &err)));
    }
    println!("rule 3, e = wind lull + sunshine:");
    for (name, n) in norms.iter() {
        let (lhs, rhs) = (n(&add(&wind, &sun)), n(&wind) + n(&sun));
        assert!(lhs <= rhs + 1e-12);
        println!("  ||e||_{} = {:.3} <= {:.3} + {:.3} = {:.3}", name, lhs, n(&wind), n(&sun), rhs);
    }

    // rules 1 to 3 on 2000 random weeks, prices -50..300 (negative prices do happen)
    let mut g = SplitMix(20261115);
    let zero = vec![0.0; 168];
    for _ in 0..1000 {
        let x: Vec<f64> = (0..168).map(|_| (g.next() % 351) as f64 - 50.0).collect();
        let y: Vec<f64> = (0..168).map(|_| (g.next() % 351) as f64 - 50.0).collect();
        let c = ((g.next() % 41) as f64 - 20.0) / 4.0;
        for (_, n) in norms.iter() {
            assert!(n(&x) > 0.0 && n(&zero) == 0.0);
            assert!((n(&scale(c, &x)) - c.abs() * n(&x)).abs() < 1e-6 * (1.0 + n(&x)));
            assert!(n(&add(&x, &y)) <= n(&x) + n(&y) + 1e-9);
        }
        assert!(sup(&x) <= one(&x) && one(&x) <= 168.0 * sup(&x));
    }
    println!("random weeks: 1000 pairs, rules 1-3 hold for all three norms");
    println!("sandwich: ||e||_sup x 1 h = {} <= ||e||_1 = {:.0} <= 168 h x ||e||_sup = {}", s, a, 168.0 * s);

    println!("what breaks:");
    let flat = vec![10.0; 168];
    let range = flat.iter().cloned().fold(f64::MIN, f64::max) - flat.iter().cloned().fold(f64::MAX, f64::min);
    println!("  range max-min of a flat +10 error: {} (rule 1 fails, yet ||.||_1 = {:.0})", range, one(&flat));
    println!("  no square root: sum of squares of e = {}, of 2e = {} (rule 2 wants {})", sq(&err), sq(&scale(2.0, &err)), 2.0 * sq(&err));
    let (hw, hs, he) = (half(&wind), half(&sun), half(&err));
    assert!(he > hw + hs);
    println!("  p = 1/2: size(e) = {:.2} > size(wind) + size(sun) = {:.2} + {:.2} = {:.2}", he, hw, hs, hw + hs);

    println!("ramps f_n (rise over 1/n h): Cauchy test ||f_n - f_2n||");
    let (mut pts1, mut ptss) = (Vec::new(), Vec::new());
    for n in [1.0f64, 2.0, 4.0, 8.0, 16.0, 32.0, 64.0] {
        let (d1, ds) = (dist1(n, 2.0 * n), distsup(n, 2.0 * n));
        assert!((d1 - 50.0 * (1.0 / n - 1.0 / (2.0 * n))).abs() < 1e-9 && (ds - H / 2.0).abs() < 1e-9);
        pts1.push(format!("{:.6}", d1));
        ptss.push(format!("{:.1}", ds));
        println!("  n = {:2}: L1 {:9.6} GBP/MW (closed form 25/n)   sup {:.1} GBP/MWh", n as i64, d1, ds);
    }
    println!("chart, L1: {}", pts1.join(", "));
    println!("chart, sup: {}", ptss.join(", "));
    let gap = H - ramp(60.0, T0 + 1.0 / GRID as f64);
    println!("  1-minute ramp to the step: L1 distance 50/60 = {:.4} GBP/MW; sup gap at t0 + 1/{} h = {:.4}, heading to {}", 50.0 / 60.0, GRID, gap, H);
    let mut total = 0.0;
    for k in 1..8 { total += dist1(2f64.powi(k - 1), 2f64.powi(k)); } // corrections x_k = f_(2^k) - f_(2^(k-1))
    println!("series of corrections: sum of L1 sizes over 7 terms = {:.6} = 50(1 - 2^-7), limit 50; sup sizes 50 each, sum grows without bound", total);
    assert!((total - 50.0 * (1.0 - 2f64.powi(-7))).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
