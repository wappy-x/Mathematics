-- Hydrogen in outline: the radial series stops only for a whole shell number n above l, it then has n - l - 1 terms after the first, and the quantum numbers give shell n exactly n² states.
import Mathlib.Basic.Real.Basic
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Order.Interval.Finset.Defs
import Mathlib.Data.Int.Interval
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Algebra.BigOperators.Group.Finset.Sigma
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Positivity

/-- The radial series of Step 4, with r in Bohr radii: term 0 is 1, and term k + 1 is term k
times 2 (k + l + 1 - ν) / (ν (k + 1) (k + 2l + 2)). Here ν is the trial shell number, any
positive real number, and l is the orbital number. -/
noncomputable def radialCoeff (ν : ℝ) (l : ℕ) : ℕ → ℝ
  | 0 => 1
  | k + 1 => radialCoeff ν l k *
      (2 * ((k : ℝ) + l + 1 - ν) / (ν * ((k : ℝ) + 1) * ((k : ℝ) + 2 * l + 2)))

/-- The states of shell n: pairs (l, m) with l = 0, 1, …, n - 1 and m = -l, …, l. -/
def shellStates (n : ℕ) : Finset (Σ _ : ℕ, ℤ) :=
  (Finset.range n).sigma fun l => Finset.Icc (-(l : ℤ)) l

/-- Helper: for ν ≠ 0, term k of the radial series is zero exactly when some earlier
numerator factor j + l + 1 - ν (with j < k) is zero. -/
theorem radialCoeff_eq_zero_iff (ν : ℝ) (hν : ν ≠ 0) (l : ℕ) (k : ℕ) :
    radialCoeff ν l k = 0 ↔ ∃ j : ℕ, j < k ∧ (j : ℝ) + l + 1 = ν := by
  induction k with
  | zero => simp [radialCoeff]
  | succ k ih =>
    have h1 : ((k : ℝ) + 1) ≠ 0 := by positivity
    have h2 : ((k : ℝ) + 2 * l + 2) ≠ 0 := by positivity
    rw [radialCoeff, mul_eq_zero, ih, div_eq_zero_iff]
    simp only [mul_eq_zero, hν, h1, h2, or_false, OfNat.ofNat_ne_zero, false_or, sub_eq_zero]
    constructor
    · rintro (⟨j, hj, e⟩ | e)
      · exact ⟨j, by omega, e⟩
      · exact ⟨k, by omega, e⟩
    · rintro ⟨j, hj, e⟩
      rcases Nat.lt_succ_iff_lt_or_eq.mp hj with hj | rfl
      · exact Or.inl ⟨j, hj, e⟩
      · exact Or.inr e

#print axioms radialCoeff_eq_zero_iff

/-- The series must stop: for a trial shell number ν > 0 and any orbital number l, the radial
series has only finitely many nonzero terms exactly when ν is a whole number n with n > l
(that is, n at least l + 1). -/
theorem radial_series_stops_iff_whole_n_above_l (ν : ℝ) (hν : 0 < ν) (l : ℕ) :
    (∃ K : ℕ, ∀ k, K ≤ k → radialCoeff ν l k = 0) ↔ ∃ n : ℕ, l < n ∧ ν = n := by
  constructor
  · rintro ⟨K, hK⟩
    obtain ⟨j, -, e⟩ := (radialCoeff_eq_zero_iff ν hν.ne' l K).mp (hK K le_rfl)
    exact ⟨j + l + 1, by omega, by rw [← e]; push_cast; ring⟩
  · rintro ⟨n, hn, rfl⟩
    obtain ⟨j, rfl⟩ := Nat.exists_eq_add_of_lt hn
    refine ⟨j + 1, fun k hk => (radialCoeff_eq_zero_iff _ hν.ne' l k).mpr ⟨j, by omega, ?_⟩⟩
    push_cast; ring

/-- When n is a whole number above l, the radial series is a polynomial with n - l - 1 terms
after the first: term k is zero exactly when k is larger than n - l - 1. -/
theorem radial_series_has_n_sub_l_sub_one_terms_after_first (n l : ℕ) (h : l < n) (k : ℕ) :
    radialCoeff n l k = 0 ↔ n - l - 1 < k := by
  have hn : ((n : ℕ) : ℝ) ≠ 0 := by exact_mod_cast (show n ≠ 0 by omega)
  rw [radialCoeff_eq_zero_iff _ hn]
  constructor
  · rintro ⟨j, hj, e⟩
    have e' : j + l + 1 = n := by exact_mod_cast e
    omega
  · intro hk
    exact ⟨n - l - 1, by omega, by
      have : n - l - 1 + l + 1 = n := by omega
      exact_mod_cast this⟩

/-- Counting states: with l from 0 to n - 1 and m from -l to l, shell n has n² states. -/
theorem shell_has_n_sq_states (n : ℕ) : (shellStates n).card = n ^ 2 := by
  rw [shellStates, Finset.card_sigma]
  have : ∀ l : ℕ, (Finset.Icc (-(l : ℤ)) l).card = 2 * l + 1 := by
    intro l
    rw [Int.card_Icc]
    omega
  simp only [this]
  induction n with
  | zero => simp
  | succ n ih => rw [Finset.sum_range_succ, ih]; ring

-- Step 4's checks: n = 2, l = 0 gives 1 - 0.5 r; n = 3, l = 0 gives 1 - (2/3) r + (2/27) r²;
-- n = 3, l = 1 gives 1 - (1/6) r.
example : radialCoeff 2 0 1 = -1 / 2 := by norm_num [radialCoeff]
example : radialCoeff 2 0 2 = 0 := by norm_num [radialCoeff]
example : radialCoeff 3 0 1 = -2 / 3 := by norm_num [radialCoeff]
example : radialCoeff 3 0 2 = 2 / 27 := by norm_num [radialCoeff]
example : radialCoeff 3 1 1 = -1 / 6 := by norm_num [radialCoeff]
example : radialCoeff 3 1 2 = 0 := by norm_num [radialCoeff]

-- Step 5: shells 1 to 4 hold 1, 4, 9, 16 states; with spin, 2, 8, 18, 32 electrons.
example : (shellStates 1).card = 1 := by decide
example : (shellStates 2).card = 4 := by decide
example : (shellStates 3).card = 9 := by decide
example : (shellStates 4).card = 16 := by decide
example : (2 * (shellStates 1).card, 2 * (shellStates 2).card,
    2 * (shellStates 3).card, 2 * (shellStates 4).card) = (2, 8, 18, 32) := by decide

-- The red line, 3 to 2, gives up 1/4 - 1/9 = 5/36 of the energy unit; the wrong 1/n rule
-- would give 1/2 - 1/3 = 1/6.
example : (1 : ℚ) / 2 ^ 2 - 1 / 3 ^ 2 = 5 / 36 := by norm_num
example : (1 : ℚ) / 2 - 1 / 3 = 1 / 6 := by norm_num

#print axioms radial_series_stops_iff_whole_n_above_l
#print axioms radial_series_has_n_sub_l_sub_one_terms_after_first
#print axioms shell_has_n_sq_states
