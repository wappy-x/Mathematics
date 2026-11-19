-- First fundamental form: the dot products E, F, G of a patch's tangent arrows give the true length of a path on the surface and the true angle between two directions, and the length does not depend on the chart.
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Calculus.FDeriv.Prod
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Inverse
import Mathlib.Geometry.Euclidean.Angle.Unoriented.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Tactic.NormNum

open Set Real

namespace FirstFundamentalForm

/-- Space, where the surface sits: ℝ³ with its usual dot product. -/
abbrev Space := EuclideanSpace ℝ (Fin 3)

/-- The tangent arrow r_u: how fast the point moves in space as u grows. -/
noncomputable def ru (r : ℝ × ℝ → Space) (x : ℝ × ℝ) : Space := fderiv ℝ r x (1, 0)

/-- The tangent arrow r_v: how fast the point moves in space as v grows. -/
noncomputable def rv (r : ℝ × ℝ → Space) (x : ℝ × ℝ) : Space := fderiv ℝ r x (0, 1)

/-- E = r_u · r_u. -/
noncomputable def E (r : ℝ × ℝ → Space) (x : ℝ × ℝ) : ℝ := inner ℝ (ru r x) (ru r x)

/-- F = r_u · r_v. -/
noncomputable def F (r : ℝ × ℝ → Space) (x : ℝ × ℝ) : ℝ := inner ℝ (ru r x) (rv r x)

/-- G = r_v · r_v. -/
noncomputable def G (r : ℝ × ℝ → Space) (x : ℝ × ℝ) : ℝ := inner ℝ (rv r x) (rv r x)

/-- The card's L: the integral over t from 0 to 1 of √(E u̇² + 2F u̇ v̇ + G v̇²),
computed in the chart r from the coordinate path (u(t), v(t)) alone. -/
noncomputable def formLength (r : ℝ × ℝ → Space) (u v : ℝ → ℝ) : ℝ :=
  ∫ t in (0 : ℝ)..1,
    √(E r (u t, v t) * deriv u t ^ 2 + 2 * F r (u t, v t) * deriv u t * deriv v t
      + G r (u t, v t) * deriv v t ^ 2)

/-- Helper: the dot product of two image arrows, written with E, F, G. -/
lemma inner_fderiv_eq (r : ℝ × ℝ → Space) (x a b : ℝ × ℝ) :
    inner ℝ (fderiv ℝ r x a) (fderiv ℝ r x b)
      = E r x * a.1 * b.1 + F r x * (a.1 * b.2 + a.2 * b.1) + G r x * a.2 * b.2 := by
  obtain ⟨a1, a2⟩ := a
  obtain ⟨b1, b2⟩ := b
  have ha : ((a1, a2) : ℝ × ℝ) = a1 • ((1 : ℝ), (0 : ℝ)) + a2 • ((0 : ℝ), (1 : ℝ)) := by
    ext <;> simp
  have hb : ((b1, b2) : ℝ × ℝ) = b1 • ((1 : ℝ), (0 : ℝ)) + b2 • ((0 : ℝ), (1 : ℝ)) := by
    ext <;> simp
  rw [ha, hb]
  simp only [map_add, map_smul, inner_add_left, inner_add_right, real_inner_smul_left,
    real_inner_smul_right, E, F, G, ru, rv]
  rw [real_inner_comm (fderiv ℝ r x (0, 1)) (fderiv ℝ r x (1, 0))]
  simp
  ring

/-- Helper: the squared length of an image arrow, written with E, F, G. -/
lemma norm_fderiv_sq (r : ℝ × ℝ → Space) (x a : ℝ × ℝ) :
    ‖fderiv ℝ r x a‖ ^ 2 = E r x * a.1 ^ 2 + 2 * F r x * a.1 * a.2 + G r x * a.2 ^ 2 := by
  rw [← real_inner_self_eq_norm_sq, inner_fderiv_eq]
  ring

/-- Helper: the length of an image arrow, written with E, F, G. -/
lemma norm_fderiv_eq (r : ℝ × ℝ → Space) (x a : ℝ × ℝ) :
    ‖fderiv ℝ r x a‖ = √(E r x * a.1 ^ 2 + 2 * F r x * a.1 * a.2 + G r x * a.2 ^ 2) := by
  rw [← norm_fderiv_sq, Real.sqrt_sq (norm_nonneg _)]

/-- Helper: chain rule for a path through a patch. -/
lemma deriv_comp_path (r : ℝ × ℝ → Space) (u v : ℝ → ℝ) (t : ℝ)
    (hr : DifferentiableAt ℝ r (u t, v t)) (hu : DifferentiableAt ℝ u t)
    (hv : DifferentiableAt ℝ v t) :
    deriv (fun s => r (u s, v s)) t = fderiv ℝ r (u t, v t) (deriv u t, deriv v t) := by
  have hγ : HasDerivAt (fun s => (u s, v s)) (deriv u t, deriv v t) t :=
    hu.hasDerivAt.prodMk hv.hasDerivAt
  exact (hr.hasFDerivAt.comp_hasDerivAt t hγ).deriv

