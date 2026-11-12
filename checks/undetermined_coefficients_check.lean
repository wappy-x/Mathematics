-- Undetermined coefficients: for y'' + c y' + k y = e^(μt) P(t) with constant c, k, a trial t^s e^(μt) Q(t), Q no higher in degree than P and s the number of times μ is a characteristic root, always contains a solution.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.Calculus.Deriv.Polynomial
import Mathlib.Algebra.Polynomial.Div
import Mathlib.Algebra.Polynomial.RingDivision
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic

open Polynomial

theorem uc_Xpow_mul_le (s m : ℕ) (p : ℂ[X]) (hp : p.natDegree ≤ m) :
    (X ^ s * p).natDegree ≤ m + s := by
  refine (natDegree_mul_le).trans ?_
  have := natDegree_X_pow_le (R := ℂ) s
  omega

#print axioms uc_Xpow_mul_le

theorem uc_deriv_le (p : ℂ[X]) (m : ℕ) (hp : p.natDegree ≤ m + 1) :
    (derivative p).natDegree ≤ m :=
  (natDegree_derivative_le p).trans (by omega)

#print axioms uc_deriv_le

theorem uc_surj (L : ℂ[X] → ℂ[X]) (hadd : ∀ p q, L (p + q) = L p + L q)
    (hsmul : ∀ (c : ℂ) p, L (C c * p) = C c * L p)
    (hdeg : ∀ (m : ℕ) p, p.natDegree ≤ m → (L p).natDegree ≤ m)
    (hlead : ∀ m : ℕ, (L (X ^ m)).coeff m ≠ 0) :
    ∀ n : ℕ, ∀ P : ℂ[X], P.natDegree ≤ n → ∃ Q : ℂ[X], Q.natDegree ≤ n ∧ L Q = P := by
  intro n
  induction n with
  | zero =>
    intro P hP
    refine ⟨C (P.coeff 0 / (L (X ^ 0)).coeff 0), ?_, ?_⟩
    · simp
    · rw [← mul_one (C _), ← pow_zero X, hsmul]
      have h1 := hdeg 0 (X ^ 0) (by simp)
      have h2 : L (X ^ 0) = C ((L (X ^ 0)).coeff 0) := eq_C_of_natDegree_le_zero h1
      conv_lhs => arg 2; rw [h2]
      rw [← C_mul, div_mul_cancel₀ _ (hlead 0)]
      exact (eq_C_of_natDegree_le_zero hP).symm
  | succ n ih =>
    intro P hP
    set e := (L (X ^ (n + 1))).coeff (n + 1)
    set Q0 := C (P.coeff (n + 1) / e) * X ^ (n + 1)
    have hE : (P - L Q0).natDegree ≤ n := by
      rw [natDegree_le_iff_coeff_eq_zero]
      intro N hN
      have hL : (L Q0).natDegree ≤ n + 1 := hdeg _ _ (by
        simp only [Q0]
        exact (natDegree_C_mul_le _ _).trans (by simp))
      rcases Nat.lt_or_ge (n + 1) N with h | h
      · rw [coeff_sub, coeff_eq_zero_of_natDegree_lt (lt_of_le_of_lt hP h),
          coeff_eq_zero_of_natDegree_lt (lt_of_le_of_lt hL h)]
        simp
      · have : N = n + 1 := by omega
        subst this
        have he : e ≠ 0 := hlead (n + 1)
        simp only [Q0, coeff_sub, hsmul, coeff_C_mul]
        rw [div_mul_cancel₀ _ he, sub_self]
    obtain ⟨Q1, hQ1, hLQ1⟩ := ih _ hE
    refine ⟨Q0 + Q1, ?_, ?_⟩
    · refine (natDegree_add_le _ _).trans (max_le ?_ (hQ1.trans (Nat.le_succ n)))
      exact (natDegree_C_mul_le _ _).trans (by simp)
    · rw [hadd, hLQ1]; ring

