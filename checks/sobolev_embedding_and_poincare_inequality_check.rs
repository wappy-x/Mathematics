// Sobolev and Poincare -- the check behind the card.  Rust std only, no crates.
// Example (illustrative): a river level h(t) over one day, L = 24 h. It rises
// 1.00 -> 1.60 m in 6 h, then drains to 1.12 m by hour 24: straight pieces with a kink.
use std::f64::consts::PI;

#[derive(Clone, Copy)]
struct Q { n: i128, d: i128 } // an exact fraction n/d, kept in lowest terms
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d) * d.signum(); Q { n: n / g, d: d / g } }
impl Q {
    fn add(self, o: Q) -> Q { q(self.n * o.d + o.n * self.d, self.d * o.d) }
    fn sub(self, o: Q) -> Q { q(self.n * o.d - o.n * self.d, self.d * o.d) }
    fn mul(self, o: Q) -> Q { q(self.n * o.n, self.d * o.d) }
    fn div(self, o: Q) -> Q { q(self.n * o.d, self.d * o.n) }
    fn f(self) -> f64 { self.n as f64 / self.d as f64 }
}

const L: f64 = 24.0;
fn hf(t: f64) -> f64 { if t <= 6.0 { 1.0 + 0.1 * t } else { 1.6 - (t - 6.0) * 0.48 / 18.0 } }

// How many eigenvalues of the path matrix (diagonal 1,2,...,2,1; off-diagonal -1) lie below x.
fn below(x: f64, n: usize) -> usize {
    let mut d = 1.0 - x;
    let mut count = (d < 0.0) as usize;
    for i in 1..n {
        let a = (if i == n - 1 { 1.0 } else { 2.0 }) - x;
        d = a - 1.0 / (if d != 0.0 { d } else { 1e-300 });
        count += (d < 0.0) as usize;
    }
    count
}
fn lam1(n: usize) -> f64 {
    let (mut lo, mut hi) = (1e-15, 4.0);
    for _ in 0..200 {
        let mid = (lo + hi) / 2.0;
        if below(mid, n) >= 2 { hi = mid } else { lo = mid }
    }
    (lo + hi) / 2.0
}

// Road 1: exact fractions.  On a straight piece, int y^2 = width*(y0^2+y0*y1+y1^2)/3.
// Returns mean, int (h - mean)^2, int h^2, the slopes and int h'^2 on each piece.
fn stats(knots: &[(Q, Q)]) -> (Q, Q, Q, Vec<Q>, Vec<Q>) {
    let segs: Vec<((Q, Q), (Q, Q))> = (0..knots.len() - 1).map(|i| (knots[i], knots[i + 1])).collect();
    let mut mean = q(0, 1);
    for &((t0, y0), (t1, y1)) in &segs { mean = mean.add(t1.sub(t0).mul(y0.add(y1)).div(q(2, 1))); }
    mean = mean.div(q(24, 1));
    let sq3 = |a: Q, b: Q| a.mul(a).add(a.mul(b)).add(b.mul(b)).div(q(3, 1));
    let (mut dev2, mut raw2, mut slopes, mut pieces) = (q(0, 1), q(0, 1), vec![], vec![]);
    for &((t0, y0), (t1, y1)) in &segs {
        let w = t1.sub(t0);
        dev2 = dev2.add(w.mul(sq3(y0.sub(mean), y1.sub(mean))));
        raw2 = raw2.add(w.mul(sq3(y0, y1)));
        let s = y1.sub(y0).div(w);
        slopes.push(s);
        pieces.push(s.mul(s).mul(w));
    }
    (mean, dev2, raw2, slopes, pieces)
}