/-- Length formula. On a patch r(u, v) that is regular (EG − F² > 0) and smooth along the path
(u(t), v(t)), t from 0 to 1, the length of the path in space, the integral of its speed, equals
the integral of √(E u̇² + 2F u̇ v̇ + G v̇²): lengths come from E, F, G and the coordinates alone. -/
theorem length_eq_integral_first_fundamental_form (r : ℝ × ℝ → Space) (u v : ℝ → ℝ)
    (hreg : ∀ t ∈ Icc (0 : ℝ) 1, 0 < E r (u t, v t) * G r (u t, v t) - F r (u t, v t) ^ 2)
    (hr : ∀ t ∈ Icc (0 : ℝ) 1, DifferentiableAt ℝ r (u t, v t))
    (hu : ∀ t ∈ Icc (0 : ℝ) 1, DifferentiableAt ℝ u t)
    (hv : ∀ t ∈ Icc (0 : ℝ) 1, DifferentiableAt ℝ v t) :
    ∫ t in (0 : ℝ)..1, ‖deriv (fun s => r (u s, v s)) t‖ = formLength r u v := by
  unfold formLength
  apply intervalIntegral.integral_congr
  intro t ht
  rw [uIcc_of_le zero_le_one] at ht
  simp only
  rw [deriv_comp_path r u v t (hr t ht) (hu t ht) (hv t ht), norm_fderiv_eq]

/-- Chart change. A second chart r ∘ φ of the same surface, with (u, v) = φ(p, q), has its own
E, F, G, different from the first chart's. If both charts are regular and everything is smooth
along the path, a path (p(t), q(t)) in the new chart and its image (u(t), v(t)) = φ(p(t), q(t))
in the old chart get the same length from their own chart's E, F, G. -/
theorem formLength_independent_of_chart (r : ℝ × ℝ → Space) (φ : ℝ × ℝ → ℝ × ℝ) (p q : ℝ → ℝ)
    (hreg : ∀ t ∈ Icc (0 : ℝ) 1,
      0 < E r (φ (p t, q t)) * G r (φ (p t, q t)) - F r (φ (p t, q t)) ^ 2)
    (hreg' : ∀ t ∈ Icc (0 : ℝ) 1,
      0 < E (r ∘ φ) (p t, q t) * G (r ∘ φ) (p t, q t) - F (r ∘ φ) (p t, q t) ^ 2)
    (hr : ∀ t ∈ Icc (0 : ℝ) 1, DifferentiableAt ℝ r (φ (p t, q t)))
    (hφ : ∀ t ∈ Icc (0 : ℝ) 1, DifferentiableAt ℝ φ (p t, q t))
    (hp : ∀ t ∈ Icc (0 : ℝ) 1, DifferentiableAt ℝ p t)
    (hq : ∀ t ∈ Icc (0 : ℝ) 1, DifferentiableAt ℝ q t) :
    formLength (r ∘ φ) p q
      = formLength r (fun t => (φ (p t, q t)).1) (fun t => (φ (p t, q t)).2) := by
  unfold formLength
  apply intervalIntegral.integral_congr
  intro t ht
  rw [uIcc_of_le zero_le_one] at ht
  simp only
  have h1 := norm_fderiv_eq (r ∘ φ) (p t, q t) (deriv p t, deriv q t)
  have h2 := norm_fderiv_eq r (φ (p t, q t))
    (deriv (fun t => (φ (p t, q t)).1) t, deriv (fun t => (φ (p t, q t)).2) t)
  simp only at h1 h2
  rw [← h1, ← h2]
  congr 1
  have hφγ : HasDerivAt (fun s => φ (p s, q s)) (fderiv ℝ φ (p t, q t) (deriv p t, deriv q t)) t :=
    (hφ t ht).hasFDerivAt.comp_hasDerivAt t ((hp t ht).hasDerivAt.prodMk (hq t ht).hasDerivAt)
  have h1' : deriv (fun s => (φ (p s, q s)).1) t
      = (fderiv ℝ φ (p t, q t) (deriv p t, deriv q t)).1 := by
    have h := (hasFDerivAt_fst (𝕜 := ℝ) (E := ℝ) (F := ℝ) (p := φ (p t, q t))).comp_hasDerivAt t hφγ
    exact h.deriv
  have h2' : deriv (fun s => (φ (p s, q s)).2) t
      = (fderiv ℝ φ (p t, q t) (deriv p t, deriv q t)).2 := by
    have h := (hasFDerivAt_snd (𝕜 := ℝ) (E := ℝ) (F := ℝ) (p := φ (p t, q t))).comp_hasDerivAt t hφγ
    exact h.deriv
  rw [h1', h2', fderiv_comp _ (hr t ht) (hφ t ht)]
  rfl

