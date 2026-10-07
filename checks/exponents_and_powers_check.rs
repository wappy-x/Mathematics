// Exponents -- the same check as the Python, in Rust.  No crates.  A chain
// message: 3 friends each, five rounds; then 243 by a second road, and the ratios.
fn power(base: i64, rounds: u32) -> i64 {   // 3, 5 -> 3 x 3 x 3 x 3 x 3 -> 243
    let mut result = 1i64;
    for _ in 0..rounds { result = result * base; }
    result
}

fn line(name: &str, value: &str) { println!("{:<44}{:>6}", name, value); }

fn main() {
    let new: Vec<i64> = (0..6).map(|r| power(3, r)).collect();
    let mut running: Vec<i64> = Vec::new();
    let mut total = 0i64;
    for n in &new { total += n; running.push(total); }
    let flip = new[5] / new[2];             // 9 x 27 = 243, so 9 / 243 is 1/27
    let mut head = format!("{:<22}", "round");
    for v in 0..6 { head.push_str(&format!("{:>5}", v)); }
    println!("{}", head);
    let mut fresh = format!("{:<22}", "new people this round");
    for v in &new { fresh.push_str(&format!("{:>5}", v)); }
    println!("{}", fresh);
    let mut all = format!("{:<22}", "everyone who has it");
    for v in &running { all.push_str(&format!("{:>5}", v)); }
    println!("{}", all);
    line("3 x 3 x 3 x 3 x 3 = 3^5", &new[5].to_string());
    line("3^2 x 3^3, the two halves multiplied", &(power(3, 2) * power(3, 3)).to_string());
    line("(3^2)^3 = 3^6, a power of a power", &power(power(3, 2), 3).to_string());
    line("3^5 / 3^2 = 3^3, five rounds against two", &(new[5] / new[2]).to_string());
    line("3^5 / 3^5 = 3^0, five rounds against five", &(new[5] / new[5]).to_string());
    line("3^2 / 3^5 = 3^-3, two rounds against five", &format!("1/{}", flip));
    println!("the three mistakes come out at {}, {} and {}", power(3, 6), 3 * 5, -power(3, 3));

    assert!(new[5] == 243 && power(3, 2) * power(3, 3) == new[5]);
    assert!(running[5] == 1 + 3 + 9 + 27 + 81 + 243 && new[0] == 1);
    assert!(new[2] == 9 && flip == 27 && new[2] * flip == new[5] && new[5] / new[5] == 1);
    assert!(power(power(3, 2), 3) == power(3, 6) && power(3, 6) == 729);
    println!("ALL CHECKS PASS");
}