fn main() {
    let knots = [(q(0, 1), q(1, 1)), (q(6, 1), q(8, 5)), (q(24, 1), q(28, 25))]; // (hour, metres)
    let (mean, dev2, raw2, slopes, pieces) = stats(&knots);
    let slope2 = pieces[0].add(pieces[1]);
    // Road 2: brute force, a midpoint sum on 240,000 slices, slope by finite differences.
    let n_fine = 240000usize;
    let dt = L / n_fine as f64;
    let hv: Vec<f64> = (0..n_fine).map(|i| hf((i as f64 + 0.5) * dt)).collect();
    let mean_bf = hv.iter().sum::<f64>() * dt / L;
    let dev2_bf = hv.iter().map(|v| (v - mean_bf).powi(2)).sum::<f64>() * dt;
    let slope2_bf = (0..n_fine).map(|i| ((hf((i + 1) as f64 * dt) - hf(i as f64 * dt)) / dt).powi(2)).sum::<f64>() * dt;

    let (rms_dev, rms_slope) = ((dev2.f() / L).sqrt(), (slope2.f() / L).sqrt());
    let cp = L / PI;
    let largest = knots.iter().map(|k| k.1.sub(mean).f().abs()).fold(0.0, f64::max);
    let maxslope = slopes.iter().map(|s| s.f().abs()).fold(0.0, f64::max);
    let pairs: Vec<(&str, f64)> = vec![
        ("slope on the rise, m/h", slopes[0].f()), ("slope on the drain, m/h", slopes[1].f()),
        ("mean level, m", mean.f()), ("int (h - mean)^2, m^2 h", dev2.f()),
        ("int h'^2 on the rise, m^2/h", pieces[0].f()), ("int h'^2 on the drain, m^2/h", pieces[1].f()),
        ("int h'^2, m^2/h", slope2.f()), ("  brute force mean", mean_bf),
        ("  brute force int (h - mean)^2", dev2_bf), ("  brute force int h'^2", slope2_bf),
        ("||h'||_2, m/sqrt(h)", slope2.f().sqrt()),
        ("RMS deviation, m", rms_dev), ("RMS slope, m/h", rms_slope),
        ("C_P = L/pi, h", cp), ("Poincare bound C_P * RMS slope, m", cp * rms_slope),
        ("ratio RMS dev / RMS slope, h", rms_dev / rms_slope),
        ("largest |h - mean|, m", largest),
        ("sup bound L * RMS slope, m", L * rms_slope),
        ("MVT bound L * max|h'|, m", L * maxslope),
        ("rise 0-6 h: actual, m", knots[1].1.sub(knots[0].1).f()),
        ("rise: local bound sqrt(6)*sqrt(int_0^6 h'^2)", (6.0 * pieces[0].f()).sqrt()),
        ("rise: global bound sqrt(6)*||h'||_2", (6.0 * slope2.f()).sqrt()),
    ];
    for (name, v) in &pairs { println!("{:<46} {:>12.6}", name, v); }
    println!("{:<46} {}", "deviation from mean at hours 0, 6, 24, m", knots.iter().map(|k| format!("{:.6}", k.1.sub(mean).f())).collect::<Vec<_>>().join(" "));

    // Hourly averages: the finite rehearsal.  Every pair of hours obeys the Holder bound.
    let u: Vec<f64> = (0..24).map(|i| hf(i as f64 + 0.5)).collect();
    let mut worst: f64 = 0.0;
    for i in 0..24 { for j in 0..24 { if i != j {
        let gap = (i as f64 - j as f64).abs();
        worst = worst.max((u[i] - u[j]).abs() / (gap.sqrt() * slope2.f().sqrt()));
    } } }
    println!("{:<46} {:>12.6}", "hourly pairs: worst |u_i - u_j| / bound", worst);

    println!();
    println!("{:>5} {:>14} {:>14} {:>14} {:>15}", "N", "C_N bisection", "C_N formula", "Rayleigh cos", "(C_N-L/pi)*N^2");
    let mut table = vec![];
    for &n in &[6usize, 24, 96, 384] {
        let d_t = L / n as f64;
        let cb = d_t / lam1(n).sqrt();
        let cf = d_t / (2.0 * (PI / (2.0 * n as f64)).sin());
        let w: Vec<f64> = (0..n).map(|i| (PI * (i as f64 + 0.5) / n as f64).cos()).collect();
        let num = w.iter().map(|x| x * x).sum::<f64>() * d_t;
        let den = (0..n - 1).map(|i| ((w[i + 1] - w[i]) / d_t).powi(2)).sum::<f64>() * d_t;
        let cr = (num / den).sqrt();
        table.push((cb, cf, cr));
        println!("{:>5} {:>14.6} {:>14.6} {:>14.6} {:>15.6}", n, cb, cf, cr, (cb - cp) * (n * n) as f64);
    }
    let ubar = u.iter().sum::<f64>() / 24.0;
    let dev24 = u.iter().map(|x| (x - ubar).powi(2)).sum::<f64>().sqrt();
    let sl24 = (0..23).map(|i| (u[i + 1] - u[i]).powi(2)).sum::<f64>().sqrt();
    println!("hourly data: spread {:.6}  slope {:.6}  ratio {:.6}  C_24 {:.6}", dev24, sl24, dev24 / sl24, table[1].0);

    // What breaks.
    println!();
    println!("{:<46} {:>12.6}", "break: RMS of h itself, no mean removed, m", (raw2.f() / L).sqrt());
    for &eps in &[1.0f64, 0.01, 0.0001] { // a sluice gate: 0.6 m jump over eps hours
        println!("break: jump 0.6 m over {:.4} h, ||h'||_2 = {:>12.6}", eps, 0.6 / eps.sqrt());
    }
    for &ll in &[24.0f64, 240.0, 2400.0] { // same cosine wave, longer and longer river record
        println!("break: record of {:>5} h, best constant L/pi = {:>12.6}", ll as i64, ll / PI);
    }
    let mut energies = vec![];
    for &k in &[2i32, 8, 32] { // 2-D: u = log log(e/r) on the unit disc
        let kf = k as f64;
        let e_closed = 2.0 * PI * (1.0 - 1.0 / (1.0 + kf * 10f64.ln()));
        let (m, a, b) = (20000usize, 1.0, 1.0 + kf * 10f64.ln());
        let e_num = 2.0 * PI * (0..m).map(|j| 1.0 / (a + (j as f64 + 0.5) * (b - a) / m as f64).powi(2)).sum::<f64>() * (b - a) / m as f64;
        energies.push((e_closed, e_num));
        println!("break: 2-D, r = 1e-{:<2}: u = {:.6}  energy {:.6}  midpoint {:.6}", k, (1.0 + kf * 10f64.ln()).ln(), e_closed, e_num);
    }
    println!("{:<46} {:>12.6}", "break: 2-D energy ceiling 2 pi", 2.0 * PI);

    // Try changing.
    println!();
    let shifted: Vec<(Q, Q)> = knots.iter().map(|&(t, y)| (t, y.add(q(1, 1)))).collect();
    let (m1, d1, _, _, _) = stats(&shifted);
    println!("try: sensor offset +1 m: mean {:.6}  RMS dev {:.6}", m1.f(), (d1.f() / L).sqrt());
    let (m2, d2, _, _, p2) = stats(&[(q(0, 1), q(1, 1)), (q(2, 1), q(8, 5)), (q(24, 1), q(28, 25))]);
    let (r2d, r2s) = ((d2.f() / L).sqrt(), (p2[0].add(p2[1]).f() / L).sqrt());
    println!("try: peak at hour 2: mean {:.6}  RMS dev {:.6}  RMS slope {:.6}  ratio {:.6}", m2.f(), r2d, r2s, r2d / r2s);

    println!();
    println!("chart, hour   {}", (0..13).map(|i| format!("{:5}", 2 * i)).collect::<Vec<_>>().join(" "));
    println!("chart, level  {}", (0..13).map(|i| format!("{:5.2}", hf(2.0 * i as f64))).collect::<Vec<_>>().join(" "));

    assert!((mean_bf - mean.f()).abs() < 1e-9, "exact mean vs brute force");
    assert!((dev2_bf - dev2.f()).abs() < 1e-8, "exact spread vs brute force");
    assert!((slope2_bf - slope2.f()).abs() < 1e-6, "exact slope energy vs brute force");
    assert!(rms_dev <= cp * rms_slope && r2d <= cp * r2s, "Poincare inequality on both rivers");
    assert!(worst <= 1.0, "Holder bound on every pair of hourly readings");
    for &(cb, cf, cr) in &table { assert!((cb - cf).abs() < 1e-9 && (cr - cb).abs() < 1e-9, "three roads to C_N"); }
    assert!((table[3].0 - cp).abs() < 1e-4 && table[0].0 > table[3].0 && table[3].0 > cp, "C_N falls to L/pi");
    assert!(dev24 / sl24 <= table[1].0, "discrete Poincare on the hourly data");
    assert!(energies.iter().all(|(a, b)| (a - b).abs() < 1e-4) && energies[2].0 < 2.0 * PI, "2-D energy");
    assert!(((d1.f() / L).sqrt() - rms_dev).abs() < 1e-12, "an offset leaves the deviation alone");
    println!("ALL CHECKS PASS");
}
