// Indices on the 13-clock, no crates.  Road one: try every x.  Road two: k i = ind a (mod 12).
const P: i64 = 13; const G: i64 = 2; const N: i64 = 12;   // the clock, the base, the index clock
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a } else { gcd(b, a % b) } }
fn show(v: &[i64]) -> String { format!("[{}]", v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ")) }
fn brute(k: i64, a: i64) -> Vec<i64> { (1..P).filter(|x| x.pow(k as u32) % P == a).collect() }   // road one
fn by_index(k: i64, a: i64, ind: &[i64]) -> Vec<i64> {    // road two: solve k i = ind a (mod 12), then x = 2^i
    let (d, ia) = (gcd(k, N), ind[a as usize]); let m = N / d;
    if ia % d != 0 { return vec![]; }
    let inv = (0..m).find(|t| k / d * t % m == 1 % m).unwrap();
    (0..d).map(|t| ia / d * inv % m + m * t).collect()
}
fn main() {
    let mut power = vec![1i64];
    for _ in 0..N - 1 { let l = power[power.len() - 1]; power.push(l * G % P); }   // 2^0 .. 2^11
    let mut ind = vec![0i64; P as usize];                  // the index table: power read backwards
    for (i, v) in power.iter().enumerate() { ind[*v as usize] = i as i64; }
    println!("index table, base 2 mod 13: {}", (1..P).map(|a| format!("{}:{}", a, ind[a as usize])).collect::<Vec<_>>().join(" "));
    let (s, q) = ((ind[7] + ind[11]) % N, (ind[5] - ind[7] + N) % N);
    println!("7 x 11: indices {} + {} = {} = {} (mod 12), 2^{} = {}; direct 77 mod 13 = {}", ind[7], ind[11], ind[7] + ind[11], s, s, power[s as usize], 77 % P);
    println!("5 / 7: indices {} - {} = {} = {} (mod 12), 2^{} = {}; check 7 x {} mod 13 = {}", ind[5], ind[7], ind[5] - ind[7], q, q, power[q as usize], power[q as usize], 7 * power[q as usize] % P);
    for (k, a) in [(5i64, 7i64), (3, 5), (3, 2)] {
        let (i, d) = (by_index(k, a, &ind), gcd(k, N));
        let x: Vec<i64> = i.iter().map(|j| power[*j as usize]).collect();
        println!("x^{} = {}: {}i = {} (mod 12), gcd {}, test {}^{} = {}; i = {}, x = {}; trying all x: {}",
                 k, a, k, ind[a as usize], d, a, N / d, a.pow((N / d) as u32) % P, show(&i), show(&x), show(&brute(k, a)));
    }
    let mut agree = 0; for k in 1..P { for a in 1..P {
        let d = gcd(k, N); let mut x: Vec<i64> = by_index(k, a, &ind).iter().map(|j| power[*j as usize]).collect(); x.sort();
        if x == brute(k, a) && brute(k, a).len() as i64 == (if a.pow((N / d) as u32) % P == 1 { d } else { 0 }) { agree += 1; } } }
    println!("rule against trying every x, k and a from 1 to 12: {} of 144 cases agree", agree);
    let w = (ind[7] * (0..P).find(|t| 5 * t % P == 1).unwrap() % P) as usize;   // the index worked mod 13
    let (f, mi) = (power[by_index(3, 5, &ind)[0] as usize], (ind[7] * ind[11] % N) as usize);
    println!("mistakes: index mod 13 gives x = {}, and {}^5 = {}; first answer only: {}; multiplying indices: 2^{} = {}; base 3 reaches only {}", power[w], power[w], power[w].pow(5) % P, f, mi, power[mi],
             show(&{ let mut v: Vec<i64> = (0..N).map(|i| 3i64.pow(i as u32) % P).collect(); v.sort(); v.dedup(); v }));
    let mut b35: Vec<i64> = by_index(3, 5, &ind).iter().map(|j| power[*j as usize]).collect(); b35.sort();
    assert!(agree == 144 && by_index(5, 7, &ind) == vec![7] && power[7] == 11 && brute(5, 7) == vec![11]);
    assert!(b35 == vec![7, 8, 11] && b35 == brute(3, 5) && brute(3, 2).is_empty());
    assert!(power[s as usize] == 12 && power[s as usize] == 77 % P && 7 * power[q as usize] % P == 5 && { let mut u = power.clone(); u.sort(); u.dedup(); u.len() as i64 == N });
    println!("ALL CHECKS PASS");
}
