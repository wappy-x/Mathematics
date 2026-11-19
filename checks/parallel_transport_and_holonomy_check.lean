-- Parallel transport: carrying a level arrow round a great-circle triangle on a sphere turns it by the triangle's angle excess, anticlockwise or clockwise as the loop runs, and round a circle of latitude it turns it by the polar cap's area over the radius squared.
import Mathlib.Geometry.Euclidean.Angle.Unoriented.CrossProduct
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.InnerProductSpace.Calculus
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Tactic.Module

open InnerProductGeometry Set
open scoped RealInnerProductSpace Real Matrix

/-- Space: arrows from the globe's centre, the origin, in three dimensions. -/
local notation "E3" => EuclideanSpace ℝ (Fin 3)

/-- The cross product of two arrows in three-dimensional Euclidean space, Mathlib's `⨯₃`. -/
noncomputable def cross (u v : E3) : E3 :=
  WithLp.toLp 2 (WithLp.ofLp u ⨯₃ WithLp.ofLp v)

/-- The direction in which the great-circle arc from `P` to `Q` leaves `P`: the part of `Q` at
right angles to `P`. -/
noncomputable def arcDir (P Q : E3) : E3 := Q - (⟪P, Q⟫ / ⟪P, P⟫) • P

/-- The great-circle leg from `P` towards `Q` on the sphere of radius `‖P‖`, with `t` the angle
travelled in radians. It starts at `P` and reaches `Q` at `t = angle P Q`. -/
noncomputable def greatArc (P Q : E3) (t : ℝ) : E3 :=
  Real.cos t • P + Real.sin t • ((‖P‖ / ‖arcDir P Q‖) • arcDir P Q)

/-- The corner angle at `P` of the spherical triangle `P Q S`: the angle between the directions in
which the great-circle arcs to `Q` and to `S` leave `P`. -/
noncomputable def cornerAngle (P Q S : E3) : ℝ := angle (arcDir P Q) (arcDir P S)

/-- The angle excess of the spherical triangle `A B C`: how far its corner angles overshoot `π`. -/
noncomputable def angleExcess (A B C : E3) : ℝ :=
  cornerAngle A B C + cornerAngle B C A + cornerAngle C A B - π

/-- Parallel transport on a sphere centred at the origin. The arrow `V t` lies in the tangent
plane at the route's point `γ t` (at right angles to `γ t`), and its rate of change has no tangent
part: the derivative `V'` is a multiple of `γ t`, the vertical, so it equals its own projection
onto `γ t`. This is the Levi-Civita transport of the sphere's metric, written from outside. -/
def IsParallelAlong (γ V : ℝ → E3) (a b : ℝ) : Prop :=
  ∀ t ∈ Icc a b, ⟪V t, γ t⟫ = 0 ∧
    ∃ V' : E3, HasDerivWithinAt V V' (Icc a b) t ∧ V' = (⟪V', γ t⟫ / ⟪γ t, γ t⟫) • γ t

/-- The arrow `v`, tangent at the point `p` of the sphere, turned by the angle `ψ` within the
tangent plane, anticlockwise seen from outside the sphere (about the outward axis `p / ‖p‖`). -/
noncomputable def turnTangent (p v : E3) (ψ : ℝ) : E3 :=
  Real.cos ψ • v + Real.sin ψ • (‖p‖⁻¹ • cross p v)

/-- Rodrigues' formula: the arrow `v` turned by the angle `t` about the unit axis `n`,
anticlockwise seen from the tip of `n`. -/
noncomputable def rotateAbout (n v : E3) (t : ℝ) : E3 :=
  Real.cos t • v + Real.sin t • cross n v + (⟪n, v⟫ * (1 - Real.cos t)) • n

/-! ## Helper lemmas -/

lemma inner_e3 (x y : E3) : ⟪x, y⟫ = x 0 * y 0 + x 1 * y 1 + x 2 * y 2 := by
  simp [EuclideanSpace.inner_eq_star_dotProduct, dotProduct, Fin.sum_univ_three]
  ring

lemma cross_coord0 (u v : E3) : cross u v 0 = u 1 * v 2 - u 2 * v 1 := by simp [cross, cross_apply]
lemma cross_coord1 (u v : E3) : cross u v 1 = u 2 * v 0 - u 0 * v 2 := by simp [cross, cross_apply]
lemma cross_coord2 (u v : E3) : cross u v 2 = u 0 * v 1 - u 1 * v 0 := by simp [cross, cross_apply]

lemma decomp3 (a b c w : E3) :
    ⟪a, cross b c⟫ • w = ⟪w, cross b c⟫ • a + ⟪w, cross c a⟫ • b + ⟪w, cross a b⟫ • c := by
  ext i; fin_cases i <;> simp [inner_e3, cross_coord0, cross_coord1, cross_coord2] <;> ring

lemma inner_cross_left_self (a b : E3) : ⟪a, cross a b⟫ = 0 := by
  simp only [inner_e3, cross_coord0, cross_coord1, cross_coord2]; ring

lemma inner_cross_right_self (a b : E3) : ⟪b, cross a b⟫ = 0 := by
  simp only [inner_e3, cross_coord0, cross_coord1, cross_coord2]; ring

lemma triple_cyclic (a b c : E3) : ⟪a, cross b c⟫ = ⟪b, cross c a⟫ := by
  simp only [inner_e3, cross_coord0, cross_coord1, cross_coord2]; ring

lemma cross_swap (a b : E3) : cross a b = -cross b a := by
  ext i; fin_cases i <;> simp [cross_coord0, cross_coord1, cross_coord2] <;> ring

lemma cross_smul_right' (k : ℝ) (a b : E3) : cross a (k • b) = k • cross a b := by
  ext i; fin_cases i <;> simp [cross_coord0, cross_coord1, cross_coord2] <;> ring

lemma cross_neg_right' (a b : E3) : cross a (-b) = -cross a b := by
  ext i; fin_cases i <;> simp [cross_coord0, cross_coord1, cross_coord2] <;> ring

lemma lagrange (a b c d : E3) : ⟪cross a b, cross c d⟫ = ⟪a, c⟫ * ⟪b, d⟫ - ⟪a, d⟫ * ⟪b, c⟫ := by
  simp only [inner_e3, cross_coord0, cross_coord1, cross_coord2]; ring

