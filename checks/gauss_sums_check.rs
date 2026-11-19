// Gauss sums: the quadratic Gauss sum mod 7 has size root seven -- the same check as the
// Python, in Rust.  No crates; cos and sin are written out, so no library holds the answer.
// Road 1 adds the weighted roots of unity directly, two ways.  Road 2 squares the sum
// exactly in Z[zeta_p], with integer lists.  Road 3 is Parseval on the Legendre list.
// Road 4 deduces the sign from eigenvalue counts and a determinant (Schur), then
// compares it with the direct sum for every odd prime below 10,000.
use std::collections::HashMap;
type C = (f64, f64);
const PI: f64 = 3.14159265358979323846;

fn cs(t: f64) -> C {                            // (cos t, sin t) by Taylor series after reduction
    let t = t - 2.0 * PI * (t / (2.0 * PI) + 0.5).floor();
    let (mut c, mut s, mut term, mut k) = (0.0, 0.0, 1.0f64, 0u32);
    while term.abs() > 1e-18 {
        match k % 4 { 0 => c += term, 1 => s += term, 2 => c -= term, _ => s -= term }
        k += 1;
        term = term * t / k as f64;
    }
    (c, s)
}
fn sqrt(x: f64) -> f64 {                        // square root by Newton's method
    let mut r = if x > 1.0 { x } else { 1.0 };
    for _ in 0..60 { r = 0.5 * (r + x / r); } r
}
fn f(x: f64) -> String { if x.abs() > 5e-10 { format!("{:.9}", x + 0.0) } else { "0.000000000".into() } }
fn cx(z: C) -> String { format!("{} {} {}i", f(z.0), if z.1 >= -5e-10 { '+' } else { '-' }, f(z.1.abs())) }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn isprime(n: i64) -> bool { n > 1 && (2..=((n as f64).sqrt() as i64)).all(|d| n % d != 0) }
fn modpow(mut b: i64, mut e: i64, m: i64) -> i64 {
    let mut r = 1 % m; b %= m;
    while e > 0 { if e & 1 == 1 { r = r * b % m; } b = b * b % m; e >>= 1; } r
}
fn leg(a: i64, p: i64) -> i64 { let r = modpow(a, (p - 1) / 2, p); if r == 0 { 0 } else if r == 1 { 1 } else { -1 } }
struct Z { roots: HashMap<i64, Vec<C>> }
impl Z {
    fn zeta(&mut self, k: i64, n: i64) -> C {   // zeta_n^k = e^(2 pi i k / n), from a table built by
        let t = self.roots.entry(n).or_insert_with(|| {   // turning one step, re-aimed every 64
            let (c1, s1) = cs(2.0 * PI / n as f64);
            let (mut c, mut s, mut v) = (0.0, 0.0, Vec::new());
            for j in 0..n {
                (c, s) = if j % 64 == 0 { cs(2.0 * PI * j as f64 / n as f64) } else { (c * c1 - s * s1, c * s1 + s * c1) };
                v.push((c, s));
            } v
        });
        t[k.rem_euclid(n) as usize]
    }
    fn wsum(&mut self, w: &[i64], n: i64, turn: i64) -> C {   // sum of w[a] zeta_n^(turn a)
        let (mut re, mut im) = (0.0, 0.0);
        for a in 0..n { if w[a as usize] != 0 {
            let (c, s) = self.zeta(turn * a, n); re += w[a as usize] as f64 * c; im += w[a as usize] as f64 * s; } }
        (re, im)
    }
    fn sq_sum(&mut self, n: i64, skip0: bool) -> C {   // sum of zeta_n^(x^2), x = 0..n-1
        let mut w = vec![0i64; n as usize];
        for x in (if skip0 { 1 } else { 0 })..n { w[(x * x % n) as usize] += 1; } self.wsum(&w, n, 1)
    }
}
fn size(z: C) -> f64 { sqrt(z.0 * z.0 + z.1 * z.1) }
fn cmul(a: C, b: C) -> C { (a.0 * b.0 - a.1 * b.1, a.0 * b.1 + a.1 * b.0) }
fn zmul(u: &[i64], v: &[i64], n: usize) -> Vec<i64> {   // exact product in Z[zeta_n], mod x^n - 1
    let mut w = vec![0i64; n];
    for i in 0..n { if u[i] != 0 { for j in 0..n { w[(i + j) % n] += u[i] * v[j]; } } } w
}
fn as_int(w: &[i64]) -> Option<i64> {           // an integer iff coefficients 1..n-1 agree
    if w[1..].iter().all(|&x| x == w[1]) { Some(w[0] - w[1]) } else { None }
}
fn schur(q: i64) -> Vec<(i64, i64, i64, i64)> { // the one (a, b, c, d) allowed by trace, size, determinant
    let (ab, cd, ph) = ((q + 1) / 2, (q - 1) / 2, (q * (q - 1) / 2) % 4);
    let mut out = Vec::new();
    for s in [-1i64, 0, 1] { for t in [-1i64, 0, 1] {
        if s * s + t * t == 1 && (ab + s) % 2 == 0 && (cd + t) % 2 == 0 {
            let (a, b, c, d) = ((ab + s) / 2, (ab - s) / 2, (cd + t) / 2, (cd - t) / 2);
            if (2 * (b + d) + c + d) % 4 == ph { out.push((a, b, c, d)); }
        }
    } }
    out
}
fn main() {
    let mut z = Z { roots: HashMap::new() };
    let p = 7i64;
    let l: Vec<i64> = (0..p).map(|a| leg(a, p)).collect();
    let sg = |v: i64| if v > 0 { "+" } else { "-" };
    println!("Legendre symbol mod 7 by Euler's criterion, a = 1..6: {}", l[1..].iter().map(|&v| sg(v)).collect::<Vec<_>>().join(" "));
    println!("x^2 mod 7 for x = 0..6: {}", (0..p).map(|x| (x * x % p).to_string()).collect::<Vec<_>>().join(" "));
    for a in 1..p { println!("  a = {}  zeta_7^a = {}  weight {}1", a, cx(z.zeta(a, p)), sg(l[a as usize])); }
    let rw: Vec<i64> = l.iter().map(|&v| (v > 0) as i64).collect();
    let nw: Vec<i64> = l.iter().map(|&v| (v < 0) as i64).collect();
    let (r, n) = (z.wsum(&rw, p, 1), z.wsum(&nw, p, 1));
    let (g, g2, r7) = (z.wsum(&l, p, 1), z.sq_sum(p, false), sqrt(7.0));
    println!("sum over residues 1, 2, 4: {};  over non-residues 3, 5, 6: {}", cx(r), cx(n));
    println!("g = residues - non-residues: {};  as sum of zeta^(x^2): {}", cx(g), cx(g2));
    println!("sqrt 7 = {};  |g|^2 = {}", f(r7), f(g.0 * g.0 + g.1 * g.1));
    assert!(g.0.abs() < 1e-12 && (g.1 - r7).abs() < 1e-12 && (g2.1 - g.1).abs() < 1e-12);
    let lc: Vec<i64> = (0..p).map(|a| l[((p - a) % p) as usize]).collect();
    let (gg, ggc) = (as_int(&zmul(&l, &l, 7)).unwrap(), as_int(&zmul(&l, &lc, 7)).unwrap());
    println!("exact in Z[zeta_7]: g^2 = {};  g times conj g = {}", gg, ggc);
    let (mut ok, mut cnt) = (true, 0);
    for q in 3..200 { if isprime(q) {
        let lq: Vec<i64> = (0..q).map(|a| leg(a, q)).collect(); cnt += 1;
        ok = ok && as_int(&zmul(&lq, &lq, q as usize)) == Some(leg(q - 1, q) * q);
    } }
    println!("exact g^2 = (-1/p) p for all {} odd primes below 200: {}", cnt, yn(ok));
    assert!(ok && gg == -7);
    let x: Vec<C> = (0..p).map(|k| z.wsum(&l, p, k)).collect();   // Parseval road
    let ratio: Vec<i64> = x.iter().map(|v| (v.1 / g.1).round() as i64).collect();
    let js = |v: &[i64]| v.iter().map(|t| t.to_string()).collect::<Vec<_>>().join(" ");
    println!("transform X_k over g, k = 0..6: {};  (k/7): {}", js(&ratio), js(&l));
    let e_in: i64 = l.iter().map(|v| v * v).sum();
    let e_out = x.iter().map(|v| v.0 * v.0 + v.1 * v.1).sum::<f64>() / p as f64;
    println!("Parseval: sum (a/7)^2 = {};  (1/7) sum |X_k|^2 = {};  so |g|^2 = 7 x {} / {}", e_in, f(e_out), e_in, e_in);
    assert!(ratio == l && x.iter().all(|v| v.0.abs() < 1e-12) && (e_out - 6.0).abs() < 1e-9);
    let mut ind = HashMap::new();                // all six characters mod 7, from the primitive root 3
    for k in 0..6 { ind.insert(modpow(3, k, p), k); }
    for j in 0..6i64 {
        let (mut re, mut im) = (0.0, 0.0);
        for a in 1..p {
            let (c1, s1) = cs(2.0 * PI * (j * ind[&a]) as f64 / 6.0); let (c2, s2) = z.zeta(a, p);
            re += c1 * c2 - s1 * s2; im += c1 * s2 + s1 * c2;
        }
        println!("  chi_{} mod 7: g = {},  |g|^2 = {}", j, cx((re, im)), f(re * re + im * im));
        assert!((re * re + im * im - if j == 0 { 1.0 } else { 7.0 }).abs() < 1e-9);
    }
    let mut f2 = true;
    for j in 0..p { for m in 0..p {
        let mut s = (0.0, 0.0);
        for k in 0..p { let t = cmul(z.zeta(j * k, p), z.zeta(k * m, p)); s = (s.0 + t.0, s.1 + t.1); }
        let want = if (j + m) % p == 0 { p as f64 } else { 0.0 };
        f2 = f2 && ((s.0 - want).powi(2) + s.1 * s.1).sqrt() < 1e-9;
    } }
    let s7 = schur(7)[0];
    println!("Schur, mod 7: F^2 = 7 x reversal: {};  det phase i^21 = i;  (m1, m2, m3, m4) = ({}, {}, {}, {});  g = i sqrt 7", yn(f2), s7.0, s7.1, s7.2, s7.3);
    let (mut vok, mut vn) = (true, 0);
    for q in 3..50 { if isprime(q) {
        let mut w = (1.0, 0.0); vn += 1;
        for j in 0..q { for k in (j + 1)..q {
            let (a, b) = (z.zeta(k, q), z.zeta(j, q)); let d = (a.0 - b.0, a.1 - b.1);
            let m = (d.0 * d.0 + d.1 * d.1).sqrt(); w = cmul(w, (d.0 / m, d.1 / m));
        } }
        let want = [(1.0, 0.0), (0.0, 1.0), (-1.0, 0.0), (0.0, -1.0)][((q * (q - 1) / 2) % 4) as usize];
        vok = vok && ((w.0 - want.0).powi(2) + (w.1 - want.1).powi(2)).sqrt() < 1e-9;
    } }
    println!("Vandermonde det of F has phase i^(p(p-1)/2) for all {} odd primes below 50: {}", vn, yn(vok));
    assert!(f2 && vok && schur(7).len() == 1);
    let (mut n1, mut n3, mut ok) = (0, 0, true);
    for q in 3..10000 { if isprime(q) {
        let (a, b, c, d) = schur(q)[0]; let w = z.sq_sum(q, false); let rq = sqrt(q as f64);
        ok = ok && schur(q).len() == 1 && (w.0 - (a - b) as f64 * rq).abs() < 1e-9 && (w.1 - (c - d) as f64 * rq).abs() < 1e-9;
        if q % 4 == 1 { n1 += 1; } else { n3 += 1; }
    } }
    println!("odd primes below 10,000: {}; p = 1 mod 4: {}, p = 3 mod 4: {}; direct sum = Schur's sign every time: {}", n1 + n3, n1, n3, yn(ok));
    println!("mod 5: g = {};  sqrt 5 = {}", cx(z.sq_sum(5, false)), f(sqrt(5.0)));
    assert!(ok && n1 + n3 == 1228);
    let bad: Vec<(&str, C)> = vec![
        ("clockwise root e^(-2 pi i/7)", z.wsum(&l, p, -1)), ("root zeta_7^3, 3 a non-residue", z.wsum(&l, p, 3)),
        ("root zeta_7^2, 2 a residue", z.wsum(&l, p, 2)), ("drop x = 0 from sum of zeta^(x^2)", z.sq_sum(p, true)),
        ("trivial character mod 7", z.wsum(&[0, 1, 1, 1, 1, 1, 1], p, 1)), ("sum of zeta_6^(x^2), modulus 6", z.sq_sum(6, false)),
        ("sum of zeta_4^(x^2), modulus 4", z.sq_sum(4, false)),
        ("chi_2 mod 10, conductor 5", z.wsum(&[0, 1, 0, -1, 0, 0, 0, -1, 0, 1], 10, 1)),
        ("mod 8 lifted from mod 4", z.wsum(&[0, 1, 0, -1, 0, 1, 0, -1], 8, 1)),
        ("primitive (2/n) mod 8", z.wsum(&[0, 1, 0, -1, 0, -1, 0, 1], 8, 1))];
    for (name, v) in &bad { println!("  {:<36} {:>28}  size {}", name, cx(*v), f(size(*v))); }
    assert!((bad[0].1 .1 + r7).abs() < 1e-12 && (size(bad[3].1) - sqrt(8.0)).abs() < 1e-12 && size(bad[5].1) < 1e-9);
    assert!((size(bad[7].1) - sqrt(5.0)).abs() < 1e-9 && size(bad[8].1) < 1e-9 && (size(bad[9].1) - sqrt(8.0)).abs() < 1e-9);
    println!("sqrt 6 = {};  sqrt 8 = {};  sqrt 10 = {}", f(sqrt(6.0)), f(sqrt(8.0)), f(sqrt(10.0)));
    for q in [11i64, 13, 101] { println!("try: mod {}, g = {},  sqrt {} = {}", q, cx(z.sq_sum(q, false)), q, f(sqrt(q as f64))); }
    let (mut pts, mut w) = (vec![(0.0f64, 0.0f64)], (0.0, 0.0));
    for a in 1..p { let (c, s) = z.zeta(a, p); w = (w.0 + l[a as usize] as f64 * c, w.1 + l[a as usize] as f64 * s); pts.push(w); }
    println!("figure, walk {}", pts.iter().map(|(x, y)| format!("({:.3},{:.3})", x + 0.0, y + 0.0)).collect::<Vec<_>>().join(" "));
    println!("ALL CHECKS PASS");
}
