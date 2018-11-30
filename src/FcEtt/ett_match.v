Set Bullet Behavior "Strict Subproofs".
Set Implicit Arguments.

Require Export FcEtt.tactics.
Require Export FcEtt.imports.
Require Import FcEtt.utils.

Require Export FcEtt.ett_inf.
Require Export FcEtt.ett_ott.
Require Export FcEtt.ett_ind.
Require Export FcEtt.toplevel.
Require Export FcEtt.fix_typing.
Require Import FcEtt.ett_roleing.
Require Import FcEtt.ett_path.
Require Import FcEtt.ett_par.

Require Import Coq.Sorting.Permutation.
Require Import Omega.

(** Patterns, agreement and substitution function **)

Inductive Pattern : tm -> Prop :=
  | Pattern_Fam : forall F, Pattern (a_Fam F)
  | Pattern_AppR : forall a1 R x, Pattern a1 -> Pattern (a_App a1 (Role R) (a_Var_f x))
  | Pattern_IApp : forall a1, Pattern a1 -> Pattern (a_App a1 (Rho Irrel) a_Bullet)
  | Pattern_CApp : forall a1, Pattern a1 -> Pattern (a_CApp a1 g_Triv).

Hint Constructors Pattern.

Inductive Pattern_like_tm : tm -> Prop :=
  | Pat_tm_Fam : forall F, Pattern_like_tm (a_Fam F)
  | Pat_tm_AppR : forall a1 nu a2, Pattern_like_tm a1 -> lc_tm a2 ->
                                  Pattern_like_tm (a_App a1 nu a2)
  | Pat_tm_CApp : forall a1, Pattern_like_tm a1 ->
                             Pattern_like_tm (a_CApp a1 g_Triv).

Hint Constructors Pattern_like_tm.

Fixpoint vars_Pattern (p : tm) := match p with
   | a_Fam F => []
   | a_App p1 (Role _) (a_Var_f x) => vars_Pattern p1 ++ [ x ]
   | a_App p1 (Rho Irrel) a_Bullet => vars_Pattern p1
   | a_CApp p1 g_Triv => vars_Pattern p1
   | _ => []
   end.

Fixpoint tms_Pattern_like_tm (a : tm) := match a with
   | a_Fam F => []
   | a_App a1 (Role _) a' => tms_Pattern_like_tm a1 ++ [ a' ]
   | a_App a1 (Rho Irrel) a_Bullet => tms_Pattern_like_tm a1
   | a_CApp a1 g_Triv => tms_Pattern_like_tm a1
   | _ => []
   end.

Definition uniq_atoms L := uniq (List.map (fun x => (x, Nom)) L).

Definition uniq_atoms_pattern p := uniq_atoms (vars_Pattern p).

