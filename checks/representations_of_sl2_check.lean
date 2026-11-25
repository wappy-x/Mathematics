-- Representations of sl(2): every finite-dimensional irreducible representation of sl(2, ℂ) is a ladder of weights n, n - 2, ..., -n, its Casimir is n(n + 2), and two ladders multiply into ladders by the Clebsch-Gordan rule.
import Mathlib.Algebra.Lie.Classical
import Mathlib.Algebra.Lie.Semisimple.Defs
import Mathlib.Algebra.Lie.Sl2
import Mathlib.Algebra.Lie.TensorProduct
import Mathlib.Algebra.DirectSum.Module
import Mathlib.LinearAlgebra.Dimension.Finrank
import Mathlib.LinearAlgebra.FiniteDimensional.Defs
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Basic.Complex.Basic
import Mathlib.Analysis.Complex.Polynomial.Basic

open LieAlgebra.SpecialLinear
open scoped TensorProduct

/-! `sl2` is Mathlib's `sl (Fin 2) ℂ`, the 2 by 2 complex matrices of trace zero with the
bracket `⁅A, B⁆ = A * B - B * A`. A representation of it is a Lie module `M`; the bracket
`⁅X, m⁆` is the matrix of `X` acting on the vector `m`. On a tensor product `M ⊗[ℂ] N`,
Mathlib lets `X` act as `X ⊗ 1 + 1 ⊗ X`, the card's rule for the algebra. -/

/-- The card's `sl(2)`: 2 by 2 complex matrices of trace zero. -/
abbrev sl2 : Type := sl (Fin 2) ℂ

/-- The card's `H`, the matrix with diagonal `1, -1`. -/
noncomputable def H : sl2 := singleSubSingle (0 : Fin 2) 1 (1 : ℂ)

/-- The card's `E`, the matrix with a single `1` in row 0, column 1. -/
noncomputable def E : sl2 := single (0 : Fin 2) 1 (by decide) (1 : ℂ)

/-- The card's `F`, the matrix with a single `1` in row 1, column 0. -/
noncomputable def F : sl2 := single (1 : Fin 2) 0 (by decide) (1 : ℂ)

lemma sl2_triple : IsSl2Triple H E F where
  h_ne_zero := by
    intro h
    have := congrArg (fun x : sl2 => x.val 0 0) h
    simp [H, Matrix.single] at this
  lie_e_f := by
    apply Subtype.ext
    ext i j
    fin_cases i <;> fin_cases j <;>
      simp [H, E, F, Ring.lie_def, Matrix.single, Matrix.mul_apply]
  lie_h_e_nsmul := by
    apply Subtype.ext
    ext i j
    fin_cases i <;> fin_cases j <;>
      norm_num [H, E, Ring.lie_def, Matrix.single, Matrix.mul_apply]
  lie_h_f_nsmul := by
    apply Subtype.ext
    ext i j
    fin_cases i <;> fin_cases j <;>
      norm_num [H, F, Ring.lie_def, Matrix.single, Matrix.mul_apply]

lemma sl2_decomp (x : sl2) : x = x.val 0 0 • H + x.val 0 1 • E + x.val 1 0 • F := by
  have hx : Matrix.trace x.val = 0 := x.prop
  rw [Matrix.trace_fin_two] at hx
  apply Subtype.ext
  ext i j
  fin_cases i <;> fin_cases j <;> simp [H, E, F, Matrix.single]
  linear_combination hx

#print axioms sl2_triple
#print axioms sl2_decomp

section ladder

open LieModule

variable {V : Type*} [AddCommGroup V] [Module ℂ V] [LieRingModule sl2 V] [LieModule ℂ sl2 V]

lemma exists_lieSubmodule_of_HEF (S : Submodule ℂ V) (hH : ∀ v ∈ S, ⁅H, v⁆ ∈ S)
    (hE : ∀ v ∈ S, ⁅E, v⁆ ∈ S) (hF : ∀ v ∈ S, ⁅F, v⁆ ∈ S) :
    ∃ W : LieSubmodule ℂ sl2 V, (W : Submodule ℂ V) = S :=
  ⟨{ S with
      lie_mem := fun {x v} hv => by
        rw [sl2_decomp x, add_lie, add_lie, smul_lie, smul_lie, smul_lie]
        exact S.add_mem (S.add_mem (S.smul_mem _ (hH v hv)) (S.smul_mem _ (hE v hv)))
          (S.smul_mem _ (hF v hv)) }, rfl⟩

lemma ladder_eq_zero [FiniteDimensional ℂ V] {w : V} {k : ℕ}
    (P : sl2_triple.HasPrimitiveVectorWith w (k : ℂ)) (j : ℕ) (hj : k < j) :
    (toEnd ℂ sl2 V F ^ j) w = 0 := by
  obtain ⟨t, rfl⟩ := Nat.exists_eq_add_of_lt hj
  rw [show k + t + 1 = t + (k + 1) by ring, pow_add, Module.End.mul_apply,
    P.pow_toEnd_f_eq_zero_of_eq_nat rfl, map_zero]

