// Area and coarea formulas -- the check behind the card.  std only.
// Every area is reached by roads that do not share a formula: the Jacobian
// integrated by Simpson's rule, a closed form, and a mesh of flat triangles
// whose areas come from cross products, with no Jacobian anywhere.
use std::f64::consts::PI;
type V3 = [f64; 3];

fn dot(a: &V3, b: &V3) -> f64 { let mut s = 0.0; for i in 0..3 { s += a[i] * b[i]; } s }

// Jf = sqrt(det(Df^T Df)) for two columns
fn gram_jf(a: &V3, b: &V3) -> f64 { let (aa, bb, ab) = (dot(a, a), dot(b, b), dot(a, b)); (aa * bb - ab * ab).sqrt() }

// sum of squared 2x2 minors (Cauchy-Binet)
fn minors_sq(a: &V3, b: &V3) -> f64 {
    let mut s = 0.0;
    for i in 0..3 { for j in (i + 1)..3 { let m = a[i] * b[j] - a[j] * b[i]; s += m * m; } }
    s
}

fn det3(m: &[[f64; 3]; 3]) -> f64 {
    m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0])
        + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0])
}

fn simpson<F: Fn(f64) -> f64>(g: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut acc = 0.0;
    for k in 1..n { acc += (if k % 2 == 1 { 4.0 } else { 2.0 }) * g(a + k as f64 * h); }
    (g(a) + g(b) + acc) * h / 3.0
}

// area of a flat triangle in space
fn tri(p: &V3, q: &V3, r: &V3) -> f64 {
    let u = [q[0] - p[0], q[1] - p[1], q[2] - p[2]];
    let v = [r[0] - p[0], r[1] - p[1], r[2] - p[2]];
    let c = [u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0]];
    0.5 * (c[0] * c[0] + c[1] * c[1] + c[2] * c[2]).sqrt()
}

// triangle-mesh area of f over a rectangle of parameters
fn mesh<F: Fn(f64, f64) -> V3>(f: F, a0: f64, a1: f64, b0: f64, b1: f64, na: usize, nb: usize) -> f64 {
    let pts: Vec<Vec<V3>> = (0..=na).map(|i| (0..=nb).map(|j|
        f(a0 + (a1 - a0) * i as f64 / na as f64, b0 + (b1 - b0) * j as f64 / nb as f64)).collect()).collect();
    let mut s = 0.0;
    for i in 0..na { for j in 0..nb {
        s += tri(&pts[i][j], &pts[i + 1][j], &pts[i + 1][j + 1]) + tri(&pts[i][j], &pts[i + 1][j + 1], &pts[i][j + 1]);
    } }
    s
}

fn show(label: &str, x: f64) { println!("{:<48}{:>12.6}", label, x); }

// z = c(x^2 + y^2) over the unit disc
fn dish(r: f64, t: f64, c: f64) -> V3 { [r * t.cos(), r * t.sin(), c * r * r] }
fn dish_cols(x: f64, y: f64, c: f64) -> (V3, V3) { ([1.0, 0.0, 2.0 * c * x], [0.0, 1.0, 2.0 * c * y]) }
fn dish_area(c: f64) -> f64 {
    2.0 * PI * simpson(|r| { let (a, b) = dish_cols(r, 0.0, c); gram_jf(&a, &b) * r }, 0.0, 1.0, 2000)
}

// length of {p x + q y = t} inside the unit square
fn seg_len(p: f64, q: f64, t: f64) -> f64 {
    let (lo, hi) = (f64::max(0.0, (t - q) / p), f64::min(1.0, t / p));
    f64::max(0.0, hi - lo) * (1.0 + (p / q) * (p / q)).sqrt()
}
// breaks at q and p, so Simpson is exact piece by piece
fn coarea_linear(p: f64, q: f64) -> f64 {
    let mut s = 0.0;
    for (u, v) in [(0.0, p), (p, q), (q, p + q)] { s += simpson(|t| seg_len(p, q, t), u, v, 20); }
    s
}

