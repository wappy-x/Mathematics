// Chern classes and Hirzebruch-Riemann-Roch -- the same check as the Python, in Rust.  No crates.
// Classes on P^2 live in Q[H]/(H^3): an array [a0, a1, a2] means a0 + a1 H + a2 H^2, and H^2 = one point.
// Road 1: Hirzebruch-Riemann-Roch, chi = the H^2 coefficient of ch times td.
// Road 2: Cech count: monomials of degree d with all powers >= 0 (h^0) or all <= -1 (h^2).
// Road 3: Riemann-Roch for surfaces, and on the cubic surface an exact rank count of plane cubics.
#[derive(Clone, Copy, PartialEq, Debug)]
struct Fr { n: i128, d: i128 }                         // a fraction in lowest terms, d > 0
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn fr(n: i128, d: i128) -> Fr {
    let g = gcd(n, d).max(1); let s = if d < 0 { -1 } else { 1 };
    Fr { n: s * n / g, d: s * d / g }
}
fn int(n: i128) -> Fr { fr(n, 1) }
fn add(a: Fr, b: Fr) -> Fr { fr(a.n.checked_mul(b.d).unwrap() + b.n.checked_mul(a.d).unwrap(), a.d.checked_mul(b.d).unwrap()) }
fn sub(a: Fr, b: Fr) -> Fr { add(a, fr(-b.n, b.d)) }
fn mulf(a: Fr, b: Fr) -> Fr { fr(a.n.checked_mul(b.n).unwrap(), a.d.checked_mul(b.d).unwrap()) }
fn divf(a: Fr, b: Fr) -> Fr { fr(a.n.checked_mul(b.d).unwrap(), a.d.checked_mul(b.n).unwrap()) }
fn s(x: Fr) -> String { if x.d == 1 { format!("{}", x.n) } else { format!("{}/{}", x.n, x.d) } }
type P = [Fr; 3];
fn mul(a: P, b: P) -> P {                              // product in Q[H]/(H^3)
    let mut c = [int(0); 3];
    for k in 0..3 { for i in 0..=k { c[k] = add(c[k], mulf(a[i], b[k - i])); } }
    c
}
fn inv(a: P) -> P {                                    // 1/a as a power series, a[0] = 1
    let mut b = [int(1), int(0), int(0)];
    for k in 1..3 { let mut t = int(0); for i in 1..=k { t = add(t, mulf(a[i], b[k - i])); } b[k] = fr(-t.n, t.d); }
    b
}
fn fact(n: i128) -> i128 { if n < 2 { 1 } else { n * fact(n - 1) } }
fn exp_h(t: i128) -> P { [int(1), int(t), fr(t * t, 2)] }   // e^(tH), the Chern character of O(t)
fn pol(a: P, v: &str) -> String {                      // a0 + a1 v + a2 v^2, fractions in brackets
    let mut out = s(a[0]);
    for k in 1..3 {
        let x = a[k];
        let co = if x == int(1) { String::new() } else if x.d == 1 { s(x) } else { format!("({})", s(x)) };
        out += &format!(" + {}{}{}", co, v, if k == 2 { "^2" } else { "" });
    }
    out
}
fn h0(d: i128) -> i128 { let mut n = 0; for a in 0..=d { for _b in 0..=(d - a) { n += 1; } } n }
fn h2(d: i128) -> i128 { let mut n = 0; for a in d..0 { for b in d..0 { if d - a - b <= -1 { n += 1; } } } n }
fn rank(m: &Vec<Vec<i128>>) -> usize {                 // exact rank by Gaussian elimination
    let mut m: Vec<Vec<Fr>> = m.iter().map(|r| r.iter().map(|&x| int(x)).collect()).collect();
    let mut r = 0;
    for col in 0..m[0].len() {
        let piv = (r..m.len()).find(|&i| m[i][col].n != 0);
        if piv.is_none() { continue; }
        m.swap(r, piv.unwrap());
        for i in r + 1..m.len() {
            let f = divf(m[i][col], m[r][col]);
            for j in 0..m[i].len() { m[i][j] = sub(m[i][j], mulf(f, m[r][j])); }
        }
        r += 1;
    }
    r
}
fn monos(n: u32) -> Vec<(u32, u32, u32)> { let mut v = vec![]; for a in 0..=n { for b in 0..=(n - a) { v.push((a, b, n - a - b)); } } v }
fn ev(p: (i128, i128, i128), m: (u32, u32, u32)) -> i128 { p.0.pow(m.0) * p.1.pow(m.1) * p.2.pow(m.2) }
fn triples(n: usize) -> Vec<(usize, usize, usize)> {
    let mut v = vec![];
    for i in 0..n { for j in i + 1..n { for k in j + 1..n { v.push((i, j, k)); } } }
    v
}
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn main() {
    // The Todd class of P^2, two ways.  Euler sequence: T + O = O(1) + O(1) + O(1), Chern roots H, H, H.
    let q = inv([int(1), fr(-1, fact(2)), fr(1, fact(3))]);  // H / (1 - e^(-H)) = 1/((1 - e^(-H))/H)
    let td = mul(mul(q, q), q);                              // one factor per Chern root
    let one = [int(1), int(1), int(0)];
    let c = mul(mul(one, one), one);                         // c(T) = (1 + H)^3, Whitney's product rule
    let (c1, c2) = (c[1], c[2]);
    let td2 = [int(1), divf(c1, int(2)), divf(add(mulf(c1, c1), c2), int(12))];
    println!("road 1, the Todd class of P^2");
    println!("H/(1 - e^(-H)) = {}; cubed: td = {}", pol(q, "H"), pol(td, "H"));
    println!("c(T) = (1 + H)^3 = {}; 1 + c1/2 + (c1^2 + c2)/12 = {}", pol(c, "H"), pol(td2, "H"));
    assert!(td == td2 && td == [int(1), fr(3, 2), int(1)]);
    let chi = |d: i128| mul(exp_h(d), td)[2];
    let ds: Vec<i128> = (-6..5).collect();
    println!("road 1 against road 2 against road 3: line bundles O(d) on P^2");
    let row = |name: &str, f: &dyn Fn(i128) -> Fr| {
        let mut l = format!("{:<24}", name);
        for &d in &ds { l += &format!("{:>5}", s(f(d))); }
        println!("{}", l);
    };
    row("d", &|d| int(d));
    row("chi, Hirzebruch-RR", &|d| chi(d));
    row("h^0, monomials", &|d| int(h0(d)));
    row("h^2, negative monomials", &|d| int(h2(d)));
    row("(d + 1)(d + 2)/2", &|d| fr((d + 1) * (d + 2), 2));
    row("1 + D.(D - K)/2, K = -3H", &|d| add(int(1), fr(d * (d + 3), 2)));
    for &d in &ds { assert!(chi(d) == int(h0(d) + h2(d)) && chi(d) == fr((d + 1) * (d + 2), 2) && chi(d) == add(int(1), fr(d * (d + 3), 2))); }
    let ch3 = exp_h(3);
    println!("d = 3: ch = {}; H^2 terms {} + {} + {} = {} plane cubics", pol(ch3, "H"), s(ch3[2]), s(mulf(ch3[1], td[1])), s(td[2]), s(chi(3)));
    let sym = ds.iter().all(|&d| chi(d) == chi(-3 - d));
    println!("Serre symmetry chi(O(d)) = chi(O(-3 - d)) for d = -6 to 4: {}", yn(sym));

    println!("the tangent bundle T of P^2");
    let e1 = exp_h(1);
    let cht = [sub(mulf(int(3), e1[0]), int(1)), mulf(int(3), e1[1]), mulf(int(3), e1[2])];  // 3e^H - 1
    let c2n = divf(sub(mulf(cht[1], cht[1]), mulf(int(2), cht[2])), int(2));  // ch2 = (c1^2 - 2 c2)/2
    let w = [0, 1, 2];                                       // the flow (x : y : z) -> (x : e^t y : e^2t z)
    let mut zeros: Vec<String> = vec![];
    for mask in [1u32, 2, 4, 3, 5, 6, 7] {                   // which coordinates are nonzero, in the Python's order
        let on = |i: usize| mask >> i & 1 == 1;
        let mut ok = true;                                   // (x, y, z) parallel to (0x, 1y, 2z)
        for i in 0..3 { for j in i + 1..3 { if on(i) && on(j) && w[i] != w[j] { ok = false; } } }
        let c: Vec<&str> = (0..3).map(|i| if !on(i) { "0" } else if mask.count_ones() > 1 { "*" } else { "1" }).collect();
        if ok { zeros.push(format!("({})", c.join(" : "))); }   // * = any nonzero value
    }
    let chit = mul(cht, td)[2];
    let euler_seq = int(3 * (h0(1) + h2(1)) - (h0(0) + h2(0)));  // Euler sequence, with the Cech counts
    println!("ch(T) = {}; c2 from ch2 = {}; c2 from (1 + H)^3 = {}", pol(cht, "H"), s(c2n), s(c2));
    println!("zeros of the vector field ({}x, {}y, {}z): {}, at {}", w[0], w[1], w[2], zeros.len(), zeros.join(", "));
    println!("chi(T) by HRR = {}; by the Euler sequence and Cech counts 3 x {} - {} = {}; 3 x 3 matrices mod scalars: {}", s(chit), h0(1) + h2(1), h0(0) + h2(0), s(euler_seq), 9 - 1);
    assert!(c2n == c2 && c2 == int(zeros.len() as i128) && zeros.len() == 3 && chit == euler_seq && chit == int(8));

    println!("the cubic surface S: P^2 blown up at 6 points");
    let cs = mul([int(1), int(4), int(6)], inv([int(1), int(3), int(0)]));  // (1 + h)^4 / (1 + 3h), h^2 = 3
    let (k2_hyp, e_hyp) = (mulf(mulf(cs[1], cs[1]), int(3)), mulf(cs[2], int(3)));
    let (k2_blow, e_blow) = (9 - 6, 3 + 6);                  // each blow-up: K^2 down 1, Euler number up 1
    let chi_o = divf(add(k2_hyp, e_hyp), int(12));           // Noether's formula
    let chi_anti_k = add(chi_o, divf(mulf(int(2), k2_hyp), int(2)));  // D = -K: (-K).(-2K)/2 = K^2
    let pts: Vec<(i128, i128, i128)> = vec![(1, 0, 0), (0, 1, 0), (0, 0, 1), (1, 1, 1), (1, 2, 3), (1, 3, 2)];
    let lines_ok = triples(6).iter().all(|&(i, j, k)| rank(&vec![
        vec![pts[i].0, pts[i].1, pts[i].2], vec![pts[j].0, pts[j].1, pts[j].2], vec![pts[k].0, pts[k].1, pts[k].2]]) == 3);
    let mat = |n: u32| -> Vec<Vec<i128>> { pts.iter().map(|&p| monos(n).iter().map(|&m| ev(p, m)).collect()).collect() };
    let (conic_rank, cubic_rank) = (rank(&mat(2)), rank(&mat(3)));
    println!("c(T_S) = {}, h^2 = 3 points: K^2 = {}, Euler number = {}; by blow-ups {} and {}", pol(cs, "h"), s(k2_hyp), s(e_hyp), k2_blow, e_blow);
    println!("Noether chi(O_S) = (K^2 + e)/12 = ({} + {})/12 = {}; Riemann-Roch chi(-K) = 1 + K^2 = {}", s(k2_hyp), s(e_hyp), s(chi_o), s(chi_anti_k));
    let ps: Vec<String> = pts.iter().map(|p| format!("({} : {} : {})", p.0, p.1, p.2)).collect();
    println!("points {}: no 3 on a line {}; conic rank {} of 6", ps.join(", "), yn(lines_ok), conic_rank);
    println!("plane cubics through them: 10 - rank {} = {} = sections of -K, so S sits in P^3", cubic_rank, 10 - cubic_rank);
    assert!(k2_hyp == int(k2_blow) && k2_blow == 3 && e_hyp == int(e_blow) && e_blow == 9 && chi_o == int(1));
    assert!(sym && lines_ok && conic_rank == 6 && chi_anti_k == int(10 - cubic_rank as i128) && cubic_rank == 6);

    println!("what breaks");
    println!("mistake 1, no Todd class: chi(O(3)) = H^2 term of ch = {}, not a whole number", s(ch3[2]));
    println!("mistake 2, td cut to 1 + c1/2: chi(O(3)) = {}, short by chi(O) = {}", s(add(ch3[2], mulf(ch3[1], td[1]))), s(chi(0)));
    let aff: Vec<i128> = [3, 6, 9].iter().map(|&n| { let mut k = 0; for a in 0..=n { for _b in 0..=(n - a) { k += 1; } } k }).collect();
    println!("mistake 3, the open plane A^2, not compact: polynomials of degree <= 3, 6, 9: {}, {}, {}, no limit", aff[0], aff[1], aff[2]);
    println!("mistake 4, chi read as h^0 at d = -4: h^0 = {}, but chi = {}, all in h^2", h0(-4), s(chi(-4)));
    println!("mistake 5, c2 taken as c1^2: Euler number {}, not {}", s(mulf(c1, c1)), s(c2));
    assert!(ch3[2] == fr(9, 2) && h0(-4) == 0 && h2(-4) == 3 && aff == vec![10, 28, 55]);
    println!("ALL CHECKS PASS");
}
