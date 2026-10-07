// Subgroups and cyclic groups -- the same check as the Python, in Rust.  No
// crates.  The group is the twelve musical pitch classes 0 to 11, added and
// wrapped at 12.  Orders come out twice: by walking, and from 12 / gcd.
const N: i32 = 12;

fn walk(step: i32, n: i32) -> Vec<i32> {        // road one: repeat the jump
    let (mut out, mut x) = (Vec::new(), 0);
    while !out.contains(&x) {
        out.push(x);
        x = (x + step).rem_euclid(n);
    }
    out
}

fn gcd(mut a: i32, mut b: i32) -> i32 {         // Euclid, used only by road two
    while b != 0 { let t = a % b; a = b; b = t; }
    a
}

fn is_subgroup(h: &[i32], n: i32) -> bool {     // brute force: a - b stays inside
    !h.is_empty() && h.iter().all(|a| h.iter().all(|b| h.contains(&(a - b).rem_euclid(n))))
}

fn show(xs: &[i32]) -> String {
    xs.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(" ")
}

fn row(name: &str, values: &[i32]) {
    let mut line = format!("{:<16}", name);
    for v in values { line.push_str(&format!("{:>4}", v)); }
    println!("{}", line);
}

fn main() {
    let jumps: Vec<i32> = (0..N).collect();
    let walked: Vec<i32> = jumps.iter().map(|&a| walk(a, N).len() as i32).collect();
    let formula: Vec<i32> = jumps.iter().map(|&a| N / gcd(a, N)).collect();   // road two
    row("jump a", &jumps);
    row("order, walked", &walked);
    row("order, 12/gcd", &formula);
    for a in [4, 5, 3] {
        let notes = walk(a, N);
        println!("jump {} reaches: {}; order {}; subgroup: {}",
                 a, show(&notes), notes.len(), is_subgroup(&notes, N));
    }
    let gens: Vec<i32> = (0..N).filter(|&a| walk(a, N).len() as i32 == N).collect();
    let coprime: Vec<i32> = (0..N).filter(|&a| gcd(a, N) == 1).collect();
    println!("jumps reaching all 12 notes: {}; count {}; jumps coprime to 12: {}",
             show(&gens), gens.len(), show(&coprime));
    let mut subs: Vec<Vec<i32>> = Vec::new();
    for &a in &jumps {
        let mut s = walk(a, N);
        s.sort();
        if !subs.contains(&s) { subs.push(s); }
    }
    subs.sort_by_key(|s| s.len());
    let sizes: Vec<i32> = subs.iter().map(|s| s.len() as i32).collect();
    let divisors: Vec<i32> = (1..=N).filter(|d| N % d == 0).collect();
    println!("cyclic subgroups, by size: {}; count {}; divisors of 12: {}",
             show(&sizes), subs.len(), show(&divisors));
    let (quarter, half) = (walk(1, 4), walk(2, 4));
    println!("tile: quarter turns {}, order {}; half turns {}, order {}",
             show(&quarter), quarter.len(), show(&half), half.len());
    let undo = (-4_i32).rem_euclid(N);
    println!("undo of jump 4 is {}, inside the triad: {}", undo, walk(4, N).contains(&undo));
    let shifted: Vec<i32> = walk(4, N).iter().map(|x| (1 + x) % N).collect();
    println!("the pair 0 and 4: subgroup {}, because 4 + 4 gives {}",
             is_subgroup(&[0, 4], N), (4 + 4) % N);
    println!("the shifted loop {}: subgroup {}, holds a 0: {}",
             show(&shifted), is_subgroup(&shifted, N), shifted.contains(&0));
    println!("multiplying instead of adding: 4^3 wraps to {}, while three jumps of 4 give {}",
             4_i32.pow(3) % N, 3 * 4 % N);
    assert!(walked == formula && walked[4] == 3 && walked[5] == N);
    assert!(walk(5, N) == vec![0, 5, 10, 3, 8, 1, 6, 11, 4, 9, 2, 7] && walk(4, N) == vec![0, 4, 8]);
    assert!(gens == coprime && gens == vec![1, 5, 7, 11] && sizes == divisors);
    assert!(is_subgroup(&[0, 4, 8], N) && !is_subgroup(&[0, 4], N)
            && !is_subgroup(&shifted, N) && !is_subgroup(&[], N));
    println!("ALL CHECKS PASS");
}
