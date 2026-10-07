// Cheaper Monte Carlo -- the same check as the Python, in Rust.  No crates.  Nothing imported knows
// an answer: the fractions come from the recurrence the Monte Carlo pricing card prints, the
// bell-curve area and both reference prices from Simpson's rule written out here in one dimension
// and in two, and the area's inverse is a rational fit the run checks against the area itself.
const S: f64 = 100.0; const K: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02;  // the house
const SIG: f64 = 0.20; const T: f64 = 1.0; const T1: f64 = 0.5; const T2: f64 = 1.0;  // market, and
const SEED: u64 = 20260919; const N: usize = 16000; const MOD: u64 = 1 << 32;  // the two dates
const AA: [f64; 4] = [2.50662823884, -18.61500062529, 41.39119773534, -25.44106049637];
const BB: [f64; 4] = [-8.47351093090, 23.08336743743, -21.06224101826, 3.13082909833];
const CC: [f64; 9] = [0.3374754822726147, 0.9761690190917186, 0.1607979714918209, 0.0276438810333863,
    0.0038405729373609, 0.0003951896511919, 0.0000321767881768, 0.0000002888167364, 0.0000003960315187];
const MU: f64 = R - Q - 0.5 * SIG * SIG;     // the pricing world's drift, in logs
const NAMES: [&str; 4] = ["plain", "antithetic pairs", "stratified slices", "control variate"];
fn disc() -> f64 { (-R * T).exp() }   fn eq() -> f64 { S * (-Q * T).exp() }   // discount; S e^-qT
fn vt() -> f64 { SIG * T.sqrt() }   fn rot() -> f64 { 0.5f64.sqrt() }   // a year's wiggle; the turn
fn a1() -> f64 { SIG * T1.sqrt() }   fn a2() -> f64 { SIG * (T2 - T1).sqrt() }   // each leg's wiggle
fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * std::f64::consts::PI).sqrt() }   // its height
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let (h, mut total) = ((b - a) / n as f64, f(a) + f(b));  // the area under f from a to b
    for i in 1..n { total += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h) }
    total * h / 3.0 }
// area to the left of x, by that same rule
fn ncdf(x: f64) -> f64 { if x < -9.0 { 0.0 } else if x > 9.0 { 1.0 } else { 0.5 + simpson(phi, 0.0, x, 4000) } }
fn ninv(u: f64) -> f64 {                     // the shock with u of the bell curve below it
    let (y, mut x) = (u - 0.5, CC[8]);
    if y.abs() < 0.42 {                      // the middle: one polynomial in y*y over another
        let w = y * y;
        return y * (((AA[3] * w + AA[2]) * w + AA[1]) * w + AA[0])
            / ((((BB[3] * w + BB[2]) * w + BB[1]) * w + BB[0]) * w + 1.0);
    }
    let w = (-(if y < 0.0 { u } else { 1.0 - u }).ln()).ln(); // the tails: a polynomial in that
    for i in (0..8).rev() { x = x * w + CC[i] }
    if y > 0.0 { x } else { -x }
}
// one step of the recurrence, then a fraction landing strictly inside 0 and 1
fn nxt(g: &mut u64) -> f64 { *g = (1664525 * *g + 1013904223) % MOD; (*g as f64 + 0.5) / MOD as f64 }
fn smallest(vs: &[f64]) -> f64 { vs.iter().cloned().fold(f64::INFINITY, f64::min) }
fn stats(vs: &[f64]) -> (f64, f64) {         // the average, and the error bar on that average
    let (m, n) = (vs.iter().sum::<f64>() / vs.len() as f64, vs.len());
    (m, (vs.iter().map(|v| (v - m) * (v - m)).sum::<f64>() / (n - 1) as f64 / n as f64).sqrt()) }
