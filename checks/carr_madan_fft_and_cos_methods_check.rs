// Transform pricing -- the same check as the Python, in Rust.  No crates.  Acme:
// S = 100, r = 5%, q = 2%, sigma = 20%, T = 1 year.  One object, the characteristic
// function of the log price, feeds two machines: Carr-Madan, which damps the call
// curve and inverts it with a single FFT, and COS, which expands the same law in
// cosine modes.  Rust has neither complex numbers nor erf, so both are built here:
// a complex number is a pair, and the bell-curve area is a sum of thin slices.
use std::f64::consts::PI;
type C = (f64, f64);                                  // (real part, imaginary part)
const S: f64 = 100.0; const R: f64 = 100.0; const RATE: f64 = 0.05; const Q: f64 = 0.02;
const SIG: f64 = 0.20; const T: f64 = 1.0; const ALPHA: f64 = 1.5; const ETA: f64 = 0.25;
const MEAN: f64 = (RATE - Q - 0.5*SIG*SIG)*T; const VAR: f64 = SIG*SIG*T;
const N: usize = 4096; const LOW: f64 = -3.0; const HIGH: f64 = 3.0;
const OFFSETS: [i64; 5] = [-32, -16, 0, 16, 32];
const HES: (f64, f64, f64, f64, f64) = (0.04, 2.0, 0.04, 0.30, -0.70);
fn add(z: C, w: C) -> C { (z.0 + w.0, z.1 + w.1) }
fn sub(z: C, w: C) -> C { (z.0 - w.0, z.1 - w.1) }
fn mul(z: C, w: C) -> C { (z.0*w.0 - z.1*w.1, z.0*w.1 + z.1*w.0) }
fn scale(z: C, s: f64) -> C { (z.0*s, z.1*s) }
fn size(z: C) -> f64 { z.0.hypot(z.1) }
fn div(z: C, w: C) -> C { let d = w.0*w.0 + w.1*w.1;
    ((z.0*w.0 + z.1*w.1)/d, (z.1*w.0 - z.0*w.1)/d) }
fn cexp(z: C) -> C { let e = z.0.exp(); (e*z.1.cos(), e*z.1.sin()) }
fn clog(z: C) -> C { (size(z).ln(), z.1.atan2(z.0)) }
fn csqrt(z: C) -> C { let m = size(z);                // principal branch, real part >= 0
    ((0.5*(m + z.0)).max(0.0).sqrt(), (0.5*(m - z.0)).max(0.0).sqrt().copysign(z.1)) }
fn lam() -> f64 { 2.0*PI/(N as f64*ETA) }             // the log-strike step
fn disc() -> f64 { (-RATE*T).exp() }
fn divy() -> f64 { (-Q*T).exp() }

