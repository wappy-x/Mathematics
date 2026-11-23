-- Approximation: splitting numbers into two equal halves is the same as covering their shifts with two people capped at half the total, so the fewest staff is at most 2 or at least 3, and that gap lets any method with ratio below 3/2 decide the split question.
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.IntervalCases

open Finset

/-- A plan with k people for shifts of lengths x and an hours cap C: a person f i for every
shift i, such that the shifts given to each person j total at most C hours. -/
def IsPlan {n : ℕ} (x : Fin n → ℕ) (C k : ℕ) (f : Fin n → Fin k) : Prop :=
  ∀ j : Fin k, ∑ i ∈ univ.filter (fun i => f i = j), x i ≤ C

/-- The gap reduction from PARTITION. Turn each number x_i into a shift of that length and set
the cap C to half the total. Then the shifts can be covered by at most 2 people exactly when the
numbers split into two groups with equal totals. So a yes-list gives a rota whose fewest staff is
at most 2, and a no-list gives one whose fewest staff is at least 3. -/
theorem two_staff_iff_equal_split {n : ℕ} (x : Fin n → ℕ) (C : ℕ) (hC : ∑ i, x i = 2 * C) :
    (∃ k ≤ 2, ∃ f : Fin n → Fin k, IsPlan x C k f) ↔
      ∃ S : Finset (Fin n), ∑ i ∈ S, x i = ∑ i ∈ Sᶜ, x i := by
  constructor
  · rintro ⟨k, hk, f, hf⟩
    have key : ∀ j : ℕ, ∑ i ∈ univ.filter (fun i => (f i).val = j), x i ≤ C := by
      intro j
      by_cases hj : j < k
      · have : univ.filter (fun i => (f i).val = j) = univ.filter (fun i => f i = ⟨j, hj⟩) := by
          ext i; simp [Fin.ext_iff]
        rw [this]; exact hf ⟨j, hj⟩
      · have : univ.filter (fun i => (f i).val = j) = ∅ := by
          ext i; simp only [mem_filter, mem_univ, true_and, Finset.notMem_empty, iff_false]
          have := (f i).isLt; omega
        rw [this]; simp
    refine ⟨univ.filter (fun i => (f i).val = 0), ?_⟩
    have hc : (univ.filter (fun i => (f i).val = 0))ᶜ = univ.filter (fun i => (f i).val = 1) := by
      ext i; simp only [mem_compl, mem_filter, mem_univ, true_and]
      have := (f i).isLt; omega
    have hsplit := Finset.sum_add_sum_compl (univ.filter (fun i => (f i).val = 0)) x
    rw [hc] at hsplit ⊢
    have h0 := key 0
    have h1 := key 1
    omega
  · rintro ⟨S, hS⟩
    refine ⟨2, le_refl _, fun i => if i ∈ S then 0 else 1, ?_⟩
    have hsplit := Finset.sum_add_sum_compl S x
    intro j
    fin_cases j
    · have : univ.filter (fun i => (if i ∈ S then (0 : Fin 2) else 1) = 0) = S := by
        ext i; by_cases hi : i ∈ S <;> simp [hi]
      simp only [Fin.zero_eta, Fin.isValue]
      rw [this]; omega
    · have : univ.filter (fun i => (if i ∈ S then (0 : Fin 2) else 1) = 1) = Sᶜ := by
        ext i; by_cases hi : i ∈ S <;> simp [hi]
      simp only [Fin.mk_one, Fin.isValue]
      rw [this]; omega

/-- The gap rule. Suppose every yes-input has fewest OPT ≤ a and every no-input has OPT ≥ b, and
a method with ratio ρ always answers ALG with OPT ≤ ALG ≤ ρ × OPT. If ρ × a < b, the method's
answer alone decides the question: it answers below b exactly on the yes-inputs. -/
theorem gap_rule_decides (yes : Prop) (a b OPT ALG : ℕ) (ρ : ℝ) (hρ : 0 ≤ ρ)
    (hgap : ρ * a < b) (hlow : OPT ≤ ALG) (hhigh : (ALG : ℝ) ≤ ρ * OPT)
    (hyes : yes → OPT ≤ a) (hno : ¬ yes → b ≤ OPT) :
    ALG < b ↔ yes := by
  by_cases hy : yes
  · simp only [hy, iff_true]
    have h1 : (OPT : ℝ) ≤ a := by exact_mod_cast hyes hy
    have h2 : (ALG : ℝ) < b := by nlinarith
    exact_mod_cast h2
  · simp only [hy, iff_false, not_lt]
    exact le_trans (hno hy) hlow

