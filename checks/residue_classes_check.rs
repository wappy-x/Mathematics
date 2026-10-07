// Residue classes -- the same check as the Python, in Rust.  No crates.  The 12
// pitch classes: up a fifth twice, 7 + 7 = 14, which lands in bucket 2.  Then the
// mod 5 and mod 6 tables, built from the buckets and again from far-off members.
fn bucket(x: i64, n: i64) -> i64 { x.rem_euclid(n) }   // which of the n buckets x falls in
fn table(n: i64, jump: i64, times: bool) -> Vec<Vec<i64>> {   // jump 0 uses 0 to n-1
    (0..n).map(|a| (0..n).map(|b| { let (p, q) = (a + jump * n, b - 2 * jump * n);
        bucket(if times { p * q } else { p + q }, n) }).collect()).collect()
}
fn walk(step: i64, n: i64) -> Vec<i64> {               // step round until back at bucket 0
    let mut seen = vec![0i64];
    loop { let next = bucket(seen[seen.len() - 1] + step, n); if next == 0 { return seen; } seen.push(next); }
}
fn join(v: &[i64]) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(" ") }
fn row(name: &str, rows: &[Vec<i64>]) {
    println!("{:<22}{}", name, rows.iter().map(|r| join(r)).collect::<Vec<_>>().join(" | "));
}
fn zero_pairs(n: i64) -> Vec<(i64, i64)> {
    (1..n).flat_map(|a| (1..n).map(move |b| (a, b))).filter(|(a, b)| bucket(a * b, n) == 0).collect()
}
fn main() {
    println!("{:<38}{:>4}", "pitch classes in an octave", 12);
    println!("{:<38}{:>4}", "up two fifths, 7 + 7 = 14, bucket", bucket(14, 12));
    println!("{:<38}{:>4}", "an octave up, 19 + 19 = 38, bucket", bucket(38, 12));
    println!("bucket 2 holds ... {} ...", join(&(-2..3).map(|k| 2 + 12 * k).collect::<Vec<_>>()));
    let (w7, w8) = (walk(7, 12), walk(8, 12));
    println!("fifths walk by 7: {}, back to 0 after {} buckets", join(&w7), w7.len());
    println!("walk by 8 instead: {}, back to 0 after {} buckets", join(&w8), w8.len());
    row("mod 5 add rows 0-4:", &table(5, 0, false));
    row("mod 5 times rows 0-4:", &table(5, 0, true));
    row("mod 6 times rows 0-5:", &table(6, 0, true));
    let z6 = zero_pairs(6);
    println!("non-zero pairs multiplying to 0: mod 5: {}, mod 6: {}: {}", zero_pairs(5).len(), z6.len(),
             z6.iter().map(|(a, b)| format!("{} x {}", a, b)).collect::<Vec<_>>().join(", "));
    assert!(bucket(14, 12) == 2 && bucket(38, 12) == 2 && bucket(-22, 12) == 2 && w7 == vec![0, 7, 2, 9, 4, 11, 6, 1, 8, 3, 10, 5] && w8 == vec![0, 8, 4]);
    assert!(table(5, 0, true) == vec![vec![0, 0, 0, 0, 0], vec![0, 1, 2, 3, 4], vec![0, 2, 4, 1, 3], vec![0, 3, 1, 4, 2], vec![0, 4, 3, 2, 1]] && zero_pairs(5).is_empty());
    assert!(z6 == vec![(2, 3), (3, 2), (3, 4), (4, 3)] && table(5, 0, true) == table(5, 3, true) && table(6, 0, true) == table(6, 3, true) && table(5, 0, false) == table(5, 3, false) && table(5, 0, false) == vec![vec![0, 1, 2, 3, 4], vec![1, 2, 3, 4, 0], vec![2, 3, 4, 0, 1], vec![3, 4, 0, 1, 2], vec![4, 0, 1, 2, 3]]);
    println!("ALL CHECKS PASS");
}
