-- Orthogonal polynomials: Gram-Schmidt on the powers 1, x, x², … in L2 on −1 to 1 gives the Legendre polynomials, which are perpendicular with sizes squared 2/(2n + 1), so every least-squares polynomial fit is a sum of one-division coefficients and the fits converge to every L2 function.
import Mathlib.Analysis.InnerProductSpace.GramSchmidtOrtho
import Mathlib.Analysis.InnerProductSpace.Projection.FiniteDimensional
import Mathlib.MeasureTheory.Function.L2Space
import Mathlib.RingTheory.Polynomial.ShiftedLegendre
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Algebra.CharZero.Infinite
import Mathlib.Analysis.Calculus.Deriv.Polynomial
import Mathlib.Topology.ContinuousMap.Weierstrass
import Mathlib.MeasureTheory.Function.ContinuousMapDense

open MeasureTheory Polynomial Filter Topology
open scoped InnerProductSpace

/-- The interval −1 to 1 with length as its measure, so that the L2 inner product of two
functions is `∫_{-1}^{1} f g`. -/
noncomputable abbrev μI : Measure ℝ := volume.restrict (Set.Icc (-1 : ℝ) 1)

/-- A real polynomial, read as a member of L2 on −1 to 1. -/
noncomputable def polyL2 (p : ℝ[X]) : Lp ℝ 2 μI :=
  MemLp.toLp (fun x => p.eval x) (by
    obtain ⟨C, hC⟩ := (isCompact_Icc (a := (-1 : ℝ)) (b := 1)).exists_bound_of_continuousOn
      (f := fun x => p.eval x) p.continuous.continuousOn
    exact MemLp.of_bound p.continuous.aestronglyMeasurable C
      (ae_restrict_of_forall_mem measurableSet_Icc hC))

/-- The Legendre polynomial `P n` on −1 to 1, taken from Mathlib's shifted Legendre polynomial on
0 to 1 by the change of variable `t = (1 − x)/2`. It equals 1 at `x = 1`. -/
noncomputable def legendre (n : ℕ) : ℝ[X] :=
  ((shiftedLegendre n).map (Int.castRingHom ℝ)).comp (C (1 / 2 : ℝ) * (1 - X))

open scoped Classical in
/-- The polynomials of degree at most `N`, as a subspace of L2 on −1 to 1: the span of
`1, x, …, x^N`. -/
noncomputable abbrev polysUpTo (N : ℕ) : Submodule ℝ (Lp ℝ 2 μI) :=
  Submodule.span ℝ (((Finset.range (N + 1)).image fun k => polyL2 (X ^ k) : Finset _) : Set _)

theorem og_ibp (p q : ℝ[X]) :
    ∫ x in (0:ℝ)..1, p.eval x * (derivative q).eval x =
      p.eval 1 * q.eval 1 - p.eval 0 * q.eval 0 -
        ∫ x in (0:ℝ)..1, (derivative p).eval x * q.eval x :=
  intervalIntegral.integral_mul_deriv_eq_deriv_mul (fun x _ => p.hasDerivAt x)
    (fun x _ => q.hasDerivAt x) (p.derivative.continuous.intervalIntegrable _ _)
    (q.derivative.continuous.intervalIntegrable _ _)

