// Matrix times vector -- the same check as the Python, in Rust.  No crates.
// The cafe's table A = [[2, 1], [1, 1]] holds the two days down and the two
// products across: Monday 2 coffees + 1 pastry, Tuesday 1 coffee + 1 pastry.
// The price vector x = (4, 3) is a $4 coffee and a $3 pastry.  The takings are
// reached by two roads that share no code, then again with a third day added.

fn columns(m: &[Vec<i64>]) -> Vec<Vec<i64>> {          // the table read down
    (0..m[0].len()).map(|j| m.iter().map(|row| row[j]).collect()).collect()
}

fn by_columns(m: &[Vec<i64>], v: &[i64]) -> Vec<i64> {  // road 1: weigh the columns
    let mut out = vec![0i64; m.len()];
    for (weight, col) in v.iter().zip(columns(m).iter()) {
        for (o, c) in out.iter_mut().zip(col.iter()) { *o += weight * c; }
    }
    out
}

fn by_rows(m: &[Vec<i64>], v: &[i64]) -> Vec<i64> {     // road 2: row against v
    m.iter()
        .map(|row| row.iter().zip(v.iter()).map(|(e, p)| e * p).sum::<i64>())
        .collect()
}

fn fits(m: &[Vec<i64>], v: &[i64]) -> bool {            // the size rule
    m.iter().all(|row| row.len() == v.len())
}

fn show(name: &str, v: &[i64]) {
    let body: Vec<String> = v.iter().map(|k| k.to_string()).collect();
    println!("{:<32}{:>14}", name, format!("({})", body.join(", ")));
}

fn main() {
    let a: Vec<Vec<i64>> = vec![vec![2, 1], vec![1, 1]];
    let b: Vec<Vec<i64>> = vec![vec![2, 1], vec![1, 1], vec![3, 2]];   // Wednesday
    let x: Vec<i64> = vec![4, 3];
    let ca = columns(&a);
    let coffee: Vec<i64> = ca[0].iter().map(|c| 4 * c).collect();
    let pastry: Vec<i64> = ca[1].iter().map(|c| 3 * c).collect();
    show("the coffee column, weighed by 4", &coffee);
    show("the pastry column, weighed by 3", &pastry);
    show("road 1: the columns, mixed", &by_columns(&a, &x));
    let ra = by_rows(&a, &x);
    for (i, row) in a.iter().enumerate() {
        let parts: Vec<String> =
            row.iter().zip(x.iter()).map(|(e, p)| format!("{}*{}", e, p)).collect();
        println!("road 2: row {} against the prices   {} = {}", i + 1, parts.join(" + "), ra[i]);
    }
    show("road 2: row by entry, added", &ra);
    println!("sizes: A is {} by {}, x has {} entries, the answer has {}",
             a.len(), a[0].len(), x.len(), ra.len());
    show("wrong: columns added, no prices", &by_columns(&a, &[1, 1]));
    show("wrong: prices swapped to (3, 4)", &by_columns(&a, &[3, 4]));
    println!("a 2 by 2 handed three prices: {}",
             if fits(&a, &[4, 3, 5]) { "fits" } else { "refused, the sizes do not fit" });
    show("third day added, road 1", &by_columns(&b, &x));
    let rb = by_rows(&b, &x);
    show("third day added, road 2", &rb);
    println!("sizes: B is {} by {}, x has {} entries, the answer has {}",
             b.len(), b[0].len(), x.len(), rb.len());
    assert!(by_columns(&a, &x) == vec![11, 7] && ra == vec![11, 7]);
    assert!(by_columns(&b, &x) == vec![11, 7, 18] && rb == vec![11, 7, 18]);
    assert!(by_columns(&a, &[1, 1]) == vec![3, 2] && by_columns(&a, &[3, 4]) == vec![10, 7]);
    assert!(!fits(&a, &[4, 3, 5]) && fits(&b, &x) && rb.len() == 3);
    println!("ALL CHECKS PASS");
}
