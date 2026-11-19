// Algebraic cycles and cycle classes: the check behind the card.  Rust std only.
// X: x^4 - y^4 - z^4 + w^4 = 0, a smooth quartic surface over C.  The plane P: x - y - z + w = 0
// cuts X in a line L (x = y, z = w), a line M (x = z, y = w) and a conic C.  The cycle is W = C + L.
use std::collections::BTreeMap;
use std::f64::consts::PI;
type Poly = BTreeMap<[u32; 3], i64>;

fn pmul(p: &Poly, q: &Poly) -> Poly {
    let mut r = Poly::new();
    for (a, c) in p { for (b, d) in q { *r.entry([a[0] + b[0], a[1] + b[1], a[2] + b[2]]).or_insert(0) += c * d; } }
    r.retain(|_, v| *v != 0); r
}
fn padd(ps: &[&Poly]) -> Poly {
    let mut r = Poly::new();
    for p in ps { for (k, v) in *p { *r.entry(*k).or_insert(0) += v; } }
    r.retain(|_, v| *v != 0); r
}
fn ppow(p: &Poly, n: u32) -> Poly { let mut r = Poly::from([([0, 0, 0], 1)]); for _ in 0..n { r = pmul(&r, p); } r }
fn neg(p: &Poly) -> Poly { p.iter().map(|(k, v)| (*k, -v)).collect() }

#[derive(Clone, Copy, PartialEq)]
struct Fr { n: i128, d: i128 }             // a fraction in lowest terms, d > 0; overflow stops the run
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn fr(n: i128, d: i128) -> Fr { let g = gcd(n, d).max(1) * d.signum(); Fr { n: n / g, d: d / g } }
fn fm(a: Fr, b: Fr) -> Fr { fr(a.n.checked_mul(b.n).unwrap(), a.d.checked_mul(b.d).unwrap()) }
fn fa(a: Fr, b: Fr) -> Fr { fr(a.n.checked_mul(b.d).unwrap() + b.n.checked_mul(a.d).unwrap(), a.d.checked_mul(b.d).unwrap()) }
fn fs(a: Fr, b: Fr) -> Fr { fa(a, fr(-b.n, b.d)) } fn fstr(a: Fr) -> String { if a.d == 1 { format!("{}", a.n) } else { format!("{}/{}", a.n, a.d) } }
fn gs(re: Fr, im: Fr) -> String {           // a Gaussian number with rational parts, printed exactly
    if im.n == 0 { return fstr(re); }
    let t = if im == fr(1, 1) { "i".to_string() } else if im == fr(-1, 1) { "-i".to_string() } else { format!("{}i", fstr(im)) };
    if re.n == 0 { t } else { format!("{} {} {}", fstr(re), if im.n > 0 { "+" } else { "-" }, t.trim_start_matches('-')) }
}

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64) -> C { C { re, im: 0.0 } }
fn cadd(a: C, b: C) -> C { C { re: a.re + b.re, im: a.im + b.im } } fn csub(a: C, b: C) -> C { C { re: a.re - b.re, im: a.im - b.im } }
fn cmul(a: C, b: C) -> C { C { re: a.re * b.re - a.im * b.im, im: a.re * b.im + a.im * b.re } }
fn cis(t: f64) -> C { C { re: t.cos(), im: t.sin() } } fn abs2(a: C) -> f64 { a.re * a.re + a.im * a.im }

fn rank(m: &Vec<Vec<i64>>) -> usize {
    let mut m: Vec<Vec<Fr>> = m.iter().map(|r| r.iter().map(|&x| fr(x as i128, 1)).collect()).collect();
    let mut rk = 0;
    for col in 0..m[0].len() {
        let piv = match (rk..m.len()).find(|&i| m[i][col].n != 0) { Some(p) => p, None => continue };
        m.swap(rk, piv);
        for i in 0..m.len() {
            if i != rk && m[i][col].n != 0 {
                let f = fm(m[i][col], fr(m[rk][col].d, m[rk][col].n));
                let row = m[rk].clone(); for j in 0..row.len() { m[i][j] = fs(m[i][j], fm(f, row[j])); }
            }
        }
        rk += 1; }
    rk }

