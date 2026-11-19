// Birch-Swinnerton-Dyer and the congruent number problem -- the same check as the Python, in Rust.
// No crates.  A small exact-fraction struct stands in for Fraction; every point count, L-value,
// period and Tunnell count is computed here.  E_n is the curve y^2 = x^3 - n^2 x.
use std::collections::HashMap;
use std::f64::consts::PI;
#[derive(Clone, Copy, PartialEq, Debug)]
struct Q { n: i128, d: i128 }
fn g(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { g(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let k = g(n, d) * d.signum(); Q { n: n / k, d: d / k } }
fn add(a: Q, b: Q) -> Q { q(a.n.checked_mul(b.d).unwrap().checked_add(b.n.checked_mul(a.d).unwrap()).unwrap(), a.d.checked_mul(b.d).unwrap()) }
fn sub(a: Q, b: Q) -> Q { add(a, Q { n: -b.n, d: b.d }) }
fn mul(a: Q, b: Q) -> Q { q(a.n.checked_mul(b.n).unwrap(), a.d.checked_mul(b.d).unwrap()) }
fn div(a: Q, b: Q) -> Q { q(a.n.checked_mul(b.d).unwrap(), a.d.checked_mul(b.n).unwrap()) }
fn w(k: i128) -> Q { Q { n: k, d: 1 } }
fn isq(v: i128) -> i128 { let mut r = (v as f64).sqrt() as i128; while r * r > v { r -= 1 } while (r + 1) * (r + 1) <= v { r += 1 } r }
fn root(r: Q) -> Q { q(isq(r.n), isq(r.d)) }
fn show(r: Q) -> String { if r.d == 1 { format!("{}", r.n) } else { format!("{}/{}", r.n, r.d) } }
fn on(n: i128, x: Q, y: Q) -> bool { mul(y, y) == sub(mul(mul(x, x), x), mul(w(n * n), x)) }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn mpow(mut b: u64, mut e: u64, m: u64) -> u64 { let mut r = 1; b %= m; while e > 0 { if e & 1 == 1 { r = r * b % m } b = b * b % m; e >>= 1 } r }
fn leg(v: i64, p: i64) -> i64 { let v = v.rem_euclid(p); if v == 0 { 0 } else if mpow(v as u64, (p as u64 - 1) / 2, p as u64) == 1 { 1 } else { -1 } }
fn fact(k: i32) -> f64 { if k < 2 { 1.0 } else { k as f64 * fact(k - 1) } }
fn e1(z: f64) -> f64 {
    if z < 1.0 { return -0.5772156649015329 - z.ln() - (1..40).map(|k| (-z).powf(k as f64) / (k as f64 * fact(k))).sum::<f64>() }
    let (mut bb, mut cc, mut dd) = (z + 1.0, 1e300, 1.0 / (z + 1.0)); let mut hh = dd;
    for i in 1..200 { let an = -((i * i) as f64); bb += 2.0; dd = 1.0 / (an * dd + bb); cc = bb + an / cc; hh *= cc * dd }
    hh * (-z).exp()
}
struct Ctx { p: Vec<i64>, a1: HashMap<i64, i64> }
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
    fn lvals(&self, n: i64) -> (i64, f64, f64, f64, f64) {
        let mm = 2000; let nn = if n % 2 == 1 { 32 * n * n } else { 16 * n * n }; let nf = nn as f64;
        let am = self.coeffs(n, mm);
        let f = |t: f64| (1..=mm).map(|k| am[k] as f64 * (-2.0 * PI * k as f64 * t).exp()).sum::<f64>();
        let t = 1.2 / nf.sqrt(); let wv = f(1.0 / (nf * t)) / (nf * t * t * f(t));
        let l = 2.0 * (1..=mm).map(|k| am[k] as f64 / k as f64 * (-2.0 * PI * k as f64 / nf.sqrt()).exp()).sum::<f64>();
        let dl = 2.0 * (1..=mm).map(|k| am[k] as f64 / k as f64 * e1(2.0 * PI * k as f64 / nf.sqrt())).sum::<f64>();
        (nn, wv, if wv > 0.0 { l } else { 0.0 }, if wv < 0.0 { dl } else { 0.0 }, l)
    }
}
fn tunnell(n: i64) -> (i64, i64) {
    let (k, qq) = if n % 2 == 1 { (n, 2) } else { (n / 2, 4) };
    let r = (k as f64).sqrt() as i64 + 1;
    let cnt = |c: i64| { let mut s = 0; for u in -r..=r { for v in -r..=r { for z in -r..=r { if qq * u * u + v * v + c * z * z == k { s += 1 } } } } s };
    (cnt(8), cnt(32))
}
fn main() {
    // Road 1: the 3-4-5 triangle gives three squares spaced 6 apart, and so a point on E_6
    let x = q(25, 4); let six = w(6);
    println!("triangle 3, 4, 5: area 6; x - 6, x, x + 6 = {}, {}, {}", show(sub(x, six)), show(x), show(add(x, six)));
    let prod = mul(mul(sub(x, six), x), add(x, six));
    println!("roots: {}, {}, {}; product {} = y^2", show(root(sub(x, six))), show(root(x)), show(root(add(x, six))), show(prod));
    let y = root(prod);
    println!("point P = ({}, {}) on y^2 = x^3 - 36x: {}; not whole, so infinite order", show(x), show(y), yn(on(6, x, y)));
    assert!(x == q(25, 4) && y == q(35, 8) && on(6, x, y) && y.d > 1);
    let m = div(sub(mul(w(3), mul(x, x)), w(36)), mul(w(2), y));
    let x2 = sub(mul(m, m), mul(w(2), x)); let y2 = sub(mul(m, sub(x, x2)), y);
    let (h, s, d) = (root(x2), root(add(x2, six)), root(sub(x2, six)));
    let area = div(mul(sub(s, d), add(s, d)), w(2));
    println!("2P = ({}, {}); triangle back: legs {}, {}, long side {}, area {}", show(x2), show(y2), show(sub(s, d)), show(add(s, d)), show(mul(w(2), h)), show(area));
    let (l1, l2, hy) = (sub(s, d), add(s, d), mul(w(2), h));
    assert!(on(6, x2, y2) && add(mul(l1, l1), mul(l2, l2)) == mul(hy, hy) && area == six);
    // Road 2: count points mod p by brute force, and by the twist rule a_p(E_n) = (n/p) a_p(E_1)
    let xm = 10000usize; let mut sieve = vec![true; xm + 1];
    for i in 2..101 { if sieve[i] { let mut j = i * i; while j <= xm { sieve[j] = false; j += i } } }
    let p: Vec<i64> = (3..=xm).filter(|&i| sieve[i]).map(|i| i as i64).collect();
    let a1: HashMap<i64, i64> = p.iter().map(|&pp| (pp, -(0..pp).map(|t| leg(t * t * t - t, pp)).sum::<i64>())).collect();
    let cx = Ctx { p: p.clone(), a1 };
    let mut rows = vec![];
    for &pp in &[5i64, 7, 11, 13, 17, 19, 23, 29, 31, 37] {
        let mut np = 1; for u in 0..pp { for v in 0..pp { if (v * v - u * u * u + 36 * u).rem_euclid(pp) == 0 { np += 1 } } }
        rows.push(format!("{}:{}/{}", pp, np, pp + 1 - np));
        assert!(pp + 1 - np == cx.ap(6, pp) && (pp + 1 - np).pow(2) <= 4 * pp && (pp % 4 == 1 || np == pp + 1));
    }
    println!("E_6 mod p, p:N_p/a_p (brute force = twist rule; Hasse |a_p| <= 2 sqrt p holds): {}", rows.join(", "));
    // Road 3: the Euler product prod N_p/p that Birch and Swinnerton-Dyer watched grow
    let mut end1 = 0.0f64;                               // E_1's product at 10000
    for &n in &[1i64, 6, 34] {
        let (mut pr, mut out, mut marks) = (1.0f64, vec![], vec![100i64, 300, 1000, 3000, 10000]);
        for &pp in &p {
            if n % pp == 0 { continue }
            while !marks.is_empty() && pp > marks[0] { out.push(format!("{:.2}", pr)); marks.remove(0); }
            pr *= (pp + 1 - cx.ap(n, pp)) as f64 / pp as f64;
        }
        out.push(format!("{:.2}", pr));
        println!("chart n = {}: prod N_p/p for p up to 100, 300, 1000, 3000, 10000: {}", n, out.join(", "));
        if n == 1 { end1 = pr }
    }
    // Road 4: the L-function at s = 1, and the period of E_1 two ways
    let (mut u, mut v) = (1.0f64, 2f64.sqrt()); for _ in 0..30 { let t = (u + v) / 2.0; v = (u * v).sqrt(); u = t }
    let om = PI / u; let kk = 2000;
    let om2 = 2.0 * (PI / 2.0 / kk as f64 / 3.0) * (0..=kk).map(|j| (if j == 0 || j == kk { 1.0 } else if j % 2 == 1 { 4.0 } else { 2.0 }) / (1.0 + (j as f64 * PI / 2.0 / kk as f64).sin().powi(2)).sqrt()).sum::<f64>();
    println!("period of y^2 = x^3 - x: by AGM {:.12}, by Simpson {:.12}; doubled over sqrt 6, for E_6: {:.12}", om, om2, 2.0 * om / 6f64.sqrt());
    assert!((om - om2).abs() < 1e-12);
    let l1 = cx.lvals(1).2;                              // rank 0: Goldfeld's limit, if the product converges at s = 1
    println!("n = 1: sqrt 2 / L(E_1, 1) = {:.4}, 1 / L(E_1, 1) = {:.4}; chart ends at {:.2}", 2f64.sqrt() / l1, 1.0 / l1, end1);
    assert!((end1 - 2f64.sqrt() / l1).abs() < (end1 - 1.0 / l1).abs());
    // Road 5: Tunnell's counts, against the L-value and against triangles from Pythagorean seeds
    let mut sf: Vec<i64> = (0..1201).collect();
    for dd in 2..35i64 { let mut k = dd * dd; while k < 1201 { while sf[k as usize] % (dd * dd) == 0 { sf[k as usize] /= dd * dd } k += dd * dd } }
    let mut seeds: HashMap<i64, (i64, i64)> = HashMap::new();
    for mm in 2..401i64 { for kq in 1..mm { if (mm - kq) % 2 == 1 && g(mm as i128, kq as i128) == 1 {
        seeds.entry(sf[mm as usize] * sf[kq as usize] * sf[(mm - kq) as usize] * sf[(mm + kq) as usize]).or_insert((mm, kq));
    } } }
    println!("n | n mod 8 | counts | sign | L(E_n, 1) | scaled L | verdict | witness");
    for n in (1..24i64).filter(|k| (2..7).all(|j| k % (j * j) != 0)) {
        let (a, b) = tunnell(n); let (_, wv, l, _, _) = cx.lvals(n);
        let scaled = (if n % 2 == 1 { 16.0 } else { 8.0 }) * (n as f64).sqrt() * l / om;
        let wit = match seeds.get(&n) { Some(&(s1, s2)) => format!("seeds ({}, {})", s1, s2), None => (if n == 23 { "23 triangle below" } else { "-" }).to_string() };
        println!("{:2} | {} | {}, {} | {} | {:.10} | {:.6} | {} | {}", n, n % 8, a, b, if wv > 0.0 { "+" } else { "-" }, l, scaled,
                 if a == 2 * b { "congruent" } else { "not congruent" }, wit);
        assert!((wv.abs() - 1.0).abs() < 1e-9 && (scaled - ((a - 2 * b) * (a - 2 * b)) as f64).abs() < 1e-6);
        assert!((a == 2 * b) == (wv < 0.0) && (wv < 0.0) == (seeds.contains_key(&n) || n == 23));
    }
    let (a23, b23, c23, dd) = (80155i128 * 3485, 41496i128 * 20748, 905141617i128, 72306780i128);
    println!("23 triangle: 80155/20748, 41496/3485, {}/{}; Pythagoras {}; area {}", c23, dd, yn(a23 * a23 + b23 * b23 == c23 * c23), show(q(80155 * 41496, 2 * 20748 * 3485)));
    assert!(a23 * a23 + b23 * b23 == c23 * c23 && 80155i128 * 41496 == 46 * 20748 * 3485);
    let (nn, wv, _, dl, wrong) = cx.lvals(6);
    println!("E_6: conductor {}, sign {:+.9}, L(E_6, 1) = 0 forced, L'(E_6, 1) = {:.10}: analytic rank 1", nn, wv, dl);
    assert!(wv < 0.0 && dl > 0.5);
    let (per, reg) = (2.140901028075231f64, 0.888625874839619f64);      // quoted from the LMFDB table, curve 576.c3
    let strong = per * reg * 16.0 / 4f64.powi(2);
    println!("strong form, table's period {}, regulator {}, Tamagawa factor 16, analytic Sha 1, torsion 4: {:.10}", per, reg, strong);
    assert!((strong - dl).abs() < 1e-9 && (2.0 * om / 6f64.sqrt() - per).abs() < 1e-12);   // the quoted period, recomputed
    // What breaks
    println!("sign forgotten for n = 6: the + formula gives {:.10}, not 0", wrong);
    let (_, w34, l34, _, _) = cx.lvals(34);
    println!("n = 34 is 2 mod 8, yet sign {:+.0}, L(E_34, 1) = {:.10}, counts {:?}, point (-16, 120) on E_34: {}", w34, l34.abs(), tunnell(34), yn(on(34, w(-16), w(120))));
    println!("n = 24, not square-free: counts {:?} say 'not congruent', yet 6, 8, 10 has area 24", tunnell(24));
    assert!(l34.abs() < 1e-9 && w34 > 0.0 && tunnell(24) == (8, 0) && (wrong - 1.2893431325).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
