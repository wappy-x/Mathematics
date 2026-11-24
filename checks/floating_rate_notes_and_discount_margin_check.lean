-- Floating-rate notes: on a reset date a floater discounted at its own quoted margin is worth exactly its face on any curve, and any positive price has exactly one discount margin.
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Algebra.BigOperators.Field
import Mathlib.Topology.Order.IntermediateValue
import Mathlib.Topology.Algebra.Order.Field
import Mathlib.Topology.Instances.Real.Lemmas
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp

open Finset

/-! The note pays once a year for `n` years on a face `F`. Year `i` runs from 1 to `n`.
`f i` is the forward rate for year `i`, read off today's curve; it is the projected index.
`m` is the quoted margin in the contract and `d` the discount margin the market asks.

`frnGrowth f d i = ∏ j ∈ Icc 1 i, (1 + f j + d)` is `G_i` on the card: what one dollar grows to
over the first `i` years at forward plus `d` (so `G_0 = 1`).

`frnPrice F f m d n` is the card's `P(d)`: each projected coupon `F (f i + m)` discounted by `G_i`,
plus the face discounted by `G_n`. -/

/-- `G_i`: one dollar grown over the first `i` years at each year's forward rate plus `d`. -/
noncomputable def frnGrowth (f : ℕ → ℝ) (d : ℝ) (i : ℕ) : ℝ :=
  ∏ j ∈ Icc 1 i, (1 + f j + d)

/-- `P(d) = ∑_{i=1}^{n} F (f_i + m) / G_i + F / G_n`: the floater's price at discount margin `d`. -/
noncomputable def frnPrice (F : ℝ) (f : ℕ → ℝ) (m d : ℝ) (n : ℕ) : ℝ :=
  (∑ i ∈ Icc 1 n, F * (f i + m) / frnGrowth f d i) + F / frnGrowth f d n


lemma frnGrowth_succ (f : ℕ → ℝ) (d : ℝ) (n : ℕ) :
    frnGrowth f d (n + 1) = frnGrowth f d n * (1 + f (n + 1) + d) := by
  unfold frnGrowth
  rw [Finset.prod_Icc_succ_top (by omega)]

lemma frnGrowth_pos (f : ℕ → ℝ) (d : ℝ) (n i : ℕ)
    (hpos : ∀ j ∈ Icc 1 n, 0 < 1 + f j + d) (hi : i ≤ n) : 0 < frnGrowth f d i := by
  unfold frnGrowth
  apply Finset.prod_pos
  intro j hj
  apply hpos
  simp only [Finset.mem_Icc] at hj ⊢
  omega

lemma frnGrowth_const (r d : ℝ) (i : ℕ) : frnGrowth (fun _ => r) d i = (1 + r + d) ^ i := by
  simp [frnGrowth, Finset.prod_const, Nat.card_Icc]

lemma frn_par_aux (F : ℝ) (f : ℕ → ℝ) (m : ℝ) (n : ℕ) :
    (∀ j ∈ Icc 1 n, 0 < 1 + f j + m) →
    (∑ i ∈ Icc 1 n, F * (f i + m) / frnGrowth f m i) + F / frnGrowth f m n = F := by
  induction n with
  | zero => intro _; simp [frnGrowth]
  | succ n ih =>
    intro hpos
    have hpos' : ∀ j ∈ Icc 1 n, 0 < 1 + f j + m := by
      intro j hj; apply hpos; simp only [Finset.mem_Icc] at hj ⊢; omega
    have hG : 0 < frnGrowth f m n := frnGrowth_pos f m n n hpos' le_rfl
    have hx : 0 < 1 + f (n + 1) + m := hpos (n + 1) (by simp)
    rw [Finset.sum_Icc_succ_top (by omega), frnGrowth_succ]
    have h1 := ih hpos'
    have key : F * (f (n + 1) + m) / (frnGrowth f m n * (1 + f (n + 1) + m))
        + F / (frnGrowth f m n * (1 + f (n + 1) + m)) = F / frnGrowth f m n := by
      rw [← add_div, div_eq_div_iff (mul_pos hG hx).ne' hG.ne']
      ring
    linarith

/-- Par on a reset date. Project each coupon as the forward rate plus the quoted margin `m`,
discount it year by year at the forward rate plus the same margin `m`, add the discounted face,
and the price is exactly the face `F`, whatever the forward rates are (every growth factor
`1 + f j + m` positive, so every discount is defined). -/
theorem par_on_reset (F : ℝ) (f : ℕ → ℝ) (m : ℝ) (n : ℕ)
    (hpos : ∀ j ∈ Icc 1 n, 0 < 1 + f j + m) :
    frnPrice F f m m n = F := by
  unfold frnPrice
  exact frn_par_aux F f m n hpos

