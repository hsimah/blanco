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

(defun my/sl-root (&optional dir)
  "Return the Sapling repo root for DIR (default `default-directory'), or nil.
On EdenFS the dotdir is `.hg' (not `.sl'), so we check both, then fall back to
asking `sl root' directly."
  (let ((default-directory (or dir default-directory)))
    (or (locate-dominating-file default-directory ".hg")
        (locate-dominating-file default-directory ".sl")
        (let ((r (string-trim (shell-command-to-string "sl root 2>/dev/null"))))
          (and (not (string-empty-p r)) (file-name-as-directory r))))))

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
  (let* ((root (or (my/sl-root) default-directory))
         (buf (get-buffer-create "*sl-smartlog*")))
    (with-current-buffer buf
      (setq default-directory root)
      (read-only-mode 1))
    (unless (timerp my/sl-smartlog-timer)
      (setq my/sl-smartlog-timer (run-with-timer 0 5 #'my/sl-smartlog-refresh)))
    (pop-to-buffer buf)
    (my/sl-smartlog-refresh)))

(map! :leader :desc "Sapling smartlog" "g S" #'my/sl-smartlog)

;; Sapling diff of uncommitted changes. Sapling isn't git, so magit/vc are out;
;; we shell out to `sl' like the smartlog does. `sl status'/`sl cat' resolve paths
;; relative to CWD, so both run from the repo root to keep paths aligned.
(defun my/sl--changed-files ()
  "Return an alist of (LABEL . REPO-RELATIVE-PATH) for uncommitted changes."
  (let* ((default-directory (my/sl-root))
         (lines (split-string (shell-command-to-string "sl status") "\n" t)))
    (delq nil
          (mapcar (lambda (l)
                    (when (string-match "\\`\\(.\\) \\(.+\\)\\'" l)
                      (cons l (match-string 2 l))))
                  lines))))

(defun my/sl-diff ()
  "Show a unified diff of uncommitted changes in a read-only `diff-mode' buffer."
  (interactive)
  (let* ((root (my/sl-root))
         (buf (get-buffer-create "*sl-diff*")))
    (with-current-buffer buf
      (setq buffer-read-only nil
            default-directory root)
      (erase-buffer)
      (call-process "sl" nil t nil "diff")
      (when (zerop (buffer-size)) (insert "No uncommitted changes.\n"))
      (goto-char (point-min))
      (diff-mode)
      (setq buffer-read-only t))
    (pop-to-buffer buf)))

(defun my/sl-ediff-file (file)
  "Side-by-side ediff of FILE's uncommitted changes (base = current commit `.').
Interactively, live-filter the changed files and pick one (RET)."
  (interactive
   (let ((files (my/sl--changed-files)))
     (unless files (user-error "No uncommitted changes"))
     (list (cdr (assoc (completing-read "sl ediff: " files nil t) files)))))
  (let* ((root (my/sl-root))
         (default-directory root)
         (abs (expand-file-name file root))
         (base (get-buffer-create (format "*sl base: %s*" (file-name-nondirectory file)))))
    (with-current-buffer base
      (setq buffer-read-only nil
            default-directory root)
      (erase-buffer)
      (call-process "sl" nil t nil "cat" "-r" "." file)
      (let ((buffer-file-name abs)) (set-auto-mode))  ; syntax-highlight base like the file
      (setq buffer-read-only t))
    (ediff-buffers base (find-file-noselect abs))))

