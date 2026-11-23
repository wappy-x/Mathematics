// Relaxation and rounding -- the check behind the card.  std only, no crates.
// Part 1: a ward rota.  Each nurse works 5 days in a row, then has 2 off.
// Part 2: two weekend teams, split by a semidefinite relaxation and a random plane.
use std::f64::consts::PI;
const DAYS: [&str; 7] = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
const NEED: [f64; 7] = [12.0, 11.0, 11.0, 10.0, 12.0, 8.0, 7.0]; // nurses needed each day
type V = Vec<f64>;
fn a(i: usize, j: usize) -> f64 { if (i + 7 - j) % 7 < 5 { 1.0 } else { 0.0 } } // day i, pattern j
fn pat(j: usize) -> String { format!("{}-{}", DAYS[j], DAYS[(j + 4) % 7]) }
fn cover(x: &[f64]) -> V { (0..7).map(|i| (0..7).map(|j| a(i, j) * x[j]).sum()).collect() }
fn short(x: &[f64]) -> Vec<&'static str> {
    let c = cover(x); (0..7).filter(|&i| c[i] < NEED[i] - 1e-9).map(|i| DAYS[i]).collect() }
fn ints(x: &[f64]) -> String { format!("[{}]", x.iter().map(|v| format!("{}", *v as i64)).collect::<Vec<_>>().join(", ")) }
fn solve(m0: &[V], b: &[f64]) -> Option<V> {          // Gaussian elimination; None if singular
    let n = m0.len();
    let mut m: Vec<V> = m0.iter().zip(b).map(|(r, &c)| { let mut r = r.clone(); r.push(c); r }).collect();
    for c in 0..n {
        let mut p = c;
        for r in c..n { if m[r][c].abs() > m[p][c].abs() { p = r; } }
        if m[p][c].abs() < 1e-12 { return None; }
        m.swap(c, p);
        for r in 0..n { if r != c { let f = m[r][c] / m[c][c];
            for k in 0..=n { m[r][k] = m[r][k] - f * m[c][k]; } } }
    }
    Some((0..n).map(|i| m[i][n] / m[i][i]).collect())
}
fn corners(rows: &[V], rhs: &[f64], fits: &dyn Fn(&V) -> bool, score: &dyn Fn(&V) -> f64) -> (V, usize) {
    let (mut best, mut seen): (Option<V>, usize) = (None, 0);
    let mut s: Vec<usize> = (0..7).collect();        // every 7 of 14, in Python's order
    loop {
        let m: Vec<V> = s.iter().map(|&k| rows[k].clone()).collect();
        let b: V = s.iter().map(|&k| rhs[k]).collect();
        if let Some(x) = solve(&m, &b) { if fits(&x) { seen += 1;
            if best.as_ref().map_or(true, |bb| score(&x) < score(bb) - 1e-9) { best = Some(x); } } }
        let mut i = 7;
        while i > 0 && s[i - 1] == i - 1 + 7 { i -= 1; }
        if i == 0 { break; }
        s[i - 1] += 1; for k in i..7 { s[k] = s[k - 1] + 1; }
    }
    (best.unwrap(), seen)
}
fn rotas(total: usize, k: usize, pre: &mut V, out: &mut Vec<V>) {
    if k == 1 { pre.push(total as f64); out.push(pre.clone()); pre.pop(); return; }
    for v in 0..=total { pre.push(v as f64); rotas(total - v, k - 1, pre, out); pre.pop(); }
}
struct Rng(u64);
impl Rng { fn next(&mut self) -> f64 {                // SplitMix64, written out
    self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15); let mut z = self.0;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9); z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0 } }
