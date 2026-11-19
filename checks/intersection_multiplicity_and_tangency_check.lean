-- Intersection multiplicity: for two plane curves over ℂ meeting at P with no shared piece, the dimension of the local ring at P divided by both equations is 1 exactly when the curves cross with different tangent lines and at least 2 when they touch, it equals the root order of the resultant for a curve and a line, and the pipe x² + y² = 25 and the beam 3x + 4y = 25 meet at (3, 4) with multiplicity 2.
import Mathlib
import Mathlib.RingTheory.Localization.AtPrime.Basic
import Mathlib.RingTheory.Ideal.Quotient.Operations
import Mathlib.RingTheory.Polynomial.Resultant.Basic
import Mathlib.Algebra.MvPolynomial.PDeriv
import Mathlib.LinearAlgebra.Dimension.Finrank
import Mathlib.LinearAlgebra.LinearIndependent.Defs
import Mathlib.Basic.Complex.Basic
import Mathlib.Tactic.LinearCombination

open scoped Polynomial

/-- The maximal ideal `𝔪_P` of the point `P = (P 0, P 1)` in the plane ring `ℂ[x, y]`
(`x = X 0`, `y = X 1`): every polynomial that is zero at `P`. -/
noncomputable abbrev pointIdeal (P : Fin 2 → ℂ) : Ideal (MvPolynomial (Fin 2) ℂ) :=
  RingHom.ker (MvPolynomial.eval P)

instance (P : Fin 2 → ℂ) : (pointIdeal P).IsPrime := RingHom.ker_isPrime _

/-- The intersection multiplicity `(F · G)_P = dim_ℂ 𝒪_P / ⟨F, G⟩`: the local ring `𝒪_P`
(fractions whose denominator is not zero at `P`) with `F` and `G` set to zero, measured by
its dimension over `ℂ`. (Mathlib's `finrank` reads 0 when the dimension is infinite, which
happens only when `F` and `G` share a piece through `P`.) -/
noncomputable def intersectionMultiplicity (F G : MvPolynomial (Fin 2) ℂ) (P : Fin 2 → ℂ) : ℕ :=
  Module.finrank ℂ (Localization.AtPrime (pointIdeal P) ⧸
    Ideal.span {algebraMap _ (Localization.AtPrime (pointIdeal P)) F,
      algebraMap _ (Localization.AtPrime (pointIdeal P)) G})

/-- The gradient `∇F(P) = (∂F/∂x (P), ∂F/∂y (P))`. -/
noncomputable def gradientAt (F : MvPolynomial (Fin 2) ℂ) (P : Fin 2 → ℂ) : Fin 2 → ℂ :=
  ![MvPolynomial.eval P (MvPolynomial.pderiv 0 F), MvPolynomial.eval P (MvPolynomial.pderiv 1 F)]

/-- A curve written as a polynomial in `y` whose coefficients are polynomials in `x`
(`ℂ[x][y]`, the form the resultant in `y` needs), read as a plane polynomial in `ℂ[x, y]`. -/
noncomputable def toPlane : ℂ[X][X] →+* MvPolynomial (Fin 2) ℂ :=
  Polynomial.eval₂RingHom (Polynomial.eval₂RingHom MvPolynomial.C (MvPolynomial.X 0))
    (MvPolynomial.X 1)

/-- The line `b y + c x + e = 0`, as a polynomial in `y` with coefficients in `ℂ[x]`. -/
noncomputable def lineY (b c e : ℂ) : ℂ[X][X] :=
  Polynomial.C (Polynomial.C b) * Polynomial.X +
    Polynomial.C (Polynomial.C c * Polynomial.X + Polynomial.C e)

/-- The pipe `x² + y² - 25` in the plane ring. -/
noncomputable def pipe : MvPolynomial (Fin 2) ℂ :=
  MvPolynomial.X 0 ^ 2 + MvPolynomial.X 1 ^ 2 - 25

/-- The beam `3x + 4y - 25` in the plane ring. -/
noncomputable def beam : MvPolynomial (Fin 2) ℂ :=
  3 * MvPolynomial.X 0 + 4 * MvPolynomial.X 1 - 25

/-- The pipe `y² + (x² - 25)` as a polynomial in `y` over `ℂ[x]`. -/
noncomputable def pipeY : ℂ[X][X] :=
  Polynomial.X ^ 2 + Polynomial.C (Polynomial.X ^ 2 - 25)

/-- The `y`-value of the line `b y + c x + e = 0` above `x`, as a polynomial in `x`. -/
noncomputable def lineRoot (b c e : ℂ) : ℂ[X] :=
  Polynomial.C (-(c / b)) * Polynomial.X + Polynomial.C (-(e / b))

theorem C_mul_lineRoot (b c e : ℂ) (hb : b ≠ 0) :
    Polynomial.C b * lineRoot b c e = -(Polynomial.C c * Polynomial.X + Polynomial.C e) := by
  simp only [lineRoot, mul_add, ← mul_assoc, ← Polynomial.C_mul]
  rw [show b * -(c / b) = -c by field_simp, show b * -(e / b) = -e by field_simp]
  simp only [Polynomial.C_neg]; ring

theorem lineY_eq (b c e : ℂ) (hb : b ≠ 0) :
    lineY b c e = Polynomial.C (Polynomial.C b) * (Polynomial.X - Polynomial.C (lineRoot b c e)) := by
  rw [mul_sub, ← Polynomial.C_mul, C_mul_lineRoot b c e hb, lineY, Polynomial.C_neg, sub_neg_eq_add]

theorem natDegree_lineY (b c e : ℂ) (hb : b ≠ 0) : (lineY b c e).natDegree = 1 := by
  rw [lineY_eq b c e hb, Polynomial.natDegree_C_mul (by simpa using hb), Polynomial.natDegree_X_sub_C]

theorem resultant_lineY (F : ℂ[X][X]) (b c e : ℂ) (hb : b ≠ 0) :
    Polynomial.resultant F (lineY b c e) =
      Polynomial.C (b ^ F.natDegree * (-1) ^ F.natDegree) * F.eval (lineRoot b c e) := by
  have h1 := natDegree_lineY b c e hb
  have h2 := Polynomial.resultant_C_mul_right (f := F) (g := Polynomial.X - Polynomial.C (lineRoot b c e))
    (m := F.natDegree) (n := 1) (Polynomial.C b)
  have h3 := Polynomial.resultant_X_sub_C_right (f := F) (m := F.natDegree) (lineRoot b c e) le_rfl
  rw [h3, ← lineY_eq b c e hb] at h2
  rw [← h1] at h2
  rw [h2]
  simp only [Polynomial.C_mul, Polynomial.C_pow, Polynomial.C_neg, Polynomial.C_1]
  ring

theorem eval_lineRoot (b c e a : ℂ) : (lineRoot b c e).eval a = -(c * a + e) / b := by
  simp [lineRoot]; ring

theorem aeval_toPlane (F : ℂ[X][X]) (r : ℂ[X]) :
    MvPolynomial.aeval ![Polynomial.X, r] (toPlane F) = F.eval r := by
  have : ((MvPolynomial.aeval ![Polynomial.X, r] : MvPolynomial (Fin 2) ℂ →ₐ[ℂ] ℂ[X]) :
      MvPolynomial (Fin 2) ℂ →+* ℂ[X]).comp toPlane = Polynomial.evalRingHom r := by
    apply Polynomial.ringHom_ext'
    · apply Polynomial.ringHom_ext'
      · ext x; simp [toPlane]
      · simp [toPlane]
    · simp [toPlane]
  exact congrArg (fun φ => φ F) this

theorem eval_aeval_line (r : ℂ[X]) (a : ℂ) (s : MvPolynomial (Fin 2) ℂ) :
    (MvPolynomial.aeval ![Polynomial.X, r] s).eval a = MvPolynomial.eval ![a, r.eval a] s := by
  induction s using MvPolynomial.induction_on with
  | C x => simp
  | add p q hp hq => simp [hp, hq]
  | mul_X p i hp => fin_cases i <;> simp [hp]

