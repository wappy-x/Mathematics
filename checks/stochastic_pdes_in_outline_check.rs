// Stochastic heat equation u_t = u_xx + xi on a rod (0, pi), ends held at 0, noise strength 1.
// Road 1: mode sums (each mode an OU process). Road 2: closed forms (Basel sum, Green's function).
// Road 3: Euler-Maruyama simulation on a grid, seeded SplitMix64 + Box-Muller.
use std::f64::consts::PI;

struct Rng(u64);
impl Rng {
    fn next_u(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^= z >> 31;
        ((z >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn normal_pair(&mut self) -> (f64, f64) {
        let r = (-2.0 * self.next_u().ln()).sqrt();
        let a = 2.0 * PI * self.next_u();
        (r * a.cos(), r * a.sin())
    }
}

fn point_var_modes(x: f64, kmax: usize) -> f64 {
    (1..=kmax).fold(0.0, |a, k| { let sk = (k as f64 * x).sin(); a + sk * sk / ((k * k) as f64) }) / PI
}

fn square_sum(r: i64) -> f64 {
    let mut s = 0.0;
    for j in 1..=r {
        for k in (1..=r).filter(|k| j * j + k * k <= r * r) { s += 1.0 / ((2 * (j * j + k * k)) as f64); }
    }
    s
}

fn grid1d(n: usize) -> f64 {
    let h = PI / (n + 1) as f64;
    let m = (n + 1) / 2;
    let mut v = 0.0;
    for j in 1..=n {
        let s = (j as f64 * m as f64 * PI / (n + 1) as f64).sin();
        let l = (j as f64 * h / 2.0).sin();
        v += (2.0 / (n + 1) as f64) * (s * s) / ((4.0 / (h * h)) * (l * l));
    }
    v / (2.0 * h)
}

fn grid2d(n: usize) -> f64 {
    let h = PI / (n + 1) as f64;
    let lam: Vec<f64> = (0..=n).map(|j| { let l = (j as f64 * h / 2.0).sin(); (4.0 / (h * h)) * (l * l) }).collect();
    let w = 2.0 / (n + 1) as f64;
    let mut v = 0.0;
    for j in (1..=n).step_by(2) {
        for k in (1..=n).step_by(2) { v += (w * w) / (lam[j] + lam[k]); }
    }
    v / (2.0 * h * h)
}

fn report(label: &str, vals: &[f64], exact: f64, cont: f64) {
    let m = vals.len() as f64;
    let mean = vals.iter().fold(0.0, |a, w| a + w) / m;
    let se = (vals.iter().fold(0.0, |a, w| a + (w - mean) * (w - mean)) / (m - 1.0) / m).sqrt();
    println!("{:22} sim {:.4} +- {:.4}  grid exact {:.4}  continuum {:.4}", label, mean, se, exact, cont);
    assert!((mean - exact).abs() < 4.0 * se);
}

fn join(v: &[f64], d: usize) -> String {
    v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(" ")
}

fn main() {
    println!("rod (0, pi), ends at 0, noise strength 1; mode k: pull k^2, stationary variance 1/(2k^2)");
    let total = PI * PI / 12.0;
    for k in 1..=5usize {
        let v = 1.0 / ((2 * k * k) as f64);
        println!("mode {}: pull {:2}  variance {:.4}  share of total {:5.2}%  at t = 3: {:.5}", k, k * k, v, 100.0 * v / total, v * (1.0 - (-6.0 * (k * k) as f64).exp()));
    }
    println!("total, closed form pi^2/12 = {:.6}", total);
    let (mut s, mut p1000, mut pbig) = (0.0, 0.0, 0.0);
    for k in 1..=100000usize {
        s += 1.0 / ((2 * k * k) as f64);
        if [1, 2, 5, 10, 100, 1000, 100000].contains(&k) {
            if k == 1000 { p1000 = s; }
            if k == 100000 { pbig = s; }
            println!("1D partial sum to K = {:6}: {:.6}  gap to pi^2/12 {:.6}  tail bound 1/(2K) {:.6}", k, s, total - s, 1.0 / (2 * k) as f64);
        }
    }
    assert!((pbig - total).abs() < 1e-5);
    assert!(total - p1000 < 1.0 / 2000.0 && total - p1000 > 1.0 / 2002.0);
    for (x, name) in [(PI / 2.0, "pi/2"), (PI / 4.0, "pi/4")] {
        let (mv, cf) = (point_var_modes(x, 200000), x * (PI - x) / (2.0 * PI));
        println!("variance at x = {}: mode sum {:.6}  closed form x(pi-x)/(2pi) {:.6}", name, mv, cf);
        assert!((mv - cf).abs() < 1e-5);
    }
    println!("hand: pi^2/12 {:.4}, pi/8 {:.4}, 3pi/32 {:.4}, (pi/4) ln 2 {:.4}", total, PI / 8.0, 3.0 * PI / 32.0, PI / 4.0 * 2f64.ln());
    let mut prev = 0.0;
    for r in [10, 20, 40, 80, 160, 320] {
        let s2 = square_sum(r);
        let rise = if r > 10 { format!("  rise since last {:.4}", s2 - prev) } else { String::new() };
        println!("2D square sum over j^2+k^2 <= {:3}^2: {:.4}{}", r, s2, rise);
        if r == 320 { assert!(((s2 - prev) - PI / 4.0 * 2f64.ln()).abs() < 0.01); }
        prev = s2;
    }
    let (mut g1, mut g2) = (vec![], vec![]);
    for n in [7usize, 15, 31, 63, 127] {
        g1.push(grid1d(n));
        g2.push(grid2d(n));
        println!("grid N = {:3}, h = pi/{}: midpoint variance, rod {:.4}  square {:.4}", n, n + 1, g1[g1.len() - 1], g2[g2.len() - 1]);
        assert!((g1[g1.len() - 1] - PI / 8.0).abs() < 1e-12);
    }
    let rise = g2[4] - g2[3];
    println!("square: rise per halving of h {:.4}, continuum rate ln 2/(4 pi) {:.4}", rise, 2f64.ln() / (4.0 * PI));
    assert!((rise - 2f64.ln() / (4.0 * PI)).abs() < 0.002);
    println!("chart, rod    {}", join(&g1, 3));
    println!("chart, square {}", join(&g2, 3));

    let (n, t, m) = (15usize, 3.0f64, 1000usize);
    let h = PI / (n + 1) as f64;
    let steps = (t / (h * h / 4.0)).round() as usize;
    let dt = t / steps as f64;
    let xs: Vec<f64> = (0..n).map(|i| (i + 1) as f64 * h).collect();
    let vk: Vec<Vec<f64>> = (1..=n).map(|k| (0..n).map(|i| (2.0 / (n + 1) as f64).sqrt() * (k as f64 * (i + 1) as f64 * PI / (n + 1) as f64).sin()).collect()).collect();
    let lk: Vec<f64> = (1..=n).map(|k| { let l = (k as f64 * h / 2.0).sin(); (4.0 / (h * h)) * (l * l) }).collect();
    assert!(1.0 - lk[n - 1] * dt >= -1.0); // stable: the fastest grid mode does not flip and grow
    let mode_var = |k: usize, step: f64, scale: f64| -> f64 { let rho = 1.0 - lk[k] * step;
        scale * (1.0 - rho.powf(2.0 * (t / step).round())) / (1.0 - rho * rho) };
    let mid = n / 2;
    let ex_mid = (0..n).fold(0.0, |a, k| a + vk[k][mid] * vk[k][mid] * mode_var(k, dt, dt / h));
    let ex_energy = h * (0..n).fold(0.0, |a, k| a + mode_var(k, dt, dt / h));
    let ex_a1 = h * mode_var(0, dt, dt / h);
    println!("simulation: N = {} interior points, h = pi/{}, dt = {:.6}, {} steps to t = {:.0}, {} paths, seed 20261123", n, n + 1, dt, steps, t, m);
    let mut rng = Rng(20261123);
    let (mut mids, mut energies, mut a1s, mut snap) = (vec![], vec![], vec![], vec![]);
    let c = (dt / h).sqrt();
    for p in 0..m {
        let mut u = vec![0.0f64; n];
        for _ in 0..steps {
            let mut z: Vec<f64> = vec![];
            while z.len() < n { let (a, b) = rng.normal_pair(); z.push(a); z.push(b); }
            u = (0..n).map(|i| { let (l, r) = (if i > 0 { u[i - 1] } else { 0.0 }, if i < n - 1 { u[i + 1] } else { 0.0 });
                u[i] + dt * (l - 2.0 * u[i] + r) / (h * h) + c * z[i] }).collect();
        }
        if p == 0 { snap.push(0.0); snap.extend(u.iter()); snap.push(0.0); }
        mids.push(u[mid] * u[mid]);
        energies.push(h * u.iter().fold(0.0, |a, w| a + w * w));
        let a1 = h * (0..n).fold(0.0, |a, i| a + (2.0 / PI).sqrt() * xs[i].sin() * u[i]);
        a1s.push(a1 * a1);
    }
    let cm = (1..50usize).step_by(2).fold(0.0, |a, k| a + (-6.0 * (k * k) as f64).exp() / ((k * k) as f64));
    let ce = (1..50usize).fold(0.0, |a, k| a + (-6.0 * (k * k) as f64).exp() / ((2 * k * k) as f64));
    report("midpoint variance", &mids, ex_mid, PI / 8.0 - cm / PI);
    report("energy, integral u^2", &energies, ex_energy, total - ce);
    report("mode 1 variance", &a1s, ex_a1, 0.5 * (1.0 - (-6.0f64).exp()));
    let xg: Vec<f64> = (0..n + 2).map(|i| i as f64 * h).collect();
    println!("chart, x      {}", join(&xg, 2));
    println!("chart, path   {}", join(&snap, 2));
    let sd: Vec<f64> = xg.iter().map(|x| (x * (PI - x) / (2.0 * PI)).sqrt()).collect();
    println!("chart, +1 sd  {}", join(&sd, 2));
    println!("chart, -1 sd  {}", join(&sd.iter().map(|w| if *w > 0.005 { -w } else { 0.0 }).collect::<Vec<_>>(), 2));
    let wrong_noise = (0..n).fold(0.0, |a, k| a + vk[k][mid] * vk[k][mid] * mode_var(k, dt, dt));
    let big = 0.6 * h * h; let factor = 1.0 - lk[n - 1] * big;
    let amp = (t / big).round() * factor.abs().log10();
    println!("mistake, variance 1/k^2 (drop the 2): total {:.4}", PI * PI / 6.0);
    println!("mistake, noise sqrt(dt) not sqrt(dt/h): midpoint variance {:.4}, true {:.4}", wrong_noise, ex_mid);
    println!("mistake, dt = 0.6 h^2: top mode factor {:.4} per step, grows by 10^{:.1} by t = 3", factor, amp);
    let (mut r, mut direct): (Vec<f64>, f64) = ((0..n).map(|i| if i == mid { 1.0 } else { 0.0 }).collect(), 0.0); // the same variance with no modes: step the scheme directly
    for _ in 0..steps { direct += dt * r.iter().fold(0.0, |a, w| a + w * w); r = (0..n).map(|i| r[i] + dt * ((if i > 0 { r[i - 1] } else { 0.0 }) - 2.0 * r[i] + (if i < n - 1 { r[i + 1] } else { 0.0 })) / (h * h)).collect(); }
    assert!((direct - wrong_noise).abs() < 1e-9);
    assert!(factor < -1.0);
    println!("ALL CHECKS PASS");
}
