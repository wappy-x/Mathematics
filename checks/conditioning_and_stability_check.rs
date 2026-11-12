// Conditioning and stability -- the check behind the card.  std only, no crates.
// Two straight roads, y = m1*x + c1 and y = m2*x + c2, cross where x = (c2 - c1)/(m1 - m2).
// Road 1: the condition number kappa from its formula.  Road 2: kappa measured by
// nudging each datum.  Road 3: exact answers (integers, algebra) against the
// floating-point methods, so every error printed is a true error.
const U: f64 = 1.0 / 9007199254740992.0; // 2^-53, the unit roundoff

fn cross(d: &[f64]) -> f64 { (d[3] - d[1]) / (d[0] - d[2]) }

fn cramer(r: &[f64]) -> f64 { (r[2] * r[4] - r[5] * r[1]) / (r[0] * r[4] - r[3] * r[1]) } // x from six stored coefficients

fn kappa(d: &[f64; 4]) -> f64 {
    (d[0].abs() + d[2].abs()) / (d[0] - d[2]).abs() + (d[1].abs() + d[3].abs()) / (d[3] - d[1]).abs()
}

fn kappa_nudged(d: &[f64], f: fn(&[f64]) -> f64) -> f64 { // each datum nudged up and down by one part in a million
    let (h, x0) = (1e-6, f(d));
    let mut total = 0.0;
    for i in 0..d.len() {
        let (mut up, mut dn) = (d.to_vec(), d.to_vec());
        up[i] *= 1.0 + h;
        dn[i] *= 1.0 - h;
        total += (f(&up) - f(&dn)).abs() / (2.0 * h * x0.abs());
    }
    total
}

fn solve(r1: [f64; 3], r2: [f64; 3], swap: bool) -> (f64, f64) { // rows (a, b, r) of a*x + b*y = r
    let (p, q) = if swap && r2[0].abs() > r1[0].abs() { (r2, r1) } else { (r1, r2) };
    let l = q[0] / p[0]; // the multiplier: how many copies of the pivot row to take away
    let y = (q[2] - l * p[2]) / (q[1] - l * p[1]);
    ((p[2] - p[1] * y) / p[0], y)
}

fn rel_err_case2(xh: f64, a: f64) -> f64 { ((xh - 1.0) - a * xh).abs() } // |xh(1 - a) - 1|, true x = 1/(1 - a)

