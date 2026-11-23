// The status register -- the check behind the card.  Rust std only, no crates.
// The register is data typed in twice: the rows, and a dated log of changes.
// Roads: status rule vs rows, log replay vs rows, two day counts, small cases.
use std::collections::BTreeMap;
use std::ops::{Add, Mul, Sub};

const TODAY: &str = "2026-11-23";
const SNAP: &str = "2026-09-13";
const ROWS: &str = "RH C p P I  BSD C o - -  PNP C o - -  NS C c D A  HODGE C o - -  YM C o - -
POINC C p P I  TWIN C o - -  GOLD C o - -  LEG C o - -  NSQ C o - -  ABC C c P X
BEAL C o - -  FLT C p P I  DIST C o - -  UNIT C r D I  KAK3 C p P I  KAKN C o - -
HN C o - -  CDC C c P A  ER C o - -  ES C c P A  UC C o - -  SP8 C p P I  SP24 C p P I
COLL C o - -  Z23 T c P A  JAC3 C r D I  JAC2 C o - -  SOFIC C c D A  KOTHE C c D A
PERC C c P A  IGP C o - -  M23 C c P A  CH T p P I  UGC C o - -  GI T p P I
BQP C o - -  ROUGH M o - -  OT T p P I  GEN C o - -  DDES C o - -  MF T p P I  SGD C o - -";
const LOG: &str = "1963-12 CH o p|1991-06 OT o p|1993-06 FLT o c|1995-05 FLT c p
2002-11-11 POINC o c|2006-07-25 POINC c p|2012-08 ABC o c|2015-12-11 GI o c
2016-03-14 SP8 o c|2016-03-21 SP24 o c|2016-06-19 GI c p|2017-01-04 GI p o
2017-01-09 GI o c|2017-01-16 GI c p|2017-05-01 SP8 c p|2017-05-01 SP24 c p
2018-04-18 MF o c|2018-07-27 MF c p|2025-02-24 KAK3 o c|2026-05-20 UNIT o r
2026-07-10 CDC o c|2026-07-20 JAC3 o r|2026-07-23 KAK3 c p|2026-08-01 SOFIC o c
2026-08-09 M23 o c|2026-08-10 Z23 o c|2026-08-28 PERC o c|2026-09-07 KOTHE o c
2026-09-08 NS o c|2026-10-19 ES o c|2026-11-21 RH o p";

fn name(s: &str) -> &str { match s { "o" => "open", "c" => "claimed", "p" => "proved", _ => "refuted" } }
fn rule(claim: &str, accept: &str) -> &'static str {
    if claim == "-" { "o" } else if accept == "I" { if claim == "P" { "p" } else { "r" } } else { "c" }
}
type Row<'a> = (&'a str, &'a str, &'a str, &'a str, &'a str);
fn replay<'a>(rows: &[Row<'a>], log: &[Vec<&'a str>], upto: &str, mono: bool) -> BTreeMap<&'a str, &'a str> {
    let mut st: BTreeMap<&str, &str> = rows.iter().map(|r| (r.0, "o")).collect();
    let mut sorted: Vec<&Vec<&str>> = log.iter().collect();
    sorted.sort_by(|a, b| a[0].cmp(b[0]));
    let rank = |s: &str| "ocpr".find(s).unwrap();
    for e in sorted {
        if e[0] > &upto[..e[0].len()] { continue; }
        if mono { if rank(e[3]) < rank(st[e[1]]) { continue; } }
        else { assert_eq!(st[e[1]], e[2], "{} {}", e[0], e[1]); }
        st.insert(e[1], e[3]);
    }
    st
}
fn ymd(s: &str) -> (i64, i64, i64) { let v: Vec<i64> = s.split('-').map(|t| t.parse().unwrap()).collect(); (v[0], v[1], v[2]) }
fn days(s: &str) -> i64 {
    let (y0, m, d) = ymd(s); let y = y0 - (m <= 2) as i64;
    let era = y.div_euclid(400); let yoe = y - era * 400;
    let doy = (153 * (m + if m > 2 { -3 } else { 9 }) + 2) / 5 + d - 1;
    era * 146097 + yoe * 365 + yoe / 4 - yoe / 100 + doy - 719468
}
fn leap(t: i64) -> bool { t % 4 == 0 && (t % 100 != 0 || t % 400 == 0) }
fn days_loop(s: &str) -> i64 {
    let (y, m, d) = ymd(s); let mut n = 0;
    for t in 1970..y { n += if leap(t) { 366 } else { 365 }; }
    let ml = [31, if leap(y) { 29 } else { 28 }, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    for t in 1..m { n += ml[(t - 1) as usize]; }
    n + d - 1
}
fn date(n: i64) -> String {
    let mut y = 1970 + n / 366;
    while days(&format!("{}-01-01", y + 1)) <= n { y += 1; }
    let mut m = 1;
    while m < 12 && days(&format!("{}-{:02}-01", y, m + 1)) <= n { m += 1; }
    format!("{}-{:02}-{:02}", y, m, n - days(&format!("{}-{:02}-01", y, m)) + 1)
}
#[derive(Clone, Copy, PartialEq, Debug)]
struct Q(i128, i128);
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d) * d.signum(); Q(n / g, d / g) }
impl Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.0 * o.1 + o.0 * self.1, self.1 * o.1) } }
impl Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { q(self.0 * o.1 - o.0 * self.1, self.1 * o.1) } }
impl Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.0 * o.0, self.1 * o.1) } }
trait Num: Copy + Add<Output = Self> + Sub<Output = Self> + Mul<Output = Self> { fn k(n: i64) -> Self; }
impl Num for Q { fn k(n: i64) -> Q { Q(n as i128, 1) } }
impl Num for f64 { fn k(n: i64) -> f64 { n as f64 } }
impl Num for i64 { fn k(n: i64) -> i64 { n } }
fn f<T: Num>(x: T, y: T, z: T) -> [T; 3] {
    let (u, v) = (T::k(1) + x * y, T::k(4) + T::k(3) * x * y);
    [u * u * u * z + y * y * u * v, y + T::k(3) * x * u * u * z + T::k(3) * x * y * y * v,
     T::k(2) * x - T::k(3) * x * x * y - x * x * x * z]
}
fn det3<T: Num>(j: &[[T; 3]; 3]) -> T {
    j[0][0] * (j[1][1] * j[2][2] - j[1][2] * j[2][1]) - j[0][1] * (j[1][0] * j[2][2] - j[1][2] * j[2][0])
        + j[0][2] * (j[1][0] * j[2][1] - j[1][1] * j[2][0])
}
fn jac<T: Num>(x: T, y: T, z: T) -> [[T; 3]; 3] {
    let (u, w, k) = (T::k(1) + x * y, x * y, T::k);
    [[k(3) * u * u * y * z + y * y * y * (k(7) + k(6) * w), k(3) * u * u * x * z + k(2) * y * u * (k(4) + k(3) * w) + x * y * y * (k(7) + k(6) * w), u * u * u],
     [k(3) * u * u * z + k(6) * w * u * z + k(3) * y * y * (k(4) + k(3) * w) + k(9) * x * y * y * y, k(1) + k(6) * x * x * u * z + k(6) * w * (k(4) + k(3) * w) + k(9) * w * w, k(3) * x * u * u],
     [k(2) - k(6) * w - k(3) * x * x * z, k(0) - k(3) * x * x, k(0) - x * x * x]]
}

