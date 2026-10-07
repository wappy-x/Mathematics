// The real numbers have no gaps -- the same check as the Python file, in
// Rust.  No crates.  The collection is every number whose square is under
// 2 -- the spot the dart hit on the tape.  Two roads to its least ceiling:
// decimal places, then halving a bracket.  i128 keeps every step exact.
fn dec(n: i128, places: usize) -> String {   // dec(14142, 4) -> "1.4142"
    let mut s = n.to_string();
    while s.len() < places + 1 { s.insert(0, '0'); }
    if places == 0 { s } else { let c = s.len() - places; format!("{}.{}", &s[..c], &s[c..]) }
}

fn ten(k: u32) -> i128 { 10i128.pow(k) }

fn main() {
    println!("places   below       its square    above       its square");
    for (k, low, high) in [(0u32, 1i128, 2i128), (1, 14, 15), (2, 141, 142), (3, 1414, 1415), (4, 14142, 14143)] {
        let unit = ten(k);
        assert!(low * low < 2 * unit * unit && 2 * unit * unit < high * high);   // low is inside, high is a ceiling
        println!("  {}      {:<12}{:<14}{:<12}{}", k, dec(low * ten(4 - k), 4), dec(low * low, 2 * k as usize),
                 dec(high * ten(4 - k), 4), dec(high * high, 2 * k as usize));
    }
    let (mut lo, mut hi, mut den) = (1i128, 2i128, 1i128);                       // the second road: halve the gap
    for _ in 0..40 {
        lo *= 2; hi *= 2; den *= 2;
        let mid = (lo + hi) / 2;
        if mid * mid < 2 * den * den { lo = mid; } else { hi = mid; }
    }
    println!("halving from 1 to 2, forty times: the least ceiling is caught between {} and {}",
             dec(lo * ten(8) / den, 8), dec(hi * ten(8) / den, 8));
    assert!(14142 * den <= lo * 10000 && hi * 10000 <= 14143 * den);
    println!("the two roads agree: the halving bracket sits inside 1.4142 and 1.4143");
    println!("a ceiling, but not the least: 1.415 squares to {}, and 1.4143 squares to {}",
             dec(1415 * 1415, 6), dec(14143 * 14143, 8));
    println!("not a ceiling at all: 1.4142 squares to {}, which is under 2", dec(14142 * 14142, 8));
    assert!(14142 * 14142 < 2 * 10000 * 10000 && 2 * 10000 * 10000 < 14143 * 14143 && 14143 < 1415 * 10);
    println!("ALL CHECKS PASS");
}
