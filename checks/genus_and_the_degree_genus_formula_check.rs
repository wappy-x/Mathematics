// Genus and the degree-genus formula: the Python check in Rust, no crates.  Curves over C are lists of (i, j, c)
// for c x^i y^j, z = 1.  Roads: (1) the formula, (2) Riemann-Hurwitz from the y-discriminant, (3) adjoint curves of
// degree d-3; genus-0 curves get a parametrisation put back in.  checked_mul stops on overflow; gcds and resultants mod P.
const P: i128 = 1_000_000_007;
type Poly = Vec<i128>;
type Curve = Vec<(u32, u32, i128)>;
fn trim(mut a: Poly) -> Poly { while a.len() > 1 && *a.last().unwrap() == 0 { a.pop(); } a }
fn padd(a: &Poly, b: &Poly) -> Poly { trim((0..a.len().max(b.len())).map(|i| a.get(i).unwrap_or(&0) + b.get(i).unwrap_or(&0)).collect()) }
fn pmul(a: &Poly, b: &Poly) -> Poly {
    let mut out = vec![0i128; a.len() + b.len() - 1];
    for (i, u) in a.iter().enumerate() { for (j, v) in b.iter().enumerate() { out[i + j] += u.checked_mul(*v).expect("overflow"); } }
    trim(out) }
fn deriv(a: &Poly) -> Poly { if a.len() < 2 { vec![0] } else { trim((1..a.len()).map(|i| i as i128 * a[i]).collect()) } }
fn show(a: &Poly) -> String {
    if *a == vec![0] { return "0".to_string(); }
    let mut s = String::new();
    for k in (0..a.len()).rev() {
        if a[k] == 0 { continue; } let c = a[k].abs();
        let m = if k == 0 { String::new() } else if k == 1 { "x".to_string() } else { format!("x^{}", k) };
        s += if a[k] < 0 { " - " } else { " + " };
        s += &(if c == 1 && k > 0 { String::new() } else { c.to_string() } + &m);
    }
    if &s[1..2] == "+" { s[3..].to_string() } else { format!("-{}", &s[3..]) }
}
fn det(m: &Vec<Vec<Poly>>) -> Poly {                 // cofactor expansion, polynomial entries
    if m.len() == 1 { return m[0][0].clone(); }
    let mut tot = vec![0];
    for c in 0..m.len() {
        if m[0][c] == vec![0] { continue; }
        let minor: Vec<Vec<Poly>> = m[1..].iter()
            .map(|row| row.iter().enumerate().filter(|(k, _)| *k != c).map(|(_, e)| e.clone()).collect()).collect();
        let sign = if c % 2 == 0 { 1 } else { -1 };
        tot = padd(&tot, &pmul(&vec![sign], &pmul(&m[0][c], &det(&minor))));
    }
    tot
}
fn coef(f: &Curve, i: u32, j: u32) -> i128 { f.iter().filter(|t| t.0 == i && t.1 == j).map(|t| t.2).sum() }
fn disc_y(f: &Curve, d: usize) -> Poly {             // Res_y(F, dF/dy): Sylvester matrix, 2d-1 rows
    let co: Vec<Poly> = (0..=d).map(|j| trim((0..=d).map(|i| coef(f, i as u32, j as u32)).collect())).collect();
    let cy: Vec<Poly> = (1..=d).map(|j| pmul(&vec![j as i128], &co[j])).collect();
    let n = 2 * d - 1;
    let mut rows: Vec<Vec<Poly>> = Vec::new();
    for r in 0..d - 1 { rows.push((0..n).map(|c| { let k = (r + d) as i64 - c as i64;
        if k >= 0 && k <= d as i64 { co[k as usize].clone() } else { vec![0] } }).collect()); }
    for r in 0..d { rows.push((0..n).map(|c| { let k = (r + d - 1) as i64 - c as i64;
        if k >= 0 && k < d as i64 { cy[k as usize].clone() } else { vec![0] } }).collect()); }
    det(&rows)
}
fn powm(mut b: i128, mut e: i128) -> i128 { let mut r = 1; b = b.rem_euclid(P);
    while e > 0 { if e & 1 == 1 { r = r * b % P; } b = b * b % P; e >>= 1; } r }
