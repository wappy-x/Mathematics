// Causal graphs and back-door adjustment -- the same check as the Python, in Rust.
// No crates.  Data: kidney-stone cures by treatment and stone size (Charig et al.,
// BMJ, 1986); M (stone-free), R (readmitted) and F (follow-up letter) are invented; they keep that table.
// Roads: back-door formula; cut graph enumerated; seeded randomised trial;
// d-separation against the numbers; the back-door rule against every adjustment set.
const NAMES: [&str; 6] = ["Z", "T", "M", "Y", "R", "F"]; // size, treatment, stone-free, cured, readmitted, follow-up letter
const ARROWS: [(usize, usize); 8] = [(0, 1), (0, 2), (0, 3), (1, 2), (2, 3), (1, 4), (3, 4), (4, 5)];
const CURE: [[(f64, f64); 2]; 2] = [[(81.0, 87.0), (192.0, 263.0)], [(234.0, 270.0), (55.0, 80.0)]]; // [t][z]
const H: f64 = 0.95; const L: [f64; 2] = [0.40, 0.30]; // P(cured | stone-free); P(cured | not stone-free), by size
const PR: [[f64; 2]; 2] = [[0.50, 0.10], [0.40, 0.05]]; const PF: [f64; 2] = [0.20, 0.90]; // [t][y]: P(readmitted); [r]: P(letter)
const AB: [&str; 2] = ["A", "B"]; const SIZE: [&str; 2] = ["small", "large"];

fn bern(q: f64, v: usize) -> f64 { if v == 1 { q } else { 1.0 - q } }
fn bit(k: usize, i: usize) -> usize { (k >> i) & 1 }

struct Model { nz: [f64; 2], tot: f64, pm: [[f64; 2]; 2] }
impl Model {
    fn joint(&self, force: Option<usize>) -> [f64; 64] { // index bits: Z T M Y R F; force cuts the arrow into T
        let mut j = [0.0; 64];
        for k in 0..64 {
            let (z, t, m, y, r, f) = (bit(k, 0), bit(k, 1), bit(k, 2), bit(k, 3), bit(k, 4), bit(k, 5));
            let pt = match force { None => CURE[t][z].1 / self.nz[z], Some(f) => if t == f { 1.0 } else { 0.0 } };
            j[k] = self.nz[z] / self.tot * pt * bern(self.pm[t][z], m)
                * bern(if m == 1 { H } else { L[z] }, y) * bern(PR[t][y], r) * bern(PF[r], f);
        }
        j
    }
}
fn prob(j: &[f64; 64], fix: &[(usize, usize)]) -> f64 {
    (0..64).filter(|&k| fix.iter().all(|&(i, v)| bit(k, i) == v)).map(|k| j[k]).sum()
}
fn desc(v: usize) -> Vec<usize> {
    let (mut out, mut todo) = (Vec::new(), vec![v]);
    while let Some(&top) = todo.last() {
        match ARROWS.iter().find(|&&(a, b)| a == top && !out.contains(&b)) {
            Some(&(_, b)) => { out.push(b); todo.push(b) }
            None => { todo.pop(); }
        }
    }
    out
}
fn paths(a: usize, b: usize, seen: Vec<usize>, out: &mut Vec<Vec<usize>>) { // every simple path, ignoring direction
    if a == b { out.push(seen); return }
    for &(u, v) in ARROWS.iter() {
        for (x, y) in [(u, v), (v, u)] {
            if x == a && !seen.contains(&y) { let mut s = seen.clone(); s.push(y); paths(y, b, s, out) }
        }
    }
}
fn all_paths(a: usize, b: usize) -> Vec<Vec<usize>> { let mut o = vec![]; paths(a, b, vec![a], &mut o); o }
fn blocked(path: &[usize], s: &[usize]) -> bool {
    for i in 1..path.len() - 1 {
        let v = path[i];
        if ARROWS.contains(&(path[i - 1], v)) && ARROWS.contains(&(path[i + 1], v)) { // a collider
            if !s.contains(&v) && !desc(v).iter().any(|d| s.contains(d)) { return true }
        } else if s.contains(&v) { return true }
    }
    false
}
fn dsep(a: usize, b: usize, s: &[usize]) -> bool { all_paths(a, b).iter().all(|q| blocked(q, s)) }
fn gap_ci(j: &[f64; 64], a: usize, b: usize, s: &[usize]) -> f64 { // largest |P(a,b,s)P(s) - P(a,s)P(b,s)|
    let mut g: f64 = 0.0;
    for k in 0..(1usize << (s.len() + 2)) {
        let fs: Vec<(usize, usize)> = s.iter().enumerate().map(|(i, &v)| (v, bit(k, i + 2))).collect();
        let with = |extra: &[(usize, usize)]| { let mut f = fs.clone(); f.extend_from_slice(extra); prob(j, &f) };
        g = g.max((with(&[(a, bit(k, 0)), (b, bit(k, 1))]) * with(&[]) - with(&[(a, bit(k, 0))]) * with(&[(b, bit(k, 1))])).abs());
    }
    g
}
fn setname(s: &[usize]) -> String { format!("{{{}}}", s.iter().map(|&v| NAMES[v]).collect::<Vec<_>>().join(", ")) }

