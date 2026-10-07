// Buckingham Pi on cyclist drag -- the check behind the card. Rust std only.
// Road 1: exact elimination on the dimension matrix gives the rank and the groups.
// Road 2: brute force over every half-step exponent finds the dimensionless products.
// Road 3: a change of units leaves the groups unchanged. Road 4: nine setups collapse.
#[derive(Clone, Copy, PartialEq)]
struct Q { n: i64, d: i64 }               // an exact fraction n/d, d > 0, lowest terms
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i64, d: i64) -> Q { let g = gcd(n, d).max(1) * d.signum(); Q { n: n / g, d: d / g } }
fn sub(a: Q, b: Q) -> Q { q(a.n * b.d - b.n * a.d, a.d * b.d) }
fn mul(a: Q, b: Q) -> Q { q(a.n * b.n, a.d * b.d) }
fn div(a: Q, b: Q) -> Q { q(a.n * b.d, a.d * b.n) }
fn fmt(a: Q) -> String { if a.d == 1 { format!("{}", a.n) } else { format!("{}/{}", a.n, a.d) } }

fn rref(rows: &[Vec<i64>]) -> (Vec<Vec<Q>>, Vec<usize>) {
    let mut m: Vec<Vec<Q>> = rows.iter().map(|r| r.iter().map(|&x| q(x, 1)).collect()).collect();
    let (mut piv, mut r) = (vec![], 0);
    let cols = if m.is_empty() { 0 } else { m[0].len() };
    for c in 0..cols {
        let p = match (r..m.len()).find(|&i| m[i][c].n != 0) { Some(p) => p, None => continue };
        m.swap(r, p);
        let lead = m[r][c];
        m[r] = m[r].iter().map(|&x| div(x, lead)).collect();
        for i in 0..m.len() {
            if i != r && m[i][c].n != 0 {
                let f = m[i][c];
                let row_r = m[r].clone();
                m[i] = m[i].iter().zip(row_r.iter()).map(|(&a, &b)| sub(a, mul(f, b))).collect();
            }
        }
        piv.push(c); r += 1;
        if r == m.len() { break; }
    }
    (m, piv)
}

fn kernel(rows: &[Vec<i64>]) -> (Vec<Vec<Q>>, usize) {
    let (m, piv) = rref(rows);
    let n = rows[0].len();
    let mut out = vec![];
    for fc in (0..n).filter(|c| !piv.contains(c)) {
        let mut v = vec![q(0, 1); n];
        v[fc] = q(1, 1);
        for (i, &pc) in piv.iter().enumerate() { v[pc] = sub(q(0, 1), m[i][fc]); }
        out.push(v);
    }
    (out, piv.len())
}

fn show(v: &[Q]) -> String { v.iter().map(|&x| format!("{:>4}", fmt(x))).collect::<Vec<_>>().join(" ") }
fn law(rho: f64, mu: f64, a: f64, v: f64) -> f64 {      // stand-in experiment, no group written in it
    0.5 * 0.65 * rho * v * v * a + 17.5 * (rho * mu).sqrt() * v.powf(1.5) * a.powf(0.75)
}
fn groups(x: [f64; 5]) -> (f64, f64) { (x[3] / (x[0] * x[1] * x[1] * x[2]), x[4] / (x[0] * x[1] * x[2].sqrt())) }
fn atmos(h: f64) -> (f64, f64, f64) {                   // US Standard Atmosphere 1976, troposphere
    let t = 288.15 - 0.0065 * h;
    let p = 101325.0 * (t / 288.15).powf(5.255877);
    (p / (287.05287 * t), 1.458e-6 * t.powf(1.5) / (t + 110.4), (1.4 * 287.05287 * t).sqrt())
}
fn master(re: f64) -> f64 { 0.65 + 35.0 / re.sqrt() }

