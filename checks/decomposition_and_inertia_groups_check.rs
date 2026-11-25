// Decomposition and inertia groups -- the same check as the Python, in Rust.  No
// crates.  L is the splitting field of x^3 - 2: a^3 = 2, w^2 + w + 1 = 0; the
// symmetry (s, t) sends a to w^s a and w to w^t, so root r_j = w^j a goes to
// r_(tj+s).  Road 1 factors subfield polynomials mod p and uses efg = n.  Road 2
// never factors: it builds GF(p^k), lists the points (a, b), and reads D and I
// off how the symmetries move one point.  The house field H = Q(sqrt-5, i) too.
type E = Vec<i64>; type Pt = (E, E); type G = (i64, i64);
struct Field { n: usize, px: Vec<i64>, py: Vec<i64>, subs: Vec<Vec<i64>>, g: Vec<G>, phi: bool }
struct R2 { k: u32, npts: usize, e: usize, f: usize, g: usize, d: Vec<G>, i: Vec<G>, ok: bool, frob: Vec<G>, all_d: Vec<Vec<G>> }

fn mul(u: &E, v: &E, p: i64, m: &E) -> E {            // product in GF(p^k) = GF(p)[z]/(m)
    let (k, mut r) = (m.len() - 1, vec![0i64; 2 * m.len() - 3]);
    for i in 0..k { for j in 0..k { r[i + j] += u[i] * v[j] } }
    for d in (k..2 * k - 1).rev() { let c = r[d].rem_euclid(p); for i in 0..=k { r[d - k + i] -= c * m[i] } }
    r[..k].iter().map(|x| x.rem_euclid(p)).collect()
}
fn pw(x: &E, n: i64, p: i64, m: &E) -> E {            // x to the power n, one multiplication at a time
    let mut one = vec![0i64; m.len() - 1];
    one[0] = 1;
    (0..n).fold(one, |acc, _| mul(&acc, x, p, m))
}
fn ev(poly: &[i64], x: &E, p: i64, m: &E) -> E {      // a whole-number polynomial at x, by Horner
    let mut acc = vec![0i64; m.len() - 1];
    for c in poly.iter().rev() { acc = mul(&acc, x, p, m); acc[0] = (acc[0] + c).rem_euclid(p) }
    acc
}
fn elems(p: i64, k: u32) -> Vec<E> {                  // every k-tuple mod p, first entry slowest
    (0..p.pow(k)).map(|i| (0..k).map(|j| i / p.pow(k - 1 - j) % p).collect()).collect()
}
fn val(c: &[i64], r: i64, p: i64) -> i64 { c.iter().rev().fold(0, |a, x| (a * r + x).rem_euclid(p)) }
fn modulus(p: i64, k: u32) -> E {                     // a rootless monic of degree 2 or 3 is irreducible
    if k == 1 { return vec![0, 1] }
    elems(p, k).into_iter().map(|mut t| { t.push(1); t }).find(|t| (0..p).all(|r| val(t, r, p) != 0)).unwrap()
}
fn pattern(poly: &[i64], p: i64) -> Vec<(usize, usize)> { // [(degree, exponent)] of poly's factors mod p
    let (mut c, mut out): (Vec<i64>, Vec<(usize, usize)>) = (poly.iter().map(|x| x.rem_euclid(p)).collect(), vec![]);
    for r in 0..p {
        let mut e = 0;
        while c.len() > 1 && val(&c, r, p) == 0 {
            let mut q = vec![0i64; c.len() - 1];             // divide by (x - r), top coefficient first
            for i in (1..c.len()).rev() { q[i - 1] = (c[i] + r * if i < q.len() { q[i] } else { 0 }).rem_euclid(p) }
            (c, e) = (q, e + 1);
        }
        if e > 0 { out.push((1, e)) }
    }
    if c.len() > 1 { out.push((c.len() - 1, 1)) }
    out }