lemma bac_cab (a b c : E3) : cross a (cross b c) = ⟪a, c⟫ • b - ⟪a, b⟫ • c := by
  ext i; fin_cases i <;> simp [inner_e3, cross_coord0, cross_coord1, cross_coord2] <;> ring

lemma triple_sq (a b c : E3) : ⟪a, cross b c⟫ ^ 2 =
    ⟪a, a⟫ * ⟪b, b⟫ * ⟪c, c⟫ + 2 * ⟪a, b⟫ * ⟪b, c⟫ * ⟪c, a⟫
      - ⟪a, a⟫ * ⟪b, c⟫ ^ 2 - ⟪b, b⟫ * ⟪c, a⟫ ^ 2 - ⟪c, c⟫ * ⟪a, b⟫ ^ 2 := by
  simp only [inner_e3, cross_coord0, cross_coord1, cross_coord2]; ring

/-- The quarter turn in the tangent plane at `X`. -/
noncomputable def qturn (X w : E3) : E3 := ‖X‖⁻¹ • cross X w

lemma inner_self_e3 (X : E3) : ⟪X, X⟫ = ‖X‖ ^ 2 := real_inner_self_eq_norm_sq X

lemma tangent_decomp (X h w : E3) (hX : X ≠ 0) (hh : ⟪h, h⟫ = 1) (hXh : ⟪X, h⟫ = 0)
    (hw : ⟪w, X⟫ = 0) : w = ⟪w, h⟫ • h + ⟪w, qturn X h⟫ • qturn X h := by
  have e1 : cross h (cross X h) = X := by
    rw [bac_cab, hh, real_inner_comm, hXh]; simp
  have e2 : cross (cross X h) X = ‖X‖ ^ 2 • h := by
    rw [cross_swap, bac_cab, hXh, inner_self_e3]; simp
  have key := decomp3 X h (cross X h) w
  rw [e1, e2, inner_self_e3, hw, inner_smul_right] at key
  have hn : ‖X‖ ≠ 0 := norm_ne_zero_iff.mpr hX
  have hn2 : ‖X‖ ^ 2 ≠ 0 := pow_ne_zero 2 hn
  apply smul_right_injective E3 hn2
  simp only [qturn, inner_smul_right, smul_add, smul_smul]
  rw [key]
  simp only [zero_smul, zero_add]
  have h1 : ‖X‖ ^ 2 * (‖X‖⁻¹ * ⟪w, cross X h⟫ * ‖X‖⁻¹) = ⟪w, cross X h⟫ := by field_simp
  rw [h1]

lemma qturn_inner_base (X a : E3) : ⟪qturn X a, X⟫ = 0 := by
  rw [qturn, real_inner_smul_left, real_inner_comm, inner_cross_left_self, mul_zero]

lemma qturn_inner_self (X a : E3) : ⟪qturn X a, a⟫ = 0 := by
  rw [qturn, real_inner_smul_left, real_inner_comm, inner_cross_right_self, mul_zero]

lemma qturn_inner_eq (X a b : E3) : ⟪qturn X a, b⟫ = ⟪X, cross a b⟫ / ‖X‖ := by
  rw [qturn, real_inner_smul_left, real_inner_comm, triple_cyclic b X a]
  field_simp

lemma qturn_inner_anti (X a b : E3) : ⟪qturn X a, b⟫ = -⟪a, qturn X b⟫ := by
  rw [real_inner_comm (qturn X b) a, qturn_inner_eq, qturn_inner_eq, cross_swap b a, inner_neg_right, neg_div,
    neg_neg]

