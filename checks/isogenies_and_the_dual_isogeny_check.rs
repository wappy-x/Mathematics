// Isogenies and the dual isogeny -- the check behind the card.  std only; polynomial arithmetic
// uses checked i128, so an overflow stops the run.  E is y^2 = x^3 - x, E2 is Y^2 = X^3 + 4X,
// phi(x, y) = (y^2/x^2, -y(x^2 + 1)/x^2).  Roads: Velu's formula against phi; dual(phi) against
// doubling, point by point and as fractions; deg[m] from division polynomials against m-torsion
// counts; Hasse's form against a brute-force count over F_25.
type Pt = Option<(i64, i64)>; // None is O
type Poly = Vec<i128>; // constant first

fn md(a: i64, p: i64) -> i64 { a.rem_euclid(p) }
fn pw(a: i64, mut e: i64, p: i64) -> i64 {
    let (mut out, mut b) = (1i64, md(a, p));
    while e > 0 { if e & 1 == 1 { out = out * b % p; } b = b * b % p; e >>= 1; }
    out
}
fn ecadd(a_: Pt, b_: Pt, a: i64, p: i64) -> Pt {
    let ((x1, y1), (x2, y2)) = match (a_, b_) { (None, q) => return q, (q, None) => return q, (Some(u), Some(v)) => (u, v) };
    if x1 == x2 && md(y1 + y2, p) == 0 { return None; }
    let m = if a_ == b_ { md((3 * x1 * x1 + a) * pw(2 * y1, p - 2, p), p) } else { md((y2 - y1) * pw(x2 - x1, p - 2, p), p) };
    let x3 = md(m * m - x1 - x2, p);
    Some((x3, md(m * (x1 - x3) - y1, p)))
}
fn mult(n: i64, p_: Pt, a: i64, p: i64) -> Pt { (0..n).fold(None, |r, _| ecadd(r, p_, a, p)) }
fn points(a: i64, p: i64) -> Vec<(i64, i64)> { // every pair (x, y) on y^2 = x^3 + ax, O left out
    (0..p * p).map(|k| (k / p, k % p)).filter(|&(x, y)| md(y * y - x * x * x - a * x, p) == 0).collect()
}
fn phi(q: Pt, p: i64) -> Pt {
    match q { Some((x, y)) if x != 0 => { let i = pw(x * x, p - 2, p);
        Some((md(y * y % p * i, p), md(-y * md(x * x + 1, p) % p * i, p))) } _ => None }
}
fn dual(q: Pt, p: i64) -> Pt {
    match q { Some((x, y)) if x != 0 => { let i = pw(8 * x * x, p - 2, p);
        Some((md(2 * y * y % p * i, p), md(y * md(4 - x * x, p) % p * i, p))) } _ => None }
}
fn velu(q: Pt, p: i64) -> Pt {
    match q { Some((x, y)) if x != 0 => Some((md(x - pw(x, p - 2, p), p), md(y + y * pw(x * x, p - 2, p), p))), _ => None }
}
fn pmul(f: &Poly, g: &Poly) -> Poly {
    let mut out = vec![0i128; f.len() + g.len() - 1];
    for (i, c) in f.iter().enumerate() { for (j, d) in g.iter().enumerate() {
        out[i + j] = out[i + j].checked_add(c.checked_mul(*d).expect("overflow")).expect("overflow"); } }
    out
}
fn psub(f: &Poly, g: &Poly) -> Poly {
    let n = f.len().max(g.len());
    let mut out: Poly = (0..n).map(|i| f.get(i).unwrap_or(&0).checked_sub(*g.get(i).unwrap_or(&0)).expect("overflow")).collect();
    while out.len() > 1 && *out.last().unwrap() == 0 { out.pop(); }
    out
}
fn gcd_deg(f: &Poly, g: &Poly, p: i128) -> i64 { // degree of gcd(f, g) mod p, by Euclid
    let mut f: Poly = f.iter().map(|c| c.rem_euclid(p)).collect();
    let mut g: Poly = g.iter().map(|c| c.rem_euclid(p)).collect();
    while g.iter().any(|c| *c != 0) { // leading terms stay nonzero mod p
        while f.len() >= g.len() && f.iter().any(|c| *c != 0) {
            let c = f[f.len() - 1] * pw(g[g.len() - 1] as i64, (p - 2) as i64, p as i64) as i128 % p;
            let s = f.len() - g.len();
            f = (0..f.len()).map(|i| (f[i] - c * if i >= s { g[i - s] } else { 0 }).rem_euclid(p)).collect();
            while !f.is_empty() && *f.last().unwrap() == 0 { f.pop(); }
        }
        std::mem::swap(&mut f, &mut g);
    }
    f.len() as i64 - 1
}
fn xmult(m: usize, a: i128, b: i128) -> (Poly, Poly) { // x([m]P) = top / bottom
    let f: Poly = vec![b, a, 0, 1];
    let mut g: Vec<Poly> = vec![vec![0], vec![1], vec![2], vec![-a * a, 12 * b, 6 * a, 0, 3],
        [-8 * b * b - a * a * a, -4 * a * b, -5 * a * a, 20 * b, 5 * a, 0, 1].iter().map(|c| 4 * c).collect()];
    for n in 5..m + 2 { // psi_n = g_n for odd n, y * g_n for even n
        let (k, f2) = (n / 2, pmul(&f, &f));
        let gn = if n % 2 == 1 {
            let (s1, s2) = if k % 2 == 0 { (f2.clone(), vec![1]) } else { (vec![1], f2.clone()) };
            psub(&pmul(&s1, &pmul(&g[k + 2], &pmul(&g[k], &pmul(&g[k], &g[k])))),
                 &pmul(&s2, &pmul(&g[k - 1], &pmul(&g[k + 1], &pmul(&g[k + 1], &g[k + 1])))))
        } else {
            let t = psub(&pmul(&g[k + 2], &pmul(&g[k - 1], &g[k - 1])), &pmul(&g[k - 2], &pmul(&g[k + 1], &g[k + 1])));
            pmul(&g[k], &t).iter().map(|c| c / 2).collect()
        };
        g.push(gn);
    }
    let sq = pmul(&g[m], &g[m]);
    if m % 2 == 1 { return (psub(&pmul(&vec![0, 1], &sq), &pmul(&f, &pmul(&g[m - 1], &g[m + 1]))), sq); }
    (psub(&pmul(&vec![0, 1], &pmul(&f, &sq)), &pmul(&g[m - 1], &g[m + 1])), pmul(&f, &sq))
}
fn show(f: &Poly) -> String { // leading term first: x^4 + 2x^2 + 1
    let mut out = String::new();
    for i in (0..f.len()).rev() { if f[i] != 0 {
        let c = if f[i].abs() == 1 && i > 0 { String::new() } else { f[i].abs().to_string() };
        let term = c + &(if i == 0 { String::new() } else if i == 1 { "x".to_string() } else { format!("x^{}", i) });
        out += if out.is_empty() { if f[i] < 0 { "-" } else { "" } } else if f[i] < 0 { " - " } else { " + " };
        out += &term; } }
    out
}
fn count2(p: i64, r: i64) -> i64 { // y^2 = x^3 - x over F_(p^2) = c + d*s, s^2 = r
    let mul = |u: (i64, i64), w: (i64, i64)| (md(u.0 * w.0 + r * u.1 * w.1, p), md(u.0 * w.1 + u.1 * w.0, p));
    let fl: Vec<(i64, i64)> = (0..p * p).map(|k| (k / p, k % p)).collect();
    let mut n = 1;
    for &x in &fl { let c = mul(x, mul(x, x)); let rhs = (md(c.0 - x.0, p), md(c.1 - x.1, p));
        for &y in &fl { if mul(y, y) == rhs { n += 1; } } }
    n
}
fn s(q: Pt) -> String { match q { Some((x, y)) => format!("({}, {})", x, y), None => "O".into() } }
fn ev(h: &Poly, x: i64) -> i64 { h.iter().rev().fold(0i64, |acc, c| md(acc * x + (*c % 61) as i64, 61)) }

