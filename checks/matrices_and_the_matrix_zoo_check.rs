// Matrices -- the same check as the Python, in Rust.  No crates.  The cafe's
// sales table has five days down the rows and two products across the columns.
// Two roads to the per-product totals: add down the columns of the table, and
// add across the rows of its transpose.  Second worked case: the two-day square
// table A, its sum with week two, its scaling, and the named shapes.
type Mat = Vec<Vec<i64>>;
fn mat(rows: &[&[i64]]) -> Mat { rows.iter().map(|r| r.to_vec()).collect() }
fn rows(m: &Mat) -> usize { m.len() }
fn cols(m: &Mat) -> usize { m[0].len() }
fn transpose(m: &Mat) -> Mat {
    (0..cols(m)).map(|j| (0..rows(m)).map(|i| m[i][j]).collect()).collect()
}
fn add(a: &Mat, b: &Mat) -> Mat {
    (0..rows(a)).map(|i| (0..cols(a)).map(|j| a[i][j] + b[i][j]).collect()).collect()
}
fn scale(c: i64, a: &Mat) -> Mat {
    (0..rows(a)).map(|i| (0..cols(a)).map(|j| c * a[i][j]).collect()).collect()
}

fn trace(m: &Mat) -> i64 {                             // add the main diagonal
    let mut total = 0;
    for i in 0..rows(m) {
        total += m[i][i];
    }
    total
}

fn show(m: &Mat) -> String {
    let rs: Vec<String> = m.iter()
        .map(|r| r.iter().map(|x| x.to_string()).collect::<Vec<String>>().join(", "))
        .collect();
    format!("[[{}]]", rs.join("], ["))
}

fn grid(label: &str, m: &Mat, names: &[&str], what: &str) {
    println!("{}, {} rows by {} columns ({})", label, rows(m), cols(m), what);
    for (name, row) in names.iter().zip(m.iter()) {
        let mut line = format!("  {:<7}", name);
        for x in row { line.push_str(&format!("{:>3}", x)); }
        println!("{}", line);
    }
}

fn main() {
    let days = ["Mon", "Tue", "Wed", "Thu", "Fri"];
    let products = ["coffee", "pastry"];
    let sales = mat(&[&[2, 1], &[1, 1], &[3, 2], &[2, 1], &[4, 3]]);   // 5 rows by 2 columns
    let flipped = transpose(&sales);
    let down: Vec<i64> = (0..cols(&sales))                             // road one
        .map(|j| (0..rows(&sales)).map(|i| sales[i][j]).sum()).collect();
    let across: Vec<i64> = flipped.iter().map(|r| r.iter().sum()).collect();   // road two
    grid("sales table", &sales, &days, "days by products");
    grid("transposed", &flipped, &products, "products by days");
    println!("coffees and pastries, down the columns:  {}  {}   ({} items in all)",
             down[0], down[1], down[0] + down[1]);
    println!("coffees and pastries, across the rows of the transpose:  {}  {}", across[0], across[1]);
    let day_totals: Vec<i64> = sales.iter().map(|r| r.iter().sum()).collect();
    let shown: Vec<String> = day_totals.iter().map(|t| t.to_string()).collect();
    println!("day totals, across the rows of the sales table: {}", shown.join(" "));

    let a = mat(&[&[2, 1], &[1, 1]]);
    let b = mat(&[&[3, 2], &[2, 1]]);
    let tri = mat(&[&[2, 1], &[0, 1]]);
    let ident = mat(&[&[1, 0], &[0, 1]]);
    let prices = mat(&[&[4, 0], &[0, 3]]);
    println!("two days only, A = {}, {} rows by {} columns", show(&a), rows(&a), cols(&a));
    println!("week two B = {};  A + B = {};  2A = {}", show(&b), show(&add(&a, &b)), show(&scale(2, &a)));
    println!("A transposed = {}, equal to A, so A is symmetric", show(&transpose(&a)));
    println!("upper triangular {}: row 2 column 1 is {}, row 1 column 2 is {}; transposed {}, not equal to it",
             show(&tri), tri[1][0], tri[0][1], show(&transpose(&tri)));
    println!("prices on the diagonal {}; identity {}", show(&prices), show(&ident));
    println!("traces: A {}, identity {}, prices {}, triangular {}",
             trace(&a), trace(&ident), trace(&prices), trace(&tri));

    assert!(flipped == mat(&[&[2, 1, 3, 2, 4], &[1, 1, 2, 1, 3]]) && rows(&flipped) == cols(&sales) && cols(&flipped) == rows(&sales));
    assert!(down == across && down == vec![12, 8]);
    assert!(transpose(&flipped) == sales && add(&a, &b) == mat(&[&[5, 3], &[3, 2]]) && scale(2, &a) == mat(&[&[4, 2], &[2, 2]]));
    assert!(transpose(&a) == a && transpose(&tri) != tri && vec![trace(&a), trace(&ident), trace(&prices), trace(&tri)] == vec![3, 2, 7, 3]);
    println!("ALL CHECKS PASS");
}
