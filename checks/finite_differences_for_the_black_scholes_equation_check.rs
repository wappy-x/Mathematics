// Pricing on a grid -- the same check as the Python, in Rust.  No crates.  Rust has
// no erf, so the bell-curve area is built the honest way: thin slices under the curve
// (Simpson).  The tridiagonal solver and the grid march are written out here too.
use std::f64::consts::PI;
const S0: f64 = 100.0; const K: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02;
const SIG: f64 = 0.20; const T: f64 = 1.0;
const XMAX: f64 = 1.0;                      // grid edge in x = ln(S/K): five sigma sqrt(T)
const A: f64 = 0.5 * SIG * SIG; const B: f64 = R - Q - 0.5 * SIG * SIG;  // spread, slide

fn phi(z: f64) -> f64 { (-0.5 * z * z).exp() / (2.0 * PI).sqrt() }   // bell-curve height
fn simpson<F: Fn(f64) -> f64>(f: F, lo: f64, hi: f64, n: usize) -> f64 {
    let step = (hi - lo) / n as f64;
    let mut s = f(lo) + f(hi);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(lo + i as f64 * step); }
    s * step / 3.0
}
fn ncdf(z: f64) -> f64 {        // bell-curve area left of z: a half, plus the slice 0 to z
    if z < -12.0 { 0.0 } else if z > 12.0 { 1.0 } else { 0.5 + simpson(phi, 0.0, z, 4000) }
}
fn formula(call: bool) -> f64 {     // the closed form: an independent road to the price
    let vt = SIG * T.sqrt();
    let d1 = ((S0 / K).ln() + (R - Q + 0.5 * SIG * SIG) * T) / vt;
    if call { return S0 * (-Q * T).exp() * ncdf(d1) - K * (-R * T).exp() * ncdf(d1 - vt); }
    K * (-R * T).exp() * ncdf(vt - d1) - S0 * (-Q * T).exp() * ncdf(-d1)
}
fn thomas(sub: &[f64], diag: &[f64], sup: &[f64], rhs: &[f64]) -> Vec<f64> {
    let n = diag.len();                     // sweep down, then back up: O(n) work
    let (mut c, mut d, mut out) = (vec![0.0; n], rhs.to_vec(), vec![0.0; n]);
    c[0] = sup[0] / diag[0]; d[0] = rhs[0] / diag[0];
    for i in 1..n {
        let m = diag[i] - sub[i] * c[i - 1];
        c[i] = sup[i] / m; d[i] = (rhs[i] - sub[i] * d[i - 1]) / m;
    }
    out[n - 1] = d[n - 1];
    for i in (0..n - 1).rev() { out[i] = d[i] - c[i] * out[i + 1]; }
    out
}
fn cell_average(h: f64, call: bool) -> f64 {    // the payoff averaged across the strike's cell
    if call { K * ((h / 2.0).exp() - 1.0 - h / 2.0) / h } else { K * ((-h / 2.0).exp() - 1.0 + h / 2.0) / h }
}
fn edges(tau: f64, call: bool, xmax: f64) -> (f64, f64) {   // the far edges: true far out
    if call { return (0.0, K * (xmax.exp() * (-Q * tau).exp() - (-R * tau).exp())); }
    (K * ((-R * tau).exp() - (-xmax).exp() * (-Q * tau).exp()), 0.0)
}
// theta: 0 explicit, 1 implicit, 1/2 Crank-Nicolson.  Returns the last row, the strike node
// after every step, the largest size anywhere after every step, and the solves' residual.
fn run(theta: f64, m: usize, n: usize, call: bool, smooth: bool, xmax: f64)
       -> (Vec<f64>, Vec<f64>, Vec<f64>, f64) {
    let (h, k) = (2.0 * xmax / m as f64, T / n as f64);
    let mut v: Vec<f64> = (0..=m).map(|i| {
        let s = K * (-xmax + i as f64 * h).exp();
        if call { (s - K).max(0.0) } else { (K - s).max(0.0) }
    }).collect();
    if smooth { v[m / 2] = cell_average(h, call); }
    let (nu, eta, rk) = (A * k / (h * h), B * k / (2.0 * h), R * k);
    let (lo, mid, hi) = (nu - eta, 2.0 * nu + rk, nu + eta);
    let (sub, diag, sup) = (vec![-theta * lo; m - 1], vec![1.0 + theta * mid; m - 1],
                            vec![-theta * hi; m - 1]);
    let (mut centre, mut peak, mut resid) = (Vec::new(), Vec::new(), 0.0_f64);
    for step in 0..n {
        let (o0, om) = edges(step as f64 * k, call, xmax);       // the old row's own edges
        v[0] = o0; v[m] = om;
        let mut rhs: Vec<f64> = (1..m)
            .map(|i| v[i] + (1.0 - theta) * (lo * v[i - 1] - mid * v[i] + hi * v[i + 1]))
            .collect();
        let (e0, em) = edges((step + 1) as f64 * k, call, xmax); // the new row's edges
        rhs[0] += theta * lo * e0; rhs[m - 2] += theta * hi * em;
        let inner = thomas(&sub, &diag, &sup, &rhs);
        for i in 0..m - 1 {                                     // put the answer back in
            let (left, right) = (if i > 0 { sub[i] * inner[i - 1] } else { 0.0 },
                                if i < m - 2 { sup[i] * inner[i + 1] } else { 0.0 });
            resid = resid.max((diag[i] * inner[i] + left + right - rhs[i]).abs());
        }
        v = std::iter::once(e0).chain(inner).chain(std::iter::once(em)).collect();
        centre.push(v[m / 2]);
        peak.push(v.iter().fold(0.0_f64, |t, x| t.max(x.abs())));
    }
    (v, centre, peak, resid)
}
fn line(name: &str, vals: &[f64]) {     // one label, then the numbers to six decimals
    println!("{:<45}{}", name, vals.iter().map(|v| format!("{:>11.6}", v)).collect::<String>()); }
