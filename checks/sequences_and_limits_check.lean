-- Sequences: a real sequence that never steps down and stays under a ceiling heads for its least upper bound, the shares 1/n head for 0 with any whole number at least 1/t as the cutoff for tolerance t, and the climb c(n+1) = sqrt(2 + c(n)) from 0 rises, stays below 2 and heads for 2.
import Mathlib.Topology.Order.MonotoneConvergence
import Mathlib.Topology.Instances.Real.Lemmas
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Algebra.Order.Floor.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open Filter Topology

/-- Monotone convergence. A list of real numbers that never steps down
(a 1 ≤ a 2 ≤ a 3 ≤ ...) and never passes a ceiling B heads for its least upper bound,
the supremum of its terms. -/
theorem monotone_bounded_sequence_tends_to_its_sup (a : ℕ → ℝ) (B : ℝ)
    (h_up : ∀ n, a n ≤ a (n + 1)) (h_ceiling : ∀ n, a n ≤ B) :
    Tendsto a atTop (𝓝 (sSup (Set.range a))) := by
  have hmono : Monotone a := monotone_nat_of_le_succ h_up
  have hbdd : BddAbove (Set.range a) := ⟨B, by rintro _ ⟨n, rfl⟩; exact h_ceiling n⟩
  exact tendsto_atTop_ciSup hmono hbdd

/-- The shares head for 0, in the card's tolerance-and-cutoff form: for every tolerance t > 0,
any whole number N at least 1/t is a cutoff, so every share 1/n with n past N is closer to 0
than t. -/
theorem shares_one_over_n_tend_to_zero (t : ℝ) (ht : 0 < t) (N : ℕ) (hN : 1 / t ≤ N) :
    ∀ n : ℕ, N < n → |1 / (n : ℝ) - 0| < t := by
  intro n hn
  have h1t : 0 < 1 / t := by positivity
  have hNpos : (0 : ℝ) < N := lt_of_lt_of_le h1t hN
  have hnN : (N : ℝ) < n := by exact_mod_cast hn
  have hnpos : (0 : ℝ) < n := lt_trans hNpos hnN
  have hlt : 1 / t < n := lt_of_le_of_lt hN hnN
  rw [sub_zero, abs_of_pos (by positivity)]
  rw [div_lt_iff₀ hnpos]
  rw [div_lt_iff₀ ht] at hlt
  linarith [mul_comm t (n : ℝ)]

/-- The climb: start at 0 and make each next term the square root of 2 plus the last.
(The card counts from place 1; here place 1 is index 0.) -/
noncomputable def climb : ℕ → ℝ
  | 0 => 0
  | n + 1 => Real.sqrt (2 + climb n)

/-- The climb steps up at every place, stays below 2 at every place, and heads for 2. -/
theorem climb_rises_stays_below_two_and_tends_to_two :
    (∀ n, climb n < climb (n + 1)) ∧ (∀ n, climb n < 2) ∧
      Tendsto climb atTop (𝓝 2) := by
  have hnn : ∀ n, 0 ≤ climb n := by
    intro n
    cases n with
    | zero => simp [climb]
    | succ n => simp only [climb]; exact Real.sqrt_nonneg _
  have hlt2 : ∀ n, climb n < 2 := by
    intro n
    induction n with
    | zero => simp [climb]
    | succ n ih =>
      simp only [climb]
      rw [Real.sqrt_lt' (by norm_num)]
      linarith
  have hup : ∀ n, climb n < climb (n + 1) := by
    intro n
    show climb n < Real.sqrt (2 + climb n)
    rw [Real.lt_sqrt (hnn n)]
    nlinarith [hnn n, hlt2 n]
  refine ⟨hup, hlt2, ?_⟩
  have hmono : Monotone climb := monotone_nat_of_le_succ (fun n => (hup n).le)
  have hbdd : BddAbove (Set.range climb) := ⟨2, by rintro _ ⟨n, rfl⟩; exact (hlt2 n).le⟩
  have hL := tendsto_atTop_ciSup hmono hbdd
  set L := ⨆ n, climb n with hLdef
  have hL0 : 0 ≤ L := le_trans (hnn 0) (le_ciSup hbdd 0)
  have h1 : Tendsto (fun n => climb (n + 1)) atTop (𝓝 L) :=
    hL.comp (tendsto_add_atTop_nat 1)
  have h2 : Tendsto (fun n => climb (n + 1)) atTop (𝓝 (Real.sqrt (2 + L))) := by
    have : Tendsto (fun n => Real.sqrt (2 + climb n)) atTop (𝓝 (Real.sqrt (2 + L))) :=
      ((Real.continuous_sqrt.comp (continuous_const.add continuous_id)).tendsto L).comp hL
    simpa [climb] using this
  have heq : L = Real.sqrt (2 + L) := tendsto_nhds_unique h1 h2
  have hsq : L ^ 2 = 2 + L := by
    have h := Real.sq_sqrt (show 0 ≤ 2 + L by linarith)
    rw [← heq] at h
    exact h
  have : (L - 2) * (L + 1) = 0 := by nlinarith
  rcases mul_eq_zero.mp this with h | h
  · have : L = 2 := by linarith
    rw [this] at hL
    exact hL
  · linarith

-- Tolerance 1/10: term 10 equals the tolerance (not below), term 11 is inside.
example : ¬ ((1 : ℚ) / 10 < 1 / 10) := by norm_num
example : (1 : ℚ) / 11 < 1 / 10 := by norm_num
-- The cutoff is the whole part of 1/t: 10 for 1/10, 100 for 1/100, 333 for 3/1000.
example : ⌊(1 : ℚ) / (1 / 10)⌋ = 10 := by norm_num
example : ⌊(1 : ℚ) / (1 / 100)⌋ = 100 := by norm_num
example : ⌊(1 : ℚ) / (3 / 1000)⌋ = 333 := by norm_num
example : 10 / 1 = 10 ∧ 100 / 1 = 100 ∧ 1000 / 3 = 333 := by decide
-- The fraction (x^2 - 1)/(x - 1) at x = 1 + 1/11 is off 2 by exactly 1/11.
example : (((1 + 1 / 11 : ℚ) ^ 2 - 1) / ((1 + 1 / 11) - 1)) - 2 = 1 / 11 := by norm_num
-- Bounded is not convergent: (-1)^n at places 101 and 102 gives -1 and 1, a gap of 2.
example : (-1 : ℤ) ^ 101 = -1 ∧ (-1 : ℤ) ^ 102 = 1 ∧ (1 : ℤ) - (-1) = 2 := by decide
-- Never steps down: the next climb term beats c exactly when 2 + c - c^2 = (2 - c)(1 + c) > 0.
example (c : ℝ) : 2 + c - c ^ 2 = (2 - c) * (1 + c) := by ring
-- L * L = 2 + L has roots 2 and -1.
example : (2 : ℤ) * 2 = 2 + 2 ∧ (-1 : ℤ) * (-1) = 2 + (-1) := by decide
-- Solving before proving: doubling from 1, the twentieth term is 2^19 = 524288.
example : (2 : ℕ) ^ 19 = 524288 := by norm_num
-- Doubling-block bound for 1 + 1/2 + ... + 1/1024: 1 + 10/2 = 6.
example : (1 : ℚ) + 10 / 2 = 6 := by norm_num

#print axioms monotone_bounded_sequence_tends_to_its_sup
#print axioms shares_one_over_n_tend_to_zero
#print axioms climb_rises_stays_below_two_and_tends_to_two
