// The August 2026 zeta-zeros claim -- the same check as the Python, in Rust.  No crates.
// It checks the claim's arithmetic and its counting step on small cases, never the theorem itself:
// the window constant Q(g) by quadrature against its closed form, a search for the best window,
// the counting lemma on random toy sets of "zeros", and the gaps between the dated records.
const N: usize = 4000; // midpoint grid on the window's support [-w, w]
// (int g^2 + iint g(x) g(y) |x - y|) / (int g)^2
fn q(g: &dyn Fn(f64) -> f64, w: f64, pairs: bool) -> f64 {
    let h = 2.0 * w / N as f64;
    let (mut a, mut b, mut c, mut s, mut sx) = (0.0, 0.0, 0.0, 0.0, 0.0);
    for k in 0..N {
        let x = -w + (k as f64 + 0.5) * h;
        let t = g(x);
        a += t; b += t * t;
        c += t * (x * s - sx); s += t; sx += t * x; // pairs j < i, by running sums
    }
    let (a, b) = (a * h, b * h);
    (b + if pairs { 2.0 * c * h * h } else { 0.0 }) / (a * a)
}
fn qs(g: &dyn Fn(f64) -> f64) -> f64 { q(g, 0.5, true) }
// K(z - s)^2 with K(w) = sin(pi w)/(pi w), as (real, imaginary)
fn k2(z: (f64, f64), s: (f64, f64)) -> (f64, f64) {
    let (a, b) = ((z.0 - s.0) * std::f64::consts::PI, (z.1 - s.1) * std::f64::consts::PI);
    if a == 0.0 && b == 0.0 { return (1.0, 0.0); }
    let (sr, si) = (a.sin() * b.cosh(), a.cos() * b.sinh());
    let d = a * a + b * b;
    let (kr, ki) = ((sr * a + si * b) / d, (si * a - sr * b) / d);
    (kr * kr - ki * ki, 2.0 * kr * ki)
}
// (simple points on the real line, 2 #Z - sum K^2)
fn lemma(zs: &[(f64, f64)]) -> (usize, f64) {
    let simple = zs.iter().filter(|z| z.1 == 0.0 && zs.iter().filter(|u| *u == *z).count() == 1).count();
    let mut tot = 0.0;
    for z in zs { for s in zs { tot += k2(*z, *s).0; } }
    (simple, 2.0 * zs.len() as f64 - tot)
}
struct Rng(u64); // SplitMix64, seed stated
impl Rng {
    fn next(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}
fn bars(n: usize) -> String { format!("{:<40}", "#".repeat(n)) }
fn main() {
    let r2 = 2f64.sqrt();
    let q_flat = qs(&|_x| 1.0); // Montgomery's window (the Fejer kernel)
    let q_flat_exact = 1.0 + 1.0 / 3.0; // int 1 = 1, iint |x - y| over the unit square = 1/3
    let q_mt = qs(&|x: f64| (r2 * x).cos()); // the Montgomery-Taylor window
    let q_mt_exact = 0.5 + 1.0 / (r2 * (1.0 / r2).tan()); // 1/2 + cot(1/sqrt 2)/sqrt 2
    let (mut lo, mut hi) = (0.5f64, 3.0f64); // golden-section search over windows cos(a x)
    let phi = (5f64.sqrt() - 1.0) / 2.0;
    for _ in 0..40 {
        let (m1, m2) = (hi - phi * (hi - lo), lo + phi * (hi - lo));
        if qs(&|x: f64| (m1 * x).cos()) < qs(&|x: f64| (m2 * x).cos()) { hi = m2; } else { lo = m1; }
    }
    let a_best = (lo + hi) / 2.0;
    let q_best = qs(&|x: f64| (a_best * x).cos());
    let q_tri = qs(&|x: f64| 1.0 - 2.0 * x.abs());
    let q_a1 = qs(&|x: f64| x.cos());
    let c0 = 2.0 - q_mt_exact; // simple and on the line
    let c1 = (c0 + 1.0) / 2.0; // distinct
    let c2 = (1.0 + 2.0 * r2 + 2.0 * c0) / (3.0 + 2.0 * r2); // simple or on the line
    println!("window g = 1:            Q by quadrature {:.6}, exact 4/3 = {:.6}", q_flat, q_flat_exact);
    println!("  bound 2 - Q = {:.6} (exact 2/3)", 2.0 - q_flat);
    println!("window g = cos(sqrt2 x): Q by quadrature {:.6}, closed form {:.10}", q_mt, q_mt_exact);
    println!("  bound 2 - Q = {:.7}", c0);
    println!("best window cos(a x) by search: a = {:.5} (sqrt 2 = {:.5}), Q = {:.6}", a_best, r2, q_best);
    println!("other windows: triangle 1 - 2|x|: Q = {:.6}, bound {:.6}; cos(x): Q = {:.6}, bound {:.6}", q_tri, 2.0 - q_tri, q_a1, 2.0 - q_a1);
    println!("distinct (C0 + 1)/2 = {:.5}; simple or on the line (1 + 2 sqrt2 + 2 C0)/(3 + 2 sqrt2) = {:.5}", c1, c2);
    let mut rng = Rng(20260813);
    let (mut worst, mut worst_off, mut offline_sets, trials) = (1e9f64, 1e9f64, 0, 4000);
    for _ in 0..trials {
        let (mut zs, mut off): (Vec<(f64, f64)>, bool) = (vec![], false);
        let n = 1 + (rng.next() * 5.0) as usize;
        for _ in 0..n {
            let x = -3.0 + 6.0 * rng.next();
            if rng.next() < 0.4 {
                let y = 0.01 + 0.99 * rng.next();
                zs.push((x, y)); zs.push((x, -y)); off = true;
            } else {
                let m = [1, 1, 1, 2, 3][(rng.next() * 5.0) as usize];
                for _ in 0..m { zs.push((x, 0.0)); }
            }
        }
        let (s, b) = lemma(&zs);
        worst = worst.min(s as f64 - b);
        if off { offline_sets += 1; worst_off = worst_off.min(s as f64 - b); } // the twin case on its own
    }
    let shown = (worst * 1e6).round() / 1e6 + 0.0;
    println!("counting lemma, {} random toy sets ({} with off-line pairs): smallest slack {:.6}", trials, offline_sets, shown);
    println!("  smallest slack among the sets with off-line pairs: {:.6}", worst_off);
    let mult = (1..50i64).map(|m| m * (2 - m) - if m == 1 { 1 } else { 0 }).max().unwrap();
    println!("one point of multiplicity m: m(2 - m) minus [m = 1] is at most {}, checked for m <= 49", mult);
    let toy = [(0.0, 0.0), (1.5, 0.0), (3.0, 0.3), (3.0, -0.3), (5.0, 0.0), (5.0, 0.0)];
    let (s, b) = lemma(&toy);
    let naive = toy.iter().filter(|z| toy.iter().filter(|u| *u == *z).count() == 1).count();
    let pair = k2((3.0, 0.3), (3.0, -0.3)).0;
    println!("toy set, 6 zeros: simple on the line {}; lemma bound {:.4}; naive count of lone points {}", s, b, naive);
    println!("  off-line pair 3 +- 0.3i: cross term K(0.6i)^2 = {:.4}, so the pair costs {:.4} against a double zero's 4", pair, 2.0 + 2.0 * pair);
    let pair2 = k2((3.0, 0.05), (3.0, -0.05)).0; // twins pulled toward the line
    println!("  pull the twins to 3 +- 0.05i: the pair costs {:.4}", 2.0 + 2.0 * pair2);
    let q_wide = q(&|_x| 1.0, 1.0, true); // window on [-1, 1]: reaches alpha = 2, |alpha| proved only to 1
    let q_diag = q(&|_x| 1.0, 0.5, false); // self-pairs only, the |alpha| term dropped
    let rec: [(&str, f64); 6] = [("Levinson 1974, on the line", 0.3474), ("Conrey 1989, on the line", 0.4088),
        ("PRZZ 2020, on the line", 0.417293), ("2026 claim, simple + line", (c0 * 1e6).round() / 1e6),
        ("ceiling of this method", 0.682), ("Riemann hypothesis says", 1.0)];
    for (name, x) in rec.iter() {
        println!("bars, {:<27} {} {:.4}", name, bars((40.0 * x).round() as usize), x);
    }
    println!("five-twelfths = {:.6}; PRZZ simple and on the line 0.407511; rise 0.417293 -> {:.4}, ratio {:.3}", 5.0 / 12.0, c0, c0 / 0.417293);
    println!("left unplaced by the claim: at most {:.4} of all zeros", 1.0 - c0);
    println!("what breaks: drop the |alpha| term: bound {:.4}; window past alpha = 1: bound {:.4}; 0.6725 x 29 zeros below height 100 = {:.2}, true count on the line 29 (quoted)",
        2.0 - q_diag, 2.0 - q_wide, 0.6725 * 29.0);
    println!("ledger: statement  simple-and-on-the-line share of zeta zeros >= 0.6725007 (liminf, with multiplicity)");
    println!("ledger: artifact   preprint v1 2026-08-13, v2 2026-08-19; Lean 4 formalisation reported, not run here");
    println!("ledger: check      independent second proof, preprint v1 2026-09-02; follow-up 0.67353, preprint 2026-10-06");
    println!("ledger: check      second proof's key inequality: formal certificate by an outside machine prover, not run here");
    println!("ledger: status     statement proved from 2026-11-21: RH (formal proof certified) with Montgomery-Taylor 1975");
    println!("ledger: status     the preprints' proof without RH: claimed, not refereed, as of 2026-11-23");
    assert!((q_flat - q_flat_exact).abs() < 1e-6 && (q_mt - q_mt_exact).abs() < 1e-6); // quadrature vs closed form
    assert!((a_best - r2).abs() < 0.01 && (q_best - q_mt_exact).abs() < 1e-6); // search finds sqrt 2
    assert!((c0 - 0.6725007).abs() < 1e-7 && (c1 - 0.83625).abs() < 1e-5 && (c2 - 0.88762).abs() < 1e-5); // quoted constants
    assert!(worst > -1e-9 && offline_sets > 1000 && mult <= 0); // counting lemma holds on every toy set
    assert!(s == 2 && naive == 4 && b <= s as f64 + 1e-9 && pair > pair2 && pair2 > 1.0); // off-line pair priced like a double zero
    assert!(q_tri > q_mt_exact && q_a1 > q_mt_exact && (q_wide - 7.0 / 6.0).abs() < 1e-6 && (q_diag - 1.0).abs() < 1e-9); // hand values
    println!("ALL CHECKS PASS");
}