fn row(name: &str, vals: &[f64], w: usize, dp: usize) {  // a table row at a chosen width
    println!("{:<12}{}", name, vals.iter().map(|v| format!("{:>w$.dp$}", v)).collect::<String>()); }
fn sci(x: f64, p: usize) -> String {        // Python's exponent form: 1.200e+03, 1.14e-13
    let s = format!("{:.*e}", p, x);
    let (mantissa, e) = s.split_once('e').unwrap(); let n: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", mantissa, if n < 0 { '-' } else { '+' }, n.abs())
}
fn main() {
    let (m0, n0) = (200usize, 200usize);
    let (h0, k0) = (2.0 * XMAX / m0 as f64, T / n0 as f64);
    let (nu0, eta0, rk0) = (A * k0 / (h0 * h0), B * k0 / (2.0 * h0), R * k0);
    let k5 = T / 500.0;
    let (nu1, eta1, rk1) = (A * k5 / (h0 * h0), B * k5 / (2.0 * h0), R * k5);
    println!("Acme call, one year: S = {:.2}, K = {:.2}, r = 5%, q = 2%, sigma = 20%", S0, K);
    println!("grid: x = ln(S/K) from {:.2} to {:.2}, so S from {:.2} to {:.2}",
             -XMAX, XMAX, K * (-XMAX).exp(), K * XMAX.exp());
    println!("      M = {} cells of h = {:.6} across, N = {} steps of k = {:.6} up", m0, h0, n0, k0);
    line("a = sigma^2/2", &[A]);
    line("b = r - q - sigma^2/2", &[B]);
    line("nu = a k / h^2", &[nu0]);
    line("eta = b k / (2 h)", &[eta0]);
    line("r k", &[rk0]);
    line("payoff averaged across the strike's cell", &[cell_average(h0, true)]);
    line("explicit row   nu-eta, 1-2nu-rk, nu+eta", &[nu0 - eta0, 1.0 - 2.0 * nu0 - rk0, nu0 + eta0]);
    line("implicit row  -nu+eta, 1+2nu+rk, -nu-eta", &[eta0 - nu0, 1.0 + 2.0 * nu0 + rk0, -nu0 - eta0]);
    line("CN row        sides halved, middle 1+nu+rk/2", &[0.5 * (eta0 - nu0), 1.0 + nu0 + 0.5 * rk0, -0.5 * (nu0 + eta0)]);
    line("explicit row with 500 steps instead of 200", &[nu1 - eta1, 1.0 - 2.0 * nu1 - rk1, nu1 + eta1]);
    line("payoff one cell above the strike, K(e^h - 1)", &[K * (h0.exp() - 1.0)]);
    line("that row's first step at the strike node", &[(1.0 - 2.0 * nu1 - rk1) * cell_average(h0, true)
         + (nu1 + eta1) * K * (h0.exp() - 1.0)]);
    let (cn, centre, _, resid) = run(0.5, m0, n0, true, true, XMAX);
    let (im, pt) = (run(1.0, m0, n0, true, true, XMAX).0, run(0.5, m0, n0, false, true, XMAX).0);
    let (ex, rough) = (run(0.0, m0, 500, true, true, XMAX).0, run(0.5, m0, n0, true, false, XMAX).0);
    let (narrow, wide) = (run(0.5, m0, n0, true, true, 0.2).0, run(0.5, m0, n0, true, true, 3.0).0);
    let (c, p) = (formula(true), formula(false));
    println!();
    line("1 Crank-Nicolson, 200 x 200", &[cn[m0 / 2]]);
    line("2 Black-Scholes formula", &[c]);
    line("  grid minus formula", &[cn[m0 / 2] - c]);
    line("3 implicit, 200 x 200", &[im[m0 / 2]]);
    line("4 explicit, 200 x 500", &[ex[m0 / 2]]);
    line("5 put, Crank-Nicolson, 200 x 200", &[pt[m0 / 2]]);
    line("  call minus put, both off the grid", &[cn[m0 / 2] - pt[m0 / 2]]);
    line("  S e^-qT - K e^-rT", &[S0 * (-Q * T).exp() - K * (-R * T).exp()]);
    line("  put by formula", &[p]);
    println!("6 largest residual left by the 200 solves     {}", sci(resid, 2));
    println!();
    println!("refinement, Crank-Nicolson, same domain:");
    println!("   M x N       h         k        call      error");
    let mut errs: Vec<f64> = Vec::new();
    for m in [50usize, 100, 200, 400] {
        let last = run(0.5, m, m, true, true, XMAX).0;
        errs.push(last[m / 2] - c);
        println!("  {:4} x {:4}  {:.6}  {:.6}  {:.6}  {:+.6}",
                 m, m, 2.0 * XMAX / m as f64, T / m as f64, last[m / 2], errs[errs.len() - 1]);
    }
    println!("what breaks:");
    line("  kink left unaveraged in the strike cell", &[rough[m0 / 2]]);
    line("  domain x in [-0.2, 0.2], same 200 cells", &[narrow[m0 / 2]]);
    line("  domain x in [-3, 3], same 200 cells", &[wide[m0 / 2]]);
    let (_, uns, upeak, _) = run(0.0, m0, n0, true, true, XMAX);
    println!();
    println!("explicit on the 200 x 200 grid, nu = 1: price at the strike node after step");
    row("  1 to 8", &uns[..8], 8, 2);
    println!("  largest size anywhere after steps 10, 20 and 50: {} {} {}",
             sci(upeak[9], 3), sci(upeak[19], 3), sci(upeak[49], 3));
    println!("  the 'price' after all 200 steps: {}", sci(uns[n0 - 1], 2));
    let spots: Vec<f64> = (0..11).map(|j| K * (-0.5 + 0.1 * j as f64).exp()).collect();
    println!("today's price across the last row, Crank-Nicolson:");
    row("  S", &spots, 7, 2);
    row("  grid", &(0..11).map(|j| cn[50 + 10 * j]).collect::<Vec<f64>>(), 7, 2);
    row("  payoff", &spots.iter().map(|s| (s - K).max(0.0)).collect::<Vec<f64>>(), 7, 2);
    println!("the strike node with 3, 6, 9 and 12 months to go, Crank-Nicolson:");
    let slices = [centre[49], centre[99], centre[149], centre[199]];
    row("  dollars", &slices, 10, 2);
    row("  six d.p.", &slices, 10, 6);
    assert!((cn[m0 / 2] - c).abs() < 2.0e-4, "grid price against the closed form");
    assert!((ex[m0 / 2] - c).abs() < 5.0e-3, "explicit road against the closed form");
    assert!((im[m0 / 2] - c).abs() < 8.0e-3, "implicit road against the closed form");
    assert!((1..m0).map(|i| (cn[i] - pt[i] - K * ((-XMAX + i as f64 * h0 - Q * T).exp()
            - (-R * T).exp())).abs()).fold(0.0_f64, f64::max) < 1.0e-4, "parity at every node");
    assert!(resid < 1.0e-10, "each Thomas solution must satisfy its own equations");
    assert!(errs[1] / errs[2] > 3.0 && errs[2] / errs[3] > 3.0, "halving h must cut the error by four");
    assert!(upeak[49] > 1.0e6, "the explicit scheme must blow up when nu = 1");
    assert!((rough[m0 / 2] - c).abs() > 20.0 * (cn[m0 / 2] - c).abs(), "averaging the cell earns its place");
    println!("ALL CHECKS PASS");
}