fn main() {
    let names = ["rho", "V", "A", "F", "mu"];
    let dims: Vec<Vec<i64>> = vec![vec![1, 0, 0, 1, 1], vec![-3, 1, 2, 1, -1], vec![0, -1, 0, -2, -1]];
    println!("dimension matrix, columns {}", names.iter().map(|s| format!("{:>4}", s)).collect::<Vec<_>>().join(" "));
    for (lab, r) in ["M", "L", "T"].iter().zip(dims.iter()) {
        let rq: Vec<Q> = r.iter().map(|&x| q(x, 1)).collect();
        println!("  {}  {}{}", lab, " ".repeat(21), show(&rq));
    }
    let (basis, k) = kernel(&dims);
    println!("variables n = {}, rank k = {}, groups n - k = {}", names.len(), k, basis.len());
    for (name, v) in ["Pi_F ", "Pi_mu"].iter().zip(basis.iter()) { println!("{} exponents rho V A F mu: {}", name, show(v)); }

    let mut found: Vec<Vec<i64>> = vec![];
    for code in 0..9i64.pow(5) {
        let e: Vec<i64> = (0..5).map(|j| (code / 9i64.pow(j)) % 9 - 4).collect();
        if dims.iter().all(|r| r.iter().zip(e.iter()).map(|(d, x)| d * x).sum::<i64>() == 0) { found.push(e); }
    }
    let mut from_basis = 0;
    for a in -4i64..5 {
        for b in -4i64..5 {
            if b % 2 != 0 { continue; }
            let v = [-a - b, -2 * a - b, -a - b / 2, a, b];
            if v.iter().all(|&x| (-4..=4).contains(&x)) { from_basis += 1; }
        }
    }
    let brute_rank = rref(&found).1.len();
    println!("brute force: {} dimensionless products in the box, {} predicted from the two groups", found.len(), from_basis);
    println!("brute force: those products span {} independent directions", brute_rank);

    let (rho, mu, a_full, v): (f64, f64, f64, f64) = (1.225, 1.7894e-5, 0.40, 12.0);
    let f = law(rho, mu, a_full, v);
    let (g, cm, mn) = (1000.0, 100.0, 1.0 / 60.0);
    let conv = [g / (cm * cm * cm), cm / mn, cm * cm, g * cm / (mn * mn), g / (cm * mn)];
    let old = [rho, v, a_full, f, mu];
    let mut new = [0.0; 5];
    for i in 0..5 { new[i] = old[i] * conv[i]; }
    let (p_si, p_new) = (groups(old), groups(new));
    let (bad_si, bad_new) = (f / (rho * v * a_full), new[3] / (new[0] * new[1] * new[2]));
    println!("units: F = {:.4} N in SI, {:.6} x 10^9 g cm/min^2 in the new units", f, new[3] / 1e9);
    println!("units: Pi_F  SI {:.6}  new {:.6}", p_si.0, p_new.0);
    println!("units: Pi_mu x 10^6 SI {:.6}  new {:.6}", p_si.1 * 1e6, p_new.1 * 1e6);
    println!("units: wrong F/(rho V A) SI {:.6}  new {:.6}", bad_si, bad_new);

    let (l, re) = (a_full.sqrt(), rho * v * a_full.sqrt() / mu);
    let cd = f / (0.5 * rho * v * v * a_full);
    println!("cyclist: sqrt(A) = {:.4} m, Re = {:.0}, C_D = {:.4}, Pi_F = {:.4}", l, re, cd, cd / 2.0);
    println!("cyclist: sqrt(Re) = {:.1}, 35/sqrt(Re) = {:.4}, 0.5 rho V^2 A = {:.2} N", re.sqrt(), 35.0 / re.sqrt(), 0.5 * rho * v * v * a_full);
    println!("cyclist: drag F = {:.2} N, power F V = {:.1} W", f, f * v);

    let mut setups = vec![];
    for h in [0.0, 2000.0, 4000.0] { for a in [0.40f64, 0.10, 0.025] { setups.push((h, a)); } }
    let mut spread_ok = true;
    for target in [2e4, 5e4, 1e5, 2e5, 5e5, 1e6] {
        let (mut cs, mut fs) = (vec![], vec![]);
        for &(h, a) in &setups {
            let (r, m, _) = atmos(h);
            let vv = target * m / (r * a.sqrt());
            let ff = law(r, m, a, vv);
            cs.push(ff / (0.5 * r * vv * vv * a)); fs.push(ff);
        }
        let mx = |x: &Vec<f64>| x.iter().cloned().fold(f64::MIN, f64::max);
        let mn_ = |x: &Vec<f64>| x.iter().cloned().fold(f64::MAX, f64::min);
        spread_ok &= mx(&cs) - mn_(&cs) < 1e-12 && (cs[0] - master(target)).abs() < 1e-12;
        println!("collapse Re {:>9.0}: C_D {:.4} in all 9 setups; raw F {:.4} N to {:.4} N", target, cs[0], mn_(&fs), mx(&fs));
    }
    println!("collapse: one curve, spread below 1e-12: {}", if spread_ok { "yes" } else { "no" });

    let fig: Vec<String> = [2e4, 5e4, 1e5, 2e5, 5e5, 1e6].iter().map(|&x| format!("{:.2}", master(x))).collect();
    println!("figure, C_D at Re 2e4 5e4 1e5 2e5 5e5 1e6: {}", fig.join(" "));
    println!("figure, C_D if viscosity is left off (one constant): {:.2}", cd);
    println!("figure, raw drag in N at V = 4 8 12 16 20 24 m/s");
    for (lab, h, a) in [("full size, sea level", 0.0, 0.40), ("full size, 4000 m", 4000.0, 0.40), ("half scale, sea level", 0.0, 0.10)] {
        let (r, m, _) = atmos(h);
        let pts: Vec<String> = [4.0, 8.0, 12.0, 16.0, 20.0, 24.0].iter().map(|&vv| format!("{:.2}", law(r, m, a, vv))).collect();
        println!("  {:<22}{}", lab, pts.join(" "));
    }

    let (q_a, q_re) = (0.025f64, rho * v * 0.025f64.sqrt() / mu);
    let q_cd = law(rho, mu, q_a, v) / (0.5 * rho * v * v * q_a);
    println!("no viscosity: quarter-scale model at 12 m/s, Re = {:.0}, C_D = {:.4}", q_re, q_cd);
    println!("no viscosity: full-size drag predicted {:.2} N, true {:.2} N", 0.5 * rho * v * v * a_full * q_cd, f);
    let (h_v, h_f) = (2.0 * v, law(rho, mu, 0.10, 2.0 * v));
    println!("similar model: half scale at {:.0} m/s, Re = {:.0}, drag {:.2} N", h_v, rho * h_v * 0.10f64.sqrt() / mu, h_f);
    let mut with_theta = dims.clone();
    with_theta.push(vec![0, 0, 0, 0, 0]);
    let (_, k4) = kernel(&with_theta);
    println!("names vs rank: 4 dimension names, rank {}, groups {} (not {})", k4, 5 - k4, 5 - 4);
    let with_c: Vec<Vec<i64>> = dims.iter().zip([0, 1, -1]).map(|(r, c)| { let mut x = r.clone(); x.push(c); x }).collect();
    let (bc, kc) = kernel(&with_c);
    let (r0, m0, c0) = atmos(0.0);
    println!("add sound speed c = {:.2} m/s: n = 6, rank {}, groups {}", c0, kc, bc.len());
    println!("Mach V/c: cyclist {:.4}, at 150 m/s {:.4}", v / c0, 150.0 / c0);
    println!("try: C_D at Re 1e7 {:.4}, at Re 1000 {:.4}", master(1e7), master(1e3));

    assert_eq!(basis.len(), brute_rank, "elimination vs brute force");
    assert!(k == 3 && basis.len() == 2 && k4 == 3 && bc.len() == 3, "the counts the card states");
    assert!((0.5 * rho * v * v * a_full * q_cd / f - 1.0).abs() > 0.05, "dropping viscosity mispredicts");
    let mut via = [1.0f64, 1.0];                  // the elimination's exponents, applied
    for (i, b) in basis.iter().enumerate() {
        for (x, e) in old.iter().zip(b.iter()) { via[i] *= x.powf(e.n as f64 / e.d as f64); }
    }
    assert!((via[0] / p_si.0 - 1.0).abs() < 1e-12 && (via[1] / p_si.1 - 1.0).abs() < 1e-12, "match the groups written out by hand");
    assert_eq!(found.len(), from_basis, "brute count vs count built from the groups");
    assert!((p_si.0 / p_new.0 - 1.0).abs() < 1e-12 && (p_si.1 / p_new.1 - 1.0).abs() < 1e-12, "groups survive the unit change");
    assert!((bad_new / bad_si - 1.0).abs() > 0.1, "a non-group does not");
    assert!(spread_ok, "raw law at nine setups vs the master curve");
    assert!((h_f - f).abs() < 1e-9 * f, "half-scale run of the law equals full size");
    assert!((r0 - 1.225).abs() < 1e-3 && (m0 - 1.7894e-5).abs() < 1e-8 && (atmos(4000.0).0 - 0.8194).abs() < 1e-3, "the standard's table, 0 m and 4000 m");
    println!("all checks passed");
}
