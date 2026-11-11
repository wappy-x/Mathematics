-- Vectors: in R^n, written as lists of n real numbers, adding two vectors adds matching slots and scaling multiplies every slot, scaling by a whole number k is adding the vector to itself k times, the all-zeros vector changes nothing and scaling by -1 gives the vector that cancels it, and the cyclist's numbers come out as the card says.
import Mathlib.Algebra.Group.Fin.Tuple
import Mathlib.Algebra.BigOperators.Group.List.Basic
import Mathlib.Basic.Real.Basic
import Mathlib.Data.Fin.VecNotation
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith

/-! A vector in R^n is a list of `n` real numbers, one in each slot `0, 1, …, n - 1`.
Lean writes that as a function `Fin n → ℝ`: slot `i` holds `u i`. The card's "both lists
are the same length" is built into the type: `u` and `v` both have `n` slots. The scalar `a`
is one real number. `![3, 4]` is the list (3, 4). -/

/-- The card's main claim. For every length `n`, every two vectors `u`, `v` in R^n and every
plain number `a`: the sum `u + v` is exactly the list whose slot `i` holds `u i + v i`, and the
scaled vector `a u` is exactly the list whose slot `i` holds `a × u i`. Add by adding matching
slots; scale by multiplying every slot by the same number. -/
theorem vector_add_and_scale_slot_by_slot (n : ℕ) (u v : Fin n → ℝ) (a : ℝ) :
    (∀ w : Fin n → ℝ, w = u + v ↔ ∀ i, w i = u i + v i) ∧
      (∀ w : Fin n → ℝ, w = a • u ↔ ∀ i, w i = a * u i) := by
  refine ⟨fun w => ⟨fun h i => by rw [h]; rfl, fun h => funext fun i => h i⟩,
    fun w => ⟨fun h i => by rw [h]; rfl, fun h => funext fun i => h i⟩⟩

/-- Scaling by a whole number is repeated adding: for every vector `u` in R^n and every whole
number `k`, the vector `k u` equals `u + u + ⋯ + u` with `k` copies of `u` (the sum of an empty
list is the zero vector). Riding the same leg twice is `2 u`. -/
theorem scale_by_whole_number_is_repeated_adding (n : ℕ) (u : Fin n → ℝ) (k : ℕ) :
    (k : ℝ) • u = (List.replicate k u).sum := by
  rw [List.sum_replicate]; funext i; simp [nsmul_eq_mul]

/-- Nothing, and the opposite of something. For every vector `u` in R^n: scaling by 0 gives the
all-zeros vector; adding the all-zeros vector to `u` gives `u` back; and adding `u` scaled by
`-1` to `u` gives the all-zeros vector. -/
theorem zero_vector_and_opposite (n : ℕ) (u : Fin n → ℝ) :
    (0 : ℝ) • u = (fun _ => 0) ∧ u + (fun _ => 0) = u ∧ u + (-1 : ℝ) • u = (fun _ => 0) := by
  refine ⟨?_, ?_, ?_⟩ <;> funext i <;> simp

-- The two legs added: (3, 4) + (2, -1) = (5, 3).
example : (![3, 4] : Fin 2 → ℝ) + ![2, -1] = ![5, 3] := by norm_num
-- The same ride walked 1 km at a time: 3 east, 4 north, 2 east, 1 south.
example : (List.replicate 3 ![1, 0] ++ List.replicate 4 ![0, 1] ++ List.replicate 2 ![1, 0]
    ++ [![0, -1]] : List (Fin 2 → ℝ)).sum = ![5, 3] := by norm_num
-- The first leg ridden twice, by scaling and by adding: 2 × (3, 4) = (3, 4) + (3, 4) = (6, 8).
example : (2 : ℝ) • (![3, 4] : Fin 2 → ℝ) = ![6, 8] := by norm_num
example : (![3, 4] : Fin 2 → ℝ) + ![3, 4] = ![6, 8] := by norm_num
-- Never left the shop: 0 × (3, 4) = (0, 0), and (3, 4) + (0, 0) = (3, 4).
example : (0 : ℝ) • (![3, 4] : Fin 2 → ℝ) = ![0, 0] := by
  norm_num [funext_iff, Fin.forall_fin_two]
example : (![3, 4] : Fin 2 → ℝ) + ![0, 0] = ![3, 4] := by norm_num
-- The undo: (3, 4) + (-1) × (3, 4) = (0, 0), and (-1) × (3, 4) = (-3, -4).
example : (-1 : ℝ) • (![3, 4] : Fin 2 → ℝ) = ![-3, -4] := by norm_num
example : (![3, 4] : Fin 2 → ℝ) + (-1 : ℝ) • ![3, 4] = ![0, 0] := by norm_num
-- A week of rides in R^4: (12, 9, 15, 11) + (3, 4, 2, 6) = (15, 13, 17, 17).
example : (![12, 9, 15, 11] : Fin 4 → ℝ) + ![3, 4, 2, 6] = ![15, 13, 17, 17] := by norm_num
-- Mistake 1: adding all four numbers into one total gives 8.
example : (3 : ℝ) + 4 + 2 + (-1) = 8 := by norm_num
-- Mistake 2: multiplying slot by slot gives (6, -4), which is not (3, 4) scaled by any number.
example : (![3, 4] : Fin 2 → ℝ) * ![2, -1] = ![6, -4] := by
  norm_num [funext_iff, Fin.forall_fin_two]
example : ¬ ∃ a : ℝ, a • (![3, 4] : Fin 2 → ℝ) = ![6, -4] := by
  norm_num [funext_iff, Fin.forall_fin_two]
  intro a h1 h2
  linarith
-- Mistake 3: doubling only the first number gives (6, 4), which is not 2 × (3, 4).
example : (![2 * 3, 4] : Fin 2 → ℝ) ≠ (2 : ℝ) • ![3, 4] := by
  norm_num [funext_iff, Fin.forall_fin_two]

#print axioms vector_add_and_scale_slot_by_slot
#print axioms scale_by_whole_number_is_repeated_adding
#print axioms zero_vector_and_opposite