fn modp(a: &Poly) -> Poly { trim(a.iter().map(|c| c.rem_euclid(P)).collect()) }
fn rem_mod(mut a: Poly, b: &Poly) -> Poly {          // remainder of a on division by b, mod P
    let inv = powm(*b.last().unwrap(), P - 2);
    while a.len() >= b.len() && a != vec![0] {
        let (q, s) = (a.last().unwrap() * inv % P, a.len() - b.len());
        a = trim((0..a.len()).map(|i| if i >= s { (a[i] - q * b[i - s]).rem_euclid(P) } else { a[i] }).collect());
    }
    a
}
fn gcd_mod(a: &Poly, b: &Poly) -> Poly {             // Euclid's algorithm for polynomials mod P
    let (mut a, mut b) = (modp(a), modp(b));
    while b != vec![0] { let r = rem_mod(a, &b); a = b; b = r; }
    let inv = powm(*a.last().unwrap(), P - 2);         // made monic, so "no common factor" reads [1]
    a.iter().map(|c| c * inv % P).collect()
}
fn res_mod(a: &Poly, b: &Poly) -> i128 {             // Res(a, b) mod P by Euclid, with no determinant
    let (mut a, mut b, mut r) = (modp(a), modp(b), 1);
    while b.len() > 1 {
        let c = rem_mod(a.clone(), &b); if c == vec![0] { return 0; }
        let sign = if (a.len() - 1) * (b.len() - 1) % 2 == 0 { 1 } else { P - 1 };
        r = r * sign % P * powm(*b.last().unwrap(), (a.len() - c.len()) as i128) % P; a = b; b = c;
    }
    r * powm(b[0], (a.len() - 1) as i128) % P
}
fn falling(n: u32, k: u32) -> i128 { (0..k).map(|i| n as i128 - i as i128).product() }
fn partial(f: &Curve, i: u32, j: u32, p: i128, q: i128) -> i128 {   // d^i/dx^i d^j/dy^j of F at (p, q)
    f.iter().filter(|t| t.0 >= i && t.1 >= j)
        .map(|&(a, b, c)| c * falling(a, i) * falling(b, j) * p.pow(a - i) * q.pow(b - j)).sum()
}
fn multiplicity(f: &Curve, p: i128, q: i128) -> u32 {
    (0..5).flat_map(|i| (0..5).map(move |j| (i, j))).filter(|&(i, j)| partial(f, i, j, p, q) != 0)
        .map(|(i, j)| i + j).min().unwrap()
}
fn road1(f: &Curve, d: i64, sing: &[(i128, i128, u32)]) -> (i64, i64, i64) {   // road 1: (d-1)(d-2)/2, the sum of m(m-1)/2
    let dl: i64 = sing.iter().map(|&(p, q, _)| multiplicity(f, p, q) as i64).map(|m| m * (m - 1) / 2).sum();   // m measured from F
    ((d - 1) * (d - 2) / 2, dl, (d - 1) * (d - 2) / 2 - dl) }
