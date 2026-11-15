// Convection-diffusion -- the check behind the card, in Rust with std only.
// 10 g of dye in water flowing at c = 1 m/s, effective diffusivity 0.01 m^2/s.
// Road 1: the heat kernel moved with the flow.  Road 2: a random walk of 10,000
// particles (SplitMix64 and Box-Muller).  Road 3: centred-difference residuals
// and Simpson moments.  Same labels and digits as the Python check.
use std::f64::consts::PI;

const C: f64 = 1.0; const KAP: f64 = 0.01; const M: f64 = 10.0; const L: f64 = 100.0;

fn uk(x: f64, t: f64, c: f64, kap: f64, k: f64) -> f64 { // g per metre of pipe
    M * (-k * t).exp() / (4.0 * PI * kap * t).sqrt() * (-(x - c * t).powi(2) / (4.0 * kap * t)).exp()
}
fn u(x: f64, t: f64) -> f64 { uk(x, t, C, KAP, 0.0) }

fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = g(a) + g(b);
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * g(a + i as f64 * h); }
    h / 3.0 * s
}

fn res(x: f64, t: f64, h: f64, k: f64, c: f64) -> f64 { // u_t + c u_x - kappa u_xx + k u
    let g = |x: f64, t: f64| uk(x, t, c, KAP, k);
    let ut = (g(x, t + h) - g(x, t - h)) / (2.0 * h);
    let ux = (g(x + h, t) - g(x - h, t)) / (2.0 * h);
    let uxx = (g(x + h, t) - 2.0 * g(x, t) + g(x - h, t)) / (h * h);
    ut + C * ux - KAP * uxx + k * g(x, t)
}

