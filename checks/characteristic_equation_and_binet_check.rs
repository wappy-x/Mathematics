// The characteristic equation and Binet -- the same check as the Python, in Rust.
// No crates.  A hallway 2 tiles wide and n long is covered with 1 x 2 tiles, counted
// twice: by laying tiles on the grid one at a time, and by Binet's formula with the
// square root of 5 worked out here.  Two more step rules follow, 5, -6 and 4, -4.
fn root(x: f64) -> f64 {                        // Newton's method, no crates
    let mut g = x;
    for _ in 0..60 { g = (g + x / g) / 2.0 }
    g
}

fn pw(x: f64, k: u32) -> f64 {                  // powers by repeated multiplying
    let mut out = 1.0;
    for _ in 0..k { out *= x }
    out
}

fn lay(used: u32, full: u32, n: u32) -> i64 {   // road one: lay tiles on the grid
    if used == full { return 1 }
    let mut i = 0u32;
    while used >> i & 1 == 1 { i += 1 }
    let (r, c, mut ways) = (i / n, i % n, 0);
    if c + 1 < n && used >> (i + 1) & 1 == 0 { ways += lay(used | 1 << i | 1 << (i + 1), full, n) }
    if r == 0 && used >> (i + n) & 1 == 0 { ways += lay(used | 1 << i | 1 << (i + n), full, n) }
    ways
}

fn tilings(n: u32) -> i64 { lay(0, (1u32 << (2 * n)) - 1, n) }

fn run(c1: i64, c2: i64, a0: i64, a1: i64, big_n: usize) -> Vec<i64> {   // road two
    let mut a = vec![a0, a1];
    while a.len() <= big_n { let k = a.len(); a.push(c1 * a[k - 1] + c2 * a[k - 2]) }
    a.truncate(big_n + 1);
    a
}

fn row(name: &str, xs: &[i64]) {
    let parts: Vec<String> = xs.iter().map(|x| x.to_string()).collect();
    println!("{:<40}{}", name, parts.join(" "));
}

fn main() {
    let s5 = root(5.0);
    let (phi, psi) = ((1.0 + s5) / 2.0, (1.0 - s5) / 2.0);
    let binet = |n: u32| (pw(phi, n) - pw(psi, n)) / s5;   // road three: the closed form
    let hall: Vec<i64> = (0..11).map(tilings).collect();
    let f = run(1, 1, 0, 1, 20);
    let (second, closed) = (run(5, -6, 2, 5, 8), (0..9).map(|n| 2i64.pow(n) + 3i64.pow(n)).collect::<Vec<i64>>());
    let (rep, repclosed) = (run(4, -4, 1, 6, 7), (0..8).map(|n| (1 + 2 * n as i64) * 2i64.pow(n)).collect::<Vec<i64>>());
    let gaps: Vec<f64> = (0..21).map(|n| (pw(psi, n) / s5).abs()).collect();
    let best = gaps.iter().cloned().fold(0.0f64, f64::max);
    let at = gaps.iter().position(|g| *g == best).unwrap();
    let bin13: Vec<i64> = (0..13).map(|n| binet(n).round() as i64).collect();
    println!("sqrt(5) = {:.10}, phi = {:.10}, psi = {:.10}", s5, phi, psi);
    row("hallway 2 x n, tiles laid one by one:", &hall);
    row("F(0)..F(12) from the step rule:", &f[..13]);
    row("F(0)..F(12) from Binet, rounded:", &bin13);
    println!("the 2 x 10 hallway: {} coverings by laying tiles, F(11) = {} by the step rule", hall[10], f[11]);
    println!("phi^10/sqrt(5) = {:.10}, psi^10/sqrt(5) = {:.10}, Binet F(10) = {:.10}", pw(phi, 10) / s5, pw(psi, 10) / s5, binet(10));
    println!("phi^11/sqrt(5) = {:.10}, psi^11/sqrt(5) = {:.10}, Binet F(11) = {:.10}", pw(phi, 11) / s5, pw(psi, 11) / s5, binet(11));
    println!("largest small-root gap over n = 0..20: {:.10} at n = {}, under one half", best, at);
    row("weights 5, -6 from seeds 2, 5:", &second);
    row("the same list from 2^n + 3^n:", &closed);
    row("weights 4, -4 from seeds 1, 6:", &rep);
    row("the same list from (1 + 2n) 2^n:", &repclosed);
    println!("mistake 1, no n at the repeated root: a(7) = {}, not {}", 2i64.pow(7), rep[7]);
    println!("mistake 2, signs carried straight across: a(4) = {}, not {}", 11 * (-2i64).pow(4) - 9 * (-3i64).pow(4), second[4]);
    println!("mistake 3, constants fitted to seeds 2, 3: a(4) = {}, not {}", 3 * 2i64.pow(4) - 3i64.pow(4), second[4]);
    let bin20: Vec<i64> = (0..21).map(|n| binet(n).round() as i64).collect();
    assert!(hall == f[1..12].to_vec());          // laying tiles against the step rule
    assert!(bin20 == f);                         // Binet against the step rule
    assert!(second == closed);                   // roots 2 and 3, fitted to the seeds
    assert!(rep == repclosed);                   // the repeated root needs its n
    println!("ALL CHECKS PASS");
}