#print axioms uc_surj

theorem uc_alg (a b : ℂ) (s : ℕ)
    (h : (s = 0 ∧ a ≠ 0) ∨ (s = 1 ∧ a = 0 ∧ b ≠ 0) ∨ (s = 2 ∧ a = 0 ∧ b = 0)) (P : ℂ[X]) :
    ∃ Q : ℂ[X], Q.natDegree ≤ P.natDegree ∧
      C a * (X ^ s * Q) + C b * derivative (X ^ s * Q) + derivative (derivative (X ^ s * Q))
        = P := by
  have hadd : ∀ p q : ℂ[X],
      C a * (X ^ s * (p + q)) + C b * derivative (X ^ s * (p + q))
        + derivative (derivative (X ^ s * (p + q)))
      = (C a * (X ^ s * p) + C b * derivative (X ^ s * p) + derivative (derivative (X ^ s * p)))
        + (C a * (X ^ s * q) + C b * derivative (X ^ s * q)
          + derivative (derivative (X ^ s * q))) := by
    intro p q
    simp only [mul_add, derivative_add]
    ring
  have hsmul : ∀ (c : ℂ) (p : ℂ[X]),
      C a * (X ^ s * (C c * p)) + C b * derivative (X ^ s * (C c * p))
        + derivative (derivative (X ^ s * (C c * p)))
      = C c * (C a * (X ^ s * p) + C b * derivative (X ^ s * p)
        + derivative (derivative (X ^ s * p))) := by
    intro c p
    simp only [mul_left_comm (X ^ s) (C c), derivative_C_mul]
    ring
  rcases h with ⟨rfl, ha⟩ | ⟨rfl, rfl, hb⟩ | ⟨rfl, rfl, rfl⟩
  · refine uc_surj _ hadd hsmul ?_ ?_ _ P le_rfl
    · intro m p hp
      have h0 := uc_Xpow_mul_le 0 m p hp
      have h1 := uc_deriv_le (X ^ 0 * p) m (by omega)
      have h2 := uc_deriv_le (derivative (X ^ 0 * p)) m (by omega)
      refine natDegree_add_le_of_degree_le (natDegree_add_le_of_degree_le ?_ ?_) h2
      · exact (natDegree_C_mul_le _ _).trans (by omega)
      · exact (natDegree_C_mul_le _ _).trans h1
    · intro m
      have h1 : m + 1 ≠ m := by omega
      have h2 : m + 1 + 1 ≠ m := by omega
      simp only [pow_zero, one_mul, coeff_add, coeff_C_mul, coeff_derivative, coeff_X_pow, h1, h2,
        ite_false, ite_true]
      simpa using ha
  · refine uc_surj _ hadd hsmul ?_ ?_ _ P le_rfl
    · intro m p hp
      have h0 := uc_Xpow_mul_le 1 m p hp
      have h1 := uc_deriv_le (X ^ 1 * p) m h0
      have h2 := uc_deriv_le (derivative (X ^ 1 * p)) m (by omega)
      refine natDegree_add_le_of_degree_le (natDegree_add_le_of_degree_le ?_ ?_) h2
      · simp
      · exact (natDegree_C_mul_le _ _).trans h1
    · intro m
      have e : (X ^ 1 * X ^ m : ℂ[X]) = X ^ (m + 1) := by ring
      have h2 : m + 1 + 1 ≠ m + 1 := by omega
      rw [e]
      simp only [coeff_add, coeff_C_mul, coeff_derivative, coeff_X_pow, h2, ite_false, ite_true]
      have : (m : ℂ) + 1 ≠ 0 := by exact_mod_cast Nat.succ_ne_zero m
      simpa using And.intro hb this
  · refine uc_surj _ hadd hsmul ?_ ?_ _ P le_rfl
    · intro m p hp
      have h0 := uc_Xpow_mul_le 2 m p hp
      have h1 := uc_deriv_le (X ^ 2 * p) (m + 1) (by omega)
      have h2 := uc_deriv_le (derivative (X ^ 2 * p)) m h1
      simpa using h2
    · intro m
      have e : (X ^ 2 * X ^ m : ℂ[X]) = X ^ (m + 1 + 1) := by ring
      rw [e]
      simp only [coeff_add, coeff_C_mul, coeff_derivative, coeff_X_pow, ite_true]
      have : ((m + 1 + 1 : ℕ) : ℂ) * ((m + 1 : ℕ) : ℂ) ≠ 0 := by
        exact_mod_cast Nat.mul_ne_zero (Nat.succ_ne_zero (m + 1)) (Nat.succ_ne_zero m)
      push_cast at this
      simpa using this

