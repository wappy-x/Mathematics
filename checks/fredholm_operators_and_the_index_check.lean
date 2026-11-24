-- Fredholm index: a compact change keeps a Fredholm operator Fredholm with the same index, Fredholm means invertible up to compact errors, and the index of a product is the sum of the indices.
import Mathlib.Analysis.Normed.Operator.Fredholm.Open
import Mathlib.Analysis.Normed.Operator.Compact.Basic
import Mathlib.Analysis.RCLike.Basic
import Mathlib.Data.Matrix.Mul
import Mathlib.Analysis.Normed.Operator.Compact.FredholmAlternative
import Mathlib.Analysis.Normed.Operator.Compact.FiniteDimension
import Mathlib.Analysis.Normed.Module.HahnBanach
import Mathlib.Analysis.LocallyConvex.HahnBanach
import Mathlib.Analysis.Normed.Module.FiniteDimension
import Mathlib.Analysis.Normed.Operator.Banach
import Mathlib.Analysis.RCLike.Lemmas
import Mathlib.Topology.Connected.TotallyDisconnected

open ContinuousLinearMap

variable {𝕜 : Type*} [RCLike 𝕜]
  {X Y Z : Type*}
  [NormedAddCommGroup X] [NormedSpace 𝕜 X] [CompleteSpace X]
  [NormedAddCommGroup Y] [NormedSpace 𝕜 Y] [CompleteSpace Y]
  [NormedAddCommGroup Z] [NormedSpace 𝕜 Z] [CompleteSpace Z]

open scoped LinearMap.FiniteRangeSetoid

/-- A bounded operator with finite-dimensional range is compact. -/
theorem fredholmAux_isCompactOperator_of_hasFiniteRange {E F : Type*}
    [NormedAddCommGroup E] [NormedSpace 𝕜 E] [NormedAddCommGroup F] [NormedSpace 𝕜 F]
    (f : E →L[𝕜] F) (hf : (f : E →ₗ[𝕜] F).HasFiniteRange) : IsCompactOperator f := by
  have : FiniteDimensional 𝕜 (LinearMap.range (f : E →ₗ[𝕜] F)) := Module.Finite.iff_fg.mpr hf
  let g : E →L[𝕜] LinearMap.range (f : E →ₗ[𝕜] F) :=
    f.codRestrict _ (fun x => LinearMap.mem_range_self _ x)
  have hg : IsCompactOperator g := isCompactOperator_of_locallyCompactSpace_dom g
  exact hg.clm_comp (LinearMap.range (f : E →ₗ[𝕜] F)).subtypeL

omit [CompleteSpace X] in
/-- For a compact `K`, the kernel of `I + K` is finite dimensional. -/
theorem fredholmAux_finiteDimensional_ker {K : X →L[𝕜] X} (hK : IsCompactOperator K) :
    FiniteDimensional 𝕜 (ContinuousLinearMap.id 𝕜 X + K).ker := by
  set N := (ContinuousLinearMap.id 𝕜 X + K).ker with hN
  have hV : ∀ v ∈ N, (K : X →ₗ[𝕜] X) v ∈ N := by
    intro v hv
    have hv' : v + K v = 0 := by simpa [hN] using hv
    have : K v = -v := by rw [eq_neg_iff_add_eq_zero, add_comm]; exact hv'
    simpa [this] using N.neg_mem hv
  have hcl : IsClosed (N : Set X) := ContinuousLinearMap.isClosed_ker _
  have hR := (hK.restrict hV hcl).neg
  apply FiniteDimensional.of_isCompactOperator_id
  convert hR using 1
  funext x
  apply Subtype.ext
  have hx : (x : X) + K x = 0 := by simpa [hN] using x.2
  simp only [id, Pi.neg_apply, Submodule.coe_neg, LinearMap.coe_restrict_apply,
    ContinuousLinearMap.coe_coe]
  rw [eq_neg_iff_add_eq_zero]; exact hx


