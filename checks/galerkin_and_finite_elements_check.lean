-- Galerkin: for a bounded coercive form, the Galerkin error is perpendicular to every chosen shape, is at most M over alpha times the error of any chosen shape, and in the symmetric case is exactly the smallest in the energy norm.
import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Data.Finset.Card
import Mathlib.Data.Finset.Prod
import Mathlib.Tactic.NormNum

/-- Céa's lemma. Let `V` be a real Hilbert space (the card's `H^1_0`) and `a(u, v)` a form,
linear in each slot, that is bounded, `|a(u, v)| ≤ M ‖u‖ ‖v‖`, and coercive,
`a(v, v) ≥ α ‖v‖²` with `α > 0`. Let `u` solve the weak form, `a(u, v) = (f, v)` for every `v`,
and let `V_h` be a chosen space of shapes inside `V`. If `u_h` lies in `V_h` and solves the
Galerkin system exactly, `a(u_h, v_h) = (f, v_h)` for every `v_h` in `V_h`, then the Galerkin
error is at most `M / α` times the error of every shape in `V_h`:
`‖u - u_h‖ ≤ (M / α) ‖u - v_h‖`. -/
theorem cea_lemma {V : Type*} [NormedAddCommGroup V] [InnerProductSpace ℝ V] [CompleteSpace V]
    (a : V →ₗ[ℝ] V →ₗ[ℝ] ℝ) (f : V →ₗ[ℝ] ℝ) {M α : ℝ}
    (h_bounded : ∀ v w, |a v w| ≤ M * ‖v‖ * ‖w‖)
    (hα : 0 < α) (h_coercive : ∀ v, α * ‖v‖ ^ 2 ≤ a v v)
    (Vh : Submodule ℝ V) {u uh : V}
    (hu : ∀ v, a u v = f v)
    (huh_mem : uh ∈ Vh) (huh : ∀ vh ∈ Vh, a uh vh = f vh) :
    ∀ vh ∈ Vh, ‖u - uh‖ ≤ M / α * ‖u - vh‖ := by
  intro vh hvh
  have horth : ∀ w ∈ Vh, a (u - uh) w = 0 := by
    intro w hw
    rw [map_sub, LinearMap.sub_apply, hu, huh w hw, sub_self]
  have hd : uh - vh ∈ Vh := Vh.sub_mem huh_mem hvh
  have key : a (u - uh) (u - uh) = a (u - uh) (u - vh) := by
    have : u - vh = (u - uh) + (uh - vh) := by abel
    rw [this, map_add, horth _ hd, add_zero]
  have h1 := h_coercive (u - uh)
  have h2 := h_bounded (u - uh) (u - vh)
  have h3 : α * ‖u - uh‖ ^ 2 ≤ M * ‖u - uh‖ * ‖u - vh‖ := by
    rw [key] at h1
    exact h1.trans ((le_abs_self _).trans h2)
  rw [div_mul_eq_mul_div, le_div_iff₀ hα]
  rcases (norm_nonneg (u - uh)).eq_or_lt with h0 | hpos
  · rw [← h0, zero_mul]
    have hw1 := h_coercive (u - vh)
    have hw2 := (le_abs_self _).trans (h_bounded (u - vh) (u - vh))
    rcases (norm_nonneg (u - vh)).eq_or_lt with hw0 | hwpos
    · rw [← hw0, mul_zero]
    · have : 0 ≤ M * ‖u - vh‖ * ‖u - vh‖ := by
        nlinarith [mul_pos hα (pow_pos hwpos 2)]
      exact nonneg_of_mul_nonneg_left this hwpos
  · have : ‖u - uh‖ * (α * ‖u - uh‖) ≤ ‖u - uh‖ * (M * ‖u - vh‖) := by nlinarith [h3]
    have := le_of_mul_le_mul_left this hpos
    linarith

