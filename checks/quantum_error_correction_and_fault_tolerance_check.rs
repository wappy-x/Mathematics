// Quantum error correction -- the check behind the card.  Rust std only, no crates.
// State vectors as on the Qubits card: n qubits are 2^n amplitudes, qubit 1 is the
// leftmost bit, and every amplitude here is real.  An error or a check is a pair of
// bit masks (x, z): Z on the z-qubits first, then X on the x-qubits.
type V = Vec<f64>;
type P = (usize, usize);
type Table = Vec<(Vec<i32>, String, P)>;

fn mask(n: usize, qs: &[usize]) -> usize { qs.iter().map(|q| 1 << (n - q)).sum() }
fn pop(v: usize) -> u32 { v.count_ones() }
fn pauli(s: &V, x: usize, z: usize) -> V {                 // apply X^x Z^z
    (0..s.len()).map(|i| if pop((i ^ x) & z) % 2 == 1 { -s[i ^ x] } else { s[i ^ x] }).collect()
}
fn dot(s: &V, t: &V) -> f64 { s.iter().zip(t).map(|(a, b)| a * b).sum() }
fn ket(n: usize, bits: &str) -> V { (0..1 << n).map(|i| if i == usize::from_str_radix(bits, 2).unwrap() { 1.0 } else { 0.0 }).collect() }
fn mix(pairs: &[(f64, &V)]) -> V { (0..pairs[0].1.len()).map(|i| pairs.iter().map(|(c, v)| c * v[i]).sum()).collect() }
fn kron(a: &V, b: &V) -> V { a.iter().flat_map(|x| b.iter().map(move |y| x * y)).collect() }
fn fid(s: &V, t: &V) -> f64 { dot(s, t).powi(2) / (dot(s, s) * dot(t, t)) }
fn syn(s: &V, checks: &[P]) -> Vec<i32> {
    checks.iter().map(|&(x, z)| (dot(s, &pauli(s, x, z)) / dot(s, s)).round() as i32).collect()
}
fn anti(e: P, c: P) -> i32 { ((pop(e.0 & c.1) + pop(e.1 & c.0)) % 2) as i32 }  // 1: anticommute
fn singles(n: usize) -> Vec<(String, P)> {
    (1..=n).flat_map(|q| { let m = mask(n, &[q]); [("X", (m, 0)), ("Z", (0, m)), ("XZ", (m, m))].map(|(k, e)| (format!("{}{}", k, q), e)) }).collect()
}
fn table(n: usize, checks: &[P]) -> Table {   // syndrome -> repair, from anticommuting alone
    let mut t: Table = vec![(vec![1; checks.len()], "none".to_string(), (0, 0))];
    for (name, e) in singles(n) {
        let sy: Vec<i32> = checks.iter().map(|&c| 1 - 2 * anti(e, c)).collect();
        if !t.iter().any(|r| r.0 == sy) { t.push((sy, name, e)); }
    }
    t
}
fn repair(s: &V, checks: &[P], t: &Table) -> (String, V) {
    let r = t.iter().find(|r| r.0 == syn(s, checks)).unwrap();
    (r.1.clone(), pauli(s, r.2 .0, r.2 .1))
}
fn signs(sy: &[i32]) -> String { sy.iter().map(|&v| if v > 0 { '+' } else { '-' }).collect() }
fn pm(sy: &[i32]) -> String { format!("({})", sy.iter().map(|v| format!("{:+}", v)).collect::<Vec<_>>().join(", ")) }
fn all_singles(n: usize, code: &V, checks: &[P], t: &Table) -> usize {
    singles(n).iter().filter(|(_, e)| fid(&repair(&pauli(code, e.0, e.1), checks, t).1, code) > 1.0 - 1e-12).count()
}
fn f(p: f64) -> f64 { 3.0 * p * p - 2.0 * p.powi(3) }
fn join(v: Vec<String>, sep: &str) -> String { v.join(sep) }
fn splitmix64(s: &mut u64) -> u64 {                          // SplitMix64, as in the Python
    *s = s.wrapping_add(0x9E3779B97F4A7C15);
    let z = (*s ^ (*s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}
fn main() {
    let (c0, c1): (f64, f64) = (0.8, 0.6);                                // the coin qubit from the Qubits card
    let l3 = mix(&[(c0, &ket(3, "000")), (c1, &ket(3, "111"))]);
    let bc = vec![(0, mask(3, &[1, 2])), (0, mask(3, &[2, 3]))];
    let bt = table(3, &bc);
    println!("two copies of the coin: {}; coin then CNOT: {}", join(kron(&vec![c0, c1], &vec![c0, c1]).iter().map(|a| format!("{:.4}", a)).collect(), " "),
             join(mix(&[(c0, &ket(2, "00")), (c1, &ket(2, "11"))]).iter().map(|a| format!("{:.4}", a)).collect(), " "));
    println!("bit-flip code: 0.8|000> + 0.6|111>; checks Z1Z2, Z2Z3 read {}", pm(&syn(&l3, &bc)));
    for q in 1..=3 {
        let bad = pauli(&l3, mask(3, &[q]), 0); let (name, back) = repair(&bad, &bc, &bt);
        println!("X on qubit {}: checks read {}, repair {}, fidelity {:.4}", q, pm(&syn(&bad, &bc)), name, fid(&back, &l3));
    }
    let mut s5 = kron(&pauli(&l3, mask(3, &[1]), 0), &ket(2, "00"));   // road two: helpers and CNOTs
    for (c, t) in [(1, 4), (2, 4), (2, 5), (3, 5)] {
        s5 = (0..32).map(|i: usize| if i & (1 << (5 - c)) != 0 { s5[i ^ (1 << (5 - t))] } else { s5[i] }).collect();
    }
    let p10: f64 = (0..32).filter(|i| i & 3 == 2).map(|i| s5[i] * s5[i]).sum();
    println!("helper qubits after four CNOTs read 1 0 with chance {:.4}; data amplitudes {:.4} on |100>, {:.4} on |011>",
             p10, s5[0b10010], s5[0b01110]);
    let p: f64 = 0.01;
    let (mut fails, mut pl_enum) = (vec![], 0.0);
    for pat in 0..8usize {                                    // road two: all 8 flip patterns
        let after = repair(&pauli(&l3, pat, 0), &bc, &bt).1;
        if fid(&after, &l3) < 0.999 { fails.push(format!("{:03b}", pat)); pl_enum += p.powi(pop(pat) as i32) * (1.0 - p).powi(3 - pop(pat) as i32); }
    }
    println!("patterns that fail: {}", fails.join(", "));
    println!("p = 0.01: logical error 3p^2 - 2p^3 = {:.8}; over all 8 patterns = {:.8}", f(p), pl_enum);
    let comb = [1.0, 3.0, 3.0, 1.0];
    println!("chance of 0, 1, 2, 3 flips: {}", join((0..4).map(|k| format!("{:.6}", comb[k] * p.powi(k as i32) * (1.0 - p).powi(3 - k as i32))).collect(), ", "));
    let (runs, mut gen, mut mc) = (1000000u64, 2026u64, 0u64);
    for _ in 0..runs {                                        // road three: random flips, same decoder
        let mut pat = 0usize;
        for b in 0..3 { if ((splitmix64(&mut gen) >> 11) as f64) / 9007199254740992.0 < p { pat |= 1 << b; } }
        let sy: Vec<i32> = bc.iter().map(|&c| 1 - 2 * anti((pat, 0), c)).collect();
        let fix = bt.iter().find(|r| r.0 == sy).unwrap().2 .0;
        if pat ^ fix == 7 { mc += 1; }
    }
    let se = (runs as f64 * f(p) * (1.0 - f(p))).sqrt();
    println!("{} random runs, seed 2026: {} logical errors; expected {:.1}, standard error {:.1}", runs, mc, runs as f64 * f(p), se);
    println!("try: p = 0.001 gives {:.8}; p = 0.1 gives {:.8}", f(0.001), f(0.1));
    let (mut lv, mut hv) = (vec![p], vec![0.6]);
    for _ in 0..3 { lv.push(f(*lv.last().unwrap())); hv.push(f(*hv.last().unwrap())); }
    println!("levels 0-3 from p = 0.01: {}", join(lv.iter().map(|v| format!("{:.3e}", v)).collect(), ", "));
    println!("  bound (3p)^(2^k)/3:     {}", join((0..4).map(|k| format!("{:.3e}", (3.0 * p).powi(1 << k) / 3.0)).collect(), ", "));
    println!("levels 0-3 from p = 0.6:  {}", join(hv.iter().map(|v| format!("{:.4}", v)).collect(), ", "));
    let (mut lo, mut hi): (f64, f64) = (0.01, 0.99);         // threshold: where f(p) = p, by bisection
    for _ in 0..60 { let mid = (lo + hi) / 2.0; if f(mid) < mid { lo = mid } else { hi = mid } }
    println!("threshold of the level map, by bisection: {:.6}", lo);
    let xs: Vec<f64> = (0..11).map(|k| k as f64 / 10.0).collect();
    println!("chart p:      {}", join(xs.iter().map(|x| format!("{:.2}", x)).collect(), " "));
    println!("chart level 1 {}", join(xs.iter().map(|&x| format!("{:.2}", f(x))).collect(), " "));
    println!("chart level 2 {}", join(xs.iter().map(|&x| format!("{:.2}", f(f(x)))).collect(), " "));
    let (mut k, mut q) = (0u32, p);
    while q > 1e-11 { q = f(q); k += 1; }
    println!("need 1e-11 per step (1% over 1e9 steps) from p = 0.01: level {}; qubits per logical qubit 3^{} = {}, Steane 7^{} = {}", k, k, 3u32.pow(k), k, 7u32.pow(k));
    let plus = mix(&[(1.0, &ket(3, "000")), (1.0, &ket(3, "111"))]);
    let minus = mix(&[(1.0, &ket(3, "000")), (-1.0, &ket(3, "111"))]);
    let mut l9 = mix(&[(c0, &kron(&kron(&plus, &plus), &plus)), (c1, &kron(&kron(&minus, &minus), &minus))]);
    let nrm = dot(&l9, &l9).sqrt(); l9 = l9.iter().map(|a| a / nrm).collect();
    let mut sc: Vec<P> = [[1, 2], [2, 3], [4, 5], [5, 6], [7, 8], [8, 9]].iter().map(|pr| (0, mask(9, pr))).collect();
    sc.extend([(mask(9, &[1, 2, 3, 4, 5, 6]), 0), (mask(9, &[4, 5, 6, 7, 8, 9]), 0)]);
    let st = table(9, &sc);
    println!("Shor code: 9 qubits ({} amplitudes), 8 checks, all read {} on the coin", l9.len(), signs(&syn(&l9, &sc)));
    for name in ["X1", "Z1", "Z5", "XZ5"] {
        let e = singles(9).into_iter().find(|r| r.0 == name).unwrap().1;
        let bad = pauli(&l9, e.0, e.1);
        println!("  {:<3} -> checks {}, repair {}", name, signs(&syn(&bad, &sc)), repair(&bad, &sc, &st).0);
    }
    println!("Shor code repairs {} of 27 single-qubit errors", all_singles(9, &l9, &sc, &st));
    let m5 = mask(9, &[5]);
    let mess = mix(&[(0.9, &l9), (0.3, &pauli(&l9, m5, 0)), (0.3, &pauli(&l9, 0, m5)), (0.1, &pauli(&l9, m5, m5))]);
    let (mut tot, mut bf) = (0.0, vec![]);                    // measuring the checks picks one branch
    for (sy, name, _) in &st {
        let mut br = mess.clone();
        for (&(x, z), &sg) in sc.iter().zip(sy) { br = br.iter().zip(&pauli(&br, x, z)).map(|(a, b)| (a + sg as f64 * b) / 2.0).collect(); }
        let pr = dot(&br, &br);
        if pr > 1e-12 {
            tot += pr; bf.push(fid(&repair(&br, &sc, &st).1, &l9));
            println!("  messy error on qubit 5, branch {}: chance {:.4}, repair {}, fidelity {:.4}", signs(sy), pr, name, bf[bf.len() - 1]);
        }
    }
    println!("  branch chances add to {:.4}", tot);
    let rows: Vec<usize> = (0..3).map(|r| mask(7, &(1..8).filter(|j| j >> r & 1 == 1).collect::<Vec<_>>())).collect();
    println!("Steane: row overlaps {}, {}, {}; row weights {}, {}, {}", pop(rows[0] & rows[1]), pop(rows[0] & rows[2]),
             pop(rows[1] & rows[2]), pop(rows[0]), pop(rows[1]), pop(rows[2]));
    let mut words: Vec<usize> = (0..8).map(|b: usize| (0..3).filter(|r| b >> r & 1 == 1).fold(0, |w, r| w ^ rows[r])).collect(); words.sort();
    println!("Steane |0_L> words: {}", join(words.iter().map(|w| format!("{:07b}", w)).collect(), " "));
    let z0: V = (0..128).map(|i| if words.contains(&i) { 1.0 / 8f64.sqrt() } else { 0.0 }).collect();
    let l7 = mix(&[(c0, &z0), (c1, &pauli(&z0, 127, 0))]);
    let mut tc: Vec<P> = rows.iter().map(|&r| (0, r)).collect();
    tc.extend(rows.iter().map(|&r| (r, 0)));
    let tt = table(7, &tc);
    let num = |sy: &[i32]| -> usize { sy.iter().enumerate().filter(|(_, &v)| v < 0).map(|(i, _)| 1 << i).sum() };
    let xs7: Vec<usize> = (1..8).map(|j| num(&syn(&pauli(&l7, mask(7, &[j]), 0), &tc)[..3])).collect();
    let zs7: Vec<usize> = (1..8).map(|j| num(&syn(&pauli(&l7, 0, mask(7, &[j])), &tc)[3..])).collect();
    println!("Steane, X on qubit 1-7, Z-checks spell: {}", join(xs7.iter().map(|v| v.to_string()).collect(), " "));
    println!("Steane, Z on qubit 1-7, X-checks spell: {}", join(zs7.iter().map(|v| v.to_string()).collect(), " "));
    println!("Steane code ({} amplitudes): checks on the coin {}; repairs {} of 21 single-qubit errors", l7.len(), signs(&syn(&l7, &tc)), all_singles(7, &l7, &tc, &tt));
    let ph = pauli(&l3, 0, mask(3, &[1]));
    let two = repair(&pauli(&l3, mask(3, &[1, 2]), 0), &bc, &bt);
    let read: f64 = [0usize, 7].iter().map(|&i| l3[i] * l3[i] * fid(&ket(3, &format!("{:03b}", i)), &l3)).sum();
    println!("mistake 1, read the data: fidelity on average {:.4}", read);
    println!("mistake 2, X1 X2: repair {}, chances now {:.4} and {:.4}, fidelity {:.4}", two.0, two.1[0].powi(2), two.1[7].powi(2), fid(&two.1, &l3));
    println!("mistake 3, Z1 on the bit-flip code: checks {}, fidelity {:.4}", pm(&syn(&ph, &bc)), fid(&ph, &l3));
    println!("surface code, distance 3 5 7: qubits (2d-1)^2 = {}; error powers (d+1)/2 = {}; cited threshold 0.57% per step",
             join([3, 5, 7].iter().map(|d| ((2 * d - 1) * (2 * d - 1)).to_string()).collect(), " "),
             join([3, 5, 7].iter().map(|d| ((d + 1) / 2).to_string()).collect(), " "));
    assert!((f(p) - pl_enum).abs() < 1e-15 && fails == ["011", "101", "110", "111"]);   // formula = all patterns
    assert!((mc as f64 - runs as f64 * f(p)).abs() < 4.0 * se);                       // simulation agrees
    assert!((p10 - 1.0).abs() < 1e-12 && (f(p) - 0.000298).abs() < 1e-12);            // 3(0.0001) - 2(0.000001)
    assert!((lo - 0.5).abs() < 1e-9 && f(0.6) > 0.6 && f(0.4) < 0.4);                  // threshold 1/2
    assert!(all_singles(9, &l9, &sc, &st) == 27 && all_singles(7, &l7, &tc, &tt) == 21);
    assert!((tot - 1.0).abs() < 1e-12 && bf.len() == 4 && bf.iter().all(|&v| v > 1.0 - 1e-12));
    assert!(rows.iter().all(|&a| rows.iter().all(|&b| pop(a & b) % 2 == 0)));         // X and Z checks commute
    assert!(xs7 == (1..8).collect::<Vec<usize>>());
    assert!((fid(&ph, &l3) - (c0 * c0 - c1 * c1).powi(2)).abs() < 1e-12);              // (0.64 - 0.36)^2
    println!("ALL CHECKS PASS");
}
