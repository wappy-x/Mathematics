-- Jensen's inequality: for a convex function on a convex set of points in n coordinates, the value at a weighted average is at most the weighted average of the values, and at every inside point a flat plane touches the function and stays under it.
import Mathlib.Analysis.Convex.Jensen
import Mathlib.Analysis.Convex.Function
import Mathlib.Analysis.Convex.Continuous
import Mathlib.Analysis.LocallyConvex.Separation
import Mathlib.Data.Matrix.Mul
import Mathlib.Topology.Instances.Real.Lemmas
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open Finset

/-- Jensen's inequality. Let `f` be convex on a convex set `C` of points with `n` coordinates.
Mix finitely many points `z i` of `C` with weights `θ i` that are each at least 0 and add to 1.
Then the value of `f` at the average point is at most the same average of the values of `f`. -/
theorem jensen_cost_of_average_le_average_of_costs {n : ℕ} {ι : Type*}
    {C : Set (Fin n → ℝ)} {f : (Fin n → ℝ) → ℝ} (hf : ConvexOn ℝ C f)
    (t : Finset ι) (θ : ι → ℝ) (z : ι → Fin n → ℝ)
    (hθ_nonneg : ∀ i ∈ t, 0 ≤ θ i) (hθ_sum : ∑ i ∈ t, θ i = 1)
    (hz : ∀ i ∈ t, z i ∈ C) :
    f (∑ i ∈ t, θ i • z i) ≤ ∑ i ∈ t, θ i * f (z i) := by
  simpa [smul_eq_mul] using hf.map_sum_le hθ_nonneg hθ_sum hz