/-- Exactly one discount margin fits any positive price. For a note with a positive face, at least
one coupon, and every projected coupon `f i + m` at or above zero, each quoted price `q > 0` is
matched by exactly one discount margin `d` among those that keep every factor `1 + f j + d`
positive. -/
theorem discount_margin_exists_unique (F : ℝ) (f : ℕ → ℝ) (m : ℝ) (n : ℕ)
    (hF : 0 < F) (hn : 1 ≤ n) (hcoupon : ∀ i ∈ Icc 1 n, 0 ≤ f i + m)
    (q : ℝ) (hq : 0 < q) :
    ∃! d : ℝ, (∀ j ∈ Icc 1 n, 0 < 1 + f j + d) ∧ frnPrice F f m d n = q := by
  have hne : (Icc 1 n).Nonempty := ⟨1, by simp; omega⟩
  obtain ⟨j0, hj0, hmin⟩ := Finset.exists_min_image (Icc 1 n) f hne
  obtain ⟨L, hLdef⟩ : ∃ L : ℝ, L = -(1 + f j0) := ⟨_, rfl⟩
  have hfac : ∀ d : ℝ, ∀ j ∈ Icc 1 n, d - L ≤ 1 + f j + d := by
    intro d j hj
    have := hmin j hj
    rw [hLdef]; linarith
  have hdom : ∀ d : ℝ, (∀ j ∈ Icc 1 n, 0 < 1 + f j + d) ↔ L < d := by
    intro d
    constructor
    · intro h; have := h j0 hj0; rw [hLdef]; linarith
    · intro h j hj; have := hfac d j hj; linarith
  -- strictly decreasing on the domain
  have hanti : ∀ d1 d2 : ℝ, L < d1 → d1 < d2 → frnPrice F f m d2 n < frnPrice F f m d1 n := by
    intro d1 d2 h1 h12
    have hp1 := (hdom d1).2 h1
    unfold frnPrice
    have hsum : ∑ i ∈ Icc 1 n, F * (f i + m) / frnGrowth f d2 i
        ≤ ∑ i ∈ Icc 1 n, F * (f i + m) / frnGrowth f d1 i := by
      apply Finset.sum_le_sum
      intro i hi
      have hin : i ≤ n := (Finset.mem_Icc.1 hi).2
      apply div_le_div_of_nonneg_left (mul_nonneg hF.le (hcoupon i hi))
        (frnGrowth_pos f d1 n i hp1 hin)
      unfold frnGrowth
      apply Finset.prod_le_prod₀
      · intro j hj
        exact (hp1 j (by simp only [Finset.mem_Icc] at hj ⊢; omega)).le
      · intro j _; linarith
    have hlast : F / frnGrowth f d2 n < F / frnGrowth f d1 n := by
      apply div_lt_div_of_pos_left hF (frnGrowth_pos f d1 n n hp1 le_rfl)
      unfold frnGrowth
      apply Finset.prod_lt_prod_of_nonempty₀
      · intro j hj; exact hp1 j hj
      · intro j _; linarith
      · exact hne
    linarith
  -- continuity
  have hGcont : ∀ i, Continuous (fun d => frnGrowth f d i) := by
    intro i; unfold frnGrowth; fun_prop
  have hPcont : ContinuousOn (fun d => frnPrice F f m d n) (Set.Ioi L) := by
    unfold frnPrice
    apply ContinuousOn.add
    · apply continuousOn_finsetSum
      intro i hi
      apply ContinuousOn.div continuousOn_const (hGcont i).continuousOn
      intro d hd
      exact (frnGrowth_pos f d n i ((hdom d).2 hd) (Finset.mem_Icc.1 hi).2).ne'
    · apply ContinuousOn.div continuousOn_const (hGcont n).continuousOn
      intro d hd
      exact (frnGrowth_pos f d n n ((hdom d).2 hd) le_rfl).ne'
  -- a point a just above L where the price is above q
  have hGL : frnGrowth f L n = 0 := by
    unfold frnGrowth
    exact Finset.prod_eq_zero hj0 (by rw [hLdef]; ring)
  have htend : Filter.Tendsto (fun d => frnGrowth f d n) (nhdsWithin L (Set.Ioi L)) (nhds 0) := by
    rw [← hGL]
    exact ((hGcont n).tendsto L).mono_left nhdsWithin_le_nhds
  have hev : ∀ᶠ d in nhdsWithin L (Set.Ioi L), frnGrowth f d n < F / q :=
    htend (Iio_mem_nhds (div_pos hF hq))
  obtain ⟨a, haG, haL⟩ := (hev.and self_mem_nhdsWithin).exists
  have haL' : L < a := haL
  have hpa : ∀ j ∈ Icc 1 n, 0 < 1 + f j + a := (hdom a).2 haL'
  have hGa := frnGrowth_pos f a n n hpa le_rfl
  have hPa : q < frnPrice F f m a n := by
    unfold frnPrice
    have hs : 0 ≤ ∑ i ∈ Icc 1 n, F * (f i + m) / frnGrowth f a i := by
      apply Finset.sum_nonneg
      intro i hi
      exact div_nonneg (mul_nonneg hF.le (hcoupon i hi))
        (frnGrowth_pos f a n i hpa (Finset.mem_Icc.1 hi).2).le
    have : q < F / frnGrowth f a n := by
      rw [lt_div_iff₀ hGa]
      rw [lt_div_iff₀ hq] at haG
      linarith
    linarith
  -- a point b far out where the price is below q
  obtain ⟨S, hS⟩ : ∃ S : ℝ, S = ∑ i ∈ Icc 1 n, F * (f i + m) := ⟨_, rfl⟩
  have hS0 : 0 ≤ S := by
    rw [hS]; exact Finset.sum_nonneg (fun i hi => mul_nonneg hF.le (hcoupon i hi))
  obtain ⟨t, ht⟩ : ∃ t : ℝ, t = max 1 ((S + F) / q + 1) := ⟨_, rfl⟩
  obtain ⟨b, hb⟩ : ∃ b : ℝ, b = max (L + t) (a + 1) := ⟨_, rfl⟩
  have hab : a < b := by
    have := le_max_right (L + t) (a + 1); rw [← hb] at this; linarith
  have htb : t ≤ b - L := by
    have := le_max_left (L + t) (a + 1); rw [← hb] at this; linarith
  have ht1 : 1 ≤ t := by rw [ht]; exact le_max_left _ _
  have htq : (S + F) / q < t := by
    have := le_max_right 1 ((S + F) / q + 1); rw [← ht] at this; linarith
  have ht0 : 0 < t := by linarith
  have hGb : ∀ i ∈ Icc 1 n, t ≤ frnGrowth f b i := by
    intro i hi
    have hi1 := Finset.mem_Icc.1 hi
    calc t ≤ t ^ i := le_self_pow₀ ht1 (by omega)
      _ = ∏ _j ∈ Icc 1 i, t := by simp [Finset.prod_const, Nat.card_Icc]
      _ ≤ frnGrowth f b i := by
            unfold frnGrowth
            apply Finset.prod_le_prod₀
            · intro j _; exact ht0.le
            · intro j hj
              have := hfac b j (by simp only [Finset.mem_Icc] at hj ⊢; omega)
              linarith
  have hPb : frnPrice F f m b n < q := by
    unfold frnPrice
    have h1 : ∑ i ∈ Icc 1 n, F * (f i + m) / frnGrowth f b i
        ≤ ∑ i ∈ Icc 1 n, F * (f i + m) / t := by
      apply Finset.sum_le_sum
      intro i hi
      exact div_le_div_of_nonneg_left (mul_nonneg hF.le (hcoupon i hi)) ht0 (hGb i hi)
    have h2 : F / frnGrowth f b n ≤ F / t :=
      div_le_div_of_nonneg_left hF.le ht0 (hGb n (by simp only [Finset.mem_Icc]; omega))
    have h3 : ∑ i ∈ Icc 1 n, F * (f i + m) / t = S / t := by
      rw [hS, Finset.sum_div]
    have h4 : (S + F) / t < q := by
      rw [div_lt_iff₀ ht0]
      rw [div_lt_iff₀ hq] at htq
      linarith
    have h5 : S / t + F / t = (S + F) / t := by rw [add_div]
    linarith
  -- intermediate value theorem on [a, b]
  have hcont_ab : ContinuousOn (fun d => frnPrice F f m d n) (Set.Icc a b) :=
    hPcont.mono (fun x hx => lt_of_lt_of_le haL' hx.1)
  obtain ⟨d, hd, hdq⟩ := intermediate_value_Icc' hab.le hcont_ab ⟨hPb.le, hPa.le⟩
  have hdq' : frnPrice F f m d n = q := hdq
  have hLd : L < d := lt_of_lt_of_le haL' hd.1
  refine ⟨d, ⟨(hdom d).2 hLd, hdq'⟩, ?_⟩
  rintro d' ⟨hd'pos, hd'q⟩
  have hL' := (hdom d').1 hd'pos
  rcases lt_trichotomy d' d with h | h | h
  · have := hanti d' d hL' h; linarith
  · exact h
  · have := hanti d d' hLd h; linarith