/-- Angle formula. At a point x where the patch is regular and smooth, two coordinate directions
a = (a₁, a₂) and b = (b₁, b₂) give arrows in space whose angle θ has
cos θ = (E a₁ b₁ + F (a₁ b₂ + a₂ b₁) + G a₂ b₂) / (|a| |b|), with |a| = √(E a₁² + 2F a₁ a₂ + G a₂²). -/
theorem angle_eq_arccos_first_fundamental_form (r : ℝ × ℝ → Space) (x a b : ℝ × ℝ)
    (hreg : 0 < E r x * G r x - F r x ^ 2) (hr : DifferentiableAt ℝ r x) :
    InnerProductGeometry.angle (fderiv ℝ r x a) (fderiv ℝ r x b)
      = arccos ((E r x * a.1 * b.1 + F r x * (a.1 * b.2 + a.2 * b.1) + G r x * a.2 * b.2)
          / (√(E r x * a.1 ^ 2 + 2 * F r x * a.1 * a.2 + G r x * a.2 ^ 2)
            * √(E r x * b.1 ^ 2 + 2 * F r x * b.1 * b.2 + G r x * b.2 ^ 2))) := by
  rw [InnerProductGeometry.angle, inner_fderiv_eq, norm_fderiv_eq, norm_fderiv_eq]

end FirstFundamentalForm

-- The card's roof, plan chart: E = 1 + u²/3600, F = −uv/3600, G = 1 + v²/3600. At P = (30, 20):
example : (1 + 30 ^ 2 / 3600 : ℚ) = 5 / 4 := by norm_num
example : (-(30 * 20) / 3600 : ℚ) = -1 / 6 := by norm_num
example : (1 + 20 ^ 2 / 3600 : ℚ) = 10 / 9 := by norm_num
-- Regular at P: EG − F² = 49/36 (the card's 1.361111).
example : (5 / 4 : ℚ) * (10 / 9) - (-1 / 6) ^ 2 = 49 / 36 := by norm_num
-- Roof height at P: 30 + (30² − 20²)/120 = 205/6 m (the card's 34.17 m).
example : (30 + (30 ^ 2 - 20 ^ 2) / 120 : ℚ) = 205 / 6 := by norm_num
-- Seam chart at P by Jᵀ I J: E + 2F + G, E − G, E − 2F + G (the card's 2.0278, 0.1389, 2.6944).
example : (5 / 4 : ℚ) + 2 * (-1 / 6) + 10 / 9 = 73 / 36 := by norm_num
example : (5 / 4 : ℚ) - 10 / 9 = 5 / 36 := by norm_num
example : (5 / 4 : ℚ) - 2 * (-1 / 6) + 10 / 9 = 97 / 36 := by norm_num
-- The walk u = 30t, v = 20t: E, F, G along it are 1 + t²/4, −t²/6, 1 + t²/9, and the squared
-- speed is 1300 + (625/9) t², which is 12325/9 at t = 1 (the card's 1369.444).
example (t : ℚ) : (1 + (30 * t) ^ 2 / 3600) * 30 ^ 2 + 2 * (-(30 * t) * (20 * t) / 3600) * 30 * 20
    + (1 + (20 * t) ^ 2 / 3600) * 20 ^ 2 = 1300 + 625 / 9 * t ^ 2 := by ring
example : (1300 : ℚ) + 625 / 9 = 12325 / 9 := by norm_num
-- The t² part by hand: 900/4 − 1200/6 + 400/9 = 625/9 (the card's 69.444).
example : (900 / 4 : ℚ) - 1200 / 6 + 400 / 9 = 625 / 9 := by norm_num
-- East and north at P: cos² θ = F²/(EG) = 1/50, so cos θ = −1/√50 (the card's −0.141421).
example : (-1 / 6 : ℚ) ^ 2 / ((5 / 4) * (10 / 9)) = 1 / 50 := by norm_num
-- Polar chart at the centre: E = 1, F = 0, G = 0, so EG − F² = 0 and the chart is not regular.
example : (1 : ℚ) * 0 - 0 ^ 2 = 0 := by norm_num

open FirstFundamentalForm

#print axioms inner_fderiv_eq
#print axioms norm_fderiv_sq
#print axioms norm_fderiv_eq
#print axioms deriv_comp_path
#print axioms length_eq_integral_first_fundamental_form
#print axioms formLength_independent_of_chart
#print axioms angle_eq_arccos_first_fundamental_form