struct Rng(u64);
impl Rng {
    fn next(&mut self) -> f64 { // SplitMix64, top 53 bits as a number in [0, 1)
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}

fn main() {
    let re: f64 = 1.0 * 0.05 / 1e-6; let f = 0.316 * re.powf(-0.25); let ustar = (f / 8.0).sqrt();
    println!("pipe: Re = {:.0}, Blasius f = {:.5}, u* = {:.4} m/s, Taylor 10.1 a u* = {:.4} m^2/s", re, f, ustar, 10.1 * 0.025 * ustar);
    let t = L / C; let sig = (2.0 * KAP * t).sqrt(); let peak = u(C * t, t);
    println!("t = {:.0} s: centre {:.0} m, 4 kappa t = {:.2} m^2, width sqrt(2 kappa t) = {:.4} m", t, C * t, 4.0 * KAP * t, sig);
    println!("road 1, peak M / sqrt(4 pi kappa t) = {:.0} / {:.4} = {:.4} g/m", M, (4.0 * PI * KAP * t).sqrt(), peak);
    println!("one width off centre, x = {:.4} m: {:.4} g/m = peak x e^(-1/2)", C * t + sig, u(C * t + sig, t));
    println!("half-peak width 2 sqrt(2 ln 2) sigma = {:.4} m", 2.0 * (2.0 * 2f64.ln()).sqrt() * sig);

    let (mut m0, mut m1, mut m2) = (0.0, 0.0, 0.0);
    for n in [400usize, 800] {
        m0 = simpson(&|x| u(x, t), 80.0, 120.0, n);
        m1 = simpson(&|x| x * u(x, t), 80.0, 120.0, n) / m0;
        let mm = m1;
        m2 = simpson(&|x| (x - mm).powi(2) * u(x, t), 80.0, 120.0, n) / m0;
        println!("road 3, Simpson n = {}: mass {:.6} g, mean {:.6} m, variance {:.6} m^2", n, m0, m1, m2);
    }
    assert!((m0 - M).abs() < 1e-6 && (m1 - C * t).abs() < 1e-6 && (m2 - 2.0 * KAP * t).abs() < 1e-6);

    let (r1, r2) = (res(101.0, t, 0.02, 0.0, C), res(101.0, t, 0.01, 0.0, C));
    println!("road 3, residual at 101 m, 100 s, in 1e-8 g/m/s: h = 0.02 {:+.3}, h = 0.01 {:+.3}, ratio {:.2}", r1 * 1e8, r2 * 1e8, r1 / r2);
    assert!((r1 / r2 - 4.0).abs() < 0.1 && r2.abs() < 1e-5);
    let rl = res(101.0, t, 0.01, 0.01, C); let pl = uk(C * t, t, C, KAP, 0.01);
    println!("with a leak k = 0.01 /s: peak {:.4} g/m = {:.4} x e^(-1), residual {:+.3} x 1e-8", pl, peak, rl * 1e8);
    assert!(rl.abs() < 1e-5);
    let rw = res(0.1, 1.0, 0.001, 0.0, 0.0);
    println!("mistake, heat kernel left at the inlet: residual at 0.1 m, 1 s = {:+.2} g/m/s, not 0", rw);
    assert!(rw.abs() > 1.0);

    let mut rng = Rng(0x2026_1115);
    let (n, steps) = (10000usize, 50usize); let dt = t / steps as f64; let mut xs = Vec::with_capacity(n);
    for _ in 0..n {
        let mut x = 0.0;
        for _ in 0..steps {
            let a = rng.next(); let b = rng.next();
            let z = (-2.0 * (1.0 - a).ln()).sqrt() * (2.0 * PI * b).cos();
            x += C * dt + (2.0 * KAP * dt).sqrt() * z;
        }
        xs.push(x);
    }
    let nf = n as f64;
    let mean = xs.iter().sum::<f64>() / nf;
    let var = xs.iter().map(|x| (x - mean).powi(2)).sum::<f64>() / (nf - 1.0);
    let inside = xs.iter().filter(|x| (*x - C * t).abs() < sig).count() as f64 / nf;
    println!("road 2, {} walkers x {} steps: mean {:.3} m, variance {:.3} m^2, share within one width {:.4}", n, steps, mean, var, inside);
    assert!((mean - C * t).abs() < 4.0 * sig / nf.sqrt() && (var - sig * sig).abs() < 4.0 * sig * sig * (2.0 / nf).sqrt());
    assert!((inside - 0.6827).abs() < 4.0 * (0.6827f64 * 0.3173 / nf).sqrt());

    let tp = (-KAP + (KAP * KAP + C * C * L * L).sqrt()) / (C * C);
    let (mut a, mut b) = (95.0f64, 105.0f64); let g = (5f64.sqrt() - 1.0) / 2.0;
    for _ in 0..100 {
        let (p, q) = (b - g * (b - a), a + g * (b - a));
        if u(L, p) > u(L, q) { b = q } else { a = p }
    }
    println!("sensor at {:.0} m: peak passes at {:.6} s by formula, {:.6} s by search, {:.4} g/m", L, tp, (a + b) / 2.0, u(L, tp));
    assert!(((a + b) / 2.0 - tp).abs() < 1e-5);
    let cross = |mut lo: f64, mut hi: f64| { // bisection for u(L, t) = half the peak
        let up = u(L, lo) < u(L, hi); let mut m = lo;
        for _ in 0..80 { m = (lo + hi) / 2.0; if (u(L, m) < u(L, tp) / 2.0) == up { lo = m } else { hi = m } }
        m
    };
    let (t1, t2) = (cross(90.0, tp), cross(tp, 110.0));
    println!("sensor above half its peak from {:.4} s to {:.4} s: {:.4} s", t1, t2, t2 - t1);
    assert!(((t2 - t1) - 2.0 * (2.0 * 2f64.ln()).sqrt() * sig / C).abs() < 0.01);
    println!("Peclet c L / kappa at {:.0} m = {:.0}, at 0.02 m = {:.0}; drift time {:.0} s, spreading time L^2/kappa = {:.0} s = {:.2} days", L, C * L / KAP, C * 0.02 / KAP, L / C, L * L / KAP, L * L / KAP / 86400.0);
    let tx = 2.0 * KAP / (C * C);
    println!("drift c t equals width sqrt(2 kappa t) at t = 2 kappa / c^2 = {:.2} s, both {:.2} m", tx, C * tx);
    for ts in ["0.005", "0.02", "1", "25", "100"] {
        let tt: f64 = ts.parse().unwrap();
        println!("race, t = {} s: drift {:.4} m, width {:.4} m, ratio {:.2}", ts, C * tt, (2.0 * KAP * tt).sqrt(), C * tt / (2.0 * KAP * tt).sqrt());
    }
    println!("mistake, no drift: at {:.0} m, {:.0} s, log10 u = {:.2}", L, t, (M / (4.0 * PI * KAP * t).sqrt()).log10() - L * L / (4.0 * KAP * t) / 10f64.ln());
    println!("mistake, molecular diffusivity 1e-9 m^2/s: width {:.4} mm, peak {:.1} g/m", (2e-9 * t).sqrt() * 1000.0, uk(L, t, C, 1e-9, 0.0));
    println!("mistake, variance 4 kappa t: width {:.4} m, not {:.4} m", (4.0 * KAP * t).sqrt(), sig);
    println!("mistake, shift x + c t: centre at {:.0} m, upstream of the inlet", -C * t);
    println!("instant reach: 1 m upstream after 1 s, u = {:.2e} g/m", u(-1.0, 1.0));
    println!("bond reading at r = 4%: drift 0.3(0.05 - 0.04) = {:.3}, spreading 0.01^2/2 = {:.5}, leak r = {:.2}, per year", 0.3 * 0.01, 0.01f64.powi(2) / 2.0, 0.04);
    for tt in [25.0f64, 50.0, 100.0] {
        let pts: Vec<String> = (-8..=8).map(|z| format!("{:.2}", u(C * tt + z as f64 / 2.0, tt))).collect();
        println!("chart, moving frame, t = {:.0} s: {}", tt, pts.join(", "));
    }
    let pts: Vec<String> = (0..17).map(|i| format!("{:.2}", u(L, 96.0 + i as f64 / 2.0))).collect();
    println!("chart, sensor at 100 m, t = 96..104 s: {}", pts.join(", "));
    println!("ALL CHECKS PASS");
}