fn gcd(a: usize, b: usize) -> usize { if b == 0 { a } else { gcd(b, a % b) } }
fn lcm(v: impl Iterator<Item = usize>) -> usize { v.fold(1, |a, b| a / gcd(a, b) * b) }
fn road1(fd: &Field, p: i64) -> Vec<(usize, usize, usize)> { // e, f only grow up a tower; efg = n pins them
    let pats: Vec<_> = fd.subs.iter().map(|s| pattern(s, p)).collect();
    let le = lcm(pats.iter().flatten().map(|x| x.1));
    let lf = lcm(pats.iter().flatten().map(|x| x.0));
    let (n, gmax) = (fd.n, pats.iter().map(|x| x.len()).max().unwrap());
    (1..=n).flat_map(|e| (1..=n).map(move |f| (e, f))).filter(|&(e, f)| n % (e * f) == 0 && e % le == 0 && f % lf == 0
        && n / (e * f) >= gmax && (le > 1 || (e, f) == (1, lf))).map(|(e, f)| (e, f, n / (e * f))).collect()
}
fn act(fd: &Field, g: G, pt: &Pt, p: i64, m: &E) -> Pt { // the point pt composed with the symmetry g
    let (a, b) = pt;
    if fd.n == 6 { return (mul(&pw(b, g.0, p, m), a, p, m), pw(b, g.1, p, m)) }
    let flip = |x: &E, s: i64, c: i64| -> E { if s > 0 { x.clone() } else { x.iter().enumerate().map(|(j, y)| (if j == 0 { c } else { 0 } - y).rem_euclid(p)).collect() } };
    if fd.phi { (flip(a, g.1, 0), flip(b, g.0 * g.1, 1)) } else { (flip(a, g.0, 0), flip(b, g.1, 0)) }
}
fn road2(fd: &Field, p: i64) -> R2 {
    let (mut k, mut m, mut pts) = (0, vec![], vec![]);
    for kk in 1..=3u32 {                                  // the smallest GF(p^k) holding a point
        (m, k) = (modulus(p, kk), kk);
        let z = vec![0i64; kk as usize];
        let xs: Vec<E> = elems(p, kk).into_iter().filter(|x| ev(&fd.px, x, p, &m) == z).collect();
        let ys: Vec<E> = elems(p, kk).into_iter().filter(|y| ev(&fd.py, y, p, &m) == z).collect();
        pts = xs.iter().flat_map(|x| ys.iter().map(move |y| (x.clone(), y.clone()))).collect::<Vec<Pt>>();
        if !pts.is_empty() { break }
    }
    let mut orbits: Vec<Vec<Pt>> = vec![];
    for pt in &pts {                                      // Frobenius orbits: one per prime ideal above p
        if orbits.iter().any(|o| o.contains(pt)) { continue }
        let mut o = vec![pt.clone()];
        loop { let l = o.last().unwrap(); let nxt = (pw(&l.0, p, p, &m), pw(&l.1, p, p, &m)); if &nxt == pt { break } o.push(nxt) }
        orbits.push(o);
    }
    let d_of = |o: &Vec<Pt>| -> Vec<G> { fd.g.iter().copied().filter(|&g| o.contains(&act(fd, g, &o[0], p, &m))).collect() };
    let (o, f, d) = (&orbits[0], orbits[0].len(), d_of(&orbits[0]));
    let idx = |q: &Pt| o.iter().position(|x| x == q).unwrap();
    let kk: Vec<usize> = d.iter().map(|&g| idx(&act(fd, g, &o[0], p, &m))).collect(); // g acts as Frob^kk
    let i: Vec<G> = d.iter().copied().filter(|&g| act(fd, g, &o[0], p, &m) == o[0]).collect();
    let mut ok = true;
    for (a, &g) in d.iter().enumerate() { for (b, &h) in d.iter().enumerate() {
        ok &= idx(&act(fd, h, &act(fd, g, &o[0], p, &m), p, &m)) == (kk[a] + kk[b]) % f } }
    let mut vals = kk.clone(); vals.sort(); vals.dedup(); ok &= vals == (0..f).collect::<Vec<_>>();
    ok &= d.iter().zip(&kk).filter(|x| *x.1 == 0).map(|x| *x.0).collect::<Vec<G>>() == i;
    let (mut reach, mut sp): (Vec<Pt>, Vec<Pt>) = (fd.g.iter().map(|&g| act(fd, g, &o[0], p, &m)).collect(), pts.clone());
    reach.sort(); reach.dedup(); sp.sort(); ok &= reach == sp;
    let frob = d.iter().zip(&kk).filter(|x| *x.1 == 1 % f).map(|x| *x.0).collect();
    R2 { k, npts: pts.len(), e: i.len(), f, g: orbits.len(), all_d: orbits.iter().map(|x| d_of(x)).collect(), d, i, ok, frob }
}
fn perm(g: G, j: i64) -> i64 { (g.1 * j + g.0).rem_euclid(3) }
fn cyc(g: G) -> String {                              // a cubic symmetry as cycles of r0, r1, r2
    let (mut out, mut seen) = (String::new(), vec![]);
    for j in 0..3 {
        let mut c = vec![j];
        while !seen.contains(&j) && perm(g, *c.last().unwrap()) != j { c.push(perm(g, *c.last().unwrap())) }
        seen.extend(c.iter().copied());
        if c.len() > 1 { out += &format!("({})", c.iter().map(|x| format!("r{}", x)).collect::<Vec<_>>().join(" ")) }
    }
    if out.is_empty() { "id".to_string() } else { out } }
