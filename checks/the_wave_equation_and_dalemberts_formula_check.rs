// The wave equation u_tt = c^2 u_xx, two roads: d'Alembert's formula and a grid stepped by its own loop.
const C: f64 = 1.0; // string speed, m/s
const H: f64 = 1.0; // pinch height, cm
const W: f64 = 0.05; // pinch width, m
const T: f64 = 0.05; // rope tension, N
const RHO: f64 = 0.2; // rope mass per length, kg/m
const A: f64 = 4.0; // rope pulse height, cm

fn f(x: f64) -> f64 { H * (-((x - 0.5) / W).powi(2)).exp() } // starting shape, cm
fn dalembert(x: f64, t: f64) -> f64 { 0.5 * (f(x - C * t) + f(x + C * t)) } // released from rest

fn grid(n: usize, t_end: f64, r: f64) -> (Vec<f64>, f64) { // leapfrog on 0..1 m, ends held at 0
    let dx = 1.0 / n as f64;
    let steps = (t_end / (r * dx / C)).round() as usize;
    let lap = |u: &Vec<f64>, j: usize| u[j + 1] - 2.0 * u[j] + u[j - 1];
    let mut old: Vec<f64> = (0..=n).map(|j| if j == 0 || j == n { 0.0 } else { f(j as f64 * dx) }).collect();
    let mut new: Vec<f64> = (0..=n).map(|j| if j == 0 || j == n { 0.0 } else { old[j] + 0.5 * r * r * lap(&old, j) }).collect();
    for _ in 0..steps - 1 {
        let next: Vec<f64> = (0..=n).map(|j| if j == 0 || j == n { 0.0 } else { 2.0 * new[j] - old[j] + r * r * lap(&new, j) }).collect();
        old = new;
        new = next;
    }
    (new, dx)
}

fn p(s: f64) -> f64 { if -0.2 < s && s < 0.0 { A * (1.0 - ((s + 0.1) / 0.1).powi(2)).powi(3) } else { 0.0 } }
fn dp(s: f64) -> f64 { if -0.2 < s && s < 0.0 { A * 3.0 * (1.0 - ((s + 0.1) / 0.1).powi(2)).powi(2) * (-2.0 * (s + 0.1) / 0.01) } else { 0.0 } }
fn rope(x: f64, t: f64, c: f64) -> f64 { // d'Alembert with f = p, g = -c p', g integrated by Simpson's rule
    let m = 4000;
    let (a, b) = (x - c * t, x + c * t);
    let h = (b - a) / m as f64;
    let s: f64 = (0..=m).map(|k| { let wt = if k == 0 || k == m { 1.0 } else if k % 2 == 1 { 4.0 } else { 2.0 }; wt * -c * dp(a + k as f64 * h) }).sum::<f64>() * h / 3.0;
    0.5 * (p(a) + p(b)) + s / (2.0 * c)
}

fn main() {
    for &(x, t) in &[(0.5, 0.0), (0.5, 0.05), (0.7, 0.2), (0.3, 0.2), (0.5, 0.2)] {
        println!("pinch: u({:.2} m, {:.2} s) = {:.6} cm", x, t, dalembert(x, t));
    }
    let mut errs = vec![];
    let (mut u, mut dx) = (vec![], 0.0);
    for &n in &[100usize, 200, 400] {
        let g = grid(n, 0.2, 0.5);
        u = g.0; dx = g.1;
        errs.push((0..=n).map(|j| (u[j] - dalembert(j as f64 * dx, 0.2)).abs()).fold(0.0, f64::max));
        println!("grid n={}: dx = {:.4} m, largest gap to d'Alembert at 0.2 s = {:.5} cm", n, dx, errs[errs.len() - 1]);
    }
    println!("error ratios: {:.2} {:.2} (order 2 means 4)", errs[0] / errs[1], errs[1] / errs[2]);
    let jp = (200..=400).fold(200, |b, j| if u[j] > u[b] { j } else { b });
    println!("grid right bump at 0.2 s: x = {:.3} m, height = {:.4} cm", jp as f64 * dx, u[jp]);
    println!("bump peaks reach the held ends at: {:.2} s", 0.5 / C);
    println!("what breaks: no 1/2 gives {:.6} cm; one copy only gives u(0.30, 0.20) = {:.6} cm", 2.0 * dalembert(0.7, 0.2), f(0.3 - C * 0.2));
    println!("figure, px: start peak (190, {:.0}); bumps ({:.0}, {:.1}) ({:.0}, {:.1})", 190.0 - 150.0 * f(0.5), 40.0 + 300.0 * 0.3, 190.0 - 150.0 * dalembert(0.3, 0.2), 40.0 + 300.0 * 0.7, 190.0 - 150.0 * dalembert(0.7, 0.2));
    let c = (T / RHO).sqrt();
    println!("rope: c = sqrt({} N / {} kg/m) = {:.2} m/s, so 1 m takes {:.2} s; T / rho = {:.2} would say {:.2} s", T, RHO, c, 1.0 / c, T / RHO, RHO / T);
    println!("rope u(1 m, 2.2 s): travelling pulse p(x - ct) = {:.6} cm, d'Alembert = {:.6} cm, no velocity term = {:.6} cm", p(1.0 - c * 2.2), rope(1.0, 2.2, c), 0.5 * (p(1.0 - c * 2.2) + p(1.0 + c * 2.2)));
    let first = (0..400).map(|k| k as f64 / 100.0).find(|&t| rope(1.0, t, c).abs() > 1e-9).unwrap();
    println!("rope: first motion at x = 1 m on a 0.01 s scan: t = {:.2} s", first);
    let row: Vec<String> = (0..13).map(|k| format!("{:.2}", (rope(1.0, 1.9 + 0.05 * k as f64, c) * 100.0).round() / 100.0 + 0.0)).collect();
    println!("rope u(1 m, t) cm, t = 1.90 to 2.50 step 0.05: {}", row.join(" "));

    assert!(errs[2] < 1e-3); // the grid, stepped blind, lands on d'Alembert's formula
    assert!(3.5 < errs[0] / errs[1] && errs[0] / errs[1] < 4.5); // halving dx cuts the gap about fourfold
    assert!((rope(1.0, 2.2, c) - p(1.0 - c * 2.2)).abs() < 1e-6); // the velocity integral makes one pulse
    assert!(1.0 / c <= first && first <= 1.0 / c + 0.01); // nothing arrives before distance / speed
}
