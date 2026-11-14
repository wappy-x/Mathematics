-- The LQR: if P is a symmetric solution of the algebraic Riccati equation and the push price R is positive definite, every push history that brings the state to rest pays at least x₀ᵀPx₀, and the feedback u = -Kx with K = R⁻¹BᵀP pays exactly that.
import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.MeasureTheory.Integral.IntegralEqImproper
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open Matrix Filter Topology MeasureTheory

lemma lqr_dot_mulVec_eq {a b : ℕ} (M : Matrix (Fin a) (Fin b) ℝ) (x : Fin a → ℝ) (y : Fin b → ℝ) :
    x ⬝ᵥ (M *ᵥ y) = (Mᵀ *ᵥ x) ⬝ᵥ y := by
  rw [dotProduct_mulVec, mulVec_transpose]

lemma lqr_split_aux {n m : ℕ}
    (A Q P : Matrix (Fin n) (Fin n) ℝ) (B : Matrix (Fin n) (Fin m) ℝ) (R : Matrix (Fin m) (Fin m) ℝ)
    (hR : R.PosDef) (hP : P.IsSymm)
    (hric : Aᵀ * P + P * A - P * B * R⁻¹ * Bᵀ * P + Q = 0)
    (x : Fin n → ℝ) (u : Fin m → ℝ) :
    x ⬝ᵥ (Q *ᵥ x) + u ⬝ᵥ (R *ᵥ u)
      = -(2 * (x ⬝ᵥ (P *ᵥ (A *ᵥ x + B *ᵥ u))))
        + (u + (R⁻¹ * Bᵀ * P) *ᵥ x) ⬝ᵥ (R *ᵥ (u + (R⁻¹ * Bᵀ * P) *ᵥ x)) := by
  have hRu : IsUnit R.det := (Matrix.isUnit_iff_isUnit_det R).mp hR.isUnit
  have hRT : Rᵀ = R := by
    have h := hR.isHermitian
    rwa [IsHermitian, conjTranspose_eq_transpose_of_trivial] at h
  have hPT : Pᵀ = P := hP
  have hQ' : Q = P * B * R⁻¹ * Bᵀ * P - Aᵀ * P - P * A := by
    rw [← sub_eq_zero, ← hric]; abel
  set K := R⁻¹ * Bᵀ * P with hK
  have hRK : R * K = Bᵀ * P := by
    simp only [K, ← Matrix.mul_assoc, Matrix.mul_nonsing_inv _ hRu, Matrix.one_mul]
  have e2 : u ⬝ᵥ (R *ᵥ (K *ᵥ x)) = x ⬝ᵥ (P *ᵥ (B *ᵥ u)) := by
    rw [mulVec_mulVec, hRK, ← mulVec_mulVec, lqr_dot_mulVec_eq Bᵀ, transpose_transpose,
      lqr_dot_mulVec_eq P x, hPT, dotProduct_comm]
  have e1 : (K *ᵥ x) ⬝ᵥ (R *ᵥ u) = x ⬝ᵥ (P *ᵥ (B *ᵥ u)) := by
    rw [lqr_dot_mulVec_eq, hRT, dotProduct_comm, e2]
  have e3 : (K *ᵥ x) ⬝ᵥ (R *ᵥ (K *ᵥ x)) = x ⬝ᵥ ((P * B * R⁻¹ * Bᵀ * P) *ᵥ x) := by
    rw [mulVec_mulVec x R K, hRK, lqr_dot_mulVec_eq, transpose_mul, hPT, transpose_transpose,
      mulVec_mulVec, dotProduct_comm, hK]
    simp only [Matrix.mul_assoc]
  have e4 : x ⬝ᵥ ((Aᵀ * P) *ᵥ x) = x ⬝ᵥ (P *ᵥ (A *ᵥ x)) := by
    rw [← mulVec_mulVec, lqr_dot_mulVec_eq, transpose_transpose, dotProduct_comm,
      lqr_dot_mulVec_eq P x, hPT]
  have e5 : x ⬝ᵥ ((P * A) *ᵥ x) = x ⬝ᵥ (P *ᵥ (A *ᵥ x)) := by rw [mulVec_mulVec]
  rw [hQ']
  simp only [sub_mulVec, dotProduct_sub, mulVec_add, dotProduct_add, add_dotProduct, e1, e2, e3,
    e4, e5]
  ring

lemma lqr_quad_hasDerivWithinAt {n : ℕ} (P : Matrix (Fin n) (Fin n) ℝ) (hP : P.IsSymm)
    {x : ℝ → Fin n → ℝ} {x' : Fin n → ℝ} {s : Set ℝ} {t : ℝ} (h : HasDerivWithinAt x x' s t) :
    HasDerivWithinAt (fun t => x t ⬝ᵥ (P *ᵥ x t)) (2 * (x t ⬝ᵥ (P *ᵥ x'))) s t := by
  have hc : ∀ i, HasDerivWithinAt (fun t => x t i) (x' i) s t := fun i => hasDerivWithinAt_pi.1 h i
  have hPx : ∀ i, HasDerivWithinAt (fun t => (P *ᵥ x t) i) ((P *ᵥ x') i) s t := by
    intro i
    simp only [mulVec, dotProduct]
    exact HasDerivWithinAt.fun_sum (fun j _ => (hc j).const_mul (P i j))
  have := HasDerivWithinAt.fun_sum (u := Finset.univ) (fun i _ => (hc i).mul (hPx i))
  convert this using 1
  · funext r; rfl
  have hPT : Pᵀ = P := hP
  have : x' ⬝ᵥ (P *ᵥ x t) = x t ⬝ᵥ (P *ᵥ x') := by
    rw [lqr_dot_mulVec_eq, hPT, dotProduct_comm]
  rw [Finset.sum_add_distrib]
  change _ = x' ⬝ᵥ (P *ᵥ x t) + x t ⬝ᵥ (P *ᵥ x')
  rw [this]; ring

lemma lqr_quad_form_nonneg {k : ℕ} (M : Matrix (Fin k) (Fin k) ℝ) (hM : M.PosSemidef)
    (v : Fin k → ℝ) : 0 ≤ v ⬝ᵥ (M *ᵥ v) := by
  simpa using hM.dotProduct_mulVec_nonneg v

#print axioms lqr_dot_mulVec_eq
#print axioms lqr_split_aux
#print axioms lqr_quad_hasDerivWithinAt
#print axioms lqr_quad_form_nonneg


/-- The LQR theorem, proved on the card by completing the square.
Plant x' = Ax + Bu with n states and m pushes; the bill is the integral over all time of
xᵀQx + uᵀRu, with state prices Q (weighted squares, never negative) and a positive price R on
the push. Let P be a symmetric solution of the algebraic Riccati equation
AᵀP + PA - PBR⁻¹BᵀP + Q = 0 and let K = R⁻¹BᵀP. Then, from a start x₀:
(1) every push history u that brings the state to rest, with a finite bill, pays at least x₀ᵀPx₀;
(2) the feedback u = -Kx, when its loop brings the state to rest, pays exactly x₀ᵀPx₀.
So the cheapest bill is x₀ᵀPx₀ and it is paid by u = -Kx. -/
theorem lqr_feedback_pays_the_cheapest_bill {n m : ℕ}
    (A Q P : Matrix (Fin n) (Fin n) ℝ) (B : Matrix (Fin n) (Fin m) ℝ) (R : Matrix (Fin m) (Fin m) ℝ)
    (hQ : Q.PosSemidef) (hR : R.PosDef) (hP : P.IsSymm)
    (hric : Aᵀ * P + P * A - P * B * R⁻¹ * Bᵀ * P + Q = 0) (x₀ : Fin n → ℝ) :
    (∀ (x : ℝ → Fin n → ℝ) (u : ℝ → Fin m → ℝ),
        x 0 = x₀ →
        (∀ t, 0 ≤ t → HasDerivWithinAt x (A *ᵥ x t + B *ᵥ u t) (Set.Ici 0) t) →
        Tendsto x atTop (𝓝 0) →
        IntegrableOn (fun t => x t ⬝ᵥ (Q *ᵥ x t) + u t ⬝ᵥ (R *ᵥ u t)) (Set.Ioi 0) →
        x₀ ⬝ᵥ (P *ᵥ x₀) ≤ ∫ t in Set.Ioi 0, (x t ⬝ᵥ (Q *ᵥ x t) + u t ⬝ᵥ (R *ᵥ u t))) ∧
    (∀ y : ℝ → Fin n → ℝ,
        y 0 = x₀ →
        (∀ t, 0 ≤ t →
          HasDerivWithinAt y (A *ᵥ y t + B *ᵥ (-((R⁻¹ * Bᵀ * P) *ᵥ y t))) (Set.Ici 0) t) →
        Tendsto y atTop (𝓝 0) →
        ∫ t in Set.Ioi 0, (y t ⬝ᵥ (Q *ᵥ y t) +
            (-((R⁻¹ * Bᵀ * P) *ᵥ y t)) ⬝ᵥ (R *ᵥ (-((R⁻¹ * Bᵀ * P) *ᵥ y t))))
          = x₀ ⬝ᵥ (P *ᵥ x₀)) := by
  have hφ : Continuous (fun v : Fin n → ℝ => v ⬝ᵥ (P *ᵥ v)) := by fun_prop
  have hV0 : ∀ z : ℝ → Fin n → ℝ, Tendsto z atTop (𝓝 0) →
      Tendsto (fun t => -(z t ⬝ᵥ (P *ᵥ z t))) atTop (𝓝 0) := by
    intro z hz
    have := (hφ.tendsto 0).comp hz
    simpa using this.neg
  refine ⟨?_, ?_⟩
  · intro x u hx0 hder hlim hint
    have hW : ∀ t, 0 ≤ t → HasDerivWithinAt (fun t => -(x t ⬝ᵥ (P *ᵥ x t)))
        (-(2 * (x t ⬝ᵥ (P *ᵥ (A *ᵥ x t + B *ᵥ u t))))) (Set.Ici 0) t :=
      fun t ht => (lqr_quad_hasDerivWithinAt P hP (hder t ht)).neg
    have hle : ∀ T, 0 ≤ T → -(x T ⬝ᵥ (P *ᵥ x T)) - -(x 0 ⬝ᵥ (P *ᵥ x 0)) ≤
        ∫ t in (0:ℝ)..T, (x t ⬝ᵥ (Q *ᵥ x t) + u t ⬝ᵥ (R *ᵥ u t)) := by
      intro T hT
      refine intervalIntegral.sub_le_integral_of_hasDeriv_right_of_le
        (g := fun t => -(x t ⬝ᵥ (P *ᵥ x t)))
        (g' := fun t => -(2 * (x t ⬝ᵥ (P *ᵥ (A *ᵥ x t + B *ᵥ u t)))))
        (φ := fun t => x t ⬝ᵥ (Q *ᵥ x t) + u t ⬝ᵥ (R *ᵥ u t)) hT ?_ ?_ ?_ ?_
      · intro t ht
        exact ((hW t ht.1).continuousWithinAt).mono Set.Icc_subset_Ici_self
      · intro t ht
        exact (hW t ht.1.le).mono (fun s hs => le_of_lt (lt_trans ht.1 hs))
      · rw [integrableOn_Icc_iff_integrableOn_Ioc]
        exact hint.mono_set Set.Ioc_subset_Ioi_self
      · intro t _
        rw [lqr_split_aux A Q P B R hR hP hric (x t) (u t)]
        have := lqr_quad_form_nonneg R hR.posSemidef (u t + (R⁻¹ * Bᵀ * P) *ᵥ x t)
        linarith
    have h1 : Tendsto (fun T => -(x T ⬝ᵥ (P *ᵥ x T)) - -(x 0 ⬝ᵥ (P *ᵥ x 0))) atTop
        (𝓝 (0 - -(x 0 ⬝ᵥ (P *ᵥ x 0)))) := (hV0 x hlim).sub_const _
    have h2 := intervalIntegral_tendsto_integral_Ioi 0 hint tendsto_id
    have := le_of_tendsto_of_tendsto h1 h2 (eventually_ge_atTop 0 |>.mono hle)
    rw [hx0] at this
    simpa using this
  · intro y hy0 hder hlim
    have hW : ∀ t, 0 ≤ t → HasDerivWithinAt (fun t => -(y t ⬝ᵥ (P *ᵥ y t)))
        (y t ⬝ᵥ (Q *ᵥ y t) +
            (-((R⁻¹ * Bᵀ * P) *ᵥ y t)) ⬝ᵥ (R *ᵥ (-((R⁻¹ * Bᵀ * P) *ᵥ y t)))) (Set.Ici 0) t := by
      intro t ht
      have := (lqr_quad_hasDerivWithinAt P hP (hder t ht)).neg
      convert this using 1
      rw [lqr_split_aux A Q P B R hR hP hric (y t)]
      simp
    have key := integral_Ioi_of_hasDerivAt_of_nonneg (a := (0:ℝ)) (l := 0)
      ((hW 0 le_rfl).continuousWithinAt)
      (fun t ht => (hW t (le_of_lt ht)).hasDerivAt (Ici_mem_nhds ht))
      (fun t _ => add_nonneg (lqr_quad_form_nonneg Q hQ _)
        (lqr_quad_form_nonneg R hR.posSemidef _))
      (hV0 y hlim)
    rw [key, hy0]
    ring

/-- Step 2's split of the running price, which is the whole proof in one line.
With P symmetric and solving the Riccati equation, R positive definite and K = R⁻¹BᵀP, for every
state x and push u: xᵀQx + uᵀRu = -(the rate of change of xᵀPx along x' = Ax + Bu)
+ (u + Kx)ᵀR(u + Kx), where that rate is 2xᵀP(Ax + Bu). -/
theorem lqr_running_price_split {n m : ℕ}
    (A Q P : Matrix (Fin n) (Fin n) ℝ) (B : Matrix (Fin n) (Fin m) ℝ) (R : Matrix (Fin m) (Fin m) ℝ)
    (hR : R.PosDef) (hP : P.IsSymm)
    (hric : Aᵀ * P + P * A - P * B * R⁻¹ * Bᵀ * P + Q = 0)
    (x : Fin n → ℝ) (u : Fin m → ℝ) :
    x ⬝ᵥ (Q *ᵥ x) + u ⬝ᵥ (R *ᵥ u)
      = -(2 * (x ⬝ᵥ (P *ᵥ (A *ᵥ x + B *ᵥ u))))
        + (u + (R⁻¹ * Bᵀ * P) *ᵥ x) ⬝ᵥ (R *ᵥ (u + (R⁻¹ * Bᵀ * P) *ᵥ x)) := by
  exact lqr_split_aux A Q P B R hR hP hric x u

/-- Step 6: only the ratios of the prices matter. Multiply every price (Q and R) by the same
positive number c: then cP solves the new Riccati equation, and the gain R⁻¹BᵀP does not move. -/
theorem lqr_gain_unchanged_when_all_prices_scale {n m : ℕ}
    (A Q P : Matrix (Fin n) (Fin n) ℝ) (B : Matrix (Fin n) (Fin m) ℝ) (R : Matrix (Fin m) (Fin m) ℝ)
    (hR : R.PosDef) (hric : Aᵀ * P + P * A - P * B * R⁻¹ * Bᵀ * P + Q = 0)
    (c : ℝ) (hc : 0 < c) :
    Aᵀ * (c • P) + (c • P) * A - (c • P) * B * (c • R)⁻¹ * Bᵀ * (c • P) + c • Q = 0 ∧
    (c • R)⁻¹ * Bᵀ * (c • P) = R⁻¹ * Bᵀ * P := by
  have hRu : IsUnit R.det := (Matrix.isUnit_iff_isUnit_det R).mp hR.isUnit
  have hinv : (c • R)⁻¹ = c⁻¹ • R⁻¹ := by
    have := invertibleOfNonzero hc.ne'
    rw [Matrix.inv_smul R c hRu, invOf_eq_inv]
  have hcc : c⁻¹ * c = 1 := inv_mul_cancel₀ hc.ne'
  have hcc' : c * c⁻¹ = 1 := mul_inv_cancel₀ hc.ne'
  rw [hinv]
  refine ⟨?_, ?_⟩
  · simp only [Matrix.mul_smul, Matrix.smul_mul, smul_smul]
    rw [hcc, mul_one]
    rw [← smul_add, ← smul_sub, ← smul_add, hric, smul_zero]
  · simp only [Matrix.mul_smul, Matrix.smul_mul, smul_smul, hcc', one_smul]

-- Bryson's rule on the card's limits 0.5 m, 0.1 rad and 5 m/s²: prices 4, 100 and 1/25.
example : (1 : ℚ) / (1 / 2) ^ 2 = 4 := by norm_num
example : (1 : ℚ) / (1 / 10) ^ 2 = 100 := by norm_num
example : (1 : ℚ) / 5 ^ 2 = 1 / 25 := by norm_num

-- Corollary one: the cart gain is -√(q_p / r) = -√(4 / (1/25)) = -√100 = -10.
example : -Real.sqrt (4 / (1 / 25)) = -10 := by
  rw [show (4 : ℝ) / (1 / 25) = 10 ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]

-- Step 4: pole placement with all four poles at -2 gives s⁴ + 8s³ + 24s² + 32s + 16.
example (s : ℝ) : (s + 2) ^ 4 = s ^ 4 + 8 * s ^ 3 + 24 * s ^ 2 + 32 * s + 16 := by ring

-- Every price times ten keeps the ratios: 40 / 0.4 = 4 / 0.04 = 100 and 1000 / 0.4 = 100 / 0.04.
example : (40 : ℚ) / (4 / 10) = 4 / (4 / 100) ∧ (1000 : ℚ) / (4 / 10) = 100 / (4 / 100) := by norm_num

#print axioms lqr_feedback_pays_the_cheapest_bill
#print axioms lqr_running_price_split
#print axioms lqr_gain_unchanged_when_all_prices_scale
