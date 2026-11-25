// Hecke operators and eigenforms -- the same check as the Python, in Rust.  No
// crates.  Here q = e^(2 pi i z), never a modulus, and tau(n) is Ramanujan's.
use std::collections::BTreeSet;
use std::f64::consts::PI;
const L: usize = 130;                     // every series is kept to q^L
type V = Vec<i128>;

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
impl std::ops::Add for C { type Output = C; fn add(self, o: C) -> C { c(self.re + o.re, self.im + o.im) } }
impl std::ops::Mul for C { type Output = C; fn mul(self, o: C) -> C { c(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) } }
fn sc(a: C, t: f64) -> C { c(a.re * t, a.im * t) }
fn cexp(w: C) -> C { c(w.re.exp() * w.im.cos(), w.re.exp() * w.im.sin()) }
fn ev(a: &[i128], z: C, top: usize) -> C {    // sum of a[n] q^n for n <= top, by Horner
    let q = cexp(c(-2.0 * PI * z.im, 2.0 * PI * z.re));
    let mut s = c(0.0, 0.0);
    for n in (1..=top).rev() { s = (s + c(a[n] as f64, 0.0)) * q }
    s
}
fn show(w: C) -> String { format!("{:.9} {} {:.9}i", w.re, if w.im >= 0.0 { "+" } else { "-" }, w.im.abs()) }
fn sci(x: f64) -> String { let e = x.abs().log10().floor(); format!("{:.7}e{}", x / 10f64.powf(e), e as i64) }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a } else { gcd(b, a % b) } }
fn sigma(k: u32, n: i128) -> i128 { (1..=n).filter(|d| n % d == 0).map(|d| d.pow(k)).sum() }
fn primes(n: usize) -> Vec<usize> { (2..=n).filter(|&p| (2..p).all(|d| p % d != 0)).collect() }
fn lst<T: std::fmt::Display>(v: &[T]) -> String { format!("[{}]", v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ")) }

fn product(parts: &[(usize, usize)]) -> V {   // q * prod over n of (1 - q^(c n))^e
    let mut p: V = vec![0; L + 1]; p[0] = 1;
    for &(c, e) in parts { for n in 1..=L / c { for _ in 0..e { for i in (c * n..=L).rev() { p[i] -= p[i - c * n] } } } }
    let mut out = vec![0]; out.extend_from_slice(&p[..L]); out
}
fn mul(a: &[i128], b: &[i128], top: usize) -> V {
    (0..=top).map(|n| (0..=n).map(|i| a[i].checked_mul(b[n - i]).unwrap()).fold(0i128, |s, t| s.checked_add(t).unwrap())).collect()
}
fn t(a: &[i128], n: usize, k: u32, lev: i128) -> V {  // Hecke T_n on coefficients, weight k, level N
    (0..=(a.len() - 1) / n).map(|m| (1..=n).filter(|&d| m % d == 0 && n % d == 0 && gcd(d as i128, lev) == 1)
        .map(|d| (d as i128).pow(k - 1).checked_mul(a[m * n / (d * d)]).unwrap()).sum()).collect()
}
fn matrix_average(a: &[i128], n: usize, k: i32, z: C) -> C {  // road 2: (a b; 0 d), ad = n, 0 <= b < d
    let mut s = c(0.0, 0.0);
    for d in (1..=n).filter(|d| n % d == 0) { for b in 0..d {
        let w = c(((n / d) as f64 * z.re + b as f64) / d as f64, (n / d) as f64 * z.im / d as f64);
        s = s + sc(ev(a, w, L), (n as f64).powi(k - 1) / (d as f64).powi(k)) } }
    s
}
fn hecke_rules(a: &[i128], k: u32, lev: usize, top: usize) -> (usize, usize) {
    let (mut cop, mut pp) = (0, 0);
    for m in 2..=top { for n in m + 1..=top / m { if gcd(m as i128, n as i128) == 1 { assert!(a[m * n] == a[m] * a[n]); cop += 1 } } }
    for p in primes(top) { if lev % p != 0 { let mut r = p;
        while r * p <= top { assert!(a[r * p] == a[p] * a[r] - (p as i128).pow(k - 1) * a[r / p]); pp += 1; r *= p } } }
    (cop, pp)
}
fn span(v: (usize, usize), w: (usize, usize), n: usize) -> u64 {   // the lattice rows v, w span, mod n, as a bit mask
    let mut s = 0u64; for i in 0..n { for j in 0..n { s |= 1 << ((i * v.0 + j * w.0) % n * n + (i * v.1 + j * w.1) % n) } } s
}
const D: i128 = 144169;
fn zm(u: (i128, i128), v: (i128, i128)) -> (i128, i128) {   // (x, y) means x + y r, r = sqrt(D)
    (u.0.checked_mul(v.0).unwrap() + D.checked_mul(u.1).unwrap().checked_mul(v.1).unwrap(), u.0 * v.1 + u.1 * v.0)
}
fn mm(a: &[[i128; 2]; 2], b: &[[i128; 2]; 2]) -> [[i128; 2]; 2] {
    let mut o = [[0; 2]; 2];
    for i in 0..2 { for j in 0..2 { o[i][j] = a[i][0] * b[0][j] + a[i][1] * b[1][j] } } o
}

fn main() {
    let mut sl2 = 0; let mut g0 = 0;
    for a in 0..11i64 { for b in 0..11 { for c2 in 0..11 { for d in 0..11 { if (a * d - b * c2).rem_euclid(11) == 1 { sl2 += 1; if c2 == 0 { g0 += 1 } } } } } }
    println!("Gamma_0(11): {} matrices in SL2(Z mod 11), {} with c = 0; index {}", sl2, g0, sl2 / g0);
    let lat: Vec<BTreeSet<u64>> = (2..7).map(|n| (0..n * n).flat_map(|v| (0..n * n).map(move |w| span((v / n, v % n), (w / n, w % n), n)))
        .filter(|s| s.count_ones() as usize == n).collect()).collect();
    let reps: Vec<BTreeSet<u64>> = (2..7).map(|n| (1..=n).filter(|d| n % d == 0).flat_map(|d| (0..d).map(move |b| span((n / d, b), (0, d), n))).collect()).collect();
    let (nl, nr): (Vec<i128>, Vec<i128>) = (lat.iter().map(|x| x.len() as i128).collect(), reps.iter().map(|x| x.len() as i128).collect());
    let sig1: Vec<i128> = (2..7).map(|n| sigma(1, n)).collect();
    println!("classes of determinant-n matrices (row lattices of index n), n = 2..6: {} ; classes holding a (u b; 0 d), 0 <= b < d: {} ; sigma_1(n): {}",
             lst(&nl), lst(&nr), lst(&sig1));
    let tau = product(&[(1, 24)]);
    println!("tau(1..12): {}", lst(&tau[1..13]));
    let m24: V = tau[1..6].iter().map(|x| -24 * x).collect();
    println!("T_2 Delta starts: {} ; -24 x Delta starts: {}", lst(&t(&tau, 2, 12, 1)[1..6]), lst(&m24));
    let eig = (2..7).all(|n| t(&tau, n, 12, 1)[..21] == tau[..21].iter().map(|x| tau[n] * x).collect::<V>()[..]);
    println!("T_n Delta = tau(n) Delta to q^20 for n = 2..6: {}", yn(eig));
    let z = c(0.3, 1.1);
    for n in [2usize, 3] {
        println!("z = {} + {}i, n = {}: matrix average x 1000 = {}; tau(n) Delta(z) x 1000 = {}", z.re, z.im, n,
                 show(sc(matrix_average(&tau, n, 12, z), 1000.0)), show(sc(ev(&tau, z, L), 1000.0 * tau[n] as f64)));
    }
    let s: V = (0..=L as i128).map(|m| (7 * m * m + 3 * m) % 13 - 6).collect();   // an arbitrary series, weight 12
    println!("arbitrary series s starts: {}", lst(&s[1..9]));
    let (t6, t23, t32) = (t(&s, 6, 12, 1), t(&t(&s, 3, 12, 1), 2, 12, 1), t(&t(&s, 2, 12, 1), 3, 12, 1));
    println!("T_2 T_3 s = T_6 s = T_3 T_2 s to q^20: {}", yn(t23[..21] == t6[..21] && t6[..21] == t32[..21]));
    let (t22, t4) = (t(&t(&s, 2, 12, 1), 2, 12, 1), t(&s, 4, 12, 1));
    println!("T_2 T_2 s = T_4 s + 2^11 s to q^30: {}; mistake, T_2 T_2 = T_4: at q^1 {} against {}",
             yn((0..31).all(|m| t22[m] == t4[m] + 2048 * s[m])), t22[1], t4[1]);
    let (cp, pp) = hecke_rules(&tau, 12, 1, L);
    println!("Delta, coprime pairs and prime-power steps to q^130, all hold: ({}, {})", cp, pp);
    println!("tau(6) = {} = ({})({});  tau(4) = {} - {} = {}", tau[6], tau[2], tau[3], tau[2] * tau[2], 2048, tau[4]);

    let f = product(&[(1, 2), (11, 2)]);       // eta(z)^2 eta(11z)^2, level 11, weight 2
    println!("level 11, a(1..12): {}", lst(&f[1..13]));
    let ps: Vec<usize> = primes(47).into_iter().filter(|&p| p != 11).collect();
    let cnt: V = ps.iter().map(|&p| { let p = p as i128; p - (0..p).map(|x| (0..p).filter(|y| (y * y + y - x * x * x + x * x + 10 * x + 20).rem_euclid(p) == 0).count() as i128).sum::<i128>() }).collect();
    let fp: V = ps.iter().map(|&p| f[p]).collect();
    println!("a_p, p = 2..47 but 11:           {}", lst(&fp));
    println!("p minus points of y^2 + y = x^3 - x^2 - 10x - 20 mod p: {}", lst(&cnt));
    println!("level 11: a6 = {} = a2 a3, a4 = {} - 2 = {}, a9 = {} - 3 = {}, a11 = {}, a121 = {}", f[6], f[2] * f[2], f[4], f[3] * f[3], f[9], f[11], f[121]);
    let (cp, pp) = hecke_rules(&f, 2, 11, L);
    println!("level 11, coprime pairs and prime-power steps (p not 11) to q^130, all hold: ({}, {})", cp, pp);
    println!("mistake, a121 = a11^2 - 11 as if 11 were good: {}, against {}", f[11] * f[11] - 11, f[121]);
    let w = sc(ev(&f, sc(z, 2.0), L), 2.0) + sc(ev(&f, sc(z, 0.5), L) + ev(&f, c((z.re + 1.0) / 2.0, z.im / 2.0), L), 0.5);
    let fz = sc(ev(&f, z, L), -2.0);
    println!("level 11 at z: 2 f(2z) + (f(z/2) + f((z+1)/2))/2 = {}; -2 f(z) = {}", show(w), show(fz));
    let h = product(&[(4, 2), (8, 2)]);       // the house curve y^2 = x^3 - x, level 32
    println!("level 32: a3 = {}, a5 = {}, a9 = {} = a3^2 - 3, a25 = {} = a5^2 - 5, a45 = {} = a9 a5", h[3], h[5], h[9], h[25], h[45]);

    let e4: V = (0..=40).map(|n| if n == 0 { 1 } else { 240 * sigma(3, n) }).collect();
    let (g1, g2) = (mul(&tau, &mul(&e4, &mul(&e4, &e4, 40), 40), 40), mul(&tau, &tau, 40));   // basis of S_24
    println!("S_24: g1 = Delta E4^3 starts {} ; g2 = Delta^2 starts {}", lst(&g1[1..5]), lst(&g2[1..5]));
    let coords = |g: &V| -> (i128, i128) { let x = g[1]; let y = g[2] - x * g1[2];
        assert!((0..g.len()).all(|i| g[i] == x * g1[i] + y * g2[i])); (x, y) };
    let mat = |n: usize| { let (a, b) = (coords(&t(&g1, n, 24, 1)), coords(&t(&g2, n, 24, 1))); [[a.0, b.0], [a.1, b.1]] };
    let (a2, a3, a6) = (mat(2), mat(3), mat(6));
    let ms = |m: &[[i128; 2]; 2]| format!("[[{}, {}], [{}, {}]]", m[0][0], m[0][1], m[1][0], m[1][1]);
    println!("T_2 on (g1, g2), columns are images: {} ; T_3: {}", ms(&a2), ms(&a3));
    println!("T_2 T_3 = T_3 T_2 = T_6 as matrices: {}", yn(mm(&a2, &a3) == mm(&a3, &a2) && mm(&a3, &a2) == a6));
    let (tr, det) = (a2[0][0] + a2[1][1], a2[0][0] * a2[1][1] - a2[0][1] * a2[1][0]);
    let (disc, rd) = (tr * tr - 4 * det, (D as f64).sqrt());
    println!("T_2: trace {}, det {}, discriminant {} = 24^2 x {}; eigenvalues 540 +/- 12 r, r = sqrt({}): {:.6}, {:.6}", tr, det, disc, D, D, 540.0 + 12.0 * rd, 540.0 - 12.0 * rd);
    let ef: Vec<(i128, i128)> = (0..=40).map(|n| (g1[n] - 156 * g2[n], 12 * g2[n])).collect();
    println!("eigenform a(2) = ({}, {}), a(3) = ({}, {}), as (x, y) meaning x + y r", ef[2].0, ef[2].1, ef[3].0, ef[3].1);
    let ok_t = [2usize, 3].iter().all(|&n| (0..2).all(|i| { let comp: V = ef.iter().map(|e| if i == 0 { e.0 } else { e.1 }).collect();
        let lhs = t(&comp, n, 24, 1); (0..13).all(|m| { let r = zm(ef[n], ef[m]); lhs[m] == if i == 0 { r.0 } else { r.1 } }) }));
    let a6e = zm(ef[2], ef[3]);
    println!("T_2 and T_3 fix it up to a(n), to q^12: {}; a(6) = a(2) a(3) = ({}, {}): {}", yn(ok_t), a6e.0, a6e.1, yn(a6e == ef[6]));

    let (nx, nt, top) = (240usize, 1200usize, 16usize);   // Simpson: x in [-1/2, 1/2], y = sqrt(1 - x^2) + t
    let (mut g, mut bm) = ([[0.0f64; 2]; 2], [[0.0f64; 2]; 2]);   // bm: the mistake, y^20 for y^22
    for i in 0..=nx { let x = -0.5 + i as f64 / nx as f64; let wx = if i == 0 || i == nx { 1 } else if i % 2 == 1 { 4 } else { 2 };
        for j in 0..=nt { let y = (1.0 - x * x).sqrt() + 6.0 * j as f64 / nt as f64; let wt = if j == 0 || j == nt { 1 } else if j % 2 == 1 { 4 } else { 2 };
            let (u, v) = (ev(&g1, c(x, y), top), ev(&g2, c(x, y), top));
            for (w, e) in [(&mut g, 22.0), (&mut bm, 20.0)] {
                let m = (wx * wt) as f64 * y.powf(e) / (9 * nx * nt) as f64 * 6.0;
                w[0][0] += m * u.re.hypot(u.im).powf(2.0); w[1][1] += m * v.re.hypot(v.im).powf(2.0);
                w[0][1] += m * (u * c(v.re, -v.im)).re; } } }
    g[1][0] = g[0][1]; bm[1][0] = bm[0][1];
    println!("Petersson <g1,g1> = {}, <g1,g2> = {}, <g2,g2> = {}", sci(g[0][0]), sci(g[0][1]), sci(g[1][1]));
    let adj = |w: &[[f64; 2]; 2]| (a2[0][0] as f64 * w[0][1] + a2[1][0] as f64 * w[1][1], a2[0][1] as f64 * w[0][0] + a2[1][1] as f64 * w[0][1]);
    let ((l, r), (lb, rb)) = (adj(&g), adj(&bm));
    println!("<T_2 g1, g2> = {}; <g1, T_2 g2> = {}; naive coefficient pairing gives {} against {}", sci(l), sci(r), a2[1][0], a2[0][1]);
    println!("mistake, y^20 in place of y^22: {} against {}", sci(lb), sci(rb));
    let (vp, vm) = ([1.0, -156.0 + 12.0 * rd], [1.0, -156.0 - 12.0 * rd]);
    let ip = |a: &[f64; 2], b: &[f64; 2]| { let mut s = 0.0; for i in 0..2 { for j in 0..2 { s += a[i] * g[i][j] * b[j] } } s };
    let cos_p = ip(&vp, &vm) / (ip(&vp, &vp) * ip(&vm, &vm)).sqrt();
    let cos_n = (1.0 + vp[1] * vm[1]) / ((1.0 + vp[1].powf(2.0)) * (1.0 + vm[1].powf(2.0))).sqrt();
    println!("the two eigenforms: Petersson cosine below 1e-6: {}; naive coordinate cosine {:.6}", yn(cos_p.abs() < 1e-6), cos_n);

    assert!(sl2 / g0 == 12);
    assert!(lat == reps && nl == sig1);
    assert!(eig && tau[6] == tau[2] * tau[3] && tau[6] == -6048 && tau[4] == tau[2] * tau[2] - 2048 && tau[4] == -1472);
    let (m3, d3) = (matrix_average(&tau, 3, 12, z), sc(ev(&tau, z, L), 252.0));
    assert!((m3.re - d3.re).hypot(m3.im - d3.im) < 1e-9 * d3.re.hypot(d3.im));
    assert!(t22[1] != t4[1] && cnt == fp && (w.re - fz.re).hypot(w.im - fz.im) < 1e-12);
    assert!((f[6], f[4], f[9]) == (2, 2, -2) && f[121] == f[11] * f[11] && mm(&a2, &a3) == a6 && disc == 576 * D);
    assert!((h[9], h[25], h[45]) == (h[3] * h[3] - 3, h[5] * h[5] - 5, h[9] * h[5]) && (h[9], h[25], h[45]) == (-3, -1, 6));
    assert!(ok_t && (l - r).abs() < 1e-6 * l.abs() && (lb - rb).abs() > 0.1 * lb.abs() && cos_p.abs() < 1e-6);
    println!("ALL CHECKS PASS");
}
