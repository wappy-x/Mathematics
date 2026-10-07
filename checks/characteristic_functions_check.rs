// Characteristic functions -- the check behind the card.  Rust std only, no crates.
// Complex numbers are a pair written out here; every average is a finite sum or
// a Simpson integral; dice totals come from a probability table built roll by roll,
// and the 100-roll count of each total is exact, in whole numbers of five 64-bit words.
use std::f64::consts::PI;

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn e(x: f64) -> C { C { re: x.cos(), im: x.sin() } }          // the point at angle x on the circle
fn add(a: C, b: C) -> C { C { re: a.re + b.re, im: a.im + b.im } }
fn mul(a: C, b: C) -> C { C { re: a.re * b.re - a.im * b.im, im: a.re * b.im + a.im * b.re } }
fn sc(a: C, k: f64) -> C { C { re: a.re * k, im: a.im * k } }
fn abs(a: C) -> f64 { (a.re * a.re + a.im * a.im).sqrt() }
fn pw(a: C, n: u32) -> C { (0..n).fold(C { re: 1.0, im: 0.0 }, |p, _| mul(p, a)) }
fn cz(z: C) -> String { format!("{:+.6} {:+.6}i", z.re, z.im) }
fn row(label: &str, vals: &[String]) { println!("{:<50}{}", label, vals.join("  ")); }

fn cf_die(t: f64) -> C { sc((1..=6).fold(C { re: 0.0, im: 0.0 }, |s, k| add(s, e(t * k as f64))), 1.0 / 6.0) }
fn cf_die6(t: f64) -> C { sc((7..=12).fold(C { re: 0.0, im: 0.0 }, |s, k| add(s, e(t * k as f64))), 1.0 / 6.0) } // die + 6, own faces
fn cf_die_closed(t: f64) -> C { sc(e(3.5 * t), (3.0 * t).sin() / (6.0 * (t / 2.0).sin())) }
fn c(s: f64) -> f64 { if s == 0.0 { 1.0 } else { (3.0 * s).sin() / (6.0 * (s / 2.0).sin()) } }

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}
fn dens(x: f64) -> f64 { (-x * x / 2.0).exp() / (2.0 * PI).sqrt() }
fn cf_normal_int(t: f64) -> f64 { simpson(|x| (t * x).cos() * dens(x), -12.0, 12.0, 2400) }
fn cf_normal_ode(t: f64) -> f64 {                             // phi' = -s phi, phi(0) = 1, by RK4
    let (steps, mut y, mut s) = (1000, 1.0, 0.0);
    let h = t / steps as f64;
    for _ in 0..steps {
        let k1 = -s * y;
        let k2 = -(s + h / 2.0) * (y + h / 2.0 * k1);
        let k3 = -(s + h / 2.0) * (y + h / 2.0 * k2);
        let k4 = -(s + h) * (y + h * k3);
        y += h * (k1 + 2.0 * k2 + 2.0 * k3 + k4) / 6.0;
        s += h;
    }
    y
}
fn law(n: usize) -> Vec<f64> {                                // P(total = s) after n rolls
    let mut p = vec![1.0];
    for _ in 0..n {
        let mut q = vec![0.0; p.len() + 6];
        for (s, m) in p.iter().enumerate() { for k in 1..=6 { q[s + k] += m / 6.0; } }
        p = q;
    }
    p
}
type Big = [u64; 5];                                          // a whole number in five 64-bit words; 6^100 < 2^259
fn big_add(a: Big, b: Big) -> Big {
    let (mut r, mut carry) = ([0u64; 5], false);
    for i in 0..5 {
        let (x, c1) = a[i].overflowing_add(b[i]);
        let (y, c2) = x.overflowing_add(carry as u64);
        r[i] = y;
        carry = c1 || c2;
    }
    assert!(!carry);                                          // five words are enough
    r
}
fn big_f64(a: Big) -> f64 { a.iter().rev().fold(0.0, |acc, &w| acc * 18446744073709551616.0 + w as f64) }
fn ways(n: usize) -> Vec<Big> {                               // exact number of ways to roll each total
    let mut w: Vec<Big> = Vec::from([[1u64, 0, 0, 0, 0]]);
    for _ in 0..n {
        let mut q = vec![Big::default(); w.len() + 6];
        for (s, m) in w.iter().enumerate() { for k in 1..=6 { q[s + k] = big_add(q[s + k], *m); } }
        w = q;
    }
    w                                                         // w[s] = ways to total s; 6^n in all
}
fn cf_w(n: u32, t: f64) -> f64 { c(t / ((35.0f64 / 12.0).sqrt() * (n as f64).sqrt())).powi(n as i32) }

