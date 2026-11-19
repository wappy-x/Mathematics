// The Hodge conjecture in degree 2, on a K3 surface -- the same check as the Python, in Rust.
// No crates.  The Fermat quartic x^4 + y^4 + z^4 + w^4 = 0 in P^3:
//   road 1 (Hodge side): h^(p,q) by counting monomials, against the Euler number and the signature
//   road 2 (cycle side): its 48 lines, which pairs meet (exact 4 x 4 determinants over Z[zeta]),
//                        and the rank of their intersection matrix, by exact integer elimination
//   road 3 (one class two ways): 24 plane sections, four lines each, all give the plane class h
type Z8 = [i128; 4];                         // Z[t]/(t^4 + 1): t = zeta, a primitive 8th root of unity
const ZERO: Z8 = [0, 0, 0, 0];
const ONE: Z8 = [1, 0, 0, 0];
const ZETA: Z8 = [0, 1, 0, 0];

fn zmul(a: Z8, b: Z8) -> Z8 {
    let mut r = [0i128; 8];
    for i in 0..4 { for j in 0..4 { r[i + j] += a[i].checked_mul(b[j]).unwrap(); } }
    [r[0] - r[4], r[1] - r[5], r[2] - r[6], r[3] - r[7]]
}

fn perms(k: usize, cur: &mut Vec<usize>, out: &mut Vec<Vec<usize>>) {
    if cur.len() == k { out.push(cur.clone()); return; }
    for v in 0..k { if !cur.contains(&v) { cur.push(v); perms(k, cur, out); cur.pop(); } }
}

fn zdet(m: &Vec<Z8>) -> Z8 {                 // 4 x 4 determinant over Z[zeta]; m is 16 entries, row by row
    let mut ps = Vec::new();
    perms(4, &mut Vec::new(), &mut ps);
    let mut total = ZERO;
    for p in ps {
        let inv = (0..4).map(|i| (i + 1..4).filter(|&j| p[i] > p[j]).count()).sum::<usize>();
        let sign = if inv % 2 == 0 { 1 } else { -1 };
        let mut term = ONE;
        for i in 0..4 { term = zmul(term, m[4 * i + p[i]]); }
        for t in 0..4 { total[t] += sign * term[t]; }
    }
    total
}

fn bareiss(m0: &Vec<Vec<i128>>) -> (usize, i128) {   // fraction-free elimination: (rank, signed det if square)
    let mut m = m0.clone();
    let (rows, cols) = (m.len(), m[0].len());
    let (mut prev, mut r, mut sign) = (1i128, 0usize, 1i128);
    for c in 0..cols {
        let Some(p) = (r..rows).find(|&i| m[i][c] != 0) else { continue };
        if p != r { m.swap(r, p); sign = -sign; }
        for i in r + 1..rows {
            for j in c + 1..cols {
                m[i][j] = (m[r][c].checked_mul(m[i][j]).unwrap() - m[i][c].checked_mul(m[r][j]).unwrap()) / prev;
            }
            m[i][c] = 0;
        }
        prev = m[r][c];
        r += 1;
    }
    (r, if r == rows && rows == cols { sign * prev } else { 0 })
}

