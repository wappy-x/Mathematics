-- Stationary distributions: every finite Markov chain has a mix of chances that one more step leaves unchanged, an irreducible one has exactly one, and its entries are the long-run fractions of days spent in each state.
import Mathlib.LinearAlgebra.Matrix.Stochastic
import Mathlib.MeasureTheory.Measure.Typeclasses.Probability
import Mathlib.MeasureTheory.Measure.Real
import Mathlib.Topology.Instances.Real.Lemmas
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib

namespace StationaryDistributions

open Matrix MeasureTheory Filter Topology

/-! Setting. The states are a finite, non-empty type `ι` (the card's states 1 to `N`). The
transition matrix `P` is row-stochastic: `P i j ≥ 0` is the chance tomorrow is `j` given today is
`i`, and each row adds to 1 (Mathlib's `Matrix.rowStochastic`). A mix of chances is a row
`π : ι → R`; `π ᵥ* P` is tomorrow's mix when today's is `π`. -/

/-- A **stationary distribution** of `P`: a row with no negative entries and total 1 that one
more step hands back unchanged, `π P = π` (the balance equations). -/
def IsStationaryDistribution {R ι : Type*} [Fintype ι] [Semiring R] [PartialOrder R]
    (P : Matrix ι ι R) (π : ι → R) : Prop :=
  (∀ j, 0 ≤ π j) ∧ ∑ j, π j = 1 ∧ π ᵥ* P = π

/-- The chain is **irreducible**: every state can reach every other, i.e. for all states `i`, `j`
some number of steps `n` takes `i` to `j` with positive chance, `(P^n) i j > 0`. -/
def Irreducible {R ι : Type*} [Fintype ι] [DecidableEq ι] [Semiring R] [PartialOrder R]
    (P : Matrix ι ι R) : Prop :=
  ∀ i j, ∃ n : ℕ, 0 < (P ^ n) i j

/-- Maximum principle: on an irreducible chain, a function with `P h = h` is constant. -/
lemma harmonic_const {ι : Type*} [Fintype ι] [DecidableEq ι] [Nonempty ι]
    {P : Matrix ι ι ℝ} (hP : P ∈ rowStochastic ℝ ι) (hirr : Irreducible P)
    (h : ι → ℝ) (hh : P *ᵥ h = h) : h = fun _ => h (Classical.arbitrary ι) := by
  obtain ⟨i0, hi0⟩ := Finite.exists_max h
  have step : ∀ m k, h m = h i0 → 0 < P m k → h k = h i0 := by
    intro m k hm hmk
    have e1 : ∑ l, P m l * h l = h m := by
      have := congrFun hh m; simpa [mulVec, dotProduct] using this
    have e2 : ∑ l, P m l = 1 := sum_row_of_mem_rowStochastic hP m
    have hsum : ∑ l, P m l * (h i0 - h l) = 0 := by
      simp only [mul_sub, Finset.sum_sub_distrib, ← Finset.sum_mul, e1, e2, hm]; ring
    have hnn : ∀ l ∈ Finset.univ, 0 ≤ P m l * (h i0 - h l) := fun l _ =>
      mul_nonneg (hP.1 m l) (sub_nonneg.2 (hi0 l))
    have := (Finset.sum_eq_zero_iff_of_nonneg hnn).1 hsum k (Finset.mem_univ _)
    rcases mul_eq_zero.1 this with h1 | h1
    · exact absurd h1 hmk.ne'
    · linarith
  have reach : ∀ n k, 0 < (P ^ n) i0 k → h k = h i0 := by
    intro n
    induction n with
    | zero =>
      intro k hk
      by_cases hik : i0 = k
      · rw [hik]
      · simp [hik] at hk
    | succ n ih =>
      intro k hk
      rw [pow_succ, Matrix.mul_apply] at hk
      by_contra hne
      have hle : ∀ m ∈ Finset.univ, (P ^ n) i0 m * P m k ≤ 0 := by
        intro m _
        by_contra hpos'
        have hpos := not_le.1 hpos'
        have ha : 0 ≤ (P ^ n) i0 m := (pow_mem hP n).1 i0 m
        have hb : 0 ≤ P m k := hP.1 m k
        have ha' : 0 < (P ^ n) i0 m := lt_of_le_of_ne ha (fun e => by
          rw [← e, zero_mul] at hpos; exact lt_irrefl _ hpos)
        have hb' : 0 < P m k := lt_of_le_of_ne hb (fun e => by
          rw [← e, mul_zero] at hpos; exact lt_irrefl _ hpos)
        exact hne (step m k (ih m ha') hb')
      linarith [Finset.sum_nonpos hle]
  have hc : ∀ k, h k = h i0 := fun k => by
    obtain ⟨n, hn⟩ := hirr i0 k; exact reach n k hn
  funext k; rw [hc k, hc (Classical.arbitrary ι)]

/-- For an irreducible chain, the kernel of `1 - P` acting on columns is one-dimensional. -/
lemma finrank_ker_one_sub {ι : Type*} [Fintype ι] [DecidableEq ι] [Nonempty ι]
    {P : Matrix ι ι ℝ} (hP : P ∈ rowStochastic ℝ ι) (hirr : Irreducible P) :
    Module.finrank ℝ (LinearMap.ker (1 - P).mulVecLin) = 1 := by
  have hmem : (fun _ : ι => (1 : ℝ)) ∈ LinearMap.ker (1 - P).mulVecLin := by
    rw [LinearMap.mem_ker, Matrix.mulVecLin_apply, sub_mulVec, one_mulVec]
    have := one_vecMul_of_mem_rowStochastic hP
    rw [sub_eq_zero]; exact this.symm
  have hne : (⟨fun _ => 1, hmem⟩ : LinearMap.ker (1 - P).mulVecLin) ≠ 0 := by
    intro e
    have := congrFun (congrArg Subtype.val e) (Classical.arbitrary ι)
    simp at this
  rw [finrank_eq_one_iff_of_ne_zero' _ hne]
  rintro ⟨w, hw⟩
  rw [LinearMap.mem_ker, Matrix.mulVecLin_apply, sub_mulVec, one_mulVec, sub_eq_zero] at hw
  have := harmonic_const hP hirr w hw.symm
  refine ⟨w (Classical.arbitrary ι), ?_⟩
  ext k
  simp only [SetLike.mk_smul_mk]
  rw [this]; simp

lemma rank_one_sub {ι : Type*} [Fintype ι] [DecidableEq ι] [Nonempty ι]
    {P : Matrix ι ι ℝ} (hP : P ∈ rowStochastic ℝ ι) (hirr : Irreducible P) :
    (1 - P).rank + 1 = Fintype.card ι := by
  have := LinearMap.finrank_range_add_finrank_ker (1 - P).mulVecLin
  rw [finrank_ker_one_sub hP hirr, Module.finrank_fintype_fun_eq_card] at this
  exact this

/-- Existence of a stationary distribution for any finite row-stochastic matrix. -/
lemma exists_stationary {ι : Type*} [Fintype ι] [DecidableEq ι] [Nonempty ι]
    (P : Matrix ι ι ℝ) (hP : P ∈ rowStochastic ℝ ι) :
    ∃ π : ι → ℝ, IsStationaryDistribution P π := by
  have hdet : (1 - P).det = 0 := by
    rw [← Matrix.exists_mulVec_eq_zero_iff]
    refine ⟨fun _ => 1, ?_, ?_⟩
    · intro e; have := congrFun e (Classical.arbitrary ι); simp at this
    · rw [sub_mulVec, one_mulVec]
      have := one_vecMul_of_mem_rowStochastic hP
      rw [sub_eq_zero]; exact this.symm
  rw [← Matrix.exists_vecMul_eq_zero_iff] at hdet
  obtain ⟨v, hv0, hv⟩ := hdet
  rw [vecMul_sub, vecMul_one, sub_eq_zero] at hv
  -- hv : v = v ᵥ* P
  set u : ι → ℝ := fun i => |v i| with hu
  have hge : ∀ j, u j ≤ (u ᵥ* P) j := by
    intro j
    have e : v j = ∑ i, v i * P i j := by
      conv_lhs => rw [hv]
      simp [vecMul, dotProduct]
    simp only [hu, vecMul, dotProduct]
    rw [e]
    refine (Finset.abs_sum_le_sum_abs _ _).trans (le_of_eq ?_)
    refine Finset.sum_congr rfl fun i _ => ?_
    rw [abs_mul, abs_of_nonneg (hP.1 i j)]
  have hsumeq : ∑ j, (u ᵥ* P) j = ∑ j, u j := by
    simp only [vecMul, dotProduct]
    rw [Finset.sum_comm]
    refine Finset.sum_congr rfl fun i _ => ?_
    rw [← Finset.mul_sum, sum_row_of_mem_rowStochastic hP i, mul_one]
  have hfix : ∀ j, (u ᵥ* P) j = u j := by
    have h0 : ∑ j, ((u ᵥ* P) j - u j) = 0 := by
      rw [Finset.sum_sub_distrib, hsumeq, sub_self]
    have := (Finset.sum_eq_zero_iff_of_nonneg (fun j _ => sub_nonneg.2 (hge j))).1 h0
    intro j; have := this j (Finset.mem_univ _); linarith
  obtain ⟨i1, hi1⟩ : ∃ i, v i ≠ 0 := by
    by_contra hcon; exact hv0 (funext fun i => not_not.1 fun hi => hcon ⟨i, hi⟩)
  have hspos : 0 < ∑ j, u j := by
    have : u i1 ≤ ∑ j, u j :=
      Finset.single_le_sum (fun j _ => abs_nonneg (v j)) (Finset.mem_univ i1)
    have : 0 < u i1 := abs_pos.2 hi1
    linarith
  refine ⟨fun i => u i / ∑ j, u j, ?_, ?_, ?_⟩
  · intro j; exact div_nonneg (abs_nonneg _) hspos.le
  · rw [← Finset.sum_div]; exact div_self hspos.ne'
  · funext j
    have := hfix j
    simp only [vecMul, dotProduct] at this ⊢
    simp_rw [div_mul_eq_mul_div]
    rw [← Finset.sum_div, this]

/-- Uniqueness: two stationary distributions of an irreducible chain agree. -/
lemma stationary_unique {ι : Type*} [Fintype ι] [DecidableEq ι] [Nonempty ι]
    {P : Matrix ι ι ℝ} (hP : P ∈ rowStochastic ℝ ι) (hirr : Irreducible P)
    {π π' : ι → ℝ} (h1 : IsStationaryDistribution P π) (h2 : IsStationaryDistribution P π') :
    π' = π := by
  have hrk := rank_one_sub hP hirr
  have hker := LinearMap.finrank_range_add_finrank_ker (1 - P)ᵀ.mulVecLin
  rw [Module.finrank_fintype_fun_eq_card] at hker
  have hrkT : Module.finrank ℝ (LinearMap.range (1 - P)ᵀ.mulVecLin) = (1 - P).rank := by
    rw [← Matrix.rank_transpose]; rfl
  have hk1 : Module.finrank ℝ (LinearMap.ker (1 - P)ᵀ.mulVecLin) = 1 := by omega
  have mem : ∀ ρ : ι → ℝ, IsStationaryDistribution P ρ → ρ ∈ LinearMap.ker (1 - P)ᵀ.mulVecLin := by
    intro ρ hρ
    rw [LinearMap.mem_ker, Matrix.mulVecLin_apply, mulVec_transpose, vecMul_sub, vecMul_one,
      hρ.2.2, sub_self]
  have hne : (⟨π, mem π h1⟩ : LinearMap.ker (1 - P)ᵀ.mulVecLin) ≠ 0 := by
    intro e
    have := congrArg Subtype.val e
    have hs := h1.2.1
    simp only [ZeroMemClass.coe_zero] at this
    rw [this] at hs; simp at hs
  obtain ⟨c, hc⟩ := (finrank_eq_one_iff_of_ne_zero' _ hne).1 hk1 ⟨π', mem π' h2⟩
  have hc' : c • π = π' := congrArg Subtype.val hc
  have : c = 1 := by
    have := congrArg (fun ρ : ι → ℝ => ∑ j, ρ j) hc'
    simp only [Pi.smul_apply, smul_eq_mul, ← Finset.mul_sum, h1.2.1, h2.2.1, mul_one] at this
    exact this
  rw [← hc', this, one_smul]

/-- Poisson equation: if `π ⬝ f = 0` then `f = (1 - P) g` for some `g`. -/
lemma poisson {ι : Type*} [Fintype ι] [DecidableEq ι] [Nonempty ι]
    {P : Matrix ι ι ℝ} (hP : P ∈ rowStochastic ℝ ι) (hirr : Irreducible P)
    {π : ι → ℝ} (hπ : IsStationaryDistribution P π) (f : ι → ℝ) (hf : π ⬝ᵥ f = 0) :
    ∃ g : ι → ℝ, (1 - P) *ᵥ g = f := by
  let φ : (ι → ℝ) →ₗ[ℝ] ℝ :=
    { toFun := fun x => π ⬝ᵥ x
      map_add' := fun x y => dotProduct_add π x y
      map_smul' := fun c x => by simp [dotProduct_smul] }
  have hsurj : LinearMap.range φ = ⊤ := by
    rw [LinearMap.range_eq_top]
    intro y
    refine ⟨fun _ => y, ?_⟩
    show π ⬝ᵥ (fun _ => y) = y
    simp only [dotProduct]
    rw [← Finset.sum_mul, hπ.2.1, one_mul]
  have hφ := LinearMap.finrank_range_add_finrank_ker φ
  rw [hsurj, finrank_top, Module.finrank_self, Module.finrank_fintype_fun_eq_card] at hφ
  have hrk := rank_one_sub hP hirr
  have hle : LinearMap.range (1 - P).mulVecLin ≤ LinearMap.ker φ := by
    rintro _ ⟨g, rfl⟩
    rw [LinearMap.mem_ker]
    show π ⬝ᵥ ((1 - P) *ᵥ g) = 0
    rw [dotProduct_mulVec, vecMul_sub, vecMul_one, hπ.2.2, sub_self, zero_dotProduct]
  have heq := Submodule.eq_of_le_of_finrank_eq hle (by
    show (1 - P).rank = _
    omega)
  have hfm : f ∈ LinearMap.ker φ := hf
  rw [← heq] at hfm
  obtain ⟨g, hg⟩ := hfm
  exact ⟨g, hg⟩


/-- The first `n + 1` states of a run, as a tuple. -/
def pathOf {ι Ω : Type*} (X : ℕ → Ω → ι) (n : ℕ) (ω : Ω) : Fin (n + 1) → ι := fun k => X k ω

lemma measurableSet_path {ι Ω : Type*} [MeasurableSpace Ω] (X : ℕ → Ω → ι)
    (hX : ∀ n i, MeasurableSet {ω | X n ω = i}) (n : ℕ) (t : Fin (n + 1) → ι) :
    MeasurableSet {ω | pathOf X n ω = t} := by
  have : {ω | pathOf X n ω = t} = ⋂ k : Fin (n + 1), {ω | X k ω = t k} := by
    ext ω; simp [pathOf, funext_iff]
  rw [this]; exact MeasurableSet.iInter fun k => hX _ _

lemma measureReal_path_pred {ι Ω : Type*} [Fintype ι] [MeasurableSpace Ω] (μ : Measure Ω)
    [IsFiniteMeasure μ] (X : ℕ → Ω → ι) (hX : ∀ n i, MeasurableSet {ω | X n ω = i}) (n : ℕ)
    (Q : (Fin (n + 1) → ι) → Prop) [DecidablePred Q] :
    μ.real {ω | Q (pathOf X n ω)} =
      ∑ t ∈ Finset.univ.filter Q, μ.real {ω | pathOf X n ω = t} := by
  classical
  have : {ω | Q (pathOf X n ω)} = ⋃ t ∈ Finset.univ.filter Q, {ω | pathOf X n ω = t} := by
    ext ω; simp
  rw [this, measureReal_biUnion_finset]
  · intro t _ t' _ htt'
    refine Set.disjoint_left.2 fun ω h1 h2 => htt' ?_
    simp only [Set.mem_ofPred_eq] at h1 h2
    rw [← h1, ← h2]
  · intro t _; exact measurableSet_path X hX n t

lemma sum_measureReal_path {ι Ω : Type*} [Fintype ι] [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] (X : ℕ → Ω → ι) (hX : ∀ n i, MeasurableSet {ω | X n ω = i})
    (n : ℕ) : ∑ t, μ.real {ω | pathOf X n ω = t} = 1 := by
  classical
  have := measureReal_path_pred μ X hX n (fun _ => True)
  simpa using this.symm

lemma measureReal_path_snoc {ι Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω)
    (P : Matrix ι ι ℝ) (X : ℕ → Ω → ι)
    (hMarkov : ∀ (n : ℕ) (s : ℕ → ι),
      μ.real {ω | ∀ k ≤ n + 1, X k ω = s k} =
        μ.real {ω | ∀ k ≤ n, X k ω = s k} * P (s n) (s (n + 1)))
    (n : ℕ) (t : Fin (n + 1) → ι) (b : ι) :
    μ.real {ω | pathOf X (n + 1) ω = Fin.snoc t b} =
      μ.real {ω | pathOf X n ω = t} * P (t (Fin.last n)) b := by
  let s : ℕ → ι := fun k => if h : k < n + 2 then (Fin.snoc t b : Fin (n + 2) → ι) ⟨k, h⟩ else b
  have hs1 : ∀ k (hk : k < n + 1), s k = t ⟨k, hk⟩ := by
    intro k hk
    simp [s, show k < n + 2 by omega, Fin.snoc, show k ≤ n by omega]
  have hs2 : s (n + 1) = b := by simp [s, Fin.snoc]
  have h1 : {ω | pathOf X (n + 1) ω = Fin.snoc t b} = {ω | ∀ k ≤ n + 1, X k ω = s k} := by
    ext ω
    simp only [Set.mem_ofPred_eq, funext_iff, pathOf]
    constructor
    · intro h k hk
      have := h ⟨k, by omega⟩
      simp only [s, (show k < n + 2 by omega), ↓reduceDIte]
      exact this
    · intro h k
      have := h k (by omega)
      simp only [s, k.isLt, ↓reduceDIte] at this
      exact this
  have h2 : {ω | pathOf X n ω = t} = {ω | ∀ k ≤ n, X k ω = s k} := by
    ext ω
    simp only [Set.mem_ofPred_eq, funext_iff, pathOf]
    constructor
    · intro h k hk
      rw [hs1 k (by omega)]; exact h ⟨k, by omega⟩
    · intro h k
      have := h k (by omega)
      rw [hs1 k k.isLt] at this; exact this
  rw [h1, h2, hMarkov n s, hs2, hs1 n (by omega)]
  rfl

lemma sum_snoc {ι : Type*} [Fintype ι] {n : ℕ} (F : (Fin (n + 2) → ι) → ℝ) :
    ∑ t', F t' = ∑ t : Fin (n + 1) → ι, ∑ b, F (Fin.snoc t b) := by
  rw [← (Fin.snocEquiv (fun _ => ι)).sum_comp, Fintype.sum_prod_type_right]
  simp [Fin.snocEquiv_apply]

/-- The martingale part along a tuple of states. -/
def martPart {ι : Type*} (D : ι → ι → ℝ) (n : ℕ) (t : Fin (n + 1) → ι) : ℝ :=
  ∑ k : Fin n, D (t k.castSucc) (t k.succ)

lemma martPart_snoc {ι : Type*} (D : ι → ι → ℝ) (n : ℕ) (t : Fin (n + 1) → ι) (b : ι) :
    martPart D (n + 1) (Fin.snoc t b) = martPart D n t + D (t (Fin.last n)) b := by
  unfold martPart
  rw [Fin.sum_univ_castSucc]
  simp only [Fin.snoc_castSucc, Fin.succ_castSucc, Fin.succ_last, Fin.snoc_last]

lemma moment_step {ι Ω : Type*} [Fintype ι] [MeasurableSpace Ω] (μ : Measure Ω)
    (P : Matrix ι ι ℝ) (X : ℕ → Ω → ι)
    (hMarkov : ∀ (n : ℕ) (s : ℕ → ι),
      μ.real {ω | ∀ k ≤ n + 1, X k ω = s k} =
        μ.real {ω | ∀ k ≤ n, X k ω = s k} * P (s n) (s (n + 1)))
    (D : ι → ι → ℝ) (Φ Ψ : ℝ → ℝ) (hΦ : ∀ a S, ∑ b, P a b * Φ (S + D a b) ≤ Ψ S) (n : ℕ) :
    ∑ t', μ.real {ω | pathOf X (n + 1) ω = t'} * Φ (martPart D (n + 1) t') ≤
      ∑ t, μ.real {ω | pathOf X n ω = t} * Ψ (martPart D n t) := by
  rw [sum_snoc]
  refine Finset.sum_le_sum fun t _ => ?_
  simp_rw [measureReal_path_snoc μ P X hMarkov, martPart_snoc, mul_assoc, ← Finset.mul_sum]
  exact mul_le_mul_of_nonneg_left (hΦ _ _) measureReal_nonneg

lemma inner_sq {ι : Type*} [Fintype ι] (q d : ι → ℝ) (hq : ∀ b, 0 ≤ q b) (hq1 : ∑ b, q b = 1)
    (hd0 : ∑ b, q b * d b = 0) (c : ℝ) (hc : ∀ b, |d b| ≤ c) (S : ℝ) :
    ∑ b, q b * (S + d b) ^ 2 ≤ S ^ 2 + c ^ 2 := by
  have hpt : ∀ b, q b * (S + d b) ^ 2 ≤ S ^ 2 * q b + 2 * S * (q b * d b) + c ^ 2 * q b := by
    intro b
    have h1 : d b ^ 2 ≤ c ^ 2 := by
      rw [← sq_abs]; exact pow_le_pow_left₀ (abs_nonneg _) (hc b) 2
    have : q b * d b ^ 2 ≤ q b * c ^ 2 := mul_le_mul_of_nonneg_left h1 (hq b)
    nlinarith
  refine (Finset.sum_le_sum fun b _ => hpt b).trans (le_of_eq ?_)
  rw [Finset.sum_add_distrib, Finset.sum_add_distrib, ← Finset.mul_sum, ← Finset.mul_sum,
    ← Finset.mul_sum, hq1, hd0]
  ring

lemma inner_four {ι : Type*} [Fintype ι] (q d : ι → ℝ) (hq : ∀ b, 0 ≤ q b) (hq1 : ∑ b, q b = 1)
    (hd0 : ∑ b, q b * d b = 0) (c : ℝ) (hc : ∀ b, |d b| ≤ c) (S : ℝ) :
    ∑ b, q b * (S + d b) ^ 4 ≤ S ^ 4 + 8 * c ^ 2 * S ^ 2 + 3 * c ^ 4 := by
  have hpt : ∀ b, q b * (S + d b) ^ 4 ≤
      (S ^ 4 + 8 * c ^ 2 * S ^ 2 + 3 * c ^ 4) * q b + 4 * S ^ 3 * (q b * d b) := by
    intro b
    have hc0 : 0 ≤ c := (abs_nonneg _).trans (hc b)
    have h1 : d b ^ 2 ≤ c ^ 2 := by
      rw [← sq_abs]; exact pow_le_pow_left₀ (abs_nonneg _) (hc b) 2
    have h4 : d b ^ 4 ≤ c ^ 4 := by
      have : d b ^ 4 = (d b ^ 2) ^ 2 := by ring
      rw [this, show c ^ 4 = (c ^ 2) ^ 2 by ring]
      exact pow_le_pow_left₀ (sq_nonneg _) h1 2
    have h3 : S * d b ^ 3 ≤ |S| * c ^ 3 := by
      calc S * d b ^ 3 ≤ |S * d b ^ 3| := le_abs_self _
        _ = |S| * |d b| ^ 3 := by rw [abs_mul, abs_pow]
        _ ≤ |S| * c ^ 3 := mul_le_mul_of_nonneg_left
            (pow_le_pow_left₀ (abs_nonneg _) (hc b) 3) (abs_nonneg _)
    have h3' : 4 * (|S| * c ^ 3) ≤ 2 * c ^ 2 * S ^ 2 + 2 * c ^ 4 := by
      have : 0 ≤ 2 * c ^ 2 * (|S| - c) ^ 2 := by positivity
      have hS : |S| ^ 2 = S ^ 2 := sq_abs S
      nlinarith
    have h2 : S ^ 2 * d b ^ 2 ≤ S ^ 2 * c ^ 2 := mul_le_mul_of_nonneg_left h1 (sq_nonneg _)
    have key : (S + d b) ^ 4 ≤ S ^ 4 + 8 * c ^ 2 * S ^ 2 + 3 * c ^ 4 + 4 * S ^ 3 * d b := by
      nlinarith
    have := mul_le_mul_of_nonneg_left key (hq b)
    nlinarith
  refine (Finset.sum_le_sum fun b _ => hpt b).trans (le_of_eq ?_)
  rw [Finset.sum_add_distrib, ← Finset.mul_sum, ← Finset.mul_sum, hq1, hd0]
  ring

lemma moment_bounds {ι Ω : Type*} [Fintype ι] [DecidableEq ι] [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] (P : Matrix ι ι ℝ) (hP : P ∈ rowStochastic ℝ ι) (X : ℕ → Ω → ι)
    (hX : ∀ n i, MeasurableSet {ω | X n ω = i})
    (hMarkov : ∀ (n : ℕ) (s : ℕ → ι),
      μ.real {ω | ∀ k ≤ n + 1, X k ω = s k} =
        μ.real {ω | ∀ k ≤ n, X k ω = s k} * P (s n) (s (n + 1)))
    (D : ι → ι → ℝ) (hD0 : ∀ a, ∑ b, P a b * D a b = 0) (c : ℝ) (hc : ∀ a b, |D a b| ≤ c)
    (n : ℕ) :
    ∑ t, μ.real {ω | pathOf X n ω = t} * martPart D n t ^ 2 ≤ c ^ 2 * n ∧
      ∑ t, μ.real {ω | pathOf X n ω = t} * martPart D n t ^ 4 ≤ 8 * c ^ 4 * n ^ 2 := by
  classical
  induction n with
  | zero => simp [martPart]
  | succ n ih =>
    have hq : ∀ a b, 0 ≤ P a b := hP.1
    have hq1 : ∀ a, ∑ b, P a b = 1 := sum_row_of_mem_rowStochastic hP
    have s2 := moment_step μ P X hMarkov D (fun x => x ^ 2) (fun S => S ^ 2 + c ^ 2)
      (fun a S => inner_sq (P a) (D a) (hq a) (hq1 a) (hD0 a) c (hc a) S) n
    have s4 := moment_step μ P X hMarkov D (fun x => x ^ 4)
      (fun S => S ^ 4 + 8 * c ^ 2 * S ^ 2 + 3 * c ^ 4)
      (fun a S => inner_four (P a) (D a) (hq a) (hq1 a) (hD0 a) c (hc a) S) n
    have hw := sum_measureReal_path μ X hX n
    have e2 : ∑ t, μ.real {ω | pathOf X n ω = t} * (martPart D n t ^ 2 + c ^ 2) =
        ∑ t, μ.real {ω | pathOf X n ω = t} * martPart D n t ^ 2 + c ^ 2 := by
      simp only [mul_add, Finset.sum_add_distrib, ← Finset.sum_mul, hw, one_mul]
    have e4 : ∑ t, μ.real {ω | pathOf X n ω = t} *
          (martPart D n t ^ 4 + 8 * c ^ 2 * martPart D n t ^ 2 + 3 * c ^ 4) =
        ∑ t, μ.real {ω | pathOf X n ω = t} * martPart D n t ^ 4 +
          8 * c ^ 2 * ∑ t, μ.real {ω | pathOf X n ω = t} * martPart D n t ^ 2 + 3 * c ^ 4 := by
      simp only [mul_add, Finset.sum_add_distrib, ← Finset.sum_mul, hw, one_mul, Finset.mul_sum]
      congr 1
      · congr 1
        refine Finset.sum_congr rfl fun t _ => ?_
        ring
    rw [e2] at s2
    rw [e4] at s4
    obtain ⟨ih2, ih4⟩ := ih
    have hc2 : 0 ≤ c ^ 2 := sq_nonneg c
    push_cast
    have hc4 : 0 ≤ c ^ 4 := by positivity
    have hn0 : (0 : ℝ) ≤ n := Nat.cast_nonneg n
    have h8 := mul_le_mul_of_nonneg_left ih2 (by positivity : (0 : ℝ) ≤ 8 * c ^ 2)
    have hcn : 0 ≤ c ^ 4 * (n : ℝ) := mul_nonneg hc4 hn0
    constructor
    · nlinarith
    · have : 8 * c ^ 2 * (c ^ 2 * (n : ℝ)) = 8 * (c ^ 4 * n) := by ring
      nlinarith

lemma tail_bound {ι Ω : Type*} [Fintype ι] [DecidableEq ι] [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] (P : Matrix ι ι ℝ) (hP : P ∈ rowStochastic ℝ ι) (X : ℕ → Ω → ι)
    (hX : ∀ n i, MeasurableSet {ω | X n ω = i})
    (hMarkov : ∀ (n : ℕ) (s : ℕ → ι),
      μ.real {ω | ∀ k ≤ n + 1, X k ω = s k} =
        μ.real {ω | ∀ k ≤ n, X k ω = s k} * P (s n) (s (n + 1)))
    (D : ι → ι → ℝ) (hD0 : ∀ a, ∑ b, P a b * D a b = 0) (c : ℝ) (hc : ∀ a b, |D a b| ≤ c)
    (r n : ℕ) :
    ((n : ℝ) + 1) ^ 2 * μ.real {ω | (n : ℝ) ≤ ((r : ℝ) + 1) * |martPart D n (pathOf X n ω)|} ≤
      1 + 32 * c ^ 4 * ((r : ℝ) + 1) ^ 4 := by
  classical
  set A := μ.real {ω | (n : ℝ) ≤ ((r : ℝ) + 1) * |martPart D n (pathOf X n ω)|} with hA
  have hA0 : 0 ≤ A := measureReal_nonneg
  have hA1 : A ≤ 1 := measureReal_le_one
  have hK : 0 ≤ 32 * c ^ 4 * ((r : ℝ) + 1) ^ 4 := by positivity
  rcases Nat.eq_zero_or_pos n with hn | hn
  · subst hn; simp only [Nat.cast_zero, zero_add, one_pow, one_mul]; linarith
  have hn1 : (1 : ℝ) ≤ n := by exact_mod_cast hn
  have hsum := measureReal_path_pred μ X hX n
    (fun t => (n : ℝ) ≤ ((r : ℝ) + 1) * |martPart D n t|)
  rw [← hA] at hsum
  have h4 := (moment_bounds μ P hP X hX hMarkov D hD0 c hc n).2
  have hcheb : (n : ℝ) ^ 4 * A ≤ ((r : ℝ) + 1) ^ 4 * (8 * c ^ 4 * (n : ℝ) ^ 2) := by
    rw [hsum, Finset.mul_sum]
    calc ∑ t ∈ Finset.univ.filter (fun t => (n : ℝ) ≤ ((r : ℝ) + 1) * |martPart D n t|),
          (n : ℝ) ^ 4 * μ.real {ω | pathOf X n ω = t}
        ≤ ∑ t ∈ Finset.univ.filter (fun t => (n : ℝ) ≤ ((r : ℝ) + 1) * |martPart D n t|),
          ((r : ℝ) + 1) ^ 4 * (μ.real {ω | pathOf X n ω = t} * martPart D n t ^ 4) := by
          refine Finset.sum_le_sum fun t ht => ?_
          have ht' := (Finset.mem_filter.1 ht).2
          have hp : (n : ℝ) ^ 4 ≤ (((r : ℝ) + 1) * |martPart D n t|) ^ 4 :=
            pow_le_pow_left₀ (by positivity) ht' 4
          have habs : |martPart D n t| ^ 4 = martPart D n t ^ 4 := by
            calc |martPart D n t| ^ 4 = (|martPart D n t| ^ 2) ^ 2 := by ring
              _ = (martPart D n t ^ 2) ^ 2 := by rw [sq_abs]
              _ = martPart D n t ^ 4 := by ring
          rw [mul_pow, habs] at hp
          have hw0 : 0 ≤ μ.real {ω | pathOf X n ω = t} := measureReal_nonneg
          nlinarith
      _ ≤ ∑ t, ((r : ℝ) + 1) ^ 4 * (μ.real {ω | pathOf X n ω = t} * martPart D n t ^ 4) := by
          refine Finset.sum_le_sum_of_subset_of_nonneg (Finset.filter_subset _ _) fun t _ _ => ?_
          have hw0 : 0 ≤ μ.real {ω | pathOf X n ω = t} := measureReal_nonneg
          positivity
      _ ≤ ((r : ℝ) + 1) ^ 4 * (8 * c ^ 4 * (n : ℝ) ^ 2) := by
          rw [← Finset.mul_sum]
          exact mul_le_mul_of_nonneg_left h4 (by positivity)
  have hn2 : 0 < (n : ℝ) ^ 2 := by positivity
  have hA2 : (n : ℝ) ^ 2 * A ≤ 8 * c ^ 4 * ((r : ℝ) + 1) ^ 4 := by
    have : (n : ℝ) ^ 2 * ((n : ℝ) ^ 2 * A) ≤ (n : ℝ) ^ 2 * (8 * c ^ 4 * ((r : ℝ) + 1) ^ 4) := by
      nlinarith
    exact le_of_mul_le_mul_left this hn2
  have hsq : ((n : ℝ) + 1) ^ 2 ≤ 4 * (n : ℝ) ^ 2 := by nlinarith
  have := mul_le_mul_of_nonneg_right hsq hA0
  nlinarith

lemma ae_martPart_div {ι Ω : Type*} [Fintype ι] [DecidableEq ι] [MeasurableSpace Ω] (μ : Measure Ω)
    [IsProbabilityMeasure μ] (P : Matrix ι ι ℝ) (hP : P ∈ rowStochastic ℝ ι) (X : ℕ → Ω → ι)
    (hX : ∀ n i, MeasurableSet {ω | X n ω = i})
    (hMarkov : ∀ (n : ℕ) (s : ℕ → ι),
      μ.real {ω | ∀ k ≤ n + 1, X k ω = s k} =
        μ.real {ω | ∀ k ≤ n, X k ω = s k} * P (s n) (s (n + 1)))
    (D : ι → ι → ℝ) (hD0 : ∀ a, ∑ b, P a b * D a b = 0) (c : ℝ) (hc : ∀ a b, |D a b| ≤ c) :
    ∀ᵐ ω ∂μ, Tendsto (fun n : ℕ => martPart D n (pathOf X n ω) / n) atTop (𝓝 0) := by
  have key : ∀ r : ℕ, ∀ᵐ ω ∂μ, ∀ᶠ n : ℕ in atTop,
      ω ∉ {ω | (n : ℝ) ≤ ((r : ℝ) + 1) * |martPart D n (pathOf X n ω)|} := by
    intro r
    apply ae_eventually_notMem
    set C := 1 + 32 * c ^ 4 * ((r : ℝ) + 1) ^ 4 with hC
    have hC0 : 0 ≤ C := by positivity
    have hsum : Summable (fun n : ℕ => C / ((n : ℝ) + 1) ^ 2) := by
      have := ((summable_nat_add_iff 1).2
        (Real.summable_one_div_nat_pow.2 one_lt_two)).mul_left C
      refine this.congr fun n => ?_
      push_cast
      ring
    have hne : ∑' n : ℕ, ENNReal.ofReal (C / ((n : ℝ) + 1) ^ 2) ≠ ⊤ := by
      rw [← ENNReal.ofReal_tsum_of_nonneg (fun n => by positivity) hsum]
      exact ENNReal.ofReal_ne_top
    refine ne_top_of_le_ne_top hne (tsum_le_tsum fun n => ?_)
    rw [← ofReal_measureReal]
    apply ENNReal.ofReal_le_ofReal
    rw [le_div_iff₀ (by positivity), mul_comm]
    exact tail_bound μ P hP X hX hMarkov D hD0 c hc r n
  filter_upwards [ae_all_iff.2 key] with ω hω
  rw [Metric.tendsto_atTop]
  intro ε hε
  obtain ⟨r, hr⟩ := exists_nat_one_div_lt hε
  obtain ⟨N, hN⟩ := eventually_atTop.1 (hω r)
  refine ⟨max N 1, fun n hn => ?_⟩
  have hn1 : (1 : ℝ) ≤ n := by exact_mod_cast le_of_max_le_right hn
  have h := hN n (le_of_max_le_left hn)
  simp only [not_le] at h
  rw [Real.dist_eq, sub_zero, abs_div, Nat.abs_cast, div_lt_iff₀ (by linarith)]
  have hr' : 1 < ε * ((r : ℝ) + 1) := by
    rwa [div_lt_iff₀ (by positivity)] at hr
  have h1 := mul_lt_mul_of_pos_left h hε
  have h2 : 0 ≤ |martPart D n (pathOf X n ω)| := abs_nonneg _
  nlinarith

lemma count_eq_sum {ι Ω : Type*} [DecidableEq ι] (X : ℕ → Ω → ι) (ω : Ω) (j : ι) (n : ℕ) :
    ((((Finset.Icc 1 n).filter (fun k => X k ω = j)).card : ℕ) : ℝ) =
      ∑ k ∈ Finset.range n, if X (k + 1) ω = j then (1 : ℝ) else 0 := by
  rw [Finset.card_filter]
  push_cast
  induction n with
  | zero => simp
  | succ n ih => rw [Finset.sum_Icc_succ_top (by omega), Finset.sum_range_succ, ih]

#print axioms harmonic_const
#print axioms finrank_ker_one_sub
#print axioms rank_one_sub
#print axioms exists_stationary
#print axioms stationary_unique
#print axioms poisson
#print axioms measurableSet_path
#print axioms measureReal_path_pred
#print axioms sum_measureReal_path
#print axioms measureReal_path_snoc
#print axioms sum_snoc
#print axioms martPart_snoc
#print axioms moment_step
#print axioms inner_sq
#print axioms inner_four
#print axioms moment_bounds
#print axioms tail_bound
#print axioms ae_martPart_div
#print axioms count_eq_sum

/-- **Existence and uniqueness.** On a finite chain where every state can reach every other
(irreducible), there is exactly one stationary distribution: exactly one mix of chances over the
states, with no negative entries and total 1, that one more step leaves unchanged. -/
theorem irreducible_has_unique_stationary_distribution
    {ι : Type*} [Fintype ι] [DecidableEq ι] [Nonempty ι]
    (P : Matrix ι ι ℝ) (hP : P ∈ rowStochastic ℝ ι) (hirr : Irreducible P) :
    ∃! π : ι → ℝ, IsStationaryDistribution P π := by
  obtain ⟨π, hπ⟩ := exists_stationary P hP
  exact ⟨π, hπ, fun π' h' => stationary_unique hP hirr hπ h'⟩

/-- **Existence needs no irreducibility.** Every chain on finitely many states has at least one
stationary distribution. -/
theorem finite_chain_has_stationary_distribution
    {ι : Type*} [Fintype ι] [DecidableEq ι] [Nonempty ι]
    (P : Matrix ι ι ℝ) (hP : P ∈ rowStochastic ℝ ι) :
    ∃ π : ι → ℝ, IsStationaryDistribution P π := by
  exact exists_stationary P hP

/-- **The stationary shares are the long-run time fractions.** Let `X 0, X 1, X 2, …` be a Markov
chain with the fixed table `P` on a finite irreducible state space, from any first day: on a
probability space `(Ω, μ)`, the chance of any run of states `s 0, …, s (n + 1)` is the chance of
`s 0, …, s n` times `P (s n) (s (n + 1))` (tomorrow depends on today only, by the same table
every day). Let `π` be its stationary distribution. Then for every state `j`, with probability 1
the fraction of days among days `1` to `n` that are `j` tends to `π j` as `n` grows. -/
theorem fraction_of_days_tends_to_stationary_share
    {ι : Type*} [Fintype ι] [DecidableEq ι] [Nonempty ι]
    (P : Matrix ι ι ℝ) (hP : P ∈ rowStochastic ℝ ι) (hirr : Irreducible P)
    {Ω : Type*} [MeasurableSpace Ω] (μ : Measure Ω) [IsProbabilityMeasure μ]
    (X : ℕ → Ω → ι) (hX : ∀ n i, MeasurableSet {ω | X n ω = i})
    (hMarkov : ∀ (n : ℕ) (s : ℕ → ι),
      μ.real {ω | ∀ k ≤ n + 1, X k ω = s k} =
        μ.real {ω | ∀ k ≤ n, X k ω = s k} * P (s n) (s (n + 1)))
    (π : ι → ℝ) (hπ : IsStationaryDistribution P π) (j : ι) :
    ∀ᵐ ω ∂μ, Tendsto
      (fun n : ℕ => (((Finset.Icc 1 n).filter (fun k => X k ω = j)).card : ℝ) / n)
      atTop (𝓝 (π j)) := by
  classical
  set f : ι → ℝ := fun i => (if i = j then 1 else 0) - π j with hf
  have hfπ : π ⬝ᵥ f = 0 := by
    simp only [dotProduct, hf, mul_sub, mul_ite, mul_one, mul_zero, Finset.sum_sub_distrib,
      Finset.sum_ite_eq', Finset.mem_univ, ite_true, ← Finset.sum_mul, hπ.2.1, one_mul, sub_self]
  obtain ⟨g, hg⟩ := poisson hP hirr hπ f hfπ
  set h : ι → ℝ := P *ᵥ g with hh
  have hgh : ∀ i, g i - h i = f i := by
    intro i
    have := congrFun hg i
    rw [sub_mulVec, one_mulVec] at this
    exact this
  set D : ι → ι → ℝ := fun a b => g b - h a with hD
  set c : ℝ := ∑ i, |g i| + ∑ i, |h i| with hc
  have hgc : ∀ i, |g i| ≤ ∑ i, |g i| := fun i =>
    Finset.single_le_sum (fun i _ => abs_nonneg (g i)) (Finset.mem_univ i)
  have hhc : ∀ i, |h i| ≤ ∑ i, |h i| := fun i =>
    Finset.single_le_sum (fun i _ => abs_nonneg (h i)) (Finset.mem_univ i)
  have hDc : ∀ a b, |D a b| ≤ c := fun a b =>
    (abs_sub _ _).trans (add_le_add (hgc b) (hhc a))
  have hD0 : ∀ a, ∑ b, P a b * D a b = 0 := by
    intro a
    simp only [hD, mul_sub, Finset.sum_sub_distrib, ← Finset.sum_mul,
      sum_row_of_mem_rowStochastic hP a, one_mul]
    simp [hh, mulVec, dotProduct]
  filter_upwards [ae_martPart_div μ P hP X hX hMarkov D hD0 c hDc] with ω hω
  have hid : ∀ n : ℕ, ((((Finset.Icc 1 n).filter (fun k => X k ω = j)).card : ℕ) : ℝ) =
      n * π j + martPart D n (pathOf X n ω) + (h (X 0 ω) - h (X n ω)) := by
    intro n
    rw [count_eq_sum]
    have hM : martPart D n (pathOf X n ω) =
        ∑ k ∈ Finset.range n, (g (X (k + 1) ω) - h (X k ω)) := by
      unfold martPart
      rw [← Fin.sum_univ_eq_sum_range (fun k => g (X (k + 1) ω) - h (X k ω)) n]
      rfl
    have hsplit : ∑ k ∈ Finset.range n, (g (X (k + 1) ω) - h (X k ω)) =
        ∑ k ∈ Finset.range n, f (X (k + 1) ω) +
          ∑ k ∈ Finset.range n, (h (X (k + 1) ω) - h (X k ω)) := by
      rw [← Finset.sum_add_distrib]
      refine Finset.sum_congr rfl fun k _ => ?_
      rw [← hgh]; ring
    have htel := Finset.sum_range_sub (fun k => h (X k ω)) n
    have hfsum : ∑ k ∈ Finset.range n, f (X (k + 1) ω) =
        (∑ k ∈ Finset.range n, if X (k + 1) ω = j then (1 : ℝ) else 0) - n * π j := by
      simp only [hf, Finset.sum_sub_distrib, Finset.sum_const, Finset.card_range, nsmul_eq_mul]
    rw [hM, hsplit, htel, hfsum]
    ring
  have hB : Tendsto (fun n : ℕ => (h (X 0 ω) - h (X n ω)) / n) atTop (𝓝 0) := by
    refine squeeze_zero_norm (fun n => ?_) (tendsto_const_div_atTop_nhds_zero_nat (2 * c))
    rw [Real.norm_eq_abs, abs_div, Nat.abs_cast]
    refine div_le_div_of_nonneg_right ?_ (Nat.cast_nonneg n)
    have h1 := (abs_sub (h (X 0 ω)) (h (X n ω)))
    have h2 := hhc (X 0 ω)
    have h3 := hhc (X n ω)
    have h4 : 0 ≤ ∑ i, |g i| := Finset.sum_nonneg fun i _ => abs_nonneg (g i)
    linarith
  have hlim := (tendsto_const_nhds (x := π j)).add (hω.add hB)
  simp only [add_zero] at hlim
  refine hlim.congr' ?_
  filter_upwards [eventually_ge_atTop 1] with n hn
  have hn' : (n : ℝ) ≠ 0 := by
    have : (1 : ℝ) ≤ n := by exact_mod_cast hn
    linarith
  rw [hid n]
  field_simp
  ring

/-! Worked numbers from the card, in exact fractions. States in the order sunny, cloudy, rainy. -/

/-- The town's table: after sunny 6, 3, 1 in 10; after cloudy 4, 4, 2; after rainy 4, 3, 3. -/
def town : Matrix (Fin 3) (Fin 3) ℚ :=
  !![6/10, 3/10, 1/10; 4/10, 4/10, 2/10; 4/10, 3/10, 3/10]

-- The town's table is a transition matrix: entries non-negative, each row adds to 1.
example : (∀ i j, 0 ≤ town i j) ∧ ∀ i, ∑ j, town i j = 1 := by
  refine ⟨?_, ?_⟩
  · intro i j; fin_cases i <;> fin_cases j <;> simp [town] <;> norm_num
  · intro i; fin_cases i <;> simp [town, Fin.sum_univ_three] <;> norm_num

-- Every entry is positive, so every state reaches every other in one day.
example : Irreducible town := by
  intro i j; refine ⟨1, ?_⟩
  fin_cases i <;> fin_cases j <;> simp [town]

-- (1/2, 1/3, 1/6) is a stationary distribution of the town's table.
example : IsStationaryDistribution town ![1/2, 1/3, 1/6] := by
  refine ⟨?_, ?_, ?_⟩
  · intro j; fin_cases j <;> simp
  · simp [Fin.sum_univ_three]; norm_num
  · ext j; fin_cases j <;> simp [town, vecMul, dotProduct, Fin.sum_univ_three] <;> norm_num

-- Hand solution: sunny 0.4 π_S = 0.4 π_C + 0.4 π_R with total 1 gives π_S = 1/2; then
-- 0.7 π_R = 0.1 (1/2) + 0.2 (1/2 - π_R), so 0.9 π_R = 0.15 and π_R = 1/6; π_C = 1 - 1/2 - 1/6.
example : (9 : ℚ) / 10 * (1 / 6) = 15 / 100 ∧ (1 : ℚ) - 1 / 2 - 1 / 6 = 1 / 3 := by norm_num
-- The spare cloudy equation: (1/2)(0.3) + (1/3)(0.4) + (1/6)(0.3) = 1/3.
example : (1 : ℚ) / 2 * (3 / 10) + 1 / 3 * (4 / 10) + 1 / 6 * (3 / 10) = 1 / 3 := by norm_num
-- Flow out of rainy per day, (1/6)(0.7), equals flow in, (1/2)(0.1) + (1/3)(0.2): both 7/60.
example : (1 : ℚ) / 6 * (7 / 10) = 7 / 60 ∧
    (1 : ℚ) / 2 * (1 / 10) + 1 / 3 * (2 / 10) = 7 / 60 := by norm_num
-- Mean return times 1/π: sunny 2, cloudy 3, rainy 6 days.
example : 1 / ((1 : ℚ) / 2) = 2 ∧ 1 / ((1 : ℚ) / 3) = 3 ∧ 1 / ((1 : ℚ) / 6) = 6 := by norm_num
-- An excursion from rain: ν = (3, 2, 1), 6 days in all, and ν / 6 = π.
example : (3 : ℚ) + 2 + 1 = 6 ∧ (3 : ℚ) / 6 = 1 / 2 ∧ (2 : ℚ) / 6 = 1 / 3 ∧ (1 : ℚ) / 6 = 1 / 6 := by
  norm_num
-- Detailed balance fails: π_S p_SR = 1/20 but π_R p_RS = 1/15.
example : (1 : ℚ) / 2 * (1 / 10) = 1 / 20 ∧ (1 : ℚ) / 6 * (4 / 10) = 1 / 15 ∧
    (1 : ℚ) / 20 ≠ 1 / 15 := by norm_num
-- Mistakes: averaging the rain column gives 1/5; rain after rain is 3/10; neither is 1/6.
example : ((1 : ℚ) / 10 + 2 / 10 + 3 / 10) / 3 = 1 / 5 ∧ (1 : ℚ) / 5 ≠ 1 / 6 ∧
    (3 : ℚ) / 10 ≠ 1 / 6 := by norm_num
-- Mistake: the column of ones solves P x = x for the town, giving the uniform 1/3.
example : town *ᵥ (fun _ => 1) = fun _ => 1 := by
  ext i; fin_cases i <;> simp [town, mulVec, dotProduct, Fin.sum_univ_three] <;> norm_num

/-- The rota: sunny, then cloudy, then rainy, then sunny again, for certain. -/
def rota : Matrix (Fin 3) (Fin 3) ℚ := !![0, 1, 0; 0, 0, 1; 1, 0, 0]

-- The rota's stationary distribution is (1/3, 1/3, 1/3).
example : IsStationaryDistribution rota ![1/3, 1/3, 1/3] := by
  refine ⟨?_, ?_, ?_⟩
  · intro j; fin_cases j <;> simp
  · simp [Fin.sum_univ_three]; norm_num
  · ext j; fin_cases j <;> simp [rota, vecMul, dotProduct, Fin.sum_univ_three]

-- From a sunny day the rota's chance of rain on day 10 is 0 and on day 11 is 1: no settling.
example : (rota ^ 10) 0 2 = 0 ∧ (rota ^ 11) 0 2 = 1 := by
  simp [rota, pow_succ]

/-- The split climate: a dry spell (sunny and cloudy, half and half) that never rains and a wet
spell that never clears. -/
def split : Matrix (Fin 3) (Fin 3) ℚ := !![1/2, 1/2, 0; 1/2, 1/2, 0; 0, 0, 1]

-- Without irreducibility two different mixes balance: (1/2, 1/2, 0) and (0, 0, 1).
example : IsStationaryDistribution split ![1/2, 1/2, 0] ∧
    IsStationaryDistribution split ![0, 0, 1] ∧ (![1/2, 1/2, 0] : Fin 3 → ℚ) ≠ ![0, 0, 1] := by
  refine ⟨⟨?_, ?_, ?_⟩, ⟨?_, ?_, ?_⟩, ?_⟩
  · intro j; fin_cases j <;> simp
  · simp [Fin.sum_univ_three]; norm_num
  · ext j; fin_cases j <;> simp [split, vecMul, dotProduct, Fin.sum_univ_three] <;> norm_num
  · intro j; fin_cases j <;> simp
  · simp [Fin.sum_univ_three]
  · ext j; fin_cases j <;> simp [split, vecMul, dotProduct, Fin.sum_univ_three]
  · intro h; have := congrFun h 2; simp at this

#print axioms irreducible_has_unique_stationary_distribution
#print axioms finite_chain_has_stationary_distribution
#print axioms fraction_of_days_tends_to_stationary_share

end StationaryDistributions