theorem og_ibp_iter (n : ℕ) (q w : ℝ[X])
    (hw : ∀ j < n, (derivative^[j] w).eval 0 = 0 ∧ (derivative^[j] w).eval 1 = 0) :
    ∀ k ≤ n, ∫ x in (0:ℝ)..1, q.eval x * (derivative^[n] w).eval x =
      (-1) ^ k * ∫ x in (0:ℝ)..1, (derivative^[k] q).eval x * (derivative^[n - k] w).eval x := by
  intro k
  induction k with
  | zero => intro _; simp
  | succ k ih =>
    intro hk
    rw [ih (by omega)]
    have e : n - k = (n - (k + 1)) + 1 := by omega
    rw [e, Function.iterate_succ_apply', og_ibp, (hw _ (by omega)).1, (hw _ (by omega)).2,
      ← Function.iterate_succ_apply' derivative k q]
    simp only [mul_zero, sub_zero, zero_sub, pow_succ]
    ring

theorem og_beta (a b : ℕ) :
    ∫ x in (0:ℝ)..1, x ^ a * (1 - x) ^ b =
      (a.factorial * b.factorial : ℝ) / ((a + b + 1).factorial) := by
  induction b generalizing a with
  | zero =>
    simp only [pow_zero, mul_one, integral_pow, Nat.factorial_zero, Nat.cast_one, add_zero]
    rw [Nat.factorial_succ]; push_cast
    have : (a.factorial : ℝ) ≠ 0 := by positivity
    field_simp; simp
  | succ b ih =>
    have h := og_ibp ((1 - X) ^ (b + 1)) (C (1 / ((a:ℝ) + 1)) * X ^ (a + 1))
    simp only [derivative_C_mul_X_pow, derivative_pow, eval_mul, eval_pow, eval_sub, eval_one,
      eval_X, eval_C, derivative_sub, derivative_one, derivative_X, eval_zero,
      Nat.add_sub_cancel, sub_self, zero_pow (Nat.succ_ne_zero _), zero_mul, mul_zero,
      sub_zero] at h
    have h2 : ∀ x : ℝ, (1 - x) ^ (b + 1) * (1 / ((a:ℝ) + 1) * ↑(a + 1) * x ^ a) =
        x ^ a * (1 - x) ^ (b + 1) := by
      intro x; push_cast; field_simp
    simp only [h2] at h
    rw [h]
    have h3 : ∀ x : ℝ, ↑(b + 1) * (1 - x) ^ b * (0 - 1) * (1 / ((a:ℝ) + 1) * x ^ (a + 1)) =
        (-(((b:ℝ) + 1) / ((a:ℝ) + 1))) * (x ^ (a + 1) * (1 - x) ^ b) := by
      intro x; push_cast; ring
    simp only [h3]
    rw [intervalIntegral.integral_const_mul, ih, show a + 1 + b + 1 = a + (b + 1) + 1 by ring]
    simp only [Nat.factorial_succ]
    push_cast
    field_simp
    ring

theorem og_rodrigues (n : ℕ) :
    ((shiftedLegendre n).map (Int.castRingHom ℝ)) =
      C (1 / (n.factorial : ℝ)) * derivative^[n] (X ^ n * (1 - X) ^ n) := by
  have h := congrArg (Polynomial.map (Int.castRingHom ℝ)) (factorial_mul_shiftedLegendre_eq n)
  rw [Polynomial.map_mul, ← iterate_derivative_map] at h
  simp only [Polynomial.map_natCast, Polynomial.map_mul, Polynomial.map_pow, Polynomial.map_X,
    Polynomial.map_sub, Polynomial.map_one] at h
  rw [← h, ← mul_assoc, ← C_eq_natCast, ← C_mul]
  have : (n.factorial : ℝ) ≠ 0 := by positivity
  simp [this]

theorem og_wvan (n : ℕ) : ∀ j < n,
    (derivative^[j] ((X : ℝ[X]) ^ n * (1 - X) ^ n)).eval 0 = 0 ∧
    (derivative^[j] ((X : ℝ[X]) ^ n * (1 - X) ^ n)).eval 1 = 0 := by
  intro j hj
  have key : ∀ t : ℝ, (X - C t) ^ n ∣ (X : ℝ[X]) ^ n * (1 - X) ^ n →
      (derivative^[j] ((X : ℝ[X]) ^ n * (1 - X) ^ n)).eval t = 0 := by
    intro t ht
    have h1 := pow_sub_dvd_iterate_derivative_of_pow_dvd j ht
    have h2 : (X - C t) ∣ derivative^[j] ((X : ℝ[X]) ^ n * (1 - X) ^ n) :=
      (dvd_pow_self _ (by omega)).trans h1
    exact dvd_iff_isRoot.mp h2
  refine ⟨key 0 ?_, key 1 ?_⟩
  · simp
  · apply Dvd.dvd.mul_left
    apply pow_dvd_pow_of_dvd
    exact ⟨-1, by simp⟩

theorem og_int_iter_zero (n : ℕ) (r : ℝ[X]) (hr : r.degree < n) :
    ∫ x in (0:ℝ)..1, r.eval x * (derivative^[n] ((X : ℝ[X]) ^ n * (1 - X) ^ n)).eval x = 0 := by
  rw [og_ibp_iter n r _ (og_wvan n) n le_rfl, iterate_derivative_eq_zero_of_degree_lt hr]
  simp

theorem og_orth0 (n : ℕ) (r : ℝ[X]) (hr : r.degree < n) :
    ∫ x in (0:ℝ)..1, r.eval x * ((shiftedLegendre n).map (Int.castRingHom ℝ)).eval x = 0 := by
  rw [og_rodrigues]
  simp only [eval_mul, eval_C]
  have : ∀ x : ℝ, r.eval x * (1 / (n.factorial : ℝ) *
      (derivative^[n] ((X : ℝ[X]) ^ n * (1 - X) ^ n)).eval x) =
      (1 / (n.factorial : ℝ)) * (r.eval x *
      (derivative^[n] ((X : ℝ[X]) ^ n * (1 - X) ^ n)).eval x) := fun x => by ring
  simp only [this, intervalIntegral.integral_const_mul, og_int_iter_zero n r hr, mul_zero]

theorem og_xn_int (n : ℕ) :
    ∫ x in (0:ℝ)..1, (X ^ n : ℝ[X]).eval x *
      ((shiftedLegendre n).map (Int.castRingHom ℝ)).eval x =
      (-1) ^ n * ∫ x in (0:ℝ)..1, x ^ n * (1 - x) ^ n := by
  rw [og_rodrigues]
  simp only [eval_mul, eval_C]
  have : ∀ x : ℝ, (X ^ n : ℝ[X]).eval x * (1 / (n.factorial : ℝ) *
      (derivative^[n] ((X : ℝ[X]) ^ n * (1 - X) ^ n)).eval x) =
      (1 / (n.factorial : ℝ)) * ((X ^ n : ℝ[X]).eval x *
      (derivative^[n] ((X : ℝ[X]) ^ n * (1 - X) ^ n)).eval x) := fun x => by ring
  simp only [this, intervalIntegral.integral_const_mul]
  rw [og_ibp_iter n _ _ (og_wvan n) n le_rfl, iterate_derivative_X_pow_eq_smul,
    Nat.descFactorial_self, Nat.sub_self, pow_zero]
  simp only [Function.iterate_zero, id_eq, eval_smul, eval_one, eval_mul, eval_pow, eval_X,
    eval_sub, smul_eq_mul, mul_one]
  rw [intervalIntegral.integral_const_mul]
  have : (n.factorial : ℝ) ≠ 0 := by positivity
  field_simp

theorem og_norm0 (n : ℕ) :
    ∫ x in (0:ℝ)..1, ((shiftedLegendre n).map (Int.castRingHom ℝ)).eval x *
      ((shiftedLegendre n).map (Int.castRingHom ℝ)).eval x = 1 / (2 * (n : ℝ) + 1) := by
  have hI := og_xn_int n
  set s := (shiftedLegendre n).map (Int.castRingHom ℝ) with hs
  have hdeg : s.degree = n := by
    rw [hs, degree_map_eq_of_injective (RingHom.injective_int (Int.castRingHom ℝ)),
      degree_shiftedLegendre]
  have hnd : s.natDegree = n := natDegree_eq_of_degree_eq_some hdeg
  have hs0 : s ≠ 0 := by intro h; rw [h] at hdeg; simp at hdeg
  have hlc : s.leadingCoeff = (-1) ^ n * ((2 * n).choose n : ℝ) := by
    rw [leadingCoeff, hnd, hs, coeff_map, coeff_shiftedLegendre]
    simp [two_mul]
  have hsplit := eraseLead_add_C_mul_X_pow s
  rw [hnd] at hsplit
  have her : s.eraseLead.degree < n := hdeg ▸ degree_eraseLead_lt hs0
  calc ∫ x in (0:ℝ)..1, s.eval x * s.eval x
      = ∫ x in (0:ℝ)..1, (s.eraseLead.eval x * s.eval x +
          s.leadingCoeff * ((X ^ n : ℝ[X]).eval x * s.eval x)) := by
        congr 1; ext x
        have hx := congrArg (eval x) hsplit
        simp only [eval_add, eval_mul, eval_C, eval_pow, eval_X] at hx
        nth_rw 1 [← hx]
        simp only [eval_pow, eval_X]; ring
    _ = s.leadingCoeff * ∫ x in (0:ℝ)..1, (X ^ n : ℝ[X]).eval x * s.eval x := by
        rw [intervalIntegral.integral_add (f := fun x => s.eraseLead.eval x * s.eval x)
          (g := fun x => s.leadingCoeff * ((X ^ n : ℝ[X]).eval x * s.eval x))
          ((s.eraseLead.continuous.mul s.continuous).intervalIntegrable _ _)
          ((continuous_const.mul ((X ^ n : ℝ[X]).continuous.mul s.continuous)).intervalIntegrable
            _ _),
          og_orth0 n _ her, zero_add, intervalIntegral.integral_const_mul]
    _ = 1 / (2 * (n : ℝ) + 1) := by
        rw [hI, og_beta, hlc]
        have h1 : ((2 * n).choose n : ℝ) * n.factorial * n.factorial = (2 * n).factorial := by
          have := Nat.choose_mul_factorial_mul_factorial (show n ≤ 2 * n by omega)
          rw [show 2 * n - n = n by omega] at this
          exact_mod_cast this
        have h2 : ((n + n + 1).factorial : ℝ) = (2 * n + 1) * (2 * n).factorial := by
          rw [show n + n + 1 = 2 * n + 1 by ring, Nat.factorial_succ]; push_cast; ring
        rw [h2, ← h1]
        have : (n.factorial : ℝ) ≠ 0 := by positivity
        have : ((2 * n).choose n : ℝ) ≠ 0 := by
          have := Nat.choose_pos (show n ≤ 2 * n by omega); positivity
        field_simp
        rw [← pow_mul, mul_comm, pow_mul]; norm_num

theorem og_legendre_eq (n : ℕ) :
    legendre n = ((shiftedLegendre n).map (Int.castRingHom ℝ)).comp
      (C (-1 / 2 : ℝ) * X + C (1 / 2)) := by
  unfold legendre
  congr 1
  apply Polynomial.funext; intro x
  simp; ring

theorem og_change_var (a b : ℝ[X]) :
    ∫ x in (-1 : ℝ)..1, a.eval x * (b.comp (C (-1 / 2 : ℝ) * X + C (1 / 2))).eval x =
      2 * ∫ t in (0 : ℝ)..1, (a.comp (1 - C 2 * X)).eval t * b.eval t := by
  set F : ℝ → ℝ := fun t => (a.comp (1 - C 2 * X)).eval t * b.eval t with hF
  have h : ∀ x : ℝ, a.eval x * (b.comp (C (-1 / 2 : ℝ) * X + C (1 / 2))).eval x =
      F ((-1 / 2) * x + 1 / 2) := by
    intro x
    simp only [hF, eval_comp, eval_mul, eval_add, eval_C, eval_X, eval_sub, eval_one]
    congr 2; ring
  simp only [h]
  rw [intervalIntegral.integral_comp_mul_add F (by norm_num : (-1 / 2 : ℝ) ≠ 0)]
  norm_num
  rw [intervalIntegral.integral_symm]
  ring

theorem og_natDegree_legendre (n : ℕ) : (legendre n).natDegree = n := by
  rw [og_legendre_eq, natDegree_comp, natDegree_map_eq_of_injective
    (RingHom.injective_int (Int.castRingHom ℝ)), natDegree_shiftedLegendre,
    natDegree_linear (by norm_num), mul_one]

theorem og_orth (n : ℕ) (q : ℝ[X]) (hq : q.natDegree < n) :
    ∫ x in (-1 : ℝ)..1, q.eval x * (legendre n).eval x = 0 := by
  rw [og_legendre_eq, og_change_var, og_orth0, mul_zero]
  refine (degree_le_natDegree).trans_lt ?_
  exact_mod_cast (natDegree_comp_le).trans_lt (by
    calc q.natDegree * (1 - C 2 * X : ℝ[X]).natDegree ≤ q.natDegree * 1 := by
          gcongr
          rw [sub_eq_add_neg, ← neg_mul, ← C_neg, add_comm, ← C_1]
          exact natDegree_linear_le
      _ < n := by omega)

theorem og_norm (n : ℕ) :
    ∫ x in (-1 : ℝ)..1, (legendre n).eval x * (legendre n).eval x =
      2 / (2 * (n : ℝ) + 1) := by
  conv_lhs => rw [og_legendre_eq n]
  rw [og_change_var]
  have : (((shiftedLegendre n).map (Int.castRingHom ℝ)).comp
      (C (-1 / 2 : ℝ) * X + C (1 / 2))).comp (1 - C 2 * X) =
      (shiftedLegendre n).map (Int.castRingHom ℝ) := by
    rw [comp_assoc]
    conv_rhs => rw [← comp_X (p := (shiftedLegendre n).map (Int.castRingHom ℝ))]
    congr 1
    apply Polynomial.funext; intro x
    simp; ring
  rw [this, og_norm0]
  ring

theorem og_polyL2_coe (p : ℝ[X]) : polyL2 p =ᵐ[μI] fun x => p.eval x :=
  MemLp.coeFn_toLp _

theorem og_polyL2_add (p q : ℝ[X]) : polyL2 (p + q) = polyL2 p + polyL2 q := by
  apply Lp.ext
  filter_upwards [og_polyL2_coe (p + q), og_polyL2_coe p, og_polyL2_coe q,
    Lp.coeFn_add (polyL2 p) (polyL2 q)] with x h1 h2 h3 h4
  rw [h1, h4, Pi.add_apply, h2, h3, eval_add]

theorem og_polyL2_smul (a : ℝ) (p : ℝ[X]) : polyL2 (a • p) = a • polyL2 p := by
  apply Lp.ext
  filter_upwards [og_polyL2_coe (a • p), og_polyL2_coe p,
    Lp.coeFn_smul a (polyL2 p)] with x h1 h2 h4
  rw [h1, h4, Pi.smul_apply, h2, eval_smul]

/-- `polyL2` as a linear map. -/
noncomputable def og_polyL2Lin : ℝ[X] →ₗ[ℝ] Lp ℝ 2 μI where
  toFun := polyL2
  map_add' := og_polyL2_add
  map_smul' := og_polyL2_smul

theorem og_inner (p q : ℝ[X]) :
    ⟪polyL2 p, polyL2 q⟫_ℝ = ∫ x in (-1 : ℝ)..1, p.eval x * q.eval x := by
  rw [MeasureTheory.L2.inner_def, intervalIntegral.integral_of_le (by norm_num),
    ← integral_Icc_eq_integral_Ioc]
  apply integral_congr_ae
  filter_upwards [og_polyL2_coe p, og_polyL2_coe q] with x h1 h2
  rw [h1, h2, RCLike.inner_apply, conj_trivial, mul_comm]

theorem og_polyL2_mem_span (m : ℕ) (r : ℝ[X]) (hr : r.degree < m) :
    polyL2 r ∈ Submodule.span ℝ ((fun k : ℕ => polyL2 (X ^ k)) '' Set.Iio m) := by
  rcases eq_or_ne r 0 with h0 | h0
  · subst h0
    have : polyL2 0 = 0 := og_polyL2Lin.map_zero
    rw [this]; exact Submodule.zero_mem _
  have hnd : r.natDegree < m := (natDegree_lt_iff_degree_lt h0).2 hr
  rw [as_sum_range' r m hnd]
  have : polyL2 (∑ i ∈ Finset.range m, monomial i (r.coeff i)) =
      ∑ i ∈ Finset.range m, (r.coeff i) • polyL2 (X ^ i) := by
    change og_polyL2Lin _ = _
    rw [map_sum]
    refine Finset.sum_congr rfl fun i _ => ?_
    rw [← C_mul_X_pow_eq_monomial, ← smul_eq_C_mul, map_smul]; rfl
  rw [this]
  refine Submodule.sum_mem _ fun i hi => Submodule.smul_mem _ _ (Submodule.subset_span ?_)
  exact ⟨i, by simpa using hi, rfl⟩

open scoped Classical in
theorem og_polysUpTo_eq (N : ℕ) :
    polysUpTo N = Submodule.span ℝ ((fun k : ℕ => polyL2 (X ^ k)) '' Set.Iio (N + 1)) := by
  rw [polysUpTo, Finset.coe_image, Finset.coe_range]

theorem og_dense (f : Lp ℝ 2 μI) (ε : ℝ) (hε : 0 < ε) :
    ∃ p : ℝ[X], ‖f - polyL2 p‖ < ε := by
  have hd := BoundedContinuousFunction.toLp_denseRange ℝ μI ℝ (p := 2) (by simp)
  obtain ⟨g, hg⟩ := hd.exists_dist_lt f (half_pos hε)
  set M : ℝ := (measureUnivNNReal μI : ℝ) ^ ((2 : ENNReal).toReal⁻¹) with hM
  have hM0 : 0 ≤ M := by positivity
  set δ : ℝ := ε / (2 * (M + 1)) with hδ
  have hδ0 : 0 < δ := by positivity
  obtain ⟨p, hp⟩ := exists_polynomial_near_of_continuousOn (-1) 1 g g.continuous.continuousOn δ hδ0
  refine ⟨p, ?_⟩
  have hb : ‖BoundedContinuousFunction.toLp 2 μI ℝ g - polyL2 p‖ ≤ M * δ := by
    apply Lp.norm_le_of_ae_bound hδ0.le
    filter_upwards [Lp.coeFn_sub (BoundedContinuousFunction.toLp 2 μI ℝ g) (polyL2 p),
      BoundedContinuousFunction.coeFn_toLp (p := 2) (μ := μI) (𝕜 := ℝ) g, og_polyL2_coe p,
      ae_restrict_mem measurableSet_Icc] with x h1 h2 h3 hx
    rw [h1, Pi.sub_apply, h2, h3, Real.norm_eq_abs, abs_sub_comm]
    exact (hp x hx).le
  have hMδ : M * δ < ε / 2 := by
    rw [hδ, mul_div_assoc', div_lt_div_iff₀ (by positivity) (by norm_num)]
    nlinarith
  calc ‖f - polyL2 p‖ ≤ ‖f - BoundedContinuousFunction.toLp 2 μI ℝ g‖ +
        ‖BoundedContinuousFunction.toLp 2 μI ℝ g - polyL2 p‖ := norm_sub_le_norm_sub_add_norm_sub _ _ _
    _ < ε / 2 + ε / 2 := by
        rw [← dist_eq_norm]; linarith
    _ = ε := by ring

/-- Gram-Schmidt run on the powers `1, x, x², …` with the L2 inner product on −1 to 1 produces the
Legendre polynomials: the `n`-th leftover is a nonzero multiple of `P n`, so scaling it to equal 1
at `x = 1` gives exactly `P n`. -/
theorem gram_schmidt_of_powers_is_legendre (n : ℕ) :
    ∃ c : ℝ, c ≠ 0 ∧
      InnerProductSpace.gramSchmidt ℝ (fun k : ℕ => polyL2 (X ^ k)) n =
        c • polyL2 (legendre n) := by
  set f : ℕ → Lp ℝ 2 μI := fun k => polyL2 (X ^ k) with hf
  set W := Submodule.span ℝ (f '' Set.Iio n) with hW
  set v := InnerProductSpace.gramSchmidt ℝ f n with hv
  set a := (legendre n).leadingCoeff with ha
  have hleg0 : legendre n ≠ 0 := by
    intro h0
    have h := og_norm n
    rw [h0] at h
    simp only [eval_zero, mul_zero, intervalIntegral.integral_zero] at h
    have : (0 : ℝ) < 2 / (2 * (n : ℝ) + 1) := by positivity
    linarith
  have ha0 : a ≠ 0 := leadingCoeff_ne_zero.2 hleg0
  -- the Gram-Schmidt leftover differs from `f n` by a member of `W`
  have hva : v - f n ∈ W := by
    rw [hv, InnerProductSpace.gramSchmidt_def ℝ f n, sub_sub_cancel_left]
    refine W.neg_mem (W.sum_mem fun i hi => ?_)
    have hi' : i < n := Finset.mem_Iio.1 hi
    have h1 : (ℝ ∙ InnerProductSpace.gramSchmidt ℝ f i) ≤ W := by
      rw [hW, ← InnerProductSpace.span_gramSchmidt_Iio ℝ f n]
      exact Submodule.span_mono (Set.singleton_subset_iff.2 ⟨i, hi', rfl⟩)
    exact h1 (Submodule.starProjection_apply_mem _ _)
  -- the leftover is perpendicular to `W`
  have hvo : ∀ w ∈ W, ⟪w, v⟫_ℝ = 0 := by
    have : W ≤ (ℝ ∙ v)ᗮ := by
      rw [hW, Submodule.span_le]
      rintro _ ⟨i, hi, rfl⟩
      rw [SetLike.mem_coe, Submodule.mem_orthogonal_singleton_iff_inner_right]
      exact InnerProductSpace.gramSchmidt_inv_triangular ℝ f hi
    intro w hw
    rw [real_inner_comm]
    exact Submodule.mem_orthogonal_singleton_iff_inner_right.1 (this hw)
  -- `P n` differs from `a • f n` by a member of `W`
  have hsplit := eraseLead_add_C_mul_X_pow (legendre n)
  rw [og_natDegree_legendre] at hsplit
  have hPa : polyL2 (legendre n) - a • f n ∈ W := by
    have : polyL2 (legendre n) - a • f n = polyL2 (legendre n).eraseLead := by
      conv_lhs => rw [← hsplit]
      rw [og_polyL2_add, ← smul_eq_C_mul, og_polyL2_smul, ← ha, add_sub_cancel_right]
    rw [this]
    apply og_polyL2_mem_span
    have := degree_eraseLead_lt hleg0
    rwa [degree_eq_natDegree hleg0, og_natDegree_legendre] at this
  -- `P n` is perpendicular to `W`
  have hPo : ∀ w ∈ W, ⟪w, polyL2 (legendre n)⟫_ℝ = 0 := by
    have : W ≤ (ℝ ∙ polyL2 (legendre n))ᗮ := by
      rw [hW, Submodule.span_le]
      rintro _ ⟨i, hi, rfl⟩
      rw [SetLike.mem_coe, Submodule.mem_orthogonal_singleton_iff_inner_right, real_inner_comm,
        og_inner]
      exact og_orth n _ (by rw [natDegree_X_pow]; exact hi)
    intro w hw
    rw [real_inner_comm]
    exact Submodule.mem_orthogonal_singleton_iff_inner_right.1 (this hw)
  -- so `a • v - P n` lies in `W` and is perpendicular to `W`, hence is zero
  set d := a • v - polyL2 (legendre n) with hd
  have hdW : d ∈ W := by
    have : d = a • (v - f n) - (polyL2 (legendre n) - a • f n) := by
      rw [hd, smul_sub]; abel
    rw [this]
    exact W.sub_mem (W.smul_mem _ hva) hPa
  have hdd : ⟪d, d⟫_ℝ = 0 := by
    conv_rhs => skip
    nth_rw 2 [hd]
    rw [inner_sub_right, real_inner_smul_right, hvo d hdW, hPo d hdW]
    ring
  have hd0 : d = 0 := inner_self_eq_zero.1 hdd
  refine ⟨a⁻¹, inv_ne_zero ha0, ?_⟩
  rw [hd, sub_eq_zero] at hd0
  rw [← hd0, smul_smul, inv_mul_cancel₀ ha0, one_smul]

/-- The Gram matrix of the Legendre polynomials on −1 to 1 is diagonal: `P m` and `P n` are
perpendicular when `m ≠ n`, and `P n` has size squared `2/(2n + 1)`. -/
theorem legendre_gram_matrix_is_diagonal (m n : ℕ) :
    ∫ x in (-1 : ℝ)..1, (legendre m).eval x * (legendre n).eval x =
      if m = n then (2 : ℝ) / (2 * (n : ℝ) + 1) else 0 := by
  split_ifs with h
  · subst h; exact og_norm m
  · rcases lt_or_gt_of_ne h with h | h
    · exact og_orth n _ (by rw [og_natDegree_legendre]; exact h)
    · simp_rw [mul_comm ((legendre m).eval _)]
      exact og_orth m _ (by rw [og_natDegree_legendre]; exact h)

/-- The least-squares fit: for every `f` in L2 on −1 to 1, the best polynomial of degree at most
`N` (the projection of `f` onto those polynomials) is `∑ c_n P_n` with each
`c_n = ⟨f, P_n⟩ / ⟨P_n, P_n⟩` found by one division; its error obeys Pythagoras,
`‖f − fit‖² = ‖f‖² − ∑ c_n² ‖P_n‖²`; and as `N` grows the error tends to 0 in the L2 norm, so the
Legendre family is complete. -/
theorem legendre_fit_is_sum_of_projections_and_converges (f : Lp ℝ 2 μI) :
    (∀ N : ℕ,
      (polysUpTo N).starProjection f =
        ∑ n ∈ Finset.range (N + 1),
          (⟪polyL2 (legendre n), f⟫_ℝ / ⟪polyL2 (legendre n), polyL2 (legendre n)⟫_ℝ) •
            polyL2 (legendre n) ∧
      ‖f - (polysUpTo N).starProjection f‖ ^ 2 =
        ‖f‖ ^ 2 - ∑ n ∈ Finset.range (N + 1),
          (⟪polyL2 (legendre n), f⟫_ℝ / ⟪polyL2 (legendre n), polyL2 (legendre n)⟫_ℝ) ^ 2 *
            ‖polyL2 (legendre n)‖ ^ 2) ∧
    Tendsto (fun N => ‖f - (polysUpTo N).starProjection f‖) atTop (𝓝 0) := by
  set e : ℕ → Lp ℝ 2 μI := fun n => polyL2 (legendre n) with he
  have hee : ∀ m n, ⟪e m, e n⟫_ℝ = if m = n then 2 / (2 * (n : ℝ) + 1) else 0 :=
    fun m n => by rw [he, og_inner]; exact legendre_gram_matrix_is_diagonal m n
  have hee0 : ∀ n, ⟪e n, e n⟫_ℝ ≠ 0 := fun n => by rw [hee]; simp only [↓reduceIte]; positivity
  have heK : ∀ N, ∀ n ≤ N, e n ∈ polysUpTo N := fun N n hn => by
    rw [og_polysUpTo_eq]
    apply og_polyL2_mem_span
    refine degree_le_natDegree.trans_lt ?_
    rw [og_natDegree_legendre]
    exact_mod_cast Nat.lt_succ_of_le hn
  have hKe : ∀ N, polysUpTo N ≤ Submodule.span ℝ (e '' Set.Iio (N + 1)) := fun N => by
    rw [og_polysUpTo_eq, ← InnerProductSpace.span_gramSchmidt_Iio ℝ, Submodule.span_le]
    rintro _ ⟨i, hi, rfl⟩
    obtain ⟨c, -, hc⟩ := gram_schmidt_of_powers_is_legendre i
    rw [SetLike.mem_coe, hc]
    exact Submodule.smul_mem _ _ (Submodule.subset_span ⟨i, hi, rfl⟩)
  have hproj : ∀ N : ℕ, (polysUpTo N).starProjection f =
      ∑ n ∈ Finset.range (N + 1), (⟪e n, f⟫_ℝ / ⟪e n, e n⟫_ℝ) • e n := by
    intro N
    apply Submodule.eq_starProjection_of_mem_of_inner_eq_zero
    · exact Submodule.sum_mem _ fun n hn =>
        Submodule.smul_mem _ _ (heK N n (Nat.lt_succ_iff.1 (Finset.mem_range.1 hn)))
    · have horth : ∀ m < N + 1, ⟪f - ∑ n ∈ Finset.range (N + 1),
          (⟪e n, f⟫_ℝ / ⟪e n, e n⟫_ℝ) • e n, e m⟫_ℝ = 0 := by
        intro m hm
        rw [inner_sub_left, sum_inner, Finset.sum_eq_single m]
        · rw [real_inner_smul_left, div_mul_cancel₀ _ (hee0 m), real_inner_comm, sub_self]
        · intro b _ hb
          rw [real_inner_smul_left, hee b m]; simp [hb]
        · intro h; exact absurd (Finset.mem_range.2 hm) h
      have hle : polysUpTo N ≤ (ℝ ∙ (f - ∑ n ∈ Finset.range (N + 1),
          (⟪e n, f⟫_ℝ / ⟪e n, e n⟫_ℝ) • e n))ᗮ := by
        refine (hKe N).trans ?_
        rw [Submodule.span_le]
        rintro _ ⟨m, hm, rfl⟩
        rw [SetLike.mem_coe, Submodule.mem_orthogonal_singleton_iff_inner_right]
        exact horth m hm
      intro w hw
      exact Submodule.mem_orthogonal_singleton_iff_inner_right.1 (hle hw)
  refine ⟨fun N => ⟨by rw [hproj N], ?_⟩, ?_⟩
  · have hpy := Submodule.norm_sq_eq_add_norm_sq_starProjection f (polysUpTo N)
    rw [Submodule.starProjection_orthogonal_val] at hpy
    have hs2 : ‖∑ n ∈ Finset.range (N + 1), (⟪e n, f⟫_ℝ / ⟪e n, e n⟫_ℝ) • e n‖ ^ 2 =
        ∑ n ∈ Finset.range (N + 1), (⟪e n, f⟫_ℝ / ⟪e n, e n⟫_ℝ) ^ 2 * ‖e n‖ ^ 2 := by
      rw [← real_inner_self_eq_norm_sq, sum_inner]
      refine Finset.sum_congr rfl fun i hi => ?_
      rw [inner_sum, Finset.sum_eq_single i]
      · rw [real_inner_smul_left, real_inner_smul_right, real_inner_self_eq_norm_sq]; ring
      · intro b _ hb
        rw [real_inner_smul_left, real_inner_smul_right, hee i b]; simp [Ne.symm hb]
      · intro h; exact absurd hi h
    rw [hproj N] at hpy ⊢
    rw [hs2] at hpy
    linarith
  · rw [Metric.tendsto_atTop]
    intro ε hε
    obtain ⟨p, hp⟩ := og_dense f ε hε
    refine ⟨p.natDegree, fun N hN => ?_⟩
    rw [Real.dist_eq, sub_zero, abs_of_nonneg (norm_nonneg _)]
    have hpK : polyL2 p ∈ polysUpTo N := by
      rw [og_polysUpTo_eq]
      apply og_polyL2_mem_span
      exact degree_le_natDegree.trans_lt (by exact_mod_cast Nat.lt_succ_of_le hN)
    calc ‖f - (polysUpTo N).starProjection f‖ ≤ ‖f - polyL2 p‖ := by
          rw [Submodule.starProjection_minimal]
          exact ciInf_le ⟨0, by rintro _ ⟨x, rfl⟩; exact norm_nonneg _⟩
            (⟨polyL2 p, hpK⟩ : polysUpTo N)
      _ < ε := hp

-- The card's worked numbers.
-- Gram matrix entries of 1, x, x²: ⟨1, x²⟩ = 2/3, ⟨x², x²⟩ = 2/5, ⟨1, x⟩ = 0.
example : ∫ x in (-1 : ℝ)..1, x ^ 2 = 2 / 3 := by norm_num [integral_pow]
example : ∫ x in (-1 : ℝ)..1, x ^ 4 = 2 / 5 := by norm_num [integral_pow]
example : ∫ x in (-1 : ℝ)..1, x = 0 := by norm_num [integral_id]
-- The leftovers scaled to 1 at x = 1: P₂ = (3x² − 1)/2 and P₃ = (5x³ − 3x)/2.
example : legendre 2 = C (3 / 2) * X ^ 2 - C (1 / 2) := by
  apply Polynomial.funext; intro x
  norm_num [legendre, shiftedLegendre, Finset.sum_range_succ, Nat.choose]; ring
example : legendre 3 = C (5 / 2) * X ^ 3 - C (3 / 2) * X := by
  apply Polynomial.funext; intro x
  norm_num [legendre, shiftedLegendre, Finset.sum_range_succ, Nat.choose]; ring
-- Shadows: x² on 1 is (2/3)/2 = 1/3; x³ on x is (2/5)/(2/3) = 3/5.
example : (2 / 3 : ℚ) / 2 = 1 / 3 := by norm_num
example : (2 / 5 : ℚ) / (2 / 3) = 3 / 5 := by norm_num
-- Gram-Schmidt as a factoring G = L D Lᵀ: the bottom-right entry (1/3)² · 2 + 8/45 = 2/5.
example : (1 / 3 : ℚ) ^ 2 * 2 + 8 / 45 = 2 / 5 := by norm_num
-- The dip |x|: ⟨|x|, P₂⟩ = 3/2 · 1/2 − 1/2 · 1 = 1/4, c₂ = (1/4)/(2/5) = 5/8.
example : (3 / 2 : ℚ) * (1 / 2) - 1 / 2 * 1 = 1 / 4 := by norm_num
example : (1 / 4 : ℚ) / (2 / 5) = 5 / 8 := by norm_num
-- The fit 1/2 + 5/8 · (3x² − 1)/2 is 3/16 + 15/16 x².
example (x : ℚ) : 1 / 2 + 5 / 8 * ((3 * x ^ 2 - 1) / 2) = 3 / 16 + 15 / 16 * x ^ 2 := by ring
-- Energy captured 1/2 + 5/32 = 21/32, and missed 2/3 − 21/32 = 1/96.
example : (1 / 2 : ℚ) ^ 2 * 2 + (5 / 8) ^ 2 * (2 / 5) = 21 / 32 := by norm_num
example : (2 / 3 : ℚ) - 21 / 32 = 1 / 96 := by norm_num
-- What breaks: on 0 to 1, ⟨P₀, P₁⟩ = 1/2, not 0.
example : ∫ x in (0 : ℝ)..1, x = 1 / 2 := by norm_num [integral_id]
-- What breaks: three samples at −1, 0, 1 see x³ − x as zero.
example : ∀ x ∈ ({-1, 0, 1} : Finset ℤ), x ^ 3 - x = 0 := by decide

#print axioms gram_schmidt_of_powers_is_legendre
#print axioms legendre_gram_matrix_is_diagonal
#print axioms legendre_fit_is_sum_of_projections_and_converges
#print axioms og_ibp
#print axioms og_ibp_iter
#print axioms og_beta
#print axioms og_rodrigues
#print axioms og_wvan
#print axioms og_int_iter_zero
#print axioms og_orth0
#print axioms og_xn_int
#print axioms og_norm0
#print axioms og_legendre_eq
#print axioms og_change_var
#print axioms og_natDegree_legendre
#print axioms og_orth
#print axioms og_norm
#print axioms og_polyL2_coe
#print axioms og_polyL2_add
#print axioms og_polyL2_smul
#print axioms og_inner
#print axioms og_polyL2_mem_span
#print axioms og_polysUpTo_eq
#print axioms og_dense
#print axioms og_polyL2Lin
