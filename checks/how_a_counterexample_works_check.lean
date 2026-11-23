-- Counterexamples: one exactly checked case inside a claim's domain refutes a claim about every case, no run of checked cases up to a bound proves the next case, and 27^5 + 84^5 + 110^5 + 133^5 = 144^5 refutes Euler's sum-of-powers conjecture.
import Mathlib.Data.Nat.Prime.Defs
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Algebra.Group.Nat.Even
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Data.Nat.Choose.Sum
import Mathlib.Tactic.NormNum.Prime
import Mathlib.Tactic.IntervalCases

open Finset

/-! Helpers. A downward and an upward loop over whole numbers that the kernel can run, with
their specifications; a trial-division prime test with a proof that it agrees with
`Nat.Prime`; and the search behind the table-lookup claim for fifth powers. -/

/-- Check `f k` for k = n, n - 1, …, 0, stopping (with success) at the first k where `stop k`. -/
def loopDown (stop f : ℕ → Bool) : ℕ → Bool
  | 0 => stop 0 || f 0
  | n + 1 => stop (n + 1) || (f (n + 1) && loopDown stop f n)

theorem loopDown_spec (stop f : ℕ → Bool) : ∀ n, loopDown stop f n = true →
    ∀ k ≤ n, (∀ j, k ≤ j → j ≤ n → stop j = false) → f k = true
  | 0 => by
    intro h k hk hs
    obtain rfl : k = 0 := by omega
    simpa [loopDown, hs 0 le_rfl le_rfl] using h
  | n + 1 => by
    intro h k hk hs
    simp only [loopDown, Bool.or_eq_true, Bool.and_eq_true] at h
    rcases h with h | ⟨h1, h2⟩
    · rw [hs (n + 1) hk le_rfl] at h; exact absurd h (by simp)
    · rcases Nat.lt_or_ge k (n + 1) with hlt | hge
      · exact loopDown_spec stop f n h2 k (by omega) (fun j hj1 hj2 => hs j hj1 (by omega))
      · obtain rfl : k = n + 1 := by omega
        exact h1

/-- Check `f k` for k = m, m + 1, …, stopping (with success) at the first k where `stop k`;
after `fuel` steps without stopping it answers false. -/
def loopUp (stop f : ℕ → Bool) : ℕ → ℕ → Bool
  | _, 0 => false
  | m, fuel + 1 => stop m || (f m && loopUp stop f (m + 1) fuel)

theorem loopUp_sound (stop f : ℕ → Bool) : ∀ fuel m, loopUp stop f m fuel = true →
    ∀ k, m ≤ k → (∀ j, m ≤ j → j ≤ k → stop j = false) → f k = true
  | 0 => by intro m h; simp [loopUp] at h
  | fuel + 1 => by
    intro m h k hk hs
    simp only [loopUp, Bool.or_eq_true, Bool.and_eq_true] at h
    rcases h with h | ⟨h1, h2⟩
    · rw [hs m le_rfl hk] at h; exact absurd h (by simp)
    · rcases Nat.lt_or_ge m k with hlt | hge
      · exact loopUp_sound stop f fuel (m + 1) h2 k hlt (fun j hj1 hj2 => hs j (by omega) hj2)
      · obtain rfl : k = m := by omega
        exact h1

theorem loopUp_complete (stop f : ℕ → Bool) : ∀ fuel m,
    (∀ j, m ≤ j → j < m + fuel → stop j = false → f j = true) →
    (∃ j, m ≤ j ∧ j < m + fuel ∧ stop j = true) → loopUp stop f m fuel = true
  | 0 => by
    intro m _ ⟨j, hj1, hj2, _⟩; omega
  | fuel + 1 => by
    intro m hf ⟨j, hj1, hj2, hj3⟩
    simp only [loopUp, Bool.or_eq_true, Bool.and_eq_true]
    cases hm : stop m
    · right
      refine ⟨hf m le_rfl (by omega) hm, ?_⟩
      apply loopUp_complete stop f fuel (m + 1) (fun i hi1 hi2 => hf i (by omega) (by omega))
      refine ⟨j, ?_, by omega, hj3⟩
      rcases Nat.lt_or_ge m j with h | h
      · omega
      · obtain rfl : j = m := by omega
        rw [hm] at hj3; exact absurd hj3 (by simp)
    · left; rfl

