-- Higher homotopy groups: from dimension 2 up, adding two spheres along any two directions gives the same commutative sum, every sphere of dimension 2 or more on the circle shrinks to a point, and the Hopf map sends the 3-sphere onto the 2-sphere with each fibre one circle of phases.
import Mathlib.Topology.Homotopy.HomotopyGroup
import Mathlib.Analysis.Complex.Circle
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Complex.Circle
import Mathlib.Topology.Homotopy.Lifting
import Mathlib.Analysis.Convex.Contractible
import Mathlib.Topology.Algebra.Module.LocallyConvex

open Topology Topology.Homotopy ComplexConjugate Complex

/-! The n-th homotopy group `π_n(X, x₀)` is Mathlib's `π_ n X x₀`, the quotient of the maps of
the n-cube `I^n` that send its boundary to `x₀` (Mathlib's `Ω^ (Fin n) X x₀`) by sliding with
the boundary held at `x₀`. `⟦f⟧` is the class of such a map `f`.
`GenLoop.transAt i f g` is the card's sum along coordinate `s_i`: `f` squeezed into the half
`s_i ≤ 1/2` and `g` into the half `s_i ≥ 1/2`. Writing `n + 2` for the dimension says `n ≥ 2`.
The circle `S¹` is Mathlib's unit circle `Circle` in the complex plane.
A point of `S³` is a pair `(z, w)` of complex numbers with `|z|² + |w|² = 1`; `normSq z` is
`|z|²`. The Hopf map sends it to the point `(2 z conj(w), |z|² − |w|²)` of `S² ⊆ ℂ × ℝ`. -/

open unitInterval in
theorem cube_contractibleSpace (N : Type*) : ContractibleSpace (I^N) := by
  refine (contractible_iff_id_nullhomotopic _).2 ⟨fun _ => 0, ⟨{
    toFun := fun p i => ⟨(1 - (p.1 : ℝ)) * (p.2 i : ℝ),
      unitInterval.mul_mem (unitInterval.symm p.1).2 (p.2 i).2⟩
    continuous_toFun := by fun_prop
    map_zero_left := fun y => by ext i; simp
    map_one_left := fun y => by ext i; simp }⟩⟩

#print axioms cube_contractibleSpace

open unitInterval in
theorem cube_locallyPathConnectedSpace (N : Type*) [Finite N] :
    LocallyPathConnectedSpace (I^N) := by
  have : LocallyPathConnectedSpace I := (convex_Icc (0 : ℝ) 1).locallyPathConnectedSpace
  infer_instance

#print axioms cube_locallyPathConnectedSpace

open unitInterval in
theorem cube_lift_const_on_boundary (n : ℕ) (x₀ : Circle) (F : C(I^(Fin (n + 2)), ℝ))
    (hF : ∀ y ∈ Cube.boundary (Fin (n + 2)), Circle.exp (F y) = x₀) :
    ∀ y ∈ Cube.boundary (Fin (n + 2)), F y = F (fun _ => 0) := by
  classical
  rintro y ⟨i, hi⟩
  obtain ⟨j, hj⟩ := exists_ne i
  let S (k : Fin (n + 2)) (c : I) : Set (I^(Fin (n + 2))) :=
    Set.pi Set.univ (fun l => if l = k then {c} else Set.univ)
  have hpre : ∀ k c, IsPreconnected (S k c) := fun k c =>
    isPreconnected_univ_pi fun l => by
      split_ifs
      · exact isPreconnected_singleton
      · exact isPreconnected_univ
  have hmem : ∀ k c z, z ∈ S k c ↔ z k = c := fun k c z => by
    simp only [S, Set.mem_pi, Set.mem_univ, true_implies]
    constructor
    · intro h; simpa using h k
    · intro h l; split_ifs with hl
      · subst hl; simpa using h
      · trivial
  have hsub : ∀ k (c : I), (c = 0 ∨ c = 1) → S k c ⊆ Cube.boundary (Fin (n + 2)) :=
    fun k c hc z hz => ⟨k, (hmem k c z).1 hz ▸ hc⟩
  have hconst : ∀ k (c : I), (c = 0 ∨ c = 1) → ∀ a ∈ S k c, ∀ b ∈ S k c, F a = F b :=
    fun k c hc a ha b hb =>
      Circle.isCoveringMap_exp.constOn_of_comp (hpre k c) F.continuous.continuousOn
        (fun a ha b hb => by rw [hF a (hsub k c hc ha), hF b (hsub k c hc hb)]) ha hb
  let y' : I^(Fin (n + 2)) := fun l => if l = i then y i else 0
  have h1 : F y = F y' := hconst i (y i) hi y ((hmem _ _ _).2 rfl) y' ((hmem _ _ _).2 (by simp [y']))
  have h2 : F y' = F (fun _ => 0) := hconst j 0 (Or.inl rfl) y' ((hmem _ _ _).2 (by simp [y', hj]))
    _ ((hmem _ _ _).2 rfl)
  exact h1.trans h2

#print axioms cube_lift_const_on_boundary

/-- **Eckmann-Hilton: from dimension 2 up, the sum of spheres does not care about direction
or order.** For `n ≥ 2`, any space `X` and base point `x₀`: adding `f` and `g` side by side along
coordinate `i` gives the same class in `π_n(X, x₀)` as adding `g` and `f` along coordinate `j`,
for any two coordinates `i`, `j`; so the group `π_n(X, x₀)` is commutative. -/
theorem homotopy_group_sum_independent_of_direction_and_commutative (n : ℕ) {X : Type*}
    [TopologicalSpace X] (x₀ : X) :
    (∀ (i j : Fin (n + 2)) (f g : Ω^ (Fin (n + 2)) X x₀),
      (⟦GenLoop.transAt i f g⟧ : HomotopyGroup (Fin (n + 2)) X x₀) = ⟦GenLoop.transAt j g f⟧) ∧
    ∀ a b : π_ (n + 2) X x₀, a * b = b * a := by
  refine ⟨fun i j f g => ?_, fun a b => mul_comm a b⟩
  have h1 := HomotopyGroup.mul_spec (N := Fin (n + 2)) (X := X) (x := x₀) (i := i) (p := g) (q := f)
  have h2 := HomotopyGroup.mul_spec (N := Fin (n + 2)) (X := X) (x := x₀) (i := j) (p := f) (q := g)
  rw [← h1, ← h2]
  exact mul_comm (G := HomotopyGroup (Fin (n + 2)) X x₀) _ _

/-- **No sphere of dimension 2 or more is caught on a circle.** For `n ≥ 2` and every base
point `x₀` of the circle, every element of `π_n(S¹, x₀)` is the identity: `π_n(S¹) = 0`. -/
theorem circle_higher_homotopy_groups_trivial (n : ℕ) (x₀ : Circle) (a : π_ (n + 2) Circle x₀) :
    a = 1 := by
  have := cube_contractibleSpace (Fin (n + 2))
  have := cube_locallyPathConnectedSpace (Fin (n + 2))
  induction a using Quotient.inductionOn' with
  | h f =>
  rw [HomotopyGroup.one_def]
  apply Quotient.sound
  obtain ⟨θ, hθ⟩ := Circle.exp_surjective x₀
  have h0 : (fun _ => 0 : Fin (n + 2) → unitInterval) ∈ Cube.boundary (Fin (n + 2)) := ⟨0, Or.inl rfl⟩
  obtain ⟨F, ⟨hF0, hFl⟩, -⟩ := Circle.isCoveringMap_exp.existsUnique_continuousMap_lifts
    (f : C(Fin (n + 2) → unitInterval, Circle)) (fun _ => 0) θ (by rw [hθ]; exact (GenLoop.boundary f _ h0).symm)
  have hb : ∀ y ∈ Cube.boundary (Fin (n + 2)), F y = θ := by
    intro y hy
    rw [cube_lift_const_on_boundary n x₀ F (fun y hy => by
      rw [show Circle.exp (F y) = (Circle.exp ∘ F) y from rfl, hFl]; exact GenLoop.boundary f y hy) y hy, hF0]
  refine ⟨{
    toFun := fun p => Circle.exp ((1 - (p.1 : ℝ)) * F p.2 + (p.1 : ℝ) * θ)
    continuous_toFun := by fun_prop
    map_zero_left := fun y => by
      simp only [Set.Icc.coe_zero, sub_zero, one_mul, zero_mul, add_zero]
      exact congr_fun hFl y
    map_one_left := fun y => by simpa using hθ
    prop' := fun t y hy => by
      simp only [ContinuousMap.coe_mk]
      rw [hb y hy, ← add_mul, sub_add_cancel, one_mul]
      rw [← (GenLoop.boundary f y hy)] at hθ
      exact hθ }⟩

/-- **The Hopf map, and its fibres are circles of phases.** For every point `(z, w)` of `S³`,
its image `(2 z conj(w), |z|² − |w|²)` lies on the unit sphere `S²`; and two points `(z, w)`
and `(z', w')` of `S³` have the same image exactly when one is the other times a phase:
`(z', w') = (u z, u w)` for some complex `u` with `|u| = 1`. -/
theorem hopf_map_lands_on_sphere_and_fibres_are_phase_circles (z w z' w' : ℂ)
    (h : normSq z + normSq w = 1) (h' : normSq z' + normSq w' = 1) :
    normSq (2 * z * conj w) + (normSq z - normSq w) ^ 2 = 1 ∧
    ((2 * z * conj w = 2 * z' * conj w' ∧ normSq z - normSq w = normSq z' - normSq w') ↔
      ∃ u : ℂ, ‖u‖ = 1 ∧ z' = u * z ∧ w' = u * w) := by
  have hnorm : ∀ a b : ℂ, normSq a = normSq b → ‖a‖ = ‖b‖ := fun a b hab => by
    rw [normSq_eq_norm_sq, normSq_eq_norm_sq] at hab
    exact (pow_left_inj₀ (norm_nonneg _) (norm_nonneg _) two_ne_zero).1 hab
  refine ⟨?_, ⟨fun ⟨hc, hd⟩ => ?_, fun ⟨u, hu, hz, hw⟩ => ?_⟩⟩
  · have h4 : normSq (2 : ℂ) = 4 := by norm_num [normSq_apply]
    rw [normSq_mul, normSq_mul, normSq_conj, h4]
    nlinarith [h]
  · have ha : normSq z = normSq z' := by linarith
    have hb : normSq w = normSq w' := by linarith
    have hc1 : z * conj w = z' * conj w' := by
      have := hc; rw [mul_assoc, mul_assoc] at this
      exact mul_left_cancel₀ two_ne_zero this
    have hc' : conj z * w = conj z' * w' := by
      have := congrArg conj hc1; simpa using this
    by_cases hz0 : z = 0
    · have hz'0 : z' = 0 := by
        rw [← normSq_eq_zero, ← ha, hz0, map_zero]
      have hw0 : w ≠ 0 := by
        intro hw; rw [hz0, hw, map_zero, add_zero] at h; norm_num at h
      refine ⟨w' / w, ?_, ?_, ?_⟩
      · rw [norm_div, ← hnorm w w' hb, div_self (norm_ne_zero_iff.2 hw0)]
      · rw [hz0, hz'0, mul_zero]
      · rw [div_mul_cancel₀ _ hw0]
    · refine ⟨z' / z, ?_, ?_, ?_⟩
      · rw [norm_div, ← hnorm z z' ha, div_self (norm_ne_zero_iff.2 hz0)]
      · rw [div_mul_cancel₀ _ hz0]
      · have hcz : conj z ≠ 0 := (map_ne_zero _).2 hz0
        have hm := mul_conj z
        have hm' := mul_conj z'
        have hn : (normSq z : ℂ) = normSq z' := by rw [ha]
        rw [div_mul_eq_mul_div, eq_div_iff hz0]
        apply mul_right_cancel₀ hcz
        linear_combination (-z') * hc' - w' * hm' + w' * hm + w' * hn
  · subst hz hw
    have hu2 : normSq u = 1 := by rw [normSq_eq_norm_sq, hu, one_pow]
    have hu3 : u * conj u = 1 := by rw [mul_conj, hu2, ofReal_one]
    refine ⟨?_, ?_⟩
    · rw [map_mul]
      linear_combination (-(2 * z * conj w)) * hu3
    · rw [normSq_mul, normSq_mul, hu2, one_mul, one_mul]

/-! Worked numbers from the card. -/

-- The example qubit (1/√2, 1/√2) lies on S³ and goes to the point (1, 0, 0) of S², ratio 1.
example : normSq ((Real.sqrt 2)⁻¹ : ℂ) + normSq ((Real.sqrt 2)⁻¹ : ℂ) = 1 := by
  rw [map_inv₀, normSq_ofReal, Real.mul_self_sqrt (by norm_num)]
  norm_num
example : 2 * ((Real.sqrt 2)⁻¹ : ℂ) * conj ((Real.sqrt 2)⁻¹ : ℂ) = 1 ∧
    normSq ((Real.sqrt 2)⁻¹ : ℂ) - normSq ((Real.sqrt 2)⁻¹ : ℂ) = 0 := by
  refine ⟨?_, sub_self _⟩
  have hs : ((Real.sqrt 2 : ℝ) : ℂ) * (Real.sqrt 2 : ℝ) = 2 := by
    rw [← ofReal_mul, Real.mul_self_sqrt (by norm_num)]; norm_num
  have hs0 : ((Real.sqrt 2 : ℝ) : ℂ) ≠ 0 :=
    ofReal_ne_zero.2 (Real.sqrt_ne_zero'.2 (by norm_num))
  rw [map_inv₀, conj_ofReal]
  field_simp
  rw [sq, hs]

-- Turning the phase by 90 degrees multiplies both numbers by i; the ratio stays 1.
example : (I * (Real.sqrt 2)⁻¹) / (I * (Real.sqrt 2)⁻¹) = (1 : ℂ) := by
  apply div_self
  exact mul_ne_zero I_ne_zero (by norm_num)

-- The second qubit (3/5, 4i/5): on S³, ratio −(3/4) i, point (−(24/25) i, −7/25) of S²,
-- that is (0, −0.96, −0.28).
example : normSq (3 / 5 : ℂ) + normSq (4 / 5 * I) = 1 := by
  simp [normSq_apply]; norm_num
example : (3 / 5 : ℂ) / (4 / 5 * I) = -(3 / 4) * I := by
  rw [div_eq_iff (mul_ne_zero (by norm_num) I_ne_zero)]
  ring_nf; rw [I_sq]; ring
example : 2 * (3 / 5 : ℂ) * conj (4 / 5 * I) = -(24 / 25) * I ∧
    normSq (3 / 5 : ℂ) - normSq (4 / 5 * I) = -7 / 25 := by
  refine ⟨?_, ?_⟩
  · rw [map_mul, conj_I]
    have : conj (4 / 5 : ℂ) = 4 / 5 := by
      rw [map_div₀, map_ofNat, map_ofNat]
    rw [this]; ring
  · simp [normSq_apply]; norm_num

#print axioms homotopy_group_sum_independent_of_direction_and_commutative
#print axioms circle_higher_homotopy_groups_trivial
#print axioms hopf_map_lands_on_sphere_and_fibres_are_phase_circles