/-- FFD's ceiling, rounded to whole people, is at most 1.5 times the fewest: if a whole number of
staff ALG is at most 11/9 × OPT + 6/9, then ALG ≤ 3/2 × OPT. -/
theorem ffd_ceiling_le_three_halves (ALG OPT : ℕ)
    (h : (ALG : ℝ) ≤ 11 / 9 * OPT + 6 / 9) :
    (ALG : ℝ) ≤ 3 / 2 * OPT := by
  have h9 : 9 * ALG ≤ 11 * OPT + 6 := by
    have : (9 * ALG : ℝ) ≤ 11 * OPT + 6 := by linarith
    exact_mod_cast this
  have h2 : 2 * ALG ≤ 3 * OPT := by
    rcases Nat.lt_or_ge OPT 3 with hO | hO
    · interval_cases OPT <;> omega
    · omega
  have : (2 * ALG : ℝ) ≤ 3 * OPT := by exact_mod_cast h2
  linarith

-- The care home's week: shifts of 12, 12, 12, 10, 10, 10, 8 and 6 hours, 80 hours in all.
example : ∑ i, (![12, 12, 12, 10, 10, 10, 8, 6] : Fin 8 → ℕ) i = 80 := by decide

-- The floor from hours: 80 / 40, rounded up, is 2.
example : (80 + 40 - 1) / 40 = 2 := by norm_num

-- The equal split: 12 + 10 + 10 + 8 against 12 + 12 + 10 + 6, 40 hours each.
example : ∑ i ∈ ({0, 3, 4, 6} : Finset (Fin 8)), (![12, 12, 12, 10, 10, 10, 8, 6] : Fin 8 → ℕ) i
    = ∑ i ∈ ({0, 3, 4, 6} : Finset (Fin 8))ᶜ, (![12, 12, 12, 10, 10, 10, 8, 6] : Fin 8 → ℕ) i := by
  decide +kernel

-- The best plan: 2 people, each exactly within the 40-hour cap.
example : IsPlan (![12, 12, 12, 10, 10, 10, 8, 6] : Fin 8 → ℕ) 40 2 ![0, 1, 1, 0, 0, 1, 0, 1] := by
  unfold IsPlan; decide

-- FFD's plan: 12, 12, 12 to person 1 (36); 10, 10, 10, 8 to person 2 (38); 6 to person 3.
example : IsPlan (![12, 12, 12, 10, 10, 10, 8, 6] : Fin 8 → ℕ) 40 3 ![0, 0, 0, 1, 1, 1, 1, 2] := by
  unfold IsPlan; decide

-- The no-split week: five 12s and two 10s, 80 hours, but no group makes 40, so 2 staff cannot do.
example : ∑ i, (![12, 12, 12, 12, 12, 10, 10] : Fin 7 → ℕ) i = 80 := by decide
example : ¬ ∃ S : Finset (Fin 7), ∑ i ∈ S, (![12, 12, 12, 12, 12, 10, 10] : Fin 7 → ℕ) i
    = ∑ i ∈ Sᶜ, (![12, 12, 12, 12, 12, 10, 10] : Fin 7 → ℕ) i := by
  decide +kernel

-- The ceilings at OPT = 2: First Fit 2 × 2 = 4, FFD (11 × 2 + 6) / 9 = 28/9 rounded down = 3.
example : 2 * 2 = 4 := by norm_num
example : (11 * 2 + 6) / 9 = 3 := by norm_num
example : 3 * 2 = 2 * 3 := by norm_num

-- Ten copies of the week: fewest 20, FFD 22, ceiling (11 × 20 + 6) / 9 rounded down = 25.
example : (11 * 20 + 6) / 9 = 25 := by norm_num
example : (22 : ℚ) / 20 = 11 / 10 := by norm_num

#print axioms two_staff_iff_equal_split
#print axioms gap_rule_decides
#print axioms ffd_ceiling_le_three_halves
