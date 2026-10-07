// The Catalan generating function -- the same check as the Python, in Rust.  No crates.  Six sorted
// stacks of envelopes stand in a row; each step merges two neighbouring stacks, so five merges finish
// the row, and a plan is the nesting of those merges.  The plans are counted three ways: by iterating
// C <- 1 + x C^2 on truncated series, by simulating every merge order and keeping the distinct
// nestings, and by the closed count C(2n, n)/(n + 1).  The closed form is then checked at x = 0.1.
const DEG: usize = 5; const DEEP: usize = 10; const X: f64 = 0.1;
fn mul(a: &[i64], b: &[i64], deg: usize) -> Vec<i64> {   // series product, powers above x^deg dropped
    let mut out = vec![0i64; deg + 1];
    for (i, ai) in a.iter().enumerate() { for (j, bj) in b.iter().take((deg + 1).saturating_sub(i)).enumerate() { out[i + j] += ai * bj } }
    out
}
fn rnd(c: &[i64], deg: usize, lead: i64) -> Vec<i64> {   // one round of C <- lead + x C^2
    let mut out = vec![lead]; out.extend_from_slice(&mul(c, c, deg)[..deg]); out
}
fn plans(k: usize) -> Vec<String> {                      // every merge order of k stacks, on strings
    let mut rows: Vec<Vec<String>> = vec![(0..k).map(|i| ((b'A' + i as u8) as char).to_string()).collect()];
    for _ in 1..k {
        let mut next: Vec<Vec<String>> = Vec::new();
        for r in &rows { for i in 0..r.len() - 1 {
            let mut s = r.clone();
            s[i] = format!("({}{})", r[i], r[i + 1]); s.remove(i + 1); next.push(s);
        } }
        rows = next;
    }
    rows.iter().map(|r| r[0].clone()).collect()
}
fn nestings(k: usize) -> Vec<String> { let mut v = plans(k); v.sort(); v.dedup(); v }
fn choose(n: i64, k: i64) -> i64 {                       // C(n, k), from the product formula
    let mut out = 1i64; for i in 0..k { out = out * (n - i) / (i + 1) } out
}
fn cat(upto: i64) -> Vec<i64> { (0..=upto).map(|n| choose(2 * n, n) / (n + 1)).collect() }
fn heron(v: f64) -> f64 {                                // square root, by Heron's own method
    let mut g = 1.0; for _ in 0..60 { g = (g + v / g) / 2.0 } g
}
fn row(label: &str, values: &[i64]) {
    let mut line = format!("{:<46}", label); for v in values { line.push_str(&format!("{:>4}", v)) } println!("{}", line);
}
fn one(deg: usize) -> Vec<i64> { let mut c = vec![0i64; deg + 1]; c[0] = 1; c }   // the series C = 1
fn joined(values: &[i64]) -> String { values.iter().map(|v| v.to_string()).collect::<Vec<String>>().join(" ") }
fn main() {
    let mut rounds: Vec<Vec<i64>> = vec![one(DEG)];               // road one: iterate it
    for _ in 0..=DEG { rounds.push(rnd(&rounds[rounds.len() - 1], DEG, 1)) }
    let listed: Vec<i64> = (1..=DEG + 1).map(|k| nestings(k).len() as i64).collect();   // road two
    let (closed, deep) = (cat(DEG as i64), cat(DEEP as i64));                           // road three
    let resid: Vec<i64> = rnd(&deep, DEEP, 1).iter().zip(deep.iter()).map(|(a, b)| a - b).collect();
    let die = [0i64, 1, 1, 1, 1, 1, 1];                  // the shelf's two dice, as a check
    let dice = mul(&die, &die, 12);
    let root = heron(1.0 - 4.0 * X);
    let (minus, plus) = ((1.0 - root) / (2.0 * X), (1.0 + root) / (2.0 * X));
    let back = 1.0 + X * minus * minus;
    let (mut total, mut p) = (0.0, 1.0);
    for c in cat(30) { total += c as f64 * p; p *= X }
    let mut dropped = one(DEG);
    for _ in 0..=DEG { dropped = rnd(&dropped, DEG, 0) }
    let mut term = vec![1i64];
    term.extend(rounds[DEG].iter().take(DEG).map(|c| c * c));
    println!("six sorted stacks in a row, five merges to finish: plans for 1 to {} stacks", DEG + 1);
    for k in 1..=DEG + 1 { row(&format!("round {} of C <- 1 + x C^2", k), &rounds[k]) }
    row("distinct nestings, by listing merge orders", &listed);
    row("the closed count C(2n,n)/(n+1)", &closed);
    println!("the 5 plans for 4 stacks: {}", nestings(4).join(" "));
    println!("1 + x C^2 - C on the closed counts, x^0 to x^{}: {}", DEEP, joined(&resid));
    println!("the shelf's two dice, the square of x + ... + x^6: {} at x^7, {} in all", dice[7], dice.iter().sum::<i64>());
    println!("closed form at x = {}: 1 - 4x = {:.1}, its square root {:.12}, (1 - {:.12})/{:.1} = {:.12}", X, 1.0 - 4.0 * X, root, root, 2.0 * X, minus);
    println!("that number back through 1 + x C^2: {:.12}; the counts summed at x = {}, n = 0 to 30: {:.12}", back, X, total);
    println!("mistake 1, the plus root: (1 + {:.12})/{:.1} = {:.12}", root, 2.0 * X, plus);
    row("mistake 2, dropping the leading 1", &dropped);
    row("mistake 3, squaring coefficient by coefficient", &term);
    println!("mistake 4, merge orders counted as plans, {} stacks: {}, not {}", DEG + 1, plans(DEG + 1).len(), listed[DEG]);
    assert!(rounds[DEG] == listed && listed == closed && rounds[DEG] == rounds[DEG + 1]);  // three roads
    assert!(resid == vec![0i64; DEEP + 1] && deep[DEG] == 42);          // the counts solve the equation
    assert!((back - minus).abs() < 1e-12 && (total - minus).abs() < 1e-12);   // the closed form, as a number
    assert!(dice[7] == 6 && dice.iter().sum::<i64>() == 36 && plans(DEG + 1).len() as i64 > listed[DEG]);
    println!("ALL CHECKS PASS");
}