fn control(xs: &[f64], ys: &[f64], known: f64) -> (f64, f64, f64, f64) {
    let n = xs.len();                        // subtract the control's own sampling slip
    let (mx, my) = (xs.iter().sum::<f64>() / n as f64, ys.iter().sum::<f64>() / n as f64);
    let cov = (0..n).map(|i| (xs[i] - mx) * (ys[i] - my)).sum::<f64>() / (n - 1) as f64;
    let vx = xs.iter().map(|x| (x - mx) * (x - mx)).sum::<f64>() / (n - 1) as f64;
    let vy = ys.iter().map(|y| (y - my) * (y - my)).sum::<f64>() / (n - 1) as f64;
    let beta = cov / vy;                     // the slope that deletes as much noise as it can
    let adj: Vec<f64> = xs.iter().zip(ys).map(|(x, y)| x - beta * (y - known)).collect();
    let s = stats(&adj); (beta, cov / (vx * vy).sqrt(), s.0, s.1) }
fn call(zs: &[f64]) -> [f64; 4] {            // the one-year call, and the share as its control
    let end = S * (MU * T + vt() * zs[0]).exp();
    [disc() * (end - K).max(0.0), disc() * end, 0.0, 0.0] }
fn asian(zs: &[f64]) -> [f64; 4] {           // one path: the arithmetic ticket, then the geometric
    let mid = S * (MU * T1 + a1() * zs[0]).exp();
    let end = mid * (MU * (T2 - T1) + a2() * zs[1]).exp();
    [disc() * (0.5 * (mid + end) - K).max(0.0), disc() * ((mid * end).sqrt() - K).max(0.0), mid, end] }
fn grid2(which: usize, n: usize) -> f64 {    // either ticket with no pricing formula at all
    simpson(|x| simpson(|y| phi(x) * phi(y) * asian(&[x, y])[which], -8.0, 8.0, n), -8.0, 8.0, n) }
// N paths: the shocks, the payoff on each, and its control on each
fn stream<F: Fn(&[f64]) -> [f64; 4]>(pay: F, dim: usize, seed: u64) -> (Vec<Vec<f64>>, Vec<f64>, Vec<f64>) {
    let (mut g, mut shocks) = (seed, Vec::new());
    for _ in 0..N { let mut zs = Vec::new();
        for _ in 0..dim { zs.push(ninv(nxt(&mut g))) } shocks.push(zs) }
    let (mut xs, mut ys) = (Vec::new(), Vec::new());
    for zs in &shocks { let t = pay(zs); xs.push(t[0]); ys.push(t[1]) }
    (shocks, xs, ys) }
fn stratified<F: Fn(&[f64]) -> [f64; 4]>(pay: F, seed: u64, mode: u32) -> (f64, f64) {
    // mode 0: the only shock.  1: the end point sliced, middle free.  2: leg one sliced, wrong way.
    let (mut g, slices, mut total, mut spread) = (seed, N / 2, 0.0, 0.0);  // two draws per slice
    for j in 0..slices {
        let mut vals = [0.0f64; 2];
        for k in 0..2 {
            let v = ninv((j as f64 + nxt(&mut g)) / slices as f64);  // this slice's own share
            let w = if mode > 0 { ninv(nxt(&mut g)) } else { 0.0 };  // the direction left free
            let zs: Vec<f64> = if mode == 0 { vec![v] }
                else if mode == 1 { vec![(v + w) * rot(), (v - w) * rot()] } else { vec![v, w] };
            vals[k] = pay(&zs)[0];
        }
        total += 0.5 * (vals[0] + vals[1]);
        spread += 0.25 * (vals[0] - vals[1]) * (vals[0] - vals[1]);
    }
    (total / slices as f64, spread.sqrt() / slices as f64) }
