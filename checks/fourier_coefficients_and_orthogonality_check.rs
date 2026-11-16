// Fourier coefficients and orthogonality -- the check behind the card.
// std only. A complex number is a small struct; every integral is a midpoint
// sum written out, and every closed form is coded separately.
use std::f64::consts::PI;

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl C {
    fn new(re: f64, im: f64) -> C { C { re, im } }
    fn cis(a: f64) -> C { C::new(a.cos(), a.sin()) }         // e^(ia)
    fn add(self, o: C) -> C { C::new(self.re + o.re, self.im + o.im) }
    fn sub(self, o: C) -> C { C::new(self.re - o.re, self.im - o.im) }
    fn mul(self, o: C) -> C { C::new(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) }
    fn scale(self, s: f64) -> C { C::new(self.re * s, self.im * s) }
    fn div(self, o: C) -> C { let d = o.re * o.re + o.im * o.im; self.mul(C::new(o.re, -o.im)).scale(1.0 / d) }
    fn abs(self) -> f64 { self.re.hypot(self.im) }
    fn phase(self) -> f64 { self.im.atan2(self.re) }
}

const F: f64 = 220.0; // cycles a second: the siren flips 440 times a second
const P: f64 = 1.0 / F; // one period, in seconds

fn fx(x: f64) -> String { format!("{:.6}", if x.abs() < 5e-7 { 0.0 } else { x }) }
fn cx(z: C) -> String {
    format!("{} {} {}i", fx(z.re), if z.im < -5e-7 { "-" } else { "+" }, fx(z.im.abs()))
}

// +1 V for the first fraction d of each period, -1 V after
fn pulse(t: f64, d: f64) -> f64 { if (t / P).rem_euclid(1.0) < d { 1.0 } else { -1.0 } }

// (1/T) * integral over [0, T) of sig(t) e^(-2 pi i nu t) dt, M midpoint slices
fn coef_t(sig: &dyn Fn(f64) -> f64, nu: f64, m: usize, t_len: f64) -> C {
    let h = t_len / m as f64;
    let mut s = C::new(0.0, 0.0);
    for k in 0..m {
        let t = (k as f64 + 0.5) * h;
        s = s.add(C::cis(-2.0 * PI * nu * t).scale(sig(t)));
    }
    s.scale(h / t_len)
}

fn coef_exact(n: i64, d: f64) -> C {
    if n == 0 { return C::new(2.0 * d - 1.0, 0.0); }
    let nf = n as f64;
    C::new(1.0, 0.0).sub(C::cis(-2.0 * PI * nf * d)).div(C::new(0.0, PI * nf))
}

// a_n, b_n from their own real integrals over one period
fn real_ab(sig: &dyn Fn(f64) -> f64, n: f64, m: usize) -> (f64, f64) {
    let h = P / m as f64;
    let (mut a, mut b) = (0.0, 0.0);
    for k in 0..m {
        let t = (k as f64 + 0.5) * h;
        a += sig(t) * (2.0 * PI * n * t / P).cos();
        b += sig(t) * (2.0 * PI * n * t / P).sin();
    }
    (2.0 * a * h / P, 2.0 * b * h / P)
}

// <e_m, e_n> = (1/2pi) int e^(imx) e^(-inx) dx over -pi <= x < pi
fn inner(m: f64, n: f64, mm: usize) -> C {
    let h = 2.0 * PI / mm as f64;
    let mut s = C::new(0.0, 0.0);
    for k in 0..mm {
        let x = -PI + (k as f64 + 0.5) * h;
        s = s.add(C::cis(m * x).mul(C::cis(-n * x)));
    }
    s.scale(h / (2.0 * PI))
}

