// Sheaf cohomology as a derived functor -- the same check as the Python, in
// Rust.  No crates; every number is an exact integer, and ranks are taken mod
// the prime P = 1000003.  Road 1: H^i(P^n, O(k)) by the Cech complex of the
// charts x_i != 0, one Laurent monomial at a time, in the exponent box [-B, B].
// Road 2: the closed forms h^0 = C(k + n, n) and h^n = C(-k - 1, n).
// Road 3: the Hilbert function of S/(F), by the rank of multiplication by F,
// and points counted by brute force.  The long exact sequence joins them.
use std::collections::HashMap;
const P: i64 = 1000003;
const B: i64 = 8;

fn pw(mut a: i64, mut e: i64) -> i64 {
    let mut out = 1;
    a = a.rem_euclid(P);
    while e > 0 { if e & 1 == 1 { out = out * a % P } a = a * a % P; e >>= 1 }
    out
}

fn rank(rows: &[Vec<i64>]) -> usize {                  // Gaussian elimination mod P
    let mut m: Vec<Vec<i64>> = rows.iter().map(|r| r.iter().map(|v| v.rem_euclid(P)).collect()).collect();
    let ncols = if m.is_empty() { 0 } else { m[0].len() };
    let mut r = 0;
    for c in 0..ncols {
        let piv = match (r..m.len()).find(|&i| m[i][c] != 0) { Some(i) => i, None => continue };
        m.swap(r, piv);
        let inv = pw(m[r][c], P - 2);
        m[r] = m[r].iter().map(|v| v * inv % P).collect();
        for i in 0..m.len() {
            if i != r && m[i][c] != 0 {
                let f = m[i][c];
                let pr = m[r].clone();
                m[i] = m[i].iter().zip(pr.iter()).map(|(a, b)| (a - f * b).rem_euclid(P)).collect();
            }
        }
        r += 1;
    }
    r
}

fn binom(m: i64, r: i64) -> i64 {
    if m < r || m < 0 { return 0 }
    let mut out = 1;
    for i in 0..r { out = out * (m - i) / (i + 1) }
    out
}

fn monomials(n: usize, k: i64, bx: i64) -> Vec<Vec<i64>> {   // exponents adding to k
    if n == 0 { return if -bx <= k && k <= bx { vec![vec![k]] } else { vec![] } }
    let mut out = Vec::new();
    for a in -bx..=bx {
        for t in monomials(n - 1, k - a, bx) { let mut v = vec![a]; v.extend(t); out.push(v) }
    }
    out
}

fn cech(n: usize, k: i64, charts: &[usize], bx: i64) -> Vec<i64> {  // Cech H^0..H^n of O(k) on P^n
    let mut h = vec![0i64; n + 1];
    for e in monomials(n, k, bx) {
        let neg: Vec<usize> = (0..=n).filter(|&i| e[i] < 0).collect();
        let mut cells: Vec<Vec<Vec<usize>>> = vec![Vec::new(); charts.len()];
        for mask in 1..(1usize << charts.len()) {
            let set: Vec<usize> = (0..charts.len()).filter(|t| mask >> t & 1 == 1).map(|t| charts[t]).collect();
            if neg.iter().all(|i| set.contains(i)) { cells[set.len() - 1].push(set) }
        }
        let mut rr = vec![0usize];
        for p in 0..charts.len() - 1 {                 // (dc)_J = sum_j (-1)^j c_(J minus j-th)
            let mut rows = vec![vec![0i64; cells[p].len()]; cells[p + 1].len()];
            for (a, jset) in cells[p + 1].iter().enumerate() {
                for j in 0..jset.len() {
                    let mut face = jset.clone();
                    face.remove(j);
                    if let Some(col) = cells[p].iter().position(|c| *c == face) {
                        rows[a][col] = if j % 2 == 0 { 1 } else { -1 };
                    }
                }
            }
            rr.push(rank(&rows));
        }
        rr.push(0);
        for p in 0..charts.len() { h[p] += (cells[p].len() - rr[p] - rr[p + 1]) as i64 }
    }
    h
}

