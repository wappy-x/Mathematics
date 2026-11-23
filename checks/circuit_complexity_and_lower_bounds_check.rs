// Circuit lower bounds -- the same check as circuit_complexity_and_lower_bounds_check.py, in Rust.
// Standard library only, no crates.  The 2^256 comparison uses a small big-integer written here.
fn parity(x: u64) -> u64 { (x.count_ones() % 2) as u64 }
fn implicant_widths(n: u32, f: &dyn Fn(u64) -> bool) -> Vec<u32> {
    let mut out = vec![];
    for t in 0..3u64.pow(n) {
        let (mut mask, mut val) = (0u64, 0u64);
        for i in 0..n {
            let d = t / 3u64.pow(i) % 3;
            if d > 0 { mask |= 1 << i; val |= (d - 1) << i; }
        }
        if mask > 0 && (0..1u64 << n).filter(|x| x & mask == val).all(|x| f(x)) { out.push(mask.count_ones()); }
    }
    out
}
type Gate = (bool, Vec<i64>); // (is AND, inputs); input -(2i+v)-1 means "staff i is v"
fn build(n: usize, ks: &[usize]) -> Vec<Gate> {
    let mut gates: Vec<Gate> = vec![];
    let mut nodes: Vec<[Vec<i64>; 2]> = (0..n as i64).map(|i| [vec![-2 * i - 1], vec![-2 * i - 2]]).collect();
    for (l, &k) in ks.iter().enumerate() {
        let odd = l % 2 == 0;
        let mut new = vec![];
        for b in (0..nodes.len()).step_by(k) {
            let (kids, mut node): (&[[Vec<i64>; 2]], [Vec<i64>; 2]) = (&nodes[b..b + k], [vec![], vec![]]);
            let vs: Vec<usize> = if nodes.len() == k { vec![1] } else { vec![0, 1] };
            for &v in &vs {
                for a in 0..1usize << k {
                    let bits: Vec<usize> = (0..k).map(|j| a >> j & 1).collect();
                    if (bits.iter().sum::<usize>() % 2 == v) != odd { continue; }
                    let ins: Vec<i64> = (0..k).flat_map(|j| kids[j][if odd { bits[j] } else { 1 - bits[j] }].iter().cloned()).collect();
                    gates.push((odd, ins)); node[v].push(gates.len() as i64 - 1);
                }
            }
            new.push(node);
        }
        nodes = new;
    }
    gates.push((ks.len() % 2 == 0, nodes[0][1].clone()));
    gates
}
fn run(gates: &[Gate], x: u64) -> u64 {
    let mut out: Vec<bool> = vec![];
    for (is_and, ins) in gates {
        let val = |r: &i64| if *r >= 0 { out[*r as usize] } else { let m = (-r - 1) as u64; (x >> (m / 2) & 1) == m % 2 };
        out.push(if *is_and { ins.iter().all(val) } else { ins.iter().any(val) });
    }
    *out.last().unwrap() as u64
}
fn depth(gates: &[Gate]) -> usize {
    let mut d: Vec<usize> = vec![];
    for (_, ins) in gates { let m = ins.iter().filter(|r| **r >= 0).map(|r| d[*r as usize]).max().unwrap_or(0); d.push(1 + m); }
    *d.last().unwrap()
}
fn formula(n: u64, ks: &[usize]) -> u64 {
    let (mut total, mut m) = (1u64, n);
    for &k in ks { m /= k as u64; total += if m > 1 { m << k } else { 1 << (k - 1) }; }
    total
}
fn splitmix(s: &mut u64) -> u64 {
    *s = s.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = (*s ^ (*s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}
fn log_road(n: i32, top: u64) -> u64 {
    let (mut lo, mut hi) = (1u64, top);
    while hi - lo > 1 {
        let (mid, m) = ((lo + hi) / 2, ((lo + hi) / 2) as f64);
        if m * (16.0 * (n as f64 + m).powi(2)).log2() < 2f64.powi(n) { lo = mid } else { hi = mid }
    }
    lo
}
fn pow_bits(base: u64, e: u64) -> u64 { // bit length of base^e, by schoolbook big-integer multiplication
    let mut limbs: Vec<u64> = vec![1];
    for _ in 0..e {
        let mut carry = 0u128;
        for l in limbs.iter_mut() { let p = *l as u128 * base as u128 + carry; *l = p as u64; carry = p >> 64; }
        if carry > 0 { limbs.push(carry as u64); }
    }
    64 * (limbs.len() as u64 - 1) + 64 - limbs.last().unwrap().leading_zeros() as u64
}
fn main() {
    println!("rota: 8 staff; flag the night when its headcount is odd (parity)");
    println!("rota with staff 1, 2, 5 on: count {}, parity {}, flag", 0b10011u64.count_ones(), parity(0b10011));
    let rows: Vec<Vec<u32>> = (2..9).map(|n| implicant_widths(n, &|x| parity(x) == 1)).collect();
    println!("depth 2, all 3^n AND terms tested: terms that never fire on an even rota");
    println!("  staff n      {}", (2..9).map(|n| format!("{:>5}", n)).collect::<String>());
    println!("  such terms   {}", rows.iter().map(|r| format!("{:>5}", r.len())).collect::<String>());
    println!("  narrowest    {}", rows.iter().map(|r| format!("{:>5}", r.iter().min().unwrap())).collect::<String>());
    println!("depth-2 circuit for 8 staff needs {} AND gates + 1 OR = {} gates", rows[6].len(), rows[6].len() + 1);
    let (mut seed, mut tests) = (2026u64, vec![]);
    let cfgs: Vec<(u64, Vec<usize>)> = vec![(8, vec![8]), (8, vec![4, 2]), (8, vec![2, 2, 2]), (64, vec![8, 8]), (64, vec![4, 4, 4]), (64, vec![2; 6])];
    for (n, ks) in &cfgs {
        let g = build(*n as usize, ks);
        let xs: Vec<u64> = if *n == 8 { (0..256).collect() } else { (0..64).map(|_| splitmix(&mut seed)).collect() };
        let ok = xs.iter().all(|&x| run(&g, x) == parity(x));
        let kmax = *ks.iter().max().unwrap();
        tests.push((depth(&g), g.len() as u64, formula(*n, ks), n << kmax, ok, ks.len() + 1));
        println!("built n={:>2} blocks {:<18} depth {} gates {:>4} formula {:>4} bound n*2^k {:>5} inputs tested {:>3} all right {}",
                 n, format!("{:?}", ks), depth(&g), g.len(), formula(*n, ks), n << kmax, xs.len(), if ok { "yes" } else { "no" });
    }
    println!("64 staff at depth 2: 2^63 + 1 = {} gates", formula(64, &[64]));
    let mut bad = 0;
    for t in 0..3u64.pow(8) {
        let fixed: Vec<u64> = (0..8).map(|i| t / 3u64.pow(i) % 3).collect();
        let free: Vec<usize> = (0..8).filter(|&i| fixed[i] == 0).collect();
        let base: u64 = (0..8).filter(|&i| fixed[i] == 2).map(|i| 1u64 << i).sum();
        let mut vals = [false; 2];
        for a in 0..1u64 << free.len() {
            let x = base | (0..free.len()).filter(|&j| a >> j & 1 == 1).map(|j| 1u64 << free[j]).sum::<u64>();
            vals[parity(x) as usize] = true;
        }
        if (vals[0] != vals[1]) != free.is_empty() { bad += 1; }
    }
    println!("all 6561 restrictions of 8 staff: parity settled only when nobody is free: {}", if bad == 0 { "yes" } else { "no" });
    let n_draws = 100000u64;
    let mut cnt = [0u64; 3];
    for _ in 0..n_draws {
        let pick: Vec<u64> = (0..8).map(|_| splitmix(&mut seed) % 8).collect();
        let nfree = pick.iter().filter(|&&p| p < 2).count() as u64;
        if pick[..4].iter().all(|&p| p < 2 || p >= 5) && pick[..4].iter().any(|&p| p < 2) { cnt[0] += 1; }
        if nfree > 0 { cnt[1] += 1; } cnt[2] += nfree;
    }
    let exact = [0.625f64.powi(4) - 0.375f64.powi(4), 1.0 - 0.75f64.powi(8), 2.0];
    println!("random restrictions, {} draws, seed 2026: exact, simulated", n_draws);
    for (i, name) in ["4-person AND term undecided", "parity of 8 undecided", "free staff per draw"].iter().enumerate() { println!("  {:<28} {:.4} {:.4}", name, exact[i], cnt[i] as f64 / n_draws as f64); }
    for i in 0..2 { assert!((cnt[i] as f64 / n_draws as f64 - exact[i]).abs() < 4.0 * (exact[i] * (1.0 - exact[i]) / n_draws as f64).sqrt()); }
    let mut s = 0u64;
    while pow_bits(16 * (8 + s + 1) * (8 + s + 1), s + 1) <= 256 { s += 1; }
    let (bits, lo) = (pow_bits(16 * (8 + s) * (8 + s), s), log_road(64, 1 << 62).to_string());
    println!("counting: 2^256 functions of 8 inputs; circuits of at most {} two-input gates number below 2^{}", s, bits);
    println!("  so at most 1 function in 2^{} has a circuit of {} gates; at {} the bound passes 2^256", 256 - bits, s, s + 1);
    println!("  64 inputs: some function needs more than about {}.{}e{} gates", &lo[0..1], &lo[1..2], lo.len() - 1);
    println!("  best proven for one named function: about 3.1 gates per input, once n is large");
    let (mut p, mut c, mut i) = ([0usize, 1, 2, 3, 4, 5, 6, 7], [0usize; 8], 1usize);
    let ins_sort = |p: &[usize; 8]| { // binary insertion sort, counting comparisons
        let (mut done, mut cmp): (Vec<usize>, u64) = (vec![], 0);
        for &v in p.iter() {
            let (mut a, mut b) = (0, done.len());
            while a < b { let m = (a + b) / 2; cmp += 1; if done[m] < v { a = m + 1 } else { b = m } }
            done.insert(a, v);
        }
        cmp
    };
    let (mut worst, mut f8) = (ins_sort(&p), 1u64);
    while i < 8 { // Heap's algorithm visits every ordering once
        if c[i] < i { if i % 2 == 0 { p.swap(0, i) } else { p.swap(c[i], i) }; worst = worst.max(ins_sort(&p)); f8 += 1; c[i] += 1; i = 1; }
        else { c[i] = 0; i += 1; }
    }
    let need = (0..40).find(|&d| 1u64 << d >= f8).unwrap();
    println!("sorting 8 staff: 8! = {} orders; 2^{} = {} leaves too few, so >= {} comparisons; binary insertion worst {}", f8, need - 1, 1u64 << (need - 1), need, worst);
    println!("what breaks:\n  a parity gate allowed: 1 gate, depth 1");
    let w7: Vec<u64> = (0..256).filter(|x| x & 127 == 127).collect();
    println!("  term on staff 1-7 only: fires on {} rotas, {} of them even", w7.len(), w7.iter().filter(|&&x| parity(x) == 0).count());
    println!("  no depth limit: 8 staff {} gates at depth {}; 64 staff {} gates at depth {}", tests[2].1, tests[2].0, tests[5].1, tests[5].0);
    let ones = implicant_widths(8, &|x| x > 0).iter().filter(|&&w| w == 1).count();
    println!("  'anyone on?' instead: {} one-person terms, so a single {}-input OR gate", ones, ones);
    let g3 = build(3, &[3]);
    let terms: Vec<String> = g3[..g3.len() - 1].iter().map(|(_, ins)| ins.iter().map(|r| { let m = -r - 1; format!("{}x{}", if m % 2 == 1 { "" } else { "~" }, m / 2 + 1) }).collect::<Vec<_>>().join(" ")).collect();
    println!("figure, inputs x=40 y=60,140,220; AND x=220 y=40,110,180,250; OR x=400 y=145; terms {}", terms.join(" | "));
    assert!(rows.iter().zip(2..9u32).all(|(r, n)| r.len() == 1 << (n - 1))); // exhaustive = 2^(n-1)
    assert!(rows.iter().zip(2..9u32).all(|(r, n)| *r.iter().min().unwrap() == n)); // every term names everyone
    assert!(tests.iter().all(|t| t.1 == t.2 && t.1 <= t.3)); // built = formula <= bound
    assert!(tests.iter().all(|t| t.4 && t.0 == t.5)); // right answers, right depth
    assert!(bad == 0 && s == log_road(8, 256)); // restrictions; two counting roads
    assert!(worst >= need as u64 && worst == (1..=8u64).map(|i| 64 - (i - 1).leading_zeros() as u64).sum::<u64>() && ones == 8); // sorting; OR
    println!("ALL CHECKS PASS");
}
