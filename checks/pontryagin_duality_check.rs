// Pontryagin duality -- the same check as the Python, in Rust.  No crates.  Four
// groups with their duals: the 12-hour clock Z/12, the circle, the integers Z and
// the line R.  A complex number is a small struct; every transform is written out.
use std::f64::consts::PI;
const N: usize = 12;

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl C {
    fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } }
    fn sub(self, o: C) -> C { C { re: self.re - o.re, im: self.im - o.im } }
    fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } }
    fn scale(self, s: f64) -> C { C { re: self.re * s, im: self.im * s } }
    fn div(self, o: C) -> C { let d = o.re * o.re + o.im * o.im; self.mul(o.conj()).scale(1.0 / d) }
    fn conj(self) -> C { C { re: self.re, im: -self.im } }
    fn abs(self) -> f64 { self.re.hypot(self.im) }
    fn pow(self, k: usize) -> C { let mut z = C { re: 1.0, im: 0.0 }; for _ in 0..k { z = z.mul(self) } z }
}
fn cis(t: f64) -> C { C { re: t.cos(), im: t.sin() } }           // e^(it)
fn re(x: f64) -> C { C { re: x, im: 0.0 } }

fn fx(x: f64, d: usize) -> String {                                // fixed decimals, no "-0"
    let x = if x.abs() < 0.5 * 10f64.powi(-(d as i32)) { 0.0 } else { x };
    format!("{:.*}", d, x)
}
fn fc(z: C) -> String { format!("{} {} {}i", fx(z.re, 6), if z.im < -5e-7 { "-" } else { "+" }, fx(z.im.abs(), 6)) }

fn simpson<F: Fn(f64) -> f64>(g: F, a: f64, b: f64, m: usize) -> f64 {   // m even
    let h = (b - a) / m as f64;
    let mut t = 0.0;
    for j in 1..m { t += if j % 2 == 1 { 4.0 } else { 2.0 } * g(a + j as f64 * h) }
    (g(a) + g(b) + t) * h / 3.0
}
fn chi(k: usize, x: usize) -> C { cis(2.0 * PI * k as f64 * x as f64 / N as f64) }   // character k at hour x
fn dft(f: &[C]) -> Vec<C> {                                         // counting measure on the hours
    (0..N).map(|k| (0..N).fold(re(0.0), |s, x| s.add(f[x].mul(chi(k, x).conj())))).collect()
}
fn gs(x: f64) -> f64 { (-PI * x * x).exp() }
fn ghat(s: f64) -> f64 {                                            // trapezoid, step 1/16 on [-8, 8]
    let mut t = 0.0;
    for j in -128i32..129 { let x = j as f64 / 16.0; t += gs(x) * (2.0 * PI * s * x).cos() }
    t / 16.0
}

