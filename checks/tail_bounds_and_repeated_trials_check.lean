-- Tail bounds: N uses of a one-sided test, each repeated k ≥ ln(N/δ)/ln(1/m) times with independent runs that each miss with chance at most m, all succeed except with chance at most δ, one run of Freivalds' check catches a wrong matrix product on at least half of all 0/1 lists while never rejecting a right one, and the card's whole-number run counts and 3 by 3 example check out exactly.
import Mathlib.Probability.Independence.Basic
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Data.Matrix.Mul
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.NormNum.NatFactorial

namespace TailBoundsAndRepeatedTrials

open MeasureTheory ProbabilityTheory Matrix

/-- The card's main claim, the one-sided repeat rule with the union bound. A method is used
`N` times; use `j` makes `k` runs, and `miss j i` is the event that run `i` of use `j` misses.
Within each use the runs are independent (fresh randomness every run), and every run misses with
chance at most `m`, where `0 < m < 1`, so the rate per run is `r = ln(1/m)`. If the number of runs
is at least `ln(N/δ) / r`, the chance that some use fails (all of its `k` runs miss) is at most
`δ`. No independence between different uses is assumed. -/
theorem one_sided_repeats_fail_somewhere_with_chance_at_most_delta
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (N k : ℕ) (miss : Fin N → Fin k → Set Ω) (hindep : ∀ j, iIndepSet (miss j) μ)
    (m δ : ℝ) (hm0 : 0 < m) (hm1 : m < 1) (hδ : 0 < δ)
    (hmiss : ∀ j i, μ (miss j i) ≤ ENNReal.ofReal m)
    (hk : Real.log (N / δ) / Real.log (1 / m) ≤ k) :
    μ (⋃ j, ⋂ i, miss j i) ≤ ENNReal.ofReal δ := by
  classical
  rcases Nat.eq_zero_or_pos N with hN | hN
  · subst hN; simp
  have hlogm : 0 < Real.log (1 / m) := Real.log_pos (by rw [one_div]; exact one_lt_inv₀ hm0 |>.2 hm1)
  have key : (N : ℝ) * m ^ k ≤ δ := by
    have h1 : Real.log (N / δ) ≤ k * Real.log (1 / m) := by rwa [div_le_iff₀ hlogm] at hk
    have h2 : Real.log ((N : ℝ) / δ) ≤ Real.log ((1 / m) ^ k) := by rw [Real.log_pow]; exact h1
    have hNpos : (0 : ℝ) < N := by exact_mod_cast hN
    have h3 : (N : ℝ) / δ ≤ (1 / m) ^ k :=
      (Real.log_le_log_iff (by positivity) (by positivity)).1 h2
    rw [div_pow, one_pow, div_le_div_iff₀ hδ (by positivity)] at h3
    linarith
  calc μ (⋃ j, ⋂ i, miss j i) ≤ ∑ j, μ (⋂ i, miss j i) := measure_iUnion_fintype_le _ _
    _ = ∑ j, ∏ i, μ (miss j i) := by
        refine Finset.sum_congr rfl fun j _ => ?_
        simpa using (hindep j).meas_biInter Finset.univ
    _ ≤ ∑ _j : Fin N, ∏ _i : Fin k, ENNReal.ofReal m := by
        gcongr with j _ i _
        exact hmiss j i
    _ = ENNReal.ofReal (N * m ^ k) := by
        rw [ENNReal.ofReal_mul (by positivity), ENNReal.ofReal_pow hm0.le]
        simp [Finset.prod_const, Finset.sum_const, nsmul_eq_mul]
    _ ≤ ENNReal.ofReal δ := ENNReal.ofReal_le_ofReal key

/-- A random list of zeros and ones, read from a list of yes/no choices. -/
def zeroOneList {R : Type*} [Zero R] [One R] {n : ℕ} (x : Fin n → Bool) : Fin n → R :=
  fun i => if x i then 1 else 0

