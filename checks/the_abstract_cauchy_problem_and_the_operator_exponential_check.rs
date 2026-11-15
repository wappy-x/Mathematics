// Evolution as an equation -- the check behind the card.  std only, no crates.
// Three 100 L stirred tanks in a row, clean water through at c = 10 L/min,
// 5 kg of salt spilled into tank 1: u' = A u with A = k(S - I), k = 0.1 per min.
// Roads: the nilpotent closed form, the power series of tA, RK4 time steps and a
// salt balance.  Then N tanks along the same 300 L: the operator tends to -c d/dx.
const C: f64 = 10.0; // L/min
const M0: f64 = 5.0; // kg spilled
const T: f64 = 15.0; // minutes

fn closed3(t: f64) -> Vec<f64> {
    // e^{-kt}(I + ktS + (kt)^2 S^2/2) u0, k = 0.1
    let (a, e) = (0.1 * t, (-0.1 * t).exp());
    vec![M0 * e, M0 * e * a, M0 * e * a * a / 2.0]
}

fn rate(u: &[f64], k: f64) -> Vec<f64> {
    // (A u)_j = k(u_{j-1} - u_j), chain
    (0..u.len()).map(|j| k * ((if j > 0 { u[j - 1] } else { 0.0 }) - u[j])).collect()
}

fn series3(t: f64) -> Vec<f64> {
    // sum of (tA)^m u0 / m!, 60 terms
    let (mut term, mut tot) = (vec![M0, 0.0, 0.0], vec![M0, 0.0, 0.0]);
    for m in 1..60 {
        term = rate(&term, 0.1).iter().map(|v| t * v / m as f64).collect();
        for i in 0..3 { tot[i] += term[i]; }
    }
    tot
}

fn rk4(mut u: Vec<f64>, k: f64, t_end: f64, dt: f64) -> Vec<f64> {
    let step = |u: &[f64], d: &[f64], s: f64| -> Vec<f64> { u.iter().zip(d).map(|(x, y)| x + s * y).collect() };
    for _ in 0..(t_end / dt).round() as usize {
        let a = rate(&u, k);
        let b = rate(&step(&u, &a, dt / 2.0), k);
        let c = rate(&step(&u, &b, dt / 2.0), k);
        let d = rate(&step(&u, &c, dt), k);
        u = (0..u.len()).map(|i| u[i] + dt / 6.0 * (a[i] + 2.0 * b[i] + 2.0 * c[i] + d[i])).collect();
    }
    u
}

fn chain(n: usize, t: f64, length: usize) -> (Vec<f64>, f64) {
    // N tanks of 300/N L, slug in first 100 L; Poisson weights e^{-lam} lam^m / m!
    let (s, lam) = (n / 3, n as f64 / 30.0 * t);
    let (mut lf, mut run, mut cdf) = (0.0f64, 0.0f64, Vec::new());
    for m in 0..length {
        if m > 0 { lf += (m as f64).ln(); }
        run += (-lam + m as f64 * lam.ln() - lf).exp();
        cdf.push(run);
    }
    let cd = |i: i64| if i >= 0 { cdf[i as usize] } else { 0.0 };
    let m = (0..length as i64).map(|j| M0 / s as f64 * (cd(j) - cd(j - s as i64))).collect();
    (m, cdf[length - 1])
}

fn plug(n: usize, t: f64, length: usize) -> Vec<f64> {
    // exact transport: slug at [ct, ct + 100]
    let (h, a) = (300.0 / n as f64, C * t);
    (0..length).map(|j| 0.05 * (((j + 1) as f64 * h).min(a + 100.0) - (j as f64 * h).max(a)).max(0.0)).collect()
}

fn f3(v: &[f64]) -> String { v.iter().map(|x| format!("{:.6}", x)).collect::<Vec<_>>().join(" ") }
fn gapv(x: &[f64], y: &[f64]) -> f64 { x.iter().zip(y).map(|(a, b)| (a - b).abs()).fold(0.0, f64::max) }

fn quot_gap(f: &dyn Fn(f64) -> f64, h: f64, lo: f64, hi: f64, dx: f64) -> f64 {
    // L1 size of q_h - q_{h/2}, q_h = (u0(x-ch)-u0(x))/h
    let n = ((hi - lo) / dx).round() as usize;
    (0..n).map(|i| {
        let x = lo + (i as f64 + 0.5) * dx;
        ((f(x - C * h) - f(x)) / h - (f(x - C * h / 2.0) - f(x)) / (h / 2.0)).abs()
    }).sum::<f64>() * dx
}

