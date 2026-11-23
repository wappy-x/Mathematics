-- Communication complexity: deciding for sure whether two n-bit lists match takes exactly n + 1 bits, a random prime fingerprint is fooled by fewer than n primes, and an exact one-pass match checker needs at least n bits of memory.
import Mathlib.NumberTheory.PrimeCounting
import Mathlib.NumberTheory.Primorial
import Mathlib.Tactic.NormNum.Prime

/-! ## The model

Leeds holds `x : X`, Bristol holds `y : Y`. A deterministic protocol is a tree. At a leaf
both parties know the answer. At an `alice` node Leeds sends one bit computed from `x` alone;
at a `bob` node Bristol sends one bit computed from `y` alone. The bit picks the subtree:
`false` the first, `true` the second. Local work is free; only bits sent are counted. -/

/-- A deterministic two-party protocol with Leeds's inputs `X` and Bristol's inputs `Y`. -/
inductive Protocol (X Y : Type) where
  | leaf : Bool → Protocol X Y
  | alice : (X → Bool) → Protocol X Y → Protocol X Y → Protocol X Y
  | bob : (Y → Bool) → Protocol X Y → Protocol X Y → Protocol X Y

namespace Protocol

variable {X Y : Type}

/-- The answer the protocol gives on the input pair `(x, y)`. -/
def eval : Protocol X Y → X → Y → Bool
  | leaf b, _, _ => b
  | alice f p q, x, y => if f x then q.eval x y else p.eval x y
  | bob g p q, x, y => if g y then q.eval x y else p.eval x y

/-- The cost of a protocol: the number of bits sent on the worst input pair, that is, the
depth of its tree. -/
def cost : Protocol X Y → ℕ
  | leaf _ => 0
  | alice _ p q => max p.cost q.cost + 1
  | bob _ p q => max p.cost q.cost + 1

end Protocol

/-- `D(f)`: the deterministic communication complexity of `f`, the least cost of a protocol
that is right on every input pair. -/
noncomputable def detCC {X Y : Type} (f : X → Y → Bool) : ℕ :=
  sInf {c | ∃ P : Protocol X Y, (∀ x y, P.eval x y = f x y) ∧ P.cost = c}

/-- EQUALITY on `n`-bit lists: `EQ(x, y) = 1` when `x = y`, else 0. -/
def eqFun (n : ℕ) (x y : Fin n → Bool) : Bool := decide (x = y)


/-! ## Helper definitions and lemmas for the proofs -/

namespace Protocol

variable {X Y : Type}

/-- A number below `2 ^ cost` naming the leaf that the input pair `(x, y)` reaches. -/
def code : Protocol X Y → X → Y → ℕ
  | leaf _, _, _ => 0
  | alice f p q, x, y => if f x then 2 ^ max p.cost q.cost + q.code x y else p.code x y
  | bob g p q, x, y => if g y then 2 ^ max p.cost q.cost + q.code x y else p.code x y

end Protocol

theorem Protocol.code_lt {X Y : Type} (P : Protocol X Y) (x : X) (y : Y) : P.code x y < 2 ^ P.cost := by
  induction P with
  | leaf b => simp [code, cost]
  | alice f p q ihp ihq =>
    have hp : 2 ^ p.cost ≤ 2 ^ max p.cost q.cost := Nat.pow_le_pow_right (by norm_num) (le_max_left _ _)
    have hq : 2 ^ q.cost ≤ 2 ^ max p.cost q.cost := Nat.pow_le_pow_right (by norm_num) (le_max_right _ _)
    simp only [code, cost, pow_succ]
    split_ifs <;> omega
  | bob g p q ihp ihq =>
    have hp : 2 ^ p.cost ≤ 2 ^ max p.cost q.cost := Nat.pow_le_pow_right (by norm_num) (le_max_left _ _)
    have hq : 2 ^ q.cost ≤ 2 ^ max p.cost q.cost := Nat.pow_le_pow_right (by norm_num) (le_max_right _ _)
    simp only [code, cost, pow_succ]
    split_ifs <;> omega