/-- Freivalds' check, one run (Step 1). The check compares `A (B x)` with `C x` for a list `x`
of zeros and ones. A right product (`C = A B`) passes on every list. A wrong product
(`C ≠ A B`) is caught by at least half of all `2^n` lists. -/
theorem freivalds_check_never_rejects_right_and_catches_wrong_half_the_time
    {R : Type*} [Ring R] [DecidableEq R] {n : ℕ} (A B C : Matrix (Fin n) (Fin n) R) :
    (C = A * B → ∀ x : Fin n → Bool, A *ᵥ (B *ᵥ zeroOneList x) = C *ᵥ zeroOneList x) ∧
      (C ≠ A * B → 2 ^ n ≤ 2 * (Finset.univ.filter (fun x : Fin n → Bool =>
        A *ᵥ (B *ᵥ zeroOneList x) ≠ C *ᵥ zeroOneList x)).card) := by
  classical
  refine ⟨fun h x => by rw [h, Matrix.mulVec_mulVec], fun hne => ?_⟩
  set D : Matrix (Fin n) (Fin n) R := A * B - C with hD
  have hDv : ∀ v, D *ᵥ v = A *ᵥ (B *ᵥ v) - C *ᵥ v := fun v => by
    rw [hD, Matrix.sub_mulVec, Matrix.mulVec_mulVec]
  obtain ⟨r, c, hrc⟩ : ∃ r c, D r c ≠ 0 := by
    by_contra hcon
    push Not at hcon
    apply hne
    have : D = 0 := by ext r c; exact hcon r c
    rw [hD, sub_eq_zero] at this
    exact this.symm
  let flip : (Fin n → Bool) → (Fin n → Bool) := fun x => Function.update x c (!x c)
  have hflip_inj : Function.Injective flip := by
    intro x y hxy
    have hc := congrFun hxy c
    simp only [flip, Function.update_self, Bool.not_inj_iff] at hc
    funext k
    by_cases hk : k = c
    · subst hk; exact hc
    · have := congrFun hxy k
      simpa [flip, Function.update_of_ne hk] using this
  have hdiff : ∀ x : Fin n → Bool, (zeroOneList x : Fin n → R) - zeroOneList (flip x)
      = Pi.single c (if x c then (1 : R) else -1) := by
    intro x
    funext k
    by_cases hk : k = c
    · subst hk
      cases h : x k <;> simp [zeroOneList, flip, h]
    · simp [zeroOneList, flip, hk]
  set S := Finset.univ.filter (fun x : Fin n → Bool =>
        A *ᵥ (B *ᵥ zeroOneList x) ≠ C *ᵥ zeroOneList x) with hS
  set T := Finset.univ.filter (fun x : Fin n → Bool =>
        ¬ (A *ᵥ (B *ᵥ zeroOneList x) ≠ C *ᵥ zeroOneList x)) with hT
  have hTS : T.card ≤ S.card := by
    refine Finset.card_le_card_of_injOn flip ?_ (hflip_inj.injOn)
    intro x hx
    simp only [hT, hS, Finset.coe_filter, Finset.mem_univ, true_and, not_not,
      Set.mem_ofPred_eq] at hx ⊢
    intro hy
    have h0 : D *ᵥ (zeroOneList x - zeroOneList (flip x)) = 0 := by
      rw [Matrix.mulVec_sub, hDv, hDv, hx, hy, sub_self, sub_self, sub_self]
    rw [hdiff, Matrix.mulVec_single] at h0
    have h1 := congrFun h0 r
    apply hrc
    cases h : x c <;> simp [h, Matrix.col] at h1 <;> simpa using h1
  have hsum := Finset.card_filter_add_card_filter_not
    (s := (Finset.univ : Finset (Fin n → Bool)))
    (fun x : Fin n → Bool => A *ᵥ (B *ᵥ zeroOneList x) ≠ C *ᵥ zeroOneList x)
  rw [Finset.card_univ, Fintype.card_pi, Fintype.card_bool, Finset.prod_const,
    Finset.card_univ, Fintype.card_fin] at hsum
  rw [← hsum]
  change S.card + T.card ≤ 2 * S.card
  omega

-- The card's 3 by 3 check: A, B, the right product AB, and a wrong one with entry (1, 2)
-- off by one (11 becomes 12). 4 of the 8 lists catch the wrong one; 0 of 8 flag the right one.
example : !![(2 : ℤ), 1, 0; 1, 3, 1; 0, 1, 2] * !![(1 : ℤ), 2, 1; 0, 1, 3; 2, 0, 1]
    = !![(2 : ℤ), 5, 5; 3, 5, 11; 4, 1, 5] := by decide
example : (Finset.univ.filter (fun x : Fin 3 → Bool =>
    !![(2 : ℤ), 1, 0; 1, 3, 1; 0, 1, 2] *ᵥ (!![(1 : ℤ), 2, 1; 0, 1, 3; 2, 0, 1] *ᵥ zeroOneList x)
      ≠ !![(2 : ℤ), 5, 5; 3, 5, 12; 4, 1, 5] *ᵥ zeroOneList x)).card = 4 := by decide
