;;; master-of-ceremonies.el --- Master of Ceremonies -*- lexical-binding: t; -*-

;; Copyright (C) 2024 Positron Solutions <contact@positron.solutions>

;; Author: Positron Solutions <contact@positron.solutions>
;; Keywords: convenience, outline
;; Version: 0.2.0
;; Package-Requires: ((emacs "29.1"))
;; Homepage: http://github.com/positron-solutions/master-of-ceremonies

;;; License:

;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sub-license, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:

;; The above copyright notice and this permission notice shall be included in
;; all copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Commentary:
;;
;; Master of ceremonies.  Tools for display, screen capture, and presentation:
;;
;; - fullscreen focus with highlight and playback with `mc-focus'
;; - set an exact frame resolution for capture with `mc-frame-size'
;; - subtle, transient cursor with `mc-subtle-cursor-mode'
;; - hide cursor entirely with `mc-hide-cursor-mode'
;; - supress all messages with `mc-quiet-mode'
;; - remap many faces with `mc-face-remap'
;; - set many options at once with `mc-dispatch'
;;
;; To all the MCs out there who go by MC Focus, my sincerest apologies for the
;; unfortunate naming collision.  We will attempt to bring glory to your name.

;;; Code:
(require 'frame)
(require 'face-remap)
(require 'rect)
(require 'transient)

(defgroup mc nil "Master of ceremonies."
  :prefix 'master-of-ceremonies
  :group 'outline)




(defcustom mc-focus-width-factor-max 0.7
  "Focused text maximum width fraction.
This is never exceeded"
  :group 'master-of-ceremonies
  :type 'float)

(defcustom mc-focus-width-factor-min 0.5
  "Focused text minimum width fraction.
This will be achieved unless another maximum is violated."
  :group 'master-of-ceremonies
  :type 'float)

(defcustom mc-focus-height-factor-max 0.7
  "Focused text maximum height fraction.
This is never exceeded."
  :group 'master-of-ceremonies
  :type 'float)

;; TODO what we need is a goal based on the height of lines that is constrained
;; by the maximum based on visible area
(defcustom mc-focus-height-factor-min 0.2
  "Focused text minimum height fraction.
This will be achieved unless another maximum is violated"
  :group 'master-of-ceremonies
  :type 'float)

(defcustom mc-screenshot-path #'temporary-file-directory
  "Directory path or function that returns a directory path.
Directory path is a string."

(defcustom mc-cap-resolutions
  '((youtube-short . (1080 . 1920))
    (1080p . (1920 . 1080))
    (2k . (2560 . 1440))
    (4k . (3840 . 2160))
    (fullscreen . fullboth))
  "Frequent screen capture resolutions.
Form is one of:

- (NAME . (WIDTH . HEIGHT))

- (NAME . FULLSCREEN)

NAME is a symbol, WIDTH and HEIGHT are integers, and FULLSCREEN
is valid value for the `fullscreen' frame parameter."
  :type '(cons (choice cons symbol))
  :group 'master-of-ceremonies)

(defface mc-org-reface-level-1 '((t :inherit 'org-level-1))
  "Org heading override."
  :group 'macro-slides)

(defface mc-org-reface-level-2 '((t :inherit 'org-level-2))
  "Org heading override."
  :group 'macro-slides)

(defface mc-org-reface-level-3 '((t :inherit 'org-level-3))
  "Org heading override."
  :group 'macro-slides)

(defface mc-org-reface-level-4 '((t :inherit 'org-level-4))
  "Org heading override."
  :group 'macro-slides)

(defface mc-org-reface-level-5 '((t :inherit 'org-level-5))
  "Org heading override."
  :group 'macro-slides)

(defface mc-org-reface-level-6 '((t :inherit 'org-level-6))
  "Org heading override."
  :group 'macro-slides)

(defface mc-org-reface-level-7 '((t :inherit 'org-level-7))
  "Org heading override."
  :group 'macro-slides)

(defface mc-org-reface-level-8 '((t :inherit 'org-level-8))
  "Org heading override."
  :group 'macro-slides)

(defface mc-org-reface-document-title '((t :inherit 'org-document-title))
  "Org document title override."
  :group 'macro-slides)

(defface mc-org-reface-document-info '((t :inherit 'org-document-info))
  "Org document info override."
  :group 'macro-slides)

(defvar mc--quiet-old-inhibit-message nil)

