-- Contractible and simply connected: a closed disc in the plane is contractible and simply connected, a contractible space is always simply connected, and an annulus and a punctured plane are neither, being homotopy equivalent to each other.
import Mathlib.Analysis.Convex.Contractible
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.AlgebraicTopology.FundamentalGroupoid.SimplyConnected
import Mathlib.Topology.Covering.FundamentalGroupCircle
import Mathlib.Analysis.SpecialFunctions.Complex.Circle

open Metric ContinuousMap

/-- The plane annulus `r ≤ ‖x‖ ≤ R` and the punctured plane are homotopy equivalent. -/
noncomputable def annulusHomotopyEquivPuncturedPlane (r R : ℝ) (hr : 0 < r) (hrR : r ≤ R) :
    {x : EuclideanSpace ℝ (Fin 2) | r ≤ ‖x‖ ∧ ‖x‖ ≤ R} ≃ₕ
      ({0}ᶜ : Set (EuclideanSpace ℝ (Fin 2))) where
  toFun := ⟨fun x => ⟨x.1, by
      have := x.2.1
      simp only [Set.mem_compl_iff, Set.mem_singleton_iff]
      intro h; rw [h, norm_zero] at this; linarith⟩,
    by apply Continuous.subtype_mk; fun_prop⟩
  invFun := ⟨fun x => ⟨(r / ‖x.1‖) • x.1, by
      have hx : ‖x.1‖ ≠ 0 := norm_ne_zero_iff.mpr x.2
      have : ‖(r / ‖x.1‖) • x.1‖ = r := by
        rw [norm_smul, Real.norm_eq_abs, abs_of_nonneg (by positivity), div_mul_cancel₀ _ hx]
      simp only [Set.mem_ofPred_eq, this]; exact ⟨le_rfl, hrR⟩⟩, by
      have hc : Continuous fun x : ({0}ᶜ : Set (EuclideanSpace ℝ (Fin 2))) => ‖x.1‖ :=
        by fun_prop
      apply Continuous.subtype_mk
      fun_prop (disch := intro x; exact norm_ne_zero_iff.mpr x.2)⟩
  left_inv := ⟨{
    toFun := fun p => ⟨((1 - (p.1 : ℝ)) * (r / ‖p.2.1‖) + p.1) • p.2.1, by
      obtain ⟨t, x⟩ := p
      have hx0 : 0 < ‖x.1‖ := lt_of_lt_of_le hr x.2.1
      have ht0 : 0 ≤ (t : ℝ) := t.2.1
      have ht1 : (t : ℝ) ≤ 1 := t.2.2
      have hco : 0 ≤ (1 - (t : ℝ)) * (r / ‖x.1‖) + t := by positivity
      have : ‖((1 - (t : ℝ)) * (r / ‖x.1‖) + t) • x.1‖ = (1 - t) * r + t * ‖x.1‖ := by
        rw [norm_smul, Real.norm_eq_abs, abs_of_nonneg hco]
        field_simp
      simp only [Set.mem_ofPred_eq, this]
      have h1 := x.2.1; have h2 := x.2.2
      constructor <;> nlinarith⟩
    continuous_toFun := by
      have hc : Continuous fun x : {x : EuclideanSpace ℝ (Fin 2) | r ≤ ‖x‖ ∧ ‖x‖ ≤ R} => ‖x.1‖ :=
        by fun_prop
      apply Continuous.subtype_mk
      fun_prop (disch := intro p; exact (lt_of_lt_of_le hr p.2.2.1).ne')
    map_zero_left := by intro x; ext1; simp
    map_one_left := by intro x; ext1; simp }⟩
  right_inv := ⟨{
    toFun := fun p => ⟨((1 - (p.1 : ℝ)) * (r / ‖p.2.1‖) + p.1) • p.2.1, by
      obtain ⟨t, x⟩ := p
      have hx0 : 0 < ‖x.1‖ := norm_pos_iff.mpr x.2
      have ht0 : 0 ≤ (t : ℝ) := t.2.1
      have ht1 : (t : ℝ) ≤ 1 := t.2.2
      have hco : 0 < (1 - (t : ℝ)) * (r / ‖x.1‖) + t := by
        rcases eq_or_lt_of_le ht1 with h | h
        · rw [h]; norm_num
        · have : 0 < 1 - (t : ℝ) := by linarith
          positivity
      simp only [Set.mem_compl_iff, Set.mem_singleton_iff, smul_eq_zero, not_or]
      exact ⟨hco.ne', x.2⟩⟩
    continuous_toFun := by
      have hc : Continuous fun x : ({0}ᶜ : Set (EuclideanSpace ℝ (Fin 2))) => ‖x.1‖ :=
        by fun_prop
      apply Continuous.subtype_mk
      fun_prop (disch := intro p; exact norm_ne_zero_iff.mpr p.2.2)
    map_zero_left := by intro x; ext1; simp
    map_one_left := by intro x; ext1; simp }⟩

/-- The circle is not simply connected. -/
theorem not_simplyConnectedSpace_addCircle : ¬ SimplyConnectedSpace (AddCircle (2 * Real.pi)) := by
  intro h
  have : Fact (0 < 2 * Real.pi) := ⟨by positivity⟩
  have hs : Subsingleton (FundamentalGroup (AddCircle (2 * Real.pi)) 0) := inferInstance
  have : Subsingleton (Multiplicative ℤ) :=
    ((AddCircle.windingNumberIso (0 : AddCircle (2 * Real.pi))).toEquiv.subsingleton_congr).mp hs
  exact absurd (Subsingleton.elim (Multiplicative.ofAdd (1 : ℤ)) (Multiplicative.ofAdd 0)) (by decide)

/-- The unit circle in the Euclidean plane is homeomorphic to the circle `AddCircle (2π)`. -/
noncomputable def unitAnnulusHomeomorph :
    {x : EuclideanSpace ℝ (Fin 2) | 1 ≤ ‖x‖ ∧ ‖x‖ ≤ 1} ≃ₜ AddCircle (2 * Real.pi) :=
  let e : EuclideanSpace ℝ (Fin 2) ≃ₜ ℂ :=
    Complex.orthonormalBasisOneI.repr.symm.toHomeomorph
  let e2 : {x : EuclideanSpace ℝ (Fin 2) | 1 ≤ ‖x‖ ∧ ‖x‖ ≤ 1} ≃ₜ sphere (0 : ℂ) 1 :=
    e.subtype (fun x => by
      simp only [Set.mem_ofPred_eq, mem_sphere_zero_iff_norm, e,
        LinearIsometryEquiv.coe_toHomeomorph, LinearIsometryEquiv.norm_map]
      constructor
      · rintro ⟨h1, h2⟩; linarith
      · intro h; rw [h]; exact ⟨le_rfl, le_rfl⟩)
  let e3 : sphere (0 : ℂ) 1 ≃ₜ Circle := Homeomorph.refl _
  (e2.trans e3).trans AddCircle.homeomorphCircle'.symm

theorem not_simplyConnectedSpace_puncturedPlane :
    ¬ SimplyConnectedSpace ({0}ᶜ : Set (EuclideanSpace ℝ (Fin 2))) := by
  rw [← (annulusHomotopyEquivPuncturedPlane 1 1 one_pos le_rfl).simplyConnectedSpace_iff,
    unitAnnulusHomeomorph.toHomotopyEquiv.simplyConnectedSpace_iff]
  exact not_simplyConnectedSpace_addCircle

#print axioms annulusHomotopyEquivPuncturedPlane
#print axioms not_simplyConnectedSpace_addCircle
#print axioms unitAnnulusHomeomorph
#print axioms not_simplyConnectedSpace_puncturedPlane

/-- The card's verdict on its three plane spaces. A disc `|x| ≤ R` is contractible and simply
connected. An annulus `r ≤ |x| ≤ R` (with `0 < r ≤ R`) and the punctured plane `ℝ² \ {0}` are
neither simply connected nor contractible, because a loop once round the hole cannot shrink. -/
theorem disc_contractible_annulus_and_punctured_plane_not
    (r R : ℝ) (hr : 0 < r) (hrR : r ≤ R) :
    ContractibleSpace (closedBall (0 : EuclideanSpace ℝ (Fin 2)) R) ∧
    SimplyConnectedSpace (closedBall (0 : EuclideanSpace ℝ (Fin 2)) R) ∧
    ¬ SimplyConnectedSpace {x : EuclideanSpace ℝ (Fin 2) | r ≤ ‖x‖ ∧ ‖x‖ ≤ R} ∧
    ¬ ContractibleSpace {x : EuclideanSpace ℝ (Fin 2) | r ≤ ‖x‖ ∧ ‖x‖ ≤ R} ∧
    ¬ SimplyConnectedSpace ({0}ᶜ : Set (EuclideanSpace ℝ (Fin 2))) ∧
    ¬ ContractibleSpace ({0}ᶜ : Set (EuclideanSpace ℝ (Fin 2))) := by
  have hR : 0 ≤ R := hr.le.trans hrR
  have hc : ContractibleSpace (closedBall (0 : EuclideanSpace ℝ (Fin 2)) R) :=
    (convex_closedBall 0 R).contractibleSpace ⟨0, mem_closedBall_self hR⟩
  have hP := not_simplyConnectedSpace_puncturedPlane
  have hA : ¬ SimplyConnectedSpace {x : EuclideanSpace ℝ (Fin 2) | r ≤ ‖x‖ ∧ ‖x‖ ≤ R} := by
    rw [(annulusHomotopyEquivPuncturedPlane r R hr hrR).simplyConnectedSpace_iff]; exact hP
  exact ⟨hc, SimplyConnectedSpace.ofContractible _, hA,
    fun h => hA (@SimplyConnectedSpace.ofContractible _ _ h), hP,
    fun h => hP (@SimplyConnectedSpace.ofContractible _ _ h)⟩

/-- Contractible implies simply connected: if a space can be squeezed continuously to one point,
then it is in one piece (path-connected) and every loop at every point `p` shrinks to the
constant loop at `p` with both ends held at `p`. -/
theorem contractible_implies_simply_connected (X : Type*) [TopologicalSpace X]
    [ContractibleSpace X] :
    PathConnectedSpace X ∧ ∀ (p : X) (γ : Path p p), γ.Homotopic (Path.refl p) := by
  exact simply_connected_iff_loops_nullhomotopic.mp (SimplyConnectedSpace.ofContractible X)

/-- The annulus `r ≤ |x| ≤ R` (with `0 < r ≤ R`) and the punctured plane `ℝ² \ {0}` are
homotopy equivalent: both squeeze onto the circle of radius `r` along rays from the hole. -/
theorem annulus_homotopy_equivalent_punctured_plane
    (r R : ℝ) (hr : 0 < r) (hrR : r ≤ R) :
    Nonempty ({x : EuclideanSpace ℝ (Fin 2) | r ≤ ‖x‖ ∧ ‖x‖ ≤ R} ≃ₕ
      ({0}ᶜ : Set (EuclideanSpace ℝ (Fin 2)))) := by
  exact ⟨annulusHomotopyEquivPuncturedPlane r R hr hrR⟩

-- The square's farthest corner: 4² + 4² = 32 square metres, inside the 10 m lawn (32 ≤ 100).
example : (4 : ℤ) ^ 2 + 4 ^ 2 = 32 ∧ (32 : ℤ) ≤ 10 ^ 2 := by norm_num
-- Four sides, each a quarter turn: winding number 1.
example : (4 : ℚ) * (1 / 4) = 1 := by norm_num
-- Round, then back the other way: up 1, down 1, signed 0.
example : (1 : ℤ) - 1 = 0 := by norm_num
-- The straight squeeze in the annulus: nearest point 4(1 - t) is 1 m at t = 3/4, 1/2 m at t = 7/8.
example : (4 : ℚ) * (1 - 3 / 4) = 1 ∧ (4 : ℚ) * (1 - 7 / 8) = 1 / 2 := by norm_num
-- The disc's squeeze of the rim point (6, 8), 10 m out: (3, 4) at t = 1/2.
example : (6 : ℤ) ^ 2 + 8 ^ 2 = 10 ^ 2 ∧ (1 - 1 / 2 : ℚ) * 6 = 3 ∧ (1 - 1 / 2 : ℚ) * 8 = 4 := by
  norm_num
-- The slide of (3, 4), 5 m out, onto the circle: x / ((1 - t) + t |x|) at t = 1/2 and t = 1.
example : (3 : ℤ) ^ 2 + 4 ^ 2 = 5 ^ 2 ∧
    (3 : ℚ) / ((1 - 1 / 2) + 1 / 2 * 5) = 1 ∧ (4 : ℚ) / ((1 - 1 / 2) + 1 / 2 * 5) = 4 / 3 ∧
    (3 : ℚ) / ((1 - 1) + 1 * 5) = 3 / 5 ∧ (4 : ℚ) / ((1 - 1) + 1 * 5) = 4 / 5 := by norm_num
-- The lift in space: squared distance 16((1 - t)² + t²) is 8 at t = 1/2, so 2√2 m.
example : (16 : ℚ) * ((1 - 1 / 2) ^ 2 + (1 / 2) ^ 2) = 8 := by norm_num

#print axioms disc_contractible_annulus_and_punctured_plane_not
#print axioms contractible_implies_simply_connected
#print axioms annulus_homotopy_equivalent_punctured_plane
