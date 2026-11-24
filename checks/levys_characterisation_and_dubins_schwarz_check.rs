// Levy's characterisation and Dubins-Schwarz: four roads, std only.
struct Rng { s: u64 }
impl Rng { // SplitMix64 uniforms, Box-Muller normals (one per call)
    fn u(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn n(&mut self) -> f64 {
        let u1 = 1.0 - self.u();
        (-2.0 * u1.ln()).sqrt() * (2.0 * std::f64::consts::PI * self.u()).cos()
    }
}

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, m: usize) -> f64 {
    let h = (b - a) / m as f64;
    let mut s = f(a) + f(b);
    for k in 1..m { s += (if k % 2 == 1 { 4.0 } else { 2.0 }) * f(a + k as f64 * h); }
    s * h / 3.0
}
fn phi(z: f64) -> f64 { (-z * z / 2.0).exp() / (2.0 * std::f64::consts::PI).sqrt() }
fn big_phi(x: f64) -> f64 { 0.5 + simpson(&phi, 0.0, x, 2000) }
fn phi_series(x: f64) -> f64 { // 0.5 + sum of the Taylor series of the integral of phi
    let (mut s, mut k, mut term) = (0.0, 0.0, x);
    while term.abs() > 1e-17 {
        s += term / (2.0 * k + 1.0); k += 1.0; term *= -x * x / (2.0 * k);
    }
    0.5 + s / (2.0 * std::f64::consts::PI).sqrt()
}
fn mean(v: &[f64]) -> f64 { v.iter().sum::<f64>() / v.len() as f64 }
fn se(v: &[f64]) -> f64 {
    let m = mean(v); let n = v.len() as f64;
    (v.iter().map(|x| (x - m) * (x - m)).sum::<f64>() / (n - 1.0) / n).sqrt()
}
fn corr(x: &[f64], y: &[f64]) -> f64 {
    let (mx, my) = (mean(x), mean(y));
    let c: f64 = x.iter().zip(y).map(|(a, b)| (a - mx) * (b - my)).sum();
    let sx: f64 = x.iter().map(|a| (a - mx) * (a - mx)).sum();
    let sy: f64 = y.iter().map(|b| (b - my) * (b - my)).sum();
    c / (sx * sy).sqrt()
}
fn ind(v: &[f64], f: &dyn Fn(f64) -> bool) -> Vec<f64> { v.iter().map(|&x| if f(x) { 1.0 } else { 0.0 }).collect() }
fn sq(v: &[f64]) -> Vec<f64> { v.iter().map(|x| x * x).collect() }
fn q4(v: &[f64]) -> Vec<f64> { v.iter().map(|x| x.powi(4)).collect() }

