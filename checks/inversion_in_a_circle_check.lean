-- Inversion in a circle: inversion in a circle of the plane sends lines and circles to lines and circles, keeps angles, and fixes a circle exactly when the power of the centre equals the radius squared.
import Mathlib.Geometry.Euclidean.Inversion.ImageHyperplane
import Mathlib.Geometry.Euclidean.Inversion.Calculus
import Mathlib.Geometry.Euclidean.Angle.Unoriented.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Geometry.Euclidean.Projection

open EuclideanGeometry

local notation "ℝ²" => EuclideanSpace ℝ (Fin 2)

/-- Squared distance from the image of `x` to a point `O + λ • (C - O)`. -/
theorem inversion_dist_sq_aux (O C x : ℝ²) (r l : ℝ) (hx : x ≠ O) :
    dist (inversion O r x) (O + l • (C - O)) ^ 2 * ‖x - O‖ ^ 2 =
      r ^ 4 - 2 * r ^ 2 * l * inner ℝ (x - O) (C - O) + l ^ 2 * ‖C - O‖ ^ 2 * ‖x - O‖ ^ 2 := by
  have hs : ‖x - O‖ ≠ 0 := by simpa [sub_eq_zero] using hx
  have h1 : inversion O r x - (O + l • (C - O)) = (r / ‖x - O‖) ^ 2 • (x - O) - l • (C - O) := by
    rw [inversion, dist_eq_norm, vsub_eq_sub, vadd_eq_add]; abel
  rw [dist_eq_norm, h1, @norm_sub_sq_real, norm_smul, norm_smul, inner_smul_left, inner_smul_right]
  simp only [Real.norm_eq_abs, conj_trivial]
  rw [abs_of_nonneg (by positivity)]
  rw [mul_pow, mul_pow, sq_abs]
  field_simp

/-- Points of the sphere `C ρ` other than `O`: relation between the old and new data. -/
theorem sphere_inner_aux (O C x : ℝ²) (ρ : ℝ) (hx : x ∈ Metric.sphere C ρ) :
    2 * inner ℝ (x - O) (C - O) = ‖x - O‖ ^ 2 + (dist O C ^ 2 - ρ ^ 2) := by
  rw [Metric.mem_sphere, dist_eq_norm] at hx
  have : x - C = (x - O) - (C - O) := by abel
  rw [this] at hx
  have h2 : ‖x - O - (C - O)‖ ^ 2 = ρ ^ 2 := by rw [hx]
  rw [norm_sub_sq_real] at h2
  rw [dist_comm, dist_eq_norm]
  linarith

theorem exists_perp_aux (w : ℝ²) : ∃ f : ℝ², f ≠ 0 ∧ inner ℝ w f = 0 := by
  have h1 := Submodule.finrank_add_finrank_orthogonal (ℝ ∙ w)
  have h2 : Module.finrank ℝ (ℝ ∙ w) ≤ 1 := by simpa using finrank_span_le_card ({w} : Set ℝ²)
  rw [finrank_euclideanSpace_fin] at h1
  have h3 : (ℝ ∙ w)ᗮ ≠ ⊥ := by
    intro h
    rw [h, finrank_bot] at h1
    omega
  obtain ⟨f, hf, hf0⟩ := Submodule.exists_mem_ne_zero_of_ne_bot h3
  exact ⟨f, hf0, Submodule.mem_orthogonal_singleton_iff_inner_right.1 hf⟩

