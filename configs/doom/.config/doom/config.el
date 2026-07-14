;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
(setq user-full-name "Hamish Blake")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type 'relative)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

;; AI: gptel wired to Claude. Supply a key via the ANTHROPIC_API_KEY env var or
;; an auth-source entry for api.anthropic.com. `M-x gptel` opens a chat buffer;
;; `gptel-send` sends a prompt; the gptel transient menu switches models (e.g.
;; to claude-opus-4-8 for harder work).
(after! gptel
  (setq gptel-default-mode 'org-mode
        gptel-model 'claude-sonnet-4-6
        gptel-backend (gptel-make-anthropic "Claude"
                        :stream t
                        :key (lambda ()
                               (or (getenv "ANTHROPIC_API_KEY")
                                   (auth-source-pick-first-password
                                    :host "api.anthropic.com"))))))

;; Sapling smartlog: live super-smartlog in a read-only, ANSI-colored buffer,
;; refreshed on a timer. Pure elisp, no vterm/native build needed (SPC g S).
(require 'ansi-color)

(defvar my/sl-smartlog-timer nil)

(defun my/sl-smartlog-refresh ()
  (let ((buf (get-buffer "*sl-smartlog*")))
    (cond
     ((not (buffer-live-p buf))
      (when (timerp my/sl-smartlog-timer) (cancel-timer my/sl-smartlog-timer))
      (setq my/sl-smartlog-timer nil))
     ((get-buffer-window buf t)
      (with-current-buffer buf
        (let ((inhibit-read-only t)
              (line (line-number-at-pos)))
          (erase-buffer)
          (call-process-shell-command "sl ssl --color=always" nil t)
          (ansi-color-apply-on-region (point-min) (point-max))
          (goto-char (point-min))
          (forward-line (1- line))))))))

(defun my/sl-smartlog ()
  "Show a live Sapling super-smartlog for the current repo (no vterm needed)."
  (interactive)
  (let* ((root (or (locate-dominating-file default-directory ".sl")
                   default-directory))
         (buf (get-buffer-create "*sl-smartlog*")))
    (with-current-buffer buf
      (setq default-directory root)
      (read-only-mode 1))
    (unless (timerp my/sl-smartlog-timer)
      (setq my/sl-smartlog-timer (run-with-timer 0 5 #'my/sl-smartlog-refresh)))
    (pop-to-buffer buf)
    (my/sl-smartlog-refresh)))

(map! :leader :desc "Sapling smartlog" "g S" #'my/sl-smartlog)

;; Meta monorepo nav (OnDemand only): myles = fuzzy filename, tbgX = BigGrep content.
;; Never gate the myles keybind on fb-master: if it fails to load, SPC SPC falls
;; back to projectile and locks the UI indexing the monorepo. Load each package
;; independently and bind only what loaded.
(let ((fb-pkgs "/usr/share/emacs/site-lisp/emacs-packages"))
  (when (file-directory-p fb-pkgs)
    (add-to-list 'load-path fb-pkgs)
    (require 'fb-master nil t)
    (when (require 'myles nil t)
      (setq myles-roots '("~/fbsource" "~/www"))
      (require 'consult)  ; myles-consult is defined only once consult loads
      (map! :leader :desc "Find file (myles)" "SPC" #'myles-consult))
    (when (require 'tbgX nil t)
      (xbgx-enable-repo "x")
      (map! :leader
            :desc "BigGrep fbsource" "s p" #'xbgs
            :desc "BigGrep www"      "s P" #'tbgs))))

;; Snappier live-refine for async consult sources (myles-consult, consult-grep/find):
;; query after 2 chars instead of 3, shorter debounce/throttle.
(setq consult-async-min-input 2
      consult-async-input-debounce 0.1
      consult-async-input-throttle 0.2
      consult-async-refresh-delay 0.1)

;; Doom needs projectile for plumbing (magit repo detection, modeline), but we
;; never navigate by project in the monorepo — myles/BigGrep do that. Stop it
;; ever indexing the giant checkouts (O(repo) = UI freeze).
(after! projectile
  (setq projectile-enable-caching nil
        projectile-indexing-method 'alien)
  (setq projectile-ignored-project-function
        (lambda (root) (string-match-p "/fbsource\\|/www\\|/sandcastle/boxes/" root))))

;; Meta's fb-master auto-starts lsp-mode on hack-mode (.php); over the monorepo it
;; prompts to import a project root on every open, and we don't use LSP here.
;; Neuter both entry points (reversible: remove this to restore LSP).
(with-eval-after-load 'lsp-mode
  (advice-add 'lsp-deferred :override #'ignore)
  (advice-add 'lsp :override #'ignore))


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `with-eval-after-load' block, otherwise Doom's defaults may override your
;; settings. E.g.
;;
;;   (with-eval-after-load 'PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look them up).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.