/-- Galerkin orthogonality. If `u` solves the weak form, `a(u, v) = (f, v)` for every `v`, and
`u_h` in the chosen space `V_h` solves the Galerkin system, `a(u_h, v_h) = (f, v_h)` for every
`v_h` in `V_h`, then the error is perpendicular to every chosen shape:
`a(u - u_h, v_h) = 0` for every `v_h` in `V_h`. -/
theorem galerkin_orthogonality {V : Type*} [NormedAddCommGroup V] [InnerProductSpace ℝ V]
    [CompleteSpace V]
    (a : V →ₗ[ℝ] V →ₗ[ℝ] ℝ) (f : V →ₗ[ℝ] ℝ) (Vh : Submodule ℝ V) {u uh : V}
    (hu : ∀ v, a u v = f v)
    (huh_mem : uh ∈ Vh) (huh : ∀ vh ∈ Vh, a uh vh = f vh) :
    ∀ vh ∈ Vh, a (u - uh) vh = 0 := by
  intro vh hvh
  rw [map_sub, LinearMap.sub_apply, hu, huh vh hvh, sub_self]

/-- The symmetric case: the factor is exactly 1. If the form is also symmetric,
`a(v, w) = a(w, v)`, then in the energy norm `‖w‖_a = √(a(w, w))`:
Pythagoras holds, `‖u - v_h‖_a² = ‖u - u_h‖_a² + ‖u_h - v_h‖_a²`; so the Galerkin answer is the
best shape in `V_h`, `‖u - u_h‖_a ≤ ‖u - v_h‖_a`, with equality only at `v_h = u_h`; and the
squared energy error is the missing energy, `‖u - u_h‖_a² = a(u, u) - a(u_h, u_h)`. -/
theorem galerkin_best_in_energy_norm {V : Type*} [NormedAddCommGroup V] [InnerProductSpace ℝ V]
    [CompleteSpace V]
    (a : V →ₗ[ℝ] V →ₗ[ℝ] ℝ) (f : V →ₗ[ℝ] ℝ) {M α : ℝ}
    (h_bounded : ∀ v w, |a v w| ≤ M * ‖v‖ * ‖w‖)
    (hα : 0 < α) (h_coercive : ∀ v, α * ‖v‖ ^ 2 ≤ a v v)
    (h_symm : ∀ v w, a v w = a w v)
    (Vh : Submodule ℝ V) {u uh : V}
    (hu : ∀ v, a u v = f v)
    (huh_mem : uh ∈ Vh) (huh : ∀ vh ∈ Vh, a uh vh = f vh) :
    (∀ vh ∈ Vh, a (u - vh) (u - vh) = a (u - uh) (u - uh) + a (uh - vh) (uh - vh)) ∧
    (∀ vh ∈ Vh, √(a (u - uh) (u - uh)) ≤ √(a (u - vh) (u - vh))) ∧
    (∀ vh ∈ Vh, √(a (u - vh) (u - vh)) = √(a (u - uh) (u - uh)) → vh = uh) ∧
    a (u - uh) (u - uh) = a u u - a uh uh := by
  have horth : ∀ w ∈ Vh, a (u - uh) w = 0 := by
    intro w hw
    rw [map_sub, LinearMap.sub_apply, hu, huh w hw, sub_self]
  have pyth : ∀ vh ∈ Vh, a (u - vh) (u - vh) = a (u - uh) (u - uh) + a (uh - vh) (uh - vh) := by
    intro vh hvh
    have hd : uh - vh ∈ Vh := Vh.sub_mem huh_mem hvh
    have : u - vh = (u - uh) + (uh - vh) := by abel
    rw [this]
    simp only [map_add, LinearMap.add_apply]
    rw [horth _ hd, h_symm (uh - vh) (u - uh), horth _ hd]
    ring
  have nonneg : ∀ v, 0 ≤ a v v := fun v =>
    le_trans (mul_nonneg hα.le (sq_nonneg _)) (h_coercive v)
  refine ⟨pyth, ?_, ?_, ?_⟩
  · intro vh hvh
    apply Real.sqrt_le_sqrt
    rw [pyth vh hvh]
    linarith [nonneg (uh - vh)]
  · intro vh hvh heq
    have heq' := (Real.sqrt_inj (nonneg _) (nonneg _)).1 heq
    rw [pyth vh hvh] at heq'
    have hz : a (uh - vh) (uh - vh) = 0 := by linarith
    have hc := h_coercive (uh - vh)
    rw [hz] at hc
    have : ‖uh - vh‖ ^ 2 ≤ 0 := by
      by_contra hneg
      rw [not_le] at hneg
      linarith [mul_pos hα hneg]
    have hn : ‖uh - vh‖ = 0 := by nlinarith [norm_nonneg (uh - vh)]
    rw [norm_eq_zero, sub_eq_zero] at hn
    exact hn.symm
  · have h0 := horth uh huh_mem
    simp only [map_sub, LinearMap.sub_apply] at h0 ⊢
    rw [h_symm uh u]
    linarith