fn ncdf(x: f64) -> f64 {                 // bell-curve area left of x, by thin slices
    if x < -12.0 { return 0.0; } else if x > 12.0 { return 1.0; }
    let (panels, h) = (4000, x/4000.0);
    let bell = |t: f64| (-0.5*t*t).exp()/(2.0*PI).sqrt();
    let mut total = bell(0.0) + bell(x);
    for i in 1..panels { total += (if i % 2 == 1 { 4.0 } else { 2.0 })*bell(i as f64*h); }
    0.5 + total*h/3.0
}
fn bs_call(strike: f64, vol: f64) -> f64 {            // the referee: the closed formula
    let vt = vol*T.sqrt();
    let d1 = ((S/strike).ln() + (RATE - Q + 0.5*vol*vol)*T)/vt;
    S*divy()*ncdf(d1) - strike*disc()*ncdf(d1 - vt)
}
fn implied_vol(target: f64, strike: f64) -> f64 {     // bisection, no library solver
    let (mut low, mut high) = (0.005, 2.0);
    for _ in 0..80 { let mid = 0.5*(low + high);
        if bs_call(strike, mid) > target { high = mid } else { low = mid } }
    0.5*(low + high)
}
// E[e^{zY}], Y = log(S_T/R): the lognormal law, then Heston in one safe grouping
fn phi_gauss(z: C) -> C { cexp(add(scale(z, MEAN), scale(mul(z, z), VAR/2.0))) }
fn phi_heston(z: C) -> C {
    let (v0, kap, th, xi, rho) = HES;
    let lin = sub(scale(z, rho*xi), (kap, 0.0));
    let root = csqrt(sub(mul(lin, lin), scale(sub(mul(z, z), z), xi*xi)));
    let top = sub(scale(lin, -1.0), root);
    let (edge, g) = (scale(top, 1.0/(xi*xi)), div(top, add(scale(lin, -1.0), root)));
    let decay = cexp(scale(scale(root, -1.0), T));
    let bee = div(mul(edge, sub((1.0, 0.0), decay)), sub((1.0, 0.0), mul(g, decay)));
    let inner = clog(div(sub((1.0, 0.0), mul(g, decay)), sub((1.0, 0.0), g)));
    let ay = scale(sub(scale(edge, T), scale(inner, 2.0/(xi*xi))), kap*th);
    cexp(add(add(scale(scale(z, RATE - Q), T), ay), scale(bee, v0)))
}
fn psi(u: f64, phi: fn(C) -> C, alpha: f64) -> C {    // the damped call curve's transform
    div(scale(phi((alpha + 1.0, u)), R*disc()), mul((alpha, u), (alpha + 1.0, u)))
}
fn fft(x: &[C]) -> Vec<C> {              // radix two, minus sign, written out here
    let n = x.len();
    if n == 1 { return x.to_vec(); }
    let even = fft(&x.iter().step_by(2).copied().collect::<Vec<C>>());
    let odd = fft(&x.iter().skip(1).step_by(2).copied().collect::<Vec<C>>());
    let mut out = vec![(0.0, 0.0); n];
    for j in 0..n/2 { let turn = mul(cexp((0.0, -2.0*PI*j as f64/n as f64)), odd[j]);
        out[j] = add(even[j], turn); out[j + n/2] = sub(even[j], turn); }
    out
}
struct Grid { freq: Vec<f64>, val: Vec<C>, trans: Vec<C>, alpha: f64 }
fn carr_madan(phi: fn(C) -> C, alpha: f64) -> Grid {
    let freq: Vec<f64> = (0..N).map(|j| (j as f64 + 0.5)*ETA).collect();
    let val: Vec<C> = freq.iter().map(|&u| psi(u, phi, alpha)).collect();
    let packed: Vec<C> = val.iter().enumerate()
        .map(|(j, &v)| mul(if j % 2 == 0 { (0.0, 1.0) } else { (0.0, -1.0) }, v)).collect();
    Grid { freq, val, trans: fft(&packed), alpha }
}
fn price(g: &Grid, off: i64, by_fft: bool) -> f64 {   // off counts steps from K = R
    let cell = (N as i64/2 + off) as usize;
    let scaling = ETA*(-g.alpha*off as f64*lam()).exp()/PI;
    if by_fft {                                       // one transform, every strike
        return scaling*mul(cexp((0.0, -PI*cell as f64/N as f64)), g.trans[cell]).0;
    }
    let mut total = (0.0, 0.0);                       // the same sum, strike by strike
    for (u, v) in g.freq.iter().zip(&g.val) {
        total = add(total, mul(cexp((0.0, -u*off as f64*lam())), *v)); }
    scaling*total.0
}
fn cos_put(phi: fn(C) -> C, strike: f64, modes: usize, low: f64, high: f64, halve: bool) -> f64 {
    let (width, edge) = (high - low, (strike/R).ln());
    let top = if edge <= low { low } else { high.min(edge) };
    let mut total = 0.0;
    for n in 0..modes {
        let w = n as f64*PI/width;
        let (turn, ph) = (mul(cexp((0.0, -w*low)), phi((0.0, w))), w*(top - low));
        let flat = if n == 0 { top - low } else { ph.sin()/w };
        let curved = if n == 0 { top.exp() - low.exp() }
            else { (top.exp()*(ph.cos() + w*ph.sin()) - low.exp())/(1.0 + w*w) };
        let weight = if n == 0 && halve { 0.5 } else { 1.0 };
        total += weight*2.0/width*turn.0*2.0/width*(strike*flat - R*curved);
    }
    disc()*width/2.0*total
}
fn cos_call(phi: fn(C) -> C, strike: f64, modes: usize) -> f64 {
    cos_put(phi, strike, modes, LOW, HIGH, true) + S*divy() - strike*disc() }

