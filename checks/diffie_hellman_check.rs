// Diffie-Hellman -- the same check as the Python twin, in Rust.  No crates.  A group
// chat everyone can read: clock 23, base 5.  Mia keeps 6 to herself, Ray keeps 15.
const P: i64 = 23;  const G: i64 = 5;
const MIA: u32 = 6;  const RAY: u32 = 15;
fn stepwise(base: i64, count: u32, p: i64) -> i64 {   // the plain way: multiply, drop whole clocks
    let mut out = 1;
    for _ in 0..count { out = out * base % p; }
    out
}
fn squaring(base: i64, count: u32, p: i64) -> i64 {   // road two: square and multiply, same answer
    let (mut out, mut b, mut c) = (1, base % p, count);
    while c > 0 {
        if c % 2 == 1 { out = out * b % p; }
        b = b * b % p;  c /= 2;
    }
    out
}
fn main() {
    let (pm, pr) = (stepwise(G, MIA, P), stepwise(G, RAY, P));
    let (sm, sr) = (stepwise(pr, MIA, P), stepwise(pm, RAY, P));
    let both = stepwise(G, MIA * RAY, P);
    let counts: Vec<u32> = (1..P as u32).filter(|&c| stepwise(G, c, P) == pm).collect();
    let two = stepwise(stepwise(2, RAY, P), MIA, P);
    let mut reach: Vec<i64> = (1..P as u32).map(|c| stepwise(2, c, P)).collect();
    reach.sort(); reach.dedup();
    println!("clock {} and base {} are public; Mia keeps {}, Ray keeps {}, and neither is ever posted", P, G, MIA, RAY);
    println!("Mia posts {} multiplied out {} times: {} = {} x {} + {}", G, MIA, G.pow(MIA), G.pow(MIA) / P, P, pm);
    println!("Ray posts {} multiplied out {} times: {} = {} x {} + {}", G, RAY, G.pow(RAY), G.pow(RAY) / P, P, pr);
    println!("Mia multiplies Ray's {} out {} times: {} = {} x {} + {}; Ray multiplies Mia's {} out {} times: {}", pr, MIA, pr.pow(MIA), pr.pow(MIA) / P, P, sm, pm, RAY, sr);
    println!("both are {} multiplied out {} times on the {} clock: {}", G, MIA * RAY, P, both);
    println!("by squaring instead of stepping: {}, {}, {}", squaring(G, MIA, P), squaring(G, RAY, P), squaring(pr, MIA, P));
    println!("a listener has {}, {}, {}, {}; every count 1 to {} tried against {} gives {:?}", P, G, pm, pr, P - 1, pm, counts);
    println!("count {} would give {}, not {}: a near miss tells you nothing", MIA + 1, stepwise(G, MIA + 1, P), pm);
    println!("mistakes: {} x {} lands on {}; base 2 shares {} and reaches only {} values", pm, pr, pm * pr % P, two, reach.len());
    assert!(pm == 8 && pr == 19 && sm == 2 && sm == sr && both == 2);
    assert!(squaring(G, MIA, P) == pm && squaring(G, RAY, P) == pr && squaring(pr, MIA, P) == sm && squaring(G, MIA * RAY, P) == 2);
    assert!(counts == vec![MIA] && stepwise(G, MIA + 1, P) == 17 && pm * pr % P == 14 && two == 4 && reach.len() == 11);
    println!("ALL CHECKS PASS");
}