theorem inversion_mem_sphere_aux (O C x : ℝ²) (r ρ : ℝ) (hρ : 0 ≤ ρ)
    (hp : dist O C ^ 2 - ρ ^ 2 ≠ 0) (hx : x ∈ Metric.sphere C ρ) (hxO : x ≠ O) :
    inversion O r x ∈ Metric.sphere (O + (r ^ 2 / (dist O C ^ 2 - ρ ^ 2)) • (C - O))
      (|r ^ 2 / (dist O C ^ 2 - ρ ^ 2)| * ρ) := by
  set p := dist O C ^ 2 - ρ ^ 2 with hp_def
  set l := r ^ 2 / p with hl
  have h1 := inversion_dist_sq_aux O C x r l hxO
  have h2 := sphere_inner_aux O C x ρ hx
  have hs : ‖x - O‖ ≠ 0 := by simpa [sub_eq_zero] using hxO
  have hd : ‖C - O‖ = dist O C := by rw [dist_comm, dist_eq_norm]
  have hlp : l * p = r ^ 2 := by rw [hl]; field_simp
  have h3 : dist (inversion O r x) (O + l • (C - O)) ^ 2 = (|l| * ρ) ^ 2 := by
    apply mul_right_cancel₀ (pow_ne_zero 2 hs)
    rw [h1, mul_pow, sq_abs, hd]
    have : 2 * r ^ 2 * l * inner ℝ (x - O) (C - O) = r ^ 2 * l * (‖x - O‖ ^ 2 + p) := by
      rw [← h2]; ring
    rw [this]
    linear_combination (‖x - O‖ ^ 2 * l - r ^ 2) * hlp
  rw [Metric.mem_sphere]
  exact (sq_eq_sq₀ dist_nonneg (by positivity)).1 h3

theorem finrank_dir_aux (v : ℝ²) (hv : v ≠ 0) : Module.finrank ℝ (ℝ ∙ v)ᗮ = 1 := by
  have : Fact (Module.finrank ℝ ℝ² = 1 + 1) := ⟨by simp⟩
  exact Submodule.finrank_orthogonal_span_singleton hv

theorem perpBisector_eq_line_aux (p₁ p₂ : ℝ²) (h : p₁ ≠ p₂) :
    ∃ A B : ℝ², A ≠ B ∧ (AffineSubspace.perpBisector p₁ p₂ : Set ℝ²) = line[ℝ, A, B] := by
  have hv : p₂ -ᵥ p₁ ≠ 0 := by simpa [vsub_eq_sub, sub_eq_zero] using h.symm
  obtain ⟨f, hf0, hf⟩ := exists_perp_aux (p₂ -ᵥ p₁)
  have hfD : f ∈ (AffineSubspace.perpBisector p₁ p₂).direction := by
    rw [AffineSubspace.direction_perpBisector]
    exact Submodule.mem_orthogonal_singleton_iff_inner_right.2 hf
  have hA := AffineSubspace.midpoint_mem_perpBisector p₁ p₂
  have hB := AffineSubspace.vadd_mem_of_mem_direction hfD hA
  refine ⟨midpoint ℝ p₁ p₂, f +ᵥ midpoint ℝ p₁ p₂, ?_, ?_⟩
  · intro hAB
    apply hf0
    simpa [vadd_eq_add] using hAB.symm
  · have hle := affineSpan_pair_le_of_mem_of_mem hA hB
    have hdir : (line[ℝ, midpoint ℝ p₁ p₂, f +ᵥ midpoint ℝ p₁ p₂]).direction =
        (AffineSubspace.perpBisector p₁ p₂).direction := by
      apply Submodule.eq_of_le_of_finrank_eq (AffineSubspace.direction_le hle)
      rw [AffineSubspace.direction_perpBisector, finrank_dir_aux _ hv, direction_affineSpan,
        vectorSpan_pair, finrank_span_singleton]
      simpa [vsub_eq_sub] using hf0
    rw [AffineSubspace.eq_of_direction_eq_of_nonempty_of_le hdir
      ((AffineSubspace.nonempty_iff_ne_bot _).2 (by
        intro hb; have := left_mem_affineSpan_pair ℝ (midpoint ℝ p₁ p₂) (f +ᵥ midpoint ℝ p₁ p₂)
        rw [hb] at this; exact this)) hle]

