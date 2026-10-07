// Rating transition matrix -- the check behind the card.  Rust std only, no crates.
// Three grades: 0 Solid, 1 Shaky, 2 Default (absorbing).  Same rows, same labels as the Python.
type M = [[f64; 3]; 3];
const P: M = [[0.90, 0.09, 0.01], [0.10, 0.80, 0.10], [0.00, 0.00, 1.00]];
const G: [&str; 3] = ["Solid", "Shaky", "Default"];

fn mul(a: &M, b: &M) -> M {
    let mut r = [[0.0; 3]; 3];
    for i in 0..3 { for j in 0..3 { let mut s = 0.0; for k in 0..3 { s += a[i][k] * b[k][j]; } r[i][j] = s; } }
    r
}
// road 1: multiply the one-year table n times
fn power(a: &M, n: usize) -> M {
    let mut r = [[0.0; 3]; 3];
    for i in 0..3 { r[i][i] = 1.0; }
    for _ in 0..n { r = mul(&r, a); }
    r
}
// road 2: list every grade path, add up those ending in Default
fn by_paths(i: usize, n: usize) -> f64 {
    if n == 0 { return if i == 2 { 1.0 } else { 0.0 }; }
    let mut s = 0.0;
    for j in 0..3 { s += P[i][j] * by_paths(j, n - 1); }
    s
}
// road 3: survival = A mu1^n + B mu2^n from the living block's eigenvalues, no matrix powers
fn eig() -> (f64, f64) {
    let (a, b, c, d) = (P[0][0], P[0][1], P[1][0], P[1][1]);
    let root = ((a - d) * (a - d) + 4.0 * b * c).sqrt();
    ((a + d + root) / 2.0, (a + d - root) / 2.0)
}
fn by_eigen(i: usize, n: usize) -> f64 {
    let (mu1, mu2) = eig();
    let s1 = P[i][0] + P[i][1];
    let a = (s1 - mu2) / (mu1 - mu2);
    1.0 - (a * mu1.powf(n as f64) + (1.0 - a) * mu2.powf(n as f64))
}
// our own random numbers: 64-bit linear congruential, same constants and seed as the Python
struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        (self.0 >> 11) as f64 / 2f64.powi(53)
    }
    fn step(&mut self, m: &M, i: usize) -> usize {
        let u = self.uniform();
        let mut cum = 0.0;
        for j in 0..3 { cum += m[i][j]; if u < cum { return j; } }
        2
    }
}
// road 4: follow firms one year at a time
fn simulate(rng: &mut Rng, i: usize, n: usize, firms: usize) -> f64 {
    let mut hit = 0usize;
    for _ in 0..firms {
        let mut g = i;
        for _ in 0..n { g = rng.step(&P, g); }
        if g == 2 { hit += 1; }
    }
    hit as f64 / firms as f64
}
// solve 1 - e^(-h T) = pd for h; one root since the left side only rises
fn hazard_by_bisection(pd: f64, t: f64) -> f64 {
    let (mut lo, mut hi) = (0.0f64, 10.0f64);
    for _ in 0..200 {
        let mid = (lo + hi) / 2.0;
        if 1.0 - (-mid * t).exp() < pd { lo = mid; } else { hi = mid; }
    }
    (lo + hi) / 2.0
}
fn row(label: &str, vals: &[f64]) {
    let mut s = format!("{:<40}", label);
    for v in vals { s += &format!("{:>11.6}", v); }
    println!("{}", s);
}
fn pd_with(m: &M, i: usize, n: usize) -> f64 { power(m, n)[i][2] }

