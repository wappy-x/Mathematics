// Hodge decomposition: the square-lattice torus, complex tori, the quartic surface, the quintic threefold
use std::collections::HashMap;
use std::f64::consts::PI;

#[derive(Clone, Copy, PartialEq, Debug)]
struct Fr { n: i128, d: i128 } // a fraction in lowest terms, denominator positive
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn fr(n: i128, d: i128) -> Fr {
    let g = gcd(n, d).max(1);
    let s = if d < 0 { -1 } else { 1 };
    Fr { n: s * n / g, d: s * d / g }
}
fn mul(a: i128, b: i128) -> i128 { a.checked_mul(b).expect("overflow") }
fn fs(x: Fr) -> String { if x.d == 1 { format!("{}", x.n) } else { format!("{}/{}", x.n, x.d) } }
fn cx(z: (Fr, Fr)) -> String {
    let (s, a) = if z.1.n < 0 { ("-", fr(-z.1.n, z.1.d)) } else { ("+", z.1) };
    format!("{} {} {} i", fs(z.0), s, fs(a))
}
type G = (i128, i128); // a Gaussian integer (re, im)
fn gmul(u: G, v: G) -> G { (mul(u.0, v.0) - mul(u.1, v.1), mul(u.0, v.1) + mul(u.1, v.0)) }
fn gsub(u: G, v: G) -> G { (u.0 - v.0, u.1 - v.1) }
fn gdiv(n: G, d: G) -> (Fr, Fr) {
    let m = mul(d.0, d.0) + mul(d.1, d.1);
    (fr(mul(n.0, d.0) + mul(n.1, d.1), m), fr(mul(n.1, d.0) - mul(n.0, d.1), m))
}
fn lin(a: i128, x: Fr, b: i128, y: Fr) -> Fr { fr(mul(a, mul(x.n, y.d)) + mul(b, mul(y.n, x.d)), mul(x.d, y.d)) } // a x + b y
fn gq(z: G) -> (Fr, Fr) { (fr(z.0, 1), fr(z.1, 1)) }
fn comb(n: i64, k: i64) -> i64 {
    if k < 0 || k > n { return 0; }
    let mut r = 1;
    for i in 0..k { r = r * (n - i) / (i + 1); }
    r
}
fn jac_ring(nv: u32, d: i64, deg: i64) -> i64 { // monomials of degree deg with exponents <= d - 2
    let base = (d - 1) as usize;
    let mut count = 0;
    for code in 0..base.pow(nv) {
        let (mut c, mut s) = (code, 0);
        for _ in 0..nv { s += (c % base) as i64; c /= base; }
        if s == deg { count += 1; }
    }
    count
}
fn euler(n: i64, d: i64) -> i64 { d * (0..=n).map(|j| comb(n + 2, n - j) * (-d).pow(j as u32)).sum::<i64>() }
fn join(v: &[i64], sep: &str) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(sep) }

