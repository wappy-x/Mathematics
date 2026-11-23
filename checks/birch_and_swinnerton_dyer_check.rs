// Birch and Swinnerton-Dyer, the Millennium problem -- the same check as the Python, in Rust.  No crates.
// E_n is the curve y^2 = x^3 - n^2 x; n is congruent exactly when E_n has rank at least 1.  The card's
// curve is E_5.  A small exact-fraction struct stands in for Fraction; L-values are summed here.
use std::collections::HashMap;
use std::f64::consts::PI;
#[derive(Clone, Copy, PartialEq)]
struct Q { n: i128, d: i128 }
fn g(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { g(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let k = g(n, d) * d.signum(); Q { n: n / k, d: d / k } }
fn add(a: Q, b: Q) -> Q { q(a.n.checked_mul(b.d).unwrap() + b.n.checked_mul(a.d).unwrap(), a.d.checked_mul(b.d).unwrap()) }
fn sub(a: Q, b: Q) -> Q { add(a, Q { n: -b.n, d: b.d }) }
fn mul(a: Q, b: Q) -> Q { q(a.n.checked_mul(b.n).unwrap(), a.d.checked_mul(b.d).unwrap()) }
fn div(a: Q, b: Q) -> Q { q(a.n.checked_mul(b.d).unwrap(), a.d.checked_mul(b.n).unwrap()) }
fn w(k: i128) -> Q { Q { n: k, d: 1 } }
fn ab(a: Q) -> Q { Q { n: a.n.abs(), d: a.d } }
fn fl(a: Q) -> f64 { a.n as f64 / a.d as f64 }
fn sh(r: Q) -> String { if r.d == 1 { format!("{}", r.n) } else { format!("{}/{}", r.n, r.d) } }
fn on(n: i128, x: Q, y: Q) -> bool { mul(y, y) == sub(mul(mul(x, x), x), mul(w(n * n), x)) }
fn tri(n: i128, x: Q, y: Q) -> (Q, Q, Q) {
    (div(sub(mul(x, x), w(n * n)), y), div(mul(w(2 * n), x), y), div(add(mul(x, x), w(n * n)), y))
}
fn dbl(n: i128, x: Q, y: Q) -> (Q, Q, Q) {
    let m = div(sub(mul(w(3), mul(x, x)), w(n * n)), mul(w(2), y)); let x2 = sub(mul(m, m), mul(w(2), x));
    (m, x2, sub(mul(m, sub(x, x2)), y))
}
fn mpow(mut b: u64, mut e: u64, m: u64) -> u64 { let mut r = 1; b %= m; while e > 0 { if e & 1 == 1 { r = r * b % m } b = b * b % m; e >>= 1 } r }
fn leg(v: i64, p: i64) -> i64 { let v = v.rem_euclid(p); if v == 0 { 0 } else if mpow(v as u64, (p as u64 - 1) / 2, p as u64) == 1 { 1 } else { -1 } }
fn e1(z: f64, fac: &[f64]) -> f64 {
    if z < 1.0 { return -0.5772156649015329 - z.ln() - (1..40).map(|k| (-z).powi(k as i32) / (k as f64 * fac[k])).sum::<f64>() }
    let (mut bb, mut cc, mut dd) = (z + 1.0, 1e300, 1.0 / (z + 1.0)); let mut hh = dd;
    for i in 1..200 { let an = -((i * i) as f64); bb += 2.0; dd = 1.0 / (an * dd + bb); cc = bb + an / cc; hh *= cc * dd }
    hh * (-z).exp()
}
struct Ctx { p: Vec<i64>, a1: HashMap<i64, i64>, fac: Vec<f64> }
struct Lf { nn: i64, w: f64, lp: f64, dl: f64, am: Vec<i64> }
fn fsum(am: &[i64], y: f64) -> f64 { (1..am.len()).map(|k| am[k] as f64 * (-2.0 * PI * k as f64 * y).exp()).sum() }
impl Ctx {
    fn ap(&self, n: i64, p: i64) -> i64 { if n % p == 0 { 0 } else { leg(n, p) * self.a1[&p] } }
    fn coeffs(&self, n: i64, m: usize) -> Vec<i64> {
        let mut am = vec![0i64; m + 1]; am[1] = 1;
        for k in 2..=m as i64 {
            let p = *std::iter::once(&2).chain(self.p.iter()).find(|&&q| k % q == 0).unwrap();
            let (mut e, mut r) = (0, k); while r % p == 0 { r /= p; e += 1 }
            let bad = (2 * n) % p == 0;
            let mut pk = vec![1, if bad { 0 } else { self.ap(n, p) }];
            for _ in 0..e - 1 { let l = pk.len(); pk.push(pk[l - 1] * pk[1] - (if bad { 0 } else { p }) * pk[l - 2]) }
            am[k as usize] = pk[e] * am[r as usize];
        }
        am
    }
    fn lfun(&self, n: i64) -> Lf {
        let nn = if n % 2 == 1 { 32 * n * n } else { 16 * n * n }; let nf = nn as f64; let sn = nf.sqrt();
        let m = (6.0 * sn) as usize + 20; let am = self.coeffs(n, m);
        let t = 1.1 / sn; let wv = fsum(&am, 1.0 / (nf * t)) / (nf * t * t * fsum(&am, t));
        let lp = 2.0 * (1..=m).map(|k| am[k] as f64 / k as f64 * (-2.0 * PI * k as f64 / sn).exp()).sum::<f64>();
        let dl = 2.0 * (1..=m).map(|k| am[k] as f64 / k as f64 * e1(2.0 * PI * k as f64 / sn, &self.fac)).sum::<f64>();
        Lf { nn, w: wv, lp, dl, am }
    }
}
fn tunnell(n: i64) -> (i64, i64) {
    let (k, qq) = if n % 2 == 1 { (n, 2) } else { (n / 2, 4) };
    let r = (k as f64).sqrt() as i64 + 1;
    let cnt = |c: i64| { let mut s = 0; for u in -r..=r { for v in -r..=r { for z in -r..=r { if qq * u * u + v * v + c * z * z == k { s += 1 } } } } s };
    (cnt(8), cnt(32))
}
fn gi(a: i64, b: i64) -> i64 { if b == 0 { a } else { gi(b, a % b) } }
fn sfree(mut k: i64) -> i64 {
    let (mut s, mut d) = (1, 2);
    while d * d <= k { while k % (d * d) == 0 { k /= d * d } if k % d == 0 { s *= d; k /= d } d += 1 }
    s * k
}
fn join(v: &[i64]) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(" ") }
fn main() {
    // Road 1: Fibonacci's number 5, a point, a triangle, and a second point that proves infinite order
    let (a, b, c) = (q(3, 2), q(20, 3), q(41, 6));
    println!("triangle {}, {}, {}: a^2 + b^2 = {}, c^2 = {}, area {}", sh(a), sh(b), sh(c), sh(add(mul(a, a), mul(b, b))), sh(mul(c, c)), sh(div(mul(a, b), w(2))));
    let (gx, gy) = (w(-4), w(6));
    println!("G = (-4, 6) on y^2 = x^3 - 25x: {} (36 = -64 + 100)", if on(5, gx, gy) { "yes" } else { "no" });
    let t = tri(5, gx, gy);
    println!("triangle from G: {}, {}, {}", sh(t.0), sh(t.1), sh(t.2));
    assert!(add(mul(a, a), mul(b, b)) == mul(c, c) && div(mul(a, b), w(2)) == w(5) && on(5, gx, gy) && (ab(t.0), ab(t.1), ab(t.2)) == (a, b, c));
    let tor = [(w(0), w(0)), (w(5), w(0)), (w(-5), w(0))]; let tok = tor.iter().all(|&(x, y)| on(5, x, y));
    println!("torsion points O, (0, 0), (5, 0), (-5, 0) on the curve: {}; 4 in all, no triangle (y = 0)", if tok { "yes" } else { "no" });
    assert!(tok && !on(5, w(4), w(0)));
    let (m, x2, y2) = dbl(5, gx, gy);
    let t2 = tri(5, x2, y2);
    println!("tangent slope at G {}; 2G = ({}, {}); whole numbers: {}", sh(m), sh(x2), sh(y2), if x2.d == 1 { "yes" } else { "no" });
    let ar2 = div(ab(mul(t2.0, t2.1)), w(2));
    println!("triangle from 2G: {}, {}, {}; area {}", sh(ab(t2.0)), sh(ab(t2.1)), sh(ab(t2.2)), sh(ar2));
    assert!(on(5, x2, y2) && x2.d > 1 && add(mul(t2.0, t2.0), mul(t2.1, t2.1)) == mul(t2.2, t2.2) && ar2 == w(5));
    println!("figure,G,-4,6,2G,{:.4},{:.4},-2G,{:.4},{:.4},slope,{:.4}", fl(x2), fl(y2), fl(x2), -fl(y2), fl(m));

    // Road 2: count E_5 mod p by brute force, and by the twist rule a_p(E_n) = (n/p) a_p(E_1)
    let x = 6000usize; let mut sv = vec![true; x + 1];
    for i in 2..80 { if sv[i] { let mut j = i * i; while j <= x { sv[j] = false; j += i } } }
    let p: Vec<i64> = (3..=x).filter(|&k| sv[k]).map(|k| k as i64).collect();
    let mut a1 = HashMap::new();
    for &pp in &p { a1.insert(pp, -(0..pp).map(|u| leg(u * u * u - u, pp)).sum::<i64>()); }
    let mut fac = vec![1.0f64]; for k in 1..41 { let l = fac[k - 1]; fac.push(l * k as f64) }
    let cx = Ctx { p, a1, fac };
    let mut rows = vec![];
    for &pp in &[3i64, 7, 11, 13, 17, 19, 23, 29] {
        let mut np = 1; for u in 0..pp { for v in 0..pp { if (v * v - u * u * u + 25 * u).rem_euclid(pp) == 0 { np += 1 } } }
        rows.push(format!("{}:{}/{}", pp, np, pp + 1 - np));
        assert!(pp + 1 - np == cx.ap(5, pp) && (pp + 1 - np) * (pp + 1 - np) <= 4 * pp);
    }
    println!("E_5 mod p, p:N_p/a_p (brute force = twist rule, Hasse holds): {}", rows.join(", "));

    // Road 3: the L-function at s = 1 from the a_k: its sign, its value, its slope (two ways)
    let l5 = cx.lfun(5); let (aa, bb) = tunnell(5);
    println!("E_5: conductor {}, sign w = {:+.9}; Tunnell counts {}, {}, so L(E_5, 1) = 0 exactly", l5.nn, l5.w, aa, bb);
    let (kk, y0) = (3000usize, 1.0 / (l5.nn as f64).sqrt()); let u = (8.0 / y0).ln(); let h = u / kk as f64;
    let quad = 4.0 * PI * (h / 3.0) * (0..=kk).map(|j| {
        let wt = if j == 0 || j == kk { 1.0 } else if j % 2 == 1 { 4.0 } else { 2.0 };
        let jf = j as f64; wt * fsum(&l5.am, y0 * (jf * h).exp()) * jf * h * y0 * (jf * h).exp()
    }).sum::<f64>();
    println!("L'(E_5, 1) by the E1 series {:.12}, by the integral {:.12}: not 0, analytic rank 1", l5.dl, quad);
    assert!(((l5.w).abs() - 1.0).abs() < 1e-9 && l5.w < 0.0 && aa == 2 * bb && (l5.dl - quad).abs() < 1e-10 && l5.dl > 0.5);

    // Road 4: the status of every square-free n up to 100, by the proved theorems; triangles from seeds up to 400
    let sf: Vec<i64> = (0..=800).map(|k| if k == 0 { 0 } else { sfree(k) }).collect();
    let mut seeds: HashMap<i64, (i64, i64)> = HashMap::new();
    for mm in 2..401i64 { for kq in 1..mm {
        if (mm - kq) % 2 == 1 && gi(mm, kq) == 1 {
            let mut s = 1; for v in [mm, kq, mm - kq, mm + kq] { let gg = gi(s, sf[v as usize]); s = s * sf[v as usize] / (gg * gg) }
            seeds.entry(s).or_insert((mm, kq));
        }
    } }
    let names = ["rank 0, proved", "rank 1, proved", "order 2 or more, no general theorem"];
    let mut cls: Vec<Vec<i64>> = vec![vec![], vec![], vec![]];
    for n in (1..101i64).filter(|&k| sf[k as usize] == k) {
        let (a, b) = tunnell(n);
        if a != 2 * b { cls[0].push(n); continue }
        let l = cx.lfun(n);
        assert!((l.w.abs() - 1.0).abs() < 1e-9 && ((l.w < 0.0) == [5, 6, 7].contains(&(n % 8))));
        if l.w < 0.0 && l.dl.abs() > 0.01 { cls[1].push(n) } else { cls[2].push(n) }
    }
    let count = (1..101i64).filter(|k| (2..11).all(|d| k % (d * d) != 0)).count();
    println!("square-free n from 1 to 100: {}", count);
    for i in 0..3 { println!("{}: {} numbers: {}", names[i], cls[i].len(), join(&cls[i])) }
    let miss: Vec<i64> = cls[1].iter().chain(cls[2].iter()).cloned().filter(|n| !seeds.contains_key(n)).collect();
    println!("L(E_n, 1) = 0 but no triangle from seeds up to 400: {} numbers: {}", miss.len(), join(&miss));
    assert!(cls[0].iter().all(|n| !seeds.contains_key(n)));
    assert!(miss.iter().all(|n| cls[1].contains(n)) && cls.iter().map(|v| v.len()).sum::<usize>() == count && count == 61);
    println!("seeds for 5: {:?}, for 41: {:?}, for 65: {:?}", seeds[&5], seeds[&41], seeds[&65]);

    // What breaks
    let l = cx.lfun(157);
    println!("157: seeds up to 400 give a triangle: {}; sign {:+.0}, L'(E_157, 1) = {:.10}", if seeds.contains_key(&157) { "yes" } else { "no" }, l.w, l.dl);
    assert!(!seeds.contains_key(&157) && l.w < 0.0 && l.dl > 0.5);
    println!("sign forgotten for n = 5: the w = +1 formula gives {:.10}, not 0", l5.lp);
    let t41 = tunnell(41);
    println!("41 = 1 mod 8, sign +1, counts {:?}: L(E_41, 1) = 0, yet seeds {:?} give a triangle", t41, seeds[&41]);
    assert!(t41.0 == 2 * t41.1 && cx.lfun(41).w > 0.0);
    println!("ALL CHECKS PASS");
}
