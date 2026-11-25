-- Roth's theorem: a progression-free set in 1 to N has fewer than 72 N / log log N members, so its share tends to 0, and progressions mod M are counted by a sum of waves.
import Mathlib.Combinatorics.Additive.AP.Three.Defs
import Mathlib.Analysis.SpecialFunctions.Complex.CircleAddChar
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Topology.Instances.Real.Lemmas
import Mathlib.Combinatorics.Additive.Corner.Roth
import Mathlib.NumberTheory.DiophantineApproximation.Basic
import Mathlib.NumberTheory.LegendreSymbol.AddCharacter
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Bounds
import Mathlib.Analysis.Real.Pi.Bounds
import Mathlib.Analysis.Complex.ExponentialBounds

open Finset Filter Topology

/-- The size of wave `ξ` in a set `A` of residues mod `M`:
`(1/M) * ∑ x, 1_A(x) * e(-x ξ / M)`, where `ZMod.stdAddChar j = exp (2 π i j / M)`. -/
noncomputable def waveSize (M : ℕ) [NeZero M] (A : Finset (ZMod M)) (ξ : ZMod M) : ℂ :=
  (1 / (M : ℂ)) * ∑ x : ZMod M, (if x ∈ A then (1 : ℂ) else 0) * ZMod.stdAddChar (-(x * ξ))

/-- `ee t = exp (2 π i t)`. -/
noncomputable def rothE (t : ℝ) : ℂ := Complex.exp (Complex.I * ((2 * Real.pi * t : ℝ) : ℂ))

lemma rothE_add (s t : ℝ) : rothE (s + t) = rothE s * rothE t := by
  unfold rothE
  rw [← Complex.exp_add]; congr 1; push_cast; ring

#print axioms rothE_add

lemma rothE_int (k : ℤ) : rothE k = 1 := by
  unfold rothE
  rw [Complex.exp_eq_one_iff]
  exact ⟨k, by push_cast; ring⟩

#print axioms rothE_int

lemma norm_rothE (t : ℝ) : ‖rothE t‖ = 1 := by
  unfold rothE
  exact Complex.norm_exp_I_mul_ofReal _

#print axioms norm_rothE

lemma rothE_neg (t : ℝ) : rothE (-t) = starRingEnd ℂ (rothE t) := by
  unfold rothE
  rw [← Complex.exp_conj]; congr 1
  rw [map_mul, Complex.conj_I, Complex.conj_ofReal]; push_cast; ring

#print axioms rothE_neg

lemma norm_rothE_sub_one (t : ℝ) : ‖rothE t - 1‖ ≤ 2 * Real.pi * |t| := by
  unfold rothE
  refine Real.norm_exp_I_mul_ofReal_sub_one_le.trans ?_
  rw [Real.norm_eq_abs, abs_mul, abs_of_pos (by positivity : (0:ℝ) < 2 * Real.pi)]

#print axioms norm_rothE_sub_one

lemma rothE_nat_mul (n : ℕ) (t : ℝ) : rothE (n * t) = rothE t ^ n := by
  induction n with
  | zero => simp [rothE]
  | succ n ih => rw [pow_succ, ← ih, ← rothE_add]; congr 1; push_cast; ring

#print axioms rothE_nat_mul

lemma rothE_ne_one (t : ℝ) (h : rothE t = 1) : ∃ k : ℤ, t = k := by
  unfold rothE at h
  rw [Complex.exp_eq_one_iff] at h
  obtain ⟨k, hk⟩ := h
  refine ⟨k, ?_⟩
  have h2 : (((2 * Real.pi * t : ℝ)) : ℂ) * Complex.I = ((2 * Real.pi * k : ℝ) : ℂ) * Complex.I := by
    rw [mul_comm]; rw [hk]; push_cast; ring
  have h3 := mul_right_cancel₀ Complex.I_ne_zero h2
  have h4 : 2 * Real.pi * t = 2 * Real.pi * k := by exact_mod_cast h3
  have hpi : (2 * Real.pi) ≠ 0 := by positivity
  exact mul_left_cancel₀ hpi h4

#print axioms rothE_ne_one