fn main() {
    let v = 3 * 0 * 0 - 1; // Velu at T = (0, 0) on y^2 = x^3 - x: v = 3x_T^2 + a, w = x_T v
    println!("Velu: v = {}, w = {}; target Y^2 = X^3 + {}X + {}", v, 0 * v, -1 - 5 * v, 0 - 7 * 0 * v);
    let mut counts = vec![];
    for p in [5i64, 13, 17, 29] {
        let (e, e2) = (points(-1, p), points(4, p));
        let homo = e.iter().all(|&a| e.iter().all(|&b| phi(ecadd(Some(a), Some(b), -1, p), p) == ecadd(phi(Some(a), p), phi(Some(b), p), 4, p)));
        let back = e.iter().all(|&a| dual(phi(Some(a), p), p) == mult(2, Some(a), -1, p));
        let fwd = e2.iter().all(|&q| phi(dual(Some(q), p), p) == mult(2, Some(q), 4, p));
        let neg = e.iter().all(|&a| phi(Some(a), p) == velu(Some(a), p).map(|(x, y)| (x, md(-y, p))));
        let ker: Vec<_> = e.iter().filter(|&&a| phi(Some(a), p).is_none()).collect();
        assert!(homo && back && fwd && neg && ker == vec![&(0, 0)] && e.len() == e2.len());
        counts.push(e.len() as i64 + 1);
        let mut img: Vec<Pt> = e.iter().map(|&a| phi(Some(a), p)).collect();
        img.sort(); img.dedup();
        println!("F_{}: #E = {}, #E2 = {}, kernel {{O, (0, 0)}}, image {} points, adds: yes, dual(phi) = [2]: yes, phi = -Velu: yes",
            p, e.len() + 1, e2.len() + 1, img.len());
    }
    assert!(counts == vec![8, 8, 16, 40]);
    let (pp, r) = (Some((3, 13)), dual(phi(Some((3, 13)), 29), 29));
    println!("F_29: P = {}, phi(P) = {}, dual(phi(P)) = {}, 2P = {}; equals P: {}", s(pp), s(phi(pp, 29)), s(r), s(mult(2, pp, -1, 29)), if r == pp { "yes" } else { "no" });
    println!("by hand mod 29: 13^2 = {} -> {}, 3^3 - 3 = {}; 9 x 13 = {} -> {}, so 1/9 = {}; X = 24 x 13 = {} -> {}; Y = -13 x {} = {}, x 13 -> {}; 21^2 = {} -> {}",
        13 * 13, 13 * 13 % 29, 27 - 3, 9 * 13, 9 * 13 % 29, pw(9, 27, 29), 24 * 13, 24 * 13 % 29, 9 + 1, -130, md(-130 * 13, 29), 21 * 21, 21 * 21 % 29);
    println!("by hand mod 29: 22^3 + 4 x 22 = {} -> {}; 4X^2 = {} -> {}; 22 x 4 = {} -> {}, so 1/22 = {}; x = 6 x 4 = {}; 2P: slope {}/{} = 1, x = 1 - {} = {} -> {}",
        22 * 22 * 22 + 88, (22 * 22 * 22 + 88) % 29, 4 * 22 * 22, 4 * 22 * 22 % 29, 88, 88 % 29, pw(22, 27, 29), 6 * 4 % 29, 3 * 9 - 1, 2 * 13, 2 * 3, 1 - 6, md(-5, 29));
    let (top, bot) = xmult(2, -1, 0); // dual after phi, as exact fractions in x
    let ltop = psub(&pmul(&vec![-1, 0, 1], &vec![-1, 0, 1]), &vec![0, 0, -4]);
    let lbot: Poly = pmul(&vec![0, 1], &vec![-1, 0, 1]).iter().map(|c| 4 * c).collect();
    assert!(pmul(&ltop, &bot) == pmul(&top, &lbot));
    println!("x(dual(phi(P))) = ({}) / ({}); x(2P) = ({}) / ({})", show(&ltop), show(&lbot), show(&top), show(&bot));
    for m in [2usize, 3, 4, 5] {
        let (top, bot) = xmult(m, -1, 0);
        let d = top.len().max(bot.len()) - 1;
        let mi = m as i64;
        let q = points(-1, 61).into_iter().find(|&q| ev(&bot, q.0) != 0 && mult(mi - 1, Some(q), -1, 61).is_some() && mult(mi + 1, Some(q), -1, 61).is_some()).unwrap();
        assert!(d == m * m && gcd_deg(&top, &bot, 10007) == 0 && Some(ev(&top, q.0) * pw(ev(&bot, q.0), 59, 61) % 61) == mult(mi, Some(q), -1, 61).map(|t| t.0));
        println!("[{}]: top degree {}, lead {}; bottom degree {}, lead {}; coprime: yes; deg = {}", m, top.len() - 1, top[top.len() - 1], bot.len() - 1, bot[bot.len() - 1], d);
    }
    let (top, bot) = xmult(2, 0, -2); // house point (3, 5): tangent slope 27/10, x(2P) = 27^2/10^2 - 6
    let (t3, b3) = (top.iter().rev().fold(0i128, |acc, c| acc * 3 + c), bot.iter().rev().fold(0i128, |acc, c| acc * 3 + c));
    assert!(t3 * 100 == b3 * (27 * 27 - 6 * 100));
    println!("house curve y^2 = x^3 - 2: x(2P) = ({}) / ({}); at x = 3: {}/{}", show(&top), show(&bot), t3, b3);
    for (m, p) in [(3i64, 61i64), (4, 17), (3, 5)] {
        let tors: Vec<_> = points(-1, p).into_iter().filter(|&q| mult(m, Some(q), -1, p).is_none()).collect();
        let mut orders = vec![1];
        for &q in &tors { orders.push((1..=m).find(|&n| mult(n, Some(q), -1, p).is_none()).unwrap()); }
        assert!(orders.len() as i64 == if p != 5 { m * m } else { 1 });
        let by: Vec<String> = (1..=m).filter(|n| orders.contains(n)).map(|n| format!("{}: {}", n, orders.iter().filter(|&&o| o == n).count())).collect();
        println!("points P of E(F_{}) with {}P = O: {}; by order {}", p, m, orders.len(), by.join(", "));
    }
    let (n9, (t9, b9)) = (count2(3, 2), xmult(3, -1, 0)); // F_9: s^2 = 2 = -1; x(3P) mod 3
    let (t9, b9): (Poly, Poly) = (t9.iter().map(|c| c.rem_euclid(3)).collect(), b9.iter().map(|c| c.rem_euclid(3)).collect());
    assert!(n9 == 16 && t9[t9.len() - 1] != 0 && b9[0] != 0 && b9[1..].iter().all(|&c| c == 0)); // mod 3 the bottom is a constant
    println!("char 3: #E(F_9) = {}, not divisible by 3, so its only point with 3P = O is O; x(3P) mod 3 = ({}) / ({}), deg[3] = {}", n9, show(&t9), show(&b9), t9.len() - 1);
    let (p, a5, n25) = (5i64, 5 + 1 - counts[0], count2(5, 2)); // Hasse at p = 5; F_25 with s^2 = 2
    let form = |m: i64, n: i64| m * m - a5 * m * n + p * n * n;
    assert!(n25 == form(1, 1) * form(1, -1));
    assert!((-9..10).all(|m| (-9..10).all(|n| form(m, n) >= 0)));
    println!("p = 5: a_5 = {}; deg(1 - pi) = #E(F_5) = {}; additive guess deg 1 + deg pi = {}", a5, form(1, 1), 1 + p);
    println!("deg(m - n pi) = m^2 - ({})mn + 5n^2 >= 0 on -9..9; discriminant a_5^2 - 4p = {}", a5, a5 * a5 - 4 * p);
    println!("#E(F_25) by brute force {}; deg(1 - pi) deg(1 + pi) = {} x {} = {}", n25, form(1, 1), form(1, -1), form(1, 1) * form(1, -1));
    for q in [5i64, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47] {
        let aq = q + 1 - (points(-1, q).len() as i64 + 1);
        assert!(aq * aq <= 4 * q);
    }
    println!("Hasse a_p^2 <= 4p at every prime from 5 to 47: yes");
    println!("ALL CHECKS PASS");
}