Fixpoint matchsubst a p b : tm := match (a,p) with
  | (a_Fam F, a_Fam F') => b
  | (a_App a1 (Role R) a2, a_App p1 (Role R') (a_Var_f x)) =>
         tm_subst_tm_tm a2 x (matchsubst a1 p1 b)
  | (a_App a1 (Rho Irrel) a', a_App p1 (Rho Irrel) a_Bullet) =>
         matchsubst a1 p1 b
  | (a_CApp a1 g_Triv, a_CApp p1 g_Triv) => matchsubst a1 p1 b
  | (_,_) => b
  end.

Fixpoint head_const (a : tm) : tm := match a with
  | a_Fam F => a_Fam F
  | a_App a' nu b => head_const a'
  | a_CApp a' g_Triv => head_const a'
  | _ => a_Bullet
  end.


Lemma patctx_pattern : forall W G F p B A, PatternContexts W G F A p B ->
      Pattern p.
Proof. intros. induction H; eauto.
Qed.

Lemma patctx_pattern_head : forall W G F p B A, PatternContexts W G F A p B ->
      head_const p = a_Fam F.
Proof. intros. induction H; simpl; eauto.
Qed.

Lemma ValuePath_Pattern_like_tm : forall a F, ValuePath a F -> Pattern_like_tm a.
Proof. intros. induction H; eauto.
Qed.

Lemma axiom_pattern : forall F p b A R1 Rs,
      binds F (Ax p b A R1 Rs) toplevel -> Pattern p.
Proof. intros. assert (P : Sig toplevel). apply Sig_toplevel.
       induction P. inversion H. inversion H. inversion H2. eauto.
       inversion H. inversion H5; subst. eapply patctx_pattern; eauto.
       eauto.
Qed.

Lemma axiom_pattern_head : forall F p b A R1 Rs,
      binds F (Ax p b A R1 Rs) toplevel -> head_const p = a_Fam F.
Proof. intros. assert (P : Sig toplevel). apply Sig_toplevel.
       induction P. inversion H. inversion H. inversion H2. eauto.
       inversion H. inversion H5; subst. eapply patctx_pattern_head; eauto.
       eauto.
Qed.


Lemma matchsubst_ind_fun : forall a p b b',
      MatchSubst a p b b' -> matchsubst a p b = b'.
Proof. intros. induction H.
        - simpl. auto.
        - destruct R; simpl. rewrite IHMatchSubst. auto.
          rewrite IHMatchSubst. auto.
        - simpl. auto.
        - simpl. auto.
Qed.

Corollary MatchSubst_function : forall a p b b1 b2,
      MatchSubst a p b b1 -> MatchSubst a p b b2 -> b1 = b2.
Proof. intros. apply matchsubst_ind_fun in H.
       apply matchsubst_ind_fun in H0. rewrite H in H0. auto.
Qed.

Lemma tm_pattern_agree_tm : forall a p, tm_pattern_agree a p -> Pattern_like_tm a.
Proof. intros. induction H; eauto.
Qed.

Lemma tm_pattern_agree_pattern : forall a p, tm_pattern_agree a p -> Pattern p.
Proof. intros. induction H; eauto.
Qed.

Lemma subtm_pattern_agree_pattern : forall a p, subtm_pattern_agree a p -> Pattern p.
Proof. intros. induction H; eauto. eapply tm_pattern_agree_pattern; eauto.
Qed.

Lemma subtm_pattern_agree_tm : forall a p, subtm_pattern_agree a p -> Pattern_like_tm a.
Proof. intros. induction H; eauto. eapply tm_pattern_agree_tm; eauto.
Qed.

Lemma tm_subpattern_agree_tm : forall a p, tm_subpattern_agree a p -> Pattern_like_tm a.
Proof. intros. induction H; eauto. eapply tm_pattern_agree_tm; eauto.
Qed.

Lemma tm_pattern_agree_const_same : forall a p, tm_pattern_agree a p ->
         head_const a = head_const p.
Proof. intros. induction H; simpl; eauto.
Qed.

Lemma MatchSubst_match : forall a p b b', MatchSubst a p b b' ->
                                            tm_pattern_agree a p.
Proof. intros. induction H; eauto.
Qed.

Corollary MatchSubst_nexists : forall a p, ~(tm_pattern_agree a p) ->
                      forall b b', ~(MatchSubst a p b b').
Proof. intros. intro H'. apply MatchSubst_match in H'. contradiction.
Qed.

Lemma tm_pattern_agree_bullet_bullet : forall a p, tm_pattern_agree a p ->
                                       MatchSubst a p a_Bullet a_Bullet.
Proof. intros. induction H; eauto.
       assert (a_Bullet = tm_subst_tm_tm a2 x a_Bullet) by auto.
       assert (MatchSubst (a_App a1 (Role R) a2) (a_App p1 (Role R) (a_Var_f x))
       a_Bullet (tm_subst_tm_tm a2 x a_Bullet)). eauto. rewrite <- H1 in H2.
       auto.
Qed.

Lemma tm_pattern_agree_dec : forall a p, lc_tm a -> tm_pattern_agree a p \/
                                        ~(tm_pattern_agree a p).
Proof. intros. pose (P := match_dec p H). inversion P as [P1 | P2].
       left. eapply MatchSubst_match; eauto.
       right. intro. apply P2. eapply tm_pattern_agree_bullet_bullet; auto.
Qed.

Lemma tm_pattern_agree_app_contr : forall a p nu b, tm_pattern_agree a p ->
               tm_pattern_agree a (a_App p nu b) -> False.
Proof. intros a p nu b H. generalize dependent b.
       induction H; intros b H1; inversion H1; subst; eauto.
Qed.

Lemma tm_pattern_agree_capp_contr : forall a p, tm_pattern_agree a p ->
               tm_pattern_agree a (a_CApp p g_Triv) -> False.
Proof. intros a p H. induction H; intro H1; inversion H1; eauto.
Qed.

Corollary MatchSubst_app_nexists : forall a p b b',
          MatchSubst (a_App a (Rho Irrel) a_Bullet) p b b' ->
          ~(tm_pattern_agree a p).
Proof. intros. apply MatchSubst_match in H. intro. inversion H.
       subst. eapply tm_pattern_agree_app_contr; eauto.
Qed.

Corollary MatchSubst_capp_nexists : forall a p b b',
          MatchSubst (a_CApp a g_Triv) p b b' ->
          ~(tm_pattern_agree a p).
Proof. intros. apply MatchSubst_match in H. intro. inversion H.
       subst. eapply tm_pattern_agree_capp_contr; eauto.
Qed.

Lemma tm_pattern_agree_rename_inv_1 : forall a p p' b b' D D',
      tm_pattern_agree a p -> Rename p b p' b' D D' -> tm_pattern_agree a p'.
Proof. intros. generalize dependent p'. generalize dependent D.
       generalize dependent b'. generalize dependent D'.
       induction H; intros D' b' D p' H1; inversion H1; subst; eauto.
Qed.

Lemma tm_pattern_agree_rename_inv_2 : forall a p p' b b' D D',
      tm_pattern_agree a p -> Rename p' b' p b D D' -> tm_pattern_agree a p'.
Proof. intros. generalize dependent p'. generalize dependent D.
       generalize dependent b. generalize dependent D'.
       induction H; intros D' b D p' H1; inversion H1; subst; eauto.
Qed.

Inductive Pi_CPi_head_form : tm -> Prop :=
  | head_Pi : forall rho A B, Pi_CPi_head_form (a_Pi rho A B)
  | head_CPi : forall phi B, Pi_CPi_head_form (a_CPi phi B).
Hint Constructors Pi_CPi_head_form.

Inductive Abs_CAbs_head_form : tm -> Prop :=
  | head_Abs : forall rho a, Abs_CAbs_head_form (a_UAbs rho a)
  | head_CAbs : forall a, Abs_CAbs_head_form (a_UCAbs a).
Hint Constructors Abs_CAbs_head_form.

Inductive Const_App_CApp_head_form : tm -> Prop :=
   | head_Fam : forall F, Const_App_CApp_head_form (a_Fam F)
   | head_App : forall nu a b, Const_App_CApp_head_form (a_App a nu b)
  | head_CApp : forall a, Const_App_CApp_head_form (a_CApp a g_Triv).
Hint Constructors Const_App_CApp_head_form.

Lemma tm_pattern_agree_tm_const_app : forall a p, tm_pattern_agree a p ->
       Const_App_CApp_head_form a.
Proof. intros. induction H; eauto.
Qed.

Lemma subtm_pattern_agree_tm_const_app : forall a p, subtm_pattern_agree a p ->
       Const_App_CApp_head_form a.
Proof. intros. induction H; eauto. eapply tm_pattern_agree_tm_const_app; eauto.
Qed.

Lemma subtm_pattern_agree_dec : forall a p, lc_tm a -> subtm_pattern_agree a p \/
                                        ~(subtm_pattern_agree a p).
Proof. intros.
       induction a; try(right; intro P;
       apply subtm_pattern_agree_tm_const_app in P; inversion P; fail).
         - inversion H; subst. destruct (IHa1 H2) as [Q1 | Q2].
           left; eauto. pose (Q := tm_pattern_agree_dec p H).
           destruct Q as [Q3 | Q4]. left; eauto. right; intro.
           inversion H0; subst; contradiction.
         - destruct g; try (right; intro P;
           apply subtm_pattern_agree_tm_const_app in P; inversion P; fail).
           inversion H; subst. destruct (IHa H2) as [Q1 | Q2].
           left; eauto. pose (Q := tm_pattern_agree_dec p H).
           destruct Q as [Q3 | Q4]. left; eauto. right; intro.
           inversion H0; subst; contradiction.
         - pose (P := tm_pattern_agree_dec p H). destruct P as [P1 | P2].
           left; eauto. right; intro. inversion H0; subst; contradiction.
Qed.


(* If a agrees with p, then a can be substituted for p in b *)

Lemma MatchSubst_exists : forall a p, tm_pattern_agree a p -> forall b,
                          lc_tm b -> exists b', MatchSubst a p b b'.
Proof. intros a p H. induction H; intros.
        - exists b; auto.
        - pose (P := IHtm_pattern_agree b H1). inversion P as [b1 Q].
          exists (tm_subst_tm_tm a2 x b1). eauto.
        - pose (P := IHtm_pattern_agree b H1). inversion P as [b1 Q].
          exists b1; eauto.
        - pose (P := IHtm_pattern_agree b H0). inversion P as [b1 Q].
          exists b1; eauto.
Qed.

Lemma matchsubst_fun_ind : forall a p b b', tm_pattern_agree a p -> lc_tm b ->
      matchsubst a p b = b' -> MatchSubst a p b b'.
Proof. intros. generalize dependent b. generalize dependent b'.
       induction H; intros; eauto.
        - simpl in H1. rewrite <- H1. auto.
        - destruct R. simpl in H2. rewrite <- H2. eauto.
          simpl in H2. rewrite <- H2. eauto.
Qed.

Fixpoint rename p b D := match p with
   | a_Fam F => (p,b,empty)
   | a_App p1 (Role R) (a_Var_f x) => let (p'b',D') := rename p1 b D in
           let (p',b') := p'b' in
           let y := fresh(AtomSetImpl.elements (D \u D')) in
           (a_App p' (Role R) (a_Var_f y), tm_subst_tm_tm (a_Var_f y) x b',
           singleton y \u D')
   | a_App p1 (Rho Irrel) a_Bullet => let (p'b',D') := rename p1 b D in
           let (p',b') := p'b' in (a_App p' (Rho Irrel) a_Bullet,b',D')
   | a_CApp p1 g_Triv => let (p'b',D') := rename p1 b D in
           let (p',b') := p'b' in (a_CApp p' g_Triv,b',D')
   | _ => (p,b,D)
   end.

Lemma rename_Rename : forall p b D, Pattern p -> lc_tm b ->
      Rename p b (rename p b D).1.1 (rename p b D).1.2 D (rename p b D).2.
Proof. intros. generalize dependent b. generalize dependent D.
       induction H; intros.
        - simpl. eauto.
        - simpl. destruct (rename a1 b D) eqn:hyp. destruct p. simpl.
          econstructor. replace t0 with (rename a1 b D).1.1.
          replace t1 with (rename a1 b D).1.2.
          replace t with (rename a1 b D).2. eauto. rewrite hyp; auto.
          rewrite hyp; auto. rewrite hyp; auto.
          intro. apply AtomSetImpl.elements_1 in H1.
          assert (In (fresh (AtomSetImpl.elements (D \u t))) 
                     (AtomSetImpl.elements (D \u t))).
          rewrite <- InA_iff_In. auto. eapply fresh_not_in. eauto.
        - simpl. destruct (rename a1 b D) eqn:hyp. destruct p. simpl.
          econstructor. replace t0 with (rename a1 b D).1.1.
          replace t1 with (rename a1 b D).1.2.
          replace t with (rename a1 b D).2. eauto. rewrite hyp; auto.
          rewrite hyp; auto. rewrite hyp; auto.
        - simpl. destruct (rename a1 b D) eqn:hyp. destruct p. simpl.
          econstructor. replace t0 with (rename a1 b D).1.1.
          replace t1 with (rename a1 b D).1.2.
          replace t with (rename a1 b D).2. eauto. rewrite hyp; auto.
          rewrite hyp; auto. rewrite hyp; auto.
Qed.

Definition chain_substitution := fold_right (fun y => tm_subst_tm_tm (snd y) (fst y)).

Fixpoint tm_pattern_correspond (a p : tm) : list (atom * tm) := match (a,p) with
  | (a_Fam F, a_Fam F') => nil
  | (a_App a1 (Role Nom) a2, a_App p1 (Role Nom) (a_Var_f x)) =>
         (x, a2) :: tm_pattern_correspond a1 p1
  | (a_App a1 (Role Rep) a2, a_App p1 (Role Rep) (a_Var_f x)) =>
         (x, a2) :: tm_pattern_correspond a1 p1
  | (a_App a1 (Rho Irrel) a_Bullet, a_App p1 (Rho Irrel) a_Bullet) =>
         tm_pattern_correspond a1 p1
  | (a_CApp a1 g_Triv, a_CApp p1 g_Triv) => tm_pattern_correspond a1 p1
  | (_,_) => nil
  end.

Lemma chain_sub_fam : forall l F,
                      chain_substitution (a_Fam F) l = a_Fam F.
Proof. intros. induction l. simpl; auto. destruct a; simpl. rewrite IHl.
       auto.
Qed.
(*
Lemma chain_sub_app : forall l nu a1 a2,
           chain_substitution l (a_App a1 nu a2) =
           a_App (chain_substitution l a1) nu (chain_substitution l a2).
Proof. intros. induction l. simpl; auto. destruct a; simpl. rewrite IHl.
       auto.
Qed.

Lemma chain_sub_var : forall l x, exists y, 
                      chain_substitution (map a_Var_f l) (a_Var_f x) = a_Var_f y.
Proof. intros. induction l. simpl. exists x; auto. destruct a.
       simpl. inversion IHl as [y P]. rewrite P. destruct (a == y).
       subst. exists t; simpl. destruct (y == y). auto. contradiction.
       exists y. simpl. destruct (y == a). symmetry in e. contradiction.
       auto.
Qed.

Lemma chain_sub_bullet : forall l, chain_substitution l a_Bullet = a_Bullet.
Proof. intros. induction l; try destruct a; simpl; try rewrite IHl; eauto.
Qed.

Lemma chain_sub_capp : forall l a, chain_substitution l (a_CApp a g_Triv) =
                       a_CApp (chain_substitution l a) g_Triv.
Proof. intros. induction l. simpl; auto. destruct a0; simpl. rewrite IHl; auto.
Qed.

Lemma Path_pat_rename_consist : forall a p l, Path_pat_consist a p ->
              Path_pat_consist a (chain_substitution (map a_Var_f l) p).
Proof. intros. induction H.
        - rewrite chain_sub_fam. eauto.
        - rewrite chain_sub_app. pose (P := chain_sub_var l x).
          inversion P as [y Q]. rewrite Q. eauto.
        - rewrite chain_sub_app. rewrite chain_sub_bullet. eauto.
        - rewrite chain_sub_capp; eauto.
Qed.


Lemma MatchSubst_permutation : forall a p b,
              chain_substitution (permutation a p) b = matchsubst a p b.
Proof. intros. generalize dependent p. generalize dependent b.
       induction a; intros; eauto.
       all: try destruct g; try destruct nu; eauto.
       all: try destruct R; try destruct rho; eauto.
        - destruct p; eauto. destruct nu; eauto. destruct R; eauto.
          destruct p2; eauto. simpl. rewrite IHa1. auto.
        - destruct p; eauto. destruct nu; eauto. destruct R; eauto.
          destruct p2; eauto. simpl. rewrite IHa1. auto.
        - destruct a2; eauto. destruct p; eauto. destruct nu; eauto.
          destruct rho; eauto. destruct p2; eauto.
        - destruct p; eauto. destruct g; eauto.
        - destruct p; eauto.
Qed.

Inductive ICApp : tm -> tm -> Prop :=
   | ICApp_refl : forall a, ICApp a a
   | ICApp_IApp : forall a1 a2, ICApp a1 a2 -> ICApp a1 (a_App a2 (Rho Irrel) a_Bullet)
   | ICApp_CApp : forall a1 a2, ICApp a1 a2 -> ICApp a1 (a_CApp a2 g_Triv).

Lemma nonempty_perm : forall a p x l, x :: l = permutation a p ->
      exists a1 a2 p1 y, (ICApp (a_App a1 (Role Nom) a2) a /\ 
              ICApp (a_App p1 (Role Nom) (a_Var_f y)) p /\ x = (y, a2)
              /\ l = permutation a1 p1) \/
              (ICApp (a_App a1 (Role Rep) a2) a /\ 
              ICApp (a_App p1 (Role Rep) (a_Var_f y)) p /\ x = (y, a2)
              /\ l = permutation a1 p1).
Proof. intros a. induction a; intros p y l H; try (inversion H; fail).
       destruct nu; try (inversion H; fail).
       destruct R; try (inversion H; fail).
       destruct p; try (inversion H; fail).
       destruct nu; try (inversion H; fail).
       destruct R; try (inversion H; fail).
       destruct p2; try (inversion H; fail).
       inversion H. exists a1, a2, p1, x. left; repeat split.
       eapply ICApp_refl. eapply ICApp_refl.
       destruct p; try (inversion H; fail).
       destruct nu; try (inversion H; fail).
       destruct R; try (inversion H; fail).
       destruct p2; try (inversion H; fail).
       inversion H. exists a1, a2, p1, x. right; repeat split.
       eapply ICApp_refl. eapply ICApp_refl.
       destruct rho; try (inversion H; fail).
       destruct a2; try (inversion H; fail).
       destruct p; try (inversion H; fail).
       destruct nu; try (inversion H; fail).
       destruct rho; try (inversion H; fail).
       destruct p2; try (inversion H; fail).
       simpl in H. pose (P := IHa1 p1 y l ltac:(auto)).
       inversion P as [a2 [a3 [p2 [y0 [Q1 | Q2]]]]]. 
       exists a2, a3, p2, y0. inversion Q1 as [S1 [S2 [S3 S4]]].
       left; repeat split.
       eapply ICApp_IApp; auto.
       eapply ICApp_IApp; auto. auto. auto.
       exists a2, a3, p2, y0. inversion Q2 as [T1 [T2 [T3 T4]]]. 
       right; repeat split.
       eapply ICApp_IApp; auto.
       eapply ICApp_IApp; auto. auto. auto.
       destruct g; try (inversion H; fail).
       destruct p; try (inversion H; fail).
       destruct g; try (inversion H; fail).
       simpl in H. pose (P := IHa p y l ltac:(auto)).
       inversion P as [a2 [a3 [p2 [y0 [Q1 | Q2]]]]]. 
       exists a2, a3, p2, y0. inversion Q1 as [S1 [S2 [S3 S4]]].
       left; repeat split.
       eapply ICApp_CApp; auto.
       eapply ICApp_CApp; auto. auto. auto.
       exists a2, a3, p2, y0. inversion Q2 as [T1 [T2 [T3 T4]]]. 
       right; repeat split.
       eapply ICApp_CApp; auto.
       eapply ICApp_CApp; auto. auto. auto.
       destruct p; try (inversion H; fail).
Qed.

Lemma fv_ICApp : forall a1 a2 x, ICApp a1 a2 -> x `in` fv_tm_tm_tm a1 <->
                  x `in` fv_tm_tm_tm a2.
Proof. intros. generalize dependent x.
       induction H; intro.
         - split; auto.
         - pose (P := IHICApp x). inversion P as [P1 P2].
           split; intro; simpl in *; fsetdec.
         - pose (P := IHICApp x). inversion P as [P1 P2].
           split; intro; simpl in *; fsetdec.
Qed.

Lemma fv_perm_1 : forall a p l x a', l = permutation a p -> In (x,a') l ->
                    x `in` fv_tm_tm_tm p.
Proof. intros. generalize dependent a. generalize dependent p.
       dependent induction l; intros. inversion H0.
       inversion H0. subst. apply nonempty_perm in H.
       inversion H as [a1 [a2 [p1 [y [Q1 | Q2]]]]].
       inversion Q1 as [S1 [S2 [S3 S4]]].
       eapply (fv_ICApp x) in S2. inversion S3; subst. simpl in S2.
       fsetdec. inversion Q2 as [T1 [T2 [T3 T4]]].
       eapply (fv_ICApp x) in T2. inversion T3; subst. simpl in T2.
       fsetdec. apply nonempty_perm in H.
       inversion H as [a1 [a2 [p1 [y [Q1 | Q2]]]]].
       inversion Q1 as [S1 [S2 [S3 S4]]].
       eapply (fv_ICApp x) in S2. apply S2. simpl. apply union_iff.
       left. eapply IHl; eauto.
       inversion Q2 as [T1 [T2 [T3 T4]]].
       eapply (fv_ICApp x) in T2. apply T2. simpl. apply union_iff.
       left. eapply IHl; eauto.
Qed.

Lemma fv_perm_2 : forall a p l x a', l = permutation a p -> In (x,a') l ->
                  forall y, y `in` fv_tm_tm_tm a' -> y `in` fv_tm_tm_tm a.
Proof. intros. generalize dependent a. generalize dependent p.
       dependent induction l; intros. inversion H0.
       inversion H0. subst. apply nonempty_perm in H.
       inversion H as [a1 [a2 [p1 [z [Q1 | Q2]]]]].
       inversion Q1 as [S1 [S2 [S3 S4]]].
       eapply (fv_ICApp y) in S1. inversion S3; subst. simpl in S1.
       fsetdec. inversion Q2 as [T1 [T2 [T3 T4]]].
       eapply (fv_ICApp y) in T1. inversion T3; subst. simpl in T1.
       fsetdec. apply nonempty_perm in H.
       inversion H as [a1 [a2 [p1 [z [Q1 | Q2]]]]].
       inversion Q1 as [S1 [S2 [S3 S4]]].
       eapply (fv_ICApp y) in S1. apply S1. simpl. apply union_iff.
       left. eapply IHl; eauto.
       inversion Q2 as [T1 [T2 [T3 T4]]].
       eapply (fv_ICApp y) in T1. apply T1. simpl. apply union_iff.
       left. eapply IHl; eauto.
Qed.

Fixpoint rang (L : list (atom * tm)) : atoms :=
   match L with
   | nil => empty
   | (x, a) :: l => fv_tm_tm_tm a \u rang l
   end.

Lemma dom_Perm : forall A (L : list (atom * A)) L', Permutation L L' ->
                                                        dom L [=] dom L'.
Proof. intros. induction H; eauto. fsetdec. destruct x; simpl. fsetdec.
       destruct x, y. simpl. fsetdec. eapply transitivity; eauto.
Qed.

Lemma rang_Perm : forall L L', Permutation L L' -> rang L [=] rang L'.
Proof. intros. induction H; eauto. fsetdec. destruct x; simpl. fsetdec.
       destruct x, y. simpl. fsetdec. eapply transitivity; eauto.
Qed.

Lemma uniq_Perm : forall A (L : list (atom * A)) L', Permutation L L' ->
                                                      uniq L -> uniq L'.
Proof. intros. induction H; eauto. destruct x. apply uniq_cons_iff in H0.
       inversion H0. eapply uniq_cons_3; eauto. apply dom_Perm in H. fsetdec.
       destruct x, y. solve_uniq.
Qed.

Lemma Chain_sub_Permutation : forall L L' b,
        uniq L -> (forall x, x `in` dom L -> x `notin` rang L) ->
        Permutation L L' -> chain_substitution L b = chain_substitution L' b.
Proof. intros.
       dependent induction H1; intros.
         - auto.
         - simpl. destruct x. erewrite IHPermutation; eauto 1.
           solve_uniq. intros. simpl in H0. pose (P := H0 x ltac:(auto)).
           fsetdec.
         - destruct x, y. simpl. rewrite tm_subst_tm_tm_tm_subst_tm_tm.
           rewrite (tm_subst_tm_tm_fresh_eq t). auto. simpl in H0.
           pose (P := H0 a0 ltac:(auto)). fsetdec. simpl in H0.
           pose (P := H0 a ltac:(auto)). fsetdec.
           solve_uniq.
         - apply transitivity with (y := chain_substitution l' b).
           eapply IHPermutation1; eauto. eapply IHPermutation2.
           eapply uniq_Perm; eauto. pose (P := H1_). pose (Q := H1_).
           apply dom_Perm in P. apply rang_Perm in Q. intros.
           pose (S := H0 x). fsetdec.
Qed.

Lemma perm_pat_subst : forall a p x y a' l l1 l2, l = permutation a p ->
      uniq l -> y `notin` dom l -> l = l1 ++ (x, a') :: l2 ->
      permutation a (tm_subst_tm_tm (a_Var_f y) x p) = l1 ++ (y, a') :: l2.
Proof. intros. generalize dependent a. generalize dependent p.
       generalize dependent l1. generalize dependent l2.
       dependent induction l; intros. destruct l1; inversion H2.
       destruct l1; simpl in *. inversion H2; subst.
       apply nonempty_perm in H. inversion H as [a1 [a2 [p1 [z [P1 | P2]]]]].
       inversion P1 as [Q1 [Q2 [Q3 Q4]]]. inversion Q3; subst.
       solve_uniq. fsetdec.

Lemma chain_sub_subst : forall a p b x y,
    uniq (permutation a p) -> (forall z, z `in` p -> z `notin` fv_tm_tm_tm a) ->
    x `in` fv_tm_tm_tm p -> y `notin` fv_tm_tm_tm a ->
    chain_substitution (permutation a (tm_subst_tm_tm (a_Var_f y) x p))
    tm_subst_tm_tm (a_Var_f y) x b) = chain_substitution (permutation a p) b.
Proof. intros. rewrite MatchSubst_permutation. rewrite MatchSubst_permutation.

Lemma rename_chain_sub : forall a l p b,
 chain_substitution (permutation a (chain_substitution (map a_Var_f l) p))
 (chain_substitution (map a_Var_f l) b) = chain_substitution (permutation a p) b.
Proof. intros. generalize dependent p; generalize dependent b.
       induction l; intros. simpl. auto.
       destruct a0. rewrite map_cons.
       rewrite (Chain_sub_Permutation (L := [(a0, a_Var_f t)] ++ map a_Var_f l)
       (L' := map a_Var_f l ++ ([(a0, a_Var_f t)]))).
       rewrite chain_sub_append.
       rewrite (Chain_sub_Permutation (L := [(a0, a_Var_f t)] ++ map a_Var_f l)
       (L' := map a_Var_f l ++ ([(a0, a_Var_f t)]))).
       rewrite chain_sub_append. simpl. rewrite IHl.

Definition Nice a p := Path_pat_consist a p /\
              (forall x, x `in` fv_tm_tm_tm p -> x `notin` fv_tm_tm_tm a) /\
               uniq (permutation a p).

Fixpoint matchsubst2 a p b : tm := match (a,p) with
  | (a_Fam F, a_Fam F') => if F == F' then b else a_Bullet
  | (a_App a1 (Role Nom) a2, a_App p1 (Role Nom) (a_Var_f x)) =>
         tm_subst_tm_tm a2 x (matchsubst a1 p1 b)
  | (a_App a1 (Role Rep) a2, a_App p1 (Role Rep) (a_Var_f x)) =>
         tm_subst_tm_tm a2 x (matchsubst a1 p1 b)
  | (a_App a1 (Rho Irrel) a_Bullet, a_App p1 (Rho Irrel) a_Bullet) =>
         matchsubst a1 p1 b
  | (a_CApp a1 g_Triv, a_CApp p1 g_Triv) => matchsubst a1 p1 b
  | (_,_) => a_Bullet
  end.

Lemma matchsubst_subst : forall a p b x y, x `notin` fv_tm_tm_tm a ->
      y `notin` fv_tm_tm_tm a -> matchsubst2 a p b =
    matchsubst2 a (tm_subst_tm_tm (a_Var_f y) x p) (tm_subst_tm_tm (a_Var_f y) x b).
Proof. intros. generalize dependent p. generalize dependent b.
       induction a; intros; eauto.
         - destruct nu; eauto. destruct R; eauto.
           destruct p; eauto. simpl. destruct (x0 == x); auto.
           destruct nu; eauto. destruct R; eauto. destruct p2; eauto.
           simpl. destruct (x0 == x); auto.

Fixpoint matchsubst2 a p b : tm := match (a,p) with
  | (a_Fam F, a_Fam F') => if F == F' then b else a_Bullet
  | (a_App a1 (Role Nom) a2, a_App p1 (Role Nom) (a_Var_f x)) =>
         matchsubst2 a1 p1 (tm_subst_tm_tm a2 x b)
  | (a_App a1 (Role Rep) a2, a_App p1 (Role Rep) (a_Var_f x)) =>
         matchsubst2 a1 p1 (tm_subst_tm_tm a2 x b)
  | (a_App a1 (Rho Irrel) a_Bullet, a_App p1 (Rho Irrel) a_Bullet) =>
         matchsubst a1 p1 b
  | (a_CApp a1 g_Triv, a_CApp p1 g_Triv) => matchsubst a1 p1 b
  | (_,_) => a_Bullet
  end.

Lemma matchsubst_matchsubst2 : forall a p b,
      (forall x, x `in` fv_tm_tm_tm a -> x `notin` fv_tm_tm_tm p) ->
       matchsubst a p b = matchsubst2 a p b.
Proof. intros. generalize dependent p. generalize dependent b.
       induction a; intros; eauto. destruct p; eauto.
       destruct p2; eauto. destruct nu; eauto.
       destruct nu0; eauto. destruct R, R0; eauto; simpl.

*)

(*
Lemma ax_const_rs_nil : forall F F0 a A R Rs S, Sig S ->
                 binds F (Ax (a_Fam F0) a A R Rs) S -> F = F0 /\ Rs = nil.
Proof. intros. induction H. inversion H0. inversion H0.
       inversion H3. eauto. inversion H0. inversion H5; subst.
       inversion H2; subst. inversion H2; auto. eauto.
Qed.

Lemma match_subst_roleing : forall W a R p b b', Roleing W a R ->
                   MatchSubst a p b b' -> Roleing W b' R.
Proof. Admitted.

Lemma match_path : forall F p a A R Rs a0 b, binds F (Ax p a A R Rs) toplevel ->
                          MatchSubst a0 p a b -> Path a0 F nil.
Proof. intros. induction H0. pose (H' := H).
       eapply ax_const_rs_nil in H'. inversion H'; subst.
       eauto. apply Sig_toplevel. econstructor. auto.
       Admitted.
*)



Lemma tm_subpattern_agree_const_same : forall a p, tm_subpattern_agree a p ->
 head_const a = head_const p.
Proof. intros. induction H; simpl; eauto.
       apply tm_pattern_agree_const_same; auto.
Qed.

Fixpoint pattern_length (a : tm) : nat := match a with
   a_Fam F => 0
 | a_App a nu b => pattern_length a + 1
 | a_CApp a g_Triv => pattern_length a + 1
 | _ => 0
 end.

Lemma tm_pattern_agree_length_same : forall a p, tm_pattern_agree a p ->
      pattern_length a = pattern_length p.
Proof. intros. induction H; simpl; eauto.
Qed.

Lemma tm_subpattern_agree_length_leq : forall a p, tm_subpattern_agree a p ->
      pattern_length a <= pattern_length p.
Proof. intros. induction H; simpl; try omega.
       eapply tm_pattern_agree_length_same in H; omega.
Qed.

Lemma subtm_pattern_agree_length_geq : forall a p, subtm_pattern_agree a p ->
      pattern_length a >= pattern_length p.
Proof. intros. induction H; simpl; try omega.
       eapply tm_pattern_agree_length_same in H; omega.
Qed.

Lemma tm_subpattern_agree_abs_cabs_contr : forall a p,
      tm_subpattern_agree a p -> Abs_CAbs_head_form a -> False.
Proof. intros. dependent induction H; eauto. inversion H0; subst; inversion H.
Qed.

Lemma tm_subpattern_agree_pi_cpi_contr : forall a p,
      tm_subpattern_agree a p -> Pi_CPi_head_form a -> False.
Proof. intros. dependent induction H; eauto. inversion H0; subst; inversion H.
Qed.

Lemma tm_subpattern_agree_case_contr : forall R a F b1 b2 p,
                tm_subpattern_agree (a_Pattern R a F b1 b2) p -> False.
Proof. intros. dependent induction H; eauto. inversion H.
Qed.

Lemma tm_subpattern_agree_app_contr : forall nu a b p, tm_pattern_agree a p ->
                  tm_subpattern_agree (a_App a nu b) p -> False.
Proof. intros. apply tm_pattern_agree_length_same in H.
       apply tm_subpattern_agree_length_leq in H0. simpl in H0. omega.
Qed.

Lemma tm_subpattern_agree_capp_contr : forall a p, tm_pattern_agree a p ->
                  tm_subpattern_agree (a_CApp a g_Triv) p -> False.
Proof. intros. apply tm_pattern_agree_length_same in H.
       apply tm_subpattern_agree_length_leq in H0. simpl in H0. omega.
Qed.

Lemma tm_subpattern_agree_sub_app : forall a nu b p,
              tm_subpattern_agree (a_App a nu b) p ->
              tm_subpattern_agree a p.
Proof. intros. dependent induction H; eauto. inversion H; subst. eauto.
       eauto.
Qed.

Lemma tm_subpattern_agree_sub_capp : forall a p,
              tm_subpattern_agree (a_CApp a g_Triv) p ->
              tm_subpattern_agree a p.
Proof. intros. dependent induction H; eauto. inversion H; subst. eauto.
Qed.

Lemma tm_subpattern_agree_rel_contr : forall a b p, tm_subpattern_agree
      (a_App a (Rho Rel) b) p -> False.
Proof. intros. dependent induction H; eauto. inversion H.
Qed.


(*
Lemma tm_subpattern_agree_irrel_bullet : forall a b p, tm_subpattern_agree
      (a_App a (Rho Irrel) b) p -> b = a_Bullet.
Proof. intros. dependent induction H; eauto. inversion H. auto.
Qed. *)

Ltac pattern_head := match goal with
      | [ P1 : binds ?F (Ax ?p _ _ _ _) toplevel,
          P2 : Rename ?p _ ?p' _ _ _,
          P3 : MatchSubst ?a ?p' _ _ |- _ ] =>
            pose (Q := tm_pattern_agree_rename_inv_2 (MatchSubst_match P3) P2);
            pose (Q1 := tm_pattern_agree_const_same Q);
            pose (Q2 := axiom_pattern_head P1);
            assert (U : head_const a = a_Fam F);
           [ rewrite Q1; rewrite Q2; auto |
             simpl in U; clear Q2; clear Q1; clear Q ]
       end.

Ltac pattern_head_tm_agree := match goal with
      | [ P1 : binds ?F (Ax ?p _ _ _ _) toplevel,
          P2 : tm_pattern_agree ?a ?p |- _ ] =>
          pose (Q := axiom_pattern_head P1);
          pose (Q1 := tm_pattern_agree_const_same P2);
          assert (U1 : head_const a = a_Fam F);
          [ rewrite Q1; auto | clear Q1; clear Q ]
      | [ P1 : binds ?F (Ax ?p _ _ _ _) toplevel,
          P2 : tm_subpattern_agree ?a ?p |- _ ] =>
          pose (Q := axiom_pattern_head P1);
          pose (Q1 := tm_subpattern_agree_const_same P2);
          assert (U1 : head_const a = a_Fam F);
          [ rewrite Q1; auto | clear Q1; clear Q ]
      end.

Ltac axioms_head_same := match goal with
     | [ P11 : binds ?F (Ax ?p1 ?b1 ?A1 ?R1 ?Rs1) toplevel,
         P12 : binds ?F (Cs ?A2 ?Rs2) toplevel |- _ ] =>
         assert (P13 : Ax p1 b1 A1 R1 Rs1 = Cs A2 Rs2);
         [ eapply binds_unique; eauto using uniq_toplevel | inversion P13]
     | [ P11 : binds ?F (Ax ?p1 ?b1 ?A1 ?R1 ?Rs1) toplevel,
         P12 : binds ?F (Ax ?p2 ?b2 ?A2 ?R2 ?Rs2) toplevel |- _ ] =>
         assert (P13 : Ax p1 b1 A1 R1 Rs1 = Ax p2 b2 A2 R2 Rs2);
         [ eapply binds_unique; eauto using uniq_toplevel |
                            inversion P13; subst; clear P13]
     end.

Inductive tm_tm_agree : tm -> tm -> Prop :=
  | tm_tm_agree_const : forall F, tm_tm_agree (a_Fam F) (a_Fam F)
  | tm_tm_agree_app_relR : forall a1 a2 nu b1 b2, tm_tm_agree a1 a2 -> lc_tm b1 ->
       lc_tm b2 -> tm_tm_agree (a_App a1 nu b1) (a_App a2 nu b2)
  | tm_tm_agree_capp : forall a1 a2, tm_tm_agree a1 a2 ->
                      tm_tm_agree (a_CApp a1 g_Triv) (a_CApp a2 g_Triv).
Hint Constructors tm_tm_agree.


Lemma tm_tm_agree_sym : forall a1 a2, tm_tm_agree a1 a2 -> tm_tm_agree a2 a1.
Proof. intros. induction H; eauto.
Qed.

Lemma tm_tm_agree_trans : forall a1 a2 a3, tm_tm_agree a1 a2 ->
      tm_tm_agree a2 a3 -> tm_tm_agree a1 a3.
Proof. intros. generalize dependent a3. induction H; intros; eauto.
       inversion H2; subst. eauto. inversion H0; subst; eauto.
Qed.

Lemma tm_pattern_agree_cong : forall a1 a2 p, tm_pattern_agree a1 p ->
              tm_tm_agree a1 a2 -> tm_pattern_agree a2 p.
Proof. intros. generalize dependent p. induction H0; intros; eauto.
         - destruct nu. inversion H2; subst. eauto.
           destruct rho. inversion H2. inversion H2; subst. eauto.
         - inversion H; subst. eauto.
Qed.

Lemma subtm_pattern_agree_cong : forall a1 a2 p, subtm_pattern_agree a1 p ->
              tm_tm_agree a1 a2 -> subtm_pattern_agree a2 p.
Proof. intros. generalize dependent a2. induction H; intros; eauto.
        - econstructor. eapply tm_pattern_agree_cong; eauto.
        - destruct nu. inversion H1; subst. eauto.
          destruct rho. inversion H1; subst; eauto.
          inversion H1; subst; eauto.
        - inversion H0; subst. eauto.
Qed.

Lemma tm_subpattern_agree_cong : forall a1 a2 p, tm_subpattern_agree a1 p ->
              tm_tm_agree a1 a2 -> tm_subpattern_agree a2 p.
Proof. intros. generalize dependent a2. induction H; intros; eauto.
       econstructor. eapply tm_pattern_agree_cong; eauto.
Qed.

Lemma tm_tm_agree_refl : forall a, Pattern_like_tm a -> tm_tm_agree a a.
Proof. intros. induction H; eauto.
Qed.

Lemma tm_tm_agree_head_same : forall a1 a2, tm_tm_agree a1 a2 ->
      head_const a1 = head_const a2.
Proof. intros. induction H; eauto.
Qed.

Lemma tm_tm_agree_resp_ValuePath : forall a a' F,
      ValuePath a F -> tm_tm_agree a a' -> ValuePath a' F.
Proof. intros. generalize dependent a'.
       induction H; intros a' H1; inversion H1; subst; eauto.
Qed.

Lemma pattern_like_tm_par : forall a a1 W R F p b A R1 Rs, 
      Par W a a1 R -> binds F (Ax p b A R1 Rs) toplevel ->
      tm_subpattern_agree a p -> ~(tm_pattern_agree a p) ->
      (Abs_CAbs_head_form a1 -> False) /\ tm_tm_agree a a1.
Proof. intros. generalize dependent p. induction H; intros; eauto.
         - split. intro. eapply tm_subpattern_agree_abs_cabs_contr; eauto.
           apply tm_tm_agree_refl. eapply tm_subpattern_agree_tm; eauto.
         - assert False. eapply IHPar1; eauto.
           eapply tm_subpattern_agree_sub_app; eauto.
           intro. eapply tm_subpattern_agree_app_contr; eauto.
           contradiction.
         - split. intro. inversion H4. econstructor. eapply IHPar1; eauto.
           eapply tm_subpattern_agree_sub_app; eauto.
           intro. eapply tm_subpattern_agree_app_contr; eauto.
           eapply Par_lc1; eauto. eapply Par_lc2; eauto.
         - assert False. eapply IHPar; eauto.
           eapply tm_subpattern_agree_sub_capp; eauto.
           intro. eapply tm_subpattern_agree_capp_contr; eauto. contradiction.
         - split. intro. inversion H3. econstructor. eapply IHPar. eauto.
           eapply tm_subpattern_agree_sub_capp; eauto.
           intro. eapply tm_subpattern_agree_capp_contr; eauto.
         - assert False.
           eapply tm_subpattern_agree_abs_cabs_contr; eauto.
           contradiction.
         - assert False. eapply tm_subpattern_agree_pi_cpi_contr; eauto.
           contradiction.
         - assert False.
           eapply tm_subpattern_agree_abs_cabs_contr; eauto. contradiction.
         - assert False. eapply tm_subpattern_agree_pi_cpi_contr; eauto.
           contradiction.
         - pattern_head_tm_agree. simpl in U1.
           inversion U1; subst. axioms_head_same. inversion H3; subst.
           contradiction.
         - pattern_head. pattern_head_tm_agree. simpl in U1.
           assert (P : tm_tm_agree a a').
             { eapply IHPar1; eauto.
               eapply tm_subpattern_agree_sub_app; eauto. intro.
               eapply tm_subpattern_agree_app_contr; eauto.
             }
           assert (F = F0).
             { apply tm_tm_agree_head_same in P.
               rewrite U in P. rewrite U1 in P. inversion P; auto.
             }
           subst. axioms_head_same.
           pose (P1 := tm_pattern_agree_rename_inv_2 (MatchSubst_match H4) H3).
           assert False. apply H8. eapply tm_pattern_agree_cong. apply P1.
           econstructor. apply tm_tm_agree_sym; auto.
           eapply Par_lc2; eauto. eapply Par_lc1; eauto. contradiction.
         - pattern_head. pattern_head_tm_agree. simpl in U1.
           assert (P : tm_tm_agree a a').
             { eapply IHPar; eauto.
               eapply tm_subpattern_agree_sub_capp; eauto. intro.
               eapply tm_subpattern_agree_capp_contr; eauto.
             }
           assert (F = F0).
             { apply tm_tm_agree_head_same in P.
               rewrite U in P. rewrite U1 in P. inversion P; auto.
             }
           subst. axioms_head_same.
           pose (P1 := tm_pattern_agree_rename_inv_2 (MatchSubst_match H3) H2).
           assert False. apply H7. eapply tm_pattern_agree_cong. apply P1.
           econstructor. apply tm_tm_agree_sym; auto. contradiction.
         - split. intro. inversion H5.
           apply tm_subpattern_agree_case_contr in H3. contradiction.
         - split. intro. inversion H7.
           apply tm_subpattern_agree_case_contr in H5. contradiction.
         - assert False.
           eapply tm_subpattern_agree_case_contr; eauto. contradiction.
Qed.

(*
Lemma par_pattern_like_tm : forall a a' W R, Par W a a' R ->
                     (exists F p b A R1 Rs, binds F (Ax p b A R1 Rs) toplevel /\
                      tm_subpattern_agree a p /\ ~(tm_pattern_agree a p)) ->
                      a' = a.
Proof. intros. induction H; eauto.
        - assert False. inversion H0 as [F [p [b1 [A [R1 [Rs [H2 [H3 H4]]]]]]]].
          eapply pattern_like_tm_par_abs_cabs_contr. apply H. eauto.
          exists F, p, b1, A, R1, Rs; split; auto. split.
          eapply tm_subpattern_agree_sub_app; eauto. intro.
          eapply tm_subpattern_agree_app_contr; eauto. contradiction.
        - inversion H0 as [F [p [b1 [A [R1 [Rs [H2 [H3 H4]]]]]]]].
          destruct rho. apply tm_subpattern_agree_rel_contr in H3. contradiction.
          assert (b = a_Bullet). eapply tm_subpattern_agree_irrel_bullet; eauto.
          subst. inversion H1; subst. f_equal. eapply IHPar1; eauto.
          exists F, p, b1, A, R1, Rs; split; auto. split.
          eapply tm_subpattern_agree_sub_app; eauto. intro.
          eapply tm_subpattern_agree_app_contr; eauto. inversion H8.
        - assert False. eapply pattern_like_tm_par_abs_cabs_contr; eauto.
          inversion H0 as [F [p [b1 [A [R1 [Rs [H2 [H3 H4]]]]]]]].
          exists F, p, b1, A, R1, Rs; split; auto. split.
          eapply tm_subpattern_agree_sub_capp; eauto.
          intro. eapply tm_subpattern_agree_capp_contr; eauto. contradiction.
        - inversion H0 as [F [p [b1 [A [R1 [Rs [H2 [H3 H4]]]]]]]].
          f_equal. eapply IHPar. exists F, p, b1, A, R1, Rs; split; auto.
          split. eapply tm_subpattern_agree_sub_capp; eauto.
          intro. eapply tm_subpattern_agree_capp_contr; eauto.
        - inversion H0 as [F [p [b1 [A [R1 [Rs [H2 [H3 H4]]]]]]]].
          assert False. eapply tm_subpattern_agree_abs_cabs_contr; eauto.
          contradiction.
        - inversion H0 as [F [p [b1 [A1 [R1 [Rs [H3 [H4 H5]]]]]]]].
          assert False. eapply tm_subpattern_agree_pi_cpi_contr; eauto.
          contradiction.
        - inversion H0 as [F [p [b1 [A [R1 [Rs [H2 [H3 H4]]]]]]]].
          assert False. eapply tm_subpattern_agree_abs_cabs_contr; eauto.
          contradiction.
        - inversion H0 as [F [p [b1 [A1 [R2 [Rs [H5 [H6 H7]]]]]]]].
          assert False. eapply tm_subpattern_agree_pi_cpi_contr; eauto.
          contradiction.
        - inversion H0 as [F0 [p0 [b1 [A0 [R0 [Rs0 [H6 [H7 H8]]]]]]]].
          pattern_head. pattern_head_tm_agree. rewrite U in U1.
          inversion U1; subst. axioms_head_same.
          assert (tm_pattern_agree a p0).
          eapply tm_pattern_agree_rename_inv_2; eauto.
          eapply MatchSubst_match; eauto. contradiction.
        - inversion H0 as [F0 [p [b [A [R1 [Rs [H6 [H7 H8]]]]]]]]. assert False.
          eapply tm_subpattern_agree_pattern_contr; eauto. contradiction.
        - inversion H0 as [F0 [p [b' [A [R1 [Rs [H6 [H7 H8]]]]]]]]. assert False.
          eapply tm_subpattern_agree_pattern_contr; eauto. contradiction.
        - inversion H0 as [F0 [p [b' [A [R1 [Rs [H6 [H7 H8]]]]]]]]. assert False.
          eapply tm_subpattern_agree_pattern_contr; eauto. contradiction.
Qed.
*)

Fixpoint applyArgs (a : tm) (b : tm) : tm := match a with
   | a_Fam F => b
   | a_App a' nu b' => a_App (applyArgs a' b) nu b'
   | a_CApp a' g_Triv => a_CApp (applyArgs a' b) g_Triv
   | _ => a_Bullet
   end.
(*
Inductive CasePath_like_tm : tm -> Prop :=
  | CasePath_like_fam : forall F, CasePath_like_tm (a_Fam F)
  | CasePath_like_app : forall a nu b, CasePath_like_tm a -> lc_tm b ->
                               CasePath_like_tm (a_App a nu b)
  | CasePath_like_capp : forall a, CasePath_like_tm a ->
                               CasePath_like_tm (a_CApp a g_Triv).
Hint Constructors CasePath_like_tm.*)

Lemma ApplyArgs_applyArgs : forall a b b', ApplyArgs a b b' ->
                             applyArgs a b = b'.
Proof. intros. induction H; simpl; subst; eauto.
Qed.

Lemma applyArgs_ApplyArgs : forall R a F b b', CasePath R a F -> lc_tm b ->
                          applyArgs a b = b' -> ApplyArgs a b b'.
Proof. intros. generalize dependent b'. apply CasePath_ValuePath in H.
       induction H; intros; simpl in *; subst; eauto.
Qed.


(* Properties of CasePath and Value *)

Lemma ValuePath_head : forall a F, ValuePath a F -> head_const a = a_Fam F.
Proof. intros. induction H; eauto.
Qed.

Lemma CasePath_head : forall F a R, CasePath R a F -> head_const a = a_Fam F.
Proof. intros. apply CasePath_ValuePath in H. apply ValuePath_head; auto.
Qed.

Ltac pattern_head_same := match goal with
      | [ P1 : binds ?F (Ax ?p _ _ _ _) toplevel,
          P2 : Rename ?p _ ?p' _ _ _,
          P3 : MatchSubst ?a ?p' _ _,
          P4 : binds ?F' (Ax _ _ _ _ _) toplevel,
          P5 : CasePath _ ?a' ?F' |- _ ] => pattern_head;
            pose (Q := CasePath_head P5); simpl in Q;
            assert (U1 : a_Fam F = a_Fam F');
            [ eapply transitivity; symmetry; eauto |
                 inversion U1; subst; clear U1; clear Q; axioms_head_same ]
      | [ P1 : binds ?F (Ax ?p _ _ _ _) toplevel,
          P2 : Rename ?p _ ?p' _ _ _,
          P3 : MatchSubst ?a ?p' _ _,
          P4 : binds ?F' (Ax _ _ _ _ _) toplevel,
          P5 : ValuePath ?a' ?F' |- _ ] => pattern_head;
            pose (Q := ValuePath_head P5); simpl in Q;
            assert (U1 : a_Fam F = a_Fam F');
            [ eapply transitivity; symmetry; eauto |
                 inversion U1; subst; clear U1; clear Q; axioms_head_same ]
       | [ P1 : binds ?F (Ax ?p _ _ _ _) toplevel,
          P2 : Rename ?p _ ?p' _ _ _,
          P3 : MatchSubst ?a ?p' _ _,
          P4 : binds ?F' (Cs _ _) toplevel,
          P5 : ValuePath ?a' ?F' |- _ ] => pattern_head;
            pose (Q := ValuePath_head P5); simpl in Q;
            assert (U1 : a_Fam F = a_Fam F');
            [ eapply transitivity; symmetry; eauto |
                 inversion U1; subst; clear U1; clear Q; axioms_head_same ]
       end.

Lemma uniq_CasePath : forall F1 F2 a R, CasePath R a F1 -> CasePath R a F2 ->
                       F1 = F2.
Proof. intros. apply CasePath_head in H. apply CasePath_head in H0.
       rewrite H0 in H. inversion H. auto.
Qed.

Lemma ValuePath_cs_par_ValuePath : forall a F A Rs W a' R, ValuePath a F ->
                 binds F (Cs A Rs) toplevel -> Par W a a' R -> ValuePath a' F.
Proof. intros. generalize dependent a'. induction H; intros; eauto.
        - inversion H1; subst; eauto. axioms_head_same.
        - axioms_head_same.
        - inversion H2; subst. auto. assert (ValuePath (a_UAbs rho a'0) F).
          apply IHValuePath; auto. subst. inversion H3.
          econstructor. eapply Par_lc2; eauto. eauto. 
          assert (head_const a = head_const a'0).
          { inversion H7. apply tm_tm_agree_head_same.
            eapply pattern_like_tm_par; eauto. }
            pattern_head_same. eapply transitivity. symmetry; eauto.
            auto.
        - inversion H1; subst; auto. assert (ValuePath (a_UCAbs a'0) F).
          eauto. inversion H2. pattern_head_same. eapply transitivity.
          symmetry; eauto. inversion H4. apply tm_tm_agree_head_same.
          eapply pattern_like_tm_par; eauto.
Qed.

Lemma ValuePath_ax_par_ValuePath_1 : forall a F p b A R1 Rs W a' R,
      ValuePath a F -> binds F (Ax p b A R1 Rs) toplevel ->
      ~(SubRole R1 R) -> Par W a a' R -> ValuePath a' F /\  ~(SubRole R1 R).
Proof. intros. generalize dependent a'. generalize dependent p.
       induction H; intros; eauto.
         - axioms_head_same.
         - axioms_head_same. inversion H2; subst.
           split; eauto. axioms_head_same.
           contradiction.
         - inversion H3; subst. 
           + split; eauto.
           + assert (ValuePath (a_UAbs rho a'0) F).
             eapply IHValuePath; eauto. inversion H4.
           + pose (P := IHValuePath p H2 a'0 H10). inversion P.
             split; eauto. econstructor. eapply Par_lc2; eauto. auto.
           + pattern_head_same. eapply transitivity. symmetry; eauto.
             inversion H8. apply tm_tm_agree_head_same.
             eapply pattern_like_tm_par; eauto. contradiction.
          - inversion H2; subst.
           + split; eauto.
           + assert (ValuePath (a_UCAbs a'0) F).
             eapply IHValuePath; eauto. inversion H3.
           + pose (P := IHValuePath p H0 a'0 H5).
             inversion P. split; auto.
           + pattern_head_same. eapply transitivity.
             symmetry; eauto. inversion H5. apply tm_tm_agree_head_same.
             eapply pattern_like_tm_par; eauto. contradiction.
Qed.


Lemma tm_subpattern_agree_base : forall F p, Pattern p ->
      head_const p = a_Fam F -> tm_subpattern_agree (a_Fam F) p.
Proof. intros. induction H; eauto. simpl in H0. inversion H0; eauto.
Qed.

Lemma ValuePath_ax_par_ValuePath_2 : forall a F p b A R1 Rs W a' R,
      ValuePath a F -> binds F (Ax p b A R1 Rs) toplevel ->
      ~(subtm_pattern_agree a p) -> Par W a a' R -> ValuePath a' F /\
      ~(subtm_pattern_agree a' p) /\ tm_tm_agree a a'.
Proof. intros. generalize dependent a'. generalize dependent p.
       induction H; intros; eauto.
         - axioms_head_same.
         - inversion H2; subst. eauto.
           axioms_head_same. assert False. apply H1. eauto. contradiction.
         - inversion H3; subst.
           + repeat split; simpl in *; eauto. eapply tm_tm_agree_refl; eauto.
             econstructor. eapply ValuePath_Pattern_like_tm; eauto. auto.
           + assert (ValuePath (a_UAbs rho a'0) F).
             eapply IHValuePath; eauto. inversion H4.
           + pose (P := IHValuePath p H1 ltac:(eauto) a'0 H10).
             inversion P as [P1 [P2 P3]].
             split; eauto. econstructor. eapply Par_lc2; eauto. auto.
             assert (Q : tm_tm_agree (a_App a'0 nu b'0) (a_App a nu b')).
             { apply tm_tm_agree_sym in P3. apply Par_lc2 in H11. eauto. }
             split. intro. apply H2. eapply subtm_pattern_agree_cong; eauto.
             apply tm_tm_agree_sym; auto.
           + inversion H8.
             assert (tm_tm_agree a a'0). eapply pattern_like_tm_par; eauto.
             pose (X1 := tm_tm_agree_head_same H6). pattern_head_same.
             eapply transitivity. symmetry; eauto. auto.
             pose (Q1 := tm_pattern_agree_rename_inv_2 (MatchSubst_match H15) H12).
             assert False. eapply H2. econstructor.
             eapply tm_pattern_agree_cong. eapply Q1. econstructor.
             eapply tm_tm_agree_sym; eauto. eapply Par_lc2; eauto. auto.
             contradiction.
          - inversion H2; subst.
           + repeat split; simpl in *; eauto. eapply tm_tm_agree_refl; eauto.
             eapply ValuePath_Pattern_like_tm; eauto.
           + assert (ValuePath (a_UCAbs a'0) F).
             eapply IHValuePath; eauto. inversion H3.
           + pose (P := IHValuePath p H0 ltac:(eauto) a'0 H5).
             inversion P as [P1 [P2 P3]].
             repeat split. econstructor. eapply IHValuePath; eauto. intro.
             apply H1. pose (Q := tm_tm_agree_sym P3).
             eapply subtm_pattern_agree_cong; eauto. eauto.
           + inversion H5.
             assert (tm_tm_agree a a'0). eapply pattern_like_tm_par; eauto.
             pose (X1 := tm_tm_agree_head_same H11). pattern_head_same.
             eapply transitivity. symmetry; eauto. auto.
             pose (Q1 := tm_pattern_agree_rename_inv_2 (MatchSubst_match H8) H7).
             assert False. eapply H1. econstructor.
             eapply tm_pattern_agree_cong. eapply Q1. econstructor.
             eapply tm_tm_agree_sym; eauto. auto. contradiction.
Qed.

Lemma Par_CasePath : forall F a R W a', CasePath R a F -> Par W a a' R ->
                                        CasePath R a' F.
Proof. intros. generalize dependent a'. induction H; intros.
       - pose (P := ValuePath_cs_par_ValuePath H H0 H1). eauto.
       - pose (P := ValuePath_ax_par_ValuePath_1 H H0 H1 H2).
         inversion P. eauto.
       - pose (P := ValuePath_ax_par_ValuePath_2 H H0 H1 H2).
         inversion P as [P1 [P2 P3]]. eauto.
Qed.

Ltac invert_par :=
     try match goal with
      | [ Hx : CasePath _ _ _,
          Hy : Par _ _ _ _ |- _ ] => apply CasePath_ValuePath in Hx;
               inversion Hy; subst;
                    match goal with
                 | [ Hz : MatchSubst _ _ _ _,
                     Hw : Rename _ _ _ _ _ |- _ ] =>
                       pose (Q := tm_pattern_agree_rename_inv_2
                              (MatchSubst_match Hz) Hw); inversion Q
                 | [ Hu : ValuePath _ _ |- _ ] => inversion Hu
                     end; fail
           end.

Lemma CasePath_Par : forall F a R W a', Value R a' -> CasePath R a F -> Par W a' a R -> CasePath R a' F.
Proof. intros. induction H; invert_par.
       pose (P := Par_CasePath H H1). apply CasePath_head in H0.
       apply CasePath_head in P. rewrite P in H0. inversion H0; subst; auto.
Qed.

Lemma Value_par_Value : forall R v W v', Value R v -> Par W v v' R -> Value R v'.
Proof. intros. generalize dependent W. generalize dependent v'.
       induction H; intros.
        - inversion H0; subst. auto.
        - inversion H1; subst. auto.
          apply Par_lc2 in H1. econstructor.
          inversion H1; auto. auto.
        - inversion H1; subst. auto.
          apply Par_lc2 in H1. econstructor.
          inversion H1; auto. auto.
        - inversion H1; subst. auto.
        - inversion H0; subst. auto.
          apply Par_lc2 in H0. econstructor. auto.
        - inversion H1; subst. eauto. eapply Value_UAbsIrrel with (L := L \u L0).
          intros. eapply H0. auto. eapply H7; eauto.
        - inversion H1; subst. auto.
        - inversion H0; subst. auto. econstructor.
          eapply Par_lc2; eauto.
        - pose (P := Par_CasePath H H0). eauto.
Qed.

Lemma multipar_CasePath :  forall F a R W a', CasePath R a F ->
                       multipar W a a' R -> CasePath R a' F.
Proof. intros. induction H0; auto. apply IHmultipar. eapply Par_CasePath; eauto.
Qed.

Lemma multipar_CasePath_join_head : forall F1 F2 W a1 a2 c R,
      multipar W a1 c R -> multipar W a2 c R ->
      CasePath R a1 F1 -> CasePath R a2 F2 -> F1 = F2.
Proof. intros. eapply multipar_CasePath in H; eauto.
       eapply multipar_CasePath in H0; eauto. eapply uniq_CasePath; eauto.
Qed.
(*
Lemma app_roleing_nom : forall W a rho b R, roleing W (a_App a (Rho rho) b) R ->
                               roleing W b Nom.
Proof. intros. dependent induction H; eauto. eapply role_a_Bullet.
       eapply rctx_uniq; eauto.
Qed.
*)
Lemma CasePath_ax_par_contr : forall R a F F' p b A R1 Rs p' b' D D' a',
       CasePath R a F -> binds F' (Ax p b A R1 Rs) toplevel ->
       Rename p b p' b' D D' -> MatchSubst a p' b' a' -> SubRole R1 R -> False.
Proof. intros. pattern_head.
       pose (Q := CasePath_head H).
       assert (a_Fam F = a_Fam F'). eapply transitivity. symmetry. eauto. auto.
       inversion H4; subst.
       inversion H; subst.
         + axioms_head_same.
         + axioms_head_same. contradiction.
         + axioms_head_same.
           pose (Q1 := tm_pattern_agree_rename_inv_2 (MatchSubst_match H2) H1).
           apply H7; eauto.
Qed.

Lemma MatchSubst_lc3 : forall a p b1 b2, MatchSubst a p b1 b2 -> lc_tm b1.
Proof. intros. induction H; eauto.
Qed.

Lemma apply_args_par : forall a b c a' b' c' W R1 R2 F, ApplyArgs a b c ->
                       CasePath R1 a F -> Par W a a' R1 -> Par W b b' R2 ->
                       ApplyArgs a' b' c' -> Par W c c' R2.
Proof. intros. generalize dependent a'. generalize dependent b'.
       generalize dependent c'. induction H; intros.
         - inversion H1; subst. inversion H3; subst. auto.
           assert (F0 = F). { eapply CasePath_head in H0; simpl in H0; 
           inversion H0; auto. } subst.
           inversion H0; subst; axioms_head_same. contradiction. assert False.
           apply H9. eauto. contradiction.
         - inversion H3; subst.
             + inversion H4; subst. econstructor.
               eapply IHApplyArgs; eauto. eapply CasePath_app; eauto.
               inversion H5; eauto. econstructor.
               destruct nu. inversion H5; eauto.
               destruct rho; inversion H5; eauto.
             + eapply CasePath_app in H0. pose (P := Par_CasePath H0 H11).
               apply CasePath_ValuePath in P. inversion P.
             + inversion H4; subst. econstructor. eapply IHApplyArgs; eauto.
               eapply CasePath_app; eauto. auto.
             + inversion H9. assert (tm_tm_agree a a'1).
               eapply pattern_like_tm_par; eauto.
               pose (P := MatchSubst_match H16).
               assert (tm_pattern_agree (a_App a nu a') p').
               eapply tm_pattern_agree_cong. eapply P.
               econstructor. eapply tm_tm_agree_sym; eauto.
               eapply Par_lc2; eauto. eapply Par_lc1; eauto.
               destruct (MatchSubst_exists H12 (MatchSubst_lc3 H16)) as [a0 Q].
               assert False. eapply CasePath_ax_par_contr; eauto.
               contradiction.
         - inversion H1; subst.
             + inversion H3; subst. econstructor.
               eapply IHApplyArgs; eauto. eapply CasePath_capp; eauto.
               inversion H4; eauto.
             + eapply CasePath_capp in H0. pose (P := Par_CasePath H0 H6).
               apply CasePath_ValuePath in P. inversion P.
             + inversion H3; subst. econstructor. eapply IHApplyArgs; eauto.
               eapply CasePath_capp; eauto.
             + inversion H6. assert (tm_tm_agree a a'0).
               eapply pattern_like_tm_par; eauto.
               pose (P := MatchSubst_match H9).
               assert (tm_pattern_agree (a_CApp a g_Triv) p').
               eapply tm_pattern_agree_cong. eapply P.
               econstructor. eapply tm_tm_agree_sym; eauto.
               destruct (MatchSubst_exists H13 (MatchSubst_lc3 H9)) as [a0 Q].
               assert False. eapply CasePath_ax_par_contr; eauto. contradiction.
Qed.

Lemma MatchSubst_par : forall a1 p b b' b'' W a2 R F p1 b1 A R1 Rs,
       MatchSubst a1 p b b' -> ~tm_pattern_agree a1 p1 ->
       tm_subpattern_agree a1 p1 -> binds F (Ax p1 b1 A R1 Rs) toplevel ->
       roleing W b R -> Par W a1 a2 R -> MatchSubst a2 p b b'' -> Par W b' b'' R.
Proof. intros. generalize dependent a2. generalize dependent b''.
       generalize dependent p1. generalize dependent W.
       induction H; intros; eauto.
        - inversion H5; subst. eauto.
        - inversion H6; subst. inversion H5; subst.
          + replace W with (nil ++ W); eauto.
            inversion H12; subst. eapply subst2; eauto.
            eapply IHMatchSubst; eauto. eapply roleing_app_rctx.
            admit. simpl_env. auto. intro.
            eapply tm_subpattern_agree_app_contr; eauto.
            eapply tm_subpattern_agree_sub_app; eauto.
            econstructor. eapply roleing_app_rctx. admit. simpl_env. auto.
          + replace W with (nil ++ W); eauto.
            eapply subst3; eauto.
            eapply IHMatchSubst; eauto.
            eapply roleing_app_rctx. admit. simpl_env. auto.
            intro. eapply tm_subpattern_agree_app_contr; eauto.
            eapply tm_subpattern_agree_sub_app; eauto.
            eapply par_app_rctx. admit. simpl_env. auto.
          + inversion H11.
            assert (a_Fam F = a_Fam F0).
             { eapply transitivity. symmetry.
               eapply axiom_pattern_head; eauto.
               eapply transitivity. symmetry.
               eapply tm_subpattern_agree_const_same; eauto.
               simpl. eapply transitivity.
               eapply tm_subpattern_agree_const_same; eauto.
               eapply axiom_pattern_head; eauto.
              }
            inversion H9; subst. axioms_head_same.
            assert (tm_tm_agree a1 a'). eapply pattern_like_tm_par; eauto.
            assert False. eapply H1. eapply tm_pattern_agree_cong.
            eapply tm_pattern_agree_rename_inv_2.
            eapply MatchSubst_match. eapply H20. eauto.
            econstructor. eapply tm_tm_agree_sym; eauto.
            eapply Par_lc2; eauto. eapply Par_lc1; eauto.
            contradiction.
        - inversion H6; subst. inversion H5; subst.
          + inversion H14; subst.
            eapply IHMatchSubst; eauto. intro.
            eapply tm_subpattern_agree_app_contr; eauto.
            eapply tm_subpattern_agree_sub_app; eauto.
          + assert False. eapply pattern_like_tm_par.
            eapply H15. eapply H4. eapply tm_subpattern_agree_sub_app; eauto.
            intro. eapply tm_subpattern_agree_app_contr; eauto. eauto.
            contradiction.
          + eapply IHMatchSubst; eauto.
            intro. eapply tm_subpattern_agree_app_contr; eauto.
            eapply tm_subpattern_agree_sub_app; eauto.
          + inversion H13.
            assert (a_Fam F = a_Fam F0).
             { eapply transitivity. symmetry.
               eapply axiom_pattern_head; eauto.
               eapply transitivity. symmetry.
               eapply tm_subpattern_agree_const_same; eauto.
               simpl. eapply transitivity.
               eapply tm_subpattern_agree_const_same; eauto.
               eapply axiom_pattern_head; eauto.
              }
            inversion H11; subst. axioms_head_same.
            assert (tm_tm_agree a1 a'). eapply pattern_like_tm_par; eauto.
            assert False. eapply H1. eapply tm_pattern_agree_cong.
            eapply tm_pattern_agree_rename_inv_2.
            eapply MatchSubst_match. eapply H20. eauto.
            econstructor. eapply tm_tm_agree_sym; eauto.
            eapply Par_lc2; eauto. eapply Par_lc1; eauto.
            contradiction.
        - inversion H5; subst. inversion H4; subst.
          + inversion H10; subst.
            eapply IHMatchSubst; eauto. intro.
            eapply tm_subpattern_agree_capp_contr; eauto.
            eapply tm_subpattern_agree_sub_capp; eauto.
          + assert False. eapply pattern_like_tm_par.
            eapply H10. eapply H2. eapply tm_subpattern_agree_sub_capp; eauto.
            intro. eapply tm_subpattern_agree_capp_contr; eauto. eauto.
            contradiction.
          + eapply IHMatchSubst; eauto.
            intro. eapply tm_subpattern_agree_capp_contr; eauto.
            eapply tm_subpattern_agree_sub_capp; eauto.
          + inversion H9.
            assert (a_Fam F = a_Fam F0).
             { eapply transitivity. symmetry.
               eapply axiom_pattern_head; eauto.
               eapply transitivity. symmetry.
               eapply tm_subpattern_agree_const_same; eauto.
               simpl. eapply transitivity.
               eapply tm_subpattern_agree_const_same; eauto.
               eapply axiom_pattern_head; eauto.
              }
            inversion H15; subst. axioms_head_same.
            assert (tm_tm_agree a1 a'). eapply pattern_like_tm_par; eauto.
            assert False. eapply H0. eapply tm_pattern_agree_cong.
            eapply tm_pattern_agree_rename_inv_2.
            eapply MatchSubst_match. eapply H12. eauto.
            econstructor. eapply tm_tm_agree_sym; eauto.
            contradiction.
Admitted.


Fixpoint tm_to_roles (a : tm) : roles := match a with
    | a_Fam F => nil
    | a_App a1 (Role R) _ => tm_to_roles a1 ++ [ R ]
    | a_App a1 (Rho _) _ => tm_to_roles a1
    | a_CApp a1 _ => tm_to_roles a1
    | _ => nil
    end.

Lemma Path_inversion : forall a F Rs, Path a F Rs->
         (exists A, binds F (Cs A (tm_to_roles a ++ Rs)) toplevel) \/
         (exists p b A R, binds F (Ax p b A R (tm_to_roles a ++ Rs)) toplevel).
Proof. intros. induction H; simpl; eauto.
        - right. exists p, a, A, R1; eauto.
        - inversion IHPath as [[A H1] | [p [a1 [A [R2 H1]]]]].
          left. exists A. rewrite <- app_assoc. eauto.
          right. exists p, a1, A, R2. rewrite <- app_assoc. eauto.
Qed.

Lemma PatternContexts_roles : forall W G p F B A, PatternContexts W G F B p A ->
      tm_to_roles p = range W.
Proof. intros. induction H; simpl; eauto. rewrite IHPatternContexts; eauto.
Qed.

Lemma tm_pattern_agree_roles : forall a p, tm_pattern_agree a p ->
      tm_to_roles a = tm_to_roles p.
Proof. intros. induction H; simpl; eauto. f_equal; eauto.
Qed.

Lemma subtm_pattern_agree_roles : forall a p, subtm_pattern_agree a p ->
      exists Rs', tm_to_roles a = tm_to_roles p ++ Rs'.
Proof. intros. induction H; simpl; eauto.
       exists nil; rewrite app_nil_r; apply tm_pattern_agree_roles; auto.
       destruct nu; eauto. inversion IHsubtm_pattern_agree as [Rs' H1].
       exists (Rs' ++ [R]). rewrite H1. rewrite app_assoc; auto.
Qed.

Lemma Path_subtm_pattern_agree_contr : forall a F p b A R Rs R0 Rs',
      Path a F (R0 :: Rs') -> binds F (Ax p b A R Rs) toplevel ->
      ~(subtm_pattern_agree a p).
Proof. intros. apply Path_inversion in H.
       inversion H as [[A1 H1] | [p1 [b1 [A1 [R1 H1]]]]].
        - axioms_head_same.
        - axioms_head_same. intro. apply toplevel_inversion in H0.
          inversion H0 as [W [G [B [H3 [H4 [H5 H6]]]]]].
          apply PatternContexts_roles in H3. rewrite <- H6 in H3.
          apply subtm_pattern_agree_roles in H2.
          inversion H2 as [Rs'' H7]. rewrite H7 in H3.
          rewrite <- app_assoc in H3.
          rewrite <- app_nil_r with (l := tm_to_roles p1) in H3.
          rewrite <- app_assoc in H3. apply app_inv_head in H3.
          apply app_cons_not_nil in H3. auto.
Qed.
(*
Lemma ValuePath_dec : forall W a R F, roleing W a R -> ValuePath a F \/ ~(ValuePath a F).
Proof. intros. induction a; try(right; intro h1; inversion h1; fail).
        - inversion H; subst. destruct (IHa1 H2). left; eauto.
          right; intro H3; inversion H3; subst; contradiction.
        - inversion H; subst.
          destruct g; try (right; intro P; inversion P; fail).
          destruct (IHa H2). left; eauto.
          right; intro Q; inversion Q; contradiction. 
        - 
Qed.*)

Lemma CasePath_dec : forall W a R F, roleing W a R -> CasePath R a F \/ ~CasePath R a F.
Proof. intros. generalize dependent R. induction a; intros R' H.
Admitted.
(*       all: try solve [right; move => h1;
                       apply CasePath_ValuePath in h1; inversion h1].
        - intros. inversion H; subst. pose (P := IHa1 R' E H6).
          inversion P as [P1 | P2]. left; econstructor.
          eapply roleing_lc; eauto. auto. right. intro.
          inversion H0; subst. contradiction.
        - intros. inversion H; subst. destruct (E == F). subst.
          left. eauto. right. intro. inversion H0; subst.
          contradiction. contradiction.
          pose (P := sub_dec R R').
          inversion P as [P1 | P2]. right. intro. inversion H0; subst.
          assert (Q : Ax a A R = Cs A0). eapply binds_unique; eauto.
          eapply uniq_toplevel. inversion Q.
          assert (Ax a A R = Ax a0 A0 R1). eapply binds_unique; eauto.
          eapply uniq_toplevel. inversion H2; subst. contradiction.
          destruct (E == F). subst. left. eauto. right. intro.
          inversion H0; subst. contradiction. contradiction.
        - intros. inversion H; subst. pose (P := IHa R' E H4).
          inversion P as [P1 | P2]. left; eauto.
          right. intro. inversion H0; subst. contradiction.
Qed.*)

Lemma tm_subst_tm_tm_back_forth_mutual : forall x y,
      (forall b, y `notin` fv_tm_tm_tm b ->
      tm_subst_tm_tm (a_Var_f x) y (tm_subst_tm_tm (a_Var_f y) x b) = b) /\
      (forall brs, y `notin` fv_tm_tm_brs brs ->
      tm_subst_tm_brs (a_Var_f x) y (tm_subst_tm_brs (a_Var_f y) x brs) = brs) /\
      (forall g, y `notin` fv_tm_tm_co g ->
      tm_subst_tm_co (a_Var_f x) y (tm_subst_tm_co (a_Var_f y) x g) = g) /\
      (forall phi, y `notin` fv_tm_tm_constraint phi ->
      tm_subst_tm_constraint (a_Var_f x) y
          (tm_subst_tm_constraint (a_Var_f y) x phi) = phi).
Proof. intros. apply tm_brs_co_constraint_mutind; intros; simpl;
       try (simpl in H; try simpl in H1; try simpl in H2; f_equal; eauto; fail).
       destruct (eq_var x0 x). simpl. rewrite eq_dec_refl. subst. auto.
       simpl. destruct (eq_var x0 y). subst. simpl in H. fsetdec. auto.
Qed.

Lemma tm_subst_tm_tm_back_forth : forall x y b, y `notin` fv_tm_tm_tm b ->
      tm_subst_tm_tm (a_Var_f x) y (tm_subst_tm_tm (a_Var_f y) x b) = b.
Proof. eapply tm_subst_tm_tm_back_forth_mutual; eauto.
Qed.
(*
Fixpoint fv_tm_tm_tm_correspondence a b x y := 
   match a, b with
   | a_Star, a_Star => True
   | a_Var_b _, a_Var_b _ => True
   | a_Var_f x1, a_Var_f x2 => (x1 = x /\ x2 = y) \/ (x1 <> x /\ x2 <> y)
   | a_Abs _ A1 b1, a_Abs _ A2 b2 =>
       fv_tm_tm_tm_correspondence A1 A2 x y /\
       fv_tm_tm_tm_correspondence b1 b2 x y
   | a_UAbs _ a1, a_UAbs _ a2 =>
       fv_tm_tm_tm_correspondence a1 a2 x y
   | a_App a1 _ b1, a_App a2 _ b2 =>
      fv_tm_tm_tm_correspondence a1 a2 x y /\
      fv_tm_tm_tm_correspondence b1 b2 x y
   | a_Pi _ A1 B1, a_Pi _ A2 B2 =>
       fv_tm_tm_tm_correspondence A1 A2 x y /\
       fv_tm_tm_tm_correspondence B1 B2 x y
   | a_CAbs phi1 b1, a_CAbs phi2 b2 =>
       fv_tm_tm_constraint_correspondence phi1 phi2 x y /\
       fv_tm_tm_tm_correspondence b1 b2 x y
   | a_UCAbs b1, a_UCAbs b2 =>
       fv_tm_tm_tm_correspondence b1 b2 x y
   | a_CApp a1 g1, a_CApp a2 g2 =>
      fv_tm_tm_tm_correspondence a1 a2 x y /\
      fv_tm_tm_co_correspondence g1 g2 x y
   | a_CPi phi1 B1, a_CPi phi2 B2 =>
      fv_tm_tm_constraint_correspondence phi1 phi2 x y /\
       fv_tm_tm_tm_correspondence B1 B2 x y
   | a_Conv a1 _ g1, a_Conv a2 _ g2 =>
      fv_tm_tm_tm_correspondence a1 a2 x y /\
      fv_tm_tm_co_correspondence g1 g2 x y
   | a_Fam _, a_Fam _ => True
   | a_Bullet, a_Bullet => True
   | a_Pattern _ a1 _ b1 b1', a_Pattern _ a2 _ b2 b2' => 
      fv_tm_tm_tm_correspondence a1 a2 x y /\
      fv_tm_tm_tm_correspondence b1 b2 x y /\
      fv_tm_tm_tm_correspondence b1' b2' x y
   | a_DataCon _, a_DataCon _ => True
   | a_Case a1 brs1, a_Case a2 brs2 =>
      fv_tm_tm_tm_correspondence a1 a2 x y /\
      fv_tm_tm_brs_correspondence brs1 brs2 x y
   | a_Sub _ a1, a_Sub _ a2 =>
      fv_tm_tm_tm_correspondence a1 a2 x y
   | _ , _ => False
   end

with fv_tm_tm_brs_correspondence brs1 brs2 x y := match brs1, brs2 with
   | br_None, br_None => True
   | br_One _ a1 br1, br_One _ a2 br2 =>
      fv_tm_tm_tm_correspondence a1 a2 x y /\
      fv_tm_tm_brs_correspondence br1 br2 x y
   | _ , _ => False
   end

with fv_tm_tm_co_correspondence g h x y := match g, h with
  | g_Triv, g_Triv => True
  | g_Var_b _, g_Var_b _ => True
  | g_Var_f _ , g_Var_f _ => True
  | g_Beta a1 b1, g_Beta a2 b2 =>
      fv_tm_tm_tm_correspondence a1 a2 x y /\
      fv_tm_tm_tm_correspondence b1 b2 x y
  | g_Refl a1, g_Refl a2 => fv_tm_tm_tm_correspondence a1 a2 x y
  | g_Refl2 a1 b1 g1, g_Refl2 a2 b2 g2 =>
      fv_tm_tm_tm_correspondence a1 a2 x y /\
      fv_tm_tm_tm_correspondence b1 b2 x y /\
      fv_tm_tm_co_correspondence g1 g2 x y
  | g_Sym g1, g_Sym g2 => fv_tm_tm_co_correspondence g1 g2 x y
  | g_Trans g1 h1, g_Trans g2 h2 =>
      fv_tm_tm_co_correspondence g1 g2 x y /\
      fv_tm_tm_co_correspondence h1 h2 x y
  | g_Sub g1, g_Sub g2 => fv_tm_tm_co_correspondence g1 g2 x y
  | g_PiCong _ _ g1 h1, g_PiCong _ _ g2 h2 =>
      fv_tm_tm_co_correspondence g1 g2 x y /\
      fv_tm_tm_co_correspondence h1 h2 x y
  | g_AbsCong _ _ g1 h1, g_AbsCong _ _ g2 h2 =>
      fv_tm_tm_co_correspondence g1 g2 x y /\
      fv_tm_tm_co_correspondence h1 h2 x y
  | g_AppCong g1 _ _ h1, g_AppCong g2 _ _ h2 =>
      fv_tm_tm_co_correspondence g1 g2 x y /\
      fv_tm_tm_co_correspondence h1 h2 x y
  | g_PiFst g1, g_PiFst g2 => fv_tm_tm_co_correspondence g1 g2 x y
  | g_CPiFst g1, g_CPiFst g2 => fv_tm_tm_co_correspondence g1 g2 x y
  | g_IsoSnd g1, g_IsoSnd g2 => fv_tm_tm_co_correspondence g1 g2 x y
  | g_PiSnd g1 h1, g_PiSnd g2 h2 =>
      fv_tm_tm_co_correspondence g1 g2 x y /\
      fv_tm_tm_co_correspondence h1 h2 x y
  | g_CPiCong g1 h1, g_CPiCong g2 h2 =>
      fv_tm_tm_co_correspondence g1 g2 x y /\
      fv_tm_tm_co_correspondence h1 h2 x y
  | g_CAbsCong g1 h1 i1, g_CAbsCong g2 h2 i2 =>
      fv_tm_tm_co_correspondence g1 g2 x y /\
      fv_tm_tm_co_correspondence h1 h2 x y /\
      fv_tm_tm_co_correspondence i1 i2 x y
  | g_CAppCong g1 h1 i1, g_CAppCong g2 h2 i2 =>
      fv_tm_tm_co_correspondence g1 g2 x y /\
      fv_tm_tm_co_correspondence h1 h2 x y /\
      fv_tm_tm_co_correspondence i1 i2 x y
  | g_CPiSnd g1 h1 i1, g_CPiSnd g2 h2 i2 =>
      fv_tm_tm_co_correspondence g1 g2 x y /\
      fv_tm_tm_co_correspondence h1 h2 x y /\
      fv_tm_tm_co_correspondence i1 i2 x y
  | g_Cast g1 _ h1, g_Cast g2 _ h2 =>
     fv_tm_tm_co_correspondence g1 g2 x y /\
     fv_tm_tm_co_correspondence h1 h2 x y
  | g_EqCong g1 A1 h1, g_EqCong g2 A2 h2 =>
      fv_tm_tm_co_correspondence g1 g2 x y /\
      fv_tm_tm_tm_correspondence A1 A2 x y /\
      fv_tm_tm_co_correspondence h1 h2 x y
  | g_IsoConv phi1 phi1' g1, g_IsoConv phi2 phi2' g2 =>
      fv_tm_tm_constraint_correspondence phi1 phi2 x y /\
      fv_tm_tm_constraint_correspondence phi1' phi2' x y /\
      fv_tm_tm_co_correspondence g1 g2 x y
  | g_Eta a1, g_Eta a2 => fv_tm_tm_tm_correspondence a1 a2 x y
  | g_Left g1 h1, g_Left g2 h2 =>
      fv_tm_tm_co_correspondence g1 g2 x y /\
      fv_tm_tm_co_correspondence h1 h2 x y
  | g_Right g1 h1, g_Right g2 h2 =>
      fv_tm_tm_co_correspondence g1 g2 x y /\
      fv_tm_tm_co_correspondence h1 h2 x y
  | _, _ => False
  end

with fv_tm_tm_constraint_correspondence phi psi x y :=
  match phi, psi with
  | Eq a1 b1 A1 _, Eq a2 b2 A2 _ =>
      fv_tm_tm_tm_correspondence a1 a2 x y /\
      fv_tm_tm_tm_correspondence b1 b2 x y /\
      fv_tm_tm_tm_correspondence A1 A2 x y
  end.

Lemma fv_tm_correspondence_refl : forall x,
     (forall a1, fv_tm_tm_tm_correspondence a1 a1 x x) /\
     (forall a1, fv_tm_tm_brs_correspondence a1 a1 x x) /\
     (forall a1, fv_tm_tm_co_correspondence a1 a1 x x) /\
     (forall a1, fv_tm_tm_constraint_correspondence a1 a1 x x).
Proof. intro x. apply tm_brs_co_constraint_mutind; try intros; simpl; eauto.
       assert (x0 = x \/ x0 <> x). fsetdec. inversion H. left; split; auto.
       right; split; auto.
Qed.

Lemma fv_tm_tm_correspondence_refl : forall x a1,
      fv_tm_tm_tm_correspondence a1 a1 x x.
Proof. intros. eapply fv_tm_correspondence_refl; eauto.
Qed.

(*
Lemma fv_tm_tm_correspondence_subst : forall x e
      (forall a1 d2, x `notin` fv_tm_tm_tm a1 -> x `notin` fv_tm_tm_tm d2 ->
       fv_tm_tm_tm_correspondence a1 d2 x) /\
      (forall a1 d2, x `notin` fv_tm_tm_brs a1 -> x `notin` fv_tm_tm_brs d2 ->
       fv_tm_tm_brs_correspondence a1 d2 x) /\
      (forall a1 d2, x `notin` fv_tm_tm_co a1 -> x `notin` fv_tm_tm_co d2 ->
       fv_tm_tm_co_correspondence a1 d2 x) /\
      (forall a1 d2, x `notin` fv_tm_tm_constraint a1 ->
       x `notin` fv_tm_tm_constraint d2 ->
      fv_tm_tm_constraint_correspondence a1 d2 x ). *)

Lemma tm_subst_tm_hole : forall x1 x2 y a2, y <> x1 -> y <> x2 ->
      (forall b1 d2, fv_tm_tm_tm_correspondence b1 d2 x1 x2 ->
       tm_subst_tm_tm (a_Var_f y) x1 b1 = tm_subst_tm_tm (a_Var_f y) x2 d2 ->
       tm_subst_tm_tm a2 x1 b1 = tm_subst_tm_tm a2 x2 d2) /\
      (forall brs1 d2, fv_tm_tm_brs_correspondence brs1 d2 x1 x2 ->
      tm_subst_tm_brs (a_Var_f y) x1 brs1 = tm_subst_tm_brs (a_Var_f y) x2 d2 ->
      tm_subst_tm_brs a2 x1 brs1 = tm_subst_tm_brs a2 x2 d2) /\
      (forall g1 d2, fv_tm_tm_co_correspondence g1 d2 x1 x2 ->
      tm_subst_tm_co (a_Var_f y) x1 g1 = tm_subst_tm_co (a_Var_f y) x2 d2 ->
      tm_subst_tm_co a2 x1 g1 = tm_subst_tm_co a2 x2 d2) /\
      (forall phi1 d2, fv_tm_tm_constraint_correspondence phi1 d2 x1 x2 ->
      tm_subst_tm_constraint (a_Var_f y) x1 phi1 =
      tm_subst_tm_constraint (a_Var_f y) x2 d2 ->
      tm_subst_tm_constraint a2 x1 phi1 = tm_subst_tm_constraint a2 x2 d2).
Proof. (* intros x1 x2 y a2 Q1 Q2. apply tm_brs_co_constraint_mutind; intros;
       generalize dependent d2; destruct d2; intros P1 P2; simpl in P2;
       eauto; try (inversion P2; subst; simpl; try f_equal; eauto 1; fail);
       try (destruct (eq_var x x2); inversion P2; fail);
       try (destruct (eq_var x x1); inversion P2; fail).
       all: try (simpl in P1; split_hyp; inversion P2;
                 subst; simpl; f_equal; auto; fail).
        - simpl. destruct (eq_var x x1); destruct (eq_var x0 x2).
          + auto.
          + inversion P2; subst. simpl in P1. inversion P1; inversion H.
            symmetry in H0. contradiction. contradiction.
          + inversion P2; subst. simpl in P1. inversion P1; inversion H.
            symmetry in H1. contradiction. contradiction.
          + auto.
Qed. *) Admitted.

Lemma tm_subst_tm_tm_hole : forall x1 x2 y a2 b1 d2, y <> x1 -> y <> x2 ->
       fv_tm_tm_tm_correspondence b1 d2 x1 x2 ->
       tm_subst_tm_tm (a_Var_f y) x1 b1 = tm_subst_tm_tm (a_Var_f y) x2 d2 ->
       tm_subst_tm_tm a2 x1 b1 = tm_subst_tm_tm a2 x2 d2.
Proof. intros. eapply tm_subst_tm_hole; eauto.
Qed.
(*
Lemma correspondence_notin_fv : forall x,
      (forall a1 d2, x `notin` fv_tm_tm_tm a1 -> x `notin` fv_tm_tm_tm d2 ->
       fv_tm_tm_tm_correspondence a1 d2 x) /\
      (forall a1 d2, x `notin` fv_tm_tm_brs a1 -> x `notin` fv_tm_tm_brs d2 ->
       fv_tm_tm_brs_correspondence a1 d2 x) /\
      (forall a1 d2, x `notin` fv_tm_tm_co a1 -> x `notin` fv_tm_tm_co d2 ->
       fv_tm_tm_co_correspondence a1 d2 x) /\
      (forall a1 d2, x `notin` fv_tm_tm_constraint a1 ->
       x `notin` fv_tm_tm_constraint d2 ->
      fv_tm_tm_constraint_correspondence a1 d2 x ).
Proof. (* intros. apply tm_brs_co_constraint_mutind; intros;
       destruct d2; simpl in *; split_hyp; try (split; intro).
       1-200: try fsetdec.
       all : try (
            match goal with
             | [P : ?x `notin` union ?S1 ?S2,
                P' : ?x `notin` union ?S3 ?S4 |- _ ] => 
               apply union_notin_iff in P; apply union_notin_iff in P';
               inversion P; inversion P'
            end; split; [eauto | eauto ]; fail). eauto.
       1-200: try fsetdec. eauto.
       1-200: try fsetdec. 1-200: try fsetdec. eauto.
       1-200 : try fsetdec. eauto. eauto.
       1-200 : try fsetdec. eauto.
       1-200 : try fsetdec. all: eauto.
       1-200 : try fsetdec. 1-100 : try fsetdec.
       all : try fsetdec.
Qed. *) Admitted.

Lemma correspondence_notin_fv_tm : forall a1 a2 x, x `notin` fv_tm_tm_tm a1 ->
      x `notin` fv_tm_tm_tm a2 -> fv_tm_tm_tm_correspondence a1 a2 x.
Proof. intros. eapply correspondence_notin_fv; eauto.
Qed.

Lemma correspondence_in_fv : forall x,
      (forall a1 d2, fv_tm_tm_tm_correspondence a1 d2 x ->
      x `in` fv_tm_tm_tm a1 -> x `in` fv_tm_tm_tm d2) /\
      (forall a1 d2, fv_tm_tm_brs_correspondence a1 d2 x ->
      x `in` fv_tm_tm_brs a1 -> x `in` fv_tm_tm_brs d2) /\
      (forall a1 d2, fv_tm_tm_co_correspondence a1 d2 x ->
      x `in` fv_tm_tm_co a1 -> x `in` fv_tm_tm_co d2) /\
      (forall a1 d2, fv_tm_tm_constraint_correspondence a1 d2 x ->
      x `in` fv_tm_tm_constraint a1 -> x `in` fv_tm_tm_constraint d2).
Proof. (* intros. apply tm_brs_co_constraint_mutind; intros;
       destruct d2; simpl in *; split_hyp.
       all: try (
            match goal with
             | [P : ?x `in` union ?S1 ?S2 |- _ ] => 
               apply AtomSetImpl.union_1 in P; inversion P
            end;
          [ apply AtomSetImpl.union_2; eauto |
            apply AtomSetImpl.union_3; eauto ]; fail).
       all : try (
            match goal with
             | [P : ?x `in` union ?S1 (union ?S2 ?S3) |- _ ] => 
               apply AtomSetImpl.union_1 in P; inversion P as [P1 | P2]
            end;
          [ apply AtomSetImpl.union_2; eauto |
            apply AtomSetImpl.union_1 in P2; inversion P2;
            [ apply AtomSetImpl.union_3; apply AtomSetImpl.union_2; eauto |
              apply AtomSetImpl.union_3; apply AtomSetImpl.union_3; eauto ]];
              fail).
       1-100 : try fsetdec. eauto.
       1-100 : try fsetdec. eauto.
       1-200 : try fsetdec. eauto.
       1-200 : try fsetdec. eauto. eauto. eauto.
       1-100 : try fsetdec. eauto. eauto. eauto.
       1-200 : try fsetdec. all: try fsetdec. eauto.
Qed. *) Admitted. *)

*)
Lemma MatchSubst_subst : forall a p x y b b',
   tm_pattern_agree a p -> lc_tm b -> x `notin` fv_tm_tm_tm p ->
   y `notin` (fv_tm_tm_tm a \u fv_tm_tm_tm p \u fv_tm_tm_tm b) ->
   MatchSubst a p (tm_subst_tm_tm (a_Var_f y) x b) b' ->
   MatchSubst a p b (tm_subst_tm_tm (a_Var_f x) y b').
Proof. intros. generalize dependent x. generalize dependent y.
       generalize dependent b. generalize dependent b'. induction H; intros.
         - inversion H3; subst. rewrite tm_subst_tm_tm_back_forth.
           fsetdec. eauto.
         - simpl in H2. simpl in H3. inversion H4; subst.
           rewrite tm_subst_tm_tm_tm_subst_tm_tm. simpl.
           fsetdec. fsetdec.
           rewrite (tm_subst_tm_tm_fresh_eq a2). fsetdec. eauto.
         - simpl in H2. simpl in H3. inversion H4; subst. eauto.
         - simpl in H2. simpl in H1. inversion H3; subst. eauto.
Qed.

Lemma Subset_trans : forall D1 D2 D3, AtomSetImpl.Subset D1 D2 ->
      AtomSetImpl.Subset D2 D3 -> AtomSetImpl.Subset D1 D3.
Proof. intros. fsetdec.
Qed.

Lemma Subset_union : forall D1 D1' D2 D2', D1 [<=] D1' -> D2 [<=] D2' ->
         (D1 \u D2) [<=] (D1' \u D2').
Proof. intros. fsetdec.
Qed.

Lemma Superset_cont_sub : forall x S1 S2, S1 [<=] S2 -> x `in` S1 -> x `in` S2.
Proof. intros. fsetdec.
Qed.


Lemma Rename_lc_4 : forall p b p' b' D D', Rename p b p' b' D D' -> lc_tm b'.
Proof. intros. induction H; eauto. eapply tm_subst_tm_tm_lc_tm; eauto.
Qed.

Lemma Rename_fv_new_pattern : forall p b p' b' D D', Rename p b p' b' D D' ->
      AtomSetImpl.Subset (fv_tm_tm_tm p') D'.
Proof. intros. induction H; simpl in *; fsetdec.
Qed.

Lemma Rename_fv_body : forall p b p' b' D D',
      Rename p b p' b' D D' ->
      AtomSetImpl.Subset (fv_tm_tm_tm b')
     ((AtomSetImpl.diff (fv_tm_tm_tm b) (fv_tm_tm_tm p)) \u fv_tm_tm_tm p').
Proof. intros. induction H; intros; simpl in *; auto.
         - pose (P := fv_tm_tm_tm_tm_subst_tm_tm_upper a2 (a_Var_f y) x).
           simpl in P.
           eapply Subset_trans. eauto. fsetdec.
         - fsetdec.
         - fsetdec.
Qed.

Lemma Rename_inter_empty : forall p b p' b' D D', Rename p b p' b' D D' ->
      (forall x, x `in` D -> x `notin` D').
Proof. intros. generalize dependent x. induction H; intros; eauto.
       pose (P := IHRename x0 H1). fsetdec.
Qed.

Lemma MatchSubst_fv : forall a p b b', MatchSubst a p b b' ->
      AtomSetImpl.Subset (fv_tm_tm_tm b')
     ((AtomSetImpl.diff (fv_tm_tm_tm b) (fv_tm_tm_tm p)) \u fv_tm_tm_tm a).
Proof. intros. induction H; simpl. auto.
       pose (P := fv_tm_tm_tm_tm_subst_tm_tm_upper b2 a x).
       eapply Subset_trans. eauto. fsetdec. fsetdec. fsetdec.
Qed.

Lemma Rename_MatchSubst_fv : forall p b p' b' D D' a b'',
      Rename p b p' b' D D' -> MatchSubst a p' b' b'' ->
      AtomSetImpl.Subset (fv_tm_tm_tm b'')
      ((AtomSetImpl.diff (fv_tm_tm_tm b) (fv_tm_tm_tm p)) \u fv_tm_tm_tm a).
Proof. intros. apply Rename_fv_body in H. apply MatchSubst_fv in H0.
       fsetdec.
Qed.

(*
Lemma MatchSubst_correspondence : forall a p1 p2 b1 b2 b1' b2' x x1 x2,
     tm_subst_tm_tm (a_Var_f x) x1 b1' = tm_subst_tm_tm (a_Var_f x) x2 b2' ->
     tm_pattern_agree a p1 -> MatchSubst a p1 b1 b1' -> MatchSubst a p2 b2 b2' ->
     x `notin` fv_tm_tm_tm b1 -> x `notin` fv_tm_tm_tm b2 ->
     x1 `notin` fv_tm_tm_tm a -> x2 `notin` fv_tm_tm_tm a ->
    fv_tm_tm_tm_correspondence b1' b2' x.
Proof. intros. generalize dependent b1.
       generalize dependent p2. generalize dependent b2.
       induction H0; intros.
        -inversion H1; subst. inversion H2; subst.
         apply correspondence_notin_fv_tm; auto.
        -inversion H3;subst. inversion H2;subst. simpl in H5, H6.
         eapply IHtm_pattern_agree. fsetdec. fsetdec.
         eapply H4.
         rewrite tm_subst_tm_tm_tm_subst_tm_tm in H2. simpl. admit.
        -inversion H1;subst. inversion H3;subst. eauto.
        -inversion H1;subst. inversion H0;subst. eauto.
Admitted.


Lemma correspondence_subst : forall x x1 x2 a, x <> x1 -> x <> x2 ->
      (forall a1 d2, fv_tm_tm_tm_correspondence (tm_subst_tm_tm a x1 a1)
          (tm_subst_tm_tm a x2 d2) x1 x2 ->
      tm_subst_tm_tm (a_Var_f x) x1 a1 = tm_subst_tm_tm (a_Var_f x) x2 d2 ->
      fv_tm_tm_tm_correspondence a1 d2 x1 x2) /\
      (forall a1 d2, fv_tm_tm_brs_correspondence (tm_subst_tm_brs a x1 a1)
          (tm_subst_tm_brs a x2 d2) x1 x2 ->
      tm_subst_tm_brs (a_Var_f x) x1 a1 = tm_subst_tm_brs (a_Var_f x) x2 d2 ->
      fv_tm_tm_brs_correspondence a1 d2 x1 x2) /\
      (forall a1 d2, fv_tm_tm_co_correspondence (tm_subst_tm_co a x1 a1)
          (tm_subst_tm_co a x2 d2) x1 x2 ->
      tm_subst_tm_co (a_Var_f x) x1 a1 = tm_subst_tm_co (a_Var_f x) x2 d2 ->
      fv_tm_tm_co_correspondence a1 d2 x1 x2) /\
      (forall a1 d2, fv_tm_tm_constraint_correspondence
          (tm_subst_tm_constraint a x1 a1)
          (tm_subst_tm_constraint a x2 d2) x1 x2 ->
      tm_subst_tm_constraint (a_Var_f x) x1 a1 =
              tm_subst_tm_constraint (a_Var_f x) x2 d2 ->
      fv_tm_tm_constraint_correspondence a1 d2 x1 x2).
Proof. intros x x1 x2 a P1 P2. apply tm_brs_co_constraint_mutind; intros;
       generalize dependent d2; destruct d2; intros Q1 Q2;
       try (simpl in *; eauto 1; fail).
       all: try (simpl in *; destruct (eq_var x0 x2); destruct a;
             eauto; try inversion Q2; fail).
       all: try (simpl in *; destruct (eq_var x0 x1); destruct a;
             eauto; try inversion Q2; fail).
       simpl in *. destruct (eq_var x0 x1); destruct (eq_var x3 x2).
       left; auto.
       destruct a; simpl in Q1; try contradiction.
       inversion Q1; inversion H; subst. left; auto.
       right; split; fsetdec.
       destruct a; simpl in Q1; try contradiction.
       inversion Q1; inversion H; subst. left; split; fsetdec.
       right; split; fsetdec.
       assert (x0 = x \/ x0 <> x). fsetdec. inversion H. subst.
       left. split; fsetdec. right; split; fsetdec.
       all: (simpl in *; split_hyp; repeat split). eapply H; eauto. eauto.
 
       inversion Q1; inversion H; subst. simpl in; right; split. eauto. eauto. try contradiction.
       all: try (inversion Q1; destruct (eq_var x0 x2); simpl in *; fsetdec).
Admitted.

Lemma correspondence_subst_tm : forall x x1 x2 a a1 a2, x <> x1 -> x <> x2 ->
      fv_tm_tm_tm_correspondence (tm_subst_tm_tm a x1 a1)
          (tm_subst_tm_tm a x2 a2) x ->
      fv_tm_tm_tm_correspondence a1 d2 x

Lemma MatchSubst_correspondence : forall p b D D' p1 b1 D1 p2 b2 D2 a a1 a2,
   tm_pattern_agree a p -> Rename p b p1 b1 D D1 -> Rename p b p2 b2 D' D2 ->
   AtomSetImpl.Subset (fv_tm_tm_tm a \u fv_tm_tm_tm p \u fv_tm_tm_tm b) D ->
   AtomSetImpl.Subset (fv_tm_tm_tm a \u fv_tm_tm_tm p \u fv_tm_tm_tm b) D' ->
   MatchSubst a p1 b1 a1 -> MatchSubst a p2 b2 a2 ->
  (forall x, x `in` fv_tm_tm_tm a -> fv_tm_tm_tm_correspondence a1 a2 x).
Proof. intros. generalize dependent p1. generalize dependent b1.
       generalize dependent D. generalize dependent D1. generalize dependent a1.
       generalize dependent a2. generalize dependent p2. generalize dependent b2.
       generalize dependent D'. generalize dependent D2. generalize dependent b.
       induction H; intros.
         - inversion H4; subst. inversion H0; subst.
           inversion H5; subst. inversion H1; subst.
           apply fv_tm_tm_correspondence_refl.
         - inversion H1; subst. inversion H5; subst.
           inversion H4; subst. inversion H7; subst.
           eapply MatchSubst_subst in H18. eapply MatchSubst_subst in H22.
           assert (x `in` fv_tm_tm_tm a1 \/ x `notin` fv_tm_tm_tm a1).
           fsetdec. inversion H8.
           assert (fv_tm_tm_tm_correspondence
            (tm_subst_tm_tm (a_Var_f x0) y0 b0)
            (tm_subst_tm_tm (a_Var_f x0) y b2) x).
           eapply IHtm_pattern_agree. auto. fsetdec.
           auto. ea 
Admitted.
*)


Theorem MatchSubst_Rename_preserve : forall p b D D' p1 b1 D1 p2 b2 D2 a a1 a2,
   tm_pattern_agree a p -> Rename p b p1 b1 D D1 -> Rename p b p2 b2 D' D2 ->
   AtomSetImpl.Subset (fv_tm_tm_tm a \u fv_tm_tm_tm p \u fv_tm_tm_tm b) D ->
   AtomSetImpl.Subset (fv_tm_tm_tm a \u fv_tm_tm_tm p \u fv_tm_tm_tm b) D' ->
   MatchSubst a p1 b1 a1 -> MatchSubst a p2 b2 a2 ->
   a1 = a2.
Proof. intros. generalize dependent p1. generalize dependent b1.
       generalize dependent D. generalize dependent D1. generalize dependent a1.
       generalize dependent a2. generalize dependent p2. generalize dependent b2.
       generalize dependent D'. generalize dependent D2. generalize dependent b.
       induction H; intros.
         - inversion H4; subst. inversion H0; subst.
           inversion H5; subst. inversion H1; subst. auto.
         - simpl in H2. simpl in H3. inversion H5; subst.
           inversion H1; subst. inversion H6; subst. inversion H4; subst.
           assert (tm_subst_tm_tm (a_Var_f x) x1 b2 =
                   tm_subst_tm_tm (a_Var_f x) x0 b3).
           { eapply IHtm_pattern_agree with (b := b)(D' := D') (D := D).
           + fsetdec.
           + eapply H18.
           + assert (fv_tm_tm_tm p3 [<=] D'0).
             eapply Rename_fv_new_pattern; eauto.
             assert (x `notin` D'0). eapply Rename_inter_empty. eauto. fsetdec.
             eapply MatchSubst_subst. eapply MatchSubst_match; eauto.
             eapply Rename_lc_4; eauto. fsetdec. pose (P' := Rename_fv_body H18).
             assert (fv_tm_tm_tm a4 [<=] union D' D'0).
             eapply Subset_trans. eauto. eapply Subset_union. fsetdec.
             auto. apply notin_union_3. fsetdec. apply notin_union_3.
             fsetdec. fsetdec. auto.
           + simpl in H2. fsetdec.
           + eapply H22.
           + assert (fv_tm_tm_tm p2 [<=] D'1).
             eapply Rename_fv_new_pattern; eauto.
             assert (x `notin` D'1). eapply Rename_inter_empty. eauto. fsetdec.
             eapply MatchSubst_subst.
             eapply MatchSubst_match; eauto. eapply Rename_lc_4; eauto. fsetdec.
             pose (P' := Rename_fv_body H22).
             assert (fv_tm_tm_tm a3 [<=] union D D'1).
             eapply Subset_trans. eauto. eapply Subset_union. fsetdec.
             auto. apply notin_union_3. fsetdec. apply notin_union_3.
             fsetdec. fsetdec. auto. }
           assert (x `in` fv_tm_tm_tm (a_App a1 (Role R) a2) \/
                   x `notin` fv_tm_tm_tm (a_App a1 (Role R) a2)).
           fsetdec. inversion H8. admit. admit. (*
         + eapply tm_subst_tm_tm_hole; eauto. fsetdec. fsetdec.
           assert (Q : fv_tm_tm_tm_correspondence (tm_subst_tm_tm a2 x1 b2)
                 (tm_subst_tm_tm a2 x0 b3) x).
           eapply MatchSubst_correspondence with (a := a_App a1 (Role R) a2)
           (p := a_App p1 (Role R) (a_Var_f x)). eauto. eapply H4. eapply H1.
           all: eauto. admit.
         + eapply f_equal with (f := tm_subst_tm_tm a2 x) in H7.
           assert (~(eq x1 x)). fsetdec. assert (~(eq x0 x)). fsetdec.
           rewrite tm_subst_tm_tm_tm_subst_tm_tm in H7. fsetdec. auto.
           simpl in H7. destruct (eq_dec x x); [| contradiction].
           pose (P := Rename_MatchSubst_fv H1 H5).
           pose (P' := Rename_MatchSubst_fv H4 H6).
           simpl in H9, P, P'.
           rewrite <- fv_tm_tm_tm_tm_subst_tm_tm_lower in P, P'.
           assert (tm_subst_tm_tm a2 x b2 = b2).
            { apply tm_subst_tm_tm_fresh_eq. intro.
              assert (x `in` Metatheory.remove x1 (fv_tm_tm_tm b2)). fsetdec.
              pose (Q := Superset_cont_sub P' H17).
              apply union_iff in Q. inversion Q. apply diff_iff in H20.
              inversion H20. apply H24. fsetdec. contradiction. }
           rewrite H12 in H7.
           rewrite tm_subst_tm_tm_tm_subst_tm_tm in H7. fsetdec. auto.
           simpl in H7. destruct (eq_dec x x); [| contradiction].
           assert (tm_subst_tm_tm a2 x b3 = b3).
            { apply tm_subst_tm_tm_fresh_eq. intro.
              assert (x `in` Metatheory.remove x0 (fv_tm_tm_tm b3)). fsetdec.
              pose (Q := Superset_cont_sub P H20).
              apply union_iff in Q. inversion Q. apply diff_iff in H21.
              inversion H21. apply H25. fsetdec. contradiction. }
           rewrite H17 in H7. auto. *)
         - inversion H5; subst. inversion H1; subst.
           inversion H6; subst. inversion H4; subst.
           eapply IHtm_pattern_agree with (b := b)(D' := D') (D := D).
           simpl in H3. admit. eapply H11. auto.
           simpl in H2. admit. eapply H14. auto.
         - inversion H4; subst. inversion H0; subst.
           inversion H5; subst. inversion H1; subst.
           eapply IHtm_pattern_agree with (b := b)(D' := D') (D := D).
           simpl in H3. admit. eapply H12. auto.
           simpl in H2. admit. eapply H10. auto.
Admitted.