-- The slab's whole-number facts. Grid nodes are (i, j), at (0.5 i, 0.5 j) m, 0 ≤ i ≤ 12, 0 ≤ j ≤ 10;
-- the missing corner is x > 4 m and y > 2.5 m, that is i > 8 and j > 5.

-- 123 nodes on the L.
set_option maxRecDepth 4000 in
example : ((Finset.range 13 ×ˢ Finset.range 11).filter
    (fun p : ℕ × ℕ => ¬ (8 < p.1 ∧ 5 < p.2))).card = 123 := by decide

-- 79 inside nodes (not on the outer edges, not on the two edges of the re-entrant corner).
set_option maxRecDepth 4000 in
example : ((Finset.range 13 ×ˢ Finset.range 11).filter
    (fun p : ℕ × ℕ => 0 < p.1 ∧ p.1 < 12 ∧ 0 < p.2 ∧ p.2 < 10 ∧ ¬ (8 ≤ p.1 ∧ 5 ≤ p.2))).card = 79 := by
  decide

-- 200 triangles: each 0.5 m square of the L (lower-left corner (i, j)) is cut into two.
set_option maxRecDepth 4000 in
example : 2 * ((Finset.range 12 ×ˢ Finset.range 10).filter
    (fun p : ℕ × ℕ => ¬ (8 ≤ p.1 ∧ 5 ≤ p.2))).card = 200 := by decide

-- Area 6 × 5 - 2 × 2.5 = 25 m², and 25 m² over 0.125 m² per triangle is 200 triangles.
example : (6 : ℚ) * 5 - 2 * (5 / 2) = 25 ∧ (25 : ℚ) / ((1 / 2) ^ 2 / 2) = 200 := by norm_num

-- f = p / (k b) = 2 / (2 × 0.1) = 10 K/m².
example : (2 : ℚ) / (2 * (1 / 10)) = 10 := by norm_num

-- Load per corner f h² / 6 = 10 × 0.125 / 3 = 5/12 K (0.41667 K).
example : (10 : ℚ) * (1 / 2) ^ 2 / 6 = 5 / 12 ∧ (10 : ℚ) * (1 / 8) / 3 = 5 / 12 := by norm_num

-- An inside row: six triangles, two with the node at the right angle (entry 1 each) and four
-- with it at an acute corner (entry 1/2 each), give 4 on the diagonal; six loads of 5/12 K
-- give f h² = 2.5 K.
example : 2 * (1 : ℚ) + 4 * (1 / 2) = 4 ∧ 6 * ((5 : ℚ) / 12) = 10 * (1 / 2) ^ 2 ∧
    10 * ((1 : ℚ) / 2) ^ 2 = 5 / 2 := by norm_num

-- Edges not held: the loads sum to f × area = 10 × 25 = 250 K.
example : (10 : ℚ) * 25 = 250 := by norm_num

#print axioms cea_lemma
#print axioms galerkin_orthogonality
#print axioms galerkin_best_in_energy_norm