fn main() {
    let w: Vec<&str> = ROWS.split_whitespace().collect();
    let rows: Vec<Row> = w.chunks(5).map(|c| (c[0], c[1], c[2], c[3], c[4])).collect();
    let log: Vec<Vec<&str>> = LOG.split(|c| c == '|' || c == '\n').map(|e| e.split(' ').collect()).collect();
    println!("register as of {}: {} rows, every row checked {}", TODAY, rows.len(), TODAY);
    assert!(rows.iter().all(|r| rule(r.3, r.4) == r.2), "status rule disagrees with a row");
    let now = replay(&rows, &log, TODAY, false);
    assert!(rows.iter().all(|r| now[r.0] == r.2), "log replay disagrees with the rows");
    let tally = |st: &BTreeMap<&str, &str>| -> Vec<usize> { ["o", "c", "p", "r"].iter().map(|s| st.values().filter(|v| *v == s).count()).collect() };
    let t = tally(&now);
    let t_rows: Vec<usize> = ["o", "c", "p", "r"].iter().map(|s| rows.iter().filter(|r| r.2 == *s).count()).collect();
    assert_eq!(t, t_rows);
    println!("open {}, claimed {}, proved {}, refuted {}", t[0], t[1], t[2], t[3]);
    let kc = |q: &str| rows.iter().filter(|r| r.1 == q).count();
    println!("kinds: conjecture {}, theorem {}, model {}", kc("C"), kc("T"), kc("M"));
    println!("status rule = rows = log replay for all {} rows; log has {} entries", rows.len(), log.len());
    for ch in log.chunks(3) {
        let s: Vec<String> = ch.iter().map(|e| format!("{} {} {}>{}", e[0], e[1], name(e[2]), name(e[3]))).collect();
        println!("log  {}", s.join(" | "));
    }
    let old = replay(&rows, &log, SNAP, false);
    let ch: Vec<String> = rows.iter().filter(|r| old[r.0] != now[r.0]).map(|r| format!("{} {}>{}", r.0, name(old[r.0]), name(now[r.0]))).collect();
    println!("changed between {} and {}: {}", SNAP, TODAY, ch.join(", "));
    for (a, b) in [(SNAP, TODAY), ("2002-11-11", "2006-07-25"), ("2017-01-04", "2017-01-09"), ("2016-03-14", "2017-05-01"), ("2025-02-24", "2026-07-23")] {
        assert_eq!(days(b) - days(a), days_loop(b) - days_loop(a));
        println!("days {} to {}: {}", a, b, days(b) - days(a));
    }
    let (due_c, due_o) = (date(days(TODAY) + 30), date(days(TODAY) + 365));
    assert!(days(&due_o) - days(TODAY) == 365 && date(days("2017-01-09")) == "2017-01-09");
    println!("next recheck: claimed rows {}, all other rows {}", due_c, due_o);
    let yrs: Vec<String> = (1995..2026).step_by(5).map(|y| y.to_string()).collect(); // the chart: replay stopped at each year's end
    let mut snaps: Vec<Vec<usize>> = yrs.iter().map(|y| tally(&replay(&rows, &log, &format!("{}-12-31", y), false))).collect();
    snaps.push(t.clone());
    println!("chart, end of {}, then {}", yrs.join(" "), TODAY);
    println!("chart, claimed {}", snaps.iter().map(|v| v[1].to_string()).collect::<Vec<_>>().join(" "));
    println!("chart, proved or refuted {}", snaps.iter().map(|v| (v[2] + v[3]).to_string()).collect::<Vec<_>>().join(" "));
    // ---- what breaks ----
    let up = rows.iter().filter(|r| "pr".contains(rule(r.3, if "AX".contains(r.4) { "I" } else { r.4 }))).count();
    let abc = rows.iter().filter(|r| rule(r.3, if r.4 == "X" { "I" } else { r.4 }) == "p").count();
    println!("breaks: claims counted as accepted: proved or refuted {} -> {}", t[2] + t[3], up);
    println!("breaks: abc's journal counted, dispute ignored: proved {} -> {}", t[2], abc);
    let (gi, gm) = (replay(&rows, &log, "2017-01-05", false)["GI"], replay(&rows, &log, "2017-01-05", true)["GI"]);
    assert_eq!((gi, gm), ("o", "p"));
    println!("breaks: never downgrade: GI on 2017-01-05 reads {}, true {}", name(gm), name(gi));
    println!("breaks: one 365-day period: claimed rows due {}, {} days late", due_o, days(&due_o) - days(&due_c));
    // ---- a slice of small cases, each 'checked for n <= N', never 'true' ----
    let n_max = 1_000_000usize;
    let mut sv = vec![true; n_max + 1]; sv[0] = false; sv[1] = false;
    for i in 2..=1000 { if sv[i] { let mut j = i * i; while j <= n_max { sv[j] = false; j += i; } } }
    assert!((4..=10000).step_by(2).all(|n| (2..=n / 2).any(|p| sv[p] && sv[n - p])));
    println!("GOLD: every even n with 4 <= n <= 10000 is a sum of two primes: checked");
    let tw = (0..n_max - 1).filter(|&p| sv[p] && sv[p + 2]).count();
    assert_eq!(tw, 8169);
    println!("TWIN: prime pairs p, p + 2 with p + 2 < 10^6: {}", tw);
    let (mut n, mut st, mut top) = (27u64, 0, 27u64);
    while n != 1 { n = if n % 2 == 0 { n / 2 } else { 3 * n + 1 }; st += 1; top = top.max(n); }
    assert_eq!((st, top), (111, 9232));
    println!("COLL: 27 reaches 1 in {} steps, peak {}", st, top);
    let pts = [(q(0, 1), q(0, 1), q(-1, 4)), (q(1, 1), q(-3, 2), q(13, 2)), (q(-1, 1), q(3, 2), q(13, 2))];
    let img: Vec<[Q; 3]> = pts.iter().map(|p| f(p.0, p.1, p.2)).collect();
    assert!(img.iter().all(|v| *v == [q(-1, 4), q(0, 1), q(0, 1)]));
    assert!((-3..4i64).all(|x| (-3..4i64).all(|y| (-3..4i64).all(|z| det3(&jac(x, y, z)) == -2))));
    let (h, p0) = (0.001f64, [0.5f64, -0.25, 0.75]);
    let mut fd = [[0.0f64; 3]; 3];
    for r in 0..3 { for i in 0..3 {
        let (mut a, mut b) = (p0, p0);
        for j in 0..3 { let e = h * if j == i { 1.0 } else { 0.0 }; a[j] = p0[j] + e; b[j] = p0[j] - e; }
        fd[r][i] = (f(a[0], a[1], a[2])[r] - f(b[0], b[1], b[2])[r]) / (2.0 * h);
    } }
    assert!((det3(&fd) + 2.0).abs() < 1e-4 && det3(&jac(q(1, 2), q(-1, 3), q(2, 5))) == q(-2, 1));
    println!("JAC3: (0, 0, -1/4), (1, -3/2, 13/2), (-1, 3/2, 13/2) all map to (-1/4, 0, 0)");
    println!("JAC3: det = -2 at all 343 grid points; by central differences at (0.5, -0.25, 0.75): {:.9}", det3(&fd));
    println!("ALL CHECKS PASS");
}
