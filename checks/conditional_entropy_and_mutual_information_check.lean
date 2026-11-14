-- Conditional entropy and mutual information: for any joint table of chances on two finite readings, seeing one reading never raises the average uncertainty about the other (with no change exactly when they are independent), the pair's entropy splits by the chain rule, and the uncertainty removed is the same from either side.
import Mathlib.Analysis.SpecialFunctions.Log.Base
import Mathlib.Algebra.BigOperators.Ring.Finset
import Mathlib.Tactic

open Finset

namespace CondEntropyCard

variable {α β ι : Type*} [Fintype α] [Fintype β] [Fintype ι]

/-- Entropy in bits of a list of chances `q`: `H = -Σ q i · log₂ (q i)`.
(Mathlib's `Real.logb 2 0 = 0`, so empty cells add nothing, as on the card.) -/
noncomputable def entropy (q : ι → ℝ) : ℝ := -∑ i, q i * Real.logb 2 (q i)

/-- The chance of each value of the first reading `X`: the row sums of the joint table. -/
def margX (p : α × β → ℝ) (x : α) : ℝ := ∑ y, p (x, y)

/-- The chance of each value of the second reading `Y`: the column sums of the joint table. -/
def margY (p : α × β → ℝ) (y : β) : ℝ := ∑ x, p (x, y)

/-- `H(Y | X) = Σ_x P(X = x) · H(Y | X = x)`, where `H(Y | X = x)` is the entropy of the row of
`x` divided by its total, `P(Y = y | X = x) = P(X = x, Y = y) / P(X = x)`. -/
noncomputable def condEntYX (p : α × β → ℝ) : ℝ :=
  ∑ x, margX p x * entropy (fun y => p (x, y) / margX p x)

/-- `H(X | Y)`, the same with the roles of the two readings swapped. -/
noncomputable def condEntXY (p : α × β → ℝ) : ℝ :=
  ∑ y, margY p y * entropy (fun x => p (x, y) / margY p y)

/-- One row's share: `s · H(f / s) = -Σ f log f + s log s`, where `s` is the row total. -/
lemma row_term (f : β → ℝ) (hf : ∀ y, 0 ≤ f y) :
    (∑ y, f y) * entropy (fun y => f y / ∑ y, f y) =
      -∑ y, f y * Real.logb 2 (f y) + (∑ y, f y) * Real.logb 2 (∑ y, f y) := by
  have hs : 0 ≤ ∑ y, f y := Finset.sum_nonneg (fun y _ => hf y)
  rcases hs.eq_or_lt with h | h
  · have h0 : ∀ y, f y = 0 := fun y =>
      (Finset.sum_eq_zero_iff_of_nonneg (fun y _ => hf y)).1 h.symm y (Finset.mem_univ y)
    simp [h0]
  · unfold entropy
    generalize hS : ∑ y, f y = s at h ⊢
    have key : ∀ y, s * (f y / s * Real.logb 2 (f y / s)) =
        f y * Real.logb 2 (f y) - f y * Real.logb 2 s := by
      intro y
      rcases (hf y).eq_or_lt with hy | hy
      · simp [← hy]
      · rw [Real.logb_div hy.ne' h.ne']
        field_simp
    rw [mul_neg, Finset.mul_sum, Finset.sum_congr rfl (fun y _ => key y),
      Finset.sum_sub_distrib, ← Finset.sum_mul, hS]
    ring

/-- One cell: `p (log p - log a - log b) ≥ p - a b`, with equality exactly when `p = a b`. -/
lemma cell_bound (p a b : ℝ) (hp : 0 ≤ p) (ha : p ≤ a) (hb : p ≤ b) :
    0 ≤ p * (Real.log p - Real.log a - Real.log b) - (p - a * b) ∧
      (p * (Real.log p - Real.log a - Real.log b) - (p - a * b) = 0 ↔ p = a * b) := by
  rcases hp.eq_or_lt with h | h
  · subst h
    have hab : 0 ≤ a * b := mul_nonneg ha hb
    refine ⟨by simpa using hab, ?_⟩
    constructor
    · intro e; linarith
    · intro e; rw [← e]; simp
  · have ha' : 0 < a := lt_of_lt_of_le h ha
    have hb' : 0 < b := lt_of_lt_of_le h hb
    have ht : 0 < a * b / p := by positivity
    have hkey : Real.log p - Real.log a - Real.log b = -Real.log (a * b / p) := by
      rw [Real.log_div (by positivity) h.ne', Real.log_mul ha'.ne' hb'.ne']; ring
    have hexp : p * (Real.log p - Real.log a - Real.log b) - (p - a * b)
        = p * (a * b / p - 1 - Real.log (a * b / p)) := by
      rw [hkey]; field_simp; ring
    rw [hexp]
    have hle := Real.log_le_sub_one_of_pos ht
    refine ⟨mul_nonneg h.le (by linarith), ?_⟩
    constructor
    · intro e
      have e2 : a * b / p - 1 - Real.log (a * b / p) = 0 := by
        rcases mul_eq_zero.1 e with e3 | e3
        · exact absurd e3 h.ne'
        · exact e3
      by_contra hne
      have h1 : a * b / p ≠ 1 := by
        intro h1; apply hne; field_simp at h1; linarith
      have := Real.log_lt_sub_one_of_pos ht h1
      linarith
    · intro e
      have : a * b / p = 1 := by rw [← e]; exact div_self h.ne'
      rw [this]; simp

/-- The chain rule, `H(X, Y) = H(X) + H(Y | X)`. -/
lemma chain_aux (p : α × β → ℝ) (hp : ∀ z, 0 ≤ p z) :
    entropy p = entropy (margX p) + condEntYX p := by
  have h : ∀ x, margX p x * entropy (fun y => p (x, y) / margX p x) =
      -∑ y, p (x, y) * Real.logb 2 (p (x, y)) + margX p x * Real.logb 2 (margX p x) :=
    fun x => row_term (fun y => p (x, y)) (fun y => hp _)
  rw [condEntYX, Finset.sum_congr rfl (fun x _ => h x), Finset.sum_add_distrib]
  simp only [entropy]
  rw [Fintype.sum_prod_type, Finset.sum_neg_distrib]
  ring

/-- The chain rule the other way round, `H(X, Y) = H(Y) + H(X | Y)`. -/
lemma chain_aux' (p : α × β → ℝ) (hp : ∀ z, 0 ≤ p z) :
    entropy p = entropy (margY p) + condEntXY p := by
  have h : ∀ y, margY p y * entropy (fun x => p (x, y) / margY p y) =
      -∑ x, p (x, y) * Real.logb 2 (p (x, y)) + margY p y * Real.logb 2 (margY p y) :=
    fun y => row_term (fun x => p (x, y)) (fun x => hp _)
  rw [condEntXY, Finset.sum_congr rfl (fun y _ => h y), Finset.sum_add_distrib]
  simp only [entropy]
  rw [Fintype.sum_prod_type, Finset.sum_comm, Finset.sum_neg_distrib]
  ring

/-- `H(X) + H(Y) - H(X, Y)` as a sum of cell terms that are each at least zero. -/
lemma mi_formula (p : α × β → ℝ) (hsum : ∑ z, p z = 1) :
    entropy (margX p) + entropy (margY p) - entropy p =
      (∑ x, ∑ y, (p (x, y) * (Real.log (p (x, y)) - Real.log (margX p x) -
        Real.log (margY p y)) - (p (x, y) - margX p x * margY p y))) / Real.log 2 := by
  have h1 : ∑ x, ∑ y, p (x, y) = 1 := by rw [← Fintype.sum_prod_type']; exact hsum
  have hX : ∑ x, margX p x = 1 := h1
  have hY : ∑ y, margY p y = 1 := by
    unfold margY; rw [Finset.sum_comm]; exact h1
  have h2 : ∑ x, ∑ y, margX p x * margY p y = 1 := by
    rw [← Finset.sum_mul_sum, hX, hY, one_mul]
  have hA : ∑ x, margX p x * Real.logb 2 (margX p x) =
      ∑ x, ∑ y, p (x, y) * Real.logb 2 (margX p x) :=
    Finset.sum_congr rfl (fun x _ => Finset.sum_mul _ _ _)
  have hB : ∑ y, margY p y * Real.logb 2 (margY p y) =
      ∑ x, ∑ y, p (x, y) * Real.logb 2 (margY p y) := by
    rw [Finset.sum_comm]
    exact Finset.sum_congr rfl (fun y _ => Finset.sum_mul _ _ _)
  have hlhs : entropy (margX p) + entropy (margY p) - entropy p =
      ∑ x, ∑ y, p (x, y) * (Real.logb 2 (p (x, y)) - Real.logb 2 (margX p x) -
        Real.logb 2 (margY p y)) := by
    simp only [entropy]
    rw [hA, hB, Fintype.sum_prod_type]
    simp only [mul_sub, Finset.sum_sub_distrib]
    ring
  rw [hlhs]
  simp only [Finset.sum_sub_distrib]
  rw [h1, h2, sub_self, sub_zero, Finset.sum_div]
  refine Finset.sum_congr rfl (fun x _ => ?_)
  rw [Finset.sum_div]
  refine Finset.sum_congr rfl (fun y _ => ?_)
  simp only [Real.logb]
  ring

#print axioms row_term
#print axioms cell_bound
#print axioms chain_aux
#print axioms chain_aux'
#print axioms mi_formula

/-- `I(X; Y) = H(X) + H(Y) - H(X, Y) ≥ 0`, with equality exactly when `X` and `Y` are independent. -/
lemma mi_nonneg_iff (p : α × β → ℝ) (hp : ∀ z, 0 ≤ p z) (hsum : ∑ z, p z = 1) :
    0 ≤ entropy (margX p) + entropy (margY p) - entropy p ∧
      (entropy (margX p) + entropy (margY p) - entropy p = 0 ↔
        ∀ x y, p (x, y) = margX p x * margY p y) := by
  have hlog : 0 < Real.log 2 := Real.log_pos (by norm_num)
  have hcell : ∀ x y, 0 ≤ p (x, y) * (Real.log (p (x, y)) - Real.log (margX p x) -
        Real.log (margY p y)) - (p (x, y) - margX p x * margY p y) ∧
      (p (x, y) * (Real.log (p (x, y)) - Real.log (margX p x) -
        Real.log (margY p y)) - (p (x, y) - margX p x * margY p y) = 0 ↔
          p (x, y) = margX p x * margY p y) := fun x y =>
    cell_bound _ _ _ (hp _)
      (Finset.single_le_sum (f := fun y => p (x, y)) (fun y _ => hp _) (Finset.mem_univ y))
      (Finset.single_le_sum (f := fun x => p (x, y)) (fun x _ => hp _) (Finset.mem_univ x))
  rw [mi_formula p hsum]
  have hnn := fun x => Finset.sum_nonneg (s := Finset.univ) (fun y _ => (hcell x y).1)
  refine ⟨div_nonneg (Finset.sum_nonneg (fun x _ => hnn x)) hlog.le, ?_⟩
  rw [div_eq_zero_iff, or_iff_left hlog.ne', Finset.sum_eq_zero_iff_of_nonneg (fun x _ => hnn x)]
  simp only [Finset.mem_univ, true_implies]
  refine forall_congr' (fun x => ?_)
  rw [Finset.sum_eq_zero_iff_of_nonneg (fun y _ => (hcell x y).1)]
  simp only [Finset.mem_univ, true_implies]
  exact forall_congr' (fun y => (hcell x y).2)

#print axioms mi_nonneg_iff

/-- Conditioning never increases entropy. For any joint table of chances `p` on two readings
with finitely many values (each chance at least 0, all adding to 1), the uncertainty about `Y`
left after seeing `X`, averaged over the readings, is at most the uncertainty about `Y` with
nothing known: `H(Y | X) ≤ H(Y)`, that is `I(X; Y) ≥ 0`. Equality holds exactly when `X` and `Y`
are independent: every cell equals its row chance times its column chance. -/
theorem conditioning_never_increases_entropy (p : α × β → ℝ) (hp : ∀ z, 0 ≤ p z)
    (hsum : ∑ z, p z = 1) :
    condEntYX p ≤ entropy (margY p) ∧
      (condEntYX p = entropy (margY p) ↔ ∀ x y, p (x, y) = margX p x * margY p y) := by
  have hc := chain_aux p hp
  obtain ⟨h1, h2⟩ := mi_nonneg_iff p hp hsum
  refine ⟨by linarith, ?_⟩
  rw [← h2]
  constructor <;> intro e <;> linarith

/-- The chain rule: the uncertainty of the pair is the uncertainty of the first reading plus
what is still uncertain about the second once the first is known, `H(X, Y) = H(X) + H(Y | X)`. -/
theorem chain_rule (p : α × β → ℝ) (hp : ∀ z, 0 ≤ p z) (hsum : ∑ z, p z = 1) :
    entropy p = entropy (margX p) + condEntYX p := by
  exact chain_aux p hp

/-- Mutual information is the same from either side: the drop `H(Y) - H(Y | X)` equals the drop
`H(X) - H(X | Y)`, and both equal `H(X) + H(Y) - H(X, Y)`. -/
theorem mutual_information_symmetric (p : α × β → ℝ) (hp : ∀ z, 0 ≤ p z)
    (hsum : ∑ z, p z = 1) :
    entropy (margY p) - condEntYX p = entropy (margX p) - condEntXY p ∧
      entropy (margY p) - condEntYX p = entropy (margX p) + entropy (margY p) - entropy p := by
  have hc := chain_aux p hp
  have hc' := chain_aux' p hp
  constructor <;> linarith

end CondEntropyCard

open CondEntropyCard

-- The card's whole-number checks.
-- The 100 mornings: rows falling 16 + 9, steady 11 + 34, rising 3 + 27; 30 rainy mornings in all.
example : 16 + 9 = 25 ∧ 11 + 34 = 45 ∧ 3 + 27 = 30 ∧ 25 + 45 + 30 = 100 ∧ 16 + 11 + 3 = 30 := by
  decide
-- Step 1: the chance of falling and rain splits as 16/100 = 25/100 × 16/25.
example : (16 / 100 : ℚ) = 25 / 100 * (16 / 25) := by norm_num
-- Try changing: the useless barometer [6, 14], [15, 35], [9, 21] (rows 20, 50, 30; columns 30, 70
-- out of 100) has every cell equal to row total × column total ÷ 100, so it is independent.
example : 6 * 100 = 20 * 30 ∧ 14 * 100 = 20 * 70 ∧ 15 * 100 = 50 * 30 ∧ 35 * 100 = 50 * 70 ∧
    9 * 100 = 30 * 30 ∧ 21 * 100 = 30 * 70 := by decide

#print axioms conditioning_never_increases_entropy
#print axioms chain_rule
#print axioms mutual_information_symmetric
