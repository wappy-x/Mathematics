-- Weyl differencing: van der Corput's inequality for any finite list of complex numbers, the exact squaring identity for sums of e(α n²), and the size √q of a quadratic Gauss sum.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.Complex.Basic
import Mathlib.Data.Int.Interval
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Algebra.Order.Chebyshev
import Mathlib.Analysis.SpecialFunctions.Complex.CircleAddChar
import Mathlib.NumberTheory.LegendreSymbol.AddCharacter
import Mathlib.Analysis.RCLike.Basic
import Mathlib.Tactic

open Finset

/-- `e x = exp(2πix)`: the point a fraction `x` of a turn round the unit circle. -/
noncomputable def e (x : ℝ) : ℂ := Complex.exp (2 * Real.pi * Complex.I * x)

theorem sum_Icc_int_shift (f : ℤ → ℂ) (a b c : ℤ) :
    ∑ n ∈ Icc a b, f (n + c) = ∑ m ∈ Icc (a + c) (b + c), f m := by
  refine sum_nbij' (fun n => n + c) (fun m => m - c) ?_ ?_ ?_ ?_ ?_
  · intro n hn; simp only [mem_Icc] at hn ⊢; omega
  · intro m hm; simp only [mem_Icc] at hm ⊢; omega
  · intro n _; simp
  · intro m _; simp
  · intro n _; rfl

#print axioms sum_Icc_int_shift

