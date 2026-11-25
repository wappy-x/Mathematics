-- Jordan form: every complex square matrix becomes, after a change of basis, a stack of Jordan blocks (an eigenvalue down the diagonal, ones just above it), the number of blocks of each size is read from the ranks of the powers of A − λI, a block of size 2 has n-th power with corner entry nλ^(n−1), and the card's 3 × 3 step-rule matrix has blocks of sizes 2 and 1 and gives a(10) = 21,504.
import Mathlib.Basic.Complex.Basic
import Mathlib.Data.Matrix.Block
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.LinearAlgebra.Matrix.Rank
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib

open Matrix

/-! A square matrix with complex entries and `n` rows is `Matrix (Fin n) (Fin n) ℂ`. `P⁻¹` is
Mathlib's inverse and `IsUnit P` says `P` is invertible. `M.rank` is the rank of `M`: how many
independent directions it outputs. `μ • 1` is `μ` times the identity, so `A - μ • 1` is the card's
`A − λI`. Mathlib's `blockDiagonal'` puts square blocks of any sizes down the diagonal, with zeros
elsewhere; its rows are labelled by pairs (block `b`, place inside block `b`). `reindex e e`
relabels those rows and columns as `0, …, n − 1` by the one-to-one matching `e`. -/

/-- The Jordan block of size `k` for the eigenvalue `μ`: `μ` down the diagonal, `1` just above
the diagonal, and `0` everywhere else. -/
def jordanBlock (k : ℕ) (μ : ℂ) : Matrix (Fin k) (Fin k) ℂ :=
  Matrix.of fun i j => if i = j then μ else if (i : ℕ) + 1 = j then 1 else 0

/-- A Jordan matrix: blocks `m` in number, block `b` being the Jordan block of size `size b` for
the eigenvalue `eig b`, stacked down the diagonal with zeros elsewhere. -/
def jordanMatrix {m : ℕ} (size : Fin m → ℕ) (eig : Fin m → ℂ) :
    Matrix (Σ b, Fin (size b)) (Σ b, Fin (size b)) ℂ :=
  blockDiagonal' fun b => jordanBlock (size b) (eig b)

section JordanHelpers
open Module

theorem restrict_pow_coe {V : Type} [AddCommGroup V] [Module ℂ V] (N : Module.End ℂ V)
    (W : Submodule ℂ V) (h : ∀ x ∈ W, N x ∈ W) (j : ℕ) (x : W) :
    (((N.restrict h) ^ j) x : V) = (N ^ j) x := by
  induction j generalizing x with
  | zero => simp
  | succ j ih => rw [pow_succ, pow_succ, Module.End.mul_apply, ih, Module.End.mul_apply,
      LinearMap.coe_restrict_apply]

theorem card_sigma_fin {ι : Type} [Fintype ι] (f : ι → ℕ) :
    Fintype.card (Σ i, Fin (f i)) = ∑ i, f i := by simp

theorem nilpotent_chains (n : ℕ) : ∀ (V : Type) [AddCommGroup V] [Module ℂ V]
    [FiniteDimensional ℂ V], finrank ℂ V = n → ∀ N : Module.End ℂ V, IsNilpotent N →
    ∃ (ι : Type) (_ : Fintype ι) (t : ι → V) (s : ι → ℕ), (∀ i, 0 < s i) ∧
      (∀ i, (N ^ s i) (t i) = 0) ∧
      LinearIndependent ℂ (fun x : Σ i, Fin (s i) => (N ^ (x.2 : ℕ)) (t x.1)) ∧
      ⊤ ≤ Submodule.span ℂ (Set.range (fun x : Σ i, Fin (s i) => (N ^ (x.2 : ℕ)) (t x.1))) := by
  induction n using Nat.strong_induction_on with
  | _ n ih =>
  intro V _ _ _ hn N hN
  by_cases hV : n = 0
  · subst hV
    haveI : Subsingleton V := Module.finrank_zero_iff.mp hn
    refine ⟨Empty, inferInstance, Empty.elim, Empty.elim, fun i => i.elim, fun i => i.elim,
      linearIndependent_empty_type, ?_⟩
    intro v _
    rw [Subsingleton.elim v 0]; exact Submodule.zero_mem _
  obtain ⟨k, hk⟩ := hN
  set W := LinearMap.range N with hWdef
  have hWV : finrank ℂ W < n := by
    rw [← hn]; apply Submodule.finrank_lt
    intro htop
    have hsurj : Function.Surjective N := LinearMap.range_eq_top.mp htop
    have hsk : Function.Surjective (N ^ k) := by
      rw [Module.End.coe_pow]; exact hsurj.iterate k
    rw [hk] at hsk
    haveI : Subsingleton V := ⟨fun a b => by
      obtain ⟨a', rfl⟩ := hsk a; obtain ⟨b', rfl⟩ := hsk b; simp⟩
    exact hV (hn ▸ finrank_zero_of_subsingleton)
  have hWinv : ∀ x ∈ W, N x ∈ W := fun x _ => LinearMap.mem_range_self N x
  set N' := N.restrict hWinv with hN'
  have hN'nil : IsNilpotent N' := ⟨k, by
    ext x; rw [restrict_pow_coe N W hWinv k x, hk]; simp⟩
  obtain ⟨ι, _, t, s, hs, hz, hli, hsp⟩ := ih _ hWV W rfl N' hN'nil
  have hcoe : ∀ (j : ℕ) (x : W), (((N' ^ j) x : W) : V) = (N ^ j) x :=
    fun j x => restrict_pow_coe N W hWinv j x
  choose u hu using fun i => (t i).2
  -- bottoms of the chains in W
  set bot : ι → V := fun i => (N ^ (s i - 1)) (t i : V) with hbot
  have hbot_u : ∀ i, bot i = (N ^ s i) (u i) := by
    intro i
    have : s i = (s i - 1) + 1 := (Nat.succ_pred_eq_of_pos (hs i)).symm
    simp only [hbot]
    conv_rhs => rw [this, pow_succ, Module.End.mul_apply, hu i]
  have hbot_ker : ∀ i, bot i ∈ LinearMap.ker N := by
    intro i
    have : s i - 1 + 1 = s i := Nat.succ_pred_eq_of_pos (hs i)
    rw [LinearMap.mem_ker, hbot, ← Module.End.mul_apply, ← pow_succ', this, ← hcoe, hz]
    rfl
  set B := Submodule.span ℂ (Set.range bot) with hB
  have hBker : B ≤ LinearMap.ker N := by
    rw [hB, Submodule.span_le]; rintro _ ⟨i, rfl⟩; exact hbot_ker i
  obtain ⟨q, hq⟩ := exists_isCompl B
  set C := q ⊓ LinearMap.ker N with hC
  set bC := Module.finBasis ℂ C
  set κ := Fin (finrank ℂ C)
  set z : κ → V := fun k => (bC k : V) with hzdef
  have hzker : ∀ k, N (z k) = 0 := fun k => (bC k).2.2
  have hkerBC : ∀ y ∈ LinearMap.ker N, ∃ b ∈ B, ∃ c ∈ C, b + c = y := by
    intro y hy
    have : y ∈ B ⊔ q := by rw [hq.sup_eq_top]; trivial
    obtain ⟨b, hb, c, hc, rfl⟩ := Submodule.mem_sup.mp this
    refine ⟨b, hb, c, ⟨hc, show N c = 0 from ?_⟩, rfl⟩
    have h1 := hBker hb
    rw [LinearMap.mem_ker] at h1 hy
    rw [map_add, h1, zero_add] at hy; exact hy
  -- the new chains
  let ι' := ι ⊕ κ
  let t' : ι' → V := Sum.elim u z
  let s' : ι' → ℕ := Sum.elim (fun i => s i + 1) (fun _ => 1)
  let F' : (Σ i : ι', Fin (s' i)) → V := fun x => (N ^ (x.2 : ℕ)) (t' x.1)
  have hcomm : ∀ (j : ℕ) y, N ((N ^ j) y) = (N ^ j) (N y) := fun j y => by
    rw [← Module.End.mul_apply, ← pow_succ', pow_succ, Module.End.mul_apply]
  have hspan : ⊤ ≤ Submodule.span ℂ (Set.range F') := by
    set S := Submodule.span ℂ (Set.range F') with hS
    have hmem : ∀ x, F' x ∈ S := fun x => Submodule.subset_span ⟨x, rfl⟩
    have hu_mem : ∀ i (j : ℕ), j ≤ s i → (N ^ j) (u i) ∈ S := fun i j hj =>
      hmem ⟨Sum.inl i, ⟨j, Nat.lt_succ_of_le hj⟩⟩
    have hz_mem : ∀ k, z k ∈ S := fun k => by simpa [F', t'] using hmem ⟨Sum.inr k, (⟨0, by simp [s']⟩ : Fin (s' (Sum.inr k)))⟩
    have hBS : B ≤ S := by
      rw [hB, Submodule.span_le]; rintro _ ⟨i, rfl⟩; rw [hbot_u]; exact hu_mem i _ le_rfl
    have hCS : C ≤ S := by
      intro c hc
      have h1 := bC.sum_repr ⟨c, hc⟩
      have h2 : c = ∑ k, bC.repr ⟨c, hc⟩ k • z k := by
        have h3 := congrArg Subtype.val h1
        rw [Submodule.coe_sum] at h3
        simp only [Submodule.coe_smul] at h3
        exact h3.symm
      rw [h2]; exact Submodule.sum_mem _ fun k _ => Submodule.smul_mem _ _ (hz_mem k)
    intro v _
    have hNv : (⟨N v, LinearMap.mem_range_self N v⟩ : W) ∈ Submodule.span ℂ
        (Set.range fun x : Σ i, Fin (s i) => (N' ^ (x.2 : ℕ)) (t x.1)) := hsp trivial
    obtain ⟨a, ha⟩ := (Submodule.mem_span_range_iff_exists_fun ℂ).mp hNv
    set w : V := ∑ x : Σ i, Fin (s i), a x • (N ^ (x.2 : ℕ)) (u x.1) with hw
    have hwS : w ∈ S :=
      Submodule.sum_mem _ fun x _ => Submodule.smul_mem _ _ (hu_mem x.1 x.2 x.2.2.le)
    have hNw : N w = N v := by
      have h3 : ((∑ x, a x • (N' ^ (x.2 : ℕ)) (t x.1) : W) : V) = N v := by rw [ha]
      rw [← h3, Submodule.coe_sum, hw, map_sum]
      refine Finset.sum_congr rfl fun x _ => ?_
      rw [map_smul, Submodule.coe_smul, hcoe, hcomm, hu]
    have hvw : v - w ∈ LinearMap.ker N := by rw [LinearMap.mem_ker, map_sub, hNw, sub_self]
    obtain ⟨b, hb, c', hc', hbc⟩ := hkerBC _ hvw
    have hv : v = w + (b + c') := by rw [hbc]; abel
    rw [hv]; exact S.add_mem hwS (S.add_mem (hBS hb) (hCS hc'))
  have hcard : Fintype.card (Σ i : ι', Fin (s' i)) = finrank ℂ V := by
    have hW : finrank ℂ W = ∑ i, s i := by
      rw [Module.finrank_eq_card_basis (Basis.mk hli hsp), Fintype.card_sigma]; simp
    have hsup : B ⊔ C = LinearMap.ker N := le_antisymm (sup_le hBker inf_le_right)
      (fun y hy => by
        obtain ⟨b, hb, c, hc, rfl⟩ := hkerBC y hy; exact Submodule.add_mem_sup hb hc)
    have hinf : B ⊓ C = ⊥ := disjoint_iff.mp (hq.disjoint.mono_right inf_le_left)
    have hBC := Submodule.finrank_sup_add_finrank_inf_eq B C
    rw [hsup, hinf, finrank_bot, add_zero] at hBC
    have hbotli : LinearIndependent ℂ bot := by
      have h4 := (hli.comp (fun i => (⟨i, ⟨s i - 1, by have := hs i; omega⟩⟩ : Σ i, Fin (s i)))
        (fun i j h => congrArg Sigma.fst h)).map' W.subtype (Submodule.ker_subtype W)
      convert h4 using 1
      funext i
      simp [Function.comp, hcoe, bot]
    have hBcard : finrank ℂ B = Fintype.card ι := finrank_span_eq_card hbotli
    have hrn := LinearMap.finrank_range_add_finrank_ker N
    rw [← hn] at *
    rw [← hrn, hBC, hBcard, hW, card_sigma_fin, Fintype.sum_sum_type]
    simp only [s', Sum.elim_inl, Sum.elim_inr, Finset.sum_add_distrib, Finset.sum_const,
      Finset.card_univ, smul_eq_mul, mul_one, κ, Fintype.card_fin]
    omega
  refine ⟨ι', inferInstance, t', s', ?_, ?_,
    linearIndependent_of_top_le_span_of_card_eq_finrank hspan hcard, hspan⟩
  · rintro (i | k) <;> simp [s']
  · rintro (i | k)
    · show (N ^ (s i + 1)) (u i) = 0
      rw [pow_succ, Module.End.mul_apply, hu i, ← hcoe, hz]; rfl
    · show (N ^ 1) (z k) = 0
      rw [pow_one, hzker]

theorem exists_jordan_basis {V : Type} [AddCommGroup V] [Module ℂ V] [FiniteDimensional ℂ V]
    (f : Module.End ℂ V) :
    ∃ (m : ℕ) (size : Fin m → ℕ) (eig : Fin m → ℂ) (b : Basis (Σ c, Fin (size c)) ℂ V),
      (∀ c, 0 < size c) ∧ ∀ c (j : Fin (size c)), f (b ⟨c, j⟩) = eig c • b ⟨c, j⟩ +
        (if h : (j : ℕ) = 0 then 0 else b ⟨c, ⟨j - 1, by omega⟩⟩) := by
  classical
  let E : ℂ → Submodule ℂ V := f.maxGenEigenspace
  have hint : DirectSum.IsInternal E :=
    DirectSum.isInternal_submodule_of_iSupIndep_of_iSup_eq_top
      (Module.End.independent_maxGenEigenspace f) (Module.End.iSup_maxGenEigenspace_eq_top f)
  have hmaps : ∀ μ, ∀ x ∈ E μ, (f - algebraMap ℂ (Module.End ℂ V) μ) x ∈ E μ := fun μ =>
    Module.End.mapsTo_maxGenEigenspace_of_comm (Algebra.mul_sub_algebraMap_commutes f μ) μ
  let N : ∀ μ, Module.End ℂ (E μ) := fun μ =>
    (f - algebraMap ℂ (Module.End ℂ V) μ).restrict (hmaps μ)
  have hN : ∀ μ, IsNilpotent (N μ) := fun μ =>
    Module.End.isNilpotent_restrict_maxGenEigenspace_sub_algebraMap f μ
  have hch := fun μ => nilpotent_chains _ (E μ) rfl (N μ) (hN μ)
  choose ι hι t s hs hz hli hsp using hch
  let bE : ∀ μ, Basis (Σ i : ι μ, Fin (s μ i)) ℂ (E μ) := fun μ => Basis.mk (hli μ) (hsp μ)
  let b0 := hint.collectedBasis bE
  let K := Σ μ, ι μ
  have hKfin : Finite K := by
    haveI := Module.Finite.finite_basis b0
    exact Finite.of_surjective (fun x : Σ μ, Σ i : ι μ, Fin (s μ i) => (⟨x.1, x.2.1⟩ : K))
      (fun p => ⟨⟨p.1, p.2, ⟨0, hs p.1 p.2⟩⟩, rfl⟩)
  letI : Fintype K := Fintype.ofFinite K
  let eK := Fintype.equivFin K
  let m := Fintype.card K
  let size : Fin m → ℕ := fun c => s (eK.symm c).1 (eK.symm c).2
  let eig : Fin m → ℂ := fun c => (eK.symm c).1
  let Eq : (Σ μ, Σ i : ι μ, Fin (s μ i)) ≃ Σ c : Fin m, Fin (size c) :=
    (Equiv.sigmaAssoc (fun μ i => Fin (s μ i))).symm.trans
      ((Equiv.sigmaCongrRight (fun p : K => Fin.revPerm)).trans (Equiv.sigmaCongrLeft' eK))
  let b := b0.reindex Eq
  have hb : ∀ c (j : Fin (size c)), b ⟨c, j⟩ =
      (((N (eK.symm c).1) ^ (size c - (j + 1) : ℕ)) (t _ (eK.symm c).2) : V) := by
    intro c j
    simp only [b, Basis.reindex_apply, b0, hint.collectedBasis_coe, bE, Basis.mk_apply]
    rfl
  have hf : ∀ μ (x : E μ), f x = μ • (x : V) + (N μ x : V) := by
    intro μ x
    simp [N, LinearMap.restrict_apply]
  have hpow : ∀ μ (a : ℕ) (x : E μ),
      f ((N μ ^ a) x : V) = μ • ((N μ ^ a) x : V) + ((N μ ^ (a + 1)) x : V) := by
    intro μ a x; rw [hf, pow_succ', Module.End.mul_apply]
  refine ⟨m, size, eig, b, fun c => hs _ _, ?_⟩
  intro c j
  rw [hb, hpow]
  have hj := j.2
  by_cases h0 : (j : ℕ) = 0
  · rw [dif_pos h0]
    have : size c - (j + 1) + 1 = s (eK.symm c).1 (eK.symm c).2 := by
      simp only [size] at hj ⊢; omega
    rw [this, hz]; simp [eig]
  · rw [dif_neg h0, hb]
    have : size c - (j + 1) + 1 = size c - ((j - 1 : ℕ) + 1) := by omega
    rw [this]

theorem toMatrix_eq_jordanMatrix {V : Type} [AddCommGroup V] [Module ℂ V] {m : ℕ}
    (f : Module.End ℂ V) (size : Fin m → ℕ) (eig : Fin m → ℂ)
    (b : Basis (Σ c, Fin (size c)) ℂ V)
    (hf : ∀ c (j : Fin (size c)), f (b ⟨c, j⟩) = eig c • b ⟨c, j⟩ +
        (if h : (j : ℕ) = 0 then 0 else b ⟨c, ⟨j - 1, by omega⟩⟩)) :
    LinearMap.toMatrix b b f = jordanMatrix size eig := by
  classical
  ext ⟨c', j'⟩ ⟨c, j⟩
  rw [LinearMap.toMatrix_apply, hf, jordanMatrix, blockDiagonal'_apply']
  by_cases hc : c' = c
  · subst hc
    simp only [dite_true, cast_eq, jordanBlock, Matrix.of_apply]
    split_ifs with h0 h1 h2 h1 h2 <;>
      simp_all [Finsupp.single_apply, Fin.ext_iff] <;> omega
  · rw [dif_neg hc]
    split_ifs <;> simp [Finsupp.single_apply, hc]

theorem blockDiagonal'_diagonal_sigma {m : ℕ} {s : Fin m → ℕ} (d : ∀ b, Fin (s b) → ℂ) :
    blockDiagonal' (fun b => diagonal (d b)) = diagonal (fun x : Σ b, Fin (s b) => d x.1 x.2) := by
  ext ⟨c, i⟩ ⟨c', j⟩
  rw [blockDiagonal'_apply']
  by_cases hc : c = c'
  · subst hc; simp [diagonal_apply]
  · rw [dif_neg hc, diagonal_apply_ne]
    intro h; exact hc (congrArg Sigma.fst h)

theorem rank_blockDiagonal'_eq_sum {m : ℕ} {s : Fin m → ℕ}
    (M : ∀ b, Matrix (Fin (s b)) (Fin (s b)) ℂ) :
    (blockDiagonal' M).rank = ∑ b, (M b).rank := by
  classical
  choose V U e hV hU hVU using fun b => Matrix.exists_rank_normal_form (M b)
  let d : ∀ b, Fin (s b) → ℂ := fun b i => if (e b i).isLeft then 1 else 0
  have hD : ∀ b, (V b) * (M b) * (U b) = diagonal (d b) := by
    intro b; rw [hVU b]; ext i j
    by_cases hij : i = j
    · subst hij; rcases h : e b i with x | x <;> simp [d, h]
    · rw [diagonal_apply_ne _ hij]; simp only [submatrix_apply]
      have : e b i ≠ e b j := (e b).injective.ne hij
      rcases h1 : e b i with x | x <;> rcases h2 : e b j with y | y <;>
        simp_all [one_apply]
  have hVd : ∀ b, IsUnit (V b).det := fun b => (Matrix.isUnit_iff_isUnit_det _).mp (hV b)
  have hUd : ∀ b, IsUnit (U b).det := fun b => (Matrix.isUnit_iff_isUnit_det _).mp (hU b)
  have hrb : ∀ b, (M b).rank = Fintype.card {i // d b i ≠ 0} := by
    intro b
    rw [← rank_diagonal, ← hD, rank_mul_eq_left_of_isUnit_det _ _ (hUd b),
      rank_mul_eq_right_of_isUnit_det _ _ (hVd b)]
  have hunit : ∀ W : ∀ b, Matrix (Fin (s b)) (Fin (s b)) ℂ, (∀ b, IsUnit (W b).det) →
      IsUnit (blockDiagonal' W).det := by
    intro W hW
    apply Matrix.isUnit_det_of_right_inverse (B := blockDiagonal' fun b => (W b)⁻¹)
    rw [← blockDiagonal'_mul]
    simp_rw [Matrix.mul_nonsing_inv _ (hW _)]
    exact blockDiagonal'_one
  have hall : blockDiagonal' V * blockDiagonal' M * blockDiagonal' U =
      diagonal (fun x : Σ b, Fin (s b) => d x.1 x.2) := by
    rw [← blockDiagonal'_mul, ← blockDiagonal'_mul, ← blockDiagonal'_diagonal_sigma]
    congr 1; funext b; exact hD b
  have h1 : (blockDiagonal' M).rank = (diagonal (fun x : Σ b, Fin (s b) => d x.1 x.2)).rank := by
    rw [← hall, rank_mul_eq_left_of_isUnit_det _ _ (hunit U hUd),
      rank_mul_eq_right_of_isUnit_det _ _ (hunit V hVd)]
  rw [h1, rank_diagonal]
  simp_rw [hrb, Fintype.card_subtype, Finset.card_filter]
  rw [Fintype.sum_sigma]

theorem jordanBlock_sub_pow_apply (s : ℕ) (μ : ℂ) (k : ℕ) (i j : Fin s) :
    ((jordanBlock s μ - μ • (1 : Matrix (Fin s) (Fin s) ℂ)) ^ k) i j =
      if (i : ℕ) + k = j then 1 else 0 := by
  induction k generalizing j with
  | zero => rw [pow_zero, Matrix.one_apply]; simp [Fin.ext_iff]
  | succ k ih =>
    have hi := i.2; have hj := j.2
    rw [pow_succ, Matrix.mul_apply]
    simp_rw [ih]
    by_cases h : (i : ℕ) + (k + 1) = j
    · rw [if_pos h, Finset.sum_eq_single ⟨i + k, by omega⟩]
      · have hne : (⟨i + k, by omega⟩ : Fin s) ≠ j := fun e => by
          have := congrArg Fin.val e; simp at this; omega
        have h1 : (i : ℕ) + k ≠ j := by omega
        have h2 : (i : ℕ) + k + 1 = j := by omega
        rw [Matrix.sub_apply, Matrix.smul_apply, Matrix.one_apply_ne hne]
        simp [jordanBlock, h2, hne]
      · intro l _ hl; rw [if_neg]; · simp
        intro h'; exact hl (Fin.ext h'.symm)
      · simp
    · rw [if_neg h]
      refine Finset.sum_eq_zero fun l _ => ?_
      by_cases h' : (i : ℕ) + k = l
      · rw [if_pos h', one_mul]
        have : (l : ℕ) + 1 ≠ j := by omega
        by_cases hlj : l = j <;> simp [jordanBlock, Matrix.one_apply, hlj, this]
      · simp [h']

theorem card_filter_fin_ge (n k : ℕ) :
    (Finset.univ.filter fun j : Fin n => k ≤ (j : ℕ)).card = n - k := by
  rw [Finset.card_filter, Fin.sum_univ_eq_sum_range (fun j => if k ≤ j then 1 else 0) n,
    ← Finset.card_filter, Finset.range_eq_Ico, Finset.Ico_filter_le, Nat.card_Ico]
  omega

theorem rank_jordanBlock_sub_pow (s : ℕ) (lam μ : ℂ) (k : ℕ) :
    ((jordanBlock s lam - μ • (1 : Matrix (Fin s) (Fin s) ℂ)) ^ k).rank =
      if lam = μ then s - k else s := by
  classical
  split_ifs with h
  · subst h
    rcases Nat.eq_zero_or_pos s with hs | hs
    · subst hs
      have := Matrix.rank_le_card_width ((jordanBlock 0 lam - lam • (1 : Matrix (Fin 0) (Fin 0) ℂ)) ^ k)
      simp at this; simp [this]
    obtain ⟨s', rfl⟩ : ∃ s', s = s' + 1 := ⟨s - 1, by omega⟩
    let d : Fin (s' + 1) → ℂ := fun j => if k ≤ (j : ℕ) then 1 else 0
    let σ : Fin (s' + 1) ≃ Fin (s' + 1) := Equiv.addRight ⟨k % (s' + 1), Nat.mod_lt _ (by omega)⟩
    have hM : (jordanBlock (s' + 1) lam - lam • (1 : Matrix _ _ ℂ)) ^ k =
        (diagonal d).submatrix σ (Equiv.refl _) := by
      ext i j
      rw [jordanBlock_sub_pow_apply, submatrix_apply, diagonal_apply, Equiv.refl_apply]
      have hσ : ((σ i : Fin (s' + 1)) : ℕ) = ((i : ℕ) + k) % (s' + 1) := by
        simp [σ, Fin.val_add, Nat.add_mod_mod]
      have hi := i.2; have hj := j.2
      by_cases hk : k < s' + 1
      · by_cases hik : (i : ℕ) + k < s' + 1
        · rw [Nat.mod_eq_of_lt hik] at hσ
          simp only [d, Fin.ext_iff]; rw [hσ]
          split_ifs <;> first | rfl | (exfalso; omega)
        · have h2 : ((i : ℕ) + k) % (s' + 1) = (i : ℕ) + k - (s' + 1) := by
            rw [Nat.mod_eq_sub_mod (by omega), Nat.mod_eq_of_lt (by omega)]
          rw [h2] at hσ
          simp only [d, Fin.ext_iff]; rw [hσ]
          split_ifs <;> first | rfl | (exfalso; omega)
      · simp only [d, Fin.ext_iff]
        split_ifs <;> first | rfl | (exfalso; omega)
    rw [hM, rank_submatrix, rank_diagonal]
    rw [Fintype.card_subtype]
    have : (Finset.univ.filter fun j : Fin (s' + 1) => d j ≠ 0) =
        Finset.univ.filter fun j : Fin (s' + 1) => k ≤ (j : ℕ) := by
      ext j; simp [d]
    rw [this, card_filter_fin_ge]
  · have htri : (jordanBlock s lam - μ • (1 : Matrix (Fin s) (Fin s) ℂ)).IsUpperTriangular := by
      intro i j hij
      have h1 : i ≠ j := (ne_of_lt hij).symm
      have h3 : (j : ℕ) < i := hij
      have h2 : (i : ℕ) + 1 ≠ j := by omega
      simp [jordanBlock, h1, h2, one_apply]
    have hdet : IsUnit ((jordanBlock s lam - μ • (1 : Matrix (Fin s) (Fin s) ℂ)) ^ k).det := by
      rw [det_pow, Matrix.det_of_isUpperTriangular htri]
      apply IsUnit.pow
      apply IsUnit.mk0
      rw [Finset.prod_ne_zero_iff]
      intro i _
      simp [jordanBlock, sub_eq_zero, h]
    rw [rank_of_isUnit _ ((Matrix.isUnit_iff_isUnit_det _).mpr hdet), Fintype.card_fin]

end JordanHelpers

/-- Jordan form. Every square matrix `A` over the complex numbers can be rewritten by a change of
basis as diagonal blocks: there is an invertible `P` with `P⁻¹ A P = J`, where `J` is a stack of
Jordan blocks of positive sizes, each with one eigenvalue `λ` down its diagonal and ones just
above it. -/
theorem exists_jordan_form {n : ℕ} (A : Matrix (Fin n) (Fin n) ℂ) :
    ∃ (m : ℕ) (size : Fin m → ℕ) (eig : Fin m → ℂ) (e : (Σ b, Fin (size b)) ≃ Fin n)
      (P : Matrix (Fin n) (Fin n) ℂ),
      IsUnit P ∧ (∀ b, 0 < size b) ∧ P⁻¹ * A * P = (jordanMatrix size eig).reindex e e := by
  classical
  obtain ⟨m, size, eig, b, hpos, hf⟩ := exists_jordan_basis (Matrix.toLin' A)
  have hcard : Fintype.card (Σ c, Fin (size c)) = n := by
    rw [← Module.finrank_eq_card_basis b, Module.finrank_fin_fun]
  let e : (Σ c, Fin (size c)) ≃ Fin n := Fintype.equivFinOfCardEq hcard
  let b' := b.reindex e
  let P := (Pi.basisFun ℂ (Fin n)).toMatrix b'
  let Q := b'.toMatrix (Pi.basisFun ℂ (Fin n))
  have hQP : Q * P = 1 := Module.Basis.toMatrix_mul_toMatrix_flip _ _
  have hPQ : P * Q = 1 := Module.Basis.toMatrix_mul_toMatrix_flip _ _
  have hPinv : P⁻¹ = Q := Matrix.inv_eq_left_inv hQP
  refine ⟨m, size, eig, e, P, ?_, hpos, ?_⟩
  · exact (Matrix.isUnit_iff_isUnit_det P).mpr (Matrix.isUnit_det_of_right_inverse hPQ)
  · have h1 : Q * A * P = LinearMap.toMatrix b' b' (Matrix.toLin' A) := by
      rw [← basis_toMatrix_mul_linearMap_toMatrix_mul_basis_toMatrix (b := b') (c := b')
        (b' := Pi.basisFun ℂ (Fin n)) (c' := Pi.basisFun ℂ (Fin n)),
        LinearMap.toMatrix_eq_toMatrix', LinearMap.toMatrix'_toLin']
    rw [hPinv, h1, ← toMatrix_eq_jordanMatrix _ size eig b hf]
    ext i j
    simp [LinearMap.toMatrix_apply, b', Module.Basis.reindex_apply, Module.Basis.repr_reindex]

/-- Block sizes from ranks. Whenever `P⁻¹ A P` is a Jordan matrix, write `r k` for the rank of
`(A − λI)^k` (so `r 0 = n`). Then the number of blocks for `λ` of size at least `k + 1` is
`r k − r (k + 1)`: each extra power of `A − λI` loses one rank for every block still long enough
to feel it. So the block sizes depend only on `A`, not on the chains chosen. -/
theorem card_blocks_size_at_least_eq_rank_drop {n m : ℕ} (A P : Matrix (Fin n) (Fin n) ℂ)
    (size : Fin m → ℕ) (eig : Fin m → ℂ) (e : (Σ b, Fin (size b)) ≃ Fin n) (hP : IsUnit P)
    (hJ : P⁻¹ * A * P = (jordanMatrix size eig).reindex e e) (μ : ℂ) (k : ℕ) :
    (Finset.univ.filter fun b => eig b = μ ∧ k + 1 ≤ size b).card
        + ((A - μ • (1 : Matrix (Fin n) (Fin n) ℂ)) ^ (k + 1)).rank
      = ((A - μ • (1 : Matrix (Fin n) (Fin n) ℂ)) ^ k).rank := by
  classical
  have hdet : IsUnit P.det := (Matrix.isUnit_iff_isUnit_det P).mp hP
  have hPP : P * P⁻¹ = 1 := Matrix.mul_nonsing_inv P hdet
  have hPP' : P⁻¹ * P = 1 := Matrix.nonsing_inv_mul P hdet
  set B := A - μ • (1 : Matrix (Fin n) (Fin n) ℂ) with hB
  have hconj : ∀ j : ℕ, P⁻¹ * B ^ j * P = (P⁻¹ * B * P) ^ j := by
    intro j
    induction j with
    | zero => simp [hPP']
    | succ j ih =>
      rw [pow_succ B, pow_succ (P⁻¹ * B * P), ← ih]
      simp only [Matrix.mul_assoc]
      rw [← Matrix.mul_assoc P P⁻¹, hPP, Matrix.one_mul]
  have hBJ : P⁻¹ * B * P = reindex e e (jordanMatrix size eig - μ • 1) := by
    rw [hB, Matrix.mul_sub, Matrix.sub_mul, hJ, Matrix.mul_smul, Matrix.smul_mul, Matrix.mul_one,
      hPP']
    ext i j
    simp [Matrix.reindex_apply, Matrix.one_apply]
  have h3 : jordanMatrix size eig - μ • 1 =
      blockDiagonal' (fun b => jordanBlock (size b) (eig b) - μ • 1) := by
    show _ = blockDiagonal' ((fun b => jordanBlock (size b) (eig b)) - μ • 1)
    rw [blockDiagonal'_sub, blockDiagonal'_smul, blockDiagonal'_one]
    rfl
  have hrank : ∀ j, (B ^ j).rank = ∑ b, (if eig b = μ then size b - j else size b) := by
    intro j
    have h1 : (B ^ j).rank = (P⁻¹ * B ^ j * P).rank := by
      rw [rank_mul_eq_left_of_isUnit_det _ _ hdet,
        rank_mul_eq_right_of_isUnit_det _ _ (Matrix.isUnit_nonsing_inv_det P hdet)]
    have h2 : ∀ X : Matrix (Σ b, Fin (size b)) (Σ b, Fin (size b)) ℂ,
        (reindex e e X) ^ j = reindex e e (X ^ j) := by
      intro X
      have := map_pow (Matrix.reindexAlgEquiv ℂ ℂ e) X j
      simpa using this.symm
    rw [h1, hconj, hBJ, h2, rank_reindex, h3, ← blockDiagonal'_pow, rank_blockDiagonal'_eq_sum]
    refine Finset.sum_congr rfl fun b _ => ?_
    rw [Pi.pow_apply, rank_jordanBlock_sub_pow]
  rw [hrank, hrank, Finset.card_filter, ← Finset.sum_add_distrib]
  refine Finset.sum_congr rfl fun b _ => ?_
  by_cases he : eig b = μ <;> by_cases hs : k + 1 ≤ size b <;> simp [he, hs] <;> omega

/-- Powers of a block of size 2. By the binomial theorem, with `N₂² = 0`, the `n`-th power of the
Jordan block `[[λ, 1], [0, λ]]` is `λⁿ I + n λⁿ⁻¹ N₂ = [[λⁿ, n λⁿ⁻¹], [0, λⁿ]]`. -/
theorem jordanBlock_two_pow (μ : ℂ) (n : ℕ) :
    jordanBlock 2 μ ^ n = !![μ ^ n, (n : ℂ) * μ ^ (n - 1); 0, μ ^ n] := by
  induction n with
  | zero => ext i j; fin_cases i <;> fin_cases j <;> simp [jordanBlock]
  | succ n ih =>
    rw [pow_succ, ih]
    ext i j; fin_cases i <;> fin_cases j <;> simp [jordanBlock, Matrix.mul_apply, Fin.sum_univ_two, pow_succ]
    rcases n with _ | n
    · simp
    · simp [pow_succ]; push_cast; ring

-- Worked numbers. A = [[0, 1, 0], [-4, 4, 0], [0, 0, 2]] steps (a(n), a(n+1), b(n)) for the rules
-- a(n+2) = 4a(n+1) − 4a(n) and b(n+1) = 2b(n); exact whole numbers throughout.
-- Characteristic polynomial: trace 6, sum of 2 × 2 diagonal minors 12, det 8, so (x − 2)³.
example : (0 : ℤ) + 4 + 2 = 6 ∧ (0 * 4 - 1 * (-4)) + (0 * 2 - 0 * 0) + (4 * 2 - 0 * 0) = (12 : ℤ) ∧
    (!![0, 1, 0; -4, 4, 0; 0, 0, 2] : Matrix (Fin 3) (Fin 3) ℤ).det = 8 := by
  refine ⟨by norm_num, by norm_num, ?_⟩
  simp [Matrix.det_fin_three]
-- x³ − 6x² + 12x − 8 is (x − 2)³.
example (x : ℤ) : x ^ 3 - 6 * x ^ 2 + 12 * x - 8 = (x - 2) ^ 3 := by ring
-- N = A − 2I is [[-2, 1, 0], [-4, 2, 0], [0, 0, 0]], and N² is the zero matrix.
example : (!![0, 1, 0; -4, 4, 0; 0, 0, 2] : Matrix (Fin 3) (Fin 3) ℤ) - 2 • 1 =
    !![-2, 1, 0; -4, 2, 0; 0, 0, 0] := by decide
example : (!![-2, 1, 0; -4, 2, 0; 0, 0, 0] : Matrix (Fin 3) (Fin 3) ℤ) ^ 2 = 0 := by decide
-- The chain: N (0, 1, 0) = (1, 2, 0), N (1, 2, 0) = 0, N (0, 0, 1) = 0.
example : (!![-2, 1, 0; -4, 2, 0; 0, 0, 0] : Matrix (Fin 3) (Fin 3) ℤ) *ᵥ ![0, 1, 0] = ![1, 2, 0] ∧
    (!![-2, 1, 0; -4, 2, 0; 0, 0, 0] : Matrix (Fin 3) (Fin 3) ℤ) *ᵥ ![1, 2, 0] = 0 ∧
    (!![-2, 1, 0; -4, 2, 0; 0, 0, 0] : Matrix (Fin 3) (Fin 3) ℤ) *ᵥ ![0, 0, 1] = 0 := by decide
-- P = [[1, 0, 0], [2, 1, 0], [0, 0, 1]] has inverse [[1, 0, 0], [-2, 1, 0], [0, 0, 1]], and
-- P⁻¹ A P = J = [[2, 1, 0], [0, 2, 0], [0, 0, 2]].
example : (!![1, 0, 0; -2, 1, 0; 0, 0, 1] : Matrix (Fin 3) (Fin 3) ℤ) * !![1, 0, 0; 2, 1, 0; 0, 0, 1] = 1 ∧
    (!![1, 0, 0; -2, 1, 0; 0, 0, 1] : Matrix (Fin 3) (Fin 3) ℤ) * !![0, 1, 0; -4, 4, 0; 0, 0, 2] *
      !![1, 0, 0; 2, 1, 0; 0, 0, 1] = !![2, 1, 0; 0, 2, 0; 0, 0, 2] := by decide
-- Block counts from the ranks 3, 1, 0: 3 − 1 = 2 blocks, 1 − 0 = 1 of size 2 or more; sizes 2 and 1.
example : (3 : ℕ) - 1 = 2 ∧ (1 : ℕ) - 0 = 1 ∧ 2 + 1 = 3 := by norm_num
-- A^10 = [[-9216, 5120, 0], [-20480, 11264, 0], [0, 0, 1024]].
example : (!![0, 1, 0; -4, 4, 0; 0, 0, 2] : Matrix (Fin 3) (Fin 3) ℤ) ^ 10 =
    !![-9216, 5120, 0; -20480, 11264, 0; 0, 0, 1024] := by decide
-- The start (1, 6, 1) is 1 × (1, 2, 0) + 4 × (0, 1, 0) + 1 × (0, 0, 1), and ten steps take it to
-- (21504, 47104, 1024).
example : (!![1, 0, 0; -2, 1, 0; 0, 0, 1] : Matrix (Fin 3) (Fin 3) ℤ) *ᵥ ![1, 6, 1] = ![1, 4, 1] ∧
    (!![0, 1, 0; -4, 4, 0; 0, 0, 2] : Matrix (Fin 3) (Fin 3) ℤ) ^ 10 *ᵥ ![1, 6, 1] =
      ![21504, 47104, 1024] := by decide
-- a(10) = 2^10 + 4 × 10 × 2^9 = 1,024 + 20,480 = 21,504.
example : (2 : ℕ) ^ 10 + 4 * 10 * 2 ^ 9 = 21504 ∧ 4 * 10 * 2 ^ 9 = 20480 := by norm_num
-- a(0), …, a(6): 1, 6, 20, 56, 144, 352, 832.
example : (List.range 7).map (fun k => ((!![0, 1, 0; -4, 4, 0; 0, 0, 2] : Matrix (Fin 3) (Fin 3) ℤ) ^ k
    *ᵥ ![1, 6, 1]) 0) = [1, 6, 20, 56, 144, 352, 832] := by decide
-- The mistakes: entry powers give a(10) = 0 × 1 + 1 × 6 = 6; 2^10 + 4 × 10 × 2^10 = 41,984.
example : (0 : ℤ) ^ 10 * 1 + 1 ^ 10 * 6 + 0 ^ 10 * 1 = 6 ∧ (2 : ℕ) ^ 10 + 4 * 10 * 2 ^ 10 = 41984 := by norm_num

#print axioms restrict_pow_coe
#print axioms card_sigma_fin
#print axioms nilpotent_chains
#print axioms exists_jordan_basis
#print axioms toMatrix_eq_jordanMatrix
#print axioms blockDiagonal'_diagonal_sigma
#print axioms rank_blockDiagonal'_eq_sum
#print axioms jordanBlock_sub_pow_apply
#print axioms card_filter_fin_ge
#print axioms rank_jordanBlock_sub_pow
#print axioms exists_jordan_form
#print axioms card_blocks_size_at_least_eq_rank_drop
#print axioms jordanBlock_two_pow
