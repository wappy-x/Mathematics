// P versus NP: what is known -- the same check as the Python, in Rust.  No crates.
// One plain DPLL solver solves a staff rota, factors a number and stalls on pigeonhole
// formulas; an adversary fools an oracle machine.  A clause lists literals, +v or -v.
type Cnf = Vec<Vec<i64>>;

struct Solver { clauses: Cnf, val: Vec<i64>, nodes: u64 }  // val: +1 true, -1 false, 0 not set

impl Solver {
    fn setlit(&mut self, lit: i64, trail: &mut Vec<usize>) {
        self.val[lit.unsigned_abs() as usize] = lit.signum(); trail.push(lit.unsigned_abs() as usize);
    }
    fn propagate(&mut self, trail: &mut Vec<usize>) -> bool {  // one free literal is forced
        let mut changed = true;
        while changed {
            changed = false;
            for c in 0..self.clauses.len() {
                let cl = &self.clauses[c];
                if cl.iter().any(|&l| self.val[l.unsigned_abs() as usize] * l > 0) { continue }
                let free: Vec<i64> = cl.iter().copied().filter(|&l| self.val[l.unsigned_abs() as usize] == 0).collect();
                if free.is_empty() { return false }        // every literal false: a dead end
                if free.len() == 1 { self.setlit(free[0], trail); changed = true }
            }
        }
        true
    }
    fn search(&mut self, lit: i64) -> bool {
        self.nodes += 1;
        let mut trail = Vec::new();
        if lit != 0 { self.setlit(lit, &mut trail) }
        if self.propagate(&mut trail) {
            match (1..self.val.len()).find(|&v| self.val[v] == 0) {
                None => return true,
                Some(v) => if self.search(v as i64) || self.search(-(v as i64)) { return true },
            }
        }
        for v in trail { self.val[v] = 0 }
        false
    }
}

fn dpll(clauses: &Cnf, nvars: usize) -> (Option<Vec<bool>>, u64) {
    let mut s = Solver { clauses: clauses.clone(), val: vec![0; nvars + 1], nodes: 0 };
    if s.search(0) { (Some(s.val.iter().map(|&v| v > 0).collect()), s.nodes) } else { (None, s.nodes) }
}
fn satisfied(clauses: &Cnf, a: &[bool]) -> bool {  // the verifier V(x, c): one pass, no search
    clauses.iter().all(|cl| cl.iter().any(|&l| a[l.unsigned_abs() as usize] == (l > 0)))
}

fn yn(t: bool) -> &'static str { if t { "yes" } else { "no" } }
fn commas(n: u128) -> String {                  // 1234567 -> 1,234,567
    let (s, mut out) = (n.to_string(), String::new());
    for (i, ch) in s.chars().enumerate() { if i > 0 && (s.len() - i) % 3 == 0 { out.push(',') } out.push(ch) }
    out
}
fn poly(rota: &Cnf, a: &[i64], p: i64) -> i64 {  // arithmetised rota: clause -> 1 - prod(1 - literal)
    let mut out = 1;
    for cl in rota {
        let mut miss = 1;
        for &l in cl { miss = (miss * if l > 0 { 1 - a[l as usize] } else { a[(-l) as usize] }).rem_euclid(p) }
        out = (out * (1 - miss)).rem_euclid(p);
    }
    out
}

fn gate(cl: &mut Cnf, top: &mut i64, kind: u8, ins: &[i64]) -> i64 {  // one clause per truth-table row
    *top += 1;
    for m in 0..(1u32 << ins.len()) {
        let bits: Vec<i64> = (0..ins.len()).map(|i| ((m >> i) & 1) as i64).collect();
        let (sum, and) = (bits.iter().sum::<i64>(), bits[0] & bits[1]);
        let f = match kind { 0 => and, 1 => sum % 2, _ => (sum >= 2) as i64 };
        let mut c: Vec<i64> = ins.iter().zip(&bits).map(|(&v, &b)| if b == 1 { -v } else { v }).collect();
        c.push(if f == 1 { *top } else { -*top });
        cl.push(c);
    }
    *top
}

