// Newton and secant: the same check as the Python, in Rust.  No crates.
// Solve x^3 = 2 (the side of a cube that holds 2 cubic metres) both ways, measure
// each error against a bisection root, and test the error laws and the orders.
fn sci(v: f64) -> String { format!("{:.2e}", v) }          // 1.23e-10
fn f(x: f64) -> f64 { x * x * x - 2.0 }
fn df(x: f64) -> f64 { 3.0 * x * x }
fn f2(x: f64) -> f64 { f(x) * f(x) }                       // the double root
fn df2(x: f64) -> f64 { 6.0 * x * x * f(x) }
fn bisect(h: fn(f64) -> f64, mut a: f64, mut b: f64) -> (f64, u32) {  // signs only
    let mut n = 0;
    while a < (a + b) / 2.0 && (a + b) / 2.0 < b {
        let c = (a + b) / 2.0;
        if (h(c) < 0.0) == (h(a) < 0.0) { a = c } else { b = c }
        n += 1;
    }
    (if h(a).abs() <= h(b).abs() { a } else { b }, n)
}
fn newton(h: fn(f64) -> f64, dh: fn(f64) -> f64, x: f64, steps: usize) -> Vec<f64> {
    let mut xs = vec![x];                                  // stops if it lands on a zero
    for _ in 0..steps {
        let x = xs[xs.len() - 1];
        if h(x) == 0.0 { break }
        xs.push(x - h(x) / dh(x));
    }
    xs
}
fn secant(h: fn(f64) -> f64, x0: f64, x1: f64, steps: usize) -> (Vec<f64>, Option<usize>) {
    let (mut xs, mut fs) = (vec![x0, x1], vec![h(x0), h(x1)]);   // stops if the chord is flat
    for _ in 0..steps {
        let n = xs.len();
        let d = fs[n - 1] - fs[n - 2];
        if d == 0.0 { return (xs, Some(n - 1)) }
        let x = xs[n - 1] - fs[n - 1] * (xs[n - 1] - xs[n - 2]) / d;
        xs.push(x); fs.push(h(x));
    }
    (xs, None)
}
fn order(e: &[f64], k: usize) -> f64 { (e[k + 1] / e[k]).ln() / (e[k] / e[k - 1]).ln() }
fn first(xs: &[f64], r: f64) -> usize { xs.iter().position(|x| (x - r).abs() < 1e-9).unwrap() }
fn main() {
    let (r, halvings) = bisect(f, 1.0, 2.0);
    let phi = (1.0 + 5f64.sqrt()) / 2.0;
    let c = r * r / 2.0;                                   // f''(r)/(2 f'(r)) = 1/r = r^2/2
    println!("root by bisection on [1, 2]: r = {:.16} after {} halvings; r^3 - 2 = {}", r, halvings, sci(f(r)));
    println!("constants: C = f''(r)/(2 f'(r)) = 1/r = {:.4}; golden ratio phi = {:.4}; C^(phi-1) = {:.4}", c, phi, c.powf(phi - 1.0));
    let xn = newton(f, df, 1.0, 5);
    let en: Vec<f64> = xn.iter().map(|x| (x - r).abs()).collect();
    println!("Newton from x0 = 1    k  x_k                 error e_k  digits  e_k/e_(k-1)^2  order");
    for k in 0..5 {
        if k > 0 {                                         // the exact error law, run in floats
            let pred = en[k - 1] * en[k - 1] * (2.0 * xn[k - 1] + r) / (3.0 * xn[k - 1] * xn[k - 1]);
            assert!((pred - en[k]).abs() <= 1e-4 * en[k]);
        }
        let ratio = if k > 0 { format!("{:.4}", en[k] / (en[k - 1] * en[k - 1])) } else { "-".to_string() };
        let p = if k >= 2 { format!("{:.3}", order(&en, k - 1)) } else { "-".to_string() };
        println!("{:21} {}  {:.16}  {:>9}  {:6.2}  {:>13}  {:>5}", "", k, xn[k], sci(en[k]), -en[k].log10(), ratio, p);
    }
    let (xs, _) = secant(f, 1.0, 2.0, 6);
    let es: Vec<f64> = xs.iter().map(|x| (x - r).abs()).collect();
    println!("secant from 1 and 2   k  x_k                 error e_k  digits  e_k/(e e)  e_k/e^phi  order");
    let mut q = [1.0f64; 8];
    for k in 0..8 {
        let (mut ratio, mut qs, mut p) = ("-".to_string(), "-".to_string(), "-".to_string());
        if k >= 2 {
            let (a, b) = (xs[k - 2], xs[k - 1]);
            let pred = es[k - 2] * es[k - 1] * (a + b + r) / (a * a + a * b + b * b);
            assert!((pred - es[k]).abs() <= 1e-4 * es[k]);
            q[k] = es[k] / es[k - 1].powf(phi);
            ratio = format!("{:.4}", es[k] / (es[k - 1] * es[k - 2]));
            qs = format!("{:.4}", q[k]);
            p = format!("{:.3}", order(&es, k - 1));
        }
        println!("{:21} {}  {:.16}  {:>9}  {:6.2}  {:>9}  {:>9}  {:>5}", "", k, xs[k], sci(es[k]), -es[k].log10(), ratio, qs, p);
    }
    let s8 = secant(f, 1.0, 2.0, 7).0[8];
    println!("Newton step 5: x = {:.16}, error {}; secant x_8: error {}", xn[5], sci(en[5]), sci((s8 - r).abs()));
    println!("both exact error laws matched the measured errors at every step, to 1 part in 10,000");
    assert!((en[4] / (en[3] * en[3]) - c).abs() < 0.001 && (es[7] / (es[6] * es[5]) - c).abs() < 0.001);
    assert!(en[3] > 1e-9 && 1e-9 > en[4] && es[6] > 1e-9 && 1e-9 > es[7] && en[5] < 2.3e-16);
    assert!((order(&en, 3) - 2.0).abs() < 0.02 && (order(&es, 6) - phi).abs() < 0.05);
    let gap: Vec<f64> = q.iter().map(|v| (v / c.powf(phi - 1.0)).ln().abs()).collect();
    assert!(gap[7] < gap[5] && gap[5] < gap[3] && gap[6] < gap[4] && gap[7] < 0.1);
    let mut d = vec![-es[5].log10(), -es[6].log10()];     // model: the law e' = C e e in logs
    for _ in 0..30 { let n = d.len(); d.push(d[n - 1] + d[n - 2] - c.log10()); }
    let n = d.len();
    let pm = (d[n - 1] - d[n - 2]) / (d[n - 2] - d[n - 3]);
    println!("the law alone, 30 more steps in logs (no rounding floor): order {:.6}", pm);
    assert!((pm - phi).abs() < 1e-6);
    let (mut ew, mut nb) = (1.0f64, 0);                    // bisection: half-width under 1e-9
    while ew / 2.0 > 1e-9 { ew /= 2.0; nb += 1; }
    println!("evaluations to an error under 1e-9: bisection 2 + {} halvings = {}; Newton 4 steps = 8 (4 of f, 4 of f'); secant 6 steps = 7", nb, 2 + nb);
    let (mut lo, mut hi) = (0.0f64, 2.0f64);               // break-even derivative cost
    while hi - lo > 1e-12 {
        let t = (lo + hi) / 2.0;
        if 2f64.powf(1.0 / (1.0 + t)) > phi { lo = t } else { hi = t }
    }
    println!("digits multiply per evaluation: secant {:.4}; Newton 2^(1/(1+t)), f' costing t evaluations of f:", phi);
    let ts: Vec<String> = ["0", "0.5", "1", "2"].iter()
        .map(|s| format!("t = {}: {:.4}", s, 2f64.powf(1.0 / (1.0 + s.parse::<f64>().unwrap())))).collect();
    println!("   {}", ts.join(", "));
    let fl = 2f64.ln() / phi.ln() - 1.0;
    println!("break-even t: bisection {:.4}, formula log(2)/log(phi) - 1 = {:.4}", lo, fl);
    assert!((lo - fl).abs() < 1e-9);
    println!("from 1 correct digit to 16: Newton {:.2} steps, secant {:.2} steps", 16f64.ln() / 2f64.ln(), 16f64.ln() / phi.ln());
    let gn = newton(f2, df2, 1.0, 60);
    let (gs, _) = secant(f2, 1.0, 2.0, 80);
    let (kn, ks) = (first(&gn, r), first(&gs, r));
    let qn = (gn[kn] - r).abs() / (gn[kn - 1] - r).abs();
    let qq = (gs[ks] - r).abs() / (gs[ks - 1] - r).abs();
    println!("break 1, double root (x^3-2)^2: Newton {} steps, ratio {:.4}; secant {} steps, ratio {:.4}", kn, qn, ks - 1, qq);
    assert!((qn - 0.5).abs() < 0.01 && (qq - (phi - 1.0)).abs() < 0.03);
    let mut fx = vec![1.0f64];                             // chord always from the fixed end 2
    for _ in 0..60 { let x = fx[fx.len() - 1]; fx.push(x - f(x) * (x - 2.0) / (f(x) - f(2.0))); }
    let kf = first(&fx, r);
    let qf = (fx[kf] - r).abs() / (fx[kf - 1] - r).abs();
    let qth = (2.0 - r) * (2.0 + 2.0 * r) / (4.0 + 2.0 * r + r * r);
    println!("break 2, one end frozen at 2: {} steps, ratio {:.4}, theory (2-r)(2+2r)/(4+2r+r^2) = {:.4}", kf, qf, qth);
    assert!((qf - qth).abs() < 0.001);
    let (xl, stall) = secant(f, 1.0, 2.0, 20);
    let st = stall.unwrap();
    println!("break 3, secant with no stop: x_{} = x_{}, so f(x_{}) - f(x_{}) = {:.1} and the step to x_{} is 0/0",
             st, st - 1, st, st - 1, f(xl[st]) - f(xl[st - 1]), st + 1);
    let xp = |x: f64| 40.0 + 250.0 * (x - 0.9);
    let yp = |y: f64| 182.5 - 25.0 * y;
    println!("figure, start ({:.1}, {:.1}), (2, 6) at ({:.1}, {:.1}), tangent lands {:.3} at {:.1}, chord lands {:.3} at {:.1}, root {:.3} at {:.1}, axis y {:.1}",
             xp(1.0), yp(-1.0), xp(2.0), yp(6.0), xn[1], xp(xn[1]), xs[2], xp(xs[2]), r, xp(r), yp(0.0));
    println!("ALL CHECKS PASS");
}