/-- Two input pairs that reach the same leaf get the same answer, and the crossed pair
reaches that leaf too. -/
theorem Protocol.code_rect {X Y : Type} (P : Protocol X Y) (a a' : X) (b b' : Y) (h : P.code a b = P.code a' b') :
    P.eval a b = P.eval a' b' ∧ P.code a b' = P.code a b := by
  induction P with
  | leaf c => simp [eval, code]
  | alice f p q ihp ihq =>
    have hp := p.code_lt
    have hq := q.code_lt
    have hp' : 2 ^ p.cost ≤ 2 ^ max p.cost q.cost := Nat.pow_le_pow_right (by norm_num) (le_max_left _ _)
    simp only [code] at h
    simp only [eval, code]
    by_cases ha : f a = true <;> by_cases ha' : f a' = true <;> simp only [ha, ha', ite_true, ite_false, Bool.false_eq_true] at h ⊢
    · have e := ihq (by omega); exact ⟨e.1, by rw [e.2]⟩
    · have := hp a' b'; omega
    · have := hp a b; omega
    · exact ihp h
  | bob g p q ihp ihq =>
    have hp := p.code_lt
    have hq := q.code_lt
    have hp' : 2 ^ p.cost ≤ 2 ^ max p.cost q.cost := Nat.pow_le_pow_right (by norm_num) (le_max_left _ _)
    simp only [code] at h
    simp only [eval, code]
    by_cases hb : g b = true <;> by_cases hb' : g b' = true <;> simp only [hb, hb', ite_true, ite_false, Bool.false_eq_true] at h ⊢
    · have e := ihq (by omega); exact ⟨e.1, by rw [e.2]⟩
    · have := hp a' b'; omega
    · have := hp a b; omega
    · exact ihp h


/-- Leeds sends the bits of `x` at positions below `m` one at a time; then Bristol, who now
knows all of `x` (the guess `acc` is right at every position from `m` on), replies with one
bit saying whether `y = x`. -/
def sendAll (n : ℕ) : ℕ → (Fin n → Bool) → Protocol (Fin n → Bool) (Fin n → Bool)
  | 0, acc => .bob (fun y => decide (y = acc)) (.leaf false) (.leaf true)
  | m + 1, acc =>
    .alice (fun x => if h : m < n then x ⟨m, h⟩ else false)
      (sendAll n m (fun i => if i.val = m then false else acc i))
      (sendAll n m (fun i => if i.val = m then true else acc i))

theorem sendAll_cost (n m : ℕ) (acc : Fin n → Bool) : (sendAll n m acc).cost = m + 1 := by
  induction m generalizing acc with
  | zero => simp [sendAll, Protocol.cost]
  | succ m ih => simp [sendAll, Protocol.cost, ih]

theorem sendAll_eval (n m : ℕ) (hm : m ≤ n) (acc : Fin n → Bool) (x y : Fin n → Bool)
    (hacc : ∀ i : Fin n, m ≤ i.val → acc i = x i) : (sendAll n m acc).eval x y = eqFun n x y := by
  induction m generalizing acc with
  | zero =>
    have : acc = x := funext fun i => hacc i (Nat.zero_le _)
    subst this
    by_cases h : y = acc <;> simp [sendAll, Protocol.eval, eqFun, h, eq_comm]
  | succ m ih =>
    have hmn : m < n := hm
    simp only [sendAll, Protocol.eval, hmn, dite_true]
    split_ifs with hx
    · apply ih (by omega)
      intro i hi
      by_cases him : i.val = m
      · have : i = ⟨m, hmn⟩ := Fin.ext him
        subst this; simp [hx]
      · simp only [him, ite_false]; exact hacc i (by omega)
    · apply ih (by omega)
      intro i hi
      by_cases him : i.val = m
      · have : i = ⟨m, hmn⟩ := Fin.ext him
        subst this; simp at hx; simp [hx]
      · simp only [him, ite_false]; exact hacc i (by omega)

theorem eq_protocol_cost_ge (n : ℕ) (hn : 0 < n) (P : Protocol (Fin n → Bool) (Fin n → Bool))
    (hP : ∀ x y, P.eval x y = eqFun n x y) : n + 1 ≤ P.cost := by
  let x0 : Fin n → Bool := fun _ => false
  let y0 : Fin n → Bool := fun _ => true
  have hne : x0 ≠ y0 := by
    intro h
    have := congrFun h ⟨0, hn⟩
    simp [x0, y0] at this
  let g : Option (Fin n → Bool) → Fin (2 ^ P.cost) := fun o =>
    match o with
    | none => ⟨P.code x0 y0, P.code_lt _ _⟩
    | some x => ⟨P.code x x, P.code_lt _ _⟩
  have hdiag : ∀ x x', P.code x x = P.code x' x' → x = x' := by
    intro x x' h
    have h2 := (P.code_rect x x' x x' h).2
    have h4 := (P.code_rect x x x x' h2.symm).1
    rw [hP, hP] at h4
    simpa [eqFun] using h4.symm
  have hoff : ∀ z, P.code x0 y0 ≠ P.code z z := by
    intro z h
    have h1 := (P.code_rect x0 z y0 z h).1
    have hz : P.code x0 z = P.code z z := (P.code_rect x0 z y0 z h).2.trans h
    have hz' := (P.code_rect x0 z z z hz).1
    rw [hP, hP] at hz' h1
    have hx0z : x0 = z := by simpa [eqFun] using hz'
    subst hx0z
    simp [eqFun, hne] at h1
  have hinj : Function.Injective g := by
    intro o o' h
    cases o with
    | none =>
      cases o' with
      | none => rfl
      | some z => exact absurd (Fin.mk.inj_iff.mp h) (hoff z)
    | some x =>
      cases o' with
      | none => exact absurd (Fin.mk.inj_iff.mp h).symm (hoff x)
      | some z => exact congrArg some (hdiag x z (Fin.mk.inj_iff.mp h))
  have hcard := Fintype.card_le_of_injective g hinj
  simp only [Fintype.card_option, Fintype.card_fun, Fintype.card_bool, Fintype.card_fin] at hcard
  have : 2 ^ n < 2 ^ P.cost := by omega
  have := (Nat.pow_lt_pow_iff_right (by norm_num : 1 < 2)).mp this
  omega

/-! ## The card's three theorems -/

/-- The exact cost of EQUALITY: to settle for sure whether two `n`-bit lists match,
`n + 1` bits must cross, and sending the whole list plus a one-bit reply achieves it:
`D(EQ_n) = n + 1`. The lists have at least one bit (`0 < n`); with empty lists every pair
matches and no bit need cross. -/
theorem detCC_equality_eq_succ (n : ℕ) (hn : 0 < n) : detCC (eqFun n) = n + 1 := by
  have hmem : n + 1 ∈ {c | ∃ P : Protocol (Fin n → Bool) (Fin n → Bool),
      (∀ x y, P.eval x y = eqFun n x y) ∧ P.cost = c} :=
    ⟨sendAll n n (fun _ => false), fun x y => sendAll_eval n n le_rfl _ x y
      (fun i hi => absurd i.isLt (by omega)), sendAll_cost n n _⟩
  unfold detCC
  apply le_antisymm (Nat.sInf_le hmem)
  apply le_csInf ⟨_, hmem⟩
  rintro c ⟨P, hP, rfl⟩
  exact eq_protocol_cost_ge n hn P hP

/-- The prime fingerprint's error. Read two different lists as whole numbers `x ≠ y` below
`2^n`. Leeds picks a prime `p` below `n^2` and the check passes when `x mod p = y mod p`.
Fewer than `n` primes fool the check, so with the prime drawn evenly from the `π(n^2)`
primes below `n^2`, two different lists pass with chance at most `n / π(n^2)`. -/
theorem fingerprint_fooled_by_fewer_than_n_primes (n x y : ℕ)
    (hx : x < 2 ^ n) (hy : y < 2 ^ n) (hxy : x ≠ y) :
    ((Finset.range (n ^ 2)).filter (fun p => p.Prime ∧ x % p = y % p)).card < n ∧
      (((Finset.range (n ^ 2)).filter (fun p => p.Prime ∧ x % p = y % p)).card : ℚ) /
          Nat.primeCounting' (n ^ 2) ≤ (n : ℚ) / Nat.primeCounting' (n ^ 2) := by
  set S := (Finset.range (n ^ 2)).filter (fun p => p.Prime ∧ x % p = y % p) with hS
  set d := ((y : ℤ) - x).natAbs with hd
  have hd0 : 0 < d := by omega
  have hdlt : d < 2 ^ n := by omega
  have hdvd : ∀ p ∈ S, p ∣ d := by
    intro p hp
    rw [hS, Finset.mem_filter] at hp
    have : (p : ℤ) ∣ (y : ℤ) - x := Nat.ModEq.dvd hp.2.2
    exact Int.natCast_dvd.mp this
  have hprod : (∏ p ∈ S, p) ∣ d :=
    Finset.prod_primes_dvd d (fun p hp => (Finset.mem_filter.mp hp).2.1.prime) hdvd
  have hle : 2 ^ S.card ≤ ∏ p ∈ S, p :=
    Finset.pow_card_le_prod _ _ _ (fun p hp => (Finset.mem_filter.mp hp).2.1.two_le)
  have hlt : 2 ^ S.card < 2 ^ n := lt_of_le_of_lt (hle.trans (Nat.le_of_dvd hd0 hprod)) hdlt
  have hc : S.card < n := (Nat.pow_lt_pow_iff_right (by norm_num : 1 < 2)).mp hlt
  refine ⟨hc, ?_⟩
  apply div_le_div_of_nonneg_right _ (by positivity)
  exact_mod_cast hc.le

/-- Memory is communication. A program that reads Leeds's list `x` and then Bristol's list
`y` in one pass keeps `s` bits of memory at the join: a state `mem x` that depends on `x`
alone, after which its answer depends only on that state and `y`. If it decides EQUALITY
exactly, then `s ≥ n`. -/
theorem one_pass_equality_memory_ge (n s : ℕ) (mem : (Fin n → Bool) → (Fin s → Bool))
    (finish : (Fin s → Bool) → (Fin n → Bool) → Bool)
    (h : ∀ x y, finish (mem x) y = eqFun n x y) : n ≤ s := by
  have hinj : Function.Injective mem := by
    intro x x' hx
    have h1 := h x x'
    rw [hx, h x' x'] at h1
    simpa [eqFun] using h1.symm
  have hcard := Fintype.card_le_of_injective mem hinj
  simp only [Fintype.card_fun, Fintype.card_bool, Fintype.card_fin] at hcard
  exact (Nat.pow_le_pow_iff_right (by norm_num : 1 < 2)).mp hcard

/-! ## The card's worked numbers -/

-- Warehouses, n = 1,000: the exact protocol sends 1,000 bits plus a 1-bit reply.
example : 1000 + 1 = 1001 := by norm_num

-- A prime or a remainder below a million needs 20 bits: 2^19 < 10^6 ≤ 2^20.
example : 2 ^ 19 < 10 ^ 6 ∧ 10 ^ 6 ≤ 2 ^ 20 := by norm_num

-- The fingerprint costs 20 + 20 + 1 = 41 bits.
example : 20 + 20 + 1 = 41 := by norm_num

-- Larger catalogues: 2^39 < 10^12 ≤ 2^40 gives 81 bits; 2^59 < 10^18 ≤ 2^60 gives 121 bits.
example : 2 ^ 39 < 10 ^ 12 ∧ 10 ^ 12 ≤ 2 ^ 40 ∧ 2 * 40 + 1 = 81 := by norm_num
example : 2 ^ 59 < 10 ^ 18 ∧ 10 ^ 18 ≤ 2 ^ 60 ∧ 2 * 60 + 1 = 121 := by norm_num

-- The worst lists: the product of the primes up to 727 fits below 2^1000, and one more
-- prime factor, 733, passes 2^1000.
example : primorial 727 < 2 ^ 1000 := by decide +kernel
example : Nat.Prime 733 ∧ 2 ^ 1000 ≤ 733 * primorial 727 := by
  refine ⟨by norm_num, by decide +kernel⟩

-- There are 129 primes from 2 to 727.
example : Nat.primeCounting' 728 = 129 := by decide +kernel

-- Lists that differ in one product differ by a power of 2, so only the prime 2 divides the gap.
example (k : ℕ) (hk : k ≠ 0) : Nat.primeFactors (2 ^ k) = {2} :=
  Nat.primeFactors_prime_pow hk Nat.prime_two

-- What breaks: a fixed prime, 999,983. Lists 999,983 apart leave the same remainder.
example : Nat.Prime 999983 := by norm_num
example (y : ℕ) : (y + 999983) % 999983 = y % 999983 := Nat.add_mod_right y 999983

-- What breaks: primes below 100 only. There are 25 of them.
example : Nat.primeCounting' 100 = 25 := by decide +kernel

-- What breaks: a 9-bit memory on 10-bit lists: 1,024 lists against 512 states.
example : 2 ^ 10 = 1024 ∧ 2 ^ 9 = 512 ∧ 2 ^ 9 < 2 ^ 10 := by norm_num

#print axioms Protocol.code_lt
#print axioms Protocol.code_rect
#print axioms sendAll_cost
#print axioms sendAll_eval
#print axioms eq_protocol_cost_ge
#print axioms detCC_equality_eq_succ
#print axioms fingerprint_fooled_by_fewer_than_n_primes
#print axioms one_pass_equality_memory_ge