fn report<F: Fn(&[f64]) -> [f64; 4]>(title: String, pay: F, shocks: &[Vec<f64>], xs: &[f64],
        ys: &[f64], known: f64, exact: f64, mode: u32) -> (Vec<(f64, f64)>, f64, f64, f64) {
    let lows = xs[..N / 2].to_vec();         // the same paths, and the same paths flipped
    let highs: Vec<f64> = shocks[..N / 2].iter().map(|zs| pay(&zs.iter().map(|z| -z).collect::<Vec<f64>>())[0]).collect();
    let (beta, rho, cv, se_cv) = control(xs, ys, known);
    let pairs: Vec<f64> = lows.iter().zip(&highs).map(|(a, b)| 0.5 * (a + b)).collect();
    let rows = vec![stats(xs), stats(&pairs), stratified(&pay, SEED, mode), (cv, se_cv)];
    println!("{}", title);
    println!("  sampler               estimate    se, c   off by, c   paths worth, millions");
    for (name, row) in NAMES.iter().zip(&rows) {
        println!("  {:<19}{:11.6} {:8.2} {:11.2}{:23.3}", name, row.0, 100.0 * row.1,
                 100.0 * (row.0 - exact), N as f64 * (rows[0].1 / row.1) * (rows[0].1 / row.1) / 1e6);
    }
    let mrho = control(&lows, &highs, 0.0).1;    // how a path and its mirror move together
    println!("  mirror correlation {:+.6}, control slope {:.6}, control correlation {:.6}", mrho, beta, rho);
    let mut pool = lows.clone(); pool.extend(&highs); (rows, stats(&pool).1, mrho, rho) }
