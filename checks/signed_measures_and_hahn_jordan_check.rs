// Signed measures, Hahn and Jordan -- the same check as the Python, in Rust,
// no crates.  Exact arithmetic by hand: every die probability is a whole
// number of thirtieths, so nothing on the die is rounded.
// The die: P fair, Q loaded (0.1, 0.1, 0.1, 0.1, 0.2, 0.4), nu = Q - P.
// Road 1: the definition -- test all 64 events for positivity by testing every
//         subset, as the Hahn proof's "largest positive set" does.
// Road 2: the sign of q_i - p_i face by face, as a density would give it.
// Road 3: total variation as the best sum |nu(E_1)| + ... over all 203 ways
//         to cut the six faces into blocks; and the distance by brute force.
// Bus waits: rate 1 against rate 2, by bisection and midpoint integration.
// The code checks these examples exactly; only the proof covers every space.
const P: [i64; 6] = [5, 5, 5, 5, 5, 5]; // thirtieths
const Q: [i64; 6] = [3, 3, 3, 3, 6, 12];

fn d6(x: i64) -> String { format!("{:.6}", x as f64 / 30.0) }
fn faces(m: usize) -> String {
    let v: Vec<String> = (0..6).filter(|i| m >> i & 1 == 1).map(|i| (i + 1).to_string()).collect();
    format!("{{{}}}", v.join(", "))
}
fn size(w: &[i64], m: usize) -> i64 { (0..6).filter(|i| m >> i & 1 == 1).map(|i| w[i]).sum() }
fn subs(m: usize) -> Vec<usize> { (0..64).filter(|b| b & m == *b).collect() }
fn row(w: &[i64]) -> String { w.iter().map(|&x| d6(x)).collect::<Vec<_>>().join(" ") }

// every way to cut six faces into blocks: block labels in restricted-growth form
fn partitions(labels: &mut Vec<usize>, top: usize, out: &mut Vec<Vec<usize>>) {
    if labels.len() == 6 { out.push(labels.clone()); return; }
    for b in 0..=top {
        labels.push(b);
        partitions(labels, if b == top { top + 1 } else { top }, out);
        labels.pop();
    }
}