lemma ladder_linIndep {w : V} {k : ℕ} (P : sl2_triple.HasPrimitiveVectorWith w (k : ℂ)) :
    LinearIndependent ℂ (fun j : Fin (k + 1) => (toEnd ℂ sl2 V F ^ (j : ℕ)) w) := by
  refine (toEnd ℂ sl2 V H).eigenvectors_linearIndependent'
    (fun j : Fin (k + 1) => (k : ℂ) - 2 * ((j : ℕ) : ℂ)) ?_ _ ?_
  · intro i j hij
    simp only [sub_right_inj, mul_eq_mul_left_iff, Nat.cast_inj] at hij
    exact Fin.ext (by simpa using hij)
  · intro j
    rw [Module.End.hasEigenvector_iff]
    refine ⟨?_, P.pow_toEnd_f_ne_zero_of_eq_nat rfl (Nat.lt_succ_iff.mp j.2)⟩
    rw [Module.End.mem_eigenspace_iff, toEnd_apply_apply, P.lie_h_pow_toEnd_f]

lemma ladder_mem_span [FiniteDimensional ℂ V] {w : V} {k : ℕ}
    (P : sl2_triple.HasPrimitiveVectorWith w (k : ℂ)) (j : ℕ) :
    (toEnd ℂ sl2 V F ^ j) w ∈
      Submodule.span ℂ (Set.range fun j : Fin (k + 1) => (toEnd ℂ sl2 V F ^ (j : ℕ)) w) := by
  by_cases hj : j ≤ k
  · exact Submodule.subset_span ⟨⟨j, Nat.lt_succ_of_le hj⟩, rfl⟩
  · rw [ladder_eq_zero P j (by omega)]
    exact Submodule.zero_mem _

lemma exists_ladder_lieSubmodule [FiniteDimensional ℂ V] {w : V} {k : ℕ}
    (P : sl2_triple.HasPrimitiveVectorWith w (k : ℂ)) :
    ∃ W : LieSubmodule ℂ sl2 V, (W : Submodule ℂ V) =
      Submodule.span ℂ (Set.range fun j : Fin (k + 1) => (toEnd ℂ sl2 V F ^ (j : ℕ)) w) := by
  set S := Submodule.span ℂ (Set.range fun j : Fin (k + 1) => (toEnd ℂ sl2 V F ^ (j : ℕ)) w)
  have key : ∀ X : sl2, (∀ j : ℕ, ⁅X, (toEnd ℂ sl2 V F ^ j) w⁆ ∈ S) → ∀ v ∈ S, ⁅X, v⁆ ∈ S := by
    intro X h v hv
    have : S ≤ S.comap (toEnd ℂ sl2 V X) :=
      Submodule.span_le.mpr (Set.range_subset_iff.mpr fun j => h j)
    exact this hv
  apply exists_lieSubmodule_of_HEF
  · refine key H fun j => ?_
    rw [P.lie_h_pow_toEnd_f]
    exact S.smul_mem _ (ladder_mem_span P j)
  · refine key E fun j => ?_
    rcases j with _ | j
    · simp only [pow_zero, Module.End.one_apply, P.lie_e]
      exact S.zero_mem
    · rw [P.lie_e_pow_succ_toEnd_f]
      exact S.smul_mem _ (ladder_mem_span P j)
  · refine key F fun j => ?_
    rw [P.lie_f_pow_toEnd_f]
    exact ladder_mem_span P (j + 1)