fn rank_mod(rows: &Vec<Vec<i128>>) -> usize {
    let mut rows: Vec<Vec<i128>> = rows.iter().map(|r| r.iter().map(|v| v.rem_euclid(P)).collect()).collect();
    let mut r = 0;
    for c in 0..rows.first().map_or(0, |x| x.len()) {
        let piv = match (r..rows.len()).find(|&k| rows[k][c] != 0) { Some(k) => k, None => continue };
        rows.swap(r, piv);
        let inv = powm(rows[r][c], P - 2);
        for k in 0..rows.len() {
            if k != r && rows[k][c] != 0 { let f = rows[k][c] * inv % P;
                rows[k] = (0..rows[k].len()).map(|x| (rows[k][x] - f * rows[r][x]).rem_euclid(P)).collect(); }
        }
        r += 1;
    }
    r
}
fn adjoints(d: u32, sing: &[(i128, i128, u32)]) -> (usize, usize) {   // degree d-3, vanishing to order m-1
    let mons: Vec<(u32, u32)> = (0..d - 2).flat_map(|a| (0..d - 2 - a).map(move |b| (a, b))).collect();
    let mut conds: Vec<Vec<i128>> = Vec::new();
    for &(p, q, m) in sing { for k in 0..m - 1 { for i in 0..=k {
        conds.push(mons.iter().map(|&(a, b)| if a >= i && b >= k - i {
            falling(a, i) * falling(b, k - i) * p.pow(a - i) * q.pow(b + i - k) } else { 0 }).collect());
    } } }
    (mons.len(), rank_mod(&conds))
}
fn homog_at(f: &Curve, d: u32, x: &Poly, y: &Poly, z: &Poly) -> Poly {  // F(X(t), Y(t), Z(t)), degree d
    let mut tot = vec![0];
    for &(a, b, c) in f {
        let mut term = vec![c];
        for (poly, e) in [(x, a), (y, b), (z, d - a - b)] { for _ in 0..e { term = pmul(&term, poly); } } tot = padd(&tot, &term);
    }
    tot
}
fn main() {
    let qn: Curve = vec![(4, 0, 1), (2, 0, -1), (0, 4, 1), (0, 3, 1), (0, 2, 1)]; let mut qs = qn.clone(); qs.push((0, 0, -1));
    println!("field: the complex numbers; exact integers; polynomial gcds modulo {}", P); let top: Poly = vec![1, 0, 0, 0, 1];
    println!("points at infinity of both quartics: s^4 + 1 has {} repeated roots, so 4 separate points", gcd_mod(&top, &deriv(&top)).len() - 1);
    let (mut nodal_genus, mut pa4) = (0, 0);
    for (name, f, sing) in [("smooth quartic x^4 - x^2 + y^4 + y^3 + y^2 - 1", &qs, vec![]),
                            ("nodal quartic x^4 - x^2 + y^4 + y^3 + y^2", &qn, vec![(0i128, 0i128, 2u32)])] {
        let dd = disc_y(f, 4); let g = gcd_mod(&dd, &deriv(&dd)); let g2 = gcd_mod(&g, &deriv(&g));
        let b = (dd.len() - 1 - 2 * (g.len() - 1)) as i64;   // simple roots; the repeated ones are double
        let ((pa, dl, g1), (nm, rk)) = (road1(f, 4, &sing), adjoints(4, &sing));
        println!("{} = 0", name);
        for &(p, q, _) in &sing {
            let hess = partial(f, 1, 1, p, q).pow(2) - partial(f, 2, 0, p, q) * partial(f, 0, 2, p, q);
            println!("  singular point ({}, {}): multiplicity {}, two tangents: {}, so a node, delta {}", p, q, multiplicity(f, p, q), if hess != 0 { "yes" } else { "no" }, dl);
        }
        println!("  road 1, formula: (4 - 1)(4 - 2)/2 - {} = {}", dl, g1);
        println!("  discriminant in y: {}", show(&dd));
        println!("  degree {}; repeated roots {}{}; branch points {}", dd.len() - 1, g.len() - 1, if sing.is_empty() { "" } else { " (x = 0, the node's x, twice)" }, b);
        println!("  road 2, Riemann-Hurwitz: 2 - 2g = 2*4 - {} = {}, so g = {}", b, 8 - b, (b - 6) / 2);
        println!("  road 3, lines through the singular points: {} coefficients - {} conditions = {}", nm, rk, nm - rk);
        assert!(g2 == vec![1] && g == if sing.is_empty() { vec![1] } else { vec![0, 1] } && gcd_mod(&top, &deriv(&top)) == vec![1]);
        assert!(2 - 2 * g1 == 8 - b && g1 == (nm - rk) as i64);   // three roads agree
        let fx = |x: i128| -> Poly { (0..5).map(|j| f.iter().filter(|t| t.1 == j).map(|t| t.2 * x.pow(t.0)).sum()).collect() };
        assert!((1..6).all(|x| res_mod(&fx(x), &deriv(&fx(x))) == dd.iter().enumerate().map(|(i, c)| c * x.pow(i as u32)).sum::<i128>().rem_euclid(P)));
        nodal_genus = g1; pa4 = pa;
    }
    let c3: Curve = vec![(0, 2, 1), (3, 0, -1), (2, 0, -1)];
    let tri: Curve = vec![(4, 0, 1), (2, 2, 2), (0, 4, 1), (3, 0, -1), (1, 2, 3)];
    let two: Curve = vec![(4, 0, 2), (2, 2, 5), (0, 4, 2), (2, 0, -9), (0, 2, -9), (0, 0, 9)];
    let f3: Poly = vec![-1, 0, -1, -1];                  // y^2 = x^3 + x^2 + 1: smooth when f3 has no repeated root
    let ((_, d0, g0), (nm, rk)) = (road1(&vec![], 3, &[]), adjoints(3, &[]));
    println!("smooth cubic y^2 = x^3 + x^2 + 1: repeated roots of the right side {}; road 1: (3 - 1)(3 - 2)/2 - {} = {}; road 3: {} - {} = {}", gcd_mod(&f3, &deriv(&f3)).len() - 1, d0, g0, nm, rk, nm - rk);
    let ((p3, d3, g3), (n3, r3)) = (road1(&c3, 3, &[(0, 0, 2)]), adjoints(3, &[(0, 0, 2)])); let par = homog_at(&c3, 3, &vec![-1, 0, 1], &vec![0, -1, 0, 1], &vec![1]);
    println!("nodal cubic y^2 = x^3 + x^2: multiplicity at (0, 0) {}; road 1: {} - {} = {}; road 3: {} - {} = {}", multiplicity(&c3, 0, 0), p3, d3, g3, n3, r3, n3 - r3);
    println!("  rational: (t^2 - 1, t^3 - t) put back in gives {}; t = 2 gives (3, 6): 6^2 = {}, 3^2 * 4 = {}", show(&par), 6 * 6, 9 * 4);
    assert!(gcd_mod(&f3, &deriv(&f3)) == vec![1] && g0 == (nm - rk) as i64 && g3 == (n3 - r3) as i64 && par == vec![0] && multiplicity(&c3, 0, 0) == 2);
    let ((pt, dt, gt), (nt, rt), mt) = (road1(&tri, 4, &[(0, 0, 3)]), adjoints(4, &[(0, 0, 3)]), multiplicity(&tri, 0, 0)); let par = homog_at(&tri, 4, &vec![1, 0, -3], &vec![0, 1, 0, -3], &vec![1, 0, 2, 0, 1]);
    println!("trifolium (x^2 + y^2)^2 = x^3 - 3xy^2: multiplicity at (0, 0) {}, delta {}*{}/2 = {}; road 1: {} - {} = {}; road 3: {} - {} = {}", mt, mt, mt - 1, dt, pt, dt, gt, nt, rt, nt - rt);
    println!("  rational: (1 - 3t^2, t - 3t^3, (1 + t^2)^2) put back in gives {}", show(&par));
    assert!(mt == 3 && gt == (nt - rt) as i64 && par == vec![0]);
    let (pts, mq): (Vec<(i128, i128)>, i64) = ([-1, 1].iter().flat_map(|&p| [-1, 1].iter().map(move |&q| (p, q))).collect(), multiplicity(&qn, 0, 0) as i64);
    let sing: Vec<(i128, i128, u32)> = pts.iter().map(|&(p, q)| (p, q, 2)).collect(); let ((pc, dc, gc), (nc, rc)) = (road1(&two, 4, &sing), adjoints(4, &sing));
    let mults: Vec<u32> = pts.iter().map(|&(p, q)| multiplicity(&two, p, q)).collect();
    println!("two conics (x^2 + 2y^2 - 3)(2x^2 + y^2 - 3): nodes at {:?}, multiplicities {:?}; road 1: {} - {} = {}; road 3: {} - {} = {}", pts, mults, pc, dc, gc, nc, rc, nc - rc);
    println!("mistake 1, node not subtracted: quartic {} - 0 = {}, not {}; cubic {} - 0 = {}, not {}", pa4, pa4, nodal_genus, p3, p3, g3);
    println!("mistake 2, triple point counted as 1: {} - 1 = {}, not {} - {} = {}", pt, pt - 1, pt, dt, gt);
    println!("mistake 3, formula on two conics: {}, a genus no surface has; road 3 says {}", gc, nc - rc);
    println!("mistake 4, delta read as multiplicity: the node has m = {}, so {} - {} = {}, not {}", mq, pa4, mq, pa4 - mq, nodal_genus);
    assert!(gc == -1 && nc - rc == 0 && mults.iter().all(|&m| m == 2) && pa4 - mq != nodal_genus);
    for d in 1..8 { let g = (d - 1) * (d - 2) / 2; println!("bars, degree {}: {:<30} {}", d, "#".repeat(2 * g), g); }
    println!("ALL CHECKS PASS");
}
