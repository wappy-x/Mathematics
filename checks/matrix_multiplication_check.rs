// Matrix multiplication -- the same check as the Python, in Rust.  No crates.
// A: kilograms per batch.  B: batches per day.  C: weekdays in four weeks.  Each
// product is reached twice: by the row-by-column definition, and by slices.
type Mat = Vec<Vec<i64>>;

fn size(m: &Mat) -> (usize, usize) { (m.len(), m[0].len()) }

fn times(m: &Mat, n: &Mat) -> Option<Mat> {          // road 1: the definition itself
    let ((rm, cm), (rn, cn)) = (size(m), size(n));
    if cm != rn { return None; }                     // inner sizes disagree: no product
    let mut out: Mat = Vec::new();
    for i in 0..rm {
        let mut row: Vec<i64> = Vec::new();
        for j in 0..cn {
            let mut total = 0;
            for k in 0..cm {                         // across m's row, down n's column
                total += m[i][k] * n[k][j];
            }
            row.push(total);
        }
        out.push(row);
    }
    Some(out)
}

fn slice_k(m: &Mat, n: &Mat, k: usize) -> Mat {      // road 2: column k of m times row k of n
    (0..size(m).0).map(|i| (0..size(n).1).map(|j| m[i][k] * n[k][j]).collect()).collect()
}

fn add(m: &Mat, n: &Mat) -> Mat {
    (0..m.len()).map(|i| (0..m[0].len()).map(|j| m[i][j] + n[i][j]).collect()).collect()
}

fn show(name: &str, value: &Mat) { println!("{:<52}{:?}", name, value); }
fn show_s(name: &str, value: &str) { println!("{:<52}{}", name, value); }

fn main() {
    let a: Mat = vec![vec![5, 3], vec![2, 2]];     // rows: flour, butter.       cols: brioche, croissant
    let b: Mat = vec![vec![2, 1], vec![1, 1]];     // rows: brioche, croissant.  cols: Monday, Tuesday
    let c: Mat = vec![vec![4], vec![4]];           // rows: Monday, Tuesday.     one column
    let (ab, ba, bc) = (times(&a, &b).unwrap(), times(&b, &a).unwrap(), times(&b, &c).unwrap());
    let (s1, s2) = (slice_k(&a, &b, 0), slice_k(&a, &b, 1));
    let (t1, t2) = (slice_k(&ab, &c, 0), slice_k(&ab, &c, 1));
    let (abc, a_bc) = (times(&ab, &c).unwrap(), times(&a, &bc).unwrap());
    show("A  kg per batch, flour/butter by brioche/croissant", &a);
    show("B  batches per day, brioche/croissant by Mon/Tue", &b);
    show("C  count of each day in four weeks", &c);
    show("AB kg per day, flour/butter by Mon/Tue", &ab);
    for &(nm, i, j) in [("flour on Monday", 0usize, 0usize), ("flour on Tuesday", 0, 1),
                        ("butter on Monday", 1, 0), ("butter on Tuesday", 1, 1)].iter() {
        let parts: Vec<String> = (0..2).map(|k| format!("{}*{}", a[i][k], b[k][j])).collect();
        println!("   {:<18}{} = {}", nm, parts.join(" + "), ab[i][j]);
    }
    show("BA the swapped order, same numbers, no meaning", &ba);
    show("BC batches in four weeks, brioche/croissant", &bc);
    show("(AB)C kg in four weeks, kg per day first", &abc);
    show("A(BC) kg in four weeks, batches first", &a_bc);
    show("slice 1, brioche recipe times brioche schedule", &s1);
    show("slice 2, croissant recipe times croissant schedule", &s2);
    show_s("(AB)C again, as slices of AB against C",
           &format!("{:?} + {:?} = {:?}", t1, t2, add(&t1, &t2)));
    let ew: Mat = (0..2).map(|i| (0..2).map(|j| a[i][j] * b[i][j]).collect()).collect();
    show("wrong: entry by entry", &ew);
    show("wrong: first product only, rest of the sum dropped", &s1);
    show_s("wrong: C on the left of AB", "no product: 2x1 then 2x2, inner sizes 1 and 2");
    println!("sizes: {}x{} times {}x{} -> {}x{}, and {}x{} times {}x{} -> {}x{}",
             size(&a).0, size(&a).1, size(&b).0, size(&b).1, size(&ab).0, size(&ab).1,
             size(&ab).0, size(&ab).1, size(&c).0, size(&c).1, size(&abc).0, size(&abc).1);
    assert!(ab == vec![vec![13, 8], vec![6, 4]] && ba == vec![vec![12, 8], vec![7, 5]] && ab != ba);
    assert!(add(&s1, &s2) == ab && s1 == vec![vec![10, 5], vec![4, 2]] && s2 == vec![vec![3, 3], vec![2, 2]]);
    assert!(abc == vec![vec![84], vec![40]] && a_bc == vec![vec![84], vec![40]] && bc == vec![vec![12], vec![8]]
            && t1 == vec![vec![52], vec![24]] && t2 == vec![vec![32], vec![16]] && add(&t1, &t2) == abc);
    assert!(times(&c, &ab).is_none() && size(&a_bc) == (2, 1));
    println!("ALL CHECKS PASS");
}