fn dot(u: &[f64], v: &[f64]) -> f64 { u.iter().zip(v).map(|(a, b)| a * b).sum() }
fn relax(e: &[(usize, usize)], n: usize, alpha: f64) -> (Vec<V>, Vec<V>, Vec<usize>, f64, f64) {
    let cut = |side: &[bool]| e.iter().filter(|&&(a, b)| side[a] != side[b]).count();
    let cuts: Vec<usize> = (0..1usize << n).map(|m| cut(&(0..n).map(|i| (m >> i) & 1 == 1).collect::<Vec<_>>())).collect();
    let mut v: Vec<V> = (0..n).map(|i| (0..n).map(|t| (1.0 * i as f64 + 0.7 * t as f64 * (i + 1) as f64).cos()).collect()).collect();
    for _ in 0..3000 { for i in 0..n {                  // each vector turns away from its partners
        let g: V = (0..n).map(|k| -e.iter().filter(|&&(a, b)| a == i || b == i)
            .map(|&(a, b)| v[if a == i { b } else { a }][k]).sum::<f64>()).collect();
        let nr = dot(&g, &g).sqrt(); v[i] = g.iter().map(|c| c / nr).collect(); } }
    let xm: Vec<V> = v.iter().map(|uu| v.iter().map(|w| dot(uu, w)).collect()).collect();
    let inc = |i: usize| e.iter().filter(move |&&(a, b)| a == i || b == i);
    let u: V = (0..n).map(|i| inc(i).map(|&(a, b)| (1.0 - xm[a][b]) / 4.0).sum()).collect(); // dual prices
    let m: Vec<V> = (0..n).map(|i| (0..n).map(|j| if i == j { u[i] - inc(i).count() as f64 / 4.0 + 1e-9 }
        else if e.contains(&(i, j)) || e.contains(&(j, i)) { 0.25 } else { 0.0 }).collect()).collect();
    let mut lc = vec![vec![0.0; n]; n]; let mut psd = true;   // Cholesky of Diag(u) - L/4: works iff PSD
    for i in 0..n { for j in 0..=i {
        let s = m[i][j] - (0..j).map(|k| lc[i][k] * lc[j][k]).sum::<f64>();
        if i == j { psd = psd && s > 0.0; lc[i][i] = s.max(1e-300).sqrt(); } else { lc[i][j] = s / lc[j][j]; } } }
    let sdp: f64 = e.iter().map(|&(a, b)| (1.0 - xm[a][b]) / 2.0).sum();
    let expct: f64 = e.iter().map(|&(a, b)| xm[a][b].max(-1.0).min(1.0).acos() / PI).sum();
    assert!(psd && *cuts.iter().max().unwrap() as f64 <= sdp + 1e-9 && expct >= alpha * sdp - 1e-9);
    (v, xm, cuts, sdp, expct)
}
fn main() {
    let (mut alpha, mut tha) = (f64::INFINITY, 0.0);
    for k in 1..=200000 { let th = k as f64 * PI / 200000.0; let r = 2.0 * th / (PI * (1.0 - th.cos()));
        if r < alpha { alpha = r; tha = th; } }
    let am: Vec<V> = (0..7).map(|i| (0..7).map(|j| a(i, j)).collect()).collect();
    let id: Vec<V> = (0..7).map(|i| (0..7).map(|j| if i == j { 1.0 } else { 0.0 }).collect()).collect();
    let mut rows = am.clone(); rows.extend(id.clone());
    let mut rhs = NEED.to_vec(); rhs.extend([0.0; 7]);
    let fits = |x: &V| x.iter().cloned().fold(f64::INFINITY, f64::min) > -1e-9 && short(x).is_empty();
    let (x, nx) = corners(&rows, &rhs, &fits, &|x: &V| x.iter().sum());    // road 1
    let at: Vec<V> = (0..7).map(|j| (0..7).map(|i| am[i][j]).collect()).collect();
    let mut rows2 = at.clone(); rows2.extend(id.clone());
    let mut rhs2 = vec![1.0; 7]; rhs2.extend([0.0; 7]);
    let fits2 = |y: &V| y.iter().cloned().fold(f64::INFINITY, f64::min) > -1e-9
        && at.iter().all(|r| (0..7).map(|i| r[i] * y[i]).sum::<f64>() < 1.0 + 1e-9);
    let (y, ny) = corners(&rows2, &rhs2, &fits2, &|y: &V| -NEED.iter().zip(y).map(|(n, p)| n * p).sum::<f64>()); // road 2
    let lp: f64 = x.iter().sum(); let dual: f64 = NEED.iter().zip(&y).map(|(n, p)| n * p).sum();
    println!("days: {}", DAYS.join(" ")); println!("need: 12 11 11 10 12 8 7");
    println!("nurse-days needed 71; divided by 5 days a nurse: {:.2}", NEED.iter().sum::<f64>() / 5.0);
    println!("LP rota, best of {} bases in {} tries: {}", nx, (8..=14).product::<u64>() / (1..=7).product::<u64>(), (0..7).map(|j| format!("{} {:.2}", pat(j), x[j])).collect::<Vec<_>>().join(", "));
    println!("LP total {:.4} = {}/3; dual prices, best of {} bases: {}", lp, (3.0 * lp).round(), ny,
        (0..7).map(|i| format!("{} {:.2}", DAYS[i], y[i])).collect::<Vec<_>>().join(", "));
    println!("dual total {:.4}; floor on whole rotas: {}", dual, (lp - 1e-9).ceil());
    assert!((lp - dual).abs() < 1e-9 && (lp - 43.0 / 3.0).abs() < 1e-9);
    let up: V = x.iter().map(|v| (v - 1e-9).ceil()).collect();
    let frac = x.iter().filter(|v| (*v - v.round()).abs() > 1e-9).count();
    let near: V = x.iter().map(|v| v.round()).collect();
    let mut trim = up.clone();
    for j in 0..7 { loop { if trim[j] <= 0.0 { break; } let mut t = trim.clone(); t[j] -= 1.0;
        if short(&t).is_empty() { trim[j] -= 1.0; } else { break; } } }
    let sum = |v: &V| v.iter().sum::<f64>();
    println!("round up: {} = {} nurses; bound LP + {} fractional = {:.2}", ints(&up), sum(&up), frac, lp + frac as f64);
    println!("round to nearest: {} = {} nurses; short on {}", ints(&near), sum(&near), short(&near).join(" "));
    let st = short(&trim);
    println!("payroll cap of 15: round up hires {}, {} over; the trimmed rota fits", sum(&up), sum(&up) - 15.0);
    println!("round up then trim: {} = {} nurses; short on {}", ints(&trim), sum(&trim), if st.is_empty() { "none".to_string() } else { st.join(" ") });
    assert!(short(&up).is_empty() && sum(&up) <= lp + frac as f64 && !short(&near).is_empty() && short(&trim).is_empty());
    let (mut r14, mut r15) = (vec![], vec![]);
    rotas(14, 7, &mut vec![], &mut r14); rotas(15, 7, &mut vec![], &mut r15);
    let c14 = r14.iter().filter(|r| short(r).is_empty()).count(); let c15 = r15.iter().filter(|r| short(r).is_empty()).count();
    println!("brute force: {} rotas of 14, {} cover; {} rotas of 15 cover", r14.len(), c14, c15);
    assert!(c14 == 0 && c15 > 0 && sum(&trim) == 15.0);
    let base: V = x.iter().map(|v| (v + 1e-9).floor()).collect();
    let fr: Vec<usize> = (0..7).filter(|&j| x[j] - base[j] > 1e-9).collect();
    let p = x[fr[0]] - base[fr[0]];
    println!("random rounding: base {}, patterns {} each up with chance {:.4}", sum(&base), fr.iter().map(|&j| pat(j)).collect::<Vec<_>>().join(" "), p);
    let mut one = (0.0, 0.0);
    for t in 1..=4 {
        let q = 1.0 - (1.0 - p).powf(t as f64); let (mut cov, mut staff) = (0.0, 0.0);
        for m in 0..(1usize << fr.len()) {
            let mut z = base.clone(); let mut pr = 1.0;
            for (k, &j) in fr.iter().enumerate() { let b = (m >> (fr.len() - 1 - k)) & 1;
                z[j] += b as f64; pr *= if b == 1 { q } else { 1.0 - q }; }
            staff += pr * sum(&z); if short(&z).is_empty() { cov += pr; }
        }
        println!("  rounds {}: expected nurses {:.4}, all days covered {:.4}, union bound on failure {:.4}", t, staff, cov, 6.0 * (-(t as f64)).exp());
        assert!(1.0 - cov <= 6.0 * (-(t as f64)).exp() && staff <= sum(&base) + t as f64 * (lp - sum(&base)) + 1e-9);
        if t == 1 { one = (staff, cov); }
    }
    let mut rng = Rng(20261119); let n_draw = 100000; let (mut hit, mut tot) = (0usize, 0.0);
    for _ in 0..n_draw {
        let z: V = (0..7).map(|j| if fr.contains(&j) { base[j] + if rng.next() < p { 1.0 } else { 0.0 } } else { base[j] }).collect();
        if short(&z).is_empty() { hit += 1; } tot += sum(&z);
    }
    let nd = n_draw as f64;
    println!("  simulated, {} draws of 1 round, seed 20261119: mean nurses {:.4}, all covered {:.4}", n_draw, tot / nd, hit as f64 / nd);
    assert!((tot / nd - one.0).abs() < 4.0 * (4.0 * p * (1.0 - p) / nd).sqrt() && (hit as f64 / nd - one.1).abs() < 4.0 * (one.1 * (1.0 - one.1) / nd).sqrt());

    let e: Vec<(usize, usize)> = vec![(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (5, 0), (5, 1), (5, 2), (5, 3), (5, 4)]; // stand-in pairs
    let (v, xm, cuts, sdp, expct) = relax(&e, 6, alpha); let best = *cuts.iter().max().unwrap();
    let cut = |side: &[bool]| e.iter().filter(|&&(a, b)| side[a] != side[b]).count();
    println!("teams: {} pairs, best split {} (brute force over {} splits, {} reach it)", e.len(), best, 64, cuts.iter().filter(|&&c| c == best).count());
    println!("relaxation {:.6}, certified: Diag(u) - L/4 is PSD, for dual prices u built to sum to it", sdp);
    for (name, a, b) in [("ring neighbours", 0, 1), ("hub to ring", 5, 0)] {
        let th = xm[a][b].acos();
        println!("  {}: angle {:.2} deg, cos {:.4}, split chance {:.4}, share {:.4}, ratio {:.4}", name, th.to_degrees(), xm[a][b],
            th / PI, (1.0 - xm[a][b]) / 2.0, th / PI / ((1.0 - xm[a][b]) / 2.0)); }
    println!("expected split {:.6} >= alpha x relaxation {:.6}; alpha {:.6} at {:.2} deg", expct, alpha * sdp, alpha, tha.to_degrees());
    println!("ratio to relaxation {:.6}, to best split {:.6}", expct / sdp, expct / best as f64);
    assert!((alpha - 0.878567).abs() < 1e-6 && best == 7);
    let (_, _, cr, s5, e5) = relax(&e[..5], 5, alpha); let b5 = *cr.iter().max().unwrap();
    println!("ring of five only: best {}, relaxation {:.6}, expected split {:.6}", b5, s5, e5);
    assert!(b5 == 4 && (s5 - 2.5 * (1.0 - (0.8 * PI).cos())).abs() < 1e-6);
    let mut hist = vec![0usize; e.len() + 1];
    for _ in 0..n_draw {                               // road 2: random planes through the origin
        let gv: V = (0..6).map(|_| { let r1 = rng.next(); let r2 = rng.next();
            (-2.0 * (1.0 - r1).ln()).sqrt() * (2.0 * PI * r2).cos() }).collect();
        hist[cut(&v.iter().map(|w| dot(w, &gv) > 0.0).collect::<Vec<_>>())] += 1;
    }
    let sim = hist.iter().enumerate().map(|(k, &h)| (k * h) as f64).sum::<f64>() / nd;
    println!("simulated, {} planes: mean split {:.4}; {}", n_draw, sim,
        hist.iter().enumerate().filter(|(_, &h)| h > 0).map(|(k, h)| format!("{}: {}", k, h)).collect::<Vec<_>>().join(", "));
    let var = hist.iter().enumerate().map(|(k, &h)| h as f64 * (k as f64 - sim).powi(2)).sum::<f64>() / nd; assert!((sim - expct).abs() < 4.0 * (var / nd).sqrt());
    for deg in (0..=180).step_by(15) { let th = (deg as f64).to_radians();
        println!("chart, {:3} deg: split chance {:.4}, relaxation share {:.4}", deg, th / PI, (1.0 - th.cos()) / 2.0); }
    println!("ALL CHECKS PASS");
}
