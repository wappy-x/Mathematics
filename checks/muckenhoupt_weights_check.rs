// Muckenhoupt weights -- the check behind the card.  std only, no crates.
// Every number on the card is printed here.  Nothing imported knows the answer.

fn f_anti(x: f64, e: f64) -> f64 {     // antiderivative of |x|^e, for e > -1
    (x.abs().powf(e + 1.0) / (e + 1.0)).copysign(x)
}
fn avg_exact(a: f64, b: f64, e: f64) -> f64 {   // road 1: average of |x|^e over [a, b], closed form
    (f_anti(b, e) - f_anti(a, e)) / (b - a)
}
fn simpson(g: &dyn Fn(f64) -> f64, lo: f64, hi: f64, n: usize) -> f64 {
    let h = (hi - lo) / n as f64;
    let mut acc = 0.0;
    for k in 1..n {
        acc += (if k % 2 == 1 { 4.0 } else { 2.0 }) * g(lo + k as f64 * h);
    }
    (g(lo) + g(hi) + acc) * h / 3.0
}
fn from_zero(c: f64, e: f64) -> f64 {  // integral of x^e over [0, c], by x = c u^8: no antiderivative
    simpson(&|u: f64| 8.0 * c.powf(e + 1.0) * u.powf(8.0 * e + 7.0), 0.0, 1.0, 2000)
}
fn avg_simpson(a: f64, b: f64, e: f64) -> f64 {  // road 2: the same average by Simpson's rule
    let side = |x: f64| from_zero(x.abs(), e).copysign(x);
    (side(b) - side(a)) / (b - a)
}
fn q(a: f64, b: f64, g: f64) -> f64 { avg_exact(a, b, g) * avg_exact(a, b, -g) }   // the A2 product
fn q_simpson(a: f64, b: f64, g: f64) -> f64 { avg_simpson(a, b, g) * avg_simpson(a, b, -g) }
fn a2_constant(g: f64) -> (f64, f64) {  // sup of q over all intervals; by scaling, intervals [u, 1]
    let (mut u0, mut best) = (-1.0, f64::NEG_INFINITY);
    for k in -1000..1000 {
        let u = k as f64 / 1000.0;
        if q(u, 1.0, g) > best { best = q(u, 1.0, g); u0 = u; }
    }
    let (mut lo, mut hi, r) = (u0 - 0.001, (u0 + 0.001f64).min(0.9999), (5f64.sqrt() - 1.0) / 2.0);
    for _ in 0..60 {                    // golden-section search on the best grid cell
        let (m1, m2) = (hi - r * (hi - lo), lo + r * (hi - lo));
        if q(m1, 1.0, g) < q(m2, 1.0, g) { lo = m1; } else { hi = m2; }
    }
    ((lo + hi) / 2.0, q((lo + hi) / 2.0, 1.0, g))
}
fn test_ratio(g: f64, eps: f64) -> f64 {  // f = 1/w on [eps,1]; Mf(x) >= average over [0, 2x]
    let s = |m: f64| if g == 1.0 { (m / eps).ln() } else { (m.powf(1.0 - g) - eps.powf(1.0 - g)) / (1.0 - g) };
    let integrand = |v: f64| s((2.0 * v.exp()).min(1.0)).powf(2.0) * ((g - 1.0) * v).exp() / 4.0;
    let mut num = 0.0;
    for (lo, hi) in [(eps.ln(), -(2f64).ln()), (-(2f64).ln(), 0.0)] { num += simpson(&integrand, lo, hi, 2000); }
    (num / s(1.0)).sqrt()
}
fn hilbert_ratio(eps: f64) -> f64 {     // gamma = 1, same f: |Hf| at x = -t is ln((t+eps)/(eps(1+t)))/(pi t)
    let pi = std::f64::consts::PI;
    let num = simpson(&|v: f64| ((v.exp() + eps) / (eps * (1.0 + v.exp()))).ln().powf(2.0),
                      eps.ln() - 30.0, 0.0, 20000) / pi.powf(2.0);
    (num / (1.0 / eps).ln()).sqrt()
}
fn hilbert_ratio2(eps: f64) -> f64 {    // road 2: |Hf| as ln_1p(t/eps) - ln_1p(t), cut 40 below ln eps, 30000 steps
    let num = simpson(&|v: f64| ((v.exp() / eps).ln_1p() - v.exp().ln_1p()).powf(2.0), eps.ln() - 40.0, 0.0, 30000);
    (num / std::f64::consts::PI.powf(2.0) / (1.0 / eps).ln()).sqrt()
}
fn osc_log(a: f64, b: f64) -> f64 {     // mean oscillation of ln x on [a, b], 0 <= a < b, by Simpson
    let xlx = |x: f64| if x > 0.0 { x * x.ln() - x } else { 0.0 };
    let m = (xlx(b) - xlx(a)) / (b - a);           // the mean of ln x on [a, b]
    let g = |x: f64| if x > 0.0 { (x.ln() - m).abs() } else { 0.0 };
    let c = m.exp();                               // where ln x crosses its mean: split there
    let mut total = 0.0;
    for (lo, hi) in [(a, c), (c, b)] {
        total += simpson(&|u: f64| g(lo + (hi - lo) * u.powf(8.0)) * 8.0 * (hi - lo) * u.powf(7.0), 0.0, 1.0, 20000);
    }
    total / (b - a)
}