/-- On a flat curve, with every forward rate equal to `r`, the floater is the bond formula:
its price is the face plus `F (m - d)` times the annuity, the sum of the `n` discount factors at
`r + d`. So a floater whose market margin moves is priced like a fixed bond whose yield moves. -/
theorem flat_curve_price_eq_face_plus_margin_annuity (F r m d : ℝ) (n : ℕ)
    (hpos : 0 < 1 + r + d) :
    frnPrice F (fun _ => r) m d n
      = F + F * (m - d) * ∑ t ∈ Icc 1 n, 1 / (1 + r + d) ^ t := by
  have hpar := frn_par_aux F (fun _ => r) d n (fun _ _ => hpos)
  unfold frnPrice
  simp only [frnGrowth_const] at hpar ⊢
  have hsplit : ∑ i ∈ Icc 1 n, F * (r + m) / (1 + r + d) ^ i
      = ∑ i ∈ Icc 1 n, F * (r + d) / (1 + r + d) ^ i
        + F * (m - d) * ∑ i ∈ Icc 1 n, 1 / (1 + r + d) ^ i := by
    rw [Finset.mul_sum, ← Finset.sum_add_distrib]
    apply Finset.sum_congr rfl
    intro i _
    ring
  rw [hsplit]
  linarith

/-! The card's exact worked numbers: Larkfield's 3-year annual note on a face of 100,
quoted margin 1/100. -/

