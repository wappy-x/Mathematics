// Zero-order hold and Tustin -- the same check as the Python, in Rust.  No crates.
// A thermostat's sample cup: heater power u (W) in, sensor reading y (K above room) out.
//   dx1/dt = (R u - x1)/tau1  (cup),  dx2/dt = (x1 - x2)/tau2  (sensor),  y = x2.
//   G(s) = R / ((tau1 s + 1)(tau2 s + 1)),  sampled at fs = 10 Hz, T = 0.1 s.
// ZOH by three roads: Van Loan matrix exponential; closed form; RK4 over one held sample.
// Tustin by two: substitute s = (2/T)(z-1)/(z+1); trapezoid integration of the ODE.
use std::f64::consts::PI;

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }                        // a complex number, written out
fn cx(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { cx(a.re + b.re, a.im + b.im) }   fn sub(a: C, b: C) -> C { cx(a.re - b.re, a.im - b.im) }
fn mul(a: C, b: C) -> C { cx(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn div(a: C, b: C) -> C { let d = b.re * b.re + b.im * b.im; cx((a.re * b.re + a.im * b.im) / d, (a.im * b.re - a.re * b.im) / d) }
fn sc(k: f64, a: C) -> C { cx(k * a.re, k * a.im) }
fn abs(a: C) -> f64 { (a.re * a.re + a.im * a.im).sqrt() }   fn deg(a: C) -> f64 { a.im.atan2(a.re).to_degrees() }
fn ejw(th: f64) -> C { cx(th.cos(), th.sin()) }             // e^(j th), a point on the unit circle

const R: f64 = 0.5; const TAU1: f64 = 1.0; const TAU2: f64 = 0.25; const P: f64 = 10.0; const T: f64 = 0.1;
const P1: f64 = 1.0 / TAU1; const P2: f64 = 1.0 / TAU2;    // pole speeds, 1/s
type M2 = [[f64; 2]; 2]; const A: M2 = [[-P1, 0.0], [P2, -P2]]; const B: [f64; 2] = [R * P1, 0.0];

fn mm(x: &Vec<Vec<f64>>, y: &Vec<Vec<f64>>) -> Vec<Vec<f64>> {
    let n = x.len();
    (0..n).map(|i| (0..n).map(|j| (0..n).map(|k| x[i][k] * y[k][j]).sum()).collect()).collect()
}
fn expm(mut m: Vec<Vec<f64>>) -> Vec<Vec<f64>> {    // scaling and squaring, then Taylor
    let (n, mut sq) = (m.len(), 0);
    while m.iter().map(|r| r.iter().map(|v| v.abs()).sum::<f64>()).fold(0.0, f64::max) > 0.5 {
        m = m.iter().map(|r| r.iter().map(|v| v / 2.0).collect()).collect(); sq += 1;
    }
    let mut e: Vec<Vec<f64>> = (0..n).map(|i| (0..n).map(|j| if i == j { 1.0 } else { 0.0 }).collect()).collect();
    let mut term = e.clone();                       // term k is M^k / k!
    for k in 1..20 {
        term = mm(&term, &m).iter().map(|r| r.iter().map(|v| v / k as f64).collect()).collect();
        for i in 0..n { for j in 0..n { e[i][j] += term[i][j] } }
    }
    for _ in 0..sq { e = mm(&e, &e) }               // undo the halvings: e^M = (e^(M/2^sq))^(2^sq)
    e
}
fn zoh_vanloan(t: f64) -> (M2, [f64; 2]) {          // exp([[A, B], [0, 0]] T) = [[Ad, Bd], [0, 1]]
    let e = expm(vec![vec![A[0][0] * t, A[0][1] * t, B[0] * t], vec![A[1][0] * t, A[1][1] * t, B[1] * t], vec![0.0; 3]]);
    ([[e[0][0], e[0][1]], [e[1][0], e[1][1]]], [e[0][2], e[1][2]])
}
fn zoh_closed(t: f64) -> (M2, [f64; 2]) {           // e^(At) written out for this lower-triangular A
    let (e1, e2, c) = ((-P1 * t).exp(), (-P2 * t).exp(), P2 / (P2 - P1));
    ([[e1, 0.0], [c * (e1 - e2), e2]], [R * (1.0 - e1), R * c * ((1.0 - e1) - P1 / P2 * (1.0 - e2))])
}
fn f(x: [f64; 2], u: f64) -> [f64; 2] { [A[0][0] * x[0] + B[0] * u, A[1][0] * x[0] + A[1][1] * x[1]] }
fn rk4(mut x: [f64; 2], u: f64, t: f64) -> [f64; 2] { // input held at u for one sample
    let h = t / 2000.0;
    let st = |x: [f64; 2], k: [f64; 2], a: f64| [x[0] + a * k[0], x[1] + a * k[1]];
    for _ in 0..2000 {
        let k1 = f(x, u); let k2 = f(st(x, k1, h / 2.0), u); let k3 = f(st(x, k2, h / 2.0), u); let k4 = f(st(x, k3, h), u);
        for i in 0..2 { x[i] += h / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]) }
    }
    x
}
fn zoh_rk4(t: f64) -> (M2, [f64; 2]) {
    let (c0, c1) = (rk4([1.0, 0.0], 0.0, t), rk4([0.0, 1.0], 0.0, t));
    ([[c0[0], c1[0]], [c0[1], c1[1]]], rk4([0.0, 0.0], 1.0, t))
}
fn tustin_coeffs(t: f64, cw: Option<f64>) -> ([f64; 3], [f64; 3]) { // G(s) = b0/(s^2 + a1 s + a0), s -> c (z-1)/(z+1)
    let c = cw.unwrap_or(2.0 / t);
    let (b0, a1, a0) = (R * P1 * P2, P1 + P2, P1 * P2);
    let den = [c * c + a1 * c + a0, 2.0 * a0 - 2.0 * c * c, c * c - a1 * c + a0];
    ([b0 / den[0], 2.0 * b0 / den[0], b0 / den[0]], [1.0, den[1] / den[0], den[2] / den[0]])
}
fn run_tf(num: &[f64; 3], den: &[f64; 3], u: f64, n: usize) -> Vec<f64> { // y[k] = sum num u[k-i] - sum den[i] y[k-i]
    let mut y: Vec<f64> = vec![];
    for k in 0..n {
        y.push((0..3).filter(|&i| k >= i).map(|i| num[i] * u).sum::<f64>() - (1..3).filter(|&i| k >= i).map(|i| den[i] * y[k - i]).sum::<f64>());
    }
    y
}
fn run_trap(t: f64, u: f64, n: usize) -> Vec<f64> { // x[k] = x[k-1] + T/2 (f(x[k-1], u[k-1]) + f(x[k], u[k]))
    let (a, c, d) = (1.0 - A[0][0] * t / 2.0, -A[1][0] * t / 2.0, 1.0 - A[1][1] * t / 2.0);
    let (mut x, mut up, mut ys) = ([0.0, 0.0], 0.0, vec![]);
    for _ in 0..n {
        let fx = f(x, up);
        let r = [x[0] + t / 2.0 * (fx[0] + B[0] * u), x[1] + t / 2.0 * fx[1]];
        let x0 = r[0] / a; x = [x0, (r[1] - c * x0) / d]; up = u; ys.push(x[1]);
    }
    ys
}
fn run_ss(ad: &M2, bd: &[f64; 2], u: f64, n: usize) -> Vec<f64> {
    let (mut x, mut ys) = ([0.0, 0.0], vec![]);
    for _ in 0..n { ys.push(x[1]); x = [ad[0][0] * x[0] + bd[0] * u, ad[1][0] * x[0] + ad[1][1] * x[1] + bd[1] * u]; }
    ys
}
fn y_exact(t: f64) -> f64 { P * R * (1.0 - P2 / (P2 - P1) * (-P1 * t).exp() + P1 / (P2 - P1) * (-P2 * t).exp()) }
fn g(s: C) -> C { div(cx(R, 0.0), mul(add(sc(TAU1, s), cx(1.0, 0.0)), add(sc(TAU2, s), cx(1.0, 0.0)))) }
fn gzoh(z: C, ad: &M2, bd: &[f64; 2]) -> C {        // C (zI - Ad)^-1 Bd
    let (a, b, c, d) = (sub(z, cx(ad[0][0], 0.0)), cx(-ad[0][1], 0.0), cx(-ad[1][0], 0.0), sub(z, cx(ad[1][1], 0.0)));
    div(add(sc(-bd[0], c), sc(bd[1], a)), sub(mul(a, d), mul(b, c)))
}
fn gzoh_step(z: C) -> C {                           // (1 - 1/z) times the z-transform of the sampled step response
    let (e1, e2) = ((-P1 * T).exp(), (-P2 * T).exp());
    let zm1 = sub(z, cx(1.0, 0.0)); sc(R, add(sub(cx(1.0, 0.0), sc(P2 / (P2 - P1), div(zm1, sub(z, cx(e1, 0.0))))), sc(P1 / (P2 - P1), div(zm1, sub(z, cx(e2, 0.0))))))
}
fn gt(z: C, num: &[f64; 3], den: &[f64; 3]) -> C {
    let z2 = mul(z, z); div(add(add(sc(num[0], z2), sc(num[1], z)), cx(num[2], 0.0)), add(add(sc(den[0], z2), sc(den[1], z)), cx(den[2], 0.0)))
}
fn db(a: C) -> f64 { 20.0 * abs(a).log10() }
fn tiny(x: f64) -> String { if x < 1e-12 { "below 1e-12".to_string() } else { format!("{:.2e}", x) } }
fn maxgap(a: &[f64], b: &[f64]) -> f64 { a.iter().zip(b).map(|(p, q)| (p - q).abs()).fold(0.0, f64::max) }

fn main() {
    let ((av, bv), (ac, bc), (ar, br)) = (zoh_vanloan(T), zoh_closed(T), zoh_rk4(T));
    println!("inputs: R = {} K/W, tau1 = {:.1} s, tau2 = {} s, step {:.0} W, fs = {:.0} Hz, T = {} s, Nyquist {:.0} Hz", R, TAU1, TAU2, P, 1.0 / T, T, 0.5 / T);
    println!("G(s) = {:.1} / (s^2 + {:.1} s + {:.1});  steady rise {:.1} K", R * P1 * P2, P1 + P2, P1 * P2, P * R);
    for (lab, ad, bd) in [("Van Loan", av, bv), ("closed  ", ac, bc), ("RK4     ", ar, br)] {
        println!("ZOH {}  Ad = [{:.9} {:.9}; {:.9} {:.9}]  Bd = [{:.9} {:.9}]", lab, ad[0][0], ad[0][1], ad[1][0], ad[1][1], bd[0], bd[1]);
    }
    let (rt, ct) = (20.0, 2.5); let et = expm(vec![vec![-T / (rt * ct), T / ct], vec![0.0, 0.0]]);   // card 08's tip, one lump: Van Loan for dx/dt = -x/(Rt Ct) + u/Ct
    println!("card 08 tip, tau = {:.0} s, ZOH by Van Loan: a = {:.6}, b = {:.6} degC per W per tick", rt * ct, et[0][0], et[0][1]);
    let (num, den) = tustin_coeffs(T, None);
    let (c, a1, a0) = (2.0 / T, P1 + P2, P1 * P2);
    println!("Tustin, c = 2/T = {:.0}: raw den = [{:.0} {:.0} {:.0}], raw num = [{:.0} {:.0} {:.0}]", c, c * c + a1 * c + a0, 2.0 * a0 - 2.0 * c * c, c * c - a1 * c + a0, R * a0, 2.0 * R * a0, R * a0);
    println!("Tustin  num = [{:.9} {:.9} {:.9}]  den = [1 {:.9} {:.9}]", num[0], num[1], num[2], den[1], den[2]);
    println!("poles   s = -1, -4   ZOH e^(sT) = {:.6}, {:.6}   Tustin (1+sT/2)/(1-sT/2) = {:.6}, {:.6}", ac[0][0], ac[1][1], (1.0 - P1 * T / 2.0) / (1.0 + P1 * T / 2.0), (1.0 - P2 * T / 2.0) / (1.0 + P2 * T / 2.0));
    let n = 31; let (yz, yt, ytr) = (run_ss(&ac, &bc, P, n), run_tf(&num, &den, P, n), run_trap(T, P, n));
    let ex: Vec<f64> = (0..n).map(|k| y_exact(k as f64 * T)).collect();
    let (ez, et) = (maxgap(&yz, &ex), maxgap(&yt, &ex));
    println!("step 10 W: max |ZOH - exact| over 3 s {} K;  max |Tustin - exact| = {:.3} mK", tiny(ez), et * 1000.0);
    println!("first samples (K): exact {:.7} {:.7}  ZOH {:.7} {:.7}  Tustin {:.7} {:.7} {:.7}", ex[1], ex[2], yz[1], yz[2], yt[0], yt[1], yt[2]);
    println!("Tustin: difference equation vs trapezoid ODE, max gap {} K", tiny(maxgap(&yt, &ytr)));
    for k in (0..n).step_by(3) {
        println!("chart, t = {:3.1} s  exact {:5.2} K  ZOH {:5.2} K  Tustin {:5.2} K  Tustin error {:+7.3} mK", k as f64 * T, ex[k], yz[k], yt[k], 1000.0 * (yt[k] - ex[k]));
    }
    let shifted: Vec<f64> = (0..n).map(|k| y_exact(k as f64 * T + T / 2.0)).collect();
    println!("Tustin vs exact shifted half a sample earlier, max gap {:.3} mK", 1000.0 * maxgap(&yt, &shifted));
    // ---- frequency response on the unit circle, z = e^(j w T) ----
    let (mut gap_zoh, mut gap_warp) = (0.0f64, 0.0f64);
    for fhz in [0.1, 0.5, 1.0, 2.0, 3.0, 4.0, 4.5] {
        let w = 2.0 * PI * fhz; let z = ejw(w * T); let wa = 2.0 / T * (w * T / 2.0).tan();
        let (gz, gtv) = (gzoh(z, &ac, &bc), gt(z, &num, &den));
        gap_zoh = gap_zoh.max(abs(sub(gz, gzoh_step(z)))); gap_warp = gap_warp.max(abs(sub(gtv, g(cx(0.0, wa)))));
        println!("chart, f = {:3.1} Hz  G {:7.2} dB  ZOH {:7.2} dB  Tustin {:7.2} dB  (= G at {:5.2} Hz)", fhz, db(g(cx(0.0, w))), db(gz), db(gtv), wa / (2.0 * PI));
    }
    println!("ZOH: state-space vs step-response z-transform, max gap {};  Tustin vs G at warped frequency, max gap {}", tiny(gap_zoh), tiny(gap_warp));
    let w1 = 2.0 * PI; let z1 = ejw(w1 * T);
    println!("phase at 1 Hz: G {:.2} deg, ZOH {:.2} deg, G - wT/2 {:.2} deg, Tustin {:.2} deg; hold delay T/2 = {} s = {:.2} deg", deg(g(cx(0.0, w1))), deg(gzoh(z1, &ac, &bc)), deg(g(cx(0.0, w1))) - (w1 * T / 2.0).to_degrees(), deg(gt(z1, &num, &den)), T / 2.0, (w1 * T / 2.0).to_degrees());
    let w0 = 2.0 * PI * 2.0; let (numw, denw) = tustin_coeffs(T, Some(w0 / (w0 * T / 2.0).tan())); let z0 = ejw(w0 * T);
    println!("prewarp at {:.0} Hz: Tustin {:.3} dB, prewarped {:.3} dB, G {:.3} dB", w0 / (2.0 * PI), db(gt(z0, &num, &den)), db(gt(z0, &numw, &denw)), db(g(cx(0.0, w0))));
    // ---- what breaks ----
    let te = 0.6; let (mut xe, mut ye) = ([0.0, 0.0], vec![]);
    for _ in 0..21 { ye.push(xe[1]); let dx = f(xe, P); xe = [xe[0] + te * dx[0], xe[1] + te * dx[1]]; }
    let (az6, _) = zoh_closed(te);
    println!("forward Euler at T = {} s: poles {:.2}, {:.2}; sensor after 20 steps {:.1} K (exact {:.4} K); ZOH poles {:.4}, {:.4}; Euler needs T < 2 tau2 = {:.2} s", te, 1.0 - P1 * te, 1.0 - P2 * te, ye[20], y_exact(20.0 * te), az6[0][0], az6[1][1], 2.0 * TAU2);
    let (n1, d1) = tustin_coeffs(1.0, None); let (a1m, b1m) = zoh_closed(1.0); let ex1: Vec<f64> = (0..8).map(|k| y_exact(k as f64)).collect();
    println!("fs = 1 Hz: max |Tustin - exact| {:.3} K; max |ZOH - exact| {} K", maxgap(&run_tf(&n1, &d1, P, 8), &ex1), tiny(maxgap(&run_ss(&a1m, &b1m, P, 8), &ex1)));
    let z4 = ejw(2.0 * PI * 4.0 * T); let g4 = g(cx(0.0, 2.0 * PI * 4.0)); let fl = (2.0 * PI * 4.0 * T / 2.0).atan() / (PI * T); let zl = ejw(2.0 * PI * fl * T);
    println!("Tustin read at 4 Hz: {:.2} dB vs G at 4 Hz {:.2} dB, error {:.2} dB", db(gt(z4, &num, &den)), db(g4), db(gt(z4, &num, &den)) - db(g4));
    println!("G's 4 Hz lands in Tustin at (2/T) atan(wT/2) = {:.2} Hz: Tustin there {:.2} dB, G at 4 Hz {:.2} dB", fl, db(gt(zl, &num, &den)), db(g4));
    println!("heater only heats: holding 2.0 K below room needs u = {:.1} W", -2.0 / R);
    let (n5, d5) = tustin_coeffs(0.5, None); let ex5: Vec<f64> = (0..12).map(|k| y_exact(k as f64 * 0.5)).collect();
    println!("try: fs = 2 Hz: max |Tustin - exact| {:.3} K", maxgap(&run_tf(&n5, &d5, P, 12), &ex5));

    let flat = |a: &M2, b: &[f64; 2]| vec![a[0][0], a[0][1], a[1][0], a[1][1], b[0], b[1]];
    assert!(maxgap(&flat(&av, &bv), &flat(&ac, &bc)) < 1e-12);           // series vs closed form
    assert!(maxgap(&flat(&ar, &br), &flat(&ac, &bc)) < 1e-10);           // RK4 vs closed form
    assert!(ez < 1e-12);                                                // ZOH samples vs the exact step response
    assert!(maxgap(&yt, &ytr) < 1e-12);                                 // Tustin difference equation vs trapezoid ODE
    assert!(gap_zoh < 1e-12 && gap_warp < 1e-12);                       // two ZOH transfer functions agree; Tustin = G at warped frequency
    assert!((deg(gzoh(z1, &ac, &bc)) - deg(g(cx(0.0, w1))) + (w1 * T / 2.0).to_degrees()).abs() < 0.1); // ZOH phase = G - wT/2 at 1 Hz
    assert!((db(gt(z0, &numw, &denw)) - db(g(cx(0.0, w0)))).abs() < 1e-9); // prewarped Tustin is exact at 2 Hz
    assert!((ye[20] - y_exact(20.0 * te)).abs() > 100.0);               // Euler at 0.6 s runs away
    println!("ALL CHECKS PASS");
}