theorem isUnit_mk_of_eval_ne_zero (a : ℂ) (k : ℕ) (p : ℂ[X]) (hp : p.eval a ≠ 0) :
    IsUnit (Ideal.Quotient.mk (Ideal.span {(Polynomial.X - Polynomial.C a) ^ k}) p) := by
  have h1 : IsCoprime (Polynomial.X - Polynomial.C a) p :=
    (Polynomial.irreducible_X_sub_C a).coprime_iff_not_dvd.2
      (by rwa [Polynomial.dvd_iff_isRoot])
  obtain ⟨u, v, huv⟩ := h1.pow_left (m := k)
  refine isUnit_iff_exists_inv.2 ⟨Ideal.Quotient.mk _ v, ?_⟩
  rw [← map_mul, mul_comm, ← sub_eq_zero, ← map_one (Ideal.Quotient.mk _), ← map_sub,
    Ideal.Quotient.eq_zero_iff_mem]
  rw [← huv]
  refine (Ideal.mem_span_singleton).2 ⟨-u, by ring⟩

theorem isUnit_algebraMap_localization (P : Fin 2 → ℂ) (s : MvPolynomial (Fin 2) ℂ)
    (hs : MvPolynomial.eval P s ≠ 0) :
    IsUnit (algebraMap (MvPolynomial (Fin 2) ℂ) (Localization.AtPrime (pointIdeal P)) s) :=
  IsLocalization.map_units (M := (pointIdeal P).primeCompl) _ ⟨s, by simpa [Ideal.primeCompl] using hs⟩

theorem intersectionMultiplicity_line (F : ℂ[X][X]) (b c e a : ℂ) (hb : b ≠ 0)
    (hf : F.eval (lineRoot b c e) ≠ 0) :
    intersectionMultiplicity (toPlane F) (toPlane (lineY b c e)) ![a, -(c * a + e) / b] =
      (F.eval (lineRoot b c e)).rootMultiplicity a := by
  set P : Fin 2 → ℂ := ![a, -(c * a + e) / b] with hP
  set r := lineRoot b c e with hr
  set f := F.eval r with hfdef
  set k := f.rootMultiplicity a with hk
  let R := Localization.AtPrime (pointIdeal P)
  let I : Ideal R := Ideal.span {algebraMap (MvPolynomial (Fin 2) ℂ) R (toPlane F), algebraMap (MvPolynomial (Fin 2) ℂ) R (toPlane (lineY b c e))}
  let J : Ideal ℂ[X] := Ideal.span {(Polynomial.X - Polynomial.C a) ^ k}
  let σ : (MvPolynomial (Fin 2) ℂ) →ₐ[ℂ] ℂ[X] := MvPolynomial.aeval ![Polynomial.X, r]
  have hσF : σ (toPlane F) = f := aeval_toPlane F r
  have hσG : σ (toPlane (lineY b c e)) = 0 := by
    rw [aeval_toPlane, lineY_eq b c e hb]; simp [hr]
  have hevσ : ∀ s, (σ s).eval a = MvPolynomial.eval P s := by
    intro s
    rw [eval_aeval_line, hr, eval_lineRoot]
  have hfJ : Ideal.Quotient.mk J f = 0 :=
    Ideal.Quotient.eq_zero_iff_mem.2 (Ideal.mem_span_singleton.2 (Polynomial.pow_rootMultiplicity_dvd f a))
  let Φ0 : (MvPolynomial (Fin 2) ℂ) →ₐ[ℂ] ℂ[X] ⧸ J := (Ideal.Quotient.mkₐ ℂ J).comp σ
  have hΦ0 : ∀ y : (pointIdeal P).primeCompl, IsUnit (Φ0 y) := by
    rintro ⟨y, hy⟩
    apply isUnit_mk_of_eval_ne_zero
    show (σ y).eval a ≠ 0
    rw [hevσ]
    simpa [Ideal.primeCompl] using hy
  let Φ1 : R →ₐ[ℂ] ℂ[X] ⧸ J := IsLocalization.liftAlgHom (M := (pointIdeal P).primeCompl) hΦ0
  have hΦ1 : ∀ s, Φ1 (algebraMap (MvPolynomial (Fin 2) ℂ) R s) = Ideal.Quotient.mk J (σ s) := by
    intro s
    show IsLocalization.lift _ (algebraMap (MvPolynomial (Fin 2) ℂ) R s) = _
    rw [IsLocalization.lift_eq]; rfl
  have hI : ∀ x ∈ I, Φ1 x = 0 := by
    intro x hx
    have : I ≤ RingHom.ker Φ1 := by
      rw [Ideal.span_le]
      rintro _ (rfl | rfl)
      · simp [hΦ1, hσF, hfJ]
      · simp [hΦ1, hσG]
    exact this hx
  let Φ : R ⧸ I →ₐ[ℂ] ℂ[X] ⧸ J := Ideal.Quotient.liftₐ I Φ1 hI
  let π : (MvPolynomial (Fin 2) ℂ) →ₐ[ℂ] R ⧸ I := (Ideal.Quotient.mkₐ ℂ I).comp (Algebra.algHom ℂ (MvPolynomial (Fin 2) ℂ) R)
  let τ : ℂ[X] →ₐ[ℂ] (MvPolynomial (Fin 2) ℂ) := Polynomial.aeval (MvPolynomial.X 0)
  have hπF : π (toPlane F) = 0 := by
    simp only [π, AlgHom.comp_apply, Ideal.Quotient.mkₐ_eq_mk]
    exact Ideal.Quotient.eq_zero_iff_mem.2 (Ideal.subset_span (Set.mem_insert _ _))
  have hπG : π (toPlane (lineY b c e)) = 0 := by
    simp only [π, AlgHom.comp_apply, Ideal.Quotient.mkₐ_eq_mk]
    exact Ideal.Quotient.eq_zero_iff_mem.2 (Ideal.subset_span (Set.mem_insert_of_mem _ rfl))
  have hπunit : ∀ s, MvPolynomial.eval P s ≠ 0 → IsUnit (π s) := by
    intro s hs
    exact (isUnit_algebraMap_localization P s hs).map (Ideal.Quotient.mk I)
  have hline : toPlane (lineY b c e) = MvPolynomial.C b * (MvPolynomial.X 1 - τ r) := by
    rw [lineY_eq b c e hb]
    simp [toPlane, τ, Polynomial.aeval_def, MvPolynomial.algebraMap_eq, ← hr]
  have hX1 : π (τ r) = π (MvPolynomial.X 1) := by
    have h0 : π (MvPolynomial.C b) * (π (MvPolynomial.X 1) - π (τ r)) = 0 := by
      rw [← map_sub, ← map_mul, ← hline, hπG]
    have hu : IsUnit (π (MvPolynomial.C b)) := hπunit _ (by simpa using hb)
    exact (sub_eq_zero.1 (hu.mul_right_eq_zero.1 h0)).symm
  have hπτσ : ∀ s, π (τ (σ s)) = π s := by
    have : (π.comp τ).comp σ = π := by
      apply MvPolynomial.algHom_ext
      intro i
      fin_cases i
      · simp [σ, τ]
      · simp only [σ, τ, AlgHom.comp_apply, MvPolynomial.aeval_X]
        exact hX1
    intro s
    exact congrArg (fun φ => φ s) this
  have hevτ : ∀ u : ℂ[X], MvPolynomial.eval P (τ u) = u.eval a := by
    intro u
    induction u using Polynomial.induction_on with
    | C x => simp [τ]
    | add p q hp hq => simp [hp, hq]
    | monomial n x _ => simp [τ, hP]
  have hJ : ∀ p ∈ J, (π.comp τ) p = 0 := by
    intro p hp
    obtain ⟨q, rfl⟩ := Ideal.mem_span_singleton.1 hp
    obtain ⟨u, hfu, hu⟩ := Polynomial.exists_eq_pow_rootMultiplicity_mul_and_not_dvd f hf a
    have hua : u.eval a ≠ 0 := by rwa [Polynomial.dvd_iff_isRoot] at hu
    have h0 : π (τ ((Polynomial.X - Polynomial.C a) ^ k)) * π (τ u) = 0 := by
      rw [← map_mul, ← map_mul, hk, ← hfu, ← hσF, hπτσ, hπF]
    have h1 := (hπunit _ (by rwa [hevτ])).mul_left_eq_zero.1 h0
    simp only [AlgHom.comp_apply, map_mul, h1, zero_mul]
  let Ψ : ℂ[X] ⧸ J →ₐ[ℂ] R ⧸ I := Ideal.Quotient.liftₐ J (π.comp τ) hJ
  have hΨ : ∀ p, Ψ (Ideal.Quotient.mk J p) = π (τ p) := fun p => rfl
  have hΦπ : ∀ s, Φ (π s) = Ideal.Quotient.mk J (σ s) := fun s => hΦ1 s
  have h1 : Φ.comp Ψ = AlgHom.id ℂ _ := by
    apply Ideal.Quotient.algHom_ext
    apply Polynomial.algHom_ext
    show Φ (Ψ (Ideal.Quotient.mk J Polynomial.X)) = Ideal.Quotient.mk J Polynomial.X
    rw [hΨ]
    simp only [τ, Polynomial.aeval_X]
    rw [hΦπ]
    simp [σ]
  have h2 : Ψ.comp Φ = AlgHom.id ℂ _ := by
    apply Ideal.Quotient.algHom_ext
    apply IsLocalization.algHom_ext (pointIdeal P).primeCompl
    apply MvPolynomial.algHom_ext
    intro i
    show Ψ (Φ (π (MvPolynomial.X i))) = π (MvPolynomial.X i)
    rw [hΦπ, hΨ, hπτσ]
  let E : (R ⧸ I) ≃ₐ[ℂ] ℂ[X] ⧸ J := AlgEquiv.ofAlgHom Φ Ψ h1 h2
  have := E.toLinearEquiv.finrank_eq
  unfold intersectionMultiplicity
  rw [this, finrank_quotient_span_eq_natDegree, Polynomial.natDegree_pow, Polynomial.natDegree_X_sub_C,
    mul_one]

