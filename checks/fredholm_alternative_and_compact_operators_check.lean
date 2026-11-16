-- The Fredholm alternative: for a compact symmetric operator K on a real Hilbert space, u - λKu = f has exactly one answer for every f when u - λKu = 0 has only u = 0, and otherwise the free answers form a finite-dimensional space, f has an answer exactly when it is perpendicular to them, and the answer is fixed only up to adding them.
import Mathlib.Analysis.InnerProductSpace.Adjoint
import Mathlib.Analysis.Normed.Operator.Compact.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Topology.Algebra.InfiniteSum.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Normed.Operator.Compact.FredholmAlternative
import Mathlib.Analysis.InnerProductSpace.Spectrum
import Mathlib.Analysis.SpecificLimits.Normed
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic

open scoped InnerProductSpace

theorem fredholm_helper_surj {X : Type*} [NormedAddCommGroup X] [NormedSpace ℝ X]
    [CompleteSpace X] (K : X →L[ℝ] X) (hK : IsCompactOperator K) (lam : ℝ)
    (hinj : ∀ v : X, v - lam • K v = 0 → v = 0) (f : X) : ∃ u : X, u - lam • K u = f := by
  rcases eq_or_ne lam 0 with rfl | hlam
  · exact ⟨f, by simp⟩
  have hμ : lam⁻¹ ≠ 0 := inv_ne_zero hlam
  rcases hK.hasEigenvalue_or_mem_resolventSet hμ with hev | hres
  · exfalso
    obtain ⟨v, hv⟩ := hev.exists_hasEigenvector
    have hKv : K v = lam⁻¹ • v := Module.End.mem_eigenspace_iff.mp hv.1
    apply hv.2
    apply hinj
    rw [hKv, smul_smul, mul_inv_cancel₀ hlam, one_smul, sub_self]
  · rw [spectrum.mem_resolventSet_iff, ContinuousLinearMap.isUnit_iff_bijective] at hres
    obtain ⟨u, hu⟩ := hres.2 (lam⁻¹ • f)
    refine ⟨u, ?_⟩
    have hu' : lam⁻¹ • u - K u = lam⁻¹ • f := by simpa [Algebra.algebraMap_eq_smul_one] using hu
    calc u - lam • K u = lam • (lam⁻¹ • u - K u) := by
          rw [smul_sub, smul_smul, mul_inv_cancel₀ hlam, one_smul]
      _ = f := by rw [hu', smul_smul, mul_inv_cancel₀ hlam, one_smul]

#print axioms fredholm_helper_surj

/-- The Fredholm alternative for a compact symmetric kernel. Let K be a compact, symmetric
(self-adjoint) operator on a real Hilbert space, such as L2(0, 1), and let λ be a number. Look at
the second-kind equation u - λKu = f. Either u - λKu = 0 has only the answer u = 0, and then every
source f gives exactly one answer u; or u - λKu = 0 has nonzero answers, these free answers form a
finite-dimensional space, a source f can be balanced exactly when f is perpendicular to every
free answer, and then any two answers differ by a free answer. -/
theorem fredholm_alternative_compact_symmetric {E : Type*} [NormedAddCommGroup E]
    [InnerProductSpace ℝ E] [CompleteSpace E] (K : E →L[ℝ] E) (hK : IsCompactOperator K)
    (hsym : IsSelfAdjoint K) (lam : ℝ) :
    (LinearMap.ker (((1 : E →L[ℝ] E) - lam • K : E →L[ℝ] E) : E →ₗ[ℝ] E) = ⊥ ∧
        ∀ f : E, ∃! u : E, u - lam • K u = f) ∨
      (LinearMap.ker (((1 : E →L[ℝ] E) - lam • K : E →L[ℝ] E) : E →ₗ[ℝ] E) ≠ ⊥ ∧
        FiniteDimensional ℝ
          (LinearMap.ker (((1 : E →L[ℝ] E) - lam • K : E →L[ℝ] E) : E →ₗ[ℝ] E)) ∧
        (∀ f : E, (∃ u : E, u - lam • K u = f) ↔
          ∀ v : E, v - lam • K v = 0 → ⟪v, f⟫_ℝ = 0) ∧
        ∀ f u w : E, u - lam • K u = f →
          (w - lam • K w = f ↔ (w - u) - lam • K (w - u) = 0)) := by
  set N := LinearMap.ker (((1 : E →L[ℝ] E) - lam • K : E →L[ℝ] E) : E →ₗ[ℝ] E) with hN
  have hmemN : ∀ v, v ∈ N ↔ v - lam • K v = 0 := by
    intro v; simp [hN]
  have hS : ∀ x y : E, ⟪K x, y⟫_ℝ = ⟪x, K y⟫_ℝ := fun x y => hsym.isSymmetric x y
  have hdiff : ∀ u w : E, (w - u) - lam • K (w - u) = (w - lam • K w) - (u - lam • K u) := by
    intro u w; rw [map_sub, smul_sub]; abel
  have hlast : ∀ f u w : E, u - lam • K u = f →
      (w - lam • K w = f ↔ (w - u) - lam • K (w - u) = 0) := by
    intro f u w hu
    rw [hdiff, hu, sub_eq_zero]
  by_cases hinj : ∀ v : E, v - lam • K v = 0 → v = 0
  · left
    refine ⟨?_, fun f => ?_⟩
    · rw [eq_bot_iff]
      intro v hv
      rw [hmemN] at hv
      simp [hinj v hv]
    · obtain ⟨u, hu⟩ := fredholm_helper_surj K hK lam hinj f
      refine ⟨u, hu, fun w hw => ?_⟩
      have := hinj _ ((hlast f u w hu).mp hw)
      exact sub_eq_zero.mp this
  · right
    push Not at hinj
    obtain ⟨v₀, hv₀, hv₀ne⟩ := hinj
    have hlam : lam ≠ 0 := by
      rintro rfl
      simp at hv₀
      exact hv₀ne hv₀
    refine ⟨?_, ?_, fun f => ?_, hlast⟩
    · intro hbot
      have : v₀ ∈ N := (hmemN v₀).mpr hv₀
      rw [hbot] at this
      exact hv₀ne ((Submodule.mem_bot ℝ).mp this)
    · have hle : N ≤ Module.End.eigenspace (K : E →ₗ[ℝ] E) lam⁻¹ := by
        intro v hv
        rw [hmemN] at hv
        rw [Module.End.mem_eigenspace_iff]
        have : v = lam • K v := sub_eq_zero.mp hv
        change K v = lam⁻¹ • v
        conv_rhs => rw [this]
        rw [smul_smul, inv_mul_cancel₀ hlam, one_smul]
      have := ContinuousLinearMap.finite_dimensional_eigenspace hK lam⁻¹ (inv_ne_zero hlam)
      exact Submodule.finiteDimensional_of_le hle
    · constructor
      · rintro ⟨u, rfl⟩ v hv
        rw [inner_sub_right, real_inner_smul_right, ← hS, ← real_inner_smul_left,
          ← inner_sub_left, hv, inner_zero_left]
      · intro hf
        set M : Submodule ℝ E := Nᗮ with hM
        have hfM : f ∈ M := by
          rw [Submodule.mem_orthogonal]
          intro v hv
          exact hf v ((hmemN v).mp hv)
        have hKN : ∀ v ∈ N, K v ∈ N := by
          intro v hv
          rw [hmemN] at hv ⊢
          rw [← map_smul, ← map_sub, hv, map_zero]
        have hinv : ∀ m ∈ M, K m ∈ M := by
          intro m hm
          rw [Submodule.mem_orthogonal] at hm ⊢
          intro v hv
          rw [← hS]
          exact hm _ (hKN v hv)
        let K' : M →L[ℝ] M := K.restrict hinv
        have hK' : IsCompactOperator K' := hK.restrict' hinv
        have hinj' : ∀ m : M, m - lam • K' m = 0 → m = 0 := by
          intro m hm
          have hm' : (m : E) - lam • K (m : E) = 0 := by
            have := congrArg (fun z : M => (z : E)) hm
            simpa [K'] using this
          have h1 : (m : E) ∈ N := (hmemN _).mpr hm'
          have h2 : ⟪(m : E), (m : E)⟫_ℝ = 0 :=
            (Submodule.mem_orthogonal _ _).mp m.2 _ h1
          ext
          simpa using h2
        obtain ⟨u, hu⟩ := fredholm_helper_surj K' hK' lam hinj' ⟨f, hfM⟩
        refine ⟨(u : E), ?_⟩
        have := congrArg (fun z : M => (z : E)) hu
        simpa [K'] using this

/-- The Neumann series. If |λ| times the size of K is below 1 (for the tent kernel, whose size is
1/π², this is |λ| < π²), then u - λKu = f has an answer, and every answer is the sum of the rounds
f + λKf + λ²K²f + ⋯. -/
theorem neumann_series_solves {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    [CompleteSpace E] (K : E →L[ℝ] E) (lam : ℝ) (h : |lam| * ‖K‖ < 1) (f : E) :
    (∃ u : E, u - lam • K u = f) ∧
      ∀ u : E, u - lam • K u = f → HasSum (fun r : ℕ => ((lam • K) ^ r) f) u := by
  set A : E →L[ℝ] E := lam • K with hA
  have hAn : ‖A‖ < 1 := by
    calc ‖A‖ ≤ ‖lam‖ * ‖K‖ := ContinuousLinearMap.opNorm_smul_le _ _
      _ = |lam| * ‖K‖ := by rw [Real.norm_eq_abs]
      _ < 1 := h
  have hs := summable_geometric_of_norm_lt_one hAn
  have h1 := mul_neg_geom_series A hAn
  have h2 := geom_series_mul_neg A hAn
  have key : ∀ u : E, u - lam • K u = (1 - A) u := by
    intro u; simp [hA]
  have hsum : HasSum (fun r : ℕ => (A ^ r) f) ((∑' i : ℕ, A ^ i) f) :=
    hs.hasSum.mapL (ContinuousLinearMap.apply ℝ E f)
  refine ⟨⟨(∑' i : ℕ, A ^ i) f, ?_⟩, ?_⟩
  · rw [key, ← mul_apply_eq_comp, h1, one_apply_eq_self]
  · intro u hu
    have : u = (∑' i : ℕ, A ^ i) f := by
      rw [← hu, key, ← mul_apply_eq_comp, h2, one_apply_eq_self]
    rw [this]; exact hsum

/-- The smoothing kernel of the layer: Green's function of -d²/dx² on [0, 1] with zero ends,
K(x, y) = min(x, y) (1 - max(x, y)). -/
noncomputable def tent (x y : ℝ) : ℝ := min x y * (1 - max x y)

/-- The kernel in its own modes. The tent kernel sends sin(nπy) to sin(nπx)/(n²π²): each sine
shape is a mode of K, with eigenvalue 1/λ_n where λ_n = n²π². -/
theorem tent_kernel_mode (n : ℕ) (x : ℝ) (hx : x ∈ Set.Icc (0 : ℝ) 1) :
    ∫ y in (0 : ℝ)..1, tent x y * Real.sin (n * Real.pi * y) =
      Real.sin (n * Real.pi * x) / ((n : ℝ) ^ 2 * Real.pi ^ 2) := by
  obtain ⟨hx0, hx1⟩ := hx
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · simp
  set a : ℝ := n * Real.pi with ha
  have ha0 : a ≠ 0 := by
    have : (0 : ℝ) < n := by exact_mod_cast hn
    positivity
  have hsa : Real.sin a = 0 := Real.sin_nat_mul_pi n
  have hc : Continuous fun y : ℝ => tent x y * Real.sin (a * y) := by
    unfold tent; fun_prop
  have hint : ∀ p q : ℝ, IntervalIntegrable (fun y : ℝ => tent x y * Real.sin (a * y))
      MeasureTheory.volume p q := fun p q => hc.intervalIntegrable p q
  rw [← intervalIntegral.integral_add_adjacent_intervals (hint 0 x) (hint x 1)]
  have e1 : ∫ y in (0 : ℝ)..x, tent x y * Real.sin (a * y) =
      ∫ y in (0 : ℝ)..x, (1 - x) * (y * Real.sin (a * y)) := by
    apply intervalIntegral.integral_congr
    intro y hy
    rw [Set.uIcc_of_le hx0] at hy
    simp only [tent, min_eq_right hy.2, max_eq_left hy.2]
    ring
  have e2 : ∫ y in x..1, tent x y * Real.sin (a * y) =
      ∫ y in x..1, x * ((1 - y) * Real.sin (a * y)) := by
    apply intervalIntegral.integral_congr
    intro y hy
    rw [Set.uIcc_of_le hx1] at hy
    simp only [tent, min_eq_left hy.1, max_eq_right hy.1]
    ring
  rw [e1, e2, intervalIntegral.integral_const_mul, intervalIntegral.integral_const_mul]
  have G : ∀ p q : ℝ, ∫ y in p..q, y * Real.sin (a * y) =
      (Real.sin (a * q) / a ^ 2 - q * Real.cos (a * q) / a) -
        (Real.sin (a * p) / a ^ 2 - p * Real.cos (a * p) / a) := by
    intro p q
    apply intervalIntegral.integral_eq_sub_of_hasDerivAt
    · intro y _
      have h1 : HasDerivAt (fun y => Real.sin (a * y)) (Real.cos (a * y) * a) y := by
        simpa using ((hasDerivAt_id y).const_mul a).sin
      have h2 : HasDerivAt (fun y => Real.cos (a * y)) (-Real.sin (a * y) * a) y := by
        simpa using ((hasDerivAt_id y).const_mul a).cos
      have h3 : HasDerivAt (fun y => Real.sin (a * y) / a ^ 2 - y * Real.cos (a * y) / a)
          (Real.cos (a * y) * a / a ^ 2 - (1 * Real.cos (a * y) + y * (-Real.sin (a * y) * a)) / a)
          y := (h1.div_const (a ^ 2)).sub (((hasDerivAt_id' y).mul h2).div_const a)
      convert h3 using 1
      field_simp
      ring
    · exact (by fun_prop : Continuous fun y : ℝ => y * Real.sin (a * y)).intervalIntegrable _ _
  have H : ∀ p q : ℝ, ∫ y in p..q, (1 - y) * Real.sin (a * y) =
      (-(1 - q) * Real.cos (a * q) / a - Real.sin (a * q) / a ^ 2) -
        (-(1 - p) * Real.cos (a * p) / a - Real.sin (a * p) / a ^ 2) := by
    intro p q
    apply intervalIntegral.integral_eq_sub_of_hasDerivAt
    · intro y _
      have h1 : HasDerivAt (fun y => Real.sin (a * y)) (Real.cos (a * y) * a) y := by
        simpa using ((hasDerivAt_id y).const_mul a).sin
      have h2 : HasDerivAt (fun y => Real.cos (a * y)) (-Real.sin (a * y) * a) y := by
        simpa using ((hasDerivAt_id y).const_mul a).cos
      have h0 : HasDerivAt (fun y : ℝ => -(1 - y)) (-(-1)) y :=
        ((hasDerivAt_id' y).const_sub 1).neg
      have h3 : HasDerivAt (fun y => -(1 - y) * Real.cos (a * y) / a - Real.sin (a * y) / a ^ 2)
          ((-(-1) * Real.cos (a * y) + -(1 - y) * (-Real.sin (a * y) * a)) / a -
            Real.cos (a * y) * a / a ^ 2) y :=
        ((h0.mul h2).div_const a).sub (h1.div_const (a ^ 2))
      convert h3 using 1
      field_simp
      ring
    · exact (by fun_prop : Continuous fun y : ℝ => (1 - y) * Real.sin (a * y)).intervalIntegrable _ _
  rw [G, H]
  simp only [mul_one, mul_zero, hsa, Real.sin_zero, Real.cos_zero]
  field_simp
  ring

-- The kernel is symmetric: K(x, y) = K(y, x).
example (x y : ℝ) : tent x y = tent y x := by
  simp only [tent, min_comm, max_comm]

-- Kernel values from the symbol table and Step 3: K(0.5, 0.5) = 1/4 m, K(0.3, 0.7) = 9/100 m.
example : min (1 / 2 : ℚ) (1 / 2) * (1 - max (1 / 2 : ℚ) (1 / 2)) = 1 / 4 := by norm_num
example : min (3 / 10 : ℚ) (7 / 10) * (1 - max (3 / 10 : ℚ) (7 / 10)) = 9 / 100 := by norm_num

-- Scaling: q = Q₀/k = 25 / (1/4) = 100 K/m², λ = β/k = (5/4) / (1/4) = 5 1/m².
example : (25 : ℚ) / (1 / 4) = 100 := by norm_num
example : ((5 / 4 : ℚ)) / (1 / 4) = 5 := by norm_num

-- Round 0 in the middle: f(1/2) = 100 × (1/2) × (1 - 1/2) / 2 = 25/2 = 12.5 K.
example : (100 : ℚ) * (1 / 2) * (1 - 1 / 2) / 2 = 25 / 2 := by norm_num

-- Round 1 in the middle: 5 × 100 × 5/384 = 625/96 K (about 6.510 K).
example : (5 : ℚ) * 100 * (5 / 384) = 625 / 96 := by norm_num

#print axioms fredholm_alternative_compact_symmetric
#print axioms neumann_series_solves
#print axioms tent_kernel_mode