/-- Riesz: for a compact `K` on a Banach space, `I + K` is Fredholm. -/
theorem fredholmAux_isFredholm_id_add {K : X →L[𝕜] X} (hK : IsCompactOperator K) :
    (ContinuousLinearMap.id 𝕜 X + K).IsFredholm := by
  suffices H : ∀ n : ℕ, ∀ K : X →L[𝕜] X, IsCompactOperator K →
      Module.finrank 𝕜 (ContinuousLinearMap.id 𝕜 X + K).ker = n →
      (ContinuousLinearMap.id 𝕜 X + K).IsFredholm from H _ K hK rfl
  intro n
  induction n using Nat.strong_induction_on with
  | _ n ih =>
  intro K hK hn
  set S := ContinuousLinearMap.id 𝕜 X + K with hS
  have hfin : FiniteDimensional 𝕜 S.ker := fredholmAux_finiteDimensional_ker hK
  by_cases hsurj : Function.Surjective S
  · exact (S.isQuotientMap hsurj).isFredholm
      (Submodule.ClosedComplemented.of_finiteDimensional _) hfin
  obtain ⟨w, hw⟩ : ∃ w, ∀ x, S x ≠ w := by
    simpa [Function.Surjective] using hsurj
  rcases Nat.eq_zero_or_pos n with hn0 | hnpos
  · exfalso
    have hker : S.ker = ⊥ := Submodule.finrank_eq_zero.mp (hn.trans hn0)
    have hinj : ∀ x, S x = 0 → x = 0 := by
      intro x hx
      have hxk : x ∈ S.ker := hx
      simpa [hker] using hxk
    rcases IsCompactOperator.hasEigenvalue_or_mem_resolventSet (T := -K) hK.neg
      (μ := (1:𝕜)) one_ne_zero with h | h
    · obtain ⟨x, hx⟩ := h.exists_hasEigenvector
      have h1 := Module.End.mem_eigenspace_iff.mp hx.1
      apply hx.2
      apply hinj
      have h2 : -(K x) = x := by simpa using h1
      simp only [hS, add_apply, ContinuousLinearMap.coe_id', id]
      rw [← sub_neg_eq_add, h2, sub_self]
    · rw [spectrum.mem_resolventSet_iff, ContinuousLinearMap.isUnit_iff_bijective] at h
      apply hsurj
      have hSeq : (algebraMap 𝕜 (X →L[𝕜] X)) 1 - -K = S := by
        rw [hS, map_one, sub_neg_eq_add]; rfl
      rw [hSeq] at h
      exact h.2
  · have hne : S.ker ≠ ⊥ := by
      intro h; rw [h, finrank_bot] at hn; omega
    obtain ⟨v, hvN, hv0⟩ := Submodule.exists_mem_ne_zero_of_ne_bot hne
    obtain ⟨φ, -, hφv⟩ := exists_dual_vector 𝕜 v (norm_ne_zero_iff.mpr hv0)
    have hφv0 : φ v ≠ 0 := by
      rw [hφv]; exact_mod_cast norm_ne_zero_iff.mpr hv0
    set F : X →L[𝕜] X := (ContinuousLinearMap.toSpanSingleton 𝕜 w).comp φ with hF
    have hFc : IsCompactOperator F :=
      (isCompactOperator_of_locallyCompactSpace_dom φ).clm_comp
        (ContinuousLinearMap.toSpanSingleton 𝕜 w)
    have hFr : ((-F : X →L[𝕜] X) : X →ₗ[𝕜] X).HasFiniteRange := by
      have h0 : ((φ : X →ₗ[𝕜] 𝕜)).HasFiniteRange := LinearMap.HasFiniteRange.of_isNoetherian_rng
      have h1 := h0.comp_left (-(ContinuousLinearMap.toSpanSingleton 𝕜 w : 𝕜 →ₗ[𝕜] X))
      convert h1 using 1
      ext x
      simp [hF]
    have hK' : IsCompactOperator (K + F) := hK.add hFc
    have key : ∀ x, (ContinuousLinearMap.id 𝕜 X + (K + F)) x = 0 → S x = 0 ∧ φ x = 0 := by
      intro x hx
      have hx' : S x + φ x • w = 0 := by
        rw [hS]
        simpa [hF, add_assoc] using hx
      by_cases hφ : φ x = 0
      · refine ⟨?_, hφ⟩
        simpa [hφ] using hx'
      · exfalso
        apply hw ((-(φ x)⁻¹) • x)
        have hSx : S x = -(φ x • w) := eq_neg_of_add_eq_zero_left hx'
        rw [map_smul, hSx, smul_neg, neg_smul, neg_neg, smul_smul, inv_mul_cancel₀ hφ, one_smul]
    have hlt : (ContinuousLinearMap.id 𝕜 X + (K + F)).ker < S.ker := by
      rw [IsConcreteLE.lt_iff_le_and_exists]
      exact ⟨fun x hx => (key x hx).1, v, hvN, fun hv => hφv0 (key v hv).2⟩
    have hlt' := Submodule.finrank_lt_finrank_of_lt hlt
    have IH := ih _ (lt_of_lt_of_eq hlt' hn) (K + F) hK' rfl
    have := IH.add_hasFiniteRange hFr
    convert this using 1
    rw [hS]
    abel

omit [CompleteSpace X] [CompleteSpace Y] in
/-- A Fredholm operator has a bounded inverse up to finite-rank, hence compact, errors. -/
theorem fredholmAux_exists_parametrix {T : X →L[𝕜] Y} (hT : T.IsFredholm) :
    ∃ B : Y →L[𝕜] X,
      IsCompactOperator (B ∘L T - ContinuousLinearMap.id 𝕜 X) ∧
      IsCompactOperator (T ∘L B - ContinuousLinearMap.id 𝕜 Y) := by
  obtain ⟨v, hv⟩ := hT.exists_isQuasiInverse
  refine ⟨v, fredholmAux_isCompactOperator_of_hasFiniteRange _ ?_,
    fredholmAux_isCompactOperator_of_hasFiniteRange _ ?_⟩
  · have := LinearMap.FiniteRangeSetoid.equiv_iff_hasFiniteRange.mp hv.1
    simpa using this
  · have := LinearMap.FiniteRangeSetoid.equiv_iff_hasFiniteRange.mp hv.2
    simpa using this

/-- An operator with a bounded inverse up to compact errors is Fredholm. -/
theorem fredholmAux_isFredholm_of_parametrix {T : X →L[𝕜] Y} (B : Y →L[𝕜] X)
    (h1 : IsCompactOperator (B ∘L T - ContinuousLinearMap.id 𝕜 X))
    (h2 : IsCompactOperator (T ∘L B - ContinuousLinearMap.id 𝕜 Y)) : T.IsFredholm := by
  have hP : (B ∘L T).IsFredholm := by
    simpa using fredholmAux_isFredholm_id_add h1
  have hQ : (T ∘L B).IsFredholm := by
    simpa using fredholmAux_isFredholm_id_add h2
  obtain ⟨w, hw⟩ := hP.exists_isQuasiInverse
  obtain ⟨w', hw'⟩ := hQ.exists_isQuasiInverse
  have hL : ((w ∘L B : Y →L[𝕜] X) : Y →ₗ[𝕜] X) ∘ₗ (T : X →ₗ[𝕜] Y) ≈ LinearMap.id := hw.1
  have hR : (T : X →ₗ[𝕜] Y) ∘ₗ ((B : Y →ₗ[𝕜] X) ∘ₗ (w' : Y →ₗ[𝕜] Y)) ≈ LinearMap.id := hw'.2
  have hLR : ((w ∘L B : Y →L[𝕜] X) : Y →ₗ[𝕜] X) ≈ (B : Y →ₗ[𝕜] X) ∘ₗ (w' : Y →ₗ[𝕜] Y) := by
    calc ((w ∘L B : Y →L[𝕜] X) : Y →ₗ[𝕜] X)
        = ((w ∘L B : Y →L[𝕜] X) : Y →ₗ[𝕜] X) ∘ₗ LinearMap.id := rfl
      _ ≈ ((w ∘L B : Y →L[𝕜] X) : Y →ₗ[𝕜] X) ∘ₗ
          ((T : X →ₗ[𝕜] Y) ∘ₗ ((B : Y →ₗ[𝕜] X) ∘ₗ (w' : Y →ₗ[𝕜] Y))) :=
          LinearMap.FiniteRangeSetoid.equiv_comp_left (Setoid.symm hR)
      _ = (((w ∘L B : Y →L[𝕜] X) : Y →ₗ[𝕜] X) ∘ₗ (T : X →ₗ[𝕜] Y)) ∘ₗ
          ((B : Y →ₗ[𝕜] X) ∘ₗ (w' : Y →ₗ[𝕜] Y)) := rfl
      _ ≈ LinearMap.id ∘ₗ ((B : Y →ₗ[𝕜] X) ∘ₗ (w' : Y →ₗ[𝕜] Y)) :=
          LinearMap.FiniteRangeSetoid.equiv_comp_right hL
      _ = (B : Y →ₗ[𝕜] X) ∘ₗ (w' : Y →ₗ[𝕜] Y) := rfl
  refine IsFredholm.of_isQuasiInverse (v := w ∘L B) ⟨hL, ?_⟩
  show (T : X →ₗ[𝕜] Y) ∘ₗ ((w ∘L B : Y →L[𝕜] X) : Y →ₗ[𝕜] X) ≈ LinearMap.id
  exact Setoid.trans (LinearMap.FiniteRangeSetoid.equiv_comp_left hLR) hR

/-- A compact change keeps an operator Fredholm. -/
theorem fredholmAux_isFredholm_add_compact {T K : X →L[𝕜] Y} (hT : T.IsFredholm)
    (hK : IsCompactOperator K) : (T + K).IsFredholm := by
  obtain ⟨B, h1, h2⟩ := fredholmAux_exists_parametrix hT
  refine fredholmAux_isFredholm_of_parametrix B ?_ ?_
  · convert h1.add (hK.clm_comp B) using 1
    funext x
    simp only [FunLike.coe_sub, coe_comp, coe_id', Pi.sub_apply, Pi.add_apply, Function.comp_apply,
      id_eq, add_apply, map_add]
    abel
  · convert h2.add (hK.comp_clm B) using 1
    funext x
    simp only [FunLike.coe_sub, coe_comp, coe_id', Pi.sub_apply, Pi.add_apply, Function.comp_apply,
      id_eq, add_apply]
    abel

/-- Compact changes cannot move the index: if `T : X → Y` is a Fredholm operator between
Banach spaces and `K : X → Y` is compact, then `T + K` is again Fredholm and
`ind (T + K) = ind T`, where the index is the kernel dimension minus the dimension of
what the range misses. -/
theorem index_add_compact_eq {T K : X →L[𝕜] Y} (hT : T.IsFredholm)
    (hK : IsCompactOperator K) :
    (T + K).IsFredholm ∧ (T + K).index = T.index := by
  refine ⟨fredholmAux_isFredholm_add_compact hT hK, ?_⟩
  let p : ℝ → (X →L[𝕜] Y) := fun t => T + ((t : 𝕜) • K)
  have hp : ∀ t, (p t).IsFredholm := fun t =>
    fredholmAux_isFredholm_add_compact hT (by simpa using hK.smul (t : 𝕜))
  have hpc : Continuous p := by fun_prop
  have hg : Continuous (fun t => (p t).index) :=
    continuous_iff_continuousAt.mpr fun t => (hp t).index_continuousAt.comp hpc.continuousAt
  have := PreconnectedSpace.constant inferInstance hg (x := 1) (y := 0)
  simpa [p] using this

/-- Atkinson's theorem: a bounded operator `T : X → Y` between Banach spaces is Fredholm
exactly when some bounded `B : Y → X` inverts it up to compact errors, that is,
`B T - I` and `T B - I` are both compact. -/
theorem isFredholm_iff_exists_parametrix (T : X →L[𝕜] Y) :
    T.IsFredholm ↔ ∃ B : Y →L[𝕜] X,
      IsCompactOperator (B ∘L T - ContinuousLinearMap.id 𝕜 X) ∧
      IsCompactOperator (T ∘L B - ContinuousLinearMap.id 𝕜 Y) := by
  refine ⟨fredholmAux_exists_parametrix, ?_⟩
  rintro ⟨B, h1, h2⟩
  exact fredholmAux_isFredholm_of_parametrix B h1 h2

/-- The product rule: if `G : X → Y` and `F : Y → Z` are Fredholm, then so is the product
`F G`, and its index is the sum of the indices, `ind (F G) = ind F + ind G`. -/
theorem index_comp_eq_add {F : Y →L[𝕜] Z} {G : X →L[𝕜] Y} (hF : F.IsFredholm)
    (hG : G.IsFredholm) :
    (F ∘L G).IsFredholm ∧ (F ∘L G).index = F.index + G.index := by
  exact ⟨hF.comp hG, hF.index_comp hG⟩

/-! The card's whole-number worked examples. -/

/-- The `r × c` section of the delay by `k` samples: column `j` has a 1 in row `j + k`. -/
def delaySection (r c k : ℕ) : Matrix (Fin r) (Fin c) ℤ :=
  Matrix.of fun i j => if (i : ℕ) = (j : ℕ) + k then 1 else 0

-- Index of the delay S: 0 killed, 1 missed.
example : (0 : ℤ) - 1 = -1 := by norm_num
-- Index of the advance S*: 1 killed, 0 missed.
example : (1 : ℤ) - 0 = 1 := by norm_num
-- Index of S^3: 0 killed, 3 missed.
example : (0 : ℤ) - 3 = -3 := by norm_num
-- Product rule: the advance twice after S^3 has index +2 + (-3) = -1, not +2 × (-3) = -6.
example : (2 : ℤ) + (-3) = -1 ∧ (2 : ℤ) * (-3) = -6 := by norm_num
-- Step 1: a 7-by-6 matrix of any rank r ≤ 6 has index (6 - r) - (7 - r) = 6 - 7 = -1.
example : ∀ r : ℤ, (6 - r) - (7 - r) = -1 := by intro r; ring
-- The advance twice after the delay by three is exactly the delay by one (7 × 9 times 9 × 6).
example : (delaySection 9 7 2).transpose * delaySection 9 6 3 = delaySection 7 6 1 := by
  decide
-- Parametrix: the advance after the delay is the identity on the 7 × 6 section.
example : (delaySection 7 6 1).transpose * delaySection 7 6 1 = 1 := by decide

#print axioms fredholmAux_isCompactOperator_of_hasFiniteRange
#print axioms fredholmAux_finiteDimensional_ker
#print axioms fredholmAux_isFredholm_id_add
#print axioms fredholmAux_exists_parametrix
#print axioms fredholmAux_isFredholm_of_parametrix
#print axioms fredholmAux_isFredholm_add_compact
#print axioms index_add_compact_eq
#print axioms isFredholm_iff_exists_parametrix
#print axioms index_comp_eq_add
