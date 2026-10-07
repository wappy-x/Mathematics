// Cantor's diagonal -- the same check as the Python twin, in Rust.  No crates.
// Five hotel guests hold five reals between 0 and 1.  Read down the diagonal, write
// a 4 in every place (a 5 where the digit read is a 4), and the number is nobody's.
const GUESTS: [(i64, i64); 5] = [(1, 7), (1, 2), (1, 3), (5, 9), (1, 8)];
const PLACES: usize = 5;
fn digits(p: i64, q: i64) -> String {   // long division, greedy: 1/2 -> "500000", not "499999"
    let (mut out, mut left) = (String::new(), p);
    for _ in 0..(PLACES + 1) { out.push_str(&(left * 10 / q).to_string()); left = left * 10 % q; }
    out
}
fn bump(d: u8) -> char {                   // add 1 to a digit, 9 goes round to 0
    char::from(b'0' + (d - b'0' + 1) % 10)
}
fn bump_all(s: &str) -> String { s.bytes().map(bump).collect() }
fn main() {
    let rows: Vec<String> = GUESTS.iter().map(|&(p, q)| digits(p, q)).collect();
    let diagonal: String = (0..PLACES).map(|i| rows[i].as_bytes()[i] as char).collect();
    let safer: String = diagonal.chars().map(|c| if c == '4' { '5' } else { '4' }).collect();
    let built = bump_all(&diagonal);
    for i in 0..PLACES {
        println!("guest {}  {}/{}  0.{}   diagonal digit {}", i + 1, GUESTS[i].0,
                 GUESTS[i].1, rows[i], rows[i].as_bytes()[i] as char);
    }
    println!("the diagonal reads {}, the 4-or-5 rule builds 0.{}", diagonal, safer);
    println!("the popular add-1 rule builds 0.{}", built);
    let heads: Vec<i64> = rows.iter().map(|r| r[..PLACES].parse::<i64>().unwrap()).collect();
    let whole: i64 = built.parse::<i64>().unwrap();
    let listed: Vec<String> = heads.iter().map(|h| h.to_string()).collect();
    println!("as whole numbers {} is none of {}", whole, listed.join(" "));
    let across = bump_all(&rows[0][..PLACES]);          // bumped row 1, not the diagonal
    let trap = bump_all("49999");                       // a list of 0.4999... rows
    println!("the three mistakes come out at 0.{}, 0.{} and 0.{}", diagonal, across, trap);
    let check: String = GUESTS.iter().enumerate()
        .map(|(i, &(p, q))| ((p * 10_i64.pow(i as u32 + 1) / q) % 10).to_string()).collect();
    assert!(diagonal == check);
    assert!(safer == "44444" && (0..PLACES).all(|i| safer.as_bytes()[i] != rows[i].as_bytes()[i]));
    assert!(whole == 21461 && (0..PLACES).all(|i| built.as_bytes()[i] != rows[i].as_bytes()[i]));
    println!("ALL CHECKS PASS");
}
