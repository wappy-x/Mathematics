// Singular value decomposition -- the same check as the Python, in Rust.  No crates.  The
// sprite transform A = [[3, 0], [4, 5]] turns the unit circle into an ellipse.  Road one:
// the stretch factors from the eigenvalues of G = A^T A; road two: measure every direction.
type Mat = [[f64; 2]; 2];
fn dot(u: [f64; 2], v: [f64; 2]) -> f64 { u[0] * v[0] + u[1] * v[1] }
fn mv(a: Mat, v: [f64; 2]) -> [f64; 2] { [dot(a[0], v), dot(a[1], v)] }
fn tp(a: Mat) -> Mat { [[a[0][0], a[1][0]], [a[0][1], a[1][1]]] }
fn mm(a: Mat, b: Mat) -> Mat { let t = tp(b); a.map(|r| [dot(r, t[0]), dot(r, t[1])]) }
fn det(a: Mat) -> f64 { a[0][0] * a[1][1] - a[0][1] * a[1][0] }
fn unit(w: [f64; 2]) -> [f64; 2] { let n = dot(w, w).sqrt(); [w[0] / n, w[1] / n] }
fn drift(a: Mat, b: Mat) -> f64 {                    // largest entry-by-entry gap
    let d = |i: usize, j: usize| (a[i][j] - b[i][j]).abs();
    d(0, 0).max(d(0, 1)).max(d(1, 0)).max(d(1, 1))
}
fn f6(v: [f64; 2]) -> String {                       // two numbers, six decimals, no minus zero
    let v = v.map(|x| if x.abs() < 5e-7 { 0.0 } else { x }); format!("({:.6}, {:.6})", v[0], v[1])
}
fn eig2(a: Mat) -> [f64; 2] {                        // both roots of the characteristic quadratic
    let mid = (a[0][0] + a[1][1]) / 2.0; let gap = (mid * mid - det(a)).sqrt();
    [mid + gap, mid - gap]
}
fn svd(a: Mat) -> (Mat, [f64; 2], [f64; 2], Mat, Mat) {   // road one: eigen-pairs of G = A^T A
    let g = mm(tp(a), a); let lam = eig2(g); let sig = lam.map(f64::sqrt);
    let vs = lam.map(|l| unit([g[0][1], l - g[0][0]]));   // solves (G - L I)v = 0 by hand
    let u1 = mv(a, vs[0]).map(|x| x / sig[0]);
    let u2 = if sig[1] > 1e-12 { mv(a, vs[1]).map(|x| x / sig[1]) }
             else { [-u1[1], u1[0]] };                    // a flattened axis: complete the pair
    (g, lam, sig, vs, [u1, u2])
}
fn sweep(a: Mat, n: i64) -> (f64, f64, [f64; 2], i64) {   // road two: stretch in every direction
    let (mut hi, mut lo, mut hdir, mut seen) = (-1.0f64, 1e18f64, [0.0, 0.0], 0i64);
    for k in 0..=n {
        let t = k as f64 / n as f64; let den = 1.0 + t * t;   // (1 - t*t, 2t)/den has length 1
        for s in [1.0f64, -1.0f64] {         // a half turn is enough: -v stretches like v
            let v = [(1.0 - t * t) / den, s * 2.0 * t / den];
            let w = mv(a, v); let l = dot(w, w); seen += 1;
            if l > hi { hi = l; hdir = v; }
            if l < lo { lo = l; }
        }
    }
    (hi.sqrt(), lo.sqrt(), hdir, seen)
}
fn main() {
    let a: Mat = [[3.0, 0.0], [4.0, 5.0]]; let b: Mat = [[1.0, 2.0], [2.0, 4.0]];
    let eye: Mat = [[1.0, 0.0], [0.0, 1.0]];
    let (g, lam, sig, vs, us) = svd(a);
    let (u, v, s) = (tp(us), tp(vs), [[sig[0], 0.0], [0.0, sig[1]]]);
    let rebuilt = mm(mm(u, s), tp(v)); let (hi, lo, hdir, seen) = sweep(a, 50000);
    let squares: f64 = a.iter().flatten().map(|x| x * x).sum();
    let cols = tp(a).map(|c| dot(c, c).sqrt()); let rank = sig.iter().filter(|&&x| x > 1e-12).count();
    let (_gb, _lamb, sigb, vsb, _usb) = svd(b); let rankb = sigb.iter().filter(|&&x| x > 1e-12).count();
    println!("sprite A rows: {}; {}; det A {:.6}", f6(a[0]), f6(a[1]), det(a));
    println!("G = A^T A rows: {}; {}", f6(g[0]), f6(g[1]));
    println!("eigenvalues of G: {}; singular values, their square roots: {}", f6(lam), f6(sig));
    println!("input axes v1, v2: {}; {}", f6(vs[0]), f6(vs[1]));
    println!("images A v1, A v2: {}; {}", f6(mv(a, vs[0])), f6(mv(a, vs[1])));
    println!("output axes u1, u2: {}; {}", f6(us[0]), f6(us[1]));
    println!("road two, longest and shortest stretch over {} directions: {}, longest along \
              ({:.4}, {:.4})", seen, f6([hi, lo]), hdir[0], hdir[1]);
    println!("U S V^T rows: {}; {}; largest drift from perpendicular unit axes, U then V: \
              {:.6}, {:.6}", f6(rebuilt[0]), f6(rebuilt[1]),
             drift(mm(tp(u), u), eye), drift(mm(tp(v), v), eye));
    println!("product of singular values {:.6}; absolute determinant {:.6}",
             sig[0] * sig[1], det(a).abs());
    println!("eigenvalues added {:.6}; squares of A's entries added {:.6}",
             lam[0] + lam[1], squares);
    println!("nonzero singular values, the rank: {}", rank);
    println!("A's own eigenvalues, not the stretches: {}; A's column lengths: {}",
             f6(eig2(a)), f6(cols));
    println!("eigenvalues left unrooted, product {:.6}, not the area factor {:.6}",
             lam[0] * lam[1], sig[0] * sig[1]);
    println!("flat matrix B rows: {}; {}; det B {:.6}; singular values {}; rank {}",
             f6(b[0]), f6(b[1]), det(b), f6(sigb), rankb);
    println!("B kills its second input axis {}: image {}", f6(vsb[1]), f6(mv(b, vsb[1])));
    assert!((hi - sig[0]).abs() < 1e-6 && (lo - sig[1]).abs() < 1e-6);   // two roads, same stretches
    assert!((sig[0] * sig[1] - det(a).abs()).abs() < 1e-12 && (lam[0] + lam[1] - squares).abs() < 1e-12);
    assert!(drift(rebuilt, a) < 1e-12 && drift(mm(tp(u), u), eye) < 1e-12 && drift(mm(tp(v), v), eye) < 1e-12);
    assert!((sigb[0] - 5.0).abs() < 1e-12 && dot(mv(b, vsb[1]), mv(b, vsb[1])) < 1e-24 && (rank, rankb) == (2, 1));
    println!("ALL CHECKS PASS");
}
