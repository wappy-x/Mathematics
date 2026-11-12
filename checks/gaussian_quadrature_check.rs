// Gaussian quadrature -- the check behind the card.  Rust std only, no crates.
// A 6 m simply supported beam carries a load rising from 0 to 12 kN/m; EI = 20,000 kN m^2.
// Bending energy U = integral over the span of M(x)^2 / (2 EI), with M(x) = w0 x (L^2 - x^2) / (6 L).
// Roads: exact integration term by term; Gauss nodes found by bisection on the Legendre
// polynomial with the weight formula; the closed-form 4-point rule; weights from moment equations.

const W0: f64 = 12.0; // kN/m
const EI: f64 = 20000.0; // kN m^2

fn e(x: f64) -> String { format!("{:.3e}", x) } // e-notation, printed the same way in Python
fn pw(x: f64, k: u32) -> f64 { if k == 0 { 1.0 } else { x * pw(x, k - 1) } } // x^k by plain multiplies
fn total<I: Iterator<Item = f64>>(v: I) -> f64 { v.fold(0.0, |a, b| a + b) } // left-to-right sum

fn legendre(n: usize, x: f64) -> (f64, f64) { // Bonnet's rule; returns P_n(x), P_(n-1)(x)
    let (mut p0, mut p1) = (1.0, x);
    for k in 1..n {
        let kf = k as f64;
        let p2 = ((2.0 * kf + 1.0) * x * p1 - kf * p0) / (kf + 1.0);
        p0 = p1;
        p1 = p2;
    }
    (p1, p0)
}

fn gauss(n: usize) -> (Vec<f64>, Vec<f64>) { // zeros of P_n by bisection; w = 2 / ((1 - x^2) P_n'(x)^2)
    let (mut xs, mut ws, grid) = (vec![], vec![], 2001);
    for i in 0..grid {
        let mut a = -1.0 + 2.0 * i as f64 / grid as f64;
        let mut b = -1.0 + 2.0 * (i + 1) as f64 / grid as f64;
        let mut fa = legendre(n, a).0;
        if fa * legendre(n, b).0 > 0.0 { continue; }
        loop {
            let m = 0.5 * (a + b);
            if m == a || m == b { break; }
            let fm = legendre(n, m).0;
            if fa * fm <= 0.0 { b = m; } else { a = m; fa = fm; }
        }
        let (p, q) = legendre(n, a);
        let dp = n as f64 * (a * p - q) / (a * a - 1.0);
        xs.push(a);
        ws.push(2.0 / ((1.0 - a * a) * dp * dp));
    }
    (xs, ws)
}

fn rule(f: &dyn Fn(f64) -> f64, a: f64, b: f64, xs: &[f64], ws: &[f64]) -> f64 {
    let (mid, half) = (0.5 * (a + b), 0.5 * (b - a)); // x = mid + half t, dx = half dt
    half * total(xs.iter().zip(ws).map(|(t, w)| w * f(mid + half * t)))
}

fn moment_weights(xs: &[f64]) -> Vec<f64> { // solve sum_j w_j x_j^k = integral of t^k, k = 0..n-1
    let n = xs.len();
    let mut a: Vec<Vec<f64>> = (0..n).map(|k| {
        let mut row: Vec<f64> = xs.iter().map(|&x| pw(x, k as u32)).collect();
        row.push(if k % 2 == 0 { 2.0 / (k as f64 + 1.0) } else { 0.0 });
        row
    }).collect();
    for c in 0..n {
        let mut piv = c;
        for r in c..n { if a[r][c].abs() > a[piv][c].abs() { piv = r; } }
        a.swap(c, piv);
        for r in c + 1..n {
            let f = a[r][c] / a[c][c];
            for j in 0..=n { a[r][j] = a[r][j] - f * a[c][j]; }
        }
    }
    let mut w = vec![0.0; n];
    for r in (0..n).rev() {
        w[r] = (a[r][n] - total((r + 1..n).map(|j| a[r][j] * w[j]))) / a[r][r];
    }
    w
}

fn mono(k: u32) -> f64 { if k % 2 == 0 { 2.0 / (k as f64 + 1.0) } else { 0.0 } } // integral of t^k on [-1, 1]