theorem rootMultiplicity_resultant_lineY (F : ℂ[X][X]) (b c e a : ℂ) (hb : b ≠ 0)
    (hf : F.eval (lineRoot b c e) ≠ 0) :
    (Polynomial.resultant F (lineY b c e)).rootMultiplicity a =
      (F.eval (lineRoot b c e)).rootMultiplicity a := by
  rw [resultant_lineY F b c e hb]
  have hβ : b ^ F.natDegree * (-1) ^ F.natDegree ≠ 0 := by simp [hb]
  rw [Polynomial.rootMultiplicity_mul (mul_ne_zero (by simpa using hβ) hf),
    Polynomial.rootMultiplicity_C, zero_add]

theorem eval_lineRoot_ne_zero (F : ℂ[X][X]) (b c e a : ℂ) (hb : b ≠ 0)
    (hshare : ∀ h, h ∣ toPlane F → h ∣ toPlane (lineY b c e) → IsUnit h) :
    F.eval (lineRoot b c e) ≠ 0 := by
  intro hf
  have hdvd : lineY b c e ∣ F := by
    obtain ⟨q, hq⟩ := Polynomial.dvd_iff_isRoot.2 hf
    refine ⟨Polynomial.C (Polynomial.C b⁻¹) * q, ?_⟩
    rw [lineY_eq b c e hb, hq]
    have : (Polynomial.C (Polynomial.C b) : ℂ[X][X]) * Polynomial.C (Polynomial.C b⁻¹) = 1 := by
      rw [← Polynomial.C_mul, ← Polynomial.C_mul, mul_inv_cancel₀ hb, Polynomial.C_1, Polynomial.C_1]
    linear_combination (-(Polynomial.X - Polynomial.C (lineRoot b c e)) * q) * this
  have hu := hshare _ (map_dvd toPlane hdvd) dvd_rfl
  have h0 : MvPolynomial.eval ![a, -(c * a + e) / b] (toPlane (lineY b c e)) = 0 := by
    simp [toPlane, lineY]
    field_simp
    ring
  have := hu.map (MvPolynomial.eval ![a, -(c * a + e) / b])
  rw [h0] at this
  exact not_isUnit_zero this

theorem exists_decomp (P : Fin 2 → ℂ) (F : MvPolynomial (Fin 2) ℂ) :
    ∃ f₁ f₂ : MvPolynomial (Fin 2) ℂ, F = MvPolynomial.C (MvPolynomial.eval P F) +
      (MvPolynomial.X 0 - MvPolynomial.C (P 0)) * f₁ + (MvPolynomial.X 1 - MvPolynomial.C (P 1)) * f₂ := by
  induction F using MvPolynomial.induction_on with
  | C x => exact ⟨0, 0, by simp⟩
  | add p q hp hq =>
    obtain ⟨p₁, p₂, hp⟩ := hp
    obtain ⟨q₁, q₂, hq⟩ := hq
    refine ⟨p₁ + q₁, p₂ + q₂, ?_⟩
    rw [map_add, map_add]
    linear_combination hp + hq
  | mul_X p i hp =>
    obtain ⟨p₁, p₂, hp⟩ := hp
    fin_cases i
    · refine ⟨p + MvPolynomial.C (P 0) * p₁, MvPolynomial.C (P 0) * p₂, ?_⟩
      simp only [Fin.zero_eta, map_mul, MvPolynomial.eval_X]
      linear_combination (MvPolynomial.C (P 0)) * hp
    · refine ⟨MvPolynomial.C (P 1) * p₁, p + MvPolynomial.C (P 1) * p₂, ?_⟩
      simp only [Fin.mk_one, map_mul, MvPolynomial.eval_X]
      linear_combination (MvPolynomial.C (P 1)) * hp

theorem exists_decomp_grad (P : Fin 2 → ℂ) (F : MvPolynomial (Fin 2) ℂ) (hF : MvPolynomial.eval P F = 0) :
    ∃ f₁ f₂ : MvPolynomial (Fin 2) ℂ, F =
      (MvPolynomial.X 0 - MvPolynomial.C (P 0)) * f₁ + (MvPolynomial.X 1 - MvPolynomial.C (P 1)) * f₂ ∧
      MvPolynomial.eval P f₁ = gradientAt F P 0 ∧ MvPolynomial.eval P f₂ = gradientAt F P 1 := by
  obtain ⟨f₁, f₂, h⟩ := exists_decomp P F
  rw [hF, map_zero, zero_add] at h
  refine ⟨f₁, f₂, h, ?_, ?_⟩
  · simp only [gradientAt, Matrix.cons_val_zero]
    conv_rhs => rw [h]
    simp [Derivation.leibniz, MvPolynomial.pderiv_X]
  · simp only [gradientAt, Matrix.cons_val_one]
    conv_rhs => rw [h]
    simp [Derivation.leibniz, MvPolynomial.pderiv_X]

/-- The ring `𝒪_P / ⟨F, G⟩` whose dimension is the intersection multiplicity. -/
noncomputable abbrev LQ (F G : MvPolynomial (Fin 2) ℂ) (P : Fin 2 → ℂ) :=
  Localization.AtPrime (pointIdeal P) ⧸
    Ideal.span {algebraMap _ (Localization.AtPrime (pointIdeal P)) F,
      algebraMap _ (Localization.AtPrime (pointIdeal P)) G}

/-- A plane polynomial, read in `𝒪_P / ⟨F, G⟩`. -/
noncomputable def toQ (F G : MvPolynomial (Fin 2) ℂ) (P : Fin 2 → ℂ) :
    MvPolynomial (Fin 2) ℂ →ₐ[ℂ] LQ F G P :=
  (Ideal.Quotient.mkₐ ℂ _).comp (Algebra.algHom ℂ _ _)

theorem toQ_left (F G : MvPolynomial (Fin 2) ℂ) (P : Fin 2 → ℂ) : toQ F G P F = 0 :=
  Ideal.Quotient.eq_zero_iff_mem.2 (Ideal.subset_span (Set.mem_insert _ _))

theorem toQ_right (F G : MvPolynomial (Fin 2) ℂ) (P : Fin 2 → ℂ) : toQ F G P G = 0 :=
  Ideal.Quotient.eq_zero_iff_mem.2 (Ideal.subset_span (Set.mem_insert_of_mem _ rfl))