fn main() {
    // ---- road 1: Hodge numbers of a smooth quartic surface ----
    let d: i64 = 4;
    let jac: Vec<i64> = [0, 4, 8].iter().map(|&k| {
        let mut c = 0;
        for e in 0..81 { let (a, b, x, y) = (e % 3, e / 3 % 3, e / 9 % 3, e / 27); if a + b + x + y == k { c += 1; } }
        c
    }).collect();
    let (h20, h11, h02) = (jac[0], jac[1] + 1, jac[2]);
    let (euler, sig) = (d.pow(3) - 4 * d * d + 6 * d, (4 - d * d) * d / 3);
    let b2 = euler - 2;
    println!("road 1, the Hodge side of a smooth quartic surface (a K3 surface)");
    println!("monomials with exponents at most 2, of degree 0, 4, 8: {}, {}, {}", jac[0], jac[1], jac[2]);
    println!("h^2,0 = {}, h^1,1 = {} + 1 = {}, h^0,2 = {}; b2 = {}", h20, jac[1], h11, h02, h20 + h11 + h02);
    println!("Euler number 64 - 64 + 24 = {}, so b2 = {}; signature (4 - 16) x 4 / 3 = {}", euler, b2, sig);
    println!("signature from Hodge numbers 2 + 2 x {} - {} = {}; positive part b+ = {} = 2 h^2,0 + 1",
             h20, h11, 2 + 2 * h20 - h11, (b2 + sig) / 2);

    // ---- road 2: the 48 lines and their intersection matrix ----
    let mut pw = vec![ONE];
    for _ in 0..7 { let t = zmul(*pw.last().unwrap(), ZETA); pw.push(t); }
    let roots: Vec<Z8> = [1, 3, 5, 7].iter().map(|&k| pw[k]).collect();     // the four a with a^4 = -1
    let pairings = [(0, 1, 2, 3), (0, 2, 1, 3), (0, 3, 1, 2)];
    let mut lines: Vec<Vec<Z8>> = Vec::new();                           // 8 entries: the two linear forms
    for &(i, j, k, l) in pairings.iter() {
        for a in roots.iter() { for b in roots.iter() {                  // the line x_i = a x_j, x_k = b x_l
            let mut f = vec![ZERO; 8];
            f[i] = ONE; f[j] = a.map(|x| -x); f[4 + k] = ONE; f[4 + l] = b.map(|x| -x);
            lines.push(f);
        } }
    }
    assert!(roots.iter().all(|&r| zmul(zmul(r, r), zmul(r, r)) == [-1, 0, 0, 0]));   // a^4 = -1: each line lies on X
    let n = lines.len();
    let meet = |r: usize, c: usize| { let mut m = lines[r].clone(); m.extend(lines[c].iter()); zdet(&m) == ZERO };
    let g: Vec<Vec<i128>> = (0..n).map(|r| (0..n).map(|c| if r == c { -2 } else if meet(r, c) { 1 } else { 0 }).collect()).collect();
    let (rank48, _) = bareiss(&g);
    println!("road 2, the cycle side: the 48 lines on the Fermat quartic");
    let mut meets: Vec<i128> = g.iter().map(|r| r.iter().sum::<i128>() + 2).collect(); meets.sort(); meets.dedup();   // how many other lines each of the 48 meets
    println!("lines: {}; each meets {} others; self-intersection of a line: {}", n, meets.iter().map(|m| m.to_string()).collect::<Vec<_>>().join(", "), g[0][0]);
    println!("rank of the 48 x 48 intersection matrix over Q: {}", rank48);
    let (mut basis, mut minors): (Vec<usize>, Vec<i128>) = (vec![], vec![1]);
    for c in 0..n {                                                     // grow a basis while the Gram determinant stays nonzero
        let mut idx = basis.clone(); idx.push(c);
        let sub: Vec<Vec<i128>> = idx.iter().map(|&a| idx.iter().map(|&b| g[a][b]).collect()).collect();
        let (_, dt) = bareiss(&sub);
        if dt != 0 { basis.push(c); minors.push(dt); }
    }
    let neg = minors.windows(2).filter(|w| (w[0] > 0) != (w[1] > 0)).count();
    println!("independent lines found: {}; Gram determinant of the {}: {}", basis.len(), basis.len(), minors.last().unwrap());
    println!("signature of the intersection form on them: ({}, {})", basis.len() - neg, neg);

    // ---- road 3: plane sections ----
    let mut planes: Vec<Vec<usize>> = Vec::new();
    for q in 0..3 { for a in 0..4 {                                     // the planes x_i = a x_j and x_k = a x_l
        planes.push((0..4).map(|b| 16 * q + 4 * a + b).collect());
        planes.push((0..4).map(|b| 16 * q + 4 * b + a).collect());
    } }
    let rows: Vec<Vec<i128>> = planes.iter().map(|pl| (0..n).map(|c| pl.iter().map(|&m| g[m][c]).sum()).collect()).collect();
    let h_sq: i128 = planes[0].iter().map(|&m| rows[0][m]).sum();
    let mut distinct = rows.clone(); distinct.sort(); distinct.dedup();
    let mut hl = rows[0].clone(); hl.sort(); hl.dedup();
    println!("road 3, the plane class h as four coplanar lines");
    println!("planes holding four lines: {}; distinct rows h.L among them: {}", planes.len(), distinct.len());
    println!("h.L for every line: {:?}; h^2 = 4 x (-2) + 2 x 6 = {}", hl, h_sq);

    // ---- what breaks ----
    let wrong: Vec<Vec<i128>> = (0..n).map(|r| (0..n).map(|c| if r == c { 1 } else { g[r][c] }).collect()).collect();
    let (kd, kp): (i64, i64) = (125, 5);
    let wrong_rank = bareiss(&wrong).0;
    println!("mistake 1, a line meets itself once, as in the plane: rank {}, more than b2 = {}", wrong_rank, b2);
    println!("mistake 2, every rational class in H^2 algebraic: {} claimed, rho = {} here", b2, basis.len());
    println!("mistake 3, every (1,1) class algebraic: h^1,1 = {} claimed, rho = 1 for a very general quartic (quoted)", h11);
    println!("mistake 4, integer coefficients: degree {} threefold, {}^3 divides {}: {}; class l of degree 1, curve degrees multiples of {} (quoted); h^2 = {} l, so l = h^2/{} over Q only",
             kd, kp, kd, if kd % kp.pow(3) == 0 { "yes" } else { "no" }, kp, kd, kd);
    assert!((h20, h11, h02) == (1, 20, 1) && h20 + h11 + h02 == b2);           // road 1 against the Euler number
    assert!(2 + 2 * h20 - h11 == sig && (b2 + sig) / 2 == 2 * h20 + 1);       // road 1 against the signature
    assert!(rank48 == basis.len() && basis.len() as i64 == h11 && h11 == 20);  // road 2 meets road 1: rho = 20
    assert!(meets == vec![14]);                                                // every line meets the same 14 others
    assert!(*minors.last().unwrap() == -64 && neg == 19);                      // Hodge index: one positive direction
    assert!(distinct.len() == 1 && hl == vec![1] && h_sq == 4);
    assert!(wrong_rank as i64 > b2);                                           // mistake 1: the wrong form is impossible
    println!("ALL CHECKS PASS");
}
