// Spinors and the Dirac operator -- the same check as the Python, in Rust.  No crates.
// Complex numbers and 2x2 matrices are written out.  Ranks are exact, in fractions of i128.
// The eigenvalues of the 22 x 22 form come from a Jacobi sweep written out here.
use std::f64::consts::PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
impl std::ops::Add for C { type Output = C; fn add(self, o: C) -> C { c(self.re + o.re, self.im + o.im) } }
impl std::ops::Sub for C { type Output = C; fn sub(self, o: C) -> C { c(self.re - o.re, self.im - o.im) } }
impl std::ops::Mul for C { type Output = C; fn mul(self, o: C) -> C { c(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) } }
impl std::ops::Div for C { type Output = C; fn div(self, o: C) -> C { let d = o.re * o.re + o.im * o.im; c((self.re * o.re + self.im * o.im) / d, (self.im * o.re - self.re * o.im) / d) } }
fn csqrt(z: C) -> C { let r = (z.re * z.re + z.im * z.im).sqrt().sqrt(); let t = z.im.atan2(z.re) / 2.0; c(r * t.cos(), r * t.sin()) }
type M = [[C; 2]; 2];
fn mul(a: &M, b: &M) -> M { let mut o = [[c(0.0, 0.0); 2]; 2]; for i in 0..2 { for j in 0..2 { for k in 0..2 { o[i][j] = o[i][j] + a[i][k] * b[k][j] } } } o }
fn lin(terms: &[(C, M)]) -> M { let mut o = [[c(0.0, 0.0); 2]; 2]; for (k, m) in terms { for i in 0..2 { for j in 0..2 { o[i][j] = o[i][j] + *k * m[i][j] } } } o }
fn size(a: &M) -> f64 { let mut s: f64 = 0.0; for i in 0..2 { for j in 0..2 { s = s.max((a[i][j].re * a[i][j].re + a[i][j].im * a[i][j].im).sqrt()) } } s }
fn eig2(a: &M) -> [f64; 2] {   // roots of the characteristic polynomial
    let (tr, det) = (a[0][0] + a[1][1], a[0][0] * a[1][1] - a[0][1] * a[1][0]);
    let r = csqrt(tr * tr - c(4.0, 0.0) * det);
    let (x, y) = (((tr - r) / c(2.0, 0.0)).re, ((tr + r) / c(2.0, 0.0)).re);
    if x <= y { [x, y] } else { [y, x] }
}
fn r(x: f64) -> C { c(x, 0.0) }
const O: C = C { re: 0.0, im: 0.0 };
const fn k(re: f64, im: f64) -> C { C { re, im } }
const I: M = [[k(1.0, 0.0), O], [O, k(1.0, 0.0)]];
const S1: M = [[O, k(1.0, 0.0)], [k(1.0, 0.0), O]];
const S2: M = [[O, k(0.0, -1.0)], [k(0.0, 1.0), O]];
const S3: M = [[k(1.0, 0.0), O], [O, k(-1.0, 0.0)]];
fn spin(t: f64) -> M { lin(&[(r((t / 2.0).cos()), I), (r(-(t / 2.0).sin()), mul(&S1, &S2))]) }   // inverse is spin(-t)
fn mode(m: f64, n: f64) -> M { lin(&[(r(m), S1), (r(n), S2)]) }   // D acting on e^{i(mx+ny)} times a spinor
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn grid_eig(m: f64, n: f64, nn: f64) -> f64 {   // D by central differences on a periodic N x N grid
    let h = 2.0 * PI / nn;   // the wave e^{i(mx+ny)} repeats on the grid, and each stencil returns it times a number,
    let w = |u: f64, v: f64| c((m * u + n * v).cos(), (m * u + n * v).sin());   // read off at the origin, where w = 1
    let (dx, dy) = ((w(h, 0.0) - w(-h, 0.0)) / r(2.0 * h), (w(0.0, h) - w(0.0, -h)) / r(2.0 * h));
    eig2(&lin(&[(c(0.0, -1.0) * dx, S1), (c(0.0, -1.0) * dy, S2)]))[1]   // so D acts on it as this 2x2 matrix
}
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn rank(rows: &Vec<Vec<i64>>) -> usize {   // exact Gaussian elimination, fractions (num, den)
    let mut a: Vec<Vec<(i128, i128)>> = rows.iter().map(|row| row.iter().map(|&v| (v as i128, 1)).collect()).collect();
    let mut rk = 0;
    for col in 0..a[0].len() {
        let p = match (rk..a.len()).find(|&i| a[i][col].0 != 0) { Some(p) => p, None => continue };
        a.swap(rk, p);
        for i in 0..a.len() {
            if i != rk && a[i][col].0 != 0 {
                let (f0, f1) = (a[i][col].0 * a[rk][col].1, a[i][col].1 * a[rk][col].0);
                for j in 0..a[0].len() {
                    let (x, y) = (a[i][j], a[rk][j]);
                    let (num, den) = (x.0 * y.1 * f1 - f0 * y.0 * x.1, x.1 * y.1 * f1);
                    let g = gcd(num, den).max(1) * if den < 0 { -1 } else { 1 };
                    a[i][j] = (num / g, den / g);
                }
            }
        }
        rk += 1;
    }
    rk
}
fn surface(faces: &Vec<[usize; 3]>) -> (usize, usize, usize, [usize; 3], usize, usize) {
    let mut edges: Vec<(usize, usize)> = Vec::new();
    for f in faces { for (a, b) in [(0, 1), (0, 2), (1, 2)] { let e = (f[a].min(f[b]), f[a].max(f[b])); if !edges.contains(&e) { edges.push(e) } } }
    edges.sort();
    let mut verts: Vec<usize> = edges.iter().flat_map(|e| [e.0, e.1]).collect(); verts.sort(); verts.dedup();
    let d0: Vec<Vec<i64>> = edges.iter().map(|e| verts.iter().map(|&v| (v == e.1) as i64 - (v == e.0) as i64).collect()).collect();
    let d1: Vec<Vec<i64>> = faces.iter().map(|f| edges.iter().map(|&e| (e == (f[1], f[2])) as i64 - (e == (f[0], f[2])) as i64 + (e == (f[0], f[1])) as i64).collect()).collect();
    for f in 0..faces.len() { for v in 0..verts.len() { assert!((0..edges.len()).map(|e| d1[f][e] * d0[e][v]).sum::<i64>() == 0) } }   // boundary of a boundary is zero
    let (r0, r1) = (rank(&d0), rank(&d1));
    let betti = [verts.len() - r0, edges.len() - r0 - r1, faces.len() - r1];
    let a: Vec<Vec<i64>> = (0..edges.len()).map(|i| { let mut row = d0[i].clone(); row.extend((0..faces.len()).map(|j| d1[j][i])); row }).collect();
    let at: Vec<Vec<i64>> = (0..a[0].len()).map(|j| (0..a.len()).map(|i| a[i][j]).collect()).collect();
    (verts.len(), edges.len(), faces.len(), betti, at.len() - rank(&a), a.len() - rank(&at))
}
fn sorted3(mut f: [usize; 3]) -> [usize; 3] { f.sort(); f }
fn gauss_bonnet(a: f64, cc: f64, n: usize) -> f64 {   // total curvature of a spheroid / 2 pi
    (0..n).map(|k| { let p = (k as f64 + 0.5) * PI / n as f64;
        let kk = 1.0 / (a.powi(4) * cc * cc * (p.sin().powi(2) / (a * a) + p.cos().powi(2) / (cc * cc)).powi(2));
        kk * a * p.sin() * (cc * cc * p.sin().powi(2) + a * a * p.cos().powi(2)).sqrt() * PI / n as f64 }).fold(0.0, |s, x| s + x)
}
fn jacobi(mut a: Vec<Vec<f64>>) -> Vec<f64> {   // eigenvalues of a symmetric matrix
    let n = a.len(); for _ in 0..60 { for p in 0..n { for q in p + 1..n {
        if a[p][q].abs() < 1e-15 { continue }
        let th = 0.5 * (2.0 * a[p][q]).atan2(a[q][q] - a[p][p]);
        let (cs, sn) = (th.cos(), th.sin());
        for k in 0..n { let (x, y) = (a[k][p], a[k][q]); a[k][p] = cs * x - sn * y; a[k][q] = sn * x + cs * y }
        for k in 0..n { let (x, y) = (a[p][k], a[q][k]); a[p][k] = cs * x - sn * y; a[q][k] = sn * x + cs * y }
    } } }
    (0..n).map(|i| a[i][i]).collect()
}
fn main() {
    let s12 = mul(&S1, &S2);
    let rules = [size(&lin(&[(r(1.0), mul(&S1, &S1)), (r(-1.0), I)])), size(&lin(&[(r(1.0), mul(&S2, &S2)), (r(-1.0), I)])), size(&lin(&[(r(1.0), s12), (r(1.0), mul(&S2, &S1))]))];
    let worst = rules.iter().cloned().fold(0.0, f64::max);
    println!("Clifford rules: s1 s1 = 1, s2 s2 = 1, s1 s2 + s2 s1 = 0: {}", yn(worst < 1e-12));
    assert!(worst < 1e-12 && size(&lin(&[(r(1.0), s12), (c(0.0, -1.0), S3)])) < 1e-12 && size(&lin(&[(r(1.0), mul(&mul(&S3, &S2), &mul(&S1, &S3))), (r(-1.0), mul(&S2, &S1))])) < 1e-12);   // s1 s2 = i s3; (e3e2)(e1e3) = e2e1
    let t = PI / 2.0;   // a quarter turn in the s1 s2 plane
    let turned = mul(&mul(&spin(t), &S1), &spin(-t));
    let err = size(&lin(&[(r(1.0), turned), (r(-t.cos()), S1), (r(-t.sin()), S2)]));
    println!("g(90 deg) s1 g^-1 = cos(90) s1 + sin(90) s2, to 1e-12: {}", yn(err < 1e-12));
    assert!(err < 1e-12);
    let minus = mul(&mul(&lin(&[(r(-1.0), spin(t))]), &S1), &lin(&[(r(-1.0), spin(-t))]));
    println!("g and -g turn s1 the same way: {}", yn(size(&lin(&[(r(1.0), minus), (r(-1.0), turned)])) < 1e-12));
    for deg in [360.0f64, 720.0] { println!("g after a {} degree turn: {:.6} times the identity", deg, spin(deg.to_radians())[0][0].re) }
    assert!((spin(2.0 * PI)[0][0].re + 1.0).abs() < 1e-12 && (spin(4.0 * PI)[0][0].re - 1.0).abs() < 1e-12 && size(&lin(&[(r(1.0), minus), (r(-1.0), turned)])) < 1e-12);
    let (dx, dy) = (lin(&[(c(0.0, -1.0), S1)]), lin(&[(c(0.0, -1.0), S2)]));   // D = -i(s1 d/dx + s2 d/dy)
    let (xx, yy, xy) = (mul(&dx, &dx), mul(&dy, &dy), lin(&[(r(1.0), mul(&dx, &dy)), (r(1.0), mul(&dy, &dx))]));
    println!("D squared: d2/dx2 coefficient {:.0} | d2/dy2 {:.0} | d2/dxdy {:.0}", xx[0][0].re, yy[0][0].re, size(&xy));
    assert!(size(&lin(&[(r(1.0), xx), (r(1.0), I)])) < 1e-12 && size(&xy) < 1e-12);
    let mut spec: Vec<(f64, usize)> = Vec::new();
    for m in -3..4 { for n in -3..4 {
        for lam in eig2(&mode(m as f64, n as f64)) {   // road 2 against road 1, sqrt(m^2 + n^2)
            assert!((lam.abs() - (m as f64).hypot(n as f64)).abs() < 1e-9 && size(&lin(&[(r(1.0), mul(&S3, &mode(m as f64, n as f64))), (r(1.0), mul(&mode(m as f64, n as f64), &S3))])) < 1e-12);
            if lam.abs() < 2.3 {
                let key = (lam * 1e6).round() / 1e6 + 0.0;
                match spec.iter_mut().find(|e| e.0 == key) { Some(e) => e.1 += 1, None => spec.push((key, 1)) }
            }
        }
    } }
    spec.sort_by(|a, b| a.0.partial_cmp(&b.0).unwrap());
    println!("torus eigenvalues with multiplicity: {}", spec.iter().map(|(k, v)| format!("{:.6} x{}", k, v)).collect::<Vec<_>>().join(", "));
    println!("chirality s3 anticommutes with D on mode (1, 2): {:.0}", size(&lin(&[(r(1.0), mul(&S3, &mode(1.0, 2.0))), (r(1.0), mul(&mode(1.0, 2.0), &S3))])));
    let (kp, km) = eig2(&S3).iter().fold((0, 0), |(p, q), &v| (p + (v > 0.0) as usize, q + (v < 0.0) as usize));   // s3 splits the kernel by handedness
    let k0 = spec.iter().find(|e| e.0 == 0.0).map_or(0, |e| e.1); assert!(k0 == kp + km && kp == km);   // flat torus: curvature integral 0
    println!("kernel: {} constant spinors, (1, 0) in S+ and (0, 1) in S-; index of D+ = {} - {} = {}", k0, kp, km, kp as i64 - km as i64);
    let e34 = eig2(&mode(3.0, 4.0)); println!("try: mode (3, 4) eigenvalues {:.6} and {:.6}", e34[0], e34[1]);
    let errs: Vec<f64> = [16.0, 32.0, 64.0].iter().map(|&nn| 5f64.sqrt() - grid_eig(1.0, 2.0, nn)).collect();
    for (nn, e) in [16, 32, 64].iter().zip(&errs) { println!("grid {} x {}: mode (1, 2) eigenvalue {:.6}, error {:.6}", nn, nn, 5f64.sqrt() - e, e) }
    assert!(3.5 < errs[0] / errs[1] && errs[0] / errs[1] < 4.5);   // error falls like h^2
    let sphere = surface(&vec![[0, 1, 2], [0, 1, 3], [0, 2, 3], [1, 2, 3]]);
    let mut tf: Vec<[usize; 3]> = Vec::new();
    for i in 0..3 { for j in 0..3 {
        tf.push(sorted3([3 * i + j, 3 * i + (j + 1) % 3, 3 * ((i + 1) % 3) + (j + 1) % 3]));
        tf.push(sorted3([3 * i + j, 3 * ((i + 1) % 3) + j, 3 * ((i + 1) % 3) + (j + 1) % 3]));
    } }
    let torus = surface(&tf);
    for (name, (v, e, f, b, ke, ko)) in [("sphere", sphere), ("torus", torus)] {
        let (chi, alt) = (v as i64 - e as i64 + f as i64, b[0] as i64 - b[1] as i64 + b[2] as i64);
        println!("{}: V - E + F = {} - {} + {} = {}; b = ({}, {}, {}); b0 - b1 + b2 = {}", name, v, e, f, chi, b[0], b[1], b[2], alt);
        println!("{}: d + delta kernel on even forms {}, on odd forms {}, index {}", name, ke, ko, ke as i64 - ko as i64);
        assert!(ke as i64 - ko as i64 == chi && chi == alt && ke == b[0] + b[2] && ko == b[1]);
    }
    for (a, cc, n) in [(2.0, 1.0, 20), (2.0, 1.0, 40), (1.0, 0.1, 40)] { println!("spheroid a = {}, c = {}, {} steps: total curvature / 2 pi = {:.6}", a, cc, n, gauss_bonnet(a, cc, n)) }
    let (gb20, gb40) = (gauss_bonnet(2.0, 1.0, 20) - 2.0, gauss_bonnet(2.0, 1.0, 40) - 2.0);
    assert!(gb40.abs() < 5e-4 && 3.5 < gb20 / gb40 && gb20 / gb40 < 4.5);   // converges to 2 like h^2
    let edges = [(0, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (1, 3)];
    let e8 = |i: usize, j: usize| -> f64 { if i == j { 2.0 } else if edges.iter().any(|&(a, b)| (a, b) == (i, j) || (a, b) == (j, i)) { -1.0 } else { 0.0 } };
    let mut q = vec![vec![0.0; 22]; 22];
    for blk in 0..2 { for i in 0..8 { for j in 0..8 { q[8 * blk + i][8 * blk + j] = -e8(i, j) } } }
    for h in 0..3 { q[16 + 2 * h][17 + 2 * h] = 1.0; q[17 + 2 * h][16 + 2 * h] = 1.0 }
    let ev = jacobi(q); let (pos, neg) = (ev.iter().filter(|&&v| v > 1e-9).count() as i64, ev.iter().filter(|&&v| v < -1e-9).count() as i64);
    let (chi, p1): (i64, i64) = (2 + 22, 0 - 2 * (2 + 22));   // c2 = chi, c1 = 0, p1 = c1^2 - 2 c2
    println!("K3 intersection form: {} positive, {} negative eigenvalues; signature {}", pos, neg, pos - neg);
    println!("K3 from curvature: chi = {}, p1 = {}, signature = p1/3 = {}, A-hat = -p1/24 = {}", chi, p1, p1 / 3, -p1 / 24);
    assert!(3 * (pos - neg) == p1);   // the signature theorem: the two roads agree
    let (c1, c2) = (3i64, 3i64); let pp = c1 * c1 - 2 * c2;   // CP2: c = 1 + 3h + 3h^2, signature 1
    println!("CP2: signature 1, p1 = {}, p1/3 = {:.6}, A-hat = -p1/24 = {:.6} (not whole: CP2 is not spin)", pp, pp as f64 / 3.0, -(pp as f64) / 24.0);
    println!("unit sphere: S = 2, Lichnerowicz S/4 = {:.6}, Friedrich nS/(4(n-1)) = {:.6}", 2.0 / 4.0, 2.0 * 2.0 / 4.0);
    let mono: Vec<String> = (0..3 + 1).map(|k| format!("z^{}", k)).collect();   // polynomials of degree <= 3
    println!("Riemann-Roch on the sphere, degree 3: sections {} count {}; d - g + 1 = {}", mono.join(", "), mono.len(), 3 - 0 + 1);
    let hv = 6.62607015e-34 * 1.0e6 / 1.602176634e-19;   // h v_F in eV m
    for l in [100e-9f64, 200e-9] { println!("graphene flake {:.0} nm: levels {:.4} and {:.4} meV", l * 1e9, 1000.0 * hv / l, 1000.0 * hv / l * 2f64.sqrt()) }
    let (same, no_i) = (lin(&[(r(1.0), S1), (r(1.0), S1)]), lin(&[(c(0.0, 1.0), S1), (c(0.0, 1.0), S2)]));   // mode (1, 1) with each mistake
    println!("mistake: commuting s1, s1 on mode (1, 1): D squared gives {:.0}, not 2", eig2(&mul(&same, &same))[1]);
    println!("mistake: no -i, (s1 dx + s2 dy) squared on mode (1, 1) gives {:.0}, not 2", eig2(&mul(&no_i, &no_i))[1]);
    let (v, e, f, _, _, _) = surface(&vec![[0, 1, 2]]);
    println!("mistake: one flat triangle, a disc: V - E + F = {} - {} + {} = {}, total curvature / 2 pi = 0", v, e, f, v as i64 - e as i64 + f as i64);
    println!("mistake: no 1/4 in Lichnerowicz: bound {:.6} above the true smallest eigenvalue squared {:.6}", 2.0, 1.0);
    println!("ALL CHECKS PASS");
}