theorem line_eq_perpBisector_aux (O A B : ℝ²) (hAB : A ≠ B) (hO : O ∉ line[ℝ, A, B]) :
    ∃ y : ℝ², y ≠ O ∧ (line[ℝ, A, B] : Set ℝ²) = AffineSubspace.perpBisector O y := by
  have : Nonempty (line[ℝ, A, B]) := ⟨⟨A, left_mem_affineSpan_pair ℝ A B⟩⟩
  refine ⟨EuclideanGeometry.reflection line[ℝ, A, B] O, ?_, ?_⟩
  · rw [Ne, EuclideanGeometry.reflection_eq_self_iff]
    exact hO
  · have hle : line[ℝ, A, B] ≤ AffineSubspace.perpBisector O
        (EuclideanGeometry.reflection line[ℝ, A, B] O) := by
      intro p hp
      rw [AffineSubspace.mem_perpBisector_iff_dist_eq,
        EuclideanGeometry.dist_reflection_eq_of_mem _ hp]
    have hv : EuclideanGeometry.reflection line[ℝ, A, B] O -ᵥ O ≠ 0 := by
      rw [Ne, vsub_eq_zero_iff_eq, EuclideanGeometry.reflection_eq_self_iff]
      exact hO
    have hdir : (line[ℝ, A, B]).direction = (AffineSubspace.perpBisector O
        (EuclideanGeometry.reflection line[ℝ, A, B] O)).direction := by
      apply Submodule.eq_of_le_of_finrank_eq (AffineSubspace.direction_le hle)
      rw [AffineSubspace.direction_perpBisector, finrank_dir_aux _ hv, direction_affineSpan,
        vectorSpan_pair, finrank_span_singleton]
      simpa [vsub_eq_sub, sub_eq_zero] using hAB
    exact congrArg (fun s : AffineSubspace ℝ ℝ² => (s : Set ℝ²))
      (AffineSubspace.eq_of_direction_eq_of_nonempty_of_le hdir
      ((AffineSubspace.nonempty_iff_ne_bot _).2 (by
        intro hb; have := left_mem_affineSpan_pair ℝ A B
        rw [hb] at this; exact this)) hle)

#print axioms inversion_dist_sq_aux
#print axioms sphere_inner_aux
#print axioms exists_perp_aux
#print axioms inversion_mem_sphere_aux
#print axioms finrank_dir_aux
#print axioms perpBisector_eq_line_aux
#print axioms line_eq_perpBisector_aux