fn main() {
    let (x, y, z) = (Poly::from([([1, 0, 0], 1)]), Poly::from([([0, 1, 0], 1)]), Poly::from([([0, 0, 1], 1)]));
    let w = padd(&[&neg(&x), &y, &z]);                         // on P, w = -x + y + z
    let f_on_p = padd(&[&ppow(&x, 4), &neg(&ppow(&y, 4)), &neg(&ppow(&z, 4)), &ppow(&w, 4)]);
    let q2 = Poly::from([([2, 0, 0], 2), ([0, 2, 0], 4), ([0, 0, 2], 4), ([1, 1, 0], -2), ([1, 0, 1], -2), ([0, 1, 1], 6)]);
    let split = pmul(&pmul(&padd(&[&x, &neg(&y)]), &padd(&[&x, &neg(&z)])), &q2);
    println!("road 1, exact algebra on the plane section, over C");
    println!("F on P = 2 (x - y)(x - z)(x^2 + 2y^2 + 2z^2 - xy - xz + 3yz): {}", if split == f_on_p { "yes" } else { "no" });
    let s = [[fr(1, 1), fr(-1, 2), fr(-1, 2)], [fr(-1, 2), fr(2, 1), fr(3, 2)], [fr(-1, 2), fr(3, 2), fr(2, 1)]];
    let m2 = |a: usize, b: usize, cc: usize, d: usize| fs(fm(s[1][a], s[2][b]), fm(s[1][cc], s[2][d]));
    let det = fa(fs(fm(s[0][0], m2(1, 2, 2, 1)), fm(s[0][1], m2(0, 2, 2, 0))), fm(s[0][2], m2(0, 1, 1, 0)));
    println!("conic matrix determinant {}, leading minors 1, {}: smooth, no real points", fstr(det), fstr(fs(fm(s[0][0], s[1][1]), fm(s[0][1], s[0][1]))));
    let qf = |u: [i128; 3], v: [i128; 3]| { let mut t = fr(0, 1);
        for i in 0..3 { for j in 0..3 { t = fa(t, fm(s[i][j], fr(u[i] * v[j], 1))); } } t };
    let rows = [("C . L", [1, 1, 0], [0, 0, 1]), ("C . M", [1, 0, 1], [0, 1, 0]), ("C . h (plane x = 0)", [0, 1, 0], [0, 0, 1])];
    let mut num = vec![];
    for (name, u, v) in rows {
        let (a, b, cc) = (qf(u, u), fm(fr(2, 1), qf(u, v)), qf(v, v));
        let disc = fs(fm(b, b), fm(fr(4, 1), fm(a, cc)));
        let n_c = if disc.n != 0 { 2 } else { 1 };
        let n_r = if disc.n > 0 { 2 } else if disc.n == 0 { 1 } else { 0 };
        num.push((n_c, n_r)); println!("{}: discriminant {}; {} points over C, {} over R", name, fstr(disc), n_c, n_r);
    }
    let lin = [[1, -1, 0, 0], [0, 0, 1, -1], [1, 0, -1, 0], [0, 1, 0, -1]];   // L: x = y, z = w; M: x = z, y = w
    let on = lin.iter().all(|r| r.iter().sum::<i64>() == 0);
    println!("L . M: (1 : 1 : 1 : 1) on both: {}; q there = {}, so C misses it", if on { "yes" } else { "no" }, fstr(qf([1, 1, 1], [1, 1, 1])));
    let (cl, cm, ch) = (num[0].0, num[1].0, num[2].0);
    let rk3 = |m: Vec<Vec<i64>>| (rank(&m) == 3) as i64;      // 3 independent planes: 1 point
    let (lm, lh, mh) = (rk3(lin.iter().map(|r| r.to_vec()).collect()), rk3(vec![lin[0].to_vec(), lin[1].to_vec(), vec![1, 0, 0, 0]]), rk3(vec![lin[2].to_vec(), lin[3].to_vec(), vec![1, 0, 0, 0]]));
    let (ccs, ll, mm) = (ch - cl - cm, lh - cl - lm, mh - cm - lm);  // h = C + L + M, paired with C, L and M
    let (g, hh) = ([[ccs, cl, cm], [cl, ll, lm], [cm, lm, mm]], ch + lh + mh);
    println!("self-intersections from h = C + L + M: C.C = {}, L.L = {}, M.M = {}; adjunction 2g - 2 = -2", ccs, ll, mm);
    let ft = [-1i64, 0, 0, 0, 1]; let dft: Vec<i64> = (0..4).map(|k| (4 - k as i64) * ft[k]).collect();   // X on x = y = 0 at w = 1 (w = 0 forces z = 0): 1 - t^4; dft = ft'
    let npts = 4 - (7 - rank(&(0..3).map(|i| [vec![0; i], ft.to_vec(), vec![0; 2 - i]].concat()).chain((0..4).map(|i| [vec![0; i], dft.clone(), vec![0; 3 - i]].concat())).collect()) as i64);  // 4 - deg gcd(ft, ft')
    println!("h.h = {} + {} + {} = {}; line x = y = 0 meets X where z^4 = w^4: {} points", ch, lh, mh, hh, npts);
    let eu = 4i64.pow(3) - 4 * 4i64.pow(2) + 6 * 4;              // Euler number of a smooth quartic surface (quoted formula)
    println!("Euler number {}, so H^2 has rank {}; h^(2,0) = h^(0,2) = 1, so type (1,1) has dimension {}", eu, eu - 2, eu - 4);
    let pair = |a: [i64; 3], b: [i64; 3]| { let mut t = 0; for i in 0..3 { for j in 0..3 { t += a[i] * g[i][j] * b[j]; } } t };
    let cycle = |n: i64, m: i64| { let wv = [n, m, 0]; (pair(wv, [1, 1, 1]), pair(wv, wv), pair(wv, [0, 0, 1])) };
    for (n, m) in [(1, 1), (3, -2)] {
        let (d, sq, wm) = cycle(n, m); println!("W = {} C {} {} L: degree W.h = {}, W.W = {}, W.M = {}", n, if m > 0 { "+" } else { "-" }, m.abs(), d, sq, wm);
    }
    let pc: Vec<i64> = [[1, 0, 0], [0, 1, 0], [0, 0, 1]].iter().map(|e| pair([1, 1, 0], *e)).collect();
    println!("[C + L] = h - [M]: pairs with C, L, M as {:?} and h - M as {:?}", pc, [ch - cm, lh - lm, mh - mm]);
    println!("road 2, the class read by integrating forms (Simpson's rule)");
    let sf: Vec<Vec<f64>> = s.iter().map(|r| r.iter().map(|a| a.n as f64 / a.d as f64).collect()).collect();
    let bf = |u: [C; 3], v: [C; 3]| { let mut t = c(0.0);
        for i in 0..3 { for j in 0..3 { t = cadd(t, cmul(c(sf[i][j]), cmul(u[i], v[j]))); } } t };
    let om = cis(2.0 * PI / 3.0);
    let p0 = [om, om, c(1.0)];                                 // a point of C, where C meets L
    let curve_c = |t: C| -> ([C; 4], [C; 4]) {                 // second point of C on the line from p0 towards d = (1, t, 0)
        let (d, dd) = ([c(1.0), t, c(0.0)], [c(0.0), c(1.0), c(0.0)]);
        let (qd, b) = (bf(d, d), bf(p0, d));
        let (qd1, b1) = (cmul(c(2.0), bf(d, dd)), bf(p0, dd));
        let mut ph = [c(0.0); 4]; let mut dph = [c(0.0); 4];
        for i in 0..3 {
            ph[i] = csub(cmul(qd, p0[i]), cmul(cmul(c(2.0), b), d[i]));
            dph[i] = csub(csub(cmul(qd1, p0[i]), cmul(cmul(c(2.0), b1), d[i])), cmul(cmul(c(2.0), b), dd[i]));
        }
        ph[3] = csub(cadd(ph[1], ph[2]), ph[0]); dph[3] = csub(cadd(dph[1], dph[2]), dph[0]); (ph, dph) };
    let curve_l = |t: C| -> ([C; 4], [C; 4]) { ([c(1.0), c(1.0), t, t], [c(0.0), c(0.0), c(1.0), c(1.0)]) };
    fn fs_area(curve: &dyn Fn(C) -> ([C; 4], [C; 4]), n: usize) -> f64 {   // integral of h over the curve; a line gives 1
        let dens = |t: C| { let (ph, dph) = curve(t);
            let a: f64 = ph.iter().map(|z| abs2(*z)).sum(); let b: f64 = dph.iter().map(|z| abs2(*z)).sum();
            let mut cr = c(0.0); for k in 0..4 { cr = cadd(cr, cmul(C { re: ph[k].re, im: -ph[k].im }, dph[k])); }
            (a * b - abs2(cr)) / (PI * a * a) };
        let mut tot = 0.0;
        for i in 0..n {                                        // t = tan(alpha) e^(i theta): Simpson in alpha, trapezium in theta
            let al = (PI / 2.0) * i as f64 / n as f64;
            let wa = if i == 0 { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
            let r = al.tan(); let jac = r / al.cos().powi(2);
            let mut ring = 0.0;
            for k in 0..n { let e = cis(2.0 * PI * k as f64 / n as f64); ring += dens(C { re: r * e.re, im: r * e.im }); }
            tot += wa * (ring * (2.0 * PI / n as f64)) * jac;
        }
        tot * (PI / 2.0) / n as f64 / 3.0
    }
    let (a_c, a_l) = (fs_area(&curve_c, 400), fs_area(&curve_l, 400));
    println!("integral of h over C {:.6}, over L {:.6}, over W = C + L {:.6}", a_c, a_l, a_c + a_l);
    println!("road 3, the type test");
    // sigma = dx dy / (dF/dz) at (1, 1, 1), chart w = 1; vectors are Gaussian integers (re, im)
    let sigma = |u: [(i128, i128); 3], v: [(i128, i128); 3]| {
        let gm = |a: (i128, i128), b: (i128, i128)| (a.0 * b.0 - a.1 * b.1, a.0 * b.1 + a.1 * b.0);
        let (p, q) = (gm(u[0], v[1]), gm(u[1], v[0]));
        gs(fr(p.0 - q.0, -4), fr(p.1 - q.1, -4)) };
    let (u, v) = ([(1, 0), (1, 0), (0, 0)], [(1, 0), (0, 0), (1, 0)]);   // tangent to L and to M; together, X's real points
    let (iu, iv) = (u.map(|a: (i128, i128)| (-a.1, a.0)), v.map(|a: (i128, i128)| (-a.1, a.0)));   // i times each vector
    println!("sigma on L's tangent (u, iu): {}; on M's (v, iv): {}; on the real plane (u, v): {}", sigma(u, iu), sigma(v, iv), sigma(u, v));
    let plk = |a: [i64; 4], b: [i64; 4]| { let mut p = vec![];
        for i in 0..4 { for j in i + 1..4 { p.push(a[i] * b[j] - a[j] * b[i]); } } p };
    let dz12 = |p: &Vec<i64>| (p[1] - p[4], p[2] + p[3]);    // dz1 dz2 on the class; basis (1,0), (i,0), (0,1), (0,i)
    let tor = [("E x 0", [1, 0, 0, 0], [0, 1, 0, 0]), ("0 x E", [0, 0, 1, 0], [0, 0, 0, 1]), ("diagonal", [1, 0, 1, 0], [0, 1, 0, 1]),
               ("graph of i", [1, 0, 0, 1], [0, 1, -1, 0]), ("real torus (1,0), (0,i)", [1, 0, 0, 0], [0, 0, 0, 1])];
    let gz = |t: (i64, i64)| gs(fr(t.0 as i128, 1), fr(t.1 as i128, 1));
    let mut cls = vec![];
    for (name, a, b) in tor {
        let p = plk(a, b); println!("E x E, {}: class ({}), dz1 dz2 gives {}", name, p.iter().map(|v| v.to_string()).collect::<Vec<_>>().join(", "), gz(dz12(&p)));
        cls.push(p); }
    let tests = vec![vec![0, 1, 0, 0, -1, 0], vec![0, 0, 1, 1, 0, 0]];   // p13 - p24 = 0, p14 + p23 = 0: the type (1, 1) classes
    let rc = rank(&cls[..4].to_vec());
    println!("rank of the four curve classes {}; rank of all type (1,1) classes 6 - {} = {}", rc, rank(&tests), 6 - rank(&tests));
    println!("mistake 1, C . L and C . M over R: {} and {}, so C.C = {} - 0 - 0 = {}", num[0].1, num[1].1, ch, ch - num[0].1 - num[1].1);
    println!("mistake 2, L.L = +1 as in the plane: L.h = {}, but L meets a plane in {} point", cl + 1 + lm, lh);
    println!("mistake 3, the real torus as a cycle: dz1 dz2 gives {}, not 0", gz(dz12(&cls[4])));
    assert!(split == f_on_p && det == fr(3, 2));                       // the section really is L + M + C
    assert!((cl, cm, ch) == (2, 2, 2) && num[0].1 == 0);              // counts over C against over R
    assert!((ccs, ll, mm) == (-2, -2, -2) && hh == npts);              // linearity against adjunction and a line's points
    assert!(cycle(1, 1).1 == hh - 2 * mh + mm && hh - 2 * mh + mm == 0 && cycle(1, 1).0 == (a_c + a_l).round() as i64 && cycle(1, 1).0 == 3);  // [W] = h - [M]
    assert!((a_c - ch as f64).abs() < 1e-6 && (a_l - lh as f64).abs() < 1e-6);   // analysis against counting
    assert!((0..4).all(|k| { let s = if k < 2 { u } else { v }; (0..3).map(|j| lin[k][j] * s[j].0 as i64).sum::<i64>() == 0 }));  // u lies along L, v along M
    assert!(sigma(u, iu) == "0" && sigma(v, iv) == "0" && sigma(u, v) != "0");
    assert!(cls[..4].iter().all(|p| dz12(p) == (0, 0)) && dz12(&cls[4]) != (0, 0));
    assert!(rc == 6 - rank(&tests) && rc == 4);
    println!("ALL CHECKS PASS");
}