/-- Orthogonality: `∑_{ξ < M} e(k ξ / M) = M` if `k = 0` and `0` if `0 < |k| < M`. -/
lemma sum_rothE (M : ℕ) (hM : 0 < M) (k : ℤ) (hk : |k| < M) :
    ∑ ξ ∈ range M, rothE (k * ξ / M) = if k = 0 then (M : ℂ) else 0 := by
  split_ifs with h0
  · subst h0; simp [rothE]
  · have hterm : ∀ ξ : ℕ, rothE (k * ξ / M) = rothE (k / M) ^ ξ := by
      intro ξ; rw [← rothE_nat_mul]; congr 1; ring
    simp_rw [hterm]
    have hr : rothE (k / M) ≠ 1 := by
      intro h
      obtain ⟨j, hj⟩ := rothE_ne_one _ h
      have hMr : (M : ℝ) ≠ 0 := by positivity
      have hkj : (k : ℝ) = j * M := by field_simp at hj; linarith
      have hkj' : k = j * M := by exact_mod_cast hkj
      rcases eq_or_ne j 0 with hj0 | hj0
      · exact h0 (by simp [hkj', hj0])
      · have : (M : ℤ) ≤ |k| := by
          rw [hkj', abs_mul, abs_of_nonneg (by positivity : (0:ℤ) ≤ M)]
          have : 1 ≤ |j| := Int.one_le_abs hj0
          nlinarith
        linarith
    rw [geom_sum_eq hr, ← rothE_nat_mul]
    have : ((M : ℕ) : ℝ) * (k / M) = (k : ℝ) := by field_simp
    rw [this, rothE_int]; simp

#print axioms sum_rothE

/-- The progression count `#{(a, c, b) : a + c = 2 b}` weighted by `g b`, written with waves. -/
lemma roth_fourier (n : ℕ) (A : Finset ℕ) (hA : A ⊆ range n) (g : ℕ → ℝ) :
    ((2 * n : ℕ) : ℂ) * (((∑ a ∈ A, ∑ c ∈ A, ∑ b ∈ range n,
        if a + c = 2 * b then g b else 0 : ℝ)) : ℂ) =
      ∑ ξ ∈ range (2 * n), (∑ a ∈ A, rothE (a * ξ / (2 * n : ℕ))) ^ 2 *
        ∑ b ∈ range n, (g b : ℂ) * rothE (b * (-2 * ξ / (2 * n : ℕ))) := by
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · simp
  set M := 2 * n with hMdef
  have hM : 0 < M := by omega
  symm
  calc ∑ ξ ∈ range M, (∑ a ∈ A, rothE (a * ξ / (M : ℕ))) ^ 2 *
        ∑ b ∈ range n, (g b : ℂ) * rothE (b * (-2 * ξ / (M : ℕ)))
      = ∑ ξ ∈ range M, ∑ a ∈ A, ∑ c ∈ A, ∑ b ∈ range n,
          (g b : ℂ) * rothE ((((a : ℤ) + c - 2 * b : ℤ) : ℝ) * ξ / M) := by
        refine sum_congr rfl fun ξ _ => ?_
        rw [sq, sum_mul_sum, sum_mul]
        refine sum_congr rfl fun a _ => ?_
        rw [sum_mul]
        refine sum_congr rfl fun c _ => ?_
        rw [mul_sum]
        refine sum_congr rfl fun b _ => ?_
        rw [show ((((a : ℤ) + c - 2 * b : ℤ) : ℝ) * ξ / M) =
            a * ξ / M + c * ξ / M + b * (-2 * ξ / M) by push_cast; ring, rothE_add, rothE_add]
        ring
    _ = ∑ a ∈ A, ∑ c ∈ A, ∑ b ∈ range n, ∑ ξ ∈ range M,
          (g b : ℂ) * rothE ((((a : ℤ) + c - 2 * b : ℤ) : ℝ) * ξ / M) := by
        rw [sum_comm]
        refine sum_congr rfl fun a _ => ?_
        rw [sum_comm]
        refine sum_congr rfl fun c _ => ?_
        rw [sum_comm]
    _ = ∑ a ∈ A, ∑ c ∈ A, ∑ b ∈ range n,
          (g b : ℂ) * (if ((a : ℤ) + c - 2 * b : ℤ) = 0 then (M : ℂ) else 0) := by
        refine sum_congr rfl fun a ha => sum_congr rfl fun c hc => sum_congr rfl fun b hb => ?_
        rw [← mul_sum, sum_rothE M hM]
        have ha' := mem_range.1 (hA ha)
        have hc' := mem_range.1 (hA hc)
        have hb' := mem_range.1 hb
        rw [abs_lt]; constructor <;> omega
    _ = _ := by
        push_cast
        rw [mul_sum]
        refine sum_congr rfl fun a _ => ?_
        rw [mul_sum]
        refine sum_congr rfl fun c _ => ?_
        rw [mul_sum]
        refine sum_congr rfl fun b _ => ?_
        by_cases h : a + c = 2 * b
        · have : ((a : ℤ) + c - 2 * b) = 0 := by omega
          rw [if_pos this, if_pos h]; ring
        · have : ¬ ((a : ℤ) + c - 2 * b) = 0 := by omega
          simp [h, this]

#print axioms roth_fourier

/-- Parseval for a set of whole numbers below `M`. -/
lemma roth_parseval (M : ℕ) (hM : 0 < M) (A : Finset ℕ) (hA : ∀ a ∈ A, a < M) :
    ∑ ξ ∈ range M, ‖∑ a ∈ A, rothE (a * ξ / M)‖ ^ 2 = M * #A := by
  have key : ((∑ ξ ∈ range M, ‖∑ a ∈ A, rothE (a * ξ / M)‖ ^ 2 : ℝ) : ℂ) = (M : ℂ) * #A := by
    push_cast
    simp_rw [← Complex.mul_conj', map_sum, ← rothE_neg, sum_mul_sum]
    calc ∑ ξ ∈ range M, ∑ a ∈ A, ∑ c ∈ A, rothE (a * ξ / M) * rothE (-(c * ξ / M))
        = ∑ ξ ∈ range M, ∑ a ∈ A, ∑ c ∈ A, rothE ((((a : ℤ) - c : ℤ) : ℝ) * ξ / M) := by
          refine sum_congr rfl fun ξ _ => sum_congr rfl fun a _ => sum_congr rfl fun c _ => ?_
          rw [← rothE_add]; congr 1; push_cast; ring
      _ = ∑ a ∈ A, ∑ c ∈ A, ∑ ξ ∈ range M, rothE ((((a : ℤ) - c : ℤ) : ℝ) * ξ / M) := by
          rw [sum_comm]; refine sum_congr rfl fun a _ => ?_; rw [sum_comm]
      _ = ∑ a ∈ A, ∑ c ∈ A, if a = c then (M : ℂ) else 0 := by
          refine sum_congr rfl fun a ha => sum_congr rfl fun c hc => ?_
          rw [sum_rothE M hM]
          · by_cases h : a = c
            · simp [h]
            · have : ¬ ((a : ℤ) - c = 0) := by omega
              simp [h, this]
          · have := hA a ha; have := hA c hc
            rw [abs_lt]; constructor <;> omega
      _ = (M : ℂ) * #A := by
          simp [sum_ite_eq, mul_comm]
  exact_mod_cast key

#print axioms roth_parseval

/-- Parity count: pairs `(a, c)` from `A` with `a + c` even number at least `#A² / 2`. -/
lemma roth_parity_count (n : ℕ) (A : Finset ℕ) (hA : A ⊆ range n) :
    ((#A : ℝ) ^ 2 / 2) ≤ ∑ a ∈ A, ∑ c ∈ A, ∑ b ∈ range n, (if a + c = 2 * b then (1 : ℝ) else 0) := by
  have h1 : ∀ a ∈ A, ∀ c ∈ A, ∑ b ∈ range n, (if a + c = 2 * b then (1 : ℝ) else 0) =
      (1 + (-1 : ℝ) ^ a * (-1) ^ c) / 2 := by
    intro a ha c hc
    have ha' := mem_range.1 (hA ha)
    have hc' := mem_range.1 (hA hc)
    rw [← pow_add]
    rcases Nat.even_or_odd (a + c) with ⟨k, hk⟩ | ⟨k, hk⟩
    · rw [sum_eq_single k]
      · rw [if_pos (by omega), hk, Even.neg_one_pow ⟨k, rfl⟩]; norm_num
      · intro b _ hb; rw [if_neg (by omega)]
      · intro hk'; exact absurd (mem_range.2 (by omega)) hk'
    · rw [sum_eq_zero, hk, Odd.neg_one_pow ⟨k, rfl⟩]
      · norm_num
      · intro b _; rw [if_neg (by omega)]
  rw [sum_congr rfl fun a ha => sum_congr rfl fun c hc => h1 a ha c hc]
  have h2 : ∑ a ∈ A, ∑ c ∈ A, (1 + (-1 : ℝ) ^ a * (-1) ^ c) / 2 =
      ((#A : ℝ) ^ 2 + (∑ a ∈ A, (-1 : ℝ) ^ a) ^ 2) / 2 := by
    rw [sq, sq, sum_mul_sum]
    simp only [add_div, sum_add_distrib, sum_const, nsmul_eq_mul, sum_div]; ring
  rw [h2]
  have := sq_nonneg (∑ a ∈ A, (-1 : ℝ) ^ a)
  linarith

#print axioms roth_parity_count

/-- A progression-free set has a large wave in its balanced function. -/
lemma roth_large_coeff (n : ℕ) (hn : 0 < n) (A : Finset ℕ) (hA : A ⊆ range n)
    (hAP : ThreeAPFree (A : Set ℕ)) :
    ∃ θ : ℝ, (#A : ℝ) / n * #A / 2 - 1 ≤
      ‖∑ b ∈ range n, (((if b ∈ A then (1 : ℝ) else 0) - (#A : ℝ) / n : ℝ) : ℂ) * rothE (b * θ)‖ := by
  set δ : ℝ := (#A : ℝ) / n with hδ
  set g : ℕ → ℝ := fun b => (if b ∈ A then (1 : ℝ) else 0) - δ with hg
  set T : ℕ → ℂ := fun ξ => ∑ b ∈ range n, (g b : ℂ) * rothE (b * (-2 * ξ / (2 * n : ℕ)))
    with hT
  have hne : (range (2 * n)).Nonempty := ⟨0, mem_range.2 (by omega)⟩
  obtain ⟨ξ0, _, hmax⟩ := (range (2 * n)).exists_max_image (fun ξ => ‖T ξ‖) hne
  refine ⟨-2 * ξ0 / (2 * n : ℕ), ?_⟩
  change δ * #A / 2 - 1 ≤ ‖T ξ0‖
  set Λ : ℝ := ∑ a ∈ A, ∑ c ∈ A, ∑ b ∈ range n, if a + c = 2 * b then g b else 0 with hΛ
  have hΛ1 : (∑ a ∈ A, ∑ c ∈ A, ∑ b ∈ range n,
      if a + c = 2 * b then (if b ∈ A then (1 : ℝ) else 0) else 0) = #A := by
    have : ∀ a ∈ A, ∀ c ∈ A, (∑ b ∈ range n,
        if a + c = 2 * b then (if b ∈ A then (1 : ℝ) else 0) else 0) = if a = c then 1 else 0 := by
      intro a ha c hc
      rw [sum_eq_single a]
      · by_cases h : a = c
        · subst h; simp [ha]; omega
        · rw [if_neg h, if_neg (by omega)]
      · intro b _ hba
        by_cases h1 : a + c = 2 * b
        · by_cases h2 : b ∈ A
          · exact absurd (hAP ha h2 hc (by omega)) (Ne.symm hba)
          · simp [h1, h2]
        · simp [h1]
      · intro h; exact absurd (hA ha) h
    rw [sum_congr rfl fun a ha => sum_congr rfl fun c hc => this a ha c hc]
    simp
  have hsplit : Λ = #A - δ * ∑ a ∈ A, ∑ c ∈ A, ∑ b ∈ range n,
      (if a + c = 2 * b then (1 : ℝ) else 0) := by
    rw [hΛ, ← hΛ1, mul_sum, ← sum_sub_distrib]
    refine sum_congr rfl fun a _ => ?_
    rw [mul_sum, ← sum_sub_distrib]
    refine sum_congr rfl fun c _ => ?_
    rw [mul_sum, ← sum_sub_distrib]
    refine sum_congr rfl fun b _ => ?_
    by_cases h : a + c = 2 * b <;> simp [h, hg]
  have hE := roth_parity_count n A hA
  have hδ0 : 0 ≤ δ := by positivity
  have hΛle : Λ ≤ #A - δ * ((#A : ℝ) ^ 2 / 2) := by
    rw [hsplit]; nlinarith [mul_le_mul_of_nonneg_left hE hδ0]
  -- the wave bound
  have hF := roth_fourier n A hA g
  have hP := roth_parseval (2 * n) (by omega) A (fun a ha => by
    have := mem_range.1 (hA ha); omega)
  have hbound : ((2 * n : ℕ) : ℝ) * |Λ| ≤ ‖T ξ0‖ * (((2 * n : ℕ) : ℝ) * #A) := by
    have h1 : ((2 * n : ℕ) : ℝ) * |Λ| = ‖((2 * n : ℕ) : ℂ) * (Λ : ℂ)‖ := by
      rw [norm_mul, Complex.norm_natCast, Complex.norm_real, Real.norm_eq_abs]
    rw [h1, hF, ← hP, mul_sum]
    refine (norm_sum_le _ _).trans (sum_le_sum fun ξ hξ => ?_)
    rw [norm_mul, norm_pow, mul_comm]
    exact mul_le_mul_of_nonneg_right (hmax ξ hξ) (by positivity)
  have hM : (0 : ℝ) < ((2 * n : ℕ) : ℝ) := by exact_mod_cast (by omega : 0 < 2 * n)
  have hb2 : |Λ| ≤ ‖T ξ0‖ * #A := by
    rw [mul_comm (‖T ξ0‖), mul_assoc] at hbound
    have := le_of_mul_le_mul_left (by linarith [hbound, mul_comm (((2 * n : ℕ) : ℝ)) (#A * ‖T ξ0‖)] : ((2 * n : ℕ) : ℝ) * |Λ| ≤ ((2 * n : ℕ) : ℝ) * (#A * ‖T ξ0‖)) hM
    linarith
  rcases Nat.eq_zero_or_pos #A with h0 | hpos
  · rw [h0]; simp only [Nat.cast_zero, mul_zero, zero_div, zero_sub]; linarith [norm_nonneg (T ξ0)]
  · have hApos : (0 : ℝ) < #A := by exact_mod_cast hpos
    have : (#A : ℝ) * (δ * #A / 2 - 1) ≤ #A * ‖T ξ0‖ := by
      nlinarith [neg_abs_le Λ]
    exact le_of_mul_le_mul_left this hApos

#print axioms roth_large_coeff

lemma roth_sum_range_mul {β : Type*} [AddCommMonoid β] (h : ℕ → β) (q K : ℕ) :
    ∑ x ∈ range (q * K), h x = ∑ j ∈ range K, ∑ r ∈ range q, h (q * j + r) := by
  induction K with
  | zero => simp
  | succ K ih => rw [Nat.mul_succ, sum_range_add, ih, sum_range_succ]

#print axioms roth_sum_range_mul

/-- Cut `0, ..., q L T - 1` into `q T` progressions of step `q` and length `L`. -/
lemma roth_decomp {β : Type*} [AddCommMonoid β] (F : ℕ → β) (q L T : ℕ) :
    ∑ x ∈ range (q * (L * T)), F x =
      ∑ r ∈ range q, ∑ t ∈ range T, ∑ i ∈ range L, F (q * (L * t + i) + r) := by
  rw [roth_sum_range_mul, sum_comm]
  refine sum_congr rfl fun r _ => ?_
  rw [roth_sum_range_mul (fun j => F (q * j + r)) L T]

#print axioms roth_decomp

lemma roth_decomp_of_support {β : Type*} [AddCommMonoid β] (F : ℕ → β) (n q L T : ℕ)
    (hcover : n ≤ q * (L * T)) (hF : ∀ x, n ≤ x → F x = 0) :
    ∑ x ∈ range n, F x =
      ∑ r ∈ range q, ∑ t ∈ range T, ∑ i ∈ range L, F (q * (L * t + i) + r) := by
  rw [← roth_decomp]
  refine sum_subset (range_subset_range.2 hcover) fun x _ hx => hF x ?_
  simpa using hx

#print axioms roth_decomp_of_support

/-- On each progression of step `q` the wave turns by at most `2 π L β`. -/
lemma roth_block_bound (n q L T : ℕ) (hcover : n ≤ q * (L * T)) (h : ℕ → ℝ)
    (hh : ∀ x, n ≤ x → h x = 0) (θ β : ℝ) (j : ℤ) (hβ : |q * θ - j| ≤ β) :
    ‖∑ x ∈ range n, (h x : ℂ) * rothE (x * θ)‖ ≤
      ∑ r ∈ range q, ∑ t ∈ range T, |∑ i ∈ range L, h (q * (L * t + i) + r)| +
        2 * Real.pi * L * β * ∑ x ∈ range n, |h x| := by
  have hβ0 : 0 ≤ β := (abs_nonneg _).trans hβ
  rw [roth_decomp_of_support _ n q L T hcover (fun x hx => by simp [hh x hx]),
    roth_decomp_of_support (fun x => |h x|) n q L T hcover (fun x hx => by simp [hh x hx]),
    mul_sum, ← sum_add_distrib]
  refine (norm_sum_le _ _).trans (sum_le_sum fun r _ => ?_)
  rw [mul_sum, ← sum_add_distrib]
  refine (norm_sum_le _ _).trans (sum_le_sum fun t _ => ?_)
  set x0 : ℕ := q * (L * t) + r
  have hexp : ∀ i : ℕ, rothE (((q * (L * t + i) + r : ℕ) : ℝ) * θ) =
      rothE (x0 * θ) * rothE (i * (q * θ - j)) := by
    intro i
    rw [← rothE_add, show (((q * (L * t + i) + r : ℕ) : ℝ) * θ) =
        x0 * θ + i * (q * θ - j) + ((i * j : ℤ) : ℝ) by simp [x0]; push_cast; ring,
      rothE_add, rothE_int, mul_one]
  have hsplit : ∑ i ∈ range L, (h (q * (L * t + i) + r) : ℂ) * rothE (((q * (L * t + i) + r : ℕ) : ℝ) * θ)
      = rothE (x0 * θ) * ((∑ i ∈ range L, (h (q * (L * t + i) + r) : ℂ)) +
          ∑ i ∈ range L, (h (q * (L * t + i) + r) : ℂ) * (rothE (i * (q * θ - j)) - 1)) := by
    rw [← sum_add_distrib, mul_sum]
    refine sum_congr rfl fun i _ => ?_
    rw [hexp]; ring
  rw [hsplit, norm_mul, norm_rothE, one_mul]
  refine (norm_add_le _ _).trans (add_le_add ?_ ?_)
  · rw [← Complex.ofReal_sum, Complex.norm_real, Real.norm_eq_abs]
  · rw [mul_sum]
    refine (norm_sum_le _ _).trans (sum_le_sum fun i hi => ?_)
    rw [norm_mul, Complex.norm_real, Real.norm_eq_abs, mul_comm]
    refine mul_le_mul_of_nonneg_right ?_ (abs_nonneg _)
    refine (norm_rothE_sub_one _).trans ?_
    have hi' : (i : ℝ) ≤ L := by exact_mod_cast (mem_range.1 hi).le
    rw [abs_mul, Nat.abs_cast]
    have := mul_le_mul hi' hβ (abs_nonneg _) (Nat.cast_nonneg L)
    have hpi : 0 ≤ 2 * Real.pi := by positivity
    nlinarith [mul_le_mul_of_nonneg_left this hpi]

#print axioms roth_block_bound

/-- Pigeonhole on the blocks: some block is long and has a density increment. -/
lemma roth_pigeon {ι : Type*} (s : Finset ι) (S a c : ι → ℝ) (κ L0 δ N : ℝ) (hκ : 0 ≤ κ)
    (hL0 : 0 ≤ L0) (hδ : 0 ≤ δ) (hS : ∀ i, S i = a i - δ * c i) (hac : ∀ i, a i ≤ c i)
    (hc0 : ∀ i, 0 ≤ c i) (hsum : ∑ i ∈ s, S i = 0) (hcN : ∑ i ∈ s, c i ≤ N)
    (hbig : 2 * κ * N + 2 * #s * L0 < ∑ i ∈ s, |S i|) :
    ∃ i ∈ s, κ * c i ≤ S i ∧ L0 ≤ c i := by
  by_contra hcon
  push Not at hcon
  have hpt : ∀ i ∈ s, |S i| ≤ 2 * (κ * c i + L0) - S i := by
    intro i hi
    have hci := hc0 i
    have hk : 0 ≤ κ * c i := mul_nonneg hκ hci
    have hSc : S i ≤ c i := by rw [hS]; nlinarith [hac i, mul_nonneg hδ hci]
    have hSle : S i ≤ κ * c i + L0 := by
      by_cases h : κ * c i ≤ S i
      · have := hcon i hi h; linarith
      · linarith
    rcases le_or_gt 0 (S i) with h | h
    · rw [abs_of_nonneg h]; linarith
    · rw [abs_of_neg h]; linarith
  have := sum_le_sum hpt
  rw [sum_sub_distrib, hsum, ← mul_sum, sum_add_distrib, ← mul_sum, sum_const, nsmul_eq_mul] at this
  nlinarith

#print axioms roth_pigeon

/-- A progression of step `q > 0` pulls a progression-free set back to a progression-free set. -/
lemma roth_threeAPFree_pullback (A : Finset ℕ) (hAP : ThreeAPFree (A : Set ℕ)) (q L t r : ℕ)
    (hq : 0 < q) :
    ThreeAPFree (((range L).filter fun i => q * (L * t + i) + r ∈ A : Finset ℕ) : Set ℕ) := by
  intro a ha b hb c hc habc
  simp only [coe_filter, Set.mem_setOf_eq] at ha hb hc
  have h1 : q * (L * t + a) + r + (q * (L * t + c) + r) =
      q * (L * t + b) + r + (q * (L * t + b) + r) := by
    have : q * (a + c) = q * (b + b) := by rw [habc]
    nlinarith [this]
  have h2 := hAP ha.2 hb.2 hc.2 h1
  have h3 : q * (L * t + a) = q * (L * t + b) := by omega
  have h4 := Nat.eq_of_mul_eq_mul_left hq h3
  omega

#print axioms roth_threeAPFree_pullback

/-- Roth's density increment, with the exact density `#A / n`. -/
lemma roth_increment (n : ℕ) (A : Finset ℕ) (hA : A ⊆ range n) (hAP : ThreeAPFree (A : Set ℕ))
    (hbig : 202 ≤ (#A : ℝ) / n * √n) :
    ∃ m : ℕ, ∃ A' : Finset ℕ, A' ⊆ range m ∧ ThreeAPFree (A' : Set ℕ) ∧
      ((#A : ℝ) / n + ((#A : ℝ) / n) ^ 2 / 16) * m ≤ #A' ∧
        ((#A : ℝ) / n) ^ 3 * √n / 6464 ≤ m := by
  obtain ⟨δ, hδ⟩ : ∃ δ : ℝ, δ = (#A : ℝ) / n := ⟨_, rfl⟩
  rw [← hδ] at hbig ⊢
  have hn : 0 < n := by
    rcases Nat.eq_zero_or_pos n with h | h
    · subst h; simp at hbig; linarith
    · exact h
  have hnR : (0 : ℝ) < n := by exact_mod_cast hn
  have hAn : (#A : ℝ) ≤ n := by
    have := card_le_card hA; rw [card_range] at this; exact_mod_cast this
  have hδ1 : δ ≤ 1 := by rw [hδ, div_le_one hnR]; exact hAn
  have hsqrt0 : 0 ≤ √(n : ℝ) := Real.sqrt_nonneg _
  have hδ0 : 0 < δ := by
    by_contra h; push Not at h
    have : δ * √n ≤ 0 := mul_nonpos_of_nonpos_of_nonneg h hsqrt0
    linarith
  have hsq : √(n : ℝ) * √n = n := Real.mul_self_sqrt hnR.le
  have hA_eq : (#A : ℝ) = δ * n := by rw [hδ]; field_simp
  have hδ2n : 8 < δ ^ 2 * n := by nlinarith
  obtain ⟨θ, hθ⟩ := roth_large_coeff n hn A hA hAP
  rw [← hδ] at hθ
  obtain ⟨Q, hQ⟩ : ∃ Q : ℕ, Q = Nat.sqrt n := ⟨_, rfl⟩
  have hQ1 : 0 < Q := hQ ▸ Nat.sqrt_pos.2 hn
  have hQ2 : Q * Q ≤ n := hQ ▸ Nat.sqrt_le n
  have hQ3 : n < (Q + 1) * (Q + 1) := hQ ▸ Nat.lt_succ_sqrt n
  have hQR : √(n : ℝ) < Q + 1 := by
    rw [Real.sqrt_lt' (by positivity)]
    have : (n : ℝ) < ((Q + 1) * (Q + 1) : ℕ) := by exact_mod_cast hQ3
    push_cast at this; nlinarith
  obtain ⟨j, k, hk0, hkQ, hjk⟩ := Real.exists_int_int_abs_mul_sub_le θ hQ1
  obtain ⟨q, hqdef⟩ : ∃ q : ℕ, q = k.toNat := ⟨_, rfl⟩
  have hqk : (q : ℤ) = k := by rw [hqdef]; exact Int.toNat_of_nonneg hk0.le
  have hq0 : 0 < q := by omega
  have hqQ : q ≤ Q := by omega
  have hqR : (q : ℝ) = k := by exact_mod_cast hqk
  obtain ⟨L, hLdef⟩ : ∃ L : ℕ, L = ⌊δ * (Q + 1) / 101⌋₊ := ⟨_, rfl⟩
  have hQ1R : (1 : ℝ) ≤ Q := by exact_mod_cast hQ1
  have hLarg : 0 ≤ δ * (Q + 1) / 101 := by positivity
  have hLle : (L : ℝ) ≤ δ * (Q + 1) / 101 := hLdef ▸ Nat.floor_le hLarg
  have hLge : δ * (Q + 1) / 101 - 1 < L := by
    rw [hLdef]; linarith [Nat.lt_floor_add_one (δ * (Q + 1) / 101)]
  have hδQ : 202 < δ * (Q + 1) := by nlinarith
  have hL0 : 0 < L := by
    have : (0 : ℝ) < L := by linarith
    exact_mod_cast this
  have hLQ : L ≤ Q := by
    have : (L : ℝ) ≤ Q := by nlinarith
    exact_mod_cast this
  obtain ⟨T, hTdef⟩ : ∃ T : ℕ, T = n / (q * L) + 1 := ⟨_, rfl⟩
  have hqL : 0 < q * L := Nat.mul_pos hq0 hL0
  have hcover : n ≤ q * (L * T) := by
    have := Nat.lt_mul_div_succ n hqL; rw [← mul_assoc, hTdef]; omega
  have hqTL : q * T * L ≤ 2 * n := by
    have h1 : q * L * (n / (q * L)) ≤ n := Nat.mul_div_le n (q * L)
    have h2 : q * L ≤ Q * Q := Nat.mul_le_mul hqQ hLQ
    have : q * T * L = q * L * (n / (q * L)) + q * L := by rw [hTdef]; ring
    omega
  -- the balanced function, extended by zero
  obtain ⟨h, hhdef⟩ : ∃ h : ℕ → ℝ,
      h = fun x => (if x ∈ A then (1 : ℝ) else 0) - (if x < n then δ else 0) := ⟨_, rfl⟩
  have hh : ∀ x, n ≤ x → h x = 0 := by
    intro x hx
    have : x ∉ A := fun hxA => by have := mem_range.1 (hA hxA); omega
    simp [hhdef, this, not_lt.2 hx]
  have hF0 : δ * #A / 2 - 1 ≤ ‖∑ x ∈ range n, (h x : ℂ) * rothE (x * θ)‖ := by
    refine hθ.trans (le_of_eq ?_)
    congr 1
    refine sum_congr rfl fun x hx => ?_
    simp [hhdef, mem_range.1 hx, hδ]
  have hblock := roth_block_bound n q L T hcover h hh θ (1 / (Q + 1)) j (by rw [hqR]; exact hjk)
  have habs : ∑ x ∈ range n, |h x| ≤ 2 * #A := by
    have h1 : ∀ x ∈ range n, |h x| ≤ (if x ∈ A then (1 : ℝ) else 0) + δ := by
      intro x hx
      simp only [hhdef, if_pos (mem_range.1 hx)]
      split_ifs <;> rw [abs_le] <;> constructor <;> linarith
    refine (sum_le_sum h1).trans (le_of_eq ?_)
    rw [sum_add_distrib, sum_ite_mem, inter_eq_right.2 hA]
    simp only [sum_const, card_range, nsmul_eq_mul, mul_one]
    rw [hA_eq]; ring
  have hQpos : (0 : ℝ) < Q + 1 := by positivity
  have hdir : 2 * Real.pi * L * (1 / (Q + 1)) * ∑ x ∈ range n, |h x| ≤ δ * #A / 8 := by
    have hpi := Real.pi_lt_d2
    have hpi0 := Real.pi_pos
    have h1 : (L : ℝ) * (1 / (Q + 1)) ≤ δ / 101 := by
      rw [mul_one_div, div_le_iff₀ hQpos]; linarith
    have h2 : 0 ≤ ∑ x ∈ range n, |h x| := sum_nonneg fun _ _ => abs_nonneg _
    have hLnn : (0 : ℝ) ≤ L * (1 / (Q + 1)) := by positivity
    calc 2 * Real.pi * L * (1 / (Q + 1)) * ∑ x ∈ range n, |h x|
        = 2 * Real.pi * (L * (1 / (Q + 1))) * ∑ x ∈ range n, |h x| := by ring
      _ ≤ 2 * Real.pi * (δ / 101) * (2 * #A) := by
          apply mul_le_mul (mul_le_mul_of_nonneg_left h1 (by positivity)) habs h2 (by positivity)
      _ ≤ δ * #A / 8 := by
          have : 0 ≤ δ * #A := mul_nonneg hδ0.le (Nat.cast_nonneg _)
          nlinarith
  have hbl : 3 * (δ * #A) / 8 - 1 ≤
      ∑ r ∈ range q, ∑ t ∈ range T, |∑ i ∈ range L, h (q * (L * t + i) + r)| := by
    linarith
  -- pigeonhole over the blocks
  obtain ⟨S, hSdef⟩ : ∃ S : ℕ × ℕ → ℝ,
    S = fun p => ∑ i ∈ range L, h (q * (L * p.2 + i) + p.1) := ⟨_, rfl⟩
  obtain ⟨a, hadef⟩ : ∃ a : ℕ × ℕ → ℝ, a = fun p => ∑ i ∈ range L,
    (if q * (L * p.2 + i) + p.1 ∈ A then (1 : ℝ) else 0) := ⟨_, rfl⟩
  obtain ⟨c, hcdef⟩ : ∃ c : ℕ × ℕ → ℝ, c = fun p => ∑ i ∈ range L,
    (if q * (L * p.2 + i) + p.1 < n then (1 : ℝ) else 0) := ⟨_, rfl⟩
  have hS : ∀ p, S p = a p - δ * c p := by
    intro p
    simp only [hSdef, hadef, hcdef, hhdef, mul_sum, ← sum_sub_distrib]
    refine sum_congr rfl fun i _ => ?_
    split_ifs <;> ring
  have hac : ∀ p, a p ≤ c p := by
    intro p
    rw [hadef, hcdef]
    refine sum_le_sum fun i _ => ?_
    by_cases h1 : q * (L * p.2 + i) + p.1 ∈ A
    · have := mem_range.1 (hA h1); simp [h1, this]
    · simp only [h1, if_false]; split_ifs <;> norm_num
  have hc0 : ∀ p, 0 ≤ c p := fun p => by
    rw [hcdef]; exact sum_nonneg fun i _ => by split_ifs <;> norm_num
  have hsum : ∑ p ∈ range q ×ˢ range T, S p = 0 := by
    rw [sum_product]
    simp only [hSdef]
    rw [← roth_decomp_of_support h n q L T hcover hh]
    simp only [hhdef, sum_sub_distrib, sum_ite_mem, inter_eq_right.2 hA]
    rw [sum_ite_of_true (fun x hx => mem_range.1 hx)]
    simp only [sum_const, card_range, nsmul_eq_mul, mul_one]
    rw [hA_eq]; ring
  have hcN : ∑ p ∈ range q ×ˢ range T, c p ≤ n := by
    rw [sum_product]
    simp only [hcdef]
    rw [← roth_decomp_of_support (fun x => if x < n then (1 : ℝ) else 0) n q L T hcover
      (fun x hx => by simp [not_lt.2 hx])]
    rw [sum_ite_of_true (fun x hx => mem_range.1 hx)]
    simp
  have hcard : (#(range q ×ˢ range T) : ℝ) * L ≤ 2 * n := by
    rw [card_product, card_range, card_range]
    exact_mod_cast hqTL
  have hpig := roth_pigeon (range q ×ˢ range T) S a c (δ ^ 2 / 16) (δ ^ 2 * L / 32) δ n
    (by positivity) (by positivity) hδ0.le hS hac hc0 hsum hcN (by
      rw [sum_product]
      simp only [hSdef]
      have hAδ : δ * (#A : ℝ) = δ ^ 2 * n := by rw [hA_eq]; ring
      have : 2 * (δ ^ 2 / 16) * n + 2 * #(range q ×ˢ range T) * (δ ^ 2 * L / 32) ≤
          δ ^ 2 * n / 4 := by
        have := mul_le_mul_of_nonneg_left hcard (by positivity : (0 : ℝ) ≤ δ ^ 2 / 16)
        nlinarith
      linarith)
  obtain ⟨⟨r, t⟩, _, hinc, hlong⟩ := hpig
  obtain ⟨A', hA'def⟩ : ∃ A' : Finset ℕ, A' = (range L).filter fun i => q * (L * t + i) + r ∈ A :=
    ⟨_, rfl⟩
  obtain ⟨m, hmdef⟩ : ∃ m : ℕ, m = #((range L).filter fun i => q * (L * t + i) + r < n) := ⟨_, rfl⟩
  have hcm : c (r, t) = m := by simp only [hcdef, sum_boole, hmdef]
  have ham : a (r, t) = #A' := by simp only [hadef, sum_boole, hA'def]
  refine ⟨m, A', ?_, hA'def ▸ roth_threeAPFree_pullback A hAP q L t r hq0, ?_, ?_⟩
  · intro i hi
    rw [hA'def, mem_filter] at hi
    have hin := mem_range.1 (hA hi.2)
    rw [mem_range]
    have : range (i + 1) ⊆ (range L).filter fun i => q * (L * t + i) + r < n := by
      intro i' hi'
      rw [mem_range] at hi'
      rw [mem_filter, mem_range]
      refine ⟨by have := mem_range.1 hi.1; omega, ?_⟩
      have : q * (L * t + i') ≤ q * (L * t + i) := Nat.mul_le_mul_left q (by omega)
      omega
    have := card_le_card this
    rw [card_range] at this
    rw [hmdef]; exact this
  · rw [← ham, ← hcm]
    have := hS (r, t)
    rw [this] at hinc
    linarith
  · rw [← hcm]
    have hLb : δ * √n / 202 ≤ L := by
      have : δ * √n < δ * (Q + 1) := mul_lt_mul_of_pos_left hQR hδ0
      linarith
    have : δ ^ 3 * √n / 6464 = δ ^ 2 * (δ * √n / 202) / 32 := by ring
    rw [this]
    have := mul_le_mul_of_nonneg_left hLb (by positivity : (0 : ℝ) ≤ δ ^ 2)
    linarith

#print axioms roth_increment

/-- The numbers behind each step of the iteration. -/
lemma roth_numeric (δ E' : ℝ) (hδ0 : 0 < δ) (hδ1 : δ ≤ 1) (hE' : E' ≤ Real.exp (72 / δ - 4)) :
    (6464 / δ ^ 3) ^ 2 * Real.exp (2 * E') ≤ Real.exp (Real.exp (72 / δ)) ∧
      (202 / δ) ^ 2 ≤ Real.exp (Real.exp (72 / δ)) := by
  set u := 72 / δ with hu
  have hu72 : 72 ≤ u := by rw [hu, le_div_iff₀ hδ0]; linarith
  have hinv : 1 / δ = u / 72 := by rw [hu]; field_simp
  set E := Real.exp u with hE
  have hE12 : 12 * u ≤ E := by
    have := Real.quadratic_le_exp_of_nonneg (by linarith : (0 : ℝ) ≤ u)
    nlinarith
  have hu6 : u ^ 6 ≤ Real.exp (6 * u) := by
    rw [show (6 : ℝ) * u = ((6 : ℕ) : ℝ) * u by norm_num, Real.exp_nat_mul]
    exact pow_le_pow_left₀ (by linarith) (by linarith [Real.add_one_le_exp u]) 6
  have hexp6 : Real.exp (6 * u) ≤ Real.exp (E / 2) := Real.exp_le_exp.2 (by linarith)
  have hE0 : 0 < E := Real.exp_pos u
  constructor
  · have h1 : 6464 / δ ^ 3 ≤ u ^ 3 := by
      have : 6464 / δ ^ 3 = 6464 * (1 / δ) ^ 3 := by field_simp
      rw [this, hinv]
      have : 0 ≤ u ^ 3 := by positivity
      nlinarith
    have h2 : (6464 / δ ^ 3) ^ 2 ≤ Real.exp (E / 2) := by
      calc (6464 / δ ^ 3) ^ 2 ≤ (u ^ 3) ^ 2 := pow_le_pow_left₀ (by positivity) h1 2
        _ = u ^ 6 := by ring
        _ ≤ _ := hu6.trans hexp6
    have h4 : (13 : ℝ) ≤ Real.exp 4 := by
      have := Real.quadratic_le_exp_of_nonneg (by norm_num : (0 : ℝ) ≤ 4); linarith
    have h3 : Real.exp (2 * E') ≤ Real.exp (E / 2) := by
      apply Real.exp_le_exp.2
      have : Real.exp (u - 4) * Real.exp 4 = E := by rw [← Real.exp_add]; simp [hE]
      have h5 : Real.exp (u - 4) ≤ E / 13 := by
        rw [le_div_iff₀ (by norm_num)]
        have := Real.exp_pos (u - 4)
        nlinarith
      linarith
    calc (6464 / δ ^ 3) ^ 2 * Real.exp (2 * E') ≤ Real.exp (E / 2) * Real.exp (E / 2) :=
          mul_le_mul h2 h3 (Real.exp_pos _).le (Real.exp_pos _).le
      _ = Real.exp E := by rw [← Real.exp_add]; ring_nf
  · have h1 : 202 / δ ≤ u ^ 3 := by
      have : 202 / δ = 202 * (1 / δ) := by ring
      rw [this, hinv]
      have hu2 : 72 * 72 ≤ u * u := mul_le_mul hu72 hu72 (by norm_num) (by linarith)
      have := mul_le_mul_of_nonneg_left hu2 (by linarith : (0 : ℝ) ≤ u)
      nlinarith
    calc (202 / δ) ^ 2 ≤ (u ^ 3) ^ 2 := pow_le_pow_left₀ (by positivity) h1 2
      _ = u ^ 6 := by ring
      _ ≤ Real.exp (E / 2) := hu6.trans hexp6
      _ ≤ Real.exp E := Real.exp_le_exp.2 (by linarith)

#print axioms roth_numeric

/-- The iterated density increment: a progression-free set of density at least `δ` in
`0, ..., n - 1` forces `n < exp (exp (72 / δ))`. -/
lemma roth_bound (k : ℕ) : ∀ δ : ℝ, 0 < δ → 17 / δ ≤ k → ∀ (n : ℕ) (A : Finset ℕ),
    A ⊆ range n → ThreeAPFree (A : Set ℕ) → δ * n ≤ #A →
      (n : ℝ) < Real.exp (Real.exp (72 / δ)) := by
  induction k with
  | zero =>
    intro δ hδ hk
    have : 0 < 17 / δ := by positivity
    norm_num at hk; linarith
  | succ k ih =>
    intro δ hδ hk n A hA hAP hδA
    have hAn : (#A : ℝ) ≤ n := by
      have := card_le_card hA; rw [card_range] at this; exact_mod_cast this
    have hnn : (0 : ℝ) ≤ n := Nat.cast_nonneg n
    by_cases hδ1 : 1 < δ
    · have : (n : ℝ) ≤ 0 := by nlinarith
      exact this.trans_lt (Real.exp_pos _)
    push Not at hδ1
    have hsq0 : 0 ≤ √(n : ℝ) := Real.sqrt_nonneg _
    have hsq : √(n : ℝ) ^ 2 = n := Real.sq_sqrt hnn
    have hnum := roth_numeric δ
    by_cases hs : δ * √n < 202
    · have h1 : √(n : ℝ) < 202 / δ := by rw [lt_div_iff₀ hδ]; linarith
      have h2 : (n : ℝ) < (202 / δ) ^ 2 := by
        rw [← hsq]; exact pow_lt_pow_left₀ h1 hsq0 (by norm_num)
      exact h2.trans_le (hnum 0 hδ hδ1 (Real.exp_pos _).le).2
    push Not at hs
    have hn : 0 < n := by
      rcases Nat.eq_zero_or_pos n with h | h
      · subst h; simp at hs; linarith
      · exact h
    have hnR : (0 : ℝ) < n := by exact_mod_cast hn
    have hδa : δ ≤ (#A : ℝ) / n := by rw [le_div_iff₀ hnR]; exact hδA
    obtain ⟨m, A', hA', hAP', hdens, hlen⟩ := roth_increment n A hA hAP (by
      have := mul_le_mul_of_nonneg_right hδa hsq0; linarith)
    set δ' := δ + δ ^ 2 / 16 with hδ'
    have hδ'0 : 0 < δ' := by positivity
    have h17 : 17 / δ' ≤ k := by
      have : 17 / δ - 1 - 17 / δ' = (δ - δ ^ 2) / (16 * δ') := by
        rw [hδ']; field_simp; ring
      have : 0 ≤ (δ - δ ^ 2) / (16 * δ') := div_nonneg (by nlinarith) (by positivity)
      push_cast at hk; linarith
    have h72 : 72 / δ' ≤ 72 / δ - 4 := by
      have : 72 / δ - 4 - 72 / δ' = (δ / 2 - δ ^ 2 / 4) / δ' := by
        rw [hδ']; field_simp; ring
      have : 0 ≤ (δ / 2 - δ ^ 2 / 4) / δ' := div_nonneg (by nlinarith) (by positivity)
      linarith
    have hδ'm : δ' * m ≤ #A' := by
      refine le_trans ?_ hdens
      apply mul_le_mul_of_nonneg_right _ (Nat.cast_nonneg m)
      nlinarith
    have hm := ih δ' hδ'0 h17 m A' hA' hAP' hδ'm
    -- √n is at most 6464 m / δ³
    have hδa0 : 0 ≤ (#A : ℝ) / n := by positivity
    have h3 : δ ^ 3 * √n / 6464 ≤ m := by
      refine le_trans ?_ hlen
      have := pow_le_pow_left₀ hδ.le hδa 3
      have := mul_le_mul_of_nonneg_right this hsq0
      linarith
    have h4 : √(n : ℝ) < 6464 / δ ^ 3 * Real.exp (Real.exp (72 / δ')) := by
      have hδ3 : 0 < δ ^ 3 := by positivity
      rw [div_mul_eq_mul_div, lt_div_iff₀ hδ3]
      nlinarith
    have h5 : (n : ℝ) < (6464 / δ ^ 3) ^ 2 * Real.exp (2 * Real.exp (72 / δ')) := by
      rw [← hsq]
      have := pow_lt_pow_left₀ h4 hsq0 (by norm_num : 2 ≠ 0)
      rw [mul_pow, ← Real.exp_nat_mul] at this
      push_cast at this
      exact this
    exact h5.trans_le (hnum _ hδ hδ1 (Real.exp_le_exp.2 h72)).1

#print axioms roth_bound

lemma roth_addRothNumber_Icc (N : ℕ) : addRothNumber (Icc 1 N) = rothNumberNat N := by
  rw [← Finset.Ico_add_one_right_eq_Icc, addRothNumber_Ico]
  simp

#print axioms roth_addRothNumber_Icc

/-- **Roth's theorem, with the card's constant.** For every `N ≥ 3`, the largest set in
`1, ..., N` with no three-term progression `x, x + d, x + 2d` (`d ≥ 1`) has fewer than
`72 N / log log N` members: `r₃(N) < 72 N / log log N`. -/
theorem roth_number_lt_seventy_two_mul_div_log_log (N : ℕ) (hN : 3 ≤ N) :
    (addRothNumber (Icc 1 N) : ℝ) < 72 * N / Real.log (Real.log N) := by
  rw [roth_addRothNumber_Icc]
  have hNR : (3 : ℝ) ≤ N := by exact_mod_cast hN
  have hN0 : (0 : ℝ) < N := by linarith
  have hlog1 : 1 < Real.log N := by
    rw [Real.lt_log_iff_exp_lt hN0]
    have := Real.exp_one_lt_d9
    linarith
  have hL : 0 < Real.log (Real.log N) := Real.log_pos hlog1
  have hr : (rothNumberNat N : ℝ) ≤ N := by exact_mod_cast rothNumberNat_le N
  by_cases hL72 : Real.log (Real.log N) < 72
  · rw [lt_div_iff₀ hL]; nlinarith
  push Not at hL72
  by_contra hcon
  push Not at hcon
  obtain ⟨t, ht, hcard, hAP⟩ := rothNumberNat_spec N
  have hδ0 : 0 < 72 / Real.log (Real.log N) := by positivity
  have hδt : 72 / Real.log (Real.log N) * N ≤ #t := by
    rw [hcard, div_mul_eq_mul_div]; exact hcon
  have key := roth_bound ⌈17 / (72 / Real.log (Real.log N))⌉₊ _ hδ0 (Nat.le_ceil _) N t ht hAP hδt
  have h72 : 72 / (72 / Real.log (Real.log N)) = Real.log (Real.log N) := by field_simp
  rw [h72, Real.exp_log (by linarith), Real.exp_log hN0] at key
  exact lt_irrefl _ key

/-- **Roth's theorem, the share.** The largest progression-free share `r₃(N) / N` of
`1, ..., N` tends to 0 as `N` grows. -/
theorem roth_number_share_tendsto_zero :
    Tendsto (fun N : ℕ => (addRothNumber (Icc 1 N) : ℝ) / N) atTop (𝓝 0) := by
  simp only [roth_addRothNumber_Icc]
  exact rothNumberNat_isLittleO_id.tendsto_div_nhds_zero

/-- **The counting identity.** For a set `A` of residues mod `M`, the number of pairs `(x, d)`
mod `M` with `x`, `x + d`, `x + 2d` all in `A` (step 0 included) equals
`M² * ∑ ξ, Â(ξ)² * Â(-2ξ)`. -/
theorem three_term_count_eq_fourier_sum (M : ℕ) [NeZero M] (A : Finset (ZMod M)) :
    ((univ.filter fun p : ZMod M × ZMod M =>
        p.1 ∈ A ∧ p.1 + p.2 ∈ A ∧ p.1 + 2 * p.2 ∈ A).card : ℂ) =
      (M : ℂ) ^ 2 * ∑ ξ : ZMod M, waveSize M A ξ ^ 2 * waveSize M A (-2 * ξ) := by
  classical
  set ψ : AddChar (ZMod M) ℂ := ZMod.stdAddChar with hψ
  set f : ZMod M → ℂ := fun x => if x ∈ A then 1 else 0 with hf
  have hM : (M : ℂ) ≠ 0 := Nat.cast_ne_zero.2 (NeZero.ne M)
  have orth : ∀ t : ZMod M, ∑ ξ : ZMod M, ψ (ξ * t) = if t = 0 then (M : ℂ) else 0 := by
    intro t
    rw [AddChar.sum_mulShift t (ZMod.isPrimitive_stdAddChar M)]
    simp [ZMod.card]
  have hw : ∀ ξ : ZMod M, waveSize M A ξ ^ 2 * waveSize M A (-2 * ξ) =
      (1 / (M : ℂ)) ^ 3 * ∑ a : ZMod M, ∑ c : ZMod M, ∑ b : ZMod M,
        f a * f b * f c * ψ (ξ * (2 * c - a - b)) := by
    intro ξ
    simp only [waveSize]
    rw [show ∀ x z : ℂ, ((1 / (M : ℂ)) * x) ^ 2 * ((1 / (M : ℂ)) * z) =
      (1 / (M : ℂ)) ^ 3 * (x * x * z) from fun x z => by ring]
    congr 1
    rw [sum_mul_sum, sum_mul]
    refine sum_congr rfl fun a _ => ?_
    simp_rw [mul_sum, sum_mul]
    refine sum_congr rfl fun c _ => sum_congr rfl fun b _ => ?_
    simp only [hf, hψ]
    rw [show ξ * (2 * c - a - b) = -(a * ξ) + -(b * ξ) + -(c * (-2 * ξ)) by ring,
      AddChar.map_add_eq_mul, AddChar.map_add_eq_mul]
    ring
  have hR : (M : ℂ) ^ 2 * ∑ ξ : ZMod M, waveSize M A ξ ^ 2 * waveSize M A (-2 * ξ) =
      ∑ a : ZMod M, ∑ c : ZMod M, f a * f c * f (2 * c - a) := by
    simp_rw [hw]
    rw [← mul_sum]
    have hswap : ∑ ξ : ZMod M, ∑ a : ZMod M, ∑ c : ZMod M, ∑ b : ZMod M,
          f a * f b * f c * ψ (ξ * (2 * c - a - b)) =
        ∑ a : ZMod M, ∑ c : ZMod M, ∑ b : ZMod M,
          f a * f b * f c * ∑ ξ : ZMod M, ψ (ξ * (2 * c - a - b)) := by
      rw [sum_comm]
      refine sum_congr rfl fun a _ => ?_
      rw [sum_comm]
      refine sum_congr rfl fun c _ => ?_
      rw [sum_comm]
      refine sum_congr rfl fun b _ => ?_
      rw [mul_sum]
    rw [hswap, mul_sum, mul_sum]
    refine sum_congr rfl fun a _ => ?_
    rw [mul_sum, mul_sum]
    refine sum_congr rfl fun c _ => ?_
    simp_rw [orth]
    rw [sum_eq_single (2 * c - a)]
    · rw [if_pos (by ring)]
      field_simp
    · intro b _ hb
      rw [if_neg (fun h => hb (by linear_combination -h))]
      ring
    · intro h; exact absurd (mem_univ _) h
  rw [hR, natCast_card_filter, ← univ_product_univ, sum_product]
  refine sum_congr rfl fun x _ => ?_
  refine Fintype.sum_equiv (Equiv.addLeft x) _ _ fun d => ?_
  rw [Equiv.coe_addLeft, show 2 * (x + d) - x = x + 2 * d by ring]
  simp only [hf]
  by_cases h1 : x ∈ A <;> by_cases h2 : x + d ∈ A <;> by_cases h3 : x + 2 * d ∈ A <;>
    simp [h1, h2, h3]

/-- r₃(9) = 5: the largest progression-free set in 1 to 9 has five members. -/
example : addRothNumber (Icc 1 9) = 5 := by
  refine le_antisymm (Nat.lt_succ_iff.1 ?_) ?_
  · exact addRothNumber_lt_of_forall_not_threeAPFree (by decide +kernel)
  · have hfree : ThreeAPFree (({1, 2, 4, 8, 9} : Finset ℕ) : Set ℕ) := by decide
    exact hfree.le_addRothNumber (by decide)

/-- {1, 2, 4, 8, 9} has no three-term progression with step at least 1. -/
example : ∀ x ∈ ({1, 2, 4, 8, 9} : Finset ℕ), ∀ d ∈ Icc 1 4,
    ¬ (x + d ∈ ({1, 2, 4, 8, 9} : Finset ℕ) ∧ x + 2 * d ∈ ({1, 2, 4, 8, 9} : Finset ℕ)) := by
  decide

/-- Mod 19, A = {1, 2, 4, 8, 9} has exactly 5 pairs (x, d): only the trivial ones. -/
example : (univ.filter fun p : ZMod 19 × ZMod 19 =>
    p.1 ∈ ({1, 2, 4, 8, 9} : Finset (ZMod 19)) ∧ p.1 + p.2 ∈ ({1, 2, 4, 8, 9} : Finset (ZMod 19)) ∧
      p.1 + 2 * p.2 ∈ ({1, 2, 4, 8, 9} : Finset (ZMod 19))).card = 5 := by
  decide

/-- Mod 9 (too small a clock), the same set shows 13 pairs, not 5. -/
example : (univ.filter fun p : ZMod 9 × ZMod 9 =>
    p.1 ∈ ({1, 2, 4, 8, 9} : Finset (ZMod 9)) ∧ p.1 + p.2 ∈ ({1, 2, 4, 8, 9} : Finset (ZMod 9)) ∧
      p.1 + 2 * p.2 ∈ ({1, 2, 4, 8, 9} : Finset (ZMod 9))).card = 13 := by
  decide

/-- T(P) = 41: the solutions of x + z = 2y with x, y, z in 1 to 9 number 5² + 4². -/
example : ((Icc 1 9 ×ˢ Icc 1 9 ×ˢ Icc 1 9).filter fun t : ℕ × ℕ × ℕ =>
    t.1 + t.2.2 = 2 * t.2.1).card = 5 ^ 2 + 4 ^ 2 := by
  decide

#print axioms roth_number_lt_seventy_two_mul_div_log_log
#print axioms roth_number_share_tendsto_zero
#print axioms three_term_count_eq_fourier_sum
