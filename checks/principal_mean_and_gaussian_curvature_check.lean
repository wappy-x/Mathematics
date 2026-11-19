-- Principal, mean and Gaussian curvature: at a point of a surface patch with a regular chart, the shape operator W = I⁻¹ II has two real eigenvalues κ₁ ≥ κ₂ with eigen-headings perpendicular on the surface, they are the largest and smallest bending rates II(t, t)/I(t, t) with Euler's formula in between, their product is (LN − M²)/(EG − F²) and their average is (EN − 2FM + GL)/(2(EG − F²)).
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Tactic.NormNum

open Matrix Real

/-- Space, where the roof sits: three coordinates in metres. -/
abbrev Space := EuclideanSpace ℝ (Fin 3)

/-! ### The card's objects at the point `p` of a patch `r(u, v)`

`r : ℝ × ℝ → Space` is the patch, `p` the plan point, `n` the chosen unit normal.
A plan step `t = (a, b)` (metres east and north on the plan) is a vector `Fin 2 → ℝ`. -/

/-- `r_u`, the patch's first derivative along the first chart coordinate. -/
noncomputable def ru (r : ℝ × ℝ → Space) (p : ℝ × ℝ) : Space := fderiv ℝ r p (1, 0)
/-- `r_v`, the patch's first derivative along the second chart coordinate. -/
noncomputable def rv (r : ℝ × ℝ → Space) (p : ℝ × ℝ) : Space := fderiv ℝ r p (0, 1)
/-- `r_uu`. -/
noncomputable def ruu (r : ℝ × ℝ → Space) (p : ℝ × ℝ) : Space :=
  fderiv ℝ (fun q => fderiv ℝ r q (1, 0)) p (1, 0)
/-- `r_uv`. -/
noncomputable def ruv (r : ℝ × ℝ → Space) (p : ℝ × ℝ) : Space :=
  fderiv ℝ (fun q => fderiv ℝ r q (1, 0)) p (0, 1)
/-- `r_vv`. -/
noncomputable def rvv (r : ℝ × ℝ → Space) (p : ℝ × ℝ) : Space :=
  fderiv ℝ (fun q => fderiv ℝ r q (0, 1)) p (0, 1)

/-- First fundamental form `E = r_u · r_u`. -/
noncomputable def formE (r : ℝ × ℝ → Space) (p : ℝ × ℝ) : ℝ := inner ℝ (ru r p) (ru r p)
/-- First fundamental form `F = r_u · r_v`. -/
noncomputable def formF (r : ℝ × ℝ → Space) (p : ℝ × ℝ) : ℝ := inner ℝ (ru r p) (rv r p)
/-- First fundamental form `G = r_v · r_v`. -/
noncomputable def formG (r : ℝ × ℝ → Space) (p : ℝ × ℝ) : ℝ := inner ℝ (rv r p) (rv r p)
/-- Second fundamental form `L = r_uu · n`. -/
noncomputable def formL (r : ℝ × ℝ → Space) (n : Space) (p : ℝ × ℝ) : ℝ := inner ℝ (ruu r p) n
/-- Second fundamental form `M = r_uv · n`. -/
noncomputable def formM (r : ℝ × ℝ → Space) (n : Space) (p : ℝ × ℝ) : ℝ := inner ℝ (ruv r p) n
/-- Second fundamental form `N = r_vv · n`. -/
noncomputable def formN (r : ℝ × ℝ → Space) (n : Space) (p : ℝ × ℝ) : ℝ := inner ℝ (rvv r p) n

/-- The first form as the matrix `I = [[E, F], [F, G]]`. -/
noncomputable def firstForm (r : ℝ × ℝ → Space) (p : ℝ × ℝ) : Matrix (Fin 2) (Fin 2) ℝ :=
  !![formE r p, formF r p; formF r p, formG r p]

/-- The second form as the matrix `II = [[L, M], [M, N]]`. -/
noncomputable def secondForm (r : ℝ × ℝ → Space) (n : Space) (p : ℝ × ℝ) :
    Matrix (Fin 2) (Fin 2) ℝ :=
  !![formL r n p, formM r n p; formM r n p, formN r n p]

/-- The shape operator `W = I⁻¹ II`, acting on plan steps. -/
noncomputable def shapeOperator (r : ℝ × ℝ → Space) (n : Space) (p : ℝ × ℝ) :
    Matrix (Fin 2) (Fin 2) ℝ :=
  (firstForm r p)⁻¹ * secondForm r n p

/-- The normal curvature along the plan step `t`: the bending rate `κ_n = II(t, t) / I(t, t)`
toward `n` (the formula from the card on the Gauss map and second fundamental form). -/
noncomputable def normalCurvature (r : ℝ × ℝ → Space) (n : Space) (p : ℝ × ℝ)
    (t : Fin 2 → ℝ) : ℝ :=
  (t ⬝ᵥ (secondForm r n p *ᵥ t)) / (t ⬝ᵥ (firstForm r p *ᵥ t))

/-- Gaussian curvature by the card's formula, `K = (LN − M²)/(EG − F²)`. -/
noncomputable def gaussianCurvature (r : ℝ × ℝ → Space) (n : Space) (p : ℝ × ℝ) : ℝ :=
  (formL r n p * formN r n p - formM r n p ^ 2) /
    (formE r p * formG r p - formF r p ^ 2)

