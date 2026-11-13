-- The doubling map: doubling and dropping the whole part deletes the first binary digit, so after n rounds the place is the start's digits from place n + 1 on, the places back after n rounds are exactly k/(2^n - 1), and the map is chaotic in Devaney's sense.
import Mathlib.Algebra.Order.Floor.Ring
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Dynamics.PeriodicPts.Defs
import Mathlib.Tactic.LinearCombination

/-- The doubling map on the 1 m strip: twice the place, with the whole part dropped
(`2x mod 1`). -/
noncomputable def doubling (x : ℝ) : ℝ := Int.fract (2 * x)

/-- The number with binary digits `b 0, b 1, b 2, …` after the point:
`0.b₁b₂b₃…` in the card's numbering, so the card's `b_k` is `b (k - 1)` here. -/
noncomputable def binVal (b : ℕ → Fin 2) : ℝ := ∑' k : ℕ, ((b k : ℕ) : ℝ) / 2 ^ (k + 1)

lemma binVal_term_le (b : ℕ → Fin 2) (k : ℕ) :
    ((b k : ℕ) : ℝ) / 2 ^ (k + 1) ≤ 1 / 2 / 2 ^ k := by
  have h : ((b k : ℕ) : ℝ) ≤ 1 := by exact_mod_cast Nat.lt_succ_iff.mp (b k).isLt
  rw [div_div, ← pow_succ']
  exact div_le_div_of_nonneg_right h (by positivity)

lemma binVal_term_nonneg (b : ℕ → Fin 2) (k : ℕ) :
    0 ≤ ((b k : ℕ) : ℝ) / 2 ^ (k + 1) := by positivity

lemma binVal_summable (b : ℕ → Fin 2) :
    Summable (fun k : ℕ => ((b k : ℕ) : ℝ) / 2 ^ (k + 1)) :=
  Summable.of_nonneg_of_le (binVal_term_nonneg b) (binVal_term_le b) (summable_geometric_two' 1)

lemma binVal_nonneg (b : ℕ → Fin 2) : 0 ≤ binVal b :=
  tsum_nonneg (binVal_term_nonneg b)

lemma binVal_lt_one (b : ℕ → Fin 2) (h : ∃ k, b k = 0) : binVal b < 1 := by
  obtain ⟨k, hk⟩ := h
  have := Summable.tsum_lt_tsum_of_nonneg (i := k) (binVal_term_nonneg b) (binVal_term_le b)
    (by rw [hk]; simp) (summable_geometric_two' 1)
  rw [tsum_geometric_two'] at this
  exact this

lemma binVal_split (b : ℕ → Fin 2) :
    2 * binVal b = ((b 0 : ℕ) : ℝ) + binVal (fun k => b (k + 1)) := by
  unfold binVal
  rw [(binVal_summable b).tsum_eq_zero_add]
  have : ∀ k : ℕ, ((b (k + 1) : ℕ) : ℝ) / 2 ^ (k + 1 + 1)
      = (((b (k + 1) : ℕ) : ℝ) / 2 ^ (k + 1)) / 2 := by
    intro k; rw [pow_succ]; ring
  simp only [this, tsum_div_const]
  ring

lemma doubling_binVal (b : ℕ → Fin 2) (h : ∃ k, b (k + 1) = 0) :
    doubling (binVal b) = binVal (fun k => b (k + 1)) := by
  unfold doubling
  rw [binVal_split, Int.fract_natCast_add, Int.fract_eq_self]
  exact ⟨binVal_nonneg _, binVal_lt_one _ h⟩

/-- The card's main theorem: write the start in binary as `0.b₁b₂b₃…`, with the string not
ending in endless 1s. After `n` rounds of "double and drop the whole part", the place is
`0.b_{n+1}b_{n+2}…`: the start's binary digits with the first `n` deleted (the shift). -/
theorem doubling_iterate_shifts_binary_digits (b : ℕ → Fin 2)
    (hb : ∀ N : ℕ, ∃ k ≥ N, b k = 0) (n : ℕ) :
    doubling^[n] (binVal b) = binVal (fun k => b (k + n)) := by
  induction n generalizing b with
  | zero => rfl
  | succ n ih =>
    rw [Function.iterate_succ_apply, doubling_binVal b]
    · rw [ih (fun k => b (k + 1))]
      · congr 1
      · intro N
        obtain ⟨k, hk, hk0⟩ := hb (N + 1)
        exact ⟨k - 1, by omega, by rw [Nat.sub_add_cancel (by omega)]; exact hk0⟩
    · obtain ⟨k, hk, hk0⟩ := hb 1
      exact ⟨k - 1, by rw [Nat.sub_add_cancel (by omega)]; exact hk0⟩

lemma fract_two_mul_fract (y : ℝ) : Int.fract (2 * Int.fract y) = Int.fract (2 * y) := by
  have : 2 * Int.fract y = 2 * y - ((2 * ⌊y⌋ : ℤ) : ℝ) := by rw [Int.fract]; push_cast; ring
  rw [this, Int.fract_sub_intCast]

lemma doubling_iterate_eq (n : ℕ) (x : ℝ) (hx : x ∈ Set.Ico (0 : ℝ) 1) :
    doubling^[n] x = Int.fract (2 ^ n * x) := by
  induction n with
  | zero =>
    simp only [Function.iterate_zero, id_eq, pow_zero, one_mul]
    exact (Int.fract_eq_self.mpr hx).symm
  | succ n ih =>
    rw [Function.iterate_succ_apply', ih, doubling, fract_two_mul_fract, pow_succ, mul_comm _ 2,
      mul_assoc]

/-- Returning places: for `n ≥ 1` rounds, a place `x` on the strip `[0, 1)` is back after
`n` rounds exactly when `x = k / (2^n - 1)` for some whole number `k = 0, 1, …, 2^n - 2`. -/
theorem doubling_returns_iff (n : ℕ) (hn : 1 ≤ n) (x : ℝ) (hx : x ∈ Set.Ico (0 : ℝ) 1) :
    doubling^[n] x = x ↔ ∃ k : ℕ, k < 2 ^ n - 1 ∧ x = (k : ℝ) / (2 ^ n - 1) := by
  have h2 : (2 : ℝ) ≤ 2 ^ n := by
    calc (2 : ℝ) = 2 ^ 1 := by norm_num
      _ ≤ 2 ^ n := pow_le_pow_right₀ (by norm_num) hn
  have hM : (0 : ℝ) < 2 ^ n - 1 := by linarith
  have hcast : (((2 ^ n - 1 : ℕ)) : ℝ) = 2 ^ n - 1 := by
    rw [Nat.cast_sub (Nat.one_le_two_pow), Nat.cast_pow]; norm_num
  rw [doubling_iterate_eq n x hx, Int.fract_eq_iff]
  constructor
  · rintro ⟨-, -, z, hz⟩
    have hz' : (z : ℝ) = x * (2 ^ n - 1) := by rw [← hz]; ring
    have hz0 : (0 : ℝ) ≤ z := by rw [hz']; exact mul_nonneg hx.1 hM.le
    have hz1 : (z : ℝ) < 2 ^ n - 1 := by
      rw [hz']; nlinarith [hx.2]
    have hz0' : 0 ≤ z := by exact_mod_cast hz0
    refine ⟨z.toNat, ?_, ?_⟩
    · have : ((z.toNat : ℕ) : ℝ) < ((2 ^ n - 1 : ℕ) : ℝ) := by
        rw [hcast]
        have : ((z.toNat : ℕ) : ℝ) = (z : ℝ) := by exact_mod_cast Int.toNat_of_nonneg hz0'
        rw [this]; exact hz1
      exact_mod_cast this
    · have : ((z.toNat : ℕ) : ℝ) = (z : ℝ) := by exact_mod_cast Int.toNat_of_nonneg hz0'
      rw [this, hz']; field_simp
  · rintro ⟨k, -, rfl⟩
    refine ⟨hx.1, hx.2, k, ?_⟩
    push_cast
    field_simp

lemma half_le_abs_fract_sub_fract_add_half (a : ℝ) :
    (1 : ℝ) / 2 ≤ |Int.fract a - Int.fract (a + 1 / 2)| := by
  have h0 := Int.fract_nonneg a
  have h1 := Int.fract_lt_one a
  rcases lt_or_ge (Int.fract a) (1 / 2) with h | h
  · have e : Int.fract (a + 1 / 2) = Int.fract a + 1 / 2 := by
      rw [Int.fract_eq_iff]
      refine ⟨by linarith, by linarith, ⌊a⌋, ?_⟩
      rw [Int.fract]; ring
    rw [e, abs_of_neg (by linarith)]; linarith
  · have e : Int.fract (a + 1 / 2) = Int.fract a - 1 / 2 := by
      rw [Int.fract_eq_iff]
      refine ⟨by linarith, by linarith, ⌊a⌋ + 1, ?_⟩
      rw [Int.fract]; push_cast; ring
    rw [e, abs_of_nonneg (by linarith)]; linarith

/-- Block `i` of the dense-orbit start has length `blkL i` and holds the whole number `blkJ i`. -/
def blkL (i : ℕ) : ℕ := (Nat.unpair i).1
def blkJ (i : ℕ) : ℕ := (Nat.unpair i).2 % 2 ^ blkL i
/-- Where block `i` starts: each block is followed by two zero digits. -/
def blkS (i : ℕ) : ℕ := ∑ l ∈ Finset.range i, (blkL l + 2)

/-- The value of the blocks from block `i` on, read from where block `i` starts. -/
noncomputable def tailVal (i : ℕ) : ℝ :=
  ∑' t : ℕ, (blkJ (i + t) : ℝ) * (1 / 2 : ℝ) ^ (blkS (i + t) - blkS i + blkL (i + t))

lemma blkS_succ (i : ℕ) : blkS (i + 1) = blkS i + blkL i + 2 := by
  simp [blkS, Finset.sum_range_succ, add_assoc]

lemma blkS_add (i t : ℕ) : blkS i + 2 * t ≤ blkS (i + t) := by
  induction t with
  | zero => simp
  | succ t ih => rw [← add_assoc, blkS_succ]; omega

lemma blkJ_bound (i : ℕ) :
    (blkJ i : ℝ) * (1 / 2 : ℝ) ^ blkL i + (1 / 2 : ℝ) ^ blkL i ≤ 1 := by
  have hlt : blkJ i < 2 ^ blkL i := Nat.mod_lt _ (by positivity)
  have hle : ((blkJ i : ℝ) + 1) ≤ 2 ^ blkL i := by exact_mod_cast hlt
  have hp : (2 : ℝ) ^ blkL i * (1 / 2) ^ blkL i = 1 := by rw [← mul_pow]; norm_num
  have hq : (0 : ℝ) ≤ (1 / 2) ^ blkL i := by positivity
  nlinarith

lemma tail_term_nonneg (i t : ℕ) :
    0 ≤ (blkJ (i + t) : ℝ) * (1 / 2 : ℝ) ^ (blkS (i + t) - blkS i + blkL (i + t)) := by
  positivity

lemma tail_term_le (i t : ℕ) :
    (blkJ (i + t) : ℝ) * (1 / 2 : ℝ) ^ (blkS (i + t) - blkS i + blkL (i + t)) ≤ (1 / 2) ^ t := by
  have hb := blkJ_bound (i + t)
  have hq : (0 : ℝ) ≤ (1 / 2) ^ blkL (i + t) := by positivity
  have hd : (1 / 2 : ℝ) ^ (blkS (i + t) - blkS i) ≤ (1 / 2) ^ t :=
    pow_le_pow_of_le_one (by norm_num) (by norm_num) (by have := blkS_add i t; omega)
  have hd0 : (0 : ℝ) ≤ (1 / 2) ^ (blkS (i + t) - blkS i) := by positivity
  have hj0 : (0 : ℝ) ≤ blkJ (i + t) := by positivity
  rw [pow_add]
  have hjq : (blkJ (i + t) : ℝ) * (1 / 2) ^ blkL (i + t) ≤ 1 := by linarith
  calc (blkJ (i + t) : ℝ) * ((1 / 2) ^ (blkS (i + t) - blkS i) * (1 / 2) ^ blkL (i + t))
      = ((blkJ (i + t) : ℝ) * (1 / 2) ^ blkL (i + t)) * (1 / 2) ^ (blkS (i + t) - blkS i) := by
        ring
    _ ≤ 1 * (1 / 2) ^ t := mul_le_mul hjq hd hd0 zero_le_one
    _ = (1 / 2) ^ t := one_mul _

lemma tail_summable (i : ℕ) :
    Summable (fun t : ℕ => (blkJ (i + t) : ℝ) * (1 / 2 : ℝ) ^ (blkS (i + t) - blkS i + blkL (i + t))) :=
  Summable.of_nonneg_of_le (tail_term_nonneg i) (tail_term_le i) summable_geometric_two

lemma tailVal_nonneg (i : ℕ) : 0 ≤ tailVal i := tsum_nonneg (tail_term_nonneg i)

lemma tailVal_le_two (i : ℕ) : tailVal i ≤ 2 := by
  calc tailVal i ≤ ∑' t : ℕ, (1 / 2 : ℝ) ^ t :=
        (tail_summable i).tsum_le_tsum (tail_term_le i) summable_geometric_two
    _ = 2 := tsum_geometric_two

lemma tailVal_succ (i : ℕ) :
    tailVal i = (blkJ i : ℝ) * (1 / 2 : ℝ) ^ blkL i + (1 / 2 : ℝ) ^ (blkL i + 2) * tailVal (i + 1) := by
  rw [tailVal, (tail_summable i).tsum_eq_zero_add, tailVal, ← tsum_mul_left]
  congr 1
  · simp
  · congr 1
    funext t
    have e1 : i + (t + 1) = i + 1 + t := by omega
    have e : blkS (i + 1 + t) - blkS i + blkL (i + 1 + t)
        = (blkL i + 2) + (blkS (i + 1 + t) - blkS (i + 1) + blkL (i + 1 + t)) := by
      have := blkS_add (i + 1) t; have := blkS_succ i; omega
    rw [e1, e, pow_add]; ring

lemma tailVal_bounds (i : ℕ) :
    (blkJ i : ℝ) * (1 / 2 : ℝ) ^ blkL i ≤ tailVal i ∧
      tailVal i ≤ (blkJ i : ℝ) * (1 / 2 : ℝ) ^ blkL i + (1 / 2 : ℝ) ^ blkL i / 2 ∧
      tailVal i < 1 := by
  have h0 := tailVal_nonneg (i + 1)
  have h2 := tailVal_le_two (i + 1)
  have hb := blkJ_bound i
  have hq : (0 : ℝ) < (1 / 2) ^ blkL i := by positivity
  have e : (1 / 2 : ℝ) ^ (blkL i + 2) = (1 / 2) ^ blkL i / 4 := by rw [pow_add]; ring
  rw [tailVal_succ, e]
  refine ⟨?_, ?_, ?_⟩
  · have : 0 ≤ (1 / 2 : ℝ) ^ blkL i / 4 * tailVal (i + 1) := by positivity
    linarith
  · nlinarith
  · nlinarith

lemma tailVal_mem (i : ℕ) : tailVal i ∈ Set.Ico (0 : ℝ) 1 :=
  ⟨tailVal_nonneg i, (tailVal_bounds i).2.2⟩

lemma tailVal_shift (i : ℕ) : ∃ N : ℤ, (2 : ℝ) ^ blkS i * tailVal 0 = N + tailVal i := by
  induction i with
  | zero => exact ⟨0, by simp [blkS]⟩
  | succ i ih =>
    obtain ⟨N, hN⟩ := ih
    refine ⟨2 ^ (blkL i + 2) * N + 4 * blkJ i, ?_⟩
    have hp : (2 : ℝ) ^ blkL i * (1 / 2) ^ blkL i = 1 := by rw [← mul_pow]; norm_num
    have h : (2 : ℝ) ^ (blkS i + blkL i + 2) * tailVal 0
        = 2 ^ blkL i * 2 ^ 2 * (2 ^ blkS i * tailVal 0) := by rw [pow_add, pow_add]; ring
    rw [blkS_succ, h, hN, tailVal_succ i, pow_add]
    push_cast
    linear_combination (4 * (blkJ i : ℝ) + tailVal (i + 1)) * hp

lemma dense_orbit :
    (∃ z ∈ Set.Ico (0 : ℝ) 1, ∀ x ∈ Set.Ico (0 : ℝ) 1, ∀ ε > 0,
        ∃ m : ℕ, |doubling^[m] z - x| < ε) := by
  refine ⟨tailVal 0, tailVal_mem 0, ?_⟩
  intro x hx ε hε
  obtain ⟨L, hL⟩ := exists_pow_lt_of_lt_one hε (by norm_num : (1 / 2 : ℝ) < 1)
  set j := ⌊x * 2 ^ L⌋₊ with hj
  have hx2 : 0 ≤ x * 2 ^ L := mul_nonneg hx.1 (by positivity)
  have hjlt : j < 2 ^ L := by
    rw [hj, Nat.floor_lt hx2]; push_cast
    have : (0 : ℝ) < 2 ^ L := by positivity
    nlinarith [hx.2]
  have hjle : (j : ℝ) ≤ x * 2 ^ L := Nat.floor_le hx2
  have hjgt : x * 2 ^ L < j + 1 := Nat.lt_floor_add_one _
  set i := Nat.pair L j
  have hLi : blkL i = L := by simp [i, blkL, Nat.unpair_pair]
  have hJi : blkJ i = j := by simp [i, blkJ, blkL, Nat.unpair_pair, Nat.mod_eq_of_lt hjlt]
  refine ⟨blkS i, ?_⟩
  obtain ⟨N, hN⟩ := tailVal_shift i
  rw [doubling_iterate_eq _ _ (tailVal_mem 0), hN, Int.fract_intCast_add,
    Int.fract_eq_self.mpr (tailVal_mem i)]
  obtain ⟨b1, b2, -⟩ := tailVal_bounds i
  rw [hLi, hJi] at b1 b2
  have hp : (2 : ℝ) ^ L * (1 / 2) ^ L = 1 := by rw [← mul_pow]; norm_num
  have hq : (0 : ℝ) < (1 / 2) ^ L := by positivity
  have c1 : (j : ℝ) * (1 / 2) ^ L ≤ x := by
    have := mul_le_mul_of_nonneg_right hjle hq.le
    calc (j : ℝ) * (1 / 2) ^ L ≤ x * 2 ^ L * (1 / 2) ^ L := this
      _ = x := by rw [mul_assoc, hp, mul_one]
  have c2 : x < (j : ℝ) * (1 / 2) ^ L + (1 / 2) ^ L := by
    have := mul_lt_mul_of_pos_right hjgt hq
    calc x = x * 2 ^ L * (1 / 2) ^ L := by rw [mul_assoc, hp, mul_one]
      _ < ((j : ℝ) + 1) * (1 / 2) ^ L := this
      _ = (j : ℝ) * (1 / 2) ^ L + (1 / 2) ^ L := by ring
  rw [abs_sub_lt_iff]
  constructor <;> linarith

lemma sensitive_dependence :
    ∀ x ∈ Set.Ico (0 : ℝ) 1, ∀ ε > 0, ∃ y ∈ Set.Ico (0 : ℝ) 1, |x - y| < ε ∧
        ∃ n : ℕ, (1 : ℝ) / 2 ≤ |doubling^[n] x - doubling^[n] y| := by
  intro x hx ε hε
  obtain ⟨n, hn⟩ := exists_pow_lt_of_lt_one hε (by norm_num : (1 / 2 : ℝ) < 1)
  set δ : ℝ := (1 / 2) ^ (n + 1) with hδ
  have hδ0 : 0 < δ := by positivity
  have hδε : δ < ε := by
    have : δ = (1 / 2) ^ n / 2 := by rw [hδ, pow_succ]; ring
    have : (0 : ℝ) < (1 / 2) ^ n := by positivity
    linarith
  have hδh : δ ≤ 1 / 2 := by
    rw [hδ, pow_succ]
    have : (1 / 2 : ℝ) ^ n ≤ 1 := pow_le_one₀ (by norm_num) (by norm_num)
    nlinarith
  have hscale : (2 : ℝ) ^ n * δ = 1 / 2 := by
    rw [hδ, pow_succ, ← mul_assoc, ← mul_pow]; norm_num
  rcases lt_or_ge (x + δ) 1 with h | h
  · refine ⟨x + δ, ⟨by linarith [hx.1], h⟩, ?_, n, ?_⟩
    · rw [show x - (x + δ) = -δ by ring, abs_neg, abs_of_pos hδ0]; exact hδε
    · rw [doubling_iterate_eq n x hx, doubling_iterate_eq n (x + δ) ⟨by linarith [hx.1], h⟩,
        mul_add, hscale]
      exact half_le_abs_fract_sub_fract_add_half _
  · have hy : x - δ ∈ Set.Ico (0 : ℝ) 1 := ⟨by linarith, by linarith [hx.2]⟩
    refine ⟨x - δ, hy, ?_, n, ?_⟩
    · rw [show x - (x - δ) = δ by ring, abs_of_pos hδ0]; exact hδε
    · rw [doubling_iterate_eq n x hx, doubling_iterate_eq n (x - δ) hy, mul_sub, hscale,
        abs_sub_comm]
      have := half_le_abs_fract_sub_fract_add_half (2 ^ n * x - 1 / 2)
      rwa [sub_add_cancel] at this

lemma dense_periodic_points :
    ∀ x ∈ Set.Ico (0 : ℝ) 1, ∀ ε > 0, ∃ y ∈ Set.Ico (0 : ℝ) 1, |x - y| < ε ∧
        ∃ n : ℕ, 0 < n ∧ Function.IsPeriodicPt doubling n y := by
  intro x hx ε hε
  obtain ⟨N, hN⟩ := exists_nat_gt (1 / ε)
  set n := N + 1
  have hNn : N + 2 ≤ 2 ^ n := by
    have := Nat.lt_two_pow_self (n := n); omega
  have hNnR : (N : ℝ) + 2 ≤ 2 ^ n := by exact_mod_cast hNn
  set M : ℝ := 2 ^ n - 1 with hMdef
  have hM : 0 < M := by
    have : (0 : ℝ) ≤ N := by positivity
    linarith
  have hεM : 1 / M < ε := by
    rw [div_lt_iff₀ hM]
    have := (div_lt_iff₀ hε).mp hN
    nlinarith
  set y : ℝ := (⌊x * M⌋ : ℝ) / M with hy
  have hxM : 0 ≤ x * M := mul_nonneg hx.1 hM.le
  have hfl0 : (0 : ℝ) ≤ (⌊x * M⌋ : ℝ) := by exact_mod_cast Int.floor_nonneg.mpr hxM
  have hyx : y ≤ x := by
    rw [hy, div_le_iff₀ hM]; exact Int.floor_le _
  have hxy : x - y < 1 / M := by
    have h1 := Int.lt_floor_add_one (x * M)
    have : x - y = (x * M - ⌊x * M⌋) / M := by rw [hy]; field_simp
    rw [this]
    exact div_lt_div_of_pos_right (by linarith) hM
  have hyI : y ∈ Set.Ico (0 : ℝ) 1 := ⟨div_nonneg hfl0 hM.le, by linarith [hx.2]⟩
  refine ⟨y, hyI, ?_, n, Nat.succ_pos N, ?_⟩
  · rw [abs_of_nonneg (by linarith)]; linarith
  · show doubling^[n] y = y
    rw [doubling_iterate_eq n y hyI, Int.fract_eq_iff]
    refine ⟨hyI.1, hyI.2, ⌊x * M⌋, ?_⟩
    have : (2 : ℝ) ^ n = M + 1 := by rw [hMdef]; ring
    rw [this, hy]; field_simp; ring

/-- Devaney's three conditions hold on the strip `[0, 1)`.
Sensitive dependence: beside every start, as close as you like, is another start that is
1/2 m away from it after some number of rounds.
Dense periodic points: as close as you like to every start is a place on a cycle.
A dense orbit: one start whose orbit comes as close as you like to every place. -/
theorem doubling_is_chaotic :
    (∀ x ∈ Set.Ico (0 : ℝ) 1, ∀ ε > 0, ∃ y ∈ Set.Ico (0 : ℝ) 1, |x - y| < ε ∧
        ∃ n : ℕ, (1 : ℝ) / 2 ≤ |doubling^[n] x - doubling^[n] y|) ∧
    (∀ x ∈ Set.Ico (0 : ℝ) 1, ∀ ε > 0, ∃ y ∈ Set.Ico (0 : ℝ) 1, |x - y| < ε ∧
        ∃ n : ℕ, 0 < n ∧ Function.IsPeriodicPt doubling n y) ∧
    (∃ z ∈ Set.Ico (0 : ℝ) 1, ∀ x ∈ Set.Ico (0 : ℝ) 1, ∀ ε > 0,
        ∃ m : ℕ, |doubling^[m] z - x| < ε) := by
  exact ⟨sensitive_dependence, dense_periodic_points, dense_orbit⟩

-- The raisin at 0.7 m: 0.7, 0.4, 0.8, 0.6, 0.2, then 0.4 again.
example : doubling (7 / 10) = 2 / 5 := by norm_num [doubling, Int.fract_eq_iff]
example : doubling (2 / 5) = 4 / 5 := by norm_num [doubling, Int.fract_eq_iff]
example : doubling (4 / 5) = 3 / 5 := by norm_num [doubling, Int.fract_eq_iff]
example : doubling (3 / 5) = 1 / 5 := by norm_num [doubling, Int.fract_eq_iff]
example : doubling (1 / 5) = 2 / 5 := by norm_num [doubling, Int.fract_eq_iff]

-- 0.7 in binary starts 0.1011001100110011: the first 16 digits are ⌊0.7 × 2^16⌋.
example : 7 * 2 ^ 16 / 10 = 0b1011001100110011 := by decide

-- The three-round cycle 1/7 → 2/7 → 4/7 → 1/7, and the other one 3/7 → 6/7 → 5/7 → 3/7.
example : doubling (1 / 7) = 2 / 7 := by norm_num [doubling, Int.fract_eq_iff]
example : doubling (2 / 7) = 4 / 7 := by norm_num [doubling, Int.fract_eq_iff]
example : doubling (4 / 7) = 1 / 7 := by norm_num [doubling, Int.fract_eq_iff]
example : doubling (3 / 7) = 6 / 7 := by norm_num [doubling, Int.fract_eq_iff]
example : doubling (6 / 7) = 5 / 7 := by norm_num [doubling, Int.fract_eq_iff]
example : doubling (5 / 7) = 3 / 7 := by norm_num [doubling, Int.fract_eq_iff]

-- Places back after 3 rounds: k/7 for k = 0, …, 6, seven places (2^3 - 1 = 7);
-- after 4 rounds: k/15, fifteen places. In whole numbers, 2^n k leaves remainder k.
example : ∀ k < 2 ^ 3 - 1, 2 ^ 3 * k % 7 = k := by decide
example : ∀ k < 2 ^ 4 - 1, 2 ^ 4 * k % 15 = k := by decide

-- Every binary word of length 1 to 4, written in a row, fills 98 digits.
example : ∑ L ∈ Finset.Icc 1 4, L * 2 ^ L = 98 := by decide

-- The tent map (stretch to 2 m and fold back) has the cycle 2/7 → 4/7 → 6/7 → 2/7.
example : (2 : ℚ) / 7 ≤ 1 / 2 ∧ 2 * (2 / 7 : ℚ) = 4 / 7 := by norm_num
example : ¬ ((4 : ℚ) / 7 ≤ 1 / 2) ∧ 2 - 2 * (4 / 7 : ℚ) = 6 / 7 := by norm_num
example : ¬ ((6 : ℚ) / 7 ≤ 1 / 2) ∧ 2 - 2 * (6 / 7 : ℚ) = 2 / 7 := by norm_num

#print axioms binVal_term_le
#print axioms binVal_term_nonneg
#print axioms binVal_summable
#print axioms binVal_nonneg
#print axioms binVal_lt_one
#print axioms binVal_split
#print axioms doubling_binVal
#print axioms fract_two_mul_fract
#print axioms doubling_iterate_eq
#print axioms half_le_abs_fract_sub_fract_add_half
#print axioms blkS_succ
#print axioms blkS_add
#print axioms blkJ_bound
#print axioms tail_term_nonneg
#print axioms tail_term_le
#print axioms tail_summable
#print axioms tailVal_nonneg
#print axioms tailVal_le_two
#print axioms tailVal_succ
#print axioms tailVal_bounds
#print axioms tailVal_mem
#print axioms tailVal_shift
#print axioms dense_orbit
#print axioms sensitive_dependence
#print axioms dense_periodic_points
#print axioms doubling_iterate_shifts_binary_digits
#print axioms doubling_returns_iff
#print axioms doubling_is_chaotic