lemma irreducible_of_primitive [FiniteDimensional ℂ V] {w : V} {k : ℕ}
    (P : sl2_triple.HasPrimitiveVectorWith w (k : ℂ)) (hdim : Module.finrank ℂ V = k + 1) :
    LieModule.IsIrreducible ℂ sl2 V := by
  have li := ladder_linIndep P
  let b := basisOfLinearIndependentOfCardEqFinrank li (by simp [hdim])
  have hb : ∀ j, b j = (toEnd ℂ sl2 V F ^ (j : ℕ)) w := fun j => by
    simp [b, coe_basisOfLinearIndependentOfCardEqFinrank]
  have : Nontrivial V := ⟨⟨w, 0, P.ne_zero⟩⟩
  refine LieModule.IsIrreducible.mk fun N hN => ?_
  have : Nontrivial N := (LieSubmodule.nontrivial_iff_ne_bot ℂ sl2 V).mpr hN
  have : IsTriangularizable ℂ sl2 V := inferInstance
  have : FiniteDimensional ℂ N := inferInstance
  have : IsTriangularizable ℂ sl2 N := inferInstance
  obtain ⟨μ, u, hu0, Pu⟩ := sl2_triple.exists_hasPrimitiveVectorWith (R := ℂ) (M := N)
  have huH : ⁅H, (u : V)⁆ = μ • (u : V) := by
    rw [← LieSubmodule.coe_bracket, Pu.lie_h]; rfl
  have huE : ⁅E, (u : V)⁆ = 0 := by
    rw [← LieSubmodule.coe_bracket, Pu.lie_e]; rfl
  have hu0' : (u : V) ≠ 0 := by simpa using hu0
  have hrepr : ∀ x : V, ∀ j : Fin (k + 1),
      b.repr ⁅H, x⁆ j = ((k : ℂ) - 2 * ((j : ℕ) : ℂ)) * b.repr x j := by
    intro x j
    conv_lhs => rw [← b.sum_repr x]
    rw [lie_sum]
    simp_rw [lie_smul, hb, P.lie_h_pow_toEnd_f, smul_smul, ← hb]
    simp [Finsupp.single_apply, mul_comm]
  have hcoord : ∀ j : Fin (k + 1), ((k : ℂ) - 2 * ((j : ℕ) : ℂ) - μ) * b.repr (u : V) j = 0 := by
    intro j
    have := hrepr (u : V) j
    rw [huH, map_smul, Finsupp.smul_apply, smul_eq_mul] at this
    linear_combination -this
  obtain ⟨j0, hj0⟩ : ∃ j0, b.repr (u : V) j0 ≠ 0 := by
    by_contra! h
    exact hu0' (b.repr.injective (by ext j; simp [h j]))
  have hμ : μ = (k : ℂ) - 2 * ((j0 : ℕ) : ℂ) := by
    have := hcoord j0
    rw [mul_eq_zero, sub_eq_zero] at this
    exact (this.resolve_right hj0).symm
  have hu_eq : (u : V) = b.repr (u : V) j0 • (toEnd ℂ sl2 V F ^ (j0 : ℕ)) w := by
    rw [← hb]
    apply b.repr.injective
    ext j
    rw [map_smul, b.repr_self, Finsupp.smul_apply, Finsupp.single_apply]
    split_ifs with h
    · subst h; simp
    · have := hcoord j
      rw [hμ, mul_eq_zero] at this
      rcases this with h' | h'
      · exfalso
        apply h
        have : ((j : ℕ) : ℂ) = ((j0 : ℕ) : ℂ) := by linear_combination -h' / 2
        exact Fin.ext (by exact_mod_cast this.symm)
      · simp [h']
  have hj00 : (j0 : ℕ) = 0 := by
    by_contra hne
    obtain ⟨j', hj'⟩ := Nat.exists_eq_succ_of_ne_zero hne
    have hj'k : j' < k := by have := j0.2; omega
    rw [hu_eq, lie_smul, hj', P.lie_e_pow_succ_toEnd_f] at huE
    refine smul_ne_zero hj0 (smul_ne_zero ?_ (P.pow_toEnd_f_ne_zero_of_eq_nat rfl hj'k.le)) huE
    refine mul_ne_zero (Nat.cast_add_one_ne_zero j') ?_
    rw [sub_ne_zero]
    exact_mod_cast hj'k.ne'
  have hwN : w ∈ N := by
    have : w = (b.repr (u : V) j0)⁻¹ • (u : V) := by
      set c := b.repr (u : V) j0
      rw [hu_eq, smul_smul, inv_mul_cancel₀ hj0, one_smul, hj00, pow_zero, Module.End.one_apply]
    rw [this]
    exact N.smul_mem _ u.2
  have hvN : ∀ j : ℕ, (toEnd ℂ sl2 V F ^ j) w ∈ N := by
    intro j
    induction j with
    | zero => simpa using hwN
    | succ j ih =>
      rw [← P.lie_f_pow_toEnd_f]
      exact N.lie_mem ih
  rw [eq_top_iff]
  rintro x -
  have hspan : Submodule.span ℂ (Set.range b) ≤ (N : Submodule ℂ V) :=
    Submodule.span_le.mpr (Set.range_subset_iff.mpr fun j => by rw [hb]; exact hvN j)
  exact hspan (b.mem_span x)

end ladder

section ladder2

open LieModule

variable {V : Type*} [AddCommGroup V] [Module ℂ V] [LieRingModule sl2 V] [LieModule ℂ sl2 V]

lemma exists_irreducible_ladder [FiniteDimensional ℂ V] {w : V} {k : ℕ}
    (P : sl2_triple.HasPrimitiveVectorWith w (k : ℂ)) :
    ∃ W : LieSubmodule ℂ sl2 V, w ∈ W ∧ LieModule.IsIrreducible ℂ sl2 W ∧
      Module.finrank ℂ W = k + 1 := by
  obtain ⟨W, hW⟩ := exists_ladder_lieSubmodule P
  have hwW : w ∈ W := by
    rw [← LieSubmodule.mem_toSubmodule, hW]
    exact Submodule.subset_span ⟨0, by simp⟩
  have hdim : Module.finrank ℂ W = k + 1 := by
    have : Module.finrank ℂ W = Module.finrank ℂ (W : Submodule ℂ V) := rfl
    rw [this, hW, finrank_span_eq_card (ladder_linIndep P), Fintype.card_fin]
  refine ⟨W, hwW, ?_, hdim⟩
  let w' : W := ⟨w, hwW⟩
  have P' : sl2_triple.HasPrimitiveVectorWith w' (k : ℂ) :=
    { ne_zero := fun h => P.ne_zero (congrArg Subtype.val h)
      lie_h := Subtype.ext (by simp [w', P.lie_h])
      lie_e := Subtype.ext (by simp [w', P.lie_e]) }
  exact irreducible_of_primitive P' hdim

end ladder2

section tensor

open LieModule TensorProduct

variable {M N : Type*} [AddCommGroup M] [Module ℂ M] [LieRingModule sl2 M] [LieModule ℂ sl2 M]
  [AddCommGroup N] [Module ℂ N] [LieRingModule sl2 N] [LieModule ℂ sl2 N]

lemma exists_primitive_tensor [FiniteDimensional ℂ M] [FiniteDimensional ℂ N] (m n : ℕ)
    (a : ℕ → M) (b : ℕ → N)
    (ba : Module.Basis (Fin (m + 1)) ℂ M) (hba : ∀ i : Fin (m + 1), ba i = a i)
    (bb : Module.Basis (Fin (n + 1)) ℂ N) (hbb : ∀ i : Fin (n + 1), bb i = b i)
    (haH : ∀ i : ℕ, ⁅H, a i⁆ = ((m : ℂ) - 2 * i) • a i)
    (hbH : ∀ i : ℕ, ⁅H, b i⁆ = ((n : ℂ) - 2 * i) • b i)
    (haE0 : ⁅E, a 0⁆ = 0) (hbE0 : ⁅E, b 0⁆ = 0)
    (haE : ∀ i : ℕ, ⁅E, a (i + 1)⁆ = (((i : ℂ) + 1) * ((m : ℂ) - i)) • a i)
    (hbE : ∀ i : ℕ, ⁅E, b (i + 1)⁆ = (((i : ℂ) + 1) * ((n : ℂ) - i)) • b i)
    (s : ℕ) (hsm : s ≤ m) (hsn : s ≤ n) :
    ∃ w : M ⊗[ℂ] N, w ≠ 0 ∧ ⁅H, w⁆ = ((m : ℂ) + n - 2 * s) • w ∧ ⁅E, w⁆ = 0 := by
  classical
  let K : Submodule ℂ (M ⊗[ℂ] N) :=
    Submodule.span ℂ ↑((Finset.antidiagonal s).image fun p => a p.1 ⊗ₜ[ℂ] b p.2)
  let T : Submodule ℂ (M ⊗[ℂ] N) :=
    Submodule.span ℂ ↑((Finset.range s).image fun i => a i ⊗ₜ[ℂ] b (s - 1 - i))
  have hT : ∀ i j, i + j + 1 = s → a i ⊗ₜ[ℂ] b j ∈ T := by
    intro i j hij
    apply Submodule.subset_span
    simp only [Finset.coe_image, Set.mem_image, Finset.mem_coe, Finset.mem_range]
    exact ⟨i, by omega, by rw [show s - 1 - i = j by omega]⟩
  have hmaps : ∀ x ∈ K, toEnd ℂ sl2 (M ⊗[ℂ] N) E x ∈ T := by
    intro x hx
    have : K ≤ T.comap (toEnd ℂ sl2 (M ⊗[ℂ] N) E) := by
      rw [Submodule.span_le]
      simp only [Finset.coe_image, Set.image_subset_iff]
      rintro ⟨i, j⟩ hij
      simp only [Finset.mem_coe, Finset.mem_antidiagonal] at hij
      simp only [Set.mem_preimage, SetLike.mem_coe, Submodule.mem_comap, toEnd_apply_apply,
        TensorProduct.LieModule.lie_tmul_right]
      refine T.add_mem ?_ ?_
      · rcases i with _ | i
        · rw [haE0, TensorProduct.zero_tmul]; exact T.zero_mem
        · rw [haE, ← TensorProduct.smul_tmul']; exact T.smul_mem _ (hT i j (by omega))
      · rcases j with _ | j
        · rw [hbE0, TensorProduct.tmul_zero]; exact T.zero_mem
        · rw [hbE, TensorProduct.tmul_smul]; exact T.smul_mem _ (hT i j (by omega))
    exact this hx
  have hTdim : Module.finrank ℂ T ≤ s := by
    refine (finrank_span_finset_le_card _).trans ?_
    exact Finset.card_image_le.trans (by simp)
  let g : Fin (s + 1) → M ⊗[ℂ] N := fun j => a j ⊗ₜ[ℂ] b (s - j)
  have hg : LinearIndependent ℂ g := by
    have := (ba.tensorProduct bb).linearIndependent.comp
      (fun j : Fin (s + 1) => ((⟨j, by omega⟩ : Fin (m + 1)), (⟨s - j, by omega⟩ : Fin (n + 1))))
      (by
        intro i j h
        simp only [Prod.mk.injEq, Fin.mk.injEq] at h
        exact Fin.ext h.1)
    convert this using 1
    ext j
    simp [g, Module.Basis.tensorProduct_apply, hba, hbb]
  have hgK : Submodule.span ℂ (Set.range g) ≤ K := by
    rw [Submodule.span_le]
    rintro _ ⟨j, rfl⟩
    apply Submodule.subset_span
    simp only [Finset.coe_image, Set.mem_image, Finset.mem_coe, Finset.mem_antidiagonal]
    exact ⟨((j : ℕ), s - j), by omega, rfl⟩
  have hKdim : s + 1 ≤ Module.finrank ℂ K := by
    have := Submodule.finrank_mono hgK
    rwa [finrank_span_eq_card hg, Fintype.card_fin] at this
  let f : K →ₗ[ℂ] T := (toEnd ℂ sl2 (M ⊗[ℂ] N) E).restrict hmaps
  have hker : LinearMap.ker f ≠ ⊥ := LinearMap.ker_ne_bot_of_finrank_lt (by omega)
  obtain ⟨x, hx, hx0⟩ := (Submodule.ne_bot_iff _).mp hker
  have hKeig : K ≤ (toEnd ℂ sl2 (M ⊗[ℂ] N) H).eigenspace ((m : ℂ) + n - 2 * s) := by
    rw [Submodule.span_le]
    simp only [Finset.coe_image, Set.image_subset_iff]
    rintro ⟨i, j⟩ hij
    simp only [Finset.mem_coe, Finset.mem_antidiagonal] at hij
    rw [Set.mem_preimage, SetLike.mem_coe, Module.End.mem_eigenspace_iff, toEnd_apply_apply,
      TensorProduct.LieModule.lie_tmul_right, haH, hbH, ← TensorProduct.smul_tmul',
      TensorProduct.tmul_smul, ← add_smul]
    congr 1
    have : (i : ℂ) + j = s := by exact_mod_cast hij
    linear_combination -2 * this
  refine ⟨x, fun h => hx0 (Subtype.ext h), ?_, ?_⟩
  · exact Module.End.mem_eigenspace_iff.mp (hKeig x.2)
  · have := congrArg Subtype.val (LinearMap.mem_ker.mp hx)
    simpa [f] using this

end tensor

lemma cg_sum_aux (p : ℕ) : ∀ q : ℕ, p ≤ q →
    ∑ i ∈ Finset.range (p + 1), (p + q - 2 * i + 1) = (p + 1) * (q + 1) := by
  induction p with
  | zero => intro q _; simp
  | succ p ih =>
    intro q hq
    obtain ⟨q', rfl⟩ := Nat.exists_eq_add_of_lt (show 0 < q by omega)
    rw [Finset.sum_range_succ']
    have h := ih q' (by omega)
    rw [Finset.sum_congr rfl (g := fun i => p + q' - 2 * i + 1) (fun i hi => by
      simp only [Finset.mem_range] at hi
      omega), h]
    ring_nf
    omega

lemma cg_sum (m n : ℕ) :
    ∑ i : Fin (min m n + 1), (m + n - 2 * (i : ℕ) + 1) = (m + 1) * (n + 1) := by
  rw [Fin.sum_univ_eq_sum_range (fun i => m + n - 2 * i + 1)]
  rcases le_total m n with h | h
  · rw [min_eq_left h]
    exact cg_sum_aux m n h
  · rw [min_eq_right h, add_comm m n, mul_comm]
    exact cg_sum_aux n m h

#print axioms exists_lieSubmodule_of_HEF
#print axioms ladder_eq_zero
#print axioms ladder_linIndep
#print axioms ladder_mem_span
#print axioms exists_ladder_lieSubmodule
#print axioms irreducible_of_primitive
#print axioms exists_irreducible_ladder
#print axioms exists_primitive_tensor
#print axioms cg_sum_aux
#print axioms cg_sum

section

variable (M : Type*) [AddCommGroup M] [Module ℂ M] [LieRingModule sl2 M] [LieModule ℂ sl2 M]

/-- The ladder: every finite-dimensional irreducible representation of `sl(2)` has a whole
number `n` and a basis `v_0, ..., v_n` with `H v_k = (n - 2k) v_k`, `F v_k = v_(k+1)`,
`E v_0 = 0` and `E v_(k+1) = (k + 1)(n - k) v_k`, where `v_(n+1) = 0`. So its weights are
`n, n - 2, ..., -n` and its dimension is `n + 1`. -/
theorem irreducible_rep_is_weight_ladder [FiniteDimensional ℂ M]
    [LieModule.IsIrreducible ℂ sl2 M] :
    ∃ (n : ℕ) (v : ℕ → M),
      (∃ b : Module.Basis (Fin (n + 1)) ℂ M, ∀ k : Fin (n + 1), b k = v k) ∧
      (∀ k, n < k → v k = 0) ∧
      (∀ k : ℕ, ⁅H, v k⁆ = ((n : ℂ) - 2 * k) • v k) ∧
      (∀ k : ℕ, ⁅F, v k⁆ = v (k + 1)) ∧
      ⁅E, v 0⁆ = 0 ∧
      (∀ k : ℕ, ⁅E, v (k + 1)⁆ = (((k : ℂ) + 1) * ((n : ℂ) - k)) • v k) := by
  have : Nontrivial M := by
    by_contra h
    rw [not_nontrivial_iff_subsingleton] at h
    apply (bot_ne_top : (⊥ : LieSubmodule ℂ sl2 M) ≠ ⊤)
    ext x
    simp [Subsingleton.elim x 0]
  obtain ⟨μ, w, hw, P⟩ := sl2_triple.exists_hasPrimitiveVectorWith (R := ℂ) (M := M)
  obtain ⟨n, rfl⟩ := P.exists_nat
  obtain ⟨W, hW⟩ := exists_ladder_lieSubmodule P
  have hWtop : W = ⊤ := by
    refine (IsSimpleOrder.eq_bot_or_eq_top W).resolve_left fun h => hw ?_
    have : w ∈ W := by
      rw [← LieSubmodule.mem_toSubmodule, hW]
      exact Submodule.subset_span ⟨0, by simp⟩
    rw [h] at this
    exact (LieSubmodule.mem_bot w).mp this
  have hspan : ⊤ ≤ Submodule.span ℂ
      (Set.range fun j : Fin (n + 1) => (LieModule.toEnd ℂ sl2 M F ^ (j : ℕ)) w) := by
    rw [← hW, hWtop, LieSubmodule.top_toSubmodule]
  exact ⟨n, fun j => (LieModule.toEnd ℂ sl2 M F ^ j) w,
    ⟨Module.Basis.mk (ladder_linIndep P) hspan, fun j => Module.Basis.mk_apply _ _ _⟩,
    fun j hj => ladder_eq_zero P j hj, P.lie_h_pow_toEnd_f, P.lie_f_pow_toEnd_f, P.lie_e,
    P.lie_e_pow_succ_toEnd_f⟩

/-- The Casimir: on an irreducible representation of dimension `n + 1`, the combination
`C = H^2 + 2EF + 2FE` multiplies every vector by the single number `n(n + 2)`. -/
theorem casimir_eq_on_irreducible [FiniteDimensional ℂ M] [LieModule.IsIrreducible ℂ sl2 M]
    (n : ℕ) (hn : Module.finrank ℂ M = n + 1) (m : M) :
    ⁅H, ⁅H, m⁆⁆ + (2 : ℂ) • ⁅E, ⁅F, m⁆⁆ + (2 : ℂ) • ⁅F, ⁅E, m⁆⁆ = ((n : ℂ) * (n + 2)) • m := by
  obtain ⟨n', v, ⟨b, hb⟩, -, hH, hF, hE0, hE⟩ := irreducible_rep_is_weight_ladder M
  have hn' : n' = n := by
    have := Module.finrank_eq_card_basis b
    simp only [Fintype.card_fin] at this
    omega
  subst hn'
  let C : Module.End ℂ M := LieModule.toEnd ℂ sl2 M H * LieModule.toEnd ℂ sl2 M H +
    (2 : ℂ) • (LieModule.toEnd ℂ sl2 M E * LieModule.toEnd ℂ sl2 M F) +
    (2 : ℂ) • (LieModule.toEnd ℂ sl2 M F * LieModule.toEnd ℂ sl2 M E)
  have hC : C = ((n' : ℂ) * (n' + 2)) • LinearMap.id := by
    apply b.ext
    rintro ⟨j, hj⟩
    simp only [C, LinearMap.add_apply, LinearMap.smul_apply, Module.End.mul_apply,
      LieModule.toEnd_apply_apply, LinearMap.id_apply, hb]
    rw [hF, hE, hH, lie_smul, hH, smul_smul]
    rcases j with _ | j
    · rw [hE0, lie_zero, smul_zero, add_zero, smul_smul, ← add_smul]
      congr 1
      push_cast
      ring
    · rw [hE, lie_smul, hF, smul_smul, smul_smul, ← add_smul, ← add_smul]
      congr 1
      push_cast
      ring
  have := LinearMap.congr_fun hC m
  simpa [C] using this

/-- Clebsch-Gordan: if `M` and `N` are irreducible of dimensions `m + 1` and `n + 1`, then
`M ⊗ N` is the direct sum of one irreducible piece each of dimension `m + n - 2i + 1`,
for `i = 0, 1, ..., min(m, n)`: top weights `m + n, m + n - 2, ..., |m - n|`. -/
theorem clebsch_gordan (N : Type*) [AddCommGroup N] [Module ℂ N] [LieRingModule sl2 N]
    [LieModule ℂ sl2 N] [FiniteDimensional ℂ M] [FiniteDimensional ℂ N]
    [LieModule.IsIrreducible ℂ sl2 M] [LieModule.IsIrreducible ℂ sl2 N]
    (m n : ℕ) (hm : Module.finrank ℂ M = m + 1) (hn : Module.finrank ℂ N = n + 1) :
    ∃ W : Fin (min m n + 1) → LieSubmodule ℂ sl2 (M ⊗[ℂ] N),
      DirectSum.IsInternal (fun i => (W i : Submodule ℂ (M ⊗[ℂ] N))) ∧
      ∀ i, LieModule.IsIrreducible ℂ sl2 (W i) ∧
        Module.finrank ℂ (W i) = m + n - 2 * (i : ℕ) + 1 := by
  classical
  obtain ⟨m', a, ⟨ba, hba⟩, -, haH, -, haE0, haE⟩ := irreducible_rep_is_weight_ladder M
  obtain ⟨n', b, ⟨bb, hbb⟩, -, hbH, -, hbE0, hbE⟩ := irreducible_rep_is_weight_ladder N
  have hm' : m' = m := by
    have := Module.finrank_eq_card_basis ba
    simp only [Fintype.card_fin] at this
    omega
  have hn' : n' = n := by
    have := Module.finrank_eq_card_basis bb
    simp only [Fintype.card_fin] at this
    omega
  subst hm' hn'
  have hW : ∀ s : Fin (min m' n' + 1), ∃ W : LieSubmodule ℂ sl2 (M ⊗[ℂ] N),
      LieModule.IsIrreducible ℂ sl2 W ∧ Module.finrank ℂ W = m' + n' - 2 * (s : ℕ) + 1 := by
    intro s
    have hs := s.2
    have hsm : (s : ℕ) ≤ m' := by have := min_le_left m' n'; omega
    have hsn : (s : ℕ) ≤ n' := by have := min_le_right m' n'; omega
    obtain ⟨w, hw0, hwH, hwE⟩ := exists_primitive_tensor m' n' a b ba hba bb hbb haH hbH haE0
      hbE0 haE hbE s hsm hsn
    have P : sl2_triple.HasPrimitiveVectorWith w (((m' + n' - 2 * (s : ℕ) : ℕ) : ℂ)) :=
      { ne_zero := hw0
        lie_h := by
          rw [hwH]
          congr 1
          push_cast [show 2 * (s : ℕ) ≤ m' + n' by omega]
          ring
        lie_e := hwE }
    obtain ⟨W, -, hirr, hdim⟩ := exists_irreducible_ladder P
    exact ⟨W, hirr, hdim⟩
  choose W hWirr hWdim using hW
  refine ⟨W, ?_, fun i => ⟨hWirr i, hWdim i⟩⟩
  let C : Module.End ℂ (M ⊗[ℂ] N) :=
    LieModule.toEnd ℂ sl2 (M ⊗[ℂ] N) H * LieModule.toEnd ℂ sl2 (M ⊗[ℂ] N) H +
    (2 : ℂ) • (LieModule.toEnd ℂ sl2 (M ⊗[ℂ] N) E * LieModule.toEnd ℂ sl2 (M ⊗[ℂ] N) F) +
    (2 : ℂ) • (LieModule.toEnd ℂ sl2 (M ⊗[ℂ] N) F * LieModule.toEnd ℂ sl2 (M ⊗[ℂ] N) E)
  let lam : Fin (min m' n' + 1) → ℂ := fun s =>
    (((m' + n' - 2 * (s : ℕ) : ℕ) : ℂ)) * ((((m' + n' - 2 * (s : ℕ) : ℕ) : ℂ)) + 2)
  have hle : ∀ s, (W s : Submodule ℂ (M ⊗[ℂ] N)) ≤ C.eigenspace (lam s) := by
    intro s x hx
    have := hWirr s
    rw [Module.End.mem_eigenspace_iff]
    have := congrArg Subtype.val
      (casimir_eq_on_irreducible (W s) (m' + n' - 2 * (s : ℕ)) (hWdim s) ⟨x, hx⟩)
    simpa [C, lam] using this
  have hlam : Function.Injective lam := by
    intro s t hst
    simp only [lam] at hst
    have h1 : (m' + n' - 2 * (s : ℕ)) * ((m' + n' - 2 * (s : ℕ)) + 2) =
        (m' + n' - 2 * (t : ℕ)) * ((m' + n' - 2 * (t : ℕ)) + 2) := by
      exact_mod_cast hst
    have h2 : m' + n' - 2 * (s : ℕ) = m' + n' - 2 * (t : ℕ) := by
      by_contra hne
      rcases Nat.lt_or_gt_of_ne hne with h | h <;> nlinarith
    have := s.2
    have := t.2
    have := min_le_left m' n'
    exact Fin.ext (by omega)
  have hind : iSupIndep fun s => (W s : Submodule ℂ (M ⊗[ℂ] N)) :=
    (C.eigenspaces_iSupIndep.comp hlam).mono hle
  have htop : iSup (fun s => (W s : Submodule ℂ (M ⊗[ℂ] N))) = ⊤ := by
    apply Submodule.eq_top_of_finrank_eq
    have hinj : Function.Injective
        (DirectSum.coeLinearMap fun s => (W s : Submodule ℂ (M ⊗[ℂ] N))) :=
      hind.dfinsupp_lsum_injective
    have hWdim' : ∀ s, Module.finrank ℂ (W s : Submodule ℂ (M ⊗[ℂ] N)) =
        m' + n' - 2 * (s : ℕ) + 1 := hWdim
    rw [← DirectSum.range_coeLinearMap, LinearMap.finrank_range_of_inj hinj,
      Module.finrank_directSum]
    simp only [hWdim']
    rw [Module.finrank_tensorProduct, hm, hn, cg_sum]
  exact (DirectSum.isInternal_submodule_iff_iSupIndep_and_iSup_eq_top _).mpr ⟨hind, htop⟩

end

/-! The card's worked numbers, checked exactly. -/

-- H, E and F are the card's three matrices.
example : H.val = !![1, 0; 0, -1] := by
  ext i j; fin_cases i <;> fin_cases j <;> simp [H, Matrix.single]

example : E.val = !![0, 1; 0, 0] := by
  ext i j; fin_cases i <;> fin_cases j <;> simp [E, Matrix.single]

example : F.val = !![0, 0; 1, 0] := by
  ext i j; fin_cases i <;> fin_cases j <;> simp [F, Matrix.single]

-- Spin 1 as the ladder V_2: H = diag(2, 0, -2), E multiplies by 2 and 2, F steps down,
-- and the three brackets hold: [H, E] = 2E, [H, F] = -2F, [E, F] = H.
example :
    let H₂ : Matrix (Fin 3) (Fin 3) ℤ := !![2, 0, 0; 0, 0, 0; 0, 0, -2]
    let E₂ : Matrix (Fin 3) (Fin 3) ℤ := !![0, 2, 0; 0, 0, 2; 0, 0, 0]
    let F₂ : Matrix (Fin 3) (Fin 3) ℤ := !![0, 0, 0; 1, 0, 0; 0, 1, 0]
    H₂ * E₂ - E₂ * H₂ = 2 • E₂ ∧ H₂ * F₂ - F₂ * H₂ = -(2 • F₂) ∧ E₂ * F₂ - F₂ * E₂ = H₂ := by
  decide

-- The Casimir on spin 1: H^2 + 2EF + 2FE is 8 times the identity, 8 = 2 × (2 + 2).
example :
    let H₂ : Matrix (Fin 3) (Fin 3) ℤ := !![2, 0, 0; 0, 0, 0; 0, 0, -2]
    let E₂ : Matrix (Fin 3) (Fin 3) ℤ := !![0, 2, 0; 0, 0, 2; 0, 0, 0]
    let F₂ : Matrix (Fin 3) (Fin 3) ℤ := !![0, 0, 0; 1, 0, 0; 0, 1, 0]
    H₂ * H₂ + 2 • (E₂ * F₂) + 2 • (F₂ * E₂) = (8 : ℤ) • (1 : Matrix (Fin 3) (Fin 3) ℤ) := by
  decide

-- Casimir values n(n + 2): 3 on spin 1/2, 8 on spin 1, 15 on spin 3/2, 24 on spin 2.
example : 1 * (1 + 2) = 3 ∧ 2 * (2 + 2) = 8 ∧ 3 * (3 + 2) = 15 ∧ 4 * (4 + 2) = 24 := by
  norm_num

-- Weights of V_2 ⊗ V_1 are the sums of 2, 0, -2 with 1, -1: 3, 1, 1, -1, -1, -3,
-- which peel into the ladders 3, 1, -1, -3 and 1, -1.
example : ([2, 0, -2].flatMap fun a : ℤ => [1, -1].map (a + ·)) = [3, 1, 1, -1, -1, -3] := by
  decide

-- Dimensions of the Clebsch-Gordan splits: 2 × 2 = 3 + 1, 3 × 2 = 4 + 2, 2 × 2 × 2 = 4 + 2 + 2,
-- and the wrong list V_3 + V_2 + V_1 has 9 states, not 6.
example : 2 * 2 = 3 + 1 ∧ 3 * 2 = 4 + 2 ∧ 2 * 2 * 2 = 4 + 2 + 2 ∧ 4 + 3 + 2 = 9 := by
  norm_num

#print axioms irreducible_rep_is_weight_ladder
#print axioms casimir_eq_on_irreducible
#print axioms clebsch_gordan