#print axioms uc_alg

theorem uc_cases (c k : ℝ) (μ : ℂ) :
    let s := (X ^ 2 + C (c : ℂ) * X + C (k : ℂ)).rootMultiplicity μ
    (s = 0 ∧ μ ^ 2 + c * μ + k ≠ 0) ∨ (s = 1 ∧ μ ^ 2 + c * μ + k = 0 ∧ 2 * μ + c ≠ 0) ∨
      (s = 2 ∧ μ ^ 2 + c * μ + k = 0 ∧ 2 * μ + c = 0) := by
  intro s
  classical
  by_cases ha : (μ ^ 2 + c * μ + k : ℂ) = 0
  · have hk : (k : ℂ) = -(μ ^ 2) - c * μ := by linear_combination ha
    have hp : (X ^ 2 + C (c : ℂ) * X + C (k : ℂ)) = (X - C μ) * (X - C (-(c : ℂ) - μ)) := by
      rw [hk]
      simp only [map_sub, map_neg, map_pow, map_mul]
      ring
    have hne : (X - C μ) * (X - C (-(c : ℂ) - μ)) ≠ 0 :=
      mul_ne_zero (X_sub_C_ne_zero _) (X_sub_C_ne_zero _)
    have hs : s = 1 + if μ = -(c : ℂ) - μ then 1 else 0 := by
      simp only [s]
      rw [hp, rootMultiplicity_mul hne, rootMultiplicity_X_sub_C_self, rootMultiplicity_X_sub_C]
    by_cases hb : (2 * μ + c : ℂ) = 0
    · right; right
      have : μ = -(c : ℂ) - μ := by linear_combination hb
      refine ⟨?_, ha, hb⟩
      rw [hs, if_pos this]
    · right; left
      have : μ ≠ -(c : ℂ) - μ := by
        intro h; apply hb; linear_combination h
      refine ⟨?_, ha, hb⟩
      rw [hs, if_neg this]
  · left
    refine ⟨rootMultiplicity_eq_zero ?_, ha⟩
    intro h
    apply ha
    simpa [IsRoot.def, eval_add, eval_mul, eval_pow] using h

#print axioms uc_cases

theorem uc_hasDeriv (μ : ℂ) (R : ℂ[X]) (t : ℝ) :
    HasDerivAt (fun u : ℝ => Complex.exp (μ * u) * R.eval (u : ℂ))
      (Complex.exp (μ * t) * (C μ * R + derivative R).eval (t : ℂ)) t := by
  have h1 : HasDerivAt (fun u : ℝ => μ * (u : ℂ)) μ t := by
    simpa using ((hasDerivAt_id t).ofReal_comp).const_mul μ
  have h2 := h1.cexp
  have h3 : HasDerivAt (fun u : ℝ => R.eval (u : ℂ)) (R.derivative.eval (t : ℂ)) t :=
    (R.hasDerivAt (t : ℂ)).comp_ofReal
  convert h2.mul h3 using 1
  simp only [eval_add, eval_mul, eval_C]
  ring

#print axioms uc_hasDeriv

theorem uc_deriv_eq (μ : ℂ) (R : ℂ[X]) :
    deriv (fun u : ℝ => Complex.exp (μ * u) * R.eval (u : ℂ))
      = fun u : ℝ => Complex.exp (μ * u) * (C μ * R + derivative R).eval (u : ℂ) :=
  funext fun t => (uc_hasDeriv μ R t).deriv

