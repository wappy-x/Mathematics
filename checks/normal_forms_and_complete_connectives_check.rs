// Normal forms -- the same check as the Python, in Rust.  No crates.  The club door: E = not A or I
// (A: after 9 pm, I: shows ID), rebuilt as a DNF, a CNF, NAND alone and NOR alone; then every table.
fn rows(n: u32) -> Vec<Vec<u8>> { (0..1u32 << n).rev().map(|k| (0..n).map(|j| (k >> (n - 1 - j) & 1) as u8).collect()).collect() }
fn nand(x: u8, y: u8) -> u8 { 1 - x * y }   fn nor(x: u8, y: u8) -> u8 { 1 - x.max(y) }   // NAND: false only on 1, 1
fn dnf(x: &[u8], trues: &[Vec<u8>]) -> u8 { trues.iter().any(|row| x.iter().zip(row).all(|(v, r)| v == r)) as u8 }
fn cnf(x: &[u8], falses: &[Vec<u8>]) -> u8 { falses.iter().all(|row| x.iter().zip(row).any(|(v, r)| v != r)) as u8 }
fn nand_only(x: &[u8], trues: &[Vec<u8>]) -> u8 {          // the DNF, wired from NAND gates only
    let one = nand(x[0], nand(x[0], x[0])); let mut acc = nand(one, one);   // wires always 1 and 0
    for row in trues {
        let mut term = one;
        for (&v, &r) in x.iter().zip(row) { let t = nand(term, if r == 1 { v } else { nand(v, v) }); term = nand(t, t); }
        acc = nand(nand(acc, acc), nand(term, term));     // or
    }
    acc
}
fn split(r: &[Vec<u8>], t: &[u8]) -> (Vec<Vec<u8>>, Vec<Vec<u8>>) {
    (r.iter().zip(t).filter(|p| *p.1 == 1).map(|p| p.0.clone()).collect(), r.iter().zip(t).filter(|p| *p.1 == 0).map(|p| p.0.clone()).collect())
}
fn rebuilt(n: u32, t: &[u8]) -> u32 {                       // 1 if all three roads give table t
    let r = rows(n); let (tr, fa) = split(&r, t);
    r.iter().zip(t).all(|(x, &b)| dnf(x, &tr) == b && cnf(x, &fa) == b && nand_only(x, &tr) == b) as u32
}
fn main() {
    let r = rows(2); let e: Vec<u8> = r.iter().map(|x| (x[0] == 0 || x[1] == 1) as u8).collect(); let (trues, falses) = split(&r, &e);   // road 1: the sign
    let cols: Vec<[u8; 4]> = r.iter().map(|x| [dnf(x, &trues), cnf(x, &falses), nand(x[0], nand(x[1], x[1])),
        nor(nor(nor(x[0], x[0]), x[1]), nor(nor(x[0], x[0]), x[1]))]).collect();
    println!("A I  NAND(I,I)  rule  DNF  CNF  NAND  NOR");
    for k in 0..4 { let c = cols[k]; println!("{} {}  {:>9}{:>6}{:>5}{:>5}{:>6}{:>5}", r[k][0], r[k][1], nand(r[k][1], r[k][1]), e[k], c[0], c[1], c[2], c[3]); }
    println!("DNF terms (one per true row): {}; CNF clauses (one per false row): {}", trues.len(), falses.len());
    let ok: Vec<u32> = [2u32, 3].iter().map(|&n| (0..1u32 << (1 << n)).map(|c| rebuilt(n, &(0..1 << n).map(|k| (c >> k & 1) as u8).collect::<Vec<u8>>())).sum()).collect();
    for (i, n) in [2u32, 3].iter().enumerate() { println!("{}-input tables rebuilt by DNF, CNF and NAND alone: {} of {}", n, ok[i], 1u32 << (1 << n)); }
    let agree = |m: Vec<u8>| m.iter().zip(&e).filter(|(a, b)| a == b).count();
    let bad = [agree(r.iter().map(|x| cnf(x, &trues)).collect()), agree(r.iter().map(|x| dnf(x, &trues[1..])).collect()), agree(r.iter().map(|x| nand(x[0], x[1])).collect()),
        agree(r.iter().map(|x| falses.iter().all(|row| x.iter().zip(row).any(|(v, w)| v == w)) as u8).collect())];
    println!("the four mistakes agree with the rule on {}, {}, {} and {} of 4 rows", bad[0], bad[1], bad[2], bad[3]);
    assert!(e == vec![1, 0, 1, 1] && cols.iter().zip(&e).all(|(c, &v)| c.iter().all(|&w| w == v)));   // four roads, one table
    assert!(ok == vec![16, 256]);                           // every table has a DNF, a CNF and a NAND form
    assert!(bad == [0, 3, 2, 2]);                           // the mistakes, counted by hand
    println!("ALL CHECKS PASS");
}
