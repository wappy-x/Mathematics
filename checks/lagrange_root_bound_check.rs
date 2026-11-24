// Lagrange's root bound -- the same check as the Python, in Rust.  No crates.  A
// polynomial is its list of coefficients, constant first; a root on the n-clock
// is a number from 0 to n - 1 where the polynomial reads 0 once clocks come off.
fn roots(f: &[i64], n: i64) -> Vec<i64> {
    (0..n).filter(|&x| f.iter().rev().fold(0, |acc, &c| acc * x + c).rem_euclid(n) == 0).collect()
}
fn peel(f: &[i64], r: i64, n: i64) -> (Vec<i64>, i64) {  // divide by (x - r) on the n-clock
    let (mut q, mut carry) = (vec![0; f.len() - 1], 0);
    for k in (1..f.len()).rev() { carry = (carry * r + f[k]).rem_euclid(n); q[k - 1] = carry; }
    (q, (carry * r + f[0]).rem_euclid(n))                // the quotient, and the remainder
}
fn j(v: &[i64]) -> String { v.iter().map(|c| c.to_string()).collect::<Vec<_>>().join(" ") }
fn main() {
    let (sq, top) = (vec![-1i64, 0, 1], vec![-1i64, 0, 0, 0, 0, 0, 1]);  // x^2 - 1 and x^6 - 1
    println!("x^2 = 1 on the 7-clock, roots: {} | 6 x 6 = {} reads {}", j(&roots(&sq, 7)), 6 * 6, 6 * 6 % 7);
    println!("x^2 = 1 on the 8-clock, roots: {} | 3 x 3 = 9 reads {}, (3 - 1) x (3 + 1) = 8 reads {}", j(&roots(&sq, 8)), 3 * 3 % 8, (3 - 1) * (3 + 1) % 8);
    let counts: Vec<i64> = (3..17).map(|n| roots(&sq, n).len() as i64).collect();
    println!("roots of x^2 = 1 on clocks 3 to 16: {}", j(&counts));
    let mut quads = vec![];
    for a in 1..7 { for b in 0..7 { for c in 0..7 { quads.push(vec![c, b, a]); } } }
    let most = quads.iter().map(|f| roots(f, 7).len()).max().unwrap();  // brute force
    println!("quadratics on the 7-clock: {}, most roots any one has: {}", quads.len(), most);
    let mut full = vec![1i64];                           // (x - 1)(x - 2)...(x - 6), in full
    for r in 1..7 { let mut g = vec![0; full.len() + 1];
        for (i, &a) in full.iter().enumerate() { g[i + 1] += a; g[i] -= r * a; } full = g; }
    println!("x^6 - 1 on the 7-clock, roots: {}", j(&roots(&top, 7)));
    let red: Vec<i64> = full.iter().map(|c| c.rem_euclid(7)).collect();
    println!("(x - 1)...(x - 6), constant first: {} | on the 7-clock: {}", j(&full), j(&red));
    let (mut left, mut rems) = (top.clone(), vec![]);
    for r in 1..7 { let (q, rem) = peel(&left, r, 7); left = q; rems.push(rem); }
    println!("peel x - 1 to x - 6 off x^6 - 1, remainders: {} | left over: {}", j(&rems), j(&left));
    let fact: i64 = 1 * 2 * 3 * 4 * 5 * 6;               // 6!, the long way
    println!("6! = {} = {} x 7 - 1, reads {}, which is -1", fact, (fact + 1) / 7, fact % 7);
    println!("traps: 7x^2 - 7 has {} roots, -720 reads {}, x^2 + 1 has {}", roots(&[-7, 0, 7], 7).len(), (-fact).rem_euclid(7), roots(&[1, 0, 1], 7).len());
    assert!(roots(&sq, 7) == vec![1, 6] && roots(&sq, 8) == vec![1, 3, 5, 7] && quads.len() == 294 && most == 2);
    assert!(red == top.iter().map(|c| c.rem_euclid(7)).collect::<Vec<_>>() && rems == vec![0; 6] && left == vec![1]);
    let prime = |n: i64| (2..n).all(|d| n % d != 0);
    assert!(full[0] == fact && full[0] == 103 * 7 - 1 && full.iter().sum::<i64>() == 0 && (3..17).zip(&counts).all(|(n, &c)| !prime(n) || c == 2));
    println!("ALL CHECKS PASS");
}