fn order(g: G) -> usize { (1..7).find(|&n| (0..3).all(|j| (0..n).fold(j, |x, _| perm(g, x)) == j)).unwrap() }
fn orbit_sizes(d: &[G]) -> Vec<usize> {               // D's orbits on the three roots
    let mut os: Vec<Vec<i64>> = (0..3).map(|j| { let mut o: Vec<i64> = d.iter().map(|&g| perm(g, j)).collect(); o.sort(); o.dedup(); o }).collect();
    os.sort(); os.dedup();
    let mut s: Vec<usize> = os.iter().map(|o| o.len()).collect(); s.sort(); s }
fn sg(g: G) -> String { format!("{}{}", if g.0 > 0 { "+" } else { "-" }, if g.1 > 0 { "+" } else { "-" }) }
fn show(s: &[G], nm: fn(G) -> String) -> String { format!("{{{}}}", s.iter().map(|&g| nm(g)).collect::<Vec<_>>().join(", ")) }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } } fn t3(x: (usize, usize, usize)) -> String { format!("({}, {}, {})", x.0, x.1, x.2) }
fn main() {
    let cubic = Field { n: 6, px: vec![-2, 0, 0, 1], py: vec![1, 1, 1], subs: vec![vec![-2, 0, 0, 1], vec![1, 1, 1]],
        g: [1, 2].iter().flat_map(|&t| (0..3).map(move |s| (s, t))).collect(), phi: false };
    let house = Field { n: 4, px: vec![5, 0, 1], py: vec![1, 0, 1], subs: vec![vec![5, 0, 1], vec![1, 0, 1], vec![-1, -1, 1]],
        g: [1, -1].iter().flat_map(|&u| [1, -1].iter().map(move |&v| (u, v))).collect(), phi: false };
    let full = Field { n: 4, px: vec![1, 0, 1], py: vec![-1, -1, 1], subs: house.subs.clone(), g: house.g.clone(), phi: true }; // all of O_H: Z[i, phi]
    println!("L = splitting field of x^3 - 2, n = 6, G = S3 on r0 = a, r1 = w a, r2 = w^2 a");
    let ps = [31i64, 5, 7, 2, 3];
    println!("by hand: 4^3 = {} = 2 + 2 x 31; roots of x^3 - 2 mod 31: {:?}; of x^2 + x + 1 mod 31: {:?}\n(degree, power) of the factors of x^3 - 2 and x^2 + x + 1 mod 31, 5, 7, 2, 3: {:?}", 4i64.pow(3),
        (0..31).filter(|r| (r * r * r - 2) % 31 == 0).collect::<Vec<i64>>(), (0..31).filter(|r| (r * r + r + 1) % 31 == 0).collect::<Vec<i64>>(), ps.iter().map(|&p| (pattern(&cubic.px, p), pattern(&cubic.py, p))).collect::<Vec<_>>()); let r: Vec<R2> = ps.iter().map(|&p| road2(&cubic, p)).collect();
    for (x, &p) in r.iter().zip(&ps) {
        println!("p={}: road 1 (e,f,g) = {} | road 2 {}, {} point{} in GF({}^{}) | D = {} | I = {}", p, t3(road1(&cubic, p)[0]),
            t3((x.e, x.f, x.g)), x.npts, if x.npts > 1 { "s" } else { "" }, p, x.k, show(&x.d, cyc), show(&x.i, cyc));
        assert!(road1(&cubic, p) == vec![(x.e, x.f, x.g)] && x.ok);
    }
    println!("p=5: the 3 primes above 5 have D = {}", r[1].all_d.iter().map(|d| show(d, cyc)).collect::<Vec<_>>().join(", "));
    println!("Frobenius at 31, 5, 7: {}, {}, {}; at 2, {} symmetries act as Frobenius on GF(4): {}",
        cyc(r[0].frob[0]), cyc(r[1].frob[0]), cyc(r[2].frob[0]), r[3].frob.len(), show(&r[3].frob, cyc));
    let mut o3: Vec<usize> = r[4].i.iter().map(|&g| order(g)).collect(); o3.sort();
    println!("p=3: orders in I = S3: {:?}; none is 6, so I is not cyclic", o3);
    let sweep: Vec<i64> = (2..50).filter(|&p| (2..p).all(|d| p % d != 0)).collect();
    let rows: Vec<R2> = sweep.iter().map(|&p| road2(&cubic, p)).collect();
    let agree = sweep.iter().zip(&rows).all(|(&p, x)| road1(&cubic, p) == vec![(x.e, x.f, x.g)] && x.ok);
    let orb = sweep.iter().zip(&rows).all(|(&p, x)| {
        let mut s: Vec<usize> = pattern(&cubic.px, p).iter().map(|(d, e)| d * e).collect(); s.sort(); orbit_sizes(&x.d) == s });
    println!("primes below 50: road 1 = road 2, D onto Gal(GF(p^f)/GF(p)) with kernel I, G moves one point to all: {}", yn(agree));
    println!("primes below 50: D's orbits on r0, r1, r2 = factors of x^3 - 2 mod p: {}", yn(orb));
    let by_size = |n: usize| -> Vec<i64> { sweep.iter().zip(&rows).filter(|(&p, x)| p > 3 && x.d.len() == n).map(|x| *x.0).collect() };
    for size in 1..=3 { println!("  |D| = {}, unramified: {:?}", size, by_size(size)) }
    println!("house H = Q(sqrt-5, i), O_H = Z[i, (1+sqrt5)/2], n = 4, symmetry = (sign on sqrt-5, sign on i), Gal(H/K) = {{++, +-}}");
    for p in [29i64, 3, 5, 2] {
        let x = road2(&full, p); println!("p={}: e={} f={} g={} | D = {} | I = {}", p, x.e, x.f, x.g, show(&x.d, sg), show(&x.i, sg));
        assert!(road1(&house, p) == vec![(x.e, x.f, x.g)] && x.ok);
    }
    let (h2, i5, r2) = (road1(&house, 2), road2(&house, 5).i, road2(&full, 2));
    let clean: Vec<usize> = (0..3).filter(|&i| pattern(&house.subs[i], 2).iter().all(|x| x.1 == 1)).collect();
    let im: Vec<G> = house.g.iter().copied().filter(|g| clean.iter().all(|&j| [g.0, g.1, g.0 * g.1][j] == 1)).collect(); // g's sign on sqrt-5, i, sqrt5
    println!("p=2 by road 1: (e,f,g) = {}; 2 is unramified only in Q(sqrt5), so I = {}", t3(h2[0]), show(&im, sg));
    let meet: Vec<usize> = [&r2.i, &i5].iter().map(|i| i.iter().filter(|g| g.0 == 1).count()).collect();
    println!("I meets Gal(H/K) in {} symmetry at 2 and {} at 5: H/K is unramified at 2 and 5", meet[0], meet[1]);
    let hsweep: Vec<i64> = sweep.iter().copied().filter(|&p| p > 2 && road2(&house, p).d == vec![(1, 1)]).collect();
    println!("odd primes below 50 with D trivial in H: {:?}", hsweep);
    let (k5, b2) = (pattern(&cubic.px, 5), road2(&house, 2));
    println!("mistake 1, Q(a) not Galois: x^3 - 2 mod 5 has factor degrees {:?}; e f g from the first prime = 1 x {} x {} = {}, not 3",
        k5.iter().map(|x| x.0).collect::<Vec<_>>(), k5[0].0, k5.len(), k5[0].0 * k5.len());
    println!("mistake 2, I read as D at 2: e = {}, e f g = {}, not 6", r[3].d.len(), r[3].d.len() * 2);
    println!("mistake 3, Z[sqrt-5, i] taken as all integers of H at 2: {} point, fixed by {}: e = {}, f = {}; truly e = {}, f = {}", b2.npts, b2.e, b2.e, b2.f, r2.e, r2.f);
    assert!(r.iter().map(|x| x.d.len()).collect::<Vec<_>>() == vec![1, 2, 3, 6, 6] && r.iter().map(|x| x.i.len()).collect::<Vec<_>>() == vec![1, 1, 1, 3, 6]);
    assert!(agree && orb && { let mut ds = r[1].all_d.clone(); ds.sort(); ds.dedup(); ds.len() == 3 } && o3 == vec![1, 2, 2, 2, 3, 3]);
    assert!(by_size(2) == sweep.iter().copied().filter(|&p| p % 3 == 2 && p > 2).collect::<Vec<_>>());
    let want: Vec<i64> = sweep.iter().copied().filter(|p| p % 20 == 1 || p % 20 == 9).collect();
    assert!(h2 == vec![(2, 2, 1)] && clean == vec![2] && im == r2.i && meet == vec![1, 1] && hsweep == want);
    let (mut dmi, mut fr): (Vec<G>, Vec<G>) = (r[3].d.iter().copied().filter(|g| !r[3].i.contains(g)).collect(), r[3].frob.clone()); dmi.sort(); fr.sort();
    assert!((b2.e, b2.f) == (4, 1) && fr == dmi && [0, 1, 2].iter().map(|&j| order(r[j].frob[0])).collect::<Vec<_>>() == vec![1, 2, 3]);
    assert!(cubic.g.iter().all(|&g| { let (a, b) = act(&cubic, g, &(vec![4], vec![5]), 31, &vec![0, 1]); (0..3).all(|j| b[0].pow(j as u32) * a[0] % 31 == 5i64.pow(perm(g, j) as u32) * 4 % 31) })); // act agrees with perm
    println!("ALL CHECKS PASS");
}