theorem isUnit_toQ (F G : MvPolynomial (Fin 2) ℂ) (P : Fin 2 → ℂ) (s : MvPolynomial (Fin 2) ℂ)
    (hs : MvPolynomial.eval P s ≠ 0) : IsUnit (toQ F G P s) :=
  (isUnit_algebraMap_localization P s hs).map (Ideal.Quotient.mk _)

theorem toQ_frac (F G : MvPolynomial (Fin 2) ℂ) (P : Fin 2 → ℂ) (q : LQ F G P) :
    ∃ r s, MvPolynomial.eval P s ≠ 0 ∧ q * toQ F G P s = toQ F G P r := by
  obtain ⟨x, rfl⟩ := Ideal.Quotient.mk_surjective q
  obtain ⟨⟨r, s⟩, rfl⟩ := IsLocalization.mk'_surjective (pointIdeal P).primeCompl x
  refine ⟨r, s, by simpa [Ideal.primeCompl] using s.2, ?_⟩
  simp only [toQ, AlgHom.comp_apply, Ideal.Quotient.mkₐ_eq_mk]
  rw [← map_mul]
  exact congrArg (Ideal.Quotient.mk _) (IsLocalization.mk'_spec _ r s)

/-- A map out of `𝒪_P / ⟨F, G⟩`, made from a map out of the plane ring that kills `F` and `G` and
sends every polynomial nonzero at `P` to a unit. -/
noncomputable def liftQ {F G : MvPolynomial (Fin 2) ℂ} {P : Fin 2 → ℂ} {B : Type*} [CommRing B]
    [Algebra ℂ B] (φ : MvPolynomial (Fin 2) ℂ →ₐ[ℂ] B)
    (hu : ∀ s, MvPolynomial.eval P s ≠ 0 → IsUnit (φ s)) (hF : φ F = 0) (hG : φ G = 0) :
    LQ F G P →ₐ[ℂ] B :=
  Ideal.Quotient.liftₐ _
    (IsLocalization.liftAlgHom (M := (pointIdeal P).primeCompl) (f := φ)
      (fun y => hu y (by simpa [Ideal.primeCompl] using y.2)))
    (by
      intro x hx
      have : Ideal.span {algebraMap _ (Localization.AtPrime (pointIdeal P)) F,
          algebraMap _ (Localization.AtPrime (pointIdeal P)) G} ≤
          RingHom.ker (IsLocalization.liftAlgHom (M := (pointIdeal P).primeCompl) (f := φ)
            (fun y => hu y (by simpa [Ideal.primeCompl] using y.2))) := by
        rw [Ideal.span_le]
        rintro _ (rfl | rfl)
        · simp [IsLocalization.lift_eq, hF]
        · simp [IsLocalization.lift_eq, hG]
      exact this hx)

theorem liftQ_toQ {F G : MvPolynomial (Fin 2) ℂ} {P : Fin 2 → ℂ} {B : Type*} [CommRing B]
    [Algebra ℂ B] (φ : MvPolynomial (Fin 2) ℂ →ₐ[ℂ] B)
    (hu : ∀ s, MvPolynomial.eval P s ≠ 0 → IsUnit (φ s)) (hF : φ F = 0) (hG : φ G = 0)
    (s : MvPolynomial (Fin 2) ℂ) : liftQ φ hu hF hG (toQ F G P s) = φ s := by
  show IsLocalization.lift (M := (pointIdeal P).primeCompl) _
    (algebraMap (MvPolynomial (Fin 2) ℂ) (Localization.AtPrime (pointIdeal P)) s) = φ s
  rw [IsLocalization.lift_eq]; rfl

theorem toQ_eq_algebraMap_of_det (F G : MvPolynomial (Fin 2) ℂ) (P : Fin 2 → ℂ)
    (hF : MvPolynomial.eval P F = 0) (hG : MvPolynomial.eval P G = 0)
    (hdet : gradientAt F P 0 * gradientAt G P 1 - gradientAt F P 1 * gradientAt G P 0 ≠ 0)
    (s : MvPolynomial (Fin 2) ℂ) :
    toQ F G P s = algebraMap ℂ (LQ F G P) (MvPolynomial.eval P s) := by
  obtain ⟨f₁, f₂, hFe, hf₁, hf₂⟩ := exists_decomp_grad P F hF
  obtain ⟨g₁, g₂, hGe, hg₁, hg₂⟩ := exists_decomp_grad P G hG
  set D := f₁ * g₂ - f₂ * g₁ with hD
  have hDu : IsUnit (toQ F G P D) := by
    apply isUnit_toQ
    simp only [hD, map_sub, map_mul, hf₁, hf₂, hg₁, hg₂]
    exact hdet
  have h0 : toQ F G P (MvPolynomial.X 0 - MvPolynomial.C (P 0)) = 0 := by
    have : toQ F G P D * toQ F G P (MvPolynomial.X 0 - MvPolynomial.C (P 0)) = 0 := by
      rw [← map_mul, show D * (MvPolynomial.X 0 - MvPolynomial.C (P 0)) = g₂ * F - f₂ * G by
        rw [hD]; linear_combination (-g₂) * hFe + f₂ * hGe]
      simp [toQ_left, toQ_right]
    exact hDu.mul_right_eq_zero.1 this
  have h1 : toQ F G P (MvPolynomial.X 1 - MvPolynomial.C (P 1)) = 0 := by
    have : toQ F G P D * toQ F G P (MvPolynomial.X 1 - MvPolynomial.C (P 1)) = 0 := by
      rw [← map_mul, show D * (MvPolynomial.X 1 - MvPolynomial.C (P 1)) = f₁ * G - g₁ * F by
        rw [hD]; linear_combination (-f₁) * hGe + g₁ * hFe]
      simp [toQ_left, toQ_right]
    exact hDu.mul_right_eq_zero.1 this
  obtain ⟨s₁, s₂, hs⟩ := exists_decomp P s
  conv_lhs => rw [hs]
  rw [map_add, map_add, map_mul, map_mul, h0, h1, zero_mul, zero_mul, add_zero, add_zero,
    ← MvPolynomial.algebraMap_eq, AlgHom.commutes]

theorem intersectionMultiplicity_eq_one_of_det (F G : MvPolynomial (Fin 2) ℂ) (P : Fin 2 → ℂ)
    (hF : MvPolynomial.eval P F = 0) (hG : MvPolynomial.eval P G = 0)
    (hdet : gradientAt F P 0 * gradientAt G P 1 - gradientAt F P 1 * gradientAt G P 0 ≠ 0) :
    intersectionMultiplicity F G P = 1 := by
  let ev : LQ F G P →ₐ[ℂ] ℂ := liftQ (MvPolynomial.aeval P) (fun s hs => by simpa using hs)
    (by simpa using hF) (by simpa using hG)
  have hinj : Function.Injective (Algebra.linearMap ℂ (LQ F G P)) := by
    intro x y hxy
    have := congrArg ev hxy
    simpa using this
  have hsurj : Function.Surjective (Algebra.linearMap ℂ (LQ F G P)) := by
    intro q
    obtain ⟨r, s, hs, hq⟩ := toQ_frac F G P q
    refine ⟨MvPolynomial.eval P r / MvPolynomial.eval P s, ?_⟩
    rw [toQ_eq_algebraMap_of_det F G P hF hG hdet, toQ_eq_algebraMap_of_det F G P hF hG hdet] at hq
    simp only [Algebra.linearMap_apply, div_eq_mul_inv, map_mul]
    rw [← hq, mul_assoc, ← map_mul, mul_inv_cancel₀ hs, map_one, mul_one]
  have e := LinearEquiv.ofBijective (Algebra.linearMap ℂ (LQ F G P)) ⟨hinj, hsurj⟩
  unfold intersectionMultiplicity
  rw [← e.finrank_eq, Module.finrank_self]

/-- The point `P + ε w` with `ε² = 0`: a point with a tangent direction `w` attached. -/
noncomputable def dualPoint (P w : Fin 2 → ℂ) : Fin 2 → TrivSqZeroExt ℂ ℂ :=
  fun i => TrivSqZeroExt.inl (P i) + TrivSqZeroExt.inr (w i)

theorem aeval_dualPoint_fst (P w : Fin 2 → ℂ) (F : MvPolynomial (Fin 2) ℂ) :
    (MvPolynomial.aeval (dualPoint P w) F).fst = MvPolynomial.eval P F := by
  induction F using MvPolynomial.induction_on with
  | C x => simp [TrivSqZeroExt.algebraMap_eq_inl]
  | add p q hp hq => simp [hp, hq]
  | mul_X p i hp => simp [hp, dualPoint]

theorem aeval_dualPoint_snd (P w : Fin 2 → ℂ) (F : MvPolynomial (Fin 2) ℂ) :
    (MvPolynomial.aeval (dualPoint P w) F).snd = gradientAt F P 0 * w 0 + gradientAt F P 1 * w 1 := by
  induction F using MvPolynomial.induction_on with
  | C x => simp [gradientAt, TrivSqZeroExt.algebraMap_eq_inl]
  | add p q hp hq =>
    simp only [map_add, TrivSqZeroExt.snd_add, hp, hq, gradientAt, Matrix.cons_val_zero,
      Matrix.cons_val_one]
    ring
  | mul_X p i hp =>
    have h1 := aeval_dualPoint_fst P w p
    simp only [gradientAt, Matrix.cons_val_zero, Matrix.cons_val_one] at hp
    fin_cases i <;>
    · simp [TrivSqZeroExt.snd_mul, h1, hp, dualPoint, gradientAt, Derivation.leibniz,
        MvPolynomial.pderiv_X]
      ring

theorem two_le_of_tangent (F G : MvPolynomial (Fin 2) ℂ) (P w : Fin 2 → ℂ)
    (hF : MvPolynomial.eval P F = 0) (hG : MvPolynomial.eval P G = 0)
    (hwF : gradientAt F P 0 * w 0 + gradientAt F P 1 * w 1 = 0)
    (hwG : gradientAt G P 0 * w 0 + gradientAt G P 1 * w 1 = 0) (hw : w ≠ 0)
    [Module.Finite ℂ (LQ F G P)] : 2 ≤ intersectionMultiplicity F G P := by
  have hzero : ∀ H : MvPolynomial (Fin 2) ℂ, MvPolynomial.eval P H = 0 →
      gradientAt H P 0 * w 0 + gradientAt H P 1 * w 1 = 0 →
      MvPolynomial.aeval (dualPoint P w) H = 0 := by
    intro H h1 h2
    ext
    · rw [aeval_dualPoint_fst, h1]; rfl
    · rw [aeval_dualPoint_snd, h2]; rfl
  let ψ : LQ F G P →ₐ[ℂ] TrivSqZeroExt ℂ ℂ := liftQ (MvPolynomial.aeval (dualPoint P w))
    (fun s hs => by
      rw [TrivSqZeroExt.isUnit_iff_isUnit_fst, aeval_dualPoint_fst]
      exact hs.isUnit)
    (hzero F hF hwF) (hzero G hG hwG)
  obtain ⟨i, hi⟩ : ∃ i, w i ≠ 0 := by
    by_contra h
    push Not at h
    exact hw (funext h)
  let v : Fin 2 → LQ F G P := ![1, toQ F G P (MvPolynomial.X i - MvPolynomial.C (P i))]
  have hψv : ψ.toLinearMap ∘ v = ![1, TrivSqZeroExt.inr (w i)] := by
    funext j
    fin_cases j
    · simp [v]
    · show ψ (toQ F G P (MvPolynomial.X i - MvPolynomial.C (P i))) = TrivSqZeroExt.inr (w i)
      rw [liftQ_toQ]
      ext
      · simp [dualPoint, TrivSqZeroExt.algebraMap_eq_inl]
      · simp [dualPoint, TrivSqZeroExt.algebraMap_eq_inl]
  have hli : LinearIndependent ℂ (ψ.toLinearMap ∘ v) := by
    rw [hψv, LinearIndependent.pair_iff]
    intro s t hst
    have h1 := congrArg TrivSqZeroExt.fst hst
    have h2 := congrArg TrivSqZeroExt.snd hst
    simp at h1 h2
    exact ⟨h1, by simpa [h1, hi] using h2⟩
  have := (LinearIndependent.of_comp _ hli).fintype_card_le_finrank
  simpa [intersectionMultiplicity] using this

theorem finite_quot_of_univariate (I : Ideal (MvPolynomial (Fin 2) ℂ))
    (h : ∀ i : Fin 2, ∃ p : ℂ[X], p ≠ 0 ∧ Polynomial.aeval (MvPolynomial.X i) p ∈ I) :
    Module.Finite ℂ (MvPolynomial (Fin 2) ℂ ⧸ I) := by
  have hX : ∀ i : Fin 2, IsIntegral ℂ (Ideal.Quotient.mk I (MvPolynomial.X i)) := by
    intro i
    obtain ⟨p, hp, hpI⟩ := h i
    apply IsAlgebraic.isIntegral
    refine ⟨p, hp, ?_⟩
    have := Polynomial.aeval_algHom_apply (Ideal.Quotient.mkₐ ℂ I) (MvPolynomial.X i) p
    rw [Ideal.Quotient.mkₐ_eq_mk] at this
    rw [this]
    exact Ideal.Quotient.eq_zero_iff_mem.2 hpI
  have : Algebra.IsIntegral ℂ (MvPolynomial (Fin 2) ℂ ⧸ I) := by
    constructor
    intro x
    obtain ⟨s, rfl⟩ := Ideal.Quotient.mk_surjective x
    induction s using MvPolynomial.induction_on with
    | C a =>
      rw [← MvPolynomial.algebraMap_eq, ← Ideal.Quotient.algebraMap_eq, ← IsScalarTower.algebraMap_apply]
      exact isIntegral_algebraMap
    | add p q hp hq => rw [map_add]; exact hp.add hq
    | mul_X p i hp => rw [map_mul]; exact hp.mul (hX i)
  have : Algebra.FiniteType ℂ (MvPolynomial (Fin 2) ℂ ⧸ I) :=
    Algebra.FiniteType.of_surjective (Ideal.Quotient.mkₐ ℂ I) (Ideal.Quotient.mkₐ_surjective ℂ I)
  exact Algebra.IsIntegral.finite

theorem finite_LQ (F G : MvPolynomial (Fin 2) ℂ) (P : Fin 2 → ℂ)
    (h : Module.Finite ℂ (MvPolynomial (Fin 2) ℂ ⧸ Ideal.span {F, G})) :
    Module.Finite ℂ (LQ F G P) := by
  let B := MvPolynomial (Fin 2) ℂ ⧸ Ideal.span {F, G}
  have hker : ∀ a ∈ Ideal.span {F, G}, toQ F G P a = 0 := by
    intro a ha
    have : Ideal.span {F, G} ≤ RingHom.ker (toQ F G P) := by
      rw [Ideal.span_le, Set.insert_subset_iff, Set.singleton_subset_iff]
      exact ⟨RingHom.mem_ker.2 (toQ_left F G P), RingHom.mem_ker.2 (toQ_right F G P)⟩
    exact this ha
  let θ : B →ₐ[ℂ] LQ F G P := Ideal.Quotient.liftₐ _ (toQ F G P) hker
  have hθ : ∀ s, θ (Ideal.Quotient.mk _ s) = toQ F G P s := fun s => rfl
  have : IsArtinianRing B := IsArtinianRing.of_finite ℂ B
  have hsurj : Function.Surjective θ := by
    intro q
    obtain ⟨r, s, hs, hq⟩ := toQ_frac F G P q
    obtain ⟨n, y, hy⟩ := IsArtinian.exists_pow_succ_smul_dvd (Ideal.Quotient.mk (Ideal.span {F, G}) s) (1 : B)
    have hy' := congrArg θ hy
    simp only [smul_eq_mul, mul_one, map_mul, map_pow, hθ] at hy'
    have hu := isUnit_toQ F G P s hs
    have h1 : toQ F G P s * θ y = 1 := by
      have := (hu.pow n).mul_left_cancel (a := toQ F G P s ^ n) (b := toQ F G P s * θ y) (c := 1)
      apply this
      rw [mul_one, ← mul_assoc, ← pow_succ, hy']
    refine ⟨Ideal.Quotient.mk _ r * y, ?_⟩
    rw [map_mul, hθ, ← hq, mul_assoc, h1, mul_one]
  exact Module.Finite.of_surjective θ.toLinearMap hsurj

theorem smul_eq_C_algebraMap_mul (b : ℂ[X]) (p : (RatFunc ℂ)[X]) :
    b • p = Polynomial.C (algebraMap ℂ[X] (RatFunc ℂ) b) * p := by
  rw [Algebra.smul_def, Polynomial.algebraMap_apply]

theorem exists_C_mem_span (F G : ℂ[X][X]) (hne : F ≠ 0) (h : ∀ d, d ∣ F → d ∣ G → IsUnit d) :
    ∃ a : ℂ[X], a ≠ 0 ∧ Polynomial.C a ∈ Ideal.span {F, G} := by
  have hφ : Function.Injective (algebraMap ℂ[X] (RatFunc ℂ)) := IsFractionRing.injective ℂ[X] (RatFunc ℂ)
  have hmapinj : Function.Injective (Polynomial.map (algebraMap ℂ[X] (RatFunc ℂ))) := Polynomial.map_injective (algebraMap ℂ[X] (RatFunc ℂ)) hφ
  by_cases hc : IsRelPrime (F.map (algebraMap ℂ[X] (RatFunc ℂ))) (G.map (algebraMap ℂ[X] (RatFunc ℂ)))
  · have := IsPrincipalIdealRing.principal (Ideal.span {F.map (algebraMap ℂ[X] (RatFunc ℂ)), G.map (algebraMap ℂ[X] (RatFunc ℂ))})
    obtain ⟨u, v, huv⟩ := hc.isCoprime
    obtain ⟨b₁, hb₁, hU⟩ := IsLocalization.integerNormalization_spec (nonZeroDivisors ℂ[X]) u
    obtain ⟨b₂, hb₂, hV⟩ := IsLocalization.integerNormalization_spec (nonZeroDivisors ℂ[X]) v
    set U := IsLocalization.integerNormalization (nonZeroDivisors ℂ[X]) u
    set V := IsLocalization.integerNormalization (nonZeroDivisors ℂ[X]) v
    refine ⟨b₁ * b₂, mul_ne_zero (nonZeroDivisors.ne_zero hb₁) (nonZeroDivisors.ne_zero hb₂), ?_⟩
    refine Ideal.mem_span_pair.2 ⟨Polynomial.C b₂ * U, Polynomial.C b₁ * V, ?_⟩
    apply hmapinj
    simp only [Polynomial.map_add, Polynomial.map_mul, Polynomial.map_C, hU, hV,
      smul_eq_C_algebraMap_mul, map_mul]
    linear_combination (Polynomial.C ((algebraMap ℂ[X] (RatFunc ℂ)) b₁) * Polynomial.C ((algebraMap ℂ[X] (RatFunc ℂ)) b₂)) * huv
  · exfalso
    unfold IsRelPrime at hc
    push Not at hc
    obtain ⟨d, hdF, hdG, hdu⟩ := hc
    have hd0 : d ≠ 0 := by
      rintro rfl
      apply hne
      apply hmapinj
      simpa using hdF
    obtain ⟨b, hb, hD0⟩ := IsLocalization.integerNormalization_spec (nonZeroDivisors ℂ[X]) d
    set D0 := IsLocalization.integerNormalization (nonZeroDivisors ℂ[X]) d
    have hb0 : (algebraMap ℂ[X] (RatFunc ℂ)) b ≠ 0 := by
      rw [map_ne_zero_iff (algebraMap ℂ[X] (RatFunc ℂ)) hφ]; exact nonZeroDivisors.ne_zero hb
    have hD00 : D0 ≠ 0 := by
      intro h0
      rw [h0, Polynomial.map_zero, smul_eq_C_algebraMap_mul] at hD0
      exact mul_ne_zero (Polynomial.C_ne_zero.2 hb0) hd0 hD0.symm
    set D := D0.primPart
    have hc0 : D0.content ≠ 0 := by rwa [Ne, Polynomial.content_eq_zero_iff]
    have hcφ : (algebraMap ℂ[X] (RatFunc ℂ)) D0.content ≠ 0 := by rwa [map_ne_zero_iff (algebraMap ℂ[X] (RatFunc ℂ)) hφ]
    have hsplit : D0.map (algebraMap ℂ[X] (RatFunc ℂ)) = Polynomial.C ((algebraMap ℂ[X] (RatFunc ℂ)) D0.content) * D.map (algebraMap ℂ[X] (RatFunc ℂ)) := by
      conv_lhs => rw [D0.eq_C_content_mul_primPart]
      rw [Polynomial.map_mul, Polynomial.map_C]
    have hDd : d = D.map (algebraMap ℂ[X] (RatFunc ℂ)) * Polynomial.C (((algebraMap ℂ[X] (RatFunc ℂ)) b)⁻¹ * (algebraMap ℂ[X] (RatFunc ℂ)) D0.content) := by
      rw [smul_eq_C_algebraMap_mul] at hD0
      have hinv : Polynomial.C ((algebraMap ℂ[X] (RatFunc ℂ)) b)⁻¹ * Polynomial.C ((algebraMap ℂ[X] (RatFunc ℂ)) b) = (1 : (RatFunc ℂ)[X]) := by
        rw [← Polynomial.C_mul, inv_mul_cancel₀ hb0, Polynomial.C_1]
      rw [Polynomial.C_mul]
      linear_combination (-(Polynomial.C ((algebraMap ℂ[X] (RatFunc ℂ)) b)⁻¹)) * hD0 + Polynomial.C ((algebraMap ℂ[X] (RatFunc ℂ)) b)⁻¹ * hsplit - d * hinv
    have hmapD : D.map (algebraMap ℂ[X] (RatFunc ℂ)) ∣ d := ⟨_, hDd⟩
    have hprim : D.IsPrimitive := Polynomial.isPrimitive_primPart D0
    have hDF : D ∣ F := hprim.dvd_of_fraction_map_dvd_fraction_map (K := RatFunc ℂ) (hmapD.trans hdF)
    have hDG : D ∣ G := hprim.dvd_of_fraction_map_dvd_fraction_map (K := RatFunc ℂ) (hmapD.trans hdG)
    have hDu := (h D hDF hDG).map (Polynomial.mapRingHom (algebraMap ℂ[X] (RatFunc ℂ)))
    apply hdu
    rw [hDd]
    refine hDu.mul ?_
    exact Polynomial.isUnit_C.2 (IsUnit.mk0 _ (mul_ne_zero (inv_ne_zero hb0) hcφ))

/-- The inverse of `toPlane`: a plane polynomial written in `y` with coefficients in `x`. -/
noncomputable def fromPlane : MvPolynomial (Fin 2) ℂ →+* ℂ[X][X] :=
  MvPolynomial.eval₂Hom (Polynomial.C.comp Polynomial.C) ![Polynomial.C Polynomial.X, Polynomial.X]

theorem fromPlane_toPlane (p : ℂ[X][X]) : fromPlane (toPlane p) = p := by
  have : fromPlane.comp toPlane = RingHom.id _ := by
    apply Polynomial.ringHom_ext'
    · apply Polynomial.ringHom_ext'
      · ext x; simp [fromPlane, toPlane]
      · simp [fromPlane, toPlane]
    · simp [fromPlane, toPlane]
  exact congrArg (fun φ => φ p) this

theorem toPlane_fromPlane (s : MvPolynomial (Fin 2) ℂ) : toPlane (fromPlane s) = s := by
  have : toPlane.comp fromPlane = RingHom.id _ := by
    apply MvPolynomial.ringHom_ext
    · intro x; simp [fromPlane, toPlane]
    · intro i; fin_cases i <;> simp [fromPlane, toPlane]
  exact congrArg (fun φ => φ s) this

/-- `toPlane` as a ring isomorphism. -/
noncomputable def planeEquiv : ℂ[X][X] ≃+* MvPolynomial (Fin 2) ℂ :=
  RingEquiv.ofRingHom toPlane fromPlane (RingHom.ext toPlane_fromPlane)
    (RingHom.ext fromPlane_toPlane)

theorem exists_univariate_mem (e : ℂ[X][X] ≃+* MvPolynomial (Fin 2) ℂ) (i : Fin 2)
    (he : ∀ a, e (Polynomial.C a) = Polynomial.aeval (MvPolynomial.X i) a)
    (F G : MvPolynomial (Fin 2) ℂ) (hF0 : F ≠ 0) (hshare : ∀ h, h ∣ F → h ∣ G → IsUnit h) :
    ∃ p : ℂ[X], p ≠ 0 ∧ Polynomial.aeval (MvPolynomial.X i) p ∈ Ideal.span {F, G} := by
  obtain ⟨a, ha, hmem⟩ := exists_C_mem_span (e.symm F) (e.symm G) (by simpa using hF0)
    (fun d h1 h2 => by
      have h1' := map_dvd e h1
      have h2' := map_dvd e h2
      simp only [RingEquiv.apply_symm_apply] at h1' h2'
      simpa using (hshare _ h1' h2').map e.symm)
  refine ⟨a, ha, ?_⟩
  obtain ⟨c, d, hcd⟩ := Ideal.mem_span_pair.1 hmem
  refine Ideal.mem_span_pair.2 ⟨e c, e d, ?_⟩
  rw [← he, ← hcd, map_add, map_mul, map_mul, RingEquiv.apply_symm_apply, RingEquiv.apply_symm_apply]

theorem finite_LQ_of_coprime (F G : MvPolynomial (Fin 2) ℂ) (P : Fin 2 → ℂ) (hF0 : F ≠ 0)
    (hshare : ∀ h, h ∣ F → h ∣ G → IsUnit h) : Module.Finite ℂ (LQ F G P) := by
  apply finite_LQ
  apply finite_quot_of_univariate
  intro i
  fin_cases i
  · exact exists_univariate_mem planeEquiv 0
      (fun a => by simp [planeEquiv, toPlane, Polynomial.aeval_def, MvPolynomial.algebraMap_eq])
      F G hF0 hshare
  · exact exists_univariate_mem
      (planeEquiv.trans (MvPolynomial.renameEquiv ℂ (Equiv.swap 0 1)).toRingEquiv) 1
      (fun a => by
        simp only [RingEquiv.trans_apply, AlgEquiv.coe_toRingEquiv,
          MvPolynomial.renameEquiv_apply]
        rw [show planeEquiv (Polynomial.C a) = Polynomial.aeval (MvPolynomial.X 0) a by
          simp [planeEquiv, toPlane, Polynomial.aeval_def, MvPolynomial.algebraMap_eq]]
        rw [← Polynomial.aeval_algHom_apply]
        simp)
      F G hF0 hshare

theorem pipeY_eval_lineRoot :
    pipeY.eval (lineRoot 4 3 (-25)) =
      Polynomial.C (25 / 16 : ℂ) * (Polynomial.X - Polynomial.C 3) ^ 2 := by
  apply Polynomial.funext
  intro x
  simp [pipeY, lineRoot]
  ring

theorem natDegree_pipeY : pipeY.natDegree = 2 := by
  unfold pipeY
  exact Polynomial.natDegree_X_pow_add_C

theorem toPlane_pipeY : toPlane pipeY = pipe := by
  simp [toPlane, pipeY, pipe, Polynomial.eval₂_pow, map_ofNat]; ring

theorem toPlane_beam : toPlane (lineY 4 3 (-25)) = beam := by
  simp [toPlane, lineY, beam, map_ofNat]; ring

/-- **A tangency counts as two.** Let `F` and `G` be two plane curves over `ℂ` that both pass
through `P`, are both smooth there (nonzero gradient, so each has one tangent line), and share
no piece (every common factor is a nonzero constant). Then their intersection multiplicity at
`P` is 1 exactly when their tangent lines differ (the two gradients are linearly independent),
and when the tangent lines are the same it is at least 2. -/
theorem intersectionMultiplicity_eq_one_iff_tangents_differ
    (F G : MvPolynomial (Fin 2) ℂ) (P : Fin 2 → ℂ)
    (hF : MvPolynomial.eval P F = 0) (hG : MvPolynomial.eval P G = 0)
    (hFs : gradientAt F P ≠ 0) (hGs : gradientAt G P ≠ 0)
    (hshare : ∀ h, h ∣ F → h ∣ G → IsUnit h) :
    (intersectionMultiplicity F G P = 1 ↔
        LinearIndependent ℂ ![gradientAt F P, gradientAt G P]) ∧
      (¬ LinearIndependent ℂ ![gradientAt F P, gradientAt G P] →
        2 ≤ intersectionMultiplicity F G P) := by
  have hF0 : F ≠ 0 := by
    rintro rfl
    apply hFs
    ext i; fin_cases i <;> simp [gradientAt]
  have hu : ¬ (gradientAt F P 0 = 0 ∧ gradientAt F P 1 = 0) := by
    rintro ⟨h0, h1⟩
    apply hFs
    ext i; fin_cases i
    · exact h0
    · exact h1
  have hdep : ¬ LinearIndependent ℂ ![gradientAt F P, gradientAt G P] →
      2 ≤ intersectionMultiplicity F G P := by
    intro hli
    rw [LinearIndependent.pair_iff] at hli
    push Not at hli
    obtain ⟨s, t, hst, hne⟩ := hli
    have e0 := congrFun hst 0
    have e1 := congrFun hst 1
    simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul, Pi.zero_apply] at e0 e1
    have ht : t ≠ 0 := by
      intro ht
      have hs := hne.mt (not_not.2 ht)
      rw [ht, zero_mul, add_zero] at e0 e1
      exact hu ⟨(mul_eq_zero.1 e0).resolve_left (by simpa using hs),
        (mul_eq_zero.1 e1).resolve_left (by simpa using hs)⟩
    have hwG : gradientAt G P 0 * gradientAt F P 1 + gradientAt G P 1 * (-gradientAt F P 0) = 0 := by
      have : t * (gradientAt G P 0 * gradientAt F P 1 + gradientAt G P 1 * (-gradientAt F P 0)) = 0 := by
        linear_combination (gradientAt F P 1) * e0 - (gradientAt F P 0) * e1
      exact (mul_eq_zero.1 this).resolve_left ht
    have := finite_LQ_of_coprime F G P hF0 hshare
    refine two_le_of_tangent F G P ![gradientAt F P 1, -gradientAt F P 0] hF hG ?_ ?_ ?_
    · simp; ring
    · simpa using hwG
    · intro hw
      apply hu
      have h0 := congrFun hw 0
      have h1 := congrFun hw 1
      simp at h0 h1
      exact ⟨h1, h0⟩
  refine ⟨⟨fun h1 => ?_, fun hli => ?_⟩, hdep⟩
  · by_contra hli
    have := hdep hli
    omega
  · apply intersectionMultiplicity_eq_one_of_det F G P hF hG
    intro hdet
    rw [LinearIndependent.pair_iff] at hli
    have ha := hli (gradientAt G P 1) (-gradientAt F P 1) (by
      ext i; fin_cases i
      · simp; linear_combination hdet
      · simp; ring)
    have hb := hli (gradientAt G P 0) (-gradientAt F P 0) (by
      ext i; fin_cases i
      · simp; ring
      · simp; linear_combination -hdet)
    exact hu ⟨neg_eq_zero.1 hb.2, neg_eq_zero.1 ha.2⟩

/-- **The resultant sees the same count, for a curve and a line.** Let `F` be a curve over
`ℂ`, written in `y` with coefficients in `x`, and let `G` be the line `b y + c x + e = 0`
with `b ≠ 0` (a constant top `y`-coefficient, so only one meeting point `P` sits above each
`x`-value `a`), sharing no piece with `F`. Then the order of `a` as a root of the resultant
`Res_y(F, G)` equals the intersection multiplicity of `F` and `G` at `P = (a, -(c a + e)/b)`. -/
theorem rootMultiplicity_resultant_eq_intersectionMultiplicity_line
    (F : ℂ[X][X]) (b c e a : ℂ) (hb : b ≠ 0)
    (hshare : ∀ h, h ∣ toPlane F → h ∣ toPlane (lineY b c e) → IsUnit h) :
    (Polynomial.resultant F (lineY b c e)).rootMultiplicity a =
      intersectionMultiplicity (toPlane F) (toPlane (lineY b c e)) ![a, -(c * a + e) / b] := by
  have hf := eval_lineRoot_ne_zero F b c e a hb hshare
  rw [rootMultiplicity_resultant_lineY F b c e a hb hf, intersectionMultiplicity_line F b c e a hb hf]

/-- **The pipe and the beam.** The beam `3x + 4y = 25` touches the pipe `x² + y² = 25` at
`P = (3, 4)` with intersection multiplicity 2, and the resultant in `y` is
`Res_y(x² + y² - 25, 3x + 4y - 25) = 25 (x - 3)²`, with `x = 3` a double root. -/
theorem pipe_beam_multiplicity_two :
    intersectionMultiplicity pipe beam ![3, 4] = 2 ∧
      Polynomial.resultant pipeY (lineY 4 3 (-25)) =
        Polynomial.C 25 * (Polynomial.X - Polynomial.C 3) ^ 2 := by
  have hf : pipeY.eval (lineRoot 4 3 (-25)) ≠ 0 := by
    rw [pipeY_eval_lineRoot]
    exact mul_ne_zero (by simp) (pow_ne_zero _ (Polynomial.X_sub_C_ne_zero 3))
  constructor
  · have h := intersectionMultiplicity_line pipeY 4 3 (-25) 3 (by norm_num) hf
    have hP : (![3, -(3 * 3 + -25) / 4] : Fin 2 → ℂ) = ![3, 4] := by
      ext i; fin_cases i <;> norm_num
    rw [hP, toPlane_pipeY, toPlane_beam, pipeY_eval_lineRoot,
      Polynomial.rootMultiplicity_mul (mul_ne_zero (by simp) (pow_ne_zero _ (Polynomial.X_sub_C_ne_zero 3))),
      Polynomial.rootMultiplicity_C, Polynomial.rootMultiplicity_X_sub_C_pow] at h
    simpa using h
  · rw [resultant_lineY pipeY 4 3 (-25) (by norm_num), natDegree_pipeY, pipeY_eval_lineRoot,
      ← mul_assoc, ← Polynomial.C_mul]
    norm_num

-- The pipe and beam in ℂ[x][y] are the plane polynomials of the card.
example : toPlane pipeY = pipe ∧ toPlane (lineY 4 3 (-25)) = beam := by
  constructor <;> simp [toPlane, pipeY, lineY, pipe, beam, Polynomial.eval₂_pow, map_ofNat] <;> ring

-- P = (3, 4) is on the pipe and on the beam.
example : (3 : ℤ) ^ 2 + 4 ^ 2 = 25 ∧ 3 * 3 + 4 * 4 = (25 : ℤ) := by norm_num

-- Gradient of the pipe at P is (6, 8) = 2 × (3, 4), the beam's normal: the 2 × 2
-- determinant is 0, so the tangent lines agree. The radius line 4x - 3y has normal (4, -3).
example : (2 * 3, 2 * 4) = ((6 : ℤ), (8 : ℤ)) ∧ (6 * 4 - 8 * 3 : ℤ) = 0 ∧
    (6 * (-3) - 8 * 4 : ℤ) ≠ 0 := by norm_num

-- Put the beam into the pipe, times 16: 25x² - 150x + 225 = 25 (x - 3)².
example (x : ℤ) : 16 * x ^ 2 + (25 - 3 * x) ^ 2 - 400 = 25 * (x - 3) ^ 2 := by ring

-- The Sylvester determinant: (3x - 25)² + 16 (x² - 25) = 25 (x - 3)².
example (x : ℤ) : (3 * x - 25) ^ 2 + 16 * (x ^ 2 - 25) = 25 * (x - 3) ^ 2 := by ring

-- Walking along the beam: (3 + 4t)² + (4 - 3t)² - 25 = 25t², order 2;
-- along the radius: (3 + 3t)² + (4 + 4t)² - 25 = 25t² + 50t, order 1.
example (t : ℤ) : (3 + 4 * t) ^ 2 + (4 - 3 * t) ^ 2 - 25 = 25 * t ^ 2 := by ring
example (t : ℤ) : (3 + 3 * t) ^ 2 + (4 + 4 * t) ^ 2 - 25 = 25 * t ^ 2 + 50 * t := by ring

-- Discriminants of the three beams: secant 3136, tangent 0, miss -17600.
example : (144 : ℤ) ^ 2 - 4 * 25 * 176 = 3136 ∧ (150 : ℤ) ^ 2 - 4 * 25 * 225 = 0 ∧
    (180 : ℤ) ^ 2 - 4 * 25 * 500 = -17600 := by norm_num

-- The secant beam 3x + 4y = 24: 25x² - 144x + 176 = (x - 4)(25x - 44), with the
-- points (4, 3) and (44/25, 117/25) on both, 2.8 cm apart (distance squared 196/25).
example (x : ℤ) : 25 * x ^ 2 - 144 * x + 176 = (x - 4) * (25 * x - 44) := by ring
example : (4 : ℚ) ^ 2 + 3 ^ 2 = 25 ∧ 3 * 4 + 4 * 3 = (24 : ℚ) ∧
    (44 / 25 : ℚ) ^ 2 + (117 / 25) ^ 2 = 25 ∧ 3 * (44 / 25) + 4 * (117 / 25) = (24 : ℚ) ∧
    (4 - 44 / 25 : ℚ) ^ 2 + (3 - 117 / 25) ^ 2 = 4 * (10 * (1 / 5) - (1 / 5) ^ 2) := by norm_num

-- The second pipe, centre (6, 8): its equation minus the first pipe's is -4 times the beam.
example (x y : ℤ) : ((x - 6) ^ 2 + (y - 8) ^ 2 - 25) - (x ^ 2 + y ^ 2 - 25) =
    -4 * (3 * x + 4 * y - 25) := by ring

-- The nodal cubic y² = x²(x + 1) against y = 2x gives -x³ + 3x², against y = x gives -x³.
example (x : ℤ) : (2 * x) ^ 2 - x ^ 2 * (x + 1) = -x ^ 3 + 3 * x ^ 2 := by ring
example (x : ℤ) : x ^ 2 - x ^ 2 * (x + 1) = -x ^ 3 := by ring

-- The vertical beam x = 3 meets the pipe at (3, 4) and (3, -4).
example : (3 : ℤ) ^ 2 + 4 ^ 2 = 25 ∧ (3 : ℤ) ^ 2 + (-4) ^ 2 = 25 := by norm_num

#print axioms C_mul_lineRoot
#print axioms lineY_eq
#print axioms natDegree_lineY
#print axioms resultant_lineY
#print axioms eval_lineRoot
#print axioms aeval_toPlane
#print axioms eval_aeval_line
#print axioms isUnit_mk_of_eval_ne_zero
#print axioms isUnit_algebraMap_localization
#print axioms intersectionMultiplicity_line
#print axioms rootMultiplicity_resultant_lineY
#print axioms eval_lineRoot_ne_zero
#print axioms exists_decomp
#print axioms exists_decomp_grad
#print axioms toQ_left
#print axioms toQ_right
#print axioms isUnit_toQ
#print axioms toQ_frac
#print axioms liftQ_toQ
#print axioms toQ_eq_algebraMap_of_det
#print axioms intersectionMultiplicity_eq_one_of_det
#print axioms aeval_dualPoint_fst
#print axioms aeval_dualPoint_snd
#print axioms two_le_of_tangent
#print axioms finite_quot_of_univariate
#print axioms finite_LQ
#print axioms smul_eq_C_algebraMap_mul
#print axioms exists_C_mem_span
#print axioms fromPlane_toPlane
#print axioms toPlane_fromPlane
#print axioms exists_univariate_mem
#print axioms finite_LQ_of_coprime
#print axioms pipeY_eval_lineRoot
#print axioms natDegree_pipeY
#print axioms toPlane_pipeY
#print axioms toPlane_beam
#print axioms intersectionMultiplicity_eq_one_iff_tangents_differ
#print axioms rootMultiplicity_resultant_eq_intersectionMultiplicity_line
#print axioms pipe_beam_multiplicity_two