/-- Inversion in a circle with centre `O` and radius `r > 0` turns lines and circles into lines
and circles: leaving out the centre `O` (which has no image), the image of a line or a circle
is a line or a circle, again with `O` left out. -/
theorem inversion_maps_lines_and_circles_to_lines_and_circles
    (O : ℝ²) (r : ℝ) (hr : 0 < r) (S : Set ℝ²)
    (hS : (∃ A B : ℝ², A ≠ B ∧ S = (line[ℝ, A, B] : Set ℝ²)) ∨
      (∃ (C : ℝ²) (ρ : ℝ), 0 < ρ ∧ S = Metric.sphere C ρ)) :
    ∃ T : Set ℝ²,
      ((∃ A B : ℝ², A ≠ B ∧ T = (line[ℝ, A, B] : Set ℝ²)) ∨
        (∃ (C : ℝ²) (ρ : ℝ), 0 < ρ ∧ T = Metric.sphere C ρ)) ∧
      inversion O r '' (S \ {O}) = T \ {O} := by
  have hr0 : r ≠ 0 := hr.ne'
  have hinj := inversion_injective O hr0
  rcases hS with ⟨A, B, hAB, rfl⟩ | ⟨C, ρ, hρ, rfl⟩
  · by_cases hO : O ∈ line[ℝ, A, B]
    · refine ⟨_, Or.inl ⟨A, B, hAB, rfl⟩, ?_⟩
      rw [Set.image_sdiff hinj, Set.image_singleton, inversion_self,
        image_inversion_affineSubspace_of_mem hr0 hO]
    · obtain ⟨y, hyO, hy⟩ := line_eq_perpBisector_aux O A B hAB hO
      have hyc : y ≠ O := hyO
      refine ⟨Metric.sphere (inversion O r y) (r ^ 2 / dist y O),
        Or.inr ⟨_, _, by have := dist_pos.2 hyc; positivity, rfl⟩, ?_⟩
      rw [Set.sdiff_singleton_eq_self (by simpa using hO), hy,
        image_inversion_perpBisector hr0 hyc]
  · by_cases hOS : dist O C = ρ
    · have hC : C ≠ O := by
        rintro rfl; rw [dist_self] at hOS; exact hρ.ne hOS
      have hiC : O ≠ inversion O r C := by
        rw [Ne, center_eq_inversion hr0]; exact hC
      obtain ⟨A, B, hAB, hP⟩ := perpBisector_eq_line_aux O (inversion O r C) hiC
      refine ⟨_, Or.inl ⟨A, B, hAB, hP⟩, ?_⟩
      rw [Set.image_sdiff hinj, Set.image_singleton, inversion_self, ← hOS, dist_comm,
        image_inversion_sphere_dist_center hr0 hC, Set.insert_sdiff_of_mem _ rfl]
    · set p := dist O C ^ 2 - ρ ^ 2 with hp_def
      have hp0 : p ≠ 0 := by
        intro h
        apply hOS
        have : (dist O C - ρ) * (dist O C + ρ) = 0 := by rw [← h, hp_def]; ring
        rcases mul_eq_zero.1 this with h1 | h1
        · linarith
        · linarith [dist_nonneg (x := O) (y := C)]
      set l := r ^ 2 / p with hl
      have hl0 : l ≠ 0 := div_ne_zero (pow_ne_zero 2 hr0) hp0
      have hOn : O ∉ Metric.sphere C ρ := by
        rw [Metric.mem_sphere]; exact hOS
      set C' := O + l • (C - O) with hC'
      have hdC' : dist O C' = |l| * dist O C := by
        rw [hC', dist_comm, dist_eq_norm, add_sub_cancel_left, norm_smul, Real.norm_eq_abs,
          dist_comm, dist_eq_norm]
      have hOn' : O ∉ Metric.sphere C' (|l| * ρ) := by
        rw [Metric.mem_sphere, hdC']
        intro h
        exact hOS (mul_left_cancel₀ (abs_ne_zero.2 hl0) h)
      refine ⟨Metric.sphere C' (|l| * ρ), Or.inr ⟨_, _, by positivity, rfl⟩, ?_⟩
      rw [Set.sdiff_singleton_eq_self hOn, Set.sdiff_singleton_eq_self hOn']
      apply Set.Subset.antisymm
      · rintro _ ⟨x, hx, rfl⟩
        exact inversion_mem_sphere_aux O C x r ρ hρ.le hp0 hx (fun h => hOn (h ▸ hx))
      · intro y hy
        have hyO : y ≠ O := fun h => hOn' (h ▸ hy)
        have hp' : dist O C' ^ 2 - (|l| * ρ) ^ 2 = l ^ 2 * p := by
          rw [hdC', hp_def, mul_pow, mul_pow, sq_abs]; ring
        have hp'0 : dist O C' ^ 2 - (|l| * ρ) ^ 2 ≠ 0 := by
          rw [hp']; exact mul_ne_zero (pow_ne_zero 2 hl0) hp0
        have key := inversion_mem_sphere_aux O C' y r (|l| * ρ) (by positivity) hp'0 hy hyO
        have hk : r ^ 2 / (l ^ 2 * p) * l = 1 := by
          rw [hl]; field_simp
        rw [hp', hC', add_sub_cancel_left, smul_smul, hk, one_smul, add_sub_cancel, ← mul_assoc,
          ← abs_mul, hk, abs_one, one_mul] at key
        exact ⟨_, key, inversion_inversion O hr0 y⟩

/-- Inversion keeps angles: at any point `x` other than the centre, the derivative of the
inversion sends any two directions `u`, `v` to two directions meeting at the same angle. -/
theorem inversion_preserves_angles (O x : ℝ²) (r : ℝ) (hr : 0 < r) (hx : x ≠ O) (u v : ℝ²) :
    InnerProductGeometry.angle (fderiv ℝ (inversion O r) x u) (fderiv ℝ (inversion O r) x v) =
      InnerProductGeometry.angle u v := by
  rw [fderiv_inversion]
  have hk : (r / dist x O) ^ 2 ≠ 0 := by
    have : dist x O ≠ 0 := dist_ne_zero.2 hx
    positivity
  rw [smul_apply, smul_apply, InnerProductGeometry.angle_smul_smul hk]
  exact (Submodule.reflection _).toLinearIsometry.angle_map u v


/-- A circle with centre `C` and radius `ρ`, other than the mirror itself, is its own image under
inversion in the circle with centre `O` and radius `r` exactly when the power of `O` for it,
`OC² - ρ²`, equals `r²`: exactly when it crosses the mirror at right angles. -/
theorem inversion_fixes_circle_iff_power_eq_radius_sq
    (O C : ℝ²) (r ρ : ℝ) (hr : 0 < r) (hρ : 0 < ρ) (hmirror : ¬ (C = O ∧ ρ = r)) :
    inversion O r '' Metric.sphere C ρ = Metric.sphere C ρ ↔ dist O C ^ 2 - ρ ^ 2 = r ^ 2 := by
  have hr0 : r ≠ 0 := hr.ne'
  constructor
  · intro himg
    by_contra hp
    -- every point of the circle other than `O` is at distance `r` from `O`
    have key : ∀ x ∈ Metric.sphere C ρ, x ≠ O → ‖x - O‖ ^ 2 = r ^ 2 := by
      intro x hx hxO
      have hix : inversion O r x ∈ Metric.sphere C ρ := himg ▸ Set.mem_image_of_mem _ hx
      have h1 := inversion_dist_sq_aux O C x r 1 hxO
      have h2 := sphere_inner_aux O C x ρ hx
      rw [one_smul, add_sub_cancel, Metric.mem_sphere.1 hix] at h1
      have hd : ‖C - O‖ = dist O C := by rw [dist_comm, dist_eq_norm]
      rw [hd] at h1
      have : (‖x - O‖ ^ 2 - r ^ 2) * (dist O C ^ 2 - ρ ^ 2 - r ^ 2) = 0 := by
        linear_combination (-1 : ℝ) * h1 + r ^ 2 * h2
      rcases mul_eq_zero.1 this with h | h
      · linarith
      · exact absurd (by linarith) hp
    set w := C - O with hw
    have hd : ‖w‖ = dist O C := by rw [hw, dist_comm, dist_eq_norm]
    obtain ⟨f, hf0, hwf⟩ := exists_perp_aux w
    have hfn : ‖f‖ ≠ 0 := norm_ne_zero_iff.2 hf0
    -- a point of the circle in the direction `f`
    have hx2 : C + (ρ / ‖f‖) • f ∈ Metric.sphere C ρ := by
      rw [Metric.mem_sphere, dist_eq_norm, add_sub_cancel_left, norm_smul, Real.norm_eq_abs,
        abs_of_pos (by positivity)]
      field_simp
    have hn2 : ‖C + (ρ / ‖f‖) • f - O‖ ^ 2 = ‖w‖ ^ 2 + ρ ^ 2 := by
      have : C + (ρ / ‖f‖) • f - O = w + (ρ / ‖f‖) • f := by rw [hw]; abel
      rw [this, norm_add_sq_real, inner_smul_right, hwf, norm_smul, Real.norm_eq_abs,
        abs_of_pos (by positivity)]
      field_simp
      ring
    have hx2O : C + (ρ / ‖f‖) • f ≠ O := by
      intro h
      rw [h, sub_self, norm_zero] at hn2
      nlinarith [sq_nonneg ‖w‖]
    have e2 := key _ hx2 hx2O
    rw [hn2] at e2
    by_cases hw0 : w = 0
    · apply hmirror
      refine ⟨sub_eq_zero.1 hw0, ?_⟩
      rw [hw0, norm_zero] at e2
      nlinarith
    · have hwn : ‖w‖ ≠ 0 := norm_ne_zero_iff.2 hw0
      have hx1 : C + (ρ / ‖w‖) • w ∈ Metric.sphere C ρ := by
        rw [Metric.mem_sphere, dist_eq_norm, add_sub_cancel_left, norm_smul, Real.norm_eq_abs,
          abs_of_pos (by positivity)]
        field_simp
      have hn1 : ‖C + (ρ / ‖w‖) • w - O‖ = ‖w‖ + ρ := by
        have : C + (ρ / ‖w‖) • w - O = (1 + ρ / ‖w‖) • w := by rw [hw, add_smul, one_smul]; abel
        rw [this, norm_smul, Real.norm_eq_abs, abs_of_pos (by positivity)]
        field_simp
      have hx1O : C + (ρ / ‖w‖) • w ≠ O := by
        intro h
        rw [h, sub_self, norm_zero] at hn1
        linarith [norm_nonneg w]
      have e1 := key _ hx1 hx1O
      rw [hn1] at e1
      have : 0 < ‖w‖ * ρ := by positivity
      nlinarith
  · intro hp
    have hp0 : dist O C ^ 2 - ρ ^ 2 ≠ 0 := by rw [hp]; positivity
    have hsub : ∀ x ∈ Metric.sphere C ρ, inversion O r x ∈ Metric.sphere C ρ := by
      intro x hx
      have hxO : x ≠ O := by
        rintro rfl
        rw [Metric.mem_sphere] at hx
        rw [hx, sub_self] at hp
        exact absurd hp.symm (by positivity)
      have := inversion_mem_sphere_aux O C x r ρ hρ.le hp0 hx hxO
      rwa [hp, div_self (by positivity), one_smul, add_sub_cancel, abs_one, one_mul] at this
    apply Set.Subset.antisymm
    · rintro _ ⟨x, hx, rfl⟩
      exact hsub x hx
    · intro y hy
      exact ⟨inversion O r y, hsub y hy, inversion_inversion O hr0 y⟩


-- In the unit circle, P = (1/2, 0) goes to P' = (2, 0) and Q = (1/2, 1/2) goes to Q' = (1, 1).
example : inversion (0 : ℝ²) 1 !₂[1/2, 0] = !₂[2, 0] := by
  have h : dist (!₂[1/2, 0] : ℝ²) 0 = 1/2 := by
    rw [EuclideanSpace.dist_eq]
    simp [Fin.sum_univ_two]
  rw [inversion, h]
  ext i; fin_cases i <;> norm_num

example : inversion (0 : ℝ²) 1 !₂[1/2, 1/2] = !₂[1, 1] := by
  have h : dist (!₂[1/2, 1/2] : ℝ²) 0 ^ 2 = 1/2 := by
    rw [EuclideanSpace.dist_eq, Real.sq_sqrt (by positivity)]
    simp [Fin.sum_univ_two]; norm_num
  rw [inversion, div_pow, h]
  ext i; fin_cases i <;> norm_num


-- The distances from the centre multiply to the radius squared: 1/2 × 2 = 1.
example : (1 / 2 : ℚ) * 2 = 1 := by norm_num

-- Q' = (1, 1) and P' = (2, 0) lie on the circle with centre (1, 0) and radius 1.
example : ((1 : ℚ) - 1) ^ 2 + (1 - 0) ^ 2 = 1 ^ 2 := by norm_num
example : ((2 : ℚ) - 1) ^ 2 + (0 - 0) ^ 2 = 1 ^ 2 := by norm_num

-- The circle through P = (1/2, 0), P' = (2, 0) and B = (0, 1/2) has centre (5/4, 5/4)
-- and radius squared 17/8 (= 2.125); the power of O is 25/8 - 17/8 = 1 = r².
example : ((1 / 2 : ℚ) - 5 / 4) ^ 2 + (0 - 5 / 4) ^ 2 = 17 / 8 := by norm_num
example : ((2 : ℚ) - 5 / 4) ^ 2 + (0 - 5 / 4) ^ 2 = 17 / 8 := by norm_num
example : ((0 : ℚ) - 5 / 4) ^ 2 + (1 / 2 - 5 / 4) ^ 2 = 17 / 8 := by norm_num
example : ((5 / 4 : ℚ) ^ 2 + (5 / 4) ^ 2) - 17 / 8 = 1 := by norm_num

-- The circle with centre (3/2, 0) and radius 1/2: power 2, image centre 3/4, image radius 1/4.
example : (3 / 2 : ℚ) ^ 2 - (1 / 2) ^ 2 = 2 := by norm_num
example : (1 : ℚ) * (3 / 2) / 2 = 3 / 4 ∧ (1 : ℚ) * (1 / 2) / 2 = 1 / 4 := by norm_num

#print axioms inversion_maps_lines_and_circles_to_lines_and_circles
#print axioms inversion_preserves_angles
#print axioms inversion_fixes_circle_iff_power_eq_radius_sq
