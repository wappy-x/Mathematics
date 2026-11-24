// Long-dated FX and PRDC notes -- the same check as long_dated_fx_and_prdc_notes_check.py,
// in Rust.  Standard library only, no crates.  Same grids, same random numbers, same labels.
use std::f64::consts::PI;
const S0: f64 = 1.10; const SS: f64 = 0.10; const SD: f64 = 0.01; const SF: f64 = 0.01;
const RSD: f64 = 0.2; const RSF: f64 = -0.2; const RDF: f64 = 0.5;
const RD: f64 = 0.035; const RF: f64 = 0.020;
const CF: f64 = 0.06; const CD: f64 = 0.03; const NOTE: f64 = 10_000_000.0;
const G: f64 = CF / S0; const K: f64 = CD / G;
fn nsum(xs: &[f64]) -> f64 {              // compensated sum, as Python's built-in sum does
    let (mut s, mut c) = (0.0_f64, 0.0_f64);
    for &x in xs { let t = s + x; if s.abs() >= x.abs() { c += (s - t) + x } else { c += (x - t) + s }; s = t; }
    s + c
}
fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let inner: Vec<f64> = (1..n).map(|i| (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h)).collect();
    (f(a) + f(b) + nsum(&inner)) * h / 3.0
}
fn ncdf(x: f64) -> f64 { if x < -12.0 { 0.0 } else if x > 12.0 { 1.0 } else { 0.5 + simpson(phi, 0.0, x, 2000) } }
fn bfac(a: f64, tau: f64) -> f64 { if a == 0.0 { tau } else { (1.0 - (-a * tau).exp()) / a } }
fn inst_var(tau: f64, a: f64, s: f64, rho: (f64, f64, f64)) -> f64 {
    let (bd, bf) = (bfac(a, tau), bfac(a, tau));
    s * s + SD * SD * bd * bd + SF * SF * bf * bf + 2.0 * rho.0 * s * SD * bd
        - 2.0 * rho.1 * s * SF * bf - 2.0 * rho.2 * SD * SF * bd * bf
}
fn var_closed(t: f64, s: f64) -> [f64; 3] {   // road 1: the integral done by hand (a = 0)
    [s * s * t, s * (RSD * SD - RSF * SF) * t.powf(2.0), (SD * SD + SF * SF - 2.0 * RDF * SD * SF) * t.powf(3.0) / 3.0]
}
fn vol_gen(t: f64, a: f64, rho: (f64, f64, f64)) -> f64 { (simpson(|u| inst_var(u, a, SS, rho), 0.0, t, 600) / t).sqrt() }
fn vol_eff(t: f64) -> f64 { vol_gen(t, 0.0, (RSD, RSF, RDF)) }        // road 2
fn coupon_g(t: f64, v: f64, rd: f64, rf: f64, disc: f64) -> (f64, f64, f64) {
    let (f, pd) = (S0 * ((rd - rf) * t).exp(), (-disc * t).exp());
    let d1 = ((f / K).ln() + 0.5 * v * v * t) / (v * t.sqrt()); let d2 = d1 - v * t.sqrt();
    (G * pd * (f * ncdf(d1) - K * ncdf(d2)), pd * (G * f - CD), G * pd * (K * ncdf(-d2) - f * ncdf(-d1)))
}
fn coupon(t: f64, v: f64) -> (f64, f64, f64) { coupon_g(t, v, RD, RF, RD) }
fn commas(x: f64) -> String {
    let s = format!("{:.2}", x); let (ip, fp) = s.split_at(s.find('.').unwrap());
    let mut out = String::new();
    for (i, ch) in ip.chars().enumerate() { if i > 0 && (ip.len() - i) % 3 == 0 { out.push(','); } out.push(ch); }
    out + fp
}
struct Rng(u64);
impl Rng {
    fn unif(&mut self) -> f64 {           // xorshift64, a uniform in (0, 1)
        self.0 ^= self.0 << 13; self.0 ^= self.0 >> 7; self.0 ^= self.0 << 17;
        ((self.0 >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn normal_pair(&mut self) -> (f64, f64) {
        let r = (-2.0 * self.unif().ln()).sqrt(); let t = 2.0 * PI * self.unif();
        (r * t.cos(), r * (t - 0.5 * PI).cos())
    }
}
fn mean_se(xs: &[f64]) -> (f64, f64) {
    let n = xs.len() as f64; let m = nsum(xs) / n;
    let sq: Vec<f64> = xs.iter().map(|v| (v - m) * (v - m)).collect();
    (m, (nsum(&sq) / (n - 1.0) / n).sqrt())
}
fn crossover(s: f64) -> f64 {             // bisection: the year the spot's share drops below half
    let (mut lo, mut hi) = (1.0_f64, 60.0_f64);
    for _ in 0..60 { let mid = 0.5 * (lo + hi); let v = var_closed(mid, s); if v[0] > v[1] + v[2] { lo = mid } else { hi = mid } }
    lo
}
fn main() {
    let (l21, l31) = (RSD, RSF);          // Cholesky factor of the 3 x 3 correlation matrix
    let l22 = (1.0 - l21 * l21).sqrt(); let l32 = (RDF - l31 * l21) / l22; let l33 = (1.0 - l31 * l31 - l32 * l32).sqrt();
    let (pairs, dt, marks) = (20000usize, 0.25_f64, [1i64, 10, 30]);
    let mut rng = Rng(0x2545F4914F6CDD1D);
    let mut acc = [[0.0_f64; 2]; 3]; let mut prs: Vec<Vec<[f64; 3]>> = vec![Vec::new(), Vec::new(), Vec::new()];
    for _ in 0..pairs {
        let mut zs = Vec::new();
        for _ in 0..(30.0 / dt) as usize { let (a, b) = rng.normal_pair(); let (c, _) = rng.normal_pair(); zs.push((a, b, c)); }
        let mut fl = [[0.0_f64; 3]; 3];
        for sign in [1.0_f64, -1.0] {
            let (mut x, mut ud, mut uf, mut ii, mut t) = (S0.ln(), RD, RF, 0.0_f64, 0.0_f64);
            for &(z1, z2, z3) in &zs {
                let w1 = sign * z1; let w2 = sign * (l21 * z1 + l22 * z2); let w3 = sign * (l31 * z1 + l32 * z2 + l33 * z3);
                let nd = ud + SD * SD * (t + 0.5 * dt) * dt + SD * dt.sqrt() * w2;               // Ho-Lee drift
                let nf = uf + (SF * SF * (t + 0.5 * dt) - RSF * SS * SF) * dt + SF * dt.sqrt() * w3; // quanto shift
                x += 0.5 * ((ud - uf) + (nd - nf)) * dt - 0.5 * SS * SS * dt + SS * dt.sqrt() * w1;
                ii += 0.5 * (ud + nd) * dt; ud = nd; uf = nf; t += dt;
                if (t - t.round()).abs() < 1e-9 {
                    if let Some(m) = marks.iter().position(|&mk| mk == t.round() as i64) {
                        let (d, st) = ((-ii).exp(), x.exp());
                        acc[m][0] += x; acc[m][1] += x * x;
                        for (i, v) in [d, d * st, d * G * (K - st).max(0.0)].iter().enumerate() { fl[m][i] += 0.5 * v; }
                    }
                }
            }
        }
        for m in 0..3 { prs[m].push(fl[m]); }
    }
    let n = 2.0 * pairs as f64;
    let mc = |m: usize| {
        let (m1, m2) = (acc[m][0] / n, acc[m][1] / n);
        let col = |i: usize| -> Vec<f64> { prs[m].iter().map(|q| q[i]).collect() };
        (((m2 - m1 * m1) / marks[m] as f64).sqrt(), mean_se(&col(0)), mean_se(&col(1)), mean_se(&col(2)))
    };
    let grid = [1.0_f64, 5.0, 10.0, 15.0, 20.0, 25.0, 30.0];
    for t in [1.0_f64, 10.0, 30.0] {
        let v = var_closed(t, SS);
        println!("forward variance at {}y: spot, cross, rates, total  {:.6} {:.6} {:.6} {:.6} rest {:.6}", t, v[0], v[1], v[2], nsum(&v), v[1] + v[2]);
    }
    let cps: Vec<String> = [1.10_f64, 1.21, 1.40, 0.55].iter().map(|x| format!("{:.2}", 100.0 * (CF * x / S0 - CD).max(0.0))).collect();
    println!("coupon % at S_T = 1.10, 1.21, 1.40, 0.55: {} | 10% euro rise lifts it {:.2}% | EUR rate drift shift {:.6} | half V at 10y {:.6}", cps.join(" "),
             100.0 * ((CF * 1.21 / S0 - CD) / (CF - CD) - 1.0), -RSF * SS * SF, 0.5 * nsum(&var_closed(10.0, SS)));
    println!("year  vol closed  vol Simpson  bond vol  spot share  rates+cross share");
    for &t in &grid {
        let v = var_closed(t, SS); let tot = nsum(&v);
        println!("{:4} {:11.6} {:12.6} {:9.4} {:11.4} {:18.4}", t, (tot / t).sqrt(), vol_eff(t), SD * bfac(0.0, t), v[0] / tot, (v[1] + v[2]) / tot);
    }
    let lo = crossover(SS);
    println!("spot share falls below half at year {:.4}; quadratic root {:.4}", lo, (-12.0 + 1344.0_f64.sqrt()) / 2.0);
    println!("year  MC vol    D(T) MC   exp(-rd T)  D S MC    S0 exp(-rf T)  floor MC   +- se     floor Black");
    for m in 0..3 {
        let t = marks[m] as f64; let (v, (md, _), (mds, _), (mfl, se)) = mc(m);
        println!("{:4} {:9.6} {:9.6} {:10.6} {:9.6} {:13.6} {:9.6} {:9.6} {:11.6}", marks[m], v, md, (-RD * t).exp(), mds,
                 S0 * (-RF * t).exp(), mfl, se, coupon(t, vol_eff(t)).2);
    }
    for t in [10.0_f64, 30.0] {
        let v = vol_eff(t); let f = S0 * ((RD - RF) * t).exp(); let d1 = ((f / K).ln() + 0.5 * v * v * t) / (v * t.sqrt());
        let (c, lin, fl) = coupon(t, v); let c0 = coupon(t, SS).0; let d2 = d1 - v * t.sqrt();
        println!("{}y coupon: forward {:.6} D(T) {:.6} d1 {:.6} d2 {:.6} N(d1) {:.6} N(d2) {:.6}", t, f, (-RD * t).exp(), d1,
                 d1 - v * t.sqrt(), ncdf(d1), ncdf(d1 - v * t.sqrt()));
        println!("{}y coupon: g {:.6} K {:.6} g F {:.6} ln(F/K) {:.6} sd {:.6} F N(d1) - K N(d2) {:.6}", t, G, K, G * f,
                 (f / K).ln(), v * t.sqrt(), f * ncdf(d1) - K * ncdf(d2));
        println!("{}y coupon: value {:.6} = linear {:.6} + floor {:.6}; USD on 10m {}", t, c, lin, fl, commas(NOTE * c));
        println!("{}y coupon: spot vol only {:.6}; USD on 10m {}; gap {}", t, c0, commas(NOTE * c0), commas(NOTE * (c - c0)));
    }
    println!("strip year  vol      forward   value     floor     floor at spot vol");
    let (mut tot, mut tot0) = (0.0_f64, 0.0_f64);
    for y in 1..=30 {
        let t = y as f64; let (c, _, fl) = coupon(t, vol_eff(t)); let (c0, _, fl0) = coupon(t, SS); tot += c; tot0 += c0;
        if grid.contains(&t) { println!("strip {:4} {:8.6} {:8.6} {:9.6} {:9.6} {:9.6}", y, vol_eff(t), S0 * ((RD - RF) * t).exp(), c, fl, fl0); }
    }
    println!("strip of 30 coupons: {:.6} (USD {}); spot vol only {:.6} (USD {}); gap {}", tot, commas(NOTE * tot), tot0, commas(NOTE * tot0), commas(NOTE * (tot - tot0)));
    let v30 = vol_eff(30.0);
    println!("30y floor, full vol over spot vol: {:.2}", coupon(30.0, v30).2 / coupon(30.0, SS).2);
    let wrong = [("spot vol only", SS), ("correlations dropped", vol_gen(30.0, 0.0, (0.0, 0.0, 0.0))),
        ("bond vol = rate vol, not rate vol x years", (inst_var(0.0, 0.0, SS, (RSD, RSF, RDF)) + (SD * SD + SF * SF - 2.0 * RDF * SD * SF) + 2.0 * SS * (RSD * SD - RSF * SF)).sqrt())];
    for (name, v) in wrong { println!("wrong 30y: {:<42} vol {:.6} value {:.6}", name, v, coupon(30.0, v).0); }
    println!("wrong 30y: {:<42} vol {:.6} value {:.6}", "discounted at the EUR rate", v30, coupon_g(30.0, v30, RD, RF, RF).0);
    println!("try: a = 0.05 vol at 30y {:.6}; spot vol 15% crossover year {:.4}", vol_gen(30.0, 0.05, (RSD, RSF, RDF)), crossover(0.15));
    let sw: Vec<(f64, f64, f64)> = (1..=30).map(|y| coupon_g(y as f64, vol_eff(y as f64), RF, RD, RF)).collect();
    let sw0: Vec<(f64, f64, f64)> = (1..=30).map(|y| coupon_g(y as f64, SS, RF, RD, RF)).collect();
    let s1: Vec<f64> = sw.iter().map(|c| c.0).collect(); let s0: Vec<f64> = sw0.iter().map(|c| c.0).collect();
    println!("try: rates swapped, 30y forward {:.6}, 30y floor {:.6} (spot vol {:.6}); strip {:.6} (spot vol {:.6})", S0 * ((RF - RD) * 30.0).exp(), sw[29].2, sw0[29].2, nsum(&s1), nsum(&s0));
    let cv: Vec<String> = grid.iter().map(|&t| format!("{:6.2}", 100.0 * vol_eff(t))).collect();
    println!("chart, vol %  {}", cv.join(" "));
    let sp: Vec<String> = grid.iter().map(|_| format!("{:6.2}", 100.0 * SS)).collect();
    println!("chart, spot % {}", sp.join(" "));
    let bv: Vec<String> = grid.iter().map(|&t| format!("{:6.2}", 100.0 * SD * bfac(0.0, t))).collect();
    println!("chart, bond % {}", bv.join(" "));
    assert!(grid.iter().all(|&t| ((nsum(&var_closed(t, SS)) / t).sqrt() - vol_eff(t)).abs() < 1e-9), "closed form vs Simpson");
    let spec: Vec<f64> = marks.iter().map(|&t| (100.0 * vol_eff(t as f64) * 100.0).round() / 100.0).collect();
    assert!(spec == vec![10.21, 13.17, 22.80], "the spec's three volatilities");
    for m in 0..3 {
        let t = marks[m] as f64; let (v, (md, ed), (mds, eds), (mfl, se)) = mc(m);
        assert!((v - vol_eff(t)).abs() < 4.0 * (0.5 / pairs as f64).sqrt() * vol_eff(t), "simulated spread of ln S_T vs the formula");
        if m == 0 { continue; }           // 1 year: printed for reference only (floor 0 on every path)
        assert!((md - (-RD * t).exp()).abs() < 4.0 * ed + 1e-6, "simulated dollar bond vs today's curve");
        assert!((mds - S0 * (-RF * t).exp()).abs() < 4.0 * eds + 1e-6, "EUR deposit is worth S0 P_f in USD");
        assert!((mfl - coupon(t, vol_eff(t)).2).abs() < 4.0 * se + 1e-6, "simulated floor vs Black floor");
    }
    let c10 = coupon(10.0, vol_eff(10.0));
    assert!((c10.0 - (c10.1 + c10.2)).abs() < 1e-9, "coupon = linear + floor");
    assert!((lo - (-12.0 + 1344.0_f64.sqrt()) / 2.0).abs() < 1e-6, "bisection vs the quadratic root");
    println!("ALL CHECKS PASS");
}
