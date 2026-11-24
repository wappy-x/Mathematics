// Transfinite induction -- the same check as the Python, in Rust.  No crates.  An
// ordinal below omega+omega is a pair (w, n), meaning omega*w + n.  Every value is
// a whole number over D = 2^60, so each step is exact; the value 1 is D itself.
const D: u128 = 1 << 60;
const N: usize = 60;
fn main() {
    let mut a = vec![vec![0u128; N + 1]; 3];              // zero: a(0) = 0
    let (zero, mut succ, mut limit) = ((a[0][0] <= D) as u32, 0, 0);
    for w in 0..3 {
        if w > 0 {                                         // limit: omega, omega+omega
            let run = a[w - 1].clone();                    // the earlier values
            let grid = (0..1001u128).find(|k| run.iter().all(|v| v * 1000 <= k * D)).unwrap();
            let tail = run[N] + (run[N] - run[N - 1]);     // the halving steps still to come
            assert!(grid == 1000 && tail == D);            // two roads to the bound: 1
            a[w][0] = tail;
            limit += (run.iter().all(|v| *v <= D) && a[w][0] <= D) as u32;
        }
        for n in 1..(if w < 2 { N + 1 } else { 1 }) {
            a[w][n] = (D + a[w][n - 1]) / 2;               // successor: (1 + a) / 2
            succ += (a[w][n - 1] <= D && a[w][n] <= D) as u32;
        }
    }
    let formula = (0..=N).all(|n| a[0][n] == D - D / (1u128 << n));   // 1 - 1/2^n
    let first = (0..=N).find(|n| a[0][*n] * 1000 > 999 * D).unwrap();
    let mut slip = 0;
    for _ in 0..3 { slip = 1 + slip; }                     // successor rule, halving dropped
    let frac = |n: usize| format!("{}/{}", a[0][n] * (1u128 << n) / D, 1u128 << n);
    let dec = |v: u128| v as f64 / D as f64;
    let sum10: u128 = (0..10).map(|n| a[0][n]).sum();
    println!("a(n) for n = 0 to 4: {}", (0..5).map(|n| frac(n)).collect::<Vec<_>>().join(", "));
    println!("a(n) = 1 - 1/2^n for every n from 0 to {}: {}", N, if formula { "yes" } else { "no" });
    println!("a({}) = {} = {}, the first value above 0.999", first, frac(first), dec(a[0][first]));
    println!("a(omega) = {}, a(omega+1) = {}, a(omega+5) = {}, a(omega+omega) = {}", a[1][0] / D, a[1][1] / D, a[1][5] / D, a[2][0] / D);
    println!("stages checked for a <= 1: zero {}, successor {}, limit {}", zero, succ, limit);
    println!("mistakes: biggest of first ten {}, sum of first ten {}, no halving a(3) = {}", dec(a[0][9]), dec(sum10), slip);
    assert!(formula && first == 10 && a[1][1] == D && a[2][0] == D);
    assert!(zero == 1 && succ == 120 && limit == 2);
    assert!(a[0][9] * 512 == 511 * D && sum10 * 512 == 4097 * D && slip == 3);
    println!("ALL CHECKS PASS");
}
