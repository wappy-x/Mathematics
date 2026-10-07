// Counting coin-flip paths -- the same check as the Python, in Rust.  No crates.
// Ten fair flips scored +1 for heads and -1 for tails; the path is the running
// total.  Every count is reached twice: once by walking all 2^n sequences step
// by step, once from a closed form built out of a product written out here.
const N: i64 = 10;                            // ten flips
const M: i64 = 4;                             // and a four-flip warm-up

fn choose(n: i64, k: i64) -> i64 {            // C(n, k), built here, no crates
    if k < 0 || k > n { return 0 }
    let (mut top, mut bot) = (1i64, 1i64);
    for i in 0..k { top *= n - i; bot *= i + 1 }
    top / bot
}

fn catalan(m: i64) -> i64 {                   // the m-th Catalan number
    choose(2 * m, m) / (m + 1)
}

fn walk(n: i64) -> (Vec<i64>, i64, i64) {     // road one: every +1/-1 sequence, one at a time
    let mut ends = vec![0i64; (2 * n + 1) as usize];  // ends[h + n]: paths finishing at h
    let (mut dyck, mut high) = (0i64, 0i64);  // never below zero; strictly above zero between
    for code in 0..(1i64 << n) {
        let (mut s, mut low, mut inner) = (0i64, 0i64, n);  // height, lowest, lowest before the end
        for k in 1..=n {
            s += if (code >> (k - 1)) & 1 == 1 { 1 } else { -1 };
            if s < low { low = s }
            if k < n && s < inner { inner = s }
        }
        ends[(s + n) as usize] += 1;
        if s == 0 && low >= 0 { dyck += 1 }
        if s == 0 && inner > 0 { high += 1 }
    }
    (ends, dyck, high)
}

fn formula(n: i64) -> (Vec<i64>, i64, i64) {  // road two: the closed forms, nothing listed
    let ends = (-n..=n)
        .map(|h| if (n + h) % 2 == 0 { choose(n, (n + h) / 2) } else { 0 })
        .collect();
    (ends, catalan(n / 2), catalan(n / 2 - 1))
}

fn row(name: &str, values: &[i64]) {
    let mut line = format!("{:<24}", name);
    for v in values { line.push_str(&format!("{:>5}", v)) }
    println!("{}", line);
}

fn main() {
    let (seen, dyck, high) = walk(N);
    let (calc, dyck_c, high_c) = formula(N);
    let (small, small_dyck, small_high) = walk(M);
    let evens: Vec<i64> = (-N..=N).step_by(2).collect();
    let at = |v: &Vec<i64>, h: i64| v[(h + N) as usize];
    let total: i64 = seen.iter().sum();
    println!("{} flips scored +1/-1: 2^{} = {} sequences, {} paths listed", N, N, 1i64 << N, total);
    row("ending height", &evens);
    row("paths, by listing", &evens.iter().map(|&h| at(&seen, h)).collect::<Vec<i64>>());
    row("paths, by C(n, (n+h)/2)", &evens.iter().map(|&h| at(&calc, h)).collect::<Vec<i64>>());
    println!("end level, height 0: listed {}, C({}, {}) = {}", at(&seen, 0), N, N / 2, at(&calc, 0));
    println!("end at +2:           listed {}, C({}, {}) = {}", at(&seen, 2), N, (N + 2) / 2, at(&calc, 2));
    println!("never below zero:    listed {}, C({}, {})/{} = {}", dyck, N, N / 2, N / 2 + 1, dyck_c);
    println!("strictly above zero: listed {}, C({}, {})/{} = {}", high, N - 2, N / 2 - 1, N / 2, high_c);
    println!("{} flips: {} sequences, {} end level, {} never below zero, {} strictly above",
             M, 1i64 << M, small[M as usize], small_dyck, small_high);
    println!("mistake 1, ending at +1 in {} flips: {} + 1 is odd, so {} paths", N, N, at(&calc, 1));
    println!("mistake 2, C({}, 2) from the height, not the head count: {}, not {}",
             N, choose(N, 2), at(&calc, 2));
    println!("mistake 3, {} shared among {} instead of {}: {:.1}, not a whole number",
             at(&calc, 0), N / 2, N / 2 + 1, at(&calc, 0) as f64 / (N / 2) as f64);
    println!("mistake 4, the never-below count used for the strictly-above one: {}, not {}", dyck, high);
    assert!(seen == calc);                                      // two roads, one distribution
    assert!(calc.iter().sum::<i64>() == 1i64 << N && at(&seen, 0) == 252);  // the row sums to 2^n
    assert!((dyck, high) == (42, 14) && (dyck_c, high_c) == (42, 14));  // listing against closed form
    assert!(small == vec![1, 0, 4, 0, 6, 0, 4, 0, 1] && (small_dyck, small_high) == (2, 1));
    println!("ALL CHECKS PASS");
}
