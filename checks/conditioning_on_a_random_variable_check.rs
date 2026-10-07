// Conditioning on a random variable -- the same check as the Python, in Rust.
// No crates.  Monthly rainfall X (mm) and temperature Y (deg C) at one
// station are jointly normal: means 55 and 15, spreads 20 and 5, correlation
// -0.6.  E[X | Y] = g(Y) is found from the line, from the density ratio
// f(x, y)/f_Y(y) integrated numerically, and from simulated months; the
// defining property is checked on the event {Y > 20}; the kernel gives a joint
// chance; the abstract Bayes formula re-weights by Z = exp(a X)/E[exp(a X)].
// A four-season table in exact fractions, written by hand, runs Bayes with Z = X/55.
use std::f64::consts::PI;

const MX: f64 = 55.0;
const SX: f64 = 20.0;
const MY: f64 = 15.0;
const SY: f64 = 5.0;
const RHO: f64 = -0.6;
const A: f64 = 0.025;
const TWO53: f64 = 9007199254740992.0;

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 { // n even
    let h = (b - a) / n as f64;
    let mut acc = 0.0;
    for i in 1..n { acc += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h) }
    (f(a) + f(b) + acc) * h / 3.0
}

fn phi(z: f64) -> f64 { (-z * z / 2.0).exp() / (2.0 * PI).sqrt() }   // standard normal density

fn cdf(z: f64) -> f64 { 0.5 + simpson(&phi, 0.0, z.abs(), 400).copysign(z) }  // by Simpson

fn joint(x: f64, y: f64) -> f64 {                                      // the bivariate normal density
    let (u, v) = ((x - MX) / SX, (y - MY) / SY);
    let q = (u * u - 2.0 * RHO * u * v + v * v) / (1.0 - RHO * RHO);
    (-q / 2.0).exp() / (2.0 * PI * SX * SY * (1.0 - RHO * RHO).sqrt())
}

fn line(y: f64) -> f64 { MX + RHO * SX / SY * (y - MY) }               // road 1: the regression line

fn xint(f: &dyn Fn(f64) -> f64, y: f64) -> f64 {                      // integral over x of f(x) joint(x, y)
    simpson(&|x| f(x) * joint(x, y), MX - 10.0 * SX, MX + 10.0 * SX, 2000)
}

fn ratio(y: f64, w: &dyn Fn(f64) -> f64) -> f64 { xint(&|x| w(x) * x, y) / xint(w, y) }  // road 2

fn splitmix(s: u64) -> (u64, u64) {                                    // SplitMix64
    let s = s.wrapping_add(0x9E3779B97F4A7C15);
    let z = (s ^ (s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, z ^ (z >> 31))
}

fn row(v: &[f64], k: usize) -> String { v.iter().map(|t| format!("{:.*}", k, t)).collect::<Vec<_>>().join(", ") }

#[derive(Clone, Copy, PartialEq, Debug)]
struct Q(i64, i64);                                                    // an exact fraction n/d
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i64, d: i64) -> Q { let g = gcd(n, d) * d.signum(); Q(n / g, d / g) }
fn add(a: Q, b: Q) -> Q { q(a.0 * b.1 + b.0 * a.1, a.1 * b.1) }
fn mul(a: Q, b: Q) -> Q { q(a.0 * b.0, a.1 * b.1) }
fn div(a: Q, b: Q) -> Q { q(a.0 * b.1, a.1 * b.0) }
fn show(v: &[Q]) -> String {
    v.iter().map(|a| if a.1 == 1 { format!("{}", a.0) } else { format!("{}/{}", a.0, a.1) }).collect::<Vec<_>>().join(", ")
}