fn factor_cnf(n: u64, b: usize) -> (Cnf, usize) {  // school multiplier, product pinned to n
    let (mut cl, mut top): (Cnf, i64) = (Vec::new(), 2 * b as i64);
    let bi = b as i64;
    let mut acc: Vec<i64> = (0..bi).map(|j| gate(&mut cl, &mut top, 0, &[1 + j, bi + 1])).collect();
    for i in 1..b {                                     // add row i, shifted i places
        let row: Vec<i64> = (0..bi).map(|j| gate(&mut cl, &mut top, 0, &[1 + j, bi + 1 + i as i64])).collect();
        let (mut out, mut c): (Vec<i64>, Option<i64>) = (acc[..i].to_vec(), None);
        for j in 0..b {
            let a = if i + j < acc.len() { Some(acc[i + j]) } else { None };
            let pair: Vec<i64> = [a, Some(row[j]), c].iter().flatten().copied().collect();
            out.push(gate(&mut cl, &mut top, 1, &pair));
            c = Some(gate(&mut cl, &mut top, if pair.len() == 3 { 2 } else { 0 }, &pair));
        }
        out.push(c.unwrap()); acc = out;
    }
    for k in 0..2 * b { cl.push(vec![if (n >> k) & 1 == 1 { acc[k] } else { -acc[k] }]) }
    cl.push((2..=bi).collect()); cl.push((bi + 2..=2 * bi).collect());  // p >= 2, q >= 2
    (cl, top as usize)
}

fn formula_size(b: u128) -> (u128, u128) { (3 * b * b, 20 * b * b - 22 * b + 2) }  // counted by hand
fn machine(oracle: &[u64], length: u32, budget: u64, asked: &mut Vec<u64>) -> bool {  // asks 0, 1, 2, ...; logs each
    (0..budget.min(1 << length)).any(|s| { asked.push(s); oracle.contains(&s) })
}