fn main() {
    // 1. The torus C / (Z + Zi). Periods round the loops a (0 to 1) and b (0 to i)
    let dz: [G; 2] = [(1, 0), (0, 1)];
    let dzb: [G; 2] = [(1, 0), (0, -1)];
    println!("periods of dz: a {}, b {}; of dz-bar: a {}, b {}", cx(gq(dz[0])), cx(gq(dz[1])), cx(gq(dzb[0])), cx(gq(dzb[1])));
    let det = gsub(gmul(dz[0], dzb[1]), gmul(dzb[0], dz[1]));
    println!("period determinant = {}", cx(gq(det)));
    assert!(det != (0, 0));
    // Road 1: Cramer's rule on the periods (A, B) of the closed real form 3 dx + 5 dy
    let (a, b): (G, G) = ((3, 0), (5, 0));
    let c1 = gdiv(gsub(gmul(a, dzb[1]), gmul(dzb[0], b)), det);
    let c2 = gdiv(gsub(gmul(dz[0], b), gmul(a, dz[1])), det);
    println!("{} dx + {} dy = ({}) dz + ({}) dz-bar", a.0, b.0, cx(c1), cx(c2));
    // Road 2: substitute dx = (dz + dz-bar)/2 and dy = (dz - dz-bar)/(2i), then collect the dz and dz-bar parts
    let dxc = (fr(1, 2), fr(0, 1));
    let dyc = [gdiv((1, 0), (0, 2)), gdiv((-1, 0), (0, 2))];
    let s: Vec<(Fr, Fr)> = (0..2).map(|j| (lin(a.0, dxc.0, b.0, dyc[j].0), lin(a.0, dxc.1, b.0, dyc[j].1))).collect();
    assert!(c1 == s[0] && c2 == s[1]);
    assert!(c2 == (c1.0, fr(-c1.1.n, c1.1.d))); // Hodge symmetry
    // Road 3: integrate c1 dz + c2 dz-bar along wiggly loops in the classes of a and b
    let f = |x: Fr| x.n as f64 / x.d as f64;
    let (a1, b1, a2, b2) = (f(c1.0), f(c1.1), f(c2.0), f(c2.1));
    let integral = |vel: &dyn Fn(f64) -> (f64, f64)| {
        let n = 4000;
        let (mut re, mut im) = (0.0f64, 0.0f64);
        for k in 0..n {
            let (vx, vy) = vel((k as f64 + 0.5) / n as f64);
            re += ((a1 + a2) * vx - (b1 - b2) * vy) / n as f64;
            im += ((b1 + b2) * vx + (a1 - a2) * vy) / n as f64;
        }
        (re, im)
    };
    let w = 0.2 * 2.0 * PI;
    let ia = integral(&|t| (1.0, w * (2.0 * PI * t).cos()));
    let ib = integral(&|t| (w * (2.0 * PI * t).cos(), 1.0));
    println!("wiggly loop a gives {:.9} {:+.9} i; wiggly loop b gives {:.9} {:+.9} i", ia.0, ia.1, ib.0, ib.1);
    assert!((ia.0 - a.0 as f64).abs() + ia.1.abs() < 1e-9 && (ib.0 - b.0 as f64).abs() + ib.1.abs() < 1e-9); // the loops return the periods

    // 2. Complex n-torus: count wedges of dz's and dz-bars by type, against binomials
    let mut hol_only = 0;
    for n in 1..=2i64 {
        let mut h: HashMap<(i64, i64), i64> = HashMap::new();
        for mask in 0u32..(1 << (2 * n)) { // first n bits: dz's, last n bits: dz-bars
            let p = (mask & ((1 << n) - 1)).count_ones() as i64;
            let k = mask.count_ones() as i64;
            *h.entry((p, k - p)).or_insert(0) += 1;
        }
        for k in 0..=2 * n {
            let ps: Vec<i64> = ((k - n).max(0)..=k.min(n)).collect();
            let row: Vec<i64> = ps.iter().map(|&p| h[&(p, k - p)]).collect();
            let mut rev = row.clone();
            rev.reverse();
            assert!(row.iter().sum::<i64>() == comb(2 * n, k) && row == rev);
            assert!(row == ps.iter().map(|&p| comb(n, p) * comb(n, k - p)).collect::<Vec<_>>());
            println!("torus dim {}, k = {}: b{} = {} = {}", n, k, k, comb(2 * n, k), join(&row, " + "));
        }
        if n == 1 { hol_only = h[&(1, 0)]; }
    }

    // 3. Hypersurfaces in projective space, two roads
    let r: Vec<i64> = (0..3).map(|q| jac_ring(4, 4, 4 * q)).collect();
    let (h20, h11, h02) = (r[0], r[1] + 1, r[2]);
    println!("quartic, Jacobian ring: h20 = {}, primitive h11 = {}, h02 = {}; with the hyperplane class h11 = {}", r[0], r[1], r[2], h11);
    let chi = euler(2, 4);
    let (b2, pg) = (chi - 2, comb(4 - 1, 3));
    let noether = fr(((4 - 4) * (4 - 4) * 4 + chi) as i128, 12);
    println!("quartic, topology: Euler characteristic {}, b2 = {}, p_g = {}, Noether (K^2 + 24)/12 = {}", chi, b2, pg, fs(noether));
    assert!(h20 == pg && h02 == pg && h11 == b2 - 2 * pg && noether == fr(1 + pg as i128, 1));
    println!("quartic diamond rows: 1 | 0 0 | {} {} {} | 0 0 | 1", h20, h11, h02);
    let q: Vec<i64> = (0..4).map(|k| jac_ring(5, 5, 5 * k)).collect();
    let chi3 = euler(3, 5);
    let b3 = 4 - chi3;
    println!("quintic, Jacobian ring: h30, h21, h12, h03 = {}", join(&q, ", "));
    println!("quintic, topology: Euler characteristic {}, b3 = {}", chi3, b3);
    let mut qr = q.clone();
    qr.reverse();
    assert!(q.iter().sum::<i64>() == b3 && q == qr);

    // 4. What breaks
    let (s1p, s3p) = ([1i64, 1], [1i64, 0, 0, 1]);
    let hopf: Vec<i64> = (0..5i64).map(|k| (0..2i64).filter(|&i| k - i >= 0 && k - i < 4).map(|i| s1p[i as usize] * s3p[(k - i) as usize]).sum()).collect();
    println!("Hopf surface S1 x S3, Betti numbers [{}]: b1 = {} is odd, so h10 = h01 is impossible", join(&hopf, ", "), hopf[1]);
    assert!(hopf[1] % 2 == 1);
    println!("mistakes: torus with holomorphic forms only, b1 = {}; quartic h11 read as b2 = {}; no hyperplane class, h11 = {}", hol_only, b2, r[1]);
    let pts = [("0", (0, 0)), ("1", (1, 0)), ("i", (0, 1)), ("1+i", (1, 1))];
    let fig: Vec<String> = pts.iter().map(|(m, z)| format!("{} at ({},{})", m, 60 + 150 * z.0, 360 - 150 * z.1)).collect();
    println!("figure, 150 px per unit, {}", fig.join(", "));
    println!("ALL CHECKS PASS");
}
