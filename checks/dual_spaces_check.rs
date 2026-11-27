// Dual spaces -- the same check as the Python, in Rust.  No crates.  The dual
// basis is found by inverting and by search; item prices are pulled back to
// hamper prices by the transpose; row rank = column rank is tested on 300 matrices.
fn bill(p: &[i64], v: &[i64]) -> i64 { p.iter().zip(v).map(|(a, b)| a * b).sum() }

fn rank(input: &[Vec<i64>]) -> usize {            // elimination in whole numbers
    let mut rows = input.to_vec();
    let mut r = 0;
    for c in 0..rows.first().map_or(0, |x| x.len()) {
        let piv = match (r..rows.len()).find(|&i| rows[i][c] != 0) { Some(i) => i, None => continue };
        rows.swap(r, piv);
        for i in r + 1..rows.len() {
            let (a, b) = (rows[r][c], rows[i][c]);
            rows[i] = rows[i].iter().zip(&rows[r]).map(|(x, y)| a * x - b * y).collect();
        }
        r += 1;
    }
    r
}

fn dual_by_inverse(b1: (i64, i64), b2: (i64, i64)) -> Vec<(i64, i64)> {
    let d = b1.0 * b2.1 - b2.0 * b1.1;             // the determinant, 1 or -1 here
    vec![(b2.1 / d, -b2.0 / d), (-b1.1 / d, b1.0 / d)]
}

fn dual_by_search(b1: (i64, i64), b2: (i64, i64)) -> Vec<(i64, i64)> {   // -5 to 5
    let rd = |f: (i64, i64), b: (i64, i64)| f.0 * b.0 + f.1 * b.1;
    let grid: Vec<(i64, i64)> = (-5..6).flat_map(|x| (-5..6).map(move |y| (x, y))).collect();
    [(1, 0), (0, 1)].iter().map(|&w| *grid.iter().find(|&&f| (rd(f, b1), rd(f, b2)) == w).unwrap()).collect()
}

fn transpose(m: &[Vec<i64>]) -> Vec<Vec<i64>> {   // rows become columns
    (0..m[0].len()).map(|j| m.iter().map(|row| row[j]).collect()).collect()
}

fn main() {
    let (b1, b2, p, v) = ((2i64, 1i64), (1i64, 1i64), (3i64, 2i64), (2i64, 3i64));
    let rd = |f: (i64, i64), b: (i64, i64)| f.0 * b.0 + f.1 * b.1;
    let f = dual_by_inverse(b1, b2);
    let readings: Vec<Vec<i64>> = f.iter().map(|&fi| vec![rd(fi, b1), rd(fi, b2)]).collect();
    let (s1, s2, c1, c2) = (rd(p, b1), rd(p, b2), rd(f[0], v), rd(f[1], v));
    let p_back = (s1 * f[0].0 + s2 * f[1].0, s1 * f[0].1 + s2 * f[1].1);
    let v_back = (c1 * b1.0 + c2 * b2.0, c1 * b1.1 + c2 * b2.1);
    let a: Vec<Vec<i64>> = vec![vec![2, 1], vec![3, 0], vec![1, 2]];   // columns are the hampers
    let (q, order) = (vec![3i64, 2, 4], vec![1i64, 2]);
    let hp: Vec<i64> = transpose(&a).iter().map(|col| bill(col, &q)).collect();   // A^T q
    let items: Vec<i64> = a.iter().map(|row| bill(row, &order)).collect();
    let mut hidden: Vec<Vec<i64>> = Vec::new();
    for x in -3..4 { for y in -3..4 { for z in -3..4 {
        if transpose(&a).iter().all(|h| bill(&[x, y, z], h) == 0) { hidden.push(vec![x, y, z]) }
    } } }
    let (mut seed, mut vals) = (7i64, Vec::new());
    for _ in 0..3600 {                             // 300 matrices, 3 by 4, entries 0 or 1
        seed = (seed * 1103515245 + 12345) % (1i64 << 31);
        vals.push(seed / 65536 % 2);
    }
    let batch: Vec<Vec<Vec<i64>>> = (0..300).map(|k| (0..3).map(|i| vals[12 * k + 4 * i..12 * k + 4 * i + 4].to_vec()).collect()).collect();
    let same = batch.iter().all(|m| rank(m) == rank(&transpose(m)));
    let mut seen: Vec<usize> = batch.iter().map(|m| rank(m)).collect();
    seen.sort(); seen.dedup();
    let hid: Vec<(i64, i64, i64)> = hidden.iter().map(|h| (h[0], h[1], h[2])).collect();
    println!("the weekly shop's bill: price list (3, 2, 4) reads basket (2, 3, 1) as ${}", bill(&[3, 2, 4], &[2, 3, 1]));
    println!("dual basis by inverting: {:?}; by search: {:?}", f, dual_by_search(b1, b2));
    println!("readings f_i(b_j): {:?}", readings);
    println!("price list {:?} = {} f1 + {} f2 -> {:?}", p, s1, s2, p_back);
    println!("basket {:?} = {} b1 + {} b2 -> {:?}", v, c1, c2, v_back);
    println!("hamper prices A^T q: {:?}; order {:?} -> items {:?}", hp, order, items);
    println!("bill of the order: item road ${}, hamper road ${}", bill(&q, &items), bill(&hp, &order));
    println!("hidden price changes by search: {:?}; independent: {} = 3 - {}", hid, rank(&hidden), rank(&a));
    println!("rank of A {}, rank of A^T {}", rank(&a), rank(&transpose(&a)));
    println!("row rank = column rank on 300 matrices: {}; ranks seen {:?}", if same { "yes" } else { "no" }, seen);
    println!("mistake 1, basis basket (2, 1) as a price list reads b1, b2 as {:?}", vec![rd(b1, b1), rd(b1, b2)]);
    println!("mistake 2, hamper prices pushed forward by A: {:?}", a.iter().map(|row| bill(row, &hp)).collect::<Vec<i64>>());
    println!("mistake 3, b2 swapped to (1, 0): dual basis becomes {:?}", dual_by_inverse(b1, (1, 0)));
    assert!(f == dual_by_search(b1, b2) && dual_by_inverse(b1, (1, 0)) == dual_by_search(b1, (1, 0)));
    assert!(readings == vec![vec![1, 0], vec![0, 1]] && p_back == p && v_back == v);
    assert!(bill(&q, &items) == 38 && bill(&hp, &order) == 38);   // two roads to one bill
    assert!(rank(&hidden) == q.len() - rank(&a) && same);         // annihilator size; the theorem
    println!("ALL CHECKS PASS");
}