struct Rng(u64); // SplitMix64
impl Rng {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}

fn main() {
    let nz = [CURE[0][0].1 + CURE[1][0].1, CURE[0][1].1 + CURE[1][1].1];
    let tot = nz[0] + nz[1];
    let p = |t: usize, z: usize| CURE[t][z].0 / CURE[t][z].1;
    println!("treatment  size   cured/n  rate");
    for k in 0..4 { let (t, z) = (k / 2, k % 2);
        println!("{:<10} {:<6} {:>3}/{:<3}  {:.3}", AB[t], SIZE[z], CURE[t][z].0, CURE[t][z].1, p(t, z)) }
    let cn: Vec<[f64; 2]> = (0..2).map(|t| [CURE[t][0].0 + CURE[t][1].0, CURE[t][0].1 + CURE[t][1].1]).collect();
    let naive = [cn[0][0] / cn[0][1], cn[1][0] / cn[1][1]];
    println!("pooled: A {}/{} = {:.3}, B {}/{} = {:.3}, gap A-B {:+.1} points; size shares small {}/{} = {:.3}, large {}/{} = {:.3}",
             cn[0][0], cn[0][1], naive[0], cn[1][0], cn[1][1], naive[1], 100.0 * (naive[0] - naive[1]), nz[0], tot, nz[0] / tot, nz[1], tot, nz[1] / tot);
    // Road 1: the back-door formula on the counts, adjusting for size
    let adj: Vec<f64> = (0..2).map(|t| p(t, 0) * nz[0] / tot + p(t, 1) * nz[1] / tot).collect();
    for t in 0..2 { println!("back-door, {}: {:.4} x {}/{} + {:.4} x {}/{} = {:.4} ({:.1}%)", AB[t], p(t, 0), nz[0], tot,
                             p(t, 1), nz[1], tot, adj[t], 100.0 * adj[t]) }
    let true_gap = adj[0] - adj[1];
    println!("adjusted gap A-B {:+.1} points", 100.0 * true_gap);
    // The model: P(z) P(t|z) P(m|t,z) P(y|m,z) P(r|t,y).  Cure depends on treatment only through M.
    let mut pm = [[0.0; 2]; 2];
    for t in 0..2 { for z in 0..2 { pm[t][z] = (p(t, z) - L[z]) / (H - L[z]) } }
    let model = Model { nz, tot, pm };
    println!("model inputs: P(cured | stone-free) {:.2}; P(cured | not) small {:.2}, large {:.2}; P(readmitted | cured, not): A {:.2}, {:.2}; B {:.2}, {:.2}; \
              P(follow-up letter | readmitted, not) {:.2}, {:.2}", H, L[0], L[1], PR[0][1], PR[0][0], PR[1][1], PR[1][0], PF[1], PF[0]);
    let parts: Vec<String> = (0..4).map(|k| format!("{} {} {:.4}", AB[k / 2], SIZE[k % 2], pm[k / 2][k % 2])).collect();
    println!("model, P(stone-free | t, z): {}", parts.join(", "));
    let j = model.joint(None);
    for k in 0..4 { let (t, z) = (k / 2, k % 2); // the model reproduces the recorded table
        assert!((prob(&j, &[(1, t), (0, z), (3, 1)]) / prob(&j, &[(1, t), (0, z)]) - p(t, z)).abs() < 1e-12) }
    // Road 2: the cut graph, enumerated
    let d: Vec<f64> = (0..2).map(|t| prob(&model.joint(Some(t)), &[(3, 1)])).collect();
    println!("cut graph: P(cured | do A) {:.4}, P(cured | do B) {:.4}", d[0], d[1]);
    assert!((d[0] - adj[0]).abs() < 1e-12 && (d[1] - adj[1]).abs() < 1e-12);
    // Road 3: a randomised trial in the model world, SplitMix64
    let mut rng = Rng(20261123);
    let (nsim, seed) = (200000, rng.0);
    let mut cnt = [[0.0f64; 2]; 2]; // [t] = [cured, n]
    for _ in 0..nsim {
        let z = if rng.uniform() < nz[1] / tot { 1 } else { 0 };
        let t = if rng.uniform() < 0.5 { 1 } else { 0 };
        let m = if rng.uniform() < pm[t][z] { 1 } else { 0 };
        if rng.uniform() < (if m == 1 { H } else { L[z] }) { cnt[t][0] += 1.0 }
        cnt[t][1] += 1.0;
    }
    let sim = [cnt[0][0] / cnt[0][1], cnt[1][0] / cnt[1][1]];
    let se = (sim[0] * (1.0 - sim[0]) / cnt[0][1] + sim[1] * (1.0 - sim[1]) / cnt[1][1]).sqrt();
    println!("trial: seed {}, {} patients by coin; A {}/{} = {:.4}, B {}/{} = {:.4}, gap {:+.2} points (SE {:.2})",
             seed, nsim, cnt[0][0], cnt[0][1], sim[0], cnt[1][0], cnt[1][1], sim[1], 100.0 * (sim[0] - sim[1]), 100.0 * se);
    assert!((sim[0] - sim[1] - true_gap).abs() < 4.0 * se);
    // Road 4: d-separation from the graph, against independence in the numbers
    let (mut n_st, mut n_sep) = (0, 0);
    for a in 0..6 { for b in a + 1..6 {
        let rest: Vec<usize> = (0..6).filter(|&v| v != a && v != b).collect();
        for k in 0..16 {
            let s: Vec<usize> = (0..4).filter(|&i| bit(k, i) == 1).map(|i| rest[i]).collect();
            let sep = dsep(a, b, &s);
            assert!(sep == (gap_ci(&j, a, b, &s) < 1e-12)); // the graph rule against the numbers
            n_st += 1; n_sep += sep as usize;
        }
    } }
    println!("d-separation: {} statements, {} separated by the graph; numbers agree on all {}", n_st, n_sep, n_st);
    let shows: [(usize, usize, &[usize]); 7] = [(1, 3, &[]), (1, 3, &[0]), (1, 3, &[0, 2]), (1, 3, &[0, 2, 4]), (1, 3, &[0, 2, 5]), (0, 4, &[1]), (0, 4, &[1, 3])];
    for (a, b, s) in shows {
        println!("  {} vs {} given {:<10} graph: {:<9}  largest gap {:.6}", NAMES[a], NAMES[b], setname(s),
                 if dsep(a, b, s) { "separated" } else { "connected" }, gap_ci(&j, a, b, s));
    }
    // Road 5: the back-door rule against the bias of every adjustment set
    let backdoor = |s: &[usize]| !desc(1).iter().any(|v| s.contains(v))
        && all_paths(1, 3).iter().filter(|q| ARROWS.contains(&(q[1], 1))).all(|q| blocked(q, s));
    let mut bars = Vec::new();
    for k in 0..8 {
        let s: Vec<usize> = (0..3).filter(|&i| bit(k, i) == 1).map(|i| [0, 2, 4][i]).collect();
        let est: Vec<f64> = (0..2).map(|t| (0..(1usize << s.len())).map(|c| {
            let fs: Vec<(usize, usize)> = s.iter().enumerate().map(|(i, &v)| (v, bit(c, i))).collect();
            let mut num = fs.clone(); num.extend([(1, t), (3, 1)]);
            let mut den = fs.clone(); den.push((1, t));
            prob(&j, &num) / prob(&j, &den) * prob(&j, &fs)
        }).sum()).collect();
        let ok = backdoor(&s); assert!(ok == ((est[0] - est[1] - true_gap).abs() < 1e-12));
        bars.push((100.0 * (est[0] - est[1]) * 1e9).round() / 1e9 + 0.0);
        println!("adjust for {:<10} A {:.4}  B {:.4}  gap {:+5.1}  back-door {}", setname(&s), est[0], est[1],
                 bars[k], if ok { "yes" } else { "no" });
    }
    assert!((bars[0] - 100.0 * (naive[0] - naive[1])).abs() < 1e-9); // holding nothing fixed gives the pooled gap
    assert!(naive[0] < naive[1] && adj[0] > adj[1]); // the reversal: B ahead pooled, A ahead adjusted
    assert!(bars[3].abs() < 1e-9); // holding the mediator fixed erases the whole effect
    println!("bars, gap A-B in points: {}", bars.iter().map(|b| format!("{:.1}", b)).collect::<Vec<_>>().join(", "));
    println!("ALL CHECKS PASS");
}
