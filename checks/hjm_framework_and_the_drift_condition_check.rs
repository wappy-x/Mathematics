// HJM drift condition -- the check behind the card, in Rust.  std only, no crates.
// One-factor HJM, exponential volatility sigma(t,T) = 0.01 e^{-0.3 (T - t)},
// today's forward curve f(0,T) = 0.05 - 0.01 e^{-0.3 T}.  The same four roads as
// the Python: drift by quadrature, the exact bell-curve law of the discounted
// bond, Monte Carlo of 100,000 curves, and Hull-White inside HJM.
const A: f64 = 0.3; // fade speed per year
const SIG: f64 = 0.01; // front volatility

fn f0(t: f64) -> f64 { 0.05 - 0.01 * (-0.3 * t).exp() }
fn f0_area(t: f64) -> f64 { 0.05 * t - 0.01 * (1.0 - (-0.3 * t).exp()) / 0.3 }
fn p0(t: f64) -> f64 { (-f0_area(t)).exp() }
fn vol(t: f64, big_t: f64) -> f64 { SIG * (-A * (big_t - t)).exp() }
fn b(h: f64) -> f64 { (1.0 - (-A * h).exp()) / A }
fn alpha(t: f64, big_t: f64) -> f64 { SIG * SIG * (-A * (big_t - t)).exp() * b(big_t - t) }

fn simpson<F: Fn(f64) -> f64>(g: F, lo: f64, hi: f64, n: usize) -> f64 {
    if hi <= lo { return 0.0; }
    let h = (hi - lo) / n as f64;
    let mut inner = 0.0;
    for k in 1..n { inner += if k % 2 == 1 { 4.0 } else { 2.0 } * g(lo + k as f64 * h); }
    (g(lo) + g(hi) + inner) * h / 3.0
}
fn alpha_quad(t: f64, big_t: f64) -> f64 { vol(t, big_t) * simpson(|u| vol(t, u), t, big_t, 200) }