#print axioms uc_deriv_eq

theorem cs_deriv (a b ω : ℝ) :
    deriv (fun u : ℝ => a * Real.cos (ω * u) + b * Real.sin (ω * u))
      = fun u : ℝ => (ω * b) * Real.cos (ω * u) + (-(ω * a)) * Real.sin (ω * u) := by
  funext t
  have h1 : HasDerivAt (fun u : ℝ => ω * u) ω t := by
    simpa using (hasDerivAt_id t).const_mul ω
  have h2 := ((h1.cos).const_mul a).add ((h1.sin).const_mul b)
  have h3 : HasDerivAt (fun u : ℝ => a * Real.cos (ω * u) + b * Real.sin (ω * u)) _ t := h2
  rw [h3.deriv]
  ring

#print axioms cs_deriv

theorem sw_deriv (a0 a1 b0 b1 : ℝ) :
    deriv (fun u : ℝ => Real.exp (-u) *
        ((a0 + a1 * u) * Real.cos (2 * u) + (b0 + b1 * u) * Real.sin (2 * u)))
      = fun u : ℝ => Real.exp (-u) *
        (((-a0 + a1 + 2 * b0) + (-a1 + 2 * b1) * u) * Real.cos (2 * u)
          + ((-b0 + b1 - 2 * a0) + (-b1 - 2 * a1) * u) * Real.sin (2 * u)) := by
  funext t
  have h2 : HasDerivAt (fun u : ℝ => 2 * u) 2 t := by
    simpa using (hasDerivAt_id t).const_mul (2 : ℝ)
  have hn : HasDerivAt (fun u : ℝ => -u) (-1) t := by
    exact hasDerivAt_neg t
  have ha : HasDerivAt (fun u : ℝ => a0 + a1 * u) a1 t := by
    simpa using ((hasDerivAt_id t).const_mul a1).const_add a0
  have hb : HasDerivAt (fun u : ℝ => b0 + b1 * u) b1 t := by
    simpa using ((hasDerivAt_id t).const_mul b1).const_add b0
  have h := (hn.exp).mul ((ha.mul h2.cos).add (hb.mul h2.sin))
  have h' : HasDerivAt (fun u : ℝ => Real.exp (-u) *
      ((a0 + a1 * u) * Real.cos (2 * u) + (b0 + b1 * u) * Real.sin (2 * u))) _ t := h
  rw [h'.deriv]
  simp only [Pi.add_apply, Pi.mul_apply]
  ring

#print axioms sw_deriv

/-- The method: a push e^(μt) P(t), with P a polynomial and μ real or complex (this covers
polynomials, exponentials, sines and cosines, and their products), has a particular solution of
the trial shape t^s e^(μt) Q(t), where Q has degree at most that of P and s is how many times μ
is a root of the characteristic polynomial z^2 + c z + k. -/
theorem undetermined_coefficients_trial_contains_solution (c k : ℝ) (μ : ℂ) (P : ℂ[X]) :
    ∃ Q : ℂ[X], Q.natDegree ≤ P.natDegree ∧
      ∀ t : ℝ,
        let s := (X ^ 2 + C (c : ℂ) * X + C (k : ℂ)).rootMultiplicity μ
        let y : ℝ → ℂ := fun u => (u : ℂ) ^ s * Complex.exp (μ * u) * Q.eval (u : ℂ)
        deriv (deriv y) t + (c : ℂ) * deriv y t + (k : ℂ) * y t
          = Complex.exp (μ * t) * P.eval (t : ℂ) := by
  obtain ⟨Q, hQ, hEq⟩ := uc_alg (μ ^ 2 + c * μ + k) (2 * μ + c) _ (uc_cases c k μ) P
  refine ⟨Q, hQ, fun t => ?_⟩
  intro s y
  have hy : y = fun u : ℝ => Complex.exp (μ * u) * (X ^ s * Q).eval (u : ℂ) := by
    funext u
    simp only [y, eval_mul, eval_pow, eval_X]
    ring
  rw [hy, uc_deriv_eq, uc_deriv_eq, ← hEq]
  simp only [eval_add, eval_mul, eval_C, derivative_add, derivative_C_mul]
  ring

/-- A cosine push F cos ωt (with ω ≠ 0): the trial A cos ωt + B sin ωt solves
y'' + c y' + k y = F cos ωt exactly when (k - ω^2) A + c ω B = F and -c ω A + (k - ω^2) B = 0;
and with damping c > 0 these two equations have exactly one answer. -/
theorem cosine_push_coefficient_equations (c k F ω : ℝ) (hω : ω ≠ 0) :
    (∀ A B : ℝ,
      (∀ t : ℝ,
        let y : ℝ → ℝ := fun u => A * Real.cos (ω * u) + B * Real.sin (ω * u)
        deriv (deriv y) t + c * deriv y t + k * y t = F * Real.cos (ω * t)) ↔
      ((k - ω ^ 2) * A + c * ω * B = F ∧ -(c * ω) * A + (k - ω ^ 2) * B = 0)) ∧
    (0 < c → ∃! AB : ℝ × ℝ,
      (k - ω ^ 2) * AB.1 + c * ω * AB.2 = F ∧ -(c * ω) * AB.1 + (k - ω ^ 2) * AB.2 = 0) := by
  refine ⟨fun A B => ?_, fun hc => ?_⟩
  · have key : ∀ t : ℝ,
        (let y : ℝ → ℝ := fun u => A * Real.cos (ω * u) + B * Real.sin (ω * u)
         deriv (deriv y) t + c * deriv y t + k * y t)
        = ((k - ω ^ 2) * A + c * ω * B) * Real.cos (ω * t)
          + (-(c * ω) * A + (k - ω ^ 2) * B) * Real.sin (ω * t) := by
      intro t
      simp only [cs_deriv]
      ring
    constructor
    · intro h
      have h0 := (key 0).symm.trans (h 0)
      have h1 := (key (Real.pi / (2 * ω))).symm.trans (h (Real.pi / (2 * ω)))
      have e : ω * (Real.pi / (2 * ω)) = Real.pi / 2 := by field_simp
      rw [e, Real.cos_pi_div_two, Real.sin_pi_div_two] at h1
      simp only [mul_zero, Real.cos_zero, Real.sin_zero] at h0
      constructor
      · linarith
      · linarith
    · rintro ⟨e1, e2⟩ t
      refine (key t).trans ?_
      rw [e1, e2]
      ring
  · have hcw : c * ω ≠ 0 := mul_ne_zero hc.ne' hω
    have hD : (k - ω ^ 2) ^ 2 + (c * ω) ^ 2 ≠ 0 := by positivity
    refine ⟨(F * (k - ω ^ 2) / ((k - ω ^ 2) ^ 2 + (c * ω) ^ 2),
      F * (c * ω) / ((k - ω ^ 2) ^ 2 + (c * ω) ^ 2)), ⟨?_, ?_⟩, ?_⟩
    · field_simp
    · field_simp
      ring
    · rintro ⟨A, B⟩ ⟨e1, e2⟩
      simp only at e1 e2
      refine Prod.ext ?_ ?_
      · simp only
        rw [eq_div_iff hD]
        linear_combination (k - ω ^ 2) * e1 - (c * ω) * e2
      · simp only
        rw [eq_div_iff hD]
        linear_combination (c * ω) * e1 + (k - ω ^ 2) * e2

/-- The collision on the swing: the plain trial e^(-t) (A cos 2t + B sin 2t) solves the unpushed law
y'' + 2y' + 5y = 0 for every size A, B, while the trial multiplied by t,
(t/4) e^(-t) sin 2t, solves y'' + 2y' + 5y = e^(-t) cos 2t. -/
theorem swing_collision_multiply_by_t :
    (∀ A B t : ℝ,
      let y : ℝ → ℝ := fun u => Real.exp (-u) * (A * Real.cos (2 * u) + B * Real.sin (2 * u))
      deriv (deriv y) t + 2 * deriv y t + 5 * y t = 0) ∧
    (∀ t : ℝ,
      let y : ℝ → ℝ := fun u => u / 4 * Real.exp (-u) * Real.sin (2 * u)
      deriv (deriv y) t + 2 * deriv y t + 5 * y t = Real.exp (-t) * Real.cos (2 * t)) := by
  refine ⟨fun A B t => ?_, fun t => ?_⟩
  · intro y
    have hy : y = fun u : ℝ => Real.exp (-u) *
        ((A + 0 * u) * Real.cos (2 * u) + (B + 0 * u) * Real.sin (2 * u)) := by
      funext u
      simp only [y]
      ring
    rw [hy, sw_deriv, sw_deriv]
    ring
  · intro y
    have hy : y = fun u : ℝ => Real.exp (-u) *
        ((0 + 0 * u) * Real.cos (2 * u) + (0 + (1 / 4) * u) * Real.sin (2 * u)) := by
      funext u
      simp only [y]
      ring
    rw [hy, sw_deriv, sw_deriv]
    ring

-- The swing y'' + 2y' + 5y = 10 cos t: the coefficient equations 4A + 2B = 10, -2A + 4B = 0
-- come from (k - ω^2) = 4 and c ω = 2, and A = 2, B = 1 solves them.
example : ((5 : ℚ) - 1 ^ 2) = 4 ∧ (2 : ℚ) * 1 = 2 := by norm_num
example : (4 : ℚ) * 2 + 2 * 1 = 10 ∧ -2 * (2 : ℚ) + 4 * 1 = 0 := by norm_num
-- The determinant (k - ω^2)^2 + c^2 ω^2 = 16 + 4 = 20.
example : ((5 : ℚ) - 1 ^ 2) ^ 2 + 2 ^ 2 * 1 ^ 2 = 20 := by norm_num
-- The height squared, A^2 + B^2 = 5 (height √5), and the mistaken A + B = 3.
example : (2 : ℚ) ^ 2 + 1 ^ 2 = 5 ∧ (2 : ℚ) + 1 = 3 := by norm_num
-- Fitting the start from rest: 2 + C1 = 0 and 1 - C1 + 2 C2 = 0 give C1 = -2, C2 = -3/2.
example : (2 : ℚ) + (-2) = 0 ∧ (1 : ℚ) - (-2) + 2 * (-3 / 2) = 0 := by norm_num
-- Ramp push 5t, trial At + B: 5A = 5 and 2A + 5B = 0 give A = 1, B = -2/5.
example : (5 : ℚ) * 1 = 5 ∧ (2 : ℚ) * 1 + 5 * (-2 / 5) = 0 := by norm_num
-- Exponential push 8e^t, trial Ae^t: (1 + 2 + 5) A = 8 gives A = 1.
example : ((1 : ℚ) + 2 + 5) * 1 = 8 := by norm_num
-- Collision, R'' + 4R = cos 2t with R = t(A cos 2t + B sin 2t): 4B = 1, -4A = 0 give B = 1/4, A = 0.
example : (4 : ℚ) * (1 / 4) = 1 ∧ -4 * (0 : ℚ) = 0 := by norm_num
-- A double root: -1 is a root of z^2 + 2z + 1 and of its derivative 2z + 2, so s = 2.
example : (-1 : ℚ) ^ 2 + 2 * (-1) + 1 = 0 ∧ 2 * (-1 : ℚ) + 2 = 0 := by norm_num

#print axioms undetermined_coefficients_trial_contains_solution
#print axioms cosine_push_coefficient_equations
#print axioms swing_collision_multiply_by_t
