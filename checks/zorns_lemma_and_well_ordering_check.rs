// Zorn's lemma -- the same check as the Python, in Rust.  No crates.  Four arrows in 3D space; the collection is every independent set of them, ordered by "inside".
const V: [[i64; 3]; 4] = [[1, 0, 0], [1, 1, 0], [2, 1, 0], [0, 0, 1]];   // a, b, c, d
fn ix(s: &str) -> Vec<usize> { s.chars().map(|c| "abcd".find(c).unwrap()).collect() }
fn rank(s: &str) -> usize {        // elimination in whole numbers: count the rows that survive
    let (mut rows, mut r): (Vec<[i64; 3]>, usize) = (ix(s).iter().map(|&i| V[i]).collect(), 0);
    for col in 0..3 {
        let Some(p) = (r..rows.len()).find(|&i| rows[i][col] != 0) else { continue };
        rows.swap(r, p); let piv = rows[r];
        for i in r + 1..rows.len() { let c = rows[i][col]; for k in 0..3 { rows[i][k] = piv[col] * rows[i][k] - c * piv[k]; } }
        r += 1;
    } r
}
fn det(s: &str) -> i64 {           // second road for three arrows: the determinant
    let t = ix(s); let ([p, q, r], [u, v, w], [x, y, z]) = (V[t[0]], V[t[1]], V[t[2]]); p * (v * z - w * y) - q * (u * z - w * x) + r * (u * y - v * x)
}
fn climb(order: &str, stop: bool) -> String {   // Zorn's move: add the next arrow that keeps the set independent
    let mut s = String::new();
    for x in order.chars() { let t = format!("{}{}", s, x); if rank(&t) == s.len() + 1 { s = t; } else if stop { break; } }
    let mut v: Vec<char> = s.chars().collect(); v.sort(); v.into_iter().collect()
}
fn perms(s: &str) -> Vec<String> { if s.len() < 2 { return vec![s.to_string()]; } s.chars().flat_map(|x| perms(&s.replace(x, "")).into_iter().map(move |p| format!("{}{}", x, p))).collect() }
fn sub(s: &str, t: &str) -> bool { s.chars().all(|c| t.contains(c)) }
fn main() {
    let all: Vec<String> = (0..16).map(|m: u32| "abcd".chars().enumerate().filter(|(i, _)| m >> i & 1 == 1).map(|(_, c)| c).collect()).collect();
    let ind: Vec<&String> = all.iter().filter(|s| rank(s) == s.len()).collect();
    let mut max: Vec<String> = ind.iter().filter(|s| !ind.iter().any(|t| t.len() > s.len() && sub(s, t))).map(|s| s.to_string()).collect(); max.sort();
    let mut u: Vec<char> = ["a", "ab", "abd"].concat().chars().collect(); u.sort(); u.dedup(); let ceil: String = u.into_iter().collect();   // union of the chain
    let land: Vec<usize> = max.iter().map(|m| perms("abcd").iter().filter(|o| &climb(o, false) == m).count()).collect();
    let top = ind.iter().filter(|s| ind.iter().all(|t| sub(t, s))).count(); let dets: Vec<&str> = all.iter().filter(|s| s.len() == 3 && det(s) != 0).map(|s| s.as_str()).collect();
    println!("independent sets among the 16: {}; by size 0 to 4: {:?}", ind.len(), (0..5).map(|k| ind.iter().filter(|s| s.len() == k).count()).collect::<Vec<_>>());
    println!("maximal, by checking every bigger set: {}\ntriples with nonzero determinant: {}; abc gives {}", max.join(", "), dets.join(", "), det("abc"));
    println!("c - a - b = {:?}; rank of abcd: {} of 4", (V[2][0] - V[0][0] - V[1][0], V[2][1] - V[0][1] - V[1][1], V[2][2] - V[0][2] - V[1][2]), rank("abcd"));
    println!("chain a, ab, abd: ceiling {}, independent {}, maximal {}", ceil, if rank(&ceil) == 3 { "yes" } else { "no" }, if max.contains(&ceil) { "yes" } else { "no" });
    println!("climb in the order a, b, c, d: {}; stopping at the first refusal: {}", climb("abcd", false), climb("abcd", true));
    println!("24 line-ups land on: {}; sets above all others: {}", max.iter().zip(&land).map(|(m, n)| format!("{} {}", m, n)).collect::<Vec<_>>().join(", "), top);
    assert!(ind.len() == 14 && max == ["abd", "acd", "bcd"] && rank("abcd") == 3 && top == 0 && rank("bb") == 1);   // bb repeats an arrow
    assert!(max == dets && det("abc") == 0 && climb("abcd", false) == ceil && ceil == "abd");
    assert!(land == [8, 8, 8] && land.iter().sum::<usize>() == 24 && climb("abcd", true) == "ab");
    println!("ALL CHECKS PASS");
}
