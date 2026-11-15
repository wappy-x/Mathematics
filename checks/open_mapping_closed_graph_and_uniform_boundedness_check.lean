-- Three Banach theorems: in complete normed spaces, a bounded linear map onto covers a ball and has a bounded inverse when one-to-one, a linear map with a closed graph is bounded, and a family bounded at each input has one common bound.
import Mathlib.Analysis.Normed.Operator.Banach
import Mathlib.Analysis.Normed.Operator.BanachSteinhaus

open Metric

/-- Open mapping and bounded inverse. Let `X` and `Y` be real Banach spaces and `T : X → Y`
a bounded linear map onto `Y`. Then the image of the unit ball of `X` holds a whole ball
`B_Y(δ)` about zero for some `δ > 0`; and if also `ker T = {0}`, the inverse is bounded by
`1/δ`: every input `x` has `‖x‖ ≤ (1/δ) ‖T x‖`. -/
theorem open_mapping_and_bounded_inverse
    {X Y : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X] [CompleteSpace X]
    [NormedAddCommGroup Y] [NormedSpace ℝ Y] [CompleteSpace Y]
    (T : X →L[ℝ] Y) (hT : Function.Surjective T) :
    ∃ δ > 0, ball (0 : Y) δ ⊆ T '' ball (0 : X) 1 ∧
      (LinearMap.ker (T : X →ₗ[ℝ] Y) = ⊥ → ∀ x : X, ‖x‖ ≤ (1 / δ) * ‖T x‖) := by
  obtain ⟨C, C0, hC⟩ := ContinuousLinearMap.exists_preimage_norm_le T hT
  refine ⟨1 / C, by positivity, ?_, ?_⟩
  · intro y hy
    rw [mem_ball_zero_iff] at hy
    obtain ⟨x, hx, hxn⟩ := hC y
    refine ⟨x, ?_, hx⟩
    rw [mem_ball_zero_iff]
    calc ‖x‖ ≤ C * ‖y‖ := hxn
      _ < C * (1 / C) := mul_lt_mul_of_pos_left hy C0
      _ = 1 := by field_simp
  · intro hker x
    obtain ⟨x', hx', hxn⟩ := hC (T x)
    have hinj : Function.Injective (T : X →ₗ[ℝ] Y) := LinearMap.ker_eq_bot.mp hker
    have : x' = x := hinj hx'
    subst this
    simpa using hxn

/-- Closed graph. Let `X` and `Y` be real Banach spaces and `T : X → Y` a linear map defined on
all of `X` whose graph `{(x, T x)}` is closed in `X × Y`. Then `T` is bounded: some constant `C`
has `‖T x‖ ≤ C ‖x‖` for every `x`. -/
theorem closed_graph_linear_map_is_bounded
    {X Y : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X] [CompleteSpace X]
    [NormedAddCommGroup Y] [NormedSpace ℝ Y] [CompleteSpace Y]
    (T : X →ₗ[ℝ] Y) (hG : IsClosed (T.graph : Set (X × Y))) :
    ∃ C : ℝ, ∀ x : X, ‖T x‖ ≤ C * ‖x‖ := by
  refine ⟨‖ContinuousLinearMap.ofIsClosedGraph hG‖, fun x => ?_⟩
  have := (ContinuousLinearMap.ofIsClosedGraph hG).le_opNorm x
  simpa using this

/-- Uniform boundedness. Let `X` be a real Banach space, `Y` a real normed space and `T α` a
family of bounded linear maps from `X` to `Y`. If the family stays bounded at each single input
(`sup_α ‖T α x‖ < ∞` for every `x`), then the gains share one bound: `sup_α ‖T α‖ < ∞`. -/
theorem uniform_boundedness_principle
    {X Y ι : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X] [CompleteSpace X]
    [NormedAddCommGroup Y] [NormedSpace ℝ Y]
    (T : ι → X →L[ℝ] Y) (h : ∀ x : X, BddAbove (Set.range fun α => ‖T α x‖)) :
    BddAbove (Set.range fun α => ‖T α‖) := by
  obtain ⟨C, hC⟩ := banach_steinhaus (g := T) (fun x => by
    obtain ⟨B, hB⟩ := h x
    exact ⟨B, fun i => hB ⟨i, rfl⟩⟩)
  exact ⟨C, by rintro _ ⟨i, rfl⟩; exact hC i⟩

-- The list of 1000 ones: max norm 1, sum norm 1000, so the inverse gain is 1000.
example : (Finset.range 1000).sup (fun _ => (1 : ℕ)) = 1 := by norm_num [Finset.sup_const]
example : ∑ _k ∈ Finset.range 1000, (1 : ℕ) = 1000 := by norm_num

-- f_k(x) = k x_k: at (1/2, -1/4, 1/8) the largest |f_k(x)| is 1/2.
example : max (max |1 * (1 / 2 : ℚ)| |2 * (-1 / 4 : ℚ)|) |3 * (1 / 8 : ℚ)| = 1 / 2 := by norm_num

-- At ten ones the largest |f_k(x)| = k is 10; at e_k the reading f_k(e_k) is k for k = 1, 10, 100.
example : (Finset.Icc 1 10).sup (fun k : ℕ => k * 1) = 10 := by decide
example : ∀ k ∈ ({1, 10, 100} : Finset ℕ),
    k * (fun i : ℕ => if i = k then 1 else 0) k = k := by decide

#print axioms open_mapping_and_bounded_inverse
#print axioms closed_graph_linear_map_is_bounded
#print axioms uniform_boundedness_principle
