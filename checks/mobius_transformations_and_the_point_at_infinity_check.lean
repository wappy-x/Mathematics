-- Mobius transformations: on the plane plus one point at infinity, a map (az + b)/(cz + d) with ad − bc not zero carries every circle and every line onto a circle or a line, is undone by the map (dw − b)/(−cw + a), and composes like its 2 by 2 matrix.
import Mathlib.Analysis.Complex.Basic
import Mathlib.Topology.Compactification.OnePoint.Basic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

open Complex OnePoint

noncomputable section

open Classical in
/-- The Mobius map T(z) = (az + b)/(cz + d) on the plane plus one point ∞ (`OnePoint ℂ`),
with the card's two rules: the pole, where cz + d = 0, goes to ∞; and ∞ goes to a/c, or stays
at ∞ when c = 0. -/
def mobius (a b c d : ℂ) : OnePoint ℂ → OnePoint ℂ
  | ∞ => if c = 0 then ∞ else ((a / c : ℂ) : OnePoint ℂ)
  | (z : ℂ) => if c * z + d = 0 then ∞ else (((a * z + b) / (c * z + d) : ℂ) : OnePoint ℂ)

/-- A set of points of the plane plus ∞ is a circle or a line: either a circle |z − p| = r with
radius r > 0 (∞ not on it), or a straight line {u + t·v : t real} with direction v ≠ 0,
together with the one point ∞. -/
def IsCircleOrLine (S : Set (OnePoint ℂ)) : Prop :=
  (∃ p : ℂ, ∃ r : ℝ, 0 < r ∧ S = (fun z : ℂ => (z : OnePoint ℂ)) '' Metric.sphere p r) ∨
  (∃ u v : ℂ, v ≠ 0 ∧
    S = insert ∞ ((fun z : ℂ => (z : OnePoint ℂ)) '' Set.range (fun t : ℝ => u + (t : ℂ) * v)))

