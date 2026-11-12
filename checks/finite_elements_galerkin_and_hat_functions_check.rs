// Finite elements: Galerkin with hat functions -- the same check as the Python, in Rust.  No crates.
// Cable on a bed of springs: -y'' + y = 0 for 0 <= x <= 1 m, y(0) = 1 cm, y(1) = 2 cm.
// Road one: the closed form y = cosh x + s sinh x.  Road two: Galerkin with hats, n elements,
// solved by the Thomas sweep.  Road three: energy identities (Ritz minimum, best fit) and the bound.
use std::f64::consts::PI;

fn s0() -> f64 { (2.0 - 1f64.cosh()) / 1f64.sinh() }      // starting slope of the exact cable
fn y(x: f64) -> f64 { x.cosh() + s0() * x.sinh() }
fn dy(x: f64) -> f64 { x.sinh() + s0() * x.cosh() }
fn sci(x: f64, d: usize) -> String { format!("{:.*e}", d, x) }    // 8.067e-4, as in Python
fn row(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ") }
fn thomas(a: &[f64], b: &[f64], c: &[f64], r: &[f64]) -> Vec<f64> {   // sub, main, super, right side
    let (mut b, mut r) = (b.to_vec(), r.to_vec());
    for i in 1..b.len() {
        let w = a[i] / b[i - 1]; b[i] -= w * c[i - 1]; r[i] -= w * r[i - 1];
    }
    let n = b.len(); let mut u = vec![0.0; n]; u[n - 1] = r[n - 1] / b[n - 1];
    for i in (0..n - 1).rev() { u[i] = (r[i] - c[i] * u[i + 1]) / b[i] }
    u
}
// ks multiplies the y'v' part, km the y v part; lump puts all of y v on the diagonal
fn galerkin(n: usize, ks: f64, km: f64, lump: bool, ends: bool) -> (Vec<f64>, f64, f64, Vec<f64>) {
    let h = 1.0 / n as f64;
    let d = ks * 2.0 / h + km * (if lump { h } else { 4.0 * h / 6.0 });    // a(phi_i, phi_i)
    let o = -ks / h + (if lump { 0.0 } else { km * h / 6.0 });             // a(phi_i, phi_(i+1))
    let mut r = vec![0.0; n - 1];
    if ends { r[0] -= o * 1.0; r[n - 2] -= o * 2.0 }                       // the end hats carry 1 cm and 2 cm
    let mut u = vec![1.0];
    u.extend(thomas(&vec![o; n - 1], &vec![d; n - 1], &vec![o; n - 1], &r));
    u.push(2.0);
    (u, d, o, r)
}
fn gal(n: usize) -> Vec<f64> { galerkin(n, 1.0, 1.0, false, true).0 }
fn errors(u: &[f64]) -> (f64, f64) {                     // L2 error and energy error of the broken line u
    let g3 = [(-(0.6f64).sqrt(), 5.0 / 9.0), (0.0, 8.0 / 9.0), ((0.6f64).sqrt(), 5.0 / 9.0)];
    let n = u.len() - 1; let h = 1.0 / n as f64; let (mut e2, mut d2) = (0.0, 0.0);
    for k in 0..n {
        let sl = (u[k + 1] - u[k]) / h;
        for &(t, w) in &g3 {
            let x = (k as f64 + 0.5 + t / 2.0) * h;
            e2 += w * h / 2.0 * (y(x) - u[k] - sl * (x - k as f64 * h)).powi(2);
            d2 += w * h / 2.0 * (dy(x) - sl).powi(2);
        }
    }
    (e2.sqrt(), (e2 + d2).sqrt())
}
fn energy(u: &[f64]) -> f64 {                            // a(y_h, y_h), element by element
    let n = u.len() - 1; let h = 1.0 / n as f64;
    (0..n).map(|k| (u[k + 1] - u[k]).powi(2) / h + h / 3.0 * (u[k] * u[k] + u[k] * u[k + 1] + u[k + 1] * u[k + 1])).sum()
}
fn nodal(u: &[f64]) -> f64 { let n = u.len() - 1; (0..=n).map(|i| (u[i] - y(i as f64 / n as f64)).abs()).fold(0.0, f64::max) }
fn errs3(u: &[f64], ex: &[f64]) -> String { [1, 2, 3].iter().map(|&i| sci(u[i] - ex[i], 3)).collect::<Vec<_>>().join(", ") }

fn main() {
    let s = s0();
    println!("cable: -y'' + y = 0, y(0) = 1 cm, y(1) = 2 cm; exact starting slope s = {:.8}", s);
    let (u4, d, o, r) = galerkin(4, 1.0, 1.0, false, true);
    let ex: Vec<f64> = (0..5).map(|i| y(i as f64 / 4.0)).collect();
    println!("n = 4, h = 0.25: diagonal 2/h + 4h/6 = {:.6}, off-diagonal -1/h + h/6 = {:.6}", d, o);
    println!("right side from the end hats: {}", row(&r, 6));
    println!("Galerkin nodes: {}", row(&u4, 6));
    println!("exact nodes:    {}", row(&ex, 6));
    println!("nodal error, Galerkin minus exact: {}", errs3(&u4, &ex));
    let f4 = galerkin(4, 1.0, 1.0, true, true).0;
    println!("lumped springs = finite differences: {}; errors {}", row(&f4, 6), errs3(&f4, &ex));
    let (_, en) = errors(&u4);
    let ay = 2.0 * dy(1.0) - dy(0.0);                    // a(y, y) = y(1)y'(1) - y(0)y'(0)
    println!("energy: exact cable a(y,y) = {:.10}, Galerkin a(y_h,y_h) = {:.10}", ay, energy(&u4));
    println!("energy error: by quadrature {}, by sqrt(a(y_h,y_h) - a(y,y)) {}", sci(en, 6), sci((energy(&u4) - ay).sqrt(), 6));
    let i4 = ex.clone();
    println!("energy error of the broken line through the exact nodes: {} (Galerkin {})", sci(errors(&i4).1, 6), sci(en, 6));
    let t = 0.01; let mut p = u4.clone(); p[2] += t;
    println!("Ritz: nudge node 2 by 0.01 cm, energy/2 rises {}; t^2 d/2 = {}", sci((energy(&p) - energy(&u4)) / 2.0, 3), sci(t * t * d / 2.0, 3));
    let y2 = 0.5 + 2f64.sinh() / 4.0 + s * 1f64.sinh().powi(2) + s * s * (2f64.sinh() / 4.0 - 0.5);  // integral of y^2 = y''^2
    let zq = errors(&vec![0.0; 65]).0;
    println!("||y''|| = ||y|| = {:.6} (closed form), {:.6} (quadrature)", y2.sqrt(), zq);
    let ns = [4usize, 8, 16, 32, 64, 128, 256, 512, 1024];
    let mut tab: Vec<[f64; 4]> = vec![];
    println!("n, nodal max error, L2 error, energy error, energy bound, bound / energy error");
    for &n in &ns {
        let u = gal(n); let (l2n, enn) = errors(&u); let h = 1.0 / n as f64;
        let b = h / PI * (1.0 + (h / PI).powi(2)).sqrt() * y2.sqrt();
        tab.push([nodal(&u), l2n, enn, b]);
        println!("  {:4}  {}  {}  {}  {}  {:.3}", n, sci(nodal(&u), 3), sci(l2n, 3), sci(enn, 3), sci(b, 3), b / enn);
    }
    let ord = |j: usize, i: usize| (tab[i][j] / tab[i + 1][j]).log2();
    for (j, name) in ["nodal", "L2", "energy"].iter().enumerate() {
        println!("observed order, {}: {}", name, row(&(0..4).map(|i| ord(j, i)).collect::<Vec<_>>(), 2));
    }
    println!("chart x, log10 h: {}", row(&ns.iter().map(|&n| (1.0 / n as f64).log10()).collect::<Vec<_>>(), 2));
    for (j, name) in ["nodal", "L2", "energy"].iter().enumerate() {
        println!("chart, log10 error, {}: {}", name, row(&tab.iter().map(|v| v[j].log10()).collect::<Vec<_>>(), 2));
    }
    let fl: Vec<f64> = [4096usize, 16384, 65536].iter().map(|&n| nodal(&gal(n))).collect();
    println!("rounding, nodal max error at n = 4096, 16384, 65536: {}", fl.iter().map(|&e| sci(e, 1)).collect::<Vec<_>>().join(", "));
    println!("cost at n = 4: 3 unknowns, Thomas sweep 8(n-1) - 7 = {} flops; at n = 1024: {} flops", 8 * 3 - 7, 8 * 1023 - 7);
    let m1 = galerkin(4, 0.0, 1.0, false, true).0; let m2 = galerkin(4, 1.0, 0.0, false, true).0;
    let m3 = galerkin(4, -1.0, 1.0, false, true).0; let m4 = galerkin(4, 1.0, 1.0, false, false).0;
    println!("mistake 1, no integration by parts (only y v survives): {}", row(&m1[1..4], 4));
    println!("mistake 2, springs dropped: {}", row(&m2[1..4], 4));
    println!("mistake 3, sign slip, -y'v' + y v: {}", row(&m3[1..4], 4));
    println!("mistake 4, end hats left out of the right side: {}", row(&m4[1..4], 4));
    let w = 10f64.sqrt(); let bb = (2.0 - w.cos()) / w.sin();    // -y'' - 10 y = 0: springs push out
    println!("push-out springs, -y'' - 10 y = 0: middle, n = 4: {:.4}, n = 64: {:.4}, exact {:.4}",
             galerkin(4, 1.0, -10.0, false, true).0[2], galerkin(64, 1.0, -10.0, false, true).0[32], (w / 2.0).cos() + bb * (w / 2.0).sin());
    let a: Vec<f64> = [1, 2, 3].iter().map(|&i| (u4[i] + f4[i]) / 2.0 - ex[i]).collect();
    println!("try, average of Galerkin and finite differences, errors: {}", a.iter().map(|&e| sci(e, 3)).collect::<Vec<_>>().join(", "));
    println!("try, n = 8 middle node {:.6}, exact {:.6}", gal(8)[4], y(0.5));
    let px = |x: f64, v: f64| format!("({:.1}, {:.1})", 40.0 + 280.0 * x, 125.0 - 100.0 * (v - 1.0));
    println!("figure, Galerkin nodes px: {}", (0..5).map(|i| px(i as f64 / 4.0, u4[i])).collect::<Vec<_>>().join(" "));
    println!("figure, exact curve px: {}", (0..9).map(|i| px(i as f64 / 8.0, y(i as f64 / 8.0))).collect::<Vec<_>>().join(" "));
    println!("figure, hats: base y = 220.0, peaks {}", (0..5).map(|i| format!("({:.1}, 175.0)", 40.0 + 70.0 * i as f64)).collect::<Vec<_>>().join(" "));

    assert!((0..5).all(|i| (u4[i] - ex[i]).abs() < 1e-3));                 // Galerkin near the closed form
    assert!((en - (energy(&u4) - ay).sqrt()).abs() < 1e-6);                 // Gauss rule = energy identity
    assert!(en < errors(&i4).1);                                            // best fit in energy beats the interpolant
    assert!(((energy(&p) - energy(&u4)) / 2.0 - t * t * d / 2.0).abs() < 1e-12);  // Ritz: the nodes sit at the minimum
    assert!((y2.sqrt() - zq).abs() < 1e-9);                                 // closed-form norm = quadrature
    assert!(tab.iter().all(|v| v[2] < v[3]));                               // the energy bound holds
    assert!((0..4).all(|i| 1.95 < ord(0, i) && ord(0, i) < 2.05));          // nodal order 2
    assert!((0..4).all(|i| 0.98 < ord(2, i) && ord(2, i) < 1.02));          // energy order 1
    assert!((0..3).all(|k| a[k].abs() < (u4[k + 1] - ex[k + 1]).abs() / 50.0));  // the two h^2 terms cancel
    assert!(fl[2] > fl[1]);                                                 // rounding stops the fall
    println!("ALL CHECKS PASS");
}
