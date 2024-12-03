<!-- !!!THIS FILE HAS BEEN GENERATED!!! Edit README.org -->


# Tools for Display & Presenting

<!--a href="https://melpa.org/#/master-of-ceremonies"--><!--img src="https://melpa.org/packages/master-of-ceremonies-badge.svg" alt="melpa package"--><!--/a--><!--a href="https://stable.melpa.org/#/master-of-ceremonies"--><!--img src="https://stable.melpa.org/packages/master-of-ceremonies-badge.svg" alt="melpa stable package"--><!--/a--><!--a href="https://elpa.nongnu.org/nongnu/master-of-ceremonies.html"--><!--img src="https://elpa.nongnu.org/nongnu/master-of-ceremonies.svg" alt="Non-GNU ELPA"--><!--/a-->

-   display and annotate a region of text fullscreen for screen capture and playback with `mc-focus`
-   set a fixed frame resolution for capture with `mc-fixed-frame-set`
-   self-disappearing subtle cursor with `mc-subtle-cursor-mode`
-   hide cursor entirely with `mc-hide-cursor-mode`
-   remap many faces in a buffer with `mc-face-remap`
-   suppress all messages with `mc-quiet-mode`


## Status 👷

This package is still pre-1.0.

The `mc-focus` command and others are super useful and is used in almost every video or presentation I make! Therefore, it is made available in this early state.

Subscribe to [Positron's YouTube channel](https://www.youtube.com/@Positron-gv7do) to catch updates on when it's added to package archives and more information about how to use it.


## Installation

```elisp
;; Not in MELPA or ELPA yet
;; (use-package master-of-ceremonies)

;; package-vc
(package-vc-install
 '(master-of-ceremonies
   :url "https://github.com/positron-solutions/master-of-ceremonies.git"))

;; using elpaca's with explicit recipe
(use-package master-of-ceremonies
  :ensure (master-of-ceremonies
           :host github
           :repo "positron-solutions/master-of-ceremonies"))

;; straight with explicit recipe
(use-package master-of-ceremonies
  :straight (master-of-ceremonies
             :type git :host github
             :repo "positron-solutions/master-of-ceremonies"))

;; or use manual load-path & require, you brave yak shaver
```


### Customization

`M-x customize-group master-of-ceremonies`

The package prefix is `mc` but the full feature name is `master-of-ceremonies`.


# Contributing

This package is brought to you by [dslide](https://github.com/positron-solutions/dslide), which is brought to you by [prizeforge.com](https://prizeforge.com), brought to you by [positron.solutions](https://positron.solutions). If our Github sponsors page is still up, you can sign up there and we will invite you to move over to PrizeForge when it is launched.

If you don't know what you are doing, most likely you want is quick solutions based on experience and to have them distributed to your normal installation method. File and issue and put a 🍔 into the 🍔 [jar](https://github.com/sponsors/positron-solutions).


## Prospective Features

MC was developed alongside [dslide](https://github.com/positron-solutions/dslide) when dslide was still called Macro Slides. Features where Dslide can benefit from the out-of-the-box behavior will be integrated into dslide. Features thave have strong standalone value **and** are not tedious to integrate with dslide via hooks can live in MC.


### Settings Profiles

It can be rather annoying when switching between multiple sets of coherent settings. For example, it is tedious to change from a live demonstration style setup to a full-screen projector slide show style setup. One set of hooks cannot do the job.


### Recording Integration

Whenever you change the resolution of a frame for recording, you need to configure the output resolution in OBS. To start recording, you have to click on OBS. This kind of work could be tighter and integrated into `mc-dispatch`.


### Extensible Transient UI

A lot of the features a person might want depends on what they have installed. Not everyone uses jinx. Not everyone needs a control to turn it off. Either we can support everything as an option or make the options themselves programmable.