-- Compressed sensing: a certificate whose correlation is the unit direction on every nonzero bin and below 1 in size on every other bin proves that the spectrum is the unique fit with the smallest summed size of bins, two fits with few nonzero entries agree when every small set of columns is independent, and in the one-reading miniature the least summed size lands on a corner.
import Mathlib.Data.Matrix.Mul
import Mathlib.LinearAlgebra.LinearIndependent.Defs
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Tactic.NormNum

open Matrix Finset

/-- The size of bin `k` of a spectrum `z`: the square root of the sum of squares of the
entries `z j` whose slot `j` belongs to bin `k` (for the card, a bin's cosine and sine weight). -/
noncomputable def binSize {ι K : Type*} [Fintype ι] [DecidableEq K] (bin : ι → K)
    (z : ι → ℝ) (k : K) : ℝ :=
  Real.sqrt (∑ j ∈ univ.filter (fun j => bin j = k), z j ^ 2)

lemma binSize_nonneg' {ι K : Type*} [Fintype ι] [DecidableEq K] (bin : ι → K)
    (z : ι → ℝ) (k : K) : 0 ≤ binSize bin z k := Real.sqrt_nonneg _

lemma binSize_sq {ι K : Type*} [Fintype ι] [DecidableEq K] (bin : ι → K)
    (z : ι → ℝ) (k : K) :
    binSize bin z k ^ 2 = ∑ j ∈ univ.filter (fun j => bin j = k), z j ^ 2 :=
  Real.sq_sqrt (Finset.sum_nonneg fun _ _ => sq_nonneg _)

lemma binSize_eq_zero_imp {ι K : Type*} [Fintype ι] [DecidableEq K] (bin : ι → K)
    (z : ι → ℝ) (k : K) (h : binSize bin z k = 0) (j : ι) (hj : bin j = k) : z j = 0 := by
  have h2 := binSize_sq bin z k
  rw [h] at h2
  have hall := (Finset.sum_eq_zero_iff_of_nonneg (fun i _ => sq_nonneg (z i))).1
    (by rw [← h2]; ring)
  have := hall j (by simp [hj])
  exact (pow_eq_zero_iff two_ne_zero).1 this

lemma binSize_cs {ι K : Type*} [Fintype ι] [DecidableEq K] (bin : ι → K)
    (f g : ι → ℝ) (k : K) :
    ∑ j ∈ univ.filter (fun j => bin j = k), f j * g j ≤ binSize bin f k * binSize bin g k :=
  Real.sum_mul_le_sqrt_mul_sqrt _ f g

#print axioms binSize_nonneg'
#print axioms binSize_sq
#print axioms binSize_eq_zero_imp
#print axioms binSize_cs

/-- **The certificate proves the fit with the smallest summed size is exact (Step 3).**
A spectrum `z` has its entries (slots `ι`) grouped into frequency bins `K` by `bin`, and the
sensing matrix `A` takes the kept readings `A z`. Suppose weights `v`, one per kept reading,
give a correlation `g = Aᵀ v` that, read bin by bin, is exactly the unit direction
`z_k / ‖z_k‖` on every bin where `z` is nonzero, and has size smaller than 1 on every other bin;
and suppose the columns of `A` belonging to the nonzero bins of `z` are independent. Then every
other spectrum that fits the same readings has a strictly larger summed size of bins: `z` is the
unique fit with the smallest summed size. -/
theorem certificate_proves_unique_smallest_fit {σ ι K : Type*} [Fintype σ] [Fintype ι]
    [Fintype K] [DecidableEq K] (bin : ι → K) (A : Matrix σ ι ℝ) (z : ι → ℝ) (v : σ → ℝ)
    (hon : ∀ j, binSize bin z (bin j) ≠ 0 → (Aᵀ *ᵥ v) j = z j / binSize bin z (bin j))
    (hoff : ∀ k, binSize bin z k = 0 → binSize bin (Aᵀ *ᵥ v) k < 1)
    (hind : LinearIndependent ℝ (fun j : {j : ι // binSize bin z (bin j) ≠ 0} => Aᵀ j.1)) :
    ∀ x : ι → ℝ, A *ᵥ x = A *ᵥ z → x ≠ z →
      ∑ k, binSize bin z k < ∑ k, binSize bin x k := by
  intro x hx hne
  classical
  set g := Aᵀ *ᵥ v with hg
  set h : ι → ℝ := x - z with hh
  obtain ⟨c, hc⟩ : ∃ c : K → ℝ,
      c = fun k => ∑ j ∈ univ.filter (fun j => bin j = k), g j * h j := ⟨_, rfl⟩
  have hAh : A *ᵥ h = 0 := by simp [hh, Matrix.mulVec_sub, hx]
  have hsum0 : ∑ k, c k = 0 := by
    have e1 : ∑ k, c k = ∑ j, g j * h j := by
      simp only [hc]
      exact Finset.sum_fiberwise univ bin (fun j => g j * h j)
    rw [e1]
    have e2 : ∑ j, g j * h j = g ⬝ᵥ h := rfl
    rw [e2, hg, Matrix.mulVec_transpose, ← Matrix.dotProduct_mulVec, hAh, dotProduct_zero]
  have hbin : ∀ k, binSize bin z k + c k ≤ binSize bin x k ∧
      (binSize bin z k = 0 → c k ≤ binSize bin g k * binSize bin x k) := by
    intro k
    by_cases hk : binSize bin z k = 0
    · have hck : c k ≤ binSize bin g k * binSize bin x k := by
        have e : c k = ∑ j ∈ univ.filter (fun j => bin j = k), g j * x j := by
          simp only [hc]
          apply Finset.sum_congr rfl
          intro j hj
          have hj' : bin j = k := (Finset.mem_filter.1 hj).2
          simp [hh, binSize_eq_zero_imp bin z k hk j hj']
        rw [e]; exact binSize_cs bin g x k
      refine ⟨?_, fun _ => hck⟩
      have h1 := hoff k hk
      have h2 := binSize_nonneg' bin g k
      have h3 := binSize_nonneg' bin x k
      rw [hk]; nlinarith
    · refine ⟨?_, fun h0 => absurd h0 hk⟩
      have hnpos : 0 < binSize bin z k := lt_of_le_of_ne (binSize_nonneg' bin z k) (Ne.symm hk)
      have hn2 := binSize_sq bin z k
      have hcn : c k * binSize bin z k =
          ∑ j ∈ univ.filter (fun j => bin j = k), z j * x j - binSize bin z k ^ 2 := by
        rw [hn2, hc, Finset.sum_mul, ← Finset.sum_sub_distrib]
        apply Finset.sum_congr rfl
        intro j hj
        have hj' : bin j = k := (Finset.mem_filter.1 hj).2
        have e := hon j (by rw [hj']; exact hk)
        rw [hj'] at e
        rw [e]
        simp only [hh, Pi.sub_apply]
        field_simp
      have hcs := binSize_cs bin z x k
      have h3 := binSize_nonneg' bin x k
      by_contra hlt
      replace hlt := not_le.1 hlt
      have : binSize bin x k * binSize bin z k < (binSize bin z k + c k) * binSize bin z k :=
        mul_lt_mul_of_pos_right hlt hnpos
      nlinarith
  by_contra hlt
  replace hlt := not_lt.1 hlt
  have hterm : ∀ k ∈ (univ : Finset K), 0 ≤ binSize bin x k - binSize bin z k - c k :=
    fun k _ => by linarith [(hbin k).1]
  have htot : ∑ k, (binSize bin x k - binSize bin z k - c k) = 0 := by
    apply le_antisymm
    · rw [Finset.sum_sub_distrib, Finset.sum_sub_distrib, hsum0]; linarith
    · exact Finset.sum_nonneg hterm
  have heach := (Finset.sum_eq_zero_iff_of_nonneg hterm).1 htot
  have hoffx : ∀ j, binSize bin z (bin j) = 0 → h j = 0 := by
    intro j hj
    have e := heach (bin j) (mem_univ _)
    have hck := (hbin (bin j)).2 hj
    have h1 := hoff (bin j) hj
    have h2 := binSize_nonneg' bin x (bin j)
    have h3 := binSize_nonneg' bin g (bin j)
    rw [hj] at e
    have hx0 : binSize bin x (bin j) = 0 := le_antisymm (by nlinarith) h2
    have ex := binSize_eq_zero_imp bin x (bin j) hx0 j rfl
    have ez := binSize_eq_zero_imp bin z (bin j) hj j rfl
    simp [hh, ex, ez]
  have hS : ∀ j, binSize bin z (bin j) ≠ 0 → h j = 0 := by
    intro j hj
    refine (Fintype.linearIndependent_iff.1 hind) (fun i => h i.1) ?_ ⟨j, hj⟩
    ext r
    have hr : (A *ᵥ h) r = 0 := by rw [hAh]; rfl
    simp only [Finset.sum_apply, Pi.smul_apply, smul_eq_mul, Pi.zero_apply,
      Matrix.transpose_apply]
    refine Eq.trans ?_ hr
    simp only [Matrix.mulVec, dotProduct]
    rw [← Fintype.sum_subtype_add_sum_subtype (fun j => binSize bin z (bin j) ≠ 0)
      (fun j => A r j * h j)]
    have e0 : ∑ i : {j // ¬ binSize bin z (bin j) ≠ 0}, A r i.1 * h i.1 = 0 :=
      Finset.sum_eq_zero (fun i _ => by rw [hoffx i.1 (not_not.1 i.2)]; ring)
    rw [e0, add_zero]
    apply Finset.sum_congr rfl
    intro i _
    ring
  apply hne
  funext j
  have : h j = 0 := by
    by_cases hj : binSize bin z (bin j) = 0
    · exact hoffx j hj
    · exact hS j hj
  have e : h j = x j - z j := rfl
  linarith

/-- **Counting gives a unique answer (Step 1).** If every set of at most `2s` columns of the
sensing matrix `A` is independent, then two spectra that each have at most `s` nonzero entries
and fit the same readings are equal: the sparsest fit is the true one. -/
theorem sparsest_fit_unique {σ ι : Type*} [Fintype σ] [Fintype ι] (A : Matrix σ ι ℝ) (s : ℕ)
    (hA : ∀ T : Finset ι, T.card ≤ 2 * s → LinearIndependent ℝ (fun j : T => Aᵀ j.1))
    (z z' : ι → ℝ) (hz : (univ.filter (fun j => z j ≠ 0)).card ≤ s)
    (hz' : (univ.filter (fun j => z' j ≠ 0)).card ≤ s) (hfit : A *ᵥ z = A *ᵥ z') :
    z = z' := by
  classical
  set T := univ.filter (fun j => z j ≠ 0) ∪ univ.filter (fun j => z' j ≠ 0) with hT
  have hcard : T.card ≤ 2 * s := (card_union_le _ _).trans (by omega)
  have hli := Fintype.linearIndependent_iff.1 (hA T hcard)
  have hoff : ∀ j, j ∉ T → z j - z' j = 0 := by
    intro j hj
    simp only [hT, mem_union, mem_filter, mem_univ, true_and, not_or, not_not] at hj
    rw [hj.1, hj.2, sub_self]
  have hAh : ∀ r, ∑ j, A r j * (z j - z' j) = 0 := by
    intro r
    have := congrFun hfit r
    simp only [Matrix.mulVec, dotProduct] at this
    rw [Finset.sum_congr rfl (fun j _ => mul_sub (A r j) (z j) (z' j)),
      Finset.sum_sub_distrib, this, sub_self]
  have hzero : ∀ j ∈ T, z j - z' j = 0 := by
    intro j hj
    refine hli (fun i => z i.1 - z' i.1) ?_ ⟨j, hj⟩
    ext r
    simp only [Finset.sum_apply, Pi.smul_apply, smul_eq_mul, Pi.zero_apply,
      Matrix.transpose_apply]
    rw [← hAh r, Finset.sum_coe_sort T (fun i => (z i - z' i) * A r i)]
    rw [Finset.sum_subset (subset_univ T) (fun j _ hj => by rw [hoff j hj]; ring)]
    apply Finset.sum_congr rfl
    intro i _
    ring
  funext j
  by_cases hj : j ∈ T
  · linarith [hzero j hj]
  · linarith [hoff j hj]

/-- **The swap in miniature.** One reading says `first + 2 × second = 2`. Among all fits, the
least energy (sum of squares) is `4/5`, reached only at `(2/5, 4/5)`, both entries nonzero; the
least summed size `|first| + |second|` is `1`, reached only at the corner `(0, 1)`. -/
theorem miniature_least_energy_vs_least_summed_size :
    (∀ a b : ℝ, a + 2 * b = 2 → 4 / 5 ≤ a ^ 2 + b ^ 2 ∧
      (a ^ 2 + b ^ 2 = 4 / 5 → a = 2 / 5 ∧ b = 4 / 5)) ∧
    (∀ a b : ℝ, a + 2 * b = 2 → 1 ≤ |a| + |b| ∧ (|a| + |b| = 1 → a = 0 ∧ b = 1)) := by
  refine ⟨fun a b hab => ?_, fun a b hab => ?_⟩
  · have ha : a = 2 - 2 * b := by linarith
    subst ha
    refine ⟨by nlinarith [sq_nonneg (b - 4 / 5)], fun he => ?_⟩
    have hb : (b - 4 / 5) ^ 2 = 0 := by nlinarith
    have hb' : b = 4 / 5 := by
      have := (pow_eq_zero_iff two_ne_zero).1 hb
      linarith
    exact ⟨by linarith, hb'⟩
  · have ha : a = 2 - 2 * b := by linarith
    subst ha
    constructor
    · rcases abs_cases (2 - 2 * b) with ⟨h1, h2⟩ | ⟨h1, h2⟩ <;>
        rcases abs_cases b with ⟨h3, h4⟩ | ⟨h3, h4⟩ <;> linarith
    · intro he
      have hb : b = 1 := by
        rcases abs_cases (2 - 2 * b) with ⟨h1, h2⟩ | ⟨h1, h2⟩ <;>
          rcases abs_cases b with ⟨h3, h4⟩ | ⟨h3, h4⟩ <;> linarith
      subst hb
      norm_num

-- The card's whole-number worked examples.
-- 1000 readings hold bins 0 to 500: 501 frequencies, 500 of them nonzero.
example : 1000 / 2 + 1 = 501 := by norm_num
-- Bin spacing 44,100 / 1000 = 44.1 Hz, and the three tones sit on bins 5, 15 and 80.
example : (44100 : ℚ) / 1000 = 441 / 10 := by norm_num
example : (5 : ℚ) * (441 / 10) = 441 / 2 ∧ (15 : ℚ) * (441 / 10) = 1323 / 2 ∧
    (80 : ℚ) * (441 / 10) = 3528 := by norm_num
-- Even sampling for the top tone: more than 2 × 3528 per second, more than 2 × 80 readings.
example : 2 * 3528 = 7056 ∧ 2 * 80 = 160 ∧ 40 * 4 = 160 := by norm_num
-- Keeping 40 of 1000 readings is 4%; every 25th reading is 40 readings at 44,100 / 25 = 1764 Hz.
example : (40 : ℚ) / 1000 = 4 / 100 ∧ 1000 / 25 = 40 ∧ 44100 / 25 = 1764 := by norm_num
-- Summed size of the chord: 100 + 60 + 40 = 200 mV; two tones per bin give s = 6, so 2s = 12.
example : 100 + 60 + 40 = 200 ∧ 2 * 3 = 6 ∧ 2 * 6 = 12 := by norm_num
-- Counting search: 3 of 500 bins, and 10 of 500 bins.
example : Nat.choose 500 3 = 20708500 := by
  norm_num [Nat.choose_eq_descFactorial_div_factorial, Nat.descFactorial, Nat.factorial]
example : Nat.choose 500 10 = 245810588801891098700 := by
  norm_num [Nat.choose_eq_descFactorial_div_factorial, Nat.descFactorial, Nat.factorial]
-- The miniature: least energy (2/5, 4/5) fits the reading and has summed size 6/5;
-- the corner (0, 1) fits it with summed size 1.
example : (2 / 5 : ℚ) + 2 * (4 / 5) = 2 ∧ (2 / 5 : ℚ) + 4 / 5 = 6 / 5 ∧
    (0 : ℚ) + 2 * 1 = 2 := by norm_num

#print axioms certificate_proves_unique_smallest_fit
#print axioms sparsest_fit_unique
#print axioms miniature_least_energy_vs_least_summed_size
