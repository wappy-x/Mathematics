// Direct sums and quotient spaces -- the same check as the Python, in Rust.  No crates.
// A basket is (loaves, milks, dozens of eggs); the price list ($3, $2, $4) reads its bill.
use std::collections::BTreeSet;
type B = (i64, i64, i64);
fn bill(x: B) -> i64 { 3 * x.0 + 2 * x.1 + 4 * x.2 }
fn sub(x: B, y: B) -> B { (x.0 - y.0, x.1 - y.1, x.2 - y.2) }
fn det(c1: B, c2: B, c3: B) -> i64 {     // 3 x 3 determinant of the columns c1, c2, c3
    let ((a, d, g), (b, e, h), (c, f, i)) = (c1, c2, c3);
    a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g)
}
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn dim7(mut n: usize) -> usize {         // n = 7^k members on the 7-hour clock means k dimensions
    let mut k = 0;
    while n > 1 { n /= 7; k += 1 }
    k
}
fn add(v: B, w: B) -> B { ((v.0 + w.0) % 7, (v.1 + w.1) % 7, (v.2 + w.2) % 7) }

fn main() {
    let (x, y, u1, u2, milk, e1): (B, B, B, B, B, B) =
        ((2, 3, 1), (4, 0, 1), (2, -3, 0), (0, 2, -1), (0, 1, 0), (1, 0, 0));
    println!("bills: {:?} -> ${}, {:?} -> ${}; difference {:?} -> ${}", x, bill(x), y, bill(y), sub(y, x), bill(sub(y, x)));
    let minor = u1.0 * u2.1 - u1.1 * u2.0;
    println!("$0 plane U: {:?} -> ${}, {:?} -> ${}; 2 x 2 minor {}, so dim U = 2", u1, bill(u1), u2, bill(u2), minor);
    let d = det(u1, u2, milk);           // road one to the split: Cramer's rule
    let (a, b, m) = (det(x, u2, milk) / d, det(u1, x, milk) / d, det(u1, u2, x) / d);
    let zero_part = (a * u1.0 + b * u2.0, a * u1.1 + b * u2.1, a * u1.2 + b * u2.2);
    println!("U + milk line: det {}, not 0, so direct; {:?} = {} x {:?} + {} x {:?} + {} milks", d, x, a, u1, b, u2, m);
    let by_bill = sub(x, (0, bill(x) / 2, 0)); // road two: 8 milks carry the $16, the rest is $0
    println!("split: $0 part {:?} + milk part (0, {}, 0); by bill / 2: {:?} + (0, {}, 0)", zero_part, m, by_bill, bill(x) / 2);
    let r = [(u1, u2, e1), (u1, u2, milk), (u1, e1, milk), (u2, e1, milk)].iter()
        .map(|&(p, q, s)| det(p, q, s).abs()).max().unwrap();
    println!("U + no-eggs plane: largest 3 x 3 minor {}, so U + E fills 3; overlap 2 + 2 - 3 = 1", r);
    println!("basket {:?} splits two ways: {:?} + (0, 0, 0) and (0, 0, 0) + {:?}", u1, u1, u1);
    let v7: Vec<B> = (0..7).flat_map(|a| (0..7).flat_map(move |b| (0..7).map(move |c| (a, b, c)))).collect();
    let u7: Vec<B> = v7.iter().cloned().filter(|&v| bill(v) % 7 == 0).collect();
    let e7: BTreeSet<B> = v7.iter().cloned().filter(|v| v.2 == 0).collect();
    let w7: Vec<B> = (0..7).map(|b| (0, b, 0)).collect();
    let cosets: BTreeSet<BTreeSet<B>> = v7.iter().map(|&v| u7.iter().map(|&u| add(v, u)).collect()).collect();
    let uw: BTreeSet<B> = u7.iter().flat_map(|&u| w7.iter().map(move |&w| add(u, w))).collect();
    let ue: BTreeSet<B> = u7.iter().flat_map(|&u| e7.iter().map(move |&e| add(u, e))).collect();
    let cap_w = u7.iter().filter(|v| w7.contains(v)).count();
    let cap_e = u7.iter().filter(|v| e7.contains(v)).count();
    println!("mod 7: {} baskets, U has {}, cosets {} = {} / {}; dim V/U = {} = 3 - {}",
             v7.len(), u7.len(), cosets.len(), v7.len(), u7.len(), dim7(cosets.len()), dim7(u7.len()));
    println!("mod 7: U + W has {}, U and W share {}; U + E has {}, U and E share {}", uw.len(), cap_w, ue.len(), cap_e);
    let bx: Vec<B> = (0..5).flat_map(|a| (0..5).flat_map(move |b| (0..5).map(move |c| (a, b, c)))).collect();
    let classes: BTreeSet<BTreeSet<B>> = bx.iter()
        .map(|&w| bx.iter().cloned().filter(|&v| det(u1, u2, sub(w, v)) == 0).collect()).collect();
    let bills: BTreeSet<i64> = bx.iter().map(|&v| bill(v)).collect();
    let one_bill = classes.iter().all(|c| c.iter().map(|&v| bill(v)).collect::<BTreeSet<i64>>().len() == 1);
    let c16 = classes.iter().find(|c| c.contains(&x)).unwrap();
    println!("box 0-4 each: {} baskets, {} classes by the U test, {} bills; one bill per class: {}",
             bx.len(), classes.len(), bills.len(), yn(one_bill));
    println!("the $16 class holds {} box baskets, {:?} among them: {}", c16.len(), y, yn(c16.contains(&y)));
    let s = (x.0 + y.0, x.1 + y.1, x.2 + y.2);
    println!("cosets add: $16 class + $16 class holds {:?} -> ${}; 3 x {:?} -> ${}", s, bill(s), x, bill((3 * x.0, 3 * x.1, 3 * x.2)));
    println!("mistake 1, dimensions added: 2 + 2 = 4, but U + E is {}-dimensional", dim7(ue.len()));
    println!("mistake 2, V/U read as division: 3 / 2 = {}, but dim V/U = {}", 3.0 / 2.0, dim7(cosets.len()));
    println!("mistake 3, baskets counted: {}, but the box meets only {} cosets", bx.len(), classes.len());
    println!("mistake 4, a 'complement' inside U: det {}, so no split of a ${} basket", det(u1, u2, u1), bill(x));
    assert!(d != 0 && minor != 0 && det(u2, u1, milk) == -d && bill(zero_part) == 0 && zero_part == by_bill && m == bill(x) / 2);
    assert!(cosets.len() == v7.len() / u7.len() && cosets.len() == 7 && dim7(u7.len()) == 2 && cap_e == 7);
    assert!(uw.len() == 343 && cap_w == 1 && ue.len() == 343 && r != 0);
    assert!(one_bill && classes.len() == bills.len() && c16.contains(&y) && det(u1, u2, u1) == 0);
    println!("ALL CHECKS PASS");
}
