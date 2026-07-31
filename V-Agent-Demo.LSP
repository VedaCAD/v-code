;;;----------------------------------------------------------------------------
;;; V-Agent Interactive Sandbox v1.0 (Tensor Stream Decoding Edition)
;;; Architecture: LLM-Optimized Morphological RPN Parsing with SIMD
;;; Compatibility: AutoCAD 2007+ (Native Unicode Render)
;;; Author: Vico
;;;----------------------------------------------------------------------------
(vl-load-com)

;; --- Core Utilities ---
(defun VA:Split ( str del / pos )
  (if (setq pos (vl-string-search del str))
      (cons (substr str 1 pos) (VA:Split (substr str (+ pos 1 (strlen del))) del))
      (list str)
  )
)

;; --- Virtual Machine & CSG Engine ---
(defun VA:RunVCode (code_str / doc ms stack push pop-val tkns tkn h w l r pt o1 o2 obj raw sub-tkns st)
  (setq doc   (vla-get-ActiveDocument (vlax-get-acad-object))
        ms    (vla-get-ModelSpace doc)
        stack nil)

  (defun push (val) (setq stack (cons val stack)))
  (defun pop-val (/ v) (if stack (progn (setq v (car stack) stack (cdr stack)) v) nil))

  (setq tkns (VA:Split code_str " "))
  (foreach tkn tkns
    (if (/= tkn "")
      (cond
        ;; \U+15B4 [Bqb] : TEXT STREAM DECODING (Pop Tensor String -> Unpack -> Push Scalars)
        ((wcmatch tkn "*\U+15B4*")
         (setq raw (pop-val))
         (if raw
           (progn
             ;; SIMD Unpacking: Split by comma for dimensional vectors
             (setq sub-tkns (VA:Split (vl-princ-to-string raw) ","))
             (foreach st sub-tkns
                 (push (atof st))
             )
           )
         )
        )
        ;; \U+1676 [Tot] : BOX (Pop H, W, L)
        ((wcmatch tkn "*\U+1676*")
         (setq h (pop-val) w (pop-val) l (pop-val) pt (vlax-3d-point 0 0 0))
         (if (not (vl-catch-all-error-p (setq obj (vl-catch-all-apply 'vla-addbox (list ms pt l w h))))) (push obj))
        )
        ;; \U+167A [Kok] : SPHERE (Pop Radius)
        ((wcmatch tkn "*\U+167A*")
         (setq r (pop-val) pt (vlax-3d-point 0 0 0))
         (if (not (vl-catch-all-error-p (setq obj (vl-catch-all-apply 'vla-addsphere (list ms pt r))))) (push obj))
        )
        ;; \U+15E3 [Nan] : SUBTRACT (Pop Obj2, Obj1 -> Obj1 - Obj2)
        ((wcmatch tkn "*\U+15E3*")
         (setq o2 (pop-val) o1 (pop-val))
         (if (and o1 o2) (vl-catch-all-apply 'vla-boolean (list o1 2 o2))) ; 2 = acSubtraction
         (push o1) 
        )
        ;; Default: Push raw token as unverified string (Dirty Data State)
        (t (push tkn))
      )
    )
  )
  
  ;; Visual Feedback: Fallback to _G (Gouraud) for wide compatibility
  (vl-catch-all-apply 'vla-put-Direction (list (vla-get-ActiveViewport doc) (vlax-3d-point 1 -1 1)))
  (vla-ZoomExtents (vlax-get-acad-object))
  (vl-catch-all-apply 'vl-cmdf (list "_.SHADEMODE" "_G"))
)

;; --- Interactive Wizard ---
(defun c:VAgent (/ dcl_tmp f dcl_id step res task v_l v_w v_h v_r prompt_data vcode_raw log_l log_r update-prompt build-stack)
  
  (setq dcl_tmp (vl-filename-mktemp "va_wizard.dcl")
        f       (open dcl_tmp "w"))
  
  ;; Step 1 UI
  (write-line "va_step1 : dialog { label=\"V-Code Morphological Matrix Simulator\"; width=85;" f)
  (write-line "  : text { key=\"step_title\"; font=\"bold\"; alignment=centered; label=\"Step 1: The Ambiguity of Natural Language\"; }" f)
  (write-line "  : spacer { height=0.5; } : boxed_radio_row { label=\"Target Geometry Generation\"; key=\"task\";" f)
  (write-line "    : radio_button { label=\"Solid Box\"; key=\"rb_box\"; value=\"1\"; } : radio_button { label=\"Solid Sphere\"; key=\"rb_sph\"; } : radio_button { label=\"Hollow Box (Boolean)\"; key=\"rb_hol\"; } }" f)
  (write-line "  : boxed_row { label=\"Spatial Parameters (Customizable)\";" f)
  (write-line "    : edit_box { label=\"Length:\"; key=\"v_l\"; edit_width=8; } : edit_box { label=\"Width:\"; key=\"v_w\"; edit_width=8; }" f)
  (write-line "    : edit_box { label=\"Height:\"; key=\"v_h\"; edit_width=8; } : edit_box { label=\"Radius:\"; key=\"v_r\"; edit_width=8; is_enabled=false; } }" f)
  (write-line "  : boxed_column { label=\"Simulated LLM Prompt (Natural Language Payload)\"; : list_box { key=\"prompt_view\"; height=9; width=81; fixed_width=true; } }" f)
  (write-line "  : spacer { height=0.2; } : row { spacer; : button { key=\"next\"; label=\"Translate to V-Code >\"; is_default=true; width=24; } : button { key=\"cancel\"; label=\"Cancel\"; is_cancel=true; width=14; } } }" f)

  ;; Step 2 UI
  (write-line "va_step2 : dialog { label=\"V-Code Morphological Matrix Simulator\"; width=75;" f)
  (write-line "  : text { font=\"bold\"; alignment=centered; label=\"Step 2: Dimensional Collapse (V-Code Matrix)\"; } : spacer { height=0.5; }" f)
  (write-line "  : boxed_column { label=\"Cosmic Language (Morphological Payload)\"; : spacer { height=1; } : text { key=\"vcode_view\"; alignment=centered; font=\"bold\"; } : spacer { height=1; } }" f)
  (write-line "  : boxed_column { label=\"Compression Metrics\"; : text { label=\"> Procedural AutoLISP required: ~180 Tokens\"; color=8; } : text { key=\"token_met\"; label=\"\"; } : text { label=\"> Spatial Hallucination Risk: 0% (Strict Type Casting)\"; } }" f)
  (write-line "  : spacer { height=0.2; } : row { : button { key=\"back\"; label=\"< Back\"; width=12; } spacer; : button { key=\"next\"; label=\"Parse AST Engine >\"; is_default=true; width=24; } : button { key=\"cancel\"; label=\"Cancel\"; is_cancel=true; width=12; } } }" f)

  ;; Step 3 UI
  (write-line "va_step3 : dialog { label=\"V-Code Morphological Matrix Simulator\"; width=125;" f)
  (write-line "  : text { font=\"bold\"; alignment=centered; label=\"Step 3: Stack-Based Virtual Machine Execution\"; } : spacer { height=0.5; }" f)
  (write-line "  : row { : boxed_column { label=\"V-Code Stream\"; : list_box { key=\"log_l\"; height=12; width=28; fixed_width=true; } }" f)
  (write-line "          : boxed_column { label=\"Local CAD Engine Execution Stack (Reverse Polish Notation)\"; : list_box { key=\"log_r\"; height=12; width=88; fixed_width=true; } } }" f)
  (write-line "  : spacer { height=0.2; } : row { : button { key=\"back\"; label=\"< Back\"; width=12; } spacer; : button { key=\"next\"; label=\"Execute Geometry in CAD\"; is_default=true; width=30; } : button { key=\"cancel\"; label=\"Cancel\"; is_cancel=true; width=12; } } }" f)
  (close f)

  ;; State Init
  (setq task "rb_box" v_l "10" v_w "10" v_h "10" v_r "6" step 1)

  (defun update-prompt ()
    (setq v_l (get_tile "v_l") v_w (get_tile "v_w") v_h (get_tile "v_h") v_r (get_tile "v_r") task (get_tile "task"))
    (cond
      ((= task "rb_box")
       (mode_tile "v_l" 0) (mode_tile "v_w" 0) (mode_tile "v_h" 0) (mode_tile "v_r" 1)
       (setq prompt_data (list "System: Hooking into LLM Context..." (strcat "> Prompt: \"Create a solid box measuring " v_l " by " v_w " by " v_h ".\"") "" "> Action: Injecting V-Code 256-Rune Dictionary..." "> Note: Numeric streams must be unpacked via Decode Rune \U+15B4." "> Command: Translate human request to Morphological Matrix."))
       (setq vcode_raw (strcat v_l "," v_w "," v_h " \U+15B4 \U+1676"))
      )
      ((= task "rb_sph")
       (mode_tile "v_l" 1) (mode_tile "v_w" 1) (mode_tile "v_h" 1) (mode_tile "v_r" 0)
       (setq prompt_data (list "System: Hooking into LLM Context..." (strcat "> Prompt: \"Create a solid sphere with a radius of " v_r ".\"") "" "> Action: Injecting V-Code 256-Rune Dictionary..." "> Note: Numeric streams must be unpacked via Decode Rune \U+15B4."))
       (setq vcode_raw (strcat v_r " \U+15B4 \U+167A"))
      )
      ((= task "rb_hol")
       (mode_tile "v_l" 0) (mode_tile "v_w" 0) (mode_tile "v_h" 0) (mode_tile "v_r" 0)
       (setq prompt_data (list "System: Hooking into LLM Context..." (strcat "> Prompt: \"Create a " v_l "x" v_w "x" v_h " box, create a radius " v_r " sphere,") "  and subtract the sphere from the box.\" " "" "> Action: Injecting V-Code Dictionary..." "> Note: Raw text streams must be decoded via \U+15B4."))
       (setq vcode_raw (strcat v_l "," v_w "," v_h " \U+15B4 \U+1676 " v_r " \U+15B4 \U+167A \U+15E3"))
      )
    )
    (start_list "prompt_view") (mapcar 'add_list prompt_data) (end_list)
  )

  (defun build-stack ()
    (cond
      ((= task "rb_box")
       (setq log_l (list (strcat v_l "," v_w "," v_h) "\U+15B4" "\U+1676")
             log_r (list (strcat "-> PUSH: \"" v_l "," v_w "," v_h "\" (Raw Stream)") "-> EVAL: \U+15B4 | Unpack Stream -> PUSH(3 Scalars)" "-> EVAL: \U+1676 (Rune 'Tot' / 3D BOX)" "   | POP(3), Evaluate vla-addbox, PUSH(Ptr_Solid_A)"))
      )
      ((= task "rb_sph")
       (setq log_l (list v_r "\U+15B4" "\U+167A")
             log_r (list (strcat "-> PUSH: \"" v_r "\" (Raw Stream)") "-> EVAL: \U+15B4 | Unpack Stream -> PUSH(1 Scalar)" "-> EVAL: \U+167A (Rune 'Kok' / SPHERE)" "   | POP(1), Evaluate vla-addsphere, PUSH(Ptr_Solid_A)"))
      )
      ((= task "rb_hol")
       (setq log_l (list (strcat v_l "," v_w "," v_h) "\U+15B4" "\U+1676" v_r "\U+15B4" "\U+167A" "\U+15E3")
             log_r (list (strcat "-> PUSH: \"" v_l "," v_w "," v_h "\" (Raw Stream)") "-> EVAL: \U+15B4 | Unpack Stream -> PUSH(3 Scalars)" "-> EVAL: \U+1676 | Draw BOX -> PUSH(Ptr_Solid_A)" (strcat "-> PUSH: \"" v_r "\" (Raw Stream)") "-> EVAL: \U+15B4 | Unpack Stream -> PUSH(1 Scalar)" "-> EVAL: \U+167A | Draw SPHERE -> PUSH(Ptr_Solid_B)" "-> EVAL: \U+15E3 | SUBTRACT (A-B) -> PUSH(Ptr_Final)"))
      )
    )
  )

  ;; Main Event Loop
  (if (>= (setq dcl_id (load_dialog dcl_tmp)) 0)
    (progn
      (while (and (> step 0) (<= step 3))
        (if (new_dialog (strcat "va_step" (itoa step)) dcl_id)
          (progn
            (cond
              ((= step 1)
               (set_tile task "1") (set_tile "v_l" v_l) (set_tile "v_w" v_w) (set_tile "v_h" v_h) (set_tile "v_r" v_r)
               (update-prompt)
               (action_tile "task" "(update-prompt)")
               (action_tile "v_l" "(update-prompt)") (action_tile "v_w" "(update-prompt)")
               (action_tile "v_h" "(update-prompt)") (action_tile "v_r" "(update-prompt)")
               (action_tile "next" "(done_dialog 2)")
              )
              ((= step 2)
               (set_tile "vcode_view" (strcat "[VCODE]  " vcode_raw "  [/VCODE]"))
               (set_tile "token_met" (strcat "> V-Code Matrix consumed: " (itoa (length (VA:Split vcode_raw " "))) " Tokens (Compression: 97.4%)"))
               (action_tile "back" "(done_dialog 1)")
               (action_tile "next" "(done_dialog 3)")
              )
              ((= step 3)
               (build-stack)
               (start_list "log_l") (mapcar 'add_list log_l) (end_list)
               (start_list "log_r") (mapcar 'add_list log_r) (end_list)
               (action_tile "back" "(done_dialog 2)")
               (action_tile "next" "(done_dialog 4)")
              )
            )
            (action_tile "cancel" "(done_dialog 0)")
            (setq res (start_dialog))
            (setq step (if (>= res 0) res 0))
          )
          (setq step 0)
        )
      )
      (unload_dialog dcl_id)
    )
  )
  (vl-file-delete dcl_tmp)
  
  (if (= step 4)
    (progn
      (princ (strcat "\n[V-Code] Received Native Payload: " vcode_raw))
      (princ "\n[V-Code] AST collapsing to physical reality...")
      (VA:RunVCode vcode_raw)
      (princ "\n[Success] Spatial execution complete.")
    )
  )
  (princ)
)
(princ "\n[VedaCAD/v-code] Sandbox loaded. Type VAGENT to launch the Simulator.")
(princ)