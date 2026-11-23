// Qubits -- the same check as the Python, in Rust.  No crates.  This is the
// shelf's state-vector simulator: n qubits are 2^n complex amplitudes, a gate
// is a unitary matrix, and a reading picks one outcome with chance |amplitude|^2.
// Two qubits A and B; amplitudes are listed in the order 00, 01, 10, 11, A first.
#[derive(Clone, Copy, PartialEq)]
struct C { re: f64, im: f64 }                  // a small complex number
impl C {
    fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } }
    fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } }
    fn sub(self, o: C) -> C { C { re: self.re - o.re, im: self.im - o.im } }
    fn conj(self) -> C { C { re: self.re, im: -self.im } }
    fn norm2(self) -> f64 { self.re * self.re + self.im * self.im }
    fn scale(self, k: f64) -> C { C { re: self.re * k, im: self.im * k } }
}
fn r(x: f64) -> C { C { re: x, im: 0.0 } }
type M = Vec<Vec<C>>;
fn mat(rows: &[&[f64]]) -> M { rows.iter().map(|row| row.iter().map(|&x| r(x)).collect()).collect() }

fn kron_v(a: &[C], b: &[C]) -> Vec<C> {        // tensor product of two vectors
    a.iter().flat_map(|&x| b.iter().map(move |&y| x.mul(y))).collect()
}
fn kron_m(a: &M, b: &M) -> M {                 // tensor product of two matrices, row by row
    a.iter().flat_map(|ra| b.iter().map(move |rb| kron_v(ra, rb))).collect()
}
fn matvec(m: &M, v: &[C]) -> Vec<C> {          // road one: multiply by the full matrix
    m.iter().map(|row| row.iter().zip(v).fold(r(0.0), |s, (&a, &b)| s.add(a.mul(b)))).collect()
}
fn unitary(m: &M) -> bool {                    // U* U = I, entry by entry
    let n = m.len();
    (0..n).all(|i| (0..n).all(|j| {
        let s = (0..n).fold(r(0.0), |s, k| s.add(m[k][i].conj().mul(m[k][j])));
        s.sub(r(if i == j { 1.0 } else { 0.0 })).norm2().sqrt() < 1e-12
    }))
}
fn apply_1q(g: &M, s: &[C], k: usize, n: usize) -> Vec<C> {   // road two: gate on qubit k, in pairs
    let (mut out, bit) = (s.to_vec(), 1 << (n - 1 - k));
    for i in 0..s.len() {
        if i & bit == 0 {
            let (a, b) = (s[i], s[i | bit]);
            out[i] = g[0][0].mul(a).add(g[0][1].mul(b));
            out[i | bit] = g[1][0].mul(a).add(g[1][1].mul(b));
        }
    }
    out
}
fn apply_cnot(s: &[C], c: usize, t: usize, n: usize) -> Vec<C> { // road two: control 1, swap target
    let (mut out, cb, tb) = (s.to_vec(), 1 << (n - 1 - c), 1 << (n - 1 - t));
    for i in 0..s.len() {
        if i & cb != 0 && i & tb == 0 { out[i] = s[i | tb]; out[i | tb] = s[i]; }
    }
    out
}
fn chances(s: &[C]) -> Vec<C> { s.iter().map(|a| r(a.norm2())).collect() }
fn read_a(s: &[C], bit: usize) -> (f64, Vec<C>) {     // read qubit A only; keep and rescale what agrees
    let keep: Vec<C> = s.iter().enumerate().map(|(i, &a)| if i >> 1 == bit { a } else { r(0.0) }).collect();
    let p: f64 = keep.iter().map(|a| a.norm2()).sum();
    (p, keep.iter().map(|a| a.scale(1.0 / p.sqrt())).collect())
}
fn clean(x: f64) -> f64 { if x.abs() < 5e-13 { 0.0 } else { x } }
fn amp(z: C) -> String {
    if z.im.abs() < 5e-13 { format!("{:.4}", clean(z.re)) } else { format!("{:.4}{:+.4}i", clean(z.re), clean(z.im)) }
}
fn row(label: &str, xs: &[C]) {
    let cells: Vec<String> = xs.iter().map(|&x| format!("{:>8}", amp(x))).collect();
    println!("{:<34}{}", label, cells.join(" "));
}
fn bar(label: &str, p: f64) { println!("{:<11}{:<50} {:.4}", label, "#".repeat((50.0 * p).round() as usize), p); }
fn test(s: &[C]) -> f64 { s[0].mul(s[3]).sub(s[1].mul(s[2])).re }
struct SplitMix64 { s: u64 }                   // SplitMix64, written out so both languages agree
impl SplitMix64 {
    fn next(&mut self) -> u64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.s ^ (self.s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
}

fn main() {
    let h = std::f64::consts::FRAC_1_SQRT_2;
    let i2 = mat(&[&[1.0, 0.0], &[0.0, 1.0]]);
    let x = mat(&[&[0.0, 1.0], &[1.0, 0.0]]);                // NOT: swaps |0> and |1>
    let zg = mat(&[&[1.0, 0.0], &[0.0, -1.0]]);              // phase flip: |1> becomes -|1>
    let hg = mat(&[&[h, h], &[h, -h]]);                      // Hadamard: the even split
    let cnot = mat(&[&[1.0, 0.0, 0.0, 0.0], &[0.0, 1.0, 0.0, 0.0], &[0.0, 0.0, 0.0, 1.0], &[0.0, 0.0, 1.0, 0.0]]);
    let (coin, zero) = (vec![r(0.8), r(0.6)], vec![r(1.0), r(0.0)]);
    let tilt = 2.0 * 0.8f64.acos().to_degrees();
    println!("coin qubit A = 0.8|0> + 0.6|1>: reads 0 with chance {:.4}, 1 with {:.4}", coin[0].norm2(), coin[1].norm2());
    println!("spin tilt from up that prepares it: {:.4} degrees", tilt);
    let before = kron_v(&coin, &zero);
    let after_m = matvec(&cnot, &before);
    let after_i = apply_cnot(&before, 0, 1, 2);
    println!("{:<34}{:>8} {:>8} {:>8} {:>8}", "outcome", "00", "01", "10", "11");
    row("A (x) B, before the gate", &before);
    row("chances before", &chances(&before));
    row("after CNOT, by the 4 x 4 matrix", &after_m);
    row("after CNOT, by swapping pairs", &after_i);
    row("chances after", &chances(&after_m));
    let total = |s: &[C]| -> f64 { s.iter().map(|a| a.norm2()).sum() };
    println!("total chance before and after: {:.4} and {:.4}", total(&before), total(&after_m));
    let mut table = Vec::new();
    for a in 0..2usize { for b in 0..2usize {
        let basis = kron_v(&[r(1.0 - a as f64), r(a as f64)], &[r(1.0 - b as f64), r(b as f64)]);
        let v = apply_cnot(&basis, 0, 1, 2).iter().position(|&z| z == r(1.0)).unwrap();
        table.push((a, b, v));
    } }
    let shown: Vec<String> = table.iter().map(|&(a, b, v)| format!("{}{} -> {}{}", a, b, v >> 1, v & 1)).collect();
    println!("CNOT on the four basis inputs: {}", shown.join(", "));
    let sum_ok = table.iter().all(|&(a, b, v)| v & 1 == a ^ b);
    println!("B ends as the half adder's sum bit, A xor B: {}", if sum_ok { "yes" } else { "no" });
    println!("product test a00*a11 - a01*a10: before {:.4}, after {:.4}", test(&before), test(&after_m));
    let pa: Vec<f64> = after_m.iter().map(|a| a.norm2()).collect();
    println!("chances test P00*P11 - P01*P10: before {:.4}, after {:.4}", test(&chances(&before)), test(&chances(&after_m)));
    for bit in 0..2 {
        let (p, s) = read_a(&after_m, bit);
        row(&format!("read A = {}, chance {:.4}; state", bit, p), &s);
    }
    println!("B alone reads 0 with chance {:.4}; it agrees with A with chance {:.4}", pa[0] + pa[2], pa[0] + pa[3]);
    let pb: Vec<f64> = before.iter().map(|a| a.norm2()).collect();
    for (when, ps) in [("before", &pb), ("after", &pa)] {
        for (b, &p) in ["00", "01", "10", "11"].iter().zip(ps.iter()) { bar(&format!("{} {}", when, b), p) }
    }
    let (shots, mut gen) = (10000usize, SplitMix64 { s: 2026 });
    let mut counts = [0usize; 4];
    for _ in 0..shots {
        let (u, mut acc) = ((gen.next() >> 11) as f64 / 2f64.powi(53), 0.0);
        for i in 0..4 {
            acc += pa[i];
            if u < acc || i == 3 { counts[i] += 1; break; }
        }
    }
    let se = (shots as f64 * pa[0] * (1.0 - pa[0])).sqrt();
    println!("{} shots, seed 2026: 00 {}, 01 {}, 10 {}, 11 {}; expected 00 {:.0}, standard error {:.0}",
             shots, counts[0], counts[1], counts[2], counts[3], shots as f64 * pa[0], se);
    let bell = apply_cnot(&apply_1q(&hg, &kron_v(&zero, &zero), 0, 2), 0, 1, 2);
    row("from 00: H on A, then CNOT", &bell);
    let hi = matvec(&kron_m(&hg, &i2), &before);
    row("H on A of A (x) B, both roads", &hi);
    let coins = [("0.8, 0.6", coin.clone()), ("0.8, -0.6 (after Z)", matvec(&zg, &coin)), ("0.8, 0.6i", vec![r(0.8), C { re: 0.0, im: 0.6 }])];
    for (name, c) in coins.iter() {
        let hc = matvec(&hg, c);
        println!("coin ({}): chances {:.4} {:.4}; after H {:.4} {:.4}", name, c[0].norm2(), c[1].norm2(), hc[0].norm2(), hc[1].norm2());
    }
    row("H twice on |0>", &matvec(&hg, &matvec(&hg, &zero)));
    let all_u = [&x, &zg, &hg, &cnot].iter().all(|g| unitary(g));
    println!("X, Z, H and CNOT each satisfy U* U = I: {}", if all_u { "yes" } else { "no" });
    let sizes: Vec<String> = [1u32, 2, 10, 20, 50].iter().map(|&n| format!("{} -> {}", n, 1u64 << n)).collect();
    println!("amplitudes for n qubits: {}", sizes.join(", "));
    println!("pair updates for one gate on 50 qubits: {}; bytes at 16 per amplitude: {}", 1u64 << 49, 16u64 << 50);
    let hidden = coin[0].norm2() * 0.5 + coin[1].norm2() * 0.5;
    let swapped = apply_cnot(&before, 1, 0, 2);
    let h_coin = matvec(&hg, &coin)[0].norm2();
    println!("mistake 1, amplitudes added as chances: {:.4}", coin[0].re + coin[1].re);
    println!("mistake 2, A and B as separate coins: P01 = {:.4}, true {:.4}", (pa[0] + pa[1]) * (pa[1] + pa[3]), pa[1]);
    println!("mistake 3, a hidden coin then H: P0 = {:.4}, true {:.4}", hidden, h_coin);
    println!("mistake 4, control and target swapped: P11 = {:.4}, product test {:.4}", swapped[3].norm2(), test(&swapped));
    println!("not a unit vector, (0.8, 0.8): chances add to {:.4}", 0.8f64 * 0.8 + 0.8 * 0.8);
    println!("figure, wires y 60 and 150, gate x 210, control dot r 7, target circle r 16, meters x 330");
    let close = |a: &[C], b: &[C]| a.iter().zip(b).all(|(p, q)| p.sub(*q).norm2().sqrt() < 1e-12);
    assert!(close(&after_m, &after_i));                                       // two roads, one state
    assert!(close(&hi, &apply_1q(&hg, &before, 0, 2)));
    assert!(pa.iter().zip([16.0 / 25.0, 0.0, 0.0, 9.0 / 25.0]).all(|(p, q)| (p - q).abs() < 1e-12));
    assert!((test(&after_m) - 12.0 / 25.0).abs() < 1e-12 && test(&before).abs() < 1e-12);
    assert!((h_coin - 49.0 / 50.0).abs() < 1e-12);                            // (0.8 + 0.6)^2 / 2
    assert!(((counts[0] as f64) - shots as f64 * pa[0]).abs() < 4.0 * se && counts[1] == 0 && counts[2] == 0);
    assert!(all_u && (total(&after_m) - 1.0).abs() < 1e-12);
    assert!(table.iter().all(|&(a, b, v)| v & 1 == a ^ b && v >> 1 == a));    // sum bit, by xor
    assert!(close(&matvec(&hg, &matvec(&hg, &zero)), &zero));                 // H undoes itself
    println!("ALL CHECKS PASS");
}