fn main() {
    let g0 = 0.5;
    println!("weight w(x) = |x|^{}", g0);
    for a in [0.01, 1.0, 100.0] {       // intervals [0, a] at three scales
        let (e1, e2, s) = (avg_exact(0.0, a, g0), avg_exact(0.0, a, -g0), q_simpson(0.0, a, g0));
        println!("I=[0,{}]: avg w={:.6} avg 1/w={:.6} product={:.6} simpson={:.6}", a, e1, e2, e1 * e2, s);
        assert!((e1 * e2 - 1.0 / (1.0 - g0 * g0)).abs() < 1e-12 && (s - e1 * e2).abs() < 1e-9);
    }
    for h in [1.0, 0.5, 0.1] {
        let (e, s) = (q(2.0 - h, 2.0 + h, g0), q_simpson(2.0 - h, 2.0 + h, g0));
        println!("centred at 2, half-width {}: avg w={:.6} avg 1/w={:.6} product={:.6} simpson={:.6}",
                 h, avg_exact(2.0 - h, 2.0 + h, g0), avg_exact(2.0 - h, 2.0 + h, -g0), e, s);
        assert!((e - s).abs() < 1e-9 && 1.0 < e && e < 1.0 / (1.0 - g0 * g0));
    }
    println!("symmetric [-1,1]: product={:.6}", q(-1.0, 1.0, g0));
    let (u, a2) = a2_constant(g0);
    let mut brute = f64::NEG_INFINITY;
    for i in -60..61 { for j in (i + 1)..61 { brute = brute.max(q(i as f64 / 20.0, j as f64 / 20.0, g0)); } }
    println!("A2 constant: worst interval [{:.4}, 1], [w]_A2={:.6}; grid of 7260 intervals: {:.6}", u, a2, brute);
    let s0 = -(2.0 - 3f64.sqrt()).powf(2.0);  // road 3, by hand: the worst left end, product 3/2
    let r0 = (-s0).sqrt();
    println!("by hand: r = 2 - sqrt 3 = {:.6}, y = r/(1+r^2) = {:.6}, left end {:.6}, product {:.6}",
             r0, r0 / (1.0 + r0 * r0), s0, q(s0, 1.0, g0));
    assert!((u - s0).abs() < 1e-6 && (a2 - 1.5).abs() < 1e-12 && brute <= a2 + 1e-12 && a2 - brute < 2e-3);
    let us = [-1.0, -0.6, -0.3, -0.2, -0.15, -0.1, -0.07, -0.05, -0.03, -0.01, 0.0, 0.1, 0.3, 0.5, 0.7, 0.9];
    for g in [0.5, 0.75] {
        let pts: Vec<String> = us.iter().map(|&x| format!("{:.4}", q(x, 1.0, g))).collect();
        println!("chart gamma={}: {}", g, pts.join(", "));
    }
    for g in [0.0, 0.25, 0.5, 0.75, 0.9, 0.99] {
        let c = a2_constant(g).1;
        println!("table gamma={:.2}: [w]_A2={:.4}  on [0,1]: {:.4}", g, c, 1.0 / (1.0 - g * g));
        let mut fine = f64::NEG_INFINITY;  // road 2: exhaustive grid of left ends
        for k in -20000..20000 { fine = fine.max(q(k as f64 / 20000.0, 1.0, g)); }
        assert!(c >= 1.0 / (1.0 - g * g) - 1e-12 && fine <= c + 1e-12 && c - fine < 1e-4 * c);
    }
    let mg = |x: f64| if 0.0 <= x && x <= 1.0 { 1.0 } else { 1.0 / (2.0 * x.max(1.0 - x)) };  // Mg, gate on [0,1]
    for x in [-0.5, 0.3, 1.5] {         // brute force: largest centred average over 40000 half-widths
        let mut b = f64::NEG_INFINITY;
        for k in 1..40001 {
            let h = k as f64 / 10000.0;
            b = b.max(((x + h).min(1.0) - (x - h).max(0.0)) / (2.0 * h));
        }
        println!("gate: Mg({}) = {:.6}, brute force {:.6}", x, mg(x), b);
        assert!((b - mg(x)).abs() < 1e-4);
    }
    let (we, we2) = (avg_exact(-1.0, 2.0, g0) * 3.0, avg_simpson(-1.0, 2.0, g0) * 3.0);
    let wr = we / 16.0 / (2.0 / 3.0);   // w-length times alpha^2, over the weighted energy 2/3
    println!("gate: w-length where Mg > 1/4 = {:.6} (simpson {:.6}); weak ratio {:.6}", we, we2, wr);
    println!("gate: weak bound 9 [w]_A2^2 = {:.4}; ratio to bound {:.4}", 9.0 * a2 * a2, wr / (9.0 * a2 * a2));
    let pi = std::f64::consts::PI;
    let left = simpson(&|v: f64| (1.5 * v).exp() / (4.0 * (1.0 + v.exp()).powf(2.0)), -60.0, 80.0, 20000);
    let tot = 2.0 / 3.0 + 0.5 + left;   // weighted energy of Mg: on the gate, right tail, left tail
    println!("gate: left tail {:.6} (pi/8 = {:.6}); energy of Mg {:.6}; strong ratio {:.4}", left, pi / 8.0, tot,
             (tot / (2.0 / 3.0)).sqrt());
    assert!((we - we2).abs() < 1e-9 && (left - pi / 8.0).abs() < 1e-9);
    let epss: [(f64, &str); 3] = [(1e-2, "1e-2"), (1e-4, "1e-4"), (1e-8, "1e-8")];
    for (eps, lab) in epss {            // gamma = 1: the average of 1/w on [0,1] diverges
        println!("gamma=1, 1/w counted from {}: product on [0,1] = {:.6}", lab, (1.0 / eps).ln() / 2.0);
    }
    let mut r5 = 0.0;
    for (eps, lab) in epss {
        let (l, r1) = ((1.0 / eps).ln(), test_ratio(1.0, eps));
        r5 = test_ratio(0.5, eps);
        let ln2 = (2f64).ln();
        let exact = (((l.powf(3.0) - ln2.powf(3.0)) / 12.0 + l * l * ln2 / 4.0) / l).sqrt();
        println!("test eps={}: gamma=1 M-ratio>={:.4} (closed form {:.4}), gamma=0.5 M-ratio>={:.4}", lab, r1, exact, r5);
        assert!((r1 - exact).abs() < 1e-6);
    }
    let lim = (2.0 * 2f64.sqrt() - 1.0).sqrt();
    println!("gamma=0.5 limit as eps -> 0: sqrt(2 sqrt 2 - 1) = {:.4}", lim);
    assert!((r5 - lim).abs() < 1e-3);
    for t in [0.001, 0.1, 0.5] {         // road 2 for Hf: the kernel integral of 1/(y(t+y)) over [1e-4, 1], y = e^v
        let k = simpson(&|v: f64| 1.0 / (t + v.exp()), (1e-4f64).ln(), 0.0, 20000) / pi;
        let c = ((t + 1e-4) / (1e-4 * (1.0 + t))).ln() / (pi * t);
        println!("gamma=1, eps=1e-4: |Hf(-{})| by kernel {:.6}, closed form {:.6}", t, k, c);
        assert!((k - c).abs() < 1e-8);
    }
    let hr: Vec<f64> = epss.iter().map(|&(e, _)| hilbert_ratio(e)).collect();
    let hr2: Vec<f64> = epss.iter().map(|&(e, _)| hilbert_ratio2(e)).collect();
    let hs: Vec<String> = hr.iter().map(|x| format!("{:.4}", x)).collect();
    let hs2: Vec<String> = hr2.iter().map(|x| format!("{:.4}", x)).collect();
    println!("gamma=1 H-ratio on x<0: {}; second cut-off: {}", hs.join(", "), hs2.join(", "));
    assert!(hr[0] < hr[1] && hr[1] < hr[2] && hr[2] > 3.0);
    assert!(hr.iter().zip(&hr2).all(|(x, y)| (x - y).abs() < 1e-6));
    for p in [2.0, 1.75, 1.6, 1.55] {   // openness: |x|^0.5 is in A_p for every p above 1.5
        let (e1, e2) = (avg_exact(0.0, 1.0, g0), avg_exact(0.0, 1.0, -g0 / (p - 1.0)));
        println!("A_p product on [0,1], p={:.2}: {:.6}", p, e1 * e2.powf(p - 1.0));
    }
    let o = osc_log(0.0, 1.0);
    let e = std::f64::consts::E;
    println!("BMO: mean oscillation of ln|x| on [0,1] = {:.6} (2/e = {:.6}); on [1,3] = {:.6}", o, 2.0 / e, osc_log(1.0, 3.0));
    println!("log w = {} ln|x|: oscillation {:.6} <= ln([w]_A2 + 1) = {:.6}", g0, g0 * o, (a2 + 1.0).ln());
    assert!((o - 2.0 / e).abs() < 1e-6 && g0 * o <= (a2 + 1.0).ln());
    println!("ALL CHECKS PASS");
}