fn main() {
    // 1. The rota: staff A, B, C; shifts Mon-early, Mon-late, Tue-early, Tue-late.
    let x = |s: i64, t: i64| 1 + 4 * s + t;
    let mut rota: Cnf = (0..4).map(|t| (0..3).map(|s| x(s, t)).collect()).collect();
    for t in 0..4 { for s in 0..3 { for r in s + 1..3 { rota.push(vec![-x(s, t), -x(r, t)]) } } }
    for s in 0..3 { for d in [0, 2] { rota.push(vec![-x(s, d), -x(s, d + 1)]) } }
    rota.push(vec![-x(1, 0)]);                          // B not Mon-early
    let (rsol, rnodes) = dpll(&rota, 12); let rsol = rsol.unwrap();
    let (shifts, mut found) = (["Mon-early", "Mon-late", "Tue-early", "Tue-late"], Vec::new());
    for t in 0..4 { for s in 0..3 { if rsol[x(s, t) as usize] { found.push(format!("{}:{}", ["A", "B", "C"][s as usize], shifts[t as usize])) } } }
    let cube: Vec<Vec<i64>> = (0..4096).map(|m| (0..13).map(|i| if i == 0 { 0 } else { (m >> (i - 1)) & 1 }).collect()).collect();
    let brute = cube.iter().filter(|pt| satisfied(&rota, &pt.iter().map(|&a| a == 1).collect::<Vec<bool>>())).count();
    let psum: i64 = cube.iter().map(|pt| poly(&rota, pt, 1009)).sum();
    println!("rota: 12 variables, {} clauses; DPLL nodes {}; verifier says {}", rota.len(), rnodes, yn(satisfied(&rota, &rsol)));
    println!("rota found: {}", found.join(", "));
    println!("valid rotas: brute force over 2^12 = 4096 settings {}; polynomial summed over them {}", brute, psum);
    println!("the polynomial at x = 2 for every variable, mod 97: {}", poly(&rota, &[2; 13], 97));

    let built: Vec<(u128, u128)> = (2..9).map(|b| { let (c, v) = factor_cnf(1, b); (v as u128, c.len() as u128) }).collect();
    let expect: Vec<(u128, u128)> = (2..9).map(formula_size).collect();
    let (n_big, bb) = (60491u64, 8usize);
    let (cl, nv) = factor_cnf(n_big, bb);
    let (sol, nodes) = dpll(&cl, nv); let sol = sol.unwrap();
    let bits = |off: usize| -> u64 { (0..bb).filter(|&j| sol[off + 1 + j]).map(|j| 1 << j).sum() };
    let (p, q) = (bits(0), bits(bb));
    let trial = (2..n_big).find(|d| n_big % d == 0).unwrap();
    let (v, c) = formula_size(1024);
    println!("formula sizes built for b = 2..8 match 3b^2 and 20b^2 - 22b + 2: {}", yn(built == expect));
    println!("b = {} bits each: b^2 = {}, 20b^2 = {}, 22b = {}; product bits {}, below 2^{} = {}", bb, bb * bb, 20 * bb * bb, 22 * bb, 2 * bb, 2 * bb, 1u64 << (2 * bb));
    println!("factor N = {}: {} variables, {} clauses; DPLL nodes {}; p = {}, q = {}", n_big, nv, cl.len(), nodes, p, q);
    println!("trial division finds {} x {}; check p x q = {}", trial, n_big / trial, p * q);
    println!("2048-bit RSA modulus as a formula: {} variables, {} clauses", commas(v), commas(c));

    // 3. Where the solver stalls: n + 1 pigeons into n holes, which can never fit.
    let mut php_nodes = Vec::new();
    for n in 1..7i64 {
        let y = |i: i64, h: i64| 1 + n * i + h;
        let mut php: Cnf = (0..=n).map(|i| (0..n).map(|h| y(i, h)).collect()).collect();
        for h in 0..n { for i in 0..=n { for j in i + 1..=n { php.push(vec![-y(i, h), -y(j, h)]) } } }
        let (res, k) = dpll(&php, (n * (n + 1)) as usize);
        php_nodes.push(k);
        println!("pigeonhole {} into {}: {} variables, {} clauses, satisfiable {}, DPLL nodes {}",
                 n + 1, n, n * (n + 1), php.len(), yn(res.is_some()), k);
    }

    // 4. Relativisation: an oracle machine with fewer than 2^L questions is fooled.
    let (l, budget, mut asked) = (10u32, (1u64 << 10) - 1, Vec::new());
    let says_empty = machine(&[], l, budget, &mut asked);              // the adversary watches this run
    let hidden: Vec<u64> = (0..1u64 << l).filter(|s| !asked.contains(s)).take(1).collect();   // and hides one never asked
    let says_hidden = machine(&hidden, l, budget, &mut Vec::new());
    println!("oracle, L = {}: {} strings of length {}; machine asks {}, answers {} on the empty oracle", l, 1u64 << l, l, asked.len(), yn(says_empty));
    let shown = hidden.iter().map(|s| format!("{:b}", s)).collect::<Vec<_>>().join(", ");
    println!("adversary adds {}: machine still answers {}; the truth is {}; the certificate check asks 1 question",
             if shown.is_empty() { "nothing" } else { shown.as_str() }, yn(says_hidden), yn(!hidden.is_empty()));

    // 5. Brute force against a polynomial budget.
    for m in [10u32, 20, 40, 60] { println!("n = {}: 2^n = {}; n^3 = {}", m, commas(1u128 << m), commas((m as u128).pow(3))) }
    let cross = (2u128..100).find(|&m| (m..100).all(|k| (1u128 << k) > k * k * k)).unwrap();
    println!("2^n passes n^3 for good at n = {}; at n = 9: {} vs {}", cross, 1 << 9, 9 * 9 * 9);

    assert!(brute == 24 && psum == 24 && satisfied(&rota, &rsol));       // three roads to the rota
    assert!(p * q == n_big && p.min(q) == trial && p.max(q) == n_big / trial);
    assert!(built == expect);                                            // construction against count
    assert!((2..5).all(|i| php_nodes[i + 1] > 6 * php_nodes[i]));      // each step over 6x
    assert!(!says_empty && says_hidden != !hidden.is_empty());          // the adversary wins
    assert!(cross == 10);
    println!("ALL CHECKS PASS");
}
