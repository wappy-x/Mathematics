// A recurrence is a matrix -- the same check as the Python, in Rust.  No crates.
// A hallway 2 feet wide and n feet long is tiled with 1 x 2 tiles: T(n) ways.
// Four roads to the count: laying real tiles, stepping the rule, powers of the
// companion matrix M = [[1, 1], [1, 0]], and Binet from M's two eigenvalues.
const N: u32 = 10;
const MOD: i64 = 1000000007;
const FAR: u32 = 1000000;
type Mat = [[i64; 2]; 2];

fn tilings(n: u32, used: u32) -> i64 {          // road one: lay real tiles, no formula
    if used == (1u32 << (2 * n)) - 1 { return 1 }
    let mut k = 0;
    while used >> k & 1 == 1 { k += 1 }         // first empty cell, numbered row + 2 x column
    let v = if k % 2 == 0 && used >> (k + 1) & 1 == 0 { tilings(n, used | 3 << k) } else { 0 };
    v + if k / 2 + 1 < n && used >> (k + 2) & 1 == 0 { tilings(n, used | 5 << k) } else { 0 }
}

fn mul(a: Mat, b: Mat, m: i64) -> Mat {         // 2 x 2 matrix product, wrapped if m > 0
    let mut o = [[0i64; 2]; 2];
    for i in 0..2 { for j in 0..2 { o[i][j] = a[i][0] * b[0][j] + a[i][1] * b[1][j];
                                    if m > 0 { o[i][j] %= m } } }
    o
}

fn power(a: Mat, n: u32, m: i64) -> (Mat, i64) {        // road two: square and multiply
    let (mut a, mut n) = (a, n);
    let (mut out, mut mults) = ([[1i64, 0], [0, 1]], -1i64);  // opening identity multiply is free
    while n > 0 {
        if n & 1 == 1 { out = mul(out, a, m); mults += 1 }
        n >>= 1;
        if n > 0 { a = mul(a, a, m); mults += 1 }
    }
    (out, if mults > 0 { mults } else { 0 })
}

fn step(n: u32, m: i64) -> (i64, u32) {         // road three: one foot at a time
    let (mut a, mut b, mut adds) = (1i64, 1i64, 0u32);        // T(0) = 1 empty hallway, T(1) = 1
    for _ in 0..n - 1 { let s = if m > 0 { (a + b) % m } else { a + b }; a = b; b = s; adds += 1 }
    (b, adds)
}

fn main() {
    let m0: Mat = [[1, 1], [1, 0]];
    let (brute, (p10, mults), (stepped, adds)) = (tilings(N, 0), power(m0, N, 0), step(N, 0));
    let mut r5 = 2.0f64;
    for _ in 0..40 { r5 = (r5 + 5.0 / r5) / 2.0 }            // our own square root of 5, by Newton
    let (phi, psi) = ((1.0 + r5) / 2.0, (1.0 - r5) / 2.0);
    let (mut fp, mut fq) = (1.0f64, 1.0f64);
    for _ in 0..N + 1 { fp *= phi; fq *= psi }               // the two roots to the 11th, by hand
    let binet = (fp - fq) / r5;
    let det_m = m0[0][0] * m0[1][1] - m0[0][1] * m0[1][0];
    let det_pow = det_m.pow(N);
    let cassini = p10[0][0] * p10[1][1] - p10[0][1] * p10[1][0];
    let ((far_pow, far_mults), (far_step, far_adds)) = (power(m0, FAR, MOD), step(FAR, MOD));
    let wrong = power([[1, 1], [0, 1]], N, 0).0;
    let entry: Mat = [[m0[0][0].pow(N), m0[0][1].pow(N)], [m0[1][0].pow(N), m0[1][1].pow(N)]];
    let ladder: Vec<String> = [1u32, 2, 4, 8].iter().map(|&e| format!("M^{} = {:?}", e, power(m0, e, 0).0)).collect();
    println!("hallway 2 feet wide, {} feet long, tiles 1 x 2: {} tilings, laid one by one", N, brute);
    println!("the ladder: {}", ladder.join(", "));
    let split: Vec<String> = (0..32).rev().filter(|&i| N >> i & 1 == 1).map(|i| format!("M^{}", 1u32 << i)).collect();
    println!("M^{} = {} = {:?}, reached in {} matrix multiplications", N, split.join(" x "), p10, mults);
    println!("the stacks: ({}, {}) -> ({}, {}) -> ({}, {})",
             p10[0][1], p10[1][1], p10[0][0], p10[0][1], p10[0][0] + p10[0][1], p10[0][0]);
    println!("stepping the rule one foot at a time: {} at {} feet, in {} additions", stepped, N, adds);
    println!("trace {}, determinant {}; eigenvalues {:.12} and {:.12}", m0[0][0] + m0[1][1], det_m, phi, psi);
    println!("each eigenvalue squared, minus itself: {:.12} and {:.12}", phi * phi - phi, psi * psi - psi);
    println!("Binet from those roots at {}: {:.9}, rounding to {}", N + 1, binet, binet.round() as i64);
    println!("Cassini: {} x {} - {} x {} = {}, and ({})^{} = {}",
             p10[0][0], p10[1][1], p10[0][1], p10[1][0], cassini, det_m, N, det_pow);
    println!("term {} wrapped at {}, by squaring: {}, in {} matrix multiplications", FAR, MOD, far_pow[0][0], far_mults);
    println!("the same term, by {} additions: {}", far_adds, far_step);
    println!("mistake 1, the matrix written [[1, 1], [0, 1]]: {:?}, top-left {}, not {}", wrong, wrong[0][0], brute);
    println!("mistake 2, each entry raised to the {}th on its own: {:?}, top-left {}; mistake 3, the stack (1, 1) carried through M^{}: {}, one foot too far",
             N, entry, entry[0][0], N, p10[0][0] + p10[0][1]);
    assert!(brute == p10[0][0] && p10[0][0] == stepped && stepped == binet.round() as i64);
    assert!(cassini == det_pow && far_pow[0][0] == far_step && far_mults == (FAR.count_ones() + FAR.ilog2() - 1) as i64 && far_mults < far_adds as i64);
    assert!((phi + psi - (m0[0][0] + m0[1][1]) as f64).abs() < 1e-12 && (phi * psi - det_m as f64).abs() < 1e-12);
    assert!(mults == (N.count_ones() + N.ilog2() - 1) as i64 && mults < adds as i64 && (phi * phi - phi - 1.0).abs() < 1e-12);
    println!("ALL CHECKS PASS");
}
