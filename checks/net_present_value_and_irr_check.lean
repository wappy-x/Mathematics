-- NPV and IRR: the value today of a dated list of cash is exactly the bank balance it leaves at the end carried back to today, and one payment out followed only by payments in has exactly one break-even rate, above which the project loses money and below which it gains.
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open Finset

/-- Helper: the cash list as a polynomial in the discount factor `t = 1 / (1 + y)`. -/
theorem npv_irr_poly_strictMonoOn (n : ℕ) (c : ℕ → ℝ)
    (hin : ∀ i ∈ Icc 1 n, 0 ≤ c i) (hpos : ∃ i ∈ Icc 1 n, 0 < c i) :
    StrictMonoOn (fun t : ℝ => ∑ i ∈ range (n + 1), c i * t ^ i) (Set.Ici 0) := by
  intro s hs t ht hst
  simp only [Set.mem_Ici] at hs ht
  obtain ⟨k, hk, hck⟩ := hpos
  rw [mem_Icc] at hk
  apply Finset.sum_lt_sum
  · intro i hi
    rcases Nat.eq_zero_or_pos i with h | h
    · subst h; simp
    · have hi' : i ∈ Icc 1 n := by
        rw [mem_Icc]; rw [mem_range] at hi; omega
      exact mul_le_mul_of_nonneg_left (pow_le_pow_left₀ hs hst.le i) (hin i hi')
  · refine ⟨k, ?_, ?_⟩
    · rw [mem_range]; omega
    · exact mul_lt_mul_of_pos_left (pow_lt_pow_left₀ hst hs (by omega)) hck

/-- Helper: the NPV at rate `y` is the polynomial at `t = (1 + y)⁻¹`. -/
theorem npv_irr_npv_eq_poly (n : ℕ) (c : ℕ → ℝ) (y : ℝ) :
    ∑ i ∈ range (n + 1), c i / (1 + y) ^ i = ∑ i ∈ range (n + 1), c i * ((1 + y)⁻¹) ^ i := by
  refine Finset.sum_congr rfl fun i _ => ?_
  rw [inv_pow, div_eq_mul_inv]

/-- Helper: the NPV is strictly decreasing in the rate above minus 100 percent. -/
theorem npv_irr_strictAntiOn (n : ℕ) (c : ℕ → ℝ)
    (hin : ∀ i ∈ Icc 1 n, 0 ≤ c i) (hpos : ∃ i ∈ Icc 1 n, 0 < c i) :
    StrictAntiOn (fun y : ℝ => ∑ i ∈ range (n + 1), c i / (1 + y) ^ i) (Set.Ioi (-1)) := by
  intro a ha b hb hab
  simp only [Set.mem_Ioi] at ha hb
  simp only [npv_irr_npv_eq_poly]
  apply npv_irr_poly_strictMonoOn n c hin hpos
  · simp only [Set.mem_Ici]; have : 0 < 1 + b := by linarith
    positivity
  · simp only [Set.mem_Ici]; have : 0 < 1 + a := by linarith
    positivity
  · exact inv_strictAnti₀ (by linarith) (by linarith)

/-- Helper: a root of the NPV exists above minus 100 percent. -/
theorem npv_irr_exists_root (n : ℕ) (c : ℕ → ℝ) (h0 : c 0 < 0)
    (hin : ∀ i ∈ Icc 1 n, 0 ≤ c i) (hpos : ∃ i ∈ Icc 1 n, 0 < c i) :
    ∃ y : ℝ, -1 < y ∧ ∑ i ∈ range (n + 1), c i / (1 + y) ^ i = 0 := by
  set g : ℝ → ℝ := fun t => ∑ i ∈ range (n + 1), c i * t ^ i with hg
  have hmono := npv_irr_poly_strictMonoOn n c hin hpos
  obtain ⟨k, hk, hck⟩ := hpos
  rw [mem_Icc] at hk
  set T : ℝ := max 1 (-c 0 / c k) + 1 with hT
  have hT1 : 1 ≤ T := by have := le_max_left 1 (-c 0 / c k); linarith
  have hT2 : -c 0 / c k < T := by have := le_max_right 1 (-c 0 / c k); linarith
  have hg0 : g 0 = c 0 := by
    simp only [hg]
    rw [Finset.sum_range_succ']
    simp
  have hgT : 0 < g T := by
    have hsplit : g T = c 0 + ∑ i ∈ (range (n + 1)).erase 0, c i * T ^ i := by
      simp only [hg]
      rw [← Finset.add_sum_erase _ _ (mem_range.mpr (Nat.succ_pos n))]
      simp
    have hkmem : k ∈ (range (n + 1)).erase 0 := by
      rw [mem_erase, mem_range]; omega
    have hle : c k * T ^ k ≤ ∑ i ∈ (range (n + 1)).erase 0, c i * T ^ i := by
      apply Finset.single_le_sum (f := fun i => c i * T ^ i) _ hkmem
      intro i hi
      rw [mem_erase, mem_range] at hi
      have : 0 ≤ c i := hin i (by rw [mem_Icc]; omega)
      have : (0 : ℝ) ≤ T ^ i := by positivity
      positivity
    have hTk : T ≤ T ^ k := le_self_pow₀ hT1 (by omega)
    have h1 : -c 0 < c k * T := by
      rw [div_lt_iff₀ hck] at hT2; linarith
    have h2 : c k * T ≤ c k * T ^ k := mul_le_mul_of_nonneg_left hTk hck.le
    linarith
  have hcont : ContinuousOn g (Set.Icc 0 T) := by
    simp only [hg]; fun_prop
  have hmem : (0 : ℝ) ∈ Set.Icc (g 0) (g T) := ⟨by rw [hg0]; exact h0.le, hgT.le⟩
  obtain ⟨t, ⟨ht0, htT⟩, hgt⟩ := intermediate_value_Icc (by linarith) hcont hmem
  have htpos : 0 < t := by
    rcases ht0.lt_or_eq with h | h
    · exact h
    · subst h; rw [hg0] at hgt; linarith
  refine ⟨t⁻¹ - 1, ?_, ?_⟩
  · have : 0 < t⁻¹ := inv_pos.mpr htpos
    linarith
  · rw [npv_irr_npv_eq_poly]
    have : (1 + (t⁻¹ - 1))⁻¹ = t := by simp
    rw [this]
    exact hgt

#print axioms npv_irr_poly_strictMonoOn
#print axioms npv_irr_npv_eq_poly
#print axioms npv_irr_strictAntiOn
#print axioms npv_irr_exists_root

/-- The ledger and the value today agree. Take a list of cash `c 0, c 1, ..., c n`, one amount
per whole year (in counts plus, out counts minus), and one rate `y` above minus 100 percent.
Run the bank account: it starts at `W 0 = c 0`, and each year the balance grows by the factor
`1 + y` and then that year's cash arrives, `W (i + 1) = W i * (1 + y) + c (i + 1)`. Then the
balance at the last date is the growth factor for `n` years times the NPV
`V(y) = c 0 + c 1 / (1 + y) + ... + c n / (1 + y)^n`. So the end balance and the NPV always
carry the same sign: a positive NPV is extra money in the account at the end. -/
theorem end_balance_is_npv_carried_forward (n : ℕ) (c : ℕ → ℝ) (y : ℝ) (hy : -1 < y)
    (W : ℕ → ℝ) (hW0 : W 0 = c 0) (hW : ∀ i, W (i + 1) = W i * (1 + y) + c (i + 1)) :
    W n = (1 + y) ^ n * ∑ i ∈ range (n + 1), c i / (1 + y) ^ i ∧
      (0 < W n ↔ 0 < ∑ i ∈ range (n + 1), c i / (1 + y) ^ i) := by
  have h1 : (1 + y) ≠ 0 := by linarith
  have hp : 0 < 1 + y := by linarith
  have key : W n = (1 + y) ^ n * ∑ i ∈ range (n + 1), c i / (1 + y) ^ i := by
    induction n with
    | zero => simp [hW0]
    | succ m ih =>
      rw [hW m, ih, Finset.sum_range_succ (n := m + 1)]
      field_simp
      ring
  refine ⟨key, ?_⟩
  rw [key]
  exact mul_pos_iff_of_pos_left (pow_pos hp n)

/-- One payment out, then nothing but payments in, gives exactly one IRR. If the cash today
`c 0` is negative, every later amount `c 1, ..., c n` is zero or more, and at least one of
them is strictly positive, then among the rates above minus 100 percent there is exactly one
rate `y` at which the NPV `c 0 + c 1 / (1 + y) + ... + c n / (1 + y)^n` is zero. -/
theorem one_outlay_then_inflows_has_exactly_one_irr (n : ℕ) (c : ℕ → ℝ) (h0 : c 0 < 0)
    (hin : ∀ i ∈ Icc 1 n, 0 ≤ c i) (hpos : ∃ i ∈ Icc 1 n, 0 < c i) :
    ∃! y : ℝ, -1 < y ∧ ∑ i ∈ range (n + 1), c i / (1 + y) ^ i = 0 := by
  obtain ⟨y, hy, hroot⟩ := npv_irr_exists_root n c h0 hin hpos
  refine ⟨y, ⟨hy, hroot⟩, ?_⟩
  rintro z ⟨hz, hzroot⟩
  exact (npv_irr_strictAntiOn n c hin hpos).injOn hz hy (hzroot.trans hroot.symm)

/-- The sign rule. For the same shape of project (one payment out today, then nothing but
payments in, at least one of them positive) there is a break-even rate `y*` above minus
100 percent with NPV zero, and at any rate `y` above minus 100 percent the project is worth
doing (positive NPV) exactly when `y` is below `y*`, that is, exactly when the IRR beats `y`. -/
theorem worth_doing_iff_irr_beats_rate (n : ℕ) (c : ℕ → ℝ) (h0 : c 0 < 0)
    (hin : ∀ i ∈ Icc 1 n, 0 ≤ c i) (hpos : ∃ i ∈ Icc 1 n, 0 < c i) :
    ∃ ystar : ℝ, -1 < ystar ∧ ∑ i ∈ range (n + 1), c i / (1 + ystar) ^ i = 0 ∧
      ∀ y : ℝ, -1 < y → (0 < ∑ i ∈ range (n + 1), c i / (1 + y) ^ i ↔ y < ystar) := by
  obtain ⟨y, hy, hroot⟩ := npv_irr_exists_root n c h0 hin hpos
  refine ⟨y, hy, hroot, ?_⟩
  intro z hz
  have hA := npv_irr_strictAntiOn n c hin hpos
  constructor
  · intro hpos'
    by_contra hle'
    have hle : y ≤ z := not_lt.mp hle'
    rcases hle.lt_or_eq with hlt | heq
    · have := hA hy hz hlt
      simp only [hroot] at this
      linarith
    · subst heq; linarith
  · intro hlt
    have := hA hz hy hlt
    simp only [hroot] at this
    exact this

-- The card's worked numbers, as exact fractions. 8 percent is 2/25, so the growth factor is 27/25.
-- The kit, -100, 60, 60, at 8 percent: NPV 5100/729, about $7.00.
example : (-100 : ℚ) + 60 / (1 + 2 / 25) + 60 / (1 + 2 / 25) ^ 2 = 5100 / 729 := by norm_num
-- The same through the NPV sum.
example : ∑ i ∈ range 3, (if i = 0 then (-100 : ℚ) else 60) / (1 + 2 / 25) ^ i = 5100 / 729 := by
  simp [sum_range_succ]; norm_num
-- The ledger: -100, then -48, then 8.16 = 204/25; and 8.16 carried back two years is the NPV.
example : (-100 : ℚ) * (27 / 25) + 60 = -48 := by norm_num
example : (-48 : ℚ) * (27 / 25) + 60 = 204 / 25 := by norm_num
example : (204 / 25 : ℚ) / (27 / 25) ^ 2 = 5100 / 729 := by norm_num
-- The kit at 0 percent: $20.00.
example : (-100 : ℚ) + 60 + 60 = 20 := by norm_num
-- The break-even growth factor z = (3 + √69)/10 solves 5z² - 3z - 3 = 0.
example : 5 * ((3 + Real.sqrt 69) / 10) ^ 2 - 3 * ((3 + Real.sqrt 69) / 10) - 3 = 0 := by
  have h : Real.sqrt 69 ^ 2 = 69 := Real.sq_sqrt (by norm_num)
  nlinarith [h]
-- The mistakes: shrinking today's 100 as well gives 3500/243 ($14.40); year one's factor for
-- both savings gives 100/9 ($11.11).
example : (-100 : ℚ) / (1 + 2 / 25) + 60 / (1 + 2 / 25) + 60 / (1 + 2 / 25) ^ 2 = 3500 / 243 := by
  norm_num
example : (-100 : ℚ) + 60 / (1 + 2 / 25) + 60 / (1 + 2 / 25) = 100 / 9 := by norm_num
-- The bigger kit, -250, 145, 145, at 8 percent: 6250/729 ($8.57), which is 1150/729 ($1.58) more.
example : (-250 : ℚ) + 145 / (1 + 2 / 25) + 145 / (1 + 2 / 25) ^ 2 = 6250 / 729 := by norm_num
example : (6250 : ℚ) / 729 - 5100 / 729 = 1150 / 729 := by norm_num
-- The cleanup kit, -100, 230, -132: zero at 10 percent and at 20 percent, 100/529 ($0.19) at 15.
example : (-100 : ℚ) + 230 / (1 + 1 / 10) - 132 / (1 + 1 / 10) ^ 2 = 0 := by norm_num
example : (-100 : ℚ) + 230 / (1 + 1 / 5) - 132 / (1 + 1 / 5) ^ 2 = 0 := by norm_num
example : (-100 : ℚ) + 230 / (1 + 3 / 20) - 132 / (1 + 3 / 20) ^ 2 = 100 / 529 := by norm_num
-- The doomed kit, -100, 150, -100, at 33⅓ percent: -175/4, that is -$43.75.
example : (-100 : ℚ) + 150 / (1 + 1 / 3) - 100 / (1 + 1 / 3) ^ 2 = -175 / 4 := by norm_num

#print axioms end_balance_is_npv_carried_forward
#print axioms one_outlay_then_inflows_has_exactly_one_irr
#print axioms worth_doing_iff_irr_beats_rate