/-- Mean curvature by the card's formula, `H = (EN − 2FM + GL)/(2(EG − F²))`. -/
noncomputable def meanCurvature (r : ℝ × ℝ → Space) (n : Space) (p : ℝ × ℝ) : ℝ :=
  (formE r p * formN r n p - 2 * formF r p * formM r n p + formG r p * formL r n p) /
    (2 * (formE r p * formG r p - formF r p ^ 2))

lemma sym2_eigen (a b c : ℝ) : ∃ (l1 l2 : ℝ) (w1 w2 : Fin 2 → ℝ), l2 ≤ l1 ∧
    w1 ⬝ᵥ w1 = 1 ∧ w2 ⬝ᵥ w2 = 1 ∧ w1 ⬝ᵥ w2 = 0 ∧
    !![a, b; b, c] *ᵥ w1 = l1 • w1 ∧ !![a, b; b, c] *ᵥ w2 = l2 • w2 ∧
    l1 + l2 = a + c ∧ l1 * l2 = a * c - b ^ 2 := by
  by_cases hb : b = 0
  · subst hb
    rcases le_total c a with h | h
    · refine ⟨a, c, ![1, 0], ![0, 1], h, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
      all_goals first
        | (ext i; fin_cases i <;> simp [Matrix.mulVec, dotProduct, Fin.sum_univ_two])
        | (simp [dotProduct, Fin.sum_univ_two]; done)
        | (simp [dotProduct, Fin.sum_univ_two]; ring)
        | ring
    · refine ⟨c, a, ![0, 1], ![1, 0], h, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
      all_goals first
        | (ext i; fin_cases i <;> simp [Matrix.mulVec, dotProduct, Fin.sum_univ_two])
        | (simp [dotProduct, Fin.sum_univ_two]; done)
        | (simp [dotProduct, Fin.sum_univ_two]; ring)
        | ring
  · set R := √((a - c) ^ 2 + 4 * b ^ 2) with hRdef
    have hb2 : 0 < b ^ 2 := by positivity
    have hR2 : R ^ 2 = (a - c) ^ 2 + 4 * b ^ 2 := Real.sq_sqrt (by positivity)
    have hR : 0 < R := Real.sqrt_pos.mpr (by positivity)
    set l1 := (a + c + R) / 2
    set l2 := (a + c - R) / 2
    have e1 : l1 ^ 2 - (a + c) * l1 + (a * c - b ^ 2) = 0 := by
      simp only [l1]; linear_combination (1 / 4 : ℝ) * hR2
    have e2 : l2 ^ 2 - (a + c) * l2 + (a * c - b ^ 2) = 0 := by
      simp only [l2]; linear_combination (1 / 4 : ℝ) * hR2
    set n1 := √(b ^ 2 + (l1 - a) ^ 2)
    set n2 := √(b ^ 2 + (l2 - a) ^ 2)
    have hn1 : n1 ^ 2 = b ^ 2 + (l1 - a) ^ 2 := Real.sq_sqrt (by positivity)
    have hn2 : n2 ^ 2 = b ^ 2 + (l2 - a) ^ 2 := Real.sq_sqrt (by positivity)
    have hn1p : 0 < n1 := Real.sqrt_pos.mpr (by positivity)
    have hn2p : 0 < n2 := Real.sqrt_pos.mpr (by positivity)
    refine ⟨l1, l2, ![b / n1, (l1 - a) / n1], ![b / n2, (l2 - a) / n2], ?_, ?_, ?_, ?_, ?_, ?_,
      ?_, ?_⟩
    · simp only [l1, l2]; linarith
    · simp [dotProduct, Fin.sum_univ_two]
      field_simp
      linarith
    · simp [dotProduct, Fin.sum_univ_two]
      field_simp
      linarith
    · simp [dotProduct, Fin.sum_univ_two]
      field_simp
      have : l1 + l2 = a + c := by simp only [l1, l2]; ring
      have : l1 * l2 = a * c - b ^ 2 := by simp only [l1, l2]; linear_combination (-1 / 4 : ℝ) * hR2
      linear_combination (by assumption : l1 * l2 = a * c - b ^ 2) - a * (by assumption : l1 + l2 = a + c)
    · ext i; fin_cases i <;> simp [Matrix.mulVec, dotProduct, Fin.sum_univ_two] <;> field_simp
      · ring
      · linear_combination (-1 : ℝ) * e1
    · ext i; fin_cases i <;> simp [Matrix.mulVec, dotProduct, Fin.sum_univ_two] <;> field_simp
      · ring
      · linear_combination (-1 : ℝ) * e2
    · simp only [l1, l2]; ring
    · simp only [l1, l2]; linear_combination (-1 / 4 : ℝ) * hR2

lemma sym2_char (a b c μ : ℝ) (w : Fin 2 → ℝ) (hw : w ≠ 0)
    (h : !![a, b; b, c] *ᵥ w = μ • w) : (a - μ) * (c - μ) - b ^ 2 = 0 := by
  have h0 := congrFun h 0
  have h1 := congrFun h 1
  simp [Matrix.mulVec, dotProduct, Fin.sum_univ_two] at h0 h1
  have hx : ((a - μ) * (c - μ) - b ^ 2) * w 0 = 0 := by
    linear_combination (c - μ) * h0 - b * h1
  have hy : ((a - μ) * (c - μ) - b ^ 2) * w 1 = 0 := by
    linear_combination (a - μ) * h1 - b * h0
  by_contra hne
  apply hw
  ext i; fin_cases i
  · simpa using (mul_eq_zero.mp hx).resolve_left hne
  · simpa using (mul_eq_zero.mp hy).resolve_left hne

