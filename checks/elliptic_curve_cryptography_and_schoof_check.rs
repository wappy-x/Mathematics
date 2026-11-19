// Curves for keys -- the same check as the Python, in Rust.  No crates; nothing
// counts points or adds them for us.  The toy curve is y^2 = x^3 + 2x + 4 over
// F_13, with 17 points; the house curve y^2 = x^3 - 2 is reduced mod 7, 13 and 41.
// P-256 is quoted from SEC 2 as sizes only.  Every toy curve here is insecure.
type Pt = Option<(i64, i64)>;

fn md(a: i64, m: i64) -> i64 { a.rem_euclid(m) }
fn pw(a: i64, mut e: i64, m: i64) -> i64 {          // a^e mod m by repeated squaring
    let (mut r, mut b) = (1, md(a, m));
    while e > 0 { if e & 1 == 1 { r = r * b % m } b = b * b % m; e >>= 1 }
    r
}
fn inv(a: i64, m: i64) -> i64 { pw(a, m - 2, m) }   // reciprocal mod a prime m, by Fermat
fn add(p1: Pt, p2: Pt, a: i64, p: i64) -> Pt {      // chord and tangent, coordinates mod p
    let ((x1, y1), (x2, y2)) = match (p1, p2) { (None, _) => return p2, (_, None) => return p1, (Some(u), Some(v)) => (u, v) };
    if x1 == x2 && md(y1 + y2, p) == 0 { return None }
    let m = if p1 == p2 { md((3 * x1 * x1 + a) * inv(2 * y1, p), p) } else { md((y2 - y1) * inv(x2 - x1, p), p) };
    let x3 = md(m * m - x1 - x2, p);
    Some((x3, md(m * (x1 - x3) - y1, p)))
}
fn mul(k: i64, pt: Pt, a: i64, p: i64) -> Pt {      // double-and-add, top bit first
    let mut r: Pt = None;
    for i in (0..64 - k.leading_zeros()).rev() { r = add(r, r, a, p); if (k >> i) & 1 == 1 { r = add(r, pt, a, p) } }
    r
}
fn rep(k: i64, pt: Pt, a: i64, p: i64) -> Pt {      // second road: add the point to itself k times
    let mut r: Pt = None;
    for _ in 0..k { r = add(r, pt, a, p) }
    r
}
fn points(a: i64, b: i64, p: i64) -> Vec<(i64, i64)> { // every pair (x, y) tried; O is not listed
    let mut v = Vec::new();
    for x in 0..p { for y in 0..p { if md(y * y - x * x * x - a * x - b, p) == 0 { v.push((x, y)) } } }
    v
}
fn count_euler(a: i64, b: i64, p: i64) -> i64 {     // O, plus 1 + (Euler's square test) for each x
    let mut n = 1;
    for x in 0..p { let e = pw(x * x * x + a * x + b, (p - 1) / 2, p); n += if e == 0 { 1 } else if e == 1 { 2 } else { 0 } }
    n
}
fn order(pt: Pt, a: i64, p: i64) -> i64 {
    let (mut k, mut r) = (1, pt);
    while r.is_some() { k += 1; r = add(r, pt, a, p) }
    k
}
fn pmod(u: &[i64], f: &[i64], p: i64) -> Vec<i64> {  // remainder of polynomial u by f, mod p, low degree first
    let mut u: Vec<i64> = u.iter().map(|&c| md(c, p)).collect();
    while u.last() == Some(&0) { u.pop(); }
    while u.len() >= f.len() {
        let (c, s) = (u[u.len() - 1] * inv(f[f.len() - 1], p) % p, u.len() - f.len());
        for (i, fi) in f.iter().enumerate() { u[s + i] = md(u[s + i] - c * fi, p) }
        while u.last() == Some(&0) { u.pop(); }
    }
    u
}
fn pmulmod(u: &[i64], v: &[i64], f: &[i64], p: i64) -> Vec<i64> {
    let mut w = vec![0; u.len() + v.len() - 1];
    for (i, ui) in u.iter().enumerate() { for (j, vj) in v.iter().enumerate() { w[i + j] += ui * vj } }
    pmod(&w, f, p)
}
fn two_step(a: i64, b: i64, p: i64) -> (Vec<i64>, usize) { // Schoof's l = 2 step: x^p mod f, then gcd(f, x^p - x)
    let f = vec![md(b, p), md(a, p), 0, 1];
    let (mut xp, mut sq, mut e) = (vec![1], vec![0, 1], p);
    while e > 0 { if e & 1 == 1 { xp = pmulmod(&xp, &sq, &f, p) } sq = pmulmod(&sq, &sq, &f, p); e >>= 1 }
    let mut xm = xp.clone(); while xm.len() < 2 { xm.push(0) } xm[1] -= 1;
    let (mut g, mut h) = (f.clone(), pmod(&xm, &f, p));
    while !h.is_empty() { let r = pmod(&g, &h, p); g = h; h = r }
    (xp, g.len() - 1)
}
fn is_prime(l: i64) -> bool { l > 1 && (2..l).all(|d| l % d != 0) }
fn emb_degree(q: i64, p: i64) -> Option<i64> {     // least k with q dividing p^k - 1; none if q = p
    if q == p { return None }
    let mut k = 1;
    while pw(p, k, q) != 1 { k += 1 }
    Some(k)
}
fn s(pt: Pt) -> String { match pt { Some((x, y)) => format!("({}, {})", x, y), None => "None".into() } }
fn tf(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn toy_hash(msg: &str) -> i64 {                     // a stated stand-in for SHA-256, NOT a real hash
    let mut h = 0;
    for c in msg.bytes() { h = (h * 31 + c as i64) % 65521 }
    h
}
const P: i64 = 13; const A: i64 = 2; const B: i64 = 4; const N: i64 = 17; const G: Pt = Some((0, 2));
fn verify(z: i64, r: i64, sg: i64, q: Pt) -> (bool, i64, i64, i64, Pt) {
    let w = inv(sg, N);
    let x = add(mul(z * w % N, G, A, P), mul(r * w % N, q, A, P), A, P);
    (matches!(x, Some((xx, _)) if xx % N == r), w, z * w % N, r * w % N, x)
}
fn main() {
    let (pts, ord_g, rt) = (points(A, B, P), order(G, A, P), 2.0 * (P as f64).sqrt());
    let in_window: Vec<i64> = (1..40).filter(|&m| m % ord_g == 0 && (P + 1) as f64 - rt <= m as f64 && m as f64 <= (P + 1) as f64 + rt).collect();
    println!("toy curve y^2 = x^3 + 2x + 4 over F_13; Hasse window 14 +/- {:.2}", rt);
    println!("count 1, every pair (x, y): {}", pts.len() + 1);
    println!("count 2, Euler's square test on 13 values of x: {}", count_euler(A, B, P));
    println!("count 3, order of G = {} is {}; multiples of it in the window: {:?}", s(G), ord_g, in_window);
    let (xp, deg) = two_step(A, B, P);
    let roots = (0..P).filter(|&x| md(x * x * x + A * x + B, P) == 0).count();
    let t = P + 1 - N;
    println!("Schoof l = 2: x^13 = {}x^2 + {}x + {} mod f; gcd(f, x^13 - x) has degree {}; roots by trial {}; a_p = 14 - 17 = {}, odd",
             xp[2], xp[1], xp[0], deg, roots, t);
    let (mut need, mut prod, mut l) = (Vec::new(), 1, 1);
    while prod as f64 <= 2.0 * rt { l += 1; if is_prime(l) { need.push(l); prod *= l } }
    let (mut bits, mut cnt, mut l2) = (0.0f64, 0, 1);
    while bits <= 130.0 { l2 += 1; if is_prime(l2) { bits += (l2 as f64).log2(); cnt += 1 } }
    println!("Schoof primes for p = 13: {:?}, product {} > 4 sqrt(p) = {:.2}", need, prod, 2.0 * rt);
    println!("Schoof primes for a 256-bit p: {} primes, 2 up to {}, product 2^{:.1} > 2^130", cnt, l2, bits);
    let (dp, dl) = (6, 9);                          // the phone's and the lock's secret numbers
    let (qp, ql) = (mul(dp, G, A, P), mul(dl, G, A, P));
    let (sp, sl) = (mul(dp, ql, A, P), mul(dl, qp, A, P));
    println!("ECDH: phone 6G = {}, lock 9G = {}; phone 6 QL = {}, lock 9 QP = {}", s(qp), s(ql), s(sp), s(sl));
    println!("6 x 9 = 54 = {} mod 17; 3G by repeated addition = {}", dp * dl % N, s(rep(dp * dl % N, G, A, P)));
    let da: Vec<String> = [1, 2, 3, 6].iter().map(|&k| format!("{}G {}", k, s(rep(k, G, A, P)))).collect();
    println!("double-and-add, 6 = 110 in binary: {}", da.join(", "));
    let tries = (1..N).find(|&k| rep(k, G, A, P) == qp).unwrap();
    println!("listener tries G, 2G, 3G, ...: phone's key found on try {} of at most 16", tries);
    let (ds, k) = (5, 8);                           // the maker's signing key, the one-time number
    let (qs, hz, rr) = (mul(ds, G, A, P), toy_hash("fw 1.4"), mul(k, G, A, P));
    let (z, r) = (hz % N, rr.unwrap().0 % N);
    let sg = inv(k, N) * (z + r * ds) % N;
    let (ok, w, u1, u2, x) = verify(z, r, sg, qs);
    let (z2, s13) = (toy_hash("fw 1.5") % N, inv(k, P) * (z + r * ds) % P);
    println!("ECDSA: QS = 5G = {}; toy hash of 'fw 1.4' = {}, z = {}; 8G = {}, r = {}, 1/8 = {}, s = {}", s(qs), hz, z, s(rr), r, inv(k, N), sg);
    println!("verify: 1/s = {}, u1 = {}, u2 = {}, u1 G + u2 QS = {}, valid {}", w, u1, u2, s(x), tf(ok));
    println!("same signature on 'fw 1.5' (z = {}): valid {}", z2, tf(verify(z2, r, sg, qs).0));
    println!("mistake, s worked mod 13 not 17: s = {}, valid {}", s13, tf(verify(z, r, s13, qs).0));
    println!("curve           points  cubic roots  largest prime  anomalous  embedding degree");
    let mut table = Vec::new();
    for (name, aa, bb, pp) in [("toy, mod 13", 2, 4, 13), ("house, mod 7", 0, -2, 7), ("house, mod 13", 0, -2, 13), ("house, mod 41", 0, -2, 41)] {
        let nn = points(aa, bb, pp).len() as i64 + 1;
        let q = (2..nn + 1).filter(|&d| nn % d == 0 && is_prime(d)).max().unwrap();
        let (kd, rts) = (emb_degree(q, pp), two_step(aa, bb, pp).1);
        let pj: Vec<i64> = (1..q).map(|j| (0..j).fold(1, |acc, _| acc * pp % q)).collect(); // second road: list p^j mod q
        table.push((nn, q, nn == pp, kd, rts, pj.iter().position(|&v| v == 1).map(|i| i as i64 + 1)));
        let ks = match kd { Some(v) => v.to_string(), None => "-".into() };
        println!("{:<15} {:>6}  {:>11}  {:>13}  {:>9}  {:>16}", name, nn, rts, q, if nn == pp { "yes" } else { "no" }, ks);
    }
    let g41: Pt = points(0, -2, 41).into_iter().map(Some).find(|&pt| order(pt, 0, 41) == 42).unwrap();
    let (d, mut trials, mut res) = (29, 0, Vec::new());
    let q41 = mul(d, g41, 0, 41);
    for q in [2, 3, 7] {                            // Pohlig-Hellman: solve in each small piece
        let (gq, qq, mut e) = (mul(42 / q, g41, 0, 41), mul(42 / q, q41, 0, 41), 0);
        while rep(e, gq, 0, 41) != qq { e += 1 }
        trials += e + 1; res.push(e);
    }
    let found = (0..42).find(|&x| vec![x % 2, x % 3, x % 7] == res).unwrap();
    println!("Pohlig-Hellman mod 41: G = {}, Q = {}G = {}; key mod 2, 3, 7 = {:?}; key {} in {} trials, against {} by trying G, 2G, ...",
             s(g41), d, s(q41), res, found, trials, d);
    println!("P-256 (SEC 2): p = 2^256 - 2^224 + 2^192 + 2^96 - 1, 256 bits; n prime, 256 bits; cofactor 1");
    for (nb, m) in [(224, 2048), (256, 3072), (384, 7680), (521, 15360)] {
        println!("n of {} bits: rho about 2^{:.1} steps; SP 800-57 modulus at that level {} bits",
                 nb, 0.5 * (nb as f64 + (std::f64::consts::PI / 4.0).log2()), m);
    }
    let fig: Vec<String> = pts.iter().map(|(x, y)| format!("({},{})", x, y)).collect();
    println!("figure, points {}; G {} QP {} QL {} S {}", fig.join(" "), s(G), s(qp), s(ql), s(sp));
    assert!(pts.len() as i64 + 1 == count_euler(A, B, P) && count_euler(A, B, P) == N && in_window == vec![N]);
    assert!(deg == roots && table.iter().all(|r| (r.4 > 0) == (r.0 % 2 == 0)));  // l = 2 step
    assert!(sp == sl && sl == rep(dp * dl % N, G, A, P) && qp == rep(dp, G, A, P));
    assert!(ok && x == rr && !verify(z2, r, sg, qs).0);     // ECDSA checks, tamper fails
    assert!(found == d && trials == [2, 3, 7].iter().map(|q| d % q + 1).sum::<i64>()); // Pohlig-Hellman, two roads
    assert!(table[1].2 && table[3].1 == 7);                                            // anomalous and smooth flags
    assert!(table.iter().all(|r| r.3 == r.5) && table[..4].iter().map(|r| r.3).collect::<Vec<_>>() == [Some(4), None, Some(18), Some(2)]);
    println!("ALL CHECKS PASS");
}
