// Solving A x = b -- the same check as the Python, in Rust.  No crates.  The
// cafe: Monday 2 coffees + 1 pastry = $11, Tuesday 1 coffee + 1 pastry = $7, so
// A = [[2, 1], [1, 1]] and b = (11, 7).  Two roads to the same prices, then the
// two look-alike days: totals $22 (a line of answers) and $23 (no answer).

// Row two minus (its left entry over row one's left entry) times row one.
// Every case here has a nonzero top left, so no row swap is needed.
fn eliminate(a: [[f64; 2]; 2], b: (f64, f64)) -> (&'static str, f64, f64, f64, f64, f64) {
    let (p, q, r, s) = (a[0][0], a[0][1], a[1][0], a[1][1]);
    let f = r / p;                             // the multiple of row one to remove
    let (s2, t2) = (s - f * q, b.1 - f * b.0); // row two after the subtraction
    if s2 != 0.0 {                             // one unknown left: read it, then back up
        let y = t2 / s2;
        return ("one answer", (b.0 - q * y) / p, y, f, s2, t2);
    }
    if t2 != 0.0 {                             // row two now reads 0 = t2
        return ("no answer", 0.0, 0.0, f, s2, t2);
    }
    ("a line of answers", 0.0, 0.0, f, s2, t2)
}

fn times(a: [[f64; 2]; 2], v: (f64, f64)) -> (f64, f64) {   // A x: the mix of A's columns
    (a[0][0] * v.0 + a[0][1] * v.1, a[1][0] * v.0 + a[1][1] * v.1)
}

fn columns_test(a: [[f64; 2]; 2]) -> f64 {     // zero when one column is a multiple of the other
    a[0][0] * a[1][1] - a[0][1] * a[1][0]
}

fn main() {
    let a = [[2.0, 1.0], [1.0, 1.0]];
    let b = (11.0, 7.0);
    let (kind, x, y, f, s2, t2) = eliminate(a, b);
    let x2 = b.0 - b.1;                        // second road: y = 7 - x put into
    let y2 = b.1 - x2;                         // 2x + y = 11 leaves x = 11 - 7
    let (ax, ay) = times(a, (x, y));
    let same = [[2.0, 1.0], [4.0, 2.0]];       // Tuesday doubled: 4 coffees + 2 pastries
    let (k22, _, _, _, _, _) = eliminate(same, (11.0, 22.0));
    let (k23, _, _, _, _, gap) = eliminate(same, (11.0, 23.0));
    let fits: Vec<(f64, f64)> = [0.0, 2.0, 4.0, 5.5].iter().map(|t| (*t, 11.0 - 2.0 * t)).collect();
    let free = (same[0][1], -same[0][0]);      // one more coffee, two fewer pastries
    let zz = times(same, free);                // and neither day's total budges
    let (_, xw, yw, _, _, _) = eliminate(a, (7.0, 11.0));   // the totals in the wrong order

    println!("A = [[2, 1], [1, 1]] and b = (11, 7), so 2x + y = 11 and x + y = 7");
    println!("elimination: row two minus {:.2} x row one leaves {:.2} y = {:.2}", f, s2, t2);
    println!("read it back up: y = {:.2}, then x = (11 - 1 x {:.2}) / 2 = {:.2}", y, y, x);
    println!("second road, substitution: x = 11 - 7 = {:.2}, then y = 7 - {:.2} = {:.2}", x2, x2, y2);
    println!("so a coffee is ${:.2} and a pastry is ${:.2}, and that is {}", x, y, kind);
    println!("multiply back: A x = ({:.2}, {:.2}) and b = (11.00, 7.00)", ax, ay);
    println!("as a column mix: {:.2} x (2, 1) + {:.2} x (1, 1) = ({:.2}, {:.2})", x, y, ax, ay);
    for (lab, c, m) in [("2x + y = 11", 11.0, 2.0), ("x + y = 7", 7.0, 1.0), ("4x + 2y = 23", 23.0 / 2.0, 2.0)] {
        let ys: Vec<String> = (0..6).map(|k| format!("{:.2}", c - m * k as f64)).collect();
        println!("the line {}, y at x = 0, 1, 2, 3, 4, 5: {}", lab, ys.join(", "));
    }
    println!("columns test, zero when dependent: {:.2} for the cafe, {:.2} for the doubled Tuesday",
             columns_test(a), columns_test(same));
    let fl: Vec<String> = fits.iter().map(|(t, u)| format!("({:.2}, {:.2})", t, u)).collect();
    println!("[[2, 1], [4, 2]] x = (11, 22): {}, and four prices that all fit are {}", k22, fl.join(" "));
    println!("the free direction ({:.2}, {:.2}) adds ({:.2}, {:.2}) to the totals, so (4.00, 3.00) \
              plus it, ({:.2}, {:.2}), fits too", free.0, free.1, zz.0, zz.1, 4.0 + free.0, 3.0 + free.1);
    println!("[[2, 1], [4, 2]] x = (11, 23): {}, elimination ends at 0 = {:.2}, so every price \
              on the line above misses the $23 day by {:.2}", k23, gap, gap);
    println!("mistakes: b divided entry by entry gives ({:.2}, {:.2}), b in the wrong order gives ({:.2}, {:.2})",
             b.0 / 2.0, b.1 / 1.0, xw, yw);
    assert!(x == 4.0 && y == 3.0 && columns_test(a) == 1.0);       // by hand: 2x1 - 1x1
    assert!(x2 == 4.0 && y2 == 3.0 && ax == 11.0 && ay == 7.0);    // second road agrees, A x hits b
    assert!(columns_test(same) == 0.0 && zz == (0.0, 0.0) && times(same, (5.0, 1.0)) == (11.0, 22.0));
    assert!(k22 == "a line of answers" && k23 == "no answer" && gap == 1.0);
    println!("ALL CHECKS PASS");
}