theorem mobius_comp_aux (a b c d a' b' c' d' : ℂ) (h' : a' * d' - b' * c' ≠ 0) (x : OnePoint ℂ) :
    mobius a b c d (mobius a' b' c' d' x) =
      mobius (a * a' + b * c') (a * b' + b * d') (c * a' + d * c') (c * b' + d * d') x := by
  induction x using OnePoint.rec with
  | infty =>
    by_cases hc' : c' = 0
    · have ha' : a' ≠ 0 := by rintro rfl; simp [hc'] at h'
      simp only [mobius, hc', ite_true, mul_zero, add_zero]
      by_cases hc : c = 0
      · simp [hc]
      · simp [hc, ha', mul_div_mul_right]
    · have key : c * (a' / c') + d = (c * a' + d * c') / c' := by field_simp
      simp only [mobius, hc', ite_false, key, div_eq_zero_iff, or_false]
      split_ifs with h1
      · rfl
      · congr 1
        field_simp
  | coe z =>
    by_cases hz : c' * z + d' = 0
    · have hn : a' * z + b' ≠ 0 := by
        intro hn; apply h'; linear_combination a' * hz - c' * hn
      have hden : (c * a' + d * c') * z + (c * b' + d * d') = c * (a' * z + b') := by
        linear_combination d * hz
      have hnum : (a * a' + b * c') * z + (a * b' + b * d') = a * (a' * z + b') := by
        linear_combination b * hz
      simp only [mobius, hz, ite_true, hden, hnum]
      by_cases hc : c = 0
      · simp [hc]
      · simp [hc, hn, mul_div_mul_right]
    · have hden : c * ((a' * z + b') / (c' * z + d')) + d
          = ((c * a' + d * c') * z + (c * b' + d * d')) / (c' * z + d') := by
        rw [eq_div_iff hz, add_mul, mul_assoc, div_mul_cancel₀ _ hz]; ring
      have hnum : a * ((a' * z + b') / (c' * z + d')) + b
          = ((a * a' + b * c') * z + (a * b' + b * d')) / (c' * z + d') := by
        rw [eq_div_iff hz, add_mul, mul_assoc, div_mul_cancel₀ _ hz]; ring
      simp only [mobius, hz, ite_false, hden, hnum, div_eq_zero_iff, or_false]
      split_ifs with h1
      · rfl
      · rw [div_div_div_cancel_right₀ hz]

theorem mobius_congr_aux {a b c d a₂ b₂ c₂ d₂ : ℂ} (h1 : a = a₂) (h2 : b = b₂) (h3 : c = c₂)
    (h4 : d = d₂) : mobius a b c d = mobius a₂ b₂ c₂ d₂ := by
  subst h1 h2 h3 h4; rfl

theorem mobius_scalar_aux (k : ℂ) (hk : k ≠ 0) (x : OnePoint ℂ) : mobius k 0 0 k x = x := by
  induction x using OnePoint.rec with
  | infty => simp [mobius]
  | coe z => simp [mobius, hk, mul_div_cancel_left₀]

/-- The set of solutions of `A (x² + y²) + B₁ x + B₂ y + C = 0`, together with `∞` when `A = 0`. -/
def genCircle_aux (A B₁ B₂ C : ℝ) : Set (OnePoint ℂ) :=
  {w | (w = ∞ ∧ A = 0) ∨
    ∃ z : ℂ, w = (z : OnePoint ℂ) ∧ A * (z.re ^ 2 + z.im ^ 2) + B₁ * z.re + B₂ * z.im + C = 0}

theorem mem_genCircle_infty_aux (A B₁ B₂ C : ℝ) : ∞ ∈ genCircle_aux A B₁ B₂ C ↔ A = 0 := by
  simp [genCircle_aux]

theorem mem_genCircle_coe_aux (A B₁ B₂ C : ℝ) (z : ℂ) :
    (z : OnePoint ℂ) ∈ genCircle_aux A B₁ B₂ C ↔
      A * (z.re ^ 2 + z.im ^ 2) + B₁ * z.re + B₂ * z.im + C = 0 := by
  simp [genCircle_aux]

theorem isCircleOrLine_to_genCircle_aux (S : Set (OnePoint ℂ)) (hS : IsCircleOrLine S) :
    ∃ A B₁ B₂ C : ℝ, 4 * A * C < B₁ ^ 2 + B₂ ^ 2 ∧ S = genCircle_aux A B₁ B₂ C := by
  rcases hS with ⟨p, r, hr, rfl⟩ | ⟨u, v, hv, rfl⟩
  · refine ⟨1, -2 * p.re, -2 * p.im, p.re ^ 2 + p.im ^ 2 - r ^ 2, by nlinarith, ?_⟩
    ext w
    induction w using OnePoint.rec with
    | infty => simp [genCircle_aux]
    | coe z =>
      rw [mem_genCircle_coe_aux, Set.mem_image]
      simp only [OnePoint.coe_eq_coe, exists_eq_right, Metric.mem_sphere, Complex.dist_eq]
      rw [← sq_eq_sq₀ (norm_nonneg _) hr.le, Complex.sq_norm, Complex.normSq_apply,
        Complex.sub_re, Complex.sub_im]
      constructor <;> intro h <;> linarith
  · have hN : 0 < v.re ^ 2 + v.im ^ 2 := by
      have := Complex.normSq_pos.mpr hv
      rw [Complex.normSq_apply] at this; nlinarith
    refine ⟨0, -v.im, v.re, v.im * u.re - v.re * u.im, by nlinarith, ?_⟩
    ext w
    induction w using OnePoint.rec with
    | infty => simp [genCircle_aux]
    | coe z =>
      rw [mem_genCircle_coe_aux, Set.mem_insert_iff, Set.mem_image]
      simp only [OnePoint.coe_ne_infty, false_or, OnePoint.coe_eq_coe, exists_eq_right,
        Set.mem_range]
      constructor
      · rintro ⟨t, rfl⟩
        simp
        ring
      · intro h
        set t : ℝ := ((z.re - u.re) * v.re + (z.im - u.im) * v.im) / (v.re ^ 2 + v.im ^ 2) with ht
        refine ⟨t, ?_⟩
        apply Complex.ext
        · simp only [Complex.add_re, Complex.re_ofReal_mul]
          rw [ht]
          field_simp
          linear_combination v.im * h
        · simp only [Complex.add_im, Complex.im_ofReal_mul]
          rw [ht]
          field_simp
          linear_combination -v.re * h

theorem genCircle_to_isCircleOrLine_aux (A B₁ B₂ C : ℝ) (hn : 4 * A * C < B₁ ^ 2 + B₂ ^ 2) :
    IsCircleOrLine (genCircle_aux A B₁ B₂ C) := by
  by_cases hA : A = 0
  · subst hA
    have hN : 0 < B₁ ^ 2 + B₂ ^ 2 := by linarith
    have hv : (⟨-B₂, B₁⟩ : ℂ) ≠ 0 := by
      intro h0
      have h1 := congrArg Complex.re h0
      have h2 := congrArg Complex.im h0
      simp at h1 h2
      subst h1 h2
      simp at hN
    right
    refine ⟨⟨-C * B₁ / (B₁ ^ 2 + B₂ ^ 2), -C * B₂ / (B₁ ^ 2 + B₂ ^ 2)⟩, ⟨-B₂, B₁⟩, hv, ?_⟩
    ext w
    induction w using OnePoint.rec with
    | infty => simp [genCircle_aux]
    | coe z =>
      rw [mem_genCircle_coe_aux, Set.mem_insert_iff, Set.mem_image]
      simp only [OnePoint.coe_ne_infty, false_or, OnePoint.coe_eq_coe, exists_eq_right,
        Set.mem_range]
      constructor
      · intro h
        set t : ℝ := (-B₂ * z.re + B₁ * z.im) / (B₁ ^ 2 + B₂ ^ 2) with ht
        refine ⟨t, ?_⟩
        apply Complex.ext
        · simp only [Complex.add_re, Complex.re_ofReal_mul]
          rw [ht]
          field_simp
          linear_combination -B₁ * h
        · simp only [Complex.add_im, Complex.im_ofReal_mul]
          rw [ht]
          field_simp
          linear_combination -B₂ * h
      · rintro ⟨t, rfl⟩
        simp
        field_simp
        ring
  · left
    have hD : 0 < B₁ ^ 2 + B₂ ^ 2 - 4 * A * C := by linarith
    have hApos : 0 < |A| := abs_pos.mpr hA
    refine ⟨⟨-B₁ / (2 * A), -B₂ / (2 * A)⟩, Real.sqrt (B₁ ^ 2 + B₂ ^ 2 - 4 * A * C) / (2 * |A|),
      by positivity, ?_⟩
    ext w
    induction w using OnePoint.rec with
    | infty => simp [genCircle_aux, hA]
    | coe z =>
      rw [mem_genCircle_coe_aux, Set.mem_image]
      simp only [OnePoint.coe_eq_coe, exists_eq_right, Metric.mem_sphere, Complex.dist_eq]
      rw [← sq_eq_sq₀ (norm_nonneg _) (by positivity), Complex.sq_norm, Complex.normSq_apply,
        Complex.sub_re, Complex.sub_im, div_pow, Real.sq_sqrt hD.le, mul_pow, sq_abs]
      have key : (z.re - -B₁ / (2 * A)) * (z.re - -B₁ / (2 * A)) +
          (z.im - -B₂ / (2 * A)) * (z.im - -B₂ / (2 * A)) -
            (B₁ ^ 2 + B₂ ^ 2 - 4 * A * C) / (2 ^ 2 * A ^ 2) =
          (A * (z.re ^ 2 + z.im ^ 2) + B₁ * z.re + B₂ * z.im + C) / A := by
        field_simp
        ring
      dsimp only
      conv_rhs => rw [← sub_eq_zero, key, div_eq_zero_iff, or_iff_left hA]

theorem mobius_inv_involutive_aux (w : OnePoint ℂ) : mobius 0 1 1 0 (mobius 0 1 1 0 w) = w := by
  rw [mobius_comp_aux _ _ _ _ _ _ _ _ (by norm_num) w,
    mobius_congr_aux (a₂ := 1) (b₂ := 0) (c₂ := 0) (d₂ := 1) (by ring) (by ring) (by ring)
      (by ring), mobius_scalar_aux 1 one_ne_zero]

theorem mobius_inv_genCircle_aux (A B₁ B₂ C : ℝ) :
    mobius 0 1 1 0 '' genCircle_aux A B₁ B₂ C = genCircle_aux C B₁ (-B₂) A := by
  rw [Set.image_eq_preimage_of_inverse mobius_inv_involutive_aux mobius_inv_involutive_aux]
  ext w
  rw [Set.mem_preimage]
  induction w using OnePoint.rec with
  | infty =>
    simp only [mobius, one_ne_zero, ite_false, zero_div]
    rw [mem_genCircle_coe_aux, mem_genCircle_infty_aux]
    simp
  | coe z =>
    by_cases hz : z = 0
    · subst hz
      simp only [mobius, mul_zero, add_zero, ite_true]
      rw [mem_genCircle_coe_aux, mem_genCircle_infty_aux]
      simp
    · simp only [mobius, zero_mul, zero_add, one_mul, add_zero]
      rw [if_neg hz]
      rw [mem_genCircle_coe_aux, mem_genCircle_coe_aux]
      have hρ : 0 < z.re * z.re + z.im * z.im := by
        have := Complex.normSq_pos.mpr hz
        rwa [Complex.normSq_apply] at this
      have key : A * ((1 / z).re ^ 2 + (1 / z).im ^ 2) + B₁ * (1 / z).re + B₂ * (1 / z).im + C =
          (C * (z.re ^ 2 + z.im ^ 2) + B₁ * z.re + -B₂ * z.im + A) / (z.re * z.re + z.im * z.im) := by
        have hρ2 : z.re ^ 2 + z.im ^ 2 ≠ 0 := by nlinarith
        rw [one_div, Complex.inv_re, Complex.inv_im, Complex.normSq_apply,
          show z.re * z.re + z.im * z.im = z.re ^ 2 + z.im ^ 2 by ring]
        field_simp
        ring
      rw [key, div_eq_zero_iff, or_iff_left hρ.ne']

theorem mobius_affine_aux (α β : ℂ) (hα : α ≠ 0) (S : Set (OnePoint ℂ)) (hS : IsCircleOrLine S) :
    IsCircleOrLine (mobius α β 0 1 '' S) := by
  have hcoe : ∀ z : ℂ, mobius α β 0 1 (z : OnePoint ℂ) = ((α * z + β : ℂ) : OnePoint ℂ) := by
    intro z; simp [mobius]
  have hinf : mobius α β 0 1 ∞ = ∞ := by simp [mobius]
  rcases hS with ⟨p, r, hr, rfl⟩ | ⟨u, v, hv, rfl⟩
  · left
    have hαn : 0 < ‖α‖ := norm_pos_iff.mpr hα
    refine ⟨α * p + β, ‖α‖ * r, by positivity, ?_⟩
    ext w
    simp only [Set.mem_image]
    constructor
    · rintro ⟨_, ⟨z, hz, rfl⟩, rfl⟩
      refine ⟨α * z + β, ?_, (hcoe z).symm⟩
      rw [Metric.mem_sphere, Complex.dist_eq, show α * z + β - (α * p + β) = α * (z - p) by ring,
        norm_mul, ← Complex.dist_eq, Metric.mem_sphere.mp hz]
    · rintro ⟨y, hy, rfl⟩
      refine ⟨((y - β) / α : ℂ), ⟨(y - β) / α, ?_, rfl⟩, ?_⟩
      · rw [Metric.mem_sphere, Complex.dist_eq,
          show (y - β) / α - p = (y - (α * p + β)) / α by field_simp; ring, norm_div,
          ← Complex.dist_eq, Metric.mem_sphere.mp hy]
        field_simp
      · rw [hcoe]
        congr 1
        field_simp
        ring
  · right
    refine ⟨α * u + β, α * v, mul_ne_zero hα hv, ?_⟩
    rw [Set.image_insert_eq, hinf, Set.image_image, ← Set.range_comp, ← Set.range_comp]
    congr 2
    funext t
    simp only [Function.comp, hcoe]
    congr 1
    ring

/-- **Circles and lines go to circles and lines.** Let T(z) = (az + b)/(cz + d) with
ad − bc ≠ 0, acting on the plane plus the one point ∞. Then T carries every circle, and every
line with ∞ added, onto a circle or a line with ∞ added: the image set is again a circle or a
line. -/
theorem mobius_maps_circles_and_lines_to_circles_and_lines
    (a b c d : ℂ) (h : a * d - b * c ≠ 0) (S : Set (OnePoint ℂ)) (hS : IsCircleOrLine S) :
    IsCircleOrLine (mobius a b c d '' S) := by
  by_cases hc : c = 0
  · subst hc
    have had : a * d ≠ 0 := by simpa using h
    have ha : a ≠ 0 := left_ne_zero_of_mul had
    have hd : d ≠ 0 := right_ne_zero_of_mul had
    have e : mobius a b 0 d = mobius (a / d) (b / d) 0 1 := by
      funext x
      have := mobius_comp_aux d⁻¹ 0 0 d⁻¹ a b 0 d h x
      rw [mobius_scalar_aux _ (inv_ne_zero hd)] at this
      rw [this]
      apply congrFun
      apply mobius_congr_aux <;> field_simp <;> ring
    rw [e]
    exact mobius_affine_aux _ _ (div_ne_zero ha hd) S hS
  · have hα : (b * c - a * d) / c ≠ 0 := by
      apply div_ne_zero _ hc
      intro h0; apply h; linear_combination -h0
    have e : mobius a b c d =
        mobius ((b * c - a * d) / c) (a / c) 0 1 ∘ (mobius 0 1 1 0 ∘ mobius c d 0 1) := by
      funext x
      simp only [Function.comp]
      rw [mobius_comp_aux 0 1 1 0 c d 0 1 (by simpa using hc),
        mobius_comp_aux _ _ 0 1 _ _ _ _ (by simpa using hc)]
      apply congrFun
      apply mobius_congr_aux <;> field_simp <;> ring
    rw [e, Set.image_comp, Set.image_comp]
    apply mobius_affine_aux _ _ hα
    obtain ⟨A, B₁, B₂, C, hn, hS'⟩ :=
      isCircleOrLine_to_genCircle_aux _ (mobius_affine_aux c d hc S hS)
    rw [hS', mobius_inv_genCircle_aux]
    apply genCircle_to_isCircleOrLine_aux
    nlinarith

/-- **The undo is the swapped matrix.** If ad − bc ≠ 0, the map T(z) = (az + b)/(cz + d) is
undone, on both sides, by T⁻¹(w) = (dw − b)/(−cw + a): swap a and d, negate b and c. So T is a
bijection (a perfect pairing) of the plane plus ∞. -/
theorem mobius_undone_by_swapped_matrix (a b c d : ℂ) (h : a * d - b * c ≠ 0) :
    Function.LeftInverse (mobius d (-b) (-c) a) (mobius a b c d) ∧
    Function.RightInverse (mobius d (-b) (-c) a) (mobius a b c d) ∧
    Function.Bijective (mobius a b c d) := by
  have hl : Function.LeftInverse (mobius d (-b) (-c) a) (mobius a b c d) := by
    intro x
    rw [mobius_comp_aux _ _ _ _ _ _ _ _ h x,
      mobius_congr_aux (a₂ := a * d - b * c) (b₂ := 0) (c₂ := 0) (d₂ := a * d - b * c)
        (by ring) (by ring) (by ring) (by ring), mobius_scalar_aux _ h]
  have hr : Function.RightInverse (mobius d (-b) (-c) a) (mobius a b c d) := by
    intro x
    have h2 : d * a - -b * -c ≠ 0 := by rw [show d * a - -b * -c = a * d - b * c by ring]; exact h
    rw [mobius_comp_aux _ _ _ _ _ _ _ _ h2 x,
      mobius_congr_aux (a₂ := a * d - b * c) (b₂ := 0) (c₂ := 0) (d₂ := a * d - b * c)
        (by ring) (by ring) (by ring) (by ring), mobius_scalar_aux _ h]
  exact ⟨hl, hr, hl.injective, hr.surjective⟩

/-- **Composing is multiplying.** If ad − bc ≠ 0 and a'd' − b'c' ≠ 0, then doing
T' = (a'z + b')/(c'z + d') first and T = (az + b)/(cz + d) second is the Mobius map of the matrix
product (a b; c d)(a' b'; c' d'), at every point of the plane plus ∞. -/
theorem mobius_comp_eq_mobius_of_matrix_product (a b c d a' b' c' d' : ℂ)
    (h : a * d - b * c ≠ 0) (h' : a' * d' - b' * c' ≠ 0) :
    mobius a b c d ∘ mobius a' b' c' d' =
      mobius (a * a' + b * c') (a * b' + b * d') (c * a' + d * c') (c * b' + d * d') := by
  funext x
  exact mobius_comp_aux a b c d a' b' c' d' h' x

-- The Cayley map C(z) = (z − i)/(z + i): a = 1, b = −i, c = 1, d = i, and ad − bc = 2i.
example : (1 : ℂ) * I - (-I) * 1 = 2 * I := by ring
-- C sends i to 0, 0 to −1, ∞ to 1, and the pole −i to ∞.
example : mobius 1 (-I) 1 I (I : ℂ) = ((0 : ℂ) : OnePoint ℂ) := by
  simp [mobius, Complex.ext_iff]
example : mobius 1 (-I) 1 I ((0 : ℂ) : OnePoint ℂ) = ((-1 : ℂ) : OnePoint ℂ) := by
  simp [mobius, Complex.ext_iff]
example : mobius 1 (-I) 1 I ∞ = ((1 : ℂ) : OnePoint ℂ) := by simp [mobius]
example : mobius 1 (-I) 1 I (-I : ℂ) = ∞ := by simp [mobius]
-- C(1) = −i, C(−1) = i, C(2i) = 1/3, and C(1 + i) = (1 − 2i)/5, that is 0.2 − 0.4i.
example : mobius 1 (-I) 1 I ((1 : ℂ) : OnePoint ℂ) = ((-I : ℂ) : OnePoint ℂ) := by
  simp only [mobius]
  rw [if_neg (by simp [Complex.ext_iff] <;> norm_num)]
  congr 1
  rw [div_eq_iff (by simp [Complex.ext_iff] <;> norm_num)]
  simp [Complex.ext_iff] <;> norm_num
example : mobius 1 (-I) 1 I ((-1 : ℂ) : OnePoint ℂ) = ((I : ℂ) : OnePoint ℂ) := by
  simp only [mobius]
  rw [if_neg (by simp [Complex.ext_iff] <;> norm_num)]
  congr 1
  rw [div_eq_iff (by simp [Complex.ext_iff] <;> norm_num)]
  simp [Complex.ext_iff] <;> norm_num
example : mobius 1 (-I) 1 I ((2 * I : ℂ) : OnePoint ℂ) = ((1 / 3 : ℂ) : OnePoint ℂ) := by
  simp only [mobius]
  rw [if_neg (by simp [Complex.ext_iff] <;> norm_num)]
  congr 1
  rw [div_eq_iff (by simp [Complex.ext_iff] <;> norm_num)]
  simp [Complex.ext_iff] <;> norm_num
example : mobius 1 (-I) 1 I ((1 + I : ℂ) : OnePoint ℂ) = (((1 - 2 * I) / 5 : ℂ) : OnePoint ℂ) := by
  simp only [mobius]
  rw [if_neg (by simp [Complex.ext_iff] <;> norm_num)]
  congr 1
  rw [div_eq_iff (by simp [Complex.ext_iff] <;> norm_num)]
  simp [Complex.ext_iff] <;> norm_num
-- C twice at 2i: C(1/3) = (1 − 3i)/(1 + 3i) = (−4 − 3i)/5, that is −0.8 − 0.6i.
example : mobius 1 (-I) 1 I ((1 / 3 : ℂ) : OnePoint ℂ) = (((-4 - 3 * I) / 5 : ℂ) : OnePoint ℂ) := by
  simp only [mobius]
  rw [if_neg (by simp [Complex.ext_iff] <;> norm_num)]
  congr 1
  rw [div_eq_iff (by simp [Complex.ext_iff] <;> norm_num)]
  simp [Complex.ext_iff] <;> norm_num
-- The matrix cubed is (2 − 2i) times the identity.
example : (!![1, -I; 1, I] : Matrix (Fin 2) (Fin 2) ℂ) ^ 3 = !![2 - 2 * I, 0; 0, 2 - 2 * I] := by
  ext i j; fin_cases i <;> fin_cases j <;> simp [pow_succ, Matrix.mul_apply, Fin.sum_univ_two, Complex.ext_iff] <;> norm_num
-- The undo, adjugate (i, i, −1, 1), takes (1 − 2i)/5 back to 1 + i.
example : mobius I I (-1) 1 (((1 - 2 * I) / 5 : ℂ) : OnePoint ℂ) = ((1 + I : ℂ) : OnePoint ℂ) := by
  simp only [mobius]
  rw [if_neg (by simp [Complex.ext_iff] <;> norm_num)]
  congr 1
  rw [div_eq_iff (by simp [Complex.ext_iff] <;> norm_num)]
  simp [Complex.ext_iff] <;> norm_num
-- 1 + i lands on the dashed circle, centre 1/2 and radius 1/2: |(1 − 2i)/5 − 1/2| = 1/2.
example : ‖(1 - 2 * I) / 5 - 1 / 2‖ = 1 / 2 := by
  rw [Complex.norm_def, Real.sqrt_eq_iff_mul_self_eq_of_pos (by norm_num)]
  simp [Complex.normSq_apply]; norm_num
-- Inside the disc: 1 − |C(1 + i)|² = 4/5, and 4y/|z + i|² at z = 1 + i is 4/5 as well.
example : 1 - ‖(1 - 2 * I) / 5‖ ^ 2 = 4 / 5 ∧ 4 * 1 / ‖(1 + I) + I‖ ^ 2 = 4 / 5 := by
  simp only [Complex.sq_norm]; simp [Complex.normSq_apply]; norm_num
-- Three points: S(z) = 1 + iz sends 2i to −1, and R(w) = 2w/(w − 1) sends C(2i) = 1/3 to −1.
example : (1 : ℂ) + I * (2 * I) = -1 ∧ 2 * (1 / 3 : ℂ) / (1 / 3 - 1) = -1 := by
  constructor
  · ring_nf; simp; norm_num
  · norm_num
-- The mistake ad − bc = 0: (z + 2)/(2z + 4) has determinant 0 and is 1/2 at 0, at 1 and at i.
example : (1 : ℂ) * 4 - 2 * 2 = 0 := by norm_num
example : mobius 1 2 2 4 ((0 : ℂ) : OnePoint ℂ) = ((1 / 2 : ℂ) : OnePoint ℂ) ∧
    mobius 1 2 2 4 ((1 : ℂ) : OnePoint ℂ) = ((1 / 2 : ℂ) : OnePoint ℂ) ∧
    mobius 1 2 2 4 ((I : ℂ) : OnePoint ℂ) = ((1 / 2 : ℂ) : OnePoint ℂ) := by
  refine ⟨?_, ?_, ?_⟩ <;>
  · simp only [mobius]
    rw [if_neg (by simp [Complex.ext_iff] <;> norm_num)]
    congr 1
    rw [div_eq_iff (by simp [Complex.ext_iff] <;> norm_num)]
    simp [Complex.ext_iff] <;> norm_num
-- Insides not promised: C(−2i) = 3, outside the disc.
example : mobius 1 (-I) 1 I ((-2 * I : ℂ) : OnePoint ℂ) = ((3 : ℂ) : OnePoint ℂ) := by
  simp only [mobius]
  rw [if_neg (by simp [Complex.ext_iff] <;> norm_num)]
  congr 1
  rw [div_eq_iff (by simp [Complex.ext_iff] <;> norm_num)]
  simp [Complex.ext_iff] <;> norm_num

end

#print axioms mobius_maps_circles_and_lines_to_circles_and_lines
#print axioms mobius_undone_by_swapped_matrix
#print axioms mobius_comp_eq_mobius_of_matrix_product
#print axioms mobius_comp_aux
#print axioms mobius_congr_aux
#print axioms mobius_scalar_aux
#print axioms mem_genCircle_infty_aux
#print axioms mem_genCircle_coe_aux
#print axioms isCircleOrLine_to_genCircle_aux
#print axioms genCircle_to_isCircleOrLine_aux
#print axioms mobius_inv_involutive_aux
#print axioms mobius_inv_genCircle_aux
#print axioms mobius_affine_aux