fn main() {
    // Road 1: formulas
    let (p1, p2w, pneg) = (1.0 - big_phi(1.0), 1.0 - big_phi(2.0 / 2f64.sqrt()), big_phi(-0.5 / 0.5f64.sqrt()));
    let kurt = simpson(&|z: f64| ((z * z - 1.0) / 2.0).powi(4) * phi(z), -12.0, 12.0, 4000) / 0.25;
    println!("formula   P(N(0,1) > 1) = {:.6}   series {:.6}   E[cos W_1] = e^-1/2 = {:.6}", p1, phi_series(-1.0), (-0.5f64).exp());
    println!("formula   twice-as-fast P(W_2 > 2) = {:.6}   P(N(0,0.5) < -0.5) = {:.6}   Poisson P(N_1 - 4 = -4) = e^-4 = {:.6}", p2w, pneg, (-4.0f64).exp());
    println!("formula   house X_1 = (W_1^2 - 1)/2: E[X_1^2] = 0.5, E[X_1^4]/E[X_1^2]^2 = {:.4} (normal: 3)", kurt);
    let mom: Vec<f64> = [8, 6, 4, 2].iter().map(|&j| simpson(&|z: f64| z.powi(j) * phi(z), -12.0, 12.0, 4000)).collect();
    println!("formula   E[(W_1^2 - 1)^4] = {:.4} - {:.4} + {:.4} - {:.4} + 1; over 16, E[X_1^4] = {:.4}", mom[0], 4.0 * mom[1], 6.0 * mom[2], 4.0 * mom[3], kurt / 4.0);
    assert!((big_phi(1.0) - phi_series(1.0)).abs() < 1e-10 && (kurt - 15.0).abs() < 1e-6);
    let dfact = |j: i32| (1..j).rev().step_by(2).map(|i| i as f64).product::<f64>(); // 7!!, 5!!, 3!!, 1!!
    assert!(mom.iter().zip([8, 6, 4, 2]).all(|(m, j)| (m - dfact(j)).abs() < 1e-6));

    // Road 2: coin flips, every one of the 4096 paths of 12 steps
    let n = 12i64; let (mut law_s, mut law_m, mut differ) = ([0u32; 25], [0u32; 25], 0);
    for code in 0..(1u32 << n) {
        let (mut s, mut m, mut h) = (0i64, 0i64, 0i64);
        for k in 0..n {
            let x = if (code >> k) & 1 == 1 { 1 } else { -1 };
            m += (if s >= 0 { 1 } else { -1 }) * x; h += s * x; s += x;
        }
        assert!(2 * h == s * s - n);
        law_s[(s + 12) as usize] += 1; law_m[(m + 12) as usize] += 1; if m != s { differ += 1; }
    }
    assert!(law_s == law_m);
    println!("coins     12 steps: sign-strategy total has the walk's law exactly; totals differ on {} of 4096 paths", differ);
    let counts: Vec<String> = (0..25).step_by(2).map(|i| law_m[i].to_string()).collect();
    println!("coins     counts at -12..12 step 2: {}", counts.join(" "));
    let ge4: u32 = law_m[16..].iter().sum();
    println!("coins     P(total >= 4) = {}/4096 = {:.6}", ge4, ge4 as f64 / 4096.0);

    // Road 3: simulate M_t = int sgn(W) dW and Y_t = int 2 dW on [0, 1]
    let mut rng = Rng { s: 20261123 }; let (pp, steps) = (40000, 200); let dt = 1.0 / steps as f64;
    let (mut mh, mut m1, mut b1) = (vec![], vec![], vec![]);
    for _ in 0..pp {
        let (mut b, mut m) = (0.0f64, 0.0f64);
        for k in 0..steps {
            let db = dt.sqrt() * rng.n(); m += (if b >= 0.0 { 1.0 } else { -1.0 }) * db; b += db;
            if k == steps / 2 - 1 { mh.push(m); }
        }
        m1.push(m); b1.push(b);
    }
    let (s2, s4, big) = (sq(&m1), q4(&m1), ind(&m1, &|m| m > 1.0));
    let cs: Vec<f64> = m1.iter().map(|m| m.cos()).collect(); let sn: Vec<f64> = m1.iter().map(|m| m.sin()).collect();
    let n1: Vec<f64> = b1.iter().map(|b| 2.0 * b).collect(); let big_n = ind(&n1, &|v| v > 2.0);
    println!("simulate  sign integral, {} paths, dt {}, bracket = steps x dt, since sgn^2 = 1: {:.4}", pp, dt, steps as f64 * dt);
    println!("  E[M_1] {:.4} se {:.4}   E[M_1^2] {:.4} se {:.4}   E[M_1^4] {:.4} se {:.4}", mean(&m1), se(&m1), mean(&s2), se(&s2), mean(&s4), se(&s4));
    println!("  P(M_1 > 1) {:.4} se {:.4}   E[cos M_1] {:.4} se {:.4}   E[sin M_1] {:.4}", mean(&big), se(&big), mean(&cs), se(&cs), mean(&sn));
    println!("  E[Z_1] = E[cos M_1] e^(1/2) = {:.4}", mean(&cs) * 0.5f64.exp());
    let inc: Vec<f64> = mh.iter().zip(&m1).map(|(a, b)| b - a).collect();
    let ab: Vec<f64> = b1.iter().map(|b| b.abs()).collect();
    println!("  corr(M_0.5^2, (M_1 - M_0.5)^2) {:.4}   corr(M_1, W_1) {:.4}   corr(M_1, |W_1|) {:.4} (continuous time {:.4})", corr(&sq(&mh), &sq(&inc)), corr(&m1, &b1), corr(&m1, &ab),
             0.5 / (1.0 - 2.0 / std::f64::consts::PI).sqrt());
    println!("  constant 2, Y = 2W: E[Y_1^2] {:.4}   P(Y_1 > 2) {:.4} se {:.4}", mean(&sq(&n1)), mean(&big_n), se(&big_n));
    assert!((mean(&s2) - 1.0).abs() < 4.0 * se(&s2) && (mean(&big) - p1).abs() < 4.0 * se(&big));
    assert!((mean(&cs) - (-0.5f64).exp()).abs() < 4.0 * se(&cs) && (mean(&big_n) - p1).abs() < 4.0 * se(&big_n));

    // Road 4: Dubins-Schwarz on the house example X = int W dW, clock A = int W^2 dt
    let mut rng = Rng { s: 20261124 }; let (p2, s, cap) = (40000, 0.5f64, 4000);
    let (mut beta, mut atau, mut tau, mut mfix, mut afix) = (vec![], vec![], vec![], vec![], vec![]);
    for _ in 0..p2 {
        let (mut b, mut m, mut a) = (0.0f64, 0.0f64, 0.0f64); let mut k = 0; let mut done = false;
        while k < cap && (!done || k < steps) {
            if !done && a >= s { beta.push(m); atau.push(a); tau.push(k as f64 * dt); done = true; }
            let db = dt.sqrt() * rng.n(); m += b * db; a += b * b * dt; b += db; k += 1;
            if k == steps { mfix.push((b * b - 1.0) / 2.0); afix.push(a); }
        }
    }
    let (b2, b4) = (sq(&beta), q4(&beta));
    let up = ind(&beta, &|b| b > s.sqrt()); let dn = ind(&beta, &|b| b < -0.5);
    let f2 = sq(&mfix);
    let zr: Vec<f64> = mfix.iter().zip(&afix).map(|(m, a)| m / a.sqrt()).collect(); let lo = ind(&zr, &|z| z < -1.0);
    let etau = (2.0 * s / std::f64::consts::PI).sqrt() * simpson(&|u: f64| 1.0 / u.cosh().sqrt(), 0.0, 60.0, 4000); // sqrt(s) E[A_1^(-1/2)]
    println!("time change  house example, {} paths, stop when the clock A reaches s = {}: reached on {}", p2, s, beta.len());
    println!("  mean stopping time {:.4} years (exact {:.4})   mean clock at the stop {:.4}", mean(&tau), etau, mean(&atau));
    println!("  E[beta_s^2] {:.4} se {:.4}   E[beta^4]/E[beta^2]^2 {:.4}   P(beta_s > sqrt s) {:.4} se {:.4}", mean(&b2), se(&b2), mean(&b4) / mean(&b2).powi(2), mean(&up), se(&up));
    println!("  P(beta_s < -0.5) {:.4} se {:.4}", mean(&dn), se(&dn));
    println!("  fixed time 1: E[X_1^2] {:.4}  E[X_1^4]/E[X_1^2]^2 {:.4}  P(X_1 < -0.5) {:.4}", mean(&f2), mean(&q4(&mfix)) / mean(&f2).powi(2), mean(&ind(&mfix, &|m| m < -0.5)));
    assert!(beta.len() == p2 && (mean(&b2) - mean(&atau)).abs() < 4.0 * se(&b2));
    assert!((mean(&up) - p1).abs() < 4.0 * se(&up) && (mean(&dn) - pneg).abs() < 4.0 * se(&dn));
    println!("  X_1/sqrt(A_1): mean square {:.4}   P(< -1) {:.4} se {:.4}   P(> 1) {:.4}   normal: 1, {:.6}", mean(&sq(&zr)), mean(&lo), se(&lo), mean(&ind(&zr, &|z| z > 1.0)), p1);
    assert!(mean(&lo) - p1 > 4.0 * se(&lo)); // dividing by a random clock does not give a normal law

    // the chart: one path's clock A_t against the clocks t and 4t
    let mut rng = Rng { s: 20261125 }; let (mut b, mut a) = (0.0f64, 0.0f64); let mut pts = vec!["0.00".to_string()];
    for k in 1..=400 {
        let db = dt.sqrt() * rng.n(); a += b * b * dt; b += db;
        if k % 20 == 0 { pts.push(format!("{:.2}", a)); }
    }
    println!("chart, A_t at t = 0, 0.1, ..., 2: {}", pts.join(" "));
    let tt: Vec<String> = (0..21).map(|j| format!("{:.2}", j as f64 / 10.0)).collect();
    println!("chart, clock t:                 {}", tt.join(" "));
    let t4: Vec<String> = (0..21).map(|j| format!("{:.2}", 4.0 * j as f64 / 10.0)).collect();
    println!("chart, clock 4t:                {}", t4.join(" "));
    let half: Vec<String> = (0..21).map(|j| format!("{:.2}", (j as f64 / 10.0).powi(2) / 2.0)).collect();
    println!("chart, t^2/2 at the same times:   {}", half.join(" "));
    println!("ALL CHECKS PASS");
}