lemma qturn_neg (X a : E3) : qturn X (-a) = -qturn X a := by
  rw [qturn, qturn, cross_neg_right', smul_neg]

lemma qturn_qturn_inner (X a b : E3) (hX : X ≠ 0) (ha : ⟪X, a⟫ = 0) :
    ⟪qturn X a, qturn X b⟫ = ⟪a, b⟫ := by
  rw [qturn, qturn, real_inner_smul_left, real_inner_smul_right, lagrange, real_inner_comm X a, ha,
    inner_self_e3]
  have hn : ‖X‖ ≠ 0 := norm_ne_zero_iff.mpr hX
  field_simp
  ring

lemma tangent_ext (X h w₁ w₂ : E3) (hX : X ≠ 0) (hh : ⟪h, h⟫ = 1) (hXh : ⟪X, h⟫ = 0)
    (hw₁ : ⟪w₁, X⟫ = 0) (hw₂ : ⟪w₂, X⟫ = 0) (e₁ : ⟪w₁, h⟫ = ⟪w₂, h⟫)
    (e₂ : ⟪w₁, qturn X h⟫ = ⟪w₂, qturn X h⟫) : w₁ = w₂ := by
  rw [tangent_decomp X h w₁ hX hh hXh hw₁, tangent_decomp X h w₂ hX hh hXh hw₂, e₁, e₂]

lemma parallel_unique (γ V W : ℝ → E3) (T : ℝ) (hV : IsParallelAlong γ V 0 T)
    (hW : ∀ t ∈ Icc 0 T, ⟪W t, γ t⟫ = 0 ∧ ∃ k : ℝ, HasDerivWithinAt W (k • γ t) (Icc 0 T) t)
    (h0 : V 0 = W 0) : ∀ t ∈ Icc 0 T, V t = W t := by
  have hd : ∀ t ∈ Icc 0 T,
      HasDerivWithinAt (fun s => ⟪V s - W s, V s - W s⟫) ((fun _ => (0 : ℝ)) t) (Icc 0 T) t := by
    intro t ht
    obtain ⟨hVt, V', hV', hV'eq⟩ := hV t ht
    obtain ⟨hWt, k, hW'⟩ := hW t ht
    have hD := hV'.sub hW'
    have := hD.inner ℝ hD
    convert this using 1
    rw [hV'eq]
    have hVt' : ⟪γ t, V t⟫ = 0 := by rw [real_inner_comm]; exact hVt
    have hWt' : ⟪γ t, W t⟫ = 0 := by rw [real_inner_comm]; exact hWt
    simp only [Pi.sub_apply, inner_sub_left, inner_sub_right, real_inner_smul_left,
      real_inner_smul_right, real_inner_comm (γ t), hVt', hWt']
    ring
  intro t ht
  have := norm_image_sub_le_of_norm_deriv_le_segment' (C := 0) hd (fun _ _ => by simp) t ht
  simp only [h0, sub_self, inner_zero_left, zero_mul, norm_le_zero_iff, sub_zero] at this
  rw [inner_self_eq_zero, sub_eq_zero] at this
  exact this

/-- The unit arrow along `u`. -/
noncomputable def unitv (u : E3) : E3 := ‖u‖⁻¹ • u

lemma arcDir_base_ne (P Q : E3) (hQ : ‖Q‖ = ‖P‖) (hu : arcDir P Q ≠ 0) : P ≠ 0 := by
  rintro rfl
  apply hu
  have : Q = 0 := by simpa using hQ
  simp [arcDir, this]

lemma inner_arcDir (P Q : E3) (hP : P ≠ 0) : ⟪P, arcDir P Q⟫ = 0 := by
  have : ⟪P, P⟫ ≠ 0 := by rw [inner_self_e3]; exact pow_ne_zero 2 (norm_ne_zero_iff.mpr hP)
  rw [arcDir, inner_sub_right, real_inner_smul_right]
  field_simp
  ring

lemma unitv_inner_self (u : E3) (hu : u ≠ 0) : ⟪unitv u, unitv u⟫ = 1 := by
  rw [unitv, real_inner_smul_left, real_inner_smul_right, inner_self_e3]
  have : ‖u‖ ≠ 0 := norm_ne_zero_iff.mpr hu
  field_simp

lemma leg_formula (P Q : E3) (hQ : ‖Q‖ = ‖P‖) (hu : arcDir P Q ≠ 0) (V : ℝ → E3)
    (hV : IsParallelAlong (greatArc P Q) V 0 (angle P Q)) :
    ∀ t ∈ Icc 0 (angle P Q),
      V t = ⟪V 0, qturn P (unitv (arcDir P Q))⟫ • qturn P (unitv (arcDir P Q)) +
        ⟪V 0, unitv (arcDir P Q)⟫ •
          (Real.cos t • unitv (arcDir P Q) - Real.sin t • (‖P‖⁻¹ • P)) := by
  have hP := arcDir_base_ne P Q hQ hu
  have hR : ‖P‖ ≠ 0 := norm_ne_zero_iff.mpr hP
  set u := arcDir P Q with hu_def
  set f := unitv u with hf_def
  set n := qturn P f with hn_def
  have hPu : ⟪P, u⟫ = 0 := inner_arcDir P Q hP
  have hff : ⟪f, f⟫ = 1 := unitv_inner_self u hu
  have hPf : ⟪P, f⟫ = 0 := by rw [hf_def, unitv, inner_smul_right, hPu, mul_zero]
  have hfP : ⟪f, P⟫ = 0 := by rw [real_inner_comm]; exact hPf
  have hnP : ⟪n, P⟫ = 0 := qturn_inner_base P f
  have hnf : ⟪n, f⟫ = 0 := qturn_inner_self P f
  have hPP : ⟪P, P⟫ = ‖P‖ ^ 2 := inner_self_e3 P
  have hγ : ∀ t, greatArc P Q t = Real.cos t • P + Real.sin t • (‖P‖ • f) := by
    intro t
    simp only [greatArc, hf_def, unitv, smul_smul, div_eq_mul_inv]
    rfl
  have hv0 : ⟪V 0, P⟫ = 0 := by
    have := (hV 0 ⟨le_refl _, angle_nonneg _ _⟩).1
    simpa [hγ] using this
  apply parallel_unique _ V _ _ hV
  · intro t _
    constructor
    · rw [hγ]
      simp only [inner_add_left, inner_add_right, inner_sub_left, real_inner_smul_left,
        real_inner_smul_right, hnP, hnf, hfP, hPf, hff, hPP]
      field_simp
      ring
    · refine ⟨-(⟪V 0, f⟫ / ‖P‖), ?_⟩
      have hd : HasDerivAt (fun t => ⟪V 0, n⟫ • n +
          ⟪V 0, f⟫ • (Real.cos t • f - Real.sin t • (‖P‖⁻¹ • P)))
          (⟪V 0, f⟫ • (-Real.sin t • f - Real.cos t • (‖P‖⁻¹ • P))) t := by
        have h1 := ((Real.hasDerivAt_cos t).smul_const f).sub
          ((Real.hasDerivAt_sin t).smul_const (‖P‖⁻¹ • P))
        have h2 := (hasDerivAt_const t (⟪V 0, n⟫ • n)).add (h1.const_smul (⟪V 0, f⟫))
        rw [zero_add] at h2
        exact h2
      convert hd.hasDerivWithinAt using 1
      rw [hγ]
      ext i
      simp only [PiLp.smul_apply, PiLp.add_apply, PiLp.sub_apply, smul_eq_mul]
      field_simp
      ring
  · simp only [Real.cos_zero, Real.sin_zero, one_smul, zero_smul, sub_zero]
    rw [add_comm]
    exact tangent_decomp P f (V 0) hP hff hPf hv0

lemma cross_smul_left' (k : ℝ) (a b : E3) : cross (k • a) b = k • cross a b := by
  ext i; fin_cases i <;> simp [cross_coord0, cross_coord1, cross_coord2] <;> ring

lemma cross_add_right' (a b c : E3) : cross a (b + c) = cross a b + cross a c := by
  ext i; fin_cases i <;> simp [cross_coord0, cross_coord1, cross_coord2] <;> ring

lemma cross_self' (a : E3) : cross a a = 0 := by
  ext i; fin_cases i <;> simp [cross_coord0, cross_coord1, cross_coord2] <;> ring

lemma rotateAbout_eq (P f : E3) (hP : P ≠ 0) (hff : ⟪f, f⟫ = 1) (hPf : ⟪P, f⟫ = 0) (v : E3)
    (hv : ⟪v, P⟫ = 0) (t : ℝ) :
    rotateAbout (qturn P f) v t = ⟪v, qturn P f⟫ • qturn P f +
        ⟪v, f⟫ • (Real.cos t • f - Real.sin t • (‖P‖⁻¹ • P)) := by
  set n := qturn P f with hn_def
  have hnf : ⟪n, f⟫ = 0 := qturn_inner_self P f
  have hnn : ⟪n, n⟫ = 1 := by rw [hn_def, qturn_qturn_inner P f f hP hPf, hff]
  have hcross : cross n f = -(‖P‖⁻¹ • P) := by
    rw [hn_def, qturn, cross_smul_left', cross_swap, bac_cab, hff, real_inner_comm, hPf]
    simp
  have key : ∀ a b : ℝ, rotateAbout n (a • f + b • n) t =
      b • n + a • (Real.cos t • f - Real.sin t • (‖P‖⁻¹ • P)) := by
    intro a b
    rw [rotateAbout, cross_add_right', cross_smul_right', cross_smul_right', cross_self', hcross,
      inner_add_right, real_inner_smul_right, real_inner_smul_right, hnf, hnn]
    module
  conv_lhs => rw [tangent_decomp P f v hP hff hPf hv]
  exact key _ _

lemma pair_arcDir_ne (P Q : E3) (hPQ : LinearIndependent ℝ ![P, Q]) : arcDir P Q ≠ 0 := by
  intro h
  rw [LinearIndependent.pair_iff] at hPQ
  have := hPQ (-(⟪P, Q⟫ / ⟪P, P⟫)) 1 (by rw [arcDir] at h; rw [← h]; module)
  exact one_ne_zero this.2


lemma arcDir_norm_sq (P Q : E3) (hQ : ‖Q‖ = ‖P‖) (hP : P ≠ 0) :
    ‖arcDir P Q‖ ^ 2 = ‖P‖ ^ 2 - ⟪P, Q⟫ ^ 2 / ‖P‖ ^ 2 := by
  have hR : ‖P‖ ≠ 0 := norm_ne_zero_iff.mpr hP
  rw [← inner_self_e3, arcDir, inner_sub_left, inner_sub_right, inner_sub_right,
    real_inner_smul_left, real_inner_smul_right, real_inner_smul_left, real_inner_smul_right,
    inner_self_e3, inner_self_e3, hQ, real_inner_comm P Q]
  field_simp
  ring

lemma leg_end (P Q : E3) (hQ : ‖Q‖ = ‖P‖) (hu : arcDir P Q ≠ 0) (V : ℝ → E3)
    (hV : IsParallelAlong (greatArc P Q) V 0 (angle P Q)) :
    V (angle P Q) = ⟪V 0, unitv (arcDir P Q)⟫ • (-unitv (arcDir Q P)) +
      ⟪V 0, qturn P (unitv (arcDir P Q))⟫ • qturn Q (-unitv (arcDir Q P)) := by
  have hP := arcDir_base_ne P Q hQ hu
  have hR : ‖P‖ ≠ 0 := norm_ne_zero_iff.mpr hP
  have hRpos : 0 < ‖P‖ := norm_pos_iff.mpr hP
  have hx : ‖arcDir P Q‖ ≠ 0 := norm_ne_zero_iff.mpr hu
  have hxpos : 0 < ‖arcDir P Q‖ := norm_pos_iff.mpr hu
  have hx2 := arcDir_norm_sq P Q hQ hP
  have hQ0 : Q ≠ 0 := by rw [← norm_ne_zero_iff, hQ]; exact hR
  have hx'2 := arcDir_norm_sq Q P (hQ.symm) hQ0
  rw [hQ, real_inner_comm] at hx'2
  have hx' : ‖arcDir Q P‖ = ‖arcDir P Q‖ := by
    have := hx'2.trans hx2.symm
    exact (pow_left_inj₀ (norm_nonneg _) (norm_nonneg _) two_ne_zero).mp this
  have hcos : Real.cos (angle P Q) = ⟪P, Q⟫ / (‖P‖ * ‖P‖) := by rw [cos_angle, hQ]
  have hsin : Real.sin (angle P Q) = ‖arcDir P Q‖ / ‖P‖ := by
    have h1 := sin_angle_nonneg P Q
    have h2 : Real.sin (angle P Q) ^ 2 = (‖arcDir P Q‖ / ‖P‖) ^ 2 := by
      rw [Real.sin_sq, hcos, div_pow (‖arcDir P Q‖), hx2]
      field_simp
    exact (pow_left_inj₀ h1 (by positivity) two_ne_zero).mp h2
  have hθ : angle P Q ∈ Icc 0 (angle P Q) := ⟨angle_nonneg _ _, le_refl _⟩
  rw [leg_formula P Q hQ hu V hV _ hθ, add_comm]
  have hue : arcDir P Q = Q - (⟪P, Q⟫ / ‖P‖ ^ 2) • P := by rw [arcDir, inner_self_e3]
  have hu'e : arcDir Q P = P - (⟪P, Q⟫ / ‖P‖ ^ 2) • Q := by
    rw [arcDir, inner_self_e3, hQ, real_inner_comm]
  set x := ‖arcDir P Q‖ with hx_def
  have h1 : Real.cos (angle P Q) • unitv (arcDir P Q) - Real.sin (angle P Q) • (‖P‖⁻¹ • P) =
      -unitv (arcDir Q P) := by
    rw [hcos, hsin, unitv, unitv, hx', ← hx_def, hue, hu'e]
    ext i
    simp only [PiLp.smul_apply, PiLp.sub_apply, PiLp.neg_apply, smul_eq_mul]
    field_simp
    have hx2' : ‖P‖ ^ 2 * x ^ 2 = ‖P‖ ^ 4 - ⟪P, Q⟫ ^ 2 := by rw [hx2]; field_simp
    linear_combination (-P i) * hx2'
  have h2 : qturn Q (-unitv (arcDir Q P)) = qturn P (unitv (arcDir P Q)) := by
    rw [qturn, qturn, unitv, unitv, hx', ← hx_def, hQ, hue, hu'e]
    ext i; fin_cases i <;>
      simp only [PiLp.smul_apply, PiLp.neg_apply, smul_eq_mul, cross_coord0, cross_coord1,
        cross_coord2, PiLp.sub_apply, Fin.zero_eta, Fin.mk_one, Fin.reduceFinMk] <;> ring
  rw [h1, h2]

lemma vertex_change (X f g : E3) (hX : X ≠ 0) (hXg : ⟪X, g⟫ = 0) (a b : ℝ) :
    ⟪a • (-g) + b • qturn X (-g), f⟫ = -⟪f, g⟫ * a + ⟪X, cross f g⟫ / ‖X‖ * b ∧
    ⟪a • (-g) + b • qturn X (-g), qturn X f⟫ = -(⟪X, cross f g⟫ / ‖X‖) * a - ⟪f, g⟫ * b := by
  have e1 : ⟪qturn X (-g), f⟫ = ⟪X, cross f g⟫ / ‖X‖ := by
    rw [qturn_neg, inner_neg_left, qturn_inner_eq, cross_swap g f, inner_neg_right, neg_div,
      neg_neg]
  have e2 : ⟪-g, qturn X f⟫ = -(⟪X, cross f g⟫ / ‖X‖) := by
    rw [inner_neg_left, real_inner_comm, qturn_inner_eq]
  have e3 : ⟪qturn X (-g), qturn X f⟫ = -⟪f, g⟫ := by
    rw [qturn_neg, inner_neg_left, qturn_qturn_inner X g f hX hXg, real_inner_comm]
  constructor
  · rw [inner_add_left, real_inner_smul_left, real_inner_smul_left, e1, inner_neg_left,
      real_inner_comm]
    ring
  · rw [inner_add_left, real_inner_smul_left, real_inner_smul_left, e2, e3]
    ring

lemma triple_arcDir (X Y Z : E3) : ⟪X, cross (arcDir X Y) (arcDir X Z)⟫ = ⟪X, cross Y Z⟫ := by
  simp only [arcDir, inner_e3, cross_coord0, cross_coord1, cross_coord2, PiLp.sub_apply,
    PiLp.smul_apply, smul_eq_mul]
  ring

lemma arcDir_zero_triple (X Y Z : E3) (h : arcDir X Y = 0) :
    ⟪X, cross Y Z⟫ = 0 ∧ ⟪X, cross Z Y⟫ = 0 := by
  rw [arcDir, sub_eq_zero] at h
  constructor
  · rw [h, cross_smul_left', real_inner_smul_right, inner_cross_left_self, mul_zero]
  · rw [h, cross_smul_right', real_inner_smul_right, cross_swap, inner_neg_right,
      inner_cross_left_self, neg_zero, mul_zero]

lemma sign_sin (S D k θ : ℝ) (hk : 0 < k) (hD : D ≠ 0) (hS : S = D / k)
    (hsq : S ^ 2 = Real.sin θ ^ 2) (hθ : 0 ≤ Real.sin θ) :
    S = (if 0 < D then 1 else -1) * Real.sin θ := by
  split_ifs with h
  · have : 0 ≤ S := by rw [hS]; positivity
    rw [one_mul]; exact (pow_left_inj₀ this hθ two_ne_zero).mp hsq
  · have hD' : D < 0 := lt_of_le_of_ne (not_lt.mp h) hD
    have : 0 ≤ -S := by rw [hS, ← neg_div]; exact div_nonneg (by linarith) hk.le
    have := (pow_left_inj₀ this hθ two_ne_zero).mp (by rw [neg_sq]; exact hsq)
    linarith

lemma corner_facts (X Y Z : E3) (hu : arcDir X Y ≠ 0) (hw : arcDir X Z ≠ 0)
    (hD : ⟪X, cross Y Z⟫ ≠ 0) (hX : X ≠ 0) :
    ⟪unitv (arcDir X Y), unitv (arcDir X Z)⟫ = Real.cos (cornerAngle X Y Z) ∧
    ⟪X, cross (unitv (arcDir X Y)) (unitv (arcDir X Z))⟫ / ‖X‖ =
      (if 0 < ⟪X, cross Y Z⟫ then 1 else -1) * Real.sin (cornerAngle X Y Z) := by
  have hR : 0 < ‖X‖ := norm_pos_iff.mpr hX
  have hx : 0 < ‖arcDir X Y‖ := norm_pos_iff.mpr hu
  have hz : 0 < ‖arcDir X Z‖ := norm_pos_iff.mpr hw
  have hC : ⟪unitv (arcDir X Y), unitv (arcDir X Z)⟫ = Real.cos (cornerAngle X Y Z) := by
    rw [cornerAngle, cos_angle, unitv, unitv, real_inner_smul_left, real_inner_smul_right]
    field_simp
  refine ⟨hC, ?_⟩
  have hXf : ⟪X, unitv (arcDir X Y)⟫ = 0 := by
    rw [unitv, inner_smul_right, inner_arcDir X Y hX, mul_zero]
  have hXg : ⟪X, unitv (arcDir X Z)⟫ = 0 := by
    rw [unitv, inner_smul_right, inner_arcDir X Z hX, mul_zero]
  apply sign_sin _ _ (‖X‖ * ‖arcDir X Y‖ * ‖arcDir X Z‖) _ (by positivity) hD
  · rw [unitv, unitv, cross_smul_left', cross_smul_right', real_inner_smul_right,
      real_inner_smul_right, triple_arcDir]
    field_simp
  · rw [div_pow, triple_sq, hXf, real_inner_comm X (unitv (arcDir X Z)), hXg, unitv_inner_self _ hu, unitv_inner_self _ hw, hC,
      Real.sin_sq, inner_self_e3]
    field_simp
    ring
  · exact sin_angle_nonneg _ _

lemma holonomy_scalar (s α β γ a0 b0 a1 b1 a2 b2 : ℝ) (hs : s = 1 ∨ s = -1)
    (h1 : a1 = -Real.cos β * a0 + s * Real.sin β * b0)
    (h1' : b1 = -(s * Real.sin β) * a0 - Real.cos β * b0)
    (h2 : a2 = -Real.cos γ * a1 + s * Real.sin γ * b1)
    (h2' : b2 = -(s * Real.sin γ) * a1 - Real.cos γ * b1) :
    -Real.cos α * a2 + s * Real.sin α * b2 =
        Real.cos (s * (α + β + γ - π)) * a0 - Real.sin (s * (α + β + γ - π)) * b0 ∧
    -(s * Real.sin α) * a2 - Real.cos α * b2 =
        Real.sin (s * (α + β + γ - π)) * a0 + Real.cos (s * (α + β + γ - π)) * b0 := by
  subst h1 h1' h2 h2'
  rcases hs with rfl | rfl
  · simp only [one_mul, Real.cos_sub_pi, Real.sin_sub_pi, Real.cos_add, Real.sin_add]
    constructor <;> ring
  · simp only [neg_one_mul, Real.cos_neg, Real.sin_neg, Real.cos_sub_pi, Real.sin_sub_pi,
      Real.cos_add, Real.sin_add]
    constructor <;> ring


lemma hasDerivAt_vec3 {f₀ f₁ f₂ : ℝ → ℝ} {d₀ d₁ d₂ t : ℝ} (h₀ : HasDerivAt f₀ d₀ t)
    (h₁ : HasDerivAt f₁ d₁ t) (h₂ : HasDerivAt f₂ d₂ t) :
    HasDerivAt (fun t => !₂[f₀ t, f₁ t, f₂ t]) !₂[d₀, d₁, d₂] t := by
  have hf : (fun t => !₂[f₀ t, f₁ t, f₂ t]) = fun t =>
      f₀ t • !₂[(1 : ℝ), 0, 0] + f₁ t • !₂[(0 : ℝ), 1, 0] + f₂ t • !₂[(0 : ℝ), 0, 1] := by
    funext s; ext i; fin_cases i <;> simp
  rw [hf]
  have := ((h₀.smul_const !₂[(1 : ℝ), 0, 0]).add (h₁.smul_const !₂[(0 : ℝ), 1, 0])).add
    (h₂.smul_const !₂[(0 : ℝ), 0, 1])
  convert this using 1
  ext i; fin_cases i <;> simp

lemma hasDerivAt_cos_mul (c t : ℝ) :
    HasDerivAt (fun t => Real.cos (c * t)) (-Real.sin (c * t) * c) t := by
  have := ((hasDerivAt_id t).const_mul c).cos
  simpa using this

lemma hasDerivAt_sin_mul (c t : ℝ) :
    HasDerivAt (fun t => Real.sin (c * t)) (Real.cos (c * t) * c) t := by
  have := ((hasDerivAt_id t).const_mul c).sin
  simpa using this

#print axioms inner_e3
#print axioms cross_coord0
#print axioms cross_coord1
#print axioms cross_coord2
#print axioms decomp3
#print axioms inner_cross_left_self
#print axioms inner_cross_right_self
#print axioms triple_cyclic
#print axioms cross_swap
#print axioms cross_smul_right'
#print axioms cross_neg_right'
#print axioms lagrange
#print axioms bac_cab
#print axioms triple_sq
#print axioms inner_self_e3
#print axioms tangent_decomp
#print axioms qturn_inner_base
#print axioms qturn_inner_self
#print axioms qturn_inner_eq
#print axioms qturn_inner_anti
#print axioms qturn_neg
#print axioms qturn_qturn_inner
#print axioms tangent_ext
#print axioms parallel_unique
#print axioms arcDir_base_ne
#print axioms inner_arcDir
#print axioms unitv_inner_self
#print axioms leg_formula
#print axioms cross_smul_left'
#print axioms cross_add_right'
#print axioms cross_self'
#print axioms rotateAbout_eq
#print axioms pair_arcDir_ne
#print axioms arcDir_norm_sq
#print axioms leg_end
#print axioms vertex_change
#print axioms triple_arcDir
#print axioms arcDir_zero_triple
#print axioms sign_sin
#print axioms corner_facts
#print axioms holonomy_scalar
#print axioms hasDerivAt_vec3
#print axioms hasDerivAt_cos_mul
#print axioms hasDerivAt_sin_mul

/-- **Holonomy of a great-circle triangle is its angle excess.** Carry an arrow level and
untwisted (parallel transport) from `A` to `B` to `C` and back to `A` along the three short
great-circle legs of a triangle on a sphere centred at the origin. If the three corners do not lie
on one great circle, so the loop bounds a region, the arrow comes back turned by the triangle's
angle excess: anticlockwise seen from outside when the loop runs anticlockwise (the triple product
`⟪A, B × C⟫` is positive), clockwise when it runs clockwise. -/
theorem holonomy_of_great_circle_triangle_eq_angle_excess (A B C : E3)
    (hB : ‖B‖ = ‖A‖) (hC : ‖C‖ = ‖A‖) (hABC : ⟪A, cross B C⟫ ≠ 0)
    (V₁ V₂ V₃ : ℝ → E3)
    (h₁ : IsParallelAlong (greatArc A B) V₁ 0 (angle A B))
    (h₂ : IsParallelAlong (greatArc B C) V₂ 0 (angle B C))
    (h₃ : IsParallelAlong (greatArc C A) V₃ 0 (angle C A))
    (h₁₂ : V₂ 0 = V₁ (angle A B)) (h₂₃ : V₃ 0 = V₂ (angle B C)) :
    V₃ (angle C A) =
      turnTangent A (V₁ 0)
        ((if 0 < ⟪A, cross B C⟫ then 1 else -1) * angleExcess A B C) := by
  set D := ⟪A, cross B C⟫ with hD_def
  have hDB : ⟪B, cross C A⟫ = D := (triple_cyclic A B C).symm
  have hDC : ⟪C, cross A B⟫ = D := by rw [← triple_cyclic B C A]; exact hDB
  -- the arcs are proper
  have hAB : arcDir A B ≠ 0 := fun h => hABC (arcDir_zero_triple A B C h).1
  have hAC : arcDir A C ≠ 0 := fun h => by
    have := (arcDir_zero_triple A C B h).2; exact hABC this
  have hBC : arcDir B C ≠ 0 := fun h => by
    have := (arcDir_zero_triple B C A h).1; rw [hDB] at this; exact hABC this
  have hBA : arcDir B A ≠ 0 := fun h => by
    have := (arcDir_zero_triple B A C h).2; rw [hDB] at this; exact hABC this
  have hCA : arcDir C A ≠ 0 := fun h => by
    have := (arcDir_zero_triple C A B h).1; rw [hDC] at this; exact hABC this
  have hCB : arcDir C B ≠ 0 := fun h => by
    have := (arcDir_zero_triple C B A h).2; rw [hDC] at this; exact hABC this
  have hA0 := arcDir_base_ne A B hB hAB
  have hB0 := arcDir_base_ne B C (hC.trans hB.symm) hBC
  have hC0 := arcDir_base_ne C A hC.symm hCA
  -- the three legs
  have e₁ := leg_end A B hB hAB V₁ h₁
  have e₂ := leg_end B C (hC.trans hB.symm) hBC V₂ h₂
  have e₃ := leg_end C A hC.symm hCA V₃ h₃
  -- the three corners
  obtain ⟨cA, sA⟩ := corner_facts A B C hAB hAC hABC hA0
  obtain ⟨cB, sB⟩ := corner_facts B C A hBC hBA (by rw [hDB]; exact hABC) hB0
  obtain ⟨cC, sC⟩ := corner_facts C A B hCA hCB (by rw [hDC]; exact hABC) hC0
  rw [hDB] at sB
  rw [hDC] at sC
  set s : ℝ := if 0 < D then 1 else -1 with hs_def
  have hs : s = 1 ∨ s = -1 := by rw [hs_def]; split_ifs <;> simp
  have hXg : ∀ X Y : E3, X ≠ 0 → ⟪X, unitv (arcDir X Y)⟫ = 0 := fun X Y hX => by
    rw [unitv, inner_smul_right, inner_arcDir X Y hX, mul_zero]
  have hv0 : ⟪V₁ 0, A⟫ = 0 := by
    have := (h₁ 0 ⟨le_refl _, angle_nonneg _ _⟩).1
    simpa [greatArc] using this
  -- coordinates after each corner
  obtain ⟨vB1, vB2⟩ := vertex_change B (unitv (arcDir B C)) (unitv (arcDir B A)) hB0
    (hXg B A hB0) (⟪V₁ 0, unitv (arcDir A B)⟫) (⟪V₁ 0, qturn A (unitv (arcDir A B))⟫)
  obtain ⟨vC1, vC2⟩ := vertex_change C (unitv (arcDir C A)) (unitv (arcDir C B)) hC0
    (hXg C B hC0) (⟪V₂ 0, unitv (arcDir B C)⟫) (⟪V₂ 0, qturn B (unitv (arcDir B C))⟫)
  obtain ⟨vA1, vA2⟩ := vertex_change A (unitv (arcDir A B)) (unitv (arcDir A C)) hA0
    (hXg A C hA0) (⟪V₃ 0, unitv (arcDir C A)⟫) (⟪V₃ 0, qturn C (unitv (arcDir C A))⟫)
  rw [cB, sB, ← e₁, ← h₁₂] at vB1 vB2
  rw [cC, sC, ← e₂, ← h₂₃] at vC1 vC2
  rw [cA, sA, ← e₃] at vA1 vA2
  obtain ⟨k1, k2⟩ := holonomy_scalar s (cornerAngle A B C) (cornerAngle B C A)
    (cornerAngle C A B) _ _ _ _ _ _ hs vB1 vB2 vC1 vC2
  rw [← vA1] at k1
  rw [← vA2] at k2
  have hT : ∀ v ψ, turnTangent A v ψ = Real.cos ψ • v + Real.sin ψ • qturn A v :=
    fun _ _ => rfl
  have hfA : ⟪unitv (arcDir A B), unitv (arcDir A B)⟫ = 1 := unitv_inner_self _ hAB
  rw [hT, angleExcess]
  apply tangent_ext A (unitv (arcDir A B)) _ _ hA0 hfA (hXg A B hA0)
  · rw [e₃, inner_add_left, real_inner_smul_left, real_inner_smul_left, inner_neg_left,
      real_inner_comm A, hXg A C hA0, qturn_inner_base]
    ring
  · rw [inner_add_left, real_inner_smul_left, real_inner_smul_left, hv0, qturn_inner_base]
    ring
  · rw [k1, inner_add_left, real_inner_smul_left, real_inner_smul_left, qturn_inner_anti]
    ring
  · rw [k2, inner_add_left, real_inner_smul_left, real_inner_smul_left,
      qturn_qturn_inner A _ _ hA0 (by rw [real_inner_comm]; exact hv0)]
    ring

/-- **On a great circle, parallel transport is a rotation of the globe.** Along the great-circle
leg from `P` to `Q` (two points of a sphere centred at the origin, neither a multiple of the
other), the transported arrow at angle `t` along the leg is the starting arrow turned by `t`
about the leg's unit axis, the one at right angles to the circle's plane. So the arrow keeps a
fixed angle with the route. -/
theorem parallel_transport_on_great_circle_is_rotation (P Q : E3)
    (hQ : ‖Q‖ = ‖P‖) (hPQ : LinearIndependent ℝ ![P, Q])
    (V : ℝ → E3) (hV : IsParallelAlong (greatArc P Q) V 0 (angle P Q)) :
    ∀ t ∈ Icc 0 (angle P Q),
      V t = rotateAbout ((‖P‖ * ‖arcDir P Q‖)⁻¹ • cross P (arcDir P Q)) (V 0) t := by
  have hu := pair_arcDir_ne P Q hPQ
  have hP := arcDir_base_ne P Q hQ hu
  intro t ht
  have hN : (‖P‖ * ‖arcDir P Q‖)⁻¹ • cross P (arcDir P Q) = qturn P (unitv (arcDir P Q)) := by
    rw [qturn, unitv, cross_smul_right', smul_smul, mul_inv]
  have hv0 : ⟪V 0, P⟫ = 0 := by
    have := (hV 0 ⟨le_refl _, angle_nonneg _ _⟩).1
    simpa [greatArc] using this
  have hPf : ⟪P, unitv (arcDir P Q)⟫ = 0 := by
    rw [unitv, inner_smul_right, inner_arcDir P Q hP, mul_zero]
  rw [hN, rotateAbout_eq P _ hP (unitv_inner_self _ hu) hPf (V 0) hv0 t]
  exact leg_formula P Q hQ hu V hV t ht

/-- **Round a circle of latitude, the turn is the cap's area over the radius squared.** Fly the
parallel at angle `φ` down from the pole, on the sphere of radius `R`, once eastward. The
transported arrow comes back turned anticlockwise (seen from outside) by `2π (1 - cos φ)`, the
area `2π R² (1 - cos φ)` of the polar cap it encloses divided by `R²`, not the `0` that counting
corner turns would give. -/
theorem holonomy_round_circle_of_latitude (R φ : ℝ) (hR : 0 < R) (hφ₀ : 0 < φ) (hφ₁ : φ < π)
    (V : ℝ → E3)
    (hV : IsParallelAlong
      (fun t => !₂[R * Real.sin φ * Real.cos t, R * Real.sin φ * Real.sin t, R * Real.cos φ])
      V 0 (2 * π)) :
    V (2 * π) =
      turnTangent !₂[R * Real.sin φ, 0, R * Real.cos φ] (V 0) (2 * π * (1 - Real.cos φ)) := by
  have _ := hφ₀; have _ := hφ₁
  set sφ := Real.sin φ with hsφ
  set cφ := Real.cos φ with hcφ
  have hpy : sφ ^ 2 + cφ ^ 2 = 1 := Real.sin_sq_add_cos_sq φ
  have hv : sφ * V 0 0 + cφ * V 0 2 = 0 := by
    have := (hV 0 ⟨le_refl _, by positivity⟩).1
    simp only [inner_e3, Real.cos_zero, Real.sin_zero] at this
    have h' : R * (sφ * V 0 0 + cφ * V 0 2) = 0 := by
      simp at this; linear_combination this
    rcases mul_eq_zero.mp h' with h | h
    · exact absurd h hR.ne'
    · exact h
  set p₀ := cφ * V 0 0 - sφ * V 0 2 with hp₀
  set q₀ := V 0 1 with hq₀
  -- the turning coordinates
  let p : ℝ → ℝ := fun t => p₀ * Real.cos (cφ * t) + q₀ * Real.sin (cφ * t)
  let q : ℝ → ℝ := fun t => -p₀ * Real.sin (cφ * t) + q₀ * Real.cos (cφ * t)
  let W : ℝ → E3 := fun t => !₂[p t * cφ * Real.cos t - q t * Real.sin t,
    p t * cφ * Real.sin t + q t * Real.cos t, -(p t * sφ)]
  have key := parallel_unique _ V W (2 * π) hV ?_ ?_ (2 * π) ⟨by positivity, le_refl _⟩
  · rw [key]
    have hn : ‖!₂[R * sφ, 0, R * cφ]‖ = R := by
      rw [EuclideanSpace.norm_eq, Fin.sum_univ_three]
      simp only [Real.norm_eq_abs, sq_abs]
      simp
      rw [show (R * sφ) ^ 2 + (R * cφ) ^ 2 = R ^ 2 by linear_combination R ^ 2 * hpy]
      exact Real.sqrt_sq hR.le
    have hψ : 2 * π * (1 - cφ) = 2 * π - cφ * (2 * π) := by ring
    rw [turnTangent, hn, hψ, Real.cos_two_pi_sub, Real.sin_two_pi_sub]
    ext i; fin_cases i
    · simp [W, p, q, cross_coord0]
      field_simp
      linear_combination (Real.cos (cφ * 2 * π) * cφ) * hp₀ + (-Real.cos (cφ * 2 * π) * sφ) * hv +
        (Real.cos (cφ * 2 * π) * V 0 0) * hpy + (cφ * Real.sin (cφ * 2 * π)) * hq₀
    · simp [W, p, q, cross_coord1]
      field_simp
      linear_combination (-Real.sin (cφ * 2 * π)) * hp₀ + Real.cos (cφ * 2 * π) * hq₀
    · simp [W, p, q, cross_coord2]
      field_simp
      linear_combination (-Real.cos (cφ * 2 * π) * sφ) * hp₀ + (-Real.cos (cφ * 2 * π) * cφ) * hv +
        (Real.cos (cφ * 2 * π) * V 0 2) * hpy + (-sφ * Real.sin (cφ * 2 * π)) * hq₀
  · intro t _
    constructor
    · simp only [inner_e3, W, p, q]
      simp
      linear_combination (R * sφ * (p₀ * Real.cos (cφ * t) + q₀ * Real.sin (cφ * t)) * cφ) *
        Real.sin_sq_add_cos_sq t
    · refine ⟨-((-p₀ * Real.sin (cφ * t) + q₀ * Real.cos (cφ * t)) * sφ) / R, ?_⟩
      have hp := ((hasDerivAt_cos_mul cφ t).const_mul p₀).add
        ((hasDerivAt_sin_mul cφ t).const_mul q₀)
      have hq := ((hasDerivAt_sin_mul cφ t).const_mul (-p₀)).add
        ((hasDerivAt_cos_mul cφ t).const_mul q₀)
      have F₀ := ((hp.mul_const cφ).mul (Real.hasDerivAt_cos t)).sub (hq.mul (Real.hasDerivAt_sin t))
      have F₁ := ((hp.mul_const cφ).mul (Real.hasDerivAt_sin t)).add (hq.mul (Real.hasDerivAt_cos t))
      have F₂ := (hp.mul_const sφ).neg
      have hd := hasDerivAt_vec3 F₀ F₁ F₂
      convert hd.hasDerivWithinAt using 1
      ext i; fin_cases i
      · simp
        field_simp
        linear_combination (-(-(p₀ * Real.sin (cφ * t)) + q₀ * Real.cos (cφ * t)) * Real.cos t) * hpy
      · simp
        field_simp
        linear_combination (-(-(p₀ * Real.sin (cφ * t)) + q₀ * Real.cos (cφ * t)) * Real.sin t) * hpy
      · simp
        field_simp
  · ext i; fin_cases i
    · simp [W, p, q]
      linear_combination (-cφ) * hp₀ + sφ * hv - V 0 0 * hpy
    · simp [W, p, q]
      linear_combination (-1 : ℝ) * hq₀
    · simp [W, p, q]
      linear_combination sφ * hp₀ + cφ * hv - V 0 2 * hpy

/- The card's worked numbers, in hundredths of a degree. -/
-- corner angles at the pole, London and New York: 73.88 + 71.67 + 51.21 = 196.76 degrees
example : (7388 + 7167 + 5121 : ℤ) = 19676 := by norm_num
-- the excess: 196.76 - 180 = 16.76 degrees
example : (19676 - 18000 : ℤ) = 1676 := by norm_num
-- each right turn of the route is 180 degrees minus a corner angle
example : (18000 - 7167 : ℤ) = 10833 ∧ (18000 - 5121 : ℤ) = 12879 ∧ (18000 - 7388 : ℤ) = 10612 := by
  norm_num
-- the route's right turns: 108.33 + 128.79 + 106.12 = 343.24, short of a full turn by 16.76
example : (10833 + 12879 + 10612 : ℤ) = 34324 ∧ (36000 - 34324 : ℤ) = 1676 := by norm_num
-- the octant: three right angles overshoot 180 degrees by 90
example : (9000 + 9000 + 9000 - 18000 : ℤ) = 9000 := by norm_num

#print axioms holonomy_of_great_circle_triangle_eq_angle_excess
#print axioms parallel_transport_on_great_circle_is_rotation
#print axioms holonomy_round_circle_of_latitude