-- On the flat 4% curve, at the note's own 1.00% margin, the price is exactly 100.
example : frnPrice 100 (fun _ => 4 / 100) (1 / 100) (1 / 100) 3 = 100 := by
  norm_num [frnPrice, frnGrowth, Finset.sum_Icc_succ_top, Finset.prod_Icc_succ_top]

-- The curve rises to 5%, margin still 1.00%: the floater stays at exactly 100.
example : frnPrice 100 (fun _ => 5 / 100) (1 / 100) (1 / 100) 3 = 100 := by
  norm_num [frnPrice, frnGrowth, Finset.sum_Icc_succ_top, Finset.prod_Icc_succ_top]

-- The rising 3%, 4%, 5% spot curve: forwards 3%, 1.04^2/1.03 - 1 and 1.05^3/1.04^2 - 1.
-- At the note's own margin both roads give exactly 100.
example :
    frnPrice 100
      (fun j => if j = 1 then 3 / 100 else if j = 2 then (104 / 100) ^ 2 / (103 / 100) - 1
        else (105 / 100) ^ 3 / (104 / 100) ^ 2 - 1)
      (1 / 100) (1 / 100) 3 = 100 := by
  norm_num [frnPrice, frnGrowth, Finset.sum_Icc_succ_top, Finset.prod_Icc_succ_top]

-- Bracketing the discount margin at a price of 99: at 1.25% the price is above 99,
-- at 1.50% it is below.
example : 99 < frnPrice 100 (fun _ => 4 / 100) (1 / 100) (125 / 10000) 3 := by
  norm_num [frnPrice, frnGrowth, Finset.sum_Icc_succ_top, Finset.prod_Icc_succ_top]

example : frnPrice 100 (fun _ => 4 / 100) (1 / 100) (150 / 10000) 3 < 99 := by
  norm_num [frnPrice, frnGrowth, Finset.sum_Icc_succ_top, Finset.prod_Icc_succ_top]

-- The margin widens to 2.00% on the flat 4% curve: the floater is priced exactly like a
-- 3-year 5% fixed bond at a 6% yield.
example : frnPrice 100 (fun _ => 4 / 100) (1 / 100) (2 / 100) 3
    = 5 / (106 / 100) + 5 / (106 / 100) ^ 2 + 105 / (106 / 100) ^ 3 := by
  norm_num [frnPrice, frnGrowth, Finset.sum_Icc_succ_top, Finset.prod_Icc_succ_top]

#print axioms frnGrowth_succ
#print axioms frnGrowth_pos
#print axioms frnGrowth_const
#print axioms frn_par_aux
#print axioms par_on_reset
#print axioms discount_margin_exists_unique
#print axioms flat_curve_price_eq_face_plus_margin_annuity
