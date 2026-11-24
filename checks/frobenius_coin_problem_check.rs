// The coin problem -- the same check as the Python, in Rust.  No crates.  Stamps of 5 and 7
// cents, then boxes of 6, 9 and 20.  Roads: search, the remainder ladder, the formula, pairing.
fn payable(sizes: &[usize], top: usize) -> Vec<bool> {     // road one: build every amount upward
    let mut ok = vec![false; top + 1]; ok[0] = true;
    for n in 1..=top { ok[n] = sizes.iter().any(|&s| n >= s && ok[n - s]); }
    ok
}
fn ladder(sizes: &[usize]) -> Vec<usize> {                 // road two: cheapest amount in each row, from the other sizes only
    let (a, ok) = (sizes[0], payable(&sizes[1..], sizes[0] * sizes.iter().max().unwrap() * 3));
    (0..a).map(|r| (0..ok.len()).filter(|&n| ok[n] && n % a == r).min().unwrap()).collect()
}
fn mix(p: i64, q: i64, w: i64) -> Vec<i64> {              // amounts 0 to 50 that counts -10 to 10 reach
    (0..51).filter(|&n| (-10..11).any(|x| (-10..11).any(|y| (-10..11).any(|z| p * x + q * y + w * z == n)))).collect()
}
fn join<T: ToString>(v: &[T], sep: &str) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(sep) }
fn main() {
    let (a, b, boxes) = (5usize, 7usize, [6usize, 9, 20]);
    let (ok, rows, f) = (payable(&[a, b], 100), ladder(&[a, b]), a * b - a - b); // road three: formula
    let gaps: Vec<usize> = (0..=100).filter(|&n| !ok[n]).collect();
    let (pairs, top) = ((0..=f).filter(|&n| ok[n] != ok[f - n]).count() / 2, *rows.iter().max().unwrap()); // road four
    let door = |ok: &[bool], a: usize, rows: &[usize]| rows.iter().enumerate().all(|(r, &d)| d % a == r && ok[d] && (d < a || !ok[d - a]));
    println!("{} and {} cannot pay: {}", a, b, join(&gaps, " "));
    println!("first payable in rows 0..{}: {:?}; gaps per row {:?}; largest gap {} - {} = {}", a - 1, rows, rows.iter().map(|r| r / a).collect::<Vec<_>>(), top, a, top - a);
    println!("formula {} x {} - {} - {} = {}; gaps {}, ({}-1)({}-1)/2 = {}, pairs split {} of {}", a, b, a, b, f, gaps.len(), a, b, (a - 1) * (b - 1) / 2, pairs, (f + 1) / 2);
    println!("{}", (f + 1..=f + a).map(|n| { let y = (0..a).find(|&y| (n - b * y) % a == 0).unwrap(); format!("{} = {} x {} + {} x {}", n, (n - b * y) / a, a, y, b) }).collect::<Vec<_>>().join("; "));
    let (bx, brows, c) = (payable(&boxes, 200), ladder(&boxes), boxes[0]);
    let (bgaps, btop): (Vec<usize>, usize) = ((0..=200).filter(|&n| !bx[n]).collect(), *brows.iter().max().unwrap());
    println!("boxes {}: largest gap {}, rows {:?}, {} - {} = {}; gaps {}", join(&boxes, ", "), bgaps[bgaps.len() - 1], brows, btop, c, btop - c, bgaps.len());
    let ((u, v), (s, t), m20, m15) = ((-1i64, 1i64), (7i64, -1i64), mix(6, 9, 20), mix(6, 9, 15)); // Bezout twice: 6u + 9v = 3, 3s + 20t = 1
    println!("negatives allowed: 3 x {} - 2 x {} = {}; 6 x {} + 9 x {} = {}, {} x {} + 20 x {} = {}, so 6 x {} + 9 x {} + 20 x {} = {}", a, b, 3 * a as i64 - 2 * b as i64,
             u, v, 6 * u + 9 * v, 6 * u + 9 * v, s, t, (6 * u + 9 * v) * s + 20 * t, u * s, v * s, t, 6 * u * s + 9 * v * s + 20 * t);
    println!("counts -10 to 10, amounts 0 to 50: 6, 9, 20 reach {} of 51; 6, 9, 15 reach only {}", m20.len(), join(&m15, " "));
    println!("the three mistakes come out at {}, {} and {}", a * b, top, (a - 1) * (b - 1));
    assert!(gaps[gaps.len() - 1] == f && f == top - a && f == 23 && gaps.len() == (a - 1) * (b - 1) / 2 && gaps.len() == pairs && pairs == rows.iter().map(|r| r / a).sum::<usize>() && pairs == 12);
    assert!(rows == vec![0, 21, 7, 28, 14] && door(&ok, a, &rows) && ok[24..].iter().all(|&v| v) && ok[a * b] && ok[top]);
    assert!(bgaps[bgaps.len() - 1] == btop - c && btop - c == 43 && bgaps.len() == brows.iter().map(|r| r / c).sum::<usize>() && bgaps.len() == 22 && door(&bx, c, &brows));
    assert!(6 * u * s + 9 * v * s + 20 * t == 1 && m20.len() == 51 && m15 == (0..51).step_by(3).collect::<Vec<i64>>());
    println!("ALL CHECKS PASS");
}