/-- A supporting plane exists at every inside point, crease or not. Let `f` be convex on a
convex set `C` of points with `n` coordinates, and let `m` be an inside point of `C`. Then
some slope vector `s` gives a flat plane `f m + s · (z - m)` that never rises above `f z`
for any point `z` of `C`. -/
theorem supporting_plane_exists_at_inside_point {n : ℕ}
    {C : Set (Fin n → ℝ)} {f : (Fin n → ℝ) → ℝ} (hf : ConvexOn ℝ C f)
    {m : Fin n → ℝ} (hm : m ∈ interior C) :
    ∃ s : Fin n → ℝ, ∀ z ∈ C, f m + s ⬝ᵥ (z - m) ≤ f z := by
  classical
  set A : Set ((Fin n → ℝ) × ℝ) := {p | p.1 ∈ interior C ∧ f p.1 < p.2} with hA
  have hcont := hf.continuousOn_interior
  have hAopen : IsOpen A := by
    have : A = (interior C ×ˢ (Set.univ : Set ℝ)) ∩
        (fun p : (Fin n → ℝ) × ℝ => p.2 - f p.1) ⁻¹' Set.Ioi 0 := by
      ext p; simp [A, sub_pos]
    rw [this]
    refine ContinuousOn.isOpen_inter_preimage ?_ (isOpen_interior.prod isOpen_univ) isOpen_Ioi
    refine continuous_snd.continuousOn.sub (hcont.comp continuousOn_fst ?_)
    intro p hp; exact hp.1
  have hAconv : Convex ℝ A := by
    rintro ⟨x, s⟩ ⟨hx, hs⟩ ⟨y, t⟩ ⟨hy, ht⟩ a b ha hb hab
    refine ⟨hf.1.interior hx hy ha hb hab, ?_⟩
    have h := hf.2 (interior_subset hx) (interior_subset hy) ha hb hab
    simp only [Prod.smul_mk, Prod.mk_add_mk, smul_eq_mul] at h ⊢
    simp only at hs ht
    rcases ha.eq_or_lt with rfl | ha'
    · have hb1 : b = 1 := by linarith
      subst hb1
      simp only [zero_mul, zero_add, one_mul] at h ⊢
      linarith
    · have h1 := mul_pos ha' (sub_pos.2 hs)
      have h2 := mul_nonneg hb (sub_nonneg.2 ht.le)
      nlinarith
  have hmA : ((m, f m) : (Fin n → ℝ) × ℝ) ∉ A := fun h => lt_irrefl _ h.2
  obtain ⟨L, hL⟩ := geometric_hahn_banach_open_point hAconv hAopen hmA
  set c := L ((0 : Fin n → ℝ), (1 : ℝ)) with hc_def
  have hsplit : ∀ (x : Fin n → ℝ) (t : ℝ), L (x, t) = L (x, 0) + t * c := by
    intro x t
    have : ((x, t) : (Fin n → ℝ) × ℝ) = (x, 0) + t • ((0 : Fin n → ℝ), (1 : ℝ)) := by
      ext <;> simp
    rw [this, map_add, map_smul, smul_eq_mul]
  have hc : c < 0 := by
    have := hL (m, f m + 1) ⟨hm, by linarith⟩
    rw [hsplit, hsplit m (f m)] at this
    linarith
  have hsub : ∀ x y : Fin n → ℝ, L (x - y, 0) = L (x, 0) - L (y, 0) := by
    intro x y
    rw [← map_sub, Prod.mk_sub_mk, sub_zero]
  have hint : ∀ x ∈ interior C, L (x - m, 0) ≤ -c * (f x - f m) := by
    intro x hx
    rw [hsub]
    by_contra hcon
    push Not at hcon
    set δ := L (x, 0) - L (m, 0) - -c * (f x - f m) with hδ
    have hδpos : 0 < δ := by rw [hδ]; linarith
    have hε : 0 < δ / (-c) := div_pos hδpos (neg_pos.2 hc)
    have := hL (x, f x + δ / (-c)) ⟨hx, by linarith⟩
    rw [hsplit, hsplit m (f m)] at this
    have hmul : (δ / (-c)) * c = -δ := by
      rw [div_neg, neg_mul, div_mul_cancel₀ δ hc.ne]
    nlinarith
  set s : Fin n → ℝ := fun i => L ((fun j => if i = j then (1 : ℝ) else 0), 0) / (-c) with hs_def
  have hpi : ∀ v : Fin n → ℝ, L (v, 0) =
      ∑ i, v i • L ((fun j => if i = j then (1 : ℝ) else 0), 0) := by
    intro v
    exact ((L : (Fin n → ℝ) × ℝ →ₗ[ℝ] ℝ).comp (LinearMap.inl ℝ (Fin n → ℝ) ℝ)).pi_apply_eq_sum_univ v
  have hdot : ∀ v : Fin n → ℝ, s ⬝ᵥ v = L (v, 0) / (-c) := by
    intro v
    rw [hpi v, div_eq_mul_inv, Finset.sum_mul, dotProduct]
    refine Finset.sum_congr rfl fun i _ => ?_
    simp only [hs_def, smul_eq_mul, div_eq_mul_inv]
    ring
  have hint' : ∀ x ∈ interior C, f m + s ⬝ᵥ (x - m) ≤ f x := by
    intro x hx
    rw [hdot]
    have h1 := hint x hx
    have h2 : L (x - m, 0) / (-c) ≤ f x - f m := by
      rw [div_le_iff₀ (neg_pos.2 hc)]
      linarith
    linarith
  refine ⟨s, fun z hz => ?_⟩
  have hw : z + (1 / 2 : ℝ) • (m - z) ∈ interior C :=
    hf.1.add_smul_sub_mem_interior hz hm ⟨by norm_num, by norm_num⟩
  have h1 := hint' _ hw
  have hw2 : z + (1 / 2 : ℝ) • (m - z) = (1 / 2 : ℝ) • z + (1 / 2 : ℝ) • m := by
    ext i; simp only [Pi.add_apply, Pi.smul_apply, Pi.sub_apply, smul_eq_mul]; ring
  have hw3 : z + (1 / 2 : ℝ) • (m - z) - m = (1 / 2 : ℝ) • (z - m) := by
    ext i; simp only [Pi.add_apply, Pi.smul_apply, Pi.sub_apply, smul_eq_mul]; ring
  have h2 := hf.2 hz (interior_subset hm) (by norm_num : (0 : ℝ) ≤ 1 / 2)
    (by norm_num : (0 : ℝ) ≤ 1 / 2) (by norm_num)
  rw [← hw2, smul_eq_mul, smul_eq_mul] at h2
  rw [hw3, dotProduct_smul, smul_eq_mul] at h1
  linarith

/-- The roaster's cost in pounds a kilo for a blend with Brazil share `x`, Colombia share `y`
and Ethiopia the rest: the beans at 7, 9 and 12 a kilo, plus the squared miss on strength
(target 6) and the squared miss on acidity (target 5). -/
def blendCost (x y : ℝ) : ℝ :=
  (7 * x + 9 * y + 12 * (1 - x - y))
    + ((8 * x + 6 * y + 4 * (1 - x - y)) - 6) ^ 2
    + ((2 * x + 6 * y + 8 * (1 - x - y)) - 5) ^ 2

/-- The size of the gap for the roaster's bowl (Step 4). For any two blends mixed half and
half, the average of their costs minus the cost of the mix is exactly `d'Hd / 8`, where `d`
is the step between the blends and `H = [[104, 40], [40, 16]]` is the cost's Hessian. -/
theorem blend_cost_half_mix_gap_eq_hessian_term_div_eight (x₁ y₁ x₂ y₂ : ℝ) :
    (blendCost x₁ y₁ + blendCost x₂ y₂) / 2 - blendCost ((x₁ + x₂) / 2) ((y₁ + y₂) / 2)
      = (104 * (x₁ - x₂) ^ 2 + 2 * 40 * (x₁ - x₂) * (y₁ - y₂) + 16 * (y₁ - y₂) ^ 2) / 8 := by
  unfold blendCost
  ring