(defvar-local mc--focus-highlight-overlays nil
  "Overlays used to focus text.")

(defvar-local mc--focus-highlights nil
  "List of highlight regions for playback.")

(defvar-local mc--focus-cleaned-text nil
  "Copy of cleaned input text for replay expressions.")

(defvar-local mc--present-old-window-config nil
  "Restore configuration for fullscreen presentation.
See `mc-present-fullscreen'.")

(defvar-local mc--focus-margin-left nil)
(defvar-local mc--focus-margin-right nil)
(defvar mc--focus-old-window-config nil)

(defvar-local mc-org-reface-level-1-cookie nil)
(defvar-local mc-org-reface-level-2-cookie nil)
(defvar-local mc-org-reface-level-3-cookie nil)
(defvar-local mc-org-reface-level-4-cookie nil)
(defvar-local mc-org-reface-level-5-cookie nil)
(defvar-local mc-org-reface-level-6-cookie nil)
(defvar-local mc-org-reface-level-7-cookie nil)
(defvar-local mc-org-reface-level-8-cookie nil)
(defvar-local mc-org-reface-document-title-cookie nil)
(defvar-local mc-org-reface-document-info-cookie nil)

;; * Remap Org Faces

(defun mc-org-reface--remap (remap)
  "Change status of heading face.  If STATUS is nil, apply the default values."
  (cond
   (remap
    (setq
     mc-org-reface-level-1-cookie
     (face-remap-add-relative 'org-level-1 'mc-org-reface-level-1)
     mc-org-reface-level-2-cookie
     (face-remap-add-relative 'org-level-2 'mc-org-reface-level-2)
     mc-org-reface-level-3-cookie
     (face-remap-add-relative 'org-level-3 'mc-org-reface-level-3)
     mc-org-reface-level-4-cookie
     (face-remap-add-relative 'org-level-4 'mc-org-reface-level-4)
     mc-org-reface-level-5-cookie
     (face-remap-add-relative 'org-level-5 'mc-org-reface-level-5)
     mc-org-reface-level-6-cookie
     (face-remap-add-relative 'org-level-6 'mc-org-reface-level-6)
     mc-org-reface-level-7-cookie
     (face-remap-add-relative 'org-level-7 'mc-org-reface-level-7)
     mc-org-reface-level-8-cookie
     (face-remap-add-relative 'org-level-8 'mc-org-reface-level-8)
     mc-org-reface-document-title-cookie
     (face-remap-add-relative 'org-document-title
                              'mc-org-reface-document-title)
     mc-org-reface-document-info-cookie
     (face-remap-add-relative 'org-document-info
                              'mc-org-reface-document-info)))
   (t
    (face-remap-remove-relative mc-org-reface-level-1-cookie)
    (face-remap-remove-relative mc-org-reface-level-2-cookie)
    (face-remap-remove-relative mc-org-reface-level-3-cookie)
    (face-remap-remove-relative mc-org-reface-level-4-cookie)
    (face-remap-remove-relative mc-org-reface-level-5-cookie)
    (face-remap-remove-relative mc-org-reface-level-6-cookie)
    (face-remap-remove-relative mc-org-reface-level-7-cookie)
    (face-remap-remove-relative mc-org-reface-level-8-cookie)
    (face-remap-remove-relative mc-org-reface-document-title-cookie)
    (face-remap-remove-relative mc-org-reface-document-info-cookie))))

;; * Subtle Cursor mode
(defvar mc-hide-cursor-mode)            ; compiler appeasement

;;;###autoload
(define-minor-mode mc-subtle-cursor-mode
  "Make cursor subtle.
If `blink-cursor-mode' is off, there will be no visible cursor at all."
  :group 'master-of-ceremonies
  (cond
   (mc-subtle-cursor-mode
    (when mc-hide-cursor-mode
      (mc-hide-cursor-mode -1))
    (setq-local blink-cursor-alist (list (cons
                                          mc-subtle-cursor-type
                                          mc-subtle-cursor-blink-type)))
    (setq-local cursor-type mc-subtle-cursor-type)
    (setq-local blink-cursor-blinks mc-subtle-cursor-blinks)
    ;; This interval and delay are not really optional.  The interval must be
    ;; short or else the cursor will not blink early enough while the delay must
    ;; be zero or else the blink state doesn't show soon enough.
    (setq-local blink-cursor-interval 2.0)
    ;; "Values smaller than 0.2 sec are treated as 0.2 sec."
    ;; because someone thought there is no use case for zero 🤡
    (setq-local blink-cursor-delay 0.2)
    (blink-cursor-mode 1))
   (t
    (setq-local blink-cursor-alist (default-value 'blink-cursor-alist))
    (setq-local cursor-type (default-value 'cursor-type))
    (setq-local blink-cursor-blinks (default-value 'blink-cursor-blinks))

    (setq-local blink-cursor-interval (default-value 'blink-cursor-interval))
    (setq-local blink-cursor-delay (default-value 'blink-cursor-delay))
    (blink-cursor-mode -1))))

;; * Hide Cursor Mode

;;;###autoload
(define-minor-mode mc-hide-cursor-mode
  "Make cursor completely hidden."
  :group 'master-of-ceremonies
  (cond
   (mc-hide-cursor-mode
    (when mc-subtle-cursor-mode
      (mc-subtle-cursor-mode -1))
    ;; Setting the `blink-cursor-alist' and the `cursor-type' this way hides it
    ;; entirely.  No need to customize.
    ;; TODO IIRC This can't match and therefore the blink state is not affected.
    ;; Everything is still hidden.
    (setq-local blink-cursor-alist '((nil . nil)))
    (setq-local cursor-type nil))
   (t
    (setq-local blink-cursor-alist (default-value 'blink-cursor-alist))
    (setq-local cursor-type (default-value 'cursor-type)))))



         ;; TODO restore image display


         (hide-mode-line-mode -1)


  :global t

;; * Quiet mode

(define-minor-mode mc-quiet-mode
  "Inhibit messages in the echo area."
  :group 'master-of-ceremonies
  :global t
  (cond (mc-quiet-mode

         ;; ⚠️ TODO inhibiting messages is a bit dangerous.  If anything fails,
         ;; messages will remain disabled ☠️

         ;; Naturally the manual sets not to set this, but the point is that the
         ;; user doesn't want to have messages for a while.  If it is never to
         ;; be turned off, how else can messages be avoided except case by case?
         (unless inhibit-message
           (setq mc--quiet-old-inhibit-message inhibit-message
                 inhibit-message t)))
        (t
         (setq inhibit-message mc--quiet-old-inhibit-message))))

;; * Focus fullscreen text

(defsubst mc--focus-assert-mode ()
  (unless (eq major-mode 'mc-focus-mode)
    (user-error "Not in focus buffer")))

(defun mc-focus-quit ()
  "Fullscreen quit command."
  (interactive)
  (mc--focus-assert-mode)
  (kill-buffer "*MC Focus*"))

;; only add to the `buffer-list-update-hook' locally so we don't need to unhook
(defun mc--maintain-margins ()
  (when mc--focus-margin-left
    (set-window-margins (selected-window)
                        mc--focus-margin-left
                        mc--focus-margin-right)))

(defun mc--focus-clean-properties (text)
  (let ((dirty-props (object-intervals text))
        (clean-string (substring-no-properties text)))
    (mapc
     (lambda (interval)
       (let ((begin (pop interval))
             (end (pop interval)))
         (put-text-property
          begin end
          'face (plist-get (car interval) 'face)
          clean-string)

         ;; TODO pass along overlays and extract their 'face and 'display to
         ;; compute the buffer visible string.

         (put-text-property
          begin end
          'display (plist-get (car interval) 'display)
          clean-string)))
     dirty-props)
    clean-string))

(defun mc--focus-cleanup ()
  (when mc--focus-old-window-config
    (set-window-configuration mc--focus-old-window-config))
  (setq mc--focus-old-window-config nil
        mc--focus-cleaned-text nil))

(defun mc--display-fullscreen (text)
  "Show TEXT with properties in a fullscreen window."
  (when-let ((old (get-buffer "*MC Focus*")))
    (kill-buffer old))
  (setq mc--focus-old-window-config (current-window-configuration))
  (let ((buffer (get-buffer-create "*MC Focus*"))
        (text (mc--focus-clean-properties text)))
    (delete-other-windows)
    (let ((inhibit-message t))
      (switch-to-buffer buffer))
    (add-hook 'kill-buffer-hook #'mc--focus-cleanup nil t)
    (mc-focus-mode)
    (setq-local mode-line-format nil)
    (show-paren-local-mode -1)
    (mc-hide-cursor-mode 1)
    (read-only-mode -1)

    ;; Before we start adding properties, save the input text without additional
    ;; properties.
    (setq-local mc--focus-cleaned-text text)

    (insert (propertize text
                        'line-prefix nil
                        'wrap-prefix nil))

    (let* ((h (window-pixel-height))
           (w (window-pixel-width))
           (text-size (window-text-pixel-size))
           ;; Not larger than any maximum
           (max-text-scale (min (/ (* w mc-focus-width-factor-max)
                                   (float (car text-size)))
                                (/ (* h mc-focus-height-factor-max)
                                   (float (cdr text-size)))))
           ;; At least as big a the minimum
           (min-scale (max (/ (* w mc-focus-width-factor-min)
                              (float (car text-size)))
                           (/ (* h mc-focus-height-factor-min)
                              (float (cdr text-size)))))
           ;; At least as big as the goal, but without exceeding the max
           (scale (min max-text-scale min-scale))
           (scale-overlay (make-overlay 1 (point-max)))
           (default-background (face-attribute 'default :background)))

      ;; Overrides faces but not inverse colors, which actually is kind of
      ;; desirable for org-modern's TODO's
      (overlay-put scale-overlay 'face
                   `(:height ,scale :background ,default-background :extend t))

      (let* ((h (window-pixel-height))
             (w (window-pixel-width))
             (text-size (window-text-pixel-size))
             (margin-left (/ (- w (car text-size)) 2.0))
             (margin-cols (1- (floor (/ margin-left (frame-char-width)))))
             (margin-top (/ (- h (cdr text-size)) 2.0))
             (margin-lines (/ margin-top (frame-char-height))))
        (set-window-margins nil margin-cols margin-cols)
        (setq mc--focus-margin-left margin-cols
              mc--focus-margin-right margin-cols)

        (add-hook 'buffer-list-update-hook
                  #'mc--maintain-margins
                  nil t)

        (goto-char 0)
        (insert (propertize "\n" 'face `(:height ,margin-lines)))
        (setf (overlay-start scale-overlay) 2)
        (setf (overlay-end scale-overlay) (point-max))))
    (read-only-mode 1)))

(defvar-keymap mc-focus-mode-map
  :parent special-mode-map
  "q" #'mc-focus-quit
  "l" #'mc-focus-highlight
  "c" #'mc-hide-cursor-mode
  "w" #'mc-focus-kill-ring-save
  "s" #'mc-focus-screenshot
  "u" #'mc-focus-highlight-clear)

;;;###autoload
(define-derived-mode mc-focus-mode special-mode
  "Modal controls for focus windows."
  :interactive nil)

(defun mc-focus-highlight-clear ()
  "Delete overlays."
  (interactive)
  (mc--focus-assert-mode)
  (setq mc--focus-highlights nil)
  (mapc #'delete-overlay mc--focus-highlight-overlays)
  (setq mc--focus-highlight-overlays nil))

(defun mc-focus-highlight (beg end)
  "Use the shadow face around BEG and END."
  (interactive "r")
  (mc--focus-assert-mode)
  (when mc--focus-highlight-overlays
    (mc-focus-highlight-clear))
  (push (list beg end) mc--focus-highlights)
  (let ((ov-beg (make-overlay (point-min) beg))
        (ov-end (make-overlay end (point-max))))
    ;; TODO customize
    (overlay-put ov-beg 'face 'shadow)
    (overlay-put ov-end 'face 'shadow)
    (push ov-beg mc--focus-highlight-overlays)
    (push ov-end mc--focus-highlight-overlays))
  ;; unnecessary to deactivate the mark when called any other way
  (when (called-interactively-p 't)
    (deactivate-mark)))

(defun mc--focus-apply-highlights (highlights)
  "Use to replay highlight from Elisp programs.
HIGHLIGHTS is a list of lists of BEG END to be highlighted.  Regions not
contained by some BEG END will have the shadow face applied."
  ;; TODO support multi-region highlight
  (when (> (length highlights) 1)
    (error "Multiple highlights not supported yet."))
  (apply #'mc-focus-highlight (car highlights)))

(defun mc-focus-kill-ring-save ()
  "Save the focused text and highlights to a playback expression."
  (interactive)
  (mc--focus-assert-mode)
  (let ((expression
         `(mc-focus
           ,mc--focus-cleaned-text
           ',mc--focus-highlights)))
    (kill-new (prin1-to-string expression)))
  (message "saved focus to kill ring"))

;;;###autoload
(defun mc-focus-region (beg end)
  (interactive "r")
  (mc--display-fullscreen (buffer-substring beg end)))

(defun mc-focus-screenshot ()
  "Save a screenshot of the current frame as an SVG image."
  (interactive)
  (mc--focus-assert-mode)
  (let* ((timestamp (format-time-string "%F-%H:%M:%S" (current-time)))
         (filename (format "screenshot-%s.svg" timestamp))
         (dir (if (stringp mc-screenshot-path)
                  mc-screenshot-path
                (funcall mc-screenshot-path)))
         (path (concat dir filename))
         (data (x-export-frames nil 'svg)))
    (unless (file-exists-p dir)
      (make-directory dir t))
    (with-temp-file path
      (insert data))
    (message "Saved to: %s" filename)))

;;;###autoload
(defun mc-focus-string (text)
  (interactive "Menter focus text: ")
  (mc--display-fullscreen text))

;;;###autoload
(defun mc-focus (text &optional highlights)
  "Focus selected region or prompt for TEXT.
Optional HIGHLIGHTS is a list of (BEG END)."
  (interactive
   (list (if (region-active-p)
             (funcall (if rectangle-mark-mode
                          (lambda (beg end)
                            (string-join (extract-rectangle beg end)
                                         "\n"))
                        #'buffer-substring)
                      (region-beginning) (region-end))
           (read-string "enter focus text: "))))
  (mc--display-fullscreen text)
  (when highlights
    (mc--focus-apply-highlights highlights)))

;; * Frame Resolution

(transient-define-infix mc--cap-select-res ()
  "Select the resolution."
  :key "r" :argument "resolution=" :format "%k %v"
  :choices mc-cap-resolutions
  :class transient-option)

(transient-define-suffix mc--cap-set-frame-resolution (resolution)
  "Set selected frame dimensions to RESOLUTION.
RESOLUTION is a key into `mc-cap-resolutions'."

  ;; TODO I think I wrote this to warm up at using the transient library.  It
  ;; could have just as easily worked using standard interactive and even
  ;; supported values outside the options.
  (interactive
   (if transient-current-command
       (list
        (transient-arg-value
         "resolution="
         (transient-args transient-current-command)))
     nil))

  (pcase-let ((`(,key . ,value)
               (assoc-string resolution mc-cap-resolutions)))
    (let* ((resolution (consp value))
           (width (and resolution (car value)))
           (height (and resolution (cdr value))))
      (if (eq key 'fullscreen)
          ;; TODO this doesn't actually care about the value of fullscreen
          (set-frame-parameter nil 'fullscreen 'fullboth)
        (set-frame-parameter nil 'fullscreen nil)

        ;; Even with `frame-resize-pixelwise' enabled, some discrepancies have
        ;; been observed.  Setting and then correcting based on the outcome
        ;; should fix most cases as the observed discrepancy is consistent
        ;; between calls.  This will still work even if there is no discrepancy.

        ;; Who requests a pixel resolution when they don't enable a pixel size?
        (unless frame-resize-pixelwise
          (warn "`frame-resize-pixelwise' not enabled"))

        (let ((frame-resize-pixelwise t))
          (set-frame-size nil width height t)
          (unless (and (eq (frame-pixel-width) width)
                       (eq (frame-pixel-height) height))
            (let ((width-correction (- width (frame-pixel-width)))
                  (height-correction (- height (frame-pixel-height))))
              (set-frame-size nil
                              (+ width width-correction)
                              (+ height height-correction)
                              t)))))

      (if resolution
          (message "%s width: %s height: %s"
                   key (frame-pixel-width) (frame-pixel-height))
        (message "%s value: %s" key (frame-parameter nil 'fullscreen))))))

(transient-define-prefix mc-set-resolution ()
  "Configure frames for screen capture."
  ["Options"
   (mc--cap-select-res)]
  ["Screen Aspect and Resolution"
   ("s" "toggle resolution" mc--cap-set-frame-resolution)])

;; TODO not every binary setting needs a mode
;; TODO multiple-settings transient
;; TODO multiple saved values, profiles
;; TODO toggle values within profiles
;; TODO reload composite value into dynamic transient

(provide 'master-of-ceremonies)
;;; master-of-ceremonies.el ends here