lemma quad_nonneg (α β b x y : ℝ) (hab : α * β = b ^ 2) (hs : 0 ≤ α + β) :
    0 ≤ α * x ^ 2 - 2 * b * x * y + β * y ^ 2 := by
  have k1 : α * (α * x ^ 2 - 2 * b * x * y + β * y ^ 2) = (α * x - b * y) ^ 2 := by
    linear_combination y ^ 2 * hab
  have k2 : β * (α * x ^ 2 - 2 * b * x * y + β * y ^ 2) = (β * y - b * x) ^ 2 := by
    linear_combination x ^ 2 * hab
  rcases hs.lt_or_eq with hs | hs
  · nlinarith [sq_nonneg (α * x - b * y), sq_nonneg (β * y - b * x)]
  · have hβ : β = -α := by linarith
    subst hβ
    have h2 : α ^ 2 + b ^ 2 = 0 := by linear_combination -hab
    have ha2 : α ^ 2 = 0 := by nlinarith [sq_nonneg α, sq_nonneg b]
    have hb2 : b ^ 2 = 0 := by nlinarith [sq_nonneg α, sq_nonneg b]
    have ha : α = 0 := pow_eq_zero_iff (n := 2) (by norm_num) |>.mp ha2
    have hb : b = 0 := pow_eq_zero_iff (n := 2) (by norm_num) |>.mp hb2
    subst ha hb
    simp