(map! :leader
      :desc "Sapling ediff file (split)" "g d" #'my/sl-ediff-file
      :desc "Sapling diff (unified)"     "g D" #'my/sl-diff)

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
      ;; Static grep-buffer search stays available on s x / s X; the live
      ;; consult versions (below) take the primary s p / s P bindings.
      (map! :leader
            :desc "BigGrep fbsource (static)" "s x" #'xbgs
            :desc "BigGrep www (static)"      "s X" #'tbgs))))

;; Live BigGrep content search (VS Code-style): type text, see file:line:match
;; filter live as you type, RET opens at the matching line (with preview). Reuses
;; consult's grep machinery — the builder shells out to xbgs (fbsource) / tbgs
;; (www) per keystroke. Those print `file:line:col:text' relative to ~, but
;; consult expects ripgrep's `file\0line:text' (NUL after the filename, no
;; column), so a tiny perl step rewrites each line before consult parses it.
(defvar my/biggrep-limit 500
  "Max results per BigGrep query (passed as -n).")
(defvar my/biggrep-min-input 3
  "Minimum query length before BigGrep runs (content search is heavier than
filename search, so this is stricter than `consult-async-min-input').")

(defun my/biggrep--make-builder (cmd)
  "Return a `consult--grep' builder that live-searches with BigGrep CMD.
CMD is the BigGrep CLI name, e.g. \"xbgs\" (fbsource) or \"tbgs\" (www)."
  (lambda (_paths)  ; BigGrep queries its own indexed corpus; local paths unused
    (lambda (input)
      (pcase-let ((`(,arg . ,opts) (consult--command-split input)))
        (when (>= (length (string-trim arg)) my/biggrep-min-input)
          (cons (list "sh" "-c"
                      (format "%s -i -n %d %s -- %s 2>/dev/null | perl -pe 's/^([^:]+):([0-9]+):[0-9]+:/$1\\x00$2:/'"
                              cmd my/biggrep-limit
                              (mapconcat #'shell-quote-argument opts " ")
                              (shell-quote-argument arg)))
                (apply-partially #'consult--highlight-literals arg t)))))))

(defun my/biggrep-consult (&optional initial)
  "Live BigGrep content search over fbsource (xbgs)."
  (interactive)
  (consult--grep "BigGrep fbsource" (my/biggrep--make-builder "xbgs")
                 (expand-file-name "~/") initial))

(defun my/tbg-consult (&optional initial)
  "Live BigGrep content search over www (tbgs)."
  (interactive)
  (consult--grep "BigGrep www" (my/biggrep--make-builder "tbgs")
                 (expand-file-name "~/") initial))

(when (and (fboundp 'consult--grep) (executable-find "xbgs"))
  (map! :leader
        :desc "BigGrep fbsource (live)" "s p" #'my/biggrep-consult
        :desc "BigGrep www (live)"      "s P" #'my/tbg-consult))

;; Snappier live-refine for async consult sources (myles-consult, consult-grep/find):
;; query after 2 chars instead of 3, shorter debounce/throttle.
(setq consult-async-min-input 2
      consult-async-input-debounce 0.1
      consult-async-input-throttle 0.2
      consult-async-refresh-delay 0.1)

;; Doom needs projectile for plumbing (magit repo detection, modeline), but we
;; never navigate by project in the monorepo — myles/BigGrep do that. Stop it
;; ever indexing the giant checkouts (O(repo) = UI freeze). `.hhconfig' makes
;; the www/fbsource root a bottom-up project marker so lsp adopts it silently.
(after! projectile
  (setq projectile-enable-caching nil
        projectile-indexing-method 'alien)
  (add-to-list 'projectile-project-root-files-bottom-up ".hhconfig")
  (setq projectile-ignored-project-function
        (lambda (root) (string-match-p "/fbsource\\|/www\\|/sandcastle/boxes/" root))))

;; Go-to-definition via hh_client's LSP (daemon-backed by a running hh_server, so
;; zero local indexing — safe/fast, NOT the projectile lockup). fb-master hooks
;; lsp-mode onto hack-mode; lsp registers an xref backend, so Doom's gd / SPC c d
;; (`+lookup/definition') reach it through the xref fallback even with Doom's own
;; (lsp) module left disabled. gd/M-. def, gD refs, C-o/M-, jump back.
(setq find-file-visit-truename t)  ; hh chokes on the ~/www -> /data/... symlink
(after! lsp-mode
  ;; fb-master loads this lsp-mode (elpa 10.0.0) via a raw `(require 'lsp)', so its
  ;; package autoloads are never registered. That leaves optional feature libraries
  ;; (lsp-lens, lsp-modeline, lsp-headerline, …) void when lsp configures a buffer,
  ;; which aborts hack-mode setup mid-hook: no font-lock, and gd fails in that
  ;; buffer. Loading the autoloads makes all of them resolve on demand.
  (load "lsp-mode-autoloads" t t)
  (setq lsp-auto-guess-root t         ; adopt the .hhconfig root silently, no prompt
        lsp-enable-file-watchers nil  ; lsp's file-watching hangs on EdenFS
        lsp-lens-enable nil           ; code lenses issue reference-count queries that
                                      ; are pathologically slow on the monorepo
        lsp-restart 'auto-restart))

;; Cross-file diagnostic refresh WITHOUT file watchers. lsp-enable-file-watchers
;; stays nil (its workspace walk hangs on EdenFS: lsp-watch-root-folder enumerates
;; every non-ignored directory under the www root synchronously at session init,
;; and the only dirs heavy enough to matter ARE the source trees — flib alone is
;; 6 figures of dirs — so there is no prune that is both bounded and useful).
;;
;; Instead: when a Hack buffer's diagnostics go stale because a symbol changed in
;; another file, replay textDocument/didClose(keep-workspace-alive)+didOpen so hh
;; recomputes and re-publishes for the current buffer contents. This is what
;; `revert-buffer' does for diagnostics, minus the disk read, without discarding
;; unsaved edits (didOpen re-sends live buffer text), and without a session
;; restart. Cheap: 2 notifications per buffer against an already-current daemon.
;; NOTE: relies on lsp-mode PRIVATE API — the `lsp--'-prefixed internal
;; functions `lsp--text-document-did-close' / `lsp--text-document-did-open'.
;; Fine while fb-master pins lsp-mode 10.0.0; revisit on any lsp-mode bump.
;; The `t' passed to did-close is `keep-workspace-alive' (verified against the
;; pinned 10.0.0 signature): it suppresses `lsp--shutdown-workspace' so the hh
;; daemon connection survives the replay and diagnostics are not torn down.
(defun my/lsp--refresh-current-buffer ()
  "Replay didClose(keep-alive)+didOpen so hh recomputes+republishes diagnostics
for the live buffer.  Guarded so one bad buffer can't break `after-save-hook'.
Returns non-nil when a refresh was actually issued."
  (when (and (bound-and-true-p lsp-mode) buffer-file-name (lsp-workspaces))
    (with-demoted-errors "my/lsp refresh: %S"
      (lsp--text-document-did-close t)
      (lsp--text-document-did-open)
      t)))

(defun my/lsp-refresh-diagnostics (&optional all)
  "Refresh diagnostics for the current lsp buffer (or ALL with a prefix arg)."
  (interactive "P")
  (let ((bufs (if all (buffer-list) (list (current-buffer)))) (n 0))
    (dolist (buf bufs)
      (with-current-buffer buf
        (when (my/lsp--refresh-current-buffer) (setq n (1+ n)))))
    (when (called-interactively-p 'any)
      (message "lsp: refreshed diagnostics for %d buffer(s)" n))))

(defun my/lsp-refresh-others-after-save ()
  "After saving a Hack file, refresh every OTHER open Hack buffer so cross-file
diagnostics settle on their own. Only catches saves made in Emacs; use the
keybinding for out-of-band changes (rebase, sl, another editor)."
  (when (and (bound-and-true-p lsp-mode) (derived-mode-p 'hack-mode))
    (let ((this (current-buffer)))
      (dolist (buf (buffer-list))
        (unless (eq buf this)
          (with-current-buffer buf
            (when (derived-mode-p 'hack-mode)
              (my/lsp--refresh-current-buffer))))))))

;; SPC c R = refresh this buffer; SPC u SPC c R = refresh all open buffers.
(map! :leader :desc "LSP refresh diagnostics" "c R" #'my/lsp-refresh-diagnostics)
(add-hook 'after-save-hook #'my/lsp-refresh-others-after-save)


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