fn main() {
    let (u, s, r) = (closed3(T), series3(T), rk4(vec![M0, 0.0, 0.0], 0.1, T, 0.01));
    let g = |x: f64| closed3(x)[2] * 0.1; // salt leaving tank 3, kg/min
    let w = (0..601).map(|i| (if i == 0 || i == 600 { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) * g(i as f64 * T / 600.0)).sum::<f64>() * T / 1800.0;
    let su: f64 = u.iter().sum();
    println!("three tanks, t = 15 min, closed form (kg): {}", f3(&u));
    println!("kt = {:.1}, e^(-kt) = {:.6}, weights 1, kt, (kt)^2/2 = {}", 0.1 * T, (-0.1 * T).exp(), f3(&[1.0, 0.1 * T, (0.1 * T).powi(2) / 2.0]));
    println!("power series of tA, 60 terms (kg):         {}", f3(&s));
    println!("RK4, step 0.01 min (kg):                   {}", f3(&r));
    println!("in tanks {:.6} kg + flushed (Simpson) {:.6} kg = {:.6} kg", su, w, su + w);
    assert!(gapv(&u, &s) < 1e-12 && gapv(&u, &r) < 1e-9);
    assert!((su + w - M0).abs() < 1e-9);
    for i in 0..3 {
        let row: Vec<String> = (0..13).map(|m| format!("{:.2}", closed3(5.0 * m as f64)[i])).collect();
        println!("chart tank {} (kg), t = 0..60 by 5: {}", i + 1, row.join(" "));
    }
    let e: Vec<f64> = [-0.1, 0.1, 0.0].iter().map(|a: &f64| M0 * (T * a).exp()).collect(); // mistake
    println!("mistake, entrywise e^(tA) (kg): {}", f3(&e));
    println!("N, norm of A_N (1/min), log10 e^(15 norm), salt in the 300 L (kg), L1 gap to plug flow (kg), gap*sqrt(N)");
    let mut gaps = Vec::new();
    for n in [3usize, 30, 300, 3000] {
        let (m, mass) = chain(n, T, 2 * n + 40);
        let p = plug(n, T, n);
        let gap: f64 = (0..n).map(|j| (m[j] - p[j]).abs()).sum();
        let kept: f64 = m[..n].iter().sum();
        gaps.push(gap);
        let nf = n as f64;
        println!("{:5} {:9.3} {:10.3} {:.6} {:.6} {:.4}", n, nf / 15.0, T * nf / 15.0 / 10f64.ln(), kept, gap, gap * nf.sqrt());
        assert!((mass - 1.0).abs() < 1e-9); // Poisson weights sum to 1: no salt made
    }
    let clt = 30.0 / std::f64::consts::PI.sqrt();
    println!("central-limit prediction of gap*sqrt(N): 30/sqrt(pi) = {:.4}", clt);
    assert!(gaps.windows(2).all(|p| p[0] >= p[1]) && (gaps[3] * 3000f64.sqrt() / clt - 1.0).abs() < 0.02);
    let mut start = vec![M0 / 10.0; 10];
    start.extend(vec![0.0; 90]);
    let m30 = rk4(start, 1.0, T, 0.01);
    assert!(gapv(&m30, &chain(30, T, 100).0) < 1e-8);
    println!("N = 30 by RK4 against the closed form: agree to 1e-8 kg");
    let xs: Vec<f64> = (0..12).map(|i| 12.5 + 25.0 * i as f64).collect();
    for n in [3usize, 300] {
        let (m, h) = (chain(n, T, 2 * n + 40).0, 300.0 / n as f64);
        let row: Vec<String> = xs.iter().map(|x| format!("{:.1}", 1000.0 * m[(x / h).floor() as usize] / h)).collect();
        println!("chart N = {} (g/L): {}", n, row.join(" "));
    }
    let row: Vec<String> = xs.iter().map(|&x| format!("{:.1}", if 150.0 < x && x < 250.0 { 50.0 } else { 0.0 })).collect();
    println!("chart plug (g/L): {}", row.join(" "));
    // a smooth plume f(x) = 0.05/(1 + ((x-150)/50)^2) kg/L; its Taylor series at 150 L
    let mut co = vec![1.0f64, 0.0]; // coefficients of 1/(1+z^2): g_n = -g_{n-2}
    for i in 2..201 { let v = -co[i - 2]; co.push(v); }
    for t in [4.0f64, 10.0] {
        let (z, mut tot, mut ps) = (-C * t / 50.0, 0.0f64, Vec::new());
        for i in 0..201 {
            tot += 0.05 * co[i] * z.powi(i as i32);
            if i % 2 == 0 { ps.push(tot); }
        }
        let truev = 0.05 / (1.0 + z * z); // the shifted plume, f(150 - ct)
        let last = ps[ps.len() - 1];
        println!("plume at 150 L, t = {:.0} min: true {:.6} kg/L, partial sums {}", t, truev, f3(&ps[..5]));
        let tail = if t < 5.0 { format!("{:.6}", last) } else { format!("size 10^{:.1}", last.abs().log10()) };
        println!("   sum to power 200: {}", tail);
        assert!(if t < 5.0 { (last - truev).abs() < 1e-12 } else { last.abs() > 1e50 });
    }
    println!("series reach: radius 50 L / c = {:.1} min; at 10 min it diverges wherever |x - 150| < {:.1} L", 50.0 / C, (100f64.powi(2) - 50f64.powi(2)).sqrt());
    let slug = |x: f64| if 0.0 <= x && x < 100.0 { 0.05 } else { 0.0 };
    let plume = |x: f64| 0.05 / (1.0 + ((x - 150.0) / 50.0).powi(2));
    let pred = C * C / 4.0 * 0.05 / 50.0 * 3.0 * 3f64.sqrt() / 2.0; // (c^2/4) times the size of f''
    println!("Taylor prediction for the plume gap: {:.6} h kg/min; for the slug: 2 x 0.05 x c = {:.6}", pred, 0.1 * C);
    for h in [1.0f64, 0.1, 0.01] {
        let (a, b) = (quot_gap(&slug, h, -1.0, 111.0, 0.001), quot_gap(&plume, h, -19850.0, 20150.0, 0.02));
        println!("rate test step = {:.2} min: slug gap {:.6} kg/min, plume gap {:.6} kg/min", h, a, b);
        assert!((a - 0.1 * C).abs() < 1e-6 && (b / h / pred - 1.0).abs() < 0.01 * 1f64.max(10.0 * h));
    }
    println!("ALL CHECKS PASS");
}