fn forms(nv: usize, n: i64) -> Vec<Vec<i64>> {         // exponents of the degree-n forms
    if n < 0 { return vec![] }
    if nv == 1 { return vec![vec![n]] }
    let mut out = Vec::new();
    for a in (0..=n).rev() {
        for t in forms(nv - 1, n - a) { let mut v = vec![a]; v.extend(t); out.push(v) }
    }
    out
}

fn hilbert(fs: &[HashMap<Vec<i64>, i64>], nv: usize, d: i64, n: i64) -> i64 {  // dim (S/(fs))_n
    let (rows_m, cols_m) = (forms(nv, n), forms(nv, n - d));
    let m: Vec<Vec<i64>> = rows_m.iter().map(|r| fs.iter().flat_map(|f| cols_m.iter().map(move |c| {
        let diff: Vec<i64> = (0..nv).map(|i| r[i] - c[i]).collect();
        *f.get(&diff).unwrap_or(&0)
    })).collect()).collect();
    rows_m.len() as i64 - rank(&m) as i64
}

fn poly(terms: &[[i64; 3]]) -> Vec<HashMap<Vec<i64>, i64>> { vec![terms.iter().map(|t| (t.to_vec(), 1)).collect()] }

fn main() {
    // ---- P^1 and two points: global sections lose one function, H^1 finds it ----
    let h1: HashMap<i64, Vec<i64>> = (-3..4).map(|k| (k, cech(1, k, &[0, 1], B))).collect();
    let pairs: Vec<String> = (-3..2).map(|k| format!("({}, {})", h1[&k][0], h1[&k][1])).collect();
    println!("P^1, (h0, h1) of O(k) for k = -3..1: {}", pairs.join(" "));
    let xy: Vec<HashMap<Vec<i64>, i64>> = vec![[(vec![1, 1], 1)].into_iter().collect()];
    let pl: Vec<(i64, i64)> = (0..7).map(|t| (1, t)).chain([(0, 1)]).collect();
    let pts = pl.iter().filter(|p| p.0 * p.1 % 7 == 0).count() as i64;
    let les_z: Vec<i64> = (0..4).map(|n| h1[&n][0] - h1[&(n - 2)][0] + h1[&(n - 2)][1] - h1[&n][1]).collect();
    let hf_z: Vec<i64> = (0..4).map(|n| hilbert(&xy, 2, 2, n)).collect();
    println!("two points Z = {{xy = 0}}: points over F_7 {}; h0(O_Z(n)), n = 0..3, by the sequence {:?}", pts, les_z);
    println!("  the same from the quotient ring (S/xy)_n: {:?}; the gap at n = 0 is h1(O(-2)) = {}", hf_z, h1[&-2][1]);

    // ---- P^2: Cech against the closed forms, and the curve's genus ----
    let h2: HashMap<i64, Vec<i64>> = (-8..6).map(|k| (k, cech(2, k, &[0, 1, 2], B))).collect();
    let big = [-6i64, 0, 2].iter().all(|&k| cech(2, k, &[0, 1, 2], B + 2) == h2[&k]);
    println!("P^2, h0 h1 h2 of O(k) by Cech in box {} (box {} agrees: {}):", B, B + 2, if big { "yes" } else { "no" });
    for k in -6..3i64 {
        let h = &h2[&k];
        let closed = [binom(k + 2, 2), 0, binom(-k - 1, 2)];
        println!("  k = {:2}: {:2} {} {:2}   closed forms {:2} 0 {:2}   chi {:2}",
                 k, h[0], h[1], h[2], closed[0], closed[2], h[0] - h[1] + h[2]);
        assert!(h[..] == closed[..] && h[0] - h[1] + h[2] == (k + 1) * (k + 2) / 2);
    }
    println!("plane curve C of degree d: h1(O_C) = h2(O(-d)), against (d - 1)(d - 2)/2");
    for d in 1..7i64 {
        let g = h2[&-d][2] - h2[&0][2];                // 0 -> H1(O_C) -> H2(O(-d)) -> H2(O) = 0
        println!("{}", format!("  degree {}: {:2} {:2}  {}", d, g, (d - 1) * (d - 2) / 2, "#".repeat(2 * g as usize)).trim_end());
        assert!(g == (d - 1) * (d - 2) / 2);
    }

    // ---- two named curves: the long exact sequence against the quotient ring ----
    let curves = [("Fermat cubic x^3 + y^3 + z^3", poly(&[[3, 0, 0], [0, 3, 0], [0, 0, 3]]), 3i64),
                  ("Klein quartic x^3y + y^3z + z^3x", poly(&[[3, 1, 0], [0, 3, 1], [1, 0, 3]]), 4)];
    for &(name, ref f, d) in curves.iter() {
        println!("{}: n, HF(n) by rank, h0(O_C(n)) and h1(O_C(n)) by the sequence, dn + 1 - g", name);
        let g = (d - 1) * (d - 2) / 2;
        for n in -1..6i64 {
            let hf = hilbert(f, 3, d, n);
            let h0 = h2[&n][0] - h2[&(n - d)][0];      // H1(O(n - d)) = 0 makes this exact
            let hh1 = h2[&(n - d)][2] - h2[&n][2];     // H2(O_C(n)) = 0: C has dimension 1
            println!("  n = {:2}: {:2} {:2} {} {:3}", n, hf, h0, hh1, d * n + 1 - g);
            assert!(hf == h0 && h0 - hh1 == d * n + 1 - g);
        }
        let slope = hilbert(f, 3, d, d + 1) - hilbert(f, 3, d, d);
        let hp0 = hilbert(f, 3, d, d) - d * slope;     // the Hilbert polynomial at n = 0
        println!("  Hilbert polynomial {}n + ({}), so 1 - HP(0) = {}, genus by the sequence {}", slope, hp0, 1 - hp0, g);
        let grads: Vec<HashMap<Vec<i64>, i64>> = (0..3).map(|i| f[0].iter().filter(|(e, _)| e[i] > 0)
            .map(|(e, c)| { let mut v = e.clone(); v[i] -= 1; (v, c * e[i]) }).collect()).collect();
        let sing = hilbert(&grads, 3, d - 1, 3 * d - 5);   // 0: the partials share no zero, so C is smooth
        println!("  smooth: forms of degree {} modulo the three partials of F leave {}", 3 * d - 5, sing);
        assert!(slope == d && 1 - hp0 == g && g == h2[&-d][2] && sing == 0);
    }

    // ---- what breaks ----
    println!("mistake 1, sections of the quotient ring as functions on Z: {}, not {}", hf_z[0], pts);
    println!("mistake 2, h1(O(-4)) for the quartic's genus: {}, not {}", h2[&-4][1], h2[&-4][2]);
    println!("mistake 3, the twist taken as O(+4): h2(O(4)) = {}, not {}", h2[&4][2], h2[&-4][2]);
    let two: Vec<i64> = [B, B + 2].iter().map(|&b| cech(2, -3, &[0, 1], b)[1]).collect();
    println!("mistake 4, charts x != 0 and y != 0 only, h1(O(-3)) in box {} and {}: {} and {}, not 0", B, B + 2, two[0], two[1]);
    assert!(les_z == vec![pts; 4] && hf_z[0] == 1 && h1[&-2] == vec![0, 1]);
    assert!((-3..4).all(|k| h1[&k] == vec![binom(k + 1, 1), binom(-k - 1, 1)]));
    assert!(two[1] > two[0] && two[0] > 0 && h2[&-4][1] == 0 && h2[&4][2] == 0 && big);
    println!("ALL CHECKS PASS");
}
