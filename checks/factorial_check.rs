// Factorials -- the same check as the Python, in Rust.  No crates.  A playlist of
// 10 songs, 8 runners and a 20-song playlist.  The count of orderings is reached
// by roads that share no arithmetic: multiplying the choices down, a tally that
// only ever adds, and a listing of every ordering of a small set.
const SONGS: u32 = 10; const RUNNERS: u32 = 8; const BIG: u32 = 20;
const PI: f64 = 3.141592653589793; const E: f64 = 2.718281828459045;

fn multiply_down(n: u32) -> u64 {           // road one: n x (n-1) x ... x 1
    let mut out: u64 = 1;
    for k in (1..=n as u64).rev() { out *= k }
    out
}

fn by_adding(n: u32) -> u64 {               // road two: a tally that never multiplies
    let mut ways = vec![0u64; 1 << n];      // ways[s] = orderings of the songs in set s
    ways[0] = 1;
    for s in 1..(1usize << n) {
        let mut t = 0u64;
        for i in 0..n as usize { if s >> i & 1 == 1 { t += ways[s ^ (1 << i)] } }
        ways[s] = t;
    }
    ways[(1usize << n) - 1]
}

fn orderings(items: &str) -> Vec<String> {  // road three: build every ordering, then count
    if items.is_empty() { return vec![String::new()] }
    let mut out = Vec::new();
    for (i, x) in items.chars().enumerate() {
        let rest: String = items.chars().enumerate().filter(|&(j, _)| j != i).map(|(_, c)| c).collect();
        for tail in orderings(&rest) { out.push(format!("{}{}", x, tail)) }
    }
    out
}

fn stirling(n: u32) -> f64 {                // sqrt(2 pi n) x (n/e)^n, no library call
    let (mut p, under) = (1.0f64, 2.0 * PI * n as f64);   // under: the number whose root is wanted
    for _ in 0..n { p *= n as f64 / E }
    let mut g = under;                      // the root itself, by Newton's method
    for _ in 0..60 { g = 0.5 * (g + under / g) }
    g * p
}

fn commas(x: u64) -> String {               // 3628800 -> "3,628,800", the way Python prints it
    let s = x.to_string();
    let mut out = String::new();
    for (i, c) in s.chars().enumerate() {
        if i > 0 && (s.len() - i) % 3 == 0 { out.push(',') }
        out.push(c);
    }
    out
}

fn main() {
    let (ten, eight, f20) = (multiply_down(SONGS), multiply_down(RUNNERS), multiply_down(BIG));
    let (listed, three) = (orderings("ABCDEFGH"), orderings("ABC"));
    let small: Vec<u64> = (0..=SONGS).map(multiply_down).collect();
    let d_fact: Vec<usize> = (0..=BIG).map(|n| multiply_down(n).to_string().len()).collect();
    let d_two: Vec<usize> = (0..=BIG).map(|n| (1u64 << n).to_string().len()).collect();
    let d_sq: Vec<usize> = (0..=BIG).map(|n| ((n as u64) * (n as u64)).to_string().len()).collect();
    let (s20, f20f) = (stirling(BIG), f20 as f64);   // f20f: the same 20!, as a decimal
    let mut wrong: u64 = 0;                 // 0! taken as 0, then the recurrence applied
    for n in 1..=SONGS as u64 { wrong *= n }
    println!("{:<74} = {}", "10 songs, one position at a time: 10 x 9 x 8 x 7 x 6 x 5 x 4 x 3 x 2 x 1", commas(ten));
    println!("{:<74} = {}", "the same count, by a tally that only ever adds", commas(by_adding(SONGS)));
    println!("8 runners by multiplying down: {}; every ordering built and counted: {}", commas(eight), commas(listed.len() as u64));
    println!("the 3-song playlists, all {} of them: {}", three.len(), three.join(" "));
    println!("0! up to 10!: {:?}; n! first passes 2^n at n = 4, {} against {}", small, multiply_down(4), 1u64 << 4);
    println!("digits in n!,  n = 0 to 20: {:?}", d_fact);
    println!("digits in 2^n, n = 0 to 20: {:?}", d_two);
    println!("digits in n^2, n = 0 to 20: {:?}", d_sq);
    println!("20! exactly: {}", commas(f20));
    println!("Stirling's estimate of 20!, then 20! itself, in units of a million million million: {:.6} and {:.6}", s20 / 1e18, f20f / 1e18);
    println!("Stirling divided by 20! = {:.6}, low by {:.3} percent; the gap it leaves, same units: {:.6}", s20 / f20f, (1.0 - s20 / f20f) * 100.0, (f20f - s20) / 1e18);
    println!("mistake 1, 0! taken as 0: 10! reads {}; mistake 2, repeats allowed: {}; mistake 3, one song on twice: {}", wrong, commas(10u64.pow(SONGS)), commas(ten / 2));
    assert!(ten == by_adding(SONGS) && ten == 3628800);
    assert!(listed.len() as u64 == eight && eight == 40320 && orderings("ABCD").len() == 24);
    assert!((1..9u32).all(|n| by_adding(n) == n as u64 * multiply_down(n - 1)));
    assert!(s20 / f20f > 0.9958 && s20 / f20f < 0.9959 && f20f - s20 > 1.0e16);
    println!("ALL CHECKS PASS");
}