/-- Trial division by 2, 3, 4, … while the divisor's square is at most n. -/
def primeB (n : ℕ) : Bool :=
  decide (2 ≤ n) && loopUp (fun k => decide (n < k * k)) (fun k => n % k != 0) 2 n

theorem primeB_iff (n : ℕ) : primeB n = true ↔ Nat.Prime n := by
  unfold primeB
  simp only [Bool.and_eq_true, decide_eq_true_eq]
  constructor
  · rintro ⟨h2, hl⟩
    by_contra hnp
    have hp := Nat.minFac_prime (show n ≠ 1 by omega)
    have hsq := Nat.minFac_sq_le_self (by omega) hnp
    have key := loopUp_sound _ _ n 2 hl (Nat.minFac n) hp.two_le (fun j _ hj2 => by
      simp only [decide_eq_false_iff_not, not_lt]
      calc j * j ≤ n.minFac * n.minFac := Nat.mul_le_mul hj2 hj2
        _ = n.minFac ^ 2 := (sq _).symm
        _ ≤ n := hsq)
    simp [Nat.mod_eq_zero_of_dvd (Nat.minFac_dvd n)] at key
  · intro hp
    have h2 := hp.two_le
    refine ⟨h2, loopUp_complete _ _ n 2 ?_ ⟨n, h2, by omega, by simp; nlinarith⟩⟩
    intro j hj1 _ hj3
    simp only [decide_eq_false_iff_not, not_lt] at hj3
    simp only [bne_iff_ne, ne_eq]
    intro hmod
    rcases hp.eq_one_or_self_of_dvd j (Nat.dvd_of_mod_eq_zero hmod) with h | h
    · omega
    · subst h; nlinarith

theorem oddComposite_iff (n : ℕ) :
    (Odd n ∧ ¬ Nat.Prime n) ↔ (n % 2 = 1 ∧ primeB n = false) := by
  rw [Nat.odd_iff, ← primeB_iff]; simp

