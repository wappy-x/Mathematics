-- Every rigid motion of the plane is at most three mirror flips: every distance-keeping move of the flat plane is one, two or three reflections in lines (or none), so it is a translation, a rotation, a reflection or a glide reflection.
import Mathlib.Geometry.Euclidean.Projection
import Mathlib.Geometry.Euclidean.Angle.Oriented.Rotation
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Topology.MetricSpace.Isometry
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Convex.StrictConvexBetween
import Mathlib.Analysis.InnerProductSpace.Convex

/-! The flat plane is `ℝ²` (Mathlib's `EuclideanSpace ℝ (Fin 2)`), with the usual distance; the
point `(x, y)` is `!₂[x, y]` and `⟪n, p⟫` is the dot product `n · p`. A distance-keeping move is
an `f : ℝ² → ℝ²` with `Isometry f`. A mirror is a line `n · p = c` with `n` a unit normal: below,
`mirror n c` is the line through `c n` at a right angle to `n`, and the flip in it is Mathlib's
`EuclideanGeometry.reflection`. A list of mirrors is applied in order, first mirror first. -/

open EuclideanGeometry EuclideanSpace RealInnerProductSpace

local notation "ℝ²" => EuclideanSpace ℝ (Fin 2)

/-- The mirror `n · p = c`: the line through the point `c n`, at a right angle to `n`. -/
noncomputable abbrev mirror (n : ℝ²) (c : ℝ) : AffineSubspace ℝ ℝ² :=
  AffineSubspace.mk' (c • n) (ℝ ∙ n)ᗮ

/-- The standard way round of the plane (counterclockwise from the x-axis to the y-axis),
used to measure turns. -/
noncomputable abbrev standardOrientation : Orientation ℝ ℝ² (Fin 2) :=
  (EuclideanSpace.basisFun (Fin 2) ℝ).toBasis.orientation

/-! Helper lemmas: coordinates on the plane, and the coordinate form of an isometry. -/

lemma inner_coord (n p : ℝ²) : ⟪n, p⟫ = n 0 * p 0 + n 1 * p 1 := by
  simp [PiLp.inner_apply, Fin.sum_univ_two]; ring

#print axioms inner_coord

lemma norm_one_iff (n : ℝ²) : ‖n‖ = 1 ↔ n 0 ^ 2 + n 1 ^ 2 = 1 := by
  rw [← pow_eq_one_iff_of_nonneg (norm_nonneg _) two_ne_zero, ← real_inner_self_eq_norm_sq, inner_coord]
  constructor <;> intro h <;> linarith

#print axioms norm_one_iff

lemma ext2 {p q : ℝ²} (h0 : p 0 = q 0) (h1 : q 1 = p 1) : p = q := by
  ext i; fin_cases i
  · exact h0
  · exact h1.symm

#print axioms ext2

lemma rot_coord (θ : Real.Angle) (x : ℝ²) :
    standardOrientation.rotation θ x 0 = θ.cos * x 0 - θ.sin * x 1 ∧
    standardOrientation.rotation θ x 1 = θ.sin * x 0 + θ.cos * x 1 := by
  have hJ : ∀ i, standardOrientation.rightAngleRotation x i =
      standardOrientation.areaForm x (EuclideanSpace.single i 1) := by
    intro i
    rw [← Orientation.inner_rightAngleRotation_left, EuclideanSpace.inner_single_right]
    simp
  have hω : ∀ y, standardOrientation.areaForm x y = x 0 * y 1 - x 1 * y 0 := by
    intro y
    rw [Orientation.areaForm_to_volumeForm,
      Orientation.volumeForm_robust _ (EuclideanSpace.basisFun (Fin 2) ℝ) rfl]
    simp [Module.Basis.det_apply, Matrix.det_fin_two, Module.Basis.toMatrix_apply]; ring
  rw [Orientation.rotation_apply]
  simp [hJ, hω]
  constructor <;> ring

#print axioms rot_coord

lemma iso_coords (f : ℝ² → ℝ²) (hf : Isometry f) :
    ∃ a b e : ℝ, a ^ 2 + b ^ 2 = 1 ∧ (e = 1 ∨ e = -1) ∧ ∀ p : ℝ²,
      f p 0 = a * p 0 - e * b * p 1 + f 0 0 ∧ f p 1 = b * p 0 + e * a * p 1 + f 0 1 := by
  set F := hf.affineIsometryOfStrictConvexSpace
  set L := F.linearIsometry
  have hL : ∀ p, f p = L p + f 0 := by
    intro p
    have := F.toAffineMap.linear_apply_vsub p 0
    simp only [vsub_eq_sub, sub_zero] at this
    have h2 : L p = f p - f 0 := this
    rw [h2]; abel
  set u := L (EuclideanSpace.single 0 1)
  set w := L (EuclideanSpace.single 1 1)
  have hp : ∀ p : ℝ², p = p 0 • EuclideanSpace.single 0 1 + p 1 • EuclideanSpace.single 1 1 := by
    intro p; ext i; fin_cases i <;> simp
  have hu : u 0 ^ 2 + u 1 ^ 2 = 1 := by
    rw [← norm_one_iff]; simp [u]
  have hw : w 0 ^ 2 + w 1 ^ 2 = 1 := by
    rw [← norm_one_iff]; simp [w]
  have huw : u 0 * w 0 + u 1 * w 1 = 0 := by
    rw [← inner_coord]; simp only [u, w, LinearIsometry.inner_map_map]
    simp [EuclideanSpace.inner_single_right]
  set e := u 0 * w 1 - u 1 * w 0 with he
  have hw0 : w 0 = -e * u 1 := by linear_combination (-w 0) * hu + u 0 * huw
  have hw1 : w 1 = e * u 0 := by linear_combination (-w 1) * hu + u 1 * huw
  have he2 : e ^ 2 = 1 := by linear_combination (w 0 ^ 2 + w 1 ^ 2) * hu + hw - (u 0 * w 0 + u 1 * w 1) * huw
  refine ⟨u 0, u 1, e, hu, ?_, ?_⟩
  · have : (e - 1) * (e + 1) = 0 := by linear_combination he2
    rcases mul_eq_zero.1 this with h | h
    · left; linarith
    · right; linarith
  · intro p
    have hLp : L p = p 0 • u + p 1 • w := by rw [← map_smul, ← map_smul, ← map_add, ← hp p]
    rw [hL p, hLp]
    simp only [PiLp.add_apply, PiLp.smul_apply, smul_eq_mul]
    constructor
    · rw [hw0]; ring
    · rw [hw1]; ring

#print axioms iso_coords

lemma refl_formula (n : ℝ²) (c : ℝ) (hn : ‖n‖ = 1) (p : ℝ²) :
    (p ∈ mirror n c ↔ ⟪n, p⟫ = c) ∧
      reflection (mirror n c) p = p - (2 * (⟪n, p⟫ - c)) • n := by
  have hnn : ⟪n, n⟫ = 1 := by rw [real_inner_self_eq_norm_sq, hn]; norm_num
  constructor
  · rw [AffineSubspace.mem_mk', vsub_eq_sub, Submodule.mem_orthogonal_singleton_iff_inner_right,
      inner_sub_right, inner_smul_right, hnn, sub_eq_zero, mul_one]
  · rw [reflection_apply_of_mem _ p (AffineSubspace.self_mem_mk' _ _)]
    rw [AffineSubspace.direction_mk', Submodule.reflection_orthogonal_apply,
      Submodule.reflection_apply, Submodule.starProjection_unit_singleton ℝ hn]
    simp only [vsub_eq_sub, vadd_eq_add, inner_sub_right, inner_smul_right, hnn]
    module

#print axioms refl_formula

lemma refl_coord (n : ℝ²) (c : ℝ) (hn : ‖n‖ = 1) (p : ℝ²) :
    reflection (mirror n c) p 0 = p 0 - 2 * (n 0 * p 0 + n 1 * p 1 - c) * n 0 ∧
    reflection (mirror n c) p 1 = p 1 - 2 * (n 0 * p 0 + n 1 * p 1 - c) * n 1 := by
  rw [(refl_formula n c hn p).2, inner_coord]
  simp

#print axioms refl_coord

lemma refl_vec (a b : ℝ) (hab : a ^ 2 + b ^ 2 = 1) :
    ∃ n : ℝ², ‖n‖ = 1 ∧ 1 - 2 * n 0 ^ 2 = a ∧ -2 * n 0 * n 1 = b ∧ 1 - 2 * n 1 ^ 2 = -a := by
  by_cases ha : a = 1
  · subst ha
    have hb : b = 0 := by nlinarith
    subst hb
    refine ⟨!₂[0, 1], ?_, ?_, ?_, ?_⟩ <;> simp [norm_one_iff]
    norm_num
  · have ha1 : a < 1 := lt_of_le_of_ne (by nlinarith) ha
    set s := Real.sqrt (2 - 2 * a)
    have hs : s ^ 2 = 2 - 2 * a := Real.sq_sqrt (by linarith)
    have hs0 : s ≠ 0 := by
      intro h; rw [h] at hs; linarith
    refine ⟨!₂[(1 - a) / s, -b / s], ?_, ?_, ?_, ?_⟩ <;> simp only [norm_one_iff] <;>
      simp <;> field_simp <;> rw [hs] <;> nlinarith

#print axioms refl_vec

lemma transl_two (v : ℝ²) : ∃ (m : ℝ²) (d₁ d₂ : ℝ), ‖m‖ = 1 ∧
    ∀ p, reflection (mirror m d₂) (reflection (mirror m d₁) p) = p + v := by
  by_cases hv : v = 0
  · refine ⟨!₂[1, 0], 0, 0, by simp [norm_one_iff], fun p => ?_⟩
    simp [hv]
  · have hv' : ‖v‖ ≠ 0 := norm_ne_zero_iff.2 hv
    set m := ‖v‖⁻¹ • v
    have hm : ‖m‖ = 1 := by simp [m, norm_smul, hv']
    have hmm : ⟪m, m⟫ = 1 := by rw [real_inner_self_eq_norm_sq, hm]; norm_num
    refine ⟨m, 0, ‖v‖ / 2, hm, fun p => ?_⟩
    rw [(refl_formula m _ hm _).2, (refl_formula m _ hm _).2]
    simp only [inner_sub_right, inner_smul_right, hmm]
    have : v = ‖v‖ • m := by simp only [m, smul_smul, mul_inv_cancel₀ hv', one_smul]
    rw [show p + v = p + ‖v‖ • m from by rw [← this]]
    module

#print axioms transl_two

lemma four_kinds (f : ℝ² → ℝ²) (hf : Isometry f) :
    (∃ v : ℝ², ∀ p, f p = p + v) ∨
    (∃ (c : ℝ²) (θ : Real.Angle), θ ≠ 0 ∧ ∀ p, f p = c + standardOrientation.rotation θ (p - c)) ∨
    (∃ (n : ℝ²) (c : ℝ), ‖n‖ = 1 ∧ ∀ p, f p = reflection (mirror n c) p) ∨
    (∃ (n : ℝ²) (c : ℝ) (s : ℝ²), ‖n‖ = 1 ∧ s ≠ 0 ∧ ⟪n, s⟫ = 0 ∧
      ∀ p, f p = reflection (mirror n c) p + s) := by
  obtain ⟨a, b, e, hab, he, hfp⟩ := iso_coords f hf
  set v := f 0
  rcases he with rfl | rfl
  · by_cases ha : a = 1
    · subst ha
      have hb : b = 0 := by nlinarith
      subst hb
      left
      refine ⟨v, fun p => ext2 ?_ ?_⟩
      · simp [(hfp p).1]
      · simp [(hfp p).2]
    · right; left
      have ha1 : a < 1 := lt_of_le_of_ne (by nlinarith) ha
      have hD : (2 - 2 * a) ≠ 0 := by intro h; linarith
      set z : ℂ := ⟨a, b⟩
      have hz : ‖z‖ = 1 := by
        rw [Complex.norm_def, Complex.normSq_mk]
        simp [show a * a + b * b = 1 by nlinarith]
      have hz0 : z ≠ 0 := by intro h; rw [h] at hz; simp at hz
      set θ : Real.Angle := (Complex.arg z : Real.Angle)
      have hcos : θ.cos = a := by
        simp only [θ, Real.Angle.cos_coe, Complex.cos_arg hz0, hz, div_one]; rfl
      have hsin : θ.sin = b := by
        simp only [θ, Real.Angle.sin_coe, Complex.sin_arg, hz, div_one]; rfl
      refine ⟨!₂[((1 - a) * v 0 - b * v 1) / (2 - 2 * a), (b * v 0 + (1 - a) * v 1) / (2 - 2 * a)],
        θ, ?_, fun p => ext2 ?_ ?_⟩
      · intro h; rw [h, Real.Angle.cos_zero] at hcos; exact ha hcos.symm
      · simp [(hfp p).1, (rot_coord θ _).1, hcos, hsin]
        field_simp
        linear_combination (-v 0) * hab
      · simp [(hfp p).2, (rot_coord θ _).2, hcos, hsin]
        field_simp
        linear_combination (v 1) * hab
  · right; right
    obtain ⟨n, hn, h1, h2, h3⟩ := refl_vec a b hab
    set k := n 0 * v 0 + n 1 * v 1
    set s := v - k • n
    have hns : ⟪n, s⟫ = 0 := by
      simp only [s, inner_sub_right, inner_smul_right, real_inner_self_eq_norm_sq, hn, inner_coord]
      ring
    have key : ∀ p, f p = reflection (mirror n (k / 2)) p + s := by
      intro p
      apply ext2
      · simp [(hfp p).1, (refl_coord n _ hn p).1, s]
        linear_combination (-p 0) * h1 - p 1 * h2
      · simp [(hfp p).2, (refl_coord n _ hn p).2, s]
        linear_combination p 1 * h3 + p 0 * h2
    by_cases hs : s = 0
    · left
      exact ⟨n, k / 2, hn, fun p => by rw [key p, hs, add_zero]⟩
    · right
      exact ⟨n, k / 2, s, hn, hs, hns, key⟩

#print axioms four_kinds

/-- The three reflections theorem. Every distance-keeping move `f` of the flat plane is at most
three mirror flips: there are at most three mirrors `n · p = c` (each `n` a unit normal) such
that flipping in them, first mirror first, moves every point exactly as `f` does. -/
theorem isometry_of_plane_is_at_most_three_reflections (f : ℝ² → ℝ²) (hf : Isometry f) :
    ∃ ms : List (ℝ² × ℝ), ms.length ≤ 3 ∧ (∀ m ∈ ms, ‖m.1‖ = 1) ∧
      ∀ p, f p = ms.foldl (fun q m => reflection (mirror m.1 m.2) q) p := by
  rcases four_kinds f hf with ⟨v, hv⟩ | ⟨c, θ, -, hrot⟩ | ⟨n, c, hn, hr⟩ |
      ⟨n, c, s, hn, -, -, hg⟩
  · obtain ⟨m, d₁, d₂, hm, ht⟩ := transl_two v
    refine ⟨[(m, d₁), (m, d₂)], by simp, by simp [hm], fun p => ?_⟩
    simp [hv p, ht p]
  · obtain ⟨n, hn, h1, h2, h3⟩ := refl_vec θ.cos θ.sin (Real.Angle.cos_sq_add_sin_sq θ)
    have he : ‖(!₂[0, 1] : ℝ²)‖ = 1 := by simp [norm_one_iff]
    refine ⟨[(!₂[0, 1], c 1), (n, n 0 * c 0 + n 1 * c 1)], by simp, by simp [hn, he],
      fun p => ?_⟩
    simp only [List.foldl_cons, List.foldl_nil]
    rw [hrot p]
    apply ext2
    · simp [(rot_coord θ _).1, (refl_coord n _ hn _).1, (refl_coord _ _ he _).1,
        (refl_coord _ _ he _).2]
      linear_combination -(p 0 - c 0) * h1 + (p 1 - c 1) * h2
    · simp [(rot_coord θ _).2, (refl_coord n _ hn _).2, (refl_coord _ _ he _).1,
        (refl_coord _ _ he _).2]
      linear_combination (p 0 - c 0) * h2 - (p 1 - c 1) * h3
  · exact ⟨[(n, c)], by simp, by simp [hn], fun p => by simp [hr p]⟩
  · obtain ⟨m, d₁, d₂, hm, ht⟩ := transl_two s
    refine ⟨[(n, c), (m, d₁), (m, d₂)], by simp, by simp [hn, hm], fun p => ?_⟩
    simp [hg p, ht]

/-- Only four kinds. Every distance-keeping move `f` of the flat plane is a translation (a slide
by some `v`, the identity being the slide by 0), a rotation about some point `c` by a nonzero
angle `θ`, a reflection in some mirror, or a glide reflection: a flip in some mirror followed by
a nonzero slide `s` along that mirror. -/
theorem isometry_of_plane_is_one_of_four_kinds (f : ℝ² → ℝ²) (hf : Isometry f) :
    (∃ v : ℝ², ∀ p, f p = p + v) ∨
    (∃ (c : ℝ²) (θ : Real.Angle), θ ≠ 0 ∧ ∀ p, f p = c + standardOrientation.rotation θ (p - c)) ∨
    (∃ (n : ℝ²) (c : ℝ), ‖n‖ = 1 ∧ ∀ p, f p = reflection (mirror n c) p) ∨
    (∃ (n : ℝ²) (c : ℝ) (s : ℝ²), ‖n‖ = 1 ∧ s ≠ 0 ∧ ⟪n, s⟫ = 0 ∧
      ∀ p, f p = reflection (mirror n c) p + s) := by
  exact four_kinds f hf

/-- The flip formula. For a unit normal `n` and a number `c`, the points of `mirror n c` are
exactly the points `p` with `n · p = c`, and the flip in it sends `p` to
`ρ(p) = p − 2 (n · p − c) n`. -/
theorem reflection_in_mirror_eq_formula (n : ℝ²) (c : ℝ) (hn : ‖n‖ = 1) (p : ℝ²) :
    (p ∈ mirror n c ↔ ⟪n, p⟫ = c) ∧
      reflection (mirror n c) p = p - (2 * (⟪n, p⟫ - c)) • n := by
  exact refl_formula n c hn p

/-! The card's whole-number examples. Every mirror in them has the unit normal `(1, 0)` or
`(0, 1)` or `(1, -1)/√2`; the first two have whole-number entries, so the flip formula
`ρ(p) = p − 2 (n · p − c) n` can be run exactly on whole-number points. -/

/-- The card's flip formula on whole-number points, for the mirrors `x = c` (`n = (1, 0)`) and
`y = c` (`n = (0, 1)`). -/
def flipZ (n : ℤ × ℤ) (c : ℤ) (p : ℤ × ℤ) : ℤ × ℤ :=
  p - (2 * (n.1 * p.1 + n.2 * p.2 - c)) • n

-- The glide (x, y) ↦ (x + 2, −y): the flips in x = 0, x = 1, y = 0 give it on the anchors
-- O (0, 0), X (1, 0), Y (0, 1) and on a sample point (5, −3).
example : [((0, 0) : ℤ × ℤ), (1, 0), (0, 1), (5, -3)].map
    (fun p => flipZ (0, 1) 0 (flipZ (1, 0) 1 (flipZ (1, 0) 0 p))) =
    [(2, 0), (3, 0), (2, -1), (7, 3)] := by decide
-- Flips in x = 0, then x = 1, slide everything 2 to the right: twice the gap of 1.
example : [((0, 0) : ℤ × ℤ), (1, 0), (0, 1), (-4, 7)].map
    (fun p => flipZ (1, 0) 1 (flipZ (1, 0) 0 p)) = [(2, 0), (3, 0), (2, 1), (-2, 7)] := by decide
-- Worked numbers, by hand: the recipe's mirrors x = 1, x = 2, y = 0 move the anchors
-- O, X, Y to (2, 0), (1, 0), (2, 1); then (2, 0), (3, 0), (2, 1); then (2, 0), (3, 0), (2, −1).
example : [((0, 0) : ℤ × ℤ), (1, 0), (0, 1)].map (flipZ (1, 0) 1) = [(2, 0), (1, 0), (2, 1)] ∧
    [((2, 0) : ℤ × ℤ), (1, 0), (2, 1)].map (flipZ (1, 0) 2) = [(2, 0), (3, 0), (2, 1)] ∧
    [((2, 0) : ℤ × ℤ), (3, 0), (2, 1)].map (flipZ (0, 1) 0) = [(2, 0), (3, 0), (2, -1)] := by
  decide
-- The glide done twice sends (0, 0) to (4, 0), so it is not a reflection.
example : (fun p : ℤ × ℤ => (p.1 + 2, -p.2)) ((fun p : ℤ × ℤ => (p.1 + 2, -p.2)) (0, 0)) =
    (4, 0) := by decide
-- Matrices: the flip in the x-axis is [[1, 0], [0, −1]] and in y = x is [[0, 1], [1, 0]];
-- x-axis first, then y = x, gives the quarter turn [[0, −1], [1, 0]], det +1. The other order
-- turns the other way, sending (1, 0) to (0, −1). The glide's matrix has det −1.
example : (!![0, 1; 1, 0] * !![1, 0; 0, -1] : Matrix (Fin 2) (Fin 2) ℤ) = !![0, -1; 1, 0] ∧
    (!![1, 0; 0, -1] * !![0, 1; 1, 0] : Matrix (Fin 2) (Fin 2) ℤ) = !![0, 1; -1, 0] ∧
    (!![0, -1; 1, 0] : Matrix (Fin 2) (Fin 2) ℤ).det = 1 ∧
    (!![1, 0; 0, -1] : Matrix (Fin 2) (Fin 2) ℤ).det = -1 := by
  decide

#print axioms isometry_of_plane_is_at_most_three_reflections
#print axioms isometry_of_plane_is_one_of_four_kinds
#print axioms reflection_in_mirror_eq_formula