example : (Finset.univ.filter (fun x : Fin 3 → Bool =>
    !![(2 : ℤ), 1, 0; 1, 3, 1; 0, 1, 2] *ᵥ (!![(1 : ℤ), 2, 1; 0, 1, 3; 2, 0, 1] *ᵥ zeroOneList x)
      ≠ !![(2 : ℤ), 5, 5; 3, 5, 11; 4, 1, 5] *ᵥ zeroOneList x)).card = 0 := by decide

-- Cost: one check 3 × 1,000² = 3,000,000 multiplications, a redo 1,000³; 20 checks are 6% of
-- a redo and 44 checks 13.2%.
example : 3 * 1000 ^ 2 = 3000000 ∧ 1000 ^ 3 = 1000000000 := by norm_num
example : 20 * 3000000 * 100 = 6 * 1000 ^ 3 ∧ 44 * 3000000 * 1000 = 132 * 1000 ^ 3 := by norm_num

-- One request: (1/2)^20 = 1 / 1,048,576 is at most 1 in a million, and 19 runs are not enough.
example : (2 : ℕ) ^ 20 = 1048576 ∧ 10 ^ 6 ≤ (2 : ℕ) ^ 20 ∧ (2 : ℕ) ^ 19 < 10 ^ 6 := by norm_num
-- A check that misses 1 time in 4 (Miller-Rabin): 10 runs reach 1 in a million, 9 do not.
example : 10 ^ 6 ≤ (4 : ℕ) ^ 10 ∧ (4 : ℕ) ^ 9 < 10 ^ 6 := by norm_num
-- The whole day, 10,000,000 requests at 20 runs: the union bound 10^7 / 2^20 is above 1.
example : (1 : ℚ) < 10 ^ 7 / 2 ^ 20 := by norm_num
-- A safe day: 44 runs give 10^7 × 2^-44 ≤ 10^-6, and 43 runs do not; 2^44 = 17,592,186,044,416.
example : (2 : ℕ) ^ 44 = 17592186044416 ∧ 10 ^ 7 * 10 ^ 6 ≤ (2 : ℕ) ^ 44 ∧
    (2 : ℕ) ^ 43 < 10 ^ 7 * 10 ^ 6 := by norm_num
example : (10 : ℚ) ^ 7 / 2 ^ 44 ≤ 1 / 10 ^ 6 := by norm_num

-- The two-sided vote, right 3 times in 4: margin ε = 3/4 - 1/2 = 1/4 and Hoeffding's rate
-- 2ε² = 1/8; Markov's bound (k/4)/(k/2) = 1/2 and Chebyshev's (3k/16)/(k/4)² = 3/k.
example : (3 / 4 : ℚ) - 1 / 2 = 1 / 4 ∧ 2 * (1 / 4 : ℚ) ^ 2 = 1 / 8 := by norm_num
example (k : ℚ) (hk : k ≠ 0) : (k / 4) / (k / 2) = 1 / 2 := by field_simp; ring
example (k : ℚ) (hk : k ≠ 0) : (3 * k / 16) / (k / 4) ^ 2 = 3 / k := by field_simp; ring
-- Chebyshev's 3/k reaches 1 in a million only at k = 3,000,000.
example : (3 : ℚ) / 3000000 = 1 / 10 ^ 6 := by norm_num
-- The exact vote: with 79 runs the chance that at least 40 are wrong,
-- Σ C(79, w) 3^(79-w) / 4^79 over w ≥ 40, is below 1 in a million.
example : 10 ^ 6 * ∑ w ∈ Finset.Ico 40 80, Nat.choose 79 w * 3 ^ (79 - w) < 4 ^ 79 := by
  simp only [Finset.sum_Ico_eq_sum_range, Finset.sum_range_succ, Finset.sum_range_zero]
  simp (disch := omega) only [Nat.choose_eq_factorial_div_factorial]
  norm_num [Nat.factorial_succ]
-- With 77 runs the chance that at least 39 are wrong is still above 1 in a million.
example : 4 ^ 77 < 10 ^ 6 * ∑ w ∈ Finset.Ico 39 78, Nat.choose 77 w * 3 ^ (77 - w) := by
  simp only [Finset.sum_Ico_eq_sum_range, Finset.sum_range_succ, Finset.sum_range_zero]
  simp (disch := omega) only [Nat.choose_eq_factorial_div_factorial]
  norm_num [Nat.factorial_succ]

#print axioms one_sided_repeats_fail_somewhere_with_chance_at_most_delta
#print axioms freivalds_check_never_rejects_right_and_catches_wrong_half_the_time

end TailBoundsAndRepeatedTrials