fn main() {
    let nu: Vec<i64> = (0..6).map(|i| Q[i] - P[i]).collect();
    println!("face: p_i fair | q_i loaded | nu = q_i - p_i");
    for i in 0..6 { println!("face {}: {} | {} | {}", i + 1, d6(P[i]), d6(Q[i]), d6(nu[i])); }

    // Road 1: positive set = every subset has nu >= 0; negative = every subset <= 0
    let pos: Vec<usize> = (0..64).filter(|&m| subs(m).iter().all(|&b| size(&nu, b) >= 0)).collect();
    let neg: Vec<usize> = (0..64).filter(|&m| subs(m).iter().all(|&b| size(&nu, b) <= 0)).collect();
    let mut m_best = pos[0];
    for &m in &pos { if size(&nu, m) > size(&nu, m_best) { m_best = m; } }
    let hahn: Vec<usize> = pos.iter().copied().filter(|&m| neg.contains(&(63 ^ m))).collect();
    println!("road 1, events tested: 64; positive sets: {}; negative sets: {}", pos.len(), neg.len());
    println!("road 1, largest nu over positive sets: {} at {}", d6(size(&nu, m_best)), faces(m_best));
    println!("road 1, Hahn splits found: {}: {} and {}", hahn.len(), faces(hahn[0]), faces(63 ^ hahn[0]));

    // Road 2: the sign of each face's difference
    let plus: usize = (0..6).filter(|&i| nu[i] > 0).map(|i| 1usize << i).sum();
    println!("road 2, faces with q_i > p_i: {}; faces with q_i < p_i: {}", faces(plus), faces(63 ^ plus));
    assert!(hahn == vec![plus] && pos == subs(plus) && neg == subs(63 ^ plus));

    // Jordan: nu+(A) = nu(A n Omega+), nu-(A) = -nu(A n Omega-)
    let nplus: Vec<i64> = nu.iter().map(|&x| x.max(0)).collect();
    let nminus: Vec<i64> = nu.iter().map(|&x| (-x).max(0)).collect();
    let (jp, jm) = (size(&nplus, 63), size(&nminus, 63));
    assert!(jp == size(&nu, m_best));
    println!("Jordan, nu+ by face: {}", row(&nplus));
    println!("Jordan, nu- by face: {}", row(&nminus));
    println!("Jordan, nu+(Omega) {} | nu-(Omega) {} | nu(Omega) {}", d6(jp), d6(jm), d6(size(&nu, 63)));

    let mut parts = Vec::new();
    partitions(&mut Vec::new(), 0, &mut parts);
    let mut best_cut = 0;
    for pt in &parts {
        let nb = pt.iter().max().unwrap() + 1;
        let cut: i64 = (0..nb).map(|b| (0..6).filter(|&i| pt[i] == b).map(|i| nu[i]).sum::<i64>().abs()).sum();
        best_cut = best_cut.max(cut);
    }
    let tv_abs: i64 = nu.iter().map(|x| x.abs()).sum();
    assert!(parts.len() == 203 && best_cut == jp + jm);
    println!("total variation |nu|(Omega): nu+ + nu- {} | sum |q_i - p_i| {} | best of {} partitions {}",
             d6(jp + jm), d6(tv_abs), parts.len(), d6(best_cut));

    let gaps: Vec<i64> = (0..64).map(|m| (size(&Q, m) - size(&P, m)).abs()).collect();
    let dist = *gaps.iter().max().unwrap();
    let winners: Vec<String> = (0..64).filter(|&m| gaps[m] == dist).map(faces).collect();
    let overlap: i64 = (0..6).map(|i| P[i].min(Q[i])).sum();
    assert!(2 * dist == tv_abs && dist == 30 - overlap);
    println!("distance, max over 64 events |Q(A) - P(A)|: {} at {}", d6(dist), winners.join(" and "));
    // tv_abs is even (checked above), so the halving below is exact
    println!("distance, half of |nu|(Omega): {} | sum min(p_i, q_i): {}, 1 minus it {}", d6(tv_abs / 2), d6(overlap), d6(30 - overlap));
    println!("distance, Q({{5, 6}}) {} - P({{5, 6}}) {}", d6(size(&Q, 48)), d6(size(&P, 48)));

    // any other split nu = mu1 - mu2 costs more: here mu1 = Q, mu2 = P
    let extra: Vec<i64> = (0..6).map(|i| Q[i] - nplus[i]).collect();
    assert!(size(&Q, 63) + size(&P, 63) > jp + jm);
    println!("other split Q - P: Q(Omega) + P(Omega) = {} against |nu|(Omega) {}; Q - nu+ by face: {}",
             d6(size(&Q, 63) + size(&P, 63)), d6(jp + jm), row(&extra));

    // what breaks
    println!("breaks, {{4, 5, 6}}: nu = {} > 0, but nu({{4}}) = {}: not a positive set", d6(size(&nu, 0b111000)), d6(nu[3]));
    println!("breaks, |nu(Omega)| read as total variation: {}", d6(size(&nu, 63).abs()));
    println!("breaks, full sum read as the distance: {}", d6(tv_abs));
    let sign = |k: i64| if k % 2 == 0 { 1i64 } else { -1 }; // evens minus odds, counting measure
    let order2: Vec<i64> = (1..=1000i64).flat_map(|t| [4 * t - 2, 4 * t, 2 * t - 1]).collect();
    let run = |ks: &[i64]| -> Vec<i64> { let mut s = 0; ks.iter().map(|&k| { s += sign(k); s }).collect() };
    let nat = run(&(1..=3000i64).collect::<Vec<_>>());
    let re2 = run(&order2);
    assert!(nat[2999] == 0 && re2[2999] == 2000 - 1000);
    let first = |v: &[i64]| v[..9].iter().map(|x| x.to_string()).collect::<Vec<_>>().join(" ");
    println!("breaks, evens minus odds, order 1, 2, 3, ...: partial sums {} ... after 3000: {}", first(&nat), nat[2999]);
    println!("breaks, evens minus odds, order 2, 4, 1, 6, 8, 3, ...: {} ... after 3000: {}", first(&re2), re2[2999]);

    // bus waits in minutes: P rate 1, Q rate 2; nu = Q - P has density fQ - fP
    let f_p = |x: f64| (-x).exp();
    let f_q = |x: f64| 2.0 * (-2.0 * x).exp();
    let (mut lo, mut hi) = (0.0f64, 5.0f64); // bisection for fQ = fP
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if f_q(mid) > f_p(mid) { lo = mid } else { hi = mid }
    }
    let cross = (lo + hi) / 2.0;
    let midpoint = |g: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize| -> f64 {
        let h = (b - a) / n as f64;
        h * (0..n).map(|k| g(a + (k as f64 + 0.5) * h)).sum::<f64>()
    };
    let nu_plus = midpoint(&|x| f_q(x) - f_p(x), 0.0, cross, 100000);
    let tv_bus = midpoint(&|x| (f_q(x) - f_p(x)).abs(), 0.0, 40.0, 400000);
    let ln2 = 2f64.ln();
    let closed = (-ln2).exp() - (-2.0 * ln2).exp();
    let mut scan = (f64::MIN, 0.0);
    for k in 1..=5000 {
        let t = k as f64 / 1000.0;
        let v = (-t).exp() - (-2.0 * t).exp();
        if v > scan.0 || (v == scan.0 && t > scan.1) { scan = (v, t); }
    }
    assert!((cross - ln2).abs() < 1e-12 && (nu_plus - closed).abs() < 1e-8);
    assert!((tv_bus - 2.0 * closed).abs() < 1e-6 && (scan.0 - closed).abs() < 1e-6);
    println!("bus, densities cross at (bisection): {:.6} min; ln 2 = {:.6}", cross, ln2);
    println!("bus, nu+ = integral of fQ - fP up to the crossing: {:.6}; closed form {:.6}", nu_plus, closed);
    println!("bus, best wait window [0, t] on a grid: t = {:.3}, Q - P = {:.6}", scan.1, scan.0);
    println!("bus, |nu|(Omega) = integral of |fQ - fP|: {:.6}; distance {:.6}", tv_bus, tv_bus / 2.0);
    let xs: Vec<f64> = (0..13).map(|k| k as f64 / 4.0).collect();
    let line = |g: &dyn Fn(f64) -> f64| xs.iter().map(|&x| format!("{:.2}", g(x))).collect::<Vec<_>>().join(" ");
    println!("chart, wait x min: {}", line(&|x| x));
    println!("chart, fP rate 1: {}", line(&f_p));
    println!("chart, fQ rate 2: {}", line(&f_q));
    let bars: Vec<String> = nu.iter().map(|&x| (140 - 15 * x).to_string()).collect();
    println!("figure, bar ends y (450 px per unit, baseline 140): {}", bars.join(" "));
    println!("ALL CHECKS PASS");
}