fn trap(f: &dyn Fn(f64) -> f64, a: f64, b: f64, m: usize) -> f64 {
    let h = (b - a) / m as f64;
    h * (0.5 * f(a) + 0.5 * f(b) + total((1..m).map(|i| f(a + i as f64 * h))))
}

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, m: usize) -> f64 {
    let h = (b - a) / m as f64;
    h / 3.0 * (f(a) + f(b) + total((1..m).map(|i| (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h))))
}

fn main() {
    let l = 6.0; // m
    let energy = move |l: f64| move |x: f64| { // J per m of span
        let m = W0 * x * (l * l - x * x) / (6.0 * l); // bending moment, kN m
        1000.0 * m * m / (2.0 * EI)
    };
    let en = energy(l);
    let c = W0 / (6.0 * l); // M^2 = c^2 (L^4 x^2 - 2 L^2 x^4 + x^6)
    let u = 1000.0 * c * c * (pw(l, 7) / 3.0 - 2.0 * pw(l, 7) / 5.0 + pw(l, 7) / 7.0) / (2.0 * EI);
    println!("L {:.0} m, w0 {:.0} kN/m, EI {:.0} kN m^2; exact U (J): term by term {:.12} | 1000 w0^2 L^5/(945 EI) {:.12}", l, W0, EI, u, 1000.0 * W0 * W0 * pw(l, 5) / (945.0 * EI));
    let (x2, w2) = gauss(2);
    println!("2-point nodes {:.12} {:.12} weights {:.12} {:.12}", x2[0], x2[1], w2[0], w2[1]);
    assert!((x2[1] - 1.0 / 3.0f64.sqrt()).abs() < 1e-15 && (w2[0] - 1.0).abs() < 1e-14);
    for k in 0..5u32 {
        println!("2-point on t^{}: rule {:.12} exact {:.12}", k, rule(&|t| pw(t, k), -1.0, 1.0, &x2, &w2), mono(k));
    }
    let (x4, w4) = gauss(4);
    let s = 2.0 * (6.0f64 / 5.0).sqrt(); // closed form: x^2 = (3 -+ 2 sqrt(6/5)) / 7, w = (18 +- sqrt 30) / 36
    let cx = [-((3.0 + s) / 7.0).sqrt(), -((3.0 - s) / 7.0).sqrt(), ((3.0 - s) / 7.0).sqrt(), ((3.0 + s) / 7.0).sqrt()];
    let r30 = 30.0f64.sqrt();
    let cw = [(18.0 - r30) / 36.0, (18.0 + r30) / 36.0, (18.0 + r30) / 36.0, (18.0 - r30) / 36.0];
    let mw = moment_weights(&x4);
    for j in 0..4 { println!("4-point t {:+.15} w {:.15} | x {:.6} m, energy {:.6} J/m", x4[j], w4[j], 3.0 + 3.0 * x4[j], en(3.0 + 3.0 * x4[j])); }
    let maxd = |p: &[f64], q: &[f64]| p.iter().zip(q).map(|(a, b)| (a - b).abs()).fold(0.0, f64::max);
    let (dx, dw, dm) = (maxd(&x4, &cx), maxd(&w4, &cw), maxd(&w4, &mw));
    println!("vs closed form: nodes {} weights {} | weights by moments {}", e(dx), e(dw), e(dm));
    assert!(dx < 1e-15 && dw < 1e-14 && dm < 1e-13);
    let mut degs = vec![];
    for n in 1..7 { // highest degree k with every t^0..t^k exact
        let (xs, ws) = gauss(n);
        let mut k = 0u32;
        while (rule(&|t| pw(t, k), -1.0, 1.0, &xs, &ws) - mono(k)).abs() < 1e-13 { k += 1; }
        degs.push(k as i32 - 1);
    }
    println!("degree of exactness, n = 1..6: {:?}", degs);
    assert!(degs == (1..7).map(|n| 2 * n - 1).collect::<Vec<i32>>());
    println!("beam, n points: U_n (J), true error");
    let mut errs = vec![];
    for n in 1..7 {
        let (xs, ws) = gauss(n);
        let un = rule(&en, 0.0, l, &xs, &ws);
        errs.push(u - un);
        println!("  n={} {:.12} {}", n, un, e(u - un));
    }
    assert!(errs[3].abs() < 4e-15 * u && errs[2].abs() > 1e-4);
    // n = 3 error from the theorem: K_3 f^(6), K_3 = 2^7 (3!)^4 / (7 (6!)^3); f^(6) = 720 x leading coefficient in t
    let k3 = 128.0 * 1296.0 / (7.0 * 720.0 * 720.0 * 720.0);
    let lead = 1000.0 * c * c * pw(l / 2.0, 7) / (2.0 * EI); // t^6 coefficient of (L/2) energy(L/2 (1 + t))
    let pred = k3 * 720.0 * lead;
    println!("n=3 error: theorem {} true {} ratio {:.6}", e(pred), e(errs[2]), errs[2] / pred);
    assert!((errs[2] / pred - 1.0).abs() < 1e-9);
    println!("4-point trapezoid {} | 5-point Simpson {}", e(u - trap(&en, 0.0, l, 3)), e(u - simpson(&en, 0.0, l, 4)));
    let m = (1..2000).map(|k| 2 * k).find(|&m| (u - simpson(&en, 0.0, l, m)).abs() <= 1e-12 * u).unwrap(); // fewest even slice count
    println!("Simpson to relative error 1e-12: {} points, error {}", m + 1, e(u - simpson(&en, 0.0, l, m)));
    assert!((u - simpson(&en, 0.0, l, 2 * m)).abs() < (u - simpson(&en, 0.0, l, m)).abs() / 8.0); // h^4: twice the slices, near 16 times less error
    println!("chart, log10 relative error by points used, n = 2..8: Gauss | trapezoid");
    let g: Vec<String> = (2..9).map(|n| { let (xs, ws) = gauss(n); format!("{:.2}", ((u - rule(&en, 0.0, l, &xs, &ws)).abs() / u).log10()) }).collect();
    let t: Vec<String> = (2..9).map(|n| format!("{:.2}", ((u - trap(&en, 0.0, l, n - 1)).abs() / u).log10())).collect();
    println!("   {}", g.join(" "));
    println!("   {}", t.join(" "));
    println!("break: no half-width factor {:.6}", total(x4.iter().zip(&w4).map(|(t, w)| w * en(3.0 + 3.0 * t))));
    let eq = [-1.0, -1.0 / 3.0, 1.0 / 3.0, 1.0]; // four equally spaced points, Simpson's 3/8 weights
    println!("break: 4 equal points, 3/8 rule {}", e(u - rule(&en, 0.0, l, &eq, &[0.25, 0.75, 0.75, 0.25])));
    let mut prev = 0.0;
    for n in [2, 4, 8, 16, 32] { // sqrt(x) on [0, 1]: infinite slope at 0
        let (xs, ws) = gauss(n);
        let err = (2.0 / 3.0 - rule(&|x: f64| x.sqrt(), 0.0, 1.0, &xs, &ws)).abs();
        let ord = if prev > 0.0 { format!(" order {:.2}, theory 3", (prev / err).log10() / 2.0f64.log10()) } else { String::new() };
        println!("break: sqrt(x), n={} error {}{}", n, e(err), ord);
        prev = err;
    }
    assert!(prev > 1e-6); // the crawl: still wrong in the sixth digit at 32 points
    let (x3, w3) = gauss(3);
    let uu = 1000.0 * W0 * W0 * pw(l, 5) / (240.0 * EI); // try: uniform 12 kN/m, M = w0 x (L - x) / 2, M^2 of degree 4
    let uni = |x: f64| 1000.0 * pw(W0 * x * (l - x) / 2.0, 2) / (2.0 * EI);
    println!("try: uniform load U {:.6}, error n=2 {} n=3 {}", uu, e(uu - rule(&uni, 0.0, l, &x2, &w2)), e(uu - rule(&uni, 0.0, l, &x3, &w3)));
    println!("try: sqrt(x) as 2 s^2 on s in [0, 1], n=2 error {}", e(2.0 / 3.0 - rule(&|s: f64| 2.0 * s * s, 0.0, 1.0, &x2, &w2)));
    let en12 = energy(12.0); // try: double the span
    println!("try: span 12 m, U {:.6}, n=4 error {}", 32.0 * u, e(32.0 * u - rule(&en12, 0.0, 12.0, &x4, &w4)));
    println!("ALL CHECKS PASS");
}