theorem card_shift_overlap (H : ℕ) (h : ℤ) (hh : h ∈ Ioo (-(H : ℤ)) H) :
    ((#((Ico (0 : ℤ) H).filter (fun b => h + b ∈ Ico (0 : ℤ) H)) : ℕ) : ℝ) = H - |(h : ℝ)| := by
  simp only [mem_Ioo] at hh
  rcases le_or_gt 0 h with h0 | h0
  · have hset : (Ico (0 : ℤ) H).filter (fun b => h + b ∈ Ico (0 : ℤ) H) = Ico 0 (H - h) := by
      ext b; simp only [mem_filter, mem_Ico]; omega
    rw [hset, Int.card_Ico, abs_of_nonneg (by exact_mod_cast h0)]
    have : ((((H : ℤ) - h - 0).toNat : ℕ) : ℤ) = H - h := by
      rw [Int.toNat_of_nonneg (by omega)]; ring
    have := congrArg (fun t : ℤ => (t : ℝ)) this
    push_cast at this
    exact this
  · have hset : (Ico (0 : ℤ) H).filter (fun b => h + b ∈ Ico (0 : ℤ) H) = Ico (-h) H := by
      ext b; simp only [mem_filter, mem_Ico]; omega
    rw [hset, Int.card_Ico, abs_of_neg (by exact_mod_cast h0)]
    have : ((((H : ℤ) - -h).toNat : ℕ) : ℤ) = H + h := by
      rw [Int.toNat_of_nonneg (by omega)]; ring
    have := congrArg (fun t : ℤ => (t : ℝ)) this
    push_cast at this
    rw [this]; ring

#print axioms card_shift_overlap

theorem sum_sum_sub_eq_weighted (H : ℕ) (f : ℤ → ℂ) :
    ∑ a ∈ Ico (0 : ℤ) H, ∑ b ∈ Ico (0 : ℤ) H, f (a - b) =
      ∑ h ∈ Ioo (-(H : ℤ)) H, (((H : ℝ) - |(h : ℝ)| : ℝ) : ℂ) * f h := by
  rw [sum_comm]
  have step : ∀ b ∈ Ico (0 : ℤ) H, ∑ a ∈ Ico (0 : ℤ) H, f (a - b) =
      ∑ h ∈ Ioo (-(H : ℤ)) H, if h + b ∈ Ico (0 : ℤ) H then f h else 0 := by
    intro b hb
    rw [← sum_filter]
    refine sum_nbij' (fun a => a - b) (fun h => h + b) ?_ ?_ ?_ ?_ ?_
    · intro a ha; simp only [mem_Ico] at hb ha; simp only [mem_filter, mem_Ioo, mem_Ico]; omega
    · intro h hh; simp only [mem_filter, mem_Ioo, mem_Ico] at hh; simp only [mem_Ico]; omega
    · intro a _; simp
    · intro h _; simp
    · intro a _; rfl
  rw [sum_congr rfl step, sum_comm]
  refine sum_congr rfl (fun h hh => ?_)
  rw [← sum_filter, sum_const, nsmul_eq_mul]
  congr 1
  have hc := card_shift_overlap H h hh
  have : ((#((Ico (0 : ℤ) H).filter (fun b => h + b ∈ Ico (0 : ℤ) H)) : ℕ) : ℂ) =
      ((((#((Ico (0 : ℤ) H).filter (fun b => h + b ∈ Ico (0 : ℤ) H)) : ℕ) : ℝ)) : ℂ) := by
    push_cast; rfl
  rw [this, hc]

#print axioms sum_sum_sub_eq_weighted

theorem e_add (x y : ℝ) : e (x + y) = e x * e y := by
  unfold e
  rw [← Complex.exp_add]
  congr 1
  push_cast
  ring

#print axioms e_add

theorem e_conj (x : ℝ) : (starRingEnd ℂ) (e x) = e (-x) := by
  unfold e
  rw [← Complex.exp_conj]
  congr 1
  simp [Complex.conj_ofReal, map_ofNat]

#print axioms e_conj

theorem e_zero : e 0 = 1 := by simp [e]

#print axioms e_zero

theorem sum_Icc_square_split (N : ℕ) (g : ℕ → ℕ → ℂ) :
    ∑ m ∈ Icc 1 N, ∑ n ∈ Icc 1 N, g m n =
      ∑ n ∈ Icc 1 N, g n n +
        ∑ h ∈ Ico 1 N, ∑ n ∈ Icc 1 (N - h), (g (n + h) n + g n (n + h)) := by
  set S := Icc 1 N ×ˢ Icc 1 N with hS
  rw [← sum_product' (f := g)]
  rw [← sum_filter_add_sum_filter_not S (fun p : ℕ × ℕ => p.1 = p.2)]
  rw [← sum_filter_add_sum_filter_not (S.filter (fun p : ℕ × ℕ => ¬ p.1 = p.2))
    (fun p : ℕ × ℕ => p.2 < p.1)]
  simp_rw [sum_add_distrib]
  congr 1
  · refine (sum_nbij' (fun n => (n, n)) Prod.fst ?_ ?_ ?_ ?_ ?_).symm
    · intro n hn
      rw [mem_filter, hS, mem_product]
      exact ⟨⟨hn, hn⟩, rfl⟩
    · intro p hp
      simp only [hS, mem_filter, mem_product, mem_Icc] at hp ⊢
      omega
    · intro n _; rfl
    · intro p hp
      simp only [hS, mem_filter, mem_product, mem_Icc] at hp
      exact Prod.ext rfl hp.2
    · intro n _; rfl
  congr 1
  · rw [sum_sigma']
    refine sum_nbij' (fun p => (⟨p.1 - p.2, p.2⟩ : (_ : ℕ) × ℕ))
      (fun x => (x.2 + x.1, x.2)) ?_ ?_ ?_ ?_ ?_
    · intro p hp
      simp only [hS, mem_filter, mem_product, mem_Icc, mem_sigma, mem_Ico] at hp ⊢
      omega
    · intro x hx
      simp only [hS, mem_filter, mem_product, mem_Icc, mem_sigma, mem_Ico] at hx ⊢
      omega
    · intro p hp
      simp only [hS, mem_filter, mem_product, mem_Icc] at hp
      refine Prod.ext ?_ rfl; dsimp only; omega
    · intro x hx
      simp only [mem_Icc, mem_sigma, mem_Ico] at hx
      ext <;> simp
    · intro p hp
      simp only [hS, mem_filter, mem_product, mem_Icc] at hp
      dsimp only
      congr 1; omega
  · rw [sum_sigma']
    refine sum_nbij' (fun p => (⟨p.2 - p.1, p.1⟩ : (_ : ℕ) × ℕ))
      (fun x => (x.2, x.2 + x.1)) ?_ ?_ ?_ ?_ ?_
    · intro p hp
      simp only [hS, mem_filter, mem_product, mem_Icc, mem_sigma, mem_Ico] at hp ⊢
      omega
    · intro x hx
      simp only [hS, mem_filter, mem_product, mem_Icc, mem_sigma, mem_Ico] at hx ⊢
      omega
    · intro p hp
      simp only [hS, mem_filter, mem_product, mem_Icc] at hp
      refine Prod.ext rfl ?_; dsimp only; omega
    · intro x hx
      simp only [mem_Icc, mem_sigma, mem_Ico] at hx
      ext <;> simp
    · intro p hp
      simp only [hS, mem_filter, mem_product, mem_Icc] at hp
      dsimp only
      congr 1; omega

#print axioms sum_Icc_square_split

theorem e_int_div_eq_stdAddChar (q : ℕ) [NeZero q] (j : ℤ) :
    e ((j : ℝ) / q) = ZMod.stdAddChar (N := q) (j : ZMod q) := by
  rw [ZMod.stdAddChar_coe, e]
  congr 1
  push_cast
  ring

#print axioms e_int_div_eq_stdAddChar

theorem sum_Icc_eq_sum_zmod (q : ℕ) [NeZero q] (f : ZMod q → ℂ) :
    ∑ n ∈ Icc 1 q, f (n : ZMod q) = ∑ x : ZMod q, f x := by
  have hq : 1 ≤ q := Nat.one_le_iff_ne_zero.mpr (NeZero.ne q)
  refine Finset.sum_bij' (fun n _ => (n : ZMod q)) (fun x _ => if x = 0 then q else x.val)
    (fun _ _ => mem_univ _) ?_ ?_ ?_ (fun _ _ => rfl)
  · intro x _
    simp only [mem_Icc]
    split_ifs with h
    · exact ⟨hq, le_rfl⟩
    · exact ⟨Nat.one_le_iff_ne_zero.mpr ((ZMod.val_ne_zero x).mpr h), (ZMod.val_lt x).le⟩
  · intro n hn
    simp only [mem_Icc] at hn
    split_ifs with h
    · rw [ZMod.natCast_eq_zero_iff] at h
      exact (Nat.le_antisymm hn.2 (Nat.le_of_dvd (by omega) h)).symm
    · rw [ZMod.val_natCast]
      apply Nat.mod_eq_of_lt
      rcases Nat.lt_or_ge n q with h' | h'
      · exact h'
      · exfalso; apply h; rw [show n = q by omega]; exact ZMod.natCast_self q
  · intro x _
    split_ifs with h
    · rw [h]; exact ZMod.natCast_self q
    · exact ZMod.natCast_zmod_val x

#print axioms sum_Icc_eq_sum_zmod

/-- Van der Corput's inequality. For any complex numbers `z 1, …, z N` (with `z n = 0` outside
1 to N) and any whole number `H` from 1 to N, the squared size of their sum is at most
`(N + H - 1)/H` times the total over shifts `|h| < H` of the weight `1 - |h|/H` times the
correlation `r(h) = ∑ₙ z (n + h) · conj (z n)`. -/
theorem van_der_corput_inequality (N H : ℕ) (z : ℤ → ℂ)
    (hz : ∀ n : ℤ, n ∉ Icc (1 : ℤ) N → z n = 0) (hH1 : 1 ≤ H) (hHN : H ≤ N) :
    ‖∑ n ∈ Icc (1 : ℤ) N, z n‖ ^ 2 ≤
      ((N + H - 1 : ℝ) / H) *
        (∑ h ∈ Ioo (-(H : ℤ)) H,
          ((1 - |(h : ℝ)| / H : ℝ) : ℂ) *
            ∑ n ∈ Icc (1 : ℤ) N, z (n + h) * (starRingEnd ℂ) (z n)).re := by
  set S := ∑ n ∈ Icc (1 : ℤ) N, z n with hSdef
  set r : ℤ → ℂ := fun h => ∑ n ∈ Icc (1 : ℤ) N, z (n + h) * (starRingEnd ℂ) (z n) with hr
  set A := Ico (0 : ℤ) H with hAdef
  set I := Icc (2 - (H : ℤ)) N with hIdef
  set w : ℤ → ℂ := fun n => ∑ a ∈ A, z (n + a) with hw
  have supp : ∀ (T : Finset ℤ) (f : ℤ → ℂ), Icc (1 : ℤ) N ⊆ T →
      (∀ m, m ∉ Icc (1 : ℤ) N → f m = 0) → ∑ m ∈ T, f m = ∑ m ∈ Icc (1 : ℤ) N, f m :=
    fun T f hT hf => (sum_subset hT (fun m _ hm => hf m hm)).symm
  have hA : ∀ a ∈ A, ∑ n ∈ I, z (n + a) = S := by
    intro a ha
    rw [hIdef, sum_Icc_int_shift z]
    apply supp _ _ _ hz
    intro m hm
    simp only [hAdef, mem_Ico] at ha
    simp only [mem_Icc] at hm ⊢
    omega
  have hsumw : ∑ n ∈ I, w n = (H : ℂ) * S := by
    simp only [hw]
    rw [sum_comm, sum_congr rfl hA, sum_const, hAdef, Int.card_Ico, nsmul_eq_mul]
    simp
  have hcard : (#I : ℝ) = N + H - 1 := by
    have h1 : ((N : ℤ) + 1 - (2 - H)).toNat = N + H - 1 := by omega
    rw [hIdef, Int.card_Icc, h1, Nat.cast_sub (by omega)]
    push_cast
    ring
  have hCS : (H : ℝ) ^ 2 * ‖S‖ ^ 2 ≤ (N + H - 1) * ∑ n ∈ I, ‖w n‖ ^ 2 := by
    have h1 : (H : ℝ) ^ 2 * ‖S‖ ^ 2 = ‖∑ n ∈ I, w n‖ ^ 2 := by
      rw [hsumw, norm_mul, mul_pow]
      simp
    rw [h1, ← hcard]
    calc ‖∑ n ∈ I, w n‖ ^ 2 ≤ (∑ n ∈ I, ‖w n‖) ^ 2 := by
          gcongr
          exact norm_sum_le _ _
      _ ≤ #I * ∑ n ∈ I, ‖w n‖ ^ 2 := sq_sum_le_card_mul_sum_sq
  have hcorr : ∀ a ∈ A, ∀ b ∈ A,
      ∑ n ∈ I, z (n + a) * (starRingEnd ℂ) (z (n + b)) = r (a - b) := by
    intro a _ b hb
    have h1 := sum_Icc_int_shift (fun m => z (m + (a - b)) * (starRingEnd ℂ) (z m))
      (2 - (H : ℤ)) N b
    beta_reduce at h1
    rw [show (∑ n ∈ I, z (n + a) * (starRingEnd ℂ) (z (n + b))) =
        ∑ n ∈ I, z (n + b + (a - b)) * (starRingEnd ℂ) (z (n + b)) from
        sum_congr rfl (fun n _ => by ring_nf), hIdef, h1]
    apply supp
    · intro m hm
      simp only [hAdef, mem_Ico] at hb
      simp only [mem_Icc] at hm ⊢
      omega
    · intro m hm
      simp [hz m hm]
  have hnorm : ∑ n ∈ I, ‖w n‖ ^ 2 = (∑ a ∈ A, ∑ b ∈ A, r (a - b)).re := by
    have h1 : ∀ n, (‖w n‖ ^ 2 : ℝ) = (w n * (starRingEnd ℂ) (w n)).re := by
      intro n
      rw [Complex.mul_conj, Complex.normSq_eq_norm_sq, Complex.ofReal_re]
    simp_rw [h1]
    rw [← Complex.re_sum]
    congr 1
    simp only [hw, map_sum, sum_mul_sum]
    rw [sum_comm]
    refine sum_congr rfl (fun a ha => ?_)
    rw [sum_comm]
    exact sum_congr rfl (fun b hb => hcorr a ha b hb)
  have hcount := sum_sum_sub_eq_weighted H r
  set Q := ∑ h ∈ Ioo (-(H : ℤ)) H, (((H : ℝ) - |(h : ℝ)| : ℝ) : ℂ) * r h with hQ
  have hmain : (H : ℝ) ^ 2 * ‖S‖ ^ 2 ≤ (N + H - 1) * Q.re := by
    rw [← hcount, ← hnorm]
    exact hCS
  have hrhs : (∑ h ∈ Ioo (-(H : ℤ)) H, ((1 - |(h : ℝ)| / H : ℝ) : ℂ) * r h) =
      ((1 / H : ℝ) : ℂ) * Q := by
    rw [hQ, mul_sum]
    refine sum_congr rfl (fun h _ => ?_)
    rw [← mul_assoc, ← Complex.ofReal_mul]
    congr 2
    have : (H : ℝ) ≠ 0 := by positivity
    field_simp
  have hHpos : (0 : ℝ) < H := by exact_mod_cast hH1
  show ‖S‖ ^ 2 ≤ ((N + H - 1 : ℝ) / H) *
    (∑ h ∈ Ioo (-(H : ℤ)) H, ((1 - |(h : ℝ)| / H : ℝ) : ℂ) * r h).re
  rw [hrhs, Complex.re_ofReal_mul]
  rw [show ((N + H - 1 : ℝ) / H) * (1 / H * Q.re) = (N + H - 1) * Q.re / H ^ 2 by
    field_simp]
  rw [le_div_iff₀ (by positivity)]
  linarith

/-- Weyl differencing for squares, as an exact identity. For any real `α` and any `N`, the squared
size of `S(N) = ∑_{n=1}^{N} e(α n²)` is `N` (each term paired with itself) plus twice the real part
of `∑_{h=1}^{N-1} e(α h²) ∑_{n=1}^{N-h} e(2 α h n)`, a sum of geometric series. -/
theorem weyl_differencing_squares (α : ℝ) (N : ℕ) :
    ‖∑ n ∈ Icc 1 N, e (α * (n : ℝ) ^ 2)‖ ^ 2 =
      (N : ℝ) + 2 * (∑ h ∈ Ico 1 N,
        e (α * (h : ℝ) ^ 2) * ∑ n ∈ Icc 1 (N - h), e (2 * α * h * n)).re := by
  set S := ∑ n ∈ Icc 1 N, e (α * (n : ℝ) ^ 2)
  set T := ∑ h ∈ Ico 1 N, e (α * (h : ℝ) ^ 2) * ∑ n ∈ Icc 1 (N - h), e (2 * α * h * n)
  have key : S * (starRingEnd ℂ) S = (N : ℂ) + (T + (starRingEnd ℂ) T) := by
    rw [map_sum, sum_mul_sum, sum_Icc_square_split]
    congr 1
    · rw [sum_congr rfl (fun n _ => by rw [e_conj, ← e_add, add_neg_cancel, e_zero])]
      simp
    · simp only [T, map_sum, map_mul, mul_sum, ← sum_add_distrib]
      refine sum_congr rfl (fun h _ => sum_congr rfl (fun n _ => ?_))
      simp only [e_conj, ← e_add]
      push_cast
      congr 2 <;> ring
  have h1 := Complex.mul_conj S
  rw [key, Complex.normSq_eq_norm_sq] at h1
  have h2 := congrArg Complex.re h1
  simp only [Complex.add_re, Complex.natCast_re, Complex.conj_re, Complex.ofReal_re] at h2
  rw [← h2]
  ring

/-- The quadratic Gauss sum by squaring. For odd `q` and `a` sharing no factor with `q`, the sum of
`e(a n² / q)` over one full period `n = 1, …, q` has squared size exactly `q`. -/
theorem quadratic_gauss_sum_norm_sq (q : ℕ) (a : ℤ) (hq : Odd q) (ha : IsCoprime a q) :
    ‖∑ n ∈ Icc 1 q, e ((a : ℝ) * (n : ℝ) ^ 2 / q)‖ ^ 2 = q := by
  have hq0 : q ≠ 0 := by rintro rfl; exact absurd hq (by decide)
  have : NeZero q := ⟨hq0⟩
  set ψ : AddChar (ZMod q) ℂ := ZMod.stdAddChar (N := q) with hψ
  set A : ZMod q := (a : ZMod q)
  have hA : IsUnit A := by
    obtain ⟨u, v, huv⟩ := ha
    have := congrArg (fun t : ℤ => (t : ZMod q)) huv
    simp only [Int.cast_add, Int.cast_mul, Int.cast_natCast, ZMod.natCast_self, mul_zero,
      add_zero, Int.cast_one] at this
    exact IsUnit.of_mul_eq_one_right _ this
  have h2 : IsUnit (2 : ZMod q) := by
    obtain ⟨k, hk⟩ := hq
    refine IsUnit.of_mul_eq_one ((k : ZMod q) + 1) ?_
    have h0 : ((2 * k + 1 : ℕ) : ZMod q) = 0 := by rw [← hk]; exact ZMod.natCast_self q
    push_cast at h0
    linear_combination h0
  have hsum : ∑ n ∈ Icc 1 q, e ((a : ℝ) * (n : ℝ) ^ 2 / q) = ∑ x : ZMod q, ψ (A * x ^ 2) := by
    rw [← sum_Icc_eq_sum_zmod q (fun x => ψ (A * x ^ 2))]
    refine sum_congr rfl (fun n _ => ?_)
    have := e_int_div_eq_stdAddChar q (a * (n : ℤ) ^ 2)
    push_cast at this
    rw [this]
  rw [hsum]
  set G := ∑ x : ZMod q, ψ (A * x ^ 2)
  have hconj : (starRingEnd ℂ) G = ∑ y : ZMod q, ψ (-(A * y ^ 2)) := by
    rw [map_sum]
    refine sum_congr rfl (fun y _ => ?_)
    rw [AddChar.map_neg_eq_conj]
  have hprod : G * (starRingEnd ℂ) G = q := by
    rw [hconj, sum_mul_sum]
    -- ∑ x ∑ y ψ(Ax²) ψ(-Ay²)
    rw [sum_comm]
    have : ∀ y : ZMod q, ∑ x : ZMod q, ψ (A * x ^ 2) * ψ (-(A * y ^ 2)) =
        ∑ h : ZMod q, ψ (A * h ^ 2) * ψ (h * (2 * A) * y) := by
      intro y
      rw [← Fintype.sum_equiv (Equiv.addRight y) _ _ (fun _ => rfl)]
      refine sum_congr rfl (fun h _ => ?_)
      rw [← AddChar.map_add_eq_mul, ← AddChar.map_add_eq_mul]
      congr 1
      simp only [Equiv.coe_addRight]
      ring
    simp_rw [this]
    rw [sum_comm]
    simp_rw [← mul_sum]
    classical
    have hm : ∀ h : ZMod q, ∑ y : ZMod q, ψ (h * (2 * A) * y) =
        if h = 0 then (q : ℂ) else 0 := by
      intro h
      have := AddChar.sum_mulShift (ψ := ψ) (h * (2 * A)) (ZMod.isPrimitive_stdAddChar q)
      simp_rw [mul_comm _ (h * (2 * A))] at this
      rw [this, ZMod.card]
      have hu : IsUnit (2 * A) := h2.mul hA
      simp only [hu.mul_left_eq_zero]
      split_ifs <;> simp
    simp_rw [hm]
    simp
  have := Complex.mul_conj G
  rw [hprod, Complex.normSq_eq_norm_sq] at this
  exact_mod_cast this.symm

-- The shifts with large caps solve Pell's equation x² - 8h² = 1: 2√2·h is nearest 3, 17, 99, 577, 3363.
example : (3 : ℤ) ^ 2 - 8 * 1 ^ 2 = 1 := by norm_num
example : (17 : ℤ) ^ 2 - 8 * 6 ^ 2 = 1 := by norm_num
example : (99 : ℤ) ^ 2 - 8 * 35 ^ 2 = 1 := by norm_num
example : (577 : ℤ) ^ 2 - 8 * 204 ^ 2 = 1 := by norm_num
example : (3363 : ℤ) ^ 2 - 8 * 1189 ^ 2 = 1 := by norm_num

-- The fractions 1393/985 and 8119/5741 near √2 come from p² - 2q² = ±1.
example : (1393 : ℤ) ^ 2 - 2 * 985 ^ 2 = -1 := by norm_num
example : (8119 : ℤ) ^ 2 - 2 * 5741 ^ 2 = -1 := by norm_num
example : Nat.gcd 1393 985 = 1 ∧ Nat.gcd 8119 5741 = 1 := by decide

-- The ten bins of {√2 n²} for n up to 10,000 hold all 10,000 points.
example : 1016 + 963 + 990 + 1042 + 979 + 1012 + 1027 + 1002 + 985 + 984 = 10000 := by norm_num

#print axioms van_der_corput_inequality
#print axioms weyl_differencing_squares
#print axioms quadratic_gauss_sum_norm_sq