fn main() {
    // the die at t = 0.5
    let t = 0.5;
    let (d1, d2) = (cf_die(t), cf_die_closed(t));
    let cs: Vec<String> = (1..=6).map(|k| (t * k as f64).cos()).chain((1..=6).map(|k| (t * k as f64).sin())).map(|v| format!("{:.4}", v)).collect();
    println!("die at t = 0.5, cos then sin of 0.5k: {}", cs.join(" "));
    row("die phi(0.5): six points averaged / closed form", &[cz(d1), cz(d2)]);
    row("size |phi(0.5)| = sin 1.5 / (6 sin 0.25)", &[format!("{:.6}", c(t)), format!("{:.6}", abs(d1))]);
    let pts: Vec<String> = (1..=6).map(|k| { let a = t * k as f64;
        format!("{:.1} {:.1}", 180.0 + 90.0 * a.cos(), 130.0 - 90.0 * a.sin()) }).collect();
    println!("figure, points 1-6 (x y): {}", pts.join(" "));
    println!("figure, average (x y): {:.1} {:.1}", 180.0 + 90.0 * d1.re, 130.0 - 90.0 * d1.im);
    assert!(abs(add(d1, sc(d2, -1.0))) < 1e-12);
    // the uniform and the normal
    let u_int = C { re: simpson(|x| x.cos(), 0.0, 1.0, 200), im: simpson(|x| x.sin(), 0.0, 1.0, 200) };
    let u_closed = C { re: 1.0f64.sin(), im: 1.0 - 1.0f64.cos() };   // (e^i - 1)/i worked by hand
    row("uniform phi(1), Simpson / (e^i - 1)/i", &[cz(u_int), cz(u_closed)]);
    let (n_int, n_ode) = (cf_normal_int(1.0), cf_normal_ode(1.0));
    row("normal phi(1), Simpson / ODE / e^(-1/2)", &[format!("{:.9}", n_int), format!("{:.9}", n_ode), format!("{:.9}", (-0.5f64).exp())]);
    assert!(abs(add(u_int, sc(u_closed, -1.0))) < 1e-9);
    assert!((n_int - n_ode).abs().max((n_ode - (-0.5f64).exp()).abs()) < 1e-9);   // three roads
    // moments from derivatives, against exact integer sums over 6
    let h = 1e-4;
    let m1 = sc(add(cf_die(h), sc(cf_die(-h), -1.0)), 1.0 / (2.0 * h)).im;
    let m2 = -(cf_die(h).re - 2.0 + cf_die(-h).re) / (h * h);
    let (s1, s2): (i64, i64) = ((1..=6).sum(), (1..=6).map(|k| k * k).sum());
    let (ex1, ex2) = (s1 as f64 / 6.0, s2 as f64 / 6.0);
    row("die E X: phi'(0)/i, exact 21/6", &[format!("{:.4}", m1), format!("{:.6}", ex1)]);
    row("die E X^2: -phi''(0), exact 91/6", &[format!("{:.4}", m2), format!("{:.6}", ex2)]);
    row("die variance 91/6 - 3.5^2 = 35/12", &[format!("{:.6}", (6 * s2 - s1 * s1) as f64 / 36.0), format!("sd {:.6}", (35.0f64 / 12.0).sqrt())]);
    assert!((m1 - ex1).abs() < 1e-6);
    assert!((m2 - ex2).abs() < 1e-4);
    // the n-roll total
    let mut w2 = [0u64; 13];
    for a in 1..=6 { for b in 1..=6 { w2[a + b] += 1; } }
    row("two dice, P(total 7): count / 36", &[format!("{}/36 = {:.6}", w2[7], w2[7] as f64 / 36.0)]);
    let p100 = law(100);
    let t = 0.05;
    let direct = p100.iter().enumerate().fold(C { re: 0.0, im: 0.0 }, |z, (s, &m)| add(z, sc(e(t * s as f64), m)));
    row("100 rolls phi(0.05): from the law / phi^100", &[cz(direct), cz(pw(cf_die(t), 100))]);
    assert!(abs(add(direct, sc(pw(cf_die(t), 100), -1.0))) < 1e-12);
    row("100 rolls: mean, variance, sd", &["350".into(), format!("{:.2}", 100.0 * 35.0 / 12.0), format!("{:.2}", (100.0f64 * 35.0 / 12.0).sqrt())]);
    // inversion on the integers
    let m = 1024;
    let inv = (0..m).fold(0.0, |acc, j| { let tj = 2.0 * PI * j as f64 / m as f64;
        acc + mul(e(-350.0 * tj), pw(cf_die(tj), 100)).re }) / m as f64;
    let w100 = ways(100);
    let exact = big_f64(w100[350]) / big_f64(w100.iter().fold([0u64; 5], |a, &b| big_add(a, b)));   // count over 6^100
    row("P(100 rolls total 350): exact / inversion", &[format!("{:.9}", exact), format!("{:.9}", inv)]);
    assert!((inv - exact).abs() < 1e-12);
    // Levy in action
    row("phi_Wn(1), n = 1, 10, 100, 1000", &[1, 10, 100, 1000].iter().map(|&n| format!("{:.6}", cf_w(n, 1.0))).collect::<Vec<_>>());
    row("  limit e^(-1/2)", &[format!("{:.6}", (-0.5f64).exp())]);
    let phi1 = 0.5 + simpson(dens, 0.0, 1.0, 200);
    let cdf: Vec<String> = [10usize, 100, 400].iter().map(|&n| {
        let cut = (3.5 * n as f64 + (35.0 * n as f64 / 12.0).sqrt()) as usize;
        format!("{:.6}", law(n)[..=cut].iter().sum::<f64>()) }).collect();
    row("P(W_n <= 1), n = 10, 100, 400", &cdf);
    row("  normal Phi(1)", &[format!("{:.6}", phi1)]);
    row("running average: phi(1/n)^n, n = 10, 100, 1000", &[10u32, 100, 1000].iter().map(|&n| cz(pw(cf_die(1.0 / n as f64), n))).collect::<Vec<_>>());
    row("  the constant 3.5: e^(3.5i)", &[cz(e(3.5))]);
    assert!((cf_w(1000, 1.0) - n_ode).abs() < 1e-3);
    // what breaks
    row("two dice vs one die doubled, |phi(0.5)|", &[format!("{:.6}", abs(pw(cf_die(0.5), 2))), format!("{:.6}", abs(cf_die(1.0)))]);
    let gap = (1..=12).map(|k| { let tk = k as f64 * PI / 3.0;
        abs(add(cf_die6(tk), sc(cf_die(tk), -1.0))) }).fold(0.0, f64::max);
    let gap1 = abs(add(cf_die6(1.0), sc(cf_die(1.0), -1.0)));
    row("die vs die + 6: max gap at t = k pi/3, k<=12", &[format!("{:.6}", gap)]);
    row("die vs die + 6: gap at t = 1", &[format!("{:.6}", gap1)]);
    assert!(gap < 1e-12); // die + 6 from its own faces agrees at every k pi/3
    assert!((gap1 - 2.0 * 3.0f64.sin().abs() * abs(cf_die(1.0))).abs() < 1e-12); // and at t = 1 differs by |e^(6i) - 1| |phi(1)|
    let near: Vec<f64> = [4usize, 36, 400].iter().map(|&n| { let (p, m) = (law(n), (3.5 * n as f64).round() as usize);
        p[m - 5..=m + 5].iter().sum() }).collect();
    row("unscaled T_n = S_n - 3.5n, |phi(0.5)|, n=4,36,400", &[4, 36, 400].iter().map(|&n| format!("{:.6}", c(0.5).abs().powi(n))).collect::<Vec<_>>());
    row("  P(|T_n| <= 5), n = 4, 36, 400", &near.iter().map(|p| format!("{:.6}", p)).collect::<Vec<_>>());
    let bw = simpson(|s| 1.0 - cf_w(100, s), -1.0, 1.0, 2000);
    let bt = simpson(|s| 1.0 - c(s).powi(400), -1.0, 1.0, 2000);
    let p400 = law(400);
    let tail_t = 1.0 - p400[1398..=1402].iter().sum::<f64>();
    let sdn = 10.0 * (35.0f64 / 12.0).sqrt();
    let tail_w = 1.0 - (0..=600).filter(|&s| (s as f64 - 350.0).abs() <= 2.0 * sdn).map(|s| p100[s]).sum::<f64>();
    row("tail bound u=1: W_100 P(|W|>2) <= integral", &[format!("{:.6}", tail_w), format!("{:.6}", bw)]);
    row("tail bound u=1: T_400 P(|T|>2) <= integral", &[format!("{:.6}", tail_t), format!("{:.6}", bt)]);
    assert!(tail_w <= bw);
    assert!(tail_t <= bt);
    // the two charts
    let f = |v: Vec<f64>| v.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(" ");
    println!("figure, |phi(t)| at t = k pi/12: {}", f((0..25).map(|k| abs(cf_die(k as f64 * PI / 12.0))).collect()));
    println!("figure, |phi(t)|^4:             {}", f((0..25).map(|k| abs(cf_die(k as f64 * PI / 12.0)).powi(4)).collect()));
    println!("figure, t labels:                {}", f((0..25).map(|k| k as f64 * PI / 12.0).collect()));
    for n in [1u32, 4] { println!("figure, phi_W{}(t), t = 0..3: {}", n, f((0..13).map(|k| cf_w(n, k as f64 / 4.0)).collect())); }
    println!("figure, normal e^(-t^2/2): {}", f((0..13).map(|k| cf_normal_int(k as f64 / 4.0)).collect()));
}