/-- Is n a prime plus twice a nonzero square? Tries k = 1, 2, … in turn. -/
def pptsB (n : ℕ) : Bool :=
  (List.range' 1 n).any (fun k => decide (2 * k ^ 2 < n) && primeB (n - 2 * k ^ 2))

theorem pptsB_iff (n : ℕ) :
    pptsB n = true ↔ ∃ k ∈ Finset.Icc 1 n, 2 * k ^ 2 < n ∧ Nat.Prime (n - 2 * k ^ 2) := by
  simp only [pptsB, List.any_eq_true, List.mem_range'_1, Finset.mem_Icc, Bool.and_eq_true,
    decide_eq_true_eq, primeB_iff]
  constructor <;> rintro ⟨k, hk, h⟩ <;> exact ⟨k, by omega, h⟩

/-- The whole-number fifth root of R, for R below 256^5, by fixing one binary digit at a time. -/
def root5 (R : ℕ) : ℕ :=
  let step (r bit : ℕ) : ℕ := if (r + bit) ^ 5 ≤ R then r + bit else r
  step (step (step (step (step (step (step (step 0 128) 64) 32) 16) 8) 4) 2) 1

theorem root5_pow : ∀ a < 151, root5 (a ^ 5) = a := by decide +kernel

/-- Bit `R % p` of the mask m: a table of which remainders mod p are allowed. -/
def inMask (m p R : ℕ) : Bool := (m >>> (R % p)) % 2 == 1

/-- R leaves a remainder that a fifth power can leave, mod 11, 25, 31 and 61. -/
def fifthOK (R : ℕ) : Bool :=
  inMask 1027 11 R && inMask 17039491 25 R && inMask 1174405219 31 R &&
    inMask 1154470721324345347 61 R

/-- R leaves a remainder that a sum of two fifth powers can leave, mod 11, 25, 31 and 61. -/
def twoFifthOK (R : ℕ) : Bool :=
  inMask 1543 11 R && inMask 26102215 25 R && inMask 1865948407 31 R &&
    inMask 2049119963381104015 61 R

theorem inMask_pow {m p : ℕ} (hp : 0 < p) (H : ∀ i < p, inMask m p (i ^ 5) = true) (x : ℕ) :
    inMask m p (x ^ 5) = true := by
  have h := H (x % p) (Nat.mod_lt _ hp)
  unfold inMask at h ⊢
  rwa [Nat.pow_mod]

theorem inMask_sum {m p : ℕ} (hp : 0 < p)
    (H : ∀ i < p, ∀ j < p, inMask m p (i ^ 5 + j ^ 5) = true) (x y : ℕ) :
    inMask m p (x ^ 5 + y ^ 5) = true := by
  have h := H (x % p) (Nat.mod_lt _ hp) (y % p) (Nat.mod_lt _ hp)
  unfold inMask at h ⊢
  rwa [Nat.add_mod, Nat.pow_mod x, Nat.pow_mod y, ← Nat.add_mod]

theorem fifthOK_pow (x : ℕ) : fifthOK (x ^ 5) = true := by
  have h1 := inMask_pow (m := 1027) (p := 11) (by decide) (by decide +kernel) x
  have h2 := inMask_pow (m := 17039491) (p := 25) (by decide) (by decide +kernel) x
  have h3 := inMask_pow (m := 1174405219) (p := 31) (by decide) (by decide +kernel) x
  have h4 := inMask_pow (m := 1154470721324345347) (p := 61) (by decide) (by decide +kernel) x
  simp only [fifthOK, h1, h2, h3, h4, Bool.and_self]

theorem twoFifthOK_sum (x y : ℕ) : twoFifthOK (x ^ 5 + y ^ 5) = true := by
  have h1 := inMask_sum (m := 1543) (p := 11) (by decide) (by decide +kernel) x y
  have h2 := inMask_sum (m := 26102215) (p := 25) (by decide) (by decide +kernel) x y
  have h3 := inMask_sum (m := 1865948407) (p := 31) (by decide) (by decide +kernel) x y
  have h4 := inMask_sum (m := 2049119963381104015) (p := 61) (by decide) (by decide +kernel) x y
  simp only [twoFifthOK, h1, h2, h3, h4, Bool.and_self]

/-- Last step of the search: is R3 = a^5 for some a, and if so is it the known witness? -/
def checkB (e d c b R3 : ℕ) : Bool :=
  !fifthOK R3 ||
  (let a := root5 R3
   (a ^ 5 != R3) || (a == 27 && b == 84 && c == 110 && d == 133 && e == 144))

/-- For fixed e, d, c with R1 = e^5 − d^5: try every b ≤ c with b^5 < R2 ≤ 2 b^5. -/
def checkEDC (e d c R1 : ℕ) : Bool :=
  let R2 := R1 - c ^ 5
  !twoFifthOK R2 ||
  loopDown (fun b => decide (2 * b ^ 5 < R2))
    (fun b => decide (R2 ≤ b ^ 5) || checkB e d c b (R2 - b ^ 5)) c

/-- For fixed e, d: try every c ≤ d with c^5 < R1 ≤ 3 c^5. -/
def checkED (e d : ℕ) : Bool :=
  let R1 := e ^ 5 - d ^ 5
  loopDown (fun c => decide (3 * c ^ 5 < R1)) (fun c => decide (R1 ≤ c ^ 5) || checkEDC e d c R1) d

/-- For fixed e: try every d < e with e^5 ≤ 4 d^5. -/
def checkE (e : ℕ) : Bool :=
  loopDown (fun d => decide (4 * d ^ 5 < e ^ 5)) (fun d => checkED e d) (e - 1)

set_option maxHeartbeats 4000000 in
theorem fifth_power_search : loopDown (fun _ => false) checkE 150 = true := by decide +kernel

/-- The search, read back: the only solution of a^5 + b^5 + c^5 + d^5 = e^5 with
1 ≤ a ≤ b ≤ c ≤ d < e ≤ 150 is (27, 84, 110, 133, 144). -/
theorem fifth_power_search_sound (a b c d e : ℕ) (ha : 1 ≤ a) (hab : a ≤ b) (hbc : b ≤ c)
    (hcd : c ≤ d) (hde : d < e) (he : e ≤ 150) (heq : a ^ 5 + b ^ 5 + c ^ 5 + d ^ 5 = e ^ 5) :
    a = 27 ∧ b = 84 ∧ c = 110 ∧ d = 133 ∧ e = 144 := by
  have pa : 1 ≤ a ^ 5 := Nat.one_le_pow _ _ ha
  have pab := Nat.pow_le_pow_left hab 5
  have pbc := Nat.pow_le_pow_left hbc 5
  have pcd := Nat.pow_le_pow_left hcd 5
  have hE := loopDown_spec _ _ 150 fifth_power_search e he (fun _ _ _ => rfl)
  have hD := loopDown_spec _ _ (e - 1) hE d (by omega) (fun j hj1 _ => by
    have := Nat.pow_le_pow_left hj1 5
    simp only [decide_eq_false_iff_not, not_lt]; omega)
  have hR1 : e ^ 5 - d ^ 5 = a ^ 5 + b ^ 5 + c ^ 5 := by omega
  simp only [checkED, hR1] at hD
  have hC := loopDown_spec _ _ d hD c hcd (fun j hj1 _ => by
    have := Nat.pow_le_pow_left hj1 5
    simp only [decide_eq_false_iff_not, not_lt]; omega)
  have hR2 : a ^ 5 + b ^ 5 + c ^ 5 - c ^ 5 = a ^ 5 + b ^ 5 := by omega
  simp only [Bool.or_eq_true, decide_eq_true_eq, checkEDC, hR2, twoFifthOK_sum,
    Bool.not_true, Bool.false_or] at hC
  rcases hC with hC | hC
  · omega
  have hB := loopDown_spec _ _ c hC b hbc (fun j hj1 _ => by
    have := Nat.pow_le_pow_left hj1 5
    simp only [decide_eq_false_iff_not, not_lt]; omega)
  have hR3 : a ^ 5 + b ^ 5 - b ^ 5 = a ^ 5 := by omega
  simp only [Bool.or_eq_true, decide_eq_true_eq, checkB, hR3, fifthOK_pow,
    root5_pow a (by omega), bne_self_eq_false, Bool.not_true, Bool.false_or,
    Bool.and_eq_true, beq_iff_eq] at hB
  rcases hB with hB | hB
  · omega
  · exact ⟨hB.1.1.1.1, hB.1.1.1.2, hB.1.1.2, hB.1.2, hB.2⟩


set_option maxHeartbeats 4000000 in
theorem fermat_candidates :
    (Finset.range 642).filter (fun p => primeB p = true ∧ p % 64 = 1) =
      {193, 257, 449, 577, 641} := by decide +kernel

set_option maxHeartbeats 4000000 in
theorem goldbach_5777_terms : ∀ k < 54, 1 ≤ k → primeB (5777 - 2 * k ^ 2) = false := by
  decide +kernel

set_option maxHeartbeats 4000000 in
theorem goldbach_count_6000 :
    ((Finset.Icc 9 6000).filter (fun n => n % 2 = 1 ∧ primeB n = false)).card = 2217 := by
  decide +kernel

set_option maxHeartbeats 4000000 in
theorem goldbach_failures_6000 :
    (Finset.Icc 9 6000).filter (fun n => n % 2 = 1 ∧ primeB n = false ∧ pptsB n = false) =
      {5777, 5993} := by
  decide +kernel

set_option maxHeartbeats 4000000 in
theorem goldbach_count_5777 :
    ((Finset.Ico 9 5777).filter (fun n => n % 2 = 1 ∧ primeB n = false)).card = 2131 := by
  decide +kernel

set_option maxHeartbeats 4000000 in
theorem goldbach_no_failure_5777 :
    (Finset.Ico 9 5777).filter (fun n => n % 2 = 1 ∧ primeB n = false ∧ pptsB n = false) =
      ∅ := by
  decide +kernel

#print axioms loopDown_spec
#print axioms loopUp_sound
#print axioms loopUp_complete
#print axioms primeB_iff
#print axioms oddComposite_iff
#print axioms pptsB_iff
#print axioms root5_pow
#print axioms inMask_pow
#print axioms inMask_sum
#print axioms fifthOK_pow
#print axioms twoFifthOK_sum
#print axioms fifth_power_search
#print axioms fifth_power_search_sound
#print axioms fermat_candidates
#print axioms goldbach_5777_terms
#print axioms goldbach_count_6000
#print axioms goldbach_failures_6000
#print axioms goldbach_count_5777
#print axioms goldbach_no_failure_5777

/-- One counterexample is enough. Take a claim "for every x in the domain D, P(x)", where each
case has a yes-or-no answer that can be computed. If one case w lies inside D and the exact
computation of P(w) answers no, then the claim is false. -/
theorem counterexample_refutes_universal_claim {α : Type*} (D : Set α) (P : α → Prop)
    [DecidablePred P] (w : α) (hw : w ∈ D) (hfail : decide (P w) = false) :
    ¬ ∀ x ∈ D, P x := by
  exact fun h => of_decide_eq_false hfail (h w hw)

/-- A run of successes proves nothing about the next case: for every bound N there is a claim
about whole numbers, with a computable yes-or-no answer, that holds for every case below N
and fails at N. So "checked for every n below N" can never by itself give "true for every n". -/
theorem checked_below_bound_proves_nothing (N : ℕ) :
    ∃ P : ℕ → Prop, ∃ _ : DecidablePred P, (∀ n < N, P n) ∧ ¬ P N := by
  exact ⟨fun n => n < N, inferInstance, fun n hn => hn, lt_irrefl N⟩

/-- Euler's sum-of-powers conjecture (1769) is false: it is not true that for every power
k ≥ 3, every number of terms n with 2 ≤ n < k, and all positive whole numbers a₁, …, aₙ and b,
the sum a₁^k + … + aₙ^k differs from b^k. Lander and Parkin's 1966 witness is k = 5, n = 4,
(27, 84, 110, 133) and b = 144. -/
theorem euler_sum_of_powers_conjecture_false :
    ¬ ∀ k : ℕ, 3 ≤ k → ∀ n : ℕ, 2 ≤ n → n < k → ∀ (a : Fin n → ℕ) (b : ℕ),
      (∀ i, 0 < a i) → 0 < b → ∑ i, a i ^ k ≠ b ^ k := by
  intro h
  apply h 5 (by norm_num) 4 (by norm_num) (by norm_num) ![27, 84, 110, 133] 144 (by decide)
    (by norm_num)
  rw [Fin.sum_univ_four]
  norm_num

/-- Goldbach's other conjecture, case by case: n is a prime plus twice a nonzero square. -/
def PrimePlusTwiceSquare (n : ℕ) : Prop :=
  ∃ k ∈ Finset.Icc 1 n, 2 * k ^ 2 < n ∧ Nat.Prime (n - 2 * k ^ 2)

instance : DecidablePred PrimePlusTwiceSquare := fun n => by
  unfold PrimePlusTwiceSquare; infer_instance

/-! Euler's witness, by hand. -/

-- The five fifth powers, and both sides equal to 61,917,364,224.
example : 27 ^ 5 = 14348907 ∧ 84 ^ 5 = 4182119424 ∧ 110 ^ 5 = 16105100000 ∧
    133 ^ 5 = 41615795893 ∧ 144 ^ 5 = 61917364224 := by norm_num
example : 27 ^ 5 + 84 ^ 5 + 110 ^ 5 + 133 ^ 5 = 144 ^ 5 := by norm_num
-- The mod 30 quick test: 27 + 84 + 110 + 133 = 354, which is 24 mod 30, and 144 is 24 mod 30.
example : 27 + 84 + 110 + 133 = 354 ∧ 354 % 30 = 24 ∧ 144 % 30 = 24 := by norm_num
-- The mod 30 shortcut behind it: x^5 and x leave the same remainder on division by 30.
example : ∀ x < 30, x ^ 5 % 30 = x := by decide
-- The table-lookup search: the only solution with 1 ≤ a ≤ b ≤ c ≤ d < e ≤ 150.
example : ∀ a b c d e : ℕ, 1 ≤ a → a ≤ b → b ≤ c → c ≤ d → d < e → e ≤ 150 →
    a ^ 5 + b ^ 5 + c ^ 5 + d ^ 5 = e ^ 5 → (a, b, c, d, e) = (27, 84, 110, 133, 144) := by
  intro a b c d e h1 h2 h3 h4 h5 h6 h7
  obtain ⟨rfl, rfl, rfl, rfl, rfl⟩ := fifth_power_search_sound a b c d e h1 h2 h3 h4 h5 h6 h7
  rfl
-- The candidates before 144, counted by a sum and by the closed formula C(146, 5).
example : ∑ e ∈ Finset.Ico 2 144, (e + 2).choose 4 = 515853624 ∧
    Nat.choose 146 5 = 515853624 := by
  have h1 : Nat.choose 146 5 = 515853624 := by
    rw [Nat.choose_eq_factorial_div_factorial (by norm_num)]
    norm_num [Nat.factorial]
  refine ⟨?_, h1⟩
  have hI : Finset.Icc 4 145 = Finset.Ico 4 146 := by ext; simp; omega
  rw [← h1, ← Nat.sum_Icc_choose 145 4, Finset.sum_Ico_eq_sum_range, hI,
    Finset.sum_Ico_eq_sum_range, show 144 - 2 = 142 from rfl]
  exact Finset.sum_congr rfl (fun k _ => by rw [show 2 + k + 2 = 4 + k by omega])
-- The doubled witness still balances: the same counterexample at a different scale.
example : 54 ^ 5 + 168 ^ 5 + 220 ^ 5 + 266 ^ 5 = 288 ^ 5 := by norm_num
-- Fourth powers, 1988: Frye's smallest witness and Elkies's constructed one.
example : 95800 ^ 4 + 217519 ^ 4 + 414560 ^ 4 = 422481 ^ 4 := by norm_num
example : 2682440 ^ 4 + 15365639 ^ 4 + 18796760 ^ 4 = 20615673 ^ 4 := by norm_num
-- Not a witness: three cubes making a cube is true, but uses k = 3 terms, not fewer.
example : 3 ^ 3 + 4 ^ 3 + 5 ^ 3 = 6 ^ 3 ∧ 27 + 64 + 125 = 216 := by norm_num
-- The near miss is not a witness: the left side is odd and the right side is even.
example : (1782 ^ 12 + 1841 ^ 12) % 2 = 1 ∧ 1922 ^ 12 % 2 = 0 ∧
    1782 ^ 12 + 1841 ^ 12 ≠ 1922 ^ 12 := by norm_num

/-! Fermat's claim (1640): every 2^(2^m) + 1 is prime. -/

-- The first five, m = 0 to 4 (3, 5, 17, 257, 65537), are prime.
example : ∀ m < 5, Nat.Prime (2 ^ 2 ^ m + 1) := by
  intro m hm
  interval_cases m <;> norm_num
example : 2 ^ 2 ^ 4 + 1 = 65537 := by norm_num
-- The witness: 2^32 + 1 = 4,294,967,297 = 641 × 6,700,417, and the cofactor is prime.
example : 2 ^ 2 ^ 5 + 1 = 4294967297 ∧ 4294967297 = 641 * 6700417 := by norm_num
example : Nat.Prime 6700417 := by norm_num
example : ¬ Nat.Prime (2 ^ 2 ^ 5 + 1) := by norm_num
example : ¬ ∀ m : ℕ, Nat.Prime (2 ^ 2 ^ m + 1) := by
  intro h
  have := h 5
  norm_num at this
-- Euler's rule for m = 5: every prime factor of 2^32 + 1 is one more than a multiple of 64.
example : ∀ p : ℕ, Nat.Prime p → p ∣ 2 ^ 2 ^ 5 + 1 → p % 64 = 1 := by
  intro p hp hd
  rw [show 2 ^ 2 ^ 5 + 1 = 641 * 6700417 by norm_num] at hd
  rcases (Nat.Prime.dvd_mul hp).1 hd with h | h
  · rw [(Nat.prime_dvd_prime_iff_eq hp (by norm_num)).1 h]
  · rw [(Nat.prime_dvd_prime_iff_eq hp (by norm_num)).1 h]
-- The five candidates up to 641, and 641 is the fifth.
example : (Finset.range 642).filter (fun p => Nat.Prime p ∧ p % 64 = 1) =
    {193, 257, 449, 577, 641} := by
  rw [Finset.filter_congr (q := fun p => primeB p = true ∧ p % 64 = 1)
    (fun p _ => by rw [primeB_iff])]
  exact fermat_candidates
-- Squaring 2 five times mod 641: 4, 16, 256, 154, 640.
example : 2 ^ 2 % 641 = 4 ∧ 4 ^ 2 % 641 = 16 ∧ 16 ^ 2 % 641 = 256 ∧ 256 ^ 2 % 641 = 154 ∧
    154 ^ 2 % 641 = 640 ∧ 2 ^ 32 % 641 = 640 := by norm_num
-- Euler's two ways of writing 641.
example : 641 = 5 * 2 ^ 7 + 1 ∧ 641 = 5 ^ 4 + 2 ^ 4 := by norm_num

/-! Goldbach's other conjecture (1752): every odd composite is a prime plus twice a square. -/

-- The first cases fit: 9 = 7 + 2 × 1², 15 = 13 + 2 × 1², 21 = 19 + 2 × 1².
example : 9 = 7 + 2 * 1 ^ 2 ∧ 15 = 13 + 2 * 1 ^ 2 ∧ 21 = 19 + 2 * 1 ^ 2 := by norm_num
-- 5777 = 53 × 109 is odd and composite.
example : 5777 = 53 * 109 ∧ Odd 5777 ∧ ¬ Nat.Prime 5777 := by exact ⟨by norm_num, ⟨2888, by norm_num⟩, by norm_num⟩
-- None of the 53 numbers 5777 − 2 × 1², …, 5777 − 2 × 53² is prime.
example : ∀ k, 1 ≤ k → k ≤ 53 → ¬ Nat.Prime (5777 - 2 * k ^ 2) := by
  intro k h1 h2
  rw [← primeB_iff, goldbach_5777_terms k (by omega) h1]
  simp
example : 2 * 53 ^ 2 < 5777 ∧ 5777 < 2 * 54 ^ 2 := by norm_num
-- Among the odd composites from 9 to 6000 (2,217 of them) the failures are 5777 and 5993.
example : ((Finset.Icc 9 6000).filter (fun n => Odd n ∧ ¬ Nat.Prime n)).card = 2217 := by
  rw [Finset.filter_congr (q := fun n => n % 2 = 1 ∧ primeB n = false)
    (fun n _ => oddComposite_iff n)]
  exact goldbach_count_6000
example : (Finset.Icc 9 6000).filter
    (fun n => Odd n ∧ ¬ Nat.Prime n ∧ ¬ PrimePlusTwiceSquare n) = {5777, 5993} := by
  rw [Finset.filter_congr (q := fun n => n % 2 = 1 ∧ primeB n = false ∧ pptsB n = false)
    (fun n _ => by
      rw [← and_assoc, oddComposite_iff, and_assoc, PrimePlusTwiceSquare, ← pptsB_iff]
      simp)]
  exact goldbach_failures_6000
-- The 2,131 odd composites below 5777 all fit.
example : ((Finset.Ico 9 5777).filter (fun n => Odd n ∧ ¬ Nat.Prime n)).card = 2131 ∧
    ∀ n ∈ Finset.Ico 9 5777, Odd n → ¬ Nat.Prime n → PrimePlusTwiceSquare n := by
  refine ⟨?_, ?_⟩
  · rw [Finset.filter_congr (q := fun n => n % 2 = 1 ∧ primeB n = false)
      (fun n _ => oddComposite_iff n)]
    exact goldbach_count_5777
  · intro n hn ho hp
    have h := (oddComposite_iff n).1 ⟨ho, hp⟩
    have key := Finset.filter_eq_empty_iff.1 goldbach_no_failure_5777 hn
    unfold PrimePlusTwiceSquare
    rw [← pptsB_iff]
    by_contra hb
    exact key ⟨h.1, h.2, by simpa using hb⟩
-- So the conjecture is false.
example : ¬ ∀ n : ℕ, Odd n → 9 ≤ n → ¬ Nat.Prime n →
    ∃ p k : ℕ, Nat.Prime p ∧ 1 ≤ k ∧ n = p + 2 * k ^ 2 := by
  intro h
  obtain ⟨p, k, hp, hk, he⟩ := h 5777 ⟨2888, by norm_num⟩ (by norm_num) (by norm_num)
  have hk53 : k ≤ 53 := by
    by_contra hc
    have : 54 ^ 2 ≤ k ^ 2 := Nat.pow_le_pow_left (by omega) 2
    omega
  have hp' : p = 5777 - 2 * k ^ 2 := by omega
  rw [hp', ← primeB_iff, goldbach_5777_terms k (by omega) hk] at hp
  exact absurd hp (by simp)

#print axioms counterexample_refutes_universal_claim
#print axioms checked_below_bound_proves_nothing
#print axioms euler_sum_of_powers_conjecture_false