fn poly(t: f64) -> f64 {
    let k = 1000; let mut s = 0.0;
    for i in 0..k {
        let (a0, a1) = (2.0 * PI * i as f64 / k as f64, 2.0 * PI * (i + 1) as f64 / k as f64);
        let (dx, dy) = (t * a1.cos() - t * a0.cos(), t * a1.sin() - t * a0.sin());
        s += (dx * dx + dy * dy).sqrt();
    }
    s
}

fn main() {
    let (a, b) = dish_cols(0.3, 0.4, 1.0);
    let gm = [dot(&a, &a), dot(&a, &b), dot(&b, &a), dot(&b, &b)];
    println!("Df^T Df at (0.3, 0.4){}{}", " ".repeat(21), gm.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(" "));
    let mn: Vec<String> = [(0, 1), (0, 2), (1, 2)].iter().map(|&(i, j)| format!("{:.2}", a[i] * b[j] - a[j] * b[i])).collect();
    println!("2x2 minors of Df at (0.3, 0.4){}{}", " ".repeat(16), mn.join(" "));
    let g = gram_jf(&a, &b);
    show("Jf at (0.3, 0.4): det(Df^T Df)", g * g);
    show("Jf at (0.3, 0.4): sum of squared minors", minors_sq(&a, &b));
    show("Jf at (0.3, 0.4)", g);
    assert!((g - (1.0f64 + 4.0 * 0.25).sqrt()).abs() < 1e-12 && (g * g - minors_sq(&a, &b)).abs() < 1e-12);
    let mut m = [[0.0; 3]; 3];
    for i in 0..3 { for j in 0..3 { m[i][j] = a[i] * a[j] + b[i] * b[j]; } }
    let big = det3(&m).abs(); // the wrong 3 by 3
    let closed = PI / 6.0 * (5.0 * 5.0f64.sqrt() - 1.0);
    let (by_jf, by_mesh) = (dish_area(1.0), mesh(|r, t| dish(r, t, 1.0), 0.0, 1.0, 0.0, 2.0 * PI, 200, 400));
    show("5 sqrt5 - 1", 5.0 * 5.0f64.sqrt() - 1.0);
    show("pi/6", PI / 6.0);
    show("dish area, closed form (pi/6)(5 sqrt5 - 1)", closed);
    show("dish area, Simpson on Jf in polar", by_jf);
    show("dish area, mesh of 160000 flat triangles", by_mesh);
    show("dish area / flat disc", by_jf / PI);
    assert!((by_jf - closed).abs() < 1e-9 && (by_mesh - closed).abs() < 2e-3);

    let sph = |p: f64, t: f64| [p.sin() * t.cos(), p.sin() * t.sin(), p.cos()];
    let sph_jf = |p: f64| gram_jf(&[p.cos(), 0.0, -p.sin()], &[0.0, p.sin(), 0.0]); // columns at angle t = 0
    let (s_jf, s_mesh) = (2.0 * PI * simpson(sph_jf, 0.0, PI, 2000), mesh(sph, 0.0, PI, 0.0, 2.0 * PI, 200, 400));
    show("sphere area, 4 pi", 4.0 * PI);
    show("sphere area, Simpson on Jf = sin(phi)", s_jf);
    show("sphere area, mesh of 160000 flat triangles", s_mesh);
    assert!((s_jf - 4.0 * PI).abs() < 1e-9 && (s_mesh - 4.0 * PI).abs() < 2e-3);

    let cone = |r: f64, t: f64| [r * t.cos(), r * t.sin(), r]; // z = |x|: Lipschitz, no slope at 0
    let c_jf = 2.0 * PI * simpson(|r| gram_jf(&[1.0, 0.0, 1.0], &[0.0, 1.0, 0.0]) * r, 0.0, 1.0, 2000);
    let c_mesh = mesh(cone, 0.0, 1.0, 0.0, 2.0 * PI, 200, 400);
    show("cone area, sqrt2 pi", 2.0f64.sqrt() * PI);
    show("cone area, Simpson on Jf = sqrt2", c_jf);
    show("cone area, mesh of 160000 flat triangles", c_mesh);
    assert!((c_jf - 2.0f64.sqrt() * PI).abs() < 1e-9 && (c_mesh - 2.0f64.sqrt() * PI).abs() < 2e-3);

    show("linear u = 3x + 4y: |grad u| x area", (3.0f64 * 3.0 + 4.0 * 4.0).sqrt() * 1.0);
    show("linear u = 3x + 4y: integral of level lengths", coarea_linear(3.0, 4.0));
    show("linear u = 5x + 12y: integral of level lengths", coarea_linear(5.0, 12.0));
    assert!((coarea_linear(3.0, 4.0) - 5.0).abs() < 1e-12 && (coarea_linear(5.0, 12.0) - 13.0).abs() < 1e-12);

    let n = 1000; let h = 2.0 / n as f64; let mut cnt = 0u64; let mut gsum = 0.0;
    for i in 0..n { for j in 0..n {
        let (x, y) = (-1.0 + (i as f64 + 0.5) * h, -1.0 + (j as f64 + 0.5) * h);
        if x * x + y * y < 1.0 { cnt += 1; gsum += 2.0 * (x * x + y * y).sqrt(); }
    } }
    let area = cnt as f64 * h * h;
    show("u = |x|: integral of |grad u| = 1, grid count", area);
    show("u = |x|: integral of circle lengths 2 pi t", simpson(|t| 2.0 * PI * t, 0.0, 1.0, 2000));
    let pp = simpson(poly, 0.0, 1.0, 40);
    show("u = |x|: integral of 1000-gon perimeters", pp);
    assert!((area - PI).abs() < 1e-3 && (pp - PI).abs() < 1e-4);
    let lhs = 2.0 * PI * simpson(|r| 2.0 * r * r, 0.0, 1.0, 2000);
    let rhs = simpson(|t| 2.0 * PI * t.sqrt(), 0.0, 1.0, 200000);
    show("u = x^2 + y^2: integral of |grad u| = 2r, polar", lhs);
    show("u = x^2 + y^2: integral of |grad u|, grid", gsum * h * h);
    show("u = x^2 + y^2: integral of contour lengths", rhs);
    let mm = 200; let mut cmap = 0.0;
    for k in 0..mm { let t = (k as f64 + 0.5) / mm as f64; cmap += poly(t.sqrt()) / (2.0 * t.sqrt()); }
    cmap /= mm as f64;
    show("contour map: integral of length / |grad u|", cmap);
    assert!((cmap - PI).abs() < 1e-4 && (lhs - 4.0 * PI / 3.0).abs() < 1e-9 && (rhs - lhs).abs() < 1e-5
        && (gsum * h * h - lhs).abs() < 1e-3);

    let c1: Vec<String> = (0..11).map(|k| format!("{:.2}", 2.0 * PI * k as f64 / 10.0)).collect();
    let c2: Vec<String> = (0..11).map(|k| format!("{:.2}", 2.0 * PI * (k as f64 / 10.0).sqrt())).collect();
    println!("chart, lengths of {{|x| = t}}   {}", c1.join(" "));
    println!("chart, lengths of {{r^2 = t}}   {}", c2.join(" "));
    let w1 = 2.0 * PI * simpson(|r| (1.0 + 2.0 * r) * r, 0.0, 1.0, 2000);
    let wrong = [("break, no Jacobian (shadow area)", PI), ("break, Jf = 1 + |grad h|", w1),
        ("break, det(Df Df^T), 3 by 3, at (0.3, 0.4)", big), ("break, unnormalised H^2 (x 4/pi)", closed * 4.0 / PI),
        ("break, angle run twice round", 2.0 * dish_area(1.0)), ("break, contour lengths added, no |grad u|", rhs)];
    show("4/pi, the Hausdorff card's area constant", 4.0 / PI);
    for (label, v) in wrong.iter() { show(label, *v); }
    assert!(big < 1e-12 && (w1 - 7.0 * PI / 3.0).abs() < 1e-9);
    show("try, dish z = 2(x^2 + y^2), Simpson on Jf", dish_area(2.0));
    show("try, dish z = 2(x^2 + y^2), closed form", PI / 24.0 * (17.0 * 17.0f64.sqrt() - 1.0));
    show("try, dish mesh starved to 10 x 20", mesh(|r, t| dish(r, t, 1.0), 0.0, 1.0, 0.0, 2.0 * PI, 10, 20));
    println!("ALL CHECKS PASS");
}
