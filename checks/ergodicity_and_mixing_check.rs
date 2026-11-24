// Ergodicity and mixing -- the same check as the Python, in Rust.  No crates.
// Maps on [0, 1), sizes measured by length: rotation x -> x + alpha mod 1, and
// doubling x -> 2x mod 1.
use std::f64::consts::PI;

const GRID: usize = 100000;                       // grid points

fn alpha() -> f64 { 2f64.sqrt() - 1.0 }           // the irrational turn

fn frac(x: f64) -> f64 { x - x.floor() }

fn dist(t: f64) -> f64 { (t - (t + 0.5).floor()).abs() } // distance to the nearest whole number

fn doubling_overlap(a: f64, b: f64, n: i32) -> f64 {  // road 1: m(D^-n [0,a) and [0,b)) by intervals
    let w = 2f64.powi(-n);                        // D^-n [0,a) is 2^n strips [j w, (j + a) w)
    let mut s = 0.0;
    for j in 0..(1u64 << n) {
        let lo = j as f64 * w;
        if lo < b { s += (lo + a * w).min(b) - lo }
    }
    s
}

fn doubling_grid(a3: u64, b3: u64, n: u32, bits: u32) -> f64 { // road 2: count grid points j / 2^bits
    let full: u64 = 1 << bits;                    // a3, b3: set is [0, 1/a3), shifting is exact
    let mut hits = 0u64;
    for j in 0..full {
        let y = (j << n) & (full - 1);
        if a3 * y < full && b3 * j < full { hits += 1 }
    }
    hits as f64 / full as f64
}

fn rotation_overlap(b: f64, n: usize) -> f64 { (b - dist(n as f64 * alpha())).max(0.0) }

fn rotation_grid(b: f64, n: usize) -> f64 {       // the same overlap by counting grid midpoints
    let c = (0..GRID).map(|i| (i as f64 + 0.5) / GRID as f64)
        .filter(|&x| x < b && frac(x + n as f64 * alpha()) < b).count();
    c as f64 / GRID as f64
}

fn bits_stream(count: usize) -> Vec<u8> {         // xorshift64: the binary digits of one start
    let mut s: u64 = 88172645463325252;
    let mut out = Vec::with_capacity(count);
    for _ in 0..count {
        s ^= s << 13;
        s ^= s >> 7;
        s ^= s << 17;
        out.push((s >> 63) as u8);
    }
    out
}

fn mean_wait(table: &[Option<usize>], starts: &[usize]) -> f64 {
    let w: Vec<usize> = starts.iter().filter_map(|&i| table[i + 1].map(|t| t - i)).collect();
    w.iter().sum::<usize>() as f64 / w.len() as f64
}

fn ret_rot(x: f64, turn: f64, b: f64) -> usize {
    let mut n = 1;
    while frac(x + n as f64 * turn) >= b { n += 1 }
    n
}

fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }

fn main() {
    let al = alpha();
    println!("-- rotation by 1/2; A = [0,1/4) and [1/2,3/4), as quarter cells");
    let cells = vec![0usize, 2];
    let back: Vec<usize> = (0..4).filter(|c| cells.contains(&((c + 2) % 4))).collect();
    println!("cells of A {:?}; cells of R^-1 A {:?}; invariant: {}; m(A) = {:.6}", cells, back, yn(back == cells), cells.len() as f64 / 4.0);
    let e: Vec<String> = (1..5).map(|k| format!("{:.6}", 2.0 * (PI * k as f64 / 2.0).sin().abs())).collect();
    println!("|e^(2 pi i k/2) - 1| for k = 1..4: {}", e.join(" "));
    let m = 40000usize;                           // road 2: c_k by a midpoint sum, as |re + i im|
    let xs: Vec<f64> = (0..m).map(|i| (i as f64 + 0.5) / m as f64)
        .filter(|&x| cells.contains(&((4.0 * x) as usize))).collect();
    let ck: Vec<f64> = [1.0, 2.0, 3.0].iter().map(|&k: &f64| {
        let re: f64 = xs.iter().map(|&x| (2.0 * PI * k * x).cos()).sum::<f64>() / m as f64;
        let im: f64 = xs.iter().map(|&x| (2.0 * PI * k * x).sin()).sum::<f64>() / m as f64;
        re.hypot(im)
    }).collect();
    println!("|c_1|, |c_2|, |c_3| of the indicator, by integration: {:.6} {:.6} {:.6}; 1/pi = {:.6}", ck[0], ck[1], ck[2], 1.0 / PI);
    let pars = 0.25 + 2.0 * (1..2000).step_by(2).map(|j| (1.0 / (PI * j as f64)).powi(2)).sum::<f64>();
    println!("Parseval: c_0^2 + sum of |c_k|^2 for 0 < |k| < 4000 = {:.6}, against m(A) = 0.5", pars);
    let share: Vec<f64> = [0.1, 0.3].iter().map(|&x0: &f64| (0..10000)
        .filter(|&n| cells.contains(&((4.0 * frac(x0 + 0.5 * n as f64)) as usize))).count() as f64 / 10000.0).collect();
    println!("share of 10000 orbit points in A: start 0.1 -> {:.4}, start 0.3 -> {:.4}", share[0], share[1]);

    println!("-- rotation by alpha = sqrt2 - 1 = {:.6}", al);
    let gaps: Vec<f64> = (1..1001).map(|k| 2.0 * (PI * k as f64 * al).sin().abs()).collect();
    let gmin = gaps.iter().cloned().fold(f64::INFINITY, f64::min);
    let kmin = 1 + gaps.iter().position(|&g| g == gmin).unwrap();
    let mut pell: Vec<usize> = vec![1, 2];        // second road: the continued fraction [0; 2, 2, 2, ...]
    while *pell.last().unwrap() < 1000 { let l = pell.len(); pell.push(2 * pell[l - 1] + pell[l - 2]) }
    println!("|e^(2 pi i k alpha) - 1|: k = 1 -> {:.6}, k = 2 -> {:.6}; smallest for k <= 1000: k = {} -> {:.6}", gaps[0], gaps[1], kmin, gmin);
    println!("denominators of the continued fraction: {:?}", &pell[..pell.len() - 1]);
    let sh = (0..10000).filter(|&n| frac(0.1 + n as f64 * al) < 0.5).count() as f64 / 10000.0;
    println!("share of 10000 orbit points in [0,1/2), start 0.1: {:.4}", sh);

    println!("-- doubling, A = B = [0,1/2): m(D^-n A and B) by intervals, by a 2^16 grid");
    for n in 1..6 { println!("n = {}: {:.6} {:.6}", n, doubling_overlap(0.5, 0.5, n), doubling_grid(2, 2, n as u32, 16)) }
    println!("doubling swaps 1/3 and 2/3: D(1/3) = {:.6}, D(2/3) = {:.6}", frac(2.0 / 3.0), frac(4.0 / 3.0));
    let d_int: Vec<f64> = (1..6).map(|n| doubling_overlap(0.5, 0.5, n)).collect();

    println!("-- the overlap as n grows, A = B = [0,1/3), as a multiple of m(A)m(B) = 1/9");
    println!(" n  doubling  rotation");
    let rows: Vec<(usize, f64, f64)> = (1..13usize)
        .map(|n| (n, 9.0 * doubling_overlap(1.0 / 3.0, 1.0 / 3.0, n as i32), 9.0 * rotation_overlap(1.0 / 3.0, n))).collect();
    for &(n, d, r) in &rows { println!("{:2}  {:.5}   {:.5}", n, d, r) }
    let grid_gap = rows[..8].iter().map(|&(n, d, _)| (doubling_grid(3, 3, n as u32, 18) - d / 9.0).abs()).fold(0.0, f64::max);
    let rot_gap = rows.iter().map(|&(n, _, r)| (rotation_grid(1.0 / 3.0, n) - r / 9.0).abs()).fold(0.0, f64::max);

    println!("-- rotation by alpha is never mixing: A = B = [0,1/2), target m(A)m(B) = 0.25");
    for n in [3usize, 70, 169, 985] {
        println!("n = {:3}: distance of n alpha to a whole number {:.6}; overlap {:.6}", n, dist(n as f64 * al), rotation_overlap(0.5, n))
    }

    println!("-- Kac: mean return time to A");
    let pr: Vec<f64> = (1..61).map(|n| 2f64.powi(-n)).collect(); // doubling, A = [0,1/2): return at n is n - 1 ones, then a 0
    let series: f64 = pr.iter().enumerate().map(|(i, p)| (i + 1) as f64 * p).sum();
    let digits = bits_stream(1000000);
    let len = digits.len();
    let (mut nxt, mut nxt00) = (vec![None; len + 1], vec![None; len + 1]);
    for i in (0..len).rev() {                     // next 0 digit, and next "00", at or after i
        nxt[i] = if digits[i] == 0 { Some(i) } else { nxt[i + 1] };
        nxt00[i] = if digits[i] == 0 && i + 1 < len && digits[i + 1] == 0 { Some(i) } else { nxt00[i + 1] };
    }
    let in_a: Vec<usize> = (0..len - 1).filter(|&i| digits[i] == 0).collect();
    let in_a4: Vec<usize> = (0..len - 1).filter(|&i| digits[i] == 0 && digits[i + 1] == 0).collect();
    let all: Vec<usize> = (0..len - 1).collect();
    let (ret2, ret4, wait4) = (mean_wait(&nxt, &in_a), mean_wait(&nxt00, &in_a4), mean_wait(&nxt00, &all));
    let p4: Vec<String> = pr[..4].iter().map(|p| format!("{:.4}", p)).collect();
    println!("doubling, A = [0,1/2): P(r = n) for n = 1..4: {}", p4.join(" "));
    println!("  mean by the series {:.6}; along 10^6 digits of one orbit {:.4}", series, ret2);
    let (l1, l2) = (0.5 - al, 2.0 * al - 0.5);    // rotation by alpha: lengths with r = 1 (and 3), r = 2
    let gr: Vec<usize> = (0..GRID / 2).map(|i| ret_rot((i as f64 + 0.5) / GRID as f64, al, 0.5)).collect();
    let gmean = gr.iter().sum::<usize>() as f64 / gr.len() as f64;
    println!("rotation by alpha, A = [0,1/2): length with r = 1: {:.6}, r = 2: {:.6}, r = 3: {:.6}", l1, l2, l1);
    println!("  mean by lengths {:.6}; by a grid of 50000 starts {:.6}", (l1 + 2.0 * l2 + 3.0 * l1) / 0.5, gmean);
    let half: Vec<usize> = (0..GRID / 4).map(|i| ret_rot((i as f64 + 0.5) / GRID as f64, 0.5, 0.25)).collect();
    let (hmin, hmax) = (*half.iter().min().unwrap(), *half.iter().max().unwrap());
    let e1 = (1.0 + 0.5) / (1.0 - 0.75);          // pattern "00": expected digits to complete it
    println!("mistake 1: rotation by 1/2, A = [0,1/4): every return time is {} (largest {}), not 1/m(A) = 4", hmin, hmax);
    println!("mistake 2: rotation by alpha, A = [0,1/2): n = 3 gives {:.4}, n = 70 gives {:.4}", rotation_overlap(0.5, 3), rotation_overlap(0.5, 70));
    println!("mistake 3: doubling, A = [0,1/4): return {:.4}; wait from a random start {:.4}; exact {:.6}", ret4, wait4, e1 - 1.0);
    println!("mistake 4: rotation by 1/2 from 0.1 spends {:.4} of its time in A, not m(A) = 0.5", share[0]);
    assert!(back == cells && (ck[1] - 1.0 / PI).abs() < 1e-6 && ck[0].abs() < 1e-9); // A invariant, |c_2| = 1/pi
    assert!((pars - 0.5).abs() < 1e-4);           // Parseval's total meets the cell count m(A)
    assert!(kmin == pell[pell.len() - 2] && gmin > 0.0); // near-returns sit at the continued-fraction q
    assert!(d_int.iter().all(|d| (d - 0.25).abs() < 1e-12)); // exact mixing for dyadic sets, by intervals ...
    assert!((1..16).all(|n| doubling_grid(2, 2, n, 16) == 0.25)); // ... and by the grid
    assert!(grid_gap < 2e-3 && rot_gap < 1e-4 && (rows[11].1 - 1.0).abs() < 1e-3);
    assert!((series - 2.0).abs() < 1e-12 && (ret2 - 2.0).abs() < 0.02 && (gmean - 2.0).abs() < 1e-3);
    assert!(((l1 + 2.0 * l2 + 3.0 * l1) / 0.5 - gmean).abs() < 1e-3); // turner: lengths against the grid
    assert!((ret4 - 4.0).abs() < 0.05 && (wait4 - 5.0).abs() < 0.05 && hmin == 2 && hmax == 2);
    assert!((sh - 0.5).abs() < 0.01 && rotation_overlap(0.5, 985) > 0.49);
    println!("ALL CHECKS PASS");
}