-- Bold (70% Brazil, 10% Colombia) costs 11.16, Bright (30%, 40%) costs 9.46,
-- the half-and-half mix (50%, 25%) costs 9.25.
example : blendCost (7/10) (1/10) = 279/25 := by norm_num [blendCost]
example : blendCost (3/10) (4/10) = 473/50 := by norm_num [blendCost]
example : blendCost (1/2) (1/4) = 37/4 := by norm_num [blendCost]
-- The average of the two prices is 10.31; the gap is 1.06.
example : (blendCost (7/10) (1/10) + blendCost (3/10) (4/10)) / 2 = 1031/100 := by
  norm_num [blendCost]
example : (blendCost (7/10) (1/10) + blendCost (3/10) (4/10)) / 2 - blendCost (1/2) (1/4)
    = 106/100 := by norm_num [blendCost]
-- Gap by the Hessian: d = (0.4, -0.3), d'Hd = 8.48, divided by 8 is 1.06.
example : (104 * (4/10 : ℝ) ^ 2 + 2 * 40 * (4/10) * (-3/10) + 16 * (-3/10) ^ 2) = 848/100 := by
  norm_num
example : (848/100 : ℝ) / 8 = 106/100 := by norm_num
-- The Hessian [[104, 40], [40, 16]] has determinant 64 and trace 120.
example : (104 : ℤ) * 16 - 40 * 40 = 64 ∧ (104 : ℤ) + 16 = 120 := by decide
-- Gradient at the mix by the chain rule, with strength 6.5 and acidity 4.5: (5, 1).
example : (-5 : ℝ) + 8 * (13/2 - 6) - 12 * (9/2 - 5) = 5 ∧
    (-3 : ℝ) + 4 * (13/2 - 6) - 4 * (9/2 - 5) = 1 := by norm_num
-- The plane 9.25 + 5(x - 0.5) + 1(y - 0.25) reads 10.10 at Bold, 8.40 at Bright, average 9.25.
example : (37/4 : ℝ) + 5 * (7/10 - 1/2) + 1 * (1/10 - 1/4) = 101/10 := by norm_num
example : (37/4 : ℝ) + 5 * (3/10 - 1/2) + 1 * (4/10 - 1/4) = 42/5 := by norm_num
example : ((101/10 : ℝ) + 42/5) / 2 = 37/4 := by norm_num
-- The week of batches: misses (+5, -5), (-5, 0), (0, +5), (+5, +5), (-5, -5) points.
example : blendCost (55/100) (20/100) = 19/2 := by norm_num [blendCost]
example : blendCost (45/100) (25/100) = 913/100 := by norm_num [blendCost]
example : blendCost (50/100) (30/100) = 233/25 := by norm_num [blendCost]
example : blendCost (55/100) (30/100) = 49/5 := by norm_num [blendCost]
example : blendCost (45/100) (20/100) = 46/5 := by norm_num [blendCost]
-- The week's average is 9.39, at least the 9.25 floor; the gap is 0.14.
example : ((19/2 : ℝ) + 913/100 + 233/25 + 49/5 + 46/5) / 5 = 939/100 := by norm_num
example : (939/100 : ℝ) - 37/4 = 14/100 := by norm_num
-- The crease: a surcharge of 4 per share of Ethiopia above 25% makes Bright cost 9.66;
-- the average of Bold and Bright is then 10.41.
example : blendCost (3/10) (4/10) + 4 * max (1 - 3/10 - 4/10 - 1/4) 0 = 483/50 := by
  norm_num [blendCost]
example : ((279/25 : ℝ) + 483/50) / 2 = 1041/100 := by norm_num
-- Weights 0.4 and 0.4 (adding to 0.8): blend (0.40, 0.20) costs 9.44, above 0.4 x 11.16 + 0.4 x 9.46.
example : blendCost (2/5) (1/5) = 236/25 := by norm_num [blendCost]
example : (2/5 : ℝ) * (279/25) + 2/5 * (473/50) < 236/25 := by norm_num
-- Mistake 1, a two-style market (strength 6 or 7, penalty 4 x the smaller squared miss,
-- no acidity): Bold 8.20, Bright 9.30, mix 9.75, above their average 8.75.
example : (41/5 : ℝ) + 4 * min ((7 - 6) ^ 2) ((7 - 7) ^ 2) = 41/5 := by norm_num
example : (93/10 : ℝ) + 4 * min ((6 - 6) ^ 2) ((6 - 7) ^ 2) = 93/10 := by norm_num
example : (35/4 : ℝ) + 4 * min ((13/2 - 6) ^ 2) ((13/2 - 7) ^ 2) = 39/4 := by norm_num
example : ((41/5 : ℝ) + 93/10) / 2 = 35/4 ∧ (35/4 : ℝ) < 39/4 := by norm_num

#print axioms jensen_cost_of_average_le_average_of_costs
#print axioms supporting_plane_exists_at_inside_point
#print axioms blend_cost_half_mix_gap_eq_hessian_term_div_eight