fn drift_area<F: Fn(f64, f64) -> f64>(dr: &F) -> f64 {
    let front = simpson(|u| simpson(|v| dr(v, u), 0.0, u, 60), 0.0, 1.0, 60);
    let back = simpson(|s| simpson(|v| dr(v, s), 0.0, 1.0, 60), 1.0, 5.0, 60);
    front + back
}
// int_0^t alpha(u,T) du, closed form
fn g_int(t: f64, big_t: f64) -> f64 {
    SIG * SIG / A * (((-A * (big_t - t)).exp() - (-A * big_t).exp()) / A
        - ((-2.0 * A * (big_t - t)).exp() - (-2.0 * A * big_t).exp()) / (2.0 * A))
}
struct Rng(u64);
impl Rng {
    fn unif(&mut self) -> f64 {
        self.0 = self.0.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((self.0 >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 {
        let u1 = self.unif();
        let u2 = self.unif();
        (-2.0 * u1.ln()).sqrt() * (2.0 * std::f64::consts::PI * u2).cos()
    }
}
fn mean_r(t: f64) -> f64 { f0(t) + simpson(|u| alpha(u, t), 0.0, t, 200) }
fn theta_hw(t: f64) -> f64 {
    0.003 * (-0.3 * t).exp() + A * f0(t) + SIG * SIG / (2.0 * A) * (1.0 - (-2.0 * A * t).exp())
}
fn f1(s: f64, x: f64) -> f64 { f0(s) + simpson(|u| alpha(u, s), 0.0, 1.0, 100) + SIG * (-A * (s - 1.0)).exp() * x }

fn main() {
    // ---- road 1: the drift is the volatility times the volatility area ----
    println!("road 1: alpha(t,T) = sigma(t,T) x A(t,T), per year");
    println!(" (t,T)     sigma(t,T)    A(t,T)      closed         quadrature");
    let mut gap1: f64 = 0.0;
    for &(t, bt) in &[(0.0, 1.0), (0.0, 5.0), (1.0, 5.0), (0.0, 10.0), (0.0, 2f64.ln() / A)] {
        let (ac, aq) = (alpha(t, bt), alpha_quad(t, bt));
        gap1 = gap1.max((ac - aq).abs());
        println!(" ({},{:5.2})  {:.7}  {:.7}  {:.10}  {:.10}", t as i32, bt, vol(t, bt), SIG * b(bt - t), ac, aq);
    }
    println!(" peak drift sigma^2/(4a) = {:.10}", SIG * SIG / (4.0 * A));

    // ---- road 2: exact law of D(1)P(1,5) ----
    let v = simpson(|v| simpson(|u| vol(v, u), v, 5.0, 200).powi(2), 0.0, 1.0, 200);
    let expect = |m: f64| p0(5.0) * (-m + v / 2.0).exp();
    let e_right = expect(drift_area(&alpha));
    println!();
    println!("road 2: exact bell-curve law of D(1) P(1,5)");
    println!(" P(0,5) market                    {:.9}   exponent {:.6}", p0(5.0), f0_area(5.0));
    println!(" drift area M                     {:.9}", drift_area(&alpha));
    println!(" half variance V/2                {:.9}", v / 2.0);
    println!(" E[D(1)P(1,5)] drift condition    {:.9}", e_right);
    let wrongs: [(&str, f64); 3] = [
        ("zero drift", drift_area(&|_v: f64, _u: f64| 0.0)),
        ("drift sign flipped", drift_area(&|v: f64, u: f64| -alpha(v, u))),
        ("drift 1/2 sigma^2", drift_area(&|v: f64, u: f64| 0.5 * vol(v, u).powi(2))),
    ];
    for (name, m) in wrongs.iter() {
        let e = expect(*m);
        println!(" wrong: {:<20} {:.9}  per $1m: {:+8.2}", name, e, 1e6 * (e - p0(5.0)));
    }

    // ---- road 3: Monte Carlo of the whole curve ----
    let mut rng = Rng(2026);
    let (n, m) = (100000usize, 25usize);
    let dt = 1.0 / m as f64;
    let (fade, kick) = ((-A * dt).exp(), ((1.0 - (-2.0 * A * dt).exp()) / (2.0 * A)).sqrt());
    let r_det: Vec<f64> = (0..=m).map(|k| f0(k as f64 * dt) + g_int(k as f64 * dt, k as f64 * dt)).collect();
    let r_nod: Vec<f64> = (0..=m).map(|k| f0(k as f64 * dt)).collect();
    let back_det = f0_area(5.0) - f0_area(1.0) + simpson(|s| g_int(1.0, s), 1.0, 5.0, 200);
    let back_nod = f0_area(5.0) - f0_area(1.0);
    let disc_det: f64 = (1..=m).map(|k| 0.5 * (r_det[k - 1] + r_det[k]) * dt).sum();
    let disc_nod: f64 = (1..=m).map(|k| 0.5 * (r_nod[k - 1] + r_nod[k]) * dt).sum();
    let (mut s1, mut s2, mut z1, mut fm, mut fs) = (0.0, 0.0, 0.0, 0.0, 0.0);
    for _ in 0..n {
        let (mut x, mut area) = (0.0f64, 0.0f64); // state, and the area under it over the year
        for _ in 0..m {
            let xn = fade * x + kick * rng.normal();
            area += 0.5 * (x + xn) * dt;
            x = xn;
        }
        let (shock_d, shock_p) = (SIG * area, SIG * b(4.0) * x);
        let y = (-(disc_det + shock_d)).exp() * (-(back_det + shock_p)).exp();
        s1 += y;
        s2 += y * y;
        z1 += (-(disc_nod + shock_d)).exp() * (-(back_nod + shock_p)).exp();
        let f15 = f0(5.0) + g_int(1.0, 5.0) + SIG * (-4.0 * A).exp() * x;
        fm += f15;
        fs += f15 * f15;
    }
    let nf = n as f64;
    let mc = s1 / nf;
    let se = ((s2 / nf - mc * mc) / nf).sqrt();
    let mc_zero = z1 / nf;
    let (f_mean, f_sd) = (fm / nf, (fs / nf - (fm / nf).powi(2)).sqrt());
    let sd_exact = SIG * (-4.0 * A).exp() * ((1.0 - (-2.0 * A).exp()) / (2.0 * A)).sqrt();
    println!();
    println!("road 3: Monte Carlo, {} curves, {} steps in the year", n, m);
    println!(" f(1,5) mean   exact {:.6}   simulated {:.6}", f0(5.0) + g_int(1.0, 5.0), f_mean);
    println!(" f(1,5) sd     exact {:.6}   simulated {:.6}", sd_exact, f_sd);
    println!(" E[D(1)P(1,5)] drift condition  {:.6}  SE {:.6}  off by {:+.2} SE", mc, se, (mc - p0(5.0)) / se);
    println!(" E[D(1)P(1,5)] zero drift       {:.6}  SE {:.6}  off by {:+.2} SE", mc_zero, se, (mc_zero - p0(5.0)) / se);

    // ---- road 4: Hull-White inside HJM ----
    println!();
    println!("road 4: Hull-White inside HJM");
    let mut gap4: f64 = 0.0;
    for &t in &[1.0, 2.0, 5.0, 10.0] {
        let h = 1e-4;
        let th = (mean_r(t + h) - mean_r(t - h)) / (2.0 * h) + A * mean_r(t);
        gap4 = gap4.max((th - theta_hw(t)).abs());
        println!(" theta({:4.1})  Hull-White {:.8}   from HJM curve {:.8}", t, theta_hw(t), th);
    }
    let conv_hjm = simpson(|u| alpha(u, 1.0), 0.0, 1.0, 200);
    let conv_hw = SIG * SIG / (2.0 * A * A) * (1.0 - (-A).exp()).powi(2);
    println!(" convexity at t=1   HJM {:.10}   Hull-White {:.10}", conv_hjm, conv_hw);
    let x1 = ((1.0 - (-2.0 * A).exp()) / (2.0 * A)).sqrt(); // one-sd upward shock of the state
    let p_curve = (-simpson(|s| f1(s, x1), 1.0, 5.0, 100)).exp();
    let r1 = f1(1.0, x1);
    let p_hw = p0(5.0) / p0(1.0)
        * (b(4.0) * f0(1.0) - SIG * SIG / (4.0 * A) * (1.0 - (-2.0 * A).exp()) * b(4.0).powi(2) - b(4.0) * r1).exp();
    println!(" after +1 sd: r(1) {:.6}   P(1,5) from curve {:.9}   from r(1) {:.9}", r1, p_curve, p_hw);

    // ---- chart points ----
    println!();
    let row = |lab: &str, vals: Vec<f64>| {
        let cells: Vec<String> = vals.iter().map(|v| format!("{:5.2}", v)).collect();
        println!("{}{}", lab, cells.join(" "));
    };
    let mats: Vec<String> = (1..=10).map(|t| format!("{:5}", t)).collect();
    println!("chart, maturity T (years)   {}", mats.join(" "));
    row("chart, f(0,T) percent       ", (1..=10).map(|t| 100.0 * f0(t as f64)).collect());
    row("chart, f(1,T) +1 sd percent ", (1..=10).map(|t| 100.0 * f1(t as f64, x1)).collect());
    row("chart, f(1,T) -1 sd percent ", (1..=10).map(|t| 100.0 * f1(t as f64, -x1)).collect());
    row("chart, alpha(0,T) bp/year   ", (0..=10).map(|t| 1e4 * alpha(0.0, t as f64)).collect());

    assert!(gap1 < 1e-12, "drift: closed form vs quadrature");
    assert!((e_right - p0(5.0)).abs() < 1e-10, "exact law: drift condition makes the discounted bond fair");
    assert!((mc - p0(5.0)).abs() < 3.0 * se, "Monte Carlo lands on today's bond price");
    assert!(mc_zero - p0(5.0) > 3.0 * se, "zero drift leaves a detectable free return");
    assert!(gap4 < 1e-7, "Hull-White theta from the HJM curve");
    assert!((p_curve - p_hw).abs() < 1e-9, "the whole HJM curve is priced by r(1) alone");
    println!("ALL CHECKS PASS");
}
