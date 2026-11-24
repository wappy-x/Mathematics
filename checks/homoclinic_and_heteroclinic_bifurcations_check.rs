// Homoclinic bifurcation: the same check as the Python, in Rust.  No crates.
// 1: the loop of x'' = x - 1.5x^2.  2: damping breaks the swing's top-to-top orbit.
// 3: in x' = y, y' = mu*y + x - x^2 + x*y a cycle grows until it touches the saddle.
use std::f64::consts::PI;
const H: f64 = 0.002;

fn rk4<F: Fn(f64, f64) -> (f64, f64)>(f: &F, x: f64, y: f64, h: f64) -> (f64, f64) {
    let (a1, b1) = f(x, y); let (a2, b2) = f(x + h / 2.0 * a1, y + h / 2.0 * b1);
    let (a3, b3) = f(x + h / 2.0 * a2, y + h / 2.0 * b2); let (a4, b4) = f(x + h * a3, y + h * b3);
    (x + h / 6.0 * (a1 + 2.0 * a2 + 2.0 * a3 + a4), y + h / 6.0 * (b1 + 2.0 * b2 + 2.0 * b3 + b4))
}
fn top(b: f64) -> f64 {                                  // part 2: leave the top, 1e-6 off
    let (mut th, mut w) = (PI - 1e-6, 0.0);
    loop {
        let pw = w; (th, w) = rk4(&|p: f64, q: f64| (q, -b * q - p.sin()), th, w, H);
        if pw < 0.0 && 0.0 <= w { return -th * 180.0 / PI }   // far-side height, in degrees
    }
}
fn eig(mu: f64) -> (f64, f64) { let r = (mu * mu + 4.0).sqrt(); ((mu + r) / 2.0, (mu - r) / 2.0) }
fn leave(mu: f64, h: f64, laps: usize) -> (f64, f64) {   // follow the saddle's outgoing path
    let f = |x: f64, y: f64| (y, mu * y + x - x * x + x * y);
    let (mut x, mut y, mut t, mut cr, mut lo) = (1e-7, 1e-7 * eig(mu).0, 0.0, Vec::new(), 1.0f64);
    while t < 400.0 {
        let py = y; (x, y) = rk4(&f, x, y, h); t += h; lo = lo.min(x);
        if laps == 0 && x < 0.0 { return (1.0, t) }                       // passes outside
        if laps == 0 && py < 0.0 && 0.0 <= y && x < 1.0 { return (-1.0, t) } // turns back inside
        if laps > 0 && py > 0.0 && 0.0 >= y && x > 1.0 {                  // right-side crossings
            cr.push(t - h * y / (y - py)); let last = lo; lo = 1.0;          // leftmost x of the lap just done
            if cr.len() == laps { return (cr[laps - 1] - cr[laps - 2], last) }
        }
    }
    panic!("no event within 400 time units")
}
fn critical(h: f64) -> f64 {                             // bisection on which side the path falls
    let (mut lo, mut hi) = (-0.87, -0.86);
    for _ in 0..34 {
        let mid = (lo + hi) / 2.0;
        if leave(mid, h, 0).0 < 0.0 { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}
fn main() {
    let lp = |x: f64, y: f64| (y, x - 1.5 * x * x);
    let (mut x, mut y, mut t, mut worst) = (1.0f64, 0.0f64, 0.0, 0.0f64);
    let ds = [1e-3, 1e-4]; let mut at = [f64::NAN; 2];      // part 1: start at the loop's top
    while x > 1e-4 && t < 30.0 {
        let px = x; (x, y) = rk4(&lp, x, y, H); t += H;
        worst = worst.max((y * y - x * x + x.powi(3)).abs());   // energy identity along the way
        for i in 0..2 { if px >= ds[i] && ds[i] > x { at[i] = t - H * (ds[i] - x) / (px - x) } }
    }
    let (mc, mc2) = (critical(H), critical(2.0 * H)); let (lu, ls) = eig(mc); let gain = 10f64.ln() / lu;
    println!("loop x = sech^2(t/2): saddle eigenvalues +1 and -1, top x = 1 at t = 0");
    for i in 0..2 {
        println!("time from the top to x = {}: by steps {:.4}, closed form {:.4}", ds[i], at[i], 2.0 * (ds[i].powf(-0.5)).acosh());
    }
    println!("tenfold closer adds {:.4}, near ln(10)/1 = {:.4}; energy identity (x')^2 = x^2 - x^3 kept to {:.1e}", at[1] - at[0], 10f64.ln(), worst);
    println!("swing leaving the top climbs on the far side to: undamped {:.4} deg, damping 0.5 {:.4} deg", top(0.0), top(0.5));
    println!("cycle born by Hopf at mu = -1; touches the saddle at mu_c = {:.7} (step {}), {:.7} (step {})", mc, H, mc2, 2.0 * H);
    println!("saddle at mu_c: lambda_u = {:.6}, lambda_s = {:.6}, sum {:.6} < 0, so the cycle attracts", lu, ls, lu + ls);
    println!("predicted extra time per tenfold step closer: ln(10)/lambda_u = {:.4}", gain);
    let lv: Vec<(f64, f64)> = (0..7).map(|k| if k < 2 { (0.0, 0.0) } else { leave(mc - 10f64.powi(-k), H, 6) }).collect(); // 6th lap: settled
    let tp: Vec<f64> = lv.iter().map(|v| v.0).collect();
    let c = tp[6] - 1e6f64.ln() / lu;
    for k in 2..7 {
        let g = if k > 2 { format!(", gain {:.4}", tp[k] - tp[k - 1]) } else { String::new() };
        println!("mu_c - mu = 1e-{}: period {:.4}, formula {:.4}, leftmost x {:.6}{}", k, tp[k], c + k as f64 * gain, lv[k].1, g);
    }
    println!("formula: period = {:.4} + ln(1/(mu_c - mu))/lambda_u", c);
    println!("mistake 1, base-10 log: 1/lambda_u = {:.4} per tenfold step, not {:.4}", 1.0 / lu, gain);
    println!("mistake 2, square-root law from 1e-2: {:.2} at 1e-6, true {:.4}", tp[2] * 100.0, tp[6]);
    println!("mistake 3, looking past mu_c at mu = mu_c + 0.01: no cycle, the path crosses x = 0 at t = {:.2} and runs off", leave(mc + 0.01, H, 0).1);
    assert!(at.iter().zip(ds.iter()).all(|(a, d)| (a - 2.0 * d.powf(-0.5).acosh()).abs() < 1e-4));
    assert!(worst < 1e-9 && (top(0.0) - 180.0).abs() < 1e-3 && top(0.5) < 120.0);
    assert!((mc - mc2).abs() < 1e-8 && (mc + 0.8645).abs() < 1e-4);          // published value -0.8645
    assert!(((tp[6] - tp[5]) - gain).abs() < 1e-3 && (tp[4] - (c + 4.0 * gain)).abs() < 1e-2);
    assert!(lv[2].1 > lv[4].1 && lv[4].1 > lv[6].1 && lv[6].1 > 0.0 && lv[6].1 < 1e-3);   // the cycle closes on the saddle at x = 0
    println!("ALL CHECKS PASS");
}
