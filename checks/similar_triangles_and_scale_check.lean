-- Similar triangles: two equal angles force every side to scale by one factor k and the area by k squared, and a line parallel to one side cuts the other two sides in the same ratio.
import Mathlib.Geometry.Euclidean.Volume.Triangle
import Mathlib.Geometry.Euclidean.Angle.Unoriented.Affine
import Mathlib.LinearAlgebra.AffineSpace.AffineSubspace.Basic
import Mathlib.Analysis.Convex.Between
import Mathlib.Geometry.Euclidean.Similarity

open EuclideanGeometry

/-- The AA test with its consequences, in flat (Euclidean) geometry: if two angles of one
triangle equal the matching two angles of another, then there is one scale factor `k > 0`
such that every side of the second triangle is `k` times the matching side of the first,
and the area of the second is `k ^ 2` times the area of the first. -/
theorem similar_of_two_angles_sides_scale_area_scales_sq
    {V₁ V₂ P₁ P₂ : Type*}
    [NormedAddCommGroup V₁] [InnerProductSpace ℝ V₁] [MetricSpace P₁] [NormedAddTorsor V₁ P₁]
    [NormedAddCommGroup V₂] [InnerProductSpace ℝ V₂] [MetricSpace P₂] [NormedAddTorsor V₂ P₂]
    (t : Affine.Triangle ℝ P₁) (t' : Affine.Triangle ℝ P₂)
    (h₁ : ∠ (t.points 0) (t.points 1) (t.points 2) = ∠ (t'.points 0) (t'.points 1) (t'.points 2))
    (h₂ : ∠ (t.points 1) (t.points 2) (t.points 0) = ∠ (t'.points 1) (t'.points 2) (t'.points 0)) :
    ∃ k : ℝ, 0 < k ∧
      (∀ i j : Fin 3, dist (t'.points i) (t'.points j) = k * dist (t.points i) (t.points j)) ∧
      t'.volume = k ^ 2 * t.volume := by
  have e1 : ![t.points 0, t.points 1, t.points 2] = t.points := by
    funext k; fin_cases k <;> rfl
  have e2 : ![t'.points 0, t'.points 1, t'.points 2] = t'.points := by
    funext k; fin_cases k <;> rfl
  have hnc : ¬ Collinear ℝ ({t.points 0, t.points 1, t.points 2} : Set P₁) := by
    rw [← affineIndependent_iff_not_collinear_set, e1]
    exact t.independent
  have hsim := similar_of_angle_angle hnc h₁ h₂
  obtain ⟨r, hr, hd⟩ := (similar_iff_exists_pos_dist_eq).1 hsim
  rw [e1, e2] at hd
  have key : ∀ i j : Fin 3,
      dist (t'.points i) (t'.points j) = r⁻¹ * dist (t.points i) (t.points j) := by
    intro i j
    rw [hd i j]
    field_simp
  refine ⟨r⁻¹, inv_pos.2 hr, key, ?_⟩
  rw [t.volume_eq_mul_sin (i₁ := 0) (i₂ := 1) (i₃ := 2) (by decide) (by decide) (by decide),
    t'.volume_eq_mul_sin (i₁ := 0) (i₂ := 1) (i₃ := 2) (by decide) (by decide) (by decide),
    key 0 1, key 1 2, ← h₁]
  ring

/-- The parallel cut (Euclid VI.2): in a triangle `T B C`, take `D` on side `TB` and `E` on
side `TC` with line `DE` parallel to `BC`. Then `D` cuts `TB` in the same ratio as `E`
cuts `TC`: `TD / TB = TE / TC`. -/
theorem parallel_cut_divides_sides_proportionally
    {V P : Type*}
    [NormedAddCommGroup V] [InnerProductSpace ℝ V] [MetricSpace P] [NormedAddTorsor V P]
    {T B C D E : P}
    (hT : ¬ Collinear ℝ ({T, B, C} : Set P))
    (hD : Wbtw ℝ T D B) (hE : Wbtw ℝ T E C)
    (hpar : (line[ℝ, D, E]).Parallel (line[ℝ, B, C])) :
    dist T D / dist T B = dist T E / dist T C := by
  have hTB : T ≠ B := ne₁₂_of_not_collinear hT
  have hTC : T ≠ C := ne₁₃_of_not_collinear hT
  have hli : LinearIndependent ℝ ![B -ᵥ T, C -ᵥ T] := by
    have hai := affineIndependent_iff_not_collinear_set.2 hT
    rw [affineIndependent_iff_linearIndependent_vsub ℝ _ (0 : Fin 3)] at hai
    let f : Fin 2 → {x : Fin 3 // x ≠ 0} := ![⟨1, by decide⟩, ⟨2, by decide⟩]
    have hf : Function.Injective f := by decide
    have h := hai.comp f hf
    convert h using 1
    funext i
    fin_cases i <;> rfl
  obtain ⟨s, -, rfl⟩ := hD
  obtain ⟨u, -, rfl⟩ := hE
  have hdir := hpar.direction_eq
  rw [direction_affineSpan, direction_affineSpan, vectorSpan_pair, vectorSpan_pair] at hdir
  have hmem : AffineMap.lineMap T B s -ᵥ AffineMap.lineMap T C u ∈ ℝ ∙ (B -ᵥ C) :=
    hdir ▸ Submodule.mem_span_singleton_self _
  obtain ⟨l, hl⟩ := Submodule.mem_span_singleton.1 hmem
  rw [AffineMap.lineMap_apply, AffineMap.lineMap_apply, vadd_vsub_vadd_cancel_right,
    ← vsub_sub_vsub_cancel_right B C T] at hl
  have h0 : (s - l) • (B -ᵥ T) + (l - u) • (C -ᵥ T) = 0 := by
    rw [smul_sub] at hl
    rw [sub_smul, sub_smul]
    have : s • (B -ᵥ T) - u • (C -ᵥ T) - (l • (B -ᵥ T) - l • (C -ᵥ T)) = 0 := by
      rw [hl, sub_self]
    rw [← this]
    abel
  obtain ⟨h1, h2⟩ := LinearIndependent.pair_iff.1 hli _ _ h0
  have hsu : s = u := by linarith
  subst hsu
  rw [dist_left_lineMap, dist_left_lineMap,
    mul_div_cancel_right₀ _ (dist_ne_zero.2 hTB), mul_div_cancel_right₀ _ (dist_ne_zero.2 hTC)]

-- The flagpole, in centimetres: shadows 960 cm and 80 cm give the scale factor 12.
example : (960 : ℚ) / 80 = 12 := by norm_num
-- The pole's height: the 100 cm stick times the factor is 1200 cm, that is 12 m.
example : (100 : ℚ) * (960 / 80) = 1200 := by norm_num
-- Areas, half base times height: stick 4000 cm^2, pole 576000 cm^2, ratio 144 = 12 * 12.
example : (100 * 80 / 2 : ℚ) = 4000 := by norm_num
example : (1200 * 960 / 2 : ℚ) = 576000 := by norm_num
example : (576000 : ℚ) / 4000 = 12 ^ 2 := by norm_num
example : (12 : ℕ) * 12 = 144 := by decide
-- The river: factor 30 / 10 = 3, so the width is 6 * 3 = 18 m.
example : (30 : ℚ) / 10 = 3 := by norm_num
example : (6 : ℚ) * (30 / 10) = 18 := by norm_num
-- The mistake of reading the stick's shadow later, at 120 cm: the pole comes out at 800 cm.
example : (100 : ℚ) * 960 / 120 = 800 := by norm_num

#print axioms similar_of_two_angles_sides_scale_area_scales_sq
#print axioms parallel_cut_divides_sides_proportionally