fn main() {
    let sc = SX * (1.0 - RHO * RHO).sqrt();                            // spread left once Y is known
    let one = |_x: f64| 1.0;
    // 1. E[X | Y = y] by the line and by the density ratio
    let ys = [5.0, 10.0, 15.0, 20.0, 25.0];
    println!("means {:.0} mm and {:.0} C, spreads {:.0} mm and {:.0} C, correlation {:.2}; tilt a = {}", MX, MY, SX, SY, RHO, A);
    println!("slope rho*sx/sy = {:.4}; spread given Y = {:.4} mm, variance {:.2}", RHO * SX / SY, sc, sc * sc);
    println!("chart, E[X|Y=y] by the line, y = 5..25: {}", row(&ys.map(line), 2));
    let dens = ys.map(|y| ratio(y, &one));
    println!("E[X|Y=y] by f(x,y)/f_Y(y), y = 5..25: {}", row(&dens, 4));
    let fy20 = xint(&one, 20.0);
    println!("f_Y(20) by integrating out x = {:.6}; by the normal formula = {:.6}", fy20, phi(1.0) / SY);
    for yc in [10.0, 15.0, 20.0] {                                      // conditional densities, % per mm
        let fy = xint(&one, yc);
        let c: Vec<f64> = (0..12).map(|i| 100.0 * joint((10 * i) as f64, yc) / fy).collect();
        println!("chart, f(x|y={:.0}) x 100, x = 0..110: {}", yc, row(&c, 2));
    }
    // 2. the defining property on B = {Y > 20}, and the kernel
    let top = MY + 10.0 * SY;
    let lhs = simpson(&|y| xint(&|x| x, y), 20.0, top, 600);
    let rhs = simpson(&|y| line(y) * phi((y - MY) / SY) / SY, 20.0, top, 600);
    let closed = MX * (1.0 - cdf(1.0)) + RHO * SX * phi(1.0);
    println!("E[X 1(Y>20)]: joint density {:.4}; E[g(Y) 1(Y>20)] {:.4}; closed form {:.4}", lhs, rhs, closed);
    let kern = simpson(&|y| (1.0 - cdf((70.0 - line(y)) / sc)) * phi((y - MY) / SY) / SY, 20.0, top, 600);
    let dbl = simpson(&|y| simpson(&|x| joint(x, y), 70.0, MX + 10.0 * SX, 400), 20.0, top, 400);
    println!("P(X>70, Y>20): kernel {:.5}; double integral {:.5}", kern, dbl);
    // 3. abstract Bayes: Q has density Z = exp(a X)/E[exp(a X)] against P
    let (qx, qy) = (MX + A * SX * SX, MY + A * RHO * SX * SY);
    let h_line = |y: f64| qx + RHO * SX / SY * (y - qy);               // road 1 under Q
    let bayes = ys.map(|y| ratio(y, &|x| (A * (x - MX)).exp()));
    println!("Var X {:.2}, Cov(X,Y) {:.2}; Q-means: X {:.2} mm, Y {:.2} C", SX * SX, RHO * SX * SY, qx, qy);
    println!("conditional shift a*sc^2 = {:.2} mm", A * sc * sc);
    println!("chart, E_Q[X|Y=y] by the Q-line, y = 5..25: {}", row(&ys.map(h_line), 2));
    println!("E_Q[X|Y=y] by E_P[ZX|Y]/E_P[Z|Y], y = 5..25: {}", row(&bayes, 4));
    let ez20 = xint(&|x| (A * (x - MX) - A * A * SX * SX / 2.0).exp(), 20.0) / fy20;
    println!("E_P[Z|Y=20] = {:.4}; forgetting to divide: E_P[ZX|Y=20] = {:.2}", ez20, bayes[3] * ez20);
    let (bx, by) = (MX + 0.1 * RHO * SX * SY, MY + 0.1 * SY * SY);      // Z = exp(0.1 Y)/E[exp(0.1 Y)]
    let r9: f64 = -0.9;                                                // the first "try changing" row
    let s9 = SX * (1.0 - r9 * r9).sqrt();
    println!("try rho -0.9: spread {:.4}, shift {:.2}, h(20) {:.2}", s9, A * s9 * s9, qx + r9 * SX / SY * (20.0 - MY - A * r9 * SX * SY));
    println!("Z from Y alone, exp(0.1 Y): Q-means {:.2}, {:.2}; E_Q[X|Y=20] = {:.4}", bx, by, bx + RHO * SX / SY * (20.0 - by));
    println!("mistake: unconditional shift 43 + 10 = {:.2}; E[Y|X] line inverted at y = 20: {:.2}",
             line(20.0) + A * SX * SX, MX + (20.0 - MY) / (RHO * SY / SX));
    // 4. simulated months, SplitMix64 seed 2026, Box-Muller normals
    let (mut st, n) = (2026u64, 200000usize);
    let mut s = [0.0f64; 11];
    for _ in 0..n {
        let (s1, u) = splitmix(st);
        let (s2, v) = splitmix(s1);
        st = s2;
        let r = (-2.0 * (((u >> 11) as f64 + 0.5) / TWO53).ln()).sqrt();
        let ang = 2.0 * PI * (v >> 11) as f64 / TWO53;
        let (z1, z2) = (r * ang.cos(), r * ang.sin());
        let y = MY + SY * z1;
        let x = MX + SX * (RHO * z1 + (1.0 - RHO * RHO).sqrt() * z2);
        let (b, z) = (if y > 20.0 { 1.0 } else { 0.0 }, (A * (x - MX) - A * A * SX * SX / 2.0).exp());
        let near = if (y - 20.0).abs() < 0.25 { 1.0 } else { 0.0 };
        let (d1, d2) = ((x - line(y)) * b, z * (x - h_line(y)) * b);
        let t = [x * b, line(y) * b, (x - line(y)) * (x - line(y)), (x - MX) * (x - MX),
                 b * (if x > 70.0 { 1.0 } else { 0.0 }), near, near * x, z * x * b, z * h_line(y) * b, d1 * d1, d2 * d2];
        for i in 0..11 { s[i] += t[i] }
    }
    let m: Vec<f64> = s.iter().map(|v| v / n as f64).collect();
    let nf = n as f64;
    println!("sim, seed 2026, {} months", n);
    println!("sim E[X 1(Y>20)] {:.4}; sim E[g(Y) 1(Y>20)] {:.4}; gap's standard error {:.4}", m[0], m[1], (m[9] / nf).sqrt());
    let se = (kern * (1.0 - kern) / nf).sqrt();
    println!("sim P(X>70, Y>20) {:.5}, standard error {:.5}, off by {:.1} standard errors", m[4], se, (m[4] - kern).abs() / se);
    println!("sim mean square error: of g(Y) {:.2}; of the constant 55 {:.2}", m[2], m[3]);
    println!("sim months with Y within 0.25 of 20: {:.0}, average rainfall {:.4}, standard error {:.2}", s[5], s[6] / s[5], sc / s[5].sqrt());
    let qclosed = qx * (1.0 - cdf(1.3)) + RHO * SX * phi(1.3);
    println!("sim E_Q[X 1(Y>20)] = E_P[Z X 1_B] {:.4}; E_Q[h(Y) 1_B] {:.4}; closed form {:.4}", m[7], m[8], qclosed);
    println!("sim gap E_Q[X 1_B] - E_Q[h(Y) 1_B]: standard error {:.4}", (m[10] / nf).sqrt());
    // 5. four seasons, two kinds of month each, all 8 months equally likely; Z = X/55
    let seasons = [30i64, 60, 90, 40];
    let (p, quarter) = (q(1, 8), q(1, 4));
    let (mut g, mut bay, mut naive, mut qs) = (vec![], vec![], vec![], vec![]);
    let mut eqx = q(0, 1);
    for &mu in &seasons {
        let (mut px, mut pzx, mut pz) = (q(0, 1), q(0, 1), q(0, 1));
        for x in [mu - 10, mu + 10] {
            let z = q(x, 55);
            px = add(px, mul(p, q(x, 1)));
            pzx = add(pzx, mul(mul(p, z), q(x, 1)));
            pz = add(pz, mul(p, z));
        }
        g.push(div(px, quarter));
        bay.push(div(pzx, pz));
        naive.push(div(pzx, quarter));
        qs.push(pz);
        eqx = add(eqx, pzx);                                            // E_Q[X] = E_P[Z X], month by month
    }
    let tower = (0..4).fold(q(0, 1), |t, s| add(t, mul(mul(quarter, div(g[s], q(55, 1))), bay[s])));  // Q(S=s) = P(S=s) E_P[X|S=s]/55
    let months: Vec<String> = seasons.iter().map(|&mu| format!("{}, {}", mu - 10, mu + 10)).collect();
    println!("table months, each 0.125, each kind 0.5 within its season, rainfall by season: {}", months.join("; "));
    println!("table g(s) = E_P[X|S=s]: {}", show(&g));
    println!("table E_Q[X|S=s] by Bayes: {}; without dividing: {}", show(&bay), show(&naive));
    println!("table Q(S=s): {}; E_Q[X] = {} directly, {} by the tower", show(&qs), show(&[eqx]), show(&[tower]));
    assert!(dens.iter().zip(ys.iter()).all(|(d, &y)| (d - line(y)).abs() < 1e-6));   // density ratio = line
    assert!((lhs - closed).abs() < 1e-6 && (rhs - closed).abs() < 1e-6);             // defining property
    assert!((kern - dbl).abs() < 1e-6 && (m[4] - kern).abs() < 4.0 * (kern / nf).sqrt());
    assert!(bayes.iter().zip(ys.iter()).all(|(b, &y)| (b - h_line(y)).abs() < 1e-6)); // Bayes = Q-line
    assert!((m[0] - m[1]).abs() < 4.0 * (m[9] / nf).sqrt() && (m[7] - m[8]).abs() < 4.0 * (m[10] / nf).sqrt());
    assert!(seasons.iter().map(|&s| q(s * s + 100, s)).collect::<Vec<Q>>() == bay && tower == eqx);  // exact table; tower under Q
    println!("ALL CHECKS PASS");
}
