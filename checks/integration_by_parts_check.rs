// Integration by parts -- the same check as the Python, in Rust.  std only;
// exp and ln are the only primitives used.
// Road one: the parts formula, and its reduction J_n = e - n * J_(n-1).
// Road two: a Simpson sum of the original integrand, refined until it closes.

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64; // n even; weights 1, 4, 2, 4, ..., 4, 1
    let mut inner = 0.0;
    for k in 1..n {
        inner += (if k % 2 == 1 { 4.0 } else { 2.0 }) * f(a + k as f64 * h);
    }
    (f(a) + f(b) + inner) * h / 3.0
}

fn main() {
    let e = 1.0_f64.exp();
    let xex = |x: f64| x * x.exp();
    let (bx, lx) = (1.0 * e - 0.0 * 1.0, e - 1.0); // [x e^x] from 0 to 1; integral of e^x
    let (bl, ll) = (e * 1.0 - 1.0 * 0.0, e - 1.0); // [x ln x] from 1 to e; integral of 1
    println!("x e^x on 0..1: boundary {:.6} - leftover {:.6} = {:.6}", bx, lx, bx - lx);
    println!("ln x on 1..e:  boundary {:.6} - leftover {:.6} = {:.6}", bl, ll, bl - ll);
    for n in [4usize, 8, 16, 32] {
        let s = simpson(&xex, 0.0, 1.0, n);
        println!("Simpson x e^x, {:2} strips: {:.12}, error {:.12}", n, s, s - (bx - lx));
    }
    let (mut j, mut rows) = (e - 1.0, Vec::new()); // J_0 = e - 1, then the reduction
    for n in 0..5i32 {
        if n > 0 {
            j = e - n as f64 * j;
        }
        let se = simpson(&|x: f64| x.powi(n) * x.exp(), 0.0, 1.0, 128);
        let sl = simpson(&|x: f64| x.ln().powi(n), 1.0, e, 128);
        rows.push((j, se, sl));
        println!("J_{}: reduction {:.6}, Simpson x^{} e^x {:.6}, Simpson (ln x)^{} {:.6}", n, j, n, se, n, sl);
    }
    let h = 1e-5; // the antiderivatives, differentiated back
    let big_f = |x: f64| x.exp() * (x - 1.0);
    let big_g = |x: f64| x * x.ln() - x;
    let d_f = (big_f(0.5 + h) - big_f(0.5 - h)) / (2.0 * h);
    let d_g = (big_g(2.0 + h) - big_g(2.0 - h)) / (2.0 * h);
    println!("rates: e^x (x - 1) at 0.5 is {:.6}, x e^x {:.6}; x ln x - x at 2 is {:.6}, ln 2 {:.6}", d_f, xex(0.5), d_g, 2.0_f64.ln());
    let pts: Vec<String> = [0.0, 0.25, 0.5, 0.75, 1.0_f64].iter()
        .map(|u: &f64| format!("({:.1}, {:.1})", 60.0 + 200.0 * u, 215.0 - 70.0 * u.exp())).collect();
    println!("figure, curve v = e^u in px (1 across = 200 px, 1 up = 70 px): {}", pts.join(" "));
    println!("mistake, plus sign instead of minus: {:.6}, not 1", bx + lx);
    println!("mistake, boundary term alone: {:.6}, not 1", bx);
    let step = |x: f64| if x >= 1.0 { 1.0 } else { 0.0 }; // v jumps from 0 to 1 at x = 1
    let vdash = |x: f64| (step(x + 1e-6) - step(x - 1e-6)) / 2e-6;
    let left = simpson(&|x: f64| x * vdash(x), 0.0, 3.0, 1000); // no node lies within 1e-6 of 1
    let right = (3.0 * step(3.0) - 0.0 * step(0.0)) - simpson(&step, 1.0, 3.0, 1000); // v is 0 before 1
    println!("mistake, v with a jump at 1 on 0..3: left side {:.6}, right side {:.6}", left, right);
    let mut j20 = e - 1.0;
    for n in 1..21 {
        j20 = e - n as f64 * j20;
    }
    let s20 = simpson(&|x: f64| x.powi(20) * x.exp(), 0.0, 1.0, 256);
    println!("mistake, reduction run to J_20 in floating point: {:.6}; Simpson {:.6}", j20, s20);
    assert!(((bx - lx) - simpson(&xex, 0.0, 1.0, 128)).abs() < 1e-8); // road one against road two
    assert!(((bl - ll) - simpson(&|x: f64| x.ln(), 1.0, e, 128)).abs() < 1e-8);
    assert!(rows.iter().all(|&(j, se, sl)| (j - se).abs() < 1e-8 && (j - sl).abs() < 1e-8));
    assert!(((right - left) - 1.0).abs() < 1e-6 && (j20 - s20).abs() > 1.0); // the breaks are real
    println!("ALL CHECKS PASS");
}