fn main() {
    let strikes: Vec<f64> = OFFSETS.iter().map(|&o| R*(o as f64*lam()).exp()).collect();
    let (grid_g, grid_h) = (carr_madan(phi_gauss, ALPHA), carr_madan(phi_heston, ALPHA));
    let grid_0 = carr_madan(phi_gauss, 0.0);
    let forward = ((RATE - Q)*T).exp();
    let drift_ok = [phi_gauss, phi_heston].iter().all(|f| (f((1.0, 0.0)).0 - forward).abs() < 1e-14);
    let (hes_fft, hes_cos) = (price(&grid_h, 0, true), cos_call(phi_heston, 100.0, 256));
    let put128 = cos_put(phi_gauss, 100.0, 128, LOW, HIGH, true);
    let vols: Vec<Vec<f64>> = [&grid_g, &grid_h].iter().map(|g| OFFSETS.iter().zip(&strikes)
        .map(|(&o, &k)| 100.0*implied_vol(price(g, o, true), k)).collect()).collect();
    let near = ((100.30/R).ln()/lam()).round() as i64;
    let breaks: Vec<(&str, f64, f64)> = vec![
        ("no damping, alpha = 0", price(&grid_0, 0, true), bs_call(100.0, SIG)),
        ("nearest node read for K = 100.30, node at 100.00", price(&grid_g, near, true), bs_call(100.30, SIG)),
        ("COS window [-0.3, 0.3], 128 modes, the put", cos_put(phi_gauss, 100.0, 128, -0.3, 0.3, true), put128),
        ("COS constant mode at full weight, the put", cos_put(phi_gauss, 100.0, 128, LOW, HIGH, false), put128)];
    let cells = |vals: &Vec<f64>| vals.iter().map(|v| format!("{:>8.2}", v)).collect::<String>();
    println!("Acme, one year: S = 100, r = 5%, q = 2%, sigma = 20%, log prices against R = 100");
    println!("grid: N = {}, eta = {}, cutoff N eta = {:.0}, lambda = {:.9}, half-window = {:.6}", N, ETA, N as f64*ETA, lam(), PI/ETA);
    println!("damped transform at zero frequency, psi(0){:>25.9}", psi(0.0, phi_gauss, ALPHA).0);
    println!("forward check, Phi(1) against e^(r-q)T = {:.12}, both laws: {}", forward, if drift_ok { "yes" } else { "no" });
    for (name, phi) in [("lognormal law", phi_gauss as fn(C) -> C), ("Heston law", phi_heston)] {
        println!("size of psi at u = 8, 16, 32, 64, {:<14}{}", name, [8.0, 16.0, 32.0, 64.0].iter()
                 .map(|&u| format!("{:>14.12}", size(psi(u, phi, ALPHA)))).collect::<Vec<_>>().join(" "));
    }
    println!("\none FFT of {} points, five strikes read off the same grid:", N);
    println!("{:>11}{:>17}{:>17}{:>17}{:>17}", "strike", "Carr-Madan FFT", "direct sum", "closed formula", "Heston FFT");
    for (&off, &strike) in OFFSETS.iter().zip(&strikes) {
        println!("{:>11.6}{:>17.9}{:>17.9}{:>17.9}{:>17.9}", strike, price(&grid_g, off, true),
                 price(&grid_g, off, false), bs_call(strike, SIG), price(&grid_h, off, true));
    }
    println!("\nCOS on the log window [-3, 3]: the put first, then the call by parity");
    println!("{:>7}{:>17}{:>17}{:>17}{:>17}", "modes", "lognormal put", "lognormal call", "Heston put", "Heston call");
    for modes in [8usize, 16, 32, 64, 128, 256] {
        println!("{:>7}{:>17.9}{:>17.9}{:>17.9}{:>17.9}", modes,
                 cos_put(phi_gauss, 100.0, modes, LOW, HIGH, true), cos_call(phi_gauss, 100.0, modes),
                 cos_put(phi_heston, 100.0, modes, LOW, HIGH, true), cos_call(phi_heston, 100.0, modes));
    }
    println!("the house numbers, from the closed formula: put 6.330080627550, call 9.227005508154");
    println!("Heston at K = 100, the FFT road minus the COS road{:>23.12}", hes_fft - hes_cos);
    println!("\nimplied volatility backed out of those five prices, percent:");
    println!("  strike        {}", cells(&strikes));
    println!("  lognormal law {}", cells(&vols[0]));
    println!("  Heston law    {}", cells(&vols[1]));
    println!("\nwhat breaks:");
    for (label, wrong, right) in &breaks {
        println!("  {:<50}{:>12.6}   right: {:.6}", label, wrong, right);
    }
    assert!(OFFSETS.iter().zip(&strikes).all(|(&o, &k)| (price(&grid_g, o, true) - bs_call(k, SIG)).abs() < 1e-8));
    assert!(OFFSETS.iter().all(|&o| (price(&grid_g, o, true) - price(&grid_g, o, false)).abs() < 1e-9));
    assert!((cos_call(phi_gauss, 100.0, 128) - bs_call(100.0, SIG)).abs() < 1e-11);
    assert!((bs_call(100.0, SIG) - 9.227005508154).abs() < 1e-12);
    assert!(drift_ok && (hes_fft - hes_cos).abs() < 1e-8);
    assert!(vols[0].iter().all(|v| (v - 100.0*SIG).abs() < 1e-6));
    assert!(vols[1][0] > vols[1][2] && vols[1][2] > vols[1][4] && hes_fft < bs_call(100.0, SIG));
    assert!(price(&grid_0, 0, true) < 0.0 && breaks.iter().all(|(_, w, r)| (w - r).abs() > 0.01));
    println!("ALL CHECKS PASS");
}