lemma sym2_rayleigh (a b c l1 l2 : ℝ) (h12 : l2 ≤ l1) (hs : l1 + l2 = a + c)
    (hp : l1 * l2 = a * c - b ^ 2) (w : Fin 2 → ℝ) :
    l2 * (w ⬝ᵥ w) ≤ w ⬝ᵥ (!![a, b; b, c] *ᵥ w) ∧
      w ⬝ᵥ (!![a, b; b, c] *ᵥ w) ≤ l1 * (w ⬝ᵥ w) := by
  simp only [Matrix.mulVec, dotProduct, Fin.sum_univ_two, Matrix.of_apply, Matrix.cons_val',
    Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.empty_val', Matrix.cons_val_fin_one]
  have q1 : (l1 - a) * (l1 - c) = b ^ 2 := by linear_combination l1 * hs - hp
  have q2 : (a - l2) * (c - l2) = (-b) ^ 2 := by linear_combination l2 * hs - hp
  have n1 := quad_nonneg (l1 - a) (l1 - c) b (w 0) (w 1) q1 (by linarith)
  have n2 := quad_nonneg (a - l2) (c - l2) (-b) (w 0) (w 1) q2 (by linarith)
  constructor <;> nlinarith [n1, n2]

/-- The Cholesky frame of a positive definite 2×2 Gram matrix, and the shape operator seen in it. -/
lemma spec_data (E F G L M N : ℝ) (hE : 0 < E) (hD : 0 < E * G - F ^ 2) :
    ∃ (P : Matrix (Fin 2) (Fin 2) ℝ) (a b c : ℝ),
      Pᵀ * !![E, F; F, G] * P = 1 ∧ Pᵀ * !![L, M; M, N] * P = !![a, b; b, c] ∧
      (∀ v, P *ᵥ ((Pᵀ * !![E, F; F, G]) *ᵥ v) = v) ∧
      (∀ z, (Pᵀ * !![E, F; F, G]) *ᵥ (P *ᵥ z) = z) ∧
      (∀ w, ((!![E, F; F, G])⁻¹ * !![L, M; M, N]) *ᵥ (P *ᵥ w) = P *ᵥ (!![a, b; b, c] *ᵥ w)) ∧
      a + c = (E * N - 2 * F * M + G * L) / (E * G - F ^ 2) ∧
      a * c - b ^ 2 = (L * N - M ^ 2) / (E * G - F ^ 2) := by
  obtain ⟨s, hs, rfl⟩ : ∃ s : ℝ, 0 < s ∧ E = s ^ 2 :=
    ⟨√E, Real.sqrt_pos.mpr hE, (Real.sq_sqrt hE.le).symm⟩
  obtain ⟨d, hd, hdD⟩ : ∃ d : ℝ, 0 < d ∧ d ^ 2 = s ^ 2 * G - F ^ 2 :=
    ⟨√(s ^ 2 * G - F ^ 2), Real.sqrt_pos.mpr hD, Real.sq_sqrt hD.le⟩
  obtain rfl : G = (d ^ 2 + F ^ 2) / s ^ 2 := by field_simp; linarith
  have hDd : s ^ 2 * ((d ^ 2 + F ^ 2) / s ^ 2) - F ^ 2 = d ^ 2 := by field_simp; ring
  rw [hDd]
  clear hdD hD hDd hE
  set I : Matrix (Fin 2) (Fin 2) ℝ := !![s ^ 2, F; F, (d ^ 2 + F ^ 2) / s ^ 2] with hI
  set II : Matrix (Fin 2) (Fin 2) ℝ := !![L, M; M, N] with hII
  set P : Matrix (Fin 2) (Fin 2) ℝ := !![1 / s, -F / (s * d); 0, s / d] with hP
  set C : Matrix (Fin 2) (Fin 2) ℝ :=
    !![(d ^ 2 + F ^ 2) / s ^ 2 / d ^ 2, -F / d ^ 2; -F / d ^ 2, s ^ 2 / d ^ 2] with hC
  have hPIP : Pᵀ * I * P = 1 := by
    ext i j; fin_cases i <;> fin_cases j <;>
      simp [hP, hI, Matrix.mul_apply, Fin.sum_univ_two] <;> field_simp <;> first | ring1 | simp
  have hCI : C * I = 1 := by
    ext i j; fin_cases i <;> fin_cases j <;>
      simp [hC, hI, Matrix.mul_apply, Fin.sum_univ_two] <;> field_simp <;> ring1
  have hPP : P * Pᵀ = C := by
    ext i j; fin_cases i <;> fin_cases j <;>
      simp [hP, hC, Matrix.mul_apply, Fin.sum_univ_two] <;> field_simp
  have hIinv : I⁻¹ = C := Matrix.inv_eq_left_inv hCI
  set S : Matrix (Fin 2) (Fin 2) ℝ := Pᵀ * II * P with hSdef
  have hsym : S 1 0 = S 0 1 := by
    simp [hSdef, hP, hII, Matrix.mul_apply, Fin.sum_univ_two]; ring
  have hS : S = !![S 0 0, S 0 1; S 0 1, S 1 1] := by
    conv_lhs => rw [Matrix.eta_fin_two S]
    rw [hsym]
  refine ⟨P, S 0 0, S 0 1, S 1 1, hPIP, hS, ?_, ?_, ?_, ?_, ?_⟩
  · intro v
    rw [Matrix.mulVec_mulVec, ← Matrix.mul_assoc, hPP, hCI, Matrix.one_mulVec]
  · intro z
    rw [Matrix.mulVec_mulVec, hPIP, Matrix.one_mulVec]
  · intro w
    rw [← hS, hIinv, ← hPP, Matrix.mulVec_mulVec, Matrix.mulVec_mulVec, hSdef]
    simp only [Matrix.mul_assoc]
  · simp [hSdef, hP, hII, Matrix.mul_apply, Fin.sum_univ_two]
    field_simp
    ring
  · simp [hSdef, hP, hII, Matrix.mul_apply, Fin.sum_univ_two]
    field_simp
    ring

lemma dot_self_pos (w : Fin 2 → ℝ) (hw : w ≠ 0) : 0 < w ⬝ᵥ w := by
  simp only [dotProduct, Fin.sum_univ_two]
  by_contra h
  rw [not_lt] at h
  apply hw
  have h0 : w 0 * w 0 = 0 := by nlinarith [mul_self_nonneg (w 0), mul_self_nonneg (w 1)]
  have h1 : w 1 * w 1 = 0 := by nlinarith [mul_self_nonneg (w 0), mul_self_nonneg (w 1)]
  ext i; fin_cases i
  · simpa using mul_self_eq_zero.mp h0
  · simpa using mul_self_eq_zero.mp h1

lemma main_lin (E F G L M N : ℝ) (hE : 0 < E) (hD : 0 < E * G - F ^ 2) :
    ∃ (κ₁ κ₂ : ℝ) (u₁ u₂ : Fin 2 → ℝ),
      κ₂ ≤ κ₁ ∧
      u₁ ⬝ᵥ (!![E, F; F, G] *ᵥ u₁) = 1 ∧ u₂ ⬝ᵥ (!![E, F; F, G] *ᵥ u₂) = 1 ∧
      u₁ ⬝ᵥ (!![E, F; F, G] *ᵥ u₂) = 0 ∧
      ((!![E, F; F, G])⁻¹ * !![L, M; M, N]) *ᵥ u₁ = κ₁ • u₁ ∧
      ((!![E, F; F, G])⁻¹ * !![L, M; M, N]) *ᵥ u₂ = κ₂ • u₂ ∧
      (∀ (μ : ℝ) (v : Fin 2 → ℝ), v ≠ 0 →
        ((!![E, F; F, G])⁻¹ * !![L, M; M, N]) *ᵥ v = μ • v → μ = κ₁ ∨ μ = κ₂) ∧
      (∀ θ : ℝ, ((cos θ • u₁ + sin θ • u₂) ⬝ᵥ (!![L, M; M, N] *ᵥ (cos θ • u₁ + sin θ • u₂))) /
          ((cos θ • u₁ + sin θ • u₂) ⬝ᵥ (!![E, F; F, G] *ᵥ (cos θ • u₁ + sin θ • u₂))) =
        κ₁ * cos θ ^ 2 + κ₂ * sin θ ^ 2) ∧
      (∀ t : Fin 2 → ℝ, t ≠ 0 →
        κ₂ ≤ (t ⬝ᵥ (!![L, M; M, N] *ᵥ t)) / (t ⬝ᵥ (!![E, F; F, G] *ᵥ t)) ∧
        (t ⬝ᵥ (!![L, M; M, N] *ᵥ t)) / (t ⬝ᵥ (!![E, F; F, G] *ᵥ t)) ≤ κ₁) ∧
      κ₁ * κ₂ = (L * N - M ^ 2) / (E * G - F ^ 2) ∧
      (κ₁ + κ₂) / 2 = (E * N - 2 * F * M + G * L) / (2 * (E * G - F ^ 2)) := by
  obtain ⟨P, a, b, c, hPIP, hS, hleft, hright, hW, htr, hdet⟩ := spec_data E F G L M N hE hD
  obtain ⟨l1, l2, w1, w2, h12, h11, h22, h1_2, hev1, hev2, hsum, hprod⟩ := sym2_eigen a b c
  have hform : ∀ (A : Matrix (Fin 2) (Fin 2) ℝ) (w w' : Fin 2 → ℝ),
      (P *ᵥ w) ⬝ᵥ (A *ᵥ (P *ᵥ w')) = w ⬝ᵥ ((Pᵀ * A * P) *ᵥ w') := by
    intro A w w'
    simp [Matrix.mulVec, dotProduct, Fin.sum_univ_two, Matrix.mul_apply]
    ring
  have hI' : ∀ w w', (P *ᵥ w) ⬝ᵥ (!![E, F; F, G] *ᵥ (P *ᵥ w')) = w ⬝ᵥ w' := by
    intro w w'; rw [hform, hPIP, Matrix.one_mulVec]
  have hII' : ∀ w w', (P *ᵥ w) ⬝ᵥ (!![L, M; M, N] *ᵥ (P *ᵥ w')) =
      w ⬝ᵥ (!![a, b; b, c] *ᵥ w') := by
    intro w w'; rw [hform, hS]
  have h21 : w2 ⬝ᵥ w1 = 0 := by rw [dotProduct_comm]; exact h1_2
  refine ⟨l1, l2, P *ᵥ w1, P *ᵥ w2, h12, by rw [hI']; exact h11, by rw [hI']; exact h22,
    by rw [hI']; exact h1_2, by rw [hW, hev1, Matrix.mulVec_smul],
    by rw [hW, hev2, Matrix.mulVec_smul], ?_, ?_, ?_, by rw [hprod, hdet], by rw [hsum, htr, div_div, mul_comm (E * G - F ^ 2) 2]⟩
  · intro μ v hv hμ
    have hvw : P *ᵥ ((Pᵀ * !![E, F; F, G]) *ᵥ v) = v := hleft v
    set w := (Pᵀ * !![E, F; F, G]) *ᵥ v with hwdef
    have hw0 : w ≠ 0 := by
      intro h; apply hv; rw [← hvw, h, Matrix.mulVec_zero]
    have hSw : !![a, b; b, c] *ᵥ w = μ • w := by
      have h1 := hW w
      rw [hvw, hμ] at h1
      have h2 := congrArg (fun x => (Pᵀ * !![E, F; F, G]) *ᵥ x) h1
      simp only [Matrix.mulVec_smul, hright] at h2
      exact h2.symm
    have hc := sym2_char a b c μ w hw0 hSw
    have hm : (μ - l1) * (μ - l2) = 0 := by linear_combination hc - μ * hsum + hprod
    rcases mul_eq_zero.mp hm with h | h
    · left; linarith
    · right; linarith
  · intro θ
    have ht : cos θ • P *ᵥ w1 + sin θ • P *ᵥ w2 = P *ᵥ (cos θ • w1 + sin θ • w2) := by
      rw [Matrix.mulVec_add, Matrix.mulVec_smul, Matrix.mulVec_smul]
    have hnum : (cos θ • w1 + sin θ • w2) ⬝ᵥ (!![a, b; b, c] *ᵥ (cos θ • w1 + sin θ • w2)) =
        l1 * cos θ ^ 2 + l2 * sin θ ^ 2 := by
      rw [Matrix.mulVec_add, Matrix.mulVec_smul, Matrix.mulVec_smul, hev1, hev2]
      simp only [dotProduct_add, add_dotProduct, dotProduct_smul, smul_dotProduct, smul_eq_mul,
        h11, h22, h1_2, h21]
      ring
    have hden : (cos θ • w1 + sin θ • w2) ⬝ᵥ (cos θ • w1 + sin θ • w2) = 1 := by
      simp only [dotProduct_add, add_dotProduct, dotProduct_smul, smul_dotProduct, smul_eq_mul,
        h11, h22, h1_2, h21]
      linear_combination cos_sq_add_sin_sq θ
    rw [ht, hI', hII', hnum, hden, div_one]
  · intro t ht0
    have hvw : P *ᵥ ((Pᵀ * !![E, F; F, G]) *ᵥ t) = t := hleft t
    set w := (Pᵀ * !![E, F; F, G]) *ᵥ t with hwdef
    have hw0 : w ≠ 0 := by
      intro h; apply ht0; rw [← hvw, h, Matrix.mulVec_zero]
    have hpos : 0 < w ⬝ᵥ w := dot_self_pos w hw0
    obtain ⟨lo, hi⟩ := sym2_rayleigh a b c l1 l2 h12 hsum hprod w
    rw [← hvw, hI', hII']
    constructor
    · rw [le_div_iff₀ hpos]; linarith
    · rw [div_le_iff₀ hpos]; linarith

lemma umb_lin (E F G L M N : ℝ) (hE : 0 < E) (hD : 0 < E * G - F ^ 2) (κ : ℝ)
    (humb : ∀ (μ : ℝ) (v : Fin 2 → ℝ), v ≠ 0 →
      ((!![E, F; F, G])⁻¹ * !![L, M; M, N]) *ᵥ v = μ • v → μ = κ) :
    ∀ t : Fin 2 → ℝ, t ≠ 0 →
      ((!![E, F; F, G])⁻¹ * !![L, M; M, N]) *ᵥ t = κ • t ∧
      (t ⬝ᵥ (!![L, M; M, N] *ᵥ t)) / (t ⬝ᵥ (!![E, F; F, G] *ᵥ t)) = κ := by
  obtain ⟨P, a, b, c, hPIP, hS, hleft, hright, hW, htr, hdet⟩ := spec_data E F G L M N hE hD
  obtain ⟨l1, l2, w1, w2, h12, h11, h22, h1_2, hev1, hev2, hsum, hprod⟩ := sym2_eigen a b c
  have hform : ∀ (A : Matrix (Fin 2) (Fin 2) ℝ) (w w' : Fin 2 → ℝ),
      (P *ᵥ w) ⬝ᵥ (A *ᵥ (P *ᵥ w')) = w ⬝ᵥ ((Pᵀ * A * P) *ᵥ w') := by
    intro A w w'
    simp [Matrix.mulVec, dotProduct, Fin.sum_univ_two, Matrix.mul_apply]
    ring
  have hI' : ∀ w w', (P *ᵥ w) ⬝ᵥ (!![E, F; F, G] *ᵥ (P *ᵥ w')) = w ⬝ᵥ w' := by
    intro w w'; rw [hform, hPIP, Matrix.one_mulVec]
  have hII' : ∀ w w', (P *ᵥ w) ⬝ᵥ (!![L, M; M, N] *ᵥ (P *ᵥ w')) =
      w ⬝ᵥ (!![a, b; b, c] *ᵥ w') := by
    intro w w'; rw [hform, hS]
  have hne : ∀ w : Fin 2 → ℝ, w ⬝ᵥ w = 1 → P *ᵥ w ≠ 0 := by
    intro w hw h
    have := hright w
    rw [h, Matrix.mulVec_zero] at this
    rw [← this] at hw
    simp at hw
  have hl1 : l1 = κ := humb l1 _ (hne w1 h11) (by rw [hW, hev1, Matrix.mulVec_smul])
  have hl2 : l2 = κ := humb l2 _ (hne w2 h22) (by rw [hW, hev2, Matrix.mulVec_smul])
  have hsq : (a - c) ^ 2 + 4 * b ^ 2 = (l1 - l2) ^ 2 := by
    linear_combination (-(l1 + l2 + a + c)) * hsum + 4 * hprod
  rw [hl1, hl2, sub_self] at hsq
  have hb : b = 0 := by nlinarith [sq_nonneg (a - c), sq_nonneg b]
  have hac : a = c := by nlinarith [sq_nonneg (a - c), sq_nonneg b]
  have ha : a = κ := by linarith
  have hSk : ∀ w : Fin 2 → ℝ, !![a, b; b, c] *ᵥ w = κ • w := by
    intro w
    rw [hb, ← hac, ha]
    ext i; fin_cases i <;> simp [Matrix.mulVec, dotProduct, Fin.sum_univ_two]
  intro t ht0
  have hvw : P *ᵥ ((Pᵀ * !![E, F; F, G]) *ᵥ t) = t := hleft t
  set w := (Pᵀ * !![E, F; F, G]) *ᵥ t with hwdef
  have hw0 : w ≠ 0 := by
    intro h; apply ht0; rw [← hvw, h, Matrix.mulVec_zero]
  have hpos : w ⬝ᵥ w ≠ 0 := (dot_self_pos w hw0).ne'
  constructor
  · rw [← hvw, hW, hSk, Matrix.mulVec_smul]
  · rw [← hvw, hI', hII', hSk, dotProduct_smul, smul_eq_mul]
    field_simp

/-- **Principal curvatures are the eigenvalues of the shape operator (Euler's theorem).**
Take a surface patch `r` that is smooth (twice continuously differentiable) at the plan point
`p`, a chosen unit normal `n` there (length 1, perpendicular to `r_u` and `r_v`), and a regular
chart, `EG − F² > 0`. Then there are two numbers `κ₁ ≥ κ₂` and two plan steps `u₁`, `u₂` that
are unit length and perpendicular on the surface (measured by the first form) such that:
`W u₁ = κ₁ u₁` and `W u₂ = κ₂ u₂`, and `W` has no other eigenvalue; the bending rate on the
heading turned by `θ` from `u₁` is `κ₁ cos² θ + κ₂ sin² θ` (Euler's formula); so `κ₁` and `κ₂`
are the largest and smallest bending rates over all headings; their product is the Gaussian
curvature `(LN − M²)/(EG − F²)` and their average is the mean curvature
`(EN − 2FM + GL)/(2(EG − F²))`. -/
theorem principal_curvatures_are_eigenvalues_of_shape_operator
    (r : ℝ × ℝ → Space) (p : ℝ × ℝ) (n : Space)
    (hsmooth : ContDiffAt ℝ 2 r p)
    (hn : ‖n‖ = 1) (hnu : inner ℝ n (ru r p) = 0) (hnv : inner ℝ n (rv r p) = 0)
    (hreg : 0 < formE r p * formG r p - formF r p ^ 2) :
    ∃ (κ₁ κ₂ : ℝ) (u₁ u₂ : Fin 2 → ℝ),
      κ₂ ≤ κ₁ ∧
      u₁ ⬝ᵥ (firstForm r p *ᵥ u₁) = 1 ∧ u₂ ⬝ᵥ (firstForm r p *ᵥ u₂) = 1 ∧
      u₁ ⬝ᵥ (firstForm r p *ᵥ u₂) = 0 ∧
      shapeOperator r n p *ᵥ u₁ = κ₁ • u₁ ∧ shapeOperator r n p *ᵥ u₂ = κ₂ • u₂ ∧
      (∀ (μ : ℝ) (v : Fin 2 → ℝ), v ≠ 0 → shapeOperator r n p *ᵥ v = μ • v →
        μ = κ₁ ∨ μ = κ₂) ∧
      (∀ θ : ℝ, normalCurvature r n p (cos θ • u₁ + sin θ • u₂) =
        κ₁ * cos θ ^ 2 + κ₂ * sin θ ^ 2) ∧
      (∀ t : Fin 2 → ℝ, t ≠ 0 →
        κ₂ ≤ normalCurvature r n p t ∧ normalCurvature r n p t ≤ κ₁) ∧
      κ₁ * κ₂ = gaussianCurvature r n p ∧
      (κ₁ + κ₂) / 2 = meanCurvature r n p := by
  have h0 : 0 ≤ formE r p := real_inner_self_nonneg
  have hE : 0 < formE r p := by
    rcases h0.lt_or_eq with h | h
    · exact h
    · exfalso; rw [← h] at hreg; nlinarith [sq_nonneg (formF r p)]
  exact main_lin _ _ _ _ _ _ hE hreg

/-- **Turning the normal over.** Replacing the normal `n` by `−n` turns the shape operator to
`−W`, so both principal curvatures change sign and the mean curvature `H` changes sign, while
the Gaussian curvature `K`, a product of two signs, stays the same. -/
theorem flip_normal_negates_mean_keeps_gaussian
    (r : ℝ × ℝ → Space) (p : ℝ × ℝ) (n : Space) :
    shapeOperator r (-n) p = -shapeOperator r n p ∧
    gaussianCurvature r (-n) p = gaussianCurvature r n p ∧
    meanCurvature r (-n) p = -meanCurvature r n p := by
  have hII : secondForm r (-n) p = -secondForm r n p := by
    ext i j; fin_cases i <;> fin_cases j <;>
      simp [secondForm, formL, formM, formN, inner_neg_right]
  refine ⟨?_, ?_, ?_⟩
  · rw [shapeOperator, shapeOperator, hII, Matrix.mul_neg]
  · simp only [gaussianCurvature, formL, formM, formN, inner_neg_right]
    ring
  · simp only [meanCurvature, formL, formM, formN, inner_neg_right]
    ring

/-- **At an umbilic every heading is principal.** Under the same hypotheses, if the shape
operator has only one eigenvalue `κ` (so `κ₁ = κ₂ = κ`, an umbilic, like every point of the
dome), then every plan step is an eigenvector of `W` with eigenvalue `κ` and the bending rate is
`κ` on every heading: there is no pair of principal axes to pick. -/
theorem umbilic_every_heading_principal
    (r : ℝ × ℝ → Space) (p : ℝ × ℝ) (n : Space)
    (hsmooth : ContDiffAt ℝ 2 r p)
    (hn : ‖n‖ = 1) (hnu : inner ℝ n (ru r p) = 0) (hnv : inner ℝ n (rv r p) = 0)
    (hreg : 0 < formE r p * formG r p - formF r p ^ 2) (κ : ℝ)
    (humb : ∀ (μ : ℝ) (v : Fin 2 → ℝ), v ≠ 0 → shapeOperator r n p *ᵥ v = μ • v → μ = κ) :
    ∀ t : Fin 2 → ℝ, t ≠ 0 →
      shapeOperator r n p *ᵥ t = κ • t ∧ normalCurvature r n p t = κ := by
  have h0 : 0 ≤ formE r p := real_inner_self_nonneg
  have hE : 0 < formE r p := by
    rcases h0.lt_or_eq with h | h
    · exact h
    · exfalso; rw [← h] at hreg; nlinarith [sq_nonneg (formF r p)]
  exact umb_lin _ _ _ _ _ _ hE hreg κ humb

/-! ### The card's worked numbers, exactly

The lamp fixing P = (30, 20) on the saddle `z = 30 + (x² − y²)/120`, with slopes
`p = 1/2`, `q = −1/3` and second derivatives `1/60`, `−1/60`. -/

-- First form at P: E = 1 + p² = 5/4 (1.250000), F = pq = −1/6, G = 1 + q² = 10/9 (1.111111).
example : (1 : ℚ) + (1 / 2) ^ 2 = 5 / 4 ∧ (1 / 2 : ℚ) * (-1 / 3) = -1 / 6 ∧
    (1 : ℚ) + (-1 / 3) ^ 2 = 10 / 9 := by norm_num
-- EG − F² = 1 + p² + q² = 49/36 (1.361111), whose root is 7/6 (1.166667).
example : (5 / 4 : ℚ) * (10 / 9) - (-1 / 6) ^ 2 = 49 / 36 ∧
    (1 : ℚ) + (1 / 2) ^ 2 + (-1 / 3) ^ 2 = 49 / 36 ∧ (7 / 6 : ℚ) ^ 2 = 49 / 36 := by norm_num
-- Second form at P: L = (1/60)/(7/6) = 1/70 (0.014285714), M = 0, N = −1/70.
example : (1 / 60 : ℚ) / (7 / 6) = 1 / 70 := by norm_num
-- K = (LN − M²)/(EG − F²) = −9/60025 (−0.000149937526 per m²).
example : ((1 / 70 : ℚ) * (-1 / 70) - 0 ^ 2) / (49 / 36) = -9 / 60025 := by norm_num
-- H = (EN − 2FM + GL)/(2(EG − F²)) = −1/1372 (−0.000728863 per m).
example : ((5 / 4 : ℚ) * (-1 / 70) - 2 * (-1 / 6) * 0 + 10 / 9 * (1 / 70)) / (2 * (49 / 36)) =
    -1 / 1372 := by norm_num
-- W = I⁻¹ II has rows (4/343, −3/1715) and (3/1715, −9/686), that is
-- (0.011661808, −0.001749271) and (0.001749271, −0.013119534): I W = II.
example : !![(5 / 4 : ℚ), -1 / 6; -1 / 6, 10 / 9] * !![4 / 343, -3 / 1715; 3 / 1715, -9 / 686] =
    !![1 / 70, 0; 0, -1 / 70] := by
  ext i j; fin_cases i <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_two]
-- trace W = −1/686 = 2H and det W = −9/60025 = K.
example : (4 / 343 : ℚ) + (-9 / 686) = 2 * (-1 / 1372) ∧
    (4 / 343 : ℚ) * (-9 / 686) - (-3 / 1715) * (3 / 1715) = -9 / 60025 := by norm_num
-- The roof-square frame matrix S at P: s11 = 2/175 (0.011428571), s22 = −221/17150
-- (−0.012886297), s12 = 2/1225 (0.001632653); same trace 2H and determinant K as W.
example : (2 / 175 : ℚ) + (-221 / 17150) = 2 * (-1 / 1372) ∧
    (2 / 175 : ℚ) * (-221 / 17150) - (2 / 1225) ^ 2 = -9 / 60025 := by norm_num
-- tan 2θ₁ = 2 s12 / (s11 − s22) = 56/417 (0.134293).
example : 2 * (2 / 1225 : ℚ) / (2 / 175 - (-221 / 17150)) = 56 / 417 := by norm_num
-- Turning n over at P: H becomes +1/1372 (0.000728863); K stays −9/60025.
example : ((5 / 4 : ℚ) * (1 / 70) - 2 * (-1 / 6) * 0 + 10 / 9 * (-1 / 70)) / (2 * (49 / 36)) =
    1 / 1372 ∧ ((-1 / 70 : ℚ) * (1 / 70) - 0 ^ 2) / (49 / 36) = -9 / 60025 := by norm_num
-- The saddle's centre O: E = G = 1, F = 0, L = 1/60, N = −1/60, so K = −1/3600
-- (−0.000277778 per m²) and H = 0.
example : ((1 / 60 : ℚ) * (-1 / 60) - 0 ^ 2) / (1 * 1 - 0 ^ 2) = -1 / 3600 ∧
    ((1 : ℚ) * (-1 / 60) - 2 * 0 * 0 + 1 * (1 / 60)) / (2 * (1 * 1 - 0 ^ 2)) = 0 := by norm_num
-- The dome, a sphere of radius 60 m with n up: κ₁ = κ₂ = −1/60, so K = 1/3600
-- (+0.000277778 per m²) and H = −1/60 (−0.016667 per m).
example : (-1 / 60 : ℚ) * (-1 / 60) = 1 / 3600 ∧ ((-1 / 60 : ℚ) + (-1 / 60)) / 2 = -1 / 60 := by
  norm_num
-- Wrong road 1: eigenvalues of II alone give K = LN = −1/4900 (−0.000204081633),
-- off by the factor EG − F² = 49/36.
example : (1 / 70 : ℚ) * (-1 / 70) = -1 / 4900 ∧ (-1 / 4900 : ℚ) / (-9 / 60025) = 49 / 36 := by
  norm_num
-- Wrong road 3: east and north as principal give L/E = 2/175 and N/G = −9/700, so
-- K = −9/61250 (−0.000146938776) and H = −1/1400 (−0.000714286).
example : (1 / 70 : ℚ) / (5 / 4) = 2 / 175 ∧ (-1 / 70 : ℚ) / (10 / 9) = -9 / 700 ∧
    (2 / 175 : ℚ) * (-9 / 700) = -9 / 61250 ∧ ((2 / 175 : ℚ) + (-9 / 700)) / 2 = -1 / 1400 := by
  norm_num
-- The vault, copper rolled to radius 20 m: principal curvatures −1/20 and 0, so K = 0 and
-- H = −1/40 (−0.025 per m); the flat sheet has K = 0 and H = 0.
example : (-1 / 20 : ℚ) * 0 = 0 ∧ ((-1 / 20 : ℚ) + 0) / 2 = -1 / 40 := by norm_num

#print axioms sym2_eigen
#print axioms sym2_char
#print axioms quad_nonneg
#print axioms sym2_rayleigh
#print axioms spec_data
#print axioms dot_self_pos
#print axioms main_lin
#print axioms umb_lin
#print axioms principal_curvatures_are_eigenvalues_of_shape_operator
#print axioms flip_normal_negates_mean_keeps_gaussian
#print axioms umbilic_every_heading_principal