fn main() {
    let d1 = ((S / K).ln() + (R - Q + 0.5 * SIG * SIG) * T) / vt();
    let call_f = eq() * ncdf(d1) - K * disc() * ncdf(d1 - vt());      // the pilot card's formula
    let call_g = simpson(|z| phi(z) * call(&[z])[0], ((K / S).ln() - MU * T) / vt(), 9.0, 2000);
    let (vg, tbar) = (SIG * SIG * (3.0 * T1 + T2) / 4.0, 0.5 * (T1 + T2));  // geometric log spread
    let (sg, egm) = (vg.sqrt(), S * (MU * tbar + 0.5 * vg).exp());    // its spread; its own average
    let g2 = (S.ln() + MU * tbar - K.ln()) / sg;
    let geo_f = disc() * (egm * ncdf(g2 + sg) - K * ncdf(g2));        // Kemna and Vorst, 1990
    let (ari_g, geo_g) = (grid2(0, 800), grid2(1, 800));
    let slip = (1..20).map(|p| (ncdf(ninv(p as f64 / 20.0)) - p as f64 / 20.0).abs()).fold(0.0, f64::max);
    let (shocks_a, xa, ya) = stream(asian, 2, SEED);
    let (shocks_c, xc, yc) = stream(call, 1, SEED);
    let gaps: Vec<f64> = (0..N).map(|i| xa[i] - ya[i]).collect();
    println!("Cheaper Monte Carlo: the Acme call, and an average-price ticket on two dates");
    println!("S = {:.2}  K = {:.2}  r = {:.0}%  q = {:.0}%  sigma = {:.0}%  T = {:.0} year; the \
average takes the price at {:.2} and at {:.2}", S, K, R * 100.0, Q * 100.0, SIG * 100.0, T, T1, T2);
    println!("seed {}; {} payoff evaluations per sampler: {} mirror pairs, or {} slices with two \
draws each; se and off-by in cents", SEED, N, N / 2, N / 2);
    println!();
    println!("exact prices");
    println!("  Acme call          formula      {:11.6}    one-shock slices  {:11.6}", call_f, call_g);
    println!("  geometric ticket   Kemna-Vorst  {:11.6}    two-shock grid    {:11.6}", geo_f, geo_g);
    println!("  arithmetic ticket  no formula                  two-shock grid    {:11.6}", ari_g);
    println!("  the geometric average by hand: spread {:.6}, average {:.6}, N(g1) {:.6}, N(g2) {:.6}",
             sg, egm, ncdf(g2 + sg), ncdf(g2));
    println!("  what the control leaves to sample: {:.6} - {:.6} = {:.6}", ari_g, geo_f, ari_g - geo_f);
    println!("  the inverse against the area: worst slip over 19 points, in billionths {:.3}", slip * 1e9);
    println!();
    println!("the first three paths, and how close the two tickets run");
    for i in 0..3 {
        let a = asian(&shocks_a[i]);
        println!("  path {}  shocks {:9.6} {:9.6}  prices {:9.4} {:9.4}  averages {:9.4} {:9.4}  \
X {:7.4}  Y {:7.4}  X - Y {:7.4}", i + 1, shocks_a[i][0], shocks_a[i][1], a[2], a[3], 0.5 * (a[2]
            + a[3]), (a[2] * a[3]).sqrt(), a[0], a[1], a[0] - a[1]);
    }
    println!("  X - Y over {} paths: average {:.6}, largest {:.6}, smallest {:.6}", N, gaps.iter().sum::<f64>()
             / N as f64, gaps.iter().cloned().fold(f64::NEG_INFINITY, f64::max), smallest(&gaps));
    println!();
    let (rows_c, pool_c, mrho_c, _) = report(format!("the Acme call, four samplers, exact price {:.6}", call_f),
                                  call, &shocks_c, &xc, &yc, eq(), call_f, 0);
    println!();
    let (rows_a, _, mrho_a, rho_a) = report(format!("the arithmetic ticket, four samplers, exact price {:.6}", ari_g),
                             asian, &shocks_a, &xa, &ya, geo_f, ari_g, 1);
    println!();
    let (bad, wrong_way) = (control(&xc, &yc, S).2, stratified(asian, SEED, 2));
    println!("what breaks");
    println!("  mirrors pooled as {} lone paths: se quoted {:.2} c, honest {:.2} c", N, 100.0 * pool_c, 100.0 * rows_c[1].1);
    println!("  control average read as S {:.2}, not S e^-qT {:.6}: the call comes out at {:.4}, \
off by {:+.4}", S, eq(), bad, bad - rows_c[3].0);
    println!("  leg one sliced, not the end point: {:.4}, se {:.2} c against {:.2} c",
             wrong_way.0, 100.0 * wrong_way.1, 100.0 * rows_a[2].1);
    println!();
    println!("bar, se in cents on the arithmetic ticket: {}", NAMES.iter().zip(&rows_a)
        .map(|(n, r)| format!("{} {:.2}", n, 100.0 * r.1)).collect::<Vec<String>>().join("  "));
    let shock: Vec<f64> = (0..9).map(|i| -1.0 + 0.5 * i as f64).collect();
    let pv: Vec<[f64; 4]> = shock.iter().map(|&z| asian(&[z, z])).collect();
    for (label, vals) in [("chart, shock      ", shock.clone()), ("chart, arithmetic ", pv.iter().map(|p| p[0]).collect()),
                          ("chart, geometric  ", pv.iter().map(|p| p[1]).collect())] {
        println!("  {}{}", label, vals.iter().map(|v| format!("{:8.2}", v)).collect::<Vec<String>>().join(" "));
    }
    assert!((call_f - 9.227005508154).abs() < 1e-9, "own bell-curve area against the pilot's price");
    assert!((call_g - call_f).abs() < 1e-8, "the call by slices against the call by formula");
    assert!((geo_g - geo_f).abs() < 1e-4, "the grid reproduces the one ticket price with a formula");
    assert!(smallest(&gaps) >= 0.0, "a geometric average never beats an arithmetic one");
    assert!(slip < 1e-8, "the inverse really inverts the area");
    assert!((rows_a[3].0 - ari_g).abs() < 2.0 * rows_a[3].1, "controlled ticket against the grid price");
    assert!((rows_c[2].0 - call_f).abs() < 3.0 * rows_c[2].1, "sliced call against the formula price");
    assert!(mrho_c < 0.0 && mrho_a < 0.0 && rows_a[1].1 < rows_a[0].1, "mirrors anti-correlate, so a pair is quieter");
    assert!(((rows_a[3].1 / rows_a[0].1).powi(2) - (1.0 - rho_a * rho_a)).abs() < 1e-12 && rho_a > 0.999,
            "the bar falls by exactly 1 - rho^2");
    println!("ALL CHECKS PASS");
}
