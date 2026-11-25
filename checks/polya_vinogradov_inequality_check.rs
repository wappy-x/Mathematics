// Polya-Vinogradov: a character sum over any stretch is below sqrt(q) log q -- the same check as the
// Python, in Rust.  No crates.  Road 1 adds the Legendre symbol (n/1019) over every stretch by brute
// force.  Road 2 rebuilds the symbol from its Gauss sum (the finite Fourier expansion) and sums the
// stretch in closed form.  Road 3 walks the proof's chain of bounds.  Road 4 counts reduced quadratic
// forms to get the class number 13 another way.  Road 5 bounds the least non-residue mod 1009.
use std::f64::consts::{E, PI};
#[derive(Clone, Copy)]
struct C(f64, f64);
impl C {
    fn add(self, o: C) -> C { C(self.0 + o.0, self.1 + o.1) }
    fn sub(self, o: C) -> C { C(self.0 - o.0, self.1 - o.1) }
    fn scale(self, k: f64) -> C { C(self.0 * k, self.1 * k) }
    fn div(self, o: C) -> C { let d = o.0 * o.0 + o.1 * o.1; C((self.0 * o.0 + self.1 * o.1) / d, (self.1 * o.0 - self.0 * o.1) / d) }
    fn abs(self) -> f64 { (self.0 * self.0 + self.1 * self.1).sqrt() }
}
fn cis(t: f64) -> C { C(t.cos(), t.sin()) }
fn modpow(mut b: i64, mut e: i64, m: i64) -> i64 {
    let mut r = 1 % m; b %= m;
    while e > 0 { if e & 1 == 1 { r = r * b % m; } b = b * b % m; e >>= 1; } r
}
fn leg(a: i64, p: i64) -> i64 { let r = modpow(a, (p - 1) / 2, p); if r == 0 { 0 } else if r == 1 { 1 } else { -1 } }
fn isqrt(n: i64) -> i64 { let mut r = (n as f64).sqrt() as i64; while r * r > n { r -= 1; } while (r + 1) * (r + 1) <= n { r += 1; } r }
fn isprime(n: i64) -> bool { n > 1 && (2..=isqrt(n)).all(|d| n % d != 0) }
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a } else { gcd(b, a % b) } }
fn f(x: f64) -> String { format!("{:.9}", x + 0.0) }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn sg(v: i64) -> &'static str { if v > 0 { "+" } else { "-" } }
fn sums(p: i64) -> Vec<i64> {                    // partial sums S(0), S(1), ..., S(p - 1)
    let mut v = vec![0i64];
    for n in 1..p { let s = v[v.len() - 1] + leg(n, p); v.push(s); } v
}
fn imax(v: &[i64]) -> i64 { *v.iter().max().unwrap() }
fn imin(v: &[i64]) -> i64 { *v.iter().min().unwrap() }
fn pos(v: &[i64], x: i64) -> usize { v.iter().position(|&y| y == x).unwrap() }
fn classno(d: i64) -> i64 {                      // reduced forms ax^2 + bxy + cy^2 of discriminant d < 0
    let mut h = 0;
    for a in 1..=isqrt(-d / 3) { for b in (-a + 1)..=a {
        if (b * b - d) % (4 * a) == 0 {
            let c = (b * b - d) / (4 * a);
            if c >= a && !(b < 0 && a == c) && gcd(gcd(a, b.abs()), c) == 1 { h += 1; }
        }
    } }
    h
}
fn main() {
    let p = 1019i64; let s = sums(p); let bound = (p as f64).sqrt() * (p as f64).ln();
    let (top, low) = (imax(&s), imin(&s)); let (n_top, n_low) = (pos(&s, top) as i64, pos(&s, low) as i64);
    println!("p = {} = 8 x {} + {};  (n/{}) for n = 1..12: {}", p, p / 8, p % 8, p, (1..13).map(|n| sg(leg(n, p))).collect::<Vec<_>>().join(" "));
    println!("partial sums S(n): largest {} at n = {}, smallest {} at n = {};  S({}) = {}", top, n_top, low, n_low, p - 1, s[s.len() - 1]);
    let res = (1..=n_top).filter(|&n| leg(n, p) > 0).count() as i64;
    println!("n = 1..{}: {} residues, {} non-residues, difference {}", n_top, res, n_top - res, 2 * res - n_top);
    println!("largest stretch sum: {}, over n = {}..{} (M = {}, N = {})", top - low, n_low + 1, n_top, n_low, n_top - n_low);
    println!("bound sqrt({}) ln {} = {};  largest stretch / bound = {}", p, p, f(bound), f((top - low) as f64 / bound));
    assert!(top == 39 && n_top == 509 && top - low == 40 && s[s.len() - 1] == 0);

    // Road 2: the Fourier expansion through the Gauss sum g = sum (a/p) zeta^a
    let z: Vec<C> = (0..p).map(|k| cis(2.0 * PI * k as f64 / p as f64)).collect();
    let mut g = C(0.0, 0.0);
    for a in 1..p { g = g.add(z[a as usize].scale(leg(a, p) as f64)); }
    let mut err = 0.0f64;
    for n in 0..p {
        let mut t = C(0.0, 0.0);
        for a in 1..p { t = t.add(z[(a * n % p) as usize].scale(leg(a, p) as f64)); }
        err = err.max(t.div(g).sub(C(leg(n, p) as f64, 0.0)).abs());
    }
    println!("g = {} + {}i;  sqrt {} = {};  expansion rebuilds every (n/{}), worst error below 1e-9: {}", f(g.0), f(g.1), p, f((p as f64).sqrt()), p, yn(err < 1e-9));
    let geo = |a: i64, m: i64, n: i64| -> C {      // sum of zeta^(a n) for m < n <= m + N, closed form
        let t = PI * a as f64 / p as f64;
        cis(t * (2 * m + n + 1) as f64).scale((t * n as f64).sin() / t.sin())
    };
    let (mut u, mut v) = (C(0.0, 0.0), C(0.0, 0.0));
    for a in 1..p { u = u.add(geo(a, 0, n_top).scale(leg(a, p) as f64)); v = v.add(geo(a, n_low, n_top - n_low).scale(leg(a, p) as f64)); }
    let (four, four2) = (u.div(g), v.div(g));
    println!("S({}) through the expansion: {};  stretch {}..{}: {}", n_top, f(four.0), n_low + 1, n_top, f(four2.0));
    assert!(g.0.abs() < 1e-8 && (g.1 - (p as f64).sqrt()).abs() < 1e-8 && err < 1e-9 && four.sub(C(39.0, 0.0)).abs() < 1e-8 && four2.sub(C(40.0, 0.0)).abs() < 1e-8);

    // Road 3: the chain of bounds in the proof
    let csc: f64 = (1..p).map(|a| 1.0 / (PI * a as f64 / p as f64).sin()).sum();
    let h_: f64 = (1..=(p - 1) / 2).map(|a| 1.0 / a as f64).sum();
    let pf = p as f64;
    println!("sum of 1/sin(pi a/{}), a = 1..{}: {};  {} x H_{} = {};  {} ln {} = {}", p, p - 1, f(csc), p, (p - 1) / 2, f(pf * h_), p, p, f(pf * pf.ln()));
    println!("so |stretch| <= {} <= {} < {}", f(csc / pf.sqrt()), f(pf * h_ / pf.sqrt()), f(bound));
    assert!(((top - low) as f64) < csc / pf.sqrt() && csc / pf.sqrt() < pf * h_ / pf.sqrt() && pf * h_ / pf.sqrt() < bound);
    let mh = ((p - 1) / 2) as f64;                // H_m against Euler's expansion log m + gamma + 1/(2m) - 1/(12 m^2)
    assert!((h_ - (mh.ln() + 0.5772156649015329 + 1.0 / (2.0 * mh) - 1.0 / (12.0 * mh * mh))).abs() < 1e-9);
    let (mut worst, mut wp, mut cnt) = (0.0f64, 0, 0);
    for q in 3..3000 { if isprime(q) {
        let t = sums(q); let r = (imax(&t) - imin(&t)) as f64 / ((q as f64).sqrt() * (q as f64).ln()); cnt += 1;
        if r > worst { worst = r; wp = q; }
    } }
    println!("all {} odd primes below 3,000: largest stretch / (sqrt p ln p) is at most {}, at p = {}", cnt, f(worst), wp);
    assert!(worst < 1.0);
    let r0 = (2..p).find(|&r| [2i64, 509].iter().all(|&d| modpow(r, (p - 1) / d, p) != 1)).unwrap();
    let mut ind = vec![0i64; p as usize];
    for k in 0..p - 1 { ind[modpow(r0, k, p) as usize] = k; }
    let mut w = vec![C(0.0, 0.0)];
    for n in 1..p { let k = ind[n as usize]; let last = w[w.len() - 1]; w.push(last.add(cis(2.0 * PI * k as f64 / (p - 1) as f64))); }
    let mut best = 0.0f64;
    for i in 0..p as usize { for j in i + 1..p as usize { best = best.max(w[j].sub(w[i]).abs()); } }
    println!("complex character of order {} (chi({}) = zeta_{}): largest stretch {}", p - 1, r0, p - 1, f(best));
    assert!(best < bound);

    // Road 4: the 39 is three class numbers
    let h = classno(-p); let (mut ok, mut cnt) = (true, 0);
    for q in 7..2000 { if isprime(q) && q % 4 == 3 {
        cnt += 1; ok = ok && sums(q)[((q - 1) / 2) as usize] == (2 - leg(2, q)) * classno(-q);
    } }
    println!("class number of discriminant -{} by reduced forms: {};  3 x {} = {} = S({})", p, h, h, 3 * h, (p - 1) / 2);
    println!("S((p-1)/2) = (2 - (2/p)) h(-p) for all {} primes p = 3 mod 4 from 7 to 2,000: {}", cnt, yn(ok));
    assert!(h == 13 && 3 * h == top && ok);

    // Road 5: the least non-residue mod 1009
    let q = 1009i64; let bq = (q as f64).sqrt() * (q as f64).ln();
    let n_q = (2..q).find(|&n| leg(n, q) < 0).unwrap();
    println!("mod {}: (n/{}) for n = 2..{}: {};  least non-residue {}", q, q, n_q, (2..=n_q).map(|n| sg(leg(n, q))).collect::<Vec<_>>().join(" "), n_q);
    let mut big = vec![1i64; q as usize];        // largest prime factor of each n below q
    for d in 2..q as usize { if big[d] == 1 { let mut k = d; while k < q as usize { big[k] = d as i64; k += d; } } }
    let m = (2..q).find(|&m| (1..q).map(|nn| nn - 2 * (2..=nn).filter(|&n| big[n as usize] >= m).count() as i64).max().unwrap() as f64 >= bq).unwrap();
    println!("bounds on it: sqrt {} ln {} = {}, so direct Polya-Vinogradov {};  Vinogradov's trick {};  elementary sqrt {} + 1 = {};  true {}", q, q, f(bq), bq.floor() as i64 + 1, m - 1, q, f((q as f64).sqrt() + 1.0), n_q);
    println!("exponents of p: elementary 0.5;  Vinogradov 1/(2 sqrt e) = {};  Burgess 1/(4 sqrt e) = {}", f(1.0 / (2.0 * E.sqrt())), f(1.0 / (4.0 * E.sqrt())));
    assert!(n_q == 11 && m - 1 == 71 && n_q <= m - 1 && ((m - 1) as f64) < bq && (m - 1) as f64 > (q as f64).sqrt() + 1.0);

    // What breaks
    println!("break, principal character mod {}, n = 1..{}: {}, over the bound {}", p, p - 1, p - 1, f(bound));
    let sq: i64 = (1..=n_top).map(|n| leg(n * n, p)).sum();
    println!("break, (n^2/{}) over n = 1..{}, squares not a stretch: {}", p, n_top, sq);
    println!("break, forget to divide by |g|: {}, not {}", f(csc), f(csc / pf.sqrt()));
    let mut g8 = C(0.0, 0.0);
    for (a, c) in [0i64, 1, 0, -1, 0, 1, 0, -1].iter().enumerate() { g8 = g8.add(cis(PI * a as f64 / 4.0).scale(*c as f64)); }
    println!("break, character mod 8 lifted from mod 4: g = {}, so the expansion divides by 0", f(g8.abs()));
    assert!((p - 1) as f64 > bound && sq == n_top && g8.abs() < 1e-12);

    for q in [1031i64, 100003] {
        let t = sums(q); let (mx, mn) = (imax(&t), imin(&t));
        println!("try: p = {} = {} mod 8: largest S = {} at n = {}, S({}) = {}, stretch {}, bound {}, h(-p) = {}, least non-residue {}", q, q % 8, mx, pos(&t, mx), (q - 1) / 2, t[((q - 1) / 2) as usize], mx - mn, f((q as f64).sqrt() * (q as f64).ln()), classno(-q), (2..q).find(|&n| leg(n, q) < 0).unwrap());
    }
    println!("chart, n: {}", (0..31).map(|k| (k * (p - 1) / 30).to_string()).collect::<Vec<_>>().join(" "));
    println!("chart, S: {}", (0..31).map(|k| s[(k * (p - 1) / 30) as usize].to_string()).collect::<Vec<_>>().join(" "));
    println!("ALL CHECKS PASS");
}
