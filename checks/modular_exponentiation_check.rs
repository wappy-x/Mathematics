// Powers on the clock -- the same check as modular_exponentiation_check.py, in Rust.  No
// crates.  A toy random-number generator multiplies its output by 7 at each step and keeps
// only the last three digits.
fn by_squaring(mut steps: i64, spare: bool) -> (i64, i64, Vec<i64>, Vec<i64>) {
    let mut rungs: Vec<i64> = Vec::new();          // halve the steps down, then square back up
    while steps > 0 { rungs.push(steps); steps /= 2; }
    rungs.reverse();
    let (mut reading, mut mults, mut trace) = (7i64, 0i64, vec![7i64]);
    for rung in &rungs[1..] {
        reading = reading * reading % 1000; mults += 1;        // square: doubles the steps
        if spare && rung % 2 == 1 { reading = reading * 7 % 1000; mults += 1; }  // spare step
        trace.push(reading);
    }
    (reading, mults, rungs, trace)
}
fn slow(steps: i64) -> i64 {            // the generator's own way, one multiplication a step
    let mut reading = 1i64;
    for _ in 0..steps { reading = reading * 7 % 1000; }
    reading
}
fn line(name: &str, values: &[i64]) {
    let mut out = format!("{:<33}", name);
    for v in values { out.push_str(&format!("{:>7}", v)); }
    println!("{}", out);
}
fn main() {
    const STEPS: i64 = 123; let (fast, mults, rungs, readings) = by_squaring(STEPS, true);
    line(&format!("the steps, from 1 up to {}", STEPS), &rungs);
    line("what the generator gives on them", &readings);
    line(&format!("step {} by squaring, mod 1000", STEPS), &[fast]);
    line(&format!("step {} the slow way, mod 1000", STEPS), &[slow(STEPS)]);
    line("multiplications, fast then slow", &[mults, STEPS]);
    line("step 7 with nothing thrown away", &[7 * 7 * 7 * 7 * 7 * 7 * 7]);
    line("biggest number written down", &[943 * 943]);
    line("skipping the spare 7s", &[by_squaring(STEPS, false).0]);
    assert!(fast == 343 && slow(STEPS) == 343 && fast == slow(STEPS));
    assert!(rungs == vec![1, 3, 7, 15, 30, 61, 123] && readings == vec![7, 343, 543, 943, 249, 7, 343]);
    assert!(mults == 11 && 7i64.pow(7) % 1000 == readings[2] && by_squaring(123, false).0 == 401);
    println!("ALL CHECKS PASS");
}