fn main() {
    let mut rng = Rng(20260928);
    let (p2, p5) = (power(&P, 2), power(&P, 5));
    for i in 0..2 { row(&format!("P^2 row {} (to Solid Shaky Default)", G[i]), &p2[i]); }
    for i in 0..2 { row(&format!("P^5 row {} (to Solid Shaky Default)", G[i]), &p5[i]); }
    let hand2 = P[0][0] * P[0][2] + P[0][1] * P[1][2] + P[0][2] * 1.0;
    row("PD Solid 2y: 0.9x0.01 + 0.09x0.10 + 0.01", &[hand2]);
    let pd5 = p5[0][2];
    let mc = simulate(&mut rng, 0, 5, 200000);
    let se = (pd5 * (1.0 - pd5) / 200000.0).sqrt();
    row("PD Solid 5y  road 1 matrix power", &[pd5]);
    row("PD Solid 5y  road 2 all 243 paths", &[by_paths(0, 5)]);
    row("PD Solid 5y  road 3 eigenvalues", &[by_eigen(0, 5)]);
    row("PD Solid 5y  road 4 simulated 200000", &[mc]);
    row("  simulation standard error", &[se]);
    row("PD Shaky 5y  roads 1 and 3", &[p5[1][2], by_eigen(1, 5)]);
    let (mu1, mu2) = eig();
    row("eigenvalues mu1 mu2", &[mu1, mu2]);
    let a0 = (P[0][0] + P[0][1] - mu2) / (mu1 - mu2);
    row("eigen weights A, 1 - A, from Solid", &[a0, 1.0 - a0]);
    row("long-run yearly default 1 - mu1", &[1.0 - mu1]);
    let (h_log, h_bis) = (-(1.0 - pd5).ln() / 5.0, hazard_by_bisection(pd5, 5.0));
    row("avg hazard Solid 5y  log formula", &[h_log]);
    row("avg hazard Solid 5y  bisection", &[h_bis]);
    println!();
    println!("   T   PD Solid   PD Shaky  hazard Solid  hazard Shaky  next-year PD Solid");
    let mut prev = 0.0;
    for t in 1..=10usize {
        let pt = power(&P, t);
        let (ps, pk) = (pt[0][2], pt[1][2]);
        println!("{:>4} {:>10.6} {:>10.6} {:>13.6} {:>13.6} {:>18.6}", t, ps, pk,
                 -(1.0 - ps).ln() / t as f64, -(1.0 - pk).ln() / t as f64, (ps - prev) / (1.0 - prev));
        prev = ps;
    }
    let mut l = [String::from("chart, year          "), String::from("chart, PD Solid %    "),
                 String::from("chart, PD Shaky %    "), String::from("chart, 1% x years    ")];
    for t in 0..=10usize {
        let pt = power(&P, t);
        l[0] += &format!("{:>6}", t);
        l[1] += &format!("{:>6.2}", 100.0 * pt[0][2]);
        l[2] += &format!("{:>6.2}", 100.0 * pt[1][2]);
        l[3] += &format!("{:>6.2}", t as f64);
    }
    for s in &l { println!("{}", s); }
    println!();
    row("wrong: 5 x 1%", &[5.0 * P[0][2]]);
    row("wrong: 2 x 1%", &[2.0 * P[0][2]]);
    row("wrong: Solid forever, 1 - 0.99^5", &[1.0 - (1.0 - P[0][2]).powf(5.0)]);
    row("wrong: hazard = PD / T", &[pd5 / 5.0]);
    // cohort estimator: one simulated year for 100000 Solid and 100000 Shaky firms
    let mut counts = [[0usize; 3]; 2];
    for i in 0..2 { for _ in 0..100000 { let j = rng.step(&P, i); counts[i][j] += 1; } }
    let mut phat: M = [[0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 1.0]];
    for i in 0..2 { for j in 0..3 { phat[i][j] = counts[i][j] as f64 / 100000.0; } }
    for i in 0..2 { row(&format!("cohort row {}", G[i]), &phat[i]); }
    row("PD Solid 5y from the cohort table", &[power(&phat, 5)[0][2]]);
    row("try: Solid->Shaky 18%, stay 81%", &[pd_with(&[[0.81, 0.18, 0.01], P[1], P[2]], 0, 5)]);
    row("try: Shaky defaults 20%, stays 70%", &[pd_with(&[P[0], [0.10, 0.70, 0.20], P[2]], 0, 5)]);
    row("try: Shaky never recovers (0, 90%, 10%)", &[pd_with(&[P[0], [0.0, 0.90, 0.10], P[2]], 0, 5)]);
    row("try: 30 years", &[pd_with(&P, 0, 30)]);

    assert!((hand2 - p2[0][2]).abs() < 1e-15, "two-year default: three paths by hand vs the matrix");
    assert!((pd5 - 0.108053).abs() < 5e-7 && (h_log - 0.022870).abs() < 5e-7, "the card's 10.81% and 2.29%, to six places");
    assert!((by_paths(0, 5) - pd5).abs() < 1e-13, "path sum vs matrix power");
    assert!((by_eigen(0, 5) - pd5).abs() < 1e-13, "eigen road, Solid");
    assert!((by_eigen(1, 5) - p5[1][2]).abs() < 1e-13, "eigen road, Shaky");
    assert!((mc - pd5).abs() < 4.0 * se, "simulation within four standard errors");
    assert!((h_bis - h_log).abs() < 1e-12, "bisection hazard vs log formula");
    for r in &p5 { assert!((r.iter().sum::<f64>() - 1.0).abs() < 1e-13, "each row of P^5 is a full set of chances"); }
    println!("ALL CHECKS PASS");
}