fn main() {
    println!("period P = 1/220 s = {} ms; flips a second = {:.0}", fx(P * 1000.0), 2.0 * F);

    // ---- road check: the square wave, b_n = 4/(pi n) for odd n ----
    let sq = |t: f64| pulse(t, 0.5);
    println!("square wave n, b_n numeric, 4/(pi n)");
    for n in [1i64, 2, 3, 5] {
        let (a, b) = real_ab(&sq, n as f64, 40000);
        let want = if n % 2 == 1 { 4.0 / (PI * n as f64) } else { 0.0 };
        println!("  {} {} {}  a_n {}", n, fx(b), fx(want), fx(a));
        assert!((b - want).abs() < 1e-5 && a.abs() < 1e-9);
    }

    // ---- orthonormality ----
    let mut worst: f64 = 0.0;
    for m in -3..4 {
        for n in -3..4 {
            let id = if m == n { 1.0 } else { 0.0 };
            worst = worst.max(inner(m as f64, n as f64, 4000).sub(C::new(id, 0.0)).abs());
        }
    }
    println!("gram matrix n = -3..3: largest gap from identity {}", fx(worst));
    assert!(worst < 1e-9);
    let leak = inner(1.5, 1.0, 200000);
    println!("<e^(1.5ix), e^(ix)> = {} (closed form 2/pi = {})", cx(leak), fx(2.0 / PI));
    assert!(leak.sub(C::new(2.0 / PI, 0.0)).abs() < 1e-6);

    // ---- the worked signal: 25% pulse ----
    let d = 0.25;
    let pl = |t: f64| pulse(t, d);
    println!("pulse high for {} ms, low for {} ms", fx(d * P * 1000.0), fx((1.0 - d) * P * 1000.0));
    println!("n, Hz, c_n closed form, error at M=400, error at M=4000");
    for n in 0..9i64 {
        let c = coef_exact(n, d);
        let e1 = coef_t(&pl, n as f64 / P, 400, P).sub(c).abs();
        let e2 = coef_t(&pl, n as f64 / P, 4000, P).sub(c).abs();
        println!("  {} {} {} {:.9} {:.9}", n, n * 220, cx(c), e1, e2);
        assert!(e2 < e1 / 50.0 || e1 < 1e-12);
        assert!(e2 < 1e-6);
    }
    println!("n, a_n, b_n from real integrals, 2 Re c_n, -2 Im c_n, amplitude 2|c_n|");
    for n in 1..5i64 {
        let (a, b) = real_ab(&pl, n as f64, 4000);
        let c = coef_exact(n, d);
        println!("  {} {} {} {} {} {}", n, fx(a), fx(b), fx(2.0 * c.re), fx(-2.0 * c.im), fx(2.0 * c.abs()));
        assert!((a - 2.0 * c.re).abs() < 1e-6 && (b + 2.0 * c.im).abs() < 1e-6);
    }
    let c1 = coef_exact(1, d);
    let peak = -c1.phase() / (2.0 * PI) * P * 1000.0;
    println!("220 Hz share: |c_1| = {}, 2 sin(pi d)/pi = {}, crest at t = {} ms", fx(c1.abs()), fx(2.0 * (PI * d).sin() / PI), fx(peak));
    assert!((c1.abs() - 2.0 * (PI * d).sin() / PI).abs() < 1e-12 && (peak - d * P * 1000.0 / 2.0).abs() < 1e-9);

    // ---- Pythagoras on a finite sum ----
    let cs: Vec<(i64, C)> = (-3..4).map(|n| (n, coef_exact(n, d))).collect();
    let s3 = |x: f64| cs.iter().fold(C::new(0.0, 0.0), |acc, &(n, c)| acc.add(c.mul(C::cis(n as f64 * x))));
    let mm = 4000;
    let mut norm2 = 0.0;
    for k in 0..mm { norm2 += s3(2.0 * PI * (k as f64 + 0.5) / mm as f64).abs().powi(2); }
    norm2 /= mm as f64;
    let shares: f64 = cs.iter().map(|&(_, c)| c.abs().powi(2)).sum();
    println!("||S_3||^2 by integral {}, sum of |c_n|^2 {}, ||f||^2 = 1", fx(norm2), fx(shares));
    assert!((norm2 - shares).abs() < 1e-9 && shares < 1.0);

    // ---- what breaks ----
    println!("1/pi in the complex formula: |c_1| = {}, right {}", fx(2.0 * c1.abs()), fx(c1.abs()));
    let cp = coef_exact(-1, d); // e^(+inx) reads off c_(-n), the conjugate
    println!("e^(+ix) instead of e^(-ix): b_1 = {}, right {}", fx(-2.0 * cp.im), fx(-2.0 * c1.im));
    let w = 0.004; // a 4 ms window: not a whole number of periods
    let wt = 2.0 * PI * F * w; // exact over [0, W): a_1 = -2 sin(wT)/wT, b_1 = 2 (3 + cos wT)/wT
    let (aw, bw) = (-2.0 * wt.sin() / wt, 2.0 * (3.0 + wt.cos()) / wt);
    let cw: Vec<C> = [440usize, 4400].iter().map(|&m| coef_t(&sq, F, m, w)).collect(); // the jump at P/2 lands on a slice edge
    let ew: Vec<f64> = cw.iter().map(|c| C::new(2.0 * c.re - aw, -2.0 * c.im - bw).abs()).collect();
    println!("square wave over 4 ms: a_1 = {}, b_1 = {}, right 0, {}", fx(aw), fx(bw), fx(4.0 / PI));
    println!("  4 ms window, midpoint error at M=440 {:.9}, at M=4400 {:.9}", ew[0], ew[1]);
    assert!(ew[1] < ew[0] / 50.0 && ew[1] < 1e-6);
    assert!((-2.0 * cw[1].im - 4.0 / PI).abs() > 0.05);
    for eps in [1e-3f64, 1e-6] {
        println!("1/|x| mean, cut at {:.6}: (1/pi) log(pi/eps) = {}", eps, fx((PI / eps).ln() / PI));
    }
    println!("on-off 0..1 V wave: mean {}, b_1 = {}, right for +-1 V {}", fx(0.5), fx(2.0 / PI), fx(4.0 / PI));
    println!("12.5% pulse: c_0 = {}, |c_8| = {}, |c_4| = {}", fx(coef_exact(0, 0.125).re),
             fx(coef_exact(8, 0.125).abs()), fx(coef_exact(4, 0.125).abs()));

    // ---- pictures ----
    let ts: Vec<String> = (0..16).map(|k| format!("{:.2}", (k as f64 + 0.5) * P * 1000.0 / 16.0)).collect();
    println!("chart t ms: {}", ts.join(" "));
    let ps: Vec<String> = (0..16).map(|k| format!("{:.0}", pulse((k as f64 + 0.5) * P / 16.0, d))).collect();
    println!("chart pulse: {}", ps.join(" "));
    let ss: Vec<String> = (0..16).map(|k| format!("{:.2}", s3(2.0 * PI * (k as f64 + 0.5) / 16.0).re)).collect();
    println!("chart S_3: {}", ss.join(" "));
    for n in 1..9i64 {
        let aq = if n % 2 == 1 { 4.0 / (PI * n as f64) } else { 0.0 };
        println!("bars {} Hz square {} pulse {}", n * 220, fx(aq), fx(2.0 * coef_exact(n, d).abs()));
    }
    println!("ALL CHECKS PASS");
}