fn main() {
    // ---- case 1: a fork.  Road A: y = 0.1x.  Road B: y = 0.101x - 2.  Metres. ----
    let d1 = [0.100, 0.0, 0.101, -2.0];
    let x1 = 2.0 * 1000.0 / (101.0 - 100.0); // exact: 2 m closed at 1 m per 1000 m, in integers
    let (k1, k1n) = (kappa(&d1), kappa_nudged(&d1, cross));
    let (k_m1, k_m2) = (d1[0].abs() / (d1[0] - d1[2]).abs(), d1[2].abs() / (d1[0] - d1[2]).abs());
    let (k_c1, k_c2) = (d1[1].abs() / (d1[3] - d1[1]).abs(), d1[3].abs() / (d1[3] - d1[1]).abs());
    let x1h = cross(&d1);
    let err1 = (x1h - x1).abs() / x1;
    println!("case 1, fork: roads y = 0.1x and y = 0.101x - 2, metres");
    println!("exact crossing x                  {:.2} m", x1);
    println!("kappa by formula                  {:.4}   (m1 {:.4}, m2 {:.4}, c1 {:.4}, c2 {:.4})", k1, k_m1, k_m2, k_c1, k_c2);
    println!("kappa by nudging each datum      {:.4}", k1n);
    println!("angle between roads {:.4} degrees, digits at risk log10 kappa {:.2}", (0.101f64.atan() - 0.1f64.atan()).to_degrees(), k1.log10());
    println!("unit roundoff u {:.2e}, 3u {:.2e}", U, 3.0 * U);
    println!("float formula: true rel error     {:.2e}   bound kappa*3u {:.2e}, ratio {:.1}", err1, k1 * 3.0 * U, k1 * 3.0 * U / err1);
    let dl = 0.001;
    let xs = cross(&[0.1, 0.0, 0.101 * (1.0 + dl), -2.0]);
    let lo = cross(&[0.1 * (1.0 - dl), 0.0, 0.101 * (1.0 + dl), -2.0 * (1.0 - dl)]);
    let hi = cross(&[0.1 * (1.0 + dl), 0.0, 0.101 * (1.0 - dl), -2.0 * (1.0 + dl)]);
    let x1pc = cross(&[0.1, 0.0, 0.101 * 0.99, -2.0]);
    println!("m2 read 0.1% high: crossing       {:.2} m, moved {:.2} m = {:.2} %", xs, xs - x1, 100.0 * (xs - x1) / x1);
    println!("  first-order: kappa_m2 x 0.1%    {:.2} % = {:.2} m", 100.0 * k_m2 * 0.001, 2000.0 * k_m2 * 0.001);
    println!("all data 0.1% off, worst case     {:.2} m to {:.2} m", lo, hi);
    println!("  first-order: x(1 -+ kappa*0.1%) {:.2} m to {:.2} m", 2000.0 * (1.0 - k1 * 0.001), 2000.0 * (1.0 + k1 * 0.001));
    println!("m2 read 1% low: crossing          {:.2} m", x1pc);
    println!("  first-order predicts            {:.2} m", 2000.0 * (1.0 + k_m2 * 0.01));
    let dxdm2 = (d1[3] - d1[1]).abs() / (d1[0] - d1[2]).powi(2);
    println!("absolute slope |dx/dm2|           {:.0} m per unit slope", dxdm2);
    for k in 0..13 { // chart: road B's offset north of road A, gap = (m2 - m1) x + c2
        let xg = 200.0 * k as f64;
        println!("chart, x {}, B {:.3}, B 0.1% steep {:.3}, B 1% shallow {:.3}", 200 * k, 0.001 * xg - 2.0, 0.001101 * xg - 2.0, -0.00001 * xg - 2.0);
    }

    // ---- case 2: a 45-degree crossing stored as a*x + y = 1 and x + y = 2 ----
    let a = 6.123233995736766e-17; // leftover of a rotation: what cos(90 degrees) returns in doubles
    let d2 = [-a, 1.0, -1.0, 2.0]; // the same roads in slope form: y = -a x + 1, y = -x + 2
    let k2 = kappa(&d2);
    let k6 = kappa_nudged(&[a, 1.0, 1.0, 1.0, 1.0, 2.0], cramer); // stored form
    let (xn, yn) = solve([a, 1.0, 1.0], [1.0, 1.0, 2.0], false);
    let (xp, yp) = solve([a, 1.0, 1.0], [1.0, 1.0, 2.0], true);
    let xf = cross(&d2);
    let (en, ep, ef) = (rel_err_case2(xn, a), rel_err_case2(xp, a), rel_err_case2(xf, a));
    println!("case 2, 45-degree crossing: a*x + y = 1 and x + y = 2");
    println!("a {:.3e}   cos(pi/2) library {:.3e}", a, (std::f64::consts::PI / 2.0).cos());
    println!("angle between roads {:.4} degrees", ((-a).atan() - (-1.0f64).atan()).to_degrees());
    println!("kappa by formula                  {:.4}   kappa by nudging {:.4}", k2, kappa_nudged(&d2, cross));
    println!("kappa on the six stored coefficients, by nudging {:.4}", k6);
    println!("no swap: x-hat {:.4}  y-hat {:.4}   true rel error {:.2e}", xn, yn, en);
    println!("  multiplier 1/a {:.3e}; road B becomes {:.0} y = {:.0}", 1.0 / a, 1.0 - 1.0 / a, 2.0 - 1.0 / a);
    println!("  road B's 2 would have to be {:.4}", xn + yn);
    println!("swap:    x-hat {:.4}  y-hat {:.4}   true rel error {:.2e}", xp, yp, ep);
    println!("formula: x-hat {:.4}               true rel error {:.2e}", xf, ef);
    println!("bound for a stable method, kappa*3u {:.2e}, ratio to swap {:.1}, to formula {:.1}", k2 * 3.0 * U, k2 * 3.0 * U / ep, k2 * 3.0 * U / ef);

    // ---- house example: a tracker adds 0.1 ten million times ----
    let mut s = 0.0f64;
    for _ in 0..10_000_000 { s += 0.1; }
    let two55 = 36028797018963968.0f64; // 2^55: the stored 0.1 is an integer over 2^55
    let t_exact = (0.1f64 * two55) as u128 * 10_000_000; // exact sum, in units of 2^-55
    let s_exact = (s * 8589934592.0) as u128 * (1u128 << 22); // s is a whole number of 2^-33
    let err_t = (t_exact - s_exact) as f64 / two55;
    println!("tracker: total {:.5}, true {:.5}, error {:.5}, kappa of a sum of positives 1", s, t_exact as f64 / two55, err_t);

    // ---- try changing ----
    let (xw, xw2) = (cross(&[0.1, 0.0, 0.2, -2.0]), cross(&[0.1, 0.0, 0.2 * 1.001, -2.0]));
    println!("try: m2 0.2: kappa {:.4}, x {:.2} m, 0.1% steeper {:.2} m", kappa(&[0.1, 0.0, 0.2, -2.0]), xw, xw2);
    println!("try: m2 0.1001: kappa {:.4}, x {:.2} m", kappa(&[0.1, 0.0, 0.1001, -2.0]), cross(&[0.1, 0.0, 0.1001, -2.0]));
    println!("try: m2 0.01% high: x {:.2} m", cross(&[0.1, 0.0, 0.101 * 1.0001, -2.0]));
    for t in [1e-3, 1e-8] {
        let (tn, _) = solve([t, 1.0, 1.0], [1.0, 1.0, 2.0], false);
        println!("try: a {:.0e}: no-swap rel error {:.2e}", t, rel_err_case2(tn, t));
    }

    // ---- asserts: each compares against an independently computed value ----
    assert!((x1h - x1).abs() < 1e-9, "float formula must land on the integer answer");
    assert!((k1 - k1n).abs() < 1e-4, "formula and nudged kappa must agree");
    assert!(err1 <= k1 * 3.0 * U, "a backward-stable formula stays inside kappa*3u");
    assert!(((xs - x1) / x1 + k_m2 * 0.001).abs() < 0.1 * k_m2 * 0.001, "first order within 10 % at 0.1 %");
    assert!(x1pc < 0.0, "a 1 % slope error sends the crossing behind the start");
    assert!((k2 - kappa_nudged(&d2, cross)).abs() < 1e-4, "case 2 kappa, two roads");
    assert!(en > 1e10 * k2 * 3.0 * U, "well-conditioned problem, unstable method");
    assert!(ep <= k2 * 3.0 * U && ef <= k2 * 3.0 * U, "swap and formula are stable");
    assert!((err_t - 1.6e-4).abs() < 1e-5, "tracker total is off by about 0.00016");
    println!("ALL CHECKS PASS");
}
