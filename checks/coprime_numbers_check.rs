// Coprime numbers -- the same check as coprime_numbers_check.py, in Rust.  No
// crates.  Two meshing gears, 15 teeth and 28 teeth, then 15 and 27 for
// contrast.  Euclid finds the shared factor; a whole-number mix is the second road.
fn gcd(mut a: i64, mut b: i64) -> i64 {      // Euclid: keep the remainder, repeat
    while b != 0 { let r = a % b; a = b; b = r; }
    a
}
fn meets(small: i64, big: i64) -> Vec<i64> { // slots of the big gear that tooth 0 meets
    let (mut seen, mut step) = (vec![0], small);
    while step % big != 0 {
        seen.push(step % big);
        step += small;
    }
    seen
}
fn row(name: &str, value: &str) { println!("{:<42}{:>7}", name, value); }
fn main() {
    for (small, big) in [(15i64, 28i64), (15, 27)] {
        let g = gcd(small, big);
        let met = meets(small, big);
        row(&format!("gcd of {} and {}, by Euclid", small, big), &g.to_string());
        row(&format!("slots of the {}-gear that tooth 0 meets", big), &met.len().to_string());
        row(&format!("tooth pairs used, of the {} there are", small * big),
            &(small * met.len() as i64).to_string());
        row(&format!("{}/{} in lowest terms", small, big),
            &format!("{}/{}", small / g, big / g));
    }
    row("the mix 28 x 7 - 15 x 13", &(28 * 7 - 15 * 13).to_string());
    row("the mix 27 x 4 - 15 x 7, the smallest", &(27 * 4 - 15 * 7).to_string());
    let list: Vec<String> = meets(15, 27).iter().map(|t| t.to_string()).collect();
    println!("slots of the 27-gear tooth 0 meets: {}", list.join(" "));
    assert!(gcd(15, 28) == 1 && 28 * 7 - 15 * 13 == 1 && meets(15, 28)[..4] == [0, 15, 2, 17]);
    assert!(meets(15, 28).len() == 28 && 15 * meets(15, 28).len() == 15 * 28);
    assert!(gcd(15, 27) == 3 && meets(15, 27).len() == 27 / 3 && 15 * meets(15, 27).len() == 135);
    println!("ALL CHECKS PASS");
}