fn main() {
    // 1. The clock's dual, and its multiplication.
    let roots: Vec<C> = (0..N).map(|k| cis(2.0 * PI * k as f64 / N as f64)).collect();
    println!("clock: characters found {}; chi_1 at hour 3 = {}; chi_2 at hour 3 = {}", roots.len(), fc(chi(1, 3)), fc(chi(2, 3)));
    let mut mult: f64 = 0.0;
    for a in 0..N { for b in 0..N { for x in 0..N { mult = mult.max(chi(a, x).mul(chi(b, x)).sub(chi((a + b) % N, x)).abs()) } } }
    println!("chi_a times chi_b = chi_(a+b), largest gap {}", fx(mult, 12));
    // 2. The double dual.
    let matched: Vec<Vec<usize>> = roots.iter().map(|&w| (0..N).filter(|&x|
        (0..N).map(|k| chi(k, x).sub(w.pow(k)).abs()).fold(0.0, f64::max) < 1e-9).collect()).collect();
    let firsts: Vec<usize> = matched.iter().map(|h| h[0]).collect();
    println!("double dual: {} characters of the dual, each equal to evaluation at hours {:?}", matched.len(), firsts);
    let sep = (1..N).map(|x| chi(1, x).sub(re(1.0)).abs()).fold(f64::INFINITY, f64::min);
    println!("characters separate hours: smallest |chi_1(x) - 1| over x = 1..11 is {}", fx(sep, 6));
    // 3. The clock inside the circle.
    let marks: Vec<f64> = (0..N).map(|x| 2.0 * PI * x as f64 / N as f64).collect();
    let gap13 = marks.iter().map(|&a| cis(13.0 * a).sub(cis(a)).abs()).fold(0.0, f64::max);
    let ann: Vec<i32> = (-30..31).filter(|&n| marks.iter().map(|&a| cis(n as f64 * a).sub(re(1.0)).abs()).fold(0.0, f64::max) < 1e-9).collect();
    println!("circle characters on the 12 marks: e^(13ix) minus e^(ix), largest gap {}; annihilator in Z, |n| <= 30: {:?}", fx(gap13, 12), ann);
    // 4. The line's characters, rebuilt from chi(delta) and the integral over [0, delta].
    let (xi, dl) = (0.5, 0.3);
    let c = C { re: simpson(|t| (2.0 * PI * xi * t).cos(), 0.0, dl, 200), im: simpson(|t| (2.0 * PI * xi * t).sin(), 0.0, dl, 200) };
    let a = cis(2.0 * PI * xi * dl).sub(re(1.0)).div(c);
    println!("line: chi'(0) rebuilt from chi(0.3) and its integral = {}, and 2 pi xi = {}", fc(a), fx(2.0 * PI * xi, 6));
    // 5. Plancherel and inversion on each pair.
    let f: Vec<C> = (0..N).map(|x| re(x as f64)).collect();
    let ff = dft(&f);
    let e_g: usize = (0..N).map(|x| x * x).sum();
    let e_d = ff.iter().fold(0.0, |s, z| s + z.abs().powi(2)) / N as f64;
    let inv = (0..N).map(|x| (0..N).fold(re(0.0), |s, k| s.add(ff[k].mul(chi(k, x)))).scale(1.0 / N as f64).sub(f[x]).abs()).fold(0.0, f64::max);
    println!("Z/12, f(x) = x: energy on the clock {}; on the dual, weight 1/12 each: {}; inversion error {}", e_g, fx(e_d, 6), fx(inv, 12));
    println!("  f-hat(0) = {}, its share {}; f-hat(4) = {}; f-hat(8) = {}", fx(ff[0].re, 6), fx(ff[0].abs().powi(2) / N as f64, 6), fc(ff[4]), fc(ff[8]));
    let m = 20000;
    let pts: Vec<f64> = (0..m).map(|j| (j as f64 + 0.5) * 2.0 * PI / m as f64 - PI).collect();
    let saw = pts.iter().fold(0.0, |s, x| s + x * x) / m as f64;
    let c3 = pts.iter().fold(re(0.0), |s, &x| s.add(cis(-3.0 * x).scale(x))).scale(1.0 / m as f64);
    let k = 100000;
    let basel = 2.0 * (1..k + 1).fold(0.0, |s, n| s + 1.0 / (n as f64 * n as f64));
    println!("circle, f(x) = x: f-hat(3) = {}; energy (1/2 pi) int x^2 dx = {}; pi^2/3 = {}", fc(c3), fx(saw, 6), fx(PI * PI / 3.0, 6));
    println!("  on Z: sum of 1/n^2 over 0 < |n| <= {} = {}; gap {}, tail bound 2/{} = {}", k, fx(basel, 9), fx(PI * PI / 3.0 - basel, 9), k, fx(2.0 / k as f64, 9));
    let cz = 2.0 * (1..61).fold(0.0, |s, n| s + 0.25f64.powi(n)) + 1.0;
    let p = |x: f64| 0.75 / (1.25 - x.cos());
    let ez = (0..64).fold(0.0, |s, j| s + p(2.0 * PI * j as f64 / 64.0).powi(2)) / 64.0;
    let c3z = (0..64).fold(0.0, |s, j| s + p(2.0 * PI * j as f64 / 64.0) * (3.0 * 2.0 * PI * j as f64 / 64.0).cos()) / 64.0;
    println!("Z, c_n = 2^-|n|: energy {}; on the circle, 64 points: {}; c_3 rebuilt = {}", fx(cz, 12), fx(ez, 12), fx(c3z, 12));
    let fl = simpson(|t: f64| (-2.0 * t.abs()).exp(), -40.0, 40.0, 80000);
    let fh = simpson(|t: f64| (-t.abs()).exp() * (2.0 * PI * xi * t).cos(), -40.0, 40.0, 80000);
    let xx = 100.0;
    let fhe = simpson(|s| (2.0 / (1.0 + 4.0 * PI * PI * s * s)).powi(2), -xx, xx, 200000);
    let tail = 1.0 / (6.0 * PI.powi(4) * xx * xx * xx);
    println!("R, f(t) = e^-|t|: energy {}; f-hat(0.5) by the integral {}, by 2/(1 + pi^2) {}", fx(fl, 9), fx(fh, 9), fx(2.0 / (1.0 + PI * PI), 9));
    println!("  energy of f-hat on |xi| <= {:.0} Hz: {}; tail bound 1/(6 pi^4 X^3) = {}", xx, fx(fhe, 9), fx(tail, 12));
    // 6. Convolution becomes multiplication (Gelfand).
    let g: Vec<C> = (0..N).map(|x| re(if x % 3 == 0 { 1.0 } else { 0.0 })).collect();
    let conv: Vec<C> = (0..N).map(|x| (0..N).fold(re(0.0), |s, y| s.add(f[y].mul(g[(x + N - y) % N])))).collect();
    let (gg, cc) = (dft(&g), dft(&conv));
    let cgap = (0..N).map(|k| cc[k].sub(ff[k].mul(gg[k])).abs()).fold(0.0, f64::max);
    println!("clock convolution: (f * g)-hat minus f-hat g-hat, largest gap {}", fx(cgap, 9));
    // 7. Poisson summation: a subgroup H and its annihilator.
    let lhs = (-6..7).fold(0.0, |s, n| s + gs(n as f64));
    let rhs = (-6..7).fold(0.0, |s, k| s + ghat(k as f64));
    println!("Poisson, H = Z in R: sum of e^(-pi n^2), |n| <= 6 = {:.14}; tail below {:.1e}", lhs, 3.0 * (-49.0 * PI).exp());
    println!("  sum over the annihilator Z of f-hat(k), each by the integral = {:.14}; gap {}", rhs, fx((lhs - rhs).abs(), 12));
    let l2 = 2.0 * (-6..7).fold(0.0, |s, n| s + gs(2.0 * n as f64));
    let r2 = (-12..13).fold(0.0, |s, k| s + ghat(k as f64 / 2.0));
    println!("Poisson, H = 2Z: 2 x sum of f(2n) = {:.12}; sum over (1/2)Z of f-hat = {:.12}", l2, r2);
    let h = [0usize, 3, 6, 9];
    let hp: Vec<usize> = (0..N).filter(|&k| h.iter().all(|&y| chi(k, y).sub(re(1.0)).abs() < 1e-9)).collect();
    let ps = hp.iter().fold(re(0.0), |s, &k| s.add(ff[k])).scale(h.len() as f64 / N as f64);
    println!("Poisson on the clock: H = {:?}, annihilator {:?}; sum of f on H = {}; |H|/12 x sum of f-hat there = {}", h, hp, h.iter().sum::<usize>(), fc(ps));
    // 8. What breaks.
    println!("mistake 1, counting measure on both sides: dual energy {}, not {}", fx(e_d * N as f64, 6), e_g);
    println!("mistake 2, all of Z as the clock's dual, k = 0..23: dual energy {}", fx((0..24).fold(0.0, |s, k| s + ff[k % N].abs().powi(2)) / N as f64, 6));
    println!("mistake 3, no weight 2 on the points of 2Z: {:.12}, not {:.12}", l2 / 2.0, r2);
    // S3: characters send r (a 3-cycle) and s (a swap) to sixth roots, r^3 = s^2 = 1, s r s = r^-1.
    let six: Vec<C> = (0..6).map(|k| cis(2.0 * PI * k as f64 / 6.0)).collect();
    let mut s3 = 0;
    for &u in &six { for &v in &six {
        if u.pow(3).sub(re(1.0)).abs() < 1e-9 && v.mul(v).sub(re(1.0)).abs() < 1e-9 && v.mul(u).mul(v).sub(u.conj()).abs() < 1e-9 { s3 += 1 }
    } }
    println!("mistake 4, S3 is not abelian: characters found {} for 6 members; delta at a swap: energy 1, dual energy {}", s3, fx(s3 as f64 / 6.0, 6));
    assert!(firsts.iter().enumerate().all(|(i, &x)| x == i) && matched.iter().all(|h| h.len() == 1)); // double dual
    assert!(ann == vec![-24, -12, 0, 12, 24] && a.sub(C { re: 0.0, im: 2.0 * PI * xi }).abs() < 1e-9 && sep > 0.5);
    assert!((e_d - 506.0).abs() < 1e-9 && inv < 1e-9 && c3.sub(C { re: 0.0, im: -1.0 / 3.0 }).abs() < 1e-6);
    assert!((saw - PI * PI / 3.0).abs() < 1e-6 && PI * PI / 3.0 - basel > 0.0 && PI * PI / 3.0 - basel < 2.0 / k as f64);
    assert!((ez - 5.0 / 3.0).abs() < 1e-12 && (cz - 5.0 / 3.0).abs() < 1e-12 && (c3z - 0.125).abs() < 1e-12);
    assert!((fh - 2.0 / (1.0 + PI * PI)).abs() < 1e-9 && (fl - 1.0).abs() < 1e-9 && (fhe + tail - 1.0).abs() < 1e-9);
    assert!((lhs - rhs).abs() < 1e-15 && (l2 - r2).abs() < 1e-14 && hp == vec![0, 4, 8] && ps.sub(re(18.0)).abs() < 1e-9);
    assert!(s3 == 2);
    println!("ALL CHECKS PASS");
}
